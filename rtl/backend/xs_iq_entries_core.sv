// =============================================================================
// xs_iq_entries_core.sv —— 发射队列「条目阵列」参数化可读核(Entries* 家族共享核体)
// -----------------------------------------------------------------------------
// 设计源:XiangShan src/main/scala/xiangshan/backend/issue/{Entries,EntryBundles,
//        EnqEntry,OthersEntry,EnqPolicy}.scala
// golden 对照:Entries<变体>.sv —— golden 把这四个 Scala 文件展平成
//        「Entries 壳 + N×EnqEntry + N×OthersEntry(simp) + N×OthersEntry(comp)
//          + 2×EnqPolicy」的层次。EnqEntry/OthersEntry/EnqPolicy 都不是独立签核
//        目标,所以本核把它们一起吃进来(扁平重写),不做黑盒。
//
// ★ 这是乱序后端的调度心脏 ★
// 每条等待发射的 uop 占一个「条目」。条目每拍监听写回(WB)唤醒总线,把命中的源置就绪;
// 「全源就绪 && 未发射 && 未阻塞 && 未冲刷」即 canIssue。上层 IssueQueue 在 canIssue
// 的条目里按年龄选最老的发射,把 one-hot 从 deqSelOH 送回来。
//
// 条目分三类(索引顺序 = golden 的 entries 向量顺序):
//   [0 .. NUM_ENQ-1]                      enq   入队条目:派遣新 uop 的落点,
//                                               带 1 拍「入队延迟唤醒」窗口。
//   [NUM_ENQ .. +NUM_SIMP-1]              simp  简单条目:enq 溢出后的暂存,可被提级。
//   [NUM_ENQ+NUM_SIMP .. +NUM_COMP-1]     comp  复杂条目:终端,发射从这里走。
// uop 生命周期: enq --(转移策略)--> simp --(提级)--> comp --(发射)--> 清空
//               enq --(comp 有空且 simp 全空时直接)--> comp
//
// ★ 本核实现的是 hasCompAndSimp 分支(numSimp>0 && numComp>0)。★
//   Entries.scala 另有 isAllComp/isAllSimp 分支(othersTransPolicy 单策略),
//   14 个 G1 变体全部走 hasCompAndSimp,故本核不实现另一分支(见文件尾 §11 待办)。
//
// =============================================================================
// 本文件导航（共 1095 行；按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   L51    §1 与变体无关的编码
//   L73    §2 xs_iq_entry —— 单条目
//   L232   §2.1 冲刷判定
//   L244   §2.2 WB 唤醒匹配
//   L272   §2.3 ignoreOldVd(向量专属)
//   L307   §2.4 valid / enqReady / clear
//   L322   §2.5 entryUpdate —— 不装载时条目的次态,同时也是 transEntry 的内容
//   L365   §2.6 时序
//   L434   §2.7 组合输出
//   L482   §3 xs_iq_entries_core —— 条目阵列顶层(golden Entries<变体> 的可读核体)
//   L595   §4 条目例化
//   L720   §5 deqSel / deqPortIdxWrite / issueResp
//   L760   §6 EnqPolicy —— golden 的 EnqPolicy 模块(SelectOne("circ", …, 2))
//   L791   §7 转移策略
//   L868   §8 othersEntryEnq 数据通路
//   L993   §9 发射出口
//   L1042  §10 阵列状态汇聚输出
//   L1072  §11 本核尚未实现的家族维度(给后续变体 owner 的清单,全部有 golden 依据)
//

// -----------------------------------------------------------------------------
// §1 与变体无关的编码。变体相关的尺寸全部走 parameter,故本包很薄。
// -----------------------------------------------------------------------------
package iq_entries_pkg;

  // 源就绪状态 SrcState(EntryBundles.SrcState)
  localparam logic SRC_BUSY = 1'b0;
  localparam logic SRC_RDY  = 1'b1;

  // 数据来源 DataSource(4 bit, object DataSource)。本核只在三处改写它:
  //   ignoreOldVd → IMM;readBypass(=2) → REG(=8);其余保持入队值。
  localparam logic [3:0] DS_BYPASS = 4'd2;  // 旁路:下一拍数据落到寄存器堆
  localparam logic [3:0] DS_IMM    = 4'd4;  // 无源/立即(ignoreOldVd 后的旧 vd)
  localparam logic [3:0] DS_REG    = 4'd8;  // 物理寄存器堆

  // 发射响应 RespType(object RespType)
  localparam logic [1:0] RESP_BLOCK     = 2'b00; // 被阻塞:退回未发射
  localparam logic [1:0] RESP_UNCERTAIN = 2'b01; // 未定:保持 issued
  localparam logic [1:0] RESP_SUCCESS   = 2'b11; // 成功:清空条目

endpackage : iq_entries_pkg

// =============================================================================
// §2 xs_iq_entry —— 单条目。golden 的 EnqEntry / OthersEntry(simp) /
//    OthersEntry(comp) 三个模块在 Scala 里本就共用 EntryBundles 的
//    CommonWireConnect / EntryRegCommonConnect / CommonOutConnect,
//    差别只有三处,这里用两个参数表达:
//      IS_ENQ=1  : 入队条目。装载条件带 enqReady;装载时强制 issued=0/
//                  issueTimer=3/firstIssue=0;多一拍「入队延迟唤醒」窗口。
//      IS_TRANS=1: 可被转移走(simp)。有 trans_sel 输入。
//      两者皆 0  : comp 终端条目。
//    「是否产出 transEntry」= IS_ENQ | IS_TRANS,记作 KEEP_WIDE:
//    这类条目要把整包 uop 交给下一级,所以负载存 PL_TRANS_W 位;
//    comp 只需喂发射口,存 PL_DEQ_W 位(golden firtool 也正是这么剪的)。
// =============================================================================
module xs_iq_entry
  import iq_entries_pkg::*;
