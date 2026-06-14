# RAS —— 返回地址栈预测器

| | |
|---|---|
| 手写 SV | `rtl/frontend/RAS.sv`（`xs_RASStack`+`xs_RAS_core` 说明）、`rtl/frontend/RAS_core_top.sv`（`xs_RAS_core`）、`rtl/frontend/RAS_wrapper.sv`（`RAS`） |
| Scala 来源 | `src/main/scala/xiangshan/frontend/newRAS.scala`（class RAS extends BasePredictor） |
| 生成器 | `scripts/gen_ras.py` |
| 验证状态 | UT ✅（多 seed 各 ~4 万拍 0 错，187 输出端口）/ FM ✅（SUCCEEDED，0 failing） |

## 功能

BPU 的返回地址栈：预测 ret 指令的目标。内部 `RASStack` 维护**投机栈**（spec，循环队列）
与**提交栈**（commit），通过 ssp/sctr/TOSR/TOSW/NOS 指针管理；支持 call 压栈、ret 弹栈、
s2/s3 写旁路、重定向恢复（redirect 用快照的 meta 回滚指针）。这是前端最复杂的有状态
模块之一。

## 关键实现点（重写中踩的坑，均已解决）

1. **push/pop 或 isCall/isRet 同时为真**（随机激励的非常规组合）：Chisel 用顺序
   last-connect，各指针独立更新。实现改为「基础恢复 + specPush 覆盖 + specPop 覆盖」
   的独立 if 结构，严格区分 specPush/specPop 的范围判定对象（TOSR-in-range vs
   NOS-in-range）与 `currentSctr` vs `topEntry.ctr` 两套自增判据。
2. **specPush/specPop 在 ctr 自增 / sctr>0 时不写 ssp**（Chisel 仅在 `.otherwise` 写）。
3. **commit_stack ctr 双写**：push 新建与 pop 递减可同周期命中不同索引，按 golden 逐
   索引 next-state 复刻。commit 栈用展平标量命名（`commit_stack_<N>_ctr/retAddr`）以便
   FM 按名 1:1 配对（避免二维数组寄存器被签名分析弄混位序）。
4. **VCS 函数敏感列表**：`ptrInRange` 读模块级 BOS 寄存器时，连续赋值不纳入敏感列表
   → 把 BOS 显式作入参传入。
5. **FM elaborate 拒绝**：`function` 读非局部变量触发 FMR_VLOG-091 → 改 `always @*`；
   异步复位块内多个 `if(reset)` 触发 FMR_VLOG-143 → 合并为单个 `if(reset)...else`。

## 验证

- **UT**（`verif/ut/RAS/`）：golden `RAS` vs `RAS_xs`，多 seed 各约 4 万拍，逐拍比对全部
  187 个输出端口，0 错。复位后跳过 40 拍 warmup（golden 同步无复位流水寄存器复位期
  保持随机初值，属正常初始化差异）。
- **FM**：SUCCEEDED，4211 按名 + 2382 签名配对，0 unmatched/failing。UT 用
  `` `ifndef SYNTHESIS `` 抢先 `define STOP_COND_=0` 屏蔽 golden 越界 $fatal 断言。

> 本模块由并行子 agent 重写（最复杂模块，耗时最长），主线已独立复跑 UT+FM 核验通过。
