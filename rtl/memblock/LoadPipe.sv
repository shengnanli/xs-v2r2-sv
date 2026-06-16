// 自动生成框架(端口表) + 手写主体(LoadPipe_core_body.svh)
//   由 scripts/gen_loadpipe.py 拼接。可读核本体改 LoadPipe_core_body.svh。
module xs_LoadPipe_core(
  input  clock,
  input  reset,
  output io_lsu_req_ready,
  input  io_lsu_req_valid,
  input  [4:0] io_lsu_req_bits_cmd,
  input  [49:0] io_lsu_req_bits_vaddr,
  input  [49:0] io_lsu_req_bits_vaddr_dup,
  input  [3:0] io_lsu_req_bits_instrtype,
  input  io_lsu_req_bits_isFirstIssue,
  input  io_lsu_req_bits_lqIdx_flag,
  input  [6:0] io_lsu_req_bits_lqIdx_value,
  output io_lsu_resp_valid,
  output [127:0] io_lsu_resp_bits_data,
  output [127:0] io_lsu_resp_bits_data_delayed,
  output io_lsu_resp_bits_miss,
  output [3:0] io_lsu_resp_bits_mshr_id,
  output [2:0] io_lsu_resp_bits_meta_prefetch,
  output io_lsu_resp_bits_handled,
  output io_lsu_resp_bits_error_delayed,
  input  io_lsu_s1_kill,
  input  io_lsu_s2_kill,
  input  [2:0] io_lsu_pf_source,
  input  [47:0] io_lsu_s1_paddr_dup_lsu,
  input  [47:0] io_lsu_s1_paddr_dup_dcache,
  output io_lsu_s2_bank_conflict,
  output io_lsu_s2_mq_nack,
  input  io_load128Req,
  output io_meta_read_valid,
  output [7:0] io_meta_read_bits_idx,
  input  [1:0] io_meta_resp_0_coh_state,
  input  [1:0] io_meta_resp_1_coh_state,
  input  [1:0] io_meta_resp_2_coh_state,
  input  [1:0] io_meta_resp_3_coh_state,
  input  io_extra_meta_resp_0_error,
  input  [2:0] io_extra_meta_resp_0_prefetch,
  input  io_extra_meta_resp_0_access,
  input  io_extra_meta_resp_1_error,
  input  [2:0] io_extra_meta_resp_1_prefetch,
  input  io_extra_meta_resp_1_access,
  input  io_extra_meta_resp_2_error,
  input  [2:0] io_extra_meta_resp_2_prefetch,
  input  io_extra_meta_resp_2_access,
  input  io_extra_meta_resp_3_error,
  input  [2:0] io_extra_meta_resp_3_prefetch,
  input  io_extra_meta_resp_3_access,
  input  io_tag_read_ready,
  output io_tag_read_valid,
  output [7:0] io_tag_read_bits_idx,
  input  [42:0] io_tag_resp_0,
  input  [42:0] io_tag_resp_1,
  input  [42:0] io_tag_resp_2,
  input  [42:0] io_tag_resp_3,
  input  io_banked_data_read_ready,
  output io_banked_data_read_valid,
  output [3:0] io_banked_data_read_bits_way_en,
  output [47:0] io_banked_data_read_bits_addr,
  output [47:0] io_banked_data_read_bits_addr_dup,
  output [7:0] io_banked_data_read_bits_bankMask,
  output io_banked_data_read_bits_lqIdx_flag,
  output [6:0] io_banked_data_read_bits_lqIdx_value,
  output io_is128Req,
  input  [63:0] io_banked_data_resp_0_raw_data,
  input  [63:0] io_banked_data_resp_1_raw_data,
  input  io_read_error_delayed_0,
  input  io_read_error_delayed_1,
  output io_access_flag_write_valid,
  output [7:0] io_access_flag_write_bits_idx,
  output [3:0] io_access_flag_write_bits_way_en,
  output io_prefetch_flag_write_valid,
  output [7:0] io_prefetch_flag_write_bits_idx,
  output [3:0] io_prefetch_flag_write_bits_way_en,
  input  io_bank_conflict_slow,
  input  io_miss_req_ready,
  output io_miss_req_valid,
  output [3:0] io_miss_req_bits_source,
  output [2:0] io_miss_req_bits_pf_source,
  output [4:0] io_miss_req_bits_cmd,
  output [47:0] io_miss_req_bits_addr,
  output [49:0] io_miss_req_bits_vaddr,
  output [1:0] io_miss_req_bits_req_coh_state,
  output io_miss_req_bits_isBtoT,
  output [3:0] io_miss_req_bits_occupy_way,
  output io_miss_req_bits_cancel,
  input  [3:0] io_miss_resp_id,
  input  io_miss_resp_handled,
  input  io_miss_resp_merged,
  output io_wbq_conflict_check_valid,
  output [47:0] io_wbq_conflict_check_bits,
  input  io_wbq_block_miss_req,
  output io_replace_access_valid,
  output [7:0] io_replace_access_bits_set,
  output [1:0] io_replace_access_bits_way,
  output [7:0] io_occupy_set,
  input  io_occupy_fail,
  input  io_disable_ld_fast_wakeup,
  output io_error_valid,
  output [47:0] io_error_bits_paddr,
  output io_error_bits_report_to_beu,
  input  io_pseudo_error_valid,
  input  io_pseudo_error_bits_0_valid,
  input  [63:0] io_pseudo_error_bits_0_mask,
  output io_pseudo_tag_error_inj_done,
  output io_pseudo_data_error_inj_done,
  output io_prefetch_info_naive_total_prefetch,
  output io_prefetch_info_naive_late_hit_prefetch,
  output io_prefetch_info_naive_late_prefetch_hit,
  output io_prefetch_info_naive_late_load_hit,
  output io_prefetch_info_naive_useful_prefetch,
  output io_prefetch_info_naive_prefetch_hit,
  output io_prefetch_info_fdp_useful_prefetch,
  output io_prefetch_info_fdp_demand_miss,
  output io_prefetch_info_fdp_pollution,
  output io_bloom_filter_query_query_valid,
  output [11:0] io_bloom_filter_query_query_bits_addr,
  input  io_bloom_filter_query_resp_valid,
  input  io_bloom_filter_query_resp_bits_res,
  output io_counter_filter_query_req_valid,
  output [7:0] io_counter_filter_query_req_bits_idx,
  output [1:0] io_counter_filter_query_req_bits_way,
  input  io_counter_filter_query_resp,
  output io_counter_filter_enq_valid,
  output [7:0] io_counter_filter_enq_bits_idx,
  output [1:0] io_counter_filter_enq_bits_way,
  output [5:0] io_perf_0_value,
  output [5:0] io_perf_1_value,
  output [5:0] io_perf_2_value,
  output [5:0] io_perf_3_value,
  output [5:0] io_perf_4_value
);
// 本文件由 scripts/gen_loadpipe.py 拼接进 LoadPipe.sv（端口表之后），勿单独编译。
// =============================================================================
//  可读核 xs_LoadPipe_core 主体 —— 从 LoadPipe.scala 设计意图重写
// -----------------------------------------------------------------------------
//  LoadPipe 是 DCache 的「load 访问流水」：load/store 单元(LSU)经它读 DCache 的
//  tag/meta/data，判断命中(hit)或缺失(miss)，命中则把数据回给 LSU，缺失则向
//  MissQueue 发缺失请求(MissReq)。它是只读探测流水(不写数据)，与 StorePipe 对称。
//
//  四级流水(与 Scala 一致，本顶层配置 WPU 关闭、nack 恒 0)：
//    s0  收 LSU 请求 -> 用 vaddr[13:6] 发 meta_read / tag_read(组索引)
//    s1  收 meta/tag resp -> 4 路并行 tag 比对 + coh 权限判定(onAccess) -> 命中路
//        coh/prefetch/access 选出 -> 算 will_send_miss_req / BtoT -> 发 data 读
//    s2  返回数据(2×64b 拼 128b) -> 判 hit/miss/nack -> 向 MissQueue 发 MissReq、
//        向 WBQ 发冲突检查 -> 回 LSU resp(miss/replay/handled/data)
//    s3  ECC 错误汇报 + 命中行 access/prefetch 标志回写 + replacer 更新 + 计数过滤
//
//  本配置裁剪(golden 已固化，端口随之裁剪，须对齐)：
//    - DCacheWpuWrapper 关闭(enWPU=false)：无 wpu 预测/纠错，s2_wpu_pred_fail 恒 0，
//      故 s1_pred_way_en == s1_real_way_en，banked_data_read.way_en 直接用 real。
//    - io.nack 恒 0(s0 未被 nack)：无 s1_nack / s2_nack_hit。
//    - meta_read 恒 ready：io_lsu_req_ready 退化为 io_tag_read_ready。
//    - 这是一个「永不阻塞」的流水：s1_ready/s2_ready 恒 1，各级只靠 valid 推进。
// =============================================================================
  import loadpipe_pkg::*;

  // ===========================================================================
  //  S0 —— 接收 LSU 请求，发起 tag / meta 组读
  // ===========================================================================
  // s0 有效 = tag array 可读 且 LSU 请求 valid(meta array 本配置恒 ready)。
  wire s0_valid = io_tag_read_ready & io_lsu_req_valid;

  // 128b load 把 vaddr 低 4 位清零(跨 16B 对齐)，否则原样。
  wire [VADDR_BITS-1:0] s0_req_vaddr =
      io_load128Req ? {io_lsu_req_bits_vaddr[VADDR_BITS-1:4], 4'h0}
                    : io_lsu_req_bits_vaddr;

  // bank one-hot：64b 用 vaddr[5:3] 选 1 个 bank；128b 再把相邻 bank 一起点亮(可进位到 bit8)。
  wire [7:0] s0_bank_oh_64 = 8'h1 << s0_req_vaddr[5:3];
  wire [BANK_OH_W-1:0] s0_bank_oh =
      io_load128Req ? {&s0_req_vaddr[5:3], ({s0_bank_oh_64[6:0], 1'h0} | s0_bank_oh_64)}
                    : {1'h0, s0_bank_oh_64};

  // tag / meta 读请求：组索引取 vaddr[13:6]，全路使能(读出 4 路再比对)。
  assign io_lsu_req_ready    = io_tag_read_ready;
  assign io_meta_read_valid  = s0_valid;
  assign io_meta_read_bits_idx = io_lsu_req_bits_vaddr[13:6];
  assign io_tag_read_valid   = s0_valid;
  assign io_tag_read_bits_idx  = io_lsu_req_bits_vaddr[13:6];

  // ===========================================================================
  //  S1 —— tag 比对 + coh 权限判定 + 命中路信息选出 + 发 data 读
  // ===========================================================================
  logic              s1_valid;
  s1_req_t           s1_req;
  logic [BANK_OH_W-1:0] s1_bank_oh;

  // s1 收到 LSU 的物理地址(s1_paddr 在 s1 才到，分 lsu / dcache 两份)。
  wire [PADDR_BITS-1:0] s1_paddr_dcache = io_lsu_s1_paddr_dup_dcache;
  wire [PADDR_BITS-1:0] s1_paddr_lsu    = io_lsu_s1_paddr_dup_lsu;

  // 把 4 路 meta / extra_meta / tag resp 聚成数组，便于 genvar 并行处理。
  meta_t       [N_WAYS-1:0] s1_meta;
  extra_meta_t [N_WAYS-1:0] s1_extra;
  logic [N_WAYS-1:0][ENC_TAG_BITS-1:0] s1_enc_tag;  // 含 ECC 的 tag(可被 pseudo error 翻转)
  assign s1_meta[0].coh_state = io_meta_resp_0_coh_state;
  assign s1_meta[1].coh_state = io_meta_resp_1_coh_state;
  assign s1_meta[2].coh_state = io_meta_resp_2_coh_state;
  assign s1_meta[3].coh_state = io_meta_resp_3_coh_state;
  assign s1_extra[0] = '{error:io_extra_meta_resp_0_error, prefetch:io_extra_meta_resp_0_prefetch, access:io_extra_meta_resp_0_access};
  assign s1_extra[1] = '{error:io_extra_meta_resp_1_error, prefetch:io_extra_meta_resp_1_prefetch, access:io_extra_meta_resp_1_access};
  assign s1_extra[2] = '{error:io_extra_meta_resp_2_error, prefetch:io_extra_meta_resp_2_prefetch, access:io_extra_meta_resp_2_access};
  assign s1_extra[3] = '{error:io_extra_meta_resp_3_error, prefetch:io_extra_meta_resp_3_prefetch, access:io_extra_meta_resp_3_access};

  // pseudo tag error 注入：把 tag 低 36 位异或一个翻转掩码(故障注入用)，正常为 0。
  wire [TAG_BITS-1:0] pseudo_tag_mask =
      (io_pseudo_error_valid & io_pseudo_error_bits_0_valid)
        ? io_pseudo_error_bits_0_mask[TAG_BITS-1:0] : '0;

  logic [N_WAYS-1:0][TAG_BITS-1:0] s1_toggle_tag;  // 注入后的 tag 低位
  genvar gw;
  generate
    for (gw = 0; gw < N_WAYS; gw++) begin : g_tag
      // 各路原始 enc tag(7 位 ecc + 36 位 tag)
      wire [ENC_TAG_BITS-1:0] raw_enc = (gw==0) ? io_tag_resp_0 :
                                        (gw==1) ? io_tag_resp_1 :
                                        (gw==2) ? io_tag_resp_2 : io_tag_resp_3;
      assign s1_toggle_tag[gw] = raw_enc[TAG_BITS-1:0] ^ pseudo_tag_mask;
      assign s1_enc_tag[gw]    = {raw_enc[ENC_TAG_BITS-1:TAG_BITS], s1_toggle_tag[gw]};
    end
  endgenerate

  // 逐路 tag 命中：tag 相等(以 dcache 侧 paddr 高位 [47:12] 比对) 且该路 coh 有效(非 Nothing)。
  logic [N_WAYS-1:0] s1_tag_match_way;   // dcache 侧命中独热
  logic [N_WAYS-1:0] s1_tag_match_lsu;   // lsu 侧命中独热(用于 BtoT 判定)
  generate
    for (gw = 0; gw < N_WAYS; gw++) begin : g_match
      assign s1_tag_match_way[gw] =
          (s1_toggle_tag[gw] == s1_paddr_dcache[47:12]) & (|s1_meta[gw].coh_state);
      assign s1_tag_match_lsu[gw] =
          (s1_toggle_tag[gw] == s1_paddr_lsu[47:12])    & (|s1_meta[gw].coh_state);
    end
  endgenerate
  wire s1_tag_match     = |s1_tag_match_way;

  // 命中路的 coh 状态(独热 OR 选)。无命中时为 0(Nothing)，相当于一个 Fake Meta。
  // 用 OR 选(而非优先选): 正常只有 1 路命中; 若激励让多路同 tag, 与 golden 一致取 OR。
  logic [1:0] s1_hit_coh;
  always_comb begin
    s1_hit_coh = '0;
    for (int w = 0; w < N_WAYS; w++)
      if (s1_tag_match_way[w]) s1_hit_coh = s1_hit_coh | s1_meta[w].coh_state;
  end

  // onAccess 权限判定：把 cmd+coh 归约成 4 位 grow_idx，查表得权限/目标 coh。
  wire [3:0] s1_grow_idx     = grow_index(s1_req.cmd, s1_hit_coh);
  wire       s1_has_perm     = has_permission(s1_grow_idx);
  wire [1:0] s1_new_hit_coh  = grow_new_coh(s1_grow_idx);

  // 命中 = tag 命中 & 已有权限 & coh 不需升级(new==old)。否则需发缺失/升级请求。
  wire s1_hit              = s1_tag_match & s1_has_perm & (s1_hit_coh == s1_new_hit_coh);
  wire s1_will_send_miss   = s1_valid & ~s1_hit;

  // ECC tag 错误检测：对每路 enc tag 做 SEC-DED 伴随式校验(coh 有效才算)。
  // 把 6 个奇偶校验位的异或归约成 syndrome；非全奇偶或 syndrome 非零即报错。
  function automatic logic ecc_tag_error(input logic [ENC_TAG_BITS-1:0] enc,
                                         input logic [TAG_BITS-1:0]     toggled,
                                         input logic                    coh_valid);
    logic        parity;       // 整体奇偶
    logic [5:0]  synd;         // 6 位伴随式(各校验位掩码下的奇偶)
    parity  = ^enc;
    synd[0] = ^({enc[41:36], toggled} & 42'h20FFC000000);
    synd[1] = ^({enc[40:36], toggled} & 41'h10003FFF800);
    synd[2] = ^({enc[39:36], toggled} & 40'h8E03FC07F0);
    synd[3] = ^({enc[38:36], toggled} & 39'h41E3C3C78E);
    synd[4] = ^({enc[37:36], toggled} & 38'h299B33366D);
    synd[5] = ^({enc[36],    toggled} & 37'h1556AAAD5B);
    return coh_valid & (parity | (~parity & (|synd)));
  endfunction

  logic [N_WAYS-1:0] s1_tag_errors;
  generate
    for (gw = 0; gw < N_WAYS; gw++) begin : g_ecc
      assign s1_tag_errors[gw] =
          ecc_tag_error(s1_enc_tag[gw], s1_toggle_tag[gw], |s1_meta[gw].coh_state);
    end
  endgenerate

  // 命中路 extra_meta(error/prefetch/access)独热选出，喂给 s2。
  logic       s1_hit_flag_error;
  logic [2:0] s1_hit_prefetch;
  logic       s1_hit_access;
  always_comb begin
    s1_hit_flag_error = 1'b0;
    s1_hit_prefetch   = '0;
    s1_hit_access     = 1'b0;
    for (int w = 0; w < N_WAYS; w++) begin
      if (s1_tag_match_way[w]) begin
        s1_hit_flag_error |= s1_extra[w].error;
        s1_hit_prefetch   |= s1_extra[w].prefetch;
        s1_hit_access     |= s1_extra[w].access;
      end
    end
  end
  // flag_error 仅在命中(非替换)时有效。
  wire s1_flag_error = s1_tag_match & s1_hit_flag_error;

  // BtoT(Branch->Trunk)升级判定：目标 coh 为 Trunk 且当前无权限，且 lsu 侧 tag 命中。
  wire s1_grow_btot = (s1_new_hit_coh == COH_TRUNK) & ~s1_has_perm & (|s1_tag_match_lsu);

  // s1 寄存器更新：s0 fire 时锁存请求上下文 / bank_oh。
  always_ff @(posedge clock) begin
    if (s0_valid) begin
      s1_req.cmd            <= io_lsu_req_bits_cmd;
      s1_req.vaddr          <= s0_req_vaddr;
      s1_req.vaddr_dup      <= io_lsu_req_bits_vaddr_dup;
      s1_req.instrtype      <= io_lsu_req_bits_instrtype;
      s1_req.is_first_issue <= io_lsu_req_bits_isFirstIssue;
      s1_req.lq_flag        <= io_lsu_req_bits_lqIdx_flag;
      s1_req.lq_value       <= io_lsu_req_bits_lqIdx_value;
      s1_req.load128        <= io_load128Req;
      s1_bank_oh            <= s0_bank_oh;
    end
  end
  always_ff @(posedge clock or posedge reset) begin
    if (reset) s1_valid <= 1'b0;
    else       s1_valid <= s0_valid;
  end

  // s1 是否为硬件预取(预取不真正读 data array)。
  wire s1_is_prefetch = (s1_req.instrtype == PREFETCH_SOURCE);

  // s1 data array 读地址：低 6 位用 s1_paddr(128b 时低 4 位清零)，高位用 s1 vaddr。
  wire [5:0] s1_paddr_off =
      s1_req.load128 ? {s1_paddr_lsu[5:4], 4'h0} : s1_paddr_lsu[5:0];
  // 发 data 读：s1 有效且非预取(预取不取数据)。
  assign io_banked_data_read_valid        = s1_valid & (s1_req.instrtype != PREFETCH_SOURCE);
  assign io_banked_data_read_bits_way_en  = s1_tag_match_way;       // WPU 关 -> 用真实命中路
  assign io_banked_data_read_bits_addr    = {s1_req.vaddr[47:6], s1_paddr_off};
  assign io_banked_data_read_bits_addr_dup =
      {s1_req.vaddr_dup[47:6],
       (s1_req.load128 ? {s1_paddr_dcache[5:4], 4'h0} : s1_paddr_dcache[5:0])};
  assign io_banked_data_read_bits_bankMask  = s1_bank_oh[7:0];
  assign io_banked_data_read_bits_lqIdx_flag  = s1_req.lq_flag;
  assign io_banked_data_read_bits_lqIdx_value = s1_req.lq_value;
  assign io_is128Req = s1_req.load128;

  // bloom filter 查询(预取相关)：地址哈希 = paddr[17:6] ^ paddr[29:18]。
  assign io_bloom_filter_query_query_valid     = s1_valid;
  assign io_bloom_filter_query_query_bits_addr = s1_paddr_dcache[17:6] ^ s1_paddr_dcache[29:18];

  // pseudo tag error 注入完成标志：s1 有效且任一路 coh 有效。
  assign io_pseudo_tag_error_inj_done = s1_valid & (|{|s1_meta[3].coh_state, |s1_meta[2].coh_state,
                                                      |s1_meta[1].coh_state, |s1_meta[0].coh_state});

  // ===========================================================================
  //  S2 —— 数据返回 + hit/miss/nack 判定 + MissReq + LSU resp
  // ===========================================================================
  logic              s2_valid, s2_valid_dup;
  s2_req_t           s2_req;
  logic [PADDR_BITS-1:0] s2_paddr;
  logic [VADDR_BITS-1:0] s2_vaddr;
  logic [N_WAYS-1:0] s2_real_way_en;     // s2 命中独热(real_miss 看它是否为 0)
  logic [N_WAYS-1:0] s2_tag_errors;
  logic [N_WAYS-1:0] s2_tag_match_way;
  logic              s2_tag_match;
  logic [1:0]        s2_hit_coh;
  logic              s2_has_perm;
  logic [1:0]        s2_new_hit_coh;
  logic              s2_grow_btot;
  logic              s2_can_send_miss, s2_can_send_miss_dup;
  logic              s2_nack_data;       // data array bank 冲突(读未 ready)
  logic              s2_flag_error;
  logic [2:0]        s2_hit_prefetch;
  logic              s2_hit_access;

  // s1 data array 读 offset 复制(用于 s2 重建 vaddr 低 6 位)。
  wire [5:0] s2_vaddr_off_src =
      s1_req.load128 ? {s1_paddr_lsu[5:4], 4'h0} : s1_paddr_lsu[5:0];

  always_ff @(posedge clock) begin
    if (s1_valid) begin
      s2_req.cmd            <= s1_req.cmd;
      s2_req.instrtype      <= s1_req.instrtype;
      s2_req.is_first_issue <= s1_req.is_first_issue;
      s2_req.load128        <= s1_req.load128;
      s2_paddr              <= s1_paddr_dcache;
      s2_vaddr              <= {s1_req.vaddr[49:6], s2_vaddr_off_src};
      s2_real_way_en        <= s1_tag_match_way;
      s2_tag_errors         <= s1_tag_errors;
      s2_tag_match_way      <= s1_tag_match_way;
      s2_tag_match          <= s1_tag_match;
      s2_hit_coh            <= s1_hit_coh;
      s2_has_perm           <= s1_has_perm;
      s2_new_hit_coh        <= s1_new_hit_coh;
      s2_grow_btot          <= s1_grow_btot;
      s2_can_send_miss      <= s1_will_send_miss;
      s2_can_send_miss_dup  <= s1_will_send_miss;
      s2_nack_data          <= ~io_banked_data_read_ready;
      s2_flag_error         <= s1_flag_error;
      s2_hit_prefetch       <= s1_hit_prefetch;
      s2_hit_access         <= s1_hit_access;
    end
  end
  // s2_valid：s1 fire 时若未被 s1_kill 则置位；下游恒 ready 故被 resp 自然清。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s2_valid     <= 1'b0;
      s2_valid_dup <= 1'b0;
    end else begin
      s2_valid <= s1_valid & ~io_lsu_s1_kill;
      if (s1_valid) s2_valid_dup <= ~io_lsu_s1_kill;
      else          s2_valid_dup <= ~s2_valid & s2_valid_dup;
    end
  end

  // s2 命中 = tag 命中 & 有权限 & coh 不需升级(WPU 关，无 pred_fail)。
  wire s2_hit       = s2_tag_match & s2_has_perm & (s2_hit_coh == s2_new_hit_coh);
  wire s2_real_miss = ~(|s2_real_way_en);

  // 缺失请求/冲突
  wire s2_miss_req_valid_dup = s2_valid_dup & s2_can_send_miss_dup;
  wire s2_nack_no_mshr       = s2_miss_req_valid_dup & ~io_miss_req_ready;   // MSHR 满
  wire s2_btot_occupy_fail   = io_occupy_fail & s2_grow_btot;                // BtoT 占位失败
  // MissReq cancel：被 s2_kill / tag ecc 错 / BtoT 占位失败 取消。
  wire s2_miss_cancel = io_lsu_s2_kill | (|s2_tag_errors) | s2_btot_occupy_fail;

  // 数据(2×64b bank 拼成 128b)。
  wire [DATA_W-1:0] s2_data128 = {io_banked_data_resp_1_raw_data, io_banked_data_resp_0_raw_data};

  // 需要 replay 的条件：真 miss 且(无 mshr / bank 冲突 / wbq 阻塞 / cancel)，或 bank 慢冲突，或 BtoT 失败。
  wire s2_resp_replay =
      (s2_real_miss & (s2_nack_no_mshr | s2_nack_data |
                       (s2_miss_req_valid_dup & io_wbq_block_miss_req) | s2_miss_cancel))
      | io_bank_conflict_slow | s2_btot_occupy_fail;
  // 缺失已被 MissQueue 接管(handled)：上层无需 replay，挂 LoadQueue 等 refill。
  wire s2_resp_handled =
      s2_miss_req_valid_dup & io_miss_req_ready & ~s2_miss_cancel
      & ~io_wbq_block_miss_req & io_miss_resp_handled;

  // io.lsu.pf_source 打两拍后给 MissReq.pf_source。
  logic [2:0] s2_pf_source_d1, s2_pf_source_d2;
  always_ff @(posedge clock) begin
    s2_pf_source_d1 <= io_lsu_pf_source;
    s2_pf_source_d2 <= s2_pf_source_d1;
  end

  // ---- 向 MissQueue 发缺失请求 ----
  assign io_miss_req_valid        = s2_valid & s2_can_send_miss;
  assign io_miss_req_bits_source  = s2_req.instrtype;
  assign io_miss_req_bits_pf_source = s2_pf_source_d2;   // pf_source 打两拍(见下)
  assign io_miss_req_bits_cmd     = s2_req.cmd;
  assign io_miss_req_bits_addr    = {s2_paddr[47:6], 6'h0};   // 行基址
  assign io_miss_req_bits_vaddr   = s2_vaddr;
  assign io_miss_req_bits_req_coh_state = s2_hit_coh;
  assign io_miss_req_bits_isBtoT  = s2_grow_btot;
  assign io_miss_req_bits_occupy_way = s2_tag_match_way;
  assign io_miss_req_bits_cancel  = s2_miss_cancel;

  // ---- 向 WBQ 发冲突检查(行基址) ----
  assign io_wbq_conflict_check_valid = s2_miss_req_valid_dup;
  assign io_wbq_conflict_check_bits  = {s2_paddr[47:6], 6'h0};

  // ---- 回 LSU 响应 ----
  assign io_lsu_resp_valid             = s2_valid;
  assign io_lsu_resp_bits_data         = s2_data128;
  assign io_lsu_resp_bits_miss         = s2_real_miss;
  assign io_lsu_resp_bits_mshr_id      = io_miss_resp_id;
  assign io_lsu_resp_bits_meta_prefetch= s2_hit_prefetch;
  assign io_lsu_resp_bits_handled      = s2_resp_handled;
  assign io_lsu_s2_bank_conflict       = io_bank_conflict_slow;
  // mq_nack：真 miss 且(无 mshr / cancel / wbq 阻塞)，或 BtoT 失败。
  assign io_lsu_s2_mq_nack =
      (s2_real_miss & (s2_nack_no_mshr | s2_miss_cancel | io_wbq_block_miss_req))
      | s2_btot_occupy_fail;

  assign io_occupy_set = s2_vaddr[13:6];

  // ---- prefetch 统计信息 ----
  wire s2_is_pf      = (s2_req.instrtype == PREFETCH_SOURCE);
  wire s2_not_pf     = (s2_req.instrtype != PREFETCH_SOURCE);
  wire s2_valid_hit  = s2_valid & s2_hit;
  wire s2_hw_pf_line = |s2_hit_prefetch[2:1];     // 命中行来自硬件预取
  assign io_pseudo_data_error_inj_done       = s2_valid_hit & ~io_bank_conflict_slow;
  assign io_prefetch_info_naive_total_prefetch  = s2_valid & s2_is_pf;
  assign io_prefetch_info_naive_late_hit_prefetch = s2_valid_hit & s2_is_pf;
  assign io_prefetch_info_naive_late_prefetch_hit = s2_valid_hit & s2_is_pf & s2_hw_pf_line;
  assign io_prefetch_info_naive_late_load_hit     = s2_valid_hit & s2_is_pf & ~s2_hw_pf_line;
  assign io_prefetch_info_naive_useful_prefetch   = s2_valid & s2_is_pf & s2_resp_handled & ~io_miss_resp_merged;
  assign io_prefetch_info_naive_prefetch_hit      = s2_valid & s2_not_pf & s2_hit & s2_hw_pf_line & s2_req.is_first_issue;
  wire s2_demand_miss = s2_valid & s2_not_pf & ~s2_hit & s2_req.is_first_issue;
  assign io_prefetch_info_fdp_demand_miss = s2_demand_miss;
  assign io_prefetch_info_fdp_pollution   =
      s2_demand_miss & io_bloom_filter_query_resp_valid & io_bloom_filter_query_resp_bits_res;

  // ===========================================================================
  //  S3 —— ECC 错误汇报 + 命中行标志回写 + replacer 更新 + 预取计数过滤
  // ===========================================================================
  logic              s3_valid;
  logic              s3_load128;
  logic [VADDR_BITS-1:0] s3_vaddr;
  logic [PADDR_BITS-1:0] s3_paddr;
  logic              s3_hit;
  logic [N_WAYS-1:0] s3_tag_match_way;
  logic [3:0]        s3_instrtype;
  logic [DATA_W-1:0] s3_data;
  logic              s3_tag_error;
  logic              s3_flag_error;
  logic [2:0]        s3_hit_prefetch;

  // 注意：s3_valid 无复位(与 golden 一致, s3 不参与流水启停判定, 复位后头几拍由
  // 上游 s2_valid 自然带入有效值, 故省去复位以匹配 golden 寄存器集)。
  always_ff @(posedge clock) begin
    s3_valid <= s2_valid;
    if (s2_valid) begin
      s3_load128       <= s2_req.load128;
      s3_vaddr         <= s2_vaddr;
      s3_paddr         <= s2_paddr;
      s3_hit           <= s2_hit;
      s3_tag_match_way <= s2_tag_match_way;
      s3_instrtype     <= s2_req.instrtype;
      s3_data          <= s2_data128;
      s3_tag_error     <= |s2_tag_errors;
      s3_flag_error    <= s2_flag_error;
      s3_hit_prefetch  <= s2_hit_prefetch;
    end
  end

  // data ECC 错误(命中时)：128b 看两个 bank，否则只看 bank0。
  wire s3_data_error =
      (s3_load128 ? (|{io_read_error_delayed_1, io_read_error_delayed_0}) : io_read_error_delayed_0)
      & s3_hit;
  wire s3_error = s3_tag_error | s3_flag_error | s3_data_error;

  assign io_lsu_resp_bits_data_delayed   = s3_data;
  assign io_lsu_resp_bits_error_delayed  = s3_error & (s3_hit | s3_tag_error) & s3_valid;

  // 命中行回写 access / prefetch 标志、replacer 更新 —— 仅命中且非预取流。
  wire s3_hit_valid    = s3_valid & s3_hit;
  wire s3_not_pf       = (s3_instrtype != PREFETCH_SOURCE);
  // 命中行来自硬件预取且本次是真正 load -> 清 prefetch 标志(prefetch -> demand)。
  wire s3_clear_pf     = s3_hit_valid & s3_not_pf & (|s3_hit_prefetch[2:1]);
  wire s3_pf_enq       = s3_clear_pf & ~io_counter_filter_query_resp;

  assign io_access_flag_write_valid   = s3_hit_valid & s3_not_pf;
  assign io_access_flag_write_bits_idx    = s3_vaddr[13:6];
  assign io_access_flag_write_bits_way_en = s3_tag_match_way;
  assign io_prefetch_flag_write_valid = s3_pf_enq;
  assign io_prefetch_flag_write_bits_idx    = s3_vaddr[13:6];
  assign io_prefetch_flag_write_bits_way_en = s3_tag_match_way;

  // way 独热 -> 2 位 way 号(OHToUInt)。
  function automatic logic [1:0] oh_to_way(input logic [N_WAYS-1:0] oh);
    return {|oh[3:2], oh[3] | oh[1]};
  endfunction

  assign io_counter_filter_query_req_valid    = s3_clear_pf;
  assign io_counter_filter_query_req_bits_idx = s3_vaddr[13:6];
  assign io_counter_filter_query_req_bits_way = oh_to_way(s3_tag_match_way);
  assign io_counter_filter_enq_valid    = s3_pf_enq;
  assign io_counter_filter_enq_bits_idx = s3_vaddr[13:6];
  assign io_counter_filter_enq_bits_way = oh_to_way(s3_tag_match_way);
  assign io_prefetch_info_fdp_useful_prefetch = s3_pf_enq;

  // ECC 错误汇报到 BusErrorUnit / CSR。
  assign io_error_valid         = s3_error & s3_valid;
  assign io_error_bits_paddr    = s3_paddr;
  assign io_error_bits_report_to_beu = (s3_tag_error | s3_data_error) & s3_valid;

  // replacer 访问更新：命中拍打两拍后给出 set/way(与 golden 一致, 用 RegNext 链)。
  assign io_replace_access_valid = s3_hit_valid;
  logic [7:0] rep_set_d1, rep_set_d2;
  logic [1:0] rep_way_d1, rep_way_d2;
  always_ff @(posedge clock) begin
    rep_set_d1 <= s1_req.vaddr[13:6];
    rep_set_d2 <= rep_set_d1;
    rep_way_d1 <= oh_to_way(s1_tag_match_way);
    rep_way_d2 <= rep_way_d1;
  end
  assign io_replace_access_bits_set = rep_set_d2;
  assign io_replace_access_bits_way = rep_way_d2;

  // ===========================================================================
  //  性能计数(各打两拍输出，与 golden io_perf_*_REG 链一致)
  // ===========================================================================
  logic [4:0] perf_d1, perf_d2;
  wire [4:0] perf_now = {
      s2_valid & s2_resp_replay & io_bank_conflict_slow,  // 4
      s2_valid & s2_resp_replay & s2_nack_no_mshr,        // 3
      s2_valid & s2_resp_replay & s2_nack_data,           // 2
      s2_valid & s2_resp_replay,                          // 1
      s0_valid                                            // 0
  };
  always_ff @(posedge clock) begin
    perf_d1 <= perf_now;
    perf_d2 <= perf_d1;
  end
  assign io_perf_0_value = {5'h0, perf_d2[0]};
  assign io_perf_1_value = {5'h0, perf_d2[1]};
  assign io_perf_2_value = {5'h0, perf_d2[2]};
  assign io_perf_3_value = {5'h0, perf_d2[3]};
  assign io_perf_4_value = {5'h0, perf_d2[4]};

endmodule