#!/usr/bin/env python3
# ============================================================================
# gen_ctrlblock_pin_manifest.py — mechanical CtrlBlock glue-partition pin bijection
# ----------------------------------------------------------------------------
# CtrlBlock 是 glue-partition assembly 目标(16 子模块两侧对称黑盒, 见
# verif/signoff/allow/CtrlBlock.json)。golden(firtool 展平字段名, 如
# delayedNotFlushedWriteBack_delayed_bits_r_20_exceptionVec_0_reg)与手写可读核的
# struct/unpacked-array 寄存器(如 wbDelayedBits_reg[20][exceptionVec][0])名字与层次
# 都不同, FM 的 auto_match_flattened_arrays 只能处理纯 name_reg[i][j] 结构, 处理不了
# 字段名内嵌的 struct+array 情形 → 1962 对寄存器落单 unmatched。
#
# 这**不是**功能差异: 两侧都是 same-source 常数 0 寄存器(golden 在 SYNTHESIS 下把
# debugInfo_*Time / 部分 exceptionVec / debug_* 字段硬连 0; 可读核对应 struct 字段也
# 恒 0), 值等价。官方 gate 会在 set_user_match 后实证 0==0 passing(非 dont_verify,
# 非 vmucp 掩盖, 非强配)。
#
# 本脚本机械枚举 golden(ref)未匹配 DFF 集, 用 fm_pins.tcl 的**同一套命名规则**推导
# impl 侧规范键, 与 impl 未匹配 DFF 集精确配对, 并 fail-closed 校验:
#   (a) 1962 == 1962 守恒(ref 数 == impl 数);
#   (b) bijection(无 ref 落单/无 impl 落单/无两 ref 撞同一 impl);
#   (c) 0 黑盒内部/rob 内部引用;
# 产出 verif/ut/CtrlBlock/ctrlblock_pin_manifest.json(1962 对 + 规则 + sha256)。
#
# 权威输入 = 官方 gate 的 native FM 未匹配 DFF 转储(--ref-list / --impl-list);
# 无输入时从冻结的 gate evidence fm_log 派生(--from-fmlog)。不手写、不按日志猜单点。
#
# ----------------------------------------------------------------------------
# codex 0127 Lane A 扩展: --wbd 模式(wbdelayed 窄化 per-lane 寄存器 pre-match 双射)
# ----------------------------------------------------------------------------
# b490e6b1 把 27 路整-struct wbDelayedBits_reg 窄化为逐 golden 保留字段的
# wbd<lane>_<field> 窄寄存器(RegEnable, enable=wbInValid[N], 无复位)。gate3 实证
# (evidence SGN-CtrlBlock-1786114121): 窄化后 FM 在 impl 侧对同函数常数标量寄存器做
# duplicate-register merge/任意常数配对, 留下 13 个 golden lane-20 exceptionVec
# hold-clear 常数寄存器 unmatched(compare_ref=13, Constrained 0X), 旧 pin 机器
# (匹配后、按 unmatched 池配对)拿不到 impl 对象 → 0 pinned。
#
# 正解 = **匹配前**(FM_PIN_PRE_TCL, fm_eq.tcl 首次 match 前 hook)把**全部** 329 个
# wbd<lane>_<field> 寄存器逐位 set_user_match 到对应 golden
# delayedNotFlushedWriteBack_delayed_bits_r[_N]_<field>(lane0=bare r_, 1..26=r_N_):
# user match 先于 auto-match/merge 固定全族双射, 消除常数池 shuffle 的不确定性。
#
# 本模式**完全机械派生**(不手写不按日志猜):
#   golden CtrlBlock.sv     -> 329 寄存器 decl + next-state 形二分类
#                              (297 load-port `if(valid) r <= io_..._bits_<field>` /
#                               32 hold-clear `r <= ~io_..._valid & r`)
#   ctrlblock_wbdelayed.svh -> 329 wbd 窄寄存器 decl + `if(wbInValid[N])` 赋值
#   ctrlblock_wbpack.svh    -> wbInValid[N]=io_..._N_valid 恒等 + 端口装包成员集
#                              (load-port 字段必须端口装包; hold-clear 字段必须
#                               **不**装包 = '{default:'0} 落 0 → 与 golden
#                               `valid?0:self ≡ ~valid&self` 真等价, FM 匹配后实证)
#   wbdelayed_field_inventory.json -> per-lane 保留字段集独立交叉核对
# fail-closed: 两侧 329==329 守恒、逐对同 lane 同 field 同位宽、无跨映射、每端唯一、
# 无黑盒内部路径、分类全覆盖零重叠、golden 无 reset 耦合——任一破 => exit 非零。
# 产出: verif/ut/CtrlBlock/ctrlblock_wbd_prepin_manifest.json(329 对/5362 位 + sha256)
#       verif/ut/CtrlBlock/fm_pins_pre.tcl(生成式 pre-match 钉点, 运行时 fail-closed)
# ============================================================================
import argparse
import hashlib
import json
import re
import sys

TOP = "CtrlBlock"
WBD_PREFIX = "delayedNotFlushedWriteBack_delayed_bits_r"


