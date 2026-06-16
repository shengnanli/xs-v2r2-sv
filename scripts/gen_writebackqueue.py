#!/usr/bin/env python3
"""
WritebackQueue：解析 golden 端口 → 生成 wrapper(golden 同名)、_xs 镜像、随机比对 tb。

WritebackQueue 的 golden 端口已是逐字段扁平 io_*，与可读核 xs_WritebackQueue_core
端口一一同名（本配置无 io_req_ready_dup / io_primary_ready_dup，已被裁剪）。
golden 顶层内部例化 18 个 WritebackEntry 黑盒（前 15 个 5 位 id 的 WritebackEntry，
后 3 个 6 位 id 的 WritebackEntry_15）——可读核同样例化这些 golden 黑盒。故 wrapper
只是把端口透传进 u_core(xs_WritebackQueue_core)。
设计意图来自 src/main/scala/xiangshan/cache/dcache/mainpipe/WritebackQueue.scala。
本脚本只负责机械端口适配 + 随机激励 tb，可读核本体见 rtl/memblock/WritebackQueue.sv。
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
    L.append("  xs_WritebackQueue_core u_core (")
    L.append(",\n".join(conns))
    L.append("  );")
    L.append("endmodule\n")
    return "\n".join(L)


def main():
    ps = ports("WritebackQueue")
    hdr = "// 自动生成：scripts/gen_writebackqueue.py —— 勿手改\n"

    (XSSV / "rtl/memblock/WritebackQueue_wrapper.sv").write_text(hdr + emit_wrapper("WritebackQueue", ps))
    ut = XSSV / "verif/ut/WritebackQueue"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit_wrapper("WritebackQueue_xs", ps))

    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]

    T = ["""// 自动生成：scripts/gen_writebackqueue.py —— 勿手改
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
    T.append(f"  WritebackQueue    u_g ({', '.join(gg)});")
    T.append(f"  WritebackQueue_xs u_i ({', '.join(ig)});")

    # ---- 随机激励 ----
    # 关键点：
    #  * 地址类（req.addr / miss_req_*）压窄高位（仅低若干 cacheline），反复命中相同
    #    block，提高 block_conflict / miss 冲突 / 同 source mem_grant 覆盖。
    #  * req.addr 低 6 位行内偏移无关紧要（entry 比的是整 48 位 addr），统一压窄。
    #  * mem_grant.source 必须命中某在途 entry 的 id(17..34) 才有效——用模型从 golden
    #    侧在途 entry 中择一回 grant，避免乱回 source 让自愿 Release 永远等不到 ack。
    #  * mem_release.ready 随机背压，触发多 beat 突发的 robin 锁定路径。
    addr_narrow = {
        "io_req_bits_addr",
        "io_miss_req_conflict_check_0_bits", "io_miss_req_conflict_check_1_bits",
        "io_miss_req_conflict_check_2_bits", "io_miss_req_conflict_check_3_bits",
        "io_miss_req_conflict_check_4_bits",
    }
    model_driven = {
        "io_mem_release_ready", "io_mem_grant_valid", "io_mem_grant_bits_source",
    }
    valid_rate = {
        "io_req_valid":  "($urandom_range(0,1))",
        "io_miss_req_conflict_check_0_valid": "($urandom_range(0,3)==0)",
        "io_miss_req_conflict_check_1_valid": "($urandom_range(0,3)==0)",
        "io_miss_req_conflict_check_2_valid": "($urandom_range(0,3)==0)",
        "io_miss_req_conflict_check_3_valid": "($urandom_range(0,3)==0)",
        "io_miss_req_conflict_check_4_valid": "($urandom_range(0,3)==0)",
        # voluntary：约一半（Release 路径需等 ReleaseAck；ProbeAck 路径不等）
        "io_req_bits_voluntary": "($urandom_range(0,1))",
        # hasData：约一半（决定 1 beat 还是 2 beat 突发）
        "io_req_bits_hasData":   "($urandom_range(0,1))",
        # dirty 必须 dirty→hasData（entry 内断言 !dirty||hasData）；这里令 dirty 只在
        # hasData 时随机置位，由下方激励块特殊处理。
    }

    def rnd(w, n):
        if n in valid_rate:
            return valid_rate[n]
        if n in addr_narrow:
            # 压窄高位：仅低 8 个 cacheline（tag 3 位），低位随机
            return f"{{{w-9}'($urandom_range(0,7)), 9'($urandom)}}"
        if w == 1:
            return "$urandom_range(0,1)"
        if w <= 32:
            return f"{w}'($urandom)"
        rep = (w + 31) // 32
        return f"{w}'({{{', '.join(['$urandom()']*rep)}}})"

    reset_valids = [
        "io_req_valid",
        "io_miss_req_conflict_check_0_valid", "io_miss_req_conflict_check_1_valid",
        "io_miss_req_conflict_check_2_valid", "io_miss_req_conflict_check_3_valid",
        "io_miss_req_conflict_check_4_valid",
    ]
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
        if n in ("io_req_bits_dirty",):
            continue  # 与 hasData 联动，下面处理
        r = rnd(w, n)
        if r is not None:
            T.append(f"      {n} <= {r};")
    # dirty 仅在 hasData 时可置位（满足 entry 内 !dirty||hasData 断言）
    T.append("      io_req_bits_dirty <= io_req_bits_hasData && ($urandom_range(0,1));")
    T.append("    end")
    T.append("  end")

    # ---- mem_grant 响应模型 ----
    # 自愿 Release(voluntary) 写完后进 s_release_resp 等 ReleaseAck（mem_grant，按 source
    # 匹配 entry id）。这里用块地址-id 影子表跟踪「哪些 entry id 在等 ack」：观察 golden
    # 侧 mem_release fire 的 source 记为「在途」，随机择一回 grant。ProbeAck 不等 ack。
    T.append("""
  // 影子记录：每个 entry id(17..34) 是否可能在等 ReleaseAck（按 golden mem_release 观察）
  // 简化：只要 golden 这拍发出 voluntary+release_done 的可能，就把该 source 标记；为稳健，
  // 直接随机回 grant 给「曾经发过 release 的 source」。这里采用：跟踪 golden 侧最近发出的
  // release source 集合（任意 voluntary release 都可能在等 ack），随机择一回 grant。
  bit [34:0] grant_pending;   // index = entry id (0..34)，只用 17..34
  int unsigned gp_start = 0;
  always @(negedge clk) begin
    if (rst) begin
      io_mem_release_ready  <= 1'b1;
      io_mem_grant_valid    <= 1'b0;
      io_mem_grant_bits_source <= 6'h0;
      grant_pending         <= 35'h0;
    end else begin
      io_mem_release_ready <= ($urandom_range(0,3)!=0);
      // golden 发出 voluntary release（opcode[1]=1 表 Release/ReleaseData）且 fire →
      // 该 source 进入 pending（等 ReleaseAck）。
      if (g_io_mem_release_valid && io_mem_release_ready &&
          g_io_mem_release_bits_opcode[1])
        grant_pending[g_io_mem_release_bits_source] <= 1'b1;
      io_mem_grant_valid <= 1'b0;
      if (|grant_pending && ($urandom_range(0,1))) begin
        int unsigned k; bit done;
        done = 1'b0;
        for (k = 17; k <= 34; k++) begin
          if (!done && grant_pending[(17+((gp_start+k-17)%18))]) begin
            done = 1'b1;
            io_mem_grant_valid       <= 1'b1;
            io_mem_grant_bits_source <= 6'(17+((gp_start+k-17)%18));
            grant_pending[(17+((gp_start+k-17)%18))] <= 1'b0;
          end
        end
        gp_start <= gp_start + 1;
      end
    end
  end
""")

    # 比对：payload 类输出仅在对应 valid（取 golden 侧）有效时比对。
    def guard_for(n):
        if n.startswith("io_mem_release_bits_"):
            return "g_io_mem_release_valid"
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
    print(f"WritebackQueue: {len(ps)} ports, {len(ins)} inputs, {len(outs)} outputs")


if __name__ == "__main__":
    main()
