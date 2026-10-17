# ctrlblock-memcert lane 预登记 / 交回（codex 0230 问题 1；codex 0232 形态 C）

- 分支：agent/ctrlblock-memcert（基于 main 7fea08787，认领 d14c4c042）
- 第一轮（本文件下半部「第一轮」各节）：步 2 M3 MANUAL → STOP（0231）。
- 第二轮（codex 0232 GO_SCOPED_SHAPE_C）：步 2–6 完成；**步 7 STOP**——CtrlBlock 证书在新 validator 下
  interface_only 并集判据已过，但被 0230 未覆盖的另一条判据（impl 闭包挂 golden 必须是 FM target / MC 登记）
  拦下，详见「第二轮 · 步 7」。

## 第一轮 · 步 1：M1 精确模板扩展（scripts/audit_ram_memory_model.py）

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

## 第一轮 · 步 2：dt_pcTransType_160x2 M1/M2/M3 原始输出（形态 C 之前）

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


---

# 第二轮（codex 0232 GO_SCOPED_SHAPE_C）

## 步 2'：M3 形态 C（scripts/audit_ram_memory_model.py，「M3 形态 C」一节）

范围：只对 `SHAPE_C` 表里写死的 `dt_pcTransType_160x2 -> Rob -> {NewRobDeqPtrWrapper, RobEnqPtrWrapper}` 生效；
design 在表里时 M3 只走形态 C（A/B 不回退）。不是通用数据流证明器：

- 表达式只认 firtool / 可读核实际出现的子集（数字、标识符、位选/段选、拼接、`N'()`、`$signed`、一元/二元算术与比较、
  三元）；`'bx` 字面量、认不出的 token / 语句（case、for、阻塞赋值、带下标左值）一律 MANUAL。
- 位宽语义按 IEEE 1800 context-determined 规则建模：`N'(e)` 先按 max(N, 自宽) 求值再截断；`$signed` 比较按补码；
  拼接 / 选择 / 比较操作数 self-determined。
- 子实例机器核对（0232 第 2 条）：两侧各恰好 1 个实例、无 `#()` 参数覆盖、`.clock(clock)` / `.reset(reset)`；
  子模块 G1 sha256 写死（NewRobDeqPtrWrapper 03a69b65…bf5、RobEnqPtrWrapper 3874e460…435）；impl 侧实例类型
  解析到 parent_impl 文件或 RTL_SRCS 里的同名定义即判「单侧 wrapper」MANUAL；当前闭包核对：
  `verif/ut/CtrlBlock/closure.mk` 两者都在 GOLDEN_CLOSURE_SHARED、不在 REPLACED，`verif/ut/CtrlBlock/Makefile`
  RTL_SRCS 里无同名 module；子模块去掉 `ifdef ENABLE_INITIAL_REG_` 后不得残留任何 `ifdef/`ifndef。
- 子模块范围证明（0232 第 3 条）：output 沿唯一组合定义追到寄存器；取同地址宽（8 位）寄存器闭包 S 做**联合归纳**：
  基例 = `if (reset)` 支路逐个赋常量且 ∈[0,159]；归纳步 = 语句树**每一条**非 reset 路径（含不赋值的保持路径）
  在「S 内 ∈[0,159]、其余寄存器与全部 input 取全宽」下穷举求值。进入 `+`/`-` 运算锥的叶子逐值枚举（保留
  `x>=160 ? x-160 : x` 的相关性），只出现在条件/选择里的叶子取全域、三元可真可假时两支取并（过近似 ⇒ sound）。
  组合爆炸用「私有切点」：组合线 W 的叶子全被枚举、且只经 W 进入表达式时，改枚举 W 的值集合（精确、sound）。
  三元叶逐支报告取值区间或「不可达」。
- 选择闭包（0232 第 4 条）：ref 侧 `_GEN_4[idx]`（拼接 8 元素、3 位下标）逐个下标取值、下标越出声明范围即 MANUAL；
  impl 侧只认 always_comb 里「`ARR[i] = SRC[0];` + `for k: if (SEL[i]==W'(k)) ARR[i] = SRC[k];`」这一个精确模式
  （默认先无条件赋 ⇒ 无 X/default 漏枚举；候选下标须在 SRC 声明范围内；ARR 只在此处被赋值），`SRC[k] = NAME;`
  必须常量下标、唯一、在 always_comb 里。
- 跨层次 ≤ 2（0232 第 4 条：parent→可读核→回 parent→G1 子模块），带环检测。
- 结论只有 PASS_C（无条件）/ FAIL（含反例）/ MANUAL（含未识别的最小表达式）；本轮**没有**引入接口契约。
- 记录：MANUAL_REVIEW_PARENTS / MANUAL_REVIEW_GOLDEN 新增 dt_pcTransType_160x2，父级范围只限
  `CtrlBlock` 的 `rob/dt_pcTransType_ext`（fm_verdict 的 ram_parent_scope 闸据此执行，fm_verdict 未改）；
  verif/ram_model_parents.tsv 增一行（`--check` 复算）。

enq 的无条件结论机器复核了 codex 的推算：redirect 支路对**任意 8 位** robIdx，`enqPtrVec_k` 取值 [0,101]∪…⊆[0,159]
（k=5 的 wrap 叶最大 101 = 255+6−160）；正常推进 `{1'b0,v}+_GEN_0`（_GEN_0∈[0,6]）回卷后 ∈[0,159]。deq 从 reset 0..7
出发，每条 commit advance / wrap 分支 ∈[0,159]，exception robIdx 只出现在比较里。

可复跑命令（rc=0，约 25 s；输出与 PYTHONHASHSEED 无关，已用两个种子逐字节比对）：

    python3 scripts/audit_ram_memory_model.py dt_pcTransType_160x2 --parent-ref Rob.sv --parent-impl rtl/backend/Rob.sv

每口结论（14 口 × 两侧，全部 **PASS_C 无条件，未用接口契约**）：

| 口 | ref 来源 | impl 来源 | 结论 |
|---|---|---|---|
| R0..R7 | NewRobDeqPtrWrapper.io_out_{7..0}_value | 同 | PASS_C / PASS_C |
| W0..W4 | allocatePtrVec_{5..1} = `_GEN_4[…]`（RobEnqPtrWrapper.io_out_0..5 的 8 选 1） | xs_Rob_core.allocatePtrValue[5..1]（默认 + 逐项覆盖，候选 enqPtrValue[0..5] = RobEnqPtrWrapper.io_out_0..5） | PASS_C / PASS_C |
| W5 | RobEnqPtrWrapper.io_out_0_value | 同 | PASS_C / PASS_C |

两侧每口的子模块来源集合逐口相等（脚本核对）。原始输出全文：

