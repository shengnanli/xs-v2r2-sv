# simperf-diag：整芯片 impl simv 比 golden 慢的只读诊断（codex 0240 遗留 4 / B 线）

Integrator 自做，2026-10-19，基于 main 9ae0e8144。**只读：不改 RTL、不改任何脚本、不入库派生态。**

## 0. 前提与口径
- 现象（fullchip-bench §5.5-4）：coremark sim CPU 5065 s（impl）对 3731 s（golden），+35.8%。
  两侧 instr/cycle 完全相同，所以这是**仿真器耗时**，不是设计 IPC 退化。
- 本诊断：两侧在独立工作区 `/home/eda/xs-env/sim-prof` 用与 sim-fcb **完全相同**的 vcs 命令行
  外加 `-simprofile` 重编（difftest 副本取 sim-fcb 的，只读），运行期加 `-simprofile time`。
- 负载：dhrystone，`+max-cycles=40000`（有界诊断；含初始化，比值偏大于整程）。

| 侧 | user CPU（/usr/bin/time） | simprofile Total CPU | 峰值 RSS |
|---|---|---|---|
| golden | 459.4 s | 434.6 s | 753 MB |
| impl | 760.1 s | 743.2 s | 401 MB |

差额 ≈ 309 s（profile 口径）。

## 1. 差额落在哪（实例子树 incl 时间，秒）

| 子树 | golden | impl | 差 |
|---|---|---|---|
| backend（Backend 合计） | 215.8 | 535.2 | **+319** |
| ├ ctrlBlock.rob（Rob） | 74.4 | 161.2 | **+87** |
| ├ intScheduler（4 个 int IQ） | 27.0 | 113.8 | **+87** |
| ├ memScheduler（Ldu×3/StaMou×2/StdMoud×2…） | 16.1 | 83.5 | **+67** |
| ├ dataPath | 30.3 | 43.5 | +13 |
| └ ctrlBlock 其余（dispatch/decode/rat/rename） | 56.1 | 87.4 | +31 |
| memBlock | 62.5 | 94.8 | +32（storeQueue 13.0→32.0，SQData8Module×16 21.5 s） |
| frontend | 70.4 | 49.7 | **−21**（impl 更快：Ftq 24.4→<10） |
| logEndpoint（LogPerfEndpoint，golden 原文件两侧同源） | 39.6 | 11.6 | −28 |

按构造类型：golden = ContAssign 216 s + Always 150 s；impl = **AlwaysComb 433 s** + ContAssign 76 s
+ Function 53 s + AlwaysFF 49 s + PortConnections 43 s。

## 2. 热点与机理

1. **Rob（+87 s）**：前三个 always_comb 就占 126 s。
   - `rtl/backend/Rob.sv:3402-3446`（54 s）：enq payload Mux1H，`for i<ROB_SIZE(160) for j<6` 对一个
     宽结构体逐字段 `|=`；
   - `Rob.sv:3474-3517`（50 s）：写回计数/flush/fflags/vxsat/taken，`for i<160` × 各写回口比较；
   - `Rob.sv:3174-3186`（22 s）：enqOH/uopCanEnq/instCanEnq，`160×6` 个比较器。
   机理：一个 always_comb 是**一个进程**，任何一个输入位变化都要把 160 项整块重算一遍；
   golden 的 firtool 输出是逐信号 `assign`，VCS 只重算真正变了扇入的那几条。
2. **IssueQueue 家族（int +87 s、mem +67 s）**：`xs_iq_entry` 118.9 s + `xs_iq_entries_core` 46.3 s
   + `xs_IssueQueue_core` 23.4 s + `xs_AgeDetector_core` 11.7 s。单个构造都不大
   （最大 `xs_iq_entries_core.sv:567-602` 唤醒匹配 7.3 s），但实例多（每个 IQ 16–24 项、十余个 IQ，
   每项 payload 541–1362 位）。同一机理：每个 entry 的唤醒/取消/payload 选择写在少数
   几个大 always_comb 里，任一唤醒口变化即整块重算。
3. **SQData8Module（21.5 s，×16）**：`SQData8Module.sv:290-302` always_comb 13.5 s。
4. 反向：Frontend（Ftq/IBuffer）impl 比 golden 快 21 s；LogPerfEndpoint 两侧同源却少 28 s，
   推测是 impl 侧 perf 事件翻转更少（perf 计数不在对拍范围，记为观察，未查）。

## 3. 可读优化建议（不自动改；每条都要过 FM + UT 6 档）
- **按条目拆进程**：把 `for (int i...)` 的大 always_comb 改成 `for (genvar i...) begin : g_ent
  always_comb ... end`（或逐项 assign）。语义不变、可读性不降，VCS 的敏感粒度变成每项一个进程。
  优先级：Rob 3402/3474/3174 三块 → xs_iq_entries_core 唤醒/取消块 → SQData8Module 290。
- **索引比较改译码**：`enqOH[i][j] = canEnqueue[j] & (allocatePtrValue[j] == i)` 改为每个 j 先做一次
  one-hot 译码再按位与，160×6 个比较器变 6 个译码器。
- **Mux1H 结构体**：逐字段 `|=` 改为打包位向量一次 AND-OR（注释里写明字段布局），或保持结构体
  但只在 genvar 块内求值。注意 Rob.sv 注释：存储必须保持每字段一个非打包数组（FM pin 匹配），
  这里只动组合路径。
- 预期：Backend 差额（+319 s）里 Rob + IQ 约 240 s 属于这一机理；先做 Rob 三块（单文件、单目标），
  用同一 sim-prof 流程复测即可量化收益，再决定是否推广到 IQ。
- 工具侧（不改 RTL）可另试：VCS `-O`/`+rad` 等优化选项对 always_comb 大进程的效果——须两侧同开，
  且不改 sim-fcb 已登记的对拍配置。

## 4. 复现
```bash
P=/home/eda/xs-env/sim-prof   # 两侧 build/ 由 sim-fcb 的 build/（除 simv*）rsync 而来
$P/build_prof.sh golden; $P/build_prof.sh impl      # = run_fullchip.sh build 的 make 命令 + EXTRA 加 -simprofile
cd $P/<side>/run/dhry && VCS_ARCH_OVERRIDE=linux $P/<side>/build/simv +workload=/home/eda/xs-env/sim-fcb/workloads/dhrystone.bin \
  +diff=$NOOP_HOME/ready-to-run/riscv64-nemu-interpreter-so +ram_size=8589934592 +max-cycles=40000 \
  -suppress=ASLR_DETECTED_INFO -simprofile time
# 报告：$P/<side>/run/dhry/profileReport.{txt,json,html}
```
