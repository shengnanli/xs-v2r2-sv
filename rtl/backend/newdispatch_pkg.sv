// =============================================================================
// newdispatch_pkg —— 香山 V2R2(昆明湖) 派遣级公共参数/类型 (可读重写)
// -----------------------------------------------------------------------------
// 设计源:src/main/scala/xiangshan/backend/dispatch/NewDispatch.scala
//
// 派遣级(NewDispatch / Dispatch2Iq)位于「重命名(Rename)」与「发射队列
// (IssueQueue/Scheduler)」之间。它每拍接收最多 RenameWidth=6 条重命名后的 uop,
// 完成三件事:
//   1. 查 BusyTable / VlBusyTable / RegCacheTagTable —— 得到各源操作数的就绪
//      (srcState)与寄存器缓存命中信息;
//   2. 路由(routing)—— 按 fuType 把每条 uop 送到「能执行该指令」的发射队列。
//      对于「多个同质 EXU 共享同种功能」的情况(如 4 个 ALU),做负载均衡:挑当前
//      表项数最少(IQValidNum 最小)的那个 IQ,见 sel_min_iq;
//   3. 容量检查 / 反压(back-pressure)—— 综合 发射队列 ready、LSQ(load/store
//      queue)流(flow)数限额、ROB 可入队、按序约束(blockBackward/waitForward),
//      决定每条 uop 能否真正派遣,并反压 ready 给 Rename。
//
// 本包定义:配置相关的拓扑参数、就绪查询用的寄存器类型枚举、以及单步 FSM 状态。
// 大量「展平的 DynInst 字段」在 body.svh 里逐端口直通/选择,不在此聚合成 struct
// (DynInst 有 ~150 字段,异构发射队列各取子集,逐字段处理反而更贴近设计且可读)。
// =============================================================================
package newdispatch_pkg;

  // ---------------------------------------------------------------------------
  // 1. 配置拓扑参数(本 BackendParams = KunMingHu 默认推导而来,见 Scala 顶部 println)
  // ---------------------------------------------------------------------------
  localparam int RENAME_WIDTH  = 6;   // 每拍最多派遣的 uop 数
  localparam int NUM_IQ        = 17;  // 发射队列个数(allIssueParams,std IQ 已过滤)
  localparam int NUM_ENQ       = 2;   // 每个 IQ 的 enq 端口数
  localparam int IQ_ENQ_SUM    = 34;  // 全部 IQ enq 端口之和(toIssueQueues 端口数)
  localparam int EXU_NUM       = 23;  // EXU 个数(IQValidNumVec 宽度)

  localparam int NUM_REG_SRC   = 5;   // uop 最大源操作数(int/fp 含 std 补位后)
  localparam int NUM_REG_TYPE  = 5;   // 寄存器堆类型数:int/fp/vec/v0/vl

  localparam int PREG_W        = 8;   // 物理寄存器号位宽
  localparam int LDEP_W        = 2;   // srcLoadDependency 每元素位宽
  localparam int LDEP_N        = 3;   // srcLoadDependency 每源的 load 距离向量长度
  localparam int RC_TAG_W      = 5;   // RegCache tag(regCacheIdx)位宽

  // LSQ 流数限额(每拍最多可入队的 load/store/vload 流数,见 Scala numLoadDeq 等)
  localparam int NUM_LOAD_DEQ      = 6;   // LSQLdEnqWidth
  localparam int NUM_STORE_AMO_DEQ = 6;   // LSQStEnqWidth
  localparam int NUM_VLOAD_DEQ     = 3;   // LoadPipelineWidth

  // ---------------------------------------------------------------------------
  // 2. 寄存器类型枚举(busyTables 的索引顺序:int/fp/vec/v0/vl)
  // ---------------------------------------------------------------------------
  // 每个源操作数按其 srcType 落到这 5 类之一,去对应 BusyTable 查 ready。
  typedef enum logic [2:0] {
    REGT_INT = 3'd0,
    REGT_FP  = 3'd1,
    REGT_VEC = 3'd2,
    REGT_V0  = 3'd3,
    REGT_VL  = 3'd4
  } reg_type_e;

  // ---------------------------------------------------------------------------
  // 3. 单步(single-step)有限状态机状态(见 Scala s_holdRobidx / s_updateRobidx)
  // ---------------------------------------------------------------------------
  // 调试单步:dret 之后只允许提交一条机器指令,随后据 singlestep 异常进入 debug 模式。
  //   S_UPDATE_ROBIDX : 正常,记录可提交到的 robIdx;
  //   S_HOLD_ROBIDX   : 已锁存一条指令的 robIdx,后续指令打 singleStep 标志(被挡)。
  typedef enum logic {
    S_HOLD_ROBIDX   = 1'b0,
    S_UPDATE_ROBIDX = 1'b1
  } sstep_state_e;

  // ---------------------------------------------------------------------------
  // 3b. 派遣决策记录(一条 uop 的反压/路由结论聚合)
  // ---------------------------------------------------------------------------
  // 把一条 uop 的「能否派遣」四个条件聚成一个 bundle,便于阅读与调试:
  //   allow_dispatch  : LSQ 流数够(保守上界 vs free count)
  //   not_block_by_iq : 目标 IQ 当拍未超容量
  //   can_actual_out  : 按序约束(waitForward/blockBackward)+ ROB 可入队
  //   lsq_can_accept  : LSQ 整体可入队
  // ready = 四者与;fire = ready & valid。
  typedef struct packed {
    logic allow_dispatch;
    logic not_block_by_iq;
    logic can_actual_out;
    logic lsq_can_accept;
  } dispatch_gate_t;

  // 由四个条件合成 ready(与 NewDispatch.scala fromRename(i).ready 一致)。
  function automatic logic nd_dispatch_ready(input dispatch_gate_t g);
    return g.allow_dispatch & g.not_block_by_iq & g.can_actual_out & g.lsq_can_accept;
  endfunction

  // ---------------------------------------------------------------------------
  // 4. SrcType 编码辅助(srcType 为 4bit;最低位区分 int/imm 这一族,见 SrcType.scala)
  // ---------------------------------------------------------------------------
  // 在派遣里只需判断少数几类:
  //   isXp(int/像-pointer): srcType == 0   (reg 整数源,bit0==0 且 ==0)
  //   实际 golden 用 srcType[0] 表示「int 类(走 int BusyTable / rcTag)」。
  // golden 在 ignoreOldVd 时把 srcType_2 改写为 4'h0(SrcType.no 在本编码即 0)。
  localparam logic [3:0] SRCTYPE_NO_VAL = 4'h0;

  // ---------------------------------------------------------------------------
  // 5. 纯函数(派遣级用到的几处离散判定)
  // ---------------------------------------------------------------------------
  // 向量 old-vd 可忽略:vl 已就绪且非零、不依赖 old_vd,且(尾被 mask 或整体被 mask)。
  //   ignoreTail  = is_vlmax & (vm!=0 | vma) & ~isWritePartVd
  //   ignoreWhole = (vm!=0 | vma) & vta
  //   见 NewDispatch.scala ignoreOldVd 与 docs §2.1。
  function automatic logic nd_ignore_old_vd(
      input logic vl_resp, input logic vl_nonzero, input logic vl_vlmax,
      input logic isDependOldVd, input logic isWritePartVd,
      input logic vta, input logic vma, input logic vm);
    logic mask_active, ignore_tail, ignore_whole;
    mask_active  = vm | vma;                 // golden:(vm!=0 | vma),vm 单 bit
    ignore_tail  = vl_vlmax & mask_active & ~isWritePartVd;
    ignore_whole = mask_active & vta;
    return vl_resp & vl_nonzero & ~isDependOldVd & (ignore_tail | ignore_whole);
  endfunction

  // 向量访存「unit-stride」判定:fuOpType[6:5]==0 且 (fuOpType[8] ^ fuOpType[7])。
  // 入参为 fuOpType[8:5](4bit:bit3=[8] bit2=[7] bit1=[6] bit0=[5])。
  function automatic logic nd_is_unit_stride(input logic [3:0] op_hi);
    return (op_hi[1:0] == 2'h0) & (op_hi[3] ^ op_hi[2]);
  endfunction

endpackage
