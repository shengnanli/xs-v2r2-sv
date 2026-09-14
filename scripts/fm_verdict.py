#!/usr/bin/env python3
"""Fail-closed FM 判定解析器(2026-07 签核基础设施, 二审后全 P0 修订版)。

替代旧 `grep "Verification SUCCEEDED"` 的**系统性假绿灯**(Formality 回显整个 Tcl 脚本,
未锚定 grep 命中未执行分支的 puts)。本解析器 fail-closed:任何不满足全部条件的一律非-SUCCEEDED。

verdict(log, make_rc, mode, expected_top=None, allowlist=None) -> (verdict, quals)
verdict ∈ {SUCCEEDED, FAILED, WAIVED, PARTIAL, SHADOW_CHECK, DIAGNOSTIC, UNRUN, ERROR}

修订覆盖二审列出的全部 P0:
 P0-1 mode 校验:未知/拼错 mode → ERROR;diagnostic-full 永不 SUCCEEDED;shadow 只 SHADOW_CHECK。
 P0-2 assembly allowlist:unmatched 超出声明的对称黑盒配额 → PARTIAL。
 P0-3 CLI 退出码:非 SUCCEEDED 时进程非零退出(见 __main__)。
 P0-4 交叉检查 Formality 原生 verdict(非 FM_RESULT 前缀的 "Verification FAILED/INCONCLUSIVE")。
 P0-5 校验 expected_top:marker 的 "for <top>" 必须匹配,否则 WrongTop → ERROR。
 P0-6 捕获 dont-verify / ELAB-147 / blackbox 作 qualification;strict 拒绝未声明者。
 P0-7 只解析**最后一个** "Matched Compare Points" 汇总表(防较早短格式覆盖终态)。
 P0-8 汇总表缺失 → ERROR(不按零处理);表内某类别缺失才视为 0。
 P0-9 freshness:要求 run 元数据(input_hash/baseline)绑定,不匹配 → 标记 stale。
"""
import json
import os
import re
import sys

KNOWN_MODES = {"signoff-strict", "assembly", "diagnostic-full", "shadow"}

# 行首锚定的、脚本实际 emit 的最终 marker(Tcl 回显的源码行有前导空白, 不会行首匹配)。
_MARKER = re.compile(r'^FM_RESULT: Verification (SUCCEEDED|WAIVED|FAILED)\b[^\n]*?(?:for (\S+))?\s*$', re.M)
# Formality **原生** verdict(独立行, 无 FM_RESULT 前缀)——交叉检查用。
_NATIVE = re.compile(r'^\s*Verification (SUCCEEDED|FAILED|INCONCLUSIVE)\s*$', re.M)
_NOTRUN = re.compile(r'Verification NOT RUN|reference design .* is a black box|FM-081', re.M)

# 最后一个 "Matched Compare Points ... TOTAL" 汇总表块。
_TABLE_HDR = re.compile(r'Matched Compare Points.*?TOTAL', re.S)

# 表内类别行,末列 TOTAL 为总数。
_ROW = {
    "passing":    re.compile(r'^\s*Passing \(equivalent\)\s+(?:\d+\s+)*(\d+)\s*$', re.M),
    "failing":    re.compile(r'^\s*Failing \(not equivalent\)\s+(?:\d+\s+)*(\d+)\s*$', re.M),
    "unverified": re.compile(r'^\s*Unverified\s+(?:\d+\s+)*(\d+)\s*$', re.M),
    "aborted":    re.compile(r'^\s*Aborted\s+(?:\d+\s+)*(\d+)\s*$', re.M),
    "unread_nc":  re.compile(r'^\s*Unread\s+(?:\d+\s+)*(\d+)\s*$', re.M),
}
# 未配对报告(在表外),R(I) 两侧任一非 0 即未完全配对。
_UNMATCH_CP = re.compile(r'(\d+)\((\d+)\)\s+Unmatched \S+ compare points', re.M)
_UNREAD_UM  = re.compile(r'(\d+)\((\d+)\)\s+Unmatched \S+ unread points', re.M)
# black-box outputs 未配对(存在黑盒的精确信号,区别于 app_var 名回显)。
_BBOUT      = re.compile(r'(\d+)\((\d+)\)\s+Unmatched \S+ (?:primary inputs, )?black-box outputs', re.M)

