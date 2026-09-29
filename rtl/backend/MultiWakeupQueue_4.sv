// MultiWakeupQueue_4.sv —— 浮点 IQ 的推测唤醒延迟队列：lat∈{1,2,0,3} 四条流水，无复制件
// -----------------------------------------------------------------------------
// 机制见 xs_MultiWakeupQueue_core.sv。本文件 = golden 同名端口表 + 四条流水子模块
// （PipeWithFlush_6/7/8/9，已签核件，实例名与 golden 相同）+ 核的拼包/拆包。
//
// 本变体（G1 golden MultiWakeupQueue_4.sv，被 IssueQueueFaluFcvtF2vFmacFdiv 例化）：
//   pipes_0 = PipeWithFlush_6 ：lat=1，出口判 redirect / og0Fail；
//   pipes_1 = PipeWithFlush_7 ：lat=2，出口判 redirect / og1Fail；
//   pipes_2 = PipeWithFlush_8 ：lat=0，组合直通，出口不判冲刷；
//   pipes_3 = PipeWithFlush_9 ：lat=3，出口只判 redirect。
//   （实例顺序是 Chisel latencySet 这个 Set 的迭代顺序，照 golden。）
//   载荷 46 位 = {fuType 35, pdest 8, fpWen, vecWen, v0Wen}；无 loadDependency、无复制件。
//   golden 寄存器：lastConnect_* 共 1+46 = 47 位，全部不复位。
// =============================================================================
module MultiWakeupQueue_4(
  input         clock,
  input         reset,
  input         io_flush_redirect_valid,
  input         io_flush_redirect_bits_robIdx_flag,
  input  [7:0]  io_flush_redirect_bits_robIdx_value,
  input         io_flush_redirect_bits_level,
  input         io_flush_og0Fail,
  input         io_flush_og1Fail,
  input         io_enq_valid,
  input  [34:0] io_enq_bits_uop_fuType,
  input         io_enq_bits_uop_robIdx_flag,
  input  [7:0]  io_enq_bits_uop_robIdx_value,
  input  [7:0]  io_enq_bits_uop_pdest,
  input         io_enq_bits_uop_fpWen,
  input         io_enq_bits_uop_vecWen,
  input         io_enq_bits_uop_v0Wen,
  input  [2:0]  io_enq_bits_lat,
  output        io_deq_valid,
  output [34:0] io_deq_bits_fuType,
  output [7:0]  io_deq_bits_pdest,
  output        io_deq_bits_fpWen,
  output        io_deq_bits_vecWen,
  output        io_deq_bits_v0Wen
);
  localparam int W = 46;

  logic         pipe_valid  [4];
  logic [8:0]   pipe_robidx [4];
  logic [W-1:0] pipe_bits   [4];
  logic         deq_valid;
  logic [W-1:0] deq_bits;

  // 各流水出口：p<i>_fuType/pdest/wen 拼成载荷，robIdx 单独给核判冲刷
  logic [34:0] p_fuType [4];
  logic [7:0]  p_pdest  [4];
  logic        p_fpWen  [4];
  logic        p_vecWen [4];
  logic        p_v0Wen  [4];
  logic        p_robIdx_flag  [4];
  logic [7:0]  p_robIdx_value [4];

  PipeWithFlush_6 pipes_0 (
    .clock                    (clock),
    .reset                    (reset),
    .io_enq_valid             (io_enq_valid & io_enq_bits_lat == 3'h1),
    .io_enq_bits_fuType       (io_enq_bits_uop_fuType),
    .io_enq_bits_robIdx_flag  (io_enq_bits_uop_robIdx_flag),
    .io_enq_bits_robIdx_value (io_enq_bits_uop_robIdx_value),
    .io_enq_bits_pdest        (io_enq_bits_uop_pdest),
    .io_enq_bits_fpWen        (io_enq_bits_uop_fpWen),
    .io_enq_bits_vecWen       (io_enq_bits_uop_vecWen),
    .io_enq_bits_v0Wen        (io_enq_bits_uop_v0Wen),
    .io_deq_valid             (pipe_valid[0]),
    .io_deq_bits_fuType       (p_fuType[0]),
    .io_deq_bits_robIdx_flag  (p_robIdx_flag[0]),
    .io_deq_bits_robIdx_value (p_robIdx_value[0]),
    .io_deq_bits_pdest        (p_pdest[0]),
    .io_deq_bits_fpWen        (p_fpWen[0]),
    .io_deq_bits_vecWen       (p_vecWen[0]),
    .io_deq_bits_v0Wen        (p_v0Wen[0])
  );

  PipeWithFlush_7 pipes_1 (
    .clock                               (clock),
    .reset                               (reset),
    .io_flush_redirect_valid             (io_flush_redirect_valid),
    .io_flush_redirect_bits_robIdx_flag  (io_flush_redirect_bits_robIdx_flag),
    .io_flush_redirect_bits_robIdx_value (io_flush_redirect_bits_robIdx_value),
    .io_flush_redirect_bits_level        (io_flush_redirect_bits_level),
    .io_flush_og0Fail                    (io_flush_og0Fail),
    .io_enq_valid                        (io_enq_valid & io_enq_bits_lat == 3'h2),
    .io_enq_bits_fuType                  (io_enq_bits_uop_fuType),
    .io_enq_bits_robIdx_flag             (io_enq_bits_uop_robIdx_flag),
    .io_enq_bits_robIdx_value            (io_enq_bits_uop_robIdx_value),
    .io_enq_bits_pdest                   (io_enq_bits_uop_pdest),
    .io_enq_bits_fpWen                   (io_enq_bits_uop_fpWen),
    .io_enq_bits_vecWen                  (io_enq_bits_uop_vecWen),
    .io_enq_bits_v0Wen                   (io_enq_bits_uop_v0Wen),
    .io_deq_valid                        (pipe_valid[1]),
    .io_deq_bits_fuType                  (p_fuType[1]),
    .io_deq_bits_robIdx_flag             (p_robIdx_flag[1]),
    .io_deq_bits_robIdx_value            (p_robIdx_value[1]),
    .io_deq_bits_pdest                   (p_pdest[1]),
    .io_deq_bits_fpWen                   (p_fpWen[1]),
    .io_deq_bits_vecWen                  (p_vecWen[1]),
    .io_deq_bits_v0Wen                   (p_v0Wen[1])
  );

  PipeWithFlush_8 pipes_2 (
    .io_enq_valid       (io_enq_valid & io_enq_bits_lat == 3'h0),
    .io_enq_bits_fuType (io_enq_bits_uop_fuType),
    .io_enq_bits_pdest  (io_enq_bits_uop_pdest),
    .io_enq_bits_fpWen  (io_enq_bits_uop_fpWen),
    .io_enq_bits_vecWen (io_enq_bits_uop_vecWen),
    .io_enq_bits_v0Wen  (io_enq_bits_uop_v0Wen),
    .io_deq_valid       (pipe_valid[2]),
    .io_deq_bits_fuType (p_fuType[2]),
    .io_deq_bits_pdest  (p_pdest[2]),
    .io_deq_bits_fpWen  (p_fpWen[2]),
    .io_deq_bits_vecWen (p_vecWen[2]),
    .io_deq_bits_v0Wen  (p_v0Wen[2])
  );
  assign p_robIdx_flag[2]  = 1'b0;   // lat=0 流水无 robIdx 出口，核不读
  assign p_robIdx_value[2] = 8'h0;

  PipeWithFlush_9 pipes_3 (
    .clock                               (clock),
    .reset                               (reset),
    .io_flush_redirect_valid             (io_flush_redirect_valid),
    .io_flush_redirect_bits_robIdx_flag  (io_flush_redirect_bits_robIdx_flag),
    .io_flush_redirect_bits_robIdx_value (io_flush_redirect_bits_robIdx_value),
    .io_flush_redirect_bits_level        (io_flush_redirect_bits_level),
    .io_flush_og0Fail                    (io_flush_og0Fail),
    .io_flush_og1Fail                    (io_flush_og1Fail),
    .io_enq_valid                        (io_enq_valid & io_enq_bits_lat == 3'h3),
    .io_enq_bits_fuType                  (io_enq_bits_uop_fuType),
    .io_enq_bits_robIdx_flag             (io_enq_bits_uop_robIdx_flag),
    .io_enq_bits_robIdx_value            (io_enq_bits_uop_robIdx_value),
    .io_enq_bits_pdest                   (io_enq_bits_uop_pdest),
    .io_enq_bits_fpWen                   (io_enq_bits_uop_fpWen),
    .io_enq_bits_vecWen                  (io_enq_bits_uop_vecWen),
    .io_enq_bits_v0Wen                   (io_enq_bits_uop_v0Wen),
    .io_deq_valid                        (pipe_valid[3]),
    .io_deq_bits_fuType                  (p_fuType[3]),
    .io_deq_bits_robIdx_flag             (p_robIdx_flag[3]),
    .io_deq_bits_robIdx_value            (p_robIdx_value[3]),
    .io_deq_bits_pdest                   (p_pdest[3]),
    .io_deq_bits_fpWen                   (p_fpWen[3]),
    .io_deq_bits_vecWen                  (p_vecWen[3]),
    .io_deq_bits_v0Wen                   (p_v0Wen[3])
  );

  for (genvar i = 0; i < 4; i++) begin : g_pack
    assign pipe_robidx[i] = {p_robIdx_flag[i], p_robIdx_value[i]};
    assign pipe_bits[i]   = {p_fuType[i], p_pdest[i], p_fpWen[i], p_vecWen[i], p_v0Wen[i]};
  end

  xs_MultiWakeupQueue_core #(
    .N_PIPES (4),
    .PIPE_LAT('{1, 2, 0, 3}),
    .W       (W),
    .LD_CNT  (0),
    .LD_W    (2),
    .COPY_NUM(0),
    .COPY_W  (1),
    .WEN_MASK(46'h7)   // fpWen/vecWen/v0Wen
  ) u_core (
    .clock                (clock),
    .flush_redirect_valid (io_flush_redirect_valid),
    .flush_redirect_level (io_flush_redirect_bits_level),
    .flush_redirect_robidx({io_flush_redirect_bits_robIdx_flag, io_flush_redirect_bits_robIdx_value}),
    .flush_ld2cancel      (1'b0),   // 本变体无 loadDependency，无 load 取消
    .flush_og0fail        (io_flush_og0Fail),
    .flush_og1fail        (io_flush_og1Fail),
    .pipe_valid           (pipe_valid),
    .pipe_robidx          (pipe_robidx),
    .pipe_bits            (pipe_bits),
    .deq_valid            (deq_valid),
    .deq_bits             (deq_bits),
    .deq_copy             (/* 无复制件 */)
  );

  assign io_deq_valid = deq_valid;
  assign {io_deq_bits_fuType, io_deq_bits_pdest, io_deq_bits_fpWen, io_deq_bits_vecWen,
          io_deq_bits_v0Wen} = deq_bits;
endmodule
