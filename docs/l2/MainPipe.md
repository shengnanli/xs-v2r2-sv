# MainPipe —— coupledL2 (tl2chi) L2 slice 主流水(命中/缺失数据通路心脏)

- 可读核：`rtl/uncore/MainPipe_1.sv`(`xs_MainPipe_core`，2425 行)
- 装配壳：`rtl/uncore/MainPipe_1_wrapper.sv`(golden 同名 `MainPipe_1` = 核 + `CustomL1Hint` 黑盒)
- 生成器：`scripts/gen_l2mainpipe.py`(壳/变体/tb/Makefile) + `scripts/gen_l2mainpipe_core.py`(核体)
- 对照 Scala：`coupledL2/src/main/scala/coupledL2/tl2chi/MainPipe.scala`(1107 行真逻辑)
- golden：`build/rtl/MainPipe_1.sv`(4299 行 / 509 端口；被 `Slice`/`Slice_1/2/3` 例化)

> 注意：`build/rtl/MainPipe.sv`(3218 行 / 444 口)是 **DCache** 的 MainPipe，不是本模块；
> L2 的是 `MainPipe_1`。`MainPipe_5` 是另一配置(LLC/Slice_4)。

## 单态化参数(firtool, MainPipe_1)
clientBits=1, ways=8, sets=512(resetIdx 9bit), mshrBits=8, beatSize=2, blockBytes=64,
**enableL2Flush=false**(无 `cmoAllBlock`/`cmoLineDone` 端口 → `cmoHitInvalid=0`)，
**Issue>=Eb**(`SnpQuery`=0x10 / `WriteEvictOrEvict`=0x42 生效)。TaskBundle 见 `l2_task_pkg`(95 字段)。

## 五级流水
| 级 | 角色 |
|----|------|
| **s2** | 组合：收 RequestArb 的 `taskFromArb_s2`；按 set/tag 反压 s1 入口(`toReqArb`/`toReqBuf` BlockInfo) |
| **s3** | 主计算：读 `dirResp_s3` → 判命中/一致性 → 派发(MSHR alloc / 各通道 / 写 Dir / 读写 DS / nestedwb / 预取) |
| **s4** | 为时序把 sinkB 响应/数据推后一拍锁存；处理 drop/forward |
| **s5** | 收 DS 读数据 `rdata_s5`；发 `releaseBufWrite`；出 `error`；各通道收尾 |

## 子模块边界
- **CustomL1Hint**(192 行，自带 hintQueue/hint_s1Queue FSM 的 L1 预取 hint 生成器)→ **黑盒**
  (wrapper 例化 golden 件；核额外输出 7 个 `hint_s3_*` 喂线；`taskInfo_s1`/`l1Hint` 直连黑盒不过核)。
- **4 个 `Arbiter3_*`(toSourceD/TXREQ/TXRSP/TXDAT)**：Chisel 优先 Arbiter(in0=s5 最高 > s4 > s3)，
  逻辑平凡(out.valid=OR；in(i).ready = out.ready & ~高优先级 valid)，**内联进核**。
  内联把"仲裁 ready 反压回流水(`chnl_fire_s*`)"的组合回路保留在核内，避免黑盒反馈失配。
  `toSourceD/TXREQ/TXRSP` 下游恒 ready=1(firtool 已优化掉口)；`toTXDAT` 用 `io_toTXDAT_ready`。

## 命中/一致性/派发协议(摸到的)
- **通道 one-hot**：`channel[0/1/2]` = fromA(上层 Acquire/Get/Hint/CBO) / fromB(RXSNP snoop) / fromC(Release)；
  `txChannel[0/1/2]` = toTXREQ / toTXRSP / toTXDAT(CHI 出向)。`mshrTask` 区分 MSHR 重发 vs 通道首次。
- **MetaData 态**(2bit)：INVALID=0 / BRANCH=1 / TRUNK=2 / TIP=3；`isT=state[1]`，`isValid=state>0`。
  `needT(op,pm)= ~op[2] | (Hint&PrefetchWrite) | ((AcqBlock|AcqPerm)&pm!=NtoB)`。
- **A 通道判 MSHR**：`need_acquire`(命中 BRANCH 需 T / 缺失 / CMO)、`need_probe`(命中有 client 且 Get/CBO 命中 TRUNK 等)、
  `cache_alias`(Acquire 命中且 client alias 不同) → 任一为真发 `mshr_alloc_s3`，否则 s3 直接 `sink_resp`(Grant/AccessAck/ReleaseAck)。
