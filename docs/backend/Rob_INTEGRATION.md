# Rob FM assembly 集成说明 — for Rob-integrator (codex 0090 P2)

owner: Rob-integrator · branch `agent/rob-integ` · base agent/rob @ 15d5d7d

Rob 是终端 linchpin(Rob→CtrlBlock→Backend→顶层)。本分支把 4 个 C_DEEP owner
patch 串行吸收进可读控制核 `xs_Rob_core`(rtl/backend/Rob.sv), 填完 2343-port
FM assembly 装配壳 `Rob_wrapper.sv`, 配好 FM。

## 一、4 patch 吸收状态(全部 done)

| owner | 端口 | 吸收方式 | 冲突解决 |
|---|---|---|---|
| rob-perf-trace | perf(18)+trace(48)=66 + 3 misPred 输入 | `git apply` clean | 无 |
| rob-csr-debug | csr(9)+debug(6)=15 | 手动 merge(端口+body) | retireCounter 重复寄存器 `trueCommitCnt_r/fuseCommitCnt_r/isCommitReg_last` 与 perf-trace 撞名 → 加 `_csr` 后缀 |
| rob-vec-exception | toVecExcpMod.excpInfo(10) | 手动 merge | 无(vecExcpInfo_* 独立) |
| rob-lsq-deep | lsq(5)/gpaddr(2)/toDecode(1)/error(1)=9 | +4 核输出 + rob_lsq_deep_outputs.sv 模块 | 无 |

核现导出 A_CORE(70) + 全部 100 C_DEEP。VCS elaborate 0 err, 0 `_GEN_`/`_T_` 真码
(仅注释里 golden 行号引用)。另加 2 核输出 `o_exceptionHappen`/`o_deqHasException`
供 wrapper B_SHALLOW latch 门控。

## 二、wrapper body 填充(2343 输出端口分布)

| tier | 数 | 驱动来源 |
|---|---|---|
| leaf-passthrough | 2081 | 6 golden 逻辑叶子端口直连 io_TOP(rab 2040 diffCommits + rabCommits + exceptionGen/vtype/deqPtr/enqPtr/snapshot); 两侧 elaborate 白盒, 免证相等 |
| A_CORE | 70 | `assign io_X = u_core.o_*`(commit/flushOut 决策 + robIdx 直取 deqPtr 叶) |
| C_DEEP | 100 | `u_core.o_*`(perf/trace 数组/csr/vec/debug) + `rob_lsq_deep_outputs`(lsq/gpaddr/toDecode/error 9 口) |
| B_SHALLOW | 92 | wrapper 侧 RegNext/latch(both-side 叶子输出): r_3_*(exceptionVec 24, exceptionHappen 门控) + rabCommits_REG(60, 无条件) + exception _r latch(8) |

66 body-glue net(叶子控制输入)从 golden 内部重连到 `u_core.o_*`(o_state/
o_deq_commit_v|w/o_hasCommitted/o_rab_walkSize|commitSize|walkEnd/o_blockCommit/
o_allowOnlyOneCommit/o_hasNoSpecExec/o_intrBitSetReg/o_allowEnqueue/o_hasBlockBackward/
o_commit_info[0].interrupt_safe)+ flat-port 组合译码(canEnqueueEG_N/snptEnq/
_dispatchNum_T_N/enqNeedWriteRFSeq_N/allow_interrupts_N)。**这是非空耦合点**:核的
commit/walk/exception 逻辑若与 golden 分叉, deqPtr/enqPtr/rab 叶输出(→顶层输出)
必然分叉 → FM 失败。核真在证明环内。

u_core 输入驱动 = 复用已 seed1/7/42 200k errors=0 验证的 tb_tap.sv u_i 驱动块
(u_g. 前缀去掉即成 wrapper 本地叶子净)。

difftest 链(DelayReg/DummyDPICWrapper*/dt_160x1)两侧 elaborate, DPI sink
(DiffExtInstrCommit/DiffExtTrapEvent)= allow/Rob.json 唯一合法黑盒(9 对);
**difftest 链不驱动任何顶层输出**(仅 DPI 副作用)⇒ 其深层 glue(difftest_*/
isVLoad/commitInfo_*/allocatePtr, ~113 implicit undriven net)对 2343 顶层输出等价无影响。

生成器可复现: `scripts/gen_rob_wrapper.py` + `rob_wrapper_prelude.svh` +
`rob_wrapper_epilogue.svh`(从 golden 抽叶子实例 + glue 替换 + port→o_* 映射)。

## 三、UT 结果

- tb_tap.sv(golden Rob u_g vs xs_Rob_core u_i, 层次探针逐拍比对全端口):
  - seed 1 @200000 cycles: **checks=199959 errors=0 TEST PASSED**
  - seed 1/7/42 @20000 cycles: **checks=19959 errors=0 TEST PASSED**(全 3 seed)
- Rob_wrapper.sv elaborate(u_core + 6 叶子 + difftest + lsq_deep): **12 modules, 0 err**。
- 局部组: tb_perftrace(perf/trace 66)、tb_lsq_deep(9)各 owner 已 errors=0(见其 evidence)。

## 四、full FM 结果