#(
  parameter bit IS_ENQ   = 1'b0,
  parameter bit IS_TRANS = 1'b0,

  parameter int NUM_REGSRC = 5,   // 每 uop 的源寄存器数
  parameter int NUM_WK_WB  = 16,  // 写回唤醒总线路数
  parameter int NUM_FU_BIT = 2,   // 本变体保留的 FuType one-hot 位数
  parameter int ROB_W      = 8,   // RobPtr.value 宽度
  parameter int PSRC_W     = 7,   // srcStatus.psrc 宽度
  parameter int PDEST_W    = 8,   // 唤醒总线 pdest 宽度
  parameter int PL_DEQ_W   = 1,   // 发射口可见的负载位宽
  parameter int PL_TRANS_W = 1,   // 转移包携带的负载位宽(>= PL_DEQ_W,低位即 DEQ 部分)

  // 投机 load 唤醒的依赖影子(EntryBundles.SrcStatus.srcLoadDependency)。
  // 每源 LD_PIPES 条 load 流水各一个 LD_DEP_W 位的移位影子,次态 = 本值左移 1。
  // ★ 只有产出 transEntry 的条目(enq/simp)存它;comp 的入口不带这些位(与 golden 同)。
  //   本变体(VfdivVidiv)没有 ldCancel,整条影子恒 0、够不到任何输出 —— 这里实现它
  //   纯粹是为了和 golden 的寄存器结构对齐(否则 FM 会多出一堆 ref-only 比较点)。
  //   有 ldCancel 的变体还要接上 LoadShouldCancel,见文件尾 §11(a)/(b)。
  parameter bit HAS_LD_DEP = 1'b0,
  parameter int LD_PIPES   = 1,
  parameter int LD_DEP_W   = 1,

  // 唤醒路由表:src s 只监听 SRC_WB_MASK[s] 里置 1 的那几路 WB,
  // 且要求 srcType[SRC_TYPE_BIT[s]] 为 1(源类型匹配)。
  parameter logic [NUM_REGSRC-1:0][NUM_WK_WB-1:0] SRC_WB_MASK  = '0,
  parameter logic [NUM_REGSRC-1:0][2:0]           SRC_TYPE_BIT = '0,

  // 向量 ignoreOldVd(§2.3)。非向量变体置 0。
  parameter bit HAS_IGNORE_OLD_VD = 1'b0,
  parameter int VD_SRC   = 2,   // 旧 vd 所在的源序号
  parameter int VL_SRC   = 4,   // vl 所在的源序号
  parameter int WB_VL_INT = 12, // vl 由整数域写回的那一路
  parameter int WB_VL_VF  = 13, // vl 由向量域写回的那一路
  // ignoreOldVd 要读的 6 个 vpu 控制位在 DEQ 负载里的比特位置
  parameter int PLB_VM              = 0,
  parameter int PLB_VMA             = 0,
  parameter int PLB_VTA             = 0,
  parameter int PLB_IS_DEPEND_OLDVD = 0,
  parameter int PLB_IS_WRITE_PARTVD = 0
) (
  input  logic clock,
  input  logic reset,

  // 冲刷
  input  logic              flush_valid,
  input  logic              flush_rob_flag,
  input  logic [ROB_W-1:0]  flush_rob_value,
  input  logic              flush_level,

  // 入队(enq 条目来自派遣;simp/comp 条目来自上一级的 transEntry)
  input  logic                        enq_valid,
  input  logic                        enq_rob_flag,
  input  logic [ROB_W-1:0]            enq_rob_value,
  input  logic [NUM_FU_BIT-1:0]       enq_fu_type,
  input  logic [NUM_REGSRC-1:0][PSRC_W-1:0] enq_psrc,
  input  logic [NUM_REGSRC-1:0][3:0]  enq_src_type,
  input  logic [NUM_REGSRC-1:0]       enq_src_state,
  input  logic [NUM_REGSRC-1:0][3:0]  enq_data_src,
  input  logic                        enq_blocked,
  input  logic                        enq_issued,
  input  logic                        enq_first_issue,
  input  logic [1:0]                  enq_issue_timer,
  input  logic                        enq_deq_port_idx,
  input  logic [PL_TRANS_W-1:0]       enq_payload,
  input  logic [NUM_REGSRC-1:0][LD_PIPES-1:0][LD_DEP_W-1:0] enq_ld_dep,

  // 唤醒总线:当拍 + 入队延迟 1 拍(后者只有 IS_ENQ 用)
  input  logic [NUM_WK_WB-1:0]              wk_valid,
  input  logic [NUM_WK_WB-1:0]              wk_wen,
  input  logic [NUM_WK_WB-1:0][PDEST_W-1:0] wk_pdest,
  input  logic [NUM_WK_WB-1:0]              wkd_valid,
  input  logic [NUM_WK_WB-1:0]              wkd_wen,
  input  logic [NUM_WK_WB-1:0][PDEST_W-1:0] wkd_pdest,

  // vl 的零 / 满长信息(ignoreOldVd 判定用)
  input  logic vl_int_is_zero,
  input  logic vl_int_is_vlmax,
  input  logic vl_vf_is_zero,
  input  logic vl_vf_is_vlmax,

  // 发射选择 / 响应 / 转移
  input  logic       deq_sel,
  input  logic       deq_port_idx_write,
  input  logic       resp_valid,
  input  logic [1:0] resp_bits,
  input  logic       trans_sel,

  // 状态输出(给阵列汇聚 / 上层年龄选择)
  output logic                       o_valid,
  output logic                       o_issued,
  output logic                       o_can_issue,
  output logic                       o_is_first_issue,
  output logic [NUM_FU_BIT-1:0]      o_fu_type,
  output logic [NUM_REGSRC-1:0][3:0] o_data_src,
  output logic [1:0]                 o_issue_timer,
  output logic                       o_deq_port_idx,
  output logic                       o_enq_ready,

  // commonOut.entry:发射口看到的那份(状态只露 robIdx/fuType/psrc/srcType)
  output logic                              o_ety_rob_flag,
  output logic [ROB_W-1:0]                  o_ety_rob_value,
  output logic [NUM_REGSRC-1:0][PSRC_W-1:0] o_ety_psrc,
  output logic [NUM_REGSRC-1:0][3:0]        o_ety_src_type,
  output logic [PL_DEQ_W-1:0]               o_ety_payload,

  // commonOut.transEntry:交给下一级的整包(= entryUpdate)
  output logic                              o_trans_valid,
  output logic                              o_trans_rob_flag,
  output logic [ROB_W-1:0]                  o_trans_rob_value,
  output logic [NUM_FU_BIT-1:0]             o_trans_fu_type,
  output logic [NUM_REGSRC-1:0][PSRC_W-1:0] o_trans_psrc,
  output logic [NUM_REGSRC-1:0][3:0]        o_trans_src_type,
  output logic [NUM_REGSRC-1:0]             o_trans_src_state,
  output logic [NUM_REGSRC-1:0][3:0]        o_trans_data_src,
  output logic                              o_trans_blocked,
  output logic                              o_trans_issued,
  output logic                              o_trans_first_issue,
  output logic [1:0]                        o_trans_issue_timer,
  output logic                              o_trans_deq_port_idx,
  output logic [PL_TRANS_W-1:0]             o_trans_payload,
  output logic [NUM_REGSRC-1:0][LD_PIPES-1:0][LD_DEP_W-1:0] o_trans_ld_dep
);

  localparam bit KEEP_WIDE = IS_ENQ | IS_TRANS;         // 是否要产出 transEntry
  localparam int PL_W      = KEEP_WIDE ? PL_TRANS_W : PL_DEQ_W;

  // -------- 条目寄存器(golden: validReg / entryReg_*) --------
  logic                              valid_reg;
  logic                              r_rob_flag;
  logic [ROB_W-1:0]                  r_rob_value;
  logic [NUM_FU_BIT-1:0]             r_fu_type;
  logic [NUM_REGSRC-1:0][PSRC_W-1:0] r_psrc;
  logic [NUM_REGSRC-1:0][3:0]        r_src_type;
  logic [NUM_REGSRC-1:0]             r_src_state;
  logic [NUM_REGSRC-1:0][3:0]        r_data_src;
  logic                              r_blocked;
  logic                              r_issued;
  logic                              r_first_issue;
  logic [1:0]                        r_issue_timer;
  logic                              r_deq_port_idx;
  logic [PL_W-1:0]                   r_payload;
  logic [NUM_REGSRC-1:0][LD_PIPES-1:0][LD_DEP_W-1:0] r_ld_dep;

  // ---------------------------------------------------------------------------
  // §2.1 冲刷判定。RobPtr 是环形指针 {flag, value};「本条目比冲刷点新」=
  //      (flag 不同) XOR (value 更大)。level=1 表示连同冲刷点自身一起冲。
  // ---------------------------------------------------------------------------
  logic newer_than_flush, flushed;
  always_comb begin
    newer_than_flush = (r_rob_flag ^ flush_rob_flag) ^ (r_rob_value > flush_rob_value);
    flushed = flush_valid &
              ((flush_level & ({r_rob_flag, r_rob_value} == {flush_rob_flag, flush_rob_value}))
               | newer_than_flush);
  end

  // ---------------------------------------------------------------------------
  // §2.2 WB 唤醒匹配。一路 WB 唤醒源 s 的条件:
  //        该路 valid & 该路写使能 & 该路 pdest == 本源 psrc & 源类型位匹配
  //      「哪几路能唤醒哪个源」由 SRC_WB_MASK 参数给,例如向量变体:
  //        src0/1/2(vs1/vs2/vd)听 WB[0:5](vecWen),srcType[2]
  //        src3    (v0 掩码)   听 WB[6:11](v0Wen), srcType[3]
  //        src4    (vl)        听 WB[12:15](vlWen),srcType[2]
  //      psrc 比 pdest 窄,golden 是零扩后比较,这里照搬。
  // ---------------------------------------------------------------------------
  logic [NUM_REGSRC-1:0] wk_hit;   // 当拍总线命中
  logic [NUM_REGSRC-1:0] wkd_hit;  // 入队延迟总线命中(仅 IS_ENQ 有意义)
  always_comb begin
    wk_hit  = '0;
    wkd_hit = '0;
    for (int s = 0; s < NUM_REGSRC; s++) begin
      for (int w = 0; w < NUM_WK_WB; w++) begin
        if (SRC_WB_MASK[s][w]) begin
          if (wk_valid[w] & wk_wen[w] & r_src_type[s][SRC_TYPE_BIT[s]]
              & (wk_pdest[w] == PDEST_W'(r_psrc[s])))
            wk_hit[s] = 1'b1;
          if (wkd_valid[w] & wkd_wen[w] & r_src_type[s][SRC_TYPE_BIT[s]]
              & (wkd_pdest[w] == PDEST_W'(r_psrc[s])))
            wkd_hit[s] = 1'b1;
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // §2.3 ignoreOldVd(向量专属)。向量指令常把目的寄存器 vd 也当源读回旧值,
  //      但在 tail/mask agnostic 且 vl 已知的配置下旧 vd 根本不会被用到 ——
  //      此时不必等它就绪:直接把 src[VD_SRC] 置就绪、srcType 清 0、
  //      dataSources 改成 IMM。判定要用本拍 vl 被哪一路写回唤醒。
  // ---------------------------------------------------------------------------
  logic vl_wk_int, vl_wk_vf, ignore_old_vd;
  logic pl_vm, pl_vma, pl_vta, pl_depend_oldvd, pl_write_partvd;
  always_comb begin
    pl_vm           = r_payload[PLB_VM];
    pl_vma          = r_payload[PLB_VMA];
    pl_vta          = r_payload[PLB_VTA];
    pl_depend_oldvd = r_payload[PLB_IS_DEPEND_OLDVD];
    pl_write_partvd = r_payload[PLB_IS_WRITE_PARTVD];

    vl_wk_int = 1'b0;
    vl_wk_vf  = 1'b0;
    ignore_old_vd = 1'b0;
    if (HAS_IGNORE_OLD_VD) begin
      vl_wk_int = wk_valid[WB_VL_INT] & wk_wen[WB_VL_INT]
                  & r_src_type[VL_SRC][SRC_TYPE_BIT[VL_SRC]]
                  & (wk_pdest[WB_VL_INT] == PDEST_W'(r_psrc[VL_SRC]));
      vl_wk_vf  = wk_valid[WB_VL_VF]  & wk_wen[WB_VL_VF]
                  & r_src_type[VL_SRC][SRC_TYPE_BIT[VL_SRC]]
                  & (wk_pdest[WB_VL_VF]  == PDEST_W'(r_psrc[VL_SRC]));
      ignore_old_vd =
          r_src_type[VD_SRC][SRC_TYPE_BIT[VD_SRC]]
        & ((~vl_int_is_zero & vl_wk_int) | (~vl_vf_is_zero & vl_wk_vf))
        & ~pl_depend_oldvd
        & ( (((vl_int_is_vlmax & vl_wk_int) | (vl_vf_is_vlmax & vl_wk_vf))
             & (pl_vm | pl_vma) & ~pl_write_partvd)
          | ((pl_vm | pl_vma) & pl_vta) );
    end
  end

  // ---------------------------------------------------------------------------
  // §2.4 valid / enqReady / clear。
  //      enqReady = 本条目空,或本拍就要被转移走(腾位)。
  //      clear    = 冲刷 | 发射成功 | 被转移走。
  //      装载优先于 clear(golden 的 Mux 顺序)。
  // ---------------------------------------------------------------------------
  logic deq_success, enq_ready, clear, load_now, valid_reg_next;
  always_comb begin
    deq_success    = resp_valid & (resp_bits == RESP_SUCCESS);
    enq_ready      = ~valid_reg | trans_sel;
    clear          = flushed | deq_success | trans_sel;
    load_now       = IS_ENQ ? (enq_valid & enq_ready) : enq_valid;
    valid_reg_next = load_now ? 1'b1 : (clear ? 1'b0 : valid_reg);
  end

  // ---------------------------------------------------------------------------
  // §2.5 entryUpdate —— 不装载时条目的次态,同时也是 transEntry 的内容。
  //      EnqEntry 在「入队后的那一拍」用延迟唤醒总线补一次 srcState,
  //      记作 cur_src_state(golden 的 currentStatus)。
  // ---------------------------------------------------------------------------
  logic                       enqd_valid_reg;   // 入队延迟窗口(仅 IS_ENQ)
  logic [NUM_REGSRC-1:0]      cur_src_state;
  always_comb
    for (int s = 0; s < NUM_REGSRC; s++)
      cur_src_state[s] = IS_ENQ ? ((enqd_valid_reg & wkd_hit[s]) | r_src_state[s])
                                : r_src_state[s];

  logic [NUM_REGSRC-1:0]             u_src_state;
  logic [NUM_REGSRC-1:0][3:0]        u_src_type;
  logic [NUM_REGSRC-1:0][3:0]        u_data_src;
  logic                              u_issued, u_first_issue, u_deq_port_idx;
  logic [1:0]                        u_issue_timer;
  always_comb begin
    for (int s = 0; s < NUM_REGSRC; s++) begin
      logic is_vd;
      is_vd = HAS_IGNORE_OLD_VD & (s == VD_SRC) & ignore_old_vd;
      // srcState:被唤醒或被 ignoreOldVd 判定为不必等 → 就绪
      u_src_state[s] = cur_src_state[s] | wk_hit[s] | is_vd;
      // srcType:ignoreOldVd 后旧 vd 不再算源,类型清 0
      u_src_type[s]  = is_vd ? 4'h0 : r_src_type[s];
      // dataSources:ignoreOldVd → IMM;入队时标记的 readBypass → 下一拍落到 REG
      u_data_src[s]  = is_vd                        ? DS_IMM
                     : (r_data_src[s] == DS_BYPASS) ? DS_REG
                                                    : r_data_src[s];
    end
    // issued:被选中发射置位;收到 BLOCK 响应退回。(本核无 IQ 唤醒 → 无 cancel 路)
    u_issued      = deq_sel | (~(resp_valid & (resp_bits == RESP_BLOCK)) & r_issued);
    // firstIssue:一旦发射过就永远置位(commonOut.isFirstIssue 是它的反)
    u_first_issue = deq_sel | r_first_issue;
    // issueTimer:发射当拍清 0,之后 0→1→2→3 饱和;未发射恒 3。
    //             它是 issueResp 的时间窗索引(见阵列 §5)。
    u_issue_timer = deq_sel  ? 2'h0
                  : r_issued ? ((r_issue_timer == 2'h3) ? 2'h3 : r_issue_timer + 2'h1)
                             : 2'h3;
    // deqPortIdx:记住这条 uop 是从哪个发射口出去的,响应要按口回。
    u_deq_port_idx = deq_sel ? deq_port_idx_write : (r_issued ? r_deq_port_idx : 1'b0);
  end

  // ---------------------------------------------------------------------------
  // §2.6 时序。装载时:enq 条目强制「从未发射」(issued=0/timer=3/firstIssue=0/
  //      deqPortIdx=0/blocked=0,这几个 golden 里就是常数 0 折叠掉的);
  //      simp/comp 条目直接吃上一级的 transEntry。
  //      valid_reg 是唯一带复位的寄存器(与 golden 一致);entryReg 无复位。
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock or posedge reset)
    if (reset) valid_reg <= 1'b0;
    else       valid_reg <= valid_reg_next;

  always_ff @(posedge clock) begin
    if (load_now) begin
      r_rob_flag     <= enq_rob_flag;
      r_rob_value    <= enq_rob_value;
      r_fu_type      <= enq_fu_type;
      r_psrc         <= enq_psrc;
      r_src_type     <= enq_src_type;
      r_src_state    <= enq_src_state;
      r_data_src     <= enq_data_src;
      r_blocked      <= IS_ENQ ? 1'b0 : enq_blocked;
      r_issued       <= IS_ENQ ? 1'b0 : enq_issued;
      r_first_issue  <= IS_ENQ ? 1'b0 : enq_first_issue;
      r_issue_timer  <= IS_ENQ ? 2'h3 : enq_issue_timer;
      r_deq_port_idx <= IS_ENQ ? 1'b0 : enq_deq_port_idx;
      r_payload      <= enq_payload[PL_W-1:0];
    end else begin
      r_src_state    <= u_src_state;
      r_src_type     <= u_src_type;
      r_data_src     <= u_data_src;
      r_blocked      <= 1'b0;             // entryUpdate.status.blocked := false.B
      r_issued       <= u_issued;
      r_first_issue  <= u_first_issue;
      r_issue_timer  <= u_issue_timer;
      r_deq_port_idx <= u_deq_port_idx;
      // 其余字段 entryUpdate 原样保持
      r_rob_flag     <= r_rob_flag;
      r_rob_value    <= r_rob_value;
      r_fu_type      <= r_fu_type;
      r_psrc         <= r_psrc;
      r_payload      <= r_payload;
    end
  end

  // srcLoadDependency 影子:装载时吃入队值,否则整体左移一位。
  generate
    if (HAS_LD_DEP && KEEP_WIDE) begin : g_ld_dep
      always_ff @(posedge clock)
        for (int s = 0; s < NUM_REGSRC; s++)
          for (int q = 0; q < LD_PIPES; q++)
            r_ld_dep[s][q] <= load_now ? enq_ld_dep[s][q]
                                       : LD_DEP_W'(r_ld_dep[s][q] << 1);
      assign o_trans_ld_dep = r_ld_dep;
    end else begin : g_no_ld_dep
      always_comb r_ld_dep = '0;
      assign o_trans_ld_dep = '0;
    end
  endgenerate

  // 入队延迟窗口寄存器:入队成功的下一拍为 1,用来再补一次唤醒。
  generate
    if (IS_ENQ) begin : g_enq_delay
      always_ff @(posedge clock or posedge reset)
        if (reset) enqd_valid_reg <= 1'b0;
        else       enqd_valid_reg <= enq_valid & enq_ready;
    end else begin : g_no_enq_delay
      assign enqd_valid_reg = 1'b0;
    end
  endgenerate

  // ---------------------------------------------------------------------------
  // §2.7 组合输出。
  //      canIssue 用「当前」源状态:enq 条目含延迟唤醒补丁,others 用寄存值。
  // ---------------------------------------------------------------------------
  logic all_src_ready;
  always_comb begin
    all_src_ready = 1'b1;
    for (int s = 0; s < NUM_REGSRC; s++) all_src_ready &= cur_src_state[s];
  end

  assign o_valid          = valid_reg;
  assign o_issued         = r_issued;
  assign o_can_issue      = valid_reg & all_src_ready & ~r_issued & ~r_blocked & ~flushed;
  assign o_is_first_issue = ~r_first_issue;
  assign o_fu_type        = r_fu_type;
  assign o_data_src       = r_data_src;
  assign o_issue_timer    = r_issue_timer;
  assign o_deq_port_idx   = r_deq_port_idx;
  assign o_enq_ready      = enq_ready;

  // commonOut.entry:enq 条目露的是「打过延迟唤醒补丁」的状态。
  assign o_ety_rob_flag  = r_rob_flag;
  assign o_ety_rob_value = r_rob_value;
  assign o_ety_psrc      = r_psrc;
  assign o_ety_src_type  = r_src_type;
  assign o_ety_payload   = r_payload[PL_DEQ_W-1:0];

  // commonOut.transEntry = entryUpdate,valid = 在队 & 未冲刷 & 未发射。
  assign o_trans_valid        = valid_reg & ~flushed & ~r_issued;
  assign o_trans_rob_flag     = r_rob_flag;
  assign o_trans_rob_value    = r_rob_value;
  assign o_trans_fu_type      = r_fu_type;
  assign o_trans_psrc         = r_psrc;
  assign o_trans_src_type     = u_src_type;
  assign o_trans_src_state    = u_src_state;
  assign o_trans_data_src     = u_data_src;
  assign o_trans_blocked      = 1'b0;
  assign o_trans_issued       = u_issued;
  assign o_trans_first_issue  = u_first_issue;
  assign o_trans_issue_timer  = u_issue_timer;
  assign o_trans_deq_port_idx = u_deq_port_idx;
  generate
    if (KEEP_WIDE) assign o_trans_payload = r_payload;
    else           assign o_trans_payload = PL_TRANS_W'(r_payload);
  endgenerate

endmodule : xs_iq_entry

// =============================================================================
// §3 xs_iq_entries_core —— 条目阵列顶层(golden Entries<变体> 的可读核体)
// =============================================================================
module xs_iq_entries_core
  import iq_entries_pkg::*;
#(
  parameter int NUM_ENQ    = 2,
  parameter int NUM_SIMP   = 2,
  parameter int NUM_COMP   = 6,
  parameter int NUM_DEQ    = 1,
  parameter int NUM_REGSRC = 5,
  parameter int NUM_WK_WB  = 16,
  parameter int NUM_FU_BIT = 2,
  parameter int ROB_W      = 8,
  parameter int PSRC_W     = 7,
  parameter int PDEST_W    = 8,
  parameter int PL_DEQ_W   = 1,
  parameter int PL_TRANS_W = 1,
  parameter bit HAS_LD_DEP = 1'b0,
  parameter int LD_PIPES   = 1,
  parameter int LD_DEP_W   = 1,
  parameter logic [NUM_REGSRC-1:0][NUM_WK_WB-1:0] SRC_WB_MASK  = '0,
  parameter logic [NUM_REGSRC-1:0][2:0]           SRC_TYPE_BIT = '0,
  parameter bit HAS_IGNORE_OLD_VD = 1'b0,
  parameter int VD_SRC    = 2,
  parameter int VL_SRC    = 4,
  parameter int WB_VL_INT = 12,
  parameter int WB_VL_VF  = 13,
  parameter int PLB_VM              = 0,
  parameter int PLB_VMA             = 0,
  parameter int PLB_VTA             = 0,
  parameter int PLB_IS_DEPEND_OLDVD = 0,
  parameter int PLB_IS_WRITE_PARTVD = 0,
  parameter bit NEED_OG2_RESP = 1'b1     // 多周期 FU:真正的成功/阻塞在 og2 才回
) (
  input  logic clock,
  input  logic reset,

  input  logic             flush_valid,
  input  logic             flush_rob_flag,
  input  logic [ROB_W-1:0] flush_rob_value,
  input  logic             flush_level,

  // 派遣进来的新 uop
  input  logic [NUM_ENQ-1:0]                            enq_valid,
  input  logic [NUM_ENQ-1:0]                            enq_rob_flag,
  input  logic [NUM_ENQ-1:0][ROB_W-1:0]                 enq_rob_value,
  input  logic [NUM_ENQ-1:0][NUM_FU_BIT-1:0]            enq_fu_type,
  input  logic [NUM_ENQ-1:0][NUM_REGSRC-1:0][PSRC_W-1:0] enq_psrc,
  input  logic [NUM_ENQ-1:0][NUM_REGSRC-1:0][3:0]       enq_src_type,
  input  logic [NUM_ENQ-1:0][NUM_REGSRC-1:0]            enq_src_state,
  input  logic [NUM_ENQ-1:0][NUM_REGSRC-1:0][3:0]       enq_data_src,
  input  logic [NUM_ENQ-1:0][PL_TRANS_W-1:0]            enq_payload,
  input  logic [NUM_ENQ-1:0][NUM_REGSRC-1:0][LD_PIPES-1:0][LD_DEP_W-1:0] enq_ld_dep,

  // 写回唤醒总线:当拍 + 延迟 1 拍
  input  logic [NUM_WK_WB-1:0]              wk_valid,
  input  logic [NUM_WK_WB-1:0]              wk_wen,
  input  logic [NUM_WK_WB-1:0][PDEST_W-1:0] wk_pdest,
  input  logic [NUM_WK_WB-1:0]              wkd_valid,
  input  logic [NUM_WK_WB-1:0]              wkd_wen,
  input  logic [NUM_WK_WB-1:0][PDEST_W-1:0] wkd_pdest,

  input  logic vl_int_is_zero,
  input  logic vl_int_is_vlmax,
  input  logic vl_vf_is_zero,
  input  logic vl_vf_is_vlmax,

  // 发射响应(按发射口):og0/og1 只有 valid,resp 是常数;og2 带真 resp。
  input  logic [NUM_DEQ-1:0]      og0_valid,
  input  logic [NUM_DEQ-1:0]      og1_valid,
  input  logic [NUM_DEQ-1:0]      og2_valid,
  input  logic [NUM_DEQ-1:0][1:0] og2_resp,

  // 发射选择(上层 IssueQueue 的年龄选择结果)
  input  logic [NUM_DEQ-1:0]                deq_ready,
  input  logic [NUM_DEQ-1:0]                deq_sel_oh_valid,
  input  logic [NUM_DEQ-1:0][NUM_ENQ+NUM_SIMP+NUM_COMP-1:0] deq_sel_oh,
  input  logic [NUM_DEQ-1:0][NUM_ENQ-1:0]   enq_oldest_sel,
  input  logic [NUM_DEQ-1:0]                simp_oldest_valid,
  input  logic [NUM_DEQ-1:0][NUM_SIMP-1:0]  simp_oldest_sel,
  input  logic [NUM_DEQ-1:0]                comp_oldest_valid,
  input  logic [NUM_DEQ-1:0][NUM_COMP-1:0]  comp_oldest_sel,

  // simp→comp 提级:上层按年龄给出「这个 enq 槽位要提哪个 simp 条目」
  input  logic [NUM_ENQ-1:0][NUM_SIMP-1:0]  simp_deq_sel_vec,

  // 阵列状态(给上层做年龄登记 / 选择)
  output logic [NUM_ENQ+NUM_SIMP+NUM_COMP-1:0]                  o_valid,
  output logic [NUM_ENQ+NUM_SIMP+NUM_COMP-1:0]                  o_issued,
  output logic [NUM_ENQ+NUM_SIMP+NUM_COMP-1:0]                  o_can_issue,
  output logic [NUM_ENQ+NUM_SIMP+NUM_COMP-1:0][NUM_FU_BIT-1:0]  o_fu_type,
  output logic [NUM_ENQ+NUM_SIMP+NUM_COMP-1:0][NUM_REGSRC-1:0][3:0] o_data_src,

  // 发射出口
  output logic [NUM_DEQ-1:0]                             o_is_first_issue,
  output logic [NUM_DEQ-1:0]                             o_deq_rob_flag,
  output logic [NUM_DEQ-1:0][ROB_W-1:0]                  o_deq_rob_value,
  output logic [NUM_DEQ-1:0][NUM_FU_BIT-1:0]             o_deq_fu_type,
  output logic [NUM_DEQ-1:0][NUM_REGSRC-1:0][PSRC_W-1:0] o_deq_psrc,
  output logic [NUM_DEQ-1:0][NUM_REGSRC-1:0][3:0]        o_deq_src_type,
  output logic [NUM_DEQ-1:0][PL_DEQ_W-1:0]               o_deq_payload,

  // 转移选择回报(上层用它维护年龄矩阵)
  output logic [NUM_ENQ-1:0][NUM_SIMP-1:0] o_simp_enq_sel_vec,
  output logic [NUM_ENQ-1:0][NUM_COMP-1:0] o_comp_enq_sel_vec
);

  localparam int NUM_ENTRIES = NUM_ENQ + NUM_SIMP + NUM_COMP;
  localparam int SIMP_BASE   = NUM_ENQ;
  localparam int COMP_BASE   = NUM_ENQ + NUM_SIMP;
  localparam int NUM_OTHERS  = NUM_SIMP + NUM_COMP;

  // ---------------------------------------------------------------------------
  // §4 条目例化。三段 genvar,索引与 golden 的 entries 向量一一对应。
  //    所有「按条目」的线都开成 NUM_ENTRIES 宽的数组,后面统一按段切片。
  // ---------------------------------------------------------------------------
  logic [NUM_ENTRIES-1:0]                       e_valid, e_issued, e_can_issue;
  logic [NUM_ENTRIES-1:0]                       e_is_first_issue, e_enq_ready;
  logic [NUM_ENTRIES-1:0][NUM_FU_BIT-1:0]       e_fu_type;
  logic [NUM_ENTRIES-1:0][NUM_REGSRC-1:0][3:0]  e_data_src;
  logic [NUM_ENTRIES-1:0][1:0]                  e_issue_timer;
  logic [NUM_ENTRIES-1:0]                       e_deq_port_idx;

  // commonOut.entry(发射口可见的一份)
  logic [NUM_ENTRIES-1:0]                              y_rob_flag;
  logic [NUM_ENTRIES-1:0][ROB_W-1:0]                   y_rob_value;
  logic [NUM_ENTRIES-1:0][NUM_REGSRC-1:0][PSRC_W-1:0]  y_psrc;
  logic [NUM_ENTRIES-1:0][NUM_REGSRC-1:0][3:0]         y_src_type;
  logic [NUM_ENTRIES-1:0][PL_DEQ_W-1:0]                y_payload;

  // commonOut.transEntry(整包,只有 enq / simp 段有意义)
  logic [NUM_ENTRIES-1:0]                              t_valid, t_rob_flag;
  logic [NUM_ENTRIES-1:0][ROB_W-1:0]                   t_rob_value;
  logic [NUM_ENTRIES-1:0][NUM_FU_BIT-1:0]              t_fu_type;
  logic [NUM_ENTRIES-1:0][NUM_REGSRC-1:0][PSRC_W-1:0]  t_psrc;
  logic [NUM_ENTRIES-1:0][NUM_REGSRC-1:0][3:0]         t_src_type, t_data_src;
  logic [NUM_ENTRIES-1:0][NUM_REGSRC-1:0]              t_src_state;
  logic [NUM_ENTRIES-1:0]                              t_blocked, t_issued;
  logic [NUM_ENTRIES-1:0]                              t_first_issue, t_deq_port_idx;
  logic [NUM_ENTRIES-1:0][1:0]                         t_issue_timer;
  logic [NUM_ENTRIES-1:0][PL_TRANS_W-1:0]              t_payload;
  logic [NUM_ENTRIES-1:0][NUM_REGSRC-1:0][LD_PIPES-1:0][LD_DEP_W-1:0] t_ld_dep;

  // 条目输入线(由 §7/§8 驱动)
  logic [NUM_ENTRIES-1:0]                              x_enq_valid, x_rob_flag;
  logic [NUM_ENTRIES-1:0][ROB_W-1:0]                   x_rob_value;
  logic [NUM_ENTRIES-1:0][NUM_FU_BIT-1:0]              x_fu_type;
  logic [NUM_ENTRIES-1:0][NUM_REGSRC-1:0][PSRC_W-1:0]  x_psrc;
  logic [NUM_ENTRIES-1:0][NUM_REGSRC-1:0][3:0]         x_src_type, x_data_src;
  logic [NUM_ENTRIES-1:0][NUM_REGSRC-1:0]              x_src_state;
  logic [NUM_ENTRIES-1:0]                              x_blocked, x_issued;
  logic [NUM_ENTRIES-1:0]                              x_first_issue, x_deq_port_idx;
  logic [NUM_ENTRIES-1:0][1:0]                         x_issue_timer;
  logic [NUM_ENTRIES-1:0][PL_TRANS_W-1:0]              x_payload;
  logic [NUM_ENTRIES-1:0][NUM_REGSRC-1:0][LD_PIPES-1:0][LD_DEP_W-1:0] x_ld_dep;
  logic [NUM_ENTRIES-1:0]                              x_trans_sel;
  logic [NUM_ENTRIES-1:0]                              x_deq_sel, x_deq_port_idx_w;
  logic [NUM_ENTRIES-1:0]                              x_resp_valid;
  logic [NUM_ENTRIES-1:0][1:0]                         x_resp_bits;

  generate
    for (genvar i = 0; i < NUM_ENTRIES; i++) begin : g_entry
      // enq 段带入队延迟窗口;simp 段可被提级走(有 transSel);comp 段是终端。
      localparam bit L_IS_ENQ   = (i < NUM_ENQ);
      localparam bit L_IS_TRANS = (i >= SIMP_BASE) && (i < COMP_BASE);

      xs_iq_entry #(
        .IS_ENQ(L_IS_ENQ), .IS_TRANS(L_IS_TRANS),
        .NUM_REGSRC(NUM_REGSRC), .NUM_WK_WB(NUM_WK_WB), .NUM_FU_BIT(NUM_FU_BIT),
        .ROB_W(ROB_W), .PSRC_W(PSRC_W), .PDEST_W(PDEST_W),
        .PL_DEQ_W(PL_DEQ_W), .PL_TRANS_W(PL_TRANS_W),
        .HAS_LD_DEP(HAS_LD_DEP), .LD_PIPES(LD_PIPES), .LD_DEP_W(LD_DEP_W),
        .SRC_WB_MASK(SRC_WB_MASK), .SRC_TYPE_BIT(SRC_TYPE_BIT),
        .HAS_IGNORE_OLD_VD(HAS_IGNORE_OLD_VD),
        .VD_SRC(VD_SRC), .VL_SRC(VL_SRC),
        .WB_VL_INT(WB_VL_INT), .WB_VL_VF(WB_VL_VF),
        .PLB_VM(PLB_VM), .PLB_VMA(PLB_VMA), .PLB_VTA(PLB_VTA),
        .PLB_IS_DEPEND_OLDVD(PLB_IS_DEPEND_OLDVD),
        .PLB_IS_WRITE_PARTVD(PLB_IS_WRITE_PARTVD)
      ) u_e (
        .clock, .reset,
        .flush_valid, .flush_rob_flag, .flush_rob_value, .flush_level,
        .enq_valid      (x_enq_valid    [i]),
        .enq_rob_flag   (x_rob_flag     [i]),
        .enq_rob_value  (x_rob_value    [i]),
        .enq_fu_type    (x_fu_type      [i]),
        .enq_psrc       (x_psrc         [i]),
        .enq_src_type   (x_src_type     [i]),
        .enq_src_state  (x_src_state    [i]),
        .enq_data_src   (x_data_src     [i]),
        .enq_blocked    (x_blocked      [i]),
        .enq_issued     (x_issued       [i]),
        .enq_first_issue(x_first_issue  [i]),
        .enq_issue_timer(x_issue_timer  [i]),
        .enq_deq_port_idx(x_deq_port_idx[i]),
        .enq_payload    (x_payload      [i]),
        .enq_ld_dep     (x_ld_dep       [i]),
        .wk_valid, .wk_wen, .wk_pdest, .wkd_valid, .wkd_wen, .wkd_pdest,
        .vl_int_is_zero, .vl_int_is_vlmax, .vl_vf_is_zero, .vl_vf_is_vlmax,
        .deq_sel           (x_deq_sel       [i]),
        .deq_port_idx_write(x_deq_port_idx_w[i]),
        .resp_valid        (x_resp_valid    [i]),
        .resp_bits         (x_resp_bits     [i]),
        .trans_sel         (x_trans_sel     [i]),
        .o_valid          (e_valid         [i]),
        .o_issued         (e_issued        [i]),
        .o_can_issue      (e_can_issue     [i]),
        .o_is_first_issue (e_is_first_issue[i]),
        .o_fu_type        (e_fu_type       [i]),
        .o_data_src       (e_data_src      [i]),
        .o_issue_timer    (e_issue_timer   [i]),
        .o_deq_port_idx   (e_deq_port_idx  [i]),
        .o_enq_ready      (e_enq_ready     [i]),
        .o_ety_rob_flag   (y_rob_flag      [i]),
        .o_ety_rob_value  (y_rob_value     [i]),
        .o_ety_psrc       (y_psrc          [i]),
        .o_ety_src_type   (y_src_type      [i]),
        .o_ety_payload    (y_payload       [i]),
        .o_trans_valid       (t_valid       [i]),
        .o_trans_rob_flag    (t_rob_flag    [i]),
        .o_trans_rob_value   (t_rob_value   [i]),
        .o_trans_fu_type     (t_fu_type     [i]),
        .o_trans_psrc        (t_psrc        [i]),
        .o_trans_src_type    (t_src_type    [i]),
        .o_trans_src_state   (t_src_state   [i]),
        .o_trans_data_src    (t_data_src    [i]),
        .o_trans_blocked     (t_blocked     [i]),
        .o_trans_issued      (t_issued      [i]),
        .o_trans_first_issue (t_first_issue [i]),
        .o_trans_issue_timer (t_issue_timer [i]),
        .o_trans_deq_port_idx(t_deq_port_idx[i]),
        .o_trans_payload     (t_payload     [i]),
        .o_trans_ld_dep      (t_ld_dep      [i])
      );
    end
  endgenerate

  // ---------------------------------------------------------------------------
  // §5 deqSel / deqPortIdxWrite / issueResp。
  //    deqSel:上层给的 one-hot 命中本条目,且该发射口这拍确实收下了(deqReady)。
  //    issueResp:发射后按 issueTimer 走一个固定的响应时间窗:
  //      timer0 → og0(常数 BLOCK)  timer1 → og1(常数 UNCERTAIN)
  //      timer2 → og2(带真 resp)   timer3 → 无响应
  //    多发射口时按条目记下的 deqPortIdx 取对应口的响应。
  // ---------------------------------------------------------------------------
  logic [NUM_ENTRIES-1:0][NUM_DEQ-1:0] deq_hit;
  always_comb begin
    for (int i = 0; i < NUM_ENTRIES; i++) begin
      for (int d = 0; d < NUM_DEQ; d++)
        deq_hit[i][d] = deq_sel_oh_valid[d] & deq_sel_oh[d][i] & deq_ready[d];
      x_deq_sel[i]        = |deq_hit[i];
      x_deq_port_idx_w[i] = 1'b0;
      for (int d = 0; d < NUM_DEQ; d++)              // OHToUInt
        if (deq_hit[i][d]) x_deq_port_idx_w[i] |= 1'(d);
    end
  end

  logic [NUM_DEQ-1:0][3:0]      resp_valid_tab;   // [口][timer]
  logic [NUM_DEQ-1:0][3:0][1:0] resp_bits_tab;
  always_comb begin
    for (int d = 0; d < NUM_DEQ; d++) begin
      resp_valid_tab[d] = {1'b0, NEED_OG2_RESP & og2_valid[d], og1_valid[d], og0_valid[d]};
      resp_bits_tab[d]  = {2'h0,
                           NEED_OG2_RESP ? og2_resp[d] : 2'h0,
                           RESP_UNCERTAIN,
                           RESP_BLOCK};
    end
  end

  always_comb
    for (int i = 0; i < NUM_ENTRIES; i++) begin
      logic p;
      p = (NUM_DEQ > 1) ? e_deq_port_idx[i] : 1'b0;
      x_resp_valid[i] = resp_valid_tab[p][e_issue_timer[i]];
      x_resp_bits [i] = resp_bits_tab [p][e_issue_timer[i]];
    end

  // ---------------------------------------------------------------------------
  // §6 EnqPolicy —— golden 的 EnqPolicy 模块(SelectOne("circ", …, 2))。
  //    numEnq=2 时它退化成极简形式:
  //      第 0 个选择 = 最低位的空槽;第 1 个选择 = 最高位的空槽。
  //      第 1 个的 valid = 至少有两个空槽。
  //    ★ golden 的 EnqPolicyIO 宽度恒为 numEntries-numEnq(=NUM_OTHERS),
  //      simp 策略只用低 NUM_SIMP 位,comp 策略只用低 NUM_COMP 位,高位喂 0。
  //      对「最低位优先」无影响;对「最高位优先」必须只在有效位内取,故这里
  //      直接按各自真实宽度实现(与 golden 高位补零后的行为一致)。
  // ---------------------------------------------------------------------------
  function automatic logic [NUM_OTHERS-1:0] pick_lowest(input logic [NUM_OTHERS-1:0] m,
                                                        input int n);
    pick_lowest = '0;
    for (int k = 0; k < n; k++)
      if (m[k] & (pick_lowest == '0)) pick_lowest[k] = 1'b1;
  endfunction

  function automatic logic [NUM_OTHERS-1:0] pick_highest(input logic [NUM_OTHERS-1:0] m,
                                                         input int n);
    pick_highest = '0;
    for (int k = n - 1; k >= 0; k--)
      if (m[k] & (pick_highest == '0)) pick_highest[k] = 1'b1;
  endfunction

  function automatic logic has_two(input logic [NUM_OTHERS-1:0] m, input int n);
    int c;
    c = 0;
    for (int k = 0; k < n; k++) if (m[k]) c++;
    has_two = (c >= 2);
  endfunction

  // ---------------------------------------------------------------------------
  // §7 转移策略。规则(Entries.scala hasCompAndSimp 分支):
  //    - simp 全空且 comp 空位够 → enq 直接提到 comp(跳过 simp,少一跳延迟);
  //    - 否则 enq 转移到 simp;
  //    - simp→comp 提级由上层按年龄给 simpEntryDeqSelVec,能提几个看 comp 空位。
  //    「够不够」都是 PopCount 比较,且要么全转要么不转(all-or-none)。
  // ---------------------------------------------------------------------------
  logic [NUM_OTHERS-1:0] simp_can_enq;    // simp 条目可接收(空 或 本拍被提走)
  logic [NUM_OTHERS-1:0] comp_free;       // comp 条目为空
  logic [NUM_ENQ-1:0]    valid_for_trans; // enq 条目在队且未发射 → 可以被转移
  int unsigned n_enq_valid, n_comp_free, n_simp_can;
  logic enq_can_trans2simp, enq_can_trans2comp;
  logic [NUM_ENQ-1:0] simp_can_trans2comp;
  always_comb begin
    simp_can_enq = '0;
    comp_free    = '0;
    for (int j = 0; j < NUM_SIMP; j++) simp_can_enq[j] = e_enq_ready[SIMP_BASE + j];
    for (int j = 0; j < NUM_COMP; j++) comp_free[j]    = ~e_valid[COMP_BASE + j];
    for (int i = 0; i < NUM_ENQ; i++)
      valid_for_trans[i] = e_valid[i] & ~e_issued[i];

    n_enq_valid = 0; n_comp_free = 0; n_simp_can = 0;
    for (int i = 0; i < NUM_ENQ;  i++) if (e_valid[i])       n_enq_valid++;
    for (int j = 0; j < NUM_COMP; j++) if (comp_free[j])     n_comp_free++;
    for (int j = 0; j < NUM_SIMP; j++) if (simp_can_enq[j])  n_simp_can++;

    // simp 段整体为空且 comp 空位不少于待转移的 enq 数 → 直通 comp
    enq_can_trans2comp = (n_enq_valid <= n_comp_free);
    for (int j = 0; j < NUM_SIMP; j++) if (e_valid[SIMP_BASE + j]) enq_can_trans2comp = 1'b0;
    enq_can_trans2simp = ~enq_can_trans2comp & (n_enq_valid <= n_simp_can);
    for (int i = 0; i < NUM_ENQ; i++)
      simp_can_trans2comp[i] = ~enq_can_trans2comp & (n_comp_free >= unsigned'(i + 1));
  end

  // 两个策略各给出「第 0/第 1 个目标槽」。enq 槽 0 无效时,槽 1 顺延用第 0 个结果
  // (派遣不保证低位 enq 一定有效,见 Entries.scala 注释)。
  logic [NUM_OTHERS-1:0] simp_pol0, simp_pol1, comp_pol0, comp_pol1;
  logic                  simp_pol0_v, simp_pol1_v, comp_pol0_v, comp_pol1_v;
  logic [NUM_ENQ-1:0][NUM_OTHERS-1:0] simp_sel, comp_sel, comp_sel_raw;
  logic [NUM_ENQ-1:0]                 simp_sel_v, comp_sel_v, comp_sel_raw_v;
  always_comb begin
    simp_pol0   = pick_lowest (simp_can_enq, NUM_SIMP);
    simp_pol1   = pick_highest(simp_can_enq, NUM_SIMP);
    simp_pol0_v = |simp_pol0;
    simp_pol1_v = has_two(simp_can_enq, NUM_SIMP);
    comp_pol0   = pick_lowest (comp_free, NUM_COMP);
    comp_pol1   = pick_highest(comp_free, NUM_COMP);
    comp_pol0_v = |comp_pol0;
    comp_pol1_v = has_two(comp_free, NUM_COMP);

    simp_sel[0]   = simp_pol0;               simp_sel_v[0] = simp_pol0_v & valid_for_trans[0];
    comp_sel[0]   = comp_pol0;               comp_sel_v[0] = comp_pol0_v & valid_for_trans[0];
    comp_sel_raw[0] = comp_pol0;             comp_sel_raw_v[0] = comp_pol0_v;
    if (NUM_ENQ == 2) begin
      simp_sel[1]     = valid_for_trans[0] ? simp_pol1   : simp_pol0;
      simp_sel_v[1]   = (valid_for_trans[0] ? simp_pol1_v : simp_pol0_v) & valid_for_trans[1];
      comp_sel[1]     = valid_for_trans[0] ? comp_pol1   : comp_pol0;
      comp_sel_v[1]   = (valid_for_trans[0] ? comp_pol1_v : comp_pol0_v) & valid_for_trans[1];
      comp_sel_raw[1] = comp_pol1;           comp_sel_raw_v[1] = comp_pol1_v;
    end
  end

  // final*TransSelVec:再和「本拍到底允不允许转」与门。
  // 注意 comp 侧的 else 分支用的是**未经 validForTrans 门控**的原始策略输出
  // (Entries.scala 里 origSelOH),这一处不对称是 golden 行为,照搬。
  logic [NUM_ENQ-1:0][NUM_SIMP-1:0] final_simp_sel;
  logic [NUM_ENQ-1:0][NUM_COMP-1:0] final_comp_sel;
  always_comb
    for (int i = 0; i < NUM_ENQ; i++) begin
      for (int j = 0; j < NUM_SIMP; j++)
        final_simp_sel[i][j] = enq_can_trans2simp & simp_sel_v[i] & simp_sel[i][j];
      for (int j = 0; j < NUM_COMP; j++)
        final_comp_sel[i][j] = enq_can_trans2comp
                             ? (comp_sel_v[i]     & comp_sel[i][j])
                             : (comp_sel_raw_v[i] & comp_sel_raw[i][j]);
    end

  // ---------------------------------------------------------------------------
  // §8 othersEntryEnq 数据通路。三条汇流:
  //    simp 的入口 = Mux1H(final_simp_sel[*][j], enq 条目的 transEntry)
  //    comp 的来源 comp_enq[i] = 直通 enq 的 transEntry(enq_can_trans2comp)
  //                            或 被提级的 simp 的 transEntry(Mux1H simp_deq_sel_vec)
  //    comp 的入口 = Mux1H(final_comp_sel[*][j], comp_enq)
  //    Mux1H 一律写成「sel ? val : 0」的 OR 累加,sel 全 0 时给出 0 而不是 X。
  // ---------------------------------------------------------------------------
  `define IQE_MUX1H(DST, SEL, SRC, N)                                  \
    DST = '0;                                                          \
    for (int k = 0; k < N; k++) if (SEL) DST = DST | (SRC);

  // comp_enq:每个 enq 槽位对应一条「要进 comp 的整包」
  logic [NUM_ENQ-1:0]                             c_valid, c_rob_flag;
  logic [NUM_ENQ-1:0][ROB_W-1:0]                  c_rob_value;
  logic [NUM_ENQ-1:0][NUM_FU_BIT-1:0]             c_fu_type;
  logic [NUM_ENQ-1:0][NUM_REGSRC-1:0][PSRC_W-1:0] c_psrc;
  logic [NUM_ENQ-1:0][NUM_REGSRC-1:0][3:0]        c_src_type, c_data_src;
  logic [NUM_ENQ-1:0][NUM_REGSRC-1:0]             c_src_state;
  logic [NUM_ENQ-1:0]                             c_blocked, c_issued;
  logic [NUM_ENQ-1:0]                             c_first_issue, c_deq_port_idx;
  logic [NUM_ENQ-1:0][1:0]                        c_issue_timer;
  logic [NUM_ENQ-1:0][PL_TRANS_W-1:0]             c_payload;

  always_comb
    for (int i = 0; i < NUM_ENQ; i++) begin
      if (enq_can_trans2comp) begin
        c_valid[i]        = t_valid[i];
        c_rob_flag[i]     = t_rob_flag[i];
        c_rob_value[i]    = t_rob_value[i];
        c_fu_type[i]      = t_fu_type[i];
        c_psrc[i]         = t_psrc[i];
        c_src_type[i]     = t_src_type[i];
        c_src_state[i]    = t_src_state[i];
        c_data_src[i]     = t_data_src[i];
        c_blocked[i]      = t_blocked[i];
        c_issued[i]       = t_issued[i];
        c_first_issue[i]  = t_first_issue[i];
        c_issue_timer[i]  = t_issue_timer[i];
        c_deq_port_idx[i] = t_deq_port_idx[i];
        c_payload[i]      = t_payload[i];
      end else begin
        `IQE_MUX1H(c_valid[i],        simp_deq_sel_vec[i][k], t_valid[SIMP_BASE+k],        NUM_SIMP)
        `IQE_MUX1H(c_rob_flag[i],     simp_deq_sel_vec[i][k], t_rob_flag[SIMP_BASE+k],     NUM_SIMP)
        `IQE_MUX1H(c_rob_value[i],    simp_deq_sel_vec[i][k], t_rob_value[SIMP_BASE+k],    NUM_SIMP)
        `IQE_MUX1H(c_fu_type[i],      simp_deq_sel_vec[i][k], t_fu_type[SIMP_BASE+k],      NUM_SIMP)
        `IQE_MUX1H(c_psrc[i],         simp_deq_sel_vec[i][k], t_psrc[SIMP_BASE+k],         NUM_SIMP)
        `IQE_MUX1H(c_src_type[i],     simp_deq_sel_vec[i][k], t_src_type[SIMP_BASE+k],     NUM_SIMP)
        `IQE_MUX1H(c_src_state[i],    simp_deq_sel_vec[i][k], t_src_state[SIMP_BASE+k],    NUM_SIMP)
        `IQE_MUX1H(c_data_src[i],     simp_deq_sel_vec[i][k], t_data_src[SIMP_BASE+k],     NUM_SIMP)
        `IQE_MUX1H(c_blocked[i],      simp_deq_sel_vec[i][k], t_blocked[SIMP_BASE+k],      NUM_SIMP)
        `IQE_MUX1H(c_issued[i],       simp_deq_sel_vec[i][k], t_issued[SIMP_BASE+k],       NUM_SIMP)
        `IQE_MUX1H(c_first_issue[i],  simp_deq_sel_vec[i][k], t_first_issue[SIMP_BASE+k],  NUM_SIMP)
        `IQE_MUX1H(c_issue_timer[i],  simp_deq_sel_vec[i][k], t_issue_timer[SIMP_BASE+k],  NUM_SIMP)
        `IQE_MUX1H(c_deq_port_idx[i], simp_deq_sel_vec[i][k], t_deq_port_idx[SIMP_BASE+k], NUM_SIMP)
        `IQE_MUX1H(c_payload[i],      simp_deq_sel_vec[i][k], t_payload[SIMP_BASE+k],      NUM_SIMP)
      end
    end

  // 三段条目的输入线
  always_comb begin
    // enq 段:直接吃派遣。transSel = 本拍能被转移出去。
    for (int i = 0; i < NUM_ENQ; i++) begin
      x_enq_valid[i]    = enq_valid[i];
      x_rob_flag[i]     = enq_rob_flag[i];
      x_rob_value[i]    = enq_rob_value[i];
      x_fu_type[i]      = enq_fu_type[i];
      x_psrc[i]         = enq_psrc[i];
      x_src_type[i]     = enq_src_type[i];
      x_src_state[i]    = enq_src_state[i];
      x_data_src[i]     = enq_data_src[i];
      x_blocked[i]      = 1'b0;
      x_issued[i]       = 1'b0;
      x_first_issue[i]  = 1'b0;
      x_issue_timer[i]  = 2'h0;
      x_deq_port_idx[i] = 1'b0;
      x_payload[i]      = enq_payload[i];
      x_ld_dep[i]       = enq_ld_dep[i];
      x_trans_sel[i]    = (enq_can_trans2simp & simp_sel_v[i])
                        | (enq_can_trans2comp & comp_sel_v[i]);
    end
    // simp 段:入口来自 enq 的 transEntry。transSel = 本拍被提级到 comp。
    for (int j = 0; j < NUM_SIMP; j++) begin
      automatic int e = SIMP_BASE + j;
      `IQE_MUX1H(x_enq_valid[e],    final_simp_sel[k][j], t_valid[k],        NUM_ENQ)
      `IQE_MUX1H(x_rob_flag[e],     final_simp_sel[k][j], t_rob_flag[k],     NUM_ENQ)
      `IQE_MUX1H(x_rob_value[e],    final_simp_sel[k][j], t_rob_value[k],    NUM_ENQ)
      `IQE_MUX1H(x_fu_type[e],      final_simp_sel[k][j], t_fu_type[k],      NUM_ENQ)
      `IQE_MUX1H(x_psrc[e],         final_simp_sel[k][j], t_psrc[k],         NUM_ENQ)
      `IQE_MUX1H(x_src_type[e],     final_simp_sel[k][j], t_src_type[k],     NUM_ENQ)
      `IQE_MUX1H(x_src_state[e],    final_simp_sel[k][j], t_src_state[k],    NUM_ENQ)
      `IQE_MUX1H(x_data_src[e],     final_simp_sel[k][j], t_data_src[k],     NUM_ENQ)
      `IQE_MUX1H(x_blocked[e],      final_simp_sel[k][j], t_blocked[k],      NUM_ENQ)
      `IQE_MUX1H(x_issued[e],       final_simp_sel[k][j], t_issued[k],       NUM_ENQ)
      `IQE_MUX1H(x_first_issue[e],  final_simp_sel[k][j], t_first_issue[k],  NUM_ENQ)
      `IQE_MUX1H(x_issue_timer[e],  final_simp_sel[k][j], t_issue_timer[k],  NUM_ENQ)
      `IQE_MUX1H(x_deq_port_idx[e], final_simp_sel[k][j], t_deq_port_idx[k], NUM_ENQ)
      `IQE_MUX1H(x_payload[e],      final_simp_sel[k][j], t_payload[k],      NUM_ENQ)
      `IQE_MUX1H(x_ld_dep[e],       final_simp_sel[k][j], t_ld_dep[k],       NUM_ENQ)
      x_trans_sel[e] = 1'b0;
      for (int i = 0; i < NUM_ENQ; i++)
        x_trans_sel[e] |= simp_deq_sel_vec[i][j] & simp_can_trans2comp[i];
    end
    // comp 段:入口来自 comp_enq。终端条目,不会被转移走。
    for (int j = 0; j < NUM_COMP; j++) begin
      automatic int e = COMP_BASE + j;
      `IQE_MUX1H(x_enq_valid[e],    final_comp_sel[k][j], c_valid[k],        NUM_ENQ)
      `IQE_MUX1H(x_rob_flag[e],     final_comp_sel[k][j], c_rob_flag[k],     NUM_ENQ)
      `IQE_MUX1H(x_rob_value[e],    final_comp_sel[k][j], c_rob_value[k],    NUM_ENQ)
      `IQE_MUX1H(x_fu_type[e],      final_comp_sel[k][j], c_fu_type[k],      NUM_ENQ)
      `IQE_MUX1H(x_psrc[e],         final_comp_sel[k][j], c_psrc[k],         NUM_ENQ)
      `IQE_MUX1H(x_src_type[e],     final_comp_sel[k][j], c_src_type[k],     NUM_ENQ)
      `IQE_MUX1H(x_src_state[e],    final_comp_sel[k][j], c_src_state[k],    NUM_ENQ)
      `IQE_MUX1H(x_data_src[e],     final_comp_sel[k][j], c_data_src[k],     NUM_ENQ)
      `IQE_MUX1H(x_blocked[e],      final_comp_sel[k][j], c_blocked[k],      NUM_ENQ)
      `IQE_MUX1H(x_issued[e],       final_comp_sel[k][j], c_issued[k],       NUM_ENQ)
      `IQE_MUX1H(x_first_issue[e],  final_comp_sel[k][j], c_first_issue[k],  NUM_ENQ)
      `IQE_MUX1H(x_issue_timer[e],  final_comp_sel[k][j], c_issue_timer[k],  NUM_ENQ)
      `IQE_MUX1H(x_deq_port_idx[e], final_comp_sel[k][j], c_deq_port_idx[k], NUM_ENQ)
      `IQE_MUX1H(x_payload[e],      final_comp_sel[k][j], c_payload[k],      NUM_ENQ)
      x_ld_dep[e]    = '0;   // golden 的 comp 条目入口不带 srcLoadDependency
      x_trans_sel[e] = 1'b0;
    end
  end

  // ---------------------------------------------------------------------------
  // §9 发射出口。上层按段各给一个「本段最老」的 one-hot,本层三级选择:
  //    comp 段有货优先,其次 simp 段,最后 enq 段(越靠后的段越老)。
  // ---------------------------------------------------------------------------
  always_comb
    for (int d = 0; d < NUM_DEQ; d++) begin
      logic                              q_rob_flag,  s_rob_flag,  p_rob_flag;
      logic [ROB_W-1:0]                  q_rob_value, s_rob_value, p_rob_value;
      logic [NUM_FU_BIT-1:0]             q_fu,        s_fu,        p_fu;
      logic [NUM_REGSRC-1:0][PSRC_W-1:0] q_psrc,      s_psrc,      p_psrc;
      logic [NUM_REGSRC-1:0][3:0]        q_st,        s_st,        p_st;
      logic [PL_DEQ_W-1:0]               q_pl,        s_pl,        p_pl;

      // enq 段最老
      `IQE_MUX1H(q_rob_flag,  enq_oldest_sel[d][k], y_rob_flag[k],  NUM_ENQ)
      `IQE_MUX1H(q_rob_value, enq_oldest_sel[d][k], y_rob_value[k], NUM_ENQ)
      `IQE_MUX1H(q_fu,        enq_oldest_sel[d][k], e_fu_type[k],   NUM_ENQ)
      `IQE_MUX1H(q_psrc,      enq_oldest_sel[d][k], y_psrc[k],      NUM_ENQ)
      `IQE_MUX1H(q_st,        enq_oldest_sel[d][k], y_src_type[k],  NUM_ENQ)
      `IQE_MUX1H(q_pl,        enq_oldest_sel[d][k], y_payload[k],   NUM_ENQ)
      // simp 段最老
      `IQE_MUX1H(s_rob_flag,  simp_oldest_sel[d][k], y_rob_flag[SIMP_BASE+k],  NUM_SIMP)
      `IQE_MUX1H(s_rob_value, simp_oldest_sel[d][k], y_rob_value[SIMP_BASE+k], NUM_SIMP)
      `IQE_MUX1H(s_fu,        simp_oldest_sel[d][k], e_fu_type[SIMP_BASE+k],   NUM_SIMP)
      `IQE_MUX1H(s_psrc,      simp_oldest_sel[d][k], y_psrc[SIMP_BASE+k],      NUM_SIMP)
      `IQE_MUX1H(s_st,        simp_oldest_sel[d][k], y_src_type[SIMP_BASE+k],  NUM_SIMP)
      `IQE_MUX1H(s_pl,        simp_oldest_sel[d][k], y_payload[SIMP_BASE+k],   NUM_SIMP)
      // comp 段最老
      `IQE_MUX1H(p_rob_flag,  comp_oldest_sel[d][k], y_rob_flag[COMP_BASE+k],  NUM_COMP)
      `IQE_MUX1H(p_rob_value, comp_oldest_sel[d][k], y_rob_value[COMP_BASE+k], NUM_COMP)
      `IQE_MUX1H(p_fu,        comp_oldest_sel[d][k], e_fu_type[COMP_BASE+k],   NUM_COMP)
      `IQE_MUX1H(p_psrc,      comp_oldest_sel[d][k], y_psrc[COMP_BASE+k],      NUM_COMP)
      `IQE_MUX1H(p_st,        comp_oldest_sel[d][k], y_src_type[COMP_BASE+k],  NUM_COMP)
      `IQE_MUX1H(p_pl,        comp_oldest_sel[d][k], y_payload[COMP_BASE+k],   NUM_COMP)

      o_deq_rob_flag [d] = comp_oldest_valid[d] ? p_rob_flag
                         : simp_oldest_valid[d] ? s_rob_flag  : q_rob_flag;
      o_deq_rob_value[d] = comp_oldest_valid[d] ? p_rob_value
                         : simp_oldest_valid[d] ? s_rob_value : q_rob_value;
      o_deq_fu_type  [d] = comp_oldest_valid[d] ? p_fu
                         : simp_oldest_valid[d] ? s_fu        : q_fu;
      o_deq_psrc     [d] = comp_oldest_valid[d] ? p_psrc
                         : simp_oldest_valid[d] ? s_psrc      : q_psrc;
      o_deq_src_type [d] = comp_oldest_valid[d] ? p_st
                         : simp_oldest_valid[d] ? s_st        : q_st;
      o_deq_payload  [d] = comp_oldest_valid[d] ? p_pl
                         : simp_oldest_valid[d] ? s_pl        : q_pl;
    end

  // ---------------------------------------------------------------------------
  // §10 阵列状态汇聚输出。
  // ---------------------------------------------------------------------------
  assign o_valid     = e_valid;
  assign o_issued    = e_issued;
  assign o_can_issue = e_can_issue;
  assign o_fu_type   = e_fu_type;
  assign o_data_src  = e_data_src;

  // isFirstIssue:本拍真发射的那条条目「是不是第一次发射」。
  always_comb
    for (int d = 0; d < NUM_DEQ; d++) begin
      logic f;
      `IQE_MUX1H(f, deq_sel_oh[d][k], e_is_first_issue[k], NUM_ENTRIES)
      o_is_first_issue[d] = deq_sel_oh_valid[d] & f;
    end

  always_comb begin
    o_simp_enq_sel_vec = '0;
    o_comp_enq_sel_vec = '0;
    for (int i = 0; i < NUM_ENQ; i++) begin
      for (int j = 0; j < NUM_SIMP; j++)
        o_simp_enq_sel_vec[i][j] = final_simp_sel[i][j] & t_valid[i];
      for (int j = 0; j < NUM_COMP; j++)
        o_comp_enq_sel_vec[i][j] = final_comp_sel[i][j] & c_valid[i];
    end
  end

  `undef IQE_MUX1H

  // ---------------------------------------------------------------------------
  // §11 本核尚未实现的家族维度(给后续变体 owner 的清单,全部有 golden 依据)
  //   (a) hasIQWakeUp:IQ 即时唤醒 + exuSources + og0Cancel/og1Cancel/ldCancel
  //       取消网络 + dataSources=forward/bypass。Alu*/Fma*/Ldu 等变体需要。
  //       落点:§2.2 唤醒匹配旁边加一路 IQ 唤醒;§2.5 srcState/dataSources 多两个
  //       MuxCase 分支;条目多出 cancelBypass 输出。
  //   (b) srcLoadDependency:每源 LoadPipelineWidth×LoadDependencyWidth 位,
  //       次态 = 本值左移 1;配合 ldCancel 做投机 load 唤醒撤销。
  //       ★ VfdivVidiv 变体里它整条通路都到不了任何顶层输出(comp 条目的入口
  //         根本没有这些位),故本核不实现;有 ldCancel 的变体必须补。
  //   (c) isVecMemIQ:status.vecMem(sqIdx/lqIdx/numLsElem)、blocked 的真逻辑
  //       (!isFirstLoad && isVleff)、按 sqIdx/lqIdx 匹配的 mem 响应。
  //       VlduVstu* 两个变体需要。本核 blocked 只做「入队装载 + 次态恒 0」。
  //   (d) needFeedBackSqIdx/LqIdx:issueResp 要在 datapath 响应和 mem 响应之间
  //       按 issueTimer 高位切换(Entries.scala §issueRespVec 的 if 分支)。
  //   (e) deqFuSame:numDeq=2 且两个口功能相同时,走 subDeqPolicy 的
  //       PriorityMux 双取(Entries.scala §deq 的 if (params.deqFuSame))。
  //   (f) isAllComp / isAllSimp:单一 othersTransPolicy 的转移分支。
  //       G1 的 14 个变体全是 hasCompAndSimp,故暂不需要。
  //   (g) needReadRegCache / needImm:SrcStatus 的 useRegCache/regCacheIdx
  //       与 EntryBundle.imm。
  // ---------------------------------------------------------------------------

endmodule : xs_iq_entries_core
