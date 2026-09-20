#!/usr/bin/env python3
"""test_fm_pins_wellformed.py —— FM 钉点文件（fm_pins_pre.tcl / fm_pins.tcl）的结构闸。

**为什么要有这道闸**

钉点文件是**唯一**在证明流程里被 source 进 fm_shell 的"模块本地代码"。它本该只做
一件事：用 `set_user_match` 消掉两侧的名字差。但它跑在证明上下文里，语法上什么都
干得了 —— 放宽比较、钉常量、加黑盒、改 appvar，全都能在这里悄悄发生，而
`fm_verdict.py` 未必看得见（sidecar 下被 source 的脚本**不会**逐行回显进 fm.log，
见 scripts/test_tcl_no_poison.py 里定的扫描范围）。所以钉点文件必须机械地受约束。

第二件事更隐蔽：**钉点文件不是 fail-closed 就等于没钉**。名字一旦漂了（改了实例名、
改了数组维度、golden 换了个 firtool 版本），`set_user_match` 会逐条失败，而脚本只
`catch` 住、`puts` 一行"miss=N"，证明照跑。那次跑出来的 SUCCEEDED 里，这批点是
FM 自己另配的或干脆没配上 —— 与钉点无关。日志里那行 miss 没有任何人会看。

## 三条判据

  P1  只出现消名差的动词：禁 set_dont_verify_points / set_constant / set_black_box /
      set_app_var 一类**会改变证明语义**的命令。
  P2  有 fail-closed 的中止路径（`error` **或** `exit <非零>`），且由一个**计数比较**守卫。
      ★为什么 `exit <非零>` 也算★（2026-09-20 实测补上）：本仓的 FM 入口是
      `fm_shell -64 -file scripts/fm_eq.tcl < /dev/null`，钉点文件由它 `source`。
      `scripts/ut_common.mk` 紧接着 `rc=$?` 并把它当 `--rc` 喂给 fm_verdict.py，
      所以 `exit 3` 一定会把这一跑判成非 SUCCEEDED —— 这是**由证据确认的**传播链，
      不是"看着像"。而已知环境坑里，`fm_shell -file` 脚本报 `error` 时不退出、
      会挂死占 license（`< /dev/null` 就是为它加的），所以 6 条 lane
      （TLBNonBlock/TLBFA/RenameBuffer/NCBTransactionQueue/SSIT/Rob）各自独立
      收敛到了 `exit 3`。闸原先只认 `error`，把这 6 个**真 fail-closed** 的文件判红。
      `exit 0` 不算（负测 M11 钉住）。
  P3  期望数量是声明出来的（字面整数或 `set <var> <整数>`），并且校验发生在
      最后一次 set_user_match **之后**（"钉完再数"，不是钉之前先数一遍空的）。

## 遗留台账（ratchet，只许缩不许长）

写这道闸时仓里有 7 个 fm_pins_pre.tcl，其中 **5 个是 fail-open 的**：它们把期望数量
写在 `puts` 的字符串里当注释用，没有任何东西校验它。那 5 个目标已经签核，此刻把
`error` 补上去是**不能凭空做的** —— 如果某个目标当年其实是 FM 自己把点配上的
（set_user_match 失败但结果照样绿），补上 error 会把一个真绿目标判红，而我没有
重跑它们的预算去分辨。所以它们进 `FAIL_OPEN_LEDGER`，带上各自的形态记录。

台账的性质是 **ratchet**：闸只认这张表里已有的条目；**任何新文件 fail-open 一律判红**
（负测 M5 钉住这条）。并且台账里的文件一旦补成 fail-closed，闸会要求把它从表里删掉
—— 表只能缩。这不是"给自己开口子"，是把已知欠账显式记账，并保证它不会再长。
"""
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent

# 会改变证明语义的动词 —— 钉点文件里一个都不许出现。
# （`match` 不在此列：重新匹配不放宽任何东西，verif/ut/Ftq 已在用。）
FORBIDDEN = [
    'set_dont_verify_points', 'set_constant', 'remove_constant',
    'set_black_box', 'set_app_var', 'set_dont_match_points',
    'set_compare_rule', 'set_cutpoint', 'verify', 'setup',
    'exec', 'open', 'socket',
]

