# -*- coding: utf-8 -*-
"""tb_template.py —— StoreMisalignBuffer UT tb 的生成模板（被 scripts/gen_smisalign.py 调用，不单独运行）。

端口声明、双例化连线、逐拍比对由端口表机械生成；**激励整形与覆盖计数是手写的**（SHAPE / MODEL / COVER）。
tb 扮演 StoreUnit + ROB + StoreQueue：
  * enq：两口按相位变化的密度塞请求；80% 真跨 16B（其中约 1/3 同时跨 4KB 页：vaddr[11:4] 取全 1），
    两口 robIdx 取在同一个小窗口里（常相等，uopIdx 0..3 决胜负），向量 30%；入队下一拍 10% revoke；
  * StoreUnit 往返模型：golden splitStoreReq fire 后隔 1..4 拍回 splitStoreResp，robIdx 95% 取请求自己的；
    need_rep 15%，异常 8%，触发器 DebugMode 3%，mmio / nc 各 3%；另有 3% 的拍送无关的乱响应；
  * ROB：pendingst 50%，pendingPtr 60% 取条目自己的 robIdx（跨页条目才能开拆）；
  * StoreQueue：doDeq 30%；sqPtr / uop 各 50% 取条目自己的（crossPageWithHit / withSamePtr 两边都常见）；
  * redirect 2%，robIdx 在窗口附近；writeBack.ready 80%，storeOutValid / storeVecOutValid 各 15%。

比对口径：每拍在输入稳定后（negedge+1）逐个比全部输出口（!==）。
  ★+vcs+initreg+random / +<seed>017 档★：req 整包寄存器不复位，两侧初值不同；req 只在入队那一拍被整包写入，
  所以 +gate_req=1 时从 golden 第一次 canEnq 的下一拍才开始比。常量档（+0 / +1）从复位后第一拍就比。

覆盖判据（读 golden 内部信号）：6 个状态都到过、13 种跨 16B 拆分组合、不跨 16B 的 s_split、子访问成功 / replay /
异常 / uncache / robIdx 不符、两片齐后多等一拍去 s_wb、标量正常 / 异常写回、向量写回两个口、跨页进 s_block 且被 doDeq
放行、跨页条目被更老的 store 顶替、revoke 杀条目、在空闲与非空闲时各被 redirect 冲掉、入队 / 入队被 redirect 拦下
—— **每项 ≥1**，否则本轮不作数（TEST FAILED）。
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
  int          phase_enq_pct;
  logic        rob_flag_base;
  logic [7:0]  rob_base;

  function automatic bit pct(int p);
    return ($urandom_range(0, 99) < p);
  endfunction

  function automatic logic [8:0] rob_near(int span);
    return {rob_flag_base, rob_base} + 9'($urandom_range(0, span));
  endfunction

  task automatic new_phase();
    case ($urandom_range(0, 3))
      0: phase_enq_pct = 3;
      1: phase_enq_pct = 15;
      2: phase_enq_pct = 40;
      default: phase_enq_pct = 80;
    endcase
  endtask

  task automatic shape_enq(output logic [8:0] op, output logic isvec, output logic [2:0] atype,
                           output logic [49:0] vaddr);
    logic [8:0] ops [8] = '{9'h00, 9'h01, 9'h02, 9'h03, 9'h10, 9'h11, 9'h12, 9'h13};
    logic [1:0] sz;
    int nbytes, off;
    op    = pct(95) ? ops[$urandom_range(0, 7)] : 9'($urandom);
    isvec = pct(30);
    sz    = op[1:0];
    if (isvec) begin
      atype = pct(95) ? {1'b0, 2'($urandom)} : 3'($urandom_range(4, 7));
      sz    = atype[1:0];
    end else begin
      atype = 3'($urandom);
    end
    vaddr  = 50'({$urandom, $urandom});
    nbytes = 1 << sz;
    if (pct(80) && nbytes > 1) begin
      do off = $urandom_range(16 - nbytes + 1, 15); while (off % nbytes == 0);
      vaddr[3:0] = 4'(off);
      if (pct(35)) vaddr[11:4] = 8'hFF;     // 同时跨 4KB 页
    end else if (pct(50)) begin
      vaddr[3:0] = 4'($urandom_range(13, 15));
    end
  endtask
'''

MODEL = r'''
  // ---------------------------------------------------------------------------
  // StoreUnit 往返模型：splitStoreReq fire → 隔 1..4 拍回一个 splitStoreResp
  // ---------------------------------------------------------------------------
  typedef struct {
    int         due;
    logic [8:0] rob;
  } pend_t;
  pend_t pend_q [$];

  task automatic drive_resp();
    logic has;
    has = 0;
    io_splitStoreResp_valid = 0;
    if (pend_q.size() > 0 && pend_q[0].due <= cyc) begin
      pend_t p;
      p = pend_q.pop_front();
      has = 1;
      io_splitStoreResp_valid = 1;
      {io_splitStoreResp_bits_uop_robIdx_flag, io_splitStoreResp_bits_uop_robIdx_value} =
        pct(95) ? p.rob : 9'($urandom);
    end else if (pct(3)) begin
      io_splitStoreResp_valid = 1;
      has = 1;
    end
    if (has) begin
      io_splitStoreResp_bits_vecActive = pct(85);
      {io_splitStoreResp_bits_uop_exceptionVec_3, io_splitStoreResp_bits_uop_exceptionVec_6,
       io_splitStoreResp_bits_uop_exceptionVec_7, io_splitStoreResp_bits_uop_exceptionVec_15,
       io_splitStoreResp_bits_uop_exceptionVec_19, io_splitStoreResp_bits_uop_exceptionVec_23} =
        pct(8) ? 6'($urandom) : 6'h0;
      io_splitStoreResp_bits_uop_trigger = pct(3) ? 4'h1 : (pct(50) ? 4'hF : 4'($urandom));
      io_splitStoreResp_bits_mmio     = pct(3);
      io_splitStoreResp_bits_nc       = pct(3);
      io_splitStoreResp_bits_need_rep = pct(15);
    end
  endtask

  task automatic model_update();
    if (g_io_splitStoreReq_valid && io_splitStoreReq_ready) begin
      pend_t p;
      p.due = cyc + $urandom_range(1, 4);
      p.rob = {g_io_splitStoreReq_bits_uop_robIdx_flag, g_io_splitStoreReq_bits_uop_robIdx_value};
      if (pct(97)) pend_q.push_back(p);
    end
  endtask

  task automatic drive_inputs();
    logic [8:0] op; logic isvec; logic [2:0] atype; logic [49:0] va;
    logic [8:0] req_rob;
    randomize_all_inputs();
    req_rob = {u_g.req_uop_robIdx_flag, u_g.req_uop_robIdx_value};
    `ENQ_SHAPE(0)
    `ENQ_SHAPE(1)
    io_enq_0_revoke = pct(10);
    io_enq_1_revoke = pct(10);
    io_splitStoreReq_ready = pct(75);
    drive_resp();
    io_writeBack_ready     = pct(80);
    io_storeOutValid       = pct(15);
    io_storeVecOutValid    = pct(15);
    io_rob_pendingst       = pct(50);
    {io_rob_pendingPtr_flag, io_rob_pendingPtr_value} = pct(60) ? req_rob : rob_near(8);
    io_sqControl_toStoreMisalignBuffer_doDeq = pct(30);
    if (pct(50)) {io_sqControl_toStoreMisalignBuffer_sqPtr_flag, io_sqControl_toStoreMisalignBuffer_sqPtr_value} =
                   {u_g.req_uop_sqIdx_flag, u_g.req_uop_sqIdx_value};
    if (pct(50)) begin
      {io_sqControl_toStoreMisalignBuffer_uop_robIdx_flag, io_sqControl_toStoreMisalignBuffer_uop_robIdx_value} = req_rob;
      io_sqControl_toStoreMisalignBuffer_uop_uopIdx = u_g.req_uop_uopIdx;
    end
    io_redirect_valid = pct(2);
    {io_redirect_bits_robIdx_flag, io_redirect_bits_robIdx_value} = rob_near(10) - 9'd4;
    if (pct(2)) {rob_flag_base, rob_base} = {rob_flag_base, rob_base} + 9'd1;
  endtask
'''

ENQ_MACRO = r'''
`define ENQ_SHAPE(I) \
    io_enq_``I``_req_valid = pct(phase_enq_pct); \
    shape_enq(op, isvec, atype, va); \
    io_enq_``I``_req_bits_uop_fuOpType = op; \
    io_enq_``I``_req_bits_isvec = isvec; \
    io_enq_``I``_req_bits_alignedType = atype; \
    io_enq_``I``_req_bits_vaddr = va; \
    io_enq_``I``_req_bits_uop_uopIdx = 7'($urandom_range(0, 3)); \
    {io_enq_``I``_req_bits_uop_robIdx_flag, io_enq_``I``_req_bits_uop_robIdx_value} = rob_near(3);
'''

COVER = r'''
  // ---------------------------------------------------------------------------
  // 覆盖计数（读 golden 内部）
  // ---------------------------------------------------------------------------
  int cov_state [6];
  int cov_split_combo [4][8];
  int cov_split_nocross, cov_resp_ok, cov_resp_rep, cov_resp_exc, cov_resp_unc, cov_resp_robmiss;
  int cov_delay_to_wb, cov_wb_normal, cov_wb_abort, cov_vec_wb0, cov_vec_wb1, cov_block_release;
  int cov_crosspage, cov_replace, cov_revoke_kill, cov_flush_idle, cov_flush_busy, cov_enq, cov_enq_blocked;

  task automatic cover_sample();
    logic [1:0] sz;
    if (u_g.bufferState < 6) cov_state[u_g.bufferState]++;
    sz = u_g.alignedType;
    if (u_g.bufferState == 1 && u_g.cross16BytesBoundary) cov_split_combo[sz][u_g.req_vaddr[2:0]]++;
    if (u_g.bufferState == 1 && !u_g.cross16BytesBoundary) cov_split_nocross++;
    if (u_g.bufferState == 1 && u_g.isCrossPage) cov_crosspage++;
    if (io_splitStoreResp_valid && u_g.bufferState == 3) begin
      if ({u_g.req_uop_robIdx_flag, u_g.req_uop_robIdx_value}
          != {io_splitStoreResp_bits_uop_robIdx_flag, io_splitStoreResp_bits_uop_robIdx_value})
        cov_resp_robmiss++;
      if (u_g.isUncache) cov_resp_unc++;
      else if (u_g.hasException) cov_resp_exc++;
      else if (io_splitStoreResp_bits_need_rep) cov_resp_rep++;
      else cov_resp_ok++;
    end
    if (u_g.bufferState == 3 && u_g.REG) cov_delay_to_wb++;
    if (g_io_writeBack_valid && io_writeBack_ready) begin
      if (u_g.globalException || u_g.globalUncache) cov_wb_abort++; else cov_wb_normal++;
    end
    if (g_io_vecWriteBack_0_valid) cov_vec_wb0++;
    if (g_io_vecWriteBack_1_valid) cov_vec_wb1++;
    if (u_g.bufferState == 5 && io_sqControl_toStoreMisalignBuffer_doDeq) cov_block_release++;
    if (u_g.req_valid && u_g.cross4KBPageBoundary && (g_io_enq_0_req_ready || g_io_enq_1_req_ready)
        && u_g.canEnq) cov_replace++;
    if (u_g.s2_needRevoke) cov_revoke_kill++;
    if (u_g.flush_probe) begin
      if (u_g.bufferState == 0) cov_flush_idle++; else cov_flush_busy++;
    end
    if (!u_g.req_valid && (io_enq_0_req_valid || io_enq_1_req_valid)) begin
      if (u_g.canEnq) cov_enq++; else cov_enq_blocked++;
    end
  endtask

  function automatic int cover_report();
    int holes;
    holes = 0;
    $display("COVER states: idle=%0d split=%0d req=%0d resp=%0d wb=%0d block=%0d",
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
    $display("COVER split_nocross=%0d crosspage_split=%0d resp: ok=%0d rep=%0d exc=%0d uncache=%0d robIdx-mismatch=%0d delay_to_wb=%0d",
             cov_split_nocross, cov_crosspage, cov_resp_ok, cov_resp_rep, cov_resp_exc, cov_resp_unc,
             cov_resp_robmiss, cov_delay_to_wb);
    $display("COVER wb_normal=%0d wb_abort=%0d vec_wb0=%0d vec_wb1=%0d block_release=%0d replace=%0d revoke_kill=%0d flush_idle=%0d flush_busy=%0d enq=%0d enq_blocked=%0d",
             cov_wb_normal, cov_wb_abort, cov_vec_wb0, cov_vec_wb1, cov_block_release, cov_replace,
             cov_revoke_kill, cov_flush_idle, cov_flush_busy, cov_enq, cov_enq_blocked);
    if (cov_split_nocross == 0) holes++;
    if (cov_crosspage == 0) holes++;
    if (cov_resp_ok == 0) holes++;
    if (cov_resp_rep == 0) holes++;
    if (cov_resp_exc == 0) holes++;
    if (cov_resp_unc == 0) holes++;
    if (cov_resp_robmiss == 0) holes++;
    if (cov_delay_to_wb == 0) holes++;
    if (cov_wb_normal == 0) holes++;
    if (cov_wb_abort == 0) holes++;
    if (cov_vec_wb0 == 0) holes++;
    if (cov_vec_wb1 == 0) holes++;
    if (cov_block_release == 0) holes++;
    if (cov_replace == 0) holes++;
    if (cov_revoke_kill == 0) holes++;
    if (cov_flush_idle == 0) holes++;
    if (cov_flush_busy == 0) holes++;
    if (cov_enq == 0) holes++;
    if (cov_enq_blocked == 0) holes++;
    return holes;
  endfunction
'''


def gen_tb(ports, cls):
    ins = [(w, n) for d, w, n in ports if d == 'input' and n not in ('clock', 'reset')]
    outs = [(w, n) for d, w, n in ports if d == 'output']

    def rng(w):
        return '' if w == 1 else '[%d:0] ' % (w - 1)

    o = []
    o.append('// StoreMisalignBuffer UT —— golden 与重写件（StoreMisalignBuffer_xs）双例化，逐拍比全部 %d 个输出口'
             % len(outs))
    o.append('// 自动生成：scripts/gen_smisalign.py + verif/ut/StoreMisalignBuffer/tb_template.py —— 勿手改')
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
    for mod, inst, pfx in (('StoreMisalignBuffer', 'u_g', 'g_'), ('StoreMisalignBuffer_xs', 'u_i', 'i_')):
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
    o.append('    io_redirect_valid = 0; io_splitStoreResp_valid = 0;')
    o.append('    io_enq_0_req_valid = 0; io_enq_1_req_valid = 0;')
    o.append('    repeat (5) @(negedge clock);')
    o.append('    reset = 0;')
    o.append('    for (cyc = 0; cyc < NCYCLES; cyc++) begin')
    o.append('      @(negedge clock);')
    o.append('      if (cyc % 1024 == 0) new_phase();')
    o.append('      drive_inputs();')
    o.append('      #1;')
    o.append('      if (!gate_req || req_seen) compare_outputs();')
    o.append('      if (u_g.canEnq) req_seen = 1;')
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
