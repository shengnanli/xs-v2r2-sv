#!/usr/bin/env python3
"""
TL2CHICoupledL2(L2 缓存主体:TileLink<->CHI 桥 + 多 bank L2 cache 阵列)装配层生成器。

== 重写原则(从 Scala/firtool 设计意图,杜绝 golden 套壳)==
TL2CHICoupledL2 是 L2 cache 的**主体装配**:把 4 个 L2 slice(cache 流水 + 目录 +
数据 + MSHR + snoop filter)与 prefetcher、MMIO 桥、CHI 链路监视、各通道仲裁器、
MBIST 自测分发拼成一个 TileLink(北,接 L1)<->CHI(南,接 L3/home)的 L2 主体。
本层做**装配互联 + 顶层 glue 重写**,29 个子模块实例对本层全部是 golden 黑盒。

与 L2Top/OpenLLC 不同,本层 glue 较重:golden firtool 产出 131 reg / 2 always /
80 assign,含 71 个 `_REG_<n>` 流水寄存器、20 个 `_T_<n>` + 6 个裸 `_T`、2 个
`_GEN_<n>` 匿名临时名。本脚本把这些 glue **从 Scala 意图重写成具名可读**(数组 +
generate-for + 具名信号),硬性闸门(`_REG_<n>`/`_T_<n>`/`_GEN_`/`io_*_n_m`/
RANDOMIZE,去注释)在核代码区 = 0。

glue 分 6 组(详见 coupledl2_glue.svh 顶注释):
  (1) MBIST 广播常量(全 0,未接,dontTouch);
  (2) L2->L1 hint 与 D 通道发射仲裁(hintFire / sliceCanFire / allCanFire 延迟链);
  (3) Grant 数据节拍计数 + hint 命中精度探针(dontTouch 统计);
  (4) 48 路性能计数 2 级打拍(4 slice × 12 事件,RegNext∘RegNext;事件 #2 恒 0);
  (5) l2Miss 汇聚打拍;
  (6) CHI rx 五通道按 bank 路由译码 + P-Credit grant 流水。

机械部分(ports/decls/inst/outassign/wrapper/stubs/filelist/ut)由本脚本生成,
glue 由本脚本以「具名可读重写」方式发出(perf 源映射从 golden always 块收割,
保证逐拍忠实)。inst/outassign 中跨入 glue 的临时名(d-ready / rx-bank-sel)按
RENAME 表做整词替换,与 glue 内具名信号一致。

产物:
  rtl/l2/coupledl2_ports.svh / coupledl2_decls.svh / coupledl2_glue.svh /
  rtl/l2/coupledl2_inst.svh / coupledl2_outassign.svh
  rtl/l2/TL2CHICoupledL2_wrapper.sv / coupledl2_blackbox_stubs.sv
  verif/ut/TL2CHICoupledL2/{variants_xs.sv,tb.sv,Makefile,golden_filelist.f}
可读核本体见 rtl/l2/TL2CHICoupledL2.sv(xs_TL2CHICoupledL2_core),类型见 coupledl2_pkg.sv。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
XC = XSSV / "rtl/l2"
UT = XSSV / "verif/ut/TL2CHICoupledL2"
GSV = (GOLDEN / "TL2CHICoupledL2.sv").read_text()
LINES = GSV.splitlines()
HDR = "// 自动生成:scripts/gen_coupledl2.py —— 勿手改(顶层 glue 为从 firtool 意图的具名可读重写)\n"

_WORD = re.compile(r"[A-Za-z_]\w*")

# 套壳闸门:rewrite 后核代码区不应残留 firtool 匿名临时名。
_BAN = re.compile(r"_REG_\d|_GEN_\d|_T_\d|RANDOMIZE|io_[a-z_]+_\d+_\d+")


def leftover_golden(s):
    return _BAN.findall(s)


# ----------------------------------------------------------------------------
# 跨区改名表:这些 firtool 临时名同时出现在 glue 与 inst/outassign。glue 内已用
# 右侧具名信号重写,故 inst/outassign 也按本表整词替换,保持一致。
#   · _slice_io_in_d_ready_T*  : 各 slice D 通道仲裁中标 / D ready(见 glue 第 2 组)
#   · _rx{snp,rsp,dat}_ready_T* : CHI rx 通道按 bank 路由译码(见 glue 第 6 组)
#   · io_l2Miss_REG            : l2Miss 汇聚寄存(见 glue 第 5 组)
#   · io_perf_<N>_value_REG_1  : perf 2 级打拍第 2 拍(见 glue 第 4 组,按正则单独处理)
# ----------------------------------------------------------------------------
RENAME = {
    "_slice_io_in_d_ready_T":   "sliceDArbWin[0]",
    "_slice_io_in_d_ready_T_2": "sliceDArbWin[1]",
    "_slice_io_in_d_ready_T_4": "sliceDArbWin[2]",
    "_slice_io_in_d_ready_T_6": "sliceDArbWin[3]",
    "_slice_io_in_d_ready_T_1": "sliceDReady[0]",
    "_slice_io_in_d_ready_T_3": "sliceDReady[1]",
    "_slice_io_in_d_ready_T_5": "sliceDReady[2]",
    "_slice_io_in_d_ready_T_7": "sliceDReady[3]",
    "_rxsnp_ready_T":   "snpBankSel0",
    "_rxsnp_ready_T_2": "snpBankSel1",
    "_rxsnp_ready_T_4": "snpBankSel2",
    "_rxrsp_ready_T":   "rspIsPCrdGrantOp",
    "_rxrsp_ready_T_1": "rspBankSel0",
    "_rxrsp_ready_T_3": "rspBankSel1",
    "_rxrsp_ready_T_5": "rspBankSel2",
    "_rxdat_ready_T":   "datBankSel0",
    "_rxdat_ready_T_2": "datBankSel1",
    "_rxdat_ready_T_4": "datBankSel2",
    "io_l2Miss_REG":    "l2MissReg",
    # l1HintArb 实例的 io_out_ready 引脚直接读 hint ready 沿寄存器(glue 第 2 组)。
    "l1HintArb_io_out_ready_REG": "hintArbOutReadyReg",
}


def apply_rename(text):
    for k in sorted(RENAME, key=len, reverse=True):
        text = re.sub(r"(?<![A-Za-z0-9_])" + re.escape(k) + r"(?![A-Za-z0-9_])",
                      RENAME[k].replace("\\", "\\\\"), text)
    # perf 第 2 拍:io_perf_<N>_value_REG_1 -> perfStage2[N]
    text = re.sub(r"(?<![A-Za-z0-9_])io_perf_(\d+)_value_REG_1(?![A-Za-z0-9_])",
                  r"perfStage2[\1]", text)
    return text


# ----------------------------------------------------------------------------
# 顶层端口
# ----------------------------------------------------------------------------
def top_ports():
    m = re.search(r"^module TL2CHICoupledL2\((.*?)\n\);", GSV, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1,
                        pm.group(3)))
    return res


def gen_ports(ps):
    L = [HDR, "// 可读核端口表(与 golden TL2CHICoupledL2 同名扁平端口,供 FM/ST 对接)。",
         "// clock/reset 在核声明处单列,这里只列功能端口。",
         "//   auto_in_0..3_*   北侧 TileLink client 节点(接 L1/core,A/B/C/D/E 五通道)",
         "//   auto_mmioBridge_* MMIO(uncacheable)请求桥端口",
         "//   io_chi_*         南侧 CHI 五通道 + 链路层(接 L3/home node)",
         "//   io_perf_*        48 路性能计数;io_l2Miss/io_l2_hint/io_debugTopDown 监视",
         "//   io_*PrefetchRecv_* prefetch 接收;io_error/io_nodeID/io_msStatus 等边界"]
    for d, w, n in ps:
        if n in ("clock", "reset"):
            continue
        ww = "" if w == 1 else f"[{w - 1}:0] "
        L.append(f"  {d} {ww}{n},")
    for i in range(len(L) - 1, -1, -1):
        if L[i].endswith(","):
            L[i] = L[i][:-1]
            break
    (XC / "coupledl2_ports.svh").write_text("\n".join(L) + "\n")
    return ps


# ----------------------------------------------------------------------------
# 子模块例化块提取(head 形如 `  Type  inst (`)
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
# 子模块互联网声明:从 golden 收割所有「不带初值」的 wire 声明(纯互联网)。
#   含:_<inst>_io_* 子模块输出网、glue 组合网 releaseSourceD_*/prefetchReqsReady_*、
#   _probe / bd_ack / bd_outdata 等。这些名字全部已通过套壳闸门(无匿名临时名),
#   原样收割宽度即可。带初值的(wire X = ...,即 glue 组合逻辑)与 reg 归入 glue。
# ----------------------------------------------------------------------------
def gen_decls():
    decls = []
    for m in re.finditer(
            r"^  wire\s+(\[\d+:0\]\s+)?([A-Za-z_][A-Za-z0-9_]*);$", GSV, re.M):
        w = (m.group(1) or "").strip()
        decls.append((w, m.group(2)))
    L = [HDR,
         "// 子模块(golden 黑盒)输出/互联网声明,宽度从 golden wire 声明收割。",
         "//   _<inst>_io_*           : 子模块输出引脚网(slice/arbiter/linkmon/mbist 互联);",
         "//   releaseSourceD_0..3    : 各 slice 因 hint 占用而本拍释放 D 的标志(glue 驱动);",
         "//   prefetchReqsReady_0..3 : prefetch 请求被路由到目标 bank slice 的 ready(glue 驱动);",
         "//   _probe / bd_ack / bd_outdata : dontTouch 探针 / MBIST 返回(未驱动功能输出)。",
         "// 由 coupledl2_inst.svh 绑定子模块输出引脚,glue/outassign 消费。", ""]
    for w, n in decls:
        L.append(f"  logic {w + ' ' if w else ''}{n};")
    (XC / "coupledl2_decls.svh").write_text("\n".join(L) + "\n")
    return dict(nets=len(decls))


# ----------------------------------------------------------------------------
# 顶层 glue —— 从 firtool 意图重写为具名可读(本层核心工作)。
#   perf 源映射从 golden always 块收割(io_perf_<N>_value_REG <= <src>),保证逐拍忠实。
# ----------------------------------------------------------------------------
def perf_source_map():
    """返回 {N: src_expr}(N=1..48),从 golden always 块的 io_perf_N_value_REG <= 收割。"""
    m = {}
    for mm in re.finditer(r"io_perf_(\d+)_value_REG <= ([^;]+);", GSV):
        m[int(mm.group(1))] = re.sub(r"\s+", " ", mm.group(2).strip())
    return m


def gen_glue():
    pm = perf_source_map()
    assert len(pm) == 48, f"perf 源应有 48 路,实得 {len(pm)}"

    L = [HDR]
    L += [
        "// ===================================================================",
        "// TL2CHICoupledL2 顶层 glue —— 从 firtool 产出的匿名流水(_REG_<n>/_T_<n>/",
        "// _GEN_<n>)重写为具名可读信号 + 数组 + generate-for,语义逐拍等价。",
        "// 共 6 组:",
        "//   (1) MBIST 广播常量(全 0,未接,dontTouch);",
        "//   (2) L2->L1 hint 与 D 通道发射仲裁(hintFire / sliceCanFire / allCanFire);",
        "//   (3) Grant 数据节拍计数 + hint 命中精度探针(dontTouch 统计);",
        "//   (4) 48 路性能计数 2 级打拍(4 slice × 12 事件;事件 #2 恒 0);",
        "//   (5) l2Miss 汇聚打拍;",
        "//   (6) CHI rx 五通道按 bank 路由译码 + P-Credit grant 流水。",
        "// ===================================================================",
        "",
        "  // ---- (1) MBIST 广播接口:本配置未接外部广播,全部恒 0(dontTouch,未驱动输出)。",
        "  wire         bd_all     = 1'h0;",
        "  wire         bd_req     = 1'h0;",
        "  wire         bd_writeen = 1'h0;",
        "  wire         bd_readen  = 1'h0;",
        "  wire [103:0] bd_indata  = 104'h0;",
        "  wire [12:0]  bd_addr    = 13'h0;",
        "  wire [12:0]  bd_addr_rd = 13'h0;",
        "  wire [7:0]   bd_be      = 8'h0;",
        "  wire [5:0]   bd_array   = 6'h0;",
        "  // bd_ack / bd_outdata 声明见 decls,这里直连 mbistPl 返回(未被下游消费)。",
        "  assign bd_ack     = _mbistPl_mbist_ack;",
        "  assign bd_outdata = _mbistPl_mbist_outdata;",
        "",
        "  // ---- (2) L2->L1 hint 与各 slice D 通道发射仲裁 ----------------------",
        "  // hintArbOutReadyReg:hint 仲裁输出 ready 的上一拍(用于产生发射沿)。",
        "  reg          hintArbOutReadyReg;",
        "  // hintFire:本拍 L1HintArb 选出的 hint 真正发射 = 上拍未 ready & 本拍 valid",
        "  //           & 目标 sourceId 落在 L1 范围(高位为 0 且低 6 位 < 0x24)。",
        "  wire         hintFire =",
        "    ~hintArbOutReadyReg & _l1HintArb_io_out_valid",
        "    & _l1HintArb_io_out_bits_sourceId[31:6] == 26'h0",
        "    & _l1HintArb_io_out_bits_sourceId[5:0] < 6'h24;",
        "  // hintChosen[i]:本拍 hint 仲裁选中的 slice(L1HintArb.chosen == i)。",
        "  wire [3:0]   hintChosen;",
        "  assign hintChosen[0] = _l1HintArb_io_chosen == 2'h0;",
        "  assign hintChosen[1] = _l1HintArb_io_chosen == 2'h1;",
        "  assign hintChosen[2] = _l1HintArb_io_chosen == 2'h2;",
        "  assign hintChosen[3] = &_l1HintArb_io_chosen;          // == 2'h3",
        "",
        "  // 每个 slice 一组「hint 发射阻塞」延迟链:hint 命中该 slice 时,把它的 D 通道",
        "  // 释放延后——A 链 2 拍、B 链 3 拍,任一有效即该 slice 本拍可发射(sliceCanFire)。",
        "  // 每个寄存器是 4 bit 向量(每 bit 一个 slice),逐拍移位。",
        "  reg  [3:0]   hintBlockA0, hintBlockA1;             // A 链两级",
        "  reg  [3:0]   hintBlockB0, hintBlockB1, hintBlockB2; // B 链三级",
        "  wire [3:0]   sliceCanFire = hintBlockA1 | hintBlockB2;",
        "",
        "  // allCanFire:无 hint 命中(~hintFire 同样经 2 拍 / 3 拍延迟)时全体可发射,",
        "  //            或任一 slice 已请求释放 D(releaseSourceD)。",
        "  reg          allBlockA0, allBlockA1;               // A 链两级(~hintFire)",
        "  reg          allBlockB0, allBlockB1, allBlockB2;   // B 链三级",
        "  wire         allCanFire =",
        "    allBlockA1 & allBlockB2",
        "    | (|{releaseSourceD_0, releaseSourceD_1, releaseSourceD_2, releaseSourceD_3});",
        "",
        "  // sliceDArbWin[i]:slice i 本拍赢得 D 仲裁(可向 L1 发 D)= 自身可发射 或 全体可发射。",
        "  wire [3:0]   sliceDArbWin = sliceCanFire | {4{allCanFire}};",
        "  // sliceDReady[i]:slice i 的 D 通道 ready = 上游 TileLink d_ready & 赢得仲裁。",
        "  wire [3:0]   sliceDReady;",
        "  assign sliceDReady[0] = auto_in_0_d_ready & sliceDArbWin[0];",
        "  assign sliceDReady[1] = auto_in_1_d_ready & sliceDArbWin[1];",
        "  assign sliceDReady[2] = auto_in_2_d_ready & sliceDArbWin[2];",
        "  assign sliceDReady[3] = auto_in_3_d_ready & sliceDArbWin[3];",
        "",
        "  // releaseSourceD[i]:slice i 本拍可发射但其 D 无数据(让出 D 给 hint)。",
        "  assign releaseSourceD_0 = sliceCanFire[0] & ~_slices_0_io_in_d_valid;",
        "  assign releaseSourceD_1 = sliceCanFire[1] & ~_slices_1_io_in_d_valid;",
        "  assign releaseSourceD_2 = sliceCanFire[2] & ~_slices_2_io_in_d_valid;",
        "  assign releaseSourceD_3 = sliceCanFire[3] & ~_slices_3_io_in_d_valid;",
        "",
        "  // prefetchReqsReady[i]:prefetch 请求按地址 bank(set[1:0])路由到目标 slice 的 ready。",
        "  assign prefetchReqsReady_0 =",
        "    _slices_0_io_prefetch_req_ready & _prefetcher_io_req_bits_set[1:0] == 2'h0;",
        "  assign prefetchReqsReady_1 =",
        "    _slices_1_io_prefetch_req_ready & _prefetcher_io_req_bits_set[1:0] == 2'h1;",
        "  assign prefetchReqsReady_2 =",
        "    _slices_2_io_prefetch_req_ready & _prefetcher_io_req_bits_set[1:0] == 2'h2;",
        "  assign prefetchReqsReady_3 =",
        "    _slices_3_io_prefetch_req_ready & (&(_prefetcher_io_req_bits_set[1:0]));",
        "",
        "  // ---- (3) Grant 数据节拍计数 + L2->L1 hint 命中精度探针(dontTouch 统计)----",
        "  // grantDValidReady[i]:slice i 的 D 通道本拍成功握手(valid & ready)。",
        "  wire [3:0]   grantDValidReady;",
        "  assign grantDValidReady[0] = sliceDReady[0] & _slices_0_io_in_d_valid;",
        "  assign grantDValidReady[1] = sliceDReady[1] & _slices_1_io_in_d_valid;",
        "  assign grantDValidReady[2] = sliceDReady[2] & _slices_2_io_in_d_valid;",
        "  assign grantDValidReady[3] = sliceDReady[3] & _slices_3_io_in_d_valid;",
        "  // grantBeatRest[i]:多拍 GrantData 的「后续节拍」标志(首拍按 opcode[0] 置位,逐拍递减)。",
        "  reg  [3:0]   grantBeatRest;",
        "  // grantDataFire[i]:slice i 本拍发出 GrantData 首拍(opcode==4'h5 且非后续节拍)。",
        "  wire [3:0]   grantDataFire;",
        "  assign grantDataFire[0] =",
        "    grantDValidReady[0] & ~grantBeatRest[0] & _slices_0_io_in_d_bits_opcode == 4'h5;",
        "  assign grantDataFire[1] =",
        "    grantDValidReady[1] & ~grantBeatRest[1] & _slices_1_io_in_d_bits_opcode == 4'h5;",
        "  assign grantDataFire[2] =",
        "    grantDValidReady[2] & ~grantBeatRest[2] & _slices_2_io_in_d_bits_opcode == 4'h5;",
        "  assign grantDataFire[3] =",
        "    grantDValidReady[3] & ~grantBeatRest[3] & _slices_3_io_in_d_bits_opcode == 4'h5;",
        "  // 以下三者均为 dontTouch 统计/探针,不驱动任何功能输出:",
        "  //   grantDataFireCount:本拍发出 GrantData 的 slice 数(0..4);",
        "  wire [2:0]   grantDataFireCount =",
        "    3'(grantDataFire[0] + grantDataFire[1] + grantDataFire[2] + grantDataFire[3]);",
        "  wire         grantDataFireAny = |grantDataFire;",
        "  //   grantDataSource:本拍发射 grant 的 sourceId(优先 slice0>1>2>3),零扩展到 32 位;",
        "  wire [31:0]  grantDataSource =",
        "    {25'h0,",
        "     grantDValidReady[0] | grantDValidReady[1]",
        "       ? (grantDValidReady[0]",
        "            ? _slices_0_io_in_d_bits_source",
        "            : _slices_1_io_in_d_bits_source)",
        "       : grantDValidReady[2]",
        "           ? _slices_2_io_in_d_bits_source",
        "           : _slices_3_io_in_d_bits_source};",
        "  //   accurateHint/okHint:hint 预测(hintPipe2/1 的 sourceId)与实际 grant 是否一致。",
        "  wire         accurateHint_probe =",
        "    grantDataFireAny & _hintPipe2_io_out_valid & _hintPipe2_io_out_bits == grantDataSource;",
        "  wire         okHint_probe =",
        "    grantDataFireAny & _hintPipe1_io_out_valid & _hintPipe1_io_out_bits == grantDataSource;",
        "",
        "  // ---- (4) 性能计数 2 级打拍:48 路 = 4 slice × 12 事件,各打两拍(RegNext∘RegNext)。",
        "  //          事件 #2(每 slice 第 3 路)在本层恒 0(占位)。slicePerfRaw[N] 源映射",
        "  //          收割自 golden(io_perf_<N>_value_REG <= <src>),与 golden 逐拍等价。",
        "  wire [5:0]   slicePerfRaw [1:48];   // 各 slice 的 12 路 perf 原始值(事件 #2 = 0)",
    ]
    for n in range(1, 49):
        L.append(f"  assign slicePerfRaw[{n}] = {pm[n]};")
    L += [
        "  reg  [5:0]   perfStage1 [1:48];     // 第 1 拍",
        "  reg  [5:0]   perfStage2 [1:48];     // 第 2 拍(经 outassign 直送 io_perf_*_value)",
        "",
        "  // ---- (5) l2Miss 汇聚打拍:io.l2Miss := RegNext(OR(各 slice l2Miss))。",
        "  reg          l2MissReg;",
        "",
        "  // ---- (6) CHI rx 五通道按 bank 路由译码 + P-Credit grant 流水 ----------",
        "  // 按 txnID[10:9](rsp/dat)/ snp addr[4:3] 选 bank 0..2(bank3 在消费处用 & 取默认)。",
        "  wire         snpBankSel0 = _linkMonitor_io_in_rx_snp_bits_addr[4:3] == 2'h0;",
        "  wire         snpBankSel1 = _linkMonitor_io_in_rx_snp_bits_addr[4:3] == 2'h1;",
        "  wire         snpBankSel2 = _linkMonitor_io_in_rx_snp_bits_addr[4:3] == 2'h2;",
        "  wire         rspIsPCrdGrantOp = _linkMonitor_io_in_rx_rsp_bits_opcode == 5'h7;",
        "  wire         isPCrdGrant = _linkMonitor_io_in_rx_rsp_valid & rspIsPCrdGrantOp;",
        "  wire         rspBankSel0 = _linkMonitor_io_in_rx_rsp_bits_txnID[10:9] == 2'h0;",
        "  wire         rspBankSel1 = _linkMonitor_io_in_rx_rsp_bits_txnID[10:9] == 2'h1;",
        "  wire         rspBankSel2 = _linkMonitor_io_in_rx_rsp_bits_txnID[10:9] == 2'h2;",
        "  wire         datBankSel0 = _linkMonitor_io_in_rx_dat_bits_txnID[10:9] == 2'h0;",
        "  wire         datBankSel1 = _linkMonitor_io_in_rx_dat_bits_txnID[10:9] == 2'h1;",
        "  wire         datBankSel2 = _linkMonitor_io_in_rx_dat_bits_txnID[10:9] == 2'h2;",
        "  // P-Credit grant 流水:rxrsp 为 PCrdGrant 时,把 (type, srcID) 打一拍送入 pCrdQueue。",
        "  reg          pCrdGrantValid_s1;",
        "  reg  [3:0]   pCrdGrantType_s1;",
        "  reg  [10:0]  pCrdGrantSrcID_s1;",
        "  wire         pCrdQueueEnqFire = _pCrdQueue_io_enq_ready & pCrdGrantValid_s1; // dontTouch",
        "  reg  [63:0]  grantCnt;             // pCrdGrant 仲裁发射计数(dontTouch 统计)",
        "",
        "  // ================= 时序逻辑 =================",
        "  // (a) 同步块(无复位):hint/all 延迟链、perf 2 级打拍、l2Miss 汇聚、pCrdGrant 打拍。",
        "  integer pi;",
        "  always @(posedge clock) begin",
        "    // hint 发射阻塞延迟链(每 bit 一个 slice;allBlock 为标量,全体共用)。",
        "    hintBlockA0 <= {4{hintFire}} & hintChosen;",
        "    hintBlockA1 <= hintBlockA0;",
        "    hintBlockB0 <= {4{hintFire}} & hintChosen;",
        "    hintBlockB1 <= hintBlockB0;",
        "    hintBlockB2 <= hintBlockB1;",
        "    allBlockA0  <= ~hintFire;",
        "    allBlockA1  <= allBlockA0;",
        "    allBlockB0  <= ~hintFire;",
        "    allBlockB1  <= allBlockB0;",
        "    allBlockB2  <= allBlockB1;",
        "    // perf 2 级打拍(48 路)。",
        "    for (pi = 1; pi <= 48; pi = pi + 1) begin",
        "      perfStage1[pi] <= slicePerfRaw[pi];",
        "      perfStage2[pi] <= perfStage1[pi];",
        "    end",
        "    // l2Miss 汇聚打拍。",
        "    l2MissReg <=",
        "      _slices_0_io_l2Miss | _slices_1_io_l2Miss | _slices_2_io_l2Miss",
        "      | _slices_3_io_l2Miss;",
        "    // P-Credit grant 打拍。",
        "    pCrdGrantValid_s1 <= isPCrdGrant;",
        "    if (isPCrdGrant) begin",
        "      pCrdGrantType_s1  <= _linkMonitor_io_in_rx_rsp_bits_pCrdType;",
        "      pCrdGrantSrcID_s1 <= _linkMonitor_io_in_rx_rsp_bits_srcID;",
        "    end",
        "  end",
        "",
        "  // (b) 异步复位块:hint ready 沿、grant 节拍计数、pCrdGrant 仲裁计数。",
        "  always @(posedge clock or posedge reset) begin",
        "    if (reset) begin",
        "      hintArbOutReadyReg <= 1'h0;",
        "      grantBeatRest      <= 4'h0;",
        "      grantCnt           <= 64'h0;",
        "    end",
        "    else begin",
        "      hintArbOutReadyReg <= hintFire;",
        "      // 各 slice 的多拍 GrantData 节拍跟踪:首拍按 opcode[0] 置位,其后逐拍递减(到 0)。",
        "      if (grantDValidReady[0])",
        "        grantBeatRest[0] <=",
        "          grantBeatRest[0] ? 1'h0 : _slices_0_io_in_d_bits_opcode[0];",
        "      if (grantDValidReady[1])",
        "        grantBeatRest[1] <=",
        "          grantBeatRest[1] ? 1'h0 : _slices_1_io_in_d_bits_opcode[0];",
        "      if (grantDValidReady[2])",
        "        grantBeatRest[2] <=",
        "          grantBeatRest[2] ? 1'h0 : _slices_2_io_in_d_bits_opcode[0];",
        "      if (grantDValidReady[3])",
        "        grantBeatRest[3] <=",
        "          grantBeatRest[3] ? 1'h0 : _slices_3_io_in_d_bits_opcode[0];",
        "      if (_pcrdgrant_arb_io_out_valid)",
        "        grantCnt <= 64'(grantCnt + 64'h1);",
        "    end",
        "  end",
    ]
    leaks = 0
    for ln in L:
        if not ln.lstrip().startswith("//") and leftover_golden(ln):
            leaks += 1
    (XC / "coupledl2_glue.svh").write_text("\n".join(L) + "\n")
    return dict(leaks=leaks)


# ----------------------------------------------------------------------------
# gen_inst():29 子模块黑盒例化。整块文本做 RENAME 整词替换(跨入 glue 的临时名),
#   再原样发出——避免深层括号嵌套引脚的逐 pin 解析。
# ----------------------------------------------------------------------------
def gen_inst(blocks):
    L = [HDR,
         "// 29 子模块黑盒例化(23 种类型)+ 引脚连核内具名信号/互联网。",
         "// 引脚 rhs 中跨入 glue 的 firtool 临时名(d-ready / rx-bank-sel)已按 RENAME",
         "// 表换成 glue 内具名信号(sliceDReady[i]/sliceDArbWin[i]/{snp,rsp,dat}BankSel*",
         "// /rspIsPCrdGrantOp),其余为 io_*/_<inst>_io_*/常量/clock·reset 直连。", ""]
    leaks = 0
    for head, lines in blocks:
        block = apply_rename("\n".join(lines))
        for ln in block.splitlines():
            L.append(ln)
            if leftover_golden(ln):
                leaks += 1
    (XC / "coupledl2_inst.svh").write_text("\n".join(L) + "\n")
    return dict(insts=len(blocks), leaks=leaks)


# ----------------------------------------------------------------------------
# coupledl2_outassign.svh:顶层 io/auto 输出 + _probe 探针 assign。
#   收割 LHS 为 io_*/auto_*/_probe 的 assign(可跨行,直到分号),做 RENAME 替换。
#   glue 组合 assign(releaseSourceD_*/prefetchReqsReady_*/bd_*)不在此(已在 glue)。
# ----------------------------------------------------------------------------
def gen_outassign():
    assigns = re.findall(r"^  assign ((?:auto_|io_|_probe)\w*)\s*=\s*(.*?);",
                         GSV, re.M | re.S)
    L = [HDR,
         "// 顶层 io/auto 输出 assign + _probe 探针。多数为子模块输出网直连;",
         "// 带运算的:auto_in_i_b_bits_address 插入 bank 号({addr[45:6],2'hi,addr[5:0]})、",
         "// auto_in_i_d_valid = slice d_valid & sliceDArbWin[i]、io_perf_* = perfStage2[N]、",
         "// io_l2Miss = l2MissReg。RENAME 表已把 firtool 临时名换成 glue 具名信号。", ""]
    leaks = 0
    for lhs, rhs in assigns:
        rhs = apply_rename(re.sub(r"\s+", " ", rhs.strip()))
        line = f"  assign {lhs} = {rhs};"
        L.append(line)
        if leftover_golden(line):
            leaks += 1
    (XC / "coupledl2_outassign.svh").write_text("\n".join(L) + "\n")
    return dict(n=len(assigns), leaks=leaks)


# ----------------------------------------------------------------------------
# TL2CHICoupledL2_wrapper.sv:golden 同名扁平 wrapper(例化可读核)
# ----------------------------------------------------------------------------
def gen_wrapper(ports):
    pl = [p for p in ports if p[2] not in ("clock", "reset")]
    L = [HDR, "// golden 同名扁平 wrapper(FM/ST 用):例化可读核 xs_TL2CHICoupledL2_core。",
         "module TL2CHICoupledL2(", "  input  clock,", "  input  reset,"]
    for i, (d, w, n) in enumerate(pl):
        comma = "," if i < len(pl) - 1 else ""
        ww = "" if w == 1 else f"[{w - 1}:0] "
        L.append(f"  {d}  {ww}{n}{comma}")
    L.append(");")
    L.append("  xs_TL2CHICoupledL2_core u_core (")
    L.append("    .clock(clock),")
    L.append("    .reset(reset),")
    for i, (d, w, n) in enumerate(pl):
        comma = "," if i < len(pl) - 1 else ""
        L.append(f"    .{n}({n}){comma}")
    L.append("  );")
    L.append("endmodule")
    (XC / "TL2CHICoupledL2_wrapper.sv").write_text("\n".join(L) + "\n")


# ----------------------------------------------------------------------------
# blackbox stubs(空体,所有 output 驱 0)—— 仅备快速 elaborate,UT/FM 用 golden 真定义
# ----------------------------------------------------------------------------
def gen_stubs(types):
    L = [HDR, "// 23 子模块类型黑盒 stub(空体,所有 output 驱 0)。",
         "// 注:UT/FM 默认用 golden 子模块真定义(-f 闭包);本 stub 仅备快速 elaborate。", ""]
    for t in sorted(types):
        gf = GOLDEN / f"{t}.sv"
        if not gf.exists():
            L.append(f"// !! golden {t}.sv 缺失,跳过 stub")
            continue
        g = gf.read_text()
        m = re.search(rf"^module {re.escape(t)}\((.*?)\n\);", g, re.S | re.M)
        if not m:
            L.append(f"// !! 无法解析 {t} 端口,跳过")
            continue
        ports = []
        for line in m.group(1).splitlines():
            pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
            if pm:
                ports.append((pm.group(1),
                              int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
        L.append(f"module {t}(")
        for i, (d, w, n) in enumerate(ports):
            comma = "," if i < len(ports) - 1 else ""
            ww = "" if w == 1 else f"[{w - 1}:0] "
            L.append(f"  {d}  {ww}{n}{comma}")
        L.append(");")
        for d, w, n in ports:
            if d == "output":
                L.append(f"  assign {n} = '0;")
        L.append("endmodule\n")
    (XC / "coupledl2_blackbox_stubs.sv").write_text("\n".join(L) + "\n")


# ----------------------------------------------------------------------------
# golden 叶子传递闭包(同 gen_l2top.py:-f 每文件一次,规避 -y 自包含 pkg 冲突)
# ----------------------------------------------------------------------------
_MODDEF = re.compile(r"^module\s+([A-Za-z_]\w*)\b", re.M)
_INSTREF = re.compile(r"^\s{2,}([A-Za-z_]\w*)\s+[\\A-Za-z_]\S*\s*\(", re.M)
_KW = {"if", "for", "case", "begin", "end", "assign", "wire", "reg", "logic",
       "always", "module", "endmodule", "input", "output", "inout", "parameter",
       "localparam", "generate", "endgenerate", "initial", "final", "function",
       "task", "package", "import", "typedef", "struct", "enum", "union",
       "genvar", "integer", "real", "supply0", "supply1", "tri", "wand", "wor",
       "posedge", "negedge", "else", "while", "repeat", "forever", "do",
       "return", "break", "continue", "fork", "join", "wait", "disable", "force",
       "release", "assert", "assume", "cover", "property", "sequence"}


def _golden_modfile_map():
    modfile = {}
    for f in sorted(GOLDEN.glob("*.sv")) + sorted(GOLDEN.glob("*.v")):
        try:
            txt = f.read_text(errors="ignore")
        except OSError:
            continue
        for m in _MODDEF.finditer(txt):
            modfile.setdefault(m.group(1), f)
    return modfile


def golden_closure(tops):
    modfile = _golden_modfile_map()
    seen, files, missing, stack = set(), set(), set(), list(tops)
    while stack:
        mod = stack.pop()
        if mod in seen:
            continue
        seen.add(mod)
        f = modfile.get(mod)
        if not f:
            missing.add(mod)
            continue
        files.add(f)
        for m in _INSTREF.finditer(f.read_text(errors="ignore")):
            t = m.group(1)
            if t not in _KW and t not in seen and t in modfile:
                stack.append(t)
    return sorted(files), sorted(missing), len(seen - missing)


def gen_filelist(tops):
    rel = "../../../golden/chisel-rtl"
    files, missing, nmod = golden_closure(tops)
    L = ["// 自动生成:scripts/gen_coupledl2.py —— golden 叶子传递闭包文件列表(每文件一次)",
         f"// 顶: {' '.join(tops)};模块数={nmod};文件数={len(files)}",
         "// 用 -f 显式编译,规避 -y 对自包含 pkg+module 文件的重复声明冲突。"]
    for f in files:
        L.append(f"{rel}/{f.name}")
    (UT / "golden_filelist.f").write_text("\n".join(L) + "\n")
    return dict(nmod=nmod, nfiles=len(files), missing=missing)


# ----------------------------------------------------------------------------
# UT:tb.sv / variants_xs.sv / Makefile
# ----------------------------------------------------------------------------
def wdecl(w):
    return "" if w == 1 else f"[{w - 1}:0] "


def gen_ut(ports, types):
    UT.mkdir(parents=True, exist_ok=True)
    pl = [p for p in ports if p[2] not in ("clock", "reset")]
    ins = [p for p in pl if p[0] == "input"]
    outs = [p for p in pl if p[0] == "output"]

    L = [HDR, "module TL2CHICoupledL2_xs(", "  input  clock,", "  input  reset,"]
    for i, (d, w, n) in enumerate(pl):
        comma = "," if i < len(pl) - 1 else ""
        L.append(f"  {d}  {wdecl(w)}{n}{comma}")
    L.append(");")
    L.append("  xs_TL2CHICoupledL2_core u_core (")
    L.append("    .clock(clock),")
    L.append("    .reset(reset),")
    for i, (d, w, n) in enumerate(pl):
        comma = "," if i < len(pl) - 1 else ""
        L.append(f"    .{n}({n}){comma}")
    L.append("  );")
    L.append("endmodule")
    (UT / "variants_xs.sv").write_text("\n".join(L) + "\n")

    T = [HDR, "`timescale 1ns/1ps", "module tb;",
         "  int unsigned NCYCLES = 200000;",
         "  bit clk = 0, rst;",
         "  int errors = 0, checks = 0;",
         "  always #5 clk = ~clk;", ""]
    for d, w, n in ins:
        T.append(f"  logic {wdecl(w)}{n};")
    for d, w, n in outs:
        T.append(f"  wire {wdecl(w)}g_{n};")
        T.append(f"  wire {wdecl(w)}i_{n};")
    T.append("")

    def conn(prefix_out):
        items = [".clock(clk)", ".reset(rst)"]
        for d, w, n in pl:
            items.append(f".{n}({n})" if d == "input" else f".{n}({prefix_out}{n})")
        return ", ".join(items)

    T.append(f"  TL2CHICoupledL2    u_g ({conn('g_')});")
    T.append(f"  TL2CHICoupledL2_xs u_i ({conn('i_')});")
    T.append("")
    T.append(f"  bit reported [0:{len(outs) - 1}];")
    T.append("  int distinct_div = 0;")
    T.append("")
    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    for d, w, n in ins:
        if n.endswith(("_valid", "_ready", "flitv", "lcrdv", "flitpend")):
            T.append(f"      {n} <= 1'b0;")
    T.append("    end else begin")
    for d, w, n in ins:
        if w == 1:
            T.append(f"      {n} <= $urandom_range(0,1);")
        elif w <= 32:
            T.append(f"      {n} <= {w}'($urandom);")
        elif w <= 64:
            T.append(f"      {n} <= {{$urandom(), $urandom()}};")
        else:
            chunks = (w + 31) // 32
            cat = ", ".join(["$urandom()"] * chunks)
            T.append(f"      {n} <= {{{cat}}};")
    T.append("    end")
    T.append("  end")
    T.append("")
    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    #4; checks++;")
    for k, (d, w, n) in enumerate(outs):
        T.append(f"    if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
        T.append(f"      if(!reported[{k}]) begin reported[{k}]=1; distinct_div++;")
        T.append(f"        $display(\"[DIV %0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end end")
    T.append("  end")
    T.append("")
    T.append("  initial begin")
    T.append("    if (!$value$plusargs(\"NCYCLES=%d\", NCYCLES)) NCYCLES = 200000;")
    T.append("    rst = 1; repeat (16) @(posedge clk); rst = 0;")
    T.append("    repeat (NCYCLES) @(posedge clk);")
    T.append(f"    $display(\"distinct_diverging_ports=%0d / %0d\", distinct_div, {len(outs)});")
    T.append("    $display(\"checks=%0d errors=%0d\", checks, errors);")
    T.append("    if (errors == 0 && checks > 1000) $display(\"TEST PASSED\"); "
             "else $display(\"TEST FAILED\");")
    T.append("    $finish;")
    T.append("  end")
    T.append("endmodule")
    (UT / "tb.sv").write_text("\n".join(T) + "\n")

    sub_deps = " ".join(f"$(GOLDEN_RTL)/{t}.sv" for t in sorted(types))
    fm_ref = " ".join(f"{t}.sv" for t in sorted(types))
    txt = f"""# 自动生成:scripts/gen_coupledl2.py —— 勿手改
