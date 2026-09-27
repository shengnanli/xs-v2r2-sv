# RenameTableWrapper / DiffRatStateBuffer FM lane（agent/rtw）—— 跑前登记

本文件在 **FM 起跑之前**提交。跑完在文件末尾追加「对账」一节，★不修改本节任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | `main` @ `d5b637e8`（Merge commit '9420eaa9…'，cb-rename 已合入；完整 hash 见对账节） |
| 工作树 | `/home/eda/xs-env/wt-rtw`，分支 `agent/rtw` |
| 目标 1 | `DiffRatStateBuffer`（golden 10,187 行 / 265 端口；重写 `rtl/backend/DiffRatStateBuffer.sv`） |
| 目标 2 | `RenameTableWrapper`（golden 2,249 行 / 455 端口；重写 `rtl/backend/RenameTableWrapper.sv`；例化 DiffRatStateBuffer + 五张 RenameTable） |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读，`G1-a4ea14f2…`） |
| 证明模式 | **assembly**（`FM_MODE = assembly`，`FM_ALLOWLIST = 1`，`FM_MERGE_DUP = false`，vmucp=false），allow 声明 `verif/allow/DiffRatStateBuffer.json` / `verif/allow/RenameTableWrapper.json`；无 dead_ref、无 fm_pins、无 fm_map |

## 1. 阻塞与处置（先于任何重跑）

上一条 lane（commit `9420eaa941b961d0d165a9dbc683afa4932b048c` 及其说明）实测：DiffRatStateBuffer 的
diagnostic **在 ref 侧 `set_top` 就失败**——golden 两个 firtool 行为级存储叶子
`diff_rat_state_bank_320x776`（320×776，1r1w）/ `stateBankTags_320x3`（320×3，1r6w）深度 320、
地址 9 位，2^9=512>320，白盒化触发 `FMR_ELAB-147 -> FM-262 -> FM-156`。与 `ram_40x47`
（L2TlbMissQueue）、`dt_pcTransType_160x2`（Rob，`docs/rob_child_ledger.tsv:80` 记为
DEP_UNCLOSED_MEM，尚未处置）同形。仓内唯一先例 = `verif/ut/L2TlbMissQueue/Makefile` 头注
（`grep -n ELAB-147`）：走 codex 0158 §1 **APPROVED_MEMORY_MACRO_MODEL**，两侧对称黑盒 +
`verif/vendor_boundary.tsv` 逐条审定 + assembly 模式。

本 lane 的处置（全部在本 commit 内，跑前就位）：

1. `scripts/audit_ram_memory_model.py` 扩展（判据不降）：M1 模板扩到 N 写口；M2 扩到每侧多实例
   （generate-for 倍数静态求值 + 每实例常量连接签名多重集相等）；M3 加形态 B「输入偏移地址」
   （`{1'b0,V}+(F?K:0)`，V/F 必须是 input 端口，须在 `verif/ram_model_parents.tsv` 第 4 列
   显式写接口契约 `value<Vmax`，脚本核 `Vmax+K<=depth` 且 `2^w<=depth`，结论标
   **PASS_INPUT_CONTRACT** 不冒充无条件 PASS）。自测 `scripts/test_audit_ram_memory_model.py`
   15 条正反例，与 `--check` 复算一起进 `scripts/gate_all.sh`。
2. 两个叶子审定结果（`python3 scripts/audit_ram_memory_model.py --check`）：
   - `diff_rat_state_bank_320x776`（sha256 `8209b41dbc4e25f826eeb14f5c66144e70201faa82d4fb71f89961f9657e2a59`）：
     M1 PASS（单写口模板逐字相等，头 == 家族参照）；M2 PASS（ref 6 扁平实例 / impl `g_bank[0..5]` 展开 6，
     常量连接 R0_en=1）；M3 PASS_INPUT_CONTRACT（两侧 7 处地址口全部为
     `{1'b0, robIdx.value[7:0]} + (robIdx.flag ? 160 : 0)`，契约 `value<160`）。
   - `stateBankTags_320x3`（sha256 `61e51d07179d127f8a9dd9c806ea36c39cbdb19e8ad421d3029775a8e447a494`）：
     M1 PASS（**6 写口**模板逐字相等）；M2 PASS（两侧各 1 实例，28 端口，W0..W5_data=4,3,2,1,5,0 逐口相同）；
     M3 PASS_INPUT_CONTRACT（同上，7 处地址口）。
   - 老条目 `ram_40x47` 在扩展后的脚本下复算仍 AUDIT_PASS（回归）。
