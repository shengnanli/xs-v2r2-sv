#!/usr/bin/env python3
"""rewrite_coverage.py —— 重写覆盖率台账（codex 0161 要求的三个独立指标）。

**为什么要有这张表**：
"253/253" 是 **FM 目标集**的口径，很容易被读成"重写完成了"。实测不是 ——
那 253 个目标里绝大多数是中小模块及其**单态化变体族**（SRAMTemplate 42 个变体、
NewPipelineConnectPipe 18 个、ICacheMSHR 14 个…），而主干（Rob / Backend /
CtrlBlock / Predictor / StoreQueue / 各类 Entries）基本没动。

codex 0161 的原话：

    From now on keep these three metrics separate in every report:
      1. FM target status: 253/253 for the currently configured target set.
      2. Unique readable-design coverage.
      3. Golden-line replacement coverage.
    Do not describe 253/253 as completion of the RTL rewrite.
    ...
    Maintain an explicit remaining-universe ledger by unique design and by golden
    source lines. **Variant FM receipts remain useful but must not inflate rewrite
    coverage.**

最后那句是本脚本的设计约束：**同一个设计的 N 个变体只算一个设计**，
而按行数统计时每个变体的 golden 行数**都算**（因为它们确实各占一份 golden 源码）。

## 三个口径分别是什么

- **FM 目标**：`verif/ut/*/Makefile` 的 `FM_VARIANTS` 并集。这是"跑了证明的东西"。
- **不同设计**：golden 模块名去掉尾部 `_<数字>` 后的不同基名。这是"讲清了多少种机制"。
- **golden 行数**：每个 golden 模块定义所在文件的行数。这是"替换掉了多少源码"。

## ★2026-09-16：把"已重写"的判据从「文件在不在」改成「有没有证据」★

原判据是 `rewritten_modules()` = `glob('rtl/**/*.sv')` 抓 module 名 —— 即
**"rtl/ 里有同名 module" 就算已重写**。LoadQueueReplay 的考古 worker 实测发现这是个
**假绿口子**：把一个 3,149 行、只实现约两成逻辑的**骨架**放进 rtl/，覆盖率立刻
从 7.4% 跳到 11.0%（凭空记账 138,860 行 golden），而任何人放个空壳进去都会如此。

这正是本仓其他闸一直在防的形态，结果出现在覆盖率台账自己身上。

修法**不是**加一张 WIP 声明表 —— 声明会忘、会过期，是 fail-open 的。改成按**证据**记账：

    written  模块名出现在 rtl/           （原口径，保留，但不再当头条数字）
    proven   written 且有绿判决证据      （★头条数字★）

绿判决证据 = `docs/fm_round_20260914.tsv` 里 SUCCEEDED / PASS_DEAD_REF，
或 `docs/fastlane_ledger.tsv` 里 WORKING_PASS / WORKING_PASS_DEAD_REF。
骨架没有 UT、没有 FM，于是自然记 0 —— 不需要谁记得去声明它是骨架。

实测口径切换的代价很小：105 个计入的设计族里 **98 个本来就有绿判决证据**，
无证据的 7 个只占 6,944 行（2.4%），且各有已文档化的原因（StorePipe 是
EXPLICITLY_UNPROVABLE、OpenLLC 是资源阻塞…）。它们现在落进 written 而不进 proven，
两个数并排列出，谁都看得见差在哪。

## 排除项（都有理由，且在输出里显式列出）

- 厂商存储宏 / 行为级 RAM（`array_*` / `ram_*` / `*_ext`）：两侧同源黑盒，不是重写对象。
- MBIST / DFT 扫描件：扫描链基础设施。
- `LogPerfEndpoint`：9903 端口全是 input 的纯观测 sink，19 万行全是端口表，
  计进分母会让覆盖率失真。**它被排除这件事本身要显示出来**，不能悄悄扣掉。
"""
import argparse
import collections
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from rewritten_floor import classify_rtl, counts_as_written
from gen_xstile_closure import load as load_tile_closure

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
OUT = REPO / 'docs' / 'rewrite_coverage.tsv'

MODULE_RE = re.compile(r'^module\s+([A-Za-z_]\w*)', re.M)
VARIANT_RE = re.compile(r'_\d+$')

def _norm_ws(s):
    return re.sub(r'\s+', ' ', s).strip()


