// 手写核 + 自动生成机械连线(scripts/gen_backend.py 接管 ports/decls/inst/wrapper/stub/UT)。
// =====================================================================
// xs_Backend_core —— 香山 V2R2 后端最高层可读核(capstone)。
//
// Backend(src/main/scala/xiangshan/backend/Backend.scala)是后端总集成:把
// CtrlBlock / Scheduler×4(int/fp/vf/mem) / DataPath / BypassNetwork /
// ExuBlock×3(int/fp/vf) / WbDataPath / WbFuBusyTable / VecExcpDataMergeModule /
// HPerfMonitor / PFEvent / Og2ForVector / NewPipelineConnectPipe×N / DelayN×2
// 共 45 个实例例化并互联。**全部子模块已单独重写完成,在本顶层作 golden 黑盒例化**。
//
// 顶层自身的真逻辑 = 模块间互联布线(在 backend_inst.svh,纯例化连线)+ 少量
// 顶层 glue。所有 glue 都在本核里用 struct/always 可读重写(见下方 always 区与
// backend_logic.svh),绝不抽进 svh 套壳:
//   ① 唤醒总线打拍 wakeupDelayed —— 四调度器 wakeupVec 各路 RegNext 回送。
//   ② 写回打拍 {int,fp,vf,v0,vl}WbDelayed —— wbDataPath 五写回端口 RegNext+RegEnable。
//   ③ CSR<->Mem 边界打拍 —— instrTransType/msiInfo/clintTime/l2FlushDone/extInt。
//   ④ mem 发射超时 issueTimeout —— 4-bit 饱和计数,检测发射卡死。
//   ⑤ vsetvl vtype 锁存 vsetvlVType —— int/vf vtype 二选一。
//   ⑥ 杂项打拍 —— debugVl/topDownInfo(l1Miss/noUopsIssued)/pfevent CSR 分发。
//   ⑦ flush 判定公用拼接别名 flushRobIdxFull/robDeqPtrFull。
//
// 类型/参数见 backend_pkg.sv;子模块黑盒输出/互联网见 backend_decls.svh;
// 45 子模块例化+引脚连核内具名信号见 backend_inst.svh。
// =====================================================================
import backend_pkg::*;

