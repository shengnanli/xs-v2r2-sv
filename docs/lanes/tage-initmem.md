# lane tage-initmem：perfre 剩下的 3 条 tage BLOCKING 是否来自初值口径

分支 `agent/tage-initmem`（worktree `/home/eda/xs-env/wt-tage-initmem`），诊断 lane，**没有改 RTL**。

* 构建 pin：`a28caa4f3bb06efaa898db020a3e7feb0435459f` = main `9c599a41` + merge `agent/perfre`（带 hier_reach / perf_rebind 两处修复；
  冲突的 5 张生成表在 9c599a41 上用 hier_map → perf_rebind → perf_tier 重算）。`git diff 9c599a41 a28caa4f -- rtl` 为空，即 RTL 与 main HEAD 逐字节相同。
* golden：`/home/eda/xs-env/G1-canonical/golden-rtl`（只读）。golden 原口径日志复用 perfre 那份
  `/home/eda/xs-env/sim-work/perfbind-runs/golden_cm20k/assert.log`（sha256 `6ceb4c0d99a048ad622035f392194dd1212dedff8457a42074e9371ea930ae39`）。
* 产物都在 scratch `T=/tmp/claude-1000/-home-eda-xs-env-XiangShan/6824a231-879a-49e3-b98d-f29f5afc381c/scratchpad/tage-initmem/`。

## 0. 结论（一句话）

**是初值差异，不是逻辑差异。** 两侧都用"全 0 初值"（Z0 口径）后，整芯片 coremark 20k 全部可比计数器 **MATCH 9801 / MISMATCH 0**，
3 条 tage BLOCKING 全部对上；换 `+ntb_random_seed`，两侧的 assert.log 都逐字节不变。
但嫌疑方向要改：**不是重写的存储层（SRAMTemplate / FoldedSRAMTemplate / WrBypass），也不是哪个 `*_ext` 存储**，
罪魁是 **golden 自己的 Tage_SC（两边都没重写）里 `s2_provideds_*` / `s2_providers_*` 这几个寄存器**。它们的
`RANDOMIZE_REG_INIT` 初值取自 `$random`，而 `$random` 是全设计共用的一条随机流：重写件替掉了带 `$random` initial 块的
golden 模块，流里的位置就跟着变，同一个 golden 寄存器在两个 build 里拿到不同的初值。

## 1. 实验矩阵

构建脚本 `T/tim_build.sh`（sha256 `7b17769d9885e564556bddfb5357facdd27cf3cd420f5a04366bf003b3bcc8c0`），由 perfre_build.sh 改出：

    SIDE=golden TAG=g_z0 INIT=z0          T/tim_build.sh   # golden：build3.log 原 vcs 命令（T/golden_vcs_cmd.orig.txt，sha ac4218368a9a0dc067478bc33e5e73e43e50dc2f1cb13c50de4a2d3cbd93042c）
    SIDE=impl PIN=a28caa4f TAG=i_z0  INIT=z0  T/tim_build.sh
    SIDE=impl PIN=a28caa4f TAG=i_std INIT=std T/tim_build.sh # 原口径，在新 HEAD 上复现 perfre 现象
    # INIT=z0：去掉全部 +define+RANDOMIZE_*（GARBAGE_ASSIGN/INVALID_ASSIGN/MEM_INIT/REG_INIT/DELAY），编译保留 +vcs+initreg+random，
    #          运行时加 +vcs+initreg+0。实测（T/inittest/t.sv）initreg 同样覆盖 unpacked 存储阵列：reg/logic/ram[] 全 0。
    # 跑法同 perfre：simv +diff=NEMU +workload=coremark-2-iteration.bin +max-cycles=20000 +b=0 +e=1000000 [+vcs+initreg+0]
    # 四次运行都是 "EXCEEDED MAX CYCLE"，difftest 没有 abort，assert.log 都是 27921 行

| 运行 | bank_0_tage_provided_at_pred | bank_1_tage_provided_at_pred | bank_1 table_3 provided_at_pred | tage_bank_0_alt_differs | assert.log sha256 |
|---|---|---|---|---|---|
| golden 原口径（perfre 复用） | 4036 | 1244 | 1037 | 617 | 6ceb4c0d99a048ad622035f392194dd1212dedff8457a42074e9371ea930ae39 |
| impl 原口径 `i_std`（a28caa4f） | **4036** | 215 | 8 | **617** | 475961f4c489d841db8c159d736316b779797ab1099c7fec9d12b9a4b0a3ee8d |
| golden Z0 `g_z0` | 3007 | 215 | 8 | 618 | 1ba999ca4739bd69b6b4a9f943140bd6ffc76efd0c491dd75c3fe9590ebc88cb |
| golden Z0 + `+ntb_random_seed=987654321` | 3007 | 215 | 8 | 618 | 1ba999ca…（**同上，逐字节相同**） |
| impl Z0 `i_z0` | 3007 | 215 | 8 | 618 | a8b7bce42ca4fcc933306c85e115ecbf19e83a50809a48a806601e8e3b70ccbe |
| impl Z0 + `+ntb_random_seed=987654321` | 3007 | 215 | 8 | 618 | a8b7bce4…（**同上，逐字节相同**） |

