// =============================================================================
//  storemisalignbuffer_pkg —— StoreMisalignBuffer 可读核的类型/常量/纯函数包
// -----------------------------------------------------------------------------
//  设计意图来源：src/main/scala/xiangshan/mem/lsqueue/StoreMisalignBuffer.scala
//
//  StoreMisalignBuffer 处理「跨 16B 边界的非对齐 store」：当 StoreUnit 发现一条 store
//  跨 16 字节边界时，把它缓冲并拆成两次「不跨界的对齐子 store」(low/high)，依次发往
//  StoreUnit 的 misalign 重发口；与 load 不同的是 store 不在此搬运数据（数据由
//  StoreQueue 通路负责），本缓冲只负责「拆地址、控时序、控 StoreQueue 出队」。
//
//  与 LoadMisalignBuffer 的关键区别：
//    1) 还要检测「跨 4KB 页边界」(cross4KB)：跨页 store 需等到该指令到达 ROB 头部
//       (robMatch) 才能拆分，且拆分后要 flush 流水（needFlushPipe）、阻塞 StoreQueue
//       出队（s_block + sqControl），避免跨页的部分写在异常时无法回滚。
//    2) s_resp 收齐后要再等 RAWTotalDelayCycles 拍（本配置=1，单级 REG）才写回，
//       以对齐 LoadQueueRAW 的 raw-rollback 时序。
//    3) 入队是 2 口「选最老(oldest)」仲裁（按 robIdx→uopIdx），不是固定优先级。
//
//  本包集中：enum fsm_state_e(6 态，含 s_block)、enum size_e、function getMask、
//  环形指针比较函数（robNeedFlush / isAfter / isNotBefore）。拆分表/掩码在核里用
//  函数 + for 表达。
// =============================================================================
package storemisalignbuffer_pkg;

  localparam int XLEN  = 64;
  localparam int VLEN  = 128;
  localparam int VADDR = 50;
  localparam int MASKW = 16;
  localparam int MAX_SPLIT = 2;
  // RAW 写回延迟拍数（本配置 LoadQueueRAWSize 推出 = 1）：s_resp 收齐后再延 1 拍写回。
  localparam int RAW_DELAY = 1;

  // ---- 拆分状态机（比 load 多一个 s_block：跨页阻塞等 StoreQueue 出队）----
  //  s_idle  : 空闲；跨页时需等 robMatch 才进 s_split
  //  s_split : 拆成 low/high 两次对齐子 store
  //  s_req   : 发当前子 store 到 StoreUnit
  //  s_resp  : 等子 store 回应；异常/uncache 直接收尾；否则延 RAW_DELAY 拍进 s_wb
  //  s_wb    : 写回 ROB / VecStoreMergeBuffer；跨页且正常完成则转 s_block
  //  s_block : 跨页 store 等待到达 ROB 头、StoreQueue 真正出队（doDeq）后释放
  typedef enum logic [2:0] {
    S_IDLE  = 3'd0,
    S_SPLIT = 3'd1,
    S_REQ   = 3'd2,
    S_RESP  = 3'd3,
    S_WB    = 3'd4,
    S_BLOCK = 3'd5
  } fsm_state_e;

  typedef enum logic [1:0] {
    SZ_B = 2'b00, SZ_H = 2'b01, SZ_W = 2'b10, SZ_D = 2'b11
  } size_e;

  function automatic logic [7:0] getMask(input size_e sz);
    case (sz)
      SZ_B: getMask = 8'h01;
      SZ_H: getMask = 8'h03;
      SZ_W: getMask = 8'h0f;
      SZ_D: getMask = 8'hff;
    endcase
  endfunction

  // 环形指针「严格在后」：v 是否晚于 r（robIdx）。
  function automatic logic isAfter(input logic vf, input logic [7:0] vv,
                                   input logic rf, input logic [7:0] rv);
    isAfter = (vf ^ rf) ^ (vv > rv);
  endfunction

  // 环形指针「不在前」：v 是否 >= r。
  function automatic logic isNotBefore(input logic vf, input logic [7:0] vv,
                                       input logic rf, input logic [7:0] rv);
    isNotBefore = (vf ^ rf) ^ (vv >= rv);
  endfunction

  // redirect 冲刷判定（同 load）。
  function automatic logic robNeedFlush(
      input logic v_flag, input logic [7:0] v_value,
      input logic r_flag, input logic [7:0] r_value,
      input logic redirect_valid, input logic redirect_level);
    logic flushItself, after;
    flushItself = redirect_level & (v_flag == r_flag) & (v_value == r_value);
    after = (v_flag ^ r_flag) ^ (v_value > r_value);
    robNeedFlush = redirect_valid & (after | flushItself);
  endfunction

endpackage
