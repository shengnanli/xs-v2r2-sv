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
    # ★2026-10-03 缩表 1 条（agent/gatefix2，codex_0207 E1）★：SyncDataModule/fm_pins_pre.tcl
    #   由 scripts/gen_dm_wrappers.py --pins-only 重出：返回值判成败 + 字面期望数 fail-closed；
    #   旧版 1 位字段/整宽载荷点名错、catch 回退走不到，8 变体共 5248 点实际没钉上（已重证）。
    # 「匹配后」钉点（FM_PIN_TCL）同一病灶、同一处置
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
# 落地时仓里 32 个钉点文件有 28 个是这个形态，涉及 28 个 top。
#
# ★这里有一句我先写错了的话，留在这里★：commit 43d9cc8b 的说明里写的是
# "它们对应的目标都已签核"。**没有核对就写了**。照 docs/coverage_three_axis.tsv
# 现查，28 个 top 里只有 12 个是 PROVEN*（Bku / Composer / EntriesAluCsrFenceDiv /
# EntriesVfdivVidiv / ITTageTable{,_1..4} / TLBFA / TLBNonBlock / TlbStorageWrapper），
# 其余 16 个是 UNPROVEN 或 MISSING。
#
# ★但也不能反过来照这个分类办事★：那张覆盖台账**自己就是漂的**（本轮实测
# rewrite_coverage.py --check 在 main 上 rc=1，coverage_three_axis 也漏记了
# 刚签核的目标）。也就是说"哪些已签核"这件事此刻没有可信的机读来源 ——
# 例如 main 刚合入的 Entries* 7 个变体日志里写着 SIGNOFF_PASS，台账里却还是 MISSING。
#
# 所以当时取保守做法：28 个全部记账，不据一张已知会漂的表单方面打红谁。
#
# ★集成者已裁（0920）：不为这件事重跑那 28 个 FM★
# 他全量扫了 evidence：带 FM-036/Unknown name 的目录 134 个，其中 SUCCEEDED 128、
# FAILED 5、无 receipt 1；**判了 SUCCEEDED 又有 unread/unmatched 残留的：0 个**。
# 机理：钉点计数从来不是承重的那道闸 —— 钉失败 => 该点没建立起比较 =>
# 它以 unmatched 或 unread 的形态留在结果里 => 被 **unread 铁律**（任何 unread
# 即 PARTIAL）和 unmatched=0 拦下。**空守卫拦的是"我钉的名字对不对"，真判决在下游。**
# 另外多数 FM-036 出自 match_packed_payload 这类**投机性**辅助（试一批可能的名字，
# 试不中是常态，不是缺陷）。所以 28 次全量 FM 换不到证据。
#
# ★解除条件（写死，免得日后被读成"重跑过就算数"）★
# 一个文件从本表删除，**不是**因为"它重跑过了"，而是因为两条判据都在位：
#   (1) 发射端改成**返回值**计数：`if {[set_user_match $r $i]} {incr _pinned}`；
#   (2) 第二条独立判据在位：fm.log 里**行首锚定**的 `Error:` 行数为 0。
# 处置节奏：在各自目标**下一次被改动或晋升时顺带修**（与 codex 0168 对 initreg
# 存量的处置同一口径），不专门为它排 FM。
# G2b 判据保证表只缩不长；新文件用 catch 一律判红。
#
# 每个文件的修法只有一行（catch 形 -> 返回值形）。
CATCH_COUNT_LEDGER = {
    'verif/ut/Bku/fm_pins_pre.tcl',
    'verif/ut/Composer/fm_pins_pre.tcl',
    'verif/ut/IBuffer/fm_pins.tcl',
    'verif/ut/ICacheMissUnit/fm_pins.tcl',
    'verif/ut/ITTageTable/fm_pins.tcl',
    'verif/ut/ITTageTable_1/fm_pins.tcl',
    'verif/ut/ITTageTable_2/fm_pins.tcl',
    'verif/ut/ITTageTable_3/fm_pins.tcl',
    'verif/ut/ITTageTable_4/fm_pins.tcl',
    'verif/ut/Predictor/fm_pins_pre.tcl',
    # SyncDataModule/fm_pins_pre.tcl：2026-10-03 改用返回值（agent/gatefix2），出表。
    # ★2026-09-20 再缩 3 条（agent/pindebt）★：RenameBuffer / TLBFA / TLBNonBlock
    #   三个「匹配后」钉点文件已改成用**返回值**计数，并把原来那几处 `exit 3`
    #   统一改成 `error`（safe interp 隐藏 exit，见 docs/pin_guard_failclosed.md §二）。
    #   同批还有两个**根本没有中止路径**的（NCBTransactionQueue / SSIT），
    #   它们本来就不在本表（本表只记 catch 计数），一并在同一轮补成 fail-closed。
    'verif/ut/TlbStorageWrapper/fm_pins.tcl',
    # ★2026-09-20 缩表 9 条（agent/pindebt）★：9 个 Entries_* 的钉点文件已由
    #   verif/ut/Entries_common/gen_fm_pins.py 改成用**返回值**计数 + 两道
    #   fail-closed（$_miss != 0 / $_n != <字面整数>），不再用 catch。
    #   注入探针前后对照（同一个变体、同一个注入：让第 7 次 set_user_match 返回 0）：
    #     旧: `IQE_PINS: 9898 / 9898 tried, 0 threw`，rc=0 —— ★完全没响★
    #     新: `IQE_PIN_FAIL: ...` + `n=9897 miss=1 expect=9898` + error 真的抛出，rc=1
    #   receipt 闭包的桥接见 docs/pin_guard_failclosed.md（调用序列逐字节相同）。
    # -- 下面 12 个与上面同一批存量，只是随 main f034da5f（OthersEntry 12 变体）
    #    在我落这张表**之后**才合进来。★分界线是 0920 那条裁定，不是我写表的时刻★；
    #    照裁定它们属于「存量、下次改动/晋升时顺带修」，不是「新长出来的违规」。
    # ★2026-09-20 缩表 12 条（agent/othersentry）★：12 个 OthersEntry_* 的钉点
    #   文件已由 verif/ut/OthersEntry_common/gen_fm_pins.py 改成用**返回值**计数，
    #   不再用 catch。真 fm_shell 实测的前后对照（同一个注入 typo）：
    #     旧: `OE_PINS: 822 / 822 tried, 0 threw` —— 完全没响
    #     新: `OE_PIN_FAIL` + `n=821 miss=1` + error 真的抛出
    #   台账只许缩，这里按闸 G2b 的要求把它们摘掉。
    # ★2026-09-21 两张表各缩 1 条（agent/ftqprove）★：verif/ut/Ftq/fm_pins_pre.tcl
    #   6 处 `catch {set_user_match ...}` 已改成取**返回值**计数，并补上
    #   OE_PIN_BEGIN/END 归因标记与 5 条由计数比较守卫的 `error`
    #   （总数 3494 + 分族 2048/2/1344/100；用 error 不用 exit，safe interp 隐藏 exit）。
    #   tclsh 桩正负对照：正 n=3494 miss=0 正常返回；
    #   负（让第 7 次 set_user_match 返回 0）-> error "FTQ_PIN_MISS=Ftq miss=1 (n=3493)"。
    #   真 fm_shell 实跑（evidence/6b056a122fad/Ftq）：OE_PIN_END Ftq n=3494 miss=0 expect=3494，
    #   scripts/check_pin_errors.py --require-pins rc=0（区间内 Error 0 条）。
    #   ★别把它读成"闸分提高了"★：本闸在 main(786aed42) 上就是 PASS 20 / FAIL 4，
    #   摘表后还是 PASS 20 / FAIL 4。中间那一步（守卫改好、表还没缩）才是 18/6。
    #   变的是 Ftq 那一行的**性质**：从"ok（遗留 fail-open / 遗留 catch，已记账）"
    #   变成真的干净的 ok，台账少一条豁免。
}