# "Verification Results" 段的散文计数行。与下面那张 "Matched Compare Points" 表
# **口径不同**，这是本工程踩过的坑：
#   表里 `Failing (not equivalent)` 只数 **matched** 失败点；
#   散文 `N Failing compare points (M matched, U unmatched)` 数的是 **M+U 总数**。
# 实证(evidence/26c4bf21b739/Alu)：表 failing=0，散文 450(0 matched, 450 unmatched)
# ——只看表会把"450 个点在失败"读成"0 个点在失败"。
# 另外 FM 对全零类别**不产生表行**（FCVT 的 Aborted 行就不存在），所以
# passing/unverified/aborted 用散文兜底填 null；两者都在且不一致 → 视为日志完整性问题。
_PROSE = {
    "passing":    re.compile(r'^\s*(\d+)\s+Passing compare points\s*$', re.M),
    "unverified": re.compile(r'^\s*(\d+)\s+Unverified compare points\s*$', re.M),
    "aborted":    re.compile(r'^\s*(\d+)\s+Aborted compare points\s*$', re.M),
}
_PROSE_FAILING = re.compile(
    r'^\s*(\d+)\s+Failing compare points\s*\((\d+)\s+matched,\s*(\d+)\s+unmatched\)\s*$', re.M)


# 一次 fm_shell 会话里可以 verify 多次（或日志被拼接），此时散文段/汇总表都会出现多份。
# reviewer 0146 P0：散文原来用 search() 取的是**第一次**，而表和 native verdict 取的是
# **最后一轮**，两者会错配。这里统一改成"先切到最后一个 Verification Results 段，
# 再在段内取值"——表(_last_table)本来就落在这个段内，两个来源从此同源同轮。
_RESULTS_HDR = re.compile(r'^\*+\s*Verification Results\s*\*+\s*$', re.M)
# "Matching Results" 段头。钉了 fm_pins 的目标会打印多个这样的段，只有最后一段反映
# 最终配对状态；且 FM 省略零值行，所以必须按段取而不是在全文里取最后一次命中。
_MATCH_HDR_RES = re.compile(r'^\*+\s*Matching Results\s*\*+\s*$', re.M)


def _last_results_block(text):
    """最后一个 "Verification Results" 段（到文本末）。没有则返回 None。"""
    ms = list(_RESULTS_HDR.finditer(text))
    if not ms:
        return None
    return text[ms[-1].start():]


def _prose_int(text, key):
    """取散文计数。text 应已是**最后一轮**的结果段；仍用 findall[-1] 兜底。"""
    ms = _PROSE[key].findall(text)
    return int(ms[-1]) if ms else None


def _prose_failing(text):
    """散文失败行 -> (total, matched, unmatched)；无则 None。取最后一个(非 search 首个)。"""
    ms = _PROSE_FAILING.findall(text)
    if not ms:
        return None
    return tuple(int(x) for x in ms[-1])


# qualification 痕迹。
# 注: 这两个用 search()/bool 是**故意**的——它们是"整份日志里只要出现过就算被污染"的
# taint 标记(保守方向), 不是 reviewer 0146 P0 说的"多轮里取错轮次"那类 bug。
_DONTVERIFY = re.compile(r'set_dont_verify_points|Don\'t verify', re.M)
_ELAB147    = re.compile(r'FMR_ELAB-147', re.M)


def _last_table(text):
    """返回最后一个汇总表块的文本(从最后一个表头到其后 '*****' 或文本末)。缺失返回 None。"""
    hdrs = list(_TABLE_HDR.finditer(text))
    if not hdrs:
        return None
    start = hdrs[-1].start()
    tail = text[start:]
    end = tail.find('*****')
    return tail if end < 0 else tail[:end]


def _row_int(tbl, key):
    m = None
    for mt in _ROW[key].finditer(tbl):
        m = int(mt.group(1))
    return m


def _unmatch_pair(text, pat):
    """取最后一次 R(I) 匹配的 (ref, impl) 元组;找不到返回 (None, None)。"""
    r = i = None
    for mt in pat.finditer(text):
        r, i = int(mt.group(1)), int(mt.group(2))
    return r, i


