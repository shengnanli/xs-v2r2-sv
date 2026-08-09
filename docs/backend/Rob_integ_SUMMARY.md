# Rob-integrator 交付摘要 (codex 0090 P2, branch agent/rob-integ)

## 4 patch 吸收 (全 done, commit 7560ab1)
- rob-perf-trace(66口): git apply clean
- rob-csr-debug(15口): 手动merge, retireCounter重复reg加_csr后缀
- rob-vec-exception(10口): 手动merge, 无冲突
- rob-lsq-deep(9口): +4核输出 + rob_lsq_deep_outputs.sv模块
核导出 A_CORE(70)+全100 C_DEEP。0 _GEN_/_T_ 真码(仅注释引用)。

## wrapper 2343-port 填充 (commit b88b8fd + 4 fix commits)
- 2081 leaf-passthrough (6逻辑叶子直驱)
- 70 A_CORE + 100 C_DEEP <- u_core (struct-field/trace-N/patch映射 + rob_lsq_deep_outputs)
- 92 B_SHALLOW <- RegNext/latch(both-side叶输出, exceptionHappen门控)
- 66 body-glue net 从golden内部重连u_core输出(非空耦合) + flat-port译码
- difftest链两侧elaborate, DPI sink=allow/Rob.json黑盒(无top-output影响)
生成器: gen_rob_wrapper.py + rob_wrapper_prelude.svh + rob_wrapper_epilogue.svh
wrapper elaborate: 12 modules 0 err (vcs)

## UT 结果 (tb_tap golden vs xs_Rob_core 逐拍)
- seed1 @200000: checks=199959 errors=0 PASS
- seed1/7/42 @20000: checks=19959 errors=0 PASS (全3seed)
- 修复后(deqSlot->commitInfo) seed1/7/42 @20000: errors=0 PASS

## full FM (Formality, 220873行golden, ~6.5GB峰值, 单跑串行)
Formality read_sverilog(比VCS严)暴露并修复5类(VCS未报):
  1. FMR_VLOG-481: deqSlot(n).field函数返回值域选 -> commitInfo[n].field
  2. FMR_VLOG-600 x2轮: wrapper o_*重复声明(prelude+u_i块) -> 剥离u_i块全类型o_*声明
  3. rab_vecLoadExcp_valid_REG 占位0 -> golden RegNext表达式
  4. 3 body-glue未驱动(exceptionGen.io_flush/enqPtr.io_allowEnqueue/rab sizes) -> 接u_core
  5. FMR_VLOG-135 illegal-select: 85 difftest-链deep-glue(_GEN_N[idx]/dt_*_ext_R*/
     commitValid_N_0/trace_valid_0)索引未驱动隐式线 -> tie 0(全difftest-only:
     0 top-output assign引用, 0 喂6逻辑叶子)。wrapper 最终 12 modules/0 err/0 implicit。
  6. FMR_ELAB-118: ptr_add/ptr_sub1 结构体返回值 -> o='0 初始化。
  7. FMR_ELAB-147(impl 侧 xs_Rob_core, 非 golden): 8位 robIdx 索引 160 深数组(rob_entries/
     debug_*/enq_ptr_vec)FM 判越界 -> link 期 FM-262 致命 -> impl set_top FM-046。★根治=
     rob_entries/rob_entries_next 声明为 ROB_ARR=256(2的幂)使8位下标恒在界 + 256宽 packed
     读向量(debug/fflags/vxsat/vls)+ 8宽 enqPtrVec8; 160..255 死项复位0永不读写★。修后
     impl-only FM check: 0 FMR_ELAB-147, impl `Setting top design to i:/WORK/Rob` 成功。
2处 main-owned infra blocker(须改共享 scripts/fm_eq.tcl, 两侧 read 前):
  1. FMR_ELAB-147+118+VLOG-091+063 filter: `set_mismatch_message_filter -warn <各>`
     (golden dt_160x1越界 + impl 核残余警告; 见 INFRA_CLOSURE_ROUND.md 已知 RAM 家族议题,
      fm_eq_full.tcl 有 ELAB-147 但共享 fm_eq.tcl 无——本 target 需扩)。
  2. fm_verdict.py --allowlist参数版本脱节。
最终 native FM 见 /tmp/rob-integ-evidence/fm_v6.log(两侧 filter 的 evidence tcl 直跑,
impl set_top 成功→match+verify)。

## integrator 须做 (main-owned)
1. declarations.tsv: Rob assembly verif/signoff/allow/Rob.json
2. regen 306-target manifest
3. scripts/fm_eq.tcl: 加FMR_ELAB-147 filter两侧
4. gap_schedule.tsv + combined_ledger 记录
5. fm_verdict.py --allowlist 参数修复
