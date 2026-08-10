#!/bin/bash
# build_release_archive.sh — RC2 release archive 构建器(Lane D 草案, codex 0132 §4 / 0133 预检 E)
#
# 布局(全普通文件, 禁 symlink; 相对路径; 单一 RC provenance):
#   <out>/
#     RC.txt                      RC commit + manifest/declaration/anchor SHA 清单
#     manifests/                  提交态 bytes: manifest_305.json manifest_306_v2.json
#                                 manifest_aux.json manifest_declarations{,_aux}.tsv
#                                 combined_ledger.tsv + allow/ + dead_ref/ 全量
#     targets/<T>/                306 fresh receipts(305 shard + Rob 见 rob/)
#     rob/                        Rob 5 分区 receipts + UNION_RECORD.tsv + BINDING_MANIFEST.tsv
#     aux/<T>/                    TL2 14 AUX receipts
#     reconcile/                  v1/v2 reconcile 输出 + ledger 守恒输出
#     FINAL_306_REFRESH_REPORT.md (integrator 手写, 构建时须已存在或后补)
#     ARCHIVE_MANIFEST.tsv        path\tsize\tsha256(除本文件与 COMPLETE 外全覆盖)
#     COMPLETE                    sha256(ARCHIVE_MANIFEST.tsv)
#
# 用法: RC2_COMMIT=<sha> bash build_release_archive.sh <rc2_checkout> \
#          <shard_evroot>... --aux <aux_evroot> --rob <rob_evroot> --out <outdir>
set -eu
ROOT=$1; shift
SHARDS=(); AUXEV=""; ROBEV=""; OUT=""
while [ $# -gt 0 ]; do case "$1" in
  --aux) AUXEV=$2; shift 2;; --rob) ROBEV=$2; shift 2;; --out) OUT=$2; shift 2;;
  *) SHARDS+=("$1"); shift;; esac; done
[ -n "$OUT" ] && [ -n "${RC2_COMMIT:-}" ] || { echo "need --out and RC2_COMMIT"; exit 2; }
[ -e "$OUT" ] && { echo "REFUSE: $OUT exists (immutable archive, no-force)"; exit 2; }
HEAD=$(git -C "$ROOT" rev-parse HEAD)
case "$HEAD" in "$RC2_COMMIT"*) ;; *) echo "RC_MISMATCH $HEAD != $RC2_COMMIT"; exit 2;; esac
[ "$(git -C "$ROOT" status --porcelain --untracked-files=no | wc -l)" = 0 ] || { echo RC_DIRTY; exit 2; }

mkdir -p "$OUT"/{manifests,targets,rob,aux,reconcile}
# 提交态 bytes(git show, 不取工作区)
for f in scripts/sidecar/manifest_305.json scripts/sidecar/manifest_306_v2.json \
         scripts/sidecar/manifest_aux.json scripts/sidecar/manifest_declarations.tsv \
         scripts/sidecar/manifest_declarations_aux.tsv scripts/sidecar/combined_ledger.tsv; do
  git -C "$ROOT" show "$HEAD:$f" > "$OUT/manifests/$(basename "$f")"
done
for d in allow dead_ref; do
  mkdir -p "$OUT/manifests/$d"
  git -C "$ROOT" ls-tree --name-only "$HEAD" "verif/signoff/$d/" | while read -r f; do
    git -C "$ROOT" show "$HEAD:$f" > "$OUT/manifests/$d/$(basename "$f")"
  done
done
# receipts: cp -rL 消 symlink; 拒绝覆盖(同名目标出现两次 = shard 重复, 违约即炸)
for ev in "${SHARDS[@]}"; do
  for td in "$ev"/*/; do t=$(basename "$td")
    [ -e "$OUT/targets/$t" ] && { echo "DUP_TARGET_RECEIPT $t"; exit 2; }
    cp -rL "$td" "$OUT/targets/$t"
  done
done
[ -n "$AUXEV" ] && for td in "$AUXEV"/*/; do cp -rL "$td" "$OUT/aux/$(basename "$td")"; done
[ -n "$ROBEV" ] && cp -rL "$ROBEV"/. "$OUT/rob/"
{ echo -e "rc_commit\t$HEAD"
  for f in "$OUT"/manifests/*.json "$OUT"/manifests/*.tsv; do
    echo -e "manifest_sha256\t$(basename "$f")\t$(sha256sum "$f" | cut -d' ' -f1)"; done
} > "$OUT/RC.txt"
# reconcile + 守恒当场重算入档
( cd "$ROOT" && python3 scripts/sidecar/reconcile_universe.py \
    scripts/sidecar/manifest_306_v2.json verif/freeze/fm_targets_v2_306.tsv ) \
  > "$OUT/reconcile/reconcile_v2_306.txt" || { echo RECONCILE_V2_DIFF; exit 2; }
# 终封: manifest + COMPLETE(生成后目录只读)
( cd "$OUT" && LC_ALL=C find . -type l | grep -q . && { echo SYMLINK_IN_ARCHIVE; exit 2; } || true )
( cd "$OUT" && LC_ALL=C find . -type f ! -path ./ARCHIVE_MANIFEST.tsv ! -path ./COMPLETE \
    | LC_ALL=C sort | sed 's|^\./||' \
    | while read -r f; do printf '%s\t%s\t%s\n' "$f" "$(stat -c%s "$f")" "$(sha256sum "$f" | cut -d' ' -f1)"; done \
) > "$OUT/ARCHIVE_MANIFEST.tsv"
sha256sum "$OUT/ARCHIVE_MANIFEST.tsv" | cut -d' ' -f1 > "$OUT/COMPLETE"
chmod -R a-w "$OUT"
echo "ARCHIVE_SEALED $OUT rc=$HEAD"
