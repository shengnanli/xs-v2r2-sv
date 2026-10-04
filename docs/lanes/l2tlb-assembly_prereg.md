# agent/l2tlb-assembly lane —— 跑前登记

基线：main `3cd47062`，认领提交 `b105bccf`；worktree `/home/eda/xs-env/wt-l2tlb-assembly`。
目标：`L2TLB`、`L2TLBWrapper` 由条件绿（native SUCCEEDED / verdict PARTIAL）转正式签核。

## 1. child 核实（逐个对着当前字节，不是转述台账）

判据：每个 child 取 `evidence/*/<child>/receipt.json` 中 impl_commit 最新的一份，
把 receipt 的 `impl_closure` + `golden_closure` 每个文件在当前 worktree / G1 golden 上重算 sha256，
全部相等记 `stale=0`。复跑：`python3 <scratch>/childcheck.py <child>...`（脚本逻辑即上句）。

| child（L2TLB 直接例化） | receipt | verdict | 闭包 stale |
|---|---|---|---|
| PtwCache | evidence/22184c5297e2 | SUCCEEDED（passing 143797） | 0 |
| PTW | evidence/f4acfd23ef8e | SUCCEEDED | 0 |
| LLPTW | evidence/5a41405d9708 | SUCCEEDED | 0 |
| HPTW | evidence/28d7028dc2fb | SUCCEEDED | 0 |
| Bitmap | evidence/46fb5c533f75 | SUCCEEDED | 0 |
| BitmapCache | evidence/dfc23ffb1c9b | SUCCEEDED | 0 |
| L2TlbMissQueue | evidence/dd55953a7513 | SUCCEEDED | 0 |
| L2TlbPrefetch | evidence/dd55953a7513 | PASS_DEAD_REF | 0 |
| PMP | evidence/4b8bfeb38497 | SUCCEEDED | 0 |
| PMPChecker（×5） | evidence/76a7067be695 | SUCCEEDED | 0 |
| Arbiter1_L2TLBImp_Anon / Arbiter2_L2TLBImp_Anon_1 / Arbiter3_bitmapReqBundle / Arbiter4_L2TlbMemReqBundle / Arbiter5_L2TlbWithHptwIdBundle | evidence/dd55953a7513 | SUCCEEDED | 0 |
| Arbiter2_L2TLBImp_Anon / Arbiter2_L2TlbWithHptwIdBundle / Arbiter2_PtwReq | evidence/50430fdf8353 | SUCCEEDED | 0 |
| Arbiter3_L2TLBImp_Anon | evidence/97d5fc20f936 | SUCCEEDED | 0 |
| DelayN_13 / DelayN_220 / DelayN_221 | evidence/eee60602a12f | SUCCEEDED | 0 |

结论：全部直接 child 已签、闭包与当前字节一致。（`docs/coverage_three_axis.tsv` 里 PtwCache
仍写 UNPROVEN —— 台账未刷新，receipt 已在 main。）

## 2. 为什么不是"填 child 证书"，而是 child 两侧白盒

assembly 的 green_child 背书走 D57 证书：`scripts/proof_certificate.py` 第 669–674 行要求
`certificate.impl_commit == POLICY.freeze_commit`；`verif/proof_certificates/POLICY.json` 的
`freeze_commit` 仍是 `null` ⇒ `green_child_policy_no_freeze_commit`，任何 green_child 在任何 commit
上都过不了闸（这 8 个 child 也都还没有 `verif/proof_certificates/<child>.json`）。冻结是 integrator
的动作，本 lane 不碰 POLICY / 闸规则。

照 CtrlBlock 第 2 轮先例（`verif/allow/CtrlBlock.json` note；receipt evidence/27fd6722e959 impl 闭包
含 77 个 golden 文件，PASS_DEAD_REF）：**child 两侧白盒展开**，ref 与 impl 读同一份 golden child 定义
（UNCHANGED_GOLDEN_DEP）。这比黑盒更强：child 的全部寄存器/输出进比较，本层 glue 的输入驱动一直比到
child 内部状态。黑盒只剩 `ram_40x47`（L2TlbMissQueue 内 Queue40 的 ram_ext；inline 触发 FMR_ELAB-147；
`verif/vendor_boundary.tsv` 已单条审定 APPROVED_MEMORY_MACRO_MODEL，codex 0158 §1，
symmetric_both_sides_only；L2TlbMissQueue 自己的签核用同一条边界）。

