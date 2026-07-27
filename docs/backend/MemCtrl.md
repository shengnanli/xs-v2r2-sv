# MemCtrl（访存预测表控制/更新流水级）

## 功能
MemCtrl 是 SSIT（Store Set ID Table）与 WaitTable 的持有者兼「更新路径打拍级」。它把
`memPredUpdate` / `csrCtrl` 输入寄存一拍后分发给 SSIT / WaitTable 的更新端口；读端口
（mdpFoldPcVec）直连 SSIT。

**MemCtrl 本身无输出端口**——SSIT/WaitTable 的读结果不经 MemCtrl 边界返回（在更外层消费）。
故本层唯一逻辑 = 7 个更新流水寄存器：
`ssit_update_REG_{valid,ldpc,stpc}` + `waittable_update_REG_{valid,waddr}` +
`{ssit,waittable}_csrCtrl_REG_lvpred_timeout`。

## 文件
- 可读核：`rtl/backend/MemCtrl_core.sv`（`xs_MemCtrl`，7 更新流水寄存器）
- 包装层：`rtl/backend/MemCtrl_wrapper.sv`（例化 u_core + SSIT/WaitTable，读同一份 golden 源）
- allow：`verif/signoff/allow/MemCtrl.json`（空——strict 全等价，无黑盒）
- UT：`verif/ut/MemCtrl/`（层次引用比对 7 个流水寄存器）

## FM 签核（strict SUCCEEDED，SSIT/WaitTable 两侧真 elaborate，codex_0072 收口）
**native strict SUCCEEDED**：passing **16634**（全 DFF）/ failing 0 / unmatched 0(0) /
unread 0 / 无 dont_verify / 无 interface_only 黑盒。fm.log `FM_RESULT: Verification SUCCEEDED`，
native `Verification SUCCEEDED`，最终汇总表仅 Passing/Failing 行 = 16634/0。

### SSIT/WaitTable 两侧真 elaborate（非黑盒）
SSIT 与 WaitTable 均为**纯寄存器逻辑**（无厂商 SRAM 宏）。FM 两侧读**同一份 golden 源**：
`SSIT → SyncDataModuleTemplate__1024entry{,_1} → DataModule__64entry{,_16}`，`WaitTable` 为叶子。
FM 日志可见 `Elaborating design SSIT` / `Elaborating design WaitTable` 各出现 2 次（ref + impl），
证明两侧真 elaborate 为设计而非黑盒。这是完整对称子树。

### cone-dead 寄存器 = 对称 matched-unread → vmucp 实比证等价（非 waive）
在 MemCtrl 这个 config 下，SSIT 的 read 输出被 firtool 裁剪（读结果不出 MemCtrl 边界）→ 下游
是 cone-dead 子树，大量「写不读」的内部寄存器。因两侧读同一份 golden 源，这些死寄存器构成
**完美对称双射**：`r:/WORK/MemCtrl/ssit/REG_reg[N]` ↔ `i:/WORK/MemCtrl/ssit/REG_reg[N]`
（`waittable` 同理）。设 `FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=true`（vmucp）令 FM
**实际比较**这些对称死寄存器证等价——**不是 waiver，true 是要求 FM 证明更多**——最终 0 unread。
7 个更新流水寄存器 glue：`r:ssit_io_*_REG` ↔ `i:u_core/ssit_*_REG`。

### 白名单（main-owned，本 worktree 已改，须 main 同步）
vmucp 精确白名单须含 MemCtrl，已在 worktree 加两处：
- `scripts/fm_eq.tcl`（vmucp 白名单集）
- `scripts/sidecar/run_signoff_target.sh`（case 白名单）

MemCtrl 是 aux_target（非 305 分母），权威 gate = `make -C verif/ut/MemCtrl fm`。
不再走 assembly / interface_only（已从 assembly_depends.tsv 移除 MemCtrl 行）。

## UT
seed 1/7/42 各 199992 checks，errors 0（层次引用比对 golden vs 可读核的 7 个流水寄存器）。
