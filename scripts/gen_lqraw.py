#!/usr/bin/env python3
"""gen_lqraw.py —— LoadQueueRAW 簇（LoadQueueRAW / LqMaskModule / LqPAddrModule_1）的机械派生区生成器。

生成对象（都是"没有微架构"的纯机械部分）：
  rtl/memblock/LqMaskModule.sv      整个文件（薄 wrapper：golden 端口表 + 例化共用核
  rtl/memblock/LqPAddrModule_1.sv   xs_LqRawDataCam_core + 输出展平）
  rtl/memblock/LoadQueueRAW.sv      两个 GENERATED 区（手写区一个字节都不动）：
    lqraw-cam-inst  核里两块 CAM 阵列的例化（golden 扁平端口 × 数组下标，逐位接线）
    lqraw-wrapper   golden 同名 wrapper：端口表逐字取 golden，按映射表拆/装结构体

端口表逐字取自 G1 golden 同名模块（顺序/名字/位宽全同），生成时三项机械核对：
  (1) golden 端口集合 == 预期形状（wen/waddr/wdata ×3、violationMdata ×2、
      [violationCheckLine ×2]、violationMmask 2×32，外加 clock/reset），多一个少一个都报错；
  (2) 位宽与核参数一致（DATA_W / ADDR_W）；
  (3) 生成结果与磁盘逐字节比较（--check）。

用法:
  scripts/gen_lqraw.py            # 写文件
  scripts/gen_lqraw.py --check    # 只比对，不写；有漂移 rc=1（gate 用）
"""
import argparse
import os
import re
import sys

GOLDEN_DIR = "/home/eda/xs-env/G1-canonical/golden-rtl"
HERE = os.path.dirname(os.path.abspath(__file__))
RTL = os.path.normpath(os.path.join(HERE, "..", "rtl", "memblock"))

NUM_WRITE = 3
NUM_CAM = 2
NUM_ENTRIES = 32
ADDR_W = 5


def port_table(module):
    """golden 顶层端口表：[(dir, width, name, 原文行)]，顺序即 golden 顺序。"""
    path = os.path.join(GOLDEN_DIR, module + ".sv")
    lines = open(path).read().split("\n")
    start = next(i for i, l in enumerate(lines) if l.startswith("module %s(" % module))
    end = start
    while not lines[end].startswith(");"):
        end += 1
    out = []
    pat = re.compile(r"\s*(input|output)\s+(?:\[(\d+):(\d+)\]\s*)?([A-Za-z_]\w*)\s*,?\s*$")
    for l in lines[start + 1:end]:
        m = pat.match(l)
        if not m:
            raise SystemExit("gen_lqraw: 端口行解析失败: %r" % l)
        w = int(m.group(2)) - int(m.group(3)) + 1 if m.group(2) else 1
        out.append((m.group(1), w, m.group(4), l.rstrip(",").rstrip()))
    return out


def expected_ports(data_w, line_cam):
    exp = [("input", 1, "clock"), ("input", 1, "reset")]
    exp += [("input", 1, "io_wen_%d" % w) for w in range(NUM_WRITE)]
    exp += [("input", ADDR_W, "io_waddr_%d" % w) for w in range(NUM_WRITE)]
    exp += [("input", data_w, "io_wdata_%d" % w) for w in range(NUM_WRITE)]
    exp += [("input", data_w, "io_violationMdata_%d" % c) for c in range(NUM_CAM)]
    if line_cam:
        exp += [("input", 1, "io_violationCheckLine_%d" % c) for c in range(NUM_CAM)]
    exp += [("output", 1, "io_violationMmask_%d_%d" % (c, j))
            for c in range(NUM_CAM) for j in range(NUM_ENTRIES)]
    return exp


CAM_FAMILY = [
    # (模块, DATA_W, LINE_CAM, 一句话, 写数据延迟件)
    ("LqMaskModule", 16, False,
     "LoadQueueRAW 的字节掩码 CAM 阵列（32 项 × 16 位）", "DelayNWithValid_103"),
    ("LqPAddrModule_1", 24, True,
     "LoadQueueRAW 的部分物理地址 CAM 阵列（32 项 × 24 位 = paddr[27:4]）",
     "DelayNWithValid_55"),
]


