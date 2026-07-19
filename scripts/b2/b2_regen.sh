#!/usr/bin/env bash
# B2 clean 重生 runner(2026-07 六审版, fail-closed + 事务式自证证据 + 真隔离离线)。
#
# 六审修订(独立 fresh-run 4 秒失败后的最小 GO 补丁):
#  - COURSIER_CACHE 指到 **v1 层**(coursier 默认 cache=~/.cache/coursier/v1, 原指父目录=根错配)。
#  - 工具闭包=**完整 bundle 树**(1990 文件/171 JAR/227 POM, bundle_tree.manifest.tsv 全量
#    type/mode/size/hash), 构建**前后**都校验(堵 TOCTOU); 非只 106 JAR。
#  - 真隔离: fresh HOME/XDG_CACHE_HOME, 清 JAVA_TOOL_OPTIONS/_JAVA_OPTIONS/JAVA_OPTS,
#    CHISEL_FIRTOOL_PATH 强制锁定 firtool; **unshare -rn OS 级断网**执行构建。
#  - phase2 门 = rc==0 **且** 行级精确 marker(grep -qx PHASE2-DONE), 单 marker 注入不再通过。
#  - finalize 前**再次**校验受控源码等于捕获 commit(防执行中变脏, 含 .pyc——已入 .gitignore)。
#  - 证据自证: evidence.manifest.tsv(精确文件集+hash)+ COMPLETE 绑定其完整 sha256;
#    独立验证器 b2_verify_evidence.py 收尾强制通过。
#  - harness 锚入 gate: fresh build/dts|json 规范化(去 model 行)后须与冻结 G0 版一致。
# rc=0 仅表示"本次 attempt 全 gate 通过", canonical 晋升由人工按证据评审。
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

verify_bundle() {  # 完整 bundle 树校验(1990 文件)
  python3 - <<'PY'
import os, hashlib, stat, sys
B='/home/eda/xs-env/b2-toolchain-bundle/coursier-cache'
MF='/home/eda/xs-env/xs-signoff/scripts/b2/bundle_tree.manifest.tsv'
want={}
for l in open(MF):
    if l.startswith('#') or l.startswith('path\t'): continue
    p,ty,mo,sz,h=l.rstrip('\n').split('\t'); want[p]=(int(sz),h)
have=set()
bad=0
for root,dirs,files in os.walk(B):
    for fn in files:
        p=os.path.join(root,fn); rel=os.path.relpath(p,B); have.add(rel)
        if rel not in want: bad+=1; continue
        sz,h=want[rel]
        if os.path.getsize(p)!=sz or hashlib.sha256(open(p,'rb').read()).hexdigest()!=h: bad+=1
miss=len(set(want)-have)
print(f"bundle树: want={len(want)} have={len(have)} miss={miss} bad={bad}")
sys.exit(0 if miss==0 and bad==0 and len(have)==len(want) else 1)
PY
}

# ---------- 阶段 0: shim 前系统 git 捕获 commit + clean ----------
SYSGIT=$(command -v git) || fail "系统 git 不可用"
SIGNOFF_COMMIT=$("$SYSGIT" -C "$SIGNOFF" rev-parse HEAD) || fail "取 signoff commit 失败"
clean_check() {
  "$SYSGIT" -C "$SIGNOFF" status --porcelain -- scripts/b2 scripts/fm_verdict.py | wc -l
}
[ "$(clean_check)" -eq 0 ] || fail "b2/verdict 脚本区不 clean, 证据无法绑定单一 commit"
echo "signoff commit: $SIGNOFF_COMMIT (clean)"

# ---------- 阶段 1: 前置校验(TRUST_ANCHORS 唯一信任根) ----------
[ "$(sha256sum "$Q/G0-source-canonical.tar.gz" | awk '{print $1}')" = "$(anchor canonical_source_tar)" ] || fail "源码tar≠锚"
SHIMH=$(LC_ALL=C find "$GIT_SHIM_DATA" -type f | LC_ALL=C sort | xargs sha256sum | sha256sum | awk '{print $1}')
[ "$SHIMH" = "$(lockv git_shim_inputs_digest)" ] || fail "shim-inputs≠锁"
FT=$(lockv firtool_path)
[ "$(sha256sum "$FT" | awk '{print $1}')" = "$(anchor firtool)" ] || fail "firtool≠锚"
[ -x "$BUNDLE/bin/mill" ] || fail "bundle缺mill"
[ "$(sha256sum "$BUNDLE/bin/mill" | awk '{print $1}')" = "$(anchor mill_exec)" ] || fail "mill≠锚"
JDK=$(lockv jdk)
JD=$(LC_ALL=C find "$JDK" -type f | LC_ALL=C sort | xargs sha256sum 2>/dev/null | sha256sum | awk '{print $1}')
[ "$JD" = "$(anchor jdk_dir_digest)" ] || fail "JDK目录≠锚"
[ "$(sha256sum "$SIGNOFF/scripts/b2/bundle_tree.manifest.tsv" | awk '{print $1}')" = "$(anchor bundle_tree_manifest)" ] || fail "bundle manifest≠锚"
verify_bundle || fail "bundle 树校验失败(构建前)"
echo "前置校验全过(唯一信任根)"

# ---------- 阶段 2: 全新目录 + 真隔离离线构建(logged 子shell, 结束即日志关闭) ----------
[ -e "$RB" ] && fail "RB=$RB 已存在"
mkdir -p "$RB"
EV_TMP="$RB/b2_evidence.tmp"; mkdir -p "$EV_TMP"
LOG="$EV_TMP/b2_regen.log"
ISOHOME="$RB/iso_home"; mkdir -p "$ISOHOME"

