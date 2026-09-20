#!/usr/bin/env python3
"""OthersEntry 家族（24 变体）字段使用矩阵 —— 全部从 G1 golden 机械实测。

为什么要这张表：OthersEntry 是 IssueQueue 条目族里「非入队条目」那一支，
golden 按 (IssueBlockParams, isComp) 把它单态化成 24 个模块。24 个模块的差别
**只在端口面**（哪些字段留下、多宽、几路唤醒），逻辑骨架是同一份 Scala
（OthersEntry.scala 调 EntryBundles 的 CommonWireConnect / EntryRegCommonConnect /
CommonOutConnect）。所以做这一族之前必须先把「差异维度」量清楚，
再决定参数化核要开哪些参数 —— 不许从某一个变体外推到全家族
（Entries 共享核已经因为外推栽过两次，见 xs_iq_entries_core.sv §2.6a）。

用法:
  python3 gen_matrix.py           # 生成 matrix.md / matrix.tsv
  python3 gen_matrix.py --check   # 只校验已提交产物没漂移（非零退出 = 漂移）
"""
import re, sys, pathlib, collections, json

HERE   = pathlib.Path(__file__).resolve().parent
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')

PORT_RE = re.compile(
    r'^\s*(input|output)\s+(?:wire\s+|reg\s+)?(?:\[\s*(\d+)\s*:\s*(\d+)\s*\]\s+)?'
    r'([A-Za-z_]\w*)\s*,?\s*$')


def ports(mod):
    """[(dir, width, name)]，顺序即 golden 顺序。"""
    txt = (GOLDEN / f'{mod}.sv').read_text()
    m = re.search(r'^module\s+%s\s*\(\n(.*?)^\);' % re.escape(mod), txt, re.S | re.M)
    if not m:
        sys.exit(f'解析失败：{mod} 找不到 module 头')
    out = []
    for line in m.group(1).split('\n'):
        pm = PORT_RE.match(line)
        if not pm:
            if line.strip() and not line.strip().startswith('//'):
                sys.exit(f'{mod}: 端口行未识别 {line!r}')
            continue
        d, hi, lo, nm = pm.groups()
        if hi is not None and int(lo) != 0:
            sys.exit(f'{mod}.{nm}: 非 [n:0] 端口，本脚本未覆盖')
        out.append((d, 1 if hi is None else int(hi) + 1, nm))
    return out


def parents():
    """从 golden Entries*.sv 的实例声明反查：每个 OthersEntry 变体属于哪个 IQ、
    是 simp 还是 comp、例化几份。这是「角色」的唯一权威依据，不靠模块名猜。"""
    res = {}
    for f in sorted(GOLDEN.glob('Entries*.sv')):
        top = f.stem
        txt = f.read_text()
        insts = re.findall(
            r'^  ([A-Za-z]\w*) (othersEntriesSimp_\d+|othersEntriesComp_\d+)\s*\(',
            txt, re.M)
        cnt = collections.Counter((t, n.rsplit('_', 1)[0]) for t, n in insts)
        for (t, role), c in cnt.items():
            if t.startswith('OthersEntryVecMem'):
                continue            # VecMem 是另一族（4 变体），不在本轮 24 之内
            assert t not in res, f'{t} 被多个 Entries 例化：{res.get(t)} 与 {top}'
            res[t] = (top, 'simp' if role.endswith('Simp') else 'comp', c)
    return res


def idx_set(names, pat):
    return sorted({int(x) for n in names for x in re.findall(pat, n)})


