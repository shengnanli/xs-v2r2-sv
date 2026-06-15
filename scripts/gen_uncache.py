#!/usr/bin/env python3
"""
Uncache：解析 golden 端口生成 wrapper(golden 同名 Uncache)、_xs 镜像、随机比对 tb。

Uncache 的 golden 端口已是逐字段扁平形式（io_*/auto_*），与可读核 xs_Uncache_core
端口一一同名，故 wrapper / _xs 只把端口透传给核（u_core），无需打包/拆分逻辑。
可读性体现在核内部用 struct/enum/function/generate 表达 ubuffer 与三处理面。

设计意图来自 src/main/scala/xiangshan/cache/dcache/Uncache.scala
（ubuffer entry 状态机 + Enter/UncReq/UncResp/Return/Forward 五处理面）。
本脚本只负责机械端口适配 + 随机激励 tb，可读核本体见 rtl/memblock/Uncache.sv。
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


def emit(modname, ps, core="xs_Uncache_core"):
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    L = [f"module {modname}(", ",\n".join(decls) + "\n);"]
    conns = [f"    .{n}({n})" for _, _, n in ps]
    L.append(f"  {core} u_core (")
    L.append(",\n".join(conns))
    L.append("  );")
    L.append("endmodule\n")
    return "\n".join(L)


def main():
    ps = ports("Uncache")
    hdr = "// 自动生成：scripts/gen_uncache.py —— 勿手改\n"

    (XSSV / "rtl/memblock/Uncache_wrapper.sv").write_text(hdr + emit("Uncache", ps))
    ut = XSSV / "verif/ut/Uncache"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit("Uncache_xs", ps))

    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]

    T = ["""// 自动生成：scripts/gen_uncache.py —— 勿手改
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
    T.append(f"  Uncache    u_g ({', '.join(gg)});")
    T.append(f"  Uncache_xs u_i ({', '.join(ig)});")

    # ---- 随机激励 ----
    # 关键点：
    #  * 地址类（addr/vaddr/paddr/forward_*）压窄高位，使少数 block 反复命中，提高
    #    merge / waitSame / forward-CAM 覆盖（这是本单元最核心的状态交互）。
    #  * d_bits_source 限制在 0..UNC_SIZE-1（2 位），否则索引越界出 X。
    #  * mask 偏向「连续对齐」窗口（继续触发 merge 的 continueAndAlign 通过路径）。
    #  * cmd 在 {load=0, store=1} 间随机，保证 Get/Put 两路与 forward(仅 store) 都跑到。
    # d 通道由下方 TileLink-slave 模型驱动（不随机），其余随机。
    model_driven = {
        "auto_client_out_d_valid", "auto_client_out_d_bits_source",
        "auto_client_out_d_bits_data", "auto_client_out_d_bits_denied",
        "auto_client_out_d_bits_corrupt",
    }
    valid_rate = {
        "io_lsq_req_valid":          "($urandom_range(0,1))",
        "auto_client_out_a_ready":   "($urandom_range(0,3)!=0)",
        "io_lsq_resp_ready":         "($urandom_range(0,2)!=0)",
        "io_flush_valid":            "($urandom_range(0,31)==0)",
        "io_wfi_wfiReq":             "($urandom_range(0,7)==0)",
        "io_enableOutstanding":      "($urandom_range(0,1))",
        "io_forward_0_valid":        "($urandom_range(0,1))",
        "io_forward_1_valid":        "($urandom_range(0,1))",
        "io_forward_2_valid":        "($urandom_range(0,1))",
    }

    addr_narrow = {
        "io_lsq_req_bits_addr", "io_lsq_req_bits_vaddr",
        "io_forward_0_vaddr", "io_forward_0_paddr",
        "io_forward_1_vaddr", "io_forward_1_paddr",
        "io_forward_2_vaddr", "io_forward_2_paddr",
    }

    def rnd(w, n):
        if n in valid_rate:
            return valid_rate[n]
        # cmd：0/1 之间随机（load/store）
        if n == "io_lsq_req_bits_cmd":
            return "5'($urandom_range(0,1))"
        # d_bits_source：限制在 0..3（2 位 entry 下标），避免越界 X
        if n == "auto_client_out_d_bits_source":
            return "2'($urandom_range(0,3))"
        # mask：偏向连续对齐窗口（提高 merge/对齐合法路径覆盖）
        if n in ("io_lsq_req_bits_mask",):
            return ("$urandom_range(0,3)==0 ? 8'hff : "
                    "$urandom_range(0,2)==0 ? (8'h3 << (4*$urandom_range(0,1))) : "
                    "(8'h1 << $urandom_range(0,7))")
        # 地址类：压窄高位（仅低若干 block）以反复命中同地址
        if n in addr_narrow:
            return f"{{{w-6}'($urandom_range(0,3)), 6'($urandom)}}"
        if w == 1:
            return "$urandom_range(0,1)"
        if w <= 32:
            return f"{w}'($urandom)"
        rep = (w + 31) // 32
        return f"{w}'({{{', '.join(['$urandom()']*rep)}}})"

    reset_valids = [
        "io_lsq_req_valid", "auto_client_out_d_valid", "io_flush_valid",
        "io_wfi_wfiReq", "io_forward_0_valid", "io_forward_1_valid", "io_forward_2_valid",
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

    # ---- TileLink-UL slave 模型：驱动 d 通道 ----
    # Uncache 内部断言「收到 D 的 source 必须是 inflight 的 entry」。纯随机 d 会违例并
    # 让两侧分叉，故这里用一个最小 TL-UL slave：以 golden 的 a 通道为参考（两侧应等价），
    # a fire 时记下该 source 在途，随机若干拍后回 d（带随机 denied/corrupt 与读数据），
    # 保证每个 d.source 都对应一个真实在途请求。两侧 d 输入完全相同。
    T.append("""
  // 在途记录：每个 source(0..3) 是否有未回的请求
  bit [3:0]  inflight_q;
  bit [3:0]  pend_isld;            // 该在途请求是否 load（需回读数据）
  int unsigned start_idx = 0;      // 轮转起点
  // 简单单拍回应：a fire 当拍即可在下一拍择一在途 source 回 d
  always @(negedge clk) begin
    if (rst) begin
      auto_client_out_d_valid         <= 1'b0;
      auto_client_out_d_bits_source   <= 2'h0;
      auto_client_out_d_bits_data     <= 64'h0;
      auto_client_out_d_bits_denied   <= 1'b0;
      auto_client_out_d_bits_corrupt  <= 1'b0;
      inflight_q                      <= 4'h0;
      pend_isld                       <= 4'h0;
    end else begin
      // 记录 golden a fire（a_valid & a_ready）→ 置该 source 在途
      if (g_auto_client_out_a_valid && auto_client_out_a_ready) begin
        inflight_q[g_auto_client_out_a_bits_source] <= 1'b1;
        pend_isld[g_auto_client_out_a_bits_source]  <= (g_auto_client_out_a_bits_opcode == 4'h4);
      end
      // 默认不发 d
      auto_client_out_d_valid <= 1'b0;
      // 随机择一在途 source 回 d（d.ready 在 Uncache 内恒 1，单拍完成）
      if (|inflight_q && ($urandom_range(0,1))) begin
        int unsigned k;
        bit hit;
        hit = 1'b0;
        for (k = 0; k < 4; k++) begin
          if (!hit && inflight_q[(start_idx+k)%4]) begin
            hit = 1'b1;
            auto_client_out_d_valid        <= 1'b1;
            auto_client_out_d_bits_source  <= 2'(((start_idx+k)%4));
            auto_client_out_d_bits_data    <= 64'({$urandom(), $urandom()});
            auto_client_out_d_bits_denied  <= ($urandom_range(0,7)==0);
            auto_client_out_d_bits_corrupt <= ($urandom_range(0,7)==0);
            inflight_q[(start_idx+k)%4]    <= 1'b0; // 这一 source 回完即清在途
          end
        end
        start_idx <= start_idx + 1; // 轮转起点，避免总回同一个
      end
    end
  end
""")

    # 比对：复位后每拍在时钟稳定区比对所有输出。
    # 关键：payload 类输出（a_bits_* / resp_bits_* / idResp_bits_* / busError_bits /
    # forward_*_forwardData|Mask|matchInvalid）只有在其对应 valid 拉高时才有意义；valid=0
    # 时 golden 暴露的是优先级编码器的「无效缺省」值（非 X 的任意下标对应内容），与 impl
    # 缺省值不同属正常。故 payload 仅在对应 valid（取 golden 侧）有效时比对。
    def guard_for(n):
        if n.startswith("auto_client_out_a_bits_"):
            return "g_auto_client_out_a_valid"
        if n.startswith("io_lsq_resp_bits_"):
            return "g_io_lsq_resp_valid"
        if n.startswith("io_lsq_idResp_bits_"):
            return "g_io_lsq_idResp_valid"
        if n == "io_busError_ecc_error_bits":
            return "g_io_busError_ecc_error_valid"
        for ch in ("0", "1", "2"):
            if n.startswith(f"io_forward_{ch}_forwardData_") or \
               n.startswith(f"io_forward_{ch}_forwardMask_") or \
               n == f"io_forward_{ch}_matchInvalid":
                # forward 输出在 f1_fwdValid（= forward.valid 打一拍）时有效；这里用
                # 该路 forward valid 打拍后的值做门控（在 tb 内维护 fwd_v_q）。
                return f"fwd_v_q[{ch}]"
        return None

    # forward.valid 打一拍寄存器（f1_fwdValid），forward payload 比对用
    T.append("  logic [2:0] fwd_v_q;")
    T.append("  always @(posedge clk) if (!rst) begin")
    T.append("    fwd_v_q[0] <= io_forward_0_valid;")
    T.append("    fwd_v_q[1] <= io_forward_1_valid;")
    T.append("    fwd_v_q[2] <= io_forward_2_valid;")
    T.append("  end")

    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    #4; checks++;")
    for w, n in outs:
        g = guard_for(n)
        pre = f"({g}) && " if g else ""
        T.append(f"    if ({pre}!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
        T.append(f"      if(errors<=60) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
    T.append("  end")
    T.append("""  initial begin
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    (ut / "tb.sv").write_text("\n".join(T))
    print(f"Uncache: {len(ps)} ports, {len(ins)} inputs, {len(outs)} outputs")


if __name__ == "__main__":
    main()
