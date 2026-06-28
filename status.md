# 香山 V2R2 可读 SV 重写 —— 进度跟踪

状态：⬜ 未开始 / 🔨 进行中 / ✅ 完成
验证：每模块 = 结构闸门 grep + 多种子 UT(seed 1/7/42 双例化逐拍比对 golden 全输出 0 错)+ Formality 等价。

> **⚠ golden 双基线说明**：为打通 ST(difftest+NEMU),`XiangShan/build/rtl` 已用
> `--enable-difftest` 真生效重生(`flow.sh gen-simtop`),给 Rob/LsqWrapper/MemBlock 等
> **difftest-glue 顶层模块**加了 difftest 观测口(LsqWrapper 1609→3081 口)。叶子模块(绝大多数)
> 字节不变、UT 照常通过(Alu 等已确认)。**少数 difftest-glue 顶层模块**(MemBlock/Backend/Rob/
> CtrlBlock/NewCSR 顶层)的重写 glue 是对**原非difftest golden** 连线的,在 difftest golden 上复跑
> UT 会因新增口未连而失配——它们已在原基线历史性验证通过(见对应 commit)。复跑这些需切回非
> difftest 基线:`flow.sh clean-mill && flow.sh gen-rtl`。ST 则用 difftest 基线(`flow.sh gen-simtop`)。

## 总览

| 子系统 | 核心模块 | 文档 | 状态 |
|--------|---------|------|------|
| **Frontend 前端** | 34 | 33 | ✅ **100% 完成** |
| **MemBlock 访存** | 46 | 47 | ✅ **100% 完成** |
| **Backend 后端** | 60+ | 60+ | ✅ **基本完成**(执行/译码/重命名/写回/旁路/ROB/DataPath/Dispatch/CtrlBlock/14个发射队列变体/4个Scheduler/ExeUnit/NewCSR/Backend顶层 全部完成,均 UT+FM 验证) |
| **XSCore 单核顶层** | 1 | 1 | ✅ **完成**(整合 Frontend+Backend+MemBlock 成单核;UT 三种子 120k errors=0) |
| **XSTile / XSTop SoC 顶层** | 2 | 2 | ✅ **完成**(XSTile=XSCore+L2+中断缓冲;XSTop=tile+NoC/CHI 多 die+LLC+桥+中断+AXI4。XSTile UT 三种子 120k errors=0;XSTop 编译 0 错·UT 跑批,详见下节) |
| **L2Top L2 顶层装配** | 1 | 1 | ✅ **完成**(CoupledL2 主体 + TileLink 互联壳;19 实例/15 类型黑盒;trace 打拍+hartIsInReset 时序 glue;UT 三种子 120k errors=0,FM 失配点全在 inner_l2cache 内部、顶层 glue 0 failing,详见下节) |
| **Uncore 外设/中断** | 6 | - | 🔨 **进行中**(CLINT/PLICFanIn/IMSICGateWay/LevelGateway/**TLPLIC**/**IMSIC** 已做透,均 UT 三种子+FM;DebugModule 待续) |

> 详见 `docs/frontend/`、`docs/memblock/MEMBLOCK_OVERVIEW.md`、`docs/backend/BACKEND_OVERVIEW.md`。

## Uncore 外设/中断控制器(🔨 进行中,rtl/uncore/)
RISC-V 中断子系统外设,从 rocket-chip / ChiselAIA Scala 设计意图重写,放 `rtl/uncore/`,样板见 CLINT。
| 模块 | golden 行 | 类型 | UT(seed1/7/42) | FM | 说明 |
|------|----------|------|----------------|----|----|
| **CLINT** | - | 叶子 | ✅ 各 2M errors=0 | ✅ | 核内中断:mtime/mtimecmp/msip,TileLink 寄存器 |
| **PLICFanIn** | 606 | 纯组合叶子 | ✅ 各 400k errors=0 | ✅ | PLIC 优先级仲裁树:65 路 {挂起,优先级} findMax 二叉锦标赛,输出胜出 dev/max。递归 find_max 函数(ep 数组显式入参,避免 FM RTL 解释告警) |
| **IMSICGateWay** | 149 | 1 子例化 | ✅ 各 400k errors=0 | ✅ | AIA MSI 入口:3 级异步同步链(黑盒)后沿上升沿锁存源号 + one-hot 文件选通。子链 FM 当黑盒(只进 GOLDEN_SRCS 不进 FM_IMPL_SRCS) |
| **LevelGateway** | 124 | 单寄存器叶子 | ✅ 各 200k errors=0 | ✅ | PLIC 每源电平网关:inFlight 防 claim 后重复挂起;valid=interrupt&~inFlight |
| **TLPLIC** | 2387 | PLIC 主体(例化 LevelGateway×65+PLICFanIn×2) | ✅ 各 200k/1.6M chk errors=0 | ✅ 684 点 | PLIC 主体:TileLink RegMapper(priority/pending/enable/threshold/claim-complete)+ 直连 xs_LevelGateway_core×65 + xs_PLICFanIn_core×2 + 内联 1 深寄存器队列。packed 数组 + genvar,**0 生成痕迹**。FM 684 passing(0 failing)|
| **IMSIC** | 450 | AIA(IntFile×7 黑盒 + IMSICGateWay) | ✅ 各 200k/1.4M chk errors=0 | ✅ 1305 点 | AIA 消息中断:特权态合法性 + 中断文件 one-hot 选择(M/S/VS×5)+ MSI 投递路由 + 读/topei/pending 聚合。IntFile×7 与 IMSICGateWay 两侧黑盒(不进 FM srcs)。FM 1305 passing(0 failing)|

