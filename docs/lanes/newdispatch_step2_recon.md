# 步骤 2 侦察笔记（只读，跑 FM 期间做的；★不是开工★）

## 三条控制链在 golden 里的形状（行号 = G1-canonical/golden-rtl/NewDispatch.sv）

### uopBlockByIQ_i（85952 起，6 条）
    uopBlockByIQ_i = OR_{j=0..16} ( io_toIssueQueues_{2j}_ready
                                    ? uopSelIQMatrix_i_j > 3'h2
                                    : |uopSelIQMatrix_i_j )
uopSelIQMatrix_i_j = lane 0..i 中要进 IQ 组 j 的个数（前缀计数）。
★重写侧已经有了★：rtl/backend/NewDispatch.sv:650 `uopBlockByIQ_o[l] = |uopBlockMatrix[l]`
在 xs_NewDispatch_core 里，公式与 golden 逐字一致（iqReady ? cnt>2 : |cnt）。
接出来的 core_uopBlockByIQ（:8548 声明，:9815 连线）**目前没有任何消费者**。
=> 交接里"这三样重写侧目前没有"对 uopBlockByIQ **不成立**：算是算了，只是没接。

### allowDispatch_i（86248 起，级联 6 级）
    allowDispatch_i = isStoreLike_i ? (sqFreeCount > conserveFlowTotal_i)
                                    : (~isLoadLike_i | lqFreeCount > conserveFlowTotal_i)
                      & allowDispatch_{i-1}     (i>0)
  isStoreLike_i = fromRename_i_valid & (fuType[16] | fuType[32] | fuType[34])
  isLoadLike_i  = isLoadVec_i | isVLoadVec_i
  sq/lqFreeCount 来自 lsqEnqCtrl，conserveFlowTotal_0..5 是 7 位寄存器（91127 起更新）
★重写侧没有★。

### thisCanActualOut_i（86345 起）
    thisCanActualOut_i = ~blockedByWaitForward_i
                       & (&_{k<i} ~isBlockBackward_k)
                       & io_enqRob_canAccept
  isBlockBackward_k       = fromRename_k_valid & fromRename_k_bits_blockBackward   (86292)
  blockedByWaitForward_i  = blockedByWaitForward_{i-1}
                          | (~enqRob_isEmpty | |fromRename_{<i}_valid)
                            & fromRename_i_valid & fromRename_i_bits_waitForward   (86314)
★重写侧没有★。

## 汇合点（golden 12748-12760，每 lane 一组）
    io_fromRename_i_ready = allowDispatch_i & ~uopBlockByIQ_i & thisCanActualOut_i
                          & lsqEnqCtrl_io_enq_canAccept
    fromRenameUpdate_i_valid = io_fromRename_i_valid & <同上四项>
                          & ~eliminatedMove & ~hasException & ~singleStep

## 自举链（交接说的那条，已核实存在）
  lsqEnqCtrl.canAccept -> io_fromRename_i_ready -> firedVec_i(= ready & valid)
  -> uopSelIQ_*_* 寄存器清位（91110 起 `uopSelIQ_5_15 <= ~firedVec_5 & uopSelIQ_5_15`）
  -> 回到 uopSelIQMatrix -> uopBlockByIQ。
  同时 firedVec/toRenameAllFire 还回喂 conserveFlowTotal_*（91127 起）与 BusyTable 家族。

## 步骤 2 的实际规模（我量的，@ d867a0da）
  顶层 output 端口 6699（golden 与重写侧逐一相等）
  已驱动 assign io_ 5974 -> ★未驱动 725★，按前缀：
      io_enqRob        379
      io_toMem         330
      io_perf            8
      io_fromRename      6   (= 6 条 lane 的 ready)
      io_toRenameAllFire 1
      io_stallReason     1
  这 725 条里绝大多数是被上面控制链门控的 payload glue。

---

## 为什么这轮到这里停（不是没时间，是判据没过）

步骤 1 的 receipt 已出（`evidence/75c143861c75/`，commit `795a7bec`），
★三条预登记判据 3/3 不达标★，且有一个未定机理（IQSort 那 55 个为什么这次配得上）
明确挂着。交接写的是「步骤 2 只在步骤 1 对账清楚之后再开工」——
对账做完了、去向逐点对上了，但**判据没过**，所以本轮只交侦察结果，不动 RTL。

对账结论对步骤 2 是**有利**的：步骤 1 之所以 passing 一点没涨，
机理已经查清且就是步骤 2 要解决的那件事（output 不驱动 -> impl 侧前向锥断 -> unread）。
换句话说步骤 2 没有被证伪，只是还没被做。

## 下一条 lane 的落手点（按风险从低到高）

1. `uopBlockByIQ`：**已经算好了**，只差消费者。接 `core_uopBlockByIQ` 即可，零新逻辑。
2. `thisCanActualOut`：纯组合，只依赖已有顶层输入
   （`io_enqRob_canAccept` / `io_enqRob_isEmpty` / `fromRename_*_valid|blockBackward|waitForward`），
   无自举，可独立写完独立验。
3. `allowDispatch`：依赖 `lsqEnqCtrl` 的 `lq/sqFreeCount` 与 6 个 `conserveFlowTotal_*` 寄存器；
   `conserveFlowTotal_*` 的次态又依赖 `toRenameAllFire`/`firedVec` ⇒ ★进自举环★。
4. 汇合 + 725 个 output：`io_fromRename_i_ready` 一通，`firedVec` 就活，
   `unresolved_toRenameAllFire`/`unresolved_firedVec` 两行常量随之删除 ——
   ★删掉那两行的同时，`provable_check.py` 报的 10 个寄存器应当归零★，
   这是步骤 2 自带的、跑 FM 之前就能验的判据，建议先登记再动手。
5. 生成手段：`scripts/gen_newdispatch.py` 已有分段生成机制
   （PORTS / UNRESOLVED / PACK / UNPACK / CHILDINST），725 个 output 里
   `io_enqRob` 379 与 `io_toMem` 330 绝大多数是 `io_fromRename_*` 直通、
   只有 `valid` 被 `firedVec_i` 门控，适合再加一个生成段而不是手写。
