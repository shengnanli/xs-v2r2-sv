#!/usr/bin/env python3
"""mutants.py —— IBuffer UT 的判别力负测（`make mutants`）。

为什么要有它：`errors=0` 只有在「注入真 bug 时 UT 会红」的前提下才有意义。
队列类模块尤其危险——上一轮 StoreQueue 就是给 604 个输入每拍独立均匀随机，
队列永远到不了满/顺序提交，3 seed × 200k 拍全绿却什么都没验。本 tb 用相位状态机
+ 覆盖闸来解决那个问题，本文件负责证明「相位真的带来了判别力」。

做法：把 rtl/ 与本目录复制进 neg_build/（已在 .gitignore 里，**变异不进库**），
逐个注入一个真 bug，跑 20k 拍，要求每个都被 UT 抓出来（errors > 0）。

★ 一条**故意不放进来**、且必须说清楚的 ★
  rtl 的 §8 说明了 golden 的「移位读越界 = 读第 0 项」（不是 0、也不是回绕），
  证据是 golden 的 _GEN_177 把 5/6/7 号位全填第 0 项。**但这一条 UT 抓不到**：
  越界只在 i < outputEntriesValidNum 时发生，而那时写使能正好是关的。
  把 pad 改成 '0 跑 20k 拍仍然 errors=0 —— 所以它不在 MUTANTS 列表里。
  这条语义由 FM 负责（次态函数逐位比），UT 这一侧诚实地承认覆盖不到。

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
RTLREL = pathlib.Path('rtl') / 'frontend'
RTL = ['IBuffer.sv']
NCYCLES = '20000'

MUTANTS = [
    ('M1  入队写选择用 0 号入队指针代替第 i 条的指针（16 条 lane 全写同一项）',
     "      enq_target[i]  = enq_value_q[enq_ptr_idx[i]];",
     "      enq_target[i]  = enq_value_q[0];"),

    ('M2  输出寄存器移位读方向反（validNum - i 而不是 i - validNum）',
     "    wire [SHW-1:0] shift_idx = SHW'(i) - SHW'(out_valid_num);",
     "    wire [SHW-1:0] shift_idx = SHW'(out_valid_num) - SHW'(i);"),

    ('M3  「这一格保持不动」的判据差一（>= 而不是 >）',
     "      out_hold[i] = out_full | (out_valid_num > CNT_W'(i));",
     "      out_hold[i] = out_full | (out_valid_num >= CNT_W'(i));"),

    ('M4  bank 推进判据差一（numOut >= validIdx 而不是 >）',
     "      bank_advance[b] = num_out > bank_valid_idx[b];",
     "      bank_advance[b] = num_out >= bank_valid_idx[b];"),

    ('M5  bank 指针复位值全 0（golden 是 0,1,2,3,4,5）',
     "      for (int i = 0; i < DECODE_W; i++)   deq_bank_q[i]   <= BANKPTR_W'(i);",
     "      for (int i = 0; i < DECODE_W; i++)   deq_bank_q[i]   <= BANKPTR_W'(0);"),

    ('M6  ★复位域★ 给 perf 两拍链加异步复位（golden 这一块**不复位**）',
     "  always_ff @(posedge clock) begin\n    perf_flush_s1   <= flush;",
     "  always_ff @(posedge clock or posedge reset) begin\n"
     "    if (reset) begin perf_flush_s2 <= 1'b0; perf_hungry_s2 <= 1'b0;\n"
     "                     perf_q1of4_s2 <= 1'b0; perf_q2of4_s2 <= 1'b0;\n"
     "                     perf_q3of4_s2 <= 1'b0; perf_q4of4_s2 <= 1'b0;\n"
     "                     perf_qfull_s2 <= 1'b0; perf_bubble_s2 <= 3'b0;\n"
     "                     perf_latency_s2 <= 1'b0; end\n"
     "    else begin\n    perf_flush_s1   <= flush;"),

    ('M7  反压阈值差一（<= 33 而不是 <= 32 条）',
     "                        < PTR_W'(IBUF_SIZE - PREDICT_W + 1));",
     "                        < PTR_W'(IBUF_SIZE - PREDICT_W + 2));"),

    ('M8  flush 不再强制放开 allowEnq',
     "      allow_enq_q <= flush\n                     | (PTR_W'",
     "      allow_enq_q <= 1'b0\n                     | (PTR_W'"),

    ('M9  旁路选择漏掉 in_valid（队列空 + Decode 能收就当有数据）',
     "  wire bypass_active = use_bypass & in_valid;",
     "  wire bypass_active = use_bypass;"),

    ('M10 异常编码优先级反（先看 fetchExcp 再看跨页）',
     "      enq_data[i].exceptionType = in_crosspage[i]      ? {1'b1, in_excp_type[i]}\n"
     "                                : (|in_excp_type[i])   ? {1'b0, in_excp_type[i]}\n"
     "                                                       : {in_illegal_instr[i], 2'b00};",
     "      enq_data[i].exceptionType = (|in_excp_type[i])   ? {1'b0, in_excp_type[i]}\n"
     "                                : in_crosspage[i]      ? {1'b1, in_excp_type[i]}\n"
     "                                                       : {in_illegal_instr[i], 2'b00};"),

    ('M11 outputEntriesValidNum 把第 5 项也算进去（Chisel 只算 0..4）',
     "    for (int i = 0; i < DECODE_W - 1; i++)",
     "    for (int i = 0; i < DECODE_W; i++)"),

    ('M12 ftqOffset 不用槽号常数而用 0',
     "      enq_data[i].ftqOffset    = 4'(i);",
     "      enq_data[i].ftqOffset    = 4'(0);"),

    ('M13 ★不能只信 Chisel★ backendException 按 Chisel 的 Vec(16) 广播到全部 lane\n'
     '      （golden 只有 lane0 有端口，其余 15 路恒 0）',
     "  wire [15:0]       core_in_backexcp  = {15'h0, io_in_bits_backendException_0};",
     "  wire [15:0]       core_in_backexcp  = {16{io_in_bits_backendException_0}};"),

    ('M14 lane0 的 pd.valid 常数折错（golden 折成 1）',
     "       1'b1};",
     "       1'b0};"),
]


def prepare():
    if BUILD.exists():
        shutil.rmtree(BUILD)
    (BUILD / RTLREL).mkdir(parents=True)
    (BUILD / 'verif' / 'ut' / 'IBuffer').mkdir(parents=True)
    (BUILD / 'scripts').symlink_to(REPO / 'scripts')
    restore()
    for f in ('Makefile', 'tb.sv'):
        shutil.copy(HERE / f, BUILD / 'verif' / 'ut' / 'IBuffer' / f)


def restore():
    for f in RTL:
        shutil.copy(REPO / RTLREL / f, BUILD / RTLREL / f)


def run_ut():
    ut = BUILD / 'verif' / 'ut' / 'IBuffer'
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
    for name, old, new in MUTANTS:
        restore()
        tgt = BUILD / RTLREL / 'IBuffer.sv'
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
        print('  %-78s errors=%-8d %s'
              % (name.splitlines()[0], res[1], 'CAUGHT' if ok else '★MISSED★'))
        if not ok:
            missed.append(name)
    restore()
    if missed:
        print('=== MUTANTS FAILED：以下变异没被 UT 抓到 ===')
        for m in missed:
            print('   ', m)
        return 1
    print('=== MUTANTS PASSED：%d/%d 个变异全部被 UT 抓到 ===' % (len(MUTANTS), len(MUTANTS)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
