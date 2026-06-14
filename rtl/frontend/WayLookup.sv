// =============================================================================
// xs_WayLookup_core —— ICache WayLookup（way 查询缓冲 FIFO）
//
// 对应 Chisel: xiangshan.frontend.icache.WayLookup
//
// 一个深度 NWAYLOOKUP 的循环 FIFO，缓冲 ICache 主流水的 way 查询信息（每个
// 条目含两个取指端口 PortNumber=2 的 vSetIdx/waymask/ptag/itlb_exception/
// itlb_pbmt/meta_codes）。三个接口：
//   - write：IFU 预取阶段写入 way 查询结果（DecoupledIO）
//   - read ：主流水读出（DecoupledIO）；FIFO 空但有写入时旁路直通 write→read
//   - update：MissUnit 回填后修正 waymask（命中/被覆盖时翻转），并重算 meta ECC
//
// GPF（guest page fault）信息单独存一份（gpf_entry + gpfPtr）：因为一旦发生
// gpf 必然紧跟一次 flush，整个 FIFO 生命周期里至多一个 gpf，无需逐条目存。
//
// 寄存器命名沿用 golden（entries_<i>_<field>_<port> / readPtr / writePtr /
// gpf_entry / gpfPtr），便于 Formality 按名匹配。
// =============================================================================
module xs_WayLookup_core #(
  parameter int unsigned NWAY        = 32,  // nWayLookupSize（FIFO 深度）
  parameter int unsigned PTR_W       = 5,   // log2(NWAY)
  parameter int unsigned VSETIDX_W   = 8,   // idxBits
  parameter int unsigned WAYMASK_W   = 4,   // nWays
  parameter int unsigned PTAG_W      = 36,  // tagBits
  parameter int unsigned EXCP_W      = 2,   // ExceptionType.width
  parameter int unsigned PBMT_W      = 2,   // Pbmt.width
  parameter int unsigned META_W      = 1,   // ICacheMetaCodeBits
  parameter int unsigned GPADDR_W    = 56,  // PAddrBitsMax
  parameter int unsigned BLKPADDR_W  = 42,  // io_update_bits_blkPaddr
  parameter int unsigned UPDVSET_W   = 8,
  // ExceptionType.gpf 编码
  parameter logic [EXCP_W-1:0] EXCP_GPF = 2'h2
)(
  input  logic                  clock,
  input  logic                  reset,
  input  logic                  io_flush,

  // ---- read 端口（输出读出的条目）----
  input  logic                  io_read_ready,
  output logic                  io_read_valid,
  output logic [VSETIDX_W-1:0]  io_read_bits_entry_vSetIdx_0,
  output logic [VSETIDX_W-1:0]  io_read_bits_entry_vSetIdx_1,
  output logic [WAYMASK_W-1:0]  io_read_bits_entry_waymask_0,
  output logic [WAYMASK_W-1:0]  io_read_bits_entry_waymask_1,
  output logic [PTAG_W-1:0]     io_read_bits_entry_ptag_0,
  output logic [PTAG_W-1:0]     io_read_bits_entry_ptag_1,
  output logic [EXCP_W-1:0]     io_read_bits_entry_itlb_exception_0,
  output logic [EXCP_W-1:0]     io_read_bits_entry_itlb_exception_1,
  output logic [PBMT_W-1:0]     io_read_bits_entry_itlb_pbmt_0,
  output logic [PBMT_W-1:0]     io_read_bits_entry_itlb_pbmt_1,
  output logic [META_W-1:0]     io_read_bits_entry_meta_codes_0,
  output logic [META_W-1:0]     io_read_bits_entry_meta_codes_1,
  output logic [GPADDR_W-1:0]   io_read_bits_gpf_gpaddr,
  output logic                  io_read_bits_gpf_isForVSnonLeafPTE,

  // ---- write 端口（输入待写条目）----
  output logic                  io_write_ready,
  input  logic                  io_write_valid,
  input  logic [VSETIDX_W-1:0]  io_write_bits_entry_vSetIdx_0,
  input  logic [VSETIDX_W-1:0]  io_write_bits_entry_vSetIdx_1,
  input  logic [WAYMASK_W-1:0]  io_write_bits_entry_waymask_0,
  input  logic [WAYMASK_W-1:0]  io_write_bits_entry_waymask_1,
  input  logic [PTAG_W-1:0]     io_write_bits_entry_ptag_0,
  input  logic [PTAG_W-1:0]     io_write_bits_entry_ptag_1,
  input  logic [EXCP_W-1:0]     io_write_bits_entry_itlb_exception_0,
  input  logic [EXCP_W-1:0]     io_write_bits_entry_itlb_exception_1,
  input  logic [PBMT_W-1:0]     io_write_bits_entry_itlb_pbmt_0,
  input  logic [PBMT_W-1:0]     io_write_bits_entry_itlb_pbmt_1,
  input  logic [META_W-1:0]     io_write_bits_entry_meta_codes_0,
  input  logic [META_W-1:0]     io_write_bits_entry_meta_codes_1,
  input  logic [GPADDR_W-1:0]   io_write_bits_gpf_gpaddr,
  input  logic                  io_write_bits_gpf_isForVSnonLeafPTE,

  // ---- update 端口（miss 回填修正）----
  input  logic                  io_update_valid,
  input  logic [BLKPADDR_W-1:0] io_update_bits_blkPaddr,
  input  logic [UPDVSET_W-1:0]  io_update_bits_vSetIdx,
  input  logic [WAYMASK_W-1:0]  io_update_bits_waymask,
  input  logic                  io_update_bits_corrupt
);

  localparam int unsigned PN = 2;  // PortNumber

  // ---------------------------------------------------------------------------
  // 存储：每条目两端口字段。用按字段二维数组（[entry][port]）保持可读，
  // 等价的展平叶子名为 entries_<entry>_<field>_<port>。
  // ---------------------------------------------------------------------------
  reg [VSETIDX_W-1:0] entries_vSetIdx        [NWAY][PN];
  reg [WAYMASK_W-1:0] entries_waymask        [NWAY][PN];
  reg [PTAG_W-1:0]    entries_ptag           [NWAY][PN];
  reg [EXCP_W-1:0]    entries_itlb_exception [NWAY][PN];
  reg [PBMT_W-1:0]    entries_itlb_pbmt      [NWAY][PN];
  reg [META_W-1:0]    entries_meta_codes     [NWAY][PN];

  // 循环指针（flag + value）。flag 翻转用于区分满/空。
  reg                 readPtr_flag;
  reg [PTR_W-1:0]     readPtr_value;
  reg                 writePtr_flag;
  reg [PTR_W-1:0]     writePtr_value;

  // 单份 GPF 信息
  reg                 gpf_entry_valid;
  reg [GPADDR_W-1:0]  gpf_entry_bits_gpaddr;
  reg                 gpf_entry_bits_isForVSnonLeafPTE;
  reg                 gpfPtr_flag;
  reg [PTR_W-1:0]     gpfPtr_value;

  // ---------------------------------------------------------------------------
  // 状态判定
  // ---------------------------------------------------------------------------
  wire empty = {readPtr_flag, readPtr_value} == {writePtr_flag, writePtr_value};
  wire full  = (readPtr_value == writePtr_value) & (readPtr_flag ^ writePtr_flag);

  wire gpf_hit = ({gpfPtr_flag, gpfPtr_value} == {readPtr_flag, readPtr_value})
               & gpf_entry_valid;

  // 空且有写入 → 旁路直通
  wire can_bypass = empty & io_write_valid;

  wire read_fire  = io_read_ready  & io_read_valid;
  // gpf 待读时阻塞写（除非本拍正好把它读走）
  wire gpf_stall  = gpf_entry_valid & ~(read_fire & gpf_hit);
  wire write_fire = io_write_ready & io_write_valid;

  assign io_read_valid  = ~empty | io_write_valid;
  assign io_write_ready = ~full & ~gpf_stall;

  // write 携带 gpf 异常
  wire write_has_gpf = (io_write_bits_entry_itlb_exception_0 == EXCP_GPF)
                     | (io_write_bits_entry_itlb_exception_1 == EXCP_GPF);

  // ---------------------------------------------------------------------------
  // read 输出：can_bypass 时直通 write，否则读 entries[readPtr]
  // ---------------------------------------------------------------------------
  wire [PTR_W-1:0] rp = readPtr_value;
  assign io_read_bits_entry_vSetIdx_0        = can_bypass ? io_write_bits_entry_vSetIdx_0        : entries_vSetIdx[rp][0];
  assign io_read_bits_entry_vSetIdx_1        = can_bypass ? io_write_bits_entry_vSetIdx_1        : entries_vSetIdx[rp][1];
  assign io_read_bits_entry_waymask_0        = can_bypass ? io_write_bits_entry_waymask_0        : entries_waymask[rp][0];
  assign io_read_bits_entry_waymask_1        = can_bypass ? io_write_bits_entry_waymask_1        : entries_waymask[rp][1];
  assign io_read_bits_entry_ptag_0           = can_bypass ? io_write_bits_entry_ptag_0           : entries_ptag[rp][0];
  assign io_read_bits_entry_ptag_1           = can_bypass ? io_write_bits_entry_ptag_1           : entries_ptag[rp][1];
  assign io_read_bits_entry_itlb_exception_0 = can_bypass ? io_write_bits_entry_itlb_exception_0 : entries_itlb_exception[rp][0];
  assign io_read_bits_entry_itlb_exception_1 = can_bypass ? io_write_bits_entry_itlb_exception_1 : entries_itlb_exception[rp][1];
  assign io_read_bits_entry_itlb_pbmt_0      = can_bypass ? io_write_bits_entry_itlb_pbmt_0      : entries_itlb_pbmt[rp][0];
  assign io_read_bits_entry_itlb_pbmt_1      = can_bypass ? io_write_bits_entry_itlb_pbmt_1      : entries_itlb_pbmt[rp][1];
  assign io_read_bits_entry_meta_codes_0     = can_bypass ? io_write_bits_entry_meta_codes_0     : entries_meta_codes[rp][0];
  assign io_read_bits_entry_meta_codes_1     = can_bypass ? io_write_bits_entry_meta_codes_1     : entries_meta_codes[rp][1];

  assign io_read_bits_gpf_gpaddr =
    can_bypass ? io_write_bits_gpf_gpaddr : (gpf_hit ? gpf_entry_bits_gpaddr : {GPADDR_W{1'b0}});
  assign io_read_bits_gpf_isForVSnonLeafPTE =
    can_bypass ? io_write_bits_gpf_isForVSnonLeafPTE : (gpf_hit & gpf_entry_bits_isForVSnonLeafPTE);

  // ---------------------------------------------------------------------------
  // update 命中判定（每条目每端口）
  //   vset_same: 同 set 且 update 有效且未 corrupt
  //   ptag_same: update 物理 tag 与存储 ptag 相同（getPhyTagFromBlk=blkPaddr[41:6]）
  // 注：write 与 update 命中同一 slot 时，write 优先（见下方时序块）。
  // ---------------------------------------------------------------------------
  wire [PTAG_W-1:0] upd_ptag = io_update_bits_blkPaddr[BLKPADDR_W-1 : BLKPADDR_W-PTAG_W];

  // ---------------------------------------------------------------------------
  // 时序逻辑
  // ---------------------------------------------------------------------------
  wire [PTR_W:0] readPtr_next  = {readPtr_flag,  readPtr_value}  + 1'b1;
  wire [PTR_W:0] writePtr_next = {writePtr_flag, writePtr_value} + 1'b1;

  integer i, p;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (i = 0; i < int'(NWAY); i = i + 1) begin
        for (p = 0; p < int'(PN); p = p + 1) begin
          entries_vSetIdx[i][p]        <= '0;
          entries_waymask[i][p]        <= '0;
          entries_ptag[i][p]           <= '0;
          entries_itlb_exception[i][p] <= '0;
          entries_itlb_pbmt[i][p]      <= '0;
          entries_meta_codes[i][p]     <= '0;
        end
      end
      readPtr_flag                     <= 1'b0;
      readPtr_value                    <= '0;
      writePtr_flag                    <= 1'b0;
      writePtr_value                   <= '0;
      gpf_entry_valid                  <= 1'b0;
      gpf_entry_bits_gpaddr            <= '0;
      gpf_entry_bits_isForVSnonLeafPTE <= 1'b0;
      gpfPtr_flag                      <= 1'b0;
      gpfPtr_value                     <= '0;
    end
    else begin
      // ---- 每条目：write 写入优先，否则 update 修正 ----
      for (i = 0; i < int'(NWAY); i = i + 1) begin
        if (write_fire & (writePtr_value == PTR_W'(i))) begin
          entries_vSetIdx[i][0]        <= io_write_bits_entry_vSetIdx_0;
          entries_vSetIdx[i][1]        <= io_write_bits_entry_vSetIdx_1;
          entries_waymask[i][0]        <= io_write_bits_entry_waymask_0;
          entries_waymask[i][1]        <= io_write_bits_entry_waymask_1;
          entries_ptag[i][0]           <= io_write_bits_entry_ptag_0;
          entries_ptag[i][1]           <= io_write_bits_entry_ptag_1;
          entries_itlb_exception[i][0] <= io_write_bits_entry_itlb_exception_0;
          entries_itlb_exception[i][1] <= io_write_bits_entry_itlb_exception_1;
          entries_itlb_pbmt[i][0]      <= io_write_bits_entry_itlb_pbmt_0;
          entries_itlb_pbmt[i][1]      <= io_write_bits_entry_itlb_pbmt_1;
          entries_meta_codes[i][0]     <= io_write_bits_entry_meta_codes_0;
          entries_meta_codes[i][1]     <= io_write_bits_entry_meta_codes_1;
        end
        else begin
          for (p = 0; p < int'(PN); p = p + 1) begin
            // vset_same / ptag_same（按端口）
            if ((io_update_bits_vSetIdx == entries_vSetIdx[i][p])
                & ~io_update_bits_corrupt & io_update_valid) begin
              if (upd_ptag == entries_ptag[i][p]) begin
                // miss -> hit：写入新 waymask
                entries_waymask[i][p]    <= io_update_bits_waymask;
                // 同步重算 meta ECC（用已存 ptag，timing 更优）
                entries_meta_codes[i][p] <= ^entries_ptag[i][p];
              end
              else if (io_update_bits_waymask == entries_waymask[i][p]) begin
                // 数据被覆盖：hit -> miss
                entries_waymask[i][p]    <= '0;
              end
            end
          end
        end
      end

      // ---- 指针 ----
      if (io_flush) begin
        readPtr_value  <= '0;
        writePtr_value <= '0;
      end
      else begin
        if (read_fire)  readPtr_value  <= readPtr_next[PTR_W-1:0];
        if (write_fire) writePtr_value <= writePtr_next[PTR_W-1:0];
      end
      readPtr_flag  <= ~io_flush & (read_fire  ? readPtr_next[PTR_W]  : readPtr_flag);
      writePtr_flag <= ~io_flush & (write_fire ? writePtr_next[PTR_W] : writePtr_flag);

      // ---- GPF 单份存储 ----
      if (write_fire & write_has_gpf) begin
        // 若被旁路且本拍读走，则无需保存
        gpf_entry_valid                  <= ~(can_bypass & read_fire);
        gpf_entry_bits_gpaddr            <= io_write_bits_gpf_gpaddr;
        gpf_entry_bits_isForVSnonLeafPTE <= io_write_bits_gpf_isForVSnonLeafPTE;
        gpfPtr_flag                      <= writePtr_flag;
        gpfPtr_value                     <= writePtr_value;
      end
      else begin
        if (can_bypass | ~gpf_hit)
          gpf_entry_valid <= ~io_flush & gpf_entry_valid;
        else
          gpf_entry_valid <= ~(read_fire | io_flush) & gpf_entry_valid;
        if (io_flush)
          gpf_entry_bits_gpaddr <= '0;
        gpf_entry_bits_isForVSnonLeafPTE <= ~io_flush & gpf_entry_bits_isForVSnonLeafPTE;
      end
    end
  end

endmodule
