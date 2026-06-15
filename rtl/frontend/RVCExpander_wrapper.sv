// =============================================================================
// RVCExpander —— golden 同名顶层包装（端口与 golden 完全一致，供 FM/ST 对接）
//
// 可读核 xs_RVCExpander_core 的端口本就是扁平标量（与 golden 同形），故本包装层
// 是机械的直通例化。FM 用本模块（impl 侧）与 golden 的 RVCExpander（ref 侧）做
// 签名等价比对；UT 则直接例化 golden RVCExpander 与可读核 xs_RVCExpander_core 双例
// 比对，不经本包装层（避免与 golden 同名模块在同一编译单元冲突）。
// =============================================================================
module RVCExpander (
  input  [31:0] io_in,
  input         io_fsIsOff,
  output [31:0] io_out_bits,
  output        io_ill
);
  xs_RVCExpander_core u_core (
    .io_in       (io_in),
    .io_fsIsOff  (io_fsIsOff),
    .io_out_bits (io_out_bits),
    .io_ill      (io_ill)
  );
endmodule
