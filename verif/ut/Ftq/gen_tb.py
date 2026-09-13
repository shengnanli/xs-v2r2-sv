#!/usr/bin/env python3
"""生成本目录的 tb.sv —— golden Ftq 与重写 Ftq_xs 双例化逐拍对照台。

Ftq 有 476 个端口（280 输入 / 196 输出），手写 tb 既不现实也不可维护：端口表
直接从 G1 golden 的 module Ftq(...) 解析出来，端口一变重跑本脚本即可。

用法:  python3 gen_tb.py tb.sv
"""
import re, sys

G1 = '/home/eda/xs-env/G1-canonical/golden-rtl/Ftq.sv'
OUT = sys.argv[1]

src = open(G1).read()
m = re.search(r'^module Ftq\(\s*(.*?)^\);', src, re.S | re.M)
ins, outs = [], []
for l in m.group(1).split('\n'):
    l = l.strip().rstrip(',')
    if not l: continue
    mm = re.match(r'(input|output)\s+(?:(\[[^\]]*\])\s+)?(\w+)$', l)
    assert mm, l
    (ins if mm.group(1) == 'input' else outs).append((mm.group(3), mm.group(2) or ''))
ins = [(n, w) for n, w in ins if n not in ('clock', 'reset')]
assert len(ins) + len(outs) == 474, (len(ins), len(outs))

# ---- 按“激励角色”给输入分类 ---------------------------------------------
# 手工驱动（协议相关，不能纯随机）：
HAND = {
  'io_fromBpu_resp_valid', 'io_toIfu_req_ready', 'io_toPrefetch_req_ready',
  'io_fromIfu_pdWb_valid', 'io_fromBackend_redirect_valid',
  'io_fromBackend_redirect_bits_satpFlush',
  'io_fromBackend_ftqIdxAhead_0_valid', 'io_fromBackend_ftqIdxAhead_0_bits_value',
  'io_fromBackend_ftqIdxSelOH_bits',
  'io_mmioCommitRead_valid',
  'io_mmioCommitRead_mmioFtqPtr_flag', 'io_mmioCommitRead_mmioFtqPtr_value',
  'io_fromBpu_resp_bits_s2_ftq_idx_flag', 'io_fromBpu_resp_bits_s2_ftq_idx_value',
  'io_fromBpu_resp_bits_s3_ftq_idx_flag', 'io_fromBpu_resp_bits_s3_ftq_idx_value',
  'io_fromIfu_pdWb_bits_ftqIdx_flag', 'io_fromIfu_pdWb_bits_ftqIdx_value',
  'io_fromBackend_redirect_bits_ftqIdx_flag', 'io_fromBackend_redirect_bits_ftqIdx_value',
}
for i in range(8):
    HAND |= {'io_fromBackend_rob_commits_%d_valid' % i,
             'io_fromBackend_rob_commits_%d_bits_ftqIdx_flag' % i,
             'io_fromBackend_rob_commits_%d_bits_ftqIdx_value' % i,
             'io_fromBackend_rob_commits_%d_bits_ftqOffset' % i}
# s1/s2/s3 valid 家族按 BPU 三级流水手工驱动
S_VALID = [n for n, _ in ins if re.match(r'io_fromBpu_resp_bits_s[123]_valid(_\d+)?$', n)]
HAND |= set(S_VALID)
RANDOM = [(n, w) for n, w in ins if n not in HAND]

def wid(w):
    if not w: return 1
    a, b = w.strip('[]').split(':'); return int(a) - int(b) + 1

