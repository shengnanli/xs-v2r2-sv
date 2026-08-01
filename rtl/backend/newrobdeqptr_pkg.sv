// ============================================================================
// newrobdeqptr_pkg —— ROB deq 指针生成器 (NewRobDeqPtrWrapper) 可读核参数
//
// golden: NewRobDeqPtrWrapper.sv (firtool-1.62.1), Rob 内实例名 deqPtrGenModule。
// ROB 容量 = 160 项 (= 0xA0), 每周期最多提交 CommitWidth=8 条。
// deqPtr 用 flag+value 的环形指针表示 (value 8 位, 0..159; flag 用于绕回相位)。
// ============================================================================
package newrobdeqptr_pkg;

  // ROB 环形容量。golden 中 -10'hA0 = 减 160 做绕回归一。
  localparam int unsigned ROB_SIZE   = 160;   // 0xA0
  localparam int unsigned COMMIT_W   = 8;     // 每周期提交宽度 (deqPtr 组大小)
  localparam int unsigned PTR_VAL_W  = 8;     // value 位宽 (需覆盖 0..159)

  // ROB 指针: {flag, value}。flag 在 value 绕回 ROB_SIZE 时翻转, 用于区分同一
  // value 的两代 (队满/队空判别)。
  typedef struct packed {
    logic                 flag;
    logic [PTR_VAL_W-1:0] value;
  } rob_ptr_t;

endpackage
