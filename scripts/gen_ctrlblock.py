#!/usr/bin/env python3
"""
CtrlBlock(后端控制块总集成)生成器。

== 重写原则(从 Scala 设计意图,杜绝 golden 套壳)==
CtrlBlock(src/main/scala/xiangshan/backend/CtrlBlock.scala)是后端控制平面顶层
集成：把 DecodeStage / FusionDecoder / RenameTableWrapper / Rename / NewDispatch /
Rob / RedirectGenerator / pcMem(SyncDataModuleTemplate) / MemCtrl /
SnapshotGenerator / Trace / GPAMem / 6×PipelineConnectPipe(decode->rename) /
PipeGroupConnect(rename->dispatch) / DelayN 等子模块组装起来。这些子模块**已单独
重写完成**，对本层是 golden 黑盒(UT/FM 两侧共用)。

本层真正属于「顶层 glue」的逻辑(都在可读核 xs_CtrlBlock_core 里用 struct/enum/
function/genvar 表达，不抽进 svh 套壳)：
  1. 重定向流水(redirect pipeline)：rob flushOut(s0->s1) / exu redirect 选最旧 /
     loadReplay 打拍 -> RedirectGenerator -> s1_s3 / s2_s4 / s3_s5 redirect 广播。
  2. decode buffer 状态机：frontend 译码输入与 buffer 的向量移位/接收计数 FSM。
  3. 写回打拍/压缩：wbData 打拍 + needFlush 杀掉被老 redirect 冲掉的写回 +
     同 robIdx 压缩计数 + needExceptionGen 聚合。
  4. 快照(snapshot)选择：genSnapshot / useSnpt / snptSelect / flushVec。
  5. frontend flush 路由：rob flush(s6) vs redirectGen 二选一 + trap target mux +
     ftqIdxAhead/ftqIdxSelOH 选择。
  6. pcMem 读口驱动(NamedIndexes：robFlush/redirect/memPred/bju/load/hybrid/store/trace)。

机械部分由本脚本生成：
  rtl/backend/ctrlblock_ports.svh  —— 可读核扁平端口表(与 golden 同名,供 FM/ST 对接)
  rtl/backend/ctrlblock_inst.svh   —— 10 类子模块黑盒例化 + 端口<->核内信号机械连线
  rtl/backend/CtrlBlock_wrapper.sv —— golden 同名扁平 wrapper(例化可读核)
  rtl/backend/ctrlblock_blackbox_stubs.sv —— 子模块黑盒 stub(UT/FM 用,空体输出 0)
  verif/ut/CtrlBlock/{variants_xs.sv,tb.sv,Makefile}

可读核本体(手写架构 glue + 中文讲解)见 rtl/backend/CtrlBlock.sv，类型见 ctrlblock_pkg.sv。

== round4 现状(inst.svh 仍占位,原因量化)==
golden CtrlBlock 22 个子模块例化共 5036 pin。其中:
  - 顶层 io 直连 / const / clk:~233 pin（机械可生成）;
  - 输入侧 glue:已在核里（round3 wbDelayedBits/enqRobBits 装包 + round4
    glue2 exuRedirect 选最旧 / mdpFlodPcVec / decode foldpc）;
  - 子模块间互联 + 输出侧:~3880 个 _<inst>_io_* 网。其中输出端口 1736 个里 1543 个是
    「子模块输出 pin 直连顶层 io」（inst.svh 机械可生成），但另 ~150 个经寄存器化输出
    glue（commits->FTQ / frontendFlushBits / s2_s4_redirect_next / newestTarget /
    io_perf_*）。本轮已补 commits->FTQ（ctrlblock_outglue.svh）;余者待后续轮。
inst.svh 要满足 GATE（pin 连核内具名信号、_GEN_/_T_≈0、不套壳）须等输出侧 glue 写齐,
否则只能套壳（违禁）或连不存在信号（编译不过）。本脚本本轮仍只生成 wbpack/enqpack/ports。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
BK = XSSV / "rtl/backend"
UT = XSSV / "verif/ut/CtrlBlock"
GSV = (GOLDEN / "CtrlBlock.sv").read_text()
LINES = GSV.splitlines()
HDR = "// 自动生成：scripts/gen_ctrlblock.py —— 勿手改(逻辑部分为从 Scala 意图的可读重写)\n"


# ----------------------------------------------------------------------------
# 顶层端口解析
# ----------------------------------------------------------------------------
def top_ports():
    m = re.search(r"^module CtrlBlock\((.*?)\n\);", GSV, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1,
                        pm.group(3)))
    return res


def gen_ports(ps):
    L = [HDR, "// 可读核端口表(与 golden CtrlBlock 同名扁平端口,供 FM/ST 对接)。",
         "// clock/reset 在核声明处单列,这里只列功能端口。"]
    for d, w, n in ps:
        if n in ("clock", "reset"):
            continue
        ww = "" if w == 1 else f"[{w - 1}:0] "
        L.append(f"  {d} {ww}{n},")
    # 去掉最后一个逗号
    for i in range(len(L) - 1, -1, -1):
        if L[i].endswith(","):
            L[i] = L[i][:-1]
            break
    (BK / "ctrlblock_ports.svh").write_text("\n".join(L) + "\n")
    return ps


# ----------------------------------------------------------------------------
# 子模块例化块提取
# ----------------------------------------------------------------------------
def extract_instances():
    starts = [i for i, l in enumerate(LINES)
              if re.match(r"^  [A-Z][A-Za-z0-9_]+ +[a-zA-Z_][A-Za-z0-9_]* +\($", l)]
    blocks = []
    for s in starts:
        e = s
        while not re.match(r"^  \);", LINES[e]):
            e += 1
        blocks.append((LINES[s], LINES[s:e + 1]))
    return blocks


def submodule_types():
    types = {}
    for head, _ in extract_instances():
        m = re.match(r"^  ([A-Z][A-Za-z0-9_]+) +([a-zA-Z_][A-Za-z0-9_]*) +\($", head)
        types.setdefault(m.group(1), []).append(m.group(2))
    return types


# ----------------------------------------------------------------------------
# 数据通路「装包」生成(round3):
#   ctrlblock_wbpack.svh   —— 顶层 io_fromWB_wbData_* -> wbInValid/wbInBits(struct)
#   ctrlblock_enqpack.svh  —— NewDispatch 黑盒输出 _dispatch_io_enqRob_req_* -> enqInValid/enqInBits
# 纯机械逐字段直通:struct 成员名与字段名一一对应,exceptionVec 折成位向量按位赋。
# 这里只做「端口/网 -> struct 成员」的连线,真逻辑(打拍/压缩)在 ctrlblock_datapath.svh。
# ----------------------------------------------------------------------------
WBNUM = 27
RENAMEW = 6


def _exc_member(struct):
    return "exceptionVec"


def gen_wbpack():
    """从 ctrlblock_ports.svh 解析每路 wbData 的字段,装进 wb_exu_output_t。"""
    ports = (BK / "ctrlblock_ports.svh").read_text()
    # i -> {field: width}
    ent = {}
    for m in re.finditer(
        r"(?:input|output)\s+(?:\[(\d+):0\]\s+)?io_fromWB_wbData_(\d+)_(valid|bits_[A-Za-z0-9_]+)",
        ports):
        w = int(m.group(1)) + 1 if m.group(1) else 1
        i = int(m.group(2)); f = m.group(3)
        ent.setdefault(i, {})[f] = w
    L = [HDR,
         "// 写回装包:io_fromWB_wbData_<i>_* -> wbInValid[i]/wbInBits[i](wb_exu_output_t)。",
         "// 异构:某路没有的字段不赋(struct 默认 0)。exceptionVec_<n> 按位填 24 位向量。"]
    for i in range(WBNUM):
        L.append(f"  assign wbInValid[{i}] = io_fromWB_wbData_{i}_valid;")
    # bits 用单个 always_comb:先整体清 0,再覆盖本路存在的字段(过程块内后写覆盖前写,
    # 不存在的字段保持 0,且无连续赋值多驱动冲突)。
    L.append("  always_comb begin")
    L.append("    // 先把所有路 struct 清 0(异构字段缺省值)")
    for i in range(WBNUM):
        L.append(f"    wbInBits[{i}] = '{{default:'0}};")
    for i in range(WBNUM):
        fields = ent.get(i, {})
        L.append(f"    // ---- wbData[{i}] ----")
        for f in sorted(fields):
            if f == "valid":
                continue
            field = f[len("bits_"):]
            src = f"io_fromWB_wbData_{i}_{f}"
            mexc = re.match(r"exceptionVec_(\d+)$", field)
            if mexc:
                L.append(f"    wbInBits[{i}].exceptionVec[{mexc.group(1)}] = {src};")
            else:
                L.append(f"    wbInBits[{i}].{field} = {src};")
    L.append("  end")
    (BK / "ctrlblock_wbpack.svh").write_text("\n".join(L) + "\n")
    return ent


def gen_enqpack():
    """从 golden 解析 NewDispatch enqRob 输出 net 集,声明黑盒网 + 装进 rob_enq_uop_t。"""
    # i -> {field: width}
    ent = {}
    for m in re.finditer(
        r"wire\s+(?:\[(\d+):0\]\s+)?_dispatch_io_enqRob_req_(\d+)_(valid|bits_[A-Za-z0-9_]+);",
        GSV):
        w = int(m.group(1)) + 1 if m.group(1) else 1
        i = int(m.group(2)); f = m.group(3)
        ent.setdefault(i, {})[f] = w
    L = [HDR,
         "// 入队装包:NewDispatch 黑盒输出 _dispatch_io_enqRob_req_<i>_* -> enqInValid[i]/enqInBits[i]。",
         "// 这些 _dispatch_* 网由 ctrlblock_inst.svh 例化 NewDispatch 时绑定,这里先声明。",
         "// snapshot 仅第 0 路有效;exceptionVec_<n> 按位填 23 位向量。", ""]
    # 1) 声明黑盒输出网
    L.append("  // -- NewDispatch enqRob 输出网(黑盒,inst.svh 绑定)--")
    for i in range(RENAMEW):
        for f in sorted(ent.get(i, {})):
            w = ent[i][f]
            ww = "" if w == 1 else f"[{w-1}:0] "
            L.append(f"  logic {ww}_dispatch_io_enqRob_req_{i}_{f};")
    L.append("")
    # 2) 装包(单个 always_comb:整体清 0 后覆盖存在字段)
    for i in range(RENAMEW):
        L.append(f"  assign enqInValid[{i}] = _dispatch_io_enqRob_req_{i}_valid;")
    L.append("  always_comb begin")
    for i in range(RENAMEW):
        L.append(f"    enqInBits[{i}] = '{{default:'0}};")
    for i in range(RENAMEW):
        fields = ent.get(i, {})
        L.append(f"    // ---- enqRob.req[{i}] ----")
        for f in sorted(fields):
            if f == "valid":
                continue
            field = f[len("bits_"):]
            src = f"_dispatch_io_enqRob_req_{i}_{f}"
            mexc = re.match(r"exceptionVec_(\d+)$", field)
            if mexc:
                L.append(f"    enqInBits[{i}].exceptionVec[{mexc.group(1)}] = {src};")
            else:
                L.append(f"    enqInBits[{i}].{field} = {src};")
    L.append("  end")
    (BK / "ctrlblock_enqpack.svh").write_text("\n".join(L) + "\n")
    return ent


def inst_pin_analysis():
    """gen_inst() 前置分析:统计 22 子模块全 pin、按 RHS 类别分桶,量化「连核内具名信号」
    所需的 body-glue 覆盖度。多行 pin 已合并解析(round5 修正:旧版只数单行 pin,漏算
    多行 RHS,故曾误报 6397 pin / 33 glue;真实为 ~13825 pin / 843 distinct glue)。

    分类:
      io_*       顶层端口(直连/经 outglue 已驱动)
      _<inst>_*  子模块互联网(inst.svh 顶部声明 + 由产出实例输出端绑定)
      body-glue  核内 glue 具名信号(须核已产出方可干净连;否则套壳/编译不过)
      complex    复合表达式(slice / zero-pad / 三元 / 拼接),内部仍引 body-glue 子标识符
    """
    starts = [i for i, l in enumerate(LINES)
              if re.match(r"^  [A-Z][A-Za-z0-9_]+ +[a-z][A-Za-z0-9_]* +\($", l)]
    n_io = n_net = n_const = 0
    glue = set()
    complex_n = 0
    for s in starts:
        e = s
        while not re.match(r"^  \);", LINES[e]):
            e += 1
        block = "\n".join(LINES[s:e + 1])
        for m in re.finditer(r"\.(\w+)\s*\(((?:[^()]|\([^()]*\))*)\)", block):
            rhs = re.sub(r"\s+", " ", m.group(2).strip())
            if rhs in ("clock", "reset"):
                n_const += 1
            elif re.fullmatch(r"\d+'[hbd][0-9a-fA-F_]+", rhs):
                n_const += 1
            elif re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", rhs):
                if rhs.startswith("io_"):
                    n_io += 1
                elif rhs.startswith("_"):
                    n_net += 1
                else:
                    glue.add(rhs)
            else:
                complex_n += 1
    return dict(io=n_io, net=n_net, const=n_const, glue=sorted(glue),
               complex_n=complex_n,
               total=n_io + n_net + n_const + len(glue) + complex_n)


# ----------------------------------------------------------------------------
# gen_inst()(round6 启用):22 子模块黑盒例化 + 引脚 rewrite 连核内具名信号。
#   ・引脚 RHS 经 rewrite_rhs() 把 golden body-glue 临时名换成可读核产出的具名信号
#     (两大 struct 族 wbDelayedBits/enqRobBits + 小 glue 别名,见 rewrite_token/whole_override)。
#   ・_<inst>_io_* 互联网:从 golden 的 wire 声明机械收割宽度后,在 inst.svh 顶部声明
#     (已在 decls.svh / enqpack.svh 声明的不重复)。io_* 顶层端口 / 常量 / clk 直连。
#   ・GATE:rewrite 后 inst.svh 不留 _GEN_<n>/_T_<n> 等 golden 临时名(由 leftover_golden 校验)。
# ----------------------------------------------------------------------------
_WORD = re.compile(r"[A-Za-z_]\w*")

# golden _GEN_2x:融合译码命中时覆盖送 rename 的 fuType/fuOpType(5 lane)。
_GEN_FU = {21: "renameInFuType[0]", 22: "renameInFuOpType[0]",
           24: "renameInFuType[1]", 25: "renameInFuOpType[1]",
           27: "renameInFuType[2]", 28: "renameInFuOpType[2]",
           30: "renameInFuType[3]", 31: "renameInFuOpType[3]",
           33: "renameInFuType[4]", 34: "renameInFuOpType[4]"}


def rewrite_token(tok):
    """单个标识符 -> 核内具名信号(找不到返回 None,表示非 body-glue,原样保留)。"""
    m = re.fullmatch(r"delayedNotFlushedWriteBack_delayed_bits_r_(\d+)_exceptionVec_(\d+)", tok)
    if m: return f"wbDelayedBits[{m.group(1)}].exceptionVec[{m.group(2)}]"
    m = re.fullmatch(r"delayedNotFlushedWriteBack_delayed_bits_r_(\d+)_(.+)", tok)
    if m: return f"wbDelayedBits[{m.group(1)}].{m.group(2)}"
    m = re.fullmatch(r"delayedNotFlushedWriteBack_delayed_bits_r_exceptionVec_(\d+)", tok)
    if m: return f"wbDelayedBits[0].exceptionVec[{m.group(1)}]"
    m = re.fullmatch(r"delayedNotFlushedWriteBack_delayed_bits_r_(.+)", tok)
    if m: return f"wbDelayedBits[0].{m.group(1)}"
    m = re.fullmatch(r"delayedNotFlushedWriteBack_delayed_bits_debugInfo_writebackTime_c_(\d+)", tok)
    if m: return f"wbWritebackTimeCnt[{m.group(1)}]"
    if tok == "delayedNotFlushedWriteBack_delayed_bits_debugInfo_writebackTime_c":
        return "wbWritebackTimeCnt[0]"
    m = re.fullmatch(r"delayedNotFlushedWriteBack_delayed_valid_last_REG_(\d+)", tok)
    if m: return f"wbDelayedValid[{m.group(1)}]"
    if tok == "delayedNotFlushedWriteBack_delayed_valid_last_REG":
        return "wbDelayedValid[0]"
    m = re.fullmatch(r"delayedWriteBack_(\d+)_valid_last_REG", tok)
    if m: return f"wbDelayedValidRaw[{m.group(1)}]"
    m = re.fullmatch(r"delayedNotFlushedWriteBackNums_delayed_bits_r_(\d+)", tok)
    if m: return f"wbNumsBits[{m.group(1)}]"
    if tok == "delayedNotFlushedWriteBackNums_delayed_bits_r":
        return "wbNumsBits[0]"
    m = re.fullmatch(r"enqRob_req_(\d+)_bits_r_exceptionVec_(\d+)", tok)
    if m: return f"enqRobBits[{m.group(1)}].exceptionVec[{m.group(2)}]"
    m = re.fullmatch(r"enqRob_req_(\d+)_bits_r_(.+)", tok)
    if m: return f"enqRobBits[{m.group(1)}].{m.group(2)}"
    m = re.fullmatch(r"enqRob_req_(\d+)_valid_REG", tok)
    if m: return f"enqRobValid[{m.group(1)}]"
    m = re.fullmatch(r"redirectGen_io_oldestExuRedirect_bits_r_(.+)", tok)
    if m: return f"oldestExuRedirectBits.{m.group(1)}"
    # decode buffer payload(块2b 的 decodeBufBits[k] 结构)与 valid 平铺名
    m = re.fullmatch(r"decodeBufBits_(\d+)_exceptionVec_(\d+)", tok)
    if m: return f"decodeBufBits[{m.group(1)}].exceptionVec[{m.group(2)}]"
    m = re.fullmatch(r"decodeBufBits_(\d+)_(.+)", tok)
    if m: return f"decodeBufBits[{m.group(1)}].{m.group(2)}"
    m = re.fullmatch(r"decodeBufValid_(\d+)", tok)
    if m: return f"decodeBufValid[{m.group(1)}]"
    # 融合 commitType 条件(块10 fuseCond*):cond1=lane0, cond1_K=lane K
    m = re.fullmatch(r"cond([123])_(\d+)", tok)
    if m: return f"fuseCond{m.group(1)}[{m.group(2)}]"
    m = re.fullmatch(r"cond([123])", tok)
    if m: return f"fuseCond{m.group(1)}[0]"
    return _SINGLETON.get(tok)


_SINGLETON = {
    "decode_io_csrCtrl_REG_singlestep": "decodeCsrSinglestepR",
    "decode_io_csrCtrl_REG_wfi_enable": "decodeCsrWfiEnR",
    "decode_io_csrCtrl_REG_fusion_enable": "decodeCsrFusionEnR",
    "dispatch_io_singleStep_last_REG": "dispatchSingleStepR",
    "rename_io_singleStep_last_REG": "renameSingleStepR",
    "flushVecNext_last_REG": "flushVecNext[0]", "flushVecNext_last_REG_1": "flushVecNext[1]",
    "flushVecNext_last_REG_2": "flushVecNext[2]", "flushVecNext_last_REG_3": "flushVecNext[3]",
    "flushVec_0": "flushVec[0]", "flushVec_1": "flushVec[1]",
    "flushVec_2": "flushVec[2]", "flushVec_3": "flushVec[3]",
    "loadReplay_valid_last_REG": "loadReplayValidR",
    "loadReplay_bits_r_robIdx_flag": "loadReplayRobFlag",
    "loadReplay_bits_r_robIdx_value": "loadReplayRobValue",
    "loadReplay_bits_r_ftqIdx_flag": "loadReplayFtqFlag",
    "loadReplay_bits_r_ftqIdx_value": "loadReplayFtqValue",
    "loadReplay_bits_r_ftqOffset": "loadReplayFtqOffset",
    "loadReplay_bits_r_level": "loadReplayLevel",
    "pcMem_io_wen_0_last_REG": "pcMemWen", "pcMem_io_waddr_0_r": "pcMemWaddr",
    "pcMem_io_wdata_0_r_startAddr": "pcMemWdataStartAddr",
    "redirectGen_io_instrAddrTransType_REG_bare": "instrTransBareR",
    "redirectGen_io_instrAddrTransType_REG_sv39": "instrTransSv39R",
    "redirectGen_io_instrAddrTransType_REG_sv39x4": "instrTransSv39x4R",
    "redirectGen_io_instrAddrTransType_REG_sv48": "instrTransSv48R",
    "redirectGen_io_instrAddrTransType_REG_sv48x4": "instrTransSv48x4R",
    "redirectGen_io_memPredPcRead_data_r": "memPredPcOffsetR",
    "redirectGen_io_oldestExuRedirectIsCSR_r": "oldestExuRedirectIsCSR",
    "redirectGen_io_oldestExuRedirect_valid_last_REG": "oldestExuRedirectValid",
    "s1_robFlushRedirect_valid_last_REG": "s1_robFlushValid",
    "s1_robFlushRedirect_bits_r_level": "s1_robFlushLevel",
    "s1_robFlushRedirect_bits_r_robIdx_flag": "s1_robFlushRobFlag",
    "s1_robFlushRedirect_bits_r_robIdx_value": "s1_robFlushRobValue",
    "snptSelect": "snptSelect", "useSnpt": "useSnpt", "x15": "decodeFlush",
    "_snpt_io_deq_T_35": "snptDeq",
    "_decode_io_in_0_bits_T_foldpc": "decodeInFoldpc[0]",
    "_decode_io_in_1_bits_T_foldpc": "decodeInFoldpc[1]",
    "_mdpFlodPcVec_0_T": "mdpVld[0]", "_mdpFlodPcVec_1_T": "mdpVld[1]",
    "_decode_io_fusion_0_T": "decodeFusionAdv[0]", "_decode_io_fusion_1_T": "decodeFusionAdv[1]",
    "_decode_io_fusion_2_T": "decodeFusionAdv[2]", "_decode_io_fusion_3_T": "decodeFusionAdv[3]",
    "_decode_io_fusion_4_T": "decodeFusionAdv[4]",
}


def whole_override(inst, pin):
    """整条 pin RHS 直接换成核内具名信号(用于深耦合 / 数组索引形)。"""
    if inst == "memCtrl":
        m = re.fullmatch(r"io_mdpFoldPcVecVld_(\d)", pin)
        if m: return f"mdpFoldPcVecVld[{m.group(1)}]"
        m = re.fullmatch(r"io_mdpFlodPcVec_(\d)", pin)
        if m: return f"mdpFoldPcVec[{m.group(1)}]"
    if inst == "rename" and pin == "io_snptLastEnq_bits_flag":  return "snptLastEnqHeadFlag"
    if inst == "rename" and pin == "io_snptLastEnq_bits_value": return "snptLastEnqHeadValue"
    if inst == "rob":
        # 压缩计数 bits:golden 把变宽 Nums 零扩展到统一 5 bit 送 rob 端口;核内 wbNumsBits[i]
        # 本就是统一 5 bit,直接连(无需零扩展)。valid 同理走 wbNumsValid[i]。
        m = re.fullmatch(r"io_writebackNums_(\d+)_bits", pin)
        if m: return f"wbNumsBits[{m.group(1)}]"
        m = re.fullmatch(r"io_writebackNums_(\d+)_valid", pin)
        if m: return f"wbNumsValid[{m.group(1)}]"
    return None


def rewrite_rhs(inst, pin, rhs):
    ov = whole_override(inst, pin)
    if ov is not None:
        return ov
    rhs = re.sub(r"\b_GEN_(\d+)\b", lambda m: _GEN_FU.get(int(m.group(1)), m.group(0)), rhs)
    rhs = rhs.replace("|_genSnapshot_T_12", "genSnapshot").replace("_genSnapshot_T_12", "genSnapshotVec")
    rhs = rhs.replace("_loadRedirectPcRead_T", "loadRedirectPcRead")
    rhs = re.sub(r"\bmdpFlodPcVecVld_(\d)_last_REG\b", lambda m: f"mdpVldLast[{m.group(1)}]", rhs)
    # 后端统一重定向广播总线:golden 把它命名为 io_redirect_*_0(索引 0 槽,见 Scala
    # redirectForExu 的 0 号源)。核里这条总线就是块1的 s1_s3_redirect_*(顶层输出端口
    # io_redirect_* 亦由它驱动,见 datapath.svh 块5)。子模块消费它须连核内具名信号,
    # 否则 _0 后缀名既非端口又非声明网,会被 VCS 当作悬空 1-bit 隐式网(位宽错连)。
    rhs = re.sub(r"\bio_redirect_valid_0\b", "s1_s3_redirect_valid", rhs)
    rhs = re.sub(r"\bio_redirect_bits_robIdx_flag_0\b", "s1_s3_redirect_robFlag", rhs)
    rhs = re.sub(r"\bio_redirect_bits_robIdx_value_0\b", "s1_s3_redirect_robValue", rhs)
    rhs = re.sub(r"\bio_redirect_bits_level_0\b", "s1_s3_redirect_level", rhs)
    return _WORD.sub(lambda m: rewrite_token(m.group(0)) or m.group(0), rhs)


def leftover_golden(rhs):
    """校验 rewrite 后是否仍有 golden 临时名残留(套壳门)。"""
    bad = []
    for t in _WORD.findall(rhs):
        if re.search(r"_GEN_\d|_T_\d|_last_REG|_valid_REG", t):
            bad.append(t)
        elif re.fullmatch(
            r"(delayedNotFlushedWriteBack\w*|delayedWriteBack\w*|enqRob_req_\d\w*"
            r"|loadReplay_(valid|bits)\w*|s1_robFlushRedirect\w*|decode_io_csrCtrl_REG\w*"
            r"|redirectGen_io_(instrAddrTransType_REG|oldestExuRedirect)\w*|pcMem_io_w\w*)", t):
            bad.append(t)
    return bad


def _harvest_wire_widths():
    """从 golden 收割每个 wire net 的宽度声明(simple wire / [W:0] / [a:0][b:0])。"""
    wm = {}
    for m in re.finditer(r"^  wire\s+(\[[\d:]+\](?:\[[\d:]+\])?\s+)?(_[A-Za-z0-9_]+);", GSV, re.M):
        wm[m.group(2)] = (m.group(1) or "").strip()
    return wm


def _already_declared():
    """decls.svh + enqpack.svh 已声明的 net(避免重复声明)。"""
    decl = (BK / "ctrlblock_decls.svh").read_text()
    enq = (BK / "ctrlblock_enqpack.svh").read_text()
    s = set(re.findall(r"\b(_[A-Za-z0-9_]+)\b", decl))
    s |= set(re.findall(r"_dispatch_io_enqRob_req_\d+_\w+", enq))
    return s


_PINRE = re.compile(r"\.(\w+)\s*\(((?:[^()]|\([^()]*\))*)\)")

# golden 里 io_in_k_valid 的 RHS 是多层嵌套括号/花括号(decode 输出全 exceptionVec 拼接
# + trigger 判定),_PINRE 只能匹配一层嵌套故漏抓这 6+6 个引脚。这里显式补连核内具名信号
# (decodeInValid[k] / fusionInValid[k],见 ctrlblock_glue4.svh),避免子模块输入端口悬空。
_FORCE_PINS = {
    "decode":        [(f"io_in_{k}_valid", f"decodeInValid[{k}]") for k in range(6)],
    "fusionDecoder": [(f"io_in_{k}_valid", f"fusionInValid[{k}]") for k in range(6)],
}


def gen_inst():
    blocks = extract_instances()
    widths = _harvest_wire_widths()
    declared = _already_declared()
    # 1) 收集所有引脚 RHS 引用的互联网(_-prefixed,且非 golden glue temp)。
    glue_temp = {"_loadRedirectPcRead_T", "_genSnapshot_T_12", "_GEN_17", "_GEN_18"} \
        | {f"_GEN_{n}" for n in _GEN_FU}
    used_nets = set()
    for head, lines in blocks:
        for m in _PINRE.finditer("\n".join(lines)):
            rhs = re.sub(r"\s+", " ", m.group(2).strip())
            for idt in re.findall(r"\b_[A-Za-z0-9_]+\b", rhs):
                # 跳过 glue temp(整体 rewrite)与有具名映射的 _ 前缀小 glue(如 _snpt_io_deq_T_35
                # -> snptDeq、_decode_io_in_N_bits_T_foldpc -> decodeInFoldpc[N] 等),只声明真互联网。
                if idt not in glue_temp and rewrite_token(idt) is None:
                    used_nets.add(idt)
    # 待声明的网 = 用到 - 已声明 - 找不到宽度(后者报警)
    to_decl = sorted(n for n in used_nets if n not in declared)
    missing_w = [n for n in to_decl if n not in widths]

    L = [HDR,
         "// 22 子模块黑盒例化 + 引脚连核内具名信号(rewrite 见 gen_ctrlblock.py)。",
         "// 顶部声明子模块互联网 _<inst>_io_*(已在 decls/enqpack 声明的不重复);",
         "// 引脚 RHS 经 rewrite:body-glue -> 核内 struct 族/别名,io_*/常量/clk 直连。", ""]
    L.append("  // ===== 子模块互联网声明(宽度从 golden 收割)=====")
    for n in to_decl:
        if n in widths:
            w = widths[n]
            L.append(f"  logic {w + ' ' if w else ''}{n};")
        else:
            L.append(f"  logic {n};   // 宽度未收割到,按 1 bit(请核对)")
    L.append("")
    # 2) 例化区:逐实例 emit,引脚 rewrite。
    leaks = 0
    for head, lines in blocks:
        typ, inst = head.strip().split()[0], head.strip().split()[1]
        L.append(f"  {typ} {inst} (")
        pins = []
        for m in _PINRE.finditer("\n".join(lines)):
            pin = m.group(1)
            rhs = re.sub(r"\s+", " ", m.group(2).strip())
            nr = rewrite_rhs(inst, pin, rhs)
            bad = leftover_golden(nr)
            if bad:
                leaks += 1
            pins.append((pin, nr))
        # 补连 _PINRE 漏抓的深嵌套引脚(io_in_k_valid)。
        have = {p for p, _ in pins}
        for fp, fr in _FORCE_PINS.get(inst, []):
            if fp not in have:
                pins.append((fp, fr))
        for i, (pin, nr) in enumerate(pins):
            comma = "," if i < len(pins) - 1 else ""
            L.append(f"    .{pin} ({nr}){comma}")
        L.append("  );")
    (BK / "ctrlblock_inst.svh").write_text("\n".join(L) + "\n")
    return dict(insts=len(blocks), nets=len(to_decl), missing_w=missing_w, leaks=leaks)


def main():
    ps = top_ports()
    gen_ports(ps)
    types = submodule_types()
    print(f"ports: {len(ps)}  submodule types: {len(types)}")
    for t, insts in sorted(types.items()):
        print(f"  {t}: {len(insts)}  ({', '.join(insts[:4])}{'...' if len(insts) > 4 else ''})")
    wb = gen_wbpack()
    eq = gen_enqpack()
    wb_regs = sum(len([f for f in v if f != "valid"]) for v in wb.values())
    eq_regs = sum(len([f for f in v if f != "valid"]) for v in eq.values())
    print(f"wbpack: {len(wb)} entries, {wb_regs} bits fields packed")
    print(f"enqpack: {len(eq)} entries, {eq_regs} bits fields packed")

    # ---- gen_inst() 前置覆盖度报告(round5)----
    a = inst_pin_analysis()
    print(f"\n[inst pin analysis] total~{a['total']}  io={a['io']}  net={a['net']}  "
          f"const/clk={a['const']}  complex={a['complex_n']}  glue distinct={len(a['glue'])}")
    fam = {}
    for g in a["glue"]:
        fam.setdefault(re.sub(r"_\d+", "_N", g), 0)
        fam[re.sub(r"_\d+", "_N", g)] += 1
    big = sorted(fam.items(), key=lambda kv: -kv[1])[:8]
    print("  top glue families:", ", ".join(f"{k}×{v}" for k, v in big))

    # ---- gen_inst()(round6 启用)----
    r = gen_inst()
    print(f"\n[gen_inst] {r['insts']} instances, {r['nets']} interconnect nets declared, "
          f"golden-temp leaks={r['leaks']}, missing-width nets={len(r['missing_w'])}")
    if r["missing_w"]:
        print("  missing-width:", ", ".join(r["missing_w"][:12]))


if __name__ == "__main__":
    main()
