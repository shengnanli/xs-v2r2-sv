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

★ 2026-09-17 自查：本文件此前有一个**真的会出假绿的 harness 洞** ★
  run_ut() 跑完直接读 sim_1.log。变异**编译失败**时 `make run` 不产生新日志，
  于是读到的是**上一个变异**留下的那份 —— 上一个是 CAUGHT(errors>0)，
  这一个就被记成 CAUGHT。IBuffer 的 M6 正是这样：它的替换文本少一个 `end`、
  VCS 报 Syntax error，而报告里它和 M5 的 errors 一模一样(77119)——
  数字撞车当时被我注意到了却没追下去，是 CONVENTIONS 那条新规矩点醒的。
  三处一起堵：
    (1) 每次跑之前**先删** sim_1.log；
    (2) `make run` 的返回码进判据，非 0 一律判 FAIL(不是 CAUGHT)；
    (3) 变异文本必须**真的改变了文件**，否则判 FAIL。
  另配 `--compile-only` 自检：只做替换+编译，不跑仿真，专门查"变异编不过"。

用法: python3 mutants.py [--compile-only]   （或 make mutants）
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
MODULE  = 'IBuffer'
MUTFILE = 'IBuffer.sv'

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

    # ★两处替换★：块首加 if(reset)/else，块尾补上配平的 end。
    # 旧版只改块首 → 少一个 end → VCS 语法错 → 旧 harness 读到上一轮日志 = 假 CAUGHT。
    ('M6  ★复位域★ 给 perf 两拍链加异步复位（golden 这一块**不复位**）',
     [("  always_ff @(posedge clock) begin\n    perf_flush_s1   <= flush;",
       "  always_ff @(posedge clock or posedge reset) begin\n"
       "    if (reset) begin\n"
       "      perf_flush_s2 <= 1'b0; perf_hungry_s2 <= 1'b0;\n"
       "      perf_q1of4_s2 <= 1'b0; perf_q2of4_s2 <= 1'b0;\n"
       "      perf_q3of4_s2 <= 1'b0; perf_q4of4_s2 <= 1'b0;\n"
       "      perf_qfull_s2 <= 1'b0; perf_bubble_s2 <= 3'b0;\n"
       "      perf_latency_s2 <= 1'b0;\n"
       "    end else begin\n    perf_flush_s1   <= flush;"),
      ("    perf_latency_s2 <= perf_latency_s1;\n  end",
       "    perf_latency_s2 <= perf_latency_s1;\n    end\n  end")]),

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


def _edits(ent):
    """MUTANTS 条目支持两种写法：
         (名字, [(old, new), ...])  —— **多处**替换，用于 M6 这种要同时改块首与块尾的
         (名字, old, new)           —— 单处替换
    多处那种是被 IBuffer M6 逼出来的：把无复位块改成带复位的 if/else，只改块首会少一个
    `end`，语法就坏了；而语法坏掉在旧 harness 下不报错、直接读到上一轮日志变成假 CAUGHT。
    """
    if len(ent) == 2:
        return list(ent[1])
    return [(ent[-2], ent[-1])]


def apply_mutant(tgt, base_text, edits):
    """返回 (是否成功施加, 新文本)。锚点找不到或文本没变都算失败。"""
    t = base_text
    for old, new in edits:
        if old not in t:
            return (False, t)
        t = t.replace(old, new, 1)
    if t == base_text:
        return (False, t)
    tgt.write_text(t)
    return (True, t)


def run_ut():
    """跑一轮 UT。★每次先删日志★，并把 make 的返回码一起带出来 ——
    编译失败时读到上一轮的日志，就是本文件此前的假绿来源。"""
    ut = BUILD / 'verif' / 'ut' / MODULE
    log = ut / 'sim_1.log'
    if log.exists():
        log.unlink()
    r = subprocess.run(['make', 'run', 'SEED=1', 'NCYCLES=' + NCYCLES], cwd=str(ut),
                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                       universal_newlines=True)
    if not log.exists():
        return (None, r.returncode, r.stdout[-2000:])
    m = re.search(r'checks=(\d+) errors=(\d+)', log.read_text())
    if not m:
        return (None, r.returncode, log.read_text()[-2000:])
    return ((int(m.group(1)), int(m.group(2))), r.returncode, '')


def main():
    compile_only = '--compile-only' in sys.argv
    prepare()
    base_text = (REPO / RTLREL / MUTFILE).read_text()
    tgt = BUILD / RTLREL / MUTFILE

    if compile_only:
        # 只查"变异编得过吗"，不跑仿真。用于快速自检锚点与语法。
        bad = []
        for ent in MUTANTS:
            restore()
            ok, _ = apply_mutant(tgt, base_text, _edits(ent))
            if not ok:
                print('  %-70s ★锚点失效/文本未变★' % ent[0].splitlines()[0])
                bad.append(ent[0])
                continue
            r = subprocess.run(['make', 'compile'],
                               cwd=str(BUILD / 'verif' / 'ut' / MODULE),
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                               universal_newlines=True)
            print('  %-70s %s' % (ent[0].splitlines()[0],
                                  'compiles' if r.returncode == 0 else '★编译失败★'))
            if r.returncode != 0:
                bad.append(ent[0])
        restore()
        print('=== COMPILE-ONLY: %d/%d 可编译 ===' % (len(MUTANTS) - len(bad), len(MUTANTS)))
        return 1 if bad else 0

    print('=== 基线（未变异，%s 拍）===' % NCYCLES)
    base, rc, tail = run_ut()
    if base is None or rc != 0 or base[1] != 0:
        print('基线就不是 errors=0（rc=%s），负测无意义：%s\n%s' % (rc, base, tail))
        return 2
    print('    checks=%d errors=%d' % base)

    missed = []
    for ent in MUTANTS:
        name = ent[0]
        restore()
        ok, _ = apply_mutant(tgt, base_text, _edits(ent))
        if not ok:
            print('!! %s：锚点失效或文本未改变 —— 变异没生效' % name.splitlines()[0])
            missed.append(name)
            continue
        res, rc, tail = run_ut()
        # ★判据是"日志里有没有本轮的 checks=/errors= 行"，不是 make 的返回码★
        # make run 对**被抓到的变异**本来就返回非 0（tb 打 TEST FAILED，Makefile 据此 exit 1），
        # 拿 rc 当判据会把"正确抓到"误判成"harness 坏了"（第一版硬化就这么错了一次）。
        # 真正堵住假绿的是 run_ut() 里**每次先删 sim_1.log**：编译失败就没有新日志，
        # res 为 None，落到下面判 FAIL，不会再读到上一个变异的结果。
        if res is None:
            print('!! %-66s ★没有产生本轮日志（编译/运行失败，rc=%s），判 FAIL★'
                  % (name.splitlines()[0], rc))
            missed.append(name)
            continue
        caught = res[1] > 0
        print('  %-70s errors=%-9d %s'
              % (name.splitlines()[0], res[1], 'CAUGHT' if caught else '★MISSED★'))
        if not caught:
            missed.append(name)
    restore()
    if missed:
        print('=== MUTANTS FAILED：以下变异没被 UT 抓到（或根本没生效）===')
        for x in missed:
            print('   ', x.splitlines()[0])
        return 1
    print('=== MUTANTS PASSED：%d/%d 个变异全部被 UT 抓到 ===' % (len(MUTANTS), len(MUTANTS)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
