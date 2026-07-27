# RenameTableWrapper（重命名表装配壳）

## 功能
纯 wiring 壳（0 寄存器）：计算 6 个提交/行走端口共享的 arch/spec 写使能/地址/数据派生信号，
分发给 5 个 RenameTable 实例：
- `intRat`（RenameTable，整数）
- `fpRat`（RenameTable_1，浮点）
- `vecRat`（RenameTable_2，向量）
- `v0Rat` / `vlRat`（RenameTable_3，v0/vl）

派生信号（每端口 p）：
- `archWen_T[p] = isCommit & commitValid_p`；`intArchWen[p] = archWen_T[p] & info_p_rfWen`
- `specWen_T[p] = isWalk & walkValid_p`
- 写使能 `= renamePorts_p_wen | specWen_T[p] & info_p_<xxx>Wen`
- 写地址 `= renamePorts_p_wen ? renamePorts_p_addr : info_p_ldest`
- 写数据 `= renamePorts_p_wen ? renamePorts_p_data : info_p_pdest`

逻辑全在各 RenameTable 子里；本层只做派生 + 分发连线。

## 文件
- 可读核：`rtl/backend/RenameTableWrapper_core.sv`（`xs_RenameTableWrapper`，含 5 实例）
- 包装层：`rtl/backend/RenameTableWrapper_wrapper.sv`
- 生成器：`scripts/gen_renametablewrapper.py`（机械转 golden wiring：去 SYNTHESIS 断言 +
  去死 wire `_GEN_17..28`，其余派生 wire + 5 实例连线原样保留）
- allow：`verif/signoff/allow/RenameTableWrapper.json`（5 实例 interface_only）
- UT：`verif/ut/RenameTableWrapper/`（tb 由 `gen_tb.py` 生成，比对 193 输出端口）

## FM 签核
**assembly SUCCEEDED**：passing 18440（16938 BBPin + 1502 Port）/ failing 0 / unmatched 0 /
unread 0，无 dont_verify。5 个 RenameTable 实例声明为对称 `interface_only` 黑盒；FM 逐位证明
所有 18440 个黑盒输入 pin + 输出端口的分发连线 == golden。

### 依赖（条件挂起）
- `RenameTable`（intRat 的类型）：305 target，已 **SIGNOFF_PASS**（绿）。
- `RenameTable_1/2/3`（fpRat/vecRat/v0Rat/vlRat 的类型）：非 305 参数变体（同 RenameTable
  结构，不同端口宽度），**未独立签核**。

∴ 父级 assembly glue 已证 SUCCEEDED，但依赖闭包未闭合 → **条件挂起**（assembly_depends.tsv），
直到 RenameTable_1/2/3 各自 SIGNOFF_PASS（同 Slice_1/2/3、Directory_1/2/3 变体族的处理）。

## UT
seed 1/7/42（大设计，编译 ~270s）：checks 199992，errors 0。
