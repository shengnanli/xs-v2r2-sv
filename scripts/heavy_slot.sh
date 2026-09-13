#!/bin/bash
# heavy_slot.sh —— 全机 heavy 任务的 fail-closed slot gate（codex 0149 要求）。
#
# 背景：0144/0145 定的"同时最多 2 个 heavy"此前只靠人工记忆执行，结果我在两个
# universe 已满时批准了会跑 FM 的 owner，把 swap 从 0 推到 1.8 GB。codex 0149：
#   "未来由调度锁/slot 构造保证，不能靠人工记忆。"
#
# 语义：
#   acquire <target>  原子取 token；取不到则非零退出（**不排队、不偷跑**）
#   release <target>  释放
#   status            列出当前 token 与阈值检查
# token 文件记 owner PID + start time，陈旧 token 只在 PID+starttime 都对不上时才清理。
set -u
LOCKDIR="${HEAVY_SLOT_DIR:-/tmp/xsv2-heavy-slots}"
MAX_HEAVY="${HEAVY_SLOT_MAX:-2}"
MIN_AVAIL_GIB="${HEAVY_MIN_AVAIL_GIB:-24}"
MAX_SWAP_GIB="${HEAVY_MAX_SWAP_GIB:-3}"
mkdir -p "$LOCKDIR"

_starttime() { awk '{print $22}' /proc/$1/stat 2>/dev/null; }

# 清理陈旧 token：PID 不存在，或 PID 存在但 starttime 对不上（PID 被复用）
_reap() {
  for f in "$LOCKDIR"/*.token; do
    [ -e "$f" ] || continue
    local pid st cur
    pid=$(sed -n 's/^pid=//p' "$f"); st=$(sed -n 's/^starttime=//p' "$f")
    cur=$(_starttime "$pid")
    if [ -z "$cur" ] || [ "$cur" != "$st" ]; then
      echo "heavy_slot: 回收陈旧 token $(basename "$f") (pid=$pid 已不在或被复用)" >&2
      rm -f "$f"
    fi
  done
}

_avail_gib() { awk '/MemAvailable/{printf "%d",$2/1048576}' /proc/meminfo; }
_swap_gib()  { free -g | awk '/Swap/{print $3}'; }

case "${1:-}" in
  acquire)
    tgt="${2:?用法: heavy_slot.sh acquire <target>}"
    _reap
    a=$(_avail_gib); s=$(_swap_gib)
    if [ "$a" -lt "$MIN_AVAIL_GIB" ]; then
      echo "heavy_slot: 拒绝 —— MemAvailable ${a}GiB < ${MIN_AVAIL_GIB}GiB" >&2; exit 2; fi
    if [ "$s" -gt "$MAX_SWAP_GIB" ]; then
      echo "heavy_slot: 拒绝 —— swap 已用 ${s}GiB > ${MAX_SWAP_GIB}GiB" >&2; exit 2; fi
    n=$(ls -1 "$LOCKDIR"/*.token 2>/dev/null | wc -l)
    if [ "$n" -ge "$MAX_HEAVY" ]; then
      echo "heavy_slot: 拒绝 —— 已有 $n 个 heavy（上限 $MAX_HEAVY）：" >&2
      grep -h '^target=' "$LOCKDIR"/*.token 2>/dev/null | sed 's/^/    /' >&2
      exit 2; fi
    # 原子创建：noclobber 保证并发下只有一个赢家
    f="$LOCKDIR/$$.token"
    if ! (set -o noclobber; printf 'pid=%s\nstarttime=%s\ntarget=%s\nstart=%s\n' \
            "$$" "$(_starttime $$)" "$tgt" "$(date -Is)" > "$f") 2>/dev/null; then
      echo "heavy_slot: 拒绝 —— token 创建失败" >&2; exit 2; fi
    echo "heavy_slot: 取得 token $f (target=$tgt, 现有 $((n+1))/$MAX_HEAVY)"
    ;;
  release)
    rm -f "$LOCKDIR/$$.token"; _reap
    echo "heavy_slot: 已释放 (pid=$$)"
    ;;
  status)
    _reap
    n=$(ls -1 "$LOCKDIR"/*.token 2>/dev/null | wc -l)
    echo "heavy token: $n/$MAX_HEAVY   MemAvailable=$(_avail_gib)GiB   swap=$(_swap_gib)GiB"
    for f in "$LOCKDIR"/*.token; do [ -e "$f" ] && { echo "  --- $(basename "$f") ---"; sed 's/^/    /' "$f"; }; done
    ;;
  *) echo "用法: heavy_slot.sh {acquire <target>|release|status}" >&2; exit 64;;
esac
