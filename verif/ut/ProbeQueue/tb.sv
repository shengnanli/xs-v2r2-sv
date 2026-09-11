// 自动生成：scripts/gen_probequeue.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic io_mem_probe_valid;
  logic [2:0] io_mem_probe_bits_opcode;
  logic [1:0] io_mem_probe_bits_param;
  logic [47:0] io_mem_probe_bits_address;
  logic [255:0] io_mem_probe_bits_data;
  logic io_pipe_req_ready;
  logic io_lrsc_locked_block_valid;
  logic [47:0] io_lrsc_locked_block_bits;
  logic io_update_resv_set;
  wire g_io_mem_probe_ready;
  wire i_io_mem_probe_ready;
  wire g_io_pipe_req_valid;
  wire i_io_pipe_req_valid;
  wire [1:0] g_io_pipe_req_bits_probe_param;
  wire [1:0] i_io_pipe_req_bits_probe_param;
  wire g_io_pipe_req_bits_probe_need_data;
  wire i_io_pipe_req_bits_probe_need_data;
  wire [49:0] g_io_pipe_req_bits_vaddr;
  wire [49:0] i_io_pipe_req_bits_vaddr;
  wire [47:0] g_io_pipe_req_bits_addr;
  wire [47:0] i_io_pipe_req_bits_addr;
  wire [5:0] g_io_pipe_req_bits_id;
  wire [5:0] i_io_pipe_req_bits_id;
  wire [5:0] g_io_perf_0_value;
  wire [5:0] i_io_perf_0_value;
  wire [5:0] g_io_perf_1_value;
  wire [5:0] i_io_perf_1_value;
  wire [5:0] g_io_perf_2_value;
  wire [5:0] i_io_perf_2_value;
  wire [5:0] g_io_perf_3_value;
  wire [5:0] i_io_perf_3_value;
  wire [5:0] g_io_perf_4_value;
  wire [5:0] i_io_perf_4_value;
  ProbeQueue    u_g (.clock(clk), .reset(rst), .io_mem_probe_valid(io_mem_probe_valid), .io_mem_probe_bits_opcode(io_mem_probe_bits_opcode), .io_mem_probe_bits_param(io_mem_probe_bits_param), .io_mem_probe_bits_address(io_mem_probe_bits_address), .io_mem_probe_bits_data(io_mem_probe_bits_data), .io_pipe_req_ready(io_pipe_req_ready), .io_lrsc_locked_block_valid(io_lrsc_locked_block_valid), .io_lrsc_locked_block_bits(io_lrsc_locked_block_bits), .io_update_resv_set(io_update_resv_set), .io_mem_probe_ready(g_io_mem_probe_ready), .io_pipe_req_valid(g_io_pipe_req_valid), .io_pipe_req_bits_probe_param(g_io_pipe_req_bits_probe_param), .io_pipe_req_bits_probe_need_data(g_io_pipe_req_bits_probe_need_data), .io_pipe_req_bits_vaddr(g_io_pipe_req_bits_vaddr), .io_pipe_req_bits_addr(g_io_pipe_req_bits_addr), .io_pipe_req_bits_id(g_io_pipe_req_bits_id), .io_perf_0_value(g_io_perf_0_value), .io_perf_1_value(g_io_perf_1_value), .io_perf_2_value(g_io_perf_2_value), .io_perf_3_value(g_io_perf_3_value), .io_perf_4_value(g_io_perf_4_value));
  ProbeQueue_xs u_i (.clock(clk), .reset(rst), .io_mem_probe_valid(io_mem_probe_valid), .io_mem_probe_bits_opcode(io_mem_probe_bits_opcode), .io_mem_probe_bits_param(io_mem_probe_bits_param), .io_mem_probe_bits_address(io_mem_probe_bits_address), .io_mem_probe_bits_data(io_mem_probe_bits_data), .io_pipe_req_ready(io_pipe_req_ready), .io_lrsc_locked_block_valid(io_lrsc_locked_block_valid), .io_lrsc_locked_block_bits(io_lrsc_locked_block_bits), .io_update_resv_set(io_update_resv_set), .io_mem_probe_ready(i_io_mem_probe_ready), .io_pipe_req_valid(i_io_pipe_req_valid), .io_pipe_req_bits_probe_param(i_io_pipe_req_bits_probe_param), .io_pipe_req_bits_probe_need_data(i_io_pipe_req_bits_probe_need_data), .io_pipe_req_bits_vaddr(i_io_pipe_req_bits_vaddr), .io_pipe_req_bits_addr(i_io_pipe_req_bits_addr), .io_pipe_req_bits_id(i_io_pipe_req_bits_id), .io_perf_0_value(i_io_perf_0_value), .io_perf_1_value(i_io_perf_1_value), .io_perf_2_value(i_io_perf_2_value), .io_perf_3_value(i_io_perf_3_value), .io_perf_4_value(i_io_perf_4_value));
  always @(negedge clk) begin
    if (rst) begin
      io_lrsc_locked_block_valid <= 1'b0;
      io_update_resv_set <= 1'b0;
    end else begin
      io_mem_probe_bits_param <= 2'($urandom);
      io_mem_probe_bits_data <= 256'({$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()});
      io_lrsc_locked_block_valid <= ($urandom_range(0,3)==0);
      io_lrsc_locked_block_bits <= {39'($urandom_range(0,7)), 9'($urandom)};
      io_update_resv_set <= ($urandom_range(0,7)==0);
    end
  end

  // 在途 block 影子（按低 3 位 block tag，覆盖压窄后的 8 个 block）。
  // probe fire（mem_probe.valid & ready）→ 标记在途；pipe_req fire（probe 完成）→ 清。
  // 由于 entry id 与 block 非一一映射，这里用保守近似：probe 入队即标记其 block，
  // pipe_req 完成即清「最近一次完成的 probe block」——足以显著降低同 block 重发率。
  bit [7:0] blk_inflight;
  reg [2:0] last_probe_blk;
  always @(negedge clk) begin
    if (rst) begin
      io_mem_probe_valid        <= 1'b0;
      io_mem_probe_bits_opcode  <= 3'h6;   // Probe
      io_mem_probe_bits_address <= 48'h0;
      io_pipe_req_ready         <= 1'b1;
      blk_inflight              <= 8'h0;
      last_probe_blk            <= 3'h0;
    end else begin
      automatic bit [2:0] blk = 3'($urandom);
      automatic bit want = ($urandom_range(0,1));
      io_pipe_req_ready        <= ($urandom_range(0,3)!=0);
      io_mem_probe_bits_opcode <= 3'h6;
      // 只在该 block 未在途时发起 probe（保持激励合法）
      if (want && !blk_inflight[blk]) begin
        io_mem_probe_valid        <= 1'b1;
        io_mem_probe_bits_address <= {39'($urandom_range(0,7)), blk, 6'($urandom)};
      end else begin
        io_mem_probe_valid <= 1'b0;
      end
      // probe 入队（golden 接受）→ 标记在途（mem_probe_* 是共享输入，直接引用）
      if (io_mem_probe_valid && g_io_mem_probe_ready)
        blk_inflight[io_mem_probe_bits_address[8:6]] <= 1'b1;
      // probe 完成（送进主流水）→ 清该 block（近似：清所有在途中地址匹配项较难，
      // 这里清 pipe_req 这拍的 addr 对应 block）
      if (g_io_pipe_req_valid && io_pipe_req_ready)
        blk_inflight[g_io_pipe_req_bits_addr[8:6]] <= 1'b0;
    end
  end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (!$isunknown(g_io_mem_probe_ready) && g_io_mem_probe_ready !== i_io_mem_probe_ready) begin errors++;
      if(errors<=80) $display("[%0t] io_mem_probe_ready g=%h i=%h", $time, g_io_mem_probe_ready, i_io_mem_probe_ready); end
    if (!$isunknown(g_io_pipe_req_valid) && g_io_pipe_req_valid !== i_io_pipe_req_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_pipe_req_valid g=%h i=%h", $time, g_io_pipe_req_valid, i_io_pipe_req_valid); end
    if ((g_io_pipe_req_valid) && !$isunknown(g_io_pipe_req_bits_probe_param) && g_io_pipe_req_bits_probe_param !== i_io_pipe_req_bits_probe_param) begin errors++;
      if(errors<=80) $display("[%0t] io_pipe_req_bits_probe_param g=%h i=%h", $time, g_io_pipe_req_bits_probe_param, i_io_pipe_req_bits_probe_param); end
    if ((g_io_pipe_req_valid) && !$isunknown(g_io_pipe_req_bits_probe_need_data) && g_io_pipe_req_bits_probe_need_data !== i_io_pipe_req_bits_probe_need_data) begin errors++;
      if(errors<=80) $display("[%0t] io_pipe_req_bits_probe_need_data g=%h i=%h", $time, g_io_pipe_req_bits_probe_need_data, i_io_pipe_req_bits_probe_need_data); end
    if ((g_io_pipe_req_valid) && !$isunknown(g_io_pipe_req_bits_vaddr) && g_io_pipe_req_bits_vaddr !== i_io_pipe_req_bits_vaddr) begin errors++;
      if(errors<=80) $display("[%0t] io_pipe_req_bits_vaddr g=%h i=%h", $time, g_io_pipe_req_bits_vaddr, i_io_pipe_req_bits_vaddr); end
    if ((g_io_pipe_req_valid) && !$isunknown(g_io_pipe_req_bits_addr) && g_io_pipe_req_bits_addr !== i_io_pipe_req_bits_addr) begin errors++;
      if(errors<=80) $display("[%0t] io_pipe_req_bits_addr g=%h i=%h", $time, g_io_pipe_req_bits_addr, i_io_pipe_req_bits_addr); end
    if ((g_io_pipe_req_valid) && !$isunknown(g_io_pipe_req_bits_id) && g_io_pipe_req_bits_id !== i_io_pipe_req_bits_id) begin errors++;
      if(errors<=80) $display("[%0t] io_pipe_req_bits_id g=%h i=%h", $time, g_io_pipe_req_bits_id, i_io_pipe_req_bits_id); end
    if (!$isunknown(g_io_perf_0_value) && g_io_perf_0_value !== i_io_perf_0_value) begin errors++;
      if(errors<=80) $display("[%0t] io_perf_0_value g=%h i=%h", $time, g_io_perf_0_value, i_io_perf_0_value); end
    if (!$isunknown(g_io_perf_1_value) && g_io_perf_1_value !== i_io_perf_1_value) begin errors++;
      if(errors<=80) $display("[%0t] io_perf_1_value g=%h i=%h", $time, g_io_perf_1_value, i_io_perf_1_value); end
    if (!$isunknown(g_io_perf_2_value) && g_io_perf_2_value !== i_io_perf_2_value) begin errors++;
      if(errors<=80) $display("[%0t] io_perf_2_value g=%h i=%h", $time, g_io_perf_2_value, i_io_perf_2_value); end
    if (!$isunknown(g_io_perf_3_value) && g_io_perf_3_value !== i_io_perf_3_value) begin errors++;
      if(errors<=80) $display("[%0t] io_perf_3_value g=%h i=%h", $time, g_io_perf_3_value, i_io_perf_3_value); end
    if (!$isunknown(g_io_perf_4_value) && g_io_perf_4_value !== i_io_perf_4_value) begin errors++;
      if(errors<=80) $display("[%0t] io_perf_4_value g=%h i=%h", $time, g_io_perf_4_value, i_io_perf_4_value); end
  end
  initial begin
    rst = 1; repeat (16) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
