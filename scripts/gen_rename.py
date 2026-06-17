#!/usr/bin/env python3
"""
Rename(重命名流水)的 wrapper + UT 生成脚本。

设计意图来自 src/main/scala/xiangshan/backend/rename/Rename.scala (class Rename)。
可读核 rtl/backend/Rename.sv (xs_Rename_core)，把 CompressUnit / MEFreeList /
StdFreeList(×4) / SnapshotGenerator 全部当 golden 黑盒例化。

产出:
  rtl/backend/Rename_wrapper.sv     golden 同名 Rename(扁平 1579 端口 → 核 struct/数组)
  verif/ut/Rename/variants_xs.sv    同一 wrapper 改名 Rename_xs
  verif/ut/Rename/tb.sv             golden vs 手写 双例化逐拍比对(随机激励)

A 批字段(逐拍比对)：psrc_0..4 / pdest / robIdx / *RenamePorts(wen/addr/data) /
  out_valid / in_ready / snapshot / eliminatedMove / hasException / srcType_0 / imm
B 批占位字段(tb 内跳过且注明)：instrSize / dirtyFs / dirtyVs / traceBlockInPipe_* /
  numWB / wfflags / numLsElem / lastUop / debugInfo_renameTime
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
MODULE = "Rename"
HDR = "// 自动生成：scripts/gen_rename.py —— 勿手改\n"

RW = 6   # RenameWidth
CW = 6   # RabCommitWidth

# ---- 直通字段(DynInst 里存在、且 = DecodedInst 同名直传)。位宽由 golden 决定。----
# 这些 out 字段直接来自 io_out_passthru[i].<struct_field>
PASSTHRU = [
    "instr", "isFetchMalAddr", "trigger", "preDecodeInfo_isRVC",
    "pred_taken", "crossPageIPFFix", "ftqPtr_flag", "ftqPtr_value", "ftqOffset",
    "srcType_1", "srcType_2", "srcType_3", "srcType_4",
    "ldest", "fuType", "fuOpType", "rfWen", "fpWen", "vecWen", "v0Wen", "vlWen",
    "isXSTrap", "waitForward", "blockBackward", "flushPipe", "selImm",
    "vlsInstr", "isMove", "uopIdx", "isVset", "firstUop", "commitType",
]
PASSTHRU += [f"exceptionVec_{k}" for k in range(24)]
PASSTHRU += ["fpu_typeTagOut", "fpu_wflags", "fpu_typ", "fpu_fmt", "fpu_rm"]
PASSTHRU += [
    "vpu_vill", "vpu_vma", "vpu_vta", "vpu_vsew", "vpu_vlmul",
    "vpu_specVill", "vpu_specVma", "vpu_specVta", "vpu_specVsew", "vpu_specVlmul",
    "vpu_vm", "vpu_vstart", "vpu_fpu_isFoldTo1_2", "vpu_fpu_isFoldTo1_4",
    "vpu_fpu_isFoldTo1_8", "vpu_vmask", "vpu_nf", "vpu_veew",
    "vpu_isExt", "vpu_isNarrow", "vpu_isDstMask", "vpu_isOpMask",
    "vpu_isDependOldVd", "vpu_isWritePartVd", "vpu_isVleff",
]
# struct 成员名(去掉 _0..23 后缀的 exceptionVec 用整段). 直通映射到 passthru.<member>
PASSTHRU_STRUCT = {f"exceptionVec_{k}": f"exceptionVec[{k}]" for k in range(24)}

# ---- A 批计算字段：映射到核显式输出 ----
def out_map(i):
    m = {}
    for s in range(5):
        m[f"psrc_{s}"] = f"o_psrc[{i}][{s}]"
    m["pdest"]               = f"o_pdest[{i}]"
    m["robIdx_flag"]         = f"o_robIdx_flag[{i}]"
    m["robIdx_value"]        = f"o_robIdx_value[{i}]"
    m["eliminatedMove"]      = f"o_eliminatedMove[{i}]"
    m["snapshot"]            = f"o_snapshot[{i}]"
    m["hasException"]        = f"o_hasException[{i}]"
    m["srcType_0"]           = f"o_srcType0[{i}]"
    m["imm"]                 = f"o_imm[{i}]"
    m["debugInfo_renameTime"]= f"o_renameTime[{i}]"
    # B 批占位
    m["instrSize"]              = f"o_instrSize[{i}]"
    m["dirtyFs"]                = f"o_dirtyFs[{i}]"
    m["dirtyVs"]                = f"o_dirtyVs[{i}]"
    m["traceBlockInPipe_itype"] = f"o_itype[{i}]"
    m["traceBlockInPipe_iretire"]= f"o_iretire[{i}]"
    m["traceBlockInPipe_ilastsize"]= f"o_ilastsize[{i}]"
    m["lastUop"]                = f"o_lastUop[{i}]"
    m["numWB"]                  = f"o_numWB[{i}]"
    m["wfflags"]                = f"o_wfflags[{i}]"
    m["numLsElem"]              = f"o_numLsElem[{i}]"
    return m


def ports(name):
    text = (GOLDEN / f"{name}.sv").read_text()
    m = re.search(rf"^module {re.escape(name)}\((.*?)\n\);", text, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return res


def make_wrapper(ps, modname="Rename"):
    L = [HDR,
         "// golden 同名扁平端口 → 可读核 xs_Rename_core 的机械适配层。",
         "// 1579 端口的拆装全在这里完成；核内只见 struct/数组。",
         f"module {modname}",
         "  import rename_pkg::*;",
         "("]
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else "       "
        kw = "input " if d == "input" else "output"
        decls.append(f"  {kw} {ws}{n}")
    L.append(",\n".join(decls))
    L.append(");")
    L.append("")

    # ---- 中间载体声明 ----
    L += [
        "  decoded_inst_t in_b   [RENAME_WIDTH];",
        "  logic [RENAME_WIDTH-1:0] in_v, in_r, out_v, out_r;",
        "  decoded_inst_t out_pt [RENAME_WIDTH];",
        "  logic [7:0]  o_psrc [RENAME_WIDTH][NUM_SRC];",
        "  logic [7:0]  o_pdest [RENAME_WIDTH];",
        "  logic        o_robIdx_flag [RENAME_WIDTH];",
        "  logic [7:0]  o_robIdx_value [RENAME_WIDTH];",
        "  logic        o_eliminatedMove [RENAME_WIDTH], o_snapshot [RENAME_WIDTH], o_hasException [RENAME_WIDTH];",
        "  logic [3:0]  o_srcType0 [RENAME_WIDTH];",
        "  logic [31:0] o_imm [RENAME_WIDTH];",
        "  logic [63:0] o_renameTime [RENAME_WIDTH];",
        "  logic [2:0]  o_instrSize [RENAME_WIDTH];",
        "  logic        o_dirtyFs [RENAME_WIDTH], o_dirtyVs [RENAME_WIDTH], o_ilastsize [RENAME_WIDTH];",
        "  logic [3:0]  o_itype [RENAME_WIDTH], o_iretire [RENAME_WIDTH];",
        "  logic        o_lastUop [RENAME_WIDTH], o_wfflags [RENAME_WIDTH];",
        "  logic [6:0]  o_numWB [RENAME_WIDTH];",
        "  logic [4:0]  o_numLsElem [RENAME_WIDTH];",
        "  rat_wport_t  intRP [COMMIT_WIDTH], fpRP [COMMIT_WIDTH], vecRP [COMMIT_WIDTH];",
        "  logic        v0RP_wen [COMMIT_WIDTH], vlRP_wen [COMMIT_WIDTH];",
        "  logic [7:0]  v0RP_data [COMMIT_WIDTH], vlRP_data [COMMIT_WIDTH];",
        "  logic [7:0]  intRd [RENAME_WIDTH][2], fpRd [RENAME_WIDTH][3], vecRd [RENAME_WIDTH][3];",
        "  logic [7:0]  v0Rd [RENAME_WIDTH], vlRd [RENAME_WIDTH];",
        "  logic [7:0]  int_oldpd [COMMIT_WIDTH], fp_oldpd [COMMIT_WIDTH], vec_oldpd [COMMIT_WIDTH], v0_oldpd [COMMIT_WIDTH], vl_oldpd [COMMIT_WIDTH];",
        "  logic [5:0]  sr_in [RENAME_WIDTH], sr_out [RENAME_WIDTH];",
        "  logic [5:0]  perf_v [30];",
        "  logic        sr_bv; logic [5:0] sr_bb;",
        "  logic [3:0]  flushv;",
        "  logic [COMMIT_WIDTH-1:0] rab_cv, rab_wv, rab_rf, rab_fp, rab_vec, rab_v0, rab_vl, rab_mv, int_nf;",
        "  logic [RENAME_WIDTH-1:0] fi_r1, fi_r2, fi_z;",
        "",
    ]

    # ---- 输入打平 → struct ----
    A = L.append
    # decoded_inst_t per port: assemble from flat io_in_N_bits_*
    for i in range(RW):
        A(f"  // ---- io_in_{i} → in_b[{i}] ----")
        A(f"  assign in_v[{i}] = io_in_{i}_valid;")
        A(f"  assign io_in_{i}_ready = in_r[{i}];")
        A(f"  assign in_b[{i}].instr = io_in_{i}_bits_instr;")
        A(f"  assign in_b[{i}].exceptionVec = {{" +
          ", ".join(f"io_in_{i}_bits_exceptionVec_{k}" for k in range(23, -1, -1)) + "};")
        for f in ["isFetchMalAddr","trigger","preDecodeInfo_isRVC","preDecodeInfo_brType",
                  "pred_taken","crossPageIPFFix","ftqPtr_flag","ftqPtr_value","ftqOffset"]:
            A(f"  assign in_b[{i}].{f} = io_in_{i}_bits_{f};")
        for s in range(5):
            A(f"  assign in_b[{i}].srcType[{s}] = io_in_{i}_bits_srcType_{s};")
        # port 0 仅有 lsrc_0/lsrc_1(golden 优化掉了 lsrc_2..4)；其余口有全部 5 个
        A(f"  assign in_b[{i}].lsrc[0] = io_in_{i}_bits_lsrc_0;")
        A(f"  assign in_b[{i}].lsrc[1] = io_in_{i}_bits_lsrc_1;")
        if i == 0:
            A(f"  assign in_b[{i}].lsrc[2] = '0; assign in_b[{i}].lsrc[3] = '0; assign in_b[{i}].lsrc[4] = '0;")
        else:
            A(f"  assign in_b[{i}].lsrc[2] = io_in_{i}_bits_lsrc_2;")
            A(f"  assign in_b[{i}].lsrc[3] = io_in_{i}_bits_lsrc_3;")
            A(f"  assign in_b[{i}].lsrc[4] = io_in_{i}_bits_lsrc_4;")
        for f in ["ldest","fuType","fuOpType","rfWen","fpWen","vecWen","v0Wen","vlWen",
                  "isXSTrap","waitForward","blockBackward","flushPipe","canRobCompress",
                  "selImm","imm","fpu_typeTagOut","fpu_wflags","fpu_typ","fpu_fmt","fpu_rm",
                  "vpu_vill","vpu_vma","vpu_vta","vpu_vsew","vpu_vlmul","vpu_specVill",
                  "vpu_specVma","vpu_specVta","vpu_specVsew","vpu_specVlmul","vpu_vm",
                  "vpu_vstart","vpu_fpu_isFoldTo1_2","vpu_fpu_isFoldTo1_4","vpu_fpu_isFoldTo1_8",
                  "vpu_vmask","vpu_nf","vpu_veew","vpu_isExt","vpu_isNarrow","vpu_isDstMask",
                  "vpu_isOpMask","vpu_isDependOldVd","vpu_isWritePartVd","vpu_isVleff",
                  "vlsInstr","wfflags","isMove","uopIdx","uopSplitType","isVset",
                  "firstUop","lastUop","numWB","commitType"]:
            A(f"  assign in_b[{i}].{f} = io_in_{i}_bits_{f};")
        A("")

    # ---- redirect / rabCommits / fusion / snpt / readPorts / oldpd / stallReason ----
    A("  // ---- 标量/向量打平 ----")
    for i in range(CW):
        A(f"  assign rab_cv[{i}] = io_rabCommits_commitValid_{i};")
        A(f"  assign rab_wv[{i}] = io_rabCommits_walkValid_{i};")
        A(f"  assign rab_rf[{i}] = io_rabCommits_info_{i}_rfWen;")
        A(f"  assign rab_fp[{i}] = io_rabCommits_info_{i}_fpWen;")
        A(f"  assign rab_vec[{i}] = io_rabCommits_info_{i}_vecWen;")
        A(f"  assign rab_v0[{i}] = io_rabCommits_info_{i}_v0Wen;")
        A(f"  assign rab_vl[{i}] = io_rabCommits_info_{i}_vlWen;")
        A(f"  assign rab_mv[{i}] = io_rabCommits_info_{i}_isMove;")
        A(f"  assign int_nf[{i}] = io_int_need_free_{i};")
    for i in range(RW):
        A(f"  assign fi_r1[{i}] = io_fusionInfo_{i}_rs2FromRs1;" if i < RW-1 else f"  assign fi_r1[{i}] = 1'b0;")
        A(f"  assign fi_r2[{i}] = io_fusionInfo_{i}_rs2FromRs2;" if i < RW-1 else f"  assign fi_r2[{i}] = 1'b0;")
        A(f"  assign fi_z[{i}]  = io_fusionInfo_{i}_rs2FromZero;" if i < RW-1 else f"  assign fi_z[{i}]  = 1'b0;")
    for i in range(RW):
        A(f"  assign intRd[{i}][0]=io_intReadPorts_{i}_0; assign intRd[{i}][1]=io_intReadPorts_{i}_1;")
        A(f"  assign fpRd[{i}][0]=io_fpReadPorts_{i}_0; assign fpRd[{i}][1]=io_fpReadPorts_{i}_1; assign fpRd[{i}][2]=io_fpReadPorts_{i}_2;")
        A(f"  assign vecRd[{i}][0]=io_vecReadPorts_{i}_0; assign vecRd[{i}][1]=io_vecReadPorts_{i}_1; assign vecRd[{i}][2]=io_vecReadPorts_{i}_2;")
        A(f"  assign v0Rd[{i}]=io_v0ReadPorts_{i}_0; assign vlRd[{i}]=io_vlReadPorts_{i}_0;")
    for i in range(CW):
        A(f"  assign int_oldpd[{i}]=io_int_old_pdest_{i}; assign fp_oldpd[{i}]=io_fp_old_pdest_{i};")
        A(f"  assign vec_oldpd[{i}]=io_vec_old_pdest_{i}; assign v0_oldpd[{i}]=io_v0_old_pdest_{i}; assign vl_oldpd[{i}]=io_vl_old_pdest_{i};")
    for i in range(RW):
        A(f"  assign sr_in[{i}] = io_stallReason_in_reason_{i};")
        A(f"  assign io_stallReason_out_reason_{i} = sr_out[{i}];")
    A("  assign flushv = {io_snpt_flushVec_3, io_snpt_flushVec_2, io_snpt_flushVec_1, io_snpt_flushVec_0};")
    A("  assign out_r = {io_out_5_ready, io_out_4_ready, io_out_3_ready, io_out_2_ready, io_out_1_ready, io_out_0_ready};")
    A("")

    # ---- 输出重组 ----
    A("  // ---- 输出重组：85 直通(out_pt) + A批计算字段 ----")
    for i in range(RW):
        om = out_map(i)
        A(f"  assign io_out_{i}_valid = out_v[{i}];")
        # passthru fields
        A(f"  assign io_out_{i}_bits_instr = out_pt[{i}].instr;")
        for k in range(24):
            A(f"  assign io_out_{i}_bits_exceptionVec_{k} = out_pt[{i}].exceptionVec[{k}];")
        # other passthru
        for f in ["isFetchMalAddr","trigger","preDecodeInfo_isRVC","pred_taken",
                  "crossPageIPFFix","ftqPtr_flag","ftqPtr_value","ftqOffset",
                  "srcType_1","srcType_2","srcType_3","srcType_4",
                  "ldest","fuType","fuOpType","rfWen","fpWen","vecWen","v0Wen","vlWen",
                  "isXSTrap","waitForward","blockBackward","flushPipe","selImm",
                  "fpu_typeTagOut","fpu_wflags","fpu_typ","fpu_fmt","fpu_rm",
                  "vpu_vill","vpu_vma","vpu_vta","vpu_vsew","vpu_vlmul",
                  "vpu_specVill","vpu_specVma","vpu_specVta","vpu_specVsew","vpu_specVlmul",
                  "vpu_vm","vpu_vstart","vpu_fpu_isFoldTo1_2","vpu_fpu_isFoldTo1_4",
                  "vpu_fpu_isFoldTo1_8","vpu_vmask","vpu_nf","vpu_veew","vpu_isExt",
                  "vpu_isNarrow","vpu_isDstMask","vpu_isOpMask","vpu_isDependOldVd",
                  "vpu_isWritePartVd","vpu_isVleff","vlsInstr","isMove","uopIdx",
                  "isVset","firstUop","commitType"]:
            # struct member name: srcType_N -> srcType[N]
            mem = f
            sm = re.match(r"srcType_(\d)", f)
            if sm:
                mem = f"srcType[{sm.group(1)}]"
            A(f"  assign io_out_{i}_bits_{f} = out_pt[{i}].{mem};")
        # computed/A-batch + B-batch placeholders
        A(f"  assign io_out_{i}_bits_psrc_0 = {om['psrc_0']};")
        A(f"  assign io_out_{i}_bits_psrc_1 = {om['psrc_1']};")
        A(f"  assign io_out_{i}_bits_psrc_2 = {om['psrc_2']};")
        A(f"  assign io_out_{i}_bits_psrc_3 = {om['psrc_3']};")
        A(f"  assign io_out_{i}_bits_psrc_4 = {om['psrc_4']};")
        A(f"  assign io_out_{i}_bits_pdest = {om['pdest']};")
        A(f"  assign io_out_{i}_bits_robIdx_flag = {om['robIdx_flag']};")
        A(f"  assign io_out_{i}_bits_robIdx_value = {om['robIdx_value']};")
        A(f"  assign io_out_{i}_bits_eliminatedMove = {om['eliminatedMove']};")
        A(f"  assign io_out_{i}_bits_snapshot = {om['snapshot']};")
        A(f"  assign io_out_{i}_bits_hasException = {om['hasException']};")
        A(f"  assign io_out_{i}_bits_srcType_0 = {om['srcType_0']};")
        A(f"  assign io_out_{i}_bits_imm = {om['imm']};")
        A(f"  assign io_out_{i}_bits_debugInfo_renameTime = {om['debugInfo_renameTime']};")
        A(f"  assign io_out_{i}_bits_instrSize = {om['instrSize']};")
        A(f"  assign io_out_{i}_bits_dirtyFs = {om['dirtyFs']};")
        A(f"  assign io_out_{i}_bits_dirtyVs = {om['dirtyVs']};")
        A(f"  assign io_out_{i}_bits_traceBlockInPipe_itype = {om['traceBlockInPipe_itype']};")
        A(f"  assign io_out_{i}_bits_traceBlockInPipe_iretire = {om['traceBlockInPipe_iretire']};")
        A(f"  assign io_out_{i}_bits_traceBlockInPipe_ilastsize = {om['traceBlockInPipe_ilastsize']};")
        A(f"  assign io_out_{i}_bits_lastUop = {om['lastUop']};")
        A(f"  assign io_out_{i}_bits_numWB = {om['numWB']};")
        A(f"  assign io_out_{i}_bits_wfflags = {om['wfflags']};")
        A(f"  assign io_out_{i}_bits_numLsElem = {om['numLsElem']};")
    # RAT write ports out
    for i in range(CW):
        A(f"  assign io_intRenamePorts_{i}_wen = intRP[{i}].wen; assign io_intRenamePorts_{i}_addr = intRP[{i}].addr[4:0]; assign io_intRenamePorts_{i}_data = intRP[{i}].data;")
        A(f"  assign io_fpRenamePorts_{i}_wen = fpRP[{i}].wen; assign io_fpRenamePorts_{i}_addr = fpRP[{i}].addr; assign io_fpRenamePorts_{i}_data = fpRP[{i}].data;")
        A(f"  assign io_vecRenamePorts_{i}_wen = vecRP[{i}].wen; assign io_vecRenamePorts_{i}_addr = vecRP[{i}].addr; assign io_vecRenamePorts_{i}_data = vecRP[{i}].data;")
        A(f"  assign io_v0RenamePorts_{i}_wen = v0RP_wen[{i}]; assign io_v0RenamePorts_{i}_data = v0RP_data[{i}];")
        A(f"  assign io_vlRenamePorts_{i}_wen = vlRP_wen[{i}]; assign io_vlRenamePorts_{i}_data = vlRP_data[{i}];")
    A("  assign io_stallReason_in_backReason_valid = sr_bv;")
    A("  assign io_stallReason_in_backReason_bits  = sr_bb;")
    for p in range(30):
        A(f"  assign io_perf_{p}_value = perf_v[{p}];")
    A("")

    # ---- core instance ----
    A("  xs_Rename_core u_core (")
    A("    .clock(clock), .reset(reset),")
    A("    .io_redirect_valid(io_redirect_valid),")
    A("    .io_redirect_bits_robIdx_flag(io_redirect_bits_robIdx_flag),")
    A("    .io_redirect_bits_robIdx_value(io_redirect_bits_robIdx_value),")
    A("    .io_redirect_bits_level(io_redirect_bits_level),")
    A("    .io_rabCommits_isCommit(io_rabCommits_isCommit), .io_rabCommits_isWalk(io_rabCommits_isWalk),")
    A("    .io_rabCommits_commitValid(rab_cv), .io_rabCommits_walkValid(rab_wv),")
    A("    .io_rabCommits_info_rfWen(rab_rf), .io_rabCommits_info_fpWen(rab_fp),")
    A("    .io_rabCommits_info_vecWen(rab_vec), .io_rabCommits_info_v0Wen(rab_v0),")
    A("    .io_rabCommits_info_vlWen(rab_vl), .io_rabCommits_info_isMove(rab_mv),")
    A("    .io_singleStep(io_singleStep),")
    A("    .io_in_bits(in_b), .io_in_valid(in_v), .io_in_ready(in_r),")
    A("    .io_fusionInfo_rs2FromRs1(fi_r1), .io_fusionInfo_rs2FromRs2(fi_r2), .io_fusionInfo_rs2FromZero(fi_z),")
    A("    .io_intReadPorts(intRd), .io_fpReadPorts(fpRd), .io_vecReadPorts(vecRd),")
    A("    .io_v0ReadPorts(v0Rd), .io_vlReadPorts(vlRd),")
    A("    .io_intRenamePorts(intRP), .io_fpRenamePorts(fpRP), .io_vecRenamePorts(vecRP),")
    A("    .io_v0RenamePorts_wen(v0RP_wen), .io_v0RenamePorts_data(v0RP_data),")
    A("    .io_vlRenamePorts_wen(vlRP_wen), .io_vlRenamePorts_data(vlRP_data),")
    A("    .io_int_old_pdest(int_oldpd), .io_fp_old_pdest(fp_oldpd), .io_vec_old_pdest(vec_oldpd),")
    A("    .io_v0_old_pdest(v0_oldpd), .io_vl_old_pdest(vl_oldpd), .io_int_need_free(int_nf),")
    A("    .io_out_valid(out_v), .io_out_ready(out_r), .io_out_passthru(out_pt),")
    A("    .io_out_psrc(o_psrc), .io_out_pdest(o_pdest),")
    A("    .io_out_robIdx_flag(o_robIdx_flag), .io_out_robIdx_value(o_robIdx_value),")
    A("    .io_out_eliminatedMove(o_eliminatedMove), .io_out_snapshot(o_snapshot),")
    A("    .io_out_hasException(o_hasException), .io_out_srcType0(o_srcType0),")
    A("    .io_out_imm(o_imm), .io_out_debugInfo_renameTime(o_renameTime),")
    A("    .io_out_instrSize(o_instrSize), .io_out_dirtyFs(o_dirtyFs), .io_out_dirtyVs(o_dirtyVs),")
    A("    .io_out_itype(o_itype), .io_out_iretire(o_iretire), .io_out_ilastsize(o_ilastsize),")
    A("    .io_out_lastUop_o(o_lastUop), .io_out_numWB(o_numWB), .io_out_wfflags_o(o_wfflags),")
    A("    .io_out_numLsElem(o_numLsElem),")
    A("    .io_snpt_snptDeq(io_snpt_snptDeq), .io_snpt_useSnpt(io_snpt_useSnpt),")
    A("    .io_snpt_snptSelect(io_snpt_snptSelect), .io_snpt_flushVec(flushv),")
    A("    .io_snptLastEnq_valid(io_snptLastEnq_valid), .io_snptLastEnq_bits_flag(io_snptLastEnq_bits_flag),")
    A("    .io_snptLastEnq_bits_value(io_snptLastEnq_bits_value), .io_snptIsFull(io_snptIsFull),")
    A("    .io_stallReason_in_reason(sr_in), .io_stallReason_out_backReason_valid(io_stallReason_out_backReason_valid),")
    A("    .io_stallReason_in_backReason_valid(sr_bv), .io_stallReason_in_backReason_bits(sr_bb),")
    A("    .io_stallReason_out_reason(sr_out), .io_perf_value(perf_v)")
    A("  );")
    A("endmodule")
    return "\n".join(L)


# =====================================================================
#  Testbench
# =====================================================================
# 逐拍比对的输出端口(精确匹配 io_out_N_bits_<x>)
#   A 批：psrc/pdest/robIdx/eliminatedMove/snapshot/hasException/srcType_0/imm
#   B 批(本批补完)：instrSize/dirtyFs/dirtyVs/traceBlockInPipe_*/lastUop/numWB/
#     wfflags/numLsElem —— 全部纳入逐拍比对。
#   仅 debugInfo_renameTime 仍跳过(自由计数器, don't-care)。
ABATCH_OUT_SUFFIX = [
    "psrc_0","psrc_1","psrc_2","psrc_3","psrc_4","pdest",
    "robIdx_flag","robIdx_value","eliminatedMove","snapshot","hasException",
    "srcType_0","imm",
    # ---- B 批字段(本批补完, 纳入逐拍比对) ----
    "instrSize","dirtyFs","dirtyVs",
    "traceBlockInPipe_itype","traceBlockInPipe_iretire","traceBlockInPipe_ilastsize",
    "lastUop","numWB","wfflags","numLsElem",
]
# A 批也比对的非 io_out 输出口(前缀匹配)
ABATCH_OTHER_PREFIX = [
    "io_intRenamePorts_","io_fpRenamePorts_","io_vecRenamePorts_",
    "io_v0RenamePorts_","io_vlRenamePorts_","io_in_", "io_out_0_valid",
    "io_out_1_valid","io_out_2_valid","io_out_3_valid","io_out_4_valid","io_out_5_valid",
]
# B 批/不可判：跳过(子串)
SKIP_SUFFIX = [
    "instrSize","dirtyFs","dirtyVs","traceBlockInPipe","numWB","wfflags",
    "numLsElem","lastUop","debugInfo_renameTime",
    # 直通字段不必比(都来自输入)，但比也无害；这里只比 A批+RenamePorts，省时
]


def is_abatch_out(name):
    if not name.startswith("io_"):
        return False
    # in_ready
    if re.match(r"io_in_\d+_ready$", name):
        return True
    if re.match(r"io_out_\d+_valid$", name):
        return True
    for p in ("io_intRenamePorts_","io_fpRenamePorts_","io_vecRenamePorts_",
              "io_v0RenamePorts_","io_vlRenamePorts_"):
        if name.startswith(p):
            return True
    m = re.match(r"io_out_\d+_bits_(.+)$", name)
    if m:
        return m.group(1) in ABATCH_OUT_SUFFIX
    return False


def make_stim(ins):
    """随机激励：valid/wen 随机；寄存器号窄域(增加旁路命中率)；redirect/walk 稀疏。"""
    L = ["  function automatic logic [5:0] rl(); return 6'($urandom_range(0,8)); endfunction",
         "  function automatic logic [7:0] rp(); return 8'($urandom_range(0,40)); endfunction",
         "  function automatic logic [3:0] rst4(); ",
         "    int x; x=$urandom_range(0,6); ",
         "    case(x) 0:return 4'h0; 1:return 4'h1; 2:return 4'h2; 3:return 4'h4; 4:return 4'h8; default: return 4'h1; endcase",
         "  endfunction",
         "  always @(negedge clk) begin",
         "    if (rst) begin"]
    for w, n in ins:
        L.append(f"      {n} <= 0;")
    L.append("    end else begin")
    L.append("      io_redirect_valid <= ($urandom_range(0,99)<3);")
    L.append("      io_redirect_bits_robIdx_value <= $urandom_range(0,159);")
    L.append("      io_redirect_bits_robIdx_flag <= $urandom_range(0,1);")
    L.append("      io_redirect_bits_level <= $urandom_range(0,1);")
    L.append("      io_rabCommits_isCommit <= $urandom_range(0,1);")
    L.append("      io_rabCommits_isWalk <= ($urandom_range(0,99)<10);")
    L.append("      io_singleStep <= ($urandom_range(0,99)<5);")
    L.append("      io_snptIsFull <= $urandom_range(0,1);")
    L.append("      io_snptLastEnq_valid <= $urandom_range(0,1);")
    L.append("      io_snptLastEnq_bits_value <= $urandom_range(0,159);")
    L.append("      io_snpt_useSnpt <= $urandom_range(0,1);")
    L.append("      io_snpt_snptDeq <= $urandom_range(0,1);")
    L.append("      io_snpt_snptSelect <= $urandom_range(0,3);")
    for k in range(4):
        L.append(f"      io_snpt_flushVec_{k} <= ($urandom_range(0,99)<5);")
    for i in range(CW):
        for f in ["commitValid","walkValid"]:
            L.append(f"      io_rabCommits_{f}_{i} <= $urandom_range(0,1);")
        for f in ["rfWen","fpWen","vecWen","v0Wen","vlWen","isMove"]:
            L.append(f"      io_rabCommits_info_{i}_{f} <= $urandom_range(0,1);")
        L.append(f"      io_int_need_free_{i} <= $urandom_range(0,1);")
        L.append(f"      io_int_old_pdest_{i} <= rp(); io_fp_old_pdest_{i} <= rp();")
        L.append(f"      io_vec_old_pdest_{i} <= rp(); io_v0_old_pdest_{i} <= rp(); io_vl_old_pdest_{i} <= rp();")
    for i in range(RW):
        L.append(f"      io_in_{i}_valid <= ($urandom_range(0,99)<80);")
        L.append(f"      io_out_{i}_ready <= ($urandom_range(0,99)<85);")
        L.append(f"      io_in_{i}_bits_instr <= $urandom;")
        L.append(f"      io_in_{i}_bits_ldest <= rl();")
        L.append(f"      io_in_{i}_bits_lsrc_0 <= rl(); io_in_{i}_bits_lsrc_1 <= rl();")
        if i > 0:
            L.append(f"      io_in_{i}_bits_lsrc_2 <= rl(); io_in_{i}_bits_lsrc_3 <= rl(); io_in_{i}_bits_lsrc_4 <= rl();")
        for s in range(5):
            L.append(f"      io_in_{i}_bits_srcType_{s} <= rst4();")
        for f in ["rfWen","fpWen","vecWen","v0Wen","vlWen","isMove","lastUop",
                  "firstUop","canRobCompress","vlsInstr","wfflags","isVset","isXSTrap",
                  "waitForward","blockBackward","flushPipe","preDecodeInfo_isRVC",
                  "pred_taken","crossPageIPFFix","isFetchMalAddr","vpu_isVleff"]:
            L.append(f"      io_in_{i}_bits_{f} <= $urandom_range(0,1);")
        # fuType：偏置覆盖 A 批特例(alu/load/fence/jmp)与 B 批向量访存/向量算术(脏标志/流数)。
        #   向量访存(31..34)驱动 numLsElem；vfalu(24)/vipu(18) 驱动 dirtyVs 特例；csr(5) 驱动 itype Xret。
        L.append(f"      io_in_{i}_bits_fuType <= ($urandom_range(0,99)<25) ? "
                 "(($urandom_range(0,3)==0)?35'h40:($urandom_range(0,2)==0)?35'h8000:($urandom_range(0,1)==0)?35'h200:35'h1) "
                 ": ($urandom_range(0,99)<30) ? "
                 "((35'h1)<<($urandom_range(0,4)==0?31:$urandom_range(0,3)==0?32:$urandom_range(0,2)==0?33:$urandom_range(0,1)==0?34:24)) "
                 ": ($urandom_range(0,99)<15) ? ((35'h1)<<($urandom_range(0,1)==0?18:5)) : $urandom_range(0,40);")
        # fuOpType：9bit；偏置低位 mop/whole/masked 组合以覆盖 emul/instType 分支。
        L.append(f"      io_in_{i}_bits_fuOpType <= $urandom_range(0,511);")
        # vpu 向量配置：nf/veew/vsew/vlmul 直接影响 emul 与 MulDataSize>>eew。
        L.append(f"      io_in_{i}_bits_vpu_nf <= $urandom_range(0,7);")
        L.append(f"      io_in_{i}_bits_vpu_veew <= $urandom_range(0,3);")
        L.append(f"      io_in_{i}_bits_vpu_vsew <= $urandom_range(0,3);")
        L.append(f"      io_in_{i}_bits_vpu_vlmul <= $urandom_range(0,7);")
        # uopSplitType：6bit；0=SCA_SIM(标量)，偏置覆盖向量/AMOCAS(0x35..0x37)。
        L.append(f"      io_in_{i}_bits_uopSplitType <= ($urandom_range(0,99)<20) ? 6'h0 : "
                 "($urandom_range(0,99)<15) ? (6'h35+$urandom_range(0,2)) : $urandom_range(0,63);")
        L.append(f"      io_in_{i}_bits_numWB <= $urandom_range(0,127);")
        L.append(f"      io_in_{i}_bits_selImm <= rst4();")
        L.append(f"      io_in_{i}_bits_imm <= $urandom;")
        L.append(f"      io_in_{i}_bits_commitType <= $urandom_range(0,7);")
        L.append(f"      io_in_{i}_bits_trigger <= $urandom_range(0,3);")
        L.append(f"      io_in_{i}_bits_preDecodeInfo_brType <= $urandom_range(0,3);")
        for k in range(24):
            L.append(f"      io_in_{i}_bits_exceptionVec_{k} <= ($urandom_range(0,99)<4);")
        for s in range(2):
            L.append(f"      io_intReadPorts_{i}_{s} <= rp();")
        for s in range(3):
            L.append(f"      io_fpReadPorts_{i}_{s} <= rp(); io_vecReadPorts_{i}_{s} <= rp();")
        L.append(f"      io_v0ReadPorts_{i}_0 <= rp(); io_vlReadPorts_{i}_0 <= rp();")
        if i < RW-1:
            L.append(f"      io_fusionInfo_{i}_rs2FromRs1 <= ($urandom_range(0,99)<8);")
            L.append(f"      io_fusionInfo_{i}_rs2FromRs2 <= ($urandom_range(0,99)<8);")
            L.append(f"      io_fusionInfo_{i}_rs2FromZero <= ($urandom_range(0,99)<8);")
    L.append("    end")
    L.append("  end")
    return "\n".join(L)


def make_tb(ps):
    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]

    def decl(w, n, p=""):
        ws = f"[{w-1}:0] " if w > 1 else ""
        return f"  logic {ws}{p}{n};"

    L = [HDR, "`timescale 1ns/1ps", "module tb;",
         "  int unsigned NCYCLES = 200000;",
         "  bit clk = 0, rst;",
         "  int errors = 0, checks = 0;",
         "  always #5 clk = ~clk;", ""]
    for w, n in ins:
        L.append(decl(w, n))
    for w, n in outs:
        L.append(decl(w, n, "g_"))
        L.append(decl(w, n, "i_"))
    L.append("")

    def inst(mod, pre):
        c = [".clock(clk)", ".reset(rst)"]
        c += [f".{n}({n})" for _, n in ins]
        c += [f".{n}({pre}{n})" for _, n in outs]
        return f"  {mod} {pre[0]}_u (" + ", ".join(c) + ");"

    L.append(inst(MODULE, "g_"))
    L.append(inst(MODULE + "_xs", "i_"))
    L.append("")
    L.append(make_stim(ins))
    L.append("  // A 批字段逐拍比对(B 批/不可判端口跳过)；!$isunknown 跳 don't-care。")
    L.append("  always @(negedge clk) if (!rst) begin")
    L.append("    #4; checks++;")
    for w, n in outs:
        if is_abatch_out(n):
            L.append(f"    if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
            L.append(f"      if(errors<=120) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
    # 内部状态层次探针：robIdxHead + 五个 FreeList 的 headPtr。仅在 golden 非 X 时比。
    L.append("    // 内部状态层次探针(robIdxHead / FreeList headPtr)")
    L.append("    if (!$isunknown(g_u.robIdxHead_value) && g_u.robIdxHead_value !== i_u.u_core.robIdxHead_value) begin errors++;")
    L.append("      if(errors<=120) $display(\"[%0t] PROBE robIdxHead_value g=%h i=%h\", $time, g_u.robIdxHead_value, i_u.u_core.robIdxHead_value); end")
    L.append("    if (!$isunknown(g_u.intFreeList.headPtrOH) && g_u.intFreeList.headPtrOH !== i_u.u_core.intFreeList.headPtrOH) begin errors++;")
    L.append("      if(errors<=120) $display(\"[%0t] PROBE intFL.headPtrOH mismatch\", $time); end")
    L.append("    if (!$isunknown(g_u.fpFreeList.headPtrOH) && g_u.fpFreeList.headPtrOH !== i_u.u_core.fpFreeList.headPtrOH) begin errors++;")
    L.append("      if(errors<=120) $display(\"[%0t] PROBE fpFL.headPtrOH mismatch\", $time); end")
    L.append("  end")
    L.append(EPILOG)
    L.append("endmodule")
    return "\n".join(L)


EPILOG = r"""  initial begin
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end"""


def main():
    ps = ports(MODULE)
    (XSSV / "rtl/backend/Rename_wrapper.sv").write_text(make_wrapper(ps, "Rename"))
    ut = XSSV / f"verif/ut/{MODULE}"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(make_wrapper(ps, "Rename_xs"))
    (ut / "tb.sv").write_text(make_tb(ps))
    print("generated wrapper + ut for", MODULE)


if __name__ == "__main__":
    main()
