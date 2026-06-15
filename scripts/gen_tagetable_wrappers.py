#!/usr/bin/env python3
# 生成 TageTable 4 变体的 golden 同名 wrapper（FM impl）+ _xs 副本（UT），
# 例化可读核 xs_TageTable_core。每变体仅 HIST_LEN 与折叠历史端口映射不同。
import re, pathlib
GOLD = pathlib.Path("golden/chisel-rtl")
RTL  = pathlib.Path("rtl/frontend")
UT   = pathlib.Path("verif/ut/TageTable")

# 变体 → (HIST_LEN, idx_fh 的 hist_N, tag_fh 的 hist_N, alt_fh 的 hist_N)
VARIANTS = {
    "TageTable":   (8,   14, 14, 7),
    "TageTable_1": (13,   1,  4, 15),
    "TageTable_2": (32,  17,  3, 9),
    "TageTable_3": (119, 16,  8, 5),
}

def port_decls(name):
    txt = (GOLD/f"{name}.sv").read_text()
    hdr = txt[txt.index(f"module {name}("):]
    hdr = hdr[:hdr.index(");")]
    out = []
    for m in re.finditer(r"(input|output)\s+(\[[0-9]+:0\])?\s*([A-Za-z_][A-Za-z0-9_]*)", hdr):
        out.append((m.group(1), m.group(2) or "", m.group(3)))
    return out

