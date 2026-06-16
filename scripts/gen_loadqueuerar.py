#!/usr/bin/env python3
# =============================================================================
#  gen_loadqueuerar.py —— 由 golden LoadQueueRAR.sv 的端口表生成：
#    1) rtl/memblock/LoadQueueRAR_wrapper.sv  —— golden 同名扁平端口 → 例化可读核（FM/ST 用）
#    2) verif/ut/LoadQueueRAR/variants_xs.sv  —— _xs 镜像（同 wrapper，UT 用，模块名 LoadQueueRAR_xs）
#    3) verif/ut/LoadQueueRAR/tb.sv           —— golden u_g vs _xs u_i 双例化逐拍比对所有输出
#
#  端口与 golden 完全一致；wrapper/_xs 内部把 3 个 query 口的扁平信号机械打包成核的
#  struct 数组端口。核（xs_LoadQueueRAR_core）实现全部逻辑（含内联 freelist / paddr CAM）。
# =============================================================================
import re, os

ROOT   = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
GOLDEN = os.path.join(ROOT, "golden", "chisel-rtl", "LoadQueueRAR.sv")
LDW    = 3   # LoadPipelineWidth

def parse_ports(path):
    txt = open(path).read()
    m = re.search(r"module LoadQueueRAR\((.*?)\n\);", txt, re.S)
    body = m.group(1)
    ports = []  # (dir, width, name)
    for ln in body.splitlines():
        ln = ln.strip().rstrip(",")
        mm = re.match(r"(input|output)\s+(\[[0-9]+:[0-9]+\]\s+)?(\w+)", ln)
        if not mm:
            continue
        d = mm.group(1)
        w = (mm.group(2) or "").strip()
        n = mm.group(3)
        ports.append((d, w, n))
    return ports

PORTS = parse_ports(GOLDEN)

def decl(d, w, n):
    return f"  {d} {w+' ' if w else ''}{n}"

# ---- core 端口连接：把扁平 io_* 打包成核的数组端口 -------------------------------
def core_inst(inst):
    # 组装每个 query 口的 packed 表达式
    def pack(sig_per_w, width=None):
        # sig_per_w(w) -> expression
        items = ", ".join(sig_per_w(LDW-1-w) for w in range(LDW))  # MSB..LSB 高位是口2
        return "{" + items + "}"
    lines = []
    lines.append(f"  xs_LoadQueueRAR_core u_core (")
    lines.append("    .clock  (clock),")
    lines.append("    .reset  (reset),")
    lines.append("    .redirect_valid (io_redirect_valid),")
    lines.append("    .redirect_robIdx('{flag:io_redirect_bits_robIdx_flag, value:io_redirect_bits_robIdx_value}),")
    lines.append("    .redirect_level (io_redirect_bits_level),")
    # query req/resp packed buses
    lines.append("    .q_req_valid      ({io_query_2_req_valid, io_query_1_req_valid, io_query_0_req_valid}),")
    lines.append("    .q_req_robIdx     ({q2_robIdx, q1_robIdx, q0_robIdx}),")
    lines.append("    .q_req_lqIdx      ({q2_lqIdx, q1_lqIdx, q0_lqIdx}),")
    lines.append("    .q_req_paddr      ({io_query_2_req_bits_paddr, io_query_1_req_bits_paddr, io_query_0_req_bits_paddr}),")
    lines.append("    .q_req_data_valid ({io_query_2_req_bits_data_valid, io_query_1_req_bits_data_valid, io_query_0_req_bits_data_valid}),")
    lines.append("    .q_req_is_nc      ({io_query_2_req_bits_is_nc, io_query_1_req_bits_is_nc, io_query_0_req_bits_is_nc}),")
    lines.append("    .q_revoke         ({io_query_2_revoke, io_query_1_revoke, io_query_0_revoke}),")
    lines.append("    .q_req_ready          (q_req_ready),")
    lines.append("    .q_resp_valid         (q_resp_valid),")
    lines.append("    .q_resp_rep_frm_fetch (q_resp_rep),")
    lines.append("    .release_valid (io_release_valid),")
    lines.append("    .release_paddr (io_release_bits_paddr),")
    lines.append("    .ldWbPtr      ('{flag:io_ldWbPtr_flag, value:io_ldWbPtr_value}),")
    lines.append("    .lqFull       (io_lqFull),")
    lines.append("    .validCount   (io_validCount),")
    lines.append("    .perf_enq           (perf0),")
    lines.append("    .perf_ldld_violation(perf1)")
    lines.append("  );")
    return "\n".join(lines)

