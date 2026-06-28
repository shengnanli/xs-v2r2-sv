// =============================================================================
//  AXI4Xbar_1 —— 香山 V2R2 AXI4 交叉开关 (可读重写核 xs_AXI4Xbar_1_core)
// -----------------------------------------------------------------------------
//  源自 rocket-chip AXI4Xbar (src/main/scala/amba/axi4/Xbar.scala): 1 主口 (auto_in)
//  × 5 从口 (UART/Flash/SD/IntrGen/Error)。从设计意图重写 (非照抄 firtool 优化后的
//  逐位地址掩码与展平命名)。本核覆盖三块"AXI 通道协议"核心机制:
//
//  [A] 五通道地址路由 + AW/W 同步: AW(写地址)与 W(写数据)是分离通道, W 必须跟随对应
//      AW 命中的从口。用深度 2 的路由队列 awIn (黑盒 Queue2_UInt5) 在 AW 入队时记录其
//      从口 one-hot, W 数据按队首出队的路由分发; latched 寄存器吸收"AW 已入队但尚未被
//      下游从口接收"的错拍, 保证 aw_ready 与队列 enq 协调。
//
//  [B] 按 ID 顺序保持 (per-ID FIFO map, Xbar.scala 的 requestFIFO): 每个 AXI ID 维护
//      count(在飞数) 与 last(锁定从口 tag)。AR/AW 仲裁: 同一 ID 的新请求仅当 count==0
//      (可任选从口) 或目标从口与在飞相同 (last==tag), 且 count 未满 (flight=7=count 上限)
//      时放行; 否则握手 ready 拉低暂停。这防止同一 ID 的多笔请求落到不同从口、其响应
//      乱序返回破坏 AXI 同 ID 顺序保证。
//
//  [C] R / B 响应 5 路 round-robin 仲裁 (Arbiter.scala): 复用前缀 OR 算法 (rr_grant);
//      idle 寄存器在下游 stall (主口未就绪) 时锁定当拍胜者 (state) 维持选择稳定, 握手
//      完成后回到 idle 重新仲裁。错误从口 out_4 (AXI4Error) 无 data/resp/last 端口,
//      其 R/B 响应固定 {resp=DECERR(2'b11), last=1, data=0}, 仅回显请求 id。
//
//  地址译码 (SimMMIO): UART 0x40600000/16B, Flash 0x10000000/256MB(从口截 29 位地址),
//  SD 0x40002000/4KB, IntrGen 0x40070000/64KB, Error = 前四者补集 (catch-all)。
//
//  验证: golden 同名 AXI4Xbar_1 例化本核 + 黑盒 Queue2_UInt5/ram_2x5; UT 双例化逐拍比对
//  全部输出 (随机 AW/AR/W/B/R 握手 + 地址偏向各从口区 + 多 ID 并发); FM 证组合/时序等价
//  (含错误从口"补集 == golden 40+ 项 masked-AddressSet OR"的逐位证明)。
// =============================================================================
module xs_AXI4Xbar_1_core
  import axi4xbar1_pkg::*;
