// =============================================================================
// HashModule.sv —— 哈希单步子块：SHA-256 / SHA-512 的 Σ/σ 与 SM3 的 P0/P1（Zknh / Zksh）
//
// 位置：Bku → CryptoModule 下的两个实现叶子之一（另一个是 BlockCipherModule），
//   只吃 rs1（io_src）。Chisel 源 src/main/scala/xiangshan/backend/fu/Bku.scala
//   `class HashModule`。结果算完直接打一拍（RegEnable，不复位）输出；
//   CryptoModule 再按拍下来的 func[4] 在本块与分组密码块之间二选一。
//
// 它算的是哈希压缩函数里"一个字的线性混合"这一步，全部是循环移位 / 逻辑右移的异或：
//   func[3]=0（SHA，func[2:0] 选 8 个之一，BKUOpType sha256sum0=110000 … sha512sig1=110111）
//     0 sha256sum0 = ROR32(x, 2) ^ ROR32(x,13) ^ ROR32(x,22)
//     1 sha256sum1 = ROR32(x, 6) ^ ROR32(x,11) ^ ROR32(x,25)
//     2 sha256sig0 = ROR32(x, 7) ^ ROR32(x,18) ^ SHR32(x, 3)
//     3 sha256sig1 = ROR32(x,17) ^ ROR32(x,19) ^ SHR32(x,10)
//     4 sha512sum0 = ROR64(x,28) ^ ROR64(x,34) ^ ROR64(x,39)
//     5 sha512sum1 = ROR64(x,14) ^ ROR64(x,18) ^ ROR64(x,41)
//     6 sha512sig0 = ROR64(x, 1) ^ ROR64(x, 8) ^ SHR64(x, 7)
//     7 sha512sig1 = ROR64(x,19) ^ ROR64(x,61) ^ SHR64(x, 6)
//   func[3]=1（SM3，func[0] 选 sm3p0=111000 / sm3p1=111001）
//     P0 = x ^ ROL32(x, 9) ^ ROL32(x,17)   （Chisel 写成 ROR32(x,23) ^ ROR32(x,15) ^ x）
//     P1 = x ^ ROL32(x,15) ^ ROL32(x,23)   （Chisel 写成 ROR32(x, 9) ^ ROR32(x,17) ^ x）
//   32 位结果一律符号扩展到 64 位（RV64 的 *W 语义）。
// =============================================================================

module xs_HashModule_core (
  input  logic        clock,
  input  logic [63:0] src,
  input  logic [8:0]  func,
  input  logic        reg_enable,
  output logic [63:0] out
);

  function automatic logic [31:0] ror32(input logic [31:0] x, input int n);
    return (x >> n) | (x << (32 - n));
  endfunction
  function automatic logic [63:0] ror64(input logic [63:0] x, input int n);
    return (x >> n) | (x << (64 - n));
  endfunction
  function automatic logic [63:0] sext32(input logic [31:0] x);
    return {{32{x[31]}}, x};
  endfunction

  logic [31:0] w;           // 32 位算法只看低 32 位
  assign w = src[31:0];

  // ---- SHA：8 个候选，func[2:0] 选一 ----
  logic [63:0] sha_candidates [8];
  always_comb begin
    sha_candidates[0] = sext32(ror32(w,  2) ^ ror32(w, 13) ^ ror32(w, 22));   // sha256sum0
    sha_candidates[1] = sext32(ror32(w,  6) ^ ror32(w, 11) ^ ror32(w, 25));   // sha256sum1
    sha_candidates[2] = sext32(ror32(w,  7) ^ ror32(w, 18) ^ (w >> 3));       // sha256sig0
    sha_candidates[3] = sext32(ror32(w, 17) ^ ror32(w, 19) ^ (w >> 10));      // sha256sig1
    sha_candidates[4] = ror64(src, 28) ^ ror64(src, 34) ^ ror64(src, 39);     // sha512sum0
    sha_candidates[5] = ror64(src, 14) ^ ror64(src, 18) ^ ror64(src, 41);     // sha512sum1
    sha_candidates[6] = ror64(src,  1) ^ ror64(src,  8) ^ (src >> 7);         // sha512sig0
    sha_candidates[7] = ror64(src, 19) ^ ror64(src, 61) ^ (src >> 6);         // sha512sig1
  end

  // ---- SM3：P0 / P1，func[0] 选一 ----
  logic [63:0] sm3_p0, sm3_p1;
  assign sm3_p0 = sext32(ror32(w, 23) ^ ror32(w, 15) ^ w);
  assign sm3_p1 = sext32(ror32(w,  9) ^ ror32(w, 17) ^ w);

  // ---- 输出寄存器 ----
  logic [63:0] out_r;
  always_ff @(posedge clock) begin
    if (reg_enable) out_r <= func[3] ? (func[0] ? sm3_p1 : sm3_p0) : sha_candidates[func[2:0]];
  end
  assign out = out_r;

endmodule


// =============================================================================
// HashModule —— golden 同名 wrapper（端口逐位同 golden）
// =============================================================================
module HashModule (
  input         clock,
  input  [63:0] io_src,
  input  [8:0]  io_func,
  input         io_regEnable,
  output [63:0] io_out
);

  xs_HashModule_core u_core (
    .clock      (clock),
    .src        (io_src),
    .func       (io_func),
    .reg_enable (io_regEnable),
    .out        (io_out)
  );

endmodule
