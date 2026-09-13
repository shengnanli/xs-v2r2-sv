#!/usr/bin/env python3
"""gen.py —— G1 新形态 SRAMTemplate 变体（B7 核能力批）的薄文件与 UT 生成器。

产物：
  1) rtl/common/SRAMTemplate_{128,145,146,155,163,166,178,185}.sv
     变体薄文件：例化 xs_SRAMTemplate_core + 厂商 SRAM 宏，只设参数 + 端口装配。
  2) verif/ut/SRAMTemplateNewForm/tb.sv        八变体 golden vs _xs 双例化比对
  3) verif/ut/SRAMTemplateNewForm/Makefile     UT/FM 驱动

为什么不并进 scripts/gen_sram_wrappers.py：本轮有别的 lane 在改 scripts/，约定不
碰该目录；这八个变体的形态（掩码复制 / 分段 MBIST / 外置时钟门控 / 多周期宏 /
结构体数据口）在老生成器里被 fail-closed 判为 unsupported 直接 SKIP。合并回老生
成器是集成者的事。

所有参数与位域布局都**从 G1 golden 机械提取**（端口表 / RW0_wdata 拼接 /
io_r_resp_data 切片 / 宏名里的 1p<SET>x<W>m<SEG>），不手填。
"""
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
XSSV = HERE.parent.parent.parent
GOLDEN = Path("/home/eda/xs-env/G1-canonical/golden-rtl")

TARGETS = ["SRAMTemplate_128", "SRAMTemplate_145", "SRAMTemplate_146",
           "SRAMTemplate_155", "SRAMTemplate_163", "SRAMTemplate_166",
           "SRAMTemplate_178", "SRAMTemplate_185"]

# 每个变体一句人话（写进薄文件头，说清它在哪一层、存什么）
BLURB = {
    "SRAMTemplate_128": "PTW 页表缓存 L1 层的 tag/数据阵列（MMU L2TLB 内）",
    "SRAMTemplate_145": "L2 预取器 SPP 的 Pattern History Table",
    "SRAMTemplate_146": "L2 预取器的 Recent Request Table（近期请求过滤表）",
    "SRAMTemplate_155": "L2 Slice 的数据阵列（一个 bank 的 data storage）",
    "SRAMTemplate_163": "L2 Directory 的元数据阵列（coherence meta，每 way 一条）",
    "SRAMTemplate_166": "L2 Slice 的数据阵列（一个 bank 的 data storage）",
    "SRAMTemplate_178": "L2 Slice 的数据阵列（一个 bank 的 data storage）",
    "SRAMTemplate_185": "L2 Directory 的元数据阵列（coherence meta，每 way 一条）",
}

SV_KEYWORDS = {"alias", "table", "assert", "final", "type", "byte", "bit",
               "cell", "config", "context", "cover", "expect", "extends",
               "local", "new", "null", "package", "priority", "program",
               "randomize", "ref", "return", "shortint", "static", "this",
               "unique", "var", "wait", "wildcard", "with", "do", "for"}


# ---------------------------------------------------------------- golden 解析
def read(name):
    return (GOLDEN / f"{name}.sv").read_text()


def port_list(name, text=None):
    text = text if text is not None else read(name)
    m = re.search(rf"^module {re.escape(name)}\((.*?)\n\);", text, re.S | re.M)
    assert m, name
    ports = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            ports.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1,
                          pm.group(3)))
    return ports


def pw(ports, nm):
    for _, w, n in ports:
        if n == nm:
            return w
    return None


def has(ports, nm):
    return any(n == nm for _, _, n in ports)


def macro_chain(text):
    macro = re.search(r"\b(sram_array_\w+)\s+array\s*\(", text).group(1)
    mtext = read(macro)
    mports = port_list(macro, mtext)
    child = re.search(r"^\s+(\w+)\s+array\s*\(", mtext, re.M).group(1)
    ctext = read(child)
    ext = re.search(r"\b(\w+_ext)\s+\w+\s*\(", ctext).group(1)
    return (macro, child, ext,
            has(mports, "RW0_wmask"), has(mports, "mbist_dft_ram_bypass"))


def _else_branch(expr):
    """把 `cond ? a : b` 剥成 b（只剥最外层，按括号/花括号深度找冒号）。"""
    expr = expr.strip()
    if "?" not in expr:
        return expr
    q = expr.index("?")
    depth, i = 0, q + 1
    while i < len(expr):
        c = expr[i]
        if c in "({[":
            depth += 1
        elif c in ")}]":
            depth -= 1
        elif c == ":" and depth == 0:
            return expr[i + 1:].strip()
        i += 1
    raise AssertionError("ternary without ':' " + expr[:60])


