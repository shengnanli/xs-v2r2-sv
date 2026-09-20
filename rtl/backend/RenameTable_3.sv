// =============================================================================
// RenameTable_3 —— RenameTable 家族变体：v0 / vl 单格 RAT（Reg_V0 与 Reg_Vl 合并）
//
// 规模：**1 格** x 8 位、地址 **0 位**、6 个读口（1 源操作数 x RenameWidth 6）、
//       6 个投机写口 + 6 个体系结构写口、快照件 SnapshotGenerator_7（1 x 8）。
//
// ★"0 位地址"是本变体全部特殊性的来源★：V0LogicRegs = VlLogicRegs = 1，
//   log2Ceil(1) = 0，于是 golden 的端口表里**一个 addr 端口都没有**
//   （readPorts 只剩 hold/data，specWritePorts 与 archWritePorts 只剩 wen/data），
//   而且**一个地址寄存器都没有**（t1_raddr / t1_wSpec_addr 全被折叠掉，
//   原来的 t1_wSpec_j_wen 直接被 firtool 改名成 matchVec_j）。
//   核用 ADDR_W=0 走 g_addr_const 分支：地址恒 0、不生成任何地址寄存器。
//
// ★一个模块两个实例★：RenameTableWrapper 里的 v0Rat 与 vlRat 参数完全相同
//   （都是 1 格、1 个读口 x 6、identity 初值），firtool 判为同构后合并成本模块，
//   在 wrapper 里例化两次。它俩在 Chisel 里唯一的区别是 debug_v0 还是 debug_vl，
//   两者都等于 arch_table(0)，合并后统一叫 io_debug_v0。
// 核体见 rtl/backend/RenameTable.sv，本文件仅设参数、展平端口、例化快照件。
// ★本文件由 verif/ut/RenameTable/gen_variants.py 生成，改请改生成器★
// =============================================================================
module RenameTable_3(
  input        clock,
  input        reset,
  input        io_redirect,
  input        io_readPorts_0_hold,
  output [7:0] io_readPorts_0_data,
  input        io_readPorts_1_hold,
  output [7:0] io_readPorts_1_data,
  input        io_readPorts_2_hold,
  output [7:0] io_readPorts_2_data,
  input        io_readPorts_3_hold,
  output [7:0] io_readPorts_3_data,
  input        io_readPorts_4_hold,
  output [7:0] io_readPorts_4_data,
  input        io_readPorts_5_hold,
  output [7:0] io_readPorts_5_data,
  input        io_specWritePorts_0_wen,
  input  [7:0] io_specWritePorts_0_data,
  input        io_specWritePorts_1_wen,
  input  [7:0] io_specWritePorts_1_data,
  input        io_specWritePorts_2_wen,
  input  [7:0] io_specWritePorts_2_data,
  input        io_specWritePorts_3_wen,
  input  [7:0] io_specWritePorts_3_data,
  input        io_specWritePorts_4_wen,
  input  [7:0] io_specWritePorts_4_data,
  input        io_specWritePorts_5_wen,
  input  [7:0] io_specWritePorts_5_data,
  input        io_archWritePorts_0_wen,
  input  [7:0] io_archWritePorts_0_data,
  input        io_archWritePorts_1_wen,
  input  [7:0] io_archWritePorts_1_data,
  input        io_archWritePorts_2_wen,
  input  [7:0] io_archWritePorts_2_data,
  input        io_archWritePorts_3_wen,
  input  [7:0] io_archWritePorts_3_data,
  input        io_archWritePorts_4_wen,
  input  [7:0] io_archWritePorts_4_data,
  input        io_archWritePorts_5_wen,
  input  [7:0] io_archWritePorts_5_data,
  output [7:0] io_old_pdest_0,
  output [7:0] io_old_pdest_1,
  output [7:0] io_old_pdest_2,
  output [7:0] io_old_pdest_3,
  output [7:0] io_old_pdest_4,
  output [7:0] io_old_pdest_5,
  output       io_need_free_0,
  output       io_need_free_1,
  output       io_need_free_2,
  output       io_need_free_3,
  output       io_need_free_4,
  output       io_need_free_5,
  input        io_snpt_snptEnq,
  input        io_snpt_snptDeq,
  input        io_snpt_useSnpt,
  input  [1:0] io_snpt_snptSelect,
  input        io_snpt_flushVec_0,
  input        io_snpt_flushVec_1,
  input        io_snpt_flushVec_2,
  input        io_snpt_flushVec_3,
  output [7:0] io_diffRatBase_0,
  output [7:0] io_debug_rdata_0,
  output [7:0] io_debug_v0
);
  logic            rd_hold [6];
  logic [0:0]      rd_addr [6];
  logic [7:0]      rd_data [6];
  logic            sw_wen  [6];
  logic [0:0]      sw_addr [6];
  logic [7:0]      sw_data [6];
  logic            aw_wen  [6];
  logic [0:0]      aw_addr [6];
  logic [7:0]      aw_data [6];
  logic [7:0]      old_pdest [6];
  logic            need_free [6];
  logic [7:0]      diffRatBase [1];
  logic [7:0]      debug_rdata [1];
  logic [7:0]      debug_arch0;
  logic [7:0]      snpt_enq_data [1];
  logic            snpt_enq, snpt_deq, snpt_redirect;
  logic [3:0]      snpt_flush;
  logic [7:0]      snpt_rdata [4][1];

  assign rd_hold[0] = io_readPorts_0_hold;
  assign rd_addr[0] = 1'b0;   // golden 无 addr 端口（表只有一格）
  assign rd_hold[1] = io_readPorts_1_hold;
  assign rd_addr[1] = 1'b0;   // golden 无 addr 端口（表只有一格）
  assign rd_hold[2] = io_readPorts_2_hold;
  assign rd_addr[2] = 1'b0;   // golden 无 addr 端口（表只有一格）
  assign rd_hold[3] = io_readPorts_3_hold;
  assign rd_addr[3] = 1'b0;   // golden 无 addr 端口（表只有一格）
  assign rd_hold[4] = io_readPorts_4_hold;
  assign rd_addr[4] = 1'b0;   // golden 无 addr 端口（表只有一格）
  assign rd_hold[5] = io_readPorts_5_hold;
  assign rd_addr[5] = 1'b0;   // golden 无 addr 端口（表只有一格）
  assign sw_wen[0]  = io_specWritePorts_0_wen;
  assign sw_data[0] = io_specWritePorts_0_data;
  assign sw_addr[0] = 1'b0;
  assign aw_wen[0]  = io_archWritePorts_0_wen;
  assign aw_data[0] = io_archWritePorts_0_data;
  assign aw_addr[0] = 1'b0;
  assign sw_wen[1]  = io_specWritePorts_1_wen;
  assign sw_data[1] = io_specWritePorts_1_data;
  assign sw_addr[1] = 1'b0;
  assign aw_wen[1]  = io_archWritePorts_1_wen;
  assign aw_data[1] = io_archWritePorts_1_data;
  assign aw_addr[1] = 1'b0;
  assign sw_wen[2]  = io_specWritePorts_2_wen;
  assign sw_data[2] = io_specWritePorts_2_data;
  assign sw_addr[2] = 1'b0;
  assign aw_wen[2]  = io_archWritePorts_2_wen;
  assign aw_data[2] = io_archWritePorts_2_data;
  assign aw_addr[2] = 1'b0;
  assign sw_wen[3]  = io_specWritePorts_3_wen;
  assign sw_data[3] = io_specWritePorts_3_data;
  assign sw_addr[3] = 1'b0;
  assign aw_wen[3]  = io_archWritePorts_3_wen;
  assign aw_data[3] = io_archWritePorts_3_data;
  assign aw_addr[3] = 1'b0;
  assign sw_wen[4]  = io_specWritePorts_4_wen;
  assign sw_data[4] = io_specWritePorts_4_data;
  assign sw_addr[4] = 1'b0;
  assign aw_wen[4]  = io_archWritePorts_4_wen;
  assign aw_data[4] = io_archWritePorts_4_data;
  assign aw_addr[4] = 1'b0;
  assign sw_wen[5]  = io_specWritePorts_5_wen;
  assign sw_data[5] = io_specWritePorts_5_data;
  assign sw_addr[5] = 1'b0;
  assign aw_wen[5]  = io_archWritePorts_5_wen;
  assign aw_data[5] = io_archWritePorts_5_data;
  assign aw_addr[5] = 1'b0;

  assign io_readPorts_0_data = rd_data[0];
  assign io_readPorts_1_data = rd_data[1];
  assign io_readPorts_2_data = rd_data[2];
  assign io_readPorts_3_data = rd_data[3];
  assign io_readPorts_4_data = rd_data[4];
  assign io_readPorts_5_data = rd_data[5];
  assign io_old_pdest_0 = old_pdest[0];
  assign io_old_pdest_1 = old_pdest[1];
  assign io_old_pdest_2 = old_pdest[2];
  assign io_old_pdest_3 = old_pdest[3];
  assign io_old_pdest_4 = old_pdest[4];
  assign io_old_pdest_5 = old_pdest[5];
  assign io_need_free_0 = need_free[0];
  assign io_need_free_1 = need_free[1];
  assign io_need_free_2 = need_free[2];
  assign io_need_free_3 = need_free[3];
  assign io_need_free_4 = need_free[4];
  assign io_need_free_5 = need_free[5];
  assign io_diffRatBase_0 = diffRatBase[0];
  assign io_debug_rdata_0 = debug_rdata[0];
  assign io_debug_v0 = debug_arch0;

  xs_RenameTable_core #(
    .N_ENTRIES(1), .ADDR_W(0), .N_READ(6), .N_WRITE(6),
    .INIT_IDENTITY(1'b1), .DIFF_N(1), .DIFF_OFF(0),
    .DBG_N(1), .DBG_OFF(0),
    .HAS_NEED_FREE(1'b1), .HAS_DBG(1'b1)
  ) u_core (
    .clock                  (clock),
    .reset                  (reset),
    .io_redirect            (io_redirect),
    .io_readPorts_hold      (rd_hold),
    .io_readPorts_addr      (rd_addr),
    .io_readPorts_data      (rd_data),
    .io_specWritePorts_wen  (sw_wen),
    .io_specWritePorts_addr (sw_addr),
    .io_specWritePorts_data (sw_data),
    .io_archWritePorts_wen  (aw_wen),
    .io_archWritePorts_addr (aw_addr),
    .io_archWritePorts_data (aw_data),
    .io_old_pdest           (old_pdest),
    .io_need_free           (need_free),
    .io_snpt_snptEnq        (io_snpt_snptEnq),
    .io_snpt_snptDeq        (io_snpt_snptDeq),
    .io_snpt_useSnpt        (io_snpt_useSnpt),
    .io_snpt_snptSelect     (io_snpt_snptSelect),
    .io_snpt_flushVec       ({io_snpt_flushVec_3, io_snpt_flushVec_2,
                              io_snpt_flushVec_1, io_snpt_flushVec_0}),
    .io_diffRatBase         (diffRatBase),
    .io_debug_rdata         (debug_rdata),
    .io_debug_arch0         (debug_arch0),
    .snpt_enq_data          (snpt_enq_data),
    .snpt_enq               (snpt_enq),
    .snpt_deq               (snpt_deq),
    .snpt_redirect          (snpt_redirect),
    .snpt_flush             (snpt_flush),
    .snpt_rdata             (snpt_rdata)
  );

  // 实例名 snapshots_snapshotGen 与 golden 逐字一致：FM 按层次路径配对内部比对点。
  SnapshotGenerator_7 snapshots_snapshotGen (
    .clock       (clock),
    .reset       (reset),
    .io_enq      (snpt_enq),
    .io_enqData_0  (snpt_enq_data[0]),
    .io_deq      (snpt_deq),
    .io_redirect (snpt_redirect),
    .io_flushVec_0(snpt_flush[0]),
    .io_flushVec_1(snpt_flush[1]),
    .io_flushVec_2(snpt_flush[2]),
    .io_flushVec_3(snpt_flush[3]),
    .io_snapshots_0_0  (snpt_rdata[0][0]),
    .io_snapshots_1_0  (snpt_rdata[1][0]),
    .io_snapshots_2_0  (snpt_rdata[2][0]),
    .io_snapshots_3_0  (snpt_rdata[3][0])
  );
endmodule
