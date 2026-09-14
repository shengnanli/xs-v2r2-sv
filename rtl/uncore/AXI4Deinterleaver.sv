// =============================================================================
//  axi4deint_pkg —— AXI4Deinterleaver (读响应去交织适配器) 常量与工具函数
// -----------------------------------------------------------------------------
//  对应 rocket-chip 的 AXI4Deinterleaver (src/main/scala/amba/axi4/Deinterleaver.scala)。
//
//  作用: AXI 从设备允许把不同事务 (不同 ID) 的读响应 (R 通道 burst) 在节拍上交织返回;
//  但某些上游主设备 (interleavedId=0) 要求"一旦某 burst 的首拍被接收, 后续节拍必须连续
//  属于同一 burst 直到 last"。本适配器把交织的 R 流"去交织"成不交织的 R 流。
//
//  机制 (按 ID 分桶 + 整 burst 锁定):
//    [A] 每个在用 ID 配一个深度=beats 的小队列 (Queue2_AXI4BundleR_3, 黑盒)。下游 (out)
//        返回的 R 拍按其 ID 入对应队列 —— 这样不同 ID 的交织拍被拆进各自队列分别缓存。
//    [B] 每个 ID 维护一个 pending 计数 (已完整收齐的 burst 个数): 收到该 ID 的 last 拍 +1,
//        向上游 (in) 吐出该 ID 的 last 拍 -1。pending!=0 表示该 ID 至少攒齐了一整个 burst。
//    [C] 上游发送由 locked/deq_id 状态机锁定: 空闲或刚吐完一个 burst 的 last 拍时, 从所有
//        pending!=0 的 ID 中选最低号 (优先编码) 作为下一个 deq_id 并 locked=1; 锁定期间只吐
//        deq_id 这一个 ID 的拍, 直到其 last —— 从而保证上游看到的 R 流不交织。
//
//  AW/AR/W 控制与写数据通道, 以及 B 写响应通道, 全部透传 (本适配器只改 R 通道)。
//
//  本实例参数 (按 golden 例化):
//    endId  = 96  (在用 ID 数, 0..95 全部在用 → 96 个队列 + 96 个 pending 计数)
//    beats  = 2   (单 burst 最多 2 拍 → 队列深度 2, pending 计数 2 位, 满=2)
//    ID 宽  = 7   (log2Up(96)=7), data 宽 = 256, addr 宽 = 48, strb 宽 = 32
//
//  注: out.r 携带 resp 字段进队列 (io_enq_bits_resp), 但上游 in.r 端口无 resp 字段, 故出队
//  侧不取 resp (与 golden 一致)。
//
//  验证: golden 同名 AXI4Deinterleaver 例化本核 (端口透传) + 黑盒 Queue2_AXI4BundleR_3。
// =============================================================================
package axi4deint_pkg;

  localparam int NUM_ID = 96;   // 在用 ID 数 (endId); 每 ID 一个队列 + 一个 pending 计数
  localparam int ID_W   = 7;    // AXI ID 位宽 (log2Up(NUM_ID))
  localparam int BEATS  = 2;    // 单读 burst 最大节拍数 (= 队列深度)
  localparam int CNT_W  = 2;    // pending 计数位宽 (log2Ceil(BEATS+1))
  localparam int DATA_W = 256;  // R/W 数据位宽
  localparam int STRB_W = 32;   // W 选通位宽
  localparam int ADDR_W = 48;   // AW/AR 地址位宽

  //  注: golden 把"按 ID 选 deq 数据 / 按 ID 选 enq 就绪"的多路选择器展平成 128 项 packed
  //  数组, 并把越界项 [96..127] 全部填成第 0 项 (firtool 的 padding)。本核在 core 内用
  //  "默认第 0 桶 + 常量下标命中覆盖"的等价多路选择实现该 padding 语义 (详见 core 注释)。

endpackage

