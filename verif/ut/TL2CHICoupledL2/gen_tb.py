#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_tb.py —— 生成 TL2CHICoupledL2 UT 的 tb.sv：golden TL2CHICoupledL2 vs 重写 TL2CHICoupledL2_xs 同激励逐拍比对。

端口表从 golden 解析。激励分五块：
  * 4 组 TileLink-C（auto_in_i_*）：偏置规则直接复用 verif/ut/Slice/gen_tb.py 的 drive_expr（同一套 A/C/E 偏置），
    只把地址的 bank 位（[7:6]）钉成 i —— 上游 XBar 本来就按 [7:6] 选 bank；
  * MMIO（auto_mmioBridge_mmio_in_*）：同 verif/ut/MMIOBridge 的偏置（Get / PutFull / PutPartial 为主）；
  * 预取：pf_recv / pfCtrl 随机、L2 TLB 响应按"上一拍 golden 发了请求则这拍回"建模（同 verif/ut/Prefetcher）；
    A 通道的 user_vaddr 3/4 时间取与地址相同（vbop 的训练流才有规律）；TopDown 的 robHeadPaddr 取同一地址域；
  * CHI 物理链路：rx_linkactivereq / tx_linkactiveack / syscoack 多数为 1；TX 的 L-Credit 由 tb 发（在途不超过 4）；
    RX 三个通道按 golden 发来的 lcrdv 记信用，有信用才发 flit。RXRSP / RXDAT 的 txnID 只指向"正在等这类响应"的
    MSHR（看 golden 的 4 个 slice 的 MSHR 状态，同 Slice tb 的 pick_target）或 MMIO 槽；RSP 里混入 PCrdGrant
    （pCrdType / srcID 压到小范围，P-Credit 队列与 80 路查询才真的命中）；snoop 地址与 A 通道同一地址域；
  * DFT / MBIST / TopDown：同 Slice tb（低频翻、aux_clk/ckbp 恒 0）。
未复位寄存器 / 存储阵列的初值同步表从三个 child UT 的 tb 机械收割（不重写规则）：
  verif/ut/Slice/tb.sv（4 对 → slices_0..3）、verif/ut/MMIOBridge/tb.sv（→ mmioBridge）、verif/ut/L2Cache/tb.sv（→ mbistPl），
  外加本层几个队列的存储体（两侧都是同一份 golden ram 模型，各一个实例）。
arm（按输出分组，不复位的出口寄存器先被写过一次才比该组）：
  CHI TX 三通道 flit ← LinkMonitor 的 Decoupled2LCredit_* 第一次 flitv；L2 TLB 请求 ← Prefetcher 的 vbop 请求过滤器
  16 项都分配过且发过一次 TLB 请求。其余输出从复位撤销起逐拍比。

