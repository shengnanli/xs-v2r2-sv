# RequestArb —— coupledL2 (tl2chi) L2 slice 请求仲裁流水

可读重写核 `xs_RequestArb_core`（`rtl/uncore/RequestArb.sv`），golden 同名壳
`RequestArb`（`rtl/uncore/RequestArb_wrapper.sv`）。设计源
`coupledL2/src/main/scala/coupledL2/RequestArb.scala`。golden 3344 行 → 核 ~2090 行
（去注释逻辑更少；体量主要在 95 字段 TaskBundle 的逐字段打包/锁存/输出端口）。

## 功能：L2 slice 主流水的请求入口仲裁（3 级，无子模块）

RequestArb 把四类请求合流进 MainPipe，并启动 Directory 读：

| 来源 | 通道 | 含义 |
|------|------|------|
| `sinkA` | A（channel[0]） | 上层 L1 的 Acquire/Get/Hint |
| `sinkB` | B（channel[1]） | 下层来的 Probe/Snoop |
| `sinkC` | C（channel[2]） | 上层的 Release/ProbeAck |
| `mshrTask` | — | MSHR 重发（refill/写回/响应）任务 |

### s0：mshrTask 入口
`io_mshrTask_ready` 受 GrantBuffer/TXDAT/TXRSP/TXREQ 的 `blockMSHRReqEntrance`、
正在 stall 的 replRead、以及在途 `mshr_task_s1` 未消化（mcp2 stall）联合反压。
`s0_fire` 时把 mshrTask 整包锁进 `mshr_task_s1`。

### s1：通道优先级仲裁
- 阻塞：`block_{A,B,C}` = MSHRCtl | MainPipe | GrantBuffer（B 另含 TXDAT/TXRSP 的
  `blockSinkBReqEntrance`）。
- 优先级 **C > B > A**，且 `mshr_task_s1` 优先于通道：
  `task_s1 = mshr_task_s1.valid ? mshr_task_s1 : (selC?C : selB?B : A)`。
- 通道入口还需 `resetFinish`（复位期 512 拍 `resetIdx` 倒数门控）+ `dirRead.ready`。
- 同拍发 Directory 读 `dirRead_s1`（tag/set/replacerInfo + refill/wayMask）。
  `replRead`（MSHR refill 任务且 opcode∈{Grant,GrantData,AccessAckData,HintAck}）会
  占用 dir 读口，未就绪时 `mshr_replRead_stall` 挂起。
- `mshrRetry` 时 `wayMask = ~(1<<way)` 屏蔽冲突 way，否则全 1。

### s2：送 MainPipe + 取数据缓冲
- `task_s1` 打一拍成 `task_s2`（`taskToPipe_s2`）。`ds_mcp2_stall = RegNext(s1_fire &
  非 AHint)`：禁止连续两拍访问 DataStorage（A-Hint 不访 DS 故豁免）。
- 按 `task_s2` 类型译码读缓冲：
  - `refillBufRead_s2`：replTask 走 TXREQ 写回族（chiOpcode∈{0x1B,0x15,0x42,0xD}），
    或上行 A 响应且非用 ProbeData。
  - `releaseBufRead_s2`：mshr 任务读 ProbeData 下行/上行用 ProbeData；或非 mshr 的 B
    探测命中带数据释放（snpHitReleaseWithData）。

### 旁路输出
- `status_s1`（sinkC/sinkB/A 入口 + mshr_s1 各 set/tag）、`status_vec[_toTX]`
  （s1/s2 的 channel/txChannel/mshrTask）供 MSHRCtl/TX 做同址/同 set 阻塞。
- `s1Entrance`：metaWen 的 mshr 任务或 sinkB/sinkC fire 时输出其 set，阻塞同 set 的后续 A。

## 重写要点
- **TaskBundle 结构体收敛**：golden 把 95 字段逐项做「mshr ? mshr : C?B?A」四路 Mux
  （~540 行）。核里打包成 `l2_task_pkg::task_bundle_t`，整包一条
  `task_s1 = mshr_valid ? mshr_task_s1 : (selC?C:selB?B:A)` 即可。
- **寄存器扁平命名**：`mshr_task_s1_bits_*` / `task_s2_bits_*` 保持 golden 扁平名，
  令 Formality 逐 DFF 按名配对（结构体打包寄存器会与 golden 逐字段 DFF 配不上）。
- **死输入**：`io_msInfo*`（dontTouch 保留、逻辑未用，544 端口）核不接收，壳里悬空。
- **perf 计数**（`_GEN_*`，喂 XSPerf）不驱动输出，省略。

## 验证
- UT 双例化逐拍比对 `RequestArb` vs `RequestArb_xs`，seed 1/7/42 各 200000 拍：
  `errors=0 ierr=0`（输出 + 全部 `mshr_task_s1_*`/`task_s2_*`/状态机内部探针）。
- FM `make fm`：**SUCCEEDED**（无子模块，ref=golden RequestArb 本体）。