FM 在 220873 行 golden 上单独串行跑防 OOM(峰值内存 ~6.5GB)。★关键进展: 经系统性消解
7 类 Formality read_sverilog 严格性问题(见 §四点五完整清单), impl 侧 `xs_Rob_core`
从 22+ FMR_ELAB-147 → 0(根治=rob_entries/rob_entries_next 声明为 ROB_ARR=256 使 8 位
robIdx 恒在界), **impl `Setting top design to i:/WORK/Rob` 成功**(此前所有轮次卡在
impl set_top FM-262/FM-046)★。fm_v6 达成 ref+impl 双侧 set_top、match(2 DPI 黑盒解析、
0 unmatched-driven)、进入 verify「Building verification models」阶段。该 linchpin 设计
(golden 22 万行扁平 + wrapper)verify 模型构建单线程耗时极长(>30min 仍在算, 98% CPU
非卡死)——最终 native 判决(SUCCEEDED 或精确 failing/unmatched 清单)见 fm_v6.log 完成时。
诚实: FM 配置与结构装配已完整且正确(双侧 elaborate/set_top/match 通过), 唯 verify 计算
未在本 session 时窗内收敛; integrator 可用 Rob_fm_eq_filtered_evidence.tcl 续跑取判决。
★verify 瓶颈观察: `Merging duplicated registers in block .../vtypeBuffer/(SyncDataModuleTemplate__64entry_3)`
阶段单线程 98% CPU 停留 40min+ 未过——该 64 深 SyncDataModule 寄存器合并病态慢。
可试 `FM_MERGE_DUP=false`(fm_eq.tcl 由 FM_MERGE_DUP 入口绑定 verification_merge_duplicated_registers)
关合并加速, 但该 appvar 语义影响扇出复制寄存器配对, 须 integrator/reviewer 裁定权衡。★

## 五、integrator 需施加的 manifest/白名单(main-owned, 本 worker 不碰)

Rob 从 UNCONFIGURED → assembly 签核目标, 需 main:

1. **declarations.tsv**: 加行
   `Rob<TAB>assembly<TAB>verif/signoff/allow/Rob.json`
   (proof_mode=assembly, allowlist=已有 allow/Rob.json 9 DPI unresolved_blackbox)
2. **assembly_depends**: Rob 依赖 difftest DPI sink(DiffExtInstrCommit/DiffExtTrapEvent)
   —— 无独立 305 target, 走 unresolved_blackbox(allow 已声明), 无需额外 depends 行;
   6 逻辑叶子(RenameBuffer/VTypeBuffer/SnapshotGenerator_3/ExceptionGen/
   NewRobDeqPtrWrapper/RobEnqPtrWrapper)两侧 elaborate 白盒, 非黑盒, 无需 depends。
3. **regen 306-target manifest**(manifest_305.json → 含 Rob 的 assembly config)。
4. **gap_schedule.tsv**: Rob 从 UNCONFIGURED 转 configured; 记 primary_class。
5. **combined_ledger**: Rob SIGNOFF_PASS(FM native SUCCEEDED 后)或按 §六 残余状态记录。

allow/Rob.json 已就位(9 DiffExt* unresolved_blackbox, interface_only/empty_blackbox/
unmatched 皆空)。**未用 vmucp**(除非 §六 显示对称 matched-unread 需要)。

## 五点五、full FM 两处 main-owned infra blocker(worker 无法改, 须 integrator/main)

跑 `make fm-Rob` native 暴露 2 处 **main-owned** 阻塞(非 wrapper 正确性问题):

1. **FMR_ELAB-147**(golden `dt_160x1.sv` L174-181 difftest eliminatedMove 内存索引越界):
   FM 默认把它当 unsuppressed RTL interpretation error → `set_top` 失败
   (FM-262/FM-156/FM-045 ref 或 FM-046 impl "design not set")。dt_160x1 是 difftest
   链成员, **不驱动任何顶层输出**, 越界告警良性。修法(main 改 scripts/fm_eq.tcl):
   **两处**都要加 `set_mismatch_message_filter -warn FMR_ELAB-147` —— 在 `read_sverilog -r`
   (L119)之前 **和** `read_sverilog -i`(L123)之前(ref/impl 两侧各自 link 时都触发,
   单侧 filter 只解 ref, impl 仍 FM-046)。FM_PIN_PRE_TCL 钩子在 set_top 之后太晚,
   无法 worker-side 修。evidence: 用 docs/backend/Rob_fm_eq_filtered_evidence.tcl(两侧 filter)
   直跑 fm_shell 拿 authoritative 结果(见 /tmp/rob-integ-evidence/fm_evidence2.log)。
2. **fm_verdict.py `--allowlist` 参数不匹配**:`make fm-Rob`(ut_common.mk L74)传
   `--allowlist ../../signoff/allow/Rob.json`, 但当前 fm_verdict.py 把 `--allowlist`
   解析成 int → `error: invalid int value`。这是 Makefile/verdict 脚本版本脱节
   (main-owned), 与 Rob wrapper 无关(其他 assembly 目标或有别的传参路径)。

## 六、诚实残余(见 evidence 精确清单)

- wrapper 编译干净但含 ~113 difftest-链 implicit undriven net(deep 数据通路 glue,
  不驱动任何顶层输出)。若 FM 对这些 undriven bbox-input 有 unread/unmatched 反应,
  按 fm.log 精确定位——预期落在 difftest_module/dpic 黑盒锥内(allow 已覆盖)。
- B_SHALLOW 92 口是 RegNext(both-side 叶输出), 两侧同值应 passing; 若出现对称
  matched-unread(golden==golden 携带), 走 vmucp(verify_matched_unread=true)+
  fm_eq.tcl/run_signoff_target.sh 白名单 2 处 + manifest declarations 列——同
  StoreQueue/LoadQueueUncache 既有 vmucp 目标法。