```
=== audit dt_pcTransType_160x2 ===
  golden  : /home/eda/xs-env/G1-canonical/golden-rtl/dt_pcTransType_160x2.sv
  sha256  : a47be472a7ebd4721e65ee6e9807c3389f712675f2afeed80ecf400d8adc80f9
  形状    : addr 8 位 / data 2 位 / depth 160 / 读口 8 / 写口 6 / 随机化 32 位
  越界余量: 2^8=256 - 160 = 96 个地址落在数组之外（★这正是 FMR_ELAB-147 的来源★）
  宏定义头: sha256=2b68dde00e97ee9a == 家族参照 ram_40x47.sv
  M1 PASS: 正文与 firtool 行为级 RAM 模板**逐字相等** —— 只有 1 个存储数组、1 个时钟写 always（6 个写口顺序非阻塞赋值，同址后口赢）、8 个组合读 assign（R0..R7），外加仿真专用随机初始化（SYNTHESIS 下不存在）；无状态机/无算术/无其它功能逻辑。
  M2 PASS: 两侧展开后各 1 个例化（ref [('dt_pcTransType_ext', 1)] / impl [('dt_pcTransType_ext', 1)]），每个实例端口集合与模块声明逐名相同（56 个），两侧每实例常量连接签名多重集相等；出现的常量连接 ['R0_en=1', 'R1_en=1', 'R2_en=1', 'R3_en=1', 'R4_en=1', 'R5_en=1', 'R6_en=1', 'R7_en=1']
  M3 形态C 闭包核对: verif/ut/CtrlBlock/closure.mk: ['NewRobDeqPtrWrapper', 'RobEnqPtrWrapper'] 均在 GOLDEN_CLOSURE_SHARED（两侧同读 G1），verif/ut/CtrlBlock/Makefile RTL_SRCS 无同名定义
  M3 形态C 子实例: ['NewRobDeqPtrWrapper', 'RobEnqPtrWrapper'] 两侧各 1 个、无参数覆盖、clock/reset 接父级
    [R0_addr ref <- deqPtrVec_7_value] M3 PASS_C[ref]: ∈ [0,159] ⊆ [0,159]（无条件，未用接口契约）；来源 [('NewRobDeqPtrWrapper', 'io_out_7_value')]
        · deqPtrVec_7_value <- NewRobDeqPtrWrapper(deqPtrGenModule).io_out_7_value：NewRobDeqPtrWrapper.io_out_7_value ∈ [0,159]（联合归纳寄存器 ['deqPtrVec_0_value', 'deqPtrVec_7_value']；deqPtrVec_0_value: 基例 [0]；路径0[_deqPtrVec_next_T_4]: 穷举 160 组（枚举 ['deqPtrVec_0_value']）值域 [0,159]；三元叶 L0=不可达 L1=[0,152] L2=不可达 L3=[1,153] L4=不可达 L5=[2,154] L6=不可达 L7=[3,155] L8=不可达 L9=[4,156] L10=不可达 L11=[5,157] L12=不可达 L13=[6,158] L14=不可达 L15=[7,159] L16=[0,0] L17=[8,152] L18=[0,159]；路径1[!_deqPtrVec_next_T_4]: 保持（归纳假设） || deqPtrVec_7_value: 基例 [7]；路径0[_deqPtrVec_next_T_4]: 穷举 160 组（枚举 ['deqPtrVec_0_value']）值域 [0,159]；三元叶 L0=不可达 L1=[7,159] L2=[0,0] L3=[8,152] L4=[1,1] L5=[9,153] L6=[2,2] L7=[10,154] L8=[3,3] L9=[11,155] L10=[4,4] L11=[12,156] L12=[5,5] L13=[13,157] L14=[6,6] L15=[14,158] L16=[7,7] L17=[15,159] L18=[0,159]；路径1[!_deqPtrVec_next_T_4]: 保持（归纳假设））
        · Rob: deqPtrVec_7_value 穷举 1 组（枚举 []）值域 [0,159]
    [R0_addr impl <- n_deqPtrVec_7_value] M3 PASS_C[impl]: ∈ [0,159] ⊆ [0,159]（无条件，未用接口契约）；来源 [('NewRobDeqPtrWrapper', 'io_out_7_value')]
        · n_deqPtrVec_7_value <- NewRobDeqPtrWrapper(deqPtrGenModule).io_out_7_value：NewRobDeqPtrWrapper.io_out_7_value ∈ [0,159]（联合归纳寄存器 ['deqPtrVec_0_value', 'deqPtrVec_7_value']；deqPtrVec_0_value: 基例 [0]；路径0[_deqPtrVec_next_T_4]: 穷举 160 组（枚举 ['deqPtrVec_0_value']）值域 [0,159]；三元叶 L0=不可达 L1=[0,152] L2=不可达 L3=[1,153] L4=不可达 L5=[2,154] L6=不可达 L7=[3,155] L8=不可达 L9=[4,156] L10=不可达 L11=[5,157] L12=不可达 L13=[6,158] L14=不可达 L15=[7,159] L16=[0,0] L17=[8,152] L18=[0,159]；路径1[!_deqPtrVec_next_T_4]: 保持（归纳假设） || deqPtrVec_7_value: 基例 [7]；路径0[_deqPtrVec_next_T_4]: 穷举 160 组（枚举 ['deqPtrVec_0_value']）值域 [0,159]；三元叶 L0=不可达 L1=[7,159] L2=[0,0] L3=[8,152] L4=[1,1] L5=[9,153] L6=[2,2] L7=[10,154] L8=[3,3] L9=[11,155] L10=[4,4] L11=[12,156] L12=[5,5] L13=[13,157] L14=[6,6] L15=[14,158] L16=[7,7] L17=[15,159] L18=[0,159]；路径1[!_deqPtrVec_next_T_4]: 保持（归纳假设））
        · Rob: n_deqPtrVec_7_value 穷举 1 组（枚举 []）值域 [0,159]
    [R1_addr ref <- deqPtrVec_6_value] M3 PASS_C[ref]: ∈ [0,159] ⊆ [0,159]（无条件，未用接口契约）；来源 [('NewRobDeqPtrWrapper', 'io_out_6_value')]
        · deqPtrVec_6_value <- NewRobDeqPtrWrapper(deqPtrGenModule).io_out_6_value：NewRobDeqPtrWrapper.io_out_6_value ∈ [0,159]（联合归纳寄存器 ['deqPtrVec_0_value', 'deqPtrVec_6_value']；deqPtrVec_0_value: 基例 [0]；路径0[_deqPtrVec_next_T_4]: 穷举 160 组（枚举 ['deqPtrVec_0_value']）值域 [0,159]；三元叶 L0=不可达 L1=[0,152] L2=不可达 L3=[1,153] L4=不可达 L5=[2,154] L6=不可达 L7=[3,155] L8=不可达 L9=[4,156] L10=不可达 L11=[5,157] L12=不可达 L13=[6,158] L14=不可达 L15=[7,159] L16=[0,0] L17=[8,152] L18=[0,159]；路径1[!_deqPtrVec_next_T_4]: 保持（归纳假设） || deqPtrVec_6_value: 基例 [6]；路径0[_deqPtrVec_next_T_4]: 穷举 160 组（枚举 ['deqPtrVec_0_value']）值域 [0,159]；三元叶 L0=不可达 L1=[6,158] L2=不可达 L3=[7,159] L4=[0,0] L5=[8,152] L6=[1,1] L7=[9,153] L8=[2,2] L9=[10,154] L10=[3,3] L11=[11,155] L12=[4,4] L13=[12,156] L14=[5,5] L15=[13,157] L16=[6,6] L17=[14,158] L18=[0,159]；路径1[!_deqPtrVec_next_T_4]: 保持（归纳假设））
        · Rob: deqPtrVec_6_value 穷举 1 组（枚举 []）值域 [0,159]
    [R1_addr impl <- n_deqPtrVec_6_value] M3 PASS_C[impl]: ∈ [0,159] ⊆ [0,159]（无条件，未用接口契约）；来源 [('NewRobDeqPtrWrapper', 'io_out_6_value')]
        · n_deqPtrVec_6_value <- NewRobDeqPtrWrapper(deqPtrGenModule).io_out_6_value：NewRobDeqPtrWrapper.io_out_6_value ∈ [0,159]（联合归纳寄存器 ['deqPtrVec_0_value', 'deqPtrVec_6_value']；deqPtrVec_0_value: 基例 [0]；路径0[_deqPtrVec_next_T_4]: 穷举 160 组（枚举 ['deqPtrVec_0_value']）值域 [0,159]；三元叶 L0=不可达 L1=[0,152] L2=不可达 L3=[1,153] L4=不可达 L5=[2,154] L6=不可达 L7=[3,155] L8=不可达 L9=[4,156] L10=不可达 L11=[5,157] L12=不可达 L13=[6,158] L14=不可达 L15=[7,159] L16=[0,0] L17=[8,152] L18=[0,159]；路径1[!_deqPtrVec_next_T_4]: 保持（归纳假设） || deqPtrVec_6_value: 基例 [6]；路径0[_deqPtrVec_next_T_4]: 穷举 160 组（枚举 ['deqPtrVec_0_value']）值域 [0,159]；三元叶 L0=不可达 L1=[6,158] L2=不可达 L3=[7,159] L4=[0,0] L5=[8,152] L6=[1,1] L7=[9,153] L8=[2,2] L9=[10,154] L10=[3,3] L11=[11,155] L12=[4,4] L13=[12,156] L14=[5,5] L15=[13,157] L16=[6,6] L17=[14,158] L18=[0,159]；路径1[!_deqPtrVec_next_T_4]: 保持（归纳假设））
        · Rob: n_deqPtrVec_6_value 穷举 1 组（枚举 []）值域 [0,159]
    [R2_addr ref <- deqPtrVec_5_value] M3 PASS_C[ref]: ∈ [0,159] ⊆ [0,159]（无条件，未用接口契约）；来源 [('NewRobDeqPtrWrapper', 'io_out_5_value')]
        · deqPtrVec_5_value <- NewRobDeqPtrWrapper(deqPtrGenModule).io_out_5_value：NewRobDeqPtrWrapper.io_out_5_value ∈ [0,159]（联合归纳寄存器 ['deqPtrVec_0_value', 'deqPtrVec_5_value']；deqPtrVec_0_value: 基例 [0]；路径0[_deqPtrVec_next_T_4]: 穷举 160 组（枚举 ['deqPtrVec_0_value']）值域 [0,159]；三元叶 L0=不可达 L1=[0,152] L2=不可达 L3=[1,153] L4=不可达 L5=[2,154] L6=不可达 L7=[3,155] L8=不可达 L9=[4,156] L10=不可达 L11=[5,157] L12=不可达 L13=[6,158] L14=不可达 L15=[7,159] L16=[0,0] L17=[8,152] L18=[0,159]；路径1[!_deqPtrVec_next_T_4]: 保持（归纳假设） || deqPtrVec_5_value: 基例 [5]；路径0[_deqPtrVec_next_T_4]: 穷举 160 组（枚举 ['deqPtrVec_0_value']）值域 [0,159]；三元叶 L0=不可达 L1=[5,157] L2=不可达 L3=[6,158] L4=不可达 L5=[7,159] L6=[0,0] L7=[8,152] L8=[1,1] L9=[9,153] L10=[2,2] L11=[10,154] L12=[3,3] L13=[11,155] L14=[4,4] L15=[12,156] L16=[5,5] L17=[13,157] L18=[0,159]；路径1[!_deqPtrVec_next_T_4]: 保持（归纳假设））
        · Rob: deqPtrVec_5_value 穷举 1 组（枚举 []）值域 [0,159]
    [R2_addr impl <- n_deqPtrVec_5_value] M3 PASS_C[impl]: ∈ [0,159] ⊆ [0,159]（无条件，未用接口契约）；来源 [('NewRobDeqPtrWrapper', 'io_out_5_value')]
        · n_deqPtrVec_5_value <- NewRobDeqPtrWrapper(deqPtrGenModule).io_out_5_value：NewRobDeqPtrWrapper.io_out_5_value ∈ [0,159]（联合归纳寄存器 ['deqPtrVec_0_value', 'deqPtrVec_5_value']；deqPtrVec_0_value: 基例 [0]；路径0[_deqPtrVec_next_T_4]: 穷举 160 组（枚举 ['deqPtrVec_0_value']）值域 [0,159]；三元叶 L0=不可达 L1=[0,152] L2=不可达 L3=[1,153] L4=不可达 L5=[2,154] L6=不可达 L7=[3,155] L8=不可达 L9=[4,156] L10=不可达 L11=[5,157] L12=不可达 L13=[6,158] L14=不可达 L15=[7,159] L16=[0,0] L17=[8,152] L18=[0,159]；路径1[!_deqPtrVec_next_T_4]: 保持（归纳假设） || deqPtrVec_5_value: 基例 [5]；路径0[_deqPtrVec_next_T_4]: 穷举 160 组（枚举 ['deqPtrVec_0_value']）值域 [0,159]；三元叶 L0=不可达 L1=[5,157] L2=不可达 L3=[6,158] L4=不可达 L5=[7,159] L6=[0,0] L7=[8,152] L8=[1,1] L9=[9,153] L10=[2,2] L11=[10,154] L12=[3,3] L13=[11,155] L14=[4,4] L15=[12,156] L16=[5,5] L17=[13,157] L18=[0,159]；路径1[!_deqPtrVec_next_T_4]: 保持（归纳假设））
        · Rob: n_deqPtrVec_5_value 穷举 1 组（枚举 []）值域 [0,159]
    [R3_addr ref <- deqPtrVec_4_value] M3 PASS_C[ref]: ∈ [0,159] ⊆ [0,159]（无条件，未用接口契约）；来源 [('NewRobDeqPtrWrapper', 'io_out_4_value')]
        · deqPtrVec_4_value <- NewRobDeqPtrWrapper(deqPtrGenModule).io_out_4_value：NewRobDeqPtrWrapper.io_out_4_value ∈ [0,159]（联合归纳寄存器 ['deqPtrVec_0_value', 'deqPtrVec_4_value']；deqPtrVec_0_value: 基例 [0]；路径0[_deqPtrVec_next_T_4]: 穷举 160 组（枚举 ['deqPtrVec_0_value']）值域 [0,159]；三元叶 L0=不可达 L1=[0,152] L2=不可达 L3=[1,153] L4=不可达 L5=[2,154] L6=不可达 L7=[3,155] L8=不可达 L9=[4,156] L10=不可达 L11=[5,157] L12=不可达 L13=[6,158] L14=不可达 L15=[7,159] L16=[0,0] L17=[8,152] L18=[0,159]；路径1[!_deqPtrVec_next_T_4]: 保持（归纳假设） || deqPtrVec_4_value: 基例 [4]；路径0[_deqPtrVec_next_T_4]: 穷举 160 组（枚举 ['deqPtrVec_0_value']）值域 [0,159]；三元叶 L0=不可达 L1=[4,156] L2=不可达 L3=[5,157] L4=不可达 L5=[6,158] L6=不可达 L7=[7,159] L8=[0,0] L9=[8,152] L10=[1,1] L11=[9,153] L12=[2,2] L13=[10,154] L14=[3,3] L15=[11,155] L16=[4,4] L17=[12,156] L18=[0,159]；路径1[!_deqPtrVec_next_T_4]: 保持（归纳假设））
        · Rob: deqPtrVec_4_value 穷举 1 组（枚举 []）值域 [0,159]
    [R3_addr impl <- n_deqPtrVec_4_value] M3 PASS_C[impl]: ∈ [0,159] ⊆ [0,159]（无条件，未用接口契约）；来源 [('NewRobDeqPtrWrapper', 'io_out_4_value')]
        · n_deqPtrVec_4_value <- NewRobDeqPtrWrapper(deqPtrGenModule).io_out_4_value：NewRobDeqPtrWrapper.io_out_4_value ∈ [0,159]（联合归纳寄存器 ['deqPtrVec_0_value', 'deqPtrVec_4_value']；deqPtrVec_0_value: 基例 [0]；路径0[_deqPtrVec_next_T_4]: 穷举 160 组（枚举 ['deqPtrVec_0_value']）值域 [0,159]；三元叶 L0=不可达 L1=[0,152] L2=不可达 L3=[1,153] L4=不可达 L5=[2,154] L6=不可达 L7=[3,155] L8=不可达 L9=[4,156] L10=不可达 L11=[5,157] L12=不可达 L13=[6,158] L14=不可达 L15=[7,159] L16=[0,0] L17=[8,152] L18=[0,159]；路径1[!_deqPtrVec_next_T_4]: 保持（归纳假设） || deqPtrVec_4_value: 基例 [4]；路径0[_deqPtrVec_next_T_4]: 穷举 160 组（枚举 ['deqPtrVec_0_value']）值域 [0,159]；三元叶 L0=不可达 L1=[4,156] L2=不可达 L3=[5,157] L4=不可达 L5=[6,158] L6=不可达 L7=[7,159] L8=[0,0] L9=[8,152] L10=[1,1] L11=[9,153] L12=[2,2] L13=[10,154] L14=[3,3] L15=[11,155] L16=[4,4] L17=[12,156] L18=[0,159]；路径1[!_deqPtrVec_next_T_4]: 保持（归纳假设））
        · Rob: n_deqPtrVec_4_value 穷举 1 组（枚举 []）值域 [0,159]
    [R4_addr ref <- deqPtrVec_3_value] M3 PASS_C[ref]: ∈ [0,159] ⊆ [0,159]（无条件，未用接口契约）；来源 [('NewRobDeqPtrWrapper', 'io_out_3_value')]
        · deqPtrVec_3_value <- NewRobDeqPtrWrapper(deqPtrGenModule).io_out_3_value：NewRobDeqPtrWrapper.io_out_3_value ∈ [0,159]（联合归纳寄存器 ['deqPtrVec_0_value', 'deqPtrVec_3_value']；deqPtrVec_0_value: 基例 [0]；路径0[_deqPtrVec_next_T_4]: 穷举 160 组（枚举 ['deqPtrVec_0_value']）值域 [0,159]；三元叶 L0=不可达 L1=[0,152] L2=不可达 L3=[1,153] L4=不可达 L5=[2,154] L6=不可达 L7=[3,155] L8=不可达 L9=[4,156] L10=不可达 L11=[5,157] L12=不可达 L13=[6,158] L14=不可达 L15=[7,159] L16=[0,0] L17=[8,152] L18=[0,159]；路径1[!_deqPtrVec_next_T_4]: 保持（归纳假设） || deqPtrVec_3_value: 基例 [3]；路径0[_deqPtrVec_next_T_4]: 穷举 160 组（枚举 ['deqPtrVec_0_value']）值域 [0,159]；三元叶 L0=不可达 L1=[3,155] L2=不可达 L3=[4,156] L4=不可达 L5=[5,157] L6=不可达 L7=[6,158] L8=不可达 L9=[7,159] L10=[0,0] L11=[8,152] L12=[1,1] L13=[9,153] L14=[2,2] L15=[10,154] L16=[3,3] L17=[11,155] L18=[0,159]；路径1[!_deqPtrVec_next_T_4]: 保持（归纳假设））
        · Rob: deqPtrVec_3_value 穷举 1 组（枚举 []）值域 [0,159]
    [R4_addr impl <- n_deqPtrVec_3_value] M3 PASS_C[impl]: ∈ [0,159] ⊆ [0,159]（无条件，未用接口契约）；来源 [('NewRobDeqPtrWrapper', 'io_out_3_value')]
        · n_deqPtrVec_3_value <- NewRobDeqPtrWrapper(deqPtrGenModule).io_out_3_value：NewRobDeqPtrWrapper.io_out_3_value ∈ [0,159]（联合归纳寄存器 ['deqPtrVec_0_value', 'deqPtrVec_3_value']；deqPtrVec_0_value: 基例 [0]；路径0[_deqPtrVec_next_T_4]: 穷举 160 组（枚举 ['deqPtrVec_0_value']）值域 [0,159]；三元叶 L0=不可达 L1=[0,152] L2=不可达 L3=[1,153] L4=不可达 L5=[2,154] L6=不可达 L7=[3,155] L8=不可达 L9=[4,156] L10=不可达 L11=[5,157] L12=不可达 L13=[6,158] L14=不可达 L15=[7,159] L16=[0,0] L17=[8,152] L18=[0,159]；路径1[!_deqPtrVec_next_T_4]: 保持（归纳假设） || deqPtrVec_3_value: 基例 [3]；路径0[_deqPtrVec_next_T_4]: 穷举 160 组（枚举 ['deqPtrVec_0_value']）值域 [0,159]；三元叶 L0=不可达 L1=[3,155] L2=不可达 L3=[4,156] L4=不可达 L5=[5,157] L6=不可达 L7=[6,158] L8=不可达 L9=[7,159] L10=[0,0] L11=[8,152] L12=[1,1] L13=[9,153] L14=[2,2] L15=[10,154] L16=[3,3] L17=[11,155] L18=[0,159]；路径1[!_deqPtrVec_next_T_4]: 保持（归纳假设））
        · Rob: n_deqPtrVec_3_value 穷举 1 组（枚举 []）值域 [0,159]
    [R5_addr ref <- deqPtrVec_2_value] M3 PASS_C[ref]: ∈ [0,159] ⊆ [0,159]（无条件，未用接口契约）；来源 [('NewRobDeqPtrWrapper', 'io_out_2_value')]
        · deqPtrVec_2_value <- NewRobDeqPtrWrapper(deqPtrGenModule).io_out_2_value：NewRobDeqPtrWrapper.io_out_2_value ∈ [0,159]（联合归纳寄存器 ['deqPtrVec_0_value', 'deqPtrVec_2_value']；deqPtrVec_0_value: 基例 [0]；路径0[_deqPtrVec_next_T_4]: 穷举 160 组（枚举 ['deqPtrVec_0_value']）值域 [0,159]；三元叶 L0=不可达 L1=[0,152] L2=不可达 L3=[1,153] L4=不可达 L5=[2,154] L6=不可达 L7=[3,155] L8=不可达 L9=[4,156] L10=不可达 L11=[5,157] L12=不可达 L13=[6,158] L14=不可达 L15=[7,159] L16=[0,0] L17=[8,152] L18=[0,159]；路径1[!_deqPtrVec_next_T_4]: 保持（归纳假设） || deqPtrVec_2_value: 基例 [2]；路径0[_deqPtrVec_next_T_4]: 穷举 160 组（枚举 ['deqPtrVec_0_value']）值域 [0,159]；三元叶 L0=不可达 L1=[2,154] L2=不可达 L3=[3,155] L4=不可达 L5=[4,156] L6=不可达 L7=[5,157] L8=不可达 L9=[6,158] L10=不可达 L11=[7,159] L12=[0,0] L13=[8,152] L14=[1,1] L15=[9,153] L16=[2,2] L17=[10,154] L18=[0,159]；路径1[!_deqPtrVec_next_T_4]: 保持（归纳假设））
        · Rob: deqPtrVec_2_value 穷举 1 组（枚举 []）值域 [0,159]
    [R5_addr impl <- n_deqPtrVec_2_value] M3 PASS_C[impl]: ∈ [0,159] ⊆ [0,159]（无条件，未用接口契约）；来源 [('NewRobDeqPtrWrapper', 'io_out_2_value')]
        · n_deqPtrVec_2_value <- NewRobDeqPtrWrapper(deqPtrGenModule).io_out_2_value：NewRobDeqPtrWrapper.io_out_2_value ∈ [0,159]（联合归纳寄存器 ['deqPtrVec_0_value', 'deqPtrVec_2_value']；deqPtrVec_0_value: 基例 [0]；路径0[_deqPtrVec_next_T_4]: 穷举 160 组（枚举 ['deqPtrVec_0_value']）值域 [0,159]；三元叶 L0=不可达 L1=[0,152] L2=不可达 L3=[1,153] L4=不可达 L5=[2,154] L6=不可达 L7=[3,155] L8=不可达 L9=[4,156] L10=不可达 L11=[5,157] L12=不可达 L13=[6,158] L14=不可达 L15=[7,159] L16=[0,0] L17=[8,152] L18=[0,159]；路径1[!_deqPtrVec_next_T_4]: 保持（归纳假设） || deqPtrVec_2_value: 基例 [2]；路径0[_deqPtrVec_next_T_4]: 穷举 160 组（枚举 ['deqPtrVec_0_value']）值域 [0,159]；三元叶 L0=不可达 L1=[2,154] L2=不可达 L3=[3,155] L4=不可达 L5=[4,156] L6=不可达 L7=[5,157] L8=不可达 L9=[6,158] L10=不可达 L11=[7,159] L12=[0,0] L13=[8,152] L14=[1,1] L15=[9,153] L16=[2,2] L17=[10,154] L18=[0,159]；路径1[!_deqPtrVec_next_T_4]: 保持（归纳假设））
        · Rob: n_deqPtrVec_2_value 穷举 1 组（枚举 []）值域 [0,159]
    [R6_addr ref <- deqPtrVec_1_value] M3 PASS_C[ref]: ∈ [0,159] ⊆ [0,159]（无条件，未用接口契约）；来源 [('NewRobDeqPtrWrapper', 'io_out_1_value')]
        · deqPtrVec_1_value <- NewRobDeqPtrWrapper(deqPtrGenModule).io_out_1_value：NewRobDeqPtrWrapper.io_out_1_value ∈ [0,159]（联合归纳寄存器 ['deqPtrVec_0_value', 'deqPtrVec_1_value']；deqPtrVec_0_value: 基例 [0]；路径0[_deqPtrVec_next_T_4]: 穷举 160 组（枚举 ['deqPtrVec_0_value']）值域 [0,159]；三元叶 L0=不可达 L1=[0,152] L2=不可达 L3=[1,153] L4=不可达 L5=[2,154] L6=不可达 L7=[3,155] L8=不可达 L9=[4,156] L10=不可达 L11=[5,157] L12=不可达 L13=[6,158] L14=不可达 L15=[7,159] L16=[0,0] L17=[8,152] L18=[0,159]；路径1[!_deqPtrVec_next_T_4]: 保持（归纳假设） || deqPtrVec_1_value: 基例 [1]；路径0[_deqPtrVec_next_T_4]: 穷举 160 组（枚举 ['deqPtrVec_0_value']）值域 [0,159]；三元叶 L0=不可达 L1=[1,153] L2=不可达 L3=[2,154] L4=不可达 L5=[3,155] L6=不可达 L7=[4,156] L8=不可达 L9=[5,157] L10=不可达 L11=[6,158] L12=不可达 L13=[7,159] L14=[0,0] L15=[8,152] L16=[1,1] L17=[9,153] L18=[0,159]；路径1[!_deqPtrVec_next_T_4]: 保持（归纳假设））
        · Rob: deqPtrVec_1_value 穷举 1 组（枚举 []）值域 [0,159]
    [R6_addr impl <- n_deqPtrVec_1_value] M3 PASS_C[impl]: ∈ [0,159] ⊆ [0,159]（无条件，未用接口契约）；来源 [('NewRobDeqPtrWrapper', 'io_out_1_value')]
        · n_deqPtrVec_1_value <- NewRobDeqPtrWrapper(deqPtrGenModule).io_out_1_value：NewRobDeqPtrWrapper.io_out_1_value ∈ [0,159]（联合归纳寄存器 ['deqPtrVec_0_value', 'deqPtrVec_1_value']；deqPtrVec_0_value: 基例 [0]；路径0[_deqPtrVec_next_T_4]: 穷举 160 组（枚举 ['deqPtrVec_0_value']）值域 [0,159]；三元叶 L0=不可达 L1=[0,152] L2=不可达 L3=[1,153] L4=不可达 L5=[2,154] L6=不可达 L7=[3,155] L8=不可达 L9=[4,156] L10=不可达 L11=[5,157] L12=不可达 L13=[6,158] L14=不可达 L15=[7,159] L16=[0,0] L17=[8,152] L18=[0,159]；路径1[!_deqPtrVec_next_T_4]: 保持（归纳假设） || deqPtrVec_1_value: 基例 [1]；路径0[_deqPtrVec_next_T_4]: 穷举 160 组（枚举 ['deqPtrVec_0_value']）值域 [0,159]；三元叶 L0=不可达 L1=[1,153] L2=不可达 L3=[2,154] L4=不可达 L5=[3,155] L6=不可达 L7=[4,156] L8=不可达 L9=[5,157] L10=不可达 L11=[6,158] L12=不可达 L13=[7,159] L14=[0,0] L15=[8,152] L16=[1,1] L17=[9,153] L18=[0,159]；路径1[!_deqPtrVec_next_T_4]: 保持（归纳假设））
        · Rob: n_deqPtrVec_1_value 穷举 1 组（枚举 []）值域 [0,159]
    [R7_addr ref <- deqPtrVec_0_value] M3 PASS_C[ref]: ∈ [0,159] ⊆ [0,159]（无条件，未用接口契约）；来源 [('NewRobDeqPtrWrapper', 'io_out_0_value')]
        · deqPtrVec_0_value <- NewRobDeqPtrWrapper(deqPtrGenModule).io_out_0_value：NewRobDeqPtrWrapper.io_out_0_value ∈ [0,159]（联合归纳寄存器 ['deqPtrVec_0_value']；deqPtrVec_0_value: 基例 [0]；路径0[_deqPtrVec_next_T_4]: 穷举 160 组（枚举 ['deqPtrVec_0_value']）值域 [0,159]；三元叶 L0=不可达 L1=[0,152] L2=不可达 L3=[1,153] L4=不可达 L5=[2,154] L6=不可达 L7=[3,155] L8=不可达 L9=[4,156] L10=不可达 L11=[5,157] L12=不可达 L13=[6,158] L14=不可达 L15=[7,159] L16=[0,0] L17=[8,152] L18=[0,159]；路径1[!_deqPtrVec_next_T_4]: 保持（归纳假设））
        · Rob: deqPtrVec_0_value 穷举 1 组（枚举 []）值域 [0,159]
    [R7_addr impl <- n_deqPtrVec_0_value] M3 PASS_C[impl]: ∈ [0,159] ⊆ [0,159]（无条件，未用接口契约）；来源 [('NewRobDeqPtrWrapper', 'io_out_0_value')]
        · n_deqPtrVec_0_value <- NewRobDeqPtrWrapper(deqPtrGenModule).io_out_0_value：NewRobDeqPtrWrapper.io_out_0_value ∈ [0,159]（联合归纳寄存器 ['deqPtrVec_0_value']；deqPtrVec_0_value: 基例 [0]；路径0[_deqPtrVec_next_T_4]: 穷举 160 组（枚举 ['deqPtrVec_0_value']）值域 [0,159]；三元叶 L0=不可达 L1=[0,152] L2=不可达 L3=[1,153] L4=不可达 L5=[2,154] L6=不可达 L7=[3,155] L8=不可达 L9=[4,156] L10=不可达 L11=[5,157] L12=不可达 L13=[6,158] L14=不可达 L15=[7,159] L16=[0,0] L17=[8,152] L18=[0,159]；路径1[!_deqPtrVec_next_T_4]: 保持（归纳假设））
        · Rob: n_deqPtrVec_0_value 穷举 1 组（枚举 []）值域 [0,159]
    [W0_addr ref <- allocatePtrVec_5_value] M3 PASS_C[ref]: ∈ [0,159] ⊆ [0,159]（无条件，未用接口契约）；来源 [('RobEnqPtrWrapper', 'io_out_0_value'), ('RobEnqPtrWrapper', 'io_out_1_value'), ('RobEnqPtrWrapper', 'io_out_2_value'), ('RobEnqPtrWrapper', 'io_out_3_value'), ('RobEnqPtrWrapper', 'io_out_4_value'), ('RobEnqPtrWrapper', 'io_out_5_value')]
        · enqPtrVec_0_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_0_value：RobEnqPtrWrapper.io_out_0_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_0_value']；enqPtrVec_0_value: 基例 [0]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,95] L1=[0,159] L2=[0,96] L3=[1,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_0_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · enqPtrVec_5_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_5_value：RobEnqPtrWrapper.io_out_5_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_5_value']；enqPtrVec_5_value: 基例 [5]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,100] L1=[5,159] L2=[0,101] L3=[6,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_5_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · enqPtrVec_4_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_4_value：RobEnqPtrWrapper.io_out_4_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_4_value']；enqPtrVec_4_value: 基例 [4]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,99] L1=[4,159] L2=[0,100] L3=[5,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_4_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · enqPtrVec_3_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_3_value：RobEnqPtrWrapper.io_out_3_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_3_value']；enqPtrVec_3_value: 基例 [3]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,98] L1=[3,159] L2=[0,99] L3=[4,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_3_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · enqPtrVec_2_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_2_value：RobEnqPtrWrapper.io_out_2_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_2_value']；enqPtrVec_2_value: 基例 [2]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,97] L1=[2,159] L2=[0,98] L3=[3,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_2_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · enqPtrVec_1_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_1_value：RobEnqPtrWrapper.io_out_1_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_1_value']；enqPtrVec_1_value: 基例 [1]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,96] L1=[1,159] L2=[0,97] L3=[2,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_1_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · io_enq_req_0_valid: parent input，取全域
        · io_enq_req_0_bits_firstUop: parent input，取全域
        · io_enq_req_1_valid: parent input，取全域
        · io_enq_req_1_bits_firstUop: parent input，取全域
        · io_enq_req_2_valid: parent input，取全域
        · io_enq_req_2_bits_firstUop: parent input，取全域
        · io_enq_req_3_valid: parent input，取全域
        · io_enq_req_3_bits_firstUop: parent input，取全域
        · io_enq_req_4_valid: parent input，取全域
        · io_enq_req_4_bits_firstUop: parent input，取全域
        · Rob: allocatePtrVec_5_value 穷举 32 组（枚举 ['_GEN', '_GEN_0', '_GEN_1', '_GEN_2', '_GEN_3']）值域 [0,159]；三元/选择叶 6 个全部求值
    [W0_addr impl <- n_allocatePtrVec_5_value] M3 PASS_C[impl]: ∈ [0,159] ⊆ [0,159]（无条件，未用接口契约）；来源 [('RobEnqPtrWrapper', 'io_out_0_value'), ('RobEnqPtrWrapper', 'io_out_1_value'), ('RobEnqPtrWrapper', 'io_out_2_value'), ('RobEnqPtrWrapper', 'io_out_3_value'), ('RobEnqPtrWrapper', 'io_out_4_value'), ('RobEnqPtrWrapper', 'io_out_5_value')]
        · n_allocatePtrVec_5_value <- xs_Rob_core(u_core).allocatePtrVec_5_value = allocatePtrValue[5]
        · n_enqPtrVec_0_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_0_value：RobEnqPtrWrapper.io_out_0_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_0_value']；enqPtrVec_0_value: 基例 [0]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,95] L1=[0,159] L2=[0,96] L3=[1,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_0_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: n_enqPtrVec_0_value 穷举 1 组（枚举 []）值域 [0,159]
        · xs_Rob_core.enqPtrValue[0] = enqPtrVec_0_value
        · n_enqPtrVec_1_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_1_value：RobEnqPtrWrapper.io_out_1_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_1_value']；enqPtrVec_1_value: 基例 [1]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,96] L1=[1,159] L2=[0,97] L3=[2,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_1_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: n_enqPtrVec_1_value 穷举 1 组（枚举 []）值域 [0,159]
        · xs_Rob_core.enqPtrValue[1] = enqPtrVec_1_value
        · n_enqPtrVec_2_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_2_value：RobEnqPtrWrapper.io_out_2_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_2_value']；enqPtrVec_2_value: 基例 [2]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,97] L1=[2,159] L2=[0,98] L3=[3,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_2_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: n_enqPtrVec_2_value 穷举 1 组（枚举 []）值域 [0,159]
        · xs_Rob_core.enqPtrValue[2] = enqPtrVec_2_value
        · n_enqPtrVec_3_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_3_value：RobEnqPtrWrapper.io_out_3_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_3_value']；enqPtrVec_3_value: 基例 [3]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,98] L1=[3,159] L2=[0,99] L3=[4,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_3_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: n_enqPtrVec_3_value 穷举 1 组（枚举 []）值域 [0,159]
        · xs_Rob_core.enqPtrValue[3] = enqPtrVec_3_value
        · n_enqPtrVec_4_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_4_value：RobEnqPtrWrapper.io_out_4_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_4_value']；enqPtrVec_4_value: 基例 [4]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,99] L1=[4,159] L2=[0,100] L3=[5,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_4_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: n_enqPtrVec_4_value 穷举 1 组（枚举 []）值域 [0,159]
        · xs_Rob_core.enqPtrValue[4] = enqPtrVec_4_value
        · n_enqPtrVec_5_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_5_value：RobEnqPtrWrapper.io_out_5_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_5_value']；enqPtrVec_5_value: 基例 [5]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,100] L1=[5,159] L2=[0,101] L3=[6,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_5_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: n_enqPtrVec_5_value 穷举 1 组（枚举 []）值域 [0,159]
        · xs_Rob_core.enqPtrValue[5] = enqPtrVec_5_value
        · xs_Rob_core.allocatePtrValue[5]：allocatePtrValue[i] = enqPtrValue[0] 默认，再按 allocSel[i]==3'(k) 覆盖为 enqPtrValue[k]，k∈[0,5]；候选 enqPtrValue[0, 1, 2, 3, 4, 5]；并集 [0,159]
        · xs_Rob_core: allocatePtrValue[5] 穷举 1 组（枚举 []）值域 [0,159]
        · Rob: n_allocatePtrVec_5_value 穷举 1 组（枚举 []）值域 [0,159]
    [W1_addr ref <- allocatePtrVec_4_value] M3 PASS_C[ref]: ∈ [0,159] ⊆ [0,159]（无条件，未用接口契约）；来源 [('RobEnqPtrWrapper', 'io_out_0_value'), ('RobEnqPtrWrapper', 'io_out_1_value'), ('RobEnqPtrWrapper', 'io_out_2_value'), ('RobEnqPtrWrapper', 'io_out_3_value'), ('RobEnqPtrWrapper', 'io_out_4_value'), ('RobEnqPtrWrapper', 'io_out_5_value')]
        · enqPtrVec_0_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_0_value：RobEnqPtrWrapper.io_out_0_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_0_value']；enqPtrVec_0_value: 基例 [0]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,95] L1=[0,159] L2=[0,96] L3=[1,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_0_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · enqPtrVec_5_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_5_value：RobEnqPtrWrapper.io_out_5_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_5_value']；enqPtrVec_5_value: 基例 [5]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,100] L1=[5,159] L2=[0,101] L3=[6,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_5_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · enqPtrVec_4_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_4_value：RobEnqPtrWrapper.io_out_4_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_4_value']；enqPtrVec_4_value: 基例 [4]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,99] L1=[4,159] L2=[0,100] L3=[5,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_4_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · enqPtrVec_3_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_3_value：RobEnqPtrWrapper.io_out_3_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_3_value']；enqPtrVec_3_value: 基例 [3]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,98] L1=[3,159] L2=[0,99] L3=[4,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_3_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · enqPtrVec_2_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_2_value：RobEnqPtrWrapper.io_out_2_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_2_value']；enqPtrVec_2_value: 基例 [2]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,97] L1=[2,159] L2=[0,98] L3=[3,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_2_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · enqPtrVec_1_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_1_value：RobEnqPtrWrapper.io_out_1_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_1_value']；enqPtrVec_1_value: 基例 [1]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,96] L1=[1,159] L2=[0,97] L3=[2,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_1_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · io_enq_req_0_valid: parent input，取全域
        · io_enq_req_0_bits_firstUop: parent input，取全域
        · io_enq_req_1_valid: parent input，取全域
        · io_enq_req_1_bits_firstUop: parent input，取全域
        · io_enq_req_2_valid: parent input，取全域
        · io_enq_req_2_bits_firstUop: parent input，取全域
        · io_enq_req_3_valid: parent input，取全域
        · io_enq_req_3_bits_firstUop: parent input，取全域
        · Rob: allocatePtrVec_4_value 穷举 16 组（枚举 ['_GEN', '_GEN_0', '_GEN_1', '_GEN_2']）值域 [0,159]；三元/选择叶 5 个全部求值
    [W1_addr impl <- n_allocatePtrVec_4_value] M3 PASS_C[impl]: ∈ [0,159] ⊆ [0,159]（无条件，未用接口契约）；来源 [('RobEnqPtrWrapper', 'io_out_0_value'), ('RobEnqPtrWrapper', 'io_out_1_value'), ('RobEnqPtrWrapper', 'io_out_2_value'), ('RobEnqPtrWrapper', 'io_out_3_value'), ('RobEnqPtrWrapper', 'io_out_4_value'), ('RobEnqPtrWrapper', 'io_out_5_value')]
        · n_allocatePtrVec_4_value <- xs_Rob_core(u_core).allocatePtrVec_4_value = allocatePtrValue[4]
        · n_enqPtrVec_0_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_0_value：RobEnqPtrWrapper.io_out_0_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_0_value']；enqPtrVec_0_value: 基例 [0]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,95] L1=[0,159] L2=[0,96] L3=[1,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_0_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: n_enqPtrVec_0_value 穷举 1 组（枚举 []）值域 [0,159]
        · xs_Rob_core.enqPtrValue[0] = enqPtrVec_0_value
        · n_enqPtrVec_1_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_1_value：RobEnqPtrWrapper.io_out_1_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_1_value']；enqPtrVec_1_value: 基例 [1]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,96] L1=[1,159] L2=[0,97] L3=[2,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_1_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: n_enqPtrVec_1_value 穷举 1 组（枚举 []）值域 [0,159]
        · xs_Rob_core.enqPtrValue[1] = enqPtrVec_1_value
        · n_enqPtrVec_2_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_2_value：RobEnqPtrWrapper.io_out_2_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_2_value']；enqPtrVec_2_value: 基例 [2]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,97] L1=[2,159] L2=[0,98] L3=[3,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_2_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: n_enqPtrVec_2_value 穷举 1 组（枚举 []）值域 [0,159]
        · xs_Rob_core.enqPtrValue[2] = enqPtrVec_2_value
        · n_enqPtrVec_3_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_3_value：RobEnqPtrWrapper.io_out_3_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_3_value']；enqPtrVec_3_value: 基例 [3]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,98] L1=[3,159] L2=[0,99] L3=[4,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_3_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: n_enqPtrVec_3_value 穷举 1 组（枚举 []）值域 [0,159]
        · xs_Rob_core.enqPtrValue[3] = enqPtrVec_3_value
        · n_enqPtrVec_4_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_4_value：RobEnqPtrWrapper.io_out_4_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_4_value']；enqPtrVec_4_value: 基例 [4]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,99] L1=[4,159] L2=[0,100] L3=[5,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_4_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: n_enqPtrVec_4_value 穷举 1 组（枚举 []）值域 [0,159]
        · xs_Rob_core.enqPtrValue[4] = enqPtrVec_4_value
        · n_enqPtrVec_5_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_5_value：RobEnqPtrWrapper.io_out_5_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_5_value']；enqPtrVec_5_value: 基例 [5]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,100] L1=[5,159] L2=[0,101] L3=[6,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_5_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: n_enqPtrVec_5_value 穷举 1 组（枚举 []）值域 [0,159]
        · xs_Rob_core.enqPtrValue[5] = enqPtrVec_5_value
        · xs_Rob_core.allocatePtrValue[4]：allocatePtrValue[i] = enqPtrValue[0] 默认，再按 allocSel[i]==3'(k) 覆盖为 enqPtrValue[k]，k∈[0,5]；候选 enqPtrValue[0, 1, 2, 3, 4, 5]；并集 [0,159]
        · xs_Rob_core: allocatePtrValue[4] 穷举 1 组（枚举 []）值域 [0,159]
        · Rob: n_allocatePtrVec_4_value 穷举 1 组（枚举 []）值域 [0,159]
    [W2_addr ref <- allocatePtrVec_3_value] M3 PASS_C[ref]: ∈ [0,159] ⊆ [0,159]（无条件，未用接口契约）；来源 [('RobEnqPtrWrapper', 'io_out_0_value'), ('RobEnqPtrWrapper', 'io_out_1_value'), ('RobEnqPtrWrapper', 'io_out_2_value'), ('RobEnqPtrWrapper', 'io_out_3_value'), ('RobEnqPtrWrapper', 'io_out_4_value'), ('RobEnqPtrWrapper', 'io_out_5_value')]
        · enqPtrVec_0_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_0_value：RobEnqPtrWrapper.io_out_0_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_0_value']；enqPtrVec_0_value: 基例 [0]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,95] L1=[0,159] L2=[0,96] L3=[1,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_0_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · enqPtrVec_5_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_5_value：RobEnqPtrWrapper.io_out_5_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_5_value']；enqPtrVec_5_value: 基例 [5]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,100] L1=[5,159] L2=[0,101] L3=[6,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_5_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · enqPtrVec_4_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_4_value：RobEnqPtrWrapper.io_out_4_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_4_value']；enqPtrVec_4_value: 基例 [4]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,99] L1=[4,159] L2=[0,100] L3=[5,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_4_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · enqPtrVec_3_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_3_value：RobEnqPtrWrapper.io_out_3_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_3_value']；enqPtrVec_3_value: 基例 [3]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,98] L1=[3,159] L2=[0,99] L3=[4,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_3_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · enqPtrVec_2_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_2_value：RobEnqPtrWrapper.io_out_2_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_2_value']；enqPtrVec_2_value: 基例 [2]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,97] L1=[2,159] L2=[0,98] L3=[3,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_2_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · enqPtrVec_1_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_1_value：RobEnqPtrWrapper.io_out_1_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_1_value']；enqPtrVec_1_value: 基例 [1]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,96] L1=[1,159] L2=[0,97] L3=[2,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_1_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · io_enq_req_0_valid: parent input，取全域
        · io_enq_req_0_bits_firstUop: parent input，取全域
        · io_enq_req_1_valid: parent input，取全域
        · io_enq_req_1_bits_firstUop: parent input，取全域
        · io_enq_req_2_valid: parent input，取全域
        · io_enq_req_2_bits_firstUop: parent input，取全域
        · Rob: allocatePtrVec_3_value 穷举 8 组（枚举 ['_GEN', '_GEN_0', '_GEN_1']）值域 [0,159]；三元/选择叶 4 个全部求值
    [W2_addr impl <- n_allocatePtrVec_3_value] M3 PASS_C[impl]: ∈ [0,159] ⊆ [0,159]（无条件，未用接口契约）；来源 [('RobEnqPtrWrapper', 'io_out_0_value'), ('RobEnqPtrWrapper', 'io_out_1_value'), ('RobEnqPtrWrapper', 'io_out_2_value'), ('RobEnqPtrWrapper', 'io_out_3_value'), ('RobEnqPtrWrapper', 'io_out_4_value'), ('RobEnqPtrWrapper', 'io_out_5_value')]
        · n_allocatePtrVec_3_value <- xs_Rob_core(u_core).allocatePtrVec_3_value = allocatePtrValue[3]
        · n_enqPtrVec_0_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_0_value：RobEnqPtrWrapper.io_out_0_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_0_value']；enqPtrVec_0_value: 基例 [0]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,95] L1=[0,159] L2=[0,96] L3=[1,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_0_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: n_enqPtrVec_0_value 穷举 1 组（枚举 []）值域 [0,159]
        · xs_Rob_core.enqPtrValue[0] = enqPtrVec_0_value
        · n_enqPtrVec_1_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_1_value：RobEnqPtrWrapper.io_out_1_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_1_value']；enqPtrVec_1_value: 基例 [1]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,96] L1=[1,159] L2=[0,97] L3=[2,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_1_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: n_enqPtrVec_1_value 穷举 1 组（枚举 []）值域 [0,159]
        · xs_Rob_core.enqPtrValue[1] = enqPtrVec_1_value
        · n_enqPtrVec_2_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_2_value：RobEnqPtrWrapper.io_out_2_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_2_value']；enqPtrVec_2_value: 基例 [2]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,97] L1=[2,159] L2=[0,98] L3=[3,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_2_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: n_enqPtrVec_2_value 穷举 1 组（枚举 []）值域 [0,159]
        · xs_Rob_core.enqPtrValue[2] = enqPtrVec_2_value
        · n_enqPtrVec_3_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_3_value：RobEnqPtrWrapper.io_out_3_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_3_value']；enqPtrVec_3_value: 基例 [3]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,98] L1=[3,159] L2=[0,99] L3=[4,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_3_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: n_enqPtrVec_3_value 穷举 1 组（枚举 []）值域 [0,159]
        · xs_Rob_core.enqPtrValue[3] = enqPtrVec_3_value
        · n_enqPtrVec_4_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_4_value：RobEnqPtrWrapper.io_out_4_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_4_value']；enqPtrVec_4_value: 基例 [4]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,99] L1=[4,159] L2=[0,100] L3=[5,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_4_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: n_enqPtrVec_4_value 穷举 1 组（枚举 []）值域 [0,159]
        · xs_Rob_core.enqPtrValue[4] = enqPtrVec_4_value
        · n_enqPtrVec_5_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_5_value：RobEnqPtrWrapper.io_out_5_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_5_value']；enqPtrVec_5_value: 基例 [5]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,100] L1=[5,159] L2=[0,101] L3=[6,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_5_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: n_enqPtrVec_5_value 穷举 1 组（枚举 []）值域 [0,159]
        · xs_Rob_core.enqPtrValue[5] = enqPtrVec_5_value
        · xs_Rob_core.allocatePtrValue[3]：allocatePtrValue[i] = enqPtrValue[0] 默认，再按 allocSel[i]==3'(k) 覆盖为 enqPtrValue[k]，k∈[0,5]；候选 enqPtrValue[0, 1, 2, 3, 4, 5]；并集 [0,159]
        · xs_Rob_core: allocatePtrValue[3] 穷举 1 组（枚举 []）值域 [0,159]
        · Rob: n_allocatePtrVec_3_value 穷举 1 组（枚举 []）值域 [0,159]
    [W3_addr ref <- allocatePtrVec_2_value] M3 PASS_C[ref]: ∈ [0,159] ⊆ [0,159]（无条件，未用接口契约）；来源 [('RobEnqPtrWrapper', 'io_out_0_value'), ('RobEnqPtrWrapper', 'io_out_1_value'), ('RobEnqPtrWrapper', 'io_out_2_value'), ('RobEnqPtrWrapper', 'io_out_3_value'), ('RobEnqPtrWrapper', 'io_out_4_value'), ('RobEnqPtrWrapper', 'io_out_5_value')]
        · enqPtrVec_0_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_0_value：RobEnqPtrWrapper.io_out_0_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_0_value']；enqPtrVec_0_value: 基例 [0]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,95] L1=[0,159] L2=[0,96] L3=[1,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_0_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · enqPtrVec_5_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_5_value：RobEnqPtrWrapper.io_out_5_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_5_value']；enqPtrVec_5_value: 基例 [5]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,100] L1=[5,159] L2=[0,101] L3=[6,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_5_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · enqPtrVec_4_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_4_value：RobEnqPtrWrapper.io_out_4_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_4_value']；enqPtrVec_4_value: 基例 [4]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,99] L1=[4,159] L2=[0,100] L3=[5,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_4_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · enqPtrVec_3_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_3_value：RobEnqPtrWrapper.io_out_3_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_3_value']；enqPtrVec_3_value: 基例 [3]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,98] L1=[3,159] L2=[0,99] L3=[4,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_3_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · enqPtrVec_2_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_2_value：RobEnqPtrWrapper.io_out_2_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_2_value']；enqPtrVec_2_value: 基例 [2]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,97] L1=[2,159] L2=[0,98] L3=[3,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_2_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · enqPtrVec_1_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_1_value：RobEnqPtrWrapper.io_out_1_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_1_value']；enqPtrVec_1_value: 基例 [1]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,96] L1=[1,159] L2=[0,97] L3=[2,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_1_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · io_enq_req_0_valid: parent input，取全域
        · io_enq_req_0_bits_firstUop: parent input，取全域
        · io_enq_req_1_valid: parent input，取全域
        · io_enq_req_1_bits_firstUop: parent input，取全域
        · Rob: allocatePtrVec_2_value 穷举 4 组（枚举 ['_GEN', '_GEN_0']）值域 [0,159]；三元/选择叶 3 个全部求值
    [W3_addr impl <- n_allocatePtrVec_2_value] M3 PASS_C[impl]: ∈ [0,159] ⊆ [0,159]（无条件，未用接口契约）；来源 [('RobEnqPtrWrapper', 'io_out_0_value'), ('RobEnqPtrWrapper', 'io_out_1_value'), ('RobEnqPtrWrapper', 'io_out_2_value'), ('RobEnqPtrWrapper', 'io_out_3_value'), ('RobEnqPtrWrapper', 'io_out_4_value'), ('RobEnqPtrWrapper', 'io_out_5_value')]
        · n_allocatePtrVec_2_value <- xs_Rob_core(u_core).allocatePtrVec_2_value = allocatePtrValue[2]
        · n_enqPtrVec_0_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_0_value：RobEnqPtrWrapper.io_out_0_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_0_value']；enqPtrVec_0_value: 基例 [0]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,95] L1=[0,159] L2=[0,96] L3=[1,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_0_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: n_enqPtrVec_0_value 穷举 1 组（枚举 []）值域 [0,159]
        · xs_Rob_core.enqPtrValue[0] = enqPtrVec_0_value
        · n_enqPtrVec_1_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_1_value：RobEnqPtrWrapper.io_out_1_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_1_value']；enqPtrVec_1_value: 基例 [1]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,96] L1=[1,159] L2=[0,97] L3=[2,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_1_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: n_enqPtrVec_1_value 穷举 1 组（枚举 []）值域 [0,159]
        · xs_Rob_core.enqPtrValue[1] = enqPtrVec_1_value
        · n_enqPtrVec_2_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_2_value：RobEnqPtrWrapper.io_out_2_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_2_value']；enqPtrVec_2_value: 基例 [2]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,97] L1=[2,159] L2=[0,98] L3=[3,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_2_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: n_enqPtrVec_2_value 穷举 1 组（枚举 []）值域 [0,159]
        · xs_Rob_core.enqPtrValue[2] = enqPtrVec_2_value
        · n_enqPtrVec_3_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_3_value：RobEnqPtrWrapper.io_out_3_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_3_value']；enqPtrVec_3_value: 基例 [3]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,98] L1=[3,159] L2=[0,99] L3=[4,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_3_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: n_enqPtrVec_3_value 穷举 1 组（枚举 []）值域 [0,159]
        · xs_Rob_core.enqPtrValue[3] = enqPtrVec_3_value
        · n_enqPtrVec_4_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_4_value：RobEnqPtrWrapper.io_out_4_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_4_value']；enqPtrVec_4_value: 基例 [4]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,99] L1=[4,159] L2=[0,100] L3=[5,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_4_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: n_enqPtrVec_4_value 穷举 1 组（枚举 []）值域 [0,159]
        · xs_Rob_core.enqPtrValue[4] = enqPtrVec_4_value
        · n_enqPtrVec_5_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_5_value：RobEnqPtrWrapper.io_out_5_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_5_value']；enqPtrVec_5_value: 基例 [5]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,100] L1=[5,159] L2=[0,101] L3=[6,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_5_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: n_enqPtrVec_5_value 穷举 1 组（枚举 []）值域 [0,159]
        · xs_Rob_core.enqPtrValue[5] = enqPtrVec_5_value
        · xs_Rob_core.allocatePtrValue[2]：allocatePtrValue[i] = enqPtrValue[0] 默认，再按 allocSel[i]==3'(k) 覆盖为 enqPtrValue[k]，k∈[0,5]；候选 enqPtrValue[0, 1, 2, 3, 4, 5]；并集 [0,159]
        · xs_Rob_core: allocatePtrValue[2] 穷举 1 组（枚举 []）值域 [0,159]
        · Rob: n_allocatePtrVec_2_value 穷举 1 组（枚举 []）值域 [0,159]
    [W4_addr ref <- allocatePtrVec_1_value] M3 PASS_C[ref]: ∈ [0,159] ⊆ [0,159]（无条件，未用接口契约）；来源 [('RobEnqPtrWrapper', 'io_out_0_value'), ('RobEnqPtrWrapper', 'io_out_1_value'), ('RobEnqPtrWrapper', 'io_out_2_value'), ('RobEnqPtrWrapper', 'io_out_3_value'), ('RobEnqPtrWrapper', 'io_out_4_value'), ('RobEnqPtrWrapper', 'io_out_5_value')]
        · enqPtrVec_0_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_0_value：RobEnqPtrWrapper.io_out_0_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_0_value']；enqPtrVec_0_value: 基例 [0]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,95] L1=[0,159] L2=[0,96] L3=[1,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_0_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · enqPtrVec_5_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_5_value：RobEnqPtrWrapper.io_out_5_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_5_value']；enqPtrVec_5_value: 基例 [5]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,100] L1=[5,159] L2=[0,101] L3=[6,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_5_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · enqPtrVec_4_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_4_value：RobEnqPtrWrapper.io_out_4_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_4_value']；enqPtrVec_4_value: 基例 [4]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,99] L1=[4,159] L2=[0,100] L3=[5,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_4_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · enqPtrVec_3_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_3_value：RobEnqPtrWrapper.io_out_3_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_3_value']；enqPtrVec_3_value: 基例 [3]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,98] L1=[3,159] L2=[0,99] L3=[4,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_3_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · enqPtrVec_2_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_2_value：RobEnqPtrWrapper.io_out_2_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_2_value']；enqPtrVec_2_value: 基例 [2]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,97] L1=[2,159] L2=[0,98] L3=[3,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_2_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · enqPtrVec_1_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_1_value：RobEnqPtrWrapper.io_out_1_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_1_value']；enqPtrVec_1_value: 基例 [1]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,96] L1=[1,159] L2=[0,97] L3=[2,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_1_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · io_enq_req_0_valid: parent input，取全域
        · io_enq_req_0_bits_firstUop: parent input，取全域
        · Rob: allocatePtrVec_1_value 穷举 1 组（枚举 []）值域 [0,159]；三元/选择叶 2 个全部求值
    [W4_addr impl <- n_allocatePtrVec_1_value] M3 PASS_C[impl]: ∈ [0,159] ⊆ [0,159]（无条件，未用接口契约）；来源 [('RobEnqPtrWrapper', 'io_out_0_value'), ('RobEnqPtrWrapper', 'io_out_1_value'), ('RobEnqPtrWrapper', 'io_out_2_value'), ('RobEnqPtrWrapper', 'io_out_3_value'), ('RobEnqPtrWrapper', 'io_out_4_value'), ('RobEnqPtrWrapper', 'io_out_5_value')]
        · n_allocatePtrVec_1_value <- xs_Rob_core(u_core).allocatePtrVec_1_value = allocatePtrValue[1]
        · n_enqPtrVec_0_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_0_value：RobEnqPtrWrapper.io_out_0_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_0_value']；enqPtrVec_0_value: 基例 [0]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,95] L1=[0,159] L2=[0,96] L3=[1,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_0_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: n_enqPtrVec_0_value 穷举 1 组（枚举 []）值域 [0,159]
        · xs_Rob_core.enqPtrValue[0] = enqPtrVec_0_value
        · n_enqPtrVec_1_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_1_value：RobEnqPtrWrapper.io_out_1_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_1_value']；enqPtrVec_1_value: 基例 [1]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,96] L1=[1,159] L2=[0,97] L3=[2,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_1_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: n_enqPtrVec_1_value 穷举 1 组（枚举 []）值域 [0,159]
        · xs_Rob_core.enqPtrValue[1] = enqPtrVec_1_value
        · n_enqPtrVec_2_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_2_value：RobEnqPtrWrapper.io_out_2_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_2_value']；enqPtrVec_2_value: 基例 [2]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,97] L1=[2,159] L2=[0,98] L3=[3,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_2_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: n_enqPtrVec_2_value 穷举 1 组（枚举 []）值域 [0,159]
        · xs_Rob_core.enqPtrValue[2] = enqPtrVec_2_value
        · n_enqPtrVec_3_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_3_value：RobEnqPtrWrapper.io_out_3_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_3_value']；enqPtrVec_3_value: 基例 [3]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,98] L1=[3,159] L2=[0,99] L3=[4,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_3_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: n_enqPtrVec_3_value 穷举 1 组（枚举 []）值域 [0,159]
        · xs_Rob_core.enqPtrValue[3] = enqPtrVec_3_value
        · n_enqPtrVec_4_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_4_value：RobEnqPtrWrapper.io_out_4_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_4_value']；enqPtrVec_4_value: 基例 [4]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,99] L1=[4,159] L2=[0,100] L3=[5,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_4_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: n_enqPtrVec_4_value 穷举 1 组（枚举 []）值域 [0,159]
        · xs_Rob_core.enqPtrValue[4] = enqPtrVec_4_value
        · n_enqPtrVec_5_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_5_value：RobEnqPtrWrapper.io_out_5_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_5_value']；enqPtrVec_5_value: 基例 [5]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,100] L1=[5,159] L2=[0,101] L3=[6,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_5_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: n_enqPtrVec_5_value 穷举 1 组（枚举 []）值域 [0,159]
        · xs_Rob_core.enqPtrValue[5] = enqPtrVec_5_value
        · xs_Rob_core.allocatePtrValue[1]：allocatePtrValue[i] = enqPtrValue[0] 默认，再按 allocSel[i]==3'(k) 覆盖为 enqPtrValue[k]，k∈[0,5]；候选 enqPtrValue[0, 1, 2, 3, 4, 5]；并集 [0,159]
        · xs_Rob_core: allocatePtrValue[1] 穷举 1 组（枚举 []）值域 [0,159]
        · Rob: n_allocatePtrVec_1_value 穷举 1 组（枚举 []）值域 [0,159]
    [W5_addr ref <- enqPtrVec_0_value] M3 PASS_C[ref]: ∈ [0,159] ⊆ [0,159]（无条件，未用接口契约）；来源 [('RobEnqPtrWrapper', 'io_out_0_value')]
        · enqPtrVec_0_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_0_value：RobEnqPtrWrapper.io_out_0_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_0_value']；enqPtrVec_0_value: 基例 [0]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,95] L1=[0,159] L2=[0,96] L3=[1,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_0_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: enqPtrVec_0_value 穷举 1 组（枚举 []）值域 [0,159]
    [W5_addr impl <- n_enqPtrVec_0_value] M3 PASS_C[impl]: ∈ [0,159] ⊆ [0,159]（无条件，未用接口契约）；来源 [('RobEnqPtrWrapper', 'io_out_0_value')]
        · n_enqPtrVec_0_value <- RobEnqPtrWrapper(enqPtrGenModule).io_out_0_value：RobEnqPtrWrapper.io_out_0_value ∈ [0,159]（联合归纳寄存器 ['enqPtrVec_0_value']；enqPtrVec_0_value: 基例 [0]；路径0[io_redirect_valid]: 穷举 256 组（枚举 ['io_redirect_bits_robIdx_value']）值域 [0,159]；三元叶 L0=[0,95] L1=[0,159] L2=[0,96] L3=[1,159]；路径1[!io_redirect_valid]: 穷举 166 组（枚举 ['enqPtrVec_0_new_value_2']）值域 [0,159]；三元叶 L0=[0,5] L1=[0,159]）
        · Rob: n_enqPtrVec_0_value 穷举 1 组（枚举 []）值域 [0,159]
  => AUDIT_PASS  （入表只是允许两侧对称黑盒；转绿仍须 clean native FM 结果）
```

