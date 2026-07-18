#!/usr/bin/env python3
# =============================================================================
# gen_bankeddata.py —— BankedDataArray wrapper + UT 脚手架生成器
#   产出:
#     rtl/memblock/BankedDataArray_wrapper.sv  (golden 同名顶层, FM/ST 用)
#     verif/ut/BankedDataArray/variants_xs.sv  (BankedDataArray_xs 镜像)
#     verif/ut/BankedDataArray/tb.sv           (golden vs _xs 双例化逐拍比对)
#
# wrapper 机械适配: 扁平 golden 端口 <-> 可读核数组端口; 例化 8 个 DataSRAM Bank 黑盒
# + MbistPipeDCacheData 黑盒, 按 golden 拓扑接 childBd/sig (bank b 用 [4b..4b+3])。
# =============================================================================
import re, os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
GOLD = os.path.join(ROOT, "golden/chisel-rtl/BankedDataArray.sv")
RTLD = os.path.join(ROOT, "rtl/memblock")
OUTD = os.path.join(ROOT, "verif/ut/BankedDataArray")
os.makedirs(OUTD, exist_ok=True)

N_BANKS, N_WAYS, N_LOAD, N_LINES = 8, 4, 3, 2
DSRAM_VARIANT = {0: "DataSRAMBank", 1: "DataSRAMBank_1", 2: "DataSRAMBank_2",
                 3: "DataSRAMBank_2", 4: "DataSRAMBank_4", 5: "DataSRAMBank_4",
                 6: "DataSRAMBank_4", 7: "DataSRAMBank_4"}

# ---- 解析 golden 顶层端口 ----
gold = open(GOLD).read()
m = re.search(r"module BankedDataArray\((.*?)\n\);", gold, re.S)
body = m.group(1)
ports = []
for line in body.split("\n"):
    line = line.strip().rstrip(",")
    mm = re.match(r"(input|output)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)$", line)
    if mm:
        w = (int(mm.group(2)) - int(mm.group(3)) + 1) if mm.group(2) else 1
        ports.append((mm.group(1), w, mm.group(4)))

inputs  = [(w, n) for (d, w, n) in ports if d == "input"  and n not in ("clock", "reset")]
outputs = [(w, n) for (d, w, n) in ports if d == "output"]

