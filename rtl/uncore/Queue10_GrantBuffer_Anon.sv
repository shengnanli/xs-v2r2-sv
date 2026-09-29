// Queue10_GrantBuffer_Anon.sv —— GrantBuffer 的预取响应队列 pftRespQueue（10 项，非 2 的幂），flow
//
// chisel3 Queue(entries=10, flow=true) 的单态化（父模块 GrantBuffer）。控制逻辑全在
// rtl/common/xs_ChiselQueue_core.sv（语义讲在那里）；存储是 golden 的 ram_10x89 行为级
// 存储叶子（10 项 x 89 位；深度非 2 的幂，逐条审定入 verif/vendor_boundary.tsv，
// FM 两侧对称黑盒、VCS 两侧共用 golden 文件）。本文件只做字段拼接/拆分：
//   ram 字（lsb 起）：tag[30:0]  set[39:31]  vaddr[83:40]  pfSource[88:84]
// golden 185 行；端口表与连线由 scripts/gen_l2_queues.py 从 golden 机械生成并逐字段校验切片。

// BEGIN GENERATED(Queue10_GrantBuffer_Anon) —— scripts/gen_l2_queues.py
module Queue10_GrantBuffer_Anon (
  input  logic clock,
  input  logic reset,
  output logic io_enq_ready,
  input  logic io_enq_valid,
  input  logic [30:0] io_enq_bits_tag,
  input  logic [8:0] io_enq_bits_set,
  input  logic [43:0] io_enq_bits_vaddr,
  input  logic [4:0] io_enq_bits_pfSource,
  input  logic io_deq_ready,
  output logic io_deq_valid,
  output logic [30:0] io_deq_bits_tag,
  output logic [8:0] io_deq_bits_set,
  output logic [43:0] io_deq_bits_vaddr,
  output logic [4:0] io_deq_bits_pfSource,
  output logic [3:0] io_count
);

  logic             do_enq;
  logic [3:0]       enq_ptr, deq_ptr;
  logic             empty;
  logic [3:0]       count;
  logic             enq_ready, deq_valid;
  logic [88:0] ramReadWord;

  xs_ChiselQueue_core #(.DEPTH(10), .FLOW(1'b1)) u_core (
    .clock     (clock),
    .reset     (reset),
    .enq_valid (io_enq_valid),
    .enq_ready (enq_ready),
    .deq_valid (deq_valid),
    .deq_ready (io_deq_ready),
    .do_enq    (do_enq),
    .enq_ptr   (enq_ptr),
    .deq_ptr   (deq_ptr),
    .empty     (empty),
    .count     (count)
  );

  // 存储：写口在 enq_ptr、读口恒使能读 deq_ptr（组合读）
  ram_10x89 ram_ext (
    .R0_addr (deq_ptr),
    .R0_en   (1'b1),
    .R0_clk  (clock),
    .R0_data (ramReadWord),
    .W0_addr (enq_ptr),
    .W0_en   (do_enq),
    .W0_clk  (clock),
    .W0_data ({io_enq_bits_pfSource, io_enq_bits_vaddr, io_enq_bits_set, io_enq_bits_tag})
  );

  assign io_enq_ready = enq_ready;
  assign io_deq_valid = deq_valid;
  assign io_count     = count;
  // flow：队列空时 enq 数据直接旁路到 deq
  assign io_deq_bits_pfSource = empty ? io_enq_bits_pfSource : ramReadWord[88:84];
  assign io_deq_bits_vaddr = empty ? io_enq_bits_vaddr : ramReadWord[83:40];
  assign io_deq_bits_set = empty ? io_enq_bits_set : ramReadWord[39:31];
  assign io_deq_bits_tag = empty ? io_enq_bits_tag : ramReadWord[30:0];

endmodule
// END GENERATED(Queue10_GrantBuffer_Anon)
