#!/usr/bin/env python3
"""mutants.py —— NCBTransactionQueue 家族 UT 的判别力负测（`make mutants`）。

为什么要有它：`errors=0` 只有在「注入真 bug 时 UT 会红」的前提下才有意义。本轮
工程里已经踩过多次「看起来在验、实际没在验」——最典型的是给每个输入每拍独立均匀
随机，队列的满/空/同拍多口撞同槽这些边界一次都打不到，3 seed × 200k 拍什么都没验。

本模块还多一层理由：tb 有**暖机**（见 tb.sv 文件头）。暖机把 20 个不复位寄存器写成
确定值之后，两轮 initreg 必然都绿 —— 那两轮于是证明不了复位域。★所以 M9/M10 两个
复位域变异是这里最关键的两条★：它们靠 tb 里的**中途异步复位**才被抓到，
如果哪天把中途复位删了，这两条会立刻变成 MISSED，闸就会响。

★余量是量出来的，不是估的★（20k 拍 / seed 1，本仓 commit 见 git log）：
  M4 102393  M3 28423  M5 27658  M15 19613  M9 12044  M2 10665  M12 10382
  M13 6785   M14 6749  M11 5055  M8 1733    M1 1480   M10 560   M6 471   M7 127
最薄的三条点名：M7(127)、M6(471)、M10(560)。M10 一开始只有 **16** ——
tb 当时只在中途打一次异步复位；改成打 20 次之后升到 560。M7 薄是因为
「自依赖(order.index == 自己的槽号)」要靠 focus 小池子撞出来，本来就稀。
UT 正式跑的是 200k 拍（10 倍），所以正式一轮里这三条各约 1.3k / 4.7k / 5.6k。

做法：把 rtl/ 与本目录复制进 neg_build/（已在 .gitignore 里，**变异不进库**），
逐个注入一个真 bug，跑 20k 拍，要求每个都被 UT 抓出来（errors > 0）。

用法: python3 mutants.py      （或 make mutants）
"""
import pathlib
import re
import shutil
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent.parent
BUILD = HERE / 'neg_build'
CORE = 'xs_NCBTransactionQueue_core.sv'

# (说明, 改哪个文件, 锚点, 替换)
MUTANTS = [
    ('M1 valid 优先级翻转：释放压过分配（golden 是分配压过释放）',
     CORE,
     "        entry_valid_q[i] <= alloc_hit[i] | (~free_strb[i] & entry_valid_q[i]);",
     "        entry_valid_q[i] <= ~free_strb[i] & (alloc_hit[i] | entry_valid_q[i]);"),

    ('M2 op 位优先级翻转：分配压过清除（golden 是清除压过分配）',
     CORE,
     """        op_comp_valid_q[i] <=
            ~(txrsp_op_done_strb[i] & txrsp_op_done_comp)
          & (alloc_hit[i] ? alloc_op.chi_comp_valid : op_comp_valid_q[i]);""",
     """        op_comp_valid_q[i] <=
            alloc_hit[i] ? alloc_op.chi_comp_valid
                         : (~(txrsp_op_done_strb[i] & txrsp_op_done_comp)
                            & op_comp_valid_q[i]);"""),

    ('M3 axi Critical 优先级翻转：W 压过 R（golden 是 R > W > allocate）',
     CORE,
     """      if (r_operand_axi_write_strb[i]) begin
        axi_critical_q[i] <= r_operand_axi_write_critical;
        axi_count_q[i]    <= r_operand_axi_write_count;
      end else if (w_operand_write_strb[i]) begin
        axi_critical_q[i] <= w_operand_write_critical;
        axi_count_q[i]    <= w_operand_write_count;""",
     """      if (w_operand_write_strb[i]) begin
        axi_critical_q[i] <= w_operand_write_critical;
        axi_count_q[i]    <= w_operand_write_count;
      end else if (r_operand_axi_write_strb[i]) begin
        axi_critical_q[i] <= r_operand_axi_write_critical;
        axi_count_q[i]    <= r_operand_axi_write_count;"""),

    ('M4 chi Critical 优先级翻转：allocate 压过 TXDAT.operandWrite',
     CORE,
     """      if (txdat_operand_write_strb[i]) begin
        chi_critical_q[i] <= txdat_operand_write_critical;
        chi_count_q[i]    <= txdat_operand_write_count;
      end else if (alloc_hit[i]) begin""",
     """      if (alloc_hit[i]) begin
        chi_critical_q[i] <= alloc_chi_critical;
        chi_count_q[i]    <= alloc_chi_count;
      end else if (txdat_operand_write_strb[i]) begin"""),

    ('M5 CompData 清除漏掉 Count==0 条件（末拍才算做完）',
     CORE,
     "            ~(txdat_op_done_strb[i] & txdat_op_done_compdata & (chi_count_q[i] == '0))",
     "            ~(txdat_op_done_strb[i] & txdat_op_done_compdata)"),

    ('M6 释放判据误用 ready（golden 用的是不带屏障的 raw valid）',
     CORE,
     "                   & ~(op_comp_valid_q[i]         | op_dbidresp_valid_q[i]",
     "                   & ~((op_comp_valid_q[i] & ~op_comp_barrier_q[i]) "
     "| op_dbidresp_valid_q[i]"),

    ('M7 前序依赖网络漏掉「排除自己」（j==i 也算命中）',
     CORE,
     "          if (i != j) begin",
     "          if (1) begin"),

    ('M8 order.valid 的分配分支与释放清除并行（golden 是 if/else，分配拍不看 free）',
     CORE,
     """        end else begin
          // ★只有在**没有**分配的拍才看 free 清除★ —— golden 是 if/else，
          // 不是两条独立的 when。分配拍上 order_valid 完全由上面那行决定。
          order_valid_q[i] <= ~free_order_hit[i] & order_valid_q[i];
        end""",
     """        end
        if (~free_order_hit[i] == 1'b0) order_valid_q[i] <= 1'b0;
        if (!alloc_hit[i]) begin
          order_valid_q[i] <= ~free_order_hit[i] & order_valid_q[i];
        end"""),

    ('M9 ★复位域★给 info/地址加复位（golden 这 20 个寄存器一个都不复位）',
     CORE,
     """  always_ff @(posedge clock) begin
    for (int i = 0; i < N; i++) begin
      if (alloc_hit[i]) begin""",
     """  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      info_q <= '0; chi_addr_q <= '0; axi_addr_q <= '0;
      chi_write_full_q <= '0; chi_write_ptl_q <= '0;
      axi_size_q <= '0; axi_len_q <= '0;
    end else
    for (int i = 0; i < N; i++) begin
      if (alloc_hit[i]) begin"""),

    ('M10 ★复位域★去掉 op_comp_valid 的复位（golden 每槽 14/15 位都复位到 0）',
     CORE,
     "      op_comp_valid_q         <= '0;\n",
     ""),

    ('M11 Burst 不经 ValidMux（strobe 全零时也输出 INCR，golden 输出 0）',
     CORE,
     "  assign aw_operand_read_burst = (|aw_operand_read_strb) ? AXI_BURST_INCR : '0;",
     "  assign aw_operand_read_burst = AXI_BURST_INCR;"),

    ('M12 TXDAT 冒泡漏掉前序依赖门控',
     CORE,
     "  assign txdat_op_valid = op_compdata_valid_q & ~order_blocks;",
     "  assign txdat_op_valid = op_compdata_valid_q;"),

    ('M13 ReadReceipt 屏障的分配值取成 0（golden 折成常数 1）',
     CORE,
     "          rr_barrier_q[i] <= ~ar_op_done_strb[i] & (alloc_hit[i] | rr_barrier_q[i]);",
     "          rr_barrier_q[i] <= ~ar_op_done_strb[i] & (alloc_hit[i] ? 1'b0 "
     ": rr_barrier_q[i]);"),

    ('M14 AR 的 Device 读口误用 AW 的 strobe',
     CORE,
     "    assign ar_operand_read_device = |(ar_operand_read_strb & axi_device_q);",
     "    assign ar_operand_read_device = |(aw_operand_read_strb & axi_device_q);"),

    ('M15 wrapper 把 Critical 两拍接反（位序错）',
     'NCBTransactionQueue_1.sv',
     "  assign alloc_chi_critical = {io_allocate_bits_operand_chi_Critical_1, "
     "io_allocate_bits_operand_chi_Critical_0};",
     "  assign alloc_chi_critical = {io_allocate_bits_operand_chi_Critical_0, "
     "io_allocate_bits_operand_chi_Critical_1};"),
]