def _unmatch_max(text, pat):
    val = None
    for mt in pat.finditer(text):
        val = max(int(mt.group(1)), int(mt.group(2)))
    return val


def _fill_stats(q, log_text):
    """把汇总表 + 未配对报告的**数字**填进 q（纯采集，不做任何判定）。

    以前这段代码只长在 `final == SUCCEEDED` 分支里，FAILED/WAIVED 直接 early-return，
    于是**失败时 passing/failing/unverified 全是 null**——恰恰是最需要数字的时候没有数字，
    诊断只能重跑一遍 FM。数字采集与判定本就无关，这里抽出来给所有分支共用。

    返回 None 表示表存在且已填；返回原因串表示表缺失（调用方决定这算不算 ERROR：
    SUCCEEDED 分支必须 fail-closed 判 ERROR，FAILED 分支只记 reason——FAILED 本身
    已经是非通过，记不到数字不构成"静默放行"）。
    """
    tbl = _last_table(log_text)
    if tbl is None:
        return "no_summary_table"
    q["passing"]    = _row_int(tbl, "passing")
    q["failing"]    = _row_int(tbl, "failing")
    q["unverified"] = _row_int(tbl, "unverified")
    q["aborted"]    = _row_int(tbl, "aborted")
    _nc = _row_int(tbl, "unread_nc")
    # ★作用域必须限定在**最后一个** Matching Results 块★（2026-09-14）
    # 踩到的坑：FM **省略零值行**。一个钉了 fm_pins 的目标会打印多个 Matching Results
    # 块，pin 之前那块有 `9(9) Unmatched ... unread points`，pin 之后那两块因为归零而
    # 根本不打印该行。于是 _unmatch_pair 的"取最后一次命中"退化成"取那唯一一次"——
    # 拿到的是**钉 pin 之前的陈旧值**，判定报 unread=9 而实际是 0。
    # 三个独立来源都证实实际为 0：sidecar/native_facts.json（走 Formality API 不过正则）
    # unread_ref=unread_impl=0、unread_points.txt 为 0 字节、最后一块无 unread 行。
    # 同文件里 _last_table 早就是按块取的，这里漏了。
    # 影响面已实测：本轮主树 224 份 receipt 命中 0 个（无 pin 的目标只有一块，不受影响）；
    # 全仓仅 5 个 UT 用 fm_pins（Bku/FCVT/ICacheCtrlUnit/ITTageTable/SyncDataModule），
    # 其中 Bku/FCVT 的 unread 是真的（unread_points.txt 非空），本次修正不影响其判定。
    _mblocks = list(_MATCH_HDR_RES.finditer(log_text))
    _scope = log_text[_mblocks[-1].start():] if _mblocks else log_text
    _umr, _umi = _unmatch_pair(_scope, _UNREAD_UM)
    q["unread"]    = max([x for x in (_nc, _umr, _umi) if x is not None], default=None)
    umr, umi = _unmatch_pair(log_text, _UNMATCH_CP)
    q["unmatched_ref"], q["unmatched_impl"] = umr, umi
    q["unmatched"] = max([x for x in (umr, umi) if x is not None], default=None)
    bbr, bbi = _unmatch_pair(log_text, _BBOUT)
    q["blackbox_out"] = max([x for x in (bbr, bbi) if x is not None], default=None)

    # 散文兜底 + 交叉核对（口径差异见 _PROSE 注释）。
    # 只在**最后一个**结果段里取，保证与 _last_table 同一轮 verify。
    blk = _last_results_block(log_text)
    if blk is None:
        # 有表却没有结果段头 = 日志被截断/裁剪过，两个来源无法互证 → fail-closed
        return "no_results_block"

    for k in ("passing", "unverified", "aborted"):
        pv = _prose_int(blk, k)
        if pv is None:
            continue
        if q[k] is None:
            q[k] = pv                      # FM 对全零类别不出表行 → 散文兜底
        elif q[k] != pv:
            # 682 份真实日志实测从未发生；真发生说明日志被拼接/截断 → fail-closed
            return f"stats_inconsistent:{k}:table={q[k]},prose={pv}"

    pf = _prose_failing(blk)
    if pf is not None:
        total, matched, unmatched = pf
        q["failing_total"]     = total
        q["failing_matched"]   = matched
        q["failing_unmatched"] = unmatched
        if total != matched + unmatched:
            return (f"stats_inconsistent:failing:prose_total={total}!="
                    f"{matched}+{unmatched}")
        if q["failing"] is not None and q["failing"] != matched:
            return (f"stats_inconsistent:failing:table={q['failing']},"
                    f"prose_matched={matched}")
    elif q["failing"] is not None:
        # 没有散文失败行 = 一个失败点都没有；表里 failing 必须也是 0
        if q["failing"] != 0:
            return f"stats_inconsistent:failing:table={q['failing']},prose_absent"
        q["failing_total"] = q["failing_matched"] = q["failing_unmatched"] = 0
    return None