3. 两条写入 `verif/vendor_boundary.tsv`（kind=APPROVED_MEMORY_MACRO_MODEL，body_rule
   `regimeA=fm_blackbox_both_sides;regimeB=FORBIDDEN_oob_static_index`），
   `python3 scripts/check_closure_symmetry.py --check-registry` OK。
4. 照 L2TlbMissQueue 先例，impl 侧**不另写同名叶子**：删除 `rtl/backend/diff_rat_state_bank_320x776.sv`
   / `stateBankTags_320x3.sv`（它们既不能被 FM 证明、又与审定 hash 不同，是一个「同名但未受验」的洞），
   impl 核直接例化 golden 那两份；UT 两侧共用 GOLDEN_SRCS 里的 golden 叶子。
   `FM_VARIANTS` 相应从 4 减到 2（两个叶子不再是 FM target，与 ram_40x47 同一口径）。
5. RenameTableWrapper 父级：五张 RenameTable + SnapshotGenerator + DiffRatStateBuffer 本体两侧
   **全部 elaborate**（ref golden 文件、impl `rtl/backend` 可读件），不黑盒、不走 green_child——
   所以 allow 里没有 green_child 条目，也就没有 `certificate_sha256` 可填；黑盒只有那 14 个存储宏实例。

## 2. 跑前预测（★跑完不许改本节★）

`python3 scripts/fm_predict.py model <target> --ut RenameTableWrapper`（merge_dup=false，模型适用），
登记在 `docs/fm_predictions/{DiffRatStateBuffer,RenameTableWrapper}.json`。先例 L2TlbMissQueue
（assembly，1 个 ram 黑盒）实测 passing 125 == 模型 125，即黑盒输入引脚不进 passing 计数。

| 目标 | 寄存器位 | 输出端口位 | **预测 passing** | failing | unmatched | unread | 黑盒对象 |
|---|---|---|---|---|---|---|---|
| DiffRatStateBuffer | 5759 | 776 | **11418** | 0 | 0 | 0 | 14（r 7 / i 7） |
| RenameTableWrapper | 12781 | 2102 | **19766** | 0 | 0 | 0 | 14（r 7 / i 7） |

DiffRatStateBuffer 的 5759 = stateSlotValid 320 + bankReadData 6×776 + readBankOH 6 + readValid 1 +
committedRat 776。可接受偏差 **0**；唯一允许的指认项是 receipt 的 `constant_reg`（两侧同判仍 SUCCEEDED），
差额必须逐位等于它；其它任何差额都算失配，不找第二个解释去圆。

### ★反向出口★

- ref 或 impl 任一侧 `set_top` 仍报 FMR_ELAB-147 ⇒ 黑盒没生效（叶子被哪一侧读进去了），照实报，
  不加 appvar、不 dont_verify、不 set_mismatch_message_filter。
- `black_boxes.rpt` 观测集合 != allow 声明（路径格式猜错、u_core 层级不同）⇒ 判定
  `assembly_bbox_set_mismatch`，照实报；修的只能是声明路径（黑盒集合本身不许扩）。
- failing > 0 ⇒ 逐点诊断（首选怀疑：bank 读回 X 语义 `R0_en ? mem : 'x`、slot valid 的读清零/写置位相位、
  committedRat 复位值），不放宽。`failing == 20` 只写「至少 20 个，计数被截断」。
- impl 侧 unmatched/unread ⇒ 大概率 bankReadData 无复位寄存器与 golden RegEnable 对不上，照实报。

## 3. UT 证据（跑前已达标，叶子换成 golden 后重跑）

`verif/ut/RenameTableWrapper`，`make run SEED=<s> NCYCLES=200000` 与 `make run-initreg0 SEED=<s> NCYCLES=200000`，
seed 1/7/42。数字见对账节 D（跑前已跑完，登记时如实抄录）。

跑前实测（叶子换成 golden 之后，本 commit 的字节）：

| seed | `+vcs+initreg+random` | `+vcs+initreg+0` |
|---|---|---|
| 1 | checks=199986 errors=0 TEST PASSED | checks=199986 errors=0 TEST PASSED |
| 7 | checks=199986 errors=0 TEST PASSED | checks=199986 errors=0 TEST PASSED |
| 42 | checks=199986 errors=0 TEST PASSED | checks=199986 errors=0 TEST PASSED |

`make gencheck`（`scripts/gen_renametablewrapper.py --check`）无 STALE。

## 4. 闸（跑前）

