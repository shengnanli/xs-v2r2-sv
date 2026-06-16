// =============================================================================
//  Pipeline 类型包
// -----------------------------------------------------------------------------
//  L1PrefetchReq 是预取流水内部传递的一条请求描述。Pipeline 模块只负责
//  Decoupled 一拍缓冲，不修改请求内容，因此这里把 payload 聚合成一个结构体。
// =============================================================================
package pipeline_pkg;
  localparam int PF_PADDR_BITS = 48;
  localparam int PF_ALIAS_BITS = 2;
  localparam int PF_SOURCE_BITS = 3;
  localparam int PIPELINE_BOUNDARIES = 2;

  typedef struct packed {
    logic [PF_PADDR_BITS-1:0] paddr;
    logic [PF_ALIAS_BITS-1:0] addr_alias;
    logic confidence;
    logic is_store;
    logic [PF_SOURCE_BITS-1:0] pf_source_value;
  } l1_prefetch_req_t;
endpackage
