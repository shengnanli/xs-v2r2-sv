// 自动生成：scripts/gen_icachectrlunit.py —— 勿手改
module ICacheCtrlUnit(
  input  clock,
  input  reset,
  output auto_in_a_ready,
  input  auto_in_a_valid,
  input  [3:0] auto_in_a_bits_opcode,
  input  [1:0] auto_in_a_bits_size,
  input  [2:0] auto_in_a_bits_source,
  input  [29:0] auto_in_a_bits_address,
  input  [7:0] auto_in_a_bits_mask,
  input  [63:0] auto_in_a_bits_data,
  input  auto_in_d_ready,
  output auto_in_d_valid,
  output [3:0] auto_in_d_bits_opcode,
  output [1:0] auto_in_d_bits_size,
  output [2:0] auto_in_d_bits_source,
  output [63:0] auto_in_d_bits_data,
  output io_ecc_enable,
  output io_injecting,
  input  io_metaRead_ready,
  output io_metaRead_valid,
  output [7:0] io_metaRead_bits_vSetIdx_0,
  output [7:0] io_metaRead_bits_vSetIdx_1,
  input  [35:0] io_metaReadResp_metas_0_0_tag,
  input  [35:0] io_metaReadResp_metas_0_1_tag,
  input  [35:0] io_metaReadResp_metas_0_2_tag,
  input  [35:0] io_metaReadResp_metas_0_3_tag,
  input  io_metaReadResp_entryValid_0_0,
  input  io_metaReadResp_entryValid_0_1,
  input  io_metaReadResp_entryValid_0_2,
  input  io_metaReadResp_entryValid_0_3,
  input  io_metaWrite_ready,
  output io_metaWrite_valid,
  output [7:0] io_metaWrite_bits_virIdx,
  output [35:0] io_metaWrite_bits_phyTag,
  output [3:0] io_metaWrite_bits_waymask,
  output io_metaWrite_bits_bankIdx,
  input  io_dataWrite_ready,
  output io_dataWrite_valid,
  output [7:0] io_dataWrite_bits_virIdx,
  output [3:0] io_dataWrite_bits_waymask
);

  // ---- RegMapper 输入队列（深度 1 skid buffer）：A 通道入队 ----
  wire        q_deq_valid;
  wire        q_deq_bits_read;
  wire [3:0]  q_deq_bits_index;
  wire [63:0] q_deq_bits_data;
  wire [7:0]  q_deq_bits_mask;

  xs_Queue1_RegMapperInput #(
    .INDEX_W(4), .DATA_W(64), .MASK_W(8), .SOURCE_W(3), .SIZE_W(2)
  ) out_back_q (
    .clock                               (clock),
    .reset                               (reset),
    .io_enq_ready                        (auto_in_a_ready),
    .io_enq_valid                        (auto_in_a_valid),
    .io_enq_bits_read                    (auto_in_a_bits_opcode == 4'h4), // Get
    .io_enq_bits_index                   (auto_in_a_bits_address[6:3]),
    .io_enq_bits_data                    (auto_in_a_bits_data),
    .io_enq_bits_mask                    (auto_in_a_bits_mask),
    .io_enq_bits_extra_tlrr_extra_source (auto_in_a_bits_source),
    .io_enq_bits_extra_tlrr_extra_size   (auto_in_a_bits_size),
    .io_deq_ready                        (auto_in_d_ready),
    .io_deq_valid                        (q_deq_valid),
    .io_deq_bits_read                    (q_deq_bits_read),
    .io_deq_bits_index                   (q_deq_bits_index),
    .io_deq_bits_data                    (q_deq_bits_data),
    .io_deq_bits_mask                    (q_deq_bits_mask),
    .io_deq_bits_extra_tlrr_extra_source (auto_in_d_bits_source),
    .io_deq_bits_extra_tlrr_extra_size   (auto_in_d_bits_size)
  );

  // D 通道：valid = 队列有响应；opcode = {3'h0, read}（AccessAck / AccessAckData）
  assign auto_in_d_valid       = q_deq_valid;
  assign auto_in_d_bits_opcode = {3'h0, q_deq_bits_read};

  // ---- 核心 ----
  xs_ICacheCtrlUnit_core #(
    .NWAY(4), .PADDR_W(48), .PTAG_W(36), .VSETIDX_W(8),
    .INDEX_W(4), .DATA_W(64), .MASK_W(8)
  ) u_core (
    .clock                          (clock),
    .reset                          (reset),
    .out_deq_valid                  (q_deq_valid),
    .out_deq_bits_read              (q_deq_bits_read),
    .out_deq_bits_index             (q_deq_bits_index),
    .out_deq_bits_data              (q_deq_bits_data),
    .out_deq_bits_mask              (q_deq_bits_mask),
    .auto_in_d_ready                (auto_in_d_ready),
    .auto_in_d_bits_data            (auto_in_d_bits_data),
    .io_ecc_enable                  (io_ecc_enable),
    .io_injecting                   (io_injecting),
    .io_metaRead_ready              (io_metaRead_ready),
    .io_metaRead_valid              (io_metaRead_valid),
    .io_metaRead_bits_vSetIdx_0     (io_metaRead_bits_vSetIdx_0),
    .io_metaRead_bits_vSetIdx_1     (io_metaRead_bits_vSetIdx_1),
    .io_metaReadResp_metas_0_0_tag  (io_metaReadResp_metas_0_0_tag),
    .io_metaReadResp_metas_0_1_tag  (io_metaReadResp_metas_0_1_tag),
    .io_metaReadResp_metas_0_2_tag  (io_metaReadResp_metas_0_2_tag),
    .io_metaReadResp_metas_0_3_tag  (io_metaReadResp_metas_0_3_tag),
    .io_metaReadResp_entryValid_0_0 (io_metaReadResp_entryValid_0_0),
    .io_metaReadResp_entryValid_0_1 (io_metaReadResp_entryValid_0_1),
    .io_metaReadResp_entryValid_0_2 (io_metaReadResp_entryValid_0_2),
    .io_metaReadResp_entryValid_0_3 (io_metaReadResp_entryValid_0_3),
    .io_metaWrite_ready             (io_metaWrite_ready),
    .io_metaWrite_valid             (io_metaWrite_valid),
    .io_metaWrite_bits_virIdx       (io_metaWrite_bits_virIdx),
    .io_metaWrite_bits_phyTag       (io_metaWrite_bits_phyTag),
    .io_metaWrite_bits_waymask      (io_metaWrite_bits_waymask),
    .io_metaWrite_bits_bankIdx      (io_metaWrite_bits_bankIdx),
    .io_dataWrite_ready             (io_dataWrite_ready),
    .io_dataWrite_valid             (io_dataWrite_valid),
    .io_dataWrite_bits_virIdx       (io_dataWrite_bits_virIdx),
    .io_dataWrite_bits_waymask      (io_dataWrite_bits_waymask)
  );

endmodule
