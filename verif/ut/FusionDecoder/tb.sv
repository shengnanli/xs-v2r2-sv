`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int unsigned WARMUP  = 8;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic        io_disableFusion;
  logic        io_in_valid [6];
  logic [31:0] io_in_bits  [6];
  logic        io_inReady  [5];
  logic [8:0]  io_dec_fuOpType [5];

  // 输出线: g=golden, i=impl
  wire         g_out_valid[5], i_out_valid[5];
  wire         g_fuType_valid[5], i_fuType_valid[5];
  wire         g_fuOpType_valid[5], i_fuOpType_valid[5];
  wire [8:0]   g_fuOpType_bits[5], i_fuOpType_bits[5];
  wire         g_lsrc2_valid[5], i_lsrc2_valid[5];
  wire [5:0]   g_lsrc2_bits[5], i_lsrc2_bits[5];
  wire         g_src2Type_valid[5], i_src2Type_valid[5];
  wire         g_selImm_valid[5], i_selImm_valid[5];
  wire [3:0]   g_selImm_bits[5], i_selImm_bits[5];
  wire         g_rs2FromRs1[5], i_rs2FromRs1[5];
  wire         g_rs2FromRs2[5], i_rs2FromRs2[5];
  wire         g_rs2FromZero[5], i_rs2FromZero[5];
  wire         g_clear[5], i_clear[5];

  FusionDecoder u_g (
    .clock(clk), .reset(rst), .io_disableFusion(io_disableFusion),
    .io_in_0_valid(io_in_valid[0]), .io_in_0_bits(io_in_bits[0]),
    .io_in_1_valid(io_in_valid[1]), .io_in_1_bits(io_in_bits[1]),
    .io_in_2_valid(io_in_valid[2]), .io_in_2_bits(io_in_bits[2]),
    .io_in_3_valid(io_in_valid[3]), .io_in_3_bits(io_in_bits[3]),
    .io_in_4_valid(io_in_valid[4]), .io_in_4_bits(io_in_bits[4]),
    .io_in_5_valid(io_in_valid[5]), .io_in_5_bits(io_in_bits[5]),
    .io_inReady_0(io_inReady[0]), .io_inReady_1(io_inReady[1]),
    .io_inReady_2(io_inReady[2]), .io_inReady_3(io_inReady[3]), .io_inReady_4(io_inReady[4]),
    .io_dec_0_fuOpType(io_dec_fuOpType[0]), .io_dec_1_fuOpType(io_dec_fuOpType[1]),
    .io_dec_2_fuOpType(io_dec_fuOpType[2]), .io_dec_3_fuOpType(io_dec_fuOpType[3]),
    .io_dec_4_fuOpType(io_dec_fuOpType[4]),
    .io_out_0_valid(g_out_valid[0]), .io_out_0_bits_fuType_valid(g_fuType_valid[0]), .io_out_0_bits_fuOpType_valid(g_fuOpType_valid[0]), .io_out_0_bits_fuOpType_bits(g_fuOpType_bits[0]), .io_out_0_bits_lsrc2_valid(g_lsrc2_valid[0]), .io_out_0_bits_lsrc2_bits(g_lsrc2_bits[0]), .io_out_0_bits_src2Type_valid(g_src2Type_valid[0]), .io_out_0_bits_selImm_valid(g_selImm_valid[0]), .io_out_0_bits_selImm_bits(g_selImm_bits[0]),
    .io_out_1_valid(g_out_valid[1]), .io_out_1_bits_fuType_valid(g_fuType_valid[1]), .io_out_1_bits_fuOpType_valid(g_fuOpType_valid[1]), .io_out_1_bits_fuOpType_bits(g_fuOpType_bits[1]), .io_out_1_bits_lsrc2_valid(g_lsrc2_valid[1]), .io_out_1_bits_lsrc2_bits(g_lsrc2_bits[1]), .io_out_1_bits_src2Type_valid(g_src2Type_valid[1]), .io_out_1_bits_selImm_valid(g_selImm_valid[1]), .io_out_1_bits_selImm_bits(g_selImm_bits[1]),
    .io_out_2_valid(g_out_valid[2]), .io_out_2_bits_fuType_valid(g_fuType_valid[2]), .io_out_2_bits_fuOpType_valid(g_fuOpType_valid[2]), .io_out_2_bits_fuOpType_bits(g_fuOpType_bits[2]), .io_out_2_bits_lsrc2_valid(g_lsrc2_valid[2]), .io_out_2_bits_lsrc2_bits(g_lsrc2_bits[2]), .io_out_2_bits_src2Type_valid(g_src2Type_valid[2]), .io_out_2_bits_selImm_valid(g_selImm_valid[2]), .io_out_2_bits_selImm_bits(g_selImm_bits[2]),
    .io_out_3_valid(g_out_valid[3]), .io_out_3_bits_fuType_valid(g_fuType_valid[3]), .io_out_3_bits_fuOpType_valid(g_fuOpType_valid[3]), .io_out_3_bits_fuOpType_bits(g_fuOpType_bits[3]), .io_out_3_bits_lsrc2_valid(g_lsrc2_valid[3]), .io_out_3_bits_lsrc2_bits(g_lsrc2_bits[3]), .io_out_3_bits_src2Type_valid(g_src2Type_valid[3]), .io_out_3_bits_selImm_valid(g_selImm_valid[3]), .io_out_3_bits_selImm_bits(g_selImm_bits[3]),
    .io_out_4_valid(g_out_valid[4]), .io_out_4_bits_fuType_valid(g_fuType_valid[4]), .io_out_4_bits_fuOpType_valid(g_fuOpType_valid[4]), .io_out_4_bits_fuOpType_bits(g_fuOpType_bits[4]), .io_out_4_bits_lsrc2_valid(g_lsrc2_valid[4]), .io_out_4_bits_lsrc2_bits(g_lsrc2_bits[4]), .io_out_4_bits_src2Type_valid(g_src2Type_valid[4]), .io_out_4_bits_selImm_valid(g_selImm_valid[4]), .io_out_4_bits_selImm_bits(g_selImm_bits[4]),
    .io_info_0_rs2FromRs1(g_rs2FromRs1[0]), .io_info_0_rs2FromRs2(g_rs2FromRs2[0]), .io_info_0_rs2FromZero(g_rs2FromZero[0]),
    .io_info_1_rs2FromRs1(g_rs2FromRs1[1]), .io_info_1_rs2FromRs2(g_rs2FromRs2[1]), .io_info_1_rs2FromZero(g_rs2FromZero[1]),
    .io_info_2_rs2FromRs1(g_rs2FromRs1[2]), .io_info_2_rs2FromRs2(g_rs2FromRs2[2]), .io_info_2_rs2FromZero(g_rs2FromZero[2]),
    .io_info_3_rs2FromRs1(g_rs2FromRs1[3]), .io_info_3_rs2FromRs2(g_rs2FromRs2[3]), .io_info_3_rs2FromZero(g_rs2FromZero[3]),
    .io_info_4_rs2FromRs1(g_rs2FromRs1[4]), .io_info_4_rs2FromRs2(g_rs2FromRs2[4]), .io_info_4_rs2FromZero(g_rs2FromZero[4]),
    .io_clear_1(g_clear[0]), .io_clear_2(g_clear[1]), .io_clear_3(g_clear[2]), .io_clear_4(g_clear[3]), .io_clear_5(g_clear[4])
  );

  FusionDecoder_xs u_i (
    .clock(clk), .reset(rst), .io_disableFusion(io_disableFusion),
    .io_in_0_valid(io_in_valid[0]), .io_in_0_bits(io_in_bits[0]),
    .io_in_1_valid(io_in_valid[1]), .io_in_1_bits(io_in_bits[1]),
    .io_in_2_valid(io_in_valid[2]), .io_in_2_bits(io_in_bits[2]),
    .io_in_3_valid(io_in_valid[3]), .io_in_3_bits(io_in_bits[3]),
    .io_in_4_valid(io_in_valid[4]), .io_in_4_bits(io_in_bits[4]),
    .io_in_5_valid(io_in_valid[5]), .io_in_5_bits(io_in_bits[5]),
    .io_inReady_0(io_inReady[0]), .io_inReady_1(io_inReady[1]),
    .io_inReady_2(io_inReady[2]), .io_inReady_3(io_inReady[3]), .io_inReady_4(io_inReady[4]),
    .io_dec_0_fuOpType(io_dec_fuOpType[0]), .io_dec_1_fuOpType(io_dec_fuOpType[1]),
    .io_dec_2_fuOpType(io_dec_fuOpType[2]), .io_dec_3_fuOpType(io_dec_fuOpType[3]),
    .io_dec_4_fuOpType(io_dec_fuOpType[4]),
    .io_out_0_valid(i_out_valid[0]), .io_out_0_bits_fuType_valid(i_fuType_valid[0]), .io_out_0_bits_fuOpType_valid(i_fuOpType_valid[0]), .io_out_0_bits_fuOpType_bits(i_fuOpType_bits[0]), .io_out_0_bits_lsrc2_valid(i_lsrc2_valid[0]), .io_out_0_bits_lsrc2_bits(i_lsrc2_bits[0]), .io_out_0_bits_src2Type_valid(i_src2Type_valid[0]), .io_out_0_bits_selImm_valid(i_selImm_valid[0]), .io_out_0_bits_selImm_bits(i_selImm_bits[0]),
    .io_out_1_valid(i_out_valid[1]), .io_out_1_bits_fuType_valid(i_fuType_valid[1]), .io_out_1_bits_fuOpType_valid(i_fuOpType_valid[1]), .io_out_1_bits_fuOpType_bits(i_fuOpType_bits[1]), .io_out_1_bits_lsrc2_valid(i_lsrc2_valid[1]), .io_out_1_bits_lsrc2_bits(i_lsrc2_bits[1]), .io_out_1_bits_src2Type_valid(i_src2Type_valid[1]), .io_out_1_bits_selImm_valid(i_selImm_valid[1]), .io_out_1_bits_selImm_bits(i_selImm_bits[1]),
    .io_out_2_valid(i_out_valid[2]), .io_out_2_bits_fuType_valid(i_fuType_valid[2]), .io_out_2_bits_fuOpType_valid(i_fuOpType_valid[2]), .io_out_2_bits_fuOpType_bits(i_fuOpType_bits[2]), .io_out_2_bits_lsrc2_valid(i_lsrc2_valid[2]), .io_out_2_bits_lsrc2_bits(i_lsrc2_bits[2]), .io_out_2_bits_src2Type_valid(i_src2Type_valid[2]), .io_out_2_bits_selImm_valid(i_selImm_valid[2]), .io_out_2_bits_selImm_bits(i_selImm_bits[2]),
    .io_out_3_valid(i_out_valid[3]), .io_out_3_bits_fuType_valid(i_fuType_valid[3]), .io_out_3_bits_fuOpType_valid(i_fuOpType_valid[3]), .io_out_3_bits_fuOpType_bits(i_fuOpType_bits[3]), .io_out_3_bits_lsrc2_valid(i_lsrc2_valid[3]), .io_out_3_bits_lsrc2_bits(i_lsrc2_bits[3]), .io_out_3_bits_src2Type_valid(i_src2Type_valid[3]), .io_out_3_bits_selImm_valid(i_selImm_valid[3]), .io_out_3_bits_selImm_bits(i_selImm_bits[3]),
    .io_out_4_valid(i_out_valid[4]), .io_out_4_bits_fuType_valid(i_fuType_valid[4]), .io_out_4_bits_fuOpType_valid(i_fuOpType_valid[4]), .io_out_4_bits_fuOpType_bits(i_fuOpType_bits[4]), .io_out_4_bits_lsrc2_valid(i_lsrc2_valid[4]), .io_out_4_bits_lsrc2_bits(i_lsrc2_bits[4]), .io_out_4_bits_src2Type_valid(i_src2Type_valid[4]), .io_out_4_bits_selImm_valid(i_selImm_valid[4]), .io_out_4_bits_selImm_bits(i_selImm_bits[4]),
    .io_info_0_rs2FromRs1(i_rs2FromRs1[0]), .io_info_0_rs2FromRs2(i_rs2FromRs2[0]), .io_info_0_rs2FromZero(i_rs2FromZero[0]),
    .io_info_1_rs2FromRs1(i_rs2FromRs1[1]), .io_info_1_rs2FromRs2(i_rs2FromRs2[1]), .io_info_1_rs2FromZero(i_rs2FromZero[1]),
    .io_info_2_rs2FromRs1(i_rs2FromRs1[2]), .io_info_2_rs2FromRs2(i_rs2FromRs2[2]), .io_info_2_rs2FromZero(i_rs2FromZero[2]),
    .io_info_3_rs2FromRs1(i_rs2FromRs1[3]), .io_info_3_rs2FromRs2(i_rs2FromRs2[3]), .io_info_3_rs2FromZero(i_rs2FromZero[3]),
    .io_info_4_rs2FromRs1(i_rs2FromRs1[4]), .io_info_4_rs2FromRs2(i_rs2FromRs2[4]), .io_info_4_rs2FromZero(i_rs2FromZero[4]),
    .io_clear_1(i_clear[0]), .io_clear_2(i_clear[1]), .io_clear_3(i_clear[2]), .io_clear_4(i_clear[3]), .io_clear_5(i_clear[4])
  );

  // 生成一条更可能命中融合模式的指令: 30% 概率用已知融合首指令模板
  function automatic logic [31:0] gen_instr(int idx);
    logic [31:0] w;
    int sel = $urandom_range(0, 9);
    logic [4:0] rd = 5'($urandom_range(1,8));   // 小寄存器域, 提升 rd 链命中率
    logic [4:0] rs1 = 5'($urandom_range(1,8));
    logic [4:0] rs2 = 5'($urandom_range(1,8));
    case (sel)
      // srli/srai(fv0/1 首指令)
      0: w = {6'h20, 6'h20, rs1, 3'h5, rd, 7'h13};
      1: w = {6'h30, 6'h20, rs1, 3'h5, rd, 7'h13};
      // slli.uw / addi 类
      2: w = {12'h1, rs1, 3'h1, rd, 7'h1B};
      3: w = {12'hFF, rs1, 3'h0, rd, 7'h13};
      // lui(fv26/27 首指令)
      4: w = {20'($urandom), rd, 7'h37};
      // andi.h(fv10 首指令 addiw)
      5: w = {6'h8, 6'h0, rs1, 3'h1, rd, 7'h1B};
      default: w = $urandom;
    endcase
    return w;
  endfunction

  // 生成第二条(后随)指令: 让 rs1/dest 与前一条挂钩(提升 rd 链命中)
  function automatic logic [31:0] gen_instr2(logic [4:0] prevRd);
    logic [31:0] w;
    int sel = $urandom_range(0, 9);
    logic [4:0] rd = prevRd;
    logic [4:0] rs2 = 5'($urandom_range(1,8));
    case (sel)
      0: w = {6'h20, rs2, prevRd, 3'h5, rd, 7'h13};   // srai(293 组)
      1: w = {6'h0, rs2, prevRd, 3'h0, rd, 7'h33};    // add(33 组)
      2: w = {12'hFF, prevRd, 3'h7, rd, 7'h13};       // andi 0xFF
      3: w = {12'h1, prevRd, 3'h7, rd, 7'h1B};
      default: w = $urandom;
    endcase
    return w;
  endfunction

  always @(negedge clk) begin
    if (rst) begin
      io_disableFusion <= '0;
      for (int j=0;j<6;j++) begin io_in_valid[j] <= '0; io_in_bits[j] <= '0; end
      for (int j=0;j<5;j++) begin io_inReady[j] <= '0; io_dec_fuOpType[j] <= '0; end
    end else begin
      io_disableFusion <= ($urandom_range(0,9)==0);
      for (int j=0;j<6;j++) begin
        io_in_valid[j] <= ($urandom_range(0,4)!=0);  // 多数有效
        io_in_bits[j]  <= gen_instr(j);
      end
      // 半数情况让相邻指令构成 rd 链
      for (int j=1;j<6;j++)
        if ($urandom_range(0,1)==0)
          io_in_bits[j] <= gen_instr2(io_in_bits[j-1][11:7]);
      for (int j=0;j<5;j++) begin
        io_inReady[j]      <= ($urandom_range(0,2)!=0);
        io_dec_fuOpType[j] <= 9'($urandom);
      end
    end
  end

  task automatic chk(input string nm, input logic g, input logic i);
    if (g !== i) begin errors++;
      if (errors<=40) $display("[%0t] %s g=%b i=%b", $time, nm, g, i); end
  endtask
  task automatic chkv(input string nm, input logic [8:0] g, input logic [8:0] i);
    if (g !== i) begin errors++;
      if (errors<=40) $display("[%0t] %s g=%h i=%h", $time, nm, g, i); end
  endtask

  always @(negedge clk) if (!rst) begin
    cyc++;
    if (cyc > WARMUP) begin
      #4; checks++;
      for (int j=0;j<5;j++) begin
        chk($sformatf("out%0d_valid",j),        g_out_valid[j],       i_out_valid[j]);
        chk($sformatf("fuType_valid%0d",j),      g_fuType_valid[j],    i_fuType_valid[j]);
        chk($sformatf("fuOpType_valid%0d",j),    g_fuOpType_valid[j],  i_fuOpType_valid[j]);
        chkv($sformatf("fuOpType_bits%0d",j),    g_fuOpType_bits[j],   i_fuOpType_bits[j]);
        chk($sformatf("lsrc2_valid%0d",j),       g_lsrc2_valid[j],     i_lsrc2_valid[j]);
        chkv($sformatf("lsrc2_bits%0d",j),       {3'b0,g_lsrc2_bits[j]}, {3'b0,i_lsrc2_bits[j]});
        chk($sformatf("src2Type_valid%0d",j),    g_src2Type_valid[j],  i_src2Type_valid[j]);
        chk($sformatf("selImm_valid%0d",j),      g_selImm_valid[j],    i_selImm_valid[j]);
        chkv($sformatf("selImm_bits%0d",j),      {5'b0,g_selImm_bits[j]}, {5'b0,i_selImm_bits[j]});
        chk($sformatf("rs2FromRs1_%0d",j),       g_rs2FromRs1[j],      i_rs2FromRs1[j]);
        chk($sformatf("rs2FromRs2_%0d",j),       g_rs2FromRs2[j],      i_rs2FromRs2[j]);
        chk($sformatf("rs2FromZero_%0d",j),      g_rs2FromZero[j],     i_rs2FromZero[j]);
        chk($sformatf("clear%0d",j),             g_clear[j],           i_clear[j]);
      end
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