ADAPT = """
  import loadqueuerar_pkg::*;
  // 把扁平 query uop 指针机械打包成核的 {flag,value} struct
  rob_ptr_t q0_robIdx, q1_robIdx, q2_robIdx;
  lq_ptr_t  q0_lqIdx,  q1_lqIdx,  q2_lqIdx;
  assign q0_robIdx = '{flag:io_query_0_req_bits_uop_robIdx_flag, value:io_query_0_req_bits_uop_robIdx_value};
  assign q1_robIdx = '{flag:io_query_1_req_bits_uop_robIdx_flag, value:io_query_1_req_bits_uop_robIdx_value};
  assign q2_robIdx = '{flag:io_query_2_req_bits_uop_robIdx_flag, value:io_query_2_req_bits_uop_robIdx_value};
  assign q0_lqIdx  = '{flag:io_query_0_req_bits_uop_lqIdx_flag,  value:io_query_0_req_bits_uop_lqIdx_value};
  assign q1_lqIdx  = '{flag:io_query_1_req_bits_uop_lqIdx_flag,  value:io_query_1_req_bits_uop_lqIdx_value};
  assign q2_lqIdx  = '{flag:io_query_2_req_bits_uop_lqIdx_flag,  value:io_query_2_req_bits_uop_lqIdx_value};

  logic [2:0] q_req_ready, q_resp_valid, q_resp_rep;
  logic [1:0] perf0, perf1;

  assign io_query_0_req_ready = q_req_ready[0];
  assign io_query_1_req_ready = q_req_ready[1];
  assign io_query_2_req_ready = q_req_ready[2];
  assign io_query_0_resp_valid = q_resp_valid[0];
  assign io_query_1_resp_valid = q_resp_valid[1];
  assign io_query_2_resp_valid = q_resp_valid[2];
  assign io_query_0_resp_bits_rep_frm_fetch = q_resp_rep[0];
  assign io_query_1_resp_bits_rep_frm_fetch = q_resp_rep[1];
  assign io_query_2_resp_bits_rep_frm_fetch = q_resp_rep[2];
  // perf：golden 输出 [5:0] = {4'h0, 2-bit count}
  assign io_perf_0_value = {4'h0, perf0};
  assign io_perf_1_value = {4'h0, perf1};
"""

def gen_module(modname):
    out = []
    out.append("// 自动生成：scripts/gen_loadqueuerar.py —— 勿手改")
    out.append(f"module {modname}(")
    out.append(",\n".join(decl(d,w,n) for d,w,n in PORTS))
    out.append(");")
    out.append(ADAPT)
    out.append(core_inst(modname))
    out.append("endmodule")
    return "\n".join(out)

