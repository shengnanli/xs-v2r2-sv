// InstrMMIOEntry UT：golden vs _xs 双例化，随机驱动 FSM 各通道，逐拍比对所有输出
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
  bit clk=0, rst; int errors=0, checks=0; int unsigned cyc=0;
  always #5 clk=~clk;
  always @(posedge clk) cyc++;
  logic        req_valid, acq_ready, grant_valid, grant_corrupt, wfiReq;
  logic [47:0] req_addr;
  logic [63:0] grant_data;
  wire g_req_rdy,g_resp_v,g_resp_c,g_acq_v,g_wfis; wire [31:0] g_resp_d; wire [47:0] g_acq_a;
  wire i_req_rdy,i_resp_v,i_resp_c,i_acq_v,i_wfis; wire [31:0] i_resp_d; wire [47:0] i_acq_a;
  `define P(RR,RV,RD,RC,AV,AA,WS) \
    .clock(clk),.reset(rst),.io_req_ready(RR),.io_req_valid(req_valid),.io_req_bits_addr(req_addr), \
    .io_resp_valid(RV),.io_resp_bits_data(RD),.io_resp_bits_corrupt(RC), \
    .io_mmio_acquire_ready(acq_ready),.io_mmio_acquire_valid(AV),.io_mmio_acquire_bits_address(AA), \
    .io_mmio_grant_valid(grant_valid),.io_mmio_grant_bits_data(grant_data),.io_mmio_grant_bits_corrupt(grant_corrupt), \
    .io_wfi_wfiReq(wfiReq),.io_wfi_wfiSafe(WS)
  InstrMMIOEntry    u_g (`P(g_req_rdy,g_resp_v,g_resp_d,g_resp_c,g_acq_v,g_acq_a,g_wfis));
  InstrMMIOEntry_xs u_i (`P(i_req_rdy,i_resp_v,i_resp_d,i_resp_c,i_acq_v,i_acq_a,i_wfis));
  always @(negedge clk) begin
    if (rst) begin req_valid<=0; acq_ready<=0; grant_valid<=0; wfiReq<=0; end
    else begin
      req_valid<=($urandom_range(0,1)); req_addr<=48'($urandom);
      acq_ready<=($urandom_range(0,1)); grant_valid<=($urandom_range(0,1));
      grant_data<={$urandom,$urandom}; grant_corrupt<=$urandom; wfiReq<=($urandom_range(0,7)==0);
    end
  end
  always @(negedge clk) if(!rst && cyc>20) begin
    #4; checks++;
    if ({g_req_rdy,g_resp_v,g_resp_d,g_resp_c,g_acq_v,g_acq_a,g_wfis} !==
        {i_req_rdy,i_resp_v,i_resp_d,i_resp_c,i_acq_v,i_acq_a,i_wfis}) begin
      errors++; if(errors<=20) $display("[%0t] mismatch g_rdy=%b resp=%b/%h/%b acq=%b/%h wfis=%b | i_rdy=%b resp=%b/%h/%b acq=%b/%h wfis=%b",
        $time,g_req_rdy,g_resp_v,g_resp_d,g_resp_c,g_acq_v,g_acq_a,g_wfis,i_req_rdy,i_resp_v,i_resp_d,i_resp_c,i_acq_v,i_acq_a,i_wfis);
    end
  end
  initial begin rst=1; repeat(5)@(posedge clk); rst=0; repeat(NCYCLES)@(posedge clk);
    $display("checks=%0d errors=%0d",checks,errors);
    if(errors==0 && checks>1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish; end
endmodule
