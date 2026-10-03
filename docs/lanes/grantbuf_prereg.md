# grantbuf lane 跑前登记（ram_10x89 审定入表后的 GrantBuffer / Queue10_GrantBuffer_Anon）

承接 `docs/lanes/l2slice_prereg.md` §12（结构 / UT / 原始预测）与 §14.3（inline 时 ERROR：FMR_ELAB-147 -> FM-156）。

## 1. 依据：codex 0202

`.agent-bridge/outbox/20260929T071500Z_codex_0202_ram10x89_ruling.md`：批准 `ram_10x89` 以
`APPROVED_MEMORY_MACRO_MODEL` **单条**登记，仅授权 GrantBuffer / Queue10_GrantBuffer_Anon 当前闭包内的两侧对称
regimeA 黑盒。本 lane 逐条落实：

| 0202 条件 | 落实 |
|---|---|
| 1 精确 design 名 | `verif/vendor_boundary.tsv` 表尾 `ram_10x89`（字面名；`--check-registry` 拒绝通配） |
| 2 golden sha256 | leaf_sha256 = `7cdc3e1c7dd131d409d1ed2b639b7cdb1f5ef12bad423815e50fed20fa6c2f0f` |
| 3 深度/宽/地址/1r1w | depth=10；port_signature `input [3:0] R0_addr;…;output [88:0] R0_data;…;input [88:0] W0_data`（sha16 81e184ef10b027bc）；clock_semantics `nclk=2;clk=R0,W0;access=1r1w` |
| 4 两侧各恰好一个 ram_ext、连接签名相同 | audit M2 机器 PASS（R0_en=1）；allow json 逐对象两侧各 1 条 |
| 5 M3 人工复核写进 rationale | rationale + `verif/ram_model_parents.tsv` 第 4 列 |
| 6 不得通用 ELAB-147 例外 | 只加一行字面名；ram_16x25 / ram_data_16x256（2 的幂）仍两侧 inline |
| 7 入表 ≠ 转绿 | 两个目标各自 clean native FM + sidecar/allowlist 精确闭合 |

## 2. 审计器结论（照实记，不为过闸改判据）

- `python3 scripts/check_closure_symmetry.py --check-registry` → rc=0（hash / 端口 / 深度 / 时钟语义与 golden 现文件一致）。
- `python3 scripts/audit_ram_memory_model.py --check` → **rc=1，ram_10x89 = AUDIT_INCOMPLETE**：M1 PASS、M2 PASS、M3 ref PASS、
  **M3 impl MANUAL**（重写件地址 `enq_ptr/deq_ptr` 是共享核 `u_core` 的输出端口，薄文件上没有非阻塞赋值）。
  codex 0202 明言"不为审计器泛化额外阻塞目标"，故不改审计器；M3 impl 以人工复核入表：
  `xs_ChiselQueue_core #(.DEPTH(10), .FLOW(1))` 的 enq_ptr/deq_ptr 复位 0，唯一更新 `next_ptr`，`!POW2 && p==9` 时回 0、否则 +1，
  归纳保持 [0,9]。**后果：`scripts/gate_all.sh` 的"RAM 模型审查复算"一项会红**，待 reviewer 决定（审计器识别共享核指针是后续维护项）。

## 3. 改动（全部早于证明）

- `verif/ut/GrantBuffer/Makefile`：ram_10x89.sv 移出 RTL_GOLDEN_DEPS（FM impl 文件集）与两个 FM_REF_DEPS，只进 GOLDEN_SRCS（VCS）；
  `FM_MODE = assembly`、`FM_ALLOWLIST ?= 1`。
- `verif/allow/Queue10_GrantBuffer_Anon.json`、`verif/allow/GrantBuffer.json`：各两条对象（r/i 各 1 个 ram_ext）。
- `scripts/gen_l2_queues.py`：非 2 的幂深度的薄文件头注释改说"审定入表、FM 两侧对称黑盒"（只改注释，重生成 Queue10 头注释）。
- UT 回归（Makefile 文件集变了）：seed 1/7/42 × initreg 0 / random / <seed>017，各 200k，**9/9 errors=0，每档 checks=14600000**。

## 4. 修正登记（★跑完不许改★）

