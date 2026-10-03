// =============================================================================
// SMSTrainFilter —— SMS 预取器的训练过滤器（xs_TrainFilter_core 变体）
//
// 随行载荷 = {paddr(48), pc(50)}，原样进 FIFO 并随 train_req 带出；FIFO 深 8，条目异步复位清零。
// 本配置下 st_in（2 路 store 训练）被上层接 0，golden 端口里没有它们；对应的 3/4 号入队指针
// 寄存器仍保留。没有 enable、train_req 是 ValidIO（无 ready）、没有 flush 寄存器。
// 机制与怪癖见 xs_TrainFilter_core.sv；本层只做端口改名、拼/拆载荷与设参。
// =============================================================================

module SMSTrainFilter(
  input         clock,
  input         reset,
  input         io_ld_in_0_valid,
  input  [49:0] io_ld_in_0_bits_uop_pc,
  input         io_ld_in_0_bits_uop_robIdx_flag,
  input  [7:0]  io_ld_in_0_bits_uop_robIdx_value,
  input  [49:0] io_ld_in_0_bits_vaddr,
  input  [47:0] io_ld_in_0_bits_paddr,
  input         io_ld_in_1_valid,
  input  [49:0] io_ld_in_1_bits_uop_pc,
  input         io_ld_in_1_bits_uop_robIdx_flag,
  input  [7:0]  io_ld_in_1_bits_uop_robIdx_value,
  input  [49:0] io_ld_in_1_bits_vaddr,
  input  [47:0] io_ld_in_1_bits_paddr,
  input         io_ld_in_2_valid,
  input  [49:0] io_ld_in_2_bits_uop_pc,
  input         io_ld_in_2_bits_uop_robIdx_flag,
  input  [7:0]  io_ld_in_2_bits_uop_robIdx_value,
  input  [49:0] io_ld_in_2_bits_vaddr,
  input  [47:0] io_ld_in_2_bits_paddr,
  output        io_train_req_valid,
  output [49:0] io_train_req_bits_vaddr,
  output [47:0] io_train_req_bits_paddr,
  output [49:0] io_train_req_bits_pc
);

  logic [97:0] train_payload;

  xs_TrainFilter_core #(
    .VADDR_W          (50),
    .ROB_W            (8),
    .ENTRIES          (8),
    .PL_IN_W          (98),
    .PL_ENT_W         (98),
    .ENTRY_FOLD_STREAM(1'b0),
    .ENQ_PTRS         (5),
    .ENTRY_RESET      (1'b1),
    .HAS_FLUSH_REG    (1'b0)
  ) u_core (
    .clock        (clock),
    .reset        (reset),
    .enable       (1'b1),
    .in_valid     ('{io_ld_in_0_valid, io_ld_in_1_valid, io_ld_in_2_valid}),
    .in_vaddr     ('{io_ld_in_0_bits_vaddr, io_ld_in_1_bits_vaddr, io_ld_in_2_bits_vaddr}),
    .in_rob_flag  ('{io_ld_in_0_bits_uop_robIdx_flag, io_ld_in_1_bits_uop_robIdx_flag, io_ld_in_2_bits_uop_robIdx_flag}),
    .in_rob_value ('{io_ld_in_0_bits_uop_robIdx_value, io_ld_in_1_bits_uop_robIdx_value, io_ld_in_2_bits_uop_robIdx_value}),
    .in_payload   ('{{io_ld_in_0_bits_paddr, io_ld_in_0_bits_uop_pc},
                     {io_ld_in_1_bits_paddr, io_ld_in_1_bits_uop_pc},
                     {io_ld_in_2_bits_paddr, io_ld_in_2_bits_uop_pc}}),
    .train_ready  (1'b1),
    .train_valid  (io_train_req_valid),
    .train_vaddr  (io_train_req_bits_vaddr),
    .train_payload(train_payload)
  );

  assign {io_train_req_bits_paddr, io_train_req_bits_pc} = train_payload;

endmodule
