# CHI / L2 通道适配叶子 重写说明（coupledL2 / openLLC）

本轮重写 coupledL2(L2) 与 openLLC(L3/LLC) 的 CHI 通道适配与链路层握手转换叶子，全部
真重写（无套壳），放 `rtl/uncore/`，验证脚本 `scripts/gen_chi_channel.py`（通用 wrapper/
变体/UT/Makefile 生成器，含子模块黑盒依赖表 `DEPS`）。样板见 `SinkA/SinkC/SourceB/LinkMonitor`。

## 方法学要点（本轮新增/复用）
- **逐拍双例化比对**：tb 同时例化 golden `<Mod>` 与可读 `<Mod>_xs`（均例化同一可读核
  `xs_<Mod>_core`），每拍随机激励、`!$isunknown(golden)` 守卫下比对全部输出，seed 1/7/42
  各 ≥200000 拍 errors=0；`+define+SYNTHESIS`（裁掉断言/RANDOMIZE 初始化块）、`+vcs+initreg+0`。
- **子模块黑盒（Queue/RAM）**：含 `Queue16_*` / `Queue4_*` / `ram_*` 的模块，UT 两侧共用同一份
  golden 子模块定义；**FM 两侧（ref 经 `FM_REF_DEPS`、impl 经 `WRAPPER_SRCS`）都引入同一 golden
  子模块做整体等价**——避免把子模块当黑盒时未知方向引脚（如 TXREQ 的 `deq_addr[47:46]` 未被
  外围使用）被 FM 误判为驱动缺失而 fail。
- **★Chisel 宽度截位坑（抓到的真差异）★**：TXRSP/TXDAT 的在飞计数 `inflightCnt`，golden 把
  流水 s2~s5 的贡献 `PopCount(...) + PopCount(...)` 用 Chisel `+`（结果宽度 = max 操作数宽度、
  **截位**）压成 **2 位**，四项全 1 时 `4` 回绕成 `0`。可读核必须 `wire [1:0] pipe_cnt = ...`
  同样 2 位截位，否则四路流水满载的罕见拍会失配（最初 5934 errors 即此因）。TXREQ 用 3 位
  （max 5 < 8 不回绕），故 5 位累加与 golden 等价。

## 本轮做透清单（22 个，全部 UT seed1/7/42 errors=0 + FM SUCCEEDED）

### coupledL2 tl2chi（L2 侧）
| 模块 | golden 行 | 类型 | 说明 |
|------|----------|------|------|
| **RXRSP** | 118 | 纯组合 | CHI RSP → 内部 RespBundle（mshrId=txnID[7:0]，opcode 零扩展）|
| **RXDAT** | 182 | 纯组合 | CHI DAT(CompData) → RespBundle + 写 refillBuffer；逐字节奇偶 dataCheck（genvar）|
| **TXRSP** | 220 | 队列+反压 | 两路 RSP 汇聚→`Queue16_CHIRSP`(黑盒)→CHI；inflightCnt **2 位截位**，门限 >13/[4] |
| **TXREQ** | 267 | 队列+反压 | 两路 REQ 汇聚→`Queue16_CHIREQ`(黑盒)→CHI；出队把 sliceId 插回 addr[7:6] |
| **TXDAT** | 593 | 三队列+2beat | 头队列+2 数据队列(黑盒)→单条目 2-beat 输出缓冲；deassertBE/poison/dataCheck |

### openLLC chi（L3/LLC 侧）
| 模块 | golden 行 | 类型 | 说明 |
|------|----------|------|------|
| **RXRSP_4** | 106 | 纯组合 | CHI RSP → 内部 Resp |
| **RXDAT_4** | 112 | 纯组合 | CHI DAT → RespWithData（256b 一拍）|
| **RXREQ** | 179 | 1 计数器 | CHI REQ → Task；id_pool 每 fire 自增；reqID={0,bank,id_pool} |
| **TXSNP** | 123 | 纯组合 | Task → CHI SNP；addr={tag,set,bank,3'b0}；snpMask |
| **TXREQ_4** | 144 | 纯组合 | Task → CHI REQ；addr={tag,set,bank,6'b0} |
| **TXRSP_4** | 121 | 纯组合 | Task → CHI RSP（opcode 截 5b）|
| **TXDAT_4** | 311 | 2beat 缓冲 | TaskWithData → 逐 beat CHI DAT；beat0/1_valid FSM + 逐字节 dataCheck |

### CHI 链路层握手转换（LinkLayer，coupledL2）
| 模块 | golden 行 | 类型 | 说明 |
|------|----------|------|------|
| **Decoupled2LCredit** | 239 | 信用池+打拍 | Decoupled→L-Credit flit（REQ 162b）；池/flitv/flit 打拍；LinkStates 译码 |
| **Decoupled2LCredit_1/_2/_5** | 201/233/204 | 同型 | 仅净荷不同：RSP(73b)/DAT(422b)/SNP(115b)，控制逻辑同上 |
| **LCredit2Decoupled** | 232 | 信用记账+队列 | L-Credit flit→Decoupled（SNP 115b，blocking，`Queue4_CHISNP` 黑盒）；LCrdReturn 过滤 |
| **LCredit2Decoupled_8/_10** | - | 同型 | blocking lcreditNum=4：REQ(162b)/DAT(422b)，`Queue4_CHIREQ`/`Queue4_CHIDAT` 黑盒 |
| **LCredit2Decoupled_1** | 201 | **非阻塞** | blocking=false：无队列、直接解包；lcreditNum=15（池 5 位）；RSP(73b)|

### CHI / TileLink 透明监视器
| 模块 | golden 行 | 类型 | 说明 |
|------|----------|------|------|
| **CHILogger** | 187 | 纯透传 | up↔down 直连（sysco/linkactive/TX·RX flit/lcrdv 32 条）；日志在 `ifndef SYNTHESIS` |
| **TLLogger** | 250 | 纯透传 | TileLink A/B/C/D/E in↔out 直连（53 条）|

## 单态化常量速查
- **LinkStates**：STOP=0 ACTIVATE=1 RUN=2 DEACTIVATE=3
- **mshrsAll=16**；TXRSP 门限 noSpaceForMSHRReq=`>13`、noSpaceForSinkBReq=`[4]`(≥16)
- **RespErrEncodings**：NDERR=2'h2，DERR=2'h3（`&respErr`）
- **CHI DataCheck**：每字节输出 `~(该字节奇偶)`（逐字节 8b 奇偶取反）
- **节拍 dataID**：first=2'b00、last=2'b10（256b 总线一行两拍）

## 下一轮入口
- **RXSNP**（coupledL2，1427 行/460 端口）：CHI 嗅探接收。核心难点是对全部 16 个 MSHR 的
  `io_msInfo` 做 4 类 nest/block 掩码归约（reqBlock/cmoBlock/replaceBlock/replaceNest），
  含每条目 `RegNext(w_replResp)` 与 `ParallelOR` 选中条目的 meta；外加 2 深 `Queue2_CHISNP`
  与 stallCnt（断言，SYNTHESIS 裁掉）。建议用 genvar 逐条目算掩码位再 OR，**严禁 generate 内
  函数捕获模块信号**（见 IMSIC 铁律）。
- 其余 LCredit2Decoupled 变体（_2 非阻塞 DAT / _3 blocking lcreditNum=15 / _4/_5/_9/_11）、
  AsyncQueue 系列（跨时钟）、NCBUpstream*（openNCB，872~2156 行）。
