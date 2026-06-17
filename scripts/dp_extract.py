#!/usr/bin/env python3
"""
DataPath 实例拓扑抽取器(只抽「实例配置常量/互联拓扑」,不抽 golden 组合逻辑)。

DataPath 高度参数化:27 路异构 EXU、5 寄存器域,各 EXU 的源数 / 每源读哪个域哪个读口 /
og1 响应类型 / ctrl 字段集 / imm 透传 / pc-target 索引 / 0 延迟取消等,均由 BackendParams
弹性化定死,Scala 源里无具体数字。本脚本解析 golden DataPath.sv 把这套「实例配置」抽成
结构化 JSON,供 gen_datapath.py 把五条数据流重写为可读 SV(genvar/function 在表上重做)。

抽取的是「连到哪/有没有/几位宽/什么类型」,不是 golden 的 wire/assign 逻辑。
"""
import re
import json
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GSV = (XSSV / "golden/chisel-rtl/DataPath.sv").read_text()
LINES = GSV.splitlines()
DOMAINS = ["Int", "Fp", "Vf", "V0", "Vl"]
# toExu 端口域名 -> 对应 fromIQ 域名
PORTDOM2IQ = {"Int": "Int", "Fp": "Fp", "Vec": "Vf", "Mem": "Mem"}


def port_widths():
    m = re.search(r"^module DataPath\((.*?)\n\);", GSV, re.S | re.M)
    pw = {}
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            pw[pm.group(3)] = (pm.group(1),
                               int(pm.group(2)) + 1 if pm.group(2) else 1)
    return pw


def exu_global_map():
    m = {}
    for mm in re.finditer(
            r"io_to([A-Za-z]+)Exu_(\d+)_(\d+)_valid = s1_toExuValid_(\d+)_(\d+);", GSV):
        dom, i, j, g, s = mm.groups()
        m[(int(g), int(s))] = (dom, int(i), int(j))
    return m


def num_reg_src():
    cnt = {}
    for mm in re.finditer(r"io_to([A-Za-z]+)Exu_(\d+)_(\d+)_bits_src_(\d+)\b", GSV):
        dom, i, j, k = mm.groups()
        cnt[(dom, int(i), int(j))] = max(cnt.get((dom, int(i), int(j)), 0), int(k) + 1)
    return cnt


def src_rhs():
    res = {}
    for mm in re.finditer(
            r"assign io_to([A-Za-z]+)Exu_(\d+)_(\d+)_bits_src_(\d+) =\s*([^;]+);", GSV, re.S):
        dom, i, j, k, rhs = mm.groups()
        res[(dom, int(i), int(j), int(k))] = re.sub(r"\s+", " ", rhs).strip()
    return res


def imm_field_map():
    """io_og1ImmInfo_<idx>_<field> = s1_immInfo_<g>_<s>_<field>。
    返回 og1ImmInfo 输出索引 -> (g,s) 及字段集(imm/immType)。"""
    pass


def toexu_ctrl_map():
    """io_to<dom>Exu_i_j_bits_<field> = s1_toExuData_<g>_<s>_<field>。
    返回 {(dom,i,j): [(field, g, s), ...]}(toExu 端口 <- s1_ctrl 寄存器)。"""
    res = {}
    for mm in re.finditer(
            r"io_to([A-Za-z]+)Exu_(\d+)_(\d+)_bits_([a-zA-Z0-9_]+) = "
            r"s1_toExuData_(\d+)_(\d+)_([a-zA-Z0-9_]+);", GSV):
        dom, i, j, f1, g, s, f2 = mm.groups()
        if f1 != f2:
            continue
        res.setdefault((dom, int(i), int(j)), []).append((f1, int(g), int(s)))
    return res


def arbiter_cfg(prefix):
    inst_re = re.compile(rf"^  {prefix}RFReadArbiter \w+ \(", re.M)
    m = inst_re.search(GSV)
    if not m:
        return []
    start = GSV[:m.start()].count("\n")
    cfg = []
    for ln in LINES[start:]:
        if re.match(r"^  \);", ln):
            break
        am = re.match(r"\s*\.io_in_(\d+)_(\d+)_(\d+)_bits_addr\s*\((.*?)\)", ln)
        if am:
            g, sub, src = int(am.group(1)), int(am.group(2)), int(am.group(3))
            rhs = am.group(4).strip()
            fm = re.match(
                r"io_from(\w+)IQ_(\d+)_(\d+)_bits_rf_(\d+)_0_addr(\[\d+:\d+\])?", rhs)
            if fm:
                cfg.append({"g": g, "sub": sub, "src": src, "iqdom": fm.group(1),
                            "iqi": int(fm.group(2)), "iqj": int(fm.group(3)),
                            "rfgrp": int(fm.group(4)), "slice": fm.group(5) or ""})
            else:
                cfg.append({"g": g, "sub": sub, "src": src, "iqdom": None})
    return cfg


