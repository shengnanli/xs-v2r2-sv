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
