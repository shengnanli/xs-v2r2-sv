#!/usr/bin/env bash
# B2 clean 重生 runner(2026-07 五审版, fail-closed + 事务式证据)。
#
# 五审修订:
#  - signoff commit 在**注入 git shim 之前**用系统 git 捕获, 并校验 b2 相关 tracked 文件 clean。
#  - **TRUST_ANCHORS.tsv 为唯一信任根**: firtool/mill(exec)/JDK(全目录)/源码tar/closure 全部对锚交叉校验。
#  - **执行锁定工具**: mill 直接用 bundle 内锁定 dist(bin/mill=hash 33634609), COURSIER_CACHE=隔离
#    bundle(全缓存拷贝, 106 jar 闭包已对 manifest 校验), COURSIER_MODE=offline(任何网络解析即失败)。
#  - **事务式证据**: 构建+比对阶段写 tmp 证据目录(log 在其中); 阶段结束后日志已关闭, finalize 阶段
#    校验全部证据 hash → 写 COMPLETE marker → 原子 rename 为最终目录。任何证据缺失即失败。
# 产出: <RB>/b2_evidence/(COMPLETE + provenance + log + 1860 result json + normalized manifest)
# 本 runner 的 rc=0 仅表示"本次 attempt 全 gate 通过", canonical 晋升由人工按证据评审。
set -euo pipefail

Q=/home/eda/xs-env/G0-quarantine
SIGNOFF="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RB="${1:-/home/eda/xs-env/G0-rebuilt2}"
SHIM="$SIGNOFF/scripts/b2/git-shim"
LOCK="$SIGNOFF/scripts/b2/TOOL_LOCK.tsv"
ANCH="$SIGNOFF/scripts/b2/TRUST_ANCHORS.tsv"
BUNDLE=/home/eda/xs-env/b2-toolchain-bundle
export GIT_SHIM_DATA="$Q/G0-source-provenance/git-shim-inputs"

fail() { echo "B2-FAIL: $*" >&2; exit 1; }
anchor() { awk -F'\t' -v k="$1" '$1==k{print $2}' "$ANCH"; }
lockv()  { awk -F'\t' -v k="$1" '$1==k{print $2}' "$LOCK"; }

# ---------- 阶段 0: shim 注入前, 系统 git 捕获 signoff commit + clean 校验 ----------
SYSGIT=$(command -v git) || fail "系统 git 不可用"
SIGNOFF_COMMIT=$("$SYSGIT" -C "$SIGNOFF" rev-parse HEAD) || fail "无法取 signoff commit"
dirty=$("$SYSGIT" -C "$SIGNOFF" status --porcelain -- scripts/b2 scripts/fm_verdict.py | wc -l)
[ "$dirty" -eq 0 ] || fail "signoff b2/verdict 脚本有未提交改动($dirty), 证据无法绑定单一 commit"
echo "signoff commit: $SIGNOFF_COMMIT (b2 脚本 clean)"

# ---------- 阶段 1: 前置校验(唯一信任根 TRUST_ANCHORS) ----------
[ -f "$Q/G0-source-canonical.tar.gz" ] || fail "缺 canonical 源码 tar"
[ "$(sha256sum "$Q/G0-source-canonical.tar.gz" | awk '{print $1}')" = "$(anchor canonical_source_tar)" ] \
  || fail "源码 tar 不匹配 TRUST_ANCHORS"
[ -d "$GIT_SHIM_DATA" ] || fail "缺 git-shim-inputs"
SHIMH_NOW=$(LC_ALL=C find "$GIT_SHIM_DATA" -type f | LC_ALL=C sort | xargs sha256sum | sha256sum | awk '{print $1}')
[ "$SHIMH_NOW" = "$(lockv git_shim_inputs_digest)" ] || fail "git-shim-inputs digest 不匹配"
FT=$(lockv firtool_path)
[ "$(sha256sum "$FT" | awk '{print $1}')" = "$(anchor firtool)" ] || fail "firtool 不匹配 TRUST_ANCHORS"
# 执行的 mill = bundle/bin/mill, 对锚校验
[ -x "$BUNDLE/bin/mill" ] || fail "bundle 缺 bin/mill"
[ "$(sha256sum "$BUNDLE/bin/mill" | awk '{print $1}')" = "$(anchor mill_exec)" ] || fail "bundle mill 不匹配 TRUST_ANCHORS"
# JDK 全目录 digest 对锚
JDK=$(lockv jdk)
JD_NOW=$(LC_ALL=C find "$JDK" -type f | LC_ALL=C sort | xargs sha256sum 2>/dev/null | sha256sum | awk '{print $1}')
[ "$JD_NOW" = "$(anchor jdk_dir_digest)" ] || fail "JDK 目录 digest 不匹配 TRUST_ANCHORS"
# bundle 内闭包校验(106 jar 对 manifest+锚)
python3 - <<'PY' || fail "bundle 闭包校验失败"
import hashlib, os, sys
B='/home/eda/xs-env/b2-toolchain-bundle/coursier-cache'
H=os.path.dirname(os.path.abspath('/home/eda/xs-env/xs-signoff/scripts/b2/x'))
anc=dict(l.rstrip('\n').split('\t')[:2] for l in open(os.path.join(H,'TRUST_ANCHORS.tsv'))
         if not l.startswith('#') and not l.startswith('key\t'))
