// MultiWakeupQueue_5.sv —— 浮点 IQ 的推测唤醒延迟队列：lat∈{1,3} 两条流水，无复制件
// -----------------------------------------------------------------------------
// 机制见 xs_MultiWakeupQueue_core.sv。本文件 = golden 同名端口表 + 两条流水子模块
// （PipeWithFlush_10/11，已签核件，实例名与 golden 相同）+ 核的拼包/拆包。
//
// 本变体（G1 golden MultiWakeupQueue_5.sv，被 IssueQueueFaluFmac 与
// IssueQueueFaluFmacFdiv 例化）：
//   pipes_0 = PipeWithFlush_10 ：lat=1，出口判 redirect / og0Fail；
//   pipes_1 = PipeWithFlush_11 ：lat=3，出口只判 redirect。
//   载荷 9 位 = {pdest 8, fpWen}；无 fuType、无 loadDependency、无复制件。
//   golden 寄存器：lastConnect_* 共 1+9 = 10 位，全部不复位。
// =============================================================================
module MultiWakeupQueue_5(
  input        clock,
  input        reset,
  input        io_flush_redirect_valid,
  input        io_flush_redirect_bits_robIdx_flag,
  input  [7:0] io_flush_redirect_bits_robIdx_value,
  input        io_flush_redirect_bits_level,
  input        io_flush_og0Fail,
  input        io_flush_og1Fail,
  input        io_enq_valid,
  input        io_enq_bits_uop_robIdx_flag,
  input  [7:0] io_enq_bits_uop_robIdx_value,
  input  [7:0] io_enq_bits_uop_pdest,
  input        io_enq_bits_uop_fpWen,
  input  [2:0] io_enq_bits_lat,
  output       io_deq_valid,
  output [7:0] io_deq_bits_pdest,
  output       io_deq_bits_fpWen
);
  localparam int W = 9;

  logic         pipe_valid  [2];
  logic [8:0]   pipe_robidx [2];
  logic [W-1:0] pipe_bits   [2];
  logic         deq_valid;
  logic [W-1:0] deq_bits;

  logic [7:0] p_pdest [2];
  logic       p_fpWen [2];
  logic       p_robIdx_flag  [2];
  logic [7:0] p_robIdx_value [2];

  PipeWithFlush_10 pipes_0 (
    .clock                    (clock),
    .reset                    (reset),
    .io_enq_valid             (io_enq_valid & io_enq_bits_lat == 3'h1),
    .io_enq_bits_robIdx_flag  (io_enq_bits_uop_robIdx_flag),
    .io_enq_bits_robIdx_value (io_enq_bits_uop_robIdx_value),
    .io_enq_bits_pdest        (io_enq_bits_uop_pdest),
    .io_enq_bits_fpWen        (io_enq_bits_uop_fpWen),
    .io_deq_valid             (pipe_valid[0]),
    .io_deq_bits_robIdx_flag  (p_robIdx_flag[0]),
    .io_deq_bits_robIdx_value (p_robIdx_value[0]),
    .io_deq_bits_pdest        (p_pdest[0]),
    .io_deq_bits_fpWen        (p_fpWen[0])
  );

  PipeWithFlush_11 pipes_1 (
    .clock                               (clock),
    .reset                               (reset),
    .io_flush_redirect_valid             (io_flush_redirect_valid),
    .io_flush_redirect_bits_robIdx_flag  (io_flush_redirect_bits_robIdx_flag),
    .io_flush_redirect_bits_robIdx_value (io_flush_redirect_bits_robIdx_value),
    .io_flush_redirect_bits_level        (io_flush_redirect_bits_level),
    .io_flush_og0Fail                    (io_flush_og0Fail),
    .io_flush_og1Fail                    (io_flush_og1Fail),
    .io_enq_valid                        (io_enq_valid & io_enq_bits_lat == 3'h3),
    .io_enq_bits_robIdx_flag             (io_enq_bits_uop_robIdx_flag),
    .io_enq_bits_robIdx_value            (io_enq_bits_uop_robIdx_value),
    .io_enq_bits_pdest                   (io_enq_bits_uop_pdest),
    .io_enq_bits_fpWen                   (io_enq_bits_uop_fpWen),
    .io_deq_valid                        (pipe_valid[1]),
    .io_deq_bits_robIdx_flag             (p_robIdx_flag[1]),
    .io_deq_bits_robIdx_value            (p_robIdx_value[1]),
    .io_deq_bits_pdest                   (p_pdest[1]),
    .io_deq_bits_fpWen                   (p_fpWen[1])
  );

  for (genvar i = 0; i < 2; i++) begin : g_pack
    assign pipe_robidx[i] = {p_robIdx_flag[i], p_robIdx_value[i]};
    assign pipe_bits[i]   = {p_pdest[i], p_fpWen[i]};
  end

  xs_MultiWakeupQueue_core #(
    .N_PIPES (2),
    .PIPE_LAT('{1, 3}),
    .W       (W),
    .LD_CNT  (0),
    .LD_W    (2),
    .COPY_NUM(0),
    .COPY_W  (1),
    .WEN_MASK(9'h1)    // fpWen
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
  assign {io_deq_bits_pdest, io_deq_bits_fpWen} = deq_bits;
endmodule
