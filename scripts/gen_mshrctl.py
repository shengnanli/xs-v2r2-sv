#!/usr/bin/env python3
"""生成 MSHRCtl (coupledL2 tl2chi L2 缓存 MSHR 控制阵列) 的可读重写核 + wrapper / 变体 / UT。

MSHRCtl = L2 slice 的 MSHR 控制阵列(对应 MSHRCtl.scala, 仅 260 行 Scala):
  * 例化 16 个 MSHR(单条目 miss 处理 FSM, 本工程已单独做透)——本核**黑盒**之;
  * 例化 MSHRSelector(空闲槽优先分配)、SourceB(Probe 上行)、4 个 FastArbiter
    (txreq / txrsp / source_b / mshr_task 下行/主流水仲裁)——均**黑盒**;
  * 真正的"重写"部分 = 控制阵列 glue + 仲裁互联:
      - 容量计数与满判断(mshrFull / a_mshrFull → blockB/blockA)
      - 分配指针(MSHRSelector one-hot → OHToUInt → mshr_alloc_ptr)
      - SinkC(release)按 PA 搜索 MSHR(resp_sinkC_match_vec)
      - 各响应(sinkC/rxrsp/rxdat/replResp/aMergeTask)按 mshrId/PA 路由进对应 MSHR
      - nestedwb 广播 + nestedwbDataId 优先选择
      - releaseBufWriteId 优先选择
      - l2Miss 统计、perf 计数(hpm_timers / lmiss / 2 级流水寄存器)

策略(与 SinkC 一致, 子模块两侧黑盒):
  - xs_MSHRCtl_core : 可读核(generate-for 例化 16 MSHR + 手写 glue), UT impl 侧
  - MSHRCtl_wrapper : golden 同名 MSHRCtl, 例化 xs_MSHRCtl_core —— FM impl 顶层
  - MSHRCtl_xs      : UT 变体顶层, 同样例化 xs_MSHRCtl_core
  - tb.sv           : 双例化 (golden MSHRCtl vs MSHRCtl_xs) 逐拍随机激励, 比对全部输出
  golden MSHR/MSHRSelector/SourceB/FastArbiter_4/5/7/8 在 UT 两侧共享(黑盒积木)。

机械部分(16 个 MSHR 的端口连线、4 个仲裁器实例、输出展平)从 golden 实例**自动派生**
以保证位级一致; glue 逻辑按 Scala 意图手写(可读 + 中文注释)。
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"
UT = ROOT / "verif" / "ut" / "MSHRCtl"

MSHRS = 16

# ----------------------------------------------------------------------------
# 端口/实例解析
# ----------------------------------------------------------------------------
def parse_ports(path, module):
    text = path.read_text()
    m = re.search(rf"module\s+{module}\s*\((.*?)\n\);", text, re.S)
    if not m:
        raise RuntimeError(f"module {module} not found in {path}")
    ports = []
    for raw in m.group(1).splitlines():
        line = raw.split("//", 1)[0].strip().rstrip(",")
        if not line:
            continue
        mm = re.match(r"(input|output)\s+(?:(?:wire|logic|reg)\s+)?(\[[^\]]+\])?\s*([A-Za-z_]\w*)$", line)
        if not mm:
            raise RuntimeError(f"cannot parse port line: {raw}")
        d, w, n = mm.groups()
        ports.append((d, w or "", n))
    return ports


def width_bits(w):
    if not w:
        return 1
    mm = re.match(r"\[(\d+):(\d+)\]", w)
    hi, lo = map(int, mm.groups())
    return abs(hi - lo) + 1


def extract_instance_block(text, header_re):
    """返回从 '  MODULE inst (' 行到匹配 '  );' 的原始文本(含首尾)。"""
    lines = text.splitlines()
    start = None
    for i, ln in enumerate(lines):
        if re.match(header_re, ln):
            start = i
            break
    if start is None:
        raise RuntimeError(f"instance header not found: {header_re}")
    for j in range(start + 1, len(lines)):
        if lines[j].rstrip() == "  );":
            return "\n".join(lines[start:j + 1])
    raise RuntimeError(f"instance close not found for: {header_re}")


def parse_inst_conns(block):
    """解析实例端口连线 → [(port, rhs)], 合并折行 RHS, 处理嵌套括号。"""
    # 去掉头行 'MODULE inst (' 和尾行 ');'
    body = block.split("(", 1)[1]
    body = body.rsplit(");", 1)[0]
    conns = []
    for m in re.finditer(r"\.(\w+)\s*\(", body):
        name = m.group(1)
        depth = 0
        j = m.end() - 1
        while j < len(body):
            c = body[j]
            if c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
                if depth == 0:
                    break
            j += 1
        rhs = body[m.end():j].strip()
        rhs = re.sub(r"\s+", " ", rhs)
        conns.append((name, rhs))
    return conns


# ----------------------------------------------------------------------------
# 每实例(per-MSHR)特殊输入表达式(占位 %I = genvar i)
# ----------------------------------------------------------------------------
def special_in_expr(port):
    table = {
        "io_alloc_valid":
            "mshrAllocOH[%I]",
        "io_resps_sinkC_valid":
            "(io_resps_sinkC_valid & resp_sinkC_match_vec[%I])",
        "io_resps_rxrsp_valid":
            "(m_io_status_valid[%I] & io_resps_rxrsp_valid & (io_resps_rxrsp_mshrId == 8'(%I)))",
        "io_resps_rxdat_valid":
            "(m_io_status_valid[%I] & io_resps_rxdat_valid & (io_resps_rxdat_mshrId == 8'(%I)))",
        "io_aMergeTask_valid":
            "(io_aMergeTask_valid & (io_aMergeTask_bits_id == 8'(%I)))",
        "io_replResp_valid":
            "(io_replResp_valid & (io_replResp_bits_mshrId == 8'(%I)))",
        "io_pCrd_grant":
            "io_pCrd_grant_arr[%I]",
        "io_tasks_txreq_ready":
            "txreq_arb_in_ready[%I]",
        "io_tasks_txrsp_ready":
            "txrsp_arb_in_ready[%I]",
        "io_tasks_source_b_ready":
            "source_b_arb_in_ready[%I]",
        "io_tasks_mainpipe_ready":
            "mshr_task_arb_in_ready[%I]",
    }
    return table.get(port)


# 仲裁器/选择器实例文本里把 golden 扁平名替换为可读数组名
def rewrite_subinst(block):
    # 仲裁器 io_in_<n>_ready (输出, 回灌给 MSHR 的 ready) → <arb>_in_ready[<n>]
    block = re.sub(r"_(txreq_arb|txrsp_arb|source_b_arb|mshr_task_arb)_io_in_(\d+)_ready",
                   r"\1_in_ready[\2]", block)
    # MSHR 的输出线 _mshrs_<n>_io_<x> → m_io_<x>[<n>]
    block = re.sub(r"_mshrs_(\d+)_io_(\w+)", r"m_io_\2[\1]", block)
    # MSHRSelector 输出
    block = block.replace("_mshrSelector_io_out_bits", "mshrSelector_out_bits")
    return block


# ----------------------------------------------------------------------------
# 主生成
# ----------------------------------------------------------------------------
def main():
    UT.mkdir(parents=True, exist_ok=True)
    ctl_text = (GOLDEN / "MSHRCtl.sv").read_text()
    ctl_ports = parse_ports(GOLDEN / "MSHRCtl.sv", "MSHRCtl")
    mshr_ports = parse_ports(GOLDEN / "MSHR.sv", "MSHR")
    mshr_dir = {n: d for d, w, n in mshr_ports}
    mshr_w = {n: w for d, w, n in mshr_ports}

    # mshrs_0 / mshrs_1 实例连线
    blk0 = extract_instance_block(ctl_text, r"^  MSHR mshrs_0 \(")
    blk1 = extract_instance_block(ctl_text, r"^  MSHR mshrs_1 \(")
    c0 = dict(parse_inst_conns(blk0))
    c1 = dict(parse_inst_conns(blk1))

    # ---- 分类每个 MSHR 端口 ----
    out_ports = []         # MSHR 输出 → 数组 m_<name>
    flat_out = []          # (mshrctl_grp, rest, mshr_port) 需展平到 io_<grp>_<i>_<rest>
    for d, w, n in mshr_ports:
        if n in ("clock", "reset"):
            continue
        if n == "io_id":
            continue
        if special_in_expr(n) is not None:
            continue
        if d == "input":
            assert c0[n] == c1[n], f"input {n} not broadcast: {c0[n]} vs {c1[n]}"
            continue
        # output
        out_ports.append((w, n))
        rhs0 = c0[n]
        mm = re.match(r"^(io_[A-Za-z]+)_(\d+)_(.+)$", rhs0)
        if mm and mm.group(2) == "0":
            flat_out.append((mm.group(1), mm.group(3), n))

    # ---- 组装 core ----
    L = []
    L.append("// 自动生成 scripts/gen_mshrctl.py —— 勿手改")
    L.append("// xs_MSHRCtl_core: L2 MSHR 控制阵列可读重写核(16 个 MSHR 黑盒 + 手写 glue/仲裁互联)")
    L.append("`timescale 1ns/1ps")
    # ---- module header (与 golden MSHRCtl 同端口) ----
    body = ",\n".join(
        f"  {d} {w}{' ' if w else ''}{n}" for d, w, n in ctl_ports)
    L.append(f"module xs_MSHRCtl_core(\n{body}\n);")
    L.append("")
    L.append("  localparam int MSHRS = 16;")
    L.append("")

    # ---- 内部数组声明: 16 个 MSHR 的输出 ----
    L.append("  // ===== 16 个 MSHR 的输出(数组), 经展平/glue 使用 =====")
    for w, n in out_ports:
        L.append(f"  wire {w}{' ' if w else ''}m_{n} [MSHRS];")
    L.append("")
    L.append("  // pCrd 授权输入去扁平 / 仲裁器回灌 ready / 选择器·SourceB 互联线")
    L.append("  logic io_pCrd_grant_arr [MSHRS];")
    L.append("  wire  txreq_arb_in_ready    [MSHRS];")
    L.append("  wire  txrsp_arb_in_ready    [MSHRS];")
    L.append("  wire  source_b_arb_in_ready [MSHRS];")
    L.append("  wire  mshr_task_arb_in_ready[MSHRS];")
    L.append("  wire [15:0] mshrSelector_out_bits;")
    L.append("  wire        _source_b_arb_io_out_valid;")
    L.append("  wire [30:0] _source_b_arb_io_out_bits_tag;")
    L.append("  wire [8:0]  _source_b_arb_io_out_bits_set;")
    L.append("  wire [2:0]  _source_b_arb_io_out_bits_opcode;")
    L.append("  wire [1:0]  _source_b_arb_io_out_bits_param;")
    L.append("  wire [1:0]  _source_b_arb_io_out_bits_alias;")
    L.append("  wire        _sourceB_io_task_ready;")
    L.append("")

    # ---- 组合函数 ----
    L.append("  // 16 路 one-hot → 4bit 下标(OHToUInt)")
    L.append("  function automatic [3:0] f_oh16_to_uint(input [15:0] oh);")
    L.append("    f_oh16_to_uint[0] = oh[1]|oh[3]|oh[5]|oh[7]|oh[9]|oh[11]|oh[13]|oh[15];")
    L.append("    f_oh16_to_uint[1] = oh[2]|oh[3]|oh[6]|oh[7]|oh[10]|oh[11]|oh[14]|oh[15];")
    L.append("    f_oh16_to_uint[2] = oh[4]|oh[5]|oh[6]|oh[7]|oh[12]|oh[13]|oh[14]|oh[15];")
    L.append("    f_oh16_to_uint[3] = oh[8]|oh[9]|oh[10]|oh[11]|oh[12]|oh[13]|oh[14]|oh[15];")
    L.append("  endfunction")
    L.append("  // 16 路向量优先选择(最低置位下标; 全 0 → 15, 与 ParallelPriorityMux 末项一致)")
    L.append("  function automatic [3:0] f_pri16(input [15:0] sel);")
    L.append("    f_pri16 = 4'd15;")
    L.append("    for (int k = 15; k >= 0; k = k - 1) if (sel[k]) f_pri16 = k[3:0];")
    L.append("  endfunction")
    L.append("")

    # ---- 分配 one-hot ----
    L.append("  // ===== 分配: 空闲槽 one-hot & 有效 alloc 请求 =====")
    L.append("  wire [15:0] mshrAllocOH =")
    L.append("    mshrSelector_out_bits & {16{io_fromMainPipe_mshr_alloc_s3_valid}};")
    L.append("")

    # ---- resp_sinkC_match_vec ----
    L.append("  // ===== SinkC(release) 按 PA 搜索 MSHR: set 相等 & tag 相等(needsRepl 选 metaTag) =====")
    L.append("  logic [15:0] resp_sinkC_match_vec;")
    L.append("  always_comb")
    L.append("    for (int k = 0; k < MSHRS; k++)")
    L.append("      resp_sinkC_match_vec[k] =")
    L.append("        m_io_status_valid[k] & m_io_status_bits_w_c_resp[k]")
    L.append("        & (io_resps_sinkC_set == m_io_status_bits_set[k])")
    L.append("        & (io_resps_sinkC_tag == (m_io_status_bits_needsRepl[k]")
    L.append("                                   ? m_io_status_bits_metaTag[k]")
    L.append("                                   : m_io_status_bits_reqTag[k]));")
    L.append("")

    # ---- generate MSHR ----
    L.append("  // ===== 16 个 MSHR 例化(黑盒): 广播输入直连, 每实例输入按 mshrId/PA 路由, 输出入数组 =====")
    L.append("  genvar i;")
    L.append("  generate for (i = 0; i < MSHRS; i = i + 1) begin : g_mshr")
    L.append("    MSHR mshrs (")
    conn_lines = []
    for d, w, n in mshr_ports:
        if n == "clock":
            rhs = "clock"
        elif n == "reset":
            rhs = "reset"
        elif n == "io_id":
            rhs = "8'(i)"
        elif special_in_expr(n) is not None:
            rhs = special_in_expr(n).replace("%I", "i")
        elif d == "input":
            rhs = c0[n]            # 广播: golden mshrs_0 的 RHS 即 MSHRCtl 输入端口
        else:
            rhs = f"m_{n}[i]"
        conn_lines.append((n, rhs))
    for k, (n, rhs) in enumerate(conn_lines):
        comma = "," if k + 1 < len(conn_lines) else ""
        L.append(f"      .{n}({rhs}){comma}")
    L.append("    );")
    L.append("  end endgenerate")
    L.append("")

    # ---- pCrd grant 去扁平 ----
    L.append("  // pCrd 授权输入: 扁平端口 → 数组")
    for n in range(MSHRS):
        L.append(f"  assign io_pCrd_grant_arr[{n}] = io_pCrd_{n}_grant;")
    L.append("")

    # ---- 子模块实例(选择器/仲裁器/SourceB), 从 golden 重写 ----
    L.append("  // ===== 选择器 / 仲裁器 / SourceB 例化(黑盒, 连线从 golden 派生) =====")
    for hdr in (r"^  MSHRSelector mshrSelector \(",
                r"^  FastArbiter_4 txreq_arb \(",
                r"^  FastArbiter_5 txrsp_arb \(",
                r"^  SourceB sourceB \(",
                r"^  FastArbiter_7 source_b_arb \(",
                r"^  FastArbiter_8 mshr_task_arb \("):
        blk = extract_instance_block(ctl_text, hdr)
        L.append(rewrite_subinst(blk))
        L.append("")

    # ---- 容量计数 / 满判断 ----
    L.append("  // ===== 容量计数: 在途流水请求(s2/s3) + 已占用 MSHR 数 =====")
    L.append("  logic [4:0] occTotal;")
    L.append("  always_comb begin")
    L.append("    occTotal = 5'd0;")
    L.append("    occTotal += 5'(io_pipeStatusVec_0_valid);")
    L.append("    occTotal += 5'(io_pipeStatusVec_1_valid);")
    L.append("    for (int k = 0; k < MSHRS; k++) occTotal += 5'(m_io_status_valid[k]);")
    L.append("  end")
    L.append("  wire mshrFull   = occTotal[4];        // >= 16: 阻塞 SinkB")
    L.append("  wire a_mshrFull = occTotal > 5'hE;    // >= 15: 留 1 槽给 SinkB, 阻塞 SinkA")
    L.append("  assign io_toReqArb_blockA_s1 = a_mshrFull;")
    L.append("  assign io_toReqArb_blockB_s1 = mshrFull;")
    L.append("")

    # ---- 分配指针 ----
    L.append("  // ===== 分配指针 → MainPipe(one-hot 转下标, 高位补 0 至 8bit) =====")
    L.append("  assign io_toMainPipe_mshr_alloc_ptr = {4'h0, f_oh16_to_uint(mshrSelector_out_bits)};")
    L.append("")

    # ---- releaseBufWriteId ----
    L.append("  // ===== releaseBuf 写入 MSHR id(SinkC 命中槽优先选择) =====")
    L.append("  assign io_releaseBufWriteId = {4'h0, f_pri16(resp_sinkC_match_vec)};")
    L.append("")

    # ---- nestedwbDataId ----
    L.append("  // ===== 嵌套回写数据 id: 各 MSHR nestedwbData 优先选择 =====")
    L.append("  wire [15:0] nestedwb_vec = {")
    L.append("    " + ", ".join(f"m_io_nestedwbData[{n}]" for n in range(MSHRS - 1, -1, -1)) + "};")
    L.append("  assign io_nestedwbDataId_valid = |nestedwb_vec;")
    L.append("  assign io_nestedwbDataId_bits  = {4'h0, f_pri16(nestedwb_vec)};")
    L.append("")

    # ---- l2Miss ----
    L.append("  // ===== l2Miss(TopDown): 任一 MSHR 处理 channel A 的 CPU load/store miss =====")
    L.append("  logic l2miss_r;")
    L.append("  always_comb begin")
    L.append("    l2miss_r = 1'b0;")
    L.append("    for (int k = 0; k < MSHRS; k++)")
    L.append("      l2miss_r |= m_io_status_valid[k] & m_io_status_bits_channel[k][0]")
    L.append("                  & (m_io_status_bits_reqSource[k] == 5'h2")
    L.append("                     | m_io_status_bits_reqSource[k] == 5'h3);")
    L.append("  end")
    L.append("  assign io_l2Miss = l2miss_r;")
    L.append("")

    # ---- perf ----
    L.append("  // ===== 性能计数: hpm_timers(每槽自占用起计时) + lmiss(>200 拍长 miss) =====")
    L.append("  reg [9:0] hpm_timers [MSHRS];")
    L.append("  always @(posedge clock or posedge reset)")
    L.append("    if (reset)")
    L.append("      for (int k = 0; k < MSHRS; k++) hpm_timers[k] <= 10'h0;")
    L.append("    else")
    L.append("      for (int k = 0; k < MSHRS; k++)")
    L.append("        hpm_timers[k] <= mshrAllocOH[k] ? 10'h1 : 10'(hpm_timers[k] + 10'h1);")
    L.append("  logic [3:0] lmiss_sum;")
    L.append("  always_comb begin")
    L.append("    lmiss_sum = 4'd0;")
    L.append("    for (int k = 0; k < MSHRS; k++)")
    L.append("      lmiss_sum += 4'(m_io_status_valid[k] & m_io_status_bits_will_free[k]")
    L.append("                      & (hpm_timers[k] > 10'hC8));")
    L.append("  end")
    L.append("  wire perf_refill = io_resps_rxdat_valid & io_resps_rxdat_respInfo_last;")
    L.append("  reg       perf01_s1, perf01_s2;")
    L.append("  reg [3:0] perf3_s1, perf3_s2;")
    L.append("  always @(posedge clock) begin")
    L.append("    perf01_s1 <= perf_refill; perf01_s2 <= perf01_s1;")
    L.append("    perf3_s1  <= lmiss_sum;   perf3_s2  <= perf3_s1;")
    L.append("  end")
    L.append("  assign io_perf_0_value = {5'h0, perf01_s2};  // l2_cache_refill")
    L.append("  assign io_perf_1_value = {5'h0, perf01_s2};  // l2_cache_rd_refill")
    L.append("  assign io_perf_3_value = {2'h0, perf3_s2};   // l2_cache_long_miss")
    L.append("")

    # ---- 输出展平: 数组 → 扁平端口 ----
    L.append("  // ===== 输出展平: 内部数组 → golden 扁平端口 =====")
    for grp, rest, port in flat_out:
        for n in range(MSHRS):
            L.append(f"  assign {grp}_{n}_{rest} = m_{port}[{n}];")
    # msStatus 的 valid/channel/set/reqTag 来自 status 输出(golden 末尾直连)
    L.append("  // msStatus 的 valid/channel/set/reqTag 取自各 MSHR status 输出")
    for n in range(MSHRS):
        L.append(f"  assign io_msStatus_{n}_valid       = m_io_status_valid[{n}];")
        L.append(f"  assign io_msStatus_{n}_bits_channel = m_io_status_bits_channel[{n}];")
        L.append(f"  assign io_msStatus_{n}_bits_set     = m_io_status_bits_set[{n}];")
        L.append(f"  assign io_msStatus_{n}_bits_reqTag  = m_io_status_bits_reqTag[{n}];")
    L.append("")
    L.append("endmodule")
    L.append("")
    (RTL / "MSHRCtl.sv").write_text("\n".join(L))

    # ---- wrapper / variant ----
    def module_header(name):
        b = ",\n".join(f"  {d} {w}{' ' if w else ''}{n}" for d, w, n in ctl_ports)
        return f"module {name}(\n{b}\n);\n"

    def inst(module, name):
        ls = [f"  {module} {name} ("]
        for k, (_, _, p) in enumerate(ctl_ports):
            comma = "," if k + 1 < len(ctl_ports) else ""
            ls.append(f"    .{p}({p}){comma}")
        ls.append("  );")
        return "\n".join(ls)

    (RTL / "MSHRCtl_wrapper.sv").write_text(
        "// 自动生成 scripts/gen_mshrctl.py —— 勿手改\n"
        + module_header("MSHRCtl") + inst("xs_MSHRCtl_core", "u_core") + "\nendmodule\n")
    (UT / "variants_xs.sv").write_text(
        "// 自动生成 scripts/gen_mshrctl.py —— 勿手改\n"
        + module_header("MSHRCtl_xs") + inst("xs_MSHRCtl_core", "u_core") + "\nendmodule\n")

    # ---- tb ----
    (UT / "tb.sv").write_text(gen_tb(ctl_ports))

    # ---- Makefile ----
    (UT / "Makefile").write_text(
        """MODULE = MSHRCtl

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/MSHRCtl.sv
WRAPPER_SRCS = $(RTL_DIR)/uncore/MSHRCtl_wrapper.sv