# 遗留 fail-open 台账（ratchet：只许缩不许长；新文件一律不得进表）。
FAIL_OPEN_LEDGER = {
    # 路径（相对仓根）: 形态记录 —— 期望数量只写在 puts 字符串里，无人校验
    'verif/ut/Bku/fm_pins_pre.tcl':
        'funcReg<->func_s1 9 位；"expect 9 / 0" 只在 puts 里',
    'verif/ut/FCVT/fm_pins_pre.tcl':
        'fmv 旁路两级 128 位；"expect 128 / 0" 只在 puts 里',
    'verif/ut/Ftq/fm_pins_pre.tcl':
        '6 组共 2048+2+1024+… 点；每组期望值都只在 puts 里',
    'verif/ut/InstrUncache/fm_pins_pre.tcl':
        '单点 req_addr[0]；失败分支只 puts 一行 *_FAIL',
    'verif/ut/SyncDataModule/fm_pins_pre.tcl':
        '8 个变体逐位钉；连期望数量都没声明，只 puts pinned/miss',
    # 「匹配后」钉点（FM_PIN_TCL）同一病灶、同一处置
    'verif/ut/ICacheCtrlUnit/fm_pins.tcl':
        'out_back_q 死位 16 点；"$_n / 16" 只在 puts 里',
    'verif/ut/ICacheMissUnit/fm_pins.tcl':
        '单点 beats1 计数器；失败分支只 puts 一行',
    'verif/ut/ITTageTable/fm_pins.tcl':
        'mbistPl 死位 9 点；miss 收进 _miss 列表后只 puts',
    'verif/ut/ITTageTable_1/fm_pins.tcl': '同 ITTageTable（变体）',
    'verif/ut/ITTageTable_2/fm_pins.tcl': '同 ITTageTable（变体）',
    'verif/ut/ITTageTable_3/fm_pins.tcl': '同 ITTageTable（变体）',
    'verif/ut/ITTageTable_4/fm_pins.tcl': '同 ITTageTable（变体）',
}

# ★用 `catch` 数钉点是空的★（2026-09-20 实测，见 docs/rob_pin_failclosed.tsv）
# `set_user_match` 遇到不存在的名字**不抛 Tcl 异常**：它返回 0 并往 fm.log 写一行
# `Error: Unknown name: ... (FM-036)`。所以
#     if {[catch {set_user_match $r $i}] == 0} {incr _pinned}
# 里 `_pinned` 恒等于 `_want`，随后那句 `if {$_pinned != $_want} {... exit 3}`
# 永远走不到 —— 一个 pin 都没配上也会打印 "pinned N of N"。
# 正确写法是用**返回值**：`if {[set_user_match $r $i]} {incr _pinned}`。
#
# 落地时仓里 32 个钉点文件有 28 个是这个形态，且它们对应的目标**都已签核**。
# 每个文件的修法只有一行，但改完必须重跑 FM 才知道那些点当年是不是真配上了 ——
# 那是 license 与机时的事，不是本 lane 能替它们决定的。所以照 FAIL_OPEN_LEDGER
# 的先例：逐条记账，**只许缩不许长**，新文件一律判红。
CATCH_COUNT_LEDGER = {
    'verif/ut/Bku/fm_pins_pre.tcl',
    'verif/ut/Composer/fm_pins_pre.tcl',
    'verif/ut/EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v/fm_pins_pre.tcl',
    'verif/ut/EntriesAluCsrFenceDiv/fm_pins_pre.tcl',
    'verif/ut/EntriesAluMulBkuBrhJmp/fm_pins_pre.tcl',
    'verif/ut/EntriesFaluFcvtF2vFmacFdiv/fm_pins_pre.tcl',
    'verif/ut/EntriesFaluFmac/fm_pins_pre.tcl',
    'verif/ut/EntriesFaluFmacFdiv/fm_pins_pre.tcl',
    'verif/ut/EntriesVfdivVidiv/fm_pins_pre.tcl',
    'verif/ut/EntriesVfmaVialuFixVfalu/fm_pins_pre.tcl',
    'verif/ut/EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf/fm_pins_pre.tcl',
    'verif/ut/FCVT/fm_pins_pre.tcl',
    'verif/ut/Ftq/fm_pins_pre.tcl',
    'verif/ut/IBuffer/fm_pins.tcl',
    'verif/ut/ICacheCtrlUnit/fm_pins.tcl',
    'verif/ut/ICacheMissUnit/fm_pins.tcl',
    'verif/ut/ITTageTable/fm_pins.tcl',
    'verif/ut/ITTageTable_1/fm_pins.tcl',
    'verif/ut/ITTageTable_2/fm_pins.tcl',
    'verif/ut/ITTageTable_3/fm_pins.tcl',
    'verif/ut/ITTageTable_4/fm_pins.tcl',
    'verif/ut/InstrUncache/fm_pins_pre.tcl',
    'verif/ut/Predictor/fm_pins_pre.tcl',
    'verif/ut/RenameBuffer/fm_pins.tcl',
    'verif/ut/SyncDataModule/fm_pins_pre.tcl',
    'verif/ut/TLBFA/fm_pins.tcl',
    'verif/ut/TLBNonBlock/fm_pins.tcl',
    'verif/ut/TlbStorageWrapper/fm_pins.tcl',
}

