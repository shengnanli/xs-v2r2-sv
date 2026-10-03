#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_redirectgen.py —— RedirectGenerator 的机械派生区生成器（G1 golden 端口表驱动）。

产出（原地替换 BEGIN/END GENERATED 标记之间的内容，手写区不碰）：
  rtl/backend/RedirectGenerator.sv
      redirect_struct     : redirectgen_pkg 里的 cfi_update_t / redirect_t（字段表见 FIELDS）
      redirectgen_wrapper : golden 同名 wrapper（端口表逐字来自 golden，struct 打包/拆包）
  verif/ut/RedirectGenerator/tb.sv        双例化随机比对 testbench（整文件）

字段表 FIELDS 是唯一事实源：struct 字段顺序、宽度、golden 展平名、load 侧是否存在。
★不产钉点文件★：Formality 把 packed struct 寄存器按字段名展平
（s1_bits_reg[cfiUpdate][NOS_value][k]），diagnostic 实测（2026-09-24，commit 558d6240，
无钉点）ref/impl 561+ 位全部原生配对：passing 1216 = 615 DFF + 601 Port、unmatched 0(0)、
unread 0。早先那版按 s1_bits_reg[<位偏移>] 钉的文件是错的（FM-036 Unknown name），已删。

用法: python3 scripts/gen_redirectgen.py [--check]
"""
import pathlib, re, sys

XSSV = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl/RedirectGenerator.sv')
RTL = XSSV / 'rtl/backend/RedirectGenerator.sv'
UT = XSSV / 'verif/ut/RedirectGenerator'

# (struct 字段名, 位宽, golden 展平名后缀(相对 io_*Redirect_bits_ / s1_redirect_bits_reg_), 是否在 loadReplay 端口里)
# cfiUpdate 子结构单列；其余为 redirect_t 顶层字段。顺序 = golden 端口表顺序。
TOP_HEAD = [
    ('isRVC',        1, 'isRVC',        True),
    ('robIdx.flag',  1, 'robIdx_flag',  True),    # rob_ptr_t robIdx（核里按环形指针比较）
    ('robIdx.value', 8, 'robIdx_value', True),
    ('ftqIdx_flag',  1, 'ftqIdx_flag',  True),
    ('ftqIdx_value', 6, 'ftqIdx_value', True),
    ('ftqOffset',    4, 'ftqOffset',    True),
    ('level',        1, 'level',        True),
    ('interrupt',    1, 'interrupt',    False),
]
FH_W = {17: 11, 16: 11, 15: 7, 14: 8, 13: 9, 12: 4, 11: 8, 10: 9, 9: 7, 8: 8,
        7: 7, 6: 9, 5: 7, 4: 8, 3: 8, 2: 8, 1: 11, 0: 8}
CFI = [('pc', 50, 'cfiUpdate_pc', True),
       ('ssp', 4, 'cfiUpdate_ssp', False), ('sctr', 3, 'cfiUpdate_sctr', False),
       ('TOSW_flag', 1, 'cfiUpdate_TOSW_flag', False), ('TOSW_value', 5, 'cfiUpdate_TOSW_value', False),
       ('TOSR_flag', 1, 'cfiUpdate_TOSR_flag', False), ('TOSR_value', 5, 'cfiUpdate_TOSR_value', False),
       ('NOS_flag', 1, 'cfiUpdate_NOS_flag', False), ('NOS_value', 5, 'cfiUpdate_NOS_value', False),
       ('topAddr', 50, 'cfiUpdate_topAddr', False)]
CFI += [(f'folded_hist_{i}', FH_W[i], f'cfiUpdate_folded_hist_hist_{i}_folded_hist', False) for i in range(17, -1, -1)]
CFI += [(f'afhob_{i}_{b}', 1, f'cfiUpdate_afhob_afhob_{i}_bits_{b}', False) for i in range(5, -1, -1) for b in range(4)]
CFI += [('lastBrNumOH', 3, 'cfiUpdate_lastBrNumOH', False), ('ghr', 4, 'cfiUpdate_ghr', False),
        ('histPtr_flag', 1, 'cfiUpdate_histPtr_flag', False), ('histPtr_value', 8, 'cfiUpdate_histPtr_value', False),
        ('specCnt_0', 10, 'cfiUpdate_specCnt_0', False), ('specCnt_1', 10, 'cfiUpdate_specCnt_1', False),
        ('br_hit', 1, 'cfiUpdate_br_hit', False), ('jr_hit', 1, 'cfiUpdate_jr_hit', False),
        ('sc_hit', 1, 'cfiUpdate_sc_hit', False), ('predTaken', 1, 'cfiUpdate_predTaken', False),
        ('target', 50, 'cfiUpdate_target', True), ('taken', 1, 'cfiUpdate_taken', False),
        ('isMisPred', 1, 'cfiUpdate_isMisPred', False), ('shift', 2, 'cfiUpdate_shift', False),
        ('addIntoHist', 1, 'cfiUpdate_addIntoHist', False),
        ('backendIGPF', 1, 'cfiUpdate_backendIGPF', False), ('backendIPF', 1, 'cfiUpdate_backendIPF', False),
        ('backendIAF', 1, 'cfiUpdate_backendIAF', False)]
TOP_TAIL = [
    ('fullTarget',     64, 'fullTarget',     False),
    ('satpFlush',       1, 'satpFlush',      False),
    ('isVlsException',  1, 'isVlsException', False),
    ('stFtqIdx_flag',   1, 'stFtqIdx_flag',  True),
    ('stFtqIdx_value',  6, 'stFtqIdx_value', True),
    ('stFtqOffset',     4, 'stFtqOffset',    True),
    ('debug_runahead_checkpoint_id', 64, 'debug_runahead_checkpoint_id', True),
    ('debugIsCtrl',     1, 'debugIsCtrl',    False),
    ('debugIsMemVio',   1, 'debugIsMemVio',  None),   # 端口里没有：s1 里由 one-hot 决定（exu 0 / load 1）
]
# 展平后的顺序（struct 位从 MSB 起）：TOP_HEAD, cfiUpdate(CFI), TOP_TAIL
FLAT = [(n, w, g, l) for (n, w, g, l) in TOP_HEAD] + \
       [('cfiUpdate.' + n, w, g, l) for (n, w, g, l) in CFI] + \
       [(n, w, g, l) for (n, w, g, l) in TOP_TAIL]
TOTAL = sum(w for _, w, _, _ in FLAT)


def offsets():
    """packed struct：表首字段在 MSB。返回 {golden_suffix: (lo, w)}。"""
    out, hi = {}, TOTAL - 1
    for n, w, g, l in FLAT:
        out[g] = (hi - w + 1, w)
        hi -= w
    assert hi == -1
    return out


def sv_struct():
    def decl(fields):
        out, seen = [], set()
        for n, w, _, _ in fields:
            if '.' in n:                       # 嵌套子结构：只声明一次
                s = n.split('.')[0]
                if s not in seen:
                    seen.add(s); out.append(f'    rob_ptr_t {s};')
                continue
            out.append(f'    logic {("[%d:0] " % (w-1)) if w > 1 else ""}{n};')
        return '\n'.join(out)
    return (f"  // 分支/预测器更新信息（Chisel CfiUpdateInfo；golden 端口序）\n"
            f"  typedef struct packed {{\n{decl(CFI)}\n  }} cfi_update_t;\n\n"
            f"  // 重定向（Chisel Redirect；exu 与 load 两源的字段并集，共 {TOTAL} 位）\n"
            f"  typedef struct packed {{\n{decl(TOP_HEAD)}\n    cfi_update_t cfiUpdate;\n{decl(TOP_TAIL)}\n  }} redirect_t;")


def parse_ports():
    text = GOLDEN.read_text()
    m = re.search(r'^module RedirectGenerator\((.*?)\n\);', text, re.S | re.M)
    ports = []
    for line in m.group(1).splitlines():
        pm = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$', line)
        if pm:
            ports.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return ports


def sv_wrapper(ports):
    L = ['module RedirectGenerator(']
    L.append(',\n'.join(f'  {d:6s} {("[%d:0] " % (w-1)) if w > 1 else ""}{n}' for d, w, n in ports) + '\n);')
    L.append('  import redirectgen_pkg::*;')
    L.append('  redirect_t exu_bits, load_bits, stage2_bits;')
    L.append('  predecode_t stage2_pd;')
    names = {n for _, _, n in ports}
    # exu / load 打包
    for src, pre in (('exu', 'io_oldestExuRedirect_bits_'), ('load', 'io_loadReplay_bits_')):
        L.append(f'  always_comb begin\n    {src}_bits = \'0;')
        for n, w, g, l in FLAT:
            p = pre + g
            if p in names:
                L.append(f'    {src}_bits.{n} = {p};')
        if src == 'load':
            L.append('    load_bits.debugIsMemVio = 1\'b1;   // load 回放来源恒 1（golden 寄存 one-hot[1]）')
        L.append('  end')
    # stage2 拆包
    for n, w, g, l in FLAT:
        p = 'io_stage2Redirect_bits_' + g
        assert p in names, p
        L.append(f'  assign {p} = stage2_bits.{n};')
    for f in ('valid', 'isRVC', 'brType', 'isCall', 'isRet'):
        L.append(f'  assign io_stage2Redirect_bits_cfiUpdate_pd_{f} = stage2_pd.{f};')
    L.append('''
  xs_RedirectGenerator_core u_core (
    .clock              (clock),
    .reset              (reset),
    .exu_valid          (io_oldestExuRedirect_valid),
    .exu_bits           (exu_bits),
    .exu_isCSR          (io_oldestExuRedirectIsCSR),
    .instrAddrTransType ('{bare: io_instrAddrTransType_bare, sv39: io_instrAddrTransType_sv39,
                           sv39x4: io_instrAddrTransType_sv39x4, sv48: io_instrAddrTransType_sv48,
                           sv48x4: io_instrAddrTransType_sv48x4}),
    .exu_predecode      ('{valid: io_oldestExuOutPredecode_valid, isRVC: io_oldestExuOutPredecode_isRVC,
                           brType: io_oldestExuOutPredecode_brType, isCall: io_oldestExuOutPredecode_isCall,
                           isRet: io_oldestExuOutPredecode_isRet}),
    .load_valid         (io_loadReplay_valid),
    .load_bits          (load_bits),
    .robFlush_valid     (io_robFlush_valid),
    .robFlush_robIdx    ('{flag: io_robFlush_bits_robIdx_flag, value: io_robFlush_bits_robIdx_value}),
    .robFlush_level     (io_robFlush_bits_level),
    .memPredPcRead_data (io_memPredPcRead_data),
    .stage2_valid       (io_stage2Redirect_valid),
    .stage2_bits        (stage2_bits),
    .stage2_pd          (stage2_pd),
    .stage2_oldestOH    (io_stage2oldestOH),
    .memPredUpdate_valid(io_memPredUpdate_valid),
    .memPredUpdate_waddr(io_memPredUpdate_waddr),
    .memPredUpdate_ldpc (io_memPredUpdate_ldpc),
    .memPredUpdate_stpc (io_memPredUpdate_stpc)
  );
endmodule''')
    return '\n'.join(L)


def gen_tb(ports):
    ins = [(w, n) for d, w, n in ports if d == 'input' and n not in ('clock', 'reset')]
    outs = [(w, n) for d, w, n in ports if d == 'output']
    L = ['''// 自动生成：scripts/gen_redirectgen.py —— 勿手改（make gencheck 校验）
// RedirectGenerator UT：golden 与 RedirectGenerator_xs 双例化同激励逐拍比对
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  int unsigned cyc = 0;
  int cov_s2 = 0, cov_load_win = 0, cov_flushed = 0, cov_mempred = 0, cov_robflush = 0, cov_ipf = 0, cov_iaf = 0, cov_igpf = 0;
  always #5 clk = ~clk;
  always @(negedge clk) if (!rst) cyc <= cyc + 1;
''']
    for w, n in ins:
        L.append(f'  logic {("[%d:0] " % (w-1)) if w > 1 else ""}{n};')
    for w, n in outs:
        L.append(f'  logic {("[%d:0] " % (w-1)) if w > 1 else ""}g_{n}, i_{n};')
    conn = ', '.join(f'.{n}({n})' for _, n in ins)
    L.append(f'  RedirectGenerator g_u (.clock(clk), .reset(rst), {conn}, ' + ', '.join(f'.{n}(g_{n})' for _, n in outs) + ');')
    L.append(f'  RedirectGenerator_xs i_u (.clock(clk), .reset(rst), {conn}, ' + ', '.join(f'.{n}(i_{n})' for _, n in outs) + ');')
    L.append('''
  function automatic logic [63:0] rnd64(); return {$urandom(), $urandom()}; endfunction
  // 全随机一拍
  task automatic drive_random();''')
    for w, n in ins:
        if n in ('io_oldestExuRedirect_valid', 'io_loadReplay_valid'):
            L.append(f'    {n} = ($urandom_range(0, 99) < 30);')
        elif n == 'io_robFlush_valid':
            L.append(f'    {n} = ($urandom_range(0, 99) < 5);')
        elif n.endswith('robIdx_value'):
            # robIdx 取小范围让 needFlush / 最老比较两种结果都常出现
            L.append(f'    {n} = 8\'($urandom_range(0, 15));')
        elif n.startswith('io_instrAddrTransType_'):
            L.append(f'    {n} = 1\'($urandom);')
        elif w <= 32:
            L.append(f'    {n} = {w}\'($urandom);')
        else:
            L.append(f'    {n} = {w}\'(rnd64());')
    L.append('''    // 目标高位常做成符号扩展/零扩展形态，让 IPF/IAF/IGPF 的两个分支都走到
    if ($urandom_range(0, 1)) io_oldestExuRedirect_bits_fullTarget[63:50] = {14{io_oldestExuRedirect_bits_cfiUpdate_target[38]}};
    if ($urandom_range(0, 1)) io_oldestExuRedirect_bits_cfiUpdate_target[49:39] = {11{io_oldestExuRedirect_bits_cfiUpdate_target[38]}};
  endtask
''')
    L.append('  always @(negedge clk) if (!rst && cyc > 8) begin\n    #4; checks++;')
    for w, n in outs:
        L.append(f'    if (g_{n} !== i_{n}) begin errors++; if (errors <= 40) $display("[%0t] {n} g=%h i=%h", $time, g_{n}, i_{n}); end')
    L.append('''    if (g_io_stage2Redirect_valid) cov_s2++;
    if (g_io_stage2Redirect_valid && g_io_stage2oldestOH[1]) cov_load_win++;
    if ((io_oldestExuRedirect_valid || io_loadReplay_valid) && g_u.flushAfter_valid && !g_u.oldestValid) cov_flushed++;
    if (g_io_memPredUpdate_valid) cov_mempred++;
    if (io_robFlush_valid && g_u.s1_redirect_valid_reg_last_REG) cov_robflush++;
    if (g_io_stage2Redirect_valid && g_io_stage2Redirect_bits_cfiUpdate_backendIPF) cov_ipf++;
    if (g_io_stage2Redirect_valid && g_io_stage2Redirect_bits_cfiUpdate_backendIAF) cov_iaf++;
    if (g_io_stage2Redirect_valid && g_io_stage2Redirect_bits_cfiUpdate_backendIGPF) cov_igpf++;
  end

  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    drive_random();''')
    for w, n in ins:
        if n.endswith('_valid'):
            L.append(f'    {n} = 0;')
    L.append('''    rst = 1; repeat (4) @(posedge clk); @(negedge clk) rst = 0;
    // ★暖机★：s1 的 bits/预译码与 memPred 三个地址寄存器无复位，只在各自使能时写定。
    // 前 2 拍强制一个 exu 重定向（写定 s1 bits/pd），再 2 拍强制一个 load 回放（robIdx 在
    // flushAfter 之前、level=1 ⇒ 写定 memPred 地址寄存器），之后才开比对窗口。
    for (int k = 0; k < 4; k++) begin
      drive_random();
      io_robFlush_valid = 0;
      io_oldestExuRedirect_valid = (k < 2); io_loadReplay_valid = (k >= 2);
      io_oldestExuRedirect_bits_robIdx_flag = 0; io_oldestExuRedirect_bits_robIdx_value = 8'd200;
      io_loadReplay_bits_robIdx_flag = 0; io_loadReplay_bits_robIdx_value = 8'd10;
      io_loadReplay_bits_level = 1;
      @(negedge clk);
    end
    for (int unsigned n = 0; n < NCYCLES / 2; n++) begin drive_random(); @(negedge clk); end
    // 中途异步复位：复位域检验（flushAfter/s1 valid/one-hot/memPred valid 有复位，其余没有）
    @(negedge clk) rst = 1; repeat (3) @(posedge clk); @(negedge clk) rst = 0;
    for (int k = 0; k < 4; k++) begin
      drive_random();
      io_robFlush_valid = 0;
      io_oldestExuRedirect_valid = (k < 2); io_loadReplay_valid = (k >= 2);
      io_oldestExuRedirect_bits_robIdx_flag = 0; io_oldestExuRedirect_bits_robIdx_value = 8'd200;
      io_loadReplay_bits_robIdx_flag = 0; io_loadReplay_bits_robIdx_value = 8'd10;
      io_loadReplay_bits_level = 1;
      @(negedge clk);
    end
    for (int unsigned n = 0; n < NCYCLES / 2; n++) begin drive_random(); @(negedge clk); end
    $display("--- COVERAGE (每项必须 > 0) ---");
    $display("  stage2Redirect 有效        : %0d", cov_s2);
    $display("  load 回放胜出              : %0d", cov_load_win);
    $display("  被 flushAfter 作废         : %0d", cov_flushed);
    $display("  memPredUpdate 有效         : %0d", cov_mempred);
    $display("  robFlush 压掉 s2 valid     : %0d", cov_robflush);
    $display("  IPF / IAF / IGPF 置位      : %0d / %0d / %0d", cov_ipf, cov_iaf, cov_igpf);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000 && cov_s2 > 0 && cov_load_win > 0 && cov_flushed > 0 &&
        cov_mempred > 0 && cov_robflush > 0 && cov_ipf > 0 && cov_iaf > 0 && cov_igpf > 0)
      $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
''')
    return '\n'.join(L)






def main():
    check = '--check' in sys.argv
    ports = parse_ports()
    text = RTL.read_text()
    def sub(text, tag, body):
        pat = re.compile(r'(// BEGIN GENERATED\(' + re.escape(tag) + r'\)[^\n]*\n)(.*?)([ \t]*// END GENERATED)', re.S)
        m = pat.search(text); assert m, tag
        return text[:m.start()] + m.group(1) + body + '\n' + m.group(3) + text[m.end():]
    text = sub(text, 'redirect_struct', sv_struct())
    text = sub(text, 'redirectgen_wrapper', sv_wrapper(ports))
    outs = {RTL: text, UT / 'tb.sv': gen_tb(ports)}
    stale = [p for p, t in outs.items() if not p.exists() or p.read_text() != t]
    if check:
        for p in stale:
            print('STALE', p.relative_to(XSSV))
        return 1 if stale else 0
    UT.mkdir(parents=True, exist_ok=True)
    for p, t in outs.items():
        p.write_text(t)
    print(f'generated: {len(ports)} ports, redirect_t {TOTAL} bits')
    return 0


if __name__ == '__main__':
    sys.exit(main())
