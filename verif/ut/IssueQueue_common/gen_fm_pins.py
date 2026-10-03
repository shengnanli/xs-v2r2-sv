#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_fm_pins.py —— IssueQueue<V> 的 FM「匹配前」钉点：复用已签核 Entries<V> 的钉点表，加实例前缀

为什么需要：IQ 父级 FM 把条目阵列两侧白盒（ref = golden Entries<V> 及其 EnqEntry/OthersEntry
子树，impl = 本仓重写 Entries<V>，u_core 里是扁平的数组寄存器）。两侧寄存器命名体系完全不同
（golden 逐条目逐字段平铺，重写按字段数组存），不钉的话 matching 要靠签名硬扛 ~2.5 万个点。
单签 Entries<V> 时已经有一张逐位、一一对应、fail-closed 的钉点表
（verif/ut/Entries<V>/fm_pins_pre.tcl，由 Entries_common/gen_fm_pins.py 从字段偏移表机械生成）。
这里**原样复用它的配对列表**，只把两侧路径各加上条目阵列在 IQ 里的实例名：
    r:/WORK/$top/<inst>/<golden 寄存器>   <->   i:/WORK/$top/<inst>/u_core/<重写寄存器>
钉点只消名差，不约束 ref、不 dont_verify、不黑盒。计数守卫照搬（用 set_user_match 返回值数，
失败一条或总数不等于字面期望值都 error）。

