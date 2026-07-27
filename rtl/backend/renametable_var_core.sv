// =====================================================================
// xs_RenameTable_var_core —— 参数化寄存器别名表(RAT)可读核【fp/vec/v0/vl 变体】
// ---------------------------------------------------------------------
// 与已签核的 xs_RenameTable_core(整数 Reg_I 例化)逐字同构的逻辑, 仅把
// 固定 localparam 提升为 module parameter, 供 golden 变体
//   RenameTable_1 (fpRat)  / RenameTable_2 (vecRat) / RenameTable_3 (v0Rat,vlRat)
// 复用。区别于基核的三处结构参数(经 diff golden 逐项核对):
//
//   1. NUM_ENTRY : spec_table/arch_table 项数 (int=32 / fp=34 / vec=47 / v0,vl=1)
//   2. ADDR_W    : 逻辑寄存器号位宽 (int=5 / fp,vec=6 / v0,vl=0→夹到1)
//   3. NUM_READ  : 读口数 = RenameWidth*ReadPerRn (int=12 / fp,vec=18 / v0,vl=6)
//   4. HAS_NEED_FREE : 仅整数 RAT 有 old_pdest 引用计数回收(need_free)。
//                      fp/vec/v0/vl 无此逻辑 → 参数关掉(核内 need_free 恒 0, wrapper 不接)。
//   5. difftest 真值表: 独立于 spec/arch 表, 项数 = NUM_DIFF_ENTRY, 覆盖逻辑寄存器号
//                      [DIFF_BASE .. DIFF_BASE+NUM_DIFF_ENTRY-1]; 写口比对 addr==DIFF_BASE+idx,
//                      复位初值 = 该逻辑号(identity map, RESET_IDENTITY)。
//                      int : NUM_DIFF_ENTRY=32 DIFF_BASE=0 RESET_IDENTITY=0(全0)
//                      fp  : 32 / 0 / 1
//                      vec : 31 / 1 / 1   ← v0(逻辑号0)不在 vec 真值表内, 故 base=1
//                      v0,vl: 1 / 0 / 0
//
// spec/arch 表复位:整数 RAT 全 0;fp/vec identity(table[e]<=e)。用 RESET_IDENTITY 控制。
// (v0/vl 只 1 项 index 0, identity 与全0 同值, 参数取 0。)
//
// 快照黑盒 SnapshotGenerator_{4,5,6,7} 由 wrapper 例化并连 spec_table/snapshots,
// 本核只暴露 spec_table 数组给外部, 与基核一致(黑盒不进核, 便于两侧同源黑盒对齐)。
// =====================================================================
module xs_RenameTable_var_core
  import renametable_pkg::*;
