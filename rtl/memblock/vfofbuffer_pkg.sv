// xs_vfofbuffer_pkg —— VfofBuffer(向量 fault-only-first 缓冲)可读核公共定义
// 手写重写, bug-for-bug 对齐 golden VfofBuffer.sv。无 SRAM/子模块。
`ifndef XS_VFOFBUFFER_PKG_SV
`define XS_VFOFBUFFER_PKG_SV
package xs_vfofbuffer_pkg;

  // ROB 索引位宽(flag + 8bit value)
  localparam int ROB_VALUE_W = 8;

endpackage
`endif
