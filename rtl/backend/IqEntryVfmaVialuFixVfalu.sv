// =============================================================================
// xs_iq_entry_vfmavialufixvfalu —— 香山 V2R2(昆明湖) 发射队列「单条目」可读重写
//                                  (VfmaVialuFixVfalu 变体)
// -----------------------------------------------------------------------------
// 设计源:src/main/scala/xiangshan/backend/issue/{EntryBundles,EnqEntry,OthersEntry}.scala
// golden 对照:EnqEntry_16.sv(入队条目) / OthersEntry_150.sv(简单条目, 转移源)
//             / OthersEntry_152.sv(复杂条目, 终端)
//
// ★ 本条目 = VfdivVidiv 单条目 + 两处多 FU 增量(见 pkg 注释)★
//   增量1:deq_port_idx 状态(numDeq=2)。条目记录自己被哪个 deq 端口选中:
//          deqSel 当拍 → 锁存 deqPortIdxWrite;之后只要还 issued 就保持;否则清 0。
//          输出 o_deq_port_idx_read 给阵列做 issueResp 路由(选 og*Resp_0 还是 _1)。
//          ★ issueResp 本身在阵列层按 deqPortIdxRead 选好后再喂进来,本条目只看单个 resp ★。
//   增量2:payload 多带 fpWen / lastUop / vpu.fpu.isFoldTo1_{2,4,8}(仅寄存透传)。
// 其余(唤醒分组 / ignoreOldVd / issued / issueTimer / 转移 / 入队延迟)与 VfdivVidiv 逐字相同。
//
// 三种条目变体由参数选择:
//   IS_ENQ=1            入队条目(EnqEntry):新 uop 落点,带 1 拍入队延迟唤醒(enqDelayIn1)。
//   IS_ENQ=0,IS_TRANS=1 简单条目(OthersEntry simp):有 transSel/transEntry(可被提级到 comp)。
//   IS_ENQ=0,IS_TRANS=0 复杂条目(OthersEntry comp):终端条目。
//
// X 铁律:三元 mux / 全源就绪用 & 归约;唤醒匹配纯组合;状态全在 entry_reg(综合下复位无关,
//   firtool 随机初始化)。UT 用 !$isunknown 跳过未写过的条目。
// =============================================================================
module xs_iq_entry_vfmavialufixvfalu import iq_vfmavialufixvfalu_pkg::*; #(
  parameter bit IS_ENQ   = 1'b0, // 入队条目(带 enqDelay)
  parameter bit IS_TRANS = 1'b0  // 是否可转移(simp 条目:有 transSel/transEntry)
) (
  input  logic                         clock,
  input  logic                         reset,

  // ---- 冲刷 / 入队 ----
  input  logic                         flush_valid,
  input  logic                         flush_rob_flag,
  input  logic [ROB_PTR_W-1:0]         flush_rob_value,
  input  logic                         flush_level,
  input  logic                         enq_valid,
  input  entry_t                       enq_bits,

  // ---- WB 唤醒(当拍)----
  input  wk_wb_t [NUM_WK_WB-1:0]       wk_wb,

  // ---- 入队延迟唤醒(仅 IS_ENQ 用):同一总线打 1 拍 ----
  input  wk_wb_t [NUM_WK_WB-1:0]       wk_wb_d1,

  // ---- vl 零/最大信息(ignoreOldVd 判定)----
  input  vl_info_t                     vl_info,

  // ---- 发射选择 / 响应 / 转移 ----
  input  logic                         deq_sel,            // 任一 deq 端口选中
  input  logic                         deq_port_idx_write, // 选中端口号(端口1=1, 端口0=0)
  input  deq_resp_t                    issue_resp,         // 阵列按本条目 deqPortIdx 选好的响应
  input  logic                         trans_sel,

  // ---- 状态输出 ----
  output logic                         o_valid,
  output logic                         o_issued,
  output logic                         o_can_issue,
  output logic [FU_NUM-1:0]            o_fu_type,
  output logic [NUM_REGSRC-1:0][3:0]   o_data_src,         // dataSources[src].value
  output entry_t                       o_entry,            // commonOut.entry.bits
  output logic [1:0]                   o_issue_timer_read,
  output logic                         o_deq_port_idx_read,// commonOut.deqPortIdxRead
  output logic                         o_enq_ready,
  output logic                         o_trans_valid,
  output entry_t                       o_trans_entry       // commonOut.transEntry.bits(=entry_update)
);

  // ===========================================================================
  // 0. 寄存器:条目本体 + valid。入队延迟窗口标志(仅 IS_ENQ)。
  // ===========================================================================
  entry_t entry_reg;
  logic   valid_reg;
  logic   enqd_valid_reg;

  status_t current_status; // EnqEntry 在 enqd 窗口用延迟唤醒覆盖;其余取 entry_reg.status

  // ===========================================================================
  // 1. 冲刷判定 flushed:本条目 robIdx 是否落在被冲刷区间(环形指针比较)。
  // ===========================================================================
  logic flushed;
  always_comb begin
    logic gt;
    gt = (entry_reg.status.rob_flag ^ flush_rob_flag) ^
         (entry_reg.status.rob_value > flush_rob_value);
    flushed = flush_valid & ((flush_level &
                ({entry_reg.status.rob_flag, entry_reg.status.rob_value} ==
                 {flush_rob_flag, flush_rob_value})) | gt);
  end

  // ===========================================================================
  // 2. ★ 向量唤醒匹配 ★:按源 index 选「组 + srcType 门控位 + 写使能含义」。
  //    src0/1/2 → vec 组 WB[0..5],srcType[2],wen=vecWen
  //    src3     → v0  组 WB[6..11],srcType[3],wen=v0Wen
  //    src4     → vl  组 WB[12..15],srcType[2],wen=vlWen
  //    命中条件:pdest==psrc & 对应 srcType 位 & wen & valid。
  //    (psrc 7 位,WB.pdest 8 位:golden 把 psrc 零扩到 8 位再比较。)
  // ===========================================================================
  function automatic logic wb_hit(input wk_wb_t w, input src_status_t s, input logic type_bit);
    return ({1'b0, s.psrc} == w.pdest) & type_bit & w.wen & w.valid;
  endfunction

  // 某源 s 对一组 WB(lo..hi)的命中位。
  function automatic logic group_hit(
      input wk_wb_t [NUM_WK_WB-1:0] bus,
      input src_status_t s, input logic type_bit, input int lo, input int hi);
    logic h;
    h = 1'b0;
    for (int i = lo; i <= hi; i++) h |= wb_hit(bus[i], s, type_bit);
    return h;
  endfunction

  // wb_hit_now[s]:源 s 本拍被「当拍 WB 总线」唤醒命中(纯匹配,对 entry_reg)。
  logic [NUM_REGSRC-1:0] wb_hit_now;
  always_comb begin
    src_status_t s0, s1, s2, s3, s4;
    s0 = entry_reg.status.src[0];
    s1 = entry_reg.status.src[1];
    s2 = entry_reg.status.src[2];
    s3 = entry_reg.status.src[3];
    s4 = entry_reg.status.src[4];
    wb_hit_now[0] = group_hit(wk_wb, s0, s0.src_type[2], WB_VEC_LO, WB_VEC_HI);
    wb_hit_now[1] = group_hit(wk_wb, s1, s1.src_type[2], WB_VEC_LO, WB_VEC_HI);
    wb_hit_now[2] = group_hit(wk_wb, s2, s2.src_type[2], WB_VEC_LO, WB_VEC_HI);
    wb_hit_now[3] = group_hit(wk_wb, s3, s3.src_type[3], WB_V0_LO,  WB_V0_HI);
    wb_hit_now[4] = group_hit(wk_wb, s4, s4.src_type[2], WB_VL_LO,  WB_VL_HI);
  end

  // ===========================================================================
  // 3. ★ ignoreOldVd(向量专属,仅 src2=旧 vd)★(与 VfdivVidiv 逐字相同)
  //    本拍 src4(vl)被 WB[12](Int 来源)/WB[13](Vf 来源)命中即 wakeUpFromVl。
  //    触发 → src2 直接就绪 + srcType 清 0 + dataSources=IMM(旧 vd 不必再等)。
  // ===========================================================================
  logic wakeup_vl_int; // src4 被 Int 来源的 vl 写回唤醒(WB[12])
  logic wakeup_vl_vf;  // src4 被 Vf  来源的 vl 写回唤醒(WB[13])
  logic ignore_old_vd2;
  always_comb begin
    src_status_t s4, s2;
    s4 = entry_reg.status.src[4];
    s2 = entry_reg.status.src[2];
    wakeup_vl_int = wb_hit(wk_wb[12], s4, s4.src_type[2]);
    wakeup_vl_vf  = wb_hit(wk_wb[13], s4, s4.src_type[2]);
    ignore_old_vd2 =
      s2.src_type[2]
      & ((~vl_info.int_is_zero & wakeup_vl_int) | (~vl_info.vf_is_zero & wakeup_vl_vf))
      & ~entry_reg.payload.vpu.is_depend_old_vd
      & (((vl_info.int_is_vlmax & wakeup_vl_int) | (vl_info.vf_is_vlmax & wakeup_vl_vf))
            & (entry_reg.payload.vpu.vm | entry_reg.payload.vpu.vma)
            & ~entry_reg.payload.vpu.is_write_part_vd
         | (entry_reg.payload.vpu.vm | entry_reg.payload.vpu.vma) & entry_reg.payload.vpu.vta);
  end

  // ===========================================================================
  // 4. 公共控制信号
  // ===========================================================================
  logic deq_success, enq_ready, clear, valid_reg_next;
  logic trans_clear; // = flushed | deqSuccess(simp transValid 与 deqValid 共用)
  always_comb begin
    deq_success = issue_resp.valid & (issue_resp.resp == RESP_SUCCESS);
    enq_ready   = ~valid_reg | trans_sel;
    trans_clear = flushed | deq_success;
    clear = trans_clear | trans_sel;
    valid_reg_next = (IS_ENQ ? (enq_valid & enq_ready)
                             : enq_valid) ? 1'b1 : (clear ? 1'b0 : valid_reg);
  end

  // ===========================================================================
  // 5. entry_update:条目下一拍状态(未入队时)= EntryRegCommonConnect。
  // ===========================================================================
  entry_t entry_update;
  always_comb begin
    entry_update = entry_reg;
    // fuType 只保留本变体功能位(IQFuType.readFuType)
    entry_update.status.fu_type_vialuf = entry_reg.status.fu_type_vialuf;
    entry_update.status.fu_type_vfalu  = entry_reg.status.fu_type_vfalu;
    entry_update.status.fu_type_vfma   = entry_reg.status.fu_type_vfma;

    for (int s = 0; s < NUM_REGSRC; s++) begin
      // srcState:被 WB 唤醒置就绪;src2 还可被 ignoreOldVd 置就绪。
      entry_update.status.src[s].src_state = src_state_e'(
        current_status.src[s].src_state | wb_hit_now[s]
        | ((s == 2) ? ignore_old_vd2 : 1'b0));
      // srcType:仅 src2 在 ignoreOldVd 时清 0(不再当向量源);其余保持。
      entry_update.status.src[s].src_type =
        ((s == 2) & ignore_old_vd2) ? 4'h0 : current_status.src[s].src_type;
      entry_update.status.src[s].psrc = current_status.src[s].psrc;
      // dataSources:src2 ignoreOldVd → IMM;否则 BYPASS(2)→REG(8);其余保持。
      if ((s == 2) & ignore_old_vd2)
        entry_update.status.src[s].data_src = DS_IMM;
      else if (current_status.src[s].data_src == DS_BYPASS)
        entry_update.status.src[s].data_src = DS_REG;
      else
        entry_update.status.src[s].data_src = current_status.src[s].data_src;
    end

    // issued:置位=deqSel;保持=~(resp==BLOCK) & 当前 issued。
    entry_update.status.issued =
      deq_sel | (~(issue_resp.valid & (issue_resp.resp == RESP_BLOCK)) & entry_reg.status.issued);
    // issueTimer:发射当拍清 0;已发射 0→1→2→3 饱和;未发射置 3(b11)。
    if (deq_sel)
      entry_update.status.issue_timer = 2'h0;
    else if (entry_reg.status.issued)
      entry_update.status.issue_timer =
        (entry_reg.status.issue_timer == 2'h3) ? entry_reg.status.issue_timer
                                               : (entry_reg.status.issue_timer + 2'h1);
    else
      entry_update.status.issue_timer = 2'h3;

    // ★ deqPortIdx:发射当拍锁存被选端口号;之后只要还 issued 就保持;否则清 0 ★
    entry_update.status.deq_port_idx =
      deq_sel ? deq_port_idx_write
              : (entry_reg.status.issued & entry_reg.status.deq_port_idx);

    entry_update.payload = entry_reg.payload;
  end

  // ===========================================================================
  // 6. 时序:valid_reg。
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) valid_reg <= 1'b0;
    else       valid_reg <= valid_reg_next;
  end

  // 入队装载:EnqEntry 强制 issued=0 / issueTimer=3 / deqPortIdx=0(新 uop 从未发射过);
  //           OthersEntry 直接取 enq.bits(来自 transEntry,含 issued/issueTimer/deqPortIdx)。
  entry_t enq_load;
  always_comb begin
    enq_load = enq_bits;
    if (IS_ENQ) begin
      enq_load.status.issued       = 1'b0;
      enq_load.status.issue_timer  = 2'h3;
      enq_load.status.deq_port_idx = 1'b0;
    end
  end

  logic load_now; // 本拍执行入队装载
  always_comb load_now = IS_ENQ ? (enq_valid & enq_ready) : enq_valid;

  always_ff @(posedge clock) begin
    if (load_now) entry_reg <= enq_load;
    else          entry_reg <= entry_update;
  end

  // ===========================================================================
  // 7. 入队延迟唤醒(仅 IS_ENQ):入队后下一拍用 enqDelayIn1 总线再唤醒一次,
  //    覆盖 current_status 的 srcState(仅 srcState;dataSources/srcType 不在 delay 路改)。
  // ===========================================================================
  generate
  if (IS_ENQ) begin : g_enq_delay
    logic enqd_valid_reg_next;
    always_comb enqd_valid_reg_next = enq_valid & enq_ready;
    always_ff @(posedge clock or posedge reset) begin
      if (reset) enqd_valid_reg <= 1'b0;
      else       enqd_valid_reg <= enqd_valid_reg_next;
    end

    logic [NUM_REGSRC-1:0] d1_hit;
    always_comb begin
      src_status_t s0, s1, s2, s3, s4;
      s0 = entry_reg.status.src[0]; s1 = entry_reg.status.src[1];
      s2 = entry_reg.status.src[2]; s3 = entry_reg.status.src[3];
      s4 = entry_reg.status.src[4];
      d1_hit[0] = group_hit(wk_wb_d1, s0, s0.src_type[2], WB_VEC_LO, WB_VEC_HI);
      d1_hit[1] = group_hit(wk_wb_d1, s1, s1.src_type[2], WB_VEC_LO, WB_VEC_HI);
      d1_hit[2] = group_hit(wk_wb_d1, s2, s2.src_type[2], WB_VEC_LO, WB_VEC_HI);
      d1_hit[3] = group_hit(wk_wb_d1, s3, s3.src_type[3], WB_V0_LO,  WB_V0_HI);
      d1_hit[4] = group_hit(wk_wb_d1, s4, s4.src_type[2], WB_VL_LO,  WB_VL_HI);
    end

    always_comb begin
      current_status = entry_reg.status;
      for (int s = 0; s < NUM_REGSRC; s++)
        current_status.src[s].src_state = src_state_e'(
          (enqd_valid_reg & d1_hit[s]) | entry_reg.status.src[s].src_state);
    end
  end else begin : g_others_status
    always_comb begin
      current_status = entry_reg.status;
      enqd_valid_reg = 1'b0; // OthersEntry 无此寄存器(占位避免 X)
    end
  end
  endgenerate

  // ===========================================================================
  // 8. 组合输出
  // ===========================================================================
  assign o_valid             = valid_reg;
  assign o_issued            = entry_reg.status.issued;
  assign o_enq_ready         = enq_ready;
  assign o_issue_timer_read  = entry_reg.status.issue_timer;
  assign o_deq_port_idx_read = entry_reg.status.deq_port_idx;

  // canIssue:全源就绪 & 未发射 & 未冲刷。本变体 comp 与 simp 同构(无 bypass)。
  logic all_src_rdy;
  always_comb begin
    all_src_rdy = 1'b1;
    for (int s = 0; s < NUM_REGSRC; s++)
      all_src_rdy &= (IS_ENQ ? current_status.src[s].src_state
                             : entry_reg.status.src[s].src_state);
  end
  assign o_can_issue = valid_reg & all_src_rdy & ~entry_reg.status.issued & ~flushed;

  // fuType 输出(仅本变体功能位)
  always_comb begin
    o_fu_type = '0;
    o_fu_type[FU_VIALUF] = entry_reg.status.fu_type_vialuf;
    o_fu_type[FU_VFALU]  = entry_reg.status.fu_type_vfalu;
    o_fu_type[FU_VFMA]   = entry_reg.status.fu_type_vfma;
  end

  // dataSources 输出:直接取寄存值(无 IQ 即时前递)。
  always_comb
    for (int s = 0; s < NUM_REGSRC; s++)
      o_data_src[s] = entry_reg.status.src[s].data_src;

  // o_entry:commonOut.entry.bits = entry_reg(EnqEntry 用 current_status 覆盖 status)。
  always_comb begin
    o_entry = entry_reg;
    if (IS_ENQ) o_entry.status = current_status;
  end

  // transEntry:出队转移携带的「更新后」条目 = entry_update。
  assign o_trans_valid  = valid_reg & ~flushed & ~entry_reg.status.issued;
  always_comb o_trans_entry = entry_update;

endmodule
