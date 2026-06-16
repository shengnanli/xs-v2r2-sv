// =============================================================================
//  exceptionbuffer_pkg —— Load/Store 访存异常缓冲共享类型与年龄比较函数
// -----------------------------------------------------------------------------
//  设计意图来源（人写 Chisel）：
//      src/main/scala/xiangshan/mem/lsqueue/LoadExceptionBuffer.scala (class LqExceptionBuffer)
//      src/main/scala/xiangshan/mem/lsqueue/StoreQueue.scala          (class StoreExceptionBuffer)
//
//  LqExceptionBuffer 与 StoreExceptionBuffer 结构高度同构：都收集多个访存流水端口
//  在 S2 报上来的“带异常的访存请求”，按 robIdx（+uopIdx）选出**最老**的一条，锁存进
//  单条 req 寄存器，持续向 CSR/ROB 汇报该异常的虚/物理地址等信息。本 pkg 抽出两者
//  公共的 rob 指针类型与“年龄比较 / 最老选择”纯函数，两个核共用。
//
//  ── 年龄语义（CircularQueuePtr）─────────────────────────────────────────────
//    robIdx = {flag, value}：flag 是环形队列回绕标志。
//      isAfter(a,b)     : a 比 b **更年轻**（在 b 之后进入流水），= flag^ ^ (value> )
//      isBefore(a,b)    : a 比 b **更老**
//      isNotBefore(a,b) : a 不比 b 老（更年轻或同一条）
//    “最老”= robIdx 最小（最先进入 ROB）。同 robIdx 时再比 uopIdx（向量指令的微操作序号），
//    uopIdx 大的更靠后 → 选 uopIdx 小的为老。
// =============================================================================
package exceptionbuffer_pkg;

  // ROB 指针位宽（RobSize=256 → value 8 bit）。flag 1 bit 用于环形回绕判向。
  localparam int ROB_VALUE_W = 8;
  localparam int UOPIDX_W    = 7;   // 向量微操作序号位宽

  // ---------------------------------------------------------------------------
  //  访存异常码（RISC-V ExceptionNO，见 xiangshan/package.scala）
  //  两个缓冲各自只关心 6 个相关异常位（selectByFu(LduCfg)/selectByFu(StaCfg)）：
  //    Lq（load）  位 {3,4,5,13,19,21}
  //    Store       位 {3,6,7,15,19,23}
  //  入队判定只需 “这 6 位 |orR”（是否带异常），故核里把它们压成一个 6-bit excVec；
  //  本 enum 仅为读者标注每一位的物理含义（按 wrapper 打包顺序 {bit5..bit0}）。
  // ---------------------------------------------------------------------------
  // load 侧 6 位异常的语义（excVec[5:0] 对应位）
  typedef enum logic [2:0] {
    LDU_EXC_BREAKPOINT       = 3'd0,  // ExceptionNO.breakPoint         (bit 3)
    LDU_EXC_ADDR_MISALIGNED  = 3'd1,  // loadAddrMisaligned            (bit 4)
    LDU_EXC_ACCESS_FAULT     = 3'd2,  // loadAccessFault               (bit 5)
    LDU_EXC_PAGE_FAULT       = 3'd3,  // loadPageFault                 (bit 13)
    LDU_EXC_HARDWARE_ERROR   = 3'd4,  // hardwareError                 (bit 19)
    LDU_EXC_GUEST_PAGE_FAULT = 3'd5   // loadGuestPageFault            (bit 21)
  } ldu_exc_e;
  // store 侧 6 位异常的语义（excVec[5:0] 对应位）
  typedef enum logic [2:0] {
    STA_EXC_BREAKPOINT       = 3'd0,  // breakPoint                    (bit 3)
    STA_EXC_ADDR_MISALIGNED  = 3'd1,  // storeAddrMisaligned           (bit 6)
    STA_EXC_ACCESS_FAULT     = 3'd2,  // storeAccessFault              (bit 7)
    STA_EXC_PAGE_FAULT       = 3'd3,  // storePageFault                (bit 15)
    STA_EXC_HARDWARE_ERROR   = 3'd4,  // hardwareError                 (bit 19)
    STA_EXC_GUEST_PAGE_FAULT = 3'd5   // storeGuestPageFault           (bit 23)
  } sta_exc_e;

  // ROB 指针：{flag, value}，CircularQueuePtr
  typedef struct packed {
    logic                   flag;
    logic [ROB_VALUE_W-1:0] value;
  } rob_ptr_t;

  // ---------------------------------------------------------------------------
  //  年龄比较（与 Chisel HasCircularQueuePtrHelper 逐位一致）
  // ---------------------------------------------------------------------------
  // isAfter(a,b)：a 比 b 更年轻。等价 Chisel: a.flag ^ b.flag ^ (a.value > b.value)
  function automatic logic rob_is_after(input rob_ptr_t a, input rob_ptr_t b);
    return a.flag ^ b.flag ^ (a.value > b.value);
  endfunction

  // isNotBefore(a,b)：a 不比 b 老（更年轻或相等）。Chisel: a.flag ^ b.flag ^ (a.value >= b.value)
  function automatic logic rob_is_not_before(input rob_ptr_t a, input rob_ptr_t b);
    return a.flag ^ b.flag ^ (a.value >= b.value);
  endfunction

  // robIdx 完全相等（flag 与 value 都相等）
  function automatic logic rob_eq(input rob_ptr_t a, input rob_ptr_t b);
    return (a.flag == b.flag) && (a.value == b.value);
  endfunction

  // ---------------------------------------------------------------------------
  //  redirect 冲刷判定（uop.robIdx.needFlush(redirect)）
  //    与 Chisel RobPtr.needFlush 一致：
  //      needFlush = redirect.valid &
  //                  (redirect.level==flush(自身也冲刷) ? !isBefore(rob,redirectRob)
  //                                                     :  isAfter (rob,redirectRob))
  //    展开（golden firtool 形式）：
  //      redirect.valid &
  //        ( (level & rob==redirectRob)            // level=1（flushItself）且同条
  //          | isAfter(rob, redirectRob) )         // 或严格更年轻
  //    注：isBefore 的取反在“相等”时由 level 那一项补上，故按位等价于下式。
  // ---------------------------------------------------------------------------
  function automatic logic rob_need_flush(
    input logic     redirect_valid,
    input logic     redirect_level,
    input rob_ptr_t rob,
    input rob_ptr_t redirect_rob
  );
    logic same_robidx, strictly_after;
    same_robidx    = rob_eq(rob, redirect_rob);
    strictly_after = rob_is_after(rob, redirect_rob);
    return redirect_valid & ((redirect_level & same_robidx) | strictly_after);
  endfunction

  // ---------------------------------------------------------------------------
  //  “两两选最老”原语：在 (va,a) 与 (vb,b) 间选出更老的一条
  //    pick_b 条件（即 a 比 b 年轻、应丢弃 a 选 b）：
  //      va && vb && ( isAfter(a,b) || (robIdx 等价 && a.uopIdx > b.uopIdx) )
  //    其中“robIdx 等价”：Lq 用严格相等 rob_eq；Store 用 isNotBefore（>=）。
  //    用 eq_is_not_before 选择两种语义（Store=1 用 >=，Lq=0 用 ==）。
  //    当只有一方 valid 时选 valid 的那个；都无效时缺省选 a（与 golden 一致）。
  // ---------------------------------------------------------------------------
  function automatic logic older_pick_b(
    input logic                  va,
    input logic                  vb,
    input rob_ptr_t              ra,
    input rob_ptr_t              rb,
    input logic [UOPIDX_W-1:0]   ua,
    input logic [UOPIDX_W-1:0]   ub,
    input logic                  eq_is_not_before
  );
    logic a_younger, tie;
    // robIdx 维度：a 比 b 年轻
    a_younger = rob_is_after(ra, rb);
    // robIdx 平手维度：Store 用 isNotBefore（含相等及 flag 异常情形），Lq 用严格相等
    tie       = eq_is_not_before ? rob_is_not_before(ra, rb) : rob_eq(ra, rb);
    // 两方都 valid：按年龄选；否则选 valid 的一方（va? a : b）
    return va & vb ? (a_younger | (tie & (ua > ub)))
                   : ~va;   // va=1→选 a(=0)，va=0→选 b(=1)
  endfunction

endpackage
