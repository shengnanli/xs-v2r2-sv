// ============================================================================
// FuBusyTableWrite_75.sv —— FuBusyTableWrite 家族薄 wrapper：表宽 4（3 个槽），有og0、无og1
// 例化者：IssueQueueVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf.sv
// 槽表：0=空、1=vfalu(24)、2=vipu(18) | vfcvt(27)
// ★golden 不对称：本变体「下移两格」的掩码非零，却没有 og1Resp 端口
//   （Chisel 侧该队列就没接 og1）—— 所以 HAS_OG1 是独立参数，不是派生量。
//
// 本文件只做参数设定与端口对位，核体见 rtl/backend/FuBusyTableWrite.sv，全家族共一份。
// 由 scripts/gen_fubusy_wbarb.py 生成，勿手改；差异维度矩阵见
// verif/ut/FuBusyTableWriteVariants/README.md。
// golden 对照：G1-canonical/golden-rtl/FuBusyTableWrite_75.sv
// ============================================================================
module FuBusyTableWrite_75(
  input         clock,
  input         reset,
  input         io_in_deqResp_valid,
  input  [34:0] io_in_deqResp_bits_fuType,
  input         io_in_og0Resp_valid,
  input  [34:0] io_in_og0Resp_bits_fuType,
  output [3:0]  io_out_fuBusyTable
);
  localparam int NSLOT = 3;
  localparam logic [7:0][34:0] SLOT_SEL = '{
    35'h0           ,   // 槽 7：本变体没有
    35'h0           ,   // 槽 6：本变体没有
    35'h0           ,   // 槽 5：本变体没有
    35'h0           ,   // 槽 4：本变体没有
    35'h0           ,   // 槽 3：本变体没有
    35'h8040000     ,   // 槽 2：vipu(18) | vfcvt(27)
    35'h1000000     ,   // 槽 1：vfalu(24)
    35'h0           };   // 槽 0：空

  xs_FuBusyTableWrite_core #(
    .NSLOT(NSLOT), .HAS_OG0(1'b1), .HAS_OG1(1'b0), .SLOT_SEL(SLOT_SEL)
  ) u_core (
    .clock         (clock),
    .reset         (reset),
    .deq_valid     (io_in_deqResp_valid),
    .deq_fu_type   (io_in_deqResp_bits_fuType),
    .og0_valid     (io_in_og0Resp_valid),
    .og0_fu_type   (io_in_og0Resp_bits_fuType),
    .og1_valid     (1'b0),   // golden 本变体无 og1Resp 端口
    .og1_resp      (2'b0),
    .og1_fu_type   (35'b0),
    .fu_busy_table (io_out_fuBusyTable)
  );
endmodule
