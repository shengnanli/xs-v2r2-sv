#!/usr/bin/env python3
"""
VirtualLoadQueue：解析 golden 端口生成 wrapper(golden 同名 VirtualLoadQueue)、_xs 镜像、
随机比对 tb。

golden 端口已是逐字段扁平形式（io_enq_req_0_*, io_ldin_1_*, io_vecCommit_*, ...），
本可读核 xs_VirtualLoadQueue_core 把展平的 rep_info_cause_0..10 聚合成 [10:0] 一个端口，
其余端口与核一一同名。故 wrapper / _xs 需要把 11 根 cause 线打包成 [10:0] 总线传给核。

设计意图来自 src/main/scala/xiangshan/mem/lsqueue/VirtualLoadQueue.scala。
本脚本只负责机械端口适配 + 随机激励 tb，可读核本体见 rtl/memblock/VirtualLoadQueue.sv。
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


# rep_info_cause_0..10 (3 个 ldin 口各 11 根) → 核侧聚合成 io_ldin_W_bits_rep_info_cause[10:0]
CAUSE_RE = re.compile(r"^(io_ldin_(\d+)_bits_rep_info_cause)_(\d+)$")


def core_conn(ps):
    """生成 wrapper/_xs 例化核 u_core 的端口连接：cause_0..10 打包成 {cause_10,...,cause_0}。"""
    conns = []
    seen_bus = set()
    for _, _, n in ps:
        m = CAUSE_RE.match(n)
        if m:
            bus = f"{m.group(1)}"  # io_ldin_W_bits_rep_info_cause
            if bus in seen_bus:
                continue
            seen_bus.add(bus)
            pieces = ", ".join(f"{bus}_{b}" for b in range(10, -1, -1))
            conns.append(f"    .{bus}({{{pieces}}})")
        else:
            conns.append(f"    .{n}({n})")
    return conns


def emit(modname, ps):
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    L = [f"module {modname}(", ",\n".join(decls) + "\n);"]
    L.append("  xs_VirtualLoadQueue_core u_core (")
    L.append(",\n".join(core_conn(ps)))
    L.append("  );")
    L.append("endmodule\n")
    return "\n".join(L)


def main():
    ps = ports("VirtualLoadQueue")
    hdr = "// 自动生成：scripts/gen_virtualloadqueue.py —— 勿手改\n"

    (XSSV / "rtl/memblock/VirtualLoadQueue_wrapper.sv").write_text(hdr + emit("VirtualLoadQueue", ps))
    ut = XSSV / "verif/ut/VirtualLoadQueue"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit("VirtualLoadQueue_xs", ps))

    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]

    T = ["""// 自动生成：scripts/gen_virtualloadqueue.py —— 勿手改
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
    T.append(f"  VirtualLoadQueue    u_g ({', '.join(gg)});")
    T.append(f"  VirtualLoadQueue_xs u_i ({', '.join(ig)});")

    # ---- 随机激励 ----
    # VirtualLoadQueue 关键覆盖点：
    #  * enq.req（6 口）：valid 常发；lqIdx 必须与 enqPtrExt 严格一致（否则 golden XSError），
    #    故 tb 自己跟踪 enqPtr 模型，按 enq 协议给出连续 lqIdx + numLsElem，且 needAlloc 对齐。
    #  * ldin（3 口）：writeback 置 committed；lqIdx 在 [0,72) 随机，cause/updateAddrValid/isvec 随机。
    #  * vecCommit（2 口）：向量 commit 置 committed；robidx/uopidx 随机。
    #  * redirect：偶发冲刷，覆盖 needCancel/enqCancel/redirectCancelCount/enqPtr 回退。
    #
    # 入队协议建模：为通过 golden 内 XSError(index.value != lqIdx.value)，tb 维护一个
    # enqPtr 模型（与 DUT 同算法），每拍按 needAlloc/numLsElem 给每个请求口分配连续 lqIdx。

    SIZE = 72
    ENQ_W = 6
    T.append(f"""
  // ---- 入队指针模型（与 VirtualLoadQueue 入队协议一致，保证 lqIdx 合法）----
  localparam int SIZE = {SIZE};
  localparam int ENQW = {ENQ_W};
  int enq_flag, enq_val;                 // enqPtrExt(0) 模型
  int deq_flag, deq_val;                 // deqPtr 模型（近似：跟 golden 输出 ldWbPtr）
  // 本拍各请求口的 numLsElem/needAlloc/valid 决策（先决定再驱动信号）
  int  nls   [ENQW];
  bit  nalloc[ENQW];
  bit  vld   [ENQW];
  bit  rdir;
  int  i;
  int  used;                             // 已分配 flow 累计
  int  base_val, base_flag;
""")

    # 信号名集合
    in_names = {n for _, n in ins}

    # 驱动块：在 negedge 计算 enq 协议 + 随机化其它输入
    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    T.append("      enq_flag<=0; enq_val<=0;")
    for n in ["io_redirect_valid"]:
        if n in in_names:
            T.append(f"      {n} <= 1'b0;")
    for k in range(ENQ_W):
        T.append(f"      io_enq_req_{k}_valid <= 1'b0;")
    for k in range(3):
        T.append(f"      io_ldin_{k}_valid <= 1'b0;")
    for k in range(2):
        T.append(f"      io_vecCommit_{k}_valid <= 1'b0;")
    T.append("    end else begin")
    # redirect 偶发
    T.append("      rdir = ($urandom_range(0,31)==0);")
    T.append("      io_redirect_valid <= rdir;")
    T.append("      io_redirect_bits_robIdx_flag  <= $urandom_range(0,1);")
    T.append("      io_redirect_bits_robIdx_value <= {4'h0, 4'($urandom)};")
    T.append("      io_redirect_bits_level        <= $urandom_range(0,1);")
    # enq 协议：决定每口 valid/numLsElem/needAlloc，按 enqPtr 给连续 lqIdx
    T.append("""
      // 计算每口决策：valid（随机）、numLsElem（1..2）、needAlloc=valid
      used = 0;
      base_val  = enq_val;
      base_flag = enq_flag;
      for (i=0;i<ENQW;i++) begin
        vld[i]    = ($urandom_range(0,1)) && !rdir;  // redirect 拍不入队（贴近 assert）
        nls[i]    = $urandom_range(1,2);
        nalloc[i] = vld[i];
      end
      // 驱动 enq 请求信号：lqIdx = enqPtr(0) + (前面口的 flow 累计)
      for (i=0;i<ENQW;i++) begin
        int lq_v, lq_f, s;
        s = (base_val + used) % SIZE;
        lq_f = base_flag ^ ((base_val + used) >= SIZE);
        lq_v = s;
        io_enq_req_valid_set(i, vld[i]);
        io_enq_req_lqidx_set(i, lq_f, lq_v);
        io_enq_req_nls_set(i, nls[i]);
        if (i < 5) io_enq_needalloc_set(i, nalloc[i]);
        if (vld[i]) used = used + nls[i];
      end
      io_enq_sqCanAccept <= 1'b1;
      // 更新 enqPtr 模型（仅在非 redirect 恢复期近似推进；DUT 自身精确，tb 只需给合法 lqIdx）
      enq_val  = (base_val + used) % SIZE;
      enq_flag = base_flag ^ ((base_val + used) >= SIZE);
""")
    # ldin 随机
    for k in range(3):
        T.append(f"      io_ldin_{k}_valid <= $urandom_range(0,1);")
        T.append(f"      io_ldin_{k}_bits_uop_lqIdx_value <= $urandom_range(0,{SIZE-1});")
        T.append(f"      io_ldin_{k}_bits_isvec <= ($urandom_range(0,3)==0);")
        T.append(f"      io_ldin_{k}_bits_updateAddrValid <= ($urandom_range(0,3)!=0);")
        for c in range(11):
            T.append(f"      io_ldin_{k}_bits_rep_info_cause_{c} <= ($urandom_range(0,15)==0);")
    # vecCommit 随机
    for k in range(2):
        T.append(f"      io_vecCommit_{k}_valid <= $urandom_range(0,1);")
        T.append(f"      io_vecCommit_{k}_bits_robidx_flag <= $urandom_range(0,1);")
        T.append(f"      io_vecCommit_{k}_bits_robidx_value <= {{4'h0, 4'($urandom)}};")
        T.append(f"      io_vecCommit_{k}_bits_uopidx <= 7'($urandom);")
    # enq fuType / uopIdx / robIdx 随机（lqIdx 已由协议驱动）
    for k in range(ENQ_W):
        T.append(f"      io_enq_req_{k}_bits_fuType <= 35'($urandom);")
        T.append(f"      io_enq_req_{k}_bits_uopIdx <= 7'($urandom);")
        T.append(f"      io_enq_req_{k}_bits_robIdx_flag <= $urandom_range(0,1);")
        T.append(f"      io_enq_req_{k}_bits_robIdx_value <= {{4'h0, 4'($urandom)}};")
    T.append("      io_noUopsIssued <= $urandom_range(0,1);")
    T.append("    end")
    T.append("  end")

    # 辅助任务：驱动 enq 请求（用 task 集中，避免在 for 内对不同口的非数组端口赋值）
    T.append("""
  // 把数组下标 i 映射到各扁平 enq 端口
  task io_enq_req_valid_set(int i, bit v);
    case(i)
      0: io_enq_req_0_valid <= v; 1: io_enq_req_1_valid <= v; 2: io_enq_req_2_valid <= v;
      3: io_enq_req_3_valid <= v; 4: io_enq_req_4_valid <= v; 5: io_enq_req_5_valid <= v;
    endcase
  endtask
  task io_enq_req_lqidx_set(int i, bit f, int v);
    case(i)
      0: begin io_enq_req_0_bits_lqIdx_flag<=f; io_enq_req_0_bits_lqIdx_value<=v[6:0]; end
      1: begin io_enq_req_1_bits_lqIdx_flag<=f; io_enq_req_1_bits_lqIdx_value<=v[6:0]; end
      2: begin io_enq_req_2_bits_lqIdx_flag<=f; io_enq_req_2_bits_lqIdx_value<=v[6:0]; end
      3: begin io_enq_req_3_bits_lqIdx_flag<=f; io_enq_req_3_bits_lqIdx_value<=v[6:0]; end
      4: begin io_enq_req_4_bits_lqIdx_flag<=f; io_enq_req_4_bits_lqIdx_value<=v[6:0]; end
      5: begin io_enq_req_5_bits_lqIdx_flag<=f; io_enq_req_5_bits_lqIdx_value<=v[6:0]; end
    endcase
  endtask
  task io_enq_req_nls_set(int i, int n);
    case(i)
      0: io_enq_req_0_bits_numLsElem <= n[4:0]; 1: io_enq_req_1_bits_numLsElem <= n[4:0];
      2: io_enq_req_2_bits_numLsElem <= n[4:0]; 3: io_enq_req_3_bits_numLsElem <= n[4:0];
      4: io_enq_req_4_bits_numLsElem <= n[4:0]; 5: io_enq_req_5_bits_numLsElem <= n[4:0];
    endcase
  endtask
  task io_enq_needalloc_set(int i, bit a);
    case(i)
      0: io_enq_needAlloc_0 <= a; 1: io_enq_needAlloc_1 <= a; 2: io_enq_needAlloc_2 <= a;
      3: io_enq_needAlloc_3 <= a; 4: io_enq_needAlloc_4 <= a;
    endcase
  endtask
""")

    # 比对
    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    #4; checks++;")
    for w, n in outs:
        T.append(f"    if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
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
    print(f"VirtualLoadQueue: {len(ps)} ports, {len(ins)} inputs, {len(outs)} outputs")


if __name__ == "__main__":
    main()