**PMP 的处境（核实结果）**：当前 main 上 L2TLB 用的是 **golden PMP，两侧白盒展开**（不在
FM_INTERFACE_ONLY 里，impl 侧读 golden `PMP.sv`）；6a06215f 曾把 impl 侧换成重写 PMP、FM 不收敛已 revert。
本 lane 不重试切换；PMP/PMPChecker 两侧同源 golden。

## 3. 配置改动

| 目标 | 旧 | 新 |
|---|---|---|
| L2TLB | assembly，8 child 对称黑盒（green_child 无证书） | assembly，只 `ram_40x47` 对称黑盒（1/1）；child 两侧 golden 白盒；FM_REF_DEPS 改字面文件名；merge_dup 仍 true |
| L2TLBWrapper | assembly，L2TLB 对称黑盒 | assembly，impl 侧换入**重写 L2TLB**（rtl/memblock/L2TLB.sv）白盒、ref 侧 golden L2TLB；child 闭包两侧 golden；只 `ram_40x47` 对称黑盒；merge_dup 改 true（理由同 L2TLB：重写 csr_dup[i] 每份完整 struct、golden 副本被裁成字段子集） |

两步走（vmucp standing rule）：第 1 次 `FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=false` 拿 matched-unread
清单核双射；第 2 次打开（`verif/fm_target_config/<T>.tcl` 记依据），核 passing 正好增 unread 数。

## 4. 预测（跑前写死）

模型：`scripts/fm_predict.py model` 给 L2TLB 57883 / L2TLBWrapper 58111，但它把**白盒读入的**
`array_9/10/11_ext.v` 当黑盒（只计输入引脚），与 PtwCache / BitmapCache 登记时同一工具缺口。手工上界
（merge 关、常量 0 时的全部比较点）：

    L2TLB        = regs 51034 + outs 3589 + ram_40x47 输入 63
                   + array_11_ext 16×(64×114+1+6)=116848 + array_10_ext (4×786+1+2)=3147
                   + array_9_ext 4×(32×90+1+5)=11544                         = 186225
    L2TLBWrapper = 上式 + 外壳 perf 两拍 19×6×2=228                           = 186453

（PtwCache 143797 与 BitmapCache 13069 的实测正是用同一算法逐位对上的。）

merge_dup=true，所以 passing 只给带：`186225 - 51034 - constant_reg - unread ≤ passing ≤ 186225`。

判别性预测（可证伪）：

1. 两目标两次跑 native 全 SUCCEEDED；failing 0 / unverified 0 / aborted 0 / unmatched（ref/impl/unread/bbox 六项）0；
   无 dont_verify、无 elab147。
2. 观测黑盒集合 = 声明：两侧各 1 个 ram_40x47，没有别的。
3. vmucp 关：matched-unread ≥ 809（PMP pmaMapping_* 那 809 对必在），并且全部是"去掉两侧前缀后后缀逐字相同"的双射对
   （两侧 child 是同一份 golden 定义）；L2TLBWrapper 的 unread 集合 = L2TLB 的集合加前缀 `ptw/`，**数目相等**。
4. vmucp 开：`passing_on = passing_off + unread_off`（逐位），unread 归零，failing 仍 0。
5. `passing(L2TLBWrapper) - passing(L2TLB) = 228`（外壳 19 路 perf × 6 位 × 两拍；外壳没有别的寄存器，
   输出位与 L2TLB 相同 3589）——两次跑各自成立。偏离则逐项指认。
6. 判定：vmucp 开那次两目标 verdict = SUCCEEDED（assembly，APPROVED_MEMORY_MACRO_MODEL 1/1）。