#(
  parameter int NUM_ENTRY      = 34,
  parameter int ADDR_W         = 6,
  parameter int NUM_READ       = 18,
  parameter int NUM_DIFF_ENTRY = 32,
  parameter int DIFF_BASE      = 0,
  parameter bit HAS_NEED_FREE  = 1'b0,
  parameter bit RESET_IDENTITY = 1'b1
) (
  input  logic                          clock,
  input  logic                          reset,

  input  logic                          io_redirect,

  // 读口
  input  logic                          io_readPorts_hold [NUM_READ],
  input  logic [ADDR_W-1:0]             io_readPorts_addr [NUM_READ],
  output logic [PHYREG_W-1:0]           io_readPorts_data [NUM_READ],

  // 投机写口 / 体系结构写口
  input  logic                          io_specWritePorts_wen  [COMMIT_WIDTH],
  input  logic [ADDR_W-1:0]             io_specWritePorts_addr [COMMIT_WIDTH],
  input  logic [PHYREG_W-1:0]           io_specWritePorts_data [COMMIT_WIDTH],
  input  logic                          io_archWritePorts_wen  [COMMIT_WIDTH],
  input  logic [ADDR_W-1:0]             io_archWritePorts_addr [COMMIT_WIDTH],
  input  logic [PHYREG_W-1:0]           io_archWritePorts_data [COMMIT_WIDTH],

  output logic [PHYREG_W-1:0]           io_old_pdest [COMMIT_WIDTH],
  output logic                          io_need_free [COMMIT_WIDTH],

  // 快照端口(转发给 wrapper 侧的 SnapshotGenerator 黑盒)
  input  logic                          io_snpt_snptEnq,
  input  logic                          io_snpt_snptDeq,
  input  logic                          io_snpt_useSnpt,
  input  logic [SNAP_SEL_W-1:0]         io_snpt_snptSelect,
  input  logic [SNAPSHOT_NUM-1:0]       io_snpt_flushVec,

  // spec_table 暴露(喂 SnapshotGenerator.io_enqData)
  output logic [PHYREG_W-1:0]           o_spec_table [NUM_ENTRY],
  // 快照回读(SnapshotGenerator.io_snapshots → 用于整表回退)
  input  logic [PHYREG_W-1:0]           i_snapshots  [SNAPSHOT_NUM][NUM_ENTRY],
  // 打一拍的 redirect(喂 SnapshotGenerator.io_redirect)
  output logic                          o_t1_redirect,
  // 打一拍的 snpt(喂 SnapshotGenerator.io_enq/deq/flushVec)
  output logic                          o_t1_snpt_snptEnq,
  output logic                          o_t1_snpt_snptDeq,
  output logic [SNAPSHOT_NUM-1:0]       o_t1_snpt_flushVec,

  // difftest 真值表写口与读出
  input  logic                          io_diffWritePorts_wen  [NUM_DIFF],
  input  logic [ADDR_W-1:0]             io_diffWritePorts_addr [NUM_DIFF],
  input  logic [PHYREG_W-1:0]           io_diffWritePorts_data [NUM_DIFF],
  output logic [PHYREG_W-1:0]           io_diff_rdata          [NUM_DIFF_ENTRY]
);

  // 注:当 2^ADDR_W > NUM_ENTRY(fp/vec/v0/vl 变体)原始 addr 可越界。所有按 addr 读表处
  // 一律用"遍历 entry 比较 addr 命中则取, 否则默认 [0]"的显式 mux(复刻 golden _GEN[addr]
  // 读 LUT 的越界补 [0] 语义), 不用动态数组下标, 从而不触发 FM 严格模式 FMR_ELAB-147。

  // =====================================================================
  // 1. 表与寄存器声明
  // =====================================================================
  logic [PHYREG_W-1:0] spec_table     [NUM_ENTRY];
  logic [PHYREG_W-1:0] arch_table     [NUM_ENTRY];
  // difftest 真值表按【逻辑寄存器号】索引(DIFF_BASE..DIFF_BASE+NUM_DIFF_ENTRY-1),
  // 与 golden difftest_table_<逻辑号> 命名一致 → FM 按名逐项正确配对(vec 的 DIFF_BASE=1
  // 令表项为 difftest_table[1..31] 对应 golden difftest_table_1..31)。
  localparam int DIFF_HI = DIFF_BASE + NUM_DIFF_ENTRY - 1;
  logic [PHYREG_W-1:0] difftest_table [DIFF_BASE:DIFF_HI];

  logic [PHYREG_W-1:0] old_pdest [COMMIT_WIDTH];
  logic                need_free [COMMIT_WIDTH];

  // 打一拍的投机写口——用参数化位宽的分离数组(不用 renametable_pkg 的 rat_wport_t,
  // 其 addr 字段固定 5 位=整数 RAT 宽度, 会把 fp/vec 的 6 位地址截断致写错索引)。
  logic                t1_wSpec_wen  [COMMIT_WIDTH];
  logic [ADDR_W-1:0]   t1_wSpec_addr [COMMIT_WIDTH];
  logic [PHYREG_W-1:0] t1_wSpec_dbits[COMMIT_WIDTH];
  logic [ADDR_W-1:0]   t1_raddr [NUM_READ];      // 打一拍的读地址(hold 保持)

  logic                t1_redirect;
  logic                t2_redirect;
  logic                t1_snpt_snptEnq, t1_snpt_snptDeq, t1_snpt_useSnpt;
  logic [SNAP_SEL_W-1:0] t1_snpt_snptSelect;
  logic [SNAPSHOT_NUM-1:0] t1_snpt_flushVec;
  logic                t2_snpt_useSnpt;
  logic [SNAP_SEL_W-1:0] t2_snpt_snptSelect;

  // 暴露 spec_table / t1 信号给 wrapper(接 SnapshotGenerator 黑盒)
  always_comb for (int e = 0; e < NUM_ENTRY; e++) o_spec_table[e] = spec_table[e];
  assign o_t1_redirect      = t1_redirect;
  assign o_t1_snpt_snptEnq  = t1_snpt_snptEnq;
  assign o_t1_snpt_snptDeq  = t1_snpt_snptDeq;
  assign o_t1_snpt_flushVec = t1_snpt_flushVec;

  // =====================================================================
  // 2. 读口:同步读 spec_table + 当拍写旁路(高编号口优先)
  // =====================================================================
  logic [COMMIT_WIDTH-1:0] t0_bypass [NUM_READ];
  generate
    if (NUM_ENTRY == 1) begin : g_byp1
      // 单项表:读/写地址恒 0, 旁路命中 = 写有效(golden 单项 RAT 的 matchVec = wen)。
      always_comb
        for (int i = 0; i < NUM_READ; i++)
          for (int p = 0; p < COMMIT_WIDTH; p++)
            t0_bypass[i][p] = io_specWritePorts_wen[p];
    end else begin : g_bypN
      always_comb
        for (int i = 0; i < NUM_READ; i++)
          for (int p = 0; p < COMMIT_WIDTH; p++) begin
            logic match;
            match = io_specWritePorts_wen[p] &
                    (io_readPorts_hold[i] ? (io_specWritePorts_addr[p] == t1_raddr[i])
                                          : (io_specWritePorts_addr[p] == io_readPorts_addr[i]));
            t0_bypass[i][p] = match;
          end
    end
  endgenerate

  logic [COMMIT_WIDTH-1:0] t1_bypass [NUM_READ];

  function automatic logic [PHYREG_W-1:0] prio_pick
      (input logic [COMMIT_WIDTH-1:0] hit, input logic [PHYREG_W-1:0] wdata [COMMIT_WIDTH]);
    logic [PHYREG_W-1:0] d;
    begin
      d = '0;
      for (int p = 0; p < COMMIT_WIDTH; p++)
        if (hit[p]) d = wdata[p];
      return d;
    end
  endfunction

  logic [PHYREG_W-1:0] t1_wSpec_data [COMMIT_WIDTH];
  always_comb for (int p = 0; p < COMMIT_WIDTH; p++) t1_wSpec_data[p] = t1_wSpec_dbits[p];

  // 同步读:地址越界(t1_raddr >= NUM_ENTRY, 仅当 2^ADDR_W > NUM_ENTRY 才可能)读回
  // spec_table[0]——与 golden 读 LUT 高位补 spec_table_0 一致(firtool 定宽 mux pad)。
  // 用显式 mux(遍历 entry 比较 addr)而非动态数组下标, 复刻 golden 的 _GEN[addr] 读 LUT:
  // 命中项返回该项, 无命中(越界)默认 spec_table[0]。避免 FM 严格模式 FMR_ELAB-147。
  logic [PHYREG_W-1:0] spec_read [NUM_READ];
  generate
    if (NUM_ENTRY == 1) begin : g_read1
      // 单项表:恒读 entry 0, 不依赖读地址(golden 单项 RAT 无 raddr 寄存器)。
      always_comb for (int i = 0; i < NUM_READ; i++) spec_read[i] = spec_table[0];
    end else begin : g_readN
      always_comb
        for (int i = 0; i < NUM_READ; i++) begin
          spec_read[i] = spec_table[0];
          for (int e = 0; e < NUM_ENTRY; e++)
            if (t1_raddr[i] == ADDR_W'(e)) spec_read[i] = spec_table[e];
        end
    end
  endgenerate

  always_comb
    for (int i = 0; i < NUM_READ; i++)
      io_readPorts_data[i] = (|t1_bypass[i]) ? prio_pick(t1_bypass[i], t1_wSpec_data)
                                             : spec_read[i];

  // =====================================================================
  // 3. 投机写口命中(spec_table 写):每口 one-hot
  // =====================================================================
  // one-hot 命中位 = wen & (addr == e)。等价 golden 的 (1<<addr)[NUM_ENTRY-1:0]:
  // 逐项 addr 比较避免任何位宽/移位截断歧义(NUM_ENTRY 非 2 的幂时 1<<addr 的
  // 定宽转换在不同工具下有坑; 直接 addr==e 与 golden _GEN 逐项一致)。
  logic [COMMIT_WIDTH-1:0] spec_hit [NUM_ENTRY];
  generate
    if (NUM_ENTRY == 1) begin : g_hit1
      // 单项表:命中 = 写有效(addr 恒 0, golden 单项 RAT 无 addr 寄存器, matchVec=wen)。
      always_comb for (int p = 0; p < COMMIT_WIDTH; p++) spec_hit[0][p] = t1_wSpec_wen[p];
    end else begin : g_hitN
      always_comb
        for (int e = 0; e < NUM_ENTRY; e++)
          for (int p = 0; p < COMMIT_WIDTH; p++)
            spec_hit[e][p] = t1_wSpec_wen[p] & (t1_wSpec_addr[p] == ADDR_W'(e));
    end
  endgenerate

  // =====================================================================
  // 4. 体系结构写口(arch_table 写) + old_pdest + need_free
  // =====================================================================
  logic [PHYREG_W-1:0] arch_next [NUM_ENTRY];
  always_comb
    for (int e = 0; e < NUM_ENTRY; e++) begin
      arch_next[e] = arch_table[e];
      for (int p = 0; p < COMMIT_WIDTH; p++)
        if (io_archWritePorts_wen[p] && io_archWritePorts_addr[p] == ADDR_W'(e))
          arch_next[e] = io_archWritePorts_data[p];
    end

  logic [PHYREG_W-1:0] old_pdest_next [COMMIT_WIDTH];
  always_comb
    for (int i = 0; i < COMMIT_WIDTH; i++) begin
      logic [PHYREG_W-1:0] base;
      logic                found;
      // arch_table 读 LUT(golden _GEN[archAddr], 越界补 arch_table[0]): 显式 mux 防 ELAB-147。
      base  = arch_table[0];
      for (int e = 0; e < NUM_ENTRY; e++)
        if (io_archWritePorts_addr[i] == ADDR_W'(e)) base = arch_table[e];
      found = 1'b0;
      for (int j = i-1; j >= 0; j--)
        if (!found && io_archWritePorts_wen[j] &&
            io_archWritePorts_addr[j] == io_archWritePorts_addr[i]) begin
          base  = io_archWritePorts_data[j];
          found = 1'b1;
        end
      old_pdest_next[i] = base & {PHYREG_W{io_archWritePorts_wen[i]}};
    end

  logic [COMMIT_WIDTH-1:0] need_free_next;
  always_comb
    for (int i = 0; i < COMMIT_WIDTH; i++) begin
      logic uniq, blockedDup;
      uniq = 1'b1;
      for (int e = 0; e < NUM_ENTRY; e++)
        if (arch_table[e] == old_pdest[i]) uniq = 1'b0;
      blockedDup = 1'b0;
      for (int j = 0; j < i; j++)
        if (old_pdest[j] == old_pdest[i]) blockedDup = 1'b1;
      need_free_next[i] = uniq & ~blockedDup;
    end

  // =====================================================================
  // 5. difftest 真值表(无旁路;高编号口优先);表项按逻辑寄存器号 d 索引(DIFF_BASE..DIFF_HI)。
  // =====================================================================
  logic [PHYREG_W-1:0] difftest_next [DIFF_BASE:DIFF_HI];
  always_comb
    for (int d = DIFF_BASE; d <= DIFF_HI; d++) begin
      difftest_next[d] = difftest_table[d];
      for (int p = 0; p < NUM_DIFF; p++)
        if (io_diffWritePorts_wen[p] && io_diffWritePorts_addr[p] == ADDR_W'(d))
          difftest_next[d] = io_diffWritePorts_data[p];
    end

  // 输出 diff_rdata[e] = 逻辑号 (DIFF_BASE+e) 的真值(golden diff_rdata_e = difftest_table_{DIFF_BASE+e})。
  always_comb for (int e = 0; e < NUM_DIFF_ENTRY; e++) io_diff_rdata[e] = difftest_table[DIFF_BASE + e];

  // =====================================================================
  // 6. 输出连接
  // =====================================================================
  always_comb
    for (int i = 0; i < COMMIT_WIDTH; i++)
      io_old_pdest[i] = old_pdest[i];

  // need_free 仅整数 RAT(HAS_NEED_FREE=1)有;变体(fp/vec/v0/vl)golden 无此输出与寄存器。
  generate
    if (HAS_NEED_FREE) begin : g_nfree
      always_comb for (int i = 0; i < COMMIT_WIDTH; i++) io_need_free[i] = need_free[i];
      always_ff @(posedge clock or posedge reset)
        if (reset)      for (int i = 0; i < COMMIT_WIDTH; i++) need_free[i] <= 1'b0;
        else            for (int i = 0; i < COMMIT_WIDTH; i++) need_free[i] <= need_free_next[i];
    end else begin : g_nofree
      always_comb for (int i = 0; i < COMMIT_WIDTH; i++) io_need_free[i] = 1'b0;
    end
  endgenerate

  // =====================================================================
  // 7. 时序更新
  // =====================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int e = 0; e < NUM_ENTRY; e++) begin
        spec_table[e] <= RESET_IDENTITY ? PHYREG_W'(e) : '0;
        arch_table[e] <= RESET_IDENTITY ? PHYREG_W'(e) : '0;
      end
      for (int d = DIFF_BASE; d <= DIFF_HI; d++)
        difftest_table[d] <= RESET_IDENTITY ? PHYREG_W'(d) : '0;
      for (int i = 0; i < COMMIT_WIDTH; i++)
        old_pdest[i] <= '0;
    end else begin
      for (int e = 0; e < NUM_ENTRY; e++) begin
        if (t2_redirect)
          spec_table[e] <= t2_snpt_useSnpt ? i_snapshots[t2_snpt_snptSelect][e]
                                           : arch_table[e];
        else if (|spec_hit[e])
          spec_table[e] <= prio_pick(spec_hit[e], t1_wSpec_data);
      end

      for (int e = 0; e < NUM_ENTRY; e++)
        arch_table[e] <= arch_next[e];
      for (int i = 0; i < COMMIT_WIDTH; i++)
        old_pdest[i] <= old_pdest_next[i];

      for (int d = DIFF_BASE; d <= DIFF_HI; d++)
        difftest_table[d] <= difftest_next[d];
    end
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      t1_redirect <= 1'b0;
      t1_snpt_snptEnq <= 1'b0; t1_snpt_snptDeq <= 1'b0; t1_snpt_useSnpt <= 1'b0;
      t1_snpt_snptSelect <= '0; t1_snpt_flushVec <= '0;
      t2_snpt_useSnpt <= 1'b0; t2_snpt_snptSelect <= '0;
    end else begin
      t1_redirect <= io_redirect;

      t1_snpt_snptEnq    <= io_snpt_snptEnq;
      t1_snpt_snptDeq    <= io_snpt_snptDeq;
      t1_snpt_useSnpt    <= io_snpt_useSnpt;
      t1_snpt_snptSelect <= io_snpt_snptSelect;
      t1_snpt_flushVec   <= io_snpt_flushVec;
      t2_snpt_useSnpt    <= t1_snpt_useSnpt;
      t2_snpt_snptSelect <= t1_snpt_snptSelect;
    end
  end

  always_ff @(posedge clock) begin
    t2_redirect <= t1_redirect;

    for (int p = 0; p < COMMIT_WIDTH; p++) begin
      t1_wSpec_wen[p]   <= io_redirect ? 1'b0 : io_specWritePorts_wen[p];
      t1_wSpec_dbits[p] <= io_redirect ? '0   : io_specWritePorts_data[p];
    end

    for (int i = 0; i < NUM_READ; i++)
      t1_bypass[i] <= io_redirect ? '0 : t0_bypass[i];
  end

  // t1_wSpec_addr 仅多项表需要(单项表 addr 恒 0, golden 单项 RAT 无此寄存器, 命中只看 wen)。
  generate
    if (NUM_ENTRY > 1) begin : g_wspec_addr
      always_ff @(posedge clock)
        for (int p = 0; p < COMMIT_WIDTH; p++)
          t1_wSpec_addr[p] <= io_redirect ? '0 : io_specWritePorts_addr[p];
    end
  endgenerate

  // t1_raddr 同步读地址寄存器仅多项表需要(单项表恒读 entry 0, golden 无此寄存器)。
  generate
    if (NUM_ENTRY > 1) begin : g_raddr
      always_ff @(posedge clock)
        for (int i = 0; i < NUM_READ; i++)
          if (!io_readPorts_hold[i])
            t1_raddr[i] <= io_readPorts_addr[i];
    end
  endgenerate

endmodule
