#!/usr/bin/env python3
"""gen.py —— 生成 IBuffer UT 的 tb.sv。

IBuffer 有 441 个端口（281 输入 / 160 输出）。端口声明、双例化连线、以及
160 根输出的逐拍比对都是纯机械的，手抄一次必错；而且这种错误**UT 自己测不出来**
（tb 抄错的那根线两侧都不接，两侧都对不上也发现不了）。所以这三段从
**G1 golden 的端口表**直接生成。

手写的部分只有两块，也正是有判断力的部分：
  · 激励（PHASE 状态机，见 tb.sv 里的注释）
  · 覆盖事件统计（用层次引用读 **golden 侧**内部状态，不看重写侧）

用法: python3 gen.py   （Makefile 不自动调用；改了本文件要手动重跑并提交 tb.sv）
"""
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl/IBuffer.sv')

PORT_RE = re.compile(r'^\s*(input|output)\s+(?:(\[[^\]]*\])\s+)?(\w+)\s*,?\s*$')


def parse_ports():
    txt = GOLDEN.read_text().split('\n')
    start = next(i for i, l in enumerate(txt) if l.startswith('module IBuffer('))
    ports = []
    i = start + 1
    while txt[i].rstrip() != ');':
        m = PORT_RE.match(txt[i])
        if not m:
            raise SystemExit('端口行解析失败: %r' % txt[i])
        ports.append((m.group(1), m.group(2) or '', m.group(3)))
        i += 1
    if len(ports) < 400:
        raise SystemExit('只解析到 %d 个端口，明显不对，拒绝生成' % len(ports))
    return ports


HEADER = r'''// =============================================================================
// IBuffer UT —— golden IBuffer 与重写 IBuffer_xs 双例化同激励，逐拍比对全部
// 160 根输出端口。★本文件由 gen.py 生成，改激励请改 gen.py 再重跑★
//
// ★ 激励为什么不是「每个输入每拍独立均匀随机」★
// IBuffer 是 48 项的循环队列 + 6 路输出寄存器。它的判别力全在**边界状态**上，
// 而边界状态纯随机走不到：
//   · 队列满（allowEnq 落 0、in_ready 落 0）：要连续很多拍只进不出；
//   · 指针绕圈（48 项 / 6 个 bank / bank 内 8 项，三组指针各有各的绕法）：
//     要累计进出上百条指令；
//   · 输出寄存器**部分填充**（outputEntriesValidNum ∈ 1..5）：要 decodeCanAccept
//     忽高忽低、且每拍出队条数小于 6 —— 这正是「i - validNum」那个会越界的
//     移位读唯一被用到的场合（见 rtl 的 §8）；
//   · 旁路（队列空 + Decode 能收 + 本拍来了 >6 条）：要队列**恰好空**。
// 所以激励走一个**相位状态机**：FILL（只进不出）/ DRAIN（只出不进）/
// TRICKLE（少量进 + decodeCanAccept 抖动，专打部分填充）/ BYPASS（保持空 + 大块进）/
// RANDOM（全随机兜底），外加随机 flush。每个相位随机长度，循环切换。
// 相位是否真的把这些状态打到了，由文件末尾的 COVERAGE 段判定 —— 任何一项为 0
// 就判 TEST FAILED，不承认「随机跑了 200k 拍所以一定测到了」。
//
// ★ 覆盖统计读的是 golden 的内部状态（层次引用 u_golden.*）★
// 用端口反推「队列现在多满」既绕又不准。这里直接读 golden 内部的 numValid_probe /
// allowEnq / useBypass / outputEntriesValidNum / 各指针 flag。**只读 golden，
// 不读重写侧** —— 否则就是拿被测件证明自己。
//
// ★ 不复位寄存器与比对窗口 ★
// golden 只有 18 个 perf 打拍寄存器不复位（io_perf_*_value_REG/REG_1），且它们
// **每拍无条件更新**，两拍就与激励同步。所以：
//   · 前 4 拍不比（让两侧的 perf 寄存器从随机初值收敛）；
//   · 之后**连复位期间也一起比** —— 这样「给 perf 寄存器加复位」这种复位域
//     变异才抓得住（见 mutants.py 的 M6）。为此复位期间照样打激励，不清零。
// =============================================================================
`timescale 1ns/1ps

module tb;

  localparam int RESETS = 8;   // 运行中插入的异步复位次数（理由见 initial 块）

  int unsigned NCYCLES = 200000;
  bit   clk = 0;
  logic rst;
  int   errors  = 0;
  longint checks = 0;
  longint cyc    = 0;

  always #5 clk = ~clk;
'''