(
  input         clock,
  input         reset,
  output        auto_in_aw_ready,
  input         auto_in_aw_valid,
  input  [1:0]  auto_in_aw_bits_id,
  input  [30:0] auto_in_aw_bits_addr,
  input  [7:0]  auto_in_aw_bits_len,
  input  [2:0]  auto_in_aw_bits_size,
  input  [1:0]  auto_in_aw_bits_burst,
  input         auto_in_aw_bits_lock,
  input  [3:0]  auto_in_aw_bits_cache,
  input  [2:0]  auto_in_aw_bits_prot,
  input  [3:0]  auto_in_aw_bits_qos,
  output        auto_in_w_ready,
  input         auto_in_w_valid,
  input  [63:0] auto_in_w_bits_data,
  input  [7:0]  auto_in_w_bits_strb,
  input         auto_in_w_bits_last,
  input         auto_in_b_ready,
  output        auto_in_b_valid,
  output [1:0]  auto_in_b_bits_id,
  output [1:0]  auto_in_b_bits_resp,
  output        auto_in_ar_ready,
  input         auto_in_ar_valid,
  input  [1:0]  auto_in_ar_bits_id,
  input  [30:0] auto_in_ar_bits_addr,
  input  [7:0]  auto_in_ar_bits_len,
  input  [2:0]  auto_in_ar_bits_size,
  input  [1:0]  auto_in_ar_bits_burst,
  input         auto_in_ar_bits_lock,
  input  [3:0]  auto_in_ar_bits_cache,
  input  [2:0]  auto_in_ar_bits_prot,
  input  [3:0]  auto_in_ar_bits_qos,
  input         auto_in_r_ready,
  output        auto_in_r_valid,
  output [1:0]  auto_in_r_bits_id,
  output [63:0] auto_in_r_bits_data,
  output [1:0]  auto_in_r_bits_resp,
  output        auto_in_r_bits_last,
  input         auto_out_4_aw_ready,
  output        auto_out_4_aw_valid,
  output [1:0]  auto_out_4_aw_bits_id,
  output [30:0] auto_out_4_aw_bits_addr,
  output [7:0]  auto_out_4_aw_bits_len,
  output [2:0]  auto_out_4_aw_bits_size,
  output [1:0]  auto_out_4_aw_bits_burst,
  output        auto_out_4_aw_bits_lock,
  output [3:0]  auto_out_4_aw_bits_cache,
  output [2:0]  auto_out_4_aw_bits_prot,
  output [3:0]  auto_out_4_aw_bits_qos,
  input         auto_out_4_w_ready,
  output        auto_out_4_w_valid,
  output [63:0] auto_out_4_w_bits_data,
  output [7:0]  auto_out_4_w_bits_strb,
  output        auto_out_4_w_bits_last,
  output        auto_out_4_b_ready,
  input         auto_out_4_b_valid,
  input  [1:0]  auto_out_4_b_bits_id,
  input         auto_out_4_ar_ready,
  output        auto_out_4_ar_valid,
  output [1:0]  auto_out_4_ar_bits_id,
  output [30:0] auto_out_4_ar_bits_addr,
  output [7:0]  auto_out_4_ar_bits_len,
  output [2:0]  auto_out_4_ar_bits_size,
  output [1:0]  auto_out_4_ar_bits_burst,
  output        auto_out_4_ar_bits_lock,
  output [3:0]  auto_out_4_ar_bits_cache,
  output [2:0]  auto_out_4_ar_bits_prot,
  output [3:0]  auto_out_4_ar_bits_qos,
  output        auto_out_4_r_ready,
  input         auto_out_4_r_valid,
  input  [1:0]  auto_out_4_r_bits_id,
  input         auto_out_3_aw_ready,
  output        auto_out_3_aw_valid,
  output [1:0]  auto_out_3_aw_bits_id,
  output [30:0] auto_out_3_aw_bits_addr,
  output [7:0]  auto_out_3_aw_bits_len,
  output [2:0]  auto_out_3_aw_bits_size,
  output [1:0]  auto_out_3_aw_bits_burst,
  output        auto_out_3_aw_bits_lock,
  output [3:0]  auto_out_3_aw_bits_cache,
  output [2:0]  auto_out_3_aw_bits_prot,
  output [3:0]  auto_out_3_aw_bits_qos,
  input         auto_out_3_w_ready,
  output        auto_out_3_w_valid,
  output [63:0] auto_out_3_w_bits_data,
  output [7:0]  auto_out_3_w_bits_strb,
  output        auto_out_3_w_bits_last,
  output        auto_out_3_b_ready,
  input         auto_out_3_b_valid,
  input  [1:0]  auto_out_3_b_bits_id,
  input  [1:0]  auto_out_3_b_bits_resp,
  input         auto_out_3_ar_ready,
  output        auto_out_3_ar_valid,
  output [1:0]  auto_out_3_ar_bits_id,
  output [30:0] auto_out_3_ar_bits_addr,
  output [7:0]  auto_out_3_ar_bits_len,
  output [2:0]  auto_out_3_ar_bits_size,
  output [1:0]  auto_out_3_ar_bits_burst,
  output        auto_out_3_ar_bits_lock,
  output [3:0]  auto_out_3_ar_bits_cache,
  output [2:0]  auto_out_3_ar_bits_prot,
  output [3:0]  auto_out_3_ar_bits_qos,
  output        auto_out_3_r_ready,
  input         auto_out_3_r_valid,
  input  [1:0]  auto_out_3_r_bits_id,
  input  [63:0] auto_out_3_r_bits_data,
  input  [1:0]  auto_out_3_r_bits_resp,
  input         auto_out_3_r_bits_last,
  input         auto_out_2_aw_ready,
  output        auto_out_2_aw_valid,
  output [1:0]  auto_out_2_aw_bits_id,
  output [30:0] auto_out_2_aw_bits_addr,
  output [7:0]  auto_out_2_aw_bits_len,
  output [2:0]  auto_out_2_aw_bits_size,
  output [1:0]  auto_out_2_aw_bits_burst,
  output        auto_out_2_aw_bits_lock,
  output [3:0]  auto_out_2_aw_bits_cache,
  output [2:0]  auto_out_2_aw_bits_prot,
  output [3:0]  auto_out_2_aw_bits_qos,
  input         auto_out_2_w_ready,
  output        auto_out_2_w_valid,
  output [63:0] auto_out_2_w_bits_data,
  output [7:0]  auto_out_2_w_bits_strb,
  output        auto_out_2_w_bits_last,
  output        auto_out_2_b_ready,
  input         auto_out_2_b_valid,
  input  [1:0]  auto_out_2_b_bits_id,
  input  [1:0]  auto_out_2_b_bits_resp,
  input         auto_out_2_ar_ready,
  output        auto_out_2_ar_valid,
  output [1:0]  auto_out_2_ar_bits_id,
  output [30:0] auto_out_2_ar_bits_addr,
  output [7:0]  auto_out_2_ar_bits_len,
  output [2:0]  auto_out_2_ar_bits_size,
  output [1:0]  auto_out_2_ar_bits_burst,
  output        auto_out_2_ar_bits_lock,
  output [3:0]  auto_out_2_ar_bits_cache,
  output [2:0]  auto_out_2_ar_bits_prot,
  output [3:0]  auto_out_2_ar_bits_qos,
  output        auto_out_2_r_ready,
  input         auto_out_2_r_valid,
  input  [1:0]  auto_out_2_r_bits_id,
  input  [63:0] auto_out_2_r_bits_data,
  input  [1:0]  auto_out_2_r_bits_resp,
  input         auto_out_2_r_bits_last,
  input         auto_out_1_aw_ready,
  output        auto_out_1_aw_valid,
  output [1:0]  auto_out_1_aw_bits_id,
  output [28:0] auto_out_1_aw_bits_addr,
  output [7:0]  auto_out_1_aw_bits_len,
  output [2:0]  auto_out_1_aw_bits_size,
  output [1:0]  auto_out_1_aw_bits_burst,
  output        auto_out_1_aw_bits_lock,
  output [3:0]  auto_out_1_aw_bits_cache,
  output [2:0]  auto_out_1_aw_bits_prot,
  output [3:0]  auto_out_1_aw_bits_qos,
  input         auto_out_1_w_ready,
  output        auto_out_1_w_valid,
  output [63:0] auto_out_1_w_bits_data,
  output [7:0]  auto_out_1_w_bits_strb,
  output        auto_out_1_w_bits_last,
  output        auto_out_1_b_ready,
  input         auto_out_1_b_valid,
  input  [1:0]  auto_out_1_b_bits_id,
  input  [1:0]  auto_out_1_b_bits_resp,
  input         auto_out_1_ar_ready,
  output        auto_out_1_ar_valid,
  output [1:0]  auto_out_1_ar_bits_id,
  output [28:0] auto_out_1_ar_bits_addr,
  output [7:0]  auto_out_1_ar_bits_len,
  output [2:0]  auto_out_1_ar_bits_size,
  output [1:0]  auto_out_1_ar_bits_burst,
  output        auto_out_1_ar_bits_lock,
  output [3:0]  auto_out_1_ar_bits_cache,
  output [2:0]  auto_out_1_ar_bits_prot,
  output [3:0]  auto_out_1_ar_bits_qos,
  output        auto_out_1_r_ready,
  input         auto_out_1_r_valid,
  input  [1:0]  auto_out_1_r_bits_id,
  input  [63:0] auto_out_1_r_bits_data,
  input  [1:0]  auto_out_1_r_bits_resp,
  input         auto_out_1_r_bits_last,
  input         auto_out_0_aw_ready,
  output        auto_out_0_aw_valid,
  output [1:0]  auto_out_0_aw_bits_id,
  output [30:0] auto_out_0_aw_bits_addr,
  output [7:0]  auto_out_0_aw_bits_len,
  output [2:0]  auto_out_0_aw_bits_size,
  output [1:0]  auto_out_0_aw_bits_burst,
  output        auto_out_0_aw_bits_lock,
  output [3:0]  auto_out_0_aw_bits_cache,
  output [2:0]  auto_out_0_aw_bits_prot,
  output [3:0]  auto_out_0_aw_bits_qos,
  input         auto_out_0_w_ready,
  output        auto_out_0_w_valid,
  output [63:0] auto_out_0_w_bits_data,
  output [7:0]  auto_out_0_w_bits_strb,
  output        auto_out_0_w_bits_last,
  output        auto_out_0_b_ready,
  input         auto_out_0_b_valid,
  input  [1:0]  auto_out_0_b_bits_id,
  input  [1:0]  auto_out_0_b_bits_resp,
  input         auto_out_0_ar_ready,
  output        auto_out_0_ar_valid,
  output [1:0]  auto_out_0_ar_bits_id,
  output [30:0] auto_out_0_ar_bits_addr,
  output [7:0]  auto_out_0_ar_bits_len,
  output [2:0]  auto_out_0_ar_bits_size,
  output [1:0]  auto_out_0_ar_bits_burst,
  output        auto_out_0_ar_bits_lock,
  output [3:0]  auto_out_0_ar_bits_cache,
  output [2:0]  auto_out_0_ar_bits_prot,
  output [3:0]  auto_out_0_ar_bits_qos,
  output        auto_out_0_r_ready,
  input         auto_out_0_r_valid,
  input  [1:0]  auto_out_0_r_bits_id,
  input  [63:0] auto_out_0_r_bits_data,
  input  [1:0]  auto_out_0_r_bits_resp,
  input         auto_out_0_r_bits_last
);

  // ===========================================================================
  //  通用 round-robin 前缀 OR 工具 (N = NUM_OUT = 5; R/B 两个仲裁器共用)
  //    mask  : 优先级掩码 (RegInit 全 1), 已服务者下一轮降到最低优先级。
  //    filter= {valid & ~mask, valid}            (2N 位)
  //    unready=(rightOR(filter,2N,cap=N)>>1)|(mask<<N)
  //    grant[i]=~(unready[i+N] & unready[i])      (N 位 one-hot 授权)
  // ===========================================================================
  function automatic logic [MAXN-1:0] left_or(input logic [MAXN-1:0] x);
    left_or = x;
    for (int s = 1; s < MAXN; s = s << 1) left_or = left_or | (left_or << s);
  endfunction

  function automatic logic [2*MAXN-1:0] right_or_capped(input logic [2*MAXN-1:0] x);
    right_or_capped = x;
    for (int s = 1; s < MAXN; s = s << 1)
      right_or_capped = right_or_capped | (right_or_capped >> s);
  endfunction

  function automatic logic [MAXN-1:0] rr_grant(input logic [MAXN-1:0] valid,
                                               input logic [MAXN-1:0] mask);
    logic [2*MAXN-1:0] filter, unready;
    filter  = {{MAXN{1'b0}}, valid} | ({{MAXN{1'b0}}, (valid & ~mask)} << MAXN);
    unready = (right_or_capped(filter) >> 1) | ({{MAXN{1'b0}}, mask} << MAXN);
    rr_grant = '0;
    for (int i = 0; i < MAXN; i++)
      rr_grant[i] = ~(unready[i + MAXN] & unready[i]);
  endfunction

  // ===========================================================================
  //  地址译码 (AR / AW) ⇒ 命中从口 one-hot
  //  注意: 错误从口"不是"四设备的全补集 (那样会把未映射的 SoC 区也当错误处理), 而是
  //  AXI4Error 节点实际的 AddressSet 列表 (pkg ERR_CARE/ERR_WANT)。未映射的空洞地址使
  //  全部 req 为 0, 主口 ready 拉低停等 —— 与 golden 一致。
  // ===========================================================================
  function automatic logic dec_uart (input logic [30:0] a); return a[30:4]   == UART_HI; endfunction
  function automatic logic dec_flash(input logic [30:0] a); return (a[30:29] == 2'b0) & a[28]; endfunction
  function automatic logic dec_sd   (input logic [30:0] a); return a[30:12]  == SD_HI;   endfunction
  function automatic logic dec_intr (input logic [30:0] a); return a[30:16]  == INTR_HI; endfunction
  function automatic logic dec_error(input logic [30:0] a);
    dec_error = 1'b0;
    for (int k = 0; k < ERR_N; k++)
      if ((a & ERR_CARE[k]) == ERR_WANT[k]) dec_error = 1'b1;
  endfunction

  // one-hot 从口集合 ⇒ 3 位从口编号 (tag); 供 per-ID FIFO map 的 last 锁定/比较。
  function automatic logic [2:0] slave_tag(input logic [NUM_OUT-1:0] req);
    slave_tag = '0;
    for (int o = 0; o < NUM_OUT; o++) if (req[o]) slave_tag = o[2:0];
  endfunction

  logic [NUM_OUT-1:0] reqAR, reqAW;
  always_comb begin
    reqAR[OUT_UART]    = dec_uart (auto_in_ar_bits_addr);
    reqAR[OUT_FLASH]   = dec_flash(auto_in_ar_bits_addr);
    reqAR[OUT_SD]      = dec_sd   (auto_in_ar_bits_addr);
    reqAR[OUT_INTRGEN] = dec_intr (auto_in_ar_bits_addr);
    reqAR[OUT_ERROR]   = dec_error(auto_in_ar_bits_addr);
    reqAW[OUT_UART]    = dec_uart (auto_in_aw_bits_addr);
    reqAW[OUT_FLASH]   = dec_flash(auto_in_aw_bits_addr);
    reqAW[OUT_SD]      = dec_sd   (auto_in_aw_bits_addr);
    reqAW[OUT_INTRGEN] = dec_intr (auto_in_aw_bits_addr);
    reqAW[OUT_ERROR]   = dec_error(auto_in_aw_bits_addr);
  end
  wire [2:0] arTag = slave_tag(reqAR);
  wire [2:0] awTag = slave_tag(reqAW);

  // ===========================================================================
  //  从口侧端口聚合: 握手 ready / 响应 valid 打包成按从口编号索引的向量
  // ===========================================================================
  wire [NUM_OUT-1:0] out_aw_ready_v = {auto_out_4_aw_ready, auto_out_3_aw_ready, auto_out_2_aw_ready, auto_out_1_aw_ready, auto_out_0_aw_ready};
  wire [NUM_OUT-1:0] out_w_ready_v  = {auto_out_4_w_ready,  auto_out_3_w_ready,  auto_out_2_w_ready,  auto_out_1_w_ready,  auto_out_0_w_ready};
  wire [NUM_OUT-1:0] out_ar_ready_v = {auto_out_4_ar_ready, auto_out_3_ar_ready, auto_out_2_ar_ready, auto_out_1_ar_ready, auto_out_0_ar_ready};
  wire [NUM_OUT-1:0] out_b_valid_v  = {auto_out_4_b_valid,  auto_out_3_b_valid,  auto_out_2_b_valid,  auto_out_1_b_valid,  auto_out_0_b_valid};
  wire [NUM_OUT-1:0] out_r_valid_v  = {auto_out_4_r_valid,  auto_out_3_r_valid,  auto_out_2_r_valid,  auto_out_1_r_valid,  auto_out_0_r_valid};

  // 从口 R / B 响应载荷 (错误从口 out_4 只有 id 端口, data/resp/last 占位 0)。
  axi_r_t out_r [NUM_OUT];
  axi_b_t out_b [NUM_OUT];
  assign out_r[OUT_UART]    = '{id: auto_out_0_r_bits_id, data: auto_out_0_r_bits_data, resp: auto_out_0_r_bits_resp, last: auto_out_0_r_bits_last};
  assign out_r[OUT_FLASH]   = '{id: auto_out_1_r_bits_id, data: auto_out_1_r_bits_data, resp: auto_out_1_r_bits_resp, last: auto_out_1_r_bits_last};
  assign out_r[OUT_SD]      = '{id: auto_out_2_r_bits_id, data: auto_out_2_r_bits_data, resp: auto_out_2_r_bits_resp, last: auto_out_2_r_bits_last};
  assign out_r[OUT_INTRGEN] = '{id: auto_out_3_r_bits_id, data: auto_out_3_r_bits_data, resp: auto_out_3_r_bits_resp, last: auto_out_3_r_bits_last};
  assign out_r[OUT_ERROR]   = '{id: auto_out_4_r_bits_id, data: 64'h0, resp: 2'h0, last: 1'b0};
  assign out_b[OUT_UART]    = '{id: auto_out_0_b_bits_id, resp: auto_out_0_b_bits_resp};
  assign out_b[OUT_FLASH]   = '{id: auto_out_1_b_bits_id, resp: auto_out_1_b_bits_resp};
  assign out_b[OUT_SD]      = '{id: auto_out_2_b_bits_id, resp: auto_out_2_b_bits_resp};
  assign out_b[OUT_INTRGEN] = '{id: auto_out_3_b_bits_id, resp: auto_out_3_b_bits_resp};
  assign out_b[OUT_ERROR]   = '{id: auto_out_4_b_bits_id, resp: 2'h0};

  // ===========================================================================
  //  per-ID FIFO map: count(在飞) / last(锁定从口 tag); 防同 ID 响应乱序
  // ===========================================================================
  reg [2:0] ar_count [NUM_ID];
  reg [2:0] ar_last  [NUM_ID];
  reg [2:0] aw_count [NUM_ID];
  reg [2:0] aw_last  [NUM_ID];

  // 放行门: count==0 (可任选从口) 或目标从口与在飞相同 (last==tag), 且 count 未满。
  logic [NUM_ID-1:0] ar_gate_v, aw_gate_v;
  always_comb begin
    for (int i = 0; i < NUM_ID; i++) begin
      ar_gate_v[i] = (ar_count[i] == 3'h0 | ar_last[i] == arTag) & (ar_count[i] != 3'(FLIGHT));
      aw_gate_v[i] = (aw_count[i] == 3'h0 | aw_last[i] == awTag) & (aw_count[i] != 3'(FLIGHT));
    end
  end

  // ===========================================================================
  //  AR 通道: 译码门控 + ID 顺序门 ⇒ 下发选中从口
  // ===========================================================================
  wire portsAROI_ar_ready = |(reqAR & out_ar_ready_v);
  wire nodeIn_ar_ready    = portsAROI_ar_ready & ar_gate_v[auto_in_ar_bits_id];
  wire in_0_ar_valid      = auto_in_ar_valid   & ar_gate_v[auto_in_ar_bits_id];
  assign auto_in_ar_ready = nodeIn_ar_ready;

  // ===========================================================================
  //  AW / W 通道: AW 入路由队列 + ID 顺序门; W 跟随队首路由分发
  // ===========================================================================
  reg                latched;          // AW 已入队但尚未被下游从口接收
  wire               awIn_enq_ready, awIn_deq_valid;
  wire [NUM_OUT-1:0] awIn_deq_bits;    // 队首 AW 的从口 one-hot 路由 (W 用)

  wire portsAWOI_aw_ready = |(reqAW & out_aw_ready_v);
  wire nodeIn_aw_ready_T  = latched | awIn_enq_ready;          // 必须已 (或可) 入队才放 AW
  wire in_0_aw_valid      = auto_in_aw_valid & nodeIn_aw_ready_T & aw_gate_v[auto_in_aw_bits_id];
  wire nodeIn_aw_ready    = portsAWOI_aw_ready & nodeIn_aw_ready_T & aw_gate_v[auto_in_aw_bits_id];
  assign auto_in_aw_ready = nodeIn_aw_ready;
  wire awIn_enq_valid     = auto_in_aw_valid & ~latched;       // 每个 AW 入队一次

  wire portsWOI_w_ready   = |(awIn_deq_bits & out_w_ready_v);  // 队首路由对应从口的 w_ready
  wire in_0_w_valid       = auto_in_w_valid & awIn_deq_valid;
  wire awIn_deq_ready     = auto_in_w_valid & auto_in_w_bits_last & portsWOI_w_ready; // 末拍出队
  assign auto_in_w_ready  = portsWOI_w_ready & awIn_deq_valid;

  // latched 下一拍: 若本拍 AW 已被下游从口接收则清, 否则在入队完成后置位维持。
  wire latched_next = ~(portsAWOI_aw_ready & in_0_aw_valid)
                    & ((awIn_enq_ready & awIn_enq_valid) | latched);

  // 路由队列 (黑盒 Queue2_UInt5, 深度 2; enq_bits = AW 命中从口 one-hot = reqAW)。
  Queue2_UInt5 awIn_0 (
    .clock        (clock),
    .reset        (reset),
    .io_enq_ready (awIn_enq_ready),
    .io_enq_valid (awIn_enq_valid),
    .io_enq_bits  (reqAW),
    .io_deq_ready (awIn_deq_ready),
    .io_deq_valid (awIn_deq_valid),
    .io_deq_bits  (awIn_deq_bits)
  );

  // ===========================================================================
  //  R 通道仲裁 (5 路 round-robin, idle 锁定; 错误从口固定 DECERR/last/data=0)
  // ===========================================================================
  reg               idle_5;
  reg [NUM_OUT-1:0] mask_r;
  reg [NUM_OUT-1:0] state_5;
  wire               anyValid_r = |out_r_valid_v;
  wire [NUM_OUT-1:0] readys_r   = rr_grant(out_r_valid_v, mask_r);
  wire [NUM_OUT-1:0] winner_r   = readys_r & out_r_valid_v;
  wire [NUM_OUT-1:0] muxState_r = idle_5 ? winner_r : state_5;
  wire               in_0_r_valid = idle_5 ? anyValid_r : (|(state_5 & out_r_valid_v));

  logic [1:0]  r_id_sel;
  logic [63:0] r_data_sel;
  logic [1:0]  r_resp_sel;
  logic        r_last_sel;
  always_comb begin
    r_id_sel = '0; r_data_sel = '0; r_resp_sel = '0; r_last_sel = 1'b0;
    for (int o = 0; o < NUM_OUT; o++) if (muxState_r[o]) r_id_sel |= out_r[o].id; // 含错误从口 (回显 id)
    for (int o = 0; o < NUM_OUT-1; o++) if (muxState_r[o]) begin
      r_data_sel |= out_r[o].data;
      r_resp_sel |= out_r[o].resp;
      r_last_sel |= out_r[o].last;
    end
    if (muxState_r[OUT_ERROR]) begin r_resp_sel = r_resp_sel | RESP_DECERR; r_last_sel = r_last_sel | 1'b1; end
  end
  assign auto_in_r_valid     = in_0_r_valid;
  assign auto_in_r_bits_id   = r_id_sel;
  assign auto_in_r_bits_data = r_data_sel;
  assign auto_in_r_bits_resp = r_resp_sel;
  assign auto_in_r_bits_last = r_last_sel;
  wire r_hs = auto_in_r_ready & in_0_r_valid;

  // ===========================================================================
  //  B 通道仲裁 (5 路 round-robin, idle 锁定; 错误从口固定 DECERR)
  // ===========================================================================
  reg               idle_6;
  reg [NUM_OUT-1:0] mask_b;
  reg [NUM_OUT-1:0] state_6;
  wire               anyValid_b = |out_b_valid_v;
  wire [NUM_OUT-1:0] readys_b   = rr_grant(out_b_valid_v, mask_b);
  wire [NUM_OUT-1:0] winner_b   = readys_b & out_b_valid_v;
  wire [NUM_OUT-1:0] muxState_b = idle_6 ? winner_b : state_6;
  wire               in_0_b_valid = idle_6 ? anyValid_b : (|(state_6 & out_b_valid_v));

  logic [1:0] b_id_sel, b_resp_sel;
  always_comb begin
    b_id_sel = '0; b_resp_sel = '0;
    for (int o = 0; o < NUM_OUT; o++) if (muxState_b[o]) b_id_sel |= out_b[o].id; // 含错误从口 (回显 id)
    for (int o = 0; o < NUM_OUT-1; o++) if (muxState_b[o]) b_resp_sel |= out_b[o].resp;
    if (muxState_b[OUT_ERROR]) b_resp_sel = b_resp_sel | RESP_DECERR;
  end
  assign auto_in_b_valid     = in_0_b_valid;
  assign auto_in_b_bits_id   = b_id_sel;
  assign auto_in_b_bits_resp = b_resp_sel;
  wire b_hs = auto_in_b_ready & in_0_b_valid;

  // ===========================================================================
  //  per-ID 请求/响应 fire (驱动 FIFO map 计数与锁定)
  // ===========================================================================
  wire ar_hs = nodeIn_ar_ready & auto_in_ar_valid;
  wire aw_hs = nodeIn_aw_ready & auto_in_aw_valid;
  logic [NUM_ID-1:0] ar_req_fire, ar_resp_fire, aw_req_fire, aw_resp_fire;
  always_comb begin
    for (int i = 0; i < NUM_ID; i++) begin
      ar_req_fire[i]  = (auto_in_ar_bits_id == i[1:0]) & ar_hs;
      ar_resp_fire[i] = (r_id_sel == i[1:0]) & r_hs & r_last_sel;       // 读末拍出飞
      aw_req_fire[i]  = (auto_in_aw_bits_id == i[1:0]) & aw_hs;
      aw_resp_fire[i] = (b_id_sel == i[1:0]) & b_hs;                    // 写 B 出飞
    end
  end

  // ===========================================================================
  //  AR / AW / W 下发到从口 (载荷广播, valid 按译码/路由门控; Flash 地址截 29 位)
  // ===========================================================================
  axi_ax_t ar_in, aw_in;
  assign ar_in = '{id: auto_in_ar_bits_id, addr: auto_in_ar_bits_addr, len: auto_in_ar_bits_len,
                   size: auto_in_ar_bits_size, burst: auto_in_ar_bits_burst, lock: auto_in_ar_bits_lock,
                   cache: auto_in_ar_bits_cache, prot: auto_in_ar_bits_prot, qos: auto_in_ar_bits_qos};
  assign aw_in = '{id: auto_in_aw_bits_id, addr: auto_in_aw_bits_addr, len: auto_in_aw_bits_len,
                   size: auto_in_aw_bits_size, burst: auto_in_aw_bits_burst, lock: auto_in_aw_bits_lock,
                   cache: auto_in_aw_bits_cache, prot: auto_in_aw_bits_prot, qos: auto_in_aw_bits_qos};

  // ---- AR ----
  assign auto_out_0_ar_valid = in_0_ar_valid & reqAR[OUT_UART];
  assign auto_out_1_ar_valid = in_0_ar_valid & reqAR[OUT_FLASH];
  assign auto_out_2_ar_valid = in_0_ar_valid & reqAR[OUT_SD];
  assign auto_out_3_ar_valid = in_0_ar_valid & reqAR[OUT_INTRGEN];
  assign auto_out_4_ar_valid = in_0_ar_valid & reqAR[OUT_ERROR];
  assign {auto_out_0_ar_bits_id, auto_out_0_ar_bits_len, auto_out_0_ar_bits_size, auto_out_0_ar_bits_burst, auto_out_0_ar_bits_lock, auto_out_0_ar_bits_cache, auto_out_0_ar_bits_prot, auto_out_0_ar_bits_qos} = {ar_in.id, ar_in.len, ar_in.size, ar_in.burst, ar_in.lock, ar_in.cache, ar_in.prot, ar_in.qos};
  assign {auto_out_2_ar_bits_id, auto_out_2_ar_bits_len, auto_out_2_ar_bits_size, auto_out_2_ar_bits_burst, auto_out_2_ar_bits_lock, auto_out_2_ar_bits_cache, auto_out_2_ar_bits_prot, auto_out_2_ar_bits_qos} = {ar_in.id, ar_in.len, ar_in.size, ar_in.burst, ar_in.lock, ar_in.cache, ar_in.prot, ar_in.qos};
  assign {auto_out_3_ar_bits_id, auto_out_3_ar_bits_len, auto_out_3_ar_bits_size, auto_out_3_ar_bits_burst, auto_out_3_ar_bits_lock, auto_out_3_ar_bits_cache, auto_out_3_ar_bits_prot, auto_out_3_ar_bits_qos} = {ar_in.id, ar_in.len, ar_in.size, ar_in.burst, ar_in.lock, ar_in.cache, ar_in.prot, ar_in.qos};
  assign {auto_out_4_ar_bits_id, auto_out_4_ar_bits_len, auto_out_4_ar_bits_size, auto_out_4_ar_bits_burst, auto_out_4_ar_bits_lock, auto_out_4_ar_bits_cache, auto_out_4_ar_bits_prot, auto_out_4_ar_bits_qos} = {ar_in.id, ar_in.len, ar_in.size, ar_in.burst, ar_in.lock, ar_in.cache, ar_in.prot, ar_in.qos};
  assign {auto_out_1_ar_bits_id, auto_out_1_ar_bits_len, auto_out_1_ar_bits_size, auto_out_1_ar_bits_burst, auto_out_1_ar_bits_lock, auto_out_1_ar_bits_cache, auto_out_1_ar_bits_prot, auto_out_1_ar_bits_qos} = {ar_in.id, ar_in.len, ar_in.size, ar_in.burst, ar_in.lock, ar_in.cache, ar_in.prot, ar_in.qos};
  assign auto_out_0_ar_bits_addr = ar_in.addr;
  assign auto_out_2_ar_bits_addr = ar_in.addr;
  assign auto_out_3_ar_bits_addr = ar_in.addr;
  assign auto_out_4_ar_bits_addr = ar_in.addr;
  assign auto_out_1_ar_bits_addr = ar_in.addr[28:0];   // Flash 从口地址截 29 位

  // ---- AW ----
  assign auto_out_0_aw_valid = in_0_aw_valid & reqAW[OUT_UART];
  assign auto_out_1_aw_valid = in_0_aw_valid & reqAW[OUT_FLASH];
  assign auto_out_2_aw_valid = in_0_aw_valid & reqAW[OUT_SD];
  assign auto_out_3_aw_valid = in_0_aw_valid & reqAW[OUT_INTRGEN];
  assign auto_out_4_aw_valid = in_0_aw_valid & reqAW[OUT_ERROR];
  assign {auto_out_0_aw_bits_id, auto_out_0_aw_bits_len, auto_out_0_aw_bits_size, auto_out_0_aw_bits_burst, auto_out_0_aw_bits_lock, auto_out_0_aw_bits_cache, auto_out_0_aw_bits_prot, auto_out_0_aw_bits_qos} = {aw_in.id, aw_in.len, aw_in.size, aw_in.burst, aw_in.lock, aw_in.cache, aw_in.prot, aw_in.qos};
  assign {auto_out_2_aw_bits_id, auto_out_2_aw_bits_len, auto_out_2_aw_bits_size, auto_out_2_aw_bits_burst, auto_out_2_aw_bits_lock, auto_out_2_aw_bits_cache, auto_out_2_aw_bits_prot, auto_out_2_aw_bits_qos} = {aw_in.id, aw_in.len, aw_in.size, aw_in.burst, aw_in.lock, aw_in.cache, aw_in.prot, aw_in.qos};
  assign {auto_out_3_aw_bits_id, auto_out_3_aw_bits_len, auto_out_3_aw_bits_size, auto_out_3_aw_bits_burst, auto_out_3_aw_bits_lock, auto_out_3_aw_bits_cache, auto_out_3_aw_bits_prot, auto_out_3_aw_bits_qos} = {aw_in.id, aw_in.len, aw_in.size, aw_in.burst, aw_in.lock, aw_in.cache, aw_in.prot, aw_in.qos};
  assign {auto_out_4_aw_bits_id, auto_out_4_aw_bits_len, auto_out_4_aw_bits_size, auto_out_4_aw_bits_burst, auto_out_4_aw_bits_lock, auto_out_4_aw_bits_cache, auto_out_4_aw_bits_prot, auto_out_4_aw_bits_qos} = {aw_in.id, aw_in.len, aw_in.size, aw_in.burst, aw_in.lock, aw_in.cache, aw_in.prot, aw_in.qos};
  assign {auto_out_1_aw_bits_id, auto_out_1_aw_bits_len, auto_out_1_aw_bits_size, auto_out_1_aw_bits_burst, auto_out_1_aw_bits_lock, auto_out_1_aw_bits_cache, auto_out_1_aw_bits_prot, auto_out_1_aw_bits_qos} = {aw_in.id, aw_in.len, aw_in.size, aw_in.burst, aw_in.lock, aw_in.cache, aw_in.prot, aw_in.qos};
  assign auto_out_0_aw_bits_addr = aw_in.addr;
  assign auto_out_2_aw_bits_addr = aw_in.addr;
  assign auto_out_3_aw_bits_addr = aw_in.addr;
  assign auto_out_4_aw_bits_addr = aw_in.addr;
  assign auto_out_1_aw_bits_addr = aw_in.addr[28:0];   // Flash 从口地址截 29 位

  // ---- W (按队首路由 one-hot 分发, 数据/strb/last 广播) ----
  assign auto_out_0_w_valid = in_0_w_valid & awIn_deq_bits[OUT_UART];
  assign auto_out_1_w_valid = in_0_w_valid & awIn_deq_bits[OUT_FLASH];
  assign auto_out_2_w_valid = in_0_w_valid & awIn_deq_bits[OUT_SD];
  assign auto_out_3_w_valid = in_0_w_valid & awIn_deq_bits[OUT_INTRGEN];
  assign auto_out_4_w_valid = in_0_w_valid & awIn_deq_bits[OUT_ERROR];
  assign {auto_out_0_w_bits_data, auto_out_0_w_bits_strb, auto_out_0_w_bits_last} = {auto_in_w_bits_data, auto_in_w_bits_strb, auto_in_w_bits_last};
  assign {auto_out_1_w_bits_data, auto_out_1_w_bits_strb, auto_out_1_w_bits_last} = {auto_in_w_bits_data, auto_in_w_bits_strb, auto_in_w_bits_last};
  assign {auto_out_2_w_bits_data, auto_out_2_w_bits_strb, auto_out_2_w_bits_last} = {auto_in_w_bits_data, auto_in_w_bits_strb, auto_in_w_bits_last};
  assign {auto_out_3_w_bits_data, auto_out_3_w_bits_strb, auto_out_3_w_bits_last} = {auto_in_w_bits_data, auto_in_w_bits_strb, auto_in_w_bits_last};
  assign {auto_out_4_w_bits_data, auto_out_4_w_bits_strb, auto_out_4_w_bits_last} = {auto_in_w_bits_data, auto_in_w_bits_strb, auto_in_w_bits_last};

  // ---- R / B 从口 ready (按仲裁授权/锁定回授) ----
  assign auto_out_0_r_ready = auto_in_r_ready & (idle_5 ? readys_r[OUT_UART]    : state_5[OUT_UART]);
  assign auto_out_1_r_ready = auto_in_r_ready & (idle_5 ? readys_r[OUT_FLASH]   : state_5[OUT_FLASH]);
  assign auto_out_2_r_ready = auto_in_r_ready & (idle_5 ? readys_r[OUT_SD]      : state_5[OUT_SD]);
  assign auto_out_3_r_ready = auto_in_r_ready & (idle_5 ? readys_r[OUT_INTRGEN] : state_5[OUT_INTRGEN]);
  assign auto_out_4_r_ready = auto_in_r_ready & (idle_5 ? readys_r[OUT_ERROR]   : state_5[OUT_ERROR]);
  assign auto_out_0_b_ready = auto_in_b_ready & (idle_6 ? readys_b[OUT_UART]    : state_6[OUT_UART]);
  assign auto_out_1_b_ready = auto_in_b_ready & (idle_6 ? readys_b[OUT_FLASH]   : state_6[OUT_FLASH]);
  assign auto_out_2_b_ready = auto_in_b_ready & (idle_6 ? readys_b[OUT_SD]      : state_6[OUT_SD]);
  assign auto_out_3_b_ready = auto_in_b_ready & (idle_6 ? readys_b[OUT_INTRGEN] : state_6[OUT_INTRGEN]);
  assign auto_out_4_b_ready = auto_in_b_ready & (idle_6 ? readys_b[OUT_ERROR]   : state_6[OUT_ERROR]);

  // ===========================================================================
  //  时序 (同步复位, 同 golden): FIFO map 计数/锁定 + 队列 latched + 仲裁器 idle/mask/state
  // ===========================================================================
  integer i;
  always_ff @(posedge clock) begin
    if (reset) begin
      for (i = 0; i < NUM_ID; i = i + 1) begin
        ar_count[i] <= 3'h0;
        aw_count[i] <= 3'h0;
      end
      latched <= 1'b0;
      idle_5  <= 1'b1;  mask_r <= {NUM_OUT{1'b1}};  state_5 <= '0;
      idle_6  <= 1'b1;  mask_b <= {NUM_OUT{1'b1}};  state_6 <= '0;
    end else begin
      for (i = 0; i < NUM_ID; i = i + 1) begin
        ar_count[i] <= ar_count[i] + 3'(ar_req_fire[i]) - 3'(ar_resp_fire[i]);
        aw_count[i] <= aw_count[i] + 3'(aw_req_fire[i]) - 3'(aw_resp_fire[i]);
      end
      latched <= latched_next;
      // R 仲裁器
      idle_5 <= r_hs | (~anyValid_r & idle_5);
      if (idle_5 & (|out_r_valid_v)) mask_r <= left_or(winner_r);
      if (idle_5)                    state_5 <= winner_r;
      // B 仲裁器
      idle_6 <= b_hs | (~anyValid_b & idle_6);
      if (idle_6 & (|out_b_valid_v)) mask_b <= left_or(winner_b);
      if (idle_6)                    state_6 <= winner_b;
    end
    // last 锁定 (无 reset 守卫, 同 golden: 仅在该 ID 请求 fire 时更新)
    for (i = 0; i < NUM_ID; i = i + 1) begin
      if (ar_req_fire[i]) ar_last[i] <= arTag;
      if (aw_req_fire[i]) aw_last[i] <= awTag;
    end
  end

endmodule
