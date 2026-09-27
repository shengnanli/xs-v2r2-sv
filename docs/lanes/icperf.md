# lane icperf —— ICacheMainPipe / IPrefetchPipe 的 perf 探针重绑（55+1 条 BLOCKING 归因与消解）

分支 `agent/icperf`（基于 main d987e60155…）。impl of record 之前是
`/home/eda/xs-env/sim-work-perfbind2/diag2/`，本 lane 的重建在 `/home/eda/xs-env/sim-work-perfbind2/icperf/`。

## 1. 归因：不是行为差，是探针没绑上 + 台账出表顺序错

`docs/perf_mismatch_ledger.tsv`（commit 63aaea97bffdde3dc5f1d8251d417386ec948500 出表）里
55 条 `frontend.inner.icache.mainPipe: ftq2icache_fire_*`（golden 6/2/1… vs impl 0）+ 1 条
`frontend.inner.icache.prefetcher: bpu_s1_flush`（23 vs 0）被判 BLOCKING。逐条查 bore：

| 计数器族 | bore | golden 观测点 | 旧档位 | 喂到的计数器数 |
|---|---|---|---|---|
| ftq2icache_fire_*（sum/mean/overflow/underflow/各桶） | perfCnt_bore_8069 | `ICacheMainPipe.cntFtqFireInterval_probe`（= 内部寄存器 cntFtqFireInterval） | T3_REG_LEAF | 304 |
| bpu_s1_flush | perfCnt_bore_13 | `IPrefetchPipe.from_bpu_s1_flush_probe`（内部 wire，锥展到 s1_isSoftPrefetch / s1_req_ftqIdx 寄存器） | T3_REG_LEAF | 1 |

两条 bore 在 diag2 的重绑 SimTop 里都是 `'0 /* UNBOUND T3_REG_LEAF */`
（`grep -n -A1 'perfCnt_bore_8069$' sim-work-perfbind2/diag2/build/rtl/SimTop.sv`），所以
impl 侧的 0 **不是测量值**。ftq2icache_fire_1_2 的 7702 与 underflow 的 7702 也是同一个假 0
在直方图 enable（enable_bore = x3_probe，T2 已绑上）每次触发时落进 <1 的桶。

★perf_compare 的分类没有洞，但台账有洞★：63aaea97 那一笔提交里 `perf_mismatch_ledger.tsv`
的头部记的是 `gap_ledger_sha256 24073dca…`——那是 **63aaea97^ 的 gap 台账**（里面 0 条
ftq2icache_fire），而同一笔提交重算后的 gap 台账（069695bd…）已经把这 304+1 条列成 EXCLUDED。
即 `--emit-mismatch` 跑在 `perf_tier.py` 重算**之前**，出表当时按旧 gap 台账把它们当成了"全绑上
但数值不同"。用 main 上的台账重跑同一对日志（不改任何代码）：

    python3 scripts/perf_compare.py /home/eda/xs-env/sim-work/perfbind-runs/golden_cm20k/assert.log \
        /home/eda/xs-env/sim-work-perfbind2/diag2/run/cm20k/assert.log --all
    # MATCH 21052 / MISMATCH 27 / EXCLUDED 4348 / MISSING 0；WAIVED 24 / BLOCKING 3
    # BLOCKING 3 = tage bank_1_tage_prov / tage_bank_0_alt_ / storeQueue vaddr_match_failed —— 没有 icache 的

所以 59 条 BLOCKING 里这 56 条在 main 现台账下本来就是 EXCLUDED；`check_perf_tier.py` 判据 E
（用当前台账重算 verdict）应当已经把那份 mismatch 台账判红——集成者在 main 重出表时顺序须是
`perf_rebind.py → perf_tier.py → perf_compare.py --emit-mismatch`。

## 2. 改了什么（不改功能，照 agent/sqcore 37a806c0 的做法）

