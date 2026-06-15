#!/usr/bin/env python3
# 生成 ITTageTable 5 变体的 golden 同名 wrapper（FM impl）+ _xs 副本（UT），
# 例化可读核 xs_ITTageTable_core + xs_MbistPipeIttage_core + 变体专属黑盒
# (FoldedSRAMTemplate_21/_23, WrBypass_41/_43)。
import re, pathlib
GOLD = pathlib.Path("golden/chisel-rtl")
RTL  = pathlib.Path("rtl/frontend")
UT   = pathlib.Path("verif/ut/ITTageTable")

# 变体配置：
#  IDX_W, idx_fh(N,W), tag_fh(N,W), alt_fh(N,W),
#  IDX_HIST, TAG_HIST, ALT_HIST, SRAM 模块, WrBypass 模块, N_SRAM, ARRAY_ID0
# 折叠历史端口名 hist_N 与位宽 W 来自 golden 端口声明。
VARIANTS = {
  # name          IDX  idxfh    tagfh    altfh    ihL thL ahL   SRAM                    WrB           N  AID0
  "ITTageTable":  (8, (12,4), (12,4), (12,4),     4,  4,  4, "FoldedSRAMTemplate_21","WrBypass_41", 1, 0x46),
  "ITTageTable_1":(8, (14,8), (14,8), (14,8),     8,  8,  8, "FoldedSRAMTemplate_21","WrBypass_42", 1, 0x47),
  "ITTageTable_2":(9, (13,9), (13,9), ( 4,8),    13, 13, 13, "FoldedSRAMTemplate_23","WrBypass_43", 2, 0x48),
  "ITTageTable_3":(9, ( 6,9), ( 6,9), ( 2,8),    16, 16, 16, "FoldedSRAMTemplate_23","WrBypass_43", 2, 0x4A),
  "ITTageTable_4":(9, (10,9), (10,9), ( 3,8),    32, 32, 32, "FoldedSRAMTemplate_23","WrBypass_43", 2, 0x4C),
}

def port_decls(name):
    txt = (GOLD/f"{name}.sv").read_text()
    hdr = txt[txt.index(f"module {name}("):]
    hdr = hdr[:hdr.index(");")]
    out = []
    for m in re.finditer(r"(input|output)\s+(\[[0-9]+:0\])?\s*([A-Za-z_][A-Za-z0-9_]*)", hdr):
        out.append((m.group(1), m.group(2) or "", m.group(3)))
    return out

# wrbypass 模块 41 用 8 位 idx，43 用 9 位 idx —— 但 var1 golden 实际是 WrBypass_42。
# 检查 golden 各变体真实例化的 WrBypass 名，覆盖配置中可能的笔误。
def real_wrb(name):
    txt = (GOLD/f"{name}.sv").read_text()
    m = re.search(r"(WrBypass_\d+) wrbypass", txt)
    return m.group(1) if m else None
def real_sram(name):
    txt = (GOLD/f"{name}.sv").read_text()
    m = re.search(r"(FoldedSRAMTemplate_\d+) table_0", txt)
    return m.group(1) if m else None
def real_mbist(name):
    txt = (GOLD/f"{name}.sv").read_text()
    m = re.search(r"(MbistPipeIttage\w*) mbistPl", txt)
    return m.group(1) if m else None

