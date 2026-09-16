#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
gen_matrix.py —— Entries* 家族「字段使用矩阵」生成器（从 golden RTL 实测，不看 Chisel）

为什么要有这个文件
------------------
共享核 xs_iq_entries_core.sv 是 14 个 Entries* 变体共用的。为某一个变体做的
「优化」（删字段 / 缩位宽 / 把某个状态常量折叠掉）如果没查过其它 13 个变体，
就会悄悄把别的变体做错，而且因为那些变体还没写，没人会发现。

所以规矩是：**裁剪任何状态之前，先跑这个脚本，看该字段在 14 个变体里的分布。**

判据是 golden（firtool 展平产物）的端口与实例，不是 Chisel 的默认值——本轮已经
有几个静默 bug 正是「Chisel 读起来是 A、firtool 展开成 B」。

用法
----
  python3 gen_matrix.py                 # 打印矩阵到 stdout，并写 matrix.tsv
  python3 gen_matrix.py --check         # 与已提交的 matrix.tsv 比对，不一致则非零退出
  python3 gen_matrix.py --golden <dir>  # 换 golden 目录

输出
----
  matrix.tsv     机器可读，一行一个变体，一列一个字段维度
  matrix.md      人读版（分组对齐）
"""

import argparse, os, re, sys, hashlib, collections

DEFAULT_GOLDEN = "/home/eda/xs-env/G1-canonical/golden-rtl"

# 端口行:  input  [7:0]   io_xxx,      /  output io_yyy
PORT_RE = re.compile(r'^\s*(input|output)\s+(?:\[(\d+):(\d+)\]\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*,?\s*$')
# 实例行:  ModuleName instName (
INST_RE = re.compile(r'^\s*([A-Z][A-Za-z0-9_]*)\s+([a-zA-Z_][A-Za-z0-9_]*)\s*\(\s*$')


def parse_golden(path):
    """返回 (ports: name->width, insts: modname->count)。只解析顶层 module 的端口。"""
    ports = {}
    insts = collections.Counter()
    in_ports = False
    started = False
    top = os.path.basename(path)[:-3]
    with open(path) as fh:
        for line in fh:
            if not started:
                if line.startswith("module " + top + "("):
                    started = True
                    in_ports = True
                continue
            if in_ports:
                if re.match(r'^\s*\);', line):
                    in_ports = False
                    continue
                m = PORT_RE.match(line)
                if m:
                    _dir, hi, _lo, name = m.groups()
                    ports[name] = (int(hi) + 1) if hi is not None else 1
                continue
            m = INST_RE.match(line)
            if m:
                insts[m.group(1)] += 1
    return ports, insts


# ---------------------------------------------------------------------------
# 探针：每个探针从端口表里量出一个「字段维度」。
# 探针只回答「golden 里有没有 / 多宽 / 几路」，不做任何语义推断。
# ---------------------------------------------------------------------------

def count_idx(ports, pat):
    """统计形如 prefix_<N>... 的最大下标+1（即该向量的路数）。"""
    rx = re.compile(pat)
    idxs = set()
    for p in ports:
        m = rx.match(p)
        if m:
            idxs.add(int(m.group(1)))
    return (max(idxs) + 1) if idxs else 0


def width(ports, name):
    return ports.get(name, 0)


def has(ports, name):
    return 1 if name in ports else 0


def fu_bits(ports):
    """status.fuType 在 golden 里被 firtool 剪成若干单 bit 端口 fuType_<k>，
    k 是原 35 位 FuType one-hot 里被本变体保留的位号。"""
    rx = re.compile(r'^io_enq_0_bits_status_fuType_(\d+)$')
    return sorted(int(rx.match(p).group(1)) for p in ports if rx.match(p))


def idxlist(ports, pat):
    """返回匹配 pat 的端口下标列表（升序）。用于记录 firtool 留下的稀疏下标。"""
    rx = re.compile(pat)
    return sorted(int(rx.match(p).group(1)) for p in ports if rx.match(p))


def probe(name, ports, insts, golden):
    """从一个变体的 golden 顶层端口 + 实例表量出它的字段使用画像。

    ★ 所有探针只描述 golden 的事实（有没有这个端口 / 多宽 / 几路 / 下标是哪些），
      不做语义推断。凡是 firtool 可能把字段删掉或稀疏化的地方，都记**下标本身**
      而不是只记个数 —— 稀疏正是共享核最容易出错的地方。
    """
    P = ports
    d = {}
    d["variant"] = name

    # ---- 结构：条目数 / 发射口数 ----
    d["numEnq"] = count_idx(P, r'^io_enq_(\d+)_valid$')
    d["numDeq"] = count_idx(P, r'^io_deqReady_(\d+)$')
    others = sorted(((m, c) for m, c in insts.items() if m.startswith("OthersEntry")),
                    key=lambda t: t[1])
    nEnqInst = sum(c for m, c in insts.items() if m.startswith("EnqEntry"))
    d["numEntries"] = sum(c for _, c in others) + nEnqInst
    d["numSimp"], d["numComp"] = (others[0][1], others[1][1]) if len(others) == 2 else (-1, -1)
    d["enqEntryMod"] = ";".join(sorted(m for m in insts if m.startswith("EnqEntry")))
    d["othersEntryMod"] = ";".join(f"{m}x{c}" for m, c in sorted(others, key=lambda t: t[0]))
    d["nEnqPolicy"] = sum(c for m, c in insts.items() if m.startswith("EnqPolicy"))
    d["deqSelOH_w"] = width(P, "io_deqSelOH_0_bits")

    # ---- status.srcStatus：每源字段 ----
    d["nSrcStatus"] = count_idx(P, r'^io_enq_0_bits_status_srcStatus_(\d+)_psrc$')
    d["psrc_w"] = width(P, "io_enq_0_bits_status_srcStatus_0_psrc")
    d["srcType_w"] = width(P, "io_enq_0_bits_status_srcStatus_0_srcType")
    d["dataSources_w"] = width(P, "io_enq_0_bits_status_srcStatus_0_dataSources_value")
    d["ldDep_pipes"] = count_idx(P, r'^io_enq_0_bits_status_srcStatus_0_srcLoadDependency_(\d+)$')
    d["ldDep_w"] = width(P, "io_enq_0_bits_status_srcStatus_0_srcLoadDependency_0")
    d["useRegCache"] = has(P, "io_enq_0_bits_status_srcStatus_0_useRegCache")
    d["regCacheIdx_w"] = width(P, "io_enq_0_bits_status_srcStatus_0_regCacheIdx")

    # ---- status 其余 ----
    d["robIdx_w"] = width(P, "io_enq_0_bits_status_robIdx_value")
    fb = fu_bits(P)
    d["fuTypeBits"] = ",".join(str(b) for b in fb)
    d["nFuTypeBits"] = len(fb)
    d["imm_w"] = width(P, "io_enq_0_bits_imm")
    d["status_blocked"] = has(P, "io_enq_0_bits_status_blocked")
    d["vecMem_sqIdx"] = has(P, "io_enq_0_bits_status_vecMem_sqIdx_value")
    d["vecMem_lqIdx"] = has(P, "io_enq_0_bits_status_vecMem_lqIdx_value")
    d["vecMem_numLsElem"] = width(P, "io_enq_0_bits_status_vecMem_numLsElem")
    d["payload_srcs"] = count_idx(P, r'^io_enq_0_bits_payload_srcType_(\d+)$')
    d["nDeqStatusPorts"] = len([q for q in P if q.startswith("io_deqEntry_0_bits_status")])

    # ---- 唤醒 ----
    # WB 唤醒有 valid；IQ 唤醒的 valid 在 golden 里没有独立端口（Entries.scala 把它
    # 折进 og0Cancel 那条路），所以 IQ 路数只能按 bits_pdest 数。
    # ★ 这是「Chisel 读起来有 valid、firtool 展开后没有」的实例，判据以 golden 为准。★
    d["nWkWB"] = count_idx(P, r'^io_wakeUpFromWB_(\d+)_valid$')
    d["nWkWBDly"] = count_idx(P, r'^io_wakeUpFromWBDelayed_(\d+)_valid$')
    d["wkWB_pdest_w"] = width(P, "io_wakeUpFromWB_0_bits_pdest")
    d["wkWB_wen"] = ",".join(w for w in ("rfWen", "fpWen", "vecWen", "v0Wen", "vlWen")
                             if "io_wakeUpFromWB_0_bits_" + w in P)
    d["nWkIQ"] = count_idx(P, r'^io_wakeUpFromIQ_(\d+)_bits_pdest$')
    d["nWkIQDly"] = count_idx(P, r'^io_wakeUpFromIQDelayed_(\d+)_bits_pdest$')
    d["wkIQ_pdest_w"] = width(P, "io_wakeUpFromIQ_0_bits_pdest")
    d["wkIQ_wen"] = ",".join(w for w in ("rfWen", "fpWen", "vecWen", "v0Wen", "vlWen")
                             if "io_wakeUpFromIQ_0_bits_" + w in P)
    d["wkIQ_ldDep_pipes"] = count_idx(P, r'^io_wakeUpFromIQ_0_bits_loadDependency_(\d+)$')
    d["wkIQ_hasRcDest"] = has(P, "io_wakeUpFromIQ_0_bits_rcDest")
    # is0Lat 只在「0 周期延迟」的那几路留了端口，其余路被折成常量 —— 记下标。
    d["wkIQ_is0LatIdx"] = ",".join(str(i) for i in idxlist(P, r'^io_wakeUpFromIQ_(\d+)_bits_is0Lat$'))

    # ---- 取消网络 ----
    # og0Cancel/og1Cancel 是按 IQ 唤醒源的 Vec[Bool]，firtool 删掉用不到的位，
    # 留下的是**稀疏下标**。共享核若按 0..N-1 连线就会错位。
    d["og0CancelIdx"] = ",".join(str(i) for i in idxlist(P, r'^io_og0Cancel_(\d+)$'))
    d["og1CancelIdx"] = ",".join(str(i) for i in idxlist(P, r'^io_og1Cancel_(\d+)$'))
    d["nLdCancel"] = count_idx(P, r'^io_ldCancel_(\d+)_ld2Cancel$')
    d["ldCancel_ld1"] = has(P, "io_ldCancel_0_ld1Cancel")
    d["ldCancel_ld2"] = has(P, "io_ldCancel_0_ld2Cancel")
    d["nCancelDeqVec"] = count_idx(P, r'^io_cancelDeqVec_(\d+)$')

    # ---- 发射响应 ----
    for k in (0, 1, 2):
        d["nOg%dResp" % k] = count_idx(P, r'^io_og%dResp_(\d+)_valid$' % k)
        d["og%dResp_hasBits" % k] = has(P, "io_og%dResp_0_bits_resp" % k)
    d["resp_hasRobIdx"] = has(P, "io_og0Resp_0_bits_robIdx_value")
    d["resp_hasSqIdx"] = has(P, "io_og0Resp_0_bits_sqIdx_value")
    d["resp_hasUopIdx"] = has(P, "io_og0Resp_0_bits_uopIdx")
    d["resp_hasVecReplay"] = has(P, "io_og0Resp_0_bits_vecReplayMask")

    # ---- 出口 ----
    d["deqEntry_hasImm"] = has(P, "io_deqEntry_0_bits_imm")
    d["nExuSrcPerEntry"] = count_idx(P, r'^io_exuSources_0_(\d+)_value$')
    d["exuSources_w"] = width(P, "io_exuSources_0_0_value")
    d["nDataSrcPerEntry"] = count_idx(P, r'^io_dataSources_0_(\d+)_value$')
    d["dataSourcesOut_w"] = width(P, "io_dataSources_0_0_value")
    d["nLdDepOutPerEntry"] = count_idx(P, r'^io_loadDependency_0_(\d+)$')
    d["ldDepOut_w"] = width(P, "io_loadDependency_0_0")

    # ---- 向量 vl / 访存接口 ----
    d["vlFromInt"] = has(P, "io_vlFromIntIsZero")
    d["vlFromVf"] = has(P, "io_vlFromVfIsZero")
    d["fromMem"] = 1 if any(q.startswith("io_fromMem") for q in P) else 0
    d["vecLdIn"] = 1 if any(q.startswith("io_vecLdIn") for q in P) else 0
    d["vecMemIn"] = 1 if any(q.startswith("io_vecMemIn") for q in P) else 0

    # ---- comp 子条目的两个「别从最小变体外推」的维度 ----
    # 这两条不是顶层端口能看出来的，必须去读 comp 段用的 OthersEntry 子模块。
    # 它们各自都有一条精确的等价条件（下面 §结论），矩阵里逐变体列出来以便复核。
    others_all = [(m, c) for m, c in insts.items() if m.startswith("OthersEntry")]
    if others_all:
        comp_mod = max(others_all, key=lambda t: t[1])[0]
        cp, _ = parse_golden(os.path.join(golden, comp_mod + ".sv"))
        d["compMod"] = comp_mod
        # comp 条目是否真有 deqPortIdx 寄存器（等价于 numDeq==2）
        d["comp_deqPortIdxRead"] = 1 if "io_commonOut_deqPortIdxRead" in cp else 0
        # comp 条目入口是否带 srcLoadDependency（等价于 ldDep_pipes>0）
        d["comp_in_ldDep"] = 1 if any(
            k.startswith("io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency")
            for k in cp) else 0
    else:
        d["compMod"], d["comp_deqPortIdxRead"], d["comp_in_ldDep"] = "", -1, -1

    d["nPorts"] = len(P)
    return d



NOTES = """
## 从矩阵读出来的家族结构（三个互斥子族）

