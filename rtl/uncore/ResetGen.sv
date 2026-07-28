// =============================================================================
//  ResetGen —— 复位同步生成器 (可读核 xs_ResetGen_core + golden 同名 wrapper)
// -----------------------------------------------------------------------------
//  XSTop 各子域 (XSTile / L2 / uncore) 的复位打拍生成器: 把外部异步复位打成一条
//  3 级同步链, 输出 o_reset 在复位撤除后再延迟 3 拍才拉低 (保证下游先看到复位、
//  且复位撤除沿被时钟同步), 避免亚稳态/复位撤除竞争。
//
//  golden 语义 (异步 set / 同步 shift):
//    always @(posedge clock or posedge reset)
//      if (reset)  pipe_reset <= 3'h7;                 // 复位时整链置 1
//      else        pipe_reset <= {pipe_reset[1:0], 1'h0}; // 每拍左移进 0
//    o_reset = pipe_reset[2];                          // 取最深一级
//  复位撤除后: 7 -> 6(110) -> 4(100) -> 0, o_reset 连续 3 拍为 1 再拉低。
//
//  纯叶子, 无子例化。UT 双例化逐拍对拍 (随机 reset 脉冲遍历撤除相位);
//  FM 逐位等价 signoff-strict。无 _GEN_/_T_ 噪声。
// =============================================================================
module xs_ResetGen_core(
  input  clock,
  input  reset,
  output o_reset
);
  // 3 级复位同步链: 复位异步置全 1, 撤除后每拍左移进 0。
  reg [2:0] pipe_reset;
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      pipe_reset <= 3'h7;
    else
      pipe_reset <= {pipe_reset[1:0], 1'h0};
  end
  assign o_reset = pipe_reset[2];
endmodule

// golden 同名 wrapper。
module ResetGen(
  input  clock,
  input  reset,
  output o_reset
);
  xs_ResetGen_core u_core (
    .clock  (clock),
    .reset  (reset),
    .o_reset(o_reset)
  );
endmodule
