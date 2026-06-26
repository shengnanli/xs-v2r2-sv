# Backend BT —— 块级（整 Backend 子系统）验证

> 照 `verif/bt/Frontend/` 样板 + `verif/it/README.md` 方法学。
> golden `Backend` (u_g) vs 部分重写装配 `Backend_bt` (u_i)，双例化逐拍比对 723 个 Backend 顶层功能输出。

---

## 1. 覆盖范围（诚实）

本 BT **不是**整 Backend 45 子模块全重写直连。原因（结构性，非偷懒）：

工程里的重写 Backend 核被设计成 **与 golden 同名的直替件**（为 ST `substitute.sh` 直接替进
`build/rtl`）。`Scheduler`/`Scheduler_1/2/3`、`ExeUnit`、`IssueQueue*`、`Rob`、`Rename`、
`DecodeStage` 等重写核 **复用 golden 名**，且彼此/对 golden 叶子按 golden 名互联。
在 BT「同一次 elaborate 里 golden + rewrite 双例化」场景下，这会 **大面积命名冲突**。
要消解须为每个重写核做 `_it`/`_bt` 重命名机械——这套机械目前只对
**Int Scheduler / Exec / Decode / RenameDispatch / Writeback** 这 5 个 IT 簇做过
（见 `verif/it/{Issue,Exec,Decode,RenameDispatch,Writeback}/`，均已 seed1/7/42 通过）。

因此本 BT 取 **能干净双例化、且重写核功能完整** 的最大子集：
把 golden Backend 的 **权威互联 body**（4.7 MB，golden `Backend.sv` 逐字）作底，
只把以下两个子模块实例的模块名换成 `_bt` 包装（内含真重写 `xs_*_core`）：

| golden 实例 | 换成 | 链路 |
|---|---|---|
| `WbFuBusyTable inner_wbFuBusyTable` | `WbFuBusyTable_bt` | → `WbFuBusyTable_xs` → **`xs_WbFuBusyTable_core`** |
| `BypassNetwork inner_bypassNetwork` | `BypassNetwork_bt` | → `BypassNetwork_xs` → **`xs_BypassNetwork_core`** |

其余 43 子模块（CtrlBlock / Scheduler×4 / DataPath / ExuBlock×3 / WbDataPath /
Og2ForVector / VecExcpDataMergeModule / NewPipelineConnectPipe×N / DelayN / PFEvent /
HPerfMonitor）保留 golden。

> **被测的真 rewrite-to-rewrite 边界**：`xs_BypassNetwork_core` 的旁路网络输出 ↔
> `xs_WbFuBusyTable_core` 的写回忙表，二者都在 Backend 互联里被 golden DataPath/ExuBlock/
> Scheduler 包围，整子系统逐拍比 golden。这是 per-module UT 看不到的集成边界
> （UT 里两核各自被 golden 团团围住，从未一起跑）。

### DataPath（已就绪但未纳入，如实标注）
`DataPath_bt.sv` + `xs_DataPath_core` 链路已生成可用，但 **未纳入功能 PASS**：
1. `xs_DataPath_core` 例化 difftest 探针 `DummyDPICWrapper_9`（ArchIntRegState 变体，
   端口 `io_bits_value_0..7`），与 golden Backend 全闭包里 **同名** 的 `DummyDPICWrapper_9`
   （PTW/L2TLB 变体，端口 `io_bits_satp…`）**编号撞名** → VCS 取错定义 → 端口未定义编译错。
   须为 DataPath 的 difftest 探针做 BT 局部 stub 才能纳入。
2. `xs_DataPath_core` 真省略 410 个功能透传/元数据 output（`preDecode_*`/mem-IQ
   `iqIdx/srcTimer/lqIdx`/`og1resp` 等，golden 里非纯直通、含逻辑，无法机械重建），
   纳入会在顶层产生量化分叉，须列 nonfunc。

---

## 2. `_bt` 包装做法（忠实，零强制置零）

每个 `<M>_bt`（`gen_bt.py` 生成）：
- **全套 golden 端口**（顶层端口逐字 = golden `<M>`，故可在 golden body 里按名直替实例）。
- 例化已验证的 **`<M>_xs` 适配器**（端口 = golden 名子集 + 真重写 glue + `xs_<M>_core`）。
- golden-only output 处理：**先扫 golden 模块体的 `assign <out> = <port>;` 纯透传规则**，
  能机械重建的（典型 ready 背压 `io_fromDataPath_X_ready = io_toExus_X_ready`、忙表自反馈位）
  **按 golden 同规则重建**，保功能等价；其余才接 `'0` 列 nonfunc。
- **本 BT 两个 active 模块 reconstructed=299+2, tied(nonfunc)=0+0** —— 即 **无任何功能
  输出被强制置零**，BypassNetwork/WbFuBusyTable 全端口忠实（见 `gen_bt.py` 输出 / `nonfunc_ports.json`）。

---

## 3. 纯重写确认（grep 可证）

```
Backend_bt.sv:   WbFuBusyTable_bt inner_wbFuBusyTable / BypassNetwork_bt inner_bypassNetwork
*_bt.sv:         例化 <M>_xs u_xs
<M>/variants_xs: 例化 xs_<M>_core u_core   (xs_BypassNetwork_core / xs_WbFuBusyTable_core)
```
rewrite 侧模块名：`{BypassNetwork,WbFuBusyTable}_bt`、`xs_{BypassNetwork,WbFuBusyTable}_core`
—— 均与 golden 无命名冲突，两侧同时 elaborate 0 错。

---

## 4. tb / Makefile

- `tb.sv`：由 `verif/ut/Backend/tb.sv` 改造——u_i 换 `Backend_bt`；`+NCYCLES=<n>` 可调；
  723 个顶层输出逐拍 `!$isunknown(golden)` 守门比对；新增 `nonfunc_errors` 单列（本 BT 为 0）。
- `Makefile`：`include ../../../scripts/ut_common.mk`（复用，未改）。
  - `RTL_SRCS` = bypassnetwork/wbfubusytable pkg + 2 个 `xs_*_core` + 2 个 `_xs` 适配器 + 2 个 `_bt` 包装 + `Backend_bt.sv`。
  - `GOLDEN_SRCS` = golden `Backend.sv` + 31 直接子模块类型；`-y GOLDEN_RTL` 自动解析更深共享叶子。
  - `+define+SYNTHESIS`（关 golden 断言/difftest 随机初值）；`+vcs+initreg+random` 编译 / `+vcs+initreg+0` 运行；`-assert disable`。

---

## 5. 复跑

```bash
cd verif/bt/Backend
source ../../../scripts/env.sh
make compile
for s in 1 7 42; do ./simv +ntb_random_seed=$s +vcs+initreg+0 +NCYCLES=100000 -l sim_$s.log; done
grep -E "distinct_diverging_ports|checks=|TEST" sim_*.log
```

扩展：`python3 gen_backend_bt.py WbFuBusyTable BypassNetwork [DataPath...]` 选择换哪些实例；
`python3 gen_bt.py` 重生 `_bt` 包装。

---

## 6. 结果

见各 `sim_<seed>.log`：seed 1/7/42 各 100000 拍，`errors=0`、`nonfunc_errors=0`、
`distinct_diverging_ports=0/723`。
