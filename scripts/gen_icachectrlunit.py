#!/usr/bin/env python3
"""
ICacheCtrlUnit：解析 golden 端口生成
  - rtl/frontend/ICacheCtrlUnit_wrapper.sv：golden 同名顶层 ICacheCtrlUnit，
    例化输入队列(xs_Queue1_RegMapperInput) + 核心(xs_ICacheCtrlUnit_core)，
    在此完成 TileLink A/D 通道与 RegMapper 队列、核心的对接。
  - verif/ut/ICacheCtrlUnit/variants_xs.sv：ICacheCtrlUnit_xs（同结构，供 UT 双例化）。
  - verif/ut/ICacheCtrlUnit/tb.sv：golden vs _xs 双例化、复位后随机激励逐拍比对全部输出。

golden 顶层把 RegMapper 输入队列 Queue1_RegMapperInput_3 例化在内部，A 通道经
  opcode==4'h4 判读、address[6:3] 取 index 后入队；D 通道 valid/source/size 由队列给出，
  opcode/data 在核心/顶层组合产生。故 wrapper 在顶层重建这一对接，逻辑与 golden 一致。
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


def decl_ports(ps):
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    return ",\n".join(decls)


# 顶层例化 body：队列 + 核心 + A/D 通道对接（golden 同构）
BODY = """
  // ---- RegMapper 输入队列（深度 1 skid buffer）：A 通道入队 ----
  wire        q_deq_valid;
  wire        q_deq_bits_read;
  wire [3:0]  q_deq_bits_index;
  wire [63:0] q_deq_bits_data;
  wire [7:0]  q_deq_bits_mask;

  xs_Queue1_RegMapperInput #(
    .INDEX_W(4), .DATA_W(64), .MASK_W(8), .SOURCE_W(3), .SIZE_W(2)
  ) out_back_q (
    .clock                               (clock),
    .reset                               (reset),
    .io_enq_ready                        (auto_in_a_ready),
    .io_enq_valid                        (auto_in_a_valid),
    .io_enq_bits_read                    (auto_in_a_bits_opcode == 4'h4), // Get
    .io_enq_bits_index                   (auto_in_a_bits_address[6:3]),
    .io_enq_bits_data                    (auto_in_a_bits_data),
    .io_enq_bits_mask                    (auto_in_a_bits_mask),
    .io_enq_bits_extra_tlrr_extra_source (auto_in_a_bits_source),
    .io_enq_bits_extra_tlrr_extra_size   (auto_in_a_bits_size),
    .io_deq_ready                        (auto_in_d_ready),
    .io_deq_valid                        (q_deq_valid),
    .io_deq_bits_read                    (q_deq_bits_read),
    .io_deq_bits_index                   (q_deq_bits_index),
    .io_deq_bits_data                    (q_deq_bits_data),
    .io_deq_bits_mask                    (q_deq_bits_mask),
    .io_deq_bits_extra_tlrr_extra_source (auto_in_d_bits_source),
    .io_deq_bits_extra_tlrr_extra_size   (auto_in_d_bits_size)
  );

  // D 通道：valid = 队列有响应；opcode = {3'h0, read}（AccessAck / AccessAckData）
  assign auto_in_d_valid       = q_deq_valid;
  assign auto_in_d_bits_opcode = {3'h0, q_deq_bits_read};

  // ---- 核心 ----
  xs_ICacheCtrlUnit_core #(
    .NWAY(4), .PADDR_W(48), .PTAG_W(36), .VSETIDX_W(8),
    .INDEX_W(4), .DATA_W(64), .MASK_W(8)
  ) u_core (
    .clock                          (clock),
    .reset                          (reset),
    .out_deq_valid                  (q_deq_valid),
    .out_deq_bits_read              (q_deq_bits_read),
    .out_deq_bits_index             (q_deq_bits_index),
    .out_deq_bits_data              (q_deq_bits_data),
    .out_deq_bits_mask              (q_deq_bits_mask),
    .auto_in_d_ready                (auto_in_d_ready),
    .auto_in_d_bits_data            (auto_in_d_bits_data),
    .io_ecc_enable                  (io_ecc_enable),
    .io_injecting                   (io_injecting),
    .io_metaRead_ready              (io_metaRead_ready),
    .io_metaRead_valid              (io_metaRead_valid),
    .io_metaRead_bits_vSetIdx_0     (io_metaRead_bits_vSetIdx_0),
    .io_metaRead_bits_vSetIdx_1     (io_metaRead_bits_vSetIdx_1),
    .io_metaReadResp_metas_0_0_tag  (io_metaReadResp_metas_0_0_tag),
    .io_metaReadResp_metas_0_1_tag  (io_metaReadResp_metas_0_1_tag),
    .io_metaReadResp_metas_0_2_tag  (io_metaReadResp_metas_0_2_tag),
    .io_metaReadResp_metas_0_3_tag  (io_metaReadResp_metas_0_3_tag),
    .io_metaReadResp_entryValid_0_0 (io_metaReadResp_entryValid_0_0),
    .io_metaReadResp_entryValid_0_1 (io_metaReadResp_entryValid_0_1),
    .io_metaReadResp_entryValid_0_2 (io_metaReadResp_entryValid_0_2),
    .io_metaReadResp_entryValid_0_3 (io_metaReadResp_entryValid_0_3),
    .io_metaWrite_ready             (io_metaWrite_ready),
    .io_metaWrite_valid             (io_metaWrite_valid),
    .io_metaWrite_bits_virIdx       (io_metaWrite_bits_virIdx),
    .io_metaWrite_bits_phyTag       (io_metaWrite_bits_phyTag),
    .io_metaWrite_bits_waymask      (io_metaWrite_bits_waymask),
    .io_metaWrite_bits_bankIdx      (io_metaWrite_bits_bankIdx),
    .io_dataWrite_ready             (io_dataWrite_ready),
    .io_dataWrite_valid             (io_dataWrite_valid),
    .io_dataWrite_bits_virIdx       (io_dataWrite_bits_virIdx),
    .io_dataWrite_bits_waymask      (io_dataWrite_bits_waymask)
  );
"""


def emit(modname, ps):
    L = [f"module {modname}(", decl_ports(ps) + "\n);", BODY, "endmodule\n"]
    return "\n".join(L)


def main():
    ps = ports("ICacheCtrlUnit")
    hdr = "// 自动生成：scripts/gen_icachectrlunit.py —— 勿手改\n"

    (XSSV / "rtl/frontend/ICacheCtrlUnit_wrapper.sv").write_text(hdr + emit("ICacheCtrlUnit", ps))
    ut = XSSV / "verif/ut/ICacheCtrlUnit"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit("ICacheCtrlUnit_xs", ps))

    # ---- testbench ----
    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]

    T = ["""// 自动生成：scripts/gen_icachectrlunit.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
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
    T.append(f"  ICacheCtrlUnit    u_g ({', '.join(gg)});")
    T.append(f"  ICacheCtrlUnit_xs u_i ({', '.join(ig)});")

    # 随机激励：
    #   A 通道：随机施加读/写寄存器请求；opcode 偏向 PutFullData(0)/Get(4)；
    #           address[6:3] 取 0/1（命中 eccctrl/ecciaddr），偶发越界；
    #           mask 偏向全 1（合法写要求 &mask）；data 随机但偏置 inject 触发位。
    #   D 通道 ready 随机制造背压；meta/data 读写 ready 随机；metaReadResp 随机但 ptag
    #           压缩值域以提高注入命中率。
    T.append("""  always @(negedge clk) begin
    if (rst) begin
      auto_in_a_valid <= 1'b0;
      auto_in_d_ready <= 1'b0;
      io_metaRead_ready <= 1'b0;
      io_metaWrite_ready <= 1'b0;
      io_dataWrite_ready <= 1'b0;
    end else begin
      auto_in_a_valid        <= ($urandom_range(0,2)!=0);
      // opcode: 0=PutFullData(写), 4=Get(读)；偏向这两者
      auto_in_a_bits_opcode  <= ($urandom_range(0,1)==0) ? 4'h0 : 4'h4;
      auto_in_a_bits_size    <= 2'($urandom);
      auto_in_a_bits_source  <= 3'($urandom);
      // address[6:3] -> index：偏向 0/1，偶发越界到 2..15
      auto_in_a_bits_address <= ($urandom_range(0,7)==0)
                                  ? 30'($urandom)
                                  : {23'($urandom), 1'($urandom_range(0,1)), 3'($urandom)};
      // mask 偏向全 1（合法寄存器写要求 &mask）
      auto_in_a_bits_mask    <= ($urandom_range(0,3)!=0) ? 8'hff : 8'($urandom);
      // data：偏置低 4 位（enable/inject/itarget），高位随机
      auto_in_a_bits_data    <= {32'($urandom), 28'($urandom), 4'($urandom_range(0,15))};
      auto_in_d_ready        <= ($urandom_range(0,2)!=0);
      io_metaRead_ready      <= ($urandom_range(0,1)==0);
      io_metaWrite_ready     <= ($urandom_range(0,1)==0);
      io_dataWrite_ready     <= ($urandom_range(0,1)==0);
      // metaReadResp：ptag 压缩值域以提高 way 命中率
      io_metaReadResp_metas_0_0_tag <= 36'($urandom_range(0,7));
      io_metaReadResp_metas_0_1_tag <= 36'($urandom_range(0,7));
      io_metaReadResp_metas_0_2_tag <= 36'($urandom_range(0,7));
      io_metaReadResp_metas_0_3_tag <= 36'($urandom_range(0,7));
      io_metaReadResp_entryValid_0_0 <= 1'($urandom);
      io_metaReadResp_entryValid_0_1 <= 1'($urandom);
      io_metaReadResp_entryValid_0_2 <= 1'($urandom);
      io_metaReadResp_entryValid_0_3 <= 1'($urandom);
    end
  end""")

    # 比对：复位后每拍在时钟稳定区比对所有输出
    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    #4; checks++;")
    for w, n in outs:
        T.append(f"    if (g_{n} !== i_{n}) begin errors++;")
        T.append(f"      if(errors<=30) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
    T.append("  end")
    T.append("""  initial begin
    rst = 1; repeat (5) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    (ut / "tb.sv").write_text("\n".join(T))
    print(f"ICacheCtrlUnit: {len(ps)} ports, {len(ins)} inputs, {len(outs)} outputs")


if __name__ == "__main__":
    main()
