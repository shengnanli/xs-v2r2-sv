// =============================================================================
// TrainFilter_1 —— L1Prefetcher 里送给 SMS 的训练过滤器（xs_TrainFilter_core 变体）
//
// 随行载荷 = {miss, meta_prefetch[2:0]}（4 位）走重排序流水；入 FIFO 时折成
// {miss, pfHitStream}（pfHitStream = meta_prefetch == L1_HW_PREFETCH_STREAM = 3）。FIFO 深 4（TrainFilter 是 6）。
// 机制与怪癖见 xs_TrainFilter_core.sv；本层只做端口改名、拼/拆载荷与设参。
// =============================================================================

module TrainFilter_1(
  input         clock,
  input         reset,
  input         io_enable,
  input         io_ld_in_0_valid,
  input         io_ld_in_0_bits_uop_robIdx_flag,
  input  [7:0]  io_ld_in_0_bits_uop_robIdx_value,
  input  [49:0] io_ld_in_0_bits_vaddr,
  input         io_ld_in_0_bits_miss,
  input  [2:0]  io_ld_in_0_bits_meta_prefetch,
  input         io_ld_in_1_valid,
  input         io_ld_in_1_bits_uop_robIdx_flag,
  input  [7:0]  io_ld_in_1_bits_uop_robIdx_value,
  input  [49:0] io_ld_in_1_bits_vaddr,
  input         io_ld_in_1_bits_miss,
  input  [2:0]  io_ld_in_1_bits_meta_prefetch,
  input         io_ld_in_2_valid,
  input         io_ld_in_2_bits_uop_robIdx_flag,
  input  [7:0]  io_ld_in_2_bits_uop_robIdx_value,
  input  [49:0] io_ld_in_2_bits_vaddr,
  input         io_ld_in_2_bits_miss,
  input  [2:0]  io_ld_in_2_bits_meta_prefetch,
  input         io_train_req_ready,
  output        io_train_req_valid,
  output [49:0] io_train_req_bits_vaddr,
  output        io_train_req_bits_miss,
  output        io_train_req_bits_pfHitStream
);

  logic [1:0] train_payload;

  xs_TrainFilter_core #(
    .VADDR_W          (50),
    .ROB_W            (8),
    .ENTRIES          (4),
    .PL_IN_W          (4),
    .PL_ENT_W         (2),
    .ENTRY_FOLD_STREAM(1'b1),
    .STREAM_CODE      (3'd3)
  ) u_core (
    .clock        (clock),
    .reset        (reset),
    .enable       (io_enable),
    .in_valid     ('{io_ld_in_0_valid, io_ld_in_1_valid, io_ld_in_2_valid}),
    .in_vaddr     ('{io_ld_in_0_bits_vaddr, io_ld_in_1_bits_vaddr, io_ld_in_2_bits_vaddr}),
    .in_rob_flag  ('{io_ld_in_0_bits_uop_robIdx_flag, io_ld_in_1_bits_uop_robIdx_flag, io_ld_in_2_bits_uop_robIdx_flag}),
    .in_rob_value ('{io_ld_in_0_bits_uop_robIdx_value, io_ld_in_1_bits_uop_robIdx_value, io_ld_in_2_bits_uop_robIdx_value}),
    .in_payload   ('{{io_ld_in_0_bits_miss, io_ld_in_0_bits_meta_prefetch},
                     {io_ld_in_1_bits_miss, io_ld_in_1_bits_meta_prefetch},
                     {io_ld_in_2_bits_miss, io_ld_in_2_bits_meta_prefetch}}),
    .train_ready  (io_train_req_ready),
    .train_valid  (io_train_req_valid),
    .train_vaddr  (io_train_req_bits_vaddr),
    .train_payload(train_payload)
  );

  assign {io_train_req_bits_miss, io_train_req_bits_pfHitStream} = train_payload;

endmodule
