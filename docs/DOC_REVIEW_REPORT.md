# 香山 V2R2（昆明湖）设计文档 Review 终报

> 日期：2026-07-01 ｜ 范围：`backend`(55) + `memblock`(47) + `l2`(9) + `uncore`(10) + `common`(7) + 顶层 xscore/xstile/xstop(3) = **131 篇**。
> 前端 34 篇此前两轮已审并已修复，不在本报告内。
> 方法：三轮——
> 1. **第一遍**：逐组核**硬事实**（端口名/方向/位宽、参数、变体、结构计数），覆盖全 131 篇；
> 2. **第二遍深审**：对 6 个大模块**独立重建 RTL 行为**，专挑「遗漏 / 行为性错误」（不数计数）；
> 3. **第三遍深审**：再深审 9 个（6 个第一遍判"全清"的复杂模块 + 3 个黑盒发射队列 vs golden）。

---

## 0. 结论速览

- 文档**主干质量高**：算法 / FSM / 端口语义 / 时序绝大多数与 RTL 逐条吻合，无大面积虚构。
- **深审证实了单遍审查的盲区**：第一遍判"清/质量高"的模块，约一半在深读下冒出**行为层** CRITICAL/MAJOR（NewCSR、DataPath、LoadQueueReplay、Sbuffer、DCache-MainPipe、DCache-MissQueue、IssueQueueLdu）。
- 但深审**有区分度**：Rob、StoreQueue、L2-MainPipe、L2-RequestArb、L2-SubDirectory 深读后**只有 MINOR**，是真干净。
- 问题按性质分四类：① 行为层遗漏/虚构（最要害）② 文档滞后于代码（占位/变体表/总览）③ 跨模块共性遗漏（WFI 门控）④ 自报元数据计数陈旧（量最大、风险最低）。

**假阳性说明**：多个审查 agent 报的 `scripts/`、`verif/`、`golden/`、`docs/frontend`、`docs/backend`、`REWRITE_STYLE.md`"不存在"，均系审查用的本地快照只含部分目录所致，已去远端确认真实存在，**已从本报告剔除**。

---

## 1. 置信度分级（该信多少）

| 级别 | 模块 | 依据 |
|---|---|---|
| **高**（硬事实+行为均深审） | Rob, NewCSR, DataPath, IssueQueueLdu, LoadQueueReplay, Sbuffer, DCache-MainPipe, DCache-MissQueue, StoreQueue, L2-MainPipe, L2-RequestArb, L2-SubDirectory | 第一遍 + 深审 |
| **中**（仅第一遍硬事实） | 执行单元(Alu/Mul/Div/FMA/FCVT…)、发射队列(除 3 黑盒)、TLB/PTW、DCache 阵列、Store 子模块、uncore Xbar、L2 其余、顶层 | 行为简单、风险低，**未深审** |
| **未闭合** | 3 个访存 IQ（Ldu/StaMou/StdMoud）**条目算法层** | golden 叶子未拉，见 §6 |

---

## 2. 【P0】行为层要害——深审挖出、第一遍全漏，**最优先修**

### DataPath.md
- 🔴**CRITICAL 行为错**：文档 §3 把 `og0Cancel / og1Cancel` 并列成对称机制，但 **`og1Cancel` 在 RTL 根本不存在**（全库 grep 无）；只有 `io_og0Cancel_0/2/4/6/8`（`datapath_ports.svh:835-839`）。
- 🔴**CRITICAL 遗漏**：`s0_ldCancel`（load 唤醒取消）整条机制未描述。RTL：`s0_ldCancel = Σ(io_ldCancel_i_ld2Cancel & loadDependency_i[1])`（`datapath_logic.svh:233`），门控 `s1_valid`（:236-237）；输入端口 `io_ldCancel_{0,1,2}_ld2Cancel`（`datapath_ports.svh:840-842`）。文档 §2.3 只裸写符号未解释。
- 🟠**MAJOR 行为错**：§2.4 "每源按 srcType 用 5 路 Mux1H 选真值"——实际绝大多数源**固定直连单域**（`datapath_logic.svh:650-731`），唯一运行时 Mux 是 STD 端口 src0 的 **2 路** `sel_src_intfp`（:729,731）。
- （第一遍已记：§7 `s0_cancel`/`perf` "接0/待重写" **实际已实现**；§2.4 虚构函数 `sel_src_scalar`/`sel_src_vec`（实为 `sel_src_intfp`）；引用不存在文件 `datapath_body.svh`。）