`--check`（6 条）rc=0；既有 5 条的输出与改前逐字节相同（前 80 行 diff 为空）。

正负测 `scripts/test_audit_ram_shape_c.py`（进 gate_all）15/15：
P1 同源子模块正例；N1 写死 sha 不同；N2 子模块端口由输入直通驱动（追不到寄存器）；N3 选择的一个候选越界（FAIL）；
N4 契约缺失：外部 idx 未归一化直写指针（FAIL，不偷加契约）；N5 递归超限（子模块里还有子实例）；
N6 (0232-a) reset 合法但 next-state 支路可产生 6（FAIL）；N7 (0232-b) ref 拼接 3 元素 / 2 位下标有 OOB 分支（MANUAL）；
N8 (0232-b) impl 选择缺默认赋值（MANUAL）；N9 impl 侧同名单侧 wrapper；N10 子实例参数覆盖；N11 子模块 always 里有 case；
P2 / N12 / N13 闭包核对正例 / RTL_SRCS 同名定义 / 不在 GOLDEN_CLOSURE_SHARED。
原有 test_audit_ram_memory_model 25/25、test_audit_ram_manual_review 全过。

## 步 3：verif/vendor_boundary.tsv 新增行（全文）

`python3 scripts/check_closure_symmetry.py --check-registry` → OK。

