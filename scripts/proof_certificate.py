#!/usr/bin/env python3
"""proof_certificate.py —— tracked 证明证书（codex 0157 D57）的 schema + 校验核心。

# 解决的是什么

`evidence/`（1035 份 receipt）与 `docs/receipt_index.tsv` 都在 `.gitignore` 里。
于是 clean clone / clean freeze 下 `fm_verdict._child_receipts()` 返回空，所有
`green_child` 声明直接判 `assembly_green_child_no_receipt` —— 已经绿的目标会在
冻结那一刻集体翻红。

D57 的裁定不是"把 evidence 提交进去"，而是：**evidence 继续不入 Git**，另立一份
tracked、reviewed 的**紧凑证书** `verif/proof_certificates/<target>.json`，每份只来自
**一次 clean official run**，并由 freeze commit 绑定。`green_child` 声明精确引用
`child_target` + `certificate_sha256`；validator 从**当前提交**读证书、只认合格 verdict、
用 `git show` 在**父 commit 的字节上重算 child 闭包**，任一源/配置/工具策略/闭包变化即失效。

# 与 receipt 的关系（别混淆）

  receipt.json      每次 run 的完整记录，含原始闭包与 native facts。**不入 Git**。
  certificate.json  从**一份**符合条件的 receipt 机械派生的紧凑摘要。**入 Git、被 review**。

证书**不**替代原始日志。原始大 evidence 应留在 hash-addressed release archive；证书里
`evidence_archive` 记它的内容 hash。没有 archive 时，`evidence_retention` 只能是
`attestation_only`，证书就只是"可复跑 attestation"，**不得声称 clean clone 含完整原件**
（本模块把这条做成硬校验，见 `cert_archive_claim_without_hash`）。

# 三条不许犯的错

1. **旧的 untracked receipt 不得自动转成 green。** 生成器只接受一次 clean official run
   的证据目录，并在生成时就用 `git show` 重算一遍闭包；对不上直接拒。
2. **不得 fail-open。** 任何拿不准（git 不可用、policy 缺失、target 全集没展开完）
   一律返回失败原因串，绝不"默认放行"。
3. **证书自身必须来自 commit。** 所有读取走 `git show <commit>:<path>`，不读工作树——
   否则"在本地放一份证书就能转绿"。

用法（模块）:
    import proof_certificate as PC
    errs = PC.validate_document(doc)                       # schema 层
    ok_or_reason = PC.validate_child_certificate(...)      # D57 五条

用法（CLI，自检 schema 与已提交证书）:
    python3 scripts/proof_certificate.py --dump-schema
    python3 scripts/proof_certificate.py --lint verif/proof_certificates/<t>.json
"""
import hashlib
import json
import os
import pathlib
import re
import subprocess
import sys

CERT_SCHEMA = 'xs-v2-sv-proof-certificate-v1'
POLICY_SCHEMA = 'xs-v2-sv-proof-policy-v1'

CERT_DIR = 'verif/proof_certificates'
POLICY_PATH = CERT_DIR + '/POLICY.json'

#: 唯一合格的 verdict。PASS_DEAD_REF 的语义见 fm_verdict._dead_ref_check：
#: 仍是"全部可达点等价"，只是 golden 侧有逐条声明过的 cone-dead 未读点。
#: 其余（PARTIAL / SHADOW_CHECK / DIAGNOSTIC / WAIVED / FAILED / ERROR / UNRUN）一律不合格。
QUALIFYING_VERDICTS = ('SUCCEEDED', 'PASS_DEAD_REF')

RETENTION_MODES = ('archived', 'attestation_only')

