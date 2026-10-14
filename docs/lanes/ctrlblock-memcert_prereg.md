# ctrlblock-memcert lane 预登记 / 交回（codex 0230 问题 1）

- 分支：agent/ctrlblock-memcert（基于 main 7fea08787，认领 d14c4c042）
- 状态：**STOPPED at 步 2（M3 MANUAL）**。按任务书「任一步 MANUAL/FAIL 就 STOP 交回」与 0230 §问题1.2
  「任一项 MANUAL/FAIL 就 STOP，不得登记」，步 3–7 **未执行**：
  - verif/vendor_boundary.tsv **未改**（dt_pcTransType_160x2 未登记）；
  - scripts/proof_certificate.py **未改**；
  - 未做第 7 步 CtrlBlock 临时证书验证。
- 已完成并提交：步 1（M1 模板扩 nRmW + 正负测）。

## 步 1：M1 精确模板扩展（scripts/audit_ram_memory_model.py）

设计：
- `build_expected_body(..., nw, nr)` 新增 `nr`（读口数）。端口表按 firtool 形状 R0..R{nr-1}
  （每口 `input [aw-1:0] Rk_addr, input Rk_en, input Rk_clk, output [dw-1:0] Rk_data`）依次排在
  W0..W{nw-1} 之前；正文末尾按 R0..R{nr-1} 顺序各一条
  `assign Rk_data = Rk_en ? Memory[Rk_addr] : <dw>'bx;`。写口部分原样（已有：同一个
  `always @(posedge W0_clk)` 内 W0..W{nw-1} 顺序 `if (Wi_en & 1'h1) Memory[Wi_addr] <= Wi_data;`，后口胜出）。
- `m1_memory_only`：读口数从端口现读，`R<k>_addr` 编号必须恰为 0..N-1 连续，否则 `M1 FAIL: 读口编号`。
  比对仍是去注释、归一空白后的**整段逐字**相等（不是正则放行）；宏定义头仍按 sha256 对家族参照件。
- M2 端口集随之含 R0..R{nr-1}；报告形状行仅在 nr>1 时多打 `读口 N`（nr=1 时输出逐字节不变）。
- M3 **未扩**。

不变性证据：
- `python3 scripts/audit_ram_memory_model.py --check` 改前/改后输出 `diff` **逐字节相同**（rc=0，全部 AUDIT_PASS；
  覆盖 ram_40x47、diff_rat_state_bank_320x776、stateBankTags_320x3、ram_10x89、ram_78x15）。
- 上述 5 个 design 的单独审查（无 parent）输出改前/改后 `cmp` 逐字节相同。
- `scripts/test_audit_ram_manual_review.py` 全过（不变）。

新增正负测（scripts/test_audit_ram_memory_model.py，已在 gate_all「RAM 模型审查负测」里）：
- 正：1R1W 原模板不变 / 3R2W / 8R6W（dt_pcTransType 形状）
- 负：读口编号不连续 / 读口错接地址（R2 读 Memory[R0_addr]）/ 读 assign 乱序 / 少一条读 assign /
  读口夹在写口之后 / 多读口外加一条逻辑 / 写序颠倒（W1 先于 W0，破坏后口胜出）
- 结果：`=== test_audit_ram_memory_model: 25/25 ===`（原 15 + 新 10）

## 步 2：dt_pcTransType_160x2 M1/M2/M3 原始输出

命令（G1=/home/eda/xs-env/G1-canonical，Rob.sv impl sha256 f24abb526efcd0fdb445e58ed6fea368fdf0f96447026aac29e81f95aec8b9cb）：

    python3 scripts/audit_ram_memory_model.py dt_pcTransType_160x2 --parent-ref Rob.sv --parent-impl rtl/backend/Rob.sv
    # rc=1

