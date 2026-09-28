// Queue1_RegMapperInput_6 —— DCache CtrlUnit 的 RegMapper 输入队列（深度 1 skid buffer）
// 例化点（G1 golden）：CtrlUnit.out_back_q，全设计仅此一处。
// 本变体参数：INDEX_W=4，DATA_W=64，MASK_W=8，SOURCE_W=4，SIZE_W=2。
// 端口规模：10 输入 / 8 输出。核体（xs_Queue1_RegMapperInput）与队列语义说明
// 在 rtl/frontend/ICacheCtrlUnit.sv 文件头；本文件只做参数固化与端口直连。
// 与 ICacheCtrlUnit 那一份（_5，source 5 位）唯一的差别是 TileLink source 宽 4 位：
// DCache 控制口挂在另一条 TL 外设总线上，source 编号空间不同（golden 端口表现读）。

module Queue1_RegMapperInput_6(
  input         clock,
  input         reset,
  output        io_enq_ready,
  input         io_enq_valid,
  input         io_enq_bits_read,
  input  [3:0]  io_enq_bits_index,
  input  [63:0] io_enq_bits_data,
  input  [7:0]  io_enq_bits_mask,
  input  [3:0]  io_enq_bits_extra_tlrr_extra_source,
  input  [1:0]  io_enq_bits_extra_tlrr_extra_size,
  input         io_deq_ready,
  output        io_deq_valid,
  output        io_deq_bits_read,
  output [3:0]  io_deq_bits_index,
  output [63:0] io_deq_bits_data,
  output [7:0]  io_deq_bits_mask,
  output [3:0]  io_deq_bits_extra_tlrr_extra_source,
  output [1:0]  io_deq_bits_extra_tlrr_extra_size
);
  localparam int unsigned INDEX_W  = 4;
  localparam int unsigned DATA_W   = 64;
  localparam int unsigned MASK_W   = 8;
  localparam int unsigned SOURCE_W = 4;
  localparam int unsigned SIZE_W   = 2;

  // 位宽自检（elaborate/time 0）：端口位宽必须与传给核体的参数一致。
  // 端口与参数不一致时（例化处会静默零扩展/截断）time 0 就炸。
  // （"端口 vs G1 golden" 那一层由 scripts/port_contract_lint.py 管。）
  initial begin
    if ($bits(io_enq_bits_extra_tlrr_extra_source) != SOURCE_W)
      $fatal(1, "Queue1_RegMapperInput_6: source 端口 %0d 位 != SOURCE_W %0d",
             $bits(io_enq_bits_extra_tlrr_extra_source), SOURCE_W);
    if ($bits(io_deq_bits_extra_tlrr_extra_source) != SOURCE_W)
      $fatal(1, "Queue1_RegMapperInput_6: deq source 端口 %0d 位 != SOURCE_W %0d",
             $bits(io_deq_bits_extra_tlrr_extra_source), SOURCE_W);
    if ($bits(io_enq_bits_index) != INDEX_W || $bits(io_enq_bits_data) != DATA_W ||
        $bits(io_enq_bits_mask) != MASK_W  || $bits(io_enq_bits_extra_tlrr_extra_size) != SIZE_W)
      $fatal(1, "Queue1_RegMapperInput_6: index/data/mask/size 端口位宽与参数不符");
    if (MASK_W * 8 != DATA_W)
      $fatal(1, "Queue1_RegMapperInput_6: MASK_W=%0d 与 DATA_W=%0d 不是字节掩码关系",
             MASK_W, DATA_W);
  end

  xs_Queue1_RegMapperInput #(
    .INDEX_W(INDEX_W), .DATA_W(DATA_W), .MASK_W(MASK_W),
    .SOURCE_W(SOURCE_W), .SIZE_W(SIZE_W)
  ) u_core (
    .clock                               (clock),
    .reset                               (reset),
    .io_enq_ready                        (io_enq_ready),
    .io_enq_valid                        (io_enq_valid),
    .io_enq_bits_read                    (io_enq_bits_read),
    .io_enq_bits_index                   (io_enq_bits_index),
    .io_enq_bits_data                    (io_enq_bits_data),
    .io_enq_bits_mask                    (io_enq_bits_mask),
    .io_enq_bits_extra_tlrr_extra_source (io_enq_bits_extra_tlrr_extra_source),
    .io_enq_bits_extra_tlrr_extra_size   (io_enq_bits_extra_tlrr_extra_size),
    .io_deq_ready                        (io_deq_ready),
    .io_deq_valid                        (io_deq_valid),
    .io_deq_bits_read                    (io_deq_bits_read),
    .io_deq_bits_index                   (io_deq_bits_index),
    .io_deq_bits_data                    (io_deq_bits_data),
    .io_deq_bits_mask                    (io_deq_bits_mask),
    .io_deq_bits_extra_tlrr_extra_source (io_deq_bits_extra_tlrr_extra_source),
    .io_deq_bits_extra_tlrr_extra_size   (io_deq_bits_extra_tlrr_extra_size)
  );
endmodule