def wb_collide_cfg(prefix):
    """<prefix>WbBusyArbiter 的 io_in valid = intRFWriteReq_<g>_<s>(= IQ.valid & wen)。
    返回该域参与写口冲突检查的 (g) 列表及其 IQ/wen 字段。"""
    pre = {"Int": "intWbBusyArbiter", "Fp": "fpWbBusyArbiter", "Vf": "vfWbBusyArbiter",
           "V0": "v0WbBusyArbiter", "Vl": "vlWbBusyArbiter"}[prefix]
    m = re.search(rf"^  {prefix}RFWBCollideChecker \w+ \(", GSV, re.M)
    if not m:
        return []
    start = GSV[:m.start()].count("\n")
    res = []
    for ln in LINES[start:]:
        if re.match(r"^  \);", ln):
            break
        am = re.match(r"\s*\.io_in_(\d+)_(\d+)_valid\s*\((.*?)\)", ln)
        if am:
            res.append({"g": int(am.group(1)), "sub": int(am.group(2)),
                        "rhs": am.group(3).strip()})
    return res


def writeport_count(prefix):
    n = set()
    for mm in re.finditer(rf"io_from{prefix}Wb_(\d+)_wen", GSV):
        n.add(int(mm.group(1)))
    return len(n)


def readport_count(prefix):
    pre = {"Int": "intRfRdata", "Fp": "fpRfRdata", "Vf": "vfRfRdata",
           "V0": "v0RfRdata", "Vl": "vlRfRdata"}[prefix]
    n = set()
    for mm in re.finditer(rf"\b{pre}_(\d+)\b", GSV):
        n.add(int(mm.group(1)))
    return len(n)


def og_ports():
    res = {}
    for mm in re.finditer(
            r"(?:output|input)\s+(?:\[(\d+):0\])?\s*io_to(\w+)IQ_(\d+)_(\d+)_(og0resp|og1resp)_(\w+),?",
            GSV):
        w, dom, i, j, og, field = mm.groups()
        res.setdefault((dom, int(i), int(j)), []).append(
            (og, field, int(w) + 1 if w else 1))
    return res


def og1_resp_type():
    res = {}
    for mm in re.finditer(
            r"assign io_to(\w+)IQ_(\d+)_(\d+)_og1resp_bits_resp =\s*([^;]+);", GSV, re.S):
        dom, i, j, expr = mm.groups()
        res[(dom, int(i), int(j))] = "success" if "2'h3" in expr else "uncertain"
    return res


def imm_map():
    """io_og1ImmInfo_<idx>_imm = s1_immInfo_<g>_<s>_imm。返回 {(g,s): idx}。"""
    res = {}
    for mm in re.finditer(
            r"io_og1ImmInfo_(\d+)_imm = s1_immInfo_(\d+)_(\d+)_imm;", GSV):
        res[(int(mm.group(2)), int(mm.group(3)))] = int(mm.group(1))
    return res


def imm_src():
    """s1_immInfo_<g>_<s>_imm <= valid ? io_from..._imm[31:0] : hold。返回 (g,s)->(iqdom,i,j)。"""
    res = {}
    for mm in re.finditer(
            r"s1_immInfo_(\d+)_(\d+)_imm <=\s*io_from(\w+)IQ_(\d+)_(\d+)_valid", GSV):
        res[(int(mm.group(1)), int(mm.group(2)))] = (
            mm.group(3), int(mm.group(4)), int(mm.group(5)))
    return res


def pc_target_map():
    res = {}
    for mm in re.finditer(
            r"io_to(\w+)Exu_(\d+)_(\d+)_bits_pc = io_fromPcTargetMem_toDataPathPC_(\d+);", GSV):
        res[(mm.group(1), int(mm.group(2)), int(mm.group(3)))] = {"pc": int(mm.group(4))}
    for mm in re.finditer(
            r"io_to(\w+)Exu_(\d+)_(\d+)_bits_predictInfo_target =\s*io_fromPcTargetMem_toDataPathTargetPC_(\d+);", GSV):
        key = (mm.group(1), int(mm.group(2)), int(mm.group(3)))
        res.setdefault(key, {})["target"] = int(mm.group(4))
    return res


def pcread_inputs():
    """io_fromPcTargetMem_fromDataPathValid_<idx> = io_from<dom>IQ_<i>_<j>_valid。"""
    res = {}
    for mm in re.finditer(
            r"io_fromPcTargetMem_fromDataPath(Valid|FtqPtr_flag|FtqPtr_value|FtqOffset)_(\d+) =\s*io_from(\w+)IQ_(\d+)_(\d+)_bits?_?([a-zA-Z0-9_]*)", GSV):
        pass
    # 简化:只取 valid 来确定 pcRead 槽 -> IQ
    res = {}
    for mm in re.finditer(
            r"io_fromPcTargetMem_fromDataPathValid_(\d+) = io_from(\w+)IQ_(\d+)_(\d+)_valid;", GSV):
        res[int(mm.group(1))] = (mm.group(2), int(mm.group(3)), int(mm.group(4)))
    return res


def cancel_delay_map():
    """og0_cancel_delay_<idx> 存在的 EXU(isIQWakeUpSink+0lat)及其 fuType 掩码位。
    返回存在 cancel 寄存器的 og0_cancel_delay 索引集(数量)。"""
    idxs = set()
    for mm in re.finditer(r"og0_cancel_delay_(\d+) <=", GSV):
        idxs.add(int(mm.group(1)))
    return sorted(idxs)