`scripts/perf_rebind.py` 的 T0/T1 判据是「golden 信号名在 impl 侧**同一层**模块（golden 同名
wrapper）里声明过」；可读核里同语义的寄存器/线一直都在（xs_ICacheMainPipe 的 cntFtqFireInterval：
reset→0、`io_fetch_req_valid & s0_can_go` 拍→1、否则 +1，与 golden ICacheMainPipe.sv:883-886 逐句同；
xs_IPrefetchPipe 的 from_bpu_s1_flush 与 golden IPrefetchPipe.sv:424-427 同式），只是没在 wrapper 层
按 golden 的名字露出来。于是：

* `rtl/frontend/ICacheMainPipe.sv`：核加输出 `cntFtqFireInterval_probe[31:0]`（`assign … = cntFtqFireInterval`），
  wrapper `ICacheMainPipe` 里 `wire [31:0] cntFtqFireInterval_probe;` 接住。
* `rtl/frontend/IPrefetchPipe.sv`：核加输出 `from_bpu_s1_flush_probe`（`assign … = from_bpu_s1_flush`），
  wrapper `IPrefetchPipe` 里 `wire from_bpu_s1_flush_probe;` 接住。
* wrapper 对外端口表一根没多：`make -C verif/ut/ICacheMainPipe portlint` / `…/IPrefetchPipe portlint`
  均 `[PASS]`（两者 PORTLINT_ORDER=fail）。
* 没动 `docs/hier_rebind_decl.tsv`：那张表只声明 INSTANCE/INLINE 的层次去向，没有信号别名机制；
  同名导出即可让机器自己判 T1。

重算：`python3 scripts/perf_rebind.py && python3 scripts/perf_tier.py`；
`docs/perf_bore_map.tsv` 只变两行（perfCnt_bore_8069 / perfCnt_bore_13：T3_REG_LEAF → T1_PATH_REBIND），
`perf_bore_unbound.tsv` -305 行，`perf_gap_ledger.tsv` -305 行；`perf_rebind.py --check` rc=0、
`perf_tier.py --check` rc=0（25888 条逐字节一致，X_UNRESOLVED=0）。

## 3. 签核不变（commit 5d0866cdffc57d79cce2129be8cc6fdf8b9e7bbb 上重跑）

| target | UT (seed=1, 200k 拍) | FM signoff-strict vmucp | 登记值 |
|---|---|---|---|
| ICacheMainPipe | checks=15986800 errors=0 | native SUCCEEDED passing 4034 failing 0 unmatched 0 dont_verify=false | 4034（evidence/8bb456d758e8） |
| IPrefetchPipe | checks=6395584 errors=0 | native SUCCEEDED passing 1006 failing 0 unmatched 0 dont_verify=false | 1006（evidence/22646c6a3734） |

证据 `evidence/5d0866cdffc5/{ICacheMainPipe,IPrefetchPipe}/`（receipt.json / fm.log / unmatched.rpt /
black_boxes.rpt / unread_points.txt / sidecar/ / MAKE_RC）。复跑：`cd verif/ut/<top> && make run && make fm`。

## 4. 整芯片重建（EXCLUDE=rtl/backend/NewDispatch.sv，与 diag2 同配方，-j16）

    TAG=icperf EXCLUDE="rtl/backend/NewDispatch.sv" JOBS=16 <scratchpad>/icperf/perfbind2_diag_icperf.sh
    # = perfbind2_diag.sh，只把 REPO 指到 /home/eda/xs-env/wt-icperf（HEAD=5d0866cd…）
    # 重绑 SimTop 头部: T0 6101 / T1 169 / T2 561 / T2C 196 / T3 1111 / T4 1759；复核 6276 条 XMR 全走得通
    # SimTop.sv sha256 c946a3fae2fc9f1ba8576d0cbc37c33dd1ab21714dc3e2d768a122e21a55be0a
    # 20k 拍 EXCEEDED MAX CYCLE（与 diag2 同），assert.log 27921 行
    # sha256 cbf9696e196e80b1f954544e6bc31d39cfd8950f253549e37241c7cf67a2263d

    python3 scripts/perf_compare.py /home/eda/xs-env/sim-work/perfbind-runs/golden_cm20k/assert.log \
        /home/eda/xs-env/sim-work-perfbind2/icperf/run/cm20k/assert.log --all
    # MATCH 21359 / MISMATCH 24 / EXCLUDED 4044 / MISSING 0；WAIVED 22 / BLOCKING 2

