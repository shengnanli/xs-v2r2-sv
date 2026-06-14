# FauFTBWay —— uFTB 单路

| | |
|---|---|
| 手写 SV | `rtl/frontend/FauFTBWay.sv`（`xs_FauFTBWay`）+ `rtl/frontend/FauFTBWay_wrapper.sv` |
| Scala 来源 | `src/main/scala/xiangshan/frontend/FauFTB.scala`（class FauFTBWay） |
| 生成器 | `scripts/gen_fauftbway.py` |
| 验证状态 | UT ✅（6 万拍 0 错）/ FM ✅（SUCCEEDED） |

## 功能

全相联微 FTB（[FauFTB](FauFTB.md)）的一路。寄存一个 FTB 条目（data，打包 60 位）+
tag（16 位）+ valid：

- **读**：`tag == io_req_tag && valid` → `io_resp_hit`；`io_resp` 原样透出存储条目
- **更新查询**：`io_update_hit = (tag命中且valid) | (本拍写同tag)`（写旁路避免重复命中）
- **写**：`io_write_valid` 时写入 tag/entry，置 valid

## 接口

| 信号 | 方向 | 说明 |
|------|------|------|
| `io_req_tag` | in[15:0] | 查询 tag |
| `io_resp_*` / `io_resp_hit` | out | 条目各字段 / 命中 |
| `io_update_req_tag` / `io_update_hit` | in/out | 更新查询 |
| `io_write_valid` / `io_write_entry_*` / `io_write_tag` | in | 写入 |

entry 作为不透明打包数据（ENTRY_W=60）整体存取，字段拼接由 wrapper 处理。

## 验证

- **UT**：golden vs `FauFTBWay_xs`，随机读/更新/写（tag 值域压缩提高命中率），6 万拍 0 错。
- **FM**：SUCCEEDED。golden 逐字段寄存器 `data_<field>` 经生成器输出的 `fm_map`
  映射到核的扁平 `data_reg` 切片（`match_packed_payload` 机制）。