def _failure_reason(q, stats_err):
    """FAILED 时给出**可机读**的失败画像，取代原来的 reason=null。"""
    if stats_err:
        return "failed_" + stats_err          # 表都没有 → 日志本身可疑
    bits = []
    # failing 优先报**总数**：Alu 那种 "表 0 / 实际 450 全是 unmatched" 只看表会谎报 0。
    ft, fm_ = q.get("failing_total"), q.get("failing_matched")
    if ft:
        if fm_ is not None and fm_ != ft:
            bits.append(f"failing={ft}(matched={fm_},unmatched={q.get('failing_unmatched')})")
        else:
            bits.append(f"failing={ft}")
    elif q.get("failing"):
        bits.append(f"failing={q['failing']}")
    for k in ("unverified", "aborted"):
        if q.get(k):
            bits.append(f"{k}={q[k]}")
    if q.get("unmatched"):
        bits.append(f"unmatched={q['unmatched']}")
    if not bits:
        # marker/native 说失败，但表里每一类都是 0 → 数字与结论矛盾，必须显形。
        return "failed_but_all_rows_zero"
    return "failed:" + ",".join(bits)




# --- assembly 精确黑盒集合策略（codex 0139 §3.3：禁止纯数字配额）-------------
# 三类抽象边界，判定强度不同：
#   vendor_macro      厂商硬宏叶子（array_*_ext 等 .v 行为模型）——两侧同源，无条件允许
#   green_child       独立 FM target 且持有 tracked 证明证书——条件允许，
#                     须写明 child_target + certificate_sha256（codex 0157 D57）
#   golden_logic_reuse 直接复用 golden 功能逻辑当黑盒——**NO-GO**，必须独立证明后才可引用
ALLOWED_BBOX_CLASSES = {'vendor_macro', 'green_child'}


def _hier_key(path):
    """把黑盒实例路径归一到可跨两侧比对的层次键：
    去掉容器前缀（r:/i:）与 /WORK/<top>，并**抹掉 wrapper 自身的 u_core 层**
    （impl 侧 wrapper 例化可读核，天然多一级；ref 侧没有）。
    结果是"这个黑盒挂在设计里的哪个位置"，两侧应完全一致。"""
    s = re.sub(r'^[ri]:/WORK/[^/]+/?', '', path)
    s = re.sub(r'(^|/)u_core(/|$)', r'\1', s)
    return s.strip('/')


def _repo_home():
    """证书与 target 全集都从**仓库的 commit** 里读，所以这里要的是仓库根，
    不是 XSSV_INDEX_HOME（那是旧的 untracked evidence 索引位置，已不再是权威输入）。"""
    import pathlib as _pl
    return _pl.Path(os.environ.get('XSSV_HOME')
                    or _pl.Path(__file__).resolve().parent.parent)