## 5. UT

L2TLB：seed 1/7/42 × INITREG 0/1，各 200k 拍，errors=0（★不许 random★：双例化两侧 golden child 是两个
实例，initreg random 按实例各摇，见 Makefile 注释）。L2TLBWrapper：impl 侧现在是**重写 L2TLB**，同样 6 档。
RTL 本 lane 不改（若 FM 逼出 RTL 修复再补变异）。

## 6. 第 1 次跑（be640c5f，vmucp 关）结果与第 2 次跑前登记（追加，早于第 2 次证明）

实测（evidence/be640c5fbd5c/{L2TLB,L2TLBWrapper}）：两目标 native **FAILED**，与预测 1 不符。
- L2TLB：passing 8644 / failing ≥20（截断）/ unverified 9856 / unmatched ref 160966、impl 161753 / matched-unread 1028 / constant_reg 83。
- L2TLBWrapper：passing 8562 / failing ≥20 / unverified 9972 / unmatched 161761 / constant_reg 167。

根因（从 unmatched.rpt 按顶层实例分组，可复跑：`grep -E '^\s*(Ref|Impl)\s' unmatched.rpt | awk '{print $1,$3}' | sed -E 's#(r|i):/WORK/L2TLB/(u_core/)?([^/]+)/.*#\1 \3#' | sort | uniq -c | sort -rn`）：
未配上的 child 内部点**全部**落在三个实例下：`cache`↔`u_core/u_page_cache`（140216/140219）、
`bitmapcache`↔`u_core/u_bitmap_cache`（12802/12802）、`missQueue`↔`u_core/u_miss_queue`（13/13）；
两侧后缀逐字相同（同一份 golden 定义）。而实例名是 `u_<golden 名>` 的 child（`u_pmp`↔`pmp`、`u_ptw`、`u_llptw`、
`u_hptw`、`u_bitmap`、`u_prefetch`）内部全部自动配上。即 FM 的名字匹配能吃掉 `u_core/` 层与 `u_` 前缀，
吃不掉 `page_cache`≠`cache`、`bitmap_cache`≠`bitmapcache`、`miss_queue`≠`missQueue`。
本层 glue 的 ~8k 点随之配不上（签名分析在 16 万未配点下失效；上一轮 child 黑盒时它们全部配上）。

修法（不用 set_user_match，按「改名不硬钉」的既有教训）：重写核里这三个实例改名为
`u_cache` / `u_bitmapcache` / `u_missQueue`（scripts/gen_l2tlb.py 的 INSTANCES 表 + 重新生成，纯改名，无逻辑变化）；
同步 docs/hier_rebind_map.tsv 的 3 行、docs/perf_bore_map.tsv 的 28 行（只改这三个实例路径；与
`perf_rebind.py` 重算结果比对，除 main 上已有的无关漂移行 x1_bore_235 外逐行相同；hier_map 的其余漂移
（CVT/VCVT/Estimate7/INT2FP 行）是 main 既有的，与本 lane 无关，不夹带）。allow 两份 impl 路径同步。

第 2 次跑（仍 vmucp 关）预测：维持 §4 的 1–5 条；另：unmatched 六项全 0 的前提是改名后这三个实例被 FM
像其余 child 一样自动配上；若 PTW 内 `stage1_entry_1..7_asid`（第 1 次 impl 侧 112 个单边未配点）仍单边，
即是 merge_dup 两侧不对称合并，届时停下诊断。
UT 回归：L2TLB / L2TLBWrapper 各 seed 1/7/42 × INITREG 0/1，200k 拍 errors=0（改名后重跑）。

## 7. 第 2 次跑（66c5bbc3，改名后，vmucp 关）L2TLB 结果与第 3 次跑前登记

