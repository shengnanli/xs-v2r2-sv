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
# ============================================================================
import argparse
import hashlib
import json
import re
import sys

TOP = "CtrlBlock"


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
    m = re.match(r"^delayedNotFlushedWriteBack_delayed_bits_r_(\d+)_exceptionVec_(\d+)_reg$", rel)
    if m:
        return f"wbDelayedBits_reg[{m.group(1)}][exceptionVec][{m.group(2)}]"
    m = re.match(r"^delayedNotFlushedWriteBack_delayed_bits_r_(\d+)_(debug_\w+)_reg$", rel)
    if m:
        return f"wbDelayedBits_reg[{m.group(1)}][{m.group(2)}]"
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


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ref-list", help="golden 未匹配 DFF 路径(每行一个 r:/...)")
    ap.add_argument("--impl-list", help="impl 未匹配 DFF 路径(每行一个 i:/...)")
    ap.add_argument("--from-fmlog", help="从官方 gate fm_log 派生 ref/impl DFF 集")
    ap.add_argument("--out", required=True, help="输出 manifest JSON 路径")
    ap.add_argument("--expect", type=int, default=1962, help="期望对数(守恒断言)")
    a = ap.parse_args()

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