def _cert_ctx(expect_impl_commit):
    """green_child 校验上下文（proof_certificate + fm_target_universe + POLICY）。

    ★codex 0157 D57★ 旧路径 `_child_receipts()` 读 `docs/receipt_index.tsv`
    ——那份索引与 `evidence/` 都在 .gitignore 里，clean clone / clean freeze 下必然为空，
    于是所有 green_child 直接 `assembly_green_child_no_receipt`，已绿目标在冻结当天集体翻红。
    D57 的解法不是把 evidence 提交进去，而是改读 **tracked、由 freeze commit 绑定的证书**
    `verif/proof_certificates/<target>.json`，并在父 commit 的字节上重算 child 闭包。

    返回 (ctx, None) 或 (None, 失败原因串)。**任何拿不到上下文的情况都是失败，不是放行。**
    """
    if not expect_impl_commit:
        return None, 'assembly_green_child_no_commit_context(须 --impl-commit)'
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    try:
        import proof_certificate as _PC
        import fm_target_universe as _FTU
    except ImportError as e:                                # noqa: BLE001
        return None, 'assembly_green_child_toolchain_missing:%s' % e
    home = _repo_home()
    repo = _PC.Repo(home)
    if not repo.available():
        return None, 'assembly_green_child_git_unavailable'
    commit = repo.rev_parse(expect_impl_commit)
    if commit is None:
        return None, 'assembly_green_child_commit_unresolvable:%s' % expect_impl_commit[:12]
    pol, perr = _PC.load_policy(repo, commit)
    if perr:
        return None, 'assembly_green_child_%s' % perr
    try:
        tmap, unresolved = _FTU.targets_at(str(home), commit)
    except Exception as e:                                  # noqa: BLE001
        return None, 'assembly_green_child_target_universe_error:%s' % type(e).__name__
    return {'PC': _PC, 'repo': repo, 'commit': commit, 'policy': pol,
            'targets': tmap, 'unresolved': unresolved,
            'g1': os.environ.get('G1_CANONICAL') or '/home/eda/xs-env/G1-canonical'}, None


def _assembly_bbox_check(observed, attrs, decl, expect_canonical=None,
                         expect_impl_commit=None):
    """观测黑盒集合须与声明**精确相等**，且每条类别合法、ref/impl 成对。
    返回 True 或失败原因串。"""
    if decl is None:
        return 'assembly_no_allow_decl(须 verif/allow/<top>.json 逐对象声明)'
    declared = {}
    for e in decl.get('objects', []):
        try:
            declared[(e['side'], e['design'], e['path'])] = e
        except KeyError:
            return 'assembly_allow_entry_missing_field'
    if observed != set(declared):
        extra = observed - set(declared)
        missing = set(declared) - observed
        det = ''
        if extra:
            det = ',observed_not_declared=' + sorted(extra)[0][2]
        elif missing:
            det = ',declared_not_observed=' + sorted(missing)[0][2]
        return f'assembly_bbox_set_mismatch:extra={len(extra)},missing={len(missing)}{det}'
    bad_cls = sorted({e.get('class', '?') for e in declared.values()} - ALLOWED_BBOX_CLASSES)
    if bad_cls:
        return f'assembly_bbox_class_not_allowed:{",".join(bad_cls)}'
    # 对称性：按**设计名的实例条数**两侧相等。
    # 为什么不比实例路径：可读核用 generate-for 数组（g_bank[0].table_bank）取代 golden
    # 的展平副本（table_banks_0），实例名本就应该不同——那正是本工程要的可读性改进。
    # 防"两侧共同黑盒错逻辑"的实际约束来自另外三条：①观测集合须与**已提交的**声明
    # 精确相等（任何新增/改名/改路径的黑盒都会打破）；②类别门控（厂商宏无条件，
    # green_child 须有独立已绿目标背书，golden_logic_reuse 直接 NO-GO）；
    # ③green_child 的 child 必须持有 tracked 证书，且证书在**本次父 commit 的字节上**
    #   仍然成立（闭包/声明/工具策略逐项复算）——见 _cert_ctx 与 proof_certificate.py。
    from collections import Counter
    ref_cnt = Counter(d for s, d, _ in declared if s == 'r')
    impl_cnt = Counter(d for s, d, _ in declared if s == 'i')
    if ref_cnt != impl_cnt:
        diff = sorted(set(ref_cnt) ^ set(impl_cnt)) or \
            sorted(d for d in ref_cnt if ref_cnt[d] != impl_cnt.get(d))
        return f'assembly_bbox_not_symmetric:{diff[0]}(ref={ref_cnt.get(diff[0], 0)},impl={impl_cnt.get(diff[0], 0)})'
    # --- green_child：D57 证书路径 -------------------------------------------
    gc = [(k, e) for k, e in declared.items() if e.get('class') == 'green_child']
    if gc:
        ctx, cerr = _cert_ctx(expect_impl_commit)
        if cerr:
            return cerr
        seen = {}
        for k, e in gc:
            ct = e.get('child_target')
            if not ct:
                return f'assembly_green_child_without_target:{k[1]}'
            # 同一个 child 在一份 allow 里可能被声明很多次（TageTable 有 16 条指 WrBypass）。
            # 判定只做一次，但**每条声明的 certificate_sha256 都必须各自对得上**，
            # 否则"第一条写对、其余抄错"会被缓存掩盖。
            key = (ct, e.get('certificate_sha256'))
            if key in seen:
                if seen[key] is not True:
                    return seen[key]
                continue
            r = ctx['PC'].validate_child_certificate(
                ctx['repo'], ctx['commit'], ct, e.get('certificate_sha256'),
                expect_canonical=expect_canonical, policy=ctx['policy'],
                fm_targets=ctx['targets'], fm_targets_unresolved=ctx['unresolved'],
                g1_root=ctx['g1'])
            if r is not True:
                r = 'assembly_' + r
            seen[key] = r
            if r is not True:
                return r
    return True