def firtool_memory_shape(text):
    """golden 文件正文是不是**纯** firtool 行为级存储模型 → (depth, width, n_read, n_write) / None。

    ★按结构认，不按名字认★（2026-10-17，floor-classifier lane）。模板 = firtool 给
    `SyncReadMem`/`Mem` 生成的叶子，读口全是组合读、写口共用 W0_clk 一个 always 块：

        reg [W-1:0] Memory[0:D-1];
        always @(posedge W0_clk) begin
          if (Wk_en & 1'h1)          Memory[Wk_addr] <= Wk_data;                    // 无掩码
          if (Wk_en & Wk_mask[j])    Memory[Wk_addr][32'hOFF +: G] <= Wk_data[..];  // 按段掩码
        end
        assign Rk_data = Rk_en ? Memory[Rk_addr] : W'bx;

    （外加 `ifdef ENABLE_INITIAL_MEM_ 仿真初值块，SYNTHESIS 下不存在，先剥掉。）
    与 mc_memory_registry.derive 的 1R1W 模板同一套写法，只是读口/写口数与掩码段数
    从端口表现读 —— 期望正文**逐字重建后整段比对**，多一条 assign / 一个别的寄存器 /
    一处位选不同都当场不认。端口名、端口顺序、位宽也全部要对上。
    """
    i = text.find('\nmodule ')
    body = text[i + 1:] if i >= 0 else text
    body = re.sub(r'`ifdef ENABLE_INITIAL_MEM_.*?`endif // ENABLE_INITIAL_MEM_', '',
                  body, flags=re.S)
    body = re.sub(r'/\*.*?\*/', ' ', body, flags=re.S)
    body = re.sub(r'//[^\n]*', '', body)
    m = re.match(r'\s*module\s+\w+\s*\((.*?)\);(.*)$', body, re.S)
    if not m:
        return None
    ports = []
    for d in m.group(1).split(','):
        d = _norm_ws(d)
        pm = re.fullmatch(r'(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+)', d)
        if not pm:
            return None
        ports.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    pw = {n: (d, w) for d, w, n in ports}
    if len(pw) != len(ports) or 'R0_data' not in pw or 'W0_data' not in pw:
        return None
    width = pw['R0_data'][1]
    mm = re.match(r'\s*reg \[(\d+):0\] Memory\[0:(\d+)\];', m.group(2))
    if not mm or int(mm.group(1)) + 1 != width:
        return None
    depth = int(mm.group(2)) + 1
    aw = pw.get('R0_addr', (None, 0))[1]
    if (1 << aw) < depth:
        return None
    nr = 0
    while 'R%d_data' % nr in pw:
        nr += 1
    nw = 0
    while 'W%d_data' % nw in pw:
        nw += 1
    want_ports = []
    for k in range(nr):
        want_ports += [('input', aw, 'R%d_addr' % k), ('input', 1, 'R%d_en' % k),
                       ('input', 1, 'R%d_clk' % k), ('output', width, 'R%d_data' % k)]
    writes = []
    for k in range(nw):
        want_ports += [('input', aw, 'W%d_addr' % k), ('input', 1, 'W%d_en' % k),
                       ('input', 1, 'W%d_clk' % k), ('input', width, 'W%d_data' % k)]
        mk = 'W%d_mask' % k
        if mk in pw:
            nseg = pw[mk][1]
            if nseg < 1 or width % nseg:
                return None
            g = width // nseg
            want_ports.append(('input', nseg, mk))
            for j in range(nseg):
                writes.append("if (W%d_en & W%d_mask[%d]) Memory[W%d_addr][32'h%X +: %d] "
                              "<= W%d_data[%d:%d];"
                              % (k, k, j, k, j * g, g, k, j * g + g - 1, j * g))
        else:
            writes.append("if (W%d_en & 1'h1) Memory[W%d_addr] <= W%d_data;" % (k, k, k))
    if ports != want_ports or nr == 0 or nw == 0:
        return None
    want = ' '.join(
        ['reg [%d:0] Memory[0:%d];' % (width - 1, depth - 1),
         'always @(posedge W0_clk) begin'] + writes + ['end'] +
        ["assign R%d_data = R%d_en ? Memory[R%d_addr] : %d'bx;" % (k, k, k, width)
         for k in range(nr)] + ['endmodule'])
    got = _norm_ws(m.group(2))
    got = got[:got.index('endmodule') + len('endmodule')] if 'endmodule' in got else got
    if got.lower() != _norm_ws(want).lower():
        return None
    return depth, width, nr, nw