- **B 通道 snoop(CHI)**：按 `chiOpcode` 分类(`isSnpToB`/`isSnpToN`/`isSnpOnceX`/`isSnpXFwd`/`isSnpStashX`/`isSnpQuery`…)，
  判 `need_pprobe`(降级上层 client)与 `need_dct`(doFwd 直传)。响应一致性态 `respCacheState` + `fwdCacheState`
  以**顺序 when(后者覆盖前者)**实现(SnpToB→SC、SnpOnceX→保态、SnpCleanShared→UC/SC、snpHitReleaseTo{Inval/Clean} 微调)；
  `resp = setPD(state, respPassDirty&doRespData)`，`PassDirty` 当命中 T 态且脏。`neverRespData` 抑制特定 snoop 回数据。
  `nestable_*`(snoop 嵌套 Release 时以 MSHR 上报 meta 替代目录结果)只用于 B/C，**A 通道逻辑禁用**。
- **写 Directory**：`metaWReq` 优先级 **a>b>c>mshr>cmo**(cmo 写全 0 = invalid)；复位期 512 拍逐 set 用 `resetIdx` 清零
  (`wayOH=8'hFF`)。`tagWReq` 仅 mshr_refill 非 retry 时写。各路 meta 构造见 `metaW_s3_{a,b,c}` / `mshrMeta_*`。
- **读写 DS**：`ren`(A 命中读数据 / B 需数据 / mshr 替换回写 / CMO 脏)；`wen`(C 释放带数据 `wen_c` / mshr 各类回写填充
  `wen_mshr`)。`req_s3_valid` 经 `task_s3_valid_hold2` 拉宽 2 拍满足 DS 时序。
- **通道派发**：`isD/isTXREQ/isTXRSP/isTXDAT` 在 s3 判定；`d_s3_latch=txdat_s3_latch=true` 使**非 mshr 的 A-D / B-DAT
  响应推后一拍到 s4**(`isD_s3_ready` 排除 fromA 路径)，s5 再补 `pendingD_s4`/`pendingTXDAT_s4`。`source_req_s3` = `req_s3`
  叠加(sink_resp 时覆盖 opcode/param/mshrId；B-snoop 时覆盖 txChannel/size/meta/id/chiOpcode/resp/fwdState)。
- **MSHR alloc**：`dirResult=nestable`，`FSMState` 初态全 1(s_/w_ 假为有效)再按通道/需求清位，`task=req_s3`(仅 `aliasTask=cache_alias`)。
- **error**：s5 出 `{tag,set,off}` 地址 + `l2Error`(目录 error | DS error | dataCheckErr)。
- **perf**：8 事件(l2_cache_access/l2wb/l1wb/wb_victim/wb_cleaning_coh/access_rd/access_wr/inv)，各经 2 级 RegNext
  延迟后零扩展成 6bit 出 `io_perf_N_value`。

## 可读构造(满足闸门)
- **struct**：`task_bundle_t` 视图 ×6(`req_s3` / `source_req_s3` / `task_s4_v` / `task_s5_v` / `s5_sd` / `s5_txdat`)。
- **function**：16 个判定(`f_needT` / `f_isToN` / `f_isParamFromT` / `f_isT` / `f_isSnp*`)，仅读入参，不捕获模块信号。
- **enum(命名常量)**：一致性态 `INVALID/BRANCH/TRUNK/TIP` 与 CHI Resp `CHI_I/SC/UC/SD/PD` 用具名 localparam 编码。
- 寄存器全用 golden 扁平命名(`task_s3/s4/s5_bits_*` 等)供 FM 逐 DFF 配对 + 逐拍内部探针；延迟链 `_REG_1/_REG_2`
  改名 `chnl_fire_s3_d1/d2`、`io_perf_*_value_dly2`(消 firtool 痕迹)。
- 结构闸门：`grep -E "io_..._[0-9]+_[0-9]+|_REG_[0-9]|_GEN_|_T_[0-9]|RANDOMIZE"`(去注释)= **0**；svh 套壳 = 0。

## X 铁律
主流水寄存器(task_s3/s4/s5_bits + valid、resetFinish、resetIdx=511、replResp_valid_s4、
task_s3_valid_hold2、isD/isTX*_s4/s5、tagError/dataError/l2Error_s4/s5、chnl_valid_*_REG)**异步复位置 0**；
`data_s4`/`data_s5`(512b) 与 `io_perf_*_REG`/`*_dly2` 为**无复位 RegNext**(`+vcs+initreg+0` 起 0，数据先写后读)。

## 验证
- **UT**：`verif/ut/L2MainPipe/`，双例化逐拍比对 golden `MainPipe_1` vs `MainPipe_1_xs`(两侧共用 golden CustomL1Hint
  + 其 Queue/ram 叶子 + 3 个 Arbiter3)。seed 1/7/42 各 **200000 拍，每拍 ~367 输出 `!$isunknown` 比对**，
  **errors=0**；s2/s3/s4/s5 流水寄存器内部探针(`ierr`)= **0**(73.4M checks/seed)。
- **FM**：`make fm` → **Verification SUCCEEDED**；6418 点按名配对 + 9 点签名配对，**0 unmatched / 0 failing**。
  CustomL1Hint 两侧黑盒；Arbiter3_* 在 golden 端展平与内联核比对等价。