def _dead_ref_check(q, decl, unread_points, assembly=False):
    """PASS_DEAD_REF 六条件(全满足才返回 True, 否则返回失败原因串)。
    decl = 声明 json(entries[].ref_path); unread_points = fm_eq.tcl 导出的实际未读点。"""
    if q.get("failing") not in (0, None):
        return "dead_ref_failing!=0"
    dims = ("unverified", "aborted") if assembly else ("unverified", "unmatched", "aborted")
    for k in dims:
        if q.get(k) not in (0, None):
            return f"dead_ref_{k}!=0"
    if not assembly and q.get("blackbox_out"):
        return "dead_ref_has_blackbox"
    if q["dont_verify"] or q["elab147"]:
        return "dead_ref_has_dontverify_or_elab147"
    if not assembly and q.get("unmatched_impl"):
        return f"dead_ref_impl_not_clean:{q['unmatched_impl']}"
    if unread_points is None:
        return "dead_ref_no_unread_points_file(须 fm_eq.tcl 导出)"
    obs_ref = {p for kind, p in unread_points if kind == "ref"}
    obs_other = {(k, p) for k, p in unread_points if k != "ref"}
    if obs_other:
        return f"dead_ref_nonref_unread:{len(obs_other)}"
    declared = {e["ref_path"] for e in decl.get("entries", [])}
    if obs_ref != declared:
        extra, missing = obs_ref - declared, declared - obs_ref
        return (f"dead_ref_set_mismatch:extra={len(extra)},missing={len(missing)}"
                + (f",e.g.{sorted(extra)[0]}" if extra else ""))
    q["dead_ref_points"] = len(declared)
    return True