MODULE = TL2CHICoupledL2

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(核通过 `include 引入端口/decls/glue/inst/outassign svh)。
RTL_SRCS = $(RTL_DIR)/l2/coupledl2_pkg.sv \\
           $(RTL_DIR)/l2/TL2CHICoupledL2.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 双例化:顶 TL2CHICoupledL2.sv + 23 子模块类型的全部叶子(传递闭包)。
GOLDEN_SRCS = $(GOLDEN_RTL)/TL2CHICoupledL2.sv

SUB_DEPS = {sub_deps}

WRAPPER_SRCS = $(RTL_DIR)/l2/TL2CHICoupledL2_wrapper.sv $(SUB_DEPS)
FM_VARIANTS = TL2CHICoupledL2
FM_REF_DEPS_TL2CHICoupledL2 = {fm_ref}

include ../../../scripts/ut_common.mk

# golden 内含非综合断言/difftest;UT 关掉并关随机化,处理 flush-X。
VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/l2
VCS += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
# golden 叶子全集(传递闭包),-f 显式列出,每文件一次。
VCS += -f golden_filelist.f
VCS += +libext+.sv+.v
VCS += -assert disable
"""
    (UT / "Makefile").write_text(txt)
    return len(ins), len(outs)


def main():
    XC.mkdir(parents=True, exist_ok=True)
    UT.mkdir(parents=True, exist_ok=True)
    ps = top_ports()
    gen_ports(ps)
    types = submodule_types()
    print(f"ports: {len(ps)}  submodule types: {len(types)}  instances: "
          f"{sum(len(v) for v in types.values())}")
    d = gen_decls()
    print(f"[decls] {d['nets']} interconnect/glue nets")
    g = gen_glue()
    print(f"[glue] hand-rewritten readable glue, golden-temp leaks={g['leaks']}")
    blocks = extract_instances()
    r = gen_inst(blocks)
    print(f"[inst] {r['insts']} instances, golden-temp leaks={r['leaks']}")
    oa = gen_outassign()
    print(f"[outassign] {oa['n']} io/auto/probe assigns, golden-temp leaks={oa['leaks']}")
    gen_wrapper(ps)
    gen_stubs(types)
    fl = gen_filelist(["TL2CHICoupledL2"])
    print(f"[filelist] golden closure: {fl['nmod']} modules, {fl['nfiles']} files"
          + (f", MISSING={fl['missing'][:10]}" if fl['missing'] else ", missing=0"))
    ni, no = gen_ut(ps, types)
    print(f"[ut] {ni} inputs driven, {no} outputs compared")


if __name__ == "__main__":
    main()
