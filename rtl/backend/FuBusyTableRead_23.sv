// ============================================================================
// FuBusyTableRead_23.sv —— FuBusyTableRead 家族薄 wrapper：24 条目 / 表宽 1，槽 0=alu(6)
// 例化者：IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v.sv / IssueQueueAluCsrFenceDiv.sv
// golden 里 TW=1 但只有槽 0 出现在表达式里，其余槽的功能单元集合为空，
// 照抄为全 0 掩码（既不补齐也不少算）。
//
// 本文件只做参数设定与端口对位，核体见 rtl/backend/FuBusyTableRead.sv，全家族共一份。
// 由 scripts/gen_fubusy_wbarb.py 生成，勿手改；差异维度矩阵见
// verif/ut/FuBusyTableReadVariants/README.md。
// golden 对照：G1-canonical/golden-rtl/FuBusyTableRead_23.sv
// ============================================================================
module FuBusyTableRead_23(
  input         io_in_fuBusyTable,
  input  [34:0] io_in_fuTypeRegVec_0,
  input  [34:0] io_in_fuTypeRegVec_1,
  input  [34:0] io_in_fuTypeRegVec_2,
  input  [34:0] io_in_fuTypeRegVec_3,
  input  [34:0] io_in_fuTypeRegVec_4,
  input  [34:0] io_in_fuTypeRegVec_5,
  input  [34:0] io_in_fuTypeRegVec_6,
  input  [34:0] io_in_fuTypeRegVec_7,
  input  [34:0] io_in_fuTypeRegVec_8,
  input  [34:0] io_in_fuTypeRegVec_9,
  input  [34:0] io_in_fuTypeRegVec_10,
  input  [34:0] io_in_fuTypeRegVec_11,
  input  [34:0] io_in_fuTypeRegVec_12,
  input  [34:0] io_in_fuTypeRegVec_13,
  input  [34:0] io_in_fuTypeRegVec_14,
  input  [34:0] io_in_fuTypeRegVec_15,
  input  [34:0] io_in_fuTypeRegVec_16,
  input  [34:0] io_in_fuTypeRegVec_17,
  input  [34:0] io_in_fuTypeRegVec_18,
  input  [34:0] io_in_fuTypeRegVec_19,
  input  [34:0] io_in_fuTypeRegVec_20,
  input  [34:0] io_in_fuTypeRegVec_21,
  input  [34:0] io_in_fuTypeRegVec_22,
  input  [34:0] io_in_fuTypeRegVec_23,
  output [23:0] io_out_fuBusyTableMask
);
  localparam int NE = 24;
  localparam int TW = 1;
  localparam logic [7:0][34:0] FU_SEL = '{
    35'h0           ,   // 槽 7：本变体没有
    35'h0           ,   // 槽 6：本变体没有
    35'h0           ,   // 槽 5：本变体没有
    35'h0           ,   // 槽 4：本变体没有
    35'h0           ,   // 槽 3：本变体没有
    35'h0           ,   // 槽 2：本变体没有
    35'h0           ,   // 槽 1：本变体没有
    35'h40          };   // 槽 0：alu(6)

  logic [NE-1:0][34:0] fu_type;
  assign fu_type = {
    io_in_fuTypeRegVec_23, io_in_fuTypeRegVec_22, io_in_fuTypeRegVec_21, io_in_fuTypeRegVec_20,
    io_in_fuTypeRegVec_19, io_in_fuTypeRegVec_18, io_in_fuTypeRegVec_17, io_in_fuTypeRegVec_16,
    io_in_fuTypeRegVec_15, io_in_fuTypeRegVec_14, io_in_fuTypeRegVec_13, io_in_fuTypeRegVec_12,
    io_in_fuTypeRegVec_11, io_in_fuTypeRegVec_10, io_in_fuTypeRegVec_9, io_in_fuTypeRegVec_8,
    io_in_fuTypeRegVec_7, io_in_fuTypeRegVec_6, io_in_fuTypeRegVec_5, io_in_fuTypeRegVec_4,
    io_in_fuTypeRegVec_3, io_in_fuTypeRegVec_2, io_in_fuTypeRegVec_1, io_in_fuTypeRegVec_0};

  xs_FuBusyTableRead_core #(.NE(NE), .TW(TW), .FU_SEL(FU_SEL)) u_core (
    .fu_busy_table (io_in_fuBusyTable),
    .fu_type       (fu_type),
    .busy_mask     (io_out_fuBusyTableMask)
  );
endmodule
