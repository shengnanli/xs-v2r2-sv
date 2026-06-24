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
#   (先编)→ 可读核 xs_M_core → 改名子集 wrapper xs_M_subset → **全端口 wrapper**
#   (golden 同名 module M)。svh 必须内联(difftest VCS 只 +incdir GEN_VSRC_DIR,
#   不含 rtl/ 子目录, 故 `include 失败)。
#
# ★ 全端口 wrapper(gen_full_wrapper.py): 重写子集 wrapper 为可读性会省略 golden 的
#   perf/debug/背压口(io_in_ready / io_in_bits_perfDebugInfo_* / io_out_ready / ...),
#   父模块(ExeUnit)例化时连了这些口 → "Undefined port(UPIMI)"。故据 golden 完整
#   端口表生成 module M, 端口与 golden 1:1; 功能子集接 xs_M_subset(→核), golden
#   多余口: io_in_ready 直通 io_out_ready, perf/debug 输出零延迟直通对应输入, 余者占位 '0。
#   perf/debug 不参与 difftest 架构比对, 不影响 HIT GOOD TRAP。
#
# ★ root-scope 守护(2b): 有的核(Bku.sv)在 $root 写裸 typedef; VCS 库文件 -y 再读
#   会二次解析报 IPD/ICILF。脚本把所有 root-scope typedef/parameter 各自用独立
#   `ifndef/`define guard 包裹, 令库重读跳过。
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

# golden 参考(用于生成全端口 wrapper): 优先 build/rtl/<M>.sv.golden(已替换过),
# 否则 build/rtl/<M>.sv(尚未替换的原 golden)。解析其完整端口表, 让生成的
# wrapper 声明 **所有** golden 端口(子集 wrapper 故意省略的 perf/debug/背压口也补齐),
# 否则父模块例化时会 "Undefined port" 报错(UPIMI)。
GEN_FULL="$SCRIPT_DIR/gen_full_wrapper.py"
GOLDEN_REF=""
if [[ -f "$BUILD_RTL/${MODULE}.sv.golden" ]]; then
  GOLDEN_REF="$BUILD_RTL/${MODULE}.sv.golden"
elif [[ -f "$BUILD_RTL/${MODULE}.sv" ]]; then
  GOLDEN_REF="$BUILD_RTL/${MODULE}.sv"
fi
if [[ -n "$GOLDEN_REF" && -f "$GEN_FULL" ]]; then
  log "golden  : $GOLDEN_REF (full-port wrapper mode)"
else
  log "warn    : no golden ref / generator; emitting subset wrapper as-is (父模块例化可能 Undefined port)"
fi

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

  # wrapper: 先把子集 wrapper 的 svh `include 内联到临时文件(子集 wrapper 大都没有,
  # 但大模块的端口分片在此处理), 再据 golden 全端口表生成 **全端口 wrapper**。
  SUBSET_INLINED="$(mktemp /tmp/st_subset_${MODULE}.XXXXXX.sv)"
  inline_includes "$WRAPPER" > "$SUBSET_INLINED"
  if [[ -n "$GOLDEN_REF" && -f "$GEN_FULL" ]]; then
    echo "// ---- FULL-PORT wrapper (golden-named module ${MODULE}); subset -> renamed inner ----"
    python3 "$GEN_FULL" "$MODULE" "$GOLDEN_REF" "$SUBSET_INLINED"
  else
    echo "// ---- wrapper (golden-named module ${MODULE}): $WRAPPER ----"
    cat "$SUBSET_INLINED"
  fi
  rm -f "$SUBSET_INLINED"
  echo ""
} > "$TMP_BUNDLE"

# ---------------------------------------------------------------------------
# 2b) 守护 root-scope 裸构件(typedef/parameter)。
#   有的重写核(如 Bku.sv)在 $root 作用域(任何 package/module 之外)直接写了
#   typedef struct {...} NAME;。VCS 把 build/rtl/M.sv 当 **库文件**(-y)用: 先扫描
#   建索引, 解析 module M 时再 **重读** 整个文件 → 这些 $root 裸构件被解析两次,
#   报 IPD "Identifier previously declared" + ICILF "constructs in $root of library
#   files must be enclosed in `ifndef/`define/`endif"。(package 与 module 不受此限,
#   故纯 pkg+module 的 Alu bundle 无此问题。)
#   修法(不动重写源, 只处理 bundle): 把所有 **不在 package/module 内的** 顶层
#   typedef/localparam/parameter 用 `ifndef ST_<M>_ROOT_GUARD ... `endif 包起来,
#   令库重读时跳过第二次解析。
# ---------------------------------------------------------------------------
python3 - "$TMP_BUNDLE" "$MODULE" <<'PY'
import sys, re
path, M = sys.argv[1], sys.argv[2]
text = open(path).read()

# 关键: 注释里出现的 "module"/"package"/"endmodule" 会污染 depth 计数(本工程 bundle
# 含大量中文注释提到这些词)。先把 //... 与 /*...*/ 注释 **原位置空格化**(保持长度,
# 使 span 偏移仍可映射回原文), 再做关键字扫描。
def blank_comments(s):
    out = list(s)
    i = 0; n = len(s)
    while i < n:
        if s[i] == '/' and i+1 < n and s[i+1] == '/':
            j = i
            while j < n and s[j] != '\n':
                out[j] = ' '; j += 1
            i = j
        elif s[i] == '/' and i+1 < n and s[i+1] == '*':
            j = i
            while j < n and not (s[j] == '*' and j+1 < n and s[j+1] == '/'):
                if s[j] != '\n': out[j] = ' '
                j += 1
            if j+1 < n:
                out[j] = ' '; out[j+1] = ' '; j += 2
            i = j
        else:
            i += 1
    return "".join(out)

scan = blank_comments(text)

# 用 token 扫描确定 root-scope(任何 package/module 之外)区间: 维护 depth,
# 遇 package/module +1(到对应 endpackage/endmodule -1)。depth==0 处的
# typedef/parameter/localparam 即 $root 裸构件, 需各自用 **独立** guard 包裹
# (同一 guard 会在同次解析里跳过后续块, 故每块一个名)。
tok = re.compile(r'\b(package|module|endpackage|endmodule|typedef|parameter|localparam)\b')
depth = 0
spans = []
for m in tok.finditer(scan):
    kw = m.group(1)
    if kw in ('package', 'module'):
        depth += 1
    elif kw in ('endpackage', 'endmodule'):
        depth = max(0, depth - 1)
    elif kw in ('typedef', 'parameter', 'localparam') and depth == 0:
        s = m.start(); j = m.end(); brace = 0; end = None
        while j < len(scan):
            c = scan[j]            # 用空格化后的副本找语句尾, 避免注释里的 ;/{}
            if c == '{': brace += 1
            elif c == '}': brace -= 1
            elif c == ';' and brace == 0:
                end = j + 1; break
            j += 1
        if end:
            spans.append((s, end))

if spans:
    out = []; last = 0
    for k, (s, e) in enumerate(spans):
        g = "ST_%s_ROOT_G%d" % (M.upper(), k)
        out.append(text[last:s])
        out.append("`ifndef %s\n`define %s\n" % (g, g))
        out.append(text[s:e])
        out.append("\n`endif // %s\n" % g)
        last = e
    out.append(text[last:])
    open(path, "w").write("".join(out))
    sys.stderr.write("[substitute] guarded %d root-scope decl(s) against library re-read\n"
                     % len(spans))
PY

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