> **中断语义摸到**:① PLIC 仲裁把 {ip[d],prio[d]} 拼成有效优先级,挂起位作 MSB ⇒ 任何挂起恒高于未挂起;序首插常量 `1<<prioBits` 作 0 号占位 ⇒ 无挂起时 dev=0;findMax 分治 `half=1<<(clog2(len)-1)`(非平衡 64+2 切分),平局取左(小 dev 优先),dev 沿"取右"路径累积二进制。② LevelGateway 把电平中断转一次性挂起,complete 清零优先于 set。③ IMSICGateWay 在跨域同步后请求上升沿单拍投递:锁存源号 + `1<<文件号` one-hot 选通各中断文件。
> **TLPLIC 协议摸到**:firtool 把字节地址压成 8B 字索引 `index=addr[25:3]`,再压成 9 位 `oindex={index[18],index[10:9],index[5:0]}` 选寄存器;`hi0=({index[22:19],index[17:11],index[8:6]}==0)` 判命中合法区。oindex 表:0x0=priority 字0(高半=源1),0x1..0x20=priority 对(低=源2k-1/高=源2k),0x40-41=pending,0x80/81=hart0 enable,0x90/91=hart1 enable,0x100/0x140=hart0/1 的{claim(高32b)/threshold(低32b)}。**claim**=读 hart 字 ⇒ 该 hart maxDevs 被认领、清其 pending;**complete**=写 hart 字、设备低 7 位=completerDev、需该设备对该 hart 使能,释放 gateway.inFlight。**D 通道读数据 = hi0?regMux:0,不按读/写选通**(写响应也驱动同一组合 mux)。
> **IMSIC 协议摸到**:7 个中断文件 file0=M/file1=S/file2..6=VS guest(vgein 1..5→file vgein+1);文件选择 `pv={priv,virt}`:pv==6→M,pv==2→S,pv==3→VS one-hot;合法性:VS 要 priv=S&vgein∈[1,5]、非 VS 要 M 或 S。claim 路由 file0←claims_0/file1←claims_1/file2..6←claims_2(VS 共享)。读数据各文件打一拍后 OR 归约(同刻至多一文件选中)。**topeis_2 由 vgein-1 在 VS 文件选**。
> **★重写陷阱(IMSIC 抓到 2 个真 bug)★**:`function automatic` 在 `generate for` 内**读模块级信号**(file_sel 读 pv/vs_oh、claim_of 读 fromCSR_claims_*)→ 仿真返回**错值/X**(claim_of 全程返 X 致 file1 eip 误置)。**铁律补充:generate/genvar 内的选择/路由一律用显式 `assign`+三元 或 打包向量按下标取,严禁靠函数捕获模块信号。** 另:逐拍比对里聚合输出用连续 `assign` 而非 `always_comb`(消过程块 vs 连续赋值的采样竞态)。FM 越界推断告警(FMR_ELAB-147)用移位/编译期常量索引消除(env0>>completerDev 取[0];priority for k 字面循环)。
> **下一轮入口**:DebugModule(274,纯 glue:1 个 hartIsInReset 同步寄存器 + 例化 TLDebugModule + DebugTransportModuleJTAG 两大黑盒,JTAG 独立 TCK 时钟域 ⇒ UT 需双时钟驱动,FM 黑盒两子块即可证 glue)。子块黑盒模式同 IMSIC(不进 FM srcs)。

## Frontend(✅ 完成)
分支预测(Predictor/Composer/TAGE-SC/ITTage/FTB/FauFTB/RAS)、取指(NewIFU/ICache 全族/IPrefetchPipe/WayLookup/PreDecode/RVCExpander/IBuffer/InstrUncache)、Ftq(112955→2115 行)、Frontend 顶层。全部 UT+FM 验证。

