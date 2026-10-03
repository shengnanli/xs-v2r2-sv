// =============================================================================
// tb —— VIDiv（向量整数除法 FU 外壳）UT
//
// golden VIDiv 与重写 VIDiv_xs（整棵子树都是重写件）双例化：
//   (1) 逐拍对拍：in_ready / out_valid 两侧相等；out_valid 时全部出口（128 位写回数据、
//       robIdx/pdest/vecWen/v0Wen、调试信息）全位相等；
//   (2) 每次出口握手对照独立 oracle：
//       · 写回数据按 SEW 逐元素算：元素 i（全局下标 idx = vuopIdx[2:0]*每寄存器元素数 + i）
//         的新值 = RISC-V 除法语义的商（fuOpType[1]=1）或余数，fuOpType[0]=有符号；
//         再按 RVV 规则合并：vl=0 → 整个 vd 取旧值；vstart>=vl → 旧值；idx<vstart → 旧值；
//         idx>=vl → vta ? 全 1 : 旧值；被掩掉（vm=0 且 v0[idx]=0）→ vma ? 全 1 : 旧值；否则新值；
//       · robIdx/pdest/vecWen/v0Wen/调试信息 = 发射时那条 uop 的值。
//       oracle 不看 golden。窄化/掩码目的（isNarrow/isDstMask）、非除法 opType、超 VLMAX 的 vl
//       只做对拍（各约 10%），不进 oracle。
// 激励：sew/vm/vta/vma/vuopIdx 随机，vl 在 [0, VLMAX] 内偏向边界，vstart 30% 非零；元素从角落值表抽
//   （0、±1、最大/最小、2 的幂、小数、前导零随机），另有向量含最小值 / -1；握手后入口立刻换垃圾；
//   忙时随机拉 in_valid（应被忽略）；out_ready 随机反压；忙时低概率冲刷（robIdx/level 随机，
//   tb 用独立的 RobPtr 比较模型判定这条是否被冲掉）。
// 判据：errors=0、完成 >= 3000 条且 oracle 检查过的每档 sew >= 300 条、被冲掉与未冲掉的冲刷都出现过。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0; always #5 clk = ~clk;
  logic reset;
  logic io_flush_valid;
  logic io_flush_bits_robIdx_flag;
  logic [7:0] io_flush_bits_robIdx_value;
  logic io_flush_bits_level;
  logic io_in_valid;
  logic [8:0] io_in_bits_ctrl_fuOpType;
  logic io_in_bits_ctrl_robIdx_flag;
  logic [7:0] io_in_bits_ctrl_robIdx_value;
  logic [7:0] io_in_bits_ctrl_pdest;
  logic io_in_bits_ctrl_vecWen;
  logic io_in_bits_ctrl_v0Wen;
  logic io_in_bits_ctrl_vpu_vma;
  logic io_in_bits_ctrl_vpu_vta;
  logic [1:0] io_in_bits_ctrl_vpu_vsew;
  logic io_in_bits_ctrl_vpu_vm;
  logic [7:0] io_in_bits_ctrl_vpu_vstart;
  logic [6:0] io_in_bits_ctrl_vpu_vuopIdx;
  logic io_in_bits_ctrl_vpu_isNarrow;
  logic io_in_bits_ctrl_vpu_isDstMask;
  logic [7:0] io_in_bits_data_src_4;
  logic [127:0] io_in_bits_data_src_3;
  logic [127:0] io_in_bits_data_src_2;
  logic [127:0] io_in_bits_data_src_1;
  logic [127:0] io_in_bits_data_src_0;
  logic io_in_bits_perfDebugInfo_eliminatedMove;
  logic [63:0] io_in_bits_perfDebugInfo_renameTime;
  logic [63:0] io_in_bits_perfDebugInfo_dispatchTime;
  logic [63:0] io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] io_in_bits_perfDebugInfo_issueTime;
  logic [63:0] io_in_bits_perfDebugInfo_writebackTime;
  logic [63:0] io_in_bits_perfDebugInfo_runahead_checkpoint_id;
  logic [63:0] io_in_bits_perfDebugInfo_tlbFirstReqTime;
  logic [63:0] io_in_bits_perfDebugInfo_tlbRespTime;
  logic [55:0] io_in_bits_debug_seqNum_seqNum;
  logic [7:0] io_in_bits_debug_seqNum_uopIdx;
  logic io_out_ready;
  wire [789:0] g_out, i_out;

  VIDiv u_g (
    .clock(clk), .reset(reset),
    .io_in_ready(g_out[0 +: 1]),
    .io_out_valid(g_out[1 +: 1]),
    .io_out_bits_ctrl_robIdx_flag(g_out[2 +: 1]),
    .io_out_bits_ctrl_robIdx_value(g_out[3 +: 8]),
    .io_out_bits_ctrl_pdest(g_out[11 +: 8]),
    .io_out_bits_ctrl_vecWen(g_out[19 +: 1]),
    .io_out_bits_ctrl_v0Wen(g_out[20 +: 1]),
    .io_out_bits_res_data(g_out[21 +: 128]),
    .io_out_bits_perfDebugInfo_eliminatedMove(g_out[149 +: 1]),
    .io_out_bits_perfDebugInfo_renameTime(g_out[150 +: 64]),
    .io_out_bits_perfDebugInfo_dispatchTime(g_out[214 +: 64]),
    .io_out_bits_perfDebugInfo_enqRsTime(g_out[278 +: 64]),
    .io_out_bits_perfDebugInfo_selectTime(g_out[342 +: 64]),
    .io_out_bits_perfDebugInfo_issueTime(g_out[406 +: 64]),
    .io_out_bits_perfDebugInfo_writebackTime(g_out[470 +: 64]),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(g_out[534 +: 64]),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(g_out[598 +: 64]),
    .io_out_bits_perfDebugInfo_tlbRespTime(g_out[662 +: 64]),
    .io_out_bits_debug_seqNum_seqNum(g_out[726 +: 56]),
    .io_out_bits_debug_seqNum_uopIdx(g_out[782 +: 8]),
    .*);
  VIDiv_xs u_i (
    .clock(clk), .reset(reset),
    .io_in_ready(i_out[0 +: 1]),
    .io_out_valid(i_out[1 +: 1]),
    .io_out_bits_ctrl_robIdx_flag(i_out[2 +: 1]),
    .io_out_bits_ctrl_robIdx_value(i_out[3 +: 8]),
    .io_out_bits_ctrl_pdest(i_out[11 +: 8]),
    .io_out_bits_ctrl_vecWen(i_out[19 +: 1]),
    .io_out_bits_ctrl_v0Wen(i_out[20 +: 1]),
    .io_out_bits_res_data(i_out[21 +: 128]),
    .io_out_bits_perfDebugInfo_eliminatedMove(i_out[149 +: 1]),
    .io_out_bits_perfDebugInfo_renameTime(i_out[150 +: 64]),
    .io_out_bits_perfDebugInfo_dispatchTime(i_out[214 +: 64]),
    .io_out_bits_perfDebugInfo_enqRsTime(i_out[278 +: 64]),
    .io_out_bits_perfDebugInfo_selectTime(i_out[342 +: 64]),
    .io_out_bits_perfDebugInfo_issueTime(i_out[406 +: 64]),
    .io_out_bits_perfDebugInfo_writebackTime(i_out[470 +: 64]),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(i_out[534 +: 64]),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(i_out[598 +: 64]),
    .io_out_bits_perfDebugInfo_tlbRespTime(i_out[662 +: 64]),
    .io_out_bits_debug_seqNum_seqNum(i_out[726 +: 56]),
    .io_out_bits_debug_seqNum_uopIdx(i_out[782 +: 8]),
    .*);

  longint errors = 0, cmp_checks = 0, elem_checks = 0, ops_started = 0, ops_done = 0;
  longint ops_flushed = 0, flush_miss = 0, oracle_ops = 0;
  longint by_sew [4] = '{0, 0, 0, 0};
  longint c_prestart = 0, c_tail_agn = 0, c_tail_und = 0, c_mask_agn = 0, c_mask_und = 0, c_active = 0,
          c_vl0 = 0, c_vstart_ge_vl = 0, c_dzero = 0, c_ovf = 0, c_dual_only = 0, c_backpressure = 0;

  // ---------------- 独立 oracle ----------------
  function automatic logic [63:0] nmask(int n);
    return (n >= 64) ? 64'hFFFF_FFFF_FFFF_FFFF : ((64'd1 << n) - 64'd1);
  endfunction
  function automatic longint sext(logic [63:0] v, int n);
    logic [63:0] s = v << (64 - n);
    return longint'($signed(s)) >>> (64 - n);
  endfunction
  task automatic div_oracle(input int n, input bit sgn, input logic [63:0] x, input logic [63:0] d,
                            output logic [63:0] q, output logic [63:0] r);
    logic [63:0] m = nmask(n);
    logic [63:0] xm = x & m, dm = d & m;
    if (dm == 0) begin q = m; r = xm; end
    else if (!sgn) begin q = xm / dm; r = xm % dm; end
    else begin
      longint sx = sext(xm, n), sd = sext(dm, n);
      longint smin = (n >= 64) ? 64'sh8000_0000_0000_0000 : -(longint'(1) << (n - 1));
      if (sx == smin && sd == -1) begin q = xm; r = 0; end
      else begin q = 64'(sx / sd) & m; r = 64'(sx % sd) & m; end
    end
  endtask
  function automatic logic [63:0] corner(int n);
    logic [63:0] m = nmask(n), v;
    case ($urandom_range(0, 13))
      0: v = 0;  1: v = 1;  2: v = m;  3: v = 64'd1 << (n - 1);  4: v = (64'd1 << (n - 1)) - 1;
      5: v = 64'd1 << $urandom_range(0, n - 1);  6: v = $urandom_range(0, 15);
      7: v = m - $urandom_range(0, 15);  8: v = {$urandom, $urandom} >> $urandom_range(0, 63);
      9: v = 3;
      default: v = {$urandom, $urandom};
    endcase
    return v & m;
  endfunction
  // RobPtr.needFlush 的独立模型：比冲刷点年轻（环形指针），或 level=1 且相等
  function automatic bit need_flush_model(bit tf, logic [7:0] tv, bit ff, logic [7:0] fv, bit lvl);
    bit after = (tf != ff) ? (tv <= fv) : (tv > fv);
    return after || (lvl && tf == ff && tv == fv);
  endfunction

  // ---------------- 当前操作的快照 ----------------
  logic [8:0]   op_fu;  logic op_rf; logic [7:0] op_rv, op_pdest; logic op_vecWen, op_v0Wen;
  logic         op_vma, op_vta, op_vm, op_narrow, op_dstmask;  logic [1:0] op_sew;
  logic [7:0]   op_vstart, op_vl;  logic [6:0] op_vuop;
  logic [127:0] op_v0, op_old, op_vs2, op_vs1;
  logic [63:0]  op_dbg [10];  logic op_elim; logic [55:0] op_seq; logic [7:0] op_suop;
  bit           op_oracle;
  bit           busy = 0;
  int           cyc = 0;

  task automatic randomize_inputs();
    io_flush_valid = 0; io_flush_bits_robIdx_flag = $urandom; io_flush_bits_robIdx_value = $urandom;
    io_flush_bits_level = $urandom;
    io_in_bits_ctrl_fuOpType = $urandom; io_in_bits_ctrl_robIdx_flag = $urandom;
    io_in_bits_ctrl_robIdx_value = $urandom; io_in_bits_ctrl_pdest = $urandom;
    io_in_bits_ctrl_vecWen = $urandom; io_in_bits_ctrl_v0Wen = $urandom;
    io_in_bits_ctrl_vpu_vma = $urandom; io_in_bits_ctrl_vpu_vta = $urandom;
    io_in_bits_ctrl_vpu_vsew = $urandom; io_in_bits_ctrl_vpu_vm = $urandom;
    io_in_bits_ctrl_vpu_vstart = $urandom; io_in_bits_ctrl_vpu_vuopIdx = $urandom;
    io_in_bits_ctrl_vpu_isNarrow = $urandom; io_in_bits_ctrl_vpu_isDstMask = $urandom;
    io_in_bits_data_src_4 = $urandom;
    io_in_bits_data_src_3 = {$urandom, $urandom, $urandom, $urandom};
    io_in_bits_data_src_2 = {$urandom, $urandom, $urandom, $urandom};
    io_in_bits_data_src_1 = {$urandom, $urandom, $urandom, $urandom};
    io_in_bits_data_src_0 = {$urandom, $urandom, $urandom, $urandom};
    io_in_bits_perfDebugInfo_eliminatedMove = $urandom;
    io_in_bits_perfDebugInfo_renameTime = {$urandom, $urandom};
    io_in_bits_perfDebugInfo_dispatchTime = {$urandom, $urandom};
    io_in_bits_perfDebugInfo_enqRsTime = {$urandom, $urandom};
    io_in_bits_perfDebugInfo_selectTime = {$urandom, $urandom};
    io_in_bits_perfDebugInfo_issueTime = {$urandom, $urandom};
    io_in_bits_perfDebugInfo_writebackTime = {$urandom, $urandom};
    io_in_bits_perfDebugInfo_runahead_checkpoint_id = {$urandom, $urandom};
    io_in_bits_perfDebugInfo_tlbFirstReqTime = {$urandom, $urandom};
    io_in_bits_perfDebugInfo_tlbRespTime = {$urandom, $urandom};
    io_in_bits_debug_seqNum_seqNum = {$urandom, $urandom};
    io_in_bits_debug_seqNum_uopIdx = $urandom;
  endtask

  task automatic start_op();
    int n, vlmax;
    randomize_inputs();
    op_oracle = 1;
    op_sew = $urandom; n = 8 << op_sew; vlmax = 128 >> op_sew;
    op_fu = 9'($urandom_range(0, 3));
    if ($urandom_range(0, 19) == 0) begin op_fu = $urandom; op_oracle = 0; end
    if ($urandom_range(0, 39) == 0) begin op_fu = ($urandom_range(0, 1)) ? 9'h084 : 9'h086; op_oracle = 0; end
    op_narrow = 0; op_dstmask = 0;
    if ($urandom_range(0, 19) == 0) begin op_narrow = $urandom; op_dstmask = $urandom; if (op_narrow | op_dstmask) op_oracle = 0; end
    op_vm = $urandom; op_vma = $urandom; op_vta = $urandom; op_vuop = $urandom;
    case ($urandom_range(0, 5))
      0: op_vl = 0;
      1: op_vl = vlmax;
      2: op_vl = 8'((op_vuop[2:0] + 1) * (16 >> op_sew)) - 8'($urandom_range(0, 1));
      default: op_vl = $urandom_range(0, vlmax);
    endcase
    if ($urandom_range(0, 19) == 0) begin op_vl = $urandom; if (op_vl > vlmax) op_oracle = 0; end
    op_vstart = ($urandom_range(0, 9) < 7) ? 8'd0 : 8'($urandom_range(0, vlmax));
    op_v0 = {$urandom, $urandom, $urandom, $urandom};
    if ($urandom_range(0, 3) == 0) op_v0 = '1;
    op_old = {$urandom, $urandom, $urandom, $urandom};
    for (int e = 0; e < 128 / n; e++) begin
      logic [63:0] x = corner(n), d = corner(n);
      if (op_fu[0] && $urandom_range(0, 24) == 0) begin x = 64'd1 << (n - 1); d = nmask(n); end
      for (int b = 0; b < n; b++) begin op_vs2[n*e + b] = x[b]; op_vs1[n*e + b] = d[b]; end
    end
    op_rf = $urandom; op_rv = $urandom; op_pdest = $urandom; op_vecWen = $urandom; op_v0Wen = $urandom;
    io_in_bits_ctrl_fuOpType = op_fu; io_in_bits_ctrl_robIdx_flag = op_rf;
    io_in_bits_ctrl_robIdx_value = op_rv; io_in_bits_ctrl_pdest = op_pdest;
    io_in_bits_ctrl_vecWen = op_vecWen; io_in_bits_ctrl_v0Wen = op_v0Wen;
    io_in_bits_ctrl_vpu_vma = op_vma; io_in_bits_ctrl_vpu_vta = op_vta; io_in_bits_ctrl_vpu_vsew = op_sew;
    io_in_bits_ctrl_vpu_vm = op_vm; io_in_bits_ctrl_vpu_vstart = op_vstart;
    io_in_bits_ctrl_vpu_vuopIdx = op_vuop; io_in_bits_ctrl_vpu_isNarrow = op_narrow;
    io_in_bits_ctrl_vpu_isDstMask = op_dstmask;
    io_in_bits_data_src_4 = op_vl; io_in_bits_data_src_3 = op_v0; io_in_bits_data_src_2 = op_old;
    io_in_bits_data_src_1 = op_vs2; io_in_bits_data_src_0 = op_vs1;
    op_elim = io_in_bits_perfDebugInfo_eliminatedMove;
    op_dbg[0] = io_in_bits_perfDebugInfo_renameTime;    op_dbg[1] = io_in_bits_perfDebugInfo_dispatchTime;
    op_dbg[2] = io_in_bits_perfDebugInfo_enqRsTime;     op_dbg[3] = io_in_bits_perfDebugInfo_selectTime;
    op_dbg[4] = io_in_bits_perfDebugInfo_issueTime;     op_dbg[5] = io_in_bits_perfDebugInfo_writebackTime;
    op_dbg[6] = io_in_bits_perfDebugInfo_runahead_checkpoint_id;
    op_dbg[7] = io_in_bits_perfDebugInfo_tlbFirstReqTime; op_dbg[8] = io_in_bits_perfDebugInfo_tlbRespTime;
    op_seq = io_in_bits_debug_seqNum_seqNum; op_suop = io_in_bits_debug_seqNum_uopIdx;
    io_in_valid = 1;
    busy = 1;
    ops_started++;
  endtask

  task automatic report_err(input string what);
    errors++;
    if (errors <= 10) $display("ORACLE MISMATCH cyc=%0d %s (sew=%0d fu=%h vl=%0d vstart=%0d vm=%b vta=%b vma=%b vuop=%0d)",
                               cyc, what, op_sew, op_fu, op_vl, op_vstart, op_vm, op_vta, op_vma, op_vuop);
  endtask

  task automatic check_result();
    int n = 8 << op_sew, epr = 128 / (8 << op_sew);
    logic [127:0] exp = op_old;
    logic [127:0] got = g_out[21 +: 128];
    // 透传字段
    if (g_out[2 +: 1] !== op_rf || g_out[3 +: 8] !== op_rv ||
        g_out[11 +: 8] !== op_pdest || g_out[19 +: 1] !== op_vecWen ||
        g_out[20 +: 1] !== op_v0Wen ||
        g_out[149 +: 1] !== op_elim ||
        g_out[150 +: 64] !== op_dbg[0] ||
        g_out[662 +: 64] !== op_dbg[8] ||
        g_out[726 +: 56] !== op_seq ||
        g_out[782 +: 8] !== op_suop)
      report_err("passthrough");
    ops_done++;
    if (!op_oracle) begin c_dual_only++; return; end
    oracle_ops++;
    by_sew[op_sew]++;
    if (op_vl == 0) c_vl0++;
    else if (op_vstart >= op_vl) c_vstart_ge_vl++;
    for (int e = 0; e < epr; e++) begin
      int idx = int'(op_vuop[2:0]) * epr + e;
      logic [63:0] x = '0, d = '0, q, r, res, old = '0, ones = nmask(n), want, gv = '0;
      bit m = op_vm ? 1'b1 : op_v0[idx];
      for (int b = 0; b < n; b++) begin
        x[b] = op_vs2[n*e + b]; d[b] = op_vs1[n*e + b]; old[b] = op_old[n*e + b]; gv[b] = got[n*e + b];
      end
      div_oracle(n, op_fu[0], x, d, q, r);
      res = op_fu[1] ? q : r;
      if (d == 0) c_dzero++;
      if (op_fu[0] && x == (64'd1 << (n - 1)) && d == ones) c_ovf++;
      if (op_vl == 0 || op_vstart >= op_vl) want = old;
      else if (idx < op_vstart)              begin want = old; c_prestart++; end
      else if (idx >= op_vl)                 begin want = op_vta ? ones : old; if (op_vta) c_tail_agn++; else c_tail_und++; end
      else if (!m)                           begin want = op_vma ? ones : old; if (op_vma) c_mask_agn++; else c_mask_und++; end
      else                                   begin want = res; c_active++; end
      elem_checks++;
      if (gv !== want) begin
        report_err($sformatf("elem %0d idx %0d x=%h d=%h got=%h want=%h", e, idx, x, d, gv, want));
      end
    end
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    reset = 1; io_in_valid = 0; io_out_ready = 0; randomize_inputs();
    repeat (4) @(negedge clk);
    reset = 0;
    for (int unsigned c = 0; c < NCYCLES; c++) begin
      @(negedge clk);
      cyc++;
      cmp_checks++;
      if (g_out[0 +: 1] !== i_out[0 +: 1] || g_out[1 +: 1] !== i_out[1 +: 1] ||
          (g_out[1 +: 1] && g_out !== i_out)) begin
        errors++;
        if (errors <= 10) $display("DUAL MISMATCH cyc=%0d g=%h i=%h", cyc, g_out, i_out);
      end
      // 上一拍的一拍脉冲撤掉；握手之后入口换垃圾
      if (io_in_valid || io_flush_valid) randomize_inputs();
      io_in_valid = 0;
      // 出口握手：先抽本拍驱动的 ready，再判
      io_out_ready = ($urandom_range(0, 9) < 6);
      if (g_out[1 +: 1] && io_out_ready && busy) begin
        check_result();
        busy = 0;
      end else if (g_out[1 +: 1] && !io_out_ready) c_backpressure++;
      if (busy && !(g_out[1 +: 1] && io_out_ready) && $urandom_range(0, 399) == 0) begin
        io_flush_valid = 1;
        // 一半对准本条（相等/更老），一半随机
        if ($urandom_range(0, 1)) begin
          io_flush_bits_robIdx_flag = op_rf; io_flush_bits_robIdx_value = op_rv - $urandom_range(0, 2);
        end
        if (need_flush_model(op_rf, op_rv, io_flush_bits_robIdx_flag, io_flush_bits_robIdx_value,
                             io_flush_bits_level)) begin
          busy = 0; ops_flushed++;
        end else flush_miss++;
      end else if (!busy && g_out[0 +: 1]) begin
        if ($urandom_range(0, 9) < 8) start_op();
      end else if (busy && $urandom_range(0, 9) == 0) begin
        io_in_valid = 1;         // in_ready=0，应被忽略
      end
    end
    @(negedge clk);
    $display("VIDiv: cmp_checks=%0d oracle_ops=%0d elem_checks=%0d errors=%0d | started=%0d done=%0d flushed=%0d flush_miss=%0d dual_only=%0d",
             cmp_checks, oracle_ops, elem_checks, errors, ops_started, ops_done, ops_flushed, flush_miss, c_dual_only);
    $display("cover: sew0=%0d sew1=%0d sew2=%0d sew3=%0d vl0=%0d vstart>=vl=%0d prestart=%0d tail_agn=%0d tail_und=%0d mask_agn=%0d mask_und=%0d active=%0d dzero=%0d ovf=%0d backpressure=%0d",
             by_sew[0], by_sew[1], by_sew[2], by_sew[3], c_vl0, c_vstart_ge_vl, c_prestart, c_tail_agn, c_tail_und,
             c_mask_agn, c_mask_und, c_active, c_dzero, c_ovf, c_backpressure);
    if (errors == 0 && ops_done >= 3000 && by_sew[0] >= 300 && by_sew[1] >= 300 && by_sew[2] >= 300 &&
        by_sew[3] >= 300 && ops_flushed > 0 && flush_miss > 0)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