_MC_REG = None


def _mc_registered():
    """verif/mc_memory_registry.tsv 登记的 design 名（codex 0222：存储层不重写、由 MC 替换）。
    表坏了直接抛 —— 覆盖率台账不许在存储契约表读不出来时 fail-open。"""
    global _MC_REG
    if _MC_REG is None:
        import mc_memory_registry as MC
        _MC_REG = set(MC.load_registry())
    return _MC_REG


# behavioral_ram 家族名（与 g1_configured_universe.EXCL_PATTERNS / g1_leaf_audit.CLASSES
# 同一份口径）里，本表原先漏收的那一支。★光有名字不算★：还必须过上面的结构模板。
_DATA_MEM_FAMILY = re.compile(r'^data_mem_')


def is_behavioral_memory(name, golden_dir=None):
    """这个 golden 模块是不是**存储模型**（按规矩不重写，由 MC 替换）。

    两条，任一成立即是：
      1. verif/mc_memory_registry.tsv 里登记了它 —— 登记表是存储契约的权威出处，
         表里有的必须归存储，否则台账与契约表互相矛盾；
      2. 名字属于 behavioral_ram 家族（`data_mem_*`）**且** golden 正文逐字等于
         firtool 行为级存储模板（firtool_memory_shape）。名字像、正文夹带了别的逻辑 → 不收。

    ★为什么 2 要名字和结构同时成立★：结构模板单独用会把 stateBankTags_320x3 /
    dt_pcTransType_160x2 / diff_rat_state_bank_320x776 这类**正文也是纯存储**、但工程里
    另有 lane 在按普通模块记账的叶子一并收走（它们不在 universe 的 behavioral_ram 家族里）。
    那是另一个口径决定，不该由一次漏收修复顺手做掉。
    """
    if name in _mc_registered():
        return True
    if not _DATA_MEM_FAMILY.match(name):
        return False
    g = pathlib.Path(golden_dir) if golden_dir else GOLDEN
    f = g / (name + '.sv')
    if not f.is_file():
        return False
    return firtool_memory_shape(f.read_text(errors='replace')) is not None


# 排除类：(判据, 名称, 为什么排除)
EXCLUSIONS = [
    (lambda n: re.match(r'^(array|ram|sram)_', n) or n.endswith('_ext'),
     'vendor_macro', '厂商存储宏/行为级RAM：两侧同源黑盒，不是重写对象'),
    # ★2026-10-17 补★：上一条的名字表是 `array|ram|sram`，比 universe 的 behavioral_ram
    # 家族（g1_configured_universe.EXCL_PATTERNS 有 `^data_mem_`）少一支，于是
    # data_mem_8x4 / data_mem_16x12（2R1W 按段掩码）与 MC 登记表里的 data_mem_0_8x3 /
    # data_mem_0_4x2 一直挂在「剩余待重写」里。按结构 + 登记表认，见 is_behavioral_memory。
    (is_behavioral_memory,
     'mc_memory_model', '行为级存储模型（MC 登记表 / firtool 存储模板）：按规矩不重写，由 MC 替换'),
    (lambda n: 'Mbist' in n or n.startswith('BoreBd'),
     'mbist_dft', 'MBIST/DFT 扫描链基础设施'),
    (lambda n: n == 'LogPerfEndpoint',
     'observation_sink', '9903 端口全 input 的纯观测 sink，19 万行全是端口表'),
]


def classify(name):
    for pred, tag, _ in EXCLUSIONS:
        if pred(name):
            return tag
    return None


def golden_modules():
    """{module_name: (file, lines)}"""
    out = {}
    for f in sorted(list(GOLDEN.glob('*.sv')) + list(GOLDEN.glob('*.v'))):
        txt = f.read_text(errors='replace')
        n = len(txt.splitlines())
        for m in MODULE_RE.finditer(txt):
            out[m.group(1)] = (f.name, n)
    return out


