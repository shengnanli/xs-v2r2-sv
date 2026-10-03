# lane perfre —— 用当前 main 全部重写件重跑整芯片 coremark，重出 perf 台账

分支 `agent/perfre`（worktree `/home/eda/xs-env/wt-perfre`）。

* **钉的 main commit：`f19ff3979ebc92daa3bfd562cb137d35c2027843`**（Merge branch 'agent/storeunit-vsplit'）。
  本 lane 的两笔脚本修复 rebase 在它之上，**rtl/ 与 main 逐字节相同**（`git diff f19ff397 HEAD -- rtl` 为空）；
  构建 pin = `310762f06710edac526842b48e897136a0e69407`（= f19ff397 + 下面 §2 两笔）。
* 首轮在 d5564588 上做过（full/full2/full4），中途机器重启，按协调者要求改钉到当前 main HEAD 重建；
  旧轮次只在 §2 作为"bug 是怎么被发现的"出现，台账数字全部出自 f19ff397 这轮。

## 1. 整芯片能启动，coremark 跑满 20k 窗口

    TAG=f19 PIN=310762f0… JOBS=16 perfre_build.sh     # 脚本同 icperf 的 perfbind2_diag.sh，EXCLUDE 为空 = 所有重写件替入
    # full_elab_filelist: 重写件顶掉 golden 1139 个，清单 2121 项
    # 重绑 SimTop 复核: 6248 条 XMR 全走得通、锥体（含位宽）与 golden 逐行相同
    # VCS -j16 编译 OK；simv +diff=NEMU +workload=coremark-2-iteration.bin +max-cycles=20000 +b=0 +e=1000000
    # sim.log: "The first instruction of core 0 has commited. Difftest enabled." → "EXCEEDED MAX CYCLE: 20000"
    #          （difftest 全程无 abort；golden 同窗口同样是 EXCEEDED MAX CYCLE）
    # assert.log 27921 行，0 条 [ERROR]/断言

| 产物 | sha256 |
|---|---|
| `/home/eda/xs-env/sim-work-perfre/f19/run/cm20k/assert.log`（impl of record） | `0bb94deec40dae726a6748918e0203d626eebb59b056662ef7a11f6feac31c32` |
| `/home/eda/xs-env/sim-work-perfre/f19/run/cm20k/sim.log` | `b2e32ba5c44f4ca2411a9c84da9aac958acf87a272f449e53006c52d5e3fa57a` |
| `/home/eda/xs-env/sim-work-perfre/f19/build/rtl/SimTop.sv`（重绑 SimTop） | `ae200fbf4e2c7cf766e17e4721fb327533d51aaa7ef5492fc5c534bb696a16c9` |
| golden `/home/eda/xs-env/sim-work/perfbind-runs/golden_cm20k/assert.log`（复用，sha 与旧台账头一致） | `6ceb4c0d99a048ad622035f392194dd1212dedff8457a42074e9371ea930ae39` |

golden 日志复用理由：golden RTL（G1-canonical）只读未变，同 workload / 同 +max-cycles / 同 +e，sha 与上一版台账头逐字一致；
另有 `golden_cm20k_seed2`（+ntb_random_seed=987654321）与之**逐字节相同**。

## 2. 起不来 / 测不准的两个探针工具 bug（不是 RTL 问题，已修在本分支）

### 2a. `scripts/hier_reach.py`：`end else begin : lbl` 出入栈顺序反了 → 整芯片构建 XMRE（commit 8ccca0bd）

在 d5564588 上第一次构建 VCS 报 10 条 `Error-[XMRE]`：重绑 SimTop 引用
`memBlock.inner_vsMergeBuffer_{0,1}.u_core.g_freelist_vl.freeCount_freeList.io_validCount`，
但 VSMergeBufferImp（`IS_VSTORE=1`）的 FreeList_1 在 `g_freelist_vs` 分支（rtl/memblock/VLMergeBufferImp.sv:458-480）。
根因：hier_reach 逐行先压 `begin` 再弹 `end`，`end else begin : g_freelist_vs` 一行把刚压的 vs 弹掉、留下 vl。
改为按 token 出现顺序处理。`docs/hier_rebind_map.tsv` 因此修正 16 行（另 15 个 SRAMTemplate 的 rcg：`g_extcg`→`g_cg`，
xs_SRAMTemplate_core.sv:315-317 实际在 g_cg）。`test_hier_map_gate.py` 全过。