```
dt_pcTransType_160x2	APPROVED_MEMORY_MACRO_MODEL	codex 0230 单条审定（codex 0232 批准 M3 形态 C；仅授权 CtrlBlock 当前闭包内 Rob 的 rob/dt_pcTransType_ext 一个实例两侧对称 interface-only 黑盒，父级范围由 scripts/audit_ram_memory_model.py MANUAL_REVIEW_PARENTS 写死；不是通用 ELAB-147 例外，不得推广到其他 *_160x2 或名字相似模块）：可复跑审查命令 python3 scripts/audit_ram_memory_model.py dt_pcTransType_160x2 --parent-ref Rob.sv --parent-impl rtl/backend/Rob.sv（亦在 --check / verif/ram_model_parents.tsv）；M1 memory-only —— 正文与 firtool 行为级 RAM 8 读口 6 写口模板逐字相等（1 个 reg [1:0] Memory[0:159] + 1 条 always @(posedge W0_clk) 内 W0..W5 顺序非阻塞写（同址后口赢）+ 8 条组合读 assign Rk_data = Rk_en ? Memory[Rk_addr] : 2'bx（k=0..7），另加 ifdef ENABLE_INITIAL_MEM_ 仿真专用随机初始化，SYNTHESIS 下不存在），无状态机/无算术/无其它功能逻辑，宏定义头 sha256=2b68dde00e97ee9a 与家族参照件 ram_40x47.sv 逐字节相同；M2 —— golden Rob.dt_pcTransType_ext 与 rtl/backend/Rob.sv 的 dt_pcTransType_ext 两侧各恰好 1 个例化，56 个端口逐名相同，常量连接签名相同（R0..R7_en=1）；M3 —— 形态 C 无条件 PASS_C（14 口 × 两侧 28 处全部，未用接口契约）：R0..R7 <- NewRobDeqPtrWrapper.io_out_{7..0}_value，W5 <- RobEnqPtrWrapper.io_out_0_value，W0..W4 <- allocatePtrVec_{5..1}（ref 为 enqPtrVec 的拼接 8 选 1，下标 3 位全覆盖；impl 为可读核「默认 enqPtrValue[0] + 逐项覆盖」选择，候选 enqPtrValue[0..5]）；两个子模块两侧同读 G1 文件（NewRobDeqPtrWrapper sha256 03a69b65a94c69f0…、RobEnqPtrWrapper sha256 3874e460d979b61f…，写死于 SHAPE_C；CtrlBlock closure.mk 列为 GOLDEN_CLOSURE_SHARED、RTL_SRCS 无同名定义），各 1 实例、无参数覆盖、clock/reset 接父级；子模块寄存器联合归纳：deqPtrVec_k 复位 k、唯一更新 commitDeqPtrVec_k（{deqPtrVec_0[7:3],3'h0}+j 后 >=160 减 160 的选择链），exception robIdx 只用于比较；enqPtrVec_k 复位 k，redirect 支路对任意 8 位 robIdx 加 0..6 后 >=160 减 160（最大 261-160=101），正常推进当前值 <160 加 <=6 后回卷，均穷举证明 ∈[0,159]；★2^8=256 与 160 之间那 96 个越界地址正是白盒化时 FMR_ELAB-147 的来源，但本条审定依据的是上面三项功能事实，不是诊断文本★；★入表不等于转绿：CtrlBlock 仍以其 official native 结果为准★	dt_pcTransType_160x2.sv	a47be472a7ebd4721e65ee6e9807c3389f712675f2afeed80ecf400d8adc80f9	56	input [7:0] R0_addr;input R0_en;input R0_clk;output [1:0] R0_data;input [7:0] R1_addr;input R1_en;input R1_clk;output [1:0] R1_data;input [7:0] R2_addr;input R2_en;input R2_clk;output [1:0] R2_data;input [7:0] R3_addr;input R3_en;input R3_clk;output [1:0] R3_data;input [7:0] R4_addr;input R4_en;input R4_clk;output [1:0] R4_data;input [7:0] R5_addr;input R5_en;input R5_clk;output [1:0] R5_data;input [7:0] R6_addr;input R6_en;input R6_clk;output [1:0] R6_data;input [7:0] R7_addr;input R7_en;input R7_clk;output [1:0] R7_data;input [7:0] W0_addr;input W0_en;input W0_clk;input [1:0] W0_data;input [7:0] W1_addr;input W1_en;input W1_clk;input [1:0] W1_data;input [7:0] W2_addr;input W2_en;input W2_clk;input [1:0] W2_data;input [7:0] W3_addr;input W3_en;input W3_clk;input [1:0] W3_data;input [7:0] W4_addr;input W4_en;input W4_clk;input [1:0] W4_data;input [7:0] W5_addr;input W5_en;input W5_clk;input [1:0] W5_data	ce49071289bb9bfa	none	symmetric_both_sides_only;regimeA=fm_blackbox_both_sides;regimeB=FORBIDDEN_oob_static_index;single_side_read=FORBIDDEN;pin_by=leaf_sha256	160	none	nclk=14;clk=R0,R1,R2,R3,R4,R5,R6,R7,W0,W1,W2,W3,W4,W5;access=8r6w
```

