// MultiWakeupQueue.sv —— 整数 IQ 的推测唤醒延迟队列：lat∈{0,2} 两条流水，带 6 份唤醒复制件
// -----------------------------------------------------------------------------
// 机制见 xs_MultiWakeupQueue_core.sv。本文件 = golden 同名端口表 + 两条流水子模块
// （PipeWithFlush / PipeWithFlush_1，已签核件，实例名与 golden 相同）+ 核的拼包/拆包。
//
// 本变体（G1 golden MultiWakeupQueue.sv，被 IssueQueueAluMulBkuBrhJmp 例化）：
//   pipes_0 = PipeWithFlush   ：lat=0，组合直通，出口不判冲刷；
//   pipes_1 = PipeWithFlush_1 ：lat=2，两级；出口判 redirect / ld2Cancel×3 / og1Fail，
//                               出口 loadDependency 再左移一位。
//   载荷 50 位 = {fuType 35, pdest 8, rfWen 1, loadDependency_2..0 各 2}；
//   复制件 6 份 × 15 位 = 载荷低 15 位 {pdest, rfWen, loadDependency_2..0}。
//   golden 寄存器：lastConnect_* 共 1+50+6*15 = 141 位，全部不复位。
//   io_enq_bits_lat 只有 2 位，按 ==0 / ==2 分发，其它值哪条流水都不进（照 golden）。
// =============================================================================
module MultiWakeupQueue(
  input         clock,
  input         reset,
  input         io_flush_redirect_valid,
  input         io_flush_redirect_bits_robIdx_flag,
  input  [7:0]  io_flush_redirect_bits_robIdx_value,
  input         io_flush_redirect_bits_level,
  input         io_flush_ldCancel_0_ld2Cancel,
  input         io_flush_ldCancel_1_ld2Cancel,
  input         io_flush_ldCancel_2_ld2Cancel,
  input         io_flush_og0Fail,
  input         io_flush_og1Fail,
  input         io_enq_valid,
  input  [34:0] io_enq_bits_uop_fuType,
  input         io_enq_bits_uop_robIdx_flag,
  input  [7:0]  io_enq_bits_uop_robIdx_value,
  input  [7:0]  io_enq_bits_uop_pdest,
  input         io_enq_bits_uop_rfWen,
  input  [1:0]  io_enq_bits_uop_loadDependency_0,
  input  [1:0]  io_enq_bits_uop_loadDependency_1,
  input  [1:0]  io_enq_bits_uop_loadDependency_2,
  input  [1:0]  io_enq_bits_lat,
  output        io_deq_valid,
  output [34:0] io_deq_bits_fuType,
  output [7:0]  io_deq_bits_pdestCopy_0,
  output [7:0]  io_deq_bits_pdestCopy_1,
  output [7:0]  io_deq_bits_pdestCopy_2,
  output [7:0]  io_deq_bits_pdestCopy_3,
  output [7:0]  io_deq_bits_pdestCopy_4,
  output [7:0]  io_deq_bits_pdestCopy_5,
  output        io_deq_bits_rfWenCopy_0,
  output        io_deq_bits_rfWenCopy_1,
  output        io_deq_bits_rfWenCopy_2,
  output        io_deq_bits_rfWenCopy_3,
  output        io_deq_bits_rfWenCopy_4,
  output        io_deq_bits_rfWenCopy_5,
  output [1:0]  io_deq_bits_loadDependencyCopy_0_0,
  output [1:0]  io_deq_bits_loadDependencyCopy_0_1,
  output [1:0]  io_deq_bits_loadDependencyCopy_0_2,
  output [1:0]  io_deq_bits_loadDependencyCopy_1_0,
  output [1:0]  io_deq_bits_loadDependencyCopy_1_1,
  output [1:0]  io_deq_bits_loadDependencyCopy_1_2,
  output [1:0]  io_deq_bits_loadDependencyCopy_2_0,
  output [1:0]  io_deq_bits_loadDependencyCopy_2_1,
  output [1:0]  io_deq_bits_loadDependencyCopy_2_2,
  output [1:0]  io_deq_bits_loadDependencyCopy_3_0,
  output [1:0]  io_deq_bits_loadDependencyCopy_3_1,
  output [1:0]  io_deq_bits_loadDependencyCopy_3_2,
  output [1:0]  io_deq_bits_loadDependencyCopy_4_0,
  output [1:0]  io_deq_bits_loadDependencyCopy_4_1,
  output [1:0]  io_deq_bits_loadDependencyCopy_4_2,
  output [1:0]  io_deq_bits_loadDependencyCopy_5_0,
  output [1:0]  io_deq_bits_loadDependencyCopy_5_1,
  output [1:0]  io_deq_bits_loadDependencyCopy_5_2,
  output [7:0]  io_deq_bits_pdest,
  output        io_deq_bits_rfWen,
  output [1:0]  io_deq_bits_loadDependency_0,
  output [1:0]  io_deq_bits_loadDependency_1,
  output [1:0]  io_deq_bits_loadDependency_2
);
  localparam int W = 50;

  // ---- 两条流水（golden 子模块原样例化）----
  logic        p0_valid, p1_valid;
  logic [34:0] p0_fuType, p1_fuType;
  logic [7:0]  p0_pdest, p1_pdest;
  logic        p0_rfWen, p1_rfWen;
  logic [1:0]  p0_ld [3];
  logic [1:0]  p1_ld [3];
  logic        p1_robIdx_flag;
  logic [7:0]  p1_robIdx_value;

  PipeWithFlush pipes_0 (
    .io_enq_valid                 (io_enq_valid & io_enq_bits_lat == 2'h0),
    .io_enq_bits_fuType           (io_enq_bits_uop_fuType),
    .io_enq_bits_pdest            (io_enq_bits_uop_pdest),
    .io_enq_bits_rfWen            (io_enq_bits_uop_rfWen),
    .io_enq_bits_loadDependency_0 (io_enq_bits_uop_loadDependency_0),
    .io_enq_bits_loadDependency_1 (io_enq_bits_uop_loadDependency_1),
    .io_enq_bits_loadDependency_2 (io_enq_bits_uop_loadDependency_2),
    .io_deq_valid                 (p0_valid),
    .io_deq_bits_fuType           (p0_fuType),
    .io_deq_bits_pdest            (p0_pdest),
    .io_deq_bits_rfWen            (p0_rfWen),
    .io_deq_bits_loadDependency_0 (p0_ld[0]),
    .io_deq_bits_loadDependency_1 (p0_ld[1]),
    .io_deq_bits_loadDependency_2 (p0_ld[2])
  );

  PipeWithFlush_1 pipes_1 (
    .clock                               (clock),
    .reset                               (reset),
    .io_flush_redirect_valid             (io_flush_redirect_valid),
    .io_flush_redirect_bits_robIdx_flag  (io_flush_redirect_bits_robIdx_flag),
    .io_flush_redirect_bits_robIdx_value (io_flush_redirect_bits_robIdx_value),
    .io_flush_redirect_bits_level        (io_flush_redirect_bits_level),
    .io_flush_ldCancel_0_ld2Cancel       (io_flush_ldCancel_0_ld2Cancel),
    .io_flush_ldCancel_1_ld2Cancel       (io_flush_ldCancel_1_ld2Cancel),
    .io_flush_ldCancel_2_ld2Cancel       (io_flush_ldCancel_2_ld2Cancel),
    .io_flush_og0Fail                    (io_flush_og0Fail),
    .io_enq_valid                        (io_enq_valid & io_enq_bits_lat == 2'h2),
    .io_enq_bits_fuType                  (io_enq_bits_uop_fuType),
    .io_enq_bits_robIdx_flag             (io_enq_bits_uop_robIdx_flag),
    .io_enq_bits_robIdx_value            (io_enq_bits_uop_robIdx_value),
    .io_enq_bits_pdest                   (io_enq_bits_uop_pdest),
    .io_enq_bits_rfWen                   (io_enq_bits_uop_rfWen),
    .io_enq_bits_loadDependency_0        (io_enq_bits_uop_loadDependency_0),
    .io_enq_bits_loadDependency_1        (io_enq_bits_uop_loadDependency_1),
    .io_enq_bits_loadDependency_2        (io_enq_bits_uop_loadDependency_2),
    .io_deq_valid                        (p1_valid),
    .io_deq_bits_fuType                  (p1_fuType),
    .io_deq_bits_robIdx_flag             (p1_robIdx_flag),
    .io_deq_bits_robIdx_value            (p1_robIdx_value),
    .io_deq_bits_pdest                   (p1_pdest),
    .io_deq_bits_rfWen                   (p1_rfWen),
    .io_deq_bits_loadDependency_0        (p1_ld[0]),
    .io_deq_bits_loadDependency_1        (p1_ld[1]),
    .io_deq_bits_loadDependency_2        (p1_ld[2])
  );

  // ---- 拼包进核 ----
  logic         pipe_valid  [2];
  logic [8:0]   pipe_robidx [2];
  logic [W-1:0] pipe_bits   [2];
  logic         deq_valid;
  logic [W-1:0] deq_bits;
  logic [14:0]  deq_copy [6];

  assign pipe_valid[0]  = p0_valid;
  assign pipe_robidx[0] = 9'h0;   // lat=0 流水无 robIdx 出口，核不读
  assign pipe_bits[0]   = {p0_fuType, p0_pdest, p0_rfWen, p0_ld[2], p0_ld[1], p0_ld[0]};
  assign pipe_valid[1]  = p1_valid;
  assign pipe_robidx[1] = {p1_robIdx_flag, p1_robIdx_value};
  assign pipe_bits[1]   = {p1_fuType, p1_pdest, p1_rfWen, p1_ld[2], p1_ld[1], p1_ld[0]};

  xs_MultiWakeupQueue_core #(
    .N_PIPES (2),
    .PIPE_LAT('{0, 2}),
    .W       (W),
    .LD_CNT  (3),
    .LD_W    (2),
    .COPY_NUM(6),
    .COPY_W  (15),
    .WEN_MASK(50'h40)   // rfWen
  ) u_core (
    .clock                (clock),
    .flush_redirect_valid (io_flush_redirect_valid),
    .flush_redirect_level (io_flush_redirect_bits_level),
    .flush_redirect_robidx({io_flush_redirect_bits_robIdx_flag, io_flush_redirect_bits_robIdx_value}),
    .flush_ld2cancel      ({io_flush_ldCancel_2_ld2Cancel, io_flush_ldCancel_1_ld2Cancel,
                             io_flush_ldCancel_0_ld2Cancel}),
    .flush_og0fail        (io_flush_og0Fail),
    .flush_og1fail        (io_flush_og1Fail),
    .pipe_valid           (pipe_valid),
    .pipe_robidx          (pipe_robidx),
    .pipe_bits            (pipe_bits),
    .deq_valid            (deq_valid),
    .deq_bits             (deq_bits),
    .deq_copy             (deq_copy)
  );

  // ---- 拆包出端口 ----
  assign io_deq_valid = deq_valid;
  assign {io_deq_bits_fuType, io_deq_bits_pdest, io_deq_bits_rfWen, io_deq_bits_loadDependency_2,
          io_deq_bits_loadDependency_1, io_deq_bits_loadDependency_0} = deq_bits;
  assign io_deq_bits_pdestCopy_0 = deq_copy[0][14:7];
  assign io_deq_bits_pdestCopy_1 = deq_copy[1][14:7];
  assign io_deq_bits_pdestCopy_2 = deq_copy[2][14:7];
  assign io_deq_bits_pdestCopy_3 = deq_copy[3][14:7];
  assign io_deq_bits_pdestCopy_4 = deq_copy[4][14:7];
  assign io_deq_bits_pdestCopy_5 = deq_copy[5][14:7];
  assign io_deq_bits_rfWenCopy_0 = deq_copy[0][6];
  assign io_deq_bits_rfWenCopy_1 = deq_copy[1][6];
  assign io_deq_bits_rfWenCopy_2 = deq_copy[2][6];
  assign io_deq_bits_rfWenCopy_3 = deq_copy[3][6];
  assign io_deq_bits_rfWenCopy_4 = deq_copy[4][6];
  assign io_deq_bits_rfWenCopy_5 = deq_copy[5][6];
  assign io_deq_bits_loadDependencyCopy_0_0 = deq_copy[0][1:0];
  assign io_deq_bits_loadDependencyCopy_0_1 = deq_copy[0][3:2];
  assign io_deq_bits_loadDependencyCopy_0_2 = deq_copy[0][5:4];
  assign io_deq_bits_loadDependencyCopy_1_0 = deq_copy[1][1:0];
  assign io_deq_bits_loadDependencyCopy_1_1 = deq_copy[1][3:2];
  assign io_deq_bits_loadDependencyCopy_1_2 = deq_copy[1][5:4];
  assign io_deq_bits_loadDependencyCopy_2_0 = deq_copy[2][1:0];
  assign io_deq_bits_loadDependencyCopy_2_1 = deq_copy[2][3:2];
  assign io_deq_bits_loadDependencyCopy_2_2 = deq_copy[2][5:4];
  assign io_deq_bits_loadDependencyCopy_3_0 = deq_copy[3][1:0];
  assign io_deq_bits_loadDependencyCopy_3_1 = deq_copy[3][3:2];
  assign io_deq_bits_loadDependencyCopy_3_2 = deq_copy[3][5:4];
  assign io_deq_bits_loadDependencyCopy_4_0 = deq_copy[4][1:0];
  assign io_deq_bits_loadDependencyCopy_4_1 = deq_copy[4][3:2];
  assign io_deq_bits_loadDependencyCopy_4_2 = deq_copy[4][5:4];
  assign io_deq_bits_loadDependencyCopy_5_0 = deq_copy[5][1:0];
  assign io_deq_bits_loadDependencyCopy_5_1 = deq_copy[5][3:2];
  assign io_deq_bits_loadDependencyCopy_5_2 = deq_copy[5][5:4];
endmodule