### LoadQueueReplay.md
- 🔴**CRITICAL 行为错**：文档把 `vecFeedback` 列为取消/释放源，但 RTL 里 `vecLdCancel/vecLdCommit` 算出后**从未使用**（`loadqueuereplay_regupd.svh:43-51`）；`allocated` 清零只由 `needCancel`(纯 redirect)（:190-191）；`freeMaskVec` 无 vec 分支（:197-203）。即 vec flush 根本不清队列。
- 🟠**MAJOR**：§7 第 220 行（"redirect/vec 取消→allocated:=0"）与第 234 行（freeMaskVec 公式无 vec）**自相矛盾**。
- 🟠**MAJOR 遗漏**：**入队当拍即可预清 blocking**（C_TM/C_DM 特判）未写（`regupd.svh:126-130`）。
- 🟠**MAJOR 遗漏**：`C_DM & ~handledByMSHR` 的行为（blocking 走默认、missMSHRId 不写）未写（`regupd.svh:129,133`）。

### DCache-MainPipe.md
- 🟠**MAJOR 遗漏**：**LR/SC 保留锁 backoff 窗口 + `block_lr`** 未写。RTL：`lrsc_valid = lrsc_count > LRSC_BACKOFF`（`MainPipe.sv:908`）、`s3_sc_fail`（:911）、`io_block_lr`（:1013-1017）。影响原子同步语义。
- 🟠**MAJOR 遗漏**："refill 未到强制阻 1 拍再 replay" 的两态 FSM `s2_can_go_to_mq_no_data`（`MainPipe.sv:788-796`）未写。
- 🟠**MAJOR 行为错**：§3 状态图 probe 转移误导——带数据判据是 `writeback_data=(s3_tag_match & probe & probe_need_data)||(coh==DIRTY)`（`MainPipe.sv:1028`），且漏 `Trunk--toB-->Branch`（`mainpipe_pkg.sv:185`）。决定 Release vs ReleaseData 的 TL-C opcode。

### NewCSR.md
- 🟠**MAJOR 遗漏**：**critical-error 致命错误状态机**（功能性、有独立输出端口，文档只当 difftest 提一句）。RTL：`criticalErrorStateInCSR = ~mnstatus.NMIE & trap_valid & ~entryDebugMode`（`NewCSR.sv:588-589`）、sticky 锁存（:683-684）、`io_status_criticalErrorState`（:3763）、`io_error_0`（:2161-2162）。
- 🟠**MAJOR 遗漏**：**NMIE 门控 + double-trap(dbltrpToMN) 派发路由**。所有 trapEntry* valid 都 `& NMIE`（`newcsr_inst.svh:5011/5085/5119/5208`）；双重陷入把入口从 M 抢到 M-NMI（:5085）。
- 🟠**MAJOR 遗漏**：**EX_II/EX_VI 何时产生**未写。RTL：`noCSRIllegal`(访问未实现 CSR)（:1336-1337）、`EX_VI`(权限)（:1340）、IMSIC illegal 按 V 态分流 II/VI（:1338/1341）。
- 🟡**MINOR 行为错**：AIA topei "claim" 由**写**触发（`NewCSR.sv:1045-1054`），文档 §7 写"读则发 claim"。
- 🟡**MINOR 行为错**：`csrAccess` = 上拍写合法位 | 上拍读位（`:1436,1451,1496` 均寄存值），文档写侧说成"本拍"。

### Sbuffer.md
- 🟠**MAJOR 行为错**：missqReplay 重发逐出**绕过 `isDcacheReqCandidate` 检查**——`out_s0_valid = missqReplayHasTimeOut | (st_is_dcache_cand & …)`（`Sbuffer.sv:547-549`）；replay entry 恒 `inflight`（:668/674/685），按文档逻辑永远逐不出去。
- 🟠**MAJOR 行为错/遗漏**：`matchInvalid` 是**双向异或** `(vtag_match != ptag_match) & (active|inflight)`（`Sbuffer.sv:845`），文档只讲"vtag 命中而 ptag 失配"单向。

