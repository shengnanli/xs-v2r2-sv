// =============================================================================
//  loadqueueraw_pkg —— LoadQueueRAW（store→load 违例/nuke 检测队列）可读重写
//                       所用的类型 / 常量 / 纯函数
// -----------------------------------------------------------------------------
//  设计意图来源（人写 Chisel 源，非 firtool golden）：
//      src/main/scala/xiangshan/mem/lsqueue/LoadQueueRAW.scala   (class LoadQueueRAW)
//      src/main/scala/xiangshan/mem/lsqueue/LoadQueueData.scala  (LqPAddrModule / LqMaskModule)
//      src/main/scala/xiangshan/mem/lsqueue/FreeList.scala       (class FreeList)
//
//  ── LoadQueueRAW 在 LSU 中的位置与职责 ──
//   它是一张「已发射但尚未提交」的 load 记录表（RAW = Read-After-Write）。
//   每条进入 load 流水线、且其前方仍有「地址未就绪的更老 store」的 load，都会在
//   此入队，记录 {robIdx, sqIdx, 部分物理地址, 字节 mask, data_valid}。
//
//   当某条 store 在其流水 s1 拿到物理地址后写回（io_storeIn），本队列用该 store 的
//   paddr/mask 对所有在队 load 做 CAM 匹配：若某条「更年轻」(robIdx 在 store 之后)
//   的 load 与该 store 地址重叠，说明这条 load 读到了本应被该 store 覆盖的旧数据
//   —— 即 store→load 违例 (nuke)。此时产生 rollback(redirect)，冲刷并从该 load
//   处重取/重放。
//
//   出队（释放条目）由「store 地址就绪指针」推进：当 stAddrReadySqPtr 越过某 load
//   的 sqIdx（其前方所有更老 store 地址都已就绪、不可能再有未知 store 与之冲突）时，
//   该 load 不再需要被监视，释放回 freelist。redirect 冲刷的条目也立即释放。
//
//  ── 本工程当前配置（golden 由 DefaultConfig 固化）──
//     LoadQueueRAWSize     = 32   （条目数，2 的幂）
//     LoadPipelineWidth    = 3    （查询/入队端口 query_0..2）
//     StorePipelineWidth   = 2    （store 写回 / rollback 端口 storeIn_0..1）
//     RollbackGroupSize    = 8    （最老选择的分组大小）
//     LoadQueueNWriteBanks = 8    （paddr/mask CAM 的写 bank 数；本核 CAM 用纯
//                                   寄存器阵列直写，bank 仅影响写时序，不影响功能）
//     numWDelay            = 2    （CAM 写入延迟 1 拍：s0 锁存→s1 落地）
//
//   关键派生时序：
//     TotalSelectCycles = ceil(log2(32)/log2(8)) + 1 = ceil(5/3)+1 = 3
//     违例从 store 写回到 rollback 输出共 3 拍（1 拍 entryNeedCheck + 2 拍最老选择）。
// =============================================================================
package loadqueueraw_pkg;

  // ---- 规模 / 位宽参数 -------------------------------------------------------
  localparam int RAW_SIZE   = 32;             // LoadQueueRAWSize
  localparam int IDX_W      = 5;              // log2Up(32)，条目索引位宽
  localparam int LD_W       = 3;              // LoadPipelineWidth
  localparam int ST_W       = 2;              // StorePipelineWidth
  localparam int GROUP_SIZE = 8;              // RollbackGroupSize
  localparam int N_GROUP    = RAW_SIZE / GROUP_SIZE; // 4 个最老选择分组
  localparam int SEL_CYCLES = 3;              // TotalSelectCycles

  localparam int MASK_BITS  = 16;             // 字节 mask = VLEN/8
  localparam int PADDR_BITS = 48;             // 完整物理地址位宽
  localparam int ROB_W      = 8;              // robIdx.value 位宽
  localparam int SQ_W       = 6;              // sqIdx.value 位宽
  localparam int FTQ_W      = 6;              // ftqPtr.value 位宽
  localparam int FTQOFF_W   = 4;              // ftqOffset 位宽

  // ---- 部分物理地址（partial paddr）参数 -------------------------------------
  //   CAM 不存完整 48 位 paddr，只存 paddr[27:4]（24 位）：
  //     paddrOffset      = DCacheVWordOffset = log2(VLEN/8) = log2(16) = 4
  //     PartialPAddrWidth = 24                → 覆盖 paddr[4 +: 24] = paddr[27:4]
  //   在 24 位 partial 内部进一步分两段做 cacheline 匹配：
  //     DCacheLineOffset = log2(64B) = 6      → cacheline 内偏移占 paddr[5:0]
  //     CL_OFFSET (partial 内) = DCacheLineOffset - paddrOffset = 6 - 4 = 2
  //   故 partial[23:2] = paddr[27:6] 是 cacheline tag；partial[1:0] = paddr[5:4]
  //   是 cacheline 内的 16B-VWord 下标。
  localparam int PADDR_OFFSET = 4;            // paddrOffset (DCacheVWordOffset)
  localparam int PPA_W        = 24;           // PartialPAddrWidth
  localparam int CL_OFFSET    = 2;            // partial 内 cacheline 偏移位置

  // ---- 截取 partial paddr：paddr[PADDR_OFFSET +: PPA_W] ----------------------
  function automatic logic [PPA_W-1:0] gen_partial_paddr(input logic [PADDR_BITS-1:0] paddr);
    return paddr[PADDR_OFFSET +: PPA_W];
  endfunction

  // ===========================================================================
  //  条目内容（per-entry payload）
  //   注意：本核把 partial paddr 与字节 mask 也聚合进 entry struct，对应 Scala 里
  //   独立的 paddrModule/maskModule（LqPAddrModule/LqMaskModule）。两个 Module 本质
  //   是「带 CAM 端口的寄存器阵列」，逻辑上就是每条目各存一份 paddr / mask；本核用
  //   一个 entry 数组表达，CAM 匹配在 store 端口处用 for 展开（见核内 cam 段）。
  // ===========================================================================
  typedef struct packed {
    logic                 robFlag;    // robIdx.flag（年龄比较高位；注意：条目“是否有效”
                                       //   由独立的 allocated[] 表示，不在本 struct 内）
    logic [ROB_W-1:0]     robIdx;     // robIdx.value（年龄比较用）
    logic                 sqFlag;     // sqIdx.flag
    logic [SQ_W-1:0]      sqIdx;      // sqIdx.value（出队释放判定用）
    logic                 isRVC;      // preDecodeInfo.isRVC（rollback target 需要）
    logic                 ftqFlag;    // ftqIdx.flag（rollback 需要）
    logic [FTQ_W-1:0]     ftqPtr;     // ftqIdx.value（rollback 需要）
    logic [FTQOFF_W-1:0]  ftqOffset;  // ftqOffset（rollback 需要）
  } ld_uop_t;

  // ===========================================================================
  //  环形指针年龄比较（与 RobPtr / SqPtr 的 isAfter / isBefore 同源）
  //   环形比较：flag 是高位，value 是低位。两指针「谁更年轻/更靠后」由
  //   flag ^ flag' ^ (value > value') 决定。
  // ===========================================================================

  // rob_is_after：self 是否比 other 更年轻（self 在 other 之后）= isAfter(self, other)
  function automatic logic rob_is_after(
      input logic self_flag, input logic [ROB_W-1:0] self_value,
      input logic other_flag, input logic [ROB_W-1:0] other_value);
    return self_flag ^ other_flag ^ (self_value > other_value);
  endfunction

  // sq_is_before：self 是否比 other 更老（self 在 other 之前）= isBefore(self, other)
  //   isBefore(a,b) = !isAfter(a,b) 且 a != b → 直接展开为 !(a 在 b 之后或相等)。
  //   Chisel isBefore = isAfter(b, a)（严格小于由环形差实现）。这里用 isAfter 取反前
  //   需排除相等：相等时既非 before 也非 after。
  function automatic logic sq_is_before(
      input logic self_flag, input logic [SQ_W-1:0] self_value,
      input logic other_flag, input logic [SQ_W-1:0] other_value);
    // isBefore(self, other) == isAfter(other, self)
    return other_flag ^ self_flag ^ (other_value > self_value);
  endfunction

  // ---- RobIdx 冲刷判定（needFlush(redirect)）--------------------------------
  //   level=1（异常/flushPipe 型）：冲刷与 redirect 同一条 robIdx；
  //   level=0（分支误预测型）：冲刷排在 redirect 之后（更年轻）的所有条。
  function automatic logic rob_need_flush(
      input logic       redir_valid,
      input logic       redir_level,
      input logic       self_flag,
      input logic [ROB_W-1:0] self_value,
      input logic       redir_flag,
      input logic [ROB_W-1:0] redir_value);
    logic flush_itself, flush_after;
    flush_itself = redir_level & (self_flag == redir_flag) & (self_value == redir_value);
    flush_after  = self_flag ^ redir_flag ^ (self_value > redir_value);
    return redir_valid & (flush_itself | flush_after);
  endfunction

  // ===========================================================================
  //  CAM 匹配纯函数
  // ===========================================================================

  // ---- 物理地址 CAM（LqPAddrModule，enableCacheLineCheck=true）--------------
  //   store partial paddr 与某 load 存的 partial paddr 比对，命中条件：
  //     cacheLineHit = 两者 cacheline tag 段相等 (partial[23:2] == partial[23:2])
  //     lowAddrHit   = 两者 VWord 段相等         (partial[1:0]  == partial[1:0])
  //     hit = cacheLineHit && (wlineflag || lowAddrHit)
  //   wlineflag 表示这条 store 写整条 cacheline（cbo.zero 等），此时只要同 cacheline
  //   即命中，忽略低位 VWord 偏移。
  //
  //   ⚠️ 易错点：cacheline tag 与 VWord 的切分点是 CL_OFFSET=2（在 24 位 partial 内），
  //   不是直接对完整 paddr 取 [47:6]/[5:4]。partial 已经右移掉了低 4 位（VWordOffset）。
  function automatic logic paddr_cam_hit(
      input logic [PPA_W-1:0] st_ppa,    // store 的 partial paddr
      input logic [PPA_W-1:0] ld_ppa,    // 在队 load 的 partial paddr
      input logic             wlineflag); // store 写整 cacheline
    logic cache_line_hit, low_addr_hit;
    cache_line_hit = (st_ppa[PPA_W-1:CL_OFFSET] == ld_ppa[PPA_W-1:CL_OFFSET]);
    low_addr_hit   = (st_ppa[CL_OFFSET-1:0]     == ld_ppa[CL_OFFSET-1:0]);
    return cache_line_hit & (wlineflag | low_addr_hit);
  endfunction

  // ---- 字节 mask CAM（LqMaskModule）-----------------------------------------
  //   store 字节 mask 与 load 字节 mask 有任一字节重叠即命中（按位与后 orR）。
  //   仅当 paddr 同 16B-VWord 时，mask 才是同一基准的字节使能，此匹配才有意义；
  //   故最终违例 = paddr_cam_hit & mask_cam_hit。
  function automatic logic mask_cam_hit(
      input logic [MASK_BITS-1:0] st_mask,
      input logic [MASK_BITS-1:0] ld_mask);
    return |(st_mask & ld_mask);
  endfunction

endpackage : loadqueueraw_pkg