def emit(name, modname):
    IDX, idxfh, tagfh, altfh, ihL, thL, ahL, _sram, _wrb, NS, AID0 = VARIANTS[name]
    sram = real_sram(name); wrb = real_wrb(name)
    idx_p = f"io_req_bits_folded_hist_hist_{idxfh[0]}_folded_hist"
    tag_p = f"io_req_bits_folded_hist_hist_{tagfh[0]}_folded_hist"
    alt_p = f"io_req_bits_folded_hist_hist_{altfh[0]}_folded_hist"
    IDXFH_W, TAGFH_W, ALTFH_W = idxfh[1], tagfh[1], altfh[1]
    decls = port_decls(name)

    L = [f"module {modname}("]
    L.append(",\n".join(f"  {d} {w+' ' if w else ''}{n}".rstrip() for d,w,n in decls))
    L.append(");")

    # ---- 核 <-> SRAM 中间线 ----
    L += [
      "  // ===== 核 <-> 条目 SRAM 读/写口 中间线 =====",
      f"  wire                sram_r_req_valid;",
      f"  wire [{IDX-1}:0]    sram_r_req_setIdx;",
      f"  wire                sram_r_req_ready;",
      f"  wire                sram_r_resp_valid;",
      f"  wire [8:0]          sram_r_resp_tag;",
      f"  wire [1:0]          sram_r_resp_ctr;",
      f"  wire [19:0]         sram_r_resp_off;",
      f"  wire [3:0]          sram_r_resp_ptr;",
      f"  wire                sram_r_resp_upr;",
      f"  wire                sram_r_resp_useful;",
      f"  wire                sram_w_req_valid;",
      f"  wire [{IDX-1}:0]    sram_w_req_setIdx;",
      f"  wire [8:0]          sram_w_req_tag;",
      f"  wire [1:0]          sram_w_req_ctr;",
      f"  wire [19:0]         sram_w_req_off;",
      f"  wire [3:0]          sram_w_req_ptr;",
      f"  wire                sram_w_req_upr;",
      f"  wire                sram_w_req_useful;",
      f"  wire [37:0]         sram_w_req_bitmask;",
      "  // ===== 核 <-> WrBypass 中间线 =====",
      f"  wire                wrbp_wen;",
      f"  wire [{IDX-1}:0]    wrbp_write_idx;",
      f"  wire [1:0]          wrbp_write_data;",
      f"  wire                wrbp_hit;",
      f"  wire [1:0]          wrbp_hit_data;",
      "  // ===== MbistPipe <-> SRAM bore 口 中间线 =====",
    ]
    for k in range(NS):
        L += [
          f"  wire [7:0]  childBd{k}_addr, childBd{k}_addr_rd;",
          f"  wire [75:0] childBd{k}_wdata, childBd{k}_wmask, childBd{k}_rdata;",
          f"  wire        childBd{k}_re, childBd{k}_we, childBd{k}_ack, childBd{k}_sel;",
          f"  wire [6:0]  childBd{k}_array;",
        ]

    # ---- 可读核例化 ----
    L += [
      "  // ===== 可读功能核 =====",
      f"  xs_ITTageTable_core #(",
      f"    .IDX_W({IDX}), .IDX_FH_W({IDXFH_W}), .TAG_FH_W({TAGFH_W}), .ALT_FH_W({ALTFH_W}),",
      f"    .IDX_HIST_LEN({ihL}), .TAG_HIST_LEN({thL}), .ALT_HIST_LEN({ahL})",
      "  ) u_core (",
      "    .clock(clock), .reset(reset),",
      "    .io_req_ready(io_req_ready), .io_req_valid(io_req_valid),",
      "    .io_req_bits_pc(io_req_bits_pc),",
      f"    .io_req_idx_fh({idx_p}), .io_req_tag_fh({tag_p}), .io_req_alt_fh({alt_p}),",
      "    .io_resp_valid(io_resp_valid), .io_resp_bits_ctr(io_resp_bits_ctr),",
      "    .io_resp_bits_u(io_resp_bits_u),",
      "    .io_resp_bits_target_offset_offset(io_resp_bits_target_offset_offset),",
      "    .io_resp_bits_target_offset_pointer(io_resp_bits_target_offset_pointer),",
      "    .io_resp_bits_target_offset_usePCRegion(io_resp_bits_target_offset_usePCRegion),",
      "    .io_update_pc(io_update_pc), .io_update_ghist(io_update_ghist),",
      "    .io_update_valid(io_update_valid), .io_update_correct(io_update_correct),",
      "    .io_update_alloc(io_update_alloc), .io_update_oldCtr(io_update_oldCtr),",
      "    .io_update_uValid(io_update_uValid), .io_update_u(io_update_u),",
      "    .io_update_reset_u(io_update_reset_u),",
      "    .io_update_target_offset_offset(io_update_target_offset_offset),",
      "    .io_update_target_offset_pointer(io_update_target_offset_pointer),",
      "    .io_update_target_offset_usePCRegion(io_update_target_offset_usePCRegion),",
      "    .io_update_old_target_offset_offset(io_update_old_target_offset_offset),",
      "    .io_update_old_target_offset_pointer(io_update_old_target_offset_pointer),",
      "    .io_update_old_target_offset_usePCRegion(io_update_old_target_offset_usePCRegion),",
      "    .sram_r_req_valid(sram_r_req_valid), .sram_r_req_setIdx(sram_r_req_setIdx),",
      "    .sram_r_req_ready(sram_r_req_ready), .sram_r_resp_valid(sram_r_resp_valid),",
      "    .sram_r_resp_tag(sram_r_resp_tag), .sram_r_resp_ctr(sram_r_resp_ctr),",
      "    .sram_r_resp_target_offset_offset(sram_r_resp_off),",
      "    .sram_r_resp_target_offset_pointer(sram_r_resp_ptr),",
      "    .sram_r_resp_target_offset_usePCRegion(sram_r_resp_upr),",
      "    .sram_r_resp_useful(sram_r_resp_useful),",
      "    .sram_w_req_valid(sram_w_req_valid), .sram_w_req_setIdx(sram_w_req_setIdx),",
      "    .sram_w_req_tag(sram_w_req_tag), .sram_w_req_ctr(sram_w_req_ctr),",
      "    .sram_w_req_target_offset_offset(sram_w_req_off),",
      "    .sram_w_req_target_offset_pointer(sram_w_req_ptr),",
      "    .sram_w_req_target_offset_usePCRegion(sram_w_req_upr),",
      "    .sram_w_req_useful(sram_w_req_useful), .sram_w_req_bitmask(sram_w_req_bitmask),",
      "    .wrbp_wen(wrbp_wen), .wrbp_write_idx(wrbp_write_idx),",
      "    .wrbp_write_data(wrbp_write_data),",
      "    .wrbp_hit(wrbp_hit), .wrbp_hit_data(wrbp_hit_data)",
      "  );",
    ]

    # ---- 条目 SRAM 黑盒例化 ----
    sig0 = ("    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),\n"
            "    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),\n"
            "    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),\n"
            "    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),\n"
            "    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),\n"
            "    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),\n"
            "    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen)")
    sig1 = ("    .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_1_ram_hold),\n"
            "    .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_1_ram_bypass),\n"
            "    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken),\n"
            "    .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk),\n"
            "    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp),\n"
            "    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold),\n"
            "    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen)")
    L += [
      "  // ===== 条目 SRAM（已验证黑盒）=====",
      f"  {sram} table_0 (",
      "    .clock(clock), .reset(reset),",
      "    .io_r_req_ready(sram_r_req_ready), .io_r_req_valid(sram_r_req_valid),",
      "    .io_r_req_bits_setIdx(sram_r_req_setIdx),",
      "    .io_r_resp_data_0_valid(sram_r_resp_valid),",
      "    .io_r_resp_data_0_tag(sram_r_resp_tag),",
      "    .io_r_resp_data_0_ctr(sram_r_resp_ctr),",
      "    .io_r_resp_data_0_target_offset_offset(sram_r_resp_off),",
      "    .io_r_resp_data_0_target_offset_pointer(sram_r_resp_ptr),",
      "    .io_r_resp_data_0_target_offset_usePCRegion(sram_r_resp_upr),",
      "    .io_r_resp_data_0_useful(sram_r_resp_useful),",
      "    .io_w_req_valid(sram_w_req_valid), .io_w_req_bits_setIdx(sram_w_req_setIdx),",
      "    .io_w_req_bits_data_0_tag(sram_w_req_tag),",
      "    .io_w_req_bits_data_0_ctr(sram_w_req_ctr),",
      "    .io_w_req_bits_data_0_target_offset_offset(sram_w_req_off),",
      "    .io_w_req_bits_data_0_target_offset_pointer(sram_w_req_ptr),",
      "    .io_w_req_bits_data_0_target_offset_usePCRegion(sram_w_req_upr),",
      "    .io_w_req_bits_data_0_useful(sram_w_req_useful),",
      "    .io_w_req_bits_bitmask(sram_w_req_bitmask),",
      "    .boreChildrenBd_bore_addr(childBd0_addr),",
      "    .boreChildrenBd_bore_addr_rd(childBd0_addr_rd),",
      "    .boreChildrenBd_bore_wdata(childBd0_wdata),",
      "    .boreChildrenBd_bore_wmask(childBd0_wmask),",
      "    .boreChildrenBd_bore_re(childBd0_re), .boreChildrenBd_bore_we(childBd0_we),",
      "    .boreChildrenBd_bore_rdata(childBd0_rdata),",
      "    .boreChildrenBd_bore_ack(childBd0_ack),",
      "    .boreChildrenBd_bore_selectedOH(childBd0_sel),",
      "    .boreChildrenBd_bore_array(childBd0_array),",
    ]
    if NS == 2:
        L += [
          "    .boreChildrenBd_bore_1_addr(childBd1_addr),",
          "    .boreChildrenBd_bore_1_addr_rd(childBd1_addr_rd),",
          "    .boreChildrenBd_bore_1_wdata(childBd1_wdata),",
          "    .boreChildrenBd_bore_1_wmask(childBd1_wmask),",
          "    .boreChildrenBd_bore_1_re(childBd1_re), .boreChildrenBd_bore_1_we(childBd1_we),",
          "    .boreChildrenBd_bore_1_rdata(childBd1_rdata),",
          "    .boreChildrenBd_bore_1_ack(childBd1_ack),",
          "    .boreChildrenBd_bore_1_selectedOH(childBd1_sel),",
          "    .boreChildrenBd_bore_1_array(childBd1_array),",
          sig0 + ",",
          sig1,
        ]
    else:
        L += [sig0]
    L.append("  );")

    # ---- WrBypass 黑盒 ----
    L += [
      "  // ===== WrBypass（已验证黑盒）=====",
      f"  {wrb} wrbypass (",
      "    .clock(clock), .reset(reset),",
      "    .io_wen(wrbp_wen), .io_write_idx(wrbp_write_idx),",
      "    .io_write_data_0(wrbp_write_data),",
      "    .io_hit(wrbp_hit), .io_hit_data_0_bits(wrbp_hit_data)",
      "  );",
    ]

    # ---- MBIST 可读核 ----
    # toSRAM 数组打平到 childBdk_*
    arr = lambda f: "'{" + ", ".join(f"childBd{k}_{f}" for k in range(NS)) + "}"
    L += [
      "  // ===== MBIST 流水寄存（可读核；上游 mbist 总线 -> SRAM bore 口）=====",
      f"  wire [7:0]  ms_addr   [{NS}], ms_addr_rd [{NS}];",
      f"  wire [75:0] ms_wdata  [{NS}], ms_wmask   [{NS}], ms_rdata [{NS}];",
      f"  wire        ms_re     [{NS}], ms_we      [{NS}], ms_ack [{NS}], ms_sel [{NS}];",
      f"  wire [6:0]  ms_array  [{NS}];",
    ]
    for k in range(NS):
        L += [
          f"  assign childBd{k}_addr=ms_addr[{k}];       assign childBd{k}_addr_rd=ms_addr_rd[{k}];",
          f"  assign childBd{k}_wdata=ms_wdata[{k}];     assign childBd{k}_wmask=ms_wmask[{k}];",
          f"  assign childBd{k}_re=ms_re[{k}];           assign childBd{k}_we=ms_we[{k}];",
          f"  assign childBd{k}_ack=ms_ack[{k}];         assign childBd{k}_sel=ms_sel[{k}];",
          f"  assign childBd{k}_array=ms_array[{k}];     assign ms_rdata[{k}]=childBd{k}_rdata;",
        ]
    L += [
      f"  xs_MbistPipeIttage_core #(.N_SRAM({NS}), .ARRAY_ID0(7'h{AID0:02X}), .ADDR_W(8), .DATA_W(76)) mbistPl (",
      "    .clock(clock), .reset(reset),",
      "    .mbist_array(boreChildrenBd_bore_array), .mbist_all(boreChildrenBd_bore_all),",
      "    .mbist_req(boreChildrenBd_bore_req), .mbist_ack(boreChildrenBd_bore_ack),",
      "    .mbist_writeen(boreChildrenBd_bore_writeen), .mbist_be(boreChildrenBd_bore_be),",
      "    .mbist_addr(boreChildrenBd_bore_addr), .mbist_indata(boreChildrenBd_bore_indata),",
      "    .mbist_readen(boreChildrenBd_bore_readen), .mbist_addr_rd(boreChildrenBd_bore_addr_rd),",
      "    .mbist_outdata(boreChildrenBd_bore_outdata),",
      f"    .toSRAM_addr(ms_addr), .toSRAM_addr_rd(ms_addr_rd),",
      f"    .toSRAM_wdata(ms_wdata), .toSRAM_wmask(ms_wmask),",
      f"    .toSRAM_re(ms_re), .toSRAM_we(ms_we), .toSRAM_rdata(ms_rdata),",
      f"    .toSRAM_ack(ms_ack), .toSRAM_selectedOH(ms_sel), .toSRAM_array(ms_array)",
      "  );",
      "endmodule",
    ]
    return "\n".join(L)

