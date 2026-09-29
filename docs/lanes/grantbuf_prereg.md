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