### 2b. `scripts/perf_rebind.py`：拆开声明的线复制成 1 位 → ~200 条 B_CONTROL 假差异 + 4707 条假断言（commit 310762f0）

修完 2a 后第一次跑通（d5564588/full2），比对出 208 条 BLOCKING（decode/rename/dispatch 的 in_fire、dataPath RF 读、IQ、LQ…），
外加 4707 次 `ctrlBlock.rat: pdest for $0 should be 0` 断言（golden 0 次）。但 `rob commitUop 12863 == 12863`、
ibuffer full/flush、ftq2icache 全等 —— 机器行为一样，是探针坏了。
golden 里 firtool 对被 bore 的线常写 `wire [2:0] _GEN_116; assign _GEN_116 = _GEN_115;`，perf_rebind 只从 assign 取定义、
位宽记空，适配器里成了 1 位线：`decode in_fire_count` 只剩最低位（in_fire 永远 ≤1/拍）；rat 断言锥里 `[4:0] ldest` 被截成 1 位，
`ldest==0` 假成立。旧复核两处漏：只比 RHS 骨架不比位宽；只扫 `wire xs_pb_` 开头的行（带位宽的行连 XMR 复核都漏）。
修：解析裸声明的位宽；复核加位宽逐条比对（位宽直接从 golden 源码 `wire <dims> 名字` 取，不用生成器自己的解析结果），XMR 复核纳入带位宽行。
负测：新复核对旧 SimTop 报 133 条位宽不符（rc=1）；修后重出 SimTop 全过。`test_perf_rebind_gate.py` 全过；
修后 full4（d5564588）上 208 条 BLOCKING 与 4707 条假断言全部消失。

## 3. 台账重出（顺序：rebind → tier → compare --emit-mismatch，全在 pin 310762f0 的 worktree 上）

    python3 scripts/hier_map.py          # hier_rebind_map：main 自身已过期（新合入的 BranchUnit/HPerfMonitor 等 77 行）
    python3 scripts/perf_rebind.py       # perf_bore_map / perf_bore_unbound
    python3 scripts/perf_tier.py         # perf_tier_ledger / perf_gap_ledger（--check: 25888 行逐字节一致，X_UNRESOLVED=0）
    python3 scripts/perf_compare.py /home/eda/xs-env/sim-work/perfbind-runs/golden_cm20k/assert.log \
        /home/eda/xs-env/sim-work-perfre/f19/run/cm20k/assert.log --all --emit-mismatch docs/perf_mismatch_ledger.tsv
    # MATCH 9950 / MISMATCH 13 / EXCLUDED 15464 / MISSING 0；WAIVED 9 / BLOCKING 4

注意 main 的 perf 表在 f19ff397 本身就已过期（`perf_rebind.py --check` 在 main 上会漂；本 lane 重算后 rc=0）。
绑定率 3988/9897 = 40.3%（T0 1322 / T1 161 / T2 1925 / T2C 580 / T3 3056 / T4 2853）——重写件越多，T3/T4 越多，
EXCLUDED 已到 15464 条：**本结果不得表述为 perf 全等价**，只说明"可测的 9963 条里 4 条必须相等的不等"。

## 4. 原 7 条 BLOCKING 逐条结论