实测（evidence/66c5bbc37f67/L2TLB）：native FAILED，但配对基本闭合——matched by name 171100 + signature 8344；
passing 179427 / failing 17（未截断）/ unverified 0 / unmatched：compare ref 0 · impl 3，unread ref 144 · impl 144 /
matched-unread 1144 / constant_reg 125 / 黑盒仅 ram_40x47 1/1（与预测 2 一致）。
- 1144 对 matched-unread：逐对核过，全部是「去掉两侧前缀（含实例改名 u_csr_delay↔csr_tmp_delay 等）后后缀逐字相同」或
  csr_dup_<n>_<field>_reg[b] ↔ csr_dup_reg[n]\[field][b]（24 对）的双射；pmp 809 / llptw 109 / cache 93 / bitmapcache 42 /
  bitmap 25 / csr_tmp_delay 24 / sfence_tmp_delay 10 / prefetch 4 / hptw 3 / ptw 1 / csr_dup 24。
- 3 个 impl 单边未配：`u_cache/ishptw_1_reg`、`u_cache/s2x_info_1_reg[1:0]`；17 个 failing 全在 PtwCache 的
  spHit / spJmpBitmapCheck / state_reg_4（PLRU）——它们的锥正好经过 ishptw_1/s2x_info_1（PtwCache.sv 6120-6122 行），
  判为这 3 个单边点的下游。这两个寄存器与 data_isHptwReq/data_req_info_s2xlate 同 D、同使能（leftFire ≡ _s2x_info_T_1），
  golden 侧被 merge_dup 合掉、重写侧没有。两侧唯一可见的结构差异是 cache.io_req_valid 的与门操作数次序
  （golden `ready & valid`，重写 `valid & ready`）→ 本轮改成与 golden 同序（假设，本次跑验证）。
- 144↔144 unmatched-unread：本层 glue 里两侧都无读者的位（PTE [9:8]、sfence addr [9:0]），扁平名↔数组名配不上。
  新增 scripts/gen_l2tlb_pins.py（--check）生成 verif/ut/L2TLB/fm_pins.tcl：按命名规则 144 条 set_user_match，
  fail-closed 字面计数 144；生成集合与 FM 报告的两侧 144 名逐字相等（已机检）。

第 3 次跑（vmucp 仍关）预测：native SUCCEEDED；failing 0 / unverified 0 / unmatched 六项 0；
matched-unread = 1144 + 144 = 1288；passing = 179427 + 17（原 failing 转 passing）+ 3（3 个单边点配上）= 179447
（若 ishptw_1/s2x_info_1 改为两侧都被合并，则不是 +3 而是 +0，passing 179444——两者之一，偏离再指认）。
第 4 次跑（vmucp 开）预测：passing = 第 3 次 passing + 1288，unread 0。

## 8. L2TLBWrapper 第 2 次跑作废 + 第 3 次跑前登记

第 2 次跑（66c5bbc3）matching 阶段超 2.5 小时未结束（同机多条 lane 的大 FM 并行），配置已过时（无钉点、无 req.valid 次序修正），
按我自己起的 PID 停掉，无证据产出。第 3 次跑在 41346152（含 L2TLB 第 3 次的全部修正）上：
verif/ut/L2TLBWrapper/fm_pins.tcl 同一规则、前缀 ptw/ 与 ptw/u_core/，144 条；sfence 代表副本取 golden 2 / 重写 0
（依据：golden sfence_dup_0/_1 被 firtool 裁掉了 addr 字段，2 号是最低的带 addr 副本；重写每份都带 addr，0 号最低——
 结构决定，与 L2TLB 同）。预测：与 L2TLB 第 3 次同形；passing(L2TLBWrapper) − passing(L2TLB) = 228；
matched-unread 数与 L2TLB 相等；黑盒仅 ram_40x47 1/1。

## 9. 第 3 次跑结果 + 第 4 次（vmucp 开，签核候选）跑前登记

实测（vmucp 关）：
| | L2TLB（413461528f8f） | L2TLBWrapper（0f42e91463d9） |
|---|---|---|
| native | FAILED | FAILED |
| passing | 179427 | 179469 |
| failing | 17（未截断，PtwCache spHit/spJmpBitmapCheck/state_reg_4） | 17（同） |
| unmatched compare ref/impl | 0 / 3 | 0 / 3 |
| unmatched unread ref/impl | 0 / 0（144 钉点全上：L2TLB_PIN ok=144 bad=0） | 0 / 0（ok=144） |
| matched-unread | 1288 | 1288 |
| constant_reg | 125 | 209 |
| 黑盒 | ram_40x47 1/1 | ram_40x47 1/1 |

