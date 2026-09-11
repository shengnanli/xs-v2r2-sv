// 自动生成：scripts/gen_writebackqueue.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic io_req_valid;
  logic [2:0] io_req_bits_param;
  logic io_req_bits_voluntary;
  logic io_req_bits_hasData;
  logic io_req_bits_corrupt;
  logic io_req_bits_dirty;
  logic [47:0] io_req_bits_addr;
  logic [511:0] io_req_bits_data;
  logic io_mem_release_ready;
  logic io_mem_grant_valid;
  logic [5:0] io_mem_grant_bits_source;
  logic io_miss_req_conflict_check_0_valid;
  logic [47:0] io_miss_req_conflict_check_0_bits;
  logic io_miss_req_conflict_check_1_valid;
  logic [47:0] io_miss_req_conflict_check_1_bits;
  logic io_miss_req_conflict_check_2_valid;
  logic [47:0] io_miss_req_conflict_check_2_bits;
  logic io_miss_req_conflict_check_3_valid;
  logic [47:0] io_miss_req_conflict_check_3_bits;
  logic io_miss_req_conflict_check_4_valid;
  logic [47:0] io_miss_req_conflict_check_4_bits;
  wire g_io_req_ready;
  wire i_io_req_ready;
  wire g_io_mem_release_valid;
  wire i_io_mem_release_valid;
  wire [2:0] g_io_mem_release_bits_opcode;
  wire [2:0] i_io_mem_release_bits_opcode;
  wire [2:0] g_io_mem_release_bits_param;
  wire [2:0] i_io_mem_release_bits_param;
  wire [2:0] g_io_mem_release_bits_size;
  wire [2:0] i_io_mem_release_bits_size;
  wire [5:0] g_io_mem_release_bits_source;
  wire [5:0] i_io_mem_release_bits_source;
  wire [47:0] g_io_mem_release_bits_address;
  wire [47:0] i_io_mem_release_bits_address;
  wire [255:0] g_io_mem_release_bits_data;
  wire [255:0] i_io_mem_release_bits_data;
  wire g_io_mem_release_bits_corrupt;
  wire i_io_mem_release_bits_corrupt;
  wire g_io_block_miss_req_0;
  wire i_io_block_miss_req_0;
  wire g_io_block_miss_req_1;
  wire i_io_block_miss_req_1;
  wire g_io_block_miss_req_2;
  wire i_io_block_miss_req_2;
  wire g_io_block_miss_req_3;
  wire i_io_block_miss_req_3;
  wire g_io_block_miss_req_4;
  wire i_io_block_miss_req_4;
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
  WritebackQueue    u_g (.clock(clk), .reset(rst), .io_req_valid(io_req_valid), .io_req_bits_param(io_req_bits_param), .io_req_bits_voluntary(io_req_bits_voluntary), .io_req_bits_hasData(io_req_bits_hasData), .io_req_bits_corrupt(io_req_bits_corrupt), .io_req_bits_dirty(io_req_bits_dirty), .io_req_bits_addr(io_req_bits_addr), .io_req_bits_data(io_req_bits_data), .io_mem_release_ready(io_mem_release_ready), .io_mem_grant_valid(io_mem_grant_valid), .io_mem_grant_bits_source(io_mem_grant_bits_source), .io_miss_req_conflict_check_0_valid(io_miss_req_conflict_check_0_valid), .io_miss_req_conflict_check_0_bits(io_miss_req_conflict_check_0_bits), .io_miss_req_conflict_check_1_valid(io_miss_req_conflict_check_1_valid), .io_miss_req_conflict_check_1_bits(io_miss_req_conflict_check_1_bits), .io_miss_req_conflict_check_2_valid(io_miss_req_conflict_check_2_valid), .io_miss_req_conflict_check_2_bits(io_miss_req_conflict_check_2_bits), .io_miss_req_conflict_check_3_valid(io_miss_req_conflict_check_3_valid), .io_miss_req_conflict_check_3_bits(io_miss_req_conflict_check_3_bits), .io_miss_req_conflict_check_4_valid(io_miss_req_conflict_check_4_valid), .io_miss_req_conflict_check_4_bits(io_miss_req_conflict_check_4_bits), .io_req_ready(g_io_req_ready), .io_mem_release_valid(g_io_mem_release_valid), .io_mem_release_bits_opcode(g_io_mem_release_bits_opcode), .io_mem_release_bits_param(g_io_mem_release_bits_param), .io_mem_release_bits_size(g_io_mem_release_bits_size), .io_mem_release_bits_source(g_io_mem_release_bits_source), .io_mem_release_bits_address(g_io_mem_release_bits_address), .io_mem_release_bits_data(g_io_mem_release_bits_data), .io_mem_release_bits_corrupt(g_io_mem_release_bits_corrupt), .io_block_miss_req_0(g_io_block_miss_req_0), .io_block_miss_req_1(g_io_block_miss_req_1), .io_block_miss_req_2(g_io_block_miss_req_2), .io_block_miss_req_3(g_io_block_miss_req_3), .io_block_miss_req_4(g_io_block_miss_req_4), .io_perf_0_value(g_io_perf_0_value), .io_perf_1_value(g_io_perf_1_value), .io_perf_2_value(g_io_perf_2_value), .io_perf_3_value(g_io_perf_3_value), .io_perf_4_value(g_io_perf_4_value));
  WritebackQueue_xs u_i (.clock(clk), .reset(rst), .io_req_valid(io_req_valid), .io_req_bits_param(io_req_bits_param), .io_req_bits_voluntary(io_req_bits_voluntary), .io_req_bits_hasData(io_req_bits_hasData), .io_req_bits_corrupt(io_req_bits_corrupt), .io_req_bits_dirty(io_req_bits_dirty), .io_req_bits_addr(io_req_bits_addr), .io_req_bits_data(io_req_bits_data), .io_mem_release_ready(io_mem_release_ready), .io_mem_grant_valid(io_mem_grant_valid), .io_mem_grant_bits_source(io_mem_grant_bits_source), .io_miss_req_conflict_check_0_valid(io_miss_req_conflict_check_0_valid), .io_miss_req_conflict_check_0_bits(io_miss_req_conflict_check_0_bits), .io_miss_req_conflict_check_1_valid(io_miss_req_conflict_check_1_valid), .io_miss_req_conflict_check_1_bits(io_miss_req_conflict_check_1_bits), .io_miss_req_conflict_check_2_valid(io_miss_req_conflict_check_2_valid), .io_miss_req_conflict_check_2_bits(io_miss_req_conflict_check_2_bits), .io_miss_req_conflict_check_3_valid(io_miss_req_conflict_check_3_valid), .io_miss_req_conflict_check_3_bits(io_miss_req_conflict_check_3_bits), .io_miss_req_conflict_check_4_valid(io_miss_req_conflict_check_4_valid), .io_miss_req_conflict_check_4_bits(io_miss_req_conflict_check_4_bits), .io_req_ready(i_io_req_ready), .io_mem_release_valid(i_io_mem_release_valid), .io_mem_release_bits_opcode(i_io_mem_release_bits_opcode), .io_mem_release_bits_param(i_io_mem_release_bits_param), .io_mem_release_bits_size(i_io_mem_release_bits_size), .io_mem_release_bits_source(i_io_mem_release_bits_source), .io_mem_release_bits_address(i_io_mem_release_bits_address), .io_mem_release_bits_data(i_io_mem_release_bits_data), .io_mem_release_bits_corrupt(i_io_mem_release_bits_corrupt), .io_block_miss_req_0(i_io_block_miss_req_0), .io_block_miss_req_1(i_io_block_miss_req_1), .io_block_miss_req_2(i_io_block_miss_req_2), .io_block_miss_req_3(i_io_block_miss_req_3), .io_block_miss_req_4(i_io_block_miss_req_4), .io_perf_0_value(i_io_perf_0_value), .io_perf_1_value(i_io_perf_1_value), .io_perf_2_value(i_io_perf_2_value), .io_perf_3_value(i_io_perf_3_value), .io_perf_4_value(i_io_perf_4_value));
  always @(negedge clk) begin
    if (rst) begin
      io_req_valid <= 1'b0;
      io_miss_req_conflict_check_0_valid <= 1'b0;
      io_miss_req_conflict_check_1_valid <= 1'b0;
      io_miss_req_conflict_check_2_valid <= 1'b0;
      io_miss_req_conflict_check_3_valid <= 1'b0;
      io_miss_req_conflict_check_4_valid <= 1'b0;
    end else begin
      io_req_valid <= ($urandom_range(0,1));
      io_req_bits_param <= 3'($urandom);
      io_req_bits_voluntary <= ($urandom_range(0,1));
      io_req_bits_hasData <= ($urandom_range(0,1));
      io_req_bits_corrupt <= $urandom_range(0,1);
      io_req_bits_addr <= {39'($urandom_range(0,7)), 9'($urandom)};
      io_req_bits_data <= 512'({$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()});
      io_miss_req_conflict_check_0_valid <= ($urandom_range(0,3)==0);
      io_miss_req_conflict_check_0_bits <= {39'($urandom_range(0,7)), 9'($urandom)};
      io_miss_req_conflict_check_1_valid <= ($urandom_range(0,3)==0);
      io_miss_req_conflict_check_1_bits <= {39'($urandom_range(0,7)), 9'($urandom)};
      io_miss_req_conflict_check_2_valid <= ($urandom_range(0,3)==0);
      io_miss_req_conflict_check_2_bits <= {39'($urandom_range(0,7)), 9'($urandom)};
      io_miss_req_conflict_check_3_valid <= ($urandom_range(0,3)==0);
      io_miss_req_conflict_check_3_bits <= {39'($urandom_range(0,7)), 9'($urandom)};
      io_miss_req_conflict_check_4_valid <= ($urandom_range(0,3)==0);
      io_miss_req_conflict_check_4_bits <= {39'($urandom_range(0,7)), 9'($urandom)};
      io_req_bits_dirty <= io_req_bits_hasData && ($urandom_range(0,1));
    end
  end

  // 影子记录：每个 entry id(17..34) 是否可能在等 ReleaseAck（按 golden mem_release 观察）
  // 简化：只要 golden 这拍发出 voluntary+release_done 的可能，就把该 source 标记；为稳健，
  // 直接随机回 grant 给「曾经发过 release 的 source」。这里采用：跟踪 golden 侧最近发出的
  // release source 集合（任意 voluntary release 都可能在等 ack），随机择一回 grant。
  bit [34:0] grant_pending;   // index = entry id (0..34)，只用 17..34
  int unsigned gp_start = 0;
  always @(negedge clk) begin
    if (rst) begin
      io_mem_release_ready  <= 1'b1;
      io_mem_grant_valid    <= 1'b0;
      io_mem_grant_bits_source <= 6'h0;
      grant_pending         <= 35'h0;
    end else begin
      io_mem_release_ready <= ($urandom_range(0,3)!=0);
      // golden 发出 voluntary release（opcode[1]=1 表 Release/ReleaseData）且 fire →
      // 该 source 进入 pending（等 ReleaseAck）。
      if (g_io_mem_release_valid && io_mem_release_ready &&
          g_io_mem_release_bits_opcode[1])
        grant_pending[g_io_mem_release_bits_source] <= 1'b1;
      io_mem_grant_valid <= 1'b0;
      if (|grant_pending && ($urandom_range(0,1))) begin
        int unsigned k; bit done;
        done = 1'b0;
        for (k = 17; k <= 34; k++) begin
          if (!done && grant_pending[(17+((gp_start+k-17)%18))]) begin
            done = 1'b1;
            io_mem_grant_valid       <= 1'b1;
            io_mem_grant_bits_source <= 6'(17+((gp_start+k-17)%18));
            grant_pending[(17+((gp_start+k-17)%18))] <= 1'b0;
          end
        end
        gp_start <= gp_start + 1;
      end
    end
  end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (!$isunknown(g_io_req_ready) && g_io_req_ready !== i_io_req_ready) begin errors++;
      if(errors<=80) $display("[%0t] io_req_ready g=%h i=%h", $time, g_io_req_ready, i_io_req_ready); end
    if (!$isunknown(g_io_mem_release_valid) && g_io_mem_release_valid !== i_io_mem_release_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_mem_release_valid g=%h i=%h", $time, g_io_mem_release_valid, i_io_mem_release_valid); end
    if ((g_io_mem_release_valid) && !$isunknown(g_io_mem_release_bits_opcode) && g_io_mem_release_bits_opcode !== i_io_mem_release_bits_opcode) begin errors++;
      if(errors<=80) $display("[%0t] io_mem_release_bits_opcode g=%h i=%h", $time, g_io_mem_release_bits_opcode, i_io_mem_release_bits_opcode); end
    if ((g_io_mem_release_valid) && !$isunknown(g_io_mem_release_bits_param) && g_io_mem_release_bits_param !== i_io_mem_release_bits_param) begin errors++;
      if(errors<=80) $display("[%0t] io_mem_release_bits_param g=%h i=%h", $time, g_io_mem_release_bits_param, i_io_mem_release_bits_param); end
    if ((g_io_mem_release_valid) && !$isunknown(g_io_mem_release_bits_size) && g_io_mem_release_bits_size !== i_io_mem_release_bits_size) begin errors++;
      if(errors<=80) $display("[%0t] io_mem_release_bits_size g=%h i=%h", $time, g_io_mem_release_bits_size, i_io_mem_release_bits_size); end
    if ((g_io_mem_release_valid) && !$isunknown(g_io_mem_release_bits_source) && g_io_mem_release_bits_source !== i_io_mem_release_bits_source) begin errors++;
      if(errors<=80) $display("[%0t] io_mem_release_bits_source g=%h i=%h", $time, g_io_mem_release_bits_source, i_io_mem_release_bits_source); end
    if ((g_io_mem_release_valid) && !$isunknown(g_io_mem_release_bits_address) && g_io_mem_release_bits_address !== i_io_mem_release_bits_address) begin errors++;
      if(errors<=80) $display("[%0t] io_mem_release_bits_address g=%h i=%h", $time, g_io_mem_release_bits_address, i_io_mem_release_bits_address); end
    if ((g_io_mem_release_valid) && !$isunknown(g_io_mem_release_bits_data) && g_io_mem_release_bits_data !== i_io_mem_release_bits_data) begin errors++;
      if(errors<=80) $display("[%0t] io_mem_release_bits_data g=%h i=%h", $time, g_io_mem_release_bits_data, i_io_mem_release_bits_data); end
    if ((g_io_mem_release_valid) && !$isunknown(g_io_mem_release_bits_corrupt) && g_io_mem_release_bits_corrupt !== i_io_mem_release_bits_corrupt) begin errors++;
      if(errors<=80) $display("[%0t] io_mem_release_bits_corrupt g=%h i=%h", $time, g_io_mem_release_bits_corrupt, i_io_mem_release_bits_corrupt); end
    if (!$isunknown(g_io_block_miss_req_0) && g_io_block_miss_req_0 !== i_io_block_miss_req_0) begin errors++;
      if(errors<=80) $display("[%0t] io_block_miss_req_0 g=%h i=%h", $time, g_io_block_miss_req_0, i_io_block_miss_req_0); end
    if (!$isunknown(g_io_block_miss_req_1) && g_io_block_miss_req_1 !== i_io_block_miss_req_1) begin errors++;
      if(errors<=80) $display("[%0t] io_block_miss_req_1 g=%h i=%h", $time, g_io_block_miss_req_1, i_io_block_miss_req_1); end
    if (!$isunknown(g_io_block_miss_req_2) && g_io_block_miss_req_2 !== i_io_block_miss_req_2) begin errors++;
      if(errors<=80) $display("[%0t] io_block_miss_req_2 g=%h i=%h", $time, g_io_block_miss_req_2, i_io_block_miss_req_2); end
    if (!$isunknown(g_io_block_miss_req_3) && g_io_block_miss_req_3 !== i_io_block_miss_req_3) begin errors++;
      if(errors<=80) $display("[%0t] io_block_miss_req_3 g=%h i=%h", $time, g_io_block_miss_req_3, i_io_block_miss_req_3); end
    if (!$isunknown(g_io_block_miss_req_4) && g_io_block_miss_req_4 !== i_io_block_miss_req_4) begin errors++;
      if(errors<=80) $display("[%0t] io_block_miss_req_4 g=%h i=%h", $time, g_io_block_miss_req_4, i_io_block_miss_req_4); end
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
