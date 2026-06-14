#!/usr/bin/env python3
# 香山 V2R2 IBuffer 重写工程生成器
#
# 产物:
#   rtl/frontend/IBuffer.sv          手写可读核心  module xs_IBuffer_core
#   rtl/frontend/IBuffer_wrapper.sv  golden 同名包装  module IBuffer (FM impl 顶层)
#   verif/ut/IBuffer/variants_xs.sv  UT 比对包装   module IBuffer_xs
#   verif/ut/IBuffer/tb.sv           双例化逐拍比对 testbench
#   verif/ut/IBuffer/fm_map/IBuffer.txt  (本模块无打包 payload, 留空)
#
# 端口表直接从 golden/chisel-rtl/IBuffer.sv 解析, 保证端口名/位宽与 golden 一致.
#
# IBuffer 参数 (来自 XSCoreParams):
#   IBufSize=48, IBufNBank=6, bankSize=8, DecodeWidth=6, PredictWidth=16
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
GOLDEN = os.path.join(ROOT, "golden", "chisel-rtl", "IBuffer.sv")

# ---------------------------------------------------------------------------
# 1. 解析 golden 端口
# ---------------------------------------------------------------------------
def parse_ports(path):
    ports = []  # (dir, width, name)  width=int bits
    in_hdr = False
    pat = re.compile(r"^\s*(input|output)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)\s*,?\s*$")
    with open(path) as f:
        for line in f:
            s = line.rstrip("\n")
            if not in_hdr:
                if re.match(r"^\s*module\s+IBuffer\b", s):
                    in_hdr = True
                continue
            if s.strip().startswith(");"):
                break
            m = pat.match(s)
            if not m:
                continue
            d = m.group(1)
            hi = m.group(2)
            w = (int(hi) + 1) if hi is not None else 1
            ports.append((d, w, m.group(4)))
    return ports

PORTS = parse_ports(GOLDEN)
INS = [(w, n) for (d, w, n) in PORTS if d == "input" and n not in ("clock", "reset")]
OUTS = [(w, n) for (d, w, n) in PORTS if d == "output"]

# ---------------------------------------------------------------------------
# 2. 手写核心 rtl/frontend/IBuffer.sv (module xs_IBuffer_core)
# ---------------------------------------------------------------------------
IBUF_SIZE = 48
NBANK = 6
BANK_SIZE = IBUF_SIZE // NBANK   # 8
DEC = 6                          # DecodeWidth
PW = 16                          # PredictWidth

# IBufEntry 字段: (名, 宽)  -- 与 golden ibuf_<i>_<field> 对齐
ENTRY_FIELDS = [
    ("inst", 32), ("pc", 50), ("foldpc", 10), ("pd_isRVC", 1),
    ("pd_brType", 2), ("pred_taken", 1), ("ftqPtr_flag", 1),
    ("ftqPtr_value", 6), ("ftqOffset", 4), ("exceptionType", 3),
    ("backendException", 1), ("triggered", 4), ("isLastInFtqEntry", 1),
]

def wsfx(w):
    return "" if w == 1 else f"[{w-1}:0] "

def port_decl_block(ports, prefix_dir):
    lines = []
    for (w, n) in ports:
        lines.append(f"  {prefix_dir} {wsfx(w)}{n},")
    return lines