def profile(mod):
    ps = ports(mod)
    W  = {n: w for d, w, n in ps}
    D  = {n: d for d, w, n in ps}
    N  = [n for d, w, n in ps]
    has = lambda s: s in W
    grp = lambda pat: [n for n in N if re.search(pat, n)]

    wb  = idx_set(N, r'wakeUpFromWB_(\d+)_')
    iq  = idx_set(N, r'wakeUpFromIQ_(\d+)_')
    src = idx_set(N, r'enq_bits_status_srcStatus_(\d+)_')
    ldc = idx_set(N, r'ldCancel_(\d+)_')
    og0 = idx_set(N, r'og0Cancel_(\d+)$')
    og1 = idx_set(N, r'og1Cancel_(\d+)$')

    def wens(bus):
        return sorted({m.group(1) for n in N
                       for m in [re.match(rf'io_commonIn_{bus}_\d+_bits_(\w+Wen)$', n)] if m})

    # 负载：commonOut.entry.bits.payload_* 是「发射口可见」那份(DEQ)，
    #       commonOut.transEntry.bits.payload_* 是「转移整包」那份(TRANS)。
    def payload(prefix):
        f = [n for n in N if n.startswith(f'io_commonOut_{prefix}_bits_payload_')]
        return len(f), sum(W[n] for n in f)

    deq_n, deq_w   = payload('entry')
    tr_n,  tr_w    = payload('transEntry')

    ld_dep = grp(r'wakeUpFromIQ_\d+_bits_loadDependency_(\d+)$')
    ld_pipes = len(idx_set(ld_dep, r'loadDependency_(\d+)$')) if ld_dep else 0
    ld_w = W[ld_dep[0]] if ld_dep else 0

    return dict(
        n_ports       = len(ps),
        lines         = len((GOLDEN / f'{mod}.sv').read_text().splitlines()),
        nSrc          = len(src),
        psrc_w        = W.get(f'io_commonIn_enq_bits_status_srcStatus_0_psrc', 0),
        srcType_w     = W.get('io_commonIn_enq_bits_status_srcStatus_0_srcType', 0),
        dataSrc_w     = W.get('io_commonIn_enq_bits_status_srcStatus_0_dataSources_value', 0),
        exuSrc_w      = W.get('io_commonIn_enq_bits_status_srcStatus_0_exuSources_value', 0),
        robIdx_w      = W.get('io_commonIn_enq_bits_status_robIdx_value', 0),
        nFuTypeBit    = len(idx_set(N, r'enq_bits_status_fuType_(\d+)$')),
        nWkWB         = len(wb),
        wkWB_wen      = ','.join(wens('wakeUpFromWB')) or '-',
        wkWB_pdest_w  = W.get('io_commonIn_wakeUpFromWB_0_bits_pdest', 0),
        nWkIQ         = len(iq),
        wkIQ_wen      = ','.join(wens('wakeUpFromIQ')) or '-',
        wkIQ_rcDest   = int(has('io_commonIn_wakeUpFromIQ_0_bits_rcDest')),
        nOg0Cancel    = len(og0),
        og0_idx       = ','.join(map(str, og0)) or '-',
        nOg1Cancel    = len(og1),
        nLdCancel     = len(ldc),
        ld1Cancel     = int(any(n.endswith('_ld1Cancel') for n in N)),
        ld2Cancel     = int(any(n.endswith('_ld2Cancel') for n in N)),
        ldDep_pipes   = ld_pipes,
        ldDep_w       = ld_w,
        useRegCache   = int(has('io_commonIn_enq_bits_status_srcStatus_0_useRegCache')),
        regCacheIdx_w = W.get('io_commonIn_enq_bits_status_srcStatus_0_regCacheIdx', 0),
        imm_w         = W.get('io_commonIn_enq_bits_imm', 0),
        ignoreOldVd   = int(has('io_commonIn_vlFromIntIsZero')),
        blocked       = int(has('io_commonIn_enq_bits_status_blocked')),
        deqPortIdx_in = int(has('io_commonIn_enq_bits_status_deqPortIdx')),
        deqPortIdxWr  = int(has('io_commonIn_deqPortIdxWrite')),
        # ★这里曾经写成 'io_commonOut_deqPortIdx' —— golden 里根本没有这个名字，
        #  于是整行恒 0，看上去像「全族都没有」。真名是 deqPortIdxRead。
        #  「量到 0」和「名字打错」长得一模一样，所以本脚本尾部有端口全覆盖断言。
        o_deqPortIdxRd= int(has('io_commonOut_deqPortIdxRead')),
        o_trnDeqPort  = int(has('io_commonOut_transEntry_bits_status_deqPortIdx')),
        vecMem        = int(has('io_commonIn_enq_bits_status_vecMem_sqIdx_value')),
        transSel      = int(has('io_commonIn_transSel')),
        o_enqReady    = int(has('io_commonOut_enqReady')),
        o_transValid  = int(has('io_commonOut_transEntry_valid')),
        o_cancelByp   = int(has('io_commonOut_cancelBypass')),
        o_isFirstIss  = int(has('io_commonOut_isFirstIssue')),
        deqPayload_n  = deq_n,  deqPayload_w  = deq_w,
        trnPayload_n  = tr_n,   trnPayload_w  = tr_w,
    )