按「有没有 IQ 即时唤醒 / 有没有 load 取消」分，14 个变体正好落成三族：

| 子族 | 变体 | 特征 |
|---|---|---|
| INT/MEM（6） | AluBrhJmpI2f…, AluCsrFenceDiv, AluMulBkuBrhJmp, Ldu, StaMou, StdMoud | `nWkIQ=7`、`og0Cancel`、`ldCancel`、`cancelDeqVec`、`exuSources`、`loadDependency` 出口、`useRegCache/regCacheIdx`；**无** og2Resp / vl |
| FP（3） | FaluFcvtF2vFmacFdiv, FaluFmacFdiv, FaluFmac | `nWkIQ=3`、有 og0Cancel、**无** ldCancel / loadDependency / cancelDeqVec / regCache |
| VEC（5） | VfdivVidiv, VfmaVialuFixVfalu, VfmaVialuFixVimac…, VlduVstu, VlduVstuVseglduVsegstu | **无** IQ 唤醒与整套取消网络；有 og2Resp + `vlFromInt/Vf`；后两个另有 vecMem（fromMem/vecLdIn/vecMemIn/status.blocked） |

**已签核的 EntriesVfdivVidiv 是 VEC 族里最小的一个**（10 条目、无 vecMem）；
canary `EntriesAluCsrFenceDiv` 在 INT 族。两者在矩阵里几乎没有重叠的"可选维度"。

