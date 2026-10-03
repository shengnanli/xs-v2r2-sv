// ArithVecLeaves5 双例化逐拍比对 tb —— 族 A 五叶：golden <M>（u_g）vs 重写 <M>_xs（u_i）。
// Adder_chain_rnd / VIAluDecoder / VIntAdder64b 是纯组合叶：每拍全随机驱动、#1 后逐输出比对。
// DivUnit / FDivSqrt 是时序包装层：共享 clock/reset/flush 激励，in_valid 50%、out_ready 75%、
// flush 约 3%；其输出 payload 寄存器无复位，两侧上电初值在随机初值档位下可能不同，
// 故 payload 比对由 armed 闸（首次接受后置位）把守；握手/数据输出恒比对（$isunknown 守卫）。
// 覆盖闸（防"DUT 没动也全绿"）：checks/toggled/fires + 每模块专项计数（sew 桶、18 条译码、
// 13 个 opcode、widen/is_sub/eew、除法/开方接受数、flush 数）。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint checks = 0, errors = 0;

  bit clock = 0;
  always #5 clock = ~clock;
  bit reset;

  // ---- 比对与翻转统计原语 ----
  task automatic cmp(input string tag, input logic [1023:0] g, input logic [1023:0] i);
    if (!$isunknown(g)) begin
      checks++;
      if (g !== i) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH %s g=%0h i=%0h", $time, tag, g, i);
      end
    end
  endtask

  localparam int N_TOG = 26;
  logic [1023:0] tog_prev [N_TOG];
  logic [N_TOG-1:0] tog_mask;
  task automatic tog(input int idx, input logic [1023:0] cur);
    if (cur !== tog_prev[idx]) tog_mask[idx] = 1'b1;
    tog_prev[idx] = cur;
  endtask

  function automatic logic [63:0] rnd64();
    return {$urandom, $urandom};
  endfunction


  // ================= Adder_chain_rnd（组合）=================
  logic [7:0] ac_din [8];
  logic [7:0] ac_rnd;
  logic       ac_nclip;
  logic [3:0] ac_sew;
  wire [7:0] g_ac_dout [8];
  wire [6:0] g_ac_cout, g_ac_a1, g_ac_a0;
  wire [7:0] i_ac_dout [8];
  wire [6:0] i_ac_cout, i_ac_a1, i_ac_a0;
  longint ac_sew_bucket [8];   // 下标 = sew_onehot_idx*2 + is_nclip

  Adder_chain_rnd u_g_ac (
    .io_din_0 (ac_din[0]),
    .io_din_1 (ac_din[1]),
    .io_din_2 (ac_din[2]),
    .io_din_3 (ac_din[3]),
    .io_din_4 (ac_din[4]),
    .io_din_5 (ac_din[5]),
    .io_din_6 (ac_din[6]),
    .io_din_7 (ac_din[7]),
    .io_rndInc_0 (ac_rnd[0]),
    .io_rndInc_1 (ac_rnd[1]),
    .io_rndInc_2 (ac_rnd[2]),
    .io_rndInc_3 (ac_rnd[3]),
    .io_rndInc_4 (ac_rnd[4]),
    .io_rndInc_5 (ac_rnd[5]),
    .io_rndInc_6 (ac_rnd[6]),
    .io_rndInc_7 (ac_rnd[7]),
    .io_isNClip (ac_nclip),
    .io_sew_oneHot (ac_sew),
    .io_dout_0 (g_ac_dout[0]),
    .io_dout_1 (g_ac_dout[1]),
    .io_dout_2 (g_ac_dout[2]),
    .io_dout_3 (g_ac_dout[3]),
    .io_dout_4 (g_ac_dout[4]),
    .io_dout_5 (g_ac_dout[5]),
    .io_dout_6 (g_ac_dout[6]),
    .io_dout_7 (g_ac_dout[7]),
    .io_cout_0 (g_ac_cout[0]),
    .io_cout_1 (g_ac_cout[1]),
    .io_cout_2 (g_ac_cout[2]),
    .io_cout_3 (g_ac_cout[3]),
    .io_cout_4 (g_ac_cout[4]),
    .io_cout_5 (g_ac_cout[5]),
    .io_cout_6 (g_ac_cout[6]),
    .io_all_1s_1 (g_ac_a1[0]),
    .io_all_1s_2 (g_ac_a1[1]),
    .io_all_1s_3 (g_ac_a1[2]),
    .io_all_1s_4 (g_ac_a1[3]),
    .io_all_1s_5 (g_ac_a1[4]),
    .io_all_1s_6 (g_ac_a1[5]),
    .io_all_1s_7 (g_ac_a1[6]),
    .io_all_0s_1 (g_ac_a0[0]),
    .io_all_0s_2 (g_ac_a0[1]),
    .io_all_0s_3 (g_ac_a0[2]),
    .io_all_0s_4 (g_ac_a0[3]),
    .io_all_0s_5 (g_ac_a0[4]),
    .io_all_0s_6 (g_ac_a0[5]),
    .io_all_0s_7 (g_ac_a0[6])
  );
  Adder_chain_rnd_xs u_i_ac (
    .io_din_0 (ac_din[0]),
    .io_din_1 (ac_din[1]),
    .io_din_2 (ac_din[2]),
    .io_din_3 (ac_din[3]),
    .io_din_4 (ac_din[4]),
    .io_din_5 (ac_din[5]),
    .io_din_6 (ac_din[6]),
    .io_din_7 (ac_din[7]),
    .io_rndInc_0 (ac_rnd[0]),
    .io_rndInc_1 (ac_rnd[1]),
    .io_rndInc_2 (ac_rnd[2]),
    .io_rndInc_3 (ac_rnd[3]),
    .io_rndInc_4 (ac_rnd[4]),
    .io_rndInc_5 (ac_rnd[5]),
    .io_rndInc_6 (ac_rnd[6]),
    .io_rndInc_7 (ac_rnd[7]),
    .io_isNClip (ac_nclip),
    .io_sew_oneHot (ac_sew),
    .io_dout_0 (i_ac_dout[0]),
    .io_dout_1 (i_ac_dout[1]),
    .io_dout_2 (i_ac_dout[2]),
    .io_dout_3 (i_ac_dout[3]),
    .io_dout_4 (i_ac_dout[4]),
    .io_dout_5 (i_ac_dout[5]),
    .io_dout_6 (i_ac_dout[6]),
    .io_dout_7 (i_ac_dout[7]),
    .io_cout_0 (i_ac_cout[0]),
    .io_cout_1 (i_ac_cout[1]),
    .io_cout_2 (i_ac_cout[2]),
    .io_cout_3 (i_ac_cout[3]),
    .io_cout_4 (i_ac_cout[4]),
    .io_cout_5 (i_ac_cout[5]),
    .io_cout_6 (i_ac_cout[6]),
    .io_all_1s_1 (i_ac_a1[0]),
    .io_all_1s_2 (i_ac_a1[1]),
    .io_all_1s_3 (i_ac_a1[2]),
    .io_all_1s_4 (i_ac_a1[3]),
    .io_all_1s_5 (i_ac_a1[4]),
    .io_all_1s_6 (i_ac_a1[5]),
    .io_all_1s_7 (i_ac_a1[6]),
    .io_all_0s_1 (i_ac_a0[0]),
    .io_all_0s_2 (i_ac_a0[1]),
    .io_all_0s_3 (i_ac_a0[2]),
    .io_all_0s_4 (i_ac_a0[3]),
    .io_all_0s_5 (i_ac_a0[4]),
    .io_all_0s_6 (i_ac_a0[5]),
    .io_all_0s_7 (i_ac_a0[6])
  );
  // 拼接视图（比对/翻转用）
  wire [63:0] g_ac_dout_c = {g_ac_dout[7],g_ac_dout[6],g_ac_dout[5],g_ac_dout[4],g_ac_dout[3],g_ac_dout[2],g_ac_dout[1],g_ac_dout[0]};
  wire [63:0] i_ac_dout_c = {i_ac_dout[7],i_ac_dout[6],i_ac_dout[5],i_ac_dout[4],i_ac_dout[3],i_ac_dout[2],i_ac_dout[1],i_ac_dout[0]};


  // ================= VIAluDecoder（组合）=================
  logic [7:0] dec_op;
  wire [5:0] g_dec_opcode, i_dec_opcode;
  wire [2:0] g_dec_st2, i_dec_st2, g_dec_vdt, i_dec_vdt;
  longint dec_hit [256];
  logic [17:0] dec_op_seen;

  VIAluDecoder u_g_dec (
    .io_in_fuOpType (dec_op),
    .io_out_opcode (g_dec_opcode),
    .io_out_srcType2 (g_dec_st2),
    .io_out_vdType (g_dec_vdt)
  );
  VIAluDecoder_xs u_i_dec (
    .io_in_fuOpType (dec_op),
    .io_out_opcode (i_dec_opcode),
    .io_out_srcType2 (i_dec_st2),
    .io_out_vdType (i_dec_vdt)
  );

  // ================= VIntAdder64b（组合）=================
  logic [5:0]  va_op;
  logic        va_vm, va_ma, va_sub, va_widen, va_widen2;
  logic [5:0]  va_uopidx;
  logic [3:0]  va_st1, va_vdt;
  logic [63:0] va_vs1, va_vs2;
  logic [7:0]  va_vmask, va_oldvd;
  wire [63:0] g_va_vd, i_va_vd;
  wire [7:0]  g_va_cmp, i_va_cmp;
  wire [7:0]  g_va_fcout, i_va_fcout;
  wire [63:0] g_va_fvd, i_va_fvd;
  wire [7:0]  g_va_vs2h, i_va_vs2h, g_va_vs1h, i_va_vs1h;
  logic [63:0] va_op_seen;
  longint va_widen_cnt, va_widen2_cnt, va_sub_cnt, va_signed_cnt;
  longint va_eew_cnt [4];

  VIntAdder64b u_g_va (
    .io_opcode_op (va_op),
    .io_info_vm (va_vm),
    .io_info_ma (va_ma),
    .io_info_uopIdx (va_uopidx),
    .io_srcType_1 (va_st1),
    .io_vdType (va_vdt),
    .io_vs1 (va_vs1),
    .io_vs2 (va_vs2),
    .io_vmask (va_vmask),
    .io_oldVd (va_oldvd),
    .io_isSub (va_sub),
    .io_widen (va_widen),
    .io_widen_vs2 (va_widen2),
    .io_vd (g_va_vd),
    .io_cmpOut (g_va_cmp),
    .io_toFixP_cout_0 (g_va_fcout[0]),
    .io_toFixP_cout_1 (g_va_fcout[1]),
    .io_toFixP_cout_2 (g_va_fcout[2]),
    .io_toFixP_cout_3 (g_va_fcout[3]),
    .io_toFixP_cout_4 (g_va_fcout[4]),
    .io_toFixP_cout_5 (g_va_fcout[5]),
    .io_toFixP_cout_6 (g_va_fcout[6]),
    .io_toFixP_cout_7 (g_va_fcout[7]),
    .io_toFixP_vd_0 (g_va_fvd[0 +: 8]),
    .io_toFixP_vd_1 (g_va_fvd[8 +: 8]),
    .io_toFixP_vd_2 (g_va_fvd[16 +: 8]),
    .io_toFixP_vd_3 (g_va_fvd[24 +: 8]),
    .io_toFixP_vd_4 (g_va_fvd[32 +: 8]),
    .io_toFixP_vd_5 (g_va_fvd[40 +: 8]),
    .io_toFixP_vd_6 (g_va_fvd[48 +: 8]),
    .io_toFixP_vd_7 (g_va_fvd[56 +: 8]),
    .io_toFixP_vs2H_0 (g_va_vs2h[0]),
    .io_toFixP_vs2H_1 (g_va_vs2h[1]),
    .io_toFixP_vs2H_2 (g_va_vs2h[2]),
    .io_toFixP_vs2H_3 (g_va_vs2h[3]),
    .io_toFixP_vs2H_4 (g_va_vs2h[4]),
    .io_toFixP_vs2H_5 (g_va_vs2h[5]),
    .io_toFixP_vs2H_6 (g_va_vs2h[6]),
    .io_toFixP_vs2H_7 (g_va_vs2h[7]),
    .io_toFixP_vs1H_0 (g_va_vs1h[0]),
    .io_toFixP_vs1H_1 (g_va_vs1h[1]),
    .io_toFixP_vs1H_2 (g_va_vs1h[2]),
    .io_toFixP_vs1H_3 (g_va_vs1h[3]),
    .io_toFixP_vs1H_4 (g_va_vs1h[4]),
    .io_toFixP_vs1H_5 (g_va_vs1h[5]),
    .io_toFixP_vs1H_6 (g_va_vs1h[6]),
    .io_toFixP_vs1H_7 (g_va_vs1h[7])
  );
  VIntAdder64b_xs u_i_va (
    .io_opcode_op (va_op),
    .io_info_vm (va_vm),
    .io_info_ma (va_ma),
    .io_info_uopIdx (va_uopidx),
    .io_srcType_1 (va_st1),
    .io_vdType (va_vdt),
    .io_vs1 (va_vs1),
    .io_vs2 (va_vs2),
    .io_vmask (va_vmask),
    .io_oldVd (va_oldvd),
    .io_isSub (va_sub),
    .io_widen (va_widen),
    .io_widen_vs2 (va_widen2),
    .io_vd (i_va_vd),
    .io_cmpOut (i_va_cmp),
    .io_toFixP_cout_0 (i_va_fcout[0]),
    .io_toFixP_cout_1 (i_va_fcout[1]),
    .io_toFixP_cout_2 (i_va_fcout[2]),
    .io_toFixP_cout_3 (i_va_fcout[3]),
    .io_toFixP_cout_4 (i_va_fcout[4]),
    .io_toFixP_cout_5 (i_va_fcout[5]),
    .io_toFixP_cout_6 (i_va_fcout[6]),
    .io_toFixP_cout_7 (i_va_fcout[7]),
    .io_toFixP_vd_0 (i_va_fvd[0 +: 8]),
    .io_toFixP_vd_1 (i_va_fvd[8 +: 8]),
    .io_toFixP_vd_2 (i_va_fvd[16 +: 8]),
    .io_toFixP_vd_3 (i_va_fvd[24 +: 8]),
    .io_toFixP_vd_4 (i_va_fvd[32 +: 8]),
    .io_toFixP_vd_5 (i_va_fvd[40 +: 8]),
    .io_toFixP_vd_6 (i_va_fvd[48 +: 8]),
    .io_toFixP_vd_7 (i_va_fvd[56 +: 8]),
    .io_toFixP_vs2H_0 (i_va_vs2h[0]),
    .io_toFixP_vs2H_1 (i_va_vs2h[1]),
    .io_toFixP_vs2H_2 (i_va_vs2h[2]),
    .io_toFixP_vs2H_3 (i_va_vs2h[3]),
    .io_toFixP_vs2H_4 (i_va_vs2h[4]),
    .io_toFixP_vs2H_5 (i_va_vs2h[5]),
    .io_toFixP_vs2H_6 (i_va_vs2h[6]),
    .io_toFixP_vs2H_7 (i_va_vs2h[7]),
    .io_toFixP_vs1H_0 (i_va_vs1h[0]),
    .io_toFixP_vs1H_1 (i_va_vs1h[1]),
    .io_toFixP_vs1H_2 (i_va_vs1h[2]),
    .io_toFixP_vs1H_3 (i_va_vs1h[3]),
    .io_toFixP_vs1H_4 (i_va_vs1h[4]),
    .io_toFixP_vs1H_5 (i_va_vs1h[5]),
    .io_toFixP_vs1H_6 (i_va_vs1h[6]),
    .io_toFixP_vs1H_7 (i_va_vs1h[7])
  );

  // ================= DivUnit（时序包装层）=================
  logic  du_io_flush_valid;
  logic  du_io_flush_bits_robIdx_flag;
  logic [7:0]  du_io_flush_bits_robIdx_value;
  logic  du_io_flush_bits_level;
  wire  g_du_io_in_ready;
  wire  i_du_io_in_ready;
  logic  du_io_in_valid;
  logic [8:0]  du_io_in_bits_ctrl_fuOpType;
  logic  du_io_in_bits_ctrl_robIdx_flag;
  logic [7:0]  du_io_in_bits_ctrl_robIdx_value;
  logic [7:0]  du_io_in_bits_ctrl_pdest;
  logic  du_io_in_bits_ctrl_rfWen;
  logic [63:0]  du_io_in_bits_data_src_1;
  logic [63:0]  du_io_in_bits_data_src_0;
  logic  du_io_in_bits_perfDebugInfo_eliminatedMove;
  logic [63:0]  du_io_in_bits_perfDebugInfo_renameTime;
  logic [63:0]  du_io_in_bits_perfDebugInfo_dispatchTime;
  logic [63:0]  du_io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0]  du_io_in_bits_perfDebugInfo_selectTime;
  logic [63:0]  du_io_in_bits_perfDebugInfo_issueTime;
  logic [63:0]  du_io_in_bits_perfDebugInfo_writebackTime;
  logic [63:0]  du_io_in_bits_perfDebugInfo_runahead_checkpoint_id;
  logic [63:0]  du_io_in_bits_perfDebugInfo_tlbFirstReqTime;
  logic [63:0]  du_io_in_bits_perfDebugInfo_tlbRespTime;
  logic [55:0]  du_io_in_bits_debug_seqNum_seqNum;
  logic [7:0]  du_io_in_bits_debug_seqNum_uopIdx;
  logic  du_io_out_ready;
  wire  g_du_io_out_valid;
  wire  i_du_io_out_valid;
  wire  g_du_io_out_bits_ctrl_robIdx_flag;
  wire  i_du_io_out_bits_ctrl_robIdx_flag;
  wire [7:0]  g_du_io_out_bits_ctrl_robIdx_value;
  wire [7:0]  i_du_io_out_bits_ctrl_robIdx_value;
  wire [7:0]  g_du_io_out_bits_ctrl_pdest;
  wire [7:0]  i_du_io_out_bits_ctrl_pdest;
  wire  g_du_io_out_bits_ctrl_rfWen;
  wire  i_du_io_out_bits_ctrl_rfWen;
  wire [63:0]  g_du_io_out_bits_res_data;
  wire [63:0]  i_du_io_out_bits_res_data;
  wire  g_du_io_out_bits_perfDebugInfo_eliminatedMove;
  wire  i_du_io_out_bits_perfDebugInfo_eliminatedMove;
  wire [63:0]  g_du_io_out_bits_perfDebugInfo_renameTime;
  wire [63:0]  i_du_io_out_bits_perfDebugInfo_renameTime;
  wire [63:0]  g_du_io_out_bits_perfDebugInfo_dispatchTime;
  wire [63:0]  i_du_io_out_bits_perfDebugInfo_dispatchTime;
  wire [63:0]  g_du_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0]  i_du_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0]  g_du_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0]  i_du_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0]  g_du_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0]  i_du_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0]  g_du_io_out_bits_perfDebugInfo_writebackTime;
  wire [63:0]  i_du_io_out_bits_perfDebugInfo_writebackTime;
  wire [63:0]  g_du_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0]  i_du_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0]  g_du_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0]  i_du_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0]  g_du_io_out_bits_perfDebugInfo_tlbRespTime;
  wire [63:0]  i_du_io_out_bits_perfDebugInfo_tlbRespTime;
  wire [55:0]  g_du_io_out_bits_debug_seqNum_seqNum;
  wire [55:0]  i_du_io_out_bits_debug_seqNum_seqNum;
  wire [7:0]  g_du_io_out_bits_debug_seqNum_uopIdx;
  wire [7:0]  i_du_io_out_bits_debug_seqNum_uopIdx;
  DivUnit u_g_du (
    .clock (clock),
    .reset (reset),
    .io_flush_valid (du_io_flush_valid),
    .io_flush_bits_robIdx_flag (du_io_flush_bits_robIdx_flag),
    .io_flush_bits_robIdx_value (du_io_flush_bits_robIdx_value),
    .io_flush_bits_level (du_io_flush_bits_level),
    .io_in_ready (g_du_io_in_ready),
    .io_in_valid (du_io_in_valid),
    .io_in_bits_ctrl_fuOpType (du_io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_robIdx_flag (du_io_in_bits_ctrl_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value (du_io_in_bits_ctrl_robIdx_value),
    .io_in_bits_ctrl_pdest (du_io_in_bits_ctrl_pdest),
    .io_in_bits_ctrl_rfWen (du_io_in_bits_ctrl_rfWen),
    .io_in_bits_data_src_1 (du_io_in_bits_data_src_1),
    .io_in_bits_data_src_0 (du_io_in_bits_data_src_0),
    .io_in_bits_perfDebugInfo_eliminatedMove (du_io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime (du_io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime (du_io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime (du_io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime (du_io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime (du_io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime (du_io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id (du_io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime (du_io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime (du_io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum (du_io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx (du_io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready (du_io_out_ready),
    .io_out_valid (g_du_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag (g_du_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value (g_du_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest (g_du_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_rfWen (g_du_io_out_bits_ctrl_rfWen),
    .io_out_bits_res_data (g_du_io_out_bits_res_data),
    .io_out_bits_perfDebugInfo_eliminatedMove (g_du_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime (g_du_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime (g_du_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime (g_du_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime (g_du_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime (g_du_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime (g_du_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id (g_du_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime (g_du_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime (g_du_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum (g_du_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx (g_du_io_out_bits_debug_seqNum_uopIdx)
  );
  DivUnit_xs u_i_du (
    .clock (clock),
    .reset (reset),
    .io_flush_valid (du_io_flush_valid),
    .io_flush_bits_robIdx_flag (du_io_flush_bits_robIdx_flag),
    .io_flush_bits_robIdx_value (du_io_flush_bits_robIdx_value),
    .io_flush_bits_level (du_io_flush_bits_level),
    .io_in_ready (i_du_io_in_ready),
    .io_in_valid (du_io_in_valid),
    .io_in_bits_ctrl_fuOpType (du_io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_robIdx_flag (du_io_in_bits_ctrl_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value (du_io_in_bits_ctrl_robIdx_value),
    .io_in_bits_ctrl_pdest (du_io_in_bits_ctrl_pdest),
    .io_in_bits_ctrl_rfWen (du_io_in_bits_ctrl_rfWen),
    .io_in_bits_data_src_1 (du_io_in_bits_data_src_1),
    .io_in_bits_data_src_0 (du_io_in_bits_data_src_0),
    .io_in_bits_perfDebugInfo_eliminatedMove (du_io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime (du_io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime (du_io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime (du_io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime (du_io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime (du_io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime (du_io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id (du_io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime (du_io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime (du_io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum (du_io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx (du_io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready (du_io_out_ready),
    .io_out_valid (i_du_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag (i_du_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value (i_du_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest (i_du_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_rfWen (i_du_io_out_bits_ctrl_rfWen),
    .io_out_bits_res_data (i_du_io_out_bits_res_data),
    .io_out_bits_perfDebugInfo_eliminatedMove (i_du_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime (i_du_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime (i_du_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime (i_du_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime (i_du_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime (i_du_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime (i_du_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id (i_du_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime (i_du_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime (i_du_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum (i_du_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx (i_du_io_out_bits_debug_seqNum_uopIdx)
  );
  wire [576:0] g_du_perf_c = {g_du_io_out_bits_perfDebugInfo_eliminatedMove,g_du_io_out_bits_perfDebugInfo_renameTime,g_du_io_out_bits_perfDebugInfo_dispatchTime,g_du_io_out_bits_perfDebugInfo_enqRsTime,g_du_io_out_bits_perfDebugInfo_selectTime,g_du_io_out_bits_perfDebugInfo_issueTime,g_du_io_out_bits_perfDebugInfo_writebackTime,g_du_io_out_bits_perfDebugInfo_runahead_checkpoint_id,g_du_io_out_bits_perfDebugInfo_tlbFirstReqTime,g_du_io_out_bits_perfDebugInfo_tlbRespTime};
  wire [576:0] i_du_perf_c = {i_du_io_out_bits_perfDebugInfo_eliminatedMove,i_du_io_out_bits_perfDebugInfo_renameTime,i_du_io_out_bits_perfDebugInfo_dispatchTime,i_du_io_out_bits_perfDebugInfo_enqRsTime,i_du_io_out_bits_perfDebugInfo_selectTime,i_du_io_out_bits_perfDebugInfo_issueTime,i_du_io_out_bits_perfDebugInfo_writebackTime,i_du_io_out_bits_perfDebugInfo_runahead_checkpoint_id,i_du_io_out_bits_perfDebugInfo_tlbFirstReqTime,i_du_io_out_bits_perfDebugInfo_tlbRespTime};
  wire [17:0] g_du_ctrl_c = {g_du_io_out_bits_ctrl_robIdx_flag,g_du_io_out_bits_ctrl_robIdx_value,g_du_io_out_bits_ctrl_pdest,g_du_io_out_bits_ctrl_rfWen};
  wire [17:0] i_du_ctrl_c = {i_du_io_out_bits_ctrl_robIdx_flag,i_du_io_out_bits_ctrl_robIdx_value,i_du_io_out_bits_ctrl_pdest,i_du_io_out_bits_ctrl_rfWen};
  wire [63:0] g_du_dbg_c = {g_du_io_out_bits_debug_seqNum_seqNum, g_du_io_out_bits_debug_seqNum_uopIdx};
  wire [63:0] i_du_dbg_c = {i_du_io_out_bits_debug_seqNum_seqNum, i_du_io_out_bits_debug_seqNum_uopIdx};

  // ================= FDivSqrt（时序包装层）=================
  logic  fd_io_flush_valid;
  logic  fd_io_flush_bits_robIdx_flag;
  logic [7:0]  fd_io_flush_bits_robIdx_value;
  logic  fd_io_flush_bits_level;
  wire  g_fd_io_in_ready;
  wire  i_fd_io_in_ready;
  logic  fd_io_in_valid;
  logic [8:0]  fd_io_in_bits_ctrl_fuOpType;
  logic  fd_io_in_bits_ctrl_robIdx_flag;
  logic [7:0]  fd_io_in_bits_ctrl_robIdx_value;
  logic [7:0]  fd_io_in_bits_ctrl_pdest;
  logic  fd_io_in_bits_ctrl_fpWen;
  logic  fd_io_in_bits_ctrl_fpu_wflags;
  logic [1:0]  fd_io_in_bits_ctrl_fpu_fmt;
  logic [2:0]  fd_io_in_bits_ctrl_fpu_rm;
  logic [63:0]  fd_io_in_bits_data_src_1;
  logic [63:0]  fd_io_in_bits_data_src_0;
  logic  fd_io_in_bits_perfDebugInfo_eliminatedMove;
  logic [63:0]  fd_io_in_bits_perfDebugInfo_renameTime;
  logic [63:0]  fd_io_in_bits_perfDebugInfo_dispatchTime;
  logic [63:0]  fd_io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0]  fd_io_in_bits_perfDebugInfo_selectTime;
  logic [63:0]  fd_io_in_bits_perfDebugInfo_issueTime;
  logic [63:0]  fd_io_in_bits_perfDebugInfo_writebackTime;
  logic [63:0]  fd_io_in_bits_perfDebugInfo_runahead_checkpoint_id;
  logic [63:0]  fd_io_in_bits_perfDebugInfo_tlbFirstReqTime;
  logic [63:0]  fd_io_in_bits_perfDebugInfo_tlbRespTime;
  logic [55:0]  fd_io_in_bits_debug_seqNum_seqNum;
  logic [7:0]  fd_io_in_bits_debug_seqNum_uopIdx;
  logic  fd_io_out_ready;
  wire  g_fd_io_out_valid;
  wire  i_fd_io_out_valid;
  wire  g_fd_io_out_bits_ctrl_robIdx_flag;
  wire  i_fd_io_out_bits_ctrl_robIdx_flag;
  wire [7:0]  g_fd_io_out_bits_ctrl_robIdx_value;
  wire [7:0]  i_fd_io_out_bits_ctrl_robIdx_value;
  wire [7:0]  g_fd_io_out_bits_ctrl_pdest;
  wire [7:0]  i_fd_io_out_bits_ctrl_pdest;
  wire  g_fd_io_out_bits_ctrl_fpWen;
  wire  i_fd_io_out_bits_ctrl_fpWen;
  wire  g_fd_io_out_bits_ctrl_fpu_wflags;
  wire  i_fd_io_out_bits_ctrl_fpu_wflags;
  wire [63:0]  g_fd_io_out_bits_res_data;
  wire [63:0]  i_fd_io_out_bits_res_data;
  wire [4:0]  g_fd_io_out_bits_res_fflags;
  wire [4:0]  i_fd_io_out_bits_res_fflags;
  wire  g_fd_io_out_bits_perfDebugInfo_eliminatedMove;
  wire  i_fd_io_out_bits_perfDebugInfo_eliminatedMove;
  wire [63:0]  g_fd_io_out_bits_perfDebugInfo_renameTime;
  wire [63:0]  i_fd_io_out_bits_perfDebugInfo_renameTime;
  wire [63:0]  g_fd_io_out_bits_perfDebugInfo_dispatchTime;
  wire [63:0]  i_fd_io_out_bits_perfDebugInfo_dispatchTime;
  wire [63:0]  g_fd_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0]  i_fd_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0]  g_fd_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0]  i_fd_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0]  g_fd_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0]  i_fd_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0]  g_fd_io_out_bits_perfDebugInfo_writebackTime;
  wire [63:0]  i_fd_io_out_bits_perfDebugInfo_writebackTime;
  wire [63:0]  g_fd_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0]  i_fd_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0]  g_fd_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0]  i_fd_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0]  g_fd_io_out_bits_perfDebugInfo_tlbRespTime;
  wire [63:0]  i_fd_io_out_bits_perfDebugInfo_tlbRespTime;
  wire [55:0]  g_fd_io_out_bits_debug_seqNum_seqNum;
  wire [55:0]  i_fd_io_out_bits_debug_seqNum_seqNum;
  wire [7:0]  g_fd_io_out_bits_debug_seqNum_uopIdx;
  wire [7:0]  i_fd_io_out_bits_debug_seqNum_uopIdx;
  logic [2:0]  fd_io_frm;
  FDivSqrt u_g_fd (
    .clock (clock),
    .reset (reset),
    .io_flush_valid (fd_io_flush_valid),
    .io_flush_bits_robIdx_flag (fd_io_flush_bits_robIdx_flag),
    .io_flush_bits_robIdx_value (fd_io_flush_bits_robIdx_value),
    .io_flush_bits_level (fd_io_flush_bits_level),
    .io_in_ready (g_fd_io_in_ready),
    .io_in_valid (fd_io_in_valid),
    .io_in_bits_ctrl_fuOpType (fd_io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_robIdx_flag (fd_io_in_bits_ctrl_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value (fd_io_in_bits_ctrl_robIdx_value),
    .io_in_bits_ctrl_pdest (fd_io_in_bits_ctrl_pdest),
    .io_in_bits_ctrl_fpWen (fd_io_in_bits_ctrl_fpWen),
    .io_in_bits_ctrl_fpu_wflags (fd_io_in_bits_ctrl_fpu_wflags),
    .io_in_bits_ctrl_fpu_fmt (fd_io_in_bits_ctrl_fpu_fmt),
    .io_in_bits_ctrl_fpu_rm (fd_io_in_bits_ctrl_fpu_rm),
    .io_in_bits_data_src_1 (fd_io_in_bits_data_src_1),
    .io_in_bits_data_src_0 (fd_io_in_bits_data_src_0),
    .io_in_bits_perfDebugInfo_eliminatedMove (fd_io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime (fd_io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime (fd_io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime (fd_io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime (fd_io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime (fd_io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime (fd_io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id (fd_io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime (fd_io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime (fd_io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum (fd_io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx (fd_io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready (fd_io_out_ready),
    .io_out_valid (g_fd_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag (g_fd_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value (g_fd_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest (g_fd_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_fpWen (g_fd_io_out_bits_ctrl_fpWen),
    .io_out_bits_ctrl_fpu_wflags (g_fd_io_out_bits_ctrl_fpu_wflags),
    .io_out_bits_res_data (g_fd_io_out_bits_res_data),
    .io_out_bits_res_fflags (g_fd_io_out_bits_res_fflags),
    .io_out_bits_perfDebugInfo_eliminatedMove (g_fd_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime (g_fd_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime (g_fd_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime (g_fd_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime (g_fd_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime (g_fd_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime (g_fd_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id (g_fd_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime (g_fd_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime (g_fd_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum (g_fd_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx (g_fd_io_out_bits_debug_seqNum_uopIdx),
    .io_frm (fd_io_frm)
  );
  FDivSqrt_xs u_i_fd (
    .clock (clock),
    .reset (reset),
    .io_flush_valid (fd_io_flush_valid),
    .io_flush_bits_robIdx_flag (fd_io_flush_bits_robIdx_flag),
    .io_flush_bits_robIdx_value (fd_io_flush_bits_robIdx_value),
    .io_flush_bits_level (fd_io_flush_bits_level),
    .io_in_ready (i_fd_io_in_ready),
    .io_in_valid (fd_io_in_valid),
    .io_in_bits_ctrl_fuOpType (fd_io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_robIdx_flag (fd_io_in_bits_ctrl_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value (fd_io_in_bits_ctrl_robIdx_value),
    .io_in_bits_ctrl_pdest (fd_io_in_bits_ctrl_pdest),
    .io_in_bits_ctrl_fpWen (fd_io_in_bits_ctrl_fpWen),
    .io_in_bits_ctrl_fpu_wflags (fd_io_in_bits_ctrl_fpu_wflags),
    .io_in_bits_ctrl_fpu_fmt (fd_io_in_bits_ctrl_fpu_fmt),
    .io_in_bits_ctrl_fpu_rm (fd_io_in_bits_ctrl_fpu_rm),
    .io_in_bits_data_src_1 (fd_io_in_bits_data_src_1),
    .io_in_bits_data_src_0 (fd_io_in_bits_data_src_0),
    .io_in_bits_perfDebugInfo_eliminatedMove (fd_io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime (fd_io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime (fd_io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime (fd_io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime (fd_io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime (fd_io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime (fd_io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id (fd_io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime (fd_io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime (fd_io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum (fd_io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx (fd_io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready (fd_io_out_ready),
    .io_out_valid (i_fd_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag (i_fd_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value (i_fd_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest (i_fd_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_fpWen (i_fd_io_out_bits_ctrl_fpWen),
    .io_out_bits_ctrl_fpu_wflags (i_fd_io_out_bits_ctrl_fpu_wflags),
    .io_out_bits_res_data (i_fd_io_out_bits_res_data),
    .io_out_bits_res_fflags (i_fd_io_out_bits_res_fflags),
    .io_out_bits_perfDebugInfo_eliminatedMove (i_fd_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime (i_fd_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime (i_fd_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime (i_fd_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime (i_fd_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime (i_fd_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime (i_fd_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id (i_fd_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime (i_fd_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime (i_fd_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum (i_fd_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx (i_fd_io_out_bits_debug_seqNum_uopIdx),
    .io_frm (fd_io_frm)
  );
  wire [576:0] g_fd_perf_c = {g_fd_io_out_bits_perfDebugInfo_eliminatedMove,g_fd_io_out_bits_perfDebugInfo_renameTime,g_fd_io_out_bits_perfDebugInfo_dispatchTime,g_fd_io_out_bits_perfDebugInfo_enqRsTime,g_fd_io_out_bits_perfDebugInfo_selectTime,g_fd_io_out_bits_perfDebugInfo_issueTime,g_fd_io_out_bits_perfDebugInfo_writebackTime,g_fd_io_out_bits_perfDebugInfo_runahead_checkpoint_id,g_fd_io_out_bits_perfDebugInfo_tlbFirstReqTime,g_fd_io_out_bits_perfDebugInfo_tlbRespTime};
  wire [576:0] i_fd_perf_c = {i_fd_io_out_bits_perfDebugInfo_eliminatedMove,i_fd_io_out_bits_perfDebugInfo_renameTime,i_fd_io_out_bits_perfDebugInfo_dispatchTime,i_fd_io_out_bits_perfDebugInfo_enqRsTime,i_fd_io_out_bits_perfDebugInfo_selectTime,i_fd_io_out_bits_perfDebugInfo_issueTime,i_fd_io_out_bits_perfDebugInfo_writebackTime,i_fd_io_out_bits_perfDebugInfo_runahead_checkpoint_id,i_fd_io_out_bits_perfDebugInfo_tlbFirstReqTime,i_fd_io_out_bits_perfDebugInfo_tlbRespTime};
  wire [18:0] g_fd_ctrl_c = {g_fd_io_out_bits_ctrl_robIdx_flag,g_fd_io_out_bits_ctrl_robIdx_value,g_fd_io_out_bits_ctrl_pdest,g_fd_io_out_bits_ctrl_fpWen,g_fd_io_out_bits_ctrl_fpu_wflags};
  wire [18:0] i_fd_ctrl_c = {i_fd_io_out_bits_ctrl_robIdx_flag,i_fd_io_out_bits_ctrl_robIdx_value,i_fd_io_out_bits_ctrl_pdest,i_fd_io_out_bits_ctrl_fpWen,i_fd_io_out_bits_ctrl_fpu_wflags};
  wire [63:0] g_fd_dbg_c = {g_fd_io_out_bits_debug_seqNum_seqNum, g_fd_io_out_bits_debug_seqNum_uopIdx};
  wire [63:0] i_fd_dbg_c = {i_fd_io_out_bits_debug_seqNum_seqNum, i_fd_io_out_bits_debug_seqNum_uopIdx};

  // ---- 握手/覆盖计数 ----
  longint du_in_fires, du_out_fires, du_isw_fires, du_sign_fires, flush_cycles;
  longint fd_in_fires, fd_out_fires, fd_sqrt_fires, fd_div_fires;
  longint fd_fmt_fires [4];
  bit du_armed, fd_armed;


  // ================= 激励 =================
  task automatic drive_all();
    // —— 组合三叶 ——
    for (int j = 0; j < 8; j++) ac_din[j] = $urandom;
    ac_rnd = $urandom;
    ac_nclip = $urandom & 1;
    // sew_oneHot：一半时间给合法 one-hot，一半时间给任意值（覆盖非 one-hot 容错）
    ac_sew = ($urandom & 1) ? (4'b0001 << ($urandom & 3)) : $urandom;
    dec_op = $urandom;
    va_op = $urandom;
    va_vm = $urandom & 1;  va_ma = $urandom & 1;
    va_sub = $urandom & 1; va_widen = $urandom & 1; va_widen2 = $urandom & 1;
    va_uopidx = $urandom;
    va_st1 = $urandom; va_vdt = $urandom;
    va_vs1 = rnd64(); va_vs2 = rnd64();
    va_vmask = $urandom; va_oldvd = $urandom;
    // —— DivUnit ——
    du_io_in_valid = $urandom & 1;
    du_io_in_bits_ctrl_fuOpType = $urandom;
    du_io_in_bits_ctrl_robIdx_flag = $urandom & 1;
    du_io_in_bits_ctrl_robIdx_value = $urandom;
    du_io_in_bits_ctrl_pdest = $urandom;
    du_io_in_bits_ctrl_rfWen = $urandom & 1;
    du_io_in_bits_data_src_1 = rnd64();
    du_io_in_bits_data_src_0 = rnd64();
    du_io_in_bits_perfDebugInfo_eliminatedMove = $urandom & 1;
    du_io_in_bits_perfDebugInfo_renameTime = rnd64();
    du_io_in_bits_perfDebugInfo_dispatchTime = rnd64();
    du_io_in_bits_perfDebugInfo_enqRsTime = rnd64();
    du_io_in_bits_perfDebugInfo_selectTime = rnd64();
    du_io_in_bits_perfDebugInfo_issueTime = rnd64();
    du_io_in_bits_perfDebugInfo_writebackTime = rnd64();
    du_io_in_bits_perfDebugInfo_runahead_checkpoint_id = rnd64();
    du_io_in_bits_perfDebugInfo_tlbFirstReqTime = rnd64();
    du_io_in_bits_perfDebugInfo_tlbRespTime = rnd64();
    du_io_in_bits_debug_seqNum_seqNum = {rnd64(), rnd64()};
    du_io_in_bits_debug_seqNum_uopIdx = $urandom;
    du_io_out_ready = ($urandom % 4) != 0;
    // —— FDivSqrt ——
    fd_io_in_valid = $urandom & 1;
    fd_io_in_bits_ctrl_fuOpType = $urandom;
    fd_io_in_bits_ctrl_robIdx_flag = $urandom & 1;
    fd_io_in_bits_ctrl_robIdx_value = $urandom;
    fd_io_in_bits_ctrl_pdest = $urandom;
    fd_io_in_bits_ctrl_fpWen = $urandom & 1;
    fd_io_in_bits_ctrl_fpu_wflags = $urandom & 1;
    fd_io_in_bits_ctrl_fpu_fmt = $urandom;
    fd_io_in_bits_ctrl_fpu_rm = $urandom;
    fd_io_in_bits_data_src_1 = rnd64();
    fd_io_in_bits_data_src_0 = rnd64();
    fd_io_in_bits_perfDebugInfo_eliminatedMove = $urandom & 1;
    fd_io_in_bits_perfDebugInfo_renameTime = rnd64();
    fd_io_in_bits_perfDebugInfo_dispatchTime = rnd64();
    fd_io_in_bits_perfDebugInfo_enqRsTime = rnd64();
    fd_io_in_bits_perfDebugInfo_selectTime = rnd64();
    fd_io_in_bits_perfDebugInfo_issueTime = rnd64();
    fd_io_in_bits_perfDebugInfo_writebackTime = rnd64();
    fd_io_in_bits_perfDebugInfo_runahead_checkpoint_id = rnd64();
    fd_io_in_bits_perfDebugInfo_tlbFirstReqTime = rnd64();
    fd_io_in_bits_perfDebugInfo_tlbRespTime = rnd64();
    fd_io_in_bits_debug_seqNum_seqNum = {rnd64(), rnd64()};
    fd_io_in_bits_debug_seqNum_uopIdx = $urandom;
    fd_io_out_ready = ($urandom % 4) != 0;
    fd_io_frm = $urandom;
    // —— 共享 flush（约 3% 拍）——
    du_io_flush_valid = ($urandom % 32) == 0;
    fd_io_flush_valid = du_io_flush_valid;
    du_io_flush_bits_robIdx_flag = $urandom & 1;
    fd_io_flush_bits_robIdx_flag = du_io_flush_bits_robIdx_flag;
    du_io_flush_bits_robIdx_value = $urandom;
    fd_io_flush_bits_robIdx_value = du_io_flush_bits_robIdx_value;
    du_io_flush_bits_level = $urandom & 1;
    fd_io_flush_bits_level = du_io_flush_bits_level;
  endtask

  // ================= 逐拍比对 =================
  task automatic check_all();
    // —— Adder_chain_rnd ——
    cmp("ac.dout",  g_ac_dout_c, i_ac_dout_c);
    cmp("ac.cout",  64'(g_ac_cout), 64'(i_ac_cout));
    cmp("ac.all1s", 64'(g_ac_a1),   64'(i_ac_a1));
    cmp("ac.all0s", 64'(g_ac_a0),   64'(i_ac_a0));
    // —— VIAluDecoder ——
    cmp("dec.opcode", 64'(g_dec_opcode), 64'(i_dec_opcode));
    cmp("dec.srcType2", 64'(g_dec_st2),  64'(i_dec_st2));
    cmp("dec.vdType",  64'(g_dec_vdt),   64'(i_dec_vdt));
    // —— VIntAdder64b ——
    cmp("va.vd",     g_va_vd,    i_va_vd);
    cmp("va.cmpOut", 64'(g_va_cmp),  64'(i_va_cmp));
    cmp("va.fcout",  64'(g_va_fcout), 64'(i_va_fcout));
    cmp("va.fvd",    g_va_fvd,   i_va_fvd);
    cmp("va.vs2h",   64'(g_va_vs2h), 64'(i_va_vs2h));
    cmp("va.vs1h",   64'(g_va_vs1h), 64'(i_va_vs1h));
    // —— DivUnit：握手/数据恒比对；无复位 payload 由 armed 闸把守 ——
    cmp("du.in_ready",  64'(g_du_io_in_ready), 64'(i_du_io_in_ready));
    cmp("du.out_valid", 64'(g_du_io_out_valid), 64'(i_du_io_out_valid));
    cmp("du.res_data",  g_du_io_out_bits_res_data, i_du_io_out_bits_res_data);
    if (du_armed) begin
      cmp("du.ctrl", g_du_ctrl_c, i_du_ctrl_c);
      cmp("du.perf", g_du_perf_c, i_du_perf_c);
      cmp("du.dbg",  g_du_dbg_c,  i_du_dbg_c);
    end
    // —— FDivSqrt ——
    cmp("fd.in_ready",  64'(g_fd_io_in_ready), 64'(i_fd_io_in_ready));
    cmp("fd.out_valid", 64'(g_fd_io_out_valid), 64'(i_fd_io_out_valid));
    cmp("fd.res_data",  g_fd_io_out_bits_res_data, i_fd_io_out_bits_res_data);
    cmp("fd.fflags",    64'(g_fd_io_out_bits_res_fflags), 64'(i_fd_io_out_bits_res_fflags));
    if (fd_armed) begin
      cmp("fd.ctrl", g_fd_ctrl_c, i_fd_ctrl_c);
      cmp("fd.perf", g_fd_perf_c, i_fd_perf_c);
      cmp("fd.dbg",  g_fd_dbg_c,  i_fd_dbg_c);
    end
  endtask

  // ================= 翻转与覆盖采样 =================
  task automatic sample_all();
    tog(0,  g_ac_dout_c);
    tog(1,  64'(g_ac_cout));
    tog(2,  64'(g_ac_a1));
    tog(3,  64'(g_ac_a0));
    tog(4,  64'(g_dec_opcode));
    tog(5,  64'(g_dec_st2));
    tog(6,  64'(g_dec_vdt));
    tog(7,  g_va_vd);
    tog(8,  64'(g_va_cmp));
    tog(9,  64'(g_va_fcout));
    tog(10, g_va_fvd);
    tog(11, 64'(g_va_vs2h));
    tog(12, 64'(g_va_vs1h));
    tog(13, 64'(g_du_io_in_ready));
    tog(14, 64'(g_du_io_out_valid));
    tog(15, g_du_io_out_bits_res_data);
    tog(16, g_du_ctrl_c);
    tog(17, g_du_perf_c);
    tog(18, g_du_dbg_c);
    tog(19, 64'(g_fd_io_in_ready));
    tog(20, 64'(g_fd_io_out_valid));
    tog(21, g_fd_io_out_bits_res_data);
    tog(22, 64'(g_fd_io_out_bits_res_fflags));
    tog(23, g_fd_ctrl_c);
    tog(24, g_fd_perf_c);
    tog(25, g_fd_dbg_c);
    // —— Adder sew 桶 ——
    for (int s = 0; s < 4; s++)
      if (ac_sew == (4'b0001 << s)) ac_sew_bucket[s*2 + ac_nclip]++;
    // —— 译码器命中 ——
    dec_hit[dec_op]++;
    case (dec_op)
      8'h39: dec_op_seen[0]  = 1'b1;
      8'h3A: dec_op_seen[1]  = 1'b1;
      8'h3B: dec_op_seen[2]  = 1'b1;
      8'h3C: dec_op_seen[3]  = 1'b1;
      8'h3D: dec_op_seen[4]  = 1'b1;
      8'h3E: dec_op_seen[5]  = 1'b1;
      8'h3F: dec_op_seen[6]  = 1'b1;
      8'h40: dec_op_seen[7]  = 1'b1;
      8'h41: dec_op_seen[8]  = 1'b1;
      8'h42: dec_op_seen[9]  = 1'b1;
      8'h4B: dec_op_seen[10] = 1'b1;
      8'h4C: dec_op_seen[11] = 1'b1;
      8'h4D: dec_op_seen[12] = 1'b1;
      8'h4E: dec_op_seen[13] = 1'b1;
      8'h4F: dec_op_seen[14] = 1'b1;
      8'h50: dec_op_seen[15] = 1'b1;
      8'h51: dec_op_seen[16] = 1'b1;
      8'h53: dec_op_seen[17] = 1'b1;
      default: ;
    endcase
    // —— VIntAdder 覆盖 ——
    va_op_seen[va_op] = 1'b1;
    if (va_widen)  va_widen_cnt++;
    if (va_widen2) va_widen2_cnt++;
    if (va_sub)    va_sub_cnt++;
    if (va_st1[3:2] == 2'd1) va_signed_cnt++;
    va_eew_cnt[va_st1[1:0]]++;
    // —— DivUnit / FDivSqrt 握手 ——
    if (du_io_flush_valid) flush_cycles++;
    if (du_io_in_valid && g_du_io_in_ready) begin
      du_in_fires++;
      du_armed = 1'b1;
      if (du_io_in_bits_ctrl_fuOpType[2]) du_isw_fires++;
      if (~du_io_in_bits_ctrl_fuOpType[1]) du_sign_fires++;
    end
    if (g_du_io_out_valid && du_io_out_ready) du_out_fires++;
    if (fd_io_in_valid && g_fd_io_in_ready) begin
      fd_in_fires++;
      fd_armed = 1'b1;
      if (fd_io_in_bits_ctrl_fuOpType[0]) fd_sqrt_fires++; else fd_div_fires++;
      fd_fmt_fires[fd_io_in_bits_ctrl_fpu_fmt]++;
    end
    if (g_fd_io_out_valid && fd_io_out_ready) fd_out_fires++;
  endtask

  // ================= 主流程 =================
  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    tog_mask = '0;
    for (int k = 0; k < N_TOG; k++) tog_prev[k] = '0;
    for (int k = 0; k < 8; k++) ac_sew_bucket[k] = 0;
    for (int k = 0; k < 256; k++) dec_hit[k] = 0;
    for (int k = 0; k < 4; k++) begin va_eew_cnt[k] = 0; fd_fmt_fires[k] = 0; end
    dec_op_seen = '0;
    va_op_seen = '0;
    va_widen_cnt = 0; va_widen2_cnt = 0; va_sub_cnt = 0; va_signed_cnt = 0;
    du_in_fires = 0; du_out_fires = 0; du_isw_fires = 0; du_sign_fires = 0; flush_cycles = 0;
    fd_in_fires = 0; fd_out_fires = 0; fd_sqrt_fires = 0; fd_div_fires = 0;
    du_armed = 0; fd_armed = 0;

    drive_all();   // 先清成一组确定值
    reset = 1'b1;
    repeat (5) @(posedge clock);
    @(negedge clock) reset = 1'b0;
    for (int unsigned c = 0; c < NCYCLES; c++) begin
      // 中途再复位一次，覆盖复位路径（两侧同拍同源）
      if (c == NCYCLES/2) begin
        reset = 1'b1;
        repeat (3) @(posedge clock);
        @(negedge clock) reset = 1'b0;
      end
      @(negedge clock);
      drive_all();
      #1 check_all();
      sample_all();
      @(posedge clock);
    end

    begin
      int unsigned toggled;
      longint dec_total;
      toggled = $countones(tog_mask);
      dec_total = 0;
      for (int k = 0; k < 256; k++) dec_total += dec_hit[k];
      for (int k = 0; k < N_TOG; k++)
        if (!tog_mask[k]) $display("COV: output group %0d never toggled", k);
      $display("ArithVecLeaves5 checks=%0d errors=%0d toggled=%0d/%0d", checks, errors, toggled, N_TOG);
      $display("COV ac_sew_buckets=%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d",
               ac_sew_bucket[0], ac_sew_bucket[1], ac_sew_bucket[2], ac_sew_bucket[3],
               ac_sew_bucket[4], ac_sew_bucket[5], ac_sew_bucket[6], ac_sew_bucket[7]);
      $display("COV dec_hit_total=%0d op_seen=%b", dec_total, dec_op_seen);
      $display("COV va widen=%0d widen2=%0d sub=%0d signed=%0d eew=%0d,%0d,%0d,%0d",
               va_widen_cnt, va_widen2_cnt, va_sub_cnt, va_signed_cnt,
               va_eew_cnt[0], va_eew_cnt[1], va_eew_cnt[2], va_eew_cnt[3]);
      $display("COV du in=%0d out=%0d isW=%0d sign=%0d flush=%0d | fd in=%0d out=%0d sqrt=%0d div=%0d fmt=%0d,%0d,%0d,%0d",
               du_in_fires, du_out_fires, du_isw_fires, du_sign_fires, flush_cycles,
               fd_in_fires, fd_out_fires, fd_sqrt_fires, fd_div_fires,
               fd_fmt_fires[0], fd_fmt_fires[1], fd_fmt_fires[2], fd_fmt_fires[3]);
      if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
      if (checks == 0) begin $display("TEST FAILED (coverage: no comparison happened)"); $fatal(1); end
      if (toggled < N_TOG) begin
        $display("TEST FAILED (coverage: only %0d/%0d output groups toggled)", toggled, N_TOG);
        $fatal(1);
      end
      for (int k = 0; k < 8; k++)
        if (ac_sew_bucket[k] < 100) begin
          $display("TEST FAILED (coverage: ac sew bucket %0d only %0d)", k, ac_sew_bucket[k]);
          $fatal(1);
        end
      if (dec_op_seen != 18'h3FFFF) begin
        $display("TEST FAILED (coverage: decoder ops seen %b != 18'h3FFFF)", dec_op_seen);
        $fatal(1);
      end
      if (dec_hit[8'h39] < 50 || dec_hit[8'h53] < 50) begin
        $display("TEST FAILED (coverage: decoder hit counts too thin)");
        $fatal(1);
      end
      // vadd/vsub/vadc/vmadc/vsbc/vmsbc/vmseq/vmsne/vmslt/vmsle/vmsgt/vmin/vmax
      if ({va_op_seen[6'h18], va_op_seen[6'h17], va_op_seen[6'h16], va_op_seen[6'h15],
           va_op_seen[6'h14], va_op_seen[6'h13], va_op_seen[6'h12], va_op_seen[6'h06],
           va_op_seen[6'h05], va_op_seen[6'h04], va_op_seen[6'h03], va_op_seen[6'h01],
           va_op_seen[6'h00]} != 13'h1FFF) begin
        $display("TEST FAILED (coverage: VIntAdder opcode not all seen)");
        $fatal(1);
      end
      if (va_widen_cnt < 1000 || va_widen2_cnt < 1000 || va_sub_cnt < 1000 || va_signed_cnt < 1000) begin
        $display("TEST FAILED (coverage: VIntAdder widen/sub/signed too thin)");
        $fatal(1);
      end
      for (int k = 0; k < 4; k++)
        if (va_eew_cnt[k] < 1000) begin
          $display("TEST FAILED (coverage: VIntAdder eew %0d only %0d)", k, va_eew_cnt[k]);
          $fatal(1);
        end
      if (du_in_fires < 500 || du_out_fires < 500) begin
        $display("TEST FAILED (coverage: DivUnit fires in=%0d out=%0d)", du_in_fires, du_out_fires);
        $fatal(1);
      end
      if (du_isw_fires < 100 || du_sign_fires < 100) begin
        $display("TEST FAILED (coverage: DivUnit isW/sign fires %0d/%0d)", du_isw_fires, du_sign_fires);
        $fatal(1);
      end
      if (flush_cycles < 1000) begin
        $display("TEST FAILED (coverage: flush only %0d cycles)", flush_cycles);
        $fatal(1);
      end
      if (fd_in_fires < 200 || fd_out_fires < 200) begin
        $display("TEST FAILED (coverage: FDivSqrt fires in=%0d out=%0d)", fd_in_fires, fd_out_fires);
        $fatal(1);
      end
      if (fd_sqrt_fires < 50 || fd_div_fires < 50) begin
        $display("TEST FAILED (coverage: FDivSqrt sqrt/div fires %0d/%0d)", fd_sqrt_fires, fd_div_fires);
        $fatal(1);
      end
      for (int k = 1; k < 4; k++)
        if (fd_fmt_fires[k] < 20) begin
          $display("TEST FAILED (coverage: FDivSqrt fmt %0d fires only %0d)", k, fd_fmt_fires[k]);
          $fatal(1);
        end
      $display("TEST PASSED");
    end
    $finish;
  end
endmodule

