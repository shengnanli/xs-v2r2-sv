// =============================================================================
// xs_l1metaarray_pkg —— L1 DCache 异步元数据阵列（Coh / Flag）的共享类型与参数
//
// 对应 Chisel: xiangshan.cache.AsynchronousMetaArray.scala
//   class L1CohMetaArray   —— 一致性状态(coherence)元数据阵列
//   class L1FlagMetaArray  —— 标志位(flag, 如 error/prefetch valid)元数据阵列
//   bundle Meta / MetaReadReq / CohMetaWriteReq / FlagMetaWriteReq
//
// 角色：DCache 每个 way 都要为每个 set 记录“这条 cacheline 现在处于什么一致性状态”
//   （Nothing/Branch/Trunk/Dirty，TileLink ClientMetadata，2 bit）以及若干 1-bit 标志。
//   这些元数据用**寄存器堆**实现（不是 SRAM），因此叫“异步”阵列：读不打拍取数，
//   组合给出当拍数据；写则经过 S0->S1 两拍流水后落寄存器堆。
//
// 为什么读侧要做 bypass：写有 2 拍延迟（S0 收请求，S1 才真正写进 meta_array）。
//   若一条读请求的 idx 恰好命中“正在 S0 或 S1 在途的写”，直接读寄存器堆会拿到旧值。
//   故对每个 (读口, way) 做在途写转发(bypass)，保证读到最新值。
//
// 组织：meta_array[nSets][nWays]，本配置 nSets=256(idxBits=8)、nWays=4。
//   - Coh entry = 2-bit coh_state（ClientMetadata.state）
//   - Flag entry = 1-bit flag
//   读口数/写口数由参数化覆盖（见各 class 的 readPorts/writePorts）。
//
// way 选择：写请求带 one-hot 的 way_en，对每个 way 独立判定是否写；读则一次返回
//   全部 nWays 份数据(resp[way])，由上层（DCache 命中比较）再做 tag 命中选 way。
//   本阵列本身**不做 tag 命中**，只按 idx 索引返回该 set 全部 way 的元数据。
// =============================================================================
package xs_l1metaarray_pkg;

  // ---------------- 物理参数（KunmingHu V2R2，DCacheParameters）----------------
  localparam int N_SETS   = 256;          // nSets
  localparam int IDX_BITS = 8;            // log2(nSets)
  localparam int N_WAYS   = 4;            // nWays
  localparam int COH_BITS = 2;            // ClientMetadata.state 宽（Nothing/Branch/Trunk/Dirty）

  // ClientMetadata 状态编码（TileLink ClientStates，仅用于阅读理解，逻辑上当 2-bit 透传）
  typedef enum logic [COH_BITS-1:0] {
    COH_NOTHING = 2'd0,                   // 无副本
    COH_BRANCH  = 2'd1,                   // 只读共享
    COH_TRUNK   = 2'd2,                   // 独占(可写未脏)
    COH_DIRTY   = 2'd3                    // 独占且已脏
  } coh_state_e;

  // 一致性元数据条目（与 Chisel class Meta 对应：只有一个 coh 字段）
  typedef struct packed {
    logic [COH_BITS-1:0] coh_state;
  } meta_coh_t;

endpackage