## 裁剪任何状态前必须先看的几行

* `og0CancelIdx` / `og1CancelIdx` —— **稀疏全局 exu 下标，不是 0..N-1**。
  Falu* 的 `nWkIQ=3` 但 og0Cancel 只留下标 `8`；Alu* 的 `nWkIQ=7` 留 `0,2,4,6`。
  共享核若按「第 w 路 IQ 唤醒配第 w 个 og0Cancel」连线，对每个变体都是错的。
  → 结论：**下标映射属于变体薄层，核只收一根已经算好的 `cancelSel[w]`。**
* `og1CancelIdx` 在 **14 个变体里全为空** —— Chisel 里 `og1Cancel` 是 `Input(ExuVec())`
  且参与 `CommonInBundle`，但 G1 配置下它一个位都没到达任何输出，firtool 全删。
  不要为它写逻辑。
* `wkIQ_is0LatIdx` —— `is0Lat` 只在部分路上是真信号，其余被折成常量真/假；
  Alu* 是 `0,1`，Ldu/StaMou/StdMoud 是 `0..6`，Falu* 是 `0`。
* `psrc_w` 7（VEC）/ 8（INT/FP）、`nSrcStatus` 1/2/3/5、`nWkWB` 4/6/10/16 ——
  这几个已经是核的参数，不构成新维度。