PASS, FAIL = [], []


def ck(name, ok, detail=''):
    (PASS if ok else FAIL).append(name)
    print(f'  {"ok  " if ok else "FAIL"}  {name}{"  " + detail if detail else ""}')


def strip_comments(text):
    """去掉 Tcl 注释，保留行数（便于报行号）。"""
    out = []
    for line in text.splitlines():
        s = line.lstrip()
        if s.startswith('#'):
            out.append('')
            continue
        # 行尾 `;# ...` 形式的注释
        out.append(re.sub(r';\s*#.*$', '', line))
    return '\n'.join(out)


def declared_ints(code):
    """`set <var> <整数>` 声明出来的常量表。"""
    return {m.group(1): int(m.group(2))
            for m in re.finditer(r'\bset\s+(\w+)\s+(\d+)\b', code)}


def check(text):
    """返回问题列表；空 = 结构良好（P1+P2+P3 全过）。"""
    probs = []
    code = strip_comments(text)

    # --- P1 只消名差 -------------------------------------------------------
    for verb in FORBIDDEN:
        for m in re.finditer(r'(?<![\w:.-])' + re.escape(verb) + r'(?![\w:.-])', code):
            ln = code[:m.start()].count('\n') + 1
            probs.append(f'P1 第 {ln} 行出现会改变证明语义的动词 `{verb}`')
    if 'set_user_match' not in code:
        probs.append('P1 通篇没有 set_user_match —— 这不是一个钉点文件')

    # --- P2 fail-closed：`if {<比较>} {… error / exit <非零> …}` -------------
    # 两种中止都认，但 `exit 0` 不认 —— 那是"装成中止的 fail-open"。
    ABORT = r'(?:\berror\b|\bexit\b\s+(?!0\s*\})[1-9]\d*)'
    guards = [(m.start(), m.group(1))
              for m in re.finditer(r'if\s*\{([^{}]*)\}\s*\{[^{}]*?' + ABORT + r'[^{}]*\}',
                                   code, re.S)]
    cmp_guards = [(pos, cond) for pos, cond in guards
                  if re.search(r'(!=|==|<=|>=|<|>)', cond)]
    if not guards:
        probs.append('P2 没有 fail-closed 的中止路径（error / exit 非零）'
                     '—— 钉不上也照跑 = 等于没钉')
    elif not cmp_guards:
        probs.append('P2 有中止路径但没有任何一条由**计数比较**守卫')

    # --- P4 不许用 catch 的返回码数钉点（set_user_match 不抛，见文件头）-------
    if re.search(r'catch\s*\{\s*set_user_match\b', code):
        probs.append('P4 用 `catch {set_user_match ...}` 数钉点 —— '
                     'set_user_match 不抛异常，这个计数恒等于总数（改用返回值）')

    # --- P3 期望数量声明 + 钉完再校验 ---------------------------------------
    ints = declared_ints(code)
    last_pin = code.rfind('set_user_match')
    ok_p3 = False
    for pos, cond in cmp_guards:
        # 期望数量 = 条件里的**正整数字面量**（`!= 0` 里的 0 是"零失败"，不是期望数量），
        # 或者一个被 `set <var> <整数>` 声明过的变量。
        # 只认**正数**：`set _n 0` 那种计数器初值不是期望数量，
        # 否则 `$_n != $_随便什么` 都会被当成"声明过了"（M8 实测踩到）。
        has_expect = any(int(d) > 0 for d in re.findall(r'\b\d+\b', cond)) or any(
            ints.get(v, 0) > 0 for v in re.findall(r'\$(\w+)', cond))
        if has_expect and pos > last_pin:
            ok_p3 = True
            break
    if cmp_guards and not ok_p3:
        probs.append('P3 期望数量没声明，或校验没发生在最后一次 set_user_match 之后')

    return probs


