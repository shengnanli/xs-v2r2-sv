// =============================================================================
// xs_FTBBank —— 大容量组相联 FTB（Fetch Target Buffer）的一个 bank
//
// 对应 Chisel: xiangshan.frontend.FTB.FTBBank（FTB.scala 内部类，class FTBBank）
//
// 【它在前端 BPU 的位置】
//   香山前端用「多级覆盖式」分支预测。S1 级有一个零气泡的微型 uFTB（见 xs_FauFTB），
//   随后的 FTB（本模块所属的预测器）容量大得多、命中率更高，在 S2/S3 级给出更准的
//   「这一取指块里有没有 CFI、跳到哪、fall-through 落在哪」并覆盖 uFTB 的结果。
//   FTBBank 就是这个大 FTB 的核心存储 + 查询/更新单元：
//
//     s0_pc ─(req_pc)─▶ [SRAM 读] ─▶ s1: tag 比较 → 命中路 + 命中条目 → read_resp
//                                          │
//                                          └▶ s2: multi-hit 检测（多路同时命中的兜底）
//     FTQ commit ─(u_req_pc 读 tag → update_hits)─▶ [写回 SRAM + setplru 替换状态更新]
//
// 【组相联结构】
//   numEntries = 2048 条，numWays = 4 路，numSets = 512 组。
//   每组 4 路并行存「FTBEntry + tag」。一次查询：
//     1. 用 PC 算 set index（idxBits=9），从 SRAM 同一组读出 4 路 {entry, tag}；
//     2. 下一拍用 PC 的 tag(20b) 与 4 路 tag 并行比较，且该路 entry.valid → 命中向量；
//     3. 命中向量 OHToUInt 得命中路号，Mux1H 选出命中条目作为 read_resp。
//
// 【索引为何要异或打散（skewed index）】
//   set index 不是直接取 PC 低位，而是 idx = pc[9:1] ^ pc[12:4]（FTBTableAddr.getIdx，
//   skewedBits=3）。把 tag 的低位异或进 index，能让相邻/规律的 PC 更均匀地散布到各组，
//   减少 conflict miss。tag 仍取 pc[29:10]（idxBits 之上的 20 位）。
//
// 【tag 匹配 vs SRAM bank】
//   tag 与 entry 一起存进同一块多路 SRAM（SplittedSRAMTemplate_2，dataSplit=8 把每路
//   ~70b 的 {entry,tag} 切成 8 片以适配物理 SRAM 位宽）。本核把 SRAM 当黑盒：只负责
//   发地址、收 4 路读数据、做 tag 比较与替换决策；条目的位打包/物理 SRAM 由它处理。
//
// 【两条读通路：预测读 vs 更新读，单端口仲裁】
//   SRAM 是单端口（singlePort），预测读(req_pc) 与 更新读(u_req_pc) 共用读口，
//   二者不会同拍有效（上层保证，golden 有断言）。地址用 u_req_pc 优先选择。
//     · 预测读：结果经 HoldUnless 保持，直到下一次预测读（避免被更新读冲掉，
//       这正是 Chisel 把 holdRead 逻辑外提到本模块的原因——见 FTB.scala:495 注释）。
//     · 更新读：直接用 SRAM 当拍 resp 比 u_req_tag，得 update_hits（FTQ commit 时
//       先查该 PC 是否已在 FTB，决定改写命中路还是新分配一路）。
//
// 【multi-hit 兜底（read_multi_*）】
//   理想情况下一组内最多一路命中。但 SRAM 数据可能因软错误/异常写出现两路同 tag 命中，
//   此时 OHToUInt 会算错命中路号，导致用错条目算目标、地址错、影响性能（不影响正确性，
//   因为后续会纠正）。所以额外做一套「multi-hit 检测 + PriorityMux 选第一路命中条目」，
//   在 s2 检测、s3 用它触发重定向。multi-hit 信号比主命中晚一拍寄存以放松时序。
//
// 【setplru 替换】
//   每组一棵 4 路二叉树 PLRU（numWays-1 = 3 bit 状态/组，共 512 组）。
//     · 选 victim（分配新条目时）：plru_victim 从 3 位状态自顶向下读出 2-bit way 号。
//     · touch（用过一路 → 让它远离 victim）：plru_touch 翻转根到该叶路径上的位。
//   touch 有两个来源：预测命中（延一拍，放松时序）与 commit 写入。二者择一作用到本组。
//   分配路选择：组内有空路(entry.valid=0) → 取最低位空路（PriorityEncoder(~valids)）；
//   全满 → 用 PLRU victim。
//
// 【可读性要点】
//   - 4 路读数据用 ftb_entry_t 数组 sram_entry[4] + tag 数组 sram_tag[4] 表达，
//     不再展平成几十个 _ftb_io_r_resp_data_n_* 标量。
//   - 命中向量、命中路、Mux1H 选条目用 for/函数表达，名字直述其意（hit/hit_way）。
//   - PLRU 的 victim/touch 写成纯函数（plru_victim4 / plru_touch4），与 uFTB 同思路。
//   - 端口沿用 golden 扁平命名以便 wrapper/FM 对齐；SRAM 实例由 wrapper 提供
//     （golden 同名 SplittedSRAMTemplate_2），本核通过结构体数组与之对接。
//
//   注：golden 含若干对所有输出无影响的结构（`ifndef SYNTHESIS 断言、MbistPipe、
//   bore/sigFromSrams 扫描链）。它们是 unread / 不可达 compare point，核内不实现；
//   SRAM 黑盒的 bore 端口由 wrapper 机械接出。
// =============================================================================
module xs_FTBBank
  import xs_ftb_pkg::*;