def gen_core():
    L = []
    L.append("// 香山 V2R2 IBuffer 指令缓冲 —— 手写可读 SystemVerilog 核心")
    L.append("// 自动生成: scripts/gen_ibuffer.py —— 勿手改")
    L.append("//")
    L.append("// IBuffer 是一个循环 FIFO 指令缓冲: 上游 IFU 每拍最多送 PredictWidth=16 条")
    L.append("// 指令入队, 下游 Decode 每拍最多取 DecodeWidth=6 条出队.")
    L.append("// 存储以 48 个裸寄存器 entry 组织 (而非 SRAM), 以精确控制多写/多读端口.")
    L.append("// 出队时把 48 entry 视作 6 个 bank * 8 深的 banked-FIFO, 每 bank 顺序读 1 条,")
    L.append("// 降低读 Mux 面积.")
    L.append("//")
    L.append(f"//   IBufSize={IBUF_SIZE} IBufNBank={NBANK} bankSize={BANK_SIZE} "
             f"DecodeWidth={DEC} PredictWidth={PW}")
    L.append("//")
    L.append("// 寄存器命名沿用 golden (firtool 展平名), 便于 Formality 按名匹配.")
    L.append("module xs_IBuffer_core (")
    L.append("  input clock,")
    L.append("  input reset,")
    L += port_decl_block(INS, "input")
    out_lines = port_decl_block(OUTS, "output")
    out_lines[-1] = out_lines[-1].rstrip(",")
    L += out_lines
    L.append(");")
    L.append("")

    # ----- 寄存器声明 -----
    L.append("  // ================= 存储寄存器 (entry 数组, 展平命名 ibuf_<i>_<field>) =======")
    for i in range(IBUF_SIZE):
        for (fn, fw) in ENTRY_FIELDS:
            L.append(f"  reg {wsfx(fw)}ibuf_{i}_{fn};")
    L.append("")
    L.append("  // 出队侧输出寄存器 (DecodeWidth 条)")
    for i in range(DEC):
        L.append(f"  reg              outputEntries_{i}_valid;")
        for (fn, fw) in ENTRY_FIELDS:
            L.append(f"  reg {wsfx(fw)}outputEntries_{i}_bits_{fn};")
    L.append("")
    L.append("  // 入队指针向量 (PredictWidth 份, 互差固定 1; 仅 entry0 保留 flag)")
    L.append("  reg              enqPtrVec_0_flag;")
    for i in range(PW):
        L.append(f"  reg  [5:0]       enqPtrVec_{i}_value;")
    L.append("  // 出队指针 (循环队列 6 位 value + flag)")
    L.append("  reg              deqPtr_flag;")
    L.append("  reg  [5:0]       deqPtr_value;")
    L.append("  // bank 间出队指针向量 (DecodeWidth 份, 3 位选 bank)")
    for i in range(DEC):
        L.append(f"  reg  [2:0]       deqBankPtrVec_{i}_value;")
    L.append("  // bank 内出队指针 (每 bank 一个, flag+3 位 value, 选 bankSize=8 深)")
    for i in range(NBANK):
        L.append(f"  reg              deqInBankPtr_{i}_flag;")
        L.append(f"  reg  [2:0]       deqInBankPtr_{i}_value;")
    L.append("  reg              allowEnq;          // 入队许可(快满则关)")
    for i in range(38):
        L.append(f"  reg              topdown_stage_reasons_{i};")
    L.append("  reg              afterInit;         // 首次入队后置位")
    L.append("  reg              headBubble;        // flush 后头部气泡")
    for i in range(9):
        pw = "  [2:0]       " if i == 7 else "              "
        L.append(f"  reg{pw}io_perf_{i}_value_REG;")
        L.append(f"  reg{pw}io_perf_{i}_value_REG_1;")
    L.append("")

    # ----- enqData (来自 fetch 的入队数据, PredictWidth 份) -----
    L.append("  // ================= 入队数据 enqData[i] = fromFetch(io_in.bits, i) =========")
    L.append("  // exceptionType 由 fetch 异常 + crossPage + RVC 非法指令合成:")
    L.append("  //   crossPage     -> {1, fetchExcp};  fetchExcp!=0 -> {0, fetchExcp};")
    L.append("  //   rvcIll        -> rvcII(3'b100);   否则 0")
    for i in range(PW):
        L.append(f"  wire [2:0] enqData_{i}_exceptionType =")
        L.append(f"    io_in_bits_crossPageIPFFix_{i} ? {{1'h1, io_in_bits_exceptionType_{i}}}")
        L.append(f"    : (|io_in_bits_exceptionType_{i}) ? {{1'h0, io_in_bits_exceptionType_{i}}}")
        L.append(f"    : {{io_in_bits_illegalInstr_{i}, 2'h0}};")
    L.append("")

    # enqOffset[i] = popcount(valid[0..i-1])
    L.append("  // enqOffset[i] = popcount(io_in_bits_valid[0..i-1]) —— 第 i 条在本拍的入队序号")
    L.append("  wire [4:0] enqOffset_0 = 5'h0;")
    for i in range(1, PW):
        terms = " + ".join(f"io_in_bits_valid[{j}]" for j in range(i))
        L.append(f"  wire [4:0] enqOffset_{i} = "
                 + " + ".join(f"{{4'h0, io_in_bits_valid[{j}]}}" for j in range(i)) + ";")
    L.append("")

    # numFromFetch, numValid, useBypass, numOut/numDeq, numTryEnq, numBypass, allowEnq next
    L.append("  // ================= 计数与指针运算 =========================================")
    L.append("  wire [4:0] numFromFetch = io_in_valid ? ("
             + " + ".join(f"{{4'h0, io_in_bits_enqEnable[{j}]}}" for j in range(PW)) + ") : 5'h0;")
    L.append("  wire [5:0] numValid = (enqPtrVec_0_flag == deqPtr_flag)")
    L.append("    ? 6'(enqPtrVec_0_value - deqPtr_value)")
    L.append("    : 6'(6'(enqPtrVec_0_value - 6'h10) - deqPtr_value);")
    L.append("  wire useBypass = ({enqPtrVec_0_flag, enqPtrVec_0_value} == {deqPtr_flag, deqPtr_value})")
    L.append("                   & io_decodeCanAccept;   // 空 且 decode 可收 -> 走旁路")
    L.append("")
    L.append("  // outputEntries 当前有效条数 (优先编码)")
    L.append("  wire [2:0] outputEntriesValidNum =")
    L.append("    outputEntries_4_valid ? 3'h5 :")
    L.append("    outputEntries_3_valid ? 3'h4 :")
    L.append("    outputEntries_2_valid ? 3'h3 :")
    L.append("    outputEntries_1_valid ? 3'h2 : {2'h0, outputEntries_0_valid};")
    L.append("  wire outputEntriesIsNotFull = ~outputEntries_5_valid;")
    L.append("  wire [2:0] numOutSpace = 3'(3'h6 - outputEntriesValidNum);")
    L.append("")
    L.append("  // numOut: 本拍出队条数")
    L.append("  wire [2:0] numOut =")
    L.append("    io_decodeCanAccept ? (numValid > 6'h5 ? 3'h6 : numValid[2:0]) :")
    L.append("    outputEntries_5_valid ? 3'h0 :")
    L.append("    (numValid >= {3'h0, numOutSpace}) ? numOutSpace : numValid[2:0];")
    L.append("  wire [2:0] numDeq = numOut;")
    L.append("")
    L.append("  // numTryEnq / numBypass: 旁路时前 DecodeWidth 条直送, 余下才真入队")
    L.append("  wire fetchGtDec = numFromFetch > 5'h5;")
    L.append("  wire [4:0] numTryEnq = useBypass ? (fetchGtDec ? 5'(numFromFetch - 5'h6) : 5'h0)")
    L.append("                                   : numFromFetch;")
    L.append("  wire enqFire = allowEnq & io_in_valid;        // io.in.fire")
    L.append("  wire doEnq   = enqFire & ~io_flush;           // 实际写 ibuf 的总门")
    L.append("")

    # outputEntriesValidNumNext + validVec
    L.append("  // outputEntries 下拍有效条数, 据此生成 validVec (低 numNext 位为 1)")
    L.append("  wire [2:0] outputEntriesValidNumNext =")
    L.append("    io_decodeCanAccept ? (useBypass ? (fetchGtDec ? 3'h6 : numFromFetch[2:0]) : numOut) :")
    L.append("    outputEntries_5_valid ? outputEntriesValidNum :")
    L.append("    3'(outputEntriesValidNum + numOut);")
    L.append("  wire [7:0] validVecMask = 8'h1 << outputEntriesValidNumNext;")
    L.append("  wire [5:0] validVec = 6'(validVecMask[5:0] - 6'h1);")
    L.append("")

    # ---- enqPtrVec packed value array for bypass-match indexing ----
    L.append("  // enqPtrVec value 打包, 供 bypass 匹配按 (enqOffset-DecodeWidth) 索引")
    L.append("  wire [5:0] enqPtrValArr [0:15];")
    for i in range(PW):
        L.append(f"  assign enqPtrValArr[{i}] = enqPtrVec_{i}_value;")
    L.append("")

    # ---- 入队 validOH 与写使能 ----
    L.append("  // ================= 入队: 每 entry 一个 16->1 写端口 ========================")
    L.append("  // wenOH[i][e] : 第 i 条 fetch 指令是否写到 entry e")
    L.append("  //   normalMatch:  enqPtrVec[enqOffset[i]].value == e")
    L.append("  //   bypassMatch:  enqOffset[i]>=DecodeWidth && enqPtrVec[enqOffset[i]-6].value == e")
    for e in range(IBUF_SIZE):
        for i in range(PW):
            if i == 0:
                # enqOffset_0 == 0 always; bypass match needs offset>=6 -> false
                L.append(f"  wire wenOH_{i}_{e} = io_in_bits_valid[0] & io_in_bits_enqEnable[0]"
                         f" & ~useBypass & (enqPtrVec_0_value == 6'd{e});")
            else:
                L.append(f"  wire wenOH_{i}_{e} = io_in_bits_valid[{i}] & io_in_bits_enqEnable[{i}] &")
                L.append(f"    (useBypass ? ((enqOffset_{i} > 5'h5)"
                         f" & (enqPtrValArr[4'(enqOffset_{i} - 5'h6)] == 6'd{e}))")
                L.append(f"               : (enqPtrValArr[enqOffset_{i}[3:0]] == 6'd{e}));")
    L.append("")
    for e in range(IBUF_SIZE):
        oh = " | ".join(f"wenOH_{i}_{e}" for i in range(PW))
        L.append(f"  wire wen_{e} = ({oh}) & doEnq;")
    L.append("")

    # ---- bypass entries (DecodeWidth) ----
    L.append("  // ================= 旁路 bypass: fetch 直接送 Decode 输出 ===================")
    L.append("  // bypassOH[idx][i] : 第 i 条 fetch 指令旁路到输出槽 idx (enqOffset[i]==idx)")
    for idx in range(DEC):
        for i in range(PW):
            L.append(f"  wire bypOH_{idx}_{i} = io_in_bits_valid[{i}] & io_in_bits_enqEnable[{i}]"
                     f" & (enqOffset_{i} == 5'd{idx});")
    L.append("")

    # ---- bank read: readStage1 ----
    L.append("  // ================= 出队读: 两级 (bank 内 8->1, 再 bank 间 6->1) ===========")
    L.append("  // bank b 含 entry b, b+6, ..., b+42 (共 bankSize=8 条), 由 deqInBankPtr[b] 选")
    for b in range(NBANK):
        for (fn, fw) in ENTRY_FIELDS:
            terms = []
            for d in range(BANK_SIZE):
                e = b + d * NBANK
                terms.append(f"(deqInBankPtr_{b}_value == 3'd{d} ? ibuf_{e}_{fn} : {fw}'h0)")
            L.append(f"  wire {wsfx(fw)}readStage1_{b}_{fn} =")
            L.append("    " + "\n    | ".join(terms) + ";")
    L.append("")
    L.append("  // deqEntries[k]: 输出槽 k 的正常出队数据 = bank 间按 deqBankPtrVec[k] 选 readStage1")
    for k in range(DEC):
        L.append(f"  wire deqEntries_{k}_valid = validVec[{k}];")
        for (fn, fw) in ENTRY_FIELDS:
            terms = []
            for b in range(NBANK):
                terms.append(f"(deqBankPtrVec_{k}_value == 3'd{b} ? readStage1_{b}_{fn} : {fw}'h0)")
            L.append(f"  wire {wsfx(fw)}deqEntries_{k}_bits_{fn} =")
            L.append("    " + "\n    | ".join(terms) + ";")
    L.append("")

    # ---- enqData_mux for each entry write & bypass & output ----
    # helper to build Mux1H over fetch slots for a given field, sel prefix
    def mux1h(sel_prefix, field, fw, sub=""):
        # value of enqData_i_field
        terms = []
        for i in range(PW):
            val = enqdata_expr(i, field, fw)
            terms.append(f"({sel_prefix}_{i}{sub} ? {val} : {fw}'h0)")
        return "\n    | ".join(terms)

    def enqdata_expr(i, field, fw):
        if field == "inst":
            return f"io_in_bits_instrs_{i}"
        if field == "pc":
            return f"io_in_bits_pc_{i}"
        if field == "foldpc":
            return f"io_in_bits_foldpc_{i}"
        if field == "pd_isRVC":
            return f"io_in_bits_pd_{i}_isRVC"
        if field == "pd_brType":
            return f"io_in_bits_pd_{i}_brType"
        if field == "pred_taken":
            return f"io_in_bits_ftqOffset_{i}_valid"
        if field == "ftqPtr_flag":
            return f"io_in_bits_ftqPtr_flag"
        if field == "ftqPtr_value":
            return f"io_in_bits_ftqPtr_value"
        if field == "ftqOffset":
            # ftqOffset bits = log2(PredictWidth)=4 -> io_in_bits has no per-slot ftqOffset bits port?
            return f"io_in_bits_ftqOffset_{i}_bits" if False else f"4'(io_in_bits_pc_{i} & 50'h0)"
        if field == "exceptionType":
            return f"enqData_{i}_exceptionType"
        if field == "backendException":
            return f"io_in_bits_backendException_{i}" if i == 0 else "1'h0"
        if field == "triggered":
            return f"io_in_bits_triggered_{i}"
        if field == "isLastInFtqEntry":
            return f"io_in_bits_isLastInFtqEntry_{i}"
        return "0"

    L.append("  // ================= 时序: 入队写 ibuf =======================================")
    L.append("  always_ff @(posedge clock) begin")
    for e in range(IBUF_SIZE):
        for (fn, fw) in ENTRY_FIELDS:
            L.append(f"    if (wen_{e}) ibuf_{e}_{fn} <=")
            L.append("      " + mux1h(f"wenOH", fn, fw, sub=f"_{e}") + ";")
    L.append("  end")
    L.append("")
    return L, mux1h

