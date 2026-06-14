// 自动生成：scripts/gen_icachemissunit.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 80000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic io_fencei;
  logic io_flush;
  logic io_wfi_wfiReq;
  logic io_fetch_req_valid;
  logic [41:0] io_fetch_req_bits_blkPaddr;
  logic [7:0] io_fetch_req_bits_vSetIdx;
  logic io_prefetch_req_valid;
  logic [41:0] io_prefetch_req_bits_blkPaddr;
  logic [7:0] io_prefetch_req_bits_vSetIdx;
  logic [1:0] io_victim_way;
  logic io_mem_acquire_ready;
  logic io_mem_grant_valid;
  logic [3:0] io_mem_grant_bits_opcode;
  logic [2:0] io_mem_grant_bits_size;
  logic [3:0] io_mem_grant_bits_source;
  logic [255:0] io_mem_grant_bits_data;
  logic io_mem_grant_bits_corrupt;
  wire g_io_wfi_wfiSafe;
  wire i_io_wfi_wfiSafe;
  wire g_io_fetch_req_ready;
  wire i_io_fetch_req_ready;
  wire g_io_fetch_resp_valid;
  wire i_io_fetch_resp_valid;
  wire [41:0] g_io_fetch_resp_bits_blkPaddr;
  wire [41:0] i_io_fetch_resp_bits_blkPaddr;
  wire [7:0] g_io_fetch_resp_bits_vSetIdx;
  wire [7:0] i_io_fetch_resp_bits_vSetIdx;
  wire [3:0] g_io_fetch_resp_bits_waymask;
  wire [3:0] i_io_fetch_resp_bits_waymask;
  wire [511:0] g_io_fetch_resp_bits_data;
  wire [511:0] i_io_fetch_resp_bits_data;
  wire g_io_fetch_resp_bits_corrupt;
  wire i_io_fetch_resp_bits_corrupt;
  wire g_io_prefetch_req_ready;
  wire i_io_prefetch_req_ready;
  wire g_io_meta_write_valid;
  wire i_io_meta_write_valid;
  wire [7:0] g_io_meta_write_bits_virIdx;
  wire [7:0] i_io_meta_write_bits_virIdx;
  wire [35:0] g_io_meta_write_bits_phyTag;
  wire [35:0] i_io_meta_write_bits_phyTag;
  wire [3:0] g_io_meta_write_bits_waymask;
  wire [3:0] i_io_meta_write_bits_waymask;
  wire g_io_meta_write_bits_bankIdx;
  wire i_io_meta_write_bits_bankIdx;
  wire g_io_data_write_valid;
  wire i_io_data_write_valid;
  wire [7:0] g_io_data_write_bits_virIdx;
  wire [7:0] i_io_data_write_bits_virIdx;
  wire [511:0] g_io_data_write_bits_data;
  wire [511:0] i_io_data_write_bits_data;
  wire [3:0] g_io_data_write_bits_waymask;
  wire [3:0] i_io_data_write_bits_waymask;
  wire g_io_victim_vSetIdx_valid;
  wire i_io_victim_vSetIdx_valid;
  wire [7:0] g_io_victim_vSetIdx_bits;
  wire [7:0] i_io_victim_vSetIdx_bits;
  wire g_io_mem_acquire_valid;
  wire i_io_mem_acquire_valid;
  wire [3:0] g_io_mem_acquire_bits_source;
  wire [3:0] i_io_mem_acquire_bits_source;
  wire [47:0] g_io_mem_acquire_bits_address;
  wire [47:0] i_io_mem_acquire_bits_address;
  ICacheMissUnit    u_g (.clock(clk), .reset(rst), .io_fencei(io_fencei), .io_flush(io_flush), .io_wfi_wfiReq(io_wfi_wfiReq), .io_fetch_req_valid(io_fetch_req_valid), .io_fetch_req_bits_blkPaddr(io_fetch_req_bits_blkPaddr), .io_fetch_req_bits_vSetIdx(io_fetch_req_bits_vSetIdx), .io_prefetch_req_valid(io_prefetch_req_valid), .io_prefetch_req_bits_blkPaddr(io_prefetch_req_bits_blkPaddr), .io_prefetch_req_bits_vSetIdx(io_prefetch_req_bits_vSetIdx), .io_victim_way(io_victim_way), .io_mem_acquire_ready(io_mem_acquire_ready), .io_mem_grant_valid(io_mem_grant_valid), .io_mem_grant_bits_opcode(io_mem_grant_bits_opcode), .io_mem_grant_bits_size(io_mem_grant_bits_size), .io_mem_grant_bits_source(io_mem_grant_bits_source), .io_mem_grant_bits_data(io_mem_grant_bits_data), .io_mem_grant_bits_corrupt(io_mem_grant_bits_corrupt), .io_wfi_wfiSafe(g_io_wfi_wfiSafe), .io_fetch_req_ready(g_io_fetch_req_ready), .io_fetch_resp_valid(g_io_fetch_resp_valid), .io_fetch_resp_bits_blkPaddr(g_io_fetch_resp_bits_blkPaddr), .io_fetch_resp_bits_vSetIdx(g_io_fetch_resp_bits_vSetIdx), .io_fetch_resp_bits_waymask(g_io_fetch_resp_bits_waymask), .io_fetch_resp_bits_data(g_io_fetch_resp_bits_data), .io_fetch_resp_bits_corrupt(g_io_fetch_resp_bits_corrupt), .io_prefetch_req_ready(g_io_prefetch_req_ready), .io_meta_write_valid(g_io_meta_write_valid), .io_meta_write_bits_virIdx(g_io_meta_write_bits_virIdx), .io_meta_write_bits_phyTag(g_io_meta_write_bits_phyTag), .io_meta_write_bits_waymask(g_io_meta_write_bits_waymask), .io_meta_write_bits_bankIdx(g_io_meta_write_bits_bankIdx), .io_data_write_valid(g_io_data_write_valid), .io_data_write_bits_virIdx(g_io_data_write_bits_virIdx), .io_data_write_bits_data(g_io_data_write_bits_data), .io_data_write_bits_waymask(g_io_data_write_bits_waymask), .io_victim_vSetIdx_valid(g_io_victim_vSetIdx_valid), .io_victim_vSetIdx_bits(g_io_victim_vSetIdx_bits), .io_mem_acquire_valid(g_io_mem_acquire_valid), .io_mem_acquire_bits_source(g_io_mem_acquire_bits_source), .io_mem_acquire_bits_address(g_io_mem_acquire_bits_address));
  ICacheMissUnit_xs u_i (.clock(clk), .reset(rst), .io_fencei(io_fencei), .io_flush(io_flush), .io_wfi_wfiReq(io_wfi_wfiReq), .io_fetch_req_valid(io_fetch_req_valid), .io_fetch_req_bits_blkPaddr(io_fetch_req_bits_blkPaddr), .io_fetch_req_bits_vSetIdx(io_fetch_req_bits_vSetIdx), .io_prefetch_req_valid(io_prefetch_req_valid), .io_prefetch_req_bits_blkPaddr(io_prefetch_req_bits_blkPaddr), .io_prefetch_req_bits_vSetIdx(io_prefetch_req_bits_vSetIdx), .io_victim_way(io_victim_way), .io_mem_acquire_ready(io_mem_acquire_ready), .io_mem_grant_valid(io_mem_grant_valid), .io_mem_grant_bits_opcode(io_mem_grant_bits_opcode), .io_mem_grant_bits_size(io_mem_grant_bits_size), .io_mem_grant_bits_source(io_mem_grant_bits_source), .io_mem_grant_bits_data(io_mem_grant_bits_data), .io_mem_grant_bits_corrupt(io_mem_grant_bits_corrupt), .io_wfi_wfiSafe(i_io_wfi_wfiSafe), .io_fetch_req_ready(i_io_fetch_req_ready), .io_fetch_resp_valid(i_io_fetch_resp_valid), .io_fetch_resp_bits_blkPaddr(i_io_fetch_resp_bits_blkPaddr), .io_fetch_resp_bits_vSetIdx(i_io_fetch_resp_bits_vSetIdx), .io_fetch_resp_bits_waymask(i_io_fetch_resp_bits_waymask), .io_fetch_resp_bits_data(i_io_fetch_resp_bits_data), .io_fetch_resp_bits_corrupt(i_io_fetch_resp_bits_corrupt), .io_prefetch_req_ready(i_io_prefetch_req_ready), .io_meta_write_valid(i_io_meta_write_valid), .io_meta_write_bits_virIdx(i_io_meta_write_bits_virIdx), .io_meta_write_bits_phyTag(i_io_meta_write_bits_phyTag), .io_meta_write_bits_waymask(i_io_meta_write_bits_waymask), .io_meta_write_bits_bankIdx(i_io_meta_write_bits_bankIdx), .io_data_write_valid(i_io_data_write_valid), .io_data_write_bits_virIdx(i_io_data_write_bits_virIdx), .io_data_write_bits_data(i_io_data_write_bits_data), .io_data_write_bits_waymask(i_io_data_write_bits_waymask), .io_victim_vSetIdx_valid(i_io_victim_vSetIdx_valid), .io_victim_vSetIdx_bits(i_io_victim_vSetIdx_bits), .io_mem_acquire_valid(i_io_mem_acquire_valid), .io_mem_acquire_bits_source(i_io_mem_acquire_bits_source), .io_mem_acquire_bits_address(i_io_mem_acquire_bits_address));

  // grant 节拍模型：保证带数据响应成对出现（beat0 then beat1），避免误触断言
  bit grant_beat;       // 0=下一拍发 beat0, 1=下一拍发 beat1
  logic [3:0] cur_src;  // 当前 cacheline 的 source
  always @(negedge clk) begin
    if (rst) begin
      io_fencei <= 1'b0; io_flush <= 1'b0; io_wfi_wfiReq <= 1'b0;
      io_fetch_req_valid <= 1'b0; io_prefetch_req_valid <= 1'b0;
      io_mem_acquire_ready <= 1'b0; io_victim_way <= 2'b0;
      io_mem_grant_valid <= 1'b0; io_mem_grant_bits_opcode <= 4'h0;
      io_mem_grant_bits_size <= 3'h0; io_mem_grant_bits_source <= 4'h0;
      io_mem_grant_bits_data <= 256'h0; io_mem_grant_bits_corrupt <= 1'b0;
      io_fetch_req_bits_blkPaddr <= 42'h0; io_fetch_req_bits_vSetIdx <= 8'h0;
      io_prefetch_req_bits_blkPaddr <= 42'h0; io_prefetch_req_bits_vSetIdx <= 8'h0;
      grant_beat <= 1'b0; cur_src <= 4'h0;
    end else begin
      // 偶发控制
      io_fencei <= ($urandom_range(0,127)==0);
      io_flush  <= ($urandom_range(0,63)==0);
      io_wfi_wfiReq <= ($urandom_range(0,15)==0);
      io_mem_acquire_ready <= ($urandom_range(0,3)!=0);
      io_victim_way <= 2'($urandom);

      // fetch/prefetch 请求：地址压缩到小值域以增加 MSHR 命中/复用
      io_fetch_req_valid <= ($urandom_range(0,2)!=0);
      io_fetch_req_bits_blkPaddr <= 42'($urandom_range(0,31));
      io_fetch_req_bits_vSetIdx  <= 8'($urandom_range(0,7));
      io_prefetch_req_valid <= ($urandom_range(0,2)!=0);
      io_prefetch_req_bits_blkPaddr <= 42'($urandom_range(0,31));
      io_prefetch_req_bits_vSetIdx  <= 8'($urandom_range(0,7));

      // grant 数据通路：成对 beat
      if (grant_beat == 1'b0) begin
        // 决定是否本拍开始一条新 cacheline
        if ($urandom_range(0,1)==0) begin
          io_mem_grant_valid <= 1'b1;
          io_mem_grant_bits_opcode <= 4'h1;     // 带数据
          io_mem_grant_bits_size <= 3'h6;       // 64B -> 多 beat（refillCycles=2）
          cur_src <= 4'($urandom_range(0,13));
          io_mem_grant_bits_source <= 4'($urandom_range(0,13));
          io_mem_grant_bits_data <= {$urandom,$urandom,$urandom,$urandom,
                                     $urandom,$urandom,$urandom,$urandom};
          io_mem_grant_bits_corrupt <= ($urandom_range(0,7)==0);
          grant_beat <= 1'b1;
        end else begin
          io_mem_grant_valid <= 1'b0;
        end
      end else begin
        // beat1：必发，source 与 beat0 一致
        io_mem_grant_valid <= 1'b1;
        io_mem_grant_bits_opcode <= 4'h1;
        io_mem_grant_bits_size <= 3'h6;
        io_mem_grant_bits_source <= cur_src;
        io_mem_grant_bits_data <= {$urandom,$urandom,$urandom,$urandom,
                                   $urandom,$urandom,$urandom,$urandom};
        io_mem_grant_bits_corrupt <= ($urandom_range(0,7)==0);
        grant_beat <= 1'b0;
      end
    end
  end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (g_io_wfi_wfiSafe !== i_io_wfi_wfiSafe) begin errors++;
      if(errors<=30) $display("[%0t] io_wfi_wfiSafe g=%h i=%h", $time, g_io_wfi_wfiSafe, i_io_wfi_wfiSafe); end
    if (g_io_fetch_req_ready !== i_io_fetch_req_ready) begin errors++;
      if(errors<=30) $display("[%0t] io_fetch_req_ready g=%h i=%h", $time, g_io_fetch_req_ready, i_io_fetch_req_ready); end
    if (g_io_fetch_resp_valid !== i_io_fetch_resp_valid) begin errors++;
      if(errors<=30) $display("[%0t] io_fetch_resp_valid g=%h i=%h", $time, g_io_fetch_resp_valid, i_io_fetch_resp_valid); end
    if (g_io_fetch_resp_bits_blkPaddr !== i_io_fetch_resp_bits_blkPaddr) begin errors++;
      if(errors<=30) $display("[%0t] io_fetch_resp_bits_blkPaddr g=%h i=%h", $time, g_io_fetch_resp_bits_blkPaddr, i_io_fetch_resp_bits_blkPaddr); end
    if (g_io_fetch_resp_bits_vSetIdx !== i_io_fetch_resp_bits_vSetIdx) begin errors++;
      if(errors<=30) $display("[%0t] io_fetch_resp_bits_vSetIdx g=%h i=%h", $time, g_io_fetch_resp_bits_vSetIdx, i_io_fetch_resp_bits_vSetIdx); end
    if (g_io_fetch_resp_bits_waymask !== i_io_fetch_resp_bits_waymask) begin errors++;
      if(errors<=30) $display("[%0t] io_fetch_resp_bits_waymask g=%h i=%h", $time, g_io_fetch_resp_bits_waymask, i_io_fetch_resp_bits_waymask); end
    if (g_io_fetch_resp_bits_data !== i_io_fetch_resp_bits_data) begin errors++;
      if(errors<=30) $display("[%0t] io_fetch_resp_bits_data g=%h i=%h", $time, g_io_fetch_resp_bits_data, i_io_fetch_resp_bits_data); end
    if (g_io_fetch_resp_bits_corrupt !== i_io_fetch_resp_bits_corrupt) begin errors++;
      if(errors<=30) $display("[%0t] io_fetch_resp_bits_corrupt g=%h i=%h", $time, g_io_fetch_resp_bits_corrupt, i_io_fetch_resp_bits_corrupt); end
    if (g_io_prefetch_req_ready !== i_io_prefetch_req_ready) begin errors++;
      if(errors<=30) $display("[%0t] io_prefetch_req_ready g=%h i=%h", $time, g_io_prefetch_req_ready, i_io_prefetch_req_ready); end
    if (g_io_meta_write_valid !== i_io_meta_write_valid) begin errors++;
      if(errors<=30) $display("[%0t] io_meta_write_valid g=%h i=%h", $time, g_io_meta_write_valid, i_io_meta_write_valid); end
    if (g_io_meta_write_bits_virIdx !== i_io_meta_write_bits_virIdx) begin errors++;
      if(errors<=30) $display("[%0t] io_meta_write_bits_virIdx g=%h i=%h", $time, g_io_meta_write_bits_virIdx, i_io_meta_write_bits_virIdx); end
    if (g_io_meta_write_bits_phyTag !== i_io_meta_write_bits_phyTag) begin errors++;
      if(errors<=30) $display("[%0t] io_meta_write_bits_phyTag g=%h i=%h", $time, g_io_meta_write_bits_phyTag, i_io_meta_write_bits_phyTag); end
    if (g_io_meta_write_bits_waymask !== i_io_meta_write_bits_waymask) begin errors++;
      if(errors<=30) $display("[%0t] io_meta_write_bits_waymask g=%h i=%h", $time, g_io_meta_write_bits_waymask, i_io_meta_write_bits_waymask); end
    if (g_io_meta_write_bits_bankIdx !== i_io_meta_write_bits_bankIdx) begin errors++;
      if(errors<=30) $display("[%0t] io_meta_write_bits_bankIdx g=%h i=%h", $time, g_io_meta_write_bits_bankIdx, i_io_meta_write_bits_bankIdx); end
    if (g_io_data_write_valid !== i_io_data_write_valid) begin errors++;
      if(errors<=30) $display("[%0t] io_data_write_valid g=%h i=%h", $time, g_io_data_write_valid, i_io_data_write_valid); end
    if (g_io_data_write_bits_virIdx !== i_io_data_write_bits_virIdx) begin errors++;
      if(errors<=30) $display("[%0t] io_data_write_bits_virIdx g=%h i=%h", $time, g_io_data_write_bits_virIdx, i_io_data_write_bits_virIdx); end
    if (g_io_data_write_bits_data !== i_io_data_write_bits_data) begin errors++;
      if(errors<=30) $display("[%0t] io_data_write_bits_data g=%h i=%h", $time, g_io_data_write_bits_data, i_io_data_write_bits_data); end
    if (g_io_data_write_bits_waymask !== i_io_data_write_bits_waymask) begin errors++;
      if(errors<=30) $display("[%0t] io_data_write_bits_waymask g=%h i=%h", $time, g_io_data_write_bits_waymask, i_io_data_write_bits_waymask); end
    if (g_io_victim_vSetIdx_valid !== i_io_victim_vSetIdx_valid) begin errors++;
      if(errors<=30) $display("[%0t] io_victim_vSetIdx_valid g=%h i=%h", $time, g_io_victim_vSetIdx_valid, i_io_victim_vSetIdx_valid); end
    if (g_io_victim_vSetIdx_bits !== i_io_victim_vSetIdx_bits) begin errors++;
      if(errors<=30) $display("[%0t] io_victim_vSetIdx_bits g=%h i=%h", $time, g_io_victim_vSetIdx_bits, i_io_victim_vSetIdx_bits); end
    if (g_io_mem_acquire_valid !== i_io_mem_acquire_valid) begin errors++;
      if(errors<=30) $display("[%0t] io_mem_acquire_valid g=%h i=%h", $time, g_io_mem_acquire_valid, i_io_mem_acquire_valid); end
    if (g_io_mem_acquire_bits_source !== i_io_mem_acquire_bits_source) begin errors++;
      if(errors<=30) $display("[%0t] io_mem_acquire_bits_source g=%h i=%h", $time, g_io_mem_acquire_bits_source, i_io_mem_acquire_bits_source); end
    if (g_io_mem_acquire_bits_address !== i_io_mem_acquire_bits_address) begin errors++;
      if(errors<=30) $display("[%0t] io_mem_acquire_bits_address g=%h i=%h", $time, g_io_mem_acquire_bits_address, i_io_mem_acquire_bits_address); end
  end
  initial begin
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
