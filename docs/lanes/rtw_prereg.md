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