L = []
A = L.append
A('// tb.sv —— Ftq UT：golden `Ftq` 与重写 `Ftq_xs` 双例化，同激励逐拍比全部 196 个输出。')
A('//')
A('// 激励不是均匀随机：Ftq 是 64 项环形取指目标队列，端口间有强协议约束')
A('// （s2/s3 预测覆盖必须带 s1 分配到的 ftqIdx、pdWb 只对已发过取指的块有效、')
A('//  rob 提交要把某一块的 16 个槽都标掉 commPtr 才推进）。纯随机会让队列永远')
A('//  在“刚入队就被冲刷”的状态里空转 —— errors=0 但什么都没测到。')
A('// 因此本 tb：')
A('//   · s2/s3 的 ftqIdx 取自 golden 的 io_toBpu_enq_ptr（= bpuPtr）延迟 1/2 拍，')
A('//     还原真实 BPU 三级流水的“同一块”语义；')
A('//   · pdWb 的 ftqIdx 跟着 io_toIfu_req 发出的块走（延迟若干拍模拟 IFU 预解码）；')
A('//   · rob 提交用一个缓慢推进的 commit_anchor 逐块逐槽扫，保证 commPtr 真能前进；')
A('//   · 后端 redirect 稀疏（~2%），其中约 1/3 带 satpFlush（G1 新增通路）。')
A('// 末尾有覆盖闸：任一关键事件计数为 0 直接判 FAIL —— 防“激励打不到的假绿”。')
A('`timescale 1ns/1ps')
A('module tb;')
A('  int unsigned NCYCLES = 200000;')
A('  bit clk = 0, rst;')
A('  longint errors = 0, checks = 0;')
A('  always #5 clk = ~clk;')
A('')
A('  // ---- 输入信号 ----')
for n, w in ins:
    A('  logic %s%s;' % ((w + ' ') if w else '', n))
A('')
A('  // ---- 输出：g_=golden, i_=impl ----')
for n, w in outs:
    A('  wire %s%s;' % ((w + ' ') if w else '', 'g_' + n))
    A('  wire %s%s;' % ((w + ' ') if w else '', 'i_' + n))
A('')
def inst(mod, pfx):
    A('  %s dut_%s (' % (mod, pfx))
    A('    .clock(clk), .reset(rst),')
    ls = ['    .%s(%s)' % (n, n) for n, _ in ins]
    ls += ['    .%s(%s%s)' % (n, pfx + '_', n) for n, _ in outs]
    A(',\n'.join(ls))
    A('  );')