# ---- 生成 wrapper body (核连接 + 黑盒例化) ----
def gen_wrapper(modname):
    L = []
    L.append(f"module {modname} import bankeddata_pkg::*; (")
    L.append("  input clock,")
    L.append("  input reset,")
    for i, (w, n) in enumerate(inputs + outputs):
        d = "input" if (w, n) in inputs else "output"
        decl = f"[{w-1}:0] " if w > 1 else ""
        comma = "," if i < len(inputs)+len(outputs)-1 else ""
        L.append(f"  {d} {decl}{n}{comma}")
    L.append(");")
    L.append("")
    # ---- 核接口信号 ----
    L.append("  // 可读核接口数组")
    for sig, ty, dim in [
        ("c_read_valid","logic",f"[0:{N_LOAD-1}]"),
        ("c_read_way_en",f"logic [{N_WAYS-1}:0]",f"[0:{N_LOAD-1}]"),
        ("c_read_addr",f"logic [{ADDR_W()-1}:0]",f"[0:{N_LOAD-1}]"),
        ("c_read_addr_dup",f"logic [{ADDR_W()-1}:0]",f"[0:{N_LOAD-1}]"),
        ("c_read_bankMask",f"logic [{N_BANKS-1}:0]",f"[0:{N_LOAD-1}]"),
        ("c_read_lqIdx_flag","logic",f"[0:{N_LOAD-1}]"),
        ("c_read_lqIdx_value","logic [6:0]",f"[0:{N_LOAD-1}]"),
        ("c_read_ready","logic",f"[0:{N_LOAD-1}]"),
        ("c_is128","logic",f"[0:{N_LOAD-1}]"),
        ("c_write_data","logic [63:0]",f"[0:{N_BANKS-1}]"),
        ("c_write_dup_valid","logic",f"[0:{N_BANKS-1}]"),
        ("c_write_dup_way_en",f"logic [{N_WAYS-1}:0]",f"[0:{N_BANKS-1}]"),
        ("c_write_dup_addr",f"logic [{ADDR_W()-1}:0]",f"[0:{N_BANKS-1}]"),
        ("c_readline_resp","logic [63:0]",f"[0:{N_BANKS-1}]"),
        ("c_read_resp","logic [63:0]",f"[0:{N_LOAD-1}][0:{N_LINES-1}]"),
        ("c_read_err_dly","logic",f"[0:{N_LOAD-1}][0:{N_LINES-1}]"),
        ("c_bank_conflict_slow","logic",f"[0:{N_LOAD-1}]"),
        ("c_disable_fast","logic",f"[0:{N_LOAD-1}]"),
        ("c_pe_bits_valid","logic",f"[0:{N_BANKS-1}]"),
        ("c_pe_bits_mask","logic [63:0]",f"[0:{N_BANKS-1}]"),
        ("c_sram_r_en","logic",f"[0:{N_BANKS-1}]"),
        ("c_sram_r_addr",f"logic [{IDX_W()-1}:0]",f"[0:{N_BANKS-1}]"),
        ("c_sram_r_data",f"logic [{ENC()-1}:0]",f"[0:{N_BANKS-1}][0:{N_WAYS-1}]"),
        ("c_sram_w_en","logic",f"[0:{N_BANKS-1}]"),
        ("c_sram_w_way_en",f"logic [{N_WAYS-1}:0]",f"[0:{N_BANKS-1}]"),
        ("c_sram_w_addr",f"logic [{IDX_W()-1}:0]",f"[0:{N_BANKS-1}]"),
        ("c_sram_w_data",f"logic [{ENC()-1}:0]",f"[0:{N_BANKS-1}]"),
    ]:
        L.append(f"  {ty} {sig} {dim};")
    L.append("  logic c_mbist_ack; logic [1:0] c_mbist_r_way; logic c_mbist_r_div;")
    L.append("")
    # 扁平 -> 核
    for i in range(N_LOAD):
        L.append(f"  assign c_read_valid[{i}]=io_read_{i}_valid; assign c_read_way_en[{i}]=io_read_{i}_bits_way_en;")
        L.append(f"  assign c_read_addr[{i}]=io_read_{i}_bits_addr; assign c_read_addr_dup[{i}]=io_read_{i}_bits_addr_dup;")
        L.append(f"  assign c_read_bankMask[{i}]=io_read_{i}_bits_bankMask;")
        L.append(f"  assign c_read_lqIdx_flag[{i}]=io_read_{i}_bits_lqIdx_flag; assign c_read_lqIdx_value[{i}]=io_read_{i}_bits_lqIdx_value;")
        L.append(f"  assign io_read_{i}_ready=c_read_ready[{i}]; assign c_is128[{i}]=io_is128Req_{i};")
        L.append(f"  assign io_read_resp_{i}_0_raw_data=c_read_resp[{i}][0]; assign io_read_resp_{i}_1_raw_data=c_read_resp[{i}][1];")
        L.append(f"  assign io_read_error_delayed_{i}_0=c_read_err_dly[{i}][0]; assign io_read_error_delayed_{i}_1=c_read_err_dly[{i}][1];")
        L.append(f"  assign io_bank_conflict_slow_{i}=c_bank_conflict_slow[{i}]; assign io_disable_ld_fast_wakeup_{i}=c_disable_fast[{i}];")
    for b in range(N_BANKS):
        L.append(f"  assign c_write_data[{b}]=io_write_bits_data_{b};")
        L.append(f"  assign c_write_dup_valid[{b}]=io_write_dup_{b}_valid; assign c_write_dup_way_en[{b}]=io_write_dup_{b}_bits_way_en; assign c_write_dup_addr[{b}]=io_write_dup_{b}_bits_addr;")
        L.append(f"  assign io_readline_resp_{b}_raw_data=c_readline_resp[{b}];")
        L.append(f"  assign c_pe_bits_valid[{b}]=io_pseudo_error_bits_{b}_valid; assign c_pe_bits_mask[{b}]=io_pseudo_error_bits_{b}_mask;")
    L.append("")
    # ---- 核例化 ----
    # mbistPl 的 per-通道 ack 输出 + 核心 readline 输出级 → 核新增端口
    L.append("  // mbistPl 的 per-通道 ack 输出（golden _mbistPl_toSRAM_N_ack）→ 核心 pseudo 注错门控")
    L.append("  wire mb_ack [8][4];")
    L.append("  // 核心 readline 输出级 {ecc,raw} → mbistPl toSRAM_{4b..4b+3}_rdata（golden 接 r_8_b）")
    L.append("  wire [71:0] mb_rl [8];")
    L.append("  xs_BankedDataArray_core u_core (")
    L.append("    .clock(clock), .reset(reset),")
    L.append("    .io_read_valid(c_read_valid), .io_read_way_en(c_read_way_en),")
    L.append("    .io_read_addr(c_read_addr), .io_read_addr_dup(c_read_addr_dup),")
    L.append("    .io_read_bankMask(c_read_bankMask), .io_read_lqIdx_flag(c_read_lqIdx_flag),")
    L.append("    .io_read_lqIdx_value(c_read_lqIdx_value), .io_read_ready(c_read_ready), .io_is128Req(c_is128),")
    L.append("    .io_readline_intend(io_readline_intend), .io_readline_valid(io_readline_valid),")
    L.append("    .io_readline_way_en(io_readline_bits_way_en), .io_readline_addr(io_readline_bits_addr),")
    L.append("    .io_readline_rmask(io_readline_bits_rmask), .io_readline_can_go(io_readline_can_go),")
    L.append("    .io_readline_stall(io_readline_stall), .io_readline_can_resp(io_readline_can_resp),")
    L.append("    .io_readline_ready(io_readline_ready),")
    L.append("    .io_write_valid(io_write_valid), .io_write_wmask(io_write_bits_wmask), .io_write_data(c_write_data),")
    L.append("    .io_write_dup_valid(c_write_dup_valid), .io_write_dup_way_en(c_write_dup_way_en), .io_write_dup_addr(c_write_dup_addr),")
    L.append("    .io_readline_resp(c_readline_resp), .io_readline_error(io_readline_error), .io_readline_error_delayed(io_readline_error_delayed),")
    L.append("    .io_read_resp(c_read_resp), .io_read_error_delayed(c_read_err_dly),")
    L.append("    .io_bank_conflict_slow(c_bank_conflict_slow), .io_disable_ld_fast_wakeup(c_disable_fast),")
    L.append("    .io_pseudo_error_valid(io_pseudo_error_valid), .io_pseudo_error_bits_valid(c_pe_bits_valid),")
    L.append("    .io_pseudo_error_bits_mask(c_pe_bits_mask), .io_pseudo_error_ready(io_pseudo_error_ready),")
    L.append("    .sram_r_en(c_sram_r_en), .sram_r_addr(c_sram_r_addr), .sram_r_data(c_sram_r_data),")
    L.append("    .sram_w_en(c_sram_w_en), .sram_w_way_en(c_sram_w_way_en), .sram_w_addr(c_sram_w_addr), .sram_w_data(c_sram_w_data),")
    L.append("    .mbist_ack(c_mbist_ack), .mbist_r_way(c_mbist_r_way), .mbist_r_div(c_mbist_r_div),")
    L.append("    .mbist_chan_ack(mb_ack), .mbist_rl_rdata(mb_rl)")
    L.append("  );")
    L.append("")
    # ---- childBd / sig 链 (32 条) ----
    L.append("  // MBIST bore: 32 条 childBd (bank b 用 [4b..4b+3]), 32 sig 组")
    # rdata 是 bank bore 的输出网(顶层悬空), ack 是 bank bore 的输入(由 mbistPl 驱动)——加注对齐注释
    cb_cmt = {
        "rdata": "   // bank bore rdata 输出：golden 顶层同为悬空网（childBd_N_rdata）",
        "ack":   "            // bank bore ack **输入**：golden childBd_N_ack = mbistPl toSRAM_N_ack",
    }
    for f, w in [("addr",9),("addr_rd",9),("wdata",72),("wmask",1),("re",1),("we",1),
                 ("rdata",72),("ack",1),("selectedOH",1)]:
        decl = f"[{w-1}:0] " if w > 1 else ""
        L.append(f"  wire {decl}cb_{f} [32];{cb_cmt.get(f, '')}")
    # array 端口宽度逐索引不同(MBIST 地址树深度), 单独声明各 cb_array_k
    AW = {0:1,1:1,2:2,3:2,4:3,5:3,6:3,7:3,8:4,9:4,10:4,11:4,12:4,13:4,14:4,15:4}
    for k in range(32):
        w = AW.get(k, 5)
        decl = f"[{w-1}:0] " if w > 1 else ""
        L.append(f"  wire {decl}cb_array_{k};")
    L.append("  wire [6:0] sg [32];")
    L.append("  wire c_mbist_ack_pl;")
    # sig 顶层端口打包
    for k in range(32):
        suf = "" if k == 0 else f"_{k}"
        L.append(f"  assign sg[{k}] = {{sigFromSrams_bore{suf}_cgen, sigFromSrams_bore{suf}_ram_mcp_hold, sigFromSrams_bore{suf}_ram_aux_ckbp, sigFromSrams_bore{suf}_ram_aux_clk, sigFromSrams_bore{suf}_ram_bp_clken, sigFromSrams_bore{suf}_ram_bypass, sigFromSrams_bore{suf}_ram_hold}};")
    L.append("")
    # mbist_r_way = OHToUInt over per-way re (Cat(re3,re2,re1) OR across banks)
    L.append("  // mbist_r_way: 各 bank 的 {re3,re2,re1} 按位或后 OHToUInt(本配置 mbist 不激活时恒 0)")
    # bank 的 bore_ack 是输入，须由 mbistPl 的 per-通道 ack 驱动（golden childBd_N_ack = _mbistPl_toSRAM_N_ack）
    L.append("  // golden: childBd_N_ack = _mbistPl_toSRAM_N_ack（bank 的 bore_ack 是输入，须由 mbistPl 驱动）")
    L.append("  for (genvar n = 0; n < 32; n++) begin : g_cback")
    L.append("    assign cb_ack[n] = mb_ack[n/4][n%4];")
    L.append("  end")
    L.append("")
    L.append("  wire [2:0] mbist_way_oh = " + " | ".join(
        f"{{cb_re[{4*b+3}],cb_re[{4*b+2}],cb_re[{4*b+1}]}}" for b in range(N_BANKS)) + ";")
    L.append("  assign c_mbist_r_way = {mbist_way_oh[2]|mbist_way_oh[1], mbist_way_oh[2]|mbist_way_oh[0]};")
    L.append("  assign c_mbist_r_div = 1'b0;")
    L.append("")
    # ---- 8 个 DataSRAMBank 黑盒 ----
    for b in range(N_BANKS):
        L.append(f"  {DSRAM_VARIANT[b]} data_banks_0_{b} (")
        L.append("    .clock(clock), .reset(reset),")
        L.append(f"    .io_w_en(c_sram_w_en[{b}]), .io_w_addr(c_sram_w_addr[{b}]), .io_w_way_en(c_sram_w_way_en[{b}]), .io_w_data(c_sram_w_data[{b}]),")
        L.append(f"    .io_r_en(c_sram_r_en[{b}]), .io_r_addr(c_sram_r_addr[{b}]),")
        L.append(f"    .io_r_data_0(c_sram_r_data[{b}][0]), .io_r_data_1(c_sram_r_data[{b}][1]), .io_r_data_2(c_sram_r_data[{b}][2]), .io_r_data_3(c_sram_r_data[{b}][3]),")
        for sub in range(4):
            cb = 4*b + sub
            pre = "boreChildrenBd_bore" + ("" if sub == 0 else f"_{sub}")
            L.append(f"    .{pre}_addr(cb_addr[{cb}]), .{pre}_addr_rd(cb_addr_rd[{cb}]), .{pre}_wdata(cb_wdata[{cb}]), .{pre}_wmask(cb_wmask[{cb}]), .{pre}_re(cb_re[{cb}]), .{pre}_we(cb_we[{cb}]), .{pre}_rdata(cb_rdata[{cb}]), .{pre}_ack(cb_ack[{cb}]), .{pre}_selectedOH(cb_selectedOH[{cb}]), .{pre}_array(cb_array_{cb}),")
        # sig: 4 sub-groups
        for sub in range(4):
            sgi = 4*b + sub
            pre = "sigFromSrams_bore" + ("" if sub == 0 else f"_{sub}")
            comma = "," if sub < 3 else ""
            L.append(f"    .{pre}_ram_hold(sg[{sgi}][0]), .{pre}_ram_bypass(sg[{sgi}][1]), .{pre}_ram_bp_clken(sg[{sgi}][2]), .{pre}_ram_aux_clk(sg[{sgi}][3]), .{pre}_ram_aux_ckbp(sg[{sgi}][4]), .{pre}_ram_mcp_hold(sg[{sgi}][5]), .{pre}_cgen(sg[{sgi}][6]){comma}")
        L.append("  );")
    L.append("")
    # ---- MbistPipeDCacheData ----
    L.append("  MbistPipeDCacheData mbistPl (")
    L.append("    .clock(clock), .reset(reset),")
    L.append("    .mbist_array(boreChildrenBd_bore_array), .mbist_all(boreChildrenBd_bore_all), .mbist_req(boreChildrenBd_bore_req), .mbist_ack(c_mbist_ack_pl),")
    L.append("    .mbist_writeen(boreChildrenBd_bore_writeen), .mbist_be(boreChildrenBd_bore_be), .mbist_addr(boreChildrenBd_bore_addr),")
    L.append("    .mbist_indata(boreChildrenBd_bore_indata), .mbist_readen(boreChildrenBd_bore_readen), .mbist_addr_rd(boreChildrenBd_bore_addr_rd), .mbist_outdata(boreChildrenBd_bore_outdata),")
    for k in range(32):
        comma = "," if k < 31 else ""
        # toSRAM_N_rdata 汇入 bank(N/4) 的 readline 输出网; toSRAM_N_ack 驱动 per-通道 mb_ack[bank][sub]
        L.append(f"    .toSRAM_{k}_addr(cb_addr[{k}]), .toSRAM_{k}_addr_rd(cb_addr_rd[{k}]), .toSRAM_{k}_wdata(cb_wdata[{k}]), .toSRAM_{k}_wmask(cb_wmask[{k}]), .toSRAM_{k}_re(cb_re[{k}]), .toSRAM_{k}_we(cb_we[{k}]), .toSRAM_{k}_rdata(mb_rl[{k//4}]), .toSRAM_{k}_ack(mb_ack[{k//4}][{k%4}]), .toSRAM_{k}_selectedOH(cb_selectedOH[{k}]), .toSRAM_{k}_array(cb_array_{k}){comma}")
    L.append("  );")
    L.append("  assign c_mbist_ack = c_mbist_ack_pl; assign boreChildrenBd_bore_ack = c_mbist_ack_pl;")
    L.append("")
    L.append("endmodule")
    return "\n".join(L)