def rewritten_modules():
    """可读侧**声明且过了驱动下限**的模块名集合（written 口径）。

    ★2026-09-21 加下限★：原判据只问"rtl/ 里有没有这个 module 名"，于是一个
    只抄了端口表、模块体空着的骨架照样计进 written。实测后果：StoreQueue 的
    77145 golden 行进了 written，而它的核驱动 0/241 条输出、UT VERIFIED=0/399。
    上面那段注释本来就写着"不说明它写完了"——问题是它照样在算分。

    现在改成 scripts/rewritten_floor.py 的驱动闭包判据：输出得真被驱动，
    而且驱动链要落到真逻辑或外部黑盒上（壳接空核不算）。它只判"驱动没驱动"，
    不判"驱动得对不对"——对不对是 FM 的事，那是 proven 口径管的。
    反证过：全树 719 个模块里，凡 FM 判过 SUCCEEDED 的，没有一个掉出这道下限。
    """
    out = set()
    for name, v in classify_rtl().items():
        tier = v[0]   # ★按下标取，不按元组宽度解包★（该元组 2026-09-21 加过第 5 列）
        if counts_as_written(tier):
            out.add(name)
    return out


_CANON = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*$')


def _add_canonical(dst, name, src):
    """把台账里的目标名收进集合，★非 canonical 的一律拒绝并出声★（codex 0169 D1）。

    实测事故：docs/fm_round_20260914.tsv:14 的目标名写成 `Bku(vmucp)` ——
    那不是模块名，是「Bku 这一跑开了 vmucp」的随手注记混进了 target 列。
    旧代码照单全收，于是集合里多出一个匹配不到任何 universe 成员的名字，
    **贡献 0 行、不影响任何百分比、也不报错** —— 一个静默的幽灵项。

    幽灵项本身不改数字，但它证明这一列没人校验；同一个位置写错一个**真**模块名
    （比如 `Bku` 写成 `BKU`）就会静默少计一个目标，那才是它真正的危险。
    codex 0169 D1：「必须由解析器拒绝或规范化，不能静默形成 0 行幽灵项。」

    这里选**拒绝并出声**而不是规范化：把 `Bku(vmucp)` 规范成 `Bku` 是在替写台账的人
    猜意图，而猜错的代价是凭空多算一个 proven。
    """
    if _CANON.match(name):
        dst.add(name)
        return
    sys.stderr.write('rewrite_coverage: ★拒收非 canonical 目标名★ %r（来自 %s）'
                     ' —— 台账的 target 列只许是模块名\n' % (name, src))


def stale_impl_targets():
    """★当前实现字节与 receipt 认证的不一致 -> 不是当前 proven★（codex 0170，选 A）。

    判据同 `gen_receipt_harvest.py` 的 chk_impl()：receipt 的 impl_closure 里每个
    kind=repo 文件的 sha256 必须等于仓里当前字节。★但这里不读收录表，直接对
    **已跟踪的** receipt 逐份算★ —— 2026-09-22 两次实测逼出来的：

      第一版读收录表的 chk_impl 列：收录表会扫 lane worktree，把**尚未合入**的新
      receipt 选成 lead（in_vcs=no）。6 个 Entries* 在 wt-entrerun 刚跑出新证据、
      还没合并时就被判"不陈旧"，而 proven 真正数进去的仍是 round 台账里那份
      **陈旧的、已跟踪的**旧 receipt —— 一份没进仓的证据给一份过期的证据背书，
      proven 凭空 +203,341 行。
      第二版加了 in_vcs==yes：又**多排了 8,573 行**——lead 是 lane 里的新 receipt
      （in_vcs=no）时，表里看不见那份仍然匹配的旧跟踪 receipt，于是被误判陈旧。

    收录表的 lead 选择回答的是"哪一份最该收"，不是"main 上有没有一份仍然成立的"。
    两个问题不能共用一列。所以这里直接问后者：
      目标不陈旧 ⟺ 存在一份**已跟踪、绿判决**的 receipt，其 impl_closure 全部字节仍等于当前仓。
    codex 0170：「current proven」= 当前 main 字节 + 已跟踪 receipt。

    实测反例仍是 OthersEntry：两条互不为祖先的并行 lane（29dd150a 改共享核 API /
    809aebb6 签核）分别合入后，整族坏到连 elaborate 都过不去，而 30 份 tracked receipt
    照样让台账记绿，直到 check_param_override 偶然撞见。★靠"下次注意"防不住。★
    """
    import hashlib
    import json
    import subprocess
    try:
        rels = subprocess.check_output(
            ['git', '-C', str(REPO), 'ls-files', 'evidence/*/receipt.json']).decode().split()
    except Exception:
        sys.stderr.write('rewrite_coverage: ★列不出已跟踪 receipt★ —— STALE_IMPL 判据未生效\n')
        return set()
    _sha_cache = {}

    def sha(path):
        if path not in _sha_cache:
            p = REPO / path
            try:
                _sha_cache[path] = hashlib.sha256(p.read_bytes()).hexdigest()
            except OSError:
                _sha_cache[path] = None
        return _sha_cache[path]

    seen, fresh = set(), set()
    for rel in rels:
        parts = rel.split('/')
        if len(parts) < 4:
            continue
        tgt = parts[2]
        try:
            d = json.loads((REPO / rel).read_text())
        except Exception:
            continue
        if d.get('verdict') not in ('SUCCEEDED', 'PASS_DEAD_REF'):
            continue
        seen.add(tgt)
        ok = True
        for e in (d.get('impl_closure') or []):
            if e.get('kind') != 'repo':
                continue
            if sha(e.get('path', '')) != e.get('sha256'):
                ok = False
                break
        if ok:
            fresh.add(tgt)
    return seen - fresh


