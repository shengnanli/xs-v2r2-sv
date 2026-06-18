// =====================================================================
// xs_RenameTable_core —— 寄存器别名表(RAT) 可读重写【整数 Reg_I 例化】
// ---------------------------------------------------------------------
// 功能定位(后端 Rename 级)：
//   维护「逻辑寄存器号 → 物理寄存器号」映射。重命名(decode-rename)级读这张表
//   拿到源寄存器的物理号；写整数寄存器的指令把目的逻辑号映射到新物理号。
//
// 两张 32×8bit 寄存器堆：
//   spec_table  投机态映射。重命名/回滚时被 specWritePorts 写；分支预测错误
//               (redirect)时整表回退到 arch_table 或某个快照(snapshot)。读口读它。
//   arch_table  体系结构态映射。仅在 RAB 提交(commit)时被 archWritePorts 写，
//               代表"已确定不会回退"的映射；redirect 用它恢复 spec_table。
//
// 关键时序(Scala 原注释，为改善时序读写都打一拍)：
//   (1) T0 写 → T1 实际生效(写口寄存为 t1_wSpec)；
//   (2) 读同步：addr 在 T0 寄存(t1_raddr)，用它访问 spec_table 得到 T0 数据；
//   (3) T0 写数据旁路到 T1 读数据(t1_bypass)。
//   (4) redirect 影响延迟两拍：t1_redirect=RegNext(redirect)，回退在 RegNext(t1_redirect)。
//
// 额外输出：
//   old_pdest[i]  archWrite 口 i 写入前该逻辑寄存器的旧物理号(供回收)。
//   need_free[i]  该旧物理号在 arch_table 中已无人引用 → 可回收(回收给 freelist)。
//   diff_rdata    difftest 用的"真值"映射表(无旁路、直接写)读出。
//
// 注：SnapshotGenerator_4(快照整张 spec_table)当黑盒例化。
// =====================================================================
module xs_RenameTable_core
  import renametable_pkg::*;