def strip_impl(ip):
    """impl 路径 -> 去 i:/WORK/TOP/ 与 u_core/ 前缀、去转义反斜杠的规范键。"""
    key = ip
    key = re.sub(r"^i:/WORK/" + TOP + r"/", "", key)
    key = re.sub(r"^u_core/", "", key)
    key = key.replace("\\", "")
    return key


def ref_to_impl_key(rel):
    """fm_pins.tcl 的命名规则表(逐字镜像 ctrlblock_pin_unmatched)。
    输入 = ref 相对路径(去 r:/WORK/TOP/ 前缀); 返回 impl 规范键或 None(非寄存器/无规则)。"""
    m = re.match(r"^enqRob_req_(\d+)_bits_r_(\w+?)_reg(\[\d+\])?$", rel)
    if m:
        k, f, b = m.group(1), m.group(2), (m.group(3) or "")
        return f"enqRobBits_reg[{k}][{f}]{b}"
    # 窄化(b490e6b1)后 impl 为 wbd<lane>_<field> 窄寄存器(exceptionVec 逐位标量,
    # 位号内嵌字段名: golden `..._r_20_exceptionVec_10_reg` -> `wbd20_exceptionVec_10_reg`;
    # 多位字段逐位: `..._r_20_robIdx_value_reg[3]` -> `wbd20_robIdx_value_reg[3]`)。
    # lane0 = golden bare `..._r_<field>` -> wbd0_<field>。正常路径下全族已由
    # fm_pins_pre.tcl 匹配前钉死, 此规则仅作漂移时的 unmatched 池兜底。
    m = re.match(r"^delayedNotFlushedWriteBack_delayed_bits_r_(\d+)_(\w+?)_reg(\[\d+\])?$", rel)
    if m:
        return f"wbd{m.group(1)}_{m.group(2)}_reg{m.group(3) or ''}"
    m = re.match(r"^delayedNotFlushedWriteBack_delayed_bits_r_([a-zA-Z]\w*?)_reg(\[\d+\])?$", rel)
    if m:
        return f"wbd0_{m.group(1)}_reg{m.group(2) or ''}"
    m = re.match(r"^delayedNotFlushedWriteBackNums_delayed_bits_r_(\d+)_reg(\[\d+\])?$", rel)
    if m:
        return f"wbNumsBits_reg[{m.group(1)}]{m.group(2) or ''}"
    m = re.match(r"^delayedNotFlushedWriteBackNums_delayed_bits_r_reg(\[\d+\])?$", rel)
    if m:
        return f"wbNumsBits_reg[0]{m.group(1) or ''}"
    m = re.match(r"^redirectGen_io_oldestExuRedirect_bits_r_(\w+?)_reg(\[\d+\])?$", rel)
    if m:
        return f"oldestExuRedirectBits_reg[{m.group(1)}]{m.group(2) or ''}"
    if re.match(r"^s3_s5_redirect_next_bits_r_level_reg$", rel):
        return "s3_s5_redirect_level_reg"
    if re.match(r"^s3_s5_redirect_next_bits_r_robIdx_flag_reg$", rel):
        return "s3_s5_redirect_robFlag_reg"
    m = re.match(r"^s3_s5_redirect_next_bits_r_robIdx_value_reg(\[\d+\])?$", rel)
    if m:
        return f"s3_s5_redirect_robValue_reg{m.group(1) or ''}"
    if re.match(r"^s3_s5_redirect_next_valid_last_REG_reg$", rel):
        return "s3_s5_redirect_valid_reg"
    if re.match(r"^s2_s4_redirect_next_valid_last_REG_reg$", rel):
        return "s2_s4_redirect_valid_reg"
    m = re.match(r"^decodeBufBits_(\d+)_foldpc_reg(\[\d+\])?$", rel)
    if m:
        return f"decodeBufBits_reg[{m.group(1)}][foldpc]{m.group(2) or ''}"
    m = re.match(r"^io_perf_(\d+)_value_REG_reg(\[\d+\])?$", rel)
    if m:
        return f"perfStage0_reg[{m.group(1)}]{m.group(2) or ''}"
    m = re.match(r"^io_perf_(\d+)_value_REG_1_reg(\[\d+\])?$", rel)
    if m:
        return f"perfStage1_reg[{m.group(1)}]{m.group(2) or ''}"
    return None


# 黑盒(16 子模块)与已 partitioned 的 rob 内部层次前缀: 任何指向这些内部寄存器的
# 引用都是非法钉点(FM-036 或跨黑盒边界), fail-closed 拒绝。
BLACKBOX_HIER = re.compile(
    r"/(rob|rename|dispatch|decode|fusionDecoder|redirectGen|gpaMem|memCtrl|trace|"
    r"pcMem|snapshotGen|s0_snpt|renameTableWrapper|decodePipeRenameModule|"
    r"pipeGroupConnect|pipelineConnect|delayN)/",
    re.IGNORECASE,
)


def load_list(path):
    out = []
    with open(path, encoding="utf-8") as fh:
        for ln in fh.read().split("\n"):
            ln = ln.strip()
            if ln:
                out.append(ln)
    return out


