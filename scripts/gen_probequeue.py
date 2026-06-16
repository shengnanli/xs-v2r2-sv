#!/usr/bin/env python3
"""
ProbeQueue：解析 golden 端口 → 生成 wrapper(golden 同名)、_xs 镜像、随机比对 tb。

ProbeQueue 的 golden 端口已是逐字段扁平 io_*，与可读核 xs_ProbeQueue_core 端口一一
同名。golden 顶层内部例化 8 个 ProbeEntry 黑盒 + 1 个 Arbiter8_MainPipeReq 黑盒——
可读核同样例化这些 golden 黑盒。wrapper 把端口透传进 u_core(xs_ProbeQueue_core)。
设计意图来自 src/main/scala/xiangshan/cache/dcache/mainpipe/Probe.scala。
本脚本只负责机械端口适配 + 随机激励 tb，可读核本体见 rtl/memblock/ProbeQueue.sv。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"


def ports(name):
    text = (GOLDEN / f"{name}.sv").read_text()
    m = re.search(rf"^module {re.escape(name)}\((.*?)\n\);", text, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return res


def emit_wrapper(modname, ps):
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    L = [f"module {modname}(", ",\n".join(decls) + "\n);"]
    conns = [f"    .{n}({n})" for _, _, n in ps]
    L.append("  xs_ProbeQueue_core u_core (")
    L.append(",\n".join(conns))
    L.append("  );")
    L.append("endmodule\n")
    return "\n".join(L)


def main():
    ps = ports("ProbeQueue")
    hdr = "// 自动生成：scripts/gen_probequeue.py —— 勿手改\n"

    (XSSV / "rtl/memblock/ProbeQueue_wrapper.sv").write_text(hdr + emit_wrapper("ProbeQueue", ps))
    ut = XSSV / "verif/ut/ProbeQueue"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit_wrapper("ProbeQueue_xs", ps))

    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]

    T = ["""// 自动生成：scripts/gen_probequeue.py —— 勿手改
`timescale 1ns/1ps
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
    T.append(f"  ProbeQueue    u_g ({', '.join(gg)});")
    T.append(f"  ProbeQueue_xs u_i ({', '.join(ig)});")

    # ---- 随机激励 ----
    # 关键点：
    #  * opcode 固定 Probe=6（golden 内有 opcode==Probe 断言，+SYNTHESIS 虽关断言，但只有
    #    Probe 才是设计的合法激励，固定它使行为有意义）。
    #  * address 压窄高位（仅低若干 block），并配合「不向已在途 block 再发 probe」的模型，
    #    避免触发 probe_conflict 断言路径（虽 +SYNTHESIS 关断言，但保持激励合法）。
    #  * lrsc_locked_block / update_resv_set 适度置位，覆盖 selected_lrsc_blocked /
    #    resvsetProbeBlock 阻塞路径。
    #  * pipe_req.ready 随机背压。
    addr_narrow = {
        "io_mem_probe_bits_address", "io_lrsc_locked_block_bits",
    }
    model_driven = {
        "io_mem_probe_valid", "io_mem_probe_bits_opcode", "io_mem_probe_bits_address",
        "io_pipe_req_ready",
    }
    valid_rate = {
        "io_lrsc_locked_block_valid": "($urandom_range(0,3)==0)",
        "io_update_resv_set":         "($urandom_range(0,7)==0)",
    }

    def rnd(w, n):
        if n in valid_rate:
            return valid_rate[n]
        if n in addr_narrow:
            return f"{{{w-9}'($urandom_range(0,7)), 9'($urandom)}}"
        if w == 1:
            return "$urandom_range(0,1)"
        if w <= 32:
            return f"{w}'($urandom)"
        rep = (w + 31) // 32
        return f"{w}'({{{', '.join(['$urandom()']*rep)}}})"

    reset_valids = ["io_lrsc_locked_block_valid", "io_update_resv_set"]
    in_names = {n for _, n in ins}

    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    for n in reset_valids:
        if n in in_names:
            T.append(f"      {n} <= 1'b0;")
    T.append("    end else begin")
    for w, n in ins:
        if n in model_driven:
            continue
        r = rnd(w, n)
        if r is not None:
            T.append(f"      {n} <= {r};")
    T.append("    end")
    T.append("  end")

    # ---- mem_probe 激励模型 + pipe_req 背压 ----
    # 维护「golden 侧在途 block」影子集合（entry block_addr 反映在 block_valid 上，但 tb
    # 无层次访问，故用「发出且未完成」的近似）：跟踪曾发给 golden 的 block，仅在未在途时
    # 再发新 probe，避免重复 probe 同 block（保持激励合法、两侧一致）。
    T.append("""
  // 在途 block 影子（按低 3 位 block tag，覆盖压窄后的 8 个 block）。
  // probe fire（mem_probe.valid & ready）→ 标记在途；pipe_req fire（probe 完成）→ 清。
  // 由于 entry id 与 block 非一一映射，这里用保守近似：probe 入队即标记其 block，
  // pipe_req 完成即清「最近一次完成的 probe block」——足以显著降低同 block 重发率。
  bit [7:0] blk_inflight;
  reg [2:0] last_probe_blk;
  always @(negedge clk) begin
    if (rst) begin
      io_mem_probe_valid        <= 1'b0;
      io_mem_probe_bits_opcode  <= 3'h6;   // Probe
      io_mem_probe_bits_address <= 48'h0;
      io_pipe_req_ready         <= 1'b1;
      blk_inflight              <= 8'h0;
      last_probe_blk            <= 3'h0;
    end else begin
      automatic bit [2:0] blk = 3'($urandom);
      automatic bit want = ($urandom_range(0,1));
      io_pipe_req_ready        <= ($urandom_range(0,3)!=0);
      io_mem_probe_bits_opcode <= 3'h6;
      // 只在该 block 未在途时发起 probe（保持激励合法）
      if (want && !blk_inflight[blk]) begin
        io_mem_probe_valid        <= 1'b1;
        io_mem_probe_bits_address <= {39'($urandom_range(0,7)), blk, 6'($urandom)};
      end else begin
        io_mem_probe_valid <= 1'b0;
      end
      // probe 入队（golden 接受）→ 标记在途（mem_probe_* 是共享输入，直接引用）
      if (io_mem_probe_valid && g_io_mem_probe_ready)
        blk_inflight[io_mem_probe_bits_address[8:6]] <= 1'b1;
      // probe 完成（送进主流水）→ 清该 block（近似：清所有在途中地址匹配项较难，
      // 这里清 pipe_req 这拍的 addr 对应 block）
      if (g_io_pipe_req_valid && io_pipe_req_ready)
        blk_inflight[g_io_pipe_req_bits_addr[8:6]] <= 1'b0;
    end
  end
""")

    # 比对：payload 类输出仅在对应 valid（取 golden 侧）有效时比对。
    def guard_for(n):
        if n.startswith("io_pipe_req_bits_"):
            return "g_io_pipe_req_valid"
        return None

    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    #4; checks++;")
    for w, n in outs:
        g = guard_for(n)
        pre = f"({g}) && " if g else ""
        T.append(f"    if ({pre}!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
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
    (ut / "tb.sv").write_text("\n".join(T))
    print(f"ProbeQueue: {len(ps)} ports, {len(ins)} inputs, {len(outs)} outputs")


if __name__ == "__main__":
    main()