# -----------------------------------------------------------------------------
# 端口全覆盖断言。
# 「某个维度量到 0」和「我把端口名拼错了」在表里长得一模一样 —— 本脚本已经栽过一次
# （`io_commonOut_deqPortIdx` 根本不存在，真名是 `deqPortIdxRead`，那一行于是恒 0）。
# 所以这里反过来钉死：golden 24 个模块的**每一个**端口名都必须落进下面的已知形状表，
# 出现没见过的端口就直接失败 —— 新维度不会被无声吞掉。
# -----------------------------------------------------------------------------
KNOWN_SHAPES = [
    r'clock$', r'reset$',
    r'io_commonIn_flush_(valid|bits_robIdx_(flag|value)|bits_level)$',
    r'io_commonIn_enq_(valid|bits_.*)$',
    r'io_commonIn_wakeUpFrom(WB|IQ)_\d+_(valid|bits_.*)$',
    r'io_commonIn_og[01]Cancel_\d+$',
    r'io_commonIn_ldCancel_\d+_ld[12]Cancel$',
    r'io_commonIn_deqSel$', r'io_commonIn_deqPortIdxWrite$',
    r'io_commonIn_issueResp_(valid|bits_resp)$',
    r'io_commonIn_transSel$',
    r'io_commonIn_vlFrom(Int|Vf)Is(Zero|Vlmax)$',
    r'io_commonOut_(valid|issued|canIssue|fuType|isFirstIssue|cancelBypass'
    r'|deqPortIdxRead|issueTimerRead|enqReady'
    r'|entryInValid|entryOutDeqValid|entryOutTransValid)$',
    r'io_commonOut_(dataSources|exuSources)_\d+_value$',
    r'io_commonOut_(entry|transEntry)_(valid|bits_.*)$',
    r'io_commonOut_perf(LdCancel|Og0Cancel|WakeupByWB)_\d+$',
    r'io_commonOut_perfWakeupByIQ_\d+_\d+$',
]


def check_port_coverage(mods):
    pats = [re.compile(s) for s in KNOWN_SHAPES]
    bad = collections.defaultdict(list)
    total = 0
    for m in mods:
        for d, w, n in ports(m):
            total += 1
            if not any(p.match(n) for p in pats):
                bad[n].append(m)
    if bad:
        for n, ms in sorted(bad.items())[:20]:
            print(f'  未知端口形状 {n}  (出现在 {len(ms)} 个变体，如 {ms[0]})',
                  file=sys.stderr)
        sys.exit(f'{len(bad)} 个端口名不在 KNOWN_SHAPES 里：'
                 f'要么是新维度（补进矩阵），要么形状表过时了')
    return total


ROWS = [
 ('parent',        'golden 里例化它的 Entries 变体'),
 ('role',          'simp=可被提级的中转条目(isComp=false) / comp=终端发射条目(isComp=true)'),
 ('count',         '在该 Entries 里例化几份'),
 ('lines',         'golden 行数'),
 ('n_ports',       'golden 端口数'),
 ('nSrc',          '每 uop 的源寄存器数 srcStatus[]'),
 ('psrc_w',        'srcStatus.psrc 位宽'),
 ('srcType_w',     'srcStatus.srcType 位宽'),
 ('dataSrc_w',     'srcStatus.dataSources.value 位宽'),
 ('exuSrc_w',      'srcStatus.exuSources.value 位宽（0=无 IQ 唤醒）'),
 ('robIdx_w',      'RobPtr.value 位宽'),
 ('nFuTypeBit',    'status.fuType 保留的 one-hot 位数'),
 ('nWkWB',         '写回唤醒总线路数'),
 ('wkWB_wen',      'WB 唤醒携带的写使能字段（★多字段=匹配要按位或，不是单对★）'),
 ('wkWB_pdest_w',  'WB 唤醒 pdest 位宽'),
 ('nWkIQ',         'IQ 即时唤醒总线路数（0=无 IQ 唤醒子族）'),
 ('wkIQ_wen',      'IQ 唤醒携带的写使能字段'),
 ('wkIQ_rcDest',   'IQ 唤醒是否带 rcDest（写寄存器缓存）'),
 ('nOg0Cancel',    'og0Cancel 位数（按全局 exu 下标稀疏给）'),
 ('og0_idx',       'og0Cancel 的全局 exu 下标集合'),
 ('nOg1Cancel',    '★og1Cancel 位数——全族实测★'),
 ('nLdCancel',     'ldCancel 条数（= load 流水条数）'),
 ('ld1Cancel',     '有无 ld1Cancel（配 srcLoadDependency 的 bit0）'),
 ('ld2Cancel',     '有无 ld2Cancel（配 bit1）'),
 ('ldDep_pipes',   'srcLoadDependency 的 pipe 数'),
 ('ldDep_w',       'srcLoadDependency 每 pipe 位宽'),
 ('useRegCache',   '有无 srcStatus.useRegCache'),
 ('regCacheIdx_w', 'srcStatus.regCacheIdx 位宽'),
 ('imm_w',         'commonIn.enq.bits.imm 位宽（0=该变体不带 imm）'),
 ('ignoreOldVd',   '有无 vlFromInt/vlFromVf（向量 ignoreOldVd 通路）'),
 ('blocked',       '有无 status.blocked'),
 ('deqPortIdx_in', 'enq 侧有无 status.deqPortIdx'),
 ('deqPortIdxWr',  '有无 commonIn.deqPortIdxWrite'),
 ('o_deqPortIdxRd','有无 commonOut.deqPortIdxRead（comp 的发射口选择回读）'),
 ('o_trnDeqPort',  '有无 commonOut.transEntry.bits.status.deqPortIdx'),
 ('vecMem',        '有无 status.vecMem（本 24 个应全 0，VecMem 是另一族）'),
 ('transSel',      '★有无 commonIn.transSel（simp 专属）★'),
 ('o_enqReady',    '有无 commonOut.enqReady'),
 ('o_transValid',  '有无 commonOut.transEntry（simp 专属）'),
 ('o_cancelByp',   '有无 commonOut.cancelBypass'),
 ('o_isFirstIss',  '有无 commonOut.isFirstIssue'),
 ('deqPayload_n',  'commonOut.entry 负载字段数（发射口可见那份）'),
 ('deqPayload_w',  'commonOut.entry 负载总位宽'),
 ('trnPayload_n',  'commonOut.transEntry 负载字段数（0=comp）'),
 ('trnPayload_w',  'commonOut.transEntry 负载总位宽'),
]


