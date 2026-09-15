#!/usr/bin/env bash
# =============================================================================
# seed.sh —— 把版本库里的仿真 collateral 摊进仿真工作区，让 run_fullchip.sh
#            不必再跑那次 29 分钟的 Chisel 重生成。
#
# 干净 checkout 跑仿真缺的是什么：G1-canonical 只冻结了 golden-rtl/（2061 个
# .sv/.v/.conf/.fir），**不含 generated-src** —— 也就是 difftest 的 DPI C++ 胶水。
# 少了它，VCS 连 golden 侧都编不出来。缺的那一小块就在 ../collateral/ 里（13 个
# 文件，207 KiB），本脚本只负责把它们摆到 run_fullchip.sh 会去找的位置。
#
# ★ 本脚本不改 run_fullchip.sh 一个字节 ★，它利用那边已有的两处「已存在就跳过」：
#
#   1) regen_generated_src() 开头：
#          if [ -f "$gs/difftest-dpic.cpp" ] && check_dpic "$gs/difftest-dpic.cpp";
#          then return 0; fi          # gs = $SIMW/regen/build/generated-src
#      -> 先把 collateral 摆进 $SIMW/regen/build/generated-src，那次 make sim-verilog
#         就整段跳过（实测 28:49 wall / 19 GB RSS）。
#      -> 注意它是 **fail-closed** 的：摆进去的 dpic 仍要通过 check_dpic（提供的
#         v_difftest_* 集合 == golden GatewayEndpoint.sv 例化的 DummyDPICWrapper_*
#         集合），对不上照样会去重生成。这道门禁本脚本不绕开，也绕不开。
#
#   2) setup() 里的 7 个 build 件：
#          [ -f "$dd/build/$f" ] || cp "$XS_HOME/build/$f" "$dd/build/$f"
#      -> 先摆好，就不会去读 $XS_HOME/build。那个目录是共享可变态（它同时是
#         --fpga-platform --disable-all 那次 make 的落点，也是 Top.scala:680
#         `FileRegisters.write(fileDir = "./build")` 硬编码的写入点），
#         整个 collateral 战役的起因就是有人从那里取到了对不上的一份。
#
# 用法:
#   verif/sim/collateral/seed.sh              # 摆进 regen + golden + impl
#   verif/sim/collateral/seed.sh golden       # 只摆 regen + golden
#   SIMW=<dir> verif/sim/collateral/seed.sh   # 换仿真工作区根
# =============================================================================
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../../.." && pwd)"
SIMW="${SIMW:-/home/eda/xs-env/sim-work}"
read -r -a SIDES <<< "${*:-golden impl}"

log() { echo "[seed] $*" >&2; }

# 摆之前先自检：collateral 与 golden 对不上的话，摆进去只会把坏件带到下游。
python3 "$REPO/scripts/check_sim_collateral.py" >/dev/null || {
  echo "[seed] ERROR: collateral 未过闸，拒绝摊开。跑 python3 scripts/check_sim_collateral.py 看原因" >&2
  exit 2
}

install_dir() {  # $1=源目录 $2=目标目录
  mkdir -p "$2"
  for src in "$1"/*; do
    local dst="$2/$(basename "$src")"
    if [ -f "$dst" ] && cmp -s "$src" "$dst"; then continue; fi
    install -m 644 "$src" "$dst"
    log "  + $dst"
  done
}

# 1) regen 落点：让 run_fullchip.sh 的 regen_generated_src() 早退
install_dir "$HERE/generated-src" "$SIMW/regen/build/generated-src"

# 2) 各侧工作区：generated-src + 7 个 build 件，切断对 $XS_HOME/build 的依赖
for side in "${SIDES[@]}"; do
  install_dir "$HERE/generated-src" "$SIMW/$side/build/generated-src"
  install_dir "$HERE/build"         "$SIMW/$side/build"
done

printf -v _sides '%s,' "${SIDES[@]}"   # ${SIDES[*]// /,} 不行：[*] 是逐元素替换再按空格拼
log "collateral 已就位：$SIMW/{regen,${_sides%,}}/build"
log "下一步: verif/sim/run_fullchip.sh build golden   # 不会再触发 29 分钟重生成"