DRIVE = r'''
  // ---------------------------------------------------------------------------
  // 激励：相位状态机
  // ---------------------------------------------------------------------------
  typedef enum int { P_RANDOM = 0, P_FILL = 1, P_DRAIN = 2,
                     P_TRICKLE = 3, P_BYPASS = 4 } phase_e;
  phase_e phase = P_RANDOM;
  int     phase_left = 20;

  function automatic logic [15:0] rand_mask(input int max_bits);
    logic [15:0] m = '0;
    int n = $urandom_range(1, max_bits);
    for (int k = 0; k < n; k++) m[$urandom_range(0, 15)] = 1'b1;
    return m;
  endfunction

  task automatic drive_payload();
    // 数据通路：每拍全随机。它们只是被搬运，不参与控制，随机就够。
    for (int i = 0; i < 16; i++) begin
      case (i)
{{PAYLOAD_CASE}}
      endcase
    end
    io_in_bits_ftqPtr_flag  = $urandom;
    io_in_bits_ftqPtr_value = 6'($urandom);
    io_in_bits_backendException_0         = ($urandom_range(0, 9) == 0);
    io_in_bits_satpFlushFirstFetchFault_0 = ($urandom_range(0, 9) == 0);
    // topdown：多数拍全 0（这样 stallReason 会走 FetchFragBubble 分支），
    // 少数拍置 1~3 个随机位（走 matchBubble 分支，且要能区分「最高位优先」）。
    for (int r = 0; r < 38; r++) set_topdown(r, 1'b0);
    if ($urandom_range(0, 3) == 0)
      for (int k = 0; k < $urandom_range(1, 3); k++)
        set_topdown($urandom_range(0, 37), 1'b1);
    io_stallReason_backReason_valid = ($urandom_range(0, 9) < 2);
    io_stallReason_backReason_bits  = 6'($urandom);
  endtask

  task automatic drive();
    logic [15:0] vmask, emask;
    if (phase_left == 0) begin
      phase      = phase_e'($urandom_range(0, 4));
      phase_left = $urandom_range(8, 120);
    end
    phase_left--;

    drive_payload();
    io_flush = ($urandom_range(0, 249) == 0);
    // flush 归因：五种 ControlRedirect 子因 + MemVioRedirect + 其它，轮着来，
    // 保证 topdown 的 when/elsewhen 优先级链每一档都被走到。
    io_ControlRedirect      = ($urandom_range(0, 2) != 0);
    io_ControlBTBMissBubble = ($urandom_range(0, 2) == 0);
    io_TAGEMissBubble       = ($urandom_range(0, 2) == 0);
    io_SCMissBubble         = ($urandom_range(0, 2) == 0);
    io_ITTAGEMissBubble     = ($urandom_range(0, 2) == 0);
    io_RASMissBubble        = ($urandom_range(0, 2) == 0);
    io_MemVioRedirect       = ($urandom_range(0, 2) == 0);

    case (phase)
      P_FILL: begin      // 只进不出：打到队列满、allowEnq 落 0
        io_decodeCanAccept = 1'b0;
        io_in_valid        = 1'b1;
        vmask = 16'hFFFF;  emask = 16'hFFFF;
      end
      P_DRAIN: begin     // 只出不进：打到队列空、指针绕圈
        io_decodeCanAccept = 1'b1;
        io_in_valid        = ($urandom_range(0, 9) < 2);
        vmask = rand_mask(16); emask = vmask;
      end
      P_TRICKLE: begin   // 少量进 + Decode 抖动：打输出寄存器的部分填充
        io_decodeCanAccept = ($urandom_range(0, 1) == 0);
        io_in_valid        = ($urandom_range(0, 9) < 7);
        vmask = rand_mask(3);  emask = vmask;
      end
      P_BYPASS: begin    // 保持空 + 大块进：打旁路（含 enqOffset >= 6 的那一半）
        io_decodeCanAccept = 1'b1;
        io_in_valid        = ($urandom_range(0, 9) < 8);
        vmask = rand_mask(16); emask = vmask;
      end
      default: begin     // 全随机兜底
        io_decodeCanAccept = ($urandom_range(0, 9) < 6);
        io_in_valid        = ($urandom_range(0, 9) < 7);
        vmask = 16'($urandom);
        // 大多数拍 enqEnable ⊆ valid（真实情形）；少数拍故意越出，
        // 压一压「numFromFetch 只数 enqEnable、写选择却要 valid&enqEnable」这条缝。
        emask = ($urandom_range(0, 9) < 8) ? (vmask & 16'($urandom)) : 16'($urandom);
      end
    endcase
    io_in_bits_valid     = vmask;
    io_in_bits_enqEnable = emask;
  endtask

  always @(negedge clk) drive();   // 复位期间也照打，理由见文件头

  // ---------------------------------------------------------------------------
  // 逐拍比对：160 根输出全比。前 4 拍不比（不复位的 perf 寄存器要两拍收敛）。
  // ---------------------------------------------------------------------------
  `define CHK(nm, g, i) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors < 40) $display("[%0t] cyc=%0d %s mismatch: g=%h i=%h", \
                                $time, cyc, nm, (g), (i)); \
    end end

  always @(posedge clk) begin
    #1;
    if (cyc >= 4) begin
{{COMPARE}}
    end
    cyc++;
  end
'''

