#!/usr/bin/env python3
"""RenameTable 家族 UT 的 tb 生成器（四个变体同一个 tb 里各自双例化逐拍比对）。

为什么生成：四个变体的端口是 159/139/175/62 个展平端口，激励与比对逻辑逐字相同，
只有维度不同。手抄四遍必然"改了三份忘了第四份"。

激励要打到的几件事（均匀随机打不到，所以按相位轮转 + 窄地址域）：
  · 多个写口写**同一个地址** -> 投机写优先链（口号大的赢）与 arch 写 else-if 链；
  · 写地址 == 读地址 -> t1_bypass 那 N_READ x N_WRITE 个寄存器；
  · 读口 hold 住 -> 旁路比的是锁存地址而不是本拍地址（两条分支都要走到）；
  · io_redirect -> t1_wSpec/t1_bypass 被清零、下一拍整表从 arch_table/快照恢复；
  · snpt useSnpt + snptSelect 的 4 种取值 -> 四张快照都要被选中过；
  · old_pdest 的同址前缀旁路 + need_free 的"arch 表里一格都没有"与去重。

用法: python3 gen_tb.py [--check]
"""
import os
import sys

# name, N_ENTRIES, ADDR_W, N_READ, HAS_NEED_FREE, DIFF_N, DIFF_OFF, DBG_N, HAS_DBG_V0
VARIANTS = [
    ("RenameTable",   32, 5, 12, 1, 32, 0, 32, 0),
    ("RenameTable_1", 34, 6, 18, 0, 32, 0,  0, 0),
    ("RenameTable_2", 47, 6, 18, 1, 31, 1, 31, 0),
    ("RenameTable_3",  1, 0,  6, 1,  1, 0,  1, 1),
]
NW = 6


