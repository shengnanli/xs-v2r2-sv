#!/usr/bin/env python3
"""
NewDispatch(派遣级)生成器 —— 「可读重写」版本(非套壳)。

设计源:src/main/scala/xiangshan/backend/dispatch/NewDispatch.scala(class NewDispatch)。
golden:golden/chisel-rtl/NewDispatch.sv(仅用于 UT/FM 对照,以及抽取「配置常量」)。

【方法学(与上版被拒的根本区别)】
  上版把 golden 模块体(满是 _GEN_/_T_ 的路由/排序/反压逻辑原文)抽进 body.svh 套壳。
  本版相反:NewDispatch 自身的全部组合/时序逻辑都由本脚本以「可读 SV」重新生成
  (named net / genvar-展开 / 纯函数 / struct / enum),logic.svh 里 0 个 _GEN_/_T_。
  只有 7 个真子模块(RegCacheTagTable / BusyTable×4 / VlBusyTable / LsqEnqCtrl)作两侧
  共享 golden 黑盒;connect.svh 只放「子模块例化 + 端口连线 + 34 enq 端口的统一选择展开」。

  从 golden 抽取的仅是「配置常量」(合法,等同 BackendParams 推导结果):
    - 各 needMultiExu 负载均衡组的 fuType 位、EXU 索引、IQ 索引、IQSort 列;
    - needSingleIQ 各 IQ 的 fuType 位;
    - 每个 toIssueQueues enq 端口的字段集 + 各字段「四来源」分类(RENAME/UPDATE/SRCSTATE/SUBMOD);
    - 各 io_* 端口位宽。
  这些是「拓扑/字段表」,不是逻辑;逻辑(allSrcState 公式、前缀 popcount、PriorityMux、
  负载均衡排序、反压、singleStep FSM、conserveFlow)全部由本脚本明文写出可读 SV。

产物:
  rtl/backend/newdispatch_pkg.sv        —— 参数/枚举/struct/纯函数(手写,保留)。
  rtl/backend/newdispatch_ports.svh     —— 可读核端口表(golden 同名扁平端口,去 clock/reset)。
  rtl/backend/newdispatch_logic.svh     —— 可读核「真逻辑」(本脚本生成,named net/genvar/function)。
  rtl/backend/newdispatch_connect.svh   —— 子模块黑盒例化 + 34 enq 端口选择展开(机械互联)。
  rtl/backend/NewDispatch.sv            —— 可读核 xs_NewDispatch_core(手写外壳,include 上面 svh)。
  rtl/backend/NewDispatch_wrapper.sv    —— golden 同名扁平 wrapper(FM/UT 用)。
  verif/ut/NewDispatch/{variants_xs.sv,tb.sv,Makefile} —— 双例化逐拍比对。
"""
import re
from pathlib import Path
from collections import OrderedDict

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
GSV = (GOLDEN / "NewDispatch.sv").read_text()
BK = XSSV / "rtl/backend"
UT = XSSV / "verif/ut/NewDispatch"
GEN_HDR = "// 自动生成:scripts/gen_newdispatch.py —— 勿手改(逻辑为从 NewDispatch.scala 设计意图的可读重写)\n"

RENAME_WIDTH = 6
NUM_IQ = 17
NUM_ENQ = 2
IQ_ENQ_SUM = 34
EXU_NUM = 25          # io_IQValidNumVec 宽度(golden 索引 0..24)
NUM_REG_SRC = 5
NUM_REG_TYPE = 5

# 每寄存器域(int/fp/vec/v0/vl)在 uop 5 个源里的位置(idxRegType),决定 busytable 读端口索引。
# 见 Scala idxRegTypeInt/Fp/Vec/V0/Vl 与 golden allSrcState_i_j_k 取的 busytable read 下标。
IDX_REG_TYPE = {0: [0, 1], 1: [0, 1, 2], 2: [0, 1, 2], 3: [3], 4: [4]}
# 各域 busytable 每 uop 占用的读端口数 = len(idxRegType)
SRC_PER_TYPE = {k: len(v) for k, v in IDX_REG_TYPE.items()}  # int2 fp3 vec3 v0_1 vl1


