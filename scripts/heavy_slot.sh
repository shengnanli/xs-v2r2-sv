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


# ---- codex 0152 D64：任务级内存 containment 探测（fail-closed）----
# 实测结论（2026-09-13，本机 125 GB）：**containment 建不起来**。
#   systemd-run --user --scope -p MemoryMax=256M 命令成功、scope 也建了，
#   但分配到 1.6 GB 仍未被杀；memory cgroup 仍是
#     /user.slice/user-1000.slice/user@1000.service
#   memory.limit_in_bytes = 9223372036854771712（无限制）。
#   根因：本机是 cgroup **v1**（/sys/fs/cgroup/cgroup.controllers 不可读），
#   v1 下 memory controller 不向普通用户下放。
#   ★ 只看"命令退出码 0"就认为 containment 生效，正是典型的 fail-open ★
#
# 据此按 D64 的降级条款执行：NORMAL 退化为**单 heavy**，XL **禁止启动**。
# 探测每次 acquire 都实跑，环境变好（如换 cgroup v2 主机）会自动恢复双 token。
_containment_ok() {
  [ -r /sys/fs/cgroup/cgroup.controllers ] || return 1          # 必须 cgroup v2
  grep -qw memory /sys/fs/cgroup/cgroup.controllers || return 1 # 必须有 memory 控制器
  command -v systemd-run >/dev/null || return 1
  # 实证：256M 上限下分配 512M 必须失败
  systemd-run --user --scope --quiet -p MemoryMax=256M --unit="xsv2-probe-$$" \
      python3 -c "bytearray(512*1024*1024)" >/dev/null 2>&1 && return 1
  return 0
}

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
    tgt="${2:?用法: heavy_slot.sh acquire <target> [owner_pid]}"
    # ★ token 必须归属**真正跑 heavy 的进程**，不是取锁的这个 shell ★
    # 实测缺陷（2026-09-13）：原实现用 $$ 记 pid，而 acquire 一返回该 shell 就退出，
    # _reap() 立刻判定 token 陈旧并回收 —— **这个锁从建起来就是空的，没拦住过任何东西**。
    # OpenLLC 与 full3 能同时跑（外加两个 universe）正是因为这个。
    # 用法二选一：
    #   1) 先起 heavy 拿到 PID，再 `acquire <target> <pid>`；
    #   2) `exec` 模式：heavy_slot.sh run <target> -- <命令...>（token 绑 exec 后的进程）
    owner="${3:-$$}"
    _reap
    a=$(_avail_gib); s=$(_swap_gib)
    if [ "$a" -lt "$MIN_AVAIL_GIB" ]; then
      echo "heavy_slot: 拒绝 —— MemAvailable ${a}GiB < ${MIN_AVAIL_GIB}GiB" >&2; exit 2; fi
    if [ "$s" -gt "$MAX_SWAP_GIB" ]; then
      echo "heavy_slot: 拒绝 —— swap 已用 ${s}GiB > ${MAX_SWAP_GIB}GiB" >&2; exit 2; fi
    # D64 降级：containment 不可信时 NORMAL 上限降为 1
    eff_max="$MAX_HEAVY"
    if ! _containment_ok; then
      eff_max=1
      echo "heavy_slot: ⚠ 内存 containment 不可用（cgroup v1 / MemoryMax 未生效）—— 按 codex 0152 D64 降级为单 heavy" >&2
    fi
    if [ "${HEAVY_CLASS:-NORMAL}" = XL ] && ! _containment_ok; then
      echo "heavy_slot: 拒绝 —— XL 类任务要求可信 containment（MemoryHigh 80/MemoryMax 96 GiB），本机不可用" >&2
      exit 2
    fi
    n=$(ls -1 "$LOCKDIR"/*.token 2>/dev/null | wc -l)
    if [ "$n" -ge "$eff_max" ]; then
      echo "heavy_slot: 拒绝 —— 已有 $n 个 heavy（当前有效上限 $eff_max）：" >&2
      grep -h '^target=' "$LOCKDIR"/*.token 2>/dev/null | sed 's/^/    /' >&2
      exit 2; fi
    # 原子创建：noclobber 保证并发下只有一个赢家
    if ! ps -o pid= -p "$owner" >/dev/null 2>&1; then
      echo "heavy_slot: 拒绝 —— owner pid=$owner 不存在（token 必须绑活进程）" >&2; exit 2; fi
    f="$LOCKDIR/$owner.token"
    if ! (set -o noclobber; printf 'pid=%s\nstarttime=%s\ntarget=%s\nstart=%s\n' \
            "$owner" "$(_starttime $owner)" "$tgt" "$(date -Is)" > "$f") 2>/dev/null; then
      echo "heavy_slot: 拒绝 —— token 创建失败" >&2; exit 2; fi
    echo "heavy_slot: 取得 token $f (target=$tgt, owner_pid=$owner, 现有 $((n+1))/$eff_max)"
    ;;
  run)
    # heavy_slot.sh run <target> -- <命令...>
    # 先取 token（绑本 shell），再 exec —— exec 保持同一 PID，token 自然跟着 heavy 走。
    tgt="${2:?用法: heavy_slot.sh run <target> -- <命令...>}"
    shift 2; [ "${1:-}" = "--" ] && shift
    [ $# -gt 0 ] || { echo "heavy_slot: run 需要命令" >&2; exit 64; }
    "$0" acquire "$tgt" $$ || exit $?
    trap 'rm -f "$LOCKDIR/$$.token"' EXIT INT TERM
    exec "$@"
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
  *) echo "用法: heavy_slot.sh {acquire <target> [owner_pid]|run <target> -- <cmd>|release|status}" >&2; exit 64;;
esac