| # | 计数器 | 旧（icperf 日志） | 现在（f19） | 结论 |
|---|---|---|---|---|
| 1 | rob `robHeadPC`（C_DIAG） | +509804448334724334 | EXCLUDED（bore_960 T4_OPEN） | **探针问题 + 读未初始化状态**，见 4a |
| 2-5 | missQueue.entries_0..3 `load_miss_penalty_to_use`（±1） | +1/+1/−1/−1 | EXCLUDED（bore_4598.. T3_REG_LEAF，`should_refill_data_reg` 内部寄存器叶子；MissEntry 已重写） | 现在测不到，不是"消失"；旧 ±1 是在 MissEntry 还是 golden 时测到的 |
| 6 | tage `bank_1_tage_provided_at_pred`（B_CONTROL） | 1244 vs 215 | **仍在**，1244 vs 215；同族新增 bank_0 provided −1029、tage_bank_0_alt_differs +1 | 真差异，见 4b |
| 7 | storeQueue `vaddr_match_failed`（C_DIAG，StoreQueue 已重写） | 24 vs 14 | 24 vs 17 | **读未初始化状态**（seed 敏感），见 4c |

### 4a. robHeadPC 的巨大差值

* golden：`LogPerfEndpoint` 里 `robHeadPCCounter += perfCnt_bore_960` **每拍无条件累加**，bore_960 = golden CtrlBlock 的 `_probe`
  = Rob 输出 `io_commits_info_0_debug_pc`（golden Rob.sv:265198，`robDeqGroup_*_debug_pc` 是无复位寄存器）。
  累加 50 位 PC 2 万拍，golden 1.0856e18 是正常量级。
* icperf 那份日志：CtrlBlock 还是 golden（T0 绑上），Rob 已是重写件 → 读的是重写 Rob 的 debug_pc，其中开机后未写入时的
  头部表项是 initreg 随机值。**实测**：同一个 icperf simv 只改 `+ntb_random_seed=987654321`，robHeadPC 1595410252034041781 →
  3809205396346055371，其余 27919 行逐字节不变（除 vaddr_match_failed）。golden 换 seed 不变（firtool `_RANDOM` 初始化是确定的）。
  所以那个 +5.1e17 是"读到未初始化寄存器"，不是行为差异，也不是计数器坏。
* 现在：CtrlBlock 已重写，`_probe` 这个 firtool 名字（Rob 实例输出端口直接连的线）perf_rebind 解析不了 → T4_OPEN → EXCLUDED，
  impl 侧印 0。要绑可以加"子实例输出端口连线即端口叶子"规则（impl 对应 `inner_ctrlBlock.rob.io_commits_info_0_debug_pc`），
  但绑上也不该判 BLOCKING：值取决于未初始化状态，需先定 initreg 口径（建议把这类"每拍累加无复位数据"的计数器归 D 类或要求 initreg+0 对比）。

### 4b. tage provider 差异（仍在，真差异，B_CONTROL）

* 计数器在 Tage_SC（golden，未重写）内部观测，T0 绑定，数没问题。差异恒为 1029（bank_1 table_3 provided 1037→8，use_bim +1029，
  sc_* 同步 −1029），从 diag2、icperf、d5564588、f19ff397 四版构建完全不变；且与 initreg seed 无关（seed 实验不动）。
* Tage_SC 的输入来自重写的 `TageTable{,_1,_2,_3}` / `TageBTable`（rtl/frontend/）。二分构建（这些回落 golden，其余全重写）结果见 §6。
* 定位方向：Tage_SC 只读 TageTable 的 resp（hit/ctr/u）；FM 签核过的 TageTable 若端口逐拍等价，差异只能来自
  初始状态（SRAM 内容/WrBypass 未写表项）——这类 FM 不覆盖。

### 4c. storeQueue vaddr_match_failed

golden 计数器累加 `vpmaskNotEqual_probe = |((r ^ r_1) & REG & next_r)`（StoreQueue.sv:9990-9992），**不带 valid 门控每拍累加**；
`vpmaskNotEqual_r/_r_1` 是 `RegEnable(forwardMmask, forward.valid)` 无复位。重写件 rtl/memblock/StoreQueue.sv:1610-1626 逐式照抄，
`fwdPaddrMmask_q/fwdVaddrMmask_q` 同样无复位。第一次 forward 之前的值来自 initreg。
**实测 seed 敏感**：f19 simv 只换 `+ntb_random_seed=987654321`，三个 vaddr_match_failed 101/101/17 → 99/41/82；icperf 同样 101/176/14 → 45/168/20。
golden 不随 seed 变。结论：对比的是两边各自的初始垃圾，不是行为差异；RTL 无需改，需在比对口径上处理（initreg+0 对照或归档为 seed 依赖）。

