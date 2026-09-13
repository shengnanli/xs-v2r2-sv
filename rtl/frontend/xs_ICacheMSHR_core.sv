// =============================================================================
// xs_ICacheMSHR_core —— 指令缓存单条 MSHR（ICacheMSHR 家族的参数化核）
//
// 位置：ICacheMissUnit 里的一格"未命中状态保持寄存器"。ICache 取指或预取撞到
//       miss 时，MissUnit 挑一个空闲 MSHR 记下这次未命中（块物理地址 + 虚 set
//       索引 + 被替换的 way），向 L2 发一次 TileLink Acquire，等数据回来。
//       一格 MSHR 只跟一次未命中，所以本模块**没有队列、没有数组**，
//       全部状态就是 7 个寄存器。
//
// 状态寄存器（名字沿用 golden）：
//   valid_q     这格被占用（有一次未命中在飞）
//   issued_q    Acquire 已经发出去了（握手成功过一次）
//   blk_paddr_q / vset_idx_q  这次未命中的块物理地址与虚 set 索引
//   way_q       发 Acquire 那一拍锁存的被替换 way（回填要用）
//   flush_q / fencei_q  这格在"被冲掉"期间登记的标记：命中查询与 resp 都要屏蔽
//
// 时序（一拍一件事）：
//   入队 enq  = req_ready & req_valid  —— 空闲且没在被冲，才收新请求；
//   发出 send = acquire_ready & acquire_valid —— 未发过、没在被冲、没进 wfi；
//   valid_q 的清除有两条路：上层 invalid（数据回填完）直接清，
//                          或 kill(fencei|flush) 在**还没发出去**时把它撤掉
//                          （已经发出去的不能撤，得等应答，只能打标记屏蔽）。
//
// ★ golden 的一处冗余，照抄不改（bug-for-bug）：flush_q 与 fencei_q 的次态表达式
//   逐字相同（都是 ~enq & (kill | 自己)），复位值也相同，因此这两个寄存器在任何
//   时刻都恒等。Chisel 侧本意大概是分别记 flush 与 fencei，单态化后合流成了同一
//   个条件。这里保留两个寄存器而不合并，保证与 golden 逐点对应。
//
// 家族形态（见家族参数表）：G1 里 14 个 ICacheMSHR 变体其实只有**两种**模块体，
//   区别只有一条 io_flush 端口 —— 取指 MSHR 没有 flush（只认 fencei），预取 MSHR
//   有。本核始终带 flush 输入，取指变体的薄文件把它接 1'b0，两者随即完全等价。
//
// elaborate 期不变式（见下面 initial）：块地址拼接、查询口数、resp 载荷宽度、
//   golden 端口数恒等式共四条，任何一处位宽/口数抄错 time 0 就 $fatal。
// =============================================================================
module xs_ICacheMSHR_core #(
  parameter int unsigned BLK_PADDR_W = 42,  // 块物理地址（去掉块内偏移后的高位）
  parameter int unsigned VSETIDX_W   = 8,   // 虚 set 索引位宽
  parameter int unsigned WAY_W       = 2,   // way 编号位宽（4 路组相联 -> 2）
  parameter int unsigned OFFSET_W    = 6,   // 块内偏移位数（64B 块 -> 6）
  parameter int unsigned NUM_LOOKUPS = 2,   // 并行命中查询口数
  parameter bit          HAS_FLUSH   = 1'b1,  // golden 是否有 io_flush 端口
  // ---- 下面几个由薄文件从 golden 端口表算出来，只用于自检 ----
  parameter int unsigned PORT_ACQ_ADDR_W  = BLK_PADDR_W + OFFSET_W,
  parameter int unsigned PORT_BITS_LOOKUP = NUM_LOOKUPS * (BLK_PADDR_W + VSETIDX_W),
  parameter int unsigned PORT_BITS_RESP   = BLK_PADDR_W + VSETIDX_W + WAY_W,
  parameter int unsigned GOLDEN_PORTS     = 19 + int'(HAS_FLUSH) + 3 * NUM_LOOKUPS
)(
  input  logic clock,
  input  logic reset,                        // 异步高有效，照搬 golden

  // 冲刷 / 低功耗控制
  input  logic fencei,                       // fence.i：整条 I$ 作废
  input  logic flush,                        // 预取通路的冲刷（取指变体恒 0）
  input  logic wfi_req,                      // 进 wfi 的请求：不许再发新的 Acquire
  output logic wfi_safe,                     // 本格没有在飞的 Acquire，可以睡
  input  logic invalid,                      // 上层宣告本格作废（数据已回填）

  // 入队：一次新的未命中
  output logic                   req_ready,
  input  logic                   req_valid,
  input  logic [BLK_PADDR_W-1:0] req_blk_paddr,
  input  logic [VSETIDX_W-1:0]   req_vset_idx,

  // 出队：向 L2 发 Acquire
  input  logic                        acquire_ready,
  output logic                        acquire_valid,
  output logic [PORT_ACQ_ADDR_W-1:0]  acquire_address,   // = {块地址, 偏移全 0}
  output logic [VSETIDX_W-1:0]        acquire_vset_idx,

  // 并行命中查询（索引 0 在最低位；薄文件按 {lookUps_1, lookUps_0} 拼接）
  input  logic [NUM_LOOKUPS-1:0][BLK_PADDR_W-1:0] lookup_blk_paddr,
  input  logic [NUM_LOOKUPS-1:0][VSETIDX_W-1:0]   lookup_vset_idx,
  output logic [NUM_LOOKUPS-1:0]                  lookup_hit,

  // 本格当前登记的内容（回填通路读）
  output logic                   resp_valid,
  output logic [BLK_PADDR_W-1:0] resp_blk_paddr,
  output logic [VSETIDX_W-1:0]   resp_vset_idx,
  output logic [WAY_W-1:0]       resp_way,
  input  logic [WAY_W-1:0]       victim_way
);

  initial begin
    if (PORT_ACQ_ADDR_W != BLK_PADDR_W + OFFSET_W)
      $fatal(1, "xs_ICacheMSHR_core: golden Acquire 地址 %0d 位 != 块地址(%0d)+偏移(%0d)（位宽抄错）",
             PORT_ACQ_ADDR_W, BLK_PADDR_W, OFFSET_W);
    if (PORT_BITS_LOOKUP != NUM_LOOKUPS * (BLK_PADDR_W + VSETIDX_W))
      $fatal(1, "xs_ICacheMSHR_core: golden 查询口共 %0d 位 != %0d 口 ×(%0d+%0d)（查询口数或位宽抄错）",
             PORT_BITS_LOOKUP, NUM_LOOKUPS, BLK_PADDR_W, VSETIDX_W);
    if (PORT_BITS_RESP != BLK_PADDR_W + VSETIDX_W + WAY_W)
      $fatal(1, "xs_ICacheMSHR_core: golden resp 载荷 %0d 位 != %0d+%0d+%0d（位宽抄错）",
             PORT_BITS_RESP, BLK_PADDR_W, VSETIDX_W, WAY_W);
    // golden 端口数恒等式：19 个固定端口 + 可选的 io_flush + 每个查询口 3 根
    if (GOLDEN_PORTS != 19 + int'(HAS_FLUSH) + 3 * NUM_LOOKUPS)
      $fatal(1, "xs_ICacheMSHR_core: golden 端口数 %0d != 19 + %0d + 3*%0d（查询口数或 flush 有无抄错）",
             GOLDEN_PORTS, int'(HAS_FLUSH), NUM_LOOKUPS);
  end

  logic                   valid_q;
  logic                   flush_q;
  logic                   fencei_q;
  logic                   issued_q;
  logic [BLK_PADDR_W-1:0] blk_paddr_q;
  logic [VSETIDX_W-1:0]   vset_idx_q;
  logic [WAY_W-1:0]       way_q;

  // kill：本拍有人要冲掉这格（fence.i 或预取冲刷）
  logic kill, enq, send;
  assign kill = fencei | flush;

  assign req_ready     = ~valid_q & ~flush & ~fencei;
  assign acquire_valid = valid_q & ~issued_q & ~flush & ~fencei & ~wfi_req;
  assign enq           = req_ready & req_valid;
  assign send          = acquire_ready & acquire_valid;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      valid_q     <= 1'b0;
      flush_q     <= 1'b0;
      fencei_q    <= 1'b0;
      issued_q    <= 1'b0;
      blk_paddr_q <= '0;
      vset_idx_q  <= '0;
      way_q       <= '0;
    end
    else begin
      // 新请求进来就占上；否则 invalid 清、或 kill 在"还没发出去"时撤掉
      valid_q  <= ~invalid & (enq | ~(kill & ~issued_q) & valid_q);
      // 冲刷标记：入队那一拍清零（新请求不受旧冲刷影响），否则见 kill 就置上并保持
      flush_q  <= ~enq & (kill | flush_q);
      fencei_q <= ~enq & (kill | fencei_q);   // 与 flush_q 恒等，见文件头说明
      issued_q <= send | (~enq & issued_q);
      if (enq) begin
        blk_paddr_q <= req_blk_paddr;
        vset_idx_q  <= req_vset_idx;
      end
      if (send)
        way_q <= victim_way;                  // 发出去那一拍才锁存替换 way
    end
  end

  // 有在飞的 Acquire（占用且已发出）时不能进 wfi
  assign wfi_safe = ~(valid_q & issued_q);

  assign acquire_address  = {blk_paddr_q, {OFFSET_W{1'b0}}};
  assign acquire_vset_idx = vset_idx_q;

  // 命中查询：地址与 set 都对上，且这格没被冲刷标记盖住
  for (genvar l = 0; l < NUM_LOOKUPS; l++) begin : g_lookup
    assign lookup_hit[l] = valid_q & ~fencei_q & ~flush_q
                         & (lookup_vset_idx[l]  == vset_idx_q)
                         & (lookup_blk_paddr[l] == blk_paddr_q);
  end

  assign resp_valid     = valid_q & ~flush_q & ~fencei_q;
  assign resp_blk_paddr = blk_paddr_q;
  assign resp_vset_idx  = vset_idx_q;
  assign resp_way       = way_q;

endmodule
