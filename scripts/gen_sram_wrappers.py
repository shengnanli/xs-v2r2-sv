#!/usr/bin/env python3
"""
为单端口 SRAMTemplate 变体生成：
  1) rtl/common/SRAMTemplate_variants.sv      变体包装（golden 同名，FM/ST 用）
  2) verif/ut/SRAMTemplate/variants_xs.sv      _xs 镜像（UT 用）
  3) verif/ut/SRAMTemplate/tb.sv               全变体 golden vs _xs 随机比对
  4) verif/ut/SRAMTemplate/sram_deps.mk        各变体宏链文件依赖（UT/FM）

每个变体例化 xs_SRAMTemplate_core（功能核）+ 对应厂商 SRAM 宏黑盒。生成器从 golden
变体源码与其宏定义自动提取参数（SET/WAY/DATA/BORE_AW）与特征（reset/holdRead/
clockgate/有无 ready 口/有无 waymask），并解析宏子模块链（sram_array_*→array_N→
array_N_ext）。

仅处理“单端口、单读口、per-way 掩码”族（ICache 等）。多读口/双口/bitmask/多周期
变体会被检测并跳过（打印 SKIP）。
"""
import re
import sys
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"

# 要覆盖的变体（ICache 单端口族：icsh_tag / icsh_dat）
VARIANTS = ["SRAMTemplate", "SRAMTemplate_2",
            "SRAMTemplate_4", "SRAMTemplate_8", "SRAMTemplate_16", "SRAMTemplate_32"]


def read(name):
    return (GOLDEN / f"{name}.sv").read_text()


def port_list(name):
    text = read(name)
    m = re.search(rf"^module {re.escape(name)}\((.*?)\n\);", text, re.S | re.M)
    assert m, name
    ports = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            d, w, n = pm.group(1), pm.group(2), pm.group(3)
            ports.append((d, int(w) + 1 if w else 1, n))
    return ports


def pwidth(ports, pname):
    for d, w, n in ports:
        if n == pname:
            return w
    return None


def has_port(ports, pname):
    return any(n == pname for _, _, n in ports)


def macro_chain(name):
    """返回 (macro, child_array, array_ext, macro_has_wmask, macro_has_bypass)"""
    text = read(name)
    macro = re.search(r"\b(sram_array_\w+)\s+array\s*\(", text).group(1)
    mtext = read(macro)
    mports = port_list(macro)
    has_wmask = has_port(mports, "RW0_wmask")
    has_bypass = has_port(mports, "mbist_dft_ram_bypass")
    child = re.search(r"^\s+(\w+)\s+array\s*\(", mtext, re.M).group(1)
    ctext = read(child)
    ext = re.search(r"\b(\w+_ext)\s+\w+\s*\(", ctext).group(1)
    return macro, child, ext, has_wmask, has_bypass


def analyze(name):
    ports = port_list(name)
    text = read(name)
    info = {}
    info["name"] = name
    info["aw"] = pwidth(ports, "io_r_req_bits_setIdx")
    info["set"] = 1 << info["aw"]
    info["way"] = len([1 for _, _, n in ports if re.match(r"io_w_req_bits_data_\d+$", n)])
    info["data_w"] = pwidth(ports, "io_r_resp_data_0")
    info["has_ready"] = has_port(ports, "io_r_req_ready")
    info["has_waymask"] = has_port(ports, "io_w_req_bits_waymask")
    info["bore_aw"] = pwidth(ports, "boreChildrenBd_bore_addr")
    info["bore_array_w"] = pwidth(ports, "boreChildrenBd_bore_array")
    info["reset"] = "_resetState" in text
    info["hold"] = "rdata_hold" in text
    info["clockgate"] = "MbistClockGateCell" in text
    # 读口数：io_r_resp_data_* 端口个数 / way
    nresp = len([1 for _, _, n in ports if re.match(r"io_r_resp_data_\d+$", n)])
    info["read_ports"] = nresp // max(info["way"], 1)
    info["ports"] = ports
    info["macro"], info["child"], info["ext"], info["m_wmask"], info["m_bypass"] = macro_chain(name)
    # 兼容性：单读口、无 bitmask、单端口（无独立 W 口/无 conflict）
    info["supported"] = (info["read_ports"] == 1
                         and not has_port(ports, "io_w_req_bits_flattened_bitmask")
                         and pwidth(ports, "io_r_resp_data_0") is not None)
    return info


