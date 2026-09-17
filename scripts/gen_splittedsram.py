#!/usr/bin/env python3
"""gen_splittedsram.py —— 生成 PtwCache 的 SplittedSRAM_1 / SplittedSRAM_2 两个变体薄文件。

两个变体共用 rtl/memblock/SplittedSRAM_ptw_core.sv 里的 xs_SplittedSRAM_ptw_core（手写，
本脚本不碰）。薄文件里只有三样东西，且**全部从 G1 golden 机械抽取**，不靠人记：
  1) 端口表：逐字取自 golden（端口必须与 golden 逐位同名同宽，这是规范硬要求）；
  2) u_core 的接线：把 golden 扁平端口按「路优先、下标从低位往高位」拼成核的位向量口；
  3) 内层 SRAMTemplate_* 的例化：实例名、模块名、每块自己的 MBIST bore / sigFromSrams
     广播编号，全部照 golden 原样（**是分份不是共用**——16 块各有一套，抄错就是真 bug）。

用法：
  python3 scripts/gen_splittedsram.py            # 写文件
  python3 scripts/gen_splittedsram.py --check    # 只比对，产物有漂移则非零退出
"""
import argparse
import difflib
import re
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import gen_file_nav

REPO = Path(__file__).resolve().parent.parent
GOLDEN = Path("/home/eda/xs-env/G1-canonical/golden-rtl")
OUT_DIR = REPO / "rtl" / "memblock"

# 每个变体的固定事实（set/way/waySplit/dataSplit 取自 PageTableCache.scala 的例化，
# tagLen/hasPerm/ReservedBits 取自 l1EntryType / l0EntryType；全部再由 golden 端口宽度复核）
VARIANTS = {
    "SplittedSRAM_1": dict(
        level="l1", tag_w=24, has_perm=False, rsvd_w=2,
        sets=4, way=2, way_split=1, data_split=1,
        what="PtwCache 的 l1：level-1 非叶 PTE 扇区缓存",
    ),
    "SplittedSRAM_2": dict(
        level="l0", tag_w=29, has_perm=True, rsvd_w=4,
        sets=64, way=4, way_split=2, data_split=8,
        what="PtwCache 的 l0：level-0 叶子 PTE（4KB 页）扇区缓存",
    ),
}
NUM, ASID_W, VMID_W, PBMT_W, PPN_W, PERM_W = 8, 16, 14, 2, 38, 7
PERM_FIELDS = ["d", "a", "g", "u", "x", "w", "r"]  # 高位在前，r 在最低位


def golden_text(name):
    return (GOLDEN / f"{name}.sv").read_text()


def port_block(name):
    """返回 golden 模块端口表的原文（不含首尾括号行）与 {端口名: 位宽}。"""
    t = golden_text(name)
    m = re.search(rf"^module {re.escape(name)}\(\n(.*?)\n\);", t, re.S | re.M)
    assert m, name
    body = m.group(1)
    widths = {}
    for pm in re.finditer(r"^\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", body, re.M):
        widths[pm.group(3)] = int(pm.group(2)) + 1 if pm.group(2) else 1
    return body, widths


def instances(name):
    """[(模块名, 实例名, {端口: 连接原文})]，顺序与 golden 一致。"""
    t = golden_text(name)
    body = t[t.index(f"module {name}("):]
    out = []
    for mod, inst, pl in re.findall(r"^  (\w+) (\w+) \(\n(.*?)^  \);", body, re.S | re.M):
        conn = {}
        for m in re.finditer(r"\.(\w+)\s*\n?\s*\((.*?)\),?\n(?=\s*\.|\s*$)", pl, re.S):
            conn[m.group(1)] = " ".join(m.group(2).split())
        out.append((mod, inst, conn))
    return out


def cat(items):
    """拼接表达式；items 按 MSB→LSB 给出。"""
    return "{" + ", ".join(items) + "}"


def way_cat(way, per_way):
    """路维拼接：way-1 在最高位（与核里 [WAY-1:0] 的下标一致）。"""
    return cat([per_way(w) for w in reversed(range(way))])