def derive_from_fmlog(fmlog):
    refs, impls = [], []
    with open(fmlog, encoding="utf-8", errors="replace") as fh:
        for ln in fh:
            m = re.match(r"^\s*Ref\s+DFF\S*\s+(r:\S+)", ln)
            if m:
                refs.append(m.group(1))
                continue
            m = re.match(r"^\s*Impl\s+DFF\S*\s+(i:\S+)", ln)
            if m:
                impls.append(m.group(1))
    return refs, impls


# ============================================================================
# --wbd 模式实现(codex 0127 Lane A)
# ============================================================================

def _sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        h.update(fh.read())
    return h.hexdigest()


def wbd_parse_golden(path):
    """golden -> {(lane,field): {name,w,form,data}}; 两形分类全覆盖零重叠, 否则 exit。
    form: load_port  = `if (io_fromWB_wbData_N_valid) name <= io_fromWB_wbData_N_bits_<field>;`
          hold_clear = `name <= ~io_fromWB_wbData_N_valid & name;`(firtool 端口 DCE 后
                       的 valid?0:self 常数形, "Constrained 0X")
    另断言: 无 reset 耦合(同一行含 reset 与寄存器名 => exit)。"""
    txt = open(path, encoding="utf-8", errors="replace").read()
    regs = {}
    for m in re.finditer(
            r"^\s*reg\s*(\[(\d+):0\])?\s*(" + WBD_PREFIX + r"(?:_(\d+))?_(\w+))\s*;",
            txt, re.M):
        w = int(m.group(2)) + 1 if m.group(2) else 1
        lane = int(m.group(4)) if m.group(4) else 0
        key = (lane, m.group(5))
        if key in regs:
            sys.exit(f"WBD FAIL golden duplicate reg decl: {m.group(3)}")
        regs[key] = {"name": m.group(3), "w": w}
    hold, load = set(), {}
    for m in re.finditer(
            r"(" + WBD_PREFIX + r"\w*) <=\s*\n\s*~io_fromWB_wbData_(\d+)_valid\s*\n\s*& \1;",
            txt):
        mm = re.match(WBD_PREFIX + r"(?:_(\d+))?_(\w+)$", m.group(1))
        lane = int(mm.group(1)) if mm.group(1) else 0
        if int(m.group(2)) != lane:
            sys.exit(f"WBD FAIL hold-clear valid-lane mismatch: {m.group(1)} vs valid_{m.group(2)}")
        hold.add((lane, mm.group(2)))
    for m in re.finditer(
            r"(" + WBD_PREFIX + r"\w*) <=\s*\n?\s*io_fromWB_wbData_(\d+)_bits_(\w+);",
            txt):
        mm = re.match(WBD_PREFIX + r"(?:_(\d+))?_(\w+)$", m.group(1))
        lane = int(mm.group(1)) if mm.group(1) else 0
        key = (lane, mm.group(2))
        if int(m.group(2)) != lane or m.group(3) != mm.group(2):
            sys.exit(f"WBD FAIL load-port name/lane mismatch: {m.group(0)!r}")
        load[key] = f"io_fromWB_wbData_{lane}_bits_{mm.group(2)}"
    uncls = set(regs) - hold - set(load)
    if uncls:
        sys.exit(f"WBD FAIL golden regs with unrecognized next-state form ({len(uncls)}): {sorted(uncls)[:5]}")
    if hold & set(load):
        sys.exit(f"WBD FAIL golden regs in BOTH forms: {sorted(hold & set(load))[:5]}")
    reset_coupled = [ln for ln in txt.split("\n") if "reset" in ln and WBD_PREFIX in ln]
    if reset_coupled:
        sys.exit(f"WBD FAIL golden delayed regs reset-coupled ({len(reset_coupled)}): {reset_coupled[:2]}")
    for key in regs:
        regs[key]["form"] = "hold_clear" if key in hold else "load_port"
        regs[key]["data"] = "0" if key in hold else load[key]
    return regs


def wbd_parse_svh(path):
    """ctrlblock_wbdelayed.svh -> {(lane,field): {name,w}}; 断言每寄存器恰有一条
    `wbd<N>_<F> <= wbInBits[N].<member>;` 且 member 与 field 逐字对应
    (exceptionVec_<j> <-> exceptionVec[<j>])。"""
    txt = open(path, encoding="utf-8", errors="replace").read()
    decls = {}
    for m in re.finditer(r"^\s*logic\s*(\[(\d+):0\])?\s*(wbd(\d+)_(\w+))\s*;", txt, re.M):
        w = int(m.group(2)) + 1 if m.group(2) else 1
        key = (int(m.group(4)), m.group(5))
        if key in decls:
            sys.exit(f"WBD FAIL svh duplicate decl: {m.group(3)}")
        decls[key] = {"name": m.group(3), "w": w}
    assigns = {}
    for m in re.finditer(r"wbd(\d+)_(\w+) <= wbInBits\[(\d+)\]\.(\w+)(\[(\d+)\])?;", txt):
        lane, field = int(m.group(1)), m.group(2)
        memb = m.group(4) + (("_" + m.group(6)) if m.group(6) else "")
        if int(m.group(3)) != lane or memb != field:
            sys.exit(f"WBD FAIL svh assign lane/member mismatch: {m.group(0)!r}")
        if (lane, field) in assigns:
            sys.exit(f"WBD FAIL svh double assign: wbd{lane}_{field}")
        assigns[(lane, field)] = True
    if set(decls) != set(assigns):
        sys.exit(f"WBD FAIL svh decl/assign set mismatch: "
                 f"decl-only={sorted(set(decls)-set(assigns))[:5]} "
                 f"assign-only={sorted(set(assigns)-set(decls))[:5]}")
    return decls


