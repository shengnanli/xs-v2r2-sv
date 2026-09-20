#!/usr/bin/env python3
"""OthersEntry* 家族 FM 钉点生成器（共享库）。
产物 = verif/ut/<变体>/fm_pins_pre.tcl（勿手改）。

★为什么需要钉点：一个被 FM 实测抓出来的名字串台★

golden（firtool 产物）把条目负载展平成上百个逐字段寄存器 `entryReg_payload_<f>_reg[b]`，
可读核把同一份负载存成一根向量 `r_payload_reg[off+b]`，两侧词干完全不同。

首跑（commit 7c4ba337，未钉点）实测：
  6 个 comp 变体全部 SUCCEEDED、failing 0；
  2 个 simp 变体 **FAILED**：
    OthersEntry_66  failing 20 / unmatched 16(ref)+16(impl) / unverified 144
    OthersEntry_88  failing 20 / unmatched 24(ref)+24(impl) / unverified 1477
  失败点长这样：
    Ref  entryReg_payload_psrc_0_reg[b]   <-> Impl u_entry/r_psrc_reg[0][b]
  也就是 FM 把 golden 的 **payload.psrc** 配到了可读核的 **status.psrc** 上，
  而 golden 真正的 status.psrc（entryReg_status_srcStatus_0_psrc_reg）反倒没人配。
  两者是**不同的寄存器**（一个装 enq.bits.payload.psrc_<i>，一个装
  enq.bits.status.srcStatus[s].psrc），自然一比就失配。

★为什么只有 simp 炸★ `transEntry.bits.payload.psrc_#` 是 simp 独有的字段
（矩阵里 payload 整包只有 simp 有），comp 的负载里压根没有 psrc，
没有同名对象可串，所以 6 个 comp 一次过。
—— 这也说明「6/12 过了」不能外推成「方法对了」。

★钉点只做名字对应★ 不 dont_verify、不黑盒、不约束 ref、不跳过任何比较点。
偏移表若算错，FM 会把钉错的对拿去比而**失败**，不会被掩盖。

★事实来源全部机械提取★
  1. 字段偏移表 <- entries_gen.Variant.pl_off（就是生成 <变体>.sv 用的同一张表）
  2. 哪些字段真有寄存器 <- 逐模块解析 golden 的 `reg ... entryReg_*;` 声明

用法（各变体目录下的 gen_fm_pins.py 是薄壳）：
  python3 gen_fm_pins.py            # 生成
  python3 gen_fm_pins.py --check    # 只校验没漂移（非零退出=漂移）
"""
import pathlib, re, sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parents[2]
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
sys.path.insert(0, str(HERE))
from othersentry_gen import OthersVariant                        # noqa: E402

REG_RE = re.compile(r'^\s*reg\s+(?:\[\s*(\d+)\s*:\s*0\s*\]\s+)?([A-Za-z_]\w*)\s*;', re.M)


def golden_regs(mod):
    out = {}
    for hi, nm in REG_RE.findall((GOLDEN / f'{mod}.sv').read_text()):
        out[nm] = 1 if hi == '' else int(hi) + 1
    return out


def ref_bits(name, width):
    """golden 寄存器在 FM 里的对象名：1 位标量无下标，多位逐位带下标。"""
    return [(name + '_reg', 0)] if width == 1 else \
           [(f'{name}_reg[{b}]', b) for b in range(width)]


def build_pins(ov):
    v = ov.v
    regs = golden_regs(ov.mod)
    pins, skipped = [], []
    # --- 负载：golden 每字段一个寄存器 <-> 核的一根扁平向量 ---
    fields = v.pl_all if ov.is_trans else v.pl_deq
    for f, w in fields:
        gname = 'entryReg_imm' if f == '#imm' else f'entryReg_payload_{f}'
        if gname not in regs:
            skipped.append(gname)           # 本变体里被 firtool DCE 掉了
            continue
        if regs[gname] != w:
            sys.exit(f'ERROR: {ov.mod}.{gname} 位宽 {regs[gname]} != 端口表 {w}')
        off = v.pl_off[f][0]
        for leaf, b in ref_bits(gname, w):
            pins.append((leaf, f'r_payload_reg[{off + b}]'))
    # --- 状态里词干不同 / 核用数组的那几组 ---
    for gname, iname in (('entryReg_status_deqPortIdx', 'r_deq_port_idx_reg'),
                         ('entryReg_status_blocked', 'r_blocked_reg')):
        if gname in regs:
            pins.append((gname + '_reg', iname))
        else:
            skipped.append(gname)
    for s in range(v.n_regsrc):
        # ★ status 的这几组也一并钉死 ★
        #   它们本来名字还算像、comp 上确实自动配对了，但 simp 上正是 payload.psrc
        #   把 r_psrc 抢走造成的失配。与其赌名字匹配的优先级，不如把两边都钉死：
        #   钉点只是名字对应，钉错会当场比失败，不会掩盖任何东西。
        for gsuf, isig in (('psrc', 'r_psrc_reg'), ('srcType', 'r_src_type_reg'),
                           ('srcState', 'r_src_state_reg'),
                           ('dataSources_value', 'r_data_src_reg'),
                           ('exuSources_value', 'r_exu_src_reg'),
                           ('useRegCache', 'r_use_rc_reg'),
                           ('regCacheIdx', 'r_rc_idx_reg')):
            gname = f'entryReg_status_srcStatus_{s}_{gsuf}'
            if gname not in regs:
                skipped.append(gname)
                continue
            w = regs[gname]
            if w == 1:
                pins.append((gname + '_reg', f'{isig}[{s}]'))
            else:
                for leaf, b in ref_bits(gname, w):
                    pins.append((leaf, f'{isig}[{s}][{b}]'))
        for q in range(v.ld_pipes):
            gname = f'entryReg_status_srcStatus_{s}_srcLoadDependency_{q}'
            if gname not in regs:
                skipped.append(gname)
                continue
            for leaf, b in ref_bits(gname, regs[gname]):
                pins.append((leaf, f'r_ld_dep_reg[{s}][{q}][{b}]'))
    return pins, skipped


