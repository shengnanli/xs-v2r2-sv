// =============================================================================
//  arbiter8_pkg / xs_arbiter8_core —— 8 输入固定优先级仲裁器公共逻辑
// -----------------------------------------------------------------------------
//  对应 Chisel `chisel3.util.Arbiter(gen, 8)` 经 firtool 展开的 golden
//  `Arbiter8_{CHIDAT,TLBundleD,...}`。这些实例只在 payload 位宽上不同, 仲裁算法
//  完全一致 —— 本核把该逻辑抽出参数化复用 (payload 打成扁平 WIDTH 位向量, 由各实例
//  wrapper 做 concat/slice, 与 golden 逐位一致)。
//
//  纯组合, 无状态寄存器, 无 clock/reset。固定优先级 (低下标优先):
//    io_in_0_ready = io_out_ready
//    io_in_i_ready = ~(io_in_0_valid | ... | io_in_{i-1}_valid) & io_out_ready
//    io_out_valid  = |{io_in_0_valid ... io_in_7_valid}
//    io_out_bits   = 第一个 valid 的输入 payload (priority-mux, 全 0 时取 io_in_7)
//  与 golden 的级联前缀-OR ready 链、逐字段三元 priority-mux 逐位等价。
// =============================================================================
package arbiter8_pkg;
  localparam int unsigned NUM = 8;
endpackage

module xs_arbiter8_core #(
  parameter int unsigned WIDTH = 1     // 单输入 payload 位宽
) (
  input  logic [7:0]         valids,     // {in7..in0}_valid
  input  logic               out_ready,
  input  logic [WIDTH-1:0]   pin [8],    // 各输入 payload
  output logic [7:0]         readies,    // {in7..in0}_ready
  output logic               out_valid,
  output logic [WIDTH-1:0]   pout        // 选中 payload
);
  import arbiter8_pkg::*;

  // 前缀-OR: prefix[i] = OR(valids[i-1:0]) = "有更高优先级的输入 valid"。
  logic [7:0] prefix;
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

  // priority-mux: 取最低下标 valid 的 payload; 全 0 时退化为 io_in_7 (与 golden 末项一致)。
  always_comb begin
    pout = pin[NUM-1];
    for (int i = NUM-1; i >= 0; i--)
      if (valids[i]) pout = pin[i];
  end
endmodule
