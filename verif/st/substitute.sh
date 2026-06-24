#!/usr/bin/env bash
# =============================================================================
# substitute.sh —— 把一个重写模块 M 的 [pkg + 可读核 + 内联svh + wrapper] 拼成
#                  单文件 bundle, 覆盖进香山 golden 库 $NOOP_HOME/build/rtl/M.sv,
#                  原 golden 备份为 M.sv.golden。
#
# 机制(见 verif/st/README.md):
#   香山 difftest VCS 用 `-y $NOOP_HOME/build/rtl +libext+.v +libext+.sv` 作库目录,
#   按 "文件名=模块名" 解析全部 RTL。把 bundle 命名为 M.sv 覆盖原文件后, 凡引用
#   module M 处都会拉到本 bundle, 整文件一起编译。bundle 内顺序: package 在前
#   (先编)→ 可读核 xs_M_core → wrapper(golden 同名 module M, 例化核)。svh 必须
#   内联(difftest VCS 只 +incdir GEN_VSRC_DIR, 不含 rtl/ 子目录, 故 `include 失败)。
#
# 用法:
#   verif/st/substitute.sh <模块名> [--dry-run] [--out <文件>]
#     <模块名>      golden 顶层 module 名, 也是 wrapper 里的 `module <M>`。
#                   会找 rtl/**/<M>_wrapper.sv 作锚点。
#     --dry-run     只生成 bundle 到临时文件并打印路径, 不碰 build/rtl(默认安全建议先跑)。
#     --out <文件>  把 bundle 写到指定文件(配合 --dry-run 做独立 elaborate 验证)。
#
# 纪律: 默认 install 模式会写 build/rtl。golden 基线在编时**只用 --dry-run**。
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SV_HOME="$(cd "$SCRIPT_DIR/../.." && pwd)"
RTL_DIR="$SV_HOME/rtl"
NOOP_HOME="${NOOP_HOME:-/home/eda/xs-env/XiangShan}"
BUILD_RTL="$NOOP_HOME/build/rtl"

die() { echo "[substitute] ERROR: $*" >&2; exit 1; }
log() { echo "[substitute] $*" >&2; }

MODULE=""
DRY_RUN=0
OUT_FILE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift;;
    --out)     OUT_FILE="$2"; shift 2;;
    -h|--help) sed -n '2,30p' "$0"; exit 0;;
    -*)        die "unknown flag: $1";;
    *)         MODULE="$1"; shift;;
  esac
done
[[ -n "$MODULE" ]] || die "missing <module name>. e.g. substitute.sh Alu --dry-run"

# ---------------------------------------------------------------------------
# 1) 定位 wrapper(锚点)、核、pkg、svh
# ---------------------------------------------------------------------------
WRAPPER="$(find "$RTL_DIR" -name "${MODULE}_wrapper.sv" -print -quit)"
[[ -n "$WRAPPER" ]] || die "no wrapper rtl/**/${MODULE}_wrapper.sv found for module '$MODULE'"
SUBDIR="$(dirname "$WRAPPER")"
log "wrapper : $WRAPPER"

# 校验 wrapper 真的声明 module <M>
grep -qE "^[[:space:]]*module[[:space:]]+${MODULE}\b" "$WRAPPER" \
  || die "$WRAPPER does not declare 'module ${MODULE}'"

# 可读核: 同目录 <M>.sv(与 wrapper 同名去掉 _wrapper)。
CORE="$SUBDIR/${MODULE}.sv"
[[ -f "$CORE" ]] || die "core file $CORE not found (expected rtl core <M>.sv)"
log "core    : $CORE"

# 收集 wrapper + core 引用的 package 名(import X::*), 解析到声明 'package X;' 的文件。
collect_pkgs() {
  grep -hoP 'import[[:space:]]+\K[A-Za-z_][A-Za-z0-9_]*(?=::)' "$@" 2>/dev/null | sort -u
}
PKG_FILES=()
declare -A PKG_SEEN=()
resolve_pkg() {
  local p="$1"
  [[ -n "${PKG_SEEN[$p]:-}" ]] && return 0
  PKG_SEEN[$p]=1
  local f
  f="$(grep -rlP "^[[:space:]]*package[[:space:]]+${p}[[:space:]]*;" "$RTL_DIR" 2>/dev/null | head -1)"
  if [[ -n "$f" ]]; then
    # 包之间可能互相 import: 先递归解析依赖, 保证拓扑顺序(被依赖者在前)。
    for dep in $(collect_pkgs "$f"); do
      [[ "$dep" == "$p" ]] && continue
      resolve_pkg "$dep"
    done
    PKG_FILES+=("$f")
    log "pkg     : $p -> $f"
  else
    log "warn    : import package '$p' not found in rtl/ (assumed builtin/std)"
  fi
}
for p in $(collect_pkgs "$CORE" "$WRAPPER"); do resolve_pkg "$p"; done

# 收集 core 引用的 `include svh, 解析到 rtl/ 下同名文件(用于内联)。
collect_svh() {
  grep -hoP '`include[[:space:]]+"\K[^"]+' "$@" 2>/dev/null | sort -u
}
SVH_FILES=()
declare -A SVH_SEEN=()
resolve_svh() {
  local s="$1"
  [[ -n "${SVH_SEEN[$s]:-}" ]] && return 0
  SVH_SEEN[$s]=1
  local f
  f="$(find "$RTL_DIR" -name "$(basename "$s")" -print -quit)"
  [[ -n "$f" ]] || die "core includes '$s' but no such file under rtl/"
  SVH_FILES+=("$f")
  log "svh     : $s -> $f"
}
for s in $(collect_svh "$CORE" "$WRAPPER"); do resolve_svh "$s"; done

