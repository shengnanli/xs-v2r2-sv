#!/usr/bin/env python3
"""gen_newifu_lane.py —— newifu-ptwfilter lane 的机械派生件生成器。

只生成两类东西，可读核一律手写：

1. golden 同名 wrapper（写进 rtl 文件的 `// BEGIN GENERATED(wrapper)` 区）
   端口表从 G1 golden 现读、逐字照抄；体里只做「扁平端口 <-> 数组端口」的打包/拆包，
   然后例化手写核 xs_<Top>_core。打包规则是纯名字规则（fail-closed）：
     * 端口名按 `_` 切词，第一个纯数字词是下标；去掉它得到"族名"；
     * 族里只有 1 个成员 -> 标量端口，核端口名 = golden 原名
       （如 io_icachePerfInfo_hit_0_miss_1、io_iTLBInter_resp_bits_paddr_0）；
     * 族里 >1 个成员 -> 核端口是 packed 数组 `[hi:lo][w-1:0] 族名`，下标必须连续、位宽必须一致
       （如 io_toIbuffer_bits_pc_0..15 -> io_toIbuffer_bits_pc[15:0][49:0]；
        io_toIbuffer_bits_pd_1..15_valid -> io_toIbuffer_bits_pd_valid[15:1]）。
   核的端口表是手写的；两边对不上 VCS elaborate 当场报错。

2. FM「匹配前」钉点 verif/ut/<Top>/fm_pins_pre.tcl
   golden 顶层寄存器是 firtool 扁平名，重写核是按字段的数组 —— 名字对不上时 FM 只能靠签名分析
   （LoadQueueRAW lane 实测 Matching 45 分钟不出）。钉点只消名差：每个 golden 寄存器必须恰好命中
   一条规则、映射必须单射、运行时逐条数 set_user_match 返回值，总数 != 字面整数即 error。
   不约束 ref、不改 appvar、不加黑盒、不 dont_verify。

用法：
    python3 scripts/gen_newifu_lane.py            # 写文件（幂等）
    python3 scripts/gen_newifu_lane.py --check    # 只比较，不一致 rc=1
    python3 scripts/gen_newifu_lane.py --core-ports <Top>   # 打印核端口表草稿（手写核时参考）
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, ".."))
GOLDEN_DIR = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")

PORT = re.compile(r'^\s*(input|output)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)\s*,?\s*$')


# ---------------------------------------------------------------------------
#  golden 解析
# ---------------------------------------------------------------------------
def golden_header(top):
    t = open(os.path.join(GOLDEN_DIR, top + ".sv")).read()
    key = "\nmodule %s(" % top
    if key not in t:
        raise SystemExit("golden %s.sv 里找不到 module %s(" % (top, top))
    body = t[t.index(key) + 1:]
    return body[:body.index("\n);") + 3]


def golden_ports(top):
    out = []
    for ln in golden_header(top).splitlines()[1:-1]:
        m = PORT.match(ln)
        if not m:
            raise SystemExit("%s: 端口行解析失败: %r" % (top, ln))
        w = int(m.group(2)) - int(m.group(3)) + 1 if m.group(2) else 1
        out.append((m.group(1), w, m.group(4)))
    return out


def golden_top_regs(top):
    t = open(os.path.join(GOLDEN_DIR, top + ".sv")).read()
    body = t[t.index("\nmodule %s(" % top):]
    body = body[:body.index("\nendmodule")]
    body = re.sub(r"reg\s+(\[\d+:\d+\])\s*\n\s*", r"reg \1 ", body)  # 折行的声明
    out = []
    for a, b, n in re.findall(r"^\s*reg\s+(?:\[(\d+):(\d+)\]\s+)?(\w+);", body, re.M):
        out.append((n, int(a) - int(b) + 1 if a else 1))
    return out


# ---------------------------------------------------------------------------
#  wrapper：扁平端口 <-> 数组端口
# ---------------------------------------------------------------------------
def split_index(name):
    toks = name.split("_")
    for k, tk in enumerate(toks):
        if tk.isdigit() and k > 0:
            return "_".join(toks[:k] + toks[k + 1:]), int(tk)
    return name, None


def families(top):
    """返回 [(方向, 位宽, 核端口名, None | (lo, hi, {idx: golden名}))]，按 golden 出现顺序。"""
    ports = golden_ports(top)
    fam = {}
    for d, w, n in ports:
        key, idx = split_index(n)
        if idx is not None:
            fam.setdefault((d, key), []).append((idx, w, n))
    out, done = [], set()
    names = {n for _, _, n in ports}
    for d, w, n in ports:
        key, idx = split_index(n)
        members = fam.get((d, key), [])
        if idx is None or len(members) == 1:
            out.append((d, w, n, None))
            continue
        if (d, key) in done:
            continue
        done.add((d, key))
        if key in names:
            raise SystemExit("%s: 族名 %s 与某个标量端口撞名" % (top, key))
        idxs = sorted(i for i, _, _ in members)
        if idxs != list(range(idxs[0], idxs[-1] + 1)):
            raise SystemExit("%s: 族 %s 下标不连续 %s" % (top, key, idxs))
        if len({mw for _, mw, _ in members}) != 1:
            raise SystemExit("%s: 族 %s 成员位宽不一致" % (top, key))
        out.append((d, w, key, (idxs[0], idxs[-1], {i: mn for i, _, mn in members})))
    return out


def vec_decl(w, arr):
    s = ""
    if arr:
        s += "[%d:%d]" % (arr[1], arr[0])
    if w > 1:
        s += "[%d:0]" % (w - 1)
    return s


def gen_wrapper(top):
    fams = families(top)
    o = []
    o.append("// 自动生成：scripts/gen_newifu_lane.py —— 勿手改（端口表照抄 G1 golden，体里只做打包/拆包）")
    o.append(golden_header(top).replace("module %s(" % top, "module %s (" % top))
    for d, w, n, arr in fams:
        if not arr:
            continue
        lo, hi, mem = arr
        if d == "input":
            o.append("  wire %s %s = {" % (vec_decl(w, arr), n))
            items = [mem[i] for i in range(hi, lo - 1, -1)]
            for k in range(0, len(items), 4):
                o.append("    " + ", ".join(items[k:k + 4]) + ("," if k + 4 < len(items) else "};"))
        else:
            o.append("  wire %s %s;" % (vec_decl(w, arr), n))
    o.append("")
    o.append("  xs_%s_core u_core (" % top)
    width = max(len(n) for _, _, n, _ in fams)
    for k, (d, w, n, arr) in enumerate(fams):
        o.append("    .%-*s (%s)%s" % (width, n, n, "," if k + 1 < len(fams) else ""))
    o.append("  );")
    o.append("")
    for d, w, n, arr in fams:
        if not arr or d == "input":
            continue
        lo, hi, mem = arr
        for i in range(lo, hi + 1):
            o.append("  assign %s = %s[%d];" % (mem[i], n, i))
    o.append("endmodule")
    return "\n".join(o) + "\n"


def core_ports(top):
    o = []
    fams = families(top)
    for k, (d, w, n, arr) in enumerate(fams):
        o.append("  %-6s logic %-14s %s%s" % (d, vec_decl(w, arr), n, "," if k + 1 < len(fams) else ""))
    return "\n".join(o) + "\n"


def replace_region(text, tag, body, path):
    b = "// BEGIN GENERATED(%s)\n" % tag
    e = "// END GENERATED(%s)\n" % tag
    if text.count(b) != 1 or text.count(e) != 1:
        raise SystemExit("%s: 期望恰好一对 GENERATED(%s) 标记" % (path, tag))
    i, j = text.index(b) + len(b), text.index(e)
    return text[:i] + body + text[j:]


# ---------------------------------------------------------------------------
#  FM 钉点
# ---------------------------------------------------------------------------
def pin_target(top, rules, name):
    hits = []
    for pat, fn in rules:
        m = re.fullmatch(pat, name)
        if m:
            hits.append(fn(m) if callable(fn) else m.expand(fn))
    if len(hits) != 1:
        raise SystemExit("%s: 钉点规则对 golden 寄存器 %s 命中 %d 条（必须恰好 1）" % (top, name, len(hits)))
    return hits[0]


def tcl_path(expr):
    """`a/b.c[1][2]` 形式的核内寄存器表达式 -> FM 对象名（数组名后加 _reg，方括号转义）。"""
    m = re.fullmatch(r"([\w/.]+?)((?:\[\d+\])*)", expr)
    if not m:
        raise SystemExit("钉点目标写法不认识: %s" % expr)
    return m.group(1) + "_reg" + m.group(2).replace("[", "\\[").replace("]", "\\]")


def gen_pins(top, groups):
    """groups: [(golden 模块名, ref 层次前缀, impl 层次前缀, 规则表)]，逐组读 golden 寄存器表。"""
    tag = top.upper()
    lines, total, seen = [], 0, set()
    for gmod, rpfx, ipfx, rules in groups:
        for n, w in golden_top_regs(gmod):
            tgt = ipfx + pin_target(gmod, rules, n)
            if tgt in seen:
                raise SystemExit("%s: 两个 golden 寄存器映射到同一个重写寄存器 %s（不是双射）" % (top, tgt))
            seen.add(tgt)
            total += w
            lines.append("%s_pin %s%s %s %d" % (tag.lower(), rpfx, n, tcl_path(tgt), w))
    o = []
    o.append("# %s FM「匹配前」钉点 —— 自动生成：scripts/gen_newifu_lane.py（勿手改）" % top)
    o.append("#")
    o.append("# 只消 golden 扁平寄存器名与重写核数组名之间的命名鸿沟（依据见生成器文件头）。")
    o.append("# set_user_match 只是声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。")
    o.append("# fail-closed：set_user_match 从不抛异常（返回 0 = 没配上），所以逐条数返回值；")
    o.append("# 拒一条或总数不等于字面整数（= 所列 golden 寄存器位数之和）就 error。")
    o.append("# 进 fm.log 的输出一律 ASCII。")
    o.append("set ::%s_PIN_OK 0" % tag)
    o.append("set ::%s_PIN_BAD 0" % tag)
    o.append("proc %s_pin {g i w} {" % tag.lower())
    o.append("  if {$w == 1} {")
    o.append("    set pairs [list \"r:/WORK/%s/${g}_reg\" \"i:/WORK/%s/${i}\"]" % (top, top))
    o.append("  } else {")
    o.append("    set pairs {}")
    o.append("    for {set b 0} {$b < $w} {incr b} {")
    o.append("      lappend pairs \"r:/WORK/%s/${g}_reg\\[$b\\]\" \"i:/WORK/%s/${i}\\[$b\\]\"" % (top, top))
    o.append("    }")
    o.append("  }")
    o.append("  foreach {r m} $pairs {")
    o.append("    if {[set_user_match $r $m]} { incr ::%s_PIN_OK } else {" % tag)
    o.append("      incr ::%s_PIN_BAD" % tag)
    o.append("      if {$::%s_PIN_BAD <= 10} { puts \"%s_PIN_FAIL: $r <-> $m\" }" % (tag, tag))
    o.append("    }")
    o.append("  }")
    o.append("}")
    o.append("puts \"%s_PIN_BEGIN %s expect=%d\"" % (tag, top, total))
    o += lines
    o.append("puts \"%s_PIN_END %s ok=$::%s_PIN_OK bad=$::%s_PIN_BAD\"" % (tag, top, tag, tag))
    o.append("if {$::%s_PIN_BAD != 0} { error \"%s_PIN_MISS=$::%s_PIN_BAD\" }" % (tag, tag, tag))
    o.append("if {$::%s_PIN_OK != %d} { error \"%s_PIN_COUNT=$::%s_PIN_OK expect=%d\" }"
             % (tag, total, tag, tag, total))
    return "\n".join(o) + "\n"


# ---- 各目标的寄存器映射规则（golden 扁平名 -> 核内寄存器表达式）----
PRED_CHECKER_RULES = [
    (r"fixedRangeNext", r"fixedRange_q"),
    (r"instrValidNext_(\d+)", r"instrValid_q[\1]"),
    (r"takenIdxNext", r"takenIdx_q"),
    (r"predTakenNext", r"predTaken_q"),
    (r"predTargetNext", r"predTarget_q"),
    (r"jumpTargetsNext_(\d+)", r"jumpTarget_q[\1]"),
    (r"seqTargetsNext_(\d+)", r"seqTarget_q[\1]"),
    (r"pdsNext_(\d+)_brType", r"brType_q[\1]"),
    (r"jalFaultVecNext_(\d+)", r"jalFault_q[\1]"),
    (r"jalrFaultVecNext_(\d+)", r"jalrFault_q[\1]"),
    (r"retFaultVecNext_(\d+)", r"retFault_q[\1]"),
    (r"notCFITakenNext_(\d+)", r"notCfiTaken_q[\1]"),
    (r"invalidTakenNext_(\d+)", r"invalidTaken_q[\1]"),
]

FRONTEND_TRIGGER_RULES = [
    (r"tdataVec_(\d)_(matchType|select|timing|action|chain|tdata2)", r"tdata_\2_q[\1]"),
    (r"triggerEnableVec_(\d)", r"enable_q[\1]"),
]

_PERF_INFO = "only_0_hit|only_0_miss|hit_0_hit_1|hit_0_miss_1|miss_0_hit_1|miss_0_miss_1|hit_0_except_1|miss_0_except_1|except_0|hit"
_REQ = "startAddr|nextlineStart|nextStartAddr|ftqIdx_flag|ftqIdx_value|ftqOffset_valid|ftqOffset_bits"
NEWIFU_RULES = [
    (r"topdown_stages_(\d)_reasons_(\d+)", r"topdown_q[\1][\2]"),
    # 各级 valid 与请求字段
    (r"(f[123])_valid", r"\1_valid_q"),
    (r"(f[123])_ftq_req_(%s)" % _REQ, r"\1_\2_q"),
    (r"(f[123])_doubleLine", r"\1_doubleLine_q"),
    (r"wb_ftq_req_(ftqIdx_flag|ftqIdx_value)", r"wb_\1_q"),
    # PC 拆半
    (r"(f2|f3|wb)_pc_lower_result_(\d+)", r"\1_pc_lower_q[\2]"),
    (r"(f2|f3|wb)_pc_(high|high_plus1)", r"\1_pc_\2_q"),
    (r"f3_pc_last_lower_result_(plus2|plus4)", r"f3_pc_last_lower_\1_q"),
    # f2
    (r"f2_icache_all_resp_reg", r"f2_icache_all_resp_q"),
    (r"f2_cut_ptr_(\d+)", r"f2_cut_ptr_q[\1]"),
    (r"(f[23])_resend_vaddr", r"\1_resend_vaddr_q"),
    # f3 数据
    (r"f3_exception_(\d)", r"f3_exception_q[\1]"),
    (r"f3_(pmp_mmio|itlb_pbmt|backendException|hasSatpFlush|instr_range|gpaddr|isForVSnonLeafPTE)", r"f3_\1_q"),
    (r"f3_instr_(\d+)", r"f3_instr_q[\1]"),
    (r"f3_pd_wire_(\d+)_(valid|isRVC|brType|isCall|isRet)", r"f3_pd_\2_q[\1]"),
    (r"f3_jump_offset_(\d+)", r"f3_jump_offset_q[\1]"),
    (r"f3_(exception_vec|crossPage_exception_vec|foldpc|hasHalfValid)_(\d+)", r"f3_\1_q[\2]"),
    (r"f3_paddrs_0", r"f3_paddr0_q"),
    (r"f3_perf_info_(%s)" % _PERF_INFO, r"f3_perf_\1_q"),
    (r"f3_perf_info_bank_hit_(\d)", r"f3_perf_bank_hit_q[\1]"),
    # MMIO
    (r"f3_mmio_data_(\d)", r"f3_mmio_data_q[\1]"),
    (r"mmio_state", r"mmio_state_q"),
    (r"mmio_(exception|is_RVC|has_resend|resend_addr|resend_gpaddr|resend_isForVSnonLeafPTE)", r"mmio_\1_q"),
    (r"is_first_instr", r"is_first_instr_q"),
    (r"f3_mmio_(sent_to_ibuffer|use_seq_pc)", r"f3_mmio_\1_q"),
    (r"io_mmioCommitRead_valid_REG", r"mmioCommitRead_valid_q"),
    (r"io_mmioCommitRead_mmioFtqPtr_REG_(flag|value)", r"mmioCommitRead_ptr_\1_q"),
    (r"fromFtqRedirectReg_bits_r_(ftqIdx_flag|ftqIdx_value|ftqOffset|level)", r"redirect_\1_q"),
    (r"fromFtqRedirectReg_valid_REG", r"redirect_valid_q"),
    (r"mmioF3Flush", r"mmioF3Flush_q"),
    (r"REG", r"f3_entered_mmio_q"),
    (r"wb_enable_REG", r"f3_entered_q"),
    (r"mmioFlushWb_valid_REG", r"uncache_resp_wb_q"),
    (r"mmio_redirect_REG", r"uncache_resp_redirect_q"),
    # last half / 预测检查
    (r"f3_lastHalf_(valid|disable)", r"f3_lastHalf_\1_q"),
    (r"predChecker_io_in_fire_in_REG", r"checker_fire_in_q"),
    (r"REG_1", r"hasLastHalf_dis_q"),
    (r"REG_2", r"f3_fire_d_q"),
    (r"REG_3", r"hasLastHalf_clr_q"),
    # wb
    (r"wb_valid", r"wb_valid_q"),
    (r"wb_check_result_stage1_fixedTaken_(\d+)", r"wb_fixedTaken_q[\1]"),
    (r"wb_instr_range", r"wb_instr_range_q"),
    (r"wb_pd_(\d+)_(isRVC|brType|isCall|isRet)", r"wb_pd_\2_q[\1]"),
    (r"wb_instr_valid_(\d+)", r"wb_instr_valid_q[\1]"),
    (r"wb_lastIdx", r"wb_lastIdx_q"),
    (r"wb_false_lastHalf_r", r"wb_false_lastHalf_q"),
    (r"wb_false_target", r"wb_false_target_q"),
    # perf 两级
    (r"io_perf_(\d+)_value_REG", r"perf_q[0][\1]"),
    (r"io_perf_(\d+)_value_REG_1", r"perf_q[1][\1]"),
]

PINS = {         # top -> [(golden 模块, ref 前缀, impl 前缀, 规则表)]
    "PredChecker": [("PredChecker", "", "u_core/", PRED_CHECKER_RULES)],
    "FrontendTrigger": [("FrontendTrigger", "", "u_core/", FRONTEND_TRIGGER_RULES)],
    # NewIFU：顶层寄存器 + 两个带状态的 child（重写核直接例化 child 的可读核，层次名与 golden 不同）
    "NewIFU": [("NewIFU", "", "u_core/", NEWIFU_RULES),
               ("PredChecker", "predChecker/", "u_core/u_predChecker/", PRED_CHECKER_RULES),
               ("FrontendTrigger", "frontendTrigger/", "u_core/u_frontendTrigger/", FRONTEND_TRIGGER_RULES)],
}
WRAPPERS = {     # top -> rtl 相对路径
    "PredChecker": "rtl/frontend/PredChecker.sv",
    "FrontendTrigger": "rtl/frontend/FrontendTrigger.sv",
    "NewIFU": "rtl/frontend/NewIFU.sv",
}


def targets():
    out = []
    for top, rel in sorted(WRAPPERS.items()):
        path = os.path.join(REPO, rel)
        text = open(path).read()
        out.append((path, replace_region(text, "wrapper", gen_wrapper(top), path)))
    for top, groups in sorted(PINS.items()):
        out.append((os.path.join(REPO, "verif", "ut", top, "fm_pins_pre.tcl"), gen_pins(top, groups)))
    return out


def main():
    if "--core-ports" in sys.argv:
        print(core_ports(sys.argv[sys.argv.index("--core-ports") + 1]), end="")
        return 0
    check = "--check" in sys.argv
    rc = 0
    for path, txt in targets():
        old = open(path).read() if os.path.exists(path) else None
        rel = os.path.relpath(path, REPO)
        if old == txt:
            print("[gen_newifu_lane] %s OK" % rel)
        elif check:
            print("[gen_newifu_lane] %s 与生成结果不一致（请跑 gen_newifu_lane.py 刷新）" % rel)
            rc = 1
        else:
            with open(path, "w") as f:
                f.write(txt)
            print("[gen_newifu_lane] wrote %s" % rel)
    return rc


if __name__ == "__main__":
    sys.exit(main())