* `imm_w` 32/15/12/0 —— **有 imm 的变体只有 6 个**，且位宽不同（StaMou 12、
  VfmaVialuFixVimac… 15）。`deqEntry_hasImm` 与 `imm_w>0` 并不等价
  （StdMoud 有 `imm_w=0` 但 `deqEntry_hasImm=0`；VfmaVialuFixVimac… imm_w=15 且露出）。
* `status_blocked` / `vecMem_*` 只有 VlduVstu 两个变体有 —— blocked 在别处恒 0。

## 已确认的「Chisel 读起来是 A、firtool 展开成 B」

1. `wakeUpFromIQ` 在 Chisel 里是 `ValidIO`，golden 顶层**没有 valid 端口**
   （矩阵里 IQ 路数只能按 `bits_pdest` 数）。
2. `EnqEntry` 在 Chisel 里有 `enqDelayIn1` **和** `enqDelayIn2` 两套延迟唤醒输入；
   INT 族走的是 `else` 分支，只用到 enqDelayOut1 —— golden EnqEntry_6 里
   `enqDelayIn2` 整套端口不存在。
3. `og0Resp.bits.resp` 在 Alu* 里没有端口，golden 的 resp 查找表
   （`_GEN_16 = {2'h0, 2'h0, og1Resp_bits_resp, 2'h0}`）把 timer=0 的 resp 钉成
   `2'b00`=BLOCK。timer=1 才是真 resp。
4. `og1Cancel` 见上，全家族皆空。

## 已发现的「拿 VfdivVidiv 推出来会错」的两条

这两条是共享核现在的写法，对 canary 是错的 —— 正是字段矩阵要防的那类错：