def wdata_terms(text):
    """RW0_wdata 的功能写分支拼接项（MSB→LSB）。每项是端口名或字面量。

    golden 的形状是 `mbistAck ? boreWdata : (resetState ? 0 : {功能数据})`，
    层数随变体而变，所以一路剥 else 分支直到剩下拼接本身。
    """
    m = re.search(r"\.RW0_wdata\s*\n?\s*\((.*?)\),\n\s*\.RW0_rdata", text, re.S)
    assert m, "RW0_wdata not found"
    func = m.group(1).strip()
    while "?" in func and not func.startswith("{"):
        func = _else_branch(func)
    if func.startswith("{"):
        func = func[1:func.rfind("}")]
        return [t.strip() for t in func.split(",")]
    return [func]


def lit_width(tok):
    m = re.match(r"(\d+)'[hbd]", tok)
    return int(m.group(1)) if m else None


def resp_slices(text):
    """io_r_resp_data* 的读切片: {端口名: (hi, lo) 或 None(整条)}"""
    out = {}
    for m in re.finditer(r"assign (io_r_resp_data\w*) = _array_RW0_rdata"
                         r"(?:\[(\d+)(?::(\d+))?\])?;", text):
        nm, hi, lo = m.group(1), m.group(2), m.group(3)
        out[nm] = None if hi is None else (int(hi), int(lo) if lo is not None else int(hi))
    return out


def analyze(name):
    text = read(name)
    ports = port_list(name, text)
    i = {"name": name, "text": text, "ports": ports}
    i["aw"] = pw(ports, "io_r_req_bits_setIdx")
    i["set"] = 1 << i["aw"]
    i["macro"], i["child"], i["ext"], i["m_wmask"], i["m_bypass"] = macro_chain(text)

    mm = re.match(r"sram_array_1p(\d+)x(\d+)m(\d+)s(\d+)h(\d+)l(\d+)b", i["macro"])
    i["macro_sets"], i["macro_w"], i["macro_seg"] = (int(mm.group(1)), int(mm.group(2)),
                                                     int(mm.group(3)))
    # G1 锚点（核里的 elaborate 期自检要用，全部机械提取自 golden，不手填）：
    #   macro 名里的 l<LAT> = 宏读延迟（>1 即多周期宏）
    #   golden io_r_resp_data_<k> 端口个数 = way 数（宏名只给 way*位宽 的乘积）
    i["macro_lat"] = int(mm.group(6))
    # 注意用「不同的 way 序号个数」而不是「恰好叫 io_r_resp_data_<k> 的端口个数」：
    # 结构体形态的变体(145/146/163/185)golden 端口叫 io_r_resp_data_<k>_<字段>，
    # 用 $ 锚定会数出 0，静默把锚点废掉。
    i["g1_way_ports"] = len({m.group(1) for _, _, n in ports
                             for m in [re.match(r"io_r_resp_data_(\d+)", n)] if m})
    terms = wdata_terms(text)
    ways = sorted({int(m.group(1)) for t in terms
                   for m in [re.match(r"io_w_req_bits_data_(\d+)", t)] if m})
    i["way"] = len(ways) if ways else 1
    per_way = len(terms) // i["way"]
    way0 = terms[-per_way:]              # 最低的一份 = way0
    rs = resp_slices(text)

    fields, pos = [], 0
    for tok in reversed(way0):           # LSB→MSB 逐项定位
        m = re.match(r"io_w_req_bits_data_\d+_?(\w*)$", tok)
        if m:
            fields.append((m.group(1), pw(ports, tok), None, pos))
            pos += pw(ports, tok)
        else:
            w = lit_width(tok)
            assert w, f"unrecognised wdata term {tok}"
            fld = None
            for rn, sl in rs.items():    # 常量项：借覆盖同一位段的读端口取个名字
                if sl and sl[1] == pos and sl[0] == pos + w - 1:
                    m2 = re.match(r"io_r_resp_data_\d+_?(\w*)$", rn)
                    if m2 and m2.group(1):
                        fld = m2.group(1)
                    break
            fields.append((fld or f"const_{pos}", w, tok, pos))
            pos += w
    i["data_w"] = pos
    i["fields"] = list(reversed(fields))          # MSB→LSB
    i["flat"] = (len(i["fields"]) == 1 and i["fields"][0][0] == "")

    i["mw"] = i["way"] * i["data_w"]
    assert i["mw"] == i["macro_w"], (name, i["mw"], i["macro_w"])
    i["bore_aw"] = pw(ports, "boreChildrenBd_bore_addr")
    i["bore_dw"] = pw(ports, "boreChildrenBd_bore_wdata")
    i["bore_nseg"] = i["mw"] // i["bore_dw"]
    i["mask_seg_w"] = 0 if i["macro_seg"] == i["data_w"] else i["macro_seg"]
    i["bitmask"] = has(ports, "io_w_req_bits_flattened_bitmask")
    i["in_mask_w"] = i["mw"] if i["bitmask"] else i["way"]
    seg_w = i["macro_seg"] if i["mask_seg_w"] else i["mw"] // i["in_mask_w"]
    i["wmask_w"] = i["mw"] // seg_w
    i["mask_rep"] = i["wmask_w"] // i["in_mask_w"]
    i["reset"] = "_resetState" in text
    i["hold"] = "rdata_hold" in text
    i["clockgate"] = "MbistClockGateCell" in text
    i["extcg"] = has(ports, "io_mbistCgCtl_en")
    i["mcp"] = "rckEnReg" in text
    i["extra_reset"] = has(ports, "extra_reset")
    i["has_r_ready"] = has(ports, "io_r_req_ready")
    i["has_w_ready"] = has(ports, "io_w_req_ready")
    i["has_resetdone"] = has(ports, "io_resetDone")
    i["has_waymask"] = has(ports, "io_w_req_bits_waymask")
    i["resp"] = rs
    if i["bore_nseg"] > 1:
        assert i["bore_nseg"] == i["wmask_w"], name
        assert pw(ports, "boreChildrenBd_bore_selectedOH") == i["bore_nseg"], name
    return i