def wbd_parse_wbpack(path):
    """ctrlblock_wbpack.svh -> (端口装包成员集 {(lane, member)}, valid 恒等 lane 数)。
    断言 wbInValid[N] = io_fromWB_wbData_N_valid 逐路恒等(enable 同源)。"""
    txt = open(path, encoding="utf-8", errors="replace").read()
    ported = set()
    for m in re.finditer(r"wbInBits\[(\d+)\]\.(\w+)(\[(\d+)\])? = (io_fromWB_wbData_(\d+)_bits_\w+);", txt):
        lane = int(m.group(1))
        memb = m.group(2) + (("_" + m.group(4)) if m.group(4) else "")
        if int(m.group(6)) != lane:
            sys.exit(f"WBD FAIL wbpack cross-lane port assign: {m.group(0)!r}")
        ported.add((lane, memb))
    vm = re.findall(r"assign wbInValid\[(\d+)\] = io_fromWB_wbData_(\d+)_valid;", txt)
    if not vm or any(a != b for a, b in vm):
        sys.exit(f"WBD FAIL wbpack wbInValid not identity-mapped: {vm[:5]}")
    return ported, len(vm)


def wbd_check_inventory(path, gold):
    """inventory per-lane kept 字段集(exceptionVec 折叠计 1) == golden 派生集, 否则 exit。"""
    inv = json.load(open(path, encoding="utf-8"))
    derived = {}
    for (lane, field) in gold:
        fam = re.sub(r"^exceptionVec_\d+$", "exceptionVec", field)
        derived.setdefault(lane, set()).add(fam)
    for lane_s, ent in inv["lanes"].items():
        lane = int(lane_s)
        kept = {e["field"] for e in ent["kept"]}
        if kept != derived.get(lane, set()):
            sys.exit(f"WBD FAIL inventory lane {lane} kept set != golden-derived: "
                     f"inv-only={sorted(kept - derived.get(lane, set()))} "
                     f"gold-only={sorted(derived.get(lane, set()) - kept)}")
    if set(int(k) for k in inv["lanes"]) != set(l for l, _ in gold):
        sys.exit("WBD FAIL inventory lane set != golden lane set")


# gate3 残余 170 unread_impl 的机械分类(family regex -> (预期计数, golden 侧空证据说明))。
# ★诚实: 170 中**没有任何** wbd<lane>_<field> 点(0127 任务简报前提修正); 156 为
# impl-only cone-dead(golden 无对应寄存器 => 无可 pin 对象), 14 为对称 both-side dead
# (golden 侧即 dead_ref 声明的 target_r[50:63]; CtrlBlock 无 vmucp 白名单, 钉了会产
# unread_notcompared>0 反而 PARTIAL)。二者都只能由后续 impl RTL 窄化收敛, 非 pin 可消。
WBD_170_FAMILIES = [
    ("enqRobBits_excvec", r"enqRobBits_reg\[[0-5]\]\\?\[exceptionVec\]\[(\d+)\]", 96,
     "impl-only: golden enqRob_req_<k>_bits_r_exceptionVec_* 仅保留位 {0,1,2,3,12,20,22}"),
    ("decodeBufBits_excvec", r"decodeBufBits_reg\[[0-5]\]\\?\[exceptionVec\]\[(3|22)\]", 12,
     "impl-only: golden decodeBufBits_<k>_exceptionVec_* 无位 3/22"),
    ("feFlushRob", r"feFlushRob(Flag_reg|Value_reg\[\d+\])", 9,
     "impl-only: impl frontendFlush robIdx 打拍寄存器无读者; golden 无对应寄存器"),
    ("perfStage40", r"perfStage[01]_reg\[40\]\[0\]", 2,
     "impl-only: golden 无 io_perf_40 端口(indices 跳 40), perfStage[40] 锥死"),
    ("toFtqCfiTargetR_hi", r"toFtqCfiTargetR_reg\[(5\d|6[0-3])\]", 14,
     "对称 both-side dead: golden io_frontend_toFtq_..._cfiUpdate_target_r[50:63] "
     "已 dead_ref 声明; 无 vmucp 白名单 => 不可 pin(会产 nc>0)"),
    ("wbDelayedValid", r"wbDelayedValid_reg\[(0|2|4|6|8|9|10|11|12|15|16|17)\]", 12,
     "impl-only: golden delayedNotFlushedWriteBack_delayed_valid_last_REG_* 仅有 lanes "
     "{1,3,5,7,13,14,18,19,20,21,22,23,24}"),
    ("wbNumsValid", r"wbNumsValid_reg\[([0-9]|1[0-9]|2[0-4])\]", 25,
     "impl-only: golden 无 delayedNotFlushedWriteBackNums_delayed_valid* 寄存器"),
]


