// =============================================================================
// ExeUnit_int0 学习台 —— golden 与可读重写**双例化对照**
//
//   tb
//    ├── u_gold : ExeUnit      ← G1-canonical/golden-rtl/ExeUnit.sv（firtool 输出）
//    └── u_read : ExeUnit_xs   ← 本目录 ExeUnit_study.sv（手写可读重写）
//
// 同一份激励同时驱动两边，每拍逐位比对**全部 17 组输出端口**。
// 在 Verdi 里把两边的同一根信号拖到一起看：左边 inPipe_2_1，右边 alive_s1，
// 一眼看懂哪个是什么，顺带看出重写有没有偏。
//
//   make          编译 + 跑，产出 novas.fsdb 和 sim.log
//   make verdi    打开 Verdi
//   make sig      产出分组的信号清单 signals.txt（Verdi 里 Restore Signal）
//   详细导读见本目录 README.md
//
// 演示的阶段（波形里看 tb.phase 定位）：
//   1   ALU 单周期（组合，当拍出结果）
//   2   MUL 两级流水（存活链 + 占用链逐级推进）
//   3   BKU 两级流水（走另一条 FU，分发可见）
//   4   连发三种 FU（分发路由 + 输出或归约）
//   51  flush 与发射同拍   → 第 0 级判定掐断
//   52  flush 晚 1 拍      → 第 1 级判定掐断
//   53  flush 晚 2 拍      → ★窗口已过，照常写回（不是 bug，见 README）
//   61  level=0 且 robIdx == flush 点 → 活（level 语义 A/B 之一）
//   62  level=1 且 robIdx == flush 点 → 死（flushItself）
//   63  level=0 且 flush 点更年轻      → 在飞的更老指令不受影响
//   7   ★下游反压 out_ready=0 —— G1 新增的两个 ready 端口在这里才有戏
//   8   ★时钟门控：DFT test-enable 拉高，被门控的 Mul/Bku 时钟恢复自由跑
//   9   ★写回口撞车：或归约的硬前提被打破时会出什么（假指令）
// =============================================================================
`timescale 1ns/1ps

module tb;

  // ---- FuType 独热编码（src/main/scala/xiangshan/backend/fu/FuType.scala 顺序）----
  localparam [34:0] FU_ALU = 35'h40;    // 1<<6
  localparam [34:0] FU_MUL = 35'h80;    // 1<<7
  localparam [34:0] FU_BKU = 35'h400;   // 1<<10

  // ---- 几条具体 opcode（src/main/scala/xiangshan/package.scala）----
  localparam [8:0] OP_ADD   = 9'b0_010_0001;  // ALUOpType.add
  localparam [8:0] OP_SUB   = 9'b0_011_0000;  // ALUOpType.sub
  localparam [8:0] OP_MUL   = 9'b0_0000_0000; // MDUOpType.mul
  localparam [8:0] OP_CLMUL = 9'b0_0000_0000; // BKUOpType.clmul
  localparam [8:0] OP_CLZ   = 9'b0_0000_1000; // BKUOpType.clz

  bit clk = 0, rst = 1;
  int phase = 0;            // ← 波形里用它定位阶段
  string phase_name = "";

  always #5 clk = ~clk;

  // ---------------------------------------------------------------------------
  // 共享激励（两个 DUT 接同一组线）
  // ---------------------------------------------------------------------------
  logic        in_valid, in_rfWen, in_robIdx_flag;
  logic [34:0] in_fuType;
  logic [8:0]  in_fuOpType;
  logic [63:0] in_src0, in_src1;
  logic [7:0]  in_robIdx_value, in_pdest;
  logic        flush_valid, flush_robIdx_flag, flush_level;
  logic [7:0]  flush_robIdx_value;
  logic        out_ready;      // 下游写回口的 ready（真实芯片整数口硬接 1）
  logic        cg_te;          // 两个 ClockGate 的 DFT test-enable

  // perf/seqNum：功能上不参与判断，喂可辨认的常量，方便在波形里追踪它们怎么随
  // uop 走完全程（这也是"perf 只是搭车的观测线"这件事的直观证据）。
  localparam [63:0] PERF_RENAME   = 64'hA1;
  localparam [63:0] PERF_DISPATCH = 64'hA2;
  localparam [63:0] PERF_ENQRS    = 64'hA3;
  localparam [63:0] PERF_SELECT   = 64'hA4;
  localparam [63:0] PERF_ISSUE    = 64'hA5;
  localparam [63:0] PERF_WB       = 64'hA6;
  localparam [63:0] PERF_RUNAHEAD = 64'hA7;
  localparam [63:0] PERF_TLBREQ   = 64'hA8;
  localparam [63:0] PERF_TLBRESP  = 64'hA9;

  // ---------------------------------------------------------------------------
  // 两侧输出（后缀 _g = golden，_r = readable）
  // ---------------------------------------------------------------------------
  wire        g_in_ready,  r_in_ready;
  wire        g_out_valid, r_out_valid;
  wire [63:0] g_data0, r_data0, g_data1, r_data1;
  wire [7:0]  g_pdest, r_pdest;
  wire        g_rob_flag, r_rob_flag;
  wire [7:0]  g_rob_value, r_rob_value;
  wire        g_intWen, r_intWen;
  wire        g_dbg_elim, r_dbg_elim;
  wire [63:0] g_dbg_rename,   r_dbg_rename;
  wire [63:0] g_dbg_dispatch, r_dbg_dispatch;
  wire [63:0] g_dbg_enqrs,    r_dbg_enqrs;
  wire [63:0] g_dbg_select,   r_dbg_select;
  wire [63:0] g_dbg_issue,    r_dbg_issue;
  wire [63:0] g_dbg_wb,       r_dbg_wb;
  wire [63:0] g_dbg_runahead, r_dbg_runahead;
  wire [63:0] g_dbg_tlbreq,   r_dbg_tlbreq;
  wire [63:0] g_dbg_tlbresp,  r_dbg_tlbresp;
  wire [55:0] g_seq,  r_seq;
  wire [7:0]  g_uopidx, r_uopidx;

  // ===========================================================================
  // DUT A：golden（firtool 生成，满是 _GEN_ / _T_ 的那份）
  // ===========================================================================
  ExeUnit u_gold (
    .clock (clk), .reset (rst),
    .io_flush_valid            (flush_valid),
    .io_flush_bits_robIdx_flag (flush_robIdx_flag),
    .io_flush_bits_robIdx_value(flush_robIdx_value),
    .io_flush_bits_level       (flush_level),
    .io_in_ready               (g_in_ready),
    .io_in_valid               (in_valid),
    .io_in_bits_fuType         (in_fuType),
    .io_in_bits_fuOpType       (in_fuOpType),
    .io_in_bits_src_0          (in_src0),
    .io_in_bits_src_1          (in_src1),
    .io_in_bits_robIdx_flag    (in_robIdx_flag),
    .io_in_bits_robIdx_value   (in_robIdx_value),
    .io_in_bits_pdest          (in_pdest),
    .io_in_bits_rfWen          (in_rfWen),
    .io_in_bits_perfDebugInfo_eliminatedMove        (1'b0),
    .io_in_bits_perfDebugInfo_renameTime            (PERF_RENAME),
    .io_in_bits_perfDebugInfo_dispatchTime          (PERF_DISPATCH),
    .io_in_bits_perfDebugInfo_enqRsTime             (PERF_ENQRS),
    .io_in_bits_perfDebugInfo_selectTime            (PERF_SELECT),
    .io_in_bits_perfDebugInfo_issueTime             (PERF_ISSUE),
    .io_in_bits_perfDebugInfo_writebackTime         (PERF_WB),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(PERF_RUNAHEAD),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime       (PERF_TLBREQ),
    .io_in_bits_perfDebugInfo_tlbRespTime           (PERF_TLBRESP),
    .io_in_bits_debug_seqNum_seqNum                 ({48'h0, in_robIdx_value}),
    .io_in_bits_debug_seqNum_uopIdx                 (8'h0),
    .io_out_ready              (out_ready),
    .io_out_valid              (g_out_valid),
    .io_out_bits_data_0        (g_data0),
    .io_out_bits_data_1        (g_data1),
    .io_out_bits_pdest         (g_pdest),
    .io_out_bits_robIdx_flag   (g_rob_flag),
    .io_out_bits_robIdx_value  (g_rob_value),
    .io_out_bits_intWen        (g_intWen),
    .io_out_bits_debugInfo_eliminatedMove        (g_dbg_elim),
    .io_out_bits_debugInfo_renameTime            (g_dbg_rename),
    .io_out_bits_debugInfo_dispatchTime          (g_dbg_dispatch),
    .io_out_bits_debugInfo_enqRsTime             (g_dbg_enqrs),
    .io_out_bits_debugInfo_selectTime            (g_dbg_select),
    .io_out_bits_debugInfo_issueTime             (g_dbg_issue),
    .io_out_bits_debugInfo_writebackTime         (g_dbg_wb),
    .io_out_bits_debugInfo_runahead_checkpoint_id(g_dbg_runahead),
    .io_out_bits_debugInfo_tlbFirstReqTime       (g_dbg_tlbreq),
    .io_out_bits_debugInfo_tlbRespTime           (g_dbg_tlbresp),
    .io_out_bits_debug_seqNum_seqNum             (g_seq),
    .io_out_bits_debug_seqNum_uopIdx             (g_uopidx),
    .cg_bore_cgen   (cg_te),
    .cg_bore_1_cgen (cg_te)
  );

  // ===========================================================================
  // DUT B：可读重写（本目录 ExeUnit_study.sv + Dispatcher_study.sv，
  //        叶子 FU 用 rtl/backend 的可读重写经 derive_ut_impl.py 改名的 *_xs 副本）
  // ===========================================================================
  ExeUnit_xs u_read (
    .clock (clk), .reset (rst),
    .io_flush_valid            (flush_valid),
    .io_flush_bits_robIdx_flag (flush_robIdx_flag),
    .io_flush_bits_robIdx_value(flush_robIdx_value),
    .io_flush_bits_level       (flush_level),
    .io_in_ready               (r_in_ready),
    .io_in_valid               (in_valid),
    .io_in_bits_fuType         (in_fuType),
    .io_in_bits_fuOpType       (in_fuOpType),
    .io_in_bits_src_0          (in_src0),
    .io_in_bits_src_1          (in_src1),
    .io_in_bits_robIdx_flag    (in_robIdx_flag),
    .io_in_bits_robIdx_value   (in_robIdx_value),
    .io_in_bits_pdest          (in_pdest),
    .io_in_bits_rfWen          (in_rfWen),
    .io_in_bits_perfDebugInfo_eliminatedMove        (1'b0),
    .io_in_bits_perfDebugInfo_renameTime            (PERF_RENAME),
    .io_in_bits_perfDebugInfo_dispatchTime          (PERF_DISPATCH),
    .io_in_bits_perfDebugInfo_enqRsTime             (PERF_ENQRS),
    .io_in_bits_perfDebugInfo_selectTime            (PERF_SELECT),
    .io_in_bits_perfDebugInfo_issueTime             (PERF_ISSUE),
    .io_in_bits_perfDebugInfo_writebackTime         (PERF_WB),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(PERF_RUNAHEAD),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime       (PERF_TLBREQ),
    .io_in_bits_perfDebugInfo_tlbRespTime           (PERF_TLBRESP),
    .io_in_bits_debug_seqNum_seqNum                 ({48'h0, in_robIdx_value}),
    .io_in_bits_debug_seqNum_uopIdx                 (8'h0),
    .io_out_ready              (out_ready),
    .io_out_valid              (r_out_valid),
    .io_out_bits_data_0        (r_data0),
    .io_out_bits_data_1        (r_data1),
    .io_out_bits_pdest         (r_pdest),
    .io_out_bits_robIdx_flag   (r_rob_flag),
    .io_out_bits_robIdx_value  (r_rob_value),
    .io_out_bits_intWen        (r_intWen),
    .io_out_bits_debugInfo_eliminatedMove        (r_dbg_elim),
    .io_out_bits_debugInfo_renameTime            (r_dbg_rename),
    .io_out_bits_debugInfo_dispatchTime          (r_dbg_dispatch),
    .io_out_bits_debugInfo_enqRsTime             (r_dbg_enqrs),
    .io_out_bits_debugInfo_selectTime            (r_dbg_select),
    .io_out_bits_debugInfo_issueTime             (r_dbg_issue),
    .io_out_bits_debugInfo_writebackTime         (r_dbg_wb),
    .io_out_bits_debugInfo_runahead_checkpoint_id(r_dbg_runahead),
    .io_out_bits_debugInfo_tlbFirstReqTime       (r_dbg_tlbreq),
    .io_out_bits_debugInfo_tlbRespTime           (r_dbg_tlbresp),
    .io_out_bits_debug_seqNum_seqNum             (r_seq),
    .io_out_bits_debug_seqNum_uopIdx             (r_uopidx),
    .cg_bore_cgen   (cg_te),
    .cg_bore_1_cgen (cg_te)
  );

  // ===========================================================================
  // 逐拍比对器：17 组输出端口，一位不一样就报
  // ---------------------------------------------------------------------------
  // 用 !== 而不是 !=，这样 X/Z 的差异也抓得到（X!==X 为假，所以"两边同样是 X"
  // 不算错——这正是我们要的：只关心两边有没有分叉）。
  // ===========================================================================
  int errors = 0;
  int checked = 0;

  task automatic chk(input string nm, input logic [63:0] gv, input logic [63:0] rv);
    if (gv !== rv) begin
      errors++;
      if (errors <= 40)
        $display("  [MISMATCH t=%0t phase=%0d] %-28s golden=0x%0h  readable=0x%0h",
                 $time, phase, nm, gv, rv);
    end
  endtask

  always @(posedge clk) if (!rst) begin
    checked++;
    chk("io_in_ready",              {63'h0, g_in_ready},  {63'h0, r_in_ready});
    chk("io_out_valid",             {63'h0, g_out_valid}, {63'h0, r_out_valid});
    chk("io_out_bits_data_0",       g_data0,              r_data0);
    chk("io_out_bits_data_1",       g_data1,              r_data1);
    chk("io_out_bits_pdest",        {56'h0, g_pdest},     {56'h0, r_pdest});
    chk("io_out_bits_robIdx_flag",  {63'h0, g_rob_flag},  {63'h0, r_rob_flag});
    chk("io_out_bits_robIdx_value", {56'h0, g_rob_value}, {56'h0, r_rob_value});
    chk("io_out_bits_intWen",       {63'h0, g_intWen},    {63'h0, r_intWen});
    chk("debugInfo_eliminatedMove", {63'h0, g_dbg_elim},  {63'h0, r_dbg_elim});
    chk("debugInfo_renameTime",     g_dbg_rename,         r_dbg_rename);
    chk("debugInfo_dispatchTime",   g_dbg_dispatch,       r_dbg_dispatch);
    chk("debugInfo_enqRsTime",      g_dbg_enqrs,          r_dbg_enqrs);
    chk("debugInfo_selectTime",     g_dbg_select,         r_dbg_select);
    chk("debugInfo_issueTime",      g_dbg_issue,          r_dbg_issue);
    chk("debugInfo_writebackTime",  g_dbg_wb,             r_dbg_wb);
    chk("debugInfo_runahead_ckpt",  g_dbg_runahead,       r_dbg_runahead);
    chk("debugInfo_tlbFirstReq",    g_dbg_tlbreq,         r_dbg_tlbreq);
    chk("debugInfo_tlbResp",        g_dbg_tlbresp,        r_dbg_tlbresp);
    chk("debug_seqNum_seqNum",      {8'h0, g_seq},        {8'h0, r_seq});
    chk("debug_seqNum_uopIdx",      {56'h0, g_uopidx},    {56'h0, r_uopidx});
  end

  // 结果监视：出结果就打一行（两侧分别打，方便一眼看出有没有一侧漏了）
  always @(posedge clk) if (!rst && g_out_valid)
    $display("  [%0t] GOLDEN   写回 robIdx=%0d pdest=%0d data=0x%016h intWen=%b",
             $time, g_rob_value, g_pdest, g_data0, g_intWen);
  always @(posedge clk) if (!rst && r_out_valid)
    $display("  [%0t] READABLE 写回 robIdx=%0d pdest=%0d data=0x%016h intWen=%b",
             $time, r_rob_value, r_pdest, r_data0, r_intWen);

  // ===========================================================================
  // 信号路径自检
  // ---------------------------------------------------------------------------
  // signals.txt / README.md 里列的每一条层次路径，在这里都引用一次。
  // 路径写错、或者将来谁把某个信号改了名，**编译就会直接报错**，
  // 不会让你打开 Verdi 对着一份烂掉的清单发呆。
  // 跑 ./simv +paths 会把这些名字连同当前值打一遍，当"清单速查表"用。
  // ===========================================================================
  task automatic dump_paths();
    $display("\n---- 信号路径自检（左 golden / 右 可读）----");
    $display("  分发命中     : acceptVec=%b%b%b            | hit_bku/mul/alu=%b%b%b",
             u_gold.in1ToN.acceptVec_2, u_gold.in1ToN.acceptVec_1, u_gold.in1ToN.acceptVec_0,
             u_read.u_core.u_disp.u_core.hit_bku,
             u_read.u_core.u_disp.u_core.hit_mul,
             u_read.u_core.u_disp.u_core.hit_alu);
    $display("  分发三路valid: io_out_{0,1,2}_valid=%b%b%b   | disp_valid=%b",
             u_gold.in1ToN.io_out_2_valid, u_gold.in1ToN.io_out_1_valid,
             u_gold.in1ToN.io_out_0_valid, u_read.u_core.disp_valid);
    $display("  三路 ready   : Alu/Mul/Bku in_ready=%b%b%b   | disp_ready=%b",
             u_gold._Bku_io_in_ready, u_gold._Mul_io_in_ready, u_gold._Alu_io_in_ready,
             u_read.u_core.disp_ready);
    $display("  存活链       : inPipe_2_1/_2_2=%b%b          | alive_s1/s2=%b%b  (kill_s0/s1=%b%b)",
             u_gold.inPipe_2_1, u_gold.inPipe_2_2,
             u_read.u_core.alive_s1, u_read.u_core.alive_s2,
             u_read.u_core.kill_s0, u_read.u_core.kill_s1);
    $display("  控制位链     : inPipe_1_1/1_2 rob=%0d/%0d pdest=%0d | ctrl_s1/s2 rob=%0d/%0d pdest=%0d",
             u_gold.inPipe_1_1_robIdx_value, u_gold.inPipe_1_2_robIdx_value,
             u_gold.inPipe_1_2_pdest,
             u_read.u_core.ctrl_s1.robIdx.value, u_read.u_core.ctrl_s2.robIdx.value,
             u_read.u_core.ctrl_s2.pdest);
    $display("  Mul 占用链   : validVecThisFu_1/_2=%b%b       | valid_thisfu_1/_2=%b%b",
             u_gold.Mul.validVecThisFu_1, u_gold.Mul.validVecThisFu_2,
             u_read.u_core.u_mul.u_core.valid_thisfu_1,
             u_read.u_core.u_mul.u_core.valid_thisfu_2);
    $display("  Mul 反压链   : rdyVec_0/_1=%b%b               | rdy_s0/s1=%b%b",
             u_gold.Mul.rdyVec_0, u_gold.Mul.rdyVec_1,
             u_read.u_core.u_mul.u_core.rdy_s0, u_read.u_core.u_mul.u_core.rdy_s1);
    $display("  Bku 占用链   : validVecThisFu_1/_2=%b%b       | valid_thisfu_1/_2=%b%b",
             u_gold.Bku.validVecThisFu_1, u_gold.Bku.validVecThisFu_2,
             u_read.u_core.u_bku.u_core.valid_thisfu_1,
             u_read.u_core.u_bku.u_core.valid_thisfu_2);
    $display("  门控影子(Mul): fuVldVec_1/_2=%b%b fuRdyVec_1=%b | occ_s1/s2=%b%b rdy_s1=%b busy/q=%b%b",
             u_gold.fuVldVec_1, u_gold.fuVldVec_2, u_gold.fuRdyVec_1,
             u_read.u_core.g_gate[0].occ_s1, u_read.u_core.g_gate[0].occ_s2,
             u_read.u_core.g_gate[0].rdy_s1,
             u_read.u_core.g_gate[0].busy,   u_read.u_core.g_gate[0].busy_q);
    $display("  门控影子(Bku): fuVldVec_1_1/_2_1=%b%b          | occ_s1/s2=%b%b",
             u_gold.fuVldVec_1_1, u_gold.fuVldVec_2_1,
             u_read.u_core.g_gate[1].occ_s1, u_read.u_core.g_gate[1].occ_s2);
    $display("  门控使能/时钟: clk_en_1/2=%b%b Q=%b%b           | clk_en_gated=%b fu_clk=%b",
             u_gold.clk_en_1_probe, u_gold.clk_en_2_probe,
             u_gold._ClockGate_Q, u_gold._ClockGate_1_Q,
             u_read.u_core.clk_en_gated, u_read.u_core.fu_clk);
    $display("  各 FU 写回   : Alu/Mul/Bku out_valid=%b%b%b     | fu_valid=%b%b%b",
             u_gold._Alu_io_out_valid, u_gold._Mul_io_out_valid, u_gold._Bku_io_out_valid,
             u_read.u_core.fu_valid[0], u_read.u_core.fu_valid[1], u_read.u_core.fu_valid[2]);
    $display("-------------------------------------------\n");
  endtask

  // ---------------------------------------------------------------------------
  // 激励原语
  // ---------------------------------------------------------------------------
  // 发一条指令（占一拍）；robIdx 递增，便于在波形里区分是哪一条
  task automatic issue(input [34:0] fuType, input [8:0] op,
                       input [63:0] s0, input [63:0] s1, input [7:0] robIdx);
    @(negedge clk);
    in_valid        <= 1'b1;
    in_fuType       <= fuType;
    in_fuOpType     <= op;
    in_src0         <= s0;
    in_src1         <= s1;
    in_robIdx_flag  <= 1'b0;
    in_robIdx_value <= robIdx;
    in_pdest        <= robIdx;          // 让 pdest 跟 robIdx 一样，波形里好认
    in_rfWen        <= 1'b1;
    @(negedge clk);
    in_valid        <= 1'b0;
  endtask

  task automatic idle(input int n);
    @(negedge clk);
    in_valid <= 1'b0;
    repeat (n) @(negedge clk);
  endtask

  // 打一拍 flush：level=0 打比 robIdx 年轻的；level=1 连 robIdx 自己一起打
  task automatic do_flush(input [7:0] robIdx, input bit level);
    @(negedge clk);
    flush_valid        <= 1'b1;
    flush_robIdx_flag  <= 1'b0;
    flush_robIdx_value <= robIdx;
    flush_level        <= level;
    @(negedge clk);
    flush_valid        <= 1'b0;
  endtask

  // 发一条指令，并在其后 delay 拍打 flush —— 用来演示 flush 窗口
  task automatic issue_then_flush(input [34:0] fuType, input [8:0] op,
                                  input [63:0] s0, input [63:0] s1,
                                  input [7:0] robIdx,
                                  input [7:0] flushIdx, input bit level,
                                  input int delay);
    fork
      issue(fuType, op, s0, s1, robIdx);
      begin
        repeat (delay) @(negedge clk);
        do_flush(flushIdx, level);
      end
    join
  endtask

  task automatic set_phase(input int n, input string nm);
    phase = n; phase_name = nm;
    $display("\n===== 阶段 %0d @%0t : %s =====", n, $time, nm);
  endtask

  // ---------------------------------------------------------------------------
  initial begin
    $fsdbDumpfile("novas.fsdb");
    $fsdbDumpvars(0, tb, "+all", "+mda", "+struct");

    in_valid = 0; flush_valid = 0; flush_level = 0;
    in_fuType = 0; in_fuOpType = 0; in_src0 = 0; in_src1 = 0;
    in_robIdx_value = 0; in_pdest = 0; in_rfWen = 0;
    in_robIdx_flag = 0; flush_robIdx_flag = 0; flush_robIdx_value = 0;
    out_ready = 1'b1;     // 与 ExuBlock 里整数写回口一致：硬接 1，永不反压
    // DFT test-enable 默认 **0**（功能模式）。这样被门控的 Mul/Bku 时钟只在有
    // 在飞 uop 时才跳，你能在波形里直接看见时钟门控在工作。
    // 想看"门常开"的样子：跑 ./simv +cg_te=1
    cg_te = 1'b0;
    if ($test$plusargs("cg_te")) cg_te = 1'b1;

    repeat (6) @(posedge clk);
    rst = 0;
    repeat (2) @(posedge clk);

    // 复位刚放开、还没发任何指令时打一遍路径表（也顺带证明两侧都干净地清了 0）
    dump_paths();

    // ---- 阶段 1：ALU 单周期 ----------------------------------------------
    // 看点：in_valid 拉高那拍，io_out_valid 同拍就起来（Alu 是纯组合），data=3+4。
    //       两侧 io_out_valid / data_0 完全重合。
    set_phase(1, "ALU add 单周期：组合出结果，无流水级");
    issue(FU_ALU, OP_ADD, 64'd3, 64'd4, 8'd10);
    idle(4);

    // ---- 阶段 2：MUL 两级流水 --------------------------------------------
    // 看点（拖成一排看）：
    //   golden : in1ToN 的 io_out_1_valid → inPipe_2_1 → inPipe_2_2 → Mul.validVecThisFu_*
    //   可读   : u_disp/u_core/hit_mul   → alive_s1   → alive_s2   → u_mul/u_core/valid_thisfu_*
    set_phase(2, "MUL 两级流水：存活链 alive 与占用链 valid_thisfu 一起逐级推进");
    issue(FU_MUL, OP_MUL, 64'd6, 64'd7, 8'd11);
    idle(6);

    // ---- 阶段 3：BKU 两级流水 --------------------------------------------
    set_phase(3, "BKU clz 两级流水：走另一条 FU，分发只给 Bku 拉 valid");
    issue(FU_BKU, OP_CLZ, 64'h0000_0000_0000_00FF, 64'd0, 8'd12);
    idle(6);

    // ---- 阶段 4：连发三种 FU --------------------------------------------
    // 看点：三条指令在不同 FU 里并行推进；输出是三路的或归约，
    //       因为延迟不同(0/2/2)且 Mul/Bku 不同拍发，它们不会撞在同一拍。
    set_phase(4, "连发 ALU/MUL/BKU：分发路由 + 输出或归约");
    issue(FU_ALU, OP_SUB, 64'd100, 64'd58, 8'd20);
    issue(FU_MUL, OP_MUL, 64'd9,   64'd9,  8'd21);
    issue(FU_BKU, OP_CLMUL, 64'h3, 64'h5,  8'd22);
    idle(8);

    // ---- 阶段 5：★flush 窗口★ 三种到达时机 --------------------------------
    // ExeUnit 只有 alive_pipe[0] / alive_pipe[1] 两个 flush 判定点（golden 的
    // inPipe_2_1 / inPipe_2_2），所以 flush 必须在「发射当拍」或「发射后 1 拍」
    // 到达才掐得掉。更晚到达时结果照常写回，由下游 ROB 按 robIdx 丢弃。
    set_phase(51, "flush 与发射同拍：第 0 级判定命中，alive 链从不置起 → 不写回");
    issue_then_flush(FU_MUL, OP_MUL, 64'd12, 64'd12, 8'd30, 8'd29, 1'b0, 0);
    idle(8);

    set_phase(52, "flush 晚 1 拍：指令已在第 1 级，第 1 级判定命中 → 不写回");
    issue_then_flush(FU_MUL, OP_MUL, 64'd13, 64'd13, 8'd31, 8'd29, 1'b0, 1);
    idle(8);

    set_phase(53, "flush 晚 2 拍：★窗口已过，14x14=0xC4 照常写回（交给 ROB 丢）");
    issue_then_flush(FU_MUL, OP_MUL, 64'd14, 64'd14, 8'd32, 8'd29, 1'b0, 2);
    idle(8);

    // ---- 阶段 6：level 的语义 —— 干净的 A/B 对照 --------------------------
    // need_flush = flush.valid & ( (level & robIdx==flush.robIdx) | robIdx 比 flush 更年轻 )
    // 所以「robIdx 恰好等于 flush 点」这一条指令，就是区分 level 的那把尺子：
    //   level=0 → 不等于就不杀、也不比自己年轻 → 活；
    //   level=1 → 等于也杀（flushItself，异常/fence 走这条） → 死。
    // 两次都用同一条 Mul、同一个 robIdx、flush 都在发射当拍到，只改 level。
    set_phase(61, "flush level=0，robIdx 与 flush 点相等 → 不杀，正常写回 6x6=0x24");
    issue_then_flush(FU_MUL, OP_MUL, 64'd6, 64'd6, 8'd40, 8'd40, 1'b0, 0);
    idle(8);

    set_phase(62, "flush level=1，同样相等 → 连自己一起杀，不写回");
    issue_then_flush(FU_MUL, OP_MUL, 64'd6, 64'd6, 8'd41, 8'd41, 1'b1, 0);
    idle(8);

    // 再补一条：更**老**的指令在 level=0 下不受年轻 flush 点影响
    set_phase(63, "flush level=0 指向更年轻的 robIdx=45 → 在飞的 42 更老，活着写回 7x7=0x31");
    issue_then_flush(FU_MUL, OP_MUL, 64'd7, 64'd7, 8'd42, 8'd45, 1'b0, 0);
    idle(8);

    // ---- 阶段 7：★下游反压 —— G1 相对 G0 新增的两个 ready 端口 -------------
    // G0 的 ExeUnit 根本没有 io_in_ready / io_out_ready 这两个端口；G1 把 FU 的
    // 握手上翻到了父层。把 out_ready 拉低，能看到：
    //   · golden fuRdyVec_1 / 可读 g_gate[0].rdy_s1 掉下来；
    //   · Mul 内部 rdyVec_0 掉下来 → 一路传到 io_in_ready（分发器的与归约）；
    //   · ★但 valid 链照旧往前走！ 见 xs_MulUnit_core 第 1 节那段注释：
    //     Chisel 的 pipelineReg() 把 validVec 的推进写在 ready 判断之外，
    //     只有 payload 在 when 里面。结果是 valid 与 payload 脱节，这一拍的写回
    //     被直接丢掉。两侧**一致地**复现这个行为（bug-for-bug）。
    // 真实芯片里整数写回口 out_ready 恒 1，这条路径不可达，所以它不是活 bug。
    set_phase(7, "下游反压 out_ready=0：ready 链塌下来，但 valid 链照走（golden 的已知脱节）");
    @(negedge clk); out_ready <= 1'b0;
    issue(FU_MUL, OP_MUL, 64'd3, 64'd3, 8'd50);
    idle(6);
    @(negedge clk); out_ready <= 1'b1;
    idle(4);
    // 反压解除后再发一条，确认两侧恢复一致
    issue(FU_MUL, OP_MUL, 64'd4, 64'd4, 8'd51);
    idle(8);

    // ---- 阶段 8：★时钟门控 -----------------------------------------------
    // 前面所有阶段 cg_te=0（功能模式）：Verdi 里看 u_gold/_ClockGate_Q 与
    // u_read/u_core/fu_clk[0]，只有 clk_en 为高的那几拍才跳。
    // 这里把 test-enable 拉高，门常开，时钟恢复自由跑 —— DFT 扫描链要的就是这个。
    set_phase(8, "cg_te=1：ClockGate 常开，被门控的 Mul/Bku 时钟恢复自由跑");
    @(negedge clk); cg_te <= 1'b1;
    idle(6);
    issue(FU_MUL, OP_MUL, 64'd2, 64'd2, 8'd60);
    idle(8);
    @(negedge clk); cg_te <= 1'b0;
    idle(6);

    // ---- 阶段 9：★写回口撞车 —— ExeUnit 自己不解决的那个问题 --------------
    // §4 的或归约有一条硬前提："同一拍至多一个 FU 写回"。这里故意打破它：
    //   cycle N   发 Mul(robIdx=70)，2 拍后出结果；
    //   cycle N+2 发 Alu(robIdx=71)，0 拍，当拍出结果 —— 正好撞在同一拍。
    // 后果（两侧一模一样地错）：或归约把两条指令搅在一起
    //   data   = 8*8 | (2+3) = 0x40 | 0x05 = 0x45
    //   robIdx = 70 | 71 = 71        pdest 同理
    // 也就是说写回口上出现了一条**根本不存在的指令**。
    // golden 在这里放了 assert(popcount<=1)（被 +define+SYNTHESIS 关掉了），
    // 说明设计者知道这是前提而不是保证。真正防撞的是发射侧的
    // WbFuBusyTable —— 发射队列按各 FU 的固定延迟预定写回时隙，撞车的组合
    // 压根不会被发出来。ExeUnit 只负责在被违反时炸出来。
    //
    // ★ 顺带一提：本目录上一版 tb 的"阶段 6"就是无意中撞了这一下，
    //   打印出 robIdx=41 data=0x1b，被当成"41 存活"读了 —— 其实 0x1b = 25|2，
    //   是 Mul 的 25 和 Alu 的 2 或在一起。看波形时务必分清"或归约的产物"
    //   和"某一条指令的结果"。
    set_phase(9, "★故意撞车：Mul(N) 与 Alu(N+2) 同拍写回，或归约产生假指令 0x45");
    issue(FU_MUL, OP_MUL, 64'd8, 64'd8, 8'd70);
    issue(FU_ALU, OP_ADD, 64'd2, 64'd3, 8'd71);
    idle(8);

    set_phase(99, "结束");
    repeat (4) @(posedge clk);

    $display("\n================ 双例化比对结果 ================");
    $display("  比对拍数 : %0d", checked);
    $display("  端口组数 : 20（golden ExeUnit 的全部输出端口）");
    $display("  失配次数 : %0d", errors);
    if (errors == 0) begin
      $display("  ==> TEST PASSED —— golden 与可读重写逐拍逐位一致");
    end else begin
      $display("  ==> TEST FAILED —— 有 %0d 次失配（上面最多列了 40 条）", errors);
    end
    $display("================================================");
    $display("\n波形已写入 novas.fsdb —— 用 make verdi 打开，信号清单见 signals.txt / README.md");
    $finish;
  end

endmodule