def build(name):
    v = VARIANTS[name]
    way, ws, ds = v["way"], v["way_split"], v["data_split"]
    perms_w = NUM * PERM_W if v["has_perm"] else 0
    entry_w = (v["tag_w"] + ASID_W + VMID_W + NUM * PBMT_W + NUM * PPN_W
               + NUM + NUM + perms_w + 1 + v["rsvd_w"])
    slice_w = entry_w // ds
    narr = ws * ds
    way_per = way // ws

    ports, widths = port_block(name)
    # 端口宽度复核：写侧 tag 宽必须与表里记的一致，否则说明参数记错了
    assert widths[f"io_w_req_bits_data_0_entries_tag"] == v["tag_w"], name
    assert widths["io_w_req_bits_waymask"] == way, name
    assert entry_w % ds == 0, (name, entry_w, ds)

    L = []
    a = L.append
    a(f"// {name}.sv —— {v['what']}（SplittedSRAM 家族变体，规模 "
      f"{v['sets']} set × {way} way × {entry_w} bit/entry）。")
    a(f"// 本变体参数：tagLen={v['tag_w']}、hasPerm={str(v['has_perm']).lower()}、"
      f"ReservedBits={v['rsvd_w']}、waySplit={ws}、dataSplit={ds}")
    a(f"//   ⇒ 拆成 {narr} 块内层 SRAM，每块 {way_per} 路 × {slice_w} bit"
      f"（{'无拆分，整条 entry 一块' if narr == 1 else f'way 维 {ws} 组 × data 维 {ds} 段'}）。")
    a("// 本层无任何寄存器：只做 PtwEntries 的打包/切分/归并，存储与读时序在内层")
    a(f"// SRAMTemplate_* 及其下的厂商 SRAM 宏里。核体见 SplittedSRAM_ptw_core.sv。")
    a("// 自动生成：scripts/gen_splittedsram.py（端口表与内层例化连线逐字取自 G1 golden）—— 勿手改。")
    a("")
    a(f"module {name}(")
    a(ports)
    a(");")
    a("")
    a("  // --------------------------------------------------------------------------")
    a("  // 参数与阵列侧总线")
    a("  // --------------------------------------------------------------------------")
    a(f"  localparam int NUM        = {NUM};")
    a(f"  localparam int TAG_W      = {v['tag_w']};")
    a(f"  localparam int ASID_W     = {ASID_W};")
    a(f"  localparam int VMID_W     = {VMID_W};")
    a(f"  localparam int PBMT_W     = {PBMT_W};")
    a(f"  localparam int PPN_W      = {PPN_W};")
    a(f"  localparam int PERM_W     = {PERM_W};")
    a(f"  localparam int WAY        = {way};")
    a(f"  localparam int WAY_SPLIT  = {ws};")
    a(f"  localparam int DATA_SPLIT = {ds};")
    a(f"  localparam int WAY_PER    = WAY / WAY_SPLIT;          // = {way_per}")
    a(f"  localparam int NARR       = WAY_SPLIT * DATA_SPLIT;   // = {narr}")
    a(f"  localparam int SLICE_W    = {slice_w};                // = ENTRY_W({entry_w}) / DATA_SPLIT")
    a("")
    a("  // 阵列侧总线：下标 n = way 组号 * DATA_SPLIT + data 段号，")
    a(f"  // 与 golden 的实例名 array_0_<组>_<段>、bore 编号 boreChildrenBd_bore_<n> 同序。")
    a("  wire [NARR-1:0][WAY_PER-1:0]              arr_waymask;")
    a("  wire [NARR-1:0][WAY_PER-1:0][SLICE_W-1:0] arr_wdata;")
    a("  wire [NARR-1:0][WAY_PER-1:0][SLICE_W-1:0] arr_rdata;")
    a("")
    for tagname, pre in (("写入", "wr"), ("读出", "rd")):
        a(f"  // {tagname}的 PtwEntries 字段，按 [路][Vec 下标] 聚成数组（核的位向量口按此序）")
        a(f"  wire [WAY-1:0][TAG_W-1:0]            {pre}_tag;")
        a(f"  wire [WAY-1:0][ASID_W-1:0]           {pre}_asid;")
        a(f"  wire [WAY-1:0][VMID_W-1:0]           {pre}_vmid;")
        a(f"  wire [WAY-1:0][NUM-1:0][PBMT_W-1:0]  {pre}_pbmt;")
        a(f"  wire [WAY-1:0][NUM-1:0][PPN_W-1:0]   {pre}_ppn;")
        a(f"  wire [WAY-1:0][NUM-1:0]              {pre}_vs;")
        a(f"  wire [WAY-1:0][NUM-1:0]              {pre}_onlypf;")
        a(f"  wire [WAY-1:0][NUM-1:0][PERM_W-1:0]  {pre}_perm;")
        a(f"  wire [WAY-1:0]                       {pre}_pref;")
        a("")
    a("  // --------------------------------------------------------------------------")
    a("  // 打包/切分核 u_core：写侧接线（路号高者在高位、Vec 下标大者在高位）")
    a("  // 写侧字段收集：golden 的扁平端口 → [路][下标] 数组")
    for w in range(way):
        q = f"io_w_req_bits_data_{w}_entries_"
        a(f"  assign wr_tag [{w}] = {q}tag;")
        a(f"  assign wr_asid[{w}] = {q}asid;")
        a(f"  assign wr_vmid[{w}] = {q}vmid;")
        a(f"  assign wr_pref[{w}] = {q}prefetch;")
        for i2 in range(NUM):
            a(f"  assign wr_pbmt[{w}][{i2}] = {q}pbmts_{i2};")
        for i2 in range(NUM):
            a(f"  assign wr_ppn [{w}][{i2}] = {q}ppns_{i2};")
        for i2 in range(NUM):
            a(f"  assign wr_vs  [{w}][{i2}] = {q}vs_{i2};")
        if v["has_perm"]:
            for i2 in range(NUM):
                a(f"  assign wr_onlypf[{w}][{i2}] = {q}onlypf_{i2};")
            for i2 in range(NUM):
                # 一条 perm 7 位，位序（高→低）d a g u x w r；逐位一行，别挤成 200 字符
                a(f"  assign wr_perm[{w}][{i2}] = {{{q}perms_{i2}_d,")
                for f in PERM_FIELDS[1:-1]:
                    a(f"                          {q}perms_{i2}_{f},")
                a(f"                          {q}perms_{i2}_r}};")
        else:
            a("  // l1 的 PtwEntries 没有 perms；onlypf 虽在 bundle 里但 PtwCache 不写也不读，")
            a("  //   golden 的写拼接里就是一串 0（8'h0），读侧连端口都被 firtool 消掉了。")
            a(f"  assign wr_onlypf[{w}] = '0;")
            a(f"  assign wr_perm[{w}] = '0;")
    a("")
    a("  // --------------------------------------------------------------------------")
    a("  xs_SplittedSRAM_ptw_core #(")
    a(f"    .NUM(NUM), .TAG_W(TAG_W), .ASID_W(ASID_W), .VMID_W(VMID_W),")
    a(f"    .PBMT_W(PBMT_W), .PPN_W(PPN_W), .PERM_W(PERM_W),")
    a(f"    .HAS_PERM({int(v['has_perm'])}), .RSVD_W({v['rsvd_w']}),")
    a(f"    .WAY(WAY), .WAY_SPLIT(WAY_SPLIT), .DATA_SPLIT(DATA_SPLIT)")
    a("  ) u_core (")

    a("    .w_tag       (wr_tag),")
    a("    .w_asid      (wr_asid),")
    a("    .w_vmid      (wr_vmid),")
    a("    .w_pbmts     (wr_pbmt),")
    a("    .w_ppns      (wr_ppn),")
    a("    .w_vs        (wr_vs),")
    a("    .w_onlypf    (wr_onlypf),")
    a("    .w_perms     (wr_perm),")
    a("    .w_prefetch  (wr_pref),")
    a("    .w_waymask   (io_w_req_bits_waymask),")
    a("    .r_tag       (rd_tag),")
    a("    .r_asid      (rd_asid),")
    a("    .r_vmid      (rd_vmid),")
    a("    .r_pbmts     (rd_pbmt),")
    a("    .r_ppns      (rd_ppn),")
    a("    .r_vs        (rd_vs),")
    a("    .r_onlypf    (rd_onlypf),")
    a("    .r_perms     (rd_perm),")
    a("    .r_prefetch  (rd_pref),")
    a("    .arr_waymask (arr_waymask),")
    a("    .arr_wdata   (arr_wdata),")
    a("    .arr_rdata   (arr_rdata)")
    a("  );")
    a("")
    a("  // --------------------------------------------------------------------------")
    a(f"  // {narr} 块内层 SRAM：每块自带一套 MBIST bore 与 sigFromSrams 广播")
    a("  // ★是分份不是共用★：编号照 golden 原样，抄错一根就是静默的真 bug。")
    a("  // --------------------------------------------------------------------------")

    insts = instances(name)
    assert len(insts) == narr, (name, len(insts), narr)
    for idx, (mod, inst, conn) in enumerate(insts):
        # 校验实例名与编号规则一致（g*DATA_SPLIT + k）
        g, k = int(inst.split("_")[2]), int(inst.split("_")[3])
        assert g * ds + k == idx, (inst, idx)
        a("  // --------------------------------------------------------------------------")
        a(f"  // 内层 SRAM #{idx}：{inst}（way 组 {g}，data 段 {k}，bore/sigFromSrams 编号 {idx}）")
        a("  // --------------------------------------------------------------------------")
        a(f"  {mod} {inst} (")
        lines = []
        for port, src in conn.items():
            m = re.fullmatch(r"io_r_resp_data_(\d)", port)
            if m:
                src = f"arr_rdata[{idx}][{m.group(1)}]"
            m = re.fullmatch(r"io_w_req_bits_data_(\d)", port)
            if m:
                src = f"arr_wdata[{idx}][{m.group(1)}]"
            if port == "io_w_req_bits_waymask":
                src = f"arr_waymask[{idx}]"
            lines.append((port, src))
        wpad = max(len(p) for p, _ in lines)
        for i, (port, src) in enumerate(lines):
            comma = "" if i == len(lines) - 1 else ","
            a(f"    .{port.ljust(wpad)} ({src}){comma}")
        a("  );")
    a("")
    a("  // --------------------------------------------------------------------------")
    a("  // 读出回填：把核给出的 struct 字段摊回 golden 的扁平输出端口")
    a("  // --------------------------------------------------------------------------")

    def emit_rd(portname, expr):
        if portname in widths:
            a(f"  assign {portname} = {expr};")

    for w in range(way):
        p = f"io_r_resp_data_{w}_entries_"
        emit_rd(p + "tag", f"rd_tag[{w}]")
        emit_rd(p + "asid", f"rd_asid[{w}]")
        emit_rd(p + "vmid", f"rd_vmid[{w}]")
        for i in range(NUM):
            emit_rd(p + f"pbmts_{i}", f"rd_pbmt[{w}][{i}]")
        for i in range(NUM):
            emit_rd(p + f"ppns_{i}", f"rd_ppn[{w}][{i}]")
        for i in range(NUM):
            emit_rd(p + f"vs_{i}", f"rd_vs[{w}][{i}]")
        for i in range(NUM):
            emit_rd(p + f"onlypf_{i}", f"rd_onlypf[{w}][{i}]")
        for i in range(NUM):
            for j, f in enumerate(PERM_FIELDS):
                bit = PERM_W - 1 - j            # d 在高位、r 在最低位
                emit_rd(p + f"perms_{i}_{f}", f"rd_perm[{w}][{i}][{bit}]")
        emit_rd(p + "prefetch", f"rd_pref[{w}]")
    a("endmodule")
    return "\n".join(L) + "\n"


