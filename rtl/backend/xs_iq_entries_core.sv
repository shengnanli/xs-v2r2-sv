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
// 本文件导航（共 1752 行；按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   L57    §1 与变体无关的编码
//   L81    §2 xs_iq_entry
//   L329   §2.1 冲刷判定
//   L341   §2.2 WB 唤醒匹配
//   L369   §2.2b IQ 即时唤醒匹配 + 投机撤销(LoadShouldCancel)
//   L481   §2.3 ignoreOldVd(向量专属)
//   L527   §2.3b currentStatus
//   L598   §2.4 valid / enqReady / clear
//   L614   §2.5 entryUpdate
//   L682   §2.6 时序
//   L722   §2.6a blocked / deqPortIdx
//   L775   §2.6b IQ 唤醒子族专属的三组状态
//   L810   §2.7 组合输出
//   L909   §3 xs_iq_entries_core
//   L1082  §3a 阵列层自己持有的两组寄存器(golden Entries.scala:140-142)
//   L1126  §4 条目例化
//   L1287  §5 deqSel / deqPortIdxWrite / issueResp
//   L1330  §6 EnqPolicy
//   L1361  §7 转移策略
//   L1438  §8 othersEntryEnq 数据通路
//   L1589  §9 发射出口
//   L1657  §10 阵列状态汇聚输出
//   L1698  §11 本核尚未实现的家族维度(给后续变体 owner 的清单,全部有 golden 依据)
// 导航由 verif/ut/Entries_common/core_nav.py 重算 —— 改完核跑一次，勿手改
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
  localparam logic [3:0] DS_FORWARD  = 4'd1;  // 本拍 IQ 唤醒:数据从 EXU 直接前递
  localparam logic [3:0] DS_BYPASS   = 4'd2;  // 旁路:下一拍数据落到寄存器堆
  localparam logic [3:0] DS_IMM      = 4'd4;  // 无源/立即(ignoreOldVd 后的旧 vd)
  localparam logic [3:0] DS_REGCACHE = 4'd6;  // 从寄存器缓存读(needReadRegCache 变体)
  localparam logic [3:0] DS_REG      = 4'd8;  // 物理寄存器堆

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

  // golden 的第三个维度:EnqEntry(isComp=true) / OthersEntry(isComp=false) simp /
  // OthersEntry(isComp=true) comp。isComp 只影响三处「本拍 IQ 唤醒也算数」的旁路:
  // canIssueBypass、dataSources=forward、cancelBypass/loadDependency 的取法。
  // 所以 IS_COMP = ~IS_TRANS(enq 与 comp 都是 true),这里仍显式给参数,便于读。
  parameter bit IS_COMP  = 1'b1,

  // 本变体的发射口数。★ deqPortIdx 到底有没有寄存器由它决定(实测 14/14:
  //   comp 条目有 deqPortIdx 寄存器 ⟺ NUM_DEQ_PORTS==2),不是由「有没有
  //   transEntry 出口」决定 —— 后者是从 VfdivVidiv(numDeq=1)外推出来的错结论。
  //   见 verif/ut/Entries_field_matrix/matrix.md 的 comp_deqPortIdxRead 列。
  parameter int NUM_DEQ_PORTS = 1,

  parameter int NUM_REGSRC = 5,   // 每 uop 的源寄存器数
  parameter int NUM_WK_WB  = 16,  // 写回唤醒总线路数
  parameter int NUM_FU_BIT = 2,   // 本变体保留的 FuType one-hot 位数
  parameter int ROB_W      = 8,   // RobPtr.value 宽度
  parameter int PSRC_W     = 7,   // srcStatus.psrc 宽度
  parameter int PDEST_W    = 8,   // 唤醒总线 pdest 宽度
  parameter int PL_DEQ_W   = 1,   // 发射口可见的负载位宽
  parameter int PL_TRANS_W = 1,   // 转移包携带的负载位宽(>= PL_DEQ_W,低位即 DEQ 部分)

  // 投机 load 唤醒的依赖影子(EntryBundles.SrcStatus.srcLoadDependency)。
  // 每源 LD_PIPES 条 load 流水各一个 LD_DEP_W 位的移位影子。
  // 次态:本拍被 IQ 唤醒则换成唤醒源给的(已移位)影子,否则自己左移一拍。
  // ★ 本参数是**按条目类型**给的:没有 ldCancel 的变体(VEC 族)里,comp 条目的
  //   这组寄存器整组是死的,golden 把它 DCE 了,所以阵列会给 comp 传 0。
  parameter bit HAS_LD_DEP = 1'b0,
  parameter int LD_PIPES   = 1,
  parameter int LD_DEP_W   = 1,

  // ---------------------------------------------------------------------------
  // IQ 即时唤醒(hasIQWakeUp 子族:INT/MEM 6 个 + FP 3 个变体)。
  // 与 WB 唤醒的区别:IQ 唤醒是「上游 EXU 还没写回、但已经确定 N 拍后出数」的
  // 投机唤醒,所以它带三样 WB 唤醒没有的东西:
  //   (1) 取消:上游若在 og0 被取消,本拍这条唤醒作废 —— cancelSel 输入。
  //   (2) 依赖影子 loadDependency:唤醒源自己的 load 依赖要传给被唤醒的源,
  //       以便 load 一旦 cancel 能把整条投机链撤回。
  //   (3) exuSources:记住「这个源是被哪一路 IQ 唤醒的」,发射时据此选前递通路。
  //
  // ★ og0Cancel 在 golden 里是按**全局 exu 下标**寻址的稀疏向量(Alu* 留
  //   {0,2,4,6},Falu* 只留 {8}),而且 is0Lat 有的路是真信号、有的被折成常量。
  //   这份下标映射属于变体薄层,核只收一根已经算好的 iq_cancel[w]。
  // ---------------------------------------------------------------------------
  parameter int NUM_WK_IQ = 0,
  // src s 只听 IQ_SRC_MASK[s] 里置 1 的那几路,且要求 srcType[IQ_TYPE_BIT[s]]。
  parameter logic [NUM_REGSRC-1:0][(NUM_WK_IQ > 0 ? NUM_WK_IQ : 1)-1:0] IQ_SRC_MASK = '0,
  parameter logic [NUM_REGSRC-1:0][2:0]                                 IQ_TYPE_BIT = '0,
  // ShiftLoadDependency:第 w 路 IQ 唤醒若自己就是第 q 条 load 流水,
  // 它给出的影子在 pipe q 上是常数 1(表示"就是我"),其余 pipe 才是左移。
  parameter logic [(NUM_WK_IQ > 0 ? NUM_WK_IQ : 1)-1:0][LD_PIPES-1:0] IQ_IS_LD_PIPE = '0,
  // exuSources.value = OHToUInt({oneHot(NUM_WK_IQ 位), 1'b0}) —— 即「第几路唤醒 + 1」,
  // 0 表示"还没被 IQ 唤醒过"。宽度 = $clog2(NUM_WK_IQ+1)。
  parameter int EXU_W = 1,

  // 寄存器缓存(needReadRegCache:INT/MEM 子族)。
  parameter bit HAS_REG_CACHE = 1'b0,
  parameter int RC_IDX_W      = 1,
  // 哪几路 IQ 唤醒会写 regcache(needWriteRegCache);RC_TYPE_BIT 是 SrcType.isXp 位。
  parameter logic [(NUM_WK_IQ > 0 ? NUM_WK_IQ : 1)-1:0] IQ_WRITE_RC = '0,
  parameter int RC_TYPE_BIT = 0,

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
  input  logic [NUM_REGSRC-1:0][EXU_W-1:0]    enq_exu_src,
  input  logic [NUM_REGSRC-1:0]               enq_use_rc,
  input  logic [NUM_REGSRC-1:0][RC_IDX_W-1:0] enq_rc_idx,

  // 唤醒总线:当拍 + 入队延迟 1 拍(后者只有 IS_ENQ 用)
  input  logic [NUM_WK_WB-1:0]              wk_valid,
  input  logic [NUM_WK_WB-1:0]              wk_wen,
  input  logic [NUM_WK_WB-1:0][PDEST_W-1:0] wk_pdest,
  input  logic [NUM_WK_WB-1:0]              wkd_valid,
  input  logic [NUM_WK_WB-1:0]              wkd_wen,
  input  logic [NUM_WK_WB-1:0][PDEST_W-1:0] wkd_pdest,

  // IQ 即时唤醒总线:当拍 + 入队延迟 1 拍。NUM_WK_IQ==0 时整组悬空不用。
  // iq_cancel[w] 已由薄层算好(= og0Cancel[该路的全局 exu 下标] & is0Lat[w])。
  input  logic [(NUM_WK_IQ > 0 ? NUM_WK_IQ : 1)-1:0]                          iq_wen,
  input  logic [(NUM_WK_IQ > 0 ? NUM_WK_IQ : 1)-1:0][PDEST_W-1:0]             iq_pdest,
  input  logic [(NUM_WK_IQ > 0 ? NUM_WK_IQ : 1)-1:0][LD_PIPES-1:0][LD_DEP_W-1:0] iq_ld_dep,
  input  logic [(NUM_WK_IQ > 0 ? NUM_WK_IQ : 1)-1:0][RC_IDX_W-1:0]            iq_rc_dest,
  input  logic [(NUM_WK_IQ > 0 ? NUM_WK_IQ : 1)-1:0]                          iq_cancel,
  input  logic [(NUM_WK_IQ > 0 ? NUM_WK_IQ : 1)-1:0]                          iqd_wen,
  input  logic [(NUM_WK_IQ > 0 ? NUM_WK_IQ : 1)-1:0][PDEST_W-1:0]             iqd_pdest,
  input  logic [(NUM_WK_IQ > 0 ? NUM_WK_IQ : 1)-1:0][LD_PIPES-1:0][LD_DEP_W-1:0] iqd_ld_dep,
  input  logic [(NUM_WK_IQ > 0 ? NUM_WK_IQ : 1)-1:0][RC_IDX_W-1:0]            iqd_rc_dest,
  input  logic [(NUM_WK_IQ > 0 ? NUM_WK_IQ : 1)-1:0]                          iqd_cancel,

  // 投机 load 撤销(LoadShouldCancel):每条 load 流水两级。
  //   ld1Cancel 配 dep 的 bit0,ld2Cancel 配 bit1。
  //   ★ Alu*/Falu* 变体只有 ld2Cancel(ld1 那一路被 firtool 删干净),
  //     Ldu/StaMou/StdMoud 两级都有 —— 见矩阵 ldCancel_ld1/ld2 两列。
  input  logic [LD_PIPES-1:0] ld1_cancel,
  input  logic [LD_PIPES-1:0] ld2_cancel,
  input  logic [LD_PIPES-1:0] ld1d_cancel,
  input  logic [LD_PIPES-1:0] ld2d_cancel,
  // ★ 入队延迟窗口判「本源影子该不该撤」用的不是条目寄存器,而是 Entries 里
  //   RegEnable(payload.srcLoadDependency, enq.valid) 存下的入队瞬间那份
  //   (golden Entries.scala:140)。两者在正常激励下同值,但结构上是两组寄存器。
  input  logic [NUM_REGSRC-1:0][LD_PIPES-1:0][LD_DEP_W-1:0] enqd_self_ld_dep,

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
  output logic                       o_cancel_bypass,   // commonOut.cancelBypass
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
  // ★ entry 出口的 srcLoadDependency 露的**不是**寄存器,而是「次态」
  //   (CommonOutConnect 里 commonOut.entry…srcLoadDependency := srcLoadDependencyOut)。
  //   comp 条目还要把本拍 IQ 唤醒带来的影子算进去,所以它与 o_trans_ld_dep 不同。
  output logic [NUM_REGSRC-1:0][LD_PIPES-1:0][LD_DEP_W-1:0] o_ety_ld_dep,
  output logic [NUM_REGSRC-1:0][RC_IDX_W-1:0]               o_ety_rc_idx,
  // commonOut.exuSources(comp 条目会把本拍 IQ 唤醒算进去,enq/simp 露寄存值)
  output logic [NUM_REGSRC-1:0][EXU_W-1:0]                  o_exu_src,

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
  output logic [NUM_REGSRC-1:0][LD_PIPES-1:0][LD_DEP_W-1:0] o_trans_ld_dep,
  output logic [NUM_REGSRC-1:0][EXU_W-1:0]                  o_trans_exu_src,
  output logic [NUM_REGSRC-1:0]                             o_trans_use_rc,
  output logic [NUM_REGSRC-1:0][RC_IDX_W-1:0]               o_trans_rc_idx
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
  // r_blocked / r_deq_port_idx 不是每种条目都真有寄存器,见 §2.6a。
  logic                              r_blocked;
  logic                              r_issued;
  logic                              r_first_issue;
  logic [1:0]                        r_issue_timer;
  logic                              r_deq_port_idx;
  logic [PL_W-1:0]                   r_payload;
  logic [NUM_REGSRC-1:0][LD_PIPES-1:0][LD_DEP_W-1:0] r_ld_dep;
  // 只有 hasIQWakeUp / needReadRegCache 子族真有这三组寄存器(否则恒 0,见 §2.6b)
  logic [NUM_REGSRC-1:0][EXU_W-1:0]    r_exu_src;
  logic [NUM_REGSRC-1:0]               r_use_rc;
  logic [NUM_REGSRC-1:0][RC_IDX_W-1:0] r_rc_idx;

  localparam int IQW = (NUM_WK_IQ > 0) ? NUM_WK_IQ : 1;   // 数组下标用的安全宽度

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
  // §2.2b IQ 即时唤醒匹配 + 投机撤销(LoadShouldCancel)。
  //
  //   wakeup_oh[s][w]  = 第 w 路 IQ 唤醒打中源 s(未计取消)   -> srcWakeupByIQWithoutCancel
  //   wk_iq_oh[s][w]   = 上面再去掉 og0 取消的那几路          -> srcWakeupByIQ
  //   ld_trans_cancel[s] = Mux1H(wakeup_oh[s], 每路唤醒自己的 load 依赖该不该撤)
  //   ld_self_cancel[s]  = 本源已经存下的 load 依赖该不该撤
  //
  //   LoadShouldCancel(dep) = |q (ld1Cancel[q] & dep[q][0]) | (ld2Cancel[q] & dep[q][1])
  //   —— 依赖影子每拍左移一位,所以 bit0 表示"上一拍才唤醒的",bit1 表示"再前一拍"。
  //
  //   ★ enq 条目的延迟窗口用同一套逻辑跑一遍延迟总线(golden EnqDelayWakeupConnect)。
  //     golden 的 EnqEntry 在 Chisel 里有 enqDelayIn1/In2 两套,但 INT 子族走的
  //     那条分支只用得到 In1,firtool 把 In2 整套端口删了 —— 这里也只做 In1。
  // ---------------------------------------------------------------------------
  function automatic logic ld_should_cancel(
      input logic [LD_PIPES-1:0][LD_DEP_W-1:0] dep,
      input logic [LD_PIPES-1:0]               c1,
      input logic [LD_PIPES-1:0]               c2);
    ld_should_cancel = 1'b0;
    for (int q = 0; q < LD_PIPES; q++)
      ld_should_cancel |= (c1[q] & dep[q][0])
                        | ((LD_DEP_W > 1) & c2[q] & dep[q][LD_DEP_W > 1 ? 1 : 0]);
  endfunction

  // 第 w 路 IQ 唤醒交给被唤醒源的影子:自己就是第 q 条 load 流水时该位记常数 1,
  // 其余位是本路影子左移一拍(ShiftLoadDependency)。
  function automatic logic [LD_PIPES-1:0][LD_DEP_W-1:0] shift_iq_dep(
      input logic [LD_PIPES-1:0][LD_DEP_W-1:0] dep,
      input int w);
    for (int q = 0; q < LD_PIPES; q++)
      shift_iq_dep[q] = IQ_IS_LD_PIPE[w][q] ? LD_DEP_W'(1)
                                            : LD_DEP_W'(dep[q] << 1);
  endfunction

  logic [NUM_REGSRC-1:0][IQW-1:0] wakeup_oh;   // srcWakeupByIQWithoutCancel
  logic [NUM_REGSRC-1:0][IQW-1:0] wk_iq_oh;    // srcWakeupByIQ
  logic [NUM_REGSRC-1:0]          ld_trans_cancel;
  logic [NUM_REGSRC-1:0]          wk_iq_hit;   // wakeupByIQ = |wk_iq_oh & !ld_trans_cancel

  // enq 延迟窗口那一拍的同名量
  logic [NUM_REGSRC-1:0][IQW-1:0] wakeup_oh_d;
  logic [NUM_REGSRC-1:0]          ld_trans_cancel_d, ld_self_cancel_d;  // 延迟窗口专用
  logic [NUM_REGSRC-1:0]          wk_iq_hit_d;

  always_comb begin
    wakeup_oh = '0; wk_iq_oh = '0; wakeup_oh_d = '0;
    ld_trans_cancel = '0; ld_trans_cancel_d = '0;
    ld_self_cancel_d = '0;
    wk_iq_hit = '0;       wk_iq_hit_d = '0;
    for (int s = 0; s < NUM_REGSRC; s++) begin
      // 延迟窗口里「本源入队时那份影子」该不该撤
      ld_self_cancel_d[s] = HAS_LD_DEP & ld_should_cancel(enqd_self_ld_dep[s],
                                                          ld1d_cancel, ld2d_cancel);
      for (int w = 0; w < NUM_WK_IQ; w++) begin
        if (IQ_SRC_MASK[s][w]) begin
          wakeup_oh[s][w] = iq_wen[w] & r_src_type[s][IQ_TYPE_BIT[s]]
                          & (iq_pdest[w] == PDEST_W'(r_psrc[s]));
          wk_iq_oh[s][w]  = wakeup_oh[s][w] & ~iq_cancel[w];
          wakeup_oh_d[s][w] = iqd_wen[w] & r_src_type[s][IQ_TYPE_BIT[s]]
                            & (iqd_pdest[w] == PDEST_W'(r_psrc[s]))
                            & ~iqd_cancel[w];
          // Mux1H:唤醒源自己那条 load 依赖该不该撤。
          // ★ 当拍这条的选择向量是 srcWakeupByIQ**WithoutCancel**(wakeup_oh),
          //   不是去掉 og0 取消之后的 wk_iq_oh —— 拿错会让"被 og0 取消的那一路"
          //   不再参与 load 撤销判定,issued 就会多置一次。
          //   延迟窗口那条(下面一行)反而用的是**去掉取消之后**的向量,
          //   这个不对称是 golden 的(EnqDelayWakeupConnect vs CommonWireConnect),照搬。
          if (wakeup_oh[s][w])
            ld_trans_cancel[s] |= ld_should_cancel(iq_ld_dep[w], ld1_cancel, ld2_cancel);
          if (wakeup_oh_d[s][w])
            ld_trans_cancel_d[s] |= ld_should_cancel(iqd_ld_dep[w], ld1d_cancel, ld2d_cancel);
        end
      end
      wk_iq_hit[s]   = (|wk_iq_oh[s])    & ~ld_trans_cancel[s];
      wk_iq_hit_d[s] = (|wakeup_oh_d[s]) & ~ld_trans_cancel_d[s];
    end
  end

  // 被 IQ 唤醒时该记下的 exuSources 值与 regcache 下标。
  //
  // ★★ golden 的 Mux1H 在选择向量**不是** one-hot 时给出的是各路的按位或,
  //    而这里的选择向量确实可能不止一位:两路不同的 IQ 唤醒可以同时打中同一个源
  //    (psrc 相同、都 rfWen)。实测就出现过 oh=1000010 两位同时置起。
  //    所以下面所有"按 oh 选一路"的地方都必须写成**或累加**,不能写成
  //    「for 循环里最后一个命中的覆盖前面的」—— 那样会丢掉另一路的贡献。
  //    (exuSources 那一路更隐蔽:golden 是 OHToUInt({oh,1'b0}),而 OHToUInt 在
  //     多位置起时正好等于各下标的按位或,所以 |= (w+1) 就是它。)
  //
  // 这里按「当拍」和「入队延迟窗口」拆成两段:延迟窗口那段要先算,
  // 因为 §2.3b 的 currentStatus 依赖它;当拍那段里的 replaceRC 要拿
  // currentStatus 的 regCacheIdx 去比,所以只能放在 §2.3b 之后(见 §2.5 前)。
  logic [NUM_REGSRC-1:0][EXU_W-1:0]    iq_exu_code_d;
  logic [NUM_REGSRC-1:0][RC_IDX_W-1:0] iq_rc_hit_idx_d;
  logic [NUM_REGSRC-1:0]               iq_rc_hit_d, rc_replaced_d;
  always_comb begin
    iq_exu_code_d = '0; iq_rc_hit_idx_d = '0; iq_rc_hit_d = '0; rc_replaced_d = '0;
    for (int s = 0; s < NUM_REGSRC; s++) begin
      for (int w = 0; w < NUM_WK_IQ; w++) begin
        if (wakeup_oh_d[s][w]) iq_exu_code_d[s] |= EXU_W'(w + 1);
        if (IQ_WRITE_RC[w]) begin
          if (wakeup_oh_d[s][w]) iq_rc_hit_idx_d[s] |= iqd_rc_dest[w];
          iq_rc_hit_d[s] |= wakeup_oh_d[s][w];
          // replaceRC:延迟窗口这一段 golden 比的是**寄存器**里的 regCacheIdx
          // (EnqEntry.scala 的 enqDelay1ReplaceRC 用 entryReg…regCacheIdx)。
          rc_replaced_d[s] |= iqd_wen[w] & (iqd_rc_dest[w] == r_rc_idx[s]);
        end
      end
      iq_rc_hit_d[s] &= r_src_type[s][RC_TYPE_BIT];
    end
  end

  // ---------------------------------------------------------------------------
  // §2.3 ignoreOldVd(向量专属)。向量指令常把目的寄存器 vd 也当源读回旧值,
  //      但在 tail/mask agnostic 且 vl 已知的配置下旧 vd 根本不会被用到 ——
  //      此时不必等它就绪:直接把 src[VD_SRC] 置就绪、srcType 清 0、
  //      dataSources 改成 IMM。判定要用本拍 vl 被哪一路写回唤醒。
  // ---------------------------------------------------------------------------
  //   ★ 这 5 个 vpu 控制位的比特位置是按**转移包**布局算的。不产出 transEntry 的
  //     comp 条目只存 PL_DEQ_W 位,非向量变体里这几个位置会落在 PL_W 之外 ——
  //     此时整条 ignoreOldVd 通路是死的(HAS_IGNORE_OLD_VD=0),但下标本身仍会被
  //     elaborate 并报越界警告。所以在这里按 PL_W 夹一下:夹到 0 只影响
  //     HAS_IGNORE_OLD_VD=0 的变体,那里这几根线一个都到不了输出。
  localparam int B_VM   = (PLB_VM   < PL_W) ? PLB_VM   : 0;
  localparam int B_VMA  = (PLB_VMA  < PL_W) ? PLB_VMA  : 0;
  localparam int B_VTA  = (PLB_VTA  < PL_W) ? PLB_VTA  : 0;
  localparam int B_DOVD = (PLB_IS_DEPEND_OLDVD < PL_W) ? PLB_IS_DEPEND_OLDVD : 0;
  localparam int B_WPVD = (PLB_IS_WRITE_PARTVD < PL_W) ? PLB_IS_WRITE_PARTVD : 0;

  logic vl_wk_int, vl_wk_vf, ignore_old_vd;
  logic pl_vm, pl_vma, pl_vta, pl_depend_oldvd, pl_write_partvd;
  always_comb begin
    pl_vm           = r_payload[B_VM];
    pl_vma          = r_payload[B_VMA];
    pl_vta          = r_payload[B_VTA];
    pl_depend_oldvd = r_payload[B_DOVD];
    pl_write_partvd = r_payload[B_WPVD];

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
  // §2.3b currentStatus —— 入队条目在「入队后那一拍」用延迟唤醒总线打的补丁。
  //   golden EnqEntry.scala 的 `when (enqDelayValidReg) { currentStatus.srcStatus … }`。
  //   ★ 要打补丁的**不止 srcState**:dataSources / srcLoadDependency / exuSources /
  //     useRegCache / regCacheIdx 五样都要跟着改。VfdivVidiv 只需要 srcState,
  //     是因为其余四样在那个变体里整条通路都是死的 —— 不是家族不变量。
  //   下面几处(§2.4 的 deqSuccess、§2.5 的 entryUpdate、§2.7 的输出)都读它,
  //   所以放在 §2.4 之前。
  // ---------------------------------------------------------------------------
  logic                       enqd_valid_reg;   // 入队延迟窗口(仅 IS_ENQ)
  logic [NUM_REGSRC-1:0]                             cur_src_state;
  logic [NUM_REGSRC-1:0][3:0]                        cur_data_src;
  logic [NUM_REGSRC-1:0][LD_PIPES-1:0][LD_DEP_W-1:0] cur_ld_dep;
  logic [NUM_REGSRC-1:0][EXU_W-1:0]                  cur_exu_src;
  logic [NUM_REGSRC-1:0]                             cur_use_rc;
  logic [NUM_REGSRC-1:0][RC_IDX_W-1:0]               cur_rc_idx;
  always_comb
    for (int s = 0; s < NUM_REGSRC; s++) begin
      logic dly;
      dly = IS_ENQ & enqd_valid_reg;
      cur_src_state[s] = dly ? ((~ld_self_cancel_d[s] & r_src_state[s])
                                | wkd_hit[s] | wk_iq_hit_d[s])
                             : r_src_state[s];
      cur_data_src[s]  = (dly & wk_iq_hit_d[s]) ? DS_BYPASS : r_data_src[s];
      // 影子:延迟窗口内若被 IQ 唤醒,换成那一路唤醒给的(已移位)影子
      cur_ld_dep[s] = r_ld_dep[s];
      cur_exu_src[s] = r_exu_src[s];
      cur_use_rc[s]  = r_use_rc[s];
      cur_rc_idx[s]  = r_rc_idx[s];
      if (dly) begin
        if (|wakeup_oh_d[s]) begin
          cur_ld_dep[s] = '0;
          for (int w = 0; w < NUM_WK_IQ; w++)
            if (wakeup_oh_d[s][w]) cur_ld_dep[s] |= shift_iq_dep(iqd_ld_dep[w], w);
        end
        // ★ exuSources 的延迟值是**无条件**的 Mux1H(没命中就是 0),不是"保持原值"
        cur_exu_src[s] = iq_exu_code_d[s];
        cur_use_rc[s]  = (r_use_rc[s] & ~(ld_self_cancel_d[s] | rc_replaced_d[s]))
                       | iq_rc_hit_d[s];
        cur_rc_idx[s]  = iq_rc_hit_d[s] ? iq_rc_hit_idx_d[s] : r_rc_idx[s];
      end
    end

  // srcLoadCancel 判的是 currentStatus 的影子(不是寄存器),enq 条目上两者不同。
  logic [NUM_REGSRC-1:0] cur_ld_cancel;
  always_comb
    for (int s = 0; s < NUM_REGSRC; s++)
      cur_ld_cancel[s] = HAS_LD_DEP & ld_should_cancel(cur_ld_dep[s], ld1_cancel, ld2_cancel);

  // 当拍的 exuSources / regcache 选择。★ replaceRC 比的是 currentStatus 的
  //   regCacheIdx(EntryBundles.scala:`x._2.bits.rcDest === srcStatus.regCacheIdx`,
  //   而那里的 srcStatus 就是 currentStatus)—— 对 enq 条目在延迟窗口里
  //   与寄存器值不同,拿错会整条 useRegCache 通路跑偏。
  logic [NUM_REGSRC-1:0][EXU_W-1:0]    iq_exu_code;
  logic [NUM_REGSRC-1:0][RC_IDX_W-1:0] iq_rc_hit_idx;
  logic [NUM_REGSRC-1:0]               iq_rc_hit, rc_replaced;
  always_comb begin
    iq_exu_code = '0; iq_rc_hit_idx = '0; iq_rc_hit = '0; rc_replaced = '0;
    for (int s = 0; s < NUM_REGSRC; s++) begin
      for (int w = 0; w < NUM_WK_IQ; w++) begin
        if (wk_iq_oh[s][w]) iq_exu_code[s] |= EXU_W'(w + 1);
        if (IQ_WRITE_RC[w]) begin
          if (wk_iq_oh[s][w]) iq_rc_hit_idx[s] |= iq_rc_dest[w];
          iq_rc_hit[s]   |= wk_iq_oh[s][w];
          rc_replaced[s] |= iq_wen[w] & (iq_rc_dest[w] == cur_rc_idx[s]);
        end
      end
      iq_rc_hit[s] &= r_src_type[s][RC_TYPE_BIT];
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
    // ★ 本拍若有源被 load 撤销,即使收到 SUCCESS 也不算发射成功(条目不清)
    deq_success    = resp_valid & (resp_bits == RESP_SUCCESS) & ~(|cur_ld_cancel);
    enq_ready      = ~valid_reg | trans_sel;
    clear          = flushed | deq_success | trans_sel;
    load_now       = IS_ENQ ? (enq_valid & enq_ready) : enq_valid;
    valid_reg_next = load_now ? 1'b1 : (clear ? 1'b0 : valid_reg);
  end

  // ---------------------------------------------------------------------------
  // §2.5 entryUpdate —— 不装载时条目的次态,同时也是 transEntry 的内容。
  //      入口状态一律用 §2.3b 的 currentStatus(cur_*),不是裸寄存器。
  // ---------------------------------------------------------------------------

  logic [NUM_REGSRC-1:0]                             u_src_state;
  logic [NUM_REGSRC-1:0][3:0]                        u_src_type;
  logic [NUM_REGSRC-1:0][3:0]                        u_data_src;
  logic [NUM_REGSRC-1:0][LD_PIPES-1:0][LD_DEP_W-1:0] u_ld_dep;
  logic [NUM_REGSRC-1:0][EXU_W-1:0]                  u_exu_src;
  logic [NUM_REGSRC-1:0]                             u_use_rc;
  logic [NUM_REGSRC-1:0][RC_IDX_W-1:0]               u_rc_idx;
  logic                              u_issued, u_first_issue, u_deq_port_idx;
  logic [1:0]                        u_issue_timer;
  // cancelBypassVec:本条目本拍该不该把"刚发射"这件事撤回。
  //   comp 条目:被 IQ 唤醒过的源看唤醒源的 load 依赖,否则看自己的;
  //   enq/simp: 一律看自己的。
  logic [NUM_REGSRC-1:0] cancel_bypass_vec;
  logic                  src_cancel_by_load;
  always_comb begin
    for (int s = 0; s < NUM_REGSRC; s++) begin
      logic is_vd, wb_or_iq;
      is_vd    = HAS_IGNORE_OLD_VD & (s == VD_SRC) & ignore_old_vd;
      wb_or_iq = wk_hit[s] | wk_iq_hit[s];
      // srcState:本拍被 load 撤销要先清掉,再或上本拍的唤醒 / ignoreOldVd
      u_src_state[s] = (cur_src_state[s] & ~cur_ld_cancel[s]) | wb_or_iq | is_vd;
      // srcType:ignoreOldVd 后旧 vd 不再算源,类型清 0
      u_src_type[s]  = is_vd ? 4'h0 : r_src_type[s];
      // dataSources(MuxCase,顺序即优先级):
      //   ignoreOldVd → IMM;本拍 IQ 唤醒 → BYPASS;入队标的 readBypass → REG
      u_data_src[s]  = is_vd                           ? DS_IMM
                     : wk_iq_hit[s]                    ? DS_BYPASS
                     : (cur_data_src[s] == DS_BYPASS)  ? DS_REG
                                                       : cur_data_src[s];
      // 影子:本拍被 IQ 唤醒则换成唤醒源给的(已移位)影子,否则自己左移一拍
      u_ld_dep[s] = '0;
      for (int q = 0; q < LD_PIPES; q++)
        u_ld_dep[s][q] = LD_DEP_W'(cur_ld_dep[s][q] << 1);
      if (wk_iq_hit[s]) begin
        u_ld_dep[s] = '0;
        for (int w = 0; w < NUM_WK_IQ; w++)
          if (wk_iq_oh[s][w]) u_ld_dep[s] |= shift_iq_dep(iq_ld_dep[w], w);
      end
      // exuSources:只有真被 IQ 唤醒才改写,否则保持
      u_exu_src[s] = (|wk_iq_oh[s]) ? iq_exu_code[s] : cur_exu_src[s];
      // regcache:被 load 撤销或被同格覆写则作废;本拍 IQ 唤醒则记下新格号
      u_use_rc[s]  = (cur_use_rc[s] & ~(cur_ld_cancel[s] | rc_replaced[s])) | iq_rc_hit[s];
      u_rc_idx[s]  = iq_rc_hit[s] ? iq_rc_hit_idx[s] : cur_rc_idx[s];

      cancel_bypass_vec[s] = (IS_COMP & (|wakeup_oh[s])) ? ld_trans_cancel[s]
                                                         : cur_ld_cancel[s];
    end
    src_cancel_by_load = |cur_ld_cancel;
    // issued(MuxCase):本拍被选中发射且没被撤 → 置位;
    //                  本源被 load 撤销 / 收到 BLOCK 响应 → 清 0;否则保持。
    u_issued = (deq_sel & ~(|cancel_bypass_vec)) ? 1'b1
             : (src_cancel_by_load | (resp_valid & (resp_bits == RESP_BLOCK))) ? 1'b0
             : r_issued;
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
  // §2.6 时序。装载时:enq 条目强制「从未发射」(issued=0/timer=3/firstIssue=0);
  //      simp/comp 条目直接吃上一级的 transEntry。
  //      blocked / deqPortIdx / 三组 IQ 专属状态不在这里,它们按变体与条目类型
  //      决定是否真的存在寄存器,见紧随其后的 §2.6a / §2.6b。
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
      r_issued       <= IS_ENQ ? 1'b0 : enq_issued;
      r_first_issue  <= IS_ENQ ? 1'b0 : enq_first_issue;
      r_issue_timer  <= IS_ENQ ? 2'h3 : enq_issue_timer;
      r_payload      <= enq_payload[PL_W-1:0];
    end else begin
      r_src_state    <= u_src_state;
      r_src_type     <= u_src_type;
      r_data_src     <= u_data_src;
      r_issued       <= u_issued;
      r_first_issue  <= u_first_issue;
      r_issue_timer  <= u_issue_timer;
      // 其余字段 entryUpdate 原样保持
      r_rob_flag     <= r_rob_flag;
      r_rob_value    <= r_rob_value;
      r_fu_type      <= r_fu_type;
      r_psrc         <= r_psrc;
      r_payload      <= r_payload;
    end
  end

  // ---------------------------------------------------------------------------
  // §2.6a blocked / deqPortIdx —— 这两个状态位 golden 只在**部分**条目类型里
  //   真有寄存器,另一类型被 firtool 常数折叠/DCE 掉了。可读核跟着一起不生成:
  //   多出来的死寄存器既误导读者,也会在 FM 里变成 golden 侧根本不存在的
  //   比较点/未读点。
  //
  //   blocked    : golden 的 EnqEntry 里**没有** entryReg_status_blocked ——
  //                入队条目的 blocked 入口恒 0(dispatch 不会送 blocked 的 uop),
  //                entryUpdate.status.blocked := false.B 又把次态钉死为 0。
  //                两种 OthersEntry(simp/comp)都有该寄存器。
  //   deqPortIdx : ★ 条件是 **KEEP_WIDE || NUM_DEQ_PORTS > 1**(实测 14/14)。
  //                enq / simp 两种条目**永远**有这个寄存器 —— 它们要把 deqPortIdx
  //                随 transEntry 传给下一级,哪怕单发射口时它恒 0。
  //                comp 是终端、不产 transEntry,所以只有双发射口时才需要它。
  //                ★ 这一条我连着栽了两次,两次方向相反,记下来:★
  //                  第一次:按 KEEP_WIDE 判 —— 漏了"双发射口时 comp 也要有",
  //                          canary 上会少 16 个条目的寄存器。
  //                  第二次:改成只按 NUM_DEQ_PORTS 判 —— 反过来把 enq/simp 的
  //                          也删了。UT 完全看不见(单口时 deqPortIdx 恒 0,不影响
  //                          任何输出),是 FM 的 FM-036 "Unknown name" 把它拽出来的。
  //                教训:矩阵里只核过 comp 那一列,就把结论套到三种条目上 ——
  //                      分份维度必须**逐个条目类型**核,别按一列外推(见矩阵
  //                      deqPortIdxReg_enq/_simp/_comp 三列)。
  // ---------------------------------------------------------------------------
  generate
    if (IS_ENQ) begin : g_no_blocked
      assign r_blocked = 1'b0;
    end else begin : g_blocked
      always_ff @(posedge clock)
        // 装载吃上一级的 transEntry.blocked;不装载时 entryUpdate 把它钉成 0。
        r_blocked <= load_now ? enq_blocked : 1'b0;
    end

    if (KEEP_WIDE || NUM_DEQ_PORTS > 1) begin : g_deq_port_idx
      always_ff @(posedge clock)
        r_deq_port_idx <= load_now ? (IS_ENQ ? 1'b0 : enq_deq_port_idx)
                                   : u_deq_port_idx;
    end else begin : g_no_deq_port_idx
      assign r_deq_port_idx = 1'b0;
    end

    // srcLoadDependency 影子。
    // ★ 存不存这个寄存器的条件是 HAS_LD_DEP(变体有没有 ldCancel),
    //   **不再**附带 KEEP_WIDE —— 有 ldCancel 的变体连 comp 条目都存它
    //   (实测 14/14,见矩阵 comp_in_ldDep 列)。
    if (HAS_LD_DEP) begin : g_ld_dep
      always_ff @(posedge clock)
        for (int s = 0; s < NUM_REGSRC; s++)
          r_ld_dep[s] <= load_now ? enq_ld_dep[s] : u_ld_dep[s];
    end else begin : g_no_ld_dep
      always_comb r_ld_dep = '0;
    end

    // ---------------------------------------------------------------------------
    // §2.6b IQ 唤醒子族专属的三组状态。没有 IQ 唤醒的变体(VEC 族 5 个)
    //   golden 里根本没有这些寄存器,这里也不生成。
    // ---------------------------------------------------------------------------
    if (NUM_WK_IQ > 0) begin : g_exu_src
      always_ff @(posedge clock)
        r_exu_src <= load_now ? enq_exu_src : u_exu_src;
    end else begin : g_no_exu_src
      always_comb r_exu_src = '0;
    end

    if (HAS_REG_CACHE) begin : g_reg_cache
      always_ff @(posedge clock) begin
        r_use_rc <= load_now ? enq_use_rc : u_use_rc;
        r_rc_idx <= load_now ? enq_rc_idx : u_rc_idx;
      end
    end else begin : g_no_reg_cache
      always_comb begin
        r_use_rc = '0;
        r_rc_idx = '0;
      end
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
  //      ★ isComp 的条目多一条 canIssueBypass:本拍刚被 IQ 唤醒的源也当就绪算,
  //        这样 0 周期唤醒的 uop 可以在同一拍就参与发射选择。
  // ---------------------------------------------------------------------------
  logic all_src_ready, all_src_ready_bypass;
  always_comb begin
    all_src_ready        = 1'b1;
    all_src_ready_bypass = 1'b1;
    for (int s = 0; s < NUM_REGSRC; s++) begin
      all_src_ready        &= cur_src_state[s];
      all_src_ready_bypass &= (cur_src_state[s] | (|wakeup_oh[s]));
    end
  end

  logic can_issue_plain, can_issue_bypass;
  assign can_issue_plain  = valid_reg & all_src_ready & ~r_issued & ~r_blocked;
  assign can_issue_bypass = valid_reg & all_src_ready_bypass & ~r_issued & ~r_blocked;

  assign o_valid          = valid_reg;
  assign o_issued         = r_issued;
  assign o_can_issue      = (IS_COMP ? (can_issue_plain | can_issue_bypass)
                                     : can_issue_plain) & ~flushed;
  assign o_cancel_bypass  = |cancel_bypass_vec;
  assign o_is_first_issue = ~r_first_issue;
  assign o_fu_type        = r_fu_type;
  assign o_issue_timer    = r_issue_timer;
  assign o_deq_port_idx   = r_deq_port_idx;
  assign o_enq_ready      = enq_ready;

  // commonOut.dataSources(MuxCase):comp 条目把本拍未取消的 IQ 唤醒记成 forward;
  // 否则「用 regcache 且本来要读寄存器堆」记成 regcache;再否则原样。
  always_comb
    for (int s = 0; s < NUM_REGSRC; s++) begin
      logic use_rc_now;
      use_rc_now = HAS_REG_CACHE & cur_use_rc[s] & (cur_data_src[s] == DS_REG);
      o_data_src[s] = (IS_COMP & (|wakeup_oh[s])) ? DS_FORWARD
                    : use_rc_now                  ? DS_REGCACHE
                                                  : cur_data_src[s];
    end

  // commonOut.exuSources:comp 条目算上本拍的 IQ 唤醒,enq/simp 露当前值。
  always_comb
    for (int s = 0; s < NUM_REGSRC; s++) begin
      logic [EXU_W-1:0] oh_code;
      oh_code = '0;
      for (int w = 0; w < NUM_WK_IQ; w++)
        if (wakeup_oh[s][w]) oh_code |= EXU_W'(w + 1);
      o_exu_src[s] = (IS_COMP & (|wakeup_oh[s])) ? oh_code : cur_exu_src[s];
    end

  // commonOut.entry:enq 条目露的是「打过延迟唤醒补丁」的状态。
  assign o_ety_rob_flag  = r_rob_flag;
  assign o_ety_rob_value = r_rob_value;
  assign o_ety_psrc      = r_psrc;
  assign o_ety_src_type  = r_src_type;
  assign o_ety_payload   = r_payload[PL_DEQ_W-1:0];
  assign o_ety_rc_idx    = cur_rc_idx;

  // ★ entry 出口的影子露的是**次态**:comp 条目要把本拍 IQ 唤醒带来的影子算进去,
  //   enq/simp 则只是"自己左移一拍"(= u_ld_dep 在没有 IQ 唤醒时的值)。
  always_comb
    for (int s = 0; s < NUM_REGSRC; s++) begin
      if (IS_COMP & (|wakeup_oh[s])) begin
        o_ety_ld_dep[s] = '0;
        for (int w = 0; w < NUM_WK_IQ; w++)
          if (wakeup_oh[s][w]) o_ety_ld_dep[s] |= shift_iq_dep(iq_ld_dep[w], w);
      end else begin
        for (int q = 0; q < LD_PIPES; q++)
          o_ety_ld_dep[s][q] = LD_DEP_W'(cur_ld_dep[s][q] << 1);
      end
    end

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
  assign o_trans_ld_dep       = u_ld_dep;
  assign o_trans_exu_src      = u_exu_src;
  assign o_trans_use_rc       = u_use_rc;
  assign o_trans_rc_idx       = u_rc_idx;
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
  // ★ comp 段的条目有没有 srcLoadDependency 寄存器,逐变体不同:
  //   有 ldCancel 的 6 个变体有(影子是活的),VfdivVidiv 那种只有死影子的没有。
  //   由薄层从 golden 的 comp 子模块端口直接量,不从 KEEP_WIDE 推。
  parameter bit COMP_HAS_LD_DEP = 1'b0,
  parameter int LD_PIPES   = 1,
  parameter int LD_DEP_W   = 1,
  parameter int NUM_WK_IQ  = 0,
  parameter logic [NUM_REGSRC-1:0][(NUM_WK_IQ > 0 ? NUM_WK_IQ : 1)-1:0] IQ_SRC_MASK = '0,
  parameter logic [NUM_REGSRC-1:0][2:0]                                 IQ_TYPE_BIT = '0,
  parameter logic [(NUM_WK_IQ > 0 ? NUM_WK_IQ : 1)-1:0][LD_PIPES-1:0]   IQ_IS_LD_PIPE = '0,
  parameter int EXU_W = 1,
  parameter bit HAS_REG_CACHE = 1'b0,
  parameter int RC_IDX_W      = 1,
  parameter logic [(NUM_WK_IQ > 0 ? NUM_WK_IQ : 1)-1:0] IQ_WRITE_RC = '0,
  parameter int RC_TYPE_BIT = 0,
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
  // issueResp 按 issueTimer(0..3)查表。哪一档有真 resp 端口、哪一档被 firtool
  // 折成常量,逐变体不同(实测:Alu* 的 og0 是常量 BLOCK、og1 才是真 resp;
  // VfdivVidiv 的 og0/og1 都是常量、og2 才是真 resp)——所以做成参数:
  //   OG_HAS_BITS[k]=1 表示第 k 档用输入 og_resp[k],否则用常量 OG_CONST_RESP[k]。
  parameter logic [3:0]      OG_HAS_BITS   = 4'b0100,
  parameter logic [3:0][1:0] OG_CONST_RESP = {2'h0, 2'h0, RESP_UNCERTAIN, RESP_BLOCK}
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
  // 入队瞬间那份 payload.srcLoadDependency,给 enq 条目的延迟窗口用
  // (golden Entries.scala:140 的 RegEnable —— 寄存器在**阵列层**,不在条目里)
  input  logic [NUM_ENQ-1:0][NUM_REGSRC-1:0][LD_PIPES-1:0][LD_DEP_W-1:0] enq_pl_ld_dep,
  // 派遣带过来的 regcache 状态(golden io_enq_*_bits_status_srcStatus_*_useRegCache
  // / _regCacheIdx)。exuSources 在派遣侧不存在,入队恒 0。
  input  logic [NUM_ENQ-1:0][NUM_REGSRC-1:0]               enq_use_rc,
  input  logic [NUM_ENQ-1:0][NUM_REGSRC-1:0][RC_IDX_W-1:0] enq_rc_idx,

  // 写回唤醒总线:当拍 + 延迟 1 拍
  input  logic [NUM_WK_WB-1:0]              wk_valid,
  input  logic [NUM_WK_WB-1:0]              wk_wen,
  input  logic [NUM_WK_WB-1:0][PDEST_W-1:0] wk_pdest,
  input  logic [NUM_WK_WB-1:0]              wkd_valid,
  input  logic [NUM_WK_WB-1:0]              wkd_wen,
  input  logic [NUM_WK_WB-1:0][PDEST_W-1:0] wkd_pdest,

  // IQ 即时唤醒总线(当拍 + 延迟一拍)与取消网络。
  // iq_cancel[w] 由薄层按 og0Cancel 的稀疏全局下标算好后送进来。
  input  logic [(NUM_WK_IQ > 0 ? NUM_WK_IQ : 1)-1:0]                            iq_wen,
  input  logic [(NUM_WK_IQ > 0 ? NUM_WK_IQ : 1)-1:0][PDEST_W-1:0]               iq_pdest,
  input  logic [(NUM_WK_IQ > 0 ? NUM_WK_IQ : 1)-1:0][LD_PIPES-1:0][LD_DEP_W-1:0] iq_ld_dep,
  input  logic [(NUM_WK_IQ > 0 ? NUM_WK_IQ : 1)-1:0][RC_IDX_W-1:0]              iq_rc_dest,
  // cancelSel[w] = og0Cancel[第 w 路唤醒的全局 exu 下标] & is0Lat[w]。
  // 薄层只负责把稀疏下标接对(og0_cancel_sel),以及把被折成常量的 is0Lat 钉成 0/1;
  // 「延迟一拍那份 og0Cancel」是 golden Entries.scala:141 的 RegNext,寄存器在本核里。
  input  logic [(NUM_WK_IQ > 0 ? NUM_WK_IQ : 1)-1:0]                            og0_cancel_sel,
  input  logic [(NUM_WK_IQ > 0 ? NUM_WK_IQ : 1)-1:0]                            iq_is0lat,
  input  logic [(NUM_WK_IQ > 0 ? NUM_WK_IQ : 1)-1:0]                            iqd_is0lat,
  input  logic [(NUM_WK_IQ > 0 ? NUM_WK_IQ : 1)-1:0]                            iqd_wen,
  input  logic [(NUM_WK_IQ > 0 ? NUM_WK_IQ : 1)-1:0][PDEST_W-1:0]               iqd_pdest,
  input  logic [(NUM_WK_IQ > 0 ? NUM_WK_IQ : 1)-1:0][LD_PIPES-1:0][LD_DEP_W-1:0] iqd_ld_dep,
  input  logic [(NUM_WK_IQ > 0 ? NUM_WK_IQ : 1)-1:0][RC_IDX_W-1:0]              iqd_rc_dest,
  input  logic [LD_PIPES-1:0] ld1_cancel,
  input  logic [LD_PIPES-1:0] ld2_cancel,

  input  logic vl_int_is_zero,
  input  logic vl_int_is_vlmax,
  input  logic vl_vf_is_zero,
  input  logic vl_vf_is_vlmax,

  // 发射响应(按发射口 × issueTimer 档位)。哪一档带真 resp 见 OG_HAS_BITS。
  input  logic [2:0][NUM_DEQ-1:0]      og_valid,
  input  logic [2:0][NUM_DEQ-1:0][1:0] og_resp,

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
  output logic [NUM_ENQ+NUM_SIMP+NUM_COMP-1:0][NUM_REGSRC-1:0][EXU_W-1:0] o_exu_src,
  // io.loadDependency:**按条目**(不是按源)——各源影子按位或起来(mergedLoadDependency)
  output logic [NUM_ENQ+NUM_SIMP+NUM_COMP-1:0][LD_PIPES-1:0][LD_DEP_W-1:0] o_ld_dep,

  // 发射出口
  output logic [NUM_DEQ-1:0]                             o_is_first_issue,
  output logic [NUM_DEQ-1:0]                             o_deq_rob_flag,
  output logic [NUM_DEQ-1:0][ROB_W-1:0]                  o_deq_rob_value,
  output logic [NUM_DEQ-1:0][NUM_FU_BIT-1:0]             o_deq_fu_type,
  output logic [NUM_DEQ-1:0][NUM_REGSRC-1:0][PSRC_W-1:0] o_deq_psrc,
  output logic [NUM_DEQ-1:0][NUM_REGSRC-1:0][3:0]        o_deq_src_type,
  output logic [NUM_DEQ-1:0][PL_DEQ_W-1:0]               o_deq_payload,
  output logic [NUM_DEQ-1:0][NUM_REGSRC-1:0][LD_PIPES-1:0][LD_DEP_W-1:0] o_deq_ld_dep,
  output logic [NUM_DEQ-1:0][NUM_REGSRC-1:0][RC_IDX_W-1:0]               o_deq_rc_idx,
  // io.cancelDeqVec:本拍这个发射口选中的那条条目要不要撤回发射
  output logic [NUM_DEQ-1:0]                             o_cancel_deq,

  // 转移选择回报(上层用它维护年龄矩阵)
  output logic [NUM_ENQ-1:0][NUM_SIMP-1:0] o_simp_enq_sel_vec,
  output logic [NUM_ENQ-1:0][NUM_COMP-1:0] o_comp_enq_sel_vec
);

  // ---------------------------------------------------------------------------
  // 本核对家族做的两条形状假设 —— 实测 14/14 成立(见字段矩阵 numEnq / numDeq 两列)。
  // 写成 elaborate 期断言而不是注释:将来真出现第三种形状时,要的是当场红,
  // 不是 §6 的 EnqPolicy 少驱动一路、§2 的 deqPortIdx 悄悄截位。
  // ---------------------------------------------------------------------------
  if (NUM_ENQ != 2)
    $error("xs_iq_entries_core: NUM_ENQ=%0d,但 §6 的 EnqPolicy 只实现了 numEnq==2 的退化形式",
           NUM_ENQ);
  if (NUM_DEQ > 2)
    $error("xs_iq_entries_core: NUM_DEQ=%0d,但 deqPortIdx 只有 1 位", NUM_DEQ);

  localparam int NUM_ENTRIES = NUM_ENQ + NUM_SIMP + NUM_COMP;
  localparam int SIMP_BASE   = NUM_ENQ;
  localparam int COMP_BASE   = NUM_ENQ + NUM_SIMP;
  localparam int NUM_OTHERS  = NUM_SIMP + NUM_COMP;

  // ---------------------------------------------------------------------------
  // §3a 阵列层自己持有的两组寄存器(golden Entries.scala:140-142)。
  //     它们属于阵列而不是条目:enq 条目的「延迟一拍」窗口要用的是阵列打过拍的
  //     ldCancel,以及入队那一瞬间 payload 里带的 srcLoadDependency。
  // ---------------------------------------------------------------------------
  logic [LD_PIPES-1:0] ld1_cancel_d, ld2_cancel_d;
  logic [(NUM_WK_IQ > 0 ? NUM_WK_IQ : 1)-1:0] og0_cancel_sel_d, iq_cancel, iqd_cancel;
  always_comb begin
    iq_cancel  = og0_cancel_sel   & iq_is0lat;
    iqd_cancel = og0_cancel_sel_d & iqd_is0lat;
  end
  generate
    if (NUM_WK_IQ > 0) begin : g_og0_dly
      always_ff @(posedge clock) og0_cancel_sel_d <= og0_cancel_sel;
    end else begin : g_no_og0_dly
      always_comb og0_cancel_sel_d = '0;
    end
  endgenerate
  logic [NUM_ENTRIES-1:0][NUM_REGSRC-1:0][LD_PIPES-1:0][LD_DEP_W-1:0] enqd_self_ld_dep;

  generate
    if (HAS_LD_DEP) begin : g_ld_cancel_dly
      always_ff @(posedge clock) begin
        ld1_cancel_d <= ld1_cancel;
        ld2_cancel_d <= ld2_cancel;
      end
      // RegEnable(payload.srcLoadDependency, enq.valid):只有 enq 段用得上,
      // simp/comp 段没有延迟窗口,钉 0(与 golden 一致:那边根本没有这组线)。
      for (genvar i = 0; i < NUM_ENQ; i++) begin : g_enqd_dep
        always_ff @(posedge clock)
          if (enq_valid[i]) enqd_self_ld_dep[i] <= enq_pl_ld_dep[i];
      end
      for (genvar i = NUM_ENQ; i < NUM_ENTRIES; i++) begin : g_enqd_dep_none
        always_comb enqd_self_ld_dep[i] = '0;
      end
    end else begin : g_no_ld_cancel_dly
      always_comb begin
        ld1_cancel_d     = '0;
        ld2_cancel_d     = '0;
        enqd_self_ld_dep = '0;
      end
    end
  endgenerate

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
  logic [NUM_ENTRIES-1:0]                       e_cancel_bypass;
  logic [NUM_ENTRIES-1:0][NUM_REGSRC-1:0][EXU_W-1:0] e_exu_src;

  // commonOut.entry(发射口可见的一份)
  logic [NUM_ENTRIES-1:0]                              y_rob_flag;
  logic [NUM_ENTRIES-1:0][ROB_W-1:0]                   y_rob_value;
  logic [NUM_ENTRIES-1:0][NUM_REGSRC-1:0][PSRC_W-1:0]  y_psrc;
  logic [NUM_ENTRIES-1:0][NUM_REGSRC-1:0][3:0]         y_src_type;
  logic [NUM_ENTRIES-1:0][PL_DEQ_W-1:0]                y_payload;
  logic [NUM_ENTRIES-1:0][NUM_REGSRC-1:0][LD_PIPES-1:0][LD_DEP_W-1:0] y_ld_dep;
  logic [NUM_ENTRIES-1:0][NUM_REGSRC-1:0][RC_IDX_W-1:0]               y_rc_idx;

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
  logic [NUM_ENTRIES-1:0][NUM_REGSRC-1:0][EXU_W-1:0]                  t_exu_src;
  logic [NUM_ENTRIES-1:0][NUM_REGSRC-1:0]                             t_use_rc;
  logic [NUM_ENTRIES-1:0][NUM_REGSRC-1:0][RC_IDX_W-1:0]               t_rc_idx;

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
  logic [NUM_ENTRIES-1:0][NUM_REGSRC-1:0][EXU_W-1:0]                  x_exu_src;
  logic [NUM_ENTRIES-1:0][NUM_REGSRC-1:0]                             x_use_rc;
  logic [NUM_ENTRIES-1:0][NUM_REGSRC-1:0][RC_IDX_W-1:0]               x_rc_idx;
  logic [NUM_ENTRIES-1:0]                              x_trans_sel;
  logic [NUM_ENTRIES-1:0]                              x_deq_sel, x_deq_port_idx_w;
  logic [NUM_ENTRIES-1:0]                              x_resp_valid;
  logic [NUM_ENTRIES-1:0][1:0]                         x_resp_bits;

  generate
    for (genvar i = 0; i < NUM_ENTRIES; i++) begin : g_entry
      // enq 段带入队延迟窗口;simp 段可被提级走(有 transSel);comp 段是终端。
      localparam bit L_IS_ENQ   = (i < NUM_ENQ);
      localparam bit L_IS_TRANS = (i >= SIMP_BASE) && (i < COMP_BASE);
      // golden: EnqEntry(isComp=true) / OthersEntry(isComp=false) simp /
      //         OthersEntry(isComp=true) comp
      localparam bit L_IS_COMP  = !L_IS_TRANS;

      xs_iq_entry #(
        .IS_ENQ(L_IS_ENQ), .IS_TRANS(L_IS_TRANS), .IS_COMP(L_IS_COMP),
        .NUM_DEQ_PORTS(NUM_DEQ),
        .NUM_REGSRC(NUM_REGSRC), .NUM_WK_WB(NUM_WK_WB), .NUM_FU_BIT(NUM_FU_BIT),
        .ROB_W(ROB_W), .PSRC_W(PSRC_W), .PDEST_W(PDEST_W),
        .PL_DEQ_W(PL_DEQ_W), .PL_TRANS_W(PL_TRANS_W),
        // comp 段(既非 enq 也非 simp)只有 COMP_HAS_LD_DEP 时才真有这组寄存器
        .HAS_LD_DEP(HAS_LD_DEP && (L_IS_ENQ || L_IS_TRANS || COMP_HAS_LD_DEP)),
        .LD_PIPES(LD_PIPES), .LD_DEP_W(LD_DEP_W),
        .NUM_WK_IQ(NUM_WK_IQ), .IQ_SRC_MASK(IQ_SRC_MASK), .IQ_TYPE_BIT(IQ_TYPE_BIT),
        .IQ_IS_LD_PIPE(IQ_IS_LD_PIPE), .EXU_W(EXU_W),
        .HAS_REG_CACHE(HAS_REG_CACHE), .RC_IDX_W(RC_IDX_W),
        .IQ_WRITE_RC(IQ_WRITE_RC), .RC_TYPE_BIT(RC_TYPE_BIT),
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
        .enq_exu_src    (x_exu_src      [i]),
        .enq_use_rc     (x_use_rc       [i]),
        .enq_rc_idx     (x_rc_idx       [i]),
        .wk_valid, .wk_wen, .wk_pdest, .wkd_valid, .wkd_wen, .wkd_pdest,
        .iq_wen, .iq_pdest, .iq_ld_dep, .iq_rc_dest, .iq_cancel,
        .iqd_wen, .iqd_pdest, .iqd_ld_dep, .iqd_rc_dest, .iqd_cancel,
        .ld1_cancel, .ld2_cancel,
        // 延迟一拍的 ldCancel 是阵列层的寄存器(golden Entries.scala:142 RegNext)
        .ld1d_cancel(ld1_cancel_d), .ld2d_cancel(ld2_cancel_d),
        .enqd_self_ld_dep(enqd_self_ld_dep[i]),
        .vl_int_is_zero, .vl_int_is_vlmax, .vl_vf_is_zero, .vl_vf_is_vlmax,
        .deq_sel           (x_deq_sel       [i]),
        .deq_port_idx_write(x_deq_port_idx_w[i]),
        .resp_valid        (x_resp_valid    [i]),
        .resp_bits         (x_resp_bits     [i]),
        .trans_sel         (x_trans_sel     [i]),
        .o_valid          (e_valid         [i]),
        .o_issued         (e_issued        [i]),
        .o_can_issue      (e_can_issue     [i]),
        .o_cancel_bypass  (e_cancel_bypass [i]),
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
        .o_ety_ld_dep     (y_ld_dep        [i]),
        .o_ety_rc_idx     (y_rc_idx        [i]),
        .o_exu_src        (e_exu_src       [i]),
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
        .o_trans_ld_dep      (t_ld_dep      [i]),
        .o_trans_exu_src     (t_exu_src     [i]),
        .o_trans_use_rc      (t_use_rc      [i]),
        .o_trans_rc_idx      (t_rc_idx      [i])
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
  always_comb
    for (int d = 0; d < NUM_DEQ; d++) begin
      resp_valid_tab[d] = '0;
      resp_bits_tab[d]  = '0;
      for (int k = 0; k < 3; k++) begin
        resp_valid_tab[d][k] = og_valid[k][d];
        resp_bits_tab[d][k]  = OG_HAS_BITS[k] ? og_resp[k][d] : OG_CONST_RESP[k];
      end
      // timer==3 表示「已经过了响应窗口」,永远没有响应
      resp_valid_tab[d][3] = 1'b0;
      resp_bits_tab[d][3]  = OG_CONST_RESP[3];
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
  logic [NUM_ENQ-1:0][NUM_REGSRC-1:0][LD_PIPES-1:0][LD_DEP_W-1:0] c_ld_dep;
  logic [NUM_ENQ-1:0][NUM_REGSRC-1:0][EXU_W-1:0]  c_exu_src;
  logic [NUM_ENQ-1:0][NUM_REGSRC-1:0]             c_use_rc;
  logic [NUM_ENQ-1:0][NUM_REGSRC-1:0][RC_IDX_W-1:0] c_rc_idx;

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
        c_ld_dep[i]       = t_ld_dep[i];
        c_exu_src[i]      = t_exu_src[i];
        c_use_rc[i]       = t_use_rc[i];
        c_rc_idx[i]       = t_rc_idx[i];
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
        `IQE_MUX1H(c_ld_dep[i],       simp_deq_sel_vec[i][k], t_ld_dep[SIMP_BASE+k],       NUM_SIMP)
        `IQE_MUX1H(c_exu_src[i],      simp_deq_sel_vec[i][k], t_exu_src[SIMP_BASE+k],      NUM_SIMP)
        `IQE_MUX1H(c_use_rc[i],       simp_deq_sel_vec[i][k], t_use_rc[SIMP_BASE+k],       NUM_SIMP)
        `IQE_MUX1H(c_rc_idx[i],       simp_deq_sel_vec[i][k], t_rc_idx[SIMP_BASE+k],       NUM_SIMP)
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
      // exuSources / useRegCache 在派遣侧不存在(golden 顶层 io_enq 没有这些端口),
      // regCacheIdx 由派遣给。三者的入队值见薄层。
      x_exu_src[i]      = '0;
      x_use_rc[i]       = enq_use_rc[i];
      x_rc_idx[i]       = enq_rc_idx[i];
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
      `IQE_MUX1H(x_exu_src[e],      final_simp_sel[k][j], t_exu_src[k],      NUM_ENQ)
      `IQE_MUX1H(x_use_rc[e],       final_simp_sel[k][j], t_use_rc[k],       NUM_ENQ)
      `IQE_MUX1H(x_rc_idx[e],       final_simp_sel[k][j], t_rc_idx[k],       NUM_ENQ)
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
      // ★ comp 条目的入口**带** srcLoadDependency —— 条件是变体有 ldCancel
      //   (HAS_LD_DEP),不是"comp 一律不带"。后者是从 VfdivVidiv 外推的错结论,
      //   那个变体是整条通路死了才被 firtool 删掉。实测 14/14,见矩阵 comp_in_ldDep。
      `IQE_MUX1H(x_ld_dep[e],       final_comp_sel[k][j], c_ld_dep[k],       NUM_ENQ)
      `IQE_MUX1H(x_exu_src[e],      final_comp_sel[k][j], c_exu_src[k],      NUM_ENQ)
      `IQE_MUX1H(x_use_rc[e],       final_comp_sel[k][j], c_use_rc[k],       NUM_ENQ)
      `IQE_MUX1H(x_rc_idx[e],       final_comp_sel[k][j], c_rc_idx[k],       NUM_ENQ)
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
      logic [NUM_REGSRC-1:0][LD_PIPES-1:0][LD_DEP_W-1:0] q_ld, s_ld, p_ld;
      logic [NUM_REGSRC-1:0][RC_IDX_W-1:0]               q_rc, s_rc, p_rc;
      logic                              q_cx,        s_cx,        p_cx;

      // enq 段最老
      `IQE_MUX1H(q_rob_flag,  enq_oldest_sel[d][k], y_rob_flag[k],  NUM_ENQ)
      `IQE_MUX1H(q_rob_value, enq_oldest_sel[d][k], y_rob_value[k], NUM_ENQ)
      `IQE_MUX1H(q_fu,        enq_oldest_sel[d][k], e_fu_type[k],   NUM_ENQ)
      `IQE_MUX1H(q_psrc,      enq_oldest_sel[d][k], y_psrc[k],      NUM_ENQ)
      `IQE_MUX1H(q_st,        enq_oldest_sel[d][k], y_src_type[k],  NUM_ENQ)
      `IQE_MUX1H(q_pl,        enq_oldest_sel[d][k], y_payload[k],   NUM_ENQ)
      `IQE_MUX1H(q_ld,        enq_oldest_sel[d][k], y_ld_dep[k],    NUM_ENQ)
      `IQE_MUX1H(q_rc,        enq_oldest_sel[d][k], y_rc_idx[k],    NUM_ENQ)
      `IQE_MUX1H(q_cx,        enq_oldest_sel[d][k], e_cancel_bypass[k], NUM_ENQ)
      // simp 段最老
      `IQE_MUX1H(s_rob_flag,  simp_oldest_sel[d][k], y_rob_flag[SIMP_BASE+k],  NUM_SIMP)
      `IQE_MUX1H(s_rob_value, simp_oldest_sel[d][k], y_rob_value[SIMP_BASE+k], NUM_SIMP)
      `IQE_MUX1H(s_fu,        simp_oldest_sel[d][k], e_fu_type[SIMP_BASE+k],   NUM_SIMP)
      `IQE_MUX1H(s_psrc,      simp_oldest_sel[d][k], y_psrc[SIMP_BASE+k],      NUM_SIMP)
      `IQE_MUX1H(s_st,        simp_oldest_sel[d][k], y_src_type[SIMP_BASE+k],  NUM_SIMP)
      `IQE_MUX1H(s_pl,        simp_oldest_sel[d][k], y_payload[SIMP_BASE+k],   NUM_SIMP)
      `IQE_MUX1H(s_ld,        simp_oldest_sel[d][k], y_ld_dep[SIMP_BASE+k],    NUM_SIMP)
      `IQE_MUX1H(s_rc,        simp_oldest_sel[d][k], y_rc_idx[SIMP_BASE+k],    NUM_SIMP)
      `IQE_MUX1H(s_cx,        simp_oldest_sel[d][k], e_cancel_bypass[SIMP_BASE+k], NUM_SIMP)
      // comp 段最老
      `IQE_MUX1H(p_rob_flag,  comp_oldest_sel[d][k], y_rob_flag[COMP_BASE+k],  NUM_COMP)
      `IQE_MUX1H(p_rob_value, comp_oldest_sel[d][k], y_rob_value[COMP_BASE+k], NUM_COMP)
      `IQE_MUX1H(p_fu,        comp_oldest_sel[d][k], e_fu_type[COMP_BASE+k],   NUM_COMP)
      `IQE_MUX1H(p_psrc,      comp_oldest_sel[d][k], y_psrc[COMP_BASE+k],      NUM_COMP)
      `IQE_MUX1H(p_st,        comp_oldest_sel[d][k], y_src_type[COMP_BASE+k],  NUM_COMP)
      `IQE_MUX1H(p_pl,        comp_oldest_sel[d][k], y_payload[COMP_BASE+k],   NUM_COMP)
      `IQE_MUX1H(p_ld,        comp_oldest_sel[d][k], y_ld_dep[COMP_BASE+k],    NUM_COMP)
      `IQE_MUX1H(p_rc,        comp_oldest_sel[d][k], y_rc_idx[COMP_BASE+k],    NUM_COMP)
      `IQE_MUX1H(p_cx,        comp_oldest_sel[d][k], e_cancel_bypass[COMP_BASE+k], NUM_COMP)

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
      o_deq_ld_dep   [d] = comp_oldest_valid[d] ? p_ld
                         : simp_oldest_valid[d] ? s_ld        : q_ld;
      o_deq_rc_idx   [d] = comp_oldest_valid[d] ? p_rc
                         : simp_oldest_valid[d] ? s_rc        : q_rc;
      // cancelDeqVec 走的是与 deqEntry **同一个**三级选择(Entries.scala §deq else 分支)
      o_cancel_deq   [d] = comp_oldest_valid[d] ? p_cx
                         : simp_oldest_valid[d] ? s_cx        : q_cx;
    end

  // ---------------------------------------------------------------------------
  // §10 阵列状态汇聚输出。
  // ---------------------------------------------------------------------------
  assign o_valid     = e_valid;
  assign o_issued    = e_issued;
  assign o_can_issue = e_can_issue;
  assign o_fu_type   = e_fu_type;
  assign o_data_src  = e_data_src;
  assign o_exu_src   = e_exu_src;

  // io.loadDependency = mergedLoadDependency:同一条目各源的影子按位或
  // (EntryBundles.Status.mergedLoadDependency)。露的是 entry 出口那份(次态)。
  always_comb
    for (int i = 0; i < NUM_ENTRIES; i++)
      for (int q = 0; q < LD_PIPES; q++) begin
        o_ld_dep[i][q] = '0;
        for (int s = 0; s < NUM_REGSRC; s++)
          o_ld_dep[i][q] |= y_ld_dep[i][s][q];
      end

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
  // §11 本核尚未实现的家族维度(给后续变体 owner 的清单,全部有 golden 依据)。
  //   现状:14 个变体分三族(见 verif/ut/Entries_field_matrix/matrix.md),
  //   VEC 族最小的 VfdivVidiv 与 INT 族的 AluCsrFenceDiv 都已经落在本核上,
  //   两者合起来覆盖了「有/无 IQ 唤醒」这条最大的分界。剩下的:
  //
  //   (a) isVecMemIQ:status.vecMem(sqIdx/lqIdx/numLsElem)、blocked 的真逻辑
  //       (!isFirstLoad && isVleff)、按 sqIdx/lqIdx 匹配的 mem 响应。
  //       VlduVstu / VlduVstuVseglduVsegstu 两个变体需要。
  //       本核 blocked 只做「入队装载 + 次态恒 0」。
  //   (b) needFeedBackSqIdx/LqIdx:issueResp 要在 datapath 响应和 mem 响应之间
  //       按 issueTimer 高位切换(Entries.scala §issueRespVec 的 if 分支)。
  //       StaMou / VlduVstu* 需要。
  //   (c) deqFuSame:numDeq=2 且两个口功能相同时,走 subDeqPolicy 的双取
  //       (Entries.scala §deq 的 if (params.deqFuSame))。G1 的 14 个变体顶层
  //       都没有 io_subDeq* 端口,说明这一支当前配置下用不到 —— 但真要用到时
  //       cancelDeqVec 的选择方式也跟着变,不要照抄本核的三级选择。
  //   (d) isAllComp / isAllSimp:单一 othersTransPolicy 的转移分支。
  //       G1 的 14 个变体全是 hasCompAndSimp,故暂不需要。
  //   (e) inVfSchd/inMemSchd 的 dataSources=bypass2 分支
  //       (EntryBundles §srcStatusNext.dataSources 的前两个 if)。
  //       向量/访存族里 readVfRf && hasIQWakeUp 的变体需要;
  //       本核只实现了第三个 else 分支(INT/FP 族走的那条)。
  //   (f) needImm 之外的 SrcStatus 选配项(useRegCache/regCacheIdx 已实现)。
  //
  // ★ 动本核之前先跑 verif/ut/Entries_field_matrix/gen_matrix.py --check ★
  //   那张矩阵是 14 个变体的字段使用画像。为某一个变体「删字段 / 缩位宽 /
  //   把某个状态折成常量」之前,必须先在矩阵里确认其余 13 个变体也不需要它 ——
  //   否则那些还没写的变体会被悄悄做错,而且没人会发现。
  //   本核里已经有两处是这么栽过的(comp 的 deqPortIdx 寄存器、comp 入口的
  //   srcLoadDependency),都是从最小变体 VfdivVidiv 外推出来的,见 §2.6a。
  //
  // ★ 结构照抄,不许"反正值一样就合并" ★
  //   「值恒等」不等于「可证等价」:FM 比的是结构对应的比较点,golden 里看起来
  //   冗余的重复结构一旦被合并,仿真绝对看不出来,FM 会直接判一堆端口失配。
  //   本核逐条对着 golden 保持了分份(改核时别顺手合掉):
  //     * issueResp 的 4 档常量表:golden **每个发射口各一张**(_GEN_15/16 与
  //       _GEN_17/18),本核的 resp_valid_tab/resp_bits_tab 也按口分份。
  //       生成器里有交叉核对,确认两张表形状确实一致才敢共用一份参数。
  //     * exuSources:golden 每个源、每条通路(当拍 / 延迟窗口 / commonOut)
  //       各例化一个 UIntCompressor,本核对应三段独立的 always_comb,没有合并。
  //     * WB / IQ 唤醒命中向量、srcLoadCancel、srcLoadTransCancel:全部按源分份。
  //     * mergedLoadDependency 是**golden 自己**就按位或过的(Status.mergedLoad-
  //       Dependency),不是本核合的。
  //   已知且**有意**的结构差异只有一处:负载。golden 是「每字段一个寄存器」,
  //   本核是一根扁平向量 —— 这一处靠 verif/ut/<变体>/fm_pins_pre.tcl 逐位钉名,
  //   不 dont_verify、不黑盒;钉错会让 FM 比失败,不会被掩盖。
  //
  // ★ 复位域照抄 ★
  //   golden 只有 validReg / enqDelayValidReg 带复位,entryReg_* 整批不复位。
  //   本核一致。把不复位写成全复位是真 bug,而 elaborate/lint 都不会响 ——
  //   所以 UT 两轮都要跑:`make run` (+vcs+initreg+random) 与 `make run-initreg0`。
  // ---------------------------------------------------------------------------

endmodule : xs_iq_entries_core
