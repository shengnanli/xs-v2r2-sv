# MSHRCtl —— coupledL2 (tl2chi) L2 MSHR 控制阵列

> 设计源:coupledL2 `src/main/scala/coupledL2/tl2chi/MSHRCtl.scala`(`class MSHRCtl`,仅 260 行 Scala)
> 可读核:`rtl/uncore/MSHRCtl.sv`(`xs_MSHRCtl_core`)
> 生成器:`scripts/gen_mshrctl.py`(派生机械连线 + 手写 glue + wrapper / 变体 / tb / Makefile)
> 子模块 **全部作 golden 黑盒**(在核内例化):
> `MSHR`×16(单条目 miss 处理 FSM,本工程已单独做透)、`MSHRSelector`(空闲槽优先分配)、
> `SourceB`(Probe 上行,内含 `FastArbiter_6`)、`FastArbiter_4/5/7/8`(txreq / txrsp / source_b / mainpipe 仲裁)

MSHRCtl 是 L2 slice 的 **MSHR 控制阵列**:把 16 个 MSHR 槽组织成一个资源池,
负责**分配**(给 MainPipe 选空闲槽)、**响应路由**(把 CHI/TileLink/嵌套回写各路响应按
`mshrId`/PA 派发进对应槽)、**下行/上行仲裁**(各槽的 txreq/txrsp/source_b/mainpipe 任务
经 FastArbiter 汇聚出口)、以及**容量背压**与若干 TopDown/perf 统计。

golden 单态化(firtool)后 **14467 行**,其中约 11000 行是 16 个 MSHR(每个 279 端口)+
4 个仲裁器(`mshr_task_arb` 的 TaskBundle 约 150 字段 × 16 入达 ~2400 行)的扁平实例连线;
**真正的控制逻辑只有约 150 行 Scala**。本核把 16 个 MSHR 收进一个 `generate-for` 循环
(可读的单份模板 + 数组),把仲裁器/选择器/SourceB 连线从 golden 机械派生(保证位级一致),
glue 逻辑按 Scala 意图手写。

## 单态化参数(KunmingHu V2R2)

| 参数 | 值 | 含义 |
|------|----|------|
| `mshrsAll` | 16 | MSHR 槽数(`mshrs_0..15`) |
| `mshrBits` | 8 | `io_id` / 各 `mshrId` 位宽(实际只用低 4 位) |
| `pipeStatusVec` | 2 | s2/s3 在途流水状态 |
| `grantBufInflightSize` | 16 | `grantStatus`(送 SourceB) |
| 端口总数 | 1001 | 含 16×(msInfo 42 + msStatus 6 + pCrd 3) 等展平输出 |

## 控制阵列做了什么(对应 Scala 逐段)

1. **分配(allocation)**:`MSHRSelector` 对 `~status.valid`(空闲)取最低位 one-hot
   `selectedMSHROH`;`mshr_alloc_ptr = OHToUInt(selectedMSHROH)` 反馈给 MainPipe;
   MainPipe 在 s3 拉高 `mshr_alloc_s3.valid` 时,one-hot 选中的那个槽 `io_alloc.valid` 置位、
   `alloc.bits` 广播到所有槽(只有被选中槽真正锁存)。

2. **容量背压**:`occTotal = pipeReqCount(s2/s3 在途) + mshrCount(已占用槽数)`。
   `mshrFull = occTotal[4]`(≥16)→ `blockB_s1` 阻塞 SinkB;
   `a_mshrFull = occTotal > 14`(≥15)→ `blockA_s1` 阻塞 SinkA(**为 SinkB 预留最后 1 槽**,
   保证 snoop/probe 类不被普通 acquire 占满而死锁)。

3. **响应路由**:每路响应按其携带的 `mshrId` 或 PA 仅命中一个槽:
   - `resps.rxrsp/rxdat`(来自 CHI RXRSP/RXDAT):`status.valid & resp.valid & (resp.mshrId == i)`;
   - `resps.sinkC`(来自 core 的 ProbeAck/Release):**无 mshrId,用 PA 搜索**——
     `resp_sinkC_match_vec[i] = status.valid & w_c_resp & (set 相等) & (tag 相等,needsRepl 取 metaTag 否则 reqTag)`;
   - `replResp`(替换路结果)、`aMergeTask`(A 合并)同样按 id 命中;
   - `bits` 一律广播,`valid` 经上述门控只对命中槽有效。

4. **releaseBuf 写指针**:`releaseBufWriteId = ParallelPriorityMux(resp_sinkC_match_vec, idx)`,
   告诉 SinkC 把回收数据写进哪个槽的 releaseBuffer。

