// =============================================================================
//  storequeue_perf.svh —— §16 8 路性能计数（每路 1 bit 事件，双拍寄存后零扩到 6 位）
//   语义与 golden 一致：mmio 忙/请求/写回成功/写回阻塞 + 队列占用 4 个分桶。
// =============================================================================
  // perfValidCount = distanceBetween(enq, deq)（与 §1 validCount 同义，6 位）
  wire [SQ_IDX_W-1:0] perfValidCount = validCount;

  // 8 路事件（组合）
  wire perf_ev0 = (mmioState != MMIO_IDLE);                       // mmio 忙
  wire perf_ev1 = mmioDoReq;                                      // mmio 请求
  wire perf_ev2 = mmioStout_fire | vecmmioStout_fire;            // mmio 写回成功
  wire perf_ev3 = io_mmioStout_valid & ~io_mmioStout_ready;      // mmio 写回阻塞
  wire perf_ev4 = perfValidCount < 7'hE;                          // 队列 1/4 占用
  wire perf_ev5 = (perfValidCount > 7'hE) & (perfValidCount < 7'h1D);  // 2/4
  wire perf_ev6 = (perfValidCount > 7'h1C) & (perfValidCount < 7'h2B); // 3/4
  wire perf_ev7 = (perfValidCount > 7'h2A);                       // 4/4

  // 双拍寄存
  logic [PERF_NUM-1:0] perf_q1, perf_q2;
  always_ff @(posedge clock) begin
    perf_q1 <= {perf_ev7, perf_ev6, perf_ev5, perf_ev4, perf_ev3, perf_ev2, perf_ev1, perf_ev0};
    perf_q2 <= perf_q1;
  end
  assign io_perf_0_value = {5'h0, perf_q2[0]};
  assign io_perf_1_value = {5'h0, perf_q2[1]};
  assign io_perf_2_value = {5'h0, perf_q2[2]};
  assign io_perf_3_value = {5'h0, perf_q2[3]};
  assign io_perf_4_value = {5'h0, perf_q2[4]};
  assign io_perf_5_value = {5'h0, perf_q2[5]};
  assign io_perf_6_value = {5'h0, perf_q2[6]};
  assign io_perf_7_value = {5'h0, perf_q2[7]};