`bash scripts/gate_all.sh`：本 lane 新挂的「RAM 模型审查负测」「RAM 模型审查复算」PASS；
红的 4 条（round 台账幂等 / 覆盖率台账幂等 / FM 钉点结构闸 / 钉点调用序列闸）在 **main 同一基线
detached checkout 上同样红**（Bitmap / InterruptFilter 动态钉点无夹具、fm_round 台账与 receipt 不一致、
覆盖率台账被别的 lane 带漂），不是本 lane 引入；`docs/rewrite_coverage.tsv` 已机械重算
（`python3 scripts/rewrite_coverage.py`，两个叶子从 written 名单里消失、并带入别的 lane 的两条）。
`scripts/check_closure_symmetry.py --only RenameTableWrapper`：DiffRatStateBuffer SYMMETRIC；
RenameTableWrapper 报 `elab_error:xs_SnapshotGenerator_core: 覆盖了不存在的参数 ['DATA_W']`，
该错在已签核的 RenameTable 目标上同样出现（`--only RenameTable` 4/4 ERROR），是该脚本的静态
elaborator 认不出 `parameter int DATA_W = $bits(rab_ptr_t)`，非本 lane 引入、不改。

## 5. 第一次起跑的结果与修正（★§2 预测不动★）

第一次 `scripts/run_proof.sh RenameTableWrapper DiffRatStateBuffer RenameTableWrapper`
@ `3070f15a64e8001bff2bb0fc73f11d0ed8a1709b`（`evidence/3070f15a64e8/*/fm.log`，无 receipt）：

- **ref 侧 `set_top r:/WORK/<top>` 两个目标都成功**——两个存储宏对称黑盒确实消掉了 golden 侧那条
  FMR_ELAB-147（上一条 lane 卡死的那一步已过）。
- **impl 侧 `set_top` 失败**：唯一一条 `FMR_ELAB-147 (Signal: stateSlotValid Block: /xs_DiffRatStateBuffer_core
  Line: 129)` -> FM-262 -> FM-156，两目标同一根因。是我自己核里
  `readSlot_in_range ? stateSlotValid[readSlot] : stateSlotValid[0]` 这个 `arr[cond ? idx : 0]` 形状
  （CONVENTIONS：FM 按下标声明位宽判越界、不传播守卫；9 位下标 vs 320 深必报）。
- 修法（不加 appvar、不 filter）：照 golden 把 320 位 valid 扩成 2^9=512 位（越界 192 项都是第 0 项，
  语义与 golden `_GEN` 逐位相同）再用 9 位下标索引——下标声明位宽与向量深度精确相等。
  寄存器/输出位数不变，§2 预测不变。修正 commit 见对账节 A；UT 3 seed × 2 档在修正后的字节上重跑。

## 6. 第二次起跑的结果与修正（★§2 预测不动★）

第二次 `run_proof` @ `dc57056bf19901fa6d62a0f1349bcf9026855dc5`（`evidence/dc57056bf199/`，两份 receipt 已产出，
判定 PARTIAL，reason `assembly_unread!=0`）：两侧 `set_top` 都过，**native 两目标 SUCCEEDED**，
failing 0 / unmatched 0 / 黑盒 14 对象（与 allow 声明精确相等）/ 无 dont_verify / 无 elab147。

| 目标 | passing | 预测 | 差 | unread | 指认 |
|---|---|---|---|---|---|
| DiffRatStateBuffer | 11418 | 11418 | 0 | 1（impl-only `u_core/set_hit_reg`） | 我核里 always_ff 内的临时量 `set_hit` 被 FM 当成 impl 独有未读寄存器（老伪影形态） |
| RenameTableWrapper | 19748 | 19766 | **18** | 18 matched_nc + 同上 1 | 18 = v0Rat/vecRat/vlRat 三张表 × 6 路 `need_free` 寄存器，两侧同为死位（golden 只引出 int/fp 的 need_free） |

修正（不改预测）：
1. `set_hit` 改为 always_comb 的 `slotSetHit[SLOTS]`（常量下标 + 相等比较形式，避免再撞 ELAB-147），
   语义逐位相同，寄存器数不变。预期 DiffRatStateBuffer unread 0 -> SUCCEEDED。
2. RenameTableWrapper 走 vmucp standing rule：`verif/fm_target_config/RenameTableWrapper.tcl`
   （依据写明 18 点来源与对称性），Makefile 仅对 `fm-RenameTableWrapper` 开
   `FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=true`。预期 18 点转入 passing，**passing 回到 19766**，unread 0。
   若加强后出现 failing ⇒ 停下诊断（standing rule 的停止条件），照实报。

---

# 对账（跑完追加，★§2 数字未动★）

## A. 起止 commit

