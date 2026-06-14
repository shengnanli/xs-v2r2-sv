#!/usr/bin/env python3
"""
ICacheMissUnit：解析 golden 端口生成
  - rtl/frontend/ICacheMissUnit_wrapper.sv  (模块名 ICacheMissUnit，golden 同名，FM impl 顶层)
  - verif/ut/ICacheMissUnit/variants_xs.sv  (模块名 ICacheMissUnit_xs，UT 镜像)
  - verif/ut/ICacheMissUnit/tb.sv           (golden vs _xs 双例化逐拍比对)

ICacheMissUnit 端口已是逐字段扁平 io_*，核 xs_ICacheMissUnit_core 端口一一同名，
wrapper / _xs 只是把端口透传给核（u_core）。核为结构化模块，无参数。

该模块为结构化顶层：例化 golden 子模块（DeMultiplexer/DeMultiplexer_1/MuxBundle/
Arbiter5_MSHRAcquire/ICacheMSHR*/FIFOReg）。FM 两侧子模块同名，按名匹配/黑盒一致；
UT 两侧链接同一份 golden 子模块，比对的是顶层连线 + grant 数据通路逻辑。
寄存器名沿用 golden，无需 fm_map。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"

# golden ICacheMissUnit 例化的全部子模块（FM/UT 两侧共用 golden 实现）
SUBMODULES = [
    "DeMultiplexer", "DeMultiplexer_1", "MuxBundle", "Arbiter5_MSHRAcquire",
    "FIFOReg",
    "ICacheMSHR", "ICacheMSHR_1", "ICacheMSHR_2", "ICacheMSHR_3",
    "ICacheMSHR_4", "ICacheMSHR_5", "ICacheMSHR_6", "ICacheMSHR_7",
    "ICacheMSHR_8", "ICacheMSHR_9", "ICacheMSHR_10", "ICacheMSHR_11",
    "ICacheMSHR_12", "ICacheMSHR_13",
]


def ports(name):
    text = (GOLDEN / f"{name}.sv").read_text()
    m = re.search(rf"^module {re.escape(name)}\((.*?)\n\);", text, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return res


def emit(modname, ps):
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    L = [f"module {modname}(", ",\n".join(decls) + "\n);"]
    conns = [f"    .{n}({n})" for _, _, n in ps]
    L.append("  xs_ICacheMissUnit_core u_core (")
    L.append(",\n".join(conns))
    L.append("  );")
    L.append("endmodule\n")
    return "\n".join(L)


def main():
    ps = ports("ICacheMissUnit")
    hdr = "// 自动生成：scripts/gen_icachemissunit.py —— 勿手改\n"

    (XSSV / "rtl/frontend/ICacheMissUnit_wrapper.sv").write_text(hdr + emit("ICacheMissUnit", ps))
    ut = XSSV / "verif/ut/ICacheMissUnit"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit("ICacheMissUnit_xs", ps))

    # ---- testbench ----
    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]

    T = ["""// 自动生成：scripts/gen_icachemissunit.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 80000;
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
    T.append(f"  ICacheMissUnit    u_g ({', '.join(gg)});")
    T.append(f"  ICacheMissUnit_xs u_i ({', '.join(ig)});")

    # ---------------------------------------------------------------------
    # 随机激励：制造 MSHR 分配 + L2 grant 回填 + flush/fencei。
    # - fetch/prefetch req：valid 偶发；地址压缩值域提高去重命中率与 MSHR 复用。
    # - mem_grant：opcode[0]=1（带数据）为主；source 限 0..13；size 偏向多 beat。
    #   注意 refill_done 断言要求 grant 序列规整（每两拍一条 cacheline），
    #   testbench 用一个简单状态保证 grant 按 (beat0, beat1) 配对发送。
    # - victim_way / mem_acquire_ready / wfi 随机。
    # ---------------------------------------------------------------------
    T.append("""
  // grant 节拍模型：保证带数据响应成对出现（beat0 then beat1），避免误触断言
  bit grant_beat;       // 0=下一拍发 beat0, 1=下一拍发 beat1
  logic [3:0] cur_src;  // 当前 cacheline 的 source
  always @(negedge clk) begin
    if (rst) begin
      io_fencei <= 1'b0; io_flush <= 1'b0; io_wfi_wfiReq <= 1'b0;
      io_fetch_req_valid <= 1'b0; io_prefetch_req_valid <= 1'b0;
      io_mem_acquire_ready <= 1'b0; io_victim_way <= 2'b0;
      io_mem_grant_valid <= 1'b0; io_mem_grant_bits_opcode <= 4'h0;
      io_mem_grant_bits_size <= 3'h0; io_mem_grant_bits_source <= 4'h0;
      io_mem_grant_bits_data <= 256'h0; io_mem_grant_bits_corrupt <= 1'b0;
      io_fetch_req_bits_blkPaddr <= 42'h0; io_fetch_req_bits_vSetIdx <= 8'h0;
      io_prefetch_req_bits_blkPaddr <= 42'h0; io_prefetch_req_bits_vSetIdx <= 8'h0;
      grant_beat <= 1'b0; cur_src <= 4'h0;
    end else begin
      // 偶发控制
      io_fencei <= ($urandom_range(0,127)==0);
      io_flush  <= ($urandom_range(0,63)==0);
      io_wfi_wfiReq <= ($urandom_range(0,15)==0);
      io_mem_acquire_ready <= ($urandom_range(0,3)!=0);
      io_victim_way <= 2'($urandom);

      // fetch/prefetch 请求：地址压缩到小值域以增加 MSHR 命中/复用
      io_fetch_req_valid <= ($urandom_range(0,2)!=0);
      io_fetch_req_bits_blkPaddr <= 42'($urandom_range(0,31));
      io_fetch_req_bits_vSetIdx  <= 8'($urandom_range(0,7));
      io_prefetch_req_valid <= ($urandom_range(0,2)!=0);
      io_prefetch_req_bits_blkPaddr <= 42'($urandom_range(0,31));
      io_prefetch_req_bits_vSetIdx  <= 8'($urandom_range(0,7));

      // grant 数据通路：成对 beat
      if (grant_beat == 1'b0) begin
        // 决定是否本拍开始一条新 cacheline
        if ($urandom_range(0,1)==0) begin
          io_mem_grant_valid <= 1'b1;
          io_mem_grant_bits_opcode <= 4'h1;     // 带数据
          io_mem_grant_bits_size <= 3'h6;       // 64B -> 多 beat（refillCycles=2）
          cur_src <= 4'($urandom_range(0,13));
          io_mem_grant_bits_source <= 4'($urandom_range(0,13));
          io_mem_grant_bits_data <= {$urandom,$urandom,$urandom,$urandom,
                                     $urandom,$urandom,$urandom,$urandom};
          io_mem_grant_bits_corrupt <= ($urandom_range(0,7)==0);
          grant_beat <= 1'b1;
        end else begin
          io_mem_grant_valid <= 1'b0;
        end
      end else begin
        // beat1：必发，source 与 beat0 一致
        io_mem_grant_valid <= 1'b1;
        io_mem_grant_bits_opcode <= 4'h1;
        io_mem_grant_bits_size <= 3'h6;
        io_mem_grant_bits_source <= cur_src;
        io_mem_grant_bits_data <= {$urandom,$urandom,$urandom,$urandom,
                                   $urandom,$urandom,$urandom,$urandom};
        io_mem_grant_bits_corrupt <= ($urandom_range(0,7)==0);
        grant_beat <= 1'b0;
      end
    end
  end
""")

    # 比对：复位后每拍在时钟稳定区比对所有输出
    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    #4; checks++;")
    for w, n in outs:
        T.append(f"    if (g_{n} !== i_{n}) begin errors++;")
        T.append(f"      if(errors<=30) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
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
    print(f"ICacheMissUnit: {len(ps)} ports, {len(ins)} inputs, {len(outs)} outputs")
    print("submodules:", " ".join(SUBMODULES))


if __name__ == "__main__":
    main()