# ★2026-09-20 两张表各缩 3 条（agent/provefleet2）★
#   FCVT / ICacheCtrlUnit / InstrUncache 三个钉点文件已改成用**返回值**计数 +
#   两道建立在返回值上的 fail-closed 守卫（$_miss != 0 / $_n != <字面整数>），
#   中止一律 `error`。原因是本轮要把这三个目标签成 PROVEN_DIRECT，
#   而"钉点文件 fail-open"意味着这三次证明里"我钉的名字对不对"这道守卫是空的。
#   （下游的 unread 铁律与 unmatched=0 仍然承重 —— 0920 裁定说的就是这件事；
#     这里补的是**上游那道本来就该在的守卫**，不是推翻那条裁定。）
#   调用序列逐字节未变（scripts/pin_call_equiv.py --check），三个目标已重跑出证。
# ---------------------------------------------------------------------------
# ★同一个空守卫也长在**共享脚本**里★（2026-09-20 实测，agent/provefleet3）
# ---------------------------------------------------------------------------
# 上面两张表扫的是 `verif/ut/*/fm_pins*.tcl`。但 `scripts/fm_eq.tcl` 的
# `match_packed_payload` 里有**一模一样**的形态，而它一个字节都不在本闸的扫描范围内：
#
#     if {![catch {set_user_match $rpath $ipath}]} { incr n; break }
#
# 实测证据（不是读代码读出来的，是 evidence/6a9e4235497e/NewPipelineConnectPipe_29）：
#   · fm.log 行首锚定 `grep -cE "^ *Error:"` = **41**，全是 FM-036 Unknown name；
#   · 41 **恰等于** verif/ut/NewPipelineConnectPipe_29_34_35/fm_map/*.txt 里
#     width==1 的字段数（_29 41 个、_34 30 个，awk 复核过）；
#   · 同一份 fm.log 的 match 统计：`41 Compare points matched by signature analysis`，
#     user-matched 只有 982 = 1023 - 41。
# ⇒ `catch` 恒为 0 ⇒ 第一支候选 `data_<suf>_reg[0]` "成功"并 `break`
#   ⇒ w==1 的第二支候选 `data_<suf>_reg`（无下标）**是死代码**
#   ⇒ `PACKED_MATCH: 1023 points pinned` 这句 **报多了 41**（真实 982）。
#
# ★集成者已裁（0920 同一条口径）：现在不改 `scripts/fm_eq.tcl`。★
# 理由与那 28 个文件不同、更硬：修它**不是守卫专属改动**。那 41 个字段会从
# signature-matched 变成 user-matched，**配对来源变了 = 证明语义变了**，
# 绑着 fm_eq.tcl 的 46+ 份既有 receipt 会一起失效；而本仓刚为 fm_eq.tcl 的
# per-target 拆分付过一次"既有证书全部过期"的代价（见 verif/fm_target_config/README.md）。
# 处置节奏同 CATCH_COUNT_LEDGER：**只许缩不许长，下次该目标被改动/晋升时顺带修**。
#
# ★为什么不塞进 CATCH_COUNT_LEDGER★：那张表的 staleness 只在扫描 `files` 时才复核，
# 而 fm_eq.tcl 不在 files 里 —— 塞进去就是一条**没有任何人复核**的台账条目，
# 正是本仓一直在防的那种"记了账却没人盯"。所以另起一张表，配自己的 G2c 复核。
#
# 判决不受影响的理由（与 docs/pin_guard_failclosed.md §三同源）：钉点计数从来不是
# 承重的那道闸 —— 钉不上的点会以 unmatched/unread 的形态留在结果里，被 unread 铁律
# 和 unmatched=0 拦下。NPCP_29/_34 两次都是 unmatched 六项全 0、unread 0、failing 0。
# ★但"field map 把整个 payload 逐位钉死"这句话对 w==1 字段不成立★ ——
# 措辞更正见 docs/receipt_harvest_field_map_hole.md 的「2026-09-20 更正」一节。
SHARED_SCRIPT_CATCH_LEDGER = {
    # 路径（相对仓根）: (还在位时必须能在**去注释后的正文**里找到的形态, 形态记录)
    'scripts/fm_eq.tcl': (
        r'catch\s*\{\s*set_user_match\b',
        'match_packed_payload 的 w==1 回退分支；PACKED_MATCH 计数含 41/30 个未真钉上的点',
    ),
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


def shared_ledger_stale(rel, pattern):
    """共享脚本台账条目是否已过期（= 那个空守卫已经被修掉）。

    ★复核去注释后的正文★：修掉代码但在注释里留一句 `catch {set_user_match ...}`
    （本文件自己就这么干了）不该被读成"还在违规"，否则表永远摘不掉。
    """
    f = REPO / rel
    if not f.is_file():
        return False          # 幽灵条目由 G3 报，不在这里重复计数
    return not re.search(pattern, strip_comments(f.read_text(errors='replace')))


stale_shared = [rel for rel, (pat, _) in SHARED_SCRIPT_CATCH_LEDGER.items()
                if shared_ledger_stale(rel, pat)]
ck('G2c 共享脚本台账只缩不长：表里的文件确实还在用 catch 数钉点',
   not stale_shared,
   f'已修好却还挂在表上：{stale_shared}' if stale_shared else
   f'{len(SHARED_SCRIPT_CATCH_LEDGER)} 条在位（scripts/fm_eq.tcl match_packed_payload）')
ledger_missing = [p for p in FAIL_OPEN_LEDGER if not (REPO / p).is_file()]
ledger_missing += [p for p in CATCH_COUNT_LEDGER if not (REPO / p).is_file()]
ledger_missing += [p for p in SHARED_SCRIPT_CATCH_LEDGER if not (REPO / p).is_file()]
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

# ---------------------------------------------------------------------------
# ★G2c 的判别性自证★：一张"写上去就永远绿"的台账等于没有台账。
# 这三条钉住：形态还在 -> 判在位；形态修掉 -> 判过期该摘表；
# 只在注释里留一句 -> 也算修好（否则本文件自己那段说明就会把表锁死，永远摘不掉）。
_SHARED_PAT = SHARED_SCRIPT_CATCH_LEDGER['scripts/fm_eq.tcl'][0]
_still = 'if {![catch {set_user_match $r $i}]} { incr n; break }'
_fixed = 'if {[set_user_match $r $i]} { incr n; break }'
_only_comment = '# 旧写法 catch {set_user_match ...}，已改成返回值\n' + _fixed
_n = len(cases) + 1
ck(f'M{_n + 1} G2c 正向：形态还在时必须判「在位」',
   bool(re.search(_SHARED_PAT, strip_comments(_still))))
ck(f'M{_n + 2} G2c 负测：形态修掉后必须判「过期、该摘表」',
   not re.search(_SHARED_PAT, strip_comments(_fixed)))
ck(f'M{_n + 3} G2c 负测：只剩注释里提一句也算修好',
   not re.search(_SHARED_PAT, strip_comments(_only_comment)))

print()
print(f'PASS {len(PASS)} / FAIL {len(FAIL)}')
sys.exit(1 if FAIL else 0)