def verdict(log_text, make_rc=0, mode="signoff-strict", expected_top=None, allowlist=0,
            dead_ref_decl=None, unread_points=None, bbox_obs=None, bbox_attrs=None,
            allow_decl=None, expect_canonical=None, expect_impl_commit=None):
    q = {"passing": None, "failing": None, "unverified": None, "unmatched": None, "aborted": None,
         "failing_total": None, "failing_matched": None, "failing_unmatched": None,
         "unread": None, "blackbox_out": None, "markers": 0, "make_rc": make_rc, "mode": mode,
         "native": None, "top": None, "dont_verify": bool(_DONTVERIFY.search(log_text)),
         "elab147": bool(_ELAB147.search(log_text)), "reason": None}

    # P0-1: mode 校验
    if mode not in KNOWN_MODES:
        q["reason"] = f"unknown_mode:{mode}"
        return "ERROR", q
    # P0-3 前置: make 非零 → ERROR
    if make_rc != 0:
        q["reason"] = "make_rc_nonzero"
        return "ERROR", q

    marks = _MARKER.findall(log_text)     # [(verdict, top), ...]
    q["markers"] = len(marks)
    if q["markers"] == 0:
        if _NOTRUN.search(log_text):
            return "UNRUN", q
        q["reason"] = "no_marker"
        return "ERROR", q
    if q["markers"] > 1:
        q["reason"] = "multiple_markers"    # 拼接历史/多variant → 不可信
        return "ERROR", q
    final, top = marks[0]
    q["top"] = top or None

    # P0-5 + 对抗: expected_top 校验。给了 expected_top 但 marker 无 top(无法确认是本模块)
    # 或不匹配 → ERROR(不得因 marker 缺 top 而跳过校验)。
    if expected_top:
        if not top:
            q["reason"] = "expected_top_but_marker_has_no_top"
            return "ERROR", q
        if top != expected_top:
            q["reason"] = f"wrong_top:{top}!={expected_top}"
            return "ERROR", q

    # P0-4: 交叉检查 Formality 原生 verdict
    natives = _NATIVE.findall(log_text)
    q["native"] = natives[-1] if natives else None
    # 数字采集提到所有分支之前：失败时同样要有 passing/failing/unverified，
    # 否则诊断只能重跑 FM（本工程真实事故：FCVT 20 个失败点靠重跑 130s 才拿到）。
    stats_err = _fill_stats(q, log_text)

    if q["native"] in ("FAILED", "INCONCLUSIVE") and final == "SUCCEEDED":
        q["reason"] = f"native_{q['native']}_vs_marker_SUCCEEDED"
        return "FAILED", q

    # WAIVED / FAILED marker 直接归类（数字已采集，reason 给出失败画像）
    if final == "WAIVED":
        if stats_err:
            q["reason"] = "waived_" + stats_err
        return "WAIVED", q
    if final == "FAILED":
        q["reason"] = _failure_reason(q, stats_err)
        return "FAILED", q

    # final == SUCCEEDED: 必须过全部数字闸门
    # P0-7 + P0-8: 只认最后一个汇总表;表缺失 → ERROR(fail-closed, 不得放行)
    if stats_err:
        q["reason"] = stats_err
        return "ERROR", q

    if q["failing"] is None:
        q["reason"] = "failing_row_missing"   # 表在但没 Failing 行 → 不确定, fail-closed
        return "ERROR", q
    if q["failing"] != 0:
        q["reason"] = "success_marker_but_failing>0"
        return "FAILED", q
    # 对抗: 空证明(passing=0)不得判绿——没有任何等价点被证明。
    if not q["passing"]:
        q["reason"] = "empty_proof_passing=0"
        return "ERROR", q

    # P0-1: 模式语义
    if mode == "diagnostic-full":
        return "DIAGNOSTIC", q                # 永不 signoff
    if mode == "shadow":
        return "SHADOW_CHECK", q              # 可读核不驱动输出, 只伴随比对
    if mode == "assembly":
        # P0-2 + 对抗: assembly 只允许**对称**黑盒(ref==impl)且总数在 allowlist 内。
        # 非对称如 5(0) 说明一侧多出未配对点(缺依赖/端口不齐), 即便 ≤allowlist 也拒绝。
        umr_, umi_ = q["unmatched_ref"], q["unmatched_impl"]
        if (umr_ or 0) != (umi_ or 0):
            q["reason"] = f"assembly_asymmetric_unmatched:{umr_}({umi_})"
            return "PARTIAL", q
        if (q["unmatched"] or 0) > allowlist:
            q["reason"] = f"assembly_unmatched>{allowlist}:{q['unmatched']}"
            return "PARTIAL", q
        # 精确黑盒集合（唯一签核依据；数字配额只作为上面的粗筛）
        if bbox_obs is None:
            q["reason"] = "assembly_no_bbox_report(须 fm_eq.tcl 导出 black_boxes.rpt)"
            return "PARTIAL", q
        bb = _assembly_bbox_check(bbox_obs, bbox_attrs or {}, allow_decl,
                                  expect_canonical, expect_impl_commit)
        if bb is not True:
            q["reason"] = bb
            return "PARTIAL", q
        q["bbox_objects"] = len(bbox_obs)
        for k in ("unverified", "aborted"):
            if q.get(k) not in (0, None):
                q["reason"] = f"assembly_{k}!=0"
                return "PARTIAL", q
        if q.get("unread"):
            # 同 strict: 唯一残余是 golden 侧 cone-dead 未读点且与声明精确相等 ⇒ PASS_DEAD_REF
            if dead_ref_decl is None:
                q["reason"] = "assembly_unread!=0"
                return "PARTIAL", q
            dr = _dead_ref_check(q, dead_ref_decl, unread_points, assembly=True)
            if dr is True:
                return "PASS_DEAD_REF", q
            q["reason"] = dr
            return "PARTIAL", q
        return "SUCCEEDED", q
    # signoff-strict: 全部质保维为 0 + 无任何黑盒(strict-replacement 不允许子模块抽象)。
    # 例外 PASS_DEAD_REF: 唯一残余是 **golden 侧 cone-dead 未读点**(impl 干净),
    # 且观测集合与声明文件**精确相等**(多一条/少一条/换一条都退 PARTIAL)。
    # 不是 waiver: 声明逐条列出 ref_path, FM 仍证明了全部可达点等价。
    if dead_ref_decl is not None and q.get("unread"):
        dr = _dead_ref_check(q, dead_ref_decl, unread_points)
        if dr is True:
            return "PASS_DEAD_REF", q
        q["reason"] = dr
        return "PARTIAL", q
    for k in ("unverified", "unmatched", "aborted", "unread"):
        if q.get(k) not in (0, None):
            q["reason"] = f"strict_{k}!=0"
            return "PARTIAL", q
    if q.get("blackbox_out"):
        q["reason"] = "strict_has_blackbox"    # 未声明黑盒 → 非纯替换
        return "PARTIAL", q
    if q["dont_verify"] or q["elab147"]:
        q["reason"] = "strict_has_dontverify_or_elab147"
        return "PARTIAL", q
    return "SUCCEEDED", q


