#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""fm_passing_model.py —— FM `passing` 比较点的**跑前**预测器（通用版）。

## 模型

    passing = Σ_(golden 闭包里的每个**实例**) 该模块的寄存器位数
            + 顶层 output 端口位数

其中 `寄存器位数(mod)` = 该 `.sv` 里所有 `reg [h:l] name;` 声明的位宽之和。
直觉：FM 的比较点就是「触发器 + 顶层输出」，而 golden 是扁平层次、每个实例
各有一套触发器。

## 这个模型的战绩（都是**跑前**登记、跑后逐条对账的实测）

| 家族 | 结果 |
|---|---|
| TlbStorageWrapper_1 / TLBFA_1/_2/_3 / DelayN_7 / DelayN_9 | 逐位命中 |
| TLBNonBlock / _1 / _2 | 逐位命中 |
| Entries*（阵列档） | 模型 25013 实测 25001、模型 12264 实测 12136（差来自 Constant 寄存器） |
| OthersEntry* 18 个（单条目档） | **18/18 差全为 +0** |

★阵列/大件会略低于模型★：golden 里被 FM 判成 Constant 的寄存器不产生比较点。
所以模型是**上界**；实测高于模型一定是哪里算漏了，必须当 fail 查。

## 用法

    python3 scripts/fm_passing_model.py <target> [--deps a.sv b.sv ...]
    python3 scripts/fm_passing_model.py --from-ut <UT目录裸名>

