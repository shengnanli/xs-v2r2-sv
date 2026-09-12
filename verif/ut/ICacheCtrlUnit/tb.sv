// 自动生成：scripts/gen_zj_ut.py ICacheCtrlUnit —— 勿手改
// ICacheCtrlUnit 双例化逐拍比对：golden ICacheCtrlUnit vs 重写 ICacheCtrlUnit_xs（derive_ut_impl.py 派生）。
// 激励 = G1 golden 端口表全随机（ready 偏置 75% 高以制造反压）；
// 收尾判 errors / checks / toggled / fires 四项，后三项是覆盖闸（防假绿）。
`timescale 1ns/1ps
module tb;
  localparam int unsigned NCYCLES     = 120000;
  localparam int unsigned MIN_TOGGLED = 19;
  localparam int unsigned MIN_FIRES   = 20000;
  localparam int unsigned N_OUT       = 19;

  bit clock = 0;
  always #5 clock = ~clock;
  bit reset;
  longint checks = 0, errors = 0, fires = 0;
  int      toggled = 0;

  // 宽随机：$urandom 一次 32 位，拼够位宽。
  function automatic logic [2047:0] rnd(input int w);
    logic [2047:0] v;
    v = '0;
    for (int i = 0; i < w; i += 32) v[i+:32] = $urandom;
    return v;
  endfunction

  logic auto_in_a_valid;
  logic [3:0] auto_in_a_bits_opcode;
  logic [1:0] auto_in_a_bits_size;
  logic [4:0] auto_in_a_bits_source;
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
  wire [4:0] g_auto_in_d_bits_source;
  wire [4:0] i_auto_in_d_bits_source;
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

  logic p_auto_in_a_ready;   // 上一拍值（toggle 统计）
  bit tog_auto_in_a_ready;
  logic p_auto_in_d_valid;   // 上一拍值（toggle 统计）
  bit tog_auto_in_d_valid;
  logic [3:0] p_auto_in_d_bits_opcode;   // 上一拍值（toggle 统计）
  bit tog_auto_in_d_bits_opcode;
  logic [1:0] p_auto_in_d_bits_size;   // 上一拍值（toggle 统计）
  bit tog_auto_in_d_bits_size;
  logic [4:0] p_auto_in_d_bits_source;   // 上一拍值（toggle 统计）
  bit tog_auto_in_d_bits_source;
  logic [63:0] p_auto_in_d_bits_data;   // 上一拍值（toggle 统计）
  bit tog_auto_in_d_bits_data;
  logic p_io_ecc_enable;   // 上一拍值（toggle 统计）
  bit tog_io_ecc_enable;
  logic p_io_injecting;   // 上一拍值（toggle 统计）
  bit tog_io_injecting;
  logic p_io_metaRead_valid;   // 上一拍值（toggle 统计）
  bit tog_io_metaRead_valid;
  logic [7:0] p_io_metaRead_bits_vSetIdx_0;   // 上一拍值（toggle 统计）
  bit tog_io_metaRead_bits_vSetIdx_0;
  logic [7:0] p_io_metaRead_bits_vSetIdx_1;   // 上一拍值（toggle 统计）
  bit tog_io_metaRead_bits_vSetIdx_1;
  logic p_io_metaWrite_valid;   // 上一拍值（toggle 统计）
  bit tog_io_metaWrite_valid;
  logic [7:0] p_io_metaWrite_bits_virIdx;   // 上一拍值（toggle 统计）
  bit tog_io_metaWrite_bits_virIdx;
  logic [35:0] p_io_metaWrite_bits_phyTag;   // 上一拍值（toggle 统计）
  bit tog_io_metaWrite_bits_phyTag;
  logic [3:0] p_io_metaWrite_bits_waymask;   // 上一拍值（toggle 统计）
  bit tog_io_metaWrite_bits_waymask;
  logic p_io_metaWrite_bits_bankIdx;   // 上一拍值（toggle 统计）
  bit tog_io_metaWrite_bits_bankIdx;
  logic p_io_dataWrite_valid;   // 上一拍值（toggle 统计）
  bit tog_io_dataWrite_valid;
  logic [7:0] p_io_dataWrite_bits_virIdx;   // 上一拍值（toggle 统计）
  bit tog_io_dataWrite_bits_virIdx;
  logic [3:0] p_io_dataWrite_bits_waymask;   // 上一拍值（toggle 统计）
  bit tog_io_dataWrite_bits_waymask;

  ICacheCtrlUnit u_g (
    .clock(clock),
    .reset(reset),
    .auto_in_a_ready(g_auto_in_a_ready),
    .auto_in_a_valid(auto_in_a_valid),
    .auto_in_a_bits_opcode(auto_in_a_bits_opcode),
    .auto_in_a_bits_size(auto_in_a_bits_size),
    .auto_in_a_bits_source(auto_in_a_bits_source),
    .auto_in_a_bits_address(auto_in_a_bits_address),
    .auto_in_a_bits_mask(auto_in_a_bits_mask),
    .auto_in_a_bits_data(auto_in_a_bits_data),
    .auto_in_d_ready(auto_in_d_ready),
    .auto_in_d_valid(g_auto_in_d_valid),
    .auto_in_d_bits_opcode(g_auto_in_d_bits_opcode),
    .auto_in_d_bits_size(g_auto_in_d_bits_size),
    .auto_in_d_bits_source(g_auto_in_d_bits_source),
    .auto_in_d_bits_data(g_auto_in_d_bits_data),
    .io_ecc_enable(g_io_ecc_enable),
    .io_injecting(g_io_injecting),
    .io_metaRead_ready(io_metaRead_ready),
    .io_metaRead_valid(g_io_metaRead_valid),
    .io_metaRead_bits_vSetIdx_0(g_io_metaRead_bits_vSetIdx_0),
    .io_metaRead_bits_vSetIdx_1(g_io_metaRead_bits_vSetIdx_1),
    .io_metaReadResp_metas_0_0_tag(io_metaReadResp_metas_0_0_tag),
    .io_metaReadResp_metas_0_1_tag(io_metaReadResp_metas_0_1_tag),
    .io_metaReadResp_metas_0_2_tag(io_metaReadResp_metas_0_2_tag),
    .io_metaReadResp_metas_0_3_tag(io_metaReadResp_metas_0_3_tag),
    .io_metaReadResp_entryValid_0_0(io_metaReadResp_entryValid_0_0),
    .io_metaReadResp_entryValid_0_1(io_metaReadResp_entryValid_0_1),
    .io_metaReadResp_entryValid_0_2(io_metaReadResp_entryValid_0_2),
    .io_metaReadResp_entryValid_0_3(io_metaReadResp_entryValid_0_3),
    .io_metaWrite_ready(io_metaWrite_ready),
    .io_metaWrite_valid(g_io_metaWrite_valid),
    .io_metaWrite_bits_virIdx(g_io_metaWrite_bits_virIdx),
    .io_metaWrite_bits_phyTag(g_io_metaWrite_bits_phyTag),
    .io_metaWrite_bits_waymask(g_io_metaWrite_bits_waymask),
    .io_metaWrite_bits_bankIdx(g_io_metaWrite_bits_bankIdx),
    .io_dataWrite_ready(io_dataWrite_ready),
    .io_dataWrite_valid(g_io_dataWrite_valid),
    .io_dataWrite_bits_virIdx(g_io_dataWrite_bits_virIdx),
    .io_dataWrite_bits_waymask(g_io_dataWrite_bits_waymask)
  );
  ICacheCtrlUnit_xs u_i (
    .clock(clock),
    .reset(reset),
    .auto_in_a_ready(i_auto_in_a_ready),
    .auto_in_a_valid(auto_in_a_valid),
    .auto_in_a_bits_opcode(auto_in_a_bits_opcode),
    .auto_in_a_bits_size(auto_in_a_bits_size),
    .auto_in_a_bits_source(auto_in_a_bits_source),
    .auto_in_a_bits_address(auto_in_a_bits_address),
    .auto_in_a_bits_mask(auto_in_a_bits_mask),
    .auto_in_a_bits_data(auto_in_a_bits_data),
    .auto_in_d_ready(auto_in_d_ready),
    .auto_in_d_valid(i_auto_in_d_valid),
    .auto_in_d_bits_opcode(i_auto_in_d_bits_opcode),
    .auto_in_d_bits_size(i_auto_in_d_bits_size),
    .auto_in_d_bits_source(i_auto_in_d_bits_source),
    .auto_in_d_bits_data(i_auto_in_d_bits_data),
    .io_ecc_enable(i_io_ecc_enable),
    .io_injecting(i_io_injecting),
    .io_metaRead_ready(io_metaRead_ready),
    .io_metaRead_valid(i_io_metaRead_valid),
    .io_metaRead_bits_vSetIdx_0(i_io_metaRead_bits_vSetIdx_0),
    .io_metaRead_bits_vSetIdx_1(i_io_metaRead_bits_vSetIdx_1),
    .io_metaReadResp_metas_0_0_tag(io_metaReadResp_metas_0_0_tag),
    .io_metaReadResp_metas_0_1_tag(io_metaReadResp_metas_0_1_tag),
    .io_metaReadResp_metas_0_2_tag(io_metaReadResp_metas_0_2_tag),
    .io_metaReadResp_metas_0_3_tag(io_metaReadResp_metas_0_3_tag),
    .io_metaReadResp_entryValid_0_0(io_metaReadResp_entryValid_0_0),
    .io_metaReadResp_entryValid_0_1(io_metaReadResp_entryValid_0_1),
    .io_metaReadResp_entryValid_0_2(io_metaReadResp_entryValid_0_2),
    .io_metaReadResp_entryValid_0_3(io_metaReadResp_entryValid_0_3),
    .io_metaWrite_ready(io_metaWrite_ready),
    .io_metaWrite_valid(i_io_metaWrite_valid),
    .io_metaWrite_bits_virIdx(i_io_metaWrite_bits_virIdx),
    .io_metaWrite_bits_phyTag(i_io_metaWrite_bits_phyTag),
    .io_metaWrite_bits_waymask(i_io_metaWrite_bits_waymask),
    .io_metaWrite_bits_bankIdx(i_io_metaWrite_bits_bankIdx),
    .io_dataWrite_ready(io_dataWrite_ready),
    .io_dataWrite_valid(i_io_dataWrite_valid),
    .io_dataWrite_bits_virIdx(i_io_dataWrite_bits_virIdx),
    .io_dataWrite_bits_waymask(i_io_dataWrite_bits_waymask)
  );

  task automatic drive_random();
    auto_in_a_valid = $urandom % 2;
    auto_in_a_bits_opcode = (($urandom % 2) ? 4'h0 : 4'($urandom));   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    auto_in_a_bits_size = rnd(2);
    auto_in_a_bits_source = rnd(5);
    auto_in_a_bits_address = (($urandom % 2) ? 30'($urandom_range(0, 15)) : 30'($urandom));   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    auto_in_a_bits_mask = (($urandom % 2) ? 8'hFF : 8'($urandom));   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    auto_in_a_bits_data = $urandom_range(0, 32767);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    auto_in_d_ready = (($urandom % 4) != 0);            // 75% 高：制造反压
    io_metaRead_ready = (($urandom % 4) != 0);            // 75% 高：制造反压
    io_metaReadResp_metas_0_0_tag = $urandom_range(0, 7);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_metaReadResp_metas_0_1_tag = $urandom_range(0, 7);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_metaReadResp_metas_0_2_tag = $urandom_range(0, 7);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_metaReadResp_metas_0_3_tag = $urandom_range(0, 7);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_metaReadResp_entryValid_0_0 = $urandom % 2;
    io_metaReadResp_entryValid_0_1 = $urandom % 2;
    io_metaReadResp_entryValid_0_2 = $urandom % 2;
    io_metaReadResp_entryValid_0_3 = $urandom % 2;
    io_metaWrite_ready = (($urandom % 4) != 0);            // 75% 高：制造反压
    io_dataWrite_ready = (($urandom % 4) != 0);            // 75% 高：制造反压
  endtask

  task automatic check_outputs();
    if (!$isunknown(g_auto_in_a_ready)) begin
      checks++;
      if (g_auto_in_a_ready !== i_auto_in_a_ready) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH auto_in_a_ready g=%0h i=%0h", $time, g_auto_in_a_ready, i_auto_in_a_ready);
      end
    end
    if (!$isunknown(g_auto_in_d_valid)) begin
      checks++;
      if (g_auto_in_d_valid !== i_auto_in_d_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH auto_in_d_valid g=%0h i=%0h", $time, g_auto_in_d_valid, i_auto_in_d_valid);
      end
    end
    if (!$isunknown(g_auto_in_d_bits_opcode)) begin
      checks++;
      if (g_auto_in_d_bits_opcode !== i_auto_in_d_bits_opcode) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH auto_in_d_bits_opcode g=%0h i=%0h", $time, g_auto_in_d_bits_opcode, i_auto_in_d_bits_opcode);
      end
    end
    if (!$isunknown(g_auto_in_d_bits_size)) begin
      checks++;
      if (g_auto_in_d_bits_size !== i_auto_in_d_bits_size) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH auto_in_d_bits_size g=%0h i=%0h", $time, g_auto_in_d_bits_size, i_auto_in_d_bits_size);
      end
    end
    if (!$isunknown(g_auto_in_d_bits_source)) begin
      checks++;
      if (g_auto_in_d_bits_source !== i_auto_in_d_bits_source) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH auto_in_d_bits_source g=%0h i=%0h", $time, g_auto_in_d_bits_source, i_auto_in_d_bits_source);
      end
    end
    if (!$isunknown(g_auto_in_d_bits_data)) begin
      checks++;
      if (g_auto_in_d_bits_data !== i_auto_in_d_bits_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH auto_in_d_bits_data g=%0h i=%0h", $time, g_auto_in_d_bits_data, i_auto_in_d_bits_data);
      end
    end
    if (!$isunknown(g_io_ecc_enable)) begin
      checks++;
      if (g_io_ecc_enable !== i_io_ecc_enable) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_ecc_enable g=%0h i=%0h", $time, g_io_ecc_enable, i_io_ecc_enable);
      end
    end
    if (!$isunknown(g_io_injecting)) begin
      checks++;
      if (g_io_injecting !== i_io_injecting) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_injecting g=%0h i=%0h", $time, g_io_injecting, i_io_injecting);
      end
    end
    if (!$isunknown(g_io_metaRead_valid)) begin
      checks++;
      if (g_io_metaRead_valid !== i_io_metaRead_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_metaRead_valid g=%0h i=%0h", $time, g_io_metaRead_valid, i_io_metaRead_valid);
      end
    end
    if (!$isunknown(g_io_metaRead_bits_vSetIdx_0)) begin
      checks++;
      if (g_io_metaRead_bits_vSetIdx_0 !== i_io_metaRead_bits_vSetIdx_0) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_metaRead_bits_vSetIdx_0 g=%0h i=%0h", $time, g_io_metaRead_bits_vSetIdx_0, i_io_metaRead_bits_vSetIdx_0);
      end
    end
    if (!$isunknown(g_io_metaRead_bits_vSetIdx_1)) begin
      checks++;
      if (g_io_metaRead_bits_vSetIdx_1 !== i_io_metaRead_bits_vSetIdx_1) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_metaRead_bits_vSetIdx_1 g=%0h i=%0h", $time, g_io_metaRead_bits_vSetIdx_1, i_io_metaRead_bits_vSetIdx_1);
      end
    end
    if (!$isunknown(g_io_metaWrite_valid)) begin
      checks++;
      if (g_io_metaWrite_valid !== i_io_metaWrite_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_metaWrite_valid g=%0h i=%0h", $time, g_io_metaWrite_valid, i_io_metaWrite_valid);
      end
    end
    if (!$isunknown(g_io_metaWrite_bits_virIdx)) begin
      checks++;
      if (g_io_metaWrite_bits_virIdx !== i_io_metaWrite_bits_virIdx) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_metaWrite_bits_virIdx g=%0h i=%0h", $time, g_io_metaWrite_bits_virIdx, i_io_metaWrite_bits_virIdx);
      end
    end
    if (!$isunknown(g_io_metaWrite_bits_phyTag)) begin
      checks++;
      if (g_io_metaWrite_bits_phyTag !== i_io_metaWrite_bits_phyTag) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_metaWrite_bits_phyTag g=%0h i=%0h", $time, g_io_metaWrite_bits_phyTag, i_io_metaWrite_bits_phyTag);
      end
    end
    if (!$isunknown(g_io_metaWrite_bits_waymask)) begin
      checks++;
      if (g_io_metaWrite_bits_waymask !== i_io_metaWrite_bits_waymask) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_metaWrite_bits_waymask g=%0h i=%0h", $time, g_io_metaWrite_bits_waymask, i_io_metaWrite_bits_waymask);
      end
    end
    if (!$isunknown(g_io_metaWrite_bits_bankIdx)) begin
      checks++;
      if (g_io_metaWrite_bits_bankIdx !== i_io_metaWrite_bits_bankIdx) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_metaWrite_bits_bankIdx g=%0h i=%0h", $time, g_io_metaWrite_bits_bankIdx, i_io_metaWrite_bits_bankIdx);
      end
    end
    if (!$isunknown(g_io_dataWrite_valid)) begin
      checks++;
      if (g_io_dataWrite_valid !== i_io_dataWrite_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_dataWrite_valid g=%0h i=%0h", $time, g_io_dataWrite_valid, i_io_dataWrite_valid);
      end
    end
    if (!$isunknown(g_io_dataWrite_bits_virIdx)) begin
      checks++;
      if (g_io_dataWrite_bits_virIdx !== i_io_dataWrite_bits_virIdx) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_dataWrite_bits_virIdx g=%0h i=%0h", $time, g_io_dataWrite_bits_virIdx, i_io_dataWrite_bits_virIdx);
      end
    end
    if (!$isunknown(g_io_dataWrite_bits_waymask)) begin
      checks++;
      if (g_io_dataWrite_bits_waymask !== i_io_dataWrite_bits_waymask) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_dataWrite_bits_waymask g=%0h i=%0h", $time, g_io_dataWrite_bits_waymask, i_io_dataWrite_bits_waymask);
      end
    end
  endtask

  task automatic sample_coverage();
    if (g_auto_in_a_ready !== p_auto_in_a_ready) tog_auto_in_a_ready = 1'b1;
    p_auto_in_a_ready = g_auto_in_a_ready;
    if (g_auto_in_d_valid !== p_auto_in_d_valid) tog_auto_in_d_valid = 1'b1;
    p_auto_in_d_valid = g_auto_in_d_valid;
    if (g_auto_in_d_bits_opcode !== p_auto_in_d_bits_opcode) tog_auto_in_d_bits_opcode = 1'b1;
    p_auto_in_d_bits_opcode = g_auto_in_d_bits_opcode;
    if (g_auto_in_d_bits_size !== p_auto_in_d_bits_size) tog_auto_in_d_bits_size = 1'b1;
    p_auto_in_d_bits_size = g_auto_in_d_bits_size;
    if (g_auto_in_d_bits_source !== p_auto_in_d_bits_source) tog_auto_in_d_bits_source = 1'b1;
    p_auto_in_d_bits_source = g_auto_in_d_bits_source;
    if (g_auto_in_d_bits_data !== p_auto_in_d_bits_data) tog_auto_in_d_bits_data = 1'b1;
    p_auto_in_d_bits_data = g_auto_in_d_bits_data;
    if (g_io_ecc_enable !== p_io_ecc_enable) tog_io_ecc_enable = 1'b1;
    p_io_ecc_enable = g_io_ecc_enable;
    if (g_io_injecting !== p_io_injecting) tog_io_injecting = 1'b1;
    p_io_injecting = g_io_injecting;
    if (g_io_metaRead_valid !== p_io_metaRead_valid) tog_io_metaRead_valid = 1'b1;
    p_io_metaRead_valid = g_io_metaRead_valid;
    if (g_io_metaRead_bits_vSetIdx_0 !== p_io_metaRead_bits_vSetIdx_0) tog_io_metaRead_bits_vSetIdx_0 = 1'b1;
    p_io_metaRead_bits_vSetIdx_0 = g_io_metaRead_bits_vSetIdx_0;
    if (g_io_metaRead_bits_vSetIdx_1 !== p_io_metaRead_bits_vSetIdx_1) tog_io_metaRead_bits_vSetIdx_1 = 1'b1;
    p_io_metaRead_bits_vSetIdx_1 = g_io_metaRead_bits_vSetIdx_1;
    if (g_io_metaWrite_valid !== p_io_metaWrite_valid) tog_io_metaWrite_valid = 1'b1;
    p_io_metaWrite_valid = g_io_metaWrite_valid;
    if (g_io_metaWrite_bits_virIdx !== p_io_metaWrite_bits_virIdx) tog_io_metaWrite_bits_virIdx = 1'b1;
    p_io_metaWrite_bits_virIdx = g_io_metaWrite_bits_virIdx;
    if (g_io_metaWrite_bits_phyTag !== p_io_metaWrite_bits_phyTag) tog_io_metaWrite_bits_phyTag = 1'b1;
    p_io_metaWrite_bits_phyTag = g_io_metaWrite_bits_phyTag;
    if (g_io_metaWrite_bits_waymask !== p_io_metaWrite_bits_waymask) tog_io_metaWrite_bits_waymask = 1'b1;
    p_io_metaWrite_bits_waymask = g_io_metaWrite_bits_waymask;
    if (g_io_metaWrite_bits_bankIdx !== p_io_metaWrite_bits_bankIdx) tog_io_metaWrite_bits_bankIdx = 1'b1;
    p_io_metaWrite_bits_bankIdx = g_io_metaWrite_bits_bankIdx;
    if (g_io_dataWrite_valid !== p_io_dataWrite_valid) tog_io_dataWrite_valid = 1'b1;
    p_io_dataWrite_valid = g_io_dataWrite_valid;
    if (g_io_dataWrite_bits_virIdx !== p_io_dataWrite_bits_virIdx) tog_io_dataWrite_bits_virIdx = 1'b1;
    p_io_dataWrite_bits_virIdx = g_io_dataWrite_bits_virIdx;
    if (g_io_dataWrite_bits_waymask !== p_io_dataWrite_bits_waymask) tog_io_dataWrite_bits_waymask = 1'b1;
    p_io_dataWrite_bits_waymask = g_io_dataWrite_bits_waymask;
    if ((g_auto_in_a_ready && auto_in_a_valid) ||
        (g_auto_in_d_valid && auto_in_d_ready) ||
        (g_io_metaRead_valid && io_metaRead_ready) ||
        (g_io_metaWrite_valid && io_metaWrite_ready) ||
        (g_io_dataWrite_valid && io_dataWrite_ready)) fires++;
  endtask

  initial begin
    auto_in_a_valid = '0;
    auto_in_a_bits_opcode = '0;
    auto_in_a_bits_size = '0;
    auto_in_a_bits_source = '0;
    auto_in_a_bits_address = '0;
    auto_in_a_bits_mask = '0;
    auto_in_a_bits_data = '0;
    auto_in_d_ready = '0;
    io_metaRead_ready = '0;
    io_metaReadResp_metas_0_0_tag = '0;
    io_metaReadResp_metas_0_1_tag = '0;
    io_metaReadResp_metas_0_2_tag = '0;
    io_metaReadResp_metas_0_3_tag = '0;
    io_metaReadResp_entryValid_0_0 = '0;
    io_metaReadResp_entryValid_0_1 = '0;
    io_metaReadResp_entryValid_0_2 = '0;
    io_metaReadResp_entryValid_0_3 = '0;
    io_metaWrite_ready = '0;
    io_dataWrite_ready = '0;
    p_auto_in_a_ready = '0; tog_auto_in_a_ready = 1'b0;
    p_auto_in_d_valid = '0; tog_auto_in_d_valid = 1'b0;
    p_auto_in_d_bits_opcode = '0; tog_auto_in_d_bits_opcode = 1'b0;
    p_auto_in_d_bits_size = '0; tog_auto_in_d_bits_size = 1'b0;
    p_auto_in_d_bits_source = '0; tog_auto_in_d_bits_source = 1'b0;
    p_auto_in_d_bits_data = '0; tog_auto_in_d_bits_data = 1'b0;
    p_io_ecc_enable = '0; tog_io_ecc_enable = 1'b0;
    p_io_injecting = '0; tog_io_injecting = 1'b0;
    p_io_metaRead_valid = '0; tog_io_metaRead_valid = 1'b0;
    p_io_metaRead_bits_vSetIdx_0 = '0; tog_io_metaRead_bits_vSetIdx_0 = 1'b0;
    p_io_metaRead_bits_vSetIdx_1 = '0; tog_io_metaRead_bits_vSetIdx_1 = 1'b0;
    p_io_metaWrite_valid = '0; tog_io_metaWrite_valid = 1'b0;
    p_io_metaWrite_bits_virIdx = '0; tog_io_metaWrite_bits_virIdx = 1'b0;
    p_io_metaWrite_bits_phyTag = '0; tog_io_metaWrite_bits_phyTag = 1'b0;
    p_io_metaWrite_bits_waymask = '0; tog_io_metaWrite_bits_waymask = 1'b0;
    p_io_metaWrite_bits_bankIdx = '0; tog_io_metaWrite_bits_bankIdx = 1'b0;
    p_io_dataWrite_valid = '0; tog_io_dataWrite_valid = 1'b0;
    p_io_dataWrite_bits_virIdx = '0; tog_io_dataWrite_bits_virIdx = 1'b0;
    p_io_dataWrite_bits_waymask = '0; tog_io_dataWrite_bits_waymask = 1'b0;
    reset = 1'b1;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    for (int unsigned c = 0; c < NCYCLES; c++) begin
      // 中途再来一次复位脉冲，覆盖复位路径（两侧同拍同源）。
      if (c == NCYCLES/2) begin
        @(negedge clock); reset = 1'b1;
        repeat (3) @(posedge clock);
        @(negedge clock); reset = 1'b0;
      end
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      sample_coverage();
      @(posedge clock);
    end

    if (tog_auto_in_a_ready) toggled++; else $display("COV: output auto_in_a_ready never toggled");
    if (tog_auto_in_d_valid) toggled++; else $display("COV: output auto_in_d_valid never toggled");
    if (tog_auto_in_d_bits_opcode) toggled++; else $display("COV: output auto_in_d_bits_opcode never toggled");
    if (tog_auto_in_d_bits_size) toggled++; else $display("COV: output auto_in_d_bits_size never toggled");
    if (tog_auto_in_d_bits_source) toggled++; else $display("COV: output auto_in_d_bits_source never toggled");
    if (tog_auto_in_d_bits_data) toggled++; else $display("COV: output auto_in_d_bits_data never toggled");
    if (tog_io_ecc_enable) toggled++; else $display("COV: output io_ecc_enable never toggled");
    if (tog_io_injecting) toggled++; else $display("COV: output io_injecting never toggled");
    if (tog_io_metaRead_valid) toggled++; else $display("COV: output io_metaRead_valid never toggled");
    if (tog_io_metaRead_bits_vSetIdx_0) toggled++; else $display("COV: output io_metaRead_bits_vSetIdx_0 never toggled");
    if (tog_io_metaRead_bits_vSetIdx_1) toggled++; else $display("COV: output io_metaRead_bits_vSetIdx_1 never toggled");
    if (tog_io_metaWrite_valid) toggled++; else $display("COV: output io_metaWrite_valid never toggled");
    if (tog_io_metaWrite_bits_virIdx) toggled++; else $display("COV: output io_metaWrite_bits_virIdx never toggled");
    if (tog_io_metaWrite_bits_phyTag) toggled++; else $display("COV: output io_metaWrite_bits_phyTag never toggled");
    if (tog_io_metaWrite_bits_waymask) toggled++; else $display("COV: output io_metaWrite_bits_waymask never toggled");
    if (tog_io_metaWrite_bits_bankIdx) toggled++; else $display("COV: output io_metaWrite_bits_bankIdx never toggled");
    if (tog_io_dataWrite_valid) toggled++; else $display("COV: output io_dataWrite_valid never toggled");
    if (tog_io_dataWrite_bits_virIdx) toggled++; else $display("COV: output io_dataWrite_bits_virIdx never toggled");
    if (tog_io_dataWrite_bits_waymask) toggled++; else $display("COV: output io_dataWrite_bits_waymask never toggled");
    $display("ICacheCtrlUnit checks=%0d errors=%0d toggled=%0d/%0d fires=%0d", checks, errors, toggled, N_OUT, fires);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0) begin $display("TEST FAILED (coverage: no comparison happened)"); $fatal(1); end
    if (toggled < MIN_TOGGLED) begin $display("TEST FAILED (coverage: only %0d outputs toggled, need >= %0d)", toggled, MIN_TOGGLED); $fatal(1); end
    if (fires < MIN_FIRES) begin $display("TEST FAILED (coverage: only %0d handshake fires, need >= %0d)", fires, MIN_FIRES); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
