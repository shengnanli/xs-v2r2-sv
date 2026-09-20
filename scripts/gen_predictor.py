#!/usr/bin/env python3
"""
gen_predictor.py —— 生成 rtl/frontend/Predictor.sv 里的**机械派生区**。

Predictor 的 633 个端口里 457 个(72%)是 MBIST 扫描链(sigFromSrams_bore_* /
boreChildrenBd_bore_*)，一根不改地穿到 Composer；Composer 那 827 根连线里也有
460 根是同名直通、63 根直连顶层输出。这些区域没有可读性可言，手抄只会抄错，
所以由本脚本按 golden 的端口表/例化表原地生成，用
`// BEGIN GENERATED(<tag>)` / `// END GENERATED(<tag>)` 标记。手写区脚本不碰。

生成两个区：
  ports          —— Predictor wrapper 的 633 端口表（与 golden 逐位同名/同宽/同序）
  glue_decls     —— wrapper 里接 Composer 用的中间线声明（宽度取自 Composer 端口表）
  passthru       —— golden 里 `assign <顶层输出> = _predictors_io_out_*` 那 40 根直通
  composer_inst  —— Composer predictors 的 827 根连线

用法: python3 scripts/gen_predictor.py [--check]
"""
import os, re, sys, pathlib

REPO   = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path(os.environ.get("GOLDEN_RTL",
             "/home/eda/xs-env/G1-canonical/golden-rtl")) / "Predictor.sv"
TARGET = REPO / "rtl/frontend/Predictor.sv"

PORT_RE = re.compile(r'^\s+(input|output)\s+(\[\d+:\d+\])?\s*([A-Za-z_]\w*)\s*,?\s*$')


def golden_ports():
    out, inside = [], False
    for line in GOLDEN.read_text().splitlines():
        if line.startswith("module Predictor("):
            inside = True; continue
        if inside:
            if line.startswith(");"):
                break
            m = PORT_RE.match(line)
            if m:
                out.append((m.group(1), m.group(2) or "", m.group(3)))
    return out


def golden_composer_conns():
    """返回 golden 里 Composer 实例的 [(pin, rhs)]。

    ★必须用括号深度扫描，不能用正则★：io_in_bits_ghist 这类 pin 的 RHS 是一个
    嵌套四层的三元表达式，正则匹配会**静默漏掉**这根线（本轮实测：io_in_bits_ghist
    与 io_in_valid 两根被漏掉，wrapper 里 Composer 的 ghist 输入整根悬空成 z，
    UT 一跑就是满屏 X）。下面按字符扫，并在 main() 里用 Composer 端口表做完备性校验。
    """
    lines = GOLDEN.read_text().split("\n")
    start = next(i for i, l in enumerate(lines) if l.strip().startswith("Composer predictors ("))
    depth, body = 0, []
    for i in range(start, len(lines)):
        body.append(lines[i])
        depth += lines[i].count("(") - lines[i].count(")")
        if i > start and depth == 0:
            break
    txt = "\n".join(body)
    txt = txt[txt.index("(") + 1: txt.rindex(")")]          # 剥掉最外层括号

    conns, i, n = [], 0, len(txt)
    while i < n:
        while i < n and txt[i] != ".":
            i += 1
        if i >= n:
            break
        i += 1
        j = i
        while j < n and (txt[j].isalnum() or txt[j] == "_"):
            j += 1
        pin = txt[i:j]
        while j < n and txt[j] != "(":
            j += 1
        k, d = j, 0
        while k < n:                                        # 括号配平找 RHS 结尾
            if txt[k] == "(":
                d += 1
            elif txt[k] == ")":
                d -= 1
                if d == 0:
                    break
            k += 1
        conns.append((pin, " ".join(txt[j + 1:k].split())))
        i = k + 1
    return conns


