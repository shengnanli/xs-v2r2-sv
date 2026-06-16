// =============================================================================
//  TLBuffer 类型包
// -----------------------------------------------------------------------------
//  TileLink Buffer 本身不解释 opcode/param 的语义，只按通道完整搬运 payload。
//  把 golden 的扁平端口聚合成 A/D 两个 bundle，便于阅读者按 TL 通道理解方向：
//    A: client -> manager，请求方向；
//    D: manager -> client，响应方向。
// =============================================================================
package tlbuffer_pkg;
  localparam int TL_BUFFER_CHANNELS = 2;

  localparam int TL_OPCODE_BITS = 4;
  localparam int TL_A_PARAM_BITS = 3;
  localparam int TL_D_PARAM_BITS = 2;
  localparam int TL_SIZE_BITS = 3;
  localparam int TL_SOURCE_BITS = 14;
  localparam int TL_ADDRESS_BITS = 49;
  localparam int TL_MASK_BITS = 8;
  localparam int TL_DATA_BITS = 64;

  typedef struct packed {
    logic bufferable;
    logic modifiable;
    logic readalloc;
    logic writealloc;
    logic privileged;
    logic secure;
    logic fetch;
  } tl_amba_prot_t;

  typedef struct packed {
    logic [TL_OPCODE_BITS-1:0] opcode;
    logic [TL_A_PARAM_BITS-1:0] param;
    logic [TL_SIZE_BITS-1:0] size;
    logic [TL_SOURCE_BITS-1:0] source;
    logic [TL_ADDRESS_BITS-1:0] address;
    tl_amba_prot_t user_amba_prot;
    logic [TL_MASK_BITS-1:0] mask;
    logic [TL_DATA_BITS-1:0] data;
    logic corrupt;
  } tl_a_bundle_t;

  typedef struct packed {
    logic [TL_OPCODE_BITS-1:0] opcode;
    logic [TL_D_PARAM_BITS-1:0] param;
    logic [TL_SIZE_BITS-1:0] size;
    logic [TL_SOURCE_BITS-1:0] source;
    logic sink;
    logic denied;
    logic [TL_DATA_BITS-1:0] data;
    logic corrupt;
  } tl_d_bundle_t;
endpackage
