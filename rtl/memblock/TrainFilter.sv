// =============================================================================
// TrainFilter —— L1Prefetcher（stream/stride）的训练过滤器（xs_TrainFilter_core 变体）
//
// 随行载荷 = uop.pc（50 位），原样进 FIFO 并随 train_req 带出。
// 机制与怪癖见 xs_TrainFilter_core.sv；本层只做端口改名与设参。
// =============================================================================

module TrainFilter(
  input         clock,
  input         reset,
  input         io_enable,
  input         io_ld_in_0_valid,
  input  [49:0] io_ld_in_0_bits_uop_pc,
  input         io_ld_in_0_bits_uop_robIdx_flag,
  input  [7:0]  io_ld_in_0_bits_uop_robIdx_value,
  input  [49:0] io_ld_in_0_bits_vaddr,
  input         io_ld_in_1_valid,
  input  [49:0] io_ld_in_1_bits_uop_pc,
  input         io_ld_in_1_bits_uop_robIdx_flag,
  input  [7:0]  io_ld_in_1_bits_uop_robIdx_value,
  input  [49:0] io_ld_in_1_bits_vaddr,
  input         io_ld_in_2_valid,
  input  [49:0] io_ld_in_2_bits_uop_pc,
  input         io_ld_in_2_bits_uop_robIdx_flag,
  input  [7:0]  io_ld_in_2_bits_uop_robIdx_value,
  input  [49:0] io_ld_in_2_bits_vaddr,
  input         io_train_req_ready,
  output        io_train_req_valid,
  output [49:0] io_train_req_bits_vaddr,
  output [49:0] io_train_req_bits_pc
);

  xs_TrainFilter_core #(
    .VADDR_W          (50),
    .ROB_W            (8),
    .ENTRIES          (6),
    .PL_IN_W          (50),
    .PL_ENT_W         (50),
    .ENTRY_FOLD_STREAM(1'b0)
  ) u_core (
    .clock        (clock),
    .reset        (reset),
    .enable       (io_enable),
    .in_valid     ('{io_ld_in_0_valid, io_ld_in_1_valid, io_ld_in_2_valid}),
    .in_vaddr     ('{io_ld_in_0_bits_vaddr, io_ld_in_1_bits_vaddr, io_ld_in_2_bits_vaddr}),
    .in_rob_flag  ('{io_ld_in_0_bits_uop_robIdx_flag, io_ld_in_1_bits_uop_robIdx_flag, io_ld_in_2_bits_uop_robIdx_flag}),
    .in_rob_value ('{io_ld_in_0_bits_uop_robIdx_value, io_ld_in_1_bits_uop_robIdx_value, io_ld_in_2_bits_uop_robIdx_value}),
    .in_payload   ('{io_ld_in_0_bits_uop_pc, io_ld_in_1_bits_uop_pc, io_ld_in_2_bits_uop_pc}),
    .train_ready  (io_train_req_ready),
    .train_valid  (io_train_req_valid),
    .train_vaddr  (io_train_req_bits_vaddr),
    .train_payload(io_train_req_bits_pc)
  );

endmodule
