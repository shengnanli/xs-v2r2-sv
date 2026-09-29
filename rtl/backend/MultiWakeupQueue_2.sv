// MultiWakeupQueue_2.sv —— 整数 IQ 的推测唤醒延迟队列：只有 lat=0 一条流水，带 6 份唤醒复制件
// -----------------------------------------------------------------------------
// 机制见 xs_MultiWakeupQueue_core.sv。本文件 = golden 同名端口表 + 一条流水子模块
// （PipeWithFlush，已签核件，实例名与 golden 相同）+ 核的拼包/拆包。
//
// 本变体（G1 golden MultiWakeupQueue_2.sv，被 IssueQueueAluCsrFenceDiv 与
// IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v 例化）：
//   只有 pipes_0 = PipeWithFlush（lat=0，组合直通），没有冲刷输入、没有 lat 输入
//   （单一延迟，firtool 把 lat==0 的比较与 flush 端口都消掉了），也没有 reset。
//   fuType 进了流水但出口没人读（golden `/* unused */`），不进载荷。
//   载荷 15 位 = {pdest 8, rfWen 1, loadDependency_2..0 各 2}；复制件 6 份 × 15 位 = 整个载荷。
//   golden 寄存器：lastConnect_* 共 1+15+6*15 = 106 位，全部不复位。
// =============================================================================
module MultiWakeupQueue_2(
  input         clock,
  input         io_enq_valid,
  input  [34:0] io_enq_bits_uop_fuType,
  input  [7:0]  io_enq_bits_uop_pdest,
  input         io_enq_bits_uop_rfWen,
  input  [1:0]  io_enq_bits_uop_loadDependency_0,
  input  [1:0]  io_enq_bits_uop_loadDependency_1,
  input  [1:0]  io_enq_bits_uop_loadDependency_2,
  output        io_deq_valid,
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
  localparam int W = 15;

  logic       p0_valid;
  logic [7:0] p0_pdest;
  logic       p0_rfWen;
  logic [1:0] p0_ld [3];

  PipeWithFlush pipes_0 (
    .io_enq_valid                 (io_enq_valid),
    .io_enq_bits_fuType           (io_enq_bits_uop_fuType),
    .io_enq_bits_pdest            (io_enq_bits_uop_pdest),
    .io_enq_bits_rfWen            (io_enq_bits_uop_rfWen),
    .io_enq_bits_loadDependency_0 (io_enq_bits_uop_loadDependency_0),
    .io_enq_bits_loadDependency_1 (io_enq_bits_uop_loadDependency_1),
    .io_enq_bits_loadDependency_2 (io_enq_bits_uop_loadDependency_2),
    .io_deq_valid                 (p0_valid),
    .io_deq_bits_fuType           (/* unused */),
    .io_deq_bits_pdest            (p0_pdest),
    .io_deq_bits_rfWen            (p0_rfWen),
    .io_deq_bits_loadDependency_0 (p0_ld[0]),
    .io_deq_bits_loadDependency_1 (p0_ld[1]),
    .io_deq_bits_loadDependency_2 (p0_ld[2])
  );

  logic         pipe_valid  [1];
  logic [8:0]   pipe_robidx [1];
  logic [W-1:0] pipe_bits   [1];
  logic         deq_valid;
  logic [W-1:0] deq_bits;
  logic [14:0]  deq_copy [6];

  assign pipe_valid[0]  = p0_valid;
  assign pipe_robidx[0] = 9'h0;   // lat=0 流水无 robIdx 出口，核不读
  assign pipe_bits[0]   = {p0_pdest, p0_rfWen, p0_ld[2], p0_ld[1], p0_ld[0]};

  xs_MultiWakeupQueue_core #(
    .N_PIPES (1),
    .PIPE_LAT('{0}),
    .W       (W),
    .LD_CNT  (3),
    .LD_W    (2),
    .COPY_NUM(6),
    .COPY_W  (15),
    .WEN_MASK(15'h40)   // rfWen
  ) u_core (
    .clock                (clock),
    // 唯一的流水 lat=0，出口不判冲刷；golden 没有 flush 端口
    .flush_redirect_valid (1'b0),
    .flush_redirect_level (1'b0),
    .flush_redirect_robidx(9'h0),
    .flush_ld2cancel      (3'h0),
    .flush_og0fail        (1'b0),
    .flush_og1fail        (1'b0),
    .pipe_valid           (pipe_valid),
    .pipe_robidx          (pipe_robidx),
    .pipe_bits            (pipe_bits),
    .deq_valid            (deq_valid),
    .deq_bits             (deq_bits),
    .deq_copy             (deq_copy)
  );

  assign io_deq_valid = deq_valid;
  assign {io_deq_bits_pdest, io_deq_bits_rfWen, io_deq_bits_loadDependency_2,
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