def gen_cam_wrapper(module, data_w, line_cam, brief, wdelay):
    ports = port_table(module)
    got = [(d, w, n) for d, w, n, _ in ports]
    exp = expected_ports(data_w, line_cam)
    if got != exp:
        gs, es = set(got), set(exp)
        raise SystemExit("gen_lqraw: %s golden 端口表与预期形状不符\n  多: %s\n  少: %s\n  (或顺序不同)"
                         % (module, sorted(gs - es)[:8], sorted(es - gs)[:8]))

    o = []
    o.append("// " + "=" * 77)
    o.append("// %s —— %s" % (module, brief))
    o.append("//")
    o.append("// 薄 wrapper：逻辑全部在共用核 xs_LqRawDataCam_core（同目录 xs_LqRawDataCam_core.sv）。")
    o.append("// 本变体：DATA_W=%d，LINE_CAM=%d（%s），写数据延迟件 = %s。"
             % (data_w, int(line_cam),
                "地址 CAM，带 cacheline 整行检查" if line_cam else "字节掩码交叠 CAM",
                wdelay))
    o.append("// 本层只做端口展平/改名：golden 的扁平 io_* 名 <-> 核的按口号成组的数组端口。")
    o.append("// reset 在综合视图里没有负载：golden 只在 `ifndef SYNTHESIS 的写冲突断言里用它")
    o.append("// （assert(!(wen(i) && wen(j) && waddr(i)===waddr(j)))），所有寄存器都不复位。")
    o.append("// 端口表逐字抄自 G1 golden 同名模块。自动生成：scripts/gen_lqraw.py —— 勿手改")
    o.append("// " + "=" * 77)
    o.append("")
    o.append("module %s(" % module)
    for i, (_, _, _, raw) in enumerate(ports):
        o.append(raw + ("," if i + 1 < len(ports) else ""))
    o.append(");")
    o.append("  logic [%d:0] waddr [%d];" % (ADDR_W - 1, NUM_WRITE))
    o.append("  logic [%d:0] wdata [%d];" % (data_w - 1, NUM_WRITE))
    o.append("  logic [%d:0] mdata [%d];" % (data_w - 1, NUM_CAM))
    o.append("  logic [%d:0] mmask [%d];" % (NUM_ENTRIES - 1, NUM_CAM))
    o.append("")
    for w in range(NUM_WRITE):
        o.append("  assign waddr[%d] = io_waddr_%d;" % (w, w))
    for w in range(NUM_WRITE):
        o.append("  assign wdata[%d] = io_wdata_%d;" % (w, w))
    for c in range(NUM_CAM):
        o.append("  assign mdata[%d] = io_violationMdata_%d;" % (c, c))
    o.append("")
    o.append("  xs_LqRawDataCam_core #(")
    o.append("    .NUM_ENTRIES (%d)," % NUM_ENTRIES)
    o.append("    .DATA_W      (%d)," % data_w)
    o.append("    .NUM_WRITE   (%d)," % NUM_WRITE)
    o.append("    .NUM_WBANK   (8),")
    o.append("    .NUM_CAM     (%d)," % NUM_CAM)
    o.append("    .LINE_CAM    (1'b%d)" % int(line_cam))
    o.append("  ) u_core (")
    o.append("    .clock                 (clock),")
    o.append("    .io_wen                ({%s})," % ", ".join("io_wen_%d" % w for w in reversed(range(NUM_WRITE))))
    o.append("    .io_waddr              (waddr),")
    o.append("    .io_wdata              (wdata),")
    o.append("    .io_violationMdata     (mdata),")
    if line_cam:
        o.append("    .io_violationCheckLine ({%s}),"
                 % ", ".join("io_violationCheckLine_%d" % c for c in reversed(range(NUM_CAM))))
    else:
        o.append("    .io_violationCheckLine (%d'b0),  // 掩码 CAM 不看整行标志" % NUM_CAM)
    o.append("    .io_violationMmask     (mmask)")
    o.append("  );")
    o.append("")
    for c in range(NUM_CAM):
        for j in range(NUM_ENTRIES):
            o.append("  assign io_violationMmask_%d_%d = mmask[%d][%d];" % (c, j, c, j))
    o.append("endmodule")
    return "\n".join(o) + "\n"


# ---------------------------------------------------------------------------
#  LoadQueueRAW
# ---------------------------------------------------------------------------
LQRAW = os.path.join(RTL, "LoadQueueRAW.sv")
LD_W = 3
ST_W = 2

