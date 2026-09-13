// =============================================================================
// ICacheMissUnit.sv —— 指令缓存的未命中处理单元（ICache 的 miss/refill 心脏）
//
// 【它在取指流水里的位置】
//   ICacheMainPipe 在 s2 查完 meta SRAM，发现某个取指块不在 cache 里（miss），
//   就把 {块物理地址 blkPaddr, 虚 set 索引 vSetIdx} 交给本单元；IPrefetchPipe
//   也会把预取到的地址交进来。本单元负责四件事：
//     1) 登记：给这次 miss 分配一格 MSHR（未命中状态保持寄存器），并对已经在飞
//        的同一条 cacheline 去重；
//     2) 发射：把 MSHR 的请求仲裁成一路 TileLink Acquire 发给 L2；
//     3) 回填：收 L2 的 Grant（两个 256b beat 拼成一条 512b cacheline），
//        按 source id 找回是哪格 MSHR，写回 meta/data SRAM，并把结果回送取指流水；
//     4) 作废：fence.i / 重定向 flush 到来时把在途请求标记作废。
//
//        fetch_req    ─▶ fetchDemux    ─▶ [4 格取指 MSHR]  ─────────┐
//                                                                   ├─▶ acquireArb ─▶ mem_acquire (TL-A)
//        prefetch_req ─▶ prefetchDemux ─▶ [10 格预取 MSHR] ─▶ prefetchArb ┘
//                              │                                ▲
//                              └─ 入队顺序记进 priorityFIFO ─────┘（谁先进谁先发）
//
//        mem_grant (TL-D) ─▶ 拼两个 beat ─▶ 512b 行 ─▶ 写 meta/data SRAM + fetch_resp
//
// 【为什么 MSHR 要分成取指组和预取组】
//   14 格 MSHR = 4 格取指 + 10 格预取，MSHR 编号就是 TileLink 的 source id
//   （0..3 取指，4..13 预取），L2 的 Grant 靠 source 找回是哪格在等数据。
//   分组的理由有三条，都能在本文件的连线里看到：
//     * 优先级：acquireArb 是固定优先级仲裁器，4 路取指排在预取前面 ——
//       取指 miss 是流水线真的停在那里等，预取只是投机，让路是应该的。
//     * 组内策略不同：取指 4 路之间也按固定优先级（编号小的先），
//       预取 10 路之间却要**按进入 MSHR 的先后**发射，所以多了 priorityFIFO
//       记录 prefetchDemux 选中的格号，prefetchArb（MuxBundle）按队头选路。
//       预取讲究"先看到的地址先取"，编号优先会让高编号格饿死。
//     * 冲刷范围不同：io_flush（分支重定向）只作废预取组；取指组不接 io_flush，
//       只认 io_fencei。取指 miss 已经在飞，结果留着仍有用（下次取指多半还要它），
//       硬撤掉只会立刻再 miss 一次。这就是 golden 里 14 个 MSHR 变体分成
//       "无 io_flush 的 4 个 / 有 io_flush 的 10 个"两种模块体的全部原因。
//
// 【去重（lookUp）】
//   每格 MSHR 都开了两个并行查询口：口 0 比当前 fetch_req，口 1 比当前
//   prefetch_req。任一格命中就说明这条 line 已经在飞：
//     fetch_hit    -> 不再新开 MSHR，但 fetch_req_ready 照样拉高（请求被吞掉）；
//     prefetch_hit -> 同理。prefetch_hit 还额外或上"本拍的预取地址与取指地址撞车"
//                     —— 让取指去取就行，预取不必重复占一格。
//
// 【Acquire 怎么上 TileLink】
//   一格 MSHR 被占上（valid）且还没发过（~issued）时拉 acquire_valid。
//   10 路预取先经 prefetchArb（MuxBundle：按 priorityFIFO 队头的格号选路，
//   顺便把 source id 填成 4+格号）压成一路，再和 4 路取指一起进 acquireArb
//   （Arbiter5：固定优先级，前 4 路的 source id 由仲裁器填常量 0..3）。
//   Acquire 握手成功的那一拍，io_victim_vSetIdx 同步有效 —— 上层的替换算法
//   用它挑一个 victim way，值下一拍从 io_victim_way 回来被 MSHR 锁存。
//
// 【回填数据怎么分发回等待方】
//   L2 的 GrantData 分两个 256b beat 回来（beat 计数器 beat_idx_q 一拍翻一次）：
//   第 0 beat 存 line_data_q[0]，第 1 beat 存 line_data_q[1]，拼成 512b。
//   第 2 个 beat 到达那一拍（line_fire）用 io_mem_grant_bits_source 去查
//   14 格 MSHR 的 resp 端口，把 {blkPaddr, vSetIdx, way} 锁存下来；
//   同一拍把 source 也锁进 resp_id_q，下一拍：
//     * 给那一格 MSHR 打 io_invalid（= line_fire_q & id 相符），把它释放掉；
//     * fetch_resp_valid = 那一格的 resp_valid & line_fire_q，把 512b 行连同
//       waymask 送回取指流水（预取格回填也会走这条路，取指流水按 vSetIdx 自行取舍）；
//     * refill_write_valid 再额外 &~corrupt &~flush &~fencei，才真的写 SRAM。
//   注意"回送流水"和"写 SRAM"的条件不同：flush/fencei 时仍然回送（Scala 注释说
//   是为了让 io_flush -> s2_miss -> s2_ready -> ftq ready 这条时序路径尽快放行，
//   下游自己的 sx_valid 已被冲掉会丢弃它），但绝不能把可能作废的数据写进 SRAM。
//
// 【io_flush / io_fencei 怎么作废在途请求】
//   本层只做两件事，真正的作废语义在 ICacheMSHR 里：
//     * priorityFIFO 的 io_flush = io_flush | io_fencei —— 预取发射顺序整队清空；
//     * io_fencei 广播给全部 14 格，io_flush 只给 10 格预取。
//   MSHR 内部的规矩是：还没发出去的直接撤掉；已经发出去的不能撤（TileLink 事务
//   发了就必须收，否则 source id 泄漏 / 协议违例），只打标记让它的 lookUp 命中与
//   resp_valid 失效，等 Grant 回来再释放。
//
// 【G1 相对 G0 的差异：+2 端口，全是 DiffTest 探针】
//   G1 多了 input io_hartId 与 output [600:0] gatewayIn_packed_2_bore：
//   把这次回填的 {valid, 物理地址, 512b 数据, mask, coreid, index} 打成一根
//   601 位的旁路总线送出去，给 DiffTest 的 refill 事件比对用。golden 顺手把
//   写 SRAM 的使能改名成 difftest_refill_valid（G0 叫 write_sram_valid），
//   表达式一字未变 —— 同一个信号同时当 SRAM 写使能和探针 valid。
//
// 【本文件结构】
//   package icachemissunit_pkg   —— DiffTest refill 探针的 601 位打包格式
//   xs_ICacheMissUnit_core       —— 可读核：数组化的 MSHR 阵列 + 回填状态机
//   ICacheMissUnit               —— golden 同名 wrapper（端口逐位同名）
//
//   19 种子模块都是本工程已重写的可读件，本层直接例化它们（不复制其逻辑）：
//   ICacheMSHR / ICacheMSHR_1..13、DeMultiplexer、DeMultiplexer_1、
//   MuxBundle、Arbiter5_MSHRAcquire、FIFOReg。
// =============================================================================

