#!/bin/bash
# heavy_watch.sh —— 每 2 分钟采样宿主机资源与 heavy 进程（codex 0149 的终止条件）。
# 只采样与告警，**不自动 kill**（杀哪个是判断，留给 integrator）。
set -u
OUT="${1:?用法: heavy_watch.sh <采样文件>}"
prev_swap=0; swap_up=0
while :; do
  ts=$(date -Is)
  avail=$(awk '/MemAvailable/{printf "%d",$2/1048576}' /proc/meminfo)
  swap=$(free -m | awk '/Swap/{print $3}')
  siso=$(vmstat 1 2 2>/dev/null | tail -1 | awk '{print $7","$8}')
  [ "$swap" -gt "$prev_swap" ] && swap_up=$((swap_up+1)) || swap_up=0
  prev_swap=$swap
  echo "$ts avail=${avail}GiB swap=${swap}MiB swap_up_streak=$swap_up si,so=$siso" >> "$OUT"
  ps -eo pid,stat,etimes,times,rss,args --no-headers | grep '[f]m_shell_exec' | \
    awk -v t="$ts" '{n=split($NF,a,"/"); printf "%s   pid=%s stat=%s wall=%ss cpu=%ss rss=%.1fGB %s\n",t,$1,$2,$3,$4,$5/1048576,a[n]}' >> "$OUT"
  # codex 0149 的告警阈值
  [ "$avail" -lt 24 ] && echo "$ts ★ALERT MemAvailable<24GiB" >> "$OUT"
  [ "$swap" -gt 3072 ] && [ "$swap_up" -ge 3 ] && echo "$ts ★ALERT swap>3GiB 且连续3次增长" >> "$OUT"
  ps -eo rss,args --no-headers | grep '[f]m_shell_exec' | awk -v t="$ts" '$1/1048576>40{print t" ★ALERT 单任务 RSS>40GiB: "$NF}' >> "$OUT"
  sleep 120
done