比对（在本分支 a28caa4f 上，`docs/perf_tier_ledger.tsv` 为重算后的版本）：

    python3 scripts/perf_compare.py <golden_cm20k>/assert.log T/runs/i_std/run/cm20k/assert.log --all --emit-mismatch T/mismatch_std.tsv
      # MATCH 9792 / MISMATCH 9（WAIVED 7 / BLOCKING 2：bank_1_tage_provided_at_pred 1244 vs 215，storeQueue vaddr_match_failed 24 vs 17）
      # mismatch_std.tsv sha256 f55076d472f6fc105d5d8e8deb15249b3a3c0ba121d81dc0a6f85ebf31def14f
    python3 scripts/perf_compare.py T/runs/g_z0/run/cm20k/assert.log T/runs/i_z0/run/cm20k/assert.log --all
      # rc=0  MATCH 9801 / MISMATCH 0 / EXCLUDED 15626 / MISSING 0
    python3 scripts/perf_compare.py T/runs/g_z0/run/cm20k_seed2/assert.log T/runs/i_z0/run/cm20k_seed2/assert.log --all
      # rc=0  MATCH 9801 / MISMATCH 0（日志 sha 与上一行 compare_z0.log 相同：af7130b573c79caa9dea1fedd32704a8a151ebc25a5195a1aefbf928b23a6eb7）

i_std 和 i_z0 的重绑 SimTop 是同一份文件（sha256 `a6f28fe4e873da093b3d8d728d3127c5e4db97828dcc4d3edb8be7b108057e92`），
所以两者只差编译 define 和运行参数。simv sha256：g_z0 `03a4c61d771239b1931bf87120a8e54759a806bb1a18e1e38239368e5e9bc031`，
i_z0 `d0ebe81bc5c3abca4109d9ae405ea0f081a8c504798bad4e43803ae93d3ff9b1`，i_std `04381262e3aa7217a1f064a975143462482d279bbb40f05e9f24ffbb82322ac9`。

另外两点：
* 在新 HEAD 上，原口径的结果又换了样子：bank_0 对上、bank_1 不对（perfre 在 f19 上是 bank_0/bank_1 都不对，在 nopred 上是 bank_0 对、bank_1 不对）。
  这和"各个 build 的 `$random` 流位置不同"完全吻合。
* golden 原口径和 golden Z0 只是初值不同，比出来有 54 个计数器不一样，但 `rob commitUop 12863 / commitInstr 16162` 两边相同。
  也就是说，初值只影响观测量和预测器的启动态，不影响提交流。

## 2. 机理（定位到寄存器）

