#!/usr/bin/env python3
"""gen_mainpipe.py —— DCache MainPipe 的机械派生区生成器（幂等，带 --check）。

唯一的"真来源"是本文件里的 IO 规格表（TYPES / PORTS）：它按 Chisel 的 IO Bundle
结构（DecoupledIO / ValidIO / Vec）描述可读核 xs_MainPipe_core 的端口，并规定了
struct 字段路径与 golden 扁平端口名之间的**唯一**换算规则：

    golden 名 = "io_" + 端口名 [+ "_" + 下标] { + "_" + 字段名 [+ "_" + 下标] }

（与 firtool 展平 Bundle 的规则一致：Vec 下标、Bundle 字段都用下划线接起来。）

生成的区域（在各文件里用 BEGIN/END GENERATED(<tag>) 标记，原地替换，手写区不碰）：
  rtl/memblock/MainPipe.sv
    io_types   —— package 里 IO bundle 的 typedef
    core_ports —— xs_MainPipe_core 的端口表
    wrapper    —— golden 同名 wrapper MainPipe（扁平端口 <-> struct，纯接线）
  verif/ut/MainPipe/tb.sv
    tb_ports   —— 输入寄存器 / 两侧输出线声明、golden 与 _xs 两个实例
    tb_compare —— 每拍逐位比较**全部**输出端口的 task

生成时三道机械核对（任何一道不过直接退出，不写文件）：
  1. 规格展平出来的名字集合 == golden 端口集合（clock/reset 除外），不多不少；
  2. 每个名字的方向与位宽和 golden 端口表逐个相等；
  3. 同一个 golden 端口只被映射一次。

用法：python3 gen_mainpipe.py          生成/刷新（内容不变不写）
      python3 gen_mainpipe.py --check  只比较，任何区域不一致 rc=1
"""
import os, re, sys

G = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")
HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "../../.."))
RTL_FILE = os.path.join(REPO, "rtl/memblock/MainPipe.sv")
TB_FILE = os.path.join(HERE, "tb.sv")
TOP = "MainPipe"
PORT_RE = re.compile(r'^\s*(input|output)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)\s*,?\s*$')

