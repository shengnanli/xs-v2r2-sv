#!/usr/bin/env python3
"""EntriesVfdivVidiv FM 钉点生成器 —— 逐位把 golden 的「每字段一个寄存器」对应到
可读核的「一根扁平 payload 向量」。产物 = 同目录 fm_pins_pre.tcl（勿手改）。

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
  1. 字段偏移表  <- verif/ut/EntriesVfdivVidiv/gen.py 的 Variant.pl_off
                    （就是生成 EntriesVfdivVidiv.sv 时用的同一张表）
  2. 哪些字段在哪个 golden 条目模块里**真有寄存器** <- 逐模块解析
                    `reg [w-1:0] entryReg_payload_<field>;` 声明
  3. 条目实例名与分段 <- gen.py 的 Variant（数 golden 里的实例）

用法：
  python3 gen_fm_pins.py            # 生成 fm_pins_pre.tcl
  python3 gen_fm_pins.py --check    # 只校验已提交产物没漂移（非零退出=漂移）
"""
import importlib.util
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')

_spec = importlib.util.spec_from_file_location('evv_gen', HERE / 'gen.py')
_gen = importlib.util.module_from_spec(_spec)
_saved_argv, sys.argv = sys.argv, ['gen.py', '--check']
try:
    _spec.loader.exec_module(_gen)      # gen.py 的 main() 在 __main__ 下才跑
except SystemExit:
    pass
finally:
    sys.argv = _saved_argv

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
        for s in range(v.n_regsrc):
            for q in range(v.ld_pipes):
                gname = f'entryReg_status_srcStatus_{s}_srcLoadDependency_{q}'
                if gname not in regs:
                    skipped.append((inst, gname))
                    continue
                w = regs[gname]
                for leaf, b in ref_bits(gname, w):
                    pins.append((f'{inst}/{leaf}',
                                 f'g_entry[{k}].u_e/r_ld_dep_reg[{s}][{q}][{b}]'))
    return pins, skipped


def emit(v, pins, skipped):
    L = ["""# EntriesVfdivVidiv FM 匹配前钉点 —— golden 逐字段寄存器 <-> 可读核扁平负载向量
# ============================================================================
# ★自动生成：verif/ut/EntriesVfdivVidiv/gen_fm_pins.py —— 勿手改★
# 事实来源：gen.py 的字段偏移表 pl_off（生成 EntriesVfdivVidiv.sv 用的同一张表）
#          + 逐个 golden 条目模块解析出来的 `reg ... entryReg_*;` 声明。
#
# 钉的是三族对应（只消名差，不 dont_verify、不黑盒、不约束 ref）：
#   entryReg_payload_<field>_reg[b]                     <-> r_payload_reg[off+b]
#   entryReg_status_deqPortIdx_reg / _blocked_reg       <-> r_deq_port_idx_reg / r_blocked_reg
#   entryReg_status_srcStatus_<s>_srcLoadDependency_<q>_reg[b] <-> r_ld_dep_reg[s][q][b]
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
         'if {$top eq "EntriesVfdivVidiv"} {',
         '  set _n 0',
         '  set _miss 0',
         '  foreach _pair {']
    for r, i in pins:
        L.append('    {%s %s}' % (r, i))
    L += ['  } {',
          '    lassign $_pair _r _i',
          '    if {[catch {set_user_match "r:/WORK/$top/$_r" "i:/WORK/$top/u_core/$_i"} _msg]} {',
          '      incr _miss',
          '      if {$_miss <= 10} { puts "EVV_PIN_FAIL: $_r <-> $_i ($_msg)" }',
          '    } else {',
          '      incr _n',
          '    }',
          '  }',
          f'  puts "EVV_PINS: $_n / {len(pins)} pinned, $_miss missed"',
          '  # 一条都不许钉不上：钉不上说明偏移表/实例名与本次 elaborate 的设计对不上,',
          '  # 那时继续跑出来的 SUCCEEDED 是假的。fail-closed。',
          # 期望数量也要校验：只查 miss==0 的话，生成器少输出一半 pair
          # 同样是 miss=0，钉点静默缩水而证明照跑（钉点结构闸 P3）。
          f'  if {{$_miss != 0 || $_n != {len(pins)}}} {{ error "EVV_PIN_MISS=$_miss n=$_n" }}',
          '}',
          '']
    if skipped:
        L.append('# --- golden 侧不存在、因而未钉的寄存器（firtool 在该条目类型里 DCE 掉了）---')
        for inst, nm in skipped:
            L.append(f'#   {inst}: {nm}')
    return '\n'.join(L) + '\n'


def main():
    check = '--check' in sys.argv
    v = _gen.Variant('EntriesVfdivVidiv')
    pins, skipped = build(v)
    txt = emit(v, pins, skipped)
    out = HERE / 'fm_pins_pre.tcl'
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
    sys.exit(main())