结论：**M1 PASS，M2 PASS，M3 MANUAL（14 口 × 两侧 = 28 个地址全部 MANUAL）→ AUDIT_INCOMPLETE**。
CtrlBlock 层：dt_pcTransType_160x2 只在 Rob 内，CtrlBlock 两侧各例化 1 个 Rob（rob），allow 里两侧各 1 个
对象 r/i:/WORK/CtrlBlock/rob/dt_pcTransType_ext；M2 在 Rob 层已核，CtrlBlock 不另引入实例。

原始输出：

```
=== audit dt_pcTransType_160x2 ===
  golden  : /home/eda/xs-env/G1-canonical/golden-rtl/dt_pcTransType_160x2.sv
  sha256  : a47be472a7ebd4721e65ee6e9807c3389f712675f2afeed80ecf400d8adc80f9
  形状    : addr 8 位 / data 2 位 / depth 160 / 读口 8 / 写口 6 / 随机化 32 位
  越界余量: 2^8=256 - 160 = 96 个地址落在数组之外（★这正是 FMR_ELAB-147 的来源★）
  宏定义头: sha256=2b68dde00e97ee9a == 家族参照 ram_40x47.sv
  M1 PASS: 正文与 firtool 行为级 RAM 模板**逐字相等** —— 只有 1 个存储数组、1 个时钟写 always（6 个写口顺序非阻塞赋值，同址后口赢）、8 个组合读 assign（R0..R7），外加仿真专用随机初始化（SYNTHESIS 下不存在）；无状态机/无算术/无其它功能逻辑。
  M2 PASS: 两侧展开后各 1 个例化（ref [('dt_pcTransType_ext', 1)] / impl [('dt_pcTransType_ext', 1)]），每个实例端口集合与模块声明逐名相同（56 个），两侧每实例常量连接签名多重集相等；出现的常量连接 ['R0_en=1', 'R1_en=1', 'R2_en=1', 'R3_en=1', 'R4_en=1', 'R5_en=1', 'R6_en=1', 'R7_en=1']
  [Rob.dt_pcTransType_ext.R0_addr <- deqPtrVec_7_value] M3 MANUAL[ref]: 在 deqPtrVec_7_value 上找不到任何非阻塞赋值（fail-closed）
  M3 MANUAL[ref]: 地址 'deqPtrVec_7_value' 解析到 'deqPtrVec_7_value'，既不是环形指针也不是 `{1'b0, V} + (F ? K : 0)` 形态（fail-closed）
  [Rob.dt_pcTransType_ext.R1_addr <- deqPtrVec_6_value] M3 MANUAL[ref]: 在 deqPtrVec_6_value 上找不到任何非阻塞赋值（fail-closed）
  M3 MANUAL[ref]: 地址 'deqPtrVec_6_value' 解析到 'deqPtrVec_6_value'，既不是环形指针也不是 `{1'b0, V} + (F ? K : 0)` 形态（fail-closed）
  [Rob.dt_pcTransType_ext.R2_addr <- deqPtrVec_5_value] M3 MANUAL[ref]: 在 deqPtrVec_5_value 上找不到任何非阻塞赋值（fail-closed）
  M3 MANUAL[ref]: 地址 'deqPtrVec_5_value' 解析到 'deqPtrVec_5_value'，既不是环形指针也不是 `{1'b0, V} + (F ? K : 0)` 形态（fail-closed）
  [Rob.dt_pcTransType_ext.R3_addr <- deqPtrVec_4_value] M3 MANUAL[ref]: 在 deqPtrVec_4_value 上找不到任何非阻塞赋值（fail-closed）
  M3 MANUAL[ref]: 地址 'deqPtrVec_4_value' 解析到 'deqPtrVec_4_value'，既不是环形指针也不是 `{1'b0, V} + (F ? K : 0)` 形态（fail-closed）
  [Rob.dt_pcTransType_ext.R4_addr <- deqPtrVec_3_value] M3 MANUAL[ref]: 在 deqPtrVec_3_value 上找不到任何非阻塞赋值（fail-closed）
  M3 MANUAL[ref]: 地址 'deqPtrVec_3_value' 解析到 'deqPtrVec_3_value'，既不是环形指针也不是 `{1'b0, V} + (F ? K : 0)` 形态（fail-closed）
  [Rob.dt_pcTransType_ext.R5_addr <- deqPtrVec_2_value] M3 MANUAL[ref]: 在 deqPtrVec_2_value 上找不到任何非阻塞赋值（fail-closed）
  M3 MANUAL[ref]: 地址 'deqPtrVec_2_value' 解析到 'deqPtrVec_2_value'，既不是环形指针也不是 `{1'b0, V} + (F ? K : 0)` 形态（fail-closed）
  [Rob.dt_pcTransType_ext.R6_addr <- deqPtrVec_1_value] M3 MANUAL[ref]: 在 deqPtrVec_1_value 上找不到任何非阻塞赋值（fail-closed）
  M3 MANUAL[ref]: 地址 'deqPtrVec_1_value' 解析到 'deqPtrVec_1_value'，既不是环形指针也不是 `{1'b0, V} + (F ? K : 0)` 形态（fail-closed）
  [Rob.dt_pcTransType_ext.R7_addr <- deqPtrVec_0_value] M3 MANUAL[ref]: 在 deqPtrVec_0_value 上找不到任何非阻塞赋值（fail-closed）
  M3 MANUAL[ref]: 地址 'deqPtrVec_0_value' 解析到 'deqPtrVec_0_value'，既不是环形指针也不是 `{1'b0, V} + (F ? K : 0)` 形态（fail-closed）
  [Rob.dt_pcTransType_ext.W0_addr <- allocatePtrVec_5_value] M3 MANUAL[ref]: 在 allocatePtrVec_5_value 上找不到任何非阻塞赋值（fail-closed）
  M3 MANUAL[ref]: 地址 'allocatePtrVec_5_value' 解析到 "_GEN_4[3'({1'h0, 2'(_GEN + _GEN_0)} + {1'h0, 2'(_GEN_1 + 2'(_GEN_2 + _GEN_3))})]"，既不是环形指针也不是 `{1'b0, V} + (F ? K : 0)` 形态（fail-closed）
  [Rob.dt_pcTransType_ext.W1_addr <- allocatePtrVec_4_value] M3 MANUAL[ref]: 在 allocatePtrVec_4_value 上找不到任何非阻塞赋值（fail-closed）
  M3 MANUAL[ref]: 地址 'allocatePtrVec_4_value' 解析到 "_GEN_4[3'({1'h0, 2'(_GEN + _GEN_0)} + {1'h0, 2'(_GEN_1 + _GEN_2)})]"，既不是环形指针也不是 `{1'b0, V} + (F ? K : 0)` 形态（fail-closed）
  [Rob.dt_pcTransType_ext.W2_addr <- allocatePtrVec_3_value] M3 MANUAL[ref]: 在 allocatePtrVec_3_value 上找不到任何非阻塞赋值（fail-closed）
  M3 MANUAL[ref]: 地址 'allocatePtrVec_3_value' 解析到 "_GEN_4[{1'h0, 2'(_GEN + 2'(_GEN_0 + _GEN_1))}]"，既不是环形指针也不是 `{1'b0, V} + (F ? K : 0)` 形态（fail-closed）
  [Rob.dt_pcTransType_ext.W3_addr <- allocatePtrVec_2_value] M3 MANUAL[ref]: 在 allocatePtrVec_2_value 上找不到任何非阻塞赋值（fail-closed）
  M3 MANUAL[ref]: 地址 'allocatePtrVec_2_value' 解析到 "_GEN_4[{1'h0, 2'(_GEN + _GEN_0)}]"，既不是环形指针也不是 `{1'b0, V} + (F ? K : 0)` 形态（fail-closed）
  [Rob.dt_pcTransType_ext.W4_addr <- allocatePtrVec_1_value] M3 MANUAL[ref]: 在 allocatePtrVec_1_value 上找不到任何非阻塞赋值（fail-closed）
  M3 MANUAL[ref]: 地址 'allocatePtrVec_1_value' 解析到 "_GEN_4[{2'h0, _dispatchNum_T}]"，既不是环形指针也不是 `{1'b0, V} + (F ? K : 0)` 形态（fail-closed）
  [Rob.dt_pcTransType_ext.W5_addr <- enqPtrVec_0_value] M3 MANUAL[ref]: 在 enqPtrVec_0_value 上找不到任何非阻塞赋值（fail-closed）
  M3 MANUAL[ref]: 地址 'enqPtrVec_0_value' 解析到 'enqPtrVec_0_value'，既不是环形指针也不是 `{1'b0, V} + (F ? K : 0)` 形态（fail-closed）
  [Rob.dt_pcTransType_ext.R0_addr <- n_deqPtrVec_7_value] M3 MANUAL[impl]: 在 n_deqPtrVec_7_value 上找不到任何非阻塞赋值（fail-closed）
  M3 MANUAL[impl]: 地址 'n_deqPtrVec_7_value' 解析到 'n_deqPtrVec_7_value'，既不是环形指针也不是 `{1'b0, V} + (F ? K : 0)` 形态（fail-closed）
  [Rob.dt_pcTransType_ext.R1_addr <- n_deqPtrVec_6_value] M3 MANUAL[impl]: 在 n_deqPtrVec_6_value 上找不到任何非阻塞赋值（fail-closed）
  M3 MANUAL[impl]: 地址 'n_deqPtrVec_6_value' 解析到 'n_deqPtrVec_6_value'，既不是环形指针也不是 `{1'b0, V} + (F ? K : 0)` 形态（fail-closed）
  [Rob.dt_pcTransType_ext.R2_addr <- n_deqPtrVec_5_value] M3 MANUAL[impl]: 在 n_deqPtrVec_5_value 上找不到任何非阻塞赋值（fail-closed）
  M3 MANUAL[impl]: 地址 'n_deqPtrVec_5_value' 解析到 'n_deqPtrVec_5_value'，既不是环形指针也不是 `{1'b0, V} + (F ? K : 0)` 形态（fail-closed）
  [Rob.dt_pcTransType_ext.R3_addr <- n_deqPtrVec_4_value] M3 MANUAL[impl]: 在 n_deqPtrVec_4_value 上找不到任何非阻塞赋值（fail-closed）
  M3 MANUAL[impl]: 地址 'n_deqPtrVec_4_value' 解析到 'n_deqPtrVec_4_value'，既不是环形指针也不是 `{1'b0, V} + (F ? K : 0)` 形态（fail-closed）
  [Rob.dt_pcTransType_ext.R4_addr <- n_deqPtrVec_3_value] M3 MANUAL[impl]: 在 n_deqPtrVec_3_value 上找不到任何非阻塞赋值（fail-closed）
  M3 MANUAL[impl]: 地址 'n_deqPtrVec_3_value' 解析到 'n_deqPtrVec_3_value'，既不是环形指针也不是 `{1'b0, V} + (F ? K : 0)` 形态（fail-closed）
  [Rob.dt_pcTransType_ext.R5_addr <- n_deqPtrVec_2_value] M3 MANUAL[impl]: 在 n_deqPtrVec_2_value 上找不到任何非阻塞赋值（fail-closed）
  M3 MANUAL[impl]: 地址 'n_deqPtrVec_2_value' 解析到 'n_deqPtrVec_2_value'，既不是环形指针也不是 `{1'b0, V} + (F ? K : 0)` 形态（fail-closed）
  [Rob.dt_pcTransType_ext.R6_addr <- n_deqPtrVec_1_value] M3 MANUAL[impl]: 在 n_deqPtrVec_1_value 上找不到任何非阻塞赋值（fail-closed）
  M3 MANUAL[impl]: 地址 'n_deqPtrVec_1_value' 解析到 'n_deqPtrVec_1_value'，既不是环形指针也不是 `{1'b0, V} + (F ? K : 0)` 形态（fail-closed）
  [Rob.dt_pcTransType_ext.R7_addr <- n_deqPtrVec_0_value] M3 MANUAL[impl]: 在 n_deqPtrVec_0_value 上找不到任何非阻塞赋值（fail-closed）
  M3 MANUAL[impl]: 地址 'n_deqPtrVec_0_value' 解析到 'n_deqPtrVec_0_value'，既不是环形指针也不是 `{1'b0, V} + (F ? K : 0)` 形态（fail-closed）
  [Rob.dt_pcTransType_ext.W0_addr <- n_allocatePtrVec_5_value] M3 MANUAL[impl]: 在 n_allocatePtrVec_5_value 上找不到任何非阻塞赋值（fail-closed）
  M3 MANUAL[impl]: 地址 'n_allocatePtrVec_5_value' 解析到 'n_allocatePtrVec_5_value'，既不是环形指针也不是 `{1'b0, V} + (F ? K : 0)` 形态（fail-closed）
  [Rob.dt_pcTransType_ext.W1_addr <- n_allocatePtrVec_4_value] M3 MANUAL[impl]: 在 n_allocatePtrVec_4_value 上找不到任何非阻塞赋值（fail-closed）
  M3 MANUAL[impl]: 地址 'n_allocatePtrVec_4_value' 解析到 'n_allocatePtrVec_4_value'，既不是环形指针也不是 `{1'b0, V} + (F ? K : 0)` 形态（fail-closed）
  [Rob.dt_pcTransType_ext.W2_addr <- n_allocatePtrVec_3_value] M3 MANUAL[impl]: 在 n_allocatePtrVec_3_value 上找不到任何非阻塞赋值（fail-closed）
  M3 MANUAL[impl]: 地址 'n_allocatePtrVec_3_value' 解析到 'n_allocatePtrVec_3_value'，既不是环形指针也不是 `{1'b0, V} + (F ? K : 0)` 形态（fail-closed）
  [Rob.dt_pcTransType_ext.W3_addr <- n_allocatePtrVec_2_value] M3 MANUAL[impl]: 在 n_allocatePtrVec_2_value 上找不到任何非阻塞赋值（fail-closed）
  M3 MANUAL[impl]: 地址 'n_allocatePtrVec_2_value' 解析到 'n_allocatePtrVec_2_value'，既不是环形指针也不是 `{1'b0, V} + (F ? K : 0)` 形态（fail-closed）
  [Rob.dt_pcTransType_ext.W4_addr <- n_allocatePtrVec_1_value] M3 MANUAL[impl]: 在 n_allocatePtrVec_1_value 上找不到任何非阻塞赋值（fail-closed）
  M3 MANUAL[impl]: 地址 'n_allocatePtrVec_1_value' 解析到 'n_allocatePtrVec_1_value'，既不是环形指针也不是 `{1'b0, V} + (F ? K : 0)` 形态（fail-closed）
  [Rob.dt_pcTransType_ext.W5_addr <- n_enqPtrVec_0_value] M3 MANUAL[impl]: 在 n_enqPtrVec_0_value 上找不到任何非阻塞赋值（fail-closed）
  M3 MANUAL[impl]: 地址 'n_enqPtrVec_0_value' 解析到 'n_enqPtrVec_0_value'，既不是环形指针也不是 `{1'b0, V} + (F ? K : 0)` 形态（fail-closed）
  => AUDIT_INCOMPLETE  （入表只是允许两侧对称黑盒；转绿仍须 clean native FM 结果）
```

## M3 为什么 MANUAL（事实，供裁定；本 lane 不自行发明处置）

现有 M3 只认两种形态：A=本父级内环形指针寄存器（复位常量 + 唯一 +1 + ==depth-1 回卷）；
B=地址是**本父级 input 端口**的纯函数 `{1'b0,V}+(F?K:0)` + 接口契约。dt_pcTransType 的 14 个地址口都不是：

| 口 | ref（G1 Rob.sv） | impl（rtl/backend/Rob.sv） |
|---|---|---|
| R0..R7 | `deqPtrVec_{7..0}_value` = 子模块 **NewRobDeqPtrWrapper**（deqPtrGenModule）的 `io_out_k_value` 输出 | `n_deqPtrVec_{7..0}_value`，同一 golden 子模块输出（两侧同源 golden elaborate） |
| W5 | `enqPtrVec_0_value` = 子模块 **RobEnqPtrWrapper**（enqPtrGenModule）输出 | `n_enqPtrVec_0_value`，同一 golden 子模块输出 |
| W0..W4 | `allocatePtrVec_{5..1}_value = _GEN_4[<firstUop 计数>]`，`_GEN_4` 是 {enqPtrVec_0..5, enqPtrVec_0, enqPtrVec_0} 的 8 选 1 | `n_allocatePtrVec_{5..1}_value` = xs_Rob_core 输出，`allocatePtrValue[i]` 在 enqPtrValue[0..5] 中选择（默认 enqPtrValue[0]） |

人读层面的可达范围论证（**未机器复核**，不构成 M3 PASS）：
- NewRobDeqPtrWrapper：deqPtrVec_k 复位 k（0..7），唯一更新是 `commitDeqPtrVec_k`，由
  `{deqPtrVec_0_value[7:3],3'h0} + n` 再「≥160 则 −160」（`10'(... - 10'hA0)` 的符号位选择）得到，
  无任何外部 robIdx 输入参与 → 若机器化，是子模块内部的闭合模 160 归纳。
- RobEnqPtrWrapper：复位 0..5；redirect 时由**输入** `io_redirect_bits_robIdx_value` 加 0/1..6 再模 160；
  否则自身 + 入队数再模 160 → 需要与 diff_rat 同款的接口契约 `robIdx.value<160`（CircularQueuePtr(RobSize=160)）。
- allocatePtrVec：在上述 enqPtrVec 值之间做选择，范围 ⊆ enqPtrVec 的并。

需要裁定的边界（0230 未覆盖）：M3 是否允许新形态「地址 = 两侧同源 golden 子模块输出（或其选择），
范围由该子模块内部的模 160 归纳 / 输入契约成立」，以及该形态是否要求机器复核（在子模块正文上做
带模回卷的归纳，现有 A/B 都不认 `x - 160` 的符号位回卷），还是可以走人工复核出口
（现有 MANUAL_REVIEW 出口只放 impl 侧，ref 侧必须机器 PASS，此处 ref 侧同样 MANUAL，出口不适用）。

## 步 3–7

未执行（STOP）。vendor_boundary 行、proof_certificate.py 改动、证书正负测、第 7 步 CtrlBlock 临时验证均无。

## gate_all（步 1 提交上跑，供集成者参考；步 6 本身因 STOP 未达）

    mkdir -p /home/eda/xs-env/tmp-cm
    TMPDIR=/home/eda/xs-env/tmp-cm bash scripts/gate_all.sh < /dev/null
    GATE_COMMIT=aafef4a8a4  GATE_RC=1

- 本 lane 相关闸全绿：「RAM 模型审查负测」PASS（25/25）、「RAM 模型审查复算」PASS（--check 输出与改前逐字节相同）。
- **唯一红**：「receipt 收录表复算」（`gen_receipt_harvest.py --check`）。与本 lane 改动无关，是仓外输入漂移：
  docs/receipt_harvest.tsv 里 1542 行的 evidence 键是 lane worktree `xsv2-proof-Xws7NB:<run>`，该 worktree
  已不在 `git worktree list` 里（被移除），`collect(only=listed)` 只能找回 318 行 → 渲染不等。
  gen_receipt_harvest.py 不读 audit_ram_memory_model.py / 其测试 / docs/lanes。修法是重生成该派生表，
  本 lane 任务书禁止改派生表，故未动，留给集成者。
