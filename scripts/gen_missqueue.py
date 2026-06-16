#!/usr/bin/env python3
"""
MissQueue：解析 golden 端口 → 生成 wrapper(golden 同名)、_xs 镜像、随机比对 tb。

MissQueue 的 golden 端口已是逐字段扁平 io_*，与可读核 xs_MissQueue_core 端口一一同名。
golden 顶层内部例化 16 个 MissEntry 黑盒 + 1 个 CMOUnit 黑盒 + 1 个 FastArbiter 黑盒
（amo main_pipe_req 仲裁）——可读核同样例化这些 golden 黑盒（队列级逻辑重写，entry
状态机 / CMO 状态机 / amo 仲裁沿用 golden 黑盒）。故 wrapper 只是把端口透传进
u_core(xs_MissQueue_core)。

设计意图来自 src/main/scala/xiangshan/cache/dcache/mainpipe/MissQueue.scala（class MissQueue）。
本脚本只负责机械端口适配 + 随机激励 tb，可读核本体见 rtl/memblock/MissQueue.sv。
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
    L.append("  xs_MissQueue_core u_core (")
    L.append(",\n".join(conns))
    L.append("  );")
    L.append("endmodule\n")
    return "\n".join(L)


def main():
    ps = ports("MissQueue")
    hdr = "// 自动生成：scripts/gen_missqueue.py —— 勿手改\n"

    (XSSV / "rtl/memblock/MissQueue_wrapper.sv").write_text(hdr + emit_wrapper("MissQueue", ps))
    ut = XSSV / "verif/ut/MissQueue"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit_wrapper("MissQueue_xs", ps))

    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]

    T = ["""// 自动生成：scripts/gen_missqueue.py —— 勿手改
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
    T.append(f"  MissQueue    u_g ({', '.join(gg)});")
    T.append(f"  MissQueue_xs u_i ({', '.join(ig)});")

    # ---- 随机激励 ----
    # 关键点：
    #  * 地址类（io_req/io_queryMQ/io_probe/io_replace 的 addr/vaddr）压窄高位，反复命中
    #    相同 block，提高 merge / reject / req_pipeline_reg_handled / block 冲突覆盖。
    #  * io_mem_grant.source 必须命中某在途 entry 的 id(0..15)/cmo(17) 才有效——用窄随机
    #    （0..18）让 grant 命中真实 entry，触发 D 通道收数据路径。
    #  * io_req.source 主要取 0/1/3（load/store/prefetch），覆盖 merge_load/merge_store。
    #  * mem_acquire.ready / main_pipe_req.ready / mem_finish.ready 随机背压，触发仲裁。
    #  * mainpipe_info.s2/s3_miss_id 窄随机命中 entry。
    addr_narrow = {
        "io_req_bits_addr", "io_req_bits_vaddr",
        "io_queryMQ_0_req_bits_addr", "io_queryMQ_0_req_bits_vaddr",
        "io_queryMQ_1_req_bits_addr", "io_queryMQ_1_req_bits_vaddr",
        "io_queryMQ_2_req_bits_addr", "io_queryMQ_2_req_bits_vaddr",
        "io_queryMQ_3_req_bits_addr", "io_queryMQ_3_req_bits_vaddr",
        "io_probe_req_bits_addr", "io_probe_req_bits_vaddr",
        "io_replace_req_bits_addr", "io_replace_req_bits_vaddr",
        "io_forward_0_paddr", "io_forward_1_paddr", "io_forward_2_paddr",
    }
    # 4 位 source/id/way 等可全随机；这些 byte 字段窄随机更易撞 entry。
    narrow_id = {  # 命中 entry / mshr：取 0..15
        "io_mainpipe_info_s2_miss_id", "io_mainpipe_info_s3_miss_id",
        "io_main_pipe_resp_bits_miss_id",
        "io_forward_0_mshrid", "io_forward_1_mshrid", "io_forward_2_mshrid",
        "io_l2_hint_bits_sourceId",
    }
    src4 = {  # req.source：偏向 load(0)/store(1)/prefetch(3)
        "io_req_bits_source",
        "io_queryMQ_0_req_bits_source", "io_queryMQ_1_req_bits_source",
        "io_queryMQ_2_req_bits_source", "io_queryMQ_3_req_bits_source",
    }
    model_driven = {
        "io_mem_grant_valid", "io_mem_grant_bits_source", "io_mem_grant_bits_opcode",
    }
    valid_rate = {
        "io_req_valid":  "($urandom_range(0,1))",
        "io_cmo_req_valid": "($urandom_range(0,7)==0)",
        "io_main_pipe_resp_valid": "($urandom_range(0,1))",
        "io_mainpipe_info_s2_valid": "($urandom_range(0,1))",
        "io_mainpipe_info_s3_valid": "($urandom_range(0,1))",
        "io_l2_hint_valid": "($urandom_range(0,3)==0)",
        "io_forward_0_valid": "($urandom_range(0,1))",
        "io_forward_1_valid": "($urandom_range(0,1))",
        "io_forward_2_valid": "($urandom_range(0,1))",
        "io_req_bits_cancel": "($urandom_range(0,7)==0)",
        "io_wbq_block_miss_req": "($urandom_range(0,7)==0)",
        "io_probe_req_bits_addr": None,  # handled by addr_narrow
    }
    ready_rate = {
        "io_mem_acquire_ready", "io_mem_finish_ready", "io_main_pipe_req_ready",
        "io_cmo_resp_ready",
    }

    def rnd(w, n):
        if n in src4:
            return "(4'($urandom_range(0,1) ? $urandom_range(0,1) : 4'h3))"
        if n in narrow_id:
            return f"{w}'($urandom_range(0,15))"
        if n in valid_rate and valid_rate[n] is not None:
            return valid_rate[n]
        if n in ready_rate:
            return "($urandom_range(0,3)!=0)"
        if n in addr_narrow:
            # 压窄高位：仅低 8 个 cacheline（tag 3 位），低位随机；保留 alias 位[13:12] 随机
            return f"{{{w-15}'($urandom_range(0,3)), 3'($urandom_range(0,7)), 12'($urandom)}}"
        if w == 1:
            return "$urandom_range(0,1)"
        if w <= 32:
            return f"{w}'($urandom)"
        rep = (w + 31) // 32
        return f"{w}'({{{', '.join(['$urandom()']*rep)}}})"

    reset_valids = [n for _, n in ins if n.endswith("_valid") or n in (
        "io_req_valid", "io_cmo_req_valid")]
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

    # ---- mem_grant 响应模型 ----
    # 收 D 通道：grant.source 命中 entry id(0..15) → 把数据送对应 entry；source==17 →
    # CMO 的 CBOAck（opcode==4'h8 也走 cmo）。随机回 grant，命中真实 in-flight entry
    # 才能让 refill 推进。简化：随机择 source∈{0..17}，opcode 随机（GrantData=5/Grant=4/
    # CBOAck=8）。
    T.append("""
  always @(negedge clk) begin
    if (rst) begin
      io_mem_grant_valid       <= 1'b0;
      io_mem_grant_bits_source <= 6'h0;
      io_mem_grant_bits_opcode <= 4'h0;
    end else begin
      io_mem_grant_valid       <= ($urandom_range(0,1));
      // source：多数命中 entry(0..15)，偶尔 17(CMO)
      io_mem_grant_bits_source <= ($urandom_range(0,7)==0) ? 6'h11
                                                           : 6'($urandom_range(0,15));
      // opcode：GrantData(5)/Grant(4)/CBOAck(8)
      case ($urandom_range(0,2))
        0: io_mem_grant_bits_opcode <= 4'h5;
        1: io_mem_grant_bits_opcode <= 4'h4;
        default: io_mem_grant_bits_opcode <= 4'h8;
      endcase
    end
  end
""")

    # 比对：mem_acquire / mem_finish payload 仅在 valid 有效时比对；其余直接比对。
    def guard_for(n):
        if n.startswith("io_mem_acquire_bits"):
            return "g_io_mem_acquire_valid"
        if n.startswith("io_mem_finish_bits"):
            return "g_io_mem_finish_valid"
        if n.startswith("io_main_pipe_req_bits"):
            return "g_io_main_pipe_req_valid"
        if n.startswith("io_cmo_resp_bits"):
            return "g_io_cmo_resp_valid"
        if n.startswith("io_resp_"):
            return None  # resp 是组合，无 valid（用 io_req_valid 弱守护）
        if n.startswith("io_refill_info_bits"):
            return "g_io_refill_info_valid"
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
    print(f"MissQueue: {len(ps)} ports, {len(ins)} inputs, {len(outs)} outputs")


if __name__ == "__main__":
    main()
