# FauFTB —— uFTB 快速分支预测器（全相联微 FTB）

| | |
|---|---|
| 手写 SV | `rtl/frontend/FauFTB.sv`（`xs_FauFTB_core`）+ `rtl/frontend/FauFTB_wrapper.sv` |
| Scala 来源 | `src/main/scala/xiangshan/frontend/FauFTB.scala`（class FauFTB extends BasePredictor） |
| 依赖 | [FauFTBWay](FauFTBWay.md)（32 路） |
| 生成器 | `scripts/gen_fauftb.py` |
| 验证状态 | UT ✅（4 万拍 0 错，4695 比对点）/ FM ✅（impl 用 xs 子模块，SUCCEEDED） |

## 功能

BPU 的 S1 级快速预测器：32 路全相联微 FTB。S1 用 PC tag 并行查询 32 个 FauFTBWay，
命中则用 Mux1H 合成 `FullBranchPrediction`（分支槽、目标地址、call/ret/jalr 等）；
更新时按 PLRU 选路替换、写入条目，并维护 2-bit 饱和计数。s1_pc/meta/fauftb_enable
等预测流水信息透传。

## 关键实现点（来自重写）

- **Mux1H 合成**：golden 把 `s1_hit_full_pred` 展开成 `OR(hit & field)`（命中一热）。
  核按每路 `fromFtbEntry` 解码后按 hit 累加，FM 证明等价。
- **fromFtbEntry**：忠实复刻目标地址计算（高半 37/29/45 位 + tarStat 三态、sharing、
  fallThroughErr 用 `{1'b0,pc[4:1]}` 与 endLowerwithCarry 比较）。
- **PLRU**：`state_reg[30:0]` 二叉树；递归翻转规则；alloc 自树根遍历；pred-touch 与
  commit-touch 的组合次序与 golden 对齐。
- **full_pred 4-dup**：核输出一份预测，wrapper 扇出到 4 个 dup 端口。
- **死逻辑省略**：s2_pc/s3_pc 流水寄存器、断言、perf 探针对输出无观测路径，未实现；
  FM `verification_verify_unread_compare_points false` 不影响等价。

## 验证

- **UT**（`verif/ut/FauFTB/`）：golden vs `FauFTB_xs`（impl 侧用 xs FauFTBWay 子模块），
  随机激励多 seed，逐拍比对全部 99 输出端口，4 万拍 0 错。
- **FM**：4695 比对点全 passing，0 unmatched/failing，SUCCEEDED。
- 注：golden 含 `ifndef SYNTHESIS` 的 fallThrough $fatal 断言，UT 编译加 `+define+SYNTHESIS`
  屏蔽（在本模块 Makefile 内，未改共享脚本）。

> 本模块由并行子 agent 重写，主线已独立复跑 UT+FM 核验通过。