- 预测对上的：144 钉点全中、unread 1144+144=1288（两目标相等）、黑盒集合。
- 预测错的：①§7 的「改 req.valid 次序消掉 3 个单边点」**证伪**，3 点仍在、17 failing 仍在；
  ②§4-5 的 `passing(Wrapper)−passing(L2TLB)=228` **不成立**：实测 +42（DFF 175814 vs 175772），
  constant_reg +84，外壳 228 位里余 102 位未逐位指认——merge_dup=true 下落在合并带内（推测是 19 路
  perf 里同值事件的两拍寄存器被合并），**未证实**，照实记。
- 1288 对 matched-unread 双射复核（两目标各自）：1144 对去前缀后后缀相同或 csr_dup 字段对应、144 对=钉点，
  other=0；复核脚本即本 lane 报告里的 python 片段（读 sidecar/native_facts.json 的
  matched_unread_notcompared_pairs 与 fm_pins.tcl）。

第 4 次跑改动：fm_pins.tcl 增 3 条一对多钉点（gen_l2tlb_pins.py merge_pairs()：重写侧 u_cache/ishptw_1、
s2x_info_1[1:0] → golden 侧 merge 幸存者 cache/data_isHptwReq、data_req_info_s2xlate[1:0]；依据 PtwCache.sv
3079/3085-3086/30766-30769/33894-33895 行：同 D、使能逐项相等），共 147；两目标打开 vmucp
（fm_target_config/L2TLB.tcl 追加依据，新建 L2TLBWrapper.tcl）。已合入 main 18359395（POLICY.freeze_commit 仍 null）。

第 4 次预测（两目标）：native SUCCEEDED；failing 0 / unverified 0 / aborted 0 / unmatched 六项 0 / unread 0；
passing = 第 3 次 passing + 17（原 failing）+ 3（新配的一对多点）+ 1288（vmucp）=
**L2TLB 180735**、**L2TLBWrapper 180777**；constant_reg 不变（125 / 209）；黑盒仅 ram_40x47 1/1；
verdict SUCCEEDED。若一对多钉点被拒（set_user_match 返回 0）则 fail-closed 报错停下。

## 10. 第 4 次跑结果 + 第 5 次跑前登记

L2TLB（evidence/8ae5cf0427db/L2TLB，vmucp 开）：native FAILED，passing **180715** = 第 3 次 179427 + 1288
（**vmucp 恰增 1288，逐位对上**，unread 归零）；failing 17 / unmatched impl 3。钉点 L2TLB_PIN ok=147 bad=0，但 3 条
「一对多」是分开写的两条 set_user_match，FM 把 golden 幸存者 cache/data_isHptwReq、data_req_info_s2xlate[1:0]
**改配**到了重写侧 ishptw_1/s2x_info_1，重写侧同名 data_* 反成 3 个单边点，failing 换成它们的下游
（bypassed_reg*/data_1_*/l0_hitVec*/l1_hitVec*）。FM man：一对多须在**同一条** set_user_match 里列出全部 impl 对象。
L2TLBWrapper 第 4 次跑同一缺陷，matching 阶段由我按 PID 停掉，无证据。

第 5 次：merge_pairs() 改为单条 `set_user_match ref impl_同名 impl_额外`（_l2p3），其余不变。
预测（两目标）：native SUCCEEDED；failing 0 / unverified 0 / unmatched 六项 0 / unread 0；
L2TLB passing = 180715 + 17 + 3 = **180735**；L2TLBWrapper passing = 第 3 次 179469 + 1288 + 17 + 3 = **180777**；
constant_reg 125 / 209；黑盒 ram_40x47 1/1；verdict SUCCEEDED。

## 11. 第 5 次跑（签核）对账

