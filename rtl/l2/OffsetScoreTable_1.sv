// =============================================================================
// OffsetScoreTable_1 —— BOP 偏移评分表（xs_OffsetScoreTable_core 家族变体）
//
// 本变体例化在 VBestOffsetPrefetch（按虚地址训练） 里：
//   训练地址 50 位；候选偏移 109 个、10 位补码；得分 5 位；ROUND_MAX=50；BAD_SCORE=2。
//   候选可跨页（±256 块）；表头 6 项（±117/±147/±91）是配置追加的偏移，其后是标准 BOP 偏移表的前 103 项。
// 机制与怪癖见 xs_OffsetScoreTable_core.sv；本层只做端口改名、设参与列候选偏移表。
// =============================================================================

module OffsetScoreTable_1(
  input         clock,
  input         reset,
  output        io_req_ready,
  input         io_req_valid,
  input  [49:0] io_req_bits,
  output [9:0]  io_prefetchOffset,
  output        io_prefetchDisable,
  output        io_test_req_valid,
  output [49:0] io_test_req_bits_addr,
  output [9:0]  io_test_req_bits_testOffset,
  output [6:0]  io_test_req_bits_ptr,
  input         io_test_resp_valid,
  input  [6:0]  io_test_resp_bits_ptr,
  input         io_test_resp_bits_hit
);

  localparam int unsigned N        = 109;
  localparam int unsigned OFFSET_W = 10;

  // 候选偏移表（单位：cache 块），下标 0 在最前
  localparam logic [0:N-1][OFFSET_W-1:0] OFFSET_LIST = {
    10'(-117), 10'(-147), 10'(-91), 10'(117), 10'(147), 10'(91), 10'(-256), 10'(-250),
    10'(-243), 10'(-240), 10'(-225), 10'(-216), 10'(-200), 10'(-192), 10'(-180), 10'(-162),
    10'(-160), 10'(-150), 10'(-144), 10'(-135), 10'(-128), 10'(-125), 10'(-120), 10'(-108),
    10'(-100), 10'(-96), 10'(-90), 10'(-81), 10'(-80), 10'(-75), 10'(-72), 10'(-64),
    10'(-60), 10'(-54), 10'(-50), 10'(-48), 10'(-45), 10'(-40), 10'(-36), 10'(-32),
    10'(-30), 10'(-27), 10'(-25), 10'(-24), 10'(-20), 10'(-18), 10'(-16), 10'(-15),
    10'(-12), 10'(-10), 10'(-9), 10'(-8), 10'(-6), 10'(-5), 10'(-4), 10'(-3),
    10'(-2), 10'(-1), 10'(1), 10'(2), 10'(3), 10'(4), 10'(5), 10'(6),
    10'(8), 10'(9), 10'(10), 10'(12), 10'(15), 10'(16), 10'(18), 10'(20),
    10'(24), 10'(25), 10'(27), 10'(30), 10'(32), 10'(36), 10'(40), 10'(45),
    10'(48), 10'(50), 10'(54), 10'(60), 10'(64), 10'(72), 10'(75), 10'(80),
    10'(81), 10'(90), 10'(96), 10'(100), 10'(108), 10'(120), 10'(125), 10'(128),
    10'(135), 10'(144), 10'(150), 10'(160), 10'(162), 10'(180), 10'(192), 10'(200),
    10'(216), 10'(225), 10'(240), 10'(243), 10'(250)
  };

  xs_OffsetScoreTable_core #(
    .ADDR_W     (50),
    .OFFSET_W   (OFFSET_W),
    .N          (N),
    .PTR_W      (7),
    .SCORE_W    (5),
    .ROUND_W    (6),
    .ROUND_MAX  (50),
    .BAD_SCORE  (2),
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