if __name__ == "__main__":
    import sys, json, argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("log"); ap.add_argument("--rc", type=int, default=0)
    ap.add_argument("--mode", default="signoff-strict")
    ap.add_argument("--top", default=None)
    ap.add_argument("--allowlist", type=int, default=0)
    ap.add_argument("--dead-ref", default=None,
                    help="PASS_DEAD_REF 声明 json(entries[].ref_path 精确枚举)")
    ap.add_argument("--unread-points", default=None,
                    help="fm_eq.tcl 导出的 unread_points.txt")
    ap.add_argument("--bbox-report", default=None,
                    help="fm_eq.tcl 导出的 black_boxes.rpt（assembly 必需）")
    ap.add_argument("--allow", default=None,
                    help="assembly 黑盒精确声明 verif/allow/<top>.json")
    ap.add_argument("--canonical-id", default=None,
                    help="本次 G1 canonical ID；green_child 的 child receipt 必须同源")
    ap.add_argument("--impl-commit", default=None,
                    help="本次 impl commit；green_child 必须在同一 committed 树上被证明")
    a = ap.parse_args()
    txt = open(a.log).read()
    decl = None
    if a.dead_ref and os.path.exists(a.dead_ref):
        with open(a.dead_ref) as f:
            decl = json.load(f)
    pts = None
    if a.unread_points and os.path.exists(a.unread_points):
        pts = []
        with open(a.unread_points) as f:
            for ln in f:
                if "\t" in ln:
                    k, p = ln.rstrip("\n").split("\t", 1)
                    pts.append((k, p))
    bbox_obs = bbox_attrs = None
    if a.bbox_report and os.path.exists(a.bbox_report):
        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
        import bbox_parse
        try:
            bbox_obs, bbox_attrs = bbox_parse.normalize(
                bbox_parse.parse(open(a.bbox_report).read()))
        except bbox_parse.BBoxParseError as e:
            print("ERROR\t" + json.dumps({"reason": f"bbox_parse:{e}"}, ensure_ascii=False))
            sys.exit(1)
    allow_decl = None
    if a.allow and os.path.exists(a.allow):
        with open(a.allow) as f:
            allow_decl = json.load(f)
    v, q = verdict(txt, a.rc, a.mode, a.top, a.allowlist, decl, pts,
                   bbox_obs, bbox_attrs, allow_decl, a.canonical_id, a.impl_commit)
    print(v + "\t" + json.dumps(q, ensure_ascii=False))
    # P0-3: 只有 SUCCEEDED 退 0；其余非零(签核 CI fail-closed)。
    # PASS_DEAD_REF 例外：仅当调用方显式给了 --dead-ref 声明文件(即该目标已被审计、
    # 声明已提交)时才算通过——没有声明的 unread 一律非零退出，不会被静默放行。
    sys.exit(0 if v == "SUCCEEDED" or (v == "PASS_DEAD_REF" and a.dead_ref) else 1)
