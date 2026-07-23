#!/usr/bin/env bash
# Step 3A runner: 对1个strict(Bku)+1个assembly(Ftq)目标, 在标准FM会话verify后source查询smoke。
# 只产字段→API实证数据, 不写sidecar。
set -u
SIGNOFF="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
XSSV=/home/eda/xs-env/xs-v2r2-sv
for T in Bku Ftq; do
  d="$XSSV/verif/ut/$T"
  OUT="/tmp/step3a_$T"
  rm -rf "$OUT"; mkdir -p "$OUT"
  # 拼接: 标准fm_eq.tcl(去掉exit) + smoke tcl
  sed 's/^exit$//' "$XSSV/scripts/fm_eq.tcl" > /tmp/step3a_$T.tcl
  cat "$SIGNOFF/scripts/sidecar/step3a_query_smoke.tcl" >> /tmp/step3a_$T.tcl
  echo "exit" >> /tmp/step3a_$T.tcl
  # 提取该目标的 make fm 命令, 换 tcl 与 work_path
  cmd=$(cd "$d" && make -n fm 2>/dev/null | sed -e ':a' -e '/\\$/{N;s/\\\n//;ba}' | grep fm_shell | head -1)
  [ -z "$cmd" ] && { echo "[$T] 无fm命令"; continue; }
  new=$(echo "$cmd" | sed -e "s|$XSSV/scripts/fm_eq.tcl|/tmp/step3a_$T.tcl|" \
                          -e "s|fm_work/$T/fm.log|$OUT/fm.log|" \
                          -e "s|-work_path fm_work/$T |-work_path $OUT/wk |" \
                          -e "s|; \\\\||g" -e "s|grep -E .*||" -e "s|grep -q .*||")
  echo "[$T] 运行(标准会话+smoke)..."
  ( cd "$d" && SMOKE_OUT="$OUT" bash -c "$new" ) >/dev/null 2>&1
  echo "[$T] smoke产物: $(ls "$OUT"/*.txt 2>/dev/null | wc -l) 个查询dump; SMOKE_DONE: $(grep -c SMOKE_DONE "$OUT/fm.log" 2>/dev/null)"
done
