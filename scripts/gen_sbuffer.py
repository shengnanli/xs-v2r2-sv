#!/usr/bin/env python3
"""
Sbuffer：解析 golden 端口生成 wrapper(golden 同名 Sbuffer)、_xs 镜像、随机比对 tb。

Sbuffer 的 golden 端口已是逐字段扁平形式（io_*），与可读核 xs_Sbuffer_core 端口
一一同名。golden 顶层 Sbuffer 内部例化黑盒 StorePfWrapper（store 预取，本配置直驱
store_prefetch_*_bits_vaddr）。可读核不含 prefetcher，故：
  · wrapper（FM/UT 用，golden 同名 Sbuffer）= 例化 u_core(xs_Sbuffer_core) 透传所有
    端口，但 store_prefetch_*_bits_vaddr 改由 wrapper 内例化的 golden StorePfWrapper 驱动
    （与 golden 顶层结构一致），u_core 这两个输出悬空。
设计意图来自 src/main/scala/xiangshan/mem/sbuffer/Sbuffer.scala。
本脚本只负责机械端口适配 + 随机激励 tb，可读核本体见 rtl/memblock/Sbuffer.sv。
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


PF_PORTS = {"io_store_prefetch_0_bits_vaddr", "io_store_prefetch_1_bits_vaddr"}


def emit_wrapper(modname, ps):
    """golden 同名 Sbuffer：例化可读核 u_core + 黑盒 StorePfWrapper（驱动 prefetch 口）。"""
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    L = [f"module {modname}(", ",\n".join(decls) + "\n);"]
    # 可读核：prefetch 输出端口不连（核内已置 0 但此处接 wrapper 内部丢弃线）
    conns = []
    for _, w, n in ps:
        if n in PF_PORTS:
            ws = f"[{w-1}:0] " if w > 1 else ""
            L.append(f"  wire {ws}u_{n}_unused;")
            conns.append(f"    .{n}(u_{n}_unused)")
        else:
            conns.append(f"    .{n}({n})")
    L.append("  xs_Sbuffer_core u_core (")
    L.append(",\n".join(conns))
    L.append("  );")
    # 黑盒 prefetcher 驱动真实 prefetch 输出（与 golden 顶层一致）
    L.append("  StorePfWrapper prefetcher (")
    L.append("    .clock(clock),")
    L.append("    .reset(reset),")
    L.append("    .io_prefetch_req_0_bits_vaddr(io_store_prefetch_0_bits_vaddr),")
    L.append("    .io_prefetch_req_1_bits_vaddr(io_store_prefetch_1_bits_vaddr)")
    L.append("  );")
    L.append("endmodule\n")
    return "\n".join(L)


def main():
    ps = ports("Sbuffer")
    hdr = "// 自动生成：scripts/gen_sbuffer.py —— 勿手改\n"

    (XSSV / "rtl/memblock/Sbuffer_wrapper.sv").write_text(hdr + emit_wrapper("Sbuffer", ps))
    ut = XSSV / "verif/ut/Sbuffer"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit_wrapper("Sbuffer_xs", ps))

    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]

    T = ["""// 自动生成：scripts/gen_sbuffer.py —— 勿手改
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
    T.append(f"  Sbuffer    u_g ({', '.join(gg)});")
    T.append(f"  Sbuffer_xs u_i ({', '.join(ig)});")

    # ---- 随机激励 ----
    # 关键点：
    #  * 地址类（addr/vaddr/paddr/forward_*）压窄高位（仅低若干 cacheline tag），使少数
    #    cacheline 反复命中，提高 merge / sameblock-inflight / forward-CAM 覆盖。
    #  * dcache hit/replay resp 的 id 限制在 0..15（4 位 entry 下标），并由模型确保只对
    #    inflight 的 entry 回 resp（否则内部断言 inflight 违例、两侧分叉）。
    #  * mask 偏向「连续/对齐」窗口，触发 merge 字节合并各路径。
    addr_narrow = {
        "io_in_0_bits_addr", "io_in_0_bits_vaddr", "io_in_1_bits_addr", "io_in_1_bits_vaddr",
        "io_forward_0_vaddr", "io_forward_0_paddr", "io_forward_1_vaddr", "io_forward_1_paddr",
        "io_forward_2_vaddr", "io_forward_2_paddr",
    }
    model_driven = {
        "io_dcache_req_ready",
        "io_dcache_main_pipe_hit_resp_valid", "io_dcache_main_pipe_hit_resp_bits_id",
        "io_dcache_replay_resp_valid", "io_dcache_replay_resp_bits_id",
    }
    valid_rate = {
        "io_in_0_valid":      "($urandom_range(0,1))",
        "io_in_1_valid":      "($urandom_range(0,1))",
        "io_flush_valid":     "($urandom_range(0,63)==0)",
        "io_sqempty":         "($urandom_range(0,3)!=0)",
        "io_force_write":     "($urandom_range(0,7)==0)",
        "io_forward_0_valid": "($urandom_range(0,1))",
        "io_forward_1_valid": "($urandom_range(0,1))",
        "io_forward_2_valid": "($urandom_range(0,1))",
        "io_in_0_bits_vecValid": "($urandom_range(0,7)!=0)",
        "io_in_1_bits_vecValid": "($urandom_range(0,7)!=0)",
        "io_in_0_bits_wline": "($urandom_range(0,15)==0)",
        "io_in_1_bits_wline": "($urandom_range(0,15)==0)",
    }

    def rnd(w, n):
        if n in valid_rate:
            return valid_rate[n]
        if n in ("io_in_0_bits_mask", "io_in_1_bits_mask"):
            # 16b 字节掩码：偏向低 8B 连续窗口（与 8B 字对齐合并路径一致）
            return ("$urandom_range(0,3)==0 ? 16'hffff : "
                    "$urandom_range(0,2)==0 ? (16'h00ff << (8*$urandom_range(0,1))) : "
                    "(16'h1 << $urandom_range(0,15))")
        if n in addr_narrow:
            # 压窄高位：仅低 8 个 cacheline（tag 取 3 位），低 6 位行内偏移随机
            return f"{{{w-9}'($urandom_range(0,7)), 9'($urandom)}}"
        if w == 1:
            return "$urandom_range(0,1)"
        if w <= 32:
            return f"{w}'($urandom)"
        rep = (w + 31) // 32
        return f"{w}'({{{', '.join(['$urandom()']*rep)}}})"

    reset_valids = [
        "io_in_0_valid", "io_in_1_valid", "io_flush_valid",
        "io_forward_0_valid", "io_forward_1_valid", "io_forward_2_valid",
        "io_dcache_main_pipe_hit_resp_valid", "io_dcache_replay_resp_valid",
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
        r = rnd(w, n)
        if r is not None:
            T.append(f"      {n} <= {r};")
    T.append("    end")
    T.append("  end")

    # ---- DCache 写口/响应模型 ----
    # Sbuffer 内部断言：收到 hit_resp/replay_resp 的 id 必须是 inflight 的 entry，且
    # 一个 entry 不能同时 hit+replay。纯随机 resp 会违例并让两侧分叉。这里用最小模型：
    #  · req_ready 随机（背压）。
    #  · 记录 golden 侧 dcache_req fire 的 id → 该 entry inflight。
    #  · 随机择一 inflight entry 回 hit_resp（释放）或 replay_resp（挂超时），二选一。
    T.append("""
  // 在途记录：每个 entry id(0..15) 是否有未回的 DCache 写
  bit [15:0] dc_inflight;
  int unsigned dc_start = 0;
  always @(negedge clk) begin
    if (rst) begin
      io_dcache_req_ready                  <= 1'b1;
      io_dcache_main_pipe_hit_resp_valid   <= 1'b0;
      io_dcache_main_pipe_hit_resp_bits_id <= 6'h0;
      io_dcache_replay_resp_valid          <= 1'b0;
      io_dcache_replay_resp_bits_id        <= 6'h0;
      dc_inflight                          <= 16'h0;
    end else begin
      io_dcache_req_ready <= ($urandom_range(0,3)!=0);
      // golden req fire → 标记该 id inflight
      if (g_io_dcache_req_valid && io_dcache_req_ready)
        dc_inflight[g_io_dcache_req_bits_id[3:0]] <= 1'b1;
      // 默认不回 resp
      io_dcache_main_pipe_hit_resp_valid <= 1'b0;
      io_dcache_replay_resp_valid        <= 1'b0;
      if (|dc_inflight && ($urandom_range(0,1))) begin
        int unsigned k; bit hit; bit do_replay;
        hit = 1'b0; do_replay = ($urandom_range(0,3)==0);
        for (k = 0; k < 16; k++) begin
          if (!hit && dc_inflight[(dc_start+k)%16]) begin
            hit = 1'b1;
            if (do_replay) begin
              io_dcache_replay_resp_valid   <= 1'b1;
              io_dcache_replay_resp_bits_id <= 6'(((dc_start+k)%16));
              // replay 不释放在途（entry 仍 inflight，挂 w_timeout 后会重发）；
              // 为避免反复同 entry replay 卡死，这里也清在途，后续重发再标记。
              dc_inflight[(dc_start+k)%16] <= 1'b0;
            end else begin
              io_dcache_main_pipe_hit_resp_valid   <= 1'b1;
              io_dcache_main_pipe_hit_resp_bits_id <= 6'(((dc_start+k)%16));
              dc_inflight[(dc_start+k)%16] <= 1'b0;
            end
          end
        end
        dc_start <= dc_start + 1;
      end
    end
  end
""")

    # 比对：payload 类输出仅在对应 valid（取 golden 侧）有效时比对。
    def guard_for(n):
        if n.startswith("io_dcache_req_bits_"):
            return "g_io_dcache_req_valid"
        for ch in ("0", "1", "2"):
            if n.startswith(f"io_forward_{ch}_forwardData_") or \
               n.startswith(f"io_forward_{ch}_forwardMask_") or \
               n == f"io_forward_{ch}_matchInvalid":
                return f"fwd_v_q[{ch}]"
        return None

    T.append("  logic [2:0] fwd_v_q;")
    T.append("  always @(posedge clk) if (!rst) begin")
    T.append("    fwd_v_q[0] <= io_forward_0_valid;")
    T.append("    fwd_v_q[1] <= io_forward_1_valid;")
    T.append("    fwd_v_q[2] <= io_forward_2_valid;")
    T.append("  end")

    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    #4; checks++;")
    for w, n in outs:
        # store_prefetch 由黑盒 StorePfWrapper 驱动，两侧应同（同例化），但其值不确定，
        # 故不比对（已是黑盒输出，UT 无意义）。
        if n in PF_PORTS:
            continue
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
    print(f"Sbuffer: {len(ps)} ports, {len(ins)} inputs, {len(outs)} outputs")


if __name__ == "__main__":
    main()