# Build the core file body and the mux1h closure
def gen_core_full():
    head, mux1h = gen_core()
    L = head

    # ---- output register update (sequential, async reset on ibuf only? golden uses sync for output) ----
    # golden: ibuf writes in posedge clock (no reset on ibuf in the reset branch? Actually reset
    # branch DOES reset ibuf). We must reset ibuf too. Rework: put everything in async-reset block.
    return L, mux1h

CORE_LINES, MUX1H = gen_core()

# Because ibuf, outputEntries, pointers all reset in golden's async-reset always block, we
# re-emit the storage/pointer sequential logic here in a unified async-reset block and DROP the
# plain posedge ibuf-write block generated above. We rebuild CORE_LINES accordingly below.

def build_core():
    L, mux1h = gen_core()
    # remove the trailing "input-write always_ff" block we appended (last block) and rebuild as
    # a single async reset always_ff covering all regs (matches golden semantics & reset values).
    # Find the marker we inserted and cut from there.
    marker = "  // ================= 时序: 入队写 ibuf"
    cut = next(i for i, s in enumerate(L) if s.startswith(marker))
    L = L[:cut]

    def enqdata_expr(i, field, fw):
        if field == "inst":        return f"io_in_bits_instrs_{i}"
        if field == "pc":          return f"io_in_bits_pc_{i}"
        if field == "foldpc":      return f"io_in_bits_foldpc_{i}"
        if field == "pd_isRVC":    return f"io_in_bits_pd_{i}_isRVC"
        if field == "pd_brType":   return f"io_in_bits_pd_{i}_brType"
        if field == "pred_taken":  return f"io_in_bits_ftqOffset_{i}_valid"
        if field == "ftqPtr_flag": return f"io_in_bits_ftqPtr_flag"
        if field == "ftqPtr_value":return f"io_in_bits_ftqPtr_value"
        if field == "ftqOffset":   return f"4'd{i}"   # fetch.ftqOffset(i).bits == i
        if field == "exceptionType":return f"enqData_{i}_exceptionType"
        if field == "backendException":
            return f"io_in_bits_backendException_{i}" if i == 0 else "1'h0"
        if field == "triggered":   return f"io_in_bits_triggered_{i}"
        if field == "isLastInFtqEntry":return f"io_in_bits_isLastInFtqEntry_{i}"
        raise ValueError(field)

    def mux_sel(selpfx, field, fw, sub):
        terms = []
        for i in range(PW):
            terms.append(f"({selpfx}_{sub}_{i} ? {enqdata_expr(i, field, fw)} : {fw}'h0)"
                         if selpfx == "bypOH"
                         else f"({selpfx}_{i}_{sub} ? {enqdata_expr(i, field, fw)} : {fw}'h0)")
        return "\n        | ".join(terms)

    # bypassEntries[idx].bits = Mux1H(bypOH[idx], enqData)
    L.append("  // ================= 旁路数据 bypassEntries[idx].bits = Mux1H ===============")
    for idx in range(DEC):
        for (fn, fw) in ENTRY_FIELDS:
            terms = []
            for i in range(PW):
                terms.append(f"(bypOH_{idx}_{i} ? {enqdata_expr(i, fn, fw)} : {fw}'h0)")
            L.append(f"  wire {wsfx(fw)}bypassBits_{idx}_{fn} =")
            L.append("    " + "\n    | ".join(terms) + ";")
        oh = " | ".join(f"bypOH_{idx}_{i}" for i in range(PW))
        L.append(f"  wire bypassValid_{idx} = ({oh}) & doEnq;")
    L.append("")

    # GEN_196 = useBypass & io_in_valid (use bypass this cycle for output)
    L.append("  wire useBypassThisCyc = useBypass & io_in_valid;")
    L.append("")

    # ---- deqBankPtrVec next (mod IBufNBank add numDeq) ----
    L.append("  // ================= 指针 next =============================================")
    L.append("  // deqBankPtrVec[k] += numDeq (mod IBufNBank=6)")
    for k in range(DEC):
        L.append(f"  wire [3:0] deqBankNext_{k}_raw = 4'({{1'h0, deqBankPtrVec_{k}_value}} + {{1'h0, numOut}});")
        L.append(f"  wire [4:0] deqBankNext_{k}_sub = 5'({{1'h0, deqBankNext_{k}_raw}} - 5'h6);")
        L.append(f"  wire [2:0] deqBankNext_{k} = $signed(deqBankNext_{k}_sub) > -5'sh1"
                 f" ? deqBankNext_{k}_sub[2:0] : deqBankNext_{k}_raw[2:0];")
    L.append("")
    L.append("  // deqPtr += numDeq (mod IBufSize=48)")
    L.append("  wire [6:0] deqPtrNext_raw = 7'({1'h0, deqPtr_value} + {1'h0, numOut});")
    L.append("  wire [7:0] deqPtrNext_sub = 8'({1'h0, deqPtrNext_raw} - 8'h30);")
    L.append("  wire       deqPtrNext_wrap = $signed(deqPtrNext_sub) > -8'sh1;")
    L.append("  wire [5:0] deqPtrNext = deqPtrNext_wrap ? deqPtrNext_sub[5:0] : deqPtrNext_raw[5:0];")
    L.append("")
    L.append("  // enqPtrVec[k] += numTryEnq (mod IBufSize=48), 仅 doEnq 时更新")
    for k in range(PW):
        L.append(f"  wire [6:0] enqNext_{k}_raw = 7'({{1'h0, enqPtrVec_{k}_value}} + {{2'h0, numTryEnq}});")
        L.append(f"  wire [7:0] enqNext_{k}_sub = 8'({{1'h0, enqNext_{k}_raw}} - 8'h30);")
        L.append(f"  wire       enqNext_{k}_wrap = $signed(enqNext_{k}_sub) > -8'sh1;")
        L.append(f"  wire [5:0] enqNext_{k} = enqNext_{k}_wrap ? enqNext_{k}_sub[5:0] : enqNext_{k}_raw[5:0];")
    L.append("")
    L.append("  // bank 内指针推进: 当本 bank 的 validIdx < numOut 时 advance(+1, flag 在 value 满 8 翻)")
    L.append("  //   validIdx = (k - deqBankPtr.value) mod IBufNBank, 截到 log2(DecodeWidth)=3 位")
    for b in range(NBANK):
        # validIdx_b = (b - deqBankPtrVec_0_value) mod 6
        L.append(f"  wire [2:0] validIdx_{b} = (deqBankPtrVec_0_value <= 3'd{b})")
        L.append(f"    ? 3'(3'd{b} - deqBankPtrVec_0_value)")
        L.append(f"    : 3'(3'd{b + NBANK} - deqBankPtrVec_0_value);")
        L.append(f"  wire bankAdvance_{b} = numOut > validIdx_{b};")
        L.append(f"  wire [3:0] deqInBankNext_{b} = 4'({{deqInBankPtr_{b}_flag, deqInBankPtr_{b}_value}} + 4'h1);")
    L.append("")

    # ---- output entries next-value wires (decodeCanAccept / notFull branches) ----
    L.append("  // ================= 输出寄存器 next (3 分支: 旁路/正常 deq / 半满累积移位) ====")
    # outputEntries_k next valid
    for k in range(DEC):
        bypoh = " | ".join(f"bypOH_{k}_{i}" for i in range(PW))
        L.append(f"  wire outEnt_{k}_valid_n = ~io_flush & (")
        L.append(f"    io_decodeCanAccept ? (useBypassThisCyc ? (({bypoh}) & doEnq) : validVec[{k}])")
        L.append(f"    : (outputEntries_5_valid ? outputEntries_{k}_valid : validVec[{k}]));")
    L.append("")
    # For bits: in decodeCanAccept branch -> bypass? bypassBits : deqEntries
    # In notFull branch (the shift-merge): outputEntries_k keeps old if k<validNum else takes
    #   deqEntries[k-validNum]. firtool builds it via per-k conditions; we replicate functionally.
    L.append("  // 半满累积分支: 已有 outputEntriesValidNum 条保留, 其后接 deqEntries 顺次填入")
    for (fn, fw) in ENTRY_FIELDS:
        for k in range(DEC):
            # decodeCanAccept value: bypass? bypassBits_k : deqEntries_k
            byp = "\n          | ".join(
                f"(bypOH_{k}_{i} ? {enqdata_expr(i, fn, fw)} : {fw}'h0)" for i in range(PW))
            L.append(f"  wire {wsfx(fw)}outEnt_{k}_{fn}_dca =")
            L.append(f"    useBypassThisCyc ? ({byp})")
            L.append(f"    : deqEntries_{k}_bits_{fn};")
            # notFull merge value: select deqEntries[ k - validNum ] when k>=validNum else keep
            # build mux over possible validNum (0..k)
            sel_terms = []
            for vn in range(0, k + 1):
                src = f"deqEntries_{k - vn}_bits_{fn}"
                sel_terms.append(f"(outputEntriesValidNum == 3'd{vn}) ? {src}")
            keep = f"outputEntries_{k}_bits_{fn}"
            # when validNum > k -> keep
            chain = " :\n      ".join(sel_terms)
            L.append(f"  wire {wsfx(fw)}outEnt_{k}_{fn}_merge =")
            L.append(f"    (outputEntriesValidNum > 3'd{k}) ? {keep} :")
            L.append(f"      {chain} : {keep};")
    L.append("")

    # ---- stallReason ----
    L.append("  // ================= stallReason (TopDown 气泡归因) =========================")
    L.append("  wire [2:0] deqValidCount = 3'("
             + " + ".join(f"{{2'h0, validVec[{i}]}}" for i in range(DEC)) + ");")
    L.append("  wire [2:0] deqWasteCount = 3'(3'h6 - deqValidCount);")
    L.append("  wire anyReason = |{" + ", ".join(f"topdown_stage_reasons_{i}" for i in range(38)) + "};")
    # matchBubble = NumStallReasons-1 - PriorityEncoder(reasons.reverse).
    # reasons.reverse[j]=reasons[37-j]; PriorityEncoder 取最低 j (=> 最高原始 idx);
    # 0x25(=37) - j = 37 - (37 - orig) = orig  => 即「置位的最高 reason 序号」.
    expr = "6'h0"
    for orig in range(0, 38):
        expr = f"(topdown_stage_reasons_{orig} ? 6'd{orig} : {expr})"
    L.append(f"  wire [5:0] matchBubble = {expr};  // 置位的最高 reason 序号")
    L.append("  // 无原因且未浪费满 -> FetchFragBubble.id=0xD; 否则 matchBubble")
    L.append("  wire [5:0] stallVal = (deqWasteCount == 3'h6 | anyReason) ? matchBubble : 6'hD;")
    L.append("")

    # ---- topdown next ----
    L.append("  // topdown_stage: 直接锁存 fetch 的 topdown_info, flush 时按重定向原因置位对应 bit")
    L.append("  wire ctrlRedir = io_flush & io_ControlRedirect;")
    def td_next(idx):
        base = f"io_in_bits_topdown_info_reasons_{idx}"
        if idx == 12:   # BTBMissBubble
            return f"(io_flush & io_ControlRedirect & io_ControlBTBMissBubble) | {base}"
        if idx == 3:    # TAGEMissBubble
            return f"(ctrlRedir & ~io_ControlBTBMissBubble & io_TAGEMissBubble) | {base}"
        if idx == 4:    # SCMissBubble
            return f"(ctrlRedir & ~(io_ControlBTBMissBubble | io_TAGEMissBubble) & io_SCMissBubble) | {base}"
        if idx == 5:    # ITTAGEMissBubble
            return (f"(ctrlRedir & ~(io_ControlBTBMissBubble | io_TAGEMissBubble | io_SCMissBubble)"
                    f" & io_ITTAGEMissBubble) | {base}")
        if idx == 6:    # RASMissBubble
            return (f"(ctrlRedir & ~(io_ControlBTBMissBubble | io_TAGEMissBubble | io_SCMissBubble"
                    f" | io_ITTAGEMissBubble) & io_RASMissBubble) | {base}")
        if idx == 7:    # MemVioRedirectBubble
            return f"(io_flush & ~io_ControlRedirect & io_MemVioRedirect) | {base}"
        if idx == 8:    # OtherRedirectBubble
            return f"(io_flush & ~(io_ControlRedirect | io_MemVioRedirect)) | {base}"
        return base
    L.append("")

    # ---- main async-reset sequential block ----
    L.append("  // ================= 主时序块 (异步复位, 复位值与 golden 对齐) ===============")
    L.append("  always_ff @(posedge clock or posedge reset) begin")
    L.append("    if (reset) begin")
    for e in range(IBUF_SIZE):
        for (fn, fw) in ENTRY_FIELDS:
            L.append(f"      ibuf_{e}_{fn} <= {fw}'h0;")
    for k in range(DEC):
        L.append(f"      outputEntries_{k}_valid <= 1'h0;")
        for (fn, fw) in ENTRY_FIELDS:
            L.append(f"      outputEntries_{k}_bits_{fn} <= {fw}'h0;")
    L.append("      enqPtrVec_0_flag <= 1'h0;")
    for k in range(PW):
        L.append(f"      enqPtrVec_{k}_value <= 6'd{k};")
    L.append("      deqPtr_flag <= 1'h0;")
    L.append("      deqPtr_value <= 6'h0;")
    for k in range(DEC):
        L.append(f"      deqBankPtrVec_{k}_value <= 3'd{k};")
    for b in range(NBANK):
        L.append(f"      deqInBankPtr_{b}_flag <= 1'h0;")
        L.append(f"      deqInBankPtr_{b}_value <= 3'h0;")
    L.append("      allowEnq <= 1'h1;")
    for i in range(38):
        L.append(f"      topdown_stage_reasons_{i} <= 1'h0;")
    L.append("      afterInit <= 1'h0;")
    L.append("      headBubble <= 1'h0;")
    L.append("    end else begin")
    # ibuf writes
    L.append("      // 入队写")
    def enqdata_expr2(i, field, fw):
        return build_core_enqdata(i, field, fw)
    for e in range(IBUF_SIZE):
        for (fn, fw) in ENTRY_FIELDS:
            terms = " | ".join(
                f"(wenOH_{i}_{e} ? {build_core_enqdata(i, fn, fw)} : {fw}'h0)" for i in range(PW))
            L.append(f"      if (wen_{e}) ibuf_{e}_{fn} <= {terms};")
    # output entries
    L.append("      // 输出寄存器")
    for k in range(DEC):
        L.append(f"      outputEntries_{k}_valid <= outEnt_{k}_valid_n;")
    L.append("      if (io_decodeCanAccept) begin")
    for k in range(DEC):
        for (fn, fw) in ENTRY_FIELDS:
            L.append(f"        outputEntries_{k}_bits_{fn} <= outEnt_{k}_{fn}_dca;")
    L.append("      end else if (outputEntriesIsNotFull) begin")
    for k in range(DEC):
        # only update if not (already have >k valid) i.e. when outputEntriesValidNum <= k
        L.append(f"        if (~(outputEntries_5_valid | (outputEntriesValidNum > 3'd{k}))) begin")
        for (fn, fw) in ENTRY_FIELDS:
            L.append(f"          outputEntries_{k}_bits_{fn} <= outEnt_{k}_{fn}_merge;")
        L.append("        end")
    L.append("      end")
    # pointers
    L.append("      // 指针更新")
    L.append("      if (io_flush) begin")
    for k in range(DEC):
        L.append(f"        deqBankPtrVec_{k}_value <= 3'd{k};")
    for b in range(NBANK):
        L.append(f"        deqInBankPtr_{b}_value <= 3'h0;")
    L.append("        deqPtr_value <= 6'h0;")
    for k in range(PW):
        L.append(f"        enqPtrVec_{k}_value <= 6'd{k};")
    L.append("      end else begin")
    for k in range(DEC):
        L.append(f"        deqBankPtrVec_{k}_value <= deqBankNext_{k};")
    for b in range(NBANK):
        L.append(f"        if (bankAdvance_{b}) deqInBankPtr_{b}_value <= deqInBankNext_{b}[2:0];")
    L.append("        deqPtr_value <= deqPtrNext;")
    L.append("        if (doEnq) begin")
    for k in range(PW):
        L.append(f"          enqPtrVec_{k}_value <= enqNext_{k};")
    L.append("        end")
    L.append("      end")
    # flag updates (always, gated by ~flush)
    for b in range(NBANK):
        L.append(f"      deqInBankPtr_{b}_flag <= ~io_flush &"
                 f" (bankAdvance_{b} ? deqInBankNext_{b}[3] : deqInBankPtr_{b}_flag);")
    L.append("      deqPtr_flag <= ~io_flush & (deqPtrNext_wrap ^ deqPtr_flag);")
    L.append("      enqPtrVec_0_flag <= ~io_flush & ((doEnq & enqNext_0_wrap) ^ enqPtrVec_0_flag);")
    # allowEnq
    L.append("      allowEnq <= io_flush | (6'(6'(numValid + {1'h0, enqFire ? numTryEnq : 5'h0})"
             " - {3'h0, numOut}) < 6'h21);")
    # topdown
    for i in range(38):
        L.append(f"      topdown_stage_reasons_{i} <= {td_next(i)};")
    L.append("      afterInit <= enqFire | afterInit;")
    L.append("      headBubble <= io_flush | (~(|numValid) & headBubble);")
    L.append("    end")
    L.append("  end")
    L.append("")
    # perf 计数寄存器: golden 用独立的「无复位」posedge 块 (RegNext 性能采样).
    # 必须同样无异步复位, 否则 FM 因复位结构不同判不等价.
    L.append("  // 性能事件采样寄存器 (无复位, 对应 golden 的 RegNext 性能链)")
    L.append("  always_ff @(posedge clock) begin")
    L.append("    io_perf_0_value_REG <= io_flush;")
    L.append("    io_perf_1_value_REG <= afterInit & ~(|numValid) & ~headBubble;")
    L.append("    io_perf_2_value_REG <= (|numValid) & (numValid < 6'hC);")
    L.append("    io_perf_3_value_REG <= (numValid > 6'hB) & (numValid < 6'h18);")
    L.append("    io_perf_4_value_REG <= (numValid > 6'h17) & (numValid < 6'h24);")
    L.append("    io_perf_5_value_REG <= (numValid > 6'h23) & (numValid[5:4] != 2'h3);")
    L.append("    io_perf_6_value_REG <= &numValid;")
    L.append("    io_perf_7_value_REG <= io_decodeCanAccept & ~headBubble ? 3'(3'h6 - numOut) : 3'h0;")
    L.append("    io_perf_8_value_REG <= io_decodeCanAccept & ~headBubble & (numOut == 3'h0);")
    for i in range(9):
        L.append(f"    io_perf_{i}_value_REG_1 <= io_perf_{i}_value_REG;")
    L.append("  end")
    L.append("")

    # ---- output port assigns ----
    L.append("  // ================= 输出端口 (outputEntries -> CtrlFlow) ===================")
    L.append("  assign io_in_ready = allowEnq;")
    L.append("  assign io_full = ~allowEnq;" if any(n == "io_full" for (_, n) in OUTS) else "")
    for k in range(DEC):
        L.append(f"  assign io_out_{k}_valid = outputEntries_{k}_valid;")
        L.append(f"  assign io_out_{k}_bits_instr = outputEntries_{k}_bits_inst;")
        L.append(f"  assign io_out_{k}_bits_pc = outputEntries_{k}_bits_pc;")
        L.append(f"  assign io_out_{k}_bits_foldpc = outputEntries_{k}_bits_foldpc;")
        L.append(f"  assign io_out_{k}_bits_exceptionVec_1 = &(outputEntries_{k}_bits_exceptionType[1:0]);")
        L.append(f"  assign io_out_{k}_bits_exceptionVec_2 = outputEntries_{k}_bits_exceptionType[2]"
                 f" & (outputEntries_{k}_bits_exceptionType[1:0] == 2'h0);")
        L.append(f"  assign io_out_{k}_bits_exceptionVec_12 = outputEntries_{k}_bits_exceptionType[1:0] == 2'h1;")
        L.append(f"  assign io_out_{k}_bits_exceptionVec_20 = outputEntries_{k}_bits_exceptionType[1:0] == 2'h2;")
        L.append(f"  assign io_out_{k}_bits_backendException = outputEntries_{k}_bits_backendException;")
        L.append(f"  assign io_out_{k}_bits_trigger = outputEntries_{k}_bits_triggered;")
        L.append(f"  assign io_out_{k}_bits_pd_isRVC = outputEntries_{k}_bits_pd_isRVC;")
        L.append(f"  assign io_out_{k}_bits_pd_brType = outputEntries_{k}_bits_pd_brType;")
        L.append(f"  assign io_out_{k}_bits_pred_taken = outputEntries_{k}_bits_pred_taken;")
        L.append(f"  assign io_out_{k}_bits_crossPageIPFFix = outputEntries_{k}_bits_exceptionType[2]"
                 f" & (|outputEntries_{k}_bits_exceptionType[1:0]);")
        L.append(f"  assign io_out_{k}_bits_ftqPtr_flag = outputEntries_{k}_bits_ftqPtr_flag;")
        L.append(f"  assign io_out_{k}_bits_ftqPtr_value = outputEntries_{k}_bits_ftqPtr_value;")
        L.append(f"  assign io_out_{k}_bits_ftqOffset = outputEntries_{k}_bits_ftqOffset;")
        L.append(f"  assign io_out_{k}_bits_isLastInFtqEntry = outputEntries_{k}_bits_isLastInFtqEntry;")
    # stallReason
    L.append("")
    L.append("  // stallReason: backReason 优先, 否则按浪费的出队槽数填 stallVal")
    cmp = ["deqWasteCount > 3'h5", "deqWasteCount > 3'h4", "deqWasteCount[2]",
           "deqWasteCount > 3'h2", "|deqWasteCount[2:1]", "|deqWasteCount"]
    for k in range(DEC):
        L.append(f"  assign io_stallReason_reason_{k} = io_stallReason_backReason_valid")
        L.append(f"    ? io_stallReason_backReason_bits : (({cmp[k]}) ? stallVal : 6'h0);")
    L.append("")
    for i in range(9):
        pad = "3'h0" if i == 7 else "5'h0"
        L.append(f"  assign io_perf_{i}_value = {{{pad}, io_perf_{i}_value_REG_1}};")
    L.append("")
    L.append("endmodule")
    L.append("")
    # drop possible empty line from io_full guard
    L = [s for s in L if s != ""] if False else L
    return L