# UT 双例化两侧共享的 golden 黑盒积木: MSHR / 选择器 / SourceB / 4 个仲裁器
GOLDEN_SRCS = $(GOLDEN_RTL)/MSHRCtl.sv \\
              $(GOLDEN_RTL)/MSHR.sv \\
              $(GOLDEN_RTL)/MSHRSelector.sv \\
              $(GOLDEN_RTL)/SourceB.sv \\
              $(GOLDEN_RTL)/FastArbiter_6.sv \\
              $(GOLDEN_RTL)/FastArbiter_4.sv \\
              $(GOLDEN_RTL)/FastArbiter_5.sv \\
              $(GOLDEN_RTL)/FastArbiter_7.sv \\
              $(GOLDEN_RTL)/FastArbiter_8.sv

TB_SRCS = variants_xs.sv tb.sv

# FM: ref 仅给 golden MSHRCtl 本体, 子模块两侧均黑盒
FM_VARIANTS = MSHRCtl
FM_REF_DEPS_MSHRCtl =

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random +incdir+$(RTL_DIR)/uncore
SIM_ARGS += +vcs+initreg+0
""")
    print("generated MSHRCtl core/wrapper/variant/tb/Makefile;",
          len(ctl_ports), "ctl ports;", len(out_ports), "mshr out arrays;",
          len(flat_out), "flat-out groups")


def gen_tb(ctl_ports):
    ins = [p for p in ctl_ports if p[0] == "input" and p[2] not in ("clock", "reset")]
    outs = [p for p in ctl_ports if p[0] == "output"]
    L = []
    L.append("// 自动生成 scripts/gen_mshrctl.py —— 勿手改")
    L.append("// MSHRCtl 双例化逐拍比对: golden MSHRCtl vs 可读重写 MSHRCtl_xs。")
    L.append("// 子 MSHR/仲裁器为两侧共享的 golden 黑盒, 故比对聚焦控制阵列 glue + 路由/仲裁互联。")
    L.append("`timescale 1ns/1ps")
    L.append("`define CHK(SIG) begin \\")
    L.append("  if (!$isunknown(g_``SIG)) begin \\")
    L.append("    checks++; \\")
    L.append("    if (g_``SIG !== i_``SIG) begin \\")
    L.append("      errors++; \\")
    L.append("      if (errors <= 40) $display(\"[%0t] MISMATCH %s g=%0h i=%0h\", $time, `\"SIG`\", g_``SIG, i_``SIG); \\")
    L.append("    end \\")
    L.append("  end \\")
    L.append("end")
    L.append("module tb;")
    L.append("  int unsigned NCYCLES = 200000;")
    L.append("  bit clock = 0; bit reset; int errors = 0; int checks = 0;")
    L.append("  always #5 clock = ~clock;")
    for _, w, n in ins:
        L.append(f"  logic {w}{' ' if w else ''}{n};")
    for _, w, n in outs:
        L.append(f"  wire {w}{' ' if w else ''}g_{n};")
        L.append(f"  wire {w}{' ' if w else ''}i_{n};")
    L.append("")
    for top, pfx in (("MSHRCtl", "g_"), ("MSHRCtl_xs", "i_")):
        L.append(f"  {top} u_{pfx[0]} (")
        for k, (d, _, n) in enumerate(ctl_ports):
            comma = "," if k + 1 < len(ctl_ports) else ""
            if n in ("clock", "reset"):
                sig = n
            elif d == "input":
                sig = n
            else:
                sig = f"{pfx}{n}"
            L.append(f"    .{n}({sig}){comma}")
        L.append("  );")
    L.append("")
    # 随机驱动
    L.append("  task automatic drive_random();")
    for _, w, n in ins:
        nb = width_bits(w)
        if n.endswith("_ready"):
            L.append(f"    {n} = ($urandom_range(0,3) != 0);")
        elif n in ("io_fromMainPipe_mshr_alloc_s3_valid",):
            L.append(f"    {n} = ($urandom_range(0,3) == 0);")
        elif n in ("io_resps_sinkC_valid", "io_resps_rxrsp_valid", "io_resps_rxdat_valid",
                   "io_replResp_valid", "io_aMergeTask_valid",
                   "io_nestedwb_c_set_dirty", "io_nestedwb_c_set_tip",
                   "io_nestedwb_b_inv_dirty", "io_nestedwb_b_toB",
                   "io_nestedwb_b_toN", "io_nestedwb_b_toClean",
                   "io_pipeStatusVec_0_valid", "io_pipeStatusVec_1_valid"):
            L.append(f"    {n} = ($urandom_range(0,3) == 0);")
        elif n.endswith("_grant"):
            L.append(f"    {n} = ($urandom_range(0,3) == 0);")
        elif n in ("io_resps_rxrsp_mshrId", "io_resps_rxdat_mshrId",
                   "io_aMergeTask_bits_id", "io_replResp_bits_mshrId"):
            # mshrId 偏向 0..15 以命中 MSHR
            L.append(f"    {n} = 8'($urandom_range(0,15));")
        elif nb <= 32:
            L.append(f"    {n} = $urandom;")
        else:
            words = (nb + 31) // 32
            cat = ", ".join(["$urandom"] * words)
            L.append(f"    {n} = {{{cat}}};")
    L.append("  endtask")
    L.append("")
    L.append("  task automatic check_outputs();")
    for _, _, n in outs:
        L.append(f"    `CHK({n})")
    L.append("  endtask")
    L.append("")
    # 内部探针: golden 的 glue 与本核同义信号(显式映射, 名字不同)
    L.append("  // 内部探针: golden 控制 glue vs 可读核(名字不同, 显式映射)")
    L.append("  int ierr = 0;")
    L.append("  task automatic check_internal();")
    L.append("    if (!$isunknown(u_g.mshrFull_probe) &&")
    L.append("        u_g.mshrFull_probe !== u_i.u_core.mshrFull) begin")
    L.append("      ierr++; if (ierr<=20) $display(\"[%0t] IPROBE mshrFull g=%0h i=%0h\", $time, u_g.mshrFull_probe, u_i.u_core.mshrFull); end")
    L.append("    if (!$isunknown(u_g.a_mshrFull_probe) &&")
    L.append("        u_g.a_mshrFull_probe !== u_i.u_core.a_mshrFull) begin")
    L.append("      ierr++; if (ierr<=20) $display(\"[%0t] IPROBE a_mshrFull g=%0h i=%0h\", $time, u_g.a_mshrFull_probe, u_i.u_core.a_mshrFull); end")
    L.append("    if (!$isunknown(u_g._mshrSelector_io_out_bits) &&")
    L.append("        u_g._mshrSelector_io_out_bits !== u_i.u_core.mshrSelector_out_bits) begin")
    L.append("      ierr++; if (ierr<=20) $display(\"[%0t] IPROBE selOH g=%0h i=%0h\", $time, u_g._mshrSelector_io_out_bits, u_i.u_core.mshrSelector_out_bits); end")
    L.append("  endtask")
    L.append("")
    L.append("  initial begin")
    L.append("    if ($value$plusargs(\"NCYCLES=%d\", NCYCLES)) begin end")
    L.append("    reset = 1'b1;")
    for _, _, n in ins:
        L.append(f"    {n} = '0;")
    L.append("    repeat (5) @(posedge clock);")
    L.append("    reset = 1'b0;")
    L.append("    repeat (NCYCLES) begin")
    L.append("      @(negedge clock);")
    L.append("      drive_random();")
    L.append("      #1 check_outputs();")
    L.append("      check_internal();")
    L.append("      @(posedge clock);")
    L.append("    end")
    L.append("    $display(\"MSHRCtl checks=%0d errors=%0d ierr=%0d\", checks, errors, ierr);")
    L.append("    if (errors == 0 && ierr == 0) begin $display(\"TEST PASSED\"); $finish; end")
    L.append("    $display(\"TEST FAILED\"); $fatal(1);")
    L.append("  end")
    L.append("endmodule")
    L.append("`undef CHK")
    L.append("")
    return "\n".join(L)


if __name__ == "__main__":
    main()
