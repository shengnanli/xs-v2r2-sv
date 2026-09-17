#!/usr/bin/env python3
"""Entries* 家族 FM 钉点生成器（共享库）—— 逐位把 golden 的「每字段一个寄存器」
对应到可读核的「一根扁平 payload 向量」和几根数组寄存器。
产物 = verif/ut/<变体>/fm_pins_pre.tcl（勿手改）。

★为什么需要钉点★
  golden（firtool 产物）把条目负载展平成 ~110 个逐字段寄存器
      entryReg_payload_<field>_reg[b]
  可读核把同一份负载存成一根向量
      r_payload_reg[off+b]        （off = 本变体的字段偏移，见 gen.py 的 pl_off）
  两侧词干完全不同，Formality 的名字匹配无从下手；而负载里**大部分位在本变体
  里没有输出锥**（debug/异常/前端预测信息等只随 uop 传递、本模块不读），
  签名分析同样无从下手，于是两侧各剩两千多个未配对 unread 点。

★钉点只做名字对应★
  不 dont_verify、不加黑盒、不约束 ref、不跳过任何比对点。若偏移表算错，
  FM 会把钉错的对拿去比而**失败**，不会被掩盖。

★事实来源，全部机械提取，不接受人工转述★
  1. 字段偏移表  <- verif/ut/Entries_common/entries_gen.py 的 Variant.pl_off
                    （就是生成 <变体>.sv 时用的同一张表）
  2. 哪些字段在哪个 golden 条目模块里**真有寄存器** <- 逐模块解析
                    `reg [w-1:0] entryReg_payload_<field>;` 声明
  3. 条目实例名与分段 <- gen.py 的 Variant（数 golden 里的实例）

用法（各变体目录下的 gen_fm_pins.py 是薄壳）：
  python3 gen_fm_pins.py            # 生成 fm_pins_pre.tcl
  python3 gen_fm_pins.py --check    # 只校验已提交产物没漂移（非零退出=漂移）
"""
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')

sys.path.insert(0, str(HERE))
import entries_gen as _gen                                         # noqa: E402

REG_RE = re.compile(r'^\s*reg\s+(?:\[\s*(\d+)\s*:\s*0\s*\]\s+)?([A-Za-z_]\w*)\s*;', re.M)


def golden_regs(mod):
    """golden 模块里的 reg 声明表：name -> 位宽。"""
    out = {}
    for hi, nm in REG_RE.findall((GOLDEN / f'{mod}.sv').read_text()):
        out[nm] = 1 if hi == '' else int(hi) + 1
    return out


def ref_bits(name, width):
    """golden 寄存器在 FM 里的对象名：1 位标量无下标，多位逐位带下标。"""
    if width == 1:
        return [(name + '_reg', 0)]
    return [(f'{name}_reg[{b}]', b) for b in range(width)]


def array_delay_pins(v):
    """阵列级「打拍」寄存器的钉点：golden REG_* <-> 核的 og0_cancel_sel_d / ld*_cancel_d。

    ★ 为什么必须钉 ★
    golden 给**每个 enq 条目各打一拍** og0Cancel/ldCancel，展平后叫 REG_0 / REG_2_0 /
    REG_1_2_ld2Cancel 这种名字；可读核叫 og0_cancel_sel_d / ld2_cancel_d。
    两侧**没有共同词干**，FM 只能对一堆结构雷同的寄存器做签名分析 ——
    实测 8 个 og0 寄存器配上 4 个、配不上 4 个（AUTO_MATCH_FAIL: REG_2 / REG_6 /
    REG_2_2 / REG_2_6），Unmatched 从 0(0) 变 4(4)。

    ★ 映射不写死 ★ firtool 的 REG 编号规则（第 0 个省略序号、向量位号拼在后面）
    是实现细节，这里改成**从 golden 的实例连线里机械提取**：
    读 enqEntries_<k> 实例上 .io_enqDelayIn1_og0Cancel_<idx> / _ldCancel_<q>_ld<n>Cancel
    接的是哪根网，那根网就是该条目该路的打拍寄存器。
    """
    if not v.n_wk_iq:
        return []
    txt = (GOLDEN / f'{v.top}.sv').read_text()
    pins = []
    for k in range(v.n_enq):
        m = re.search(r'^  \w+ enqEntries_%d \(\n(.*?)^  \);' % k, txt, re.S | re.M)
        assert m, f'{v.top}: 找不到 enqEntries_{k} 实例'
        body = m.group(1)

        def net(port):
            mm = re.search(r'\.%s\s*\n?\s*\(([A-Za-z_]\w*)\)' % re.escape(port), body)
            return mm.group(1) if mm else None

        for w, idx in enumerate(v.og0_idx):
            if idx is None:
                continue
            n = net(f'io_enqDelayIn1_og0Cancel_{idx}')
            assert n, f'{v.top}: enqEntries_{k} 的 og0Cancel_{idx} 连线没解析出来'
            pins.append((f'{n}_reg', f'og0_cancel_sel_d_reg[{k}][{w}]'))
        for q in range(v.n_ld_cancel):
            for lvl, sig in ((2, 'ld2_cancel_d'), (1, 'ld1_cancel_d')):
                if lvl == 1 and not v.has_ld1:
                    continue
                if lvl == 2 and not v.has_ld2:
                    continue
                n = net(f'io_enqDelayIn1_ldCancel_{q}_ld{lvl}Cancel')
                assert n, f'{v.top}: enqEntries_{k} 的 ldCancel_{q}_ld{lvl} 连线没解析出来'
                pins.append((f'{n}_reg', f'{sig}_reg[{k}][{q}]'))
    return pins


