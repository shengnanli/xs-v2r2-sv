// =============================================================================
//  IntBuffer —— 中断信号缓冲寄存器 (可读核 xs_IntBuffer_core + golden 同名 wrapper)
// -----------------------------------------------------------------------------
//  XSTile 中断通路上的一级打拍缓冲: 把外部 (uncore/PLIC 侧) 送来的单比特中断线
//  auto_in_0 打一拍再输出 auto_out_0, 隔离时序 / 同步跨模块中断脉冲。
//
//  golden 语义 (异步复位):
//    always @(posedge clock or posedge reset)
//      if (reset) REG_0 <= 1'h0; else REG_0 <= auto_in_0;
//    auto_out_0 = REG_0;                    // 单拍延迟
//
//  纯叶子, 无子例化。UT 双例化逐拍对拍; FM 逐位等价 signoff-strict。无 _GEN_/_T_。
// =============================================================================
module xs_IntBuffer_core(
  input  clock,
  input  reset,
  input  auto_in_0,
  output auto_out_0
);
  // 单比特中断线打一拍 (异步复位清 0)。
  reg REG_0;
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      REG_0 <= 1'h0;
    else
      REG_0 <= auto_in_0;
  end
  assign auto_out_0 = REG_0;
endmodule

// golden 同名 wrapper。
module IntBuffer(
  input  clock,
  input  reset,
  input  auto_in_0,
  output auto_out_0
);
  xs_IntBuffer_core u_core (
    .clock     (clock),
    .reset     (reset),
    .auto_in_0 (auto_in_0),
    .auto_out_0(auto_out_0)
  );
endmodule