用法: python3 gen_fm_pins.py <IssueQueueV> [--check]
"""
import argparse
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
UT = HERE.parent


def gen(v):
    ev = 'Entries' + v[len('IssueQueue'):]
    src = (UT / ev / 'fm_pins_pre.tcl').read_text()
    m = re.search(r'foreach _pair \{\n(.*?)\n  \} \{', src, re.S)
    if not m:
        raise SystemExit(f'{ev}: 找不到钉点列表')
    pairs = [l for l in m.group(1).splitlines() if l.strip()]
    for l in pairs:
        if not re.fullmatch(r'    \{\S+ \S+\}', l):
            raise SystemExit(f'{ev}: 钉点行格式异常 {l!r}')
    exp = int(re.search(r'expect=(\d+)"', src).group(1))
    if exp != len(pairs):
        raise SystemExit(f'{ev}: 期望数 {exp} != 列表行数 {len(pairs)}')
    # golden IQ 里条目阵列的实例名
    gsrc = pathlib.Path(f'/home/eda/xs-env/G1-canonical/golden-rtl/{v}.sv').read_text()
    inst = re.findall(r'^  %s (\w+) \($' % ev, gsrc, re.M)
    if len(inst) != 1:
        raise SystemExit(f'{v}: {ev} 实例数 != 1')
    inst = inst[0]
    # IQ 自身层：validCntDeqVec 打拍寄存器比端口宽的那几位（端口只取低位）两侧都无人读，
    # 名字不同（golden io_validCntDeqVec_<d>_REG[_k]，重写 g_vcnt[<d>].g_on.vcnt_q），
    # FM 配不上就成了 unmatched unread。逐位钉上。
    outw = {}
    for m in re.finditer(r'output\s+\[(\d+):0\]\s+io_validCntDeqVec_(\d+)', gsrc):
        outw[int(m.group(2))] = int(m.group(1)) + 1
    iq_pairs = []
    for m in re.finditer(r'^\s+reg\s+\[(\d+):0\]\s+(io_validCntDeqVec_(\d+)_REG(?:_\d+)?);', gsrc, re.M):
        w, name, d = int(m.group(1)) + 1, m.group(2), int(m.group(3))
        for b in range(outw[d], w):
            iq_pairs.append(f'    {{{name}_reg[{b}] u_core/g_vcnt[{d}].g_on.vcnt_q_reg[{b}]}}')
    # 条目状态寄存器（srcStatus 的 psrc/srcType/srcState/dataSources、robIdx、issued/firstIssue/issueTimer）：
    # 单签 Entries 时靠签名就配上了，没进钉点表；IQ 父级里入队翻译把部分 dataSources 位变成常量
    # （如向量源 3/4 的 dataSources 只可能是 imm/reg，bit1 恒 0），签名失效 -> unmatched + 连带 failing
    # （VfdivVidiv 诊断跑实测 23(23) unmatched / 99 failing）。按 golden 条目实例逐字段钉上。
    have_ent = {(r, i) for r, i in (re.findall(r'\{(\S+) (\S+)\}', src))}
    ep_src = pathlib.Path(f'/home/eda/xs-env/G1-canonical/golden-rtl/{ev}.sv').read_text()
    ent_insts = re.findall(r'^  ((?:EnqEntry|OthersEntry)\w*) (\w+) \($', ep_src, re.M)
    nenq = sum(1 for _, n in ent_insts if n.startswith('enqEntries_'))
    nsimp = sum(1 for _, n in ent_insts if n.startswith('othersEntriesSimp_'))
    for emod, en in ent_insts:
        k = int(en.rsplit('_', 1)[1])
        idx = k if en.startswith('enqEntries_') else (nenq + k if 'Simp' in en else nenq + nsimp + k)
        er = {m.group(2): int(m.group(1)) + 1 if m.group(1) else 1 for m in re.finditer(
            r'^\s+reg\s+(?:\[(\d+):0\]\s+)?(\w+);',
            pathlib.Path(f'/home/eda/xs-env/G1-canonical/golden-rtl/{emod}.sv').read_text(), re.M)}
        def add(gname, ifmt):
            if gname not in er:
                return
            w = er[gname]
            for b in range(w):
                g_r = f'{en}/{gname}_reg[{b}]' if w > 1 else f'{en}/{gname}_reg'
                i_r = f'g_entry[{idx}].u_e/' + (ifmt.format(b) if w > 1 else ifmt.replace('[{}]', ''))
                if (g_r, i_r) not in have_ent:
                    iq_pairs.append(f'    {{{inst}/{g_r} {inst}/u_core/{i_r}}}')
        for sidx in range(5):
            add(f'entryReg_status_srcStatus_{sidx}_psrc', f'r_psrc_reg[{sidx}][{{}}]')
            add(f'entryReg_status_srcStatus_{sidx}_srcType', f'r_src_type_reg[{sidx}][{{}}]')
            add(f'entryReg_status_srcStatus_{sidx}_srcState', f'r_src_state_reg[{sidx}]')
            add(f'entryReg_status_srcStatus_{sidx}_dataSources_value', f'r_data_src_reg[{sidx}][{{}}]')
        add('entryReg_status_robIdx_flag', 'r_rob_flag_reg')
        add('entryReg_status_robIdx_value', 'r_rob_value_reg[{}]')
        add('entryReg_status_issued', 'r_issued_reg')
        add('entryReg_status_firstIssue', 'r_first_issue_reg')
        add('entryReg_status_issueTimer', 'r_issue_timer_reg[{}]')
    # 忙表写模块（FuBusyTableWrite*）：golden 寄存器 fuBusyTable[W-1:0]，重写 u_core/fu_busy_table_q。
    # 最低位在 IQ 父级里两侧都无人读（FuBusyTableRead 只看 [W-1:1]），名字不同就成了 unmatched unread
    # （FaluFmac 诊断跑实测 1(1)）。整张表逐位钉上（钉点只消名差）。
    for mod, bi in re.findall(r'^  (FuBusyTableWrite\w*) (\w+) \($', gsrc, re.M):
        mt = pathlib.Path(f'/home/eda/xs-env/G1-canonical/golden-rtl/{mod}.sv').read_text()
        w = int(re.search(r'^\s+reg\s+\[(\d+):0\]\s+fuBusyTable;', mt, re.M).group(1)) + 1
        for b in range(w):
            iq_pairs.append(f'    {{{bi}/fuBusyTable_reg[{b}] {bi}/u_core/fu_busy_table_q_reg[{b}]}}')
    # 推测唤醒队列（MultiWakeupQueue*）及其流水（PipeWithFlush*）：golden 逐字段寄存器
    # （lastConnect_bits_<f> / bits_<s>_<f>）↔ 重写核的扁平载荷寄存器（last_bits / g_pipe.bits_q[s]）。
    # IQ 父级里 fuType 只有少数位被读（lat / is0Lat 查表），其余位两侧都无人读，名字不同就成了
    # unmatched unread（FaluFcvtF2vFmacFdiv 诊断跑实测 224(224)）。按载荷布局逐位钉上。
    G = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
    R = UT.parents[1] / 'rtl'
    def gregs(mod):
        t = (G / f'{mod}.sv').read_text()
        return {m.group(2): int(m.group(1)) + 1 if m.group(1) else 1
                for m in re.finditer(r'^\s+reg\s+(?:\[(\d+):0\]\s+)?(\w+);', t, re.M)}
    def gport_w(mod):
        t = (G / f'{mod}.sv').read_text()
        return {m.group(2): int(m.group(1)) + 1 if m.group(1) else 1
                for m in re.finditer(r'^\s*(?:input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?\s*$', t, re.M)}
    def pin_field(pairs, gpath, ipath_fmt, gname, width, off, have):
        if gname not in have:
            return
        if have[gname] != width:
            raise SystemExit(f'{gname}: golden 位宽 {have[gname]} != 布局位宽 {width}')
        for b in range(width):
            gr = f'{gpath}{gname}_reg[{b}]' if width > 1 else f'{gpath}{gname}_reg'
            pairs.append(f'    {{{gr} {ipath_fmt.format(off + b)}}}')
    MWQ_LAYOUT = {   # 与 rtl/backend/MultiWakeupQueue*.sv 的 pipe_bits 拼包顺序一致（高位在前）
        'MultiWakeupQueue':   [('fuType', 35), ('pdest', 8), ('rfWen', 1), ('loadDependency_2', 2),
                               ('loadDependency_1', 2), ('loadDependency_0', 2)],
        'MultiWakeupQueue_2': [('pdest', 8), ('rfWen', 1), ('loadDependency_2', 2), ('loadDependency_1', 2),
                               ('loadDependency_0', 2)],
        'MultiWakeupQueue_4': [('fuType', 35), ('pdest', 8), ('fpWen', 1), ('vecWen', 1), ('v0Wen', 1)],
        'MultiWakeupQueue_5': [('pdest', 8), ('fpWen', 1)],
    }
    for mmod, mi in re.findall(r'^  (MultiWakeupQueue\w*) (\w+) \($', gsrc, re.M):
        have = gregs(mmod)
        off = sum(w for _, w in MWQ_LAYOUT[mmod])
        for f, w in MWQ_LAYOUT[mmod]:
            off -= w
            pin_field(iq_pairs, f'{mi}/', f'{mi}/u_core/last_bits_reg[{{}}]', f'lastConnect_bits_{f}', w, off, have)
        mt = (G / f'{mmod}.sv').read_text()
        for pmod, pi in re.findall(r'^  (PipeWithFlush\w*) (\w+) \($', mt, re.M):
            pw = gport_w(pmod)
            rt = (R / 'common' / f'{pmod}.sv').read_text()
            cat = re.search(r'assign payload_in =\s*\{(.*?)\};', rt, re.S).group(1)
            fields = [x.strip()[len('io_enq_bits_'):] for x in cat.split(',')]
            have_p = gregs(pmod)
            stages = max([int(m) for m in re.findall(r'bits_(\d+)_', ' '.join(have_p))] or [0])
            tot = sum(pw['io_enq_bits_' + f] for f in fields)
            for st in range(1, stages + 1):
                off = tot
                for f in fields:
                    w = pw['io_enq_bits_' + f]
                    off -= w
                    pin_field(iq_pairs, f'{mi}/{pi}/', f'{mi}/{pi}/u_core/g_pipe.bits_q_reg[{st}][{{}}]',
                              f'bits_{st}_{f}', w, off, have_p)
    out = f'''# {v} FM 匹配前钉点 —— 复用已签核 {ev} 的钉点表，两侧路径加实例前缀 "{inst}/"
# ============================================================================
# ★自动生成：verif/ut/IssueQueue_common/gen_fm_pins.py —— 勿手改★
# 配对来源：verif/ut/{ev}/fm_pins_pre.tcl（逐字复制其配对列表，{exp} 对）
#          + IQ 自身层 validCntDeqVec 打拍寄存器的无人读高位、忙表写模块的表寄存器、
#            推测唤醒队列及其流水的载荷寄存器，共 {len(iq_pairs)} 对。
# 计数守卫：用 set_user_match 的**返回值**数（它从不抛异常），失败一条或总数 != {exp + len(iq_pairs)} 都 error
# （用 error 不用 exit：sidecar 模式下本文件在 safe interp 里执行，exit 被隐藏）。
# ============================================================================

if {{$top eq "{v}"}} {{
  set _n 0
  set _miss 0
  puts "IQE_PIN_BEGIN {v} expect={exp + len(iq_pairs)}"
  foreach _pair {{
{chr(10).join(pairs)}
  }} {{
    lassign $_pair _r _i
    if {{[set_user_match "r:/WORK/$top/{inst}/$_r" "i:/WORK/$top/{inst}/u_core/$_i"]}} {{
      incr _n
    }} else {{
      incr _miss
      if {{$_miss <= 10}} {{ puts "IQE_PIN_FAIL: $_r <-> $_i" }}
    }}
  }}
  # IQ 自身层、忙表写模块、推测唤醒队列的钉点（不在条目阵列实例下）
  foreach _pair {{
{chr(10).join(iq_pairs)}
  }} {{
    lassign $_pair _r _i
    if {{[set_user_match "r:/WORK/$top/$_r" "i:/WORK/$top/$_i"]}} {{
      incr _n
    }} else {{
      incr _miss
      if {{$_miss <= 10}} {{ puts "IQE_PIN_FAIL: $_r <-> $_i" }}
    }}
  }}
  puts "IQE_PIN_END {v} n=$_n miss=$_miss expect={exp + len(iq_pairs)}"
  if {{$_miss != 0}} {{ error "IQE_PIN_MISS={v} miss=$_miss" }}
  if {{$_n != {exp + len(iq_pairs)}}} {{ error "IQE_PIN_COUNT={v} n=$_n expect={exp + len(iq_pairs)}" }}
}}
'''
    return out


def gen_sched(v):
    """Scheduler*：把每个 IQ 实例自己的钉点表（verif/ut/<IQ>/fm_pins_pre.tcl，已随 IQ 签核）加上实例前缀汇总。"""
    gsrc = pathlib.Path(f'/home/eda/xs-env/G1-canonical/golden-rtl/{v}.sv').read_text()
    pairs = []
    for mod, inst in re.findall(r'^  (IssueQueue\w+) (\w+) \($', gsrc, re.M):
        t = (UT / mod / 'fm_pins_pre.tcl').read_text()
        blocks = re.findall(r'foreach _pair \{\n(.*?)\n  \} \{\n    lassign \$_pair _r _i\n    if \{\[set_user_match "(.*?)" "(.*?)"\]\}',
                            t, re.S)
        if len(blocks) != 2:
            raise SystemExit(f'{mod}: 钉点文件结构异常')
        for body, rt, it in blocks:
            rpre = rt.replace('r:/WORK/$top/', '').replace('$_r', '')
            ipre = it.replace('i:/WORK/$top/', '').replace('$_i', '')
            for r, i in re.findall(r'\{(\S+) (\S+)\}', body):
                pairs.append(f'    {{{inst}/{rpre}{r} {inst}/{ipre}{i}}}')
        # IQ 自身的出队打拍负载（deqDelay_<d>_*）与性能计时器：单签 IQ 时它们都直接驱动输出、按名/签名
        # 就配上了；在调度器里大多数字段没有出口（Scheduler_1 诊断跑实测 4962 个 unmatched unread），
        # 按 gen_iq.py 同一张负载布局逐位钉上。
        sys.path.insert(0, str(UT.parents[1] / 'scripts'))
        import gen_iq
        c = gen_iq.Ctx(mod)
        P, _ = gen_iq.measure(c)
        for d in range(P['N_DEQ']):
            fields = [(m.group(1), w) for r, w in c.regs for m in [re.fullmatch(r'deqDelay_%d_(\w+)' % d, r)]
                      if m and m.group(1) != 'valid']
            off = sum(w for _, w in fields)
            for f, w in fields:
                off -= w
                for b in range(w):
                    g_r = f'deqDelay_{d}_{f}_reg[{b}]' if w > 1 else f'deqDelay_{d}_{f}_reg'
                    pairs.append(f'    {{{inst}/{g_r} {inst}/u_core/dly{d}_q_reg[{off + b}]}}')
            for tname, iname in (('selectTime', 'select_timer'), ('issueTime', 'issue_timer')):
                for b in range(64):
                    pairs.append(f'    {{{inst}/deqBeforeDly_{d}_bits_common_perfDebugInfo_{tname}_c_reg[{b}] '
                                 f'{inst}/u_core/{iname}_reg[{d}][{b}]}}')
    n = len(pairs)
    return f'''# {v} FM 匹配前钉点 —— 汇总各 IssueQueue 实例已签核的钉点表，加实例前缀
# ============================================================================
# ★自动生成：verif/ut/IssueQueue_common/gen_fm_pins.py —— 勿手改★
# 来源：verif/ut/<IssueQueue*>/fm_pins_pre.tcl（每条配对原样，两侧路径各加 "<IQ 实例>/"）
#       + 各 IQ 的 deqDelay 负载寄存器与性能计时器（按 gen_iq.py 的负载布局），共 {n} 对。
# 计数守卫同 IQ：用 set_user_match 的返回值数，失败一条或总数 != {n} 都 error。
# ============================================================================

if {{$top eq "{v}"}} {{
  set _n 0
  set _miss 0
  puts "IQE_PIN_BEGIN {v} expect={n}"
  foreach _pair {{
{chr(10).join(pairs)}
  }} {{
    lassign $_pair _r _i
    if {{[set_user_match "r:/WORK/$top/$_r" "i:/WORK/$top/$_i"]}} {{
      incr _n
    }} else {{
      incr _miss
      if {{$_miss <= 10}} {{ puts "IQE_PIN_FAIL: $_r <-> $_i" }}
    }}
  }}
  puts "IQE_PIN_END {v} n=$_n miss=$_miss expect={n}"
  if {{$_miss != 0}} {{ error "IQE_PIN_MISS={v} miss=$_miss" }}
  if {{$_n != {n}}} {{ error "IQE_PIN_COUNT={v} n=$_n expect={n}" }}
}}
'''


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('variant')
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    dst = UT / a.variant / 'fm_pins_pre.tcl'
    txt = gen_sched(a.variant) if a.variant.startswith('Scheduler') else gen(a.variant)
    if a.check:
        ok = dst.exists() and dst.read_text() == txt
        print(f'gen_fm_pins --check: {a.variant} ' + ('OK' if ok else '不一致'))
        return 0 if ok else 1
    dst.write_text(txt)
    print(f'gen_fm_pins: 写 {dst}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
