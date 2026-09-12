#!/bin/bash
# FCVT 变异体反证 —— 证明本目录的 UT（尤其是 tb.sv 里的 512 拍定向相位）确实**能抓到**
# fmv 旁路 / 输出宽度标志 / valid 链这三条流水上的相位与使能错误。
# ============================================================================
# 为什么需要它（2026-09-12 FM 反例诊断）：
#   signoff-strict 曾报 20 个 failing，全落在 golden result_r_1 <-> 重写核
#   mvResult_s1 上。查清后是 **Formality 把 fmv 旁路的两级前后配反了**（两级同宽、
#   同无复位、词干与 golden 不同，名字匹配退化成比尾部序号），钉正双射后 FM
#   native SUCCEEDED —— RTL 本身与 golden 等价，UT 也没有漏报。
#   但"UT 没漏报"这句话必须自己拿证据，不能靠 UT 通过来自证。本脚本就是那份证据：
#   把 RTL **临时**改成 5 种错法，要求每一种都被 UT 抓到；跑完原样还原。
#
# ★ 这些变异体只活在本脚本运行期间，绝不进 RTL commit。脚本用 trap 保证异常退出
#   也会还原，并在最后逐字节比对确认 rtl/backend/FCVT.sv 与运行前完全一致。
# ★ 用 SEED=901 跑，日志落 sim_901.log，不碰正式验收的 sim_1/7/42.log。
#
# 用法：  bash mutation_check.sh          （约 5 分钟，5 个变异体各编译+跑 200k 拍）
# 结果：  mutation_result.txt
# ============================================================================
set -u
cd "$(dirname "$0")" || exit 1

RTL=../../../rtl/backend/FCVT.sv
BAK=$(mktemp /tmp/FCVT.sv.orig.XXXXXX)
RES=mutation_result.txt
SEED=901

cp "$RTL" "$BAK"
restore() { cp "$BAK" "$RTL"; }
trap restore EXIT

# 每个变异体：编号|一句话说明|改法（对 $RTL 原地改，必须恰好改动 1 行）
apply_mutation() {
  case "$1" in
    M1) # 末级选择器少走一级流水（正是 Formality 配反时"看起来"的那个错误）
        sed -i 's/? mvResult_s2$/? mvResult_s1/' "$RTL" ;;
    M2) # fmv 第 2 级使能写成 io_in_valid（应为 fireReg_last，即延迟一拍的 valid）
        perl -0pi -e 's/if \(fireReg_last\)\n      mvResult_s2/if (io_in_valid)\n      mvResult_s2/' "$RTL" ;;
    M3) # 输出宽度标志少打一拍（outIs32bits 这条链**完全无使能**，最易写错级数）
        sed -i 's/outIs32bits    <= outIs32bits_s1;/outIs32bits    <= output1H[OW_32];/' "$RTL" ;;
    M4) # e8 的 fmv 改成零扩展（golden 是符号扩展）
        sed -i "s/{{56{src\[7\]}},  src\[7:0\]}/{56'b0, src[7:0]}/" "$RTL" ;;
    M5) # fmv 第 1 级使能加上 ready 门控（golden 用的是**裸** io_in_valid）
        perl -0pi -e 's/if \(io_in_valid\)\n      mvResult_s1/if (rdy[0] & io_in_valid)\n      mvResult_s1/' "$RTL" ;;
  esac
}

describe() {
  case "$1" in
    M1) echo "末级选择器取 mvResult_s1（少走一级 fmv 流水）" ;;
    M2) echo "fmv 第 2 级使能 fireReg_last -> io_in_valid" ;;
    M3) echo "outIs32bits 少打一拍（无使能 RegNext 链级数错）" ;;
    M4) echo "e8 的 fmv 由符号扩展改成零扩展" ;;
    M5) echo "fmv 第 1 级使能由裸 io_in_valid 改成 fire" ;;
  esac
}

{
  echo "FCVT 变异体反证 —— 生成时间 $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "基准 RTL : $(cd ../../.. && git rev-parse HEAD 2>/dev/null || echo nogit) + 工作区改动"
  echo "判据     : 每个变异体都必须让 UT FAIL（errors>0）。任一变异体 PASS = UT 失效。"
  echo "时间戳换算: timescale 1ns/1ps, 时钟周期 10000ps —— 拍号 = t/10000"
  echo "-----------------------------------------------------------------------"
} > "$RES"

fail_total=0
for M in M1 M2 M3 M4 M5; do
  restore
  apply_mutation "$M"
  changed=$(diff "$BAK" "$RTL" | grep -c '^<')
  if [ "$changed" -ne 1 ]; then
    echo "$M : !! 变异未按预期落地（改动行数=$changed，应为 1）—— 脚本与 RTL 已脱节" | tee -a "$RES"
    fail_total=$((fail_total + 1))
    continue
  fi
  make run SEED=$SEED > /dev/null 2>&1
  err=$(grep -oE 'errors=[0-9]+' sim_$SEED.log | tail -1)
  # 首条两侧都非 X 的失配（X 失配只是复位期未初始化寄存器被换了一个，不算功能证据）
  firstk=$(grep 'mismatch' sim_$SEED.log | grep -v 'x' | head -1)
  cyc=$(echo "$firstk" | sed -n 's/^\[\([0-9]*\)\].*/\1/p')
  [ -n "$cyc" ] && cyc=$((cyc / 10000))
  if grep -q "TEST PASSED" sim_$SEED.log; then
    verdict="!! UT 未抓到（本脚本判失败）"
    fail_total=$((fail_total + 1))
  else
    verdict="OK 被抓到"
  fi
  printf '%s : %s\n' "$M" "$(describe "$M")" >> "$RES"
  printf '      %s  %s  首条非X失配=第 %s 拍\n' "$verdict" "${err:-errors=?}" "${cyc:-?}" >> "$RES"
  printf '      %s\n' "${firstk:-<无非X失配>}" >> "$RES"
done

restore
trap - EXIT
rm -f sim_$SEED.log
if diff -q "$BAK" "$RTL" > /dev/null; then
  echo "-----------------------------------------------------------------------" >> "$RES"
  echo "RTL 已逐字节还原：OK" >> "$RES"
else
  echo "!!! RTL 未能还原，请手工核对 $RTL" | tee -a "$RES"
  fail_total=$((fail_total + 1))
fi
rm -f "$BAK"

# 还原后重新编译，别把带变异体的 simv 留给下一次 make run
make compile > /dev/null 2>&1

if [ "$fail_total" -eq 0 ]; then
  echo "结论：5/5 变异体全部被 UT 抓到 —— UT 对这三条流水的相位与使能是有效的。" >> "$RES"
else
  echo "结论：有 $fail_total 项未达标，见上。" >> "$RES"
fi
cat "$RES"
exit "$fail_total"