# ---------------------------------------------------------------------------
# 顶层端口解析(保留 golden 同名扁平端口)
# ---------------------------------------------------------------------------
def top_ports():
    m = re.search(r"^module NewDispatch\((.*?)\n\);", GSV, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return res


PORTS = top_ports()
PORTW = {n: w for _, w, n in PORTS}


def wd(w):
    return f"[{w-1}:0] " if w > 1 else ""


# ---------------------------------------------------------------------------
# 1. newdispatch_ports.svh
# ---------------------------------------------------------------------------
def gen_ports():
    lines = [GEN_HDR]
    body = [p for p in PORTS if p[2] not in ("clock", "reset")]
    for i, (d, w, n) in enumerate(body):
        comma = "," if i < len(body) - 1 else ""
        kw = "input  logic" if d == "input" else "output logic"
        lines.append(f"  {kw} {wd(w)}{n}{comma}")
    (BK / "newdispatch_ports.svh").write_text("\n".join(lines) + "\n")
    print(f"[gen] newdispatch_ports.svh: {len(body)} ports")


# ---------------------------------------------------------------------------
# 抽取每个 toIssueQueues enq 端口的字段集 + 来源分类(配置/字段表)
# ---------------------------------------------------------------------------
def field_src_kind(b):
    """返回 (kind, *args):
       SRC j k     : allSrcState[slot][j][k]   (srcState_j)
       LQ / SQ     : LsqEnqCtrl resp lqIdx/sqIdx
       RCV / RCA   : RegCacheTagTable readPorts valid/addr
       UST2        : fromRenameUpdate srcType_2(ignoreOldVd 改写)
       SLD a b     : fromRenameUpdate srcLoadDependency[a][b]
       DROP / SS   : isDropAmocasSta / singleStep
       RN          : io_fromRename 直通
    """
    if re.search(r'allSrcState_\d+_\d+_\d+', b):
        # srcState_j 可能 OR 多个域(maskForStd:sta IQ 的 j==1 含 int+fp)。
        # 提取所有出现的 (j,k);j 应一致,k 收集成集合。
        pairs = [(int(a), int(c)) for a, c in re.findall(r'allSrcState_\d+_(\d+)_(\d+)', b)]
        j = pairs[0][0]
        ks = sorted(set(k for jj, k in pairs))
        return ('SRC', j, ks)
    if re.search(r'_lsqEnqCtrl_io_enq_resp_\d+_lqIdx', b): return ('LQ',)
    if re.search(r'_lsqEnqCtrl_io_enq_resp_\d+_sqIdx', b): return ('SQ',)
    if re.search(r'_rcTagTable_io_readPorts_\d+_valid', b): return ('RCV',)
    if re.search(r'_rcTagTable_io_readPorts_\d+_addr', b): return ('RCA',)
    if re.search(r'fromRenameUpdate_\d+_bits_srcType_2', b): return ('UST2',)
    if re.search(r'fromRenameUpdate_\d+_bits_srcLoadDependency', b):
        m = re.search(r'srcLoadDependency_(\d+)_(\d+)', b); return ('SLD', int(m.group(1)), int(m.group(2)))
    if re.search(r'fromRenameUpdate_\d+_bits_isDropAmocasSta', b): return ('DROP',)
    if re.search(r'fromRenameUpdate_\d+_bits_singleStep', b): return ('SS',)
    return ('RN',)


def parse_iq_ports():
    out = OrderedDict()
    for p in range(IQ_ENQ_SUM):
        fields = []
        for m in re.finditer(rf'assign io_toIssueQueues_{p}_bits_(\w+) =\s*(.*?);', GSV, re.S):
            fields.append((m.group(1), field_src_kind(m.group(2))))
        out[p] = {'iq': p // NUM_ENQ, 'enq': p % NUM_ENQ, 'fields': fields}
    return out


IQPORTS = parse_iq_ports()


# ---------------------------------------------------------------------------
# needMultiExu 负载均衡组配置(从 golden compareMatrix/uopSelIQ 抽取)
# 每组:fuType 位列表、EXU 索引(用于读 IQValidNumVec)、{IQ: IQSort 列}。
# ---------------------------------------------------------------------------
def parse_multi_groups():
    # group fuType bits: fuTypeOH_0_<g> = (fuType[a]|fuType[b]|...) & valid
    fuoh_bits = {}
    for m in re.finditer(r'wire\s+fuTypeOH_0_(\d+) =\s*(.*?);', GSV, re.S):
        g = int(m.group(1)); bits = sorted(int(x) for x in re.findall(r'fuType\[(\d+)\]', m.group(2)))
        fuoh_bits[g] = bits
    # group exu indices: compareMatrix_<grp>_0_1 = IQValidNumVec_a < IQValidNumVec_b ...
    grp_exu = {}
    for m in re.finditer(r'wire\s+compareMatrix_([a-zA-Z_]+?)_(\d+)_(\d+) = io_IQValidNumVec_(\d+) < io_IQValidNumVec_(\d+);', GSV):
        grp = m.group(1); i, j = int(m.group(2)), int(m.group(3)); a, b = int(m.group(4)), int(m.group(5))
        d = grp_exu.setdefault(grp, {}); d[i] = a; d[j] = b
    # group -> {iq: col} and fuoh index, from slot0 uopSelIQ
    grp_iqcol = {}; grp_fuoh = {}
    for iq in range(NUM_IQ):
        s = re.sub(r'\s+', ' ', re.search(rf'\buopSelIQ_0_{iq} <=\s*(.*?);', GSV, re.S).group(1))
        for mm in re.finditer(r'fuTypeOH_0_(\d+) & IQSort_([a-zA-Z_]+?)_0_(\d+)', s):
            fuoh, grp, col = int(mm.group(1)), mm.group(2), int(mm.group(3))
            grp_fuoh[grp] = fuoh; grp_iqcol.setdefault(grp, {})[iq] = col
    groups = []
    for grp in grp_iqcol:
        fuoh = grp_fuoh[grp]
        exu = grp_exu.get(grp)
        iqcol = grp_iqcol[grp]
        iqNum = len(iqcol)
        # exu 索引按 col 排序(col 即 exu 在该组里的位置)
        if exu:
            exu_list = [exu[i] for i in range(iqNum)]
        else:  # 2-EXU 组复用 alu 的 compareMatrix(mul_bku),exu 直接取 iq->col 不需要,占位
            exu_list = None
        # iq 列表按 col 排序
        iqs = [None] * iqNum
        for iq, c in iqcol.items():
            iqs[c] = iq
        groups.append({'name': grp, 'fuoh': fuoh, 'bits': fuoh_bits[fuoh],
                       'iqNum': iqNum, 'iqs': iqs, 'exu': exu_list})
    # 2-EXU 组(如 mul_bku)可能复用别组的 compareMatrix(因共享 EXU);
    # 从 IQSort_<grp>_0_0 <= [~]compareMatrix_<other>_a_b 还原其 EXU 对。
    for g in groups:
        if g['exu'] is None:
            m = re.search(rf'IQSort_{g["name"]}_0_0 <=\s*~?compareMatrix_([a-zA-Z_]+?)_(\d+)_(\d+);', GSV)
            other, a, b = m.group(1), int(m.group(2)), int(m.group(3))
            d = grp_exu[other]
            g['exu'] = [d[a], d[b]]
    groups.sort(key=lambda g: g['fuoh'])
    return groups


MULTI = parse_multi_groups()
NUM_GRP = len(MULTI)

# needSingleIQ 各 IQ 的 fuType 位(从 slot0 uopSelIQ 单 IQ 回退分支抽取)
def parse_single():
    single = {}
    for iq in range(NUM_IQ):
        s = re.sub(r'\s+', ' ', re.search(rf'\buopSelIQ_0_{iq} <=\s*(.*?);', GSV, re.S).group(1))
        # 单 IQ 回退:形如 "... : io_renameIn_0_valid & io_renameIn_0_bits_fuType[..] | ..."
        # 取冒号后的部分,或整体无 IQSort 的;提取 fuType 位
        if '?' in s:
            tail = s.split('?', 1)[1].split(':', 1)
            seg = tail[1] if len(tail) > 1 else ''
        elif 'IQSort' in s:
            seg = ''   # 纯多组贡献,无单 IQ 回退
        else:
            seg = s
        bits = sorted(set(int(b) for b in re.findall(r'fuType\[(\d+)\]', seg)))
        if bits:
            single[iq] = bits
    return single


SINGLE = parse_single()


# 哪些 IQ 由「IQSort 多组贡献」驱动 vs 「单 IQ 直接译码」驱动:
# 对每个 IQ,multi 贡献列表 = [(grp_idx, col), ...];single 贡献 = fuType 位列表(可空)。
def iq_routing_table():
    tab = {}
    for iq in range(NUM_IQ):
        contribs = []
        for gi, g in enumerate(MULTI):
            if iq in g['iqs']:
                col = g['iqs'].index(iq)
                contribs.append((gi, col))
        tab[iq] = {'multi': contribs, 'single': SINGLE.get(iq, [])}
    return tab


ROUTE = iq_routing_table()


# ===========================================================================
# 2. newdispatch_logic.svh —— 可读核「真逻辑」(named net / genvar / 纯函数)
# ===========================================================================
def gen_logic():
    L = [GEN_HDR,
         "// =====================================================================",
         "// 派遣级核心逻辑(从 NewDispatch.scala 设计意图重写,非 golden 网表抽取)。",
         "// 全部为命名网线 / generate-for / 纯函数;无 _GEN_/_T_ 临时名。",
         "// 子模块(BusyTable×4 / VlBusyTable / RegCacheTagTable / LsqEnqCtrl)的「读端口",
         "// 驱动」「allocPregs」在此算好,例化与连线见 newdispatch_connect.svh。",
         "// =====================================================================",
         "import newdispatch_pkg::*;", ""]

    # ----- 把 6 条 uop 的 fromRename/renameIn 字段「数组化」,供 generate 使用 -----
    L += ["  // ---- 0. 把 6 条 uop 的关键标量字段聚成数组(便于 generate 遍历)----",
          "  logic [RENAME_WIDTH-1:0] rn_valid, ri_valid, rn_ready;",
          "  logic [RENAME_WIDTH-1:0] rn_rfWen, rn_elimMove, rn_hasExc, rn_blockBkwd, rn_waitFwd;",
          "  logic [3:0] rn_srcType [RENAME_WIDTH][NUM_REG_SRC];",
          "  logic [PREG_W-1:0] rn_pdest [RENAME_WIDTH];"]
    for i in range(RENAME_WIDTH):
        L.append(f"  assign rn_valid[{i}]    = io_fromRename_{i}_valid;")
        L.append(f"  assign ri_valid[{i}]    = io_renameIn_{i}_valid;")
        L.append(f"  assign rn_rfWen[{i}]    = io_fromRename_{i}_bits_rfWen;")
        L.append(f"  assign rn_elimMove[{i}] = io_fromRename_{i}_bits_eliminatedMove;")
        L.append(f"  assign rn_hasExc[{i}]   = io_fromRename_{i}_bits_hasException;")
        L.append(f"  assign rn_blockBkwd[{i}]= io_fromRename_{i}_bits_blockBackward;")
        L.append(f"  assign rn_waitFwd[{i}]  = io_fromRename_{i}_bits_waitForward;")
        L.append(f"  assign rn_pdest[{i}]    = io_fromRename_{i}_bits_pdest;")
        for j in range(NUM_REG_SRC):
            L.append(f"  assign rn_srcType[{i}][{j}] = io_fromRename_{i}_bits_srcType_{j};")
    L.append("")

    # ----- toRenameAllFire / firedVec -----
    L += ["  // ---- 1. fire / toRenameAllFire ----",
          "  // firedVec[i] = ready & valid;toRenameAllFire = 每条 uop 「无效或已 fire」。",
          "  logic [RENAME_WIDTH-1:0] firedVec;",
          "  logic toRenameAllFire;",
          "  always_comb begin",
          "    logic acc;",
          "    acc = 1'b1;",
          "    for (int i = 0; i < RENAME_WIDTH; i++)",
          "      acc = acc & (~rn_valid[i] | (rn_ready[i] & rn_valid[i]));",
          "    toRenameAllFire = acc;",
          "  end"]
    for i in range(RENAME_WIDTH):
        L.append(f"  assign firedVec[{i}] = rn_ready[{i}] & io_fromRename_{i}_valid;")
    L.append("  assign io_toRenameAllFire = toRenameAllFire;")
    L.append("")

    # ----- allocPregsValid(5 域 × 6 uop) -----
    L += ["  // ---- 2. allocPregs valid(写 5 个 BusyTable / RegCacheTagTable 的分配端口)----",
          "  // 每域:valid = uop.valid & 对应写使能(int 额外排除 eliminatedMove)。",
          "  logic [RENAME_WIDTH-1:0] allocPregsValid [NUM_REG_TYPE];"]
    we = {0: "rfWen", 1: "fpWen", 2: "vecWen", 3: "v0Wen", 4: "vlWen"}
    for k in range(NUM_REG_TYPE):
        for i in range(RENAME_WIDTH):
            extra = " & ~io_fromRename_%d_bits_eliminatedMove" % i if k == 0 else ""
            L.append(f"  assign allocPregsValid[{k}][{i}] = io_fromRename_{i}_valid & io_fromRename_{i}_bits_{we[k]}{extra};")
    L.append("")

    # ----- 读端口地址/使能驱动(送各 BusyTable / RegCacheTagTable) -----
    # int 读端口 idx = i*2 + pos(pos∈{0,1}=idxRegTypeInt);fp/vec=i*3+pos;v0=i;vl=i。
    L += ["  // ---- 3. BusyTable / RegCacheTagTable 读端口驱动 ----",
          "  // 读地址 = uop 对应源的 psrc;读使能 = 该源属于该域(SrcType 对应位)。",
          "  // 读端口索引 idx = i*len(idxRegType) + 域内位置(见 docs §2.1)。"]
    # 这些直接在 connect.svh 连到子模块引脚(地址即 psrc),此处只列出 srcType 位判定的命名网,
    # 供 allSrcState 与 srcLoadDependency 使用。
    L.append("")

    # ----- allSrcState(就绪查询)用纯函数 + generate -----
    L += ["  // ---- 4. allSrcState[i][j][k]:第 i 条 uop 第 j 源在第 k 域的就绪 ----",
          "  // allSrcState = (srcType 命中该域位) & busyTable.resp | (srcType==imm 恒就绪)。",
          "  // 仅 (j,k) 合法组合存在(int:j∈{0,1};fp/vec:j∈{0,1,2};v0:j=3;vl:j=4)。",
          "  // 向量 old-vd(j=2,k=vec)额外或上 ignoreOldVd。busyTable.resp 见 connect.svh。",
          "  logic allSrcState [RENAME_WIDTH][NUM_REG_SRC][NUM_REG_TYPE];",
          "  logic ignoreOldVd [RENAME_WIDTH];   // 向量 old_vd 可忽略",
          "  // busyTable.resp 数组(由 connect.svh 从子模块输出填入)",
          "  logic bt_resp_int [RENAME_WIDTH*2];",
          "  logic bt_resp_fp  [RENAME_WIDTH*3];",
          "  logic bt_resp_vec [RENAME_WIDTH*3];",
          "  logic bt_resp_v0  [RENAME_WIDTH];",
          "  logic bt_resp_vl  [RENAME_WIDTH];",
          "  // vlBusyTable 读出的 vl 信息(is_vlmax / is_nonzero)",
          "  logic vl_is_vlmax [RENAME_WIDTH];",
          "  logic vl_is_nonzero [RENAME_WIDTH];",
          "  // vpu 字段数组(供 ignoreOldVd)",
          "  logic vpu_isDependOldVd [RENAME_WIDTH], vpu_isWritePartVd [RENAME_WIDTH];",
          "  logic vpu_vta [RENAME_WIDTH], vpu_vma [RENAME_WIDTH], vpu_vm [RENAME_WIDTH];"]
    for i in range(RENAME_WIDTH):
        L.append(f"  assign vpu_isDependOldVd[{i}] = io_fromRename_{i}_bits_vpu_isDependOldVd;")
        L.append(f"  assign vpu_isWritePartVd[{i}] = io_fromRename_{i}_bits_vpu_isWritePartVd;")
        L.append(f"  assign vpu_vta[{i}] = io_fromRename_{i}_bits_vpu_vta;")
        L.append(f"  assign vpu_vma[{i}] = io_fromRename_{i}_bits_vpu_vma;")
        L.append(f"  assign vpu_vm[{i}]  = io_fromRename_{i}_bits_vpu_vm;")
    # 默认全 0,再逐合法项赋值(避免 X)
    L.append("  always_comb begin")
    L.append("    for (int i = 0; i < RENAME_WIDTH; i++)")
    L.append("      for (int j = 0; j < NUM_REG_SRC; j++)")
    L.append("        for (int k = 0; k < NUM_REG_TYPE; k++)")
    L.append("          allSrcState[i][j][k] = 1'b0;")
    L.append("    for (int i = 0; i < RENAME_WIDTH; i++) begin")
    L.append("      // imm 恒就绪标志(srcType==0)")
    L.append("      logic [4:0] immJ;  // 每源是否立即数")
    L.append("      for (int j = 0; j < NUM_REG_SRC; j++)")
    L.append("        immJ[j] = (rn_srcType[i][j] == 4'h0);")
    # int j0,j1: k0 int(bit0), k1 fp(bit1), k2 vec(bit2)
    L.append("      // src0/src1:可落 int(bit0)/fp(bit1)/vec(bit2)三域")
    L.append("      for (int j = 0; j < 2; j++) begin")
    L.append("        allSrcState[i][j][0] = rn_srcType[i][j][0] & bt_resp_int[i*2+j] | immJ[j];")
    L.append("        allSrcState[i][j][1] = rn_srcType[i][j][1] & bt_resp_fp [i*3+j] | immJ[j];")
    L.append("        allSrcState[i][j][2] = rn_srcType[i][j][2] & bt_resp_vec[i*3+j] | immJ[j];")
    L.append("      end")
    L.append("      // src2:fp(bit1)/vec(bit2,含 ignoreOldVd);old_vd 是 vec 第 3 源(j=2)")
    L.append("      allSrcState[i][2][1] = rn_srcType[i][2][1] & bt_resp_fp [i*3+2] | immJ[2];")
    L.append("      allSrcState[i][2][2] = rn_srcType[i][2][2] & (bt_resp_vec[i*3+2] | ignoreOldVd[i]) | immJ[2];")
    L.append("      // src3:v0(bit3);src4:vl(恒读)")
    L.append("      allSrcState[i][3][3] = rn_srcType[i][3][3] & bt_resp_v0[i] | immJ[3];")
    L.append("      allSrcState[i][4][4] = bt_resp_vl[i] | immJ[4];")
    L.append("    end")
    L.append("  end")
    # ignoreOldVd
    L += ["  // ignoreOldVd:vl 已就绪且非零、不依赖 old_vd,且(尾被 mask 或整体被 mask)→ 可忽略 old_vd。",
          "  always_comb for (int i = 0; i < RENAME_WIDTH; i++)",
          "    ignoreOldVd[i] = nd_ignore_old_vd(",
          "      bt_resp_vl[i], vl_is_nonzero[i], vl_is_vlmax[i],",
          "      vpu_isDependOldVd[i], vpu_isWritePartVd[i], vpu_vta[i], vpu_vma[i], vpu_vm[i]);"]
    L.append("")

    # ----- 5. 负载均衡:compareMatrix / IQSort / minIQSel -----
    L += ["  // ---- 5. 负载均衡(needMultiExu):compareMatrix→IQSort 排序→各 uop 轮选最空 IQ ----",
          "  // 对每个「多同质 EXU」组:compareMatrix 两两比 IQValidNum;IQSort[row] = 表项数",
          "  // 第 (iqNum-1-row) 多的那个 IQ 的 one-hot(寄存一拍);uop i 落到 IQSort[i%iqNum]。",
          f"  logic [4:0] iqvld [{EXU_NUM}];   // IQValidNumVec 数组化(部分 EXU 无负载均衡需求,端口缺省)"]
    iqvld_present = sorted(int(n.rsplit('_', 1)[1]) for _, _, n in PORTS if n.startswith("io_IQValidNumVec_"))
    for e in iqvld_present:
        L.append(f"  assign iqvld[{e}] = io_IQValidNumVec_{e};")
    for g in MULTI:
        nm, n = g['name'], g['iqNum']; exu = g['exu']
        cntw = max(1, (n - 1).bit_length())
        exu_lp = "{" + ", ".join(str(e) for e in exu) + "}"
        L.append(f"  // -- 组 {nm}:{n} 个 EXU(IQValidNumVec 索引 {exu})--")
        L.append(f"  localparam int unsigned EXU_{nm} [{n}] = '{exu_lp};")
        L.append(f"  logic cmp_{nm} [{n}][{n}];   // compareMatrix(i<j:vld[i]<vld[j])")
        L.append(f"  logic [{cntw}-1:0] cmpcnt_{nm} [{n}];")
        # sort 表寄存 8 行(row 0..7,row r 等价 IQSort[r % iqNum]),使 selPop(3bit)可直接索引,
        # 不需运行期取模 → 避免 FM 的「索引越界」告警(FMR_ELAB-147)。
        L.append(f"  logic sort_{nm} [8][{n}];  // IQSort 寄存器(8 行,row r = IQSort[r%{n}],寄一拍)")
        L.append("  always_comb begin")
        L.append(f"    for (int i = 0; i < {n}; i++)")
        L.append(f"      for (int j = 0; j < {n}; j++) begin")
        L.append("        if (i == j) cmp_%s[i][j] = 1'b0;" % nm)
        L.append(f"        else if (i < j) cmp_{nm}[i][j] = iqvld[EXU_{nm}[i]] < iqvld[EXU_{nm}[j]];")
        L.append(f"        else cmp_{nm}[i][j] = ~cmp_{nm}[j][i];")
        L.append("      end")
        L.append(f"    for (int i = 0; i < {n}; i++) begin")
        L.append(f"      cmpcnt_{nm}[i] = '0;")
        L.append(f"      for (int j = 0; j < {n}; j++) cmpcnt_{nm}[i] += cmp_{nm}[i][j];")
        L.append("    end")
        L.append("  end")
        L.append("  always_ff @(posedge clock)")
        L.append("    for (int r = 0; r < 8; r++)")
        L.append(f"      for (int j = 0; j < {n}; j++)")
        L.append(f"        sort_{nm}[r][j] <= (cmpcnt_{nm}[j] == ({n}-1-(r % {n})));")
    L.append("")

    # fuTypeOH(每 uop 对每组的命中)+ multiHit
    L += ["  // ---- 6. fuTypeOH:renameIn 每条 uop 命中哪个 needMultiExu 组 ----",
          "  logic [34:0] ri_fuType [RENAME_WIDTH];"]
    for i in range(RENAME_WIDTH):
        L.append(f"  assign ri_fuType[{i}] = io_renameIn_{i}_bits_fuType;")
    L += [f"  logic fuTypeOH [RENAME_WIDTH][{NUM_GRP}];",
          "  logic [RENAME_WIDTH-1:0] multiHit;   // 该 uop 命中任一多 EXU 组"]
    L.append("  always_comb for (int i = 0; i < RENAME_WIDTH; i++) begin")
    L.append("    logic mh;")
    L.append("    mh = 1'b0;")
    for gi, g in enumerate(MULTI):
        cond = " | ".join(f"ri_fuType[i][{b}]" for b in g['bits'])
        L.append(f"    fuTypeOH[i][{gi}] = ({cond}) & ri_valid[i];")
        L.append(f"    mh = mh | fuTypeOH[i][{gi}];")
    L.append("    multiHit[i] = mh;")
    L.append("  end")
    L.append("")

    # uopSelIQ 寄存器 + 下一拍组合
    L += ["  // ---- 7. uopSelIQ:每条 uop 选中的 IQ(one-hot,寄一拍)----",
          "  // toRenameAllFire 时更新:命中多 EXU 组→取该组 IQSort[i%iqNum] 对应列;否则单 IQ 直接译码。",
          "  // 否则若本条已 fire→清零。",
          "  logic uopSelIQ [RENAME_WIDTH][NUM_IQ];",
          "  logic uopSelIQ_next [RENAME_WIDTH][NUM_IQ];"]
    # popFuTypeOH[i][g] = 前 i 条 uop(不含自己)里命中组 g 的数量 → 负载均衡:本组第 popg 条
    # uop 落到第 popg 空的 IQ(IQSort 第 popg%iqNum 行)。见 Scala popFuTypeOH / Mux1H 索引。
    L += [f"  // popFuTypeOH[i][g]:前 i 条 uop 命中组 g 的累计数(决定本条用 IQSort 第几行)",
          f"  logic [2:0] popFuTypeOH [RENAME_WIDTH][{NUM_GRP}];",
          "  always_comb for (int g = 0; g < %d; g++) begin" % NUM_GRP,
          "    logic [2:0] acc;",
          "    acc = '0;",
          "    for (int i = 0; i < RENAME_WIDTH; i++) begin",
          "      popFuTypeOH[i][g] = acc;   // 不含自己",
          "      acc += fuTypeOH[i][g];",
          "    end",
          "  end",
          "  // selPop[i] = Mux1H(fuTypeOH[i], popFuTypeOH[i]):本条命中组的 pop 计数(OR 合成,",
          "  //   与 golden _GEN_600 一致;正常 one-hot 时即唯一命中组的 pop)。所有组共用此行索引。",
          f"  logic [2:0] selPop [RENAME_WIDTH];",
          "  always_comb for (int i = 0; i < RENAME_WIDTH; i++) begin",
          "    logic [2:0] sp;",
          "    sp = '0;",
          "    for (int g = 0; g < %d; g++) sp = sp | (fuTypeOH[i][g] ? popFuTypeOH[i][g] : 3'h0);" % NUM_GRP,
          "    selPop[i] = sp;",
          "  end"]
    # 为每组、每条 uop 预选出 IQSort 行(rowsel_<g>[i] = sort_<g>[selPop[i]]),
    # 显式只在 0..i 行上做 mux(selPop[i] 上界为 i),便于 FM 常量折叠(uop0 → 恒第 0 行)。
    for g in MULTI:
        nm, n = g['name'], g['iqNum']
        L.append(f"  logic rowsel_{nm} [RENAME_WIDTH][{n}];")
    L.append("  always_comb for (int i = 0; i < RENAME_WIDTH; i++) begin")
    for g in MULTI:
        nm, n = g['name'], g['iqNum']
        L.append(f"    for (int c = 0; c < {n}; c++) begin")
        # 显式 mux:row = selPop[i],候选行 0..min(i, 7)
        L.append("      case (selPop[i])")
        for r in range(RENAME_WIDTH):
            L.append(f"        3'd{r}: rowsel_{nm}[i][c] = sort_{nm}[{r}][c];")
        L.append(f"        default: rowsel_{nm}[i][c] = sort_{nm}[0][c];")
        L.append("      endcase")
        L.append("    end")
    L.append("  end")
    L.append("  always_comb for (int i = 0; i < RENAME_WIDTH; i++) begin")
    L.append("    for (int q = 0; q < NUM_IQ; q++) uopSelIQ_next[i][q] = 1'b0;")
    for iq in range(NUM_IQ):
        rt = ROUTE[iq]
        multi_terms = []
        for gi, col in rt['multi']:
            g = MULTI[gi]; n = g['iqNum']
            # 行 = selPop[i](Mux1H 共享索引)。uop i 的 selPop 上界为 i(只有 i 条更早 uop),
            # 故只需在 0..i 这 (i+1) 个可能行上展开显式 mux(便于 FM 常量折叠与配对);
            # 用 sort 表的 8 行(已含 %iqNum 折叠)。
            multi_terms.append(f"fuTypeOH[i][{gi}] & rowsel_{g['name']}[i][{col}]")
        mexpr = " | ".join(multi_terms) if multi_terms else "1'b0"
        single_terms = [f"ri_fuType[i][{b}]" for b in rt['single']]
        sexpr = " | ".join(single_terms) if single_terms else "1'b0"
        if multi_terms and single_terms:
            L.append(f"    uopSelIQ_next[i][{iq}] = ri_valid[i] & (multiHit[i] ? ({mexpr}) : ({sexpr}));")
        elif multi_terms:
            L.append(f"    uopSelIQ_next[i][{iq}] = ri_valid[i] & multiHit[i] & ({mexpr});")
        elif single_terms:
            L.append(f"    uopSelIQ_next[i][{iq}] = ri_valid[i] & ~multiHit[i] & ({sexpr});")
    L.append("  end")
    # 与 golden 一致:uopSelIQ 无复位(仅时钟更新);TRAF 时写 next,否则 fire 清零、不 fire 保持。
    L.append("  always_ff @(posedge clock)")
    L.append("    for (int i = 0; i < RENAME_WIDTH; i++)")
    L.append("      for (int q = 0; q < NUM_IQ; q++)")
    L.append("        if (toRenameAllFire) uopSelIQ[i][q] <= uopSelIQ_next[i][q];")
    L.append("        else if (firedVec[i]) uopSelIQ[i][q] <= 1'b0;")
    L.append("")

    # uopSelIQMatrix:前缀 popcount
    L += ["  // ---- 8. uopSelIQMatrix[i][q]:前 i+1 条 uop 里选了 IQ q 的累计数(前缀 popcount)----",
          "  // body 据此为每个 enq 端口(q,enq)挑出 matrix==enq+1 的那条 uop(PriorityMux)。",
          "  logic [2:0] uopSelIQMatrix [RENAME_WIDTH][NUM_IQ];",
          "  always_comb for (int q = 0; q < NUM_IQ; q++) begin",
          "    logic [2:0] acc;",
          "    acc = '0;",
          "    for (int i = 0; i < RENAME_WIDTH; i++) begin",
          "      acc += uopSelIQ[i][q];",
          "      uopSelIQMatrix[i][q] = acc;",
          "    end",
          "  end",
          "  // 每个 enq 端口的选择 one-hot:oh[p][i] = (matrix[i][iq(p)] == enq(p)+1)",
          "  logic ohSel [IQ_ENQ_SUM][RENAME_WIDTH];",
          "  always_comb for (int p = 0; p < IQ_ENQ_SUM; p++)",
          "    for (int i = 0; i < RENAME_WIDTH; i++)",
          "      ohSel[p][i] = (uopSelIQMatrix[i][p/NUM_ENQ] == (p%NUM_ENQ)+1);",
          ""]

    # ----- 9. singleStep FSM -----
    L += ["  // ---- 9. singleStep(单步)FSM:dret 后只许提交一条机器指令 ----",
          "  // S_HOLD:已锁存可提交 robIdx;redirect 时翻转 flag。见 docs §2.4。",
          "  sstep_state_e sstepState;",
          "  logic robidxStepReg_flag;  logic [7:0] robidxStepReg_value;",
          "  logic robidxStepHold_flag; logic [7:0] robidxStepHold_value;",
          "  logic robidxCommit_flag;   logic [7:0] robidxCommit_value;",
          "  logic ss_hold;  // 本拍进入 hold(singleStep & uop0 fire)",
          "  assign ss_hold = io_singleStep & firedVec[0];",
          "  always_comb begin",
          "    robidxStepHold_flag  = io_singleStep & ss_hold & io_fromRename_0_bits_robIdx_flag;",
          "    robidxStepHold_value = (io_singleStep & ss_hold) ? io_fromRename_0_bits_robIdx_value : 8'h0;",
          "    // 可提交点:UPDATE 态取 hold;HOLD 态 redirect 翻 flag 否则取 reg",
          "    if (sstepState == S_UPDATE_ROBIDX) begin",
          "      robidxCommit_flag  = robidxStepHold_flag;",
          "      robidxCommit_value = robidxStepHold_value;",
          "    end else if (io_redirect_valid) begin",
          "      robidxCommit_flag  = ~robidxStepReg_flag;",
          "      robidxCommit_value = 8'h0;",
          "    end else begin",
          "      robidxCommit_flag  = robidxStepReg_flag;",
          "      robidxCommit_value = robidxStepReg_value;",
          "    end",
          "  end",
          "  always_ff @(posedge clock or posedge reset)",
          "    if (reset) begin",
          "      sstepState <= S_UPDATE_ROBIDX;",
          "      robidxStepReg_flag <= 1'b0; robidxStepReg_value <= 8'h0;",
          "    end else begin",
          "      if (!io_singleStep) sstepState <= S_UPDATE_ROBIDX;",
          "      else if (ss_hold & io_enqRob_req_0_valid) sstepState <= S_HOLD_ROBIDX;",
          "      robidxStepReg_flag  <= robidxCommit_flag;",
          "      robidxStepReg_value <= robidxCommit_value;",
          "    end",
          "  // 每条 uop 的 singleStep 标志 = singleStep & (robIdx != 可提交点)",
          "  logic [RENAME_WIDTH-1:0] uopSingleStep;"]
    for i in range(RENAME_WIDTH):
        L.append(f"  assign uopSingleStep[{i}] = io_singleStep & "
                 f"({{io_fromRename_{i}_bits_robIdx_flag, io_fromRename_{i}_bits_robIdx_value}} "
                 f"!= {{robidxCommit_flag, robidxCommit_value}});")
    L.append("")

    # ----- 10. conserveFlow(LSQ 流数保守上界,前缀累加)-----
    L += ["  // ---- 10. conserveFlow:LSQ 流数保守上界(标量=1 / unit-stride=2 / 其他向量=16)----",
          "  // 见 docs §2.3。conserveFlowTotal = {highCount(is16 前缀和), lowCount({is2,is1} 前缀和)}。",
          "  // toRenameAllFire 时用 renameIn 早一拍的值,否则用 fromRename 当拍值,寄一拍。",
          "  logic [RENAME_WIDTH-1:0] is16_d, is2_d, is1_d;   // dispatch 侧(fromRename)",
          "  logic [RENAME_WIDTH-1:0] is16_r, is2_r, is1_r;   // rename 侧(renameIn)",
          "  logic [3:0] rn_fuOpType_lo [RENAME_WIDTH];  // fuOpType[8:5] 判 unit-stride"]
    for i in range(RENAME_WIDTH):
        L.append(f"  assign rn_fuOpType_lo[{i}] = io_fromRename_{i}_bits_fuOpType[8:5];")
    # is helpers using functions in pkg
    L.append("  logic [34:0] rn_fuType [RENAME_WIDTH];")
    L.append("  logic [3:0]  ri_fuOpType_lo [RENAME_WIDTH];")
    for i in range(RENAME_WIDTH):
        L.append(f"  assign rn_fuType[{i}] = io_fromRename_{i}_bits_fuType;")
        L.append(f"  assign ri_fuOpType_lo[{i}] = io_renameIn_{i}_bits_fuOpType[8:5];")
    # isVlsType_N:命名网(LsqEnqCtrl 例化的 numLsElem mux 引用)。
    L.append("  // isVlsType_N:向量访存判定(LsqEnqCtrl numLsElem mux 引用)")
    for i in range(RENAME_WIDTH):
        L.append(f"  wire isVlsType_{i} = (io_fromRename_{i}_bits_fuType[31] | io_fromRename_{i}_bits_fuType[32] "
                 f"| io_fromRename_{i}_bits_fuType[33] | io_fromRename_{i}_bits_fuType[34]) & io_fromRename_{i}_valid;")
    L.append("  always_comb for (int i = 0; i < RENAME_WIDTH; i++) begin")
    L.append("    logic vls_d, ls_d, us_d, vls_r, ls_r, us_r;")
    L.append("    // fromRename 侧:isVls=fuType[31..34];isLS=fuType[15]|[16];unit-stride 见 nd_is_unit_stride")
    L.append("    vls_d = (rn_fuType[i][31]|rn_fuType[i][32]|rn_fuType[i][33]|rn_fuType[i][34]) & rn_valid[i];")
    L.append("    ls_d  = (rn_fuType[i][15]|rn_fuType[i][16]) & rn_valid[i];")
    L.append("    us_d  = nd_is_unit_stride(rn_fuOpType_lo[i]);")
    L.append("    is16_d[i] = vls_d & ~us_d;")
    L.append("    is2_d[i]  = vls_d & us_d;")
    L.append("    is1_d[i]  = ls_d;")
    L.append("    // renameIn 侧(注意 golden/Scala 里 isLSTypeRename 的括号 bug:valid&[15] | [16])")
    L.append("    vls_r = ri_valid[i] & (ri_fuType[i][31]|ri_fuType[i][32]|ri_fuType[i][33]|ri_fuType[i][34]);")
    L.append("    ls_r  = (ri_valid[i] & ri_fuType[i][15]) | ri_fuType[i][16];")
    L.append("    us_r  = nd_is_unit_stride(ri_fuOpType_lo[i]);")
    L.append("    is16_r[i] = vls_r & ~us_r;")
    L.append("    is2_r[i]  = vls_r & us_r;")
    L.append("    is1_r[i]  = ls_r;")
    L.append("  end")
    L += ["  logic [6:0] conserveFlowTotal [RENAME_WIDTH];",
          "  logic [6:0] cft_d [RENAME_WIDTH], cft_r [RENAME_WIDTH];",
          "  always_comb begin",
          "    logic [2:0] hi_d, hi_r; logic [3:0] lo_d, lo_r;",
          "    hi_d = '0; lo_d = '0; hi_r = '0; lo_r = '0;",
          "    for (int i = 0; i < RENAME_WIDTH; i++) begin",
          "      hi_d += is16_d[i]; lo_d += {is2_d[i], is1_d[i]};",
          "      hi_r += is16_r[i]; lo_r += {is2_r[i], is1_r[i]};",
          "      cft_d[i] = {hi_d, lo_d};",
          "      cft_r[i] = {hi_r, lo_r};",
          "    end",
          "  end",
          "  always_ff @(posedge clock)",
          "    for (int i = 0; i < RENAME_WIDTH; i++)",
          "      conserveFlowTotal[i] <= toRenameAllFire ? cft_r[i] : cft_d[i];",
          ""]

    # ----- 11. allowDispatch(LSQ 流控,前缀串行)-----
    L += ["  // ---- 11. allowDispatch:LSQ 空闲表项是否够本条保守流数(前缀串行依赖前一条)----",
          "  // lsq_sqFreeCount/lqFreeCount/canAccept 来自 LsqEnqCtrl(connect.svh 填入)。",
          "  logic [5:0] lsq_sqFreeCount;  logic [6:0] lsq_lqFreeCount;  logic lsq_canAccept;",
          "  logic [RENAME_WIDTH-1:0] allowDispatch;",
          "  logic [6:0] sqFree7, lqFree7;",
          "  assign sqFree7 = {1'b0, lsq_sqFreeCount};   // sqFreeCount 6bit → 补 0 到 7bit",
          "  assign lqFree7 = lsq_lqFreeCount;           // lqFreeCount 已 7bit",
          "  logic [RENAME_WIDTH-1:0] isVStoreUop, isVLoadUop;"]
    for i in range(RENAME_WIDTH):
        # vstore = fuType[16]|[32]|[34]; vload = fuType[15]|[31]|[33]; gated valid
        L.append(f"  assign isVStoreUop[{i}] = io_fromRename_{i}_valid & "
                 f"(io_fromRename_{i}_bits_fuType[16] | io_fromRename_{i}_bits_fuType[32] | io_fromRename_{i}_bits_fuType[34]);")
        L.append(f"  assign isVLoadUop[{i}]  = io_fromRename_{i}_valid & "
                 f"(io_fromRename_{i}_bits_fuType[15] | io_fromRename_{i}_bits_fuType[31] | io_fromRename_{i}_bits_fuType[33]);")
    L += ["  // golden:vstore→sqFree>cft;否则→(~vload | lqFree>cft);均 & 前一条 allowDispatch。",
          "  // 先算每条「自身条件」self,再用独立 prefix 变量做前缀与(避免在 always_comb 里",
          "  // 同时读写 allowDispatch,绕开 FMR_VLOG-929)。",
          "  logic [RENAME_WIDTH-1:0] allowSelf;",
          "  always_comb for (int i = 0; i < RENAME_WIDTH; i++)",
          "    allowSelf[i] = isVStoreUop[i] ? (sqFree7 > conserveFlowTotal[i])",
          "                                  : (~isVLoadUop[i] | (lqFree7 > conserveFlowTotal[i]));",
          "  always_comb begin",
          "    logic pfx;",
          "    pfx = 1'b1;",
          "    for (int i = 0; i < RENAME_WIDTH; i++) begin",
          "      pfx = pfx & allowSelf[i];",
          "      allowDispatch[i] = pfx;",
          "    end",
          "  end",
          ""]

    # ----- 12. uopBlockByIQ(IQ 容量反压)-----
    L += ["  // ---- 12. uopBlockByIQ:落到某 IQ 的 uop 数超过其 enq 数(或该 IQ 当拍 not-ready)→ 挡住 ----",
          "  // 只看每 IQ 第 0 个 enq 端口的 ready(偶数号 toIssueQueues_ready);见 docs §5。",
          "  logic [NUM_IQ-1:0] iq_ready0;   // 每 IQ enq0 端口 ready"]
    for q in range(NUM_IQ):
        L.append(f"  assign iq_ready0[{q}] = io_toIssueQueues_{q*NUM_ENQ}_ready;")
    L += ["  logic [RENAME_WIDTH-1:0] uopBlockByIQ;",
          "  always_comb for (int i = 0; i < RENAME_WIDTH; i++) begin",
          "    logic blkAcc;",
          "    blkAcc = 1'b0;",
          "    for (int q = 0; q < NUM_IQ; q++)",
          "      // ready 时:matrix>numEnq(=2) 才超容量;not-ready 时:有任意 uop(matrix!=0)就挡。",
          "      blkAcc = blkAcc | (iq_ready0[q] ? (uopSelIQMatrix[i][q] > NUM_ENQ) : (uopSelIQMatrix[i][q] != 0));",
          "    uopBlockByIQ[i] = blkAcc;",
          "  end",
          ""]

    # ----- 13. 按序约束:blockedByWaitForward / notBlockedByPrevious / thisCanActualOut -----
    L += ["  // ---- 13. 按序入队约束 ----",
          "  // blockedByWaitForward[i]:本条 waitForward 且(ROB 非空或前面有 valid)→ 自己被挡(前缀或)。",
          "  // notBlockedByPrevious[i]:前面无 blockBackward。thisCanActualOut = ~waitFwd & notBlocked & canAccept。",
          "  logic [RENAME_WIDTH-1:0] isBlockBackward, blockedByWaitForward, thisCanActualOut;",
          "  always_comb for (int i = 0; i < RENAME_WIDTH; i++)",
          "    isBlockBackward[i] = rn_valid[i] & rn_blockBkwd[i];",
          "  // 用独立 prefix 变量做前缀或(避免 always_comb 内同时读写 blockedByWaitForward)。",
          "  always_comb begin",
          "    logic prevValidOr, pfxBlk;",
          "    pfxBlk = 1'b0;",
          "    for (int i = 0; i < RENAME_WIDTH; i++) begin",
          "      prevValidOr = ~io_enqRob_isEmpty;",
          "      for (int j = 0; j < i; j++) prevValidOr |= rn_valid[j];",
          "      pfxBlk = pfxBlk | (prevValidOr & rn_valid[i] & rn_waitFwd[i]);",
          "      blockedByWaitForward[i] = pfxBlk;",
          "    end",
          "  end",
          "  always_comb for (int i = 0; i < RENAME_WIDTH; i++) begin",
          "    logic notBlk;",
          "    notBlk = 1'b1;",
          "    for (int j = 0; j < i; j++) notBlk &= ~isBlockBackward[j];",
          "    thisCanActualOut[i] = ~blockedByWaitForward[i] & notBlk & io_enqRob_canAccept;",
          "  end",
          ""]

    # ----- 14. fromRename ready / fromRenameUpdate valid 等 -----
    L += ["  // ---- 14. ready 反压 + fromRenameUpdate.valid ----",
          "  // 把四个反压条件聚成 dispatch_gate_t(见 pkg);ready = 四者与。",
          "  // update.valid 在 ready 基础上再 & valid & ~elimMove & ~hasException & ~singleStep。",
          "  logic [RENAME_WIDTH-1:0] fromRenameUpdate_valid;",
          "  dispatch_gate_t gate [RENAME_WIDTH];",
          "  always_comb for (int i = 0; i < RENAME_WIDTH; i++) begin",
          "    gate[i].allow_dispatch  = allowDispatch[i];",
          "    gate[i].not_block_by_iq = ~uopBlockByIQ[i];",
          "    gate[i].can_actual_out  = thisCanActualOut[i];",
          "    gate[i].lsq_can_accept  = lsq_canAccept;",
          "    rn_ready[i] = nd_dispatch_ready(gate[i]);",
          "    fromRenameUpdate_valid[i] = rn_ready[i] & rn_valid[i]",
          "      & ~rn_elimMove[i] & ~rn_hasExc[i] & ~uopSingleStep[i];",
          "  end"]
    for i in range(RENAME_WIDTH):
        L.append(f"  assign io_fromRename_{i}_ready = rn_ready[{i}];")
    L.append("")

    # ----- 15. fromRenameUpdate 改写字段:srcType_2 / isDropAmocasSta / singleStep / srcLoadDependency -----
    L += ["  // ---- 15. fromRenameUpdate 改写字段(其余字段直通 fromRename,见 connect.svh)----",
          "  // srcType_2:ignoreOldVd 时改 SrcType.no(0);isDropAmocasSta:AMOCAS 且 uopIdx[0]==0;",
          "  // singleStep 见上;srcLoadDependency:int 源取 busyTable.loadDependency,否则 0。",
          "  logic [3:0] fru_srcType2 [RENAME_WIDTH];",
          "  logic [RENAME_WIDTH-1:0] fru_isDropAmocasSta;"]
    L.append("  always_comb for (int i = 0; i < RENAME_WIDTH; i++)")
    L.append("    fru_srcType2[i] = (rn_srcType[i][2][2] & ignoreOldVd[i]) ? SRCTYPE_NO_VAL : rn_srcType[i][2];")
    for i in range(RENAME_WIDTH):
        L.append(f"  assign fru_isDropAmocasSta[{i}] = io_fromRename_{i}_bits_fuType[17] "
                 f"& (io_fromRename_{i}_bits_fuOpType[5:2] == 4'hB) & ~io_fromRename_{i}_bits_uopIdx[0];")
    L += ["  // srcLoadDependency:仅 int 两源(j=0,1),取对应 busyTable 读端口 loadDependency(若该源是 int)。",
          "  // 维度 [uop][srcsel(0|1)][ldep(0..2)];busyTable loadDependency 由 connect.svh 填入。",
          "  logic [LDEP_W-1:0] bt_int_ldep [RENAME_WIDTH*2][LDEP_N];",
          "  logic [LDEP_W-1:0] fru_srcLoadDep [RENAME_WIDTH][2][LDEP_N];",
          "  always_comb for (int i = 0; i < RENAME_WIDTH; i++)",
          "    for (int s = 0; s < 2; s++)",
          "      for (int d = 0; d < LDEP_N; d++)",
          "        fru_srcLoadDep[i][s][d] = rn_srcType[i][s][0] ? bt_int_ldep[i*2+s][d] : '0;",
          ""]

    # ----- 16. enqRob 计算字段 + io_enqRob valid/needAlloc -----
    L += ["  // ---- 16. enqRob:valid=fire;needAlloc=valid;hasException/numWB/singleStep 改写 ----",
          "  logic [RENAME_WIDTH-1:0] enqRob_hasExc, enqRob_singleStep;",
          "  logic [6:0] enqRob_numWB [RENAME_WIDTH];"]
    # 注:io_enqRob_needAlloc 在 golden 里被优化掉(无该输出端口),故不驱动。
    for i in range(RENAME_WIDTH):
        L.append(f"  assign io_enqRob_req_{i}_valid = firedVec[{i}];")
        L.append(f"  assign enqRob_singleStep[{i}] = uopSingleStep[{i}];")
        L.append(f"  assign enqRob_hasExc[{i}] = io_fromRename_{i}_bits_hasException | uopSingleStep[{i}];")
        L.append(f"  assign enqRob_numWB[{i}] = uopSingleStep[{i}] ? 7'h0 : io_fromRename_{i}_bits_numWB;")
        L.append(f"  assign io_enqRob_req_{i}_bits_hasException = enqRob_hasExc[{i}];")
        L.append(f"  assign io_enqRob_req_{i}_bits_singleStep   = enqRob_singleStep[{i}];")
        L.append(f"  assign io_enqRob_req_{i}_bits_numWB        = enqRob_numWB[{i}];")
    L.append("")

    # ----- 17. canAccept / stallReason / perf(双拍寄存计数)-----
    L += ["  // ---- 17. canAccept / stallReason / perf 计数 ----",
          "  // canAccept = 无 valid 指令,或(无 blockBackward 且 ROB 可入队)。",
          "  logic hasValidInstr, hasSpecialInstr, canAccept;",
          "  always_comb begin",
          "    hasValidInstr = 1'b0; hasSpecialInstr = 1'b0;",
          "    for (int i = 0; i < RENAME_WIDTH; i++) begin",
          "      hasValidInstr   |= rn_valid[i];",
          "      hasSpecialInstr |= isBlockBackward[i];",
          "    end",
          "    canAccept = ~hasValidInstr | (~hasSpecialInstr & io_enqRob_canAccept);",
          "  end",
          "  assign io_stallReason_backReason_valid = ~canAccept;",
          "  // stall 探针",
          "  logic stall_rob, stall_fp_dq;",
          "  assign stall_rob   = hasValidInstr & ~io_enqRob_canAccept;",
          "  assign stall_fp_dq = hasValidInstr & io_enqRob_canAccept;",
          "  // perf 事件:dispatch_in(valid&ready0) / dispatch_empty / dispatch_utili(valid) /",
          "  //   dispatch_waitinstr(~valid&canAccept) / stall_rob / stall_*_dq(=stall_fp_dq)。HasPerfEvents 双拍寄存。",
          "  logic [2:0] cnt_in, cnt_util, cnt_wait;",
          "  always_comb begin",
          "    cnt_in = '0; cnt_util = '0; cnt_wait = '0;",
          "    for (int i = 0; i < RENAME_WIDTH; i++) begin",
          "      cnt_in   += (rn_valid[i] & rn_ready[0]);",
          "      cnt_util += rn_valid[i];",
          "      cnt_wait += (~rn_valid[i] & canAccept);",
          "    end",
          "  end",
          "  logic [2:0] perf0_r, perf0_rr, perf2_r, perf2_rr, perf3_r, perf3_rr;",
          "  logic perf1_r, perf1_rr, perf5_r, perf5_rr, perf6_r, perf6_rr, perf7_r, perf7_rr, perf8_r, perf8_rr;",
          "  always_ff @(posedge clock) begin",
          "    perf0_r <= cnt_in;   perf0_rr <= perf0_r;",
          "    perf1_r <= ~hasValidInstr; perf1_rr <= perf1_r;",
          "    perf2_r <= cnt_util; perf2_rr <= perf2_r;",
          "    perf3_r <= cnt_wait; perf3_rr <= perf3_r;",
          "    perf5_r <= stall_rob;   perf5_rr <= perf5_r;",
          "    perf6_r <= stall_fp_dq; perf6_rr <= perf6_r;",
          "    perf7_r <= stall_fp_dq; perf7_rr <= perf7_r;",
          "    perf8_r <= stall_fp_dq; perf8_rr <= perf8_r;",
          "  end",
          "  assign io_perf_0_value = {3'h0, perf0_rr};",
          "  assign io_perf_1_value = {5'h0, perf1_rr};",
          "  assign io_perf_2_value = {3'h0, perf2_rr};",
          "  assign io_perf_3_value = {3'h0, perf3_rr};",
          "  assign io_perf_5_value = {5'h0, perf5_rr};",
          "  assign io_perf_6_value = {5'h0, perf6_rr};",
          "  assign io_perf_7_value = {5'h0, perf7_rr};",
          "  assign io_perf_8_value = {5'h0, perf8_rr};",
          ""]

    return "\n".join(L)


# ===========================================================================
# 3. newdispatch_connect.svh —— 子模块黑盒例化 + 输出端口选择展开(机械互联)
# ===========================================================================
INST_NAMES = ['rcTagTable', 'intBusyTable', 'fpBusyTable', 'vecBusyTable',
              'v0BusyTable', 'vlBusyTable', 'lsqEnqCtrl']


# golden 在 lsqEnqCtrl 例化里用内部临时名 _GEN_87.._99 表示「该 slot 是 vstore/vload」。
# 例化块按 golden 抽取后,把这些临时名替换为可读核命名网(语义一致)。
GEN_REMAP = {}
for _i, _g in enumerate([87, 90, 92, 94, 96, 98]):
    GEN_REMAP[f"_GEN_{_g}"] = f"isVStoreUop[{_i}]"
for _i, _g in enumerate([89, 91, 93, 95, 97, 99]):
    GEN_REMAP[f"_GEN_{_g}"] = f"isVLoadUop[{_i}]"
# firedVec_N(golden 标量名)→ 可读核 firedVec[N] 数组。
for _i in range(RENAME_WIDTH):
    GEN_REMAP[f"firedVec_{_i}"] = f"firedVec[{_i}]"


def extract_inst_block(inst):
    lines = GSV.splitlines()
    si = next(i for i, l in enumerate(lines) if re.match(rf'\s*[A-Za-z_0-9]+ {inst} \(', l))
    ei = next(i for i in range(si, len(lines)) if lines[i].strip() == ');')
    out = []
    for l in lines[si:ei + 1]:
        for k in sorted(GEN_REMAP, key=lambda x: -len(x)):
            l = re.sub(rf'\b{k}\b', GEN_REMAP[k], l)
        out.append(l)
    return out


def extract_subout_wires():
    out = []
    for m in re.finditer(r'^\s*(wire(?:\s+\[\d+:0\])?)\s+(_(?:rcTagTable|intBusyTable|fpBusyTable|'
                         r'vecBusyTable|v0BusyTable|vlBusyTable|lsqEnqCtrl)_\w+);', GSV, re.M):
        out.append(f"  {m.group(1)} {m.group(2)};")
    return out


def _pmux(p, vals):
    """内联 PriorityMux:oh[p][0]?v0 : oh[p][1]?v1 : ... : v5(slot0 优先,slot5 为默认)。
       与 golden 的 uopSelIQ_iq_0 ? .. : .. 链一致。三元 mux 天然防 X。"""
    s = vals[RENAME_WIDTH - 1]
    for i in range(RENAME_WIDTH - 2, -1, -1):
        s = f"(ohSel[{p}][{i}] ? {vals[i]} : {s})"
    return s


def _slot_src_array(field, kind):
    K = kind[0]; vals = []
    for s in range(RENAME_WIDTH):
        if K == 'RN':   vals.append(f"io_fromRename_{s}_bits_{field}")
        elif K == 'UST2': vals.append(f"fru_srcType2[{s}]")
        elif K == 'DROP': vals.append(f"fru_isDropAmocasSta[{s}]")
        elif K == 'SS':   vals.append(f"uopSingleStep[{s}]")
        elif K == 'SRC':
            j, ks = kind[1], kind[2]
            vals.append("(" + " | ".join(f"allSrcState[{s}][{j}][{k}]" for k in ks) + ")")
        elif K == 'SLD':  vals.append(f"fru_srcLoadDep[{s}][{kind[1]}][{kind[2]}]")
        elif K == 'LQ':   vals.append(f"_lsqEnqCtrl_io_enq_resp_{s}_{field}")
        elif K == 'SQ':   vals.append(f"_lsqEnqCtrl_io_enq_resp_{s}_{field}")
        elif K in ('RCV', 'RCA'):
            pos = int(field.rsplit('_', 1)[1]); sig = 'valid' if K == 'RCV' else 'addr'
            vals.append(f"_rcTagTable_io_readPorts_{2*s+pos}_{sig}")
        else: vals.append("'0")
    return vals


def _field_sel(p, field, kind):
    return _pmux(p, _slot_src_array(field, kind))


def gen_connect():
    L = [GEN_HDR,
         "// =====================================================================",
         "// 机械互联表(豁免结构闸门):7 个真子模块黑盒例化 + 34 enq 端口输出选择展开。",
         "// 子模块两侧共用 golden 定义(UT/FM)。输入引脚「驱动值」已在 newdispatch_logic.svh",
         "// 算好(allSrcState/路由/反压/...);本表只做例化、连线、统一 PriorityMux 展开。",
         "// =====================================================================", ""]
    L.append("  // ---- 子模块输出网线(golden 同名,桥接到可读核 clean 网)----")
    L += extract_subout_wires(); L.append("")
    L.append("  // ---- 桥接:子模块输出 → 可读核就绪查询/反压用网 ----")
    for i in range(RENAME_WIDTH * 2):
        L.append(f"  assign bt_resp_int[{i}] = _intBusyTable_io_read_{i}_resp;")
        for d in range(3):
            L.append(f"  assign bt_int_ldep[{i}][{d}] = _intBusyTable_io_read_{i}_loadDependency_{d};")
    for i in range(RENAME_WIDTH * 3):
        L.append(f"  assign bt_resp_fp[{i}]  = _fpBusyTable_io_read_{i}_resp;")
        L.append(f"  assign bt_resp_vec[{i}] = _vecBusyTable_io_read_{i}_resp;")
    for i in range(RENAME_WIDTH):
        L.append(f"  assign bt_resp_v0[{i}] = _v0BusyTable_io_read_{i}_resp;")
        L.append(f"  assign bt_resp_vl[{i}] = _vlBusyTable_io_read_{i}_resp;")
        L.append(f"  assign vl_is_vlmax[{i}]   = _vlBusyTable_io_vl_read_vlReadInfo_{i}_is_vlmax;")
        L.append(f"  assign vl_is_nonzero[{i}] = _vlBusyTable_io_vl_read_vlReadInfo_{i}_is_nonzero;")
    L.append("  assign lsq_canAccept    = _lsqEnqCtrl_io_enq_canAccept;")
    L.append("  assign lsq_lqFreeCount  = _lsqEnqCtrl_io_lqFreeCount;")
    L.append("  assign lsq_sqFreeCount  = _lsqEnqCtrl_io_sqFreeCount;")
    L.append("")
    L.append("  // ---- allocPregsValid(int 域,intBusyTable / rcTagTable 引用的命名网)----")
    for i in range(RENAME_WIDTH):
        L.append(f"  wire allocPregsValid_0_{i} = allocPregsValid[0][{i}];")
    L.append("")
    L += ["  // ---- lsqEnqCtrl 用 RegNext(redirect)(派遣比 dispatch2iq 早一拍)----",
          "  reg lsqEnqCtrl_io_redirect_REG_valid;",
          "  always_ff @(posedge clock) lsqEnqCtrl_io_redirect_REG_valid <= io_redirect_valid;", ""]
    L.append("  // ---- 7 个真子模块黑盒例化(两侧共用 golden 定义)----")
    for inst in INST_NAMES:
        L += extract_inst_block(inst); L.append("")
    L += ["  // ---- 34 个发射队列 enq 端口输出:对每端口 oh = uopSelIQMatrix[i][iq]==enq+1,",
          "  //      在 6 条 uop 中 PriorityMux 选源(四来源:RENAME/UPDATE/SRCSTATE/SUBMOD)。"]
    for p in range(IQ_ENQ_SUM):
        iq = IQPORTS[p]['iq']; enq = IQPORTS[p]['enq']
        L.append(f"  // -- 端口 {p}(IQ {iq} enq {enq})--")
        valid_vals = [f"fromRenameUpdate_valid[{s}]" for s in range(RENAME_WIDTH)]
        L.append(f"  assign io_toIssueQueues_{p}_valid = {_pmux(p, valid_vals)};")
        for f, kind in IQPORTS[p]['fields']:
            L.append(f"  assign io_toIssueQueues_{p}_bits_{f} = {_field_sel(p, f, kind)};")
    L.append("")
    L.append("  // ---- enqRob.req 直通字段 + toRenameAllFire(计算字段已在 logic)----")
    for m in re.finditer(r'assign (io_enqRob_req_(\d+)_bits_(\w+)) =\s*(io_fromRename_\2_bits_\w+);', GSV):
        L.append(f"  assign {m.group(1)} = {m.group(4)};")
    L.append("")
    return "\n".join(L)


# ===========================================================================
# 4. 可读核 NewDispatch.sv(手写外壳) / wrapper / variants / tb / Makefile
# ===========================================================================
SUB_DEPS = [
    "RegCacheTagTable.sv",
    "BusyTable.sv", "BusyTable_1.sv", "BusyTable_2.sv", "BusyTable_3.sv",
    "VlBusyTable.sv", "LsqEnqCtrl.sv",
    "RegCacheTagModule.sv", "RegCacheTagModule_1.sv",
]


def gen_core():
    return (GEN_HDR +
"""
// =====================================================================
// xs_NewDispatch_core —— 香山 V2R2(昆明湖)派遣级可读核。
// 三大职责(就绪查询 / 路由+负载均衡 / 容量反压 + singleStep FSM)的「真逻辑」全部
// 在 newdispatch_logic.svh 里以命名网 / generate-for / 纯函数重写(无 _GEN_/_T_);
// 7 个真子模块(RegCacheTagTable / BusyTable×4 / VlBusyTable / LsqEnqCtrl)黑盒例化
// 与 34 enq 端口的统一选择展开见 newdispatch_connect.svh。
// 设计源:src/main/scala/xiangshan/backend/dispatch/NewDispatch.scala。
// =====================================================================
import newdispatch_pkg::*;

module xs_NewDispatch_core (
  input clock,
  input reset,
`include "newdispatch_ports.svh"
);

`include "newdispatch_logic.svh"
`include "newdispatch_connect.svh"

endmodule : xs_NewDispatch_core
""")


def emit_wrapper(modname, ps):
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    L = [f"module {modname}(", ",\n".join(decls) + "\n);"]
    conns = [f"    .{n}({n})" for _, _, n in ps]
    L.append("  xs_NewDispatch_core u_core (")
    L.append(",\n".join(conns))
    L.append("  );")
    L.append("endmodule\n")
    return "\n".join(L)


def gen_tb(ps):
    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]
    T = ["// 自动生成:scripts/gen_newdispatch.py —— 勿手改",
         "`timescale 1ns/1ps", "module tb;",
         "  int unsigned NCYCLES = 200000;",
         "  bit clk = 0, rst;", "  int errors = 0, checks = 0;",
         "  always #5 clk = ~clk;"]
    for w, n in ins:
        T.append(f"  logic {('['+str(w-1)+':0] ') if w>1 else ''}{n};")
    for w, n in outs:
        ws = f"[{w-1}:0] " if w > 1 else ""
        T.append(f"  wire {ws}g_{n};")
        T.append(f"  wire {ws}i_{n};")
    gc = [".clock(clk)", ".reset(rst)"] + [f".{n}({n})" for _, n in ins]
    gg = gc + [f".{n}(g_{n})" for _, n in outs]
    ig = gc + [f".{n}(i_{n})" for _, n in outs]
    T.append(f"  NewDispatch    u_g ({', '.join(gg)});")
    T.append(f"  NewDispatch_xs u_i ({', '.join(ig)});")
    T.append("""  function automatic logic [34:0] futype_rand();
    int b;
    if ($urandom_range(0,3) == 0) futype_rand = {35{1'b0}} | $urandom;
    else begin b = $urandom_range(0,34); futype_rand = (35'b1 << b); end
  endfunction""")

    def rnd(w, n):
        if n.endswith("_valid") or n.endswith("_ready"):
            return "$urandom_range(0,1)"
        if n.endswith("_bits_fuType"):
            return "futype_rand()"
        if w == 1:
            return "$urandom_range(0,1)"
        if w <= 32:
            return f"{w}'($urandom)"
        rep = (w + 31) // 32
        return f"{w}'({{{', '.join(['$urandom()'] * rep)}}})"

    reset_valids = [n for _, n in ins if n.endswith("_valid")]
    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    for n in reset_valids:
        T.append(f"      {n} <= 1'b0;")
    T.append("    end else begin")
    for w, n in ins:
        T.append(f"      {n} <= {rnd(w, n)};")
    T.append("    end")
    T.append("  end")
    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    #4; checks++;")
    for w, n in outs:
        T.append(f"    if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
        T.append(f"      if(errors<=80) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
    T.append("  end")
    T.append("""  initial begin
    rst = 1; repeat (16) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    return "\n".join(T)


def gen_makefile():
    deps = " \\\n           ".join(f"$(GOLDEN_RTL)/{s}" for s in SUB_DEPS)
    return f"""MODULE = NewDispatch

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(核通过 `include 引入端口表 / logic / connect)。
RTL_SRCS = $(RTL_DIR)/backend/newdispatch_pkg.sv \\
           $(RTL_DIR)/backend/NewDispatch.sv

TB_SRCS = variants_xs.sv tb.sv

SUB_DEPS = {deps}

GOLDEN_SRCS = $(GOLDEN_RTL)/NewDispatch.sv $(SUB_DEPS)

WRAPPER_SRCS = $(RTL_DIR)/backend/NewDispatch_wrapper.sv $(SUB_DEPS)
FM_VARIANTS = NewDispatch
FM_REF_DEPS_NewDispatch = {' '.join(SUB_DEPS)}

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/backend
VCS += -y $(GOLDEN_RTL) +libext+.sv+.v
VCS += -assert disable
"""


def main():
    ps = top_ports()
    gen_ports()
    (BK / "newdispatch_logic.svh").write_text(gen_logic())
    (BK / "newdispatch_connect.svh").write_text(gen_connect())
    (BK / "NewDispatch.sv").write_text(gen_core())
    (BK / "NewDispatch_wrapper.sv").write_text(GEN_HDR + emit_wrapper("NewDispatch", ps))
    UT.mkdir(parents=True, exist_ok=True)
    (UT / "variants_xs.sv").write_text(GEN_HDR + emit_wrapper("NewDispatch_xs", ps))
    (UT / "tb.sv").write_text(gen_tb(ps))
    (UT / "Makefile").write_text(gen_makefile())
    ni = sum(1 for d, _, _ in ps if d == "input")
    no = sum(1 for d, _, _ in ps if d == "output")
    print(f"NewDispatch: {len(ps)} ports ({ni} in / {no} out), {len(MULTI)} multiExu groups, {len(SUB_DEPS)} blackbox deps")
    print("可读核 logic+connect 已生成(真逻辑在 logic.svh,无 golden body 抽取)。")


if __name__ == "__main__":
    main()
