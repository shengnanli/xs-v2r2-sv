#!/usr/bin/env python3
"""
NewCSR 第7轮 步9: 可读性重映射。
把 golden 展平的 _T_/_GEN_ 网名原子重命名为语义名，三文件同步：
  rtl/backend/NewCSR.sv  +  newcsr_decls.svh  +  newcsr_inst.svh

映射来源（全部从 NewCSR.sv 自身的真值推导，保证可信）：
  * _noCSRIllegal_T_<n>  -> addrHit_<csr>
      csr 名优先用 assign 行的 // 注释；否则用读出路由
      (_T ? _<csr>_regOut_ALL/_rdata) 反推；个别只参与合法性检查的
      用 RISC-V 地址表补。
  * _imsicAddrPrivState_T*  -> addrHit_mireg / addrHit_sireg / addrHit_vsireg
      + toAIA_v (T_18 是 AIA 间接访问 v 标志)
  * _GEN_0..7   -> pmpCfgWdataByte_<i>
    _GEN_8..15  -> pmaCfgWdataByte_<i>
    _GEN_20     -> hgeipVgeinShamt
  * _<csr>_w_wen_T_*           -> <csr>_wen
    _<csr>_wAlias<X>_wen_T_*   -> <csr>_wAlias<X>_wen
  * _platformIRPVseipChange_T_*-> hgeipForVseip_<n>
  * 其余少数 -> 按逻辑语义名
纯改名、等价不变；UT/FM 必须维持。
"""
import re, sys
from pathlib import Path

RTL = Path(__file__).resolve().parent.parent / "rtl/backend"
SV    = RTL / "NewCSR.sv"
DECLS = RTL / "newcsr_decls.svh"
INST  = RTL / "newcsr_inst.svh"

sv = SV.read_text()

# RISC-V 地址表：仅给「无注释 + 无读出路由」的少数地址补名
ADDR_FALLBACK = {
    "12'hC22": "vlenb",
    "12'hEB0": "vstopi",
    "12'hF12": "marchid",
}

mapping = {}  # golden name -> semantic name

# ---- 1) addrHit_<csr> from comment / routing / addr ------------------------
addr_of = {}
for m in re.finditer(r"assign (_noCSRIllegal_T_\d+) = io_in_bits_addr == (12'h[0-9A-Fa-f]+);", sv):
    addr_of[m.group(1)] = m.group(2)
# 同行带声明的形式: logic _noCSRIllegal_T_507; assign ... == 12'hC22;
for m in re.finditer(r"(_noCSRIllegal_T_\d+) = io_in_bits_addr == (12'h[0-9A-Fa-f]+);", sv):
    addr_of.setdefault(m.group(1), m.group(2))

comment_name = {}
for m in re.finditer(r"(_noCSRIllegal_T_\d+) = io_in_bits_addr == 12'h[0-9A-Fa-f]+;\s*//\s*([A-Za-z0-9_]+)", sv):
    comment_name[m.group(1)] = m.group(2)

route_name = {}
for m in re.finditer(r"(_noCSRIllegal_T_\d+) \? _([A-Za-z0-9_]+)_(?:regOut_ALL|rdata)\b", sv):
    route_name.setdefault(m.group(1), m.group(2))

def norm(s):
    # 统一小写首字母 (Mhpmevent3 -> mhpmevent3); pmpcfg_0 等保持
    return s[0].lower() + s[1:] if s else s

all_noill = set(re.findall(r"_noCSRIllegal_T_\d+", sv))
all_noill.discard("_noCSRIllegal_T_529")  # 宽向量, 单独处理
for n in all_noill:
    csr = comment_name.get(n) or route_name.get(n)
    if not csr:
        a = addr_of.get(n)
        csr = ADDR_FALLBACK.get(a)
    if not csr:
        print("WARN: no name for", n, addr_of.get(n)); continue
    mapping[n] = "addrHit_" + norm(csr)

# 宽聚合向量 (&_noCSRIllegal_T_529) = 全部地址合法性 one-hot 集
mapping["_noCSRIllegal_T_529"] = "csrAddrLegalVec"

