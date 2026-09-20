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
  python3 mutants.py --check    # 只验变异体表没和 RTL 脱钩（不编译、毫秒级）
环境:
  MUT_CYCLES  每个变异体跑多少拍（默认 20000）
  MUT_SEED    种子（默认 1）
  MUT_WORK    构建目录名（默认 mut_work）。分组并行跑时必须各组不同，
              否则几个进程会同时 rmtree/重建同一个 base/ 目录。
退出码:
  0 = 全部符合期望；1 = baseline 异常；★2 = 有变异体不符合期望（fail-closed）★
  ——原先无论多少条不符合期望都 return 0，只把计数打在屏幕上。闸不出声就不是闸。
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
WORK = HERE / os.environ.get("MUT_WORK", "mut_work")   # ★分组并行时各组给不同的 MUT_WORK，避免抢 base/★

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

    # ★M5 余量极薄★：只有「第 71 条是唯一 allocated 的那一条」时才可观测。
    #  实测 20k 拍 seed 1 只抓到 errors=2 —— 换个种子就可能漏。它真正的兜底在 FM
    #  （io_replayAllocate 是 allocated 的纯组合归约，FM 全取值域逐点比）。
    ("M5", "io_replayAllocate 漏掉最后一条 entry（★余量极薄，见注释★）", "CAUGHT",
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

    # ★M9 的 old_str 在 2026-09-20 修过一次，理由记在这里★
    #  原文是 `      u  = uopR[...]`（u 后两个空格）。commit a01bb65（redirect 打拍
    #  改成 6 份）顺手把这一行对齐成了 `u    =`（四个空格），于是 old_str 命中 0 次。
    #  ★这就是"变异体表会和 RTL 脱钩"的实例★：harness 老老实实报了 PATCH_MISS，
    #  但当时 main() 无论如何都 return 0，所以没人会发现——这一条是本轮把 harness
    #  改成 fail-closed 之后**第一件被抓出来的事**。
    ("M9", "s1_cancel 读 uop 时加 valid 门控（golden 无条件读）", "EXPECTED_MISSED",
     "      u    = uopR[s1_oldestSel_bits_q[i]];",
     "      u    = s1_oldestSel_valid_q[i] ? uopR[s1_oldestSel_bits_q[i]] : uop[0];"),

    ("M10", "给 golden 无复位的 s1_oldestSel_bits 加复位（复位域变异）", "EXPECTED_MISSED",
     "  always_ff @(posedge clock)\n"
     "    for (int i = 0; i < LD_PIPE_W; i++)\n"
     "      if (s0_can_go[i]) s1_oldestSel_bits_q[i] <= oh72_to_idx(s0_oldestSel_bits[i]);",
     "  always_ff @(posedge clock or posedge reset)\n"
     "    if (reset) s1_oldestSel_bits_q <= '0;\n"
     "    else for (int i = 0; i < LD_PIPE_W; i++)\n"
     "      if (s0_can_go[i]) s1_oldestSel_bits_q[i] <= oh72_to_idx(s0_oldestSel_bits[i]);"),

    # ★M11 换过一次，理由写在这里★
    # 原来的 M11 是「把 td_n[2] 的两个实参对调」，实测 MISSED。复盘发现那是**近乎空变异**：
    #   td_merge(a,b) 两者都有效时取 isAfter(a.rob,b.rob) ? b : a，也就是取 robIdx 较老的那个；
    #   对调实参后是 isAfter(b.rob,a.rob) ? a : b —— 在 a.rob != b.rob 时**逐位相同**
    #   （isAfter 反对称），只有 a.rob == b.rob 这个平局才分叉。
    # 也就是说：归约树的**形状/顺序**这件事本身就只在平局时可观测，仿真按构造几乎产生不出
    # （要两条 allocated entry 同 vaddr、同 robIdx、不同 lqIdx）。所以它归 FM 管，
    # 标 EXPECTED_MISSED 并保留 —— 剔掉它会让人以为树形无所谓。
    # 另加 M11b 打同一块逻辑的**真**功能变异：把比较方向翻过来（取最新而不是最老）。
    ("M11", "topdown 归约树两个实参对调（★平局才分叉，近乎空变异，见代码注释★）",
     "EXPECTED_MISSED",
     "    td_n[2] = td_merge(td_n[0], td_n[1]);",
     "    td_n[2] = td_merge(td_n[1], td_n[0]);"),

    ("M11b", "topdown 归约取最新而不是最老（td_merge 的比较方向翻转）", "CAUGHT",
     "    if (a.v & b.v) td_merge = isAfter ? '{v:1'b1, robF:b.robF, robV:b.robV, lqV:b.lqV}\n"
     "                                      : '{v:1'b1, robF:a.robF, robV:a.robV, lqV:a.lqV};",
     "    if (a.v & b.v) td_merge = isAfter ? '{v:1'b1, robF:a.robF, robV:a.robV, lqV:a.lqV}\n"
     "                                      : '{v:1'b1, robF:b.robF, robV:b.robV, lqV:b.lqV};"),

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


def check_patches(base):
    """★毫秒级的脱钩闸★：只验每个变异体的 old_str 在当前 RTL 里恰好命中一次。

    为什么单独做一个：M9 的 old_str 被一个无关 commit 的空白对齐改掉了，
    harness 要**编译并跑完前面几个变异体**才轮到它报 PATCH_MISS——代价是几分钟。
    而"表和 RTL 脱钩"这件事不需要 VCS 就能查。放进 gate_all 也不占任何工具 license。
    """
    bad = 0
    for mid, desc, _e, old, _n in MUTANTS:
        n = base.count(old)
        if n != 1:
            print(f"  DRIFT {mid}: old_str 命中 {n} 次（须恰 1）—— {desc}")
            bad += 1
    print(f"check_patches: {len(MUTANTS)} 个变异体，脱钩 {bad} 个")
    return 2 if bad else 0


def main():
    argv = list(sys.argv[1:])
    if "--check" in argv:
        return check_patches(RTL.read_text())
    want = set(argv)
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
        # EXPECTED_MISSED 的含义是「UT 观测不到，由 FM 兜底」：收到 MISSED 是符合期望；
        # 收到 CAUGHT 也算好消息（UT 比预期强），两者都算符合。
        ok = (verdict == expect) or (expect == "EXPECTED_MISSED" and verdict in ("MISSED", "CAUGHT"))
        if not ok:
            bad += 1
        print(f"{mid:<5} {expect:<16} {verdict:<10} {detail:<28} {desc}")
    print(f"\n不符合期望: {bad}")
    return 2 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
