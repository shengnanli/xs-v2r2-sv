#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_frontend.py —— Frontend（前端顶层装配）的 golden 同名 wrapper 生成器。

产出：rtl/frontend/Frontend.sv 里 `// BEGIN GENERATED(fe_wrapper)` … `// END GENERATED` 之间的
module Frontend：端口表（与 golden 逐位同名同序）、子模块之间的连线声明、23 个子模块例化
（实例名与 golden 一致）、可读核 u_core 的例化、直通输出 assign。手写区（文件头 + xs_Frontend_core）
脚本不碰。

★fail-closed（对照 golden 现读，任何一条不满足就非零退出、不写文件）★
  1. 端口：golden Frontend 的每个端口按原序原宽原方向出现；
  2. 例化：golden 的 23 个实例逐个照搬模块名与实例名；每个端口连接的 golden 表达式必须落进下面
     已知形状之一：
       a. 顶层端口名                       → 原样
       b. `_inner_<实例>_<端口>`（子模块输出线）→ 改名 `<别名>_<端口去 io_>`，驱动方必须是那个实例的输出口
       c. golden 具名线 inner_childBd*（MBIST 穿线）→ 改名 mbistBd<k>_<字段>，恰一个驱动
       d. 常量 / 悬空（/* unused */）      → 原样常量 / 空连接
       e. CORE_SIGNALS 表里列出的 golden 寄存器名或胶合表达式 → u_core 的同名输出口（表与核端口双向核对）
       f. inner__probe（golden 只接探针线、无读者）→ 空连接
     落不进任何一类 = 报错；
  3. 顶层输出：golden 的每个 `assign <顶层输出> = <RHS>`，RHS 必须是 (b) 类线、reset，或 CORE_TOP 表里
     对应的 golden 寄存器（此时由 u_core 的同名输出口直接驱动）；其余 golden assign 只许是 probe / bd 无读者线；
  4. u_core：核的每个端口名必须恰好对上一个顶层端口、一根子模块输出线或一个 CORE_SIGNALS 输出；
     位宽与对端逐个比对；
  5. 分组注释：实例之间每一对"谁连谁"都必须在 PAIR_DESC 里有一句说明（新出现的连接对 = 报错，逼着写清楚）；
     顶层端口按 TOP_GROUPS 前缀归组，未归组的端口 = 报错。

另产出：verif/ut/Frontend/fm_pins_pre.tcl ——**只有** Frontend 本层的「顶层胶合寄存器」钉点：golden Frontend 本层的全部
寄存器（firtool 展平名 inner_*）逐位 set_user_match 到 u_core 里的对应寄存器位。映射表 CORE_REGS 必须覆盖 golden
本层**每一个** reg 声明（漏一个即报错），对端寄存器必须在 xs_Frontend_core 里以同宽声明；钉点总数写成字面常数，
运行时逐条数返回值，拒一条或总数不符即 error。
（codex 0226：Frontend 走八个直接 child 的 exact green_child 组合，child 两侧 -interface_only 对称黑盒；以前这里还有
「子树钉点重定位 / 子树自配对录制 / 恒等副本配对类」三节共约 15 万条，全部删除——不再有 child 内部配对，也不把诊断
matched.rpt 当输入。）