# ---------------------------------------------------------------- 薄文件生成
def sv_name(f):
    return ("way_" + f) if f in SV_KEYWORDS else f


def emit_wrapper(i):
    n, mw, way, dw = i["name"], i["mw"], i["way"], i["data_w"]
    cg = ("外置（上层例化门控单元；本模块导出使能、收回 rclk）" if i["extcg"]
          else "内置 MbistClockGateCell" if i["clockgate"] else "无（宏时钟直连 clock）")
    L = [
        f"// {n}.sv — {BLURB[n]}",
        f"// 规模：{i['set']} set × {way} way × {dw} 位/way = 宏 {mw} 位（{i['macro']}）；",
        "//       写掩码 " + (f"{i['wmask_w']} 段 × {i['macro_seg']} 位"
                            + (f"，每 way 一位掩码复制 {i['mask_rep']} 份盖住自己那几段"
                               if i["mask_rep"] > 1 else "，每 way 恰好一位")
                            if i["m_wmask"] else "无（宏不带 wmask，整条写）")
        + f"；MBIST bore 口 {i['bore_dw']} 位"
        + (f"（= 宏的 1/{i['bore_nseg']}，selectedOH 选段）；" if i["bore_nseg"] > 1 else "（整宏）；"),
        f"//       上电清零 {'有' if i['reset'] else '无'}；读保持 {'有' if i['hold'] else '无'}；"
        f"时钟门控 {cg}；"
        f"多周期宏 {'是（隔拍门控 + 读数据晚 2 拍回）' if i['mcp'] else '否'}。",
        "// 本文件设参数并把 golden 的扁平端口装配成核要的位向量；核体见 "
        "rtl/common/xs_SRAMTemplate_core.sv。",
    ]

    decls = []
    for d, w, nm in i["ports"]:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{nm}")
    L.append(f"module {n}(")
    L.append(",\n".join(decls))
    L.append(");")

    L.append("  wire        ram_clk, ram_bypass, ram_bp_clken, ram_en, ram_wmode;")
    L.append(f"  wire [{i['aw']-1}:0]  ram_addr;")
    L.append(f"  wire [{i['wmask_w']-1}:0]  ram_wmask;")
    L.append(f"  wire [{mw-1}:0] ram_wdata, ram_rdata;")

    need_done = i["has_w_ready"] or i["has_resetdone"]
    if need_done:
        L.append("  wire        resetDone;   // 清零 FSM 已跑完（无清零 FSM 的变体恒 1）")

    post = []
    if i["flat"]:
        rd_expr = ("{" + ", ".join(f"io_r_resp_data_{k}" for k in reversed(range(way))) + "}"
                   if way > 1 else "io_r_resp_data_0")
        wd_expr = ("{" + ", ".join(f"io_w_req_bits_data_{k}" for k in reversed(range(way))) + "}"
                   if way > 1 else "io_w_req_bits_data_0")
    else:
        L.append("")
        L.append(f"  // 一条 {dw} 位表项；字段顺序 = golden 写口拼接顺序（MSB→LSB），"
                 f"位 [{dw-1}:0]")
        L.append("  typedef struct packed {")
        tw = max((len(f"[{w-1}:0]") for _, w, _, _ in i["fields"] if w > 1), default=0)
        nw = max(len(sv_name(f)) for f, _, _, _ in i["fields"])
        for fld, w, const, pos in i["fields"]:
            ws = (f"[{w-1}:0]" if w > 1 else "").ljust(tw)
            cmt = ""
            if const is not None:
                cmt = f"  // golden 写入恒为 {const}"
            elif sv_name(fld) != fld:
                cmt = f"  // golden 端口名叫 {fld}，是 SV 保留字，这里改名"
            L.append(((f"    logic {ws} {sv_name(fld)};").ljust(14 + tw + nw) + cmt).rstrip())
        L.append("  } entry_t;")
        arr = f" [{way-1}:0]" if way > 1 else ""
        cmt = "   // 按 way 索引，[0] 在宏数据的低位" if way > 1 else ""
        L.append(f"  entry_t{arr} wdata, rdata;{cmt}")
        L.append("")
        L.append("  always_comb begin")
        for k in range(way):
            idx = f"[{k}]" if way > 1 else ""
            L.append(f"    wdata{idx} = '{{")
            items = [f"{sv_name(f):<{nw}s}: {c if c is not None else f'io_w_req_bits_data_{k}_{f}'}"
                     for f, w, c, pos in i["fields"]]
            for j, it in enumerate(items):
                L.append(f"      {it}" + ("," if j + 1 < len(items) else ""))
            L.append("    };")
        L.append("  end")
        for k in range(way):
            idx = f"[{k}]" if way > 1 else ""
            for fld, w, const, pos in i["fields"]:
                rp = f"io_r_resp_data_{k}_{fld}"
                if has(i["ports"], rp):
                    post.append(f"  assign {rp} = rdata{idx}.{sv_name(fld)};")
        rd_expr, wd_expr = "rdata", "wdata"
        L.append("")

    wmask = ("io_w_req_bits_flattened_bitmask" if i["bitmask"]
             else "io_w_req_bits_waymask" if i["has_waymask"] else "1'b1")
    extra = "extra_reset" if i["extra_reset"] else "1'b0"
    rdy = "io_r_req_ready" if i["has_r_ready"] else "/* 本变体无 r ready 口 */"
    done = "resetDone" if need_done else "/* 本变体不引出清零完成 */"
    rclk = "io_mbistCgCtl_rclk" if i["extcg"] else "1'b0"
    cgen = (["io_mbistCgCtl_en", "io_mbistCgCtl_rckEn", "io_mbistCgCtl_wckEn"] if i["extcg"]
            else ["/* 门控内置 */"] * 3)

    L += [
        "  xs_SRAMTemplate_core #(",
        f"    .SET({i['set']}), .WAY({way}), .DATA_WIDTH({dw}), .BORE_AW({i['bore_aw']}),",
        f"    .ENABLE_RESET({int(i['reset'])}), .ENABLE_HOLDREAD({int(i['hold'])}),",
        f"    .ENABLE_CLOCKGATE({int(i['clockgate'])}), .EXTRA_RESET({int(i['extra_reset'])}),",
        f"    .USE_BITMASK({int(i['bitmask'])}),",
        f"    .MASK_SEG_W({i['mask_seg_w']}), .BORE_NSEG({i['bore_nseg']}),",
        f"    .EXT_CLOCKGATE({int(i['extcg'])}), .MCP_HOLD({int(i['mcp'])}),",
        f"    // G1 锚点（勿手改，全部来自 golden {i['name']}.sv）：",
        f"    //   宏名 sram_array_1p{i['macro_sets']}x{i['macro_w']}m{i['macro_seg']}...l{i['macro_lat']}b_* "
        f"/ io_r_resp_data_<k> 共 {i['g1_way_ports']} 个 / bore_addr {i['bore_aw']} 位",
        f"    .G1_MACRO_SETS({i['macro_sets']}), .G1_MACRO_BITS({i['macro_w']}), "
        f".G1_MACRO_MASK({i['macro_seg']}),",
        f"    .G1_MACRO_LAT({i['macro_lat']}), .G1_WAY_PORTS({i['g1_way_ports']}), "
        f".G1_BORE_AW({i['bore_aw']})",
        "  ) u_core (",
        f"    .clock(clock), .reset(reset), .io_extra_reset({extra}),",
        f"    .io_r_req_ready({rdy}),",
        "    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),",
        f"    .io_r_resp_data({rd_expr}),",
        "    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),",
        f"    .io_w_req_bits_data({wd_expr}), .io_w_mask({wmask}),",
        f"    .io_resetDone({done}),",
        "    .io_broadcast_ram_hold(io_broadcast_ram_hold),",
        "    .io_broadcast_ram_bypass(io_broadcast_ram_bypass),",
        "    .io_broadcast_ram_bp_clken(io_broadcast_ram_bp_clken),",
        "    .io_broadcast_cgen(io_broadcast_cgen),",
        f"    .io_mbistCgCtl_en({cgen[0]}), .io_mbistCgCtl_rckEn({cgen[1]}),",
        f"    .io_mbistCgCtl_wckEn({cgen[2]}), .io_mbistCgCtl_rclk({rclk}),",
        "    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),",
        "    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),",
        "    .boreChildrenBd_bore_wdata(boreChildrenBd_bore_wdata),",
        "    .boreChildrenBd_bore_wmask(boreChildrenBd_bore_wmask),",
        "    .boreChildrenBd_bore_re(boreChildrenBd_bore_re),",
        "    .boreChildrenBd_bore_we(boreChildrenBd_bore_we),",
        "    .boreChildrenBd_bore_rdata(boreChildrenBd_bore_rdata),",
        "    .boreChildrenBd_bore_ack(boreChildrenBd_bore_ack),",
        "    .boreChildrenBd_bore_selectedOH(boreChildrenBd_bore_selectedOH),",
        "    .ram_clk(ram_clk), .ram_bypass(ram_bypass), .ram_bp_clken(ram_bp_clken),",
        "    .ram_addr(ram_addr), .ram_en(ram_en), .ram_wmode(ram_wmode),",
        "    .ram_wmask(ram_wmask), .ram_wdata(ram_wdata), .ram_rdata(ram_rdata)",
        "  );",
        f"  {i['macro']} array (",
    ]
    if i["m_bypass"]:
        L.append("    .mbist_dft_ram_bypass(ram_bypass), .mbist_dft_ram_bp_clken(ram_bp_clken),")
    L.append("    .RW0_clk(ram_clk), .RW0_addr(ram_addr), .RW0_en(ram_en), .RW0_wmode(ram_wmode),")
    if i["m_wmask"]:
        L.append("    .RW0_wmask(ram_wmask),")
    L.append("    .RW0_wdata(ram_wdata), .RW0_rdata(ram_rdata)")
    L.append("  );")
    L += post
    if i["has_w_ready"]:
        L.append("  assign io_w_req_ready = resetDone;   // 清零期间不收写")
    if i["has_resetdone"]:
        L.append("  assign io_resetDone = resetDone;")
    L.append("endmodule")
    return "\n".join(L) + "\n"


