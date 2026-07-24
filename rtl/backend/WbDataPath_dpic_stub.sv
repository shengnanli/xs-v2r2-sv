// =============================================================================
// DummyDPICWrapper_* —— difftest 探针空体 stub(由 gen_wbdatapath.py 从 golden 模块头生成)
// -----------------------------------------------------------------------------
// WbDataPath 在 EnableDifftest 时为每个写回出口例化一个 DummyDPICWrapper(内含 DPI-C
// 的 DiffXxxWriteback), 把仲裁器胜出的写回结果送给 difftest 框架做指令级比对。
// 这些实例是**纯 sink**: 只有输入端口, 不驱动 WbDataPath 的任何输出, 对功能行为无影响。
//
// 仅供 UT 双例化链接(golden DUT 与可读 DUT 共用)。FM 两侧都不读本文件 →
// hdlin_unresolved_modules=black_box 使 26 个实例在 ref/impl 对称黑盒、引脚按名配对。
// =============================================================================

module DummyDPICWrapper_44(
  input        clock,
  input        io_valid,
  input        io_bits_valid,
  input [7:0]  io_bits_address,
  input [63:0] io_bits_data,
  input [7:0]  io_bits_coreid
);
endmodule

module DummyDPICWrapper_52(
  input        clock,
  input        io_valid,
  input        io_bits_valid,
  input [7:0]  io_bits_address,
  input [63:0] io_bits_data,
  input [7:0]  io_bits_coreid
);
endmodule

module DummyDPICWrapper_58(
  input        clock,
  input        io_valid,
  input        io_bits_valid,
  input [6:0]  io_bits_address,
  input [63:0] io_bits_data_0,
  input [63:0] io_bits_data_1,
  input [7:0]  io_bits_coreid
);
endmodule

module DummyDPICWrapper_64(
  input        clock,
  input        io_valid,
  input        io_bits_valid,
  input [4:0]  io_bits_address,
  input [63:0] io_bits_data_0,
  input [63:0] io_bits_data_1,
  input [7:0]  io_bits_coreid
);
endmodule