# golden 端口名（下标位置换成 N）-> 核侧表达式模板（{n} = 下标）。
# 每个 golden 端口必须恰好命中一条规则；每条规则至少命中一个端口（防规则写错了没人用）。
LQRAW_PORT_MAP = [
    ("io_redirect_valid",                              "redirect.valid"),
    ("io_redirect_bits_robIdx_flag",                   "redirect.robIdx.flag"),
    ("io_redirect_bits_robIdx_value",                  "redirect.robIdx.value"),
    ("io_redirect_bits_level",                         "redirect.level"),
    ("io_query_N_req_ready",                           "query_ready[{n}]"),
    ("io_query_N_req_valid",                           "query_req[{n}].valid"),
    ("io_query_N_req_bits_uop_preDecodeInfo_isRVC",    "query_req[{n}].uop.isRVC"),
    ("io_query_N_req_bits_uop_ftqPtr_flag",            "query_req[{n}].uop.ftqPtr.flag"),
    ("io_query_N_req_bits_uop_ftqPtr_value",           "query_req[{n}].uop.ftqPtr.value"),
    ("io_query_N_req_bits_uop_ftqOffset",              "query_req[{n}].uop.ftqOffset"),
    ("io_query_N_req_bits_uop_robIdx_flag",            "query_req[{n}].uop.robIdx.flag"),
    ("io_query_N_req_bits_uop_robIdx_value",           "query_req[{n}].uop.robIdx.value"),
    ("io_query_N_req_bits_uop_debugInfo_runahead_checkpoint_id",
                                                       "query_req[{n}].uop.runaheadId"),
    ("io_query_N_req_bits_uop_sqIdx_flag",             "query_req[{n}].sqIdx.flag"),
    ("io_query_N_req_bits_uop_sqIdx_value",            "query_req[{n}].sqIdx.value"),
    ("io_query_N_req_bits_mask",                       "query_req[{n}].mask"),
    ("io_query_N_req_bits_paddr",                      "query_req[{n}].paddr"),
    ("io_query_N_req_bits_data_valid",                 "query_req[{n}].data_valid"),
    ("io_query_N_revoke",                              "query_revoke[{n}]"),
    ("io_storeIn_N_valid",                             "storeIn[{n}].valid"),
    ("io_storeIn_N_bits_uop_ftqPtr_flag",              "storeIn[{n}].ftqPtr.flag"),
    ("io_storeIn_N_bits_uop_ftqPtr_value",             "storeIn[{n}].ftqPtr.value"),
    ("io_storeIn_N_bits_uop_ftqOffset",                "storeIn[{n}].ftqOffset"),
    ("io_storeIn_N_bits_uop_robIdx_flag",              "storeIn[{n}].robIdx.flag"),
    ("io_storeIn_N_bits_uop_robIdx_value",             "storeIn[{n}].robIdx.value"),
    ("io_storeIn_N_bits_paddr",                        "storeIn[{n}].paddr"),
    ("io_storeIn_N_bits_mask",                         "storeIn[{n}].mask"),
    ("io_storeIn_N_bits_wlineflag",                    "storeIn[{n}].wlineflag"),
    ("io_storeIn_N_bits_miss",                         "storeIn[{n}].miss"),
    ("io_rollback_N_valid",                            "rollback[{n}].valid"),
    ("io_rollback_N_bits_isRVC",                       "rollback[{n}].isRVC"),
    ("io_rollback_N_bits_robIdx_flag",                 "rollback[{n}].robIdx.flag"),
    ("io_rollback_N_bits_robIdx_value",                "rollback[{n}].robIdx.value"),
    ("io_rollback_N_bits_ftqIdx_flag",                 "rollback[{n}].ftqIdx.flag"),
    ("io_rollback_N_bits_ftqIdx_value",                "rollback[{n}].ftqIdx.value"),
    ("io_rollback_N_bits_ftqOffset",                   "rollback[{n}].ftqOffset"),
    ("io_rollback_N_bits_stFtqIdx_flag",               "rollback[{n}].stFtqIdx.flag"),
    ("io_rollback_N_bits_stFtqIdx_value",              "rollback[{n}].stFtqIdx.value"),
    ("io_rollback_N_bits_stFtqOffset",                 "rollback[{n}].stFtqOffset"),
    ("io_rollback_N_bits_debug_runahead_checkpoint_id","rollback[{n}].runaheadId"),
    ("io_stAddrReadySqPtr_flag",                       "stAddrReadySqPtr.flag"),
    ("io_stAddrReadySqPtr_value",                      "stAddrReadySqPtr.value"),
    ("io_stIssuePtr_flag",                             "stIssuePtr.flag"),
    ("io_stIssuePtr_value",                            "stIssuePtr.value"),
]
# 这三个端口直接接到核的同名端口，不经结构体
LQRAW_DIRECT = {"clock", "reset", "io_lqFull", "io_perf_0_value", "io_perf_1_value"}