### DCache-MissQueue.md
- 🟠**MAJOR 遗漏**：pipereg 直发 acquire 漏第三个门控——`acquire_from_pipereg_valid = mqpr_alloc & ~pr_merge_by_new_store & ~io_wfi_wfiReq`（`MissQueue.sv:189`），文档只写前两项。

### IssueQueueLdu.md
- 🟠**MAJOR 遗漏**：`og0Cancel / ldCancel / is0Lat` 推测唤醒取消（load 核心机制）全文未解释（`IssueQueueLdu.sv:752-758`；`iq_ldu_pkg.sv:86-88`）。
- 🟡**MINOR**：§3.5（storeSet 字段"从 imm 派生"）↔ §5.2（"恒 0 死寄存器"）**自相矛盾**，未裁决（见 §6）。

---

## 3. 【P1】文档滞后/虚构/总览破链/缺失文档（第一遍发现，仍需修）

- **占位滞后（会误导"功能没做"）**：`LoadUnit.md`（🔴 §2/§5/§6 S2/S3/perf_6 已实现却写"占位/待补"）、`Rename.md §7`（🔴 "B 批占位"已实现）。
- **变体表过时**：`SRAMTemplate.md`（🔴 单口变体 6→**11**；🟠 漏 2p 核、漏 `EXTRA_RESET`/`USE_BITMASK`）、`SplittedSRAMTemplate.md`（🟠 `_23` 误列未就绪）、`FoldedSRAMTemplate.md`（🟠 `_20` 误列未就绪）。
- **总览矛盾/破链**：`MEMBLOCK_OVERVIEW.md`（🟠 漏 FreeList、LoadUnit/StoreUnit 层级错）、`BACKEND_OVERVIEW.md`（🟠 NewDispatch 状态高报 errors=0、`RegFilePart.md` 破链）、`MemBlock.md §4.2`（🟠 stub 71→49）、`XSTile.md`（🟠 `io_l2_flush_en`/`io_power_down_en` 误归 L2Top，实为 XSCore 输出）。
- **文档缺失**：🟠 **`IssueQueueAluCsrFenceDiv.md`**（RTL 有、Int Scheduler 例化，却无文档）。
- **虚构/位宽/行为小错**：`RenameBuffer.md`（preg "低 7 位"实为 8）、`StdFreeList.md`（canAllocate `>` vs `>=`）、`LinkMonitor.md`（`ram_4x115` 不存在）、`ProbeQueue.md`（虚构 `io_mem_probe.source`）、`VSetRvfWvf.md`（vtype_out 7→8）、`PtwCache.md`（L0 tag 24→30）、`loadqueue_pkg.sv`（perf 注释错乱）、`MissQueue.md`（架构图 LoadPipe×2→×3）、`Alu.md`（§1 直通职责错记在核上）、`Bku.md`（包名应 `xs_bku_pkg`）。
- **自报计数/端口/行数陈旧（低风险，量最大，建议脚本批量刷）**：DecodeStage(713/707→986/709)、DecodeUnit(译码表 721/716→717)、UopInfoGen(split 47→44)、FPDecoder(行数 248→315)、NewCSR("28 DelayReg"→2)、Rob(§12 function/for/行数)、Backend(NewPipelineConnectPipe 28→27)、L2TLB(657→675)、AXI4Xbar(localparam 11→12) 等数十处。

---

## 4. 【P2】跨模块共性遗漏：WFI 门控

`io_wfi_wfiReq` 对"发起外部访问/acquire"的门控，在 **DCache-MissQueue**（acquire）、**StoreQueue**（mmio/nc/cmo 请求）等多个模块都存在，但文档普遍未写。它决定 WFI 期间是否仍发外部请求，建议统一补一句。

---

## 5. 深审确认"真干净"（高置信度、只出 MINOR）

- **Rob** —— commit/walk/异常中断优先级/WFI/指针回卷 全对，仅 4 处 MINOR 边角。
- **StoreQueue** —— 三套 FSM/多根指针/force_write 全对，仅 6 处 MINOR。
- **L2-MainPipe / L2-RequestArb / L2-SubDirectory** —— 目录/一致性/仲裁/PLRU 全对，仅少量 MINOR。

---

## 6. 未闭合盲区：3 个访存 IQ 条目算法层

