// =============================================================================
// StorePfWrapper 类型包
// -----------------------------------------------------------------------------
// 这些类型对应 Scala StorePfWrapper 附近的两个 bundle：
//   * DCacheWordReqWithVaddr：Sbuffer 提交给 store prefetch 训练流的 store word。
//   * StorePrefetchReq：预取器发往 DCache 的预取请求。
//
// 当前 KunmingHu V2R2 配置中 EnableStorePrefetchSPB=false，firtool 把 wrapper 的
// store 训练输入和 Decoupled 握手全部裁掉，顶层只剩两路 vaddr 输出。但保留这些
// struct 能让读者看到 wrapper 原本连接的是“store 训练流 -> 串行器 -> SPB -> 预取请求”。
// =============================================================================
package storepfwrapper_pkg;
  localparam int VADDR_BITS = 50;
  localparam int STORE_TRAIN_LANES = 2;    // EnsbufferWidth
  localparam int PREFETCH_REQ_LANES = 2;   // StorePipelineWidth in this golden
  localparam int CACHE_BLOCK_BYTES = 64;

  typedef struct packed {
    logic [VADDR_BITS-1:0] vaddr;
  } store_prefetch_req_t;

  typedef struct packed {
    logic                  valid;
    logic [VADDR_BITS-1:0] vaddr;
  } store_train_req_t;

  typedef enum logic [1:0] {
    PF_SRC_DISABLED = 2'b00,
    PF_SRC_SPB      = 2'b01
  } prefetch_source_e;
endpackage