hdr = "// 自动生成：scripts/gen_ittagetable_wrappers.py —— 例化 xs_ITTageTable_core + 变体专属黑盒\n"
RTL.mkdir(parents=True, exist_ok=True); UT.mkdir(parents=True, exist_ok=True)
(RTL/"ITTageTable_wrapper.sv").write_text(hdr + "\n\n".join(emit(v, v) for v in VARIANTS))
(UT/"variants_xs.sv").write_text(hdr + "\n\n".join(emit(v, v+"_xs") for v in VARIANTS))
print("generated wrappers + _xs for", ", ".join(VARIANTS))

# ---- 通用 tb：驱动所有 input、比对所有 output，5 变体同跑 ----
def emit_tb():
    L = ["// 自动生成：scripts/gen_ittagetable_wrappers.py", "`timescale 1ns/1ps", "module tb;",
         "  int unsigned NCYCLES=40000; localparam int WARMUP=4000;",
         "  bit clk=0,rst; int errors=0,checks=0; int unsigned cycle=0;",
         "  always #5 clk=~clk;  always @(posedge clk) cycle++;"]
    for v in VARIANTS:
        decls=port_decls(v); pre="v"+v.replace("ITTageTable","T")
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
            if re.search(r"(req_valid|update_valid|_re$|_we$|_ack$|_req$|_all$|_writeen$|_readen$|_reset_u$)",n):
                L.append(f"      {pre}_{n}<=1'b0;")
        L.append("    end else begin")
        for w,n in ins:
            wid=int(w[1:-3])+1 if w else 1
            if re.search(r"req_valid$",n):       L.append(f"      {pre}_{n}<=($urandom_range(0,3)!=0);")
            elif re.search(r"update_valid$",n):  L.append(f"      {pre}_{n}<=($urandom_range(0,2)==0);")
            elif re.search(r"reset_u$",n):       L.append(f"      {pre}_{n}<=($urandom_range(0,63)==0);")
            elif re.search(r"(_re$|_we$|_ack$|_req$|_all$|_writeen$|_readen$)",n):
                                                 L.append(f"      {pre}_{n}<=($urandom_range(0,7)==0);")
            elif re.search(r"(ram_hold|ram_bypass|bp_clken|aux_clk|aux_ckbp|mcp_hold|cgen)$",n):
                                                 L.append(f"      {pre}_{n}<=1'b0;")
            elif wid<=32: L.append(f"      {pre}_{n}<={wid}'($urandom);")
            else:
                rep=(wid+31)//32; L.append(f"      {pre}_{n}<={wid}'({{{', '.join(['$urandom']*rep)}}});")
        L.append("    end")
        L.append("  end")
        L.append("  always @(negedge clk) if(!rst&&cycle>WARMUP) begin #4; checks++;")
        for w,n in outs:
            L.append(f"    if ({pre}_g_{n}!=={pre}_i_{n}) begin errors++; if(errors<=40) $display(\"[%0t] {v}.{n} g=%h i=%h\",$time,{pre}_g_{n},{pre}_i_{n}); end")
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
