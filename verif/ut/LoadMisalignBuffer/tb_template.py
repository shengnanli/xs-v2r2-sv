# -*- coding: utf-8 -*-
"""tb_template.py —— LoadMisalignBuffer UT tb 的生成模板（被 scripts/gen_lmisalign.py 调用，不单独运行）。

端口声明、双例化连线、逐拍比对由端口表机械生成；**激励整形与覆盖计数是手写的**（SHAPE / MODEL /
COVER 三段 SystemVerilog 文本）。设计意图 —— 均匀随机几乎走不完一次"拆分→两次往返→唤醒→写回"，
所以 tb 扮演 LoadUnit：
  * enq：按相位变化的密度往 3 个口塞请求；80% 是真跨 16B 的非对齐 load（宽度 H/W/D、偏移贴着 16B 边界），
    其余含对齐的 / 不跨的 / lb / alignedType 4..7 的非法组合（golden 只有断言，行为照样要一致）；
    向量 30%；fuOpType 取自 load 指令全集（含 hlv*/hlvx*），fp load 20%；
  * LoadUnit 往返模型：golden 的 splitLoadReq fire 后，隔 1..4 拍把一个响应送回 splitLoadResp，
    robIdx 95% 取请求自己的（5% 乱写，测"robIdx 对不上"分支），唤醒请求回来时带 misalignNeedWakeUp；
    响应里异常 / 触发器 DebugMode / mmio / nc / replay 原因按低概率置位；另有 3% 的拍送一个与请求无关的乱响应；
  * redirect 2% 的拍，robIdx 取在条目附近（前后 4 个），level 随机：冲条目、冲入队者两种都常见；
  * writeBack.ready 80%，loadOutValid / loadVecOutValid 各 15%。

比对口径：每拍在输入稳定后（negedge+1）逐个比 golden 与 _xs 的全部输出口（!==）。
  ★+vcs+initreg+random / +<seed>017 档★：req 整包寄存器不复位，两侧初值不同；它们只在入队那一拍被整包写入，
  所以 +gate_req=1 时从 golden 第一次 canEnqValid 的下一拍才开始比（此前所有输出都不比）。
  常量档（+0 / +1）两侧初值相同，Makefile 给 +gate_req=0：从复位后第一拍就比。

覆盖判据（读 golden 内部信号）：6 个状态都到过、跨 16B 的 13 种合法拆分组合每种都拆过、不跨 16B 的也进过 s_split、
子访问成功 / replay / 异常 / uncache / robIdx 对不上、唤醒请求 fire、标量正常写回 / 异常写回 / 向量写回、
在空闲与非空闲时各被 redirect 冲掉、入队被本拍 redirect 拦下 —— **每项 ≥1**，否则本轮不作数（TEST FAILED）。
"""


def rand_expr(w):
    words = (w + 31) // 32
    if words == 1:
        return "%d'($urandom)" % w
    return "%d'({%s})" % (w, ', '.join(['$urandom'] * words))


