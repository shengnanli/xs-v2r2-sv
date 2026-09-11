// 自动生成：scripts/gen_icachereplacer.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 20000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic io_touch_0_valid;
  logic [7:0] io_touch_0_bits_vSetIdx;
  logic [1:0] io_touch_0_bits_way;
  logic io_touch_1_valid;
  logic [7:0] io_touch_1_bits_vSetIdx;
  logic [1:0] io_touch_1_bits_way;
  logic io_victim_vSetIdx_valid;
  logic [7:0] io_victim_vSetIdx_bits;
  wire [1:0] g_io_victim_way;
  wire [1:0] i_io_victim_way;

  ICacheReplacer u_g (.clock(clk), .reset(rst), .io_touch_0_valid(io_touch_0_valid), .io_touch_0_bits_vSetIdx(io_touch_0_bits_vSetIdx), .io_touch_0_bits_way(io_touch_0_bits_way), .io_touch_1_valid(io_touch_1_valid), .io_touch_1_bits_vSetIdx(io_touch_1_bits_vSetIdx), .io_touch_1_bits_way(io_touch_1_bits_way), .io_victim_vSetIdx_valid(io_victim_vSetIdx_valid), .io_victim_vSetIdx_bits(io_victim_vSetIdx_bits), .io_victim_way(g_io_victim_way));
  ICacheReplacer_xs u_i (.clock(clk), .reset(rst), .io_touch_0_valid(io_touch_0_valid), .io_touch_0_bits_vSetIdx(io_touch_0_bits_vSetIdx), .io_touch_0_bits_way(io_touch_0_bits_way), .io_touch_1_valid(io_touch_1_valid), .io_touch_1_bits_vSetIdx(io_touch_1_bits_vSetIdx), .io_touch_1_bits_way(io_touch_1_bits_way), .io_victim_vSetIdx_valid(io_victim_vSetIdx_valid), .io_victim_vSetIdx_bits(io_victim_vSetIdx_bits), .io_victim_way(i_io_victim_way));

  always @(negedge clk) begin
    if (rst) begin
      io_touch_0_valid <= 1'b0;
      io_touch_1_valid <= 1'b0;
      io_victim_vSetIdx_valid <= 1'b0;
    end else begin
      logic [7:0] base;
      base = {7'($urandom), 1'b0};
      io_touch_0_valid <= ($urandom_range(0,1)==0);
      io_touch_1_valid <= ($urandom_range(0,1)==0);
      io_touch_0_bits_way <= 2'($urandom);
      io_touch_1_bits_way <= 2'($urandom);
      if ($urandom_range(0,1)==0) begin
        // 取指跨边界：相邻偶/奇组
        io_touch_0_bits_vSetIdx <= base;
        io_touch_1_bits_vSetIdx <= base + 8'd1;
      end else begin
        // 完全独立随机（含同奇偶、同组冲突）
        io_touch_0_bits_vSetIdx <= 8'($urandom);
        io_touch_1_bits_vSetIdx <= ($urandom_range(0,3)==0) ? base
                                                            : 8'($urandom);
      end
      // victim 查询：随机 set（含奇偶），valid 随机 → 覆盖延迟 refill touch；
      // 偏向小地址以提高与 touch 命中同组的概率
      io_victim_vSetIdx_valid <= ($urandom_range(0,1)==0);
      io_victim_vSetIdx_bits <= ($urandom_range(0,2)==0) ? base
                                                         : 8'($urandom);
    end
  end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (g_io_victim_way !== i_io_victim_way) begin errors++;
      if(errors<=30) $display("[%0t] io_victim_way g=%h i=%h", $time, g_io_victim_way, i_io_victim_way); end
  end

  initial begin
    rst = 1'b1;
    repeat (5) @(negedge clk);
    rst = 1'b0;
    repeat (NCYCLES) @(negedge clk);
    if (errors == 0) $display("TEST PASSED  checks=%0d errors=%0d", checks, errors);
    else             $display("TEST FAILED  checks=%0d errors=%0d", checks, errors);
    $finish;
  end
endmodule
