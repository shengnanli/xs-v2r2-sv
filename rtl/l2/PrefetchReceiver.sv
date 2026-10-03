// =============================================================================
// PrefetchReceiver —— L2 预取"接收器"：把 L1 送来的预取地址直接转成 L2 预取请求
//
// 在哪一层：L2 Prefetcher 里的接收型预取源（coupledL2/prefetch/PrefetchReceiver.scala）。
//   L1 / 其他层发现值得预取的地址后经 recv_addr 推给 L2，本模块不做任何训练或过滤，
//   只把物理地址拆成 L2 的 tag / set 发出去（"L1&L2 不支持 Hint 时的临时方案"）。
// 机制：纯组合——
//   req.valid = io_enable & recv_addr.valid（Scala 里还与 Constantin 记录 pfRcv_enable 相与，
//               其初值 1、本配置下被常量折叠掉）；
//   地址拆分（parseFullAddress，64B 行、512 组/slice 的 L2）：
//     offset = addr[5:0]（丢弃），set = addr[14:6]（9 位），tag = addr[47:15]（33 位）；
//   pfSource 原样带过去。needT/source/vaddr、train/resp/tlb 等口在 golden 端口表里已被裁掉。
// 边界：无时钟、无复位、无子模块。addr 的 [63:48] 不参与（物理地址 48 位）。
// 结构：golden 端口 -> xs_PrefetchReceiver_core（可读核）。
// golden 对照：G1-canonical/golden-rtl/PrefetchReceiver.sv
// =============================================================================
module xs_PrefetchReceiver_core (
  input  logic        enable,
  // L1 推来的预取地址
  input  logic        recv_valid,
  input  logic [63:0] recv_addr,
  input  logic [4:0]  recv_pf_source,
  // 发给 L2 预取队列的请求
  output logic        req_valid,
  output logic [32:0] req_tag,
  output logic [8:0]  req_set,
  output logic [4:0]  req_pf_source
);
  localparam int OFFSET_W = 6;   // 64B cache line
  localparam int SET_W    = 9;   // 512 sets per slice
  localparam int PADDR_W  = 48;  // 物理地址宽度
  localparam int TAG_LSB  = OFFSET_W + SET_W;

  assign req_valid     = enable & recv_valid;
  assign req_set       = recv_addr[TAG_LSB-1:OFFSET_W];
  assign req_tag       = recv_addr[PADDR_W-1:TAG_LSB];
  assign req_pf_source = recv_pf_source;
endmodule

module PrefetchReceiver (
  output logic        io_req_valid,
  output logic [32:0] io_req_bits_tag,
  output logic [8:0]  io_req_bits_set,
  output logic [4:0]  io_req_bits_pfSource,
  input  logic        io_recv_addr_valid,
  input  logic [63:0] io_recv_addr_bits_addr,
  input  logic [4:0]  io_recv_addr_bits_pfSource,
  input  logic        io_enable
);
  xs_PrefetchReceiver_core u_core (
    .enable         (io_enable),
    .recv_valid     (io_recv_addr_valid),
    .recv_addr      (io_recv_addr_bits_addr),
    .recv_pf_source (io_recv_addr_bits_pfSource),
    .req_valid      (io_req_valid),
    .req_tag        (io_req_bits_tag),
    .req_set        (io_req_bits_set),
    .req_pf_source  (io_req_bits_pfSource)
  );
endmodule
