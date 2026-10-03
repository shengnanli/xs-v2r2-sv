// CsrEpcTvecLeaves7 双例化逐拍比对 tb —— 7 个 NewCSR trap 返回地址/向量叶：
//   epc 亚族：MepcModule / SepcModule / VSepcModule / MnepcModule（仅 trap 口前缀不同）
//   tvec 亚族：MtvecModule / StvecModule / VStvecModule（逐字节同构）
// 每叶 golden <M> u_*_g 与重写件 <M>_xs u_*_i（derive_ut_impl.py 派生）同激励，
// 逐拍比对全部 17 个输出（epc 各 2 个：rdata/regOut_epc；tvec 各 3 个：
// rdata/regOut_mode/regOut_addr）。
//
// 激励（一律 @(negedge clock) 驱动，避开 posedge 同刻改激励的 tb/DUT 求值竞争）：
//   前 7 拍定向角：全 0 写 / 全 1 写（tvec mode=3 非法 → 保持）/ 保持 /
//     epc 纯 trap 装载全 1 / epc trap+软件写同拍按位或合并角（两源数据互补，
//     结果与任一单源都不同，优先级选择的错实现必被抓）/ tvec 非法 mode=2/3
//     纯写（mode 保持、base 照写）/ epc trap 有效但数据全 0（OR 退化为软件写）；
//     之后全随机。
//   随机档各叶独立掷点：epc wen 50% / trap 25%；tvec wen 50%；写数据 1/8 全 0、
//   1/8 全 1、其余随机（tvec 随机数据的 mode[1:0] 约一半非法，天然覆盖 WARL 保持）。
//   NCYCLES 中点插一次 3 拍复位（两侧同拍同源）。
// 覆盖闸（防"DUT 没动也全绿"）：
//   checks  比对次数（0 直接 FAIL）；
//   toggled 至少翻转过一次的输出个数（17 个输出在本激励下全部可翻转，< 17 判 FAIL）；
//   fires   7 类事件计数（软件写/trap 装载/同拍竞争/非法 mode 写/合法 mode 写/
//           全 0 写角/全 1 写角），每类下限按 NCYCLES 线性缩放（200k 拍时 500；
//           实测期望最低的全角写也在 ~8 万量级，门限留两个数量级余量，
//           不是贴着实测值设的）。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int N_OUT = 17;
  bit clock = 0;
  always #5 clock = ~clock;
  bit reset;
  longint checks = 0, errors = 0;
  int toggled;
  longint minf, total_fires;

  // ---- 事件计数（fires 覆盖闸） ----
  longint wen_fires = 0;        // 7 叶任一软件写
  longint trap_fires = 0;       // epc 4 叶任一 trap 装载
  longint both_fires = 0;       // epc 任一叶 trap+软件写同拍
  longint illmode_fires = 0;    // tvec 任一叶写且 mode[1:0]>=2（WARL 保持角）
  longint legalmode_fires = 0;  // tvec 任一叶写且 mode[1:0]<=1
  longint all0_fires = 0;       // 任一软件写数据全 0
  longint all1_fires = 0;       // 任一软件写数据全 1

  // ---- 激励 ----
  logic        me_wen,  se_wen,  vse_wen,  mne_wen;
  logic [63:0] me_wdata, se_wdata, vse_wdata, mne_wdata;
  logic        me_tv,   se_tv,   vse_tv,   mne_tv;
  logic [62:0] me_tb,   se_tb,   vse_tb,   mne_tb;
  logic        mt_wen,  st_wen,  vst_wen;
  logic [63:0] mt_wdata, st_wdata, vst_wdata;

  // ---- 输出（g = golden，i = 重写件） ----
  wire [63:0] g_me_rdata,  i_me_rdata;
  wire [62:0] g_me_epc,    i_me_epc;
  wire [63:0] g_se_rdata,  i_se_rdata;
  wire [62:0] g_se_epc,    i_se_epc;
  wire [63:0] g_vse_rdata, i_vse_rdata;
  wire [62:0] g_vse_epc,   i_vse_epc;
  wire [63:0] g_mne_rdata, i_mne_rdata;
  wire [62:0] g_mne_epc,   i_mne_epc;
  wire [63:0] g_mt_rdata,  i_mt_rdata;
  wire [1:0]  g_mt_mode,   i_mt_mode;
  wire [61:0] g_mt_addr,   i_mt_addr;
  wire [63:0] g_st_rdata,  i_st_rdata;
  wire [1:0]  g_st_mode,   i_st_mode;
  wire [61:0] g_st_addr,   i_st_addr;
  wire [63:0] g_vst_rdata, i_vst_rdata;
  wire [1:0]  g_vst_mode,  i_vst_mode;
  wire [61:0] g_vst_addr,  i_vst_addr;

  // ---- toggle 统计（golden 侧，零扩展到 64 位打包） ----
  logic [16:0][63:0] prev_g;
  bit   [16:0]       tog;

  // ---------------- epc 亚族 4 叶 × 双例化 ----------------
  MepcModule u_me_g (
    .clock(clock), .reset(reset),
    .w_wen(me_wen), .w_wdata(me_wdata),
    .rdata(g_me_rdata), .regOut_epc(g_me_epc),
    .trapToM_mepc_valid(me_tv), .trapToM_mepc_bits_epc(me_tb)
  );
  MepcModule_xs u_me_i (
    .clock(clock), .reset(reset),
    .w_wen(me_wen), .w_wdata(me_wdata),
    .rdata(i_me_rdata), .regOut_epc(i_me_epc),
    .trapToM_mepc_valid(me_tv), .trapToM_mepc_bits_epc(me_tb)
  );

  SepcModule u_se_g (
    .clock(clock), .reset(reset),
    .w_wen(se_wen), .w_wdata(se_wdata),
    .rdata(g_se_rdata), .regOut_epc(g_se_epc),
    .trapToHS_sepc_valid(se_tv), .trapToHS_sepc_bits_epc(se_tb)
  );
  SepcModule_xs u_se_i (
    .clock(clock), .reset(reset),
    .w_wen(se_wen), .w_wdata(se_wdata),
    .rdata(i_se_rdata), .regOut_epc(i_se_epc),
    .trapToHS_sepc_valid(se_tv), .trapToHS_sepc_bits_epc(se_tb)
  );

  VSepcModule u_vse_g (
    .clock(clock), .reset(reset),
    .w_wen(vse_wen), .w_wdata(vse_wdata),
    .rdata(g_vse_rdata), .regOut_epc(g_vse_epc),
    .trapToVS_vsepc_valid(vse_tv), .trapToVS_vsepc_bits_epc(vse_tb)
  );
  VSepcModule_xs u_vse_i (
    .clock(clock), .reset(reset),
    .w_wen(vse_wen), .w_wdata(vse_wdata),
    .rdata(i_vse_rdata), .regOut_epc(i_vse_epc),
    .trapToVS_vsepc_valid(vse_tv), .trapToVS_vsepc_bits_epc(vse_tb)
  );

  MnepcModule u_mne_g (
    .clock(clock), .reset(reset),
    .w_wen(mne_wen), .w_wdata(mne_wdata),
    .rdata(g_mne_rdata), .regOut_epc(g_mne_epc),
    .trapToMN_mnepc_valid(mne_tv), .trapToMN_mnepc_bits_epc(mne_tb)
  );
  MnepcModule_xs u_mne_i (
    .clock(clock), .reset(reset),
    .w_wen(mne_wen), .w_wdata(mne_wdata),
    .rdata(i_mne_rdata), .regOut_epc(i_mne_epc),
    .trapToMN_mnepc_valid(mne_tv), .trapToMN_mnepc_bits_epc(mne_tb)
  );

  // ---------------- tvec 亚族 3 叶 × 双例化 ----------------
  MtvecModule u_mt_g (
    .clock(clock), .reset(reset),
    .w_wen(mt_wen), .w_wdata(mt_wdata),
    .rdata(g_mt_rdata), .regOut_mode(g_mt_mode), .regOut_addr(g_mt_addr)
  );
  MtvecModule_xs u_mt_i (
    .clock(clock), .reset(reset),
    .w_wen(mt_wen), .w_wdata(mt_wdata),
    .rdata(i_mt_rdata), .regOut_mode(i_mt_mode), .regOut_addr(i_mt_addr)
  );

  StvecModule u_st_g (
    .clock(clock), .reset(reset),
    .w_wen(st_wen), .w_wdata(st_wdata),
    .rdata(g_st_rdata), .regOut_mode(g_st_mode), .regOut_addr(g_st_addr)
  );
  StvecModule_xs u_st_i (
    .clock(clock), .reset(reset),
    .w_wen(st_wen), .w_wdata(st_wdata),
    .rdata(i_st_rdata), .regOut_mode(i_st_mode), .regOut_addr(i_st_addr)
  );

  VStvecModule u_vst_g (
    .clock(clock), .reset(reset),
    .w_wen(vst_wen), .w_wdata(vst_wdata),
    .rdata(g_vst_rdata), .regOut_mode(g_vst_mode), .regOut_addr(g_vst_addr)
  );
  VStvecModule_xs u_vst_i (
    .clock(clock), .reset(reset),
    .w_wen(vst_wen), .w_wdata(vst_wdata),
    .rdata(i_vst_rdata), .regOut_mode(i_vst_mode), .regOut_addr(i_vst_addr)
  );

  // 写数据全角：1/8 全 0、1/8 全 1、其余随机
  function automatic logic [63:0] wdata_pick();
    case ($urandom_range(0, 7))
      0:       return 64'h0;
      1:       return 64'hFFFF_FFFF_FFFF_FFFF;
      default: return {$urandom, $urandom};
    endcase
  endfunction

  // trap 装载数据全角：1/8 全 0、1/8 全 1、其余随机（63 位）
  function automatic logic [62:0] trap_pick();
    logic [62:0] v;
    case ($urandom_range(0, 7))
      0:       return 63'h0;
      1:       return 63'h7FFF_FFFF_FFFF_FFFF;
      default: begin
        v = {$urandom, $urandom};
        return v[62:0];
      end
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
    cmp_tog(0,  g_me_rdata,  i_me_rdata,  "Mepc.rdata");
    cmp_tog(1,  {1'b0, g_me_epc},  {1'b0, i_me_epc},  "Mepc.regOut_epc");
    cmp_tog(2,  g_se_rdata,  i_se_rdata,  "Sepc.rdata");
    cmp_tog(3,  {1'b0, g_se_epc},  {1'b0, i_se_epc},  "Sepc.regOut_epc");
    cmp_tog(4,  g_vse_rdata, i_vse_rdata, "VSepc.rdata");
    cmp_tog(5,  {1'b0, g_vse_epc}, {1'b0, i_vse_epc}, "VSepc.regOut_epc");
    cmp_tog(6,  g_mne_rdata, i_mne_rdata, "Mnepc.rdata");
    cmp_tog(7,  {1'b0, g_mne_epc}, {1'b0, i_mne_epc}, "Mnepc.regOut_epc");
    cmp_tog(8,  g_mt_rdata,  i_mt_rdata,  "Mtvec.rdata");
    cmp_tog(9,  {62'h0, g_mt_mode},  {62'h0, i_mt_mode},  "Mtvec.regOut_mode");
    cmp_tog(10, {2'h0, g_mt_addr},   {2'h0, i_mt_addr},   "Mtvec.regOut_addr");
    cmp_tog(11, g_st_rdata,  i_st_rdata,  "Stvec.rdata");
    cmp_tog(12, {62'h0, g_st_mode},  {62'h0, i_st_mode},  "Stvec.regOut_mode");
    cmp_tog(13, {2'h0, g_st_addr},   {2'h0, i_st_addr},   "Stvec.regOut_addr");
    cmp_tog(14, g_vst_rdata, i_vst_rdata, "VStvec.rdata");
    cmp_tog(15, {62'h0, g_vst_mode}, {62'h0, i_vst_mode}, "VStvec.regOut_mode");
    cmp_tog(16, {2'h0, g_vst_addr},  {2'h0, i_vst_addr},  "VStvec.regOut_addr");
  endtask

  task automatic drive(input int unsigned c);
    if (c == 0) begin
      // 全 0 写角（读全 0 角在复位后已由复位值覆盖）
      me_wen = 1; me_wdata = '0; me_tv = 0; me_tb = '0;
      se_wen = 1; se_wdata = '0; se_tv = 0; se_tb = '0;
      vse_wen = 1; vse_wdata = '0; vse_tv = 0; vse_tb = '0;
      mne_wen = 1; mne_wdata = '0; mne_tv = 0; mne_tb = '0;
      mt_wen = 1; mt_wdata = '0;
      st_wen = 1; st_wdata = '0;
      vst_wen = 1; vst_wdata = '0;
    end
    else if (c == 1) begin
      // 全 1 写角：epc 取 [63:1] 全 1；tvec mode=2'h3 非法 → mode 保持 0、base 全 1
      me_wen = 1; me_wdata = '1; me_tv = 0; me_tb = '1;
      se_wen = 1; se_wdata = '1; se_tv = 0; se_tb = '1;
      vse_wen = 1; vse_wdata = '1; vse_tv = 0; vse_tb = '1;
      mne_wen = 1; mne_wdata = '1; mne_tv = 0; mne_tb = '1;
      mt_wen = 1; mt_wdata = '1;
      st_wen = 1; st_wdata = '1;
      vst_wen = 1; vst_wdata = '1;
    end
    else if (c == 2) begin
      // 保持角：一切写/trap 使能撤掉，读回上两拍写入的结果
      me_wen = 0; me_tv = 0; se_wen = 0; se_tv = 0;
      vse_wen = 0; vse_tv = 0; mne_wen = 0; mne_tv = 0;
      mt_wen = 0; st_wen = 0; vst_wen = 0;
    end
    else if (c == 3) begin
      // epc 纯 trap 装载角：trap 数据全 1，软件写撤掉
      me_wen = 0; me_tv = 1; me_tb = '1;
      se_wen = 0; se_tv = 1; se_tb = '1;
      vse_wen = 0; vse_tv = 1; vse_tb = '1;
      mne_wen = 0; mne_tv = 1; mne_tb = '1;
      mt_wen = 0; st_wen = 0; vst_wen = 0;
    end
    else if (c == 4) begin
      // epc trap+软件写同拍按位或合并角：两源数据互补（trap=0x1555.., 软件
      // wdata[63:1]=0x5555..），或合成 0x5555.. —— 与任一单源都不同，
      // 写成优先级选择的实现必被抓。tvec 同拍打合法 mode=1 写。
      me_wen = 1; me_wdata = 64'hAAAA_AAAA_AAAA_AAAA; me_tv = 1; me_tb = 63'h1555_5555_5555_5555;
      se_wen = 1; se_wdata = 64'hAAAA_AAAA_AAAA_AAAA; se_tv = 1; se_tb = 63'h1555_5555_5555_5555;
      vse_wen = 1; vse_wdata = 64'hAAAA_AAAA_AAAA_AAAA; vse_tv = 1; vse_tb = 63'h1555_5555_5555_5555;
      mne_wen = 1; mne_wdata = 64'hAAAA_AAAA_AAAA_AAAA; mne_tv = 1; mne_tb = 63'h1555_5555_5555_5555;
      mt_wen = 1; mt_wdata = 64'h1234_5678_9ABC_DEF1;   // mode=1 合法
      st_wen = 1; st_wdata = 64'hFEDC_BA98_7654_3211;   // mode=1 合法
      vst_wen = 1; vst_wdata = 64'h5555_AAAA_5A5A_A5A5; // mode=1 合法
    end
    else if (c == 5) begin
      // tvec 非法 mode 纯写角：mode=2/3 被丢弃保持上拍（=1），base 照写。
      // epc 撤掉一切写，读回上拍或合成结果。
      me_wen = 0; me_tv = 0; se_wen = 0; se_tv = 0;
      vse_wen = 0; vse_tv = 0; mne_wen = 0; mne_tv = 0;
      mt_wen = 1; mt_wdata = 64'hDEAD_BEEF_0000_0002;   // mode=2 非法
      st_wen = 1; st_wdata = 64'hCAFE_0000_0000_0003;   // mode=3 非法
      vst_wen = 1; vst_wdata = 64'h0123_4567_89AB_CDE2; // mode=2 非法
    end
    else if (c == 6) begin
      // epc trap 有效但数据全 0 角：OR 退化为纯软件写；
      // tvec 合法 mode=0 写（从 1 写回 0，覆盖 mode 下跳变）。
      me_wen = 1; me_wdata = 64'h0000_0000_0000_00F0; me_tv = 1; me_tb = '0;
      se_wen = 1; se_wdata = 64'h0000_0000_0000_0F00; se_tv = 1; se_tb = '0;
      vse_wen = 1; vse_wdata = 64'h0000_0000_0000_F000; vse_tv = 1; vse_tb = '0;
      mne_wen = 1; mne_wdata = 64'h0000_0000_0001_E000; mne_tv = 1; mne_tb = '0;
      mt_wen = 1; mt_wdata = 64'h0000_0000_0000_0400;   // mode=0 合法
      st_wen = 1; st_wdata = 64'h0000_0000_0000_0800;
      vst_wen = 1; vst_wdata = 64'h0000_0000_0000_0C00;
    end
    else begin
      // 随机档
      me_wen = $urandom_range(0, 1); me_wdata = wdata_pick();
      me_tv = ($urandom_range(0, 3) == 0); me_tb = trap_pick();
      se_wen = $urandom_range(0, 1); se_wdata = wdata_pick();
      se_tv = ($urandom_range(0, 3) == 0); se_tb = trap_pick();
      vse_wen = $urandom_range(0, 1); vse_wdata = wdata_pick();
      vse_tv = ($urandom_range(0, 3) == 0); vse_tb = trap_pick();
      mne_wen = $urandom_range(0, 1); mne_wdata = wdata_pick();
      mne_tv = ($urandom_range(0, 3) == 0); mne_tb = trap_pick();
      mt_wen = $urandom_range(0, 1); mt_wdata = wdata_pick();
      st_wen = $urandom_range(0, 1); st_wdata = wdata_pick();
      vst_wen = $urandom_range(0, 1); vst_wdata = wdata_pick();
    end
  endtask

  task automatic sample_fires();
    if (reset) return;
    if (me_wen | se_wen | vse_wen | mne_wen | mt_wen | st_wen | vst_wen) wen_fires++;
    if (me_tv | se_tv | vse_tv | mne_tv) trap_fires++;
    if ((me_wen & me_tv) | (se_wen & se_tv) | (vse_wen & vse_tv) | (mne_wen & mne_tv))
      both_fires++;
    if ((mt_wen && mt_wdata[1:0] >= 2'h2) ||
        (st_wen && st_wdata[1:0] >= 2'h2) ||
        (vst_wen && vst_wdata[1:0] >= 2'h2)) illmode_fires++;
    if ((mt_wen && mt_wdata[1:0] < 2'h2) ||
        (st_wen && st_wdata[1:0] < 2'h2) ||
        (vst_wen && vst_wdata[1:0] < 2'h2)) legalmode_fires++;
    if ((me_wen && me_wdata == 64'h0) || (se_wen && se_wdata == 64'h0) ||
        (vse_wen && vse_wdata == 64'h0) || (mne_wen && mne_wdata == 64'h0) ||
        (mt_wen && mt_wdata == 64'h0) || (st_wen && st_wdata == 64'h0) ||
        (vst_wen && vst_wdata == 64'h0)) all0_fires++;
    if ((me_wen && &me_wdata) || (se_wen && &se_wdata) ||
        (vse_wen && &vse_wdata) || (mne_wen && &mne_wdata) ||
        (mt_wen && &mt_wdata) || (st_wen && &st_wdata) ||
        (vst_wen && &vst_wdata)) all1_fires++;
  endtask

  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    me_wen = 0; me_wdata = '0; me_tv = 0; me_tb = '0;
    se_wen = 0; se_wdata = '0; se_tv = 0; se_tb = '0;
    vse_wen = 0; vse_wdata = '0; vse_tv = 0; vse_tb = '0;
    mne_wen = 0; mne_wdata = '0; mne_tv = 0; mne_tb = '0;
    mt_wen = 0; mt_wdata = '0;
    st_wen = 0; st_wdata = '0;
    vst_wen = 0; vst_wdata = '0;
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
    total_fires = wen_fires + trap_fires + both_fires + illmode_fires
                + legalmode_fires + all0_fires + all1_fires;
    $display("CsrEpcTvecLeaves7 UT: checks=%0d errors=%0d toggled=%0d/%0d fires=%0d",
             checks, errors, toggled, N_OUT, total_fires);
    $display("COV wen=%0d trap=%0d both=%0d illmode=%0d legalmode=%0d all0=%0d all1=%0d",
             wen_fires, trap_fires, both_fires, illmode_fires, legalmode_fires,
             all0_fires, all1_fires);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0) begin $display("TEST FAILED (coverage: no comparison happened)"); $fatal(1); end
    if (toggled < N_OUT) begin
      $display("TEST FAILED (coverage: only %0d/%0d outputs toggled)", toggled, N_OUT);
      $fatal(1);
    end
    if (wen_fires < minf || trap_fires < minf || both_fires < minf ||
        illmode_fires < minf || legalmode_fires < minf ||
        all0_fires < minf || all1_fires < minf) begin
      $display("TEST FAILED (coverage: some fire counter below floor %0d)", minf);
      $fatal(1);
    end
    $display("TEST PASSED");
    $finish;
  end
endmodule