SHAPE = r'''
  // ---------------------------------------------------------------------------
  // 激励整形（手写）
  // ---------------------------------------------------------------------------
  int          phase_enq_pct;      // 本相位每口 valid 的概率（%）
  logic        rob_flag_base;
  logic [7:0]  rob_base;           // robIdx 窗口基点（缓慢前移，跨回绕点）

  function automatic bit pct(int p);
    return ($urandom_range(0, 99) < p);
  endfunction

  function automatic logic [8:0] rob_near(int span);
    logic [8:0] r;
    r = {rob_flag_base, rob_base} + 9'($urandom_range(0, span));
    return r;
  endfunction

  task automatic new_phase();
    case ($urandom_range(0, 3))
      0: phase_enq_pct = 3;
      1: phase_enq_pct = 15;
      2: phase_enq_pct = 40;
      default: phase_enq_pct = 80;
    endcase
  endtask

  // 一个入队请求：返回 {fuOpType, isvec, alignedType, vaddr[49:0]} 与 fpWen
  task automatic shape_enq(output logic [8:0] op, output logic isvec, output logic [2:0] atype,
                           output logic [49:0] vaddr, output logic fpwen);
    logic [8:0] ops [16] = '{9'h00, 9'h01, 9'h02, 9'h03, 9'h04, 9'h05, 9'h06,
                             9'h10, 9'h11, 9'h12, 9'h13, 9'h14, 9'h15, 9'h16, 9'h1D, 9'h1E};
    logic [1:0] sz;
    int nbytes, off;
    // 注：跨 16B 的访问必然不对齐，所以 split_plan 的"非法组合"（lb / 对齐的 lw、ld）在跨 16B 时结构上不可达，
    //     只能靠 FM 证等价；这里能打到的是"不跨 16B 也进来了"（s_split 什么都不写）。
    op    = pct(95) ? ops[$urandom_range(0, 15)] : 9'($urandom);
    isvec = pct(30);
    fpwen = pct(20);
    sz    = op[1:0];
    if (isvec) begin
      atype = pct(95) ? {1'b0, 2'($urandom)} : 3'($urandom_range(4, 7));
      sz    = atype[1:0];
    end else begin
      atype = 3'($urandom);
    end
    vaddr = 50'({$urandom, $urandom});
    nbytes = 1 << sz;
    if (pct(80) && nbytes > 1) begin
      // 真跨 16B：起点落在 [16-nbytes+1, 15]，且按宽度不对齐（对齐的访问不会跨）
      do off = $urandom_range(16 - nbytes + 1, 15); while (off % nbytes == 0);
      vaddr[3:0] = 4'(off);
    end else if (pct(50)) begin
      vaddr[3:0] = 4'($urandom_range(13, 15));
    end
  endtask
'''

MODEL = r'''
  // ---------------------------------------------------------------------------
  // LoadUnit 往返模型：splitLoadReq fire → 隔 1..4 拍回一个 splitLoadResp
  // ---------------------------------------------------------------------------
  typedef struct {
    int         due;
    logic [8:0] rob;
    logic       wakeup;
  } pend_t;
  pend_t pend_q [$];

  task automatic drive_resp();
    logic has;
    has = 0;
    io_splitLoadResp_valid = 0;
    if (pend_q.size() > 0 && pend_q[0].due <= cyc) begin
      pend_t p;
      p = pend_q.pop_front();
      has = 1;
      io_splitLoadResp_valid = 1;
      {io_splitLoadResp_bits_uop_robIdx_flag, io_splitLoadResp_bits_uop_robIdx_value} =
        pct(95) ? p.rob : 9'($urandom);
      io_splitLoadResp_bits_misalignNeedWakeUp = pct(95) ? p.wakeup : 1'($urandom);
    end else if (pct(3)) begin
      io_splitLoadResp_valid = 1;   // 与任何请求无关的乱响应
      has = 1;
    end
    if (has) begin
      // 异常 / 触发器 / uncache / replay 按低概率
      io_splitLoadResp_bits_vecActive = pct(85);
      {io_splitLoadResp_bits_uop_exceptionVec_3, io_splitLoadResp_bits_uop_exceptionVec_4,
       io_splitLoadResp_bits_uop_exceptionVec_5, io_splitLoadResp_bits_uop_exceptionVec_13,
       io_splitLoadResp_bits_uop_exceptionVec_19, io_splitLoadResp_bits_uop_exceptionVec_21} =
        pct(8) ? 6'($urandom) : 6'h0;
      io_splitLoadResp_bits_uop_trigger = pct(3) ? 4'h1 : (pct(50) ? 4'hF : 4'($urandom));
      io_splitLoadResp_bits_mmio = pct(3);
      io_splitLoadResp_bits_nc   = pct(3);
      {io_splitLoadResp_bits_rep_info_cause_10, io_splitLoadResp_bits_rep_info_cause_9,
       io_splitLoadResp_bits_rep_info_cause_8, io_splitLoadResp_bits_rep_info_cause_7,
       io_splitLoadResp_bits_rep_info_cause_6, io_splitLoadResp_bits_rep_info_cause_5,
       io_splitLoadResp_bits_rep_info_cause_4, io_splitLoadResp_bits_rep_info_cause_3,
       io_splitLoadResp_bits_rep_info_cause_2, io_splitLoadResp_bits_rep_info_cause_1,
       io_splitLoadResp_bits_rep_info_cause_0} = pct(15) ? (11'h1 << $urandom_range(0, 10)) : 11'h0;
    end else if (pct(50)) begin
      io_splitLoadResp_bits_misalignNeedWakeUp = 0;
    end
  endtask

  // 本拍（下一个 posedge）golden 的 splitLoadReq fire 了：登记一个待回响应
  task automatic model_update();
    if (g_io_splitLoadReq_valid && io_splitLoadReq_ready) begin
      pend_t p;
      p.due    = cyc + $urandom_range(1, 4);
      p.rob    = {g_io_splitLoadReq_bits_uop_robIdx_flag, g_io_splitLoadReq_bits_uop_robIdx_value};
      p.wakeup = g_io_splitLoadReq_bits_misalignNeedWakeUp;
      if (pct(97)) pend_q.push_back(p);     // 3% 丢掉（LoadUnit 那边被冲掉的情形）
    end
  endtask

  task automatic drive_inputs();
    logic [8:0] op; logic isvec, fpwen; logic [2:0] atype; logic [49:0] va;
    randomize_all_inputs();
    // enq 三口
    `ENQ_SHAPE(0)
    `ENQ_SHAPE(1)
    `ENQ_SHAPE(2)
    io_splitLoadReq_ready = pct(75);
    drive_resp();
    io_writeBack_ready  = pct(80);
    io_loadOutValid     = pct(15);
    io_loadVecOutValid  = pct(15);
    io_redirect_valid   = pct(2);
    {io_redirect_bits_robIdx_flag, io_redirect_bits_robIdx_value} = rob_near(10) - 9'd4;
    // robIdx 窗口缓慢前移
    if (pct(2)) {rob_flag_base, rob_base} = {rob_flag_base, rob_base} + 9'd1;
  endtask
'''

