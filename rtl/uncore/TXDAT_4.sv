// =============================================================================
//  TXDAT_4 —— openLLC CHI DAT 发送通道 可读重写核 (xs_TXDAT_4_core)
// -----------------------------------------------------------------------------
//  对照 Scala: openLLC/src/main/scala/openLLC/chi/TXDAT.scala
//  LLC(L3) 侧: 把一个携带整行数据 (2 个 256-bit beat) 的内部 Task 缓存进单条目缓冲,
//  然后每拍逐 beat 以 CHIDAT flit 发往 CHI 互联。beatSize=2。
//
//  ===== 状态 =====
//    beat0_valid / beat1_valid : 缓冲里两个 beat 是否还未发送
//    buffer_*                   : 锁存的任务头字段 + 两拍数据 (task.fire 时整体载入)
//
//  ===== 发送顺序 (PriorityEncoder: 先发 beat0 再 beat1) =====
//    beat_id = beat0_valid ? 0 : 1
//    dataID  = beat0_valid ? 2'b00(first) : 2'b10(last)
//    data    = beat0_valid ? beat0 数据 : beat1 数据
//
//  ===== 握手 =====
//    dat.valid = 缓冲非空; dat.fire = dat.valid & dat_ready ⇒ 当拍发出一个 beat
//    task.ready = 缓冲空 | (只剩最后一个 beat 且本拍正发出)  ⇒ 可载入新任务
//
//  ===== DataCheck =====
//    每字节输出 ~(该字节奇偶)  (CHI DataCheck = 取反的逐字节奇偶位)
//  ===== 其它常量字段 =====
//    be = 全 1 (32 字节全有效); dataSource = {1'b0, fwdState}; opcode = chiOpcode[3:0]
// =============================================================================
module xs_TXDAT_4_core (
  input          clock,
  input          reset,
  // ---- io.dat (DecoupledIO CHIDAT, 发往 CHI 互联) ----
  input          io_dat_ready,
  output         io_dat_valid,
  output [10:0]  io_dat_bits_tgtID,
  output [10:0]  io_dat_bits_srcID,
  output [11:0]  io_dat_bits_txnID,
  output [10:0]  io_dat_bits_homeNID,
  output [3:0]   io_dat_bits_opcode,
  output [2:0]   io_dat_bits_resp,
  output [3:0]   io_dat_bits_dataSource,
  output [11:0]  io_dat_bits_dbID,
  output [1:0]   io_dat_bits_dataID,
  output [31:0]  io_dat_bits_be,
  output [255:0] io_dat_bits_data,
  output [31:0]  io_dat_bits_dataCheck,
  // ---- io.task (Flipped DecoupledIO TaskWithData, 来自 LLC 内部) ----
  output         io_task_ready,
  input          io_task_valid,
  input  [10:0]  io_task_bits_task_tgtID,
  input  [10:0]  io_task_bits_task_srcID,
  input  [11:0]  io_task_bits_task_txnID,
  input  [10:0]  io_task_bits_task_homeNID,
  input  [11:0]  io_task_bits_task_dbID,
  input  [6:0]   io_task_bits_task_chiOpcode,
  input  [2:0]   io_task_bits_task_resp,
  input  [2:0]   io_task_bits_task_fwdState,
  input  [255:0] io_task_bits_data_data_0_data,
  input  [255:0] io_task_bits_data_data_1_data
);

  // ---- 状态寄存器 ----
  reg          beat0_valid, beat1_valid;
  reg  [10:0]  buffer_task_tgtID;
  reg  [10:0]  buffer_task_srcID;
  reg  [11:0]  buffer_task_txnID;
  reg  [10:0]  buffer_task_homeNID;
  reg  [11:0]  buffer_task_dbID;
  reg  [6:0]   buffer_task_chiOpcode;
  reg  [2:0]   buffer_task_resp;
  reg  [2:0]   buffer_task_fwdState;
  reg  [255:0] buffer_data_0;
  reg  [255:0] buffer_data_1;

  // ---- 握手 ----
  wire buffer_nonempty = beat0_valid | beat1_valid;
  wire last_beat = ~beat0_valid & beat1_valid;        // 只剩 beat1 待发
  wire task_ready = ~buffer_nonempty | (last_beat & io_dat_ready);
  wire task_fire  = task_ready & io_task_valid;
  wire dat_fire   = io_dat_ready & buffer_nonempty;    // 本拍发出一个 beat
  assign io_task_ready = task_ready;

  // ---- 状态更新 (异步复位) ----
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      beat0_valid <= 1'h0;
      beat1_valid <= 1'h0;
      buffer_task_tgtID     <= 11'h0;
      buffer_task_srcID     <= 11'h0;
      buffer_task_txnID     <= 12'h0;
      buffer_task_homeNID   <= 11'h0;
      buffer_task_dbID      <= 12'h0;
      buffer_task_chiOpcode <= 7'h0;
      buffer_task_resp      <= 3'h0;
      buffer_task_fwdState  <= 3'h0;
      buffer_data_0 <= 256'h0;
      buffer_data_1 <= 256'h0;
    end
    else begin
      // 载入新任务时两 beat 全置有效; 否则发出哪个 beat 就清哪个 (先 beat0 后 beat1)
      beat0_valid <= task_fire | (beat0_valid & ~(dat_fire & beat0_valid));
      beat1_valid <= task_fire | (beat1_valid & ~(dat_fire & ~beat0_valid));
      if (task_fire) begin
        buffer_task_tgtID     <= io_task_bits_task_tgtID;
        buffer_task_srcID     <= io_task_bits_task_srcID;
        buffer_task_txnID     <= io_task_bits_task_txnID;
        buffer_task_homeNID   <= io_task_bits_task_homeNID;
        buffer_task_dbID      <= io_task_bits_task_dbID;
        buffer_task_chiOpcode <= io_task_bits_task_chiOpcode;
        buffer_task_resp      <= io_task_bits_task_resp;
        buffer_task_fwdState  <= io_task_bits_task_fwdState;
        buffer_data_0 <= io_task_bits_data_data_0_data;
        buffer_data_1 <= io_task_bits_data_data_1_data;
      end
    end
  end

  // ---- 输出选择: 先发 beat0 再 beat1 ----
  wire [255:0] sel_data = beat0_valid ? buffer_data_0 : buffer_data_1;
  wire [31:0]  sel_dataCheck;
  genvar i;
  generate
    for (i = 0; i < 32; i = i + 1) begin : g_datacheck
      assign sel_dataCheck[i] = ~(^sel_data[8*i +: 8]);
    end
  endgenerate

  assign io_dat_valid           = buffer_nonempty;
  assign io_dat_bits_tgtID      = buffer_task_tgtID;
  assign io_dat_bits_srcID      = buffer_task_srcID;
  assign io_dat_bits_txnID      = buffer_task_txnID;
  assign io_dat_bits_homeNID    = buffer_task_homeNID;
  assign io_dat_bits_opcode     = buffer_task_chiOpcode[3:0];
  assign io_dat_bits_resp       = buffer_task_resp;
  assign io_dat_bits_dataSource = {1'h0, buffer_task_fwdState};
  assign io_dat_bits_dbID       = buffer_task_dbID;
  assign io_dat_bits_dataID     = {~beat0_valid, 1'h0};
  assign io_dat_bits_be         = 32'hFFFFFFFF;
  assign io_dat_bits_data       = sel_data;
  assign io_dat_bits_dataCheck  = sel_dataCheck;

endmodule