# ---------------------------------------------------------------------------
print('=== FM 钉点文件结构闸（P1 只消名差 / P2 fail-closed / P3 期望数量）===')
files = sorted(REPO.glob('verif/ut/*/fm_pins_pre.tcl')) + \
        sorted(REPO.glob('verif/ut/*/fm_pins.tcl'))
if not files:
    ck('G0 找到钉点文件', False, '一个都没找到 —— 闸在空转')
else:
    ck('G0 找到钉点文件', True, f'{len(files)} 个')

bad = 0
stale_ledger = []
stale_catch = []
for f in files:
    rel = str(f.relative_to(REPO))
    probs = check(f.read_text(errors='replace'))
    legacy = rel in FAIL_OPEN_LEDGER
    catch_legacy = rel in CATCH_COUNT_LEDGER
    if catch_legacy:
        p4 = [p for p in probs if p.startswith('P4')]
        if not p4:
            stale_catch.append(rel)     # 已经改成用返回值了 -> 该从表里删掉
        probs = [p for p in probs if not p.startswith('P4')]
    if legacy:
        # 台账只豁免 P2/P3；P1 对谁都不豁免。
        hard = [p for p in probs if p.startswith('P1')]
        soft = [p for p in probs if not p.startswith('P1')]
        if not soft:
            stale_ledger.append(rel)
        probs = hard
    if probs:
        bad += len(probs)
        FAIL.append(rel)
        print(f'  FAIL  {rel}')
        for p in probs:
            print(f'          {p}')
    else:
        tags = []
        if legacy:
            tags.append('遗留 fail-open')
        if catch_legacy:
            tags.append('遗留 catch 计数')
        print(f'  ok    {rel}{"   (" + " / ".join(tags) + "，已记账)" if tags else ""}')

ck('G1 全部钉点文件结构良好', bad == 0, f'{bad} 项问题' if bad else '')
ck('G2 台账只缩不长：表里的文件确实还 fail-open',
   not stale_ledger,
   f'已修好却还挂在表上：{stale_ledger}' if stale_ledger else '')
ck('G2b catch 计数台账只缩不长：表里的文件确实还在用 catch',
   not stale_catch,
   f'已改用返回值却还挂在表上：{stale_catch}' if stale_catch else '')
ledger_missing = [p for p in FAIL_OPEN_LEDGER if not (REPO / p).is_file()]
ledger_missing += [p for p in CATCH_COUNT_LEDGER if not (REPO / p).is_file()]
ck('G3 台账无幽灵条目', not ledger_missing, str(ledger_missing) if ledger_missing else '')

# ---------------------------------------------------------------------------
# ★负测★：种入每种违规都必须被抓，否则上面的 ok 可能是空转。
GOOD = '''
# 一个结构良好的钉点文件样本
if {$top eq "Demo"} {
  set _expect 4
  set _n 0
  set _miss 0
  for {set _i 0} {$_i < $_expect} {incr _i} {
    if {[set_user_match "r:/WORK/$top/a_${_i}_reg" "i:/WORK/$top/u_core/a_reg\\[$_i\\]"]} {
      incr _n
    } else {
      incr _miss
    }
  }
  puts "DEMO_PINS: $_n / $_expect"
  if {$_miss != 0 || $_n != $_expect} { error "DEMO_PIN_MISS=$_miss" }
}
'''
print()
print('=== 负测（种病必须变红，撤掉必须变绿）===')
ck('M0 干净样本不报任何问题', not check(GOOD), str(check(GOOD)))