// =============================================================================
//  AXI4Deinterleaver —— AXI4 读响应去交织适配器 (可读重写核 xs_AXI4Deinterleaver_core)
// -----------------------------------------------------------------------------
//  源自 rocket-chip AXI4Deinterleaver (src/main/scala/amba/axi4/Deinterleaver.scala)。
//  从设计意图重写 (非照抄 firtool 展平后的 5572 行逐 ID 复制 + _GEN_/_T_ 临时名)。
//
//  数据通路 (详见 axi4deint_pkg 头注释):
//    · AW / AR / W 控制+写数据: in → out 透传; B 写响应: out → in 透传 (本核不改)。
//    · R 读响应: 按 ID 分桶去交织 —— 96 个深度 2 队列 (Queue2_AXI4BundleR_3, 黑盒) 各缓存
//      一个 ID 的 R 拍; pending[id] 计每个 ID 攒齐的整 burst 数; locked/deq_id 状态机选最低
//      号 pending!=0 的 ID 并锁定到其 last 拍, 保证上游 R 流不交织。
//
//  关键时序 (与 golden 一致):
//    · locked / pending_count[*]: 异步复位清 0。
//    · deq_id: 无复位 (仅 posedge clock, 选中换桶时更新)。
//    · pending / locked / deq_id 的下拍值均用 pending 的"次态" (count 加减后) 计算。
//
//  验证: golden 同名 AXI4Deinterleaver 例化本核 + 黑盒队列; UT 双例化逐拍比对全部输出
//  (下游随机交织 R 响应 + 随机 ID/握手 + 上游随机 R ready, 覆盖分桶/锁定/优先选择); FM 证等价。
// =============================================================================

module xs_AXI4Deinterleaver_core
  import axi4deint_pkg::*;