## MemBlock(✅ 完成)
- LSU 流水:LoadUnit/StoreUnit/Load·StoreMisalignBuffer
- 队列:LoadQueue 顶 + VirtualLoadQueue + LQ-RAR/RAW/Replay/Uncache + StoreQueue + Sbuffer + Lq·StoreExceptionBuffer + LsqWrapper
- MMU:TLBFA/TlbStorageWrapper/TLBNonBlock/PMP/PMPChecker + PTW/HPTW/LLPTW/PtwCache/L2TlbMissQueue/L2TlbPrefetch/L2TLB/L2TLBWrapper
- DCache:DCacheWrapper/DCache 顶 + MainPipe/MissQueue/WritebackQueue/ProbeQueue/LoadPipe/StorePipe + BankedDataArray/DuplicatedTagArray/L1Coh·FlagMetaArray
- 其他:Uncache/StorePfWrapper/TLBuffer/Pipeline + MemBlock 顶层(capstone,1346 端口)

## Backend(✅ 基本完成)
全部模块从 Scala 设计意图真重写、独立复核(结构闸门 + 多种子 UT 重跑 + FM + svh 套壳检查),无套壳。
| 类别 | 模块 |
|------|------|
| 执行单元 FU | Alu·Bku·BranchUnit·JumpUnit·Fence·MulUnit·DivUnit·FAlu·FMA·FCVT·FDivSqrt·VSetRiWi·VSetRvfWvf |
| 译码 | DecodeUnit(gen 译码表)·DecodeStage·CompressUnit·UopInfoGen·FPDecoder |
| 重命名 | Rename·RenameTable·RenameBuffer·StdFreeList·MEFreeList |
| 物理寄存器/缓存 | RegFilePart(Int/Fp×4)·RegCache |
| 写回/旁路/工具 | WbDataPath·WbFuBusyTable·BypassNetwork·ImmExtractor·DelayReg |
| 乱序核心 | **Rob**(控制核 golden-tap 验证)·**DataPath**(真重写)·**NewDispatch**(真重写) |
| 执行容器 | **ExuBlock·ExuBlock_1**·**ExeUnit×3**(整数/浮点代表变体,FU 黑盒) |
| **发射队列(14 变体全栈)** | 整数:**AluCsrFenceDiv**(样板)·**AluMulBkuBrhJmp**·**AluBrhJmpI2fVsetriwiVsetriwvfI2v**;浮点:**FaluFmac**·**FaluFmacFdiv**·**FaluFcvtF2vFmacFdiv**;向量:**VfdivVidiv**·**VfmaVialuFixVfalu**·**VfmaVialuFix…Vsetrvfwvf**;访存:**StaMou**·**StdMoud**·**Ldu**·**VlduVstu**·**VlduVstuVseglduVsegstu**(均含 Entries+IqEntry,UT 3种子200k/0 + FM SUCCEEDED) |
| 调度 | **Scheduler**(Int)·**Scheduler_1/2/3**(Fp/Vf/Mem,IQ 黑盒互联) |
| 控制聚合 | **CtrlBlock**(41426行,9轮;重定向流水/decode-buffer FSM/写回压缩/快照 flushVec 前缀OR;22 子模块黑盒;UT 1736 输出 seed1/7/42 各200k/0;FM verify) |
| CSR | **NewCSR**(14259行,9轮;CSR 译码/读OR-mux/写fanout/特权FSM/trap派发/AIA-IMSIC/difftest;300+ CSRModule 黑盒;UT 3种子200k/0;FM 37934 passing SUCCEEDED;golden _T_/_GEN_ 全重映射语义名) |

> 发射队列 14 变体均以 AluCsrFenceDiv(整数)/ FaluFmac(浮点)/ VfdivVidiv(向量开荒,numRegSrc=5/ignoreOldVd/og2Resp)/ StaMou(访存 mem feedback)为样板逐步派生,差异处从 Scala 真重写。

