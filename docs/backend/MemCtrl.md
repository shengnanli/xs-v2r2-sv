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
- 包装层：`rtl/backend/MemCtrl_wrapper.sv`（例化 u_core + SSIT/WaitTable）
- allow：`verif/signoff/allow/MemCtrl.json`（SSIT/WaitTable interface_only）
- UT：`verif/ut/MemCtrl/`（层次引用比对 7 个流水寄存器）

## FM 签核
**assembly SUCCEEDED**：passing 104（含 36 DFF = 7 个更新流水寄存器逐位）/ failing 0 /
unmatched 0 / unread 0。SSIT + WaitTable 声明为对称 `interface_only` 黑盒（`FM_INTERFACE_ONLY`），
其输入成为等价边界——可读核 7 个流水寄存器驱动这些黑盒输入，FM 逐位证明 == golden。

### 为什么不能做 strict 全等价（诚实定级）
若把 SSIT/WaitTable 两侧 elaborate（golden==golden），FM 报 **9252 unread**（strict PARTIAL）：
SSIT（~3087 reg）/ WaitTable（~1026 reg）/ SyncDataModuleTemplate 的全部内部寄存器在
MemCtrl 这个 config 下**无观测输出**（SSIT 的 read 输出被 firtool 裁剪成写入 `s2_*` 寄存器
后即终止，不出 SSIT 边界）→ 整个下游是 cone-dead 子树。这与 StorePipe 的 DCE-collapsed
情形同类：golden 自身携带大量 cone-dead 寄存器。

∴ MemCtrl 只能在 assembly 模式证明本层 glue（7 流水寄存器）。SSIT/WaitTable 非 305 target，
且在此 config 下本身也无法做有意义的独立等价签核（同样全 cone-dead）。**assembly 条件挂起**
（assembly_depends.tsv），除非 main 接受 SSIT/WaitTable 为文档化 cone-dead 边界。

## UT
seed 1/7/42 各 199992 checks，errors 0（层次引用比对 golden vs 可读核的 7 个流水寄存器）。
