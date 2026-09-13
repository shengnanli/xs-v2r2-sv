#!/usr/bin/env bash
# 必失败负测入口（make negtest）。每个用例的正确值现场从 G1 golden 读，
# 负例只在真值上扰动一处；先跑未扰动的正对照证明"不是什么都编不过"。
set -u
cd "$(dirname "$0")"
exec python3 gen_negtests.py
