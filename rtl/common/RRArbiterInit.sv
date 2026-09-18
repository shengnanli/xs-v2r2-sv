// =============================================================================
// RRArbiterInit.sv —— 轮转（round-robin）仲裁器：家族参数化核 + 本变体 wrapper
//
// 在哪一层：这是 rocket-chip `LockingRRArbiter`(count=1) 的香山实例化，属于通用
//   互连件，不隶属某一个子系统。golden 里同一份 Chisel 生成了 15 个模块
//   （RRArbiterInit / _1 / _4..._9 / _11..._16 / _20），分布在 MMU（Bitmap、LLPTW、
//   PTWNewFilter）、L2 预取（PrefetchFilter、MutiLevelPrefetchFilter、
//   PrefetchReqBuffer）、访存（LoadQueueUncache）与 L2/CHI（MMIOBridge、SinkC、
//   TL2CHICoupledL2）四处。本文件放 rtl/common/ 就是因为它跨子系统。
//
// 核心机制（三段，全部照抄 Chisel 的 LockingRRArbiter）：
//   1. 轮转指针 lastGrant：每次 out 握手成功后记下这次给了谁，下一拍起**只有
//      编号更大的请求方**算"优先"（after_last[i] = i > lastGrant）。
//   2. 选择 chosen：默认 N-1，先从高到低被 in_valid 覆写（保证"有请求就选到"），
//      再从高到低被 valid_after 覆写（优先项赢）—— 两轮覆写的顺序就是优先级，
//      与 Chisel 的两个 `for` 逐字同构。
//   3. 授权 in_ready：ArbiterCtrl 的前缀链 —— 把 2N 个请求排成
//      [valid_after(0..N-1), in_valid(0..N-1)]，no_higher[k] = 前 k 项全无请求；
//      grant(i) = no_higher[i] & after_last[i] | no_higher[N+i]，再与 out_ready 相与。
//
// 复位域：★全模块只有 lastGrant 一个寄存器★，异步高有效复位到 0（golden 15 个
//   变体一律 `always @(posedge clock or posedge reset)`，复位值 0，实测无第二个寄存器）。
//
// 家族差异（15 个变体只差 6 个维度，一个核全覆盖）：仲裁宽度 N、payload 打平位宽 W、
//   有无 in_ready 输出、有无 out_ready 输入（无 = golden 里该端口被常量 1 折掉）、
//   有无 chosen 输出、以及两处 golden 自己的不对称（_11 的 id 常数表、_20 的
//   tgtID/size 只有 in_4 有真端口）。差异矩阵与逐变体参数见
//   verif/ut/RRArbiterInitVariants/README.md；14 个薄 wrapper 由
//   verif/ut/RRArbiterInitVariants/gen.py 生成。
//
// 设计源：rocket-chip src/main/scala/freechips/rocketchip/util/Arbiters.scala
//         (class LockingRRArbiter / object ArbiterCtrl)
// golden 对照：G1-canonical/golden-rtl/RRArbiterInit.sv（本文件的 wrapper 段）
// =============================================================================