# ---------------------------------------------------------------------------
# 2) 拼 bundle。顺序: header → packages → core(svh `include 改成内联) → wrapper
#    svh 内联做法: 把 core/wrapper 里对应的 `include "x.svh" 整行替换为文件内容。
# ---------------------------------------------------------------------------
TMP_BUNDLE="$(mktemp /tmp/st_bundle_${MODULE}.XXXXXX.sv)"
{
  echo "// ==========================================================================="
  echo "// AUTO-GENERATED ST bundle for module ${MODULE}"
  echo "// by verif/st/substitute.sh  $(date '+%Y-%m-%d %H:%M:%S')"
  echo "// sources: pkg(${#PKG_FILES[@]}) core svh(${#SVH_FILES[@]}) wrapper"
  echo "// 替换原 golden ${BUILD_RTL}/${MODULE}.sv (备份 .golden)。"
  echo "// ==========================================================================="
  echo ""
  for f in "${PKG_FILES[@]}"; do
    echo "// ---- package file: $f ----"
    cat "$f"
    echo ""
  done

  # inline_includes <file>: 输出文件内容, 但把 `include "name.svh" 行替换为 svh 内容。
  inline_includes() {
    local src="$1"
    python3 - "$src" "$RTL_DIR" <<'PY'
import sys, os, re
src, rtl_dir = sys.argv[1], sys.argv[2]
inc_re = re.compile(r'^\s*`include\s+"([^"]+)"')
def find(name):
    base = os.path.basename(name)
    for root, _, files in os.walk(rtl_dir):
        if base in files:
            return os.path.join(root, base)
    return None
def emit(path, seen):
    with open(path) as fh:
        for line in fh:
            m = inc_re.match(line)
            if m:
                inc = find(m.group(1))
                if inc and inc not in seen:
                    seen.add(inc)
                    sys.stdout.write("// >>> inlined `include \"%s\"\n" % m.group(1))
                    emit(inc, seen)
                    sys.stdout.write("// <<< end inline \"%s\"\n" % m.group(1))
                elif inc:
                    sys.stdout.write("// (skip dup include %s)\n" % m.group(1))
                else:
                    sys.stdout.write(line)  # leave unresolved (should not happen)
            else:
                sys.stdout.write(line)
emit(src, set())
PY
  }

  echo "// ---- readable core: $CORE ----"
  inline_includes "$CORE"
  echo ""
  echo "// ---- wrapper (golden-named module ${MODULE}): $WRAPPER ----"
  inline_includes "$WRAPPER"
  echo ""
} > "$TMP_BUNDLE"

log "bundle generated: $TMP_BUNDLE ($(wc -l < "$TMP_BUNDLE") lines)"

# 受影响文件清单
echo "[substitute] === affected source files for ${MODULE} ===" >&2
for f in "${PKG_FILES[@]}" "$CORE" "${SVH_FILES[@]}" "$WRAPPER"; do echo "  $f" >&2; done

# ---------------------------------------------------------------------------
# 3) 落地
# ---------------------------------------------------------------------------
if [[ -n "$OUT_FILE" ]]; then
  cp "$TMP_BUNDLE" "$OUT_FILE"
  log "bundle copied to: $OUT_FILE"
fi

if [[ "$DRY_RUN" == "1" ]]; then
  log "DRY-RUN: build/rtl NOT touched. bundle at $TMP_BUNDLE"
  echo "$TMP_BUNDLE"
  exit 0
fi

# install 模式: 备份 golden, 覆盖。
TARGET="$BUILD_RTL/${MODULE}.sv"
[[ -d "$BUILD_RTL" ]] || die "build/rtl not found: $BUILD_RTL (set NOOP_HOME)"

# 包冲突守卫: 若本 bundle 内联的某 package 已被另一个已安装 bundle 定义,
# 全片编译会 package 重定义报错(如 xs_ftb_pkg 被 4 个模块共用)。检测并拒绝。
for f in "${PKG_FILES[@]}"; do
  pname="$(grep -oP '^[[:space:]]*package[[:space:]]+\K[A-Za-z_]\w*' "$f" | head -1)"
  [[ -n "$pname" ]] || continue
  while IFS= read -r other; do
    [[ "$(basename "$other")" == "${MODULE}.sv" ]] && continue   # 自己上次的安装
    log "FATAL: package '$pname' already defined by installed bundle: $other"
    die "package collision — restore that module first, or co-bundle them. (shared pkgs: ftb/ptw/pmp/...)"
  done < <(grep -rlP "^[[:space:]]*package[[:space:]]+${pname}[[:space:]]*;" "$BUILD_RTL" 2>/dev/null)
done
if [[ -f "$TARGET" ]]; then
  if [[ ! -f "$TARGET.golden" ]]; then
    cp "$TARGET" "$TARGET.golden"
    log "backed up golden -> $TARGET.golden"
  else
    log "golden backup already exists, keeping it: $TARGET.golden"
  fi
else
  log "warn: no existing $TARGET (module may be pure-leaf orphan); installing anyway"
fi
cp "$TMP_BUNDLE" "$TARGET"
log "INSTALLED bundle -> $TARGET"
log "rebuild difftest simv to pick it up (see run_st.sh)."
