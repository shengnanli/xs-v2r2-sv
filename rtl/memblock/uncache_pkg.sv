// =============================================================================
//  uncache_pkg —— Uncache（非缓存 / MMIO 访问单元）可读重写用的类型/常量/纯函数
// -----------------------------------------------------------------------------
//  设计意图来源（人写 Chisel 源，非 firtool golden）：
//      src/main/scala/xiangshan/cache/dcache/Uncache.scala
//
//  Uncache 是 DCache 旁路通道：LoadQueue/StoreQueue 里被判定为 uncached（MMIO 或
//  non-cacheable NC）的访存请求不进 L1 cache，而是走这里经 TileLink-UL 主端口直接
//  打到总线/L2。它内部维护一张「ubuffer」：UncacheBufferSize 个 entry，每个 entry
//  是一条在途 uncached 访存的小状态机。
//
//  ── entry 生命周期（见 UncacheEntryState 的 4 个 bool）─────────────────────
//      idle(valid&!inflight&!waitSame&!waitReturn)         可上总线
//        │  上 TileLink A（mem_acquire.fire）
//        ▼
//      inflight                                            等 TileLink D 返回
//        │  收 TileLink D（mem_grant.fire）
//        ▼
//      waitReturn                                          等回写 LSQ
//        │  resp.fire
//        ▼
//      （清空 → idle/invalid）
//    waitSame 是「同 block 地址串行化」的旁路标志：若已有同 block entry 在途，新
//    entry 先挂 waitSame，等老的回来再放行，保证 uncached 同地址访问的顺序。
//
//  ── 三个并发处理面（对应 Scala 的分节）────────────────────────────────────
//   (1) Enter Buffer (e0/e1)：req 进来，按 block 地址做 merge（合并到已有 entry）
//       或 alloc（占一个空 entry）；e1 打一拍把分配到的 sid 通过 idResp 返回 LSQ。
//   (2) Uncache Req (q0)：在所有「可上总线」的 entry 里按优先级选一个，组 TileLink
//       Get(load)/Put(store) A 通道请求；非 outstanding 模式下用 uState 串行化。
//   (3) Uncache Resp / Return：收 D 写回 entry，再择机把结果 resp 回 LSQ。
//   另有 forward 面：把 ubuffer 里 in-flight 的 store 数据前递给 load 流水（f0/f1）。
//
//  ── 本工程 KunmingHu V2R2 配置固化参数（与 golden 对齐）────────────────────
//      UncacheBufferSize = 4   →  INDEX_WIDTH = 2（source/sid/idx 均 2 位）
//      LoadPipelineWidth = 3   →  forward 端口 3 路
//      XLEN=64, DataBytes=8, VDataBytes=16(=VLEN/8), PAddrBits=48, VAddrBits=50
//      M_SZ=5（mem cmd 宽度），LSQ id（mid）= 7 位
// =============================================================================
package uncache_pkg;

  // ---- 关键位宽/常量（与香山 KunmingHu V2R2 配置一致）-----------------------
  localparam int UNC_SIZE    = 4;                 // UncacheBufferSize（entry 数）
  localparam int IDX_W       = 2;                 // log2Up(UNC_SIZE)
  localparam int LD_WIDTH    = 3;                  // LoadPipelineWidth（forward 路数）
  localparam int XLEN        = 64;
  localparam int DATA_BYTES  = 8;                  // XLEN/8（一个 TL beat 字节数）
  localparam int VDATA_BYTES = 16;                 // VLEN/8（forward 输出字节数）
  localparam int PADDR_BITS  = 48;
  localparam int VADDR_BITS  = 50;
  localparam int M_SZ        = 5;                  // mem cmd 宽度
  localparam int MID_W       = 7;                  // LSQ 侧请求 id（mid）宽度
  localparam int BLOCK_OFFSET = 3;                 // log2Up(XLEN/8)，merge/同 8B 字对齐用低位
  localparam int VADDR_BLK_BITS = VADDR_BITS - BLOCK_OFFSET; // entry 内 vaddr 只存 block 位数
  localparam int CACHE_BLK_OFF = 6;                // blockOffBits=log2(64B cache line)，busError 上报用

  // ---- mem cmd 编码（rocket Consts）-----------------------------------------
  localparam logic [M_SZ-1:0] M_XRD = 5'h0;        // uncached load
  localparam logic [M_SZ-1:0] M_XWR = 5'h1;        // uncached store

  // ---- TileLink-UL A 通道 opcode --------------------------------------------
  localparam logic [3:0] TL_GET            = 4'h4; // load
  localparam logic [3:0] TL_PUTPARTIALDATA = 4'h1; // store（带 mask 的部分写）

  // ===========================================================================
  //  数据结构
  // ===========================================================================

  // ---- 单个 ubuffer entry 的 payload（对应 Scala class UncacheEntry）--------
  //   保存一条 uncached 访存的命令/地址/数据/掩码及属性；data 在 store 时是写数据，
  //   在 load 返回后被 TileLink D 的读数据覆盖。resp_nderr 记录总线返回的 denied/corrupt。
  typedef struct packed {
    logic [M_SZ-1:0]        cmd;            // M_XRD(load)/M_XWR(store)
    logic [PADDR_BITS-1:0]  addr;           // 物理地址（block 对齐后或合并后对齐到首个有效字节）
    // vaddr 只存 block 地址位 [VADDR_BITS-1:BLOCK_OFFSET]：forward 的 vaddr CAM 只比较
    //   [49:3]（addr_match_v = >>BLOCK_OFFSET），merge 重对齐也只保留 [49:3]。低 3 位字节
    //   偏移从不被读——golden 的 entries_N_vaddr 存满 50 位但同样只读 [49:3]（低 3 位冗余死位）。
    logic [VADDR_BITS-1:BLOCK_OFFSET] vaddr; // 虚地址 block 位（forward 用 vaddr CAM）
    logic [XLEN-1:0]        data;           // store 写数据 / load 返回数据
    logic [DATA_BYTES-1:0]  mask;           // 字节有效掩码
    logic                   nc;             // non-cacheable（区别于强序 MMIO）
    logic                   memBackTypeMM;  // 后端按 main-memory 处理（影响 difftest/总线属性）
    logic                   resp_nderr;     // 总线返回 denied|corrupt
  } unc_entry_t;

  // ---- entry 状态机的 4 个 bool（对应 Scala class UncacheEntryState）--------
  //   有效态由 valid 与其余位组合而成，下方纯函数给出各种「能否」判定。
  typedef struct packed {
    logic valid;        // 占用
    logic inflight;     // uncache → L2（A 已发、D 未回）
    logic waitSame;     // 等同 block 老 entry 先完成（顺序约束）
    logic waitReturn;   // uncache → LSQ（D 已回、resp 未发）
  } unc_state_t;

  // ---- 非 outstanding 模式下的全局串行状态机（对应 Scala uState）------------
  //   io_enableOutstanding=0 时，整单元一次只允许一条在途请求：
  //   idle →(A fire) inflight →(D fire) wait_return →(resp fire) idle。
  typedef enum logic [1:0] {
    US_IDLE        = 2'd0,
    US_INFLIGHT    = 2'd1,
    US_WAIT_RETURN = 2'd2
  } ustate_e;

  // ===========================================================================
  //  纯函数区
  // ===========================================================================

  // ---- block 地址：丢弃低 BLOCK_OFFSET 位（同一 8B block 归一）---------------
  function automatic logic [PADDR_BITS-1:0] get_block_addr_p(input logic [PADDR_BITS-1:0] a);
    return a >> BLOCK_OFFSET;
  endfunction
  function automatic logic [VADDR_BITS-1:0] get_block_addr_v(input logic [VADDR_BITS-1:0] a);
    return a >> BLOCK_OFFSET;
  endfunction

  // ---- 同 block 判定（paddr / vaddr）----------------------------------------
  function automatic logic addr_match_p(input logic [PADDR_BITS-1:0] x,
                                        input logic [PADDR_BITS-1:0] y);
    return get_block_addr_p(x) == get_block_addr_p(y);
  endfunction
  function automatic logic addr_match_v(input logic [VADDR_BITS-1:0] x,
                                        input logic [VADDR_BITS-1:0] y);
    return get_block_addr_v(x) == get_block_addr_v(y);
  endfunction
  // 取 vaddr 的 block 位（entry 内只存这些位）。
  function automatic logic [VADDR_BLK_BITS-1:0] vaddr_blk(input logic [VADDR_BITS-1:0] a);
    return a[VADDR_BITS-1:BLOCK_OFFSET];
  endfunction
  // full vaddr 与已存 block-vaddr 的同 block 判定（一侧是 io 请求全宽，一侧是 entry block 位）。
  function automatic logic addr_match_v_blk(input logic [VADDR_BITS-1:0]     full,
                                            input logic [VADDR_BLK_BITS-1:0]  blk);
    return full[VADDR_BITS-1:BLOCK_OFFSET] == blk;
  endfunction

  function automatic logic is_store(input logic [M_SZ-1:0] cmd);
    return cmd == M_XWR;
  endfunction

  // ---- 逐字节合并：newMask 选中的字节用 newData，否则保留 oldData ------------
  //   对应 Scala doMerge。返回 {合并后 data, 合并后 mask=old|new}。
  function automatic logic [XLEN-1:0] merge_data(input logic [XLEN-1:0] oldData,
                                                 input logic [XLEN-1:0] newData,
                                                 input logic [DATA_BYTES-1:0] newMask);
    logic [XLEN-1:0] res;
    for (int j = 0; j < DATA_BYTES; j++)
      res[8*j +: 8] = newMask[j] ? newData[8*j +: 8] : oldData[8*j +: 8];
    return res;
  endfunction

  // ---- merge 后地址重对齐：取合并掩码里第一个为 1 的字节位置做新低位 ----------
  //   对应 Scala update(x: UncacheWordReq) 里的 PriorityEncoderWithFlag(resMask)：
  //   把 block 基址 | 首个有效字节偏移，作为新的访存起始地址。
  //   resOffset：最低置位字节的下标（与 golden 同款显式优先级三元，避免循环-return
  //   在形式化里被综合成对全 0 输入产生 X 的优先 mux）。resFlag = 任一字节有效。
  function automatic logic [BLOCK_OFFSET-1:0] res_offset(input logic [DATA_BYTES-1:0] m);
    return m[0] ? 3'h0 : m[1] ? 3'h1 : m[2] ? 3'h2 : m[3] ? 3'h3 :
           m[4] ? 3'h4 : m[5] ? 3'h5 : {2'h3, ~m[6]};
  endfunction
  function automatic logic res_flag(input logic [DATA_BYTES-1:0] m);
    return |m;
  endfunction

  // ---- merge primary 判定里的「连续且对齐」检查（对应 continueAndAlign）------
  //   合并后掩码必须落在天然对齐的 1/2/4/8 字节窗口内，才允许 merge。
  function automatic logic continue_and_align(input logic [DATA_BYTES-1:0] m);
    return ($countones(m) == 1) ||
           (m == 8'b0000_0011) || (m == 8'b0000_1100) ||
           (m == 8'b0011_0000) || (m == 8'b1100_0000) ||
           (m == 8'b0000_1111) || (m == 8'b1111_0000) ||
           (m == 8'b1111_1111);
  endfunction

  // ---- TileLink size 编码：lgSize = log2(PopCount(mask))（合法时）------------
  //   对应 Scala: size=PopCount(mask)，再 PriorityMux 到 {1,2,4,8}->{0,1,2,3}。
  function automatic logic [1:0] tl_lg_size(input logic [DATA_BYTES-1:0] mask);
    logic [3:0] sz;
    sz = $countones(mask);
    return (sz == 4'h1) ? 2'h0 :
           (sz == 4'h2) ? 2'h1 :
           {1'b1, ~(sz == 4'h4)};   // 4->2，否则(8)->3
  endfunction

  // ---- TileLink Get 的天然对齐字节掩码（对应 edge.Get 自动生成的 a_mask）-----
  //   对一个 8B beat，按 lgSize 给出覆盖 [addr 对齐的 2^lgSize 字节] 的掩码：
  //     lgSize=3 → 0xFF；lgSize=2 → 0x0F/0xF0（看 addr[2]）；
  //     lgSize=1 → 看 addr[2:1]；lgSize=0 → 单字节（看 addr[2:0]）。
  function automatic logic [DATA_BYTES-1:0] tl_get_mask(input logic [2:0] addr,
                                                        input logic [1:0] lgSize);
    logic [DATA_BYTES-1:0] m;
    for (int j = 0; j < DATA_BYTES; j++) begin
      // 该字节属于以 addr 对齐到 2^lgSize 的窗口内即点亮
      m[j] = ((j >> lgSize) == (addr >> lgSize));
    end
    return m;
  endfunction

endpackage
