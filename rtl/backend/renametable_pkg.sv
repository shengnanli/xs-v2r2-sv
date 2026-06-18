// =====================================================================
// renametable_pkg —— 寄存器别名表(RAT, Register Alias Table)的类型与参数
// ---------------------------------------------------------------------
// RenameTable 维护「逻辑寄存器号 → 物理寄存器号」的映射。本工程重写的 golden
// 例化是【整数】RAT(Reg_I)：32 个逻辑整数寄存器，物理寄存器号 8 bit。
//
// 两张表(都是 32 项 × 8bit 的寄存器堆)：
//   spec_table  投机态映射：重命名时被写(spec write)，redirect 时可整表回退到
//               arch_table 或某个快照(snapshot)。读口(decode-rename 级)读这张表。
//   arch_table  体系结构态映射：仅在 commit(RAB 提交)时被写(arch write)，代表
//               "已确定、不会回退"的映射。redirect 用它恢复 spec_table。
//
// 关键时序设计(Scala 注释原文)：为改善时序，读写都打一拍：
//   (1) T0 的写在 T1 实际生效；
//   (2) 读是同步的：addr 在 T0 寄存、用它访问表得到 T0 的数据；
//   (3) T0 的写数据旁路(bypass)到 T1 的读数据。
//
// 文档见 docs/backend/RenameTable.md。
// =====================================================================
package renametable_pkg;

  // ---- 整数 RAT(Reg_I) 例化参数 ----
  localparam int NUM_ENTRY     = 32;   // 逻辑寄存器数 IntLogicRegs (rdataNums)
  localparam int ADDR_W        = 5;    // 逻辑寄存器号位宽 = log2(32)
  localparam int PHYREG_W      = 8;    // 物理寄存器号位宽 PhyRegIdxWidth
  localparam int RENAME_WIDTH  = 6;    // 每拍重命名口数 RenameWidth
  localparam int READ_PER_RN   = 2;    // 每条重命名指令的读口数(Reg_I=2: rs1/rs2)
  localparam int NUM_READ      = RENAME_WIDTH * READ_PER_RN; // 12 个读口
  localparam int COMMIT_WIDTH  = 6;    // 提交/回滚口数 RabCommitWidth
  // diff 写口数 = RabCommitWidth * MaxUopSize(用于 difftest 的"真值表"无旁路写入)。
  // 本 golden 例化为 255 个 diff 写口(索引 0..254)，仅在 basicDebugEn 时存在。
  localparam int NUM_DIFF      = 255;
  localparam int SNAPSHOT_NUM  = 4;    // 快照个数 RenameSnapshotNum
  localparam int SNAP_SEL_W    = 2;    // 快照选择位宽 = log2(4)

  // ---- RAT 写端口(spec / arch / diff 共用此结构) ----
  typedef struct packed {
    logic                wen;   // 写使能
    logic [ADDR_W-1:0]   addr;  // 逻辑寄存器号
    logic [PHYREG_W-1:0] data;  // 物理寄存器号
  } rat_wport_t;

  // ---- RAT 读端口(读侧) ----
  // hold=1 时保持上拍地址(stall)；data 为同步读出的物理寄存器号。
  typedef struct packed {
    logic                hold;
    logic [ADDR_W-1:0]   addr;
  } rat_rport_t;

endpackage