def ADDR_W(): return 48
def IDX_W(): return 8
def ENC(): return 72

hdr = ("// 自动生成: scripts/gen_bankeddata.py —— 勿手改\n"
       "// BankedDataArray wrapper: 扁平 golden 端口 <-> 可读核 + DataSRAMBank/Mbist 黑盒\n")
open(os.path.join(RTLD, "BankedDataArray_wrapper.sv"), "w").write(hdr + gen_wrapper("BankedDataArray"))
open(os.path.join(OUTD, "variants_xs.sv"), "w").write(hdr + gen_wrapper("BankedDataArray_xs"))

# =============================================================================
# tb.sv —— golden vs _xs 双例化, 随机激励, 逐拍比对功能输出
# =============================================================================
def is_checked(n):
    return (n.endswith("_raw_data") or n.endswith("_ready") or
            n.startswith("io_read_error_delayed") or n.startswith("io_bank_conflict_slow") or
            n.startswith("io_disable_ld_fast_wakeup") or
            n in ("io_readline_error","io_readline_error_delayed","io_pseudo_error_ready"))

T = []
T.append("// 自动生成: scripts/gen_bankeddata.py —— 勿手改")
T.append("`timescale 1ns/1ps")
T.append("module tb;")
T.append("  int unsigned NVEC = 200000;")
T.append("  int WARMUP = 50;")
T.append("  int errors = 0, checks = 0;")
T.append("  logic clock = 0, reset;")
T.append("  always #5 clock = ~clock;")
for w, n in inputs:
    T.append(f"  logic [{w-1}:0] {n};" if w > 1 else f"  logic {n};")