def vlpreg_map():
    """s1_vlPregRData_<g>_<s>_<k> = {120'h0, vlRegFile_readPorts_<p>_data}。返回名->vl 读口 p。"""
    res = {}
    for mm in re.finditer(
            r"s1_vlPregRData_(\d+)_(\d+)_(\d+) = \{120'h0, _vlRegFile_io_readPorts_(\d+)_data\}",
            GSV):
        res[f"{mm.group(1)}_{mm.group(2)}_{mm.group(3)}"] = int(mm.group(4))
    return res


def regcache_cfg():
    res = []
    m = re.search(r"^  RegCache regCache \(", GSV, re.M)
    start = GSV[:m.start()].count("\n")
    for ln in LINES[start:]:
        if re.match(r"^  \);", ln):
            break
        am = re.match(
            r"\s*\.io_readPorts_(\d+)_addr\s*\(io_from(\w+)IQ_(\d+)_(\d+)_bits_rcIdx_(\d+)\)", ln)
        if am:
            res.append({"port": int(am.group(1)), "iqdom": am.group(2),
                        "iqi": int(am.group(3)), "iqj": int(am.group(4)),
                        "src": int(am.group(5))})
    res.sort(key=lambda x: x["port"])
    return res


def main():
    gmap = exu_global_map()
    nsrc = num_reg_src()
    rhs = src_rhs()
    tcm = toexu_ctrl_map()
    pw = port_widths()
    immm = imm_map()
    imms = imm_src()
    ptm = pc_target_map()
    exus = []
    for (g, s), (dom, i, j) in sorted(gmap.items()):
        iqdom = PORTDOM2IQ[dom]
        e = {"g": g, "sub": s, "port_dom": dom, "iqdom": iqdom, "iqi": i, "iqj": j,
             "numRegSrc": nsrc.get((dom, i, j), 0), "src_rhs": {}}
        for k in range(e["numRegSrc"]):
            e["src_rhs"][k] = rhs.get((dom, i, j, k))
        # ctrl 流水字段集 = toExu 端口所用 s1_toExuData 字段(权威);皆从 fromIQ.common
        # 寄存(RegEnable on s0.valid),loadDependency_X 特例为 {ld[0],1'b0}(依赖窗老化)。
        e["toexu_ctrl"] = tcm.get((dom, i, j), [])  # [(field,g,s)]
        e["ctrl_fields"] = [f for (f, gg, ss) in e["toexu_ctrl"]]
        e["imm_idx"] = immm.get((g, s))             # og1ImmInfo 输出序号 or None
        e["pc"] = ptm.get((dom, i, j), {})
        # 该 EXU 的 IQ 是否带 loadDependency(Int/Mem 类),决定 s1_valid 是否含 ldCancel 项。
        e["has_loaddep"] = bool(re.search(
            rf"io_from{iqdom}IQ_{i}_{j}_bits_common_loadDependency_0\b", GSV))
        exus.append(e)
    out = {
        "exus": exus,
        "arbiters": {d: arbiter_cfg(d) for d in DOMAINS},
        "wbcollide": {d: wb_collide_cfg(d) for d in DOMAINS},
        "wports": {d: writeport_count(d) for d in DOMAINS},
        "rports": {d: readport_count(d) for d in DOMAINS},
        "og_ports": {f"{d}|{i}|{j}": v for (d, i, j), v in og_ports().items()},
        "og1_type": {f"{d}|{i}|{j}": v for (d, i, j), v in og1_resp_type().items()},
        "imm_src": {f"{g}|{s}": v for (g, s), v in imms.items()},
        "pcread": {str(k): v for k, v in pcread_inputs().items()},
        "og0_delay": [
            (int(mm.group(1)), int(mm.group(2)), int(mm.group(3)),
             mm.group(4), int(mm.group(5)), int(mm.group(6)))
            for mm in re.finditer(
                r"og0_cancel_delay_(\d+) <=\s*og0FailedVec2_(\d+)_(\d+)\s*&\s*\("
                r"io_from(\w+)IQ_(\d+)_(\d+)_bits_common_fuType", GSV)],
        "cancel_enc": [
            ((mm.group(1) or ""), mm.group(2), int(mm.group(3)), int(mm.group(4)),
             int(mm.group(5)))
            for mm in re.finditer(
                r"_exuOHNoLoad_encodedExuOH_T(_\d+)? =\s*8'h1 << "
                r"io_from(\w+)IQ_(\d+)_(\d+)_bits_common_exuSources_(\d+)_value", GSV)],
        "og0cancel": {int(mm.group(1)): (int(mm.group(2)), int(mm.group(3)))
                      for mm in re.finditer(
                          r"io_og0Cancel_(\d+) = og0FailedVec2_(\d+)_(\d+)", GSV)},
        "regcache": regcache_cfg(),
        "vlpreg": vlpreg_map(),
        "port_widths": pw,
        "ncancel": len(cancel_delay_map()),
    }
    print(json.dumps(out))


if __name__ == "__main__":
    main()