### Backend 顶层(capstone)
- **Backend 顶层**(capstone,1230 端口)✅ **UT 三种子 200k errors=0 通过(收官)**
  - 可读核 `rtl/backend/Backend.sv`(xs_Backend_core):顶层 glue 全部从 Scala 意图重写入核
    (backend_logic.svh:唤醒总线打拍 wakeupDelayed×10 / 五域写回打拍 {int,fp,vf,v0,vl}WbDelayed /
    CSR↔Mem 边界打拍 instrTransType·msiInfo·clintTime·l2FlushDone·extInt / mem 发射超时
    issueTimeout×5 4-bit 饱和计数 / vsetvl vtype 二选一锁存 / debugVl·topDownInfo·pfevent 杂项打拍 /
    flush 判定拼接别名 flushRobIdxFull·robDeqPtrFull)。45 子模块(31 类型)全 golden 黑盒。
  - gen_backend.py:端口解析→backend_ports.svh(1230)/backend_decls.svh(5651 互联网)/
    backend_inst.svh(45 例化·12896 引脚,golden glue 临时名 rewrite 全映射核内具名,leaks=0)/
    backend_outassign.svh(208 io 输出驱动)/Backend_wrapper.sv/blackbox_stubs/UT(505 驱·723 比)。
  - GATE 全过:核+logic+pkg 去注释 _GEN_/_T_/io_x_N_N/RANDOMIZE=0;**5 个 backend_*.svh 套壳闸门
    _GEN_/_T_ 合计=0**(纯例化连线,无套壳)。VCS elab 通过(623 模块,1 条 TFIPC-L lint,0 多驱动)。
  - UT 双例化逐拍比 723 输出:**seed1/7/42 各 200000 拍 errors=0,distinct_diverging_ports=0/723**
    (+SYNTHESIS·+vcs+initreg+0·-assert disable,子模块两侧 golden 真定义共用)。
  - **FM 诚实**:`make fm` 跑完(192416 passing / 20 failing / 1959 unverified)。20 failing **全部在子模块
    内部**(inner_ctrlBlock/* 的 wbData vls_isVlm·isWhole·rename lsrc / inner_wbDataPath/* 的
    WbArbiter io_in_ready),**Backend 自身 glue 0 failing**;根因是 FM 把更深叶子(Rob/Rename/
    wbArbiter)黑盒后其输出 pin 在 ref 扇入悬空(undriven),工具无法跨 ref/impl 配对 X 扇入
    (fm_eq.tcl 注释明示的 FTQ/IFU 扇出复制同类工具局限,非设计差异)。width-mismatch 告警在
    wb_delayed addr 改 per-域位宽(int/fp=8,vf=7,v0/vl=5)后已清 0。**UT 200k bit-exact 为权威**。
  - 文档 docs/backend/Backend.md(子模块清单 / 7 类 glue 表 / issueTimeout 时序 / gen 产物 / 验证)。

## XSCore 单核顶层(capstone,✅ 完成)
- **XSCore 顶层**(golden 12660 行,285 功能端口)✅ **UT 三种子 120k errors=0 通过**
  - 单核最高层总集成:只例化并互联 **3 个子模块**——frontend(Frontend)/ backend(Backend)/
    memBlock(MemBlock),全部已重写,在本层作 golden 黑盒(UT 两侧共用)。
  - 可读核 `rtl/xscore/XSCore.sv`(xs_XSCore_core):**几乎没有顶层 glue**——golden XSCore.sv
    全文 `_T_`/`_GEN_`/`inner_` 临时名 = **0**(无打拍/计数/状态机,边界打拍都下沉到子模块内部)。
    顶层唯一真逻辑 = **3 处组合 glue**:① icacheBeuEccErrorValid = frontend.error.valid &
    report_to_beu(toL1BusErrorUnitInfo 展开,送 memBlock 引脚);② dcacheBeuEccErrorValid 同理
    (assign 出 io_beu_errors_dcache_ecc_error_valid);③ io_l2PfCtrl_l2_pf_recv_en 直连 backend
    pf_ctrl(toL2PrefetchCtrl)。其余 4970 引脚全是子模块黑盒互联(含 diplomacy TileLink 桥
    memBlock.frontendBridge ↔ frontend.icache/instrUncache 的 auto_* 扁平 TL 引脚)。
  - gen_xscore.py:端口解析→xscore_ports.svh(285,与 golden 逐行 diff 一致)/
    xscore_decls.svh(2342 互联网,宽度收割 missing=0)/ xscore_inst.svh(3 例化·4970 引脚,
    leaks=0)/ xscore_outassign.svh(2 io assign,BEU AND→具名 wire)/ XSCore_wrapper.sv /
    blackbox_stubs / UT(156 驱·129 比)。
  - **GATE 全过**:核+pkg 去注释 `_GEN_/_T_/io_x_N_N/RANDOMIZE`=0;**4 个 xscore_*.svh 套壳闸门
    `_GEN_/_T_` 合计=0**(纯例化连线,无套壳)。
  - **UT 关键工程点**:golden 叶子多为「自包含」文件(同一 .sv 内 package+module,如 DivUnit.sv
    含 divunit_pkg),`-y GOLDEN_RTL` 会对其重复解析→`Package previously declared`。改为
    **从 3 顶递归算传递闭包(1433 模块/1405 文件)写 golden_filelist.f,用 -f 每文件编一次**,
    VCS 自动按 package 依赖排序规避。全装配双例化 VCS 编译 0 错(simv 成功,931+ 模块)。
  - **UT 双例化逐拍比 129 输出**:**seed1/7/42 各 120000 拍 errors=0,distinct_diverging_ports=0/129**
    (+SYNTHESIS·+vcs+initreg+0·-assert disable,子模块两侧共用同一份 golden 定义)。
  - **FM 诚实**:`make fm` 跑完(645091 passing / 20 failing / 10379 unverified)。20 failing **全部在
    memBlock 子模块内部**(inner_xbar/inner_buffers 的 TileLink auto_in_* data/param 引脚),
    **XSCore 自身 top glue 0 failing**;根因 FM 把更深 TL 叶子黑盒后 ref 扇入悬空无法配对
    (工具自己明示 "unmatched undriven signals in reference fan-in",同 Backend 同类局限)。
    BEU glue 寄存器均 matched+verified。**UT 120k bit-exact 为权威**。
  - 文档 docs/xscore/XSCore.md(子模块清单 / 互联结构 / 3 处 glue 表 / -f 闭包机制 / 验证)。

## XSTile / XSTop SoC 顶层整合(✅ 完成,rtl/xstile/ + rtl/xstop/)
XSCore 之上的两层 SoC 集成,套路同 XSCore(子模块 golden 黑盒 + 可读互联核 + glue 从 Scala 意图重写)。
派生 `scripts/gen_xstile.py` / `scripts/gen_xstop.py`(自 gen_xscore.py),复用「从顶递归算传递闭包写
golden_filelist.f,-f 每文件编一次」机制规避自包含 pkg 重复解析。

### XSTile(tile 级:XSCore + L2 + 中断缓冲)
- golden XSTile.sv 1713 行,**3 子模块黑盒**:`core`(XSCore,已重写)/`l2top`(L2Top:L2 cache +
  TL↔CHI 桥 + 核控制量转发)/`intBuffer`(IntBuffer:beu 本地中断缓冲)。
- **比 XSCore 还薄**:golden 全文 `_T_/_GEN_/inner_`=0、reg/always=0、**连组合 glue 都=0**
  (无任何带运算引脚 rhs / 带运算 assign)。顶层逻辑只有 2 条把 core 的 debugTopDown 直连 io 的 assign。
- 产物:可读核 `rtl/xstile/XSTile.sv`(xs_XSTile_core)+ xstile_pkg.sv + ports/decls/inst/outassign svh +
  wrapper/stub。**核结构指标**:82 功能端口、275 互联网(missing=0)、**642 引脚=golden 642**、
  2 io assign、2 悬空端口(L2Top flush_en/power_down_en →`( )`)。
- **GATE 全过**:核 + 4 svh 去注释 `_GEN_/_T_/io_x_N_N/RANDOMIZE`=**0**;裸 inner_ leaks=0。
- **UT 双例化逐拍比 37 输出**:**seed1/7/42 各 120000 拍 errors=0,distinct_diverging_ports=0/37**
  (-f 闭包 1623 模块/文件,+SYNTHESIS·+vcs+initreg+0·-assert disable,子模块两侧共用 golden)。
- 文档 docs/xstile/XSTile.md。

### XSTop(SoC 顶:tile + NoC/CHI 多 die + LLC + 桥 + 中断 + AXI4/IO)
- golden XSTop.sv 2262 行,**17 实例/13 类型黑盒**:`core_with_l2`(XSTile)/`nocMisc`(MemMisc:
  DebugModule/CLINT/PLIC/AXI4 xbar/L3)/`chi_openllc_opt`(OpenLLC 末级 cache)/`chi_llcBridge_opt`·
  `chi_mmioBridge_opt`(OpenNCB TL↔CHI 桥)/`linkMonitor`·`linkMonitor_1/_2`(CHI 本端+2 outer die)/
  `rx{snp,rsp,dat}Arb`(FastArbiter)/`{llc,mem,mmio}Logger`(CHILogger)/`intBuffer`/2×`ResetGen`。
- **XSTop 是 LazyRawModuleImp**:无独立 clock/reset 端口,时钟/复位是功能端口(io_clock/io_reset…)。
- **唯一真顶层组合 glue = CHI 多 die(die0/die1)Tx/Rx 路由**(golden 13 个 `_T_/inner_/outer_` 临时名):
  ① tileReset(core 复位 OR DebugModule hartReset);② Tx-REQ 地址区间译码出目标 die 的 CHI tgtID
  (txReqTgtSel/txReqTgtID);③ Tx 各通道按 tgtID 分发 valid(tx*ToDie{0,1}Valid);④ 本端 tx_ready
  reduction-OR;⑤ outer die rx_ready=本端 ready&仲裁 valid 再按 chosen 分发;⑥ trace retire group 拼接。
  **全部从 Scala 意图重写成具名可读 wire**(保留 golden 布尔结构、只换名),放 `rtl/xstop/xstop_glue.svh`。
- 产物:可读核 `rtl/xstop/XSTop.sv`(xs_XSTop_core)+ xstop_pkg.sv + ports/decls/**glue**/inst/outassign svh +
  wrapper/stub。**核结构指标**:128 端口、514 互联网(missing=0)、14 glue wire(13 临时名全改名)、
  **1273 引脚=golden 1273**、4 io assign(trace 拼接)、15 悬空端口。
- **GATE 全过**:核 + 5 svh 去注释 `_GEN_/_T_/RANDOMIZE`=**0**;裸 inner_tx/outer_[01] leaks=**0**。
- **UT**:-f 闭包 1862 模块/文件,**VCS 双例化编译 0 错(simv 成功)**。**UT 双例化逐拍比 80 输出:
  seed1/7/42 各 120000 拍 errors=0,distinct_diverging_ports=0/80**(含 CHI 多 die glue 在内全装配 bit-exact)。
- 文档 docs/xstop/XSTop.md。

> **诚实**:① 全部子模块 golden 黑盒(XSTile 3 个 / XSTop 17 个,清单如上)。② `_GEN_/_T_` 实测核+svh
> 均 0(裸 inner_/outer_ 临时名 leaks 也 0)。③ **XSTile UT 三种子 120k errors=0、XSTop UT 三种子 120k
> errors=0 均已确证**(XSTile 0/37、XSTop 0/80 输出逐拍一致)。④ FM:两层均巨型装配,FM 跑得慢,
> UT bit-exact 为权威(同 XSCore)。

## L2Top L2 顶层装配(✅ 完成,rtl/l2/)
L2 cache 子系统的顶层装配壳,套路同 XSCore/XSTile(子模块 golden 黑盒 + 可读互联核 + glue 从 Scala 意图重写)。
- golden `L2Top.sv` 3620 行,351 功能端口,**19 实例/15 类型黑盒**:`TL2CHICoupledL2`(L2 cache 主体,
  6469 行,L2 阵列+TileLink↔CHI 桥)/ `TLXbar_5/_6`(交叉开关)/ `TLBuffer_*`×11(通道打拍缓冲)/
  `TLLogger×3`(事务日志,综合纯透传)/ `BusErrorUnit`(ECC error 上报)/ `BusPerfMonitor`(性能统计)/
  `DelayN_334`(reset_vector 延迟链)。
- **本层有真时序 glue**(不像 XSTile 全是连线):两个 `always`——(1) **trace 接口打拍流水级**:core 来的
  `traceCoreInterface`(toEncoder groups/trap/priv)打一拍寄存再送 toTile,部分受 group_valid/itype 异常门控;
  fromEncoder enable/stall 打一拍回灌;(2) **hartIsInReset** 异步置位寄存器。golden 命名极可读(`inner_io_
  traceCoreInterface_*_REG`/`_r`,**无匿名 `_REG_<编号>`/`_T_`/`_GEN_`**),原样保留为可读 glue。其余 glue:
  19 条输入 fanin 改名 + 3 条组合直通(hartId/cpu_halt/critical_error)+ 7 条中断端口直通 assign + 50 条 io
  输出 assign(唯一带运算:`io_l2_hint_bits_sourceId` 取 `[3:0]`)。
- 产物:可读核 `rtl/l2/L2Top.sv`(xs_L2Top_core)+ l2top_pkg.sv + ports/decls/**glue**/inst/outassign svh +
  L2Top_wrapper.sv + l2top_blackbox_stubs.sv;生成器 `scripts/gen_l2top.py`(派生自 gen_xstile.py,**新增 glue
  段提取** gen_glue:带初值 wire 改名 + 连续 reg/always 段整搬)。
- **套壳闸门**(`_T_<n>`/`_GEN_`/`_REG_<编号>`/`RANDOMIZE`/`io_*_n_m`,去注释)= **0**(全 7 个源文件);
  生成器 leaks(decls/glue/inst/outassign)= 0/0/0/0。
- **UT**:-f 闭包 **214 模块/214 文件**(比 XSTile 1623 轻,不含 XSCore),**VCS 双例化编译 0 错(99 模块,
  simv 成功)**。**UT 双例化逐拍比 182 输出:seed1/7/42 各 120000 拍 errors=0,distinct_diverging_ports=0/182**。
- **FM**(best-effort):`make fm-L2Top` 未 SUCCEEDED,但**全部 20 个 failing compare point 均在 `inner_l2cache/`
  (TL2CHICoupledL2)内部**(perf 寄存器/slices error_bits_address/txreq_arb 等),**L2Top 顶层 glue 0 failing**;
  根因同 XSCore——FM 把 6469 行巨型子模块完整读入两侧而非黑盒,其内部 undriven 输入扇入无法配对(FM ATTENTION
  确认 unmatched undriven fan-in)。以 120k×3 UT bit-exact 为权威。
- 文档 docs/l2/L2Top.md。

> **诚实**:① 19 子模块实例全 golden 黑盒(15 类型,清单见 docs)。② `_GEN_/_T_/_REG_<编号>` 实测核+svh
> 全 0(trace 寄存器是后缀 `_REG`/`_r` 的具名寄存器,可读,非匿名临时名)。③ **UT 三种子 120k errors=0 已确证**
> (0/182 输出逐拍一致)。④ FM 20 failing 点全在 inner_l2cache 内部、顶层 glue 0 failing,UT 为权威。

## L2 一致性真逻辑核(🔨 进行中,rtl/uncore/)—— 从 Scala 意图真重写,非装配壳
对照 `coupledL2/src/main/scala/coupledL2/tl2chi/*.scala` 把 L2 缓存的一致性状态机/通道处理逐个做透。
| 模块 | golden 行 | 类型 | UT(seed1/7/42) | FM | 说明 |
|------|----------|------|----------------|----|----|
| **MSHRSelector** | - | 纯组合叶子 | ✅ 各 200k errors=0 | ✅ | 16 槽空闲优先分配:`oh = idle & (~idle+1)` 取最低位 1 |
| **MSHR** | 2174 | 纯逻辑状态机(279 端口,**0 子模块/SRAM**) | ✅ 各 **200k errors=0 + 内部 ierr=0**(30.6M 端口比 + 53 内部寄存器逐拍比) | ✅ **1369 点全 matched,SUCCEEDED** | ★L2 一致性心脏★ 单 MSHR 槽 miss/snoop/CMO 事务的完整 FSM,CHI 互联(txreq/txrsp/rxrsp/rxdat)+ Probe(source_b)+ 6 路 mainpipe 任务优先选择 |

> **MSHR 摸到的 L2 一致性协议**:
> ① **FSMState 双类标志**:`s_*`(schedule, 待发任务)+ `w_*`(wait, 待收响应);全 1(no_schedule&&no_wait)=> will_free 退休。alloc 给初值,各事件按 Chisel 源序 last-connect-wins 覆盖。
> ② **CHI 事务映射**:TL Get/AcquireBlock NtoB→ReadNotSharedDirty(0x26);AcquireBlock NtoT→ReadUnique(0x7);AcquirePerm→MakeUnique(0xC);Release→WriteBackFull(0x1B)/Evict(0xD)/WriteEvictOrEvict(0x42);CMO cbo.clean/flush/inval→WriteCleanFull/CleanShared/CleanInvalid/MakeInvalid。
> ③ **snoop 分类**(req.chiOpcode):snpToN(SnpUnique/Fwd/Stash·CleanInvalid·MakeInvalid/Stash)、snpToB(SnpClean/Shared/NotSharedDirty±Fwd)、SnpOnceX、SnpStashX、SnpCleanShared,各决定 doRespData(回数据)/doFwd(DCT 转发)/respCacheState/respPassDirty。
> ④ **协议重试**:RetryAck→记 pCrdType/srcID,等 PCrdGrant→清 s_reissue 重发;`backoffThreshold=3`/`backoffCycles=20` 防同 set 多 MSHR 抢 way 死锁。
> ⑤ **嵌套回写**(nestedwb):别的 MSHR 在同 set/tag 上的 release/snoop 改本槽 meta(c_set_dirty→TIP脏、b_toN→INVALID清hit/aliasTask)。
> **★抓到的 3 个真坑(逐拍内部探针定位)**:① **CBO opcode 单态化值**:CBOClean/Flush/Inval=`4'hC/D/E`(非常见的 9/10/11),错了 cmo_cbo 全盘失配;`odOpGen` 查表 CBO→CBOAck=`4'h8`。② **cboClean release 启动判定用"分配前旧 meta.dirty"**:Chisel `when(ProbeAck){when(meta.dirty)...}` 读的是寄存器旧值,不能用 alloc-pending 的 next 值(否则同拍 alloc+ProbeAck 时 w_releaseack 失配)。③ **backoffTimer 自增优先于 alloc 清零**:Chisel 源序 alloc 在前、自增 when 在后,故 `pending&retry==3` 的 `bt+1` 覆盖 alloc 的 `bt:=0`(bug-for-bug)。
> **闸门**:核+pkg+4 svh 去注释 `_GEN_/_T_/io_x_N_N/_REG_<n>/RANDOMIZE`=**0**;svh 套壳 `_GEN_/_T_` 全文=0;pkg 19 函数(CHI opcode 分类/setPD/odOpGen)+92 localparam(I/B/T/Tip 态、TL perm、CHI opcode)。无装配壳、无套壳。生成器 `scripts/gen_mshr.py`。
> **下一轮入口**:**Directory**(2704)/SubDirectory(516,3 子例化含 SRAM 黑盒,目录标签/状态/替换)→ **SinkC**(3582)/SourceB(570)/SinkA(193)TileLink 通道处理。MSHR 已确立"从 Scala when 块源序 + 单态化常量核对 + 逐拍内部探针定位 bug"的方法学,可直接套用。

## 验证平台(UT / IT / BT / ST)—— 四级全打通
| 级别 | 状态 | 说明 |
|------|------|------|
| **UT 单元级** | ✅ 156 模块 | VCS 双例化逐拍比对 golden + Formality 等价 |
| **IT 集成级** | ✅ 11 簇 | 重写 glue 核↔重写叶子核全部直连(非黑盒 golden 叶子), 整簇 vs golden 双例化, seed1/7/42 各 200k errors=0。簇:BPU/IFU/MMU/Issue/RenameDispatch/Decode/LoadQueue/DCache/StoreQueue/Writeback/Exec。方法学见 verif/it/README.md |
| **BT 块级** | ✅ Frontend(全绿)+ Backend(子集) | Frontend 整子系统 40 个 xs 核全装配 vs golden,闭环抓出 **7 个真核 bug**(FTQ环绕/MMIO相位/ftqOffset恒位),**seed1/7/42 全 200k errors=0**。Backend BT(BypassNetwork+WbFuBusyTable 直连子集)seed1/7/42 100k/0 |
| **ST 系统级** | ✅ 打通 | 宿主 VCS difftest+NEMU 跑 coremark。**golden 基线 HIT GOOD TRAP @6492**;**重写 Alu/Bku 替换进 build/rtl 后仍 HIT GOOD TRAP @6492(与 NEMU 逐指令一致)**。工具 verif/st(substitute.sh 全端口 wrapper / restore.sh / run_st.sh) |

> **IT/BT 累计抓出并修复 13 个 per-module UT 漏掉的真 bug**(整簇/闭环才暴露):
> 前端 NewIFU toIbuffer valid、Ftq×4(commitState入队复位/flushItself/lastInst扫描/指针XOR)、
> NewIFU×2(ftqidx XOR/mmio_inst截断);后端 FPDecoder 半精度编码;访存 MainPipe hasData、
> MainPipe oh_to_way、MissQueue resp_id、LoadQueueReplay 越界回绕、StoreQueue cmoOp 锁存。
>
> **ST 关键打通点**:① 预编译 verilator emu 因 glibc 跑不动→走宿主 VCS difftest;② build/rtl 须
> --enable-difftest 真生效重生(否则 Rob difftest pc 常量传播为0→首指令永不提交);③ WITH_CHISELDB=0
> 避 sqlite3.h;④ 运行须 +ram_size=8589934592(默认 8TB 致 NEMU crash);⑤ 替换 wrapper 须带完整
> golden 端口(perf/debug 占位)。

## 方法学与闸门(见 docs/REWRITE_STYLE.md)
从 Scala 设计意图重写(非 golden 转写)→ 结构硬闸门(struct/enum/function/genvar>0、0 生成痕迹)→ 多种子 UT → FM。
- 大互联模块:可读核(真逻辑)+ `*.svh`(纯子模块例化+连线);**.svh 套壳闸门**:`grep _GEN_/_T_` 必须≈0,上百即 golden 逻辑套壳→拒收(DataPath/NewDispatch 首版曾犯,已回退重做)。
- **铁律**:① `array[可能X索引]`→三元 mux;② priority 仲裁用 `priority case`;③ UT 只比端口、会漏覆盖内部状态分叉→关键模块用 tb 内部层次探针逐拍比 golden 内部寄存器(PtwCache/Rob/NewDispatch 即靠此抓出真 bug)。
- 协作:Claude 子 agent + codex(gpt-5.5)并行;所有产出一律独立复核(结构 grep + 多种子 UT 重跑 + FM + svh 套壳检查),不凭自报。
