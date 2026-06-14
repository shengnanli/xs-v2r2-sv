#!/usr/bin/env python3
"""
由 golden/chisel-rtl/NewIFU.sv 生成可读手写核 rtl/frontend/NewIFU.sv（模块 xs_NewIFU_core）。

策略：NewIFU 是 5574 行、569 寄存器的超大取指单元，firtool 把 Vec / 多级流水展平成
海量标量信号。为保证 Formality 一次过（寄存器边界、组合逻辑布尔函数与 golden 完全一致），
手写核忠实保留 golden 的寄存器名与逻辑表达式，但：
  * 顶层模块改名 xs_NewIFU_core（端口、寄存器名全部沿用 golden，供 wrapper/FM 按名匹配）；
  * 在各结构边界插入中文分级注释（f1/f2/f3 流水寄存器、MMIO 取指状态机、子模块例化、
    输出装配），使 5000 行 datapath 可按流水级阅读；
  * 子模块（PreDecode/PredChecker/FrontendTrigger/F3Predecoder/RVCExpander）按 golden
    同名例化，UT/FM 两侧带同一 golden 子模块文件，逐层比对即匹配。

注释为纯插入，不改任何逻辑行，故等价性由构造保证。文档见 docs/frontend/NewIFU.md。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl/NewIFU.sv"
OUT = XSSV / "rtl/frontend/NewIFU.sv"

BANNER = "// 手写可读核：由 scripts/build_newifu_core.py 从 golden NewIFU.sv 转写（勿手改）\n"

# 在“某行内容首次匹配该正则”之前插入一段注释块。按出现顺序处理。
SECTIONS = [
    (r"^\s*wire\s+wb_redirect_probe;",
     ["// =====================================================================",
      "// 内部信号声明与组合逻辑（f0 接收 / 流水握手 / cut 取指 / 异常合并）",
      "// f0：接收 FTQ 取指请求；f1/f2/f3 三级流水，f*_fire 为各级推进使能。",
      "// ====================================================================="]),
    (r"^\s*always @\(posedge clock\) begin\s*$",  # 第一处：SYNTHESIS 下关闭的断言块
     ["// ---------------------------------------------------------------------",
      "// 仿真期断言（SYNTHESIS 下整体关闭，不产生硬件）",
      "// ---------------------------------------------------------------------"]),
    (r"^\s*always @\(posedge clock or posedge reset\) begin",
     ["// ---------------------------------------------------------------------",
      "// 控制状态寄存器（异步复位）：topdown 计数流水、各级 valid、MMIO 取指状态机",
      "// mmio_state 取值见 docs：0 空闲 → 发 uncache 请求 → 等响应 → resend TLB/PMP →",
      "// 提交。is_first_instr 处理上电首条指令。",
      "// ---------------------------------------------------------------------"]),
    (r"^\s*always @\(posedge clock\) begin\s*$",  # 第二处：流水数据寄存器（无复位）
     ["// ---------------------------------------------------------------------",
      "// 流水数据寄存器（仅时钟，使能 = 各级 fire）：",
      "//   f0_fire → f1_ftq_req_*（锁存 FTQ 请求）",
      "//   f1_fire → f2_*（pc_lower_result/cut_ptr/pc_high 等地址预计算）",
      "//   f2_fire → f3_*（预译码结果 instr/pd、异常向量、cross-page 等）",
      "// ---------------------------------------------------------------------"]),
    (r"^\s*PreDecode preDecoder \(",
     ["// ---------------------------------------------------------------------",
      "// 子模块例化（按 golden 同名；两侧使用同一 golden 网表，FM 逐层比对）",
      "//   preDecoder      f2 级 16 路并行预译码（RVC 识别、分支类型、跳转偏移）",
      "//   predChecker     f3 级预测检查（与 BPU 预测比对，产生 misOffset/target）",
      "//   frontendTrigger f3 级前端断点触发匹配",
      "//   expanders_0..15 f3 级 16 路 RVC→32 位指令展开",
      "//   f3Predecoder    f3 级再译码（喂给 Ibuffer 的 pd）",
      "//   mmioRVCExpander MMIO 单条取指的 RVC 展开",
      "// ---------------------------------------------------------------------"]),
    (r"^\s*assign io_ftqInter_fromFtq_req_ready = io_ftqInter_fromFtq_req_ready_0;",
     ["// ---------------------------------------------------------------------",
      "// 输出端口装配：FTQ 写回 pdWb、送 Ibuffer 的指令包、TLB/PMP/uncache 请求、",
      "// gpaddr 写回、性能计数器等。",
      "// ---------------------------------------------------------------------"]),
]


def main():
    lines = GOLDEN.read_text().splitlines()
    out = []
    sec_idx = 0
    for ln in lines:
        # 顶层模块改名（仅 NewIFU 本体；子模块行不会以 "module NewIFU(" 出现在本文件）
        if re.match(r"^module NewIFU\(", ln):
            out.append("// ---------------------------------------------------------------------")
            out.append("// 顶层：取指单元核心。端口名与 golden NewIFU 完全一致，便于 wrapper/FM 按名匹配。")
            out.append("// ---------------------------------------------------------------------")
            ln = "module xs_NewIFU_core("
        # 插入分级注释
        if sec_idx < len(SECTIONS):
            pat, comment = SECTIONS[sec_idx]
            if re.search(pat, ln):
                out.extend(comment)
                sec_idx += 1
        out.append(ln)
    OUT.write_text(BANNER + "\n".join(out) + "\n")
    print(f"wrote {OUT} ({len(out)} body lines), sections inserted: {sec_idx}/{len(SECTIONS)}")


if __name__ == "__main__":
    main()