ENQ_MACRO = r'''
`define ENQ_SHAPE(I) \
    io_enq_``I``_req_valid = pct(phase_enq_pct); \
    shape_enq(op, isvec, atype, va, fpwen); \
    io_enq_``I``_req_bits_uop_fuOpType = op; \
    io_enq_``I``_req_bits_isvec = isvec; \
    io_enq_``I``_req_bits_alignedType = atype; \
    io_enq_``I``_req_bits_vaddr = va; \
    io_enq_``I``_req_bits_uop_fpWen = fpwen; \
    {io_enq_``I``_req_bits_uop_robIdx_flag, io_enq_``I``_req_bits_uop_robIdx_value} = rob_near(6);
'''

COVER = r'''
  // ---------------------------------------------------------------------------
  // 覆盖计数（读 golden 内部）
  // ---------------------------------------------------------------------------
  int cov_state [6];
  int cov_split_combo [4][8];     // [size][vaddr[2:0]]，只在 s_split 且跨 16B 时计
  int cov_split_nocross, cov_resp_ok, cov_resp_rep, cov_resp_exc, cov_resp_unc, cov_resp_robmiss;
  int cov_wakeup_fire, cov_wb_normal, cov_wb_abort, cov_vec_wb, cov_flush_idle, cov_flush_busy;
  int cov_enq_blocked_by_redirect, cov_enq;

  task automatic cover_sample();
    logic [1:0] sz;
    if (u_g.bufferState < 6) cov_state[u_g.bufferState]++;
    sz = u_g.alignedType;
    if (u_g.bufferState == 1 && u_g.cross16BytesBoundary)
      cov_split_combo[sz][u_g.req_vaddr[2:0]]++;
    if (u_g.bufferState == 1 && !u_g.cross16BytesBoundary)
      cov_split_nocross++;   // 不跨 16B 还进来了（golden 只有断言）：拆分寄存器不写
    if (io_splitLoadResp_valid && u_g.bufferState == 3) begin
      if ({u_g.req_uop_robIdx_flag, u_g.req_uop_robIdx_value}
          != {io_splitLoadResp_bits_uop_robIdx_flag, io_splitLoadResp_bits_uop_robIdx_value})
        cov_resp_robmiss++;
      if (u_g.isUncache) cov_resp_unc++;
      else if (u_g.hasException) cov_resp_exc++;
      else if (|{io_splitLoadResp_bits_rep_info_cause_0, io_splitLoadResp_bits_rep_info_cause_1,
                  io_splitLoadResp_bits_rep_info_cause_2, io_splitLoadResp_bits_rep_info_cause_3,
                  io_splitLoadResp_bits_rep_info_cause_4, io_splitLoadResp_bits_rep_info_cause_5,
                  io_splitLoadResp_bits_rep_info_cause_6, io_splitLoadResp_bits_rep_info_cause_7,
                  io_splitLoadResp_bits_rep_info_cause_8, io_splitLoadResp_bits_rep_info_cause_9,
                  io_splitLoadResp_bits_rep_info_cause_10}) cov_resp_rep++;
      else cov_resp_ok++;
    end
    if (g_io_splitLoadReq_valid && io_splitLoadReq_ready && g_io_splitLoadReq_bits_misalignNeedWakeUp)
      cov_wakeup_fire++;
    if (g_io_writeBack_valid && io_writeBack_ready) begin
      if (u_g.globalException || u_g.globalUncache) cov_wb_abort++; else cov_wb_normal++;
    end
    if (g_io_vecWriteBack_valid) cov_vec_wb++;
    if (u_g.flush_probe) begin
      if (u_g.bufferState == 0) cov_flush_idle++; else cov_flush_busy++;
    end
    if (!u_g.req_valid && (io_enq_0_req_valid || io_enq_1_req_valid || io_enq_2_req_valid)) begin
      if (u_g.canEnqValid) cov_enq++; else cov_enq_blocked_by_redirect++;
    end
  endtask

  function automatic int cover_report();
    int holes;
    holes = 0;
    $display("COVER states: idle=%0d split=%0d req=%0d resp=%0d comb=%0d wb=%0d",
             cov_state[0], cov_state[1], cov_state[2], cov_state[3], cov_state[4], cov_state[5]);
    for (int s = 0; s < 6; s++) if (cov_state[s] == 0) holes++;
    $display("COVER split legal combos: H/x=%0d  W/01=%0d W/10=%0d W/11=%0d  D/001..111=%0d %0d %0d %0d %0d %0d %0d",
             cov_split_combo[1][0] + cov_split_combo[1][1] + cov_split_combo[1][2] + cov_split_combo[1][3]
             + cov_split_combo[1][4] + cov_split_combo[1][5] + cov_split_combo[1][6] + cov_split_combo[1][7],
             cov_split_combo[2][1] + cov_split_combo[2][5], cov_split_combo[2][2] + cov_split_combo[2][6],
             cov_split_combo[2][3] + cov_split_combo[2][7],
             cov_split_combo[3][1], cov_split_combo[3][2], cov_split_combo[3][3], cov_split_combo[3][4],
             cov_split_combo[3][5], cov_split_combo[3][6], cov_split_combo[3][7]);
    if (cov_split_combo[1][7] == 0) holes++;
    for (int o = 1; o < 4; o++) if (cov_split_combo[2][o] + cov_split_combo[2][o + 4] == 0) holes++;
    for (int o = 1; o < 8; o++) if (cov_split_combo[3][o] == 0) holes++;
    $display("COVER split_nocross=%0d resp: ok=%0d rep=%0d exc=%0d uncache=%0d robIdx-mismatch=%0d",
             cov_split_nocross, cov_resp_ok, cov_resp_rep, cov_resp_exc, cov_resp_unc, cov_resp_robmiss);
    $display("COVER wakeup_fire=%0d wb_normal=%0d wb_abort=%0d vec_wb=%0d flush_idle=%0d flush_busy=%0d enq=%0d enq_blocked=%0d",
             cov_wakeup_fire, cov_wb_normal, cov_wb_abort, cov_vec_wb, cov_flush_idle, cov_flush_busy,
             cov_enq, cov_enq_blocked_by_redirect);
    if (cov_split_nocross == 0) holes++;
    if (cov_resp_ok == 0) holes++;
    if (cov_resp_rep == 0) holes++;
    if (cov_resp_exc == 0) holes++;
    if (cov_resp_unc == 0) holes++;
    if (cov_resp_robmiss == 0) holes++;
    if (cov_wakeup_fire == 0) holes++;
    if (cov_wb_normal == 0) holes++;
    if (cov_wb_abort == 0) holes++;
    if (cov_vec_wb == 0) holes++;
    if (cov_flush_idle == 0) holes++;
    if (cov_flush_busy == 0) holes++;
    if (cov_enq == 0) holes++;
    if (cov_enq_blocked_by_redirect == 0) holes++;
    return holes;
  endfunction
'''