def lqraw_map_ports(ports):
    """[(dir, 端口名, 核侧表达式)]；逐条 fail-closed 核对。"""
    rules = [(re.compile("^" + pat.replace("_N_", r"_(\d+)_") + "$"), tmpl, pat)
             for pat, tmpl in LQRAW_PORT_MAP]
    used = set()
    out = []
    for d, _, name, _ in ports:
        if name in LQRAW_DIRECT:
            out.append((d, name, None))
            continue
        hits = [(r, t, p) for r, t, p in rules if r.match(name)]
        if len(hits) != 1:
            raise SystemExit("gen_lqraw: LoadQueueRAW 端口 %s 命中 %d 条规则（必须恰好 1 条）"
                             % (name, len(hits)))
        r, t, p = hits[0]
        m = r.match(name)
        n = m.group(1) if m.groups() else None
        used.add(p)
        out.append((d, name, t.format(n=n)))
    unused = [p for p, _ in LQRAW_PORT_MAP if p not in used]
    if unused:
        raise SystemExit("gen_lqraw: 映射规则没有命中任何 golden 端口（写错了？）: %s" % unused)
    return out


def gen_lqraw_wrapper():
    ports = port_table("LoadQueueRAW")
    mapped = lqraw_map_ports(ports)
    o = []
    o.append("module LoadQueueRAW")
    o.append("  import loadqueueraw_pkg::*;")
    o.append("(")
    for i, (_, _, _, raw) in enumerate(ports):
        o.append(raw + ("," if i + 1 < len(ports) else ""))
    o.append(");")
    o.append("  // golden 的端口是 firtool 完全展平的标量；这里按语义重新装成结构体交给可读核。")
    o.append("  redirect_t              redirect;")
    o.append("  query_req_t [LD_W-1:0]  query_req;")
    o.append("  logic       [LD_W-1:0]  query_ready;")
    o.append("  logic       [LD_W-1:0]  query_revoke;")
    o.append("  store_in_t  [ST_W-1:0]  storeIn;")
    o.append("  rollback_t  [ST_W-1:0]  rollback;")
    o.append("  sq_ptr_t                stAddrReadySqPtr;")
    o.append("  sq_ptr_t                stIssuePtr;")
    o.append("")
    for d, name, expr in mapped:
        if expr is None:
            continue
        if d == "input":
            o.append("  assign %s = %s;" % (expr, name))
        else:
            o.append("  assign %s = %s;" % (name, expr))
    o.append("")
    o.append("  xs_LoadQueueRAW_core u_core (")
    conns = [("clock", "clock"), ("reset", "reset"),
             ("io_redirect", "redirect"),
             ("io_query_req", "query_req"),
             ("io_query_req_ready", "query_ready"),
             ("io_query_revoke", "query_revoke"),
             ("io_storeIn", "storeIn"),
             ("io_rollback", "rollback"),
             ("io_stAddrReadySqPtr", "stAddrReadySqPtr"),
             ("io_stIssuePtr", "stIssuePtr"),
             ("io_lqFull", "io_lqFull"),
             ("io_perf_0_value", "io_perf_0_value"),
             ("io_perf_1_value", "io_perf_1_value")]
    for i, (f, a) in enumerate(conns):
        o.append("    .%-20s (%s)%s" % (f, a, "," if i + 1 < len(conns) else ""))
    o.append("  );")
    o.append("endmodule")
    return "\n".join(o)