对比 diag2 现台账下的 MATCH 21052 / EXCLUDED 4348：EXCLUDED -304、MATCH +307。

逐族核对（把 63aaea97 那版 unbound 表里 icache 的 312 个计数器名从两份日志各抓出来 diff）：
**305 条（304 ftq2icache_fire_* + bpu_s1_flush）全部与 golden 逐字节相等**
（ftq2icache_fire_sum 19973=19973、_1_2 6345=6345、_mean 2=2、_underflow 0=0、bpu_s1_flush 23=23），
在 perf_compare 里进 MATCH（不是 EXCLUDED 也不是 0==0）。

剩下 2 条 BLOCKING（tage bank_1_tage_prov、storeQueue vaddr_match_failed 24 vs 14）不属本 lane；
注意 main 自 diag2 出表后已合入别的 lane，所以本次的 24 条 MISMATCH 集合与 diag2 的 27 条不完全同源。

## 5. 仍然没绑、诚实列出的 7 条（都在 docs/perf_bore_unbound.tsv，EXCLUDED）

mainPipe: data_corrupt_0/1、meta_corrupt_0/1、icache_bubble_s2_miss（golden 4171）；
prefetcher: prefetch_req_send_hw（golden 1020）、prefetch_req_send_sw。这些 bore 的 golden 观测点是
firtool 匿名线 `_GEN_0.._GEN_5 / _GEN_8 / _GEN_9`（如 `_GEN_0 = s2_data_corrupt_0 & REG`，REG=RegNext(s1_fire)），
同名导出就得在可读核里造 `_GEN_*` 名字（代码区禁用），T2 锥复制又只认端口/子模块叶子，寄存器叶子不认。
要绑它们需要 perf_rebind 增加「信号别名声明」这一类机制（或 hier_rebind_decl 扩一列），不在本 lane 范围。

## 6. 文件 sha256（commit 3a4fd6f34bfa3abfbac28e337a38e98d5debdddc 之后）

    5b3771fc6b59d15699253ecc4724d38f8c9d59fb5447b5b2bfbfd15d723d1f0a  rtl/frontend/ICacheMainPipe.sv
    c51e57c83b9193582b7bd11e51fed9cbab826c8e29116f77514dc8ea64c06958  rtl/frontend/IPrefetchPipe.sv
    dcfc330038360adc92de12bc6c089b0e2a6785b735b69fc79e0720376371c425  docs/perf_bore_map.tsv
    740aaf5dd892172e1ea562745802cc6903ebdf8a1bd4d1b83d39b56c307aaf94  docs/perf_bore_unbound.tsv
    3e1b31dbccb97e29a4f5f0bed60c40fc6d71e6ad9c1eb1ab99f02c0469726778  docs/perf_gap_ledger.tsv
    e634a39261de70c6e28ee5add95f062bb9b90b1869501c1ddb1c6c9781af3891  docs/perf_tier_ledger.tsv
    4bc2f6f9466271e37232c38440a451f91f60226f5c8d7ccef318831c85437575  evidence/5d0866cdffc5/ICacheMainPipe/receipt.json
    262be725fa7bdc5f352a07a1d5b17afe4b2dd82f84accaca0063d1022834ac0c  evidence/5d0866cdffc5/IPrefetchPipe/receipt.json
    6ceb4c0d99a048ad622035f392194dd1212dedff8457a42074e9371ea930ae39  golden assert.log（不变）

`docs/perf_mismatch_ledger.tsv` 本 lane 不写，由集成者在 main 上按 rebind → tier → compare 的顺序重出。
