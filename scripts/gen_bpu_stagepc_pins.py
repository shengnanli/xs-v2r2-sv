#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_bpu_stagepc_pins.py —— BPU 预测器（FauFTB / ITTage / Tage_SC）的 FM「匹配前」钉点生成器。

钉点只消名差：golden（firtool 展平名）与重写核（数组 / 结构体 / 共享辅助件层次）的寄存器名字不同，
不钉时 FM 要么把无读者的寄存器报成两侧 unmatched unread（vmucp 对 unmatched 点是空转），要么在签名
分析里耗很久（ITTage 不钉实测 Matching 30 分钟未结束）。不 dont_verify、不约束 ref、不加黑盒。

规则表按"golden 顶层寄存器名 -> 重写侧寄存器路径"写（见 RULES），一个 golden 寄存器的每一位对一位：
  · 公共外壳 xs_BpuStagePc（三个预测器共用）：
      s1_pc_dup_<d>                         <-> u_core/u_stage_pc/s1_pc_reg[d][bit]
      s{2,3}_pc_dup_s{2,3}_pc_seg_{0,1,2}_value[_<d>]（dup 0 无后缀）<-> u_core/u_stage_pc/s{2,3}_{hi,mid,lo}_reg[d][bit]
      modified_reset                        <-> u_core/u_stage_pc/modified_reset_reg
  · 各目标自己的寄存器见 RULES[目标]。
fail-closed（生成期）：golden 寄存器名与位宽从 G1 golden 现读；目标声明 FULL=True 时，golden 顶层每一个寄存器都必须
  恰好被一条规则认领（多认领 / 漏认领都拒绝生成）；映射必须单射；位宽来自 golden 声明。
fail-closed（运行期）：生成的 tcl 逐条按 set_user_match 的**返回值**计数（它遇坏名不抛异常、只返回 0 并在 fm.log 记一行
  Error —— 旧版用 catch 计数是空的，ITTage 曾因此 250 位静默落空），成功数必须等于字面总数，否则 error。

父级：PARENTS 里的父目标（Composer）的 fm_pins_pre.tcl 里维护一个 GENERATED(bpu-child-pins) 区，
  把各预测器子实例的钉点加实例前缀并入；父级自己的钉点在区外、不碰。父级另并入子模块自证时 FM 自己给出的
  寄存器配对（verif/ut/<父级>/child_pairs/<子模块>.tsv）：父级规模下签名分析在子模块内部的对称结构上配不全
  （Composer 诊断跑实测 18136 个 unmatched compare point），配对本身是 FM 在子模块证明里的结论，不是人工指定；
  与规则钉点重叠时以 FM 配对为准（只差位号写法）；合并后仍须单射。

用法：
    python3 scripts/gen_bpu_stagepc_pins.py            # 生成全部目标（幂等）
    python3 scripts/gen_bpu_stagepc_pins.py --check    # 产物与生成器不一致则 rc=1
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, ".."))
GOLDEN_DIR = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")

SEG = {"0": "hi", "1": "mid", "2": "lo"}
SP = "u_core/u_stage_pc/"


def die(msg):
    raise SystemExit("gen_bpu_stagepc_pins: " + msg)


def golden_regs(top):
    """golden 顶层模块体里的 reg 声明：[(名字, 位宽)]，按声明顺序。"""
    t = open(os.path.join(GOLDEN_DIR, top + ".sv")).read()
    m = re.search(r"^module\s+%s\s*\(.*?^\);(.*?)^endmodule" % re.escape(top), t, re.S | re.M)
    if not m:
        die("golden 里找不到 module %s" % top)
    out = []
    for rm in re.finditer(r"^\s*reg\s+(?:\[(\d+):0\]\s+)?(\w+);", m.group(1), re.M):
        out.append((rm.group(2), int(rm.group(1)) + 1 if rm.group(1) else 1))
    return out


# ---- 规则：(golden 名正则, 函数(match) -> 重写侧"位前缀"字符串；位下标按 [bit] 追加) ----
# 返回值里的 "{b}" 若出现，表示位下标插在那里（结构体内偏移等）；否则在末尾追加 [bit]（多位）或不加（1 位）。
def stagepc_rules():
    return [
        (r"modified_reset", lambda m: SP + "modified_reset_reg"),
        (r"s1_pc_dup_(\d)", lambda m: SP + "s1_pc_reg[%s]" % m.group(1)),
        (r"s([23])_pc_dup_s\1_pc_seg_([012])_value(?:_(\d))?",
         lambda m: SP + "s%s_%s_reg[%s]" % (m.group(1), SEG[m.group(2)], m.group(3) or "0")),
    ]