* **comp 条目的 `deqPortIdx` 寄存器**。核现在按 `KEEP_WIDE`（= 有 transEntry 出口）
  决定生不生成，依据是"VfdivVidiv 的 comp 条目没有这个寄存器"。
  实测 14/14 的真实条件是 **`numDeq == 2`**（列 `comp_deqPortIdxRead`）：
  VfdivVidiv `numDeq=1` 才被折成常量 0；canary `numDeq=2`，golden `OthersEntry_72`
  **有** `io_commonOut_deqPortIdxRead`。
* **comp 条目入口的 `srcLoadDependency`**。核现在把 comp 段的 `x_ld_dep` 钉 0，
  依据是"golden 的 comp 条目入口不带这些位"。实测 14/14 的真实条件是
  **`ldDep_pipes > 0`**（列 `comp_in_ldDep`）：canary 的 `OthersEntry_72`
  **带**这些位；VfdivVidiv 那边是整条通路死了才被 DCE，不是家族不变量。

这两条等价关系由 `gen_matrix.py --check` 直接断言 —— 哪天新变体破了它，
闸会先红，而不是等 FM 去发现核里那两处 `generate` 条件写错了。
"""

COLS = None


def build(golden):
    global COLS
    rows = []
    files = sorted(f for f in os.listdir(golden)
                   if f.startswith("Entries") and f.endswith(".sv"))
    for f in files:
        ports, insts = parse_golden(os.path.join(golden, f))
        rows.append(probe(f[:-3], ports, insts, golden))
    COLS = list(rows[0].keys())
    return rows


def to_tsv(rows):
    out = ["\t".join(COLS)]
    for r in rows:
        out.append("\t".join(str(r[c]) for c in COLS))
    return "\n".join(out) + "\n"


def to_md(rows, golden):
    """人读版：转置成「字段 × 变体」，因为字段多、变体少，转置更好读。"""
    short = [r["variant"].replace("Entries", "") for r in rows]
    # 变体名太长，用编号 + 图例
    L = []
    L.append("# Entries* 家族 字段使用矩阵（从 golden 实测）\n")
    L.append(f"golden: `{golden}`\n")
    L.append("由 `verif/ut/Entries_field_matrix/gen_matrix.py` 生成，"
             "改动共享核前必须复跑并核对（`--check`）。\n")
    L.append("## 变体编号\n")
    for i, s in enumerate(short):
        L.append(f"- V{i:02d} = `Entries{s}`")
    L.append("")
    L.append("## 矩阵（行 = 字段维度，列 = 变体）\n")
    hdr = "| 字段维度 | " + " | ".join(f"V{i:02d}" for i in range(len(rows))) + " |"
    L.append(hdr)
    L.append("|" + "---|" * (len(rows) + 1))
    for c in COLS:
        if c == "variant":
            continue
        vals = [str(r[c]) for r in rows]
        L.append(f"| `{c}` | " + " | ".join(vals) + " |")
    L.append("")
    L.append(NOTES)
    return "\n".join(L) + "\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--golden", default=DEFAULT_GOLDEN)
    ap.add_argument("--check", action="store_true",
                    help="与已提交的 matrix.tsv/matrix.md 比对，不一致则非零退出")
    a = ap.parse_args()

    here = os.path.dirname(os.path.abspath(__file__))
    rows = build(a.golden)

    # 矩阵自检：下面两条等价关系是共享核里两处 generate 条件的依据。
    # 如果哪天某个变体破了它，核里那两处就必须改 —— 所以让矩阵直接守住。
    for r in rows:
        assert r["comp_deqPortIdxRead"] == int(r["numDeq"] == 2), (
            f'{r["variant"]}: comp 的 deqPortIdx 寄存器与 numDeq==2 不再等价')
        assert r["comp_in_ldDep"] == int(r["ldDep_pipes"] > 0), (
            f'{r["variant"]}: comp 入口的 srcLoadDependency 与 ldDep_pipes>0 不再等价')
    tsv, md = to_tsv(rows), to_md(rows, a.golden)

    ok = True
    for fn, content in (("matrix.tsv", tsv), ("matrix.md", md)):
        p = os.path.join(here, fn)
        if a.check:
            cur = open(p).read() if os.path.exists(p) else ""
            if cur != content:
                sys.stderr.write(f"[FAIL] {fn} 与 golden 实测不一致（重跑 gen_matrix.py）\n")
                ok = False
        else:
            open(p, "w").write(content)
    if a.check:
        print("matrix --check:", "PASS" if ok else "FAIL")
        return 0 if ok else 1
    print(tsv)
    print("sha256(matrix.tsv) =", hashlib.sha256(tsv.encode()).hexdigest())
    return 0


if __name__ == "__main__":
    sys.exit(main())
