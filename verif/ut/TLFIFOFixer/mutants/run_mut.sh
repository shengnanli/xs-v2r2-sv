#!/bin/bash
# 变异测试跑手: 把一条 m_*.py 打进 rtl/uncore/TLFIFOFixer.sv 的**副本**(绝不改库里的源文件),
# 派生成 _xs, 与 golden 双例化跑 tb.sv, 看 UT 报不报。
#
#   ./run_mut.sh <名字> m_<名字>.py [拍数]
#
# 期望: 除 README 里明确标注"端口不可观测"的那条外, 每条都应打出 MISMATCH / TEST FAILED。
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
UT=$(dirname "$HERE")
XSSV=$(cd "$UT/../../.." && pwd)
GOLDEN=${GOLDEN_RTL:-/home/eda/xs-env/G1-canonical/golden-rtl}
NC=${3:-20000}
name=$1
W=${WORK:-$HERE/work}/$name
rm -rf "$W"; mkdir -p "$W/ut_gen"
cp "$XSSV/rtl/uncore/TLFIFOFixer.sv" "$W/TLFIFOFixer.sv"
python3 "$2" "$W/TLFIFOFixer.sv"
python3 "$XSSV/scripts/derive_ut_impl.py" --out "$W/ut_gen" "$W/TLFIFOFixer.sv" >/dev/null
cd "$W"
export VCS_ARCH_OVERRIDE=linux
vcs -full64 -sverilog -timescale=1ns/1ps +define+SYNTHESIS +vcs+initreg+random -q \
  ut_gen/TLFIFOFixer.sv "$GOLDEN/TLFIFOFixer.sv" "$UT/tb.sv" \
  -top tb -o simv -l comp.log >/dev/null 2>&1 \
  || { echo "--- $name: COMPILE FAIL ---"; tail -20 comp.log; exit 1; }
echo "--- $name ---"
./simv -q +ntb_random_seed=1 +vcs+initreg+0 +ncycles=$NC 2>&1 \
  | grep -E "errors=|TEST |MISMATCH" | head -4