def build_core_enqdata(i, field, fw):
    if field == "inst":        return f"io_in_bits_instrs_{i}"
    if field == "pc":          return f"io_in_bits_pc_{i}"
    if field == "foldpc":      return f"io_in_bits_foldpc_{i}"
    if field == "pd_isRVC":    return f"io_in_bits_pd_{i}_isRVC"
    if field == "pd_brType":   return f"io_in_bits_pd_{i}_brType"
    if field == "pred_taken":  return f"io_in_bits_ftqOffset_{i}_valid"
    if field == "ftqPtr_flag": return f"io_in_bits_ftqPtr_flag"
    if field == "ftqPtr_value":return f"io_in_bits_ftqPtr_value"
    if field == "ftqOffset":   return f"4'd{i}"   # fetch.ftqOffset(i).bits == i
    if field == "exceptionType":return f"enqData_{i}_exceptionType"
    if field == "backendException":
        return f"io_in_bits_backendException_{i}" if i == 0 else "1'h0"
    if field == "triggered":   return f"io_in_bits_triggered_{i}"
    if field == "isLastInFtqEntry":return f"io_in_bits_isLastInFtqEntry_{i}"
    raise ValueError(field)


# ---------------------------------------------------------------------------
# 3. wrapper / variants / tb
# ---------------------------------------------------------------------------
def gen_wrapper(modname, core_inst_outsuffix=None):
    # module <modname> with golden-identical port list, instantiates xs_IBuffer_core as u_core
    L = []
    L.append("// 自动生成: scripts/gen_ibuffer.py —— 勿手改")
    L.append(f"module {modname}(")
    L.append("  input clock,")
    L.append("  input reset,")
    L += port_decl_block(INS, "input")
    out_lines = port_decl_block(OUTS, "output")
    out_lines[-1] = out_lines[-1].rstrip(",")
    L += out_lines
    L.append(");")
    conns = [".clock(clock)", ".reset(reset)"]
    for (w, n) in INS:
        conns.append(f".{n}({n})")
    for (w, n) in OUTS:
        conns.append(f".{n}({n})")
    L.append("  xs_IBuffer_core u_core (")
    L.append("    " + ",\n    ".join(conns))
    L.append("  );")
    L.append("endmodule")
    L.append("")
    return L

