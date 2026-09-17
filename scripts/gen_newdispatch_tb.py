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

用法: gen_newdispatch_tb.py            # 写 verif/ut/NewDispatch/tb.sv
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
# 第一版我按「数据锥」算，错了：payload 的**选择**也还没通。
# uopSelIQ 的两个写源 toRenameAllFire / firedVec 都要 io_fromRename_*_ready，
# 而 ready 要 LsqEnqCtrl 的 canAccept —— 现在被钉成 0，于是重写侧 uopSelIQ 永远
# 停在上电值、oh 恒定、payload mux 永远选同一条 lane；golden 那边子模块是真的，
# 选择在动。所以**凡是经过这个 mux 的位都必然失配**，不管它的数据接没接。
#
# 真正"两侧都与选择无关"的只有一类：golden 六条 lane 的数据全是同一个常量，
# 于是 mux 输出恒为该常量，重写侧也恒为该常量 —— 这类位才该是 clean。
#   * pack_spec 里六条 lane 全判 CONST 的 leaf（debugInfo×9 / ssid / storeSetHit /
#     waitForRobIdx / loadWait* / replayInst / srcLoadDependency_2,3,4_*）
#   * srcState 中被逐 IQ 掩码折成 0 的那 72 个位
# 其余 6699-N 个输出**全部**应当红。
UNCONNECTED_GROUPS = ('io_fromRename_', 'io_toRenameAllFire', 'io_enqRob_',
                      'io_toMem_', 'io_perf_', 'io_stallReason_')


def const_both_sides_leaves():
    """六条 lane 的数据全是同一个常量的 leaf —— 这类位与选择无关，两侧恒等。"""
    ports = G.golden_ports()
    spec = G.pack_spec(ports)
    out = set()
    for leaf, _ in G.dyninst_leaves(ports):
        if re.match(r'^srcState_\d$', leaf):
            continue   # srcState 走 allSrcState 覆写路径，由掩码单独判
        kinds = {spec[(l, leaf)][0] for l in range(6)}
        vals = {spec[(l, leaf)][1] for l in range(6)}
        if kinds == {'CONST'} and len(vals) == 1:
            out.add(leaf)
    return out