def build(v):
    """返回 [(ref_leaf, impl_leaf, entry_index)]，已按条目分段展开。"""
    segs = ([('enqEntries_%d' % i, v.enq_mod, True) for i in range(v.n_enq)] +
            [('othersEntriesSimp_%d' % i, v.simp_mod, True) for i in range(v.n_simp)] +
            [('othersEntriesComp_%d' % i, v.comp_mod, False) for i in range(v.n_comp)])
    pins, skipped = [], []
    for k, (inst, mod, keep_wide) in enumerate(segs):
        regs = golden_regs(mod)
        # --- 负载：逐字段 -> 扁平向量 ---
        for f, w in (v.pl_all if keep_wide else v.pl_deq):
            gname = 'entryReg_payload_' + f
            if gname not in regs:
                skipped.append((inst, gname))      # golden 里被 DCE 掉的字段
                continue
            if regs[gname] != w:
                sys.exit(f'ERROR: {mod}.{gname} 位宽 {regs[gname]} != 端口表 {w}')
            off = v.pl_off[f][0]
            for leaf, b in ref_bits(gname, w):
                pins.append((f'{inst}/{leaf}', f'g_entry[{k}].u_e/r_payload_reg[{off + b}]'))
        # --- 状态：三族词干不同、可读核用数组的寄存器 ---
        for gname, iname in (('entryReg_status_deqPortIdx', 'r_deq_port_idx_reg'),
                             ('entryReg_status_blocked',    'r_blocked_reg')):
            if gname in regs:
                if regs[gname] != 1:
                    sys.exit(f'ERROR: {mod}.{gname} 不是 1 位')
                pins.append((f'{inst}/{gname}_reg', f'g_entry[{k}].u_e/{iname}'))
            else:
                skipped.append((inst, gname))
        # --- 每源的数组寄存器：golden 逐源逐位平铺，可读核是二/三维数组 ---
        #     ★ 哪个条目类型真有哪一组寄存器逐变体不同（VfdivVidiv 的 comp 没有
        #       srcLoadDependency，AluCsrFenceDiv 的有），所以一律以 golden 的
        #       reg 声明为准，不按条目类型硬推。
        for s in range(v.n_regsrc):
            for q in range(v.ld_pipes):
                gname = f'entryReg_status_srcStatus_{s}_srcLoadDependency_{q}'
                if gname not in regs:
                    skipped.append((inst, gname))
                    continue
                for leaf, b in ref_bits(gname, regs[gname]):
                    pins.append((f'{inst}/{leaf}',
                                 f'g_entry[{k}].u_e/r_ld_dep_reg[{s}][{q}][{b}]'))
            for gsuf, isig in (('exuSources_value', 'r_exu_src_reg'),
                               ('useRegCache',      'r_use_rc_reg'),
                               ('regCacheIdx',      'r_rc_idx_reg')):
                gname = f'entryReg_status_srcStatus_{s}_{gsuf}'
                if gname not in regs:
                    skipped.append((inst, gname))
                    continue
                w = regs[gname]
                if w == 1:
                    pins.append((f'{inst}/{gname}_reg',
                                 f'g_entry[{k}].u_e/{isig}[{s}]'))
                else:
                    for leaf, b in ref_bits(gname, w):
                        pins.append((f'{inst}/{leaf}',
                                     f'g_entry[{k}].u_e/{isig}[{s}][{b}]'))
    # 阵列级打拍寄存器（两侧无共同词干，签名分析配不齐，必须钉名）
    for r, i in array_delay_pins(v):
        pins.append((r, i))
    return pins, skipped


