// 自动生成：gen_tb.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
  int unsigned WARMUP  = 8;   // 跳过复位后未稳定的若干拍
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic io_spec_push_valid;
  logic io_spec_pop_valid;
  logic [49:0] io_spec_push_addr;
  logic io_s2_fire;
  logic io_s3_fire;
  logic io_s3_cancel;
  logic [3:0] io_s3_meta_ssp;
  logic [2:0] io_s3_meta_sctr;
  logic io_s3_meta_TOSW_flag;
  logic [4:0] io_s3_meta_TOSW_value;
  logic io_s3_meta_TOSR_flag;
  logic [4:0] io_s3_meta_TOSR_value;
  logic io_s3_meta_NOS_flag;
  logic [4:0] io_s3_meta_NOS_value;
  logic io_s3_missed_pop;
  logic io_s3_missed_push;
  logic [49:0] io_s3_pushAddr;
  logic io_commit_valid;
  logic io_commit_push_valid;
  logic io_commit_pop_valid;
  logic io_commit_meta_TOSW_flag;
  logic [4:0] io_commit_meta_TOSW_value;
  logic [3:0] io_commit_meta_ssp;
  logic io_redirect_valid;
  logic io_redirect_isCall;
  logic io_redirect_isRet;
  logic [3:0] io_redirect_meta_ssp;
  logic [2:0] io_redirect_meta_sctr;
  logic io_redirect_meta_TOSW_flag;
  logic [4:0] io_redirect_meta_TOSW_value;
  logic io_redirect_meta_TOSR_flag;
  logic [4:0] io_redirect_meta_TOSR_value;
  logic io_redirect_meta_NOS_flag;
  logic [4:0] io_redirect_meta_NOS_value;
  logic [49:0] io_redirect_callAddr;
  wire [49:0] g_io_spec_pop_addr;
  wire [49:0] i_io_spec_pop_addr;
  wire [3:0] g_io_ssp;
  wire [3:0] i_io_ssp;
  wire [2:0] g_io_sctr;
  wire [2:0] i_io_sctr;
  wire g_io_TOSR_flag;
  wire i_io_TOSR_flag;
  wire [4:0] g_io_TOSR_value;
  wire [4:0] i_io_TOSR_value;
  wire g_io_TOSW_flag;
  wire i_io_TOSW_flag;
  wire [4:0] g_io_TOSW_value;
  wire [4:0] i_io_TOSW_value;
  wire g_io_NOS_flag;
  wire i_io_NOS_flag;
  wire [4:0] g_io_NOS_value;
  wire [4:0] i_io_NOS_value;
  wire g_io_spec_near_overflow;
  wire i_io_spec_near_overflow;

  RASStack    u_g (.clock(clk), .reset(rst), .io_spec_push_valid(io_spec_push_valid), .io_spec_pop_valid(io_spec_pop_valid), .io_spec_push_addr(io_spec_push_addr), .io_s2_fire(io_s2_fire), .io_s3_fire(io_s3_fire), .io_s3_cancel(io_s3_cancel), .io_s3_meta_ssp(io_s3_meta_ssp), .io_s3_meta_sctr(io_s3_meta_sctr), .io_s3_meta_TOSW_flag(io_s3_meta_TOSW_flag), .io_s3_meta_TOSW_value(io_s3_meta_TOSW_value), .io_s3_meta_TOSR_flag(io_s3_meta_TOSR_flag), .io_s3_meta_TOSR_value(io_s3_meta_TOSR_value), .io_s3_meta_NOS_flag(io_s3_meta_NOS_flag), .io_s3_meta_NOS_value(io_s3_meta_NOS_value), .io_s3_missed_pop(io_s3_missed_pop), .io_s3_missed_push(io_s3_missed_push), .io_s3_pushAddr(io_s3_pushAddr), .io_commit_valid(io_commit_valid), .io_commit_push_valid(io_commit_push_valid), .io_commit_pop_valid(io_commit_pop_valid), .io_commit_meta_TOSW_flag(io_commit_meta_TOSW_flag), .io_commit_meta_TOSW_value(io_commit_meta_TOSW_value), .io_commit_meta_ssp(io_commit_meta_ssp), .io_redirect_valid(io_redirect_valid), .io_redirect_isCall(io_redirect_isCall), .io_redirect_isRet(io_redirect_isRet), .io_redirect_meta_ssp(io_redirect_meta_ssp), .io_redirect_meta_sctr(io_redirect_meta_sctr), .io_redirect_meta_TOSW_flag(io_redirect_meta_TOSW_flag), .io_redirect_meta_TOSW_value(io_redirect_meta_TOSW_value), .io_redirect_meta_TOSR_flag(io_redirect_meta_TOSR_flag), .io_redirect_meta_TOSR_value(io_redirect_meta_TOSR_value), .io_redirect_meta_NOS_flag(io_redirect_meta_NOS_flag), .io_redirect_meta_NOS_value(io_redirect_meta_NOS_value), .io_redirect_callAddr(io_redirect_callAddr), .io_spec_pop_addr(g_io_spec_pop_addr), .io_ssp(g_io_ssp), .io_sctr(g_io_sctr), .io_TOSR_flag(g_io_TOSR_flag), .io_TOSR_value(g_io_TOSR_value), .io_TOSW_flag(g_io_TOSW_flag), .io_TOSW_value(g_io_TOSW_value), .io_NOS_flag(g_io_NOS_flag), .io_NOS_value(g_io_NOS_value), .io_spec_near_overflow(g_io_spec_near_overflow));
  RASStack_xs u_i (.clock(clk), .reset(rst), .io_spec_push_valid(io_spec_push_valid), .io_spec_pop_valid(io_spec_pop_valid), .io_spec_push_addr(io_spec_push_addr), .io_s2_fire(io_s2_fire), .io_s3_fire(io_s3_fire), .io_s3_cancel(io_s3_cancel), .io_s3_meta_ssp(io_s3_meta_ssp), .io_s3_meta_sctr(io_s3_meta_sctr), .io_s3_meta_TOSW_flag(io_s3_meta_TOSW_flag), .io_s3_meta_TOSW_value(io_s3_meta_TOSW_value), .io_s3_meta_TOSR_flag(io_s3_meta_TOSR_flag), .io_s3_meta_TOSR_value(io_s3_meta_TOSR_value), .io_s3_meta_NOS_flag(io_s3_meta_NOS_flag), .io_s3_meta_NOS_value(io_s3_meta_NOS_value), .io_s3_missed_pop(io_s3_missed_pop), .io_s3_missed_push(io_s3_missed_push), .io_s3_pushAddr(io_s3_pushAddr), .io_commit_valid(io_commit_valid), .io_commit_push_valid(io_commit_push_valid), .io_commit_pop_valid(io_commit_pop_valid), .io_commit_meta_TOSW_flag(io_commit_meta_TOSW_flag), .io_commit_meta_TOSW_value(io_commit_meta_TOSW_value), .io_commit_meta_ssp(io_commit_meta_ssp), .io_redirect_valid(io_redirect_valid), .io_redirect_isCall(io_redirect_isCall), .io_redirect_isRet(io_redirect_isRet), .io_redirect_meta_ssp(io_redirect_meta_ssp), .io_redirect_meta_sctr(io_redirect_meta_sctr), .io_redirect_meta_TOSW_flag(io_redirect_meta_TOSW_flag), .io_redirect_meta_TOSW_value(io_redirect_meta_TOSW_value), .io_redirect_meta_TOSR_flag(io_redirect_meta_TOSR_flag), .io_redirect_meta_TOSR_value(io_redirect_meta_TOSR_value), .io_redirect_meta_NOS_flag(io_redirect_meta_NOS_flag), .io_redirect_meta_NOS_value(io_redirect_meta_NOS_value), .io_redirect_callAddr(io_redirect_callAddr), .io_spec_pop_addr(i_io_spec_pop_addr), .io_ssp(i_io_ssp), .io_sctr(i_io_sctr), .io_TOSR_flag(i_io_TOSR_flag), .io_TOSR_value(i_io_TOSR_value), .io_TOSW_flag(i_io_TOSW_flag), .io_TOSW_value(i_io_TOSW_value), .io_NOS_flag(i_io_NOS_flag), .io_NOS_value(i_io_NOS_value), .io_spec_near_overflow(i_io_spec_near_overflow));

  // 随机激励：指针类输入约束到小范围，使 meta 合理（ssp/nsp<16, ptr value<32）
  always @(negedge clk) begin
    if (rst) begin
      io_spec_push_valid <= '0;
      io_spec_pop_valid <= '0;
      io_spec_push_addr <= '0;
      io_s2_fire <= '0;
      io_s3_fire <= '0;
      io_s3_cancel <= '0;
      io_s3_meta_ssp <= '0;
      io_s3_meta_sctr <= '0;
      io_s3_meta_TOSW_flag <= '0;
      io_s3_meta_TOSW_value <= '0;
      io_s3_meta_TOSR_flag <= '0;
      io_s3_meta_TOSR_value <= '0;
      io_s3_meta_NOS_flag <= '0;
      io_s3_meta_NOS_value <= '0;
      io_s3_missed_pop <= '0;
      io_s3_missed_push <= '0;
      io_s3_pushAddr <= '0;
      io_commit_valid <= '0;
      io_commit_push_valid <= '0;
      io_commit_pop_valid <= '0;
      io_commit_meta_TOSW_flag <= '0;
      io_commit_meta_TOSW_value <= '0;
      io_commit_meta_ssp <= '0;
      io_redirect_valid <= '0;
      io_redirect_isCall <= '0;
      io_redirect_isRet <= '0;
      io_redirect_meta_ssp <= '0;
      io_redirect_meta_sctr <= '0;
      io_redirect_meta_TOSW_flag <= '0;
      io_redirect_meta_TOSW_value <= '0;
      io_redirect_meta_TOSR_flag <= '0;
      io_redirect_meta_TOSR_value <= '0;
      io_redirect_meta_NOS_flag <= '0;
      io_redirect_meta_NOS_value <= '0;
      io_redirect_callAddr <= '0;
    end else begin
      io_spec_push_valid <= ($urandom_range(0,2)==0);
      io_spec_pop_valid <= ($urandom_range(0,2)==0);
      io_spec_push_addr <= 50'($urandom_range(0,15));
      io_s2_fire <= ($urandom_range(0,1)==0);
      io_s3_fire <= ($urandom_range(0,1)==0);
      io_s3_cancel <= ($urandom_range(0,4)==0);
      io_s3_meta_ssp <= 4'($urandom_range(0,15));
      io_s3_meta_sctr <= 3'($urandom_range(0,7));
      io_s3_meta_TOSW_flag <= 1'($urandom);
      io_s3_meta_TOSW_value <= 5'($urandom_range(0,31));
      io_s3_meta_TOSR_flag <= 1'($urandom);
      io_s3_meta_TOSR_value <= 5'($urandom_range(0,31));
      io_s3_meta_NOS_flag <= 1'($urandom);
      io_s3_meta_NOS_value <= 5'($urandom_range(0,31));
      io_s3_missed_pop <= ($urandom_range(0,3)==0);
      io_s3_missed_push <= ($urandom_range(0,3)==0);
      io_s3_pushAddr <= 50'($urandom_range(0,15));
      io_commit_valid <= ($urandom_range(0,1)==0);
      io_commit_push_valid <= ($urandom_range(0,3)==0);
      io_commit_pop_valid <= ($urandom_range(0,3)==0);
      io_commit_meta_TOSW_flag <= 1'($urandom);
      io_commit_meta_TOSW_value <= 5'($urandom_range(0,31));
      io_commit_meta_ssp <= 4'($urandom_range(0,15));
      io_redirect_valid <= ($urandom_range(0,6)==0);
      io_redirect_isCall <= ($urandom_range(0,2)==0);
      io_redirect_isRet <= ($urandom_range(0,2)==0);
      io_redirect_meta_ssp <= 4'($urandom_range(0,15));
      io_redirect_meta_sctr <= 3'($urandom_range(0,7));
      io_redirect_meta_TOSW_flag <= 1'($urandom);
      io_redirect_meta_TOSW_value <= 5'($urandom_range(0,31));
      io_redirect_meta_TOSR_flag <= 1'($urandom);
      io_redirect_meta_TOSR_value <= 5'($urandom_range(0,31));
      io_redirect_meta_NOS_flag <= 1'($urandom);
      io_redirect_meta_NOS_value <= 5'($urandom_range(0,31));
      io_redirect_callAddr <= 50'($urandom_range(0,15));
    end
  end

  always @(negedge clk) if (!rst) begin
    cyc++;
    if (cyc > WARMUP) begin
      #4; checks++;
      if (g_io_spec_pop_addr !== i_io_spec_pop_addr) begin errors++;
        if(errors<=30) $display("[%0t] io_spec_pop_addr g=%h i=%h", $time, g_io_spec_pop_addr, i_io_spec_pop_addr); end
      if (g_io_ssp !== i_io_ssp) begin errors++;
        if(errors<=30) $display("[%0t] io_ssp g=%h i=%h", $time, g_io_ssp, i_io_ssp); end
      if (g_io_sctr !== i_io_sctr) begin errors++;
        if(errors<=30) $display("[%0t] io_sctr g=%h i=%h", $time, g_io_sctr, i_io_sctr); end
      if (g_io_TOSR_flag !== i_io_TOSR_flag) begin errors++;
        if(errors<=30) $display("[%0t] io_TOSR_flag g=%h i=%h", $time, g_io_TOSR_flag, i_io_TOSR_flag); end
      if (g_io_TOSR_value !== i_io_TOSR_value) begin errors++;
        if(errors<=30) $display("[%0t] io_TOSR_value g=%h i=%h", $time, g_io_TOSR_value, i_io_TOSR_value); end
      if (g_io_TOSW_flag !== i_io_TOSW_flag) begin errors++;
        if(errors<=30) $display("[%0t] io_TOSW_flag g=%h i=%h", $time, g_io_TOSW_flag, i_io_TOSW_flag); end
      if (g_io_TOSW_value !== i_io_TOSW_value) begin errors++;
        if(errors<=30) $display("[%0t] io_TOSW_value g=%h i=%h", $time, g_io_TOSW_value, i_io_TOSW_value); end
      if (g_io_NOS_flag !== i_io_NOS_flag) begin errors++;
        if(errors<=30) $display("[%0t] io_NOS_flag g=%h i=%h", $time, g_io_NOS_flag, i_io_NOS_flag); end
      if (g_io_NOS_value !== i_io_NOS_value) begin errors++;
        if(errors<=30) $display("[%0t] io_NOS_value g=%h i=%h", $time, g_io_NOS_value, i_io_NOS_value); end
      if (g_io_spec_near_overflow !== i_io_spec_near_overflow) begin errors++;
        if(errors<=30) $display("[%0t] io_spec_near_overflow g=%h i=%h", $time, g_io_spec_near_overflow, i_io_spec_near_overflow); end
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
