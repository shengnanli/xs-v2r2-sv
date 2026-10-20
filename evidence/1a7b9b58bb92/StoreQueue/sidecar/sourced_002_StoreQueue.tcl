# vmucp 白名单条目：StoreQueue
#
# 本文件 = StoreQueue 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-09-21，agent/sqcore）----
# 第 7 轮 strict 跑（钉点 60795 条、未开 vmucp）实报：
#     Matching : 60761 by user + 14475 by name + 1735 by signature + 0 by topology
#                0(0) Unmatched reference(implementation) compare points
#                0(0) Unmatched reference(implementation) primary inputs, black-box outputs
#     Verify   : Verification SUCCEEDED
#                passing 76971 / failing 0 / unverified 0 / aborted 0 / blackbox_out 0
#                dont_verify=false / elab147=false
#     verdict  : PARTIAL —— 唯一原因是 unread=41（strict 铁律：任何 unread 判 PARTIAL）
#
# 这 41 点**全部** matched_nc（已配对、未比较），且是严格双射：ref 侧 41 个唯一点
# 对 impl 侧 41 个唯一点，非 matched_nc 项为 0。逐条都是两侧**对称**的死位：
#     golden REG / REG_1              <-> 可读核 mmioStoutFireRegChain{,_1}
#         golden 里这两个只喂
#         assert(!RegNext(RegNext(io.sbuffer(0).fire) && io.mmioStout.fire))
#     golden counter[31:0]            <-> 可读核 timeoutCounter[31:0]
#         只喂 TimeOutAssert(vecExceptionFlag.valid, 3000, ...)
#     golden uncacheUop_fuOpType[8:2] <-> 可读核同名同位
#         cmoOpCode 只取 fuOpType[1:0]，高 7 位两侧都没人读
# 本仓 UT 与 FM 两侧都按 SYNTHESIS 编译，`ifndef SYNTHESIS 的断言块不生成，
# 所以这些位在两侧同样是死的。★份数照 golden 留★：少留一个就会变成 unmatched，
# 多留一个就是凭空加状态 —— 这不是"为了绿"而留，是可读核必须与 golden 同形。
#
# 开 vmucp 之后它们变成真比较点：passing 76971 -> 77012（+41，恰好等于 unread 数），
# 即"确实开了比较、不是空转"。★开 vmucp 不放宽任何判据★：它只把「配上了但没比」
# 改成「配上了并且比了」，比不过一样红；不 dont_verify、不加黑盒、不动别的 appvar。

fm_target_vmucp_allow