# ---------------------------------------------------------------------------
# 可读核里**按条件生成**的寄存器清单：名字 -> (生成条件, golden 侧对应的 reg 名)
#
# ★ 为什么要有这张表 ★
# 本轮连着三次踩同一个病：可读核生成了 golden 没有的寄存器。
#   deqPortIdx   —— 核了矩阵一列就推及三种条目类型
#   ld1_cancel_d —— c1 恒 0，但走的是**寄存器**不是常量
#   enqd_self_ld_dep / ld_cancel_d —— 变体没有 ldCancel 却照样生成
# 共同点：仿真完全看不见（常 0，不影响任何输出），而 FM 看得见 ——
# **常 0 的寄存器 ≠ 常量**：FM 不做可达性分析，多一个寄存器就多一条扇入边，
# 于是 golden 的锥里没有的边出现在 impl 的锥里。
# 而且这类点往往是 **matched** 的，`report_unmatched_points` 里根本看不见，
# 只能靠 analyze_points 一个一个挖锥——太贵。
#
# 所以做成一张机械核对表：每条"条件为真才生成"的寄存器，都要求 golden 侧
# 真的存在对应物；反之 golden 有而条件为假，也要报。差集是纯文本操作。
# ---------------------------------------------------------------------------
def check_reg_bijection(v):
    """两侧 DFF 名单做差集：核按参数生成的寄存器 <-> golden 的 reg 声明。"""
    # 独立重读 golden 顶层端口名单（不复用 Variant 上的派生属性，见下面的★）
    gold_top_ports = {n for _, _, n, _ in _gen.port_decls(v.top)}
    enq_regs = golden_regs(v.enq_mod)
    simp_regs = golden_regs(v.simp_mod)
    comp_regs = golden_regs(v.comp_mod)
    top_regs = golden_regs(v.top)
    problems = []

    # (描述, 核里生成该寄存器的条件, golden 侧应当存在的证据)
    checks = [
        ('条目 deqPortIdx(enq/simp)', True,
         'entryReg_status_deqPortIdx' in enq_regs and
         'entryReg_status_deqPortIdx' in simp_regs),
        ('条目 deqPortIdx(comp)', v.n_deq > 1,
         'entryReg_status_deqPortIdx' in comp_regs),
        ('条目 blocked(simp/comp)', True,
         'entryReg_status_blocked' in simp_regs and
         'entryReg_status_blocked' in comp_regs),
        ('条目 blocked(enq) —— 核**不**生成', False,
         'entryReg_status_blocked' in enq_regs),
        ('条目 srcLoadDependency(comp)', v.comp_has_ld_dep,
         'entryReg_status_srcStatus_0_srcLoadDependency_0' in comp_regs),
        ('条目 exuSources', v.n_wk_iq > 0,
         'entryReg_status_srcStatus_0_exuSources_value' in enq_regs),
        ('条目 useRegCache/regCacheIdx', v.has_rc,
         'entryReg_status_srcStatus_0_useRegCache' in enq_regs),
        # 阵列层：这几组只在顶层真有对应端口时才该生成。
        # ★ golden 侧证据必须**独立地**从 golden 文件里重新读 ★
        #   不能拿 v 上那个同源属性去比自己——那样写出来的是 (cond, cond)，
        #   恒真、永远不会响。本文件第一版的 ld1Cancel 与 og0Cancel 两行就是这么写的，
        #   负测里它们一声不吭，是负测把它们抓出来的。
        ('阵列 ld2Cancel 打拍(ld2_cancel_d)', v.n_ld_cancel > 0,
         'io_ldCancel_0_ld2Cancel' in gold_top_ports),
        ('阵列 ld1Cancel 打拍(ld1_cancel_d)', v.has_ld1,
         'io_ldCancel_0_ld1Cancel' in gold_top_ports),
        ('阵列 og0Cancel 打拍', any(i is not None for i in v.og0_idx),
         any(re.fullmatch(r'io_og0Cancel_\d+', n) for n in gold_top_ports)),
        ('阵列 入队瞬间 payload 影子(enqd_self_ld_dep)', v.n_ld_cancel > 0,
         'io_enq_0_bits_payload_srcLoadDependency_0_0' in gold_top_ports),
    ]

    # ★ 打拍寄存器必须**按 enq 条目分份**，不许合并 ★
    #   golden 的 RegNext(og0Cancel) / RegNext(ldCancel) 写在
    #   `for (entryIdx <- 0 until EnqEntryNum)` 里，于是每个 enq 条目各一套
    #   同源、逐位恒等的寄存器。合并成一份仿真永远看不出（值一样），
    #   FM 会把这一份配给其中一套、另一套 globally unmatched —— 本轮 canary
    #   的 1030 个失败点就是这么来的。这里按声明数核份数。
    top_txt = (GOLDEN / f"{v.top}.sv").read_text()
    n_og0 = len(set(re.findall(r'^\s*reg\s+(REG(?:_\d+)*)\s*;\s*$', top_txt, re.M)))
    n_ld2 = len(set(re.findall(r'^\s*reg\s+(REG(?:_\d+)*_ld2Cancel)\s*;', top_txt, re.M)))
    n_og0_expect = v.n_enq * sum(1 for i in v.og0_idx if i is not None)
    n_ld2_expect = v.n_enq * v.n_ld_cancel if v.has_ld2 else 0
    if n_og0 != n_og0_expect:
        problems.append(f'og0Cancel 打拍寄存器 golden {n_og0} 个，核按 NUM_ENQ 分份应为 '
                        f'{n_og0_expect} 个（{v.n_enq} 条目 × '
                        f'{sum(1 for i in v.og0_idx if i is not None)} 路）')
    if n_ld2 != n_ld2_expect:
        problems.append(f'ld2Cancel 打拍寄存器 golden {n_ld2} 个，核应为 {n_ld2_expect} 个'
                        f'（{v.n_enq} 条目 × {v.n_ld_cancel} 条 load 流水）')
    for desc, core_makes, golden_has in checks:
        if bool(core_makes) != bool(golden_has):
            problems.append(f'{desc}: 核生成={bool(core_makes)} golden存在={bool(golden_has)}')
    return problems