for w, n in outputs:
    if w > 1:
        T.append(f"  wire [{w-1}:0] g_{n}; wire [{w-1}:0] i_{n};")
    else:
        T.append(f"  wire g_{n}; wire i_{n};")

def inst(mod, pre):
    c = [".clock(clock)", ".reset(reset)"]
    for w, n in inputs: c.append(f".{n}({n})")
    for w, n in outputs: c.append(f".{n}({pre}{n})")
    return f"  {mod} {pre}u (" + ", ".join(c) + ");"

T.append(inst("BankedDataArray", "g_"))
T.append(inst("BankedDataArray_xs", "i_"))
T.append("  task automatic do_check(int t);")
T.append("    checks++;")
for w, n in outputs:
    if is_checked(n):
        T.append(f"    if (!$isunknown(g_{n}) && (g_{n} !== i_{n})) begin errors++;")
        T.append(f"      if(errors<=80) $display(\"vec %0d {n} g=%h i=%h\",t,g_{n},i_{n}); end")
T.append("  endtask")
# 旁带/MBIST 默认置 0; 激励主链
sig_inits = []
for k in range(32):
    suf = "" if k == 0 else f"_{k}"
    for f in ["ram_hold","ram_bypass","ram_bp_clken","ram_aux_clk","ram_aux_ckbp","ram_mcp_hold","cgen"]:
        sig_inits.append(f"sigFromSrams_bore{suf}_{f}=0;")