inst('Ftq', 'g')
inst('Ftq_xs', 'i')
A('')
A('  // =========================================================================')
A('  // 激励生成')
A('  // =========================================================================')
A('  // bpuPtr 延迟链：BPU s1 在 bpuPtr 处分配块，s2 下一拍、s3 再下一拍带着同一 idx 回来')
A('  logic       enq_flag_d1, enq_flag_d2;')
A('  logic [5:0] enq_val_d1,  enq_val_d2;')
A('  // ifuPtr 延迟链：IFU 取完指再做预解码写回，延迟 4 拍近似')
A('  logic       ifu_flag_d [0:3];')
A('  logic [5:0] ifu_val_d  [0:3];')
A('  // 提交扫描锚点：保证某一块的 16 个槽都被标掉，commPtr 才会真的推进')
A('  logic [5:0] commit_idx;')
A('  logic [3:0] commit_off;')
A('  logic [5:0] mmio_idx;')
A('  int unsigned tick;')
A('')
A('  // 本拍的“事件抽签”结果，drive() 要用，故声明在前')
A('  bit s2_fire, s3_fire, be_redir, ahead_v;')
A('  logic [2:0] ahead_sel;')
A('')
A('  function automatic bit chance(int unsigned pct);')
A('    return ($urandom_range(0, 99) < pct);')
A('  endfunction')
A('')
A('  // ---- 覆盖计数（关键事件；为 0 即判失败）----')
A('  longint cov_bpu_enq_fire   = 0;   // BPU 预测块入队握手')
A('  longint cov_s2_redirect    = 0;   // s2 覆盖 s1（bpuPtr 回退）')
A('  longint cov_s3_redirect    = 0;   // s3 覆盖（bpuPtr 回退）')
A('  longint cov_ifu_req_fire   = 0;   // 向 IFU 发出取指请求握手')
A('  longint cov_pf_req_fire    = 0;   // 向 Prefetch 发出请求握手')
A('  longint cov_pdwb           = 0;   // IFU 预解码写回')
A('  longint cov_be_redirect    = 0;   // 后端重定向')
A('  longint cov_be_redir_ahead = 0;   // 后端重定向走 ftqIdxAhead 提前路径')
A('  longint cov_satp_redirect  = 0;   // ★后端重定向带 satpFlush（G1 新增）')
A('  longint cov_satp_out       = 0;   // ★io_toICache_req_bits_hasSatpFlush 拉高')
A('  longint cov_backend_exc    = 0;   // io_toICache_req_bits_backendException 拉高')
A('  longint cov_rob_commit     = 0;   // rob 提交')
A('  longint cov_bpu_update     = 0;   // 向 BPU 回送 update（出队训练）')
A('  longint cov_ifu_redirect   = 0;   // FTQ 向 IFU 发重定向')
A('  longint cov_icache_flush   = 0;   // icacheFlush')
A('  longint cov_mmio_read      = 0;   // mmioCommitRead.valid（G1 新增门控输入）')
A('  longint cov_mmio_lastcmt   = 0;   // mmioLastCommit 拉高')
A('  longint cov_bpu_stall      = 0;   // FTQ 反压 BPU（resp_ready=0）')
A('')
A('  always @(posedge clk) begin')
A('    if (rst) begin')
A('      enq_flag_d1 <= 0; enq_val_d1 <= 0; enq_flag_d2 <= 0; enq_val_d2 <= 0;')
A('      for (int k = 0; k < 4; k++) begin ifu_flag_d[k] <= 0; ifu_val_d[k] <= 0; end')
A('      commit_idx <= 0; commit_off <= 0; mmio_idx <= 0; tick <= 0;')
A('    end else begin')
A('      enq_flag_d1 <= g_io_toBpu_enq_ptr_flag;  enq_val_d1 <= g_io_toBpu_enq_ptr_value;')
A('      enq_flag_d2 <= enq_flag_d1;              enq_val_d2 <= enq_val_d1;')
A('      ifu_flag_d[0] <= g_io_toIfu_req_bits_ftqIdx_flag;')
A('      ifu_val_d[0]  <= g_io_toIfu_req_bits_ftqIdx_value;')
A('      for (int k = 1; k < 4; k++) begin')
A('        ifu_flag_d[k] <= ifu_flag_d[k-1]; ifu_val_d[k] <= ifu_val_d[k-1];')
A('      end')
A('      tick <= tick + 1;')
A('      // 提交锚点：每拍扫一个槽，扫满 16 槽换下一块 —— 这样 commPtr 一定能推进')
A('      if (commit_off == 4\'hF) begin commit_off <= 0; commit_idx <= commit_idx + 1; end')
A('      else commit_off <= commit_off + 1;')
A('      if (tick[4:0] == 0) mmio_idx <= mmio_idx + 1;')
A('    end')
A('  end')
A('')
A('  task automatic drive();')
A('    // ---- 纯随机字段（payload：pc/target/meta/ftb_entry/pd 等）----')
for n, w in RANDOM:
    W = wid(n and w)
    if W == 1:
        A('    %s = $urandom_range(0,1);' % n)
    elif W <= 32:
        A('    %s = %d\'($urandom());' % (n, W))
    else:
        parts = (W + 31) // 32
        A('    %s = %d\'({%s});' % (n, W, ', '.join(['$urandom()'] * parts)))
A('')
A('    // ---- BPU 三级预测流水 ----')
A('    io_fromBpu_resp_valid = chance(75);')
for n in sorted(S_VALID):
    st = re.match(r'io_fromBpu_resp_bits_s(\d)_valid', n).group(1)
    if st == '1':
        A('    %s = io_fromBpu_resp_valid;' % n)
    elif st == '2':
        A('    %s = s2_fire;' % n)
    else:
        A('    %s = s3_fire;' % n)
