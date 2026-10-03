// =============================================================================
// OffsetScoreTable —— BOP 偏移评分表（xs_OffsetScoreTable_core 家族变体）
//
// 本变体例化在 PBestOffsetPrefetch（按物理地址训练） 里：
//   训练地址 48 位；候选偏移 37 个、7 位补码；得分 5 位；ROUND_MAX=50；BAD_SCORE=1。
//   候选限制在同一页内（±32 块以内），故只有 37 个。
// 机制与怪癖见 xs_OffsetScoreTable_core.sv；本层只做端口改名、设参与列候选偏移表。
// =============================================================================

module OffsetScoreTable(
  input         clock,
  input         reset,
  output        io_req_ready,
  input         io_req_valid,
  input  [47:0] io_req_bits,
  output [6:0]  io_prefetchOffset,
  output        io_prefetchDisable,
  output        io_test_req_valid,
  output [47:0] io_test_req_bits_addr,
  output [6:0]  io_test_req_bits_testOffset,
  output [5:0]  io_test_req_bits_ptr,
  input         io_test_resp_valid,
  input  [5:0]  io_test_resp_bits_ptr,
  input         io_test_resp_bits_hit
);

  localparam int unsigned N        = 37;
  localparam int unsigned OFFSET_W = 7;

  // 候选偏移表（单位：cache 块），下标 0 在最前
  localparam logic [0:N-1][OFFSET_W-1:0] OFFSET_LIST = {
    7'(-32), 7'(-30), 7'(-27), 7'(-25), 7'(-24), 7'(-20), 7'(-18), 7'(-16),
    7'(-15), 7'(-12), 7'(-10), 7'(-9), 7'(-8), 7'(-6), 7'(-5), 7'(-4),
    7'(-3), 7'(-2), 7'(-1), 7'(1), 7'(2), 7'(3), 7'(4), 7'(5),
    7'(6), 7'(8), 7'(9), 7'(10), 7'(12), 7'(15), 7'(16), 7'(18),
    7'(20), 7'(24), 7'(25), 7'(27), 7'(30)
  };

  xs_OffsetScoreTable_core #(
    .ADDR_W     (48),
    .OFFSET_W   (OFFSET_W),
    .N          (N),
    .PTR_W      (6),
    .SCORE_W    (5),
    .ROUND_W    (6),
    .ROUND_MAX  (50),
    .BAD_SCORE  (1),
    .OFFSET_LIST(OFFSET_LIST)
  ) u_core (
    .clock           (clock),
    .reset           (reset),
    .req_ready       (io_req_ready),
    .req_valid       (io_req_valid),
    .req_addr        (io_req_bits),
    .prefetch_offset (io_prefetchOffset),
    .prefetch_disable(io_prefetchDisable),
    .test_req_valid  (io_test_req_valid),
    .test_req_addr   (io_test_req_bits_addr),
    .test_req_offset (io_test_req_bits_testOffset),
    .test_req_ptr    (io_test_req_bits_ptr),
    .test_resp_valid (io_test_resp_valid),
    .test_resp_ptr   (io_test_resp_bits_ptr),
    .test_resp_hit   (io_test_resp_bits_hit)
  );

endmodule
