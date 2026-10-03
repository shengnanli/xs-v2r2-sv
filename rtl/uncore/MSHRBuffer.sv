// MSHRBuffer.sv —— L2 slice 的 MSHR 数据暂存缓冲（每个 MSHR 一个 cache 块大小的槽）
//
// 在 coupledL2（tl2chi）Slice 里有两份：
//   * refillBuf（本文件的 MSHRBuffer）：暂存从下游（CHI RXDAT）回来的 refill 数据，
//     2 个写口：w_0 = RXDAT（按 beat 写，带 beatMask），w_1 = MainPipe（整块写）。
//   * releaseBuf（MSHRBuffer_1.sv）：暂存要写回/释放的数据，3 个写口（SinkC 的
//     ProbeAck 数据、MainPipe s3 读出的数据、……），**全都整块写**，没有 beatMask。
// 两者是同一个 Chisel 类 `coupledL2.MSHRBuffer(wPorts)` 的两个单态化，逻辑完全相同，
// 差别只在写口数和 w_0 有没有 beatMask，所以共用本文件的参数化核 xs_MSHRBuffer_core。
//
// 机制（对照 MSHRBuffer.scala）：
//   * 存储：16 个槽（mshrsAll）× 2 个 beat × 256 位；**无复位**（golden `Reg(Vec(...))`）。
//   * 写：对每个槽 i，看哪些写口本拍命中（w.valid && w.id == i，id 按 8 位全宽比较）；
//     有命中时按**口号越小越优先**（PriorityMux）选出数据和 beatMask，beatMask 的
//     第 b 位为 1 才写第 b 个 beat。没有 beatMask 的口视为 2'b11（整块写）。
//   * 读：r.valid 那一拍用 id 的**低 4 位**选槽（更高位被截掉），把两个 beat 拼成
//     512 位锁进 resp 寄存器（异步复位清 0；golden RegEnable(rdata, 0, r.valid)），
//     所以读数据在下一拍出现，r.valid 无效时保持上一次读到的值。
//   * golden 里"同一槽三写"的 assert 在 `ifndef SYNTHESIS 里，不属于电路，本重写不带。

module xs_MSHRBuffer_core #(
  parameter int unsigned N_WPORT = 2,   // 写口数
  parameter int unsigned N_ENTRY = 16,  // 槽数 = mshrsAll
  parameter int unsigned N_BEAT  = 2,   // 每块 beat 数（blockBytes / beatBytes）
  parameter int unsigned BEAT_W  = 256, // 每 beat 位宽
  parameter int unsigned ID_W    = 8    // id 位宽（mshrBits）
)(
  input  logic                       clock,
  input  logic                       reset,
  // 读口：本拍给 id，下一拍在 r_data 看到
  input  logic                       r_valid,
  input  logic [ID_W-1:0]            r_id,
  output logic [N_BEAT*BEAT_W-1:0]   r_data,
  // 写口：w_mask 第 b 位 = 写第 b 个 beat（无 beatMask 的口由 wrapper 接全 1）
  input  logic                       w_valid [N_WPORT],
  input  logic [ID_W-1:0]            w_id    [N_WPORT],
  input  logic [N_BEAT*BEAT_W-1:0]   w_data  [N_WPORT],
  input  logic [N_BEAT-1:0]          w_mask  [N_WPORT]
);

  localparam int unsigned IDX_W = $clog2(N_ENTRY);

  // ---- 存储阵列（不复位）----
  logic [BEAT_W-1:0] buffer [N_ENTRY][N_BEAT];

  // ---- 写：每个槽独立判命中、按口号优先级选数据 ----
  for (genvar i = 0; i < int'(N_ENTRY); i++) begin : g_entry
    logic                     hit;        // 本拍有口写这个槽
    logic [N_BEAT*BEAT_W-1:0] selData;    // 优先级最高的命中口的数据
    logic [N_BEAT-1:0]        selMask;    // 以及它的 beatMask

    always_comb begin
      hit     = 1'b0;
      selData = w_data[N_WPORT-1];        // PriorityMux：全不命中时落到最后一口（无所谓，hit=0 不写）
      selMask = w_mask[N_WPORT-1];
      for (int p = int'(N_WPORT) - 1; p >= 0; p--) begin
        if (w_valid[p] && w_id[p] == ID_W'(i)) begin
          hit     = 1'b1;
          selData = w_data[p];            // 从高往低扫，最后留下的是最小口号
          selMask = w_mask[p];
        end
      end
    end

    for (genvar b = 0; b < int'(N_BEAT); b++) begin : g_beat
      always_ff @(posedge clock) begin
        if (hit && selMask[b])
          buffer[i][b] <= selData[b*BEAT_W +: BEAT_W];
      end
    end
  end

  // ---- 读：id 低位选槽，打一拍输出 ----
  logic [N_BEAT*BEAT_W-1:0] readBlock;
  always_comb begin
    for (int b = 0; b < int'(N_BEAT); b++)
      readBlock[b*BEAT_W +: BEAT_W] = buffer[r_id[IDX_W-1:0]][b];
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      r_data <= '0;
    else if (r_valid)
      r_data <= readBlock;
  end

endmodule

// MSHRBuffer —— refillBuf：2 写口，w_0 带 beatMask，w_1 整块写。
module MSHRBuffer (
  input  logic         clock,
  input  logic         reset,
  input  logic         io_r_valid,
  input  logic [7:0]   io_r_bits_id,
  output logic [511:0] io_resp_data_data,
  input  logic         io_w_0_valid,
  input  logic [7:0]   io_w_0_bits_id,
  input  logic [511:0] io_w_0_bits_data_data,
  input  logic [1:0]   io_w_0_bits_beatMask,
  input  logic         io_w_1_valid,
  input  logic [7:0]   io_w_1_bits_id,
  input  logic [511:0] io_w_1_bits_data_data
);

  xs_MSHRBuffer_core #(.N_WPORT(2)) u_core (
    .clock   (clock),
    .reset   (reset),
    .r_valid (io_r_valid),
    .r_id    (io_r_bits_id),
    .r_data  (io_resp_data_data),
    .w_valid ('{io_w_0_valid, io_w_1_valid}),
    .w_id    ('{io_w_0_bits_id, io_w_1_bits_id}),
    .w_data  ('{io_w_0_bits_data_data, io_w_1_bits_data_data}),
    .w_mask  ('{io_w_0_bits_beatMask, 2'b11})
  );

endmodule