RTL = [CORE, 'NCBTransactionQueue.sv', 'NCBTransactionQueue_1.sv']
NCYCLES = '20000'


def prepare():
    if BUILD.exists():
        shutil.rmtree(BUILD)
    (BUILD / 'rtl' / 'uncore').mkdir(parents=True)
    (BUILD / 'verif' / 'ut' / 'NCBTransactionQueue').mkdir(parents=True)
    (BUILD / 'scripts').symlink_to(REPO / 'scripts')
    for f in RTL:
        shutil.copy(REPO / 'rtl' / 'uncore' / f, BUILD / 'rtl' / 'uncore' / f)
    for f in ('Makefile', 'tb.sv'):
        shutil.copy(HERE / f, BUILD / 'verif' / 'ut' / 'NCBTransactionQueue' / f)


def restore():
    for f in RTL:
        shutil.copy(REPO / 'rtl' / 'uncore' / f, BUILD / 'rtl' / 'uncore' / f)


def run_ut():
    ut = BUILD / 'verif' / 'ut' / 'NCBTransactionQueue'
    subprocess.run(['make', 'run', 'SEED=1', 'NCYCLES=' + NCYCLES], cwd=str(ut),
                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                   universal_newlines=True)
    log = ut / 'sim_1.log'
    if not log.exists():
        return None
    m = re.search(r'checks=(\d+) errors=(\d+)', log.read_text())
    return (int(m.group(1)), int(m.group(2))) if m else None


def main():
    prepare()
    print('=== 基线（未变异，%s 拍）===' % NCYCLES)
    base = run_ut()
    if base is None or base[1] != 0:
        print('基线就不是 errors=0，负测无意义：', base)
        return 2
    print('    checks=%d errors=%d' % base)
    missed = []
    for name, fname, old, new in MUTANTS:
        restore()
        tgt = BUILD / 'rtl' / 'uncore' / fname
        t = tgt.read_text()
        if old not in t:
            print('!! %s：锚点没找到，变异未生效（源码改过？请同步本文件）' % name)
            missed.append(name)
            continue
        tgt.write_text(t.replace(old, new, 1))
        res = run_ut()
        if res is None:
            print('!! %s：编译/运行失败，不算「被抓到」' % name)
            missed.append(name)
            continue
        ok = res[1] > 0
        print('  %-62s checks=%d errors=%-8d %s'
              % (name, res[0], res[1], 'CAUGHT' if ok else '★MISSED★'))
        if not ok:
            missed.append(name)
    restore()
    if missed:
        print('=== MUTANTS FAILED：以下变异没被 UT 抓到 ===')
        for m in missed:
            print('   ', m)
        return 1
    print('=== MUTANTS PASSED：%d/%d 个变异全部被 UT 抓到 ==='
          % (len(MUTANTS), len(MUTANTS)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
