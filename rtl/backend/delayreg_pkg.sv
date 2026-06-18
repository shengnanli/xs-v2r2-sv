// =============================================================================
// delayreg_pkg —— 香山 V2R2 通用「延迟 N 拍」工具件 DelayReg 的类型定义
// -----------------------------------------------------------------------------
// 设计源:
//   - utility/src/main/scala/utility/Hold.scala 的 class DelayN[T](gen, n):
//       把任意 bundle 经 n 个背靠背 RegNext 打 n 拍后输出。
//   - golden DelayReg 是 DifftestModule(new DiffInstrCommit, delay=3) 生成的实例:
//       即把一个「指令提交信息」difftest payload 延迟 3 拍。
//       见 src/main/scala/xiangshan/backend/rob/Rob.scala 的 difftest.* 赋值。
//
// 角色:DelayReg 是 difftest(仿真比对)专用的纯打拍移位链,综合后会被优化掉。
//   它把 ROB 提交时刻的指令信息延迟固定拍数,以与差分测试参考模型(NEMU/Spike)
//   的时序对齐。功能上就是一个「无握手、每拍无条件前移」的 N 级流水寄存器。
//
// 为什么用 struct + 参数化:golden 把 payload 的每个字段展平成独立 reg、再手工
//   复制成 3 份(REG/REG_1/REG_2)。这里改用一个 typedef struct packed 表达
//   payload 语义、用 genvar 生成 N 级,既贴合 DelayN 的设计意图,又消除 42 个
//   展平端口/几十个 REG_* 的可读性负担。
// =============================================================================
package delayreg_pkg;

  // 默认延迟拍数(DiffInstrCommit 的 delay=3)。
  localparam int DELAY_N = 3;

  // ---------------------------------------------------------------------------
  // DiffInstrCommit payload —— 一条指令提交的 difftest 信息(见 Rob.scala)。
  // 字段顺序与位宽对齐 golden 端口;打包成 struct 便于整体打拍。
  //   注:packed struct 的最高位字段在 MSB 端。这里把控制位放在高位、数据位放在
  //   低位,具体位序由 wrapper 负责与 golden 端口对齐,核内不依赖具体排布。
  // ---------------------------------------------------------------------------
  localparam int DEST_W   = 8;   // 物理/逻辑寄存器号、coreid、index、nFused 宽度
  localparam int N_OTHER  = 8;   // 向量指令的其它写目的 pdest 个数 (otherwpdest_0..7)

  typedef struct packed {
    logic                       valid;   // 本拍是否有有效提交
    logic                       skip;    // difftest 是否跳过该指令
    logic                       isRVC;   // 是否压缩指令
    logic                       rfwen;   // 写整数寄存器
    logic                       fpwen;   // 写浮点寄存器
    logic                       vecwen;  // 写向量寄存器
    logic                       v0wen;   // 写 v0 掩码寄存器
    logic [DEST_W-1:0]          wpdest;  // 写物理寄存器号
    logic [DEST_W-1:0]          wdest;   // 写逻辑寄存器号
    logic [N_OTHER-1:0][DEST_W-1:0] otherwpdest; // 向量其它写目的(8 个)
    logic [DEST_W-1:0]          nFused;  // 融合指令条数
    logic [DEST_W-1:0]          coreid;  // 核 id
    logic [DEST_W-1:0]          index;   // 提交端口序号
  } diff_commit_t;

endpackage : delayreg_pkg
