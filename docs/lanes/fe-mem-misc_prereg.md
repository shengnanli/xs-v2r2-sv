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

### A. UT（9 档 × 200k 拍，全部 errors=0 / cov_fail=0 / TEST PASSED）

| UT 目录 | 每档 checks | 变异自证（scratchpad 副本树，30k 拍，先确认改动生效并清旧日志） |
|---|---|---|
| ProbeEntry | 1799928 | M1 resp 不比 id → 65597；M2 lrsc 用已存地址 → 8030 |
| WritebackEntry（两对） | 3999750~3999770 | M1 半行选择反 → 7767；M2 去掉 alloc_q → 1955；M3 dup_1→dup_0 → 0（等价变异：三份复制值恒等） |
| Arbiter8_MainPipeReq | 2799888 | M1 第 6 路载荷接第 7 路 → 1068 |
| Arbiter8_bitmapCacheReqBundle | 799968 | M1 chosen 反序 → 29992 |
| perfEventsModule | 199992 | M1 WARL 合法集错一项 → 18502；M2 保留位置 1 → 29992 |
| Queue1_L1PrefetchReq | 1399944 | M1 改成 pipe → 56429 |
| Pipeline_1 | 1599936 | M1 子队列 PIPE 1→0 → 76091 |
| MbistBitmapCache | 7599696 | M1b child1 读回接 child2 → 7190 |
| Serializer（探针 tb） | 200000 | M1 QUEUE_SIZE 13 → 5583；M2 `<=` 改 `<` → 990 |
| RecentRequestTable（两对） | 1997325~1997330 | M1 去掉 hash2 → 5779；M2 resp 保持寄存器去使能 → 50647 |
| SplittedSRAMBitmap | 2399040 | M1 第 2 组 waymask 接错 → 120184 |
| SRAMTemplateWithFixedWidth（4 对） | 1597496~1597536 | M1 补位写 1 → 28553 |
| L1Prefetcher | 4694688~4789272 | M1 二选一 bit_vec 选 stride → 36614；M2 pmem 上界减半 → 191 |
| 父级 ProbeQueue / WritebackQueue / Pipeline / Bitmap / BitmapCache / ICacheDataArray | 9/9 各档 PASSED | 见 §5 |

tb 修正（均先于证明提交）：WritebackEntry / SRAMTemplateWithFixedWidth 的 arm 排除复位期与清表期（复位期 alloc /
读请求不写不复位寄存器 —— tb 违反契约，不是 RTL 差异）；SRAMTemplateWithFixedWidth 上电 2000 拍 DFT 口静默。

### B. FM 正式证明（第一轮 evidence/bd284f4ddd1e；merge main 后在 397a2bc9c 全量重证 evidence/397a2bc9c8d3，读数逐项相同）

