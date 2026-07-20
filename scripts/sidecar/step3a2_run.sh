#!/usr/bin/env bash
# Step 3A.2 runner(审查 3A.1 PARTIAL_PASS 后的补测)。5 会话, clean 入口 + canonical golden:
#   strict_full      : Bku strict+pins, smoke v3(补齐 3A.1 实际未执行的 -status/-point_type 查询)
#   strict_unread_on : Bku strict+pins + verification_verify_unread_compare_points=true
#                      (fm_eq.tcl:40 与 relaxed_appvars 契约冲突的实证探针)
#   unresolved_sample: IMSIC strict(IntFile/IMSICGateWay 两侧未解析)→ 非空 unresolved 样本
#   bbout_probe      : Bku strict+pins + 仅 impl 侧 set_black_box xs_bku_clmul
#                      (非对称黑盒 → 非空 unmatched bbox_output 样本, 标注探针会话)
#   fmbb_empty       : DCacheWrapper fmbb 配方(两侧显式空 DCache 模块)→ empty 'e' flag 样本
# 证据链修复(审查指出 3A.1 manifest 不能自校验):
#   ①session.tcl + smoke tcl 本体入证据目录(hash 进 MANIFEST)
#   ②大文件规则: >100KB 的 raw 先记 <f>.fullhash(name/size/sha256)再截 <f>.sample, 原件删除
#     ——全部发生在 MANIFEST 生成**之前**, 无冒充
#   ③MANIFEST 最后生成 + 末尾自校验
set -u
SIGNOFF="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GOLDEN=/home/eda/xs-env/G0-canonical/golden-rtl
EVID="$SIGNOFF/scripts/sidecar/step3a2-evidence"
SMOKE="$SIGNOFF/scripts/sidecar/step3a2_query_smoke.tcl"
COMMIT=$(git -C "$SIGNOFF" rev-parse HEAD)

finish_evidence() {  # name outdir dir rc cmd
  local name=$1 OUT=$2 d=$3 rc=$4 cmd=$5
  local ED="$EVID/$name"
  rm -rf "$ED"; mkdir -p "$ED"
  cp "$OUT"/*.ret "$OUT"/*.out "$OUT"/*.rc "$ED"/ 2>/dev/null
  cp "$OUT/session.tcl" "$ED/session.tcl"
  cp "$SMOKE" "$ED/smoke.tcl"
  grep -E "^FM_RESULT|^SMOKE" "$OUT/fm.log" > "$ED/fm_result_and_smoke_lines.txt" 2>/dev/null
  {
    echo "session: $name"
    echo "signoff_commit: $COMMIT"
    echo "golden: $GOLDEN"
    echo "ut_dir: $d"
    echo "fm_shell_actual_rc: $rc"
    echo "cmd: $cmd"
  } > "$ED/ENV.txt"
  # 大文件规则(先于 MANIFEST, 显式分名)
  local f sz
  for f in "$ED"/*; do
    [ -f "$f" ] || continue
    sz=$(stat -c%s "$f")
    if [ "$sz" -gt 100000 ]; then
      printf '%s\t%s\t%s\n' "$(basename "$f")" "$sz" "$(sha256sum "$f"|cut -d' ' -f1)" > "$f.fullhash"
      head -c 4096 "$f" > "$f.sample"
      rm "$f"
    fi
  done
  ( cd "$ED" && LC_ALL=C ls | LC_ALL=C sort | while read -r f; do
      printf '%s\t%s\t%s\n' "$f" "$(stat -c%s "$f")" "$(sha256sum "$f"|cut -d' ' -f1)"
    done ) > "$ED/../$name.MANIFEST.tsv"
  # 自校验
  local bad=0 a b h
  while IFS=$'\t' read -r f sz h; do
    a=$(stat -c%s "$ED/$f" 2>/dev/null); b=$(sha256sum "$ED/$f" 2>/dev/null|cut -d' ' -f1)
    [ "$a" = "$sz" ] && [ "$b" = "$h" ] || bad=$((bad+1))
  done < "$ED/../$name.MANIFEST.tsv"
  echo "[$name] 完成 rc=$rc: $(ls "$ED"|wc -l) 文件, manifest自校验不符=$bad"
}

run_std() {  # name target tcl_patch(sed脚本, 可空)
  local name=$1 T=$2 patch=$3
  local d="$SIGNOFF/verif/ut/$T"
  local OUT="/tmp/step3a2_$name"
  rm -rf "$OUT"; mkdir -p "$OUT"
  sed 's/^exit$//' "$SIGNOFF/scripts/fm_eq.tcl" > "$OUT/session.tcl"
  [ -n "$patch" ] && sed -i "$patch" "$OUT/session.tcl"
  cat "$SMOKE" >> "$OUT/session.tcl"
  echo "exit" >> "$OUT/session.tcl"
  local cmd
  cmd=$(cd "$d" && make -n fm FM_MODE=signoff-strict GOLDEN_RTL="$GOLDEN" 2>/dev/null \
        | sed -e ':a' -e '/\\$/{N;s/\\\n//;ba}' | grep "fm_shell" | head -1)
  [ -z "$cmd" ] && { echo "[$name] 无fm命令"; return 1; }
  local new
  new=$(echo "$cmd" | sed -e "s|$SIGNOFF/scripts/fm_eq.tcl|$OUT/session.tcl|" \
                          -e "s|fm_work/[^/]*/fm.log|$OUT/fm.log|" \
                          -e "s|-work_path fm_work/[^ ]*|-work_path $OUT/wk|" \
                          -e "s|; \\\\||g" -e "s|python3 .*fm_verdict.py.*||" \
                          -e "s|grep -E .*||" -e "s|grep -q .*||" -e "s|rc=\$?;||")
  mkdir -p "$d/fm_work/$T"
  echo "[$name] 运行($T)..."
  ( cd "$d" && SMOKE_OUT="$OUT" bash -c "$new" ) >/dev/null 2>&1
  finish_evidence "$name" "$OUT" "$d" $? "$new"
}

