// =============================================================================
//  arbiter4_pkg / xs_arbiter4_core —— 4 输入固定优先级仲裁器公共逻辑
// -----------------------------------------------------------------------------
//  对应 Chisel `chisel3.util.Arbiter(gen, 4)` 经 firtool 展开的 golden
//  `Arbiter4_{L2CacheErrorInfo, L2ToL1Hint, ...}`。这些实例在 payload 位宽及
//  是否引出 ready/chosen 端口上略有差异, 但仲裁算法完全一致 —— 本核把该逻辑
//  抽出参数化复用 (payload 打成扁平 WIDTH 位向量, 由各实例 wrapper 做
//  concat/slice, 与 golden 逐位一致)。
//
//  纯组合, 无状态寄存器, 无 clock/reset。固定优先级 (低下标优先):
//    io_in_0_ready = io_out_ready
//    io_in_i_ready = ~(io_in_0_valid | ... | io_in_{i-1}_valid) & io_out_ready
//    io_out_valid  = |{io_in_0_valid ... io_in_3_valid}
//    io_out_bits   = 第一个 valid 的输入 payload (priority-mux, 全 0 时取 io_in_3)
//    io_chosen     = 第一个 valid 输入的下标 (全 0 时退化为 3), 与 golden
//                    `io_in_0_valid ? 0 : io_in_1_valid ? 1 : {1'h1, ~io_in_2_valid}`
//                    逐位一致。
//  与 golden 的级联前缀-OR ready 链、逐字段三元 priority-mux 逐位等价。
//
//  某些实例 (如 L2CacheErrorInfo) golden 未引出 ready/chosen 端口; 对应 wrapper
//  只是不连接这些核输出 (悬空), 不影响 io_out_valid / io_out_bits 的比对。
// =============================================================================
package arbiter4_pkg;
  localparam int unsigned NUM = 4;
endpackage

module xs_arbiter4_core #(
  parameter int unsigned WIDTH = 1     // 单输入 payload 位宽
) (
  input  logic [3:0]         valids,     // {in3..in0}_valid
  input  logic               out_ready,
  input  logic [WIDTH-1:0]   pin [4],    // 各输入 payload
  output logic [3:0]         readies,    // {in3..in0}_ready
  output logic               out_valid,
  output logic [WIDTH-1:0]   pout,       // 选中 payload
  output logic [1:0]         chosen      // 选中输入下标
);
  import arbiter4_pkg::*;

  // 前缀-OR: prefix[i] = OR(valids[i-1:0]) = "有更高优先级的输入 valid"。
  logic [3:0] prefix;
  always_comb begin
    prefix[0] = 1'b0;
    for (int i = 1; i < NUM; i++)
      prefix[i] = prefix[i-1] | valids[i-1];
  end

  // 第 i 路 ready = 没有更高优先级 valid 且下游 ready。
  always_comb
    for (int i = 0; i < NUM; i++)
      readies[i] = ~prefix[i] & out_ready;

  assign out_valid = |valids;

  // priority-mux: 取最低下标 valid 的 payload; 全 0 时退化为 io_in_3 (与 golden 末项一致)。
  always_comb begin
    pout = pin[NUM-1];
    for (int i = NUM-1; i >= 0; i--)
      if (valids[i]) pout = pin[i];
  end

  // chosen: 与 golden `in0?0 : in1?1 : {1'h1, ~in2}` 逐位一致 —— 全 0 或仅 in3 时为 3,
  // 仅 in2(或更高)时为 2。等价于 priority-encoder 全 0 默认 3。
  assign chosen = valids[0] ? 2'h0 : valids[1] ? 2'h1 : {1'h1, ~valids[2]};
endmodule
