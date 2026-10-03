#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_bpu_stagepc_pins.py —— BPU 预测器（FauFTB / ITTage / Tage_SC）FM「匹配前」钉点生成器。

钉的是什么：BasePredictor 公共外壳里 utility.SegmentedAddrNext 的 s2/s3 段寄存器（4 dup × 2 级 × 50 位 = 400 位）。
  golden（firtool 展平）: s{2,3}_pc_dup_s{2,3}_pc_seg_{0,1,2}_value[_<dup>]_reg[bit]（dup 0 无后缀）
  重写（共享辅助件 rtl/common/xs_BpuStagePc.sv，数组）: <核层次>/u_stage_pc/s{2,3}_{hi,mid,lo}_reg[dup][bit]
  seg_0 <-> hi(26 位，pc[49:24])、seg_1 <-> mid(12 位，pc[23:12])、seg_2 <-> lo(12 位，pc[11:0])，位号逐位同号。
为什么要钉：这些寄存器在各预测器里大部分或全部无消费者（cone-dead），没有功能签名可配，
  名字又两侧不同 —— 不钉时 FM 把它们报成两侧 unmatched unread（FauFTB 诊断跑实测 400(400)），
  vmucp 对 unmatched 点是空转。钉点只消名差：不 dont_verify、不约束 ref、不加黑盒。

fail-closed：生成的 tcl 逐条数 set_user_match 返回值（catch 只用来计数失败，不吞错误），
  成功数必须等于字面 400，否则 error 退出。

用法：
    python3 scripts/gen_bpu_stagepc_pins.py            # 生成全部目标（幂等）
    python3 scripts/gen_bpu_stagepc_pins.py --check    # 产物与生成器不一致则 rc=1
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, ".."))

# 目标 -> 重写侧 xs_BpuStagePc 实例的层次（相对顶层）
TARGETS = {
    "FauFTB": "u_core/u_stage_pc",
}
SEGS = [(0, "hi", 26), (1, "mid", 12), (2, "lo", 12)]
NUM_DUP = 4
TOTAL = 2 * NUM_DUP * sum(w for _, _, w in SEGS)


def pairs(inst):
    out = []
    for stage in (2, 3):
        for d in range(NUM_DUP):
            sfx = "" if d == 0 else "_%d" % d
            for si, sname, w in SEGS:
                for b in range(w):
                    out.append(("s%d_pc_dup_s%d_pc_seg_%d_value%s_reg[%d]" % (stage, stage, si, sfx, b),
                                "%s/s%d_%s_reg[%d][%d]" % (inst, stage, sname, d, b)))
    assert len(out) == TOTAL == 400
    assert len(set(r for r, _ in out)) == TOTAL and len(set(i for _, i in out)) == TOTAL  # 单射
    return out


def render(top, inst):
    L = []
    L.append("# %s FM 匹配前钉点 —— BPU 公共外壳 s2/s3 段 PC 的 %d 位（scripts/gen_bpu_stagepc_pins.py 生成，勿手改）" % (top, TOTAL))
    L.append("# 映射规则与依据见生成器文件头。双射是机械的：seg_0/1/2 <-> hi/mid/lo，dup 后缀 无/_1/_2/_3 <-> [0]/[1]/[2]/[3]，位号同号。")
    L.append("if {$top eq \"%s\"} {" % top)
    L.append("  set _n 0")
    L.append("  set _miss 0")
    L.append("  set _pairs {")
    for r, i in pairs(inst):
        L.append("    {%s %s}" % (r.replace("[", "\\[").replace("]", "\\]"), i.replace("[", "\\[").replace("]", "\\]")))
    L.append("  }")
    L.append("  foreach _p $_pairs {")
    L.append("    set _r \"r:/WORK/$top/[lindex $_p 0]\"")
    L.append("    set _i \"i:/WORK/$top/[lindex $_p 1]\"")
    L.append("    if {[catch {set_user_match $_r $_i} _msg]} {")
    L.append("      incr _miss")
    L.append("      if {$_miss <= 10} { puts \"BPU_STAGEPC_PIN_FAIL: $_r <-> $_i ($_msg)\" }")
    L.append("    } else {")
    L.append("      incr _n")
    L.append("    }")
    L.append("  }")
    L.append("  puts \"BPU_STAGEPC_PINS: $_n / %d pinned, $_miss missed\"" % TOTAL)
    L.append("  if {$_miss != 0 || $_n != %d} { error \"BPU_STAGEPC_PIN_MISS=$_miss n=$_n\" }" % TOTAL)
    L.append("}")
    return "\n".join(L) + "\n"


def main():
    check = "--check" in sys.argv[1:]
    rc = 0
    for top, inst in sorted(TARGETS.items()):
        p = os.path.join(REPO, "verif", "ut", top, "fm_pins_pre.tcl")
        txt = render(top, inst)
        old = open(p).read() if os.path.exists(p) else None
        rel = os.path.relpath(p, REPO)
        if check:
            if old != txt:
                print("[gencheck] %s 与生成结果不一致" % rel)
                rc = 1
            else:
                print("[gencheck] %s OK" % rel)
        elif old != txt:
            open(p, "w").write(txt)
            print("wrote", rel)
        else:
            print("unchanged", rel)
    return rc


if __name__ == "__main__":
    sys.exit(main())
