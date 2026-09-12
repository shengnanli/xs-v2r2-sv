// =============================================================================
// xs_ICacheMetaArray_core —— 指令缓存 meta（tag + valid）阵列（可读重写核心）
//
// 对应 Chisel: xiangshan.frontend.icache.ICacheMetaArray（ICache.scala）
//
// 【它在前端的位置】
//   ICache 是 4 路组相联、256 组、64B line。一次取指请求会跨「最多两个相邻
//   cacheline」（port 0 / port 1），因此 meta 阵列被设计成「双端口、按奇偶 bank
//   交织」：
//     - 物理上分成 bank0 / bank1 两块 SRAM（tagArrays_0 / tagArrays_1）；
//     - 一个 vSetIdx 的最低位 vSetIdx[0] 决定它落在哪个 bank（偶组→bank0，奇组→bank1），
//       高 7 位 vSetIdx[7:1] 是 bank 内的行地址。
//   IPrefetch/MainPipe 给出两个 cacheline 的 vSetIdx，本阵列**读**出这两组、各 4 路的
//   {物理 tag, ECC code, valid}，上游据此比对命中路（waymask）。MissUnit refill 完成后
//   **写**入一路的 tag + 置 valid；分支失效 / fence.i 时**flush**清 valid。
//
//   IPrefetch.s0 ──read(vSetIdx×2)──▶ [meta 阵列] ──readResp(metas/codes/entryValid)──▶ s1 比对
//   MissUnit     ──write(virIdx, phyTag, waymask, bankIdx)──▶ [meta 阵列]
//   BPU/fence.i  ──flush / flushAll──▶ [meta 阵列]
//
// 【tag/code 与 valid 分开存：为什么】
//   - tag（36b 物理 tag）+ code（1b 奇偶校验）很宽、量大，存进**编译宏 SRAM**
//     （tagArrays_0/1，内部是 SplittedSRAMTemplate）。SRAM 读有「请求拍 → 下一拍出数据」
//     的一拍延迟，故读地址要打一拍（read_set_idx_next、port_x_read_0_reg）后才能选数据。
//   - valid 位每路每组仅 1bit、且要支持「按位 flush」「整体 flushAll」「随机置位」，
//     用 SRAM 不灵活，故单独用**触发器阵列** valid_array[way][set] 存（本模块自带，复位清零）。
//     valid 读出与 tag 读出对齐（都靠打一拍的组索引选出当拍组）。
//
// 【meta ECC code 怎么算】
//   KunminghuV2 的 meta 用最简单的 1-bit 奇偶校验：code = (^phyTag) ^ poison。
//   poison 是「注入错误」测试位，平时为 0，则 code 就是 phyTag 的奇偶。上游读出后
//   重新对读出 tag 算奇偶、与读出 code 比对即可检出单 bit 翻转。
//
// 【way_num：从 one-hot waymask 反解路号】
//   写请求给的是 one-hot 的 waymask（4b，命中/选中的那一路置 1）。valid 触发器阵列
//   按「路号」索引，故需把 one-hot 压成 2b 路号。当 waymask 非法（非 one-hot）时此
//   压缩按优先级编码，与 golden 位运算严格一致（见 onehot_to_waynum）。
//
// 【读握手 io_read_ready】
//   写 / flush / flushAll 与读共用 valid 触发器阵列的写端口，故它们任一活跃时读不就绪；
//   再 AND 上两块 tag SRAM 的 r_req_ready，得到对外的 read_ready。
// =============================================================================
package xs_icache_meta_pkg;
  // ---- 容量 / 位宽参数（与 KunminghuV2 ICache 一致）----
  localparam int unsigned PORT_NUM  = 2;    // 一次取指跨 2 个 cacheline → 2 个读端口
  localparam int unsigned N_WAYS    = 4;    // 4 路组相联
  localparam int unsigned N_SETS    = 256;  // 256 组（vSetIdx 8b）
  localparam int unsigned IDX_BITS  = 8;    // vSetIdx 宽
  localparam int unsigned TAG_BITS  = 36;   // 物理 tag 宽（pTagBits）
  localparam int unsigned BANK_IDX_BITS = $clog2(N_SETS) - 1; // bank 内行地址宽 = 7

  // ---- 一路 meta 读出（tag + ECC code）----
  typedef struct packed {
    logic [TAG_BITS-1:0] tag;   // 物理 tag
    logic                code;  // 1-bit 奇偶校验
  } meta_resp_t;

  // meta ECC 编码：1-bit 奇偶校验（phyTag 全位异或，再与 poison 异或）
  function automatic logic encode_meta_code(input logic [TAG_BITS-1:0] phy_tag,
                                            input logic                poison);
    return (^phy_tag) ^ poison;
  endfunction

  // one-hot waymask → 2bit 路号。与 golden 位运算等价：
  //   bit1 = |waymask[3:2]            （路 2/3 → 高位 1）
  //   bit0 = waymask[3] | waymask[1]  （路 1/3 → 低位 1）
  // 合法 one-hot 时即对应路号；非法输入时按此固定优先级压缩（与 golden 一致）。
  function automatic logic [1:0] onehot_to_waynum(input logic [N_WAYS-1:0] waymask);
    return {|waymask[3:2], waymask[3] | waymask[1]};
  endfunction