def gen_lqraw_cam_inst():
    """核内两块 CAM 阵列的例化：端口名逐个取 golden 子模块端口表。"""
    o = []
    for module, inst, wdata, mdata, line in (
            ("LqPAddrModule_1", "paddrModule", "cam_wPaddr[{w}]", "cam_qPaddr[{c}]", "st_checkLine_q[{c}]"),
            ("LqMaskModule", "maskModule", "io_query_req[{w}].mask", "st_mask_q[{c}]", None)):
        ports = port_table(module)
        mm = "paddrMatch" if inst == "paddrModule" else "maskMatch"
        conns = []
        for d, _, name, _ in ports:
            m = re.match(r"^io_(wen|waddr|wdata|violationMdata|violationCheckLine)_(\d+)$", name)
            mo = re.match(r"^io_violationMmask_(\d+)_(\d+)$", name)
            if name in ("clock", "reset"):
                conns.append((name, name))
            elif m:
                k, i = m.group(1), m.group(2)
                expr = {"wen": "acceptedVec[{w}]", "waddr": "enqIndexVec[{w}]", "wdata": wdata,
                        "violationMdata": mdata, "violationCheckLine": line}[k]
                if expr is None:
                    raise SystemExit("gen_lqraw: %s 不该有端口 %s" % (module, name))
                conns.append((name, expr.format(w=i, c=i)))
            elif mo:
                conns.append((name, "%s[%s][%s]" % (mm, mo.group(1), mo.group(2))))
            else:
                raise SystemExit("gen_lqraw: %s 端口 %s 无接线规则" % (module, name))
        o.append("  %s %s (" % (module, inst))
        for i, (n, e) in enumerate(conns):
            o.append("    .%-23s (%s)%s" % (n, e, "," if i + 1 < len(conns) else ""))
        o.append("  );")
    return "\n".join(o)


def replace_region(text, tag, body):
    begin = "// BEGIN GENERATED(%s)" % tag
    end = "// END GENERATED"
    i = text.index(begin)
    j = text.index(end, i)
    # 保留 marker 行自身的缩进
    line_start = text.rfind("\n", 0, i) + 1
    indent = text[line_start:i]
    return text[:i] + begin + "\n" + body + "\n" + indent + end + text[j + len(end):]


def gen_lqraw_file():
    text = open(LQRAW).read()
    text = replace_region(text, "lqraw-cam-inst", gen_lqraw_cam_inst())
    text = replace_region(text, "lqraw-wrapper", gen_lqraw_wrapper())
    return text


# ---------------------------------------------------------------------------
#  LoadQueueRAW 的 FM「匹配前」钉点（verif/ut/LoadQueueRAW/fm_pins_pre.tcl）
# ---------------------------------------------------------------------------
# golden 顶层的 552 个寄存器是 firtool 的扁平名（uop_17_robIdx_value、
# detectedRollback_lqSelect_select_2_2_1_uop_ftqOffset …），重写核是按字段的数组
# （u_core/uop_robIdx_value[17]、u_core/grpUop_ftqOffset_q[1][2] …）。两套名字 FM 自动
# 配对配不上，只能走签名分析 —— 首次试跑在 Matching 阶段卡了 45 分钟没出来。
# 钉点只消名差：告诉 FM"这两个点是同一个点"，比较照比，不约束 ref、不放宽任何判据。
# 映射由下表机械给出，每个 golden 寄存器必须恰好命中一条规则（fail-closed）。
PIN_FIELDS = {
    "preDecodeInfo_isRVC": "isRVC", "ftqPtr_flag": "ftqPtr_flag", "ftqPtr_value": "ftqPtr_value",
    "ftqOffset": "ftqOffset", "robIdx_flag": "robIdx_flag", "robIdx_value": "robIdx_value",
    "debugInfo_runahead_checkpoint_id": "runaheadId",
}
PIN_REDIRECT = {"valid": "valid", "bits_robIdx_flag": "robIdx_flag",
                "bits_robIdx_value": "robIdx_value", "bits_level": "level"}
DR = "detectedRollback_"