def gen_tb(ports, cls):
    ins = [(w, n) for d, w, n in ports if d == 'input' and n not in ('clock', 'reset')]
    outs = [(w, n) for d, w, n in ports if d == 'output']

    def rng(w):
        return '' if w == 1 else '[%d:0] ' % (w - 1)

    o = []
    o.append('// LoadMisalignBuffer UT —— golden 与重写件（LoadMisalignBuffer_xs）双例化，逐拍比全部 %d 个输出口'
             % len(outs))
    o.append('// 自动生成：scripts/gen_lmisalign.py + verif/ut/LoadMisalignBuffer/tb_template.py —— 勿手改')
    o.append('// 激励 / 比对口径 / 覆盖判据见 tb_template.py 文件头。')
    o.append('`timescale 1ns/1ps')
    o.append(ENQ_MACRO.strip('\n'))
    o.append('module tb;')
    o.append('  int unsigned NCYCLES = 200000;')
    o.append('  int gate_req = 1;')
    o.append('  logic clock = 0, reset = 1;')
    o.append('  int errors = 0, checks = 0, cyc = 0;')
    o.append('  bit req_seen = 0;')
    o.append('')
    o.append('  // ---- 输入（两侧共用）----')
    for w, n in ins:
        o.append('  logic %s%s;' % (rng(w), n))
    o.append('  // ---- 输出（g_ = golden，i_ = 重写件）----')
    for w, n in outs:
        o.append('  wire  %s g_%s, i_%s;' % (rng(w), n, n))
    o.append('')
    for mod, inst, pfx in (('LoadMisalignBuffer', 'u_g', 'g_'), ('LoadMisalignBuffer_xs', 'u_i', 'i_')):
        o.append('  %s %s (' % (mod, inst))
        conns = ['    .clock (clock)', '    .reset (reset)']
        for w, n in ins:
            conns.append('    .%s (%s)' % (n, n))
        for w, n in outs:
            conns.append('    .%s (%s%s)' % (n, pfx, n))
        o.append(',\n'.join(conns))
        o.append('  );')
        o.append('')
    o.append('  task automatic randomize_all_inputs();')
    for w, n in ins:
        o.append('    %s = %s;' % (n, rand_expr(w)))
    o.append('  endtask')
    o.append(SHAPE.rstrip('\n'))
    o.append(MODEL.rstrip('\n'))
    o.append(COVER.rstrip('\n'))
    o.append('')
    o.append('  task automatic compare_outputs();')
    o.append('    checks++;')
    for w, n in outs:
        o.append('    if (g_%s !== i_%s) begin' % (n, n))
        o.append('      errors++;')
        o.append('      if (errors <= 20) $display("MISMATCH cyc=%%0d %s g=%%h i=%%h", cyc, g_%s, i_%s);'
                 % (n, n, n))
        o.append('    end')
    o.append('  endtask')
    o.append('')
    o.append('  always #5 clock = ~clock;')
    o.append('')
    o.append('  initial begin')
    o.append('    int holes;')
    o.append('    void\'($value$plusargs("ncycles=%d", NCYCLES));')
    o.append('    void\'($value$plusargs("gate_req=%d", gate_req));')
    o.append('    rob_flag_base = 0; rob_base = 8\'($urandom);')
    o.append('    new_phase();')
    o.append('    randomize_all_inputs();')
    o.append('    io_redirect_valid = 0; io_splitLoadResp_valid = 0;')
    o.append('    io_enq_0_req_valid = 0; io_enq_1_req_valid = 0; io_enq_2_req_valid = 0;')
    o.append('    repeat (5) @(negedge clock);')
    o.append('    reset = 0;')
    o.append('    for (cyc = 0; cyc < NCYCLES; cyc++) begin')
    o.append('      @(negedge clock);')
    o.append('      if (cyc % 1024 == 0) new_phase();')
    o.append('      drive_inputs();')
    o.append('      #1;')
    o.append('      if (!gate_req || req_seen) compare_outputs();')
    o.append('      if (u_g.canEnqValid) req_seen = 1;')
    o.append('      cover_sample();')
    o.append('      model_update();')
    o.append('    end')
    o.append('    holes = cover_report();')
    o.append('    $display("checks=%0d errors=%0d cover_holes=%0d", checks, errors, holes);')
    o.append('    if (errors == 0 && holes == 0) $display("TEST PASSED");')
    o.append('    else $display("TEST FAILED");')
    o.append('    $finish;')
    o.append('  end')
    o.append('endmodule')
    return '\n'.join(o) + '\n'
