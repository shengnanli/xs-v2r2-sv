#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
生成 ICacheDataArray 的 wrapper（golden 同名）与 UT 变体（_xs）。
wrapper 是机械的端口适配 + 黑盒例化层：
  · 把 golden 扁平端口拆成可读核 xs_ICacheDataArray 的 struct/数组端口；
  · 例化 32 块 golden 数据 SRAM（SRAMTemplateWithFixedWidth{,_4,_12,_28}）黑盒；
  · 例化 4 条 golden Mbist 流水（MbistPipeIcacheDataWay{0..3}）黑盒；
  · 完成 Mbist toSRAM_n <-> SRAM boreChildrenBd_bore 的 DFT 互联。
SRAM/Mbist 的存储体与 DFT 细节均不在可读重写范围内，故沿用 golden。
"""
import sys

NUM_WAYS = 4
NUM_BANKS = 8

# 各 (way,bank) 对应的 golden SRAM 变体名（接口一致，仅 array 宽度/物理宏不同）。
SRAM_VARIANT = [
    # way0
    ["SRAMTemplateWithFixedWidth"]*4 + ["SRAMTemplateWithFixedWidth_4"]*4,
    # way1
    ["SRAMTemplateWithFixedWidth_4"]*4 + ["SRAMTemplateWithFixedWidth_12"]*4,
    # way2
    ["SRAMTemplateWithFixedWidth_12"]*8,
    # way3
    ["SRAMTemplateWithFixedWidth_12"]*4 + ["SRAMTemplateWithFixedWidth_28"]*4,
]
# 各 (way,bank) SRAM 的 array 端口宽度（= 对应 Mbist toSRAM_n_array 宽度）
ARRAY_W = [
    [3,3,3,3,4,4,4,4],
    [4,4,4,4,5,5,5,5],
    [5,5,5,5,5,5,5,5],
    [5,5,5,5,6,6,6,6],
]
# 顶层 boreChildrenBd_bore{,_1,_2,_3} 的 array 宽度（每 way 一组，= mbist_array 宽度）
TOP_BD_ARRAY_W = [4, 5, 5, 6]


def header(module_name):
    return f"""// =============================================================================
