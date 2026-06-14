// 自动生成：scripts/gen_icachectrlunit.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic auto_in_a_valid;
  logic [3:0] auto_in_a_bits_opcode;
  logic [1:0] auto_in_a_bits_size;
  logic [2:0] auto_in_a_bits_source;
  logic [29:0] auto_in_a_bits_address;
  logic [7:0] auto_in_a_bits_mask;
  logic [63:0] auto_in_a_bits_data;
  logic auto_in_d_ready;
  logic io_metaRead_ready;
  logic [35:0] io_metaReadResp_metas_0_0_tag;
  logic [35:0] io_metaReadResp_metas_0_1_tag;
  logic [35:0] io_metaReadResp_metas_0_2_tag;
  logic [35:0] io_metaReadResp_metas_0_3_tag;
  logic io_metaReadResp_entryValid_0_0;
  logic io_metaReadResp_entryValid_0_1;
  logic io_metaReadResp_entryValid_0_2;
  logic io_metaReadResp_entryValid_0_3;
  logic io_metaWrite_ready;
  logic io_dataWrite_ready;
  wire g_auto_in_a_ready;
  wire i_auto_in_a_ready;
  wire g_auto_in_d_valid;
  wire i_auto_in_d_valid;
  wire [3:0] g_auto_in_d_bits_opcode;
  wire [3:0] i_auto_in_d_bits_opcode;
  wire [1:0] g_auto_in_d_bits_size;
  wire [1:0] i_auto_in_d_bits_size;
  wire [2:0] g_auto_in_d_bits_source;
  wire [2:0] i_auto_in_d_bits_source;
  wire [63:0] g_auto_in_d_bits_data;
  wire [63:0] i_auto_in_d_bits_data;
  wire g_io_ecc_enable;
  wire i_io_ecc_enable;
  wire g_io_injecting;
  wire i_io_injecting;
  wire g_io_metaRead_valid;
  wire i_io_metaRead_valid;
  wire [7:0] g_io_metaRead_bits_vSetIdx_0;
  wire [7:0] i_io_metaRead_bits_vSetIdx_0;
  wire [7:0] g_io_metaRead_bits_vSetIdx_1;
  wire [7:0] i_io_metaRead_bits_vSetIdx_1;
  wire g_io_metaWrite_valid;
  wire i_io_metaWrite_valid;
  wire [7:0] g_io_metaWrite_bits_virIdx;
  wire [7:0] i_io_metaWrite_bits_virIdx;
  wire [35:0] g_io_metaWrite_bits_phyTag;
  wire [35:0] i_io_metaWrite_bits_phyTag;
  wire [3:0] g_io_metaWrite_bits_waymask;
  wire [3:0] i_io_metaWrite_bits_waymask;
  wire g_io_metaWrite_bits_bankIdx;
  wire i_io_metaWrite_bits_bankIdx;
  wire g_io_dataWrite_valid;
  wire i_io_dataWrite_valid;
  wire [7:0] g_io_dataWrite_bits_virIdx;
  wire [7:0] i_io_dataWrite_bits_virIdx;
  wire [3:0] g_io_dataWrite_bits_waymask;
  wire [3:0] i_io_dataWrite_bits_waymask;
  ICacheCtrlUnit    u_g (.clock(clk), .reset(rst), .auto_in_a_valid(auto_in_a_valid), .auto_in_a_bits_opcode(auto_in_a_bits_opcode), .auto_in_a_bits_size(auto_in_a_bits_size), .auto_in_a_bits_source(auto_in_a_bits_source), .auto_in_a_bits_address(auto_in_a_bits_address), .auto_in_a_bits_mask(auto_in_a_bits_mask), .auto_in_a_bits_data(auto_in_a_bits_data), .auto_in_d_ready(auto_in_d_ready), .io_metaRead_ready(io_metaRead_ready), .io_metaReadResp_metas_0_0_tag(io_metaReadResp_metas_0_0_tag), .io_metaReadResp_metas_0_1_tag(io_metaReadResp_metas_0_1_tag), .io_metaReadResp_metas_0_2_tag(io_metaReadResp_metas_0_2_tag), .io_metaReadResp_metas_0_3_tag(io_metaReadResp_metas_0_3_tag), .io_metaReadResp_entryValid_0_0(io_metaReadResp_entryValid_0_0), .io_metaReadResp_entryValid_0_1(io_metaReadResp_entryValid_0_1), .io_metaReadResp_entryValid_0_2(io_metaReadResp_entryValid_0_2), .io_metaReadResp_entryValid_0_3(io_metaReadResp_entryValid_0_3), .io_metaWrite_ready(io_metaWrite_ready), .io_dataWrite_ready(io_dataWrite_ready), .auto_in_a_ready(g_auto_in_a_ready), .auto_in_d_valid(g_auto_in_d_valid), .auto_in_d_bits_opcode(g_auto_in_d_bits_opcode), .auto_in_d_bits_size(g_auto_in_d_bits_size), .auto_in_d_bits_source(g_auto_in_d_bits_source), .auto_in_d_bits_data(g_auto_in_d_bits_data), .io_ecc_enable(g_io_ecc_enable), .io_injecting(g_io_injecting), .io_metaRead_valid(g_io_metaRead_valid), .io_metaRead_bits_vSetIdx_0(g_io_metaRead_bits_vSetIdx_0), .io_metaRead_bits_vSetIdx_1(g_io_metaRead_bits_vSetIdx_1), .io_metaWrite_valid(g_io_metaWrite_valid), .io_metaWrite_bits_virIdx(g_io_metaWrite_bits_virIdx), .io_metaWrite_bits_phyTag(g_io_metaWrite_bits_phyTag), .io_metaWrite_bits_waymask(g_io_metaWrite_bits_waymask), .io_metaWrite_bits_bankIdx(g_io_metaWrite_bits_bankIdx), .io_dataWrite_valid(g_io_dataWrite_valid), .io_dataWrite_bits_virIdx(g_io_dataWrite_bits_virIdx), .io_dataWrite_bits_waymask(g_io_dataWrite_bits_waymask));
  ICacheCtrlUnit_xs u_i (.clock(clk), .reset(rst), .auto_in_a_valid(auto_in_a_valid), .auto_in_a_bits_opcode(auto_in_a_bits_opcode), .auto_in_a_bits_size(auto_in_a_bits_size), .auto_in_a_bits_source(auto_in_a_bits_source), .auto_in_a_bits_address(auto_in_a_bits_address), .auto_in_a_bits_mask(auto_in_a_bits_mask), .auto_in_a_bits_data(auto_in_a_bits_data), .auto_in_d_ready(auto_in_d_ready), .io_metaRead_ready(io_metaRead_ready), .io_metaReadResp_metas_0_0_tag(io_metaReadResp_metas_0_0_tag), .io_metaReadResp_metas_0_1_tag(io_metaReadResp_metas_0_1_tag), .io_metaReadResp_metas_0_2_tag(io_metaReadResp_metas_0_2_tag), .io_metaReadResp_metas_0_3_tag(io_metaReadResp_metas_0_3_tag), .io_metaReadResp_entryValid_0_0(io_metaReadResp_entryValid_0_0), .io_metaReadResp_entryValid_0_1(io_metaReadResp_entryValid_0_1), .io_metaReadResp_entryValid_0_2(io_metaReadResp_entryValid_0_2), .io_metaReadResp_entryValid_0_3(io_metaReadResp_entryValid_0_3), .io_metaWrite_ready(io_metaWrite_ready), .io_dataWrite_ready(io_dataWrite_ready), .auto_in_a_ready(i_auto_in_a_ready), .auto_in_d_valid(i_auto_in_d_valid), .auto_in_d_bits_opcode(i_auto_in_d_bits_opcode), .auto_in_d_bits_size(i_auto_in_d_bits_size), .auto_in_d_bits_source(i_auto_in_d_bits_source), .auto_in_d_bits_data(i_auto_in_d_bits_data), .io_ecc_enable(i_io_ecc_enable), .io_injecting(i_io_injecting), .io_metaRead_valid(i_io_metaRead_valid), .io_metaRead_bits_vSetIdx_0(i_io_metaRead_bits_vSetIdx_0), .io_metaRead_bits_vSetIdx_1(i_io_metaRead_bits_vSetIdx_1), .io_metaWrite_valid(i_io_metaWrite_valid), .io_metaWrite_bits_virIdx(i_io_metaWrite_bits_virIdx), .io_metaWrite_bits_phyTag(i_io_metaWrite_bits_phyTag), .io_metaWrite_bits_waymask(i_io_metaWrite_bits_waymask), .io_metaWrite_bits_bankIdx(i_io_metaWrite_bits_bankIdx), .io_dataWrite_valid(i_io_dataWrite_valid), .io_dataWrite_bits_virIdx(i_io_dataWrite_bits_virIdx), .io_dataWrite_bits_waymask(i_io_dataWrite_bits_waymask));
  always @(negedge clk) begin
    if (rst) begin
      auto_in_a_valid <= 1'b0;
      auto_in_d_ready <= 1'b0;
      io_metaRead_ready <= 1'b0;
      io_metaWrite_ready <= 1'b0;
      io_dataWrite_ready <= 1'b0;
    end else begin
      auto_in_a_valid        <= ($urandom_range(0,2)!=0);
      // opcode: 0=PutFullData(写), 4=Get(读)；偏向这两者
      auto_in_a_bits_opcode  <= ($urandom_range(0,1)==0) ? 4'h0 : 4'h4;
      auto_in_a_bits_size    <= 2'($urandom);
      auto_in_a_bits_source  <= 3'($urandom);
      // address[6:3] -> index：偏向 0/1，偶发越界到 2..15
      auto_in_a_bits_address <= ($urandom_range(0,7)==0)
                                  ? 30'($urandom)
                                  : {23'($urandom), 1'($urandom_range(0,1)), 3'($urandom)};
      // mask 偏向全 1（合法寄存器写要求 &mask）
      auto_in_a_bits_mask    <= ($urandom_range(0,3)!=0) ? 8'hff : 8'($urandom);
      // data：偏置低 4 位（enable/inject/itarget），高位随机
      auto_in_a_bits_data    <= {32'($urandom), 28'($urandom), 4'($urandom_range(0,15))};
      auto_in_d_ready        <= ($urandom_range(0,2)!=0);
      io_metaRead_ready      <= ($urandom_range(0,1)==0);
      io_metaWrite_ready     <= ($urandom_range(0,1)==0);
      io_dataWrite_ready     <= ($urandom_range(0,1)==0);
      // metaReadResp：ptag 压缩值域以提高 way 命中率
      io_metaReadResp_metas_0_0_tag <= 36'($urandom_range(0,7));
      io_metaReadResp_metas_0_1_tag <= 36'($urandom_range(0,7));
      io_metaReadResp_metas_0_2_tag <= 36'($urandom_range(0,7));
      io_metaReadResp_metas_0_3_tag <= 36'($urandom_range(0,7));
      io_metaReadResp_entryValid_0_0 <= 1'($urandom);
      io_metaReadResp_entryValid_0_1 <= 1'($urandom);
      io_metaReadResp_entryValid_0_2 <= 1'($urandom);
      io_metaReadResp_entryValid_0_3 <= 1'($urandom);
    end
  end
  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (g_auto_in_a_ready !== i_auto_in_a_ready) begin errors++;
      if(errors<=30) $display("[%0t] auto_in_a_ready g=%h i=%h", $time, g_auto_in_a_ready, i_auto_in_a_ready); end
    if (g_auto_in_d_valid !== i_auto_in_d_valid) begin errors++;
      if(errors<=30) $display("[%0t] auto_in_d_valid g=%h i=%h", $time, g_auto_in_d_valid, i_auto_in_d_valid); end
    if (g_auto_in_d_bits_opcode !== i_auto_in_d_bits_opcode) begin errors++;
      if(errors<=30) $display("[%0t] auto_in_d_bits_opcode g=%h i=%h", $time, g_auto_in_d_bits_opcode, i_auto_in_d_bits_opcode); end
    if (g_auto_in_d_bits_size !== i_auto_in_d_bits_size) begin errors++;
      if(errors<=30) $display("[%0t] auto_in_d_bits_size g=%h i=%h", $time, g_auto_in_d_bits_size, i_auto_in_d_bits_size); end
    if (g_auto_in_d_bits_source !== i_auto_in_d_bits_source) begin errors++;
      if(errors<=30) $display("[%0t] auto_in_d_bits_source g=%h i=%h", $time, g_auto_in_d_bits_source, i_auto_in_d_bits_source); end
    if (g_auto_in_d_bits_data !== i_auto_in_d_bits_data) begin errors++;
      if(errors<=30) $display("[%0t] auto_in_d_bits_data g=%h i=%h", $time, g_auto_in_d_bits_data, i_auto_in_d_bits_data); end
    if (g_io_ecc_enable !== i_io_ecc_enable) begin errors++;
      if(errors<=30) $display("[%0t] io_ecc_enable g=%h i=%h", $time, g_io_ecc_enable, i_io_ecc_enable); end
    if (g_io_injecting !== i_io_injecting) begin errors++;
      if(errors<=30) $display("[%0t] io_injecting g=%h i=%h", $time, g_io_injecting, i_io_injecting); end
    if (g_io_metaRead_valid !== i_io_metaRead_valid) begin errors++;
      if(errors<=30) $display("[%0t] io_metaRead_valid g=%h i=%h", $time, g_io_metaRead_valid, i_io_metaRead_valid); end
    if (g_io_metaRead_bits_vSetIdx_0 !== i_io_metaRead_bits_vSetIdx_0) begin errors++;
      if(errors<=30) $display("[%0t] io_metaRead_bits_vSetIdx_0 g=%h i=%h", $time, g_io_metaRead_bits_vSetIdx_0, i_io_metaRead_bits_vSetIdx_0); end
    if (g_io_metaRead_bits_vSetIdx_1 !== i_io_metaRead_bits_vSetIdx_1) begin errors++;
      if(errors<=30) $display("[%0t] io_metaRead_bits_vSetIdx_1 g=%h i=%h", $time, g_io_metaRead_bits_vSetIdx_1, i_io_metaRead_bits_vSetIdx_1); end
    if (g_io_metaWrite_valid !== i_io_metaWrite_valid) begin errors++;
      if(errors<=30) $display("[%0t] io_metaWrite_valid g=%h i=%h", $time, g_io_metaWrite_valid, i_io_metaWrite_valid); end
    if (g_io_metaWrite_bits_virIdx !== i_io_metaWrite_bits_virIdx) begin errors++;
      if(errors<=30) $display("[%0t] io_metaWrite_bits_virIdx g=%h i=%h", $time, g_io_metaWrite_bits_virIdx, i_io_metaWrite_bits_virIdx); end
    if (g_io_metaWrite_bits_phyTag !== i_io_metaWrite_bits_phyTag) begin errors++;
      if(errors<=30) $display("[%0t] io_metaWrite_bits_phyTag g=%h i=%h", $time, g_io_metaWrite_bits_phyTag, i_io_metaWrite_bits_phyTag); end
    if (g_io_metaWrite_bits_waymask !== i_io_metaWrite_bits_waymask) begin errors++;
      if(errors<=30) $display("[%0t] io_metaWrite_bits_waymask g=%h i=%h", $time, g_io_metaWrite_bits_waymask, i_io_metaWrite_bits_waymask); end
    if (g_io_metaWrite_bits_bankIdx !== i_io_metaWrite_bits_bankIdx) begin errors++;
      if(errors<=30) $display("[%0t] io_metaWrite_bits_bankIdx g=%h i=%h", $time, g_io_metaWrite_bits_bankIdx, i_io_metaWrite_bits_bankIdx); end
    if (g_io_dataWrite_valid !== i_io_dataWrite_valid) begin errors++;
      if(errors<=30) $display("[%0t] io_dataWrite_valid g=%h i=%h", $time, g_io_dataWrite_valid, i_io_dataWrite_valid); end
    if (g_io_dataWrite_bits_virIdx !== i_io_dataWrite_bits_virIdx) begin errors++;
      if(errors<=30) $display("[%0t] io_dataWrite_bits_virIdx g=%h i=%h", $time, g_io_dataWrite_bits_virIdx, i_io_dataWrite_bits_virIdx); end
    if (g_io_dataWrite_bits_waymask !== i_io_dataWrite_bits_waymask) begin errors++;
      if(errors<=30) $display("[%0t] io_dataWrite_bits_waymask g=%h i=%h", $time, g_io_dataWrite_bits_waymask, i_io_dataWrite_bits_waymask); end
  end
  initial begin
    rst = 1; repeat (5) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
