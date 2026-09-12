// FCVT UT —— golden FCVT 与重写 FCVT_xs 双例化逐拍全输出比对。
// 被测：浮点格式与整浮转换（LAT=2）。端口表按 G1 golden 重新生成（G1 新增了 io_in_ready /
//   io_out_ready 握手、perfDebugInfo 扩到 10 字段、debug.seqNum）。
// 激励 = 定向浮点边界池（零/±Inf/qNaN/sNaN/非规格化/最大最小规格化/近 1.0）
//   × 全部 fmt 与舍入模式 × 故意不 NaN-box 的窄浮点 × 随机反压。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0;
  int errors = 0, checks = 0;
  int unsigned cyc = 0;
  logic reset;
  always #5 clk = ~clk;

  logic io_in_valid;
  logic [8:0] io_in_bits_ctrl_fuOpType;
  logic [1:0] io_in_bits_ctrl_fpu_fmt;
  logic [2:0] io_in_bits_ctrl_fpu_rm;
  logic [8:0] io_in_bits_ctrlPipe_2_fuOpType;
  logic io_in_bits_ctrlPipe_2_robIdx_flag;
  logic [7:0] io_in_bits_ctrlPipe_2_robIdx_value;
  logic [7:0] io_in_bits_ctrlPipe_2_pdest;
  logic io_in_bits_ctrlPipe_2_rfWen;
  logic io_in_bits_ctrlPipe_2_fpWen;
  logic io_in_bits_ctrlPipe_2_fpu_wflags;
  logic io_in_bits_validPipe_2;
  logic [63:0] io_in_bits_data_src_0;
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
  logic [2:0] io_frm;

  wire g_io_in_ready, i_io_in_ready;
  wire g_io_out_valid, i_io_out_valid;
  wire g_io_out_bits_ctrl_robIdx_flag, i_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] g_io_out_bits_ctrl_robIdx_value, i_io_out_bits_ctrl_robIdx_value;
  wire [7:0] g_io_out_bits_ctrl_pdest, i_io_out_bits_ctrl_pdest;
  wire g_io_out_bits_ctrl_rfWen, i_io_out_bits_ctrl_rfWen;
  wire g_io_out_bits_ctrl_fpWen, i_io_out_bits_ctrl_fpWen;
  wire g_io_out_bits_ctrl_fpu_wflags, i_io_out_bits_ctrl_fpu_wflags;
  wire [63:0] g_io_out_bits_res_data, i_io_out_bits_res_data;
  wire [4:0] g_io_out_bits_res_fflags, i_io_out_bits_res_fflags;
  wire g_io_out_bits_perfDebugInfo_eliminatedMove, i_io_out_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] g_io_out_bits_perfDebugInfo_renameTime, i_io_out_bits_perfDebugInfo_renameTime;
  wire [63:0] g_io_out_bits_perfDebugInfo_dispatchTime, i_io_out_bits_perfDebugInfo_dispatchTime;
  wire [63:0] g_io_out_bits_perfDebugInfo_enqRsTime, i_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] g_io_out_bits_perfDebugInfo_selectTime, i_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] g_io_out_bits_perfDebugInfo_issueTime, i_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] g_io_out_bits_perfDebugInfo_writebackTime, i_io_out_bits_perfDebugInfo_writebackTime;
  wire [63:0] g_io_out_bits_perfDebugInfo_runahead_checkpoint_id, i_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] g_io_out_bits_perfDebugInfo_tlbFirstReqTime, i_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] g_io_out_bits_perfDebugInfo_tlbRespTime, i_io_out_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] g_io_out_bits_debug_seqNum_seqNum, i_io_out_bits_debug_seqNum_seqNum;
  wire [7:0] g_io_out_bits_debug_seqNum_uopIdx, i_io_out_bits_debug_seqNum_uopIdx;


  // ---------------------------------------------------------------------------
  //  激励覆盖计数器（只为在验收报告里给出真实数字，不参与 pass/fail 判定）
  // ---------------------------------------------------------------------------
  string F64_NAME[18] = '{"+0", "-0", "+Inf", "-Inf", "+qNaN", "-qNaN", "sNaN(min)",
                          "sNaN(alt)", "min subnorm", "max -subnorm", "min normal",
                          "+1.0", "-1.0", "+0.5", "max normal", "mid subnorm",
                          "rand near 1.0", "rand any"};
  string FNN_NAME[14] = '{"+0", "-0", "+Inf", "-Inf", "qNaN", "sNaN", "min subnorm",
                          "max subnorm", "min normal", "+1.0", "-1.0", "max normal",
                          "rand near 1.0", "rand any"};
  int unsigned cov_f64[18], cov_f32[14], cov_f16[14];
  int unsigned cov_fmt[4];
  int unsigned cov_boxed, cov_unboxed;   // 窄浮点是否正确 NaN-box
  int unsigned cov_rm[8];                // 指令 rm（7 = 动态，走 fcsr.frm）
  logic [1:0]  last_fmt;                 // 本拍选中的 fmt，供 optype 覆盖统计复用

  // 舍入模式：均匀扫 0..7。7 是「动态舍入」，本层会换用 fcsr.frm，必须常打。
  function automatic logic [2:0] pick_rm();
    pick_rm = 3'($urandom);
    cov_rm[pick_rm]++;
  endfunction

  // ---------------------------------------------------------------------------
  //  浮点激励池 —— 纯 $urandom 的 64bit 值有 99.95% 概率落在 f64 的规格化区，
  //  但按 f32/f16 解读时几乎必然是「未 NaN-box 的垃圾」，NaN/Inf/非规格化/零
  //  这些真正有意思的边界一个都碰不到。所以定向池 + 随机各占一半。
  // ---------------------------------------------------------------------------
  function automatic logic [63:0] pick_f64();
    int k;
    k = $urandom_range(0, 17);
    cov_f64[k]++;
    case (k)
      0:  pick_f64 = 64'h0000_0000_0000_0000; // +0
      1:  pick_f64 = 64'h8000_0000_0000_0000; // -0
      2:  pick_f64 = 64'h7FF0_0000_0000_0000; // +Inf
      3:  pick_f64 = 64'hFFF0_0000_0000_0000; // -Inf
      4:  pick_f64 = 64'h7FF8_0000_0000_0000; // +qNaN (规范 NaN)
      5:  pick_f64 = 64'hFFF8_0000_0000_0000; // -qNaN
      6:  pick_f64 = 64'h7FF0_0000_0000_0001; // sNaN（运算要置 NV）
      7:  pick_f64 = 64'h7FF4_0000_0000_0000; // 另一个 sNaN 位型
      8:  pick_f64 = 64'h0000_0000_0000_0001; // 最小正非规格化
      9:  pick_f64 = 64'h800F_FFFF_FFFF_FFFF; // 最大负非规格化
      10: pick_f64 = 64'h0010_0000_0000_0000; // 最小正规格化
      11: pick_f64 = 64'h3FF0_0000_0000_0000; // +1.0
      12: pick_f64 = 64'hBFF0_0000_0000_0000; // -1.0
      13: pick_f64 = 64'h3FE0_0000_0000_0000; // +0.5（乘加时要移位对阶）
      14: pick_f64 = 64'h7FEF_FFFF_FFFF_FFFF; // 最大正规格化（加法易溢出）
      15: pick_f64 = 64'h0008_0000_0000_0000; // 非规格化中段
      // 指数落在 1.0 附近的随机数：保证两操作数真的能相加/相乘出有效位，
      // 而不是一个吞掉另一个（否则舍入路径永远走不到）。
      16: pick_f64 = {1'($urandom), 11'($urandom_range(1013, 1033)), 52'({$urandom, $urandom})};
      17: pick_f64 = {32'($urandom), 32'($urandom)};  // 全随机
    endcase
  endfunction

  function automatic logic [31:0] pick_f32();
    int k;
    k = $urandom_range(0, 13);
    cov_f32[k]++;
    case (k)
      0:  pick_f32 = 32'h0000_0000; // +0
      1:  pick_f32 = 32'h8000_0000; // -0
      2:  pick_f32 = 32'h7F80_0000; // +Inf
      3:  pick_f32 = 32'hFF80_0000; // -Inf
      4:  pick_f32 = 32'h7FC0_0000; // qNaN
      5:  pick_f32 = 32'h7F80_0001; // sNaN
      6:  pick_f32 = 32'h0000_0001; // 最小正非规格化
      7:  pick_f32 = 32'h007F_FFFF; // 最大非规格化
      8:  pick_f32 = 32'h0080_0000; // 最小正规格化
      9:  pick_f32 = 32'h3F80_0000; // +1.0
      10: pick_f32 = 32'hBF80_0000; // -1.0
      11: pick_f32 = 32'h7F7F_FFFF; // 最大正规格化
      12: pick_f32 = {1'($urandom), 8'($urandom_range(120, 134)), 23'($urandom)};
      13: pick_f32 = 32'($urandom);
    endcase
  endfunction

  function automatic logic [15:0] pick_f16();
    int k;
    k = $urandom_range(0, 13);
    cov_f16[k]++;
    case (k)
      0:  pick_f16 = 16'h0000; // +0
      1:  pick_f16 = 16'h8000; // -0
      2:  pick_f16 = 16'h7C00; // +Inf
      3:  pick_f16 = 16'hFC00; // -Inf
      4:  pick_f16 = 16'h7E00; // qNaN
      5:  pick_f16 = 16'h7C01; // sNaN
      6:  pick_f16 = 16'h0001; // 最小正非规格化
      7:  pick_f16 = 16'h03FF; // 最大非规格化
      8:  pick_f16 = 16'h0400; // 最小正规格化
      9:  pick_f16 = 16'h3C00; // +1.0
      10: pick_f16 = 16'hBC00; // -1.0
      11: pick_f16 = 16'h7BFF; // 最大正规格化
      12: pick_f16 = {1'($urandom), 5'($urandom_range(12, 18)), 10'($urandom)};
      13: pick_f16 = 16'($urandom);
    endcase
  endfunction

  // 按 fmt 造源操作数：窄浮点有 1/4 概率**故意不 NaN-box**（高位不全 1），
  // 用来打 isFpCanonicalNAN 这条规范 NaN 通路——这是本层自己的逻辑，必须覆盖。
  function automatic logic [63:0] pick_src(logic [1:0] fmt);
    logic [31:0] v32;
    logic [15:0] v16;
    logic        unboxed;
    unboxed = ($urandom_range(0, 3) == 0);
    case (fmt)
      2'b01: begin
        v16 = pick_f16();
        if (unboxed) begin cov_unboxed++; pick_src = {48'({$urandom, $urandom}), v16}; end
        else         begin cov_boxed++;   pick_src = {48'hFFFF_FFFF_FFFF, v16};       end
      end
      2'b10: begin
        v32 = pick_f32();
        if (unboxed) begin cov_unboxed++; pick_src = {32'($urandom), v32}; end
        else         begin cov_boxed++;   pick_src = {32'hFFFF_FFFF, v32}; end
      end
      default: pick_src = pick_f64();  // e8 与 e64 都按 64bit 位型给
    endcase
  endfunction

  // 覆盖统计的打印（末尾调用）。计数是「驱动了多少次」，不是形式覆盖率——
  // 它能证明某条边界确实被喂进去过，不能证明它在设计里被观测到。
  task automatic dump_cov();
    $display("---- 激励覆盖（驱动次数）----");
    $display("  fmt e8/e16/e32/e64 : %0d %0d %0d %0d",
             cov_fmt[0], cov_fmt[1], cov_fmt[2], cov_fmt[3]);
    $display("  窄浮点 NaN-box 合法/故意不合法 : %0d / %0d", cov_boxed, cov_unboxed);
    $display("  指令 rm 0..7 : %0d %0d %0d %0d %0d %0d %0d %0d (7=动态,走 fcsr.frm)",
             cov_rm[0], cov_rm[1], cov_rm[2], cov_rm[3],
             cov_rm[4], cov_rm[5], cov_rm[6], cov_rm[7]);
    for (int k = 0; k < 18; k++)
      $display("  f64 %-14s : %0d", F64_NAME[k], cov_f64[k]);
    for (int k = 0; k < 14; k++)
      $display("  f32 %-14s : %0d", FNN_NAME[k], cov_f32[k]);
    for (int k = 0; k < 14; k++)
      $display("  f16 %-14s : %0d", FNN_NAME[k], cov_f16[k]);
    dump_cov_mod();
  endtask

  // FCVT 是三个 FP FU 里唯一真在译 fuOpType 的：
  //   · [4:3] = widen（00 同宽 / 01 变宽 / 10 变窄 / 11 f16<->f64 特例）→ 输出宽度 one-hot
  //   · isRtz = [2]&[1] | isFcvtmod  → 舍入强制 RTZ
  //   · isRod = [2]&~[1]&[0]         → 舍入强制 ROD(就近奇)
  //   · 0xC0 = fround, 0xC4 = froundnx, 0x191 = fcvtmod.w.d
  // 所以要定向命中这几个特例，再用结构化随机扫 widen×低 3 位全组合。
  int unsigned cov_fround, cov_froundnx, cov_fcvtmod, cov_rtz, cov_rod, cov_rmnorm;
  int unsigned cov_widen[4];
  int unsigned cov_ow[5];   // [0..3]=8/16/32/64bit one-hot 命中，[4]=全 0（非法组合）

  function automatic logic [8:0] pick_optype();
    logic [3:0] ow;
    case ($urandom_range(0, 9))
      0: pick_optype = 9'h0C0;  // fround
      1: pick_optype = 9'h0C4;  // froundnx
      2: pick_optype = 9'h191;  // fcvtmod.w.d（强制 RTZ）
      3: pick_optype = 9'h180;  // FMVXF（也可能出现在 in 侧）
      4: pick_optype = 9'($urandom);
      default: pick_optype = {2'($urandom), 7'($urandom)};
    endcase
    if (pick_optype == 9'h0C0) cov_fround++;
    if (pick_optype == 9'h0C4) cov_froundnx++;
    if (pick_optype == 9'h191) cov_fcvtmod++;
    if ((pick_optype[2] & pick_optype[1]) | (pick_optype == 9'h191)) cov_rtz++;
    else if (pick_optype[2] & ~pick_optype[1] & pick_optype[0])      cov_rod++;
    else                                                             cov_rmnorm++;
    cov_widen[pick_optype[4:3]]++;
    ow = ow_ref(pick_optype[4:3], last_fmt);
    if (ow == 4'b0000) cov_ow[4]++;
    else for (int k = 0; k < 4; k++) if (ow[k]) cov_ow[k]++;
  endfunction

  // 输出宽度真值表的独立副本（tb 侧只用来统计覆盖，不作判定依据）
  function automatic logic [3:0] ow_ref(logic [1:0] widen, logic [1:0] sew);
    case ({widen, sew})
      4'b00_01, 4'b01_00, 4'b10_01, 4'b11_11: ow_ref = 4'b0010;
      4'b00_10, 4'b01_01, 4'b10_10:           ow_ref = 4'b0100;
      4'b00_11, 4'b01_10, 4'b11_01:           ow_ref = 4'b1000;
      4'b10_00:                               ow_ref = 4'b0001;
      default:                                ow_ref = 4'b0000;
    endcase
  endfunction

  // 末级用的 ctrlPipe_2.fuOpType：[6] 区分「输出是浮点还是整数」，
  // ==0x180 是 fmv（走旁路整数化结果、fflags 清零）。两条都要高频覆盖。
  int unsigned cov_mv, cov_outfp, cov_outint;
  function automatic logic [8:0] pick_ctrl_optype();
    if ($urandom_range(0, 5) == 0) pick_ctrl_optype = 9'h180;   // FMVXF
    else                           pick_ctrl_optype = 9'($urandom);
    if (pick_ctrl_optype == 9'h180) cov_mv++;
    if (pick_ctrl_optype[6]) cov_outfp++; else cov_outint++;
  endfunction

  task automatic dump_cov_mod();
    $display("  fround / froundnx / fcvtmod : %0d / %0d / %0d",
             cov_fround, cov_froundnx, cov_fcvtmod);
    $display("  舍入来源 RTZ / ROD / rm|frm : %0d / %0d / %0d",
             cov_rtz, cov_rod, cov_rmnorm);
    $display("  widen(opType[4:3]) 00/01/10/11 : %0d %0d %0d %0d",
             cov_widen[0], cov_widen[1], cov_widen[2], cov_widen[3]);
    $display("  输出宽度 one-hot 8/16/32/64/非法全0 : %0d %0d %0d %0d %0d",
             cov_ow[0], cov_ow[1], cov_ow[2], cov_ow[3], cov_ow[4]);
    $display("  末级 ctrlPipe_2: fmv / 输出浮点 / 输出整数 : %0d / %0d / %0d",
             cov_mv, cov_outfp, cov_outint);
  endtask

  FCVT u_g (.clock(clk), .reset(reset), .io_in_valid(io_in_valid), .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType), .io_in_bits_ctrl_fpu_fmt(io_in_bits_ctrl_fpu_fmt), .io_in_bits_ctrl_fpu_rm(io_in_bits_ctrl_fpu_rm), .io_in_bits_ctrlPipe_2_fuOpType(io_in_bits_ctrlPipe_2_fuOpType), .io_in_bits_ctrlPipe_2_robIdx_flag(io_in_bits_ctrlPipe_2_robIdx_flag), .io_in_bits_ctrlPipe_2_robIdx_value(io_in_bits_ctrlPipe_2_robIdx_value), .io_in_bits_ctrlPipe_2_pdest(io_in_bits_ctrlPipe_2_pdest), .io_in_bits_ctrlPipe_2_rfWen(io_in_bits_ctrlPipe_2_rfWen), .io_in_bits_ctrlPipe_2_fpWen(io_in_bits_ctrlPipe_2_fpWen), .io_in_bits_ctrlPipe_2_fpu_wflags(io_in_bits_ctrlPipe_2_fpu_wflags), .io_in_bits_validPipe_2(io_in_bits_validPipe_2), .io_in_bits_data_src_0(io_in_bits_data_src_0), .io_in_bits_perfDebugInfo_eliminatedMove(io_in_bits_perfDebugInfo_eliminatedMove), .io_in_bits_perfDebugInfo_renameTime(io_in_bits_perfDebugInfo_renameTime), .io_in_bits_perfDebugInfo_dispatchTime(io_in_bits_perfDebugInfo_dispatchTime), .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime), .io_in_bits_perfDebugInfo_writebackTime(io_in_bits_perfDebugInfo_writebackTime), .io_in_bits_perfDebugInfo_runahead_checkpoint_id(io_in_bits_perfDebugInfo_runahead_checkpoint_id), .io_in_bits_perfDebugInfo_tlbFirstReqTime(io_in_bits_perfDebugInfo_tlbFirstReqTime), .io_in_bits_perfDebugInfo_tlbRespTime(io_in_bits_perfDebugInfo_tlbRespTime), .io_in_bits_debug_seqNum_seqNum(io_in_bits_debug_seqNum_seqNum), .io_in_bits_debug_seqNum_uopIdx(io_in_bits_debug_seqNum_uopIdx), .io_out_ready(io_out_ready), .io_frm(io_frm), .io_in_ready(g_io_in_ready), .io_out_valid(g_io_out_valid), .io_out_bits_ctrl_robIdx_flag(g_io_out_bits_ctrl_robIdx_flag), .io_out_bits_ctrl_robIdx_value(g_io_out_bits_ctrl_robIdx_value), .io_out_bits_ctrl_pdest(g_io_out_bits_ctrl_pdest), .io_out_bits_ctrl_rfWen(g_io_out_bits_ctrl_rfWen), .io_out_bits_ctrl_fpWen(g_io_out_bits_ctrl_fpWen), .io_out_bits_ctrl_fpu_wflags(g_io_out_bits_ctrl_fpu_wflags), .io_out_bits_res_data(g_io_out_bits_res_data), .io_out_bits_res_fflags(g_io_out_bits_res_fflags), .io_out_bits_perfDebugInfo_eliminatedMove(g_io_out_bits_perfDebugInfo_eliminatedMove), .io_out_bits_perfDebugInfo_renameTime(g_io_out_bits_perfDebugInfo_renameTime), .io_out_bits_perfDebugInfo_dispatchTime(g_io_out_bits_perfDebugInfo_dispatchTime), .io_out_bits_perfDebugInfo_enqRsTime(g_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(g_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(g_io_out_bits_perfDebugInfo_issueTime), .io_out_bits_perfDebugInfo_writebackTime(g_io_out_bits_perfDebugInfo_writebackTime), .io_out_bits_perfDebugInfo_runahead_checkpoint_id(g_io_out_bits_perfDebugInfo_runahead_checkpoint_id), .io_out_bits_perfDebugInfo_tlbFirstReqTime(g_io_out_bits_perfDebugInfo_tlbFirstReqTime), .io_out_bits_perfDebugInfo_tlbRespTime(g_io_out_bits_perfDebugInfo_tlbRespTime), .io_out_bits_debug_seqNum_seqNum(g_io_out_bits_debug_seqNum_seqNum), .io_out_bits_debug_seqNum_uopIdx(g_io_out_bits_debug_seqNum_uopIdx));
  FCVT_xs u_i (.clock(clk), .reset(reset), .io_in_valid(io_in_valid), .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType), .io_in_bits_ctrl_fpu_fmt(io_in_bits_ctrl_fpu_fmt), .io_in_bits_ctrl_fpu_rm(io_in_bits_ctrl_fpu_rm), .io_in_bits_ctrlPipe_2_fuOpType(io_in_bits_ctrlPipe_2_fuOpType), .io_in_bits_ctrlPipe_2_robIdx_flag(io_in_bits_ctrlPipe_2_robIdx_flag), .io_in_bits_ctrlPipe_2_robIdx_value(io_in_bits_ctrlPipe_2_robIdx_value), .io_in_bits_ctrlPipe_2_pdest(io_in_bits_ctrlPipe_2_pdest), .io_in_bits_ctrlPipe_2_rfWen(io_in_bits_ctrlPipe_2_rfWen), .io_in_bits_ctrlPipe_2_fpWen(io_in_bits_ctrlPipe_2_fpWen), .io_in_bits_ctrlPipe_2_fpu_wflags(io_in_bits_ctrlPipe_2_fpu_wflags), .io_in_bits_validPipe_2(io_in_bits_validPipe_2), .io_in_bits_data_src_0(io_in_bits_data_src_0), .io_in_bits_perfDebugInfo_eliminatedMove(io_in_bits_perfDebugInfo_eliminatedMove), .io_in_bits_perfDebugInfo_renameTime(io_in_bits_perfDebugInfo_renameTime), .io_in_bits_perfDebugInfo_dispatchTime(io_in_bits_perfDebugInfo_dispatchTime), .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime), .io_in_bits_perfDebugInfo_writebackTime(io_in_bits_perfDebugInfo_writebackTime), .io_in_bits_perfDebugInfo_runahead_checkpoint_id(io_in_bits_perfDebugInfo_runahead_checkpoint_id), .io_in_bits_perfDebugInfo_tlbFirstReqTime(io_in_bits_perfDebugInfo_tlbFirstReqTime), .io_in_bits_perfDebugInfo_tlbRespTime(io_in_bits_perfDebugInfo_tlbRespTime), .io_in_bits_debug_seqNum_seqNum(io_in_bits_debug_seqNum_seqNum), .io_in_bits_debug_seqNum_uopIdx(io_in_bits_debug_seqNum_uopIdx), .io_out_ready(io_out_ready), .io_frm(io_frm), .io_in_ready(i_io_in_ready), .io_out_valid(i_io_out_valid), .io_out_bits_ctrl_robIdx_flag(i_io_out_bits_ctrl_robIdx_flag), .io_out_bits_ctrl_robIdx_value(i_io_out_bits_ctrl_robIdx_value), .io_out_bits_ctrl_pdest(i_io_out_bits_ctrl_pdest), .io_out_bits_ctrl_rfWen(i_io_out_bits_ctrl_rfWen), .io_out_bits_ctrl_fpWen(i_io_out_bits_ctrl_fpWen), .io_out_bits_ctrl_fpu_wflags(i_io_out_bits_ctrl_fpu_wflags), .io_out_bits_res_data(i_io_out_bits_res_data), .io_out_bits_res_fflags(i_io_out_bits_res_fflags), .io_out_bits_perfDebugInfo_eliminatedMove(i_io_out_bits_perfDebugInfo_eliminatedMove), .io_out_bits_perfDebugInfo_renameTime(i_io_out_bits_perfDebugInfo_renameTime), .io_out_bits_perfDebugInfo_dispatchTime(i_io_out_bits_perfDebugInfo_dispatchTime), .io_out_bits_perfDebugInfo_enqRsTime(i_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(i_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(i_io_out_bits_perfDebugInfo_issueTime), .io_out_bits_perfDebugInfo_writebackTime(i_io_out_bits_perfDebugInfo_writebackTime), .io_out_bits_perfDebugInfo_runahead_checkpoint_id(i_io_out_bits_perfDebugInfo_runahead_checkpoint_id), .io_out_bits_perfDebugInfo_tlbFirstReqTime(i_io_out_bits_perfDebugInfo_tlbFirstReqTime), .io_out_bits_perfDebugInfo_tlbRespTime(i_io_out_bits_perfDebugInfo_tlbRespTime), .io_out_bits_debug_seqNum_seqNum(i_io_out_bits_debug_seqNum_seqNum), .io_out_bits_debug_seqNum_uopIdx(i_io_out_bits_debug_seqNum_uopIdx));

  // 每拍在 negedge 换激励，posedge 采样，negedge+4 比对上一拍结果。
  task automatic drive();
    logic [1:0] fmt_n;
    // fmt：e16/e32/e64 各占大头，e8 也给一点（标量浮点用不到，但编码合法）
    fmt_n = ($urandom_range(0, 9) == 0) ? 2'b00 : 2'($urandom_range(1, 3));
    last_fmt = fmt_n;
    cov_fmt[fmt_n]++;
    io_in_valid <= ($urandom_range(0, 3) != 0);
    io_in_bits_ctrl_fuOpType <= pick_optype();
    io_in_bits_ctrl_fpu_fmt <= fmt_n;
    io_in_bits_ctrl_fpu_rm <= pick_rm();
    io_in_bits_ctrlPipe_2_fuOpType <= pick_ctrl_optype();
    io_in_bits_ctrlPipe_2_robIdx_flag <= 1'($urandom);
    io_in_bits_ctrlPipe_2_robIdx_value <= 8'($urandom);
    io_in_bits_ctrlPipe_2_pdest <= 8'($urandom);
    io_in_bits_ctrlPipe_2_rfWen <= 1'($urandom);
    io_in_bits_ctrlPipe_2_fpWen <= 1'($urandom);
    io_in_bits_ctrlPipe_2_fpu_wflags <= 1'($urandom);
    io_in_bits_validPipe_2 <= 1'($urandom);
    io_in_bits_data_src_0 <= pick_src(fmt_n);
    io_in_bits_perfDebugInfo_eliminatedMove <= 1'($urandom);
    io_in_bits_perfDebugInfo_renameTime <= 64'({$urandom, $urandom});
    io_in_bits_perfDebugInfo_dispatchTime <= 64'({$urandom, $urandom});
    io_in_bits_perfDebugInfo_enqRsTime <= 64'({$urandom, $urandom});
    io_in_bits_perfDebugInfo_selectTime <= 64'({$urandom, $urandom});
    io_in_bits_perfDebugInfo_issueTime <= 64'({$urandom, $urandom});
    io_in_bits_perfDebugInfo_writebackTime <= 64'({$urandom, $urandom});
    io_in_bits_perfDebugInfo_runahead_checkpoint_id <= 64'({$urandom, $urandom});
    io_in_bits_perfDebugInfo_tlbFirstReqTime <= 64'({$urandom, $urandom});
    io_in_bits_perfDebugInfo_tlbRespTime <= 64'({$urandom, $urandom});
    io_in_bits_debug_seqNum_seqNum <= 56'({$urandom, $urandom});
    io_in_bits_debug_seqNum_uopIdx <= 8'($urandom);
    io_out_ready <= ($urandom_range(0, 3) != 0);
    io_frm <= 3'($urandom);
  endtask

  initial begin
    reset = 1;
    drive();          // t=0 就把输入喂成确定值：
                      // 让 X 只来自寄存器初值（两侧同构），不来自输入
  end

  always @(negedge clk) begin
    cyc++;
    // 前 4 拍复位；之后偶发单拍复位，覆盖 valid 链的异步复位分支
    reset <= (cyc <= 4) || ($urandom_range(0, 1999) == 0);
    drive();
  end

  always @(negedge clk) begin
    #4;
    checks++;
    if (g_io_in_ready !== i_io_in_ready) begin
      errors++;
      $display("[%0t] io_in_ready mismatch: g=%h i=%h", $time, g_io_in_ready, i_io_in_ready);
    end
    if (g_io_out_valid !== i_io_out_valid) begin
      errors++;
      $display("[%0t] io_out_valid mismatch: g=%h i=%h", $time, g_io_out_valid, i_io_out_valid);
    end
    if (g_io_out_bits_ctrl_robIdx_flag !== i_io_out_bits_ctrl_robIdx_flag) begin
      errors++;
      $display("[%0t] io_out_bits_ctrl_robIdx_flag mismatch: g=%h i=%h", $time, g_io_out_bits_ctrl_robIdx_flag, i_io_out_bits_ctrl_robIdx_flag);
    end
    if (g_io_out_bits_ctrl_robIdx_value !== i_io_out_bits_ctrl_robIdx_value) begin
      errors++;
      $display("[%0t] io_out_bits_ctrl_robIdx_value mismatch: g=%h i=%h", $time, g_io_out_bits_ctrl_robIdx_value, i_io_out_bits_ctrl_robIdx_value);
    end
    if (g_io_out_bits_ctrl_pdest !== i_io_out_bits_ctrl_pdest) begin
      errors++;
      $display("[%0t] io_out_bits_ctrl_pdest mismatch: g=%h i=%h", $time, g_io_out_bits_ctrl_pdest, i_io_out_bits_ctrl_pdest);
    end
    if (g_io_out_bits_ctrl_rfWen !== i_io_out_bits_ctrl_rfWen) begin
      errors++;
      $display("[%0t] io_out_bits_ctrl_rfWen mismatch: g=%h i=%h", $time, g_io_out_bits_ctrl_rfWen, i_io_out_bits_ctrl_rfWen);
    end
    if (g_io_out_bits_ctrl_fpWen !== i_io_out_bits_ctrl_fpWen) begin
      errors++;
      $display("[%0t] io_out_bits_ctrl_fpWen mismatch: g=%h i=%h", $time, g_io_out_bits_ctrl_fpWen, i_io_out_bits_ctrl_fpWen);
    end
    if (g_io_out_bits_ctrl_fpu_wflags !== i_io_out_bits_ctrl_fpu_wflags) begin
      errors++;
      $display("[%0t] io_out_bits_ctrl_fpu_wflags mismatch: g=%h i=%h", $time, g_io_out_bits_ctrl_fpu_wflags, i_io_out_bits_ctrl_fpu_wflags);
    end
    if (g_io_out_bits_res_data !== i_io_out_bits_res_data) begin
      errors++;
      $display("[%0t] io_out_bits_res_data mismatch: g=%h i=%h", $time, g_io_out_bits_res_data, i_io_out_bits_res_data);
    end
    if (g_io_out_bits_res_fflags !== i_io_out_bits_res_fflags) begin
      errors++;
      $display("[%0t] io_out_bits_res_fflags mismatch: g=%h i=%h", $time, g_io_out_bits_res_fflags, i_io_out_bits_res_fflags);
    end
    if (g_io_out_bits_perfDebugInfo_eliminatedMove !== i_io_out_bits_perfDebugInfo_eliminatedMove) begin
      errors++;
      $display("[%0t] io_out_bits_perfDebugInfo_eliminatedMove mismatch: g=%h i=%h", $time, g_io_out_bits_perfDebugInfo_eliminatedMove, i_io_out_bits_perfDebugInfo_eliminatedMove);
    end
    if (g_io_out_bits_perfDebugInfo_renameTime !== i_io_out_bits_perfDebugInfo_renameTime) begin
      errors++;
      $display("[%0t] io_out_bits_perfDebugInfo_renameTime mismatch: g=%h i=%h", $time, g_io_out_bits_perfDebugInfo_renameTime, i_io_out_bits_perfDebugInfo_renameTime);
    end
    if (g_io_out_bits_perfDebugInfo_dispatchTime !== i_io_out_bits_perfDebugInfo_dispatchTime) begin
      errors++;
      $display("[%0t] io_out_bits_perfDebugInfo_dispatchTime mismatch: g=%h i=%h", $time, g_io_out_bits_perfDebugInfo_dispatchTime, i_io_out_bits_perfDebugInfo_dispatchTime);
    end
    if (g_io_out_bits_perfDebugInfo_enqRsTime !== i_io_out_bits_perfDebugInfo_enqRsTime) begin
      errors++;
      $display("[%0t] io_out_bits_perfDebugInfo_enqRsTime mismatch: g=%h i=%h", $time, g_io_out_bits_perfDebugInfo_enqRsTime, i_io_out_bits_perfDebugInfo_enqRsTime);
    end
    if (g_io_out_bits_perfDebugInfo_selectTime !== i_io_out_bits_perfDebugInfo_selectTime) begin
      errors++;
      $display("[%0t] io_out_bits_perfDebugInfo_selectTime mismatch: g=%h i=%h", $time, g_io_out_bits_perfDebugInfo_selectTime, i_io_out_bits_perfDebugInfo_selectTime);
    end
    if (g_io_out_bits_perfDebugInfo_issueTime !== i_io_out_bits_perfDebugInfo_issueTime) begin
      errors++;
      $display("[%0t] io_out_bits_perfDebugInfo_issueTime mismatch: g=%h i=%h", $time, g_io_out_bits_perfDebugInfo_issueTime, i_io_out_bits_perfDebugInfo_issueTime);
    end
    if (g_io_out_bits_perfDebugInfo_writebackTime !== i_io_out_bits_perfDebugInfo_writebackTime) begin
      errors++;
      $display("[%0t] io_out_bits_perfDebugInfo_writebackTime mismatch: g=%h i=%h", $time, g_io_out_bits_perfDebugInfo_writebackTime, i_io_out_bits_perfDebugInfo_writebackTime);
    end
    if (g_io_out_bits_perfDebugInfo_runahead_checkpoint_id !== i_io_out_bits_perfDebugInfo_runahead_checkpoint_id) begin
      errors++;
      $display("[%0t] io_out_bits_perfDebugInfo_runahead_checkpoint_id mismatch: g=%h i=%h", $time, g_io_out_bits_perfDebugInfo_runahead_checkpoint_id, i_io_out_bits_perfDebugInfo_runahead_checkpoint_id);
    end
    if (g_io_out_bits_perfDebugInfo_tlbFirstReqTime !== i_io_out_bits_perfDebugInfo_tlbFirstReqTime) begin
      errors++;
      $display("[%0t] io_out_bits_perfDebugInfo_tlbFirstReqTime mismatch: g=%h i=%h", $time, g_io_out_bits_perfDebugInfo_tlbFirstReqTime, i_io_out_bits_perfDebugInfo_tlbFirstReqTime);
    end
    if (g_io_out_bits_perfDebugInfo_tlbRespTime !== i_io_out_bits_perfDebugInfo_tlbRespTime) begin
      errors++;
      $display("[%0t] io_out_bits_perfDebugInfo_tlbRespTime mismatch: g=%h i=%h", $time, g_io_out_bits_perfDebugInfo_tlbRespTime, i_io_out_bits_perfDebugInfo_tlbRespTime);
    end
    if (g_io_out_bits_debug_seqNum_seqNum !== i_io_out_bits_debug_seqNum_seqNum) begin
      errors++;
      $display("[%0t] io_out_bits_debug_seqNum_seqNum mismatch: g=%h i=%h", $time, g_io_out_bits_debug_seqNum_seqNum, i_io_out_bits_debug_seqNum_seqNum);
    end
    if (g_io_out_bits_debug_seqNum_uopIdx !== i_io_out_bits_debug_seqNum_uopIdx) begin
      errors++;
      $display("[%0t] io_out_bits_debug_seqNum_uopIdx mismatch: g=%h i=%h", $time, g_io_out_bits_debug_seqNum_uopIdx, i_io_out_bits_debug_seqNum_uopIdx);
    end
  end

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    repeat (NCYCLES) @(posedge clk);
    dump_cov();
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
