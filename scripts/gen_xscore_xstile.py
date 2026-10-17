#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_xscore_xstile.py —— 生成 rtl/xstile/XSCore.sv 与 rtl/xstile/XSTile.sv（两个顶层装配壳）。

## 为什么整份文件都是生成的

golden XSCore / XSTile **本层没有任何逻辑**（实测：0 个寄存器、0 个 always、XSCore 0 条 assign；
XSTile 只有 2 条把子模块输出直接送到顶层的 assign），子模块之间的连线也全部是"纯连线形状"
（直连 / 位截取 / 高位补零 / 字面常量）。所以这两个文件没有可读核（xs_*_core）——
按 Backend / MemBlock 的分工，纯连线形状一律在 golden 同名 wrapper 里，有运算或寄存器的才进核；
这里一样运算都没有，核会是空壳。先例：rtl/frontend/MbistIntfFrontend.sv（纯连线，无核）。

可读性落在**分组与注释**上：子模块之间的线按"驱动实例 → 读者"分组声明，每个子模块的端口按
"从谁来 / 到哪去"分组接线，每组注明这一组线在流水线里是什么（PEER_DESC，手写），组内再按
总线前缀（如 io_mem_issueLda）列出位宽小计。

## fail-closed 规则

  * 端口表从 G1 golden 现读，逐位同名同序（parent_wrapper_lib.ports，解析不了即失败）；
  * 子模块按 golden 的模块名 / 实例名 / 顺序例化；子模块端口集合必须与该子模块 golden 端口表相等；
  * 每个子模块输入的 golden 表达式必须恰好落进下面一类，否则生成失败：
      - 顶层输入口（可带位选）；
      - 另一个子模块的输出线（可带位选）；
      - 字面常量 N'hX；
      - 高位补零 {N'h0, <顶层输入口>}；
  * 每个子模块输出：接顶层输出口（golden 直连的）/ 接一根本文件的线 / 悬空（golden `/* unused */`）；
    一根 golden 线不许有两个驱动；
  * 每个顶层输出恰好一个驱动者（子模块输出直连，或 golden assign 的纯连线来源）；
  * golden 线位宽必须等于驱动端口位宽；子模块输入位宽必须等于来源表达式位宽（位选 / 补零按算出的宽度比）；
  * PEER_DESC 每一条都必须被用到，每个出现的（来源, 读者）组合都必须有说明（防陈旧 / 防漏写）。

## 用法

    python3 scripts/gen_xscore_xstile.py           # 重生成两个文件
    python3 scripts/gen_xscore_xstile.py --check   # 幂等校验（不写）
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import parent_wrapper_lib as L      # noqa: E402  只 import 它的 golden 解析函数，不改它
import gen_file_nav as NAV          # noqa: E402  导航用同一把尺子

REPO = os.path.dirname(HERE)


def die(msg):
    raise SystemExit('gen_xscore_xstile: ' + msg)


# ---------------------------------------------------------------------------
# 每个目标的手写部分：文件头 + 每组线的语义说明
#   PEER_DESC 的键：(来源, 读者)。来源 / 读者 = 实例名，或 'TOP'（顶层端口）。
# ---------------------------------------------------------------------------
SPECS = {}

SPECS['XSCore'] = dict(
    out='rtl/xstile/XSCore.sv',
    header="""\
// XSCore.sv —— 香山处理器核顶层装配：前端（取指 / 分支预测）+ 后端（译码 / 重命名 / 调度 / 执行 / 提交）+ 访存子系统
// =============================================================================
// 在哪一层：XSTile 之下、三大块之上。Chisel 源 xiangshan/XSCore.scala（XSCoreImp）。
//   golden G1-canonical/golden-rtl/XSCore.sv（13,423 行 / 374 端口 / 3 个子模块实例 / 本层 0 个寄存器）。
//
// 一条指令的视角：
//   Frontend 取指（ICache 经 MemBlock 里的 FrontendBridge 走 TileLink 到 L2）→ 指令包 cfVec 送 Backend；
//   Backend 译码 / 重命名 / 派遣 / 发射，算术类在自己的执行块里做完，访存类经 io_mem_issue* 发给 MemBlock；
//   MemBlock 执行 load / store 后把写回、唤醒、发射反馈送回 Backend；Backend 提交时经 toFtq 告诉 Frontend
//   哪些预测对了、哪里要重定向。
//
// MemBlock 是本核与外界的"门户"：
//   L1D / ICache / PTW 三路 TileLink、CLINT / PLIC / debug / NMI 中断、BEU 错误上报、hartId、复位向量、
//   L2 的预取提示与 TopDown 信息，都从 MemBlock 的端口进出本核；需要的东西由 MemBlock 转发给另两块
//   （例：hartId / 复位向量转给 Frontend，中断 / MSI / CLINT 时间转给 Backend 的 CSR，
//   trace 接口从 Backend 经 MemBlock 转给 L2Top）。所以本文件里 memBlock 的连线最多。
//
// 本文件的分工：只有 golden 同名 wrapper XSCore（scripts/gen_xscore_xstile.py 从 golden 例化表机械生成）。
//   本层没有任何逻辑（0 个寄存器、0 条运算），子模块之间全是直连，因此没有可读核 xs_XSCore_core。
//   * 子模块之间的线按"驱动实例"分组声明，命名 <驱动实例>_<端口>（golden 的 _<实例>_<端口> 去掉前导下划线）；
//   * 每个子模块的接线按"从谁来 / 到哪去"分组，每组一句话说明这组线是什么，组内按总线前缀列出位宽；
//   * 三个子模块的 gatewayIn_packed_* 是 difftest 网关（仿真比对用的提交 / 写回 / 访存快照），直通顶层输出。
//
// 边界与怪癖（golden 实测）：
//   * 7 根写回包的 debugInfo_runahead_checkpoint_id 只是 MemBlock 写回到 Backend 的普通字段，golden 照接，这里也照接。
//   * 子模块输出没有悬空的，也没有一根线扇出给两个读者（每根线恰好一个读者）。
""",
)

SPECS['XSCore']['peer'] = {
    ('TOP', 'frontend'): '时钟 / 复位',
    ('TOP', 'backend'): '时钟 / 复位；TopDown 调试：L2 / L3 的 missMatch（性能分析用，从核外来）',
    ('TOP', 'memBlock'): '核与外界的全部输入：L1D / ICache 桥 / PTW 三路 TileLink 的回包与反压、CLINT / PLIC / debug / NMI / BEU 中断、'
                         'hartId、复位向量、L2 预取提示 / TLB 共享口 / 刷新完成、MSI 与 CLINT 时间、L2 的性能事件（hc）、trace 编码器回压、DFT 控制',
    ('frontend', 'backend'): '取指 → 后端：指令包 cfVec（译码入口，每拍至多 8 条）、FTQ 给后端的 pc / 预测信息（fromFtq）、'
                             'IFU 信息（fromIfu）、取指停顿原因、wfi 安全应答、前端性能事件',
    ('frontend', 'memBlock'): '取指 → MemBlock：ICache 与指令 uncache 的 TileLink 请求（经 FrontendBridge 出核）、ITLB 缺失的 PTW 请求、'
                              '前端 ECC 错误（交 BEU 上报）、resetInFrontend（转给 L2Top）',
    ('frontend', 'TOP'): 'difftest 网关（gatewayIn_packed_*，前端的取指快照）',
    ('backend', 'frontend'): '后端 → 取指：toFtq（重定向 / 提交 / 预测器更新）、cfVec 的 ready 与 canAccept 反压、'
                             'CSR 控制（frontendCsrCtrl：分支预测开关、预取、分布式 CSR 写）、sfence、ITLB 用的地址翻译 CSR（satp / vsatp / hgatp / priv / pmm）、fence.i、wfi 请求',
    ('backend', 'memBlock'): '后端 → MemBlock：四类发射（issueLda / Sta / Std / Vldu）、LSQ 入队（lsqEnqIO）、ROB 给 LSQ 的提交信息（robLsqIO）、'
                             '重定向、DTLB 的地址翻译 CSR、访存相关 CSR 控制、sfence、wfi 请求、ROB 头虚地址（TopDown）、trace 接口（经 MemBlock 转给 L2Top）',
    ('backend', 'TOP'): 'difftest 网关（gatewayIn_packed_*，提交 / 寄存器堆 / CSR 快照）与 TopDown 的 ROB 头信息',
    ('memBlock', 'frontend'): 'MemBlock → 取指：ICache 与指令 uncache 的 TileLink 回包与反压（经 FrontendBridge）、ITLB 的 PTW 回应、'
                              '软件预取（cbo.prefetch.i 转成 ICache 预取）、hartId 与复位向量（从核外经 MemBlock 转来）、DFT 控制',
    ('memBlock', 'backend'): 'MemBlock → 后端：写回（load / sta / std / 向量）与唤醒、发射反馈（各 IqFeedback）与 load 取消、违例回滚、'
                             '例外地址、LQ / SQ 指针与容量、TopDown 与性能事件；以及核外输入的转发（hartId、外部中断、MSI、CLINT 时间、L2 刷新完成、trace 编码器回压、DFT）',
    ('memBlock', 'TOP'): '核与外界的全部输出：三路 TileLink 的请求、L1D / uncache 的 ECC 错误、BEU 错误、L2 TLB / PMP 共享口、L2 预取控制、'
                         'wfi / 停机 / 关键错误、MSI 应答、trace 接口（转给 L2Top）、difftest 网关（访存快照）',
}

SPECS['XSTile'] = dict(
    out='rtl/xstile/XSTile.sv',
    header="""\
// XSTile.sv —— 香山 tile 顶层装配：一个处理器核（XSCore）+ 它私有的 L2 子系统（L2Top）+ 4 个中断同步缓冲（IntBuffer）
// =============================================================================
// 在哪一层：SoC（XSTop）之下、XSCore 之上。Chisel 源 xiangshan/XSTile.scala。
//   golden G1-canonical/golden-rtl/XSTile.sv（2,077 行 / 150 端口 / 6 个子模块实例 / 本层 0 个寄存器）。
//
// 数据怎么走：
//   * 核的三路 TileLink（L1D / ICache 桥 / PTW）全部进 L2Top；L2Top 里是 L2 cache 与 TileLink→CHI 桥，
//     对 SoC 的出口是 CHI（io_chi_*）与 MMIO（auto_mmio_*）；
//   * 中断：核外来的 CLINT（msip / mtip）、debug、PLIC（meip / seip）、NMI 先进 L2Top 的中断节点，
//     再各过一个 IntBuffer（一拍异步复位同步寄存器）才到核里 MemBlock 的中断端口；
//   * hartId / 复位向量 / MSI / CLINT 时间也经 L2Top 转给核；核的 BEU 错误、L2 TLB / PMP 共享口、L2 预取控制、
//     trace 接口、停机 / 关键错误等经 L2Top 送出 tile。
//
// 本文件的分工：只有 golden 同名 wrapper XSTile（scripts/gen_xscore_xstile.py 从 golden 例化表机械生成）。
//   本层没有任何逻辑（0 个寄存器），只有纯连线形状，因此没有可读核 xs_XSTile_core：
//   * hartId：顶层 6 位 io_hartId 高位补零成 64 位交给 L2Top（{58'h0, io_hartId}），L2Top 转回来的 64 位只取低 6 位给核；
//   * 核的 io_debugTopDown_robHeadPaddr（48 位）给 L2Top 时只取低 36 位，同时整宽直通 tile 输出；
//   * 核的 L2 刷新完成输入恒 0，核的 L2 刷新请求 / 掉电请求两个输出悬空（本配置不接）。
//   子模块之间的线命名 <驱动实例>_<端口>；接线按"从谁来 / 到哪去"分组并说明。
//
// 4 个 IntBuffer（实例名 golden 原样）：intBuffer（IntBuffer_1，CLINT 两根 msip / mtip）、intBuffer_1（IntBuffer_2，
//   PLIC 两根 meip / seip，端口按 _1_0 / _0_0 编号）、intBuffer_2（IntBuffer，debug 一根）、intBuffer_3（IntBuffer_1，NMI 两根）。
""",
)
SPECS['XSTile']['peer'] = {
    ('TOP', 'core'): '时钟 / 复位、DFT 控制、TopDown 的 L3 missMatch',
    ('TOP', 'l2top'): 'tile 的全部外部输入：CHI 回包与链路控制、MMIO 回包、CLINT / debug / PLIC / NMI 中断源、复位向量、MSI、CLINT 时间、'
                      'trace 编码器回压、DFT 与时钟门控控制',
    ('TOP', 'intBuffer'): '时钟 / 复位',
    ('TOP', 'intBuffer_1'): '时钟 / 复位',
    ('TOP', 'intBuffer_2'): '时钟 / 复位',
    ('TOP', 'intBuffer_3'): '时钟 / 复位',
    ('CONST', 'core'): 'L2 刷新完成恒 0（本配置不做 L2 刷新）',
    ('CONST', 'l2top'): '高位补零：顶层 6 位 hartId 补成 64 位',
    ('core', 'l2top'): '核 → L2Top：三路 TileLink 请求（L1D / ICache 桥 / PTW）、BEU 错误、L2 TLB / PMP 共享口请求、L2 预取控制、'
                       'trace 接口、resetInFrontend、停机 / 关键错误 / MSI 应答、ROB 头物理地址（TopDown，取低 36 位）',
    ('core', 'TOP'): 'difftest 网关（gatewayIn_packed_*）与 TopDown 的 ROB 头物理地址（整宽直通）',
    ('l2top', 'core'): 'L2Top → 核：三路 TileLink 回包与反压、hartId（取低 6 位）、复位向量、MSI、CLINT 时间、L2 预取提示、'
                       'L2 TLB 共享口回应、TopDown 的 L2 missMatch、L2 性能事件',
    ('l2top', 'intBuffer'): 'CLINT 中断（msip / mtip）进同步缓冲',
    ('l2top', 'intBuffer_1'): 'PLIC 中断（meip / seip）进同步缓冲',
    ('l2top', 'intBuffer_2'): 'debug 中断进同步缓冲',
    ('l2top', 'intBuffer_3'): 'NMI 中断（nmi_31 / nmi_43）进同步缓冲',
    ('l2top', 'TOP'): 'tile 的全部外部输出：CHI 请求与链路控制、MMIO 请求、trace 接口、停机 / 关键错误 / MSI 应答、复位链',
    ('intBuffer', 'core'): '同步后的 CLINT 中断进核（MemBlock 的 clint 端口）',
    ('intBuffer_1', 'core'): '同步后的 PLIC 中断进核（MemBlock 的 plic 端口）',
    ('intBuffer_2', 'core'): '同步后的 debug 中断进核',
    ('intBuffer_3', 'core'): '同步后的 NMI 进核',
    ('core', 'UNUSED'): 'L2 刷新请求 / 掉电请求（本配置不接）',
}

INST_DESC = {
    ('XSCore', 'frontend'): 'Frontend：BPU 预测 → FTQ → IFU 取指 → IBuffer，ICache / ITLB 在里面',
    ('XSCore', 'backend'): 'Backend：CtrlBlock（译码 / 重命名 / 派遣 / ROB）、四个调度器、DataPath、执行块、写回、CSR',
    ('XSCore', 'memBlock'): 'MemBlock：load / store 流水、LSQ、Sbuffer、L1 DCache、DTLB / L2TLB、PMP、预取、向量访存；本核与外界的门户',
    ('XSTile', 'core'): 'XSCore：处理器核',
    ('XSTile', 'l2top'): 'L2Top：L2 cache、TileLink → CHI 桥、MMIO 桥、中断节点、BEU',
    ('XSTile', 'intBuffer'): 'IntBuffer_1：CLINT 中断同步（2 根）',
    ('XSTile', 'intBuffer_1'): 'IntBuffer_2：PLIC 中断同步（2 根）',
    ('XSTile', 'intBuffer_2'): 'IntBuffer：debug 中断同步（1 根）',
    ('XSTile', 'intBuffer_3'): 'IntBuffer_1：NMI 同步（2 根）',
}

SIMPLE = re.compile(r"(\w+)(?:\[(\d+)(?::(\d+))?\])?$")
CONST = re.compile(r"(\d+)'h[0-9A-Fa-f]+$")
ZEXT = re.compile(r"\{(\d+)'h0, (\w+)\}$")


def bundle(p):
    """总线前缀：端口名前三段，数字段记作 N（io_mem_issueLda_0_bits_x -> io_mem_issueLda）"""
    return '_'.join(('N' if t.isdigit() else t) for t in p.split('_')[:3])


def rng(w):
    return '' if w == 1 else '[%d:0] ' % (w - 1)


def build(TOP):
    S = SPECS[TOP]
    P = L.ports(TOP)
    pdir = {n: d for d, w, n in P}
    pw = {n: w for d, w, n in P}
    I = L.golden_instances(TOP)
    A_ = L.golden_assigns(TOP)
    gtext = L.golden_text(TOP)
    gbody = gtext[gtext.index('\nmodule %s(' % TOP):]
    gwire_w = {}
    for m in re.finditer(r'^  wire\s+(?:\[(\d+):0\]\s+)?(\w+);', gbody, re.M):
        gwire_w[m.group(2)] = 1 if m.group(1) is None else int(m.group(1)) + 1
    for m in re.finditer(r'^  wire\s+(?:\[(\d+):0\]\s*)?\n\s+(\w+);', gbody, re.M):
        gwire_w[m.group(2)] = 1 if m.group(1) is None else int(m.group(1)) + 1
    if re.search(r'^\s*(reg|always)\b', gbody, re.M):
        die('%s: golden 本层出现了寄存器 / always —— 本生成器只处理纯连线壳' % TOP)

    cports = {}
    for mod, inst, cm in I:
        pd = {n: (d, w) for d, w, n in L.ports(mod)}
        if set(cm) != set(pd):
            die('%s.%s 端口集合与 golden %s 不同' % (TOP, inst, mod))
        cports[inst] = (mod, L.ports(mod), cm)

    # golden 线 -> 驱动 (inst, port, w)；直连顶层输出的 (inst, port) -> 顶层口
    gdrv, out_top = {}, {}
    for inst, (mod, pl, cm) in cports.items():
        for d, w, p in pl:
            e = cm[p]
            if d != 'output' or e in ('', '/* unused */'):
                continue
            if not re.fullmatch(r'\w+', e):
                die('%s.%s 输出接了表达式 %s' % (inst, p, e))
            if e in gdrv:
                die('golden 线 %s 有两个驱动' % e)
            gdrv[e] = (inst, p, w)
            if e in pdir:
                if pdir[e] != 'output':
                    die('%s.%s 接到顶层输入 %s' % (inst, p, e))
                if pw[e] != w:
                    die('%s.%s 位宽 %d 与顶层口 %s 位宽 %d 不同' % (inst, p, w, e, pw[e]))
                out_top[(inst, p)] = e
            else:
                if gwire_w.get(e) != w:
                    die('golden 线 %s 位宽 %s 与驱动端口 %s.%s 位宽 %d 不同' % (e, gwire_w.get(e), inst, p, w))

    def netname(inst, p):
        return '%s_%s' % (inst, p)

    # 每个子模块输入：来源分类 -> (来源记号, wrapper 表达式)
    def resolve(e, want_w, where):
        m = CONST.match(e)
        if m:
            if int(m.group(1)) != want_w:
                die('%s: 常量 %s 位宽与端口 %d 不同' % (where, e, want_w))
            return 'CONST', e
        m = ZEXT.match(e)
        if m:
            z, b = int(m.group(1)), m.group(2)
            if pdir.get(b) != 'input' or z + pw[b] != want_w:
                die('%s: 补零 %s 不是"顶层输入补到端口宽"' % (where, e))
            return 'CONST', e
        m = SIMPLE.match(e)
        if not m:
            die('%s: golden 来源 "%s" 不是纯连线形状' % (where, e[:80]))
        base, hi, lo = m.group(1), m.group(2), m.group(3)
        if hi is None:
            sw = None
        else:
            sw = 1 if lo is None else int(hi) - int(lo) + 1
        if base in pdir:
            if pdir[base] != 'input':
                die('%s: 来源 %s 是顶层输出' % (where, base))
            src, full_w, expr = 'TOP', pw[base], base
        elif base in gdrv:
            si, sp, full_w = gdrv[base]
            src = si
            expr = out_top.get((si, sp)) or netname(si, sp)
        else:
            die('%s: 来源 %s 既不是顶层输入也不是子模块输出' % (where, base))
        w = full_w if sw is None else sw
        if w != want_w:
            die('%s: 来源 %s 位宽 %d 与端口位宽 %d 不同' % (where, e, w, want_w))
        if hi is not None:
            expr += '[%s]' % (hi if lo is None else '%s:%s' % (hi, lo))
        return src, expr

    readers = {}          # golden 线 -> [读者实例 / 'TOP']
    conns = {}            # inst -> [(组键, 端口, 表达式, 位宽)]
    for inst, (mod, pl, cm) in cports.items():
        rows = []
        for d, w, p in pl:
            e = cm[p]
            where = '%s.%s.%s' % (TOP, inst, p)
            if d == 'input':
                src, expr = resolve(e, w, where)
                if src not in ('TOP', 'CONST'):
                    base = SIMPLE.match(e).group(1)
                    readers.setdefault(base, []).append(inst)
                rows.append(((src, inst), p, expr, w))
            else:
                if e in ('', '/* unused */'):
                    rows.append(((inst, 'UNUSED'), p, '', w))
                elif (inst, p) in out_top:
                    rows.append(((inst, 'TOP'), p, out_top[(inst, p)], w))
                else:
                    rows.append((None, p, netname(inst, p), w))   # 读者稍后填
        conns[inst] = rows

    # 顶层输出：子模块直连或 golden assign 的纯连线来源
    top_assign = []
    driven = set(out_top.values())
    for d, w, n in P:
        if d != 'output' or n in driven:
            continue
        e = A_.get(n)
        if e is None:
            die('%s: 顶层输出 %s 无驱动' % (TOP, n))
        src, expr = resolve(e, w, '%s.assign %s' % (TOP, n))
        if src in ('TOP', 'CONST'):
            die('%s: 顶层输出 %s 由 %s 驱动——不是子模块输出' % (TOP, n, e))
        readers.setdefault(SIMPLE.match(e).group(1), []).append('TOP')
        top_assign.append((src, n, expr, w))
        driven.add(n)
    if driven != {n for d, w, n in P if d == 'output'}:
        die('%s: 顶层输出未全覆盖' % TOP)
    extra_assign = set(A_) - {n for _, n, _, _ in top_assign}
    if extra_assign:
        die('%s: golden 有没处理的 assign %s' % (TOP, sorted(extra_assign)[:5]))

    # 子模块输出线的读者组
    for inst, rows in conns.items():
        new = []
        for k, p, expr, w in rows:
            if k is None:
                gname = cports[inst][2][p]
                rd = readers.get(gname)
                if not rd:
                    die('%s: 线 %s 没有读者' % (TOP, gname))
                k = (inst, '+'.join(sorted(set(rd), key=lambda r: list(cports).index(r) if r in cports else 99)))
            new.append((k, p, expr, w))
        conns[inst] = new

    used_desc = set()

    def desc(src, dst):
        parts = dst.split('+')
        texts = []
        for d in parts:
            key = (src, d)
            if key not in S['peer']:
                die('%s: (来源 %s, 读者 %s) 没有 PEER_DESC 说明' % (TOP, src, d))
            used_desc.add(key)
            texts.append(S['peer'][key])
        return '；'.join(texts)

    def who(x):
        return {'TOP': '顶层', 'CONST': '常量', 'UNUSED': '悬空'}.get(x, x)

    out = []
    A = out.append
    A('// BEGIN GENERATED(%s_wrapper) —— 由 scripts/gen_xscore_xstile.py 从 golden 端口表与例化表产出，勿手改' % TOP.lower())
    A('// golden 同名 wrapper：端口与 golden 逐位同名同序；子模块模块名 / 实例名 / 顺序与 golden 一致；')
    A('// 子模块之间的线命名为 <驱动实例>_<端口>。')
    A('module %s (' % TOP)
    A(',\n'.join('  %-6s logic %s%s' % (d, rng(w), n) for d, w, n in P))
    A(');')
    A('')

    # ---- 线声明（按驱动实例，再按读者分组）----
    for inst, rows in conns.items():
        nets = [(k, p, expr, w) for k, p, expr, w in rows
                if k[0] == inst and k[1] not in ('TOP', 'UNUSED')]
        if not nets:
            continue
        A('  // ' + '=' * 75)
        A('  // %s 的输出线（%d 根，%d 位）' % (inst, len(nets), sum(r[3] for r in nets)))
        A('  // ' + '=' * 75)
        A('')
        groups = []
        for r in nets:
            if not groups or groups[-1][0] != r[0]:
                if any(g[0] == r[0] for g in groups):
                    g = [g for g in groups if g[0] == r[0]][0]
                    g[1].append(r)
                    continue
                groups.append((r[0], [r]))
            else:
                groups[-1][1].append(r)
        for k, rs in groups:
            A('  // ---- %s → %s（%d 根）----' % (inst, ' / '.join(who(x) for x in k[1].split('+')), len(rs)))
            for _, p, expr, w in rs:
                A('  logic %s%s;' % (rng(w), expr))
        A('')

    # ---- 子模块例化 ----
    for inst, rows in conns.items():
        mod = cports[inst][0]
        A('  // ' + '=' * 75)
        A('  // 子模块 %s %s（%s）' % (mod, inst, INST_DESC[(TOP, inst)]))
        A('  //   %d 个端口：输入 %d / 输出 %d' % (len(rows), sum(1 for r in rows if r[0][1] == inst),
                                            sum(1 for r in rows if r[0][1] != inst)))
        A('  // ' + '=' * 75)
        # 组顺序 = 在 golden 端口表里第一次出现的顺序；clock / reset 单列在最前
        order, gmap = [], {}
        for r in rows:
            if r[1] in ('clock', 'reset'):
                continue
            if r[0] not in gmap:
                gmap[r[0]] = []
                order.append(r[0])
            gmap[r[0]].append(r)
        cl = []
        ck = [r for r in rows if r[1] in ('clock', 'reset')]
        if ck:
            # 时钟 / 复位单列在最前；只有它俩来自顶层时，顶层那条说明就是"时钟 / 复位"
            if not any(r[0] == ('TOP', inst) for r in rows if r[1] not in ('clock', 'reset')):
                cl.append((None, '    // ← 顶层：%s' % desc('TOP', inst)))
            for r in ck:
                cl.append(('    .%s (%s)' % (r[1], r[2]), None))
        for k in order:
            src, dst = k
            if dst == inst:
                head = '← %s：%s' % (who(src), desc(src, inst))
            else:
                head = '→ %s：%s' % (' / '.join(who(x) for x in dst.split('+')), desc(inst, dst))
            cl.append((None, '    // ' + head))
            last = None
            for _, p, expr, w in gmap[k]:
                b = bundle(p)
                if b != last:
                    rs = [x for x in gmap[k] if bundle(x[1]) == b]
                    cl.append((None, '    //   %s*（%d 根，%d 位）' % (b, len(rs), sum(x[3] for x in rs))))
                    last = b
                cl.append(('    .%s (%s)' % (p, expr), None))
        # 逗号只加在端口行之间（注释行不算）
        port_idx = [i for i, (c, _) in enumerate(cl) if c is not None]
        A('  %s %s (' % (mod, inst))
        for i, (c, cm_) in enumerate(cl):
            if c is None:
                A(cm_)
            else:
                A(c + (',' if i != port_idx[-1] else ''))
        A('  );')
        A('')

    if top_assign:
        A('  // ' + '=' * 75)
        A('  // 顶层输出：子模块输出线直通（这几根同时还有子模块读者，所以经线转一手）')
        A('  // ' + '=' * 75)
        for src, n, expr, w in top_assign:
            used_desc.add((src, 'TOP'))
            A('  assign %s = %s;' % (n, expr))
        A('')
    A('endmodule')
    A('// END GENERATED')

    stale = set(S['peer']) - used_desc
    if stale:
        die('%s: PEER_DESC 有没用到的条目 %s' % (TOP, sorted(stale)))

    lines = '\n'.join(S['header'].rstrip('\n').split('\n') + [''] + out).split('\n')
    # 导航：与 scripts/gen_file_nav.py 同一算法（插在文件头之后，行号统一右移导航块长度）
    if len(lines) + 1 > 1500:
        k = NAV.header_end(lines)
        secs = [(ln, t) for ln, t in NAV.sections(lines) if not t.startswith(('对应 ', '角色：')) and ln > 3]
        shift = len(secs) + 2
        nav = NAV.build(lines, shift)
        if len(nav) != shift:
            die('导航长度不符')
        lines = lines[:k] + nav + lines[k:]
    return S['out'], '\n'.join(lines) + '\n'


def main(argv):
    check = '--check' in argv
    rc = 0
    for TOP in ('XSCore', 'XSTile'):
        rel, text = build(TOP)
        path = os.path.join(REPO, rel)
        cur = open(path).read() if os.path.exists(path) else None
        if check:
            ok = cur == text
            print(('OK: ' if ok else 'DRIFT: ') + rel)
            rc |= 0 if ok else 1
        else:
            os.makedirs(os.path.dirname(path), exist_ok=True)
            if cur != text:
                open(path, 'w').write(text)
            print('wrote %s（%d 行）' % (rel, text.count('\n')))
    return rc


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