# ---- 2) imsicAddrPrivState ------------------------------------------------
mapping["_imsicAddrPrivState_T"]    = "addrHit_mireg"
mapping["_imsicAddrPrivState_T_6"]  = "addrHit_sireg"
mapping["_imsicAddrPrivState_T_8"]  = "addrHit_vsireg"
mapping["_imsicAddrPrivState_T_18"] = "toAIA_addr_v"

# ---- 3) _GEN_ -------------------------------------------------------------
for i in range(8):
    mapping[f"_GEN_{i}"] = f"pmpCfgWdataByte_{i}"
for i in range(8, 16):
    mapping[f"_GEN_{i}"] = f"pmaCfgWdataByte_{i-8}"
mapping["_GEN_20"] = "hgeipVgeinShamt"

# ---- 4) write-enable fanout ----------------------------------------------
for m in re.finditer(r"(_([a-z][A-Za-z0-9]*)_w_wen_T_\d+)\b", sv):
    mapping[m.group(1)] = f"{m.group(2)}_wen"
for m in re.finditer(r"(_([a-z][A-Za-z0-9]*)_wAlias([A-Za-z0-9]+)_wen_T_\d+)\b", sv):
    mapping[m.group(1)] = f"{m.group(2)}_wAlias{m.group(3)}_wen"

# ---- 5) platformIRPVseipChange (hgeip>>shamt 取 VSEIP 位) -----------------
for m in re.finditer(r"_platformIRPVseipChange_T_(\d+)\b", sv):
    mapping[f"_platformIRPVseipChange_T_{m.group(1)}"] = f"hgeipForVseip_{m.group(1)}"

# ---- 6) 其余零散（含无数字后缀的 bare _T 名）------------------------------
# mstatus.FS/VS off（送 io_toDecode.illegalInst，浮点/向量关闭→非法指令）
mapping["_io_toDecode_illegalInst_fsIsOff_T"] = "mstatusFsIsOff"
mapping["_io_toDecode_illegalInst_vsIsOff_T"] = "mstatusVsIsOff"
# lcofi（local counter-overflow interrupt）请求 29bit 向量（mhpmevent overflow 聚合）
mapping["_lcofiReq_T"] = "lcofiReqVec"
# tselect 命中第 i 个 trigger（送各 tdata1/tdata2 子模块写使能/读出 mux）
mapping["_tdata2RegVec_0_w_wen_T"] = "triggerSel0Hit"
mapping["_tdata2RegVec_1_w_wen_T"] = "triggerSel1Hit"
mapping["_tdata2RegVec_2_w_wen_T"] = "triggerSel2Hit"
mapping["_diffMhpmeventOverflowEvent_valid_T_145"]              = "diffMhpmeventOverflowVec"
mapping["_diffNonRegInterruptPendingEvent_platformIRPVseip_T_1"] = "diffHgeipForVseip"
mapping["_io_status_instrAddrTransType_sv48x4_T_2"]            = "vsatpModeBare"
mapping["_io_toDecode_illegalInst_fsIsOff_T_2"]               = "vsFsIsOff"
mapping["_io_toDecode_illegalInst_vsIsOff_T_2"]               = "vsVsIsOff"

# ---- 冲突检测 -------------------------------------------------------------
rev = {}
for k, v in mapping.items():
    rev.setdefault(v, []).append(k)
dups = {v: ks for v, ks in rev.items() if len(ks) > 1}
if dups:
    print("FATAL: duplicate target names:")
    for v, ks in dups.items():
        print(" ", v, "<-", ks)
    sys.exit(1)

# 确认没有遗漏 (NewCSR.sv 里所有 _T_/_GEN_ 名都在 map 里)
remaining = set(re.findall(r"_[A-Za-z0-9_]*_T_\d+|_[A-Za-z0-9_]*_T(?![A-Za-z0-9_])|_GEN_\d+", sv))
notmapped = remaining - set(mapping)
if notmapped:
    print("WARN unmapped names:", sorted(notmapped))

print(f"mapping entries: {len(mapping)}")

# ---- 应用：按名字长度降序，词边界替换，三文件同步 -------------------------
def apply(text):
    for k in sorted(mapping, key=len, reverse=True):
        text = re.sub(r"(?<![A-Za-z0-9_])" + re.escape(k) + r"(?![A-Za-z0-9_])",
                      mapping[k], text)
    return text

for p in (SV, DECLS, INST):
    p.write_text(apply(p.read_text()))
    print("rewrote", p.name)