## 步 4：scripts/proof_certificate.py 改动

- 新函数 `approved_memory_interface_designs(repo, parent_commit, allow, g1_root)`：取 allow 里 class=APPROVED_MEMORY_MACRO_MODEL
  且 attrs='i'（interface-only）的 design；每个都须逐项成立，否则整体 fail-closed：
  1. 该 design 的全部 allow 对象都是 APPROVED_MEMORY_MACRO_MODEL + attrs='i'（与 vendor_macro / green_child / 'u' 混用即错）；
  2. r/i 各 ≥1、数目相等、去前缀路径集合相同、无重复；
  3. **父 commit** 的 vendor_boundary.tsv 恰好一行字面同名、kind=APPROVED_MEMORY_MACRO_MODEL、body_rule 含
     symmetric_both_sides_only 与 pin_by=leaf_sha256；
  4. G1 文件字节 sha256 == 登记 leaf_sha256 == G1 MANIFEST；
  5. G1 文件过 M1 精确模板（防「登记行伪造成指向普通逻辑模块」）。
- `validate_certificate_current` 的 hdlin_interface_only 判据：回读（Tcl list、不许重复）去重排序后必须**严格等于**
  green_child 集合 ∪ 上述集合；同一 design 两类都占即错。attrs='u' 的 memory（GrantBuffer / L2TlbMissQueue 等既有
  证书的形态）不进回读集合，既有证书判定不变（test_proof_certificate 95/95、nested 22/22、grandchild 全过）。
