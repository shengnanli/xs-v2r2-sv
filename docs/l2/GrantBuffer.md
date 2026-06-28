# GrantBuffer —— coupledL2 (tl2chi) L2 slice 授权(D)/确认(E) 路径

可读重写核 `xs_GrantBuffer_core`（`rtl/uncore/GrantBuffer.sv`），golden 同名装配壳
`GrantBuffer`（`rtl/uncore/GrantBuffer_wrapper.sv`）。设计源
`coupledL2/src/main/scala/coupledL2/GrantBuffer.scala`。golden 1599 行。

## 功能：向上层 L1 发 Grant，收 GrantAck，并做容量反压

数据流（按出现顺序）：

1. **入队**：MainPipe 投来 `d_task`(TaskWithData)。task 进 `grantQueue`(16 深 FIFO)，
   512bit 数据切两个 256bit beat 进 `grantQueueData0/1`。`HintAck`(opcode==2，预取响应)
   不入 grantQueue，单独走 `pftRespQueue`(10 深) 回 Prefetcher。
2. **mergeA 重组**：当 `d_task.mergeA`（把一个 A 请求并进 release 的 Grant）时，用
   `aMergeTask` 的字段重组入队 task（off/alias/opcode/param/sourceId/meta/isKeyword 取
   aMergeTask，其余清 0 或沿用）。核里以 `mergeAtask`(清 0 后逐项覆盖) + 整包
   `enqTask = mergeA ? mergeAtask : d_task` 收敛 golden 的 ~90 路逐字段 Mux。
3. **出队组 TLBundleD**：`grantQueue` 出队 → `toTLBundleD` 发 `io.d` 给 L1。GrantData
   两拍：首拍直发，第二拍存 `grantBuf`（单深寄存器），下一拍 `io.d` 优先发 grantBuf。
   keyword 重排：出队首拍数据 `isKeyword ? beat1 : beat0`，存进 grantBuf 的反过来取。
4. **inflightGrant[16]**：发出 Grant/GrantData/mergeA 时在空槽（`PriorityEncoder(~valid)`）
   记下 {set,tag}；收到 `io.e`(GrantAck，sink=槽号) 清除。`grantStatus` 即该表，供
   SourceB 阻塞同址 Probe（防 Probe 抢跑未确认的 Grant）。
5. **容量反压** `toReqArb`：统计流水级 1..4 中 fromA(channel[0])/fromC(channel[2]) 占用 +
   各 FIFO 计数，逼近容量时阻塞 Sink/MSHR/B 入口：
   - `blockA = (cntAC+grantQ≥16) | (cntA+inflight≥16) | (cntA+pftQ≥10)`
   - `blockC = cntAC+grantQ≥16`
   - `blockMSHR = (cntAC+grantQ≥15) | (cntA+inflight≥15) | (cntA+pftQ≥9)`（留一拍 s1 余量）
   - `blockB = ∃ inflightGrant 与 ReqArb s1 的 B-set/tag 同址`

## 黑盒（FIFO 叶，在壳内例化，两侧一致）
| 实例 | 模块 | 内容 |
|------|------|------|
| `grantQueue` | `Queue16_GrantQueueTask` | {TaskBundle, grantid}，16 深 |
| `grantQueueData0/1` | `Queue16_GrantQueueData` | 各一个 256bit beat |
| `pftRespQueue` | `Queue10_GrantBuffer_Anon` | 预取响应，10 深 |

核 `xs_GrantBuffer_core` 做除 FIFO 外的全部逻辑，暴露与队列对接的边界端口。

## 重写要点
- **mergeA 用 TaskBundle 结构体**：`enqTask = mergeA ? mergeAtask : dtask` 一条 Mux 替掉
  golden 在队列例化处的 ~90 路逐字段三元。
- **inflightGrant 用数组 + genvar/for**：分配/释放/同址比较以 `for` 写，FM 原生配对通过
  （表项各由 `e.sink==k`/`insertIdx==k` 区分，签名可辨）。
- **反压算式严格对齐 golden 位宽**：队列计数在 FM 里是自由 cut-point（可超 16），故
  `sum_grant/sum_infl` 截断 5bit、`sum_pft` 截断 4bit，照搬 golden 的 `[4]`/`>5'hE`/`>4'h9`
  判定，否则 FM 会在 count>15 处反例。
- **perf 计数器省略**：`timers/REG/enable_REG`（仅喂 XSPerf/assert）不驱动任何输出。

## 验证
- UT 双例化逐拍比对 `GrantBuffer` vs `GrantBuffer_xs`，seed 1/7/42 各 200000 拍：
  `errors=0 ierr=0`（输出 + inflightGrant[16] + grantBuf 内部探针）。
- FM `make fm`：**SUCCEEDED**。FIFO 叶两侧取同一 golden 真叶（叶内 `ram_*` 厂商宏自动黑盒），
  消除「仅喂被裁剪 assert 的 unread 黑盒输出引脚 `io_enq_ready`」导致的比对点失配；
  ram 行为模型的越界索引告警在 Formality 会升级为链接错误，故 ram 不进 FM（自动黑盒）。
