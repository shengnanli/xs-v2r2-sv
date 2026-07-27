`timescale 1ns/1ps
// MemCtrl 无输出端口, 逻辑=7 个更新流水寄存器。tb 用层次引用比对 golden(u_g)与
// 可读核(u_i.u_core)的这 7 个寄存器逐拍一致。
module tb;
  int unsigned NCYCLES = 200000;
  int unsigned WARMUP  = 8;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic [4:0] io_csrCtrl_lvpred_timeout;
  logic       io_memPredUpdate_valid;
  logic [9:0] io_memPredUpdate_waddr, io_memPredUpdate_ldpc, io_memPredUpdate_stpc;
  logic       io_mdpFoldPcVecVld_0, io_mdpFoldPcVecVld_1;
  logic [9:0] io_mdpFlodPcVec_0, io_mdpFlodPcVec_1;

  MemCtrl u_g (
    .clock(clk), .reset(rst),
    .io_csrCtrl_lvpred_timeout(io_csrCtrl_lvpred_timeout),
    .io_memPredUpdate_valid(io_memPredUpdate_valid),
    .io_memPredUpdate_waddr(io_memPredUpdate_waddr),
    .io_memPredUpdate_ldpc(io_memPredUpdate_ldpc),
    .io_memPredUpdate_stpc(io_memPredUpdate_stpc),
    .io_mdpFoldPcVecVld_0(io_mdpFoldPcVecVld_0),
    .io_mdpFoldPcVecVld_1(io_mdpFoldPcVecVld_1),
    .io_mdpFlodPcVec_0(io_mdpFlodPcVec_0),
    .io_mdpFlodPcVec_1(io_mdpFlodPcVec_1)
  );

  MemCtrl_xs u_i (
    .clock(clk), .reset(rst),
    .io_csrCtrl_lvpred_timeout(io_csrCtrl_lvpred_timeout),
    .io_memPredUpdate_valid(io_memPredUpdate_valid),
    .io_memPredUpdate_waddr(io_memPredUpdate_waddr),
    .io_memPredUpdate_ldpc(io_memPredUpdate_ldpc),
    .io_memPredUpdate_stpc(io_memPredUpdate_stpc),
    .io_mdpFoldPcVecVld_0(io_mdpFoldPcVecVld_0),
    .io_mdpFoldPcVecVld_1(io_mdpFoldPcVecVld_1),
    .io_mdpFlodPcVec_0(io_mdpFlodPcVec_0),
    .io_mdpFlodPcVec_1(io_mdpFlodPcVec_1)
  );

  always @(negedge clk) begin
    if (rst) begin
      io_csrCtrl_lvpred_timeout <= '0;
      io_memPredUpdate_valid <= '0;
      io_memPredUpdate_waddr <= '0; io_memPredUpdate_ldpc <= '0; io_memPredUpdate_stpc <= '0;
      io_mdpFoldPcVecVld_0 <= '0; io_mdpFoldPcVecVld_1 <= '0;
      io_mdpFlodPcVec_0 <= '0; io_mdpFlodPcVec_1 <= '0;
    end else begin
      io_csrCtrl_lvpred_timeout <= 5'($urandom);
      io_memPredUpdate_valid <= ($urandom_range(0,1)==0);
      io_memPredUpdate_waddr <= 10'($urandom);
      io_memPredUpdate_ldpc  <= 10'($urandom);
      io_memPredUpdate_stpc  <= 10'($urandom);
      io_mdpFoldPcVecVld_0 <= ($urandom_range(0,1)==0);
      io_mdpFoldPcVecVld_1 <= ($urandom_range(0,1)==0);
      io_mdpFlodPcVec_0 <= 10'($urandom);
      io_mdpFlodPcVec_1 <= 10'($urandom);
    end
  end

  task automatic chk(input string nm, input logic [15:0] g, input logic [15:0] i);
    if (g !== i) begin errors++;
      if (errors<=30) $display("[%0t] %s g=%h i=%h", $time, nm, g, i); end
  endtask

  always @(negedge clk) if (!rst) begin
    cyc++;
    if (cyc > WARMUP) begin
      #4; checks++;
      chk("ssit_update_valid",   {15'b0,u_g.ssit_io_update_REG_valid},        {15'b0,u_i.u_core.ssit_update_REG_valid});
      chk("ssit_update_ldpc",    {6'b0,u_g.ssit_io_update_REG_ldpc},          {6'b0,u_i.u_core.ssit_update_REG_ldpc});
      chk("ssit_update_stpc",    {6'b0,u_g.ssit_io_update_REG_stpc},          {6'b0,u_i.u_core.ssit_update_REG_stpc});
      chk("wt_update_valid",     {15'b0,u_g.waittable_io_update_REG_valid},   {15'b0,u_i.u_core.waittable_update_REG_valid});
      chk("wt_update_waddr",     {6'b0,u_g.waittable_io_update_REG_waddr},    {6'b0,u_i.u_core.waittable_update_REG_waddr});
      chk("ssit_csr_timeout",    {11'b0,u_g.ssit_io_csrCtrl_REG_lvpred_timeout},      {11'b0,u_i.u_core.ssit_csrCtrl_REG_lvpred_timeout});
      chk("wt_csr_timeout",      {11'b0,u_g.waittable_io_csrCtrl_REG_lvpred_timeout}, {11'b0,u_i.u_core.waittable_csrCtrl_REG_lvpred_timeout});
    end
  end

  initial begin
    rst = 1; repeat (5) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