def emit(v):
    name, N, AW, NR, HNF, DIFF_N, DIFF_OFF, DBG_N, HAS_V0 = v
    p = name.lower()
    L = []
    a = L.append
    a("  // %s" % ("=" * 74))
    a("  // %s: %d 格 / addr %d 位 / %d 读口 / need_free %s / debug_rdata %d 格"
      % (name, N, AW, NR, "有" if HNF else "无", DBG_N))
    a("  // %s" % ("=" * 74))
    a("  logic            %s_redirect;" % p)
    a("  logic            %s_rd_hold [%d];" % (p, NR))
    if AW:
        a("  logic [%d:0]      %s_rd_addr [%d];" % (AW - 1, p, NR))
    a("  logic            %s_sw_wen [%d];" % (p, NW))
    a("  logic [7:0]      %s_sw_data [%d];" % (p, NW))
    a("  logic            %s_aw_wen [%d];" % (p, NW))
    a("  logic [7:0]      %s_aw_data [%d];" % (p, NW))
    if AW:
        a("  logic [%d:0]      %s_sw_addr [%d];" % (AW - 1, p, NW))
        a("  logic [%d:0]      %s_aw_addr [%d];" % (AW - 1, p, NW))
    a("  logic            %s_snpt_enq, %s_snpt_deq, %s_snpt_use;" % (p, p, p))
    a("  logic [1:0]      %s_snpt_sel;" % p)
    a("  logic [3:0]      %s_snpt_flush;" % p)
    for side in ("g", "i"):
        a("  logic [7:0] %s_%s_rdata [%d];" % (p, side, NR))
        a("  logic [7:0] %s_%s_oldp [%d];" % (p, side, NW))
        a("  logic       %s_%s_nfree [%d];" % (p, side, NW))
        a("  logic [7:0] %s_%s_diff [%d];" % (p, side, DIFF_N))
        if DBG_N:
            a("  logic [7:0] %s_%s_dbg [%d];" % (p, side, DBG_N))
        if HAS_V0:
            a("  logic [7:0] %s_%s_dv0;" % (p, side))
    a("")
    for side, mod in (("g", name), ("i", name + "_xs")):
        a("  %s %s_%s_u (" % (mod, p, side))
        a("    .clock(clk), .reset(rst), .io_redirect(%s_redirect)," % p)
        for r in range(NR):
            a("    .io_readPorts_%d_hold(%s_rd_hold[%d])," % (r, p, r))
            if AW:
                a("    .io_readPorts_%d_addr(%s_rd_addr[%d])," % (r, p, r))
            a("    .io_readPorts_%d_data(%s_%s_rdata[%d])," % (r, p, side, r))
        for j in range(NW):
            a("    .io_specWritePorts_%d_wen(%s_sw_wen[%d])," % (j, p, j))
            if AW:
                a("    .io_specWritePorts_%d_addr(%s_sw_addr[%d])," % (j, p, j))
            a("    .io_specWritePorts_%d_data(%s_sw_data[%d])," % (j, p, j))
        for j in range(NW):
            a("    .io_archWritePorts_%d_wen(%s_aw_wen[%d])," % (j, p, j))
            if AW:
                a("    .io_archWritePorts_%d_addr(%s_aw_addr[%d])," % (j, p, j))
            a("    .io_archWritePorts_%d_data(%s_aw_data[%d])," % (j, p, j))
        for j in range(NW):
            a("    .io_old_pdest_%d(%s_%s_oldp[%d])," % (j, p, side, j))
        if HNF:
            for j in range(NW):
                a("    .io_need_free_%d(%s_%s_nfree[%d])," % (j, p, side, j))
        a("    .io_snpt_snptEnq(%s_snpt_enq), .io_snpt_snptDeq(%s_snpt_deq)," % (p, p))
        a("    .io_snpt_useSnpt(%s_snpt_use), .io_snpt_snptSelect(%s_snpt_sel)," % (p, p))
        for k in range(4):
            a("    .io_snpt_flushVec_%d(%s_snpt_flush[%d])," % (k, p, k))
        tailparts = []
        for k in range(DIFF_N):
            tailparts.append(".io_diffRatBase_%d(%s_%s_diff[%d])" % (k, p, side, k))
        for k in range(DBG_N):
            tailparts.append(".io_debug_rdata_%d(%s_%s_dbg[%d])" % (k, p, side, k))
        if HAS_V0:
            tailparts.append(".io_debug_v0(%s_%s_dv0)" % (p, side))
        for idx, tp in enumerate(tailparts):
            a("    %s%s" % (tp, "" if idx == len(tailparts) - 1 else ","))
        a("  );")
    a("")
    if AW:
        a("  // golden 的 t1_raddr 是 %d 个独立 reg，打包成数组才好循环比" % NR)
        a("  logic [%d:0] %s_g_raddr [%d];" % (AW - 1, p, NR))
        for r in range(NR):
            a("  assign %s_g_raddr[%d] = %s_g_u.t1_raddr_%d;" % (p, r, p, r))
        a("")
    # ---------------- 激励 ----------------
    a("  int %s_phase, %s_phaseCnt;" % (p, p))
    a("  int %s_cov_redir, %s_cov_use, %s_cov_hold, %s_cov_coll, %s_cov_byp;" % (p, p, p, p, p))
    a("  int %s_cov_sel [4];" % p)
    a("  always @(negedge clk) begin")
    a("    automatic int lo;")
    a("    if (rst) begin")
    a("      %s_redirect = 1'b0; %s_snpt_enq = 1'b0; %s_snpt_deq = 1'b0;" % (p, p, p))
    a("      %s_snpt_use = 1'b0; %s_snpt_sel = 2'h0; %s_snpt_flush = 4'h0;" % (p, p, p))
    a("      for (int r = 0; r < %d; r++) begin" % NR)
    a("        %s_rd_hold[r] = 1'b0;" % p)
    if AW:
        a("        %s_rd_addr[r] = '0;" % p)
    a("      end")
    a("      for (int j = 0; j < %d; j++) begin" % NW)
    a("        %s_sw_wen[j] = 1'b0; %s_sw_data[j] = '0;" % (p, p))
    a("        %s_aw_wen[j] = 1'b0; %s_aw_data[j] = '0;" % (p, p))
    if AW:
        a("        %s_sw_addr[j] = '0; %s_aw_addr[j] = '0;" % (p, p))
    a("      end")
    a("      %s_phase <= 0; %s_phaseCnt <= 0;" % (p, p))
    a("    end else begin")
    a("      %s_phaseCnt <= %s_phaseCnt + 1;" % (p, p))
    a("      if (%s_phaseCnt >= 97) begin %s_phaseCnt <= 0; %s_phase <= (%s_phase + 1) %% 3; end"
      % (p, p, p, p))
    a("      // 相位 0/1：把地址挤进一个很窄的窗口（lo..lo+3），制造同址撞车与旁路命中；")
    a("      // 相位 2：全域随机。窗口起点每拍重掷，保证扫遍整张表。")
    a("      lo = (%s_phase == 2) ? 0 : $urandom_range(0, %d);" % (p, max(N - 4, 0)))
    a("      // 暖机窗口：纯入队，把 4 个快照槽写成两侧相同的确定值（见文件头说明）。")
    a("      if (warmup) begin")
    a("        %s_redirect = 1'b0;   %s_snpt_enq = 1'b1;  %s_snpt_deq = 1'b0;" % (p, p, p))
    a("        %s_snpt_use = 1'b0;   %s_snpt_sel = 2'h0;  %s_snpt_flush = 4'h0;" % (p, p, p))
    a("      end else begin")
    a("        %s_redirect = ($urandom_range(0, 99) < 4);" % p)
    a("        %s_snpt_enq = ($urandom_range(0, 99) < 12);" % p)
    a("        %s_snpt_deq = ($urandom_range(0, 99) < 10);" % p)
    a("        %s_snpt_use = ($urandom_range(0, 99) < 25);" % p)
    a("        %s_snpt_sel = 2'($urandom_range(0, 3));" % p)
    a("        %s_snpt_flush = 4'($urandom_range(0, 15));" % p)
    a("      end")
    a("      for (int r = 0; r < %d; r++) begin" % NR)
    a("        %s_rd_hold[r] = ($urandom_range(0, 99) < 30);" % p)
    if AW:
        a("        %s_rd_addr[r] = %d'((%s_phase == 2) ? $urandom_range(0, %d)"
          % (p, AW, p, (1 << AW) - 1))
        a("                                          : (lo + $urandom_range(0, 3)));")
    a("      end")
    a("      for (int j = 0; j < %d; j++) begin" % NW)
    a("        %s_sw_wen[j]  = ($urandom_range(0, 99) < 45);" % p)
    a("        %s_sw_data[j] = 8'($urandom_range(0, 255));" % p)
    a("        %s_aw_wen[j]  = ($urandom_range(0, 99) < 40);" % p)
    a("        %s_aw_data[j] = 8'($urandom_range(0, 15));   // 小值域，让 need_free 的"
      % p)
    a("                                                      // \"arch 表里一格都没有\" 两种结果都出现")
    if AW:
        a("        %s_sw_addr[j] = %d'((%s_phase == 2) ? $urandom_range(0, %d)"
          % (p, AW, p, (1 << AW) - 1))
        a("                                          : (lo + $urandom_range(0, 3)));")
        a("        %s_aw_addr[j] = %d'((%s_phase == 2) ? $urandom_range(0, %d)"
          % (p, AW, p, (1 << AW) - 1))
        a("                                          : (lo + $urandom_range(0, 3)));")
    a("      end")
    a("    end")
    a("  end")
    a("")
    # ---------------- 覆盖 ----------------
    a("  always @(posedge clk) if (!rst) begin")
    a("    automatic int nh, nc, nb;")
    a("    if (%s_redirect) %s_cov_redir++;" % (p, p))
    a("    if (%s_snpt_use) %s_cov_sel[%s_snpt_sel]++;" % (p, p, p))
    a("    nh = 0; for (int r = 0; r < %d; r++) if (%s_rd_hold[r]) nh++;" % (NR, p))
    a("    if (nh > 0) %s_cov_hold++;" % p)
    if AW:
        a("    nc = 0;")
        a("    for (int j = 1; j < %d; j++)" % NW)
        a("      for (int k = 0; k < j; k++)")
        a("        if (%s_sw_wen[j] && %s_sw_wen[k] && %s_sw_addr[j] == %s_sw_addr[k]) nc++;"
          % (p, p, p, p))
        a("    if (nc > 0) %s_cov_coll++;" % p)
        a("    nb = 0;")
        a("    for (int r = 0; r < %d; r++)" % NR)
        a("      for (int j = 0; j < %d; j++)" % NW)
        a("        if (%s_sw_wen[j] && %s_sw_addr[j] == %s_rd_addr[r]) nb++;" % (p, p, p))
        a("    if (nb > 0) %s_cov_byp++;" % p)
    else:
        a("    nc = 0; nb = 0;")
        a("    for (int j = 0; j < %d; j++) if (%s_sw_wen[j]) begin nc++; nb++; end" % (NW, p))
        a("    if (nc > 1) %s_cov_coll++;" % p)
        a("    if (nb > 0) %s_cov_byp++;" % p)
    a("  end")
    a("")
    # ---------------- 比对 ----------------
    a("  always @(negedge clk) if (!rst) begin")
    a("    #4; checks++;")
    a("    for (int r = 0; r < %d; r++)" % NR)
    a("      `CHK($sformatf(\"%s.readData[%%0d]\", r), %s_g_rdata[r], %s_i_rdata[r])"
      % (name, p, p))
    a("    for (int j = 0; j < %d; j++)" % NW)
    a("      `CHK($sformatf(\"%s.old_pdest[%%0d]\", j), %s_g_oldp[j], %s_i_oldp[j])"
      % (name, p, p))
    if HNF:
        a("    for (int j = 0; j < %d; j++)" % NW)
        a("      `CHK($sformatf(\"%s.need_free[%%0d]\", j), %s_g_nfree[j], %s_i_nfree[j])"
          % (name, p, p))
    a("    for (int k = 0; k < %d; k++)" % DIFF_N)
    a("      `CHK($sformatf(\"%s.diffRatBase[%%0d]\", k), %s_g_diff[k], %s_i_diff[k])"
      % (name, p, p))
    if DBG_N:
        a("    for (int k = 0; k < %d; k++)" % DBG_N)
        a("      `CHK($sformatf(\"%s.debug_rdata[%%0d]\", k), %s_g_dbg[k], %s_i_dbg[k])"
          % (name, p, p))
    if HAS_V0:
        a("    `CHK(\"%s.debug_v0\", %s_g_dv0, %s_i_dv0)" % (name, p, p))
    a("    // 内部状态也逐格比：输出被旁路/选择遮蔽时，表先错一步")
    for i in range(N):
        a("    `CHK(\"%s.spec_table[%d]\", %s_g_u.spec_table_%d, %s_i_u.u_core.spec_table[%d])"
          % (name, i, p, i, p, i))
        a("    `CHK(\"%s.arch_table[%d]\", %s_g_u.arch_table_%d, %s_i_u.u_core.arch_table[%d])"
          % (name, i, p, i, p, i))
    a("    `CHK(\"%s.t1_redirect\", %s_g_u.t1_redirect_last_REG, %s_i_u.u_core.t1_redirect)"
      % (name, p, p))
    a("    `CHK(\"%s.spec_redirect_q[0]\", %s_g_u.spec_table_next_0_REG,"
      % (name, p))
    a("          %s_i_u.u_core.spec_redirect_q[0])" % p)
    if N > 1:
        a("    `CHK(\"%s.spec_redirect_q[%d]\", %s_g_u.spec_table_next_%d_REG,"
          % (name, N - 1, p, N - 1))
        a("          %s_i_u.u_core.spec_redirect_q[%d])" % (p, N - 1))
    if AW:
        a("    for (int r = 0; r < %d; r++)" % NR)
        a("      `CHK($sformatf(\"%s.t1_raddr[%%0d]\", r), %s_g_raddr[r], %s_i_u.u_core.t1_raddr[r])"
          % (name, p, p))
    a("  end")
    a("")
    return "\n".join(L)