package icachemissunit_pkg;

  // DiffTest 的 refill 事件探针。golden 把它扁平拼成 gatewayIn_packed_2_bore：
  //   {valid, addr, data_7..data_0, mask, coreid, index} = 1+64+512+8+8+8 = 601 位。
  // 这里用 packed struct 表达同一个布局：packed struct 的第一个字段落在最高位，
  // data 声明成 [7:0][63:0] 时元素 7 也在最高位，两处顺序正好对上。
  typedef struct packed {
    logic             valid;   // 本拍真的把一条 line 写进了 SRAM
    logic [63:0]      addr;    // 该 line 的物理起始地址（块地址左移 6 位）
    logic [7:0][63:0] data;    // 512b cacheline 切成 8 个 64 位字，字 7 在最高位
    logic [7:0]       mask;    // 8 个字全有效，恒 8'hFF
    logic [7:0]       coreid;  // = {7'h0, hartId}
    logic [7:0]       index;   // 恒 0（ICache 只有一个 refill 通道）
  } difftest_refill_t;

  localparam int unsigned DIFFTEST_REFILL_W = $bits(difftest_refill_t);  // 601

endpackage

// =============================================================================
// xs_ICacheMissUnit_core —— 可读核
//
// 端口按语义分组命名；14 格 MSHR 的所有连线都收进 [N_MSHR-1:0] 的数组，
// 数组下标 == MSHR 编号 == TileLink source id，读代码时不必再数第几个实例。
// =============================================================================
module xs_ICacheMissUnit_core
  import icachemissunit_pkg::*;
