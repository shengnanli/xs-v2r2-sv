// =============================================================================
// PrefetcherMonitor —— L1 预取器"动态开关"：按预取的及时性/有效性统计决定是否暂停预取
//
// 位置：DCacheImp 例化一份（prefetcherMonitor），输出 io.pf_ctrl 经 DCache 送给
//   L1 预取器（enable = 预取总开关，confidence = 预取置信度）。输入是每拍的事件脉冲：
//   timely.total_prefetch    —— 某条 LoadPipe 这拍有一次预取请求（三条 OR）；
//   timely.late_hit_prefetch —— 预取"晚到但命中"（load 已经到了、预取才到）；
//   timely.late_miss_prefetch—— MissQueue 报：预取晚到且 miss；
//   validity.good/bad_prefetch —— 替换出去的预取行：被访问过 = good，没被访问 = bad。
//
// 机制（Scala PrefetcherMonitor，enableDynamicPrefetcher=1 这一支）：
//   ① 及时性窗口：total/late_hit/late_miss 三个 11 位计数器按事件加 1；
//      当 total == 1000 或 late_hit >= 1000 时"窗口结束"（timely_reset），三者清 0。
//   ② 有效性窗口：good/bad 两个计数器；good+bad == 1000 时窗口结束（validity_reset），清 0。
//   ③ 关闭条件（只在窗口结束那一拍判）：
//        trigger_disable  = 有效性窗口结束 且 bad  >= 900（坏预取太多）；
//        trigger_late_hit = 及时性窗口结束 且 late_hit >= 900（预取总是太晚）；
//      任一成立 → enable=0、confidence=0。
//      ★例外★：Scala 用 when(late_miss)…elsewhen(late_hit)，late_miss 分支只调 depth，
//      所以同一拍 trigger_late_miss（及时性窗口结束且 late_miss >= 200）成立时，
//      late_hit 不起作用，只看 trigger_disable。
//   ④ 退避恢复：enable=0 期间 back_off_cnt 每拍 +1，数到 100000 清 0 且 enable 回 1；
//      confidence=0 期间 low_conf_cnt 每拍 +1，数到 200000 清 0 且 confidence 回 1。
//      恢复与关闭同拍时关闭优先（when(trigger) 写在 Mux(reset…) 之后）。
//   Scala 里的 depth / flush / prefetch_hit_cnt 以及 trigger_bad_prefetch
//   在本配置下都没有观察者（depth 被 Constantin 常量覆盖、flush 恒 0），firtool 已删，
//   这里也不写。
//
// 复位：全部寄存器异步复位（enable/confidence 复位为 1，计数器复位为 0），照搬 golden。
// =============================================================================