# ---------------- tb ----------------
def gen_tb():
    inputs  = [(w,n) for d,w,n in PORTS if d=="input"  and n not in ("clock","reset")]
    outputs = [(w,n) for d,w,n in PORTS if d=="output"]
    L = []
    L.append("// 自动生成：scripts/gen_loadqueuerar.py —— 勿手改")
    L.append("`timescale 1ns/1ps")
    L.append("module tb;")
    L.append("  int unsigned NCYCLES = 200000;")
    L.append("  bit clk = 0, rst;")
    L.append("  int errors = 0, checks = 0;")
    L.append("  always #5 clk = ~clk;")
    L.append("")
    for w,n in inputs:
        L.append(f"  logic {w+' ' if w else ''}{n};")
    for w,n in outputs:
        L.append(f"  wire {w+' ' if w else ''}g_{n};")
        L.append(f"  wire {w+' ' if w else ''}i_{n};")
    L.append("")
    # instantiate golden
    def inst(name, pfx):
        s = [f"  LoadQueueRAR{'' if name=='g' else '_xs'} u_{name} ("]
        s.append("    .clock(clk), .reset(rst),")
        conns = []
        for d,w,n in PORTS:
            if n in ("clock","reset"): continue
            if d=="input":  conns.append(f"    .{n}({n})")
            else:           conns.append(f"    .{n}({pfx}{n})")
        s.append(",\n".join(conns))
        s.append("  );")
        return "\n".join(s)
    L.append(inst("g","g_"))
    L.append(inst("i","i_"))
    L.append("")
    # random drive: keep ldWbPtr/release/redirect plausible; queries random
    L.append("""  // 随机激励：以 freelist 自然推进为前提随机驱动 query/release/redirect/ldWbPtr。
  // robIdx/lqIdx 用受限随机（小范围）以让违例/出队条件较易命中，提升覆盖。
  task automatic drive();
    io_redirect_valid = ($urandom_range(0,15)==0);
    io_redirect_bits_robIdx_flag = $urandom;
    io_redirect_bits_robIdx_value = $urandom_range(0,40);
    io_redirect_bits_level = $urandom;
    for (int w=0; w<3; w++) begin
    end
    io_query_0_req_valid = $urandom_range(0,1);
    io_query_1_req_valid = $urandom_range(0,1);
    io_query_2_req_valid = $urandom_range(0,1);
    io_query_0_req_bits_uop_robIdx_flag = $urandom;
    io_query_1_req_bits_uop_robIdx_flag = $urandom;
    io_query_2_req_bits_uop_robIdx_flag = $urandom;
    io_query_0_req_bits_uop_robIdx_value = $urandom_range(0,40);
    io_query_1_req_bits_uop_robIdx_value = $urandom_range(0,40);
    io_query_2_req_bits_uop_robIdx_value = $urandom_range(0,40);
    io_query_0_req_bits_uop_lqIdx_flag = $urandom;
    io_query_1_req_bits_uop_lqIdx_flag = $urandom;
    io_query_2_req_bits_uop_lqIdx_flag = $urandom;
    io_query_0_req_bits_uop_lqIdx_value = $urandom_range(0,80);
    io_query_1_req_bits_uop_lqIdx_value = $urandom_range(0,80);
    io_query_2_req_bits_uop_lqIdx_value = $urandom_range(0,80);
    // paddr：限制在少数 cacheline 上，提高地址匹配/违例命中率
    io_query_0_req_bits_paddr = {$urandom_range(0,7), 6'($urandom)} << 0 | ($urandom_range(0,3)<<6);
    io_query_1_req_bits_paddr = ($urandom_range(0,7)<<6) | $urandom_range(0,63);
    io_query_2_req_bits_paddr = ($urandom_range(0,7)<<6) | $urandom_range(0,63);
    io_query_0_req_bits_data_valid = $urandom;
    io_query_1_req_bits_data_valid = $urandom;
    io_query_2_req_bits_data_valid = $urandom;
    io_query_0_req_bits_is_nc = ($urandom_range(0,7)==0);
    io_query_1_req_bits_is_nc = ($urandom_range(0,7)==0);
    io_query_2_req_bits_is_nc = ($urandom_range(0,7)==0);
    io_query_0_revoke = ($urandom_range(0,7)==0);
    io_query_1_revoke = ($urandom_range(0,7)==0);
    io_query_2_revoke = ($urandom_range(0,7)==0);
    io_release_valid = $urandom_range(0,1);
    io_release_bits_paddr = ($urandom_range(0,7)<<6) | $urandom_range(0,63);
    io_ldWbPtr_flag = $urandom;
    io_ldWbPtr_value = $urandom_range(0,80);
  endtask
""")
    # checker —— WARMUP：跳过复位刚释放后的若干拍，让两侧 perf/resp 等多级延迟流水填满。
    #   golden 的 perf 计数器是 2 级延迟寄存器，复位释放瞬间会保留 1 拍的复位前残值
    #   （firtool 在 +SYNTHESIS 下不随机初始化），属流水填充期，非功能差异。
    L.append("  int warmup = 4;")
    L.append("  always @(posedge clk) if (!rst) begin")
    L.append("    if (warmup > 0) warmup--; else begin")
    L.append("    checks++;")
    for w,n in outputs:
        L.append(f"    if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
        L.append(f"      if(errors<=60) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
    L.append("    end")
    L.append("  end")
    L.append("")
    L.append("""  initial begin
    rst = 1; drive();
    repeat (8) @(posedge clk);
    rst = 0;
    repeat (NCYCLES) begin @(negedge clk); drive(); end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule""")
    return "\n".join(L)

if __name__ == "__main__":
    wrapper = gen_module("LoadQueueRAR")
    xs      = gen_module("LoadQueueRAR_xs")
    open(os.path.join(ROOT,"rtl","memblock","LoadQueueRAR_wrapper.sv"),"w").write(wrapper+"\n")
    vdir = os.path.join(ROOT,"verif","ut","LoadQueueRAR")
    os.makedirs(vdir, exist_ok=True)
    open(os.path.join(vdir,"variants_xs.sv"),"w").write(xs+"\n")
    open(os.path.join(vdir,"tb.sv"),"w").write(gen_tb()+"\n")
    print("generated wrapper, variants_xs.sv, tb.sv")
