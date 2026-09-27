`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, vectors = 0;
  logic [10:0] a11, b11; logic [7:0] a8, b8;
  logic [63:0] x64, y64; logic [31:0] x32; logic select_nez;
  logic [26:0] sparse27; logic [2:0] packed3; logic [6:0] packed7;
  logic [52:0] f53a, f53b; logic [10:0] f11a, f11b;
  logic [23:0] f24a, f24b;
  wire [10:0] d11; wire [7:0] d8; wire [64:0] d65;
  wire [63:0] add64, cz; wire [31:0] add32;
  wire [2:0] comp3; wire [6:0] comp7; wire [26:0] ext3, ext7;
  wire [53:0] cp53, cp53s; wire [11:0] cp11, cp11s;
  wire [24:0] cp24, cp24s;

  Adder_xs u0(.io_a(a11),.io_b(b11),.io_c(d11));
  Adder_2_xs u1(.io_a(a8),.io_b(b8),.io_c(d8));
  SubModule_xs u2(.io_src_0(x64),.io_src_1(y64),.io_sub(d65));
  AddModule_xs u3(.io_src_0(x64),.io_src_1(y64),.io_srcw(x32),.io_add(add64),.io_addw(add32));
  ConditionalZeroModule_xs u4(.io_condition(x64),.io_value(y64),.io_isNez(select_nez),.io_condRes(cz));
  UIntCompressor_27_000000000000001010100000000_xs u5(.io_in(sparse27),.io_out(comp3));
  UIntCompressor_27_000011100000000000001010101_xs u6(.io_in(sparse27),.io_out(comp7));
  UIntExtractor_27_000000000000001010100000000_xs u7(.io_in(packed3),.io_out(ext3));
  UIntExtractor_27_000011100000000000001010101_xs u8(.io_in(packed7),.io_out(ext7));
  ClosePathAdder_xs u9(.io_adder_op0(f53a),.io_adder_op1(f53b),.io_result(cp53));
  ClosePathAdder_2_xs u10(.io_adder_op0(f53a),.io_adder_op1(f53b),.io_result(cp53s));
  ClosePathAdderF16Pipeline_xs u11(.io_adder_op0(f11a),.io_adder_op1(f11b),.io_result(cp11));
  ClosePathAdderF16Pipeline_2_xs u12(.io_adder_op0(f11a),.io_adder_op1(f11b),.io_result(cp11s));
  ClosePathF32WidenF16MixedPipelineAdder_xs u13(.io_adder_op0(f24a),.io_adder_op1(f24b),.io_result(cp24));
  ClosePathF32WidenF16MixedPipelineAdder_2_xs u14(.io_adder_op0(f24a),.io_adder_op1(f24b),.io_result(cp24s));

  task automatic check_value(input logic condition, input string tag);
    if (!condition) begin errors++; if (errors < 8) $display("mismatch %s vector=%0d",tag,vectors); end
  endtask
  task automatic compare_now;
    logic [26:0] expected3, expected7;
    #1; vectors++; expected3='0; expected7='0;
    expected3[12]=packed3[2]; expected3[10]=packed3[1]; expected3[8]=packed3[0];
    expected7[22:20]=packed7[6:4]; expected7[6]=packed7[3];
    expected7[4]=packed7[2]; expected7[2]=packed7[1]; expected7[0]=packed7[0];
    check_value(d11 === 11'(a11-b11), "Adder");
    check_value(d8 === 8'(a8-b8), "Adder_2");
    check_value(d65 === ({1'b0,x64}-{1'b0,y64}), "SubModule");
    check_value(add64 === x64+y64 && add32 === x32+y64[31:0], "AddModule");
    check_value(cz === (((~(|x64)) ^ select_nez) ? 64'b0 : y64), "ConditionalZero");
    check_value(comp3 === {sparse27[12],sparse27[10],sparse27[8]}, "Compressor3");
    check_value(comp7 === {sparse27[22:20],sparse27[6],sparse27[4],sparse27[2],sparse27[0]}, "Compressor7");
    check_value(ext3 === expected3, "Extractor3"); check_value(ext7 === expected7, "Extractor7");
    check_value(cp53 === {1'b0,f53a}-{1'b0,f53b}, "Close53");
    check_value(cp53s === {f53a,1'b0}-{1'b0,f53b}, "Close53Shift");
    check_value(cp11 === {1'b0,f11a}-{1'b0,f11b}, "Close11");
    check_value(cp11s === {f11a,1'b0}-{1'b0,f11b}, "Close11Shift");
    check_value(cp24 === {1'b0,f24a}-{1'b0,f24b}, "Close24");
    check_value(cp24s === {f24a,1'b0}-{1'b0,f24b}, "Close24Shift");
  endtask
  task automatic randomize_inputs;
    a11=$urandom; b11=$urandom; a8=$urandom; b8=$urandom;
    x64={$urandom,$urandom}; y64={$urandom,$urandom}; x32=$urandom;
    select_nez=$urandom; sparse27=$urandom; packed3=$urandom; packed7=$urandom;
    f53a={$urandom,$urandom}; f53b={$urandom,$urandom};
    f11a=$urandom; f11b=$urandom; f24a=$urandom; f24b=$urandom;
  endtask
  initial begin
    {a11,b11,a8,b8,x64,y64,x32,select_nez,sparse27,packed3,packed7,
     f53a,f53b,f11a,f11b,f24a,f24b}='0; compare_now();
    {a11,b11,a8,b8,x64,y64,x32,select_nez,sparse27,packed3,packed7,
     f53a,f53b,f11a,f11b,f24a,f24b}='1; compare_now();
    repeat(NCYCLES) begin randomize_inputs(); compare_now(); end
    $display("ReadableLeaves15 UT: vectors=%0d module_checks=%0d errors=%0d",vectors,vectors*15,errors);
    if(errors==0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
