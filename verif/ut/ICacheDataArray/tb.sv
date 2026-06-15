// =============================================================================
// ICacheDataArray UT：golden ICacheDataArray vs 手写 ICacheDataArray_xs 双例化。
// 两侧均例化同一批 golden 数据 SRAM / Mbist 黑盒，给完全相同的随机激励，逐拍比对
// 全部输出（8 bank 数据读出、8 bank 校验码、io_read_3_ready、4 way Mbist 出数/应答）。
//
// 注意：+define+SYNTHESIS 下 SRAM 存储体初值为 X；尚未写过的组读出即为 X。比对时用
// !$isunknown(golden) 跳过 golden 未知项（两侧 X 不可用 !== 比较）。预热阶段先大量写入
// 各组，使后续随机读多数命中已写数据，从而获得充分的有效比对点。
// =============================================================================
`timescale 1ns/1ps
module tb;
  localparam int NCYCLES = 30000;
  localparam int WARMUP  = 2000;   // 须大于 SRAM 复位清零拍数 + 预热写入

  bit clk = 0, rst;
  int errors = 0, checks = 0;
  int unsigned cycle = 0;
  always #5 clk = ~clk;
  always @(posedge clk) cycle++;

  // ---- 公共激励信号 ----
  logic         w_valid, w_poison;
  logic [7:0]   w_virIdx;
  logic [511:0] w_data;
  logic [3:0]   w_waymask;

  logic         r0_v, r1_v, r2_v, r3_v;
  logic [7:0]   r0_s0, r0_s1, r1_s0, r1_s1, r2_s0, r2_s1, r3_s0, r3_s1;
  logic         wm00, wm01, wm02, wm03, wm10, wm11, wm12, wm13;
  logic [5:0]   blkOff;

  // ---- Mbist / sigFromSrams 激励（DFT，给随机但两侧一致）----
  logic [5:0]   bd_arr, bd1_arr, bd2_arr, bd3_arr;   // 取最宽 6bit，按端口宽度截断
  logic         bd_all, bd_req, bd_we, bd_be, bd_re;
  logic [8:0]   bd_addr, bd_addr_rd;
  logic [65:0]  bd_indata;
  logic [6:0]   sig [32];                              // 每块 SRAM 7 个 sig 位

  // ---- 输出（golden=g_*, impl=i_*）----
  wire          g_r3rdy, i_r3rdy;
  wire [63:0]   g_d [8], i_d [8];
  wire          g_c [8], i_c [8];
  wire [65:0]   g_bo [4], i_bo [4];
  wire          g_ba [4], i_ba [4];

  // 端口连线宏：DUT 例化两侧共用，仅输出信号不同
  `define DUT(NAME, R3, D, C, BO, BA) \
    NAME u_``NAME ( \
      .clock(clk), .reset(rst), \
      .io_write_valid(w_valid), .io_write_bits_virIdx(w_virIdx), \
      .io_write_bits_data(w_data), .io_write_bits_waymask(w_waymask), \
      .io_write_bits_poison(w_poison), \
      .io_read_0_valid(r0_v), .io_read_0_bits_vSetIdx_0(r0_s0), .io_read_0_bits_vSetIdx_1(r0_s1), \
      .io_read_0_bits_waymask_0_0(wm00), .io_read_0_bits_waymask_0_1(wm01), \
      .io_read_0_bits_waymask_0_2(wm02), .io_read_0_bits_waymask_0_3(wm03), \
      .io_read_0_bits_waymask_1_0(wm10), .io_read_0_bits_waymask_1_1(wm11), \
      .io_read_0_bits_waymask_1_2(wm12), .io_read_0_bits_waymask_1_3(wm13), \
      .io_read_0_bits_blkOffset(blkOff), \
      .io_read_1_valid(r1_v), .io_read_1_bits_vSetIdx_0(r1_s0), .io_read_1_bits_vSetIdx_1(r1_s1), \
      .io_read_2_valid(r2_v), .io_read_2_bits_vSetIdx_0(r2_s0), .io_read_2_bits_vSetIdx_1(r2_s1), \
      .io_read_3_ready(R3), \
      .io_read_3_valid(r3_v), .io_read_3_bits_vSetIdx_0(r3_s0), .io_read_3_bits_vSetIdx_1(r3_s1), \
      .io_readResp_datas_0(D[0]), .io_readResp_datas_1(D[1]), .io_readResp_datas_2(D[2]), \
      .io_readResp_datas_3(D[3]), .io_readResp_datas_4(D[4]), .io_readResp_datas_5(D[5]), \
      .io_readResp_datas_6(D[6]), .io_readResp_datas_7(D[7]), \
      .io_readResp_codes_0(C[0]), .io_readResp_codes_1(C[1]), .io_readResp_codes_2(C[2]), \
      .io_readResp_codes_3(C[3]), .io_readResp_codes_4(C[4]), .io_readResp_codes_5(C[5]), \
      .io_readResp_codes_6(C[6]), .io_readResp_codes_7(C[7]), \
      .boreChildrenBd_bore_array(bd_arr[3:0]), .boreChildrenBd_bore_all(bd_all), \
      .boreChildrenBd_bore_req(bd_req), .boreChildrenBd_bore_ack(BA[0]), \
      .boreChildrenBd_bore_writeen(bd_we), .boreChildrenBd_bore_be(bd_be), \
      .boreChildrenBd_bore_addr(bd_addr), .boreChildrenBd_bore_indata(bd_indata), \
      .boreChildrenBd_bore_readen(bd_re), .boreChildrenBd_bore_addr_rd(bd_addr_rd), \
      .boreChildrenBd_bore_outdata(BO[0]), \
      .boreChildrenBd_bore_1_array(bd1_arr[4:0]), .boreChildrenBd_bore_1_all(bd_all), \
      .boreChildrenBd_bore_1_req(bd_req), .boreChildrenBd_bore_1_ack(BA[1]), \
      .boreChildrenBd_bore_1_writeen(bd_we), .boreChildrenBd_bore_1_be(bd_be), \
      .boreChildrenBd_bore_1_addr(bd_addr), .boreChildrenBd_bore_1_indata(bd_indata), \
      .boreChildrenBd_bore_1_readen(bd_re), .boreChildrenBd_bore_1_addr_rd(bd_addr_rd), \
      .boreChildrenBd_bore_1_outdata(BO[1]), \
      .boreChildrenBd_bore_2_array(bd2_arr[4:0]), .boreChildrenBd_bore_2_all(bd_all), \
      .boreChildrenBd_bore_2_req(bd_req), .boreChildrenBd_bore_2_ack(BA[2]), \
      .boreChildrenBd_bore_2_writeen(bd_we), .boreChildrenBd_bore_2_be(bd_be), \
      .boreChildrenBd_bore_2_addr(bd_addr), .boreChildrenBd_bore_2_indata(bd_indata), \
      .boreChildrenBd_bore_2_readen(bd_re), .boreChildrenBd_bore_2_addr_rd(bd_addr_rd), \
      .boreChildrenBd_bore_2_outdata(BO[2]), \
      .boreChildrenBd_bore_3_array(bd3_arr[5:0]), .boreChildrenBd_bore_3_all(bd_all), \
      .boreChildrenBd_bore_3_req(bd_req), .boreChildrenBd_bore_3_ack(BA[3]), \
      .boreChildrenBd_bore_3_writeen(bd_we), .boreChildrenBd_bore_3_be(bd_be), \
      .boreChildrenBd_bore_3_addr(bd_addr), .boreChildrenBd_bore_3_indata(bd_indata), \
      .boreChildrenBd_bore_3_readen(bd_re), .boreChildrenBd_bore_3_addr_rd(bd_addr_rd), \
      .boreChildrenBd_bore_3_outdata(BO[3]), \
      `SIGS \
    );

  // sigFromSrams_bore_<k> 端口（32 块各 7 信号），两侧接同一 sig[k]
  `define SIG1(K,SF) \
    .sigFromSrams_bore``SF``_ram_hold(sig[K][0]), .sigFromSrams_bore``SF``_ram_bypass(sig[K][1]), \
    .sigFromSrams_bore``SF``_ram_bp_clken(sig[K][2]), .sigFromSrams_bore``SF``_ram_aux_clk(sig[K][3]), \
    .sigFromSrams_bore``SF``_ram_aux_ckbp(sig[K][4]), .sigFromSrams_bore``SF``_ram_mcp_hold(sig[K][5]), \
    .sigFromSrams_bore``SF``_cgen(sig[K][6])
  `define SIGS \
    `SIG1(0,), `SIG1(1,_1), `SIG1(2,_2), `SIG1(3,_3), `SIG1(4,_4), `SIG1(5,_5), \
    `SIG1(6,_6), `SIG1(7,_7), `SIG1(8,_8), `SIG1(9,_9), `SIG1(10,_10), `SIG1(11,_11), \
    `SIG1(12,_12), `SIG1(13,_13), `SIG1(14,_14), `SIG1(15,_15), `SIG1(16,_16), `SIG1(17,_17), \
    `SIG1(18,_18), `SIG1(19,_19), `SIG1(20,_20), `SIG1(21,_21), `SIG1(22,_22), `SIG1(23,_23), \
    `SIG1(24,_24), `SIG1(25,_25), `SIG1(26,_26), `SIG1(27,_27), `SIG1(28,_28), `SIG1(29,_29), \
    `SIG1(30,_30), `SIG1(31,_31)

  `DUT(ICacheDataArray,    g_r3rdy, g_d, g_c, g_bo, g_ba)
  `DUT(ICacheDataArray_xs, i_r3rdy, i_d, i_c, i_bo, i_ba)

  // ---- 随机激励（negedge 更新，避免与采样竞争）----
  // 取指偏移约束：硬件断言要求一次访问恰好 5 个 bank，对应 blkOffset[5:3] 合法即可；
  // 这里给整个 6bit 随机偏移（断言已在 SYNTHESIS 下关闭），充分覆盖跨行各情形。
  always @(negedge clk) begin
    if (rst) begin
      w_valid<=0; r0_v<=0; r1_v<=0; r2_v<=0; r3_v<=0;
      bd_all<=0; bd_req<=0; bd_we<=0; bd_re<=0; bd_be<=0;
    end else begin
      // 预热阶段偏重写入，铺满更多组；之后读写混合
      w_valid  <= (cycle < WARMUP) ? ($urandom_range(0,1)==0) : ($urandom_range(0,2)==0);
      w_virIdx <= 8'($urandom);
      w_data   <= {$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,
                   $urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom};
      w_waymask<= 4'($urandom);
      w_poison <= $urandom;

      r0_v <= ($urandom_range(0,1)==0);
      r1_v <= r0_v_next(); r2_v <= r0_v_next(); r3_v <= r0_v_next();
      r0_s0<=8'($urandom); r0_s1<=8'($urandom);
      r1_s0<=8'($urandom); r1_s1<=8'($urandom);
      r2_s0<=8'($urandom); r2_s1<=8'($urandom);
      r3_s0<=8'($urandom); r3_s1<=8'($urandom);
      {wm03,wm02,wm01,wm00} <= 4'($urandom);
      {wm13,wm12,wm11,wm10} <= 4'($urandom);
      blkOff <= 6'($urandom);

      // DFT 随机激励（两侧一致即可，仅验证透传/互联正确）
      bd_arr<=6'($urandom); bd1_arr<=6'($urandom); bd2_arr<=6'($urandom); bd3_arr<=6'($urandom);
      bd_all<=$urandom; bd_req<=$urandom; bd_we<=$urandom; bd_re<=$urandom; bd_be<=$urandom;
      bd_addr<=9'($urandom); bd_addr_rd<=9'($urandom); bd_indata<=66'($urandom);
      for (int k=0;k<32;k++) sig[k] <= 7'($urandom);
    end
  end
  function automatic logic r0_v_next; return ($urandom_range(0,1)==0); endfunction

  // ---- 逐拍比对（采样在 posedge 后，避开组合稳定前）----
  always @(posedge clk) if (!rst && cycle>WARMUP) begin
    #1; checks++;
    if (g_r3rdy !== i_r3rdy) begin errors++; rpt("read_3_ready"); end
    for (int b=0;b<8;b++) begin
      if (!$isunknown(g_d[b]) && g_d[b] !== i_d[b]) begin errors++; if(errors<=30) $display("[%0t] datas[%0d] g=%h i=%h",$time,b,g_d[b],i_d[b]); end
      if (!$isunknown(g_c[b]) && g_c[b] !== i_c[b]) begin errors++; if(errors<=30) $display("[%0t] codes[%0d] g=%b i=%b",$time,b,g_c[b],i_c[b]); end
    end
    for (int w=0;w<4;w++) begin
      if (!$isunknown(g_bo[w]) && g_bo[w] !== i_bo[w]) begin errors++; if(errors<=30) $display("[%0t] mbist_outdata[%0d] g=%h i=%h",$time,w,g_bo[w],i_bo[w]); end
      if (!$isunknown(g_ba[w]) && g_ba[w] !== i_ba[w]) begin errors++; if(errors<=30) $display("[%0t] mbist_ack[%0d]",$time,w); end
    end
  end

  task automatic rpt(string s); if(errors<=30) $display("[%0t] %s mismatch",$time,s); endtask

  initial begin
    rst=1; repeat(20) @(posedge clk); rst=0;
    repeat(NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors==0 && checks>1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
