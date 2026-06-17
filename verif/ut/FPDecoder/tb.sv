// =============================================================================
// tb —— FPDecoder UT:golden FPDecoder (u_g) vs 可读核 FPDecoder_xs (u_i)。
// 纯组合:每拍驱动一个 32 位指令编码,组合稳定后逐输出比对。
// 激励:大概率从"合法浮点指令编码生成器"取(覆盖 single/double/half 全部
//   FADD/FSUB/FMUL/FDIV/FSQRT/SGNJ/MIN/MAX/CMP/FCLASS/FMV/各 FCVT/FMADD 系列,
//   并在 don't-care 位(rs1/rs2/rm/rd)填随机);小概率全随机指令。
// 比对用 !$isunknown 跳过 golden 的 don't-care(typeTagOut 默认 "??")。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic [31:0] io_instr;
  logic [1:0]  g_tag, i_tag, g_typ, i_typ, g_fmt, i_fmt;
  logic        g_wf, i_wf;
  logic [2:0]  g_rm, i_rm;

  FPDecoder u_g (
    .io_instr(io_instr),
    .io_fpCtrl_typeTagOut(g_tag), .io_fpCtrl_wflags(g_wf),
    .io_fpCtrl_typ(g_typ), .io_fpCtrl_fmt(g_fmt), .io_fpCtrl_rm(g_rm)
  );
  FPDecoder_xs u_i (
    .io_instr(io_instr),
    .io_fpCtrl_typeTagOut(i_tag), .io_fpCtrl_wflags(i_wf),
    .io_fpCtrl_typ(i_typ), .io_fpCtrl_fmt(i_fmt), .io_fpCtrl_rm(i_rm)
  );

  // ---- 合法浮点指令编码生成 ----
  // funct7 高 5 位(对应 [31:27])选大类,bit[26:25]=fmt(00=S,01=D,10=H)。
  // OP-FP opcode = 1010011。
  localparam logic [6:0] OPFP = 7'b1010011;

  // 大类的 funct7[6:2] 取值表(与 RTL 一致)。
  localparam int NCLS = 12;
  logic [4:0] CLS [NCLS] = '{
    5'b00000, // ADD
    5'b00001, // SUB
    5'b00010, // MUL
    5'b00011, // DIV
    5'b01011, // SQRT (rs2=0)
    5'b00100, // SGNJ
    5'b00101, // MIN/MAX
    5'b01000, // FCVT.fp.fp
    5'b10100, // FEQ/FLT/FLE
    5'b11100, // FMV.X / FCLASS
    5'b11110, // FMV.fp.X
    5'b11000  // FCVT.int.fp (与 11010 互补,这里随机选)
  };

  function automatic logic [31:0] gen_fp_instr();
    logic [4:0] f7hi = CLS[$urandom_range(0, NCLS-1)];
    logic [1:0] fmt2 = $urandom_range(0, 2);          // S/D/H
    logic [2:0] f3   = $urandom;                       // rm / 比较子码
    logic [4:0] rs2v = $urandom;
    logic [4:0] rs1v = $urandom;
    logic [4:0] rdv  = $urandom;
    logic [6:0] opc;
    logic [6:0] f7;
    int pick = $urandom_range(0, 9);
    // 偶尔生成 FMADD 系列(R4-type,opcode 1000x11)
    if (pick < 2) begin
      logic [6:0] madds [4] = '{7'b1000011,7'b1000111,7'b1001011,7'b1001111};
      logic [4:0] rs3v = $urandom;
      opc = madds[$urandom_range(0,3)];
      if (fmt2 == 2'b11) fmt2 = 2'b00;           // 跳过非法宽度
      // R4-type 布局:rs3[31:27] fmt[26:25] rs2[24:20] rs1[19:15] rm[14:12] rd[11:7] opcode[6:0]
      return {rs3v, fmt2, rs2v, rs1v, f3, rdv, opc};
    end
    // 偶尔切到 FCVT.int.fp(11010)
    if (f7hi == 5'b11000 && ($urandom & 1)) f7hi = 5'b11010;
    // 只生成 **合法编码**(off-set 是设计 don't-care,golden 经最小化后
    // 取值任意,无意义比对);故各类的固定子码 rs2/funct3 取合法值。
    if (f7hi == 5'b01011) rs2v = 5'd0;               // SQRT rs2=0
    if (f7hi == 5'b11110) begin rs2v = 5'd0; f3 = 3'b000; end // FMV.fp.X
    if (f7hi == 5'b11100) begin rs2v = 5'd0; f3 = ($urandom&1)?3'b001:3'b000; end // FCLASS/FMV.X
    if (f7hi == 5'b11000 || f7hi == 5'b11010) rs2v = $urandom_range(0,3); // FCVT.int<->fp 子码 0..3
    if (f7hi == 5'b01000) rs2v = $urandom_range(0,2); // FCVT.fp.fp 源族 0..2
    if (f7hi == 5'b00100) f3 = $urandom_range(0,2);   // SGNJ/N/X
    if (f7hi == 5'b00101) f3 = $urandom_range(0,1);   // MIN/MAX
    if (f7hi == 5'b10100) f3 = $urandom_range(0,2);   // FEQ/FLT/FLE
    // fmt2=11 是非法浮点宽度(off-set),不生成
    if (fmt2 == 2'b11) fmt2 = 2'b00;
    f7 = {f7hi, fmt2};
    return {f7, rs2v, rs1v, f3, rdv, OPFP};
  endfunction

  task automatic drive();
    // 只喂合法浮点指令编码:FPDecoder 对非浮点/非法编码的输出是设计
    // don't-care(golden 经 DecodeLogic 最小化后取值任意),比对无意义。
    io_instr = gen_fp_instr();
  endtask

  `define CK(g,i,nm) \
    if (!$isunknown(g) && (g) !== (i)) begin errors++; \
      if (errors<=60) $display("[%0t] %s g=%h i=%h (instr=%h)", $time, nm, g, i, io_instr); end \
    checks++;

  task automatic check();
    `CK(g_tag, i_tag, "typeTagOut")
    `CK(g_wf,  i_wf,  "wflags")
    `CK(g_typ, i_typ, "typ")
    `CK(g_fmt, i_fmt, "fmt")
    `CK(g_rm,  i_rm,  "rm")
  endtask

  initial begin
    drive();
    repeat (NCYCLES) begin
      @(posedge clk);
      #1 check();
      drive();
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