# ---------------------------------------------------------------------------
# IO 规格表
#   TYPES: 类型名 -> [(字段名, 类型(int=位宽 / str=类型名), 个数(None=标量), 注释)]
#          顺序即 typedef 的输出顺序（被引用的类型必须排在前面）
#   PORTS: (方向, 端口名, 类型, 个数, 注释)  —— 顺序即核端口表顺序
# ---------------------------------------------------------------------------
TYPES = [
    ("tl_error_t", [
        ("tl_denied", 1, None, "L2 拒绝访问（denied）"),
        ("tl_corrupt", 1, None, "数据损坏（corrupt）"),
    ]),
    ("probe_req_bits_t", [          # ProbeQueue -> MainPipe（MainPipeReq 里 probe 用到的字段）
        ("probe_param", 2, None, "TileLink probe 目标权限 toT/toB/toN"),
        ("probe_need_data", 1, None, "probe 要不要把数据带回去"),
        ("vaddr", 50, None, "取 set 下标用"),
        ("addr", 48, None, "被 probe 的块物理地址"),
        ("id", 6, None, "请求 id"),
    ]),
    ("refill_req_bits_t", [         # MissQueue -> MainPipe（回填请求）
        ("miss_id", 4, None, "MissQueue 表项号"),
        ("occupy_way", 4, None, "BtoT 升权失败时强制占用的路"),
        ("miss_fail_cause_evict_btot", 1, None, "置 1：替换路用 occupy_way"),
        ("source", 4, None, "原请求来源（store/amo/load）"),
        ("cmd", 5, None, "原请求命令"),
        ("vaddr", 50, None, ""),
        ("addr", 48, None, ""),
        ("word_idx", 3, None, "AMO miss 回填时作用的字"),
        ("amo_data", 128, None, ""),
        ("amo_mask", 16, None, ""),
        ("amo_cmp", 128, None, ""),
        ("pf_source", 3, None, "预取来源（写进 prefetch 标志阵列）"),
        ("access", 1, None, "是否被访问过（写进 access 标志阵列）"),
        ("id", 6, None, ""),
    ]),
    ("store_req_bits_t", [          # Sbuffer -> MainPipe（DCacheLineReq，整行写）
        ("vaddr", 50, None, ""),
        ("addr", 48, None, ""),
        ("data", 512, None, "整行 store 数据"),
        ("mask", 64, None, "字节掩码"),
        ("id", 6, None, "Sbuffer 表项号"),
    ]),
    ("atomic_req_bits_t", [         # AtomicsUnit -> MainPipe
        ("cmd", 5, None, "M_XLR/M_XSC/M_XA_*"),
        ("vaddr", 50, None, ""),
        ("addr", 48, None, ""),
        ("word_idx", 3, None, "作用的 64 位字"),
        ("amo_data", 128, None, ""),
        ("amo_mask", 16, None, ""),
        ("amo_cmp", 128, None, "AMOCAS 比较值"),
    ]),
    ("miss_req_bits_t", [           # MainPipe -> MissQueue（store/AMO miss）
        ("source", 4, None, ""),
        ("cmd", 5, None, ""),
        ("addr", 48, None, ""),
        ("vaddr", 50, None, ""),
        ("full_overwrite", 1, None, "store 整行覆盖（可免读 L2 数据）"),
        ("word_idx", 3, None, ""),
        ("amo_data", 128, None, ""),
        ("amo_mask", 16, None, ""),
        ("amo_cmp", 128, None, ""),
        ("req_coh_state", 2, None, "请求时本地的 coh 状态"),
        ("id", 6, None, ""),
        ("isBtoT", 1, None, "Branch->Trunk 升权请求"),
        ("occupy_way", 4, None, "升权时占用的那一路"),
        ("cancel", 1, None, "升权失败（BtoT 路太多），MissQueue 丢弃"),
        ("store_data", 512, None, ""),
        ("store_mask", 64, None, ""),
    ]),
    ("atomic_resp_bits_t", [        # MainPipe -> AtomicsUnit
        ("source", 4, None, ""),
        ("data", 128, None, "AMO 旧值 / SC 结果"),
        ("miss", 1, None, ""),
        ("miss_id", 4, None, ""),
        ("replay", 1, None, "要求 AtomicsUnit 重发"),
        ("tl_error", "tl_error_t", None, ""),
        ("ack_miss_queue", 1, None, "AMO miss 在主流水完成，通知 MissQueue"),
        ("id", 6, None, "借用：LR/SC 保留集是否还有效"),
    ]),
    ("mainpipe_info_t", [           # MainPipe -> MissQueue（MainPipeInfoToMQ）
        ("s2_valid", 1, None, "s2 是 refill 请求"),
        ("s2_miss_id", 4, None, ""),
        ("s2_replay_to_mq", 1, None, "s2 refill 没等到数据，回 MissQueue 重来"),
        ("s2_evict_BtoT_way", 1, None, "s2 替换被 MissQueue 阻塞"),
        ("s2_next_evict_way", 4, None, "第一个非 BtoT 的路（独热）"),
        ("s3_valid", 1, None, ""),
        ("s3_miss_id", 4, None, ""),
        ("s3_refill_resp", 1, None, "上一拍 refill 进了 s3"),
    ]),
    ("refill_info_bits_t", [        # MissQueue -> MainPipe（回填数据）
        ("store_data", 512, None, ""),
        ("store_mask", 64, None, ""),
        ("miss_param", 2, None, "Grant 的权限 toT/toB"),
        ("error", "tl_error_t", None, ""),
    ]),
    ("wb_bits_t", [                 # MainPipe -> WritebackQueue
        ("param", 3, None, "Release/ProbeAck 的 shrink 参数"),
        ("voluntary", 1, None, "主动 Release（替换）而非 ProbeAck"),
        ("hasData", 1, None, ""),
        ("corrupt", 1, None, ""),
        ("dirty", 1, None, ""),
        ("addr", 48, None, ""),
        ("data", 512, None, ""),
    ]),
    ("readline_bits_t", [           # 读 data SRAM 整行
        ("way_en", 4, None, ""),
        ("addr", 48, None, ""),
        ("rmask", 8, None, "要读的 bank"),
    ]),
    ("data_resp_t", [
        ("raw_data", 64, None, "一个 bank 的 64 位数据"),
    ]),
    ("data_write_bits_t", [
        ("wmask", 8, None, "要写的 bank"),
        ("data", 64, 8, "8 个 bank 的写数据"),
    ]),
    ("data_write_ctrl_t", [
        ("way_en", 4, None, ""),
        ("addr", 48, None, ""),
    ]),
    ("data_write_dup_t", [          # 每个 bank 一份的写控制复制（时序用）
        ("valid", 1, None, ""),
        ("bits", "data_write_ctrl_t", None, ""),
    ]),
    ("meta_t", [
        ("coh_state", 2, None, "Nothing/Branch/Trunk/Dirty"),
    ]),
    ("meta_write_bits_t", [
        ("idx", 8, None, ""),
        ("way_en", 4, None, ""),
        ("meta_coh_state", 2, None, ""),
    ]),
    ("extra_meta_t", [              # DCacheExtraMeta：error/prefetch/access 标志阵列读出
        ("error", "tl_error_t", None, ""),
        ("prefetch", 3, None, "该行由哪个预取器带进来"),
        ("access", 1, None, "该行被 demand 访问过"),
    ]),
    ("error_flag_write_bits_t", [
        ("idx", 8, None, ""),
        ("way_en", 4, None, ""),
        ("error", "tl_error_t", None, ""),
    ]),
    ("prefetch_flag_write_bits_t", [
        ("idx", 8, None, ""),
        ("way_en", 4, None, ""),
        ("source", 3, None, ""),
    ]),
    ("access_flag_write_bits_t", [
        ("idx", 8, None, ""),
        ("way_en", 4, None, ""),
        ("flag", 1, None, ""),
    ]),
    ("tag_write_bits_t", [
        ("idx", 8, None, ""),
        ("way_en", 4, None, ""),
        ("tag", 36, None, ""),
    ]),
    ("replace_access_bits_t", [     # 更新替换算法（PLRU）状态
        ("set", 8, None, ""),
        ("way", 2, None, ""),
    ]),
    ("replace_req_bits_t", [        # 本拍要替换出去的块（给 MissQueue 做冲突检查）
        ("addr", 48, None, ""),
        ("vaddr", 50, None, ""),
    ]),
    ("status_bits_t", [
        ("set", 8, None, ""),
        ("way_en", 4, None, ""),
    ]),
    ("stage_status_t", [            # ValidIO(MainPipeStatus)
        ("valid", 1, None, ""),
        ("bits", "status_bits_t", None, ""),
    ]),
    ("status_dup_t", [              # 一份 s1/s2/s3 占用状态（给 load 流水做冲突检查）
        ("s1", "stage_status_t", None, ""),
        ("s2", "stage_status_t", None, ""),
        ("s3", "stage_status_t", None, ""),
    ]),
    ("error_bits_t", [
        ("paddr", 48, None, ""),
        ("report_to_beu", 1, None, "报给总线错误单元（tag/data ECC 错）"),
    ]),
    ("bloom_query_t", [
        ("valid", 1, None, ""),
        ("bits_addr", 12, None, "块地址哈希"),
    ]),
    ("bloom_filter_query_t", [
        ("set", "bloom_query_t", None, "被替换出去的预取行 -> 置位"),
        ("clr", "bloom_query_t", None, "预取行被 demand 用到 -> 清除"),
    ]),
    ("perf_event_t", [
        ("value", 6, None, ""),
    ]),
]