A('    // s2/s3 覆盖必须带 s1 当初分配到的 ftqIdx，否则 FTQ 认不出是同一块')
A('    io_fromBpu_resp_bits_s2_ftq_idx_flag  = enq_flag_d1;')
A('    io_fromBpu_resp_bits_s2_ftq_idx_value = enq_val_d1;')
A('    io_fromBpu_resp_bits_s3_ftq_idx_flag  = enq_flag_d2;')
A('    io_fromBpu_resp_bits_s3_ftq_idx_value = enq_val_d2;')
A('')
A('    // ---- IFU / Prefetch 背压 ----')
A('    io_toIfu_req_ready      = chance(85);')
A('    io_toPrefetch_req_ready = chance(85);')
A('')
A('    // ---- IFU 预解码写回：跟着已发出去的取指块走 ----')
A('    io_fromIfu_pdWb_valid          = chance(30);')
A('    io_fromIfu_pdWb_bits_ftqIdx_flag  = ifu_flag_d[3];')
A('    io_fromIfu_pdWb_bits_ftqIdx_value = ifu_val_d[3];')
A('')
A('    // ---- 后端重定向（稀疏）；ahead 路径与普通路径各占一半 ----')
A('    io_fromBackend_redirect_valid = be_redir;')
A('    io_fromBackend_redirect_bits_ftqIdx_flag  = ifu_flag_d[1];')
A('    io_fromBackend_redirect_bits_ftqIdx_value = ifu_val_d[1];')
A('    // ★G1 新增：satpFlush —— 只在真有重定向时才可能置 1（后端语义）')
A('    io_fromBackend_redirect_bits_satpFlush = be_redir & chance(35);')
A('    io_fromBackend_ftqIdxAhead_0_valid     = ahead_v;')
A('    io_fromBackend_ftqIdxAhead_0_bits_value= ifu_val_d[1];')
A('    io_fromBackend_ftqIdxSelOH_bits        = ahead_sel;')
A('')
A('    // ---- rob 提交：锚点逐槽扫 + 少量随机散点 ----')
for i in range(8):
    A('    io_fromBackend_rob_commits_%d_valid = chance(45);' % i)
    A('    io_fromBackend_rob_commits_%d_bits_ftqIdx_flag  = 1\'b0;' % i)
    A('    io_fromBackend_rob_commits_%d_bits_ftqIdx_value = chance(80) ? commit_idx' % i)
    A('                                                     : 6\'($urandom());')
    A('    io_fromBackend_rob_commits_%d_bits_ftqOffset = chance(80) ? commit_off' % i)
    A('                                                  : 4\'($urandom());')
A('')
A('    // ---- mmio 提交读（G1 新增 valid 门控）----')
A('    io_mmioCommitRead_valid = chance(25);')
A('    io_mmioCommitRead_mmioFtqPtr_flag  = 1\'b0;')
A('    io_mmioCommitRead_mmioFtqPtr_value = chance(70) ? commit_idx : mmio_idx;')
A('  endtask')
A('')
A('  always @(negedge clk) begin')
A('    s2_fire   = chance(20);')
A('    s3_fire   = chance(15);')
A('    be_redir  = chance(3);')
A('    ahead_v   = chance(4);')
A('    ahead_sel = chance(60) ? 3\'b001 : 3\'($urandom());')
A('    drive();')
A('  end')
A('')
A('  // =========================================================================')
A('  // 逐拍比对全部 %d 个输出' % len(outs))
A('  // =========================================================================')
A('  // drive() 在 negedge 打激励，这里在 posedge 采样 —— 不同事件，无竞争；')
A('  // 采到的是上一拍激励作用下已完全稳定的输出。')
A('  always @(posedge clk) if (!rst) begin')
for n, _ in outs:
    A('    if (!$isunknown(g_%s)) begin checks++;' % n)
    A('      if (g_%s !== i_%s) begin errors++;' % (n, n))
    A('        if (errors<=60) $display("[%%0t] %s g=%%h i=%%h", $time, g_%s, i_%s); end end'
      % (n, n, n))