def with_nav(text):
    """>1500 行的文件必须带「本文件导航」；复用 scripts/gen_file_nav.py 保证与闸同源。"""
    if text.count("\n") + 1 <= 1500:
        return text
    with tempfile.NamedTemporaryFile("w", suffix=".sv", delete=False) as fh:
        fh.write(text)
        tmp = Path(fh.name)
    try:
        gen_file_nav.apply(tmp)
        return tmp.read_text()
    finally:
        tmp.unlink()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="只比对，不写文件")
    args = ap.parse_args()
    rc = 0
    for name in VARIANTS:
        text = with_nav(build(name))
        dst = OUT_DIR / f"{name}.sv"
        old = dst.read_text() if dst.exists() else None
        if args.check:
            if old != text:
                rc = 1
                print(f"DRIFT: {dst}")
                for ln in list(difflib.unified_diff((old or "").splitlines(), text.splitlines(),
                                                    "repo", "generated", lineterm=""))[:40]:
                    print("  " + ln)
            else:
                print(f"OK: {dst}")
        else:
            if old != text:
                dst.write_text(text)
                print(f"written: {dst} ({text.count(chr(10))} 行)")
            else:
                print(f"unchanged: {dst}")
    return rc


if __name__ == "__main__":
    sys.exit(main())