_HEX64 = re.compile(r'^[0-9a-f]{64}$')
_HEX40 = re.compile(r'^[0-9a-f]{40}$')
_ISO_Z = re.compile(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$')

_HERE = pathlib.Path(__file__).resolve().parent


# --------------------------------------------------------------------------
# 摘要原语
# --------------------------------------------------------------------------
def canon_json(obj):
    """证书内一切"结构体摘要"的唯一序列化方式：排序键、无空格、UTF-8。
    换一种写法就换一个 hash —— 所以这里定死，任何地方都必须调它。"""
    return json.dumps(obj, sort_keys=True, separators=(',', ':'),
                      ensure_ascii=False).encode('utf-8')


def canon_digest(obj):
    return hashlib.sha256(canon_json(obj)).hexdigest()


def closure_digest(entries):
    """闭包摘要：对 (kind, path, sha256) 三元组排序后逐行拼接再取 sha256。

    为什么不直接 `canon_digest(entries)`：闭包条目将来可能加字段（注释、来源），
    加字段不该让历史证书全部失效；而 kind/path/sha256 三元组一变就必须失效。
    """
    lines = ''.join(
        '%s\t%s\t%s\n' % (e.get('kind'), e.get('path'), e.get('sha256'))
        for e in sorted(entries, key=lambda x: (str(x.get('path')),
                                                str(x.get('sha256')),
                                                str(x.get('kind')))))
    return hashlib.sha256(lines.encode('utf-8')).hexdigest()


# --------------------------------------------------------------------------
# git 访问层（只读 commit 的字节，绝不读工作树）
# --------------------------------------------------------------------------
class GitUnavailable(RuntimeError):
    pass


class Repo(object):
    def __init__(self, path):
        self.path = str(path)
        self._blob_cache = {}

    def _run(self, args):
        return subprocess.run(['git'] + args, cwd=self.path,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    def rev_parse(self, rev):
        p = self._run(['rev-parse', rev + '^{commit}'])
        if p.returncode != 0:
            return None
        return p.stdout.decode().strip()

    def show(self, commit, path):
        """返回 `<commit>:<path>` 的原始字节；不存在返回 None。"""
        key = (commit, path)
        if key in self._blob_cache:
            return self._blob_cache[key]
        p = self._run(['show', '%s:%s' % (commit, path)])
        out = p.stdout if p.returncode == 0 else None
        self._blob_cache[key] = out
        return out

    def is_ancestor(self, a, b):
        if a == b:
            return True
        return self._run(['merge-base', '--is-ancestor', a, b]).returncode == 0

    def available(self):
        return self._run(['rev-parse', '--git-dir']).returncode == 0


# --------------------------------------------------------------------------
# schema：显式字段表（不依赖 jsonschema 包 —— 本机 python3.6 没有）
# --------------------------------------------------------------------------
def _is_closure_list(v):
    if not isinstance(v, list):
        return False
    for e in v:
        if not isinstance(e, dict):
            return False
        if not isinstance(e.get('path'), str) or not e['path']:
            return False
        if not isinstance(e.get('sha256'), str) or not _HEX64.match(e['sha256']):
            return False
        if e.get('kind') not in ('repo', 'golden', 'external'):
            return False
    return True


def _is_script_list(v):
    if not isinstance(v, list) or not v:
        return False
    for e in v:
        if not isinstance(e, dict):
            return False
        if not isinstance(e.get('path'), str) or not e['path']:
            return False
        if not isinstance(e.get('sha256'), str) or not _HEX64.match(e['sha256']):
            return False
        if e.get('kind') not in ('repo', 'external'):
            return False
    return True


def _nonempty_str(v):
    return isinstance(v, str) and bool(v)


def _hex64(v):
    return isinstance(v, str) and bool(_HEX64.match(v))


def _hex40(v):
    return isinstance(v, str) and bool(_HEX40.match(v))


#: (dotted-path, 校验函数, 人读说明, 来源)
#: "来源"一栏是 reviewer 审这份 schema 时最该看的：每个字段到底谁写的、能不能被伪造。
FIELD_SPEC = [
    ('schema',              lambda v: v == CERT_SCHEMA,
     'schema 标识', '常量'),
    ('target',              _nonempty_str,
     '目标名（= verif/proof_certificates/<target>.json 的文件名）', 'receipt.top'),
    ('variant',             _nonempty_str,
     '实际被证明的 golden 顶层（FM_TOP / FM_VARIANTS 成员）', 'receipt.top'),
    ('ut_dir',              _nonempty_str,
     'verif/ut/<ut_dir>，复跑入口', 'fm_target_universe(commit)'),
    ('verdict',             _nonempty_str,
     '最终 verdict（合格性由 validator 用 QUALIFYING_VERDICTS 判）', 'receipt.verdict'),
    ('proof_mode',          lambda v: v in ('signoff-strict', 'assembly',
                                            'diagnostic-full', 'shadow'),
     'proof mode（= FM_MODE）', 'receipt.proof_config.fm_mode'),
    ('provisional',         lambda v: v is False,
     '必须 false —— dirty 工作树产出的 receipt 不得出证书', 'receipt.provisional'),
    ('impl_worktree_dirty', lambda v: v is False,
     '必须 false', 'receipt.impl_worktree_dirty'),
    ('impl_commit',         _hex40,
     'impl 侧被证明的 commit（40 hex）', 'receipt.impl_commit'),
    ('proof_commit',        _hex40,
     'run_proof.sh detached worktree 所钉的 commit', 'RUN_CONTEXT.tsv:commit'),
    ('proof_worktree_digest', _hex64,
     '证明期 worktree 全量 tracked 字节摘要（前后一致才出证据）', 'RUN_CONTEXT.tsv'),
    ('g1_canonical_id',     _nonempty_str,
     'G1 golden manifest 摘要（canonical ID 全文，不截断）', 'receipt.g1_canonical_id'),
    ('g1_manifest_sha256',  _hex64,
     'G1-canonical/MANIFEST.tsv 的 sha256', '生成时读 G1'),
    ('tool.name',           _nonempty_str,
     '工具名', '常量 fm_shell'),
    ('tool.version',        _nonempty_str,
     'Formality 版本串（从 fm.log banner 解析）', 'fm.log'),
    ('tool.build',          _nonempty_str,
     'Formality Build 号', 'fm.log'),
    ('tool.fm_shell_rc',    lambda v: v == 0,
     'fm_shell 退出码，必须 0', 'receipt.fm_shell_rc'),
    ('proof_config',        lambda v: isinstance(v, dict) and bool(v),
     'FM_MODE/allowlist/vmucp/pin/声明文件 hash/appvar 回读', 'receipt.proof_config'),
    ('proof_config_sha256', _hex64,
     'canon_digest(proof_config)，自洽校验用', '派生'),
    ('input_closure.golden', _is_closure_list,
     'ref 侧逐文件 (path, kind, sha256)', 'receipt.golden_closure'),
    ('input_closure.impl',   _is_closure_list,
     'impl 侧逐文件 (path, kind, sha256)', 'receipt.impl_closure'),
    ('input_closure.golden_sha256', _hex64,
     'closure_digest(golden)', '派生'),
    ('input_closure.impl_sha256',   _hex64,
     'closure_digest(impl)', '派生'),
    ('input_closure.repo_impl_files', lambda v: isinstance(v, int) and v > 0,
     'impl 闭包里 kind==repo 的条数，必须 >0（否则无从在父 commit 上复算）', '派生'),
    ('script_closure.entries', _is_script_list,
     'fm_eq.tcl / sidecar tcl 的逐文件 hash', 'sidecar/script_closure.list'),
    ('script_closure.sha256',  _hex64,
     'closure_digest(script entries)', '派生'),
    ('native_facts_sha256',  _hex64,
     'sidecar/native_facts.json 原始字节 sha256', 'sidecar'),
    ('native_result',        lambda v: isinstance(v, dict) and 'native_verdict' in v,
     'native verdict + stats + unmatched（供无 archive 时的事实核对）', 'native_facts'),
    ('result_sha256',        _hex64,
     'canon_digest({verdict, native_result})', '派生'),
    ('receipt_sha256',       _hex64,
     '派生本证书所用 receipt.json 的原始字节 sha256', 'evidence'),
    ('evidence_retention',   lambda v: v in RETENTION_MODES,
     'archived / attestation_only', '生成时由 --archive 决定'),
    ('reproduce.command',    _nonempty_str,
     '可复跑命令', '派生'),
    ('generated_at',         lambda v: isinstance(v, str) and bool(_ISO_Z.match(v)),
     'UTC 生成时刻', '生成时'),
    ('generator.script',     _nonempty_str,
     '生成器路径', '常量'),
    ('generator.version',    lambda v: isinstance(v, int) and v >= 1,
     '生成器版本', '常量'),
    ('generator.source_evidence_dir', _nonempty_str,
     '派生来源证据目录（untracked，仅作可审计线索）', '生成时'),
    ('run_id',               _nonempty_str,
     'FM_RUN_ID（sidecar 与 receipt 双向绑定过）', 'receipt.run_id'),
]

_REQUIRED_PATHS = [f[0] for f in FIELD_SPEC]


def _get(doc, dotted):
    cur = doc
    for part in dotted.split('.'):
        if not isinstance(cur, dict) or part not in cur:
            return (False, None)
        cur = cur[part]
    return (True, cur)


def validate_document(doc):
    """纯 schema 层校验（不碰 git）。返回错误串列表，空列表 = 通过。

    每条错误都带稳定前缀关键字，负测按关键字断言（不是按"不是 OK"断言）。
    """
    errs = []
    if not isinstance(doc, dict):
        return ['cert_not_object']
    if doc.get('schema') != CERT_SCHEMA:
        errs.append('cert_schema_mismatch:%s' % doc.get('schema'))
    for dotted, check, _desc, _src in FIELD_SPEC:
        present, val = _get(doc, dotted)
        if not present:
            errs.append('cert_missing_field:%s' % dotted)
            continue
        try:
            ok = bool(check(val))
        except Exception:                                   # noqa: BLE001
            ok = False
        if not ok:
            errs.append('cert_bad_field:%s' % dotted)
    if errs:
        # 字段都没齐就别谈自洽了，早返回避免 KeyError 噪声淹没真实原因
        return errs

    # --- 自洽：证书内的派生摘要必须真的等于对内容重算的结果 -----------------
    if canon_digest(doc['proof_config']) != doc['proof_config_sha256']:
        errs.append('cert_self_digest_mismatch:proof_config_sha256')
    if closure_digest(doc['input_closure']['golden']) != doc['input_closure']['golden_sha256']:
        errs.append('cert_self_digest_mismatch:input_closure.golden_sha256')
    if closure_digest(doc['input_closure']['impl']) != doc['input_closure']['impl_sha256']:
        errs.append('cert_self_digest_mismatch:input_closure.impl_sha256')
    if closure_digest(doc['script_closure']['entries']) != doc['script_closure']['sha256']:
        errs.append('cert_self_digest_mismatch:script_closure.sha256')
    if canon_digest({'verdict': doc['verdict'],
                     'native_result': doc['native_result']}) != doc['result_sha256']:
        errs.append('cert_self_digest_mismatch:result_sha256')
    n_repo = sum(1 for e in doc['input_closure']['impl'] if e.get('kind') == 'repo')
    if n_repo != doc['input_closure']['repo_impl_files']:
        errs.append('cert_self_digest_mismatch:input_closure.repo_impl_files')
    if n_repo == 0:
        errs.append('cert_no_repo_impl_closure_entry')

    # --- archive 语义：没有 archive hash 就不许声称"留有完整原件" -----------
    arc = doc.get('evidence_archive')
    if doc['evidence_retention'] == 'archived':
        if not isinstance(arc, dict) or not _hex64(arc.get('sha256')):
            errs.append('cert_archive_claim_without_hash')
        elif not _nonempty_str(arc.get('name')) or not isinstance(arc.get('size'), int):
            errs.append('cert_archive_record_incomplete')
    else:
        if arc not in (None, {}):
            errs.append('cert_archive_hash_without_claim')
    return errs


# --------------------------------------------------------------------------
# policy（tracked）：工具策略 + freeze commit + 合格 verdict 集
# --------------------------------------------------------------------------
def validate_policy(doc):
    errs = []
    if not isinstance(doc, dict):
        return ['policy_not_object']
    if doc.get('schema') != POLICY_SCHEMA:
        errs.append('policy_schema_mismatch:%s' % doc.get('schema'))
    if not isinstance(doc.get('qualifying_verdicts'), list) or not doc['qualifying_verdicts']:
        errs.append('policy_missing_field:qualifying_verdicts')
    elif set(doc['qualifying_verdicts']) - set(QUALIFYING_VERDICTS):
        errs.append('policy_qualifying_verdicts_wider_than_code')
    t = doc.get('tool')
    if not isinstance(t, dict) or not _nonempty_str(t.get('version')) \
            or not _nonempty_str(t.get('build')) or not _nonempty_str(t.get('name')):
        errs.append('policy_missing_field:tool')
    if not isinstance(doc.get('pinned_entry_appvars'), dict):
        errs.append('policy_missing_field:pinned_entry_appvars')
    if not isinstance(doc.get('script_closure_files'), list) or not doc['script_closure_files']:
        errs.append('policy_missing_field:script_closure_files')
    fc = doc.get('freeze_commit')
    if fc is not None and not _hex40(fc):
        errs.append('policy_bad_field:freeze_commit')
    if not _nonempty_str(doc.get('g1_canonical_id')):
        errs.append('policy_missing_field:g1_canonical_id')
    return errs


def load_policy(repo, commit):
    """从 commit 读 tracked policy。返回 (policy, None) 或 (None, reason)。"""
    blob = repo.show(commit, POLICY_PATH)
    if blob is None:
        return None, 'policy_not_in_commit:%s' % POLICY_PATH
    try:
        pol = json.loads(blob.decode('utf-8'))
    except Exception as e:                                  # noqa: BLE001
        return None, 'policy_unparsable:%s' % type(e).__name__
    errs = validate_policy(pol)
    if errs:
        return None, 'policy_invalid:%s' % errs[0]
    return pol, None


def load_certificate(repo, commit, target):
    """从 commit 读 tracked 证书。返回 (doc, blob_sha256, None) 或 (None, None, reason)。

    ★只走 `git show`。工作树里放一份证书**不会**被认。
    """
    path = '%s/%s.json' % (CERT_DIR, target)
    blob = repo.show(commit, path)
    if blob is None:
        return None, None, 'certificate_not_in_commit:%s' % target
    sha = hashlib.sha256(blob).hexdigest()
    try:
        doc = json.loads(blob.decode('utf-8'))
    except Exception as e:                                  # noqa: BLE001
        return None, sha, 'certificate_unparsable:%s:%s' % (target, type(e).__name__)
    return doc, sha, None


# --------------------------------------------------------------------------
# D57 的五条：在父 commit 上复算并判定一个 child 证书是否仍然有效
# --------------------------------------------------------------------------
def recompute_closure_at(repo, commit, entries):
    """用 `git show <commit>:<path>` 重算 kind=='repo' 条目的 sha256。

    复用 make_receipt.py:157-177 已在用的做法（D57 第 3 条要的就是它）。
    返回 (ok_count, changed[list of path], missing[list of path])。
    """
    ok, changed, missing = 0, [], []
    for e in entries:
        if e.get('kind') != 'repo':
            continue
        blob = repo.show(commit, e['path'])
        if blob is None:
            missing.append(e['path'])
        elif hashlib.sha256(blob).hexdigest() != e['sha256']:
            changed.append(e['path'])
        else:
            ok += 1
    return ok, changed, missing


def _g1_manifest(g1_root):
    """{basename: sha256}，来自 G1-canonical/MANIFEST.tsv。缺失返回 None。"""
    mp = pathlib.Path(g1_root) / 'MANIFEST.tsv'
    if not mp.exists():
        return None
    man = {}
    for ln in mp.read_text().splitlines():
        c = ln.split('\t')
        if len(c) == 3:
            man[c[2]] = c[0]
    return man


def impl_golden_entries(doc):
    """证书的 **impl 侧**闭包里 kind=='golden' 的条目。

    为什么单独拎出来：`recompute_closure_at` 只复算 kind=='repo'，
    **golden 条目被整个跳过**（它按设计只管"仓库里的字节有没有变"）。
    于是一个 child 可以把 golden 文件当作自己 impl 的一部分带进来，
    而 green_child 校验一个字都不会说。
    """
    return [e for e in (doc.get('input_closure', {}).get('impl') or [])
            if e.get('kind') == 'golden']


def validate_impl_golden_certified(repo, parent_commit, child, doc,
                                   policy=None, fm_targets=None,
                                   fm_targets_unresolved=None, g1_root=None,
                                   _seen=None, _depth=0):
    """★递归★：child 的 impl 闭包里若挂着 golden 文件，那些文件必须**自身**有合格证书，
    且该证书证的 golden 与这里挂的**逐字节同一份**。返回 True 或失败原因串。

    # 为什么必须有这一条（2026-09-20，LoadQueueReplay 手核时发现）

    `LqVAddrModule` 的 receipt 里 impl_closure 挂着三份 **golden** 文件
    （`golden-rtl/DelayN_13.sv` / `DelayNWithValid_152` / `_155`）——
    那一跑把 golden DelayN **两侧 elaborate、不黑盒**。它的 verdict 是干净的 SUCCEEDED。

    ★只看 verdict、不看 impl_closure 里挂着 golden，就会把一个**还带着 golden 依赖**的绿
     当成无条件绿。★ 而 `recompute_closure_at` 跳过 golden 条目，所以原来的九条一条都不响。

    本例最后是闭的（三个 DelayN 各有独立 clean 证明，且证的 golden 与这里挂的逐字节同一份），
    但★"查过"和"绿"是两件事★：一次人工核对回答"此刻对不对"，
    一道闸回答"以后变了会不会有人喊"。这个函数是后者。

    递归：golden-in-impl 的那个模块的证书，自己也可能再挂 golden，故继续往下查；
    `_seen` 防环，`_depth` 兜底（证书链不该深过这个数，深了就是出了别的问题）。
    """
    MAX_DEPTH = 8
    if _depth > MAX_DEPTH:
        return 'green_child_impl_golden_chain_too_deep:%s' % child
    if _seen is None:
        _seen = set()
    gold = impl_golden_entries(doc)
    for e in gold:
        base = os.path.basename(e.get('path') or '')
        if not base.endswith('.sv'):
            return 'green_child_impl_golden_unexpected_path:%s:%s' % (child, base or '?')
        mod = base[:-3]
        if mod in _seen:
            continue
        _seen.add(mod)
        # (i) 那个模块必须自身是 FM target —— 与 D57 尾条同一条判据，不许在这里放松
        if fm_targets is None:
            return 'green_child_impl_golden_universe_unavailable:%s' % child
        if mod not in fm_targets:
            if fm_targets_unresolved:
                return 'green_child_impl_golden_universe_unresolved:%s:%s' % (child, mod)
            return 'green_child_impl_golden_not_fm_target:%s:%s' % (child, mod)
        # (ii) 必须有 tracked 证书（只走 git show，工作树放一份不算）
        gdoc, _gsha, gerr = load_certificate(repo, parent_commit, mod)
        if gerr:
            return 'green_child_impl_golden_uncertified:%s:%s:%s' % (child, mod, gerr)
        derrs = validate_document(gdoc)
        if derrs:
            return 'green_child_impl_golden_cert_invalid:%s:%s:%s' % (child, mod, derrs[0])
        # (iii) 合格 verdict
        if gdoc.get('verdict') not in QUALIFYING_VERDICTS:
            return ('green_child_impl_golden_verdict_not_qualifying:%s:%s=%s'
                    % (child, mod, gdoc.get('verdict')))
        # (iv) ★字节对齐★：它证的 golden 必须就是这里 impl 侧挂着的那一份
        want = e.get('sha256')
        got = [g for g in (gdoc.get('input_closure', {}).get('golden') or [])
               if os.path.basename(g.get('path') or '') == base]
        if not got:
            return ('green_child_impl_golden_cert_lacks_that_golden:%s:%s:%s'
                    % (child, mod, base))
        if got[0].get('sha256') != want:
            return ('green_child_impl_golden_bytes_mismatch:%s:%s:cert=%s,impl=%s'
                    % (child, mod, (got[0].get('sha256') or '?')[:12], (want or '?')[:12]))
        # (v) 它的 impl 若又挂 golden，继续往下（递归）
        r = validate_impl_golden_certified(
            repo, parent_commit, mod, gdoc, policy=policy, fm_targets=fm_targets,
            fm_targets_unresolved=fm_targets_unresolved, g1_root=g1_root,
            _seen=_seen, _depth=_depth + 1)
        if r is not True:
            return r
    return True


def validate_child_certificate(repo, parent_commit, child, declared_sha,
                               expect_canonical=None, policy=None,
                               fm_targets=None, fm_targets_unresolved=None,
                               g1_root=None):
    """D57 五条的落地。返回 True 或**失败原因串**（永不抛出、永不 fail-open）。

    参数全部来自调用方已有的上下文：
      repo/parent_commit  = 父 proof 的 `--impl-commit`（ut_common.mk 传的 git rev-parse HEAD）
      declared_sha        = allow 条目里写死的 certificate_sha256
      expect_canonical    = 父本次的 G1 canonical ID
      fm_targets          = fm_target_universe.targets_at(parent_commit) 的结果
    """
    # 0) 上下文齐全才谈判定 —— 缺就拒（fail-closed）
    if not parent_commit:
        return 'green_child_no_commit_context'
    if not repo.available():
        return 'green_child_git_unavailable'

    # (D57 尾条) child 必须是真的 FM target。不是 FM target 的 child 只能走
    # 两侧 inline elaborate 或新建 AUX leaf target，不得用 allow 绕过。
    if fm_targets is None:
        return 'green_child_target_universe_unavailable'
    if child not in fm_targets:
        if fm_targets_unresolved:
            # 全集没完全展开时不许下"不是 target"的结论，也不许放行
            return 'green_child_target_universe_unresolved:%s' % child
        return 'green_child_not_fm_target:%s' % child

    # 1) 从**当前提交**读 tracked certificate
    doc, blob_sha, err = load_certificate(repo, parent_commit, child)
    if err:
        return 'green_child_%s' % err
    if not declared_sha:
        return 'green_child_declaration_without_certificate_sha256:%s' % child
    if declared_sha != blob_sha:
        return ('green_child_certificate_sha_mismatch:%s:declared=%s,actual=%s'
                % (child, declared_sha[:12], blob_sha[:12]))
    errs = validate_document(doc)
    if errs:
        return 'green_child_certificate_invalid:%s:%s' % (child, errs[0])
    if doc['target'] != child:
        return 'green_child_certificate_target_mismatch:%s!=%s' % (doc['target'], child)

    # 2) 只接受规定的合格 verdict
    qual = policy['qualifying_verdicts'] if policy else list(QUALIFYING_VERDICTS)
    if doc['verdict'] not in qual:
        return 'green_child_verdict_not_qualifying:%s=%s' % (child, doc['verdict'])

    # 4a) 配置变化 → 失效：canonical 必须与父本次同源
    if expect_canonical and doc['g1_canonical_id'] != expect_canonical:
        return 'green_child_canonical_mismatch:%s' % child
    if policy and policy.get('g1_canonical_id') and \
            doc['g1_canonical_id'] != policy['g1_canonical_id']:
        return 'green_child_canonical_not_policy:%s' % child

    # 4b) 工具策略变化 → 失效
    if policy is None:
        return 'green_child_policy_missing'
    ptool = policy['tool']
    if doc['tool'].get('name') != ptool.get('name') or \
            doc['tool'].get('version') != ptool.get('version') or \
            doc['tool'].get('build') != ptool.get('build'):
        return ('green_child_tool_policy_mismatch:%s:%s/%s vs policy %s/%s'
                % (child, doc['tool'].get('version'), doc['tool'].get('build'),
                   ptool.get('version'), ptool.get('build')))
    appvars = (doc['proof_config'].get('entry_appvars_readback') or {})
    for k, want in policy['pinned_entry_appvars'].items():
        if appvars.get(k) != want:
            return ('green_child_appvar_policy_mismatch:%s:%s=%r!=%r'
                    % (child, k, appvars.get(k), want))

    # 4c) 声明文件（allow / dead_ref）在父 commit 上必须仍是证书记录的那份字节
    for kind, rec in (doc['proof_config'].get('declarations') or {}).items():
        p = rec.get('path')
        if not p:
            return 'green_child_declaration_record_incomplete:%s:%s' % (child, kind)
        blob = repo.show(parent_commit, p)
        if blob is None:
            return 'green_child_declaration_missing_at_parent:%s:%s' % (child, p)
        if hashlib.sha256(blob).hexdigest() != rec.get('sha256'):
            return 'green_child_declaration_changed:%s:%s' % (child, p)

    # 3) 用 git show / 当前提交重新计算 child closure，并与证书一致
    ok, changed, missing = recompute_closure_at(repo, parent_commit,
                                                doc['input_closure']['impl'])
    if missing:
        return 'green_child_closure_missing_at_parent:%s:%s' % (child, missing[0])
    if changed:
        return 'green_child_closure_changed:%s:%s' % (child, changed[0])
    if ok == 0:
        return 'green_child_closure_empty:%s' % child

    # 3b) script closure（工具脚本也是证明输入）同样在父 commit 上复算
    sok, schanged, smissing = recompute_closure_at(repo, parent_commit,
                                                   doc['script_closure']['entries'])
    if smissing:
        return 'green_child_script_closure_missing_at_parent:%s:%s' % (child, smissing[0])
    if schanged:
        return 'green_child_script_closure_changed:%s:%s' % (child, schanged[0])
    want_scripts = set(policy['script_closure_files'])
    have_scripts = {e['path'] for e in doc['script_closure']['entries']
                    if e.get('kind') == 'repo'}
    if want_scripts - have_scripts:
        return ('green_child_script_closure_incomplete:%s:%s'
                % (child, sorted(want_scripts - have_scripts)[0]))

    # 3c) golden 闭包对 G1 MANIFEST（golden 换字节 = 换被比对对象）
    if g1_root:
        man = _g1_manifest(g1_root)
        if man:
            for e in doc['input_closure']['golden']:
                base = e['path'].split('/')[-1]
                if base in man and man[base] != e['sha256']:
                    return 'green_child_golden_changed:%s:%s' % (child, base)

    # 3d) ★递归★ child 的 **impl** 闭包里若挂着 golden 文件，那些必须自身有合格证书，
    #     且证的 golden 与这里挂的逐字节同一份。原来的九条一条都不管这个：
    #     `recompute_closure_at` 只复算 kind=='repo'，golden 条目被整个跳过。
    r = validate_impl_golden_certified(
        repo, parent_commit, child, doc, policy=policy, fm_targets=fm_targets,
        fm_targets_unresolved=fm_targets_unresolved, g1_root=g1_root)
    if r is not True:
        return r

    # 5) child 必须在 freeze commit 上 clean 重跑过；且其 commit 在父之前（或同一个）
    if not repo.is_ancestor(doc['impl_commit'], parent_commit):
        return ('green_child_commit_not_ancestor:%s=%s'
                % (child, doc['impl_commit'][:12]))
    fc = policy.get('freeze_commit')
    if not fc:
        return 'green_child_policy_no_freeze_commit'
    if doc['impl_commit'] != fc:
        return ('green_child_not_freeze_commit:%s=%s,policy=%s'
                % (child, doc['impl_commit'][:12], fc[:12]))
    return True


# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------
def schema_json():
    """把 FIELD_SPEC 导成可 review / 可 diff 的机读 schema。"""
    return {
        'schema': CERT_SCHEMA,
        'qualifying_verdicts': list(QUALIFYING_VERDICTS),
        'retention_modes': list(RETENTION_MODES),
        'required_fields': [
            {'field': d, 'description': desc, 'source': src}
            for d, _c, desc, src in FIELD_SPEC],
        'self_consistency': [
            'proof_config_sha256      == canon_digest(proof_config)',
            'input_closure.*_sha256   == closure_digest(input_closure.*)',
            'script_closure.sha256    == closure_digest(script_closure.entries)',
            'result_sha256            == canon_digest({verdict, native_result})',
            'input_closure.repo_impl_files == count(kind=="repo") > 0',
        ],
        'archive_rule': ('evidence_retention=="archived" 必须有 evidence_archive.sha256；'
                         '"attestation_only" 必须 evidence_archive==null。'
                         '无 archive 的证书只是可复跑 attestation，'
                         '不得声称 clean clone 含完整历史原件。'),
    }


def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument('--dump-schema', action='store_true')
    ap.add_argument('--lint', nargs='*', default=None, help='校验证书文件（schema 层）')
    ap.add_argument('--lint-policy', default=None)
    a = ap.parse_args()
    if a.dump_schema:
        print(json.dumps(schema_json(), ensure_ascii=False, indent=1))
        return 0
    rc = 0
    for f in (a.lint or []):
        try:
            doc = json.loads(pathlib.Path(f).read_text())
        except Exception as e:                              # noqa: BLE001
            print('%s\tUNPARSABLE\t%r' % (f, e))
            rc = 1
            continue
        errs = validate_document(doc)
        print('%s\t%s\t%s' % (f, 'OK' if not errs else 'INVALID', ';'.join(errs[:4])))
        if errs:
            rc = 1
    if a.lint_policy:
        doc = json.loads(pathlib.Path(a.lint_policy).read_text())
        errs = validate_policy(doc)
        print('%s\t%s\t%s' % (a.lint_policy, 'OK' if not errs else 'INVALID',
                              ';'.join(errs[:4])))
        if errs:
            rc = 1
    if not a.dump_schema and a.lint is None and not a.lint_policy:
        ap.print_help()
        return 2
    return rc


if __name__ == '__main__':
    sys.exit(main())