| | 预测 | 实测 | 差 |
|---|---|---|---|
| L2TLB passing（evidence/6d4a2ff1e712） | 180735 | 180735 | 0 |
| L2TLBWrapper passing | 180777 | 180777 | 0 |
| failing / unverified / aborted / unread | 0 | 0 | — |
| unmatched（compare/unread/bbout，ref·impl） | 0 | 0 | — |
| constant_reg | 125 / 209 | 125 / 209 | 0 |
| 黑盒 | ram_40x47 1/1 | ram_40x47 1/1（interface-only，matched bbox pair） | — |
| 钉点 | 147 | L2TLB_PIN ok=147 bad=0（两目标） | — |
| verdict | SUCCEEDED | SUCCEEDED（assembly，无 dont_verify / elab147） | — |

账目：180735 = 179427（第 3 次）+ 1288（vmucp）+ 17（原 failing）+ 3（一对多新增比较点）；
180777 = 179469 + 1288 + 17 + 3。`fm_predict.py check` 对两目标机械给 ABOVE_MODEL（工具把白盒读入的
array_*_ext.v 当黑盒，§4 已登记的同一缺口；手工模型上界 186225 / 186453，实测在 merge 带内）。
仍未逐位指认的一项：外壳 228 位 perf 寄存器只有 42 位成比较点、84 位常量，余 102 位推测为 merge_dup 合并（§9）。

## 12. codex 0209：ram_40x47 父级范围显式登记（合 main bd3b7081 后）

- `scripts/audit_ram_memory_model.py` 的 `MANUAL_REVIEW_PARENTS['ram_40x47']` = {L2TlbMissQueue（codex_0158，原授权）,
  L2TLB / L2TLBWrapper（codex_0209，经由 `receipt:evidence/dd55953a7513/L2TlbMissQueue/receipt.json`）}；
  `MANUAL_REVIEW_GOLDEN['ram_40x47']` 绑 golden sha256 68dbc6df…9766 + 8 端口签名（并与 vendor_boundary.tsv 同行逐字核）。
  父级内相对路径两侧不同名，表项 rel 支持 (ref_rel, impl_rel)；ram_10x89 原表项不变。
- 经由 child 不用证书（L2TlbMissQueue 没有 tracked 证书，0209 明令不虚构）：新增 `check_child_receipt_current()`，
  在被证明 commit 的字节上复算该 receipt 的 impl 闭包（rtl/memblock/L2TlbMissQueue.sv）与 golden 闭包
  （L2TlbMissQueue.sv、Queue40_L2TlbMQBundle.sv）逐个 sha256，verdict 合格、非 dirty/provisional。当前：未 stale。
- `scripts/fm_verdict.py` 的 ram 父级范围判据改按 `MANUAL_REVIEW_PARENTS` 的 design 触发（原来只看 MANUAL_REVIEW_DESIGNS，
  ram_40x47 不在里面，等于此前从未对它做父级范围检查）。
- 负测进 `scripts/test_audit_ram_manual_review.py`（gate_all 已在跑）：R0 三父级真实声明通过；R1 别的父级、R2 别的 ram、
  R3 不在 MissQueue 子树、R4 两侧不对称、R5 一侧两实例、R6 receipt impl 闭包 stale、R7 verdict 不合格、R8 receipt 不存在、
  R9 fm_verdict 判据里子树外多一个 → 全红；R6-/R9- 正样本通过。
- 是否重证：不重证。依据：合 main 后 L2TLB / L2TLBWrapper receipt（evidence/6d4a2ff1e712）的 impl 闭包、golden 闭包、
  script 闭包（fm_eq.tcl、sidecar/fm_native_emit.tcl、fm_target_config/*.tcl）与 fm_pins.tcl 逐个 sha256 未变；
  用合并后的新 fm_verdict.py（含 ram_40x47 父级范围判据）对两份 fm.log 重判仍为 SUCCEEDED（180735 / 180777），
  L2TlbMissQueue 自己的 fm.log 重判也仍为 SUCCEEDED（125）。