#(
  parameter int unsigned NUM_SETS = 512,
  parameter int unsigned NUM_WAYS = 4,
  parameter int unsigned PC_W     = 50,
  parameter int unsigned TAG_W    = 20,   // FtbTagLength
  parameter int unsigned IDX_W    = 9,    // log2(NUM_SETS)
  parameter int unsigned SKEW_W   = 3     // skewedBits（索引异或打散位数）
)(
  input  logic                clock,
  input  logic                reset,

  input  logic                io_s1_fire,

  // ---- 预测读请求（DecoupledIO，← BPU s0） ----
  output logic                io_req_pc_ready,
  input  logic                io_req_pc_valid,
  input  logic [PC_W-1:0]     io_req_pc_bits,

  // ---- 预测读结果（s1）：命中条目（Mux1H） ----
  output ftb_entry_t          read_resp,
  output logic                io_read_hits_valid,
  output logic [1:0]          io_read_hits_bits,

  // ---- multi-hit 兜底条目（s2 检测，PriorityMux 选第一路命中） ----
  output ftb_entry_t          read_multi_entry,
  output logic                io_read_multi_hits_valid,
  output logic [1:0]          io_read_multi_hits_bits,

  // ---- 更新读请求（DecoupledIO，← FTQ commit，查 PC 是否已在 FTB） ----
  input  logic                io_u_req_pc_valid,
  input  logic [PC_W-1:0]     io_u_req_pc_bits,
  output logic                io_update_hits_valid,
  output logic [1:0]          io_update_hits_bits,
  input  logic                io_update_access,   // 本拍是更新读（与预测读互斥）

  // ---- 更新写（← FTQ commit） ----
  input  logic [PC_W-1:0]     io_update_pc,
  input  logic                io_update_write_data_valid,
  input  ftb_entry_t          update_write_entry,
  input  logic [TAG_W-1:0]    update_write_tag,
  input  logic [1:0]          io_update_write_way,
  input  logic                io_update_write_alloc,

  // ---- 与 SRAM bank（SplittedSRAMTemplate_2）对接 ----
  // 读口
  output logic                sram_r_req_valid,
  output logic [IDX_W-1:0]    sram_r_req_setIdx,
  input  logic                sram_r_req_ready,
  input  ftb_entry_t          sram_r_entry [NUM_WAYS],   // 4 路读出条目
  input  logic [TAG_W-1:0]    sram_r_tag   [NUM_WAYS],   // 4 路读出 tag
  // 写口（4 路共享同一条目/同一 tag，由 waymask 选实际写入路）
  output logic                sram_w_req_valid,
  output logic [IDX_W-1:0]    sram_w_req_setIdx,
  output ftb_entry_t          sram_w_entry,
  output logic [TAG_W-1:0]    sram_w_tag,
  output logic [NUM_WAYS-1:0] sram_w_waymask
);

  localparam int unsigned WAY_IDX_W = $clog2(NUM_WAYS);   // =2

  // ===========================================================================
  // 纯函数：索引/tag 提取、OHToUInt、4 路 PLRU
  // ===========================================================================

  // set index：idx = addr.getIdx ^ getTag(x)[idxBits+skew-1 : skew]（skewed index）
  //   addr.getIdx(x) = x[idxBits+instOff-1 : instOff] = pc[9:1]
  //   异或项         = pc[idxBits+skew : skew+1] = pc[12:4]
  function automatic logic [IDX_W-1:0] get_idx(input logic [PC_W-1:0] pc);
    return pc[IDX_W+INST_OFF_BITS-1 : INST_OFF_BITS]
         ^ pc[IDX_W+SKEW_W+INST_OFF_BITS-1 : SKEW_W+INST_OFF_BITS];
  endfunction

  // tag = pc[tagLen+idxBits+instOff-1 : idxBits+instOff] = pc[29:10]
  function automatic logic [TAG_W-1:0] get_tag(input logic [PC_W-1:0] pc);
    return pc[TAG_W+IDX_W+INST_OFF_BITS-1 : IDX_W+INST_OFF_BITS];
  endfunction

  // one-hot 命中向量 → 命中路号（OHToUInt）；多路命中时此函数会算错（multi-hit 兜底处理）
  function automatic logic [WAY_IDX_W-1:0] oh_to_idx(input logic [NUM_WAYS-1:0] oh);
    logic [WAY_IDX_W-1:0] idx;
    idx = '0;
    for (int b = 0; b < WAY_IDX_W; b++)
      for (int i = 0; i < NUM_WAYS; i++)
        if (i[b]) idx[b] = idx[b] | oh[i];
    return idx;
  endfunction

  // 4 路二叉树 PLRU（3 位状态）：选 victim（自顶向下读 2-bit way 号）
  //   st[2] 选高半/低半；选中半边内再用 st[1]/st[0] 选叶。与 golden u_way 公式一致。
  function automatic logic [WAY_IDX_W-1:0] plru_victim4(input logic [WAY_IDX_W:0] st);
    return {st[2], st[2] ? st[1] : st[0]};
  endfunction

  // 4 路 PLRU touch：翻转根到被访问叶路径上的位，使该叶最不易被选为 victim。
  //   与 golden state_vec 更新公式、与 uFTB plru_touch4 完全一致。
  function automatic logic [WAY_IDX_W:0] plru_touch4(
      input logic [WAY_IDX_W:0] st, input logic [WAY_IDX_W-1:0] way);
    return {~way[1], way[1] ? ~way[0] : st[1], way[1] ? st[0] : ~way[0]};
  endfunction

  // ===========================================================================
  // 读地址仲裁（单端口）：更新读优先于预测读；二者上层保证不会同拍有效
  // ===========================================================================
  assign sram_r_req_valid  = io_req_pc_valid | io_u_req_pc_valid;
  assign sram_r_req_setIdx = io_u_req_pc_valid ? get_idx(io_u_req_pc_bits)
                                               : get_idx(io_req_pc_bits);
  // 读口 ready 直接回传给两个请求方（单端口共享）
  assign io_req_pc_ready   = sram_r_req_ready;

  // ===========================================================================
  // 预测读：寄存请求的 tag/idx；SRAM resp 经 HoldUnless 保持
  //
  //   pred_rdata = HoldUnless(sram_resp, RegNext(req_pc.valid && !update_access))
  //   即：仅当「上一拍是预测读」时用本拍 SRAM resp 刷新保持寄存器；否则维持旧值。
  //   这样更新读穿插进来时不会把预测读结果冲掉（holdRead 外提，FTB.scala:495）。
  // ===========================================================================
  logic [TAG_W-1:0] req_tag;   // RegEnable(getTag(req_pc), req_pc.valid)
  logic [IDX_W-1:0] req_idx;   // RegEnable(getIdx(req_pc), req_pc.valid)
  logic             pred_rd_en;// RegNext(req_pc.valid && !update_access)

  always_ff @(posedge clock) begin
    pred_rd_en <= io_req_pc_valid & ~io_update_access;
    if (io_req_pc_valid) begin
      req_tag <= get_tag(io_req_pc_bits);
      req_idx <= get_idx(io_req_pc_bits);
    end
  end

  // HoldUnless 保持寄存器（异步复位清 0：条目 valid 位须复位，避免上电误命中）
  ftb_entry_t       hold_entry [NUM_WAYS];
  logic [TAG_W-1:0] hold_tag   [NUM_WAYS];

  genvar gw;
  generate
    for (gw = 0; gw < NUM_WAYS; gw++) begin : g_hold
      always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
          hold_entry[gw] <= '0;
          hold_tag[gw]   <= '0;
        end else if (pred_rd_en) begin
          hold_entry[gw] <= sram_r_entry[gw];
          hold_tag[gw]   <= sram_r_tag[gw];
        end
      end
    end
  endgenerate

  // pred_rdata：上一拍是预测读 → 用 SRAM 当拍 resp；否则用保持值
  ftb_entry_t       pred_entry [NUM_WAYS];
  logic [TAG_W-1:0] pred_tag   [NUM_WAYS];
  generate
    for (gw = 0; gw < NUM_WAYS; gw++) begin : g_pred
      assign pred_entry[gw] = pred_rd_en ? sram_r_entry[gw] : hold_entry[gw];
      assign pred_tag[gw]   = pred_rd_en ? sram_r_tag[gw]   : hold_tag[gw];
    end
  endgenerate

  // ===========================================================================
  // s1 命中判定：4 路 tag 比较，且该路 entry.valid，且 s1_fire
  // ===========================================================================
  logic [NUM_WAYS-1:0] total_hits;
  generate
    for (gw = 0; gw < NUM_WAYS; gw++) begin : g_hit
      assign total_hits[gw] = (pred_tag[gw] == req_tag) & pred_entry[gw].valid & io_s1_fire;
    end
  endgenerate

  wire                 hit     = |total_hits;
  wire [WAY_IDX_W-1:0] hit_way = oh_to_idx(total_hits);

  // read_resp = Mux1H(total_hits, pred_entry)（命中互斥 → 按位 OR 等价 Mux1H）
  always_comb begin
    read_resp = '0;
    for (int i = 0; i < NUM_WAYS; i++)
      if (total_hits[i]) read_resp = read_resp | pred_entry[i];
  end
  assign io_read_hits_valid = hit;
  assign io_read_hits_bits  = {{(2-WAY_IDX_W){1'b0}}, hit_way};

  // ===========================================================================
  // multi-hit 兜底：把命中向量与命中条目寄存一拍（s2），检测「≥2 路同时命中」，
  //   并用 PriorityMux 选第一路命中条目作为兜底（避免 OHToUInt 在多命中时算错路号）。
  // ===========================================================================
  logic [NUM_WAYS-1:0] total_hits_reg;
  ftb_entry_t          read_entries_reg [NUM_WAYS];
  generate
    for (gw = 0; gw < NUM_WAYS; gw++) begin : g_multi_reg
      always_ff @(posedge clock) begin
        if (io_s1_fire) begin
          total_hits_reg[gw]   <= total_hits[gw];
          read_entries_reg[gw] <= pred_entry[gw];
        end
      end
    end
  endgenerate

  // multi-hit：存在任意 i<j 两路同时命中
  logic multi_hit;
  always_comb begin
    multi_hit = 1'b0;
    for (int i = 0; i < NUM_WAYS; i++)
      for (int j = 0; j < NUM_WAYS; j++)
        if (i < j) multi_hit = multi_hit | (total_hits_reg[i] & total_hits_reg[j]);
  end

  // PriorityMux：选最低位命中路号 / 其条目。
  //   Chisel PriorityMux(Seq(hit_i -> i)) 无显式默认项：当无命中时取链尾（最后一路）。
  //   故 multi_way / read_multi_entry 默认都取 NUM_WAYS-1，再由高→低遍历用低位命中覆盖。
  //   （multi_* 仅在 multi_hit 有效时被上层使用；此默认值只为与 golden 端口逐位等价。）
  logic [WAY_IDX_W-1:0] multi_way;
  always_comb begin
    multi_way        = WAY_IDX_W'(NUM_WAYS-1);
    read_multi_entry = read_entries_reg[NUM_WAYS-1];
    for (int i = NUM_WAYS-1; i >= 0; i--)
      if (total_hits_reg[i]) begin
        multi_way        = WAY_IDX_W'(i);
        read_multi_entry = read_entries_reg[i];
      end
  end
  assign io_read_multi_hits_valid = multi_hit;
  assign io_read_multi_hits_bits  = {{(2-WAY_IDX_W){1'b0}}, multi_way};

  // ===========================================================================
  // 更新读命中（update_hits）：FTQ commit 先查该 PC 是否已在 FTB。
  //   用 SRAM 当拍 resp（不经 HoldUnless）比 u_req_tag，且该路 valid，
  //   且「上一拍确实是更新读」(RegNext(update_access))。
  // ===========================================================================
  logic [TAG_W-1:0] u_req_tag;
  logic             u_access_d1;   // RegNext(update_access)
  always_ff @(posedge clock) begin
    if (io_u_req_pc_valid) u_req_tag <= get_tag(io_u_req_pc_bits);
    u_access_d1 <= io_update_access;
  end

  logic [NUM_WAYS-1:0] u_total_hits;
  generate
    for (gw = 0; gw < NUM_WAYS; gw++) begin : g_uhit
      assign u_total_hits[gw] = (sram_r_tag[gw] == u_req_tag) & sram_r_entry[gw].valid & u_access_d1;
    end
  endgenerate
  assign io_update_hits_valid = |u_total_hits;
  assign io_update_hits_bits  = {{(2-WAY_IDX_W){1'b0}}, oh_to_idx(u_total_hits)};

  // ===========================================================================
  // 写回 SRAM + 分配路选择
  //   写 set index 用 update_pc 的 idx。
  //   写哪一路 u_way：
  //     · 非 alloc（命中改写）→ io_update_write_way（上层给的命中路）；
  //     · alloc（未命中新分配）→ 组内有空路取最低位空路，全满用 PLRU victim。
  //   「各路 valid」用 RegNext(sram_resp.entry.valid) ——即更新读那一拍读出的有效位，
  //   与 u_way 在同一拍可用（alloc_valid_d1）。
  // ===========================================================================
  wire [IDX_W-1:0] u_idx = get_idx(io_update_pc);

  // alloc_valid_d1[n] = RegNext(sram_resp[n].entry.valid)
  logic [NUM_WAYS-1:0] alloc_valid_d1;
  generate
    for (gw = 0; gw < NUM_WAYS; gw++) begin : g_allocv
      always_ff @(posedge clock) alloc_valid_d1[gw] <= sram_r_entry[gw].valid;
    end
  endgenerate

  // PLRU 状态：每组 3 位，共 NUM_SETS 组
  logic [WAY_IDX_W:0] plru_state [NUM_SETS];

  // 分配路：全满 → PLRU victim；否则最低位空路（PriorityEncoder(~valids)）
  logic [WAY_IDX_W-1:0] alloc_way;
  always_comb begin
    if (&alloc_valid_d1)
      alloc_way = plru_victim4(plru_state[u_idx]);
    else begin
      alloc_way = WAY_IDX_W'(NUM_WAYS-1);
      for (int i = NUM_WAYS-1; i >= 0; i--)
        if (!alloc_valid_d1[i]) alloc_way = WAY_IDX_W'(i);
    end
  end

  wire [WAY_IDX_W-1:0] u_way = io_update_write_alloc ? alloc_way : io_update_write_way[WAY_IDX_W-1:0];

  // 写口驱动：waymask = UIntToOH(u_way)
  assign sram_w_req_valid  = io_update_write_data_valid;
  assign sram_w_req_setIdx = u_idx;
  assign sram_w_entry      = update_write_entry;
  assign sram_w_tag        = update_write_tag;
  assign sram_w_waymask    = NUM_WAYS'(1) << u_way;

  // ===========================================================================
  // setplru 替换状态更新
  //   touch（读访问延一拍，放松时序）：
  //     touch_set/way = 写有效时用写的 set/way，否则用 RegNext 的预测读 set/命中路。
  //     touch_valid   = 写有效 | RegNext(预测命中)。
  //   命中的那组在本拍 touch 该路（plru_touch4）。
  // ===========================================================================
  logic [IDX_W-1:0]     read_set_d1;   // RegNext(req_idx)
  logic                 read_hit_d1;   // RegNext(hit)
  logic [WAY_IDX_W-1:0] read_way_d1;   // RegNext(hit_way)
  always_ff @(posedge clock) begin
    read_set_d1 <= req_idx;
    read_hit_d1 <= hit;
    read_way_d1 <= hit_way;
  end

  wire                  touch_valid = io_update_write_data_valid | read_hit_d1;
  wire [IDX_W-1:0]      touch_set   = io_update_write_data_valid ? u_idx  : read_set_d1;
  wire [WAY_IDX_W-1:0]  touch_way   = io_update_write_data_valid ? u_way  : read_way_d1;

  generate
    for (genvar gs = 0; gs < NUM_SETS; gs++) begin : g_plru
      always_ff @(posedge clock or posedge reset) begin
        if (reset)
          plru_state[gs] <= '0;
        else if (touch_valid && (touch_set == IDX_W'(gs)))
          plru_state[gs] <= plru_touch4(plru_state[gs], touch_way);
      end
    end
  endgenerate

endmodule
