// =============================================================================
//  storepipe_pkg —— StorePipe(DCache store 探测流水) 可读核的类型/参数包
// -----------------------------------------------------------------------------
//  设计意图来源：src/main/scala/xiangshan/cache/dcache/storepipe/StorePipe.scala
//
//  ⚠️ 本顶层配置(KunmingHu V2R2)下 golden StorePipe 被 firtool 完全裁剪：
//     DCache 例化 StorePipe 时, 其 resp / miss_req / meta_read / tag_read 等输出
//     全部悬空(DontCare), 且 EnableStorePrefetchAtIssue=false, 故常量传播后顶层
//     只剩唯一端口 `input io_lsu_req_valid`(其余被死代码消除)。
//     => 可读核 xs_StorePipe_core 的「端口」对齐这个裁剪后接口(供 FM/UT)，
//        而完整的三级流水设计意图见 docs/memblock/StorePipe.md(学习载体)。
//
//  本包仍按设计意图给出 StorePipe 的几何参数与一致性模型(与 LoadPipe 同源)，
//  以便文档与未来未裁剪配置复用。
// =============================================================================
package storepipe_pkg;

  // ---- DCache 几何参数(同 LoadPipe)------------------------------------------
  localparam int N_WAYS    = 4;       // 组相联路数
  localparam int IDX_BITS  = 8;       // set 索引 vaddr[13:6]
  localparam int TAG_BITS  = 36;      // 物理 tag paddr[47:12]

  // instrtype: 硬件预取来源编码
  localparam logic [3:0] PREFETCH_SOURCE = 4'h3;

  // ---- TileLink ClientStates(2 位 coh 状态), 与 LoadPipe 一致 ------------------
  typedef enum logic [1:0] {
    COH_NOTHING = 2'h0,   // 无副本
    COH_BRANCH  = 2'h1,   // 共享只读
    COH_TRUNK   = 2'h2,   // 独占可写
    COH_DIRTY   = 2'h3    // 独占已改
  } coh_e;

  // ---- 单路 meta 条目(从 golden io_meta_resp_i_coh_state)-----------------------
  typedef struct packed {
    logic [1:0] coh_state;   // 该路当前一致性状态
  } meta_t;

  // ---- s1 流水级寄存的请求上下文 ----------------------------------------------
  typedef struct packed {
    logic [4:0]  cmd;        // store 访问命令
    logic [49:0] vaddr;      // 虚拟地址
    logic [3:0]  instrtype;  // 来源类型(==PREFETCH_SOURCE 表示硬件预取)
  } s1_req_t;

  // ---- s2 流水级寄存的请求 + 命中信息 -----------------------------------------
  typedef struct packed {
    logic [4:0]  cmd;
    logic [49:0] vaddr;
    logic        hit;        // s1 判定的命中结果
    logic [47:0] paddr;
    logic [1:0]  hit_coh;    // 命中路 coh(发 MissReq.req_coh 用)
    logic        is_prefetch;
  } s2_req_t;

endpackage
