// =============================================================================
// WrBypass 单态化变体包装层
//
// Chisel 把参数化的 WrBypass 单态化成多个同构模块（WrBypass、WrBypass_32 …）。
// 本文件用 golden RTL 的模块名和端口名包装参数化核心 xs_WrBypass，用于：
//   1) Formality 与 golden 同名顶层直接做等价比对；
//   2) 系统级验证时直接替换 build/rtl 下的同名生成文件。
// 注意 firtool 会裁剪上层未使用的输出端口（WrBypass_41/_43 没有
// io_hit_data_0_valid），包装层须与 golden 实际端口一致。
//
// 变体参数对照（V2R2 KunminghuV2Config）：
//   WrBypass    : 8 项, idx 9b, 1 路 × 3b
//   WrBypass_32 : 8 项, idx 11b, 2 路 × 2b, 带 way 掩码
//   WrBypass_33 : 16 项, idx 8b, 2 路 × 6b, 带 way 掩码
//   WrBypass_41 : 4 项, idx 8b, 1 路 × 2b （valid 输出被裁剪）
//   WrBypass_43 : 4 项, idx 9b, 1 路 × 2b （valid 输出被裁剪）
// =============================================================================

module WrBypass(
  input         clock,
  input         reset,
  input         io_wen,
  input  [8:0]  io_write_idx,
  input  [2:0]  io_write_data_0,
  output        io_hit,
  output        io_hit_data_0_valid,
  output [2:0]  io_hit_data_0_bits
);
  xs_WrBypass #(
    .NUM_ENTRIES(8), .IDX_WIDTH(9), .NUM_WAYS(1), .TAG_WIDTH(0), .DATA_WIDTH(3)
  ) u_core (
    .clock(clock), .reset(reset),
    .io_wen(io_wen),
    .io_write_idx(io_write_idx),
    .io_write_tag(1'b0),
    .io_write_data(io_write_data_0),
    .io_write_way_mask(1'b1),
    .io_hit(io_hit),
    .io_hit_data_valid(io_hit_data_0_valid),
    .io_hit_data_bits(io_hit_data_0_bits)
  );
endmodule

module WrBypass_32(
  input         clock,
  input         reset,
  input         io_wen,
  input  [10:0] io_write_idx,
  input  [1:0]  io_write_data_0,
  input  [1:0]  io_write_data_1,
  input         io_write_way_mask_0,
  input         io_write_way_mask_1,
  output        io_hit,
  output        io_hit_data_0_valid,
  output [1:0]  io_hit_data_0_bits,
  output        io_hit_data_1_valid,
  output [1:0]  io_hit_data_1_bits
);
  xs_WrBypass #(
    .NUM_ENTRIES(8), .IDX_WIDTH(11), .NUM_WAYS(2), .TAG_WIDTH(0), .DATA_WIDTH(2)
  ) u_core (
    .clock(clock), .reset(reset),
    .io_wen(io_wen),
    .io_write_idx(io_write_idx),
    .io_write_tag(1'b0),
    .io_write_data({io_write_data_1, io_write_data_0}),
    .io_write_way_mask({io_write_way_mask_1, io_write_way_mask_0}),
    .io_hit(io_hit),
    .io_hit_data_valid({io_hit_data_1_valid, io_hit_data_0_valid}),
    .io_hit_data_bits({io_hit_data_1_bits, io_hit_data_0_bits})
  );
endmodule

module WrBypass_33(
  input         clock,
  input         reset,
  input         io_wen,
  input  [7:0]  io_write_idx,
  input  [5:0]  io_write_data_0,
  input  [5:0]  io_write_data_1,
  input         io_write_way_mask_0,
  input         io_write_way_mask_1,
  output        io_hit,
  output        io_hit_data_0_valid,
  output [5:0]  io_hit_data_0_bits,
  output        io_hit_data_1_valid,
  output [5:0]  io_hit_data_1_bits
);
  xs_WrBypass #(
    .NUM_ENTRIES(16), .IDX_WIDTH(8), .NUM_WAYS(2), .TAG_WIDTH(0), .DATA_WIDTH(6)
  ) u_core (
    .clock(clock), .reset(reset),
    .io_wen(io_wen),
    .io_write_idx(io_write_idx),
    .io_write_tag(1'b0),
    .io_write_data({io_write_data_1, io_write_data_0}),
    .io_write_way_mask({io_write_way_mask_1, io_write_way_mask_0}),
    .io_hit(io_hit),
    .io_hit_data_valid({io_hit_data_1_valid, io_hit_data_0_valid}),
    .io_hit_data_bits({io_hit_data_1_bits, io_hit_data_0_bits})
  );
endmodule

module WrBypass_41(
  input         clock,
  input         reset,
  input         io_wen,
  input  [7:0]  io_write_idx,
  input  [1:0]  io_write_data_0,
  output        io_hit,
  output [1:0]  io_hit_data_0_bits
);
  xs_WrBypass #(
    .NUM_ENTRIES(4), .IDX_WIDTH(8), .NUM_WAYS(1), .TAG_WIDTH(0), .DATA_WIDTH(2),
    .TRACK_HIT_VALID(1'b0)  // golden 裁剪了 io_hit_data_valid → 不建 valids 死寄存器
  ) u_core (
    .clock(clock), .reset(reset),
    .io_wen(io_wen),
    .io_write_idx(io_write_idx),
    .io_write_tag(1'b0),
    .io_write_data(io_write_data_0),
    .io_write_way_mask(1'b1),
    .io_hit(io_hit),
    .io_hit_data_valid(/* 上层未使用，golden 中已被裁剪 */),
    .io_hit_data_bits(io_hit_data_0_bits)
  );
endmodule

module WrBypass_43(
  input         clock,
  input         reset,
  input         io_wen,
  input  [8:0]  io_write_idx,
  input  [1:0]  io_write_data_0,
  output        io_hit,
  output [1:0]  io_hit_data_0_bits
);
  xs_WrBypass #(
    .NUM_ENTRIES(4), .IDX_WIDTH(9), .NUM_WAYS(1), .TAG_WIDTH(0), .DATA_WIDTH(2),
    .TRACK_HIT_VALID(1'b0)  // golden 裁剪了 io_hit_data_valid → 不建 valids 死寄存器
  ) u_core (
    .clock(clock), .reset(reset),
    .io_wen(io_wen),
    .io_write_idx(io_write_idx),
    .io_write_tag(1'b0),
    .io_write_data(io_write_data_0),
    .io_write_way_mask(1'b1),
    .io_hit(io_hit),
    .io_hit_data_valid(),
    .io_hit_data_bits(io_hit_data_0_bits)
  );
endmodule
