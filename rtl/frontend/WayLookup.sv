// =============================================================================
// xs_WayLookup —— ICache way 查询结果缓冲（IPrefetch → MainPipe 之间的环形 FIFO）
//
// 对应 Chisel: xiangshan.frontend.icache.WayLookup（WayLookup.scala）
//
// 【它在前端的位置】
//   IPrefetch 流水（s1 级）查 ICache meta SRAM，得到「这次取指的两个 cacheline 各命中
//   哪一路（waymask）、物理 tag（ptag）、iTLB 例外/属性、meta ECC」等信息，**写入**本 FIFO；
//   MainPipe 在需要时把队头**读出**，用 waymask 去 data SRAM 取指令数据。两条流水异步推进，
//   故中间用一个深 nWayLookupSize=32 的 FIFO 解耦（IPrefetch 可比 MainPipe 跑得快几拍）。
//
//   IPrefetch.s1 ──write(WayLookupInfo)──▶ [ 环形 FIFO×32 ] ──read──▶ ICacheMainPipe.s0
//                                              ▲
//                          MissUnit ──update（refill 完成后回填命中路）
//
// 【三种访问】
//   write  : IPrefetch 压入一项（命中信息 + 可能的 gpf 信息）；满 / gpf 占用时反压。
//   read   : MainPipe 取队头；空但同拍有 write 时可「旁路」直接把 write 透传到 read（省一拍）。
//   update : MissUnit refill 完一个 cacheline 后，扫描 FIFO 里所有在途项，把「当时 miss、
//            现在这次 refill 正好填的就是它要的 line」的项就地改成 hit（写入 waymask）；
//            反之若某项记的命中路被本次 refill 覆盖（同 way 但 tag 变了），就改回 miss。
//
// 【gpf（guest page fault）信息为何单独存一份】
//   gpf 的 gpaddr 很宽（PAddrBitsMax=56），若每个 entry 都存太费面积。设计观察到：
//   itlb 报 gpf 后必然紧跟一次 flush，所以**整个 FIFO 在被 flush 前最多只会有一个 gpf**。
//   于是把 gpf 信息从 entry 里拆出来，全局只存一份（gpf_entry + gpfPtr 记它属于哪一项）。
//   读到对应项（gpfPtr==readPtr）时把这份 gpf 旁路给 read.bits.gpf，否则输出 0。
//
// 【环形指针 FIFO】
//   readPtr/writePtr 各含 {flag, value(5b)}。empty = 指针全等；full = value 相等但 flag 异。
//   flush 时两指针清零（gpf_entry.valid 也清，无需复位 gpfPtr，因为它靠 valid 兜底）。
// =============================================================================
package xs_waylookup_pkg;
  // ---- 容量/位宽参数（与 KunminghuV2 ICache 一致）----
  localparam int unsigned PORT_NUM     = 2;   // 一次取指跨 2 个 cacheline → 2 个端口
  localparam int unsigned N_ENTRIES    = 32;  // nWayLookupSize：FIFO 深度
  localparam int unsigned PTR_W        = 5;   // log2(N_ENTRIES)，环形指针 value 宽
  localparam int unsigned N_WAYS       = 4;   // 组相联路数 → waymask 宽
  localparam int unsigned IDX_BITS     = 8;   // vSetIdx 宽
  localparam int unsigned TAG_BITS     = 36;  // ptag 宽
  localparam int unsigned EXCP_W       = 2;   // ExceptionType.width
  localparam int unsigned PBMT_W       = 2;   // Pbmt.width
  localparam int unsigned META_CODE_W  = 1;   // ICacheMetaCodeBits（meta ECC 校验位宽）
  localparam int unsigned GPADDR_W     = 56;  // PAddrBitsMax（注意非 GPAddrBits，见 Scala 注释）
  localparam int unsigned BLK_PADDR_W  = 42;  // update 的 blkPaddr 宽
  localparam int unsigned BLK_OFF_BITS = 6;   // log2(blockBytes=64)；ptag = blkPaddr[41:6]

  localparam logic [EXCP_W-1:0] EXCP_GPF = 2'd2;  // ExceptionType.gpf 编码

  // ---- 单端口（一个 cacheline）的查询结果 ----
  typedef struct packed {
    logic [IDX_BITS-1:0]    vSetIdx;        // 虚拟组索引
    logic [N_WAYS-1:0]      waymask;        // 命中路 one-hot（全 0 = miss）
    logic [TAG_BITS-1:0]    ptag;           // 物理 tag
    logic [EXCP_W-1:0]      itlb_exception; // iTLB 例外类型
    logic [PBMT_W-1:0]      itlb_pbmt;      // 页属性（PBMT）
    logic [META_CODE_W-1:0] meta_codes;     // meta ECC（命中路 ptag 的校验位）
  } way_lookup_port_t;

  // ---- 一个 FIFO entry：两个端口（两条 cacheline）----
  typedef struct packed {
    way_lookup_port_t [PORT_NUM-1:0] port;
  } way_lookup_entry_t;

  // ---- gpf 旁路信息（全局只存一份）----
  typedef struct packed {
    logic [GPADDR_W-1:0] gpaddr;
    logic                isForVSnonLeafPTE;
  } way_lookup_gpf_t;

  // 物理 tag 提取：blkPaddr 去掉块内偏移 → 高 TAG_BITS 位
  function automatic logic [TAG_BITS-1:0] get_phy_tag_from_blk(input logic [BLK_PADDR_W-1:0] blk);
    return blk[BLK_PADDR_W-1 : BLK_OFF_BITS];
  endfunction

  // meta ECC 编码：KunminghuV2 用 1-bit 奇偶校验（ptag 全位异或）
  function automatic logic [META_CODE_W-1:0] encode_meta_ecc(input logic [TAG_BITS-1:0] ptag);
    return ^ptag;
  endfunction