**计数器写法**（golden Tage_SC.sv）：`bank_N_tage_provided_at_pred` 是 `XSPerfAccumulate(s2_provideds(N))`，每拍都累加，**不带 fire 门控**；
分表的计数用 `pred_i_provided_*_probe = s2_provideds_N & s2_providers_N == k`（Tage_SC.sv:1237-1270）。
而 `s2_provideds_*` / `s2_providers_*` 只在 `io_s1_fire_1` 时更新（Tage_SC.sv:5164-5167），上电初值来自
`_RANDOM[9'h36]`（Tage_SC.sv:5815-5818，`RANDOMIZE_REG_INIT`，`` `RANDOM `` = `$random`）。
所以 BPU 第一次 s1_fire 之前的那段启动窗口里（TageBTable 的 `doing_reset` 要扫 1024 行，Tage 表的 SRAM resetState 要扫 512 行），
计数器每拍都在累加寄存器里的那个随机初值。

**ucli 实测**（脚本 `T/ucli/p.tcl` sha d0fc23f6fba29dc96996a2cc1e214bb27c6fec537f56fdbdb43b36e9f9a6a21d，`T/ucli/c.tcl` sha e10305f2c92ba299030d05bd9ba10ef55b3be3dcef0198acaa6c351bfed0f022；
simv 用的就是产生台账的两份：golden `/home/eda/xs-env/sim-work/golden/build/simv` sha 855484a7a8f44b10ec3eb42f84adf35c16dbab733b474d7d2ccd8aec8f0c04a0，
impl `/home/eda/xs-env/sim-work-perfre/f19/build/simv` sha 88c5c2456ae66a4dad4b5d5e4bb15ad7f112b26e424db72c12a6a7c0eba29ba0）：

| 实例 `…frontend.inner_bpu.predictors.tage` | s2_provideds_0 | s2_provideds_1 | s2_providers_0 | s2_providers_1 |
|---|---|---|---|---|
| golden，t=5ns…2100ns | 1 | 1 | 0 | 3 |
| impl f19，t=5ns…2100ns | 0 | 0 | 3 | 3 |

reset 在 105ns 释放，到 2157ns 第一次 `io_s1_fire_1` 时寄存器才被改写（时钟周期 2ns，中间约 1026 拍；计数器自己的复位比这里早几拍释放，
所以累加了 1029 拍）。golden 的初值是 provided=1、provider_0=table_0、provider_1=table_3，于是在启动窗口里
bank_0 table_0 和 bank_1 table_3 各多出 1029，`use_bim` 少 1029，`sc_*_at_pred` 少 1029。impl build 里这个 golden 寄存器的初值碰巧是 0，
所以没有多出来的部分。这正是 perfre 看到的"−1029 在 table_0/table_3/bim 之间搬家、总预测数不变"。

**为什么对 `+ntb_random_seed` 不敏感，却随 build 变化**：最小复现 `T/inittest/r.sv`（sha f2bcb0eb71d071a29750ad43c8ba4cd8757392cbd265e29e3940b8724173be9d）。
同一个 `victim` 模块里的 `v = $random`：前面多例化两个也调 `$random` 的模块，值就从 `12153524` 变成 `8484d609`；加 `+ntb_random_seed=7`，两种情况都不变。
VCS 里不带 seed 参数的 `$random` 用的是全局种子，与 `+ntb_random_seed` 无关；它取到的值由取号顺序决定，也就是由前面有多少个
`$random` initial 块决定。重写件用 initreg、不调 `$random`，每多替换掉一个带 `$random` 的 golden 模块，后面 golden 寄存器
拿到的初值就会整体移位。perfre 的二分（notage2 修好 bank_1、nopred 修好 bank_0 又弄坏 bank_1）只是在挪这条流的位置，
并没有定位到任何模块。

`tage_bank_0_alt_differs`（617/618）和 `tables_0` 的 `real_updates / silent_updates_eliminated` 也属于同一类：同一份 golden RTL，
只把初值从原口径换成 Z0，结果就从 617 变成 618，Z0 下两侧相等。这里没有继续追是哪一个寄存器或 WrBypass 表项，因为结论不受影响。

**关于原先的嫌疑**：Tage 表的 SRAM（golden SRAMTemplate_45 `_resetState/_resetSet`，重写核 `xs_SRAMTemplate_core` resetState）和
TageBTable（`doing_reset` 写 2'h2）上电后都会整表清扫，`*_ext` 里随机的阵列内容根本到不了预测输出；SRAM 读口另有
`rdata_last_REG ? array : hold` 寄存器挡在中间，`RANDOMIZE_GARBAGE_ASSIGN` 的每拍垃圾数据也传不出来。
所以本案与存储层的初值口径无关。任务 2（继续二分到单模块）不需要做：Z0 下已经全部相等，没有残余的逻辑差异。

## 3. storeQueue vaddr_match_failed 与 missQueue utilization 族

**在 Z0 下两者都稳定并且相等**：三个 `vaddr_match_failed` 在 g_z0、i_z0 以及各自换 seed 的四次运行里都是 0/0/0；
`missQueue utilization` 四次都是 2658；整份 assert.log 换 seed 逐字节不变。原口径下的 24 vs 17 和 seed 敏感性，
正是 perfre 所说的"无复位寄存器读 initreg 垃圾"，与 tage 同属初值口径问题。

## 4. 处置建议（不改 RTL）

1. **把 perf 比对的初值约定写进规范**：golden 和 impl 都用 Z0。编译时去掉全部 `+define+RANDOMIZE_*`，保留 `+vcs+initreg+random`；
   运行时加 `+vcs+initreg+0`。只有这样两侧的初值才与 build 拓扑无关：firtool 的 `$random` 初始化会随"替换了哪些模块"漂移，
   不能拿来做跨 build 的对照。台账 of record 应改用 Z0 重出（本 lane 的 g_z0/i_z0 可直接作为新基线）。
2. 在 `perf_compare.py` / `check_perf_tier.py` 里加口径闸：两侧日志都必须带 Z0 标记（例如 sim 目录里的 `runargs.txt`，或 sim.log 回显的编译 define），
   口径不一致或缺标记时直接 rc≠0，避免把初值差异判成 BLOCKING。
3. 可选的加强：再加一档 `+vcs+initreg+1`（Z1，本 lane **没跑**）。Z0 与 Z1 结果不同的计数器标为"初值敏感"，
   比如每拍累加的无复位寄存器（robHeadPC、vaddr_match_failed、tage `*_at_pred`、missQueue utilization），归入 C_DIAG/D 类，不作为 BLOCKING。
4. perfre §7 的 tage 二分结论应改为：嫌疑不在 TageTable/TageBTable/Predictor/Composer/存储层，而在启动窗口里 golden 寄存器的 `$random` 初值。
