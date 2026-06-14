# ICacheCtrlUnit —— ICache ECC 控制/注入单元

| | |
|---|---|
| 手写 SV | `rtl/frontend/ICacheCtrlUnit.sv`（`xs_ICacheCtrlUnit_core` + `xs_Queue1_RegMapperInput`）+ `rtl/frontend/ICacheCtrlUnit_wrapper.sv`（golden 同名顶层 `ICacheCtrlUnit`）+ `rtl/frontend/Queue1_RegMapperInput_3_wrapper.sv`（golden 同名队列） |
| Scala 来源 | `src/main/scala/xiangshan/frontend/icache/ICacheCtrlUnit.scala` |
| 验证状态 | UT ✅（6 万拍 0 错，checks=60000）/ FM ✅（Queue1_RegMapperInput_3 与 ICacheCtrlUnit 均 SUCCEEDED，0 unmatched） |

## 功能

ICacheCtrlUnit 通过一个 **TileLink-UL 寄存器映射（RegMapper）** 总线挂在 ICache 旁，给软件
提供 ECC 控制与「注错」（error injection）能力，用于诊断/测试 ICache 的 ECC 通路。

它做两件事：
1. **寄存器读写**：把 A 通道的读/写请求解码成对 3 组寄存器（eccctrl / ecciaddr / iwaymask）
   的访问，并在 D 通道回 AccessAck/AccessAckData。
2. **ECC 注入 FSM**：软件写下注入命令后，自动「读 meta → 比较 tag 选 way → 写 meta 或写 data」
   往指定物理地址注入 ECC 错误。

## 寄存器映射

A 通道地址按 8 字节对齐，`index = address[6:3]` 选寄存器；合法寄存器写要求字节掩码全 1
（`&mask`）。本配置只用到 index 0 / 1（`index[3:1]==0` 判定为低寄存器区）。

| index | 寄存器 | 写 | 读回（D 通道 data） |
|-------|--------|----|---------------------|
| 0 | **eccctrl** | `data[0]`→enable、`data[1]`→注入使能、`data[3:2]`→itarget | `{…, ierror[2:0], istatus[2:0], itarget[1:0], 1'b0, enable}` |
| 1 | **ecciaddr** | `data[47:0]`→注入物理地址 paddr | `{16'h0, paddr[47:0]}` |
| 其它 | — | — | 0 |

eccctrl 内部字段：

- `enable`：ECC 检查总开关（复位值 1），驱动 `io_ecc_enable`。
- `itarget[1:0]`：注入目标，`0`=注 meta（tag），`2`=注 data；其余为非法。
- `istatus[2:0]`：`0`=idle，`1`=working（正在注入，驱动 `io_injecting`），`2`=injected（注入完成），`7`=error（命令非法/不注入即结束）。
- `ierror[2:0]`：`0`=无错，`1`=参数非法（itarget 非法），`2`=未命中（选 way 没命中）。

ecciaddr_paddr 字段切分：`paddr[13:6]`→vSetIdx、`paddr[47:12]`→phyTag、`paddr[6]`→bankIdx。

读 eccctrl 且 istatus 处于完成态（2 或 7）时，该读动作会顺带清状态/错误，回到 idle。

## 注入 FSM（istate）

软件向 eccctrl 写「注入使能=1 且 istatus 当前为 idle」即下发命令；若 `data[0]=1` 且 itarget
合法，istatus 进 working，istate FSM 启动：

| istate | 行为 |
|--------|------|
| INJ_IDLE(0) | istatus==working 时 → INJ_READ |
| INJ_READ(1) | 发 `io_metaRead`（vSetIdx=paddr[13:6]）；握手 → INJ_SELECT |
| INJ_SELECT(2) | 用 metaReadResp 的 entryValid & tag 比 paddr[47:12] 选命中 way（waymask）；锁存 iwaymask。命中：itarget==0→INJ_WMETA，否则→INJ_WDATA；未命中：→IDLE 且 istatus=error、ierror=miss |
| INJ_WMETA(3) | 发 `io_metaWrite`（phyTag/waymask/bankIdx）；握手 → IDLE，istatus=injected |
| INJ_WDATA(4) | 发 `io_dataWrite`（virIdx/waymask）；握手 → IDLE，istatus=injected |

ierror 在命令下发时按「itarget 非法→param、读清→none、select 未命中→miss」更新。

## 结构

- **xs_ICacheCtrlUnit_core**：寄存器组 + 注入 FSM + D 通道读数据组合逻辑。
  寄存器名沿用 golden（`eccctrl_*`/`ecciaddr_paddr`/`iwaymask`/`istate`）。
- **xs_Queue1_RegMapperInput**：深度 1 的 skid buffer（`full` + 82 位打包 `ram`），
  把 A 通道请求（read/index/data/mask/source/size）缓存一拍后送核心，并提供 D 通道的
  valid/source/size 反压。
- **ICacheCtrlUnit（wrapper）**：在顶层例化队列 + 核心，完成 TileLink A/D 对接：
  A 通道 `opcode==4'h4`(Get) 判读、`address[6:3]` 取 index 入队；
  D 通道 `valid=队列有响应`、`opcode={3'h0, read}`。

## 验证

- **UT**：golden `ICacheCtrlUnit` vs `ICacheCtrlUnit_xs` 双例化，复位后逐拍比对全部 19 个输出。
  随机激励覆盖：A 通道随机读/写请求（opcode 偏 Put/Get、index 偏 0/1 偶发越界、mask 偏全 1）、
  D 通道随机背压、meta/data 读写 ready 随机、metaReadResp 的 ptag 压缩值域以提高注入命中率。
  6 万拍 0 错。
- **FM**：`Queue1_RegMapperInput_3`（167 点）与 `ICacheCtrlUnit`（287 点）均 SUCCEEDED，
  全部按名配对、0 unmatched，无需 fm_map（寄存器名沿用 golden）。
  注：核心里 ierror/istatus、itarget/enable、ecciaddr、iwaymask、istate 各自拆成独立
  `always_ff`，结构对齐 golden 的分块条件赋值，避免 FM 把部分位判不等价。

## 未改动

未修改 `scripts/fm_eq.tcl`、`scripts/ut_common.mk` 及其它模块；本模块 FM 通用脚本即可通过，
无需改 fm_eq.tcl。
