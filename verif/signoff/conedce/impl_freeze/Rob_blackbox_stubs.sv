// =====================================================================
// Rob_blackbox_stubs —— ROB 顶层例化的「difftest 探针」空 sink 黑盒
// ---------------------------------------------------------------------
// 这些模块在 golden 顶层 Rob.sv 内被例化, 仅用于 difftest 仿真探针(把提交流
// 经 DPI-C 送给参考模型比对), 对 RTL 功能无任何反向作用——是纯 sink。
// 在可读核 + wrapper 的 FM/ST 流程里给出与 golden 同名、同端口的空壳, 让综合/
// 形式工具把它们当黑盒(两侧共享同一空实现即可配平)。
//
// 注: 端口列表随 difftest 配置而变, 这里仅给出占位骨架; 实际 FM/UT 接 golden
// 同名文件(golden/chisel-rtl/DummyDPICWrapper*.sv / DelayReg*.sv) 作两侧共享黑盒
// 更稳妥(见 verif/ut/Rob/Makefile 注释)。本文件用于无 golden 时的独立编译占位。
// =====================================================================

// difftest DPI-C 包装(空 sink): 吃掉所有输入, 无输出影响。
module DummyDPICWrapper_stub #(parameter int WIDTH = 1) (
  input  logic              clock,
  input  logic              reset,
  input  logic [WIDTH-1:0]  io_in
);
  // 纯 sink: 无逻辑。
endmodule

// DelayReg: difftest 用的延迟寄存器(把提交信息打 N 拍再送 DPI)。空壳占位。
module DelayReg_stub #(parameter int WIDTH = 1, parameter int DELAY = 3) (
  input  logic              clock,
  input  logic              reset,
  input  logic [WIDTH-1:0]  io_in,
  output logic [WIDTH-1:0]  io_out
);
  logic [WIDTH-1:0] pipe [DELAY];
  always_ff @(posedge clock) begin
    pipe[0] <= io_in;
    for (int i = 1; i < DELAY; i++) pipe[i] <= pipe[i-1];
  end
  assign io_out = pipe[DELAY-1];
endmodule
