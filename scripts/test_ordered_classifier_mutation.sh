#!/bin/bash
# test_ordered_classifier_mutation.sh —— 变异测试：证明回归测试**不是假通过**。
#
# 本工程有过「三个断言全被前置门挡掉却报 PASS」的教训。光看 22/22 绿不足以说明
# 测试有效 —— 必须证明「判据被打坏时测试会挂」。本脚本逐条把 ordered_classifier.py
# 的关键判据故意改坏，跑对应的负测，要求它**挂**。任何一条改坏后测试仍绿，
# 就是那条负测没有实际保护力（实测抓到过一次：单靠 BypassNetwork 保护不了
# 「含 ready 就判 B」，因为它在 rank4 就被 A2 收走，B 判据怎么改都影响不到它 ——
# 于是补了 test_neg_ready_present_but_not_added_is_not_B）。
#
# 用法：  bash scripts/test_ordered_classifier_mutation.sh [工作目录]
# 退出码 0 = 六条变异全部被抓；1 = 有变异逃逸（=测试假通过）。
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${1:-$(mktemp -d -t oc_mutation_XXXX)}"
mkdir -p "$WORK"
export OC_TEST_CACHE="${OC_TEST_CACHE:-${TMPDIR:-/tmp}/ordered_classifier_cache}"
ESCAPED=0

mutate_and_run() {
  local name="$1" spec="$2" filt="$3"
  cp "$REPO"/scripts/ordered_classifier.py "$REPO"/scripts/check_name_collisions.py \
     "$REPO"/scripts/test_ordered_classifier.py "$WORK"/
  SPEC="$spec" TARGET="$WORK/ordered_classifier.py" python3 - <<'PY' || { echo "  锚点找不到，变异没生效：$name"; ESCAPED=1; return; }
import os, pathlib
old, new = os.environ['SPEC'].split('|@|')
p = pathlib.Path(os.environ['TARGET'])
s = p.read_text()
assert old in s, 'anchor not found'
p.write_text(s.replace(old, new, 1))
PY
  out="$(cd "$WORK" && timeout 900 python3 test_ordered_classifier.py -k "$filt" 2>&1 | tail -5)"
  if echo "$out" | grep -q FAIL; then
    echo "CAUGHT      [$name] -> $filt 挂了（正确）"
  else
    echo "!! ESCAPED  [$name] -> $filt 仍然全绿 = 这条负测没有保护力"
    echo "$out" | sed 's/^/            /'
    ESCAPED=1
  fi
}

mutate_and_run "删掉 A 档的 width/dir 硬闸" \
  "a_ok = body_id and r['width_chg'] == 0 and r['dir_chg'] == 0|@|a_ok = body_id" \
  "tlbuffer_must_not_be_A"

mutate_and_run "A2 退回粗字段名过滤" \
  "        ok_attr, bad_a, bad_d = attribute(add, dele, new_ids, old_ids,
                                          d['added'], d['removed'])|@|        ok_attr = coarse_field_filter_equal(ll0, ll1, d['added'], d['removed'])
        bad_a, bad_d = [], []" \
  "a2_coarse_field_spoof"

mutate_and_run "把 B 提到 rank3 之前（破坏顺序契约）" \
  "    (3, 'A_BODY_IDENTICAL'),|@|    (3, 'B_HANDSHAKE_MOVED'),
    (3, 'A_BODY_IDENTICAL')," \
  "order_contract"

mutate_and_run "D 档改用顺序 sub（链式吃掉）" \
  "def simul_sub(text, mapping):|@|def simul_sub(text, mapping):
    if mapping:
        for _k in mapping:
            text = re.sub(r'\\\\b%s\\\\b' % re.escape(_k), mapping[_k], text)
        return text" \
  "snxbar"

mutate_and_run "B 判据放宽成「端口名里含 ready」" \
  "        b_ok = r['ready_added'] > 0|@|        b_ok = r['ready_g0'] > 0 or r['ready_added'] > 0" \
  "not_B"

mutate_and_run "关掉 temp_blind 归一（Ftq 又变成「从头重写」）" \
  "    return _TEMPNUM.sub(r'\\1_@', text)|@|    return text" \
  "ftq"

mutate_and_run "X_RETIRED 判据 key 回 g0_name（派生后继行会再触发一次）" \
  "        retired = (target in self.b0.mods) and (target not in self.b1.mods)|@|        retired = (g0_name in self.b0.mods) and (g0_name not in self.b1.mods)" \
  "derived_successor"

mutate_and_run "关掉薄壳解壳（IMSIC 又被报成 IMSIC_WRAP）" \
  "        peeled = []|@|        return name, []
        peeled = []" \
  "imsic"

if [ "$ESCAPED" = 0 ]; then echo; echo "全部变异被抓：回归测试有实际保护力。"; else
  echo; echo "有变异逃逸 —— 对应的负测等于没测，必须补夹具。"; fi
exit $ESCAPED
