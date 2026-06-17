// =============================================================================
// compressunit_pkg —— 香山 V2R2(昆明湖) ROB 压缩单元 CompressUnit 的类型/常量
// -----------------------------------------------------------------------------
// 对应 Scala 源:xiangshan.backend.rename.CompressUnit。
//
// 【背景:为什么要"ROB 压缩"】
//   重命名阶段每拍最多吞 RenameWidth(=6) 条指令。某些**连续**且"可压缩"
//   (canRobCompress)的指令(典型是被 fusion 融合后的同类指令、或同一宏指令
//   拆出的微操作),可以共享**一个 ROB 表项**提交,从而扩大有效指令窗口
//   (思路见模块头引用的 CROB 论文)。本单元在重命名前算出"这 6 条里哪些能
//   压成一组、每组多大、组的最后一条是谁(谁占 ROB 表项)"。
//
// 【它输出什么(对每条 lane i ∈ 0..5)】
//   canCompressVec[i] : 该 lane 本身是否"可参与压缩"(有效、非 fusion、是末 uop、
//                       无异常/非调试触发、且 canRobCompress)。
//   needRobFlags[i]   : 该 lane 是否需要**独占一个 ROB 表项**。一个压缩组里只有
//                       "最后一条可压缩指令"置 1;组内其余置 0(并入末条的表项)。
//                       不可压缩指令各自置 1。
//   instrSizes[i]     : 包含该 lane 的压缩组大小(可压缩则=连续 1 的游程长度;
//                       不可压缩则=1)。
//   masks[i]          : 6 位 one-hot/多热,标出"和该 lane 同组"的所有 lane。
//                       不可压缩 lane:仅自身位为 1;可压缩 lane:整段游程为 1。
//
// 【数据流】canCompress(6bit) --查表/逐lane计算--> 上述四组输出。
//   Scala 用 DecodeLogic 把 2^6=64 种 key 预先算成真值表;这里直接用纯组合的
//   **逐 lane 游程统计**重建同一函数(更可读,且与查表等价)。
// =============================================================================
package compressunit_pkg;

  // 重命名宽度(每拍最多处理的指令数)。
  localparam int unsigned RENAME_WIDTH = 6;

  // 输出位宽。
  localparam int unsigned SIZE_W = $clog2(RENAME_WIDTH + 1); // 3:可表示 0..6
  localparam int unsigned MASK_W = RENAME_WIDTH;             // 6

  // 异常向量位数(ExceptionVec)。CompressUnit 只用其 "是否有任一异常"。
  localparam int unsigned EXC_W = 24;

  // TriggerAction.DebugMode 编码(4 位):进入调试模式的触发动作。
  localparam logic [3:0] TRIGGER_DEBUG_MODE = 4'd1;

  // CommitType.isFused(c) = c(2) —— 即 commitType 的 bit2 表示"该指令是 fusion
  // 融合产物"。被融合的指令不参与 ROB 压缩(它已经是合并结果)。

  // 单条 lane 的输入(聚合 golden 扁平端口为 struct)。
  typedef struct packed {
    logic                  valid;
    logic [EXC_W-1:0]      exceptionVec;
    logic [3:0]            trigger;
    logic                  canRobCompress;
    logic                  lastUop;
    logic [2:0]            commitType;
  } compress_in_t;

endpackage