用法: python3 gen_tb.py [--check]
"""
import os
import pathlib
import re
import sys
import importlib.util

HERE = pathlib.Path(__file__).resolve().parent
UT = HERE.parent
GOLDEN = pathlib.Path(os.environ.get('G1_GOLDEN', '/home/eda/xs-env/G1-canonical/golden-rtl'))
TOP = 'TL2CHICoupledL2'
NS = 4

_spec = importlib.util.spec_from_file_location('slice_gen_tb', str(UT / 'Slice' / 'gen_tb.py'))
slice_tb = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(slice_tb)


def ports(top):
    src = (GOLDEN / (top + '.sv')).read_text()
    m = re.search(r'^module %s\(\n(.*?)\n\);\n' % top, src, re.S | re.M)
    out = []
    for ln in m.group(1).split('\n'):
        mm = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?\s*$', ln)
        out.append((mm.group(1), int(mm.group(2)) + 1 if mm.group(2) else 1, mm.group(3)))
    return out


# ---------------------------------------------------------------------------
# 初值同步表收割：(golden 路径, 重写路径, force?)，路径相对 tb
# ---------------------------------------------------------------------------
HARVEST = [
    # (child tb, 正则（组：force?, impl 路径, golden 路径）, 本层实例名映射)
    ('Slice', re.compile(r'^\s*(force\s+)?u_i(\d)\.(\S+)\s*=\s*u_g\2\.(\S+?)\s*;\s*$')),
    ('MMIOBridge', re.compile(r'^\s*(force\s+)mb_u_impl\.(\S+)\s*=\s*mb_u_gold\.(\S+?)\s*;\s*$')),
    ('L2Cache', re.compile(r'^\s*(force\s+)u_i_L2Cache\.(\S+)\s*=\s*u_g_L2Cache\.(\S+?)\s*;\s*$')),
]
# 本层的队列存储体（两侧都是同一份 golden ram 模型）
MEM_SYNC = [
    ('pCrdQueue_s2.ram_ext.Memory', 'pCrdQueue_s2.ram_ext.Memory'),
    ('pCrdQueue_s3.ram_ext.Memory', 'pCrdQueue_s3.ram_ext.Memory'),
    ('linkMonitor.LCredit2Decoupled_rxsnp.queue.ram_ext.Memory',
     'linkMonitor.LCredit2Decoupled_rxsnp.u_core.queue.ram_ext.Memory'),
]


def harvest(pfx=''):
    """pfx：TL2CHICoupledL2 在 tb 顶层下的实例路径前缀（本 UT 为空；L2Top 的 UT 传 'inner_l2cache.'）"""
    out = []
    for ut, rx in HARVEST:
        n = 0
        for ln in (UT / ut / 'tb.sv').read_text().split('\n'):
            m = rx.match(ln)
            if not m:
                continue
            if ut == 'Slice':
                frc, k, ip, gp = bool(m.group(1)), int(m.group(2)), m.group(3), m.group(4)
                out.append((pfx + 'slices_%d.%s' % (k, gp), pfx + 'slices_%d.%s' % (k, ip), frc))
            elif ut == 'MMIOBridge':
                out.append((pfx + 'mmioBridge.' + m.group(3), pfx + 'mmioBridge.' + m.group(2), True))
            else:
                out.append((pfx + 'mbistPl.' + m.group(3), pfx + 'mbistPl.' + m.group(2), True))
            n += 1
        if n == 0:
            raise SystemExit('从 %s/tb.sv 没收割到任何同步行' % ut)
    out += [(pfx + g, pfx + i, False) for g, i in MEM_SYNC]
    if len({i for _, i, _ in out}) != len(out):
        raise SystemExit('同步表重写侧有重复')
    return out


# ---------------------------------------------------------------------------
# 激励
# ---------------------------------------------------------------------------
MMIO_A_OPCODE = "pick_mmio_opcode()"


def drive_expr(name, w):
    m = re.match(r'auto_in_(\d)_(\w+)$', name)
    if m:
        k, f = int(m.group(1)), m.group(2)
        e = slice_tb.drive_expr('io_in_' + f, w)
        return e.replace('pick_addr()', 'pick_addr(%d)' % k)
    if name == 'auto_mmioBridge_mmio_in_a_valid':
        return '($urandom_range(0, 3) == 0)'
    if name == 'auto_mmioBridge_mmio_in_a_bits_opcode':
        return MMIO_A_OPCODE
    if name == 'auto_mmioBridge_mmio_in_d_ready':
        return 'slow_phase() ? ($urandom_range(0, 7) == 0) : ($urandom_range(0, 3) != 0)'
    if name == 'auto_pf_recv_in_addr_valid':
        return '($urandom_range(0, 7) == 0)'
    if name == 'auto_pf_recv_in_pf_source':
        return "pick_pf_source()"
    if name == 'io_pfCtrlFromCore_l2_pf_master_en':
        return '($urandom_range(0, 15) != 0)'
    if name.startswith('io_pfCtrlFromCore_l2_') and name.endswith('_en'):
        return '($urandom_range(0, 7) != 0)'
    if name == 'io_pfCtrlFromCore_l2_pf_delay_latency':
        return "10'($urandom_range(0, 15))"
    if name == 'io_l2_tlb_req_resp_valid':
        return 'tlb_q'
    if name == 'io_l2_tlb_req_resp_bits_miss':
        return '($urandom_range(0, 3) == 0)'
    if name.startswith('io_l2_tlb_req_resp_bits_excp_0_'):
        return '($urandom_range(0, 19) == 0)'
    if name.startswith('io_l2_tlb_req_pmp_resp_'):
        return '($urandom_range(0, 9) == 0)'
    if name.startswith('io_dft_') and name.endswith(('_aux_clk', '_aux_ckbp')):
        return "1'b0"   # 同 Slice tb：DFT 备用时钟恒 0（避免 tb 造出零延迟时钟竞争）
    if name.startswith('io_dft_'):
        return '($urandom_range(0, 63) == 0)'
    if name == 'io_chi_syscoack':
        return "($urandom_range(0, 31) == 0) ? 1'($urandom) : g_io_chi_syscoreq"
    if name == 'io_chi_rxsactive':
        return "1'($urandom)"
    if name == 'io_chi_tx_linkactiveack':
        return "($urandom_range(0, 63) == 0) ? 1'($urandom) : g_io_chi_tx_linkactivereq"
    if name == 'io_chi_rx_linkactivereq':
        return "link_down_phase() ? 1'b0 : 1'b1"
    if name.startswith('io_chi_tx_') and name.endswith('_lcrdv'):
        return "1'b0"   # 由 credit_model_drive() 覆写
    if name.startswith('io_chi_rx_') and (name.endswith('_flitv') or name.endswith('_flitpend') or name.endswith('_flit')):
        return "'0"     # 由 rx_flits() 覆写
    if name == 'io_debugTopDown_robHeadPaddr_bits':
        return "36'(pick_addr($urandom_range(0, 3)))"   # 与 A 通道同一地址域，TopDown 的 MissMatch 才比得上
    if name == 'io_nodeID':
        return "11'($urandom_range(0, 3))"
    if name.endswith('_ready'):
        return '($urandom_range(0, 9) < 8)'
    if w <= 32:
        return "%d'($urandom)" % w
    return "%d'({%s})" % (w, ', '.join(['$urandom'] * ((w + 31) // 32)))


COVER = [
    # (名字, golden 侧表达式（u_g. 前缀由生成器补，@ 开头的是 tb 里的 g_/输入信号））
    ('hint 发出', 'hintFire'),
    ('slice0 D 放行', '@auto_in_0_d_valid & @auto_in_0_d_ready'),
    ('slice3 D 放行', '@auto_in_3_d_valid & @auto_in_3_d_ready'),
    ('D 被 hint 挡住', '_slices_1_io_in_d_valid & ~(sliceCanFire_1 | allCanFire)'),
    # hint 选中 slice i 后 2~3 拍 i 却没有 D（hint 不准）才会"释放"；随机激励下 hint 一直准，实测 2 万拍 0 次 ——
    # 只打印，这条路径（§1 的 releaseSourceD / allCanFire 的或项）由 FM 逐寄存器覆盖
    ('(信息)releaseSourceD', 'releaseSourceD_2'),
    ('A 收下', '@auto_in_0_a_valid & @auto_in_0_a_ready'),
    ('B 发出', '@auto_in_2_b_valid & @auto_in_2_b_ready'),
    ('TXREQ 可缓存发出', '_txreq_arb_io_out_valid & _linkMonitor_io_in_tx_req_ready & req_pass & _txreq_arb_io_chosen != 3\'h4'),
    ('TXREQ MMIO 发出', '_txreq_arb_io_out_valid & _linkMonitor_io_in_tx_req_ready & _txreq_arb_io_chosen == 3\'h4'),
    ('TXREQ 被一致性挡住', '_txreq_arb_io_out_valid & ~req_pass'),
    ('TXDAT 发出', '@io_chi_tx_dat_flitv'),
    ('TXRSP 发出', '@io_chi_tx_rsp_flitv'),
    ('RXRSP 到 slice', '_rxrspPipe_pipeline_io_out_valid & ~_rxrspPipe_pipeline_io_out_bits_txnID[11] & ~isPCrdGrant'),
    ('RXRSP 到 MMIO', '_rxrspPipe_pipeline_io_out_valid & _rxrspPipe_pipeline_io_out_bits_txnID[11] & ~isPCrdGrant'),
    ('RXDAT 到 slice', '_rxdatPipe_pipeline_io_out_valid & ~_rxdatPipe_pipeline_io_out_bits_txnID[11]'),
    ('RXDAT 到 MMIO', '_rxdatPipe_pipeline_io_out_valid & _rxdatPipe_pipeline_io_out_bits_txnID[11]'),
    ('RXSNP 收下', '_linkMonitor_io_in_rx_snp_valid & _slices_0_io_out_rx_snp_ready'),
    ('PCrdGrant 入队', 'pCrdGrantValid_s1'),
    ('P-Credit 授出', '_pcrdgrant_arb_io_out_valid'),
    ('MMIO D 发出', '@auto_mmioBridge_mmio_in_d_valid & @auto_mmioBridge_mmio_in_d_ready'),
    ('预取请求到 slice', '_prefetcher_io_req_valid & (|{prefetchReqsReady_0, prefetchReqsReady_1, prefetchReqsReady_2, prefetchReqsReady_3})'),
    ('预取 train', '_prefetch_train_arb_io_out_valid'),
    ('(信息)L2 TLB 请求', '@io_l2_tlb_req_req_valid'),
    ('ECC error', '@io_error_valid'),
    ('l2Miss', '@io_l2Miss'),
    ('topDown MissMatch', '@io_debugTopDown_l2MissMatch'),
]

# 名字以 "(信息)" 开头的覆盖项只打印、不计入 TEST PASSED 判据（见下面 ARM_GROUPS 的说明）。

# 输出分组的 arm：[(条件（golden 侧，sticky）, 受管输出名前缀, 是否要求 arm 过)]
#   L2 TLB 请求组：vbop 要学出最佳偏移才会发 TLB 请求，Prefetcher 自己的 UT 里 train 每拍 1/2 也要 2.6 万 ~ 10 万拍；
#   本层 train 只来自 slice 的缺失 / 预取命中（实测 2 万拍约 160 次），200k 拍内学不出来，该组输出位（tlb req bits）
#   在本 UT 里不比、也不要求 arm —— 由 verif/ut/Prefetcher 的 UT 与 FM 覆盖；tlb req valid 仍逐拍比。
ARM_GROUPS = [
    ('linkMonitor.Decoupled2LCredit_txreqLink.out_flitv_REG', ['io_chi_tx_req_flit'], True),
    ('linkMonitor.Decoupled2LCredit_txrspLink.out_flitv_REG', ['io_chi_tx_rsp_flit'], True),
    ('linkMonitor.Decoupled2LCredit_txdatLink.out_flitv_REG', ['io_chi_tx_dat_flit'], True),
    ('(&pf_alloc_seen) & pf_tlb_seen', ['io_l2_tlb_req_req_bits_'], False),
]


VADDR_OVERRIDE = [
    # 虚地址 3/4 时间取与物理地址相同（恒等映射）：vbop 的训练流才有规律、学得出偏移、才会发 TLB 请求
    "if ($urandom_range(0, 3) != 0) auto_in_%d_a_bits_user_vaddr = 44'(auto_in_%d_a_bits_address);" % (k, k)
    for k in range(NS)]


def tb(top=TOP, pfx='', drive=None, extra_drive=None, cover=None, arm_groups=None, extra_syncs=(),
       title='TL2CHICoupledL2 UT：golden TL2CHICoupledL2 与重写 TL2CHICoupledL2_xs 双例化，同激励逐拍比对',
       genfile='verif/ut/TL2CHICoupledL2/gen_tb.py', mmio_one_in=0):
    """pfx：TL2CHICoupledL2 在 golden 顶层里的实例路径前缀（L2Top 的 UT 复用本函数时传 'inner_l2cache.'）。
    mmio_one_in：0 = MMIO 槽与 slice 的 MSHR 一起等概率入选；N > 0 = 两边都有候选时只有 1/N 的机会选 MMIO 槽
    （MMIO 槽空闲时 rx ready 恒为 1，等概率会让 RX 响应几乎全落到 MMIO 上）。"""
    drive = drive or drive_expr
    extra_drive = VADDR_OVERRIDE if extra_drive is None else extra_drive
    COVER_ = COVER if cover is None else cover
    ARM_GROUPS_ = ARM_GROUPS if arm_groups is None else arm_groups
    P = ports(top)
    ins = [(w, n) for d, w, n in P if d == 'input' and n not in ('clock', 'reset')]
    outs = [(w, n) for d, w, n in P if d == 'output']
    syncs = harvest(pfx) + list(extra_syncs)
    G_ = 'u_g.' + pfx
    gated = {}
    for gi, (_, pres, _req) in enumerate(ARM_GROUPS_):
        for w, n in outs:
            if any(n.startswith(p) for p in pres):
                if n in gated:
                    raise SystemExit('输出 %s 落入两个 arm 组' % n)
                gated[n] = gi
    for gi, (_, pres, _req) in enumerate(ARM_GROUPS_):
        if gi not in gated.values():
            raise SystemExit('arm 组 %d 没有管到任何输出' % gi)
    L = []
    A = L.append
    A('// =============================================================================')
    A('// tb —— ' + title)
    A('//       全部 %d 个输出（4 态 !==）；激励 / 同步 / arm 规则见 gen_tb.py 文件头。' % len(outs))
    A('// 本文件由 %s 生成，勿手改。' % genfile)
    A('// =============================================================================')
    A('`timescale 1ns/1ps')
    A('module tb;')
    A('  int unsigned NCYCLES = 200000;')
    A('  bit clock = 0; always #5 clock = ~clock;')
    A('  logic reset;')
    A('  longint errors = 0, checks = 0;')
    A('  longint cyc = 0;')
    A('  // 阶段（同 Slice tb）：每 4000 拍 [0,2000) 常速；[2000,3000) 下游慢；[3000,4000) MBIST 窗口。')
    A('  // 另每 50000 拍里有 600 拍 RX 链路去激活（rx_linkactivereq=0），走 LinkMonitor 的信用回收。')
    A('  function automatic bit slow_phase();  return (cyc % 4000) >= 2000 && (cyc % 4000) < 3000; endfunction')
    A('  function automatic bit mbist_phase(); return (cyc % 4000) >= 3000; endfunction')
    A('  function automatic bit link_down_phase(); return (cyc % 50000) >= 30000 && (cyc % 50000) < 30600; endfunction')
    A('')
    for w, n in ins:
        A('  logic %s%s;' % ('[%d:0] ' % (w - 1) if w > 1 else '', n))
    for w, n in outs:
        A('  logic %sg_%s, i_%s;' % ('[%d:0] ' % (w - 1) if w > 1 else '', n, n))
    A('')
    for side, mod in (('g', top), ('i', top + '_xs')):
        A('  %s u_%s (' % (mod, side))
        conns = ['    .clock(clock)', '    .reset(reset)']
        for d, w, n in P:
            if n in ('clock', 'reset'):
                continue
            conns.append('    .%s(%s)' % (n, n if d == 'input' else '%s_%s' % (side, n)))
        A(',\n'.join(conns))
        A('  );')
    A('')
    A('  // ---- 地址域：{tag 31 位, set 9 位, bank 2 位, offset 6 位}；tag 0..15、set 0..3（同 Slice tb）----')
    A('  function automatic logic [47:0] pick_addr(input int bank);')
    A("    return {31'($urandom_range(0, 15)), 9'($urandom_range(0, 3)), 2'(bank),")
    A("            ($urandom_range(0, 7) == 0) ? 6'($urandom) : 6'h0};")
    A('  endfunction')
    A('  function automatic logic [3:0] pick_a_opcode();')
    A('    case ($urandom_range(0, 9))')
    A("      0, 1: return 4'h4;  2: return 4'h5;  3, 4, 5: return 4'h6;  6, 7: return 4'h7;")
    A("      default: return 4'($urandom);")
    A('    endcase')
    A('  endfunction')
    A('  function automatic logic [3:0] pick_mmio_opcode();')
    A('    case ($urandom_range(0, 7))')
    A("      0, 1, 2: return 4'h4;  3, 4: return 4'h0;  5, 6: return 4'h1;  default: return 4'($urandom);")
    A('    endcase')
    A('  endfunction')
    A('  function automatic logic [4:0] pick_pf_source();')
    A('    case ($urandom_range(0, 7))')
    A("      0, 1: return 5'd10;  2, 3: return 5'd11;  4: return 5'd12;  5, 6: return 5'd14;  default: return 5'($urandom);")
    A('    endcase')
    A('  endfunction')
    A('  // RXRSP opcode：RetryAck 3 / Comp 4 / CompDBIDResp 5 / DBIDResp 6 / PCrdGrant 7 / ReadReceipt 8 / RespSepData B')
    A('  function automatic logic [4:0] pick_rsp_opcode();')
    A('    case ($urandom_range(0, 7))')
    A("      0: return 5'h3;  1: return 5'h4;  2: return 5'h5;  3: return 5'h6;")
    A("      4: return 5'h8;  5: return 5'hB;  6: return 5'h7;  default: return 5'($urandom);")
    A('    endcase')
    A('  endfunction')
    A('')
    A('  // ---- RXRSP / RXDAT 的目标：slice k 的 MSHR（txnID = {0, k, mshrId}）或 MMIO 槽（{1, 槽号}）----')
    A('  //   kind 0 = RXDAT；1 = RetryAck；2 = 其余 RXRSP（规则同 verif/ut/Slice/gen_tb.py 的 pick_target）')
    A('  //   MMIO 槽：响应在路上（LinkMonitor + rx*Pipe 约 3 拍）时槽仍显示在等，此时再给同一个槽发任何响应，到达时槽')
    A('  //   可能已换了状态，RXDAT 就卡在 rxdatPipe 出口（ready 只看 txnID 对上的槽）——整个 RXDAT 通道从此停摆。')
    A('  //   所以给过响应（RSP 或 DAT）的槽 16 拍内不再选。')
    A('  longint mmio_sent [16];')
    A('  initial foreach (mmio_sent[k]) mmio_sent[k] = -100;')
    A('  function automatic int pick_target(input int kind);')
    A('    int c[$];')
    for s in range(NS):
        for k in range(16):
            m = G_ + 'slices_%d.mshrCtl.mshrs_%d.' % (s, k)
            A('    if (%sreq_valid && !%sgotRetryAck && (' % (m, m))
            A('          kind == 0 ? !%sstate_w_grantlast :' % m)
            A('          kind == 1 ? (%sstate_s_acquire && !%sstate_w_grantfirst && !%sstate_w_grant ||' % (m, m, m))
            A('                       %sstate_s_release && !%sstate_w_releaseack) :' % (m, m))
            A('                      (!%sstate_w_grant || !%sstate_w_releaseack))) c.push_back(%d);' % (m, m, (s << 9) | k))
    if mmio_one_in:
        A('    begin')
        A('      int cm[$];')
        for k in range(16):
            A('      if ((kind == 0 ? %smmioBridge._entries_%d_io_chi_rx_dat_ready : %smmioBridge._entries_%d_io_chi_rx_rsp_ready)'
              ' && cyc - mmio_sent[%d] > 16) cm.push_back(%d);' % (G_, k, G_, k, k, 0x800 | k))
        A('      if (cm.size() != 0 && (c.size() == 0 || $urandom_range(0, %d) == 0)) return cm[$urandom_range(0, cm.size() - 1)];' % (mmio_one_in - 1))
        A('    end')
    else:
        for k in range(16):
            A('    if ((kind == 0 ? %smmioBridge._entries_%d_io_chi_rx_dat_ready : %smmioBridge._entries_%d_io_chi_rx_rsp_ready)'
              ' && cyc - mmio_sent[%d] > 16) c.push_back(%d);' % (G_, k, G_, k, k, 0x800 | k))
    A('    if (c.size() == 0) return -1;')
    A('    return c[$urandom_range(0, c.size() - 1)];')
    A('  endfunction')
    A('')
    A('  // ---- CHI 信用：RX 侧按 golden 的 lcrdv 记账，有信用才发 flit；TX 侧 tb 发信用，在途不超过 4 ----')
    A('  int rx_crd_rsp = 0, rx_crd_dat = 0, rx_crd_snp = 0;')
    A('  int tx_crd_req = 0, tx_crd_rsp = 0, tx_crd_dat = 0;')
    A('  bit tlb_q = 0;           // 上一拍 golden 发了 L2 TLB 请求')
    A('  task automatic credit_model_account();')
    A('    // 上一拍的结果：golden 发来的 RX 信用 / tb 发出的 RX flit；tb 发出的 TX 信用 / golden 发出的 TX flit')
    for ch in ('rsp', 'dat', 'snp'):
        A('    if (g_io_chi_rx_%s_lcrdv) rx_crd_%s++;' % (ch, ch))
        A('    if (io_chi_rx_%s_flitv) rx_crd_%s--;' % (ch, ch))
    for ch in ('req', 'rsp', 'dat'):
        A('    if (g_io_chi_tx_%s_flitv && tx_crd_%s > 0) tx_crd_%s--;' % (ch, ch, ch))
        A('    if (io_chi_tx_%s_lcrdv) tx_crd_%s++;' % (ch, ch))
    A('    if (reset || !g_io_chi_rx_linkactiveack) begin rx_crd_rsp = 0; rx_crd_dat = 0; rx_crd_snp = 0; end')
    A('    if (reset || !g_io_chi_tx_linkactivereq) begin tx_crd_req = 0; tx_crd_rsp = 0; tx_crd_dat = 0; end')
    A('  endtask')
    A('  task automatic credit_model_drive();')
    for ch in ('req', 'rsp', 'dat'):
        A("    io_chi_tx_%s_lcrdv = (tx_crd_%s < 4) && ($urandom_range(0, 1) == 0) && g_io_chi_tx_linkactivereq && io_chi_tx_linkactiveack;" % (ch, ch))
    A('  endtask')
    A('')
    A('  task automatic rx_flits();')
    A('    automatic int t;')
    A('    // RSP flit（73 位）：qos[3:0] tgtID[14:4] srcID[25:15] txnID[37:26] opcode[42:38] respErr[44:43] resp[47:45]')
    A('    //   fwdState[50:48] cBusy[53:51] dbID[65:54] pCrdType[69:66] tagOp[71:70] traceTag[72]')
    A("    io_chi_rx_rsp_flit = 73'({$urandom, $urandom, $urandom});")
    A("    io_chi_rx_rsp_flit[42:38] = pick_rsp_opcode();")
    A("    io_chi_rx_rsp_flit[25:15] = ($urandom_range(0, 15) == 0) ? 11'($urandom) : 11'($urandom_range(0, 1));")
    A("    io_chi_rx_rsp_flit[69:66] = ($urandom_range(0, 15) == 0) ? 4'($urandom) : 4'($urandom_range(0, 1));")
    A("    io_chi_rx_rsp_flit[44:43] = ($urandom_range(0, 15) == 0) ? 2'($urandom) : 2'h0;")
    A("    io_chi_rx_rsp_flitv = (rx_crd_rsp > 0) && (slow_phase() ? ($urandom_range(0, 31) == 0) : ($urandom_range(0, 3) == 0));")
    A("    if (io_chi_rx_rsp_flitv && io_chi_rx_rsp_flit[42:38] != 5'h7 && io_chi_rx_rsp_flit[42:38] != 5'h0) begin")
    A("      t = pick_target(io_chi_rx_rsp_flit[42:38] == 5'h3 ? 1 : 2);")
    A("      if (t < 0) io_chi_rx_rsp_flitv = 1'b0; else io_chi_rx_rsp_flit[37:26] = 12'(t);")
    A("      if (t >= 'h800) mmio_sent[t & 15] = cyc;")
    A('    end')
    A("    io_chi_rx_rsp_flitpend = io_chi_rx_rsp_flitv | ($urandom_range(0, 3) == 0);")
    A('    // DAT flit（422 位）：txnID[37:26] homeNID[48:38] opcode[52:49] respErr[54:53] dataID[80:79] dataCheck[417:386] poison[421:418]')
    A("    io_chi_rx_dat_flit = 422'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom,")
    A("                               $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});")
    A("    io_chi_rx_dat_flit[52:49] = ($urandom_range(0, 7) == 0) ? 4'($urandom) : (($urandom_range(0, 3) == 0) ? 4'hB : 4'h4);")
    A("    io_chi_rx_dat_flit[80:79] = 2'($urandom_range(0, 1)) << 1;")
    A("    io_chi_rx_dat_flit[48:38] = ($urandom_range(0, 15) == 0) ? 11'($urandom) : 11'($urandom_range(0, 1));")
    A("    io_chi_rx_dat_flit[54:53] = ($urandom_range(0, 15) == 0) ? 2'($urandom) : 2'h0;")
    A("    io_chi_rx_dat_flit[421:418] = ($urandom_range(0, 15) == 0) ? 4'($urandom) : 4'h0;")
    A("    io_chi_rx_dat_flitv = (rx_crd_dat > 0) && (slow_phase() ? ($urandom_range(0, 31) == 0) : ($urandom_range(0, 3) == 0));")
    A('    if (io_chi_rx_dat_flitv) begin')
    A('      t = pick_target(0);')
    A("      if (t < 0) io_chi_rx_dat_flitv = 1'b0; else io_chi_rx_dat_flit[37:26] = 12'(t);")
    A("      if (t >= 'h800) mmio_sent[t & 15] = cyc;")
    A('    end')
    A("    io_chi_rx_dat_flitpend = io_chi_rx_dat_flitv | ($urandom_range(0, 3) == 0);")
    A('    // SNP flit（115 位）：srcID[14:4] txnID[26:15] opcode[54:50] addr[99:55]（= 物理地址 >> 3）')
    A("    io_chi_rx_snp_flit = 115'({$urandom, $urandom, $urandom, $urandom});")
    A("    io_chi_rx_snp_flit[54:50] = ($urandom_range(0, 3) == 0) ? 5'($urandom) : 5'($urandom_range(1, 10));")
    A("    io_chi_rx_snp_flit[99:55] = 45'(pick_addr($urandom_range(0, 3)) >> 3);")
    A("    io_chi_rx_snp_flit[14:4] = ($urandom_range(0, 15) == 0) ? 11'($urandom) : 11'($urandom_range(0, 1));")
    A("    io_chi_rx_snp_flitv = (rx_crd_snp > 0) && ($urandom_range(0, 9) == 0);")
    A("    io_chi_rx_snp_flitpend = io_chi_rx_snp_flitv | ($urandom_range(0, 3) == 0);")
    A('  endtask')
    A('')
    A('  task automatic drive();')
    A('    credit_model_account();   // 先记上一拍的账（必须在本拍重摇输入之前：要读上一拍发出的 flitv / lcrdv）')
    for w, n in ins:
        A('    %s = %s;' % (n, drive(n, w)))
    for ln in extra_drive:
        A('    ' + ln)
    A('    tlb_q = g_io_l2_tlb_req_req_valid;')
    A('    credit_model_drive();')
    A('    rx_flits();')
    A("    reset = ($urandom_range(0, 39999) == 0);")
    A('  endtask')
    A('')
    A('  // ---- arm（按输出分组）----')
    A('  logic [15:0] pf_alloc_seen = 0;')
    A('  bit pf_tlb_seen = 0;')
    A('  bit [%d:0] armed = 0;' % (len(ARM_GROUPS_) - 1))
    A('  task automatic update_arm();')
    A('    pf_alloc_seen |= {%s};' % ', '.join(G_ + 'prefetcher.vbop.reqFilter.alloc_%d' % i for i in range(15, -1, -1)))
    A('    if (g_io_l2_tlb_req_req_valid) pf_tlb_seen = 1;')
    for gi, (cond, _, _req) in enumerate(ARM_GROUPS_):
        c = re.sub(r'\blinkMonitor\.', G_ + 'linkMonitor.', cond)
        A('    if (%s) armed[%d] = 1;' % (c, gi))
    A('  endtask')
    A('')
    A('  `define CK(nm) begin checks++; if (g_``nm !== i_``nm) begin errors++; \\')
    A('    if (errors <= 40) $display("[cycle %0d] MISMATCH %s golden=%h impl=%h", cyc, `"nm`", g_``nm, i_``nm); \\')
    A('    end end')
    A('  task automatic check();')
    for w, n in outs:
        if n in gated:
            A('    if (armed[%d]) `CK(%s)' % (gated[n], n))
        else:
            A('    `CK(%s)' % n)
    A('  endtask')
    A('')
    A('  longint cov [%d];' % len(COVER_))
    A("  localparam string COV_NAME [%d] = '{%s};" % (len(COVER_), ', '.join('"%s"' % c for c, _ in COVER_)))
    A("  localparam bit COV_INFO [%d] = '{%s};   // 1 = 只打印、不计入判据" % (
        len(COVER_), ', '.join("1'b1" if c.startswith('(信息)') else "1'b0" for c, _ in COVER_)))
    A('  task automatic sample();')
    for k, (_, expr) in enumerate(COVER_):
        e = re.sub(r"(?<![\w'@.])([A-Za-z_]\w*)", lambda m: G_ + m.group(1), expr)
        e = re.sub(r'@(\w+)', lambda m: ('g_' + m.group(1)) if m.group(1) in {n for _, n in outs} else m.group(1), e)
        A('    if (%s) cov[%d]++;' % (e, k))
    A('  endtask')
    A('')
    A('  task automatic sync_init();')
    for g, i, frc in syncs:
        # g 是 golden 侧相对路径；('RAW', 表达式) 表示收割来的现成表达式（如拼接），原样使用
        gexpr = g[1] if isinstance(g, tuple) else 'u_g.' + g
        A('    %su_i.%s = %s;' % ('force ' if frc else '', i, gexpr))
    A('    #1;')
    for g, i, frc in syncs:
        if frc:
            A('    release u_i.%s;' % i)
    A('  endtask')
    A('')
    A('  initial begin')
    A('    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;')
    A('    foreach (cov[k]) cov[k] = 0;')
    A("    drive(); reset = 1'b1;")
    A('    #1;')
    A('    sync_init();          // 未复位寄存器两侧同初值（见文件头）')
    A('    repeat (8) @(posedge clock);')
    A("    #1; drive(); reset = 1'b0;")
    A('    repeat (NCYCLES) begin')
    A('      @(posedge clock); #1; cyc++;')
    A('      update_arm(); check(); sample(); drive();')
    A('    end')
    A('    begin')
    A('      int zero = 0;')
    A('      foreach (cov[k]) begin')
    A('        $display("COVER %-24s %0d", COV_NAME[k], cov[k]);')
    A('        if (cov[k] == 0 && !COV_INFO[k]) zero++;')
    A('      end')
    A('      $display("ARMED=%b", armed);')
    A("      if ((armed & %d'b%s) != %d'b%s) zero++;   // 只要求标了必需的 arm 组" % (
        len(ARM_GROUPS_), ''.join('1' if r else '0' for _, _, r in reversed(ARM_GROUPS_)),
        len(ARM_GROUPS_), ''.join('1' if r else '0' for _, _, r in reversed(ARM_GROUPS_))))
    A('      $display("checks=%0d errors=%0d cover_zero=%0d", checks, errors, zero);')
    A('      if (errors == 0 && zero == 0) $display("TEST PASSED");')
    A('      else $display("TEST FAILED");')
    A('    end')
    A('    $finish;')
    A('  end')
    A('endmodule')
    return '\n'.join(L) + '\n'


def main():
    new = tb()
    p = HERE / 'tb.sv'
    cur = p.read_text() if p.exists() else None
    if '--check' in sys.argv[1:]:
        if cur != new:
            print('gen_tb(TL2CHICoupledL2): DRIFT tb.sv')
            return 1
        print('gen_tb(TL2CHICoupledL2): OK')
        return 0
    if cur != new:
        p.write_text(new)
        print('gen_tb(TL2CHICoupledL2): 更新 tb.sv')
    else:
        print('gen_tb(TL2CHICoupledL2): 已是最新')
    return 0


if __name__ == '__main__':
    sys.exit(main())
