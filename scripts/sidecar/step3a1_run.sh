#!/usr/bin/env bash
# Step 3A.1 runner(审查批准的小范围补测)。三类会话, 全部从 **clean xs-signoff 入口**
# (committed ut_common.mk/fm_eq.tcl, FM_MODE 门控生效)+ **canonical golden**(GOLDEN_RTL 覆盖,
# 不动 worktree 的跟踪 symlink):
#   strict_pass    : Bku, FM_MODE=signoff-strict, 带 pins → 期望 native SUCCEEDED
#   assembly_iface : NewIFU, FM_MODE=assembly, FM_INTERFACE_ONLY 非空(5 模块)
#   native_failed  : Bku, 去 pins → 期望 native FAILED(真实失败会话)
# 证据: 每 query 的 .ret/.out/.rc 原始字节 + MANIFEST(sha256) + ENV + COMMIT 锚, 入库。
set -u
SIGNOFF="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GOLDEN=/home/eda/xs-env/G0-canonical/golden-rtl
EVID="$SIGNOFF/scripts/sidecar/step3a1-evidence"
COMMIT=$(git -C "$SIGNOFF" rev-parse HEAD)

run_session() {  # name target mode strip_pins
  local name=$1 T=$2 mode=$3 strip=$4
  local d="$SIGNOFF/verif/ut/$T"
  local OUT="/tmp/step3a1_$name"
  rm -rf "$OUT"; mkdir -p "$OUT"
  # 拼 tcl: committed fm_eq.tcl(去 exit)+ smoke
  sed 's/^exit$//' "$SIGNOFF/scripts/fm_eq.tcl" > "$OUT/session.tcl"
  cat "$SIGNOFF/scripts/sidecar/step3a1_query_smoke.tcl" >> "$OUT/session.tcl"
  echo "exit" >> "$OUT/session.tcl"
  # 从 clean 入口提取命令(FM_MODE/GOLDEN_RTL 由 make 变量注入)
  local cmd
  cmd=$(cd "$d" && make -n fm FM_MODE=$mode GOLDEN_RTL="$GOLDEN" 2>/dev/null \
        | sed -e ':a' -e '/\\$/{N;s/\\\n//;ba}' | grep "fm_shell" | head -1)
  [ -z "$cmd" ] && { echo "[$name] 无fm命令"; return 1; }
  local new
  new=$(echo "$cmd" | sed -e "s|$SIGNOFF/scripts/fm_eq.tcl|$OUT/session.tcl|" \
                          -e "s|fm_work/[^/]*/fm.log|$OUT/fm.log|" \
                          -e "s|-work_path fm_work/[^ ]*|-work_path $OUT/wk|" \
                          -e "s|; \\\\||g" -e "s|python3 .*fm_verdict.py.*||" \
                          -e "s|grep -E .*||" -e "s|grep -q .*||" -e "s|rc=\$?;||")
  if [ "$strip" = "yes" ]; then
    new=$(echo "$new" | sed -e "s|FM_PIN_TCL=[^ ]*||" -e "s|FM_PIN_PRE_TCL=[^ ]*||")
  fi
  mkdir -p "$d/fm_work/$T"
  echo "[$name] 运行($T mode=$mode strip_pins=$strip)..."
  ( cd "$d" && SMOKE_OUT="$OUT" bash -c "$new" ) >/dev/null 2>&1
  local rc=$?
  # 汇总证据入库
  local ED="$EVID/$name"
  rm -rf "$ED"; mkdir -p "$ED"
  cp "$OUT"/*.ret "$OUT"/*.out "$OUT"/*.rc "$ED"/ 2>/dev/null
  grep -E "^FM_RESULT|^SMOKE" "$OUT/fm.log" > "$ED/fm_result_and_smoke_lines.txt" 2>/dev/null
  {
    echo "session: $name  target: $T  mode: $mode  strip_pins: $strip"
    echo "signoff_commit: $COMMIT"
    echo "golden: $GOLDEN"
    echo "fm_shell_actual_rc: $rc"
    echo "env_extract:"; echo "$new" | tr ' ' '\n' | grep -E "^FM_" | head -12
  } > "$ED/ENV.txt"
  ( cd "$ED" && LC_ALL=C ls | LC_ALL=C sort | while read -r f; do
      printf '%s\t%s\t%s\n' "$f" "$(stat -c%s "$f")" "$(sha256sum "$f"|cut -d' ' -f1)"
    done ) > "$ED/../$name.MANIFEST.tsv"
  echo "[$name] 完成 rc=$rc: $(ls "$ED" | wc -l) 文件入库"
}

run_session strict_pass    Bku    signoff-strict no
run_session native_failed  Bku    signoff-strict yes
run_session assembly_iface NewIFU assembly       no
echo "STEP3A1_ALL_DONE"
