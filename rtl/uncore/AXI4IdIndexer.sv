// =============================================================================
//  AXI4IdIndexer / AXI4IdIndexer_1 —— AXI4 ID 位宽适配器 (可读重写核)
// -----------------------------------------------------------------------------
//  源自 rocket-chip AXI4IdIndexer (src/main/scala/amba/axi4/IdIndexer.scala)。两者均为
//  纯组合直通适配器 (无时钟/寄存器/子模块), 只对 AW/AR/B/R 的 ID 字段做适配, 其余字段直通:
//
//    xs_AXI4IdIndexer_core   : 上游 7 位 ID → 下游 14 位 ID, 上行零扩展 {7'h0,id}; 下行截 id[6:0]。
//    xs_AXI4IdIndexer_1_core : 下游仅 2 位 ID; 上行 out.id=id[1:0] + echo.extra_id=id[6:2] 随路;
//                              下行 in.id={echo.extra_id, out.id} 还原 7 位。
//
//  端口表据 golden 同名模块忠实生成 (位宽/顺序一致), 赋值体为手写可读逻辑。
//  验证: 各变体 golden vs 可读变体 双例化逐拍比对全部输出; FM 证等价。
// =============================================================================

module xs_AXI4IdIndexer_core(
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
  output [1:0] auto_in_r_bits_resp,
  output auto_in_r_bits_last,
  input auto_out_aw_ready,
  output auto_out_aw_valid,
  output [13:0] auto_out_aw_bits_id,
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
  input [13:0] auto_out_b_bits_id,
  input auto_out_ar_ready,
  output auto_out_ar_valid,
  output [13:0] auto_out_ar_bits_id,
  output [47:0] auto_out_ar_bits_addr,
  output [7:0] auto_out_ar_bits_len,
  output [2:0] auto_out_ar_bits_size,
  output [1:0] auto_out_ar_bits_burst,
  output [3:0] auto_out_ar_bits_cache,
  output [2:0] auto_out_ar_bits_prot,
  output [3:0] auto_out_ar_bits_qos,
  output auto_out_r_ready,
  input auto_out_r_valid,
  input [13:0] auto_out_r_bits_id,
  input [255:0] auto_out_r_bits_data,
  input [1:0] auto_out_r_bits_resp,
  input auto_out_r_bits_last
);

  // ---- 上行 (in→out): AW/AR 把 7 位主口 ID 零扩展到 14 位下游 ID (高 7 位补 0) ----
  assign auto_out_aw_bits_id    = {7'h0, auto_in_aw_bits_id};
  assign auto_out_ar_bits_id    = {7'h0, auto_in_ar_bits_id};
  // ---- 下行 (out→in): B/R 把 14 位下游 ID 截回 7 位主口 ID ----
  assign auto_in_b_bits_id      = auto_out_b_bits_id[6:0];
  assign auto_in_r_bits_id      = auto_out_r_bits_id[6:0];

  // ---- 其余字段全直通 ----
  // 握手: ready 反向直通, valid 正向直通
  assign auto_in_aw_ready       = auto_out_aw_ready;
  assign auto_in_w_ready        = auto_out_w_ready;
  assign auto_in_ar_ready       = auto_out_ar_ready;
  assign auto_in_b_valid        = auto_out_b_valid;
  assign auto_in_r_valid        = auto_out_r_valid;
  assign auto_out_aw_valid      = auto_in_aw_valid;
  assign auto_out_w_valid       = auto_in_w_valid;
  assign auto_out_ar_valid      = auto_in_ar_valid;
  assign auto_out_b_ready       = auto_in_b_ready;
  assign auto_out_r_ready       = auto_in_r_ready;
  // AW 载荷 (除 id 外) 正向直通
  assign auto_out_aw_bits_addr  = auto_in_aw_bits_addr;
  assign auto_out_aw_bits_len   = auto_in_aw_bits_len;
  assign auto_out_aw_bits_size  = auto_in_aw_bits_size;
  assign auto_out_aw_bits_burst = auto_in_aw_bits_burst;
  assign auto_out_aw_bits_cache = auto_in_aw_bits_cache;
  assign auto_out_aw_bits_prot  = auto_in_aw_bits_prot;
  assign auto_out_aw_bits_qos   = auto_in_aw_bits_qos;
  // W 载荷正向直通
  assign auto_out_w_bits_data   = auto_in_w_bits_data;
  assign auto_out_w_bits_strb   = auto_in_w_bits_strb;
  assign auto_out_w_bits_last   = auto_in_w_bits_last;
  // AR 载荷 (除 id 外) 正向直通
  assign auto_out_ar_bits_addr  = auto_in_ar_bits_addr;
  assign auto_out_ar_bits_len   = auto_in_ar_bits_len;
  assign auto_out_ar_bits_size  = auto_in_ar_bits_size;
  assign auto_out_ar_bits_burst = auto_in_ar_bits_burst;
  assign auto_out_ar_bits_cache = auto_in_ar_bits_cache;
  assign auto_out_ar_bits_prot  = auto_in_ar_bits_prot;
  assign auto_out_ar_bits_qos   = auto_in_ar_bits_qos;
  // R 载荷 (除 id 外) 反向直通
  assign auto_in_r_bits_data    = auto_out_r_bits_data;
  assign auto_in_r_bits_resp    = auto_out_r_bits_resp;
  assign auto_in_r_bits_last    = auto_out_r_bits_last;

endmodule

module xs_AXI4IdIndexer_1_core(
  output auto_in_aw_ready,
  input auto_in_aw_valid,
  input [6:0] auto_in_aw_bits_id,
  input [30:0] auto_in_aw_bits_addr,
  input [7:0] auto_in_aw_bits_len,
  input [2:0] auto_in_aw_bits_size,
  input [1:0] auto_in_aw_bits_burst,
  input auto_in_aw_bits_lock,
  input [3:0] auto_in_aw_bits_cache,
  input [2:0] auto_in_aw_bits_prot,
  input [3:0] auto_in_aw_bits_qos,
  output auto_in_w_ready,
  input auto_in_w_valid,
  input [63:0] auto_in_w_bits_data,
  input [7:0] auto_in_w_bits_strb,
  input auto_in_w_bits_last,
  input auto_in_b_ready,
  output auto_in_b_valid,
  output [6:0] auto_in_b_bits_id,
  output [1:0] auto_in_b_bits_resp,
  output auto_in_ar_ready,
  input auto_in_ar_valid,
  input [6:0] auto_in_ar_bits_id,
  input [30:0] auto_in_ar_bits_addr,
  input [7:0] auto_in_ar_bits_len,
  input [2:0] auto_in_ar_bits_size,
  input [1:0] auto_in_ar_bits_burst,
  input auto_in_ar_bits_lock,
  input [3:0] auto_in_ar_bits_cache,
  input [2:0] auto_in_ar_bits_prot,
  input [3:0] auto_in_ar_bits_qos,
  input auto_in_r_ready,
  output auto_in_r_valid,
  output [6:0] auto_in_r_bits_id,
  output [63:0] auto_in_r_bits_data,
  output [1:0] auto_in_r_bits_resp,
  output auto_in_r_bits_last,
  input auto_out_aw_ready,
  output auto_out_aw_valid,
  output [1:0] auto_out_aw_bits_id,
  output [30:0] auto_out_aw_bits_addr,
  output [7:0] auto_out_aw_bits_len,
  output [2:0] auto_out_aw_bits_size,
  output [1:0] auto_out_aw_bits_burst,
  output auto_out_aw_bits_lock,
  output [3:0] auto_out_aw_bits_cache,
  output [2:0] auto_out_aw_bits_prot,
  output [3:0] auto_out_aw_bits_qos,
  output [4:0] auto_out_aw_bits_echo_extra_id,
  input auto_out_w_ready,
  output auto_out_w_valid,
  output [63:0] auto_out_w_bits_data,
  output [7:0] auto_out_w_bits_strb,
  output auto_out_w_bits_last,
  output auto_out_b_ready,
  input auto_out_b_valid,
  input [1:0] auto_out_b_bits_id,
  input [1:0] auto_out_b_bits_resp,
  input [4:0] auto_out_b_bits_echo_extra_id,
  input auto_out_ar_ready,
  output auto_out_ar_valid,
  output [1:0] auto_out_ar_bits_id,
  output [30:0] auto_out_ar_bits_addr,
  output [7:0] auto_out_ar_bits_len,
  output [2:0] auto_out_ar_bits_size,
  output [1:0] auto_out_ar_bits_burst,
  output auto_out_ar_bits_lock,
  output [3:0] auto_out_ar_bits_cache,
  output [2:0] auto_out_ar_bits_prot,
  output [3:0] auto_out_ar_bits_qos,
  output [4:0] auto_out_ar_bits_echo_extra_id,
  output auto_out_r_ready,
  input auto_out_r_valid,
  input [1:0] auto_out_r_bits_id,
  input [63:0] auto_out_r_bits_data,
  input [1:0] auto_out_r_bits_resp,
  input [4:0] auto_out_r_bits_echo_extra_id,
  input auto_out_r_bits_last
);

  // ---- 上行 (in→out): 下游从口仅支持 2 位 ID ----
  //  把 7 位主口 ID 拆成 {高 5 位, 低 2 位}: 低 2 位作下游 ID; 高 5 位塞进 AXI user-echo 字段
  //  echo.extra_id 随 AW/AR 携带到从口 (从口原样回传, 不解析), 供响应时还原主口 ID。
  assign auto_out_aw_bits_id            = auto_in_aw_bits_id[1:0];
  assign auto_out_aw_bits_echo_extra_id = auto_in_aw_bits_id[6:2];
  assign auto_out_ar_bits_id            = auto_in_ar_bits_id[1:0];
  assign auto_out_ar_bits_echo_extra_id = auto_in_ar_bits_id[6:2];
  // ---- 下行 (out→in): 从 echo.extra_id 取回高 5 位, 与 2 位下游 ID 拼回 7 位主口 ID ----
  assign auto_in_b_bits_id   = {auto_out_b_bits_echo_extra_id, auto_out_b_bits_id};
  assign auto_in_r_bits_id   = {auto_out_r_bits_echo_extra_id, auto_out_r_bits_id};

  // ---- 其余字段全直通 ----
  // 握手
  assign auto_in_aw_ready    = auto_out_aw_ready;
  assign auto_in_w_ready     = auto_out_w_ready;
  assign auto_in_ar_ready    = auto_out_ar_ready;
  assign auto_in_b_valid     = auto_out_b_valid;
  assign auto_in_r_valid     = auto_out_r_valid;
  assign auto_out_aw_valid   = auto_in_aw_valid;
  assign auto_out_w_valid    = auto_in_w_valid;
  assign auto_out_ar_valid   = auto_in_ar_valid;
  assign auto_out_b_ready    = auto_in_b_ready;
  assign auto_out_r_ready    = auto_in_r_ready;
  // B 载荷 (resp) 反向直通
  assign auto_in_b_bits_resp = auto_out_b_bits_resp;
  // AW 载荷 (除 id/echo 外) 正向直通
  assign auto_out_aw_bits_addr  = auto_in_aw_bits_addr;
  assign auto_out_aw_bits_len   = auto_in_aw_bits_len;
  assign auto_out_aw_bits_size  = auto_in_aw_bits_size;
  assign auto_out_aw_bits_burst = auto_in_aw_bits_burst;
  assign auto_out_aw_bits_lock  = auto_in_aw_bits_lock;
  assign auto_out_aw_bits_cache = auto_in_aw_bits_cache;
  assign auto_out_aw_bits_prot  = auto_in_aw_bits_prot;
  assign auto_out_aw_bits_qos   = auto_in_aw_bits_qos;
  // W 载荷正向直通
  assign auto_out_w_bits_data   = auto_in_w_bits_data;
  assign auto_out_w_bits_strb   = auto_in_w_bits_strb;
  assign auto_out_w_bits_last   = auto_in_w_bits_last;
  // AR 载荷 (除 id/echo 外) 正向直通
  assign auto_out_ar_bits_addr  = auto_in_ar_bits_addr;
  assign auto_out_ar_bits_len   = auto_in_ar_bits_len;
  assign auto_out_ar_bits_size  = auto_in_ar_bits_size;
  assign auto_out_ar_bits_burst = auto_in_ar_bits_burst;
  assign auto_out_ar_bits_lock  = auto_in_ar_bits_lock;
  assign auto_out_ar_bits_cache = auto_in_ar_bits_cache;
  assign auto_out_ar_bits_prot  = auto_in_ar_bits_prot;
  assign auto_out_ar_bits_qos   = auto_in_ar_bits_qos;
  // R 载荷 (除 id 外) 反向直通
  assign auto_in_r_bits_data    = auto_out_r_bits_data;
  assign auto_in_r_bits_resp    = auto_out_r_bits_resp;
  assign auto_in_r_bits_last    = auto_out_r_bits_last;

endmodule
