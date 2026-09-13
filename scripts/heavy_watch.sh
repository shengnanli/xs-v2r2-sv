#!/bin/bash
# heavy_watch.sh —— 采样宿主机资源与 heavy 进程（codex 0149 终止条件 / 0152 D64）。
#
# 采样周期 120s -> 10s（codex 0152 D64）。原因：full3 被内核 OOM 杀时，
# 采样器最后 6 条全是 avail=109~110GiB、si,so=0,0，**三条阈值一条都没命中** ——
# FM elaborate 巨型 RAM 时内存能在两次采样之间从十几 GB 冲到 116 GB。
# 但 codex 明确指出：**仅缩短采样不足以防雪崩**，真正的防线是 heavy_slot.sh 里的
# 任务级内存 containment（cgroup/systemd scope），本脚本仍然只记录/告警、不自动 kill。
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
  sleep "${HEAVY_WATCH_INTERVAL:-10}"
done