(
  input          clock,
  input          reset,
  // ---- 上游主口 in (面向要求不交织的主设备) ----
  output         auto_in_aw_ready,
  input          auto_in_aw_valid,
  input  [6:0]   auto_in_aw_bits_id,
  input  [47:0]  auto_in_aw_bits_addr,
  input  [7:0]   auto_in_aw_bits_len,
  input  [2:0]   auto_in_aw_bits_size,
  input  [1:0]   auto_in_aw_bits_burst,
  input  [3:0]   auto_in_aw_bits_cache,
  input  [2:0]   auto_in_aw_bits_prot,
  input  [3:0]   auto_in_aw_bits_qos,
  output         auto_in_w_ready,
  input          auto_in_w_valid,
  input  [255:0] auto_in_w_bits_data,
  input  [31:0]  auto_in_w_bits_strb,
  input          auto_in_w_bits_last,
  input          auto_in_b_ready,
  output         auto_in_b_valid,
  output [6:0]   auto_in_b_bits_id,
  output         auto_in_ar_ready,
  input          auto_in_ar_valid,
  input  [6:0]   auto_in_ar_bits_id,
  input  [47:0]  auto_in_ar_bits_addr,
  input  [7:0]   auto_in_ar_bits_len,
  input  [2:0]   auto_in_ar_bits_size,
  input  [1:0]   auto_in_ar_bits_burst,
  input  [3:0]   auto_in_ar_bits_cache,
  input  [2:0]   auto_in_ar_bits_prot,
  input  [3:0]   auto_in_ar_bits_qos,
  input          auto_in_r_ready,
  output         auto_in_r_valid,
  output [6:0]   auto_in_r_bits_id,
  output [255:0] auto_in_r_bits_data,
  output         auto_in_r_bits_last,
  // ---- 下游从口 out (面向允许交织的从设备) ----
  input          auto_out_aw_ready,
  output         auto_out_aw_valid,
  output [6:0]   auto_out_aw_bits_id,
  output [47:0]  auto_out_aw_bits_addr,
  output [7:0]   auto_out_aw_bits_len,
  output [2:0]   auto_out_aw_bits_size,
  output [1:0]   auto_out_aw_bits_burst,
  output [3:0]   auto_out_aw_bits_cache,
  output [2:0]   auto_out_aw_bits_prot,
  output [3:0]   auto_out_aw_bits_qos,
  input          auto_out_w_ready,
  output         auto_out_w_valid,
  output [255:0] auto_out_w_bits_data,
  output [31:0]  auto_out_w_bits_strb,
  output         auto_out_w_bits_last,
  output         auto_out_b_ready,
  input          auto_out_b_valid,
  input  [6:0]   auto_out_b_bits_id,
  input          auto_out_ar_ready,
  output         auto_out_ar_valid,
  output [6:0]   auto_out_ar_bits_id,
  output [47:0]  auto_out_ar_bits_addr,
  output [7:0]   auto_out_ar_bits_len,
  output [2:0]   auto_out_ar_bits_size,
  output [1:0]   auto_out_ar_bits_burst,
  output [3:0]   auto_out_ar_bits_cache,
  output [2:0]   auto_out_ar_bits_prot,
  output [3:0]   auto_out_ar_bits_qos,
  output         auto_out_r_ready,
  input          auto_out_r_valid,
  input  [6:0]   auto_out_r_bits_id,
  input  [255:0] auto_out_r_bits_data,
  input  [1:0]   auto_out_r_bits_resp,
  input          auto_out_r_bits_last
);

  // ===========================================================================
  //  [1] 透传通道: AW / AR / W 沿 in→out, B 沿 out→in (本适配器不改这些通道)
  // ===========================================================================
  assign auto_in_aw_ready      = auto_out_aw_ready;
  assign auto_out_aw_valid     = auto_in_aw_valid;
  assign auto_out_aw_bits_id   = auto_in_aw_bits_id;
  assign auto_out_aw_bits_addr = auto_in_aw_bits_addr;
  assign auto_out_aw_bits_len  = auto_in_aw_bits_len;
  assign auto_out_aw_bits_size = auto_in_aw_bits_size;
  assign auto_out_aw_bits_burst= auto_in_aw_bits_burst;
  assign auto_out_aw_bits_cache= auto_in_aw_bits_cache;
  assign auto_out_aw_bits_prot = auto_in_aw_bits_prot;
  assign auto_out_aw_bits_qos  = auto_in_aw_bits_qos;

  assign auto_in_w_ready       = auto_out_w_ready;
  assign auto_out_w_valid      = auto_in_w_valid;
  assign auto_out_w_bits_data  = auto_in_w_bits_data;
  assign auto_out_w_bits_strb  = auto_in_w_bits_strb;
  assign auto_out_w_bits_last  = auto_in_w_bits_last;

  assign auto_out_b_ready      = auto_in_b_ready;
  assign auto_in_b_valid       = auto_out_b_valid;
  assign auto_in_b_bits_id     = auto_out_b_bits_id;

  assign auto_in_ar_ready      = auto_out_ar_ready;
  assign auto_out_ar_valid     = auto_in_ar_valid;
  assign auto_out_ar_bits_id   = auto_in_ar_bits_id;
  assign auto_out_ar_bits_addr = auto_in_ar_bits_addr;
  assign auto_out_ar_bits_len  = auto_in_ar_bits_len;
  assign auto_out_ar_bits_size = auto_in_ar_bits_size;
  assign auto_out_ar_bits_burst= auto_in_ar_bits_burst;
  assign auto_out_ar_bits_cache= auto_in_ar_bits_cache;
  assign auto_out_ar_bits_prot = auto_in_ar_bits_prot;
  assign auto_out_ar_bits_qos  = auto_in_ar_bits_qos;

  // ===========================================================================
  //  [2] R 通道去交织
  // ===========================================================================
  // ---- 状态寄存器 ----
  logic                  locked;                 // 是否正锁定在某个 burst 上发送
  logic [ID_W-1:0]       deq_id;                 // 当前 (或下一个) 出队的 ID (无复位)
  logic [CNT_W-1:0]      pending_count [NUM_ID]; // 每 ID 已攒齐的整 burst 数

  // ---- 每 ID 的队列接口线 ----
  logic                  q_enq_ready [NUM_ID];   // 各队列入队就绪
  logic [ID_W-1:0]       q_deq_id    [NUM_ID];   // 各队列队首 ID
  logic [DATA_W-1:0]     q_deq_data  [NUM_ID];   // 各队列队首 data
  logic                  q_deq_last  [NUM_ID];   // 各队列队首 last

  // ---- 组合派生 ----
  logic [NUM_ID-1:0]     enq_OH;                 // 入队 ID one-hot (out.r.bits.id 译码)
  logic [NUM_ID-1:0]     deq_OH;                 // 出队 ID one-hot (deq_id 译码)
  logic [NUM_ID-1:0]     pending_inc;            // 各 ID 本拍 +1 (收到该 ID 的 last)
  logic [NUM_ID-1:0]     pending_dec;            // 各 ID 本拍 -1 (吐出该 ID 的 last)
  logic [CNT_W-1:0]      pending_next [NUM_ID];  // 各 ID pending 计数次态
  logic [NUM_ID-1:0]     pending;                // 各 ID 次态 pending!=0 (攒齐≥1 个 burst)
  logic [NUM_ID-1:0]     pref_or;                // pending 的前缀 OR (leftOR): pref_or[i]=|pending[i:0]
  logic [NUM_ID-1:0]     winner;                 // pending 中最低号的那一位 (优先选择)

  // ---- 按 ID 选桶的多路选择器 (常量下标遍历, 默认取第 0 桶) ----
  //  golden 把这些选择器展平成 128 项 packed 数组并把越界项 [96..127] 填成第 0 项;
  //  这里用"默认 = 第 0 桶 + 命中即覆盖"等价实现: deq_id/enq_id 落 [0,95] 时取对应桶,
  //  落 [96,127] 时无命中保持默认第 0 桶 —— 与 golden 越界 padding 逐位一致, 且下标恒为
  //  编译期常量, 不触发越界访问 (FM 全值域可证)。
  logic              nodeIn_r_bits_last; // 上游送出的 last = deq_id 桶队首 last
  logic [ID_W-1:0]   sel_deq_id;         // deq_id 桶队首 id
  logic [DATA_W-1:0] sel_deq_data;       // deq_id 桶队首 data
  logic              nodeOut_r_ready;    // 下游就绪 = enq_id 桶入队就绪

  always_comb begin
    nodeIn_r_bits_last = q_deq_last[0];
    sel_deq_id         = q_deq_id[0];
    sel_deq_data       = q_deq_data[0];
    for (int k = 0; k < NUM_ID; k++)
      if (deq_id == ID_W'(k)) begin
        nodeIn_r_bits_last = q_deq_last[k];
        sel_deq_id         = q_deq_id[k];
        sel_deq_data       = q_deq_data[k];
      end
  end

  always_comb begin
    nodeOut_r_ready = q_enq_ready[0];
    for (int k = 0; k < NUM_ID; k++)
      if (auto_out_r_bits_id == ID_W'(k)) nodeOut_r_ready = q_enq_ready[k];
  end

  // 握手 fire 信号
  wire in_r_fire  = auto_in_r_ready & locked;            // 上游 R 成交 (in.r.valid=locked)
  wire out_r_fire = nodeOut_r_ready & auto_out_r_valid;  // 下游 R 成交

  // 逐 ID 组合逻辑
  genvar gi;
  generate
    for (gi = 0; gi < NUM_ID; gi++) begin : g_id
      assign enq_OH[gi] = (auto_out_r_bits_id == ID_W'(gi));
      assign deq_OH[gi] = (deq_id == ID_W'(gi));
      // +1: 该 ID 入队且本拍是 burst 末拍; -1: 该 ID 出队且本拍是 burst 末拍
      assign pending_inc[gi] = enq_OH[gi] & out_r_fire & auto_out_r_bits_last;
      assign pending_dec[gi] = deq_OH[gi] & in_r_fire  & nodeIn_r_bits_last;
      // 2 位回绕计数: count + inc - dec
      assign pending_next[gi] =
        pending_count[gi] + {1'b0, pending_inc[gi]} - {1'b0, pending_dec[gi]};
      assign pending[gi] = |pending_next[gi];
      // 前缀 OR (leftOR): 低位起累积
      if (gi == 0) begin : g_pref0
        assign pref_or[0]  = pending[0];
        assign winner[0]   = pending[0];               // 最低位无更低位, 直接是候选
      end else begin : g_prefN
        assign pref_or[gi] = pref_or[gi-1] | pending[gi];
        assign winner[gi]  = pending[gi] & ~pref_or[gi-1]; // 该位 set 且其下无 set → 最低号
      end
    end
  endgenerate

  // OHToUInt(winner): 把"最低号 pending 位"的下标编出来 (winner 为 0 时得 0)
  logic [ID_W-1:0] deq_id_next;
  always_comb begin
    deq_id_next = '0;
    for (int j = 1; j < NUM_ID; j++)
      if (winner[j]) deq_id_next = deq_id_next | ID_W'(j);
  end

  // 选中换桶的时机: 空闲, 或刚吐完一个 burst 的 last 拍 (此时可切到下一个 ID)
  wire reselect = ~locked | (in_r_fire & nodeIn_r_bits_last);
  wire locked_next = |pending;  // 下拍是否仍有可发送的整 burst

  // ---- 时序: locked / pending_count 异步复位; deq_id 无复位 ----
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      locked <= 1'b0;
      for (int i = 0; i < NUM_ID; i++)
        pending_count[i] <= '0;
    end else begin
      if (reselect)
        locked <= locked_next;
      for (int i = 0; i < NUM_ID; i++)
        pending_count[i] <= pending_next[i];
    end
  end

  always_ff @(posedge clock) begin
    if (reselect)
      deq_id <= deq_id_next;
  end

  // ---- 上游 in.r 输出 ----
  assign auto_in_r_valid     = locked;
  assign auto_in_r_bits_id   = sel_deq_id;
  assign auto_in_r_bits_data = sel_deq_data;
  assign auto_in_r_bits_last = nodeIn_r_bits_last;
  // ---- 下游 out.r 就绪 ----
  assign auto_out_r_ready    = nodeOut_r_ready;

  // ===========================================================================
  //  [3] 每 ID 一个深度 2 的 R 队列 (黑盒 Queue2_AXI4BundleR_3)
  //      入队: 该 ID 命中且下游 valid; 出队: 该 ID 被选中且上游 R 成交。
  // ===========================================================================
  generate
    for (gi = 0; gi < NUM_ID; gi++) begin : g_qs
      Queue2_AXI4BundleR_3 qs (
        .clock            (clock),
        .reset            (reset),
        .io_enq_ready     (q_enq_ready[gi]),
        .io_enq_valid     (enq_OH[gi] & auto_out_r_valid),
        .io_enq_bits_id   (auto_out_r_bits_id),
        .io_enq_bits_data (auto_out_r_bits_data),
        .io_enq_bits_resp (auto_out_r_bits_resp),
        .io_enq_bits_last (auto_out_r_bits_last),
        .io_deq_ready     (deq_OH[gi] & in_r_fire),
        .io_deq_bits_id   (q_deq_id[gi]),
        .io_deq_bits_data (q_deq_data[gi]),
        .io_deq_bits_last (q_deq_last[gi])
      );
    end
  endgenerate

endmodule

// 自动生成：xs-v2r2-sv/scripts/gen_axi4deint.py —— 该脚本未移植到本轮(它按上一轮规范产出独立 _wrapper.sv)，本文件手工维护

// ---------------------------------------------------------------------------
// golden 同名 wrapper
// ---------------------------------------------------------------------------

module AXI4Deinterleaver(
  input clock,
  input reset,
  output auto_in_aw_ready,
  input auto_in_aw_valid,
  input [6:0] auto_in_aw_bits_id,
  input [47:0] auto_in_aw_bits_addr,
  input [7:0] auto_in_aw_bits_len,
  input [2:0] auto_in_aw_bits_size,
  input [1:0] auto_in_aw_bits_burst,
  input [3:0] auto_in_aw_bits_cache,
  input [2:0] auto_in_aw_bits_prot,
  input [3:0] auto_in_aw_bits_qos,
  output auto_in_w_ready,
  input auto_in_w_valid,
  input [255:0] auto_in_w_bits_data,
  input [31:0] auto_in_w_bits_strb,
  input auto_in_w_bits_last,
  input auto_in_b_ready,
  output auto_in_b_valid,
  output [6:0] auto_in_b_bits_id,
  output auto_in_ar_ready,
  input auto_in_ar_valid,
  input [6:0] auto_in_ar_bits_id,
  input [47:0] auto_in_ar_bits_addr,
  input [7:0] auto_in_ar_bits_len,
  input [2:0] auto_in_ar_bits_size,
  input [1:0] auto_in_ar_bits_burst,
  input [3:0] auto_in_ar_bits_cache,
  input [2:0] auto_in_ar_bits_prot,
  input [3:0] auto_in_ar_bits_qos,
  input auto_in_r_ready,
  output auto_in_r_valid,
  output [6:0] auto_in_r_bits_id,
  output [255:0] auto_in_r_bits_data,
  output auto_in_r_bits_last,
  input auto_out_aw_ready,
  output auto_out_aw_valid,
  output [6:0] auto_out_aw_bits_id,
  output [47:0] auto_out_aw_bits_addr,
  output [7:0] auto_out_aw_bits_len,
  output [2:0] auto_out_aw_bits_size,
  output [1:0] auto_out_aw_bits_burst,
  output [3:0] auto_out_aw_bits_cache,
  output [2:0] auto_out_aw_bits_prot,
  output [3:0] auto_out_aw_bits_qos,
  input auto_out_w_ready,
  output auto_out_w_valid,
  output [255:0] auto_out_w_bits_data,
  output [31:0] auto_out_w_bits_strb,
  output auto_out_w_bits_last,
  output auto_out_b_ready,
  input auto_out_b_valid,
  input [6:0] auto_out_b_bits_id,
  input auto_out_ar_ready,
  output auto_out_ar_valid,
  output [6:0] auto_out_ar_bits_id,
  output [47:0] auto_out_ar_bits_addr,
  output [7:0] auto_out_ar_bits_len,
  output [2:0] auto_out_ar_bits_size,
  output [1:0] auto_out_ar_bits_burst,
  output [3:0] auto_out_ar_bits_cache,
  output [2:0] auto_out_ar_bits_prot,
  output [3:0] auto_out_ar_bits_qos,
  output auto_out_r_ready,
  input auto_out_r_valid,
  input [6:0] auto_out_r_bits_id,
  input [255:0] auto_out_r_bits_data,
  input [1:0] auto_out_r_bits_resp,
  input auto_out_r_bits_last
);
  xs_AXI4Deinterleaver_core u_core (
    .clock(clock),
    .reset(reset),
    .auto_in_aw_ready(auto_in_aw_ready),
    .auto_in_aw_valid(auto_in_aw_valid),
    .auto_in_aw_bits_id(auto_in_aw_bits_id),
    .auto_in_aw_bits_addr(auto_in_aw_bits_addr),
    .auto_in_aw_bits_len(auto_in_aw_bits_len),
    .auto_in_aw_bits_size(auto_in_aw_bits_size),
    .auto_in_aw_bits_burst(auto_in_aw_bits_burst),
    .auto_in_aw_bits_cache(auto_in_aw_bits_cache),
    .auto_in_aw_bits_prot(auto_in_aw_bits_prot),
    .auto_in_aw_bits_qos(auto_in_aw_bits_qos),
    .auto_in_w_ready(auto_in_w_ready),
    .auto_in_w_valid(auto_in_w_valid),
    .auto_in_w_bits_data(auto_in_w_bits_data),
    .auto_in_w_bits_strb(auto_in_w_bits_strb),
    .auto_in_w_bits_last(auto_in_w_bits_last),
    .auto_in_b_ready(auto_in_b_ready),
    .auto_in_b_valid(auto_in_b_valid),
    .auto_in_b_bits_id(auto_in_b_bits_id),
    .auto_in_ar_ready(auto_in_ar_ready),
    .auto_in_ar_valid(auto_in_ar_valid),
    .auto_in_ar_bits_id(auto_in_ar_bits_id),
    .auto_in_ar_bits_addr(auto_in_ar_bits_addr),
    .auto_in_ar_bits_len(auto_in_ar_bits_len),
    .auto_in_ar_bits_size(auto_in_ar_bits_size),
    .auto_in_ar_bits_burst(auto_in_ar_bits_burst),
    .auto_in_ar_bits_cache(auto_in_ar_bits_cache),
    .auto_in_ar_bits_prot(auto_in_ar_bits_prot),
    .auto_in_ar_bits_qos(auto_in_ar_bits_qos),
    .auto_in_r_ready(auto_in_r_ready),
    .auto_in_r_valid(auto_in_r_valid),
    .auto_in_r_bits_id(auto_in_r_bits_id),
    .auto_in_r_bits_data(auto_in_r_bits_data),
    .auto_in_r_bits_last(auto_in_r_bits_last),
    .auto_out_aw_ready(auto_out_aw_ready),
    .auto_out_aw_valid(auto_out_aw_valid),
    .auto_out_aw_bits_id(auto_out_aw_bits_id),
    .auto_out_aw_bits_addr(auto_out_aw_bits_addr),
    .auto_out_aw_bits_len(auto_out_aw_bits_len),
    .auto_out_aw_bits_size(auto_out_aw_bits_size),
    .auto_out_aw_bits_burst(auto_out_aw_bits_burst),
    .auto_out_aw_bits_cache(auto_out_aw_bits_cache),
    .auto_out_aw_bits_prot(auto_out_aw_bits_prot),
    .auto_out_aw_bits_qos(auto_out_aw_bits_qos),
    .auto_out_w_ready(auto_out_w_ready),
    .auto_out_w_valid(auto_out_w_valid),
    .auto_out_w_bits_data(auto_out_w_bits_data),
    .auto_out_w_bits_strb(auto_out_w_bits_strb),
    .auto_out_w_bits_last(auto_out_w_bits_last),
    .auto_out_b_ready(auto_out_b_ready),
    .auto_out_b_valid(auto_out_b_valid),
    .auto_out_b_bits_id(auto_out_b_bits_id),
    .auto_out_ar_ready(auto_out_ar_ready),
    .auto_out_ar_valid(auto_out_ar_valid),
    .auto_out_ar_bits_id(auto_out_ar_bits_id),
    .auto_out_ar_bits_addr(auto_out_ar_bits_addr),
    .auto_out_ar_bits_len(auto_out_ar_bits_len),
    .auto_out_ar_bits_size(auto_out_ar_bits_size),
    .auto_out_ar_bits_burst(auto_out_ar_bits_burst),
    .auto_out_ar_bits_cache(auto_out_ar_bits_cache),
    .auto_out_ar_bits_prot(auto_out_ar_bits_prot),
    .auto_out_ar_bits_qos(auto_out_ar_bits_qos),
    .auto_out_r_ready(auto_out_r_ready),
    .auto_out_r_valid(auto_out_r_valid),
    .auto_out_r_bits_id(auto_out_r_bits_id),
    .auto_out_r_bits_data(auto_out_r_bits_data),
    .auto_out_r_bits_resp(auto_out_r_bits_resp),
    .auto_out_r_bits_last(auto_out_r_bits_last)
  );
endmodule
