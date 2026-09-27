#!/usr/bin/env python3
"""gen_newdispatch_tb.py —— 生成 NewDispatch 的差分 UT testbench（本 lane 自建）。

NewDispatch 有 7725 个端口（1026 in / 6699 out），tb 手写必错，故机械生成。

★本 tb 的判据不是"errors==0"★。NewDispatch 现在有一批位**故意悬空**（依赖
Lane H/I 的 9 个子模块还没实现），所以"全绿"在当前状态下反而说明 tb 什么都没比。
判据改成三条，任何一条不满足都是 FAIL：

  A  失配位 ⊆ 声明的 blocked 清单        —— 红在清单外 = 我把真值位接错了
  B  blocked 清单里每一位都真的红了      —— 悬空位没红 = tb 漏检，比失配更严重
  C  比较真的发生过（checks > 0 且激励真的动过）

判据 B 是"占位不能悄悄变绿"：哪天 Lane H/I 落地、某位接上了真值，它会从 B 掉出来
而不是悄悄混在绿里——那时**必须**同步把它从 blocked 清单里删掉，判据才会再次成立。

比较用 `!==`（case 不等），所以 X/Z 一定算失配；悬空位在仿真里是 Z，必然触发 B。

用法:
    gen_newdispatch_tb.py            # 写 verif/ut/NewDispatch/tb.sv
    gen_newdispatch_tb.py --check    # 只比对不写（幂等闸用；有差异则非零退出）
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_newdispatch as G  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(REPO, 'verif', 'ut', 'NewDispatch', 'tb.sv')
MAXW = 128  # vpu_vmask 是最宽的 leaf

# ★静态推断的 blocked 集合，不是跑完回填的★
#
# 步骤 1 之前这里写的是「凡是经过 payload mux 的位都必然失配」——理由是重写侧的
# 选择通路冻住（uopSelIQ 的两个写源都钉在常量 0），mux 永远选同一条 lane。
# ★步骤 2 之后这条理由整个失效了★：ready/firedVec/toRenameAllFire 已是真值，
# 选择通路与 golden 同步在动。于是 blocked 集合收缩成**只剩真正悬空的那批位**：
# io_toIssueQueues 里 leaf ∈ gen_newdispatch.BLOCKED_LEAVES 的（srcState 再按
# 逐 IQ 掩码扣掉折成常量 0 的 72 位）。其余每一位都改判"必须始终一致"。
# ★2026-09-21（步骤 2）：本常量已清空，原值与失效理由留在这里★
#   原值 = ('io_fromRename_', 'io_toRenameAllFire', 'io_enqRob_',
#           'io_toMem_', 'io_perf_', 'io_stallReason_')
# 那时这 725 个 output 在重写侧一个驱动源都没有，所以整组进 blocked。
# 步骤 2 之后它们全部有真驱动（io_toMem 直接来自 lsqEnqCtrl、io_enqRob 基本是
# io_fromRename 直通、握手/perf/stallReason 由节 2.8~2.12 的派遣流控算出），
# ★于是它们从"必然红"变成"必须绿"★ —— 判据 B 的原话就是这个意思：
# 「哪天某位接上了真值，它会从 B 掉出来而不是悄悄混在绿里，那时**必须**同步
#  把它从 blocked 清单里删掉，判据才会再次成立」。这里就是在做那件事。
UNCONNECTED_GROUPS = ()




# srcState 逐 IQ 掩码（与 rtl/backend/NewDispatch.sv 节 1.4 的 SRCSTATE_LIVE 同一张表，
# 都实测自 golden 的 IQSelUop_<q>_bits_srcState_<j> 是否被折成常量）。
# [IQ][src] = 1 表示这一位真的从 busy table 来（=现在还悬空）。
SRCSTATE_LIVE = [
    [1, 1, 0, 0, 0], [1, 1, 0, 0, 0], [1, 1, 0, 0, 0], [1, 1, 0, 0, 0],   # IQ 0-3
    [1, 1, 1, 0, 0], [1, 1, 1, 0, 0], [1, 1, 1, 0, 0],                    # IQ 4-6
    [1, 1, 1, 1, 1], [1, 1, 1, 1, 1], [1, 1, 1, 1, 1],                    # IQ 7-9
    [1, 1, 0, 0, 0], [1, 1, 0, 0, 0],                                     # IQ 10,11
    [1, 0, 0, 0, 0], [1, 0, 0, 0, 0], [1, 0, 0, 0, 0],                    # IQ 12-14
    [1, 1, 1, 1, 1], [1, 1, 1, 1, 1]]                                     # IQ 15,16


def is_const_both(name):
    """必须**始终一致**的位（判据 A 的对象）。

    ★步骤 2 起判据 A 的范围整个变了★，这是本 tb 最重要的一次收紧：
    在步骤 1 之前，重写侧的**选择通路是冻住的**（uopSelIQ 的两个写源都钉在 0），
    所以哪怕数据位接对了，mux 也永远选同一条 lane，与 golden 必然对不上 ——
    那时只有"六条 lane 数据全是同一个常量"的位才敢断言一致。
    步骤 2 把 ready/firedVec/toRenameAllFire 接成真值之后，选择通路活了，
    于是判断反过来：**除了仍然悬空的那批位，其余每一位都必须始终一致**。

    判据 A 的覆盖面因此从几百位涨到五万位量级；这也意味着流控但凡写错一位，
    这条闸就会红 —— 这正是它该有的样子。
    """
    return not is_dangling(name)


def is_dangling(name):
    """impl 侧驱动是 unresolved_*（无驱动 -> Z）的位。

    ★为什么只有这一类配当判据 B 的对象★：Z !== 任何值，所以这类位**与种子、
    与选择通路通不通都无关地必然失配**。第二版我把"所有 blocked"都要求必红，
    结果 6 个全长配置里 5 个报 B 失败（7/14/139/161/279 位不等）—— 那些位是
    透传位：impl 的选择被冻住、golden 在动，两边**有可能恰好一直相等**，
    不红既不是 tb 漏检也不是我接错，只是没被区分开。把它们塞进判据 B 是我
    把判据定过头了，不是 tb 的毛病，所以修判据、不修数据。
    """
    m = re.match(r'^io_toIssueQueues_(\d+)_(valid|bits_(.+))$', name)
    if not m:
        return False
    q = int(m.group(1))
    if m.group(2) == 'valid':
        # 步骤 2 起 iq_valid 的每一项都是真值（renameUpdateValid 由节 2.8 算出），
        # 不再有 Z，所以 valid 归判据 A（必须始终一致），不是悬空位。
        return False
    leaf = m.group(3)
    # 步骤 4（2026-09-24）起 srcState 也有真来源（核的 srcStateAll 逐 IQ 选择），
    # 与其余 leaf 一样归判据 A；BLOCKED_LEAVES 已清空，下面这行恒为 False，留着
    # 是为了"哪天又有 leaf 接不上"时判据 B 自动恢复。
    return leaf in set(G.BLOCKED_LEAVES)


def is_blocked(name):
    """跑前报告用：步骤 2 之后 blocked 与 dangling 是同一个集合。

    步骤 1 之前两者不同：那时"选择通路冻住"让一大批**接对了数据**的位也必然失配，
    它们算 blocked 但不算 dangling。选择通路接通后这个区别消失了。
    """
    return is_dangling(name)


def main():
    ports = G.golden_ports()
    ins = [(d, w, n) for d, w, n in ports if d == 'input' and n not in ('clock', 'reset')]
    outs = [(d, w, n) for d, w, n in ports if d == 'output']
    L = []
    a = L.append
    a('// NewDispatch UT —— golden NewDispatch 与重写 NewDispatch_xs 双例化逐拍比对。')
    a('//')
    a('// ★判据不是 errors==0★（见 scripts/gen_newdispatch_tb.py 头注释）：')
    a('//   A 失配位 ⊆ blocked 清单   B blocked 每一位都真红了   C 比较真的发生过')
    a('// 步骤 2 之后只剩 io_toIssueQueues 的 536 个端口故意悬空（srcState/srcType_2/')
    a('// lqIdx/sqIdx/useRegCache/regCacheIdx/srcLoadDependency 还没接），仿真里是 Z，')
    a('// 它们**必须**红——不红说明 tb 漏检；其余每一位都**必须**始终一致。')
    a('//')
    a('// 本文件由 scripts/gen_newdispatch_tb.py 生成，不要手改。')
    a('`timescale 1ns/1ps')
    a('module tb;')
    a('  localparam int NOUT = %d;' % len(outs))
    a('  int unsigned NCYCLES = 200000;')
    a('  int unsigned WARMUP  = 64;   // 跳过复位与不复位寄存器的上电瞬态')
    a('  bit clk = 0, rst = 1;')
    a('  int unsigned cyc = 0, checks = 0, stim_moves = 0;')
    a('  bit ever_mm  [NOUT];   // 这一位是否曾经失配')
    a('  bit must_red [NOUT];   // impl 侧悬空(Z) -> 与种子无关地必然失配')
    a('  bit must_eq  [NOUT];   // 两侧都与"选择"无关的常量 -> 必须始终一致')
    a('  string pname [NOUT];')
    a('  always #5 clk = ~clk;')
    a('')
    a('  // ---- 输入 ----')
    for d, w, n in ins:
        a('  logic %-9s %s;' % (w or '', n))
    a('')
    a('  // ---- 输出：g_=golden, i_=重写 ----')
    for d, w, n in outs:
        a('  wire %-9s g_%s, i_%s;' % (w or '', n, n))
    a('')
    conn_in = ', '.join('.%s(%s)' % (n, n) for _, _, n in ins)
    a('  NewDispatch u_g (.clock(clk), .reset(rst), %s,' % conn_in)
    a('    %s);' % ', '.join('.%s(g_%s)' % (n, n) for _, _, n in outs))
    a('  NewDispatch_xs u_i (.clock(clk), .reset(rst), %s,' % conn_in)
    a('    %s);' % ', '.join('.%s(i_%s)' % (n, n) for _, _, n in outs))
    a('')
    a('  // ---- 输出打平成定宽数组，判据逻辑就能只写一遍 ----')
    a('  logic [%d:0] gv [NOUT];' % (MAXW - 1))
    a('  logic [%d:0] iv [NOUT];' % (MAXW - 1))
    for k, (d, w, n) in enumerate(outs):
        a('  assign gv[%d] = %d\'(g_%s);  assign iv[%d] = %d\'(i_%s);'
          % (k, MAXW, n, k, MAXW, n))
    a('')
    a('  int pport [NOUT];   // 该输出属于哪个 enq 口；不属于任何口记 -1')
    a('  initial begin')
    for k, (d, w, n) in enumerate(outs):
        mq = re.match(r'^io_toIssueQueues_(\d+)_', n)
        a('    pname[%d] = "%s"; must_red[%d] = 1\'b%d; must_eq[%d] = 1\'b%d; pport[%d] = %s;'
          % (k, n, k, 1 if is_dangling(n) else 0,
             k, 1 if is_const_both(n) else 0, k, mq.group(1) if mq else '-1'))
    a('  end')
    a('')
    a('  // ---- 激励 ----')
    a('  // fuType 必须是"多数时候单热"：直接 35 位全随机会让 fuTypeOH 常年多热，')
    a('  // Mux1H 退化、minIQSel/popFuTypeOH 全程被同一条路径盖住，等于没在验选队列网络。')
    a('  function automatic logic [34:0] rand_futype();')
    a('    int unsigned r = $urandom_range(0, 99);')
    a('    if (r < 80) return 35\'(1) << $urandom_range(0, 34);   // 单热')
    a('    else if (r < 95) return 35\'(0);                        // 空')
    a('    else return {$urandom(), $urandom()} & 35\'h7FFFFFFFF;  // 多热（角落）')
    a('  endfunction')
    a('')
    a('  always @(negedge clk) begin')
    a('    if (!rst) stim_moves++;')
    for d, w, n in ins:
        if re.match(r'^io_(renameIn|fromRename)_\d+_bits_fuType$', n):
            a('    %s <= rand_futype();' % n)
        elif re.match(r'^io_IQValidNumVec_\d+$', n):
            a('    %s <= 5\'($urandom_range(0, 16));' % n)
        elif n == 'io_enqRob_canAccept':
            a('    %s <= ($urandom_range(0, 99) < 85);' % n)
        else:
            bits = G.leaf_width(w)
            if bits == 1:
                a('    %s <= 1\'($urandom);' % n)
            elif bits <= 32:
                a('    %s <= %d\'($urandom);' % (n, bits))
            else:
                words = (bits + 31) // 32
                a('    %s <= %d\'({%s});' % (n, bits, ', '.join(['$urandom()'] * words)))
    a('  end')
    a('')
    a('  // ---- 诊断：每条 lane 是否真的被某个 enq 口选中过 ----')
    a('  // MA-3（改 lane3 的常量位）没被抓到，就是靠这组计数查清原因的：')
    a('  // 重写侧 uopSelIQ 现在被冻在上电值（toRenameAllFire/firedVec 还没来源），')
    a('  // oh 恒定，于是只有个别 lane 会被选中，别的 lane 的 payload 根本到不了输出。')
    a('  // 这不是 tb 写错，是"选择通路没通"必然带来的覆盖洞——但必须量出来，不能当没有。')
    a('  int g_lane_sel [6];')
    a('  int i_lane_sel [6];')
    a('  // 每个 enq 口是否被"用过"= 该口的 oh 曾经非全零。两侧都没用过的口，')
    a('  // 两边都会走 PriorityMux 的无默认尾项（取 lane5），于是恒等 —— 那不是 tb')
    a('  // 漏检，是这个 enq 口根本没被激励碰过。两种成因必须分开报，否则要么')
    a('  // 冤枉 tb，要么把真的漏检混进"已知洞"里放过去。')
    a('  bit g_port_used [34];')
    a('  bit i_port_used [34];')
    a('  always @(posedge clk) if (!rst && cyc > WARMUP) begin')
    for l in range(6):
        gterms = ' | '.join('u_g.oh_IQSelUop_%d_%d' % (q, l) for q in range(34))
        a('    if (%s) g_lane_sel[%d]++;' % (gterms, l))
    for l in range(6):
        a('    if (|{%s}) i_lane_sel[%d]++;'
          % (', '.join('u_i.u_core.oh[%d][%d]' % (q, l) for q in range(34)), l))
    for q in range(34):
        a('    if (%s) g_port_used[%d] = 1\'b1;'
          % (' | '.join('u_g.oh_IQSelUop_%d_%d' % (q, l) for l in range(6)), q))
        a('    if (|u_i.u_core.oh[%d]) i_port_used[%d] = 1\'b1;' % (q, q))
    a('  end')
    a('')
    a('  // ---- 逐拍比对 ----')
    a('  always @(posedge clk) begin')
    a('    cyc++;')
    a('    if (!rst && cyc > WARMUP) begin')
    a('      checks++;')
    a('      for (int k = 0; k < NOUT; k++)')
    a('        if (gv[k] !== iv[k]) ever_mm[k] = 1\'b1;')
    a('    end')
    a('  end')
    a('')
    a('  // 判据 D：重写侧每条 lane 的 payload 都必须真的被某个 enq 口选中过，')
    a('  // 否则"A 清单外失配=0"里有一大半位置根本没被激励碰到过（MA-3 就是这么漏的）。')
    a('  // ★步骤 2 起 D 重新是硬闸★：选择通路已接通，Makefile 里那行')
    a('  // +known_hole_frozen_select 已经删掉（放行开关的那句"落地后必须删掉"兑现了）。')
    a('  // known_hole 这条路径留着只为让老命令行不报错，正常跑法下它恒为 0。')
    a('  int unexpected_red = 0, silent_blocked = 0, blocked_red = 0, clean = 0, unsel_lanes = 0, undetermined = 0;')
    a('  bit known_hole = 0;')
    a('  initial begin')
    a('    if ($value$plusargs("ncycles=%d", NCYCLES));')
    a('    known_hole = $test$plusargs("known_hole_frozen_select");')
    a('    repeat (8) @(posedge clk);')
    a('    rst = 0;')
    a('    repeat (NCYCLES) @(posedge clk);')
    a('    for (int k = 0; k < NOUT; k++) begin')
    a('      if (must_eq[k] && ever_mm[k]) begin')
    a('        unexpected_red++;')
    a('        if (unexpected_red <= 25) $display("  [A-FAIL] 应恒等的位却失配: %s", pname[k]);')
    a('      end else if (must_red[k] && !ever_mm[k]) begin')
    a('        silent_blocked++;')
    a('        if (silent_blocked <= 25) $display("  [B-FAIL] 悬空位(Z)竟没失配 = tb 漏检: %s", pname[k]);')
    a('      end else if (must_eq[k]) clean++;')
    a('      else if (must_red[k]) blocked_red++;')
    a('      else undetermined++;')
    a('    end')
    a('    $display("NewDispatch UT: checks=%0d stim_moves=%0d NOUT=%0d", checks, stim_moves, NOUT);')
    a('    $display("  A 组 必须恒等(与选择无关的常量) = %0d 位，全部一致", clean);')
    a('    $display("  B 组 必须失配(impl 悬空=Z)      = %0d 位，全部如期失配", blocked_red);')
    a('    $display("  A 清单外失配               = %0d", unexpected_red);')
    a('    $display("  未判定(选择通路冻住，两侧可能巧合相等) = %0d 位", undetermined);')
    a('    $display("  A 违反 = %0d   B 违反 = %0d", unexpected_red, silent_blocked);')
    a('    for (int l = 0; l < 6; l++) if (i_lane_sel[l] == 0) unsel_lanes++;')
    a('    $display("  lane 被选中的拍数 golden/重写:");')
    a('    for (int l = 0; l < 6; l++)')
    a('      $display("    lane%0d  golden=%0d  重写=%0d%s", l, g_lane_sel[l], i_lane_sel[l],')
    a('               (i_lane_sel[l] == 0) ? "   <- 重写侧从没选中，该 lane 的 payload 未被验证" : "");')
    a('    if (checks == 0 || stim_moves == 0)')
    a('      $display("TEST FAILED: 判据 C —— 根本没比/激励没动");')
    a('    else if (unsel_lanes != 0 && !known_hole)')
    a('      $display("TEST FAILED: 判据 D —— %0d 条 lane 的 payload 从没被选中过(覆盖洞)", unsel_lanes);')
    a('    else if (unexpected_red != 0)')
    a('      $display("TEST FAILED: 判据 A —— %0d 个应恒等的位失配了", unexpected_red);')
    a('    else if (silent_blocked != 0)')
    a('      $display("TEST FAILED: 判据 B —— %0d 个悬空位(Z)竟没失配，tb 漏检", silent_blocked);')
    a('    else if (unsel_lanes != 0)')
    a('      $display("TEST PASSED (但有已知覆盖洞: %0d 条 lane 没被选中，靠 +known_hole_frozen_select 放行)", unsel_lanes);')
    a('    else $display("TEST PASSED");')
    a('    $finish;')
    a('  end')
    a('endmodule')
    body = '\n'.join(L) + '\n'
    if '--check' in sys.argv:
        cur = open(OUT).read() if os.path.exists(OUT) else None
        if cur != body:
            print('FAIL: %s 与生成器不同步，请重跑 gen_newdispatch_tb.py' % OUT)
            return 1
        print('OK: tb.sv 与生成器同步')
        return 0
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    open(OUT, 'w').write(body)
    nb = sum(1 for _, _, n in outs if is_blocked(n))
    print('已生成 %s' % OUT)
    print('  输出端口 %d，其中声明为 blocked %d，预期应 clean %d'
          % (len(outs), nb, len(outs) - nb))
    return 0


if __name__ == '__main__':
    sys.exit(main())