PORTS = [
    ("input", "probe_req_valid", 1, None, "ProbeQueue 的 probe 请求"),
    ("output", "probe_req_ready", 1, None, ""),
    ("input", "probe_req_bits", "probe_req_bits_t", None, ""),
    ("input", "refill_req_valid", 1, None, "MissQueue 的回填请求"),
    ("output", "refill_req_ready", 1, None, ""),
    ("input", "refill_req_bits", "refill_req_bits_t", None, ""),
    ("input", "store_req_valid", 1, None, "Sbuffer 的整行写"),
    ("output", "store_req_ready", 1, None, ""),
    ("input", "store_req_bits", "store_req_bits_t", None, ""),
    ("input", "atomic_req_valid", 1, None, "AtomicsUnit 的 AMO/LR/SC"),
    ("output", "atomic_req_ready", 1, None, ""),
    ("input", "atomic_req_bits", "atomic_req_bits_t", None, ""),
    ("input", "miss_req_ready", 1, None, "-> MissQueue：store/AMO miss"),
    ("output", "miss_req_valid", 1, None, ""),
    ("output", "miss_req_bits", "miss_req_bits_t", None, ""),
    ("output", "wbq_conflict_check_valid", 1, None, "-> WritebackQueue 冲突检查"),
    ("output", "wbq_conflict_check_bits", 48, None, ""),
    ("input", "wbq_block_miss_req", 1, None, ""),
    ("output", "store_replay_resp_valid", 1, None, "-> Sbuffer：store miss/升权失败，要重发"),
    ("output", "store_replay_resp_bits_id", 6, None, ""),
    ("output", "store_hit_resp_valid", 1, None, "-> Sbuffer：store 已写入"),
    ("output", "store_hit_resp_bits_id", 6, None, ""),
    ("output", "atomic_resp_valid", 1, None, "-> AtomicsUnit"),
    ("output", "atomic_resp_bits", "atomic_resp_bits_t", None, ""),
    ("output", "mainpipe_info", "mainpipe_info_t", None, "-> MissQueue"),
    ("input", "refill_info_valid", 1, None, "MissQueue 回填数据"),
    ("input", "refill_info_bits", "refill_info_bits_t", None, ""),
    ("input", "wb_ready", 1, None, "-> WritebackQueue：Release/ProbeAck"),
    ("output", "wb_valid", 1, None, ""),
    ("output", "wb_bits", "wb_bits_t", None, ""),
    ("output", "data_read_intend", 1, None, "data SRAM 读口：s1 读整行"),
    ("input", "data_readline_ready", 1, None, ""),
    ("output", "data_readline_valid", 1, None, ""),
    ("output", "data_readline_bits", "readline_bits_t", None, ""),
    ("output", "data_readline_can_go", 1, None, ""),
    ("output", "data_readline_stall", 1, None, ""),
    ("output", "data_readline_can_resp", 1, None, ""),
    ("input", "data_resp", "data_resp_t", 8, "s3 拿到的读出数据（8 bank）"),
    ("input", "readline_error_delayed", 1, None, "data ECC 错（晚一拍报）"),
    ("output", "data_write_valid", 1, None, "data SRAM 写口：s3 写回"),
    ("output", "data_write_bits", "data_write_bits_t", None, ""),
    ("output", "data_write_dup", "data_write_dup_t", 8, ""),
    ("output", "meta_read_valid", 1, None, "coh meta 读口：s0"),
    ("output", "meta_read_bits_idx", 8, None, ""),
    ("input", "meta_resp", "meta_t", 4, "s1 拿到的 4 路 coh 状态"),
    ("output", "meta_write_valid", 1, None, "coh meta 写口：s3"),
    ("output", "meta_write_bits", "meta_write_bits_t", None, ""),
    ("input", "extra_meta_resp", "extra_meta_t", 4, "s1 拿到的 4 路标志位"),
    ("output", "error_flag_write_valid", 1, None, ""),
    ("output", "error_flag_write_bits", "error_flag_write_bits_t", None, ""),
    ("output", "prefetch_flag_write_valid", 1, None, ""),
    ("output", "prefetch_flag_write_bits", "prefetch_flag_write_bits_t", None, ""),
    ("output", "access_flag_write_valid", 1, None, ""),
    ("output", "access_flag_write_bits", "access_flag_write_bits_t", None, ""),
    ("input", "tag_read_ready", 1, None, "tag SRAM 读口：s0"),
    ("output", "tag_read_valid", 1, None, ""),
    ("output", "tag_read_bits_idx", 8, None, ""),
    ("input", "tag_resp", 43, 4, "s1 拿到的 4 路 tag（带 7 位 SECDED 校验）"),
    ("output", "tag_write_valid", 1, None, "tag SRAM 写口：s3（只有 refill 写 tag）"),
    ("output", "tag_write_bits", "tag_write_bits_t", None, ""),
    ("output", "tag_write_intend", 1, None, ""),
    ("output", "replace_access_valid", 1, None, "替换算法状态更新"),
    ("output", "replace_access_bits", "replace_access_bits_t", None, ""),
    ("output", "replace_way_set_bits", 8, None, "替换算法查询：s1 的 set"),
    ("input", "replace_way_way", 2, None, "替换算法给出的受害路"),
    ("output", "evict_set", 8, None, "-> MissQueue：s2 的 set（查该 set 的 BtoT 路）"),
    ("input", "btot_ways_for_set", 4, None, "该 set 里哪些路正在 BtoT 升权"),
    ("output", "replace_req_bits", "replace_req_bits_t", None, "-> MissQueue：要替换的块"),
    ("input", "replace_block", 1, None, "MissQueue 说这个替换要等"),
    ("output", "sms_agt_evict_req_valid", 1, None, "-> SMS 预取器：有行被替换"),
    ("output", "sms_agt_evict_req_bits_vaddr", 50, None, ""),
    ("output", "status_dup", "status_dup_t", 24, "24 份 s1/s2/s3 状态（扇出复制）"),
    ("output", "lrsc_locked_block_valid", 1, None, "LR 保留集（挡住 probe）"),
    ("output", "lrsc_locked_block_bits", 48, None, ""),
    ("input", "invalid_resv_set", 1, None, "该块被 release，保留集失效"),
    ("output", "update_resv_set", 1, None, ""),
    ("output", "block_lr", 1, None, ""),
    ("output", "error_valid", 1, None, "ECC 错误上报"),
    ("output", "error_bits", "error_bits_t", None, ""),
    ("input", "pseudo_error_valid", 1, None, "错误注入（CtrlUnit）"),
    ("input", "pseudo_error_bits_0_valid", 1, None, ""),
    ("input", "pseudo_error_bits_0_mask", 64, None, ""),
    ("output", "pseudo_tag_error_inj_done", 1, None, ""),
    ("output", "pseudo_data_error_inj_done", 1, None, ""),
    ("output", "bloom_filter_query", "bloom_filter_query_t", None, "-> 预取布隆过滤器"),
    ("output", "perf", "perf_event_t", 4, "性能事件"),
]

