# Rob FM 首跑（修 bug 之前）的报告存档

## 为什么有这个目录

上一条 lane 把这次 FM 跑完了（2.97 小时、正常退出、`Verification FAILED`），
但 `verif/ut/*/fm_work/` 在 `.gitignore:51` 里，**结果一个字节都没进版本库**，
随后那条 lane 被 HTTP 403 打断，报告就再没人看。
本目录把这次跑的小体积报告钉进库，好让后面任何人不用重跑 3 小时就能复核结论。

* run_id `Rob-20260920T162808Z-2486a47b`
* impl commit `2486a47b`（golden = G1-canonical，见 `SHA256SUMS.bigfiles`）
* mode `signoff-strict`、`FM_MERGE_DUP=false`、`verification_failing_point_limit` 取 FM 默认值 20
* 钉点 `ROB_PINS pinned 168720 of 168720`，line-anchored `grep -cE "^ *Error:"` = **0**

## ★这次跑的 failing=20 是截断值，不是真实数量★

Formality 的 `verification_failing_point_limit` 默认 20，撞到第 20 个 matched failing
就停止验证，**剩下的点全部计进 Unverified**。所以

    25 Failing (20 matched, 5 unmatched)    78,881 Unverified

这两个数是同一件事的两面，**不是"七万个地方错了"**。真实失败集合只能用
`FM_FAILING_LIMIT=0` 的诊断跑（`--mode diagnostic-full`）拿到。

## 20 个 matched failing 的聚类（逐条数出来的，不是估的）

| 簇 | 点数 | 根因 | 修在哪个 commit |
|---|---|---|---|
| `robEntries_<0,1,2,3,4,10,11,12,13>_isHls_reg` | 9 | isHls 被写成 `Mux1H(f(x))`，golden 是 `f(Mux1H(x))` | 真 bug 1/4 |
| `io_csr_fflags_next_bits_r_reg[0..4]` | 5 | 按 deqPtr 的越界读默认值写成 0，golden 回绕到条目 0 | 真 bug 2/4 |
| `io_lsq_scommit_REG_reg[0..3]` | 4 | 同上（vls 表） | 真 bug 2/4 |
| `io_csr_vxsat_next_bits_r_reg` + `io_csr_vxsat_next_valid_last_REG_reg` | 2 | 同上（vxsat 表） | 真 bug 2/4 |

★交班时给的聚类是「三簇、isHls 约 11 个」，实测是**四簇、isHls 9 个**★
（vxsat 那两位当时被漏掉了）。9 同样是截断下的数字，不是该族的真实规模。

5 个 unmatched failing 全在 `enqPtrGenModule/io_out_<1..5>_flag`（ref 侧 BBPin，
Impl None），根因与修法见真 bug 3/4。

## Unread（67,689）是**另一个独立问题**，与 failing 无关

`unread_classes.tsv` / `unread_families.tsv` 是从 `unread_points.txt` 机械分类出来的：

| 类 | 点数 | 性质 | 处置 |
|---|---|---|---|
| `matched_nc` | 67,689 | **两侧对称**的死位：`debug_microOp_debugReg_*`（6 个 64 位 debugInfo 时间戳 × 160 条目 = 61,440，加 fuType 5,280 等）+ `debug_lsIssued` 159 + `io_perf_*_REG` 10。这些是 XSPerfAccumulate 的锥，golden 侧同样读不到输出 | 需要 vmucp（加强，不是放宽）实跑才能转绿；**本轮没做**，理由见下 |
| `impl` | 261 | **我们自己漏的**：`u_core/s_reg3..s_reg10` 共 256 位（always_ff 里的 automatic int 被推成寄存器）+ 5 个 enqPtrGenModule BBPin | 真 bug 3/4 与 4/4 已修 |
| `ref` | 72 | golden-only：`walkCycle_reg[0..7]` / `waitRabWalkCycle_reg[0..7]` 共 16 位真死寄存器，+ `deqPtrGenModule/io_next_out_<1..7>_value` 56 个两侧都悬空的黑盒 pin | 属 dead_ref / 对称悬空类，尚未声明 |

`matched_nc` 已核为**严格双射**：67,689 条记录里 ref 路径两两不同、impl 路径也两两不同
（各 67,689 个互不相同），满足 vmucp 加强的配对前提。

★但本轮没有开 vmucp★：`scripts/fm_eq.tcl` 对该 appvar 设了显式白名单，Rob 不在上面；
而本轮判据要求 per-target 白名单/appvar 放在 `verif/fm_target_config/<top>.tcl`
而不是 `fm_eq.tcl` —— 那个目录当前**不存在**，fm_eq.tcl 里也没有引用它。
也就是说给 Rob 开 vmucp 需要先把那套 per-target 机制建起来，属于 harness 改动，
不在本 lane 范围内。没跑过就不许说它绿，所以这 67,689 位**如实留作未决**。

## 存了什么、没存什么

小报告原样存：`failing.rpt` / `unmatched.rpt` / `black_boxes.rpt`。
派生汇总：`fm_summary.txt`（结果表 + 锚定错误行计数 + 钉点行 + 机时）、
`unread_classes.tsv`、`unread_families.tsv`。
`fm.log`(34MB) / `receipt.json`(15MB) / `matched.rpt`(18MB) / `unread_points.txt`(10MB)
**没有入库**（本仓已入库的最大证据文件是 4.4MB，这四个是数量级外的异类），
只留 `SHA256SUMS.bigfiles` 记指纹。它们仍在跑它的机器上，重跑可复现。
