#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
gen_decodestage.py —— 香山 V2R2 DecodeStage 互联层生成脚本（端口/实例机械展开）

DecodeStage 是后端译码级：前端 IBuffer 每拍送 DecodeWidth(=6) 条已展开指令，本级
把它们并行送 6 个简单译码器 DecodeUnit；其中需要拆 uop 的复杂指令（向量等）择一
送复杂译码器 DecodeUnitComp；VTypeGen 维护向量 vtype 并旁路给各译码器。本级真正
手写的是 glue：复杂/简单结果路由汇聚、流水握手与反压、重定向冲刷、RAT 读口地址、
非法指令上报 CSR、性能事件。这三类子模块（DecodeUnit ×6 / DecodeUnitComp /
VTypeGen 及其传递闭包）全部作 golden 黑盒（UT/FM 两侧共用同一份 golden 定义）。

可读核 xs_DecodeStage_core（手写，见 rtl/backend/DecodeStage.sv）用 decoded_inst_t
等 struct 表达「按指令/按通道」的结构化逻辑。本脚本只负责把 golden 上百根扁平
io_*_bits_* 端口与黑盒实例的扁平引脚，机械地与可读核的 struct 字段对接，生成：

  decodestage_core_ports.svh —— 可读核的扁平端口表（顶层同名，便于 wrapper 直连）
  decodestage_unpack.svh     —— 扁平输入 → 输入 struct；输出 struct 字段 → 扁平输出
  decodestage_decoders.svh   —— 6 个 DecodeUnit 简单译码器实例
  decodestage_comp.svh       —— DecodeUnitComp 复杂译码器实例
  decodestage_vtypegen.svh   —— VTypeGen 实例
  DecodeStage_wrapper.sv     —— golden 同名 wrapper（扁平端口 → 例化可读核）