def proven_modules():
    """有**绿判决证据**的模块名集合（proven 口径，头条数字用它）。

    证据只认已提交的台账，都是机器产物、可复算：
      docs/fm_round_*.tsv          SUCCEEDED / PASS_DEAD_REF
      docs/fastlane_ledger.tsv     WORKING_PASS / WORKING_PASS_DEAD_REF（UT+FM 都过）

    ★2026-09-17 修：round 台账原先**写死**成 fm_round_20260914.tsv 一份★
    后果是每开一轮新的签核，proven 就原地不动 —— written 在涨、proven 不涨，
    看上去像"写了一堆没证"，实际是记账口径漏了新台账。改成 glob 之后，
    新增一轮只要落一份 docs/fm_round_<日期>.tsv 就自动计入，不需要改代码
    （"不需要任何人记得做什么"这条原则，对台账本身也得成立）。

    ★为什么不接受"声明自己写完了"★：声明是 fail-open 的 —— 忘了写、写错、过期，
    都会让覆盖率虚高，而虚高的覆盖率正是本仓在防的那类假绿。证据式记账不需要
    任何人记得做什么：没跑出绿判决，就不计分。
    """
    ok = set()
    rounds = sorted((REPO / 'docs').glob('fm_round_*.tsv'))
    for rnd in rounds:
        for l in rnd.read_text(errors='replace').splitlines():
            if l.startswith('#') or l.startswith('target'):
                continue
            c = l.split('\t')
            if len(c) > 1 and c[1] in ('SUCCEEDED', 'PASS_DEAD_REF'):
                _add_canonical(ok, c[0], rnd.name)
    led = REPO / 'docs' / 'fastlane_ledger.tsv'
    if led.exists():
        for l in led.read_text(errors='replace').splitlines():
            if l.startswith('#'):
                continue
            c = l.split('\t')
            if len(c) > 1 and c[1] in ('WORKING_PASS', 'WORKING_PASS_DEAD_REF'):
                _add_canonical(ok, c[0], led.name)
    if not ok:
        raise SystemExit('proven_modules: %d 份 round 台账 + fastlane 台账都读不出绿判决'
                         ' —— 拒绝按 0 继续' % len(rounds))
    return ok


def fm_targets():
    """FM 目标全集 —— ★用仓里的 make 权威引擎，不要自己写正则★。

    本轮 D70 已经证明过：正则解析 `FM_VARIANTS` 是个**缺陷模型**（它不展开
    `$(VARIANTS)` 之类的变量，实测 248 vs 权威 272，漏 24 个）。我第一版这里
    照样写了正则，解析出 250 而实际是 253 —— 同一个坑第二次。改用
    `fm_target_universe.targets_at()`（make 展开 git archive 出的临时树，
    engine='both' 时与正则交叉校验、不一致就 fail-closed 抛 EngineDisagree）。
    """
    import subprocess
    sys.path.insert(0, str(REPO / 'scripts'))
    import fm_target_universe as U
    head = subprocess.check_output(['git', 'rev-parse', 'HEAD'],
                                   cwd=str(REPO)).decode().strip()
    tmap, unresolved = U.targets_at(str(REPO), head)
    if unresolved:
        raise SystemExit('fm_target_universe 未完全展开: %s' % unresolved[:3])
    return set(tmap)