def lqraw_pin_target(name):
    """golden 顶层寄存器名 -> 重写核里的寄存器元素（不含 _reg 后缀的数组表达式）。"""
    F = "|".join(PIN_FIELDS)
    R = "|".join(PIN_REDIRECT)
    rules = [
        (r"allocated_(\d+)", lambda m: "allocated[%s]" % m[1]),
        (r"datavalid_(\d+)", lambda m: "datavalid[%s]" % m[1]),
        (r"uop_(\d+)_(%s|sqIdx_flag|sqIdx_value)" % F,
         lambda m: "uop_%s[%s]" % (PIN_FIELDS.get(m[2], m[2]), m[1])),
        (r"lastCanAccept_r_(\d)", lambda m: "lastCanAccept[%s]" % m[1]),
        (r"lastAllocIndex_next_nextVec_(\d)_r", lambda m: "lastAllocIndex[%s]" % m[1]),
        (DR + r"paddrModule_io_violationMdata_(\d)_r", lambda m: "st_paddr_q[%s]" % m[1]),
        (DR + r"paddrModule_io_violationCheckLine_(\d)_r", lambda m: "st_checkLine_q[%s]" % m[1]),
        (DR + r"maskModule_io_violationMdata_(\d)_r", lambda m: "st_mask_q[%s]" % m[1]),
        (DR + r"entryNeedCheck_r_(\d+)", lambda m: "entryNeedCheck[0][%s]" % m[1]),
        (DR + r"entryNeedCheck_r_1_(\d+)", lambda m: "entryNeedCheck[1][%s]" % m[1]),
        # 第一级组：selValidNext / REG 按 k = 4*store + group 连续编号（k=0 无后缀）
        (DR + r"lqSelect_select_selValidNext(?:_(\d))?",
         lambda m: "grpValid_q[%d][%d]" % divmod(int(m[1] or 0), 4)),
        (DR + r"lqSelect_select_REG(?:_(\d))?_(%s)" % R,
         lambda m: "grpRedirect_%s_q[%d][%d]" % ((PIN_REDIRECT[m[2]],) + divmod(int(m[1] or 0), 4))),
        # 第一级组 bits：select_<g>_2_uop_*（store 0）/ select_<g>_2_1_uop_*（store 1）
        (DR + r"lqSelect_select_(\d)_2_uop_(%s)" % F,
         lambda m: "grpUop_%s_q[0][%s]" % (PIN_FIELDS[m[2]], m[1])),
        (DR + r"lqSelect_select_(\d)_2_1_uop_(%s)" % F,
         lambda m: "grpUop_%s_q[1][%s]" % (PIN_FIELDS[m[2]], m[1])),
        # 第二级
        (DR + r"lqSelect_selValidNext_last_REG(?:_(1))?",
         lambda m: "lastValid_q[%d]" % int(m[1] or 0)),
        (DR + r"lqSelect_REG(?:_(1))?_(%s)" % R,
         lambda m: "lastRedirect_%s_q[%d]" % (PIN_REDIRECT[m[2]], int(m[1] or 0))),
        (DR + r"lqSelect_2_0(?:_(1))?_uop_(%s)" % F,
         lambda m: "lastUop_%s_q[%d]" % (PIN_FIELDS[m[2]], int(m[1] or 0))),
        (r"io_perf_0_value_REG(?:_(1))?", lambda m: "perfEnq_q[%d]" % int(m[1] or 0)),
        (r"io_perf_1_value_REG(?:_(1))?", lambda m: "perfRollback_q[%d]" % int(m[1] or 0)),
    ]
    hits = []
    for pat, fn in rules:
        m = re.fullmatch(pat, name)
        if m:
            hits.append(fn(m))
    if len(hits) != 1:
        raise SystemExit("gen_lqraw: 钉点规则对 golden 寄存器 %s 命中 %d 条（必须恰好 1）" % (name, len(hits)))
    return hits[0]


def golden_top_regs(module):
    t = open(os.path.join(GOLDEN_DIR, module + ".sv")).read()
    body = t[t.index("module %s(" % module):]
    body = body[:body.index("\nendmodule")]
    body = re.sub(r"reg\s+(\[\d+:\d+\])\s*\n\s*", r"reg \1 ", body)  # 折行的声明
    out = []
    for a, b, n in re.findall(r"^\s*reg\s+(?:\[(\d+):(\d+)\]\s+)?(\w+);", body, re.M):
        out.append((n, int(a) - int(b) + 1 if a else 1))
    return out


