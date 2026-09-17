// VlBusyTable.sv —— 向量长度(vl)寄存器忙位表 + 两张 vl 谓词表，薄包装层
// -----------------------------------------------------------------------------
// 核体见 xs_BusyTable_core.sv（家族共享参数化核，HAS_VL=1 打开本变体专属的两张表）。
//
// 本变体规模（全部从 G1 golden VlBusyTable.sv 机械量得）：
//   表深 32 项（VlPhyRegs）；分配口 6；写回口 **4**；读口 6
//   快速唤醒 **0 路** —— Chisel 显式 `allWakeUp.filter(x => false)`，
//     源码注释给了原因：ldCancel 没接到 vl 表，接快速唤醒会让 vsetvli 出错。
//     于是 golden 里连 og0Cancel / ldCancel / wakeUp 端口都没有。
//   寄存器 96 个 = 32 × 3 张表（忙位 / nonzeroTable / vlmaxTable），全部异步复位到 0。
//
// 两张附加表（VlBusyTable extends BusyTable 加出来的）：
//   vl 是写回时才知道的值，后级只关心两个谓词「vl≠0」「vl=vlmax」。
//   写回口语义按端口号分（golden 实测 intSchdVlWbPort=0、vfSchdVlWbPort=1）：
//     wbPregs[0] → 用 vlFromInt{IsZero,IsVlmax} 填表
//     wbPregs[1] → 用 vlFromVf{IsZero,IsVlmax} 填表
//     wbPregs[2..3] → 不知道 vl 是多少，只能置「未知 = 忙」
//   vlmaxTable 存的是取反值（golden 写 `~vlFromIntIsVlmax`），读口再取反一次。
//   这两张表的读口**没有**分配旁路（忙位读口有）—— golden 就是这样，照抄。
//
// 自动生成：verif/ut/BusyTable/gen.py —— 勿手改
// ============================================================================
module VlBusyTable(
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
  input        io_vl_Wb_vlWriteBackInfo_vlFromIntIsZero,
  input        io_vl_Wb_vlWriteBackInfo_vlFromIntIsVlmax,
  input        io_vl_Wb_vlWriteBackInfo_vlFromVfIsZero,
  input        io_vl_Wb_vlWriteBackInfo_vlFromVfIsVlmax,
  output       io_vl_read_vlReadInfo_0_is_nonzero,
  output       io_vl_read_vlReadInfo_0_is_vlmax,
  output       io_vl_read_vlReadInfo_1_is_nonzero,
  output       io_vl_read_vlReadInfo_1_is_vlmax,
  output       io_vl_read_vlReadInfo_2_is_nonzero,
  output       io_vl_read_vlReadInfo_2_is_vlmax,
  output       io_vl_read_vlReadInfo_3_is_nonzero,
  output       io_vl_read_vlReadInfo_3_is_vlmax,
  output       io_vl_read_vlReadInfo_4_is_nonzero,
  output       io_vl_read_vlReadInfo_4_is_vlmax,
  output       io_vl_read_vlReadInfo_5_is_nonzero,
  output       io_vl_read_vlReadInfo_5_is_vlmax
);

  logic [6-1:0] core_read_resp;
  logic [6-1:0] core_vl_is_nonzero, core_vl_is_vlmax;

  xs_BusyTable_core #(
    .NUM_PREGS        (32),
    .NUM_ALLOC        (6),
    .NUM_WB           (4),
    .NUM_READ         (6),
    .NUM_WAKEUP       (0),
    .HAS_LOAD_DEP     (0),
    .ZERO_ALWAYS_READY(0),
    .HAS_VL           (1),
    .WK_FROM_LOAD     (8'b00000000),
    .WK_LD_ONEHOT     ({3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0})
  ) u_core (
    .clock (clock),
    .reset (reset),
    .alloc_valid({io_allocPregs_5_valid, io_allocPregs_4_valid, io_allocPregs_3_valid, io_allocPregs_2_valid, io_allocPregs_1_valid, io_allocPregs_0_valid}),
    .alloc_preg ({io_allocPregs_5_bits, io_allocPregs_4_bits, io_allocPregs_3_bits, io_allocPregs_2_bits, io_allocPregs_1_bits, io_allocPregs_0_bits}),
    .wb_valid   ({io_wbPregs_3_valid, io_wbPregs_2_valid, io_wbPregs_1_valid, io_wbPregs_0_valid}),
    .wb_preg    ({io_wbPregs_3_bits, io_wbPregs_2_bits, io_wbPregs_1_bits, io_wbPregs_0_bits}),
    .wk_valid    (1'b0),
    .wk_wen      (1'b0),
    .wk_pdest    (8'b0),
    .wk_is0lat   (1'b0),
    .wk_og0cancel(1'b0),
    .wk_load_dep ({6{1'b0}}),
    .ld_cancel  ({3{1'b0}}),
    .read_req      ({io_read_5_req, io_read_4_req, io_read_3_req, io_read_2_req, io_read_1_req, io_read_0_req}),
    .read_resp     (core_read_resp),
    .read_load_dep (/* unused */),
    .vl_from_int_is_zero (io_vl_Wb_vlWriteBackInfo_vlFromIntIsZero),
    .vl_from_int_is_vlmax(io_vl_Wb_vlWriteBackInfo_vlFromIntIsVlmax),
    .vl_from_vf_is_zero  (io_vl_Wb_vlWriteBackInfo_vlFromVfIsZero),
    .vl_from_vf_is_vlmax (io_vl_Wb_vlWriteBackInfo_vlFromVfIsVlmax),
    .vl_is_nonzero       (core_vl_is_nonzero),
    .vl_is_vlmax         (core_vl_is_vlmax)
  );

  assign io_read_0_resp = core_read_resp[0];
  assign io_vl_read_vlReadInfo_0_is_nonzero = core_vl_is_nonzero[0];
  assign io_vl_read_vlReadInfo_0_is_vlmax = core_vl_is_vlmax[0];
  assign io_read_1_resp = core_read_resp[1];
  assign io_vl_read_vlReadInfo_1_is_nonzero = core_vl_is_nonzero[1];
  assign io_vl_read_vlReadInfo_1_is_vlmax = core_vl_is_vlmax[1];
  assign io_read_2_resp = core_read_resp[2];
  assign io_vl_read_vlReadInfo_2_is_nonzero = core_vl_is_nonzero[2];
  assign io_vl_read_vlReadInfo_2_is_vlmax = core_vl_is_vlmax[2];
  assign io_read_3_resp = core_read_resp[3];
  assign io_vl_read_vlReadInfo_3_is_nonzero = core_vl_is_nonzero[3];
  assign io_vl_read_vlReadInfo_3_is_vlmax = core_vl_is_vlmax[3];
  assign io_read_4_resp = core_read_resp[4];
  assign io_vl_read_vlReadInfo_4_is_nonzero = core_vl_is_nonzero[4];
  assign io_vl_read_vlReadInfo_4_is_vlmax = core_vl_is_vlmax[4];
  assign io_read_5_resp = core_read_resp[5];
  assign io_vl_read_vlReadInfo_5_is_nonzero = core_vl_is_nonzero[5];
  assign io_vl_read_vlReadInfo_5_is_vlmax = core_vl_is_vlmax[5];

endmodule