(
  input  logic                          clock,
  input  logic                          reset,

  input  logic                          io_redirect,

  // 读口(12 个：RenameWidth=6 × 每指令 2 个源)
  input  rat_rport_t                    io_readPorts_in  [NUM_READ],
  output logic [PHYREG_W-1:0]           io_readPorts_data[NUM_READ],

  // 投机写口(重命名 / walk 回放)
  input  rat_wport_t                    io_specWritePorts[COMMIT_WIDTH],
  // 体系结构写口(commit)
  input  rat_wport_t                    io_archWritePorts[COMMIT_WIDTH],

  output logic [PHYREG_W-1:0]           io_old_pdest     [COMMIT_WIDTH],
  output logic                          io_need_free     [COMMIT_WIDTH],

  // 快照端口(转发 SnapshotGenerator 黑盒；注意用打一拍的 t1_snpt 驱动)
  input  logic                          io_snpt_snptEnq,
  input  logic                          io_snpt_snptDeq,
  input  logic                          io_snpt_useSnpt,
  input  logic [SNAP_SEL_W-1:0]         io_snpt_snptSelect,
  input  logic [SNAPSHOT_NUM-1:0]       io_snpt_flushVec,

  // difftest 真值表写口(无旁路)与读出
  input  rat_wport_t                    io_diffWritePorts[NUM_DIFF],
  output logic [PHYREG_W-1:0]           io_diff_rdata    [NUM_ENTRY]
);

  // =====================================================================
  // 1. 表与寄存器声明
  // =====================================================================
  logic [PHYREG_W-1:0] spec_table     [NUM_ENTRY];
  logic [PHYREG_W-1:0] arch_table     [NUM_ENTRY];
  logic [PHYREG_W-1:0] difftest_table [NUM_ENTRY];

  logic [PHYREG_W-1:0] old_pdest [COMMIT_WIDTH];
  logic                need_free [COMMIT_WIDTH];

  // -------- 打一拍的写口 / 读地址 / redirect / snpt --------
  // t1_wSpec = RegNext(redirect ? 0 : specWritePorts)：redirect 拍清零写口。
  rat_wport_t          t1_wSpec [COMMIT_WIDTH];
  // t1_raddr[i] = RegEnable(addr, !hold)：hold 时保持(stall)，实现同步读。
  logic [ADDR_W-1:0]   t1_raddr [NUM_READ];

  logic                t1_redirect;        // RegNext(io_redirect)
  logic                t2_redirect;        // RegNext(t1_redirect)，整表回退触发
  // snpt 打一拍(驱动黑盒) + 打两拍(选回退快照)
  logic                t1_snpt_snptEnq, t1_snpt_snptDeq, t1_snpt_useSnpt;
  logic [SNAP_SEL_W-1:0] t1_snpt_snptSelect;
  logic [SNAPSHOT_NUM-1:0] t1_snpt_flushVec;
  logic                t2_snpt_useSnpt;
  logic [SNAP_SEL_W-1:0] t2_snpt_snptSelect;

  // =====================================================================
  // 2. 快照黑盒：对整张 spec_table 打快照，redirect 时供整表恢复
  //    snapshots[s][e] = 第 s 个快照里逻辑寄存器 e 的物理号。
  // =====================================================================
  logic [PHYREG_W-1:0] snapshots [SNAPSHOT_NUM][NUM_ENTRY];

  SnapshotGenerator_4 snapshots_snapshotGen (
    .clock      (clock),
    .reset      (reset),
    .io_enq     (t1_snpt_snptEnq),
    .io_deq     (t1_snpt_snptDeq),
    .io_redirect(t1_redirect),
    // 注意：flushVec 用打一拍的 t1_snpt_flushVec(golden 即如此)，与 enq/deq/redirect 同 T1。
    .io_flushVec_0(t1_snpt_flushVec[0]), .io_flushVec_1(t1_snpt_flushVec[1]),
    .io_flushVec_2(t1_snpt_flushVec[2]), .io_flushVec_3(t1_snpt_flushVec[3]),
    .io_enqData_0 (spec_table[0]),  .io_enqData_1 (spec_table[1]),
    .io_enqData_2 (spec_table[2]),  .io_enqData_3 (spec_table[3]),
    .io_enqData_4 (spec_table[4]),  .io_enqData_5 (spec_table[5]),
    .io_enqData_6 (spec_table[6]),  .io_enqData_7 (spec_table[7]),
    .io_enqData_8 (spec_table[8]),  .io_enqData_9 (spec_table[9]),
    .io_enqData_10(spec_table[10]), .io_enqData_11(spec_table[11]),
    .io_enqData_12(spec_table[12]), .io_enqData_13(spec_table[13]),
    .io_enqData_14(spec_table[14]), .io_enqData_15(spec_table[15]),
    .io_enqData_16(spec_table[16]), .io_enqData_17(spec_table[17]),
    .io_enqData_18(spec_table[18]), .io_enqData_19(spec_table[19]),
    .io_enqData_20(spec_table[20]), .io_enqData_21(spec_table[21]),
    .io_enqData_22(spec_table[22]), .io_enqData_23(spec_table[23]),
    .io_enqData_24(spec_table[24]), .io_enqData_25(spec_table[25]),
    .io_enqData_26(spec_table[26]), .io_enqData_27(spec_table[27]),
    .io_enqData_28(spec_table[28]), .io_enqData_29(spec_table[29]),
    .io_enqData_30(spec_table[30]), .io_enqData_31(spec_table[31]),
    .io_snapshots_0_0 (snapshots[0][0]),  .io_snapshots_0_1 (snapshots[0][1]),
    .io_snapshots_0_2 (snapshots[0][2]),  .io_snapshots_0_3 (snapshots[0][3]),
    .io_snapshots_0_4 (snapshots[0][4]),  .io_snapshots_0_5 (snapshots[0][5]),
    .io_snapshots_0_6 (snapshots[0][6]),  .io_snapshots_0_7 (snapshots[0][7]),
    .io_snapshots_0_8 (snapshots[0][8]),  .io_snapshots_0_9 (snapshots[0][9]),
    .io_snapshots_0_10(snapshots[0][10]), .io_snapshots_0_11(snapshots[0][11]),
    .io_snapshots_0_12(snapshots[0][12]), .io_snapshots_0_13(snapshots[0][13]),
    .io_snapshots_0_14(snapshots[0][14]), .io_snapshots_0_15(snapshots[0][15]),
    .io_snapshots_0_16(snapshots[0][16]), .io_snapshots_0_17(snapshots[0][17]),
    .io_snapshots_0_18(snapshots[0][18]), .io_snapshots_0_19(snapshots[0][19]),
    .io_snapshots_0_20(snapshots[0][20]), .io_snapshots_0_21(snapshots[0][21]),
    .io_snapshots_0_22(snapshots[0][22]), .io_snapshots_0_23(snapshots[0][23]),
    .io_snapshots_0_24(snapshots[0][24]), .io_snapshots_0_25(snapshots[0][25]),
    .io_snapshots_0_26(snapshots[0][26]), .io_snapshots_0_27(snapshots[0][27]),
    .io_snapshots_0_28(snapshots[0][28]), .io_snapshots_0_29(snapshots[0][29]),
    .io_snapshots_0_30(snapshots[0][30]), .io_snapshots_0_31(snapshots[0][31]),
    .io_snapshots_1_0 (snapshots[1][0]),  .io_snapshots_1_1 (snapshots[1][1]),
    .io_snapshots_1_2 (snapshots[1][2]),  .io_snapshots_1_3 (snapshots[1][3]),
    .io_snapshots_1_4 (snapshots[1][4]),  .io_snapshots_1_5 (snapshots[1][5]),
    .io_snapshots_1_6 (snapshots[1][6]),  .io_snapshots_1_7 (snapshots[1][7]),
    .io_snapshots_1_8 (snapshots[1][8]),  .io_snapshots_1_9 (snapshots[1][9]),
    .io_snapshots_1_10(snapshots[1][10]), .io_snapshots_1_11(snapshots[1][11]),
    .io_snapshots_1_12(snapshots[1][12]), .io_snapshots_1_13(snapshots[1][13]),
    .io_snapshots_1_14(snapshots[1][14]), .io_snapshots_1_15(snapshots[1][15]),
    .io_snapshots_1_16(snapshots[1][16]), .io_snapshots_1_17(snapshots[1][17]),
    .io_snapshots_1_18(snapshots[1][18]), .io_snapshots_1_19(snapshots[1][19]),
    .io_snapshots_1_20(snapshots[1][20]), .io_snapshots_1_21(snapshots[1][21]),
    .io_snapshots_1_22(snapshots[1][22]), .io_snapshots_1_23(snapshots[1][23]),
    .io_snapshots_1_24(snapshots[1][24]), .io_snapshots_1_25(snapshots[1][25]),
    .io_snapshots_1_26(snapshots[1][26]), .io_snapshots_1_27(snapshots[1][27]),
    .io_snapshots_1_28(snapshots[1][28]), .io_snapshots_1_29(snapshots[1][29]),
    .io_snapshots_1_30(snapshots[1][30]), .io_snapshots_1_31(snapshots[1][31]),
    .io_snapshots_2_0 (snapshots[2][0]),  .io_snapshots_2_1 (snapshots[2][1]),
    .io_snapshots_2_2 (snapshots[2][2]),  .io_snapshots_2_3 (snapshots[2][3]),
    .io_snapshots_2_4 (snapshots[2][4]),  .io_snapshots_2_5 (snapshots[2][5]),
    .io_snapshots_2_6 (snapshots[2][6]),  .io_snapshots_2_7 (snapshots[2][7]),
    .io_snapshots_2_8 (snapshots[2][8]),  .io_snapshots_2_9 (snapshots[2][9]),
    .io_snapshots_2_10(snapshots[2][10]), .io_snapshots_2_11(snapshots[2][11]),
    .io_snapshots_2_12(snapshots[2][12]), .io_snapshots_2_13(snapshots[2][13]),
    .io_snapshots_2_14(snapshots[2][14]), .io_snapshots_2_15(snapshots[2][15]),
    .io_snapshots_2_16(snapshots[2][16]), .io_snapshots_2_17(snapshots[2][17]),
    .io_snapshots_2_18(snapshots[2][18]), .io_snapshots_2_19(snapshots[2][19]),
    .io_snapshots_2_20(snapshots[2][20]), .io_snapshots_2_21(snapshots[2][21]),
    .io_snapshots_2_22(snapshots[2][22]), .io_snapshots_2_23(snapshots[2][23]),
    .io_snapshots_2_24(snapshots[2][24]), .io_snapshots_2_25(snapshots[2][25]),
    .io_snapshots_2_26(snapshots[2][26]), .io_snapshots_2_27(snapshots[2][27]),
    .io_snapshots_2_28(snapshots[2][28]), .io_snapshots_2_29(snapshots[2][29]),
    .io_snapshots_2_30(snapshots[2][30]), .io_snapshots_2_31(snapshots[2][31]),
    .io_snapshots_3_0 (snapshots[3][0]),  .io_snapshots_3_1 (snapshots[3][1]),
    .io_snapshots_3_2 (snapshots[3][2]),  .io_snapshots_3_3 (snapshots[3][3]),
    .io_snapshots_3_4 (snapshots[3][4]),  .io_snapshots_3_5 (snapshots[3][5]),
    .io_snapshots_3_6 (snapshots[3][6]),  .io_snapshots_3_7 (snapshots[3][7]),
    .io_snapshots_3_8 (snapshots[3][8]),  .io_snapshots_3_9 (snapshots[3][9]),
    .io_snapshots_3_10(snapshots[3][10]), .io_snapshots_3_11(snapshots[3][11]),
    .io_snapshots_3_12(snapshots[3][12]), .io_snapshots_3_13(snapshots[3][13]),
    .io_snapshots_3_14(snapshots[3][14]), .io_snapshots_3_15(snapshots[3][15]),
    .io_snapshots_3_16(snapshots[3][16]), .io_snapshots_3_17(snapshots[3][17]),
    .io_snapshots_3_18(snapshots[3][18]), .io_snapshots_3_19(snapshots[3][19]),
    .io_snapshots_3_20(snapshots[3][20]), .io_snapshots_3_21(snapshots[3][21]),
    .io_snapshots_3_22(snapshots[3][22]), .io_snapshots_3_23(snapshots[3][23]),
    .io_snapshots_3_24(snapshots[3][24]), .io_snapshots_3_25(snapshots[3][25]),
    .io_snapshots_3_26(snapshots[3][26]), .io_snapshots_3_27(snapshots[3][27]),
    .io_snapshots_3_28(snapshots[3][28]), .io_snapshots_3_29(snapshots[3][29]),
    .io_snapshots_3_30(snapshots[3][30]), .io_snapshots_3_31(snapshots[3][31])
  );

  // =====================================================================
  // 3. 读口：同步读 spec_table + 当拍写旁路(highest-port-wins 优先级)
  //    bypass[i][p]：读口 i 命中投机写口 p。hold 时比上拍地址 t1_raddr，否则比当拍地址。
  //    t0_bypass 打一拍 → t1_bypass(redirect 拍清零)，旁路数据取 t1_wSpec。
  // =====================================================================
  // 当拍(T0)旁路命中位
  logic [COMMIT_WIDTH-1:0] t0_bypass [NUM_READ];
  always_comb
    for (int i = 0; i < NUM_READ; i++)
      for (int p = 0; p < COMMIT_WIDTH; p++) begin
        logic match;
        match = io_specWritePorts[p].wen &
                (io_readPorts_in[i].hold ? (io_specWritePorts[p].addr == t1_raddr[i])
                                         : (io_specWritePorts[p].addr == io_readPorts_in[i].addr));
        t0_bypass[i][p] = match;
      end

  // t1_bypass = RegNext(redirect ? 0 : t0_bypass)
  logic [COMMIT_WIDTH-1:0] t1_bypass [NUM_READ];

  // 纯函数(只用参数，不读模块级信号——避免 FM 的 non-local 解释错误)：
  // 从命中位 hit + 各口数据 wdata 里按"高编号优先"选一个(ParallelPriorityMux(reverse))。
  function automatic logic [PHYREG_W-1:0] prio_pick
      (input logic [COMMIT_WIDTH-1:0] hit, input logic [PHYREG_W-1:0] wdata [COMMIT_WIDTH]);
    logic [PHYREG_W-1:0] d;
    begin
      d = '0;
      for (int p = 0; p < COMMIT_WIDTH; p++)
        if (hit[p]) d = wdata[p];  // 顺序遍历，最后命中(最高口)覆盖
      return d;
    end
  endfunction

  // 各投机写口数据(供 prio_pick 取用)
  logic [PHYREG_W-1:0] t1_wSpec_data [COMMIT_WIDTH];
  always_comb for (int p = 0; p < COMMIT_WIDTH; p++) t1_wSpec_data[p] = t1_wSpec[p].data;

  // 读口输出：旁路命中则按高编号优先选写数据，否则同步读 spec_table[t1_raddr]
  always_comb
    for (int i = 0; i < NUM_READ; i++)
      io_readPorts_data[i] = (|t1_bypass[i]) ? prio_pick(t1_bypass[i], t1_wSpec_data)
                                             : spec_table[t1_raddr[i]];

  // =====================================================================
  // 4. 投机写口命中(spec_table 写)：每口 one-hot = wen ? UIntToOH(addr) : 0
  //    spec_hit[e] = 表项 e 被各写口命中的位向量。
  // =====================================================================
  logic [NUM_ENTRY-1:0]    t1_wSpec_oh [COMMIT_WIDTH];
  logic [COMMIT_WIDTH-1:0] spec_hit    [NUM_ENTRY];
  always_comb begin
    for (int p = 0; p < COMMIT_WIDTH; p++)
      t1_wSpec_oh[p] = t1_wSpec[p].wen ? (NUM_ENTRY'(1) << t1_wSpec[p].addr) : '0;
    for (int e = 0; e < NUM_ENTRY; e++)
      for (int p = 0; p < COMMIT_WIDTH; p++)
        spec_hit[e][p] = t1_wSpec_oh[p][e];
  end

  // =====================================================================
  // 5. 体系结构写口(arch_table 写) + old_pdest + need_free
  // =====================================================================
  // arch_table 下一值：默认保持，高编号 arch 写口优先覆盖。
  logic [PHYREG_W-1:0] arch_next [NUM_ENTRY];
  always_comb
    for (int e = 0; e < NUM_ENTRY; e++) begin
      arch_next[e] = arch_table[e];
      for (int p = 0; p < COMMIT_WIDTH; p++)
        if (io_archWritePorts[p].wen && io_archWritePorts[p].addr == ADDR_W'(e))
          arch_next[e] = io_archWritePorts[p].data;
    end

  // old_pdest[i] 组合值：archWrite 口 i 的旧物理号。优先取同拍前序口(0..i-1)中"最靠近 i"
  // 写同地址者的数据(MuxCase take(i).reverse)，否则取 arch_table[addr]；整体 & {8{wen}}。
  logic [PHYREG_W-1:0] old_pdest_next [COMMIT_WIDTH];
  always_comb
    for (int i = 0; i < COMMIT_WIDTH; i++) begin
      logic [PHYREG_W-1:0] base;
      logic                found;
      base  = arch_table[io_archWritePorts[i].addr];
      found = 1'b0;
      for (int j = i-1; j >= 0; j--)
        if (!found && io_archWritePorts[j].wen &&
            io_archWritePorts[j].addr == io_archWritePorts[i].addr) begin
          base  = io_archWritePorts[j].data;
          found = 1'b1;
        end
      old_pdest_next[i] = base & {PHYREG_W{io_archWritePorts[i].wen}};
    end

  // need_free[i] 组合值：旧物理号在 arch_table 中已无人引用，且不与前序口 old_pdest 重复。
  // 注意用【寄存的】old_pdest / arch_table(与 golden 逐拍一致)。
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
  // 6. difftest 真值表：无旁路、直接写(高编号口优先)；basicDebugEn 用。
  // =====================================================================
  logic [PHYREG_W-1:0] difftest_next [NUM_ENTRY];
  always_comb
    for (int e = 0; e < NUM_ENTRY; e++) begin
      difftest_next[e] = difftest_table[e];
      for (int p = 0; p < NUM_DIFF; p++)
        if (io_diffWritePorts[p].wen && io_diffWritePorts[p].addr == ADDR_W'(e))
          difftest_next[e] = io_diffWritePorts[p].data;
    end

  always_comb for (int e = 0; e < NUM_ENTRY; e++) io_diff_rdata[e] = difftest_table[e];

  // =====================================================================
  // 7. 输出连接
  // =====================================================================
  always_comb
    for (int i = 0; i < COMMIT_WIDTH; i++) begin
      io_old_pdest[i] = old_pdest[i];
      io_need_free[i] = need_free[i];
    end

  // =====================================================================
  // 8. 时序更新
  // =====================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int e = 0; e < NUM_ENTRY; e++) begin
        spec_table[e]     <= '0;
        arch_table[e]     <= '0;
        difftest_table[e] <= '0;
      end
      for (int i = 0; i < COMMIT_WIDTH; i++) begin
        old_pdest[i] <= '0;
        need_free[i] <= 1'b0;
      end
    end else begin
      // --- spec_table 下一值 ---
      // 优先级：RegNext(t1_redirect) 整表回退 > 投机写命中 > 保持。
      for (int e = 0; e < NUM_ENTRY; e++) begin
        if (t2_redirect)
          spec_table[e] <= t2_snpt_useSnpt ? snapshots[t2_snpt_snptSelect][e]
                                           : arch_table[e];
        else if (|spec_hit[e])
          spec_table[e] <= prio_pick(spec_hit[e], t1_wSpec_data);
      end

      // --- arch_table 下一值 + old_pdest + need_free(均寄存) ---
      for (int e = 0; e < NUM_ENTRY; e++)
        arch_table[e] <= arch_next[e];
      for (int i = 0; i < COMMIT_WIDTH; i++) begin
        old_pdest[i] <= old_pdest_next[i];
        need_free[i] <= need_free_next[i];
      end

      // --- difftest 真值表 ---
      for (int e = 0; e < NUM_ENTRY; e++)
        difftest_table[e] <= difftest_next[e];
    end
  end

  // --- 带异步复位的打拍级(对应 GatedValidRegNext(.,0) / RegNext(.,0))：
  //     t1_redirect、t1_snpt_*、t2_snpt_* 复位初值 0。 ---
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

  // --- 无复位的随路打拍级(对应 golden 不带 reset 的 always；RegNext 无初值)：
  //     t2_redirect(spec_table_next_REG)、t1_wSpec、t1_bypass、t1_raddr。
  //     t1_wSpec / t1_bypass 在 redirect 拍清零(redirect ? 0 : ...)。 ---
  always_ff @(posedge clock) begin
    t2_redirect <= t1_redirect;

    for (int p = 0; p < COMMIT_WIDTH; p++)
      t1_wSpec[p] <= io_redirect ? '{wen:1'b0, addr:'0, data:'0}
                                 : io_specWritePorts[p];

    for (int i = 0; i < NUM_READ; i++)
      t1_bypass[i] <= io_redirect ? '0 : t0_bypass[i];

    for (int i = 0; i < NUM_READ; i++)
      if (!io_readPorts_in[i].hold)
        t1_raddr[i] <= io_readPorts_in[i].addr;
  end

endmodule