| 项 | 值 |
|---|---|
| 基线 main | `d5b637e8` |
| 跑前登记 | `3070f15a64e8001bff2bb0fc73f11d0ed8a1709b`（第一次起跑：impl 侧 ELAB-147，无 receipt） |
| 修正 1 | `dc57056bf19901fa6d62a0f1349bcf9026855dc5`（第二次起跑：native SUCCEEDED / PARTIAL unread） |
| 修正 2 = 受理 commit | `6aed766ee2ebb18b4538e31c6b412044f2a32b44`（第三次起跑：两目标 SUCCEEDED） |
| 复跑命令 | `bash scripts/run_proof.sh RenameTableWrapper DiffRatStateBuffer RenameTableWrapper`（PROOF_COMMIT=6aed766e） |

## B. FM 读数（`evidence/6aed766ee2eb/<target>/`，RUN_CONTEXT 前后 worktree 摘要一致）

| 目标 | verdict | native | mode | vmucp | passing | failing | unverified | aborted | unmatched | unread | 黑盒对象 | blackbox_out | dont_verify | elab147 | `^ *Error:` |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| DiffRatStateBuffer | **SUCCEEDED** | SUCCEEDED | assembly | false | **11418** | 0 | 0 | 0 | 0 | 0 | 14（r7/i7）== 声明 | 0 | 无 | 无 | 0 |
| RenameTableWrapper | **SUCCEEDED** | SUCCEEDED | assembly | **true** | **19766** | 0 | 0 | 0 | 0 | 0 | 14（r7/i7）== 声明 | 0 | 无 | 无 | 0 |

黑盒边界（两目标同一集合）：ref `r:/WORK/<top>[/diffRatBuffer]/diff_rat_state_bank_{0..5}_ext` + `stateBankTags_ext`；
impl `i:/WORK/<top>/u_core[/diffRatBuffer/u_core]/g_bank[0..5].diff_rat_state_bank_ext` + `stateBankTags_ext`。
只有这两个审定过的存储宏，无逻辑子模块黑盒，无 green_child。

receipt sha256：
- `evidence/6aed766ee2eb/DiffRatStateBuffer/receipt.json` = `14f13856503cb999acf805014427abd8035a1a7cde5a515dcd5f01751c381a91`
- `evidence/6aed766ee2eb/RenameTableWrapper/receipt.json` = `604de2048332c5fc93e712d12261acc4be6ab8017f837f7454cb8043ee8b9d5a`

## C. 逐条对账（`python3 scripts/fm_predict.py check DiffRatStateBuffer RenameTableWrapper`）

| 目标 | 预测 | 实测 | 差 | constant_reg | 判决 |
|---|---|---|---|---|---|
| DiffRatStateBuffer | 11418 | 11418 | 0 | 0 | 逐位相等 |
| RenameTableWrapper | 19766 | 19766 | 0 | 0 | 逐位相等 |

中间轮次 dc57056b 的 19748 = 19766 − 18，那 18 点正是 §6 指认的 need_free 对称死位；加强后如预期回到 19766。

vmucp standing rule 六条：① 精确目标绑定 `verif/fm_target_config/RenameTableWrapper.tcl`（单目标，无通配；DiffRatStateBuffer 不在）；
② 18 点逐名自动配对（`unread_points.txt` 每行一对，无 set_user_match、无强配）；③ FM 实开比较，passing 19748 → 19766；
④ failing/unverified/unread 全零；⑤ 无 dont_verify、黑盒集合与不加强轮次相同（14 个存储宏）；⑥ 来源与对称性写在该 tcl 与本文件 §6。

## D. UT 两档读数（受理 commit 的字节，`verif/ut/RenameTableWrapper`）

| seed | `+vcs+initreg+random` | `+vcs+initreg+0` |
|---|---|---|
| 1 | checks=199986 errors=0 TEST PASSED | checks=199986 errors=0 TEST PASSED |
| 7 | checks=199986 errors=0 TEST PASSED | checks=199986 errors=0 TEST PASSED |
| 42 | checks=199986 errors=0 TEST PASSED | checks=199986 errors=0 TEST PASSED |

## E. 反向出口逐条核

§2 列的四条反向出口：ELAB-147 —— 第一次起跑 impl 侧命中（我核里的 `arr[cond?idx:0]`，非黑盒失效），改 RTL 消掉，未加 appvar / filter；
黑盒集合失配 —— 未发生（声明路径一次对上）；failing —— 三轮均 0；impl unmatched/unread —— 第二轮 1 个 impl 伪影，改 RTL 消掉。
两个叶子（`diff_rat_state_bank_320x776` / `stateBankTags_320x3`）本身不再是 FM target（与 ram_40x47 同口径），其正确性由
审定条目（M1 模板逐字相等 + UT 两侧共用同一份 golden 叶子）承担。