def build():
    gold = golden_modules()
    done = rewritten_modules()
    # ★codex 0170 选 A：chk_impl != same 的一律不计当前 proven★
    stale = stale_impl_targets()
    prov = (rewritten_modules() & proven_modules()) - stale
    targets = fm_targets()

    excl = collections.Counter()
    real = {}
    for name, (f, n) in gold.items():
        tag = classify(name)
        if tag:
            excl[tag] += 1
        else:
            real[name] = (f, n)

    base = lambda n: VARIANT_RE.sub('', n)
    fam = collections.defaultdict(list)
    for name in real:
        fam[base(name)].append(name)

    fam_done = {b for b, ms in fam.items() if any(m in done for m in ms)}
    fam_prov = {b for b, ms in fam.items() if any(m in prov for m in ms)}
    lines_tot = sum(n for _, n in real.values())
    lines_done = sum(n for m, (_, n) in real.items() if m in done)
    lines_prov = sum(n for m, (_, n) in real.items() if m in prov)

    rows = []
    rows.append('# 重写覆盖率台账（codex 0161）。复算: python3 scripts/rewrite_coverage.py')
    rows.append('# ★三个口径必须分开报，不得互相冒充★：')
    rows.append('#   fm_targets      跑了证明的目标数（含同一设计的 N 个变体）')
    rows.append('#   unique_design   golden 模块名去掉尾部 _<数字> 后的不同基名数')
    rows.append('#   golden_lines    每个 golden 模块定义所在文件的行数之和')
    rows.append('#')
    rows.append('# ★written vs proven（2026-09-16 加）★')
    rows.append('#   written  模块名出现在 rtl/ —— **不说明它写完了**，骨架同样算 written')
    rows.append('#   proven   written 且有绿判决证据（fm_round 的 SUCCEEDED/PASS_DEAD_REF')
    rows.append('#            或 fastlane_ledger 的 WORKING_PASS[_DEAD_REF]）')
    rows.append('#   ★头条数字看 proven★。起因：一个 3,149 行、只实现约两成逻辑的')
    rows.append('#   LoadQueueReplay 骨架放进 rtl/，旧口径下覆盖率从 7.4% 跳到 11.0%，')
    rows.append('#   凭空记账 138,860 行 golden。判据改成按证据记，骨架自然记 0，')
    rows.append('#   不依赖任何人记得去声明"这是骨架"。')
    rows.append('# codex 0161: "Variant FM receipts remain useful but must not inflate')
    rows.append('#              rewrite coverage."')
    rows.append('#')
    rows.append('# 排除项（显式列出，不悄悄扣）：')
    for _, tag, why in EXCLUSIONS:
        rows.append('#   %-16s %4d 个   %s' % (tag, excl[tag], why))
    rows.append('#')
    rows.append('metric\tdone\ttotal\tpercent')
    # ★fm_targets 的分母是**配置集**，不是本轮实跑数★
    # 实测：配置 273，本轮实跑 253。差的 21 个大多是 worker 在自己分支验过、
    # 没进汇总表的（TLBuffer/SRAMTemplate 变体），另有 OpenLLC 资源阻塞、
    # StorePipe 是已文档化的 EXPLICITLY_UNPROVABLE。把 253 当分母会让这一栏
    # 永远是 100%，那就失去意义了。
    # ★2026-09-20 修：这里原先也**写死**成 fm_round_20260914.tsv★
    # 上面 proven 那条在 2026-09-17 已经从写死改成 glob，★但这一处漏了★ ——
    # 同一个 bug 的第二处，修了一个没修另一个。
    # 后果是分子永远停在旧台账那批（252），而分母随每轮新目标增长，于是
    # fm_targets_configured 一路往下掉：252/397=63.5% -> 252/419 -> 252/425…
    # 看上去像覆盖退步，实际是记账口径漏了新台账。
    # 由 agent/fubusy-wbarb 发现并如实记账（它没擅自改这个共享口径，做得对）。
    ran = set()
    for rnd in sorted((REPO / 'docs').glob('fm_round_*.tsv')):
        for l in rnd.read_text(errors='replace').splitlines():
            if l and not l.startswith('#') and not l.startswith('target'):
                ran.add(l.split('\t')[0])
    nran = len(targets & ran)
    rows.append('fm_targets_configured\t%d\t%d\t%.1f'
                % (nran, len(targets), nran * 100.0 / len(targets)))
    rows.append('unique_design_written\t%d\t%d\t%.1f'
                % (len(fam_done), len(fam), len(fam_done) * 100.0 / len(fam)))
    rows.append('unique_design_proven\t%d\t%d\t%.1f'
                % (len(fam_prov), len(fam), len(fam_prov) * 100.0 / len(fam)))
    rows.append('golden_lines_written\t%d\t%d\t%.1f'
                % (lines_done, lines_tot, lines_done * 100.0 / lines_tot))
    rows.append('golden_lines_proven\t%d\t%d\t%.1f'
                % (lines_prov, lines_tot, lines_prov * 100.0 / lines_tot))
    # ★核内口径（2026-09-21 加）★
    # 上面四行的分母来自 universe，而 universe 的根是 **XSTop**（见
    # docs/g1_configured_universe.tsv 表头），装的是整个 SoC —— L3(OpenLLC)、
    # TileLink/AXI 桥、NCB 家族、APLIC 全在里面。而本轮重写范围是**核**
    # （用户长期约束：核外面的文件不要重写）。
    # 两个口径的百分比差别不大（实测 proven 41.2% -> 42.4%），★所以别拿它当进展★；
    # 真正的损失在排期表：核外大件会排到核内大件前面（实测 30 个候选里 7 个核外、
    # 合计 21 万行，一直夹在 Backend / LoadQueueUncache / CtrlBlock 中间）。
    tile = load_tile_closure()
    if tile:
        i_tot = sum(n for m, (_, n) in real.items() if m in tile)
        i_done = sum(n for m, (_, n) in real.items() if m in tile and m in done)
        i_prov = sum(n for m, (_, n) in real.items() if m in tile and m in prov)
        o_tot, o_done, o_prov = (lines_tot - i_tot, lines_done - i_done,
                                 lines_prov - i_prov)
        rows.append('#')
        rows.append('# ★核内口径（XSTile 闭包，docs/xstile_closure.tsv）= 本轮真实范围★')
        rows.append('incore_golden_lines_written\t%d\t%d\t%.1f'
                    % (i_done, i_tot, i_done * 100.0 / i_tot))
        rows.append('incore_golden_lines_proven\t%d\t%d\t%.1f'
                    % (i_prov, i_tot, i_prov * 100.0 / i_tot))
        rows.append('# 核外（XSTop 有、XSTile 没有）—— ★本轮范围外，不排期★')
        rows.append('#   已证出来的不作废，只是不该和核内混在一个百分比里报')
        rows.append('outcore_golden_lines_written\t%d\t%d\t%.1f'
                    % (o_done, o_tot, o_done * 100.0 / o_tot if o_tot else 0.0))
        rows.append('outcore_golden_lines_proven\t%d\t%d\t%.1f'
                    % (o_prov, o_tot, o_prov * 100.0 / o_tot if o_tot else 0.0))
    # ★LEGACY_PROVEN_UNANCHORED（codex 0169 D1）★
    # proven 口径读的是 docs/fm_round_*.tsv 的**行**，不是 receipt。于是一行手写台账
    # 就能算数 —— Ftq 的 112754 行就是这么从 09-14 起被计进 proven 的，而当时
    # 它的终局 verify 从没跑完、evidence 从没入库（后由 agent/ftqprove 补上）。
    #
    # codex 0169 D1 裁定：**暂不收紧**（receipt 是可复算性资产，不是 RTL 功能本身；
    # 当前优先级是继续写 RTL、跑 Formal、转绿），但这些历史结果要——
    #   · 保留原功能结论，标记 LEGACY_PROVEN_UNANCHORED
    #   · ★不计作本轮新增进展★
    #   · 在目标 RTL 被改动、依赖父级晋升或自然回归时，顺带用当前官方流程刷新
    # 从现在起的新 proven 必须来自实际完成的 FM 结果。
    import subprocess as _sp
    try:
        _tracked = {x.split('/')[2] for x in _sp.check_output(
            ['git', '-C', str(REPO), 'ls-files', 'evidence/*/receipt.json']
        ).decode().split() if x.count('/') >= 3}
    except Exception:
        _tracked = None
    if _tracked is not None:
        _unanchored = sorted(m for m in prov if m not in _tracked)
        _ul = sum(real[m][1] for m in _unanchored if m in real)
        rows.append('#')
        rows.append('# ★LEGACY_PROVEN_UNANCHORED（codex 0169 D1）—— 台账行有绿判决，'
                    '但仓里没有已跟踪 receipt★')
        rows.append('#   它们保留原功能结论、仍计在上面的 proven 里，'
                    '但★不计作本轮新增进展★；')
        rows.append('#   在各自目标下次被改动/晋升/自然回归时，顺带用当前官方 FM 流程刷新。')
        rows.append('legacy_proven_unanchored\t%d\t%d\t%.1f'
                    % (len(_unanchored), len(prov),
                       len(_unanchored) * 100.0 / len(prov) if prov else 0.0))
        rows.append('#   合计 %d golden 行' % _ul)
        for m in _unanchored:
            rows.append('#   %-40s %8d 行' % (m, real[m][1] if m in real else 0))
    rows.append('#')
    rows.append('# written 里没有绿判决证据的设计族（差额都在这儿，逐个列出不藏）：')
    for b in sorted(fam_done - fam_prov):
        n = sum(real[m][1] for m in fam[b] if m in done)
        rows.append('#   %-44s %8d 行' % (b, n))
    rows.append('#')
    rows.append('# 剩余最大的 30 个（按 golden 行数）—— 下一波排期的候选')
    rows.append('# ★只列核内★：核外的另列在本表末尾，不要从那里接活')
    rows.append('remaining_design\tgolden_lines\tvariants\tscope')
    scope = {}
    uni = REPO / 'docs' / 'g1_universe.tsv'
    if uni.exists():
        for l in uni.read_text(errors='replace').splitlines():
            if l.startswith('#'):
                continue
            c = l.split('\t')
            if len(c) > 3:
                scope[c[0]] = c[3]
    rest = sorted(((sum(real[m][1] for m in ms if m not in done), b, ms)
                   for b, ms in fam.items() if b not in fam_done),
                  reverse=True)
    incore = [r for r in rest if not tile or any(m in tile for m in r[2])]
    outcore = [r for r in rest if tile and not any(m in tile for m in r[2])]
    for n, b, ms in incore[:30]:
        rows.append('%s\t%d\t%d\t%s' % (b, n, len(ms), scope.get(b, '-')))
    if outcore:
        rows.append('#')
        rows.append('# ★核外剩余（XSTop 有、XSTile 没有）—— 本轮不排期，列在这里只为')
        rows.append('#   让人看得见它们的存在，别当成"还没人接的活"★  合计 %d 行'
                    % sum(n for n, _, _ in outcore))
        for n, b, ms in outcore[:20]:
            rows.append('#   %-40s %8d 行  variants=%d' % (b, n, len(ms)))
    return '\n'.join(rows) + '\n', (len(targets), len(fam_done), len(fam),
                                    lines_done, lines_tot, len(fam_prov), lines_prov)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true', help='只校验台账与重算结果一致')
    a = ap.parse_args()
    text, (nt, fd, ft, ld, lt, fp, lp) = build()
    if a.check:
        if not OUT.exists():
            print('FAIL: %s 不存在' % OUT)
            return 1
        if OUT.read_text() != text:
            print('FAIL: %s 与重算结果不一致（DRIFT）' % OUT)
            return 1
        print('rewrite_coverage --check: 逐字节一致')
        return 0
    OUT.write_text(text)
    print('  FM 目标          %d' % nt)
    print('  不同设计 written %d / %d  = %.1f%%' % (fd, ft, fd * 100.0 / ft))
    print('  不同设计 proven  %d / %d  = %.1f%%' % (fp, ft, fp * 100.0 / ft))
    print('  golden 行 written %s / %s = %.1f%%'
          % (format(ld, ','), format(lt, ','), ld * 100.0 / lt))
    print('  ★golden 行 proven %s / %s = %.1f%%★'
          % (format(lp, ','), format(lt, ','), lp * 100.0 / lt))
    print('  已写 %s' % OUT)
    return 0


if __name__ == '__main__':
    sys.exit(main())