def wbd_disposition(native_facts_path, gold):
    """从 gate3 native_facts 机械分类 170 unread_impl + 核对 13 compare_ref 全被
    pre-pin ref 集覆盖。任何未落族的点 / 计数不符 / wbd 点混入 => exit(不静默排除)。"""
    nf = json.load(open(native_facts_path, encoding="utf-8"))
    u170 = nf["objects"]["unmatched_unread_impl"]
    c13 = nf["objects"]["unmatched_ref"]
    wbd_in_170 = [p for p in u170 if re.search(r"/wbd\d+_", p)]
    if wbd_in_170:
        sys.exit(f"WBD FAIL premise: {len(wbd_in_170)} of unread_impl ARE wbd regs: {wbd_in_170[:3]}")
    fam_hits = {name: [] for name, *_ in WBD_170_FAMILIES}
    unclassified = []
    for p in u170:
        for name, rx, _, _ in WBD_170_FAMILIES:
            if re.search(rx, p):
                fam_hits[name].append(p)
                break
        else:
            unclassified.append(p)
    if unclassified:
        sys.exit(f"WBD FAIL {len(unclassified)} unread_impl points not in any known family "
                 f"(单列勿静默排除): {unclassified[:5]}")
    for name, _, expect_n, _ in WBD_170_FAMILIES:
        if len(fam_hits[name]) != expect_n:
            sys.exit(f"WBD FAIL family {name}: got {len(fam_hits[name])} expect {expect_n}")
    # 13 compare_ref 必须全是 golden hold-clear 且 ∈ pre-pin ref 集
    hold_names = {v["name"] for v in gold.values() if v["form"] == "hold_clear"}
    bad13 = [p for p in c13 if re.sub(r"^r:/WORK/" + TOP + r"/(.*)_reg$", r"\1", p) not in hold_names]
    if bad13:
        sys.exit(f"WBD FAIL compare_ref not covered by hold-clear pre-pin set: {bad13}")
    return {
        "evidence_run_id": nf.get("run_id"),
        "unread_impl_total": len(u170),
        "compare_ref_total": len(c13),
        "compare_ref_all_covered_by_prepin": True,
        "wbd_points_in_unread_impl": 0,
        "families": [
            {"family": name, "count": len(fam_hits[name]), "why_not_pinnable": why,
             "points": sorted(fam_hits[name])}
            for name, _, _, why in WBD_170_FAMILIES
        ],
    }


