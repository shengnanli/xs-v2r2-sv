// 自动生成：scripts/gen_l2slice_ut.py —— 勿手改（命令行见同目录 Makefile 的 gentb）
// 目标：DataStorage DataStorage_1 DataStorage_2 DataStorage_3
// golden <T> 与派生 <T>_xs 双例化，同激励逐拍 4 态比全部输出；覆盖闸见文件尾。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  always #5 clock = ~clock;
  logic reset;
  longint checks = 0, errors = 0;
  longint cyc = 0;   // 复位释放后的拍号（--narrow 表达式可用它做分相激励）
  function automatic logic [4095:0] rnd(input int w);
    logic [4095:0] v;
    v = '0;
    for (int i = 0; i < w; i += 32) v[i+:32] = $urandom;
    return v;
  endfunction

  // ======================= DataStorage =======================
  logic DataStorage__io_en;
  logic DataStorage__io_req_valid;
  logic [2:0] DataStorage__io_req_bits_way;
  logic [8:0] DataStorage__io_req_bits_set;
  logic DataStorage__io_req_bits_wen;
  logic [511:0] DataStorage__io_wdata_data;
  logic [3:0] DataStorage__boreChildrenBd_bore_array;
  logic DataStorage__boreChildrenBd_bore_all;
  logic DataStorage__boreChildrenBd_bore_req;
  logic DataStorage__boreChildrenBd_bore_writeen;
  logic DataStorage__boreChildrenBd_bore_be;
  logic [12:0] DataStorage__boreChildrenBd_bore_addr;
  logic [136:0] DataStorage__boreChildrenBd_bore_indata;
  logic DataStorage__boreChildrenBd_bore_readen;
  logic [12:0] DataStorage__boreChildrenBd_bore_addr_rd;
  logic DataStorage__sigFromSrams_bore_ram_hold;
  logic DataStorage__sigFromSrams_bore_ram_bypass;
  logic DataStorage__sigFromSrams_bore_ram_bp_clken;
  logic DataStorage__sigFromSrams_bore_ram_aux_clk;
  logic DataStorage__sigFromSrams_bore_ram_aux_ckbp;
  logic DataStorage__sigFromSrams_bore_ram_mcp_hold;
  logic DataStorage__sigFromSrams_bore_cgen;
  logic DataStorage__sigFromSrams_bore_1_ram_hold;
  logic DataStorage__sigFromSrams_bore_1_ram_bypass;
  logic DataStorage__sigFromSrams_bore_1_ram_bp_clken;
  logic DataStorage__sigFromSrams_bore_1_ram_aux_clk;
  logic DataStorage__sigFromSrams_bore_1_ram_aux_ckbp;
  logic DataStorage__sigFromSrams_bore_1_ram_mcp_hold;
  logic DataStorage__sigFromSrams_bore_1_cgen;
  logic DataStorage__sigFromSrams_bore_2_ram_hold;
  logic DataStorage__sigFromSrams_bore_2_ram_bypass;
  logic DataStorage__sigFromSrams_bore_2_ram_bp_clken;
  logic DataStorage__sigFromSrams_bore_2_ram_aux_clk;
  logic DataStorage__sigFromSrams_bore_2_ram_aux_ckbp;
  logic DataStorage__sigFromSrams_bore_2_ram_mcp_hold;
  logic DataStorage__sigFromSrams_bore_2_cgen;
  logic DataStorage__sigFromSrams_bore_3_ram_hold;
  logic DataStorage__sigFromSrams_bore_3_ram_bypass;
  logic DataStorage__sigFromSrams_bore_3_ram_bp_clken;
  logic DataStorage__sigFromSrams_bore_3_ram_aux_clk;
  logic DataStorage__sigFromSrams_bore_3_ram_aux_ckbp;
  logic DataStorage__sigFromSrams_bore_3_ram_mcp_hold;
  logic DataStorage__sigFromSrams_bore_3_cgen;
  wire  g_DataStorage__io_error;
  wire  i_DataStorage__io_error;
  logic p_DataStorage__io_error;
  bit   t_DataStorage__io_error;
  wire  [511:0] g_DataStorage__io_rdata_data;
  wire  [511:0] i_DataStorage__io_rdata_data;
  logic [511:0] p_DataStorage__io_rdata_data;
  bit   t_DataStorage__io_rdata_data;
  wire  g_DataStorage__boreChildrenBd_bore_ack;
  wire  i_DataStorage__boreChildrenBd_bore_ack;
  logic p_DataStorage__boreChildrenBd_bore_ack;
  bit   t_DataStorage__boreChildrenBd_bore_ack;
  wire  [136:0] g_DataStorage__boreChildrenBd_bore_outdata;
  wire  [136:0] i_DataStorage__boreChildrenBd_bore_outdata;
  logic [136:0] p_DataStorage__boreChildrenBd_bore_outdata;
  bit   t_DataStorage__boreChildrenBd_bore_outdata;
  DataStorage u_g_DataStorage (
    .clock (clock),
    .reset (reset),
    .io_en (DataStorage__io_en),
    .io_error (g_DataStorage__io_error),
    .io_req_valid (DataStorage__io_req_valid),
    .io_req_bits_way (DataStorage__io_req_bits_way),
    .io_req_bits_set (DataStorage__io_req_bits_set),
    .io_req_bits_wen (DataStorage__io_req_bits_wen),
    .io_rdata_data (g_DataStorage__io_rdata_data),
    .io_wdata_data (DataStorage__io_wdata_data),
    .boreChildrenBd_bore_array (DataStorage__boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all (DataStorage__boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req (DataStorage__boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack (g_DataStorage__boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen (DataStorage__boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be (DataStorage__boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr (DataStorage__boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata (DataStorage__boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen (DataStorage__boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd (DataStorage__boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata (g_DataStorage__boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold (DataStorage__sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass (DataStorage__sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (DataStorage__sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk (DataStorage__sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (DataStorage__sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (DataStorage__sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen (DataStorage__sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold (DataStorage__sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass (DataStorage__sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (DataStorage__sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk (DataStorage__sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (DataStorage__sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (DataStorage__sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen (DataStorage__sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold (DataStorage__sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass (DataStorage__sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (DataStorage__sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk (DataStorage__sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (DataStorage__sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (DataStorage__sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen (DataStorage__sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold (DataStorage__sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass (DataStorage__sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (DataStorage__sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk (DataStorage__sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (DataStorage__sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (DataStorage__sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen (DataStorage__sigFromSrams_bore_3_cgen)
  );
  DataStorage_xs u_i_DataStorage (
    .clock (clock),
    .reset (reset),
    .io_en (DataStorage__io_en),
    .io_error (i_DataStorage__io_error),
    .io_req_valid (DataStorage__io_req_valid),
    .io_req_bits_way (DataStorage__io_req_bits_way),
    .io_req_bits_set (DataStorage__io_req_bits_set),
    .io_req_bits_wen (DataStorage__io_req_bits_wen),
    .io_rdata_data (i_DataStorage__io_rdata_data),
    .io_wdata_data (DataStorage__io_wdata_data),
    .boreChildrenBd_bore_array (DataStorage__boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all (DataStorage__boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req (DataStorage__boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack (i_DataStorage__boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen (DataStorage__boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be (DataStorage__boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr (DataStorage__boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata (DataStorage__boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen (DataStorage__boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd (DataStorage__boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata (i_DataStorage__boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold (DataStorage__sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass (DataStorage__sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (DataStorage__sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk (DataStorage__sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (DataStorage__sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (DataStorage__sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen (DataStorage__sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold (DataStorage__sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass (DataStorage__sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (DataStorage__sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk (DataStorage__sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (DataStorage__sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (DataStorage__sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen (DataStorage__sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold (DataStorage__sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass (DataStorage__sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (DataStorage__sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk (DataStorage__sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (DataStorage__sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (DataStorage__sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen (DataStorage__sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold (DataStorage__sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass (DataStorage__sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (DataStorage__sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk (DataStorage__sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (DataStorage__sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (DataStorage__sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen (DataStorage__sigFromSrams_bore_3_cgen)
  );
  task automatic drive_DataStorage();
    DataStorage__io_en = $urandom % 2;
    DataStorage__io_req_valid = $urandom % 2;
    DataStorage__io_req_bits_way = 3'($urandom_range(0, 1));
    DataStorage__io_req_bits_set = 9'($urandom_range(0, 3));
    DataStorage__io_req_bits_wen = $urandom % 2;
    DataStorage__io_wdata_data = rnd(512);
    DataStorage__boreChildrenBd_bore_array = rnd(4);
    DataStorage__boreChildrenBd_bore_all = $urandom % 2;
    DataStorage__boreChildrenBd_bore_req = $urandom % 2;
    DataStorage__boreChildrenBd_bore_writeen = $urandom % 2;
    DataStorage__boreChildrenBd_bore_be = $urandom % 2;
    DataStorage__boreChildrenBd_bore_addr = rnd(13);
    DataStorage__boreChildrenBd_bore_indata = rnd(137);
    DataStorage__boreChildrenBd_bore_readen = $urandom % 2;
    DataStorage__boreChildrenBd_bore_addr_rd = rnd(13);
    DataStorage__sigFromSrams_bore_ram_hold = $urandom % 2;
    DataStorage__sigFromSrams_bore_ram_bypass = $urandom % 2;
    DataStorage__sigFromSrams_bore_ram_bp_clken = $urandom % 2;
    DataStorage__sigFromSrams_bore_ram_aux_clk = 1'b0;
    DataStorage__sigFromSrams_bore_ram_aux_ckbp = 1'b0;
    DataStorage__sigFromSrams_bore_ram_mcp_hold = $urandom % 2;
    DataStorage__sigFromSrams_bore_cgen = $urandom % 2;
    DataStorage__sigFromSrams_bore_1_ram_hold = $urandom % 2;
    DataStorage__sigFromSrams_bore_1_ram_bypass = $urandom % 2;
    DataStorage__sigFromSrams_bore_1_ram_bp_clken = $urandom % 2;
    DataStorage__sigFromSrams_bore_1_ram_aux_clk = 1'b0;
    DataStorage__sigFromSrams_bore_1_ram_aux_ckbp = 1'b0;
    DataStorage__sigFromSrams_bore_1_ram_mcp_hold = $urandom % 2;
    DataStorage__sigFromSrams_bore_1_cgen = $urandom % 2;
    DataStorage__sigFromSrams_bore_2_ram_hold = $urandom % 2;
    DataStorage__sigFromSrams_bore_2_ram_bypass = $urandom % 2;
    DataStorage__sigFromSrams_bore_2_ram_bp_clken = $urandom % 2;
    DataStorage__sigFromSrams_bore_2_ram_aux_clk = 1'b0;
    DataStorage__sigFromSrams_bore_2_ram_aux_ckbp = 1'b0;
    DataStorage__sigFromSrams_bore_2_ram_mcp_hold = $urandom % 2;
    DataStorage__sigFromSrams_bore_2_cgen = $urandom % 2;
    DataStorage__sigFromSrams_bore_3_ram_hold = $urandom % 2;
    DataStorage__sigFromSrams_bore_3_ram_bypass = $urandom % 2;
    DataStorage__sigFromSrams_bore_3_ram_bp_clken = $urandom % 2;
    DataStorage__sigFromSrams_bore_3_ram_aux_clk = 1'b0;
    DataStorage__sigFromSrams_bore_3_ram_aux_ckbp = 1'b0;
    DataStorage__sigFromSrams_bore_3_ram_mcp_hold = $urandom % 2;
    DataStorage__sigFromSrams_bore_3_cgen = $urandom % 2;
  endtask
  task automatic check_DataStorage();
    checks++;
    if (g_DataStorage__io_error !== i_DataStorage__io_error) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH DataStorage.io_error g=%h i=%h", cyc, g_DataStorage__io_error, i_DataStorage__io_error);
    end
    if (g_DataStorage__io_error !== p_DataStorage__io_error) t_DataStorage__io_error = 1'b1;
    p_DataStorage__io_error = g_DataStorage__io_error;
    checks++;
    if (g_DataStorage__io_rdata_data !== i_DataStorage__io_rdata_data) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH DataStorage.io_rdata_data g=%h i=%h", cyc, g_DataStorage__io_rdata_data, i_DataStorage__io_rdata_data);
    end
    if (g_DataStorage__io_rdata_data !== p_DataStorage__io_rdata_data) t_DataStorage__io_rdata_data = 1'b1;
    p_DataStorage__io_rdata_data = g_DataStorage__io_rdata_data;
    checks++;
    if (g_DataStorage__boreChildrenBd_bore_ack !== i_DataStorage__boreChildrenBd_bore_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH DataStorage.boreChildrenBd_bore_ack g=%h i=%h", cyc, g_DataStorage__boreChildrenBd_bore_ack, i_DataStorage__boreChildrenBd_bore_ack);
    end
    if (g_DataStorage__boreChildrenBd_bore_ack !== p_DataStorage__boreChildrenBd_bore_ack) t_DataStorage__boreChildrenBd_bore_ack = 1'b1;
    p_DataStorage__boreChildrenBd_bore_ack = g_DataStorage__boreChildrenBd_bore_ack;
    checks++;
    if (g_DataStorage__boreChildrenBd_bore_outdata !== i_DataStorage__boreChildrenBd_bore_outdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH DataStorage.boreChildrenBd_bore_outdata g=%h i=%h", cyc, g_DataStorage__boreChildrenBd_bore_outdata, i_DataStorage__boreChildrenBd_bore_outdata);
    end
    if (g_DataStorage__boreChildrenBd_bore_outdata !== p_DataStorage__boreChildrenBd_bore_outdata) t_DataStorage__boreChildrenBd_bore_outdata = 1'b1;
    p_DataStorage__boreChildrenBd_bore_outdata = g_DataStorage__boreChildrenBd_bore_outdata;
  endtask
  longint cov_DataStorage_rd = 0;
  longint cov_DataStorage_err = 0;
  longint cov_DataStorage_wr = 0;
  task automatic cover_DataStorage();
    if (u_g_DataStorage.error_REG_1) cov_DataStorage_rd++;
    if (u_g_DataStorage.io_error) cov_DataStorage_err++;
    if (u_g_DataStorage.io_req_valid && u_g_DataStorage.io_req_bits_wen) cov_DataStorage_wr++;
  endtask
  task automatic preinit_DataStorage();
  endtask
  task automatic sync_DataStorage();
    u_i_DataStorage.array.array_0_0_0.array.array.array_18_ext.ram = u_g_DataStorage.array.array_0_0_0.array.array.array_18_ext.ram;
    u_i_DataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_addr = u_g_DataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_addr;
    u_i_DataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_ren = u_g_DataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_ren;
    force u_i_DataStorage.array.array_0_0_0.u_core.rdataReg = u_g_DataStorage.array.array_0_0_0.rdataReg;
    #0 release u_i_DataStorage.array.array_0_0_0.u_core.rdataReg;
    u_i_DataStorage.array.array_0_0_1.array.array.array_18_ext.ram = u_g_DataStorage.array.array_0_0_1.array.array.array_18_ext.ram;
    u_i_DataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_addr = u_g_DataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_addr;
    u_i_DataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_ren = u_g_DataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_ren;
    force u_i_DataStorage.array.array_0_0_1.u_core.rdataReg = u_g_DataStorage.array.array_0_0_1.rdataReg;
    #0 release u_i_DataStorage.array.array_0_0_1.u_core.rdataReg;
    u_i_DataStorage.array.array_0_0_2.array.array.array_18_ext.ram = u_g_DataStorage.array.array_0_0_2.array.array.array_18_ext.ram;
    u_i_DataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_addr = u_g_DataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_addr;
    u_i_DataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_ren = u_g_DataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_ren;
    force u_i_DataStorage.array.array_0_0_2.u_core.rdataReg = u_g_DataStorage.array.array_0_0_2.rdataReg;
    #0 release u_i_DataStorage.array.array_0_0_2.u_core.rdataReg;
    u_i_DataStorage.array.array_0_0_3.array.array.array_18_ext.ram = u_g_DataStorage.array.array_0_0_3.array.array.array_18_ext.ram;
    u_i_DataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_addr = u_g_DataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_addr;
    u_i_DataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_ren = u_g_DataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_ren;
    force u_i_DataStorage.array.array_0_0_3.u_core.rdataReg = u_g_DataStorage.array.array_0_0_3.rdataReg;
    #0 release u_i_DataStorage.array.array_0_0_3.u_core.rdataReg;
    force u_i_DataStorage.u_core.error_REG = u_g_DataStorage.error_REG;
    #0 release u_i_DataStorage.u_core.error_REG;
    force u_i_DataStorage.u_core.error_REG_1 = u_g_DataStorage.error_REG_1;
    #0 release u_i_DataStorage.u_core.error_REG_1;
  endtask

  // ======================= DataStorage_1 =======================
  logic DataStorage_1__io_en;
  logic DataStorage_1__io_req_valid;
  logic [2:0] DataStorage_1__io_req_bits_way;
  logic [8:0] DataStorage_1__io_req_bits_set;
  logic DataStorage_1__io_req_bits_wen;
  logic [511:0] DataStorage_1__io_wdata_data;
  logic [4:0] DataStorage_1__boreChildrenBd_bore_array;
  logic DataStorage_1__boreChildrenBd_bore_all;
  logic DataStorage_1__boreChildrenBd_bore_req;
  logic DataStorage_1__boreChildrenBd_bore_writeen;
  logic DataStorage_1__boreChildrenBd_bore_be;
  logic [12:0] DataStorage_1__boreChildrenBd_bore_addr;
  logic [136:0] DataStorage_1__boreChildrenBd_bore_indata;
  logic DataStorage_1__boreChildrenBd_bore_readen;
  logic [12:0] DataStorage_1__boreChildrenBd_bore_addr_rd;
  logic DataStorage_1__sigFromSrams_bore_ram_hold;
  logic DataStorage_1__sigFromSrams_bore_ram_bypass;
  logic DataStorage_1__sigFromSrams_bore_ram_bp_clken;
  logic DataStorage_1__sigFromSrams_bore_ram_aux_clk;
  logic DataStorage_1__sigFromSrams_bore_ram_aux_ckbp;
  logic DataStorage_1__sigFromSrams_bore_ram_mcp_hold;
  logic DataStorage_1__sigFromSrams_bore_cgen;
  logic DataStorage_1__sigFromSrams_bore_1_ram_hold;
  logic DataStorage_1__sigFromSrams_bore_1_ram_bypass;
  logic DataStorage_1__sigFromSrams_bore_1_ram_bp_clken;
  logic DataStorage_1__sigFromSrams_bore_1_ram_aux_clk;
  logic DataStorage_1__sigFromSrams_bore_1_ram_aux_ckbp;
  logic DataStorage_1__sigFromSrams_bore_1_ram_mcp_hold;
  logic DataStorage_1__sigFromSrams_bore_1_cgen;
  logic DataStorage_1__sigFromSrams_bore_2_ram_hold;
  logic DataStorage_1__sigFromSrams_bore_2_ram_bypass;
  logic DataStorage_1__sigFromSrams_bore_2_ram_bp_clken;
  logic DataStorage_1__sigFromSrams_bore_2_ram_aux_clk;
  logic DataStorage_1__sigFromSrams_bore_2_ram_aux_ckbp;
  logic DataStorage_1__sigFromSrams_bore_2_ram_mcp_hold;
  logic DataStorage_1__sigFromSrams_bore_2_cgen;
  logic DataStorage_1__sigFromSrams_bore_3_ram_hold;
  logic DataStorage_1__sigFromSrams_bore_3_ram_bypass;
  logic DataStorage_1__sigFromSrams_bore_3_ram_bp_clken;
  logic DataStorage_1__sigFromSrams_bore_3_ram_aux_clk;
  logic DataStorage_1__sigFromSrams_bore_3_ram_aux_ckbp;
  logic DataStorage_1__sigFromSrams_bore_3_ram_mcp_hold;
  logic DataStorage_1__sigFromSrams_bore_3_cgen;
  wire  g_DataStorage_1__io_error;
  wire  i_DataStorage_1__io_error;
  logic p_DataStorage_1__io_error;
  bit   t_DataStorage_1__io_error;
  wire  [511:0] g_DataStorage_1__io_rdata_data;
  wire  [511:0] i_DataStorage_1__io_rdata_data;
  logic [511:0] p_DataStorage_1__io_rdata_data;
  bit   t_DataStorage_1__io_rdata_data;
  wire  g_DataStorage_1__boreChildrenBd_bore_ack;
  wire  i_DataStorage_1__boreChildrenBd_bore_ack;
  logic p_DataStorage_1__boreChildrenBd_bore_ack;
  bit   t_DataStorage_1__boreChildrenBd_bore_ack;
  wire  [136:0] g_DataStorage_1__boreChildrenBd_bore_outdata;
  wire  [136:0] i_DataStorage_1__boreChildrenBd_bore_outdata;
  logic [136:0] p_DataStorage_1__boreChildrenBd_bore_outdata;
  bit   t_DataStorage_1__boreChildrenBd_bore_outdata;
  DataStorage_1 u_g_DataStorage_1 (
    .clock (clock),
    .reset (reset),
    .io_en (DataStorage_1__io_en),
    .io_error (g_DataStorage_1__io_error),
    .io_req_valid (DataStorage_1__io_req_valid),
    .io_req_bits_way (DataStorage_1__io_req_bits_way),
    .io_req_bits_set (DataStorage_1__io_req_bits_set),
    .io_req_bits_wen (DataStorage_1__io_req_bits_wen),
    .io_rdata_data (g_DataStorage_1__io_rdata_data),
    .io_wdata_data (DataStorage_1__io_wdata_data),
    .boreChildrenBd_bore_array (DataStorage_1__boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all (DataStorage_1__boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req (DataStorage_1__boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack (g_DataStorage_1__boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen (DataStorage_1__boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be (DataStorage_1__boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr (DataStorage_1__boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata (DataStorage_1__boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen (DataStorage_1__boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd (DataStorage_1__boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata (g_DataStorage_1__boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold (DataStorage_1__sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass (DataStorage_1__sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (DataStorage_1__sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk (DataStorage_1__sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (DataStorage_1__sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (DataStorage_1__sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen (DataStorage_1__sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold (DataStorage_1__sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass (DataStorage_1__sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (DataStorage_1__sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk (DataStorage_1__sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (DataStorage_1__sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (DataStorage_1__sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen (DataStorage_1__sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold (DataStorage_1__sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass (DataStorage_1__sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (DataStorage_1__sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk (DataStorage_1__sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (DataStorage_1__sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (DataStorage_1__sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen (DataStorage_1__sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold (DataStorage_1__sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass (DataStorage_1__sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (DataStorage_1__sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk (DataStorage_1__sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (DataStorage_1__sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (DataStorage_1__sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen (DataStorage_1__sigFromSrams_bore_3_cgen)
  );
  DataStorage_1_xs u_i_DataStorage_1 (
    .clock (clock),
    .reset (reset),
    .io_en (DataStorage_1__io_en),
    .io_error (i_DataStorage_1__io_error),
    .io_req_valid (DataStorage_1__io_req_valid),
    .io_req_bits_way (DataStorage_1__io_req_bits_way),
    .io_req_bits_set (DataStorage_1__io_req_bits_set),
    .io_req_bits_wen (DataStorage_1__io_req_bits_wen),
    .io_rdata_data (i_DataStorage_1__io_rdata_data),
    .io_wdata_data (DataStorage_1__io_wdata_data),
    .boreChildrenBd_bore_array (DataStorage_1__boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all (DataStorage_1__boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req (DataStorage_1__boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack (i_DataStorage_1__boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen (DataStorage_1__boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be (DataStorage_1__boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr (DataStorage_1__boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata (DataStorage_1__boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen (DataStorage_1__boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd (DataStorage_1__boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata (i_DataStorage_1__boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold (DataStorage_1__sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass (DataStorage_1__sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (DataStorage_1__sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk (DataStorage_1__sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (DataStorage_1__sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (DataStorage_1__sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen (DataStorage_1__sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold (DataStorage_1__sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass (DataStorage_1__sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (DataStorage_1__sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk (DataStorage_1__sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (DataStorage_1__sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (DataStorage_1__sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen (DataStorage_1__sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold (DataStorage_1__sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass (DataStorage_1__sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (DataStorage_1__sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk (DataStorage_1__sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (DataStorage_1__sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (DataStorage_1__sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen (DataStorage_1__sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold (DataStorage_1__sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass (DataStorage_1__sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (DataStorage_1__sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk (DataStorage_1__sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (DataStorage_1__sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (DataStorage_1__sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen (DataStorage_1__sigFromSrams_bore_3_cgen)
  );
  task automatic drive_DataStorage_1();
    DataStorage_1__io_en = $urandom % 2;
    DataStorage_1__io_req_valid = $urandom % 2;
    DataStorage_1__io_req_bits_way = 3'($urandom_range(0, 1));
    DataStorage_1__io_req_bits_set = 9'($urandom_range(0, 3));
    DataStorage_1__io_req_bits_wen = $urandom % 2;
    DataStorage_1__io_wdata_data = rnd(512);
    DataStorage_1__boreChildrenBd_bore_array = rnd(5);
    DataStorage_1__boreChildrenBd_bore_all = $urandom % 2;
    DataStorage_1__boreChildrenBd_bore_req = $urandom % 2;
    DataStorage_1__boreChildrenBd_bore_writeen = $urandom % 2;
    DataStorage_1__boreChildrenBd_bore_be = $urandom % 2;
    DataStorage_1__boreChildrenBd_bore_addr = rnd(13);
    DataStorage_1__boreChildrenBd_bore_indata = rnd(137);
    DataStorage_1__boreChildrenBd_bore_readen = $urandom % 2;
    DataStorage_1__boreChildrenBd_bore_addr_rd = rnd(13);
    DataStorage_1__sigFromSrams_bore_ram_hold = $urandom % 2;
    DataStorage_1__sigFromSrams_bore_ram_bypass = $urandom % 2;
    DataStorage_1__sigFromSrams_bore_ram_bp_clken = $urandom % 2;
    DataStorage_1__sigFromSrams_bore_ram_aux_clk = 1'b0;
    DataStorage_1__sigFromSrams_bore_ram_aux_ckbp = 1'b0;
    DataStorage_1__sigFromSrams_bore_ram_mcp_hold = $urandom % 2;
    DataStorage_1__sigFromSrams_bore_cgen = $urandom % 2;
    DataStorage_1__sigFromSrams_bore_1_ram_hold = $urandom % 2;
    DataStorage_1__sigFromSrams_bore_1_ram_bypass = $urandom % 2;
    DataStorage_1__sigFromSrams_bore_1_ram_bp_clken = $urandom % 2;
    DataStorage_1__sigFromSrams_bore_1_ram_aux_clk = 1'b0;
    DataStorage_1__sigFromSrams_bore_1_ram_aux_ckbp = 1'b0;
    DataStorage_1__sigFromSrams_bore_1_ram_mcp_hold = $urandom % 2;
    DataStorage_1__sigFromSrams_bore_1_cgen = $urandom % 2;
    DataStorage_1__sigFromSrams_bore_2_ram_hold = $urandom % 2;
    DataStorage_1__sigFromSrams_bore_2_ram_bypass = $urandom % 2;
    DataStorage_1__sigFromSrams_bore_2_ram_bp_clken = $urandom % 2;
    DataStorage_1__sigFromSrams_bore_2_ram_aux_clk = 1'b0;
    DataStorage_1__sigFromSrams_bore_2_ram_aux_ckbp = 1'b0;
    DataStorage_1__sigFromSrams_bore_2_ram_mcp_hold = $urandom % 2;
    DataStorage_1__sigFromSrams_bore_2_cgen = $urandom % 2;
    DataStorage_1__sigFromSrams_bore_3_ram_hold = $urandom % 2;
    DataStorage_1__sigFromSrams_bore_3_ram_bypass = $urandom % 2;
    DataStorage_1__sigFromSrams_bore_3_ram_bp_clken = $urandom % 2;
    DataStorage_1__sigFromSrams_bore_3_ram_aux_clk = 1'b0;
    DataStorage_1__sigFromSrams_bore_3_ram_aux_ckbp = 1'b0;
    DataStorage_1__sigFromSrams_bore_3_ram_mcp_hold = $urandom % 2;
    DataStorage_1__sigFromSrams_bore_3_cgen = $urandom % 2;
  endtask
  task automatic check_DataStorage_1();
    checks++;
    if (g_DataStorage_1__io_error !== i_DataStorage_1__io_error) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH DataStorage_1.io_error g=%h i=%h", cyc, g_DataStorage_1__io_error, i_DataStorage_1__io_error);
    end
    if (g_DataStorage_1__io_error !== p_DataStorage_1__io_error) t_DataStorage_1__io_error = 1'b1;
    p_DataStorage_1__io_error = g_DataStorage_1__io_error;
    checks++;
    if (g_DataStorage_1__io_rdata_data !== i_DataStorage_1__io_rdata_data) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH DataStorage_1.io_rdata_data g=%h i=%h", cyc, g_DataStorage_1__io_rdata_data, i_DataStorage_1__io_rdata_data);
    end
    if (g_DataStorage_1__io_rdata_data !== p_DataStorage_1__io_rdata_data) t_DataStorage_1__io_rdata_data = 1'b1;
    p_DataStorage_1__io_rdata_data = g_DataStorage_1__io_rdata_data;
    checks++;
    if (g_DataStorage_1__boreChildrenBd_bore_ack !== i_DataStorage_1__boreChildrenBd_bore_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH DataStorage_1.boreChildrenBd_bore_ack g=%h i=%h", cyc, g_DataStorage_1__boreChildrenBd_bore_ack, i_DataStorage_1__boreChildrenBd_bore_ack);
    end
    if (g_DataStorage_1__boreChildrenBd_bore_ack !== p_DataStorage_1__boreChildrenBd_bore_ack) t_DataStorage_1__boreChildrenBd_bore_ack = 1'b1;
    p_DataStorage_1__boreChildrenBd_bore_ack = g_DataStorage_1__boreChildrenBd_bore_ack;
    checks++;
    if (g_DataStorage_1__boreChildrenBd_bore_outdata !== i_DataStorage_1__boreChildrenBd_bore_outdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH DataStorage_1.boreChildrenBd_bore_outdata g=%h i=%h", cyc, g_DataStorage_1__boreChildrenBd_bore_outdata, i_DataStorage_1__boreChildrenBd_bore_outdata);
    end
    if (g_DataStorage_1__boreChildrenBd_bore_outdata !== p_DataStorage_1__boreChildrenBd_bore_outdata) t_DataStorage_1__boreChildrenBd_bore_outdata = 1'b1;
    p_DataStorage_1__boreChildrenBd_bore_outdata = g_DataStorage_1__boreChildrenBd_bore_outdata;
  endtask
  longint cov_DataStorage_1_rd = 0;
  longint cov_DataStorage_1_err = 0;
  longint cov_DataStorage_1_wr = 0;
  task automatic cover_DataStorage_1();
    if (u_g_DataStorage_1.error_REG_1) cov_DataStorage_1_rd++;
    if (u_g_DataStorage_1.io_error) cov_DataStorage_1_err++;
    if (u_g_DataStorage_1.io_req_valid && u_g_DataStorage_1.io_req_bits_wen) cov_DataStorage_1_wr++;
  endtask
  task automatic preinit_DataStorage_1();
  endtask
  task automatic sync_DataStorage_1();
    u_i_DataStorage_1.array.array_0_0_0.array.array.array_18_ext.ram = u_g_DataStorage_1.array.array_0_0_0.array.array.array_18_ext.ram;
    u_i_DataStorage_1.array.array_0_0_0.array.array.array_18_ext.reg_RW0_addr = u_g_DataStorage_1.array.array_0_0_0.array.array.array_18_ext.reg_RW0_addr;
    u_i_DataStorage_1.array.array_0_0_0.array.array.array_18_ext.reg_RW0_ren = u_g_DataStorage_1.array.array_0_0_0.array.array.array_18_ext.reg_RW0_ren;
    force u_i_DataStorage_1.array.array_0_0_0.u_core.rdataReg = u_g_DataStorage_1.array.array_0_0_0.rdataReg;
    #0 release u_i_DataStorage_1.array.array_0_0_0.u_core.rdataReg;
    u_i_DataStorage_1.array.array_0_0_1.array.array.array_18_ext.ram = u_g_DataStorage_1.array.array_0_0_1.array.array.array_18_ext.ram;
    u_i_DataStorage_1.array.array_0_0_1.array.array.array_18_ext.reg_RW0_addr = u_g_DataStorage_1.array.array_0_0_1.array.array.array_18_ext.reg_RW0_addr;
    u_i_DataStorage_1.array.array_0_0_1.array.array.array_18_ext.reg_RW0_ren = u_g_DataStorage_1.array.array_0_0_1.array.array.array_18_ext.reg_RW0_ren;
    force u_i_DataStorage_1.array.array_0_0_1.u_core.rdataReg = u_g_DataStorage_1.array.array_0_0_1.rdataReg;
    #0 release u_i_DataStorage_1.array.array_0_0_1.u_core.rdataReg;
    u_i_DataStorage_1.array.array_0_0_2.array.array.array_18_ext.ram = u_g_DataStorage_1.array.array_0_0_2.array.array.array_18_ext.ram;
    u_i_DataStorage_1.array.array_0_0_2.array.array.array_18_ext.reg_RW0_addr = u_g_DataStorage_1.array.array_0_0_2.array.array.array_18_ext.reg_RW0_addr;
    u_i_DataStorage_1.array.array_0_0_2.array.array.array_18_ext.reg_RW0_ren = u_g_DataStorage_1.array.array_0_0_2.array.array.array_18_ext.reg_RW0_ren;
    force u_i_DataStorage_1.array.array_0_0_2.u_core.rdataReg = u_g_DataStorage_1.array.array_0_0_2.rdataReg;
    #0 release u_i_DataStorage_1.array.array_0_0_2.u_core.rdataReg;
    u_i_DataStorage_1.array.array_0_0_3.array.array.array_18_ext.ram = u_g_DataStorage_1.array.array_0_0_3.array.array.array_18_ext.ram;
    u_i_DataStorage_1.array.array_0_0_3.array.array.array_18_ext.reg_RW0_addr = u_g_DataStorage_1.array.array_0_0_3.array.array.array_18_ext.reg_RW0_addr;
    u_i_DataStorage_1.array.array_0_0_3.array.array.array_18_ext.reg_RW0_ren = u_g_DataStorage_1.array.array_0_0_3.array.array.array_18_ext.reg_RW0_ren;
    force u_i_DataStorage_1.array.array_0_0_3.u_core.rdataReg = u_g_DataStorage_1.array.array_0_0_3.rdataReg;
    #0 release u_i_DataStorage_1.array.array_0_0_3.u_core.rdataReg;
    force u_i_DataStorage_1.u_core.error_REG = u_g_DataStorage_1.error_REG;
    #0 release u_i_DataStorage_1.u_core.error_REG;
    force u_i_DataStorage_1.u_core.error_REG_1 = u_g_DataStorage_1.error_REG_1;
    #0 release u_i_DataStorage_1.u_core.error_REG_1;
  endtask

  // ======================= DataStorage_2 =======================
  logic DataStorage_2__io_en;
  logic DataStorage_2__io_req_valid;
  logic [2:0] DataStorage_2__io_req_bits_way;
  logic [8:0] DataStorage_2__io_req_bits_set;
  logic DataStorage_2__io_req_bits_wen;
  logic [511:0] DataStorage_2__io_wdata_data;
  logic [5:0] DataStorage_2__boreChildrenBd_bore_array;
  logic DataStorage_2__boreChildrenBd_bore_all;
  logic DataStorage_2__boreChildrenBd_bore_req;
  logic DataStorage_2__boreChildrenBd_bore_writeen;
  logic DataStorage_2__boreChildrenBd_bore_be;
  logic [12:0] DataStorage_2__boreChildrenBd_bore_addr;
  logic [136:0] DataStorage_2__boreChildrenBd_bore_indata;
  logic DataStorage_2__boreChildrenBd_bore_readen;
  logic [12:0] DataStorage_2__boreChildrenBd_bore_addr_rd;
  logic DataStorage_2__sigFromSrams_bore_ram_hold;
  logic DataStorage_2__sigFromSrams_bore_ram_bypass;
  logic DataStorage_2__sigFromSrams_bore_ram_bp_clken;
  logic DataStorage_2__sigFromSrams_bore_ram_aux_clk;
  logic DataStorage_2__sigFromSrams_bore_ram_aux_ckbp;
  logic DataStorage_2__sigFromSrams_bore_ram_mcp_hold;
  logic DataStorage_2__sigFromSrams_bore_cgen;
  logic DataStorage_2__sigFromSrams_bore_1_ram_hold;
  logic DataStorage_2__sigFromSrams_bore_1_ram_bypass;
  logic DataStorage_2__sigFromSrams_bore_1_ram_bp_clken;
  logic DataStorage_2__sigFromSrams_bore_1_ram_aux_clk;
  logic DataStorage_2__sigFromSrams_bore_1_ram_aux_ckbp;
  logic DataStorage_2__sigFromSrams_bore_1_ram_mcp_hold;
  logic DataStorage_2__sigFromSrams_bore_1_cgen;
  logic DataStorage_2__sigFromSrams_bore_2_ram_hold;
  logic DataStorage_2__sigFromSrams_bore_2_ram_bypass;
  logic DataStorage_2__sigFromSrams_bore_2_ram_bp_clken;
  logic DataStorage_2__sigFromSrams_bore_2_ram_aux_clk;
  logic DataStorage_2__sigFromSrams_bore_2_ram_aux_ckbp;
  logic DataStorage_2__sigFromSrams_bore_2_ram_mcp_hold;
  logic DataStorage_2__sigFromSrams_bore_2_cgen;
  logic DataStorage_2__sigFromSrams_bore_3_ram_hold;
  logic DataStorage_2__sigFromSrams_bore_3_ram_bypass;
  logic DataStorage_2__sigFromSrams_bore_3_ram_bp_clken;
  logic DataStorage_2__sigFromSrams_bore_3_ram_aux_clk;
  logic DataStorage_2__sigFromSrams_bore_3_ram_aux_ckbp;
  logic DataStorage_2__sigFromSrams_bore_3_ram_mcp_hold;
  logic DataStorage_2__sigFromSrams_bore_3_cgen;
  wire  g_DataStorage_2__io_error;
  wire  i_DataStorage_2__io_error;
  logic p_DataStorage_2__io_error;
  bit   t_DataStorage_2__io_error;
  wire  [511:0] g_DataStorage_2__io_rdata_data;
  wire  [511:0] i_DataStorage_2__io_rdata_data;
  logic [511:0] p_DataStorage_2__io_rdata_data;
  bit   t_DataStorage_2__io_rdata_data;
  wire  g_DataStorage_2__boreChildrenBd_bore_ack;
  wire  i_DataStorage_2__boreChildrenBd_bore_ack;
  logic p_DataStorage_2__boreChildrenBd_bore_ack;
  bit   t_DataStorage_2__boreChildrenBd_bore_ack;
  wire  [136:0] g_DataStorage_2__boreChildrenBd_bore_outdata;
  wire  [136:0] i_DataStorage_2__boreChildrenBd_bore_outdata;
  logic [136:0] p_DataStorage_2__boreChildrenBd_bore_outdata;
  bit   t_DataStorage_2__boreChildrenBd_bore_outdata;
  DataStorage_2 u_g_DataStorage_2 (
    .clock (clock),
    .reset (reset),
    .io_en (DataStorage_2__io_en),
    .io_error (g_DataStorage_2__io_error),
    .io_req_valid (DataStorage_2__io_req_valid),
    .io_req_bits_way (DataStorage_2__io_req_bits_way),
    .io_req_bits_set (DataStorage_2__io_req_bits_set),
    .io_req_bits_wen (DataStorage_2__io_req_bits_wen),
    .io_rdata_data (g_DataStorage_2__io_rdata_data),
    .io_wdata_data (DataStorage_2__io_wdata_data),
    .boreChildrenBd_bore_array (DataStorage_2__boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all (DataStorage_2__boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req (DataStorage_2__boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack (g_DataStorage_2__boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen (DataStorage_2__boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be (DataStorage_2__boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr (DataStorage_2__boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata (DataStorage_2__boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen (DataStorage_2__boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd (DataStorage_2__boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata (g_DataStorage_2__boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold (DataStorage_2__sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass (DataStorage_2__sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (DataStorage_2__sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk (DataStorage_2__sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (DataStorage_2__sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (DataStorage_2__sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen (DataStorage_2__sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold (DataStorage_2__sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass (DataStorage_2__sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (DataStorage_2__sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk (DataStorage_2__sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (DataStorage_2__sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (DataStorage_2__sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen (DataStorage_2__sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold (DataStorage_2__sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass (DataStorage_2__sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (DataStorage_2__sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk (DataStorage_2__sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (DataStorage_2__sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (DataStorage_2__sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen (DataStorage_2__sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold (DataStorage_2__sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass (DataStorage_2__sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (DataStorage_2__sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk (DataStorage_2__sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (DataStorage_2__sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (DataStorage_2__sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen (DataStorage_2__sigFromSrams_bore_3_cgen)
  );
  DataStorage_2_xs u_i_DataStorage_2 (
    .clock (clock),
    .reset (reset),
    .io_en (DataStorage_2__io_en),
    .io_error (i_DataStorage_2__io_error),
    .io_req_valid (DataStorage_2__io_req_valid),
    .io_req_bits_way (DataStorage_2__io_req_bits_way),
    .io_req_bits_set (DataStorage_2__io_req_bits_set),
    .io_req_bits_wen (DataStorage_2__io_req_bits_wen),
    .io_rdata_data (i_DataStorage_2__io_rdata_data),
    .io_wdata_data (DataStorage_2__io_wdata_data),
    .boreChildrenBd_bore_array (DataStorage_2__boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all (DataStorage_2__boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req (DataStorage_2__boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack (i_DataStorage_2__boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen (DataStorage_2__boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be (DataStorage_2__boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr (DataStorage_2__boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata (DataStorage_2__boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen (DataStorage_2__boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd (DataStorage_2__boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata (i_DataStorage_2__boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold (DataStorage_2__sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass (DataStorage_2__sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (DataStorage_2__sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk (DataStorage_2__sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (DataStorage_2__sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (DataStorage_2__sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen (DataStorage_2__sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold (DataStorage_2__sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass (DataStorage_2__sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (DataStorage_2__sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk (DataStorage_2__sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (DataStorage_2__sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (DataStorage_2__sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen (DataStorage_2__sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold (DataStorage_2__sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass (DataStorage_2__sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (DataStorage_2__sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk (DataStorage_2__sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (DataStorage_2__sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (DataStorage_2__sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen (DataStorage_2__sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold (DataStorage_2__sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass (DataStorage_2__sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (DataStorage_2__sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk (DataStorage_2__sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (DataStorage_2__sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (DataStorage_2__sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen (DataStorage_2__sigFromSrams_bore_3_cgen)
  );
  task automatic drive_DataStorage_2();
    DataStorage_2__io_en = $urandom % 2;
    DataStorage_2__io_req_valid = $urandom % 2;
    DataStorage_2__io_req_bits_way = 3'($urandom_range(0, 1));
    DataStorage_2__io_req_bits_set = 9'($urandom_range(0, 3));
    DataStorage_2__io_req_bits_wen = $urandom % 2;
    DataStorage_2__io_wdata_data = rnd(512);
    DataStorage_2__boreChildrenBd_bore_array = rnd(6);
    DataStorage_2__boreChildrenBd_bore_all = $urandom % 2;
    DataStorage_2__boreChildrenBd_bore_req = $urandom % 2;
    DataStorage_2__boreChildrenBd_bore_writeen = $urandom % 2;
    DataStorage_2__boreChildrenBd_bore_be = $urandom % 2;
    DataStorage_2__boreChildrenBd_bore_addr = rnd(13);
    DataStorage_2__boreChildrenBd_bore_indata = rnd(137);
    DataStorage_2__boreChildrenBd_bore_readen = $urandom % 2;
    DataStorage_2__boreChildrenBd_bore_addr_rd = rnd(13);
    DataStorage_2__sigFromSrams_bore_ram_hold = $urandom % 2;
    DataStorage_2__sigFromSrams_bore_ram_bypass = $urandom % 2;
    DataStorage_2__sigFromSrams_bore_ram_bp_clken = $urandom % 2;
    DataStorage_2__sigFromSrams_bore_ram_aux_clk = 1'b0;
    DataStorage_2__sigFromSrams_bore_ram_aux_ckbp = 1'b0;
    DataStorage_2__sigFromSrams_bore_ram_mcp_hold = $urandom % 2;
    DataStorage_2__sigFromSrams_bore_cgen = $urandom % 2;
    DataStorage_2__sigFromSrams_bore_1_ram_hold = $urandom % 2;
    DataStorage_2__sigFromSrams_bore_1_ram_bypass = $urandom % 2;
    DataStorage_2__sigFromSrams_bore_1_ram_bp_clken = $urandom % 2;
    DataStorage_2__sigFromSrams_bore_1_ram_aux_clk = 1'b0;
    DataStorage_2__sigFromSrams_bore_1_ram_aux_ckbp = 1'b0;
    DataStorage_2__sigFromSrams_bore_1_ram_mcp_hold = $urandom % 2;
    DataStorage_2__sigFromSrams_bore_1_cgen = $urandom % 2;
    DataStorage_2__sigFromSrams_bore_2_ram_hold = $urandom % 2;
    DataStorage_2__sigFromSrams_bore_2_ram_bypass = $urandom % 2;
    DataStorage_2__sigFromSrams_bore_2_ram_bp_clken = $urandom % 2;
    DataStorage_2__sigFromSrams_bore_2_ram_aux_clk = 1'b0;
    DataStorage_2__sigFromSrams_bore_2_ram_aux_ckbp = 1'b0;
    DataStorage_2__sigFromSrams_bore_2_ram_mcp_hold = $urandom % 2;
    DataStorage_2__sigFromSrams_bore_2_cgen = $urandom % 2;
    DataStorage_2__sigFromSrams_bore_3_ram_hold = $urandom % 2;
    DataStorage_2__sigFromSrams_bore_3_ram_bypass = $urandom % 2;
    DataStorage_2__sigFromSrams_bore_3_ram_bp_clken = $urandom % 2;
    DataStorage_2__sigFromSrams_bore_3_ram_aux_clk = 1'b0;
    DataStorage_2__sigFromSrams_bore_3_ram_aux_ckbp = 1'b0;
    DataStorage_2__sigFromSrams_bore_3_ram_mcp_hold = $urandom % 2;
    DataStorage_2__sigFromSrams_bore_3_cgen = $urandom % 2;
  endtask
  task automatic check_DataStorage_2();
    checks++;
    if (g_DataStorage_2__io_error !== i_DataStorage_2__io_error) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH DataStorage_2.io_error g=%h i=%h", cyc, g_DataStorage_2__io_error, i_DataStorage_2__io_error);
    end
    if (g_DataStorage_2__io_error !== p_DataStorage_2__io_error) t_DataStorage_2__io_error = 1'b1;
    p_DataStorage_2__io_error = g_DataStorage_2__io_error;
    checks++;
    if (g_DataStorage_2__io_rdata_data !== i_DataStorage_2__io_rdata_data) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH DataStorage_2.io_rdata_data g=%h i=%h", cyc, g_DataStorage_2__io_rdata_data, i_DataStorage_2__io_rdata_data);
    end
    if (g_DataStorage_2__io_rdata_data !== p_DataStorage_2__io_rdata_data) t_DataStorage_2__io_rdata_data = 1'b1;
    p_DataStorage_2__io_rdata_data = g_DataStorage_2__io_rdata_data;
    checks++;
    if (g_DataStorage_2__boreChildrenBd_bore_ack !== i_DataStorage_2__boreChildrenBd_bore_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH DataStorage_2.boreChildrenBd_bore_ack g=%h i=%h", cyc, g_DataStorage_2__boreChildrenBd_bore_ack, i_DataStorage_2__boreChildrenBd_bore_ack);
    end
    if (g_DataStorage_2__boreChildrenBd_bore_ack !== p_DataStorage_2__boreChildrenBd_bore_ack) t_DataStorage_2__boreChildrenBd_bore_ack = 1'b1;
    p_DataStorage_2__boreChildrenBd_bore_ack = g_DataStorage_2__boreChildrenBd_bore_ack;
    checks++;
    if (g_DataStorage_2__boreChildrenBd_bore_outdata !== i_DataStorage_2__boreChildrenBd_bore_outdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH DataStorage_2.boreChildrenBd_bore_outdata g=%h i=%h", cyc, g_DataStorage_2__boreChildrenBd_bore_outdata, i_DataStorage_2__boreChildrenBd_bore_outdata);
    end
    if (g_DataStorage_2__boreChildrenBd_bore_outdata !== p_DataStorage_2__boreChildrenBd_bore_outdata) t_DataStorage_2__boreChildrenBd_bore_outdata = 1'b1;
    p_DataStorage_2__boreChildrenBd_bore_outdata = g_DataStorage_2__boreChildrenBd_bore_outdata;
  endtask
  longint cov_DataStorage_2_rd = 0;
  longint cov_DataStorage_2_err = 0;
  longint cov_DataStorage_2_wr = 0;
  task automatic cover_DataStorage_2();
    if (u_g_DataStorage_2.error_REG_1) cov_DataStorage_2_rd++;
    if (u_g_DataStorage_2.io_error) cov_DataStorage_2_err++;
    if (u_g_DataStorage_2.io_req_valid && u_g_DataStorage_2.io_req_bits_wen) cov_DataStorage_2_wr++;
  endtask
  task automatic preinit_DataStorage_2();
  endtask
  task automatic sync_DataStorage_2();
    u_i_DataStorage_2.array.array_0_0_0.array.array.array_18_ext.ram = u_g_DataStorage_2.array.array_0_0_0.array.array.array_18_ext.ram;
    u_i_DataStorage_2.array.array_0_0_0.array.array.array_18_ext.reg_RW0_addr = u_g_DataStorage_2.array.array_0_0_0.array.array.array_18_ext.reg_RW0_addr;
    u_i_DataStorage_2.array.array_0_0_0.array.array.array_18_ext.reg_RW0_ren = u_g_DataStorage_2.array.array_0_0_0.array.array.array_18_ext.reg_RW0_ren;
    force u_i_DataStorage_2.array.array_0_0_0.u_core.rdataReg = u_g_DataStorage_2.array.array_0_0_0.rdataReg;
    #0 release u_i_DataStorage_2.array.array_0_0_0.u_core.rdataReg;
    u_i_DataStorage_2.array.array_0_0_1.array.array.array_18_ext.ram = u_g_DataStorage_2.array.array_0_0_1.array.array.array_18_ext.ram;
    u_i_DataStorage_2.array.array_0_0_1.array.array.array_18_ext.reg_RW0_addr = u_g_DataStorage_2.array.array_0_0_1.array.array.array_18_ext.reg_RW0_addr;
    u_i_DataStorage_2.array.array_0_0_1.array.array.array_18_ext.reg_RW0_ren = u_g_DataStorage_2.array.array_0_0_1.array.array.array_18_ext.reg_RW0_ren;
    force u_i_DataStorage_2.array.array_0_0_1.u_core.rdataReg = u_g_DataStorage_2.array.array_0_0_1.rdataReg;
    #0 release u_i_DataStorage_2.array.array_0_0_1.u_core.rdataReg;
    u_i_DataStorage_2.array.array_0_0_2.array.array.array_18_ext.ram = u_g_DataStorage_2.array.array_0_0_2.array.array.array_18_ext.ram;
    u_i_DataStorage_2.array.array_0_0_2.array.array.array_18_ext.reg_RW0_addr = u_g_DataStorage_2.array.array_0_0_2.array.array.array_18_ext.reg_RW0_addr;
    u_i_DataStorage_2.array.array_0_0_2.array.array.array_18_ext.reg_RW0_ren = u_g_DataStorage_2.array.array_0_0_2.array.array.array_18_ext.reg_RW0_ren;
    force u_i_DataStorage_2.array.array_0_0_2.u_core.rdataReg = u_g_DataStorage_2.array.array_0_0_2.rdataReg;
    #0 release u_i_DataStorage_2.array.array_0_0_2.u_core.rdataReg;
    u_i_DataStorage_2.array.array_0_0_3.array.array.array_18_ext.ram = u_g_DataStorage_2.array.array_0_0_3.array.array.array_18_ext.ram;
    u_i_DataStorage_2.array.array_0_0_3.array.array.array_18_ext.reg_RW0_addr = u_g_DataStorage_2.array.array_0_0_3.array.array.array_18_ext.reg_RW0_addr;
    u_i_DataStorage_2.array.array_0_0_3.array.array.array_18_ext.reg_RW0_ren = u_g_DataStorage_2.array.array_0_0_3.array.array.array_18_ext.reg_RW0_ren;
    force u_i_DataStorage_2.array.array_0_0_3.u_core.rdataReg = u_g_DataStorage_2.array.array_0_0_3.rdataReg;
    #0 release u_i_DataStorage_2.array.array_0_0_3.u_core.rdataReg;
    force u_i_DataStorage_2.u_core.error_REG = u_g_DataStorage_2.error_REG;
    #0 release u_i_DataStorage_2.u_core.error_REG;
    force u_i_DataStorage_2.u_core.error_REG_1 = u_g_DataStorage_2.error_REG_1;
    #0 release u_i_DataStorage_2.u_core.error_REG_1;
  endtask

  // ======================= DataStorage_3 =======================
  logic DataStorage_3__io_en;
  logic DataStorage_3__io_req_valid;
  logic [2:0] DataStorage_3__io_req_bits_way;
  logic [8:0] DataStorage_3__io_req_bits_set;
  logic DataStorage_3__io_req_bits_wen;
  logic [511:0] DataStorage_3__io_wdata_data;
  logic [5:0] DataStorage_3__boreChildrenBd_bore_array;
  logic DataStorage_3__boreChildrenBd_bore_all;
  logic DataStorage_3__boreChildrenBd_bore_req;
  logic DataStorage_3__boreChildrenBd_bore_writeen;
  logic DataStorage_3__boreChildrenBd_bore_be;
  logic [12:0] DataStorage_3__boreChildrenBd_bore_addr;
  logic [136:0] DataStorage_3__boreChildrenBd_bore_indata;
  logic DataStorage_3__boreChildrenBd_bore_readen;
  logic [12:0] DataStorage_3__boreChildrenBd_bore_addr_rd;
  logic DataStorage_3__sigFromSrams_bore_ram_hold;
  logic DataStorage_3__sigFromSrams_bore_ram_bypass;
  logic DataStorage_3__sigFromSrams_bore_ram_bp_clken;
  logic DataStorage_3__sigFromSrams_bore_ram_aux_clk;
  logic DataStorage_3__sigFromSrams_bore_ram_aux_ckbp;
  logic DataStorage_3__sigFromSrams_bore_ram_mcp_hold;
  logic DataStorage_3__sigFromSrams_bore_cgen;
  logic DataStorage_3__sigFromSrams_bore_1_ram_hold;
  logic DataStorage_3__sigFromSrams_bore_1_ram_bypass;
  logic DataStorage_3__sigFromSrams_bore_1_ram_bp_clken;
  logic DataStorage_3__sigFromSrams_bore_1_ram_aux_clk;
  logic DataStorage_3__sigFromSrams_bore_1_ram_aux_ckbp;
  logic DataStorage_3__sigFromSrams_bore_1_ram_mcp_hold;
  logic DataStorage_3__sigFromSrams_bore_1_cgen;
  logic DataStorage_3__sigFromSrams_bore_2_ram_hold;
  logic DataStorage_3__sigFromSrams_bore_2_ram_bypass;
  logic DataStorage_3__sigFromSrams_bore_2_ram_bp_clken;
  logic DataStorage_3__sigFromSrams_bore_2_ram_aux_clk;
  logic DataStorage_3__sigFromSrams_bore_2_ram_aux_ckbp;
  logic DataStorage_3__sigFromSrams_bore_2_ram_mcp_hold;
  logic DataStorage_3__sigFromSrams_bore_2_cgen;
  logic DataStorage_3__sigFromSrams_bore_3_ram_hold;
  logic DataStorage_3__sigFromSrams_bore_3_ram_bypass;
  logic DataStorage_3__sigFromSrams_bore_3_ram_bp_clken;
  logic DataStorage_3__sigFromSrams_bore_3_ram_aux_clk;
  logic DataStorage_3__sigFromSrams_bore_3_ram_aux_ckbp;
  logic DataStorage_3__sigFromSrams_bore_3_ram_mcp_hold;
  logic DataStorage_3__sigFromSrams_bore_3_cgen;
  wire  g_DataStorage_3__io_error;
  wire  i_DataStorage_3__io_error;
  logic p_DataStorage_3__io_error;
  bit   t_DataStorage_3__io_error;
  wire  [511:0] g_DataStorage_3__io_rdata_data;
  wire  [511:0] i_DataStorage_3__io_rdata_data;
  logic [511:0] p_DataStorage_3__io_rdata_data;
  bit   t_DataStorage_3__io_rdata_data;
  wire  g_DataStorage_3__boreChildrenBd_bore_ack;
  wire  i_DataStorage_3__boreChildrenBd_bore_ack;
  logic p_DataStorage_3__boreChildrenBd_bore_ack;
  bit   t_DataStorage_3__boreChildrenBd_bore_ack;
  wire  [136:0] g_DataStorage_3__boreChildrenBd_bore_outdata;
  wire  [136:0] i_DataStorage_3__boreChildrenBd_bore_outdata;
  logic [136:0] p_DataStorage_3__boreChildrenBd_bore_outdata;
  bit   t_DataStorage_3__boreChildrenBd_bore_outdata;
  DataStorage_3 u_g_DataStorage_3 (
    .clock (clock),
    .reset (reset),
    .io_en (DataStorage_3__io_en),
    .io_error (g_DataStorage_3__io_error),
    .io_req_valid (DataStorage_3__io_req_valid),
    .io_req_bits_way (DataStorage_3__io_req_bits_way),
    .io_req_bits_set (DataStorage_3__io_req_bits_set),
    .io_req_bits_wen (DataStorage_3__io_req_bits_wen),
    .io_rdata_data (g_DataStorage_3__io_rdata_data),
    .io_wdata_data (DataStorage_3__io_wdata_data),
    .boreChildrenBd_bore_array (DataStorage_3__boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all (DataStorage_3__boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req (DataStorage_3__boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack (g_DataStorage_3__boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen (DataStorage_3__boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be (DataStorage_3__boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr (DataStorage_3__boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata (DataStorage_3__boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen (DataStorage_3__boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd (DataStorage_3__boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata (g_DataStorage_3__boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold (DataStorage_3__sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass (DataStorage_3__sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (DataStorage_3__sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk (DataStorage_3__sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (DataStorage_3__sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (DataStorage_3__sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen (DataStorage_3__sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold (DataStorage_3__sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass (DataStorage_3__sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (DataStorage_3__sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk (DataStorage_3__sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (DataStorage_3__sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (DataStorage_3__sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen (DataStorage_3__sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold (DataStorage_3__sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass (DataStorage_3__sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (DataStorage_3__sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk (DataStorage_3__sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (DataStorage_3__sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (DataStorage_3__sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen (DataStorage_3__sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold (DataStorage_3__sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass (DataStorage_3__sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (DataStorage_3__sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk (DataStorage_3__sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (DataStorage_3__sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (DataStorage_3__sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen (DataStorage_3__sigFromSrams_bore_3_cgen)
  );
  DataStorage_3_xs u_i_DataStorage_3 (
    .clock (clock),
    .reset (reset),
    .io_en (DataStorage_3__io_en),
    .io_error (i_DataStorage_3__io_error),
    .io_req_valid (DataStorage_3__io_req_valid),
    .io_req_bits_way (DataStorage_3__io_req_bits_way),
    .io_req_bits_set (DataStorage_3__io_req_bits_set),
    .io_req_bits_wen (DataStorage_3__io_req_bits_wen),
    .io_rdata_data (i_DataStorage_3__io_rdata_data),
    .io_wdata_data (DataStorage_3__io_wdata_data),
    .boreChildrenBd_bore_array (DataStorage_3__boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all (DataStorage_3__boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req (DataStorage_3__boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack (i_DataStorage_3__boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen (DataStorage_3__boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be (DataStorage_3__boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr (DataStorage_3__boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata (DataStorage_3__boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen (DataStorage_3__boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd (DataStorage_3__boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata (i_DataStorage_3__boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold (DataStorage_3__sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass (DataStorage_3__sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (DataStorage_3__sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk (DataStorage_3__sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (DataStorage_3__sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (DataStorage_3__sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen (DataStorage_3__sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold (DataStorage_3__sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass (DataStorage_3__sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (DataStorage_3__sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk (DataStorage_3__sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (DataStorage_3__sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (DataStorage_3__sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen (DataStorage_3__sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold (DataStorage_3__sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass (DataStorage_3__sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (DataStorage_3__sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk (DataStorage_3__sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (DataStorage_3__sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (DataStorage_3__sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen (DataStorage_3__sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold (DataStorage_3__sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass (DataStorage_3__sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (DataStorage_3__sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk (DataStorage_3__sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (DataStorage_3__sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (DataStorage_3__sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen (DataStorage_3__sigFromSrams_bore_3_cgen)
  );
  task automatic drive_DataStorage_3();
    DataStorage_3__io_en = $urandom % 2;
    DataStorage_3__io_req_valid = $urandom % 2;
    DataStorage_3__io_req_bits_way = 3'($urandom_range(0, 1));
    DataStorage_3__io_req_bits_set = 9'($urandom_range(0, 3));
    DataStorage_3__io_req_bits_wen = $urandom % 2;
    DataStorage_3__io_wdata_data = rnd(512);
    DataStorage_3__boreChildrenBd_bore_array = rnd(6);
    DataStorage_3__boreChildrenBd_bore_all = $urandom % 2;
    DataStorage_3__boreChildrenBd_bore_req = $urandom % 2;
    DataStorage_3__boreChildrenBd_bore_writeen = $urandom % 2;
    DataStorage_3__boreChildrenBd_bore_be = $urandom % 2;
    DataStorage_3__boreChildrenBd_bore_addr = rnd(13);
    DataStorage_3__boreChildrenBd_bore_indata = rnd(137);
    DataStorage_3__boreChildrenBd_bore_readen = $urandom % 2;
    DataStorage_3__boreChildrenBd_bore_addr_rd = rnd(13);
    DataStorage_3__sigFromSrams_bore_ram_hold = $urandom % 2;
    DataStorage_3__sigFromSrams_bore_ram_bypass = $urandom % 2;
    DataStorage_3__sigFromSrams_bore_ram_bp_clken = $urandom % 2;
    DataStorage_3__sigFromSrams_bore_ram_aux_clk = 1'b0;
    DataStorage_3__sigFromSrams_bore_ram_aux_ckbp = 1'b0;
    DataStorage_3__sigFromSrams_bore_ram_mcp_hold = $urandom % 2;
    DataStorage_3__sigFromSrams_bore_cgen = $urandom % 2;
    DataStorage_3__sigFromSrams_bore_1_ram_hold = $urandom % 2;
    DataStorage_3__sigFromSrams_bore_1_ram_bypass = $urandom % 2;
    DataStorage_3__sigFromSrams_bore_1_ram_bp_clken = $urandom % 2;
    DataStorage_3__sigFromSrams_bore_1_ram_aux_clk = 1'b0;
    DataStorage_3__sigFromSrams_bore_1_ram_aux_ckbp = 1'b0;
    DataStorage_3__sigFromSrams_bore_1_ram_mcp_hold = $urandom % 2;
    DataStorage_3__sigFromSrams_bore_1_cgen = $urandom % 2;
    DataStorage_3__sigFromSrams_bore_2_ram_hold = $urandom % 2;
    DataStorage_3__sigFromSrams_bore_2_ram_bypass = $urandom % 2;
    DataStorage_3__sigFromSrams_bore_2_ram_bp_clken = $urandom % 2;
    DataStorage_3__sigFromSrams_bore_2_ram_aux_clk = 1'b0;
    DataStorage_3__sigFromSrams_bore_2_ram_aux_ckbp = 1'b0;
    DataStorage_3__sigFromSrams_bore_2_ram_mcp_hold = $urandom % 2;
    DataStorage_3__sigFromSrams_bore_2_cgen = $urandom % 2;
    DataStorage_3__sigFromSrams_bore_3_ram_hold = $urandom % 2;
    DataStorage_3__sigFromSrams_bore_3_ram_bypass = $urandom % 2;
    DataStorage_3__sigFromSrams_bore_3_ram_bp_clken = $urandom % 2;
    DataStorage_3__sigFromSrams_bore_3_ram_aux_clk = 1'b0;
    DataStorage_3__sigFromSrams_bore_3_ram_aux_ckbp = 1'b0;
    DataStorage_3__sigFromSrams_bore_3_ram_mcp_hold = $urandom % 2;
    DataStorage_3__sigFromSrams_bore_3_cgen = $urandom % 2;
  endtask
  task automatic check_DataStorage_3();
    checks++;
    if (g_DataStorage_3__io_error !== i_DataStorage_3__io_error) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH DataStorage_3.io_error g=%h i=%h", cyc, g_DataStorage_3__io_error, i_DataStorage_3__io_error);
    end
    if (g_DataStorage_3__io_error !== p_DataStorage_3__io_error) t_DataStorage_3__io_error = 1'b1;
    p_DataStorage_3__io_error = g_DataStorage_3__io_error;
    checks++;
    if (g_DataStorage_3__io_rdata_data !== i_DataStorage_3__io_rdata_data) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH DataStorage_3.io_rdata_data g=%h i=%h", cyc, g_DataStorage_3__io_rdata_data, i_DataStorage_3__io_rdata_data);
    end
    if (g_DataStorage_3__io_rdata_data !== p_DataStorage_3__io_rdata_data) t_DataStorage_3__io_rdata_data = 1'b1;
    p_DataStorage_3__io_rdata_data = g_DataStorage_3__io_rdata_data;
    checks++;
    if (g_DataStorage_3__boreChildrenBd_bore_ack !== i_DataStorage_3__boreChildrenBd_bore_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH DataStorage_3.boreChildrenBd_bore_ack g=%h i=%h", cyc, g_DataStorage_3__boreChildrenBd_bore_ack, i_DataStorage_3__boreChildrenBd_bore_ack);
    end
    if (g_DataStorage_3__boreChildrenBd_bore_ack !== p_DataStorage_3__boreChildrenBd_bore_ack) t_DataStorage_3__boreChildrenBd_bore_ack = 1'b1;
    p_DataStorage_3__boreChildrenBd_bore_ack = g_DataStorage_3__boreChildrenBd_bore_ack;
    checks++;
    if (g_DataStorage_3__boreChildrenBd_bore_outdata !== i_DataStorage_3__boreChildrenBd_bore_outdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH DataStorage_3.boreChildrenBd_bore_outdata g=%h i=%h", cyc, g_DataStorage_3__boreChildrenBd_bore_outdata, i_DataStorage_3__boreChildrenBd_bore_outdata);
    end
    if (g_DataStorage_3__boreChildrenBd_bore_outdata !== p_DataStorage_3__boreChildrenBd_bore_outdata) t_DataStorage_3__boreChildrenBd_bore_outdata = 1'b1;
    p_DataStorage_3__boreChildrenBd_bore_outdata = g_DataStorage_3__boreChildrenBd_bore_outdata;
  endtask
  longint cov_DataStorage_3_rd = 0;
  longint cov_DataStorage_3_err = 0;
  longint cov_DataStorage_3_wr = 0;
  task automatic cover_DataStorage_3();
    if (u_g_DataStorage_3.error_REG_1) cov_DataStorage_3_rd++;
    if (u_g_DataStorage_3.io_error) cov_DataStorage_3_err++;
    if (u_g_DataStorage_3.io_req_valid && u_g_DataStorage_3.io_req_bits_wen) cov_DataStorage_3_wr++;
  endtask
  task automatic preinit_DataStorage_3();
  endtask
  task automatic sync_DataStorage_3();
    u_i_DataStorage_3.array.array_0_0_0.array.array.array_18_ext.ram = u_g_DataStorage_3.array.array_0_0_0.array.array.array_18_ext.ram;
    u_i_DataStorage_3.array.array_0_0_0.array.array.array_18_ext.reg_RW0_addr = u_g_DataStorage_3.array.array_0_0_0.array.array.array_18_ext.reg_RW0_addr;
    u_i_DataStorage_3.array.array_0_0_0.array.array.array_18_ext.reg_RW0_ren = u_g_DataStorage_3.array.array_0_0_0.array.array.array_18_ext.reg_RW0_ren;
    force u_i_DataStorage_3.array.array_0_0_0.u_core.rdataReg = u_g_DataStorage_3.array.array_0_0_0.rdataReg;
    #0 release u_i_DataStorage_3.array.array_0_0_0.u_core.rdataReg;
    u_i_DataStorage_3.array.array_0_0_1.array.array.array_18_ext.ram = u_g_DataStorage_3.array.array_0_0_1.array.array.array_18_ext.ram;
    u_i_DataStorage_3.array.array_0_0_1.array.array.array_18_ext.reg_RW0_addr = u_g_DataStorage_3.array.array_0_0_1.array.array.array_18_ext.reg_RW0_addr;
    u_i_DataStorage_3.array.array_0_0_1.array.array.array_18_ext.reg_RW0_ren = u_g_DataStorage_3.array.array_0_0_1.array.array.array_18_ext.reg_RW0_ren;
    force u_i_DataStorage_3.array.array_0_0_1.u_core.rdataReg = u_g_DataStorage_3.array.array_0_0_1.rdataReg;
    #0 release u_i_DataStorage_3.array.array_0_0_1.u_core.rdataReg;
    u_i_DataStorage_3.array.array_0_0_2.array.array.array_18_ext.ram = u_g_DataStorage_3.array.array_0_0_2.array.array.array_18_ext.ram;
    u_i_DataStorage_3.array.array_0_0_2.array.array.array_18_ext.reg_RW0_addr = u_g_DataStorage_3.array.array_0_0_2.array.array.array_18_ext.reg_RW0_addr;
    u_i_DataStorage_3.array.array_0_0_2.array.array.array_18_ext.reg_RW0_ren = u_g_DataStorage_3.array.array_0_0_2.array.array.array_18_ext.reg_RW0_ren;
    force u_i_DataStorage_3.array.array_0_0_2.u_core.rdataReg = u_g_DataStorage_3.array.array_0_0_2.rdataReg;
    #0 release u_i_DataStorage_3.array.array_0_0_2.u_core.rdataReg;
    u_i_DataStorage_3.array.array_0_0_3.array.array.array_18_ext.ram = u_g_DataStorage_3.array.array_0_0_3.array.array.array_18_ext.ram;
    u_i_DataStorage_3.array.array_0_0_3.array.array.array_18_ext.reg_RW0_addr = u_g_DataStorage_3.array.array_0_0_3.array.array.array_18_ext.reg_RW0_addr;
    u_i_DataStorage_3.array.array_0_0_3.array.array.array_18_ext.reg_RW0_ren = u_g_DataStorage_3.array.array_0_0_3.array.array.array_18_ext.reg_RW0_ren;
    force u_i_DataStorage_3.array.array_0_0_3.u_core.rdataReg = u_g_DataStorage_3.array.array_0_0_3.rdataReg;
    #0 release u_i_DataStorage_3.array.array_0_0_3.u_core.rdataReg;
    force u_i_DataStorage_3.u_core.error_REG = u_g_DataStorage_3.error_REG;
    #0 release u_i_DataStorage_3.u_core.error_REG;
    force u_i_DataStorage_3.u_core.error_REG_1 = u_g_DataStorage_3.error_REG_1;
    #0 release u_i_DataStorage_3.u_core.error_REG_1;
  endtask

  bit covfail = 0;
  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    reset = 1'b1;
    drive_DataStorage();
    drive_DataStorage_1();
    drive_DataStorage_2();
    drive_DataStorage_3();
    #1;
    preinit_DataStorage();
    preinit_DataStorage_1();
    preinit_DataStorage_2();
    preinit_DataStorage_3();
    sync_DataStorage();
    sync_DataStorage_1();
    sync_DataStorage_2();
    sync_DataStorage_3();
    repeat (5) @(posedge clock);
    @(negedge clock) reset = 1'b0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      if (reset) reset = 1'b0; else if (($urandom % 5000) == 0) reset = 1'b1;
      drive_DataStorage();
      drive_DataStorage_1();
      drive_DataStorage_2();
      drive_DataStorage_3();
      #1;
      check_DataStorage();
      cover_DataStorage();
      check_DataStorage_1();
      cover_DataStorage_1();
      check_DataStorage_2();
      cover_DataStorage_2();
      check_DataStorage_3();
      cover_DataStorage_3();
    end
    begin int tg; tg = 0;
      if (t_DataStorage__io_error) tg++; else $display("COV: DataStorage.io_error never toggled");
      if (t_DataStorage__io_rdata_data) tg++; else $display("COV: DataStorage.io_rdata_data never toggled");
      if (t_DataStorage__boreChildrenBd_bore_ack) tg++; else $display("COV: DataStorage.boreChildrenBd_bore_ack never toggled");
      if (t_DataStorage__boreChildrenBd_bore_outdata) tg++; else $display("COV: DataStorage.boreChildrenBd_bore_outdata never toggled");
      $display("DataStorage: toggled=%0d/4 (need >= 4)", tg);
      if (tg < 4) covfail = 1;
      $display("DataStorage: cover rd = %0d", cov_DataStorage_rd);
      if (cov_DataStorage_rd == 0) covfail = 1;
      $display("DataStorage: cover err = %0d", cov_DataStorage_err);
      if (cov_DataStorage_err == 0) covfail = 1;
      $display("DataStorage: cover wr = %0d", cov_DataStorage_wr);
      if (cov_DataStorage_wr == 0) covfail = 1;
    end
    begin int tg; tg = 0;
      if (t_DataStorage_1__io_error) tg++; else $display("COV: DataStorage_1.io_error never toggled");
      if (t_DataStorage_1__io_rdata_data) tg++; else $display("COV: DataStorage_1.io_rdata_data never toggled");
      if (t_DataStorage_1__boreChildrenBd_bore_ack) tg++; else $display("COV: DataStorage_1.boreChildrenBd_bore_ack never toggled");
      if (t_DataStorage_1__boreChildrenBd_bore_outdata) tg++; else $display("COV: DataStorage_1.boreChildrenBd_bore_outdata never toggled");
      $display("DataStorage_1: toggled=%0d/4 (need >= 4)", tg);
      if (tg < 4) covfail = 1;
      $display("DataStorage_1: cover rd = %0d", cov_DataStorage_1_rd);
      if (cov_DataStorage_1_rd == 0) covfail = 1;
      $display("DataStorage_1: cover err = %0d", cov_DataStorage_1_err);
      if (cov_DataStorage_1_err == 0) covfail = 1;
      $display("DataStorage_1: cover wr = %0d", cov_DataStorage_1_wr);
      if (cov_DataStorage_1_wr == 0) covfail = 1;
    end
    begin int tg; tg = 0;
      if (t_DataStorage_2__io_error) tg++; else $display("COV: DataStorage_2.io_error never toggled");
      if (t_DataStorage_2__io_rdata_data) tg++; else $display("COV: DataStorage_2.io_rdata_data never toggled");
      if (t_DataStorage_2__boreChildrenBd_bore_ack) tg++; else $display("COV: DataStorage_2.boreChildrenBd_bore_ack never toggled");
      if (t_DataStorage_2__boreChildrenBd_bore_outdata) tg++; else $display("COV: DataStorage_2.boreChildrenBd_bore_outdata never toggled");
      $display("DataStorage_2: toggled=%0d/4 (need >= 4)", tg);
      if (tg < 4) covfail = 1;
      $display("DataStorage_2: cover rd = %0d", cov_DataStorage_2_rd);
      if (cov_DataStorage_2_rd == 0) covfail = 1;
      $display("DataStorage_2: cover err = %0d", cov_DataStorage_2_err);
      if (cov_DataStorage_2_err == 0) covfail = 1;
      $display("DataStorage_2: cover wr = %0d", cov_DataStorage_2_wr);
      if (cov_DataStorage_2_wr == 0) covfail = 1;
    end
    begin int tg; tg = 0;
      if (t_DataStorage_3__io_error) tg++; else $display("COV: DataStorage_3.io_error never toggled");
      if (t_DataStorage_3__io_rdata_data) tg++; else $display("COV: DataStorage_3.io_rdata_data never toggled");
      if (t_DataStorage_3__boreChildrenBd_bore_ack) tg++; else $display("COV: DataStorage_3.boreChildrenBd_bore_ack never toggled");
      if (t_DataStorage_3__boreChildrenBd_bore_outdata) tg++; else $display("COV: DataStorage_3.boreChildrenBd_bore_outdata never toggled");
      $display("DataStorage_3: toggled=%0d/4 (need >= 4)", tg);
      if (tg < 4) covfail = 1;
      $display("DataStorage_3: cover rd = %0d", cov_DataStorage_3_rd);
      if (cov_DataStorage_3_rd == 0) covfail = 1;
      $display("DataStorage_3: cover err = %0d", cov_DataStorage_3_err);
      if (cov_DataStorage_3_err == 0) covfail = 1;
      $display("DataStorage_3: cover wr = %0d", cov_DataStorage_3_wr);
      if (cov_DataStorage_3_wr == 0) covfail = 1;
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0 || covfail) begin $display("TEST FAILED (coverage)"); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