#(
  parameter int unsigned N_FETCH_MSHR    = 4,   // 取指 MSHR 格数（无 flush）
  parameter int unsigned N_PREFETCH_MSHR = 10,  // 预取 MSHR 格数（有 flush）
  parameter int unsigned BLK_PADDR_W     = 42,  // 块物理地址（去掉块内偏移）
  parameter int unsigned VSETIDX_W       = 8,   // 虚 set 索引
  parameter int unsigned WAY_W           = 2,   // way 编号（4 路组相联）
  parameter int unsigned OFFSET_W        = 6,   // 块内偏移位数（64B 块）
  parameter int unsigned SRC_W           = 4,   // TileLink source id 位宽
  parameter int unsigned BEAT_W          = 256, // TileLink D 通道一拍的数据位宽
  parameter int unsigned GRANT_SIZE_W    = 3,   // Grant 的 size 字段位宽
  parameter int unsigned GRANT_OPCODE_W  = 4,   // Grant 的 opcode 字段位宽
  // ---- 由 wrapper 从 golden 端口表算出来，只用于自检 ----
  parameter int unsigned PORT_ACQ_ADDR_W = BLK_PADDR_W + OFFSET_W,
  parameter int unsigned PORT_LINE_W     = 2 * BEAT_W,
  parameter int unsigned PORT_PHYTAG_W   = BLK_PADDR_W - OFFSET_W,
  parameter int unsigned PORT_WAYMASK_W  = 1 << WAY_W,
  parameter int unsigned PORT_PROBE_W    = DIFFTEST_REFILL_W,
  parameter int unsigned GOLDEN_PORTS    = 44
)(
  input  logic clock,
  input  logic reset,                      // 异步高有效，照搬 golden

  input  logic hart_id,                    // 只喂 DiffTest 探针的 coreid

  // 全局作废 / 低功耗
  input  logic fencei,                     // fence.i：作废全部 14 格
  input  logic flush,                      // 分支重定向：只作废 10 格预取
  input  logic wfi_req,                    // 进 wfi 的请求
  output logic wfi_safe,                   // 14 格都没有在飞的 Acquire

  // 取指 miss 请求入口
  output logic                   fetch_req_ready,
  input  logic                   fetch_req_valid,
  input  logic [BLK_PADDR_W-1:0] fetch_req_blk_paddr,
  input  logic [VSETIDX_W-1:0]   fetch_req_vset_idx,

  // 回填结果回送取指流水（只有 valid，无 ready：下游必收）
  output logic                     fetch_resp_valid,
  output logic [BLK_PADDR_W-1:0]   fetch_resp_blk_paddr,
  output logic [VSETIDX_W-1:0]     fetch_resp_vset_idx,
  output logic [PORT_WAYMASK_W-1:0] fetch_resp_waymask,
  output logic [PORT_LINE_W-1:0]   fetch_resp_data,
  output logic                     fetch_resp_corrupt,

  // 预取 miss 请求入口
  output logic                   prefetch_req_ready,
  input  logic                   prefetch_req_valid,
  input  logic [BLK_PADDR_W-1:0] prefetch_req_blk_paddr,
  input  logic [VSETIDX_W-1:0]   prefetch_req_vset_idx,

  // 回填写 meta SRAM
  output logic                      meta_write_valid,
  output logic [VSETIDX_W-1:0]      meta_write_vir_idx,
  output logic [PORT_PHYTAG_W-1:0]  meta_write_phy_tag,
  output logic [PORT_WAYMASK_W-1:0] meta_write_waymask,
  output logic                      meta_write_bank_idx,

  // 回填写 data SRAM
  output logic                      data_write_valid,
  output logic [VSETIDX_W-1:0]      data_write_vir_idx,
  output logic [PORT_LINE_W-1:0]    data_write_data,
  output logic [PORT_WAYMASK_W-1:0] data_write_waymask,

  // 替换：Acquire 发出那一拍问 victim way，值同拍/次拍由 victim_way 回来
  output logic                 victim_vset_idx_valid,
  output logic [VSETIDX_W-1:0] victim_vset_idx,
  input  logic [WAY_W-1:0]     victim_way,

  // TileLink A 通道（Acquire）
  input  logic                       mem_acquire_ready,
  output logic                       mem_acquire_valid,
  output logic [SRC_W-1:0]           mem_acquire_source,
  output logic [PORT_ACQ_ADDR_W-1:0] mem_acquire_address,

  // TileLink D 通道（Grant）
  input  logic                      mem_grant_valid,
  input  logic [GRANT_OPCODE_W-1:0] mem_grant_opcode,
  input  logic [GRANT_SIZE_W-1:0]   mem_grant_size,
  input  logic [SRC_W-1:0]          mem_grant_source,
  input  logic [BEAT_W-1:0]         mem_grant_data,
  input  logic                      mem_grant_corrupt,

  // DiffTest refill 探针（G1 新增）
  output difftest_refill_t difftest_refill
);

  localparam int unsigned N_MSHR    = N_FETCH_MSHR + N_PREFETCH_MSHR;   // 14
  localparam int unsigned N_SRC     = 1 << SRC_W;                       // 16
  localparam int unsigned N_BEAT    = 2;                                // 512b / 256b
  localparam int unsigned LINE_W    = N_BEAT * BEAT_W;                  // 512
  localparam int unsigned N_WAY     = 1 << WAY_W;                       // 4
  localparam int unsigned PHYTAG_W  = BLK_PADDR_W - OFFSET_W;           // 36

  // ---- elaborate 期不变式：位宽/格数抄错，time 0 就 $fatal ----
  initial begin
    if (N_MSHR > N_SRC)
      $fatal(1, "xs_ICacheMissUnit_core: %0d 格 MSHR 装不进 %0d 位 source id",
             N_MSHR, SRC_W);
    if (PORT_ACQ_ADDR_W != BLK_PADDR_W + OFFSET_W)
      $fatal(1, "xs_ICacheMissUnit_core: golden Acquire 地址 %0d 位 != 块地址(%0d)+偏移(%0d)（位宽抄错）",
             PORT_ACQ_ADDR_W, BLK_PADDR_W, OFFSET_W);
    if (PORT_LINE_W != LINE_W)
      $fatal(1, "xs_ICacheMissUnit_core: golden cacheline %0d 位 != %0d beat ×%0d 位（beat 数或位宽抄错）",
             PORT_LINE_W, N_BEAT, BEAT_W);
    if (PORT_PHYTAG_W != PHYTAG_W)
      $fatal(1, "xs_ICacheMissUnit_core: golden phyTag %0d 位 != 块地址(%0d)-偏移(%0d)（set 数或块大小抄错）",
             PORT_PHYTAG_W, BLK_PADDR_W, OFFSET_W);
    if (PORT_WAYMASK_W != N_WAY)
      $fatal(1, "xs_ICacheMissUnit_core: golden waymask %0d 位 != 2^way 宽(%0d)=%0d（相联度抄错）",
             PORT_WAYMASK_W, WAY_W, N_WAY);
    if (PORT_PROBE_W != DIFFTEST_REFILL_W)
      $fatal(1, "xs_ICacheMissUnit_core: golden 探针 %0d 位 != 结构体 %0d 位（DiffTest 打包格式抄错）",
             PORT_PROBE_W, DIFFTEST_REFILL_W);
    // golden 端口数恒等式：7 个控制 + 取指 req 4 + 取指 resp 6 + 预取 req 4
    // + meta 写 5 + data 写 4 + victim 3 + TL-A 4 + TL-D 6 + 探针 1
    if (GOLDEN_PORTS != 7 + 4 + 6 + 4 + 5 + 4 + 3 + 4 + 6 + 1)
      $fatal(1, "xs_ICacheMissUnit_core: golden 端口数 %0d != 44（端口表变了，核要跟着改）",
             GOLDEN_PORTS);
  end

  // ===========================================================================
  // 1) MSHR 阵列的连线总账
  //    下标 == MSHR 编号 == TileLink source id：0..3 取指，4..13 预取。
  //    凡是被 14 个实例分头驱动的，声明成 wire（每个实例只驱动自己那一位/段）。
  // ===========================================================================
  wire [N_MSHR-1:0]                    mshr_wfi_safe;
  wire [N_MSHR-1:0]                    mshr_req_ready;
  wire [N_MSHR-1:0]                    mshr_req_valid;
  wire [N_MSHR-1:0][BLK_PADDR_W-1:0]   mshr_req_blk_paddr;
  wire [N_MSHR-1:0][VSETIDX_W-1:0]     mshr_req_vset_idx;
  wire [N_MSHR-1:0]                    mshr_acq_ready;
  wire [N_MSHR-1:0]                    mshr_acq_valid;
  wire [N_MSHR-1:0][PORT_ACQ_ADDR_W-1:0] mshr_acq_address;
  wire [N_MSHR-1:0][VSETIDX_W-1:0]     mshr_acq_vset_idx;
  wire [N_MSHR-1:0]                    mshr_hit_fetch;     // 查询口 0：比 fetch_req
  wire [N_MSHR-1:0]                    mshr_hit_prefetch;  // 查询口 1：比 prefetch_req
  wire [N_MSHR-1:0]                    mshr_resp_valid;
  wire [N_MSHR-1:0][BLK_PADDR_W-1:0]   mshr_resp_blk_paddr;
  wire [N_MSHR-1:0][VSETIDX_W-1:0]     mshr_resp_vset_idx;
  wire [N_MSHR-1:0][WAY_W-1:0]         mshr_resp_way;
  wire  [N_MSHR-1:0]                   mshr_invalid;       // 回填完成，释放这一格

  // ===========================================================================
  // 2) 去重：任一格 MSHR 命中就说明这条 line 已经在飞
  // ===========================================================================
  logic fetch_hit, prefetch_hit;
  logic prefetch_same_line_as_fetch;

  assign fetch_hit = |mshr_hit_fetch;
  // 预取额外的一条：本拍的预取地址与本拍的取指地址是同一条 line —— 让取指去取。
  assign prefetch_same_line_as_fetch =
      (prefetch_req_blk_paddr == fetch_req_blk_paddr)
    & (prefetch_req_vset_idx == fetch_req_vset_idx)
    & fetch_req_valid;
  assign prefetch_hit = |mshr_hit_prefetch | prefetch_same_line_as_fetch;

  // 命中就不必新开 MSHR：分发器不用看这次请求。
  logic fetch_alloc_valid, prefetch_alloc_valid;
  logic fetch_alloc_ready, prefetch_alloc_ready;   // 由分发器驱动（有空闲格）
  assign fetch_alloc_valid    = fetch_req_valid    & ~fetch_hit;
  assign prefetch_alloc_valid = prefetch_req_valid & ~prefetch_hit;

  // 对上游而言，"命中被吞掉"也算收下了。
  assign fetch_req_ready    = fetch_alloc_ready    | fetch_hit;
  assign prefetch_req_ready = prefetch_alloc_ready | prefetch_hit;

  // ===========================================================================
  // 3) 预取发射顺序队列：谁先占上格子，谁先发 Acquire
  // ===========================================================================
  logic       prefetch_alloc_fire;   // 本拍真的占上了一格预取 MSHR
  logic [SRC_W-1:0] prefetch_chosen; // 占的是第几格（prefetchDemux 给出，0..9）
  logic       prefetch_order_valid;  // 队头有效
  logic [SRC_W-1:0] prefetch_order_head;
  logic       prefetch_order_ready;  // 队列还能进（FIFO 未满）
  logic       prefetch_acq_fire;     // 队头那一格的 Acquire 本拍被 acquireArb 收走

  assign prefetch_alloc_fire = prefetch_alloc_ready & prefetch_alloc_valid;

  // ===========================================================================
  // 4) Acquire 出口：10 路预取先按队头选成一路，再和 4 路取指定优先级仲裁
  // ===========================================================================
  logic                       prefetch_acq_valid;
  logic                       prefetch_acq_ready;   // = acquireArb 第 5 路 ready
  logic [SRC_W-1:0]           prefetch_acq_source;  // MuxBundle 填的 4+队头
  logic [PORT_ACQ_ADDR_W-1:0] prefetch_acq_address;
  logic [VSETIDX_W-1:0]       prefetch_acq_vset_idx;
  logic                       acq_out_valid;

  assign prefetch_acq_fire = prefetch_acq_ready & prefetch_acq_valid;

  assign mem_acquire_valid = acq_out_valid;
  // Acquire 握手成功那一拍向上层要 victim way（地址已在 mem_acquire_address 上）
  assign victim_vset_idx_valid = mem_acquire_ready & acq_out_valid;

  // ===========================================================================
  // 5) TL-D 回填：两个 256b beat 拼成一条 512b cacheline
  // ===========================================================================
  // TileLink Grant 的 opcode 最低位 = 1 表示"带数据"（GrantData / AccessAckData）。
  logic grant_has_data;
  assign grant_has_data = mem_grant_valid & mem_grant_opcode[0];

  logic                 beat_idx_q;              // golden readBeatCnt：0/1 交替
  logic [BEAT_W-1:0]    line_data_q [N_BEAT];    // golden respDataReg_0/1
  logic                 line_fire;               // golden last_fire：最后一个 beat 到

  assign line_fire = grant_has_data & beat_idx_q;

  // 本次 Grant 是否多于一个 beat。golden 用 TileLink 的 beats1 解码式写成
  // `(13'h3F << size)[5]`：0x3F 铺满第 0..5 位，左移 size 后第 5 位仍为 1
  // 当且仅当 size <= 5（<= 32B，正好一个 beat）；所以取反就是"size >= 6，多 beat"。
  logic [12:0] grant_size_decode;
  logic        grant_multi_beat;
  assign grant_size_decode = 13'h3F << mem_grant_size;
  assign grant_multi_beat  = mem_grant_opcode[0] & ~grant_size_decode[5];

  logic grant_beat_left_q;   // golden refill_done_r_counter：还差几个 beat（0/1）
  logic refill_done;         // 本拍是本次 Grant 的最后一个 beat（按计数器算）
  assign refill_done = (grant_beat_left_q | ~grant_multi_beat) & mem_grant_valid;

  // ---- 回填结果寄存器（第 2 个 beat 到达那一拍锁存）----
  logic                   line_fire_q;        // golden last_fire_r（无复位）
  logic [SRC_W-1:0]       resp_id_q;          // golden id_r（无复位）
  logic                   resp_corrupt_q;
  logic [BLK_PADDR_W-1:0] resp_blk_paddr_q;
  logic [VSETIDX_W-1:0]   resp_vset_idx_q;
  logic [WAY_W-1:0]       resp_way_q;

  // source id 是 4 位（0..15），MSHR 只有 14 格。golden 把 14 格的 resp 端口摊成
  // 一张 16 项查找表，越界的第 14/15 项填的是第 0 格 —— 这是 firtool 展开
  // Chisel Vec 读多路时的兜底分支，正常运行到不了，但 FM 比全状态空间，照抄。
  wire [N_SRC-1:0]                    src_resp_valid;
  wire [N_SRC-1:0][BLK_PADDR_W-1:0]   src_resp_blk_paddr;
  wire [N_SRC-1:0][VSETIDX_W-1:0]     src_resp_vset_idx;
  wire [N_SRC-1:0][WAY_W-1:0]         src_resp_way;
  for (genvar s = 0; s < N_SRC; s++) begin : g_src_table
    localparam int unsigned M = (s < N_MSHR) ? s : 0;
    assign src_resp_valid[s]     = mshr_resp_valid[M];
    assign src_resp_blk_paddr[s] = mshr_resp_blk_paddr[M];
    assign src_resp_vset_idx[s]  = mshr_resp_vset_idx[M];
    assign src_resp_way[s]       = mshr_resp_way[M];
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      beat_idx_q        <= 1'b0;
      line_data_q[0]    <= '0;
      line_data_q[1]    <= '0;
      grant_beat_left_q <= 1'b0;
      resp_corrupt_q    <= 1'b0;
      resp_blk_paddr_q  <= '0;
      resp_vset_idx_q   <= '0;
      resp_way_q        <= '0;
    end
    else begin
      // beat 计数器：只在带数据的 Grant 上翻转（1 位，两个 beat 一轮）
      if (grant_has_data)
        beat_idx_q <= ~beat_idx_q;
      if (grant_has_data & ~beat_idx_q) line_data_q[0] <= mem_grant_data;
      if (grant_has_data &  beat_idx_q) line_data_q[1] <= mem_grant_data;

      // TileLink 的 beats1 倒计数：非首拍就减一，首拍装入本次传输的 beats-1
      if (mem_grant_valid)
        grant_beat_left_q <= grant_beat_left_q ? 1'b0 : grant_multi_beat;

      // corrupt 是"整条 line 的粘滞标记"：任一 beat 带 corrupt 就置上，
      // 一直保持到这条 line 被送走（line_fire_q）的下一拍才允许清。
      resp_corrupt_q <= (grant_has_data & mem_grant_corrupt)
                      | (~line_fire_q & resp_corrupt_q);

      // 最后一个 beat 到达：按 source 查回是哪格 MSHR 在等，锁存它登记的内容
      if (line_fire) begin
        resp_blk_paddr_q <= src_resp_blk_paddr[mem_grant_source];
        resp_vset_idx_q  <= src_resp_vset_idx[mem_grant_source];
        resp_way_q       <= src_resp_way[mem_grant_source];
      end
    end
  end

  // 这两个 golden 里就没有复位（只有随机初值），照搬：无复位的 always_ff。
  always_ff @(posedge clock) begin
    line_fire_q <= line_fire;
    resp_id_q   <= mem_grant_source;
  end

  // ---- 回填结果输出（比 line_fire 晚一拍）----
  logic [PORT_WAYMASK_W-1:0] resp_waymask;
  logic [LINE_W-1:0]         resp_line;
  logic                      refill_resp_valid;   // golden fetch_resp_valid
  logic                      refill_write_valid;  // golden difftest_refill_valid
                                                  // （G0 叫 write_sram_valid）

  assign resp_waymask      = PORT_WAYMASK_W'(1) << resp_way_q;
  assign resp_line         = {line_data_q[1], line_data_q[0]};
  assign refill_resp_valid = src_resp_valid[resp_id_q] & line_fire_q;
  // 写 SRAM 比回送流水多三个条件：数据没坏，且这一拍没有 flush / fencei
  assign refill_write_valid = refill_resp_valid & ~resp_corrupt_q & ~flush & ~fencei;

  // 回填完成，释放那一格 MSHR
  for (genvar k = 0; k < N_MSHR; k++) begin : g_invalid
    assign mshr_invalid[k] = line_fire_q & (resp_id_q == SRC_W'(k));
  end

  // ---- 输出 ----
  assign fetch_resp_valid     = refill_resp_valid;
  assign fetch_resp_blk_paddr = resp_blk_paddr_q;
  assign fetch_resp_vset_idx  = resp_vset_idx_q;
  assign fetch_resp_waymask   = resp_waymask;
  assign fetch_resp_data      = resp_line;
  assign fetch_resp_corrupt   = resp_corrupt_q;

  assign meta_write_valid    = refill_write_valid;
  assign meta_write_vir_idx  = resp_vset_idx_q;
  assign meta_write_phy_tag  = resp_blk_paddr_q[BLK_PADDR_W-1 -: PHYTAG_W];
  assign meta_write_waymask  = resp_waymask;
  // meta SRAM 分两个 bank，按 set 索引的最低位分（相邻 set 落不同 bank）
  assign meta_write_bank_idx = resp_vset_idx_q[0];

  assign data_write_valid   = refill_write_valid;
  assign data_write_vir_idx = resp_vset_idx_q;
  assign data_write_data    = resp_line;
  assign data_write_waymask = resp_waymask;

  assign wfi_safe = &mshr_wfi_safe;

  // ---- DiffTest refill 探针（G1 新增，不参与任何功能通路）----
  always_comb begin
    difftest_refill        = '0;
    difftest_refill.valid  = refill_write_valid;
    difftest_refill.addr   = 64'({resp_blk_paddr_q, {OFFSET_W{1'b0}}});
    for (int unsigned w = 0; w < 8; w++)
      difftest_refill.data[w] = resp_line[w*64 +: 64];
    difftest_refill.mask   = 8'hFF;
    difftest_refill.coreid = 8'(hart_id);
    difftest_refill.index  = 8'h0;
  end