def wbd_emit(a):
    gold = wbd_parse_golden(a.wbd_golden)
    impl = wbd_parse_svh(a.wbd_svh)
    ported, nvalid = wbd_parse_wbpack(a.wbd_wbpack)
    wbd_check_inventory(a.wbd_inventory, gold)

    # ---- fail-closed 守恒 + 双射 + 位宽 ----
    errs = []
    only_g = sorted(set(gold) - set(impl))
    only_i = sorted(set(impl) - set(gold))
    if only_g:
        errs.append(f"{len(only_g)} golden-only regs (impl 缺 reg): {only_g[:5]}")
    if only_i:
        errs.append(f"{len(only_i)} impl-only wbd regs (golden 无): {only_i[:5]}")
    wmis = [k for k in set(gold) & set(impl) if gold[k]["w"] != impl[k]["w"]]
    if wmis:
        errs.append(f"{len(wmis)} width mismatch: {wmis[:5]}")
    if errs:
        sys.exit("WBD FAIL bijection:\n  " + "\n  ".join(errs))
    # load-port 字段必须端口装包; hold-clear 必须不装包(=tied0, 与 golden 常数形真等价)
    for key, gv in sorted(gold.items()):
        lane, field = key
        if gv["form"] == "load_port" and key not in ported:
            sys.exit(f"WBD FAIL load-port field NOT port-packed in wbpack: wbd{lane}_{field}")
        if gv["form"] == "hold_clear" and key in ported:
            sys.exit(f"WBD FAIL hold-clear field IS port-packed (would mismatch golden const): wbd{lane}_{field}")

    # ---- 逐位 pair 展开(稳定序) + 唯一性/无跨映射断言 ----
    pairs, seen_r, seen_i = [], set(), set()
    for key in sorted(gold):
        lane, field = key
        gname, iname, w = gold[key]["name"], impl[key]["name"], gold[key]["w"]
        for b in range(w):
            suf = f"[{b}]" if w > 1 else ""
            rp = f"r:/WORK/{TOP}/{gname}_reg{suf}"
            ip = f"i:/WORK/{TOP}/u_core/{iname}_reg{suf}"
            if rp in seen_r or ip in seen_i:
                sys.exit(f"WBD FAIL duplicate path in expansion: {rp} / {ip}")
            if BLACKBOX_HIER.search(rp) or BLACKBOX_HIER.search(ip):
                sys.exit(f"WBD FAIL blackbox-internal path: {rp} / {ip}")
            seen_r.add(rp)
            seen_i.add(ip)
            pairs.append((rp, ip))
    if len(pairs) != len(seen_r) or len(pairs) != len(seen_i):
        sys.exit("WBD FAIL not a bijection after expansion")
    blob = "".join(f"{r}\t{i}\n" for r, i in pairs).encode()
    digest = hashlib.sha256(blob).hexdigest()
    nbits = len(pairs)
    nload = sum(1 for v in gold.values() if v["form"] == "load_port")
    nhold = len(gold) - nload

    disposition = wbd_disposition(a.wbd_evidence, gold) if a.wbd_evidence else None

    # ---- manifest ----
    entries = []
    for key in sorted(gold):
        lane, field = key
        gv, iv = gold[key], impl[key]
        if gv["form"] == "load_port":
            g_next = (f"RegEnable(en=io_fromWB_wbData_{lane}_valid, d={gv['data']}), no reset")
            i_next = (f"RegEnable(en=wbInValid[{lane}]==io_fromWB_wbData_{lane}_valid, "
                      f"d=wbInBits[{lane}].{field}<=port {gv['data']}), no reset")
        else:
            g_next = (f"hold-clear: r <= ~io_fromWB_wbData_{lane}_valid & r "
                      f"(== RegEnable(en=valid, d=1'b0); firtool 端口 DCE 常数形)")
            i_next = (f"RegEnable(en=wbInValid[{lane}]==io_fromWB_wbData_{lane}_valid, "
                      f"d=wbInBits[{lane}].{field} tied 1'b0 via '{{default:'0}}, 未装包), no reset; "
                      f"valid?0:self ≡ ~valid&self => FM 匹配后实证等价")
        entries.append({
            "lane": lane, "field": field, "width": gv["w"],
            "ref_reg": gv["name"], "impl_reg": iv["name"],
            "ref_path_base": f"r:/WORK/{TOP}/{gv['name']}_reg",
            "impl_path_base": f"i:/WORK/{TOP}/u_core/{iv['name']}_reg",
            "family": gv["form"],
            "golden_next_state": g_next,
            "impl_next_state": i_next,
            "reset": "none/none",
        })

    manifest = {
        "schema": "ctrlblock-wbd-prepin-bijection-v1",
        "top": TOP,
        "proof_mode": "assembly",
        "phase": "FM_PIN_PRE_TCL (before first match; user match 先于 auto-match/merge)",
        "description": (
            "b490e6b1 wbdelayed per-lane narrowing introduced wbd<lane>_<field> registers "
            "(exact golden-surviving field/bit set). Full-family pre-match bijection to golden "
            f"{WBD_PREFIX}[_N]_<field> (lane0 bare). 297 load-port pairs are literal same-source; "
            "32 hold-clear pairs are golden `~valid&self` const-form vs impl RegEnable(valid,d=0) "
            "-- next-state forms differ textually, FM verifies the equivalence after matching "
            "(both Constrained-0X constants). Fixes gate3 compare_ref=13 (impl const scalars "
            "merged/shuffled by FM before old post-match pin proc could pair them)."
        ),
        "generator": ("scripts/gen_ctrlblock_pin_manifest.py --wbd "
                      "(mechanical: golden+svh+wbpack+inventory cross-derived; fail-closed)"),
        "sources_sha256": {
            "golden_CtrlBlock_sv": _sha256_file(a.wbd_golden),
            "ctrlblock_wbdelayed_svh": _sha256_file(a.wbd_svh),
            "ctrlblock_wbpack_svh": _sha256_file(a.wbd_wbpack),
            "wbdelayed_field_inventory_json": _sha256_file(a.wbd_inventory),
        },
        "reg_pair_count": len(gold),
        "bit_pair_count": nbits,
        "families": {"load_port": nload, "hold_clear_const0": nhold},
        "conservation": {
            "golden_only": 0, "impl_only": 0, "width_mismatch": 0,
            "bijection": True, "unique_ref": True, "unique_impl": True,
            "cross_lane_or_field_mappings": 0, "blackbox_internal_paths": 0,
            "wbInValid_identity_lanes": nvalid,
        },
        "pairs_sha256": digest,
        "pairs": entries,
    }
    if disposition is not None:
        manifest["gate3_residual_disposition"] = disposition
    with open(a.wbd_out_manifest, "w", encoding="utf-8") as fh:
        json.dump(manifest, fh, indent=1, ensure_ascii=False)
        fh.write("\n")

    # ---- fm_pins_pre.tcl(生成式; 运行时 fail-closed) ----
    lines = []
    lines.append("# ============================================================================")
    lines.append("# fm_pins_pre.tcl -- CtrlBlock wbdelayed 窄寄存器**匹配前**全族双射钉点")
    lines.append("# (codex 0127 Lane A; GENERATED -- DO NOT EDIT BY HAND)")
    lines.append("#   regen: python3 scripts/gen_ctrlblock_pin_manifest.py --wbd \\")
    lines.append("#            --wbd-golden <golden>/CtrlBlock.sv \\")
    lines.append("#            --wbd-svh rtl/backend/ctrlblock_wbdelayed.svh \\")
    lines.append("#            --wbd-wbpack rtl/backend/ctrlblock_wbpack.svh \\")
    lines.append("#            --wbd-inventory verif/ut/CtrlBlock/wbdelayed_field_inventory.json \\")
    lines.append("#            --wbd-out-manifest verif/ut/CtrlBlock/ctrlblock_wbd_prepin_manifest.json \\")
    lines.append("#            --wbd-out-pretcl verif/ut/CtrlBlock/fm_pins_pre.tcl")
    lines.append("# ----------------------------------------------------------------------------")
    lines.append("# 为什么必须匹配前(FM_PIN_PRE_TCL): gate3(SGN-CtrlBlock-1786114121)实证, 窄化后")
    lines.append("# 32 个 hold-clear 常数窄标量在 FM merge/常数配对 shuffle 下留 13 个 golden 侧")
    lines.append("# lane-20 exceptionVec unmatched(compare_ref=13), impl 对象不再出现在 unmatched")
    lines.append("# 池 => 匹配后 pin 机器(fm_pins.tcl)拿不到。user match 在首次 match 前钉全族 329")
    lines.append(f"# 寄存器/{nbits} 位, 先于 auto-match/merge, 双射确定性成立。")
    lines.append("# 32 个 hold-clear 对: golden `r <= ~valid & r` vs impl RegEnable(valid, d=0)")
    lines.append("# -- next-state 表达式形不同但函数相同(valid?0:self), FM 匹配后**实际比较**证明,")
    lines.append("# 非 dont_verify/非 vmucp/非强配(两侧同为 Constrained-0X 常数)。")
    lines.append(f"# bijection: ctrlblock_wbd_prepin_manifest.json (sha256 pairs={digest})")
    lines.append("# 运行时 fail-closed: 任一 set_user_match 失败或计数≠预期 => error 中止 gate")
    lines.append("# (对象缺失=RTL/golden 漂移, 早停优于跑完得一个误导性 PARTIAL)。")
    lines.append("# ============================================================================")
    lines.append("proc ctrlblock_wbd_prepin { top } {")
    lines.append("    # {golden_reg_base impl_wbd_base width} x " + str(len(gold)))
    lines.append("    set pairs {")
    for key in sorted(gold):
        gname, iname, w = gold[key]["name"], impl[key]["name"], gold[key]["w"]
        lines.append(f"        {gname} {iname} {w}")
    lines.append("    }")
    lines.append("    set n 0")
    lines.append("    set fails 0")
    lines.append("    foreach {rb ib w} $pairs {")
    lines.append("        for {set b 0} {$b < $w} {incr b} {")
    lines.append("            if {$w == 1} {")
    lines.append("                set rp \"r:/WORK/${top}/${rb}_reg\"")
    lines.append("                set ip \"i:/WORK/${top}/u_core/${ib}_reg\"")
    lines.append("            } else {")
    lines.append("                set rp \"r:/WORK/${top}/${rb}_reg\\[$b\\]\"")
    lines.append("                set ip \"i:/WORK/${top}/u_core/${ib}_reg\\[$b\\]\"")
    lines.append("            }")
    lines.append("            if {[catch {set_user_match $rp $ip} msg]} {")
    lines.append("                incr fails")
    lines.append("                puts \"CTRLBLOCK_WBD_PREPIN_FAIL: $rp <-> $ip ($msg)\"")
    lines.append("            } else {")
    lines.append("                incr n")
    lines.append("            }")
    lines.append("        }")
    lines.append("    }")
    lines.append(f"    puts \"CTRLBLOCK_WBD_PREPIN: $n pinned, $fails failed (expect {nbits}/0)\"")
    lines.append(f"    if {{$fails != 0 || $n != {nbits}}} {{")
    lines.append(f"        error \"CTRLBLOCK_WBD_PREPIN_FAIL: n=$n fails=$fails expect={nbits}/0 (wbd 双射破; 中止 gate)\"")
    lines.append("    }")
    lines.append("}")
    lines.append("ctrlblock_wbd_prepin $top")
    with open(a.wbd_out_pretcl, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines) + "\n")

    print(f"OK wbd manifest {a.wbd_out_manifest}: {len(gold)} regs / {nbits} bit-pairs, "
          f"sha256={digest}")
    print(f"   families: load_port={nload} hold_clear_const0={nhold}; "
          f"bijection=True golden_only=0 impl_only=0 width_mismatch=0")
    print(f"OK pre-pin tcl {a.wbd_out_pretcl}")
    if disposition:
        print(f"   gate3 disposition: compare_ref={disposition['compare_ref_total']} covered; "
              f"unread_impl={disposition['unread_impl_total']} classified "
              f"({len(disposition['families'])} families, 0 wbd, 0 unclassified)")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ref-list", help="golden 未匹配 DFF 路径(每行一个 r:/...)")
    ap.add_argument("--impl-list", help="impl 未匹配 DFF 路径(每行一个 i:/...)")
    ap.add_argument("--from-fmlog", help="从官方 gate fm_log 派生 ref/impl DFF 集")
    ap.add_argument("--out", help="输出 manifest JSON 路径(legacy 模式必填)")
    ap.add_argument("--expect", type=int, default=1962, help="期望对数(守恒断言)")
    ap.add_argument("--wbd", action="store_true",
                    help="wbdelayed 窄寄存器 pre-match 双射模式(codex 0127)")
    ap.add_argument("--wbd-golden", help="golden CtrlBlock.sv 路径")
    ap.add_argument("--wbd-svh", help="rtl/backend/ctrlblock_wbdelayed.svh 路径")
    ap.add_argument("--wbd-wbpack", help="rtl/backend/ctrlblock_wbpack.svh 路径")
    ap.add_argument("--wbd-inventory", help="wbdelayed_field_inventory.json 路径")
    ap.add_argument("--wbd-evidence", help="gate3 native_facts.json(170/13 disposition, 可选)")
    ap.add_argument("--wbd-out-manifest", help="输出 wbd manifest JSON")
    ap.add_argument("--wbd-out-pretcl", help="输出 fm_pins_pre.tcl")
    a = ap.parse_args()

    if a.wbd:
        need = ["wbd_golden", "wbd_svh", "wbd_wbpack", "wbd_inventory",
                "wbd_out_manifest", "wbd_out_pretcl"]
        missing = [k for k in need if not getattr(a, k)]
        if missing:
            sys.exit(f"--wbd mode needs: {', '.join('--' + m.replace('_', '-') for m in missing)}")
        wbd_emit(a)
        return

    if not a.out:
        sys.exit("legacy mode needs --out")

    if a.from_fmlog:
        refs, impls = derive_from_fmlog(a.from_fmlog)
    elif a.ref_list and a.impl_list:
        refs, impls = load_list(a.ref_list), load_list(a.impl_list)
    else:
        sys.exit("need --from-fmlog OR (--ref-list AND --impl-list)")

    refs = sorted(set(refs))
    impls = sorted(set(impls))

    # 黑盒/rob 内部引用 fail-closed
    bad = [p for p in refs + impls if BLACKBOX_HIER.search(p)]
    if bad:
        sys.exit(f"FAIL blackbox-internal reference present ({len(bad)}): {bad[:3]}")

    # impl 规范键 LUT
    ilut = {}
    for ip in impls:
        k = strip_impl(ip)
        if k in ilut:
            sys.exit(f"FAIL duplicate impl canonical key: {k}")
        ilut[k] = ip

    pairs = []
    used = set()
    no_rule, no_impl = [], []
    for rp in refs:
        rel = re.sub(r"^r:/WORK/" + TOP + r"/", "", rp)
        key = ref_to_impl_key(rel)
        if key is None:
            no_rule.append(rel)
            continue
        ip = ilut.get(key)
        if ip is None:
            no_impl.append((rel, key))
            continue
        if key in used:
            sys.exit(f"FAIL collision: two refs map to impl key {key}")
        used.add(key)
        pairs.append({"ref": rp, "impl": ip, "impl_key": key})

    leftover_impl = sorted(set(ilut) - used)

    # ---- fail-closed 守恒 + bijection ----
    errs = []
    if no_rule:
        errs.append(f"{len(no_rule)} ref have NO rule (e.g. {no_rule[:3]})")
    if no_impl:
        errs.append(f"{len(no_impl)} ref map to MISSING impl key (e.g. {no_impl[:3]})")
    if leftover_impl:
        errs.append(f"{len(leftover_impl)} impl unconsumed (e.g. {leftover_impl[:3]})")
    if len(refs) != len(impls):
        errs.append(f"count asym ref={len(refs)} impl={len(impls)}")
    if len(pairs) != len(refs) or len(pairs) != len(impls):
        errs.append(f"not full bijection: pairs={len(pairs)} ref={len(refs)} impl={len(impls)}")
    if a.expect and len(pairs) != a.expect:
        errs.append(f"expected {a.expect} pairs, got {len(pairs)}")
    if errs:
        sys.exit("FAIL bijection:\n  " + "\n  ".join(errs))

    # 稳定序 + 每对 hash
    pairs.sort(key=lambda p: (p["ref"], p["impl"]))
    blob = "".join(f"{p['ref']}\t{p['impl']}\n" for p in pairs).encode()
    digest = hashlib.sha256(blob).hexdigest()

    manifest = {
        "schema": "ctrlblock-pin-bijection-v1",
        "top": TOP,
        "proof_mode": "assembly",
        "description": (
            "golden(firtool flattened field names) <-> readable-core struct/array "
            "registers; symmetric same-source constant-0 registers that FM "
            "auto_match_flattened_arrays cannot pair (field-name-embedded struct+array). "
            "set_user_match makes them matched compare points; verify proves 0==0 passing. "
            "NOT dont_verify, NOT vmucp masking, NOT forced-match over a real diff."
        ),
        "pair_count": len(pairs),
        "ref_count": len(refs),
        "impl_count": len(impls),
        "bijection": True,
        "pairs_sha256": digest,
        "pairs": pairs,
    }
    with open(a.out, "w", encoding="utf-8") as fh:
        json.dump(manifest, fh, indent=1, ensure_ascii=False)
        fh.write("\n")
    print(f"OK wrote {a.out}: {len(pairs)} pairs, sha256={digest}")
    print(f"   ref={len(refs)} impl={len(impls)} bijection=True leftover_impl=0 no_rule=0 no_impl=0")


if __name__ == "__main__":
    main()