TYPE_MAP = {name: fields for name, fields in TYPES}


def golden_ports():
    txt = open(f"{G}/{TOP}.sv").read()
    body = txt[txt.index(f"\nmodule {TOP}(") + 1:]
    head = body[:body.index("\n);")]
    out = []
    for ln in head.splitlines()[1:]:
        m = PORT_RE.match(ln)
        if not m:
            raise SystemExit(f"golden 端口行解析失败: {ln!r}")
        w = int(m.group(2)) - int(m.group(3)) + 1 if m.group(2) else 1
        out.append((m.group(1), w, m.group(4)))
    return out, head + "\n);"


def flatten(gname, path, typ, count):
    """展平一个(可能是数组的)端口/字段：产出 (golden 名, SV 路径, 位宽)。"""
    items = []
    idxs = [None] if count is None else list(range(count))
    for i in idxs:
        g = gname if i is None else f"{gname}_{i}"
        p = path if i is None else f"{path}[{i}]"
        if isinstance(typ, int):
            items.append((g, p, typ))
        else:
            for fname, ftyp, fcnt, _ in TYPE_MAP[typ]:
                items.extend(flatten(f"{g}_{fname}", f"{p}.{fname}", ftyp, fcnt))
    return items


def type_decl(typ, count):
    base = f"logic [{typ-1}:0]" if isinstance(typ, int) and typ > 1 else \
           ("logic" if isinstance(typ, int) else typ)
    if count is None:
        return base
    if isinstance(typ, int):
        return f"logic [{count-1}:0][{typ-1}:0]" if typ > 1 else f"logic [{count-1}:0]"
    return f"{typ} [{count-1}:0]"