HDR = """# {mod} FM 匹配前钉点 —— golden 逐字段寄存器 <-> 可读核的扁平负载向量与数组寄存器
# ============================================================================
# ★自动生成：verif/ut/{mod}/gen_fm_pins.py
#   （共享库 verif/ut/OthersEntry_common/gen_fm_pins.py）—— 勿手改★
#
# 为什么要钉：未钉点首跑（commit 7c4ba337）实测 6 个 comp 全过、2 个 simp FAILED，
# 失败点是 golden 的 **payload.psrc** 被配到了可读核的 **status.psrc** 上
# （Ref entryReg_payload_psrc_0_reg[b] <-> Impl u_entry/r_psrc_reg[0][b]），
# 而 golden 真正的 status.psrc 反倒没人配。payload 整包是 simp 独有的，
# 所以只有 simp 炸 —— 「comp 6/12 过了」不能外推成方法对了。
#
# 钉的对应（只消名差，不 dont_verify、不黑盒、不约束 ref、不跳过任何比较点）：
#   entryReg_payload_<field>_reg[b] / entryReg_imm_reg[b]  <-> r_payload_reg[off+b]
#   entryReg_status_deqPortIdx / _blocked                  <-> r_deq_port_idx / r_blocked
#   entryReg_status_srcStatus_<s>_<f>                      <-> r_<f>_reg[s][..]
#
# ★ 钉点数不是证据 ★ set_user_match 对不存在的名字不抛异常，所以下面那个计数
#   只说明"没抛"。判钉点真的生效看 fm.log 三条：行首 Error 计数为 0 /
#   match 后 Unmatched 0(0) / 终判 SUCCEEDED 且 failing=0。
#
# 本文件钉 {npin} 对；golden 侧不存在（被 firtool DCE）因而跳过的 {nskip} 个列在文件尾。
# ============================================================================

if {{$top eq "{mod}"}} {{
  set _n 0
  set _miss 0
  # ★标记★：fm.log 里 OE_PIN_BEGIN 与 OE_PIN_END 之间的 `Error:` 行才是**本文件**
  #   钉点失败；区间外的 FM-036 多半来自 match_packed_payload 那类**投机性试名**
  #   （试不中是常态）。判据见 scripts/check_pin_errors.py。
  puts "OE_PIN_BEGIN {mod} expect={npin}"
  foreach _pair {{
"""

FTR = """  }} {{
    lassign $_pair _r _i
    # ★用**返回值**判成败，不用 catch★（2026-09-20 本 lane 在真 fm_shell 上实测）：
    #   名字存在   -> 返回 1
    #   名字不存在 -> 返回 0，并往 fm.log 写 `Error: Unknown name: ... (FM-036)`
    #   catch {{...}} -> 恒为 0（**从不抛异常**），msg 就是那个返回值本身
    # 所以旧写法 `if {{[catch {{set_user_match ...}}]}} ... else {{incr _n}}` 里
    # else 支恒成立，_miss 恒 0、_n 恒等于总数 —— 两道守卫**都是空的**。
    # 这正是 P4 判据要抓的形态。
    if {{[set_user_match "r:/WORK/$top/$_r" "i:/WORK/$top/u_entry/$_i"]}} {{
      incr _n
    }} else {{
      incr _miss
      if {{$_miss <= 10}} {{ puts "OE_PIN_FAIL: $_r <-> $_i" }}
    }}
  }}
  puts "OE_PIN_END {mod} n=$_n miss=$_miss expect={npin}"
  # fail-closed 两道，都在最后一次 set_user_match **之后**：
  #   (1) 一条都不许失败；
  #   (2) 成功条数必须**恰好**等于生成时算出来的期望数量（字面整数，钉死）。
  if {{$_miss != 0}} {{ error "OE_PIN_MISS={mod} miss=$_miss" }}
  if {{$_n != {npin}}} {{ error "OE_PIN_COUNT={mod} n=$_n expect={npin}" }}
}}
"""


def gen(mod):
    ov = OthersVariant(mod)
    pins, skipped = build_pins(ov)
    out = [HDR.format(mod=mod, npin=len(pins), nskip=len(skipped))]
    for r, i in pins:
        out.append('    {%s %s}\n' % (r, i))
    out.append(FTR.format(npin=len(pins), mod=mod))
    if skipped:
        out.append('\n# golden 侧不存在、因而未钉点的寄存器：\n')
        for s in skipped:
            out.append(f'#   {s}\n')
    return ''.join(out), len(pins), len(skipped)


def main(mod):
    txt, npin, nskip = gen(mod)
    p = REPO / 'verif' / 'ut' / mod / 'fm_pins_pre.tcl'
    if '--check' in sys.argv:
        if not p.exists() or p.read_text() != txt:
            print(f'DRIFT: {p}')
            return 1
        print(f'{p.name} 与 golden 一致（{npin} 对）')
        return 0
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(txt)
    print(f'wrote {p}  钉 {npin} 对，跳过 {nskip} 个')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1]))