def only_s23():
    return [stagepc_rules()[2]]


ITTAGE_SIMPLE = {
    "tickCtr": "tick_ctr", "s3_providerTarget": "s3_provider_target", "s3_altProviderTarget": "s3_alt_provider_target",
    "s3_provided": "s3_provided", "s3_provider": "s3_provider", "s3_altProvided": "s3_alt_provided",
    "s3_altProvider": "s3_alt_provider", "s3_providerU": "s3_provider_u", "s3_providerCtr": "s3_provider_ctr",
    "s3_altProviderCtr": "s3_alt_provider_ctr", "resp_meta_allocate_valid_r": "s3_alloc_valid",
    "resp_meta_allocate_bits_r": "s3_alloc_entry", "resp_meta_pred_cycle_c": "pred_cycle", "u_valid": "u_valid",
    "update_r_pc": "u_pc", "update_r_ftb_entry_isRet": "u_is_ret_raw", "update_r_ftb_entry_isJalr": "u_is_jalr_raw",
    "update_r_ftb_entry_tailSlot_offset": "u_tail_offset", "update_r_ftb_entry_tailSlot_sharing": "u_tail_sharing",
    "update_r_ftb_entry_tailSlot_valid": "u_tail_valid", "update_r_ftb_entry_strong_bias_1": "u_strong_bias_1",
    "update_r_cfi_idx_valid": "u_cfi_valid", "update_r_jmp_taken": "u_jmp_taken",
    "update_r_mispred_mask_2": "u_jmp_mispred", "updateMeta_r_provider_valid": "um_provider_valid",
    "updateMeta_r_altProvider_valid": "um_alt_provider_valid", "updateMeta_r_altDiffers": "um_alt_differs",
    "updateMeta_r_providerU": "um_provider_u", "updateMeta_r_providerCtr": "um_provider_ctr",
    "updateMeta_r_altProviderCtr": "um_alt_provider_ctr", "updateMeta_r_allocate_valid": "um_allocate_valid",
    "updateMeta_provider_bits_r": "um_provider", "updateMeta_providerTarget_r": "um_provider_target",
    "updateMeta_allocate_bits_r": "um_allocate", "updateMeta_altProvider_bits_r": "um_alt_provider",
    "updateMeta_altProviderTarget_r": "um_alt_provider_target", "update_full_target_r": "u_full_target",
    "update_cfi_idx_bits_r": "u_cfi_idx", "update_ghist_r": "u_ghist",
}
ITTAGE_TBL = {"valid_REG": "upd_valid_q", "reset_u_REG": "upd_reset_u_q", "uValid_r": "upd_u_valid_q",
              "correct_r": "upd_correct_q", "alloc_r": "upd_alloc_q", "oldCtr_r": "upd_old_ctr_q",
              "u_r": "upd_u_q", "pc_r": "upd_pc_q", "ghist_r": "upd_ghist_q"}
# ittage_offset_t 字段寄存器：FM elaborate 后按结构体字段名起名 —— <数组>_reg[i]\[<字段>][位]（1 位字段无位号）。
# ★2026-10-04 修正★：原先按打平位号写成 <数组>_reg[i][5+位]，FM 不认（fm.log 行首 250 行 Unknown name），
# 而旧模板用 catch 数钉点、set_user_match 遇坏名不抛异常 —— 静默落空、照样打印 3301/3301。见 render() 的返回值计数。
OFF_FIELDS = ("offset", "pointer", "usePCRegion")


def ittage_rules():
    r = stagepc_rules()
    r.append((r"(%s)" % "|".join(sorted(ITTAGE_SIMPLE, key=len, reverse=True)),
              lambda m: "u_core/%s_reg" % ITTAGE_SIMPLE[m.group(1)]))
    r.append((r"s3_tageTarget_dup_(\d)", lambda m: "u_core/s3_target_reg[%s]" % m.group(1)))
    r.append((r"tables_(\d)_io_update_(%s)" % "|".join(ITTAGE_TBL),
              lambda m: "u_core/%s_reg[%s]" % (ITTAGE_TBL[m.group(2)], m.group(1))))
    r.append((r"tables_(\d)_io_update_(old_target_offset|target_offset)_r_(offset|pointer|usePCRegion)",
              lambda m: "u_core/%s_reg[%s]\\[%s]" % ("upd_old_off_q" if m.group(2).startswith("old") else
                                                   "upd_tgt_off_q", m.group(1), m.group(3))))
    return r