# ---------------------------------------------------------------- tb 生成
TB_HEAD = """// 自动生成：verif/ut/SRAMTemplateNewForm/gen.py —— 勿手改
// G1 新形态 SRAMTemplate 八变体的双例化 UT：golden <名> 与重写 <名>_xs 吃同一份激励，
// 每拍比全部输出。
//
// 存储类模块最容易出的假绿是"UT 全过但根本没写进去"（两边都读出 x，比较当然相等）。
// 所以除 errors 外还有两道闸：
//   * z 闸：任何一侧输出出现 z（未驱动）直接算错——上一轮出过输出悬空的 SRAM wrapper；
//   * 覆盖闸：写掩码全 0 / 全 1 / 混合、读写同 set、时钟门控关闭拍、MBIST 读写、
//     以及"读回数据无 x"与"读回非全 0"（证明数据真写进去又读出来）各自计数，
//     任一项为 0 判 FAIL。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 120000;
  int unsigned WARMUP  = 1000;   // 等最大的 reset FSM(256 set) 清零完成并写热几个 set
  bit clk = 0, rst;
  int errors = 0, checks = 0, zhits = 0;
  int unsigned cycle = 0;
  always #5 clk = ~clk;
  always @(posedge clk) cycle++;

  // 某个值里有没有 z 位（x 是允许的：没写过的 RAM 本来就读出 x）
  function automatic bit has_z(input logic [1023:0] v, input int w);
    has_z = 1'b0;
    for (int b = 0; b < w; b++) if (v[b] === 1'bz) has_z = 1'b1;
  endfunction
  function automatic bit has_x(input logic [1023:0] v, input int w);
    has_x = 1'b0;
    for (int b = 0; b < w; b++) if (v[b] === 1'bx) has_x = 1'b1;
  endfunction
"""