## 5. 另外发现的 seed 依赖（目前 MATCH，但不稳）

f19 换 seed 后 missQueue `utilization/full/exHalf/empty/util_*/num_valids_*/L1DMLP_Total_*` 变了（11532→2658 等），其余计数器全不变。
锥 = `~entries_i.io_primary_ready` 计数；golden MissEntry.sv:327-331 `primary_ready` 在空闲时还看 `io_req_bits_source`，
空闲时这组 req bits 是上游无复位寄存器的初值。默认 seed 下与 golden 恰好相等（11532），换 seed 就不等——
这批 B_CONTROL 的 MATCH 不是稳的证据。

## 6. 闸

    python3 scripts/check_perf_tier.py      # rc=1，唯一红项 E「无 BLOCKING 差异」：4 条（tage ×3 + storeQueue vaddr_match_failed）
                                            # A/B/C/D/E 其余/F 全 ok（原来红的「档位未过期」「verdict 与现算一致」已绿）
    python3 scripts/test_perf_tier_gate.py  # 注入 1..12 全部按预期红；第 0 条「未注入时闸是绿的」红 = 上面那 4 条真实 BLOCKING
    python3 scripts/test_perf_rebind_gate.py / test_hier_map_gate.py   # 全过

## 7. tage 二分（构建 pin 同 310762f0，只把列出的重写件回落 golden；`PREP` 删掉对应 hier_rebind_decl 行）

| 构建 | 回落 golden | bank_0 provided（g=4036） | bank_1 provided（g=1244） | bank_1 table_3 provided（g=1037） | alt_differs（g=617） | assert.log sha256 |
|---|---|---|---|---|---|---|
| f19 | 无 | 3007 | 215 | 8 | 618 | 0bb94dee…（见 §1） |
| f19_notage2 | TageTable{,_1,_2,_3}+TageBTable | 3007 | **1244** | 8 | **617** | ecec7f6d39ac43a7a88cfccd1d2a1991dfb4af31701abc773f33b42eeb0837ef |
| f19_nopred | 上面 + Predictor + Composer | 4036 | 215 | 8 | 618 | 8daa35424a36e70efd86131b76627f445a831e676783ded903a7615f0f6f8ad9 |

结论：**不能定位到 TageTable/TageBTable/Predictor/Composer 中任何一个**——把它们全回落 golden 差异还在，而且各计数器在三版之间
"跳来跳去"（同一个 1029 在 table_0 / table_3 / bim 之间换位置，bank_1 provided 在 notage2 恢复、在 nopred 又坏），
总预测数与 commit 流（rob commitUop 12863=12863）不变。这是"命中哪张表取决于表里原有内容"的特征：TAGE 表项在开机后
未写入前的初值（SRAM/array 内容、WrBypass 表项）参与 tag 比较。剩余嫌疑是这些表下面共用的重写层
（xs_SRAMTemplate_core / FoldedSRAMTemplate / WrBypass 家族）与 golden `*_ext` 的 RANDOMIZE_MEM_INIT 初值口径不同；
该差异对 initreg seed 不敏感（seed 实验不动），说明来源是存储阵列初始化而非寄存器 initreg。
下一步（归 tage/SRAM owner lane）：在 golden 与 impl 两侧各打一次 +vcs+initmem+0（或 define 关 RANDOMIZE_MEM_INIT）再比；
若两侧都 0 初始化后相等，即是初值口径问题而非逻辑问题。

复跑：`PIN=310762f0… TAG=<tag> EXCLUDE="rtl/frontend/…" PREP="sed -i '/^TageTable/d;…' docs/hier_rebind_decl.tsv" JOBS=16 \
 <scratchpad>/perfre/perfre_build.sh`（脚本在 scratchpad/perfre/perfre_build.sh，即 perfbind2_diag.sh + PIN/PREP）。