# ---- 连线规则：pin -> wrapper 侧 RHS -----------------------------------------
# golden 的 RHS 若本身就是顶层端口名，直接沿用；否则按下面的结构规则映射到
# 可读核的信号。规则按顺序匹配，第一条命中为准。
def rhs_for(pin, grhs, topports, width=""):
    if grhs in topports:
        return grhs                                   # 顶层端口直通（含全部 MBIST）
    m = re.fullmatch(r"io_in_bits_s0_pc_(\d)", pin)
    if m: return f"s0_pc_w[{m.group(1)}]"
    m = re.fullmatch(r"io_in_bits_folded_hist_(\d)_hist_(\d+)_folded_hist", pin)
    # 折叠历史现在是 packed 结构、每条按自己的 CLEN 开宽，端口宽度天然相等，
    # 不再需要 golden 端口宽度切片（早先的 [10:0]/[3:0] 是等宽存储留下的疤）。
    if m: return f"s0_fg_w[{m.group(1)}].h{m.group(2)}"
    m = re.fullmatch(r"io_in_bits_s1_folded_hist_(\d)_hist_(\d+)_folded_hist", pin)
    if m: return f"s1_fg_w[{m.group(1)}].h{m.group(2)}"
    m = re.fullmatch(r"io_in_bits_ghist", pin)
    if m: return "s0_ghist_w"
    m = re.fullmatch(r"io_s([0-3])_fire_(\d)", pin)
    if m: return f"s{m.group(1)}_fire_w[{m.group(2)}]"
    m = re.fullmatch(r"io_s([23])_redirect_(\d)", pin)
    if m: return f"s{m.group(1)}_redirect_w[{m.group(2)}]"
    if pin == "io_in_valid":            return "s0_fire_w[0]"
    if pin == "io_redirectFromIFU":     return "redirect_from_ifu_q_w"
    if pin == "io_redirect_valid":      return "do_redirect_valid_w"
    if pin == "io_update_bits_ghist":   return "update_ghist_w"
    if pin == "io_update_bits_pc":      return "update_pc_seg_w"
    m = re.fullmatch(r"io_perf_(\d)_value", pin)
    if m: return f"comp_perf_w[{m.group(1)}]"
    m = re.fullmatch(r"io_s([123])_ready", pin)
    if m: return f"comp_s{m.group(1)}_ready_w"
    m = re.fullmatch(r"io_redirect_bits_(.*)", pin)
    if m: return "rdr_q_" + m.group(1)
    m = re.fullmatch(r"io_ctrl_(.*)", pin)
    if m: return "ctrl_q_" + m.group(1)
    if pin.startswith("io_out_"):       return "comp_" + pin[len("io_out_"):]
    if pin.startswith("io_in_bits_resp_in_0_") or pin.startswith("io_fauftb_entry_"):
        return None                                   # Chisel 侧钉常数 0，见 wrapper 注释
    return "/*TODO*/" + pin


def composer_port_widths():
    """从重写件 rtl/frontend/Composer.sv 的 wrapper 端口表取每个 pin 的宽度。"""
    src = (REPO / "rtl/frontend/Composer.sv").read_text().split("\n")
    start = next(i for i, l in enumerate(src) if l.startswith("module Composer("))
    w = {}
    for l in src[start + 1:]:
        if l.startswith(");"):
            break
        m = PORT_RE.match(l)
        if m:
            w[m.group(3)] = (m.group(1), m.group(2) or "")
    return w


def gen_glue_decls(conns, topports, cw):
    """声明所有非顶层端口的中间线。宽度以 Composer 端口表为准。"""
    seen, rows = set(), []
    for pin, grhs in conns:
        rhs = rhs_for(pin, grhs, topports)
        if rhs is None or rhs in topports:
            continue
        if not re.fullmatch(r"[A-Za-z_]\w*", rhs):      # 带下标的(数组元素)由手写区声明
            continue
        if rhs in seen:
            continue
        seen.add(rhs)
        _, width = cw.get(pin, ("input", ""))
        rows.append((width, rhs))
    ww = max((len(w) for w, _ in rows), default=0)
    return [f"  logic {w:<{ww}} {n};" for w, n in sorted(rows, key=lambda r: r[1])]


def gen_pred_pack():
    """把 Composer 吐出的散装 full_pred 字段打包成 full_pred_t 送进可读核。
    字段名与 predictor_pkg::full_pred_t 一一对应；multiHit 只有 S3 有真值。"""
    rows = []
    for st in ("s1", "s2", "s3"):
        for d in range(4):
            b = f"comp_{st}_full_pred_{d}_"
            mh = f"{b}multiHit" if st == "s3" else "1'b0"
            rows += [
                f"  assign {st}_pred_w[{d}] = '{{",
                f"      br_taken_mask:     {{{b}br_taken_mask_1, {b}br_taken_mask_0}},",
                f"      slot_valids:       {{{b}slot_valids_1, {b}slot_valids_0}},",
                f"      targets:           {{{b}targets_1, {b}targets_0}},",
                f"      jalr_target:       {b}jalr_target,",
                f"      offsets:           {{{b}offsets_1, {b}offsets_0}},",
                f"      fall_through_addr: {b}fallThroughAddr,",
                f"      fall_through_err:  {b}fallThroughErr,",
                f"      multi_hit:         {mh},",
                f"      is_br_sharing:     {b}is_br_sharing,",
                f"      hit:               {b}hit}};",
            ]
        rows.append("")
    return rows[:-1]