def gen_tb():
    L = []
    L.append("// 自动生成: scripts/gen_ibuffer.py —— 勿手改")
    L.append("`timescale 1ns/1ps")
    L.append("module tb;")
    L.append("  int unsigned NCYCLES = 120000;")
    L.append("  bit clk = 0, rst;")
    L.append("  int errors = 0, checks = 0;")
    L.append("  always #5 clk = ~clk;")
    L.append("")
    # input nets
    for (w, n) in INS:
        L.append(f"  logic {wsfx(w)}{n};")
    # output nets g_/i_
    for (w, n) in OUTS:
        L.append(f"  logic {wsfx(w)}g_{n};")
        L.append(f"  logic {wsfx(w)}i_{n};")
    L.append("")
    # instantiate golden and impl
    def inst(mod, instn, opref):
        c = [".clock(clk)", ".reset(rst)"]
        for (w, n) in INS:
            c.append(f".{n}({n})")
        for (w, n) in OUTS:
            c.append(f".{n}({opref}{n})")
        return f"  {mod} {instn} (" + ", ".join(c) + ");"
    L.append(inst("IBuffer", "u_g", "g_"))
    L.append(inst("IBuffer_xs", "u_i", "i_"))
    L.append("")
    # stimulus
    L.append("  always @(negedge clk) begin")
    L.append("    if (rst) begin")
    L.append("      io_in_valid <= 1'b0;")
    L.append("      io_flush <= 1'b0;")
    L.append("      io_decodeCanAccept <= 1'b0;")
    L.append("      io_stallReason_backReason_valid <= 1'b0;")
    L.append("    end else begin")
    for (w, n) in INS:
        if n == "io_in_valid":
            L.append(f"      {n} <= ($urandom_range(0,3) != 0);")
        elif n == "io_flush":
            L.append(f"      {n} <= ($urandom_range(0,31) == 0);")
        elif n == "io_decodeCanAccept":
            L.append(f"      {n} <= ($urandom_range(0,3) != 0);")
        elif n == "io_in_bits_valid":
            # 16-bit contiguous-low mask (valid is a leading run typically); use random
            L.append(f"      {n} <= 16'($urandom);")
        elif n == "io_in_bits_enqEnable":
            L.append(f"      {n} <= 16'($urandom);")
        elif n == "io_stallReason_backReason_valid":
            L.append(f"      {n} <= ($urandom_range(0,7) == 0);")
        elif n.endswith("_value") or n.endswith("_bits") or "instrs" in n or "_pc_" in n \
                or "foldpc" in n or "exceptionType" in n or "triggered" in n \
                or "brType" in n or "backReason_bits" in n or "reasons" in n \
                or n.endswith("_flag"):
            if w <= 32:
                L.append(f"      {n} <= {w}'($urandom);")
            else:
                nw = (w + 31) // 32
                parts = ", ".join("$urandom()" for _ in range(nw))
                L.append(f"      {n} <= {w}'({{{parts}}});")
        else:
            L.append(f"      {n} <= {w}'($urandom);")
    L.append("    end")
    L.append("  end")
    L.append("")
    # compare
    L.append("  always @(negedge clk) if (!rst) begin")
    L.append("    #4; checks++;")
    for (w, n) in OUTS:
        L.append(f"    if (g_{n} !== i_{n}) begin errors++;")
        L.append(f"      if(errors<=40) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
    L.append("  end")
    L.append("")
    L.append("  initial begin")
    L.append("    rst = 1; repeat (5) @(posedge clk); rst = 0;")
    L.append("    repeat (NCYCLES) @(posedge clk);")
    L.append("    $display(\"checks=%0d errors=%0d\", checks, errors);")
    L.append("    if (errors == 0 && checks > 1000) $display(\"TEST PASSED\"); else $display(\"TEST FAILED\");")
    L.append("    $finish;")
    L.append("  end")
    L.append("endmodule")
    L.append("")
    return L


def writef(path, lines):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write("\n".join(lines))
    print("wrote", path)


def main():
    core = build_core()
    writef(os.path.join(ROOT, "rtl", "frontend", "IBuffer.sv"), core)
    writef(os.path.join(ROOT, "rtl", "frontend", "IBuffer_wrapper.sv"), gen_wrapper("IBuffer"))
    utd = os.path.join(ROOT, "verif", "ut", "IBuffer")
    writef(os.path.join(utd, "variants_xs.sv"), gen_wrapper("IBuffer_xs"))
    writef(os.path.join(utd, "tb.sv"), gen_tb())
    # fm_map: 本模块无打包 payload, 留空文件 (auto_match 处理展平命名一致即可)
    writef(os.path.join(utd, "fm_map", "IBuffer.txt"), ["# IBuffer 无打包 payload; 寄存器名与 golden 一致, 由 FM 按名匹配", ""])

if __name__ == "__main__":
    main()