set +e
(
  set -euo pipefail
  cd "$RB"
  tar xzf "$Q/G0-source-canonical.tar.gz"
  bad=0
  while IFS=$'\t' read -r f sz h; do
    [ "$(sha256sum "$f" 2>/dev/null | cut -d' ' -f1)" = "$h" ] || { echo "SRC-MISMATCH $f"; bad=$((bad+1)); }
  done < "$Q/G0-source-canonical.manifest.tsv"
  [ "$bad" -eq 0 ] || { echo "源码 $bad 不匹配"; exit 1; }
  echo "源码解包校验 OK"
  export JAVA_HOME="$JDK"
  export PATH="$SHIM:$BUNDLE/bin:$(dirname "$FT"):$JAVA_HOME/bin:/usr/bin:/bin"
  export HOME="$ISOHOME" XDG_CACHE_HOME="$ISOHOME/.cache"
  export COURSIER_CACHE="$BUNDLE/coursier-cache/v1"    # 六审: 指到 v1 层
  export COURSIER_MODE=offline
  export CHISEL_FIRTOOL_PATH="$(dirname "$FT")"        # 强制锁定 firtool
  unset JAVA_TOOL_OPTIONS _JAVA_OPTIONS JAVA_OPTS COURSIER_REPOSITORIES 2>/dev/null || true
  export NOOP_HOME="$RB" NEMU_HOME="$RB"
  command -v mill | grep -qx "$BUNDLE/bin/mill" || { echo "mill非锁定dist"; exit 1; }
  # OS 级断网(unshare user+net ns, 环境继承)
  unshare -rn make sim-verilog CONFIG=KunminghuV2Config
  [ -f build/rtl/SimTop.sv ] || { echo "无SimTop.sv"; exit 1; }
  echo "PHASE2-DONE"
) > "$LOG" 2>&1
rc=$?
set -e
echo "PHASE2-RC: $rc" >> "$LOG"
# 六审: rc==0 且 行级 marker 同时要求
{ [ "$rc" -eq 0 ] && grep -qx "PHASE2-DONE" "$LOG"; } || { tail -8 "$LOG" >&2; fail "构建阶段失败 rc=$rc"; }
echo "构建阶段完成(rc=0 + marker, 日志已关闭)"

# ---------- 阶段 3: 闭包后校验(TOCTOU) + 1860 gate + harness gate ----------
verify_bundle || fail "bundle 树校验失败(构建后=TOCTOU)"
STAGE="$RB/canonical_staging"; mkdir -p "$STAGE"
cp -r "$RB/build/rtl/." "$STAGE/"
find "$STAGE" -type f -exec chmod 0644 {} +
CROOT=$(echo "$RB" | sed 's|^/||')
python3 "$SIGNOFF/scripts/b2/b2_compare_1860.py" "$Q" "$STAGE" --cand-root "$CROOT" --out "$EV_TMP" \
  || fail "1860 canonical gate 未过"
# harness gate: fresh dts/json 规范化(去 model 行)后与冻结 G0 版一致
for hf in dts json; do
  fz="$Q/harness-frozen/build_${hf}.G0"
  fr="$RB/build/$hf"
  [ -f "$fr" ] || fail "fresh build/$hf 缺失"
  a=$(grep -v '"model"\|model = ' "$fz" | sha256sum | awk '{print $1}')
  b=$(grep -v '"model"\|model = ' "$fr" | sha256sum | awk '{print $1}')
  [ "$a" = "$b" ] || fail "harness $hf 规范化后不一致(非 model 行差异)"
done
echo "harness gate OK(dts/json 仅 model 行差异)"

# ---------- 阶段 4: finalize(clean 复查 + 证据自证 + 原子提交) ----------
[ "$(clean_check)" -eq 0 ] || fail "执行中 b2 脚本区变脏(finalize 拒绝)"
[ "$("$SYSGIT" -C "$SIGNOFF" rev-parse HEAD)" = "$SIGNOFF_COMMIT" ] || fail "commit 变了"
{
  echo "signoff_commit: $SIGNOFF_COMMIT"
  echo "date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "rb_dir: $RB"
  echo "bundle_tree_manifest_sha256: $(anchor bundle_tree_manifest)"
  sha256sum "$SIGNOFF/scripts/b2/b2_regen.sh" "$SHIM/git" "$SIGNOFF/scripts/b2/b2_compare_1860.py" \
            "$SIGNOFF/scripts/b2/b2_verify_evidence.py" "$ANCH" "$SIGNOFF/scripts/b2/bundle_tree.manifest.tsv" \
            "$BUNDLE/bin/mill"
} > "$EV_TMP/provenance.txt"
# 证据 manifest(精确文件集; 不含 manifest 自身与 COMPLETE)
( cd "$EV_TMP" && LC_ALL=C find . -maxdepth 1 -type f ! -name evidence.manifest.tsv ! -name COMPLETE \
    | sed 's|^\./||' | LC_ALL=C sort | while read -r f; do
      printf '%s\t%s\t%s\n' "$f" "$(stat -c%s "$f")" "$(sha256sum "$f"|cut -d' ' -f1)"
    done ) > "$EV_TMP/evidence.manifest.tsv"
MSHA=$(sha256sum "$EV_TMP/evidence.manifest.tsv" | awk '{print $1}')
echo "B2_ATTEMPT_COMPLETE $(date +%s) manifest_sha256=$MSHA" > "$EV_TMP/COMPLETE"
sync
mv "$EV_TMP" "$RB/b2_evidence"
python3 "$SIGNOFF/scripts/b2/b2_verify_evidence.py" "$RB/b2_evidence" || fail "证据自证未过"
echo "RESULT: B2-ATTEMPT-ALL-GATES-PASSED(证据: $RB/b2_evidence, 独立验证器通过; canonical 晋升须人工评审)"