run_fmbb() {  # DCacheWrapper 自定义配方
  local name=fmbb_empty T=DCacheWrapper
  local d="$SIGNOFF/verif/ut/$T"
  local OUT="/tmp/step3a2_$name"
  rm -rf "$OUT"; mkdir -p "$OUT"
  sed 's/^exit$//' "$d/fm_eq_bb.tcl" > "$OUT/session.tcl"
  cat "$SMOKE" >> "$OUT/session.tcl"
  echo "exit" >> "$OUT/session.tcl"
  local cmd
  cmd=$(cd "$d" && make -n fmbb GOLDEN_RTL="$GOLDEN" 2>/dev/null \
        | sed -e ':a' -e '/\\$/{N;s/\\\n//;ba}' | grep "fm_shell" | head -1)
  [ -z "$cmd" ] && { echo "[$name] 无fmbb命令"; return 1; }
  local new
  new=$(echo "$cmd" | sed -e "s|-file [^ ]*fm_eq_bb.tcl|-file $OUT/session.tcl|" \
                          -e "s|fm_work/[^/]*/fm.log|$OUT/fm.log|" \
                          -e "s|-work_path fm_work/[^ ]*|-work_path $OUT/wk|" \
                          -e "s|; \\\\||g" -e "s|grep -E .*||" -e "s|grep -q .*||")
  mkdir -p "$d/fm_work/$T"
  echo "[$name] 运行($T fmbb)..."
  ( cd "$d" && SMOKE_OUT="$OUT" bash -c "$new" ) >/dev/null 2>&1
  finish_evidence "$name" "$OUT" "$d" $? "$new"
}

mkdir -p "$EVID"
run_std strict_full      Bku ""
# 探针: unread 比对点开启(契约冲突实证)
run_std strict_unread_on Bku "s|set_app_var verification_verify_unread_compare_points false|set_app_var verification_verify_unread_compare_points true|"
run_std unresolved_sample IMSIC ""
# 探针: 仅 impl 侧黑盒 clmul(非对称 → unmatched bbox_output 非空样本)
run_std bbout_probe      Bku "/^set_top i:/a set_black_box i:/WORK/xs_bku_clmul"
run_fmbb
echo "STEP3A2_ALL_DONE"
