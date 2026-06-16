#!/usr/bin/env python3
"""
StoreQueue 生成器。

StoreQueue 是 store 顺序队列：dispatch 入队、地址/数据分别就绪、ROB 提交、
出队写回 Sbuffer、mmio/nc/cmo uncache store、向 load 提供 forward。可读核
xs_StoreQueue_core 手写**控制逻辑**（指针推进 / entry 状态机 / enq/commit/deq
仲裁 / forward mask / mmio·nc·cmo FSM），并把数据存储子模块黑盒例化：
  · SQDataModule           （data/mask 存储 + forward 数据 CAM）
  · SQAddrModule           （paddr 存储 + forward 地址 CAM）
  · SQAddrModule_1         （vaddr 存储 + forward 地址 CAM）
  · DatamoduleResultBuffer （dataBuffer：出队到 Sbuffer 的 2 项结果缓冲）
  · StoreExceptionBuffer   （异常地址选最老 store）

本脚本只做**机械的端口/适配生成**，不含微架构逻辑（逻辑全在手写 .sv）：
  1. 解析 golden/chisel-rtl/StoreQueue.sv 顶层端口表 → rtl/memblock/storequeue_ports.svh
     （被可读核 include；与 golden StoreQueue 完全同名同序的扁平端口）。
  2. 解析 golden 里 5 个子模块实例的端口连接表，把连接对象改接到可读核内手写的
     readable 网（核内统一命名前缀），其余 clock/reset 直通 → storequeue_subinst.svh。
     注意：连接值里的 golden 内部网名（_GEN_*/_T_*）一律替换为核内手写网名，
     使可读核不出现生成痕迹。这些替换由「子模块端口 → 核内网名」映射表 PORTMAP 决定。
  3. 生成 golden 同名 wrapper（FM/ST 用，→ 可读核 + 黑盒子模块）。
  4. 生成黑盒 stub sq_blackbox.sv（仅 FM 单独跑时用；UT 用真实 golden 子模块）。
  5. 生成 UT 镜像 variants_xs.sv 与逐拍随机比对 tb.sv。

可读核本体（手写、含全部控制逻辑）见 rtl/memblock/StoreQueue.sv，类型见 storequeue_pkg.sv。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
RTL = XSSV / "rtl/memblock"
GSV = (GOLDEN / "StoreQueue.sv").read_text()
LINES = GSV.splitlines()
HDR = "// 自动生成：scripts/gen_storequeue.py —— 勿手改\n"


# ----------------------------------------------------------------------------
# 顶层端口解析
# ----------------------------------------------------------------------------
def top_ports():
    m = re.search(r"^module StoreQueue\((.*?)\n\);", GSV, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return res


# ----------------------------------------------------------------------------
# 子模块实例连接表解析
# ----------------------------------------------------------------------------
def inst_conns(head_re):
    start = next(i for i, l in enumerate(LINES) if re.match(head_re, l))
    i = start + 1
    raw = []
    while not re.match(r"^  \);", LINES[i]):
        raw.append(LINES[i])
        i += 1
    res, cur = [], None
    for l in raw:
        m = re.match(r"^\s*\.(\w+)\s*(.*)$", l)
        if m and (m.group(2).strip() == "" or m.group(2).strip().startswith("(")):
            if cur:
                res.append(cur)
            cur = [m.group(1), m.group(2).strip()]
        else:
            cur[1] += " " + l.strip()
    if cur:
        res.append(cur)
    return [(p, re.sub(r"\s+", " ", v).strip().rstrip(",")) for p, v in res]


def unwrap(v):
    v = v.strip()
    while v.startswith("(") and v.endswith(")"):
        # 仅当整体是一对匹配括号才去
        depth = 0
        ok = True
        for k, c in enumerate(v):
            if c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
                if depth == 0 and k != len(v) - 1:
                    ok = False
                    break
        if ok:
            v = v[1:-1].strip()
        else:
            break
    return v


# ----------------------------------------------------------------------------
# 子模块例化：把每个子模块端口接到核内手写 readable 网。
# 直通的（顶层端口直连子模块、与逻辑无关）保留 golden 连接值（去括号后即顶层端口名）。
# 被逻辑驱动 / 读出的端口接到核内统一命名的 readable 网（前缀见各 emit）。
# ----------------------------------------------------------------------------

# 核内 readable 网命名约定（手写 .sv 里同名声明 / 驱动）：
#   data 子模块：sd_*    paddr：pa_*    vaddr：va_*    dataBuffer：db_*    excBuf：eb_*
# 这些网由手写控制逻辑产生（写口 wen/waddr/wdata、读口 rdata、forward 命中等）。

def conn_data(port, val):
    # 直通顶层（写数据 wdata 含 genVWdata 组合在手写里算好 → sd_wdata_i）
    PASS = {
        "clock": "clock", "reset": "reset",
        "io_data_wen_0": "sd_data_wen[0]", "io_data_wen_1": "sd_data_wen[1]",
        "io_data_waddr_0": "io_storeDataIn_0_bits_uop_sqIdx_value",
        "io_data_waddr_1": "io_storeDataIn_1_bits_uop_sqIdx_value",
        "io_data_wdata_0": "sd_data_wdata[0]", "io_data_wdata_1": "sd_data_wdata[1]",
        "io_mask_wen_0": "io_storeMaskIn_0_valid", "io_mask_wen_1": "io_storeMaskIn_1_valid",
        "io_mask_waddr_0": "io_storeMaskIn_0_bits_sqIdx_value",
        "io_mask_waddr_1": "io_storeMaskIn_1_bits_sqIdx_value",
        "io_mask_wdata_0": "io_storeMaskIn_0_bits_mask",
        "io_mask_wdata_1": "io_storeMaskIn_1_bits_mask",
        "io_raddr_0": "sq_rdata_raddr[0]", "io_raddr_1": "sq_rdata_raddr[1]",
    }
    if port in PASS:
        return PASS[port]
    # 读出 data/mask → 核内网
    m = re.match(r"^io_rdata_(\d)_(mask|data)$", port)
    if m:
        return f"sd_rdata_{m.group(2)}[{m.group(1)}]"
    # needForward：核内算好的 forward 命中候选（每路 2 段，56 位）
    m = re.match(r"^io_needForward_(\d)_(\d)$", port)
    if m:
        return f"sd_need_forward_{m.group(1)}_{m.group(2)}"
    # forwardMask/forwardMaskFast/forwardData → 核内网（再拆 bit 接顶层）
    m = re.match(r"^io_(forwardMask|forwardMaskFast)_(\d)_(\d+)$", port)
    if m:
        return f"sd_{m.group(1)}[{m.group(2)}][{m.group(3)}]"
    m = re.match(r"^io_forwardData_(\d)_(\d+)$", port)
    if m:
        return f"sd_forwardData[{m.group(1)}][{m.group(2)}]"
    return None


def conn_addr(prefix, port, val):
    # prefix: "pa"(paddr) / "va"(vaddr)
    PASS = {
        "clock": "clock", "reset": "reset",
        "io_raddr_0": "sq_rdata_raddr[0]", "io_raddr_1": "sq_rdata_raddr[1]",
        f"io_wen_0": f"{prefix}_wen[0]", f"io_wen_1": f"{prefix}_wen[1]",
    }
    if port in PASS:
        return PASS[port]
    m = re.match(r"^io_rdata_(\d)$", port)
    if m:
        return f"{prefix}_rdata[{m.group(1)}]"
    m = re.match(r"^io_rlineflag_(\d)$", port)
    if m:
        return f"{prefix}_rlineflag[{m.group(1)}]"
    m = re.match(r"^io_w(addr|data|mask|lineflag)_(\d)$", port)
    if m:
        # 写地址/数据/掩码/行标志：来自 storeAddrIn（直通顶层）
        which, idx = m.group(1), m.group(2)
        src = {"addr": "bits_uop_sqIdx_value" if False else None}
        # 直接照搬 golden 连接值（顶层端口），它本就是 io_storeAddrIn_* 直连
        return None
    m = re.match(r"^io_forwardMdata_(\d)$", port)
    if m:
        return None  # 直通顶层 io_forward_i_paddr/vaddr
    m = re.match(r"^io_forwardDataMask_(\d)$", port)
    if m:
        return None  # 直通顶层 io_forward_i_mask
    m = re.match(r"^io_forwardMmask_(\d)_(\d+)$", port)
    if m:
        return f"{prefix}_forwardMmask[{m.group(1)}][{m.group(2)}]"
    return None


def conn_db(port, val):
    PASS = {"clock": "clock", "reset": "reset"}
    if port in PASS:
        return PASS[port]
    # enq 侧：核内手写算好的 dataBuffer 入队 payload（含非对齐拆分）
    m = re.match(r"^io_enq_(\d)_ready$", port)
    if m:
        return f"db_enq_ready[{m.group(1)}]"
    m = re.match(r"^io_enq_(\d)_(valid|bits_addr|bits_vaddr|bits_data|bits_mask|bits_wline|bits_sqPtr_value|bits_vecValid|bits_sqNeedDeq)$", port)
    if m:
        return f"db_enq_{m.group(1)}_{m.group(2)}"
    # deq 侧：直通顶层 io_sbuffer_*（ready 来自顶层，valid/bits 出顶层）
    if port == "io_deq_0_ready":
        return "io_sbuffer_0_ready"
    if port == "io_deq_1_ready":
        return "io_sbuffer_1_ready"
    m = re.match(r"^io_deq_(\d)_(valid|bits_addr|bits_vaddr|bits_data|bits_mask|bits_wline|bits_sqPtr_value|bits_vecValid|bits_sqNeedDeq)$", port)
    if m:
        return f"db_deq_{m.group(1)}_{m.group(2)}"
    return None


def conn_exc(port, val):
    if port in ("clock", "reset"):
        return port
    # 异常地址输出 → 核内网（再接顶层 io_exceptionAddr_*）
    m = re.match(r"^io_exceptionAddr_(\w+)$", port)
    if m:
        return f"eb_exc_{m.group(1)}"
    # redirect 直通顶层
    if port.startswith("io_redirect_"):
        return None
    # storeAddrIn_* 入队：核内手写算好（valid/bits）→ eb_in_*
    m = re.match(r"^io_storeAddrIn_(\d+)_(.+)$", port)
    if m:
        return f"eb_in_{m.group(1)}_{m.group(2)}"
    return None


def emit_inst(modname, instname, head_re, connfn):
    conns = inst_conns(head_re)
    body = []
    for port, val in conns:
        rw = connfn(port, val)
        if rw is None:
            body.append(f"    .{port}({unwrap(val)})")
        else:
            body.append(f"    .{port}({rw})")
    return f"  {modname} {instname} (\n" + ",\n".join(body) + "\n  );"


def gen_subinst_svh():
    parts = []
    parts.append(emit_inst("SQDataModule", "u_data", r"^  SQDataModule dataModule \(", conn_data))
    parts.append(emit_inst("SQAddrModule", "u_paddr", r"^  SQAddrModule paddrModule \(",
                           lambda p, v: conn_addr("pa", p, v)))
    parts.append(emit_inst("SQAddrModule_1", "u_vaddr", r"^  SQAddrModule_1 vaddrModule \(",
                           lambda p, v: conn_addr("va", p, v)))
    parts.append(emit_inst("DatamoduleResultBuffer", "u_databuf",
                           r"^  DatamoduleResultBuffer dataBuffer \(", conn_db))
    parts.append(emit_inst("StoreExceptionBuffer", "u_excbuf",
                           r"^  StoreExceptionBuffer exceptionBuffer \(", conn_exc))
    txt = (HDR +
           "// 5 个数据存储子模块（黑盒）的例化与端口连接表，由可读核 include。\n"
           "// 直通端口连顶层同名口/输入；读出与被控制逻辑驱动的端口连核内 readable 网。\n\n"
           + "\n\n".join(parts) + "\n")
    (RTL / "storequeue_subinst.svh").write_text(txt)


def gen_rdyvec_svh():
    # 56 路 stAddrReadyVec / stDataReadyVec 扁平输出绑定（机械展开）。
    L = [HDR + "// stAddr/stDataReadyVec 的 56 路扁平输出绑定（核内向量 → golden 扁平端口）。"]
    for i in range(56):
        L.append(f"  assign io_stAddrReadyVec_{i} = stAddrReadyVec_q[{i}];")
        L.append(f"  assign io_stDataReadyVec_{i} = stDataReadyVec_q[{i}];")
    (RTL / "storequeue_rdyvec.svh").write_text("\n".join(L) + "\n")


def gen_ebdecl_svh():
    # exceptionBuffer 7 个输入口被改接到核内 eb_in_<k>_<field> 网；这里按 golden
    # StoreExceptionBuffer 的端口宽度，逐个生成核内 logic 声明（与 subinst 引用名一致）。
    ps = sub_ports("StoreExceptionBuffer")
    L = [HDR + "// exceptionBuffer 7 个输入口的核内 readable 网声明（被 §14 vec 驱动、subinst 引用）。"]
    for d, w, n in ps:
        if d != "input":
            continue
        if n in ("clock", "reset") or n.startswith("io_redirect_"):
            continue
        # io_storeAddrIn_<k>_* → eb_in_<k>_*
        m = re.match(r"^io_storeAddrIn_(\d+)_(.+)$", n)
        if not m:
            continue
        net = f"eb_in_{m.group(1)}_{m.group(2)}"
        ws = f"[{w-1}:0] " if w > 1 else ""
        L.append(f"  logic {ws}{net};")
    (RTL / "storequeue_ebdecl.svh").write_text("\n".join(L) + "\n")


def gen_forward_out_svh():
    # 3 路 forward 的输出端口绑定（forwardMask/Data/MaskFast 来自 data 子模块网，
    # 其余来自 §8 generate 内算出的 fwd_*_o）。机械展开 16 字节 × 3 路。
    L = [HDR + "// 3 路 load forward 输出端口绑定。"]
    for i in range(3):
        for b in range(16):
            L.append(f"  assign io_forward_{i}_forwardMask_{b} = sd_forwardMask[{i}][{b}];")
            L.append(f"  assign io_forward_{i}_forwardData_{b} = sd_forwardData[{i}][{b}];")
        L.append(f"  assign io_forward_{i}_dataInvalid = fwd_dataInvalid_q[{i}];")
        L.append(f"  assign io_forward_{i}_matchInvalid = fwd_matchInvalid_q[{i}];")
        L.append(f"  assign io_forward_{i}_addrInvalid = fwd_addrInvalid_o[{i}];")
        L.append(f"  assign io_forward_{i}_addrInvalidSqIdx_flag = fwd_addrInvalidSqIdx_o[{i}].flag;")
        L.append(f"  assign io_forward_{i}_addrInvalidSqIdx_value = fwd_addrInvalidSqIdx_o[{i}].value;")
        L.append(f"  assign io_forward_{i}_dataInvalidSqIdx_flag = fwd_dataInvalidSqIdx_o[{i}].flag;")
        L.append(f"  assign io_forward_{i}_dataInvalidSqIdx_value = fwd_dataInvalidSqIdx_o[{i}].value;")
    (RTL / "storequeue_forward_out.svh").write_text("\n".join(L) + "\n")


def gen_ports_svh(ps):
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    txt = (HDR +
           "// 可读核 xs_StoreQueue_core 的端口列表（与 golden StoreQueue 同名扁平端口）。\n"
           + ",\n".join(decls) + "\n")
    (RTL / "storequeue_ports.svh").write_text(txt)


# ----------------------------------------------------------------------------
# golden 同名 wrapper（FM/ST 用）：直接例化可读核（核已是同名扁平端口）。
# ----------------------------------------------------------------------------
def emit_flat_wrapper(modname, ps, corename="xs_StoreQueue_core"):
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    L = [f"module {modname}(", ",\n".join(decls) + "\n);"]
    conns = [f"    .{n}({n})" for _, _, n in ps]
    L.append(f"  {corename} u_core (")
    L.append(",\n".join(conns))
    L.append("  );")
    L.append("endmodule\n")
    return "\n".join(L)


# ----------------------------------------------------------------------------
# 黑盒 stub：5 个子模块的空壳（仅 FM 单独验证时给空定义；UT 用真实 golden 子模块）。
# ----------------------------------------------------------------------------
def sub_ports(modname):
    src = (GOLDEN / f"{modname}.sv").read_text()
    m = re.search(rf"^module {modname}\((.*?)\n\);", src, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return res


def gen_blackbox_sv():
    out = [HDR + "// 5 个数据存储子模块黑盒 stub：仅供 FM 单独跑（hdlin_unresolved_modules=black_box）。\n"
                 "// UT 双例化两侧共用真实 golden 子模块文件，不用这里的空壳。\n"]
    for modname in ("SQDataModule", "SQAddrModule", "SQAddrModule_1",
                    "DatamoduleResultBuffer", "StoreExceptionBuffer"):
        ps = sub_ports(modname)
        decls = []
        for d, w, n in ps:
            ws = f"[{w-1}:0] " if w > 1 else ""
            decls.append(f"  {d:6s} {ws}{n}")
        out.append(f"module {modname}(\n" + ",\n".join(decls) + "\n);\nendmodule\n")
    (RTL / "sq_blackbox.sv").write_text("\n".join(out))


# ----------------------------------------------------------------------------
# UT tb：双例化 u_g(golden StoreQueue) vs u_i(StoreQueue_xs)，逐拍比对全部输出。
# ----------------------------------------------------------------------------
def gen_tb(ps):
    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]

    T = [HDR + """`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;
"""]
    for w, n in ins:
        ws = f"[{w-1}:0] " if w > 1 else ""
        T.append(f"  logic {ws}{n};")
    for w, n in outs:
        ws = f"[{w-1}:0] " if w > 1 else ""
        T.append(f"  wire {ws}g_{n};")
        T.append(f"  wire {ws}i_{n};")

    gc = [".clock(clk)", ".reset(rst)"] + [f".{n}({n})" for _, n in ins]
    gg = gc + [f".{n}(g_{n})" for _, n in outs]
    ig = gc + [f".{n}(i_{n})" for _, n in outs]
    T.append(f"  StoreQueue    u_g ({', '.join(gg)});")
    T.append(f"  StoreQueue_xs u_i ({', '.join(ig)});")

    # 激励发生率：valid/ready/fire 给中等率覆盖握手；redirect 偶发；地址/数据全随机。
    valid_rate = {
        "io_brqRedirect_valid":     "($urandom_range(0,31)==0)",
        "io_uncacheOutstanding":    "($urandom_range(0,3)==0)",
        "io_uncache_req_ready":     "($urandom_range(0,1))",
        "io_uncache_resp_valid":    "($urandom_range(0,3)==0)",
        "io_uncache_idResp_valid":  "($urandom_range(0,3)==0)",
        "io_cmoOpResp_valid":       "($urandom_range(0,3)==0)",
        "io_cmoOpReq_ready":        "($urandom_range(0,1))",
        "io_sbuffer_0_ready":       "($urandom_range(0,1))",
        "io_sbuffer_1_ready":       "($urandom_range(0,1))",
        "io_mmioStout_ready":       "($urandom_range(0,1))",
        "io_vecmmioStout_ready":    "($urandom_range(0,1))",
        "io_cboZeroStout_ready":    "($urandom_range(0,1))",
        "io_rob_pendingst":         "($urandom_range(0,1))",
        "io_wfi_wfiReq":            "($urandom_range(0,7)==0)",
        "io_flushSbuffer_empty":    "($urandom_range(0,1))",
    }

    def rnd(w, n):
        if n in valid_rate:
            return valid_rate[n]
        if n.endswith("_valid") or n.endswith("_ready") or n.endswith("_fire"):
            return "$urandom_range(0,1)"
        if n.startswith("io_enq_needAlloc"):
            return "$urandom_range(0,1)"
        if w == 1:
            return "$urandom_range(0,1)"
        if w <= 32:
            return f"{w}'($urandom)"
        rep = (w + 31) // 32
        return f"{w}'({{{', '.join(['$urandom()']*rep)}}})"

    reset_valids = [n for _, n in ins if n.endswith("_valid")]

    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    for n in reset_valids:
        T.append(f"      {n} <= 1'b0;")
    T.append("    end else begin")
    for w, n in ins:
        T.append(f"      {n} <= {rnd(w, n)};")
    T.append("    end")
    T.append("  end")

    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    #4; checks++;")
    for w, n in outs:
        T.append(f"    if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
        T.append(f"      if(errors<=80) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
    T.append("  end")
    T.append("""  initial begin
    rst = 1; repeat (16) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    return "\n".join(T)


def main():
    ps = top_ports()
    gen_ports_svh(ps)
    gen_rdyvec_svh()
    gen_forward_out_svh()
    gen_ebdecl_svh()
    gen_subinst_svh()
    gen_blackbox_sv()
    (RTL / "StoreQueue_wrapper.sv").write_text(HDR + emit_flat_wrapper("StoreQueue", ps))
    ut = XSSV / "verif/ut/StoreQueue"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(HDR + emit_flat_wrapper("StoreQueue_xs", ps))
    (ut / "tb.sv").write_text(gen_tb(ps))
    ins = sum(1 for d, _, _ in ps if d == "input")
    outs = sum(1 for d, _, _ in ps if d == "output")
    print(f"StoreQueue: {len(ps)} ports ({ins} in / {outs} out)")


if __name__ == "__main__":
    main()