- ★取 attrs='i' 是对 0230 原文「本 allow 中逐条登记且当前有效的 APPROVED_MEMORY_MACRO_MODEL design 集合」的落地解释★：
  若把 'u'（两侧不读、未解析黑盒）的 memory 也算进去，GrantBuffer / L2TlbMissQueue / Queue40 / Queue78 / Slice×4
  共 8 份既有证书会立刻失效（它们回读为空）。请 reviewer 确认此解释。

正负测 `scripts/test_proof_certificate_memory.py`（进 gate_all）16/16：
P0 GC + memory 并集；P1 回读乱序；P2 'u' 形态 memory 不进回读；M1 漏 memory；M2 多一项；M3 未登记 RAM（冻结夹具，样本是
夹具表里根本没有的名字）；M4 G1 字节与登记 hash 不同；M5 登记 kind 错；M6 allow 一侧写成 vendor_macro；M7 单侧路径；
M8 两侧路径不同名；M9 普通逻辑伪装 memory（登记行 sha 与 G1 一致，M1 模板拦下）；M10 同一 design 既 GC 又 memory；
M11 'i'/'u' 混用；M12 body_rule 缺对称约束；M13 回读重复。（夹具复用 test_proof_certificate_nested.Tree，新增
extra_gold / extra_files / g1_override 三个钩子，原 22 条不变。）