def build_map():
    gp, head = golden_ports()
    gdict = {n: (d, w) for d, w, n in gp}
    seen = {}
    rows = []
    for d, name, typ, cnt, _ in PORTS:
        for g, p, w in flatten(f"io_{name}", name, typ, cnt):
            if g in seen:
                raise SystemExit(f"核对 3 失败：{g} 被映射两次")
            if g not in gdict:
                raise SystemExit(f"核对 1 失败：规格展平出 {g}，golden 没有这个端口")
            gd, gw = gdict[g]
            if gd != d or gw != w:
                raise SystemExit(f"核对 2 失败：{g} 规格 {d}[{w}] vs golden {gd}[{gw}]")
            seen[g] = p
            rows.append((d, name, typ, cnt, g, p, w))
    missing = [n for d, w, n in gp if n not in seen and n not in ("clock", "reset")]
    if missing:
        raise SystemExit(f"核对 1 失败：golden 端口未被规格覆盖: {missing[:10]} ... 共 {len(missing)}")
    return gp, head, rows


def gen_io_types():
    L = []
    for name, fields in TYPES:
        L.append("  typedef struct packed {")
        wn = max(len(type_decl(t, c)) for _, t, c, _ in fields)
        for fname, ftyp, fcnt, cmt in fields:
            decl = type_decl(ftyp, fcnt).ljust(wn)
            line = f"    {decl} {fname};"
            if cmt:
                line = line.ljust(48) + f"  // {cmt}"
            L.append(line)
        L.append(f"  }} {name};")
        L.append("")
    return L[:-1]


def gen_core_ports():
    L = ["  input  logic clock,", "  input  logic reset,"]
    for k, (d, name, typ, cnt, cmt) in enumerate(PORTS):
        sep = "," if k < len(PORTS) - 1 else ""
        dd = "input " if d == "input" else "output"
        line = f"  {dd} {type_decl(typ, cnt)} {name}{sep}"
        if cmt:
            line = line.ljust(56) + f"  // {cmt}"
        L.append(line)
    return L


