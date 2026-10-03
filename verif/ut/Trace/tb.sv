// Trace UT —— golden Trace（含 golden TraceBuffer）与 Trace_xs（含 TraceBuffer_xs）双例化逐拍比对
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  int unsigned cyc = 0;
  int cov_block = 0, cov_stall = 0, cov_full3 = 0, cov_merge = 0;
  always #5 clk = ~clk;
  always @(negedge clk) if (!rst) cyc <= cyc + 1;

  logic enable, stall;
  logic v0; logic [5:0] idx0; logic [3:0] off0, ity0, ret0; logic ls0;
  logic v1; logic [5:0] idx1; logic [3:0] off1, ity1, ret1; logic ls1;
  logic v2; logic [5:0] idx2; logic [3:0] off2, ity2, ret2; logic ls2;
  logic v3; logic [5:0] idx3; logic [3:0] off3, ity3, ret3; logic ls3;
  logic v4; logic [5:0] idx4; logic [3:0] off4, ity4, ret4; logic ls4;
  logic v5; logic [5:0] idx5; logic [3:0] off5, ity5, ret5; logic ls5;
  logic v6; logic [5:0] idx6; logic [3:0] off6, ity6, ret6; logic ls6;
  logic v7; logic [5:0] idx7; logic [3:0] off7, ity7, ret7; logic ls7;
  logic g_toPcMem_blocks_0_valid, i_toPcMem_blocks_0_valid;
  logic [5:0] g_toPcMem_blocks_0_bits_ftqIdx_value, i_toPcMem_blocks_0_bits_ftqIdx_value;
  logic g_toPcMem_blocks_1_valid, i_toPcMem_blocks_1_valid;
  logic [5:0] g_toPcMem_blocks_1_bits_ftqIdx_value, i_toPcMem_blocks_1_bits_ftqIdx_value;
  logic g_toPcMem_blocks_2_valid, i_toPcMem_blocks_2_valid;
  logic [5:0] g_toPcMem_blocks_2_bits_ftqIdx_value, i_toPcMem_blocks_2_bits_ftqIdx_value;
  logic g_toEncoder_blocks_0_valid, i_toEncoder_blocks_0_valid;
  logic [3:0] g_toEncoder_blocks_0_bits_ftqOffset, i_toEncoder_blocks_0_bits_ftqOffset;
  logic [3:0] g_toEncoder_blocks_0_bits_tracePipe_itype, i_toEncoder_blocks_0_bits_tracePipe_itype;
  logic [6:0] g_toEncoder_blocks_0_bits_tracePipe_iretire, i_toEncoder_blocks_0_bits_tracePipe_iretire;
  logic g_toEncoder_blocks_0_bits_tracePipe_ilastsize, i_toEncoder_blocks_0_bits_tracePipe_ilastsize;
  logic g_toEncoder_blocks_1_valid, i_toEncoder_blocks_1_valid;
  logic [3:0] g_toEncoder_blocks_1_bits_ftqOffset, i_toEncoder_blocks_1_bits_ftqOffset;
  logic [3:0] g_toEncoder_blocks_1_bits_tracePipe_itype, i_toEncoder_blocks_1_bits_tracePipe_itype;
  logic [6:0] g_toEncoder_blocks_1_bits_tracePipe_iretire, i_toEncoder_blocks_1_bits_tracePipe_iretire;
  logic g_toEncoder_blocks_1_bits_tracePipe_ilastsize, i_toEncoder_blocks_1_bits_tracePipe_ilastsize;
  logic g_toEncoder_blocks_2_valid, i_toEncoder_blocks_2_valid;
  logic [3:0] g_toEncoder_blocks_2_bits_ftqOffset, i_toEncoder_blocks_2_bits_ftqOffset;
  logic [3:0] g_toEncoder_blocks_2_bits_tracePipe_itype, i_toEncoder_blocks_2_bits_tracePipe_itype;
  logic [6:0] g_toEncoder_blocks_2_bits_tracePipe_iretire, i_toEncoder_blocks_2_bits_tracePipe_iretire;
  logic g_toEncoder_blocks_2_bits_tracePipe_ilastsize, i_toEncoder_blocks_2_bits_tracePipe_ilastsize;
  logic g_blockRobCommit, i_blockRobCommit;
  Trace g_u (.clock(clk), .reset(rst), .io_in_fromEncoder_enable(enable), .io_in_fromEncoder_stall(stall), .io_in_fromRob_blocks_0_valid(v0), .io_in_fromRob_blocks_0_bits_ftqIdx_value(idx0), .io_in_fromRob_blocks_0_bits_ftqOffset(off0), .io_in_fromRob_blocks_0_bits_tracePipe_itype(ity0), .io_in_fromRob_blocks_0_bits_tracePipe_iretire(ret0), .io_in_fromRob_blocks_0_bits_tracePipe_ilastsize(ls0), .io_in_fromRob_blocks_1_valid(v1), .io_in_fromRob_blocks_1_bits_ftqIdx_value(idx1), .io_in_fromRob_blocks_1_bits_ftqOffset(off1), .io_in_fromRob_blocks_1_bits_tracePipe_itype(ity1), .io_in_fromRob_blocks_1_bits_tracePipe_iretire(ret1), .io_in_fromRob_blocks_1_bits_tracePipe_ilastsize(ls1), .io_in_fromRob_blocks_2_valid(v2), .io_in_fromRob_blocks_2_bits_ftqIdx_value(idx2), .io_in_fromRob_blocks_2_bits_ftqOffset(off2), .io_in_fromRob_blocks_2_bits_tracePipe_itype(ity2), .io_in_fromRob_blocks_2_bits_tracePipe_iretire(ret2), .io_in_fromRob_blocks_2_bits_tracePipe_ilastsize(ls2), .io_in_fromRob_blocks_3_valid(v3), .io_in_fromRob_blocks_3_bits_ftqIdx_value(idx3), .io_in_fromRob_blocks_3_bits_ftqOffset(off3), .io_in_fromRob_blocks_3_bits_tracePipe_itype(ity3), .io_in_fromRob_blocks_3_bits_tracePipe_iretire(ret3), .io_in_fromRob_blocks_3_bits_tracePipe_ilastsize(ls3), .io_in_fromRob_blocks_4_valid(v4), .io_in_fromRob_blocks_4_bits_ftqIdx_value(idx4), .io_in_fromRob_blocks_4_bits_ftqOffset(off4), .io_in_fromRob_blocks_4_bits_tracePipe_itype(ity4), .io_in_fromRob_blocks_4_bits_tracePipe_iretire(ret4), .io_in_fromRob_blocks_4_bits_tracePipe_ilastsize(ls4), .io_in_fromRob_blocks_5_valid(v5), .io_in_fromRob_blocks_5_bits_ftqIdx_value(idx5), .io_in_fromRob_blocks_5_bits_ftqOffset(off5), .io_in_fromRob_blocks_5_bits_tracePipe_itype(ity5), .io_in_fromRob_blocks_5_bits_tracePipe_iretire(ret5), .io_in_fromRob_blocks_5_bits_tracePipe_ilastsize(ls5), .io_in_fromRob_blocks_6_valid(v6), .io_in_fromRob_blocks_6_bits_ftqIdx_value(idx6), .io_in_fromRob_blocks_6_bits_ftqOffset(off6), .io_in_fromRob_blocks_6_bits_tracePipe_itype(ity6), .io_in_fromRob_blocks_6_bits_tracePipe_iretire(ret6), .io_in_fromRob_blocks_6_bits_tracePipe_ilastsize(ls6), .io_in_fromRob_blocks_7_valid(v7), .io_in_fromRob_blocks_7_bits_ftqIdx_value(idx7), .io_in_fromRob_blocks_7_bits_ftqOffset(off7), .io_in_fromRob_blocks_7_bits_tracePipe_itype(ity7), .io_in_fromRob_blocks_7_bits_tracePipe_iretire(ret7), .io_in_fromRob_blocks_7_bits_tracePipe_ilastsize(ls7), .io_out_toPcMem_blocks_0_valid(g_toPcMem_blocks_0_valid), .io_out_toPcMem_blocks_0_bits_ftqIdx_value(g_toPcMem_blocks_0_bits_ftqIdx_value), .io_out_toPcMem_blocks_1_valid(g_toPcMem_blocks_1_valid), .io_out_toPcMem_blocks_1_bits_ftqIdx_value(g_toPcMem_blocks_1_bits_ftqIdx_value), .io_out_toPcMem_blocks_2_valid(g_toPcMem_blocks_2_valid), .io_out_toPcMem_blocks_2_bits_ftqIdx_value(g_toPcMem_blocks_2_bits_ftqIdx_value), .io_out_toEncoder_blocks_0_valid(g_toEncoder_blocks_0_valid), .io_out_toEncoder_blocks_0_bits_ftqOffset(g_toEncoder_blocks_0_bits_ftqOffset), .io_out_toEncoder_blocks_0_bits_tracePipe_itype(g_toEncoder_blocks_0_bits_tracePipe_itype), .io_out_toEncoder_blocks_0_bits_tracePipe_iretire(g_toEncoder_blocks_0_bits_tracePipe_iretire), .io_out_toEncoder_blocks_0_bits_tracePipe_ilastsize(g_toEncoder_blocks_0_bits_tracePipe_ilastsize), .io_out_toEncoder_blocks_1_valid(g_toEncoder_blocks_1_valid), .io_out_toEncoder_blocks_1_bits_ftqOffset(g_toEncoder_blocks_1_bits_ftqOffset), .io_out_toEncoder_blocks_1_bits_tracePipe_itype(g_toEncoder_blocks_1_bits_tracePipe_itype), .io_out_toEncoder_blocks_1_bits_tracePipe_iretire(g_toEncoder_blocks_1_bits_tracePipe_iretire), .io_out_toEncoder_blocks_1_bits_tracePipe_ilastsize(g_toEncoder_blocks_1_bits_tracePipe_ilastsize), .io_out_toEncoder_blocks_2_valid(g_toEncoder_blocks_2_valid), .io_out_toEncoder_blocks_2_bits_ftqOffset(g_toEncoder_blocks_2_bits_ftqOffset), .io_out_toEncoder_blocks_2_bits_tracePipe_itype(g_toEncoder_blocks_2_bits_tracePipe_itype), .io_out_toEncoder_blocks_2_bits_tracePipe_iretire(g_toEncoder_blocks_2_bits_tracePipe_iretire), .io_out_toEncoder_blocks_2_bits_tracePipe_ilastsize(g_toEncoder_blocks_2_bits_tracePipe_ilastsize), .io_out_blockRobCommit(g_blockRobCommit));
  Trace_xs i_u (.clock(clk), .reset(rst), .io_in_fromEncoder_enable(enable), .io_in_fromEncoder_stall(stall), .io_in_fromRob_blocks_0_valid(v0), .io_in_fromRob_blocks_0_bits_ftqIdx_value(idx0), .io_in_fromRob_blocks_0_bits_ftqOffset(off0), .io_in_fromRob_blocks_0_bits_tracePipe_itype(ity0), .io_in_fromRob_blocks_0_bits_tracePipe_iretire(ret0), .io_in_fromRob_blocks_0_bits_tracePipe_ilastsize(ls0), .io_in_fromRob_blocks_1_valid(v1), .io_in_fromRob_blocks_1_bits_ftqIdx_value(idx1), .io_in_fromRob_blocks_1_bits_ftqOffset(off1), .io_in_fromRob_blocks_1_bits_tracePipe_itype(ity1), .io_in_fromRob_blocks_1_bits_tracePipe_iretire(ret1), .io_in_fromRob_blocks_1_bits_tracePipe_ilastsize(ls1), .io_in_fromRob_blocks_2_valid(v2), .io_in_fromRob_blocks_2_bits_ftqIdx_value(idx2), .io_in_fromRob_blocks_2_bits_ftqOffset(off2), .io_in_fromRob_blocks_2_bits_tracePipe_itype(ity2), .io_in_fromRob_blocks_2_bits_tracePipe_iretire(ret2), .io_in_fromRob_blocks_2_bits_tracePipe_ilastsize(ls2), .io_in_fromRob_blocks_3_valid(v3), .io_in_fromRob_blocks_3_bits_ftqIdx_value(idx3), .io_in_fromRob_blocks_3_bits_ftqOffset(off3), .io_in_fromRob_blocks_3_bits_tracePipe_itype(ity3), .io_in_fromRob_blocks_3_bits_tracePipe_iretire(ret3), .io_in_fromRob_blocks_3_bits_tracePipe_ilastsize(ls3), .io_in_fromRob_blocks_4_valid(v4), .io_in_fromRob_blocks_4_bits_ftqIdx_value(idx4), .io_in_fromRob_blocks_4_bits_ftqOffset(off4), .io_in_fromRob_blocks_4_bits_tracePipe_itype(ity4), .io_in_fromRob_blocks_4_bits_tracePipe_iretire(ret4), .io_in_fromRob_blocks_4_bits_tracePipe_ilastsize(ls4), .io_in_fromRob_blocks_5_valid(v5), .io_in_fromRob_blocks_5_bits_ftqIdx_value(idx5), .io_in_fromRob_blocks_5_bits_ftqOffset(off5), .io_in_fromRob_blocks_5_bits_tracePipe_itype(ity5), .io_in_fromRob_blocks_5_bits_tracePipe_iretire(ret5), .io_in_fromRob_blocks_5_bits_tracePipe_ilastsize(ls5), .io_in_fromRob_blocks_6_valid(v6), .io_in_fromRob_blocks_6_bits_ftqIdx_value(idx6), .io_in_fromRob_blocks_6_bits_ftqOffset(off6), .io_in_fromRob_blocks_6_bits_tracePipe_itype(ity6), .io_in_fromRob_blocks_6_bits_tracePipe_iretire(ret6), .io_in_fromRob_blocks_6_bits_tracePipe_ilastsize(ls6), .io_in_fromRob_blocks_7_valid(v7), .io_in_fromRob_blocks_7_bits_ftqIdx_value(idx7), .io_in_fromRob_blocks_7_bits_ftqOffset(off7), .io_in_fromRob_blocks_7_bits_tracePipe_itype(ity7), .io_in_fromRob_blocks_7_bits_tracePipe_iretire(ret7), .io_in_fromRob_blocks_7_bits_tracePipe_ilastsize(ls7), .io_out_toPcMem_blocks_0_valid(i_toPcMem_blocks_0_valid), .io_out_toPcMem_blocks_0_bits_ftqIdx_value(i_toPcMem_blocks_0_bits_ftqIdx_value), .io_out_toPcMem_blocks_1_valid(i_toPcMem_blocks_1_valid), .io_out_toPcMem_blocks_1_bits_ftqIdx_value(i_toPcMem_blocks_1_bits_ftqIdx_value), .io_out_toPcMem_blocks_2_valid(i_toPcMem_blocks_2_valid), .io_out_toPcMem_blocks_2_bits_ftqIdx_value(i_toPcMem_blocks_2_bits_ftqIdx_value), .io_out_toEncoder_blocks_0_valid(i_toEncoder_blocks_0_valid), .io_out_toEncoder_blocks_0_bits_ftqOffset(i_toEncoder_blocks_0_bits_ftqOffset), .io_out_toEncoder_blocks_0_bits_tracePipe_itype(i_toEncoder_blocks_0_bits_tracePipe_itype), .io_out_toEncoder_blocks_0_bits_tracePipe_iretire(i_toEncoder_blocks_0_bits_tracePipe_iretire), .io_out_toEncoder_blocks_0_bits_tracePipe_ilastsize(i_toEncoder_blocks_0_bits_tracePipe_ilastsize), .io_out_toEncoder_blocks_1_valid(i_toEncoder_blocks_1_valid), .io_out_toEncoder_blocks_1_bits_ftqOffset(i_toEncoder_blocks_1_bits_ftqOffset), .io_out_toEncoder_blocks_1_bits_tracePipe_itype(i_toEncoder_blocks_1_bits_tracePipe_itype), .io_out_toEncoder_blocks_1_bits_tracePipe_iretire(i_toEncoder_blocks_1_bits_tracePipe_iretire), .io_out_toEncoder_blocks_1_bits_tracePipe_ilastsize(i_toEncoder_blocks_1_bits_tracePipe_ilastsize), .io_out_toEncoder_blocks_2_valid(i_toEncoder_blocks_2_valid), .io_out_toEncoder_blocks_2_bits_ftqOffset(i_toEncoder_blocks_2_bits_ftqOffset), .io_out_toEncoder_blocks_2_bits_tracePipe_itype(i_toEncoder_blocks_2_bits_tracePipe_itype), .io_out_toEncoder_blocks_2_bits_tracePipe_iretire(i_toEncoder_blocks_2_bits_tracePipe_iretire), .io_out_toEncoder_blocks_2_bits_tracePipe_ilastsize(i_toEncoder_blocks_2_bits_tracePipe_ilastsize), .io_out_blockRobCommit(i_blockRobCommit));

  // 激励：enable 多数为 1（阻塞机制只在 enable 下起作用），stall 偶发；
  // itype 一半为 None(0) 让压缩合并真的发生；valid 前缀式（提交块连续）与全随机各半。
  always @(negedge clk) begin
    if (rst) begin
      enable <= 0; stall <= 0;
      v0 <= 0; idx0 <= 0; off0 <= 0; ity0 <= 0; ret0 <= 0; ls0 <= 0; v1 <= 0; idx1 <= 0; off1 <= 0; ity1 <= 0; ret1 <= 0; ls1 <= 0; v2 <= 0; idx2 <= 0; off2 <= 0; ity2 <= 0; ret2 <= 0; ls2 <= 0; v3 <= 0; idx3 <= 0; off3 <= 0; ity3 <= 0; ret3 <= 0; ls3 <= 0; v4 <= 0; idx4 <= 0; off4 <= 0; ity4 <= 0; ret4 <= 0; ls4 <= 0; v5 <= 0; idx5 <= 0; off5 <= 0; ity5 <= 0; ret5 <= 0; ls5 <= 0; v6 <= 0; idx6 <= 0; off6 <= 0; ity6 <= 0; ret6 <= 0; ls6 <= 0; v7 <= 0; idx7 <= 0; off7 <= 0; ity7 <= 0; ret7 <= 0; ls7 <= 0;
    end else begin
      enable <= ($urandom_range(0, 99) < 85);
      stall  <= ($urandom_range(0, 99) < 15);
      if ($urandom_range(0, 1)) begin
        int n = $urandom_range(0, 8);
        v0 <= (0 < n); v1 <= (1 < n); v2 <= (2 < n); v3 <= (3 < n); v4 <= (4 < n); v5 <= (5 < n); v6 <= (6 < n); v7 <= (7 < n);
      end else begin
        v0 <= $urandom_range(0, 1); v1 <= $urandom_range(0, 1); v2 <= $urandom_range(0, 1); v3 <= $urandom_range(0, 1); v4 <= $urandom_range(0, 1); v5 <= $urandom_range(0, 1); v6 <= $urandom_range(0, 1); v7 <= $urandom_range(0, 1);
      end
      idx0 <= 6'($urandom); off0 <= 4'($urandom); ity0 <= ($urandom_range(0,1)) ? 4'h0 : 4'($urandom); ret0 <= 4'($urandom); ls0 <= 1'($urandom);
      idx1 <= 6'($urandom); off1 <= 4'($urandom); ity1 <= ($urandom_range(0,1)) ? 4'h0 : 4'($urandom); ret1 <= 4'($urandom); ls1 <= 1'($urandom);
      idx2 <= 6'($urandom); off2 <= 4'($urandom); ity2 <= ($urandom_range(0,1)) ? 4'h0 : 4'($urandom); ret2 <= 4'($urandom); ls2 <= 1'($urandom);
      idx3 <= 6'($urandom); off3 <= 4'($urandom); ity3 <= ($urandom_range(0,1)) ? 4'h0 : 4'($urandom); ret3 <= 4'($urandom); ls3 <= 1'($urandom);
      idx4 <= 6'($urandom); off4 <= 4'($urandom); ity4 <= ($urandom_range(0,1)) ? 4'h0 : 4'($urandom); ret4 <= 4'($urandom); ls4 <= 1'($urandom);
      idx5 <= 6'($urandom); off5 <= 4'($urandom); ity5 <= ($urandom_range(0,1)) ? 4'h0 : 4'($urandom); ret5 <= 4'($urandom); ls5 <= 1'($urandom);
      idx6 <= 6'($urandom); off6 <= 4'($urandom); ity6 <= ($urandom_range(0,1)) ? 4'h0 : 4'($urandom); ret6 <= 4'($urandom); ls6 <= 1'($urandom);
      idx7 <= 6'($urandom); off7 <= 4'($urandom); ity7 <= ($urandom_range(0,1)) ? 4'h0 : 4'($urandom); ret7 <= 4'($urandom); ls7 <= 1'($urandom);
    end
  end

  // 比对窗口：复位撤销后第 4 拍起（deqPtrPre / s3 寄存器无复位，前 2 拍才写定）。
  always @(negedge clk) if (!rst && cyc > 4) begin
    #4; checks++;
    if (g_toPcMem_blocks_0_valid !== i_toPcMem_blocks_0_valid) begin errors++; if (errors <= 40) $display("[%0t] toPcMem_blocks_0_valid g=%h i=%h", $time, g_toPcMem_blocks_0_valid, i_toPcMem_blocks_0_valid); end
    if (g_toPcMem_blocks_0_bits_ftqIdx_value !== i_toPcMem_blocks_0_bits_ftqIdx_value) begin errors++; if (errors <= 40) $display("[%0t] toPcMem_blocks_0_bits_ftqIdx_value g=%h i=%h", $time, g_toPcMem_blocks_0_bits_ftqIdx_value, i_toPcMem_blocks_0_bits_ftqIdx_value); end
    if (g_toPcMem_blocks_1_valid !== i_toPcMem_blocks_1_valid) begin errors++; if (errors <= 40) $display("[%0t] toPcMem_blocks_1_valid g=%h i=%h", $time, g_toPcMem_blocks_1_valid, i_toPcMem_blocks_1_valid); end
    if (g_toPcMem_blocks_1_bits_ftqIdx_value !== i_toPcMem_blocks_1_bits_ftqIdx_value) begin errors++; if (errors <= 40) $display("[%0t] toPcMem_blocks_1_bits_ftqIdx_value g=%h i=%h", $time, g_toPcMem_blocks_1_bits_ftqIdx_value, i_toPcMem_blocks_1_bits_ftqIdx_value); end
    if (g_toPcMem_blocks_2_valid !== i_toPcMem_blocks_2_valid) begin errors++; if (errors <= 40) $display("[%0t] toPcMem_blocks_2_valid g=%h i=%h", $time, g_toPcMem_blocks_2_valid, i_toPcMem_blocks_2_valid); end
    if (g_toPcMem_blocks_2_bits_ftqIdx_value !== i_toPcMem_blocks_2_bits_ftqIdx_value) begin errors++; if (errors <= 40) $display("[%0t] toPcMem_blocks_2_bits_ftqIdx_value g=%h i=%h", $time, g_toPcMem_blocks_2_bits_ftqIdx_value, i_toPcMem_blocks_2_bits_ftqIdx_value); end
    if (g_toEncoder_blocks_0_valid !== i_toEncoder_blocks_0_valid) begin errors++; if (errors <= 40) $display("[%0t] toEncoder_blocks_0_valid g=%h i=%h", $time, g_toEncoder_blocks_0_valid, i_toEncoder_blocks_0_valid); end
    if (g_toEncoder_blocks_0_bits_ftqOffset !== i_toEncoder_blocks_0_bits_ftqOffset) begin errors++; if (errors <= 40) $display("[%0t] toEncoder_blocks_0_bits_ftqOffset g=%h i=%h", $time, g_toEncoder_blocks_0_bits_ftqOffset, i_toEncoder_blocks_0_bits_ftqOffset); end
    if (g_toEncoder_blocks_0_bits_tracePipe_itype !== i_toEncoder_blocks_0_bits_tracePipe_itype) begin errors++; if (errors <= 40) $display("[%0t] toEncoder_blocks_0_bits_tracePipe_itype g=%h i=%h", $time, g_toEncoder_blocks_0_bits_tracePipe_itype, i_toEncoder_blocks_0_bits_tracePipe_itype); end
    if (g_toEncoder_blocks_0_bits_tracePipe_iretire !== i_toEncoder_blocks_0_bits_tracePipe_iretire) begin errors++; if (errors <= 40) $display("[%0t] toEncoder_blocks_0_bits_tracePipe_iretire g=%h i=%h", $time, g_toEncoder_blocks_0_bits_tracePipe_iretire, i_toEncoder_blocks_0_bits_tracePipe_iretire); end
    if (g_toEncoder_blocks_0_bits_tracePipe_ilastsize !== i_toEncoder_blocks_0_bits_tracePipe_ilastsize) begin errors++; if (errors <= 40) $display("[%0t] toEncoder_blocks_0_bits_tracePipe_ilastsize g=%h i=%h", $time, g_toEncoder_blocks_0_bits_tracePipe_ilastsize, i_toEncoder_blocks_0_bits_tracePipe_ilastsize); end
    if (g_toEncoder_blocks_1_valid !== i_toEncoder_blocks_1_valid) begin errors++; if (errors <= 40) $display("[%0t] toEncoder_blocks_1_valid g=%h i=%h", $time, g_toEncoder_blocks_1_valid, i_toEncoder_blocks_1_valid); end
    if (g_toEncoder_blocks_1_bits_ftqOffset !== i_toEncoder_blocks_1_bits_ftqOffset) begin errors++; if (errors <= 40) $display("[%0t] toEncoder_blocks_1_bits_ftqOffset g=%h i=%h", $time, g_toEncoder_blocks_1_bits_ftqOffset, i_toEncoder_blocks_1_bits_ftqOffset); end
    if (g_toEncoder_blocks_1_bits_tracePipe_itype !== i_toEncoder_blocks_1_bits_tracePipe_itype) begin errors++; if (errors <= 40) $display("[%0t] toEncoder_blocks_1_bits_tracePipe_itype g=%h i=%h", $time, g_toEncoder_blocks_1_bits_tracePipe_itype, i_toEncoder_blocks_1_bits_tracePipe_itype); end
    if (g_toEncoder_blocks_1_bits_tracePipe_iretire !== i_toEncoder_blocks_1_bits_tracePipe_iretire) begin errors++; if (errors <= 40) $display("[%0t] toEncoder_blocks_1_bits_tracePipe_iretire g=%h i=%h", $time, g_toEncoder_blocks_1_bits_tracePipe_iretire, i_toEncoder_blocks_1_bits_tracePipe_iretire); end
    if (g_toEncoder_blocks_1_bits_tracePipe_ilastsize !== i_toEncoder_blocks_1_bits_tracePipe_ilastsize) begin errors++; if (errors <= 40) $display("[%0t] toEncoder_blocks_1_bits_tracePipe_ilastsize g=%h i=%h", $time, g_toEncoder_blocks_1_bits_tracePipe_ilastsize, i_toEncoder_blocks_1_bits_tracePipe_ilastsize); end
    if (g_toEncoder_blocks_2_valid !== i_toEncoder_blocks_2_valid) begin errors++; if (errors <= 40) $display("[%0t] toEncoder_blocks_2_valid g=%h i=%h", $time, g_toEncoder_blocks_2_valid, i_toEncoder_blocks_2_valid); end
    if (g_toEncoder_blocks_2_bits_ftqOffset !== i_toEncoder_blocks_2_bits_ftqOffset) begin errors++; if (errors <= 40) $display("[%0t] toEncoder_blocks_2_bits_ftqOffset g=%h i=%h", $time, g_toEncoder_blocks_2_bits_ftqOffset, i_toEncoder_blocks_2_bits_ftqOffset); end
    if (g_toEncoder_blocks_2_bits_tracePipe_itype !== i_toEncoder_blocks_2_bits_tracePipe_itype) begin errors++; if (errors <= 40) $display("[%0t] toEncoder_blocks_2_bits_tracePipe_itype g=%h i=%h", $time, g_toEncoder_blocks_2_bits_tracePipe_itype, i_toEncoder_blocks_2_bits_tracePipe_itype); end
    if (g_toEncoder_blocks_2_bits_tracePipe_iretire !== i_toEncoder_blocks_2_bits_tracePipe_iretire) begin errors++; if (errors <= 40) $display("[%0t] toEncoder_blocks_2_bits_tracePipe_iretire g=%h i=%h", $time, g_toEncoder_blocks_2_bits_tracePipe_iretire, i_toEncoder_blocks_2_bits_tracePipe_iretire); end
    if (g_toEncoder_blocks_2_bits_tracePipe_ilastsize !== i_toEncoder_blocks_2_bits_tracePipe_ilastsize) begin errors++; if (errors <= 40) $display("[%0t] toEncoder_blocks_2_bits_tracePipe_ilastsize g=%h i=%h", $time, g_toEncoder_blocks_2_bits_tracePipe_ilastsize, i_toEncoder_blocks_2_bits_tracePipe_ilastsize); end
    if (g_blockRobCommit !== i_blockRobCommit) begin errors++; if (errors <= 40) $display("[%0t] blockRobCommit g=%h i=%h", $time, g_blockRobCommit, i_blockRobCommit); end
    if (g_blockRobCommit) cov_block++;
    if (stall && enable) cov_stall++;
    if (g_toPcMem_blocks_0_valid && g_toPcMem_blocks_1_valid && g_toPcMem_blocks_2_valid) cov_full3++;
    if (g_toEncoder_blocks_0_valid && g_toEncoder_blocks_0_bits_tracePipe_iretire > 7'd15) cov_merge++;
  end

  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES / 2) @(posedge clk);
    // 中途异步复位：复位域检验（指针/blockCommit/s1 有复位，traceEntries/deqPtrPre/s3 没有）
    @(negedge clk) rst = 1; repeat (3) @(posedge clk); @(negedge clk) rst = 0;
    repeat (NCYCLES / 2) @(posedge clk);
    $display("--- COVERAGE (每项必须 > 0) ---");
    $display("  blockRobCommit 反压   : %0d", cov_block);
    $display("  enable 下 stall       : %0d", cov_stall);
    $display("  一拍出满 3 组         : %0d", cov_full3);
    $display("  合并后 iretire > 15   : %0d", cov_merge);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000 && cov_block > 0 && cov_full3 > 0 && cov_merge > 0)
      $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