def emit(v, pins, skipped):
    L = ["""# %s FM 匹配前钉点 —— golden 逐字段寄存器 <-> 可读核的扁平负载向量与数组寄存器
# ============================================================================
# ★自动生成：verif/ut/%s/gen_fm_pins.py
#   （共享库 verif/ut/Entries_common/gen_fm_pins.py）—— 勿手改★
# 事实来源：entries_gen.py 的字段偏移表 pl_off（生成 %s.sv 用的同一张表）""" % (
        v.top, v.top, v.top) + """
#          + 逐个 golden 条目模块解析出来的 `reg ... entryReg_*;` 声明。
#
# 钉的是三族对应（只消名差，不 dont_verify、不黑盒、不约束 ref）：
#   entryReg_payload_<field>_reg[b]                     <-> r_payload_reg[off+b]
#   entryReg_status_deqPortIdx_reg / _blocked_reg       <-> r_deq_port_idx_reg / r_blocked_reg
#   entryReg_status_srcStatus_<s>_srcLoadDependency_<q>_reg[b] <-> r_ld_dep_reg[s][q][b]
#   entryReg_status_srcStatus_<s>_{exuSources_value,useRegCache,regCacheIdx}
#                                                       <-> r_{exu_src,use_rc,rc_idx}_reg[s][..]
#
# ★ 钉点数不是证据 ★ set_user_match 对不存在的名字不报错（实测），所以本文件
#   末尾那个计数只说明"没抛异常"。判钉点真的生效，看 fm.log 的三条：
#   grep -cE "^ *Error:" 为 0 / match 后 Unmatched 0(0) / 终判 SUCCEEDED failing=0。
#   （判据刻意不写具体错误编号：本脚本会被 fm_shell 逐行回显进 fm.log，
#     写出来就会命中注释自身，判据当场失效。）
#
# 放在**首次 match 之前**（fm_pins_pre.tcl）而不是之后：Formality 只在计数非零时
# 才打印 "N(M) Unmatched ... unread points"，fm_verdict.py 取日志里最后一次出现的
# 那行；钉在 match 之后会让第一次 match 的陈旧非零值被当成终态读回。
#
# 条目段与 golden 实例对应（索引 = golden entries 向量顺序 = 可读核 g_entry 下标）：""",
         f'#   enq  0..{v.n_enq - 1}  <- enqEntries_*        ({v.enq_mod},  KEEP_WIDE, 负载 {v.pl_trans_w} 位)',
         f'#   simp {v.n_enq}..{v.n_enq + v.n_simp - 1}  <- othersEntriesSimp_* ({v.simp_mod}, KEEP_WIDE, 负载 {v.pl_trans_w} 位)',
         f'#   comp {v.n_enq + v.n_simp}..{v.n_ent - 1}  <- othersEntriesComp_* ({v.comp_mod}, 仅 deq 子集 {v.pl_deq_w} 位)',
         '#',
         f'# 本文件钉 {len(pins)} 对。golden 侧不存在（被 firtool DCE）因而跳过的寄存器共 '
         f'{len(skipped)} 个，逐条列在文件尾，不产生钉点。',
         '# ============================================================================',
         '',
         'if {$top eq "%s"} {' % v.top,
         '  set _n 0',
         '  set _miss 0',
         '  foreach _pair {']
    for r, i in pins:
        L.append('    {%s %s}' % (r, i))
    L += ['  } {',
          '    lassign $_pair _r _i',
          '    if {[catch {set_user_match "r:/WORK/$top/$_r" "i:/WORK/$top/u_core/$_i"} _msg]} {',
          '      incr _miss',
          '      if {$_miss <= 10} { puts "IQE_PIN_FAIL: $_r <-> $_i ($_msg)" }',
          '    } else {',
          '      incr _n',
          '    }',
          '  }',
          f'  puts "IQE_PINS: $_n / {len(pins)} tried, $_miss threw"',
          '  # ★ 这个计数**不是** fail-closed，别拿它当判据 ★',
          '  #   实测（Lane L 的负向探针）：set_user_match 喂一个完全不存在的路径',
          '  #   照样返回 0，catch 抓不到 —— 所以"钉满 N 个"只说明没抛 Tcl 异常，',
          '  #   不说明这 N 对名字在设计里真的存在。',
          '  #   真正 fail-closed 的判据有三条，都在 fm.log 里：',
          '  #     (1) 行首错误行计数为 0：grep -cE "^ *Error:" fm.log',
          '  #         （钉了不存在的名字会在那里现形）',
          '  #     (2) match 之后 Unmatched Points 是 0(0)',
          '  #     (3) 终判 SUCCEEDED 且 failing=0 / unverified=0 / aborted=0',
          '  #   ★注意判据不能写成匹配某个错误编号的字面量★：fm_shell 会把本脚本',
          '  #   逐行回显进 fm.log，注释也不例外 —— 判据里出现的字面量会命中注释',
          '  #   自身，于是那条判据永远为真/永远为假。所以这里只用行首锚定的形式，',
          '  #   并且刻意不写出那个编号。',
          '  #   下面这条只兜住"Tcl 当场抛异常"这一种情况，聊胜于无。',
          '  if {$_miss != 0} { error "IQE_PIN_THREW=$_miss" }',
          '}',
          '']
    if skipped:
        L.append('# --- golden 侧不存在、因而未钉的寄存器（firtool 在该条目类型里 DCE 掉了）---')
        for inst, nm in skipped:
            L.append(f'#   {inst}: {nm}')
    return '\n'.join(L) + '\n'


def main(top):
    check = '--check' in sys.argv
    v = _gen.Variant(top)
    probs = check_reg_bijection(v)
    if probs:
        sys.stderr.write('[FAIL] 可读核与 golden 的寄存器名单对不上（多生成/少生成）：\n')
        for x in probs:
            sys.stderr.write('  ' + x + '\n')
        sys.stderr.write('  ★ 常 0 的寄存器不是常量：多一个 golden 没有的寄存器，\n'
                         '    FM 的锥里就多一条边，而仿真完全看不见。\n')
        return 1
    pins, skipped = build(v)
    txt = emit(v, pins, skipped)
    out = _gen.outdir(top) / 'fm_pins_pre.tcl'
    if check:
        if not out.exists() or out.read_text() != txt:
            print(f'DRIFT: {out}')
            return 1
        print(f'OK: {out} ({len(pins)} pins)')
        return 0
    out.write_text(txt)
    print(f'wrote {out}: {len(pins)} pins, {len(skipped)} skipped')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1]))