| 目标 | 判决 | passing | 预测 | 差额指认 | receipt.json sha256（397a2bc9c8d3） |
|---|---|---|---|---|---|
| Arbiter8_bitmapCacheReqBundle | SUCCEEDED | 48 | 48 | 0 | `34e3af9ffeef298e2a426f129e57f294699da6e55a5f4c0de5831851d12d06cb` |
| Arbiter8_MainPipeReq | SUCCEEDED | 116 | 116 | 0 | `f7d9387524250a70cde7dd68363d937638dd29860a2fcdb78f1938fd631755fe` |
| Bitmap | SUCCEEDED | 1777 | 1777 | constant_reg 11 | `27653302c0e746db4409e83fa8724a7b45639c7b56ea6826ba03585f982b0b57` |
| BitmapCache | SUCCEEDED | 13069 | 13069 | ★模型上界 1925 < 实测 13069：模型把 array_9_ext 当黑盒，本 UT 两侧读入 array_9_ext.v 行为模型、存储位进比较点；与上一份 receipt dfc23ffb 同读数——模型缺口，不是实测漂移★ | `6f9259265247470e72c195ffb96416e099ba1d209c9dfcffd2a2b3524afbbbd0` |
| FTB | PASS_DEAD_REF | 8605 | 8605 | merge 带内；unread 50 = dead_ref（见 fe-mem-misc-ftb_prereg.md） | `a027b58b8d2658620d48dc03d32842bb2d17398153abc5bdbe48a48a381a8e5d` |
| ICacheDataArray | SUCCEEDED | 8237 | 8237 | 0 | `7a81d255d03dca4ccb96de3162f01fd92c3c7935479ba6efea3fc1829922efd2` |
| L1Prefetcher | SUCCEEDED | 9089 | 9089 | constant_reg 60 | `4788718649d558ccf3a98fbc888a956b3c08fe06b13a953e8e548ad28ceb1e67` |
| MbistBitmapCache | SUCCEEDED | 661 | 661 | 0 | `c2adc6ca6b4b045f22b2671c70ae486b4f050c6bcf5b129fcdc4d1bea7259f14` |
| perfEventsModule | SUCCEEDED | 125 | 125 | 0 | `14b7b4c46446d39d3190ab2b7143a93b579b3072fb5cabe8c0b6b3e52cee7fcc` |
| Pipeline | SUCCEEDED | 113 | 113 | 0 | `d0bca3d779064283a51def97ac550b2397193465b5281102f9997230c44ec30e` |
| Pipeline_1 | SUCCEEDED | 201 | 201 | 0 | `9211fb06b3987df9f6f96ec8368b2ec7fb15bdb774addd23607b1f85e842c5d6` |
| ProbeEntry | SUCCEEDED | 262 | 262 | 0 | `ef8aed426c25d70c70eafbcdff1218952b5ccbc895c0dcb3406a9dc6f4c931ca` |
| ProbeQueue | SUCCEEDED | 1092 | 1092 | constant_reg 2 | `11c8d0fef5fe1e40989e574d9f1b13378e1ca6b1f019084e83292587884235f6` |
| Queue1_L1PrefetchReq | SUCCEEDED | 113 | 113 | 0 | `39e1d9c82938fed2506ffc3c43be856fe89d4640550ec7297b75486292f31bdc` |
| RAS | SUCCEEDED | 6592 | 6592 | 0 | `a41a5e15db439788017be924bf1dc2491270e7ebef43e85ad9f1ebc04925953e` |
| RecentRequestTable | SUCCEEDED | 97 | 97 | 0 | `35e8c69561dafb28817bd94117b1c7e0b0f89e7693ffbdd4c4e1ae4c66814e1a` |
| RecentRequestTable_1 | SUCCEEDED | 100 | 100 | 0 | `8da8aca43bca08fbdb78065c029aafc4eda67ef883bd4a130897140fdb7ad1ea` |
| Serializer | SUCCEEDED | 5 | 5 | 0 | `57ba27aa2df19f14fbbc80a469066f51ceceede74e5532893fa47e73a26dc906` |
| SplittedSRAM | SUCCEEDED | 1480 | 1480 | 0 | `fbbf8907ce14c576000f2f03922d8156ff6eeb2b2eb17bd9c8caed89dbe840ab` |
| SRAMTemplateWithFixedWidth | SUCCEEDED | 351 | 351 | 0 | `84c2f604818fb1bb543de5717edd2e2abd92ebf4da2d76f6bfdbdc605b4362dc` |
| SRAMTemplateWithFixedWidth_12 | SUCCEEDED | 351 | 351 | 0 | `ca53756cd13453cdafd4530c56bf55dd21a589b085c66845b5ef59d255dcfd65` |
| SRAMTemplateWithFixedWidth_28 | SUCCEEDED | 351 | 351 | 0 | `1d5139da260474def7582ed2210d9f305dd599d01f43df2f5e617c140e2e6c3a` |
| SRAMTemplateWithFixedWidth_4 | SUCCEEDED | 351 | 351 | 0 | `3a8bc2e06abde68d14d620bdc9b039e3f77f4c764aa53fd19d5326f24ef37a05` |
| WritebackEntry | SUCCEEDED | 1042 | 1042 | 0 | `a9265deb662861602da7f7eaf6a7cbe1fde241821213cc4df8d3540f9697ff92` |
| WritebackEntry_15 | SUCCEEDED | 1042 | 1042 | 0 | `37b33e771bba0f2613ddb43fae32c51e992a68b54676790c8bc1c99248c3d2cd` |
| WritebackQueue | SUCCEEDED | 13053 | 13053 | 0 | `5fed86c17ceb36d5dbbbf4fa25ad1a03140aa664fb1868171861317d27a1ed7e` |

全部：failing / unverified / aborted / unmatched 0；dont_verify / elab147 / relaxed_appvars 空（Serializer 的
verification_assume_reg_init none 为加强方向，见其配置）；黑盒仅 allow 声明的厂商宏叶子。
`fm_predict.py check` 除 BitmapCache（见上）外全部对上；`check_lane_receipts.py` rc=0。

### C. ICache —— 未签（如实记）

UT（verif/ut/ICache，8 子模块全部读重写件，tb 加 MBIST 上电写满再读 + 3000 拍暖机）9 档全绿（每档 checks=196999）。
FM 三次诊断跑（不出证，每次约 45 分钟）：
1. merge_dup=false：failing 8117 / unmatched 635 —— 子模块重写核把 golden 的多份恒等打拍寄存器合成一份
   （ICacheMainPipe s1_datas_REG_0..6 等），关 merge 时 ref 侧无对家；
2. merge_dup 默认：failing 325 / unmatched 597(ref) —— 全在 missUnit：MSHR blkPaddr / vSetIdx、优先级 FIFO regFiles
   名字不同，多层 u_core 下 fm_eq 的自动配对失效；
3. 加 scripts/gen_icache_pins.py 钉点（pre 740 / post 33，全部被接受）+ vmucp：failing 808 / unmatched 24(impl) ——
   ref 侧 4 个取指 MSHR 的 vSetIdx[5:0] 在父级被 merge 并入同源寄存器，impl 侧 vset_idx_q[5:0] 没被并掉，
   成了无对家的自由变量，MSHR 状态全线连带 failing。
阻塞点：merge 开 / 关两种口径各缺一部分对家；需要按 merge 代表逐位处理，或让 ICacheMainPipe / ICacheMissUnit 重写件
在这 24 位上与 golden 同构（要改别的 lane 已签子模块，本 lane 未做）。
