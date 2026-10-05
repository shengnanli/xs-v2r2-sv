// =============================================================================
// VecDataSplitModule.sv —— 把一个 128 位向量寄存器按四种元素宽度同时切开
//
// 在哪一层：向量 FU 外壳（VIAluFix / VFAlu / VFMA / VFDivSqrt 等）里，用来把 vs1 / vs2 /
//   oldVd 等 128 位源操作数切成 8/16/32/64 位元素视图，供外壳按 SEW 挑元素或拼结果。
// 机制：纯组合、无状态、无子模块。RVV 寄存器内元素按小端排列——第 k 个 SEW 位元素占
//   [SEW*(k+1)-1 : SEW*k]。四种视图同时给出（16×8b / 8×16b / 4×32b / 2×64b），谁用谁挑。
// 设计源：src/main/scala/xiangshan/backend/fu/vector/utils/VecDataSplitModule.scala
//   （inDataWidth=128、outDataWidth=64 的实例化；Chisel 对每种宽度 asTypeOf(Vec)）。
// golden 对照：G1-canonical/golden-rtl/VecDataSplitModule.sv
// =============================================================================

// -----------------------------------------------------------------------------
// xs_VecDataSplitModule_core —— 可读核：packed 数组的元素顺序正好就是小端元素顺序，
//   所以「切开」就是把同一组 128 位按不同的元素宽度重新解释一次。
// -----------------------------------------------------------------------------
module xs_VecDataSplitModule_core (
  input  logic [127:0]      vec,
  output logic [15:0][7:0]  elem8,    // elem8[k]  = vec[8k+7  : 8k]
  output logic [7:0][15:0]  elem16,   // elem16[k] = vec[16k+15: 16k]
  output logic [3:0][31:0]  elem32,   // elem32[k] = vec[32k+31: 32k]
  output logic [1:0][63:0]  elem64    // elem64[k] = vec[64k+63: 64k]
);
  assign elem8  = vec;
  assign elem16 = vec;
  assign elem32 = vec;
  assign elem64 = vec;
endmodule

// -----------------------------------------------------------------------------
// VecDataSplitModule —— golden 同名 wrapper：端口逐位同名，把数组元素展平成 io_outVec<W>b_<k>
// -----------------------------------------------------------------------------
module VecDataSplitModule (
  input  logic [127:0] io_inVecData,
  output logic [7:0]   io_outVec8b_0,
  output logic [7:0]   io_outVec8b_1,
  output logic [7:0]   io_outVec8b_2,
  output logic [7:0]   io_outVec8b_3,
  output logic [7:0]   io_outVec8b_4,
  output logic [7:0]   io_outVec8b_5,
  output logic [7:0]   io_outVec8b_6,
  output logic [7:0]   io_outVec8b_7,
  output logic [7:0]   io_outVec8b_8,
  output logic [7:0]   io_outVec8b_9,
  output logic [7:0]   io_outVec8b_10,
  output logic [7:0]   io_outVec8b_11,
  output logic [7:0]   io_outVec8b_12,
  output logic [7:0]   io_outVec8b_13,
  output logic [7:0]   io_outVec8b_14,
  output logic [7:0]   io_outVec8b_15,
  output logic [15:0]  io_outVec16b_0,
  output logic [15:0]  io_outVec16b_1,
  output logic [15:0]  io_outVec16b_2,
  output logic [15:0]  io_outVec16b_3,
  output logic [15:0]  io_outVec16b_4,
  output logic [15:0]  io_outVec16b_5,
  output logic [15:0]  io_outVec16b_6,
  output logic [15:0]  io_outVec16b_7,
  output logic [31:0]  io_outVec32b_0,
  output logic [31:0]  io_outVec32b_1,
  output logic [31:0]  io_outVec32b_2,
  output logic [31:0]  io_outVec32b_3,
  output logic [63:0]  io_outVec64b_0,
  output logic [63:0]  io_outVec64b_1
);
  logic [15:0][7:0] elem8;
  logic [7:0][15:0] elem16;
  logic [3:0][31:0] elem32;
  logic [1:0][63:0] elem64;

  xs_VecDataSplitModule_core u_core (
    .vec    (io_inVecData),
    .elem8  (elem8),
    .elem16 (elem16),
    .elem32 (elem32),
    .elem64 (elem64)
  );

  assign io_outVec8b_0 = elem8[0];
  assign io_outVec8b_1 = elem8[1];
  assign io_outVec8b_2 = elem8[2];
  assign io_outVec8b_3 = elem8[3];
  assign io_outVec8b_4 = elem8[4];
  assign io_outVec8b_5 = elem8[5];
  assign io_outVec8b_6 = elem8[6];
  assign io_outVec8b_7 = elem8[7];
  assign io_outVec8b_8 = elem8[8];
  assign io_outVec8b_9 = elem8[9];
  assign io_outVec8b_10 = elem8[10];
  assign io_outVec8b_11 = elem8[11];
  assign io_outVec8b_12 = elem8[12];
  assign io_outVec8b_13 = elem8[13];
  assign io_outVec8b_14 = elem8[14];
  assign io_outVec8b_15 = elem8[15];
  assign io_outVec16b_0 = elem16[0];
  assign io_outVec16b_1 = elem16[1];
  assign io_outVec16b_2 = elem16[2];
  assign io_outVec16b_3 = elem16[3];
  assign io_outVec16b_4 = elem16[4];
  assign io_outVec16b_5 = elem16[5];
  assign io_outVec16b_6 = elem16[6];
  assign io_outVec16b_7 = elem16[7];
  assign io_outVec32b_0 = elem32[0];
  assign io_outVec32b_1 = elem32[1];
  assign io_outVec32b_2 = elem32[2];
  assign io_outVec32b_3 = elem32[3];
  assign io_outVec64b_0 = elem64[0];
  assign io_outVec64b_1 = elem64[1];
endmodule