def emit_wrapper(info, suffix=""):
    n = info["name"] + suffix
    ports = info["ports"]
    way, dw, mw = info["way"], info["data_w"], info["way"] * info["data_w"]
    decls = []
    for d, w, nm in ports:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{nm}")
    L = [f"module {n}(", ",\n".join(decls) + "\n);"]
    L.append(f"  wire        ram_clk, ram_bypass, ram_bp_clken, ram_en, ram_wmode;")
    L.append(f"  wire [{info['aw']-1}:0]  ram_addr;")
    L.append(f"  wire [{way-1}:0]  ram_wmask;")
    L.append(f"  wire [{mw-1}:0] ram_wdata, ram_rdata;")

    # core 连接
    rdata_cat = "{" + ", ".join(f"io_r_resp_data_{i}" for i in reversed(range(way))) + "}" if way > 1 else "io_r_resp_data_0"
    wdata_cat = "{" + ", ".join(f"io_w_req_bits_data_{i}" for i in reversed(range(way))) + "}" if way > 1 else "io_w_req_bits_data_0"
    rdy = "io_r_req_ready" if info["has_ready"] else "/* no ready port */"
    wmask = "io_w_req_bits_waymask" if info["has_waymask"] else "1'b1"
    L.append(f"  xs_SRAMTemplate_core #(")
    L.append(f"    .SET({info['set']}), .WAY({way}), .DATA_WIDTH({dw}), .BORE_AW({info['bore_aw']}),")
    L.append(f"    .ENABLE_RESET({int(info['reset'])}), .ENABLE_HOLDREAD({int(info['hold'])}), .ENABLE_CLOCKGATE({int(info['clockgate'])})")
    L.append(f"  ) u_core (")
    L.append(f"    .clock(clock), .reset(reset),")
    L.append(f"    .io_r_req_ready({rdy}),")
    L.append(f"    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),")
    L.append(f"    .io_r_resp_data({rdata_cat}),")
    L.append(f"    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),")
    L.append(f"    .io_w_req_bits_data({wdata_cat}), .io_w_req_bits_waymask({wmask}),")
    L.append(f"    .io_broadcast_ram_hold(io_broadcast_ram_hold),")
    L.append(f"    .io_broadcast_ram_bypass(io_broadcast_ram_bypass),")
    L.append(f"    .io_broadcast_ram_bp_clken(io_broadcast_ram_bp_clken),")
    L.append(f"    .io_broadcast_cgen(io_broadcast_cgen),")
    L.append(f"    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),")
    L.append(f"    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),")
    L.append(f"    .boreChildrenBd_bore_wdata(boreChildrenBd_bore_wdata),")
    bwmask = "boreChildrenBd_bore_wmask" if info["has_waymask"] else "boreChildrenBd_bore_wmask"
    L.append(f"    .boreChildrenBd_bore_wmask({bwmask}),")
    L.append(f"    .boreChildrenBd_bore_re(boreChildrenBd_bore_re),")
    L.append(f"    .boreChildrenBd_bore_we(boreChildrenBd_bore_we),")
    L.append(f"    .boreChildrenBd_bore_rdata(boreChildrenBd_bore_rdata),")
    L.append(f"    .boreChildrenBd_bore_ack(boreChildrenBd_bore_ack),")
    L.append(f"    .boreChildrenBd_bore_selectedOH(boreChildrenBd_bore_selectedOH),")
    L.append(f"    .ram_clk(ram_clk), .ram_bypass(ram_bypass), .ram_bp_clken(ram_bp_clken),")
    L.append(f"    .ram_addr(ram_addr), .ram_en(ram_en), .ram_wmode(ram_wmode),")
    L.append(f"    .ram_wmask(ram_wmask), .ram_wdata(ram_wdata), .ram_rdata(ram_rdata)")
    L.append(f"  );")

    # 宏例化（按宏实际端口）
    L.append(f"  {info['macro']} array (")
    if info["m_bypass"]:
        L.append(f"    .mbist_dft_ram_bypass(ram_bypass), .mbist_dft_ram_bp_clken(ram_bp_clken),")
    L.append(f"    .RW0_clk(ram_clk), .RW0_addr(ram_addr), .RW0_en(ram_en), .RW0_wmode(ram_wmode),")
    if info["m_wmask"]:
        L.append(f"    .RW0_wmask(ram_wmask),")
    L.append(f"    .RW0_wdata(ram_wdata), .RW0_rdata(ram_rdata)")
    L.append(f"  );")
    L.append("endmodule\n")
    return "\n".join(L)