def gen_wrapper(head, rows):
    L = []
    L.append("// golden 同名 wrapper：端口与 G1 golden 逐位同名同序；函数上只做扁平端口 <-> struct")
    L.append("// 的接线（字段路径换算规则见 verif/ut/MainPipe/gen_mainpipe.py），逻辑全在核里。")
    L.append("module MainPipe")
    L.append("  import mainpipe_pkg::*;")
    hl = head.split("\n")[1:]          # 去掉 "module MainPipe(" 行，保留端口行与 ");"
    L.append("(")
    L.extend(hl)
    L.append("")
    struct_ports = [(d, n, t, c) for d, n, t, c, _ in PORTS if not isinstance(t, int) or c is not None]
    for d, n, t, c in struct_ports:
        L.append(f"  {type_decl(t, c)} c_{n};")
    L.append("")
    for d, name, typ, cnt, g, p, w in rows:
        if isinstance(typ, int) and cnt is None:
            continue
        if d == "input":
            L.append(f"  assign c_{p} = {g};")
        else:
            L.append(f"  assign {g} = c_{p};")
    L.append("")
    L.append("  xs_MainPipe_core u_core (")
    conns = ["    .clock(clock)", "    .reset(reset)"]
    for d, n, t, c, _ in PORTS:
        if isinstance(t, int) and c is None:
            conns.append(f"    .{n}(io_{n})")
        else:
            conns.append(f"    .{n}(c_{n})")
    L.append(",\n".join(conns))
    L.append("  );")
    L.append("")
    L.append("endmodule")
    return L


def gen_tb_ports(gp):
    L = []
    for d, w, n in gp:
        r = f"[{w-1}:0] " if w > 1 else ""
        if d == "input":
            if n not in ("clock", "reset"):
                L.append(f"  logic {r}{n};")
        else:
            L.append(f"  wire  {r}g_{n}, i_{n};")
    L.append("")
    for inst, pre, mod in (("u_gold", "g_", TOP), ("u_impl", "i_", TOP + "_xs")):
        L.append(f"  {mod} {inst} (")
        conns = []
        for d, w, n in gp:
            conns.append(f"    .{n}({n if d == 'input' else pre + n})")
        L.append(",\n".join(conns))
        L.append("  );")
    return L


def gen_tb_compare(gp):
    L = ["  task automatic compare_outputs();"]
    for d, w, n in gp:
        if d != "output":
            continue
        L.append(f"    if (g_{n} !== i_{n}) report_mismatch(\"{n}\", {w}'(g_{n}), {w}'(i_{n}));")
    L.append("  endtask")
    return L


def replace_region(text, tag, lines, path):
    b = f"// BEGIN GENERATED({tag})"
    e = "// END GENERATED"
    i = text.find(b)
    if i < 0:
        raise SystemExit(f"{path}: 缺 {b}")
    j = text.find(e, i)
    if j < 0:
        raise SystemExit(f"{path}: {b} 没有配对的 {e}")
    ls = text.rfind("\n", 0, i) + 1
    indent = text[ls:i]
    body = "\n".join(lines)
    return text[:i] + b + "\n" + body + "\n" + indent + text[j:]


def main():
    check = "--check" in sys.argv
    gp, head, rows = build_map()
    jobs = [
        (RTL_FILE, [("io_types", gen_io_types()),
                    ("core_ports", gen_core_ports()),
                    ("wrapper", gen_wrapper(head, rows))]),
        (TB_FILE, [("tb_ports", gen_tb_ports(gp)),
                   ("tb_compare", gen_tb_compare(gp))]),
    ]
    bad = 0
    for path, regions in jobs:
        old = open(path).read()
        new = old
        for tag, lines in regions:
            new = replace_region(new, tag, lines, path)
        if check:
            if new != old:
                print(f"GEN CHECK FAILED: {path} 的生成区与生成器输出不一致")
                bad = 1
        elif new != old:
            open(path, "w").write(new)
            print(f"wrote {path}")
        else:
            print(f"unchanged {path}")
    n_in = sum(1 for d, w, n in gp if d == "input")
    print(f"ports: golden {len(gp)} (in {n_in} / out {len(gp)-n_in})，规格映射 {len(rows)} 个扁平端口")
    if check:
        print("GEN CHECK OK" if not bad else "GEN CHECK FAILED")
    sys.exit(bad)


if __name__ == "__main__":
    main()
