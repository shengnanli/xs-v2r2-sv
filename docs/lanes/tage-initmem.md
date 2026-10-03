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

## 5. 落地（codex 0207 P1：perf 主比较两侧 Z0，GO）

codex 0207 P1 原话的四条要求：两侧 Z0 标记、编译设定、运行期 initreg、workload/seed 必须一致，任一缺失就判比较失败；
主结果仍要求全部已绑定探针逐拍精确相等，不设容差；`+vcs+initreg+1` 只作可选诊断；记录"原模式差异来自 simulation-only random-init 流，不改 RTL"。

### 5a. 设定凭据：`[PERFCFG]` 行由仿真器现场测得，不靠手填

* `verif/sim/perf_cfg_stamp.sv` 作为第二个 top（`-top perf_cfg_stamp`）编进整芯片，不连任何信号。它在 t=1 往 stderr 打一行
  `[PERFCFG] randomize_defines=… initreg_plusarg=… initreg_probe_reg=… initreg_probe_mem=… workload=… seed=… max_cycles=…`，
  落在 assert.log 里，与 `[PERF ]` 行同一个文件，因此被同一个 sha256 钉住。
  * `randomize_defines`：用 `` `ifdef `` 现场查 REG_INIT / MEM_INIT / GARBAGE_ASSIGN / INVALID_ASSIGN 以及 firtool 派生的 `RANDOMIZE`。
    stamp 文件编在文件表最后，所以 RTL 文本里泄漏出来的宏也看得到。
  * `initreg_probe_*`：一个无初值的 64 位 reg 加一个无初值阵列表项，取 t=1 的实测值。
    0…0 说明编译期开了 initreg 且运行期 +vcs+initreg+0；x…x 说明编译期没开 initreg；f…f 是 +1；其它值是 random。
  * **踩过的坑**：首轮整芯片 stamp 报 `randomize_defines=DELAY,`。原因是 golden 的 1998 个 firtool 文件头都自己写了
    `` `define RANDOMIZE_DELAY 0.002 ``，这是 RTL 文本，不是编译设定（它只在 `` `ifdef RANDOMIZE `` 块里用，Z0 下这些块不生成）。
    所以 stamp 不再查 DELAY（commit fdc503f6c），第二轮重建两侧之后数据才算正式。
  * 用独立的 VCS 小例子验证过五种设定（Z0 / 不加 initreg 值 / +1 / 带 RANDOMIZE_REG_INIT 等 define / 编译期不开 initreg），
    stamp 都报对了；另外造了一个在源文件里定义 RANDOMIZE_DELAY 的例子，stamp 报 none。
* `verif/sim/run_perf_z0.sh`：工作区直接复用 `run_perfbind.sh setup`。vcs 命令由 difftest 的 `make -n vcs-build` **机械生成**，
  然后去掉 `+define+RANDOMIZE_*`；脚本断言命令里有 `+vcs+initreg+random`，再追加 stamp。
  运行时固定加 `+vcs+initreg+0 +b=0 +e=…`；带额外 plusarg（例如 seed）的运行另起一个目录。

### 5b. 闸

* `scripts/perf_compare.py` 在比数之前先过 `init_contract()`。两侧都必须恰好有一条 `[PERFCFG]`，并且：
  * 每侧单独满足 Z0：无 RANDOMIZE_*、plusarg=0、两个探针全 0、有 workload 和 max_cycles；
  * 两侧 `randomize_defines/initreg_plusarg/workload/seed/max_cycles` 逐字相同。
  任一项不满足，就**不做比较，rc=3**，而且没有绕过开关。主比较本身照旧是精确相等，不设容差。
  `--emit-mismatch` 现在 0 条差异也会出表，表头另记 `init_contract Z0` 和两侧 `golden_cfg/impl_cfg` 原文。
* `scripts/check_perf_tier.py` 的判据 D 新增两项：`init_contract=Z0`；用同一个 `init_contract()` 对表头的两侧 cfg **现场复判**，
  不认表头的自述。
* 负测：
  * `scripts/test_perf_init_contract.py`（已进 gate_all）：P0 正例 rc 0；N1–N14 每次只坏一项，各自 rc 3，而且要红在预期的那条消息上
    （缺行 ×2、RANDOMIZE ×2、initreg random / +1、编译期没开 initreg、plusarg 写 0 但探针非 0、workload / seed / max_cycles 不一致、
    重复行、缺字段、没给 workload）；N15 设定全对但一个 B_CONTROL 计数差 1，rc 1（证明无容差）。
    破坏性自检：把 `cfg_problems` 改成早退，7 条用例当场变红。
  * `scripts/test_perf_tier_gate.py` 新增 13–15（表头缺 init_contract / impl 侧 initreg=random / 两侧 seed 不一致，都要红在判据 D）。
    夹具改成自带一条与分档台账一致的 WAIVED 行（Tage_SC `bank_1_tage_table_3_provided_at_pred`），
    这样 Z0 台账为 0 行时 1/2/4 号注入仍然有对象可打。
* 实测：
  * 旧口径日志（golden_cm20k 对 i_std）喂给 perf_compare，rc=3（缺 `[PERFCFG]`）；
  * Z0 golden 默认 seed 对 Z0 impl seed=987654321，rc=3（两侧 seed 不一致）。

### 5c. 当前 main HEAD 两侧 Z0 整芯片重出台账

* 分支在 merge main `3cd470621b7d0b5bd6cb1afe07ba5031930c82b6` 之后，生成表按 hier_map → perf_rebind → perf_tier 重算
  （main 自带的 hier_rebind_map 少 43 行，已补）。`git diff 3cd470621 <本分支> -- rtl` 为空。
* 构建 pin：setup（重绑 SimTop）在 `a71275fd215187b0a5bbd67b478f05179bafcb8c` 上做，build/run 在 `fdc503f6c32d0a2d7aaacde3f87f9c8383f6fc31` 上做。
  两者之间只改了 stamp、run 脚本和比较/闸脚本，生成表与 rtl/ 没动。

      T=/tmp/claude-1000/-home-eda-xs-env-XiangShan/6824a231-879a-49e3-b98d-f29f5afc381c/scratchpad/tage-initmem
      git worktree add --detach $T/wt-z0pin fdc503f6c
      SIMW=$T/z0main JOBS=16 $T/wt-z0pin/verif/sim/run_perf_z0.sh setup
      SIMW=$T/z0main JOBS=16 $T/wt-z0pin/verif/sim/run_perf_z0.sh build golden   # impl 同
      SIMW=$T/z0main $T/wt-z0pin/verif/sim/run_perf_z0.sh run golden                # impl 同；另加 "" "" +ntb_random_seed=987654321 做 seed 复跑
      python3 scripts/perf_compare.py $T/z0main/golden/run/coremark-2-iteration-20000/assert.log \
          $T/z0main/impl/run/coremark-2-iteration-20000/assert.log --all --emit-mismatch docs/perf_mismatch_ledger.tsv
      # rc=0  初值设定闸 ok；MATCH 9771 / MISMATCH 0 / EXCLUDED 15656 / MISSING 0；WAIVED 0 / BLOCKING 0

| 产物 | sha256 |
|---|---|
| golden Z0 assert.log `$T/z0main/golden/run/coremark-2-iteration-20000/assert.log` | `1489d6299121b59869c6be09266a18c742d3b540f5cd067c7aa967fbba8c4785` |
| impl Z0 assert.log `$T/z0main/impl/run/coremark-2-iteration-20000/assert.log` | `19ab356ee767ccfedf19da35d14c4ccaf2f8a467d32aa6e745ccb12c11ea1744` |
| golden Z0 seed=987654321 assert.log | `4b0285226980941ea2c82063ab6833ffbc46960a4cb33bb6da5c76b517e26916` |
| impl Z0 seed=987654321 assert.log | `fd577929393360483af18c359a82640c752df4fc3a2cfef1c6a335d7773e59f3` |
| golden simv / impl simv | `2eb43a4c3cc1b1cdcf6c949935bec85c635050df622b92e732c2362400ebd023` / `9514b3eb50a83ea9133c8001eb5ce3a74e766e2e7e6ad4664fbca020b0d122ca` |
| impl 重绑 SimTop.sv（复核：5943 条 XMR 全走得通、锥体与 golden 逐行相同） | `f257f9e77cd086ee01cd678b17a786d2a835c89f9763fae7721c6114fbcf90ef` |
| vcs_cmd_z0.sh golden / impl | `631063d037661c86c351168e9c8c47e7367a13f0460227d7c4aecb6660db18b1` / `0c6ef2c14feffe6e17471c6db7d2911da8b64147021fee60d163bbf77c32cc80` |
| `docs/perf_mismatch_ledger.tsv`（0 行，commit 头 c7e115154） | `31f58cd9b9dcdc4056990b817a1ea303b8742cc9c1692c7e0abf769a1a775a10` |
| `docs/perf_tier_ledger.tsv` / `docs/perf_gap_ledger.tsv` | `88d9815982223784d2574b901d666df5abff90a83458559bcb1daf1c70f176c5` / `7978af83f01a6b01d441435da1f3011c2f56f0c9da09dc353b84cd9739371720` |

* 两侧四次运行都是 EXCEEDED MAX CYCLE，difftest 没有 abort，assert.log 都是 27921 行 PERF。
  `[PERFCFG]` 两侧都报 `randomize_defines=none initreg_plusarg=0 probe=0`。
* seed 复跑：两侧去掉 `[PERFCFG]` 那一行（其中 seed 字段本来就该变）之后，其余内容逐字节相同；seed2 这一对 perf_compare 同样 rc=0、9771/0。
* 原 3 条 tage BLOCKING 现在全部相等：bank_0 provided 3007、bank_1 provided 215、alt_differs 618。
  storeQueue vaddr_match_failed 是 0/0/0，missQueue utilization 是 2658，与 golden 相同，且对 seed 不敏感。
* EXCLUDED 15656 条是"没测"（绑定率 3791/9897 = 38.3%），例如 impl 的 `rob commitInstr` 未绑，打印的是 0。
  按 codex 0207 E3 只对 release KPI 定向补绑，**本结果不得表述为 perf 全等价**。
* 闸 rc：`check_perf_tier.py` rc=0（A–F 全 PASS，含 A 台账幂等重算、D init_contract=Z0、两侧初值设定 Z0 且一致）；
  `test_perf_tier_gate.py` rc=0；`test_perf_init_contract.py` rc=0。

**原模式差异的定性（记录在案）**：原 RANDOMIZE_* 口径下的 tage provider / sc / alt_differs、vaddr_match_failed、missQueue utilization
等差异，都来自 simulation-only 的随机初值流：firtool 的无种子 `$random` 随模块替换平移，重写件用的是 initreg random。
**不据此修改 RTL。**
