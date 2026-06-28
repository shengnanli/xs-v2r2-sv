// =============================================================================
// DummyDPICWrapper_* —— difftest 探针黑盒 stub
// -----------------------------------------------------------------------------
// WbDataPath 在 EnableDifftest 时为每个写回出口例化一个 DummyDPICWrapper(内含 DPI-C
// 的 DiffXxxWriteback), 把仲裁器胜出的写回结果送给 difftest 框架做指令级比对。
// 这些实例是**纯 sink**: 只有输入, 不驱动 WbDataPath 的任何输出端口, 对功能行为无影响。
//
// 因其依赖 DPI-C difftest 运行时, UT/FM 中把它当**黑盒**: 这里给出空实现 stub(端口
// 与 golden 逐一对齐, 体内不做任何事)。golden DUT 与可读 DUT 在 UT 中共用这份 stub,
// FM 时两侧共享同一黑盒。共 4 个位宽变体(_24/_32 标量 8b 地址; _38 向量 7b 地址双数据;
// _44 向量 5b 地址双数据)。
// =============================================================================

module DummyDPICWrapper_24_wbdp(
  input        clock,
  input        io_valid,
  input        io_bits_valid,
  input [7:0]  io_bits_address,
  input [63:0] io_bits_data,
  input [7:0]  io_bits_coreid
);
endmodule

module DummyDPICWrapper_32_wbdp(
  input        clock,
  input        io_valid,
  input        io_bits_valid,
  input [7:0]  io_bits_address,
  input [63:0] io_bits_data,
  input [7:0]  io_bits_coreid
);
endmodule

module DummyDPICWrapper_38_wbdp(
  input        clock,
  input        io_valid,
  input        io_bits_valid,
  input [6:0]  io_bits_address,
  input [63:0] io_bits_data_0,
  input [63:0] io_bits_data_1,
  input [7:0]  io_bits_coreid
);
endmodule

module DummyDPICWrapper_44_wbdp(
  input        clock,
  input        io_valid,
  input        io_bits_valid,
  input [4:0]  io_bits_address,
  input [63:0] io_bits_data_0,
  input [63:0] io_bits_data_1,
  input [7:0]  io_bits_coreid
);
endmodule
