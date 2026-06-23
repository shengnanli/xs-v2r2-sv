// ============================================================================
// backend_pkg —— 香山 V2R2 后端顶层（Backend）类型与参数包
// ----------------------------------------------------------------------------
// 设计意图来源：src/main/scala/xiangshan/backend/Backend.scala
//   （class Backend / class BackendInlinedImp）
//
// Backend 是后端「最高层」总集成：把控制平面（CtrlBlock）、四个调度器
// （intScheduler / fpScheduler / vfScheduler / memScheduler = Scheduler×4）、
// 数据通路（DataPath）、旁路网络（BypassNetwork）、三个执行容器
// （intExuBlock / fpExuBlock / vfExuBlock = ExuBlock×3）、写回数据通路
// （WbDataPath）、写回功能单元忙表（WbFuBusyTable）、向量异常合并
// （VecExcpDataMergeModule）、性能监控（HPerfMonitor / PFEvent）、og2 向量
// 旁路（Og2ForVector）以及若干流水连接（NewPipelineConnectPipe / DelayN）组装
// 起来。这些子模块**已单独重写完成**，对本层是 golden 黑盒（UT/FM 两侧共用）。
//
// 本层真正属于「顶层 glue」的可读逻辑（都在 xs_Backend_core 里用 struct/
// function/always 表达，绝不抽进 svh 套壳）：
//   1. 唤醒总线打拍：iqWakeUpMappedBundleDelayed —— 把四调度器的 wakeupVec 各路
//      RegNext 一拍后回送给调度器（消除唤醒-选择组合环的时序压力）。
//   2. 写回打拍：int/fp/vf/v0/vlWriteBackDelayed —— wbDataPath 的五个写回端口经
//      RegNext(wen/typeWen) + RegEnable(addr, wen) 延迟一拍送各调度器。
//   3. CSR<->Mem 握手打拍：instrAddrTransType / msiInfo / clintTime / l2FlushDone /
//      externalInterrupt 等在 Backend 边界 RegNext，去抖/对齐流水。
//   4. mem 发射超时计数：issueTimeout —— 检测 bypass->mem 执行单元的发射端口
//      连续 N 拍 valid 未被 ready 吃掉（卡死）的 4-bit 饱和计数。
//   5. vsetvl vtype 锁存：vsetvlVType —— int/vf 两路 vtype 写回二选一锁存，供
//      ctrlBlock 提交比对。
//   6. 杂项打拍：debugVl_s1 / topDownInfo（noUopsIssued/l1Miss）/ pfevent CSR 分发。
//   7. 旁路->执行单元的 flush 判定：每路 out 用 robIdx 与 ctrlBlock flush 比较，
//      算 needFlush（flushItself/older 判定），其中公用的拼接子式给可读别名。
//
// 端口极宽（1230 个扁平端口，多为子模块直通），故端口表与 45 个子模块例化连线
// 落在 backend_ports.svh / backend_inst.svh；本包只放架构常量与少量聚合类型。
// ============================================================================
package backend_pkg;

  // ----- 顶层宽度参数（昆明湖 V2R2 默认配置，与 golden 端口宽度一致）-----
  localparam int RenameWidth   = 6;   // 重命名 / 派遣宽度
  localparam int RobIdxW       = 8;   // RobPtr value 位宽（不含 flag）
  localparam int RobPtrW       = 9;   // {flag, value} 拼接位宽（flushItself 比较用）

  // 唤醒总线打拍路数：int4 + fp3 + mem3 = 10（与 golden REG_0..REG_9 一致）。
  // 各路异构（int/mem 带 rfWen/rcDest/loadDependency，fp 带 fpWen），结构按并集取字段。
  localparam int WakeupDelayedNum = 10;

  // 写回打拍各域路数（与 wbDataPath.io.toXxxPreg 端口数一致）。
  localparam int IntWbDelayedNum = 5;  // toIntPreg 0..4（golden 缺第 3 路，连线时跳过）
  localparam int FpWbDelayedNum  = 6;  // toFpPreg  0..5
  localparam int VfWbDelayedNum  = 6;  // toVfPreg  0..5
  localparam int V0WbDelayedNum  = 6;  // toV0Preg  0..5
  localparam int VlWbDelayedNum  = 4;  // toVlPreg  0..3

  localparam int PregIdxW = 8;   // 物理寄存器号最大位宽（int/fp/vf 8 位）
  localparam int V0IdxW   = 5;   // v0/vl 物理号位宽
  localparam int LoadDepW = 2;   // loadDependency 每项位宽
  localparam int RcDestW  = 5;   // 寄存器缓存目的号位宽

  // mem 发射超时计数器：5 个发射端口（Lda0/1/2 + Vldu0/1），4-bit 饱和。
  localparam int IssueTimeoutNum = 5;
  localparam int IssueTimeoutW   = 4;

  // ----- 唤醒打拍单条目（IssueQueueIQWakeUpBundle 的打拍子集）-----
  // golden 各路只锁存实际用到的字段；这里取并集，缺省字段保持 0，逐字段连线。
  typedef struct packed {
    logic                  rfWen;            // 写整型寄存器
    logic                  fpWen;            // 写浮点寄存器
    logic                  is0Lat;           // 0 周期延迟唤醒
    logic [PregIdxW-1:0]   pdest;            // 目的物理寄存器号
    logic [RcDestW-1:0]    rcDest;           // 寄存器缓存目的号
    logic [LoadDepW-1:0]   loadDependency_0; // load 依赖向量(3 项)
    logic [LoadDepW-1:0]   loadDependency_1;
    logic [LoadDepW-1:0]   loadDependency_2;
  } wakeup_delayed_t;

  // ----- 写回打拍单条目（addr 位宽随域不同，须分别声明以与子模块端口位宽精确对齐）-----
  // golden 对每路写回锁存 wen(RegNext) / typeWen(RegNext) / addr(RegEnable by wen)。
  // typeWen 含义随域不同：int=intWen, fp=fpWen, vf=vecWen, v0=v0Wen, vl=vlWen。
  // addr 位宽：int/fp=8(物理整型/浮点号)、vf=7(向量号)、v0/vl=5。
  localparam int VfPregW = 7;   // vf 物理寄存器号位宽
  typedef struct packed {       // int / fp 域（addr 8 bit）
    logic                wen;
    logic                typeWen;
    logic [PregIdxW-1:0] addr;
  } wb_delayed8_t;
  typedef struct packed {       // vf 域（addr 7 bit）
    logic                wen;
    logic                typeWen;
    logic [VfPregW-1:0]  addr;
  } wb_delayed7_t;
  typedef struct packed {       // v0 / vl 域（addr 5 bit）
    logic                wen;
    logic                typeWen;
    logic [V0IdxW-1:0]   addr;
  } wb_delayed5_t;

  // ----- vsetvl 锁存的 vtype 字段 -----
  typedef struct packed {
    logic       illegal;
    logic       vma;
    logic       vta;
    logic [1:0] vsew;
    logic [2:0] vlmul;
  } vtype_lite_t;

endpackage : backend_pkg