T.append("  initial begin")
T.append("    boreChildrenBd_bore_array=0; boreChildrenBd_bore_all=0; boreChildrenBd_bore_req=0;")
T.append("    boreChildrenBd_bore_writeen=0; boreChildrenBd_bore_be=0; boreChildrenBd_bore_addr=0;")
T.append("    boreChildrenBd_bore_indata=0; boreChildrenBd_bore_readen=0; boreChildrenBd_bore_addr_rd=0;")
for s in sig_inits:
    T.append("    " + s)
T.append("  end")
T.append("""
  task automatic drive();
    for (int i=0;i<3;i++);
    io_read_0_valid=$urandom; io_read_0_bits_way_en=(1<<($urandom%4)); io_read_0_bits_addr={$urandom,$urandom}; io_read_0_bits_addr_dup=io_read_0_bits_addr; io_read_0_bits_bankMask=$urandom; io_read_0_bits_lqIdx_flag=$urandom; io_read_0_bits_lqIdx_value=$urandom;
    io_read_1_valid=$urandom; io_read_1_bits_way_en=(1<<($urandom%4)); io_read_1_bits_addr={$urandom,$urandom}; io_read_1_bits_addr_dup=io_read_1_bits_addr; io_read_1_bits_bankMask=$urandom; io_read_1_bits_lqIdx_flag=$urandom; io_read_1_bits_lqIdx_value=$urandom;
    io_read_2_valid=$urandom; io_read_2_bits_way_en=(1<<($urandom%4)); io_read_2_bits_addr={$urandom,$urandom}; io_read_2_bits_addr_dup=io_read_2_bits_addr; io_read_2_bits_bankMask=$urandom; io_read_2_bits_lqIdx_flag=$urandom; io_read_2_bits_lqIdx_value=$urandom;
    io_is128Req_0=$urandom; io_is128Req_1=$urandom; io_is128Req_2=$urandom;
    io_readline_intend=$urandom; io_readline_valid=$urandom; io_readline_bits_way_en=(1<<($urandom%4)); io_readline_bits_addr={$urandom,$urandom}; io_readline_bits_rmask=$urandom;
    io_readline_can_go=$urandom; io_readline_stall=$urandom; io_readline_can_resp=$urandom;
    io_write_valid=($urandom%3==0); io_write_bits_wmask=$urandom;
    io_write_bits_data_0={$urandom,$urandom}; io_write_bits_data_1={$urandom,$urandom}; io_write_bits_data_2={$urandom,$urandom}; io_write_bits_data_3={$urandom,$urandom};
    io_write_bits_data_4={$urandom,$urandom}; io_write_bits_data_5={$urandom,$urandom}; io_write_bits_data_6={$urandom,$urandom}; io_write_bits_data_7={$urandom,$urandom};
    for (int b=0;b<8;b++);
    io_write_dup_0_valid=io_write_valid; io_write_dup_0_bits_way_en=(1<<($urandom%4)); io_write_dup_0_bits_addr={$urandom,$urandom};
    io_write_dup_1_valid=io_write_valid; io_write_dup_1_bits_way_en=io_write_dup_0_bits_way_en; io_write_dup_1_bits_addr=io_write_dup_0_bits_addr;
    io_write_dup_2_valid=io_write_valid; io_write_dup_2_bits_way_en=io_write_dup_0_bits_way_en; io_write_dup_2_bits_addr=io_write_dup_0_bits_addr;
    io_write_dup_3_valid=io_write_valid; io_write_dup_3_bits_way_en=io_write_dup_0_bits_way_en; io_write_dup_3_bits_addr=io_write_dup_0_bits_addr;
    io_write_dup_4_valid=io_write_valid; io_write_dup_4_bits_way_en=io_write_dup_0_bits_way_en; io_write_dup_4_bits_addr=io_write_dup_0_bits_addr;
    io_write_dup_5_valid=io_write_valid; io_write_dup_5_bits_way_en=io_write_dup_0_bits_way_en; io_write_dup_5_bits_addr=io_write_dup_0_bits_addr;
    io_write_dup_6_valid=io_write_valid; io_write_dup_6_bits_way_en=io_write_dup_0_bits_way_en; io_write_dup_6_bits_addr=io_write_dup_0_bits_addr;
    io_write_dup_7_valid=io_write_valid; io_write_dup_7_bits_way_en=io_write_dup_0_bits_way_en; io_write_dup_7_bits_addr=io_write_dup_0_bits_addr;
    io_pseudo_error_valid=($urandom%8==0);
    io_pseudo_error_bits_0_valid=$urandom; io_pseudo_error_bits_0_mask={$urandom,$urandom};
    io_pseudo_error_bits_1_valid=$urandom; io_pseudo_error_bits_1_mask={$urandom,$urandom};
    io_pseudo_error_bits_2_valid=$urandom; io_pseudo_error_bits_2_mask={$urandom,$urandom};
    io_pseudo_error_bits_3_valid=$urandom; io_pseudo_error_bits_3_mask={$urandom,$urandom};
    io_pseudo_error_bits_4_valid=$urandom; io_pseudo_error_bits_4_mask={$urandom,$urandom};
    io_pseudo_error_bits_5_valid=$urandom; io_pseudo_error_bits_5_mask={$urandom,$urandom};
    io_pseudo_error_bits_6_valid=$urandom; io_pseudo_error_bits_6_mask={$urandom,$urandom};
    io_pseudo_error_bits_7_valid=$urandom; io_pseudo_error_bits_7_mask={$urandom,$urandom};
  endtask

  initial begin
    reset = 1; drive();
    io_read_0_valid=0; io_read_1_valid=0; io_read_2_valid=0; io_readline_valid=0; io_write_valid=0; io_pseudo_error_valid=0;
    io_write_dup_0_valid=0; io_write_dup_1_valid=0; io_write_dup_2_valid=0; io_write_dup_3_valid=0;
    io_write_dup_4_valid=0; io_write_dup_5_valid=0; io_write_dup_6_valid=0; io_write_dup_7_valid=0;
    repeat (20) @(posedge clock);
    reset = 0;
    for (int t = 0; t < NVEC; t++) begin
      drive();
      @(posedge clock); #1;
      if (t >= WARMUP) do_check(t);
    end
    if (errors == 0) $display("TEST PASSED  checks=%0d errors=%0d", checks, errors);
    else             $display("TEST FAILED  checks=%0d errors=%0d", checks, errors);
    $finish;
  end
endmodule
""")
open(os.path.join(OUTD, "tb.sv"), "w").write("\n".join(T))
print("generated wrapper + variants_xs.sv + tb.sv")