5. **嵌套回写(nestedwb)**:`io_nestedwb` 广播到所有槽(别的槽在同 set/tag 上的 release/snoop
   会改本槽 meta);`nestedwbDataId = ParallelPriorityMux(各槽 nestedwbData, idx)` + valid=OR。
   (golden 含断言 `PopCount(nestedwbData) <= 1`,即同一拍最多一个槽产生嵌套数据。)

6. **下行/上行仲裁**:四把 `fastArb`——
   `txreq_arb`(各槽 CHI Acquire → TXREQ)、`txrsp_arb`(各槽 CHI Rsp → TXRSP)、
   `source_b_arb`→`SourceB`(各槽 Probe → TileLink B,SourceB 还按 `grantStatus` 阻塞同址
   probe 直至 GrantAck)、`mshr_task_arb`(各槽回灌 MainPipe 的 TaskBundle)。
   仲裁器输出的 `io_in_<i>_ready` 回灌给对应槽的 `tasks_*.ready`。

7. **TopDown / perf**:`l2Miss` = 任一槽在 channel A 处理 CPU load/store miss;
   `hpm_timers[i]`(自占用起每拍 +1,异步 reset 清 0)+ `lmiss`(>200 拍长 miss 计数)→ `io_perf_3`;
   `io_perf_0/1` = RXDAT refill 事件(2 级流水寄存)。

## 黑盒清单(UT 两侧共享 golden 积木)

| 模块 | 数量 | 作用 |
|------|------|------|
| `MSHR` | 16 | 单 MSHR 槽 miss/snoop/CMO 事务完整 FSM(已单独做透,279 端口) |
| `MSHRSelector` | 1 | 空闲槽最低位优先 one-hot(`io_idle_0..14` + `io_out_bits`) |
| `SourceB` | 1 | Probe 上行,内含 `FastArbiter_6` |
| `FastArbiter_4/5/7/8` | 各 1 | txreq / txrsp / source_b / mainpipe 16 入仲裁 |

## 重写要点 / 易错点

- **生成-循环里禁函数捕获模块信号**(X 铁律):16 个 MSHR 的每实例输入用显式数组/表达式
  下标驱动(`mshrAllocOH[i]`、`resp_sinkC_match_vec[i]`、`(mshrId == 8'(i))`),
  组合 glue 用 `always_comb` for 循环而非 generate 内函数。
- **扁平接口 ↔ 内部数组**:golden 接口是 firtool 展平的标量端口(`io_msInfo_0_*` …),
  核内用 `generate-for` + 数组(可读),边界处显式展平(已清楚标注为接口要求)。
- **`hpm_timers` 异步 reset**:golden 是 `always @(posedge clock or posedge reset)`,
  漏掉 reset 会令 UT 通过(`+initreg+0` 下凑巧一致)但 **FM 判 20 个寄存器不等价**——
  必须照搬异步 reset;而 `io_perf_*` 流水寄存器 golden **无 reset**,照搬即可。
- **`ParallelPriorityMux` 语义**:最低置位下标优先,全 0 默认末项(下标 15);
  `f_pri16` 高→低遍历赋值实现,位级匹配 firtool 展开(含 `~vec` 编码)。

## 验证

- **UT**(`verif/ut/MSHRCtl/`):双例化 golden `MSHRCtl` vs 可读 `MSHRCtl_xs`,逐拍随机激励,
  比对全部 **804 个输出**(msInfo×16 / msStatus×16 / pCrd×16 / 4 仲裁出口 / blockA·B /
  alloc_ptr / releaseBufWriteId / nestedwbDataId / l2Miss / perf)+ 3 个内部 glue 探针
  (mshrFull / a_mshrFull / 选择器 one-hot)。
  **seed 1/7/42 各 200000 拍:`checks=160800000 errors=0 ierr=0`**。
  (子 MSHR/仲裁器为两侧共享 golden 黑盒,任何路由/仲裁错连都会经其输出暴露。)
- **FM**(`make fm-MSHRCtl`):ref=golden MSHRCtl,impl=可读核 + wrapper,子模块两侧均黑盒,
  **`FM_RESULT: Verification SUCCEEDED`**(26444 passing / 0 failing)。

## 闸门

核去注释 `io_x_N_N / _GEN_ / _T_<n> / _REG_<n> / RANDOMIZE` = **0**;无 `.svh` 套壳;
genvar(MSHR 阵列)+ 2 函数(`f_oh16_to_uint` / `f_pri16`)+ `localparam MSHRS`;
全部子模块黑盒、glue 纯重写,非装配壳。