endpackage


// -----------------------------------------------------------------------------
// 可读核心：valid 触发器阵列 + 读端口路由 + 读响应选择 + 写/flush 控制。
// tag/code 存储与 Mbist 链由外层 wrapper 例化 golden SRAM 黑盒后接入本核（通过
// tag SRAM 的握手/读出端口）。本核只负责「架构行为」，不重写 SRAM 宏本身。
// -----------------------------------------------------------------------------

module xs_ICacheMetaArray_core
  import xs_icache_meta_pkg::*;
(
  input  logic clock,
  input  logic reset,

  // ---- 写端口（MissUnit refill）----
  input  logic                io_write_valid,
  input  logic [IDX_BITS-1:0] io_write_bits_virIdx,    // 写入的组（含 bank 位）
  input  logic [TAG_BITS-1:0] io_write_bits_phyTag,
  input  logic [N_WAYS-1:0]   io_write_bits_waymask,   // 写哪一路（one-hot）
  input  logic                io_write_bits_bankIdx,   // 写哪个 bank（=virIdx[0]）
  input  logic                io_write_bits_poison,    // ECC 注错位

  // ---- 读端口（IPrefetch）----
  output logic                io_read_ready,
  input  logic                io_read_valid,
  input  logic [IDX_BITS-1:0] io_read_bits_vSetIdx_0,  // port0 cacheline 组索引
  input  logic [IDX_BITS-1:0] io_read_bits_vSetIdx_1,  // port1 cacheline 组索引
  input  logic                io_read_bits_isDoubleLine,// 是否真的跨两个 line

  // ---- 读响应（下一拍出数据）：[port][way] 的 tag / code / valid ----
  output logic [TAG_BITS-1:0] io_readResp_metas      [PORT_NUM][N_WAYS],
  output logic                io_readResp_codes      [PORT_NUM][N_WAYS],
  output logic                io_readResp_entryValid [PORT_NUM][N_WAYS],

  // ---- flush（按 way 清某组的 valid）/ flushAll（整体清零）----
  input  logic                io_flush_valid   [PORT_NUM],
  input  logic [IDX_BITS-1:0] io_flush_virIdx  [PORT_NUM],
  input  logic [N_WAYS-1:0]   io_flush_waymask [PORT_NUM],
  input  logic                io_flushAll,

  // ---- 接入 tag SRAM（bank0 / bank1）的握手与端口（由 wrapper 连 golden 黑盒）----
  // bank0 = tagArrays_0，bank1 = tagArrays_1。
  output logic                sram_r_valid    [PORT_NUM],          // 各 bank 读请求 valid
  output logic [BANK_IDX_BITS-1:0] sram_r_setIdx [PORT_NUM],       // 各 bank 读行地址
  input  logic                sram_r_ready    [PORT_NUM],          // 各 bank 读就绪
  input  meta_resp_t          sram_r_resp     [PORT_NUM][N_WAYS],  // 各 bank 各路读出
  output logic                sram_w_valid    [PORT_NUM],          // 各 bank 写 valid
  output logic [BANK_IDX_BITS-1:0] sram_w_setIdx,                  // 写行地址（两 bank 共用）
  output meta_resp_t          sram_w_data,                         // 写数据（tag+code，4 路相同）
  output logic [N_WAYS-1:0]   sram_w_waymask                       // 写哪一路（one-hot）
);

  // ===========================================================================
  // 读端口路由：把两个 cacheline 的 vSetIdx 按奇偶 bank 分发到 bank0 / bank1
  // ===========================================================================
  // vSetIdx[0] = 0 → 落 bank0；=1 → 落 bank1。port1 仅在 isDoubleLine 时才真的读。
  logic port0_to_bank0, port0_to_bank1;  // port0 这次读 bank0 / bank1
  logic port1_to_bank0, port1_to_bank1;  // port1 这次读 bank0 / bank1
  assign port0_to_bank0 = io_read_valid &  ~io_read_bits_vSetIdx_0[0];
  assign port0_to_bank1 = io_read_valid &   io_read_bits_vSetIdx_0[0];
  assign port1_to_bank0 = io_read_valid &  ~io_read_bits_vSetIdx_1[0] & io_read_bits_isDoubleLine;
  assign port1_to_bank1 = io_read_valid &   io_read_bits_vSetIdx_1[0] & io_read_bits_isDoubleLine;

  // 每个 bank 同一拍只服务一个端口：约定「port0 优先用 bank，port1 用另一 bank」。
  // 由于两 port 的 bank 位通常互补（跨相邻 line），同 bank 冲突不会同拍发生；
  // setIdx 选择沿用 golden：bank 命中 port0 时取 vSetIdx_0，否则取 vSetIdx_1。
  // bank0 读请求 = port0 或 port1 想读 bank0
  assign sram_r_valid[0]  = port0_to_bank0 | port1_to_bank0;
  assign sram_r_setIdx[0] = port0_to_bank0 ? io_read_bits_vSetIdx_0[IDX_BITS-1:1]
                                           : io_read_bits_vSetIdx_1[IDX_BITS-1:1];
  // bank1 读请求 = port0 或 port1 想读 bank1
  assign sram_r_valid[1]  = port0_to_bank1 | port1_to_bank1;
  assign sram_r_setIdx[1] = port0_to_bank1 ? io_read_bits_vSetIdx_0[IDX_BITS-1:1]
                                           : io_read_bits_vSetIdx_1[IDX_BITS-1:1];

  // ===========================================================================
  // 读地址打一拍：SRAM 与 valid 阵列都是「请求拍发地址、下一拍出数据」，
  // 故需记住「上一拍每个 port 读的是哪个 bank」「读的组索引」以在数据拍选数据。
  // ===========================================================================
  logic                port0_read_bank0_reg;  // 上一拍 port0 读的是 bank0？
  logic                port1_read_bank0_reg;  // 上一拍 port1 读的是 bank0？
  logic [IDX_BITS-1:0] read_set_idx_reg [PORT_NUM]; // 上一拍各 port 的完整组索引（含 bank 位）

  // valid 触发器阵列：valid_array[way][set]，复位清零。
  logic valid_array [N_WAYS][N_SETS];

  // 读就绪：写 / flush / flushAll 占用 valid 阵列写端口时读不就绪；再 AND tag SRAM 就绪。
  logic any_flush;
  assign any_flush = io_flush_valid[0] | io_flush_valid[1];
  assign io_read_ready = ~io_write_valid & ~any_flush & ~io_flushAll
                       & sram_r_ready[0] & sram_r_ready[1];

  logic read_fire;
  assign read_fire = io_read_ready & io_read_valid;

  // ===========================================================================
  // 写 / flush 译码（组合）
  // ===========================================================================
  logic [1:0] write_way_num;
  assign write_way_num = onehot_to_waynum(io_write_bits_waymask);

  // ===========================================================================
  // valid 阵列时序逻辑：复位 / 读地址打拍 / flushAll / flush / write
  //   优先级（与 golden 完全一致）：flushAll > flush > write。
  //   读地址打拍与 valid 更新互不影响，可在同一时钟块内并列。
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      port0_read_bank0_reg <= 1'b0;
      port1_read_bank0_reg <= 1'b0;
      for (int unsigned p = 0; p < PORT_NUM; p++)
        read_set_idx_reg[p] <= '0;
      for (int unsigned w = 0; w < N_WAYS; w++)
        for (int unsigned s = 0; s < N_SETS; s++)
          valid_array[w][s] <= 1'b0;
    end
    else begin
      // ---- 读地址打一拍（仅读真正握手成功时更新）----
      if (read_fire) begin
        port0_read_bank0_reg   <= port0_to_bank0;
        port1_read_bank0_reg   <= port1_to_bank0;
        read_set_idx_reg[0]    <= io_read_bits_vSetIdx_0;
        read_set_idx_reg[1]    <= io_read_bits_vSetIdx_1;
      end

      // ---- valid 更新：flushAll > flush > write ----
      if (io_flushAll) begin
        for (int unsigned w = 0; w < N_WAYS; w++)
          for (int unsigned s = 0; s < N_SETS; s++)
            valid_array[w][s] <= 1'b0;
      end
      else if (any_flush) begin
        // 按 way 清「被 flush 命中组」的 valid：两个 flush 端口可同拍各清各的。
        // 对每一路：若 flush_k 有效且其 waymask 选中该路，则清掉 flush_k.virIdx 那组。
        for (int unsigned w = 0; w < N_WAYS; w++) begin
          for (int unsigned k = 0; k < PORT_NUM; k++) begin
            if (io_flush_valid[k] & io_flush_waymask[k][w])
              valid_array[w][io_flush_virIdx[k]] <= 1'b0;
          end
        end
      end
      else if (io_write_valid) begin
        // refill 写入：把被选中路（way_num）在 virIdx 组的 valid 置 1。
        valid_array[write_way_num][io_write_bits_virIdx] <= 1'b1;
      end
    end
  end

  // ===========================================================================
  // tag SRAM 写端口连接：两块 bank 共用写地址 / 数据，仅 valid 按 bankIdx 选 bank。
  //   写数据 4 路相同（tag/code 一致），由 SRAM 内部按 waymask 选路写入。
  // ===========================================================================
  assign sram_w_valid[0] = io_write_valid & ~io_write_bits_bankIdx; // 写 bank0
  assign sram_w_valid[1] = io_write_valid &  io_write_bits_bankIdx; // 写 bank1
  assign sram_w_setIdx   = io_write_bits_virIdx[IDX_BITS-1:1];
  assign sram_w_data.tag  = io_write_bits_phyTag;
  assign sram_w_data.code = encode_meta_code(io_write_bits_phyTag, io_write_bits_poison);
  assign sram_w_waymask  = io_write_bits_waymask;

  // ===========================================================================
  // 读响应选择（数据拍）：
  //   - tag/code：每个 port 上一拍读哪个 bank，就选哪个 bank 的 SRAM 读出。
  //   - valid   ：用上一拍打拍的组索引去 valid 阵列取出对应组、各路的 valid。
  // ===========================================================================
  always_comb begin
    for (int unsigned p = 0; p < PORT_NUM; p++) begin
      // 该 port 上一拍读的是 bank0 还是 bank1
      logic read_bank0;
      read_bank0 = (p == 0) ? port0_read_bank0_reg : port1_read_bank0_reg;
      for (int unsigned w = 0; w < N_WAYS; w++) begin
        // tag/code：bank0 命中取 bank0 读出，否则取 bank1 读出
        io_readResp_metas[p][w] = read_bank0 ? sram_r_resp[0][w].tag
                                             : sram_r_resp[1][w].tag;
        io_readResp_codes[p][w] = read_bank0 ? sram_r_resp[0][w].code
                                             : sram_r_resp[1][w].code;
        // valid：按打拍组索引读触发器阵列
        io_readResp_entryValid[p][w] = valid_array[w][read_set_idx_reg[p]];
      end
    end
  end