def gen_lqraw_pins():
    regs = golden_top_regs("LoadQueueRAW")
    total = sum(w for _, w in regs)
    seen = set()
    o = []
    o.append("# LoadQueueRAW FM「匹配前」钉点 —— 自动生成：scripts/gen_lqraw.py（勿手改）")
    o.append("#")
    o.append("# 只消 golden 扁平寄存器名与重写核按字段数组名之间的命名鸿沟（依据见生成器注释）。")
    o.append("# set_user_match 只是声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。")
    o.append("# fail-closed：set_user_match 从不抛异常（返回 0 = 没配上），所以逐条数返回值；")
    o.append("# 拒一条或总数不等于字面整数（= golden 顶层寄存器位数）就 error（safe interp 里不用 exit）。")
    o.append("# 子模块（paddrModule / maskModule / freeList / 延迟件）内部不钉，交给 FM 自动配对。")
    o.append("# 进 fm.log 的输出一律 ASCII。")
    o.append("set ::LQRAW_PIN_EXPECT %d" % total)
    o.append("set ::LQRAW_PIN_OK 0")
    o.append("set ::LQRAW_PIN_BAD 0")
    o.append("proc lqraw_pin {g i w} {")
    o.append("  if {$w == 1} {")
    o.append("    set pairs [list \"r:/WORK/LoadQueueRAW/${g}_reg\" \"i:/WORK/LoadQueueRAW/u_core/${i}\"]")
    o.append("  } else {")
    o.append("    set pairs {}")
    o.append("    for {set b 0} {$b < $w} {incr b} {")
    o.append("      lappend pairs \"r:/WORK/LoadQueueRAW/${g}_reg\\[$b\\]\" \"i:/WORK/LoadQueueRAW/u_core/${i}\\[$b\\]\"")
    o.append("    }")
    o.append("  }")
    o.append("  foreach {r m} $pairs {")
    o.append("    if {[set_user_match $r $m]} { incr ::LQRAW_PIN_OK } else {")
    o.append("      incr ::LQRAW_PIN_BAD")
    o.append("      if {$::LQRAW_PIN_BAD <= 10} { puts \"LQRAW_PIN_FAIL: $r <-> $m\" }")
    o.append("    }")
    o.append("  }")
    o.append("}")
    o.append("puts \"LQRAW_PIN_BEGIN LoadQueueRAW expect=$::LQRAW_PIN_EXPECT\"")
    for n, w in regs:
        tgt = lqraw_pin_target(n)
        if tgt in seen:
            raise SystemExit("gen_lqraw: 两个 golden 寄存器映射到同一个重写寄存器 %s（不是双射）" % tgt)
        seen.add(tgt)
        arr, idx = tgt.split("[", 1)
        ipath = arr + "_reg\\[" + idx.replace("][", "\\]\\[")[:-1] + "\\]"
        o.append("lqraw_pin %s %s %d" % (n, ipath, w))
    o.append("puts \"LQRAW_PIN_END LoadQueueRAW ok=$::LQRAW_PIN_OK bad=$::LQRAW_PIN_BAD\"")
    o.append("if {$::LQRAW_PIN_BAD != 0} { error \"LQRAW_PIN_MISS=$::LQRAW_PIN_BAD\" }")
    o.append("if {$::LQRAW_PIN_OK != %d} { error \"LQRAW_PIN_COUNT=$::LQRAW_PIN_OK expect=%d\" }"
             % (total, total))
    return "\n".join(o) + "\n"


LQRAW_PINS = os.path.normpath(os.path.join(HERE, "..", "verif", "ut", "LoadQueueRAW", "fm_pins_pre.tcl"))


def targets():
    out = {}
    out[LQRAW] = gen_lqraw_file()
    out[LQRAW_PINS] = gen_lqraw_pins()
    for module, dw, lc, brief, wd in CAM_FAMILY:
        out[os.path.join(RTL, module + ".sv")] = gen_cam_wrapper(module, dw, lc, brief, wd)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="只比对不写，有漂移 rc=1")
    args = ap.parse_args()
    drift = 0
    for path, text in targets().items():
        cur = open(path).read() if os.path.exists(path) else None
        if cur == text:
            print("gen_lqraw: OK     %s" % os.path.relpath(path))
            continue
        if args.check:
            print("gen_lqraw: DRIFT  %s" % os.path.relpath(path))
            drift += 1
        else:
            with open(path, "w") as f:
                f.write(text)
            print("gen_lqraw: WROTE  %s" % os.path.relpath(path))
    return 1 if drift else 0


if __name__ == "__main__":
    sys.exit(main())
