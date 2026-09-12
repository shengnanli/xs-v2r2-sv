// Queue1_RegMapperInput_5 —— ICacheCtrlUnit 的 RegMapper 输入队列（深度 1 skid buffer）
// 例化点（G1 golden）：ICacheCtrlUnit.out_back_q，全设计仅此一处。
// 本变体参数：INDEX_W=4，DATA_W=64，MASK_W=8，SOURCE_W=5，SIZE_W=2。
// 端口规模：10 输入 / 8 输出。核体（xs_Queue1_RegMapperInput）与队列语义说明
// 在 rtl/frontend/ICacheCtrlUnit.sv 文件头；本文件只做参数固化与端口直连。
//
// ★名字警告★：G0(v2r2) 里这个队列叫 Queue1_RegMapperInput_3；G1 里叫 _3 的是
// 另一个模块（MemMisc.out_back_q / TLPMA.out_back_q，index 9 位 / source 15 位）。
// 同时 TileLink source 宽度从 3 位加到了 5 位（ICacheCtrlUnit 的 auto_in_*_bits_source
// 同步 3->5），所以本变体不是"纯改名"，端口位宽也变了。
// 判据：例化点比对，见 scripts/check_name_collisions.py。

module Queue1_RegMapperInput_5(
  input         clock,
  input         reset,
  output        io_enq_ready,
  input         io_enq_valid,
  input         io_enq_bits_read,
  input  [3:0]  io_enq_bits_index,
  input  [63:0] io_enq_bits_data,
  input  [7:0]  io_enq_bits_mask,
  input  [4:0]  io_enq_bits_extra_tlrr_extra_source,
  input  [1:0]  io_enq_bits_extra_tlrr_extra_size,
  input         io_deq_ready,
  output        io_deq_valid,
  output        io_deq_bits_read,
  output [3:0]  io_deq_bits_index,
  output [63:0] io_deq_bits_data,
  output [7:0]  io_deq_bits_mask,
  output [4:0]  io_deq_bits_extra_tlrr_extra_source,
  output [1:0]  io_deq_bits_extra_tlrr_extra_size
);
  xs_Queue1_RegMapperInput #(
    .INDEX_W(4), .DATA_W(64), .MASK_W(8), .SOURCE_W(5), .SIZE_W(2)
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
