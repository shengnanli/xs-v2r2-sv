// =============================================================================
// xs_ICacheReplacer_core —— 指令缓存（ICache）路替换算法（树形伪 LRU）
//
// 在前端的位置与作用
// ------------------------------------------------------------------
//   ICache 是组相联结构：每个虚 set（vSet）有 NUM_WAYS 路。当某 vSet 发生 miss
//   需要 refill 时，必须挑一路淘汰（victim）；当某路被命中（hit）或被 refill 填入
//   时，需要把它标记为"最近使用"（touch）。本模块就是维护各 vSet 的替换状态、
//   给出 victim way、并在 hit/refill 时更新状态的纯替换器。
//
//   - io_touch[0/1]：两条命中 touch 通道（MainPipe 的 SRAM 读命中后回写）。
//     ICache 一次取指会跨相邻两个 vSet（取指块横跨 cacheline 边界），故有 2 路 touch。
//   - io_victim：MissUnit 在 refill 前查询某 vSet 的 victim way（组合给出）。
//     查询结果会在**下一拍**作为一次 touch 写回（refill 把 victim 路填上新数据，
//     该路立即变为最近使用），即下面的"延迟 refill touch"。
//
// 替换算法：rocket-chip PseudoLRU（与 utility.ReplacementPolicy "plru" 同源）
// ------------------------------------------------------------------
//   每个 vSet 用 NUM_WAYS-1 位状态描述一棵二叉树（NUM_WAYS=4 → 3 位）：
//     state[2] = 根：指向"下次应替换"的半边（0=低半边 way0/1，1=高半边 way2/3）
//     state[1] = 高半子树根（way2 vs way3）
//     state[0] = 低半子树根（way0 vs way1）
//   victim：从根开始沿置位指示的半边下行，得到最久未用的一路。
//   touch(way)：沿被访问路的树路径，把每个节点翻转为"指向另一半边"。
//   状态编码与 rocket-chip 完全一致——这是与 golden 等价的关键。
//
// 分体（banking）：256 个 vSet 按 vSetIdx 最低位拆成 2 个 bank，各 128 组
// ------------------------------------------------------------------
//   两条 touch / 一条 victim 查询每拍最多各触达一个 bank，按各自地址的 bit0 路由。
//   两 bank 的状态阵列物理独立，故同一拍 bank0 与 bank1 可各自被一条 touch 命中。
//   这与 golden 把 state_vec 拆成 even(0..127)/odd(1_0..1_127) 两组寄存器一致。
// =============================================================================
module xs_ICacheReplacer_core #(
  parameter int unsigned NUM_SETS = 256,                 // 总 vSet 数
  parameter int unsigned NUM_WAYS = 4,                   // 每 set 路数（PLRU 树叶子数）
  localparam int unsigned SET_W   = $clog2(NUM_SETS),    // vSetIdx 位宽 = 8
  localparam int unsigned WAY_W   = $clog2(NUM_WAYS),    // way 位宽 = 2
  localparam int unsigned STATE_W = NUM_WAYS - 1,        // PLRU 状态位宽 = 3
  localparam int unsigned NUM_BANKS = 2,                 // 按 vSetIdx[0] 分 2 bank
  localparam int unsigned BANK_SETS = NUM_SETS / NUM_BANKS, // 每 bank 组数 = 128
  localparam int unsigned BSET_W  = $clog2(BANK_SETS)    // bank 内组号位宽 = 7
)(
  input  logic               clock,
  input  logic               reset,

  // 命中 touch 通道 0 / 1（取指可能跨两个相邻 vSet，故两条）
  input  logic               io_touch_0_valid,
  input  logic [SET_W-1:0]   io_touch_0_bits_vSetIdx,
  input  logic [WAY_W-1:0]   io_touch_0_bits_way,
  input  logic               io_touch_1_valid,
  input  logic [SET_W-1:0]   io_touch_1_bits_vSetIdx,
  input  logic [WAY_W-1:0]   io_touch_1_bits_way,

  // victim 查询：组合给出该 vSet 当前应淘汰的路；valid 触发下一拍的 refill touch
  input  logic               io_victim_vSetIdx_valid,
  input  logic [SET_W-1:0]   io_victim_vSetIdx_bits,
  output logic [WAY_W-1:0]   io_victim_way
);

  // ---------------------------------------------------------------------------
  // PLRU 纯函数（4 路专用；编码同 rocket-chip PseudoLRU，与 golden 逐位一致）
  // ---------------------------------------------------------------------------
  // victim：state[2] 选高/低半边，再用对应子树根选具体一路
  function automatic logic [WAY_W-1:0] plru_victim(input logic [STATE_W-1:0] s);
    plru_victim = {s[2], s[2] ? s[1] : s[0]};
  endfunction

  // touch：沿 way 路径翻转各节点，指向"另一半边"
  //   根   <- ~way[1]
  //   way[1]=1（高半边）：高子树根 <- ~way[0]，低子树根保持
  //   way[1]=0（低半边）：低子树根 <- ~way[0]，高子树根保持
  function automatic logic [STATE_W-1:0] plru_touch(
    input logic [STATE_W-1:0] s,
    input logic [WAY_W-1:0]   way
  );
    plru_touch = {~way[1],
                  way[1] ? ~way[0] : s[1],
                  way[1] ? s[0]    : ~way[0]};
  endfunction

  // ---------------------------------------------------------------------------
  // touch 路由：把两条 touch 通道按地址 bit0 归到对应 bank
  // ---------------------------------------------------------------------------
  // 每个 bank b 选出要施加到它的那条 touch：以**端口 b 自身**的地址 bit0 作选择子
  // （bank0 看 touch0[0]、bank1 看 touch1[0]）——bit0=0 取 touch0，bit0=1 取 touch1。
  // 这与 golden 的 touch_ways_b_0_* 逐位一致（注意是非对称的：两 bank 用不同端口的
  // bit0 当选择子，而非简单的"地址匹配 bank"）。正常用例中两条 touch 指向相邻偶/奇
  // 组，恰好分别落到 bank0/bank1；该选择子在此前提下等价于按地址归 bank。
  logic                 bank_touch_valid [NUM_BANKS];
  logic [BSET_W-1:0]    bank_touch_set   [NUM_BANKS];
  logic [WAY_W-1:0]     bank_touch_way   [NUM_BANKS];

  always_comb begin
    logic               port_valid [NUM_BANKS]; // 各端口的 valid/set/way（按端口号索引）
    logic [BSET_W-1:0]  port_set   [NUM_BANKS];
    logic [WAY_W-1:0]   port_way   [NUM_BANKS];
    logic               port_lsb   [NUM_BANKS]; // 各端口地址 bit0（作 bank 选择子）
    port_valid[0] = io_touch_0_valid;
    port_valid[1] = io_touch_1_valid;
    port_set[0]   = io_touch_0_bits_vSetIdx[SET_W-1:1];
    port_set[1]   = io_touch_1_bits_vSetIdx[SET_W-1:1];
    port_way[0]   = io_touch_0_bits_way;
    port_way[1]   = io_touch_1_bits_way;
    port_lsb[0]   = io_touch_0_bits_vSetIdx[0];
    port_lsb[1]   = io_touch_1_bits_vSetIdx[0];
    for (int unsigned b = 0; b < NUM_BANKS; b++) begin
      // bank b 用端口 b 的 bit0 选择：0→端口0，1→端口1
      logic sel1;
      sel1 = port_lsb[b];
      bank_touch_valid[b] = sel1 ? port_valid[1] : port_valid[0];
      bank_touch_set  [b] = sel1 ? port_set[1]   : port_set[0];
      bank_touch_way  [b] = sel1 ? port_way[1]   : port_way[0];
    end
  end

  // ---------------------------------------------------------------------------
  // 延迟 refill touch：victim 查询的下一拍，把"被淘汰且已 refill 的那一路"标记为
  // 最近使用。锁存上一拍的查询 set 与给出的 victim way，按 bit0 归 bank。
  // ---------------------------------------------------------------------------
  logic              refill_touch_valid_reg; // 上一拍 io_victim_vSetIdx_valid
  logic [SET_W-1:0]  victim_vSetIdx_reg;     // 上一拍查询的 vSetIdx
  logic [WAY_W-1:0]  victim_way_reg;         // 上一拍给出的 victim way（即被填入的路）

  // 每 bank 的 refill touch：仅当锁存地址 bit0 == bank 时生效
  logic              bank_refill_valid [NUM_BANKS];
  logic [BSET_W-1:0] bank_refill_set;
  always_comb begin
    bank_refill_set = victim_vSetIdx_reg[SET_W-1:1];
    for (int unsigned b = 0; b < NUM_BANKS; b++)
      bank_refill_valid[b] = refill_touch_valid_reg & (victim_vSetIdx_reg[0] == b[0]);
  end

  // ---------------------------------------------------------------------------
  // 状态阵列：每 bank 一组 BANK_SETS × STATE_W 位 PLRU 状态
  // ---------------------------------------------------------------------------
  logic [STATE_W-1:0] plru_state [NUM_BANKS][BANK_SETS];

  // 更新逻辑：每组每拍可同时收到"命中 touch"与"refill touch"。rocket-chip 的
  // ReplacementPolicy 语义是把同拍多次 touch **按顺序依次折叠**，而非二选一：
  //   先应用命中 touch（若有），再在其结果之上应用 refill touch（若有）。
  // 折叠顺序固定为 [命中, refill]——refill 在后，故根位由 refill way 决定，而
  // refill 未触及的另一半子树位则保留命中 touch 的结果。两者只命中其一时退化为
  // 单次 plru_touch；都没有则状态保持。这与 golden 把命中结果再喂给 refill 的
  // 嵌套三元表达式等价。
  genvar gb, gs;
  generate
    for (gb = 0; gb < NUM_BANKS; gb++) begin : g_bank
      for (gs = 0; gs < BANK_SETS; gs++) begin : g_set
        always_ff @(posedge clock or posedge reset) begin
          if (reset) begin
            plru_state[gb][gs] <= '0;
          end else begin
            logic [STATE_W-1:0] s_cur;   // 折叠中的中间状态
            logic               hit_en;  // 本组本拍命中 touch 有效
            logic               rfl_en;  // 本组本拍 refill touch 有效
            s_cur  = plru_state[gb][gs];
            hit_en = bank_touch_valid[gb]  && (bank_touch_set[gb] == BSET_W'(gs));
            rfl_en = bank_refill_valid[gb] && (bank_refill_set    == BSET_W'(gs));
            // 1) 命中 touch 先折叠
            if (hit_en) s_cur = plru_touch(s_cur, bank_touch_way[gb]);
            // 2) refill touch 后折叠（叠加在命中结果之上）
            if (rfl_en) s_cur = plru_touch(s_cur, victim_way_reg);
            if (hit_en || rfl_en) plru_state[gb][gs] <= s_cur;
          end
        end
      end
    end
  endgenerate

  // ---------------------------------------------------------------------------
  // 锁存控制寄存器（victim 查询 → 下一拍 refill touch）
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      victim_vSetIdx_reg <= '0;
      victim_way_reg     <= '0;
    end else if (io_victim_vSetIdx_valid) begin
      victim_vSetIdx_reg <= io_victim_vSetIdx_bits;
      victim_way_reg     <= io_victim_way; // 锁存本拍组合给出的 victim
    end
  end

  // golden 中该 valid 由不带异步复位的 always @(posedge clock) 驱动
  always_ff @(posedge clock) begin
    refill_touch_valid_reg <= io_victim_vSetIdx_valid;
  end

  // ---------------------------------------------------------------------------
  // victim 输出：组合读取查询 vSet 所在 bank 的当前 PLRU 状态
  // ---------------------------------------------------------------------------
  always_comb begin
    logic [STATE_W-1:0] sel_state;
    sel_state     = plru_state[io_victim_vSetIdx_bits[0]][io_victim_vSetIdx_bits[SET_W-1:1]];
    io_victim_way = plru_victim(sel_state);
  end

endmodule
