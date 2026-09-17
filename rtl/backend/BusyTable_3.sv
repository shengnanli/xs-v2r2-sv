// BusyTable_3.sv —— 物理寄存器忙位表（V0 向量掩码堆变体）薄包装层
// -----------------------------------------------------------------------------
// 核体见 xs_BusyTable_core.sv（家族共享参数化核）。本文件只做端口打包与参数设定。
//
// 本变体规模（全部从 G1 golden BusyTable_3.sv 机械量得）：
//   表深 **22** 项（V0PhyRegs）—— 全家族最小；分配口 6；写回口 6；读口 6
//   快速唤醒 1 路：wakeUpFp_0，门控位 **v0Wen**
//   寄存器 22 个 = 纯忙位，异步复位到 0；无 loadDependency 影子、无 ldCancel 端口。
//
// ★ 越界是这个变体的常态：preg 索引端口仍是 8 位（全后端共用 PhyRegIdxWidth），
//   而表只有 22 项，随便一个 22..255 的索引就落在表外。golden 用 `table >> req`
//   得到 0（读成「就绪」）—— 核 §6 照这个语义写。
//
// 唤醒取消路由：wk0 = `~(is0Lat & og0Cancel_8)`（is0Lat 是真端口）。
//
// 自动生成：verif/ut/BusyTable/gen.py —— 勿手改
// ============================================================================
module BusyTable_3(
  input        clock,
  input        reset,
  input        io_allocPregs_0_valid,
  input  [7:0] io_allocPregs_0_bits,
  input        io_allocPregs_1_valid,
  input  [7:0] io_allocPregs_1_bits,
  input        io_allocPregs_2_valid,
  input  [7:0] io_allocPregs_2_bits,
  input        io_allocPregs_3_valid,
  input  [7:0] io_allocPregs_3_bits,
  input        io_allocPregs_4_valid,
  input  [7:0] io_allocPregs_4_bits,
  input        io_allocPregs_5_valid,
  input  [7:0] io_allocPregs_5_bits,
  input        io_wbPregs_0_valid,
  input  [7:0] io_wbPregs_0_bits,
  input        io_wbPregs_1_valid,
  input  [7:0] io_wbPregs_1_bits,
  input        io_wbPregs_2_valid,
  input  [7:0] io_wbPregs_2_bits,
  input        io_wbPregs_3_valid,
  input  [7:0] io_wbPregs_3_bits,
  input        io_wbPregs_4_valid,
  input  [7:0] io_wbPregs_4_bits,
  input        io_wbPregs_5_valid,
  input  [7:0] io_wbPregs_5_bits,
  input        io_wakeUpFp_0_valid,
  input        io_wakeUpFp_0_bits_v0Wen,
  input  [7:0] io_wakeUpFp_0_bits_pdest,
  input        io_wakeUpFp_0_bits_is0Lat,
  input        io_og0Cancel_8,
  input  [7:0] io_read_0_req,
  output       io_read_0_resp,
  input  [7:0] io_read_1_req,
  output       io_read_1_resp,
  input  [7:0] io_read_2_req,
  output       io_read_2_resp,
  input  [7:0] io_read_3_req,
  output       io_read_3_resp,
  input  [7:0] io_read_4_req,
  output       io_read_4_resp,
  input  [7:0] io_read_5_req,
  output       io_read_5_resp
);

  logic [6-1:0] core_read_resp;

  xs_BusyTable_core #(
    .NUM_PREGS        (22),
    .NUM_ALLOC        (6),
    .NUM_WB           (6),
    .NUM_READ         (6),
    .NUM_WAKEUP       (1),
    .HAS_LOAD_DEP     (0),
    .ZERO_ALWAYS_READY(0),
    .HAS_VL           (0),
    .WK_FROM_LOAD     (8'b00000000),
    .WK_LD_ONEHOT     ({3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0})
  ) u_core (
    .clock (clock),
    .reset (reset),
    .alloc_valid({io_allocPregs_5_valid, io_allocPregs_4_valid, io_allocPregs_3_valid, io_allocPregs_2_valid, io_allocPregs_1_valid, io_allocPregs_0_valid}),
    .alloc_preg ({io_allocPregs_5_bits, io_allocPregs_4_bits, io_allocPregs_3_bits, io_allocPregs_2_bits, io_allocPregs_1_bits, io_allocPregs_0_bits}),
    .wb_valid   ({io_wbPregs_5_valid, io_wbPregs_4_valid, io_wbPregs_3_valid, io_wbPregs_2_valid, io_wbPregs_1_valid, io_wbPregs_0_valid}),
    .wb_preg    ({io_wbPregs_5_bits, io_wbPregs_4_bits, io_wbPregs_3_bits, io_wbPregs_2_bits, io_wbPregs_1_bits, io_wbPregs_0_bits}),
    .wk_valid    (io_wakeUpFp_0_valid),
    .wk_wen      (io_wakeUpFp_0_bits_v0Wen),
    .wk_pdest    (io_wakeUpFp_0_bits_pdest),
    .wk_is0lat   (io_wakeUpFp_0_bits_is0Lat),
    .wk_og0cancel(io_og0Cancel_8),
    .wk_load_dep ({6{1'b0}}),
    .ld_cancel  ({3{1'b0}}),
    .read_req      ({io_read_5_req, io_read_4_req, io_read_3_req, io_read_2_req, io_read_1_req, io_read_0_req}),
    .read_resp     (core_read_resp),
    .read_load_dep (/* unused */),
    .vl_from_int_is_zero (1'b0),
    .vl_from_int_is_vlmax(1'b0),
    .vl_from_vf_is_zero  (1'b0),
    .vl_from_vf_is_vlmax (1'b0),
    .vl_is_nonzero       (/* unused */),
    .vl_is_vlmax         (/* unused */)
  );

  assign io_read_0_resp = core_read_resp[0];
  assign io_read_1_resp = core_read_resp[1];
  assign io_read_2_resp = core_read_resp[2];
  assign io_read_3_resp = core_read_resp[3];
  assign io_read_4_resp = core_read_resp[4];
  assign io_read_5_resp = core_read_resp[5];

endmodule
