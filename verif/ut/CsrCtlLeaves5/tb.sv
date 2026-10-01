// CsrCtlLeaves5 双例化逐拍比对 tb —— 5 个 NewCSR 控制/计数叶：
//   FcsrModule / DcsrModule / VcsrModule / McycleModule / MinstretModule
// 每叶 golden <M> u_*_g 与重写件 <M>_xs u_*_i（derive_ut_impl.py 派生）同激励，
// 逐拍比对全部 28 个输出。
//
// 激励：
//   前 8 拍定向角：全 0 写 / 全 1 写 / 写后保持读回 / 提交+写同拍（粘性累积优先级角）/
//     dcsr trap+dret+软件写三源或合成角 / dcsr 非法 PRV=2 纯写（WARL 保持角）/
//     inhibit 停表角 / 计数器写全 1 后自增回绕角；之后全随机。
//   随机档各写使能独立掷点（wen 50%、alias 35%、commit 30%、trap 15%、dret 10%、
//   inhibit 25%）；写数据 1/8 全 0、1/8 全 1、其余随机（读全角由全 0/全 1 写覆盖）。
//   NCYCLES 中点插一次 3 拍复位（VcsrModule 无复位端口，两侧同样无视它）。
// 覆盖闸（防"DUT 没动也全绿"）：
//   checks  比对次数（0 直接 FAIL）；
//   toggled 至少翻转过一次的输出个数（28 个输出在本激励下全部可翻转，< 28 判 FAIL）；
//   fires   15 类事件计数（各模块写使能/别名写/退休提交/trap/dret/非法 PRV 纯写/停表/
//           自增），每类下限按 NCYCLES 线性缩放（200k 拍时 500；实测期望最低的
//           dret 也在 ~2 万量级，门限留两个数量级余量，不是贴着实测值设的）。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int N_OUT = 28;
  bit clock = 0;
  always #5 clock = ~clock;
  bit reset;
  longint checks = 0, errors = 0;
  int toggled;
  longint minf, total_fires;

  // ---- 事件计数（fires 覆盖闸） ----
  longint f_wen_fires = 0, f_alias_fires = 0, f_cmt_fires = 0;
  longint v_wen_fires = 0, v_alias_fires = 0, v_cmt_fires = 0;
  longint d_wen_fires = 0, d_trap_fires = 0, d_ret_fires = 0, d_prvill_fires = 0;
  longint mcy_wen_fires = 0, mcy_hold_fires = 0, mcy_inc_fires = 0;
  longint min_wen_fires = 0, min_inc_fires = 0;

  // ---- 激励 ----
  logic        f_wen, f_cmt_valid, f_aff_wen, f_afm_wen;
  logic [63:0] f_wdata, f_aff_wdata, f_afm_wdata;
  logic [4:0]  f_cmt_bits;
  logic        v_wen, v_cmt_valid, v_cmt_bits, v_asat_wen, v_axrm_wen;
  logic [63:0] v_wdata, v_asat_wdata, v_axrm_wdata;
  logic        d_wen, d_trap_valid, d_trap_v, d_ret_valid, d_ret_v, d_nmip;
  logic [63:0] d_wdata;
  logic [2:0]  d_trap_cause;
  logic [1:0]  d_trap_prv, d_ret_prv;
  logic        mcy_wen, mcy_inh;
  logic [63:0] mcy_wdata;
  logic        min_wen, min_inh;
  logic [63:0] min_wdata;
  logic [6:0]  min_instnum;

  // ---- 输出（g = golden，i = 重写件） ----
  wire [63:0] g_f_rdata, i_f_rdata;
  wire [4:0]  g_f_fflags, i_f_fflags, g_f_fflags_r, i_f_fflags_r;
  wire [2:0]  g_f_frm, i_f_frm, g_f_frm_r, i_f_frm_r;
  wire [63:0] g_v_rdata, i_v_rdata;
  wire        g_v_vxsat, i_v_vxsat;
  wire [1:0]  g_v_vxrm, i_v_vxrm;
  wire [31:0] g_d_rdata, i_d_rdata;
  wire        g_d_cetrig, i_d_cetrig, g_d_ebreakvs, i_d_ebreakvs;
  wire        g_d_ebreakvu, i_d_ebreakvu, g_d_ebreakm, i_d_ebreakm;
  wire        g_d_ebreaks, i_d_ebreaks, g_d_ebreaku, i_d_ebreaku;
  wire        g_d_stepie, i_d_stepie, g_d_stopcount, i_d_stopcount;
  wire        g_d_stoptime, i_d_stoptime, g_d_v, i_d_v, g_d_mprven, i_d_mprven;
  wire        g_d_nmip, i_d_nmip, g_d_step, i_d_step;
  wire [2:0]  g_d_cause, i_d_cause;
  wire [1:0]  g_d_prv, i_d_prv;
  wire [63:0] g_mcy_rdata, i_mcy_rdata, g_mcy_mirror, i_mcy_mirror;
  wire [63:0] g_min_rdata, i_min_rdata, g_min_mirror, i_min_mirror;

  // ---- toggle 统计（golden 侧，零扩展到 64 位打包） ----
  logic [27:0][63:0] prev_g;
  bit   [27:0]       tog;

  FcsrModule u_f_g (
    .clock(clock), .reset(reset),
    .w_wen(f_wen), .w_wdata(f_wdata), .rdata(g_f_rdata),
    .robCommit_fflags_valid(f_cmt_valid), .robCommit_fflags_bits(f_cmt_bits),
    .wAliasFflags_wen(f_aff_wen), .wAliasFflags_wdata(f_aff_wdata),
    .wAliasFfm_wen(f_afm_wen), .wAliasFfm_wdata(f_afm_wdata),
    .fflags(g_f_fflags), .frm(g_f_frm),
    .fflagsRdata(g_f_fflags_r), .frmRdata(g_f_frm_r)
  );
  FcsrModule_xs u_f_i (
    .clock(clock), .reset(reset),
    .w_wen(f_wen), .w_wdata(f_wdata), .rdata(i_f_rdata),
    .robCommit_fflags_valid(f_cmt_valid), .robCommit_fflags_bits(f_cmt_bits),
    .wAliasFflags_wen(f_aff_wen), .wAliasFflags_wdata(f_aff_wdata),
    .wAliasFfm_wen(f_afm_wen), .wAliasFfm_wdata(f_afm_wdata),
    .fflags(i_f_fflags), .frm(i_f_frm),
    .fflagsRdata(i_f_fflags_r), .frmRdata(i_f_frm_r)
  );

  DcsrModule u_d_g (
    .clock(clock), .reset(reset),
    .w_wen(d_wen), .w_wdata(d_wdata), .rdata(g_d_rdata),
    .regOut_CETRIG(g_d_cetrig), .regOut_EBREAKVS(g_d_ebreakvs),
    .regOut_EBREAKVU(g_d_ebreakvu), .regOut_EBREAKM(g_d_ebreakm),
    .regOut_EBREAKS(g_d_ebreaks), .regOut_EBREAKU(g_d_ebreaku),
    .regOut_STEPIE(g_d_stepie), .regOut_STOPCOUNT(g_d_stopcount),
    .regOut_STOPTIME(g_d_stoptime), .regOut_CAUSE(g_d_cause),
    .regOut_V(g_d_v), .regOut_MPRVEN(g_d_mprven), .regOut_NMIP(g_d_nmip),
    .regOut_STEP(g_d_step), .regOut_PRV(g_d_prv),
    .trapToD_dcsr_valid(d_trap_valid), .trapToD_dcsr_bits_CAUSE(d_trap_cause),
    .trapToD_dcsr_bits_V(d_trap_v), .trapToD_dcsr_bits_PRV(d_trap_prv),
    .retFromD_dcsr_valid(d_ret_valid), .retFromD_dcsr_bits_V(d_ret_v),
    .retFromD_dcsr_bits_PRV(d_ret_prv), .nmip(d_nmip)
  );
  DcsrModule_xs u_d_i (
    .clock(clock), .reset(reset),
    .w_wen(d_wen), .w_wdata(d_wdata), .rdata(i_d_rdata),
    .regOut_CETRIG(i_d_cetrig), .regOut_EBREAKVS(i_d_ebreakvs),
    .regOut_EBREAKVU(i_d_ebreakvu), .regOut_EBREAKM(i_d_ebreakm),
    .regOut_EBREAKS(i_d_ebreaks), .regOut_EBREAKU(i_d_ebreaku),
    .regOut_STEPIE(i_d_stepie), .regOut_STOPCOUNT(i_d_stopcount),
    .regOut_STOPTIME(i_d_stoptime), .regOut_CAUSE(i_d_cause),
    .regOut_V(i_d_v), .regOut_MPRVEN(i_d_mprven), .regOut_NMIP(i_d_nmip),
    .regOut_STEP(i_d_step), .regOut_PRV(i_d_prv),
    .trapToD_dcsr_valid(d_trap_valid), .trapToD_dcsr_bits_CAUSE(d_trap_cause),
    .trapToD_dcsr_bits_V(d_trap_v), .trapToD_dcsr_bits_PRV(d_trap_prv),
    .retFromD_dcsr_valid(d_ret_valid), .retFromD_dcsr_bits_V(d_ret_v),
    .retFromD_dcsr_bits_PRV(d_ret_prv), .nmip(d_nmip)
  );

  VcsrModule u_v_g (
    .clock(clock),
    .w_wen(v_wen), .w_wdata(v_wdata), .rdata(g_v_rdata),
    .robCommit_vxsat_valid(v_cmt_valid), .robCommit_vxsat_bits(v_cmt_bits),
    .wAliasVxsat_wen(v_asat_wen), .wAliasVxsat_wdata(v_asat_wdata),
    .wAliasVxrm_wen(v_axrm_wen), .wAliasVxrm_wdata(v_axrm_wdata),
    .vxsat(g_v_vxsat), .vxrm(g_v_vxrm)
  );
  VcsrModule_xs u_v_i (
    .clock(clock),
    .w_wen(v_wen), .w_wdata(v_wdata), .rdata(i_v_rdata),
    .robCommit_vxsat_valid(v_cmt_valid), .robCommit_vxsat_bits(v_cmt_bits),
    .wAliasVxsat_wen(v_asat_wen), .wAliasVxsat_wdata(v_asat_wdata),
    .wAliasVxrm_wen(v_axrm_wen), .wAliasVxrm_wdata(v_axrm_wdata),
    .vxsat(i_v_vxsat), .vxrm(i_v_vxrm)
  );

  McycleModule u_mcy_g (
    .clock(clock), .reset(reset),
    .w_wen(mcy_wen), .w_wdata(mcy_wdata),
    .rdata(g_mcy_rdata), .regOut_ALL(g_mcy_mirror),
    .mcountinhibit_CY(mcy_inh)
  );
  McycleModule_xs u_mcy_i (
    .clock(clock), .reset(reset),
    .w_wen(mcy_wen), .w_wdata(mcy_wdata),
    .rdata(i_mcy_rdata), .regOut_ALL(i_mcy_mirror),
    .mcountinhibit_CY(mcy_inh)
  );

  MinstretModule u_min_g (
    .clock(clock), .reset(reset),
    .w_wen(min_wen), .w_wdata(min_wdata),
    .rdata(g_min_rdata), .regOut_ALL(g_min_mirror),
    .mcountinhibit_IR(min_inh), .robCommit_instNum_bits(min_instnum)
  );
  MinstretModule_xs u_min_i (
    .clock(clock), .reset(reset),
    .w_wen(min_wen), .w_wdata(min_wdata),
    .rdata(i_min_rdata), .regOut_ALL(i_min_mirror),
    .mcountinhibit_IR(min_inh), .robCommit_instNum_bits(min_instnum)
  );

  // 写数据全角：1/8 全 0、1/8 全 1、其余随机
  function automatic logic [63:0] wdata_pick();
    case ($urandom_range(0, 7))
      0:       return 64'h0;
      1:       return 64'hFFFF_FFFF_FFFF_FFFF;
      default: return {$urandom, $urandom};
    endcase
  endfunction

  // 逐输出比对 + toggle 统计（golden 侧为基准；golden 未知的拍跳过）
  task automatic cmp_tog(input int idx, input logic [63:0] g, input logic [63:0] i,
                         input string tag);
    if (!$isunknown(g)) begin
      checks++;
      if (g !== i) begin
        errors++;
        if (errors <= 30)
          $display("[%0t] MISMATCH %s g=%0h i=%0h", $time, tag, g, i);
      end
      if (!$isunknown(prev_g[idx]) && g !== prev_g[idx]) tog[idx] = 1'b1;
      prev_g[idx] = g;
    end
  endtask

  task automatic check_outputs();
    cmp_tog(0,  g_f_rdata,     i_f_rdata,     "Fcsr.rdata");
    cmp_tog(1,  g_f_fflags,    i_f_fflags,    "Fcsr.fflags");
    cmp_tog(2,  g_f_frm,       i_f_frm,       "Fcsr.frm");
    cmp_tog(3,  g_f_fflags_r,  i_f_fflags_r,  "Fcsr.fflagsRdata");
    cmp_tog(4,  g_f_frm_r,     i_f_frm_r,     "Fcsr.frmRdata");
    cmp_tog(5,  g_v_rdata,     i_v_rdata,     "Vcsr.rdata");
    cmp_tog(6,  g_v_vxsat,     i_v_vxsat,     "Vcsr.vxsat");
    cmp_tog(7,  g_v_vxrm,      i_v_vxrm,      "Vcsr.vxrm");
    cmp_tog(8,  g_d_rdata,     i_d_rdata,     "Dcsr.rdata");
    cmp_tog(9,  g_d_cetrig,    i_d_cetrig,    "Dcsr.CETRIG");
    cmp_tog(10, g_d_ebreakvs,  i_d_ebreakvs,  "Dcsr.EBREAKVS");
    cmp_tog(11, g_d_ebreakvu,  i_d_ebreakvu,  "Dcsr.EBREAKVU");
    cmp_tog(12, g_d_ebreakm,   i_d_ebreakm,   "Dcsr.EBREAKM");
    cmp_tog(13, g_d_ebreaks,   i_d_ebreaks,   "Dcsr.EBREAKS");
    cmp_tog(14, g_d_ebreaku,   i_d_ebreaku,   "Dcsr.EBREAKU");
    cmp_tog(15, g_d_stepie,    i_d_stepie,    "Dcsr.STEPIE");
    cmp_tog(16, g_d_stopcount, i_d_stopcount, "Dcsr.STOPCOUNT");
    cmp_tog(17, g_d_stoptime,  i_d_stoptime,  "Dcsr.STOPTIME");
    cmp_tog(18, g_d_cause,     i_d_cause,     "Dcsr.CAUSE");
    cmp_tog(19, g_d_v,         i_d_v,         "Dcsr.V");
    cmp_tog(20, g_d_mprven,    i_d_mprven,    "Dcsr.MPRVEN");
    cmp_tog(21, g_d_nmip,      i_d_nmip,      "Dcsr.NMIP");
    cmp_tog(22, g_d_step,      i_d_step,      "Dcsr.STEP");
    cmp_tog(23, g_d_prv,       i_d_prv,       "Dcsr.PRV");
    cmp_tog(24, g_mcy_rdata,   i_mcy_rdata,   "Mcycle.rdata");
    cmp_tog(25, g_mcy_mirror,  i_mcy_mirror,  "Mcycle.regOut_ALL");
    cmp_tog(26, g_min_rdata,   i_min_rdata,   "Minstret.rdata");
    cmp_tog(27, g_min_mirror,  i_min_mirror,  "Minstret.regOut_ALL");
  endtask

  task automatic drive(input int unsigned c);
    if (c == 0) begin
      // 全 0 写角（读全 0 角在复位后已由复位值覆盖）
      f_wen = 1; f_wdata = '0; f_cmt_valid = 0; f_cmt_bits = '0;
      f_aff_wen = 1; f_aff_wdata = '0; f_afm_wen = 1; f_afm_wdata = '0;
      v_wen = 1; v_wdata = '0; v_cmt_valid = 0; v_cmt_bits = 0;
      v_asat_wen = 1; v_asat_wdata = '0; v_axrm_wen = 1; v_axrm_wdata = '0;
      d_wen = 1; d_wdata = '0;
      d_trap_valid = 0; d_trap_cause = '0; d_trap_v = 0; d_trap_prv = '0;
      d_ret_valid = 0; d_ret_v = 0; d_ret_prv = '0; d_nmip = 0;
      mcy_wen = 1; mcy_wdata = '0; mcy_inh = 0;
      min_wen = 1; min_wdata = '0; min_inh = 0; min_instnum = '0;
    end
    else if (c == 1) begin
      // 全 1 写角（下一拍读回全 1）
      f_wen = 1; f_wdata = '1; f_cmt_valid = 0; f_cmt_bits = '1;
      f_aff_wen = 1; f_aff_wdata = '1; f_afm_wen = 1; f_afm_wdata = '1;
      v_wen = 1; v_wdata = '1; v_cmt_valid = 0; v_cmt_bits = 1;
      v_asat_wen = 1; v_asat_wdata = '1; v_axrm_wen = 1; v_axrm_wdata = '1;
      d_wen = 1; d_wdata = '1;
      d_trap_valid = 0; d_trap_cause = '1; d_trap_v = 1; d_trap_prv = '1;
      d_ret_valid = 0; d_ret_v = 1; d_ret_prv = '1; d_nmip = 1;
      mcy_wen = 1; mcy_wdata = '1; mcy_inh = 0;
      min_wen = 1; min_wdata = '1; min_inh = 0; min_instnum = '1;
    end
    else if (c == 2) begin
      // 保持角：一切写使能撤掉，读回全 1 写入的结果
      f_wen = 0; f_cmt_valid = 0; f_aff_wen = 0; f_afm_wen = 0;
      v_wen = 0; v_cmt_valid = 0; v_asat_wen = 0; v_axrm_wen = 0;
      d_wen = 0; d_trap_valid = 0; d_ret_valid = 0;
      mcy_wen = 0; min_wen = 0;
    end
    else if (c == 3) begin
      // 提交+写同拍：fflags/vxsat 应走粘性累积（退休优先于软件写）
      f_wen = 1; f_wdata = '0; f_aff_wen = 1; f_aff_wdata = '0;
      f_afm_wen = 1; f_afm_wdata = '1;
      f_cmt_valid = 1; f_cmt_bits = '1;
      v_wen = 1; v_wdata = '0; v_asat_wen = 1; v_asat_wdata = '0;
      v_axrm_wen = 1; v_axrm_wdata = '1;
      v_cmt_valid = 1; v_cmt_bits = 1;
    end
    else if (c == 4) begin
      // dcsr 三源或合成角：trap + dret + 软件写同拍
      d_wen = 1; d_wdata = '1;
      d_trap_valid = 1; d_trap_cause = '1; d_trap_v = 1; d_trap_prv = '1;
      d_ret_valid = 1; d_ret_v = 1; d_ret_prv = '1;
    end
    else if (c == 5) begin
      // dcsr 非法 PRV=2 纯写角（无 trap/dret）：PRV 必须保持，其余字段照写
      d_wen = 1; d_wdata = '1; d_wdata[1:0] = 2'h2;
      d_trap_valid = 0; d_ret_valid = 0;
    end
    else if (c == 6) begin
      // inhibit 停表角：计数器保持
      mcy_wen = 0; mcy_inh = 1; min_wen = 0; min_inh = 1;
    end
    else if (c == 7) begin
      // 计数器写全 1 角：下一拍起自增覆盖回绕
      mcy_wen = 1; mcy_wdata = '1; mcy_inh = 0;
      min_wen = 1; min_wdata = '1; min_inh = 0; min_instnum = '1;
    end
    else begin
      // 随机档
      f_wen = $urandom_range(0, 1); f_wdata = wdata_pick();
      f_cmt_valid = ($urandom_range(0, 9) < 3); f_cmt_bits = $urandom;
      f_aff_wen = ($urandom_range(0, 19) < 7); f_aff_wdata = wdata_pick();
      f_afm_wen = ($urandom_range(0, 19) < 7); f_afm_wdata = wdata_pick();
      v_wen = $urandom_range(0, 1); v_wdata = wdata_pick();
      v_cmt_valid = ($urandom_range(0, 9) < 3); v_cmt_bits = $urandom_range(0, 1);
      v_asat_wen = ($urandom_range(0, 19) < 7); v_asat_wdata = wdata_pick();
      v_axrm_wen = ($urandom_range(0, 19) < 7); v_axrm_wdata = wdata_pick();
      d_wen = $urandom_range(0, 1); d_wdata = wdata_pick();
      d_trap_valid = ($urandom_range(0, 19) < 3);
      d_trap_cause = $urandom; d_trap_v = $urandom_range(0, 1); d_trap_prv = $urandom;
      d_ret_valid = ($urandom_range(0, 9) < 1);
      d_ret_v = $urandom_range(0, 1); d_ret_prv = $urandom;
      d_nmip = $urandom_range(0, 1);
      mcy_wen = $urandom_range(0, 1); mcy_wdata = wdata_pick();
      mcy_inh = ($urandom_range(0, 3) < 1);
      min_wen = $urandom_range(0, 1); min_wdata = wdata_pick();
      min_inh = ($urandom_range(0, 3) < 1); min_instnum = $urandom;
    end
  endtask

  task automatic sample_fires();
    if (reset) return;
    if (f_wen) f_wen_fires++;
    if (f_aff_wen | f_afm_wen) f_alias_fires++;
    if (f_cmt_valid) f_cmt_fires++;
    if (v_wen) v_wen_fires++;
    if (v_asat_wen | v_axrm_wen) v_alias_fires++;
    if (v_cmt_valid) v_cmt_fires++;
    if (d_wen) d_wen_fires++;
    if (d_trap_valid) d_trap_fires++;
    if (d_ret_valid) d_ret_fires++;
    if (d_wen && (d_wdata[1:0] == 2'h2) && !d_trap_valid && !d_ret_valid) d_prvill_fires++;
    if (mcy_wen) mcy_wen_fires++;
    if (!mcy_wen && mcy_inh) mcy_hold_fires++;
    if (!mcy_wen && !mcy_inh) mcy_inc_fires++;
    if (min_wen) min_wen_fires++;
    if (!min_wen && !min_inh) min_inc_fires++;
  endtask

  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    f_wen = 0; f_wdata = '0; f_cmt_valid = 0; f_cmt_bits = '0;
    f_aff_wen = 0; f_aff_wdata = '0; f_afm_wen = 0; f_afm_wdata = '0;
    v_wen = 0; v_wdata = '0; v_cmt_valid = 0; v_cmt_bits = 0;
    v_asat_wen = 0; v_asat_wdata = '0; v_axrm_wen = 0; v_axrm_wdata = '0;
    d_wen = 0; d_wdata = '0;
    d_trap_valid = 0; d_trap_cause = '0; d_trap_v = 0; d_trap_prv = '0;
    d_ret_valid = 0; d_ret_v = 0; d_ret_prv = '0; d_nmip = 0;
    mcy_wen = 0; mcy_wdata = '0; mcy_inh = 0;
    min_wen = 0; min_wdata = '0; min_inh = 0; min_instnum = '0;
    prev_g = '{default: 'x};   // 首个已知值只登记、不算翻转
    tog = '0;
    reset = 1;
    repeat (5) @(posedge clock);
    @(negedge clock); reset = 0;   // negedge 撤复位，避开 posedge 采样竞争
    for (int unsigned c = 0; c < NCYCLES; c++) begin
      // 中途再复位一次，覆盖复位路径（两侧同拍同源）
      if (c == NCYCLES/2) begin
        @(negedge clock); reset = 1;
        repeat (3) @(posedge clock);
        @(negedge clock); reset = 0;
      end
      @(negedge clock);
      drive(c);
      #1 check_outputs();
      sample_fires();
      @(posedge clock);
    end

    toggled = $countones(tog);
    minf = (longint'(NCYCLES) * 500) / 200000;
    total_fires = f_wen_fires + f_alias_fires + f_cmt_fires
                + v_wen_fires + v_alias_fires + v_cmt_fires
                + d_wen_fires + d_trap_fires + d_ret_fires + d_prvill_fires
                + mcy_wen_fires + mcy_hold_fires + mcy_inc_fires
                + min_wen_fires + min_inc_fires;
    $display("CsrCtlLeaves5 UT: checks=%0d errors=%0d toggled=%0d/%0d fires=%0d",
             checks, errors, toggled, N_OUT, total_fires);
    $display("COV fcsr     wen=%0d alias=%0d cmt=%0d", f_wen_fires, f_alias_fires, f_cmt_fires);
    $display("COV vcsr     wen=%0d alias=%0d cmt=%0d", v_wen_fires, v_alias_fires, v_cmt_fires);
    $display("COV dcsr     wen=%0d trap=%0d dret=%0d prv_ill_write=%0d",
             d_wen_fires, d_trap_fires, d_ret_fires, d_prvill_fires);
    $display("COV mcycle   wen=%0d hold=%0d inc=%0d", mcy_wen_fires, mcy_hold_fires, mcy_inc_fires);
    $display("COV minstret wen=%0d inc=%0d", min_wen_fires, min_inc_fires);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0) begin $display("TEST FAILED (coverage: no comparison happened)"); $fatal(1); end
    if (toggled < N_OUT) begin
      $display("TEST FAILED (coverage: only %0d/%0d outputs toggled)", toggled, N_OUT);
      $fatal(1);
    end
    if (f_wen_fires < minf || f_alias_fires < minf || f_cmt_fires < minf ||
        v_wen_fires < minf || v_alias_fires < minf || v_cmt_fires < minf ||
        d_wen_fires < minf || d_trap_fires < minf || d_ret_fires < minf ||
        d_prvill_fires < minf ||
        mcy_wen_fires < minf || mcy_hold_fires < minf || mcy_inc_fires < minf ||
        min_wen_fires < minf || min_inc_fires < minf) begin
      $display("TEST FAILED (coverage: some fire counter below floor %0d)", minf);
      $fatal(1);
    end
    $display("TEST PASSED");
    $finish;
  end
endmodule