cases = [
    ('放宽比较（dont_verify）',
     GOOD.replace('  puts "DEMO_PINS', '  set_dont_verify_points -all\n  puts "DEMO_PINS')),
    ('钉常量', GOOD.replace('  set _n 0', '  set_constant r:/WORK/Demo/x 0\n  set _n 0')),
    ('加黑盒', GOOD.replace('  set _n 0', '  set_black_box r:/WORK/Demo/sub\n  set _n 0')),
    ('改 appvar', GOOD.replace('  set _n 0', '  set_app_var verification_clock_gate_hold_mode any\n  set _n 0')),
    ('去掉 fail-closed（只 puts 不 error）',
     GOOD.replace('if {$_miss != 0 || $_n != $_expect} { error "DEMO_PIN_MISS=$_miss" }',
                  'puts "miss=$_miss (expect 0)"')),
    ('error 无计数守卫',
     GOOD.replace('if {$_miss != 0 || $_n != $_expect} { error "DEMO_PIN_MISS=$_miss" }',
                  'if {$_bogus} { error "DEMO" }')),
    ('校验发生在钉点之前（先数空的）',
     GOOD.replace('if {$_miss != 0 || $_n != $_expect} { error "DEMO_PIN_MISS=$_miss" }', '')
         .replace('  set _n 0', '  set _n 0\n  if {$_n != $_expect} { error "early" }')),
    ('期望数量没声明',
     GOOD.replace('  set _expect 4\n', '')
         .replace('$_expect', '$_unknown')),
    ('通篇没有 set_user_match',
     GOOD.replace('set_user_match', 'puts')),
    # --- 下面三条守住 2026-09-20 放宽 P2（认 `exit <非零>`）留下的新缺口 ---
    ('exit 0 装成中止（其实是 fail-open）',
     GOOD.replace('{ error "DEMO_PIN_MISS=$_miss" }', '{ puts "miss"; exit 0 }')),
    ('exit 非零但没有计数守卫',
     GOOD.replace('if {$_miss != 0 || $_n != $_expect} { error "DEMO_PIN_MISS=$_miss" }',
                  'if {$_bogus} { exit 3 }')),
    # ★P4★：用 catch 的返回码数钉点必须被抓（set_user_match 不抛，计数恒等于总数）
    ('用 catch 数钉点',
     GOOD.replace('if {[set_user_match ', 'if {[catch {set_user_match ')
         .replace('u_core/a_reg\\[$_i\\]"]} {', 'u_core/a_reg\\[$_i\\]"}] == 0} {')),
    ('exit 非零但校验发生在钉点之前',
     GOOD.replace('if {$_miss != 0 || $_n != $_expect} { error "DEMO_PIN_MISS=$_miss" }', '')
         .replace('  set _n 0', '  set _n 0\n  if {$_n != $_expect} { exit 3 }')),
]
# ★正向对照★：把样本里的 `error` 换成 `exit 3`，必须**仍然干净** ——
# 否则这次放宽就没生效，6 个真 fail-closed 的文件还是红的。
_GOOD_EXIT = GOOD.replace('{ error "DEMO_PIN_MISS=$_miss" }',
                          '{ puts "DEMO_PIN_MISS=$_miss"; exit 3 }')
ck('M0b 正向：`exit 3` 形态的样本也必须干净', not check(_GOOD_EXIT),
   str(check(_GOOD_EXIT)) if check(_GOOD_EXIT) else 'exit 非零被认作 fail-closed')

for i, (label, bad_txt) in enumerate(cases, start=1):
    got = check(bad_txt)
    ck(f'M{i} 种入「{label}」必须被抓', bool(got),
       f'报出 {len(got)} 项：{got[0][:60]}' if got else '★没抓到★')

# M5 的同族：台账不能是通配符 —— 一个**不在表里**的新 fail-open 文件必须判红。
fake = 'verif/ut/__NotInLedger__/fm_pins_pre.tcl'
ck(f'M{len(cases)+1} 台账不是通配符：新文件 fail-open 仍判红',
   fake not in FAIL_OPEN_LEDGER and bool(check(cases[4][1])))

print()
print(f'PASS {len(PASS)} / FAIL {len(FAIL)}')
sys.exit(1 if FAIL else 0)