COVER = r'''
  // ---------------------------------------------------------------------------
  // 覆盖事件（每项必须 > 0，否则对应状态根本没走到，这一轮 errors=0 不作数）
  // 全部用层次引用读 **golden** 内部状态。
  // ---------------------------------------------------------------------------
  longint cov_full          = 0;  // allowEnq 落 0（队列快满，in_ready 反压）
  longint cov_deep          = 0;  // numValid >= 32（真的填到 IBufSize-PredictWidth）
  longint cov_empty         = 0;  // numValid == 0
  longint cov_bypass        = 0;  // 走旁路（空 + Decode 能收 + 本拍有输入）
  longint cov_bypass_big    = 0;  // 且本块 > 6 条 —— 旁路的 useBypassMatch 那一支
  longint cov_partial[6];         // outputEntriesValidNum == k 的拍数（k=1..5 须 > 0）
  longint cov_shift_read    = 0;  // Decode 不收、寄存器没满、已有有效项 > 0
                                  // → 走「i - validNum」移位读（含越界补第 0 项）
  longint cov_out_full      = 0;  // 输出寄存器 6 条全满（整组保持的分支）
  longint cov_enq_wrap      = 0;  // 入队指针绕过 48（enqPtrVec_0_flag 翻转）
  longint cov_deq_wrap      = 0;  // 出队指针绕过 48
  longint cov_inbank_wrap   = 0;  // bank 内指针绕过 8（deqInBankPtr flag 翻转）
  longint cov_flush_nonempty= 0;  // 非空时 flush
  longint cov_flush_ctrl    = 0;  // ControlRedirect 归因
  longint cov_flush_memvio  = 0;  // MemVioRedirect 归因
  longint cov_flush_other   = 0;  // 其它重定向归因
  longint cov_stall_frag    = 0;  // stallReason 走 FetchFragBubble（无 topdown 归因）
  longint cov_stall_match   = 0;  // stallReason 走 matchBubble（有 topdown 归因）
  longint cov_stall_back    = 0;  // 后端 backReason 覆盖
  longint cov_reset_mid     = 0;  // 运行中异步复位次数
  int     max_numvalid      = 0;

  logic prev_enq_flag, prev_deq_flag;
  logic [5:0] prev_inbank_flag;

  initial for (int k = 0; k < 6; k++) cov_partial[k] = 0;

  // ★ 采样点必须在 negedge 之后、posedge 之前 ★
  // 一开始写在 posedge+2，结果「非空时 flush」恒为 0 —— 因为那一刻 flush 已经
  // 生效、指针已经被清成空了，量到的是**结果**而不是**条件**。同理 useBypass /
  // outputEntriesValidNum 也必须与激励同相位。negedge+2 时激励已驱动、DUT 还是
  // 本拍将要被采样的那个状态，两边对齐。
  always @(negedge clk) begin
    #2;
    if (!rst && cyc > 4) begin
      if (!u_golden.allowEnq)                       cov_full++;
      if (u_golden.numValid_probe >= 6'd32)         cov_deep++;
      if (u_golden.numValid_probe == 6'd0)          cov_empty++;
      if (int'(u_golden.numValid_probe) > max_numvalid)
        max_numvalid = int'(u_golden.numValid_probe);
      if (u_golden.useBypass && io_in_valid) begin
        cov_bypass++;
        if (u_golden.numFromFetch > 5'd6) cov_bypass_big++;
      end
      cov_partial[u_golden.outputEntriesValidNum]++;
      if (u_golden.outputEntries_5_valid) cov_out_full++;
      if (!io_decodeCanAccept && !u_golden.outputEntries_5_valid
          && u_golden.outputEntriesValidNum != 3'd0) cov_shift_read++;
      if (u_golden.enqPtrVec_0_flag !== prev_enq_flag)   cov_enq_wrap++;
      if (u_golden.deqPtr_flag      !== prev_deq_flag)   cov_deq_wrap++;
      for (int b = 0; b < 6; b++)
        if (inbank_flag(b) !== prev_inbank_flag[b])      cov_inbank_wrap++;
      if (io_flush) begin
        if (u_golden.numValid_probe != 6'd0) cov_flush_nonempty++;
        if (io_ControlRedirect)        cov_flush_ctrl++;
        else if (io_MemVioRedirect)    cov_flush_memvio++;
        else                           cov_flush_other++;
      end
      if (io_stallReason_backReason_valid) cov_stall_back++;
      else if (g_io_stallReason_reason_5 == 6'd13) cov_stall_frag++;
      else if (g_io_stallReason_reason_5 != 6'd0)  cov_stall_match++;
    end
    prev_enq_flag = u_golden.enqPtrVec_0_flag;
    prev_deq_flag = u_golden.deqPtr_flag;
    for (int b = 0; b < 6; b++) prev_inbank_flag[b] = inbank_flag(b);
  end

  function automatic logic inbank_flag(input int b);
    case (b)
      0: return u_golden.deqInBankPtr_0_flag;
      1: return u_golden.deqInBankPtr_1_flag;
      2: return u_golden.deqInBankPtr_2_flag;
      3: return u_golden.deqInBankPtr_3_flag;
      4: return u_golden.deqInBankPtr_4_flag;
      default: return u_golden.deqInBankPtr_5_flag;
    endcase
  endfunction

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    rst = 1'b1;
    repeat (6) @(posedge clk);
    @(negedge clk) rst = 1'b0;
    // 运行中多次异步复位：验证「大块异步复位 + perf 两拍链不复位」这个结构。
    // ★ 为什么是多次而不是一次 ★：复位窗口是「perf 链不复位」这条判据**唯一**的
    // 可观测窗口（perf 寄存器每拍无条件更新，复位一放开两拍就重新收敛）。姊妹模块
    // BloomFilter 实测：只打一次时同类变异只差出 5 个比对点，离 0 太近。所以打
    // RESETS 次、每次长度 2/3/4 轮换，让判据有余量。
    for (int k = 0; k < RESETS; k++) begin
      repeat (NCYCLES / (RESETS + 1)) @(posedge clk);
      @(negedge clk) rst = 1'b1; cov_reset_mid++;
      repeat (2 + (k % 3)) @(posedge clk);
      @(negedge clk) rst = 1'b0;
    end
    repeat (NCYCLES / (RESETS + 1)) @(posedge clk);

    $display("--- COVERAGE (标 * 的每项必须 > 0) ---");
    $display("* allowEnq 落 0(满)        : %0d", cov_full);
    $display("* numValid >= 32           : %0d", cov_deep);
    $display("  numValid 峰值            : %0d", max_numvalid);
    $display("* numValid == 0(空)        : %0d", cov_empty);
    $display("* 旁路                     : %0d", cov_bypass);
    $display("* 旁路且本块 > 6 条        : %0d", cov_bypass_big);
    for (int k = 1; k <= 5; k++)
      $display("* 输出寄存器部分填充 = %0d  : %0d", k, cov_partial[k]);
    $display("* 输出寄存器 6 条全满      : %0d", cov_out_full);
    $display("* 移位读(i - validNum)     : %0d", cov_shift_read);
    $display("* 入队指针绕圈             : %0d", cov_enq_wrap);
    $display("* 出队指针绕圈             : %0d", cov_deq_wrap);
    $display("* bank 内指针绕圈          : %0d", cov_inbank_wrap);
    $display("* 非空时 flush             : %0d", cov_flush_nonempty);
    $display("* flush 归因 Control       : %0d", cov_flush_ctrl);
    $display("* flush 归因 MemVio        : %0d", cov_flush_memvio);
    $display("* flush 归因 其它          : %0d", cov_flush_other);
    $display("* stall = FetchFragBubble  : %0d", cov_stall_frag);
    $display("* stall = matchBubble      : %0d", cov_stall_match);
    $display("* stall = backReason       : %0d", cov_stall_back);
    $display("* 运行中异步复位           : %0d", cov_reset_mid);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && cov_full > 0 && cov_deep > 0 && cov_empty > 0 &&
        cov_bypass > 0 && cov_bypass_big > 0 &&
        cov_partial[1] > 0 && cov_partial[2] > 0 && cov_partial[3] > 0 &&
        cov_partial[4] > 0 && cov_partial[5] > 0 &&
        cov_out_full > 0 && cov_shift_read > 0 &&
        cov_enq_wrap > 0 && cov_deq_wrap > 0 && cov_inbank_wrap > 0 &&
        cov_flush_nonempty > 0 && cov_flush_ctrl > 0 && cov_flush_memvio > 0 &&
        cov_flush_other > 0 && cov_stall_frag > 0 && cov_stall_match > 0 &&
        cov_stall_back > 0 && cov_reset_mid >= RESETS)
      $display("TEST PASSED");
    else
      $display("TEST FAILED (errors=%0d 或覆盖项为 0)", errors);
    $finish;
  end

endmodule
'''