// -----------------------------------------------------------------------------
// xs_RRArbiterInit_core —— N 路轮转仲裁器（payload 打平成 W 位总线）
//
// payload 之所以打平：15 个变体的 bundle 字段数从 1 到 94 不等，但仲裁器对 payload
// 只做"按 chosen 选一路"这一件事，与字段结构无关。薄 wrapper 负责把 golden 的
// 逐字段端口拼成 W 位、再按同一顺序拆回去，核里只有一条 W 位的多路选择。
// -----------------------------------------------------------------------------
module xs_RRArbiterInit_core #(
  parameter int N     = 2,                        // 仲裁宽度（请求方个数）
  parameter int W     = 1,                        // payload 打平后的位宽
  parameter int IDX_W = (N > 1) ? $clog2(N) : 1   // 派生参数：chosen/lastGrant 位宽，例化处勿覆盖
) (
  input  logic                    clock,
  input  logic                    reset,          // 异步、高有效
  input  logic [N-1:0]            in_valid,
  input  logic [N-1:0][W-1:0]     in_bits,
  output logic [N-1:0]            in_ready,
  input  logic                    out_ready,      // golden 无此端口的变体由 wrapper 接 1'b1
  output logic                    out_valid,
  output logic [W-1:0]            out_bits,
  output logic [IDX_W-1:0]        chosen
);
  // N 不是 2 的幂时，chosen 的取值域（2^IDX_W）比请求方多。golden 的选择表把多出来
  // 的那几项**填第 0 路**（实测 N=3/5/6 三个变体都是这样），这里照抄：填法本身
  // 不可达（chosen 由下面的逻辑产生，永远 < N），但 FM 不做可达性分析，照抄最省事。
  localparam int SEL_N = 1 << IDX_W;

  logic [IDX_W-1:0] last_grant_q;

  // ---- 1. 轮转掩码 ---------------------------------------------------------
  // after_last[i]：第 i 路排在上次授权之后，因而这一轮算"优先"。
  // 注意 lastGrant 是 IDX_W 位自由寄存器，N 不是 2 的幂时它可以取到 >= N 的值
  // （复位后不可达，但 FM 当自由变量），此时所有 after_last 位都为 0 —— 与 golden
  // 用 `lastGrant < i` 化简出来的表达式逐值相同。
  logic [N-1:0] after_last;
  logic [N-1:0] valid_after;   // = in_valid & after_last，Chisel 的 validMask
  always_comb begin
    for (int i = 0; i < N; i++) begin
      after_last[i]  = (i > int'(last_grant_q));
      valid_after[i] = in_valid[i] & after_last[i];
    end
  end

  // ---- 2. 选择 ------------------------------------------------------------
  // 两轮从高到低的覆写：第一轮让"有请求的最低编号"胜出（这是无轮转时的固定优先级），
  // 第二轮让"轮转后优先的最低编号"再覆盖它 —— 于是轮转优先级永远压过固定优先级，
  // 而当轮转段里一个请求都没有时自然回落到固定优先级（完成一圈回绕）。
  always_comb begin
    chosen = IDX_W'(N - 1);
    for (int i = N - 2; i >= 0; i--)
      if (in_valid[i]) chosen = IDX_W'(i);
    for (int i = N - 1; i >= 1; i--)
      if (valid_after[i]) chosen = IDX_W'(i);
  end

  // ---- 3. 输出多路选择 ------------------------------------------------------
  logic [SEL_N-1:0]        sel_valid;
  logic [SEL_N-1:0][W-1:0] sel_bits;
  always_comb begin
    for (int k = 0; k < SEL_N; k++) begin
      sel_valid[k] = (k < N) ? in_valid[k] : in_valid[0];
      sel_bits[k]  = (k < N) ? in_bits[k]  : in_bits[0];
    end
  end
  assign out_valid = sel_valid[chosen];
  assign out_bits  = sel_bits[chosen];

  // ---- 4. 授权（ArbiterCtrl 前缀链）------------------------------------------
  // request 把两组请求首尾相接：低 N 位是"轮转优先"的请求，高 N 位是"任意"请求。
  // no_higher[k] = 排在 k 前面的请求一个都没有。于是
  //   grant(i) = (轮转段里 i 最靠前 且 i 本身优先) 或 (整条链上 i 最靠前)
  // 后一项就是"轮转段全空时回落到固定优先级"，与 chosen 的两轮覆写一一对应。
  logic [2*N-1:0] request;
  logic [2*N-1:0] no_higher;
  assign request = {in_valid, valid_after};
  always_comb begin
    no_higher[0] = 1'b1;
    for (int k = 1; k < 2*N; k++)
      no_higher[k] = no_higher[k-1] & ~request[k-1];
  end
  always_comb
    for (int i = 0; i < N; i++)
      in_ready[i] = ((no_higher[i] & after_last[i]) | no_higher[N+i]) & out_ready;

  // ---- 5. 轮转指针 ---------------------------------------------------------
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      last_grant_q <= '0;
    else if (out_valid & out_ready)
      last_grant_q <= chosen;
  end
endmodule

// -----------------------------------------------------------------------------
// RRArbiterInit —— golden 同名 wrapper
//   本变体：N=8，payload = 单字段 ppn[35:0]（W=36），有 out_ready、有 chosen、
//   **无 in_ready 输出**（golden 端口表里没有 io_in_*_ready —— 使用者 Bitmap.sv
//   不读它，firtool 把这些输出消掉了）。例化者：Bitmap.sv ×1。
// -----------------------------------------------------------------------------
module RRArbiterInit(
  input         clock,
  input         reset,
  input         io_in_0_valid,
  input  [35:0] io_in_0_bits_ppn,
  input         io_in_1_valid,
  input  [35:0] io_in_1_bits_ppn,
  input         io_in_2_valid,
  input  [35:0] io_in_2_bits_ppn,
  input         io_in_3_valid,
  input  [35:0] io_in_3_bits_ppn,
  input         io_in_4_valid,
  input  [35:0] io_in_4_bits_ppn,
  input         io_in_5_valid,
  input  [35:0] io_in_5_bits_ppn,
  input         io_in_6_valid,
  input  [35:0] io_in_6_bits_ppn,
  input         io_in_7_valid,
  input  [35:0] io_in_7_bits_ppn,
  input         io_out_ready,
  output        io_out_valid,
  output [35:0] io_out_bits_ppn,
  output [2:0]  io_chosen
);
  localparam int N = 8;
  localparam int W = 36;

  logic [N-1:0][W-1:0] in_bits;
  assign in_bits[0] = io_in_0_bits_ppn;
  assign in_bits[1] = io_in_1_bits_ppn;
  assign in_bits[2] = io_in_2_bits_ppn;
  assign in_bits[3] = io_in_3_bits_ppn;
  assign in_bits[4] = io_in_4_bits_ppn;
  assign in_bits[5] = io_in_5_bits_ppn;
  assign in_bits[6] = io_in_6_bits_ppn;
  assign in_bits[7] = io_in_7_bits_ppn;

  xs_RRArbiterInit_core #(.N(N), .W(W)) u_core (
    .clock     (clock),
    .reset     (reset),
    .in_valid  ({io_in_7_valid, io_in_6_valid, io_in_5_valid, io_in_4_valid,
                 io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid}),
    .in_bits   (in_bits),
    .in_ready  (),                 // 本变体 golden 无 in_ready 输出端口
    .out_ready (io_out_ready),
    .out_valid (io_out_valid),
    .out_bits  (io_out_bits_ppn),
    .chosen    (io_chosen)
  );
endmodule