// {module_name} —— ICacheDataArray 包装层（机械端口适配 + 黑盒例化）
// -----------------------------------------------------------------------------
// 本文件由 scripts/gen_icachedata.py 生成。职责：
//   1) 把 golden 扁平端口（io_read_*, io_readResp_*, io_write_*）拆/拼成可读核
//      xs_ICacheDataArray 的数组端口；
//   2) 例化 4 路 × 8 bank = 32 块 golden 数据 SRAM 黑盒；
//   3) 例化 4 条 golden Mbist 流水黑盒，并完成 Mbist toSRAM_n <-> SRAM 的 DFT 互联；
//   4) 透传 sigFromSrams_bore_* / boreChildrenBd_bore_* 等 DFT 信号。
//   存储体与 DFT 细节沿用 golden（不在可读重写范围内），数据阵列逻辑在 u_core 内。
// =============================================================================
module {module_name}(
  input          clock,
  input          reset,
  // ---- 写口（refill 一整条 cacheline）----
  input          io_write_valid,
  input  [7:0]   io_write_bits_virIdx,
  input  [511:0] io_write_bits_data,
  input  [3:0]   io_write_bits_waymask,
  input          io_write_bits_poison,
  // ---- 读口 0：携带全部译码所需信息（其余端口仅 valid + vSetIdx）----
  input          io_read_0_valid,
  input  [7:0]   io_read_0_bits_vSetIdx_0,
  input  [7:0]   io_read_0_bits_vSetIdx_1,
  input          io_read_0_bits_waymask_0_0,
  input          io_read_0_bits_waymask_0_1,
  input          io_read_0_bits_waymask_0_2,
  input          io_read_0_bits_waymask_0_3,
  input          io_read_0_bits_waymask_1_0,
  input          io_read_0_bits_waymask_1_1,
  input          io_read_0_bits_waymask_1_2,
  input          io_read_0_bits_waymask_1_3,
  input  [5:0]   io_read_0_bits_blkOffset,
  input          io_read_1_valid,
  input  [7:0]   io_read_1_bits_vSetIdx_0,
  input  [7:0]   io_read_1_bits_vSetIdx_1,
  input          io_read_2_valid,
  input  [7:0]   io_read_2_bits_vSetIdx_0,
  input  [7:0]   io_read_2_bits_vSetIdx_1,
  output         io_read_3_ready,
  input          io_read_3_valid,
  input  [7:0]   io_read_3_bits_vSetIdx_0,
  input  [7:0]   io_read_3_bits_vSetIdx_1,
  // ---- 读结果：每 bank 一组 64bit 数据 + 1bit 校验码 ----
  output [63:0]  io_readResp_datas_0,
  output [63:0]  io_readResp_datas_1,
  output [63:0]  io_readResp_datas_2,
  output [63:0]  io_readResp_datas_3,
  output [63:0]  io_readResp_datas_4,
  output [63:0]  io_readResp_datas_5,
  output [63:0]  io_readResp_datas_6,
  output [63:0]  io_readResp_datas_7,
  output         io_readResp_codes_0,
  output         io_readResp_codes_1,
  output         io_readResp_codes_2,
  output         io_readResp_codes_3,
  output         io_readResp_codes_4,
  output         io_readResp_codes_5,
  output         io_readResp_codes_6,
  output         io_readResp_codes_7,
"""


def top_bd_ports():
    """顶层 Mbist boreChildrenBd_bore{,_1,_2,_3} 端口（每 way 一组）"""
    lines = []
    for w in range(NUM_WAYS):
        sfx = "" if w == 0 else f"_{w}"
        aw = TOP_BD_ARRAY_W[w]
        lines.append(f"  input  [{aw-1}:0]   boreChildrenBd_bore{sfx}_array,")
        lines.append(f"  input          boreChildrenBd_bore{sfx}_all,")
        lines.append(f"  input          boreChildrenBd_bore{sfx}_req,")
        lines.append(f"  output         boreChildrenBd_bore{sfx}_ack,")
        lines.append(f"  input          boreChildrenBd_bore{sfx}_writeen,")
        lines.append(f"  input          boreChildrenBd_bore{sfx}_be,")
        lines.append(f"  input  [8:0]   boreChildrenBd_bore{sfx}_addr,")
        lines.append(f"  input  [65:0]  boreChildrenBd_bore{sfx}_indata,")
        lines.append(f"  input          boreChildrenBd_bore{sfx}_readen,")
        lines.append(f"  input  [8:0]   boreChildrenBd_bore{sfx}_addr_rd,")
        lines.append(f"  output [65:0]  boreChildrenBd_bore{sfx}_outdata,")
    return "\n".join(lines)


def top_sig_ports():
    """每块 SRAM 一组 sigFromSrams_bore_<k>（k=0..31）"""
    SIGS = ["ram_hold", "ram_bypass", "ram_bp_clken", "ram_aux_clk",
            "ram_aux_ckbp", "ram_mcp_hold", "cgen"]
    lines = []
    for k in range(NUM_WAYS * NUM_BANKS):
        sfx = "" if k == 0 else f"_{k}"
        for i, s in enumerate(SIGS):
            comma = "," if not (k == NUM_WAYS*NUM_BANKS-1 and i == len(SIGS)-1) else ""
            lines.append(f"  input          sigFromSrams_bore{sfx}_{s}{comma}")
    return "\n".join(lines)


def body():
    L = []
    a = L.append
    a("  // -------------------------------------------------------------------------")
    a("  // 把扁平 read/write 端口聚合成可读核的数组端口")
    a("  // -------------------------------------------------------------------------")
    a("  logic                 read_valid   [7:0];")
    a("  logic [7:0]           read_vSetIdx [7:0][1:0];")
    a("  logic [3:0]           read_waymask [1:0];")
    a("  logic [63:0]          resp_datas   [7:0];")
    a("  logic                 resp_codes   [7:0];")
    a("")
    a("  // 仅读端口 0..3 有效，按 golden 接到 4 个外部读请求")
    a("  assign read_valid[0] = io_read_0_valid;")
    a("  assign read_valid[1] = io_read_1_valid;")
    a("  assign read_valid[2] = io_read_2_valid;")
    a("  assign read_valid[3] = io_read_3_valid;")
    a("  assign read_valid[4] = 1'b0;")
    a("  assign read_valid[5] = 1'b0;")
    a("  assign read_valid[6] = 1'b0;")
    a("  assign read_valid[7] = 1'b0;")
    a("")
    a("  // 两条行各自的组索引（[port][line]）")
    for p in range(4):
        a(f"  assign read_vSetIdx[{p}][0] = io_read_{p}_bits_vSetIdx_0;")
        a(f"  assign read_vSetIdx[{p}][1] = io_read_{p}_bits_vSetIdx_1;")
    for p in range(4, 8):
        a(f"  assign read_vSetIdx[{p}][0] = 8'b0;")
        a(f"  assign read_vSetIdx[{p}][1] = 8'b0;")
    a("")
    a("  // 命中掩码 [line][way]，全部取自读端口 0")
    a("  assign read_waymask[0] = {io_read_0_bits_waymask_0_3, io_read_0_bits_waymask_0_2,")
    a("                            io_read_0_bits_waymask_0_1, io_read_0_bits_waymask_0_0};")
    a("  assign read_waymask[1] = {io_read_0_bits_waymask_1_3, io_read_0_bits_waymask_1_2,")
    a("                            io_read_0_bits_waymask_1_1, io_read_0_bits_waymask_1_0};")
    a("")
    a("  // 可读核 <-> SRAM 黑盒之间的读写端口数组")
    a("  logic        sram_r_valid  [3:0][7:0];")
    a("  logic [7:0]  sram_r_setIdx [3:0][7:0];")
    a("  logic [64:0] sram_r_data   [3:0][7:0];")
    a("  logic        sram_w_valid  [3:0][7:0];")
    a("  logic [7:0]  sram_w_setIdx [3:0][7:0];")
    a("  logic [64:0] sram_w_data   [3:0][7:0];")
    a("")
    a("  // -------------------------------------------------------------------------")
    a("  // 可读核：数据阵列全部逻辑（bankSel/lineSel/masks/Mux1H/ECC 编码/写切分）")
    a("  // -------------------------------------------------------------------------")
    a("  xs_ICacheDataArray u_core (")
    a("    .clock          (clock),")
    a("    .reset          (reset),")
    a("    .write_valid    (io_write_valid),")
    a("    .write_virIdx   (io_write_bits_virIdx),")
    a("    .write_data     (io_write_bits_data),")
    a("    .write_waymask  (io_write_bits_waymask),")
    a("    .write_poison   (io_write_bits_poison),")
    a("    .read_valid     (read_valid),")
    a("    .read_vSetIdx   (read_vSetIdx),")
    a("    .read_waymask   (read_waymask),")
    a("    .read_blkOffset (io_read_0_bits_blkOffset),")
    a("    .read_ready     (io_read_3_ready),")
    a("    .resp_datas     (resp_datas),")
    a("    .resp_codes     (resp_codes),")
    a("    .sram_r_valid   (sram_r_valid),")
    a("    .sram_r_setIdx  (sram_r_setIdx),")
    a("    .sram_r_data    (sram_r_data),")
    a("    .sram_w_valid   (sram_w_valid),")
    a("    .sram_w_setIdx  (sram_w_setIdx),")
    a("    .sram_w_data    (sram_w_data)")
    a("  );")
    a("")
    a("  // 读结果回拼到扁平输出端口")
    for b in range(NUM_BANKS):
        a(f"  assign io_readResp_datas_{b} = resp_datas[{b}];")
    for b in range(NUM_BANKS):
        a(f"  assign io_readResp_codes_{b} = resp_codes[{b}];")
    a("")
    a("  // -------------------------------------------------------------------------")
    a("  // Mbist <-> SRAM DFT 互联网（childBd_<k>，k = way*8 + bank）")
    a("  // -------------------------------------------------------------------------")
    for k in range(NUM_WAYS * NUM_BANKS):
        w, b = k // NUM_BANKS, k % NUM_BANKS
        aw = ARRAY_W[w][b]
        sfx = "" if k == 0 else f"_{k}"
        a(f"  wire [8:0]  childBd{sfx}_addr;")
        a(f"  wire [8:0]  childBd{sfx}_addr_rd;")
        a(f"  wire [65:0] childBd{sfx}_wdata;")
        a(f"  wire        childBd{sfx}_wmask;")
        a(f"  wire        childBd{sfx}_re;")
        a(f"  wire        childBd{sfx}_we;")
        a(f"  wire [65:0] childBd{sfx}_rdata;")
        a(f"  wire        childBd{sfx}_ack;")
        a(f"  wire        childBd{sfx}_selectedOH;")
        a(f"  wire [{aw-1}:0]  childBd{sfx}_array;")
    a("")
    a("  // -------------------------------------------------------------------------")
    a("  // 32 块数据 SRAM 黑盒（golden 同名）")
    a("  // -------------------------------------------------------------------------")
    for w in range(NUM_WAYS):
        for b in range(NUM_BANKS):
            k = w*NUM_BANKS + b
            sfx = "" if k == 0 else f"_{k}"
            sig = "" if k == 0 else f"_{k}"
            variant = SRAM_VARIANT[w][b]
            a(f"  {variant} dataArrays_{w}_{b} (")
            a(f"    .clock                          (clock),")
            a(f"    .reset                          (reset),")
            a(f"    .io_r_req_valid                 (sram_r_valid[{w}][{b}]),")
            a(f"    .io_r_req_bits_setIdx           (sram_r_setIdx[{w}][{b}]),")
            a(f"    .io_r_resp_data_0               (sram_r_data[{w}][{b}]),")
            a(f"    .io_w_req_valid                 (sram_w_valid[{w}][{b}]),")
            a(f"    .io_w_req_bits_setIdx           (sram_w_setIdx[{w}][{b}]),")
            a(f"    .io_w_req_bits_data_0           (sram_w_data[{w}][{b}]),")
            a(f"    .boreChildrenBd_bore_addr       (childBd{sfx}_addr),")
            a(f"    .boreChildrenBd_bore_addr_rd    (childBd{sfx}_addr_rd),")
            a(f"    .boreChildrenBd_bore_wdata      (childBd{sfx}_wdata),")
            a(f"    .boreChildrenBd_bore_wmask      (childBd{sfx}_wmask),")
            a(f"    .boreChildrenBd_bore_re         (childBd{sfx}_re),")
            a(f"    .boreChildrenBd_bore_we         (childBd{sfx}_we),")
            a(f"    .boreChildrenBd_bore_rdata      (childBd{sfx}_rdata),")
            a(f"    .boreChildrenBd_bore_ack        (childBd{sfx}_ack),")
            a(f"    .boreChildrenBd_bore_selectedOH (childBd{sfx}_selectedOH),")
            a(f"    .boreChildrenBd_bore_array      (childBd{sfx}_array),")
            a(f"    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore{sig}_ram_hold),")
            a(f"    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore{sig}_ram_bypass),")
            a(f"    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore{sig}_ram_bp_clken),")
            a(f"    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore{sig}_ram_aux_clk),")
            a(f"    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore{sig}_ram_aux_ckbp),")
            a(f"    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore{sig}_ram_mcp_hold),")
            a(f"    .sigFromSrams_bore_cgen         (sigFromSrams_bore{sig}_cgen)")
            a(f"  );")
    a("")
    a("  // -------------------------------------------------------------------------")
    a("  // 4 条 Mbist 流水黑盒（golden 同名），每 way 一条，其 toSRAM_n 接本 way 的 8 个 bank")
    a("  // -------------------------------------------------------------------------")
    INST = ["res", "res_1", "res_2", "res_3"]
    for w in range(NUM_WAYS):
        sfx = "" if w == 0 else f"_{w}"
        a(f"  MbistPipeIcacheDataWay{w} {INST[w]} (")
        a(f"    .clock               (clock),")
        a(f"    .reset               (reset),")
        a(f"    .mbist_array         (boreChildrenBd_bore{sfx}_array),")
        a(f"    .mbist_all           (boreChildrenBd_bore{sfx}_all),")
        a(f"    .mbist_req           (boreChildrenBd_bore{sfx}_req),")
        a(f"    .mbist_ack           (boreChildrenBd_bore{sfx}_ack),")
        a(f"    .mbist_writeen       (boreChildrenBd_bore{sfx}_writeen),")
        a(f"    .mbist_be            (boreChildrenBd_bore{sfx}_be),")
        a(f"    .mbist_addr          (boreChildrenBd_bore{sfx}_addr),")
        a(f"    .mbist_indata        (boreChildrenBd_bore{sfx}_indata),")
        a(f"    .mbist_readen        (boreChildrenBd_bore{sfx}_readen),")
        a(f"    .mbist_addr_rd       (boreChildrenBd_bore{sfx}_addr_rd),")
        a(f"    .mbist_outdata       (boreChildrenBd_bore{sfx}_outdata),")
        for b in range(NUM_BANKS):
            k = w*NUM_BANKS + b
            cs = "" if k == 0 else f"_{k}"
            tail = "" if b == NUM_BANKS-1 else ","
            a(f"    .toSRAM_{b}_addr       (childBd{cs}_addr),")
            a(f"    .toSRAM_{b}_addr_rd    (childBd{cs}_addr_rd),")
            a(f"    .toSRAM_{b}_wdata      (childBd{cs}_wdata),")
            a(f"    .toSRAM_{b}_wmask      (childBd{cs}_wmask),")
            a(f"    .toSRAM_{b}_re         (childBd{cs}_re),")
            a(f"    .toSRAM_{b}_we         (childBd{cs}_we),")
            a(f"    .toSRAM_{b}_rdata      (childBd{cs}_rdata),")
            a(f"    .toSRAM_{b}_ack        (childBd{cs}_ack),")
            a(f"    .toSRAM_{b}_selectedOH (childBd{cs}_selectedOH),")
            a(f"    .toSRAM_{b}_array      (childBd{cs}_array){tail}")
        a(f"  );")
    a("")
    a("endmodule")
    return "\n".join(L)


def gen(module_name):
    return (header(module_name)
            + top_bd_ports() + "\n"
            + top_sig_ports() + "\n);\n\n"
            + body() + "\n")


if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else "wrapper"
    if target == "wrapper":
        sys.stdout.write(gen("ICacheDataArray"))
    elif target == "xs":
        sys.stdout.write(gen("ICacheDataArray_xs"))
    else:
        sys.exit("usage: gen_icachedata.py [wrapper|xs]")