A('  end')
A('')
A('  // ---- 覆盖统计 ----')
A('  always @(posedge clk) if (!rst) begin')
A('    if (io_fromBpu_resp_valid & g_io_fromBpu_resp_ready)   cov_bpu_enq_fire++;')
A('    if (io_fromBpu_resp_valid & ~g_io_fromBpu_resp_ready)  cov_bpu_stall++;')
A('    if (g_io_toIfu_flushFromBpu_s2_valid)                  cov_s2_redirect++;')
A('    if (g_io_toIfu_flushFromBpu_s3_valid)                  cov_s3_redirect++;')
A('    if (g_io_toIfu_req_valid & io_toIfu_req_ready)         cov_ifu_req_fire++;')
A('    if (g_io_toPrefetch_req_valid & io_toPrefetch_req_ready) cov_pf_req_fire++;')
A('    if (io_fromIfu_pdWb_valid)                             cov_pdwb++;')
A('    if (io_fromBackend_redirect_valid)                     cov_be_redirect++;')
A('    if (io_fromBackend_redirect_valid & io_fromBackend_ftqIdxAhead_0_valid)')
A('                                                           cov_be_redir_ahead++;')
A('    if (io_fromBackend_redirect_valid & io_fromBackend_redirect_bits_satpFlush)')
A('                                                           cov_satp_redirect++;')
A('    if (g_io_toICache_req_bits_hasSatpFlush === 1\'b1)       cov_satp_out++;')
A('    if (g_io_toICache_req_bits_backendException === 1\'b1)   cov_backend_exc++;')
A('    if (|{io_fromBackend_rob_commits_0_valid, io_fromBackend_rob_commits_1_valid,')
A('          io_fromBackend_rob_commits_2_valid, io_fromBackend_rob_commits_3_valid,')
A('          io_fromBackend_rob_commits_4_valid, io_fromBackend_rob_commits_5_valid,')
A('          io_fromBackend_rob_commits_6_valid, io_fromBackend_rob_commits_7_valid})')
A('                                                           cov_rob_commit++;')
A('    if (g_io_toBpu_update_valid === 1\'b1)                   cov_bpu_update++;')
A('    if (g_io_toIfu_redirect_valid === 1\'b1)                 cov_ifu_redirect++;')
A('    if (g_io_icacheFlush === 1\'b1)                          cov_icache_flush++;')
A('    if (io_mmioCommitRead_valid)                           cov_mmio_read++;')
A('    if (g_io_mmioCommitRead_mmioLastCommit === 1\'b1)        cov_mmio_lastcmt++;')
A('  end')
A('')
A('  initial begin')
A('    void\'($value$plusargs("ncycles=%d", NCYCLES));   // ut_common.mk 统一下发 200000')
A('    rst = 1; repeat (20) @(posedge clk); rst = 0;')
A('    repeat (NCYCLES) @(posedge clk);')
A('    $display("checks=%0d errors=%0d", checks, errors);')
A('    $display("--- coverage ---");')
COV = ['bpu_enq_fire','bpu_stall','s2_redirect','s3_redirect','ifu_req_fire','pf_req_fire',
       'pdwb','be_redirect','be_redir_ahead','satp_redirect','satp_out','backend_exc',
       'rob_commit','bpu_update','ifu_redirect','icache_flush','mmio_read','mmio_lastcmt']
for c in COV:
    A('    $display("  cov_%-16s = %%0d", cov_%s);' % (c, c))
A('    begin')
A('      int unsigned zero_cov = 0;')
for c in COV:
    A('      if (cov_%s == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_%s 从未发生"); end' % (c, c))
A('      if (errors == 0 && checks > 1000000 && zero_cov == 0) $display("TEST PASSED");')
A('      else begin')
A('        if (zero_cov != 0) $display("=== 覆盖闸不过：%0d 个关键事件计数为 0 ===", zero_cov);')
A('        if (checks <= 1000000) $display("=== checks=%0d 过少，激励没打进去 ===", checks);')
A('        $display("TEST FAILED");')
A('      end')
A('    end')
A('    $finish;')
A('  end')
A('endmodule')
open(OUT, 'w').write('\n'.join(L) + '\n')
print('wrote %s: %d lines, %d inputs (%d hand-driven, %d random), %d outputs'
      % (OUT, len(L), len(ins), len(ins) - len(RANDOM), len(RANDOM), len(outs)))
