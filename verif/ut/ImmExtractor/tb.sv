// =============================================================================
// tb —— ImmExtractor UT:golden vs 可读核,逐拍逐输出比对。
// ImmExtractor 为纯组合叶子:每拍随机驱动 imm(32 位压缩立即数)与 immType
// (4 位类型码),组合稳定后比对输出。
// 同时验两个变体:
//   u_g0/u_i0  : ImmExtractor      (整数最小集, 64 位)
//   u_g1/u_i1  : ImmExtractor_12   (全类型集, 128 位)
// 激励:immType 多数从合法类型表取(全覆盖每种类型,含本变体未使能的类型——
//   未使能时 golden 与核都应输出 0),少数取完全随机 4 位值;imm 混合全随机
//   与边界(0/全1/各字段符号边界)。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  // 全部 13 种合法 selImm 类型码(见 SelImm)。
  localparam int NT = 13;
  logic [3:0] TYPES [NT] = '{
    4'h1, 4'h2, 4'h3, 4'h4, 4'h5, 4'h8, 4'h9, 4'hA, 4'hB, 4'hC, 4'hD, 4'hE, 4'hF
  };

  logic [31:0] io_in_imm;
  logic [3:0]  io_in_immType;

  logic [63:0]  g0_out, i0_out;
  logic [127:0] g1_out, i1_out;

  // 变体 1:64 位整数最小集
  ImmExtractor    u_g0 (.io_in_imm(io_in_imm), .io_in_immType(io_in_immType), .io_out_imm(g0_out));
  ImmExtractor_xs u_i0 (.io_in_imm(io_in_imm), .io_in_immType(io_in_immType), .io_out_imm(i0_out));
  // 变体 2:128 位全类型集
  ImmExtractor_12    u_g1 (.io_in_imm(io_in_imm), .io_in_immType(io_in_immType), .io_out_imm(g1_out));
  ImmExtractor_12_xs u_i1 (.io_in_imm(io_in_imm), .io_in_immType(io_in_immType), .io_out_imm(i1_out));

  // 32 位随机立即数(混合边界值,触发各类型符号位边界)。
  function automatic logic [31:0] rand_imm();
    int unsigned sel = $urandom_range(0, 7);
    case (sel)
      0: return 32'h0;
      1: return '1;
      2: return 32'h0000_0800;  // bit11 = 符号位(I/S)
      3: return 32'h0008_0000;  // bit19 = 符号位(U/UJ)
      4: return 32'h8000_0000;  // bit31 = 符号位(LUI32)
      5: return 32'h0000_4000;  // bit14 = 符号位(VSETIVLI)
      default: return $urandom;
    endcase
  endfunction

  task automatic drive_inputs();
    int unsigned pick = $urandom_range(0, 99);
    if (pick < 85)
      io_in_immType = TYPES[$urandom_range(0, NT-1)];   // 定向覆盖每种类型
    else
      io_in_immType = $urandom_range(0, 15);            // 随机 4 位(含 0/6/7 非法码)
    io_in_imm = rand_imm();
  endtask

  `define CK(g,i,nm) \
    if (!$isunknown(g) && (g) !== (i)) begin errors++; \
      if (errors<=60) $display("[%0t] %s g=%h i=%h (immType=%h imm=%h)", $time, nm, g, i, \
        io_in_immType, io_in_imm); end \
    checks++;

  task automatic check_outputs();
    `CK(g0_out, i0_out, "var0_out64")
    `CK(g1_out, i1_out, "var1_out128")
  endtask

  initial begin
    drive_inputs();
    repeat (NCYCLES) begin
      @(posedge clk);
      #1 check_outputs();
      drive_inputs();
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