def tage_rules():
    r = stagepc_rules()
    r.append((r"tables_(\d)_io_update_(pc|ghist)_r_1", lambda m: "u_core/tbl_upd_%s_reg[%s]" % (m.group(2), m.group(1))))
    r.append((r"scTables_(\d)_io_update_(pc|ghist)_r_1", lambda m: "u_core/sc_upd_%s_reg[%s]" % (m.group(2), m.group(1))))
    r.append((r"bt_io_update_pc_r", lambda m: "u_core/bt_upd_pc_reg"))
    return r


# 目标 -> (规则, FULL：golden 顶层寄存器是否必须全部被认领, 只钉这些名字的正则（FULL=False 时）)
TARGETS = {
    "FauFTB":  (only_s23, False),
    "ITTage":  (ittage_rules, True),
    "Tage_SC": (tage_rules, False),
}


def pairs_for(top, prefix=""):
    """top = 预测器模块名；prefix = 它在父级里的实例层次（父级钉点用，如 Composer 的 "tage/"）。"""
    rules_fn, full = TARGETS[top]
    rules = [(re.compile(rx), fn) for rx, fn in rules_fn()]
    out = []
    for name, w in golden_regs(top):
        hits = [(rx, fn) for rx, fn in rules if rx.fullmatch(name)]
        if len(hits) > 1:
            die("%s: golden 寄存器 %s 被 %d 条规则认领" % (top, name, len(hits)))
        if not hits:
            if full:
                die("%s: golden 寄存器 %s 没有规则认领（FULL）" % (top, name))
            continue
        rx, fn = hits[0]
        base = fn(rx.fullmatch(name))
        for b in range(w):
            ref = "%s_reg[%d]" % (name, b) if w > 1 else "%s_reg" % name
            impl = base + ("[%d]" % b if w > 1 else "")
            out.append((prefix + ref, prefix + impl))
    refs = [r for r, _ in out]
    impls = [i for _, i in out]
    if len(set(refs)) != len(refs) or len(set(impls)) != len(impls):
        die("%s: 映射不是单射" % top)
    if not out:
        die("%s: 一条钉点都没有" % top)
    return out


# 父级：在父级的 fm_pins_pre.tcl 里维护一个 GENERATED 区，把各预测器子实例的钉点按实例层次前缀并入
# （父级自己的钉点在 GENERATED 区外，由父级自己的工具维护，本生成器不碰）。
PARENTS = {
    "Composer": [("FauFTB", "uftb/"), ("Tage_SC", "tage/"), ("ITTage", "ittage/")],
}
PBEGIN = "# BEGIN GENERATED(bpu-child-pins) —— scripts/gen_bpu_stagepc_pins.py 生成，勿手改\n"
PEND = "# END GENERATED(bpu-child-pins)\n"


def child_matched_pairs(parent, child):
    """子模块自证时 FM 自己给出的寄存器配对（verif/ut/<parent>/child_pairs/<child>.tsv，
    由 scripts/extract_fm_matched_pairs.py 从与 receipt 同字节的那次子模块 FM 跑抽出）。"""
    p = os.path.join(REPO, "verif", "ut", parent, "child_pairs", child + ".tsv")
    out = []
    for ln in open(p):
        if ln.startswith("#") or not ln.strip():
            continue
        r, i = ln.rstrip("\n").split("\t")
        out.append((r, i))
    return out


