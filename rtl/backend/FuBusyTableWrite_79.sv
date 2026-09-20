// ============================================================================
// FuBusyTableWrite_79.sv —— FuBusyTableWrite 家族薄 wrapper：表宽 2（1 个槽），无og0、无og1
// 例化者：IssueQueueVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf.sv
// 槽表：0=vsetfwf(30)
//
// 本文件只做参数设定与端口对位，核体见 rtl/backend/FuBusyTableWrite.sv，全家族共一份。
// 由 scripts/gen_fubusy_wbarb.py 生成，勿手改；差异维度矩阵见
// verif/ut/FuBusyTableWriteVariants/README.md。
// golden 对照：G1-canonical/golden-rtl/FuBusyTableWrite_79.sv
// ============================================================================
module FuBusyTableWrite_79(
  input         clock,
  input         reset,
  input         io_in_deqResp_valid,
  input  [34:0] io_in_deqResp_bits_fuType,
  output [1:0]  io_out_fuBusyTable
);
  localparam int NSLOT = 1;
  localparam logic [7:0][34:0] SLOT_SEL = '{
    35'h0           ,   // 槽 7：本变体没有
    35'h0           ,   // 槽 6：本变体没有
    35'h0           ,   // 槽 5：本变体没有
    35'h0           ,   // 槽 4：本变体没有
    35'h0           ,   // 槽 3：本变体没有
    35'h0           ,   // 槽 2：本变体没有
    35'h0           ,   // 槽 1：本变体没有
    35'h40000000    };   // 槽 0：vsetfwf(30)

  xs_FuBusyTableWrite_core #(
    .NSLOT(NSLOT), .HAS_OG0(1'b0), .HAS_OG1(1'b0), .SLOT_SEL(SLOT_SEL)
  ) u_core (
    .clock         (clock),
    .reset         (reset),
    .deq_valid     (io_in_deqResp_valid),
    .deq_fu_type   (io_in_deqResp_bits_fuType),
    .og0_valid     (1'b0),   // golden 本变体无 og0Resp 端口
    .og0_fu_type   (35'b0),
    .og1_valid     (1'b0),   // golden 本变体无 og1Resp 端口
    .og1_resp      (2'b0),
    .og1_fu_type   (35'b0),
    .fu_busy_table (io_out_fuBusyTable)
  );
endmodule