`ifndef SYNTHESIS
  // golden 的三条 Scala assert（ICacheMissUnit.scala:320 / 324 / 348）。
  always @(posedge clock) begin
    if (!reset) begin
      // 预取占上一格与"记进发射顺序队列"必须同拍完成，否则顺序就丢了
      assert (!(prefetch_order_ready & prefetch_alloc_fire ^ prefetch_alloc_fire))
        else $error("priorityFIFO.io.enq and io.prefetch_req must fire at the same cycle");
      // 队头出队与预取 Acquire 发出必须同拍，否则队头会指错格子
      assert (!(prefetch_acq_fire & prefetch_order_valid ^ prefetch_acq_fire))
        else $error("priorityFIFO.io.deq and prefetchArb.io.out must fire at the same cycle");
      // beat 计数器与 TileLink 的 beats1 倒计数必须同时判"最后一拍"
      assert (!(refill_done ^ line_fire))
        else $error("refill not done!");
    end
  end
`endif

  // ===========================================================================
  // 6) 子模块例化
  // ===========================================================================

  // ---- 6a) 取指 miss 分发：一入四出，按 ready 优先级投给空闲的取指 MSHR ----
  DeMultiplexer fetchDemux (
    .io_in_ready            (fetch_alloc_ready),
    .io_in_valid            (fetch_alloc_valid),
    .io_in_bits_blkPaddr    (fetch_req_blk_paddr),
    .io_in_bits_vSetIdx     (fetch_req_vset_idx),
    .io_out_0_ready         (mshr_req_ready[0]),
    .io_out_0_valid         (mshr_req_valid[0]),
    .io_out_0_bits_blkPaddr (mshr_req_blk_paddr[0]),
    .io_out_0_bits_vSetIdx  (mshr_req_vset_idx[0]),
    .io_out_1_ready         (mshr_req_ready[1]),
    .io_out_1_valid         (mshr_req_valid[1]),
    .io_out_1_bits_blkPaddr (mshr_req_blk_paddr[1]),
    .io_out_1_bits_vSetIdx  (mshr_req_vset_idx[1]),
    .io_out_2_ready         (mshr_req_ready[2]),
    .io_out_2_valid         (mshr_req_valid[2]),
    .io_out_2_bits_blkPaddr (mshr_req_blk_paddr[2]),
    .io_out_2_bits_vSetIdx  (mshr_req_vset_idx[2]),
    .io_out_3_ready         (mshr_req_ready[3]),
    .io_out_3_valid         (mshr_req_valid[3]),
    .io_out_3_bits_blkPaddr (mshr_req_blk_paddr[3]),
    .io_out_3_bits_vSetIdx  (mshr_req_vset_idx[3])
  );

  // ---- 6b) 预取 miss 分发：一入十出，另外报出选中的格号（进发射顺序队列）----
  DeMultiplexer_1 prefetchDemux (
    .io_in_ready            (prefetch_alloc_ready),
    .io_in_valid            (prefetch_alloc_valid),
    .io_in_bits_blkPaddr    (prefetch_req_blk_paddr),
    .io_in_bits_vSetIdx     (prefetch_req_vset_idx),
    .io_out_0_ready         (mshr_req_ready[4]),
    .io_out_0_valid         (mshr_req_valid[4]),
    .io_out_0_bits_blkPaddr (mshr_req_blk_paddr[4]),
    .io_out_0_bits_vSetIdx  (mshr_req_vset_idx[4]),
    .io_out_1_ready         (mshr_req_ready[5]),
    .io_out_1_valid         (mshr_req_valid[5]),
    .io_out_1_bits_blkPaddr (mshr_req_blk_paddr[5]),
    .io_out_1_bits_vSetIdx  (mshr_req_vset_idx[5]),
    .io_out_2_ready         (mshr_req_ready[6]),
    .io_out_2_valid         (mshr_req_valid[6]),
    .io_out_2_bits_blkPaddr (mshr_req_blk_paddr[6]),
    .io_out_2_bits_vSetIdx  (mshr_req_vset_idx[6]),
    .io_out_3_ready         (mshr_req_ready[7]),
    .io_out_3_valid         (mshr_req_valid[7]),
    .io_out_3_bits_blkPaddr (mshr_req_blk_paddr[7]),
    .io_out_3_bits_vSetIdx  (mshr_req_vset_idx[7]),
    .io_out_4_ready         (mshr_req_ready[8]),
    .io_out_4_valid         (mshr_req_valid[8]),
    .io_out_4_bits_blkPaddr (mshr_req_blk_paddr[8]),
    .io_out_4_bits_vSetIdx  (mshr_req_vset_idx[8]),
    .io_out_5_ready         (mshr_req_ready[9]),
    .io_out_5_valid         (mshr_req_valid[9]),
    .io_out_5_bits_blkPaddr (mshr_req_blk_paddr[9]),
    .io_out_5_bits_vSetIdx  (mshr_req_vset_idx[9]),
    .io_out_6_ready         (mshr_req_ready[10]),
    .io_out_6_valid         (mshr_req_valid[10]),
    .io_out_6_bits_blkPaddr (mshr_req_blk_paddr[10]),
    .io_out_6_bits_vSetIdx  (mshr_req_vset_idx[10]),
    .io_out_7_ready         (mshr_req_ready[11]),
    .io_out_7_valid         (mshr_req_valid[11]),
    .io_out_7_bits_blkPaddr (mshr_req_blk_paddr[11]),
    .io_out_7_bits_vSetIdx  (mshr_req_vset_idx[11]),
    .io_out_8_ready         (mshr_req_ready[12]),
    .io_out_8_valid         (mshr_req_valid[12]),
    .io_out_8_bits_blkPaddr (mshr_req_blk_paddr[12]),
    .io_out_8_bits_vSetIdx  (mshr_req_vset_idx[12]),
    .io_out_9_ready         (mshr_req_ready[13]),
    .io_out_9_valid         (mshr_req_valid[13]),
    .io_out_9_bits_blkPaddr (mshr_req_blk_paddr[13]),
    .io_out_9_bits_vSetIdx  (mshr_req_vset_idx[13]),
    .io_chosen              (prefetch_chosen)
  );

  // ---- 6c) 预取发射顺序队列（10 深 × 4 位，存"占上的是第几格"）----
  //      flush 或 fencei 一来整队清空：那些格子马上要被作废，顺序也就无意义了。
  FIFOReg priorityFIFO (
    .clock        (clock),
    .reset        (reset),
    .io_enq_ready (prefetch_order_ready),
    .io_enq_valid (prefetch_alloc_fire),
    .io_enq_bits  (prefetch_chosen),
    .io_deq_ready (prefetch_acq_fire),
    .io_deq_valid (prefetch_order_valid),
    .io_deq_bits  (prefetch_order_head),
    .io_flush     (flush | fencei)
  );

  // ---- 6d) 预取 Acquire 出口：按队头格号十选一，顺便填 source = 4 + 格号 ----
  MuxBundle prefetchArb (
    .io_sel                       (prefetch_order_head),
    .io_in_0_ready                (mshr_acq_ready[4]),
    .io_in_0_valid                (mshr_acq_valid[4]),
    .io_in_0_bits_acquire_address (mshr_acq_address[4]),
    .io_in_0_bits_vSetIdx         (mshr_acq_vset_idx[4]),
    .io_in_1_ready                (mshr_acq_ready[5]),
    .io_in_1_valid                (mshr_acq_valid[5]),
    .io_in_1_bits_acquire_address (mshr_acq_address[5]),
    .io_in_1_bits_vSetIdx         (mshr_acq_vset_idx[5]),
    .io_in_2_ready                (mshr_acq_ready[6]),
    .io_in_2_valid                (mshr_acq_valid[6]),
    .io_in_2_bits_acquire_address (mshr_acq_address[6]),
    .io_in_2_bits_vSetIdx         (mshr_acq_vset_idx[6]),
    .io_in_3_ready                (mshr_acq_ready[7]),
    .io_in_3_valid                (mshr_acq_valid[7]),
    .io_in_3_bits_acquire_address (mshr_acq_address[7]),
    .io_in_3_bits_vSetIdx         (mshr_acq_vset_idx[7]),
    .io_in_4_ready                (mshr_acq_ready[8]),
    .io_in_4_valid                (mshr_acq_valid[8]),
    .io_in_4_bits_acquire_address (mshr_acq_address[8]),
    .io_in_4_bits_vSetIdx         (mshr_acq_vset_idx[8]),
    .io_in_5_ready                (mshr_acq_ready[9]),
    .io_in_5_valid                (mshr_acq_valid[9]),
    .io_in_5_bits_acquire_address (mshr_acq_address[9]),
    .io_in_5_bits_vSetIdx         (mshr_acq_vset_idx[9]),
    .io_in_6_ready                (mshr_acq_ready[10]),
    .io_in_6_valid                (mshr_acq_valid[10]),
    .io_in_6_bits_acquire_address (mshr_acq_address[10]),
    .io_in_6_bits_vSetIdx         (mshr_acq_vset_idx[10]),
    .io_in_7_ready                (mshr_acq_ready[11]),
    .io_in_7_valid                (mshr_acq_valid[11]),
    .io_in_7_bits_acquire_address (mshr_acq_address[11]),
    .io_in_7_bits_vSetIdx         (mshr_acq_vset_idx[11]),
    .io_in_8_ready                (mshr_acq_ready[12]),
    .io_in_8_valid                (mshr_acq_valid[12]),
    .io_in_8_bits_acquire_address (mshr_acq_address[12]),
    .io_in_8_bits_vSetIdx         (mshr_acq_vset_idx[12]),
    .io_in_9_ready                (mshr_acq_ready[13]),
    .io_in_9_valid                (mshr_acq_valid[13]),
    .io_in_9_bits_acquire_address (mshr_acq_address[13]),
    .io_in_9_bits_vSetIdx         (mshr_acq_vset_idx[13]),
    .io_out_ready                 (prefetch_acq_ready),
    .io_out_valid                 (prefetch_acq_valid),
    .io_out_bits_acquire_source   (prefetch_acq_source),
    .io_out_bits_acquire_address  (prefetch_acq_address),
    .io_out_bits_vSetIdx          (prefetch_acq_vset_idx)
  );

  // ---- 6e) TL-A 总出口：4 路取指优先，预取那一路排最后 ----
  //      前 4 路没有 source 端口，仲裁器替它们填常量 0..3（= MSHR 编号）。
  Arbiter5_MSHRAcquire acquireArb (
    .io_in_0_ready                (mshr_acq_ready[0]),
    .io_in_0_valid                (mshr_acq_valid[0]),
    .io_in_0_bits_acquire_address (mshr_acq_address[0]),
    .io_in_0_bits_vSetIdx         (mshr_acq_vset_idx[0]),
    .io_in_1_ready                (mshr_acq_ready[1]),
    .io_in_1_valid                (mshr_acq_valid[1]),
    .io_in_1_bits_acquire_address (mshr_acq_address[1]),
    .io_in_1_bits_vSetIdx         (mshr_acq_vset_idx[1]),
    .io_in_2_ready                (mshr_acq_ready[2]),
    .io_in_2_valid                (mshr_acq_valid[2]),
    .io_in_2_bits_acquire_address (mshr_acq_address[2]),
    .io_in_2_bits_vSetIdx         (mshr_acq_vset_idx[2]),
    .io_in_3_ready                (mshr_acq_ready[3]),
    .io_in_3_valid                (mshr_acq_valid[3]),
    .io_in_3_bits_acquire_address (mshr_acq_address[3]),
    .io_in_3_bits_vSetIdx         (mshr_acq_vset_idx[3]),
    .io_in_4_ready                (prefetch_acq_ready),
    .io_in_4_valid                (prefetch_acq_valid),
    .io_in_4_bits_acquire_source  (prefetch_acq_source),
    .io_in_4_bits_acquire_address (prefetch_acq_address),
    .io_in_4_bits_vSetIdx         (prefetch_acq_vset_idx),
    .io_out_ready                 (mem_acquire_ready),
    .io_out_valid                 (acq_out_valid),
    .io_out_bits_acquire_source   (mem_acquire_source),
    .io_out_bits_acquire_address  (mem_acquire_address),
    .io_out_bits_vSetIdx          (victim_vset_idx)
  );

  // ---- 6f) 14 格 MSHR ----
  //   firtool 把同一份 MSHR 逻辑单态化复制成了 14 个模块名（取指 4 个无 io_flush、
  //   预取 10 个有），端口连线一模一样，只差数组下标。所以这里把连线写成一个宏，
  //   14 行例化。宏体在下面 `undef 掉，不外泄。
  //   （这不是 include 套壳：宏体就在眼前 25 行，展开成什么一目了然。）