rows=[l.rstrip('\n').split('\t') for l in open(os.path.join(H,'coursier_closure.manifest.tsv'))
      if not l.startswith('#') and not l.startswith('path\t')]
h_all=hashlib.sha256(); bad=0
for p,sz,h in rows:
    bp=os.path.join(B,p.replace('/home/eda/.cache/coursier/',''))
    try: b=open(bp,'rb').read()
    except FileNotFoundError: bad+=1; continue
    if len(b)!=int(sz) or hashlib.sha256(b).hexdigest()!=h: bad+=1; continue
    h_all.update(b)
sys.exit(0 if bad==0 and h_all.hexdigest()==anc['coursier_closure'] else 1)
PY
echo "前置校验全过(唯一信任根 TRUST_ANCHORS)"

# ---------- 阶段 2: 全新目录解包 + 隔离离线构建(logged, 子shell内→日志会正常关闭) ----------
[ -e "$RB" ] && fail "RB=$RB 已存在(不覆盖)"
mkdir -p "$RB"
EV_TMP="$RB/b2_evidence.tmp"; mkdir -p "$EV_TMP"
LOG="$EV_TMP/b2_regen.log"

set +e
(
  set -euo pipefail
  cd "$RB"
  tar xzf "$Q/G0-source-canonical.tar.gz"
  bad=0
  while IFS=$'\t' read -r f sz h; do
    [ "$(sha256sum "$f" 2>/dev/null | cut -d' ' -f1)" = "$h" ] || { echo "SRC-MISMATCH $f"; bad=$((bad+1)); }
  done < "$Q/G0-source-canonical.manifest.tsv"
  [ "$bad" -eq 0 ] || { echo "源码解包 $bad 不匹配"; exit 1; }
  echo "源码解包校验 OK"
  export JAVA_HOME="$JDK"
  export PATH="$SHIM:$BUNDLE/bin:$(dirname "$FT"):$JAVA_HOME/bin:/usr/bin:/bin"
  export COURSIER_CACHE="$BUNDLE/coursier-cache"
  export COURSIER_MODE=offline
  export NOOP_HOME="$RB" NEMU_HOME="$RB"
  command -v mill | grep -q "$BUNDLE/bin/mill" || { echo "mill 不是锁定 dist"; exit 1; }
  make sim-verilog CONFIG=KunminghuV2Config
  [ -f build/rtl/SimTop.sv ] || { echo "无 SimTop.sv"; exit 1; }
  echo "PHASE2-DONE"
) > "$LOG" 2>&1
rc=$?
set -e
grep -q "PHASE2-DONE" "$LOG" || { tail -5 "$LOG" >&2; fail "构建阶段失败 rc=$rc(log: $LOG)"; }
echo "构建阶段完成(log 已关闭)"

# ---------- 阶段 3: 1860 canonical gate(0644 staging) ----------
STAGE="$RB/canonical_staging"; mkdir -p "$STAGE"
cp -r "$RB/build/rtl/." "$STAGE/"
find "$STAGE" -type f -exec chmod 0644 {} +
CROOT=$(echo "$RB" | sed 's|^/||')
python3 "$SIGNOFF/scripts/b2/b2_compare_1860.py" "$Q" "$STAGE" --cand-root "$CROOT" --out "$EV_TMP" \
  || fail "1860 canonical gate 未过"

# ---------- 阶段 4: finalize(校验证据完整→COMPLETE→原子rename) ----------
for f in b2_regen.log b2_1860_result.json normalized.manifest.tsv; do
  [ -s "$EV_TMP/$f" ] || fail "证据缺失: $f"
done
grep -q '"result": "CANONICAL_ARTIFACT_REPRODUCED"' "$EV_TMP/b2_1860_result.json" || fail "1860 result 非 canonical"
{
  echo "signoff_commit: $SIGNOFF_COMMIT"
  echo "date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "rb_dir: $RB"
  sha256sum "$EV_TMP/b2_regen.log" "$EV_TMP/b2_1860_result.json" "$EV_TMP/normalized.manifest.tsv" \
            "$SIGNOFF/scripts/b2/b2_regen.sh" "$SHIM/git" "$SIGNOFF/scripts/b2/b2_compare_1860.py" \
            "$ANCH" "$SIGNOFF/scripts/b2/coursier_closure.manifest.tsv" "$BUNDLE/bin/mill"
} > "$EV_TMP/provenance.txt"
echo "B2_ATTEMPT_COMPLETE $(date -u +%s)" > "$EV_TMP/COMPLETE"
sync
mv "$EV_TMP" "$RB/b2_evidence"
echo "RESULT: B2-ATTEMPT-ALL-GATES-PASSED(证据: $RB/b2_evidence; canonical 晋升须人工评审)"
