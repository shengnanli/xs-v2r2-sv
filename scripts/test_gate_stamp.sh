#!/bin/bash
# test_gate_stamp.sh —— gate_all.sh 的「树指纹」判据负测。
#
# ★为什么要有这一条★（2026-09-20 实测缘起）
# `GATE_RC=` 解决了「结果存不存在」（没有那一行 = 结果不存在，既不是绿也不是红）。
# 但本轮撞到了它管不住的另一半：同时有三个 gate_all 实例在跑，其中一个是**陈旧**的
# ——它执行的是还没接进新闸的旧脚本、读的是还没修的旧树——它照样打印了一行格式
# 完全正确的 `GATE_RC=1`。那一行作为「这棵树的判决」是**假的**，而从日志上看
# 它和真结果长得一模一样。
#
# ⇒ `GATE_RC=` 之外还得答「结果属于谁」：`GATE_COMMIT=` 记跑在哪个 commit（带 -dirty），
#   并且开跑/收尾各取一次，不相等就判红（跑动期间树被改过 = 结果不属于任何确定状态）。
#
# 这道负测按判据的两侧各种一个病：
#   A 树没动   -> begin == end，且 dirty 标记如实              （不能恒红）
#   B 树动了   -> begin != end                                  （不能恒绿）
#   C 脏树     -> 指纹必须带 -dirty（否则脏树会伪装成干净 commit）
# 只测 A 不测 B 的实现（恒等返回相同）和只测 B 不测 A 的实现（恒红）都会在这里露馅。
#
# 用法：bash scripts/test_gate_stamp.sh

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
PASS=0; FAIL=0
ck() { # ck <名字> <条件真假:0/1> <细节>
  if [ "$2" = "0" ]; then echo "  ok    $1  ${3:-}"; PASS=$((PASS+1));
  else echo "  FAIL  $1  ${3:-}"; FAIL=$((FAIL+1)); fi
}

# 从 gate_all.sh 里把 gate_stamp() 原样抠出来测 —— ★测的必须是真在用的那份★，
# 不是这里另抄一份（另抄一份 = 判据的输入不是被判断的对象）。
TMP="$(mktemp -d -t gatestamp.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT
sed -n '/^gate_stamp() {$/,/^}$/p' "$HERE/gate_all.sh" > "$TMP/stamp.sh"
if [ ! -s "$TMP/stamp.sh" ]; then
  echo "  FAIL  从 gate_all.sh 里抠不出 gate_stamp() —— 判据和被测对象脱钩了"
  echo "PASS 0 / FAIL 1"; exit 1
fi
. "$TMP/stamp.sh"

# 造一个一次性的小 git 仓，不碰真仓
R="$TMP/repo"; mkdir -p "$R"
( cd "$R" \
  && git init -q . \
  && git config user.email t@t && git config user.name t \
  && echo one > a.txt && git add a.txt && git commit -qm one ) || {
  echo "  FAIL  造临时 git 仓失败"; echo "PASS 0 / FAIL 1"; exit 1; }

cd "$R" || exit 1

echo "=== gate_all.sh 树指纹判据负测 ==="

# --- A：树没动，两次取指纹必须相同（判据不能恒红）---
A1="$(gate_stamp)"; A2="$(gate_stamp)"
[ "$A1" = "$A2" ]; ck "A 树没动 -> 两次指纹相同（不能恒红）" "$?" "$A1"

# --- C：干净树不许带 -dirty ---
case "$A1" in *-dirty) ck "C1 干净树不带 -dirty" 1 "$A1";; *) ck "C1 干净树不带 -dirty" 0 "$A1";; esac

# --- C2：脏树必须带 -dirty（否则脏树伪装成干净 commit）---
echo two >> a.txt
D="$(gate_stamp)"
case "$D" in *-dirty) ck "C2 脏树带 -dirty" 0 "$D";; *) ck "C2 脏树带 -dirty" 1 "$D";; esac
[ "$D" != "$A1" ]; ck "C3 脏树指纹 != 干净树指纹" "$?" "$A1 -> $D"

# --- B：树动了（提交新 commit），指纹必须变（判据不能恒绿）---
git add a.txt && git commit -qm two
B="$(gate_stamp)"
[ "$B" != "$A1" ]; ck "B 树动了 -> 指纹必须变（不能恒绿）" "$?" "$A1 -> $B"

# --- B2：模拟 gate_all 的真实用法：开跑取一次、跑动中改树、收尾再取 ---
BEGIN="$(gate_stamp)"
echo three >> a.txt            # 跑动期间有人改了树
END="$(gate_stamp)"
[ "$BEGIN" != "$END" ]; ck "B2 跑动期间改树 -> begin != end（gate_all 据此判红）" "$?" "$BEGIN -> $END"

# --- B3：反向对照 —— 跑动期间**没人**改树时必须 begin == end ---
git add a.txt && git commit -qm three
BEGIN2="$(gate_stamp)"; : ; END2="$(gate_stamp)"
[ "$BEGIN2" = "$END2" ]; ck "B3 跑动期间没改 -> begin == end（不能误报）" "$?" "$BEGIN2"

echo
echo "PASS $PASS / FAIL $FAIL"
[ "$FAIL" -eq 0 ]
