# source 此文件以确保 EDA 工具环境正确
# 本机 VCS（W-2024.09-SP1 @ Rocky 8.10）要求 VCS_ARCH_OVERRIDE=linux 且始终使用 -full64
export VCS_ARCH_OVERRIDE=linux
export XS_HOME="${XS_HOME:-/home/eda/xs-env/XiangShan}"
export XSSV_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export GOLDEN_RTL="$XSSV_HOME/golden/chisel-rtl"

# VCS 通用选项：所有 Makefile 引用
export VCS_OPTS_COMMON="-full64 -sverilog -timescale=1ns/1ps +lint=TFIPC-L -kdb -lca -debug_access+all"
