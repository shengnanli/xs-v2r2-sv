// =============================================================================
// tb —— VCVT_8 UT：golden VCVT_8 与重写 VCVT_8_xs 双例化，逐拍比全部 25 个输出口。
//
// 激励（每拍）：
//   io_in_valid 70%；io_out_ready 90% 为 1（偶尔反压，golden 的 valid 链不受 ready 门控，照比）；
//   fuOpType 92% = {0, pick_op 的 opType}，8% 任意 9 位；vsew = pick_op 的 sew；vlmul 均匀 8 种；
//   vm 1/2；vuopIdx 75% 在 0..7、其余任意；vl（data_src_4）一半在 0..vlmax、一半任意；
//   v0（data_src_3）随机/全 0/全 1/稀疏；vs2（data_src_1）两半各按源元素宽度从定向池填；
//   frm 85% 在 0..4。ctrlPipe_2 / dataPipe_2 / validPipe_2：85% 的拍取「两拍前那条指令」的值
//   （与真实流水一致，Mgu 的合并才有意义），15% 任意；vstart / vta / vma / isDstMask / oldVd 随机。
//   perfDebugInfo / seqNum 全随机。复位：前 5 拍拉高，之后随机偶发。
// 覆盖（写进 PASS 判据）：每个合法 (opType, sew) × 生效舍入模式 0..4 >= 20 次（键里的 rm 是
//   RTZ/ROD 覆盖后真正送下去的那个）；vlmul 8 种各 >= 1000；变窄 × vuopIdx[0] 两值各 >= 500；
//   fflags 各位、res_data 非零都见过。
// =============================================================================
`timescale 1ns/1ps
module tb import cvt_tb_pkg::*; ;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0;
  int cyc;
  bit clock = 0;
  always #5 clock = ~clock;

  // ---- 输入 ----
  logic         reset;
  logic         io_in_valid;
  logic [8:0]   io_in_bits_ctrl_fuOpType;
  logic [1:0]   io_in_bits_ctrl_vpu_vsew;
  logic [2:0]   io_in_bits_ctrl_vpu_vlmul;
  logic         io_in_bits_ctrl_vpu_vm;
  logic [6:0]   io_in_bits_ctrl_vpu_vuopIdx;
  logic         io_in_bits_ctrlPipe_2_robIdx_flag;
  logic [7:0]   io_in_bits_ctrlPipe_2_robIdx_value;
  logic [7:0]   io_in_bits_ctrlPipe_2_pdest;
  logic         io_in_bits_ctrlPipe_2_vecWen;
  logic         io_in_bits_ctrlPipe_2_v0Wen;
  logic         io_in_bits_ctrlPipe_2_fpu_wflags;
  logic         io_in_bits_ctrlPipe_2_vpu_vma;
  logic         io_in_bits_ctrlPipe_2_vpu_vta;
  logic         io_in_bits_ctrlPipe_2_vpu_vm;
  logic [7:0]   io_in_bits_ctrlPipe_2_vpu_vstart;
  logic [6:0]   io_in_bits_ctrlPipe_2_vpu_vuopIdx;
  logic         io_in_bits_ctrlPipe_2_vpu_isDstMask;
  logic         io_in_bits_validPipe_2;
  logic [7:0]   io_in_bits_data_src_4;
  logic [127:0] io_in_bits_data_src_3;
  logic [127:0] io_in_bits_data_src_1;
  logic [7:0]   io_in_bits_dataPipe_2_src_4;
  logic [127:0] io_in_bits_dataPipe_2_src_3;
  logic [127:0] io_in_bits_dataPipe_2_src_2;
  logic         io_in_bits_perfDebugInfo_eliminatedMove;
  logic [63:0]  io_in_bits_perfDebugInfo_renameTime;
  logic [63:0]  io_in_bits_perfDebugInfo_dispatchTime;
  logic [63:0]  io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0]  io_in_bits_perfDebugInfo_selectTime;
  logic [63:0]  io_in_bits_perfDebugInfo_issueTime;
  logic [63:0]  io_in_bits_perfDebugInfo_writebackTime;
  logic [63:0]  io_in_bits_perfDebugInfo_runahead_checkpoint_id;
  logic [63:0]  io_in_bits_perfDebugInfo_tlbFirstReqTime;
  logic [63:0]  io_in_bits_perfDebugInfo_tlbRespTime;
  logic [55:0]  io_in_bits_debug_seqNum_seqNum;
  logic [7:0]   io_in_bits_debug_seqNum_uopIdx;
  logic         io_out_ready;
  logic [2:0]   io_frm;

  // ---- 输出（g_ = golden，i_ = 重写）----
  `define OUTS(P) \
    wire         P``io_in_ready; \
    wire         P``io_out_valid; \
    wire         P``io_out_bits_ctrl_robIdx_flag; \
    wire [7:0]   P``io_out_bits_ctrl_robIdx_value; \
    wire [7:0]   P``io_out_bits_ctrl_pdest; \
    wire         P``io_out_bits_ctrl_vecWen; \
    wire         P``io_out_bits_ctrl_v0Wen; \
    wire         P``io_out_bits_ctrl_fpu_wflags; \
    wire [127:0] P``io_out_bits_res_data; \
    wire [4:0]   P``io_out_bits_res_fflags; \
    wire         P``io_out_bits_perfDebugInfo_eliminatedMove; \
    wire [63:0]  P``io_out_bits_perfDebugInfo_renameTime; \
    wire [63:0]  P``io_out_bits_perfDebugInfo_dispatchTime; \
    wire [63:0]  P``io_out_bits_perfDebugInfo_enqRsTime; \
    wire [63:0]  P``io_out_bits_perfDebugInfo_selectTime; \
    wire [63:0]  P``io_out_bits_perfDebugInfo_issueTime; \
    wire [63:0]  P``io_out_bits_perfDebugInfo_writebackTime; \
    wire [63:0]  P``io_out_bits_perfDebugInfo_runahead_checkpoint_id; \
    wire [63:0]  P``io_out_bits_perfDebugInfo_tlbFirstReqTime; \
    wire [63:0]  P``io_out_bits_perfDebugInfo_tlbRespTime; \
    wire [55:0]  P``io_out_bits_debug_seqNum_seqNum; \
    wire [7:0]   P``io_out_bits_debug_seqNum_uopIdx;
  `OUTS(g_)
  `OUTS(i_)

  `define CONN(P) \
    .clock(clock), .reset(reset), .io_in_ready(P``io_in_ready), .io_in_valid(io_in_valid), \
    .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType), .io_in_bits_ctrl_vpu_vsew(io_in_bits_ctrl_vpu_vsew), \
    .io_in_bits_ctrl_vpu_vlmul(io_in_bits_ctrl_vpu_vlmul), .io_in_bits_ctrl_vpu_vm(io_in_bits_ctrl_vpu_vm), \
    .io_in_bits_ctrl_vpu_vuopIdx(io_in_bits_ctrl_vpu_vuopIdx), \
    .io_in_bits_ctrlPipe_2_robIdx_flag(io_in_bits_ctrlPipe_2_robIdx_flag), \
    .io_in_bits_ctrlPipe_2_robIdx_value(io_in_bits_ctrlPipe_2_robIdx_value), \
    .io_in_bits_ctrlPipe_2_pdest(io_in_bits_ctrlPipe_2_pdest), \
    .io_in_bits_ctrlPipe_2_vecWen(io_in_bits_ctrlPipe_2_vecWen), \
    .io_in_bits_ctrlPipe_2_v0Wen(io_in_bits_ctrlPipe_2_v0Wen), \
    .io_in_bits_ctrlPipe_2_fpu_wflags(io_in_bits_ctrlPipe_2_fpu_wflags), \
    .io_in_bits_ctrlPipe_2_vpu_vma(io_in_bits_ctrlPipe_2_vpu_vma), \
    .io_in_bits_ctrlPipe_2_vpu_vta(io_in_bits_ctrlPipe_2_vpu_vta), \
    .io_in_bits_ctrlPipe_2_vpu_vm(io_in_bits_ctrlPipe_2_vpu_vm), \
    .io_in_bits_ctrlPipe_2_vpu_vstart(io_in_bits_ctrlPipe_2_vpu_vstart), \
    .io_in_bits_ctrlPipe_2_vpu_vuopIdx(io_in_bits_ctrlPipe_2_vpu_vuopIdx), \
    .io_in_bits_ctrlPipe_2_vpu_isDstMask(io_in_bits_ctrlPipe_2_vpu_isDstMask), \
    .io_in_bits_validPipe_2(io_in_bits_validPipe_2), \
    .io_in_bits_data_src_4(io_in_bits_data_src_4), .io_in_bits_data_src_3(io_in_bits_data_src_3), \
    .io_in_bits_data_src_1(io_in_bits_data_src_1), \
    .io_in_bits_dataPipe_2_src_4(io_in_bits_dataPipe_2_src_4), \
    .io_in_bits_dataPipe_2_src_3(io_in_bits_dataPipe_2_src_3), \
    .io_in_bits_dataPipe_2_src_2(io_in_bits_dataPipe_2_src_2), \
    .io_in_bits_perfDebugInfo_eliminatedMove(io_in_bits_perfDebugInfo_eliminatedMove), \
    .io_in_bits_perfDebugInfo_renameTime(io_in_bits_perfDebugInfo_renameTime), \
    .io_in_bits_perfDebugInfo_dispatchTime(io_in_bits_perfDebugInfo_dispatchTime), \
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime), \
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime), \
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime), \
    .io_in_bits_perfDebugInfo_writebackTime(io_in_bits_perfDebugInfo_writebackTime), \
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(io_in_bits_perfDebugInfo_runahead_checkpoint_id), \
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(io_in_bits_perfDebugInfo_tlbFirstReqTime), \
    .io_in_bits_perfDebugInfo_tlbRespTime(io_in_bits_perfDebugInfo_tlbRespTime), \
    .io_in_bits_debug_seqNum_seqNum(io_in_bits_debug_seqNum_seqNum), \
    .io_in_bits_debug_seqNum_uopIdx(io_in_bits_debug_seqNum_uopIdx), \
    .io_out_ready(io_out_ready), .io_out_valid(P``io_out_valid), \
    .io_out_bits_ctrl_robIdx_flag(P``io_out_bits_ctrl_robIdx_flag), \
    .io_out_bits_ctrl_robIdx_value(P``io_out_bits_ctrl_robIdx_value), \
    .io_out_bits_ctrl_pdest(P``io_out_bits_ctrl_pdest), \
    .io_out_bits_ctrl_vecWen(P``io_out_bits_ctrl_vecWen), \
    .io_out_bits_ctrl_v0Wen(P``io_out_bits_ctrl_v0Wen), \
    .io_out_bits_ctrl_fpu_wflags(P``io_out_bits_ctrl_fpu_wflags), \
    .io_out_bits_res_data(P``io_out_bits_res_data), .io_out_bits_res_fflags(P``io_out_bits_res_fflags), \
    .io_out_bits_perfDebugInfo_eliminatedMove(P``io_out_bits_perfDebugInfo_eliminatedMove), \
    .io_out_bits_perfDebugInfo_renameTime(P``io_out_bits_perfDebugInfo_renameTime), \
    .io_out_bits_perfDebugInfo_dispatchTime(P``io_out_bits_perfDebugInfo_dispatchTime), \
    .io_out_bits_perfDebugInfo_enqRsTime(P``io_out_bits_perfDebugInfo_enqRsTime), \
    .io_out_bits_perfDebugInfo_selectTime(P``io_out_bits_perfDebugInfo_selectTime), \
    .io_out_bits_perfDebugInfo_issueTime(P``io_out_bits_perfDebugInfo_issueTime), \
    .io_out_bits_perfDebugInfo_writebackTime(P``io_out_bits_perfDebugInfo_writebackTime), \
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(P``io_out_bits_perfDebugInfo_runahead_checkpoint_id), \
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(P``io_out_bits_perfDebugInfo_tlbFirstReqTime), \
    .io_out_bits_perfDebugInfo_tlbRespTime(P``io_out_bits_perfDebugInfo_tlbRespTime), \
    .io_out_bits_debug_seqNum_seqNum(P``io_out_bits_debug_seqNum_seqNum), \
    .io_out_bits_debug_seqNum_uopIdx(P``io_out_bits_debug_seqNum_uopIdx), \
    .io_frm(io_frm)

  VCVT_8    u_g (`CONN(g_));
  VCVT_8_xs u_i (`CONN(i_));

  // ---- 逐拍全输出比较 ----
  `define CMP(nm) \
    begin checks++; if (g_``nm !== i_``nm) begin errors++; \
      if (errors <= 30) $display("[%0d] MISMATCH %s golden=%h impl=%h", cyc, `"nm`", g_``nm, i_``nm); end end
  task automatic compare_all();
    `CMP(io_in_ready)
    `CMP(io_out_valid)
    `CMP(io_out_bits_ctrl_robIdx_flag)
    `CMP(io_out_bits_ctrl_robIdx_value)
    `CMP(io_out_bits_ctrl_pdest)
    `CMP(io_out_bits_ctrl_vecWen)
    `CMP(io_out_bits_ctrl_v0Wen)
    `CMP(io_out_bits_ctrl_fpu_wflags)
    `CMP(io_out_bits_res_data)
    `CMP(io_out_bits_res_fflags)
    `CMP(io_out_bits_perfDebugInfo_eliminatedMove)
    `CMP(io_out_bits_perfDebugInfo_renameTime)
    `CMP(io_out_bits_perfDebugInfo_dispatchTime)
    `CMP(io_out_bits_perfDebugInfo_enqRsTime)
    `CMP(io_out_bits_perfDebugInfo_selectTime)
    `CMP(io_out_bits_perfDebugInfo_issueTime)
    `CMP(io_out_bits_perfDebugInfo_writebackTime)
    `CMP(io_out_bits_perfDebugInfo_runahead_checkpoint_id)
    `CMP(io_out_bits_perfDebugInfo_tlbFirstReqTime)
    `CMP(io_out_bits_perfDebugInfo_tlbRespTime)
    `CMP(io_out_bits_debug_seqNum_seqNum)
    `CMP(io_out_bits_debug_seqNum_uopIdx)
  endtask

  // 两拍前那条指令（给 ctrlPipe_2 / dataPipe_2 用）
  typedef struct {
    logic         valid;
    logic         vm;
    logic [6:0]   vuopIdx;
    logic [7:0]   vl;
    logic [127:0] v0;
  } hist_t;
  hist_t hist [3];

  int cov [string];
  int cov_lmul [8];
  int cov_narrow_uop [2];
  int cov_fl [5];
  int cov_data_nz;

  function automatic logic [127:0] shape128();
    logic [127:0] x;
    x = {$urandom, $urandom, $urandom, $urandom};
    case ($urandom_range(0, 3))
      0: return x;
      1: return '0;
      2: return '1;
      default: return x & {$urandom, $urandom, $urandom, $urandom};
    endcase
  endfunction

  initial begin
    int bad;
    logic [7:0] op;
    logic [1:0] sew;
    logic [2:0] eff_rm;
    bit consistent;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    reset = 1;
    io_in_valid = 0; io_out_ready = 1; io_frm = 0;
    foreach (hist[k]) begin hist[k].valid = 0; hist[k].vm = 0; hist[k].vuopIdx = 0; hist[k].vl = 0; hist[k].v0 = 0; end
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(posedge clock); #1;
      compare_all();
      for (int b = 0; b < 5; b++) if (g_io_out_bits_res_fflags[b]) cov_fl[b]++;
      if (|g_io_out_bits_res_data) cov_data_nz++;
      // ---- 新激励 ----
      reset = (cyc < 5) || ($urandom_range(0, 19999) == 0);
      pick_op(op, sew);
      io_in_valid                  = ($urandom_range(0, 9) < 7);
      io_out_ready                 = ($urandom_range(0, 9) != 0);
      io_in_bits_ctrl_fuOpType     = ($urandom_range(0, 99) < 92) ? {1'b0, op} : 9'($urandom);
      io_in_bits_ctrl_vpu_vsew     = sew;
      io_in_bits_ctrl_vpu_vlmul    = 3'($urandom);
      io_in_bits_ctrl_vpu_vm       = 1'($urandom);
      io_in_bits_ctrl_vpu_vuopIdx  = ($urandom_range(0, 3) != 0) ? 7'($urandom_range(0, 7)) : 7'($urandom);
      io_in_bits_data_src_4        = $urandom_range(0, 1) ? 8'($urandom_range(0, 64)) : 8'($urandom);
      io_in_bits_data_src_3        = shape128();
      io_in_bits_data_src_1        = {pick_vec64(op, sew), pick_vec64(op, sew)};
      io_frm                       = ($urandom_range(0, 99) < 85) ? 3'($urandom_range(0, 4)) : 3'($urandom);
      // 两拍前那条指令
      hist[2] = hist[1]; hist[1] = hist[0];
      hist[0].valid = io_in_valid; hist[0].vm = io_in_bits_ctrl_vpu_vm;
      hist[0].vuopIdx = io_in_bits_ctrl_vpu_vuopIdx; hist[0].vl = io_in_bits_data_src_4;
      hist[0].v0 = io_in_bits_data_src_3;
      consistent = ($urandom_range(0, 99) < 85);
      io_in_bits_validPipe_2              = consistent ? hist[2].valid   : 1'($urandom);
      io_in_bits_ctrlPipe_2_vpu_vm        = consistent ? hist[2].vm      : 1'($urandom);
      io_in_bits_ctrlPipe_2_vpu_vuopIdx   = consistent ? hist[2].vuopIdx : 7'($urandom);
      io_in_bits_dataPipe_2_src_4         = consistent ? hist[2].vl      : 8'($urandom);
      io_in_bits_dataPipe_2_src_3         = consistent ? hist[2].v0      : shape128();
      io_in_bits_dataPipe_2_src_2         = shape128();
      io_in_bits_ctrlPipe_2_vpu_vstart    = $urandom_range(0, 1) ? 8'h0 : 8'($urandom_range(0, 64));
      io_in_bits_ctrlPipe_2_vpu_vma       = 1'($urandom);
      io_in_bits_ctrlPipe_2_vpu_vta       = 1'($urandom);
      io_in_bits_ctrlPipe_2_vpu_isDstMask = ($urandom_range(0, 9) == 0);
      io_in_bits_ctrlPipe_2_robIdx_flag   = 1'($urandom);
      io_in_bits_ctrlPipe_2_robIdx_value  = 8'($urandom);
      io_in_bits_ctrlPipe_2_pdest         = 8'($urandom);
      io_in_bits_ctrlPipe_2_vecWen        = 1'($urandom);
      io_in_bits_ctrlPipe_2_v0Wen         = 1'($urandom);
      io_in_bits_ctrlPipe_2_fpu_wflags    = 1'($urandom);
      io_in_bits_perfDebugInfo_eliminatedMove         = 1'($urandom);
      io_in_bits_perfDebugInfo_renameTime             = rnd64();
      io_in_bits_perfDebugInfo_dispatchTime           = rnd64();
      io_in_bits_perfDebugInfo_enqRsTime              = rnd64();
      io_in_bits_perfDebugInfo_selectTime             = rnd64();
      io_in_bits_perfDebugInfo_issueTime              = rnd64();
      io_in_bits_perfDebugInfo_writebackTime          = rnd64();
      io_in_bits_perfDebugInfo_runahead_checkpoint_id = rnd64();
      io_in_bits_perfDebugInfo_tlbFirstReqTime        = rnd64();
      io_in_bits_perfDebugInfo_tlbRespTime            = rnd64();
      io_in_bits_debug_seqNum_seqNum                  = 56'(rnd64());
      io_in_bits_debug_seqNum_uopIdx                  = 8'($urandom);
      // ---- 覆盖计数 ----
      if (io_in_valid && !reset) begin
        op = io_in_bits_ctrl_fuOpType[7:0];
        if (op[2] & op[1])               eff_rm = 3'd1;      // RTZ
        else if (op[2] & ~op[1] & op[0]) eff_rm = 3'd6;      // ROD
        else                             eff_rm = io_frm;
        if (io_in_bits_ctrl_fuOpType[8] == 1'b0 && op_legal(op, sew)) cov[op_key(op, sew, eff_rm)]++;
        cov_lmul[io_in_bits_ctrl_vpu_vlmul]++;
        if (op[4] & ~op[3]) cov_narrow_uop[io_in_bits_ctrl_vpu_vuopIdx[0]]++;
      end
    end
    bad = 0;
    foreach (VEC_OPS[k]) for (int s = 0; s < 4; s++) if (op_legal(VEC_OPS[k], 2'(s))) begin
      logic [7:0] o;
      o = VEC_OPS[k];
      for (int r = 0; r < 5; r++) begin
        string key;
        logic [2:0] er;
        if (o[2] & o[1]) begin if (r != 1) continue; end                  // RTZ 编码只会出 rm=1
        else if (o[2] & ~o[1] & o[0]) continue;                           // ROD 只会出 rm=6（单独查）
        key = op_key(o, 2'(s), 3'(r));
        if (!cov.exists(key) || cov[key] < 20) begin bad++; $display("cov LOW %s", key); end
      end
      if (o[2] & ~o[1] & o[0]) begin
        string key;
        key = op_key(o, 2'(s), 3'd6);
        if (!cov.exists(key) || cov[key] < 20) begin bad++; $display("cov LOW %s", key); end
      end
    end
    foreach (cov[key]) $display("cov %s : %0d", key, cov[key]);
    $display("cov vlmul 0..7 : %0d %0d %0d %0d %0d %0d %0d %0d", cov_lmul[0], cov_lmul[1], cov_lmul[2],
             cov_lmul[3], cov_lmul[4], cov_lmul[5], cov_lmul[6], cov_lmul[7]);
    foreach (cov_lmul[l]) if (cov_lmul[l] < NCYCLES / 200) bad++;
    $display("cov narrow vuopIdx[0]=0/1 : %0d / %0d", cov_narrow_uop[0], cov_narrow_uop[1]);
    foreach (cov_narrow_uop[u]) if (cov_narrow_uop[u] < NCYCLES / 400) bad++;
    $display("cov fflags set NX/UF/OF/DZ/NV : %0d %0d %0d %0d %0d", cov_fl[0], cov_fl[1], cov_fl[2], cov_fl[3], cov_fl[4]);
    foreach (cov_fl[b]) if (cov_fl[b] == 0) bad++;
    $display("cov res_data nonzero cycles : %0d", cov_data_nz);
    if (cov_data_nz == 0) bad++;
    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
    if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
