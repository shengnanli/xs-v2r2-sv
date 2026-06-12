# xs_IndexableCAM —— 可按索引写入的 CAM

| | |
|---|---|
| 手写 SV | `rtl/common/IndexableCAM.sv` |
| Scala 来源 | utility 子模块 `IndexableCAMTemplate`（按香山前端 1 读 1 写用法实现） |
| 验证状态 | 随 WrBypass UT/FM 验证（5 种参数组合） |

## 功能

`NUM_ENTRIES` 项、每项 `ENTRY_WIDTH` 位的全相联内容寻址存储器：

- **读（组合）**：`io_r_req_idx` 与全部条目并行等值比较，输出逐条目命中位图
  `io_r_resp[NUM_ENTRIES-1:0]`；
- **写（同步）**：`io_w_valid` 时把 `io_w_bits_data` 写入第 `io_w_bits_index` 项。

条目寄存器**不复位**：上电内容未定义，可能产生假命中，上层必须用类似
`ever_written` 的有效位屏蔽（见 [WrBypass](../frontend/WrBypass.md)）。

## 接口

| 信号 | 方向 | 位宽 | 说明 |
|------|------|------|------|
| `clock` | in | 1 | |
| `io_r_req_idx` | in | ENTRY_WIDTH | 查询键 |
| `io_r_resp` | out | NUM_ENTRIES | 命中位图（组合） |
| `io_w_valid` | in | 1 | 写使能 |
| `io_w_bits_data` | in | ENTRY_WIDTH | 写入内容 |
| `io_w_bits_index` | in | clog2(NUM_ENTRIES) | 写入条目号 |

## 与 Chisel 模板的差异

Chisel 的 `IndexableCAMTemplate` 支持多读口、可选的按索引读出（`isIndexable`）。
前端现用场景均为 1 读 1 写且不需要索引读出，本实现只覆盖该子集；扩展时再加参数。