module xs_Backend_core (
  input clock,
  input reset,
`include "backend_ports.svh"
);

  // ===================================================================
  // glue 寄存器/聚合信号声明(被 always 块驱动,被 inst.svh 引脚消费)
  // ===================================================================

  // ① 唤醒总线打拍:int4(REG_0..3) + fp3(REG_4..6) + mem3(REG_7..9)=10 路。
  //    各路 RegNext 各调度器 wakeupVec 对应路,回送给调度器消除唤醒环时序压力。
  wakeup_delayed_t wakeupDelayed [WakeupDelayedNum];

  // ② 写回打拍:每路 wen/typeWen 走 RegNext,addr 走 RegEnable(by wen)。
  //    送各调度器的 xxWriteBackDelayed 端口(见 inst.svh)。
  wb_delayed8_t intWbDelayed [IntWbDelayedNum];  // toIntPreg(addr 8b,golden 缺第 3 路)
  wb_delayed8_t fpWbDelayed  [FpWbDelayedNum];   // toFpPreg (addr 8b)
  wb_delayed7_t vfWbDelayed  [VfWbDelayedNum];   // toVfPreg (addr 7b)
  wb_delayed5_t v0WbDelayed  [V0WbDelayedNum];   // toV0Preg (addr 5b)
  wb_delayed5_t vlWbDelayed  [VlWbDelayedNum];   // toVlPreg (addr 5b)

  // ③ CSR<->Mem 边界打拍。
  typedef struct packed {
    logic bare, sv39, sv39x4, sv48, sv48x4;
  } instr_trans_type_t;
  instr_trans_type_t instrTransTypeR;            // RegNext(intExuBlock.csrio.instrAddrTransType)

  logic        msiInfoValidR;                    // RegNext(io_fromTop_msiInfo_valid)
  logic [10:0] msiInfoBitsR;                     // RegEnable(bits, valid)
  logic        clintTimeValidR;
  logic [63:0] clintTimeBitsR;
  logic        l2FlushDoneR;

  typedef struct packed {
    logic mtip, msip, meip, seip, debug, nmi31, nmi43;
  } ext_int_t;
  ext_int_t    extIntR;                          // RegNext(io_fromTop_externalInterrupt_*)

  // ④ mem 发射超时计数:5 端口(Lda0/1/2 + Vldu0/1)。
  //    每端口:发射 valid 但未被 mem.ready 吃掉(out_fire=0)且非新发射(in_fire),
  //    则计数;计满(全 1)且仍卡 -> issueTimeout 置 1 通知调度器。
  logic [IssueTimeoutW-1:0] issueTimeoutCnt [IssueTimeoutNum];
  logic memIssueFire    [IssueTimeoutNum];       // out_valid & ~(mem.ready & out_valid) 实为 out 未吃
  logic memIssueOutFire [IssueTimeoutNum];       // in_ready & toExus.valid:新一拍发射
  logic issueTimeout    [IssueTimeoutNum];       // 计满且卡死

  // ⑤ vsetvl vtype 锁存(int/vf 二选一)。
  vtype_lite_t vsetvlVType;

  // ⑥ 杂项打拍。
  logic       topDownL1MissR;                    // RegNext(io_topDownInfo_l1Miss)
  logic       noUopsIssuedR;                     // RegNext(dataPath.topDownInfo.noUopsIssued)
  logic [7:0] debugVlS1R;                        // RegNext(dataPath.diffVl)
  typedef struct packed {
    logic        valid;
    logic [11:0] addr;
    logic [63:0] data;
  } pfevent_csr_t;
  pfevent_csr_t pfeventCsrR;                     // RegNext(intExuBlock.customCtrl.distribute_csr.w)

  // hartId 零扩展 / DFT 时钟门控使能(直通别名)。
  wire [7:0] hartIdFull = {2'h0, io_fromTop_hartId};
  wire       dftCgen    = io_dft_cgen;

  // ===================================================================
  // 子模块黑盒输出/互联网声明(供上面 glue 与 inst.svh 引脚消费)
  // ===================================================================
`include "backend_decls.svh"

  // ⑦ flush 判定公用拼接别名(纯组合,被 inst.svh 多路 flush 比较引用)。
  //    须在 backend_decls.svh 之后(引用其中声明的 _inner_ctrlBlock_* 网)。
  //    flushRobIdxFull = {ctrlBlock.flush.robIdx.flag, .value}(9 bit);
  //    robDeqPtrFull   = {ctrlBlock.robDeqPtr.flag, .value}(9 bit)。
  wire [RobPtrW-1:0] flushRobIdxFull =
      {_inner_ctrlBlock_io_toExuBlock_flush_bits_robIdx_flag,
       _inner_ctrlBlock_io_toExuBlock_flush_bits_robIdx_value};
  wire [RobPtrW-1:0] robDeqPtrFull =
      {_inner_ctrlBlock_io_robio_robDeqPtr_flag,
       _inner_ctrlBlock_io_robio_robDeqPtr_value};

  // ===================================================================
  // ④ mem 发射超时:组合判定(端口 i:Lda0/1/2=bypassMem2/3/4,Vldu0/1=5/6)
  //   golden:_<2i>=mem.ready & out_valid(吃掉);issueTimeout_T=out_valid&~吃掉;
  //          _<2i+1>=in_ready & toExus.valid(新发射);饱和计满且卡 -> 置位。
  // ===================================================================
  // Lda0 <- bypassNetwork2toMemExus_2,mem.issueLda_0
  assign memIssueFire[0]    = io_mem_issueLda_0_ready & _inner_bypassNetwork2toMemExus_2_io_out_valid;
  wire issueStuck0          = _inner_bypassNetwork2toMemExus_2_io_out_valid & ~memIssueFire[0];
  assign memIssueOutFire[0] = _inner_bypassNetwork2toMemExus_2_io_in_ready
                            & _inner_bypassNetwork_io_toExus_mem_2_0_valid;
  assign issueTimeout[0]    = ~memIssueOutFire[0] & issueStuck0 & (&issueTimeoutCnt[0]);
  // Lda1 <- bypassNetwork2toMemExus_3,mem.issueLda_1
  assign memIssueFire[1]    = io_mem_issueLda_1_ready & _inner_bypassNetwork2toMemExus_3_io_out_valid;
  wire issueStuck1          = _inner_bypassNetwork2toMemExus_3_io_out_valid & ~memIssueFire[1];
  assign memIssueOutFire[1] = _inner_bypassNetwork2toMemExus_3_io_in_ready
                            & _inner_bypassNetwork_io_toExus_mem_3_0_valid;
  assign issueTimeout[1]    = ~memIssueOutFire[1] & issueStuck1 & (&issueTimeoutCnt[1]);
  // Lda2 <- bypassNetwork2toMemExus_4,mem.issueLda_2
  assign memIssueFire[2]    = io_mem_issueLda_2_ready & _inner_bypassNetwork2toMemExus_4_io_out_valid;
  wire issueStuck2          = _inner_bypassNetwork2toMemExus_4_io_out_valid & ~memIssueFire[2];
  assign memIssueOutFire[2] = _inner_bypassNetwork2toMemExus_4_io_in_ready
                            & _inner_bypassNetwork_io_toExus_mem_4_0_valid;
  assign issueTimeout[2]    = ~memIssueOutFire[2] & issueStuck2 & (&issueTimeoutCnt[2]);
  // Vldu0 <- bypassNetwork2toMemExus_5,mem.issueVldu_0
  assign memIssueFire[3]    = io_mem_issueVldu_0_ready & _inner_bypassNetwork2toMemExus_5_io_out_valid;
  wire issueStuck3          = _inner_bypassNetwork2toMemExus_5_io_out_valid & ~memIssueFire[3];
  assign memIssueOutFire[3] = _inner_bypassNetwork2toMemExus_5_io_in_ready
                            & _inner_bypassNetwork_io_toExus_mem_5_0_valid;
  assign issueTimeout[3]    = ~memIssueOutFire[3] & issueStuck3 & (&issueTimeoutCnt[3]);
  // Vldu1 <- bypassNetwork2toMemExus_6,mem.issueVldu_1
  assign memIssueFire[4]    = io_mem_issueVldu_1_ready & _inner_bypassNetwork2toMemExus_6_io_out_valid;
  wire issueStuck4          = _inner_bypassNetwork2toMemExus_6_io_out_valid & ~memIssueFire[4];
  assign memIssueOutFire[4] = _inner_bypassNetwork2toMemExus_6_io_in_ready
                            & _inner_bypassNetwork_io_toExus_mem_6_0_valid;
  assign issueTimeout[4]    = ~memIssueOutFire[4] & issueStuck4 & (&issueTimeoutCnt[4]);

  // ===================================================================
  // 顶层 glue 时序逻辑(从 Backend.scala 设计意图重写)
  // ===================================================================
`include "backend_logic.svh"

  // ===================================================================
  // 45 子模块黑盒例化 + 引脚连核内具名信号(纯机械,gen_backend.py 生成)
  // ===================================================================
`include "backend_inst.svh"

  // ===================================================================
  // 顶层 io 输出驱动(208 条 assign,子模块输出直连 io;纯连线)
  // ===================================================================
`include "backend_outassign.svh"

endmodule
