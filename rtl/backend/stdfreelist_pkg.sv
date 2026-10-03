// =====================================================================
// stdfreelist_pkg —— 重命名「标准空闲列表」(StdFreeList 家族) 的家族常量
// ---------------------------------------------------------------------
// 家族说明、四个变体的参数来历(逐个量自 G1 golden)见 rtl/backend/StdFreeList.sv
// 文件头；参数化核 xs_StdFreeList_core 与浮点变体 wrapper 也在那里，另外三个变体
// 各自一个薄文件 rtl/backend/StdFreeList_{1,2,3}.sv。
//
// ★为什么单独成文件★：本包被 StdFreeList.sv 与三个变体薄文件共同 import。
// 包若住在 StdFreeList.sv 里，编译 StdFreeList_{1,2,3}.sv 就隐含要求
// StdFreeList.sv 先编(否则 VCS 报 SV-LCM-PND)——这是一条藏在文件顺序里的依赖
// (scripts/check_pkg_scope.py 判据 B)。单独成文件后，filelist 只需把本文件放在最前。
//
// 家族内不变的量放在本包；随变体变的量(SIZE / NUM_LOGIC_REGS 及由它们导出的
// 指针宽)是核参数——所以循环指针类型与指针算术定义在核里，而不是包里
// (SystemVerilog 的 package 不能参数化)。
// =====================================================================
package stdfreelist_pkg;

  localparam int PHYREG_W      = 8;    // 物理寄存器号位宽 PhyRegIdxWidth(四个变体都是 8)
  localparam int RENAME_WIDTH  = 6;    // 每拍重命名(分配)口数
  localparam int COMMIT_WIDTH  = 6;    // 每拍提交/回滚(回收)口数 RabCommitWidth
  localparam int SNAPSHOT_NUM  = 4;    // 快照个数 RenameSnapshotNum

  // ---- 四个变体的参数表(薄 wrapper 用；见文件头表格) ----
  localparam int FP_SIZE  = 158, FP_NUM_LOGIC  = 34;   // StdFreeList
  localparam int VEC_SIZE = 81,  VEC_NUM_LOGIC = 47;   // StdFreeList_1
  localparam int V0_SIZE  = 21,  V0_NUM_LOGIC  = 1;    // StdFreeList_2
  localparam int VL_SIZE  = 31,  VL_NUM_LOGIC  = 1;    // StdFreeList_3

endpackage