def emit_tb(infos):
    L = [TB_HEAD]
    covnames = []
    for i in infos:
        n, p = i["name"], "v" + i["name"]
        ins = [(w, nm) for d, w, nm in i["ports"]
               if d == "input" and nm not in ("clock", "reset", "io_mbistCgCtl_rclk")]
        outs = [(w, nm) for d, w, nm in i["ports"] if d == "output"]
        L.append(f"  // ================= {n} =================")
        for w, nm in ins:
            ws = f"[{w-1}:0] " if w > 1 else ""
            L.append(f"  logic {ws}{p}_{nm};")
        for w, nm in outs:
            ws = f"[{w-1}:0] " if w > 1 else ""
            L.append(f"  wire {ws}{p}_g_{nm};")
            L.append(f"  wire {ws}{p}_i_{nm};")

        gc = [".clock(clk)", ".reset(rst)"] + [f".{nm}({p}_{nm})" for _, nm in ins]
        ic = list(gc)
        if i["extcg"]:
            # 外置门控：tb 扮演上层，给两侧各配一个 ICG（低电平透明锁存 + 与门）。
            # 使能本身也在被比较，所以各用各的门控不会掩盖差异。
            L.append(f"  logic {p}_g_lat, {p}_i_lat;")
            L.append(f"  wire  {p}_g_rclk = clk & {p}_g_lat;")
            L.append(f"  wire  {p}_i_rclk = clk & {p}_i_lat;")
            L.append(f"  always @(*) if (!clk) begin")
            L.append(f"    {p}_g_lat = {p}_g_io_mbistCgCtl_rckEn | {p}_g_io_mbistCgCtl_wckEn;")
            L.append(f"    {p}_i_lat = {p}_i_io_mbistCgCtl_rckEn | {p}_i_io_mbistCgCtl_wckEn;")
            L.append("  end")
            gc.append(f".io_mbistCgCtl_rclk({p}_g_rclk)")
            ic.append(f".io_mbistCgCtl_rclk({p}_i_rclk)")
        gc += [f".{nm}({p}_g_{nm})" for _, nm in outs]
        ic += [f".{nm}({p}_i_{nm})" for _, nm in outs]
        L.append(f"  {n}    u_g_{n} ({', '.join(gc)});")
        L.append(f"  {n}_xs u_i_{n} ({', '.join(ic)});")

        mask_port = ("io_w_req_bits_flattened_bitmask" if i["bitmask"]
                     else "io_w_req_bits_waymask" if i["has_waymask"] else None)
        mwb = i["in_mask_w"]
        cov = [f"{p}_cov_w", f"{p}_cov_rw_same", f"{p}_cov_cgoff", f"{p}_cov_bore_w",
               f"{p}_cov_bore_r", f"{p}_cov_hold", f"{p}_cov_rd_known", f"{p}_cov_rd_nonzero"]
        if mask_port:
            cov += [f"{p}_cov_m0", f"{p}_cov_m1", f"{p}_cov_mmix"]
        if i["bore_nseg"] > 1:
            cov += [f"{p}_cov_seg_all"]
        if i["extcg"]:
            # 外置门控才看得见使能：请求在、但门控使能被压低的拍（多周期宏的隔拍关门）
            cov += [f"{p}_cov_cg_gap"]
        covnames += cov
        L.append("  int " + ", ".join(f"{c} = 0" for c in cov) + ";")
        if i["bore_nseg"] > 1:
            L.append(f"  logic [{i['bore_nseg']-1}:0] {p}_seg_seen = '0;")

        # ---- 激励：地址向少数几个 set 集中，保证读写同址与写后读回都打得到
        L.append("  always @(negedge clk) begin")
        L.append("    if (rst) begin")
        for w, nm in ins:
            if re.search(r"(valid|_re$|_we$|_ack$|_hold$)", nm):
                L.append(f"      {p}_{nm} <= 1'b0;")
        L.append("    end else begin")
        for w, nm in ins:
            if re.search(r"req_valid$", nm):
                pct = "($urandom_range(0,2)==0)" if "_w_" in nm else "($urandom_range(0,3)!=0)"
                L.append(f"      {p}_{nm} <= {pct};")
            elif re.search(r"req_bits_setIdx$", nm):
                L.append(f"      {p}_{nm} <= ($urandom_range(0,3)!=0)"
                         f" ? {w}'($urandom_range(0,7)) : {w}'($urandom);")
            elif nm == mask_port:
                L.append("      case ($urandom_range(0,2))   // 全 0 / 全 1 / 混合 各 1/3")
                L.append(f"        0: {p}_{nm} <= {mwb}'b0;")
                L.append(f"        1: {p}_{nm} <= {{{mwb}{{1'b1}}}};")
                L.append(f"        default: {p}_{nm} <= {mwb}'($urandom);")
                L.append("      endcase")
            elif re.search(r"(_re$|_we$|_ack$)", nm):
                L.append(f"      {p}_{nm} <= ($urandom_range(0,7)==0);")
            elif nm.endswith("selectedOH") and i["bore_nseg"] > 1:
                L.append(f"      {p}_{nm} <= {w}'(1) << $urandom_range(0,{w-1});")
            elif re.search(r"ram_hold$", nm):
                L.append(f"      {p}_{nm} <= ($urandom_range(0,15)==0);")
            elif re.search(r"(bypass|bp_clken|aux_clk|aux_ckbp|mcp_hold)$", nm):
                L.append(f"      {p}_{nm} <= 1'b0;")
            elif w <= 32:
                L.append(f"      {p}_{nm} <= {w}'($urandom);")
            else:
                rep = (w + 31) // 32
                L.append(f"      {p}_{nm} <= {w}'({{{', '.join(['$urandom()'] * rep)}}});")
        L.append("    end")
        L.append("  end")

        # ---- 覆盖统计（两侧输入相同，用共享输入 + golden 侧输出观测）
        rdport = [(w, nm) for w, nm in outs if nm.startswith("io_r_resp_data")]
        L.append("  always @(posedge clk) if (!rst && cycle > WARMUP) begin")
        L.append(f"    if ({p}_io_w_req_valid && !{p}_io_broadcast_ram_hold) {p}_cov_w++;")
        L.append(f"    if ({p}_io_w_req_valid && {p}_io_r_req_valid"
                 f" && {p}_io_w_req_bits_setIdx == {p}_io_r_req_bits_setIdx) {p}_cov_rw_same++;")
        L.append(f"    if (!{p}_io_w_req_valid && !{p}_io_r_req_valid"
                 f" && !{p}_boreChildrenBd_bore_ack) {p}_cov_cgoff++;")
        L.append(f"    if ({p}_boreChildrenBd_bore_ack && {p}_boreChildrenBd_bore_we)"
                 f" {p}_cov_bore_w++;")
        L.append(f"    if ({p}_boreChildrenBd_bore_ack && {p}_boreChildrenBd_bore_re)"
                 f" {p}_cov_bore_r++;")
        L.append(f"    if ({p}_io_broadcast_ram_hold) {p}_cov_hold++;")
        if mask_port:
            L.append(f"    if ({p}_io_w_req_valid) begin")
            L.append(f"      if ({p}_{mask_port} == {mwb}'b0)      {p}_cov_m0++;")
            L.append(f"      else if (&{p}_{mask_port})            {p}_cov_m1++;")
            L.append(f"      else                                  {p}_cov_mmix++;")
            L.append("    end")
        if i["bore_nseg"] > 1:
            L.append(f"    if ({p}_boreChildrenBd_bore_ack)"
                     f" {p}_seg_seen <= {p}_seg_seen | {p}_boreChildrenBd_bore_selectedOH;")
            L.append(f"    {p}_cov_seg_all = &{p}_seg_seen;")
        if i["extcg"]:
            L.append(f"    if (({p}_io_r_req_valid || {p}_io_w_req_valid)"
                     f" && !({p}_g_io_mbistCgCtl_rckEn || {p}_g_io_mbistCgCtl_wckEn))"
                     f" {p}_cov_cg_gap++;")
        allrd = "{" + ", ".join(f"{p}_g_{nm}" for _, nm in rdport) + "}"
        tot = sum(w for w, _ in rdport)
        L.append(f"    if (!has_x({allrd}, {tot}) && !has_z({allrd}, {tot})) begin")
        L.append(f"      {p}_cov_rd_known++;")
        L.append(f"      if (|{allrd}) {p}_cov_rd_nonzero++;")
        L.append("    end")
        L.append("  end")

        # ---- 逐拍比对 + z 闸
        L.append("  always @(negedge clk) if (!rst && cycle > WARMUP) begin")
        L.append("    #4; checks++;")
        for w, nm in outs:
            L.append(f"    if ({p}_g_{nm} !== {p}_i_{nm}) begin errors++;")
            L.append(f"      if (errors < 40) $display(\"[%0t] {n}.{nm} g=%h i=%h\","
                     f" $time, {p}_g_{nm}, {p}_i_{nm}); end")
            L.append(f"    if (has_z({p}_g_{nm}, {w}) || has_z({p}_i_{nm}, {w})) begin zhits++;")
            L.append(f"      if (zhits < 20) $display(\"[%0t] Z-DRIVE {n}.{nm} g=%h i=%h\","
                     f" $time, {p}_g_{nm}, {p}_i_{nm}); end")
        L.append("  end")
        L.append("")

    L.append("  int cov_fail = 0;")
    L.append("  task automatic covchk(string nm, int v);")
    L.append("    $display(\"  cov %-38s = %0d\", nm, v);")
    L.append("    if (v == 0) begin cov_fail++; $display(\"  *** COVERAGE HOLE: %s == 0\", nm); end")
    L.append("  endtask")
    L.append("""
  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 120000;
    rst = 1; repeat (5) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("---------------------------------------------");""")
    for c in covnames:
        L.append(f'    covchk("{c[1:]}", {c});')
    L.append("""    $display("---------------------------------------------");
    $display("checks=%0d errors=%0d zhits=%0d cov_holes=%0d", checks, errors, zhits, cov_fail);
    if (errors == 0 && zhits == 0 && cov_fail == 0 && checks > 100000) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    return "\n".join(L)


# ---------------------------------------------------------------- Makefile
def emit_mk(infos):
    rtl = ["$(RTL_DIR)/common/xs_SRAMTemplate_core.sv"] + \
          [f"$(RTL_DIR)/common/{i['name']}.sv" for i in infos]
    sim_deps, fm_deps, fm_ref = set(), set(), {}
    for i in infos:
        sim_deps |= {i["macro"] + ".sv", i["child"] + ".sv", i["ext"] + ".v"}
        fm_deps |= {i["macro"] + ".sv", i["child"] + ".sv"}
        deps = [i["macro"] + ".sv", i["child"] + ".sv"]
        if i["clockgate"]:
            deps += ["MbistClockGateCell.sv", "ClockGate.sv"]
            fm_deps |= {"MbistClockGateCell.sv", "ClockGate.sv"}
            sim_deps |= {"MbistClockGateCell.sv", "ClockGate.sv"}
        fm_ref[i["name"]] = deps
    mk = ["# 自动生成：verif/ut/SRAMTemplateNewForm/gen.py（G1 基线驱动）—— 勿手改",
          "# G1 新形态 SRAMTemplate 八变体（掩码复制 / 分段 MBIST / 外置时钟门控 /",
          "# 多周期宏 / 结构体数据口）。verif/ut/SRAMTemplate 覆盖其余变体，两边共用",
          "# 同一个 rtl/common/xs_SRAMTemplate_core.sv。",
          "MODULE = SRAMTemplateNewForm", "", "RTL_DIR = ../../../rtl",
          "RTL_SRCS = " + " \\\n           ".join(rtl),
          "TB_SRCS = tb.sv", "",
          "# 厂商 SRAM 宏链：golden 同源文件, 两侧同读(FM impl 侧经 RTL_GOLDEN_DEPS)。",
          "# 宏内 array_*_ext 是 vendor 叶子(.v, FM 不读)⇒ 对称未解析黑盒。",
          "RTL_GOLDEN_DEPS = " + " \\\n                  ".join(
              f"$(GOLDEN_RTL)/{d}" for d in sorted(fm_deps)),
          "",
          "GOLDEN_SRCS = " + " \\\n              ".join(
              [f"$(GOLDEN_RTL)/{i['name']}.sv" for i in infos]
              + [f"$(GOLDEN_RTL)/{d}" for d in sorted(sim_deps)]),
          ""]
    for i in infos:
        mk.append(f"FM_REF_DEPS_{i['name']} = " + " ".join(fm_ref[i["name"]]))
    mk += ["",
           "# FM_MODE=assembly: 唯一抽象边界 = 厂商 SRAM 宏叶子 array_*_ext(.v 行为模型,",
           "# 两侧同一文件, FM 不读 ⇒ 对称未解析黑盒)。",
           "FM_MODE = assembly",
           "FM_ALLOWLIST ?= 8",
           "FM_VARIANTS = " + " ".join(i["name"] for i in infos), "",
           "include ../../../scripts/ut_common.mk", "",
           "VCS += +define+SYNTHESIS", ""]
    return "\n".join(mk)


def main():
    infos = [analyze(t) for t in TARGETS]
    for i in infos:
        (XSSV / "rtl/common" / f"{i['name']}.sv").write_text(emit_wrapper(i))
    HERE.mkdir(parents=True, exist_ok=True)
    (HERE / "tb.sv").write_text(emit_tb(infos))
    (HERE / "Makefile").write_text(emit_mk(infos))
    for i in infos:
        print(f"{i['name']}: set={i['set']} way={i['way']} dw={i['data_w']} mw={i['mw']} "
              f"wmask={i['wmask_w']}x{i['macro_seg']} rep={i['mask_rep']} "
              f"maskseg={i['mask_seg_w']} boreNseg={i['bore_nseg']} "
              f"rst={int(i['reset'])} hold={int(i['hold'])} cg={int(i['clockgate'])} "
              f"extcg={int(i['extcg'])} mcp={int(i['mcp'])} fields={len(i['fields'])} "
              f"wrdy={int(i['has_w_ready'])} rdone={int(i['has_resetdone'])}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