endmodule

// =============================================================================
// ICacheMetaArray（golden 同名 wrapper）——可读核 xs_ICacheMetaArray_core 的端口适配层
//
// 职责（机械适配，允许平铺）：
//   1. 把 golden 扁平端口（io_readResp_metas_p_w_tag 等）拆/聚到核的 struct/数组端口；
//   2. 例化 golden 的两块 tag SRAM 黑盒（SplittedSRAMTemplate / _1，对应 bank0 / bank1）
//      和 Mbist 流水（MbistPipeIcacheTag），把核给出的读/写请求接进 SRAM，
//      把 SRAM 读出回接给核；
//   3. 透传 Mbist / sigFromSrams 旁路链（FM 时这些子模块当黑盒，两侧同名一致）。
//
//   valid 触发器阵列、读端口路由、读响应选择、写/flush 行为全在核里；本层不含行为逻辑。
// =============================================================================

// ---------------------------------------------------------------------------
// golden 同名 wrapper
// ---------------------------------------------------------------------------

module ICacheMetaArray(
  input         clock,
  input         reset,
  input         io_write_valid,
  input  [7:0]  io_write_bits_virIdx,
  input  [35:0] io_write_bits_phyTag,
  input  [3:0]  io_write_bits_waymask,
  input         io_write_bits_bankIdx,
  input         io_write_bits_poison,
  output        io_read_ready,
  input         io_read_valid,
  input  [7:0]  io_read_bits_vSetIdx_0,
  input  [7:0]  io_read_bits_vSetIdx_1,
  input         io_read_bits_isDoubleLine,
  output [35:0] io_readResp_metas_0_0_tag,
  output [35:0] io_readResp_metas_0_1_tag,
  output [35:0] io_readResp_metas_0_2_tag,
  output [35:0] io_readResp_metas_0_3_tag,
  output [35:0] io_readResp_metas_1_0_tag,
  output [35:0] io_readResp_metas_1_1_tag,
  output [35:0] io_readResp_metas_1_2_tag,
  output [35:0] io_readResp_metas_1_3_tag,
  output        io_readResp_codes_0_0,
  output        io_readResp_codes_0_1,
  output        io_readResp_codes_0_2,
  output        io_readResp_codes_0_3,
  output        io_readResp_codes_1_0,
  output        io_readResp_codes_1_1,
  output        io_readResp_codes_1_2,
  output        io_readResp_codes_1_3,
  output        io_readResp_entryValid_0_0,
  output        io_readResp_entryValid_0_1,
  output        io_readResp_entryValid_0_2,
  output        io_readResp_entryValid_0_3,
  output        io_readResp_entryValid_1_0,
  output        io_readResp_entryValid_1_1,
  output        io_readResp_entryValid_1_2,
  output        io_readResp_entryValid_1_3,
  input         io_flush_0_valid,
  input  [7:0]  io_flush_0_bits_virIdx,
  input  [3:0]  io_flush_0_bits_waymask,
  input         io_flush_1_valid,
  input  [7:0]  io_flush_1_bits_virIdx,
  input  [3:0]  io_flush_1_bits_waymask,
  input         io_flushAll,
  input  [1:0]  boreChildrenBd_bore_array,
  input         boreChildrenBd_bore_all,
  input         boreChildrenBd_bore_req,
  output        boreChildrenBd_bore_ack,
  input         boreChildrenBd_bore_writeen,
  input  [1:0]  boreChildrenBd_bore_be,
  input  [7:0]  boreChildrenBd_bore_addr,
  input  [73:0] boreChildrenBd_bore_indata,
  input         boreChildrenBd_bore_readen,
  input  [7:0]  boreChildrenBd_bore_addr_rd,
  output [73:0] boreChildrenBd_bore_outdata,
  input         sigFromSrams_bore_ram_hold,
  input         sigFromSrams_bore_ram_bypass,
  input         sigFromSrams_bore_ram_bp_clken,
  input         sigFromSrams_bore_ram_aux_clk,
  input         sigFromSrams_bore_ram_aux_ckbp,
  input         sigFromSrams_bore_ram_mcp_hold,
  input         sigFromSrams_bore_cgen,
  input         sigFromSrams_bore_1_ram_hold,
  input         sigFromSrams_bore_1_ram_bypass,
  input         sigFromSrams_bore_1_ram_bp_clken,
  input         sigFromSrams_bore_1_ram_aux_clk,
  input         sigFromSrams_bore_1_ram_aux_ckbp,
  input         sigFromSrams_bore_1_ram_mcp_hold,
  input         sigFromSrams_bore_1_cgen,
  input         sigFromSrams_bore_2_ram_hold,
  input         sigFromSrams_bore_2_ram_bypass,
  input         sigFromSrams_bore_2_ram_bp_clken,
  input         sigFromSrams_bore_2_ram_aux_clk,
  input         sigFromSrams_bore_2_ram_aux_ckbp,
  input         sigFromSrams_bore_2_ram_mcp_hold,
  input         sigFromSrams_bore_2_cgen,
  input         sigFromSrams_bore_3_ram_hold,
  input         sigFromSrams_bore_3_ram_bypass,
  input         sigFromSrams_bore_3_ram_bp_clken,
  input         sigFromSrams_bore_3_ram_aux_clk,
  input         sigFromSrams_bore_3_ram_aux_ckbp,
  input         sigFromSrams_bore_3_ram_mcp_hold,
  input         sigFromSrams_bore_3_cgen
);
  import xs_icache_meta_pkg::*;

  // ---- 核 <-> tag SRAM 接口（数组化）----
  logic                core_sram_r_valid  [PORT_NUM];
  logic [BANK_IDX_BITS-1:0] core_sram_r_setIdx [PORT_NUM];
  logic                core_sram_r_ready  [PORT_NUM];
  meta_resp_t          core_sram_r_resp   [PORT_NUM][N_WAYS];
  logic                core_sram_w_valid  [PORT_NUM];
  logic [BANK_IDX_BITS-1:0] core_sram_w_setIdx;
  meta_resp_t          core_sram_w_data;
  logic [N_WAYS-1:0]   core_sram_w_waymask;

  // ---- 核读响应（数组）----
  logic [TAG_BITS-1:0] rr_metas      [PORT_NUM][N_WAYS];
  logic                rr_codes      [PORT_NUM][N_WAYS];
  logic                rr_entryValid [PORT_NUM][N_WAYS];

  // ---- flush 输入（数组化）----
  logic                flush_valid   [PORT_NUM];
  logic [IDX_BITS-1:0] flush_virIdx  [PORT_NUM];
  logic [N_WAYS-1:0]   flush_waymask [PORT_NUM];
  assign flush_valid[0]   = io_flush_0_valid;
  assign flush_valid[1]   = io_flush_1_valid;
  assign flush_virIdx[0]  = io_flush_0_bits_virIdx;
  assign flush_virIdx[1]  = io_flush_1_bits_virIdx;
  assign flush_waymask[0] = io_flush_0_bits_waymask;
  assign flush_waymask[1] = io_flush_1_bits_waymask;

  // ===========================================================================
  // 可读核例化（固定实例名 u_core，供 FM 脚本定位 valid_array 等）
  // ===========================================================================
  xs_ICacheMetaArray_core u_core (
    .clock                  (clock),
    .reset                  (reset),
    .io_write_valid         (io_write_valid),
    .io_write_bits_virIdx   (io_write_bits_virIdx),
    .io_write_bits_phyTag   (io_write_bits_phyTag),
    .io_write_bits_waymask  (io_write_bits_waymask),
    .io_write_bits_bankIdx  (io_write_bits_bankIdx),
    .io_write_bits_poison   (io_write_bits_poison),
    .io_read_ready          (io_read_ready),
    .io_read_valid          (io_read_valid),
    .io_read_bits_vSetIdx_0 (io_read_bits_vSetIdx_0),
    .io_read_bits_vSetIdx_1 (io_read_bits_vSetIdx_1),
    .io_read_bits_isDoubleLine (io_read_bits_isDoubleLine),
    .io_readResp_metas      (rr_metas),
    .io_readResp_codes      (rr_codes),
    .io_readResp_entryValid (rr_entryValid),
    .io_flush_valid         (flush_valid),
    .io_flush_virIdx        (flush_virIdx),
    .io_flush_waymask       (flush_waymask),
    .io_flushAll            (io_flushAll),
    .sram_r_valid           (core_sram_r_valid),
    .sram_r_setIdx          (core_sram_r_setIdx),
    .sram_r_ready           (core_sram_r_ready),
    .sram_r_resp            (core_sram_r_resp),
    .sram_w_valid           (core_sram_w_valid),
    .sram_w_setIdx          (core_sram_w_setIdx),
    .sram_w_data            (core_sram_w_data),
    .sram_w_waymask         (core_sram_w_waymask)
  );

  // ---- 读响应：核数组 → golden 扁平输出 ----
  assign io_readResp_metas_0_0_tag = rr_metas[0][0];
  assign io_readResp_metas_0_1_tag = rr_metas[0][1];
  assign io_readResp_metas_0_2_tag = rr_metas[0][2];
  assign io_readResp_metas_0_3_tag = rr_metas[0][3];
  assign io_readResp_metas_1_0_tag = rr_metas[1][0];
  assign io_readResp_metas_1_1_tag = rr_metas[1][1];
  assign io_readResp_metas_1_2_tag = rr_metas[1][2];
  assign io_readResp_metas_1_3_tag = rr_metas[1][3];
  assign io_readResp_codes_0_0 = rr_codes[0][0];
  assign io_readResp_codes_0_1 = rr_codes[0][1];
  assign io_readResp_codes_0_2 = rr_codes[0][2];
  assign io_readResp_codes_0_3 = rr_codes[0][3];
  assign io_readResp_codes_1_0 = rr_codes[1][0];
  assign io_readResp_codes_1_1 = rr_codes[1][1];
  assign io_readResp_codes_1_2 = rr_codes[1][2];
  assign io_readResp_codes_1_3 = rr_codes[1][3];
  assign io_readResp_entryValid_0_0 = rr_entryValid[0][0];
  assign io_readResp_entryValid_0_1 = rr_entryValid[0][1];
  assign io_readResp_entryValid_0_2 = rr_entryValid[0][2];
  assign io_readResp_entryValid_0_3 = rr_entryValid[0][3];
  assign io_readResp_entryValid_1_0 = rr_entryValid[1][0];
  assign io_readResp_entryValid_1_1 = rr_entryValid[1][1];
  assign io_readResp_entryValid_1_2 = rr_entryValid[1][2];
  assign io_readResp_entryValid_1_3 = rr_entryValid[1][3];

  // ===========================================================================
  // Mbist 流水（黑盒）：把外部 boreChildrenBd 总线分发给 4 个 SRAM 子端口
  //   toSRAM_0/1 → tagArrays_0（bank0 内部两块 SRAM），toSRAM_2/3 → tagArrays_1。
  // ===========================================================================
  wire [73:0] bd_outdata;
  wire        bd_ack;
  // childBd_N：Mbist → 各内层 SRAM 的子总线（与 golden 同构）
  wire [7:0]  childBd_addr,   childBd_addr_rd;
  wire [73:0] childBd_wdata,  childBd_rdata;
  wire [1:0]  childBd_wmask;
  wire        childBd_re, childBd_we, childBd_ack, childBd_selectedOH, childBd_array;
  wire [7:0]  childBd_1_addr,  childBd_1_addr_rd;
  wire [73:0] childBd_1_wdata, childBd_1_rdata;
  wire [1:0]  childBd_1_wmask;
  wire        childBd_1_re, childBd_1_we, childBd_1_ack, childBd_1_selectedOH, childBd_1_array;
  wire [7:0]  childBd_2_addr,  childBd_2_addr_rd;
  wire [73:0] childBd_2_wdata, childBd_2_rdata;
  wire [1:0]  childBd_2_wmask;
  wire        childBd_2_re, childBd_2_we, childBd_2_ack, childBd_2_selectedOH;
  wire [1:0]  childBd_2_array;
  wire [7:0]  childBd_3_addr,  childBd_3_addr_rd;
  wire [73:0] childBd_3_wdata, childBd_3_rdata;
  wire [1:0]  childBd_3_wmask;
  wire        childBd_3_re, childBd_3_we, childBd_3_ack, childBd_3_selectedOH;
  wire [1:0]  childBd_3_array;

  assign boreChildrenBd_bore_ack     = bd_ack;
  assign boreChildrenBd_bore_outdata = bd_outdata;

  // ===========================================================================
  // bank0 tag SRAM 黑盒（golden SplittedSRAMTemplate）
  //   读：核给 valid/setIdx；读出聚回核 core_sram_r_resp[0][*]。
  //   写：核给写数据（4 路同）+ waymask；写 valid 来自核 core_sram_w_valid[0]。
  // ===========================================================================
  SplittedSRAMTemplate tagArrays_0 (
    .clock                            (clock),
    .reset                            (reset),
    .io_r_req_ready                   (core_sram_r_ready[0]),
    .io_r_req_valid                   (core_sram_r_valid[0]),
    .io_r_req_bits_setIdx             (core_sram_r_setIdx[0]),
    .io_r_resp_data_0_meta_tag        (core_sram_r_resp[0][0].tag),
    .io_r_resp_data_0_code            (core_sram_r_resp[0][0].code),
    .io_r_resp_data_1_meta_tag        (core_sram_r_resp[0][1].tag),
    .io_r_resp_data_1_code            (core_sram_r_resp[0][1].code),
    .io_r_resp_data_2_meta_tag        (core_sram_r_resp[0][2].tag),
    .io_r_resp_data_2_code            (core_sram_r_resp[0][2].code),
    .io_r_resp_data_3_meta_tag        (core_sram_r_resp[0][3].tag),
    .io_r_resp_data_3_code            (core_sram_r_resp[0][3].code),
    .io_w_req_valid                   (core_sram_w_valid[0]),
    .io_w_req_bits_setIdx             (core_sram_w_setIdx),
    .io_w_req_bits_data_0_meta_tag    (core_sram_w_data.tag),
    .io_w_req_bits_data_0_code        (core_sram_w_data.code),
    .io_w_req_bits_data_1_meta_tag    (core_sram_w_data.tag),
    .io_w_req_bits_data_1_code        (core_sram_w_data.code),
    .io_w_req_bits_data_2_meta_tag    (core_sram_w_data.tag),
    .io_w_req_bits_data_2_code        (core_sram_w_data.code),
    .io_w_req_bits_data_3_meta_tag    (core_sram_w_data.tag),
    .io_w_req_bits_data_3_code        (core_sram_w_data.code),
    .io_w_req_bits_waymask            (core_sram_w_waymask),
    .boreChildrenBd_bore_addr         (childBd_addr),
    .boreChildrenBd_bore_addr_rd      (childBd_addr_rd),
    .boreChildrenBd_bore_wdata        (childBd_wdata),
    .boreChildrenBd_bore_wmask        (childBd_wmask),
    .boreChildrenBd_bore_re           (childBd_re),
    .boreChildrenBd_bore_we           (childBd_we),
    .boreChildrenBd_bore_rdata        (childBd_rdata),
    .boreChildrenBd_bore_ack          (childBd_ack),
    .boreChildrenBd_bore_selectedOH   (childBd_selectedOH),
    .boreChildrenBd_bore_array        (childBd_array),
    .boreChildrenBd_bore_1_addr       (childBd_1_addr),
    .boreChildrenBd_bore_1_addr_rd    (childBd_1_addr_rd),
    .boreChildrenBd_bore_1_wdata      (childBd_1_wdata),
    .boreChildrenBd_bore_1_wmask      (childBd_1_wmask),
    .boreChildrenBd_bore_1_re         (childBd_1_re),
    .boreChildrenBd_bore_1_we         (childBd_1_we),
    .boreChildrenBd_bore_1_rdata      (childBd_1_rdata),
    .boreChildrenBd_bore_1_ack        (childBd_1_ack),
    .boreChildrenBd_bore_1_selectedOH (childBd_1_selectedOH),
    .boreChildrenBd_bore_1_array      (childBd_1_array),
    .sigFromSrams_bore_ram_hold       (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass     (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken   (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk    (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp   (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold   (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen           (sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold     (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass   (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk  (sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen         (sigFromSrams_bore_1_cgen)
  );

  // ===========================================================================
  // bank1 tag SRAM 黑盒（golden SplittedSRAMTemplate_1）
  // ===========================================================================
  SplittedSRAMTemplate_1 tagArrays_1 (
    .clock                            (clock),
    .reset                            (reset),
    .io_r_req_ready                   (core_sram_r_ready[1]),
    .io_r_req_valid                   (core_sram_r_valid[1]),
    .io_r_req_bits_setIdx             (core_sram_r_setIdx[1]),
    .io_r_resp_data_0_meta_tag        (core_sram_r_resp[1][0].tag),
    .io_r_resp_data_0_code            (core_sram_r_resp[1][0].code),
    .io_r_resp_data_1_meta_tag        (core_sram_r_resp[1][1].tag),
    .io_r_resp_data_1_code            (core_sram_r_resp[1][1].code),
    .io_r_resp_data_2_meta_tag        (core_sram_r_resp[1][2].tag),
    .io_r_resp_data_2_code            (core_sram_r_resp[1][2].code),
    .io_r_resp_data_3_meta_tag        (core_sram_r_resp[1][3].tag),
    .io_r_resp_data_3_code            (core_sram_r_resp[1][3].code),
    .io_w_req_valid                   (core_sram_w_valid[1]),
    .io_w_req_bits_setIdx             (core_sram_w_setIdx),
    .io_w_req_bits_data_0_meta_tag    (core_sram_w_data.tag),
    .io_w_req_bits_data_0_code        (core_sram_w_data.code),
    .io_w_req_bits_data_1_meta_tag    (core_sram_w_data.tag),
    .io_w_req_bits_data_1_code        (core_sram_w_data.code),
    .io_w_req_bits_data_2_meta_tag    (core_sram_w_data.tag),
    .io_w_req_bits_data_2_code        (core_sram_w_data.code),
    .io_w_req_bits_data_3_meta_tag    (core_sram_w_data.tag),
    .io_w_req_bits_data_3_code        (core_sram_w_data.code),
    .io_w_req_bits_waymask            (core_sram_w_waymask),
    .boreChildrenBd_bore_addr         (childBd_2_addr),
    .boreChildrenBd_bore_addr_rd      (childBd_2_addr_rd),
    .boreChildrenBd_bore_wdata        (childBd_2_wdata),
    .boreChildrenBd_bore_wmask        (childBd_2_wmask),
    .boreChildrenBd_bore_re           (childBd_2_re),
    .boreChildrenBd_bore_we           (childBd_2_we),
    .boreChildrenBd_bore_rdata        (childBd_2_rdata),
    .boreChildrenBd_bore_ack          (childBd_2_ack),
    .boreChildrenBd_bore_selectedOH   (childBd_2_selectedOH),
    .boreChildrenBd_bore_array        (childBd_2_array),
    .boreChildrenBd_bore_1_addr       (childBd_3_addr),
    .boreChildrenBd_bore_1_addr_rd    (childBd_3_addr_rd),
    .boreChildrenBd_bore_1_wdata      (childBd_3_wdata),
    .boreChildrenBd_bore_1_wmask      (childBd_3_wmask),
    .boreChildrenBd_bore_1_re         (childBd_3_re),
    .boreChildrenBd_bore_1_we         (childBd_3_we),
    .boreChildrenBd_bore_1_rdata      (childBd_3_rdata),
    .boreChildrenBd_bore_1_ack        (childBd_3_ack),
    .boreChildrenBd_bore_1_selectedOH (childBd_3_selectedOH),
    .boreChildrenBd_bore_1_array      (childBd_3_array),
    .sigFromSrams_bore_ram_hold       (sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_ram_bypass     (sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken   (sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk    (sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp   (sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold   (sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_cgen           (sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_1_ram_hold     (sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_1_ram_bypass   (sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk  (sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen         (sigFromSrams_bore_3_cgen)
  );

  // ===========================================================================
  // Mbist 流水黑盒：内建自测总线分发（与 golden 端口一致）
  // ===========================================================================
  MbistPipeIcacheTag mbistPl (
    .clock               (clock),
    .reset               (reset),
    .mbist_array         (boreChildrenBd_bore_array),
    .mbist_all           (boreChildrenBd_bore_all),
    .mbist_req           (boreChildrenBd_bore_req),
    .mbist_ack           (bd_ack),
    .mbist_writeen       (boreChildrenBd_bore_writeen),
    .mbist_be            (boreChildrenBd_bore_be),
    .mbist_addr          (boreChildrenBd_bore_addr),
    .mbist_indata        (boreChildrenBd_bore_indata),
    .mbist_readen        (boreChildrenBd_bore_readen),
    .mbist_addr_rd       (boreChildrenBd_bore_addr_rd),
    .mbist_outdata       (bd_outdata),
    .toSRAM_0_addr       (childBd_addr),
    .toSRAM_0_addr_rd    (childBd_addr_rd),
    .toSRAM_0_wdata      (childBd_wdata),
    .toSRAM_0_wmask      (childBd_wmask),
    .toSRAM_0_re         (childBd_re),
    .toSRAM_0_we         (childBd_we),
    .toSRAM_0_rdata      (childBd_rdata),
    .toSRAM_0_ack        (childBd_ack),
    .toSRAM_0_selectedOH (childBd_selectedOH),
    .toSRAM_0_array      (childBd_array),
    .toSRAM_1_addr       (childBd_1_addr),
    .toSRAM_1_addr_rd    (childBd_1_addr_rd),
    .toSRAM_1_wdata      (childBd_1_wdata),
    .toSRAM_1_wmask      (childBd_1_wmask),
    .toSRAM_1_re         (childBd_1_re),
    .toSRAM_1_we         (childBd_1_we),
    .toSRAM_1_rdata      (childBd_1_rdata),
    .toSRAM_1_ack        (childBd_1_ack),
    .toSRAM_1_selectedOH (childBd_1_selectedOH),
    .toSRAM_1_array      (childBd_1_array),
    .toSRAM_2_addr       (childBd_2_addr),
    .toSRAM_2_addr_rd    (childBd_2_addr_rd),
    .toSRAM_2_wdata      (childBd_2_wdata),
    .toSRAM_2_wmask      (childBd_2_wmask),
    .toSRAM_2_re         (childBd_2_re),
    .toSRAM_2_we         (childBd_2_we),
    .toSRAM_2_rdata      (childBd_2_rdata),
    .toSRAM_2_ack        (childBd_2_ack),
    .toSRAM_2_selectedOH (childBd_2_selectedOH),
    .toSRAM_2_array      (childBd_2_array),
    .toSRAM_3_addr       (childBd_3_addr),
    .toSRAM_3_addr_rd    (childBd_3_addr_rd),
    .toSRAM_3_wdata      (childBd_3_wdata),
    .toSRAM_3_wmask      (childBd_3_wmask),
    .toSRAM_3_re         (childBd_3_re),
    .toSRAM_3_we         (childBd_3_we),
    .toSRAM_3_rdata      (childBd_3_rdata),
    .toSRAM_3_ack        (childBd_3_ack),
    .toSRAM_3_selectedOH (childBd_3_selectedOH),
    .toSRAM_3_array      (childBd_3_array)
  );

endmodule
