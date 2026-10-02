// Queue1_BundleMap.sv —— AXI4UserYanker_2 给 id==0 的 AR 暂存 tl_state（size+source），R 通道 last 时弹出（深度 1，非 pipe）
//
// payload 19 位（tl_state_source + tl_state_size），父模块 AXI4UserYanker_2。
// ram 字（lsb 起）：tl_state_size[3:0]  tl_state_source[18:4]
// PIPE=0：enq_ready = ~full，满时拒收；同拍入出不存在（结构性）。
// 控制 + 存储复用共享核 rtl/common/xs_ChiselQueue1_core.sv（语义见该文件头，Queue1_ChosenQBundle 同用）；本文件只把字段按 golden 的顺序拼成整字、再拆回来。
// golden 139 行；端口表与连线由 scripts/gen_depth1queue_leaves5.py 从 golden 机械生成并逐字段校验。


// BEGIN GENERATED(Queue1_BundleMap) —— scripts/gen_depth1queue_leaves5.py
module Queue1_BundleMap (
  input  logic clock,
  input  logic reset,
  output logic io_enq_ready,
  input  logic io_enq_valid,
  input  logic [3:0] io_enq_bits_tl_state_size,
  input  logic [14:0] io_enq_bits_tl_state_source,
  input  logic io_deq_ready,
  output logic io_deq_valid,
  output logic [3:0] io_deq_bits_tl_state_size,
  output logic [14:0] io_deq_bits_tl_state_source
);

  logic [18:0] enqWord, deqWord;

  // 入队字（高位在前，照 golden 的 ram 拼接顺序）
  assign enqWord = {
    io_enq_bits_tl_state_source,
    io_enq_bits_tl_state_size
  };

  xs_ChiselQueue1_core #(.W(19), .PIPE(1'b0)) u_core (
    .clock     (clock),
    .reset     (reset),
    .enq_valid (io_enq_valid),
    .enq_ready (io_enq_ready),
    .enq_word  (enqWord),
    .deq_valid (io_deq_valid),
    .deq_ready (io_deq_ready),
    .deq_word  (deqWord)
  );

  assign io_deq_bits_tl_state_size = deqWord[3:0];
  assign io_deq_bits_tl_state_source = deqWord[18:4];

endmodule
// END GENERATED(Queue1_BundleMap)