原因：§12.3 的登记是"ram_10x89 两侧 inline"下的模型；黑盒后 Memory 10×89=890 位寄存器不再是比较点，换成黑盒输入引脚
101 位（R0_addr 4 + R0_en 1 + R0_clk 1 + W0_addr 4 + W0_en 1 + W0_clk 1 + W0_data 89；同 L2TlbMissQueue 先例，黑盒输入引脚计入）。

| 目标 | 模型 | 预测 |
|---|---|---|
| Queue10_GrantBuffer_Anon | 205（regs 9 + outs 95 + bbin 101） | passing **205** SUCCEEDED；failing / unverified / unmatched / unread / constant 0；黑盒 ram_10x89 r1/i1 |
| GrantBuffer | 11756（regs 10622 + outs 1033 + bbin 101） | failing / unverified / unmatched 0，SUCCEEDED；差额只许 unread + constant_reg：unread ≥ 1056（timers 1024 + REG 16 + enable_REG 16）、constant ≥ 68（§12.3），即 passing ≤ 10632；黑盒 ram_10x89 r1/i1 |

## 5. 第一跑（commit c51b83fb，evidence/c51b83fb1067/，未入库）与 RTL 修正

- Queue10_GrantBuffer_Anon：**SUCCEEDED passing 205**（failing/unmatched 0，unread/constant 无，黑盒对象 2 = r/i 各 1 个 ram_10x89），与登记逐位相等。
- GrantBuffer：**FAILED failing 2**（未截断，limit 20）：`io_toReqArb_blockSinkReqEntrance_blockA_s1`、`io_toReqArb_blockMSHRReqEntrance`；
  passing 10677 / unread 1072 / constant 4 / unmatched 0。
- 根因（真失配，修 RTL 对齐 golden）：golden 的 pftRespQueue 门槛写成 `4'(pipeA + io_count) > 9 / > 8`（4 位截断加法），
  重写件用了 6 位宽加法 `>= 10 / >= 9`。可达状态下 io_count ≤ 10、pipeA ≤ 4 不回绕，UT 抓不到；但 io_count 来自 4 位指针，
  FM 不知道指针 ∈[0,9]，在 10..15 的不可达状态下两者不同。inline 时 FM 连 set_top 都过不去，所以这一处此前从未被比到。
  修法：`rtl/uncore/GrantBuffer.sv` 两条改成 golden 的 4 位截断形式（注释讲清原因）；UT 9 档（seed 1/7/42 × 0/random/<seed>017，200k）
  errors=0、每档 checks=14600000。登记（§4）不变。

## 6. 第二跑（commit 4e421fc8，evidence/4e421fc82194/，未入库）与 vmucp 加强登记

- Queue10_GrantBuffer_Anon：**SUCCEEDED passing 205**，与登记相等。
- GrantBuffer：native **SUCCEEDED**、failing 0 / unverified 0 / unmatched 0 / 黑盒 ram_10x89 r1/i1 / dont_verify 无，
  但 validator **PARTIAL（assembly_unread!=0）**：passing 10679、constant_reg 4、matched_nc 1072、unmatched_unread r1/i1。
  - matched_nc 1072 = timers 1024 + REG 16 + enable_REG 16 + grantQueue ram 存储第 7 位（task.param[2]）16。
  - unmatched_unread：golden `grantBuf_task_param_reg[2]` / 重写 `u_core/gb_param_reg[2]` —— D 通道 param 只有 2 位，
    两侧都只读 [1:0]，对称死位但名字不同、FM 不给未读点做签名配对。
  - §4 文字预测的"constant ≥ 68、passing ≤ 10632"**没有兑现**（实测 constant 4）：当时以为 grantQueue 存储里 grantid 高 4 位
    也会被判常量，FM 实际没有；照实记。
- 处置（均为证明加强，跑前登记）：
  1. `scripts/gen_l2_grantbuf.py` 钉点加 param[2] 一条（32 -> 33，fail-closed 字面计数），重生成 fm_pins_pre.tcl；
  2. `verif/fm_target_config/GrantBuffer.tcl` 按 vmucp standing rule 六条入白名单，Makefile `fm-GrantBuffer` 开 vmucp。
- 第三跑预测（★跑完不许改★）：Queue10_GrantBuffer_Anon 205 SUCCEEDED（不变）；GrantBuffer **passing 11752**
  （= 10679 + 1073）SUCCEEDED，failing / unverified / unmatched / unread 全 0，constant_reg 4，黑盒 ram_10x89 r1/i1；
  fm_predict 差额 11756 - 11752 = 4 = constant_reg 4。