def main():
    ports = parse_ports()
    ins = [p for p in ports if p[0] == 'input' and p[2] not in ('clock', 'reset')]
    outs = [p for p in ports if p[0] == 'output']

    L = [HEADER]
    L.append('\n  // ---- 激励信号（两侧共用）----')
    for _, w, n in ins:
        L.append('  logic %-9s %s;' % (w, n))
    L.append('\n  // ---- golden 侧输出 ----')
    for _, w, n in outs:
        L.append('  logic %-9s g_%s;' % (w, n))
    L.append('  // ---- 重写侧输出 ----')
    for _, w, n in outs:
        L.append('  logic %-9s i_%s;' % (w, n))

    for inst, pfx in (('IBuffer u_golden', 'g_'), ('IBuffer_xs u_impl', 'i_')):
        L.append('\n  %s (' % inst)
        L.append('    .clock(clk), .reset(rst),')
        conn = ['.%s(%s)' % (n, n) for _, _, n in ins]
        conn += ['.%s(%s%s)' % (n, pfx, n) for _, _, n in outs]
        L.append(',\n'.join('    ' + c for c in conn))
        L.append('  );')

    payload = []
    for i in range(16):
        payload.append('        %d: begin' % i)
        payload.append('          io_in_bits_instrs_%d = 32\'($urandom);' % i)
        payload.append('          io_in_bits_pc_%d = 50\'($urandom);' % i)
        payload.append('          io_in_bits_foldpc_%d = 10\'($urandom);' % i)
        if i != 0:
            payload.append('          io_in_bits_pd_%d_valid = $urandom;' % i)
        payload.append('          io_in_bits_pd_%d_isRVC = $urandom;' % i)
        payload.append('          io_in_bits_pd_%d_brType = 2\'($urandom);' % i)
        payload.append('          io_in_bits_pd_%d_isCall = $urandom;' % i)
        payload.append('          io_in_bits_pd_%d_isRet = $urandom;' % i)
        payload.append('          io_in_bits_ftqOffset_%d_valid = $urandom;' % i)
        # 异常编码三选一分布：多数无异常，其余均匀落在 PF/GPF/AF/跨页/非法 RVC 上，
        # 保证 exceptionType 的 8 种编码与 exceptionVec 的 4 路译码都被走到。
        payload.append('          io_in_bits_exceptionType_%d = '
                       '($urandom_range(0,2)==0) ? 2\'($urandom_range(1,3)) : 2\'b00;' % i)
        payload.append('          io_in_bits_crossPageIPFFix_%d = ($urandom_range(0,3)==0);' % i)
        payload.append('          io_in_bits_illegalInstr_%d = ($urandom_range(0,3)==0);' % i)
        payload.append('          io_in_bits_triggered_%d = 4\'($urandom);' % i)
        payload.append('          io_in_bits_isLastInFtqEntry_%d = $urandom;' % i)
        payload.append('        end')
    drive = DRIVE.replace('{{PAYLOAD_CASE}}', '\n'.join(payload))

    cmp_lines = []
    for _, _, n in outs:
        cmp_lines.append('      `CHK("%s", g_%s, i_%s)' % (n, n, n))
    drive = drive.replace('{{COMPARE}}', '\n'.join(cmp_lines))
    L.append(drive)

    # set_topdown：38 位 reason 是 38 根独立端口，用一个任务按下标写
    td = ['\n  task automatic set_topdown(input int r, input logic v);',
          '    case (r)']
    for r in range(38):
        td.append('      %d: io_in_bits_topdown_info_reasons_%d = v;' % (r, r))
    td += ['      default: ;', '    endcase', '  endtask']
    L.append('\n'.join(td))

    L.append(COVER)

    (HERE / 'tb.sv').write_text('\n'.join(L) + '\n')
    print('gen.py: 写入 tb.sv （%d 输入 / %d 输出）' % (len(ins), len(outs)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