CONST_BOTH = None


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
    """两侧都与"选择"无关、恒等于同一个常量的位。只有这一类现在可以断言一致。"""
    m = re.match(r'^io_toIssueQueues_(\d+)_bits_(.+)$', name)
    if not m:
        return False
    q, leaf = int(m.group(1)), m.group(2)
    ms = re.match(r'^srcState_(\d)$', leaf)
    if ms:
        return not SRCSTATE_LIVE[q // 2][int(ms.group(1))]
    if leaf == 'snapshot' and q % 2 == 1:
        return True
    return leaf in CONST_BOTH


def is_dangling(name):
    """impl 侧驱动是 unresolved_*（无驱动 -> Z）的位。

    ★为什么只有这一类配当判据 B 的对象★：Z !== 任何值，所以这类位**与种子、
    与选择通路通不通都无关地必然失配**。第二版我把"所有 blocked"都要求必红，
    结果 6 个全长配置里 5 个报 B 失败（7/14/139/161/279 位不等）—— 那些位是
    透传位：impl 的选择被冻住、golden 在动，两边**有可能恰好一直相等**，
    不红既不是 tb 漏检也不是我接错，只是没被区分开。把它们塞进判据 B 是我
    把判据定过头了，不是 tb 的毛病，所以修判据、不修数据。
    """
    if name == 'io_toRenameAllFire':
        return True
    for g in ('io_fromRename_', 'io_enqRob_', 'io_toMem_', 'io_perf_',
              'io_stallReason_'):
        if name.startswith(g):
            return True
    m = re.match(r'^io_toIssueQueues_(\d+)_(valid|bits_(.+))$', name)
    if not m:
        return False
    q = int(m.group(1))
    if m.group(2) == 'valid':
        # ★不是无条件悬空★：iq_valid[q] 的尾项是 oh[q][5] & rename_valid[5]，
        # rename_valid 虽然是 Z，但 SV 四值里 0 & Z = 0 —— 当该 enq 口一次都没被
        # 选中（oh 全零，initreg=0 时必然如此）时 valid 恒为 0，而不是 Z，
        # golden 那边同样没人进这个槽也是 0，于是两边恒等、永远不失配。
        # 实测：seed=7 initreg=0 下正是这 17 个 valid 触发了判据 B。
        # 所以 valid 只能算"未判定"，不能当判据 B 的对象。bits 则不同：
        # 六条 lane 的该 leaf 全是 unresolved_*(Z)，选哪条都是 Z，无条件失配。
        return False
    leaf = m.group(3)
    ms = re.match(r'^srcState_(\d)$', leaf)
    if ms:                   # 掩码折 0 的那些由核直接钉 1'b0，不是悬空
        return bool(SRCSTATE_LIVE[q // 2][int(ms.group(1))])
    return leaf in set(G.BLOCKED_LEAVES)


def is_blocked(name):
    if name.endswith('_ready') and name.startswith('io_fromRename_'):
        return True
    for g in UNCONNECTED_GROUPS:
        if name.startswith(g):
            return True
    m = re.match(r'^io_toIssueQueues_(\d+)_(valid|bits_(.+))$', name)
    if m:
        q = int(m.group(1))
        if m.group(2) == 'valid':
            return True
        leaf = m.group(3)
        ms = re.match(r'^srcState_(\d)$', leaf)
        if ms:
            return bool(SRCSTATE_LIVE[q // 2][int(ms.group(1))])
        # snapshot 的二阶常量性（判据 B 替我抓出来的，不是我事先想到的）：
        # snapshot 只有 lane0 非常量（lane1~5 被 golden 钉成 1'h0，PriorityMux 尾项
        # 也是 lane5 的 0）。而 golden 自己写着
        #     uopSelIQMatrix_0_<iq> = {2'h0, uopSelIQ_0_<iq>}      -> 取值只能是 0/1
        #     oh_IQSelUop_<奇数口>_0 = (uopSelIQMatrix_0_<iq> == 3'h2)
        # 后者**恒为假** —— lane0 的前缀计数最多是 1，永远占不到第二个 enq 口。
        # 所以奇数口的 snapshot 在两侧都恒等于 0，属于 clean，不该进 blocked。
        if leaf == 'snapshot' and q % 2 == 1:
            return False
        return leaf not in CONST_BOTH
    return False


def main():
    global CONST_BOTH
    CONST_BOTH = const_both_sides_leaves()
    ports = G.golden_ports()
    ins = [(d, w, n) for d, w, n in ports if d == 'input' and n not in ('clock', 'reset')]
    outs = [(d, w, n) for d, w, n in ports if d == 'output']
    L = []
    a = L.append
    a('// NewDispatch UT —— golden NewDispatch 与重写 NewDispatch_xs 双例化逐拍比对。')
    a('//')
    a('// ★判据不是 errors==0★（见 scripts/gen_newdispatch_tb.py 头注释）：')
    a('//   A 失配位 ⊆ blocked 清单   B blocked 每一位都真红了   C 比较真的发生过')
    a('// 现在有一批位故意悬空（Lane H/I 的 9 个子模块未实现），仿真里是 Z，必然红；')
    a('// 它们**必须**红——不红说明 tb 漏检。')
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
    a('  // 现在选择通路没通（uopSelIQ 冻在上电值），D 必然不满足 —— 所以 Makefile 暂时')
    a('  // 传 +known_hole_frozen_select 把它降成响亮的 WARNING。★Lane I(LsqEnqCtrl) 落地后')
    a('  // 必须把那个 plusarg 从 Makefile 删掉★，D 才会重新变成硬闸；洞没补上就会红。')
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
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    open(OUT, 'w').write('\n'.join(L) + '\n')
    nb = sum(1 for _, _, n in outs if is_blocked(n))
    print('已生成 %s' % OUT)
    print('  输出端口 %d，其中声明为 blocked %d，预期应 clean %d'
          % (len(outs), nb, len(outs) - nb))
    return 0


if __name__ == '__main__':
    sys.exit(main())
