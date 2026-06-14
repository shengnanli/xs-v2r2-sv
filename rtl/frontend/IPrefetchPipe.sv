// =============================================================================
// xs_IPrefetchPipe_core —— ICache 预取流水（IPrefetch pipeline）
//
// 对应 Chisel: xiangshan.frontend.icache.IPrefetchPipe
//
// 三级流水（s0 组合接收 / s1 寄存+ITLB+Meta / s2 寄存+PMP+MSHR 发送）的预取请求处理：
//   - s0：组合，把 req 旁路给 ITLB / IMeta 读端口，并在 s0_fire 时打入 s1。
//   - s1：状态机 state(3bit) 驱动，等待 ITLB（可能多周期 miss 重发）→ 读 IMeta
//         比较 ptag 得 waymask/meta_codes，期间监听 MSHRResp 修正 waymask；
//         结束时把 way 查询结果写 WayLookup（io_wayLookupWrite），并在 s1_real_fire
//         (s1_fire & csr_pf_enable) 时把数据打入 s2。
//   - s2：用 PMP 结果定 exception/mmio，判定 miss，经 2 路优先级 Arbiter 发 MSHRReq；
//         has_send 记录已发，s2_finish 后流水推进。
//
// 状态编码 state（与 Chisel m_* 一致）：
//   0 m_idle, 1 m_itlbResend, 2 m_metaResend, 3 m_enqWay, 4 m_enqIPF(等 s2)
//
// 寄存器命名沿用 golden（s1_*/s2_*/state/has_send_*/REG* 等），便于 Formality 按名匹配。
// 子模块 Arbiter2_ICacheMissReq 为纯组合优先级仲裁器，这里内联其逻辑。
// =============================================================================
module xs_IPrefetchPipe_core (
  input         clock,
  input         reset,
  input         io_csr_pf_enable,
  input         io_flush,
  output        io_req_ready,
  input         io_req_valid,
  input  [49:0] io_req_bits_startAddr,
  input  [49:0] io_req_bits_nextlineStart,
  input         io_req_bits_ftqIdx_flag,
  input  [5:0]  io_req_bits_ftqIdx_value,
  input         io_req_bits_isSoftPrefetch,
  input  [1:0]  io_req_bits_backendException,
  input         io_flushFromBpu_s2_valid,
  input         io_flushFromBpu_s2_bits_flag,
  input  [5:0]  io_flushFromBpu_s2_bits_value,
  input         io_flushFromBpu_s3_valid,
  input         io_flushFromBpu_s3_bits_flag,
  input  [5:0]  io_flushFromBpu_s3_bits_value,
  output        io_itlb_0_req_valid,
  output [49:0] io_itlb_0_req_bits_vaddr,
  input  [47:0] io_itlb_0_resp_bits_paddr_0,
  input  [63:0] io_itlb_0_resp_bits_gpaddr_0,
  input  [1:0]  io_itlb_0_resp_bits_pbmt_0,
  input         io_itlb_0_resp_bits_miss,
  input         io_itlb_0_resp_bits_isForVSnonLeafPTE,
  input         io_itlb_0_resp_bits_excp_0_gpf_instr,
  input         io_itlb_0_resp_bits_excp_0_pf_instr,
  input         io_itlb_0_resp_bits_excp_0_af_instr,
  output        io_itlb_1_req_valid,
  output [49:0] io_itlb_1_req_bits_vaddr,
  input  [47:0] io_itlb_1_resp_bits_paddr_0,
  input  [63:0] io_itlb_1_resp_bits_gpaddr_0,
  input  [1:0]  io_itlb_1_resp_bits_pbmt_0,
  input         io_itlb_1_resp_bits_miss,
  input         io_itlb_1_resp_bits_isForVSnonLeafPTE,
  input         io_itlb_1_resp_bits_excp_0_gpf_instr,
  input         io_itlb_1_resp_bits_excp_0_pf_instr,
  input         io_itlb_1_resp_bits_excp_0_af_instr,
  output        io_itlbFlushPipe,
  output [47:0] io_pmp_0_req_bits_addr,
  input         io_pmp_0_resp_instr,
  input         io_pmp_0_resp_mmio,
  output [47:0] io_pmp_1_req_bits_addr,
  input         io_pmp_1_resp_instr,
  input         io_pmp_1_resp_mmio,
  input         io_metaRead_toIMeta_ready,
  output        io_metaRead_toIMeta_valid,
  output [7:0]  io_metaRead_toIMeta_bits_vSetIdx_0,
  output [7:0]  io_metaRead_toIMeta_bits_vSetIdx_1,
  output        io_metaRead_toIMeta_bits_isDoubleLine,
  input  [35:0] io_metaRead_fromIMeta_metas_0_0_tag,
  input  [35:0] io_metaRead_fromIMeta_metas_0_1_tag,
  input  [35:0] io_metaRead_fromIMeta_metas_0_2_tag,
  input  [35:0] io_metaRead_fromIMeta_metas_0_3_tag,
  input  [35:0] io_metaRead_fromIMeta_metas_1_0_tag,
  input  [35:0] io_metaRead_fromIMeta_metas_1_1_tag,
  input  [35:0] io_metaRead_fromIMeta_metas_1_2_tag,
  input  [35:0] io_metaRead_fromIMeta_metas_1_3_tag,
  input         io_metaRead_fromIMeta_codes_0_0,
  input         io_metaRead_fromIMeta_codes_0_1,
  input         io_metaRead_fromIMeta_codes_0_2,
  input         io_metaRead_fromIMeta_codes_0_3,
  input         io_metaRead_fromIMeta_codes_1_0,
  input         io_metaRead_fromIMeta_codes_1_1,
  input         io_metaRead_fromIMeta_codes_1_2,
  input         io_metaRead_fromIMeta_codes_1_3,
  input         io_metaRead_fromIMeta_entryValid_0_0,
  input         io_metaRead_fromIMeta_entryValid_0_1,
  input         io_metaRead_fromIMeta_entryValid_0_2,
  input         io_metaRead_fromIMeta_entryValid_0_3,
  input         io_metaRead_fromIMeta_entryValid_1_0,
  input         io_metaRead_fromIMeta_entryValid_1_1,
  input         io_metaRead_fromIMeta_entryValid_1_2,
  input         io_metaRead_fromIMeta_entryValid_1_3,
  input         io_MSHRReq_ready,
  output        io_MSHRReq_valid,
  output [41:0] io_MSHRReq_bits_blkPaddr,
  output [7:0]  io_MSHRReq_bits_vSetIdx,
  input         io_MSHRResp_valid,
  input  [41:0] io_MSHRResp_bits_blkPaddr,
  input  [7:0]  io_MSHRResp_bits_vSetIdx,
  input  [3:0]  io_MSHRResp_bits_waymask,
  input         io_MSHRResp_bits_corrupt,
  input         io_wayLookupWrite_ready,
  output        io_wayLookupWrite_valid,
  output [7:0]  io_wayLookupWrite_bits_entry_vSetIdx_0,
  output [7:0]  io_wayLookupWrite_bits_entry_vSetIdx_1,
  output [3:0]  io_wayLookupWrite_bits_entry_waymask_0,
  output [3:0]  io_wayLookupWrite_bits_entry_waymask_1,
  output [35:0] io_wayLookupWrite_bits_entry_ptag_0,
  output [35:0] io_wayLookupWrite_bits_entry_ptag_1,
  output [1:0]  io_wayLookupWrite_bits_entry_itlb_exception_0,
  output [1:0]  io_wayLookupWrite_bits_entry_itlb_exception_1,
  output [1:0]  io_wayLookupWrite_bits_entry_itlb_pbmt_0,
  output [1:0]  io_wayLookupWrite_bits_entry_itlb_pbmt_1,
  output        io_wayLookupWrite_bits_entry_meta_codes_0,
  output        io_wayLookupWrite_bits_entry_meta_codes_1,
  output [55:0] io_wayLookupWrite_bits_gpf_gpaddr,
  output        io_wayLookupWrite_bits_gpf_isForVSnonLeafPTE
);

  // 状态编码
  localparam [2:0] M_IDLE       = 3'h0;
  localparam [2:0] M_ITLBRESEND = 3'h1;
  localparam [2:0] M_METARESEND = 3'h2;
  localparam [2:0] M_ENQWAY     = 3'h3;
  localparam [2:0] M_ENQIPF     = 3'h4;

  // ExceptionType 编码
  localparam [1:0] EXCP_NONE = 2'h0;
  localparam [1:0] EXCP_PF   = 2'h1;
  localparam [1:0] EXCP_GPF  = 2'h2;

  // 跨级握手信号前置声明（在 next_state / s2 区域驱动）
  wire s1_flush;
  wire s1_ready;
  wire s2_ready;

  // ---------------------------------------------------------------------------
  // 流水寄存器
  // ---------------------------------------------------------------------------
  reg         s1_valid;
  reg  [49:0] s1_req_vaddr_0;
  reg  [49:0] s1_req_vaddr_1;
  reg         s1_isSoftPrefetch;
  reg         s1_doubleline;
  reg         s1_req_ftqIdx_flag;
  reg  [5:0]  s1_req_ftqIdx_value;
  reg  [1:0]  s1_backendException_0;
  reg  [1:0]  s1_backendException_1;
  reg  [2:0]  state;

  // s0_fire 的若干打拍副本（firtool 拆出来的同源寄存器）
  reg         s0_fire_r;
  reg         REG;
  reg         REG_1;
  reg         s1_need_itlb_REG;
  reg         s1_need_itlb_REG_1;
  reg         tlb_valid_pulse_REG;
  reg         tlb_valid_pulse_REG_1;

  reg         s1_wait_itlb_0;
  reg         s1_wait_itlb_1;
  reg         tlb_valid_latch_valid;
  reg         tlb_valid_latch_valid_1;

  reg  [47:0] s1_req_paddr_reg_r;
  reg  [47:0] s1_req_paddr_reg_r_1;
  reg  [55:0] s1_req_gpaddr_tmp_r;
  reg  [55:0] s1_req_gpaddr_tmp_r_1;
  reg         s1_req_isForVSnonLeafPTE_tmp_r;
  reg         s1_req_isForVSnonLeafPTE_tmp_r_1;
  reg  [1:0]  s1_itlb_exception_tmp_r;
  reg  [1:0]  s1_itlb_exception_tmp_r_1;
  reg  [1:0]  s1_itlb_pbmt_r;
  reg  [1:0]  s1_itlb_pbmt_r_1;

  reg         s1_SRAM_valid_REG;
  reg  [3:0]  s1_waymasks_r_0;
  reg  [3:0]  s1_waymasks_r_1;
  reg         s1_meta_codes_r_0;
  reg         s1_meta_codes_r_1;

  reg         s2_valid;
  reg  [49:0] s2_req_vaddr_0;
  reg  [49:0] s2_req_vaddr_1;
  reg         s2_isSoftPrefetch;
  reg         s2_doubleline;
  reg  [47:0] s2_req_paddr_0;
  reg  [47:0] s2_req_paddr_1;
  reg  [1:0]  s2_exception_0;
  reg  [1:0]  s2_exception_1;
  reg         s2_mmio_0;
  reg         s2_mmio_1;
  reg  [3:0]  s2_waymasks_0;
  reg  [3:0]  s2_waymasks_1;
  reg         s2_MSHR_hits_valid;
  reg         s2_MSHR_hits_valid_1;
  reg         has_send_0;
  reg         has_send_1;

  // ===========================================================================
  // s0 级：组合接收
  // ===========================================================================
  // BPU s2/s3 冲刷探测（软预取不受 BPU 冲刷影响）
  wire from_bpu_s0_flush_probe =
    ~io_req_bits_isSoftPrefetch
    & (io_flushFromBpu_s2_valid
       & (io_flushFromBpu_s2_bits_flag ^ io_req_bits_ftqIdx_flag
          ^ io_flushFromBpu_s2_bits_value <= io_req_bits_ftqIdx_value)
       | io_flushFromBpu_s3_valid
       & (io_flushFromBpu_s3_bits_flag ^ io_req_bits_ftqIdx_flag
          ^ io_flushFromBpu_s3_bits_value <= io_req_bits_ftqIdx_value));

  wire s0_can_go = s1_ready & io_metaRead_toIMeta_ready;
  wire s0_fire =
    io_req_valid & s0_can_go & ~(io_flush | from_bpu_s0_flush_probe | s1_flush);

  // ===========================================================================
  // s1 级：ITLB / IMeta
  // ===========================================================================
  // ITLB 重发需求与有效脉冲（端口 1 仅在 doubleline 时有效）
  wire s1_need_itlb_0 =
    (s1_need_itlb_REG | s1_wait_itlb_0) & io_itlb_0_resp_bits_miss;
  wire s1_need_itlb_1 =
    (s1_need_itlb_REG_1 | s1_wait_itlb_1) & io_itlb_1_resp_bits_miss & s1_doubleline;

  wire tlb_valid_pulse_0 =
    (tlb_valid_pulse_REG | s1_wait_itlb_0) & ~io_itlb_0_resp_bits_miss;
  wire tlb_valid_pulse_1 =
    (tlb_valid_pulse_REG_1 | s1_wait_itlb_1) & ~io_itlb_1_resp_bits_miss & s1_doubleline;

  wire itlb_finish =
    (tlb_valid_latch_valid | tlb_valid_pulse_0)
    & (~s1_doubleline | tlb_valid_latch_valid_1 | tlb_valid_pulse_1);

  // paddr：本拍 ITLB 命中用 resp，否则用已存值
  wire [47:0] s1_req_paddr_0 =
    tlb_valid_pulse_0 ? io_itlb_0_resp_bits_paddr_0 : s1_req_paddr_reg_r;
  wire [47:0] s1_req_paddr_1 =
    tlb_valid_pulse_1 ? io_itlb_1_resp_bits_paddr_0 : s1_req_paddr_reg_r_1;

  // ITLB 异常 one-hot → 编码（pf 优先 gpf 优先 af）
  wire [1:0] s1_itlb_exception_tmp_x9 =
    io_itlb_0_resp_bits_excp_0_pf_instr
      ? EXCP_PF
      : io_itlb_0_resp_bits_excp_0_gpf_instr
          ? EXCP_GPF
          : {2{io_itlb_0_resp_bits_excp_0_af_instr}};
  wire [1:0] s1_itlb_exception_tmp_x9_1 =
    io_itlb_1_resp_bits_excp_0_pf_instr
      ? EXCP_PF
      : io_itlb_1_resp_bits_excp_0_gpf_instr
          ? EXCP_GPF
          : {2{io_itlb_1_resp_bits_excp_0_af_instr}};

  wire [1:0] s1_itlb_exception_tmp_0 =
    tlb_valid_pulse_0 ? s1_itlb_exception_tmp_x9 : s1_itlb_exception_tmp_r;
  wire [1:0] s1_itlb_exception_tmp_1 =
    tlb_valid_pulse_1 ? s1_itlb_exception_tmp_x9_1 : s1_itlb_exception_tmp_r_1;
  wire [1:0] s1_itlb_pbmt_0 =
    tlb_valid_pulse_0 ? io_itlb_0_resp_bits_pbmt_0 : s1_itlb_pbmt_r;
  wire [1:0] s1_itlb_pbmt_1 =
    tlb_valid_pulse_1 ? io_itlb_1_resp_bits_pbmt_0 : s1_itlb_pbmt_r_1;

  // backendException 优先于 itlb 异常
  wire [1:0] s1_itlb_exception_0 =
    (|s1_backendException_0) ? s1_backendException_0 : s1_itlb_exception_tmp_0;
  wire [1:0] s1_itlb_exception_1 =
    (|s1_backendException_1) ? s1_backendException_1 : s1_itlb_exception_tmp_1;
  wire s1_itlb_exception_gpf_0 = s1_itlb_exception_0 == EXCP_GPF;
  wire s1_itlb_exception_gpf_1 = s1_itlb_exception_1 == EXCP_GPF;

  wire s1_need_meta = (state == M_ITLBRESEND & itlb_finish) | state == M_METARESEND;

  // IMeta 读出后比 ptag 算 waymask（命中 tag 且 entryValid）
  wire [3:0] s1_SRAM_waymasks_0 =
    tlb_valid_pulse_0
      ? {io_metaRead_fromIMeta_metas_0_3_tag == io_itlb_0_resp_bits_paddr_0[47:12]
           & io_metaRead_fromIMeta_entryValid_0_3,
         io_metaRead_fromIMeta_metas_0_2_tag == io_itlb_0_resp_bits_paddr_0[47:12]
           & io_metaRead_fromIMeta_entryValid_0_2,
         io_metaRead_fromIMeta_metas_0_1_tag == io_itlb_0_resp_bits_paddr_0[47:12]
           & io_metaRead_fromIMeta_entryValid_0_1,
         io_metaRead_fromIMeta_metas_0_0_tag == io_itlb_0_resp_bits_paddr_0[47:12]
           & io_metaRead_fromIMeta_entryValid_0_0}
      : {io_metaRead_fromIMeta_metas_0_3_tag == s1_req_paddr_reg_r[47:12]
           & io_metaRead_fromIMeta_entryValid_0_3,
         io_metaRead_fromIMeta_metas_0_2_tag == s1_req_paddr_reg_r[47:12]
           & io_metaRead_fromIMeta_entryValid_0_2,
         io_metaRead_fromIMeta_metas_0_1_tag == s1_req_paddr_reg_r[47:12]
           & io_metaRead_fromIMeta_entryValid_0_1,
         io_metaRead_fromIMeta_metas_0_0_tag == s1_req_paddr_reg_r[47:12]
           & io_metaRead_fromIMeta_entryValid_0_0};
  wire [3:0] s1_SRAM_waymasks_1 =
    tlb_valid_pulse_1
      ? {io_metaRead_fromIMeta_metas_1_3_tag == io_itlb_1_resp_bits_paddr_0[47:12]
           & io_metaRead_fromIMeta_entryValid_1_3,
         io_metaRead_fromIMeta_metas_1_2_tag == io_itlb_1_resp_bits_paddr_0[47:12]
           & io_metaRead_fromIMeta_entryValid_1_2,
         io_metaRead_fromIMeta_metas_1_1_tag == io_itlb_1_resp_bits_paddr_0[47:12]
           & io_metaRead_fromIMeta_entryValid_1_1,
         io_metaRead_fromIMeta_metas_1_0_tag == io_itlb_1_resp_bits_paddr_0[47:12]
           & io_metaRead_fromIMeta_entryValid_1_0}
      : {io_metaRead_fromIMeta_metas_1_3_tag == s1_req_paddr_reg_r_1[47:12]
           & io_metaRead_fromIMeta_entryValid_1_3,
         io_metaRead_fromIMeta_metas_1_2_tag == s1_req_paddr_reg_r_1[47:12]
           & io_metaRead_fromIMeta_entryValid_1_2,
         io_metaRead_fromIMeta_metas_1_1_tag == s1_req_paddr_reg_r_1[47:12]
           & io_metaRead_fromIMeta_entryValid_1_1,
         io_metaRead_fromIMeta_metas_1_0_tag == s1_req_paddr_reg_r_1[47:12]
           & io_metaRead_fromIMeta_entryValid_1_0};

  // 选中 way 的 meta ECC code（OR-reduce）
  wire s1_SRAM_meta_codes_0 =
    s1_SRAM_waymasks_0[0] & io_metaRead_fromIMeta_codes_0_0 | s1_SRAM_waymasks_0[1]
    & io_metaRead_fromIMeta_codes_0_1 | s1_SRAM_waymasks_0[2]
    & io_metaRead_fromIMeta_codes_0_2 | s1_SRAM_waymasks_0[3]
    & io_metaRead_fromIMeta_codes_0_3;
  wire s1_SRAM_meta_codes_1 =
    s1_SRAM_waymasks_1[0] & io_metaRead_fromIMeta_codes_1_0 | s1_SRAM_waymasks_1[1]
    & io_metaRead_fromIMeta_codes_1_1 | s1_SRAM_waymasks_1[2]
    & io_metaRead_fromIMeta_codes_1_2 | s1_SRAM_waymasks_1[3]
    & io_metaRead_fromIMeta_codes_1_3;

  wire s1_SRAM_valid = s0_fire_r | s1_SRAM_valid_REG;

  // MSHRResp 回填修正 waymask（updateMetaInfo）
  wire [3:0] old_waymask   = s1_SRAM_valid ? s1_SRAM_waymasks_0 : s1_waymasks_r_0;
  wire [3:0] old_waymask_1 = s1_SRAM_valid ? s1_SRAM_waymasks_1 : s1_waymasks_r_1;

  wire new_info_ptag_same   = io_MSHRResp_bits_blkPaddr[41:6] == s1_req_paddr_0[47:12];
  wire new_info_ptag_same_1 = io_MSHRResp_bits_blkPaddr[41:6] == s1_req_paddr_1[47:12];
  wire new_info_way_same    = io_MSHRResp_bits_waymask == old_waymask;
  wire new_info_way_same_1  = io_MSHRResp_bits_waymask == old_waymask_1;

  wire _new_info_T =
    io_MSHRResp_valid & ~io_MSHRResp_bits_corrupt
    & io_MSHRResp_bits_vSetIdx == s1_req_vaddr_0[13:6];
  wire _new_info_T_1 =
    io_MSHRResp_valid & ~io_MSHRResp_bits_corrupt
    & io_MSHRResp_bits_vSetIdx == s1_req_vaddr_1[13:6];

  wire _GEN   = _new_info_T   & new_info_ptag_same;    // 命中→需重算 meta code
  wire _GEN_0 = _new_info_T_1 & new_info_ptag_same_1;

  wire [3:0] new_info_1 =
    _new_info_T
      ? (new_info_ptag_same
           ? io_MSHRResp_bits_waymask
           : new_info_way_same ? 4'h0 : old_waymask)
      : old_waymask;
  wire [3:0] new_info_1_1 =
    _new_info_T_1
      ? (new_info_ptag_same_1
           ? io_MSHRResp_bits_waymask
           : new_info_way_same_1 ? 4'h0 : old_waymask_1)
      : old_waymask_1;

  // way 查询写出有效（enqWay 或 idle+itlb_finish，且非冲刷/非 MSHRResp 占用/非软预取）
  wire io_wayLookupWrite_valid_0 =
    (state == M_ENQWAY | ~(|state) & itlb_finish) & ~s1_flush & ~io_MSHRResp_valid
    & ~s1_isSoftPrefetch;
  wire _GEN_1 = io_wayLookupWrite_ready & io_wayLookupWrite_valid_0;

  // ---- 状态机次态 ----
  wire [2:0] next_state =
    s1_flush
      ? M_IDLE
      : (|state)
          ? (state == M_ITLBRESEND
               ? (itlb_finish ? {2'h1, io_metaRead_toIMeta_ready} : state)
               : state == M_METARESEND
                   ? (io_metaRead_toIMeta_ready ? M_ENQWAY : state)
                   : state == M_ENQWAY
                       ? (_GEN_1 | s1_isSoftPrefetch ? {~s2_ready, 2'h0} : state)
                       : state == M_ENQIPF & s2_ready ? M_IDLE : state)
          : s1_valid
              ? (itlb_finish ? (_GEN_1 ? (s2_ready ? state : M_ENQIPF) : M_ENQWAY) : M_ITLBRESEND)
              : state;

  wire from_bpu_s1_flush_probe =
    s1_valid & ~s1_isSoftPrefetch & io_flushFromBpu_s3_valid
    & (io_flushFromBpu_s3_bits_flag ^ s1_req_ftqIdx_flag
       ^ io_flushFromBpu_s3_bits_value <= s1_req_ftqIdx_value);
  assign s1_flush = io_flush | from_bpu_s1_flush_probe;
  assign s1_ready = next_state == M_IDLE;
  wire s1_fire = s1_ready & s1_valid & ~s1_flush;
  wire s1_real_fire = s1_fire & io_csr_pf_enable;
  wire _GEN_11 = s1_flush | s1_fire;

  // ===========================================================================
  // s2 级：PMP / MSHR
  // ===========================================================================
  wire s2_MSHR_match_0 =
    s2_req_vaddr_0[13:6] == io_MSHRResp_bits_vSetIdx
    & s2_req_paddr_0[47:12] == io_MSHRResp_bits_blkPaddr[41:6] & s2_valid
    & io_MSHRResp_valid & ~io_MSHRResp_bits_corrupt;
  wire s2_MSHR_match_1 =
    s2_req_vaddr_1[13:6] == io_MSHRResp_bits_vSetIdx
    & s2_req_paddr_1[47:12] == io_MSHRResp_bits_blkPaddr[41:6] & s2_valid
    & io_MSHRResp_valid & ~io_MSHRResp_bits_corrupt;

  wire s2_miss_0 =
    ~(s2_MSHR_hits_valid | s2_MSHR_match_0 | (|s2_waymasks_0)) & s2_exception_0 == EXCP_NONE
    & ~s2_mmio_0;
  wire s2_miss_1 =
    ~(s2_MSHR_hits_valid_1 | s2_MSHR_match_1 | (|s2_waymasks_1)) & s2_doubleline
    & ~((|s2_exception_0) | (|s2_exception_1)) & ~s2_mmio_0 & ~s2_mmio_1;

  wire _toMSHRArbiter_io_in_0_valid_T_2 = s2_valid & s2_miss_0 & ~has_send_0;
  wire _toMSHRArbiter_io_in_1_valid_T_2 = s2_valid & s2_miss_1 & ~has_send_1;

  // ---- 内联 Arbiter2_ICacheMissReq（端口 0 优先）----
  wire _toMSHRArbiter_io_in_0_ready = io_MSHRReq_ready;
  wire _toMSHRArbiter_io_in_1_ready = ~_toMSHRArbiter_io_in_0_valid_T_2 & io_MSHRReq_ready;
  wire _toMSHRArbiter_io_out_valid  =
    _toMSHRArbiter_io_in_0_valid_T_2 | _toMSHRArbiter_io_in_1_valid_T_2;

  wire s2_finish = (has_send_0 | ~s2_miss_0) & (has_send_1 | ~s2_miss_1);
  assign s2_ready = s2_finish | ~s2_valid;
  wire s2_fire = s2_valid & s2_finish & ~io_flush;
  wire _s2_MSHR_hits_T_1 = s2_fire | io_flush;

  // ===========================================================================
  // 时序逻辑
  // ===========================================================================
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      s1_valid <= 1'h0;
      s1_req_vaddr_0 <= 50'h0;
      s1_req_vaddr_1 <= 50'h0;
      s1_isSoftPrefetch <= 1'h0;
      s1_doubleline <= 1'h0;
      s1_req_ftqIdx_flag <= 1'h0;
      s1_req_ftqIdx_value <= 6'h0;
      s1_backendException_0 <= 2'h0;
      s1_backendException_1 <= 2'h0;
      state <= 3'h0;
      s1_wait_itlb_0 <= 1'h0;
      s1_wait_itlb_1 <= 1'h0;
      tlb_valid_latch_valid <= 1'h0;
      tlb_valid_latch_valid_1 <= 1'h0;
      s1_req_paddr_reg_r <= 48'h0;
      s1_req_paddr_reg_r_1 <= 48'h0;
      s1_req_gpaddr_tmp_r <= 56'h0;
      s1_req_gpaddr_tmp_r_1 <= 56'h0;
      s1_req_isForVSnonLeafPTE_tmp_r <= 1'h0;
      s1_req_isForVSnonLeafPTE_tmp_r_1 <= 1'h0;
      s1_itlb_exception_tmp_r <= 2'h0;
      s1_itlb_exception_tmp_r_1 <= 2'h0;
      s1_itlb_pbmt_r <= 2'h0;
      s1_itlb_pbmt_r_1 <= 2'h0;
      s1_waymasks_r_0 <= 4'h0;
      s1_waymasks_r_1 <= 4'h0;
      s1_meta_codes_r_0 <= 1'h0;
      s1_meta_codes_r_1 <= 1'h0;
      s2_valid <= 1'h0;
      s2_req_vaddr_0 <= 50'h0;
      s2_req_vaddr_1 <= 50'h0;
      s2_isSoftPrefetch <= 1'h0;
      s2_doubleline <= 1'h0;
      s2_req_paddr_0 <= 48'h0;
      s2_req_paddr_1 <= 48'h0;
      s2_exception_0 <= 2'h0;
      s2_exception_1 <= 2'h0;
      s2_mmio_0 <= 1'h0;
      s2_mmio_1 <= 1'h0;
      s2_waymasks_0 <= 4'h0;
      s2_waymasks_1 <= 4'h0;
      s2_MSHR_hits_valid <= 1'h0;
      s2_MSHR_hits_valid_1 <= 1'h0;
      has_send_0 <= 1'h0;
      has_send_1 <= 1'h0;
    end
    else begin
      // ---- s0 → s1 ----
      s1_valid <= ~s1_flush & (s0_fire | ~s1_fire & s1_valid);
      if (s0_fire) begin
        s1_req_vaddr_0 <= io_req_bits_startAddr;
        s1_req_vaddr_1 <= io_req_bits_nextlineStart;
        s1_isSoftPrefetch <= io_req_bits_isSoftPrefetch;
        s1_doubleline <= io_req_bits_startAddr[5];
        s1_req_ftqIdx_flag <= io_req_bits_ftqIdx_flag;
        s1_req_ftqIdx_value <= io_req_bits_ftqIdx_value;
        s1_backendException_0 <= io_req_bits_backendException;
        s1_backendException_1 <= io_req_bits_backendException;
      end

      state <= next_state;

      // ITLB 等待标志
      s1_wait_itlb_0 <=
        ~s1_flush
        & (REG & io_itlb_0_resp_bits_miss | ~(s1_wait_itlb_0 & ~io_itlb_0_resp_bits_miss)
           & s1_wait_itlb_0);
      s1_wait_itlb_1 <=
        ~s1_flush
        & (REG_1 & io_itlb_1_resp_bits_miss
           | ~(s1_wait_itlb_1 & ~io_itlb_1_resp_bits_miss) & s1_wait_itlb_1);

      tlb_valid_latch_valid   <= ~_GEN_11 & (tlb_valid_pulse_0 | tlb_valid_latch_valid);
      tlb_valid_latch_valid_1 <= ~_GEN_11 & (tlb_valid_pulse_1 | tlb_valid_latch_valid_1);

      // ITLB 命中时锁存 paddr/gpaddr/exception/pbmt
      if (tlb_valid_pulse_0) begin
        s1_req_paddr_reg_r <= io_itlb_0_resp_bits_paddr_0;
        s1_req_gpaddr_tmp_r <= io_itlb_0_resp_bits_gpaddr_0[55:0];
        s1_req_isForVSnonLeafPTE_tmp_r <= io_itlb_0_resp_bits_isForVSnonLeafPTE;
        s1_itlb_exception_tmp_r <= s1_itlb_exception_tmp_x9;
        s1_itlb_pbmt_r <= io_itlb_0_resp_bits_pbmt_0;
      end
      if (tlb_valid_pulse_1) begin
        s1_req_paddr_reg_r_1 <= io_itlb_1_resp_bits_paddr_0;
        s1_req_gpaddr_tmp_r_1 <= io_itlb_1_resp_bits_gpaddr_0[55:0];
        s1_req_isForVSnonLeafPTE_tmp_r_1 <= io_itlb_1_resp_bits_isForVSnonLeafPTE;
        s1_itlb_exception_tmp_r_1 <= s1_itlb_exception_tmp_x9_1;
        s1_itlb_pbmt_r_1 <= io_itlb_1_resp_bits_pbmt_0;
      end

      // waymask / meta_codes 锁存（含 MSHRResp 修正）
      if (s1_SRAM_valid | io_MSHRResp_valid & ~io_MSHRResp_bits_corrupt) begin
        if (_new_info_T) begin
          if (new_info_ptag_same)
            s1_waymasks_r_0 <= io_MSHRResp_bits_waymask;
          else if (new_info_way_same)
            s1_waymasks_r_0 <= 4'h0;
          else if (s1_SRAM_valid)
            s1_waymasks_r_0 <= s1_SRAM_waymasks_0;
        end
        else if (s1_SRAM_valid)
          s1_waymasks_r_0 <= s1_SRAM_waymasks_0;
        if (_new_info_T_1) begin
          if (new_info_ptag_same_1)
            s1_waymasks_r_1 <= io_MSHRResp_bits_waymask;
          else if (new_info_way_same_1)
            s1_waymasks_r_1 <= 4'h0;
          else if (s1_SRAM_valid)
            s1_waymasks_r_1 <= s1_SRAM_waymasks_1;
        end
        else if (s1_SRAM_valid)
          s1_waymasks_r_1 <= s1_SRAM_waymasks_1;
        if (_GEN)
          s1_meta_codes_r_0 <= ^(s1_req_paddr_0[47:12]);
        else if (s1_SRAM_valid)
          s1_meta_codes_r_0 <= s1_SRAM_meta_codes_0;
        if (_GEN_0)
          s1_meta_codes_r_1 <= ^(s1_req_paddr_1[47:12]);
        else if (s1_SRAM_valid)
          s1_meta_codes_r_1 <= s1_SRAM_meta_codes_1;
      end

      // ---- s1 → s2 ----
      s2_valid <= ~io_flush & (s1_real_fire | ~s2_fire & s2_valid);
      if (s1_real_fire) begin
        s2_req_vaddr_0 <= s1_req_vaddr_0;
        s2_req_vaddr_1 <= s1_req_vaddr_1;
        s2_isSoftPrefetch <= s1_isSoftPrefetch;
        s2_doubleline <= s1_doubleline;
        s2_req_paddr_0 <= s1_req_paddr_0;
        s2_req_paddr_1 <= s1_req_paddr_1;
        s2_exception_0 <=
          (|s1_itlb_exception_0) ? s1_itlb_exception_0 : {2{io_pmp_0_resp_instr}};
        s2_exception_1 <=
          (|s1_itlb_exception_1) ? s1_itlb_exception_1 : {2{io_pmp_1_resp_instr}};
        s2_mmio_0 <= io_pmp_0_resp_mmio | s1_itlb_pbmt_0 == 2'h1 | s1_itlb_pbmt_0 == 2'h2;
        s2_mmio_1 <= io_pmp_1_resp_mmio | s1_itlb_pbmt_1 == 2'h1 | s1_itlb_pbmt_1 == 2'h2;
        s2_waymasks_0 <= new_info_1;
        s2_waymasks_1 <= new_info_1_1;
      end

      s2_MSHR_hits_valid   <= ~_s2_MSHR_hits_T_1 & (s2_MSHR_match_0 | s2_MSHR_hits_valid);
      s2_MSHR_hits_valid_1 <= ~_s2_MSHR_hits_T_1 & (s2_MSHR_match_1 | s2_MSHR_hits_valid_1);

      has_send_0 <=
        ~s1_real_fire
        & (_toMSHRArbiter_io_in_0_ready & _toMSHRArbiter_io_in_0_valid_T_2 | has_send_0);
      has_send_1 <=
        ~s1_real_fire
        & (_toMSHRArbiter_io_in_1_ready & _toMSHRArbiter_io_in_1_valid_T_2 | has_send_1);
    end
  end

  // s0_fire 打拍副本（无复位，与 golden 的 always @(posedge clock) 一致）
  always @(posedge clock) begin
    s0_fire_r <= s0_fire;
    REG <= s0_fire;
    REG_1 <= s0_fire;
    s1_need_itlb_REG <= s0_fire;
    s1_need_itlb_REG_1 <= s0_fire;
    tlb_valid_pulse_REG <= s0_fire;
    tlb_valid_pulse_REG_1 <= s0_fire;
    s1_SRAM_valid_REG <= s1_need_meta & io_metaRead_toIMeta_ready;
  end

  // ===========================================================================
  // 输出
  // ===========================================================================
  assign io_req_ready = s0_can_go;

  assign io_itlb_0_req_valid = s1_need_itlb_0 | io_req_valid;
  assign io_itlb_0_req_bits_vaddr =
    s1_need_itlb_0 ? s1_req_vaddr_0 : io_req_bits_startAddr;
  assign io_itlb_1_req_valid = s1_need_itlb_1 | io_req_valid & io_req_bits_startAddr[5];
  assign io_itlb_1_req_bits_vaddr =
    s1_need_itlb_1 ? s1_req_vaddr_1 : io_req_bits_nextlineStart;
  assign io_itlbFlushPipe = s1_flush;

  assign io_pmp_0_req_bits_addr = s1_req_paddr_0;
  assign io_pmp_1_req_bits_addr = s1_req_paddr_1;

  assign io_metaRead_toIMeta_valid = s1_need_meta | io_req_valid;
  assign io_metaRead_toIMeta_bits_vSetIdx_0 =
    s1_need_meta ? s1_req_vaddr_0[13:6] : io_req_bits_startAddr[13:6];
  assign io_metaRead_toIMeta_bits_vSetIdx_1 =
    s1_need_meta ? s1_req_vaddr_1[13:6] : io_req_bits_nextlineStart[13:6];
  assign io_metaRead_toIMeta_bits_isDoubleLine =
    s1_need_meta ? s1_doubleline : io_req_bits_startAddr[5];

  // MSHR 请求（内联仲裁器输出）
  assign io_MSHRReq_valid = _toMSHRArbiter_io_out_valid;
  assign io_MSHRReq_bits_blkPaddr =
    _toMSHRArbiter_io_in_0_valid_T_2 ? s2_req_paddr_0[47:6] : s2_req_paddr_1[47:6];
  assign io_MSHRReq_bits_vSetIdx =
    _toMSHRArbiter_io_in_0_valid_T_2 ? s2_req_vaddr_0[13:6] : s2_req_vaddr_1[13:6];

  // WayLookup 写出
  assign io_wayLookupWrite_valid = io_wayLookupWrite_valid_0;
  assign io_wayLookupWrite_bits_entry_vSetIdx_0 = s1_req_vaddr_0[13:6];
  assign io_wayLookupWrite_bits_entry_vSetIdx_1 = s1_req_vaddr_1[13:6];
  assign io_wayLookupWrite_bits_entry_waymask_0 = new_info_1;
  assign io_wayLookupWrite_bits_entry_waymask_1 = new_info_1_1;
  assign io_wayLookupWrite_bits_entry_ptag_0 = s1_req_paddr_0[47:12];
  assign io_wayLookupWrite_bits_entry_ptag_1 = s1_req_paddr_1[47:12];
  assign io_wayLookupWrite_bits_entry_itlb_exception_0 = s1_itlb_exception_0;
  assign io_wayLookupWrite_bits_entry_itlb_exception_1 =
    s1_doubleline ? s1_itlb_exception_1 : 2'h0;
  assign io_wayLookupWrite_bits_entry_itlb_pbmt_0 = s1_itlb_pbmt_0;
  assign io_wayLookupWrite_bits_entry_itlb_pbmt_1 = s1_doubleline ? s1_itlb_pbmt_1 : 2'h0;
  assign io_wayLookupWrite_bits_entry_meta_codes_0 =
    _GEN
      ? ^(s1_req_paddr_0[47:12])
      : s1_SRAM_valid ? s1_SRAM_meta_codes_0 : s1_meta_codes_r_0;
  assign io_wayLookupWrite_bits_entry_meta_codes_1 =
    _GEN_0
      ? ^(s1_req_paddr_1[47:12])
      : s1_SRAM_valid ? s1_SRAM_meta_codes_1 : s1_meta_codes_r_1;
  // gpf gpaddr：port0 gpf 用 port0；否则 port1 gpf 用 (port1 gpaddr - blockBytes=0x40)
  assign io_wayLookupWrite_bits_gpf_gpaddr =
    s1_itlb_exception_gpf_0
      ? (tlb_valid_pulse_0 ? io_itlb_0_resp_bits_gpaddr_0[55:0] : s1_req_gpaddr_tmp_r)
      : s1_itlb_exception_gpf_1
          ? 56'((tlb_valid_pulse_1
                   ? io_itlb_1_resp_bits_gpaddr_0[55:0]
                   : s1_req_gpaddr_tmp_r_1) - 56'h40)
          : 56'h0;
  assign io_wayLookupWrite_bits_gpf_isForVSnonLeafPTE =
    s1_itlb_exception_gpf_0
      ? (tlb_valid_pulse_0
           ? io_itlb_0_resp_bits_isForVSnonLeafPTE
           : s1_req_isForVSnonLeafPTE_tmp_r)
      : s1_itlb_exception_gpf_1
        & (tlb_valid_pulse_1
             ? io_itlb_1_resp_bits_isForVSnonLeafPTE
             : s1_req_isForVSnonLeafPTE_tmp_r_1);

endmodule
