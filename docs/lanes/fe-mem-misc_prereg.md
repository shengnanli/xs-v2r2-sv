# fe-mem-misc lane（agent/fe-mem-misc）—— 跑前登记（叶子/小件批次）

本文件在下列目标的正式 FM（`run_proof.sh`）起跑之前提交；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。FTB / RAS 由子任务各自登记，见
`docs/lanes/fe-mem-misc-ftb_prereg.md`、`docs/lanes/fe-mem-misc-ras_prereg.md`。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | main `3f23a91cb`（claim commit `2aa8de801`） |
| 工作树 / 分支 | `/home/eda/xs-env/wt-fe-mem-misc`，`agent/fe-mem-misc` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 口径 | 无 SRAM 的目标 `signoff-strict`、含厂商 SRAM 宏的目标 `assembly`（唯一黑盒 = verif/allow/<T>.json 声明的 `array_*_ext`，由 `verif/allow_gen` 的 `gen_expected.build` 独立生成，不读运行结果）；allowlist 0；无 dont_verify |
| 证明命令 | `PROOF_COMMIT=<登记 commit> bash scripts/run_proof.sh <UT> <T> < /dev/null`（同 lane 另有子任务在改别的文件，钉 commit） |

## 1. 目标、结构与子模块处置

| 目标 | golden 行 | 重写件 | 结构 / 复用 | 子模块（两侧白盒，impl 读重写件） |
|---|---|---|---|---|
| ProbeEntry | 189 | rtl/memblock/ProbeEntry.sv | 手写核 xs_ProbeEntry_core（3 态 enum 状态机） | 无 |
| WritebackEntry / _15 | 275 / 275 | rtl/memblock/WritebackEntry.sv / _15.sv | 共享核 xs_WritebackEntry_core（ID_W 5/6），_15 只是薄 wrapper | 无 |
| Arbiter8_MainPipeReq | 243 | rtl/memblock/Arbiter8_MainPipeReq.sv | 已签共享核 xs_FixedPriorityArbiter_core（未改核） | 无 |
| Arbiter8_bitmapCacheReqBundle | 148 | rtl/mmu/Arbiter8_bitmapCacheReqBundle.sv | 同上；chosen 作载荷字段，out_ready 接 1 | 无 |
| perfEventsModule | 214 | rtl/backend/perfEventsModule.sv | 手写核 xs_perfEvents_core（OPTYPE WARL） | 无 |
| Queue1_L1PrefetchReq | 155 | rtl/memblock/Queue1_L1PrefetchReq.sv | 已签共享核 xs_ChiselQueue1_core（PIPE=0），薄文件由 scripts/gen_depth1queue_leaves5.py 生成 | 无 |
| Pipeline_1 | 129 | rtl/uncore/Pipeline_1.sv | 单例化 | Queue1_PrefetchReq |
| MbistBitmapCache | 279 | rtl/dft/MbistBitmapCache.sv | 已签共享核 xs_mbist_pipe_core，由 scripts/gen_mbist_pipe_family.py（EXTRA_MODS）生成 | 无 |
| Serializer | 134 | rtl/memblock/Serializer.sv | 手写核 xs_Serializer_core（ENABLE_SPB=false 下只剩一个死指针） | 无 |
| RecentRequestTable / _1 | 228 / 228 | rtl/uncore/RecentRequestTable.sv / _1.sv | 共享核 xs_RecentRequestTable_core | SRAMTemplate_146（+ 厂商宏链两侧同读，array_13_ext 黑盒） |
| SplittedSRAM | 330 | rtl/mmu/SplittedSRAM.sv | 手写核 xs_SplittedSRAM_bitmap_core（2×2 切块） | SRAMTemplate_124 ×4（array_9_ext ×4 黑盒） |
| SRAMTemplateWithFixedWidth / _4 / _12 / _28 | 146 ×4 | rtl/frontend/SRAMTemplateWithFixedWidth*.sv | 薄文件由 scripts/gen_sram_fixed_width.py 生成（逐端口核对 golden） | SRAMTemplate_4 / _8 / _16 / _32（array_0_ext 黑盒） |
| L1Prefetcher | 377 | rtl/memblock/L1Prefetcher.sv | 本层接线 + 二选一 + 出口门控 | TrainFilter / TrainFilter_1 / StrideMetaArray / StreamBitVectorArray / MutiLevelPrefetchFilter（+ RRArbiterInit_6..9） |

## 2. UT（9 档 = seed 1/7/42 × `+vcs+initreg+0` / `+vcs+initreg+random` / `+vcs+initreg+<seed>017`，各 200k 拍，seed 串行）

全部双例化 golden vs `<T>_xs`，逐拍逐位比全部输出（dual_tb_lib；Serializer 无输出端口，手写探针 tb：每拍给两侧注入同一随机指针、比次态）。
★seed 1 × random 档实为全 1 档（CONVENTIONS initreg 节），`<seed>017` 是第三个真随机档。★
读数见 §对账 A（commit 早于本登记的 RTL 字节；tb 修正记录在对账里）。

## 3. 跑前预测（★跑完不许改本节★；登记见 docs/fm_predictions/<T>.json）

模型 = golden 闭包寄存器位 + 顶层输出位（`fm_predict.py model`）。lane 内非正式试跑（`make fm-<T>`，工作树 dirty 故不出证）读数作依据，均已写明。

