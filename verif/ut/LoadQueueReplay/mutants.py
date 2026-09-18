#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""LoadQueueReplay 变异体靶子 —— 证明这套 UT 真有判别力。

规矩（CONVENTIONS「验证件自身的两个坑」）：
  1. 每个变异体必须**先自证改变了电路**。本 harness 的做法是三重：
       a) 打补丁后文本必须真的变了（old_str 必须命中且唯一）；
       b) 必须能编过 —— ★编不过判 FAIL，不许当成 CAUGHT★；
       c) 每次跑前删日志，杜绝读到上一轮的 errors。
     逻辑等价的"空变异"要剔除并注明理由；本表里 M3 是**结构**变异
     （3 个同源寄存器合成 1 个），不是空变异 —— 它改了网表里的触发器数，
     只是功能等价，所以按构造 UT 看不见、归 FM 管。
  2. CAUGHT 不是二值：报出每个变异抓到的 errors 数。余量薄的要点名。

用法:
  python3 mutants.py            # 跑全部
  python3 mutants.py M1 M7      # 只跑指定的
环境:
  MUT_CYCLES  每个变异体跑多少拍（默认 20000）
  MUT_SEED    种子（默认 1）
"""
import os
import pathlib
import re
import shutil
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent.parent
RTL = REPO / "rtl" / "memblock" / "LoadQueueReplay.sv"
GOLDEN = pathlib.Path("/home/eda/xs-env/G1-canonical/golden-rtl")
WORK = HERE / "mut_work"

CYCLES = int(os.environ.get("MUT_CYCLES", "20000"))
SEED = os.environ.get("MUT_SEED", "1")

# (id, 说明, 期望, old, new)
#   期望 = UT 是否应当抓到。EXPECTED_MISSED 读作「UT 观测不到，由 FM 兜底」，
#   不是「没人管」。
MUTANTS = [
    ("M1", "C_MF 解除条件退回 G0（用 lqIdx vs ldWbPtr，不用 robDeqPtr）", "CAUGHT",
     "      clr_MF  = ~rob_is_after(entRob, robDeqPtr);",
     "      clr_MF  = ~lq_is_after('{flag: uop[i].p.lqIdx_flag, value: uop[i].p.lqIdx_value}, ldWbPtr);"),

    ("M2", "把 G0 的 hasExceptions 门控补回 needEnqueue", "CAUGHT",
     "      assign needEnqueue[gi] = canEnqueue[gi] & ~cancelEnq[gi] & needReplay[gi];",
     "      assign needEnqueue[gi] = canEnqueue[gi] & ~cancelEnq[gi] & needReplay[gi]\n"
     "                             & ~(|(enq_uop[gi].exceptionVec & 24'h20_0028));"),

    ("M3", "把 golden 逐口三份的 D-channel 打拍寄存器合并成一份（功能等价、结构不等价）",
     "EXPECTED_MISSED",
     "                            & ~(tl_d_valid_q[w] & (tl_d_mshrid_q[w] == enq_mshr_id[w]));",
     "                            & ~(tl_d_valid_q[0] & (tl_d_mshrid_q[0] == enq_mshr_id[w]));"),

    ("M4", "去掉 G1 新增的「上一拍 D-channel」这一项（退回 G0 的入队 blocking）", "CAUGHT",
     "                            & ~(tl_d_valid      & (tl_d_mshrid      == enq_mshr_id[w]))\n"
     "                            & ~(tl_d_valid_q[w] & (tl_d_mshrid_q[w] == enq_mshr_id[w]));",
     "                            & ~(tl_d_valid      & (tl_d_mshrid      == enq_mshr_id[w]));"),

    ("M5", "io_replayAllocate 漏掉最后一条 entry", "CAUGHT",
     "  assign replayAllocate = |allocated_v;",
     "  assign replayAllocate = |allocated_v[LQ_REPLAY_SIZE-2:0];"),

    ("M6", "入队时存入队的 exceptionVec，而不是清 0（= 本轮真抓到的那个差异）", "CAUGHT",
     "          if (EXC_KEEP[b]) uop[i].exceptionVec[b] <= 1'b0;",
     "          if (EXC_KEEP[b]) uop[i].exceptionVec[b] <= entry_ne_uop[i].exceptionVec[b];"),

    ("M7", "StoreQueue 就绪向量越界读返回 0，而不是第 0 项", "CAUGHT",
     "    r = vec[0];\n    for (int k = 0; k < SQ_SIZE; k++) if (idx == k[SQ_IDX_W-1:0]) r = vec[k];",
     "    r = 1'b0;\n    for (int k = 0; k < SQ_SIZE; k++) if (idx == k[SQ_IDX_W-1:0]) r = vec[k];"),

    ("M8", "topdown 的 robHeadLoadMSHR 取 C_DM 而不是 C_DR（名字误导处）", "CAUGHT",
     "  assign dtd_robHeadLoadMSHR  = lq_match & matchCause[C_DR];",
     "  assign dtd_robHeadLoadMSHR  = lq_match & matchCause[C_DM];"),

    ("M9", "s1_cancel 读 uop 时加 valid 门控（golden 无条件读）", "EXPECTED_MISSED",
     "      u  = uopR[s1_oldestSel_bits_q[i]];",
     "      u  = s1_oldestSel_valid_q[i] ? uopR[s1_oldestSel_bits_q[i]] : uop[0];"),

    ("M10", "给 golden 无复位的 s1_oldestSel_bits 加复位（复位域变异）", "EXPECTED_MISSED",
     "  always_ff @(posedge clock)\n"
     "    for (int i = 0; i < LD_PIPE_W; i++)\n"
     "      if (s0_can_go[i]) s1_oldestSel_bits_q[i] <= oh72_to_idx(s0_oldestSel_bits[i]);",
     "  always_ff @(posedge clock or posedge reset)\n"
     "    if (reset) s1_oldestSel_bits_q <= '0;\n"
     "    else for (int i = 0; i < LD_PIPE_W; i++)\n"
     "      if (s0_can_go[i]) s1_oldestSel_bits_q[i] <= oh72_to_idx(s0_oldestSel_bits[i]);"),

    ("M11", "topdown 归约树换成左结合 fold（平局时与 ParallelOperation 分叉）", "CAUGHT",
     "    td_n[2] = td_merge(td_n[0], td_n[1]);",
     "    td_n[2] = td_merge(td_n[1], td_n[0]);"),

    ("M12", "冷却阈值 12 -> 13", "CAUGHT",
     "  localparam logic [COLD_DOWN_W-1:0] COLD_DOWN_THRESHOLD = 4'd12;",
     "  localparam logic [COLD_DOWN_W-1:0] COLD_DOWN_THRESHOLD = 4'd13;"),
]

GOLDEN_SRCS = [GOLDEN / f"{m}.sv" for m in
               ("LoadQueueReplay", "LqVAddrModule", "FreeList_5", "AgeDetector_38",
                "DelayN_13", "DelayNWithValid_152", "DelayNWithValid_155")]


def build_and_run(tag, rtl_text):
    d = WORK / tag
    if d.exists():
        shutil.rmtree(d)
    d.mkdir(parents=True)
    # impl 侧改名为 _xs（等价于 derive_ut_impl.py 对单文件做的事）
    derived = re.sub(r"\bLoadQueueReplay\b(?!_)", "LoadQueueReplay_xs", rtl_text)
    # 只改 golden 同名 wrapper；xs_LoadQueueReplay_core / 包名不受影响（上面 \b 已保证
    # xs_LoadQueueReplay_core 里的 LoadQueueReplay 前面是下划线，不是词边界）
    (d / "impl.sv").write_text(derived)
    log = d / "sim.log"
    if log.exists():
        log.unlink()
    env = dict(os.environ, VCS_ARCH_OVERRIDE="linux")
    cc = subprocess.run(
        ["vcs", "-full64", "-sverilog", "-timescale=1ns/1ps", "-lca",
         "+define+SYNTHESIS", "+vcs+initreg+random",
         str(d / "impl.sv")] + [str(p) for p in GOLDEN_SRCS] + [str(HERE / "tb.sv"),
         "-top", "tb", "-o", str(d / "simv"), "-l", str(d / "compile.log")],
        cwd=d, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        universal_newlines=True)
    if cc.returncode != 0 or not (d / "simv").exists():
        return None, "COMPILE_FAIL"
    sr = subprocess.run([str(d / "simv"), f"+ntb_random_seed={SEED}",
                         f"+ncycles={CYCLES}", "+vcs+initreg+random",
                         "-l", str(log)], cwd=d, env=env,
                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                        universal_newlines=True)
    if not log.exists():
        return None, "NO_LOG"
    txt = log.read_text(errors="replace")
    m = re.search(r"checks=(\d+) errors=(\d+)", txt)
    if not m:
        return None, "NO_RESULT_LINE"
    return (int(m.group(2)), int(m.group(1))), "OK"


def main():
    want = set(sys.argv[1:])
    base = RTL.read_text()
    WORK.mkdir(exist_ok=True)

    print(f"=== baseline ({CYCLES} 拍, seed {SEED}) ===")
    r, st = build_and_run("base", base)
    if st != "OK":
        print(f"FATAL: baseline {st}")
        return 1
    print(f"  baseline errors={r[0]} checks={r[1]}")
    if r[0] != 0:
        print("FATAL: baseline 不是 errors=0，变异体结果没有意义")
        return 1

    rows = []
    for mid, desc, expect, old, new in MUTANTS:
        if want and mid not in want:
            continue
        # (a) 自证改变了文本：old 必须出现且唯一
        n = base.count(old)
        if n != 1:
            rows.append((mid, desc, expect, "PATCH_MISS", f"old_str 命中 {n} 次（须恰 1）"))
            print(f"  {mid}: PATCH_MISS (命中 {n} 次)")
            continue
        mutated = base.replace(old, new)
        assert mutated != base
        r2, st2 = build_and_run(mid, mutated)
        if st2 != "OK":
            # ★编不过判 FAIL，不许当成 CAUGHT★
            rows.append((mid, desc, expect, "FAIL", st2))
            print(f"  {mid}: FAIL ({st2})")
            continue
        errs, chks = r2
        verdict = "CAUGHT" if errs > 0 else "MISSED"
        rows.append((mid, desc, expect, verdict, f"errors={errs} checks={chks}"))
        print(f"  {mid}: {verdict:7s} errors={errs:<10d} {desc}")

    print("\n=== 变异体矩阵 ===")
    print(f"{'ID':<5} {'期望':<16} {'实测':<10} {'量':<28} 说明")
    bad = 0
    for mid, desc, expect, verdict, detail in rows:
        ok = (verdict == expect) or (expect == "EXPECTED_MISSED" and verdict == "CAUGHT")
        if not ok:
            bad += 1
        print(f"{mid:<5} {expect:<16} {verdict:<10} {detail:<28} {desc}")
    print(f"\n不符合期望: {bad}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
