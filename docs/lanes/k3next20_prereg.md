# kimi/k3-next20 lane —— 预登记（prereg）：20 个 FPU 可读叶目标

基线：`kimi/k3-next20` @ 选择时 HEAD（见本文件首次提交）。目标全部来自冻结 G1
XSTop design universe（`docs/g1_configured_universe.tsv` 中 `in_universe=yes,
new_target`；`docs/coverage_three_axis.tsv` 均为 `MISSING/UNPROVEN`）。

## 排除对账（机械）

- codex_0204/0205 已完成未集成的 20 个：AluResSel、ShiftResultSelect、
  WordResultSelect、MiscResultSelect、JumpDataModule、BranchModule、
  CommitIDModule、RoundingUnit{,_1,_2,_3,_4,_8,_9,_11}、
  Arbiter2_L2TLBImp_Anon、Arbiter2_PtwReq、Arbiter2_LLPTW_Anon、
  Arbiter2_L2TlbWithHptwIdBundle、Arbiter4_L2CacheErrorInfo —— 无重叠。
- Claude 在途认领（bridge 0193/0194/0195/0197/0198）：ctrlblock、datapath
  （DataPath + Fp/Vf/V0/Vl RegFile + *RFReadArbiter + *RFWBCollideChecker）、
  lquncache2（LoadQueueUncache、PipelineRegModule/_1/_2、LqExceptionBuffer）、
  iqfam（NewAgeDetector*、MultiWakeupQueue*、IssueQueue*、Scheduler/_1/_2/_3）、
  dcache 子树、l2slice 子树 —— 无重叠。
- 对 `.agent-bridge/outbox+inbox` 全部消息逐名 `grep -w`：20 个名字零命中。
- 全部父模块（fpdiv_r64_block{,_vector}、fpsqrt_r16{,_block}、fpsqrt_vector_r16、
  SRT16Divint{,_4,_6}、I8DivNr4、IntToFPDataModule、IntToFP_3、ExeUnit_5、
  VectorFloatDividerR64、FloatAdderWidenFormat）均 MISSING/UNPROVEN 且无人认领，
  因此这些叶不是任何已重写模块的吸收子模块（无 hier 吸收冲突）。
- 文件隔离：每个目标一个新 `rtl/backend/<Module>.sv`，三个新
  `verif/ut/<Family>/`，三个新 `scripts/gen_*.py`；不改任何共享文件
  （共享核、gate_all、台账、fm_target_config 均不碰；生成器幂等闸为自动扫描，
  无需登记）。

## 精确目标清单（20）

### 族 A —— FPU radix-4 SRT 除法/开方 qds 与 lzc 叶（10），UT 目录 `SRTDivSqrtLeaves10`

| # | 模块 | golden 行数 | golden 子模块 | golden 父 |
|---|---|---:|---|---|
| 1 | r4_qds | 109 | — | fpsqrt_r16_block |
| 2 | r4_qds_v2 | 105 | — | fpdiv_r64_block{,_vector} |
| 3 | r4_qds_spec | 179 | — | fpsqrt_r16_block |
| 4 | r4_qds_v2_spec | 150 | — | fpdiv_r64_block{,_vector} |
| 5 | r4_qds_cg | 133 | — | fpsqrt_r16{,_block}、fpsqrt_vector_r16 |
| 6 | SRT4qdsCons | 106 | — | SRT16Divint{,_4,_6} |
| 7 | IterBlockI8Nr4 | 114 | — | I8DivNr4 |
| 8 | lzc | 214 | — | fpsqrt_r16{,_vector_r16} |
| 9 | lzc_3 | 145 | — | fpsqrt_vector_r16 |
| 10 | lzc_4 | 113 | — | fpsqrt_vector_r16 |

### 族 B —— IntToFP 转换闭包（8），UT 目录 `IntToFPLeaves8`

| # | 模块 | golden 行数 | golden 子模块 | 处置 |
|---|---|---:|---|---|
| 11 | LZA | 158 | — | 重写 |
| 12 | IntToFP_prenorm | 191 | CLZ、LZA | 重写；CLZ 用已签 rtl/common/CLZ.sv，LZA 用本族 #11 |
| 13 | IntToFP_postnorm | 124 | RoundingUnit | 重写；RoundingUnit 两侧 golden-reuse（codex_0205 在途，避让其 rtl 文件） |
| 14 | IntToFP_postnorm_1 | 123 | RoundingUnit_1 | 同上 |
| 15 | IntToFP_postnorm_2 | 124 | RoundingUnit_2 | 同上 |
| 16 | IntToFP | 119 | prenorm+postnorm | 重写，族内例化 |
| 17 | IntToFP_1 | 119 | prenorm+postnorm_1 | 重写，族内例化 |
| 18 | IntToFP_2 | 119 | prenorm+postnorm_2 | 重写，族内例化 |

### 族 C —— FP 规格化 shift-priority 叶（2），UT 目录 `ShiftPriorityLeaves2`

| # | 模块 | golden 行数 | golden 父 |
|---|---|---:|---|
| 19 | ShiftLeftPriorityWithF32EXPResult | 121 | FloatAdderWidenFormat |
| 20 | ShiftLeftPriorityWithLZDResult | 244 | VectorFloatDividerR64 |

## 验收

- 每族一个确定性生成器（`scripts/gen_srt_divsqrt_leaves10.py`、
  `gen_inttofp_leaves8.py`、`gen_shiftpriority_leaves2.py`），支持 `--check`。
- 每目标 golden 双例化差分 UT + 独立数学/行为 oracle；>= 6 个确定性种子，
  含定向边界（全 0、全 1、前导 0 计数 0/宽度/宽度±1、qds 五比较器全符号组合、
  IntToFP 各精度/符号/舍入模式与特殊值）。
- `make portlint`（FM_VARIANTS 全 20 个端口契约）。
- official detached-clean-worktree FM（`scripts/run_proof.sh`）：20/20 native
  SUCCEEDED；failing/unverified/aborted/unread/unmatched/blackbox/dont_verify
  全零。任何 mismatch 只改 RTL 修，不 waiver。
- 实现 commit 与 evidence commit 分离；receipt 绑定 clean committed 字节；
  结束时工作树 clean。
