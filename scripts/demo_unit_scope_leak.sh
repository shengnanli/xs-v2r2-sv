#!/bin/bash
# demo_unit_scope_leak.sh —— 复现「模块外 import 跨文件泄漏」这条工具行为（需要 VCS）。
#
# 为什么留着这个脚本：scripts/check_pkg_scope.py 判据 C 禁止模块外 import，理由是
# 「VCS 会 0 Error / 0 Warning 地让一个文件的包泄漏到另一个文件」。那条理由是**工具行为**，
# 不是从 LRM 推的——所以它必须可复跑，否则后人只能选择相信我。
#
# 本脚本不进 gate_all（它依赖 VCS，而闸要能在没有 EDA 工具的环境里跑）。
# 手工跑：  bash scripts/demo_unit_scope_leak.sh
# 退出码 0 = 复现成功（泄漏在 $unit 版出现、在模块头版消失），非 0 = 与记录不符，
# 说明工具行为变了或本脚本腐烂了，这时**要么更新判据 C 的理由，要么修脚本**。
#
# 实测环境：VCS W-2024.09-SP1（2026-09-14）。素材取自真实病例：
#   probequeue_pkg::IDX_BITS = 3  vs  writebackqueue_pkg::IDX_BITS = 5
set -u
D=$(mktemp -d "${TMPDIR:-/tmp}/unitleak-XXXXXX") || exit 2
trap 'rm -rf "$D"' EXIT
export VCS_ARCH_OVERRIDE=linux     # 本工程已知坑：必须与 -full64 成对

mk() { # $1=目录 $2=A的import写法 $3=B的import写法
  mkdir -p "$D/$1"
  cat > "$D/$1/a.sv" <<EOF
package pq_pkg;
  localparam int IDX_BITS = 3;
endpackage
$2
EOF
  cat > "$D/$1/b.sv" <<EOF
package wb_pkg;
  localparam int IDX_BITS = 5;
endpackage
$3
EOF
  cat > "$D/$1/top.sv" <<'EOF'
module top;
  int unsigned wa, wb;
  A u_a(.w(wa));
  B u_b(.w(wb));
  initial begin #1; $display("RESULT %0d %0d", wa, wb); $finish; end
endmodule
EOF
}

# $unit 作用域版（= 修改前 rtl/ 里的写法）
mk unit \
'import pq_pkg::*;
module A (output int unsigned w);
  assign w = IDX_BITS;
endmodule' \
'import wb_pkg::*;
module B (output int unsigned w);
  assign w = IDX_BITS;
endmodule'

# 模块头 import 版（= 修改后的写法）
mk hdr \
'module A import pq_pkg::*; (output int unsigned w);
  assign w = IDX_BITS;
endmodule' \
'module B import wb_pkg::*; (output int unsigned w);
  assign w = IDX_BITS;
endmodule'

run() { # $1=目录 $2=先编的文件 $3=后编的文件 -> 打印 "rc|错误告警数|A值 B值"
  local d=$D/$1/run_$2_$3; mkdir -p "$d"
  ( cd "$d" && vcs -full64 -sverilog -top top -o simv -l vcs.log \
      "$D/$1/$2" "$D/$1/$3" "$D/$1/top.sv" >/dev/null 2>&1 )
  local rc=$?
  # grep -c 无命中时打印 0 并 exit 1；别再接 `|| echo 0`，那会多出一行
  local n; n=$(grep -cE '^(Error|Warning)-\[' "$d/vcs.log" 2>/dev/null); n=${n:-0}
  # 必须在 $d 里跑 simv：它会往 cwd 写 ucli.key，在仓库根跑就把工作树弄脏了
  local r; r=$( cd "$d" && ./simv 2>/dev/null | sed -n 's/^RESULT //p' )
  echo "$rc|$n|$r"
}

fail=0
chk() { # $1=说明 $2=实得 $3=期望
  if [ "$2" = "$3" ]; then printf '  OK   %-46s %s\n' "$1" "$2"
  else printf '  ★FAIL %-45s 实得 %s，记录的是 %s\n' "$1" "$2" "$3"; fail=1; fi
}

echo "=== \$unit 作用域 import（修改前的写法）——泄漏且 VCS 不吭声 ==="
chk "a.sv 在前：A/B 都应拿到 pq 的 3"  "$(run unit a.sv b.sv)" "0|0|3 3"
chk "b.sv 在前：A/B 都应拿到 wb 的 5"  "$(run unit b.sv a.sv)" "0|0|5 5"
echo "=== 模块头 import（修改后的写法）——各取各的，且与文件序无关 ==="
chk "a.sv 在前：A=3 B=5"               "$(run hdr a.sv b.sv)"  "0|0|3 5"
chk "b.sv 在前：A=3 B=5"               "$(run hdr b.sv a.sv)"  "0|0|3 5"

if [ $fail -eq 0 ]; then
  echo "=== 复现成功：模块外 import 会让两个模块一起拿到排在前面那个包的值，"
  echo "    退出码 0、0 条 Error、0 条 Warning；改成模块头 import 后消失。 ==="
else
  echo "=== 与记录不符：check_pkg_scope.py 判据 C 的理由需要重新核对 ==="
fi
exit $fail
