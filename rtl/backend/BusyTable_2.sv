// BusyTable_2.sv —— 物理寄存器忙位表（Vf 向量/浮点堆变体）薄包装层
// -----------------------------------------------------------------------------
// 核体见 xs_BusyTable_core.sv（家族共享参数化核）。本文件只做端口打包与参数设定。
//
// 本变体规模（全部从 G1 golden BusyTable_2.sv 机械量得）：
//   表深 128 项（VfPhyRegs）；分配口 6；写回口 6；读口 18
//   快速唤醒 **1 路**：wakeUpFp_0，但门控位是 **vecWen** 不是 fpWen
//     （Chisel 把 wakeUpInt++wakeUpFp++wakeUpVec++wakeUpMem 拼起来再按 writeVfRf 过滤，
//       活下来的那一路恰好挂在 io.wakeUpFp 这个 IO 束上，所以端口名叫 io_wakeUpFp_0_*
//       而门控位是 vecWen —— 名字与语义对不上是 golden 的事实，照抄。）
//   寄存器 128 个 = 纯忙位，异步复位到 0；无 loadDependency 影子、无 ldCancel 端口。
//   唤醒路数为 1 时 firtool 把 `|wakeupOHVec` 直接折成那一位本身（golden 里连
//   wakeupOHVec_* 这个名字都没有），功能不变。
//
// 唤醒取消路由：wk0 = `~(is0Lat & og0Cancel_8)`（is0Lat 是真端口）。
//
// 自动生成：verif/ut/BusyTable/gen.py —— 勿手改
// ============================================================================
module BusyTable_2(
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
  input        io_wakeUpFp_0_bits_vecWen,
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
  output       io_read_5_resp,
  input  [7:0] io_read_6_req,
  output       io_read_6_resp,
  input  [7:0] io_read_7_req,
  output       io_read_7_resp,
  input  [7:0] io_read_8_req,
  output       io_read_8_resp,
  input  [7:0] io_read_9_req,
  output       io_read_9_resp,
  input  [7:0] io_read_10_req,
  output       io_read_10_resp,
  input  [7:0] io_read_11_req,
  output       io_read_11_resp,
  input  [7:0] io_read_12_req,
  output       io_read_12_resp,
  input  [7:0] io_read_13_req,
  output       io_read_13_resp,
  input  [7:0] io_read_14_req,
  output       io_read_14_resp,
  input  [7:0] io_read_15_req,
  output       io_read_15_resp,
  input  [7:0] io_read_16_req,
  output       io_read_16_resp,
  input  [7:0] io_read_17_req,
  output       io_read_17_resp
);

  logic [18-1:0] core_read_resp;

  xs_BusyTable_core #(
    .NUM_PREGS        (128),
    .NUM_ALLOC        (6),
    .NUM_WB           (6),
    .NUM_READ         (18),
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
    .wk_wen      (io_wakeUpFp_0_bits_vecWen),
    .wk_pdest    (io_wakeUpFp_0_bits_pdest),
    .wk_is0lat   (io_wakeUpFp_0_bits_is0Lat),
    .wk_og0cancel(io_og0Cancel_8),
    .wk_load_dep ({6{1'b0}}),
    .ld_cancel  ({3{1'b0}}),
    .read_req      ({io_read_17_req, io_read_16_req, io_read_15_req, io_read_14_req, io_read_13_req, io_read_12_req, io_read_11_req, io_read_10_req, io_read_9_req, io_read_8_req, io_read_7_req, io_read_6_req, io_read_5_req, io_read_4_req, io_read_3_req, io_read_2_req, io_read_1_req, io_read_0_req}),
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
  assign io_read_6_resp = core_read_resp[6];
  assign io_read_7_resp = core_read_resp[7];
  assign io_read_8_resp = core_read_resp[8];
  assign io_read_9_resp = core_read_resp[9];
  assign io_read_10_resp = core_read_resp[10];
  assign io_read_11_resp = core_read_resp[11];
  assign io_read_12_resp = core_read_resp[12];
  assign io_read_13_resp = core_read_resp[13];
  assign io_read_14_resp = core_read_resp[14];
  assign io_read_15_resp = core_read_resp[15];
  assign io_read_16_resp = core_read_resp[16];
  assign io_read_17_resp = core_read_resp[17];

endmodule
