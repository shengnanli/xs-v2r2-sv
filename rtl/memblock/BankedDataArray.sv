// =============================================================================
// xs_BankedDataArray_core —— DCache 分体数据阵列（可读重写核）
// -----------------------------------------------------------------------------
// 对应 Chisel: xiangshan.cache.BankedDataArray.scala  class BankedDataArray
//   （“最小访问单位 = bank”的实现，论文 ASPLOS'91 高带宽多体数据存储）。
//
// 角色：DCache 的“数据体”，与 DuplicatedTagArray（tag）配对。一条 64B cacheline 横向
//   切成 8 个 bank（每 bank 8B），4 路组相联。把数据按 bank 分体，使不同 load 流水若
//   访问**不同 bank**就能同拍并行读，互不阻塞（bank 化的根本目的：提升读带宽）。
//
// 三类访问口：
//   · read[0..2]   ：3 条 LoadPipe 的“按字读”——各给一个地址，读出其所在 bank 的数据
//                    （128 位 load 会跨 2 个相邻 bank，靠 is128Req + bank_addr(1) 表达）。
//   · readline     ：MainPipe 的“整行读”——一次把整条 cacheline 的 8 个 bank 全读出。
//   · write        ：refill/store 写——一次写一整行（8 bank × 64bit），按 wmask 选 bank。
//
// 冲突仲裁（同拍多口争用同一 bank 体）：
//   · rr_bank_conflict：两条 load 命中同 bank 但不同 set（同 set 可共享读，不算冲突）。
//     冲突时按 lqIdx 选“最老”的那条放行，另一条本拍被压（rr_bank_conflict_oldest）。
//   · rrl_bank_conflict：load 与 readline 撞同一 div → readline 抢占，load 让路。
//   · wr/wrl_bank_conflict：上一拍的写与本拍读/readline 撞 → 单口 SRAM 不能同址读写，置 ready=0。
//
// 读时序（SRAM 同步读，1 拍延迟）：
//   s0(读发起拍)：组合算各 bank 的 read_enable / set 地址，驱动 bank SRAM 读口；
//                 同时寄存 div/bank/way 选择子（r_* 寄存器）。
//   s1：bank SRAM 吐出 4 路 × 72bit；按寄存的 bank/way 选出该口结果 → io_read_resp。
//   s2(再延 1 拍)：ecc 解码出的 error_delayed → io_read_error_delayed。
//
// ECC：每 bank SRAM 字宽 72 = 64 数据 + 8 ECC（SECDED）。写入时算 ECC，读出时解码判错。
//   pseudo_error 是“人为注错”通道：把读出数据异或一个 mask 制造可控错误用于演练 ECC 流程。
//
// 存储体 DataSRAMBank（→ 4 路 SRAMTemplate → 厂商宏）+ MbistPipeDCacheData 为 golden 黑盒，
// 本核暴露各 bank 的读写端口（sram_*），由 wrapper 例化黑盒并回连。
// =============================================================================
module xs_BankedDataArray_core import bankeddata_pkg::*; (
  input  logic clock,
  input  logic reset,

  // ---- read：3 条 LoadPipe 按字读 ----
  input  logic                   io_read_valid   [LOAD_PIPES],
  input  logic [N_WAYS-1:0]      io_read_way_en  [LOAD_PIPES],
  input  logic [ADDR_W-1:0]      io_read_addr    [LOAD_PIPES],
  input  logic [ADDR_W-1:0]      io_read_addr_dup[LOAD_PIPES],
  input  logic [N_BANKS-1:0]     io_read_bankMask[LOAD_PIPES],
  input  logic                   io_read_lqIdx_flag [LOAD_PIPES],
  input  logic [6:0]             io_read_lqIdx_value[LOAD_PIPES],
  output logic                   io_read_ready   [LOAD_PIPES],
  input  logic                   io_is128Req     [LOAD_PIPES],

  // ---- readline：整行读 ----
  input  logic                   io_readline_intend,
  input  logic                   io_readline_valid,
  input  logic [N_WAYS-1:0]      io_readline_way_en,
  input  logic [ADDR_W-1:0]      io_readline_addr,
  input  logic [N_BANKS-1:0]     io_readline_rmask,
  input  logic                   io_readline_can_go,
  input  logic                   io_readline_stall,
  input  logic                   io_readline_can_resp,
  output logic                   io_readline_ready,

  // ---- write：整行写 + 8 份 write_dup 控制副本 ----
  input  logic                   io_write_valid,
  input  logic [N_BANKS-1:0]     io_write_wmask,
  input  logic [ROW_BITS-1:0]    io_write_data [N_BANKS],
  input  logic                   io_write_dup_valid  [N_BANKS],
  input  logic [N_WAYS-1:0]      io_write_dup_way_en [N_BANKS],
  input  logic [ADDR_W-1:0]      io_write_dup_addr   [N_BANKS],

  // ---- 读结果 ----
  output logic [ROW_BITS-1:0]    io_readline_resp [N_BANKS],   // 整行 8 bank 数据
  output logic                   io_readline_error,
  output logic                   io_readline_error_delayed,
  output logic [ROW_BITS-1:0]    io_read_resp [LOAD_PIPES][N_LINES],  // 每口 2 行
  output logic                   io_read_error_delayed [LOAD_PIPES][N_LINES],
  output logic                   io_bank_conflict_slow [LOAD_PIPES],
  output logic                   io_disable_ld_fast_wakeup [LOAD_PIPES],

  // ---- pseudo error（人为注错演练 ECC）----
  input  logic                   io_pseudo_error_valid,
  input  logic                   io_pseudo_error_bits_valid [N_BANKS],
  input  logic [ROW_BITS-1:0]    io_pseudo_error_bits_mask  [N_BANKS],
  output logic                   io_pseudo_error_ready,

  // ---- 与 8 个 DataSRAMBank 黑盒的接口（wrapper 例化后回连）----
  output logic                   sram_r_en   [N_BANKS],
  output logic [IDX_W-1:0]       sram_r_addr [N_BANKS],
  input  logic [ENC_BITS-1:0]    sram_r_data [N_BANKS][N_WAYS],
  output logic                   sram_w_en   [N_BANKS],
  output logic [N_WAYS-1:0]      sram_w_way_en [N_BANKS],
  output logic [IDX_W-1:0]       sram_w_addr [N_BANKS],
  output logic [ENC_BITS-1:0]    sram_w_data [N_BANKS],
  // mbist ack（黑盒给出，影响 pseudo toggle 与 readline 选择）
  input  logic                   mbist_ack,
  input  logic [WAY_W-1:0]       mbist_r_way,
  input  logic                   mbist_r_div   // SET_DIV=1，恒 0
);

  // ===========================================================================
  // 1) 地址切分（每 load 口：bank/set，主地址与 dup 地址）
  //    bank_addrs[i][0] = 主 bank；bank_addrs[i][1] = is128 ? bank0+1 : bank0。
  // ===========================================================================
  logic [BANK_W-1:0] bank_addrs     [LOAD_PIPES][N_LINES];
  logic [BANK_W-1:0] bank_addrs_dup [LOAD_PIPES][N_LINES];
  logic [IDX_W-1:0]  set_addrs      [LOAD_PIPES];
  logic [IDX_W-1:0]  set_addrs_dup  [LOAD_PIPES];

  for (genvar i = 0; i < LOAD_PIPES; i++) begin : g_addr
    always_comb begin
      bank_addrs[i][0]     = addr_to_bank(io_read_addr[i]);
      bank_addrs[i][1]     = io_is128Req[i] ? (addr_to_bank(io_read_addr[i]) + 3'd1)
                                            :  addr_to_bank(io_read_addr[i]);
      bank_addrs_dup[i][0] = addr_to_bank(io_read_addr_dup[i]);
      bank_addrs_dup[i][1] = io_is128Req[i] ? (addr_to_bank(io_read_addr_dup[i]) + 3'd1)
                                            :  addr_to_bank(io_read_addr_dup[i]);
      set_addrs[i]         = addr_to_set(io_read_addr[i]);
      set_addrs_dup[i]     = addr_to_set(io_read_addr_dup[i]);
    end
  end

  wire [BANK_W-1:0] line_bank_unused = '0;  // readline 不按 bank 分（整行）
  wire [IDX_W-1:0]  line_set_addr = addr_to_set(io_readline_addr);
  // div 维退化为 0（SET_DIV=1），故 readline_match / 各 div 比较恒成立，下文省略 div 维。

  // ===========================================================================
  // 2) 冲突判定
  // ===========================================================================
  // rr_bank_conflict[x][y]：两条 load 命中相同 bankMask 交集、同 div、但不同 set
  logic rr_conflict [LOAD_PIPES][LOAD_PIPES];
  for (genvar x = 0; x < LOAD_PIPES; x++) begin : g_rrx
    for (genvar y = 0; y < LOAD_PIPES; y++) begin : g_rry
      always_comb begin
        if (x == y) rr_conflict[x][y] = 1'b0;
        else rr_conflict[x][y] =
          io_read_valid[x] & io_read_valid[y] &
          ((io_read_bankMask[x] & io_read_bankMask[y]) != '0) &
          (set_addrs[x] != set_addrs[y]);
        // 注：SET_DIV=1，div 恒相等，故 div 比较项省略。
      end
    end
  end

  // 每条 load 是否与“别的某条”冲突
  logic load_conflict [LOAD_PIPES];
  for (genvar i = 0; i < LOAD_PIPES; i++) begin : g_lc
    always_comb begin
      load_conflict[i] = 1'b0;
      for (int y = 0; y < LOAD_PIPES; y++) load_conflict[i] |= rr_conflict[i][y];
    end
  end

  // 冲突时选“最老”的端口放行（lqIdx 为环形队列指针 LqPtr，比较含 flag 翻转位）。
  //   LqPtr 比较 a 比 b 年轻 ⟺ a.flag ^ b.flag ^ (a.value > b.value)。
  //   ParallelOperation 两两归约取老者：bSel(a 比 b 年轻)→取 b，否则取 a；valid 合并。
  // 这里 LOAD_PIPES=3，按 golden 结构：先归约端口 {1,2}，再与端口 0 归约。
  function automatic logic lq_younger(input logic fa, input logic [6:0] va,
                                      input logic fb, input logic [6:0] vb);
    lq_younger = fa ^ fb ^ (va > vb);
  endfunction

  logic [1:0] conflict_sel_idx;   // 选中放行（最老有冲突）的端口索引
  always_comb begin
    // 端口 {1,2} 归约：both→bSel?2:1；仅1→1；否则→2
    automatic logic v1 = load_conflict[1];
    automatic logic v2 = load_conflict[2];
    automatic logic bSel12 = lq_younger(io_read_lqIdx_flag[1], io_read_lqIdx_value[1],
                                        io_read_lqIdx_flag[2], io_read_lqIdx_value[2]);
    automatic logic [1:0] idx12 = (v1 & v2) ? (bSel12 ? 2'd2 : 2'd1)
                                            : ((v1 & ~v2) ? 2'd1 : 2'd2);
    // idx12 对应的 lqIdx（用于与端口 0 比较）
    automatic logic       f12 = (v1 & v2) ? (bSel12 ? io_read_lqIdx_flag[2] : io_read_lqIdx_flag[1])
                                          : ((v1 & ~v2) ? io_read_lqIdx_flag[1] : io_read_lqIdx_flag[2]);
    automatic logic [6:0] x12 = (v1 & v2) ? (bSel12 ? io_read_lqIdx_value[2] : io_read_lqIdx_value[1])
                                          : ((v1 & ~v2) ? io_read_lqIdx_value[1] : io_read_lqIdx_value[2]);
    automatic logic v12 = v1 | v2;
    // 与端口 0 归约
    if (load_conflict[0] & v12)
      conflict_sel_idx = lq_younger(io_read_lqIdx_flag[0], io_read_lqIdx_value[0], f12, x12)
                         ? idx12 : 2'd0;
    else if (load_conflict[0] & ~v12)
      conflict_sel_idx = 2'd0;
    else
      conflict_sel_idx = idx12;
  end

  // 某口“因冲突且不是被选中放行者” → 本拍被压
  logic rr_oldest [LOAD_PIPES];
  for (genvar i = 0; i < LOAD_PIPES; i++) begin : g_old
    always_comb rr_oldest[i] = (conflict_sel_idx != i[1:0]) & load_conflict[i];
  end

  // ===========================================================================
  // 3) 写口寄存（refill 写晚 1 拍，地址/数据/wmask/way_en 各打一拍；dup 副本各自寄存）
  // ===========================================================================
  logic [N_BANKS-1:0] write_wmask_reg;
  logic [ROW_BITS-1:0] write_data_reg [N_BANKS];
  logic                write_valid_reg;
  logic                write_dup_valid_reg  [N_BANKS];
  logic [N_WAYS-1:0]   write_dup_wayen_reg  [N_BANKS];
  logic [IDX_W-1:0]    write_dup_set_reg    [N_BANKS];
  logic [ECC_BITS-1:0] write_ecc_reg        [N_BANKS];

  always_ff @(posedge clock) begin
    if (io_write_valid) begin
      write_wmask_reg <= io_write_wmask;
      for (int b = 0; b < N_BANKS; b++) begin
        write_data_reg[b] <= io_write_data[b];
        write_ecc_reg[b]  <= data_ecc_encode(io_write_data[b]);
      end
    end
    write_valid_reg <= io_write_valid;
    for (int b = 0; b < N_BANKS; b++) begin
      write_dup_valid_reg[b] <= io_write_dup_valid[b];
      if (io_write_dup_valid[b]) begin
        write_dup_wayen_reg[b] <= io_write_dup_way_en[b];
        write_dup_set_reg[b]   <= addr_to_set(io_write_dup_addr[b]);
      end
    end
  end

  // ===========================================================================
  // 4) 冲突聚合 → ready / disable_fast_wakeup / bank_conflict_slow
  // ===========================================================================
  // 上一拍写与本拍读撞同 div+bank → wr 冲突（用 write_dup 头副本）
  // wr 冲突：本拍读 valid + 上拍有写 + 写 wmask 命中本读的 bank。
  //   注意 SET_DIV=1 → addr_to_dcache_div 恒 0，golden 的 div 相等比较恒真，故省略；
  //   真正区分体的只有 bank（wmask 命中位），不比 set。
  logic wr_conflict [LOAD_PIPES];
  for (genvar i = 0; i < LOAD_PIPES; i++) begin : g_wr
    always_comb wr_conflict[i] =
      io_read_valid[i] & write_valid_reg &
      (write_wmask_reg[bank_addrs[i][0]] |
       (write_wmask_reg[bank_addrs[i][1]] & io_is128Req[i]));
  end
  // readline 与上一拍写撞（div 恒相等）
  wire wrl_conflict = io_readline_valid & write_valid_reg;

  // rrl：load 与 readline 撞同 div（ReduceReadlineConflict=false）
  logic rrl_conflict [LOAD_PIPES];
  logic rrl_conflict_intend [LOAD_PIPES];
  for (genvar i = 0; i < LOAD_PIPES; i++) begin : g_rrl
    always_comb begin
      automatic logic judge = io_read_valid[i];  // div 恒相等
      rrl_conflict[i]        = judge & io_readline_valid;
      rrl_conflict_intend[i] = judge & io_readline_intend;
    end
  end

  // ready
  always_comb begin
    io_readline_ready = ~wrl_conflict;
    for (int i = 0; i < LOAD_PIPES; i++)
      io_read_ready[i] = ~wr_conflict[i];   // rrhazard=false
  end

  // disable_ld_fast_wakeup[i] = wr | rrl_intend | (∃ x<i: rr_conflict[x][i])
  for (genvar i = 0; i < LOAD_PIPES; i++) begin : g_dis
    always_comb begin
      automatic logic prio = 1'b0;
      for (int x = 0; x < i; x++) prio |= rr_conflict[x][i];
      io_disable_ld_fast_wakeup[i] = wr_conflict[i] | rrl_conflict_intend[i] | prio;
    end
  end

  // bank_conflict_slow[i] = RegNext(wr|rrl) | RegNext(rr_oldest)
  logic other_conflict_reg [LOAD_PIPES];
  logic rr_oldest_reg       [LOAD_PIPES];
  always_ff @(posedge clock) begin
    for (int i = 0; i < LOAD_PIPES; i++) begin
      other_conflict_reg[i] <= wr_conflict[i] | rrl_conflict[i];
      rr_oldest_reg[i]      <= rr_oldest[i];
    end
  end
  for (genvar i = 0; i < LOAD_PIPES; i++) begin : g_slow
    always_comb io_bank_conflict_slow[i] = other_conflict_reg[i] | rr_oldest_reg[i];
  end

  // ===========================================================================
  // 5) 每 bank：算 read_enable + set 地址，驱动 bank SRAM 读口
  //    bank b 命中 = ∃ load i：valid & 未被冲突压 & (bank0==b | bank1==b&is128) ；或 readline。
  //    set 地址用 PriorityMux（按 load 口序），DuplicatedQueryBankSeq={0,1,2,3} 用 dup 地址。
  // ===========================================================================
  for (genvar b = 0; b < N_BANKS; b++) begin : g_bank_rd
    logic match     [LOAD_PIPES];
    logic match_dup [LOAD_PIPES];
    logic readline_match;
    logic [IDX_W-1:0] bank_set, bank_set_dup;
    logic ren;
    always_comb begin
      for (int i = 0; i < LOAD_PIPES; i++) begin
        match[i] = io_read_valid[i] &
          ((bank_addrs[i][0] == b[BANK_W-1:0]) |
           ((bank_addrs[i][1] == b[BANK_W-1:0]) & io_is128Req[i])) &
          ~rr_oldest[i];
        match_dup[i] = io_read_valid[i] &
          ((bank_addrs_dup[i][0] == b[BANK_W-1:0]) |
           ((bank_addrs_dup[i][1] == b[BANK_W-1:0]) & io_is128Req[i])) &
          ~rr_oldest[i];
      end
      readline_match = io_readline_valid;  // div 恒相等
      // PriorityMux 选 set（低口优先）
      bank_set = set_addrs[LOAD_PIPES-1];
      for (int i = LOAD_PIPES-1; i >= 0; i--) if (match[i]) bank_set = set_addrs[i];
      bank_set_dup = set_addrs_dup[LOAD_PIPES-1];
      for (int i = LOAD_PIPES-1; i >= 0; i--) if (match_dup[i]) bank_set_dup = set_addrs_dup[i];
      ren = readline_match;
      for (int i = 0; i < LOAD_PIPES; i++) ren |= match[i];

      sram_r_en[b]   = ren;
      // readline 优先用 line_set；否则按 PriorityMux 结果。bank 0..3 用 dup 地址。
      if (readline_match)
        sram_r_addr[b] = line_set_addr;
      else if (b < 4)
        sram_r_addr[b] = bank_set_dup;
      else
        sram_r_addr[b] = bank_set;
    end
  end

  // ===========================================================================
  // 6) bank 读结果：SRAM 数据 → pseudo toggle → 拆 raw/ecc → ECC error 延迟解码
  //    bank_result[b][w]：raw_data/ecc 组合；error_delayed 经 RegEnable(read_en) 后解码。
  // ===========================================================================
  // pseudo toggle mask（每 bank）：error 通道 valid & 本 bank valid 时取 mask，否则 0；
  //   mbist_ack 时强制 0（MBIST 读不注错）。
  logic [ROW_BITS-1:0] pseudo_toggle [N_BANKS];
  for (genvar b = 0; b < N_BANKS; b++) begin : g_pst
    always_comb pseudo_toggle[b] =
      (io_pseudo_error_valid & io_pseudo_error_bits_valid[b]) ? io_pseudo_error_bits_mask[b] : '0;
  end

  read_result_t bank_result [N_BANKS][N_WAYS];
  // ECC 延迟解码：先寄存 read_en，再用其使能寄存 encData，下一拍解码出 error。
  logic                read_en_reg [N_BANKS][N_WAYS];
  logic [ENC_BITS-1:0] ecc_dly     [N_BANKS][N_WAYS];

  for (genvar b = 0; b < N_BANKS; b++) begin : g_res
    for (genvar w = 0; w < N_WAYS; w++) begin : g_resw
      logic [ROW_BITS-1:0] raw;
      logic [ECC_BITS-1:0] ec;
      logic [ENC_BITS-1:0] encd;
      always_comb begin
        // 注错只叠在 raw 上；mbist_ack 时不叠（MBIST 读原值）
        raw  = sram_r_data[b][w][ROW_BITS-1:0] ^ (mbist_ack ? '0 : pseudo_toggle[b]);
        ec   = sram_r_data[b][w][ENC_BITS-1:ROW_BITS];
        encd = {ec, raw};
        bank_result[b][w].ecc      = ec;
        bank_result[b][w].raw_data = raw;
        bank_result[b][w].error_delayed = data_ecc_error(ecc_dly[b][w]);
      end
      always_ff @(posedge clock) begin
        read_en_reg[b][w] <= sram_r_en[b];
        if (read_en_reg[b][w]) ecc_dly[b][w] <= encd;
      end
    end
  end

  // ===========================================================================
  // 7) read_resp：每 load 口把读发起拍的 div/bank/way 寄存，s1 用其从 bank_result 选数据
  //    bank/way 索引可能为 X（无效拍），用三元 mux 收敛（golden firtool 同此处理）。
  // ===========================================================================
  for (genvar i = 0; i < LOAD_PIPES; i++) begin : g_rresp
    logic                r_fire;            // RegNext(read.fire)
    logic [BANK_W-1:0]   r_bank [N_LINES];
    logic [WAY_W-1:0]    r_way;
    logic                rr_fire;           // 2 拍后
    logic [BANK_W-1:0]   rr_bank [N_LINES];
    logic [WAY_W-1:0]    rr_way;
    wire  fire = io_read_valid[i] & io_read_ready[i];
    always_ff @(posedge clock) begin
      r_fire <= fire;
      if (fire) begin
        for (int j = 0; j < N_LINES; j++) r_bank[j] <= bank_addrs[i][j];
        r_way <= oh_to_way(io_read_way_en[i]);
      end
      rr_fire <= r_fire;
      if (r_fire) begin
        for (int j = 0; j < N_LINES; j++) rr_bank[j] <= r_bank[j];
        rr_way <= r_way;
      end
    end
    // io_read_error_delayed 的冲突门控用 RegNext(bank_conflict_slow)（与 golden 一致）
    logic slow_reg;
    always_ff @(posedge clock) slow_reg <= io_bank_conflict_slow[i];
    for (genvar j = 0; j < N_LINES; j++) begin : g_line
      always_comb begin
        // 用寄存的 bank/way 从 bank_result 选数据
        io_read_resp[i][j] = bank_result[r_bank[j]][r_way].raw_data;
        io_read_error_delayed[i][j] =
          rr_fire & bank_result[rr_bank[j]][rr_way].error_delayed & ~slow_reg;
      end
    end
  end

  // ===========================================================================
  // 8) readline_resp：整行 8 bank 数据，way/div 寄存后选；can_go/stall 控制保持。
  //    way 选择在 mbist_ack 时取 mbist_r_way；resp 经 can_go 选新值 / stall 保持旧值，
  //    最后再过一级 RegEnable(can_resp|mbist_ack)。error 用 2 拍后的 way + 本拍 ecc 解码。
  // ===========================================================================
  logic [WAY_W-1:0] rl_r_way, rl_rr_way;
  logic             rl_fire_reg;            // RegNext(readline.fire)
  wire  rl_fire = io_readline_valid & io_readline_ready;
  always_ff @(posedge clock) begin
    if (rl_fire | mbist_ack) rl_r_way <= mbist_ack ? mbist_r_way : oh_to_way(io_readline_way_en);
    rl_fire_reg <= rl_fire;
    if (rl_fire_reg) rl_rr_way <= rl_r_way;
  end

  // readline_resp 结构（与 golden / Scala 完全对齐）：
  //   组合 wire readline_resp = (can_go|mbist_ack) ? 新读行 : 保持寄存器；
  //   保持寄存器 readline_resp_r 在 (stall|mbist_ack) 时捕获该 wire；
  //   输出 r_8 = RegEnable(readline_resp_wire, can_resp|mbist_ack)。
  logic [ROW_BITS-1:0] rl_resp_r    [N_BANKS];   // 保持寄存器（raw）
  logic [ECC_BITS-1:0] rl_resp_r_ecc[N_BANKS];   // 保持寄存器（ecc）
  logic [ROW_BITS-1:0] r8_raw       [N_BANKS];   // 输出级（raw）= io_readline_resp
  logic [ECC_BITS-1:0] r8_ecc       [N_BANKS];   // 输出级（ecc）
  logic [N_BANKS-1:0]  rl_error;
  logic [N_BANKS-1:0]  rl_error_delayed;
  wire  rl_take = io_readline_can_go | mbist_ack;  // _readline_resp_7_T

  for (genvar b = 0; b < N_BANKS; b++) begin : g_rlresp
    // 组合：本拍要给出的 readline 数据
    logic [ROW_BITS-1:0] fresh_raw;
    logic [ECC_BITS-1:0] fresh_ecc;
    logic [ROW_BITS-1:0] wire_raw;
    logic [ECC_BITS-1:0] wire_ecc;
    always_comb begin
      fresh_raw = bank_result[b][rl_r_way].raw_data;
      fresh_ecc = bank_result[b][rl_r_way].ecc;
      wire_raw  = rl_take ? fresh_raw : rl_resp_r[b];
      wire_ecc  = rl_take ? fresh_ecc : rl_resp_r_ecc[b];
    end
    always_ff @(posedge clock) begin
      // 保持寄存器：stall|mbist_ack 时捕获 wire（golden 该处只在 take 真时更新值）
      if ((io_readline_stall | mbist_ack) & rl_take) begin
        rl_resp_r[b]     <= fresh_raw;
        rl_resp_r_ecc[b] <= fresh_ecc;
      end
      // 输出级
      if (io_readline_can_resp | mbist_ack) begin
        r8_raw[b] <= wire_raw;
        r8_ecc[b] <= wire_ecc;
      end
    end
    always_comb begin
      io_readline_resp[b] = r8_raw[b];
      // error：用 2 拍后 way 取 error_delayed；error_delayed：对输出级 {ecc,raw} 解码
      rl_error[b]         = bank_result[b][rl_rr_way].error_delayed;
      rl_error_delayed[b] = data_ecc_error({r8_ecc[b], r8_raw[b]});
    end
  end
  always_comb begin
    io_readline_error = |rl_error;
    io_readline_error_delayed = |rl_error_delayed;
  end

  // ===========================================================================
  // 9) pseudo_error_ready：RegNext(readline_hit | readbank_hit)
  // ===========================================================================
  logic readline_hit, readbank_hit;
  always_comb begin
    automatic logic [N_BANKS-1:0] err_valid;
    for (int b = 0; b < N_BANKS; b++) err_valid[b] = io_pseudo_error_bits_valid[b];
    readline_hit = rl_fire & ((io_readline_rmask & err_valid) != '0);
    readbank_hit = 1'b0;
    for (int i = 0; i < LOAD_PIPES; i++) begin
      automatic logic fire_i = io_read_valid[i] & io_read_ready[i];
      readbank_hit |= fire_i &
        (io_pseudo_error_bits_valid[bank_addrs[i][0]] |
         (io_pseudo_error_bits_valid[bank_addrs[i][1]] & io_is128Req[i])) &
        ~io_bank_conflict_slow[i];
    end
  end
  always_ff @(posedge clock) io_pseudo_error_ready <= readline_hit | readbank_hit;

  // ===========================================================================
  // 10) 写 bank SRAM：用寄存的 write_dup（晚 1 拍），各 bank 独立 wen/wayen/addr/data
  //     wen = wmask[b] & write_dup_valid[b] & div相等 & RegNext(write.valid)
  // ===========================================================================
  for (genvar b = 0; b < N_BANKS; b++) begin : g_wr_bank
    always_comb begin
      sram_w_en[b]     = write_wmask_reg[b] & write_dup_valid_reg[b] & write_valid_reg;
      sram_w_way_en[b] = write_dup_wayen_reg[b];
      sram_w_addr[b]   = write_dup_set_reg[b];
      sram_w_data[b]   = {write_ecc_reg[b], write_data_reg[b]};
    end
  end

endmodule