`--from-ut` 直接读那个 UT 的 Makefile：`FM_VARIANTS` 逐个算，
依赖取 `FM_REF_DEPS_<名>`（没写就只算自己）。
"""
import argparse, collections, json, os, pathlib, re, sys

GOLDEN = pathlib.Path(os.environ.get('G1_CANONICAL',
                                     '/home/eda/xs-env/G1-canonical')) / 'golden-rtl'
REPO = pathlib.Path(__file__).resolve().parents[1]

# ★三处收口（2026-09-20，TXREQ 实测逼出来的）★，逐条说明见 CHANGELOG 注释块。
REG_RE = re.compile(r'^\s*reg\s+(?:\[\s*(\d+)\s*:\s*(\d+)\s*\]\s*)?([A-Za-z_]\w*)\s*'
                    r'(?:\[\s*(\d+)\s*:\s*(\d+)\s*\]\s*)?;', re.M)
OUT_RE = re.compile(r'^\s*output\s+(?:\[\s*(\d+)\s*:\s*(\d+)\s*\]\s+)?[A-Za-z_]\w*\s*,?\s*$',
                    re.M)
# 模块例化：`<Type> <inst> (` 单独占一行。★首字母不再限定大写★——firtool 生成的
# SRAM 包装模块叫 `ram_16x137` / `array_0_ext` 这类全小写名字，原来的 `[A-Z]` 把它们
# 整类漏掉了（TXREQ 实测：模型 149 / 实测 1492，正是漏了 ram_16x137 那块存储）。
# 放开首字母后要挡住语言关键字，否则 `if (` / `case (` 之类会被当成例化。
INST_RE = re.compile(r'^\s{0,4}([A-Za-z_]\w*)\s+([a-zA-Z_]\w*)\s*\(\s*$', re.M)
NOT_A_MODULE = {
    'if', 'else', 'case', 'casex', 'casez', 'for', 'while', 'repeat', 'always',
    'always_ff', 'always_comb', 'always_latch', 'initial', 'final', 'assign',
    'wire', 'reg', 'logic', 'input', 'output', 'inout', 'parameter', 'localparam',
    'function', 'task', 'module', 'endmodule', 'generate', 'begin', 'end',
    'return', 'automatic', 'static', 'typedef', 'import', 'export', 'default',
}

# ---------------------------------------------------------------------------
# ★黑盒输入引脚（BBPin）★ —— assembly 档的比较点里有一块模型原先整个漏掉了
# ---------------------------------------------------------------------------
# 逼出它的实测（agent/provefleet3，evidence/7877497350a2 8 份正式 receipt）：
# 8 个 SRAMTemplate 全部 native SUCCEEDED，但 fm_predict 一律判 ABOVE_MODEL
# （"实测高于模型上界 = 模型算漏了"）。拆开 fm.log 的 `Matched Compare Points` 表：
#
#     Passing (equivalent)   BBPin  Loop BBNet Cut  Port  DFF  LAT  TOTAL
#     SRAMTemplate_145         158     0    0    0   294  149    1    602
#                              ^^^                   ^^^  ^^^^^^^
#                          模型漏的       = 模型 outs   = 模型 regs
#
# 也就是说 FM 把**未解析黑盒的输入引脚**也当比较点（黑盒的 output 不是比较点，
# 它算进另一行 "Matched primary inputs, black-box outputs"）。
# 纯 strict 无黑盒的目标这一项恒为 0，所以加上它对那些目标**逐字节不变**。
#
# 黑盒是谁：在 FM 的 **ref 闭包**（`$top.sv` + `FM_REF_DEPS_<top>` 里的 .sv）内部
# 被例化、而定义文件**不在该闭包里**的模块。厂商 SRAM 宏叶子 `array_N_ext` 就是
# 这么来的：两侧都读 `array_N.sv`（宏壳），都不读 `array_N_ext.v`（行为模型）。
#
# 引脚位宽从哪来：读那份**没被 FM 读**的定义文件的端口表（`.v` 优先，其次 `.sv`）。
# ★读不到就返回 None，不猜★ —— 上界宁可标成"算不出"，也不能虚报一个数。
# 8/8 逐位命中见 model() 下方 --selftest 的正向用例。
#
# ★为什么另起一个正则，而不是放开 INST_RE 的首字母★：INST_RE 决定 `regs`
# （寄存器位数）的口径，动它会改变**所有已登记目标**的 expected；这里只是发现黑盒，
# 两件事的失败方向不同（多数一个实例 = 上界虚高 vs 少发现一个黑盒 = 上界虚低）。
# 另：agent/provefleet2 正在同一个文件里放开 INST_RE 首字母（commit a5f476fd，
# 尚未合进本分支）。两边合并后可以把两个正则统一，但那是集成者的一次有意合并，
# 不该由我在这里抢跑。
BBOX_INST_RE = re.compile(r'^\s{0,4}([A-Za-z_]\w*)\s+([A-Za-z_]\w*)\s*\(\s*$', re.M)
# 关键字黑名单：放开首字母后必须有它，否则会把语句当例化。
_INST_KW = {
    'if', 'else', 'case', 'casex', 'casez', 'endcase', 'always', 'always_ff',
    'always_comb', 'always_latch', 'assign', 'initial', 'final', 'module',
    'endmodule', 'function', 'endfunction', 'task', 'endtask', 'for', 'while',
    'repeat', 'forever', 'begin', 'end', 'generate', 'endgenerate', 'wire',
    'reg', 'logic', 'bit', 'byte', 'int', 'integer', 'input', 'output', 'inout',
    'parameter', 'localparam', 'typedef', 'struct', 'union', 'enum', 'import',
    'export', 'return', 'automatic', 'static', 'default', 'posedge', 'negedge',
}
# 黑盒端口表：`input [h:l] name` / `input wire name`（ANSI 头与非 ANSI 体都能命中）
BB_IN_RE = re.compile(
    r'\binput\s+(?:wire\s+|reg\s+|logic\s+)?'
    r'(?:\[\s*(\d+)\s*:\s*(\d+)\s*\]\s*)?([A-Za-z_]\w*)')


def _module_body(text, mod):
    """取 `module <mod> ... endmodule` 之间的整段（含端口头）。找不到返回 None。"""
    m = re.search(r'^\s*module\s+%s\b' % re.escape(mod), text, re.M)
    if not m:
        return None
    e = re.search(r'^\s*endmodule\b', text[m.start():], re.M)
    return text[m.start(): m.start() + e.start()] if e else text[m.start():]


def bbox_in_bits(mod):
    """黑盒的**输入**引脚位宽之和 = FM 给它建的 BBPin 比较点数。

    黑盒 output 不产生比较点（它在 "Matched primary inputs, black-box outputs" 那行）。
    ★读不到定义文件就返回 None（不猜）。★
    """
    for ext in ('.v', '.sv'):
        f = GOLDEN / (mod + ext)
        if not f.is_file():
            continue
        body = _module_body(f.read_text(errors='replace'), mod)
        if body is None:
            continue
        seen, n = set(), 0
        for hi, lo, name in BB_IN_RE.findall(body):
            if name in seen:
                continue
            seen.add(name)
            n += 1 if not hi else int(hi) - int(lo) + 1
        return n
    return None


def bbox_counts(top, deps):
    """FM ref 闭包内被例化、但定义文件不在闭包里的模块 -> 实例总数。"""
    closure = {top} | set(deps)
    cnt = collections.Counter()
    stack, guard = [top], 0
    while stack:
        cur = stack.pop()
        guard += 1
        if guard > 5000:            # 防环（golden 是扁平层次，正常远达不到）
            break
        f = GOLDEN / (cur + '.sv')
        if not f.is_file():
            continue
        for child, inst in BBOX_INST_RE.findall(f.read_text(errors='replace')):
            if child in _INST_KW or inst in _INST_KW:
                continue
            if child in closure and (GOLDEN / (child + '.sv')).is_file():
                stack.append(child)
            else:
                cnt[child] += 1
    return cnt



def _txt(mod):
    return (GOLDEN / f'{mod}.sv').read_text(errors='replace')


def reg_bits(mod):
    """该模块一份实例的触发器位数（上界）。

    ★两处与原版不同★（2026-09-20）：
    1. **unpacked 深度要乘进去**。`reg [136:0] Memory[0:15];` 是 16 项 × 137 位
       = 2192 位，原版只数 137。firtool 的 SRAM 包装模块全长这个样子。
    2. **`_RANDOM*` 不算**。那些声明只出现在 `ENABLE_INITIAL_MEM_` /
       `ENABLE_INITIAL_REG_` 块里，而这两个宏只在 **未定义 SYNTHESIS** 时才有；
       scripts/fm_eq.tcl 的 read_sverilog 是 `-define {SYNTHESIS}`，FM 根本读不到
       它们。把它们算进去只会让上界虚高。
    """
    n = 0
    for hi, lo, name, dhi, dlo in REG_RE.findall(_txt(mod)):
        if name.startswith('_RANDOM'):
            continue
        w = 1 if not hi else int(hi) - int(lo) + 1
        d = 1 if not dhi else abs(int(dhi) - int(dlo)) + 1
        n += w * d
    return n


def out_bits(top):
    t = _txt(top)
    m = re.search(r'^module\s+%s\s*\(\n(.*?)^\);' % re.escape(top), t, re.S | re.M)
    if not m:
        sys.exit(f'{top}: 找不到 module 头')
    n = 0
    for hi, lo in OUT_RE.findall(m.group(1)):
        n += 1 if not hi else int(hi) - int(lo) + 1
    return n


def instance_counts(top, allowed):
    """从 top 往下数**实例**（不是模块）。allowed = 允许展开的模块集合。

    ★为什么按实例数而不是模块数★：golden 是扁平层次，同一个模块例化 N 份就有
    N 套触发器，FM 的比较点也是 N 份。只按模块数算会把大件严重低估。
    """
    cnt = collections.Counter({top: 1})
    stack = [top]
    while stack:
        cur = stack.pop()
        if not (GOLDEN / f'{cur}.sv').exists():
            continue
        for child, _inst in INST_RE.findall(_txt(cur)):
            if child in NOT_A_MODULE:
                continue
            if child in allowed and (GOLDEN / f'{child}.sv').exists():
                cnt[child] += 1
                stack.append(child)
    return cnt


def model(top, deps, deps_unexpanded=()):
    allowed = set(deps)
    cnt = instance_counts(top, allowed)
    per = {m: reg_bits(m) for m in cnt}
    regs = sum(cnt[m] * per[m] for m in cnt)
    outs = out_bits(top)
    r = dict(top=top, insts=dict(cnt), per_reg=per, regs=regs, outs=outs,
             model=regs + outs)
    # ★deps 没读全就不许算 BBPin★（2026-09-20，NewDispatch 当场逼出来的）
    # `verif/ut/NewDispatch/Makefile` 写的是 `FM_REF_DEPS_NewDispatch = $(ND_CHILDREN)`。
    # from_ut 只挑 `.sv` 结尾的词，于是 deps 读成空 —— 而"闭包为空"和"闭包里真没有
    # 那几个模块"在下面的 bbox_counts 看来一模一样，NewDispatch 的 9 个真子设计
    # 会被整批误判成黑盒，凭空加出 2999 个比较点。
    # ★这正是本文件已经在 bbox_in_bits 里守过的那条：读不到就说读不到，不猜。★
    # 所以这里直接不加 bbin（模型退回 regs+outs，与加这一项之前逐字节相同），
    # 只把"为什么没加"记进结果里。
    # （agent/provefleet2 的 b820e35f 正在修 `$(VAR)` 展开；等它合进来，
    #   这里的 deps_unexpanded 自然为空，本守卫随之失效——它是兜底不是替代。）
    if deps_unexpanded:
        r['deps_unexpanded'] = list(deps_unexpanded)
        return r
    # ★只有真有黑盒时才加这几个键★：没有黑盒的目标（绝大多数 strict 目标）
    # 返回的字典与加这一项之前**逐字节相同**，已有登记不会被无谓地改动。
    bb = bbox_counts(top, deps)
    if bb:
        detail, bbin, unknown = {}, 0, []
        for m, c in sorted(bb.items()):
            w = bbox_in_bits(m)
            if w is None:
                unknown.append(m)
                continue
            detail[m] = dict(insts=c, in_bits=w, points=c * w)
            bbin += c * w
        r['bbox'] = detail
        r['bbin'] = bbin
        r['model'] = regs + outs + bbin
        if unknown:
            # 读不到端口表 = 这一项算不出来，**上界不再是上界**，必须说出来。
            r['bbox_unknown'] = sorted(unknown)
    return r


def _mk_vars(mk):
    """收集 Makefile 里的简单赋值（`NAME = ...` / `:=` / `?=`），供 $(NAME) 展开。"""
    return {m.group(1): m.group(2)
            for m in re.finditer(r'^([A-Za-z_]\w*)[^\S\n]*[:?]?=[^\S\n]*(.*)$', mk, re.M)}


def _expand(s, vars_, depth=0):
    """展开 `$(NAME)` / `${NAME}`。

    ★为什么必须展开★（2026-09-20 实测）：FCVT / FAlu / MulUnit 三个 UT 把
    golden 闭包写成 `FM_REF_DEPS_FCVT = $(FCVT_LEAVES)`。不展开时 deps 落成空集，
    模型只数顶层自己的寄存器 —— FCVT 模型给 2149，而这三个目标的**实测**分别是
    2514 / 2462 / 4537，全部 **高于**模型上界，于是判据只会报 ABOVE_MODEL
    （"模型算漏了"），登记本身就是错的。这不是模型不准，是 Makefile 没读全。
    `$(addprefix ...)` 之类的函数调用不展开（由调用方只取 .sv 结尾的词过滤掉）。
    """
    if depth > 8:
        return s
    def sub(m):
        name = m.group(1) or m.group(2)
        return _expand(vars_.get(name, ''), vars_, depth + 1) if name in vars_ else m.group(0)
    return re.sub(r'\$\((\w+)\)|\$\{(\w+)\}', sub, s)


def from_ut(ut):
    mk = (REPO / 'verif' / 'ut' / ut / 'Makefile').read_text(errors='replace')
    # ★同目录的 `include xxx.mk` 先内联★（2026-09-27 CtrlBlock）：闭包文件表由生成器写在
    # verif/ut/CtrlBlock/closure.mk 里、Makefile 只 include 它。不内联的话 FM_REF_DEPS 里的
    # $(GOLDEN_CLOSURE_*) 展不开，模型退回 regs+outs（缺失与否定长得一样）。只认同目录、
    # 只认 .mk、读不到就原样留着让 deps_unexpanded 守卫报出来。
    def _inl(m):
        f = REPO / 'verif' / 'ut' / ut / m.group(1)
        return f.read_text(errors='replace') if f.suffix == '.mk' and f.exists() else m.group(0)
    mk = re.sub(r'^include\s+(\S+)\s*$', _inl, mk, flags=re.M)
    mk = re.sub(r'\\\n', ' ', mk)          # 续行拼起来
    vars_ = _mk_vars(mk)
    # ★FM_INTERFACE_ONLY 里的模块在证明里是接口黑盒★：从 deps 里剔掉，让下面的 bbox_counts
    # 按黑盒计（BBPin 输入位进模型、子树寄存器不进）。Makefile 没写就是空表，行为不变。
    io_ = re.search(r'^FM_INTERFACE_ONLY[^\S\n]*=[^\S\n]*(.*)$', mk, re.M)
    iface_only = set(_expand(io_.group(1), vars_).split()) if io_ else set()
    mv = re.search(r'^FM_VARIANTS[^\S\n]*=[^\S\n]*(.*)$', mk, re.M)
    if not mv:
        sys.exit(f'{ut}: Makefile 里没有 FM_VARIANTS')
    tops = mv.group(1).split()
    out = []
    for t in tops:
        d = re.search(r'^FM_REF_DEPS_%s[^\S\n]*=[^\S\n]*(.*)$' % re.escape(t), mk, re.M)
        # ★两条改动的并集，不是二选一★（2026-09-21 集成者并）
        #   provefleet2：真的展开 $(VAR)（_expand）—— 这是**修复**；
        #   provefleet3：检测未展开变量并传给 model() 当守卫 —— 这是**兜底**。
        # provefleet3 自己写着「合进来后我这个守卫自然失效 —— 它是兜底不是替代」。
        # 所以：先展开，再看展开后**仍然残留**的 $(...)；两者都保留。
        # 只留展开：展不开的变量会让 deps 读成空、真子设计被整批误判成黑盒
        #           （NewDispatch 那次凭空 +2999，★缺失与否定长得一样★）。
        # 只留守卫：能展开的也不展开，白白退回 regs+outs。
        raw = d.group(1) if d else ''
        exp = _expand(raw, vars_)
        deps = [x.split('/')[-1][:-3] for x in exp.split() if x.endswith('.sv')]
        deps = [x for x in deps if x not in iface_only]
        unexp = sorted(set(re.findall(r'\$\(([A-Za-z_]\w*)\)', exp)))
        out.append(model(t, deps, unexp))
    return out


def _receipt_passing(top):
    """从已提交的 receipt 里取 native passing（自证要拿实测对账，不许硬编码期望）。

    ★按 target 名 glob，不钉 run id★：钉了 run id 的自证会在证据被重跑/换目录时
    静默失效，而"自证跑不起来"和"自证通过"必须长得不一样 —— 找不到就返回 None，
    调用处判红。同名多份取**最新**（与 fm_predict.find_receipt 同口径）。
    """
    cands = sorted((REPO / 'evidence').glob('*/%s/receipt.json' % top),
                   key=lambda x: x.stat().st_mtime)
    if not cands:
        return None
    return json.loads(cands[-1].read_text())['native_facts']['stats']['passing']


def selftest():
    """★BBPin 这一项的双向自证★（用的是本仓已提交的 receipt，不是编的数）。

    正向：有黑盒的目标，加项之后模型必须对得上实测。
    反向：无黑盒的目标，加项之后行为必须**逐字节不变**（连字典的键都不多一个）。
    判别性：把黑盒的定义文件名换成一个不存在的，必须落进 bbox_unknown 而不是
            悄悄按 0 算 —— 否则"算不出"和"没有"又长成一个样。
    """
    rc = 0

    def ck(name, ok, detail=''):
        nonlocal rc
        print('  [%s] %s%s' % ('OK' if ok else 'FAIL', name,
                               '  ' + detail if detail else ''))
        rc |= 0 if ok else 1

    # --- 正向 1：有黑盒 + 无重复寄存器合并 -> 逐位相等 ---------------------
    for top in ('SRAMTemplate_145', 'SRAMTemplate_146', 'SRAMTemplate_152'):
        r = next(x for x in from_ut('SRAMTemplateNewForm') if x['top'] == top)
        act = _receipt_passing(top)
        ck('正向 %s 有黑盒：模型 %d == 实测 %s' % (top, r['model'], act),
           act is not None and r['model'] == act,
           'bbin=%d' % r.get('bbin', 0))

    # --- 正向 2：有黑盒 + 有一对重复寄存器被 merge 合掉 -> 恰好差 1 --------
    for top in ('SRAMTemplate_155', 'SRAMTemplate_166', 'SRAMTemplate_178'):
        r = next(x for x in from_ut('SRAMTemplateNewForm') if x['top'] == top)
        act = _receipt_passing(top)
        ck('正向 %s 差额恰为 1（merge 合掉 respReg[1]≡rckEnReg 一对）' % top,
           act is not None and r['model'] - act == 1,
           '模型 %d 实测 %s' % (r['model'], act))

    # --- 反向：无黑盒的目标，加项前后逐字节不变 ---------------------------
    for top in ('NewPipelineConnectPipe_29', 'NewPipelineConnectPipe_34'):
        r = next(x for x in from_ut('NewPipelineConnectPipe_29_34_35')
                 if x['top'] == top)
        act = _receipt_passing(top)
        ck('反向 %s 无黑盒：不多出 bbox/bbin 键' % top,
           'bbox' not in r and 'bbin' not in r and 'bbox_unknown' not in r)
        ck('反向 %s 无黑盒：model 仍等于 regs+outs 且等于实测' % top,
           r['model'] == r['regs'] + r['outs'] == act,
           'model %d 实测 %s' % (r['model'], act))

    # --- 判别性：黑盒定义文件读不到时必须说"算不出"，不许按 0 算 ----------
    ck('判别性 bbox_in_bits 读不到定义文件时返回 None（不猜 0）',
       bbox_in_bits('__NoSuchVendorMacro__') is None)
    ck('判别性 发现得到黑盒：SRAMTemplate_145 -> array_12_ext x1',
       dict(bbox_counts('SRAMTemplate_145',
                        ['sram_array_1p32x148m74s1h0l1b_pftch_pht', 'array_12',
                         'MbistClockGateCell', 'ClockGate']))
       == {'array_12_ext': 1})
    ck('判别性 闭包里的模块不算黑盒：把 array_12 从 deps 里拿掉才会变成黑盒',
       dict(bbox_counts('SRAMTemplate_145',
                        ['sram_array_1p32x148m74s1h0l1b_pftch_pht',
                         'MbistClockGateCell', 'ClockGate']))
       == {'array_12': 1})
    # --- deps 读不全时必须拒绝算 BBPin -----------------------------------
    # ★这条原先断言的是「NewDispatch 的 deps 有未展开的 $(ND_CHILDREN)」★，
    # 也就是**依赖一个真实缺陷继续存在**。2026-09-21 把 provefleet2 的
    # `_expand`（真展开）与 provefleet3 的未展开检测并起来之后，
    # 那个变量能展开了 ⇒ 断言当场变红 —— 红得对，但红的是「问题被修好了」。
    # ★自测不该以某个真实缺陷不被修复为前提★：改成**合成输入**，
    # 只验守卫本身的行为，与仓库当下有没有这种 Makefile 无关。
    # 用一个**真实存在**的小 top（它自己无黑盒，上面已验过），
    # 但喂一个**合成的**未展开变量 —— 只验守卫行为，不依赖任何真实缺陷。
    synth = model('NewPipelineConnectPipe_29', [], ['UNEXPANDABLE_VAR'])
    ck('守卫 未展开的 make 变量必须被记下来',
       synth.get('deps_unexpanded') == ['UNEXPANDABLE_VAR'])
    ck('守卫 deps 读不全时不加 bbin（模型退回 regs+outs，与加项前逐字节相同）',
       'bbin' not in synth and 'bbox' not in synth
       and synth['model'] == synth['regs'] + synth['outs'])
    # 顺带把真实状态也量一下，但**不作为判据**（它会随仓库变化）：
    nd = next(x for x in from_ut('NewDispatch') if x['top'] == 'NewDispatch')
    print('    (参考，非判据) NewDispatch deps_unexpanded=%r deps=%d'
          % (nd.get('deps_unexpanded'), len(nd.get('deps') or [])))
    # ★判别性★：守卫不是空转 —— 同一个 top 若不声明"deps 没读全"，
    # 那 9 个真子设计就会被整批误判成黑盒、凭空加出上千个点。
    nd_naive = model('NewDispatch', [])
    ck('判别性 去掉守卫就会误判（同一 top 的 naive 算法 bbin > 0）',
       nd_naive.get('bbin', 0) > 0,
       'naive bbin=%d（%d 个"黑盒"）' % (nd_naive.get('bbin', 0),
                                        len(nd_naive.get('bbox', {}))))

    print('fm_passing_model --selftest', 'PASS' if rc == 0 else '★FAIL★')
    return rc


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('target', nargs='?')
    ap.add_argument('--deps', nargs='*', default=[])
    ap.add_argument('--from-ut')
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    rows = from_ut(a.from_ut) if a.from_ut else [
        model(a.target, [d[:-3] if d.endswith('.sv') else d for d in a.deps])]
    print(f'{"target":<24}{"regs":>10}{"outs":>8}{"模型(上界)":>12}   实例构成')
    for r in rows:
        comp = ', '.join(f'{m}x{c}' for m, c in sorted(r['insts'].items())
                         if m != r['top'])
        print(f'{r["top"]:<24}{r["regs"]:>10}{r["outs"]:>8}{r["model"]:>12}   '
              f'{comp or "(无子实例)"}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