`define XS_IMU_MSHR_PORTS(K)                                        \
    .clock                           (clock),                       \
    .reset                           (reset),                       \
    .io_fencei                       (fencei),                      \
    .io_wfi_wfiReq                   (wfi_req),                     \
    .io_wfi_wfiSafe                  (mshr_wfi_safe[K]),            \
    .io_invalid                      (mshr_invalid[K]),             \
    .io_req_ready                    (mshr_req_ready[K]),           \
    .io_req_valid                    (mshr_req_valid[K]),           \
    .io_req_bits_blkPaddr            (mshr_req_blk_paddr[K]),       \
    .io_req_bits_vSetIdx             (mshr_req_vset_idx[K]),        \
    .io_acquire_ready                (mshr_acq_ready[K]),           \
    .io_acquire_valid                (mshr_acq_valid[K]),           \
    .io_acquire_bits_acquire_address (mshr_acq_address[K]),         \
    .io_acquire_bits_vSetIdx         (mshr_acq_vset_idx[K]),        \
    .io_lookUps_0_info_bits_blkPaddr (fetch_req_blk_paddr),         \
    .io_lookUps_0_info_bits_vSetIdx  (fetch_req_vset_idx),          \
    .io_lookUps_0_hit                (mshr_hit_fetch[K]),           \
    .io_lookUps_1_info_bits_blkPaddr (prefetch_req_blk_paddr),      \
    .io_lookUps_1_info_bits_vSetIdx  (prefetch_req_vset_idx),       \
    .io_lookUps_1_hit                (mshr_hit_prefetch[K]),        \
    .io_resp_valid                   (mshr_resp_valid[K]),          \
    .io_resp_bits_blkPaddr           (mshr_resp_blk_paddr[K]),      \
    .io_resp_bits_vSetIdx            (mshr_resp_vset_idx[K]),       \
    .io_resp_bits_way                (mshr_resp_way[K]),            \
    .io_victimWay                    (victim_way)

  // source id 0..3：取指 MSHR，不接 io_flush（重定向不撤在途取指）
  ICacheMSHR    fetchMSHRs_0    (`XS_IMU_MSHR_PORTS(0));
  ICacheMSHR_1  fetchMSHRs_1    (`XS_IMU_MSHR_PORTS(1));
  ICacheMSHR_2  fetchMSHRs_2    (`XS_IMU_MSHR_PORTS(2));
  ICacheMSHR_3  fetchMSHRs_3    (`XS_IMU_MSHR_PORTS(3));

  // source id 4..13：预取 MSHR，多一条 io_flush
  ICacheMSHR_4  prefetchMSHRs_0 (.io_flush(flush), `XS_IMU_MSHR_PORTS(4));
  ICacheMSHR_5  prefetchMSHRs_1 (.io_flush(flush), `XS_IMU_MSHR_PORTS(5));
  ICacheMSHR_6  prefetchMSHRs_2 (.io_flush(flush), `XS_IMU_MSHR_PORTS(6));
  ICacheMSHR_7  prefetchMSHRs_3 (.io_flush(flush), `XS_IMU_MSHR_PORTS(7));
  ICacheMSHR_8  prefetchMSHRs_4 (.io_flush(flush), `XS_IMU_MSHR_PORTS(8));
  ICacheMSHR_9  prefetchMSHRs_5 (.io_flush(flush), `XS_IMU_MSHR_PORTS(9));
  ICacheMSHR_10 prefetchMSHRs_6 (.io_flush(flush), `XS_IMU_MSHR_PORTS(10));
  ICacheMSHR_11 prefetchMSHRs_7 (.io_flush(flush), `XS_IMU_MSHR_PORTS(11));
  ICacheMSHR_12 prefetchMSHRs_8 (.io_flush(flush), `XS_IMU_MSHR_PORTS(12));
  ICacheMSHR_13 prefetchMSHRs_9 (.io_flush(flush), `XS_IMU_MSHR_PORTS(13));

`undef XS_IMU_MSHR_PORTS

endmodule

// =============================================================================
// ICacheMissUnit —— golden 同名 wrapper
//   端口与 G1 golden 逐位同名同序同宽；只做改名与探针结构体的拆包。
// =============================================================================
module ICacheMissUnit
  import icachemissunit_pkg::*;
(
  input          clock,
  input          reset,
  input          io_hartId,
  input          io_fencei,
  input          io_flush,
  input          io_wfi_wfiReq,
  output         io_wfi_wfiSafe,
  output         io_fetch_req_ready,
  input          io_fetch_req_valid,
  input  [41:0]  io_fetch_req_bits_blkPaddr,
  input  [7:0]   io_fetch_req_bits_vSetIdx,
  output         io_fetch_resp_valid,
  output [41:0]  io_fetch_resp_bits_blkPaddr,
  output [7:0]   io_fetch_resp_bits_vSetIdx,
  output [3:0]   io_fetch_resp_bits_waymask,
  output [511:0] io_fetch_resp_bits_data,
  output         io_fetch_resp_bits_corrupt,
  output         io_prefetch_req_ready,
  input          io_prefetch_req_valid,
  input  [41:0]  io_prefetch_req_bits_blkPaddr,
  input  [7:0]   io_prefetch_req_bits_vSetIdx,
  output         io_meta_write_valid,
  output [7:0]   io_meta_write_bits_virIdx,
  output [35:0]  io_meta_write_bits_phyTag,
  output [3:0]   io_meta_write_bits_waymask,
  output         io_meta_write_bits_bankIdx,
  output         io_data_write_valid,
  output [7:0]   io_data_write_bits_virIdx,
  output [511:0] io_data_write_bits_data,
  output [3:0]   io_data_write_bits_waymask,
  output         io_victim_vSetIdx_valid,
  output [7:0]   io_victim_vSetIdx_bits,
  input  [1:0]   io_victim_way,
  input          io_mem_acquire_ready,
  output         io_mem_acquire_valid,
  output [3:0]   io_mem_acquire_bits_source,
  output [47:0]  io_mem_acquire_bits_address,
  input          io_mem_grant_valid,
  input  [3:0]   io_mem_grant_bits_opcode,
  input  [2:0]   io_mem_grant_bits_size,
  input  [3:0]   io_mem_grant_bits_source,
  input  [255:0] io_mem_grant_bits_data,
  input          io_mem_grant_bits_corrupt,
  output [600:0] gatewayIn_packed_2_bore
);

  difftest_refill_t difftest_refill;
  assign gatewayIn_packed_2_bore = difftest_refill;

  xs_ICacheMissUnit_core #(
    .N_FETCH_MSHR    (4),
    .N_PREFETCH_MSHR (10),
    .BLK_PADDR_W     (42),
    .VSETIDX_W       (8),
    .WAY_W           (2),
    .OFFSET_W        (6),
    .SRC_W           (4),
    .BEAT_W          (256),
    .GRANT_SIZE_W    (3),
    .GRANT_OPCODE_W  (4),
    // 端口表事实：$bits 只认端口声明，抄错位宽这些常量立刻跟着变
    .PORT_ACQ_ADDR_W ($bits(io_mem_acquire_bits_address)),
    .PORT_LINE_W     ($bits(io_data_write_bits_data)),
    .PORT_PHYTAG_W   ($bits(io_meta_write_bits_phyTag)),
    .PORT_WAYMASK_W  ($bits(io_meta_write_bits_waymask)),
    .PORT_PROBE_W    ($bits(gatewayIn_packed_2_bore)),
    .GOLDEN_PORTS    (44)
  ) u_core (
    .clock                 (clock),
    .reset                 (reset),
    .hart_id               (io_hartId),
    .fencei                (io_fencei),
    .flush                 (io_flush),
    .wfi_req               (io_wfi_wfiReq),
    .wfi_safe              (io_wfi_wfiSafe),

    .fetch_req_ready       (io_fetch_req_ready),
    .fetch_req_valid       (io_fetch_req_valid),
    .fetch_req_blk_paddr   (io_fetch_req_bits_blkPaddr),
    .fetch_req_vset_idx    (io_fetch_req_bits_vSetIdx),

    .fetch_resp_valid      (io_fetch_resp_valid),
    .fetch_resp_blk_paddr  (io_fetch_resp_bits_blkPaddr),
    .fetch_resp_vset_idx   (io_fetch_resp_bits_vSetIdx),
    .fetch_resp_waymask    (io_fetch_resp_bits_waymask),
    .fetch_resp_data       (io_fetch_resp_bits_data),
    .fetch_resp_corrupt    (io_fetch_resp_bits_corrupt),

    .prefetch_req_ready    (io_prefetch_req_ready),
    .prefetch_req_valid    (io_prefetch_req_valid),
    .prefetch_req_blk_paddr(io_prefetch_req_bits_blkPaddr),
    .prefetch_req_vset_idx (io_prefetch_req_bits_vSetIdx),

    .meta_write_valid      (io_meta_write_valid),
    .meta_write_vir_idx    (io_meta_write_bits_virIdx),
    .meta_write_phy_tag    (io_meta_write_bits_phyTag),
    .meta_write_waymask    (io_meta_write_bits_waymask),
    .meta_write_bank_idx   (io_meta_write_bits_bankIdx),

    .data_write_valid      (io_data_write_valid),
    .data_write_vir_idx    (io_data_write_bits_virIdx),
    .data_write_data       (io_data_write_bits_data),
    .data_write_waymask    (io_data_write_bits_waymask),

    .victim_vset_idx_valid (io_victim_vSetIdx_valid),
    .victim_vset_idx       (io_victim_vSetIdx_bits),
    .victim_way            (io_victim_way),

    .mem_acquire_ready     (io_mem_acquire_ready),
    .mem_acquire_valid     (io_mem_acquire_valid),
    .mem_acquire_source    (io_mem_acquire_bits_source),
    .mem_acquire_address   (io_mem_acquire_bits_address),

    .mem_grant_valid       (io_mem_grant_valid),
    .mem_grant_opcode      (io_mem_grant_bits_opcode),
    .mem_grant_size        (io_mem_grant_bits_size),
    .mem_grant_source      (io_mem_grant_bits_source),
    .mem_grant_data        (io_mem_grant_bits_data),
    .mem_grant_corrupt     (io_mem_grant_bits_corrupt),

    .difftest_refill       (difftest_refill)
  );

endmodule