def emit(name, modname):
    H, idxN, tagN, altN = VARIANTS[name]
    decls = port_decls(name)
    lines = [f"module {modname}("]
    lines.append(",\n".join(f"  {d} {w+' ' if w else ''}{n}".rstrip() for d,w,n in decls))
    lines.append(");")
    # 折叠历史端口名
    idx_p = f"io_req_bits_folded_hist_hist_{idxN}_folded_hist"
    tag_p = f"io_req_bits_folded_hist_hist_{tagN}_folded_hist"
    alt_p = f"io_req_bits_folded_hist_hist_{altN}_folded_hist"
    # bore_bank / sig_bank 中转数组（bore_1..4 → [0..3]）
    lines += [
        "  // ---- bore_bank/sig_bank 打包（golden bore_1..4 → 数组 [0..3]）----",
        "  wire [9:0]  bb_addr [4], bb_addr_rd [4];",
        "  wire [23:0] bb_wdata [4];",
        "  wire [1:0]  bb_wmask [4];",
        "  wire        bb_re [4], bb_we [4], bb_ack [4], bb_sel [4];",
        "  wire [23:0] bb_rdata [4];",
        "  wire [5:0]  bb_array [4];",
        "  wire [6:0]  sig_bk [4];",
    ]
    for i in range(4):
        g = f"boreChildrenBd_bore_{i+1}"
        s = f"sigFromSrams_bore_{i+1}"
        lines += [
          f"  assign bb_addr[{i}]={g}_addr;    assign bb_addr_rd[{i}]={g}_addr_rd;",
          f"  assign bb_wdata[{i}]={g}_wdata;  assign bb_wmask[{i}]={g}_wmask;",
          f"  assign bb_re[{i}]={g}_re;        assign bb_we[{i}]={g}_we;",
          f"  assign bb_ack[{i}]={g}_ack;      assign bb_sel[{i}]={g}_selectedOH;",
          f"  assign bb_array[{i}]={g}_array;",
          f"  assign {g}_rdata=bb_rdata[{i}];",
          f"  assign sig_bk[{i}]={{{s}_cgen,{s}_ram_mcp_hold,{s}_ram_aux_ckbp,{s}_ram_aux_clk,{s}_ram_bp_clken,{s}_ram_bypass,{s}_ram_hold}};",
        ]
    lines += [
        f"  xs_TageTable_core #(.HIST_LEN({H})) u_core (",
        "    .clock(clock), .reset(reset),",
        "    .io_req_ready(io_req_ready), .io_req_valid(io_req_valid),",
        "    .io_req_bits_pc(io_req_bits_pc), .io_req_bits_ghist(io_req_bits_ghist),",
        f"    .io_req_idx_fh({idx_p}), .io_req_tag_fh({tag_p}), .io_req_alt_fh({alt_p}),",
        "    .io_resps_0_valid(io_resps_0_valid), .io_resps_0_bits_ctr(io_resps_0_bits_ctr),",
        "    .io_resps_0_bits_u(io_resps_0_bits_u), .io_resps_0_bits_unconf(io_resps_0_bits_unconf),",
        "    .io_resps_1_valid(io_resps_1_valid), .io_resps_1_bits_ctr(io_resps_1_bits_ctr),",
        "    .io_resps_1_bits_u(io_resps_1_bits_u), .io_resps_1_bits_unconf(io_resps_1_bits_unconf),",
        "    .io_update_pc(io_update_pc), .io_update_ghist(io_update_ghist),",
        "    .io_update_mask_0(io_update_mask_0), .io_update_mask_1(io_update_mask_1),",
        "    .io_update_takens_0(io_update_takens_0), .io_update_takens_1(io_update_takens_1),",
        "    .io_update_alloc_0(io_update_alloc_0), .io_update_alloc_1(io_update_alloc_1),",
        "    .io_update_oldCtrs_0(io_update_oldCtrs_0), .io_update_oldCtrs_1(io_update_oldCtrs_1),",
        "    .io_update_uMask_0(io_update_uMask_0), .io_update_uMask_1(io_update_uMask_1),",
        "    .io_update_us_0(io_update_us_0), .io_update_us_1(io_update_us_1),",
        "    .io_update_reset_u_0(io_update_reset_u_0), .io_update_reset_u_1(io_update_reset_u_1),",
        "    .bore_us_addr(boreChildrenBd_bore_addr), .bore_us_addr_rd(boreChildrenBd_bore_addr_rd),",
        "    .bore_us_wdata(boreChildrenBd_bore_wdata), .bore_us_wmask(boreChildrenBd_bore_wmask),",
        "    .bore_us_re(boreChildrenBd_bore_re), .bore_us_we(boreChildrenBd_bore_we),",
        "    .bore_us_rdata(boreChildrenBd_bore_rdata), .bore_us_ack(boreChildrenBd_bore_ack),",
        "    .bore_us_selectedOH(boreChildrenBd_bore_selectedOH), .bore_us_array(boreChildrenBd_bore_array),",
        "    .bore_bank_addr(bb_addr), .bore_bank_addr_rd(bb_addr_rd),",
        "    .bore_bank_wdata(bb_wdata), .bore_bank_wmask(bb_wmask),",
        "    .bore_bank_re(bb_re), .bore_bank_we(bb_we), .bore_bank_rdata(bb_rdata),",
        "    .bore_bank_ack(bb_ack), .bore_bank_selectedOH(bb_sel), .bore_bank_array(bb_array),",
        "    .sig_us({sigFromSrams_bore_cgen,sigFromSrams_bore_ram_mcp_hold,sigFromSrams_bore_ram_aux_ckbp,sigFromSrams_bore_ram_aux_clk,sigFromSrams_bore_ram_bp_clken,sigFromSrams_bore_ram_bypass,sigFromSrams_bore_ram_hold}),",
        "    .sig_bank(sig_bk)",
        "  );",
        "endmodule",
    ]
    return "\n".join(lines)

hdr = "// 自动生成：scripts/gen_tagetable_wrappers.py —— 例化 xs_TageTable_core\n"
RTL.mkdir(parents=True, exist_ok=True); UT.mkdir(parents=True, exist_ok=True)
(RTL/"TageTable_wrapper.sv").write_text(hdr + "\n\n".join(emit(v, v) for v in VARIANTS))
(UT/"variants_xs.sv").write_text(hdr + "\n\n".join(emit(v, v+"_xs") for v in VARIANTS))
print("generated wrappers + _xs for", ", ".join(VARIANTS))

