// ============================================================================
// lsq_pkg —— LsqWrapper（Load/Store 队列包装器）的公共类型与纯函数
// ----------------------------------------------------------------------------
// 设计意图来源：src/main/scala/xiangshan/mem/lsqueue/LSQWrapper.scala
//
// LsqWrapper 是香山乱序访存（LSU）的“队列层”顶层：它把 LoadQueue 与 StoreQueue
// 两个大子模块拼在一起，对外暴露统一的访存队列接口，并在二者之间做少量
// **包装级（wrapper-level）控制**：
//   1. 入队拆分（enq split）：dispatch 来的每条访存指令按 needAlloc 的两个 bit
//      分别送入 LoadQueue（bit0）和 StoreQueue（bit1）。
//   2. canAccept 联立：只有两个队列都能收时整体才能收。
//   3. 非缓存（uncache / MMIO）仲裁：Load/Store 队列各自可能发起一笔 uncache
//      请求，但下游 uncache 通道一次只能处理一笔，故用一个 3 态仲裁状态机
//      （IDLE / LOAD / STORE）按 robIdx 年龄择一放行，并把 resp 按 is2lq 回送。
//   4. 异常地址选择（exceptionAddr）：ROB 提交触发异常后，按“该异常是否来自
//      store”延迟一拍选择 StoreQueue 还是 LoadQueue 给出的异常虚地址等信息。
//   5. 性能事件（perf）：把两队列的性能计数器各打两拍对齐后输出。
//
// 其余绝大多数端口（forward / replay / ldout / sbuffer / rob / nuke ...）都是
// 在 LoadQueue / StoreQueue 与顶层端口之间的**直通连线**，不含包装级逻辑，
// 由生成器机械铺在实例连接表里（见 LsqWrapper_inst.svh）。
// ============================================================================
package lsq_pkg;

  // ---- 队列规模 / 入队宽度（与本配置的 firtool 展开一致）----
  localparam int LSQ_ENQ_WIDTH   = 6;   // dispatch 一拍最多 6 条访存 uop
  localparam int LD_PIPE_WIDTH   = 2;   // load 流水条数
  localparam int ST_PIPE_WIDTH   = 2;   // store 流水条数
  localparam int ENSBUFFER_WIDTH = 2;

  // StoreQueue → LoadQueue 的“地址/数据就绪向量”宽度（= StoreQueueSize）
  localparam int SQ_SIZE         = 56;

  // 性能事件计数：LoadQueue 提供前 28 个，StoreQueue 提供后 8 个
  localparam int PERF_LQ_NUM     = 28;
  localparam int PERF_SQ_NUM     = 8;
  localparam int PERF_NUM        = PERF_LQ_NUM + PERF_SQ_NUM; // 36
  localparam int PERF_W          = 6;   // 每个计数器位宽

  // ---- ROB 索引：{flag, value}，用于 uncache 仲裁的年龄比较 ----
  localparam int ROB_VALUE_W = 8;
  typedef struct packed {
    logic                    flag;   // 环形队列的回绕标志
    logic [ROB_VALUE_W-1:0]  value;  // 队列内序号
  } rob_idx_t;

  // ---- 非缓存仲裁状态机：一次只服务一笔在途 uncache 事务 ----
  //  IDLE  ：空闲，可放行新的 Load 或 Store uncache 请求
  //  LOAD  ：已放行一笔 Load uncache，等其 resp 返回
  //  STORE ：已放行一笔 Store uncache，等其 resp 返回
  typedef enum logic [1:0] {
    UNC_IDLE  = 2'd0,
    UNC_LOAD  = 2'd1,
    UNC_STORE = 2'd2
  } uncache_arb_e;

  // ----------------------------------------------------------------------
  // age_before：判断 robIdx a 是否“老于”（程序序更早于）b。
  //   环形队列里 flag 相同则比 value，flag 不同则较小 flag 者更老。
  //   等价于 firtool 展开的 (a.flag ^ b.flag ^ (a.value < b.value))。
  // 用途：当 Load 与 Store 队列同时发起 uncache 请求时，优先服务更老的那笔。
  // ----------------------------------------------------------------------
  function automatic logic age_before(input rob_idx_t a, input rob_idx_t b);
    return a.flag ^ b.flag ^ (a.value < b.value);
  endfunction

  // ----------------------------------------------------------------------
  // pick_load：在 IDLE 态选择放行 Load 还是 Store 的 uncache 请求。
  //   - 只有 Load 有请求            → 选 Load
  //   - 两者都有请求且 Load 更老     → 选 Load
  //   - 否则                        → 选 Store
  // ----------------------------------------------------------------------
  function automatic logic pick_load(input logic    ld_req_valid,
                                     input logic    st_req_valid,
                                     input rob_idx_t ld_rob,
                                     input rob_idx_t st_rob);
    return (ld_req_valid & ~st_req_valid)
         | (ld_req_valid &  st_req_valid & age_before(ld_rob, st_rob));
  endfunction

endpackage
