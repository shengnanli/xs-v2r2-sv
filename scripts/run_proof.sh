#!/usr/bin/env bash
# run_proof.sh —— 在 detached clean worktree 里跑一个目标的 proof（codex 0140 P0-2）。
#
# 为什么要 worktree：receipt 必须绑定 **committed 字节**。在活动工作树里跑，证明输入
# 可能在跑的过程中被改，事后再 hash 就成了"执行 A、记录 B"。这里的做法是：
#   1. 要求仓库 clean（有未提交改动直接退出，不给绕过开关）；
#   2. 在 HEAD 上开一个 detached worktree（只读意义上的隔离：别人改活动树不影响它）；
#   3. 在 worktree 内跑 make fm-<target>，receipt 随之产生，dirty 必然为 false；
#   4. 跑前/跑后对 impl 闭包文件与 HEAD 各取一次摘要，要求完全一致；
#   5. 把 receipt / native_facts / 报告 收进证据目录，然后删掉 worktree。
#
# 用法: scripts/run_proof.sh <ut_dir> <target> [<target>...]
#   EVIDENCE_ROOT=<dir>  证据落地根目录（默认 <repo>/evidence/<commit>）
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
UT_DIR="${1:?用法: run_proof.sh <ut_dir> <target>...}"; shift
TARGETS=("$@")
[[ ${#TARGETS[@]} -gt 0 ]] || { echo "ERROR: 未指定 target" >&2; exit 2; }

cd "$REPO"
# dirty 判定只看**会进入证明闭包的路径**（rtl / verif / scripts / docs 里的声明与工具）。
# 仓库里出现无关新文件（如正在写的分析脚本）不该把证明拦死，但凡是证明会读到的字节
# 必须 committed。新增未跟踪文件同样算 dirty——它可能被 Makefile 引用。
# 证明钉在**某个 commit 的字节**上，与活动工作树当前状态无关：
#   PROOF_COMMIT=<rev>  显式指定（批跑用：钉住一个 commit，期间主线可继续改 RTL/加脚本）
#   未指定             = HEAD，此时要求证明输入路径 clean，
#                        否则"跑的是工作树、记的是 HEAD"就对不上。
if [[ -n "${PROOF_COMMIT:-}" ]]; then
  COMMIT="$(git rev-parse "$PROOF_COMMIT^{commit}")" || {
    echo "ERROR: PROOF_COMMIT=$PROOF_COMMIT 无法解析" >&2; exit 3; }
else
  DIRTY="$(git status --porcelain -- rtl verif scripts)"
  if [[ -n "$DIRTY" ]]; then
    echo "ERROR: 证明输入路径 dirty（rtl/verif/scripts）。要么提交，要么用 PROOF_COMMIT=<rev> 钉住一个 commit：" >&2
    echo "$DIRTY" | head -5 >&2
    exit 3
  fi
  COMMIT="$(git rev-parse HEAD)"
fi
HEAD_BEFORE="$COMMIT"
EVID="${EVIDENCE_ROOT:-$REPO/evidence/${COMMIT:0:12}}"
WT="$(mktemp -d "${TMPDIR:-/tmp}/xsv2-proof-XXXXXX")"

cleanup() { cd "$REPO"; git worktree remove --force "$WT" >/dev/null 2>&1 || rm -rf "$WT"; }
trap cleanup EXIT

git worktree add --detach "$WT" "$COMMIT" >/dev/null || exit 4

# 可读性是与 FM 并列的硬指标，但它此前只在我记得的时候才跑——已经被工程压力挤掉过一次。
# 这里把它接进同一道闸：证明跑在哪份字节上，可读性就在同一份字节上验。
# 注意版本斜错：证明**钉在某 commit**，而本脚本是从活动仓库读的。被钉的 commit 可能
# 早于这道闸存在，那时 worktree 里没有审计脚本——此时应说明并放行，而不是把整批判失败
# （我就是在批跑中途加了这道闸，把 38 个已跑完的目标判成 rc=6）。
if [[ -f "$WT/scripts/readability_audit.py" ]]; then
  if ! ( cd "$WT" && python3 scripts/readability_audit.py --quiet ); then
    echo "ERROR: 可读性验收未通过（见上），拒绝在该 commit 上出证明" >&2
    exit 6
  fi
else
  echo "[run_proof] 注意：被钉 commit ${COMMIT:0:12} 早于可读性闸，本次跳过该项检查" >&2
fi
echo "[run_proof] worktree=$WT commit=${COMMIT:0:12} ut=$UT_DIR targets=${TARGETS[*]}"

# 跑前闭包摘要（worktree 内 tracked 文件的整体摘要）
# 摘要必须覆盖**工作树实际字节**：`git ls-files -s` 只是 index 条目，工作树文件被改动
# 时它不会变（codex 0141 P1）。这里按稳定顺序对每个 tracked 文件的真实内容取 sha256，
# 再对 "<sha>  <path>" 列表整体取一次。
digest_worktree() {
  ( cd "$WT" && git ls-files -z | LC_ALL=C sort -z \
      | xargs -0 -r sha256sum -- | sha256sum | cut -d' ' -f1 )
}
D_BEFORE="$(digest_worktree)"

rc_all=0
mkdir -p "$EVID"
for t in "${TARGETS[@]}"; do
  ( cd "$WT/verif/ut/$UT_DIR" && XSSV_HOME="$WT" XSSV_INDEX_HOME="$REPO" make "fm-$t" ) ; rc=$?
  dst="$EVID/$t"; mkdir -p "$dst"
  src="$WT/verif/ut/$UT_DIR/fm_work/$t"
  for f in receipt.json fm.log black_boxes.rpt unread_points.txt unmatched.rpt; do
    [[ -f "$src/$f" ]] && cp "$src/$f" "$dst/" 2>/dev/null
  done
  [[ -d "$src/sidecar" ]] && cp -r "$src/sidecar" "$dst/" 2>/dev/null
  echo "$rc" > "$dst/MAKE_RC"
  if [[ $rc -ne 0 ]]; then rc_all=$rc; fi
  echo "[run_proof] $t rc=$rc evidence=$dst"
done

D_AFTER="$(digest_worktree)"
# 跑后校验的是 **worktree 自己的 HEAD**（detached 在 $COMMIT 上），不是活动仓库的 HEAD。
# 证明钉在某个 commit 的字节上，主线在此期间提交新代码与本次证明无关；
# 之前误取活动 HEAD，导致批跑中途我一提交就把 6 个已完成目标判成"输入变了"（exit 5）。
HEAD_AFTER="$(git -C "$WT" rev-parse HEAD)"
{
  echo "commit	$COMMIT"
  echo "head_before	$HEAD_BEFORE"
  echo "head_after	$HEAD_AFTER"
  echo "worktree_digest_before	$D_BEFORE"
  echo "worktree_digest_after	$D_AFTER"
  echo "targets	${TARGETS[*]}"
} > "$EVID/RUN_CONTEXT.tsv"

if [[ "$D_BEFORE" != "$D_AFTER" || "$HEAD_BEFORE" != "$HEAD_AFTER" ]]; then
  echo "ERROR: 跑期间输入发生变化（worktree 摘要或 HEAD 变了）—— 证据作废" >&2
  exit 5
fi
echo "[run_proof] 输入前后一致；证据在 $EVID"
exit $rc_all