# ---- 通用 tb：驱动所有 input、比对所有 output，4 变体同跑 ----
import re as _re
def emit_tb():
    L = ["// 自动生成：scripts/gen_tagetable_wrappers.py", "`timescale 1ns/1ps", "module tb;",
         "  int unsigned NCYCLES=40000; localparam int WARMUP=400;",
         "  bit clk=0,rst; int errors=0,checks=0; int unsigned cycle=0;",
         "  always #5 clk=~clk;  always @(posedge clk) cycle++;"]
    insts=[]
    for v in VARIANTS:
        decls=port_decls(v); pre="v"+v.replace("TageTable","T")
        ins=[(w,n) for d,w,n in decls if d=="input" and n not in("clock","reset")]
        outs=[(w,n) for d,w,n in decls if d=="output"]
        for w,n in ins:  L.append(f"  logic {w+' ' if w else ''}{pre}_{n};")
        for w,n in outs: L.append(f"  wire {w+' ' if w else ''}{pre}_g_{n}; wire {w+' ' if w else ''}{pre}_i_{n};")
        gc=[".clock(clk)",".reset(rst)"]+[f".{n}({pre}_{n})" for _,n in ins]
        L.append(f"  {v}    u_g_{v}({', '.join(gc+[f'.{n}({pre}_g_{n})' for _,n in outs])});")
        L.append(f"  {v}_xs u_i_{v}({', '.join(gc+[f'.{n}({pre}_i_{n})' for _,n in outs])});")
        # 驱动
        L.append("  always @(negedge clk) begin")
        L.append("    if (rst) begin")
        for w,n in ins:
            if _re.search(r"(req_valid|update_mask|_re$|_we$|_ack$)",n): L.append(f"      {pre}_{n}<=1'b0;")
        L.append("    end else begin")
        for w,n in ins:
            wid=int(w[1:-3])+1 if w else 1
            if _re.search(r"req_valid$",n): L.append(f"      {pre}_{n}<=($urandom_range(0,3)!=0);")
            elif _re.search(r"update_mask",n): L.append(f"      {pre}_{n}<=($urandom_range(0,2)==0);")
            elif _re.search(r"(_re$|_we$|_ack$)",n): L.append(f"      {pre}_{n}<=($urandom_range(0,7)==0);")
            elif _re.search(r"(ram_hold|ram_bypass|bp_clken|aux_clk|aux_ckbp|mcp_hold|cgen)$",n): L.append(f"      {pre}_{n}<=1'b0;")
            elif wid<=32: L.append(f"      {pre}_{n}<={wid}'($urandom);")
            else:
                rep=(wid+31)//32; L.append(f"      {pre}_{n}<={wid}'({{{', '.join(['$urandom']*rep)}}});")
        L.append("    end")
        L.append("  end")
        L.append("  always @(negedge clk) if(!rst&&cycle>WARMUP) begin #4; checks++;")
        for w,n in outs:
            L.append(f"    if (!$isunknown({pre}_g_{n}) && {pre}_g_{n}!=={pre}_i_{n}) begin errors++; if(errors<=30) $display(\"[%0t] {v}.{n} g=%h i=%h\",$time,{pre}_g_{n},{pre}_i_{n}); end")
        L.append("  end")
    L+=["  initial begin",
        "    if(!$value$plusargs(\"ncycles=%d\",NCYCLES)) NCYCLES=40000;",
        "    rst=1; repeat(5)@(posedge clk); rst=0; repeat(NCYCLES)@(posedge clk);",
        "    $display(\"checks=%0d errors=%0d\",checks,errors);",
        "    if(errors==0&&checks>1000) $display(\"TEST PASSED\"); else $display(\"TEST FAILED\");",
        "    $finish; end","endmodule"]
    (UT/"tb.sv").write_text("\n".join(L))
    print("generated tb.sv")
emit_tb()
