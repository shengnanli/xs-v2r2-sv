// =============================================================================
// CryptoModule.sv —— 标量密码扩展（Zkn/Zks）的结果二选一：哈希块 vs 分组密码块
//
// 在哪一层：Bku（位运算/密码功能单元，两拍延迟）的四个运算子块之一。
//   Chisel 源 src/main/scala/xiangshan/backend/fu/Bku.scala `class CryptoModule`。
// 结构（照 Scala 逐句）：
//   * HashModule        吃 src0，算 SHA-256/512 的 Σ/σ 与 SM3 的 P0/P1，内部打一拍；
//   * BlockCipherModule 吃 src0/src1，算 AES / SM4 单轮部件，内部同样打一拍；
//   * 两个子块与本层都用同一个 func 与 regEnable：func 在 regEnable 拍被锁进 funcReg，
//     下一拍按 funcReg[4] 选结果（BKUOpType 里哈希类编码 0b11_0xxx 的 bit4=1，
//     分组密码类 0b10_xxxx 的 bit4=0）。
// 怪癖：funcReg 照 golden 存满 9 位、无复位，但只有 bit4 被读；其余 8 位两侧同为死位
//   （FM 里由 verif/fm_target_config/CryptoModule.tcl 的 vmucp 条目让它们照样被比较）。
// 子模块：HashModule / BlockCipherModule（本仓重写件，实例名与 golden 一致）。
// golden 对照：G1-canonical/golden-rtl/CryptoModule.sv（138 行）
// =============================================================================
module CryptoModule (
  input  logic        clock,
  input  logic [63:0] io_src_0,
  input  logic [63:0] io_src_1,
  input  logic [8:0]  io_func,
  input  logic        io_regEnable,
  output logic [63:0] io_out
);

  // ---- 两个实现子块：同拍收操作数与功能码，各自打一拍出结果 ----
  logic [63:0] hash_out;
  logic [63:0] cipher_out;

  HashModule hashModule (
    .clock        (clock),
    .io_src       (io_src_0),
    .io_func      (io_func),
    .io_regEnable (io_regEnable),
    .io_out       (hash_out)
  );

  BlockCipherModule blockCipherModule (
    .clock        (clock),
    .io_src_0     (io_src_0),
    .io_src_1     (io_src_1),
    .io_func      (io_func),
    .io_regEnable (io_regEnable),
    .io_out       (cipher_out)
  );

  // ---- 功能码随数据一起打一拍（RegEnable，无复位），下一拍据此选结果 ----
  logic [8:0] funcReg;
  always_ff @(posedge clock) begin
    if (io_regEnable)
      funcReg <= io_func;
  end

  // funcReg[4]=1：哈希类（sha256*/sha512*/sm3*）；=0：分组密码类（aes*/sm4*）
  assign io_out = funcReg[4] ? hash_out : cipher_out;

endmodule