可读核本体（流水控制 / 路由 / fusion glue）见 rtl/backend/DecodeStage.sv。
公共类型见 rtl/backend/decodestage_pkg.sv。
"""
import re
from pathlib import Path

ROOT   = Path(__file__).resolve().parent.parent
GOLDEN = ROOT / "golden/chisel-rtl"
GSV    = (GOLDEN / "DecodeStage.sv").read_text()
OUT    = ROOT / "rtl/backend"

DW = 6  # DecodeWidth

# ----------------------------------------------------------------------------
# 1. 顶层端口解析（保留方向 / 位宽 / 名字）
# ----------------------------------------------------------------------------
def top_ports():
    m = re.search(r"^module DecodeStage\(\n(.*?)\n\);", GSV, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            w = int(pm.group(2)) + 1 if pm.group(2) else 1
            res.append((pm.group(1), w, pm.group(3)))
    return res

PORTS = top_ports()

def decl(dir_, w, name):
    rng = f"[{w-1}:0] " if w > 1 else ""
    pad = "" if w > 1 else "      "
    return f"  {dir_} {pad if dir_=='input' else pad}{rng}{name}"

# ----------------------------------------------------------------------------
# 2. decoded_inst_t 字段表（名字, 位宽, 是否 packed-array 元素）
#    与 decodestage_pkg.sv 的 decoded_inst_t 一一对应。golden 把 srcType/lsrc/
#    exceptionVec 展平成 _0.._N，这里给出 struct 字段名与 golden 后缀的映射。
# ----------------------------------------------------------------------------
# golden 扁平后缀 -> (struct 表达式生成函数)；struct 实例名为 inst
# 普通标量字段：后缀直接是字段名
SCALAR_FIELDS = [
    ("instr",32),("foldpc",10),("isFetchMalAddr",1),("trigger",4),
    ("preDecodeInfo_isRVC",1),("preDecodeInfo_brType",2),("pred_taken",1),
    ("crossPageIPFFix",1),("ftqPtr_flag",1),("ftqPtr_value",6),("ftqOffset",4),
    ("ldest",6),("fuType",35),("fuOpType",9),("selImm",4),("imm",22),
    ("rfWen",1),("fpWen",1),("vecWen",1),("v0Wen",1),("vlWen",1),
    ("isXSTrap",1),("waitForward",1),("blockBackward",1),("flushPipe",1),
    ("canRobCompress",1),("vlsInstr",1),("wfflags",1),("isMove",1),("isVset",1),
    ("fpu_typeTagOut",2),("fpu_wflags",1),("fpu_typ",2),("fpu_fmt",2),("fpu_rm",3),
    ("vpu_vill",1),("vpu_vma",1),("vpu_vta",1),("vpu_vsew",2),("vpu_vlmul",3),
    ("vpu_specVill",1),("vpu_specVma",1),("vpu_specVta",1),("vpu_specVsew",2),
    ("vpu_specVlmul",3),("vpu_vm",1),("vpu_vstart",8),
    ("vpu_fpu_isFoldTo1_2",1),("vpu_fpu_isFoldTo1_4",1),("vpu_fpu_isFoldTo1_8",1),
    ("vpu_nf",3),("vpu_veew",2),("vpu_isExt",1),("vpu_isNarrow",1),
    ("vpu_isDstMask",1),("vpu_isOpMask",1),("vpu_isDependOldVd",1),
    ("vpu_isWritePartVd",1),("vpu_isVleff",1),("vpu_isReverse",1),
    ("uopIdx",7),("uopSplitType",6),("firstUop",1),("lastUop",1),
    ("numWB",7),("commitType",3),
]
# struct 字段名 -> golden 后缀里的实际写法（这里 struct 字段名即等于 golden 后缀，
# 但 fpu_*/vpu_* 在 struct 里就是 fpu_x/vpu_x，golden 后缀也是 fpu_x/vpu_x，直接相等）

# 数组字段：(struct 名, golden 后缀前缀, 元素数, 元素位宽)
ARRAY_FIELDS = [
    ("srcType", "srcType", 5, 4),
    ("lsrc",    "lsrc",    3, 6),
]
EXC_BITS = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23]

# 简单译码器 (DecodeUnit) io_deq 没有这些字段（本级补常量 / 复杂译码器才有）
SIMPLE_MISSING = {"uopIdx","firstUop","lastUop","numWB","v0Wen","vlWen",
                  "vpu_fpu_isFoldTo1_2","vpu_fpu_isFoldTo1_4","vpu_fpu_isFoldTo1_8"}


def field_to_struct(struct, suffix):
    """golden 后缀 suffix -> 可读核 struct 表达式。"""
    m = re.match(r"exceptionVec_(\d+)$", suffix)
    if m:
        return f"{struct}.exceptionVec[{m.group(1)}]"
    m = re.match(r"srcType_(\d+)$", suffix)
    if m:
        return f"{struct}.srcType[{m.group(1)}]"
    m = re.match(r"lsrc_(\d+)$", suffix)
    if m:
        return f"{struct}.lsrc[{m.group(1)}]"
    return f"{struct}.{suffix}"


# 收集 golden io_out_0_bits_* 的全部后缀（= DecodedInst 的输出字段集合，含顺序）
def out_field_suffixes():
    res = []
    for d, w, n in PORTS:
        m = re.match(r"io_out_0_bits_(.+)$", n)
        if m:
            res.append((m.group(1), w))
    return res

OUT_SUFFIXES = out_field_suffixes()


# 收集 DecodeUnit (decoders_0) io_deq_decodedInst_* 的后缀集合
def decoder_deq_suffixes():
    blk = re.search(r"DecodeUnit decoders_0 \((.*?)\n  \);", GSV, re.S)
    txt = blk.group(1)
    res = []
    seen = set()
    for m in re.finditer(r"\.io_deq_decodedInst_(\w+)\b", txt):
        s = m.group(1)
        if s not in seen:
            seen.add(s); res.append(s)
    return res

DEQ_SUFFIXES = decoder_deq_suffixes()


# ----------------------------------------------------------------------------
# 3. 生成可读核端口表 svh（顶层同名扁平端口）
# ----------------------------------------------------------------------------
def gen_core_ports():
    lines = ["// 由 scripts/gen_decodestage.py 生成：可读核 xs_DecodeStage_core 的扁平端口",
             "// （与 golden DecodeStage 端口同名同向同宽，供顶层 wrapper 直连）"]
    body = []
    for d, w, n in PORTS:
        body.append(decl(d, w, n))
    lines.append(",\n".join(body))
    (OUT / "decodestage_core_ports.svh").write_text("\n".join(lines) + "\n")


# ----------------------------------------------------------------------------
# 4. 生成 unpack svh：扁平输入端口 → 输入 struct；输出 struct → 扁平输出端口
# ----------------------------------------------------------------------------
def gen_unpack():
    L = []
    L.append("// 由 scripts/gen_decodestage.py 生成：扁平端口 <-> 可读核 struct 的拆装。")
    L.append("// 上半：前端 io_in[i] 扁平输入 -> ctrlFlow struct（喂给简单译码器实例）。")
    L.append("// 下半：可读核算出的 out_inst[i] / 控制信号 -> 扁平输出端口。")
    L.append("")
    # ---- 4.1 io_in[i] -> in_ctrl[i] (StaticInst -> 仅 ctrlFlow 字段) ----
    # 简单译码器的 ctrlFlow 直接来自 io_in_i_bits_*；这里不建 struct，实例 svh 直接连
    # io_in。out 输出则需要从 out_inst[i] 拆。
    # ---- 4.2 out_inst[i] -> io_out_i_bits_* ----
    # 输出端口里有些是 glue 计算后的（valid/ready/lsrc/srcType/v0Wen/vecWen 等），
    # 这些不走 out_inst，由核内单独 assign。其余 bits 字段从 out_inst[i] 直接拆。
    GLUE_OUT = {"lsrc_0","lsrc_1","srcType_0","srcType_1","srcType_3","v0Wen","vecWen"}
    for i in range(DW):
        L.append(f"  // ---- 通道 {i}：out_inst[{i}] -> io_out_{i}_bits_* ----")
        L.append(f"  assign io_out_{i}_valid = out_valid[{i}];")
        for suf, w in OUT_SUFFIXES:
            if suf in GLUE_OUT:
                continue  # 由核内 glue assign（反序交换 / V0 修正 / vecWen 拆分）
            expr = field_to_struct(f"out_inst[{i}]", suf)
            L.append(f"  assign io_out_{i}_bits_{suf} = {expr};")
        # glue 输出（在核内已算好 readable 信号 out_lsrc0/1、out_srcType0/1/3、
        # out_v0Wen、out_vecWen），这里接到端口
        L.append(f"  assign io_out_{i}_bits_lsrc_0   = out_lsrc0[{i}];")
        L.append(f"  assign io_out_{i}_bits_lsrc_1   = out_lsrc1[{i}];")
        L.append(f"  assign io_out_{i}_bits_srcType_0 = out_srcType0[{i}];")
        L.append(f"  assign io_out_{i}_bits_srcType_1 = out_srcType1[{i}];")
        L.append(f"  assign io_out_{i}_bits_srcType_3 = out_srcType3[{i}];")
        L.append(f"  assign io_out_{i}_bits_v0Wen     = out_v0Wen[{i}];")
        L.append(f"  assign io_out_{i}_bits_vecWen    = out_vecWen[{i}];")
        L.append("")
    (OUT / "decodestage_unpack.svh").write_text("\n".join(L) + "\n")


# ----------------------------------------------------------------------------
# 5. 生成 6 个 DecodeUnit 简单译码器实例
#    输入 ctrlFlow 直接连 io_in_i_*；vtype 连可读核 vtype 信号；csrCtrl/fromCSR
#    连顶层；输出 io_deq_decodedInst_* 接到核内 simple[i] struct 字段、isComplex/
#    uopInfo 接到 simple_isComplex[i]/simple_uop[i]。
# ----------------------------------------------------------------------------
def parse_inst_ports(modname, instname):
    blk = re.search(rf"{modname} {instname} \((.*?)\n  \);", GSV, re.S)
    txt = blk.group(1)
    ports = []
    for m in re.finditer(r"\.(\w+)\s*\(", txt):
        ports.append(m.group(1))
    return ports

def gen_decoders():
    L = ["// 由 scripts/gen_decodestage.py 生成：6 个 DecodeUnit 简单译码器实例（golden 黑盒）。",
         "// ctrlFlow 直连前端 io_in[i]；vtype 取可读核 VTypeGen 输出 vt；csrCtrl/fromCSR",
         "// 直连顶层；译码结果写入核内 simple[i] struct 与 simple_isComplex[i]/simple_uop[i]。"]
    ports0 = parse_inst_ports("DecodeUnit", "decoders_0")
    for i in range(DW):
        L.append(f"  DecodeUnit decoders_{i} (")
        conns = []
        for p in ports0:
            conns.append(f"    .{p:<40}({decoder_conn(p, i)})")
        L.append(",\n".join(conns))
        L.append("  );")
        L.append("")
    (OUT / "decodestage_decoders.svh").write_text("\n".join(L) + "\n")

def decoder_conn(p, i):
    # ctrlFlow 输入
    m = re.match(r"io_enq_ctrlFlow_(.+)$", p)
    if m:
        return f"io_in_{i}_bits_{m.group(1)}"
    if p == "io_enq_vstart":
        return "io_vstart"
    m = re.match(r"io_enq_vtype_(\w+)$", p)
    if m:
        return f"vt.{m.group(1)}"
    if p == "io_csrCtrl_singlestep":
        return "io_csrCtrl_singlestep"
    m = re.match(r"io_fromCSR_(.+)$", p)
    if m:
        return f"io_fromCSR_{m.group(1)}"
    # 输出 isComplex / uopInfo
    if p == "io_deq_isComplex":
        return f"simple_isComplex[{i}]"
    m = re.match(r"io_deq_uopInfo_(\w+)$", p)
    if m:
        return f"simple_uop[{i}].{m.group(1)}"
    # 输出 decodedInst 字段
    m = re.match(r"io_deq_decodedInst_(.+)$", p)
    if m:
        return field_to_struct(f"simple[{i}]", m.group(1))
    raise RuntimeError("unknown decoder port "+p)


# ----------------------------------------------------------------------------
# 6. 生成 DecodeUnitComp 复杂译码器实例
#    输入 simpleDecodedInst / uopInfo 取核内择一信号 comp_in_inst / comp_in_uop；
#    握手 in.valid=comp_in_valid、in.ready=comp_in_ready、complexNum=complex_num；
#    输出 complexDecodedInsts_j 写入核内 complex[j] struct，valid 写 complex_valid_o[j]，
#    ready 连 io_out_j_ready。
# ----------------------------------------------------------------------------
def gen_comp():
    L = ["// 由 scripts/gen_decodestage.py 生成：DecodeUnitComp 复杂译码器实例（golden 黑盒）。",
         "// 输入取核内 PriorityMux 选出的复杂指令 comp_in_inst / comp_in_uop（见核体）；",
         "// 输出 6 路 complexDecodedInsts 写入核内 complex[j] struct。"]
    ports = parse_inst_ports("DecodeUnitComp", "decoderComp")
    L.append("  DecodeUnitComp decoderComp (")
    conns = []
    for p in ports:
        conns.append(f"    .{p:<44}({comp_conn(p)})")
    L.append(",\n".join(conns))
    L.append("  );")
    (OUT / "decodestage_comp.svh").write_text("\n".join(L) + "\n")

def comp_conn(p):
    if p == "clock": return "clock"
    if p == "reset": return "reset"
    if p == "io_redirect": return "io_redirect"
    m = re.match(r"io_vtypeBypass_(\w+)$", p)
    if m: return f"vt.{m.group(1)}"
    if p == "io_in_ready": return "comp_in_ready"
    if p == "io_in_valid": return "comp_in_valid"
    if p == "io_complexNum": return "complex_num"
    m = re.match(r"io_in_bits_simpleDecodedInst_(.+)$", p)
    if m: return field_to_struct("comp_in_inst", m.group(1))
    m = re.match(r"io_in_bits_uopInfo_(\w+)$", p)
    if m: return f"comp_in_uop.{m.group(1)}"
    # outputs
    m = re.match(r"io_out_complexDecodedInsts_(\d+)_valid$", p)
    if m: return f"complex_valid_o[{m.group(1)}]"
    m = re.match(r"io_out_complexDecodedInsts_(\d+)_ready$", p)
    if m: return f"io_out_{m.group(1)}_ready"
    m = re.match(r"io_out_complexDecodedInsts_(\d+)_bits_(.+)$", p)
    if m:
        j, suf = m.group(1), m.group(2)
        return field_to_struct(f"complex[{j}]", suf)
    raise RuntimeError("unknown comp port "+p)


# ----------------------------------------------------------------------------
# 7. 生成 VTypeGen 实例
# ----------------------------------------------------------------------------
def gen_vtypegen():
    L = ["// 由 scripts/gen_decodestage.py 生成：VTypeGen 实例（golden 黑盒）。",
         "// 监听 6 条入口指令更新 vtype；canUpdateVType 由核给出；输出 vtype 写核内 vt。"]
    ports = parse_inst_ports("VTypeGen", "vtypeGen")
    L.append("  VTypeGen vtypeGen (")
    conns = []
    for p in ports:
        conns.append(f"    .{p:<36}({vtype_conn(p)})")
    L.append(",\n".join(conns))
    L.append("  );")
    (OUT / "decodestage_vtypegen.svh").write_text("\n".join(L) + "\n")

def vtype_conn(p):
    if p == "clock": return "clock"
    if p == "reset": return "reset"
    m = re.match(r"io_insts_(\d+)_valid$", p)
    if m: return f"io_in_{m.group(1)}_valid"
    m = re.match(r"io_insts_(\d+)_bits$", p)
    if m: return f"io_in_{m.group(1)}_bits_instr"
    if p == "io_walkToArchVType": return "io_fromRob_walkToArchVType"
    if p == "io_walkVType_valid": return "io_fromRob_walkVType_valid"
    m = re.match(r"io_walkVType_bits_(\w+)$", p)
    if m: return f"io_fromRob_walkVType_bits_{m.group(1)}"
    if p == "io_canUpdateVType": return "can_update_vtype"
    m = re.match(r"io_vtype_(\w+)$", p)
    if m: return f"vt.{m.group(1)}"
    m = re.match(r"io_vsetvlVType_(\w+)$", p)
    if m: return f"io_vsetvlVType_{m.group(1)}"
    if p == "io_commitVType_vtype_valid": return "io_fromRob_commitVType_vtype_valid"
    m = re.match(r"io_commitVType_vtype_bits_(\w+)$", p)
    if m: return f"io_fromRob_commitVType_vtype_bits_{m.group(1)}"
    if p == "io_commitVType_hasVsetvl": return "io_fromRob_commitVType_hasVsetvl"
    raise RuntimeError("unknown vtypegen port "+p)


# ----------------------------------------------------------------------------
# 7b. 生成 RAT 读口接出 svh（int 2 源 / fp 3 源 / vec 3 源；地址零扩展，hold=~ready）
#     addr 用「融合/反序后」的 lsrc：口 0->out_lsrc0、口 1->out_lsrc1、口 2->lsrc[2]。
# ----------------------------------------------------------------------------
def gen_rat():
    L = ["// 由 scripts/gen_decodestage.py 生成：RAT(重命名别名表) 读口地址 / hold 接出。",
         "// addr 端口按各自逻辑寄存器编号空间定宽，仅低 6 位有效(=lsrc)，高位补 0。",
         "// hold = ~out_ready（下游 Rename 未就绪时保持地址）。口 0/1 用反序后 lsrc。"]
    # (前缀, 总位宽, 源数)
    rats = [("intRat", 32, 2), ("fpRat", 34, 3), ("vecRat", 47, 3)]
    for i in range(DW):
        for pre, w, n in rats:
            pad = w - 6
            for k in range(n):
                if k == 0:
                    addr_src = f"out_lsrc0[{i}]"
                elif k == 1:
                    addr_src = f"out_lsrc1[{i}]"
                else:
                    addr_src = f"final_inst[{i}].lsrc[{k}]"
                L.append(f"  assign io_{pre}_{i}_{k}_hold = ~out_ready[{i}];")
                L.append(f"  assign io_{pre}_{i}_{k}_addr = {{{pad}'h0, {addr_src}}};")
    (OUT / "decodestage_rat.svh").write_text("\n".join(L) + "\n")


# ----------------------------------------------------------------------------
# 7c. 生成 stallReason out.reason 接出 svh
# ----------------------------------------------------------------------------
def gen_stall():
    L = ["// 由 scripts/gen_decodestage.py 生成：stallReason out.reason[i] 接出。",
         "// out.reason[i] = backReason.valid ? backReason.bits : in.reason[i]（背压回灌）。"]
    for i in range(DW):
        L.append(f"  assign io_stallReason_out_reason_{i} = "
                 f"io_stallReason_out_backReason_valid"
                 f" ? io_stallReason_out_backReason_bits : io_stallReason_in_reason_{i};")
    (OUT / "decodestage_stall.svh").write_text("\n".join(L) + "\n")


# ----------------------------------------------------------------------------
# 8. 生成 golden 同名 wrapper（扁平端口 -> 例化可读核）
# ----------------------------------------------------------------------------
def gen_wrapper():
    L = ["// 由 scripts/gen_decodestage.py 生成：DecodeStage 顶层 wrapper（golden 同名）。",
         "// 机械适配层：扁平端口原样转接给可读核 xs_DecodeStage_core，供 FM/ST 对接。",
         "`include \"decodestage_pkg.sv\"", "",
         "module DecodeStage("]
    body = [decl(d, w, n) for d, w, n in PORTS]
    L.append(",\n".join(body))
    L.append(");")
    L.append("  xs_DecodeStage_core u_core (")
    conns = [f"    .{n}({n})" for d, w, n in PORTS]
    L.append(",\n".join(conns))
    L.append("  );")
    L.append("endmodule")
    (OUT / "DecodeStage_wrapper.sv").write_text("\n".join(L) + "\n")


# ----------------------------------------------------------------------------
# 9. 生成 UT testbench（双例化 golden vs 可读 wrapper，逐拍比对全部输出）
# ----------------------------------------------------------------------------
def gen_tb():
    ins  = [(w, n) for d, w, n in PORTS if d == "input"  and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in PORTS if d == "output"]
    L = []
    L.append("// 由 scripts/gen_decodestage.py 生成：DecodeStage UT testbench。")
    L.append("// 双例化 golden DecodeStage(u_g) 与可读 wrapper DecodeStage(u_i，内部为可读核)，")
    L.append("// 同一随机激励逐拍驱动两侧，比对全部输出端口（!$isunknown(golden) 才比，跳")
    L.append("// don't-care）。入口指令用「合法编码池 + 随机 don't-care 位」混合随机指令，")
    L.append("// 配合随机 valid/ready/redirect/vtype/csr/fromRob/stallReason/fusion，覆盖")
    L.append("// 简单/复杂混合、反压、重定向、vtype 恢复等流水控制路径。")
    L.append("`timescale 1ns/1ps")
    L.append("module tb;")
    L.append("  logic clock = 0; logic reset = 1;")
    L.append("  always #5 clock = ~clock;")
    L.append("")
    # 输入信号声明 + 驱动寄存器
    for w, n in ins:
        rng = f"[{w-1}:0] " if w > 1 else ""
        L.append(f"  logic {rng}{n};")
    L.append("")
    # golden 输出线网 g_*，impl 输出线网 i_*
    for w, n in outs:
        rng = f"[{w-1}:0] " if w > 1 else ""
        L.append(f"  logic {rng}g_{n}; logic {rng}i_{n};")
    L.append("")
    # 例化 golden
    def inst(modname, instname, oprefix):
        s = [f"  {modname} {instname} ("]
        c = ["    .clock(clock)", "    .reset(reset)"]
        for w, n in ins:
            c.append(f"    .{n}({n})")
        for w, n in outs:
            c.append(f"    .{n}({oprefix}{n})")
        s.append(",\n".join(c))
        s.append("  );")
        return "\n".join(s)
    L.append(inst("DecodeStage", "u_g", "g_"))
    L.append("")
    # impl 顶层 wrapper 模块名也是 DecodeStage —— 用配置化绑定避免重名：编译时只能有一个
    # DecodeStage。因此 UT 比对让 golden 用原名，可读核直接例化 xs_DecodeStage_core。
    s = ["  xs_DecodeStage_core u_i ("]
    c = ["    .clock(clock)", "    .reset(reset)"]
    for w, n in ins:
        c.append(f"    .{n}({n})")
    for w, n in outs:
        c.append(f"    .{n}(i_{n})")
    s.append(",\n".join(c))
    s.append("  );")
    L.append("\n".join(s))
    L.append("")
    # 合法指令池
    L.append('`include "legal_instrs.svh"')
    L.append("")
    L.append("  int errors = 0; int checks = 0; int ecnt [string];")
    L.append("  int n_iters = 250000;")
    L.append("  initial if ($value$plusargs(\"ITERS=%d\", n_iters)) ;")
    L.append("  task automatic chk(input string nm, input logic [63:0] g,")
    L.append("                     input logic [63:0] d, input logic gx);")
    L.append("    checks++;")
    L.append("    if (!gx && (g !== d)) begin")
    L.append("      errors++; ecnt[nm]++;")
    L.append("      if (ecnt[nm] <= 4) $display(\"MISMATCH %s g=%h d=%h\", nm, g, d);")
    L.append("    end")
    L.append("  endtask")
    L.append("")
    L.append("  logic [31:0] r; int idx;")
    L.append("  task automatic drive_in(int ch);")
    L.append("    if ($urandom_range(0,99) < 70) begin")
    L.append("      idx = $urandom_range(0, N_LEGAL-1);")
    L.append("      r   = $urandom();")
    L.append("      case (ch)")
    for ch in range(DW):
        L.append(f"        {ch}: io_in_{ch}_bits_instr = LEGAL_MATCH[idx] | (r & ~LEGAL_MASK[idx]);")
    L.append("      endcase")
    L.append("    end else begin")
    for ch in range(DW):
        L.append(f"      if (ch=={ch}) io_in_{ch}_bits_instr = $urandom();")
    L.append("    end")
    L.append("  endtask")
    L.append("")
    L.append("  task automatic randomize_inputs();")
    # 随机化所有输入（instr 单独处理）
    for w, n in ins:
        if "bits_instr" in n:
            continue
        if w == 1:
            L.append(f"    {n} = $urandom_range(0,1);")
        else:
            L.append(f"    {n} = $urandom();")
    L.append("  endtask")
    L.append("")
    # 时序规范：在「时钟下降沿」驱动新输入（远离上升沿，避免与寄存器采样竞争）；
    # 在「上升沿后 #1」比对（让组合逻辑 + 黑盒内部寄存器全部稳定后再采样输出，
    # golden 与可读核两侧采样点一致，消除 delta-cycle 竞争导致的伪 1 拍偏差）。
    L.append("  initial begin")
    L.append("    reset = 1;")
    L.append("    randomize_inputs();")
    for ch in range(DW):
        L.append(f"    io_in_{ch}_bits_instr = 32'h13;")
    L.append("    repeat (4) @(negedge clock);")
    L.append("    reset = 0;")
    L.append("    for (int it = 0; it < n_iters; it++) begin")
    L.append("      // 下降沿驱动新激励")
    L.append("      @(negedge clock);")
    L.append("      randomize_inputs();")
    for ch in range(DW):
        L.append(f"      drive_in({ch});")
    L.append("      // 上升沿后采样比对（寄存器已更新且组合稳定）")
    L.append("      @(posedge clock); #1;")
    # 比对所有输出
    for w, n in outs:
        L.append(f'      chk("{n}", g_{n}, i_{n}, $isunknown(g_{n}));')
    L.append("    end")
    L.append("    foreach (ecnt[k]) $display(\"[errcount] %-44s = %0d\", k, ecnt[k]);")
    L.append("    $display(\"[DecodeStage UT] iters=%0d checks=%0d errors=%0d\", n_iters, checks, errors);")
    L.append("    if (errors == 0) $display(\"TEST PASSED\"); else $display(\"TEST FAILED\");")
    L.append("    $finish;")
    L.append("  end")
    L.append("endmodule")
    (ROOT / "verif/ut/DecodeStage/tb.sv").write_text("\n".join(L) + "\n")


if __name__ == "__main__":
    gen_core_ports()
    gen_unpack()
    gen_decoders()
    gen_comp()
    gen_vtypegen()
    gen_rat()
    gen_stall()
    gen_wrapper()
    gen_tb()
    print("generated: decodestage_core_ports.svh decodestage_unpack.svh "
          "decodestage_decoders.svh decodestage_comp.svh decodestage_vtypegen.svh "
          "DecodeStage_wrapper.sv")