| 目标 | 模型 | 预测 passing | 其余预测 | 依据（试跑） |
|---|---|---|---|---|
| ProbeEntry | 262 | 262 | 全 0；无 vmucp | 试跑 SUCCEEDED 262 |
| WritebackEntry | 1042 | 1042 | vmucp 开（2 位对称死位：req_dirty / remain_dup_0[1]） | 关 vmucp 1040 + matched_nc 2；开后 1042 |
| WritebackEntry_15 | 1042 | 1042 | 同上 | 同上 |
| Arbiter8_MainPipeReq | 116 | 116 | 纯组合 | 试跑 116 |
| Arbiter8_bitmapCacheReqBundle | 48 | 48 | 纯组合 | 试跑 48 |
| perfEventsModule | 125 | 125 | — | 试跑 125 |
| Queue1_L1PrefetchReq | 113 | 113 | — | 试跑 113 |
| Pipeline_1 | 201 | 201 | — | 试跑 201 |
| MbistBitmapCache | 661 | 661 | — | 试跑 661 |
| Serializer | 5 | 5 | vmucp 开 + `verification_assume_reg_init none`（见 verif/fm_target_config/Serializer.tcl） | Auto 下 5 位全判 Constant reg → FM-334 NOT RUN；none 后 5 |
| RecentRequestTable | 97 | 97 | assembly；merge_dup 默认；1 对钉点（REG ↔ rw_same_cycle_q）+ vmucp | 试跑 97 |
| RecentRequestTable_1 | 100 | 100 | 同上 | 试跑 100 |
| SplittedSRAM | 1480 | 1480 | assembly；merge_dup 默认；黑盒 array_9_ext ×4（两侧） | 试跑 1480（merge 关时有 4 个 impl 独占 rdata_last_REG，见 Makefile 注释） |
| SRAMTemplateWithFixedWidth | 351 | 351 | assembly；1 对钉点（rdata_hold[65]）+ vmucp | 关钉点 350 + 两侧各 1 unread；钉+vmucp 后 351（_4 实测） |
| SRAMTemplateWithFixedWidth_4 | 351 | 351 | 同上 | 同上 |
| SRAMTemplateWithFixedWidth_12 | 351 | 351 | 同上 | 同上 |
| SRAMTemplateWithFixedWidth_28 | 351 | 351 | 同上 | 同上 |
| L1Prefetcher | 9149 | 9089 | Constant reg 60；vmucp 开（1011 位）；钉点 1692+1400（pre）+1（post） | 关 vmucp/未钉 TrainFilter：passing 8078 + matched_nc 558 + 两侧各 453 未配上 |

其余各项一律预测：failing 0 / unverified 0 / aborted 0 / unmatched 0(0) / unread 0（vmucp 开者加强后）/
dont_verify [] / elab147 [] / relaxed_appvars []（Serializer 的 assume_reg_init none 是加强方向，见其配置文件）。
`fm_predict check` 对账口径：差额 = constant_reg（只有 L1Prefetcher 预计非 0，= 60）。

## 4. 明写可能出错的地方

1. 本登记之前所有数字来自 lane 内试跑；正式跑在 detached worktree 上，若与试跑不同，按对账逐项指认，不改本节。
2. RRT / SplittedSRAM 用 merge_dup 默认（true），模型严格性只到「带内」；若 passing 偏离模型，先查 merge 合并对。
3. codex 0206 D1 的共享核 xs_SRAMTemplate_core 修改（另一条 lane）合入后，含 SRAMTemplate_* 的目标闭包字节变化，需随批量重证。

## 对账

（跑完追加）

## 5. 第二批跑前登记：父级改读重写子模块后的重证（★跑完不许改本节★）

| 父级 | 改动（子模块两侧同读 golden → impl 读本 lane 重写件） | 预测 passing | 试跑依据 / 与上一份 receipt |
|---|---|---|---|
| ProbeQueue | ProbeEntry ×8、Arbiter8_MainPipeReq | 1092（模型 1094 − constant_reg 2） | 试跑 1092；上一份 f40deba9 同为 1092 |
| WritebackQueue | WritebackEntry ×15、WritebackEntry_15 ×3（vmucp 照旧） | 13053 | 试跑 13053；上一份同 |
| Pipeline | Queue1_L1PrefetchReq | 113 | 试跑 113；上一份 40ec7fc3 同 |
| Bitmap | Arbiter8_bitmapCacheReqBundle | 1777（模型 1788 − constant_reg 11） | 试跑 1777；上一份 46fb5c53 同 |
| BitmapCache | SplittedSRAM（+4×SRAMTemplate_124）、MbistBitmapCache；merge_dup 改默认（见 Makefile 注释） | 13069 | 试跑 13069；上一份 dfc23ffb 同 |
| ICacheDataArray | SRAMTemplateWithFixedWidth ×4（+SRAMTemplate_{4,8,16,32}）、MbistPipeIcacheDataWay0..3（assembly，黑盒 = array_0_ext ×32 两侧，allow 不变） | 8237 | 试跑 8237；上一份 76d345fc 同 |

其余项一律预测 failing / unverified / aborted / unmatched / unread 全 0、无 dont_verify。
UT：上述 6 个目录补齐 9 档（Makefile 加 INITREG；BitmapCache / ICacheDataArray tb 加 MBIST 上电初始化，
Bitmap / BitmapCache 不复位输出寄存器按首次写入事件 arm，ICacheDataArray tb 原先写死 30000 拍、改读 +ncycles），读数见对账。
