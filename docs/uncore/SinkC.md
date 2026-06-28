# SinkC —— coupledL2 (tl2chi) TileLink C 通道接收器

> 设计源:coupledL2 `src/main/scala/coupledL2/SinkC.scala`(`class SinkC`)
> 可读核:`rtl/uncore/SinkC.sv`(`xs_SinkC_core`)+ `rtl/uncore/sinkc_pkg.sv`
> 一个子模块 `RRArbiterInit_14`(4 入 1 出轮询仲裁,TaskBundle 95 字段)作 golden 黑盒,在核内例化
> 生成器:`scripts/gen_sinkc.py`(薄壳 wrapper / 变体 / tb / Makefile)

SinkC 是 L2 一致性数据**回收路径**的入口:把上层(DCache)经 TileLink C 通道送来的
`Release/ProbeAck` 事务归一成内部 `TaskBundle`,并把脏数据缓存进缓冲区供后续写回。
golden 单态化(firtool)后 3582 行,其中 ~3000 行是 4 表项 × 95 字段 `TaskBundle` 的展平
寄存器与轮询仲裁器例化,真正的功能逻辑只有约 200 行(对应 Scala 源)。

## 单态化参数(KunmingHu V2R2)

| 参数 | 值 | 含义 |
|------|----|------|
| `bufBlocks` | 4 | `dataBuf`/`beatValids`/`taskBuf` 缓冲块数 |
| `beatSize`  | 2 | 每块 2 拍,`beatBytes=32` ⇒ 256 bit/拍 |
| `bufIdxBits`| 2 | 缓冲块号 |
| `mshrsAll`  | 16 | `io_msInfo` 路数 |
| `ways`      | 8 | `wayMask = 8'hFF` |

## 三条数据通路

```
        ┌──────────────┐  Release/ReleaseData (脏数据)   ┌───────────┐
io.c ──▶│ dataBuf[4][2]│───────────────────────────────▶│ taskBuf[4]│──RRArbiter──▶ io.task
(TL-C)  │ beatValids   │  末拍生成 TaskBundle             │ taskValids│             (→ RequestArb)
        └──────────────┘                                 └───────────┘
            │ ProbeAck/ProbeAckData (非 Release)
            ├────────────────────────────────────────────▶ io.resp  (唤醒 MSHR w_probeack)
            │ ProbeAckData 整块 (2 拍)
            └────────────────────────────────────────────▶ io.releaseBufWrite (写 ReleaseBuffer)
```

1. **Release / ReleaseData**:多拍数据按 `writeIdx`(首拍 `nextPtr`、次拍沿用 `nextPtrReg`)
   写入 `dataBuf`;末拍 `cValidLast` 时调用 `toTaskBundle` 生成一条 `TaskBundle` 投入 `taskBuf`,
   由 `RRArbiterInit_14` 轮询后发往 RequestArb。
2. **ProbeAck / ProbeAckData**:首/末拍经 `io.resp` 唤醒 MSHR 的 `w_probeack`;`ProbeAckData`
   的整块数据(第一拍暂存进 `probeAckDataBuf`,末拍拼成 512 bit)写入 `io.releaseBufWrite`。
3. **refillBufWrite 冒险处理**:C-Release 带来的新数据可能先于 MSHR-Release 的旧 refill 写回 DS。
   当 `taskArb` 发射的 task 地址命中某 MSHR 且其 `blockRefill` 置位(`newdataMask`)时,把
   `dataBuf` 内容打两拍回写 `io.refillBufWrite`,使后到的 MSHR-Release 能读到这份新数据。

## 多拍计数(edgeIn.count)

`r_beats1 = hasData & (size≥6)`:整块(64 B)`ReleaseData` 为 2 拍,其余为单拍。

| 拍 | `r_counter` | `first` | `last` | `beat`(拍序号) |
|----|-------------|---------|--------|----------------|
| 首拍 | 0 | 1 | `~r_beats1` | 0 |
| 次拍 | 1 | 0 | 1 | `r_beats1` |

单拍事务 `first=last=1`。`io.c.ready = !isRelease | r_counter | !full`(只有 Release 首拍且缓冲满时反压)。

## 关键时序细节(踩坑点)

- **分配 vs 消费的优先级**:`taskValids[k] <= ~arbInFire[k] & (taskValids[k] | alloc_k)`,
  即**仲裁器消费(清)优先于本拍分配(置)**。单拍 `ReleaseData` 时 `allocIdx = nextPtrReg`
  可能是上一笔事务遗留、当拍正被仲裁器消费的表项;golden 在此取「净置 0」语义。
  (这是首版用 `if(alloc) ... else if(fire)` 写错优先级时唯一暴露的功能差异。)
- **`taskBuf` 写与消费解耦**:末拍写 `taskBuf[k]` 只看是否被选中,与是否同拍被消费无关;
  即使当拍净 `taskValids` 变 0,`taskBuf` 仍被覆盖(下拍才生效,不影响)。
- **bufResp 两级流水**:`io.bufResp.data := RegNext(RegEnable(dataBuf(bufIdx), io.task.fire))`,
  对应 `r_0/r_1 → REG_0/REG_1`(同步无复位寄存器,名字对齐 golden)。
- **OHToUInt**:`refillBufWrite.bits.id = OHToUInt(newdataMask)`,用 4 个显式位掩码归约
  (`sinkc_pkg::ohToUInt16`),与 golden 门级归约逐位等价。

## 与 golden 的等价策略

`TaskBundle` 在 golden 里被完整建成寄存器(4 表项 × 95 字段 ≈ 316 bit/表项),即便 `toTaskBundle`
只填 12 个有效字段、其余恒 0。为通过 Formality(常量寄存器仍是比对点,不能优化掉),可读核用
`SC_TB_DECL/RST/WR/ARB` 四个宏按表项号 `K` 展开,**逐字段保留与 golden 同名的寄存器**:
95 个字段只写一遍,4 个表项各例化一次,既 DRY 可读又与 golden 1:1 命名对齐。

仲裁器 `RRArbiterInit_14` 在核内例化(避免向 wrapper 暴露 ~428 根 taskBuf 线),FM 两侧均当黑盒。

## 验证

- **UT**(`verif/ut/SinkC/`):`SinkC`(golden)与 `SinkC_xs`(可读核)双例化,逐拍比对全部
  输出 + 内部状态探针(dataBuf/beatValids/taskBuf 有效字段/taskValids/计数/流水寄存器)。
  激励偏向 C 通道合法 opcode、`size=6` 满块与小 size 混合、偏小 `set/tag` 促 `msInfo` 命中。
  seed 1/7/42 各 200000 拍:`errors=0 ierr=0`(每 seed 22.4M 次比对)。
- **FM**(`make fm`):ref = golden `SinkC`,impl = 核 + 薄壳 wrapper,`RRArbiterInit_14` 两侧黑盒。
  `Verification SUCCEEDED`,7176 比对点全通过(5633 按名 + 1543 按签名),0 unmatched。
