// RenameTable UT —— 家族四个变体 golden/重写件双例化逐拍比对
//
// 四个变体（int / fp / vec / v0vl）共用 rtl/backend/RenameTable.sv 里的同一个
// 参数化核 xs_RenameTable_core，差异维度见该文件头的家族对照表。
// 每个变体的 wrapper 里还例化一个 SnapshotGenerator_<N>（实例名与 golden 一致），
// 那四个快照件本身有自己的 UT/FM 目录（verif/ut/SnapshotGenerator），
// 这里两侧都完整 elaborate，**零黑盒**。
//
// ★本文件由 gen_tb.py 生成，勿手改★
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  // ==========================================================================
  // 复位后的"暖机窗口"—— 为什么必须有
  // ==========================================================================
  // 4 个快照槽是**无复位存储器**：golden SnapshotGenerator_6.sv 里写它们的那个
  // always @(posedge clock) 块没有 reset 臂（rtl/backend/SnapshotGenerator.sv §6
  // 照抄了这一点，这是对的）。于是：
  //   · golden 与重写件是**两个独立例化**（RenameTable_2 / RenameTable_2_xs），
  //     +vcs+initreg+random 给它们各自抽一份**互不相同**的上电值；
  //   · 一个"还没被写过"的槽，两侧的内容天然不等 —— 这不是 RTL 差异，
  //     是 tb 在比一个还没有定义的东西。
  // 设计契约本来就是"只读有效槽"（snptValids 保证），而本 tb 的 snptSelect 是
  // 全随机的，不看有效位。实测（seed=42 +vcs+initreg+random）：第 26 拍就有一次
  // useSnpt 恢复选中了**从未被写过的**槽 3，整张 spec_table 当场分叉。
  //
  // 修法：复位一撤，先做 WARMUP 拍**纯入队**——redirect/useSnpt/deq/flushVec 全压 0、
  // snptEnq 恒 1。enq_fire = ~redirect & ~full & enq，队列复位后是空的，
  // 所以前 4 拍依次写满槽 0/1/2/3（第 5 拍起队满、静默丢弃）。槽只会被覆盖、
  // 不会被"擦回未写"，因此窗口之后整段仿真里任何槽的内容都是**输入的函数**。
  // 窗口内 redirect 恒 0 ⇒ spec_redirect_q 恒 0 ⇒ 恢复路径根本不会启动，
  // 不存在"窗口内读到脏槽"的残留。读写口照常随机，暖机不降低激励强度。
  int unsigned WARMUP = 8;
  int cyc = 0;
  always @(posedge clk) if (!rst) cyc <= cyc + 1;
  // 在 posedge 更新、在 negedge 使用，差半拍，没有竞争。
  wire warmup = (cyc < WARMUP);

  `define CHK(nm, g, i) \
    if (!$isunknown(g) && (g) !== (i)) begin errors++; \
      if (errors <= 80) $display("[%0t] %s g=%h i=%h", $time, nm, g, i); end

  // ==========================================================================
  // RenameTable: 32 格 / addr 5 位 / 12 读口 / need_free 有 / debug_rdata 32 格
  // ==========================================================================
  logic            renametable_redirect;
  logic            renametable_rd_hold [12];
  logic [4:0]      renametable_rd_addr [12];
  logic            renametable_sw_wen [6];
  logic [7:0]      renametable_sw_data [6];
  logic            renametable_aw_wen [6];
  logic [7:0]      renametable_aw_data [6];
  logic [4:0]      renametable_sw_addr [6];
  logic [4:0]      renametable_aw_addr [6];
  logic            renametable_snpt_enq, renametable_snpt_deq, renametable_snpt_use;
  logic [1:0]      renametable_snpt_sel;
  logic [3:0]      renametable_snpt_flush;
  logic [7:0] renametable_g_rdata [12];
  logic [7:0] renametable_g_oldp [6];
  logic       renametable_g_nfree [6];
  logic [7:0] renametable_g_diff [32];
  logic [7:0] renametable_g_dbg [32];
  logic [7:0] renametable_i_rdata [12];
  logic [7:0] renametable_i_oldp [6];
  logic       renametable_i_nfree [6];
  logic [7:0] renametable_i_diff [32];
  logic [7:0] renametable_i_dbg [32];

  RenameTable renametable_g_u (
    .clock(clk), .reset(rst), .io_redirect(renametable_redirect),
    .io_readPorts_0_hold(renametable_rd_hold[0]),
    .io_readPorts_0_addr(renametable_rd_addr[0]),
    .io_readPorts_0_data(renametable_g_rdata[0]),
    .io_readPorts_1_hold(renametable_rd_hold[1]),
    .io_readPorts_1_addr(renametable_rd_addr[1]),
    .io_readPorts_1_data(renametable_g_rdata[1]),
    .io_readPorts_2_hold(renametable_rd_hold[2]),
    .io_readPorts_2_addr(renametable_rd_addr[2]),
    .io_readPorts_2_data(renametable_g_rdata[2]),
    .io_readPorts_3_hold(renametable_rd_hold[3]),
    .io_readPorts_3_addr(renametable_rd_addr[3]),
    .io_readPorts_3_data(renametable_g_rdata[3]),
    .io_readPorts_4_hold(renametable_rd_hold[4]),
    .io_readPorts_4_addr(renametable_rd_addr[4]),
    .io_readPorts_4_data(renametable_g_rdata[4]),
    .io_readPorts_5_hold(renametable_rd_hold[5]),
    .io_readPorts_5_addr(renametable_rd_addr[5]),
    .io_readPorts_5_data(renametable_g_rdata[5]),
    .io_readPorts_6_hold(renametable_rd_hold[6]),
    .io_readPorts_6_addr(renametable_rd_addr[6]),
    .io_readPorts_6_data(renametable_g_rdata[6]),
    .io_readPorts_7_hold(renametable_rd_hold[7]),
    .io_readPorts_7_addr(renametable_rd_addr[7]),
    .io_readPorts_7_data(renametable_g_rdata[7]),
    .io_readPorts_8_hold(renametable_rd_hold[8]),
    .io_readPorts_8_addr(renametable_rd_addr[8]),
    .io_readPorts_8_data(renametable_g_rdata[8]),
    .io_readPorts_9_hold(renametable_rd_hold[9]),
    .io_readPorts_9_addr(renametable_rd_addr[9]),
    .io_readPorts_9_data(renametable_g_rdata[9]),
    .io_readPorts_10_hold(renametable_rd_hold[10]),
    .io_readPorts_10_addr(renametable_rd_addr[10]),
    .io_readPorts_10_data(renametable_g_rdata[10]),
    .io_readPorts_11_hold(renametable_rd_hold[11]),
    .io_readPorts_11_addr(renametable_rd_addr[11]),
    .io_readPorts_11_data(renametable_g_rdata[11]),
    .io_specWritePorts_0_wen(renametable_sw_wen[0]),
    .io_specWritePorts_0_addr(renametable_sw_addr[0]),
    .io_specWritePorts_0_data(renametable_sw_data[0]),
    .io_specWritePorts_1_wen(renametable_sw_wen[1]),
    .io_specWritePorts_1_addr(renametable_sw_addr[1]),
    .io_specWritePorts_1_data(renametable_sw_data[1]),
    .io_specWritePorts_2_wen(renametable_sw_wen[2]),
    .io_specWritePorts_2_addr(renametable_sw_addr[2]),
    .io_specWritePorts_2_data(renametable_sw_data[2]),
    .io_specWritePorts_3_wen(renametable_sw_wen[3]),
    .io_specWritePorts_3_addr(renametable_sw_addr[3]),
    .io_specWritePorts_3_data(renametable_sw_data[3]),
    .io_specWritePorts_4_wen(renametable_sw_wen[4]),
    .io_specWritePorts_4_addr(renametable_sw_addr[4]),
    .io_specWritePorts_4_data(renametable_sw_data[4]),
    .io_specWritePorts_5_wen(renametable_sw_wen[5]),
    .io_specWritePorts_5_addr(renametable_sw_addr[5]),
    .io_specWritePorts_5_data(renametable_sw_data[5]),
    .io_archWritePorts_0_wen(renametable_aw_wen[0]),
    .io_archWritePorts_0_addr(renametable_aw_addr[0]),
    .io_archWritePorts_0_data(renametable_aw_data[0]),
    .io_archWritePorts_1_wen(renametable_aw_wen[1]),
    .io_archWritePorts_1_addr(renametable_aw_addr[1]),
    .io_archWritePorts_1_data(renametable_aw_data[1]),
    .io_archWritePorts_2_wen(renametable_aw_wen[2]),
    .io_archWritePorts_2_addr(renametable_aw_addr[2]),
    .io_archWritePorts_2_data(renametable_aw_data[2]),
    .io_archWritePorts_3_wen(renametable_aw_wen[3]),
    .io_archWritePorts_3_addr(renametable_aw_addr[3]),
    .io_archWritePorts_3_data(renametable_aw_data[3]),
    .io_archWritePorts_4_wen(renametable_aw_wen[4]),
    .io_archWritePorts_4_addr(renametable_aw_addr[4]),
    .io_archWritePorts_4_data(renametable_aw_data[4]),
    .io_archWritePorts_5_wen(renametable_aw_wen[5]),
    .io_archWritePorts_5_addr(renametable_aw_addr[5]),
    .io_archWritePorts_5_data(renametable_aw_data[5]),
    .io_old_pdest_0(renametable_g_oldp[0]),
    .io_old_pdest_1(renametable_g_oldp[1]),
    .io_old_pdest_2(renametable_g_oldp[2]),
    .io_old_pdest_3(renametable_g_oldp[3]),
    .io_old_pdest_4(renametable_g_oldp[4]),
    .io_old_pdest_5(renametable_g_oldp[5]),
    .io_need_free_0(renametable_g_nfree[0]),
    .io_need_free_1(renametable_g_nfree[1]),
    .io_need_free_2(renametable_g_nfree[2]),
    .io_need_free_3(renametable_g_nfree[3]),
    .io_need_free_4(renametable_g_nfree[4]),
    .io_need_free_5(renametable_g_nfree[5]),
    .io_snpt_snptEnq(renametable_snpt_enq), .io_snpt_snptDeq(renametable_snpt_deq),
    .io_snpt_useSnpt(renametable_snpt_use), .io_snpt_snptSelect(renametable_snpt_sel),
    .io_snpt_flushVec_0(renametable_snpt_flush[0]),
    .io_snpt_flushVec_1(renametable_snpt_flush[1]),
    .io_snpt_flushVec_2(renametable_snpt_flush[2]),
    .io_snpt_flushVec_3(renametable_snpt_flush[3]),
    .io_diffRatBase_0(renametable_g_diff[0]),
    .io_diffRatBase_1(renametable_g_diff[1]),
    .io_diffRatBase_2(renametable_g_diff[2]),
    .io_diffRatBase_3(renametable_g_diff[3]),
    .io_diffRatBase_4(renametable_g_diff[4]),
    .io_diffRatBase_5(renametable_g_diff[5]),
    .io_diffRatBase_6(renametable_g_diff[6]),
    .io_diffRatBase_7(renametable_g_diff[7]),
    .io_diffRatBase_8(renametable_g_diff[8]),
    .io_diffRatBase_9(renametable_g_diff[9]),
    .io_diffRatBase_10(renametable_g_diff[10]),
    .io_diffRatBase_11(renametable_g_diff[11]),
    .io_diffRatBase_12(renametable_g_diff[12]),
    .io_diffRatBase_13(renametable_g_diff[13]),
    .io_diffRatBase_14(renametable_g_diff[14]),
    .io_diffRatBase_15(renametable_g_diff[15]),
    .io_diffRatBase_16(renametable_g_diff[16]),
    .io_diffRatBase_17(renametable_g_diff[17]),
    .io_diffRatBase_18(renametable_g_diff[18]),
    .io_diffRatBase_19(renametable_g_diff[19]),
    .io_diffRatBase_20(renametable_g_diff[20]),
    .io_diffRatBase_21(renametable_g_diff[21]),
    .io_diffRatBase_22(renametable_g_diff[22]),
    .io_diffRatBase_23(renametable_g_diff[23]),
    .io_diffRatBase_24(renametable_g_diff[24]),
    .io_diffRatBase_25(renametable_g_diff[25]),
    .io_diffRatBase_26(renametable_g_diff[26]),
    .io_diffRatBase_27(renametable_g_diff[27]),
    .io_diffRatBase_28(renametable_g_diff[28]),
    .io_diffRatBase_29(renametable_g_diff[29]),
    .io_diffRatBase_30(renametable_g_diff[30]),
    .io_diffRatBase_31(renametable_g_diff[31]),
    .io_debug_rdata_0(renametable_g_dbg[0]),
    .io_debug_rdata_1(renametable_g_dbg[1]),
    .io_debug_rdata_2(renametable_g_dbg[2]),
    .io_debug_rdata_3(renametable_g_dbg[3]),
    .io_debug_rdata_4(renametable_g_dbg[4]),
    .io_debug_rdata_5(renametable_g_dbg[5]),
    .io_debug_rdata_6(renametable_g_dbg[6]),
    .io_debug_rdata_7(renametable_g_dbg[7]),
    .io_debug_rdata_8(renametable_g_dbg[8]),
    .io_debug_rdata_9(renametable_g_dbg[9]),
    .io_debug_rdata_10(renametable_g_dbg[10]),
    .io_debug_rdata_11(renametable_g_dbg[11]),
    .io_debug_rdata_12(renametable_g_dbg[12]),
    .io_debug_rdata_13(renametable_g_dbg[13]),
    .io_debug_rdata_14(renametable_g_dbg[14]),
    .io_debug_rdata_15(renametable_g_dbg[15]),
    .io_debug_rdata_16(renametable_g_dbg[16]),
    .io_debug_rdata_17(renametable_g_dbg[17]),
    .io_debug_rdata_18(renametable_g_dbg[18]),
    .io_debug_rdata_19(renametable_g_dbg[19]),
    .io_debug_rdata_20(renametable_g_dbg[20]),
    .io_debug_rdata_21(renametable_g_dbg[21]),
    .io_debug_rdata_22(renametable_g_dbg[22]),
    .io_debug_rdata_23(renametable_g_dbg[23]),
    .io_debug_rdata_24(renametable_g_dbg[24]),
    .io_debug_rdata_25(renametable_g_dbg[25]),
    .io_debug_rdata_26(renametable_g_dbg[26]),
    .io_debug_rdata_27(renametable_g_dbg[27]),
    .io_debug_rdata_28(renametable_g_dbg[28]),
    .io_debug_rdata_29(renametable_g_dbg[29]),
    .io_debug_rdata_30(renametable_g_dbg[30]),
    .io_debug_rdata_31(renametable_g_dbg[31])
  );
  RenameTable_xs renametable_i_u (
    .clock(clk), .reset(rst), .io_redirect(renametable_redirect),
    .io_readPorts_0_hold(renametable_rd_hold[0]),
    .io_readPorts_0_addr(renametable_rd_addr[0]),
    .io_readPorts_0_data(renametable_i_rdata[0]),
    .io_readPorts_1_hold(renametable_rd_hold[1]),
    .io_readPorts_1_addr(renametable_rd_addr[1]),
    .io_readPorts_1_data(renametable_i_rdata[1]),
    .io_readPorts_2_hold(renametable_rd_hold[2]),
    .io_readPorts_2_addr(renametable_rd_addr[2]),
    .io_readPorts_2_data(renametable_i_rdata[2]),
    .io_readPorts_3_hold(renametable_rd_hold[3]),
    .io_readPorts_3_addr(renametable_rd_addr[3]),
    .io_readPorts_3_data(renametable_i_rdata[3]),
    .io_readPorts_4_hold(renametable_rd_hold[4]),
    .io_readPorts_4_addr(renametable_rd_addr[4]),
    .io_readPorts_4_data(renametable_i_rdata[4]),
    .io_readPorts_5_hold(renametable_rd_hold[5]),
    .io_readPorts_5_addr(renametable_rd_addr[5]),
    .io_readPorts_5_data(renametable_i_rdata[5]),
    .io_readPorts_6_hold(renametable_rd_hold[6]),
    .io_readPorts_6_addr(renametable_rd_addr[6]),
    .io_readPorts_6_data(renametable_i_rdata[6]),
    .io_readPorts_7_hold(renametable_rd_hold[7]),
    .io_readPorts_7_addr(renametable_rd_addr[7]),
    .io_readPorts_7_data(renametable_i_rdata[7]),
    .io_readPorts_8_hold(renametable_rd_hold[8]),
    .io_readPorts_8_addr(renametable_rd_addr[8]),
    .io_readPorts_8_data(renametable_i_rdata[8]),
    .io_readPorts_9_hold(renametable_rd_hold[9]),
    .io_readPorts_9_addr(renametable_rd_addr[9]),
    .io_readPorts_9_data(renametable_i_rdata[9]),
    .io_readPorts_10_hold(renametable_rd_hold[10]),
    .io_readPorts_10_addr(renametable_rd_addr[10]),
    .io_readPorts_10_data(renametable_i_rdata[10]),
    .io_readPorts_11_hold(renametable_rd_hold[11]),
    .io_readPorts_11_addr(renametable_rd_addr[11]),
    .io_readPorts_11_data(renametable_i_rdata[11]),
    .io_specWritePorts_0_wen(renametable_sw_wen[0]),
    .io_specWritePorts_0_addr(renametable_sw_addr[0]),
    .io_specWritePorts_0_data(renametable_sw_data[0]),
    .io_specWritePorts_1_wen(renametable_sw_wen[1]),
    .io_specWritePorts_1_addr(renametable_sw_addr[1]),
    .io_specWritePorts_1_data(renametable_sw_data[1]),
    .io_specWritePorts_2_wen(renametable_sw_wen[2]),
    .io_specWritePorts_2_addr(renametable_sw_addr[2]),
    .io_specWritePorts_2_data(renametable_sw_data[2]),
    .io_specWritePorts_3_wen(renametable_sw_wen[3]),
    .io_specWritePorts_3_addr(renametable_sw_addr[3]),
    .io_specWritePorts_3_data(renametable_sw_data[3]),
    .io_specWritePorts_4_wen(renametable_sw_wen[4]),
    .io_specWritePorts_4_addr(renametable_sw_addr[4]),
    .io_specWritePorts_4_data(renametable_sw_data[4]),
    .io_specWritePorts_5_wen(renametable_sw_wen[5]),
    .io_specWritePorts_5_addr(renametable_sw_addr[5]),
    .io_specWritePorts_5_data(renametable_sw_data[5]),
    .io_archWritePorts_0_wen(renametable_aw_wen[0]),
    .io_archWritePorts_0_addr(renametable_aw_addr[0]),
    .io_archWritePorts_0_data(renametable_aw_data[0]),
    .io_archWritePorts_1_wen(renametable_aw_wen[1]),
    .io_archWritePorts_1_addr(renametable_aw_addr[1]),
    .io_archWritePorts_1_data(renametable_aw_data[1]),
    .io_archWritePorts_2_wen(renametable_aw_wen[2]),
    .io_archWritePorts_2_addr(renametable_aw_addr[2]),
    .io_archWritePorts_2_data(renametable_aw_data[2]),
    .io_archWritePorts_3_wen(renametable_aw_wen[3]),
    .io_archWritePorts_3_addr(renametable_aw_addr[3]),
    .io_archWritePorts_3_data(renametable_aw_data[3]),
    .io_archWritePorts_4_wen(renametable_aw_wen[4]),
    .io_archWritePorts_4_addr(renametable_aw_addr[4]),
    .io_archWritePorts_4_data(renametable_aw_data[4]),
    .io_archWritePorts_5_wen(renametable_aw_wen[5]),
    .io_archWritePorts_5_addr(renametable_aw_addr[5]),
    .io_archWritePorts_5_data(renametable_aw_data[5]),
    .io_old_pdest_0(renametable_i_oldp[0]),
    .io_old_pdest_1(renametable_i_oldp[1]),
    .io_old_pdest_2(renametable_i_oldp[2]),
    .io_old_pdest_3(renametable_i_oldp[3]),
    .io_old_pdest_4(renametable_i_oldp[4]),
    .io_old_pdest_5(renametable_i_oldp[5]),
    .io_need_free_0(renametable_i_nfree[0]),
    .io_need_free_1(renametable_i_nfree[1]),
    .io_need_free_2(renametable_i_nfree[2]),
    .io_need_free_3(renametable_i_nfree[3]),
    .io_need_free_4(renametable_i_nfree[4]),
    .io_need_free_5(renametable_i_nfree[5]),
    .io_snpt_snptEnq(renametable_snpt_enq), .io_snpt_snptDeq(renametable_snpt_deq),
    .io_snpt_useSnpt(renametable_snpt_use), .io_snpt_snptSelect(renametable_snpt_sel),
    .io_snpt_flushVec_0(renametable_snpt_flush[0]),
    .io_snpt_flushVec_1(renametable_snpt_flush[1]),
    .io_snpt_flushVec_2(renametable_snpt_flush[2]),
    .io_snpt_flushVec_3(renametable_snpt_flush[3]),
    .io_diffRatBase_0(renametable_i_diff[0]),
    .io_diffRatBase_1(renametable_i_diff[1]),
    .io_diffRatBase_2(renametable_i_diff[2]),
    .io_diffRatBase_3(renametable_i_diff[3]),
    .io_diffRatBase_4(renametable_i_diff[4]),
    .io_diffRatBase_5(renametable_i_diff[5]),
    .io_diffRatBase_6(renametable_i_diff[6]),
    .io_diffRatBase_7(renametable_i_diff[7]),
    .io_diffRatBase_8(renametable_i_diff[8]),
    .io_diffRatBase_9(renametable_i_diff[9]),
    .io_diffRatBase_10(renametable_i_diff[10]),
    .io_diffRatBase_11(renametable_i_diff[11]),
    .io_diffRatBase_12(renametable_i_diff[12]),
    .io_diffRatBase_13(renametable_i_diff[13]),
    .io_diffRatBase_14(renametable_i_diff[14]),
    .io_diffRatBase_15(renametable_i_diff[15]),
    .io_diffRatBase_16(renametable_i_diff[16]),
    .io_diffRatBase_17(renametable_i_diff[17]),
    .io_diffRatBase_18(renametable_i_diff[18]),
    .io_diffRatBase_19(renametable_i_diff[19]),
    .io_diffRatBase_20(renametable_i_diff[20]),
    .io_diffRatBase_21(renametable_i_diff[21]),
    .io_diffRatBase_22(renametable_i_diff[22]),
    .io_diffRatBase_23(renametable_i_diff[23]),
    .io_diffRatBase_24(renametable_i_diff[24]),
    .io_diffRatBase_25(renametable_i_diff[25]),
    .io_diffRatBase_26(renametable_i_diff[26]),
    .io_diffRatBase_27(renametable_i_diff[27]),
    .io_diffRatBase_28(renametable_i_diff[28]),
    .io_diffRatBase_29(renametable_i_diff[29]),
    .io_diffRatBase_30(renametable_i_diff[30]),
    .io_diffRatBase_31(renametable_i_diff[31]),
    .io_debug_rdata_0(renametable_i_dbg[0]),
    .io_debug_rdata_1(renametable_i_dbg[1]),
    .io_debug_rdata_2(renametable_i_dbg[2]),
    .io_debug_rdata_3(renametable_i_dbg[3]),
    .io_debug_rdata_4(renametable_i_dbg[4]),
    .io_debug_rdata_5(renametable_i_dbg[5]),
    .io_debug_rdata_6(renametable_i_dbg[6]),
    .io_debug_rdata_7(renametable_i_dbg[7]),
    .io_debug_rdata_8(renametable_i_dbg[8]),
    .io_debug_rdata_9(renametable_i_dbg[9]),
    .io_debug_rdata_10(renametable_i_dbg[10]),
    .io_debug_rdata_11(renametable_i_dbg[11]),
    .io_debug_rdata_12(renametable_i_dbg[12]),
    .io_debug_rdata_13(renametable_i_dbg[13]),
    .io_debug_rdata_14(renametable_i_dbg[14]),
    .io_debug_rdata_15(renametable_i_dbg[15]),
    .io_debug_rdata_16(renametable_i_dbg[16]),
    .io_debug_rdata_17(renametable_i_dbg[17]),
    .io_debug_rdata_18(renametable_i_dbg[18]),
    .io_debug_rdata_19(renametable_i_dbg[19]),
    .io_debug_rdata_20(renametable_i_dbg[20]),
    .io_debug_rdata_21(renametable_i_dbg[21]),
    .io_debug_rdata_22(renametable_i_dbg[22]),
    .io_debug_rdata_23(renametable_i_dbg[23]),
    .io_debug_rdata_24(renametable_i_dbg[24]),
    .io_debug_rdata_25(renametable_i_dbg[25]),
    .io_debug_rdata_26(renametable_i_dbg[26]),
    .io_debug_rdata_27(renametable_i_dbg[27]),
    .io_debug_rdata_28(renametable_i_dbg[28]),
    .io_debug_rdata_29(renametable_i_dbg[29]),
    .io_debug_rdata_30(renametable_i_dbg[30]),
    .io_debug_rdata_31(renametable_i_dbg[31])
  );

  // golden 的 t1_raddr 是 12 个独立 reg，打包成数组才好循环比
  logic [4:0] renametable_g_raddr [12];
  assign renametable_g_raddr[0] = renametable_g_u.t1_raddr_0;
  assign renametable_g_raddr[1] = renametable_g_u.t1_raddr_1;
  assign renametable_g_raddr[2] = renametable_g_u.t1_raddr_2;
  assign renametable_g_raddr[3] = renametable_g_u.t1_raddr_3;
  assign renametable_g_raddr[4] = renametable_g_u.t1_raddr_4;
  assign renametable_g_raddr[5] = renametable_g_u.t1_raddr_5;
  assign renametable_g_raddr[6] = renametable_g_u.t1_raddr_6;
  assign renametable_g_raddr[7] = renametable_g_u.t1_raddr_7;
  assign renametable_g_raddr[8] = renametable_g_u.t1_raddr_8;
  assign renametable_g_raddr[9] = renametable_g_u.t1_raddr_9;
  assign renametable_g_raddr[10] = renametable_g_u.t1_raddr_10;
  assign renametable_g_raddr[11] = renametable_g_u.t1_raddr_11;

  int renametable_phase, renametable_phaseCnt;
  int renametable_cov_redir, renametable_cov_use, renametable_cov_hold, renametable_cov_coll, renametable_cov_byp;
  int renametable_cov_sel [4];
  always @(negedge clk) begin
    automatic int lo;
    if (rst) begin
      renametable_redirect = 1'b0; renametable_snpt_enq = 1'b0; renametable_snpt_deq = 1'b0;
      renametable_snpt_use = 1'b0; renametable_snpt_sel = 2'h0; renametable_snpt_flush = 4'h0;
      for (int r = 0; r < 12; r++) begin
        renametable_rd_hold[r] = 1'b0;
        renametable_rd_addr[r] = '0;
      end
      for (int j = 0; j < 6; j++) begin
        renametable_sw_wen[j] = 1'b0; renametable_sw_data[j] = '0;
        renametable_aw_wen[j] = 1'b0; renametable_aw_data[j] = '0;
        renametable_sw_addr[j] = '0; renametable_aw_addr[j] = '0;
      end
      renametable_phase <= 0; renametable_phaseCnt <= 0;
    end else begin
      renametable_phaseCnt <= renametable_phaseCnt + 1;
      if (renametable_phaseCnt >= 97) begin renametable_phaseCnt <= 0; renametable_phase <= (renametable_phase + 1) % 3; end
      // 相位 0/1：把地址挤进一个很窄的窗口（lo..lo+3），制造同址撞车与旁路命中；
      // 相位 2：全域随机。窗口起点每拍重掷，保证扫遍整张表。
      lo = (renametable_phase == 2) ? 0 : $urandom_range(0, 28);
      // 暖机窗口：纯入队，把 4 个快照槽写成两侧相同的确定值（见文件头说明）。
      if (warmup) begin
        renametable_redirect = 1'b0;   renametable_snpt_enq = 1'b1;  renametable_snpt_deq = 1'b0;
        renametable_snpt_use = 1'b0;   renametable_snpt_sel = 2'h0;  renametable_snpt_flush = 4'h0;
      end else begin
        renametable_redirect = ($urandom_range(0, 99) < 4);
        renametable_snpt_enq = ($urandom_range(0, 99) < 12);
        renametable_snpt_deq = ($urandom_range(0, 99) < 10);
        renametable_snpt_use = ($urandom_range(0, 99) < 25);
        renametable_snpt_sel = 2'($urandom_range(0, 3));
        renametable_snpt_flush = 4'($urandom_range(0, 15));
      end
      for (int r = 0; r < 12; r++) begin
        renametable_rd_hold[r] = ($urandom_range(0, 99) < 30);
        renametable_rd_addr[r] = 5'((renametable_phase == 2) ? $urandom_range(0, 31)
                                          : (lo + $urandom_range(0, 3)));
      end
      for (int j = 0; j < 6; j++) begin
        renametable_sw_wen[j]  = ($urandom_range(0, 99) < 45);
        renametable_sw_data[j] = 8'($urandom_range(0, 255));
        renametable_aw_wen[j]  = ($urandom_range(0, 99) < 40);
        renametable_aw_data[j] = 8'($urandom_range(0, 15));   // 小值域，让 need_free 的
                                                      // "arch 表里一格都没有" 两种结果都出现
        renametable_sw_addr[j] = 5'((renametable_phase == 2) ? $urandom_range(0, 31)
                                          : (lo + $urandom_range(0, 3)));
        renametable_aw_addr[j] = 5'((renametable_phase == 2) ? $urandom_range(0, 31)
                                          : (lo + $urandom_range(0, 3)));
      end
    end
  end

  always @(posedge clk) if (!rst) begin
    automatic int nh, nc, nb;
    if (renametable_redirect) renametable_cov_redir++;
    if (renametable_snpt_use) renametable_cov_sel[renametable_snpt_sel]++;
    nh = 0; for (int r = 0; r < 12; r++) if (renametable_rd_hold[r]) nh++;
    if (nh > 0) renametable_cov_hold++;
    nc = 0;
    for (int j = 1; j < 6; j++)
      for (int k = 0; k < j; k++)
        if (renametable_sw_wen[j] && renametable_sw_wen[k] && renametable_sw_addr[j] == renametable_sw_addr[k]) nc++;
    if (nc > 0) renametable_cov_coll++;
    nb = 0;
    for (int r = 0; r < 12; r++)
      for (int j = 0; j < 6; j++)
        if (renametable_sw_wen[j] && renametable_sw_addr[j] == renametable_rd_addr[r]) nb++;
    if (nb > 0) renametable_cov_byp++;
  end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    for (int r = 0; r < 12; r++)
      `CHK($sformatf("RenameTable.readData[%0d]", r), renametable_g_rdata[r], renametable_i_rdata[r])
    for (int j = 0; j < 6; j++)
      `CHK($sformatf("RenameTable.old_pdest[%0d]", j), renametable_g_oldp[j], renametable_i_oldp[j])
    for (int j = 0; j < 6; j++)
      `CHK($sformatf("RenameTable.need_free[%0d]", j), renametable_g_nfree[j], renametable_i_nfree[j])
    for (int k = 0; k < 32; k++)
      `CHK($sformatf("RenameTable.diffRatBase[%0d]", k), renametable_g_diff[k], renametable_i_diff[k])
    for (int k = 0; k < 32; k++)
      `CHK($sformatf("RenameTable.debug_rdata[%0d]", k), renametable_g_dbg[k], renametable_i_dbg[k])
    // 内部状态也逐格比：输出被旁路/选择遮蔽时，表先错一步
    `CHK("RenameTable.spec_table[0]", renametable_g_u.spec_table_0, renametable_i_u.u_core.spec_table[0])
    `CHK("RenameTable.arch_table[0]", renametable_g_u.arch_table_0, renametable_i_u.u_core.arch_table[0])
    `CHK("RenameTable.spec_table[1]", renametable_g_u.spec_table_1, renametable_i_u.u_core.spec_table[1])
    `CHK("RenameTable.arch_table[1]", renametable_g_u.arch_table_1, renametable_i_u.u_core.arch_table[1])
    `CHK("RenameTable.spec_table[2]", renametable_g_u.spec_table_2, renametable_i_u.u_core.spec_table[2])
    `CHK("RenameTable.arch_table[2]", renametable_g_u.arch_table_2, renametable_i_u.u_core.arch_table[2])
    `CHK("RenameTable.spec_table[3]", renametable_g_u.spec_table_3, renametable_i_u.u_core.spec_table[3])
    `CHK("RenameTable.arch_table[3]", renametable_g_u.arch_table_3, renametable_i_u.u_core.arch_table[3])
    `CHK("RenameTable.spec_table[4]", renametable_g_u.spec_table_4, renametable_i_u.u_core.spec_table[4])
    `CHK("RenameTable.arch_table[4]", renametable_g_u.arch_table_4, renametable_i_u.u_core.arch_table[4])
    `CHK("RenameTable.spec_table[5]", renametable_g_u.spec_table_5, renametable_i_u.u_core.spec_table[5])
    `CHK("RenameTable.arch_table[5]", renametable_g_u.arch_table_5, renametable_i_u.u_core.arch_table[5])
    `CHK("RenameTable.spec_table[6]", renametable_g_u.spec_table_6, renametable_i_u.u_core.spec_table[6])
    `CHK("RenameTable.arch_table[6]", renametable_g_u.arch_table_6, renametable_i_u.u_core.arch_table[6])
    `CHK("RenameTable.spec_table[7]", renametable_g_u.spec_table_7, renametable_i_u.u_core.spec_table[7])
    `CHK("RenameTable.arch_table[7]", renametable_g_u.arch_table_7, renametable_i_u.u_core.arch_table[7])
    `CHK("RenameTable.spec_table[8]", renametable_g_u.spec_table_8, renametable_i_u.u_core.spec_table[8])
    `CHK("RenameTable.arch_table[8]", renametable_g_u.arch_table_8, renametable_i_u.u_core.arch_table[8])
    `CHK("RenameTable.spec_table[9]", renametable_g_u.spec_table_9, renametable_i_u.u_core.spec_table[9])
    `CHK("RenameTable.arch_table[9]", renametable_g_u.arch_table_9, renametable_i_u.u_core.arch_table[9])
    `CHK("RenameTable.spec_table[10]", renametable_g_u.spec_table_10, renametable_i_u.u_core.spec_table[10])
    `CHK("RenameTable.arch_table[10]", renametable_g_u.arch_table_10, renametable_i_u.u_core.arch_table[10])
    `CHK("RenameTable.spec_table[11]", renametable_g_u.spec_table_11, renametable_i_u.u_core.spec_table[11])
    `CHK("RenameTable.arch_table[11]", renametable_g_u.arch_table_11, renametable_i_u.u_core.arch_table[11])
    `CHK("RenameTable.spec_table[12]", renametable_g_u.spec_table_12, renametable_i_u.u_core.spec_table[12])
    `CHK("RenameTable.arch_table[12]", renametable_g_u.arch_table_12, renametable_i_u.u_core.arch_table[12])
    `CHK("RenameTable.spec_table[13]", renametable_g_u.spec_table_13, renametable_i_u.u_core.spec_table[13])
    `CHK("RenameTable.arch_table[13]", renametable_g_u.arch_table_13, renametable_i_u.u_core.arch_table[13])
    `CHK("RenameTable.spec_table[14]", renametable_g_u.spec_table_14, renametable_i_u.u_core.spec_table[14])
    `CHK("RenameTable.arch_table[14]", renametable_g_u.arch_table_14, renametable_i_u.u_core.arch_table[14])
    `CHK("RenameTable.spec_table[15]", renametable_g_u.spec_table_15, renametable_i_u.u_core.spec_table[15])
    `CHK("RenameTable.arch_table[15]", renametable_g_u.arch_table_15, renametable_i_u.u_core.arch_table[15])
    `CHK("RenameTable.spec_table[16]", renametable_g_u.spec_table_16, renametable_i_u.u_core.spec_table[16])
    `CHK("RenameTable.arch_table[16]", renametable_g_u.arch_table_16, renametable_i_u.u_core.arch_table[16])
    `CHK("RenameTable.spec_table[17]", renametable_g_u.spec_table_17, renametable_i_u.u_core.spec_table[17])
    `CHK("RenameTable.arch_table[17]", renametable_g_u.arch_table_17, renametable_i_u.u_core.arch_table[17])
    `CHK("RenameTable.spec_table[18]", renametable_g_u.spec_table_18, renametable_i_u.u_core.spec_table[18])
    `CHK("RenameTable.arch_table[18]", renametable_g_u.arch_table_18, renametable_i_u.u_core.arch_table[18])
    `CHK("RenameTable.spec_table[19]", renametable_g_u.spec_table_19, renametable_i_u.u_core.spec_table[19])
    `CHK("RenameTable.arch_table[19]", renametable_g_u.arch_table_19, renametable_i_u.u_core.arch_table[19])
    `CHK("RenameTable.spec_table[20]", renametable_g_u.spec_table_20, renametable_i_u.u_core.spec_table[20])
    `CHK("RenameTable.arch_table[20]", renametable_g_u.arch_table_20, renametable_i_u.u_core.arch_table[20])
    `CHK("RenameTable.spec_table[21]", renametable_g_u.spec_table_21, renametable_i_u.u_core.spec_table[21])
    `CHK("RenameTable.arch_table[21]", renametable_g_u.arch_table_21, renametable_i_u.u_core.arch_table[21])
    `CHK("RenameTable.spec_table[22]", renametable_g_u.spec_table_22, renametable_i_u.u_core.spec_table[22])
    `CHK("RenameTable.arch_table[22]", renametable_g_u.arch_table_22, renametable_i_u.u_core.arch_table[22])
    `CHK("RenameTable.spec_table[23]", renametable_g_u.spec_table_23, renametable_i_u.u_core.spec_table[23])
    `CHK("RenameTable.arch_table[23]", renametable_g_u.arch_table_23, renametable_i_u.u_core.arch_table[23])
    `CHK("RenameTable.spec_table[24]", renametable_g_u.spec_table_24, renametable_i_u.u_core.spec_table[24])
    `CHK("RenameTable.arch_table[24]", renametable_g_u.arch_table_24, renametable_i_u.u_core.arch_table[24])
    `CHK("RenameTable.spec_table[25]", renametable_g_u.spec_table_25, renametable_i_u.u_core.spec_table[25])
    `CHK("RenameTable.arch_table[25]", renametable_g_u.arch_table_25, renametable_i_u.u_core.arch_table[25])
    `CHK("RenameTable.spec_table[26]", renametable_g_u.spec_table_26, renametable_i_u.u_core.spec_table[26])
    `CHK("RenameTable.arch_table[26]", renametable_g_u.arch_table_26, renametable_i_u.u_core.arch_table[26])
    `CHK("RenameTable.spec_table[27]", renametable_g_u.spec_table_27, renametable_i_u.u_core.spec_table[27])
    `CHK("RenameTable.arch_table[27]", renametable_g_u.arch_table_27, renametable_i_u.u_core.arch_table[27])
    `CHK("RenameTable.spec_table[28]", renametable_g_u.spec_table_28, renametable_i_u.u_core.spec_table[28])
    `CHK("RenameTable.arch_table[28]", renametable_g_u.arch_table_28, renametable_i_u.u_core.arch_table[28])
    `CHK("RenameTable.spec_table[29]", renametable_g_u.spec_table_29, renametable_i_u.u_core.spec_table[29])
    `CHK("RenameTable.arch_table[29]", renametable_g_u.arch_table_29, renametable_i_u.u_core.arch_table[29])
    `CHK("RenameTable.spec_table[30]", renametable_g_u.spec_table_30, renametable_i_u.u_core.spec_table[30])
    `CHK("RenameTable.arch_table[30]", renametable_g_u.arch_table_30, renametable_i_u.u_core.arch_table[30])
    `CHK("RenameTable.spec_table[31]", renametable_g_u.spec_table_31, renametable_i_u.u_core.spec_table[31])
    `CHK("RenameTable.arch_table[31]", renametable_g_u.arch_table_31, renametable_i_u.u_core.arch_table[31])
    `CHK("RenameTable.t1_redirect", renametable_g_u.t1_redirect_last_REG, renametable_i_u.u_core.t1_redirect)
    `CHK("RenameTable.spec_redirect_q[0]", renametable_g_u.spec_table_next_0_REG,
          renametable_i_u.u_core.spec_redirect_q[0])
    `CHK("RenameTable.spec_redirect_q[31]", renametable_g_u.spec_table_next_31_REG,
          renametable_i_u.u_core.spec_redirect_q[31])
    for (int r = 0; r < 12; r++)
      `CHK($sformatf("RenameTable.t1_raddr[%0d]", r), renametable_g_raddr[r], renametable_i_u.u_core.t1_raddr[r])
  end

  // ==========================================================================
  // RenameTable_1: 34 格 / addr 6 位 / 18 读口 / need_free 无 / debug_rdata 0 格
  // ==========================================================================
  logic            renametable_1_redirect;
  logic            renametable_1_rd_hold [18];
  logic [5:0]      renametable_1_rd_addr [18];
  logic            renametable_1_sw_wen [6];
  logic [7:0]      renametable_1_sw_data [6];
  logic            renametable_1_aw_wen [6];
  logic [7:0]      renametable_1_aw_data [6];
  logic [5:0]      renametable_1_sw_addr [6];
  logic [5:0]      renametable_1_aw_addr [6];
  logic            renametable_1_snpt_enq, renametable_1_snpt_deq, renametable_1_snpt_use;
  logic [1:0]      renametable_1_snpt_sel;
  logic [3:0]      renametable_1_snpt_flush;
  logic [7:0] renametable_1_g_rdata [18];
  logic [7:0] renametable_1_g_oldp [6];
  logic       renametable_1_g_nfree [6];
  logic [7:0] renametable_1_g_diff [32];
  logic [7:0] renametable_1_i_rdata [18];
  logic [7:0] renametable_1_i_oldp [6];
  logic       renametable_1_i_nfree [6];
  logic [7:0] renametable_1_i_diff [32];

  RenameTable_1 renametable_1_g_u (
    .clock(clk), .reset(rst), .io_redirect(renametable_1_redirect),
    .io_readPorts_0_hold(renametable_1_rd_hold[0]),
    .io_readPorts_0_addr(renametable_1_rd_addr[0]),
    .io_readPorts_0_data(renametable_1_g_rdata[0]),
    .io_readPorts_1_hold(renametable_1_rd_hold[1]),
    .io_readPorts_1_addr(renametable_1_rd_addr[1]),
    .io_readPorts_1_data(renametable_1_g_rdata[1]),
    .io_readPorts_2_hold(renametable_1_rd_hold[2]),
    .io_readPorts_2_addr(renametable_1_rd_addr[2]),
    .io_readPorts_2_data(renametable_1_g_rdata[2]),
    .io_readPorts_3_hold(renametable_1_rd_hold[3]),
    .io_readPorts_3_addr(renametable_1_rd_addr[3]),
    .io_readPorts_3_data(renametable_1_g_rdata[3]),
    .io_readPorts_4_hold(renametable_1_rd_hold[4]),
    .io_readPorts_4_addr(renametable_1_rd_addr[4]),
    .io_readPorts_4_data(renametable_1_g_rdata[4]),
    .io_readPorts_5_hold(renametable_1_rd_hold[5]),
    .io_readPorts_5_addr(renametable_1_rd_addr[5]),
    .io_readPorts_5_data(renametable_1_g_rdata[5]),
    .io_readPorts_6_hold(renametable_1_rd_hold[6]),
    .io_readPorts_6_addr(renametable_1_rd_addr[6]),
    .io_readPorts_6_data(renametable_1_g_rdata[6]),
    .io_readPorts_7_hold(renametable_1_rd_hold[7]),
    .io_readPorts_7_addr(renametable_1_rd_addr[7]),
    .io_readPorts_7_data(renametable_1_g_rdata[7]),
    .io_readPorts_8_hold(renametable_1_rd_hold[8]),
    .io_readPorts_8_addr(renametable_1_rd_addr[8]),
    .io_readPorts_8_data(renametable_1_g_rdata[8]),
    .io_readPorts_9_hold(renametable_1_rd_hold[9]),
    .io_readPorts_9_addr(renametable_1_rd_addr[9]),
    .io_readPorts_9_data(renametable_1_g_rdata[9]),
    .io_readPorts_10_hold(renametable_1_rd_hold[10]),
    .io_readPorts_10_addr(renametable_1_rd_addr[10]),
    .io_readPorts_10_data(renametable_1_g_rdata[10]),
    .io_readPorts_11_hold(renametable_1_rd_hold[11]),
    .io_readPorts_11_addr(renametable_1_rd_addr[11]),
    .io_readPorts_11_data(renametable_1_g_rdata[11]),
    .io_readPorts_12_hold(renametable_1_rd_hold[12]),
    .io_readPorts_12_addr(renametable_1_rd_addr[12]),
    .io_readPorts_12_data(renametable_1_g_rdata[12]),
    .io_readPorts_13_hold(renametable_1_rd_hold[13]),
    .io_readPorts_13_addr(renametable_1_rd_addr[13]),
    .io_readPorts_13_data(renametable_1_g_rdata[13]),
    .io_readPorts_14_hold(renametable_1_rd_hold[14]),
    .io_readPorts_14_addr(renametable_1_rd_addr[14]),
    .io_readPorts_14_data(renametable_1_g_rdata[14]),
    .io_readPorts_15_hold(renametable_1_rd_hold[15]),
    .io_readPorts_15_addr(renametable_1_rd_addr[15]),
    .io_readPorts_15_data(renametable_1_g_rdata[15]),
    .io_readPorts_16_hold(renametable_1_rd_hold[16]),
    .io_readPorts_16_addr(renametable_1_rd_addr[16]),
    .io_readPorts_16_data(renametable_1_g_rdata[16]),
    .io_readPorts_17_hold(renametable_1_rd_hold[17]),
    .io_readPorts_17_addr(renametable_1_rd_addr[17]),
    .io_readPorts_17_data(renametable_1_g_rdata[17]),
    .io_specWritePorts_0_wen(renametable_1_sw_wen[0]),
    .io_specWritePorts_0_addr(renametable_1_sw_addr[0]),
    .io_specWritePorts_0_data(renametable_1_sw_data[0]),
    .io_specWritePorts_1_wen(renametable_1_sw_wen[1]),
    .io_specWritePorts_1_addr(renametable_1_sw_addr[1]),
    .io_specWritePorts_1_data(renametable_1_sw_data[1]),
    .io_specWritePorts_2_wen(renametable_1_sw_wen[2]),
    .io_specWritePorts_2_addr(renametable_1_sw_addr[2]),
    .io_specWritePorts_2_data(renametable_1_sw_data[2]),
    .io_specWritePorts_3_wen(renametable_1_sw_wen[3]),
    .io_specWritePorts_3_addr(renametable_1_sw_addr[3]),
    .io_specWritePorts_3_data(renametable_1_sw_data[3]),
    .io_specWritePorts_4_wen(renametable_1_sw_wen[4]),
    .io_specWritePorts_4_addr(renametable_1_sw_addr[4]),
    .io_specWritePorts_4_data(renametable_1_sw_data[4]),
    .io_specWritePorts_5_wen(renametable_1_sw_wen[5]),
    .io_specWritePorts_5_addr(renametable_1_sw_addr[5]),
    .io_specWritePorts_5_data(renametable_1_sw_data[5]),
    .io_archWritePorts_0_wen(renametable_1_aw_wen[0]),
    .io_archWritePorts_0_addr(renametable_1_aw_addr[0]),
    .io_archWritePorts_0_data(renametable_1_aw_data[0]),
    .io_archWritePorts_1_wen(renametable_1_aw_wen[1]),
    .io_archWritePorts_1_addr(renametable_1_aw_addr[1]),
    .io_archWritePorts_1_data(renametable_1_aw_data[1]),
    .io_archWritePorts_2_wen(renametable_1_aw_wen[2]),
    .io_archWritePorts_2_addr(renametable_1_aw_addr[2]),
    .io_archWritePorts_2_data(renametable_1_aw_data[2]),
    .io_archWritePorts_3_wen(renametable_1_aw_wen[3]),
    .io_archWritePorts_3_addr(renametable_1_aw_addr[3]),
    .io_archWritePorts_3_data(renametable_1_aw_data[3]),
    .io_archWritePorts_4_wen(renametable_1_aw_wen[4]),
    .io_archWritePorts_4_addr(renametable_1_aw_addr[4]),
    .io_archWritePorts_4_data(renametable_1_aw_data[4]),
    .io_archWritePorts_5_wen(renametable_1_aw_wen[5]),
    .io_archWritePorts_5_addr(renametable_1_aw_addr[5]),
    .io_archWritePorts_5_data(renametable_1_aw_data[5]),
    .io_old_pdest_0(renametable_1_g_oldp[0]),
    .io_old_pdest_1(renametable_1_g_oldp[1]),
    .io_old_pdest_2(renametable_1_g_oldp[2]),
    .io_old_pdest_3(renametable_1_g_oldp[3]),
    .io_old_pdest_4(renametable_1_g_oldp[4]),
    .io_old_pdest_5(renametable_1_g_oldp[5]),
    .io_snpt_snptEnq(renametable_1_snpt_enq), .io_snpt_snptDeq(renametable_1_snpt_deq),
    .io_snpt_useSnpt(renametable_1_snpt_use), .io_snpt_snptSelect(renametable_1_snpt_sel),
    .io_snpt_flushVec_0(renametable_1_snpt_flush[0]),
    .io_snpt_flushVec_1(renametable_1_snpt_flush[1]),
    .io_snpt_flushVec_2(renametable_1_snpt_flush[2]),
    .io_snpt_flushVec_3(renametable_1_snpt_flush[3]),
    .io_diffRatBase_0(renametable_1_g_diff[0]),
    .io_diffRatBase_1(renametable_1_g_diff[1]),
    .io_diffRatBase_2(renametable_1_g_diff[2]),
    .io_diffRatBase_3(renametable_1_g_diff[3]),
    .io_diffRatBase_4(renametable_1_g_diff[4]),
    .io_diffRatBase_5(renametable_1_g_diff[5]),
    .io_diffRatBase_6(renametable_1_g_diff[6]),
    .io_diffRatBase_7(renametable_1_g_diff[7]),
    .io_diffRatBase_8(renametable_1_g_diff[8]),
    .io_diffRatBase_9(renametable_1_g_diff[9]),
    .io_diffRatBase_10(renametable_1_g_diff[10]),
    .io_diffRatBase_11(renametable_1_g_diff[11]),
    .io_diffRatBase_12(renametable_1_g_diff[12]),
    .io_diffRatBase_13(renametable_1_g_diff[13]),
    .io_diffRatBase_14(renametable_1_g_diff[14]),
    .io_diffRatBase_15(renametable_1_g_diff[15]),
    .io_diffRatBase_16(renametable_1_g_diff[16]),
    .io_diffRatBase_17(renametable_1_g_diff[17]),
    .io_diffRatBase_18(renametable_1_g_diff[18]),
    .io_diffRatBase_19(renametable_1_g_diff[19]),
    .io_diffRatBase_20(renametable_1_g_diff[20]),
    .io_diffRatBase_21(renametable_1_g_diff[21]),
    .io_diffRatBase_22(renametable_1_g_diff[22]),
    .io_diffRatBase_23(renametable_1_g_diff[23]),
    .io_diffRatBase_24(renametable_1_g_diff[24]),
    .io_diffRatBase_25(renametable_1_g_diff[25]),
    .io_diffRatBase_26(renametable_1_g_diff[26]),
    .io_diffRatBase_27(renametable_1_g_diff[27]),
    .io_diffRatBase_28(renametable_1_g_diff[28]),
    .io_diffRatBase_29(renametable_1_g_diff[29]),
    .io_diffRatBase_30(renametable_1_g_diff[30]),
    .io_diffRatBase_31(renametable_1_g_diff[31])
  );
  RenameTable_1_xs renametable_1_i_u (
    .clock(clk), .reset(rst), .io_redirect(renametable_1_redirect),
    .io_readPorts_0_hold(renametable_1_rd_hold[0]),
    .io_readPorts_0_addr(renametable_1_rd_addr[0]),
    .io_readPorts_0_data(renametable_1_i_rdata[0]),
    .io_readPorts_1_hold(renametable_1_rd_hold[1]),
    .io_readPorts_1_addr(renametable_1_rd_addr[1]),
    .io_readPorts_1_data(renametable_1_i_rdata[1]),
    .io_readPorts_2_hold(renametable_1_rd_hold[2]),
    .io_readPorts_2_addr(renametable_1_rd_addr[2]),
    .io_readPorts_2_data(renametable_1_i_rdata[2]),
    .io_readPorts_3_hold(renametable_1_rd_hold[3]),
    .io_readPorts_3_addr(renametable_1_rd_addr[3]),
    .io_readPorts_3_data(renametable_1_i_rdata[3]),
    .io_readPorts_4_hold(renametable_1_rd_hold[4]),
    .io_readPorts_4_addr(renametable_1_rd_addr[4]),
    .io_readPorts_4_data(renametable_1_i_rdata[4]),
    .io_readPorts_5_hold(renametable_1_rd_hold[5]),
    .io_readPorts_5_addr(renametable_1_rd_addr[5]),
    .io_readPorts_5_data(renametable_1_i_rdata[5]),
    .io_readPorts_6_hold(renametable_1_rd_hold[6]),
    .io_readPorts_6_addr(renametable_1_rd_addr[6]),
    .io_readPorts_6_data(renametable_1_i_rdata[6]),
    .io_readPorts_7_hold(renametable_1_rd_hold[7]),
    .io_readPorts_7_addr(renametable_1_rd_addr[7]),
    .io_readPorts_7_data(renametable_1_i_rdata[7]),
    .io_readPorts_8_hold(renametable_1_rd_hold[8]),
    .io_readPorts_8_addr(renametable_1_rd_addr[8]),
    .io_readPorts_8_data(renametable_1_i_rdata[8]),
    .io_readPorts_9_hold(renametable_1_rd_hold[9]),
    .io_readPorts_9_addr(renametable_1_rd_addr[9]),
    .io_readPorts_9_data(renametable_1_i_rdata[9]),
    .io_readPorts_10_hold(renametable_1_rd_hold[10]),
    .io_readPorts_10_addr(renametable_1_rd_addr[10]),
    .io_readPorts_10_data(renametable_1_i_rdata[10]),
    .io_readPorts_11_hold(renametable_1_rd_hold[11]),
    .io_readPorts_11_addr(renametable_1_rd_addr[11]),
    .io_readPorts_11_data(renametable_1_i_rdata[11]),
    .io_readPorts_12_hold(renametable_1_rd_hold[12]),
    .io_readPorts_12_addr(renametable_1_rd_addr[12]),
    .io_readPorts_12_data(renametable_1_i_rdata[12]),
    .io_readPorts_13_hold(renametable_1_rd_hold[13]),
    .io_readPorts_13_addr(renametable_1_rd_addr[13]),
    .io_readPorts_13_data(renametable_1_i_rdata[13]),
    .io_readPorts_14_hold(renametable_1_rd_hold[14]),
    .io_readPorts_14_addr(renametable_1_rd_addr[14]),
    .io_readPorts_14_data(renametable_1_i_rdata[14]),
    .io_readPorts_15_hold(renametable_1_rd_hold[15]),
    .io_readPorts_15_addr(renametable_1_rd_addr[15]),
    .io_readPorts_15_data(renametable_1_i_rdata[15]),
    .io_readPorts_16_hold(renametable_1_rd_hold[16]),
    .io_readPorts_16_addr(renametable_1_rd_addr[16]),
    .io_readPorts_16_data(renametable_1_i_rdata[16]),
    .io_readPorts_17_hold(renametable_1_rd_hold[17]),
    .io_readPorts_17_addr(renametable_1_rd_addr[17]),
    .io_readPorts_17_data(renametable_1_i_rdata[17]),
    .io_specWritePorts_0_wen(renametable_1_sw_wen[0]),
    .io_specWritePorts_0_addr(renametable_1_sw_addr[0]),
    .io_specWritePorts_0_data(renametable_1_sw_data[0]),
    .io_specWritePorts_1_wen(renametable_1_sw_wen[1]),
    .io_specWritePorts_1_addr(renametable_1_sw_addr[1]),
    .io_specWritePorts_1_data(renametable_1_sw_data[1]),
    .io_specWritePorts_2_wen(renametable_1_sw_wen[2]),
    .io_specWritePorts_2_addr(renametable_1_sw_addr[2]),
    .io_specWritePorts_2_data(renametable_1_sw_data[2]),
    .io_specWritePorts_3_wen(renametable_1_sw_wen[3]),
    .io_specWritePorts_3_addr(renametable_1_sw_addr[3]),
    .io_specWritePorts_3_data(renametable_1_sw_data[3]),
    .io_specWritePorts_4_wen(renametable_1_sw_wen[4]),
    .io_specWritePorts_4_addr(renametable_1_sw_addr[4]),
    .io_specWritePorts_4_data(renametable_1_sw_data[4]),
    .io_specWritePorts_5_wen(renametable_1_sw_wen[5]),
    .io_specWritePorts_5_addr(renametable_1_sw_addr[5]),
    .io_specWritePorts_5_data(renametable_1_sw_data[5]),
    .io_archWritePorts_0_wen(renametable_1_aw_wen[0]),
    .io_archWritePorts_0_addr(renametable_1_aw_addr[0]),
    .io_archWritePorts_0_data(renametable_1_aw_data[0]),
    .io_archWritePorts_1_wen(renametable_1_aw_wen[1]),
    .io_archWritePorts_1_addr(renametable_1_aw_addr[1]),
    .io_archWritePorts_1_data(renametable_1_aw_data[1]),
    .io_archWritePorts_2_wen(renametable_1_aw_wen[2]),
    .io_archWritePorts_2_addr(renametable_1_aw_addr[2]),
    .io_archWritePorts_2_data(renametable_1_aw_data[2]),
    .io_archWritePorts_3_wen(renametable_1_aw_wen[3]),
    .io_archWritePorts_3_addr(renametable_1_aw_addr[3]),
    .io_archWritePorts_3_data(renametable_1_aw_data[3]),
    .io_archWritePorts_4_wen(renametable_1_aw_wen[4]),
    .io_archWritePorts_4_addr(renametable_1_aw_addr[4]),
    .io_archWritePorts_4_data(renametable_1_aw_data[4]),
    .io_archWritePorts_5_wen(renametable_1_aw_wen[5]),
    .io_archWritePorts_5_addr(renametable_1_aw_addr[5]),
    .io_archWritePorts_5_data(renametable_1_aw_data[5]),
    .io_old_pdest_0(renametable_1_i_oldp[0]),
    .io_old_pdest_1(renametable_1_i_oldp[1]),
    .io_old_pdest_2(renametable_1_i_oldp[2]),
    .io_old_pdest_3(renametable_1_i_oldp[3]),
    .io_old_pdest_4(renametable_1_i_oldp[4]),
    .io_old_pdest_5(renametable_1_i_oldp[5]),
    .io_snpt_snptEnq(renametable_1_snpt_enq), .io_snpt_snptDeq(renametable_1_snpt_deq),
    .io_snpt_useSnpt(renametable_1_snpt_use), .io_snpt_snptSelect(renametable_1_snpt_sel),
    .io_snpt_flushVec_0(renametable_1_snpt_flush[0]),
    .io_snpt_flushVec_1(renametable_1_snpt_flush[1]),
    .io_snpt_flushVec_2(renametable_1_snpt_flush[2]),
    .io_snpt_flushVec_3(renametable_1_snpt_flush[3]),
    .io_diffRatBase_0(renametable_1_i_diff[0]),
    .io_diffRatBase_1(renametable_1_i_diff[1]),
    .io_diffRatBase_2(renametable_1_i_diff[2]),
    .io_diffRatBase_3(renametable_1_i_diff[3]),
    .io_diffRatBase_4(renametable_1_i_diff[4]),
    .io_diffRatBase_5(renametable_1_i_diff[5]),
    .io_diffRatBase_6(renametable_1_i_diff[6]),
    .io_diffRatBase_7(renametable_1_i_diff[7]),
    .io_diffRatBase_8(renametable_1_i_diff[8]),
    .io_diffRatBase_9(renametable_1_i_diff[9]),
    .io_diffRatBase_10(renametable_1_i_diff[10]),
    .io_diffRatBase_11(renametable_1_i_diff[11]),
    .io_diffRatBase_12(renametable_1_i_diff[12]),
    .io_diffRatBase_13(renametable_1_i_diff[13]),
    .io_diffRatBase_14(renametable_1_i_diff[14]),
    .io_diffRatBase_15(renametable_1_i_diff[15]),
    .io_diffRatBase_16(renametable_1_i_diff[16]),
    .io_diffRatBase_17(renametable_1_i_diff[17]),
    .io_diffRatBase_18(renametable_1_i_diff[18]),
    .io_diffRatBase_19(renametable_1_i_diff[19]),
    .io_diffRatBase_20(renametable_1_i_diff[20]),
    .io_diffRatBase_21(renametable_1_i_diff[21]),
    .io_diffRatBase_22(renametable_1_i_diff[22]),
    .io_diffRatBase_23(renametable_1_i_diff[23]),
    .io_diffRatBase_24(renametable_1_i_diff[24]),
    .io_diffRatBase_25(renametable_1_i_diff[25]),
    .io_diffRatBase_26(renametable_1_i_diff[26]),
    .io_diffRatBase_27(renametable_1_i_diff[27]),
    .io_diffRatBase_28(renametable_1_i_diff[28]),
    .io_diffRatBase_29(renametable_1_i_diff[29]),
    .io_diffRatBase_30(renametable_1_i_diff[30]),
    .io_diffRatBase_31(renametable_1_i_diff[31])
  );

  // golden 的 t1_raddr 是 18 个独立 reg，打包成数组才好循环比
  logic [5:0] renametable_1_g_raddr [18];
  assign renametable_1_g_raddr[0] = renametable_1_g_u.t1_raddr_0;
  assign renametable_1_g_raddr[1] = renametable_1_g_u.t1_raddr_1;
  assign renametable_1_g_raddr[2] = renametable_1_g_u.t1_raddr_2;
  assign renametable_1_g_raddr[3] = renametable_1_g_u.t1_raddr_3;
  assign renametable_1_g_raddr[4] = renametable_1_g_u.t1_raddr_4;
  assign renametable_1_g_raddr[5] = renametable_1_g_u.t1_raddr_5;
  assign renametable_1_g_raddr[6] = renametable_1_g_u.t1_raddr_6;
  assign renametable_1_g_raddr[7] = renametable_1_g_u.t1_raddr_7;
  assign renametable_1_g_raddr[8] = renametable_1_g_u.t1_raddr_8;
  assign renametable_1_g_raddr[9] = renametable_1_g_u.t1_raddr_9;
  assign renametable_1_g_raddr[10] = renametable_1_g_u.t1_raddr_10;
  assign renametable_1_g_raddr[11] = renametable_1_g_u.t1_raddr_11;
  assign renametable_1_g_raddr[12] = renametable_1_g_u.t1_raddr_12;
  assign renametable_1_g_raddr[13] = renametable_1_g_u.t1_raddr_13;
  assign renametable_1_g_raddr[14] = renametable_1_g_u.t1_raddr_14;
  assign renametable_1_g_raddr[15] = renametable_1_g_u.t1_raddr_15;
  assign renametable_1_g_raddr[16] = renametable_1_g_u.t1_raddr_16;
  assign renametable_1_g_raddr[17] = renametable_1_g_u.t1_raddr_17;

  int renametable_1_phase, renametable_1_phaseCnt;
  int renametable_1_cov_redir, renametable_1_cov_use, renametable_1_cov_hold, renametable_1_cov_coll, renametable_1_cov_byp;
  int renametable_1_cov_sel [4];
  always @(negedge clk) begin
    automatic int lo;
    if (rst) begin
      renametable_1_redirect = 1'b0; renametable_1_snpt_enq = 1'b0; renametable_1_snpt_deq = 1'b0;
      renametable_1_snpt_use = 1'b0; renametable_1_snpt_sel = 2'h0; renametable_1_snpt_flush = 4'h0;
      for (int r = 0; r < 18; r++) begin
        renametable_1_rd_hold[r] = 1'b0;
        renametable_1_rd_addr[r] = '0;
      end
      for (int j = 0; j < 6; j++) begin
        renametable_1_sw_wen[j] = 1'b0; renametable_1_sw_data[j] = '0;
        renametable_1_aw_wen[j] = 1'b0; renametable_1_aw_data[j] = '0;
        renametable_1_sw_addr[j] = '0; renametable_1_aw_addr[j] = '0;
      end
      renametable_1_phase <= 0; renametable_1_phaseCnt <= 0;
    end else begin
      renametable_1_phaseCnt <= renametable_1_phaseCnt + 1;
      if (renametable_1_phaseCnt >= 97) begin renametable_1_phaseCnt <= 0; renametable_1_phase <= (renametable_1_phase + 1) % 3; end
      // 相位 0/1：把地址挤进一个很窄的窗口（lo..lo+3），制造同址撞车与旁路命中；
      // 相位 2：全域随机。窗口起点每拍重掷，保证扫遍整张表。
      lo = (renametable_1_phase == 2) ? 0 : $urandom_range(0, 30);
      // 暖机窗口：纯入队，把 4 个快照槽写成两侧相同的确定值（见文件头说明）。
      if (warmup) begin
        renametable_1_redirect = 1'b0;   renametable_1_snpt_enq = 1'b1;  renametable_1_snpt_deq = 1'b0;
        renametable_1_snpt_use = 1'b0;   renametable_1_snpt_sel = 2'h0;  renametable_1_snpt_flush = 4'h0;
      end else begin
        renametable_1_redirect = ($urandom_range(0, 99) < 4);
        renametable_1_snpt_enq = ($urandom_range(0, 99) < 12);
        renametable_1_snpt_deq = ($urandom_range(0, 99) < 10);
        renametable_1_snpt_use = ($urandom_range(0, 99) < 25);
        renametable_1_snpt_sel = 2'($urandom_range(0, 3));
        renametable_1_snpt_flush = 4'($urandom_range(0, 15));
      end
      for (int r = 0; r < 18; r++) begin
        renametable_1_rd_hold[r] = ($urandom_range(0, 99) < 30);
        renametable_1_rd_addr[r] = 6'((renametable_1_phase == 2) ? $urandom_range(0, 63)
                                          : (lo + $urandom_range(0, 3)));
      end
      for (int j = 0; j < 6; j++) begin
        renametable_1_sw_wen[j]  = ($urandom_range(0, 99) < 45);
        renametable_1_sw_data[j] = 8'($urandom_range(0, 255));
        renametable_1_aw_wen[j]  = ($urandom_range(0, 99) < 40);
        renametable_1_aw_data[j] = 8'($urandom_range(0, 15));   // 小值域，让 need_free 的
                                                      // "arch 表里一格都没有" 两种结果都出现
        renametable_1_sw_addr[j] = 6'((renametable_1_phase == 2) ? $urandom_range(0, 63)
                                          : (lo + $urandom_range(0, 3)));
        renametable_1_aw_addr[j] = 6'((renametable_1_phase == 2) ? $urandom_range(0, 63)
                                          : (lo + $urandom_range(0, 3)));
      end
    end
  end

  always @(posedge clk) if (!rst) begin
    automatic int nh, nc, nb;
    if (renametable_1_redirect) renametable_1_cov_redir++;
    if (renametable_1_snpt_use) renametable_1_cov_sel[renametable_1_snpt_sel]++;
    nh = 0; for (int r = 0; r < 18; r++) if (renametable_1_rd_hold[r]) nh++;
    if (nh > 0) renametable_1_cov_hold++;
    nc = 0;
    for (int j = 1; j < 6; j++)
      for (int k = 0; k < j; k++)
        if (renametable_1_sw_wen[j] && renametable_1_sw_wen[k] && renametable_1_sw_addr[j] == renametable_1_sw_addr[k]) nc++;
    if (nc > 0) renametable_1_cov_coll++;
    nb = 0;
    for (int r = 0; r < 18; r++)
      for (int j = 0; j < 6; j++)
        if (renametable_1_sw_wen[j] && renametable_1_sw_addr[j] == renametable_1_rd_addr[r]) nb++;
    if (nb > 0) renametable_1_cov_byp++;
  end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    for (int r = 0; r < 18; r++)
      `CHK($sformatf("RenameTable_1.readData[%0d]", r), renametable_1_g_rdata[r], renametable_1_i_rdata[r])
    for (int j = 0; j < 6; j++)
      `CHK($sformatf("RenameTable_1.old_pdest[%0d]", j), renametable_1_g_oldp[j], renametable_1_i_oldp[j])
    for (int k = 0; k < 32; k++)
      `CHK($sformatf("RenameTable_1.diffRatBase[%0d]", k), renametable_1_g_diff[k], renametable_1_i_diff[k])
    // 内部状态也逐格比：输出被旁路/选择遮蔽时，表先错一步
    `CHK("RenameTable_1.spec_table[0]", renametable_1_g_u.spec_table_0, renametable_1_i_u.u_core.spec_table[0])
    `CHK("RenameTable_1.arch_table[0]", renametable_1_g_u.arch_table_0, renametable_1_i_u.u_core.arch_table[0])
    `CHK("RenameTable_1.spec_table[1]", renametable_1_g_u.spec_table_1, renametable_1_i_u.u_core.spec_table[1])
    `CHK("RenameTable_1.arch_table[1]", renametable_1_g_u.arch_table_1, renametable_1_i_u.u_core.arch_table[1])
    `CHK("RenameTable_1.spec_table[2]", renametable_1_g_u.spec_table_2, renametable_1_i_u.u_core.spec_table[2])
    `CHK("RenameTable_1.arch_table[2]", renametable_1_g_u.arch_table_2, renametable_1_i_u.u_core.arch_table[2])
    `CHK("RenameTable_1.spec_table[3]", renametable_1_g_u.spec_table_3, renametable_1_i_u.u_core.spec_table[3])
    `CHK("RenameTable_1.arch_table[3]", renametable_1_g_u.arch_table_3, renametable_1_i_u.u_core.arch_table[3])
    `CHK("RenameTable_1.spec_table[4]", renametable_1_g_u.spec_table_4, renametable_1_i_u.u_core.spec_table[4])
    `CHK("RenameTable_1.arch_table[4]", renametable_1_g_u.arch_table_4, renametable_1_i_u.u_core.arch_table[4])
    `CHK("RenameTable_1.spec_table[5]", renametable_1_g_u.spec_table_5, renametable_1_i_u.u_core.spec_table[5])
    `CHK("RenameTable_1.arch_table[5]", renametable_1_g_u.arch_table_5, renametable_1_i_u.u_core.arch_table[5])
    `CHK("RenameTable_1.spec_table[6]", renametable_1_g_u.spec_table_6, renametable_1_i_u.u_core.spec_table[6])
    `CHK("RenameTable_1.arch_table[6]", renametable_1_g_u.arch_table_6, renametable_1_i_u.u_core.arch_table[6])
    `CHK("RenameTable_1.spec_table[7]", renametable_1_g_u.spec_table_7, renametable_1_i_u.u_core.spec_table[7])
    `CHK("RenameTable_1.arch_table[7]", renametable_1_g_u.arch_table_7, renametable_1_i_u.u_core.arch_table[7])
    `CHK("RenameTable_1.spec_table[8]", renametable_1_g_u.spec_table_8, renametable_1_i_u.u_core.spec_table[8])
    `CHK("RenameTable_1.arch_table[8]", renametable_1_g_u.arch_table_8, renametable_1_i_u.u_core.arch_table[8])
    `CHK("RenameTable_1.spec_table[9]", renametable_1_g_u.spec_table_9, renametable_1_i_u.u_core.spec_table[9])
    `CHK("RenameTable_1.arch_table[9]", renametable_1_g_u.arch_table_9, renametable_1_i_u.u_core.arch_table[9])
    `CHK("RenameTable_1.spec_table[10]", renametable_1_g_u.spec_table_10, renametable_1_i_u.u_core.spec_table[10])
    `CHK("RenameTable_1.arch_table[10]", renametable_1_g_u.arch_table_10, renametable_1_i_u.u_core.arch_table[10])
    `CHK("RenameTable_1.spec_table[11]", renametable_1_g_u.spec_table_11, renametable_1_i_u.u_core.spec_table[11])
    `CHK("RenameTable_1.arch_table[11]", renametable_1_g_u.arch_table_11, renametable_1_i_u.u_core.arch_table[11])
    `CHK("RenameTable_1.spec_table[12]", renametable_1_g_u.spec_table_12, renametable_1_i_u.u_core.spec_table[12])
    `CHK("RenameTable_1.arch_table[12]", renametable_1_g_u.arch_table_12, renametable_1_i_u.u_core.arch_table[12])
    `CHK("RenameTable_1.spec_table[13]", renametable_1_g_u.spec_table_13, renametable_1_i_u.u_core.spec_table[13])
    `CHK("RenameTable_1.arch_table[13]", renametable_1_g_u.arch_table_13, renametable_1_i_u.u_core.arch_table[13])
    `CHK("RenameTable_1.spec_table[14]", renametable_1_g_u.spec_table_14, renametable_1_i_u.u_core.spec_table[14])
    `CHK("RenameTable_1.arch_table[14]", renametable_1_g_u.arch_table_14, renametable_1_i_u.u_core.arch_table[14])
    `CHK("RenameTable_1.spec_table[15]", renametable_1_g_u.spec_table_15, renametable_1_i_u.u_core.spec_table[15])
    `CHK("RenameTable_1.arch_table[15]", renametable_1_g_u.arch_table_15, renametable_1_i_u.u_core.arch_table[15])
    `CHK("RenameTable_1.spec_table[16]", renametable_1_g_u.spec_table_16, renametable_1_i_u.u_core.spec_table[16])
    `CHK("RenameTable_1.arch_table[16]", renametable_1_g_u.arch_table_16, renametable_1_i_u.u_core.arch_table[16])
    `CHK("RenameTable_1.spec_table[17]", renametable_1_g_u.spec_table_17, renametable_1_i_u.u_core.spec_table[17])
    `CHK("RenameTable_1.arch_table[17]", renametable_1_g_u.arch_table_17, renametable_1_i_u.u_core.arch_table[17])
    `CHK("RenameTable_1.spec_table[18]", renametable_1_g_u.spec_table_18, renametable_1_i_u.u_core.spec_table[18])
    `CHK("RenameTable_1.arch_table[18]", renametable_1_g_u.arch_table_18, renametable_1_i_u.u_core.arch_table[18])
    `CHK("RenameTable_1.spec_table[19]", renametable_1_g_u.spec_table_19, renametable_1_i_u.u_core.spec_table[19])
    `CHK("RenameTable_1.arch_table[19]", renametable_1_g_u.arch_table_19, renametable_1_i_u.u_core.arch_table[19])
    `CHK("RenameTable_1.spec_table[20]", renametable_1_g_u.spec_table_20, renametable_1_i_u.u_core.spec_table[20])
    `CHK("RenameTable_1.arch_table[20]", renametable_1_g_u.arch_table_20, renametable_1_i_u.u_core.arch_table[20])
    `CHK("RenameTable_1.spec_table[21]", renametable_1_g_u.spec_table_21, renametable_1_i_u.u_core.spec_table[21])
    `CHK("RenameTable_1.arch_table[21]", renametable_1_g_u.arch_table_21, renametable_1_i_u.u_core.arch_table[21])
    `CHK("RenameTable_1.spec_table[22]", renametable_1_g_u.spec_table_22, renametable_1_i_u.u_core.spec_table[22])
    `CHK("RenameTable_1.arch_table[22]", renametable_1_g_u.arch_table_22, renametable_1_i_u.u_core.arch_table[22])
    `CHK("RenameTable_1.spec_table[23]", renametable_1_g_u.spec_table_23, renametable_1_i_u.u_core.spec_table[23])
    `CHK("RenameTable_1.arch_table[23]", renametable_1_g_u.arch_table_23, renametable_1_i_u.u_core.arch_table[23])
    `CHK("RenameTable_1.spec_table[24]", renametable_1_g_u.spec_table_24, renametable_1_i_u.u_core.spec_table[24])
    `CHK("RenameTable_1.arch_table[24]", renametable_1_g_u.arch_table_24, renametable_1_i_u.u_core.arch_table[24])
    `CHK("RenameTable_1.spec_table[25]", renametable_1_g_u.spec_table_25, renametable_1_i_u.u_core.spec_table[25])
    `CHK("RenameTable_1.arch_table[25]", renametable_1_g_u.arch_table_25, renametable_1_i_u.u_core.arch_table[25])
    `CHK("RenameTable_1.spec_table[26]", renametable_1_g_u.spec_table_26, renametable_1_i_u.u_core.spec_table[26])
    `CHK("RenameTable_1.arch_table[26]", renametable_1_g_u.arch_table_26, renametable_1_i_u.u_core.arch_table[26])
    `CHK("RenameTable_1.spec_table[27]", renametable_1_g_u.spec_table_27, renametable_1_i_u.u_core.spec_table[27])
    `CHK("RenameTable_1.arch_table[27]", renametable_1_g_u.arch_table_27, renametable_1_i_u.u_core.arch_table[27])
    `CHK("RenameTable_1.spec_table[28]", renametable_1_g_u.spec_table_28, renametable_1_i_u.u_core.spec_table[28])
    `CHK("RenameTable_1.arch_table[28]", renametable_1_g_u.arch_table_28, renametable_1_i_u.u_core.arch_table[28])
    `CHK("RenameTable_1.spec_table[29]", renametable_1_g_u.spec_table_29, renametable_1_i_u.u_core.spec_table[29])
    `CHK("RenameTable_1.arch_table[29]", renametable_1_g_u.arch_table_29, renametable_1_i_u.u_core.arch_table[29])
    `CHK("RenameTable_1.spec_table[30]", renametable_1_g_u.spec_table_30, renametable_1_i_u.u_core.spec_table[30])
    `CHK("RenameTable_1.arch_table[30]", renametable_1_g_u.arch_table_30, renametable_1_i_u.u_core.arch_table[30])
    `CHK("RenameTable_1.spec_table[31]", renametable_1_g_u.spec_table_31, renametable_1_i_u.u_core.spec_table[31])
    `CHK("RenameTable_1.arch_table[31]", renametable_1_g_u.arch_table_31, renametable_1_i_u.u_core.arch_table[31])
    `CHK("RenameTable_1.spec_table[32]", renametable_1_g_u.spec_table_32, renametable_1_i_u.u_core.spec_table[32])
    `CHK("RenameTable_1.arch_table[32]", renametable_1_g_u.arch_table_32, renametable_1_i_u.u_core.arch_table[32])
    `CHK("RenameTable_1.spec_table[33]", renametable_1_g_u.spec_table_33, renametable_1_i_u.u_core.spec_table[33])
    `CHK("RenameTable_1.arch_table[33]", renametable_1_g_u.arch_table_33, renametable_1_i_u.u_core.arch_table[33])
    `CHK("RenameTable_1.t1_redirect", renametable_1_g_u.t1_redirect_last_REG, renametable_1_i_u.u_core.t1_redirect)
    `CHK("RenameTable_1.spec_redirect_q[0]", renametable_1_g_u.spec_table_next_0_REG,
          renametable_1_i_u.u_core.spec_redirect_q[0])
    `CHK("RenameTable_1.spec_redirect_q[33]", renametable_1_g_u.spec_table_next_33_REG,
          renametable_1_i_u.u_core.spec_redirect_q[33])
    for (int r = 0; r < 18; r++)
      `CHK($sformatf("RenameTable_1.t1_raddr[%0d]", r), renametable_1_g_raddr[r], renametable_1_i_u.u_core.t1_raddr[r])
  end

  // ==========================================================================
  // RenameTable_2: 47 格 / addr 6 位 / 18 读口 / need_free 有 / debug_rdata 31 格
  // ==========================================================================
  logic            renametable_2_redirect;
  logic            renametable_2_rd_hold [18];
  logic [5:0]      renametable_2_rd_addr [18];
  logic            renametable_2_sw_wen [6];
  logic [7:0]      renametable_2_sw_data [6];
  logic            renametable_2_aw_wen [6];
  logic [7:0]      renametable_2_aw_data [6];
  logic [5:0]      renametable_2_sw_addr [6];
  logic [5:0]      renametable_2_aw_addr [6];
  logic            renametable_2_snpt_enq, renametable_2_snpt_deq, renametable_2_snpt_use;
  logic [1:0]      renametable_2_snpt_sel;
  logic [3:0]      renametable_2_snpt_flush;
  logic [7:0] renametable_2_g_rdata [18];
  logic [7:0] renametable_2_g_oldp [6];
  logic       renametable_2_g_nfree [6];
  logic [7:0] renametable_2_g_diff [31];
  logic [7:0] renametable_2_g_dbg [31];
  logic [7:0] renametable_2_i_rdata [18];
  logic [7:0] renametable_2_i_oldp [6];
  logic       renametable_2_i_nfree [6];
  logic [7:0] renametable_2_i_diff [31];
  logic [7:0] renametable_2_i_dbg [31];

  RenameTable_2 renametable_2_g_u (
    .clock(clk), .reset(rst), .io_redirect(renametable_2_redirect),
    .io_readPorts_0_hold(renametable_2_rd_hold[0]),
    .io_readPorts_0_addr(renametable_2_rd_addr[0]),
    .io_readPorts_0_data(renametable_2_g_rdata[0]),
    .io_readPorts_1_hold(renametable_2_rd_hold[1]),
    .io_readPorts_1_addr(renametable_2_rd_addr[1]),
    .io_readPorts_1_data(renametable_2_g_rdata[1]),
    .io_readPorts_2_hold(renametable_2_rd_hold[2]),
    .io_readPorts_2_addr(renametable_2_rd_addr[2]),
    .io_readPorts_2_data(renametable_2_g_rdata[2]),
    .io_readPorts_3_hold(renametable_2_rd_hold[3]),
    .io_readPorts_3_addr(renametable_2_rd_addr[3]),
    .io_readPorts_3_data(renametable_2_g_rdata[3]),
    .io_readPorts_4_hold(renametable_2_rd_hold[4]),
    .io_readPorts_4_addr(renametable_2_rd_addr[4]),
    .io_readPorts_4_data(renametable_2_g_rdata[4]),
    .io_readPorts_5_hold(renametable_2_rd_hold[5]),
    .io_readPorts_5_addr(renametable_2_rd_addr[5]),
    .io_readPorts_5_data(renametable_2_g_rdata[5]),
    .io_readPorts_6_hold(renametable_2_rd_hold[6]),
    .io_readPorts_6_addr(renametable_2_rd_addr[6]),
    .io_readPorts_6_data(renametable_2_g_rdata[6]),
    .io_readPorts_7_hold(renametable_2_rd_hold[7]),
    .io_readPorts_7_addr(renametable_2_rd_addr[7]),
    .io_readPorts_7_data(renametable_2_g_rdata[7]),
    .io_readPorts_8_hold(renametable_2_rd_hold[8]),
    .io_readPorts_8_addr(renametable_2_rd_addr[8]),
    .io_readPorts_8_data(renametable_2_g_rdata[8]),
    .io_readPorts_9_hold(renametable_2_rd_hold[9]),
    .io_readPorts_9_addr(renametable_2_rd_addr[9]),
    .io_readPorts_9_data(renametable_2_g_rdata[9]),
    .io_readPorts_10_hold(renametable_2_rd_hold[10]),
    .io_readPorts_10_addr(renametable_2_rd_addr[10]),
    .io_readPorts_10_data(renametable_2_g_rdata[10]),
    .io_readPorts_11_hold(renametable_2_rd_hold[11]),
    .io_readPorts_11_addr(renametable_2_rd_addr[11]),
    .io_readPorts_11_data(renametable_2_g_rdata[11]),
    .io_readPorts_12_hold(renametable_2_rd_hold[12]),
    .io_readPorts_12_addr(renametable_2_rd_addr[12]),
    .io_readPorts_12_data(renametable_2_g_rdata[12]),
    .io_readPorts_13_hold(renametable_2_rd_hold[13]),
    .io_readPorts_13_addr(renametable_2_rd_addr[13]),
    .io_readPorts_13_data(renametable_2_g_rdata[13]),
    .io_readPorts_14_hold(renametable_2_rd_hold[14]),
    .io_readPorts_14_addr(renametable_2_rd_addr[14]),
    .io_readPorts_14_data(renametable_2_g_rdata[14]),
    .io_readPorts_15_hold(renametable_2_rd_hold[15]),
    .io_readPorts_15_addr(renametable_2_rd_addr[15]),
    .io_readPorts_15_data(renametable_2_g_rdata[15]),
    .io_readPorts_16_hold(renametable_2_rd_hold[16]),
    .io_readPorts_16_addr(renametable_2_rd_addr[16]),
    .io_readPorts_16_data(renametable_2_g_rdata[16]),
    .io_readPorts_17_hold(renametable_2_rd_hold[17]),
    .io_readPorts_17_addr(renametable_2_rd_addr[17]),
    .io_readPorts_17_data(renametable_2_g_rdata[17]),
    .io_specWritePorts_0_wen(renametable_2_sw_wen[0]),
    .io_specWritePorts_0_addr(renametable_2_sw_addr[0]),
    .io_specWritePorts_0_data(renametable_2_sw_data[0]),
    .io_specWritePorts_1_wen(renametable_2_sw_wen[1]),
    .io_specWritePorts_1_addr(renametable_2_sw_addr[1]),
    .io_specWritePorts_1_data(renametable_2_sw_data[1]),
    .io_specWritePorts_2_wen(renametable_2_sw_wen[2]),
    .io_specWritePorts_2_addr(renametable_2_sw_addr[2]),
    .io_specWritePorts_2_data(renametable_2_sw_data[2]),
    .io_specWritePorts_3_wen(renametable_2_sw_wen[3]),
    .io_specWritePorts_3_addr(renametable_2_sw_addr[3]),
    .io_specWritePorts_3_data(renametable_2_sw_data[3]),
    .io_specWritePorts_4_wen(renametable_2_sw_wen[4]),
    .io_specWritePorts_4_addr(renametable_2_sw_addr[4]),
    .io_specWritePorts_4_data(renametable_2_sw_data[4]),
    .io_specWritePorts_5_wen(renametable_2_sw_wen[5]),
    .io_specWritePorts_5_addr(renametable_2_sw_addr[5]),
    .io_specWritePorts_5_data(renametable_2_sw_data[5]),
    .io_archWritePorts_0_wen(renametable_2_aw_wen[0]),
    .io_archWritePorts_0_addr(renametable_2_aw_addr[0]),
    .io_archWritePorts_0_data(renametable_2_aw_data[0]),
    .io_archWritePorts_1_wen(renametable_2_aw_wen[1]),
    .io_archWritePorts_1_addr(renametable_2_aw_addr[1]),
    .io_archWritePorts_1_data(renametable_2_aw_data[1]),
    .io_archWritePorts_2_wen(renametable_2_aw_wen[2]),
    .io_archWritePorts_2_addr(renametable_2_aw_addr[2]),
    .io_archWritePorts_2_data(renametable_2_aw_data[2]),
    .io_archWritePorts_3_wen(renametable_2_aw_wen[3]),
    .io_archWritePorts_3_addr(renametable_2_aw_addr[3]),
    .io_archWritePorts_3_data(renametable_2_aw_data[3]),
    .io_archWritePorts_4_wen(renametable_2_aw_wen[4]),
    .io_archWritePorts_4_addr(renametable_2_aw_addr[4]),
    .io_archWritePorts_4_data(renametable_2_aw_data[4]),
    .io_archWritePorts_5_wen(renametable_2_aw_wen[5]),
    .io_archWritePorts_5_addr(renametable_2_aw_addr[5]),
    .io_archWritePorts_5_data(renametable_2_aw_data[5]),
    .io_old_pdest_0(renametable_2_g_oldp[0]),
    .io_old_pdest_1(renametable_2_g_oldp[1]),
    .io_old_pdest_2(renametable_2_g_oldp[2]),
    .io_old_pdest_3(renametable_2_g_oldp[3]),
    .io_old_pdest_4(renametable_2_g_oldp[4]),
    .io_old_pdest_5(renametable_2_g_oldp[5]),
    .io_need_free_0(renametable_2_g_nfree[0]),
    .io_need_free_1(renametable_2_g_nfree[1]),
    .io_need_free_2(renametable_2_g_nfree[2]),
    .io_need_free_3(renametable_2_g_nfree[3]),
    .io_need_free_4(renametable_2_g_nfree[4]),
    .io_need_free_5(renametable_2_g_nfree[5]),
    .io_snpt_snptEnq(renametable_2_snpt_enq), .io_snpt_snptDeq(renametable_2_snpt_deq),
    .io_snpt_useSnpt(renametable_2_snpt_use), .io_snpt_snptSelect(renametable_2_snpt_sel),
    .io_snpt_flushVec_0(renametable_2_snpt_flush[0]),
    .io_snpt_flushVec_1(renametable_2_snpt_flush[1]),
    .io_snpt_flushVec_2(renametable_2_snpt_flush[2]),
    .io_snpt_flushVec_3(renametable_2_snpt_flush[3]),
    .io_diffRatBase_0(renametable_2_g_diff[0]),
    .io_diffRatBase_1(renametable_2_g_diff[1]),
    .io_diffRatBase_2(renametable_2_g_diff[2]),
    .io_diffRatBase_3(renametable_2_g_diff[3]),
    .io_diffRatBase_4(renametable_2_g_diff[4]),
    .io_diffRatBase_5(renametable_2_g_diff[5]),
    .io_diffRatBase_6(renametable_2_g_diff[6]),
    .io_diffRatBase_7(renametable_2_g_diff[7]),
    .io_diffRatBase_8(renametable_2_g_diff[8]),
    .io_diffRatBase_9(renametable_2_g_diff[9]),
    .io_diffRatBase_10(renametable_2_g_diff[10]),
    .io_diffRatBase_11(renametable_2_g_diff[11]),
    .io_diffRatBase_12(renametable_2_g_diff[12]),
    .io_diffRatBase_13(renametable_2_g_diff[13]),
    .io_diffRatBase_14(renametable_2_g_diff[14]),
    .io_diffRatBase_15(renametable_2_g_diff[15]),
    .io_diffRatBase_16(renametable_2_g_diff[16]),
    .io_diffRatBase_17(renametable_2_g_diff[17]),
    .io_diffRatBase_18(renametable_2_g_diff[18]),
    .io_diffRatBase_19(renametable_2_g_diff[19]),
    .io_diffRatBase_20(renametable_2_g_diff[20]),
    .io_diffRatBase_21(renametable_2_g_diff[21]),
    .io_diffRatBase_22(renametable_2_g_diff[22]),
    .io_diffRatBase_23(renametable_2_g_diff[23]),
    .io_diffRatBase_24(renametable_2_g_diff[24]),
    .io_diffRatBase_25(renametable_2_g_diff[25]),
    .io_diffRatBase_26(renametable_2_g_diff[26]),
    .io_diffRatBase_27(renametable_2_g_diff[27]),
    .io_diffRatBase_28(renametable_2_g_diff[28]),
    .io_diffRatBase_29(renametable_2_g_diff[29]),
    .io_diffRatBase_30(renametable_2_g_diff[30]),
    .io_debug_rdata_0(renametable_2_g_dbg[0]),
    .io_debug_rdata_1(renametable_2_g_dbg[1]),
    .io_debug_rdata_2(renametable_2_g_dbg[2]),
    .io_debug_rdata_3(renametable_2_g_dbg[3]),
    .io_debug_rdata_4(renametable_2_g_dbg[4]),
    .io_debug_rdata_5(renametable_2_g_dbg[5]),
    .io_debug_rdata_6(renametable_2_g_dbg[6]),
    .io_debug_rdata_7(renametable_2_g_dbg[7]),
    .io_debug_rdata_8(renametable_2_g_dbg[8]),
    .io_debug_rdata_9(renametable_2_g_dbg[9]),
    .io_debug_rdata_10(renametable_2_g_dbg[10]),
    .io_debug_rdata_11(renametable_2_g_dbg[11]),
    .io_debug_rdata_12(renametable_2_g_dbg[12]),
    .io_debug_rdata_13(renametable_2_g_dbg[13]),
    .io_debug_rdata_14(renametable_2_g_dbg[14]),
    .io_debug_rdata_15(renametable_2_g_dbg[15]),
    .io_debug_rdata_16(renametable_2_g_dbg[16]),
    .io_debug_rdata_17(renametable_2_g_dbg[17]),
    .io_debug_rdata_18(renametable_2_g_dbg[18]),
    .io_debug_rdata_19(renametable_2_g_dbg[19]),
    .io_debug_rdata_20(renametable_2_g_dbg[20]),
    .io_debug_rdata_21(renametable_2_g_dbg[21]),
    .io_debug_rdata_22(renametable_2_g_dbg[22]),
    .io_debug_rdata_23(renametable_2_g_dbg[23]),
    .io_debug_rdata_24(renametable_2_g_dbg[24]),
    .io_debug_rdata_25(renametable_2_g_dbg[25]),
    .io_debug_rdata_26(renametable_2_g_dbg[26]),
    .io_debug_rdata_27(renametable_2_g_dbg[27]),
    .io_debug_rdata_28(renametable_2_g_dbg[28]),
    .io_debug_rdata_29(renametable_2_g_dbg[29]),
    .io_debug_rdata_30(renametable_2_g_dbg[30])
  );
  RenameTable_2_xs renametable_2_i_u (
    .clock(clk), .reset(rst), .io_redirect(renametable_2_redirect),
    .io_readPorts_0_hold(renametable_2_rd_hold[0]),
    .io_readPorts_0_addr(renametable_2_rd_addr[0]),
    .io_readPorts_0_data(renametable_2_i_rdata[0]),
    .io_readPorts_1_hold(renametable_2_rd_hold[1]),
    .io_readPorts_1_addr(renametable_2_rd_addr[1]),
    .io_readPorts_1_data(renametable_2_i_rdata[1]),
    .io_readPorts_2_hold(renametable_2_rd_hold[2]),
    .io_readPorts_2_addr(renametable_2_rd_addr[2]),
    .io_readPorts_2_data(renametable_2_i_rdata[2]),
    .io_readPorts_3_hold(renametable_2_rd_hold[3]),
    .io_readPorts_3_addr(renametable_2_rd_addr[3]),
    .io_readPorts_3_data(renametable_2_i_rdata[3]),
    .io_readPorts_4_hold(renametable_2_rd_hold[4]),
    .io_readPorts_4_addr(renametable_2_rd_addr[4]),
    .io_readPorts_4_data(renametable_2_i_rdata[4]),
    .io_readPorts_5_hold(renametable_2_rd_hold[5]),
    .io_readPorts_5_addr(renametable_2_rd_addr[5]),
    .io_readPorts_5_data(renametable_2_i_rdata[5]),
    .io_readPorts_6_hold(renametable_2_rd_hold[6]),
    .io_readPorts_6_addr(renametable_2_rd_addr[6]),
    .io_readPorts_6_data(renametable_2_i_rdata[6]),
    .io_readPorts_7_hold(renametable_2_rd_hold[7]),
    .io_readPorts_7_addr(renametable_2_rd_addr[7]),
    .io_readPorts_7_data(renametable_2_i_rdata[7]),
    .io_readPorts_8_hold(renametable_2_rd_hold[8]),
    .io_readPorts_8_addr(renametable_2_rd_addr[8]),
    .io_readPorts_8_data(renametable_2_i_rdata[8]),
    .io_readPorts_9_hold(renametable_2_rd_hold[9]),
    .io_readPorts_9_addr(renametable_2_rd_addr[9]),
    .io_readPorts_9_data(renametable_2_i_rdata[9]),
    .io_readPorts_10_hold(renametable_2_rd_hold[10]),
    .io_readPorts_10_addr(renametable_2_rd_addr[10]),
    .io_readPorts_10_data(renametable_2_i_rdata[10]),
    .io_readPorts_11_hold(renametable_2_rd_hold[11]),
    .io_readPorts_11_addr(renametable_2_rd_addr[11]),
    .io_readPorts_11_data(renametable_2_i_rdata[11]),
    .io_readPorts_12_hold(renametable_2_rd_hold[12]),
    .io_readPorts_12_addr(renametable_2_rd_addr[12]),
    .io_readPorts_12_data(renametable_2_i_rdata[12]),
    .io_readPorts_13_hold(renametable_2_rd_hold[13]),
    .io_readPorts_13_addr(renametable_2_rd_addr[13]),
    .io_readPorts_13_data(renametable_2_i_rdata[13]),
    .io_readPorts_14_hold(renametable_2_rd_hold[14]),
    .io_readPorts_14_addr(renametable_2_rd_addr[14]),
    .io_readPorts_14_data(renametable_2_i_rdata[14]),
    .io_readPorts_15_hold(renametable_2_rd_hold[15]),
    .io_readPorts_15_addr(renametable_2_rd_addr[15]),
    .io_readPorts_15_data(renametable_2_i_rdata[15]),
    .io_readPorts_16_hold(renametable_2_rd_hold[16]),
    .io_readPorts_16_addr(renametable_2_rd_addr[16]),
    .io_readPorts_16_data(renametable_2_i_rdata[16]),
    .io_readPorts_17_hold(renametable_2_rd_hold[17]),
    .io_readPorts_17_addr(renametable_2_rd_addr[17]),
    .io_readPorts_17_data(renametable_2_i_rdata[17]),
    .io_specWritePorts_0_wen(renametable_2_sw_wen[0]),
    .io_specWritePorts_0_addr(renametable_2_sw_addr[0]),
    .io_specWritePorts_0_data(renametable_2_sw_data[0]),
    .io_specWritePorts_1_wen(renametable_2_sw_wen[1]),
    .io_specWritePorts_1_addr(renametable_2_sw_addr[1]),
    .io_specWritePorts_1_data(renametable_2_sw_data[1]),
    .io_specWritePorts_2_wen(renametable_2_sw_wen[2]),
    .io_specWritePorts_2_addr(renametable_2_sw_addr[2]),
    .io_specWritePorts_2_data(renametable_2_sw_data[2]),
    .io_specWritePorts_3_wen(renametable_2_sw_wen[3]),
    .io_specWritePorts_3_addr(renametable_2_sw_addr[3]),
    .io_specWritePorts_3_data(renametable_2_sw_data[3]),
    .io_specWritePorts_4_wen(renametable_2_sw_wen[4]),
    .io_specWritePorts_4_addr(renametable_2_sw_addr[4]),
    .io_specWritePorts_4_data(renametable_2_sw_data[4]),
    .io_specWritePorts_5_wen(renametable_2_sw_wen[5]),
    .io_specWritePorts_5_addr(renametable_2_sw_addr[5]),
    .io_specWritePorts_5_data(renametable_2_sw_data[5]),
    .io_archWritePorts_0_wen(renametable_2_aw_wen[0]),
    .io_archWritePorts_0_addr(renametable_2_aw_addr[0]),
    .io_archWritePorts_0_data(renametable_2_aw_data[0]),
    .io_archWritePorts_1_wen(renametable_2_aw_wen[1]),
    .io_archWritePorts_1_addr(renametable_2_aw_addr[1]),
    .io_archWritePorts_1_data(renametable_2_aw_data[1]),
    .io_archWritePorts_2_wen(renametable_2_aw_wen[2]),
    .io_archWritePorts_2_addr(renametable_2_aw_addr[2]),
    .io_archWritePorts_2_data(renametable_2_aw_data[2]),
    .io_archWritePorts_3_wen(renametable_2_aw_wen[3]),
    .io_archWritePorts_3_addr(renametable_2_aw_addr[3]),
    .io_archWritePorts_3_data(renametable_2_aw_data[3]),
    .io_archWritePorts_4_wen(renametable_2_aw_wen[4]),
    .io_archWritePorts_4_addr(renametable_2_aw_addr[4]),
    .io_archWritePorts_4_data(renametable_2_aw_data[4]),
    .io_archWritePorts_5_wen(renametable_2_aw_wen[5]),
    .io_archWritePorts_5_addr(renametable_2_aw_addr[5]),
    .io_archWritePorts_5_data(renametable_2_aw_data[5]),
    .io_old_pdest_0(renametable_2_i_oldp[0]),
    .io_old_pdest_1(renametable_2_i_oldp[1]),
    .io_old_pdest_2(renametable_2_i_oldp[2]),
    .io_old_pdest_3(renametable_2_i_oldp[3]),
    .io_old_pdest_4(renametable_2_i_oldp[4]),
    .io_old_pdest_5(renametable_2_i_oldp[5]),
    .io_need_free_0(renametable_2_i_nfree[0]),
    .io_need_free_1(renametable_2_i_nfree[1]),
    .io_need_free_2(renametable_2_i_nfree[2]),
    .io_need_free_3(renametable_2_i_nfree[3]),
    .io_need_free_4(renametable_2_i_nfree[4]),
    .io_need_free_5(renametable_2_i_nfree[5]),
    .io_snpt_snptEnq(renametable_2_snpt_enq), .io_snpt_snptDeq(renametable_2_snpt_deq),
    .io_snpt_useSnpt(renametable_2_snpt_use), .io_snpt_snptSelect(renametable_2_snpt_sel),
    .io_snpt_flushVec_0(renametable_2_snpt_flush[0]),
    .io_snpt_flushVec_1(renametable_2_snpt_flush[1]),
    .io_snpt_flushVec_2(renametable_2_snpt_flush[2]),
    .io_snpt_flushVec_3(renametable_2_snpt_flush[3]),
    .io_diffRatBase_0(renametable_2_i_diff[0]),
    .io_diffRatBase_1(renametable_2_i_diff[1]),
    .io_diffRatBase_2(renametable_2_i_diff[2]),
    .io_diffRatBase_3(renametable_2_i_diff[3]),
    .io_diffRatBase_4(renametable_2_i_diff[4]),
    .io_diffRatBase_5(renametable_2_i_diff[5]),
    .io_diffRatBase_6(renametable_2_i_diff[6]),
    .io_diffRatBase_7(renametable_2_i_diff[7]),
    .io_diffRatBase_8(renametable_2_i_diff[8]),
    .io_diffRatBase_9(renametable_2_i_diff[9]),
    .io_diffRatBase_10(renametable_2_i_diff[10]),
    .io_diffRatBase_11(renametable_2_i_diff[11]),
    .io_diffRatBase_12(renametable_2_i_diff[12]),
    .io_diffRatBase_13(renametable_2_i_diff[13]),
    .io_diffRatBase_14(renametable_2_i_diff[14]),
    .io_diffRatBase_15(renametable_2_i_diff[15]),
    .io_diffRatBase_16(renametable_2_i_diff[16]),
    .io_diffRatBase_17(renametable_2_i_diff[17]),
    .io_diffRatBase_18(renametable_2_i_diff[18]),
    .io_diffRatBase_19(renametable_2_i_diff[19]),
    .io_diffRatBase_20(renametable_2_i_diff[20]),
    .io_diffRatBase_21(renametable_2_i_diff[21]),
    .io_diffRatBase_22(renametable_2_i_diff[22]),
    .io_diffRatBase_23(renametable_2_i_diff[23]),
    .io_diffRatBase_24(renametable_2_i_diff[24]),
    .io_diffRatBase_25(renametable_2_i_diff[25]),
    .io_diffRatBase_26(renametable_2_i_diff[26]),
    .io_diffRatBase_27(renametable_2_i_diff[27]),
    .io_diffRatBase_28(renametable_2_i_diff[28]),
    .io_diffRatBase_29(renametable_2_i_diff[29]),
    .io_diffRatBase_30(renametable_2_i_diff[30]),
    .io_debug_rdata_0(renametable_2_i_dbg[0]),
    .io_debug_rdata_1(renametable_2_i_dbg[1]),
    .io_debug_rdata_2(renametable_2_i_dbg[2]),
    .io_debug_rdata_3(renametable_2_i_dbg[3]),
    .io_debug_rdata_4(renametable_2_i_dbg[4]),
    .io_debug_rdata_5(renametable_2_i_dbg[5]),
    .io_debug_rdata_6(renametable_2_i_dbg[6]),
    .io_debug_rdata_7(renametable_2_i_dbg[7]),
    .io_debug_rdata_8(renametable_2_i_dbg[8]),
    .io_debug_rdata_9(renametable_2_i_dbg[9]),
    .io_debug_rdata_10(renametable_2_i_dbg[10]),
    .io_debug_rdata_11(renametable_2_i_dbg[11]),
    .io_debug_rdata_12(renametable_2_i_dbg[12]),
    .io_debug_rdata_13(renametable_2_i_dbg[13]),
    .io_debug_rdata_14(renametable_2_i_dbg[14]),
    .io_debug_rdata_15(renametable_2_i_dbg[15]),
    .io_debug_rdata_16(renametable_2_i_dbg[16]),
    .io_debug_rdata_17(renametable_2_i_dbg[17]),
    .io_debug_rdata_18(renametable_2_i_dbg[18]),
    .io_debug_rdata_19(renametable_2_i_dbg[19]),
    .io_debug_rdata_20(renametable_2_i_dbg[20]),
    .io_debug_rdata_21(renametable_2_i_dbg[21]),
    .io_debug_rdata_22(renametable_2_i_dbg[22]),
    .io_debug_rdata_23(renametable_2_i_dbg[23]),
    .io_debug_rdata_24(renametable_2_i_dbg[24]),
    .io_debug_rdata_25(renametable_2_i_dbg[25]),
    .io_debug_rdata_26(renametable_2_i_dbg[26]),
    .io_debug_rdata_27(renametable_2_i_dbg[27]),
    .io_debug_rdata_28(renametable_2_i_dbg[28]),
    .io_debug_rdata_29(renametable_2_i_dbg[29]),
    .io_debug_rdata_30(renametable_2_i_dbg[30])
  );

  // golden 的 t1_raddr 是 18 个独立 reg，打包成数组才好循环比
  logic [5:0] renametable_2_g_raddr [18];
  assign renametable_2_g_raddr[0] = renametable_2_g_u.t1_raddr_0;
  assign renametable_2_g_raddr[1] = renametable_2_g_u.t1_raddr_1;
  assign renametable_2_g_raddr[2] = renametable_2_g_u.t1_raddr_2;
  assign renametable_2_g_raddr[3] = renametable_2_g_u.t1_raddr_3;
  assign renametable_2_g_raddr[4] = renametable_2_g_u.t1_raddr_4;
  assign renametable_2_g_raddr[5] = renametable_2_g_u.t1_raddr_5;
  assign renametable_2_g_raddr[6] = renametable_2_g_u.t1_raddr_6;
  assign renametable_2_g_raddr[7] = renametable_2_g_u.t1_raddr_7;
  assign renametable_2_g_raddr[8] = renametable_2_g_u.t1_raddr_8;
  assign renametable_2_g_raddr[9] = renametable_2_g_u.t1_raddr_9;
  assign renametable_2_g_raddr[10] = renametable_2_g_u.t1_raddr_10;
  assign renametable_2_g_raddr[11] = renametable_2_g_u.t1_raddr_11;
  assign renametable_2_g_raddr[12] = renametable_2_g_u.t1_raddr_12;
  assign renametable_2_g_raddr[13] = renametable_2_g_u.t1_raddr_13;
  assign renametable_2_g_raddr[14] = renametable_2_g_u.t1_raddr_14;
  assign renametable_2_g_raddr[15] = renametable_2_g_u.t1_raddr_15;
  assign renametable_2_g_raddr[16] = renametable_2_g_u.t1_raddr_16;
  assign renametable_2_g_raddr[17] = renametable_2_g_u.t1_raddr_17;

  int renametable_2_phase, renametable_2_phaseCnt;
  int renametable_2_cov_redir, renametable_2_cov_use, renametable_2_cov_hold, renametable_2_cov_coll, renametable_2_cov_byp;
  int renametable_2_cov_sel [4];
  always @(negedge clk) begin
    automatic int lo;
    if (rst) begin
      renametable_2_redirect = 1'b0; renametable_2_snpt_enq = 1'b0; renametable_2_snpt_deq = 1'b0;
      renametable_2_snpt_use = 1'b0; renametable_2_snpt_sel = 2'h0; renametable_2_snpt_flush = 4'h0;
      for (int r = 0; r < 18; r++) begin
        renametable_2_rd_hold[r] = 1'b0;
        renametable_2_rd_addr[r] = '0;
      end
      for (int j = 0; j < 6; j++) begin
        renametable_2_sw_wen[j] = 1'b0; renametable_2_sw_data[j] = '0;
        renametable_2_aw_wen[j] = 1'b0; renametable_2_aw_data[j] = '0;
        renametable_2_sw_addr[j] = '0; renametable_2_aw_addr[j] = '0;
      end
      renametable_2_phase <= 0; renametable_2_phaseCnt <= 0;
    end else begin
      renametable_2_phaseCnt <= renametable_2_phaseCnt + 1;
      if (renametable_2_phaseCnt >= 97) begin renametable_2_phaseCnt <= 0; renametable_2_phase <= (renametable_2_phase + 1) % 3; end
      // 相位 0/1：把地址挤进一个很窄的窗口（lo..lo+3），制造同址撞车与旁路命中；
      // 相位 2：全域随机。窗口起点每拍重掷，保证扫遍整张表。
      lo = (renametable_2_phase == 2) ? 0 : $urandom_range(0, 43);
      // 暖机窗口：纯入队，把 4 个快照槽写成两侧相同的确定值（见文件头说明）。
      if (warmup) begin
        renametable_2_redirect = 1'b0;   renametable_2_snpt_enq = 1'b1;  renametable_2_snpt_deq = 1'b0;
        renametable_2_snpt_use = 1'b0;   renametable_2_snpt_sel = 2'h0;  renametable_2_snpt_flush = 4'h0;
      end else begin
        renametable_2_redirect = ($urandom_range(0, 99) < 4);
        renametable_2_snpt_enq = ($urandom_range(0, 99) < 12);
        renametable_2_snpt_deq = ($urandom_range(0, 99) < 10);
        renametable_2_snpt_use = ($urandom_range(0, 99) < 25);
        renametable_2_snpt_sel = 2'($urandom_range(0, 3));
        renametable_2_snpt_flush = 4'($urandom_range(0, 15));
      end
      for (int r = 0; r < 18; r++) begin
        renametable_2_rd_hold[r] = ($urandom_range(0, 99) < 30);
        renametable_2_rd_addr[r] = 6'((renametable_2_phase == 2) ? $urandom_range(0, 63)
                                          : (lo + $urandom_range(0, 3)));
      end
      for (int j = 0; j < 6; j++) begin
        renametable_2_sw_wen[j]  = ($urandom_range(0, 99) < 45);
        renametable_2_sw_data[j] = 8'($urandom_range(0, 255));
        renametable_2_aw_wen[j]  = ($urandom_range(0, 99) < 40);
        renametable_2_aw_data[j] = 8'($urandom_range(0, 15));   // 小值域，让 need_free 的
                                                      // "arch 表里一格都没有" 两种结果都出现
        renametable_2_sw_addr[j] = 6'((renametable_2_phase == 2) ? $urandom_range(0, 63)
                                          : (lo + $urandom_range(0, 3)));
        renametable_2_aw_addr[j] = 6'((renametable_2_phase == 2) ? $urandom_range(0, 63)
                                          : (lo + $urandom_range(0, 3)));
      end
    end
  end

  always @(posedge clk) if (!rst) begin
    automatic int nh, nc, nb;
    if (renametable_2_redirect) renametable_2_cov_redir++;
    if (renametable_2_snpt_use) renametable_2_cov_sel[renametable_2_snpt_sel]++;
    nh = 0; for (int r = 0; r < 18; r++) if (renametable_2_rd_hold[r]) nh++;
    if (nh > 0) renametable_2_cov_hold++;
    nc = 0;
    for (int j = 1; j < 6; j++)
      for (int k = 0; k < j; k++)
        if (renametable_2_sw_wen[j] && renametable_2_sw_wen[k] && renametable_2_sw_addr[j] == renametable_2_sw_addr[k]) nc++;
    if (nc > 0) renametable_2_cov_coll++;
    nb = 0;
    for (int r = 0; r < 18; r++)
      for (int j = 0; j < 6; j++)
        if (renametable_2_sw_wen[j] && renametable_2_sw_addr[j] == renametable_2_rd_addr[r]) nb++;
    if (nb > 0) renametable_2_cov_byp++;
  end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    for (int r = 0; r < 18; r++)
      `CHK($sformatf("RenameTable_2.readData[%0d]", r), renametable_2_g_rdata[r], renametable_2_i_rdata[r])
    for (int j = 0; j < 6; j++)
      `CHK($sformatf("RenameTable_2.old_pdest[%0d]", j), renametable_2_g_oldp[j], renametable_2_i_oldp[j])
    for (int j = 0; j < 6; j++)
      `CHK($sformatf("RenameTable_2.need_free[%0d]", j), renametable_2_g_nfree[j], renametable_2_i_nfree[j])
    for (int k = 0; k < 31; k++)
      `CHK($sformatf("RenameTable_2.diffRatBase[%0d]", k), renametable_2_g_diff[k], renametable_2_i_diff[k])
    for (int k = 0; k < 31; k++)
      `CHK($sformatf("RenameTable_2.debug_rdata[%0d]", k), renametable_2_g_dbg[k], renametable_2_i_dbg[k])
    // 内部状态也逐格比：输出被旁路/选择遮蔽时，表先错一步
    `CHK("RenameTable_2.spec_table[0]", renametable_2_g_u.spec_table_0, renametable_2_i_u.u_core.spec_table[0])
    `CHK("RenameTable_2.arch_table[0]", renametable_2_g_u.arch_table_0, renametable_2_i_u.u_core.arch_table[0])
    `CHK("RenameTable_2.spec_table[1]", renametable_2_g_u.spec_table_1, renametable_2_i_u.u_core.spec_table[1])
    `CHK("RenameTable_2.arch_table[1]", renametable_2_g_u.arch_table_1, renametable_2_i_u.u_core.arch_table[1])
    `CHK("RenameTable_2.spec_table[2]", renametable_2_g_u.spec_table_2, renametable_2_i_u.u_core.spec_table[2])
    `CHK("RenameTable_2.arch_table[2]", renametable_2_g_u.arch_table_2, renametable_2_i_u.u_core.arch_table[2])
    `CHK("RenameTable_2.spec_table[3]", renametable_2_g_u.spec_table_3, renametable_2_i_u.u_core.spec_table[3])
    `CHK("RenameTable_2.arch_table[3]", renametable_2_g_u.arch_table_3, renametable_2_i_u.u_core.arch_table[3])
    `CHK("RenameTable_2.spec_table[4]", renametable_2_g_u.spec_table_4, renametable_2_i_u.u_core.spec_table[4])
    `CHK("RenameTable_2.arch_table[4]", renametable_2_g_u.arch_table_4, renametable_2_i_u.u_core.arch_table[4])
    `CHK("RenameTable_2.spec_table[5]", renametable_2_g_u.spec_table_5, renametable_2_i_u.u_core.spec_table[5])
    `CHK("RenameTable_2.arch_table[5]", renametable_2_g_u.arch_table_5, renametable_2_i_u.u_core.arch_table[5])
    `CHK("RenameTable_2.spec_table[6]", renametable_2_g_u.spec_table_6, renametable_2_i_u.u_core.spec_table[6])
    `CHK("RenameTable_2.arch_table[6]", renametable_2_g_u.arch_table_6, renametable_2_i_u.u_core.arch_table[6])
    `CHK("RenameTable_2.spec_table[7]", renametable_2_g_u.spec_table_7, renametable_2_i_u.u_core.spec_table[7])
    `CHK("RenameTable_2.arch_table[7]", renametable_2_g_u.arch_table_7, renametable_2_i_u.u_core.arch_table[7])
    `CHK("RenameTable_2.spec_table[8]", renametable_2_g_u.spec_table_8, renametable_2_i_u.u_core.spec_table[8])
    `CHK("RenameTable_2.arch_table[8]", renametable_2_g_u.arch_table_8, renametable_2_i_u.u_core.arch_table[8])
    `CHK("RenameTable_2.spec_table[9]", renametable_2_g_u.spec_table_9, renametable_2_i_u.u_core.spec_table[9])
    `CHK("RenameTable_2.arch_table[9]", renametable_2_g_u.arch_table_9, renametable_2_i_u.u_core.arch_table[9])
    `CHK("RenameTable_2.spec_table[10]", renametable_2_g_u.spec_table_10, renametable_2_i_u.u_core.spec_table[10])
    `CHK("RenameTable_2.arch_table[10]", renametable_2_g_u.arch_table_10, renametable_2_i_u.u_core.arch_table[10])
    `CHK("RenameTable_2.spec_table[11]", renametable_2_g_u.spec_table_11, renametable_2_i_u.u_core.spec_table[11])
    `CHK("RenameTable_2.arch_table[11]", renametable_2_g_u.arch_table_11, renametable_2_i_u.u_core.arch_table[11])
    `CHK("RenameTable_2.spec_table[12]", renametable_2_g_u.spec_table_12, renametable_2_i_u.u_core.spec_table[12])
    `CHK("RenameTable_2.arch_table[12]", renametable_2_g_u.arch_table_12, renametable_2_i_u.u_core.arch_table[12])
    `CHK("RenameTable_2.spec_table[13]", renametable_2_g_u.spec_table_13, renametable_2_i_u.u_core.spec_table[13])
    `CHK("RenameTable_2.arch_table[13]", renametable_2_g_u.arch_table_13, renametable_2_i_u.u_core.arch_table[13])
    `CHK("RenameTable_2.spec_table[14]", renametable_2_g_u.spec_table_14, renametable_2_i_u.u_core.spec_table[14])
    `CHK("RenameTable_2.arch_table[14]", renametable_2_g_u.arch_table_14, renametable_2_i_u.u_core.arch_table[14])
    `CHK("RenameTable_2.spec_table[15]", renametable_2_g_u.spec_table_15, renametable_2_i_u.u_core.spec_table[15])
    `CHK("RenameTable_2.arch_table[15]", renametable_2_g_u.arch_table_15, renametable_2_i_u.u_core.arch_table[15])
    `CHK("RenameTable_2.spec_table[16]", renametable_2_g_u.spec_table_16, renametable_2_i_u.u_core.spec_table[16])
    `CHK("RenameTable_2.arch_table[16]", renametable_2_g_u.arch_table_16, renametable_2_i_u.u_core.arch_table[16])
    `CHK("RenameTable_2.spec_table[17]", renametable_2_g_u.spec_table_17, renametable_2_i_u.u_core.spec_table[17])
    `CHK("RenameTable_2.arch_table[17]", renametable_2_g_u.arch_table_17, renametable_2_i_u.u_core.arch_table[17])
    `CHK("RenameTable_2.spec_table[18]", renametable_2_g_u.spec_table_18, renametable_2_i_u.u_core.spec_table[18])
    `CHK("RenameTable_2.arch_table[18]", renametable_2_g_u.arch_table_18, renametable_2_i_u.u_core.arch_table[18])
    `CHK("RenameTable_2.spec_table[19]", renametable_2_g_u.spec_table_19, renametable_2_i_u.u_core.spec_table[19])
    `CHK("RenameTable_2.arch_table[19]", renametable_2_g_u.arch_table_19, renametable_2_i_u.u_core.arch_table[19])
    `CHK("RenameTable_2.spec_table[20]", renametable_2_g_u.spec_table_20, renametable_2_i_u.u_core.spec_table[20])
    `CHK("RenameTable_2.arch_table[20]", renametable_2_g_u.arch_table_20, renametable_2_i_u.u_core.arch_table[20])
    `CHK("RenameTable_2.spec_table[21]", renametable_2_g_u.spec_table_21, renametable_2_i_u.u_core.spec_table[21])
    `CHK("RenameTable_2.arch_table[21]", renametable_2_g_u.arch_table_21, renametable_2_i_u.u_core.arch_table[21])
    `CHK("RenameTable_2.spec_table[22]", renametable_2_g_u.spec_table_22, renametable_2_i_u.u_core.spec_table[22])
    `CHK("RenameTable_2.arch_table[22]", renametable_2_g_u.arch_table_22, renametable_2_i_u.u_core.arch_table[22])
    `CHK("RenameTable_2.spec_table[23]", renametable_2_g_u.spec_table_23, renametable_2_i_u.u_core.spec_table[23])
    `CHK("RenameTable_2.arch_table[23]", renametable_2_g_u.arch_table_23, renametable_2_i_u.u_core.arch_table[23])
    `CHK("RenameTable_2.spec_table[24]", renametable_2_g_u.spec_table_24, renametable_2_i_u.u_core.spec_table[24])
    `CHK("RenameTable_2.arch_table[24]", renametable_2_g_u.arch_table_24, renametable_2_i_u.u_core.arch_table[24])
    `CHK("RenameTable_2.spec_table[25]", renametable_2_g_u.spec_table_25, renametable_2_i_u.u_core.spec_table[25])
    `CHK("RenameTable_2.arch_table[25]", renametable_2_g_u.arch_table_25, renametable_2_i_u.u_core.arch_table[25])
    `CHK("RenameTable_2.spec_table[26]", renametable_2_g_u.spec_table_26, renametable_2_i_u.u_core.spec_table[26])
    `CHK("RenameTable_2.arch_table[26]", renametable_2_g_u.arch_table_26, renametable_2_i_u.u_core.arch_table[26])
    `CHK("RenameTable_2.spec_table[27]", renametable_2_g_u.spec_table_27, renametable_2_i_u.u_core.spec_table[27])
    `CHK("RenameTable_2.arch_table[27]", renametable_2_g_u.arch_table_27, renametable_2_i_u.u_core.arch_table[27])
    `CHK("RenameTable_2.spec_table[28]", renametable_2_g_u.spec_table_28, renametable_2_i_u.u_core.spec_table[28])
    `CHK("RenameTable_2.arch_table[28]", renametable_2_g_u.arch_table_28, renametable_2_i_u.u_core.arch_table[28])
    `CHK("RenameTable_2.spec_table[29]", renametable_2_g_u.spec_table_29, renametable_2_i_u.u_core.spec_table[29])
    `CHK("RenameTable_2.arch_table[29]", renametable_2_g_u.arch_table_29, renametable_2_i_u.u_core.arch_table[29])
    `CHK("RenameTable_2.spec_table[30]", renametable_2_g_u.spec_table_30, renametable_2_i_u.u_core.spec_table[30])
    `CHK("RenameTable_2.arch_table[30]", renametable_2_g_u.arch_table_30, renametable_2_i_u.u_core.arch_table[30])
    `CHK("RenameTable_2.spec_table[31]", renametable_2_g_u.spec_table_31, renametable_2_i_u.u_core.spec_table[31])
    `CHK("RenameTable_2.arch_table[31]", renametable_2_g_u.arch_table_31, renametable_2_i_u.u_core.arch_table[31])
    `CHK("RenameTable_2.spec_table[32]", renametable_2_g_u.spec_table_32, renametable_2_i_u.u_core.spec_table[32])
    `CHK("RenameTable_2.arch_table[32]", renametable_2_g_u.arch_table_32, renametable_2_i_u.u_core.arch_table[32])
    `CHK("RenameTable_2.spec_table[33]", renametable_2_g_u.spec_table_33, renametable_2_i_u.u_core.spec_table[33])
    `CHK("RenameTable_2.arch_table[33]", renametable_2_g_u.arch_table_33, renametable_2_i_u.u_core.arch_table[33])
    `CHK("RenameTable_2.spec_table[34]", renametable_2_g_u.spec_table_34, renametable_2_i_u.u_core.spec_table[34])
    `CHK("RenameTable_2.arch_table[34]", renametable_2_g_u.arch_table_34, renametable_2_i_u.u_core.arch_table[34])
    `CHK("RenameTable_2.spec_table[35]", renametable_2_g_u.spec_table_35, renametable_2_i_u.u_core.spec_table[35])
    `CHK("RenameTable_2.arch_table[35]", renametable_2_g_u.arch_table_35, renametable_2_i_u.u_core.arch_table[35])
    `CHK("RenameTable_2.spec_table[36]", renametable_2_g_u.spec_table_36, renametable_2_i_u.u_core.spec_table[36])
    `CHK("RenameTable_2.arch_table[36]", renametable_2_g_u.arch_table_36, renametable_2_i_u.u_core.arch_table[36])
    `CHK("RenameTable_2.spec_table[37]", renametable_2_g_u.spec_table_37, renametable_2_i_u.u_core.spec_table[37])
    `CHK("RenameTable_2.arch_table[37]", renametable_2_g_u.arch_table_37, renametable_2_i_u.u_core.arch_table[37])
    `CHK("RenameTable_2.spec_table[38]", renametable_2_g_u.spec_table_38, renametable_2_i_u.u_core.spec_table[38])
    `CHK("RenameTable_2.arch_table[38]", renametable_2_g_u.arch_table_38, renametable_2_i_u.u_core.arch_table[38])
    `CHK("RenameTable_2.spec_table[39]", renametable_2_g_u.spec_table_39, renametable_2_i_u.u_core.spec_table[39])
    `CHK("RenameTable_2.arch_table[39]", renametable_2_g_u.arch_table_39, renametable_2_i_u.u_core.arch_table[39])
    `CHK("RenameTable_2.spec_table[40]", renametable_2_g_u.spec_table_40, renametable_2_i_u.u_core.spec_table[40])
    `CHK("RenameTable_2.arch_table[40]", renametable_2_g_u.arch_table_40, renametable_2_i_u.u_core.arch_table[40])
    `CHK("RenameTable_2.spec_table[41]", renametable_2_g_u.spec_table_41, renametable_2_i_u.u_core.spec_table[41])
    `CHK("RenameTable_2.arch_table[41]", renametable_2_g_u.arch_table_41, renametable_2_i_u.u_core.arch_table[41])
    `CHK("RenameTable_2.spec_table[42]", renametable_2_g_u.spec_table_42, renametable_2_i_u.u_core.spec_table[42])
    `CHK("RenameTable_2.arch_table[42]", renametable_2_g_u.arch_table_42, renametable_2_i_u.u_core.arch_table[42])
    `CHK("RenameTable_2.spec_table[43]", renametable_2_g_u.spec_table_43, renametable_2_i_u.u_core.spec_table[43])
    `CHK("RenameTable_2.arch_table[43]", renametable_2_g_u.arch_table_43, renametable_2_i_u.u_core.arch_table[43])
    `CHK("RenameTable_2.spec_table[44]", renametable_2_g_u.spec_table_44, renametable_2_i_u.u_core.spec_table[44])
    `CHK("RenameTable_2.arch_table[44]", renametable_2_g_u.arch_table_44, renametable_2_i_u.u_core.arch_table[44])
    `CHK("RenameTable_2.spec_table[45]", renametable_2_g_u.spec_table_45, renametable_2_i_u.u_core.spec_table[45])
    `CHK("RenameTable_2.arch_table[45]", renametable_2_g_u.arch_table_45, renametable_2_i_u.u_core.arch_table[45])
    `CHK("RenameTable_2.spec_table[46]", renametable_2_g_u.spec_table_46, renametable_2_i_u.u_core.spec_table[46])
    `CHK("RenameTable_2.arch_table[46]", renametable_2_g_u.arch_table_46, renametable_2_i_u.u_core.arch_table[46])
    `CHK("RenameTable_2.t1_redirect", renametable_2_g_u.t1_redirect_last_REG, renametable_2_i_u.u_core.t1_redirect)
    `CHK("RenameTable_2.spec_redirect_q[0]", renametable_2_g_u.spec_table_next_0_REG,
          renametable_2_i_u.u_core.spec_redirect_q[0])
    `CHK("RenameTable_2.spec_redirect_q[46]", renametable_2_g_u.spec_table_next_46_REG,
          renametable_2_i_u.u_core.spec_redirect_q[46])
    for (int r = 0; r < 18; r++)
      `CHK($sformatf("RenameTable_2.t1_raddr[%0d]", r), renametable_2_g_raddr[r], renametable_2_i_u.u_core.t1_raddr[r])
  end

  // ==========================================================================
  // RenameTable_3: 1 格 / addr 0 位 / 6 读口 / need_free 有 / debug_rdata 1 格
  // ==========================================================================
  logic            renametable_3_redirect;
  logic            renametable_3_rd_hold [6];
  logic            renametable_3_sw_wen [6];
  logic [7:0]      renametable_3_sw_data [6];
  logic            renametable_3_aw_wen [6];
  logic [7:0]      renametable_3_aw_data [6];
  logic            renametable_3_snpt_enq, renametable_3_snpt_deq, renametable_3_snpt_use;
  logic [1:0]      renametable_3_snpt_sel;
  logic [3:0]      renametable_3_snpt_flush;
  logic [7:0] renametable_3_g_rdata [6];
  logic [7:0] renametable_3_g_oldp [6];
  logic       renametable_3_g_nfree [6];
  logic [7:0] renametable_3_g_diff [1];
  logic [7:0] renametable_3_g_dbg [1];
  logic [7:0] renametable_3_g_dv0;
  logic [7:0] renametable_3_i_rdata [6];
  logic [7:0] renametable_3_i_oldp [6];
  logic       renametable_3_i_nfree [6];
  logic [7:0] renametable_3_i_diff [1];
  logic [7:0] renametable_3_i_dbg [1];
  logic [7:0] renametable_3_i_dv0;

  RenameTable_3 renametable_3_g_u (
    .clock(clk), .reset(rst), .io_redirect(renametable_3_redirect),
    .io_readPorts_0_hold(renametable_3_rd_hold[0]),
    .io_readPorts_0_data(renametable_3_g_rdata[0]),
    .io_readPorts_1_hold(renametable_3_rd_hold[1]),
    .io_readPorts_1_data(renametable_3_g_rdata[1]),
    .io_readPorts_2_hold(renametable_3_rd_hold[2]),
    .io_readPorts_2_data(renametable_3_g_rdata[2]),
    .io_readPorts_3_hold(renametable_3_rd_hold[3]),
    .io_readPorts_3_data(renametable_3_g_rdata[3]),
    .io_readPorts_4_hold(renametable_3_rd_hold[4]),
    .io_readPorts_4_data(renametable_3_g_rdata[4]),
    .io_readPorts_5_hold(renametable_3_rd_hold[5]),
    .io_readPorts_5_data(renametable_3_g_rdata[5]),
    .io_specWritePorts_0_wen(renametable_3_sw_wen[0]),
    .io_specWritePorts_0_data(renametable_3_sw_data[0]),
    .io_specWritePorts_1_wen(renametable_3_sw_wen[1]),
    .io_specWritePorts_1_data(renametable_3_sw_data[1]),
    .io_specWritePorts_2_wen(renametable_3_sw_wen[2]),
    .io_specWritePorts_2_data(renametable_3_sw_data[2]),
    .io_specWritePorts_3_wen(renametable_3_sw_wen[3]),
    .io_specWritePorts_3_data(renametable_3_sw_data[3]),
    .io_specWritePorts_4_wen(renametable_3_sw_wen[4]),
    .io_specWritePorts_4_data(renametable_3_sw_data[4]),
    .io_specWritePorts_5_wen(renametable_3_sw_wen[5]),
    .io_specWritePorts_5_data(renametable_3_sw_data[5]),
    .io_archWritePorts_0_wen(renametable_3_aw_wen[0]),
    .io_archWritePorts_0_data(renametable_3_aw_data[0]),
    .io_archWritePorts_1_wen(renametable_3_aw_wen[1]),
    .io_archWritePorts_1_data(renametable_3_aw_data[1]),
    .io_archWritePorts_2_wen(renametable_3_aw_wen[2]),
    .io_archWritePorts_2_data(renametable_3_aw_data[2]),
    .io_archWritePorts_3_wen(renametable_3_aw_wen[3]),
    .io_archWritePorts_3_data(renametable_3_aw_data[3]),
    .io_archWritePorts_4_wen(renametable_3_aw_wen[4]),
    .io_archWritePorts_4_data(renametable_3_aw_data[4]),
    .io_archWritePorts_5_wen(renametable_3_aw_wen[5]),
    .io_archWritePorts_5_data(renametable_3_aw_data[5]),
    .io_old_pdest_0(renametable_3_g_oldp[0]),
    .io_old_pdest_1(renametable_3_g_oldp[1]),
    .io_old_pdest_2(renametable_3_g_oldp[2]),
    .io_old_pdest_3(renametable_3_g_oldp[3]),
    .io_old_pdest_4(renametable_3_g_oldp[4]),
    .io_old_pdest_5(renametable_3_g_oldp[5]),
    .io_need_free_0(renametable_3_g_nfree[0]),
    .io_need_free_1(renametable_3_g_nfree[1]),
    .io_need_free_2(renametable_3_g_nfree[2]),
    .io_need_free_3(renametable_3_g_nfree[3]),
    .io_need_free_4(renametable_3_g_nfree[4]),
    .io_need_free_5(renametable_3_g_nfree[5]),
    .io_snpt_snptEnq(renametable_3_snpt_enq), .io_snpt_snptDeq(renametable_3_snpt_deq),
    .io_snpt_useSnpt(renametable_3_snpt_use), .io_snpt_snptSelect(renametable_3_snpt_sel),
    .io_snpt_flushVec_0(renametable_3_snpt_flush[0]),
    .io_snpt_flushVec_1(renametable_3_snpt_flush[1]),
    .io_snpt_flushVec_2(renametable_3_snpt_flush[2]),
    .io_snpt_flushVec_3(renametable_3_snpt_flush[3]),
    .io_diffRatBase_0(renametable_3_g_diff[0]),
    .io_debug_rdata_0(renametable_3_g_dbg[0]),
    .io_debug_v0(renametable_3_g_dv0)
  );
  RenameTable_3_xs renametable_3_i_u (
    .clock(clk), .reset(rst), .io_redirect(renametable_3_redirect),
    .io_readPorts_0_hold(renametable_3_rd_hold[0]),
    .io_readPorts_0_data(renametable_3_i_rdata[0]),
    .io_readPorts_1_hold(renametable_3_rd_hold[1]),
    .io_readPorts_1_data(renametable_3_i_rdata[1]),
    .io_readPorts_2_hold(renametable_3_rd_hold[2]),
    .io_readPorts_2_data(renametable_3_i_rdata[2]),
    .io_readPorts_3_hold(renametable_3_rd_hold[3]),
    .io_readPorts_3_data(renametable_3_i_rdata[3]),
    .io_readPorts_4_hold(renametable_3_rd_hold[4]),
    .io_readPorts_4_data(renametable_3_i_rdata[4]),
    .io_readPorts_5_hold(renametable_3_rd_hold[5]),
    .io_readPorts_5_data(renametable_3_i_rdata[5]),
    .io_specWritePorts_0_wen(renametable_3_sw_wen[0]),
    .io_specWritePorts_0_data(renametable_3_sw_data[0]),
    .io_specWritePorts_1_wen(renametable_3_sw_wen[1]),
    .io_specWritePorts_1_data(renametable_3_sw_data[1]),
    .io_specWritePorts_2_wen(renametable_3_sw_wen[2]),
    .io_specWritePorts_2_data(renametable_3_sw_data[2]),
    .io_specWritePorts_3_wen(renametable_3_sw_wen[3]),
    .io_specWritePorts_3_data(renametable_3_sw_data[3]),
    .io_specWritePorts_4_wen(renametable_3_sw_wen[4]),
    .io_specWritePorts_4_data(renametable_3_sw_data[4]),
    .io_specWritePorts_5_wen(renametable_3_sw_wen[5]),
    .io_specWritePorts_5_data(renametable_3_sw_data[5]),
    .io_archWritePorts_0_wen(renametable_3_aw_wen[0]),
    .io_archWritePorts_0_data(renametable_3_aw_data[0]),
    .io_archWritePorts_1_wen(renametable_3_aw_wen[1]),
    .io_archWritePorts_1_data(renametable_3_aw_data[1]),
    .io_archWritePorts_2_wen(renametable_3_aw_wen[2]),
    .io_archWritePorts_2_data(renametable_3_aw_data[2]),
    .io_archWritePorts_3_wen(renametable_3_aw_wen[3]),
    .io_archWritePorts_3_data(renametable_3_aw_data[3]),
    .io_archWritePorts_4_wen(renametable_3_aw_wen[4]),
    .io_archWritePorts_4_data(renametable_3_aw_data[4]),
    .io_archWritePorts_5_wen(renametable_3_aw_wen[5]),
    .io_archWritePorts_5_data(renametable_3_aw_data[5]),
    .io_old_pdest_0(renametable_3_i_oldp[0]),
    .io_old_pdest_1(renametable_3_i_oldp[1]),
    .io_old_pdest_2(renametable_3_i_oldp[2]),
    .io_old_pdest_3(renametable_3_i_oldp[3]),
    .io_old_pdest_4(renametable_3_i_oldp[4]),
    .io_old_pdest_5(renametable_3_i_oldp[5]),
    .io_need_free_0(renametable_3_i_nfree[0]),
    .io_need_free_1(renametable_3_i_nfree[1]),
    .io_need_free_2(renametable_3_i_nfree[2]),
    .io_need_free_3(renametable_3_i_nfree[3]),
    .io_need_free_4(renametable_3_i_nfree[4]),
    .io_need_free_5(renametable_3_i_nfree[5]),
    .io_snpt_snptEnq(renametable_3_snpt_enq), .io_snpt_snptDeq(renametable_3_snpt_deq),
    .io_snpt_useSnpt(renametable_3_snpt_use), .io_snpt_snptSelect(renametable_3_snpt_sel),
    .io_snpt_flushVec_0(renametable_3_snpt_flush[0]),
    .io_snpt_flushVec_1(renametable_3_snpt_flush[1]),
    .io_snpt_flushVec_2(renametable_3_snpt_flush[2]),
    .io_snpt_flushVec_3(renametable_3_snpt_flush[3]),
    .io_diffRatBase_0(renametable_3_i_diff[0]),
    .io_debug_rdata_0(renametable_3_i_dbg[0]),
    .io_debug_v0(renametable_3_i_dv0)
  );

  int renametable_3_phase, renametable_3_phaseCnt;
  int renametable_3_cov_redir, renametable_3_cov_use, renametable_3_cov_hold, renametable_3_cov_coll, renametable_3_cov_byp;
  int renametable_3_cov_sel [4];
  always @(negedge clk) begin
    automatic int lo;
    if (rst) begin
      renametable_3_redirect = 1'b0; renametable_3_snpt_enq = 1'b0; renametable_3_snpt_deq = 1'b0;
      renametable_3_snpt_use = 1'b0; renametable_3_snpt_sel = 2'h0; renametable_3_snpt_flush = 4'h0;
      for (int r = 0; r < 6; r++) begin
        renametable_3_rd_hold[r] = 1'b0;
      end
      for (int j = 0; j < 6; j++) begin
        renametable_3_sw_wen[j] = 1'b0; renametable_3_sw_data[j] = '0;
        renametable_3_aw_wen[j] = 1'b0; renametable_3_aw_data[j] = '0;
      end
      renametable_3_phase <= 0; renametable_3_phaseCnt <= 0;
    end else begin
      renametable_3_phaseCnt <= renametable_3_phaseCnt + 1;
      if (renametable_3_phaseCnt >= 97) begin renametable_3_phaseCnt <= 0; renametable_3_phase <= (renametable_3_phase + 1) % 3; end
      // 相位 0/1：把地址挤进一个很窄的窗口（lo..lo+3），制造同址撞车与旁路命中；
      // 相位 2：全域随机。窗口起点每拍重掷，保证扫遍整张表。
      lo = (renametable_3_phase == 2) ? 0 : $urandom_range(0, 0);
      // 暖机窗口：纯入队，把 4 个快照槽写成两侧相同的确定值（见文件头说明）。
      if (warmup) begin
        renametable_3_redirect = 1'b0;   renametable_3_snpt_enq = 1'b1;  renametable_3_snpt_deq = 1'b0;
        renametable_3_snpt_use = 1'b0;   renametable_3_snpt_sel = 2'h0;  renametable_3_snpt_flush = 4'h0;
      end else begin
        renametable_3_redirect = ($urandom_range(0, 99) < 4);
        renametable_3_snpt_enq = ($urandom_range(0, 99) < 12);
        renametable_3_snpt_deq = ($urandom_range(0, 99) < 10);
        renametable_3_snpt_use = ($urandom_range(0, 99) < 25);
        renametable_3_snpt_sel = 2'($urandom_range(0, 3));
        renametable_3_snpt_flush = 4'($urandom_range(0, 15));
      end
      for (int r = 0; r < 6; r++) begin
        renametable_3_rd_hold[r] = ($urandom_range(0, 99) < 30);
      end
      for (int j = 0; j < 6; j++) begin
        renametable_3_sw_wen[j]  = ($urandom_range(0, 99) < 45);
        renametable_3_sw_data[j] = 8'($urandom_range(0, 255));
        renametable_3_aw_wen[j]  = ($urandom_range(0, 99) < 40);
        renametable_3_aw_data[j] = 8'($urandom_range(0, 15));   // 小值域，让 need_free 的
                                                      // "arch 表里一格都没有" 两种结果都出现
      end
    end
  end

  always @(posedge clk) if (!rst) begin
    automatic int nh, nc, nb;
    if (renametable_3_redirect) renametable_3_cov_redir++;
    if (renametable_3_snpt_use) renametable_3_cov_sel[renametable_3_snpt_sel]++;
    nh = 0; for (int r = 0; r < 6; r++) if (renametable_3_rd_hold[r]) nh++;
    if (nh > 0) renametable_3_cov_hold++;
    nc = 0; nb = 0;
    for (int j = 0; j < 6; j++) if (renametable_3_sw_wen[j]) begin nc++; nb++; end
    if (nc > 1) renametable_3_cov_coll++;
    if (nb > 0) renametable_3_cov_byp++;
  end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    for (int r = 0; r < 6; r++)
      `CHK($sformatf("RenameTable_3.readData[%0d]", r), renametable_3_g_rdata[r], renametable_3_i_rdata[r])
    for (int j = 0; j < 6; j++)
      `CHK($sformatf("RenameTable_3.old_pdest[%0d]", j), renametable_3_g_oldp[j], renametable_3_i_oldp[j])
    for (int j = 0; j < 6; j++)
      `CHK($sformatf("RenameTable_3.need_free[%0d]", j), renametable_3_g_nfree[j], renametable_3_i_nfree[j])
    for (int k = 0; k < 1; k++)
      `CHK($sformatf("RenameTable_3.diffRatBase[%0d]", k), renametable_3_g_diff[k], renametable_3_i_diff[k])
    for (int k = 0; k < 1; k++)
      `CHK($sformatf("RenameTable_3.debug_rdata[%0d]", k), renametable_3_g_dbg[k], renametable_3_i_dbg[k])
    `CHK("RenameTable_3.debug_v0", renametable_3_g_dv0, renametable_3_i_dv0)
    // 内部状态也逐格比：输出被旁路/选择遮蔽时，表先错一步
    `CHK("RenameTable_3.spec_table[0]", renametable_3_g_u.spec_table_0, renametable_3_i_u.u_core.spec_table[0])
    `CHK("RenameTable_3.arch_table[0]", renametable_3_g_u.arch_table_0, renametable_3_i_u.u_core.arch_table[0])
    `CHK("RenameTable_3.t1_redirect", renametable_3_g_u.t1_redirect_last_REG, renametable_3_i_u.u_core.t1_redirect)
    `CHK("RenameTable_3.spec_redirect_q[0]", renametable_3_g_u.spec_table_next_0_REG,
          renametable_3_i_u.u_core.spec_redirect_q[0])
  end
  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("COV RenameTable: redirect=%0d hold=%0d addr_collision=%0d bypass_hit=%0d useSnpt_sel=[%0d %0d %0d %0d]",
             renametable_cov_redir, renametable_cov_hold, renametable_cov_coll, renametable_cov_byp,
             renametable_cov_sel[0], renametable_cov_sel[1], renametable_cov_sel[2], renametable_cov_sel[3]);
    $display("COV RenameTable_1: redirect=%0d hold=%0d addr_collision=%0d bypass_hit=%0d useSnpt_sel=[%0d %0d %0d %0d]",
             renametable_1_cov_redir, renametable_1_cov_hold, renametable_1_cov_coll, renametable_1_cov_byp,
             renametable_1_cov_sel[0], renametable_1_cov_sel[1], renametable_1_cov_sel[2], renametable_1_cov_sel[3]);
    $display("COV RenameTable_2: redirect=%0d hold=%0d addr_collision=%0d bypass_hit=%0d useSnpt_sel=[%0d %0d %0d %0d]",
             renametable_2_cov_redir, renametable_2_cov_hold, renametable_2_cov_coll, renametable_2_cov_byp,
             renametable_2_cov_sel[0], renametable_2_cov_sel[1], renametable_2_cov_sel[2], renametable_2_cov_sel[3]);
    $display("COV RenameTable_3: redirect=%0d hold=%0d addr_collision=%0d bypass_hit=%0d useSnpt_sel=[%0d %0d %0d %0d]",
             renametable_3_cov_redir, renametable_3_cov_hold, renametable_3_cov_coll, renametable_3_cov_byp,
             renametable_3_cov_sel[0], renametable_3_cov_sel[1], renametable_3_cov_sel[2], renametable_3_cov_sel[3]);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