## 步 5/6：gate_all

见文末「gate_all 结果」。

## 第二轮 · 步 7：CtrlBlock 证书在新 validator 下是否 current-valid —— **否，STOP**

方法：临时 worktree（detached，已删除）= wt-backend-asm HEAD 4dc41afc619f7ec5a437bf778394947d059397d8 上覆盖本 lane 的
scripts/audit_ram_memory_model.py、scripts/proof_certificate.py、verif/vendor_boundary.tsv、verif/ram_model_parents.tsv
（来自 ef8ea97244f8a0295f59fbc2b42bff36e7638e8d），提交为临时 commit bf2a9079553e8760199b3d6560438935cc60c976（不在任何分支）；
对其 tracked `verif/proof_certificates/CtrlBlock.json`（blob sha256 b179fcc972269178d0cc112c0a3c5bdffbba5b6a5db340065be89b3a9b1a101a，
verdict PASS_DEAD_REF，impl_commit 9df1c6fb0545）跑 `validate_certificate_current`（policy / fm_targets / G1 均按父 commit）。
未改 wt-backend-asm、未跑 FM、未重出证书。

| validator | CtrlBlock current-valid |
|---|---|
| 旧（wt-backend-asm HEAD） | `green_child_interface_only_not_declared_set:CtrlBlock:readback=[diff_rat_state_bank_320x776, dt_pcTransType_160x2, stateBankTags_320x3],green_child=[]` |
| 新（本 lane） | `green_child_impl_golden_not_fm_target:CtrlBlock:dt_pcTransType_160x2` |

