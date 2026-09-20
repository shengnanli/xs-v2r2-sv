// ============================================================================
// FuBusyTableWrite_42.sv —— FuBusyTableWrite 家族薄 wrapper：表宽 4（3 个槽），有og0、有og1
// 例化者：IssueQueueFaluFcvtF2vFmacFdiv.sv
// 槽表：0=falu(11)、1=fcvt(13)、2=fmac(12)
//
// 本文件只做参数设定与端口对位，核体见 rtl/backend/FuBusyTableWrite.sv，全家族共一份。
// 由 scripts/gen_fubusy_wbarb.py 生成，勿手改；差异维度矩阵见
// verif/ut/FuBusyTableWriteVariants/README.md。
// golden 对照：G1-canonical/golden-rtl/FuBusyTableWrite_42.sv
// ============================================================================
module FuBusyTableWrite_42(
  input         clock,
  input         reset,
  input         io_in_deqResp_valid,
  input  [34:0] io_in_deqResp_bits_fuType,
  input         io_in_og0Resp_valid,
  input  [34:0] io_in_og0Resp_bits_fuType,
  input         io_in_og1Resp_valid,
  input  [1:0]  io_in_og1Resp_bits_resp,
  input  [34:0] io_in_og1Resp_bits_fuType,
  output [3:0]  io_out_fuBusyTable
);
  localparam int NSLOT = 3;
  localparam logic [7:0][34:0] SLOT_SEL = '{
    35'h0           ,   // 槽 7：本变体没有
    35'h0           ,   // 槽 6：本变体没有
    35'h0           ,   // 槽 5：本变体没有
    35'h0           ,   // 槽 4：本变体没有
    35'h0           ,   // 槽 3：本变体没有
    35'h1000        ,   // 槽 2：fmac(12)
    35'h2000        ,   // 槽 1：fcvt(13)
    35'h800         };   // 槽 0：falu(11)

  xs_FuBusyTableWrite_core #(
    .NSLOT(NSLOT), .HAS_OG0(1'b1), .HAS_OG1(1'b1), .SLOT_SEL(SLOT_SEL)
  ) u_core (
    .clock         (clock),
    .reset         (reset),
    .deq_valid     (io_in_deqResp_valid),
    .deq_fu_type   (io_in_deqResp_bits_fuType),
    .og0_valid     (io_in_og0Resp_valid),
    .og0_fu_type   (io_in_og0Resp_bits_fuType),
    .og1_valid     (io_in_og1Resp_valid),
    .og1_resp      (io_in_og1Resp_bits_resp),
    .og1_fu_type   (io_in_og1Resp_bits_fuType),
    .fu_busy_table (io_out_fuBusyTable)
  );
endmodule
