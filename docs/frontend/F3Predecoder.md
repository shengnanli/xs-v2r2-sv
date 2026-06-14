# F3Predecoder —— F3 阶段分支预译码

| | |
|---|---|
| 手写 SV | `rtl/frontend/F3Predecoder.sv`（`xs_F3Predecoder_core`）+ `rtl/frontend/F3Predecoder_wrapper.sv` |
| 共享译码 | `rtl/frontend/predecode_pkg.sv`（与 [PreDecode](PreDecode.md) 复用） |
| Scala 来源 | `src/main/scala/xiangshan/frontend/PreDecode.scala`（class F3Predecoder） |
| 验证状态 | UT ✅（20 万随机向量 0 错）/ FM ✅（SUCCEEDED） |

## 功能

IFU 的 F3 级对 `PredictWidth`(=16) 条**已对齐的 32-bit 指令**做分支信息译码，仅输出
每条的 `brType`/`isCall`/`isRet`（该模块不产出 valid/isRVC，Chisel 中为 DontCare，
firtool 未引出对应端口）。纯组合。

与 PreDecode 的区别：PreDecode 输入是未对齐的半字流、还需做 RVC 边界检测与偏移计算；
F3Predecoder 输入已是对齐指令，只取分支译码这一子集。两者的分支译码（brType/isCall/
isRet）语义完全相同，统一由 `xs_predecode_pkg` 提供（单一来源，避免分叉）。

## 接口

| 信号 | 方向 | 说明 |
|------|------|------|
| `io_in_instr_0..15` | in [31:0] | 16 条对齐指令 |
| `io_out_pd_i_brType` | out [1:0] | 分支类型（notCFI/branch/jal/jalr） |
| `io_out_pd_i_isCall` / `isRet` | out | 是否 call / ret |

## 验证

- **UT**（`verif/ut/F3Predecoder/`）：golden vs `F3Predecoder_xs`，20 万随机指令向量
  逐拍比对全部 48 个输出；0 错误。
- **FM**（`make fm`）：SUCCEEDED。