def cov(v):
    name, N, AW, NR, HNF, DIFF_N, DIFF_OFF, DBG_N, HAS_V0 = v
    p = name.lower()
    return ('    $display("COV %s: redirect=%%0d hold=%%0d addr_collision=%%0d bypass_hit=%%0d '
            'useSnpt_sel=[%%0d %%0d %%0d %%0d]",\n'
            '             %s_cov_redir, %s_cov_hold, %s_cov_coll, %s_cov_byp,\n'
            '             %s_cov_sel[0], %s_cov_sel[1], %s_cov_sel[2], %s_cov_sel[3]);'
            % (name, p, p, p, p, p, p, p, p))


def build():
    head = '''// RenameTable UT —— 家族四个变体 golden/重写件双例化逐拍比对
//
// 四个变体（int / fp / vec / v0vl）共用 rtl/backend/RenameTable.sv 里的同一个
// 参数化核 xs_RenameTable_core，差异维度见该文件头的家族对照表。
// 每个变体的 wrapper 里还例化一个 SnapshotGenerator_<N>（实例名与 golden 一致），
// 那四个快照件本身有自己的 UT/FM 目录（verif/ut/SnapshotGenerator），
// 这里两侧都完整 elaborate，**零黑盒**。
//
// ★本文件由 gen_tb.py 生成，勿手改★
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  // ==========================================================================
  // 复位后的"暖机窗口"—— 为什么必须有
  // ==========================================================================
  // 4 个快照槽是**无复位存储器**：golden SnapshotGenerator_6.sv 里写它们的那个
  // always @(posedge clock) 块没有 reset 臂（rtl/backend/SnapshotGenerator.sv §6
  // 照抄了这一点，这是对的）。于是：
  //   · golden 与重写件是**两个独立例化**（RenameTable_2 / RenameTable_2_xs），
  //     +vcs+initreg+random 给它们各自抽一份**互不相同**的上电值；
  //   · 一个"还没被写过"的槽，两侧的内容天然不等 —— 这不是 RTL 差异，
  //     是 tb 在比一个还没有定义的东西。
  // 设计契约本来就是"只读有效槽"（snptValids 保证），而本 tb 的 snptSelect 是
  // 全随机的，不看有效位。实测（seed=42 +vcs+initreg+random）：第 26 拍就有一次
  // useSnpt 恢复选中了**从未被写过的**槽 3，整张 spec_table 当场分叉。
  //
  // 修法：复位一撤，先做 WARMUP 拍**纯入队**——redirect/useSnpt/deq/flushVec 全压 0、
  // snptEnq 恒 1。enq_fire = ~redirect & ~full & enq，队列复位后是空的，
  // 所以前 4 拍依次写满槽 0/1/2/3（第 5 拍起队满、静默丢弃）。槽只会被覆盖、
  // 不会被"擦回未写"，因此窗口之后整段仿真里任何槽的内容都是**输入的函数**。
  // 窗口内 redirect 恒 0 ⇒ spec_redirect_q 恒 0 ⇒ 恢复路径根本不会启动，
  // 不存在"窗口内读到脏槽"的残留。读写口照常随机，暖机不降低激励强度。
  int unsigned WARMUP = 8;
  int cyc = 0;
  always @(posedge clk) if (!rst) cyc <= cyc + 1;
  // 在 posedge 更新、在 negedge 使用，差半拍，没有竞争。
  wire warmup = (cyc < WARMUP);

  `define CHK(nm, g, i) \\
    if (!$isunknown(g) && (g) !== (i)) begin errors++; \\
      if (errors <= 80) $display("[%0t] %s g=%h i=%h", $time, nm, g, i); end

'''
    body = "\n".join(emit(v) for v in VARIANTS)
    tail = '''  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
''' + "\n".join(cov(v) for v in VARIANTS) + '''
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
'''
    return head + body + tail


if __name__ == "__main__":
    here = os.path.dirname(os.path.abspath(__file__))
    out = os.path.join(here, "tb.sv")
    txt = build()
    if "--check" in sys.argv:
        cur = open(out, encoding="utf-8").read() if os.path.exists(out) else ""
        if cur != txt:
            print("ERROR: tb.sv 与 gen_tb.py 的生成结果不一致")
            sys.exit(1)
        print("OK")
    else:
        open(out, "w", encoding="utf-8").write(txt)
        print("wrote", out)