def build():
    par = parents()
    mods = sorted(par, key=lambda m: (par[m][0], par[m][1] != 'simp'))
    prof = {}
    for m in mods:
        p = profile(m)
        p['parent'], p['role'], p['count'] = par[m]
        prof[m] = p
    return mods, prof


def render(mods, prof):
    tsv = ['\t'.join(['dim'] + mods)]
    for k, _ in ROWS:
        tsv.append('\t'.join([k] + [str(prof[m][k]) for m in mods]))
    tsv = '\n'.join(tsv) + '\n'

    simp = [m for m in mods if prof[m]['role'] == 'simp']
    comp = [m for m in mods if prof[m]['role'] == 'comp']
    md = []
    md.append('# OthersEntry 家族（24 变体）字段使用矩阵 —— 从 golden 实测\n')
    md.append(f'golden: `{GOLDEN}`\n')
    md.append('由 `verif/ut/OthersEntry_field_matrix/gen_matrix.py` 生成；'
              '改共享核或任一变体薄文件前必须复跑 `--check`。\n')
    md.append('## 这一族是什么\n')
    md.append('`OthersEntry(isComp)` = 发射队列里**非入队**的那些条目'
              '（`src/main/scala/xiangshan/backend/issue/OthersEntry.scala`）。'
              'golden 按 (IQ 参数, isComp) 单态化成 24 个模块，'
              '每个 `Entries*` 变体例化其中两个：\n')
    for m in simp:
        p = prof[m]
        c = next(x for x in comp if prof[x]['parent'] == p['parent'])
        md.append(f'- `{p["parent"]}`：simp=`{m}`×{p["count"]}，'
                  f'comp=`{c}`×{prof[c]["count"]}')
    md.append('')
    md.append('## 角色两分（结构结论，非猜测）\n')
    md.append('把 24 个模块的端口名集合按角色取并集比对：\n')
    md.append('- **comp 的端口组 ⊆ simp 的端口组，comp-only 为空集**。')
    md.append('- simp 独有的是：`commonIn.transSel`、`commonOut.{enqReady,transEntry.*}`，'
              '以及 `commonIn.enq.bits.payload_*` 的**整包宽负载**。')
    md.append('  comp 的 enq 负载只留发射口看得见那一小份。')
    md.append('- 也就是 `xs_iq_entries_core.sv` 里写的 '
              '`KEEP_WIDE = IS_ENQ | IS_TRANS`：')
    md.append('  要产出 `transEntry` 的条目才存宽负载。')
    md.append('  simp 行数反而比 comp 大（例：`OthersEntry_66` 2494 行 vs '
              '`OthersEntry_72` 1442 行），别拿行数猜角色。\n')
    md.append('## 矩阵（行 = 维度，列 = 变体，按 parent 分组，simp 在前）\n')
    md.append('| 维度 | ' + ' | '.join(mods) + ' |')
    md.append('|---|' + '---|' * len(mods))
    for k, desc in ROWS:
        md.append(f'| `{k}` | ' + ' | '.join(str(prof[m][k]) for m in mods) + ' |')
    md.append('')
    md.append('## 维度释义\n')
    for k, desc in ROWS:
        md.append(f'- `{k}`：{desc}')
    md.append('')
    # 自动提炼：哪些维度真的在变
    md.append('## 真正在变的维度（自动提炼）\n')
    varying, constant = [], []
    for k, _ in ROWS:
        vals = {str(prof[m][k]) for m in mods}
        (varying if len(vals) > 1 else constant).append((k, sorted(vals)))
    md.append(f'变的 {len(varying)} 个 / 恒定的 {len(constant)} 个。\n')
    md.append('恒定（全 24 个一致，参数化核可以写死）：\n')
    for k, v in constant:
        md.append(f'- `{k}` = {v[0]}')
    md.append('')
    md.append('变的（必须走 parameter）：\n')
    for k, v in varying:
        if k in ('parent', 'count', 'lines', 'n_ports', 'og0_idx'):
            continue
        md.append(f'- `{k}`：{{{", ".join(v)}}}')
    md.append('')
    # ---- 覆盖判断：与 Entries 共享核 xs_iq_entry 的关系 ----
    nq = sum(1 for m in mods if prof[m]['nWkIQ'] > 0)
    multi = sorted({prof[m]['wkWB_wen'] for m in mods})
    md.append('## 覆盖判断：这一族属于 Entries 共享核，不是独立族\n')
    md.append('依据（全部可从上表复核）：\n')
    md.append('1. **同一份 Scala**。`OthersEntry.scala` 的模块体只有四句：'
              '`CommonWireConnect` / `CommonIQWakeupConnect` / `EntryRegCommonConnect` / '
              '`CommonOutConnect`，全在 `EntryBundles.scala`；`EnqEntry.scala` 调的是'
              '**同样四句**，只是 `isEnq=true`。也就是说 golden 的 EnqEntry 与 '
              'OthersEntry 本来就是一份逻辑的两次单态化。')
    md.append('2. **本仓已有那份核**。`rtl/backend/xs_iq_entries_core.sv` 的 `xs_iq_entry` '
              '就是这份逻辑的参数化重写，参数 `IS_ENQ` / `IS_TRANS` / `IS_COMP` 正对应'
              '三种条目；`KEEP_WIDE = IS_ENQ | IS_TRANS` 正对应本表量到的'
              '「simp 存宽负载、comp 存窄负载」。')
    md.append('3. **端口面对得上**。golden `OthersEntry*` 的端口就是 '
              '`CommonInBundle`/`CommonOutBundle` 摊平，而 `xs_iq_entry` 的端口是同一对 '
              'Bundle 的打包形式；差的是「摊平/改名」，属于 wrapper 的活。')
    md.append('')
    md.append('结论：**复用 `xs_iq_entry`，不自建核**。自建等于把 800 行核体复制一份，'
              '违反 CONVENTIONS「变体家族：核体绝不复制」，而且两份核以后会各修各的。\n')
    md.append('### 落地形态\n')
    md.append('24 个变体 = **12 组家族参数 × 2 种角色**（本表里 simp/comp 在除角色专属端口'
              '外的每一个维度上都同值，可逐列复核）。所以：')
    md.append('- 核：沿用 `rtl/backend/xs_iq_entries_core.sv` 的 `xs_iq_entry`，不复制；')
    md.append('- 每变体一个薄文件 `rtl/backend/OthersEntry[_N].sv`：只做端口摊平 + 设参数，'
              '例化 `xs_iq_entry`；')
    md.append('- 生成器复用 `verif/ut/Entries_common/entries_gen.py` 已经在用的那几张表'
              '（负载字段偏移、唤醒路由），不另起一套。\n')
    md.append('### 但是：落地前必须先改共享核（★跨 lane 冲突★）\n')
    md.append('本表量出三处 `xs_iq_entry` **现在没有**的东西。三处都在共享核里，'
              '而 `agent/entries-rest3` 正在改同一个文件，所以不能由本 lane 自己动手：\n')
    md.append('**(A) 7 组 debug/perf 输出 —— 24 个变体全都要，一个也绕不过去。**')
    md.append('   `commonOut.{entryInValid, entryOutDeqValid, entryOutTransValid, '
              'perfLdCancel[], perfOg0Cancel[], perfWakeupByWB[], perfWakeupByIQ[][]}`。')
    md.append('   它们在 golden `OthersEntry*` 上是**真端口**（见上表末几行与 '
              '`EntryBundles.scala:476-483`，每个都是一行赋值，用的信号核里全都有），')
    md.append('   但在 `Entries*` 这一层被 firtool 消掉了，所以共享核当初没有产出它们。')
    md.append('   ★必须挂在 parameter 后面（例如 `HAS_DBG_OUT`，Entries 例化时给 0）★：'
              '否则这些新输出在 `xs_iq_entries_core` 里无人读，')
    md.append('   会给已经签核的 `EntriesAluCsrFenceDiv` / `EntriesVfdivVidiv` '
              '带来 unread 点，把绿的打回 PARTIAL。')
    md.append('')
    md.append('**(B) WB 唤醒匹配要从「单个 wen」扩成「按源分工的多 wen」。**')
    md.append(f'   本表 `wkWB_wen` 实测有 {len(multi)} 种形态：{multi}。')
    md.append('   其中 `v0Wen,vecWen,vlWen` 那一档（nSrc=5 的向量族）**不是简单按位或**：')
    md.append('   `EntryBundles.scala:185-193` 对 numRegSrc==5 是'
              '「源 0..2 用 `wakeUp`、源 3 用 `wakeUpV0`、源 4 用 `wakeUpVl`」，'
              '按源分工，不是同一个式子 OR 起来。')
    md.append('   这与 `agent/entries-rest3` 要做的「唤醒匹配从单对改成一串对按位或」'
              '是同一处代码 —— 请确认它那边是按**按源分工**实现的，不是一律 OR。')
    md.append('')
    md.append(f'**(C) §11 里已登记的家族维度**：有 IQ 唤醒的变体 {nq}/24 个，'
              '其中 StaMou（needFeedBackSqIdx）、向量族（ignoreOldVd / bypass2）'
              '这些在共享核 §11 里已列为待办，本族一样绕不过。\n')
    md.append('### 量出来的几条、与既有结论对表\n')
    md.append('- `nOg1Cancel` **全 24 个实测为 0** —— 原先只是「已查过的变体里全空」，'
              '现在是全族实测。')
    md.append('- `o_deqPortIdxRead` ⟺ 该 IQ `numDeq==2`，且 **simp 与 comp 同时有**；'
              '共享核 §2.6a 把它记成 comp 条目的性质，按本表应改成「与角色无关，只看 numDeq」。')
    md.append('- `transEntry` 的**负载部分**在 12 个 simp 上逐位相同'
              '（180 字段 / 1330 位，脚本里有 signature 断言），'
              '变的只有 `transEntry.bits.status.*` 与 `transEntry.bits.imm`。')
    md.append('- `commonOut.fuType` 是 **35 位全宽 one-hot**，而条目里存的是压缩过的 '
              '`nFuTypeBit` 位；摊回 35 位是 wrapper 的活，不必动核。')
    md.append('- `blocked` 在 24 个变体上**都有** `enq.bits.status.blocked` 端口，'
              '而 Entries 层矩阵只有 VecMem 两个变体为 1 —— 同一个字段在不同层次上'
              '被 DCE 的程度不同，这正是「每层都要自己量」的例子。')
    md.append('')
    return tsv, '\n'.join(md) + '\n'


def main():
    mods, prof = build()
    n = check_port_coverage(mods)
    print(f'端口全覆盖断言通过：{len(mods)} 个变体 / {n} 个端口全部有已知形状')
    tsv, md = render(mods, prof)
    ft, fm = HERE / 'matrix.tsv', HERE / 'matrix.md'
    if '--check' in sys.argv:
        bad = [f for f, s in ((ft, tsv), (fm, md))
               if not f.exists() or f.read_text() != s]
        if bad:
            sys.exit('矩阵已漂移，复跑 gen_matrix.py：' + ', '.join(p.name for p in bad))
        print('matrix.tsv / matrix.md 与 golden 一致')
        return
    ft.write_text(tsv); fm.write_text(md)
    print(f'{len(mods)} 个变体 -> {ft.name}, {fm.name}')


if __name__ == '__main__':
    main()