def emit_tb(infos):
    L = ["""// 自动生成：scripts/gen_sram_wrappers.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 40000;
  int unsigned WARMUP  = 400;   // 等最大 set 的 reset FSM 清零完成
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  int unsigned cycle = 0;
  always #5 clk = ~clk;
  always @(posedge clk) cycle++;
"""]
    for info in infos:
        nm = info["name"]
        pre = "v" + nm
        ins = [(w, n) for d, w, n in info["ports"] if d == "input" and n not in ("clock", "reset")]
        outs = [(w, n) for d, w, n in info["ports"] if d == "output"]
        for w, n in ins:
            ws = f"[{w-1}:0] " if w > 1 else ""
            L.append(f"  logic {ws}{pre}_{n};")
        for w, n in outs:
            ws = f"[{w-1}:0] " if w > 1 else ""
            L.append(f"  wire {ws}{pre}_g_{n};")
            L.append(f"  wire {ws}{pre}_i_{n};")
        gc = [".clock(clk)", ".reset(rst)"] + [f".{n}({pre}_{n})" for _, n in ins]
        ic = list(gc)
        gc += [f".{n}({pre}_g_{n})" for _, n in outs]
        ic += [f".{n}({pre}_i_{n})" for _, n in outs]
        L.append(f"  {nm} u_g_{nm} ({', '.join(gc)});")
        L.append(f"  {nm}_xs u_i_{nm} ({', '.join(ic)});")
        # 激励
        L.append("  always @(negedge clk) begin")
        L.append("    if (rst) begin")
        for w, n in ins:
            if re.search(r"(valid|_re$|_we$|_ack$|_hold$)", n):
                L.append(f"      {pre}_{n} <= 1'b0;")
        L.append("    end else begin")
        for w, n in ins:
            if re.search(r"req_valid$", n):
                pct = "($urandom_range(0,2)==0)" if "_w_" in n else "($urandom_range(0,3)!=0)"
                L.append(f"      {pre}_{n} <= {pct};")
            elif re.search(r"(_re$|_we$|_ack$)", n):
                L.append(f"      {pre}_{n} <= ($urandom_range(0,7)==0);")
            elif re.search(r"ram_hold$", n):
                L.append(f"      {pre}_{n} <= ($urandom_range(0,15)==0);")
            elif re.search(r"(bypass|bp_clken|aux_clk|aux_ckbp|mcp_hold)$", n):
                L.append(f"      {pre}_{n} <= 1'b0;")
            elif w <= 32:
                L.append(f"      {pre}_{n} <= {w}'($urandom);")
            else:
                rep = (w + 31) // 32
                rnd = "{" + ", ".join(["$urandom()"] * rep) + "}"
                L.append(f"      {pre}_{n} <= {w}'({rnd});")
        L.append("    end")
        L.append("  end")
        L.append("  always @(negedge clk) if (!rst && cycle > WARMUP) begin")
        L.append("    #4; checks++;")
        for w, n in outs:
            L.append(f"    if ({pre}_g_{n} !== {pre}_i_{n}) begin errors++;")
            L.append(f"      $display(\"[%0t] {nm}.{n} g=%h i=%h\", $time, {pre}_g_{n}, {pre}_i_{n}); end")
        L.append("  end")
        L.append("")
    L.append("""  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 40000;
    $fsdbDumpfile("novas.fsdb"); $fsdbDumpvars(0, tb);
    rst = 1; repeat (5) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("---------------------------------------------");
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    return "\n".join(L)


def main():
    infos, skipped = [], []
    for v in VARIANTS:
        info = analyze(v)
        if info["supported"]:
            infos.append(info)
        else:
            skipped.append(v)

    hdr = "// 自动生成：scripts/gen_sram_wrappers.py —— 勿手改\n"
    note = ("// 变体包装层：例化 xs_SRAMTemplate_core + 厂商 SRAM 宏黑盒\n")
    (XSSV / "rtl/common/SRAMTemplate_variants.sv").write_text(
        hdr + note + "\n".join(emit_wrapper(i) for i in infos))
    ut = XSSV / "verif/ut/SRAMTemplate"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(
        hdr + "\n".join(emit_wrapper(i, "_xs") for i in infos))
    (ut / "tb.sv").write_text(emit_tb(infos))

    # 宏链依赖（UT 需 array_ext.v；FM 不读 ext）
    sim_deps, fm_deps = set(), set()
    fm_ref = {}
    for i in infos:
        sim_deps |= {i["macro"] + ".sv", i["child"] + ".sv", i["ext"] + ".v"}
        fm_deps |= {i["macro"] + ".sv", i["child"] + ".sv"}
        deps = [i["macro"] + ".sv", i["child"] + ".sv"]
        if i["clockgate"]:
            deps += ["MbistClockGateCell.sv", "ClockGate.sv"]
            fm_deps |= {"MbistClockGateCell.sv", "ClockGate.sv"}
            sim_deps |= {"MbistClockGateCell.sv", "ClockGate.sv"}
        fm_ref[i["name"]] = deps
    mk = ["# 自动生成：scripts/gen_sram_wrappers.py"]
    mk.append("SRAM_VARIANTS = " + " ".join(i["name"] for i in infos))
    mk.append("MACRO_SIM = " + " ".join(f"$(GOLDEN_RTL)/{d}" for d in sorted(sim_deps)))
    mk.append("MACRO_FM  = " + " ".join(f"$(GOLDEN_RTL)/{d}" for d in sorted(fm_deps)))
    for i in infos:
        mk.append(f"FM_REF_DEPS_{i['name']} = " + " ".join(fm_ref[i['name']]))
    (ut / "sram_deps.mk").write_text("\n".join(mk) + "\n")

    print(f"covered {len(infos)} variants: {', '.join(i['name'] for i in infos)}")
    for i in infos:
        print(f"  {i['name']}: set={i['set']} way={i['way']} dw={i['data_w']} "
              f"reset={int(i['reset'])} hold={int(i['hold'])} cg={int(i['clockgate'])} "
              f"ready={int(i['has_ready'])} wmask={int(i['has_waymask'])} macro={i['macro']}")
    if skipped:
        print(f"SKIPPED (不支持的形态): {', '.join(skipped)}")


if __name__ == "__main__":
    main()