def render_parent(parent):
    prs = []
    for child, pfx in PARENTS[parent]:
        rule = pairs_for(child, pfx)
        seen = dict(rule)
        for r, i in child_matched_pairs(parent, child):
            r, i = pfx + r, pfx + i
            # 同一 ref 两边都有时以 FM 自己的配对为准（实测只差写法：规则写打平位号 [i][5]，
            # FM 报告写结构体字段名 [i]\[offset][0]，两者在子模块证明里都钉得上、指同一个寄存器位）
            seen[r] = i
        prs += sorted(seen.items())
    if len(set(r for r, _ in prs)) != len(prs) or len(set(i for _, i in prs)) != len(prs):
        die("%s: 子实例钉点合并后不是单射" % parent)
    n = len(prs)
    L = []
    L.append("# 子实例（%s）的 FM 匹配前钉点，共 %d 位：规则同各预测器自己的钉点（见生成器），只是路径加实例前缀。"
             % (" / ".join("%s=%s" % (pfx.rstrip("/"), c) for c, pfx in PARENTS[parent]), n))
    L.append("if {$top eq \"%s\"} {" % parent)
    L.append("  set _cn 0")
    L.append("  set _cmiss 0")
    L.append("  set _cpairs {")
    for r, i in prs:
        L.append("    {%s %s}" % (esc(r), esc(i)))
    L.append("  }")
    L.append("  foreach _p $_cpairs {")
    L.append("    set _r \"r:/WORK/$top/[lindex $_p 0]\"")
    L.append("    set _i \"i:/WORK/$top/[lindex $_p 1]\"")
    L.append("    # set_user_match 遇坏名不抛异常、返回 0（CONVENTIONS）：按返回值计数，catch 只兜底真异常")
    L.append("    if {[catch {set_user_match $_r $_i} _rv] || $_rv != 1} {")
    L.append("      incr _cmiss")
    L.append("      if {$_cmiss <= 10} { puts \"BPU_CHILD_PIN_FAIL: $_r <-> $_i ($_rv)\" }")
    L.append("    } else {")
    L.append("      incr _cn")
    L.append("    }")
    L.append("  }")
    L.append("  puts \"BPU_CHILD_PINS: $_cn / %d pinned, $_cmiss missed\"" % n)
    L.append("  if {$_cmiss != 0 || $_cn != %d} { error \"BPU_CHILD_PIN_MISS=$_cmiss n=$_cn\" }" % n)
    L.append("}")
    return "\n".join(L) + "\n"


def esc(x):
    return x.replace("\\", "\\\\").replace("[", "\\[").replace("]", "\\]")


def render(top):
    prs = pairs_for(top)
    n = len(prs)
    L = []
    L.append("# %s FM 匹配前钉点 —— %d 位（scripts/gen_bpu_stagepc_pins.py 生成，勿手改）" % (top, n))
    L.append("# 映射规则与依据见生成器文件头与 RULES；golden 名与位宽从 G1 golden 现读，单射由生成器断言。")
    L.append("if {$top eq \"%s\"} {" % top)
    L.append("  set _n 0")
    L.append("  set _miss 0")
    L.append("  set _pairs {")
    for r, i in prs:
        L.append("    {%s %s}" % (esc(r), esc(i)))
    L.append("  }")
    L.append("  foreach _p $_pairs {")
    L.append("    set _r \"r:/WORK/$top/[lindex $_p 0]\"")
    L.append("    set _i \"i:/WORK/$top/[lindex $_p 1]\"")
    L.append("    # set_user_match 遇坏名不抛异常、返回 0（CONVENTIONS）：按返回值计数，catch 只兜底真异常")
    L.append("    if {[catch {set_user_match $_r $_i} _rv] || $_rv != 1} {")
    L.append("      incr _miss")
    L.append("      if {$_miss <= 10} { puts \"BPU_PIN_FAIL: $_r <-> $_i ($_rv)\" }")
    L.append("    } else {")
    L.append("      incr _n")
    L.append("    }")
    L.append("  }")
    L.append("  puts \"BPU_PINS: $_n / %d pinned, $_miss missed\"" % n)
    L.append("  if {$_miss != 0 || $_n != %d} { error \"BPU_PIN_MISS=$_miss n=$_n\" }" % n)
    L.append("}")
    return "\n".join(L) + "\n"


def main():
    check = "--check" in sys.argv[1:]
    rc = 0
    jobs = [(top, render(top)) for top in sorted(TARGETS)]
    for parent in sorted(PARENTS):
        p = os.path.join(REPO, "verif", "ut", parent, "fm_pins_pre.tcl")
        cur = open(p).read()
        if cur.count(PBEGIN) == 0 and cur.count(PEND) == 0:
            base = cur.rstrip("\n") + "\n\n" + PBEGIN + PEND
        elif cur.count(PBEGIN) == 1 and cur.count(PEND) == 1:
            base = cur
        else:
            die("%s 里 GENERATED 标记不是恰好一对" % p)
        a = base.index(PBEGIN) + len(PBEGIN)
        b = base.index(PEND)
        jobs.append((parent, base[:a] + render_parent(parent) + base[b:]))
    for top, txt in jobs:
        p = os.path.join(REPO, "verif", "ut", top, "fm_pins_pre.tcl")
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