def gen_passthru(topports):
    """golden 用一条 assign 把 Composer 的输出接到顶层输出的那些线。
    （另有 63 根是直接写在实例连线里的，由 composer_inst 覆盖，不在这里。）"""
    src = GOLDEN.read_text()
    rows = []
    for m in re.finditer(r"assign\s+([A-Za-z_]\w*)\s*=\s*_predictors_io_out_([A-Za-z_]\w*)\s*;", src):
        if m.group(1) in topports:
            rows.append((m.group(1), "comp_" + m.group(2)))
    nw = max((len(a) for a, _ in rows), default=0)
    return [f"  assign {a:<{nw}} = {b};" for a, b in sorted(rows)]


def gen_ports(ports):
    dw = max(len(d) for d, _, _ in ports)
    ww = max(len(w) for _, w, _ in ports)
    return [f"  {d:<{dw}} {w:<{ww}} {n}" + ("" if i == len(ports) - 1 else ",")
            for i, (d, w, n) in enumerate(ports)]


def gen_composer(conns, topports, cw):
    body, unresolved = ["  Composer predictors ("], []
    pw = max(len(p) for p, _ in conns)
    items = []
    for pin, grhs in conns:
        rhs = rhs_for(pin, grhs, topports, cw.get(pin, ('', ''))[1])
        if rhs is None:
            rhs = "'0"                                # resp_in / fauftb_entry：Chisel 钉 0
        if rhs.startswith("/*TODO*/"):
            unresolved.append(pin)
        items.append((pin, rhs))
    for i, (pin, rhs) in enumerate(items):
        comma = "" if i == len(items) - 1 else ","
        body.append(f"    .{pin:<{pw}} ({rhs}){comma}")
    body.append("  );")
    return body, unresolved


def main():
    ports = golden_ports()
    assert len(ports) == 633, f"expected 633 golden ports, got {len(ports)}"
    topports = {n for _, _, n in ports}
    conns = golden_composer_conns()
    cw = composer_port_widths()
    # ★完备性校验★：生成的连线必须**恰好**覆盖 Composer 的全部端口，一根不多一根不少。
    pins, cpins = {p for p, _ in conns}, set(cw)
    missing, extra = cpins - pins, pins - cpins
    if missing or extra:
        print(f"[gen_predictor] Composer 连线不完备: 少 {sorted(missing)} 多 {sorted(extra)}",
              file=sys.stderr)
        return 2
    if len(conns) != len(pins):
        print(f"[gen_predictor] Composer 连线有重复 pin", file=sys.stderr)
        return 2
    comp, unresolved = gen_composer(conns, topports, cw)
    blocks = {"ports": gen_ports(ports),
              "glue_decls": gen_glue_decls(conns, topports, cw),
              "pred_pack": gen_pred_pack(),
              "passthru": gen_passthru(topports),
              "composer_inst": comp}

    if unresolved:
        print(f"[gen_predictor] {len(unresolved)} 根连线没有规则:", file=sys.stderr)
        for p in unresolved[:40]:
            print("   ", p, file=sys.stderr)
        return 2
    if not TARGET.exists():
        for tag, b in blocks.items():
            print(f"--- {tag}: {len(b)} lines")
        return 1

    text = orig = TARGET.read_text()
    for tag, b in blocks.items():
        pat = re.compile(r"(  // BEGIN GENERATED\(" + tag + r"\)\n).*?(  // END GENERATED\(" + tag + r"\))", re.S)
        if not pat.search(text):
            print(f"[gen_predictor] 缺 GENERATED({tag}) 标记", file=sys.stderr)
            return 1
        text = pat.sub(lambda m: m.group(1) + "\n".join(b) + "\n" + m.group(2), text)
    if "--check" in sys.argv:
        if text != orig:
            print("[gen_predictor] 机械区与 golden 不同步（请重跑 scripts/gen_predictor.py）", file=sys.stderr)
            return 1
        print("[gen_predictor] OK")
        return 0
    TARGET.write_text(text)
    print(f"[gen_predictor] 已更新 {TARGET}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