interface_only 并集判据已过（memory 集合 = 上述三个，全部通过 registry / G1 hash / class / 对称路径 / M1 校验）。
新的拦截来自 `validate_impl_golden_certified`：CtrlBlock 证书 impl 闭包里挂着 76 个 golden 文件，其中
**dt_pcTransType_160x2 / diff_rat_state_bank_320x776 / stateBankTags_320x3 三个**既不是 FM target、也不在
verif/mc_memory_registry.tsv 里（其余 73 个都是有 tracked 证书的 FM target）。三者是两侧都以 -interface_only 读入的
同一份 G1 字节（ref golden 闭包里有逐字节同一份），这正是 APPROVED_MEMORY_MACRO_MODEL 对称边界的形态，但这条
「impl 侧挂 golden」判据目前只认 FM target 证书或 MC 登记，0230 没有覆盖。

探针（只在内存里替换 `impl_golden_entries`，不改文件）：把「属于本证书已验证 memory 集合、且 ref 闭包有逐字节同一份」
的三条 golden 条目跳过后，CtrlBlock current-valid = **True**。即**剩下的唯一阻塞**就是这一条判据。

需要裁定（不自行处置）：是否允许 `validate_impl_golden_certified` 在 MC 分支之外再加一个与之并列的分支——
golden 条目的 module 恰是本证书 allow 里经 `approved_memory_interface_designs` 校验通过的 interface-only
APPROVED_MEMORY_MACRO_MODEL design，且 ref golden 闭包有逐字节同一份时放行（不改登记表、不改 MC registry）。
批准后改动只在 proof_certificate.py 一处 + 正负测，CtrlBlock 证书可按 0230 直接用现有证书判 current-valid（无需重跑 FM）。