`IssueQueueLdu / StaMou / StdMoud` 的手写重写**只做了顶层连线**，条目算法（replay/推测取消/issueTimer/年龄选择）是 golden。补审时发现：即便拉了 golden `EntriesX.sv`（各 2.9 万行），它**内部又实例化 `EnqEntry_*/OthersEntry_*` golden 叶子**（未拉），真正的状态机在更深一层——**本地无法证真证伪**。
- 悬而未决：Ldu 文档 §3.5↔§5.2 关于 storeSet 字段（有效 vs 死寄存器）的矛盾。
- 闭合方式：再拉 golden `EnqEntry_*/OthersEntry_*`，或直接对照 XiangShan `kunminghu-v2r2` 的 Scala 源。

---

## 7. 各子系统健康度一览

| 子系统 | 篇 | 最高级 | 关键项 |
|---|---|---|---|
| 后端-寄存器堆/DataPath | 4 | 🔴 CRIT | DataPath og1Cancel 虚构 + s0_ldCancel 遗漏 |
| 访存-Load 队列(Replay) | 6 | 🔴 CRIT | vecFeedback 描述了未实现行为 |
| 访存-Load 单元/LSQ | 5 | 🔴 CRIT | LoadUnit 占位滞后 |
| 后端-重命名 | 5 | 🔴 CRIT | Rename §7 占位 |
| common 公共库 | 7 | 🔴 CRIT | SRAM 变体表过时 |
| 后端-ROB/CSR/Fence | 3 | 🟠 MAJOR | NewCSR 3 行为遗漏（Rob 深审真干净） |
| 访存-DCache 核心 | 6 | 🟠 MAJOR | MainPipe LR/SC 等 + MissQueue WFI |
| 访存-Sbuffer(Store) | 6 | 🟠 MAJOR | Sbuffer missqReplay/matchInvalid（StoreQueue 真干净） |
| 后端-发射队列 | 13 | 🟠 MAJOR | Ldu 推测取消遗漏；条目层部分未闭合 |
| 访存-memblock 顶层 | 3 | 🟠 MAJOR | OVERVIEW 漏 FreeList/层级 |
| 后端-派遣/控制/顶层 | 4 | 🟠 MAJOR | OVERVIEW 高报/破链 |
| 后端-浮点 EU/Vset | 6 | 🟠 MAJOR | VSetRvfWvf 位宽 |
| 访存-PTW/L2TLB | 8 | 🟠 MAJOR | PtwCache L0 tag |
| 顶层 xscore/tile/top | 3 | 🟠 MAJOR | XSTile 悬空端口归属 |
| uncore 其它 | 4 | 🟠 MAJOR | LinkMonitor 通道 |
| 后端-译码 | 6 | 🟠 MAJOR | 均为元数据计数 |
| L2 | 9 | 🟡→深审确认干净 | 仅 MINOR |
| 其余(整数EU/TLB/DCache阵列/Xbar/…) | 41 | 🟡 MINOR | 未深审，低风险 |

---

## 8. 修复建议与执行顺序

1. **P0 行为要害**（§2）：DataPath 两 CRITICAL、LoadQueueReplay CRITICAL、DCache-MainPipe(LR/SC 等)、NewCSR(3 遗漏)、Sbuffer(2 行为错)、DCache-MissQueue/IssueQueueLdu。
2. **P1 滞后/虚构/总览/缺失**（§3）：占位滞后（LoadUnit/Rename/DataPath §7）、SRAM 变体表、总览破链、补 `IssueQueueAluCsrFenceDiv.md`。
3. **P2 WFI 门控**（§4）：多模块统一补。
4. **元数据计数**：写脚本按 `wc -l`/`grep -c` 自动重算回填（勿手改，否则再过时）。
5. **闭合盲区**（§6）：拉 golden 叶子或对照 Scala，补审 3 个访存 IQ 条目层。

---

## 附：方法学与盲区说明

- 第一遍"逐组单遍 + 偏硬事实"对端口/位宽/计数很强，但**系统性欠查**跨模块问题、遗漏、大模块深层行为——这正是第二/三遍深审要堵的盲区，且已证实盲区真实存在。
- 深审对**可读手写 RTL** 效果好；对 **golden 扁平/黑盒**（发射队列条目层）效果受限，相关结论标注为"未闭合"。
- 本报告所有 CRITICAL/MAJOR 均带 `文件:行号` 证据，可直接定位。