endpackage


module xs_WayLookup
  import xs_waylookup_pkg::*;
(
  input  logic                clock,
  input  logic                reset,

  input  logic                io_flush,

  // ---- read 口（→ MainPipe），DecoupledIO ----
  input  logic                io_read_ready,
  output logic                io_read_valid,
  output way_lookup_entry_t   io_read_bits_entry,
  output way_lookup_gpf_t     io_read_bits_gpf,

  // ---- write 口（← IPrefetch），DecoupledIO ----
  output logic                io_write_ready,
  input  logic                io_write_valid,
  input  way_lookup_entry_t   io_write_bits_entry,
  input  way_lookup_gpf_t     io_write_bits_gpf,

  // ---- update 口（← MissUnit），ValidIO ----
  input  logic                   io_update_valid,
  input  logic [BLK_PADDR_W-1:0] io_update_bits_blkPaddr,
  input  logic [IDX_BITS-1:0]    io_update_bits_vSetIdx,
  input  logic [N_WAYS-1:0]      io_update_bits_waymask,
  input  logic                   io_update_bits_corrupt
);

  // ===========================================================================
  // 存储与环形指针
  // ===========================================================================
  way_lookup_entry_t [N_ENTRIES-1:0] entries;

  logic             readPtr_flag,  writePtr_flag;
  logic [PTR_W-1:0] readPtr_value, writePtr_value;

  // empty：读写指针完全相等；full：value 相等而 flag 相反（写绕了一圈追上读）
  wire empty = (readPtr_flag == writePtr_flag) && (readPtr_value == writePtr_value);
  wire full  = (readPtr_value == writePtr_value) && (readPtr_flag ^ writePtr_flag);

  // ===========================================================================
  // gpf 旁路寄存器（全局一份，见模块头说明）
  // ===========================================================================
  way_lookup_gpf_t  gpf_entry_bits;
  logic             gpf_entry_valid;
  logic             gpfPtr_flag;
  logic [PTR_W-1:0] gpfPtr_value;

  // gpf 命中：当前队头正是当初记录 gpf 的那一项，且该份 gpf 仍有效
  wire gpf_hit = (gpfPtr_flag == readPtr_flag) && (gpfPtr_value == readPtr_value) && gpf_entry_valid;

  // ===========================================================================
  // 握手 / 旁路
  // ===========================================================================
  // 空 FIFO 但同拍有 write：直接把 write 透传到 read（省一拍延迟，时序较紧）
  wire can_bypass = empty && io_write_valid;

  // 有一份待读的 gpf 时必须暂停 write（否则新 gpf 会覆盖未读的旧 gpf）；
  // 但若本拍正好把这份 gpf 读走（read.fire && gpf_hit）则不必暂停。
  wire read_fire  = io_read_valid && io_read_ready;
  wire gpf_stall  = gpf_entry_valid && !(read_fire && gpf_hit);

  assign io_read_valid  = !empty || io_write_valid;
  assign io_write_ready = !full && !gpf_stall;

  wire write_fire = io_write_ready && io_write_valid;

  // ===========================================================================
  // read：输出队头（或旁路 write），并旁路 gpf
  // ===========================================================================
  always_comb begin
    if (can_bypass) begin
      // 旁路：write 直透 read（含其自带 gpf）
      io_read_bits_entry = io_write_bits_entry;
      io_read_bits_gpf   = io_write_bits_gpf;
    end else begin
      io_read_bits_entry = entries[readPtr_value];
      // gpf 命中才输出存的那份，否则输出 0
      io_read_bits_gpf   = gpf_hit ? gpf_entry_bits : '0;
    end
  end

  // ===========================================================================
  // 指针更新：flush 清零；否则 fire 时 +1（含 flag 翻转）
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      writePtr_flag  <= 1'b0;
      writePtr_value <= '0;
    end else if (io_flush) begin
      writePtr_flag  <= 1'b0;
      writePtr_value <= '0;
    end else if (write_fire) begin
      if (writePtr_value == PTR_W'(N_ENTRIES - 1)) begin
        writePtr_value <= '0;
        writePtr_flag  <= ~writePtr_flag;   // 绕回 → 翻 flag
      end else begin
        writePtr_value <= writePtr_value + 1'b1;
      end
    end
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      readPtr_flag  <= 1'b0;
      readPtr_value <= '0;
    end else if (io_flush) begin
      readPtr_flag  <= 1'b0;
      readPtr_value <= '0;
    end else if (read_fire) begin
      if (readPtr_value == PTR_W'(N_ENTRIES - 1)) begin
        readPtr_value <= '0;
        readPtr_flag  <= ~readPtr_flag;
      end else begin
        readPtr_value <= readPtr_value + 1'b1;
      end
    end
  end

  // ===========================================================================
  // entries 写回（每个 entry 独立）
  //
  //   每拍每个 entry 二选一：
  //     A. 本拍 write 命中该 entry（write_fire && writePtr==idx）→ 整项写入 write.bits.entry
  //     B. 否则按 update 做 miss↔hit 修正（update 同时作用于所有在途 entry）
  //   这与 golden 的 per-entry `if(write_this) ... else (update)` 结构一致。
  //
  //   update 修正（每端口独立），仅当 update.valid && !corrupt 且 vSetIdx 相同：
  //     · ptag 也相同 → 这正是它当初 miss 的 line 现在被 refill 了：waymask←本次填的路，
  //       并同步更新 meta_codes（用本项 ptag 重算 ECC，比用 update 的 ptag 时序更好）；
  //     · 否则若「本次 refill 的路」恰是本项已记的命中路 → 数据被覆盖：hit→miss，waymask←0。
  // ===========================================================================
  wire                update_active = io_update_valid && !io_update_bits_corrupt;
  wire [TAG_BITS-1:0] update_ptag   = get_phy_tag_from_blk(io_update_bits_blkPaddr);

  genvar gi, gp;
  generate
    for (gi = 0; gi < N_ENTRIES; gi++) begin : g_entry
      // 该 entry 本拍是否被 write 选中
      wire write_this = write_fire && (writePtr_value == PTR_W'(gi));

      for (gp = 0; gp < PORT_NUM; gp++) begin : g_port
        // 该端口的 update 命中判定（vSetIdx 相同是前提）
        wire vset_same = update_active && (io_update_bits_vSetIdx == entries[gi].port[gp].vSetIdx);
        wire ptag_same = (update_ptag == entries[gi].port[gp].ptag);
        wire way_same  = (io_update_bits_waymask == entries[gi].port[gp].waymask);

        // waymask：write 优先，否则 update 修正
        always_ff @(posedge clock or posedge reset) begin
          if (reset)               entries[gi].port[gp].waymask <= '0;
          else if (write_this)     entries[gi].port[gp].waymask <= io_write_bits_entry.port[gp].waymask;
          else if (vset_same) begin
            if (ptag_same)         entries[gi].port[gp].waymask <= io_update_bits_waymask; // miss→hit
            else if (way_same)     entries[gi].port[gp].waymask <= '0;                     // hit→miss
          end
        end

        // meta_codes：write 优先；update miss→hit 时用本项 ptag 重算 ECC
        always_ff @(posedge clock or posedge reset) begin
          if (reset)                          entries[gi].port[gp].meta_codes <= '0;
          else if (write_this)                entries[gi].port[gp].meta_codes <= io_write_bits_entry.port[gp].meta_codes;
          else if (vset_same && ptag_same)    entries[gi].port[gp].meta_codes <= encode_meta_ecc(entries[gi].port[gp].ptag);
        end

        // 其余字段：仅 write 时写入（update 不改）
        always_ff @(posedge clock or posedge reset) begin
          if (reset) begin
            entries[gi].port[gp].vSetIdx        <= '0;
            entries[gi].port[gp].ptag           <= '0;
            entries[gi].port[gp].itlb_exception <= '0;
            entries[gi].port[gp].itlb_pbmt      <= '0;
          end else if (write_this) begin
            entries[gi].port[gp].vSetIdx        <= io_write_bits_entry.port[gp].vSetIdx;
            entries[gi].port[gp].ptag           <= io_write_bits_entry.port[gp].ptag;
            entries[gi].port[gp].itlb_exception <= io_write_bits_entry.port[gp].itlb_exception;
            entries[gi].port[gp].itlb_pbmt      <= io_write_bits_entry.port[gp].itlb_pbmt;
          end
        end
      end
    end
  endgenerate

  // ===========================================================================
  // gpf_entry 维护
  //   - flush：清 valid（及 bits 清零，与 golden 一致）。
  //   - read 命中并 fire（非旁路）：把这份 gpf 读走 → 清 valid。
  //   - write 且写入项带 gpf 例外：记下这份 gpf 与其指针；若该 write 同时被旁路读走则无需置 valid。
  //   优先级：write（含其对 valid 的设置）覆盖 read 的清除——对应 Scala L181 覆盖 L161。
  // ===========================================================================
  // 本拍 write 的项是否携带 gpf 例外（任一端口 itlb_exception==gpf）
  wire write_has_gpf = (io_write_bits_entry.port[0].itlb_exception == EXCP_GPF)
                    || (io_write_bits_entry.port[1].itlb_exception == EXCP_GPF);

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      gpf_entry_valid                  <= 1'b0;
      gpf_entry_bits.gpaddr            <= '0;
      gpf_entry_bits.isForVSnonLeafPTE <= 1'b0;
      gpfPtr_flag                      <= 1'b0;
      gpfPtr_value                     <= '0;
    end else begin
      // 1) flush：丢弃整份 gpf
      if (io_flush) begin
        gpf_entry_valid                  <= 1'b0;
        gpf_entry_bits.gpaddr            <= '0;
        gpf_entry_bits.isForVSnonLeafPTE <= 1'b0;
      end
      // 2) 读走当前 gpf（仅清 valid；旁路读不清，对应 golden 的 .otherwise 分支）
      else if (read_fire && gpf_hit && !can_bypass) begin
        gpf_entry_valid <= 1'b0;
      end

      // 3) write 携带 gpf：登记新 gpf（覆盖上面对 valid 的清除）
      if (write_fire && write_has_gpf) begin
        // 若该 write 被旁路同拍读走，则这份 gpf 无需留存 → valid 置 0
        gpf_entry_valid <= !(can_bypass && read_fire);
        gpf_entry_bits  <= io_write_bits_gpf;
        gpfPtr_flag     <= writePtr_flag;
        gpfPtr_value    <= writePtr_value;
      end
    end
  end

endmodule
