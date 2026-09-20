// =============================================================================
// WBArbiter.sv —— 写回/读口仲裁器（带反饥饿计数）：家族参数化核 + 本变体 wrapper
//
// 在哪一层：后端寄存器堆周边。golden 里 13 个变体全部由两类父模块例化 ——
//   *RFReadArbiter（整型/浮点/向量寄存器堆的**读口**仲裁，payload 是读地址 addr）
//   与 *RFWBCollideChecker（**写回**端口撞车检查，只判 valid 不带 payload）。
//   下游拿 io_out_valid 决定这一拍读/写口给了谁。
//
// 核心机制（两级）：
//   1. 反饥饿级（本族独有）：每一路一个 3 位 cancelCounter。被拒一拍 +1（饱和在 7），
//      握手成功清 0；当计数达到 6 或 7（cnt[2:1] 全 1）该路置 isFull。
//      只要有任何一路 isFull（hasFull）且这一拍有 isFull 的路在请求，
//      **这一拍只让 isFull 的路参与竞争**，把饿着的那几路放出去。
//   2. 优先级级：编号小者先赢。这一级与 RealWBArbiter 族**逐字相同**，
//      已抽成共享件 rtl/common/xs_PriorityArbSelect.sv（两族关系的实测依据见该文件头）。
//
// 复位域：cancelCounter[N] / isFull[N] / hasFull 共 2N+1 个寄存器，一律
//   **异步高有效**复位到 0，与 golden 的 `always @(posedge clock or posedge reset)` 对应。
//
// ★golden 的不对称照抄★：N=1 的四个变体（_3/_38/_58/_66）里 golden 把 hasFull 的
//   次态直接写成那一路的 isFull 次态（一元的「或」被 firtool 化简掉了），而不是
//   N>=2 的 `|{...}` 形式。核里统一用 N 元归约表达，N=1 时逐值相同 —— 这是化简，
//   不是补齐结构：寄存器个数、复位域、次态函数都与 golden 一一对应。
//
// 家族差异（13 个变体只差 2 个维度）：仲裁宽度 N（1/2/3/4）、payload 位宽 PW
//   （0 = golden 无 bits 端口，或 addr 的 5/7/8 位）。逐变体矩阵见
//   verif/ut/WBArbiterVariants/README.md；12 个薄 wrapper 由
//   scripts/gen_fubusy_wbarb.py 生成。
//
// 设计源：XiangShan src/main/scala/xiangshan/backend/datapath/WbArbiter.scala
// golden 对照：G1-canonical/golden-rtl/WBArbiter.sv（本文件的 wrapper 段）
// =============================================================================

// -----------------------------------------------------------------------------
// xs_WBArbiter_core —— 反饥饿计数 + 固定优先级仲裁
//
// payload 打平成 PW 位：本族 payload 只有 addr 一个字段，仲裁器对它只做「按赢家选
// 一路」。golden 完全没有 bits 端口的变体（8 个）由 wrapper 传 PW=1、in_bits 接 0、
// out_bits 悬空 —— 那条 1 位多路选择没有任何读者，不进任何输出锥。
// -----------------------------------------------------------------------------
module xs_WBArbiter_core #(
  parameter int N  = 3,
  parameter int PW = 1
) (
  input  logic                 clock,
  input  logic                 reset,      // 异步、高有效
  input  logic [N-1:0]         in_valid,
  input  logic [N-1:0][PW-1:0] in_bits,
  output logic [N-1:0]         in_ready,
  output logic                 out_valid,
  output logic [PW-1:0]        out_bits
);
  logic [N-1:0][2:0] cancel_cnt_q;   // 每一路连续被拒的拍数（饱和 7）
  logic [N-1:0]      is_full_q;      // 该路已经饿到阈值
  logic              has_full_q;     // 任何一路饿到阈值

  // ---- 1. 反饥饿筛选 --------------------------------------------------------
  // 有人饿着且正在请求时，只放饿着的那些路进竞争；否则所有请求都参与。
  logic        starving_now;
  logic [N-1:0] final_valid;
  assign starving_now = has_full_q & (|(in_valid & is_full_q));
  assign final_valid  = in_valid & ({N{~starving_now}} | is_full_q);

  // ---- 2. 优先级仲裁（与 RealWBArbiter 族共用的那条法则）---------------------
  xs_PriorityArbSelect #(.N(N), .PW(PW)) u_sel (
    .in_valid  (in_valid),
    .eff_valid (final_valid),
    .in_bits   (in_bits),
    .in_ready  (in_ready),
    .out_valid (out_valid),
    .out_bits  (out_bits)
  );

  // ---- 3. 计数器次态 --------------------------------------------------------
  logic [N-1:0] stalled, fired, is_full_d;
  assign stalled = in_valid & ~in_ready;   // 这一拍请求了但没被放行
  assign fired   = in_valid & in_ready;    // 这一拍握手成功

  always_comb
    for (int i = 0; i < N; i++)
      // 被拒时用**当前**计数判阈值（与 golden 同相位）；握手清零；不请求则保持。
      is_full_d[i] = stalled[i] ? (&cancel_cnt_q[i][2:1]) : (~fired[i] & is_full_q[i]);

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      cancel_cnt_q <= '0;
      is_full_q    <= '0;
      has_full_q   <= 1'b0;
    end
    else begin
      for (int i = 0; i < N; i++) begin
        if (stalled[i])      cancel_cnt_q[i] <= (&cancel_cnt_q[i]) ? 3'h7
                                                                   : cancel_cnt_q[i] + 3'h1;
        else if (fired[i])   cancel_cnt_q[i] <= 3'h0;
      end
      is_full_q  <= is_full_d;
      has_full_q <= |is_full_d;
    end
  end
endmodule

// -----------------------------------------------------------------------------
// WBArbiter —— 家族里最朴素的一个：N=3、无 payload。
//   例化者：IntRFWBCollideChecker.sv（整型寄存器堆写回撞车检查）
// -----------------------------------------------------------------------------
module WBArbiter(
  input  clock,
  input  reset,
  output io_in_0_ready,
  input  io_in_0_valid,
  output io_in_1_ready,
  input  io_in_1_valid,
  output io_in_2_ready,
  input  io_in_2_valid,
  output io_out_valid
);
  localparam int N = 3;

  logic [N-1:0] in_ready;
  xs_WBArbiter_core #(.N(N), .PW(1)) u_core (
    .clock     (clock),
    .reset     (reset),
    .in_valid  ({io_in_2_valid, io_in_1_valid, io_in_0_valid}),
    .in_bits   ('0),            // golden 本变体无 bits 端口
    .in_ready  (in_ready),
    .out_valid (io_out_valid),
    .out_bits  ()               // 同上：无读者
  );
  assign io_in_0_ready = in_ready[0];
  assign io_in_1_ready = in_ready[1];
  assign io_in_2_ready = in_ready[2];
endmodule