用法：python3 scripts/gen_frontend.py [--check]
"""
import argparse
import collections
import os
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
G1 = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
OUT = REPO / 'rtl' / 'frontend' / 'Frontend.sv'
BEGIN = '// BEGIN GENERATED(fe_wrapper)'
END = '// END GENERATED'

# 实例别名（子模块输出线命名用）与在 wrapper 里出现的顺序 / 所属节
SECTIONS = [
    ('§A 预测与取指主干：BPU → FTQ → ICache / IFU → IBuffer，外加 MMIO 取指', [
        ('inner_bpu', 'bpu'), ('inner_ftq', 'ftq'), ('inner_icache', 'icache'),
        ('inner_ifu', 'ifu'), ('inner_ibuffer', 'ibuffer'), ('inner_instrUncache', 'instrUncache')]),
    ('§B 地址翻译与访问权限：ITLB → PTWFilter → PTWRepeaterNB → L2TLB；PMP + 5 个检查口', [
        ('inner_itlb', 'itlb'), ('inner_itlbRepeater1', 'itlbRepeater1'),
        ('inner_itlbRepeater2', 'itlbRepeater2'), ('inner_pmp', 'pmp'),
        ('inner_PMPChecker', 'pmpCheck0'), ('inner_PMPChecker_1', 'pmpCheck1'),
        ('inner_PMPChecker_2', 'pmpCheck2'), ('inner_PMPChecker_3', 'pmpCheck3'),
        ('inner_PMPChecker_4', 'pmpCheck4')]),
    ('§C CSR 打拍与 wfi 握手的延迟线', [
        ('inner_tlbCsr_delay', 'tlbCsrDelay'), ('inner_csrCtrl_delay', 'csrCtrlDelay'),
        ('inner_wfiReq_delay', 'wfiReqDelay'), ('inner_io_backend_wfi_wfiSafe_delay', 'wfiSafeDelay')]),
    ('§D 性能事件：PFEvent（CSR 选择）+ HPerfMonitor（汇成 8 路）', [
        ('inner_pfevent', 'pfevent'), ('inner_perfEvents_hpm', 'perfHpm')]),
    ('§E MBIST（存储器内建自测）分发树：接口 → 流水 → 各 SRAM 子树', [
        ('inner_mbistIntf', 'mbistIntf'), ('inner_mbistPl', 'mbistPl')]),
]
ALIAS = collections.OrderedDict((i, a) for _, lst in SECTIONS for i, a in lst)

# (e) 类：golden 里由顶层自己产生、送进子模块的信号 → u_core 输出口
CORE_SIGNALS = {
    'inner_needFlush': 'redirect_flush',
    'inner_FlushControlRedirect': 'redirect_from_ctrl',
    'inner_FlushMemVioRedirect': 'redirect_from_memvio',
    'inner_sfence_valid': 'sfence_dly_valid',
    'inner_sfence_bits_rs1': 'sfence_dly_bits_rs1',
    'inner_sfence_bits_rs2': 'sfence_dly_bits_rs2',
    'inner_sfence_bits_addr': 'sfence_dly_bits_addr',
    'inner_sfence_bits_id': 'sfence_dly_bits_id',
    'inner_sfence_bits_flushPipe': 'sfence_dly_bits_flushPipe',
    'inner_sfence_bits_hv': 'sfence_dly_bits_hv',
    'inner_sfence_bits_hg': 'sfence_dly_bits_hg',
    'inner_icache_io_csr_pf_enable_REG': 'icache_pf_enable',
    'inner_icache_io_fencei_REG': 'icache_fencei',
    '_inner_ifu_io_ftqInter_fromFtq_req_ready & _inner_icache_io_fetch_req_ready': 'fetch_req_ready',
    '_inner_wfiReq_delay_io_out & _inner_icache_io_wfi_wfiSafe & _inner_instrUncache_io_wfi_wfiSafe':
        'wfi_safe_now',
}
# 顶层输出里由 golden 寄存器直接驱动的：顶层端口 → golden 寄存器（u_core 用同名输出口驱动）
CORE_TOP = {'io_error_ecc_error_valid': 'inner_io_error_REG_ecc_error_valid',
            'io_error_ecc_error_bits': 'inner_io_error_REG_ecc_error_bits'}
for _k in range(8):
    CORE_TOP[f'io_perf_{_k}_value'] = f'inner_io_perf_{_k}_value_REG_1'

# 顶层端口分组（最长前缀命中）
TOP_GROUPS = [
    ('clock', '时钟'), ('reset', '复位'),
    ('auto_inner_icache_ctrlUnitOpt_in', 'ICache 控制寄存器 TL-UL 从口（总线经 MemBlock.FrontendBridge.icachectrl 进来）'),
    ('auto_inner_icache_client_out', 'ICache 取指 TL-UL 主口（经 MemBlock.FrontendBridge.icache 去 L2）'),
    ('auto_inner_instrUncache_client_out', 'MMIO 取指 TL-UL 主口（经 MemBlock.FrontendBridge.instr_uncache）'),
    ('io_hartId', '核号'), ('io_reset_vector', '复位向量'), ('io_fencei', 'fence.i'),
    ('io_ptw', '与 L2TLB 的页表遍历请求 / 回应'),
    ('io_backend_cfVec', '送往后端译码的指令（每拍 6 条）'),
    ('io_backend_stallReason', 'TopDown 停顿原因'),
    ('io_backend_fromFtq', 'FTQ 写给后端的 PC 存储'),
    ('io_backend_fromIfu', 'IFU 写给后端的 gpaddr 存储'),
    ('io_backend_toFtq', '后端提交 / 重定向回送 FTQ'),
    ('io_backend_canAccept', '后端译码能否接收'),
    ('io_backend_wfi', 'wfi 握手'),
    ('io_softPrefetch', '后端软件预取（prefetch.i）请求'),
    ('io_sfence', 'sfence.vma'),
    ('io_tlbCsr', 'TLB 相关 CSR'),
    ('io_csrCtrl', '自定义 CSR 控制'),
    ('io_error', 'ECC 错误上报'),
    ('io_resetInFrontend', '复位镜像'),
    ('io_dft', 'DFT 广播（SRAM 测试控制）'),
    ('io_perf', '性能事件'),
    ('gatewayIn_packed', 'MBIST 网关穿线'),
]

# 实例之间"谁连谁"的说明（无序对）。新出现的连接对必须在这里补一句，否则生成器报错。
PAIR_DESC = {
    ('bpu', 'ftq'): 'BPU 的 s1/s2/s3 预测结果写入 FTQ；FTQ 回送重定向（误预测恢复）与提交后的更新',
    ('bpu', 'csrCtrlDelay'): '分支预测器各部件开关（bp_ctrl，CSR 打两拍后）',
    ('bpu', 'perfHpm'): 'BPU 性能事件',
    ('bpu', 'mbistPl'): 'BPU 内各预测表 SRAM 的 MBIST 穿线',
    ('ftq', 'ifu'): 'FTQ 发取指请求给 IFU；IFU 回写预译码 / 误预测检查结果；MMIO 指令提交读 FTQ',
    ('ftq', 'icache'): 'FTQ 发取指请求 / 预取请求给 ICache，以及 ICache 冲刷',
    ('ftq', 'ibuffer'): 'FTQ 统计的各类重定向气泡（TopDown 用）给 IBuffer',
    ('ftq', 'perfHpm'): 'FTQ 性能事件',
    ('ftq', 'core'): 'FTQ 的取指请求握手（IFU 与 ICache 都 ready）；PC 存储写口供自检镜像',
    ('icache', 'ifu'): 'ICache 回指令数据与 topdown 信息给 IFU；IFU 让 ICache 停（stop）；ICache 命中统计给 IFU',
    ('icache', 'itlb'): 'ICache 预取流水的 2 个 ITLB 请求口 / 回应',
    ('icache', 'pmpCheck0'): 'ICache 物理地址权限检查口 0',
    ('icache', 'pmpCheck1'): 'ICache 物理地址权限检查口 1',
    ('icache', 'pmpCheck2'): 'ICache 物理地址权限检查口 2',
    ('icache', 'pmpCheck3'): 'ICache 物理地址权限检查口 3',
    ('icache', 'wfiReqDelay'): 'wfi 请求（打一拍后）',
    ('icache', 'perfHpm'): 'ICache 性能事件',
    ('icache', 'core'): 'L1I 预取开关 / fence.i（各打一拍）；ECC 错误；wfi 安全',
    ('icache', 'mbistPl'): 'ICache tag / data SRAM 的 MBIST 穿线',
    ('ifu', 'ibuffer'): 'IFU 把预译码后的取指块写进 IBuffer',
    ('ifu', 'instrUncache'): 'IFU 的 MMIO 取指请求 / 回应',
    ('ifu', 'itlb'): 'IFU 的 MMIO 取指重新翻译口（ITLB 第 3 口，阻塞式）',
    ('ifu', 'pmpCheck4'): 'IFU（MMIO 取指）的物理地址权限检查口',
    ('ifu', 'csrCtrlDelay'): '前端断点触发器配置与 fsIsOff（CSR 打两拍后）',
    ('ifu', 'perfHpm'): 'IFU 性能事件',
    ('ifu', 'core'): 'IFU 对取指请求的 ready（与 ICache 的 ready 相与后给 FTQ）',
    ('ibuffer', 'perfHpm'): 'IBuffer 性能事件',
    ('ibuffer', 'core'): '后端重定向冲刷与原因标志（打一拍）；出口 6 条指令供自检',
    ('instrUncache', 'wfiReqDelay'): 'wfi 请求（打一拍后）',
    ('instrUncache', 'core'): 'MMIO 取指的 wfi 安全',
    ('itlb', 'itlbRepeater1'): 'ITLB 未命中 → PTWFilter（去重、排队）；回填结果回到 ITLB',
    ('itlb', 'tlbCsrDelay'): 'satp/vsatp/hgatp/特权级等 TLB CSR（打两拍后）',
    ('itlb', 'perfHpm'): 'ITLB 性能事件',
    ('itlb', 'core'): 'sfence.vma（打两拍后）',
    ('itlbRepeater1', 'itlbRepeater2'): 'PTWFilter → PTWRepeaterNB（再打拍）→ L2TLB',
    ('itlbRepeater1', 'tlbCsrDelay'): 'TLB CSR（打两拍后）',
    ('itlbRepeater1', 'core'): 'sfence.vma（打两拍后）',
    ('itlbRepeater2', 'tlbCsrDelay'): 'TLB CSR（打两拍后）',
    ('itlbRepeater2', 'core'): 'sfence.vma（打两拍后）',
    ('pmp', 'csrCtrlDelay'): 'pmpcfg/pmpaddr 等 CSR 写广播（打两拍后）',
    ('pmp', 'pmpCheck0'): 'PMP/PMA 表项给检查口 0',
    ('pmp', 'pmpCheck1'): 'PMP/PMA 表项给检查口 1',
    ('pmp', 'pmpCheck2'): 'PMP/PMA 表项给检查口 2',
    ('pmp', 'pmpCheck3'): 'PMP/PMA 表项给检查口 3',
    ('pmp', 'pmpCheck4'): 'PMP/PMA 表项给检查口 4',
    ('pmpCheck0', 'tlbCsrDelay'): '当前特权级 / debug（打两拍后）',
    ('pmpCheck1', 'tlbCsrDelay'): '当前特权级 / debug（打两拍后）',
    ('pmpCheck2', 'tlbCsrDelay'): '当前特权级 / debug（打两拍后）',
    ('pmpCheck3', 'tlbCsrDelay'): '当前特权级 / debug（打两拍后）',
    ('pmpCheck4', 'tlbCsrDelay'): '当前特权级 / debug（打两拍后）',
    ('csrCtrlDelay', 'core'): 'L1I 预取开关（延迟后的 csrCtrl 再打一拍给 ICache）',
    ('wfiReqDelay', 'core'): 'wfi 请求（打一拍后）参与 safe 判定',
    ('wfiSafeDelay', 'core'): 'wfi safe（三者相与）再打一拍回后端',
    ('pfevent', 'perfHpm'): 'CSR 选出的 8 个性能事件编码',
    ('perfHpm', 'core'): '8 路性能计数增量（再打两拍送出）',
    ('mbistIntf', 'mbistPl'): 'MBIST 接口 ↔ 分发流水',
}


# 顶层胶合寄存器：golden 本层寄存器名（去掉 inner_ 前缀前的全名）→ (u_core 里的寄存器名, 数组维)
#   维为 None：标量/向量寄存器；为 (n, 'idx')：golden 是 n 个展平名 <...>_<i>_<...>，impl 是非打包数组 name[i]
CORE_REGS = collections.OrderedDict([
    ('inner_needFlush', 'redirect_flush'),
    ('inner_FlushControlRedirect', 'redirect_from_ctrl'),
    ('inner_FlushMemVioRedirect', 'redirect_from_memvio'),
] + [('inner_sfence_REG_valid', 'sfence_s1_valid')]
  + [('inner_sfence_REG_bits_%s' % f, 'sfence_s1_%s' % f) for f in ('rs1', 'rs2', 'addr', 'id', 'flushPipe', 'hv', 'hg')]
  + [('inner_sfence_valid', 'sfence_dly_valid')]
  + [('inner_sfence_bits_%s' % f, 'sfence_dly_bits_%s' % f) for f in ('rs1', 'rs2', 'addr', 'id', 'flushPipe', 'hv', 'hg')]
  + [('inner_icache_io_csr_pf_enable_REG', 'icache_pf_enable'),
     ('inner_icache_io_fencei_REG', 'icache_fencei')]
  + [('inner_checkPcMem_%d_startAddr' % i, 'check_pc_mem[%d]' % i) for i in range(64)]
  + [('inner_prevTakenValid', 'taken_ptr_valid_q'),
     ('inner_prevTakenFtqPtr_flag', 'taken_ptr_flag_q'),
     ('inner_prevTakenFtqPtr_value', 'taken_ptr_value_q'),
     ('inner_prevTakenFtqPtr_1_flag', 'taken_tgt_ptr_flag_q'),
     ('inner_prevTakenFtqPtr_1_value', 'taken_tgt_ptr_value_q'),
     ('inner_prevTakenValid_1', 'taken_tgt_valid_q'),
     ('inner_prevNotTakenPC', 'not_taken_pc_q'),
     ('inner_prevIsRVC', 'not_taken_is_rvc_q'),
     ('inner_prevNotTakenValid', 'not_taken_valid_q'),
     ('inner_errorReg_valid', 'err_valid_q'),
     ('inner_errorReg_bits_paddr', 'err_paddr_q'),
     ('inner_errorReg_bits_report_to_beu', 'err_report_q'),
     ('inner_io_error_REG_ecc_error_valid', 'io_error_ecc_error_valid'),
     ('inner_io_error_REG_ecc_error_bits', 'io_error_ecc_error_bits')]
  + [('inner_io_perf_%d_value_REG' % k, 'perf_s1[%d]' % k) for k in range(8)]
  + [('inner_io_perf_%d_value_REG_1' % k, 'perf_s2[%d]' % k) for k in range(8)])
PINS = REPO / 'verif' / 'ut' / 'Frontend' / 'fm_pins_pre.tcl'

PORT_RE = re.compile(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?$')


def fail(msg):
    sys.stderr.write('gen_frontend: FAIL: %s\n' % msg)
    sys.exit(1)


def golden_ports(mod):
    t = (G1 / ('%s.sv' % mod)).read_text(errors='replace')
    m = re.search(r'^module %s\(\n(.*?)\n\);' % re.escape(mod), t, re.M | re.S)
    if not m:
        fail('golden %s 端口表解析失败' % mod)
    out = []
    for ln in m.group(1).splitlines():
        pm = PORT_RE.match(ln)
        if not pm:
            fail('golden %s 端口行形状未知: %r' % (mod, ln))
        out.append((pm.group(1), int(pm.group(2) or 0) + 1, pm.group(3)))
    return out


def parse_golden_frontend():
    t = (G1 / 'Frontend.sv').read_text(errors='replace')
    start = re.search(r'^module Frontend\(', t, re.M).start()
    body = t[start:]
    body = body[:body.index('\nendmodule')]
    code = body[body.index('\n);') + 3:]
    code = re.sub(r'`ifndef SYNTHESIS.*?`endif // not def SYNTHESIS', '', code, flags=re.S)
    code = re.sub(r'`ifdef ENABLE_INITIAL_REG_.*?`endif // ENABLE_INITIAL_REG_', '', code, flags=re.S)
    insts = collections.OrderedDict()
    for m in re.finditer(r'^  (\w+) (\w+) \(\n(.*?)\n  \);', code, re.M | re.S):
        conns = []
        for c in re.finditer(r'\.(\w+)\s*\((.*?)\)(?=,\n|\Z)', m.group(3), re.S):
            conns.append((c.group(1), ' '.join(c.group(2).split())))
        insts[m.group(2)] = (m.group(1), conns)
    assigns = []
    for m in re.finditer(r'^  assign (\w+) =\s*(.*?);', code, re.M | re.S):
        assigns.append((m.group(1), ' '.join(m.group(2).split())))
    return golden_ports('Frontend'), insts, assigns


def parse_core():
    t = OUT.read_text()
    m = re.search(r'^module xs_Frontend_core \(\n(.*?)\n\);', t, re.M | re.S)
    if not m:
        fail('rtl/frontend/Frontend.sv 里找不到手写核 xs_Frontend_core 的端口表')
    ports = []
    for ln in m.group(1).splitlines():
        s = ln.strip()
        if not s or s.startswith('//'):
            continue
        pm = re.match(r'(input|output)\s+logic\s+(?:\[(\d+):0\]\s+)?(\w+),?$', s)
        if not pm:
            fail('核端口行形状未知: %r' % ln)
        ports.append((pm.group(1), int(pm.group(2) or 0) + 1, pm.group(3)))
    return ports


def top_group(name):
    best = None
    for pfx, desc in TOP_GROUPS:
        if name == pfx or name.startswith(pfx + '_'):
            if best is None or len(pfx) > len(best[0]):
                best = (pfx, desc)
    if best is None:
        fail('顶层端口 %s 没有归组（补 TOP_GROUPS）' % name)
    return best


def strip_io(p):
    return p[3:] if p.startswith('io_') else p


def build():
    tports, insts, assigns = parse_golden_frontend()
    tdir = {n: d for d, w, n in tports}
    twid = {n: w for d, w, n in tports}
    if list(insts) != [i for i in insts] or set(insts) != set(ALIAS):
        fail('golden 实例集合与 ALIAS 不一致: golden=%s' % sorted(insts))
    cports = {}
    for inst, (mod, conns) in insts.items():
        ps = golden_ports(mod)
        cports[inst] = {n: (d, w) for d, w, n in ps}
        names = [p for p, _ in conns]
        if sorted(names) != sorted(cports[inst]):
            fail('%s(%s) 的连接端口集合与模块端口表不一致' % (inst, mod))
    core = parse_core()
    core_names = {n: (d, w) for d, w, n in core}

    # ---- 1. 子模块输出线 / 具名线 的驱动表 ----
    child_net = {}        # golden 表达式 -> (新名, 驱动实例, 端口, 宽)
    named_drv = collections.defaultdict(list)
    for inst, (mod, conns) in insts.items():
        for p, e in conns:
            d, w = cports[inst][p]
            if d != 'output':
                continue
            if e.startswith('_inner_'):
                want = '_%s_%s' % (inst, p)
                if e != want:
                    fail('%s.%s 驱动的线名 %s 不是预期的 %s' % (inst, p, e, want))
                child_net[e] = ('%s_%s' % (ALIAS[inst], strip_io(p)), inst, p, w)
            elif e.startswith('inner_childBd'):
                named_drv[e].append((inst, p, w))
    bd_net = {}
    for e, drv in named_drv.items():
        if len(drv) != 1:
            fail('具名线 %s 有 %d 个驱动' % (e, len(drv)))
        m = re.fullmatch(r'inner_childBd(?:_(\d+))?_(\w+)', e)
        k = m.group(1) or '0'
        bd_net[e] = ('mbistBd%s_%s' % (k, m.group(2)), drv[0][0], drv[0][1], drv[0][2])
    newnames = [v[0] for v in list(child_net.values()) + list(bd_net.values())]
    dup = [n for n, c in collections.Counter(newnames).items() if c > 1]
    if dup:
        fail('改名后线名冲突: %s' % dup[:5])
    clash = set(newnames) & set(tdir)
    if clash:
        fail('改名后线名与顶层端口冲突: %s' % sorted(clash)[:5])

    # ---- 2. 核输出 ----
    core_out = {}
    for g, n in CORE_SIGNALS.items():
        if n not in core_names or core_names[n][0] != 'output':
            fail('CORE_SIGNALS[%r] -> %s 不是 xs_Frontend_core 的输出口' % (g, n))
        core_out[g] = n

    # ---- 3. 逐实例逐端口分类 ----
    consumers = collections.defaultdict(list)   # 新线名 -> [(实例/core/top)]
    rendered = collections.OrderedDict()
    used_core_out = set()
    for inst, (mod, conns) in insts.items():
        rows = []
        for p, e in conns:
            d, w = cports[inst][p]
            if e in ('', '/* unused */'):
                if d != 'output':
                    fail('%s.%s 是输入却悬空' % (inst, p))
                rows.append((p, '', d, ('unused', None)))
            elif e in tdir:
                if twid[e] != w:
                    fail('%s.%s 宽 %d 与顶层 %s 宽 %d 不符' % (inst, p, w, e, twid[e]))
                rows.append((p, e, d, ('top', top_group(e))))
            elif e in child_net:
                n, di, dp, dw = child_net[e]
                if d == 'output':
                    rows.append((p, n, d, ('drv', None)))
                else:
                    if dw != w:
                        fail('%s.%s 宽 %d 与驱动 %s 宽 %d 不符' % (inst, p, w, n, dw))
                    consumers[n].append(ALIAS[inst])
                    rows.append((p, n, d, ('inst', ALIAS[di])))
            elif e in bd_net:
                n, di, dp, dw = bd_net[e]
                if d == 'output':
                    rows.append((p, n, d, ('drv', None)))
                else:
                    consumers[n].append(ALIAS[inst])
                    rows.append((p, n, d, ('inst', ALIAS[di])))
            elif re.fullmatch(r"\d+'h[0-9A-F]+", e):
                if d != 'input':
                    fail('%s.%s 输出接常量' % (inst, p))
                rows.append((p, e, d, ('const', None)))
            elif e in core_out:
                n = core_out[e]
                if core_names[n][1] != w:
                    fail('核输出 %s 宽 %d 与 %s.%s 宽 %d 不符' % (n, core_names[n][1], inst, p, w))
                used_core_out.add(n)
                rows.append((p, n, d, ('core', None)))
            elif e == 'inner__probe' and d == 'output':
                rows.append((p, '', d, ('unused', None)))
            else:
                fail('%s.%s 的 golden 连接表达式未归类: %r' % (inst, p, e))
        rendered[inst] = (mod, rows)
    missing = set(CORE_SIGNALS.values()) - used_core_out
    if missing:
        fail('CORE_SIGNALS 里有核输出没被任何子模块用到: %s' % sorted(missing))

    # ---- 4. 顶层输出 ----
    top_assign = collections.OrderedDict()
    for lhs, rhs in assigns:
        if lhs in tdir:
            if tdir[lhs] != 'output':
                fail('assign 给顶层输入 %s' % lhs)
            if rhs in child_net:
                n = child_net[rhs][0]
                if child_net[rhs][3] != twid[lhs]:
                    fail('assign %s 宽不符' % lhs)
                consumers[n].append('top')
                top_assign[lhs] = n
            elif rhs == 'reset' and lhs == 'io_resetInFrontend':
                top_assign[lhs] = 'reset'
            elif lhs in CORE_TOP and CORE_TOP[lhs] == rhs:
                if lhs not in core_names or core_names[lhs] != ('output', twid[lhs]):
                    fail('顶层输出 %s 应由核同名同宽输出口驱动' % lhs)
                top_assign[lhs] = None            # 由 u_core 直接驱动
            else:
                fail('顶层输出 %s 的 golden 驱动 %r 未归类' % (lhs, rhs))
        elif not re.fullmatch(r'inner__probe_\d+|inner_bd_(ack|outdata)', lhs):
            fail('golden 内部 assign %s 未归类（只许 probe / bd 无读者线）' % lhs)
    if set(CORE_TOP) - set(top_assign):
        fail('CORE_TOP 有顶层输出 golden 里不是寄存器驱动: %s' % sorted(set(CORE_TOP) - set(top_assign)))
    driven_by_inst = {e for _, (_, rows) in rendered.items() for p, e, d, k in rows
                      if d == 'output' and k[0] == 'top'}
    for d, w, n in tports:
        if d == 'output' and (n in top_assign) == (n in driven_by_inst):
            fail('顶层输出 %s 的驱动不唯一或缺失' % n)

    # ---- 5. u_core 端口 ----
    netw = {v[0]: v[3] for v in list(child_net.values()) + list(bd_net.values())}
    core_conn = []
    for d, w, n in core:
        if n in tdir:
            if tdir[n] != d or twid[n] != w:
                fail('核端口 %s 与同名顶层端口方向/宽不符' % n)
            if d == 'output' and n not in CORE_TOP:
                fail('核输出 %s 驱动顶层但 golden 不是寄存器驱动' % n)
        elif n in netw:
            if d != 'input' or netw[n] != w:
                fail('核端口 %s 应是宽 %d 的输入（子模块输出线）' % (n, netw[n]))
            consumers[n].append('core')
        elif n in used_core_out:
            pass
        else:
            fail('核端口 %s 对不上任何顶层端口 / 子模块输出线 / CORE_SIGNALS 输出' % n)
        core_conn.append((d, w, n))

    # ---- 6. 连接对说明齐全 ----
    def pair(a, b):
        k = tuple(sorted((a, b)))
        if k in PAIR_DESC:
            return PAIR_DESC[k]
        if (b, a) in PAIR_DESC:
            return PAIR_DESC[(b, a)]
        if (a, b) in PAIR_DESC:
            return PAIR_DESC[(a, b)]
        return None
    need = set()
    for inst, (mod, rows) in rendered.items():
        a = ALIAS[inst]
        for p, e, d, k in rows:
            if k[0] == 'inst':
                need.add((a, k[1]))
            elif k[0] == 'core':
                need.add((a, 'core'))
            elif k[0] == 'drv':
                for c in consumers.get(e, []):
                    if c != 'top':
                        need.add((a, c))
    miss = sorted({tuple(sorted(x)) for x in need if pair(*x) is None})
    if miss:
        fail('PAIR_DESC 缺这些连接对的说明: %s' % miss)
    return tports, rendered, child_net, bd_net, consumers, core_conn, top_assign, pair, netw


def decl(w, n, kind='logic'):
    return '  %s %s%s;' % (kind, ('[%d:0] ' % (w - 1)) if w > 1 else '', n)


def render():
    tports, rendered, child_net, bd_net, consumers, core_conn, top_assign, pair, netw = build()
    L = []
    A = L.append
    A(BEGIN + ' —— 由 scripts/gen_frontend.py 从 golden 端口表与例化表产出，勿手改')
    A('// golden 同名 wrapper：端口与 golden 逐位同名同序；子模块实例名与 golden 一致；')
    A('// 子模块之间的线一律命名为"<驱动实例别名>_<端口名去掉 io_>"。')
    A('module Frontend (')
    for k, (d, w, n) in enumerate(tports):
        A('  %-6s logic %s%s%s' % (d, ('[%d:0] ' % (w - 1)) if w > 1 else '', n,
                                   ',' if k + 1 < len(tports) else ''))
    A(');')
    A('')
    A('  // ===========================================================================')
    A('  // 子模块输出线（按驱动实例分组；只声明有读者的那些——直接接顶层输出的口不经线）')
    A('  // ===========================================================================')
    by_drv = collections.OrderedDict((i, []) for i in ALIAS)
    for e, (n, di, dp, w) in list(child_net.items()) + list(bd_net.items()):
        by_drv[di].append((n, w))
    for i, nets in by_drv.items():
        if not nets:
            continue
        A('  // ---- %s（%s）----' % (ALIAS[i], i))
        for n, w in nets:
            A(decl(w, n))
    A('  // ---- 可读核产生、送进子模块的信号 ----')
    for d, w, n in core_conn:
        if d == 'output' and n not in dict((x[2], 1) for x in tports):
            A(decl(w, n))
    A('')
    A('  // ===========================================================================')
    A('  // 可读核：重定向分发 / CSR 与 sfence 打拍 / 取指握手 / wfi / 错误上报 / 性能 / 自检')
    A('  // ===========================================================================')
    A('  xs_Frontend_core u_core (')
    for k, (d, w, n) in enumerate(core_conn):
        A('    .%s (%s)%s' % (n, n, ',' if k + 1 < len(core_conn) else ''))
    A('  );')
    for title, lst in SECTIONS:
        A('')
        A('  // ===========================================================================')
        A('  // %s' % title)
        A('  // ===========================================================================')
        for inst, alias in lst:
            mod, rows = rendered[inst]
            groups = collections.OrderedDict()
            for p, e, d, k in rows:
                if k[0] == 'top' and k[1][0] in ('clock', 'reset'):
                    key = ('top', 'clock/reset')
                    head = '时钟 / 复位'
                elif k[0] == 'top':
                    key = ('top', k[1][0])
                    head = '顶层 %s* —— %s' % (k[1][0], k[1][1])
                elif k[0] == 'inst':
                    key = ('inst', k[1])
                    head = '← %s：%s' % (k[1], pair(alias, k[1]))
                elif k[0] == 'core':
                    key = ('core',)
                    head = '← u_core：%s' % pair(alias, 'core')
                elif k[0] == 'drv':
                    cs = [c for c in collections.OrderedDict.fromkeys(consumers.get(e, []))]
                    key = ('drv', tuple(cs))
                    if cs == ['top']:
                        head = '→ 顶层输出（经 assign）'
                    else:
                        parts = []
                        for c in cs:
                            parts.append('顶层输出' if c == 'top' else '%s（%s）' % (c, pair(alias, c)))
                        head = '→ ' + '；'.join(parts)
                elif k[0] == 'const':
                    key = ('const',)
                    head = '常量（golden 在本配置下钉死的输入）'
                else:
                    key = ('unused',)
                    head = '无读者的输出（golden 同样悬空）'
                groups.setdefault(key, (head, []))[1].append((p, e))
            pw = max(len(p) for p, _, _, _ in rows)
            A('  %s %s (' % (mod, inst))
            flat = [(key, head, p, e) for key, (head, items) in groups.items() for p, e in items]
            last = len(flat) - 1
            prev = None
            for idx, (key, head, p, e) in enumerate(flat):
                if key != prev:
                    A('    // ---- %s ----' % head)
                    prev = key
                A('    .%-*s (%s)%s' % (pw, p, e, ',' if idx < last else ''))
            A('  );')
    A('')
    A('  // ===========================================================================')
    A('  // 直通输出：子模块结果原样送出（io_error / io_perf 由 u_core 直接驱动）')
    A('  // ===========================================================================')
    for lhs, rhs in top_assign.items():
        if rhs is not None:
            A('  assign %s = %s;' % (lhs, rhs))
    A('')
    A('endmodule')
    A(END)
    return '\n'.join(L) + '\n'


def golden_top_regs():
    t = (G1 / 'Frontend.sv').read_text(errors='replace')
    start = re.search(r'^module Frontend\(', t, re.M).start()
    body = t[start:]
    body = body[:body.index('\nendmodule')]
    body = re.sub(r'`ifdef ENABLE_INITIAL_REG_.*?`endif // ENABLE_INITIAL_REG_', '', body, flags=re.S)
    regs = collections.OrderedDict()
    for m in re.finditer(r'^  reg\s+(?:\[(\d+):0\]\s+)?(\w+);', body, re.M):
        regs[m.group(2)] = int(m.group(1) or 0) + 1
    return regs


def core_regs():
    t = OUT.read_text()
    m = re.search(r'^module xs_Frontend_core \((.*?)^endmodule', t, re.M | re.S)
    body = m.group(1)
    # 核里用到的宽度 / 维度参数（与核内 localparam 一致；对不上时下面的宽度核对会报错）
    for k, v in (('VADDR_W-1', '49'),):
        body = body.replace('[%s:0]' % k, '[%s:0]' % v)
    out = {}
    for mm in re.finditer(r'^\s*(?:output\s+)?logic\s+(?:\[(\d+):0\]\s+)?(\w+)(?:\s*\[(\w+)\])?\s*[;,]', body, re.M):
        w = int(mm.group(1) or 0) + 1
        n = mm.group(3)
        if n is not None and not n.isdigit():
            n = {'NUM_PERF': '8', 'FTQ_SIZE': '64', 'DECODE_WIDTH': '6'}.get(n)
        out[mm.group(2)] = (w, int(n) if n else None)
    return out


def render_pins():
    g = golden_top_regs()
    c = core_regs()
    miss = [r for r in g if r not in CORE_REGS]
    extra = [r for r in CORE_REGS if r not in g]
    if miss or extra:
        fail('CORE_REGS 与 golden 本层寄存器不对应：缺 %s 多 %s' % (miss[:5], extra[:5]))
    pairs = []
    for gr, ir in CORE_REGS.items():
        w = g[gr]
        mm = re.fullmatch(r'(\w+)(?:\[(\d+)\])?', ir)
        base, idx = mm.group(1), mm.group(2)
        if base not in c:
            fail('u_core 里找不到寄存器 %s' % base)
        cw, cn = c[base]
        if cw != w or (idx is None) != (cn is None) or (idx is not None and int(idx) >= cn):
            fail('寄存器 %s(宽 %d) 与 u_core.%s(宽 %d, 维 %s) 不符' % (gr, w, ir, cw, cn))
        ipre = 'u_core/%s_reg%s' % (base, '' if idx is None else '[%s]' % idx)
        for b in range(w):
            rb = '' if w == 1 else '[%d]' % b
            pairs.append(('r:/WORK/Frontend/%s_reg%s' % (gr, rb), 'i:/WORK/Frontend/%s%s' % (ipre, rb)))
    L = []
    A = L.append
    A('# Frontend FM 「匹配前」钉点 —— 自动生成：scripts/gen_frontend.py（勿手改；规则与理由见生成器文件头）')
    A('# 只 set_user_match 消名差：不约束 ref、不改 appvar、不加黑盒。逐条数返回值，拒一条或总数不等于字面常数即 error。')
    A('# 跑在 sidecar 的 safe child interp 里：只用 set_user_match / puts / error。进 fm.log 的输出一律 ASCII。')
    A('if {$top ne "Frontend"} { error "FRONTEND_PRE_PIN_UNKNOWN_TOP=$top" }')
    A('# ---- 一、顶层胶合寄存器（golden 本层 %d 个寄存器 / %d 位 -> u_core）----' % (len(g), len(pairs)))
    A('set ::FE_CORE_EXPECT %d' % len(pairs))
    A('set ::FE_CORE_OK 0')
    A('set ::FE_CORE_BAD 0')
    A('proc fe_core_pin {r i} {')
    A('  if {[set_user_match $r $i]} { incr ::FE_CORE_OK } else {')
    A('    incr ::FE_CORE_BAD')
    A('    if {$::FE_CORE_BAD <= 10} { puts "FE_CORE_PIN_FAIL: $r <-> $i" }')
    A('  }')
    A('}')
    A('puts "FE_CORE_PIN_BEGIN expect=$::FE_CORE_EXPECT"')
    for r, i in pairs:
        A('fe_core_pin {%s} {%s}' % (r, i))
    A('puts "FE_CORE_PIN_END ok=$::FE_CORE_OK bad=$::FE_CORE_BAD expect=$::FE_CORE_EXPECT"')
    A('if {$::FE_CORE_BAD != 0 || $::FE_CORE_OK != $::FE_CORE_EXPECT} {')
    A('  error "FE_CORE_PIN: ok=$::FE_CORE_OK bad=$::FE_CORE_BAD expect=$::FE_CORE_EXPECT"')
    A('}')
    return '\n'.join(L) + '\n'


# ---------------------------------------------------------------------------
# 二、白盒直接子模块的内部配对（codex 0226：只给**本层白盒**的 10 种非 green 子模块；八个 green child 内部一律不碰）
#   a. 子模块自己签核用的钉点脚本原样重定位（tclsh 打桩执行取字面对，只换层次前缀）：PMP、PTWRepeaterNB；
#   b. 由两侧源码结构推出的语义配对（不读任何诊断 matched.rpt）——这几处在 Frontend 层两侧都无读者（对称死位），
#      FM 不做函数配对，名字又不同，需要显式对上再由 vmucp 真比：
#      · PFEvent：golden perfEvents_<n>/reg_<FIELD> ↔ 重写 g_evt[n].perfEvents/u_core/<field 小写>（逐字段同宽）；
#      · DelayN_8（inner_csrCtrl_delay）：golden REG[_k]_<端口名去 io_in_> ↔ 重写 u_core/g_chain.stage_reg[k][off]，
#        off 由重写 wrapper 里 payload_in 的拼接顺序（= io_in_* 端口声明顺序，MSB 在前）逐位算出；
#      · MbistPipeFrontend（inner_mbistPl）：golden pipelineDataOutReg ↔ 重写 u_core/g_node_return.pipelineDataOutReg。
# ---------------------------------------------------------------------------
G1 = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
CHILD_PIN_REBASE = [  # (钉点脚本, golden 设计名, golden 实例, 重写实例)
    ('verif/ut/PMP/fm_pins_pre.tcl', 'PMP', 'inner_pmp', 'inner_pmp'),
    ('verif/ut/PTWRepeaterNB/fm_pins_pre.tcl', 'PTWRepeaterNB', 'inner_itlbRepeater2', 'inner_itlbRepeater2'),
]
_EXTRACT_TCL = r"""
set top [lindex $argv 1]
proc set_user_match {args} {
  set a [lsearch -all -inline -not -regexp $args {^-}]
  puts "PAIR\t[lindex $a 0]\t[lindex $a 1]"
  return 1
}
rename puts _puts
proc puts {args} { if {[string match "PAIR*" [lindex $args end]]} { _puts [lindex $args end] } }
proc error {args} { _puts stderr "PINFILE_ERROR $args"; exit 3 }
source [lindex $argv 0]
"""


def rebased_child_pins():
    import subprocess
    import tempfile
    out = []
    with tempfile.NamedTemporaryFile('w', suffix='.tcl', delete=False) as f:
        f.write(_EXTRACT_TCL)
        stub = f.name
    for pin, design, gi, ii in CHILD_PIN_REBASE:
        r = subprocess.run(['tclsh', stub, str(REPO / pin), design], stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE, universal_newlines=True)
        if r.returncode:
            fail('钉点脚本 %s 执行失败: %s' % (pin, r.stderr[:200]))
        n = 0
        for ln in r.stdout.splitlines():
            _, a, b = ln.split('\t')
            if not a.startswith('r:/WORK/%s/' % design) or not b.startswith('i:/WORK/%s/' % design):
                fail('%s 的钉点不在 %s 层次内: %s %s' % (pin, design, a, b))
            out.append(('r:/WORK/Frontend/%s/%s' % (gi, a[len('r:/WORK/%s/' % design):]),
                        'i:/WORK/Frontend/%s/%s' % (ii, b[len('i:/WORK/%s/' % design):])))
            n += 1
        if not n:
            fail('钉点脚本 %s 一条也没给出' % pin)
    os.unlink(stub)
    return out


def _golden_regs(mod):
    t = (G1 / (mod + '.sv')).read_text()
    body = t[t.index('module %s(' % mod):]
    body = body[:body.index('endmodule')]
    return [(n, int(w) + 1 if w else 1)
            for w, n in re.findall(r'^\s+reg\s+(?:\[(\d+):0\]\s+)?(\w+);', body, re.M)]


def semantic_child_pins():
    out = []
    # PFEvent
    t = (G1 / 'PFEvent.sv').read_text()
    insts = re.findall(r'^\s{2}perfEventsModule perfEvents_(\d+) \($', t, re.M)
    if not insts:
        fail('golden PFEvent 里找不到 perfEventsModule 实例')
    regs = _golden_regs('perfEventsModule')
    impl = (REPO / 'rtl' / 'backend' / 'perfEventsModule.sv').read_text()
    for n in insts:
        for name, w in regs:
            if not name.startswith('reg_'):
                fail('perfEventsModule 出现不认识的寄存器 %s' % name)
            iname = name[4:].lower()
            if not re.search(r'\blogic\b[^;]*\b%s\b' % iname, impl):
                fail('重写 perfEventsModule 里没有 %s' % iname)
            for b in range(w):
                rb = '' if w == 1 else '[%d]' % b
                out.append(('r:/WORK/Frontend/inner_pfevent/perfEvents_%s/%s_reg%s' % (n, name, rb),
                            'i:/WORK/Frontend/inner_pfevent/g_evt[%s].perfEvents/u_core/%s_reg%s' % (n, iname, rb)))
    # DelayN_8（inner_csrCtrl_delay）
    src = (REPO / 'rtl' / 'common' / 'DelayN_8.sv').read_text()
    ins = [(n, int(w) + 1 if w else 1)
           for w, n in re.findall(r'^\s*input\s+(?:\[(\d+):0\]\s+)?io_in_(\w+),?$', src, re.M)]
    cat = re.search(r'assign payload_in =\s*\{([^}]*)\};', src).group(1)
    order = [x.strip()[len('io_in_'):] for x in cat.split(',')]
    if order != [n for n, _ in ins]:
        fail('DelayN_8 payload_in 的拼接顺序与 io_in_* 声明顺序不一致')
    off, o = {}, sum(w for _, w in ins)
    for n, w in ins:
        o -= w
        off[n] = (o, w)
    for name, w in _golden_regs('DelayN_8'):
        m = re.fullmatch(r'REG(?:_(\d+))?_(\w+)', name)
        if not m or m.group(2) not in off or off[m.group(2)][1] != w:
            fail('DelayN_8 寄存器 %s 对不上任何 io_in_ 字段' % name)
        k, (lo, _) = int(m.group(1) or 0), off[m.group(2)]
        for b in range(w):
            rb = '' if w == 1 else '[%d]' % b
            out.append(('r:/WORK/Frontend/inner_csrCtrl_delay/%s_reg%s' % (name, rb),
                        'i:/WORK/Frontend/inner_csrCtrl_delay/u_core/g_chain.stage_reg[%d][%d]' % (k, lo + b)))
    # MbistPipeFrontend
    for name, w in _golden_regs('MbistPipeFrontend'):
        if name == 'pipelineDataOutReg':
            for b in range(w):
                out.append(('r:/WORK/Frontend/inner_mbistPl/pipelineDataOutReg_reg[%d]' % b,
                            'i:/WORK/Frontend/inner_mbistPl/u_core/g_node_return.pipelineDataOutReg_reg[%d]' % b))
    return out


def render_child_pins():
    pairs = rebased_child_pins() + semantic_child_pins()
    seen = set()
    for r, i in pairs:
        if r in seen:
            fail('第二节同一个 ref 对象出现两次: %s' % r)
        seen.add(r)
    L = []
    A = L.append
    A('# ---- 二、白盒直接子模块的内部配对（%d 条；规则见生成器第二节；八个 green child 内部不碰）----' % len(pairs))
    A('set ::FE_CHILD_EXPECT %d' % len(pairs))
    A('set ::FE_CHILD_OK 0')
    A('set ::FE_CHILD_BAD 0')
    A('proc fe_child_pin {r i} {')
    A('  if {[set_user_match -type cell $r $i]} { incr ::FE_CHILD_OK } else {')
    A('    incr ::FE_CHILD_BAD')
    A('    if {$::FE_CHILD_BAD <= 10} { puts "FE_CHILD_PIN_FAIL: $r <-> $i" }')
    A('  }')
    A('}')
    A('puts "FE_CHILD_PIN_BEGIN expect=$::FE_CHILD_EXPECT"')
    for r, i in pairs:
        A('fe_child_pin {%s} {%s}' % (r, i))
    A('puts "FE_CHILD_PIN_END ok=$::FE_CHILD_OK bad=$::FE_CHILD_BAD expect=$::FE_CHILD_EXPECT"')
    A('if {$::FE_CHILD_BAD != 0 || $::FE_CHILD_OK != $::FE_CHILD_EXPECT} {')
    A('  error "FE_CHILD_PIN: ok=$::FE_CHILD_OK bad=$::FE_CHILD_BAD expect=$::FE_CHILD_EXPECT"')
    A('}')
    return '\n'.join(L) + '\n'



def splice(text, gen):
    if BEGIN in text:
        i = text.index(BEGIN)
        j = text.index(END, i) + len(END) + 1
        return text[:i] + gen + text[j:]
    return text.rstrip('\n') + '\n\n' + gen


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    text = OUT.read_text()
    outs = [(OUT, text, splice(text, render())),
            (PINS, PINS.read_text() if PINS.exists() else '', render_pins() + render_child_pins())]
    rc = 0
    for path, old, new in outs:
        if a.check:
            if new != old:
                print('DRIFT: %s 与生成器输出不一致' % path.relative_to(REPO))
                rc = 1
            else:
                print('OK: %s' % path.relative_to(REPO))
        elif new != old:
            path.write_text(new)
            print('wrote %s' % path.relative_to(REPO))
        else:
            print('unchanged %s' % path.relative_to(REPO))
    return rc


if __name__ == '__main__':
    sys.exit(main())