module PrefetcherMonitor(
  input  clock,
  input  reset,
  input  io_timely_total_prefetch,
  input  io_timely_late_hit_prefetch,
  input  io_timely_late_miss_prefetch,
  input  io_validity_good_prefetch,
  input  io_validity_bad_prefetch,
  output io_pf_ctrl_enable,
  output io_pf_ctrl_confidence
);

  // ---- 窗口长度与阈值（HasPrefetcherMonitorHelper）----
  localparam int TIMELY_CHECK_INTERVAL   = 1000;
  localparam int VALIDITY_CHECK_INTERVAL = 1000;
  localparam int DISABLE_THRESHOLD       = 900;
  localparam int LATE_HIT_THRESHOLD      = 900;
  localparam int LATE_MISS_THRESHOLD     = 200;
  localparam int BACK_OFF_INTERVAL       = 100000;
  localparam int LOW_CONF_INTERVAL       = 200000;

  // 计数器位宽 = log2Up(区间) + 1（与 Scala 一致）
  localparam int WIN_W      = $clog2(TIMELY_CHECK_INTERVAL) + 1;   // 11
  localparam int BACK_OFF_W = $clog2(BACK_OFF_INTERVAL) + 1;       // 18
  localparam int LOW_CONF_W = $clog2(LOW_CONF_INTERVAL) + 1;       // 19

  // ---- 状态 ----
  logic                  enable;
  logic                  confidence;
  logic [WIN_W-1:0]      total_prefetch_cnt;
  logic [WIN_W-1:0]      late_hit_prefetch_cnt;
  logic [WIN_W-1:0]      late_miss_prefetch_cnt;
  logic [WIN_W-1:0]      good_prefetch_cnt;
  logic [WIN_W-1:0]      bad_prefetch_cnt;
  logic [BACK_OFF_W-1:0] back_off_cnt;
  logic [LOW_CONF_W-1:0] low_conf_cnt;

  // ---- 窗口结束判定 ----
  wire [WIN_W-1:0] validity_sum = WIN_W'(good_prefetch_cnt + bad_prefetch_cnt);   // 11 位回绕加
  wire timely_reset   = (total_prefetch_cnt == WIN_W'(TIMELY_CHECK_INTERVAL)) |
                        (late_hit_prefetch_cnt >= WIN_W'(TIMELY_CHECK_INTERVAL));
  wire validity_reset = (validity_sum == WIN_W'(VALIDITY_CHECK_INTERVAL));
  wire back_off_reset = (back_off_cnt == BACK_OFF_W'(BACK_OFF_INTERVAL));
  wire conf_reset     = (low_conf_cnt == LOW_CONF_W'(LOW_CONF_INTERVAL));

  // ---- 关闭触发 ----
  wire trigger_disable   = validity_reset & (bad_prefetch_cnt       >= WIN_W'(DISABLE_THRESHOLD));
  wire trigger_late_hit  = timely_reset   & (late_hit_prefetch_cnt  >= WIN_W'(LATE_HIT_THRESHOLD));
  wire trigger_late_miss = timely_reset   & (late_miss_prefetch_cnt >= WIN_W'(LATE_MISS_THRESHOLD));
  // late_miss 分支压住 late_hit（见文件头 ③）
  wire turn_off = trigger_disable | (trigger_late_hit & ~trigger_late_miss);

  // 退避计时的加数。★必须先取反成 1 位再做位宽转换★：写成 N'(~enable) 时
  // 转换是"按赋值语境"求值的，enable 先被扩到 N 位再取反，得到 0x3FFFE/0x3FFFF
  // 而不是 0/1（本 lane UT 实测抓到过这个错）。
  wire disabled = ~enable;
  wire low_conf = ~confidence;

  // 下一拍的开关：先按退避计时恢复，再被关闭触发压成 0
  wire enable_next     = ~turn_off & (back_off_reset | enable);
  wire confidence_next = ~turn_off & (conf_reset | confidence);

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      enable                 <= 1'b1;
      confidence             <= 1'b1;
      total_prefetch_cnt     <= '0;
      late_hit_prefetch_cnt  <= '0;
      late_miss_prefetch_cnt <= '0;
      good_prefetch_cnt      <= '0;
      bad_prefetch_cnt       <= '0;
      back_off_cnt           <= '0;
      low_conf_cnt           <= '0;
    end
    else begin
      enable     <= enable_next;
      confidence <= confidence_next;

      // ① 及时性窗口
      if (timely_reset) begin
        total_prefetch_cnt     <= '0;
        late_hit_prefetch_cnt  <= '0;
        late_miss_prefetch_cnt <= '0;
      end
      else begin
        total_prefetch_cnt     <= total_prefetch_cnt     + WIN_W'(io_timely_total_prefetch);
        late_hit_prefetch_cnt  <= late_hit_prefetch_cnt  + WIN_W'(io_timely_late_hit_prefetch);
        late_miss_prefetch_cnt <= late_miss_prefetch_cnt + WIN_W'(io_timely_late_miss_prefetch);
      end

      // ② 有效性窗口
      if (validity_reset) begin
        good_prefetch_cnt <= '0;
        bad_prefetch_cnt  <= '0;
      end
      else begin
        good_prefetch_cnt <= good_prefetch_cnt + WIN_W'(io_validity_good_prefetch);
        bad_prefetch_cnt  <= bad_prefetch_cnt  + WIN_W'(io_validity_bad_prefetch);
      end

      // ④ 退避计时：关闭期间每拍 +1，到点清 0（同拍 enable/confidence 恢复）
      back_off_cnt <= back_off_reset ? '0 : back_off_cnt + BACK_OFF_W'(disabled);
      low_conf_cnt <= conf_reset     ? '0 : low_conf_cnt + LOW_CONF_W'(low_conf);
    end
  end

  assign io_pf_ctrl_enable     = enable;
  assign io_pf_ctrl_confidence = confidence;

endmodule
