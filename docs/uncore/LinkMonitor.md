# LinkMonitor —— CHI 链路层监视器 (LINKACTIVE 握手 + L-Credit 流控)

> 设计源:OpenLLC `chi/LinkLayer.scala`(RN 侧 LinkMonitor)
> 可读核:`rtl/uncore/LinkMonitor.sv`(`xs_LinkMonitor_core`)+ `rtl/uncore/linkmonitor_pkg.sv`
> 黑盒子模块:`Decoupled2LCredit{,_1,_2}`(txreq/txrsp/txdat)、
> `LCredit2Decoupled{,_1,_2}`(rxsnp/rxrsp/rxdat,内含 `Queue4_CHISNP` + `ram_4x115`)
> 生成器:`scripts/gen_linkmonitor.py`;UT:`verif/ut/LinkMonitor/`

LinkMonitor 是 CHI 链路层的**最薄管理层**:把上层的 `Decoupled`(ready/valid)接口与下层
CHI 物理链路的 **flit + L-Credit** 协议互转(互转由 6 个子模块黑盒完成),自身只负责
**链路激活握手、L-Credit 回收时序、系统一致性握手、性能计数,以及给上行 flit 注入本节点
ID**。本核是「真时序 glue」而非纯连线,值得逐拍重写。

## L-Credit 链路层协议(本层只摆链路态,流控本体在子模块)

CHI 链路层用 **L-Credit**(Link Credit)做逐通道反压:
- 接收方每发一个 `lcrdv` 脉冲 = 授予发送方 **1 个信用**;发送方**有信用才可拉 `flitv` 发一个
  flit**(`flitpend` 提前一拍预告)。
- 链路有 4 态 **LINKACTIVE FSM**:`STOP → ACTIVATE → RUN → DEACTIVATE → STOP`,由对端的
  两根握手线 `{linkactivereq, linkactiveack}` 直接译码:

  | {req, ack} | 链路态 | 含义 |
  |-----------|--------|------|
  | `00` | STOP | 链路停止 |
  | `10` | ACTIVATE | 已请求激活,待对端确认 |
  | `11` | RUN | 可正常收发 flit |
  | `01` | DEACTIVATE | 已撤请求,待对端撤确认 |

- **去激活必须先还清信用**:进入 DEACTIVATE 时,发送方要把手里未用的信用如数「归还」
  (发 NULL flit / 撤信用),接收侧的子模块以 `reclaimLCredit` 回报「已还清」。

## 本核逻辑(`xs_LinkMonitor_core`)

### 1. LINKACTIVE 状态机(TX / RX 对称,折叠成数组)
TX 与 RX 两个方向用**同一译码函数** `link_state()`,折叠成 `link_st[DIR_TX/DIR_RX]` 数组
循环(对应 Scala 的 `Seq(txState, rxState).zip(...).foreach`):
```
reqack_tx = {tx_linkactivereq_q, io_out_tx_linkactiveack}  // 本端 req + 对端 ack
reqack_rx = {io_out_rx_linkactivereq, rx_linkactiveack_q}  // 对端 req + 本端 ack
link_st[d] <= link_state(reqack_d[1], reqack_d[0])         // d∈{TX,RX}
```
译码结果下发给各 flit 转换子模块的 `io_state_state`(子模块据此决定能否发 / 收 flit、何时
回收信用)。

### 2. 链路握手(本端策略)
```
tx_linkactivereq_q <= 1                                     // 本端总想激活 TX 链路
rx_linkactiveack_q <= rx_linkactiveack_d | ~rx_deact       // 见下
rx_linkactiveack_d <= io_out_rx_linkactivereq              // RegNext(对端 RX req), 无复位
rx_deact = rxsnp_reclaim & rxrsp_reclaim & rxdat_reclaim   // 三 RX 通道信用全还清
```
**关键时序**:对端撤下 `rx.linkactivereq` 后,本端的 `rx.linkactiveack` **不能立刻撤** ——
要等三个 RX 子模块把欠的 L-Credit 全部回收(`reclaim` 全 1)才允许撤,否则会丢信用。这正是
`| ~rx_deact` 的作用(只要还有通道没还清,ack 维持高)。

### 3. 系统一致性 + txsactive
```
syscoreq_q  <= 1                          // 系统一致性请求恒高
txsactive_q <= syscoreq_q | io_out_syscoack   // = ~(~syscoreq & ~syscoack)
io_out_syscoack ← (对端输入)              // syscoack 由对端按 RegNext(syscoreq) 回握
```

### 4. 性能计数器(仅监测,无输出端口)
```
retryAckCnt     ++  当 rxrsp 握手成功 & opcode==RetryAck(5'h3)
pCrdGrantCnt    ++  当 rxrsp 握手成功 & opcode==PCrdGrant(5'h7)
noAllowRetryCnt ++  当 txreq 被接收 & allowRetry==0(发出不可重试请求)
```
这三个计数器在 golden 里也无输出端口(`dontTouch`,综合时裁掉);本核保留以忠实表达设计
意图。FM 对无观测路径的寄存器不作为比对点(`verification_verify_unread_compare_points
false`),不影响等价证明。

### 5. srcID 注入
3 个上行(TX)子模块的 `io_in_bits_srcID` 恒接 `io_nodeID` —— 链路层在发 flit 时填本节点
的 CHI nodeID 作为源。

## 子模块(黑盒)与端口连线要点

- `io_in_tx_rsp_ready` / `io_in_tx_dat_ready` / `io_in_rx_dat_valid` 由对应子模块**直接连出**;
- 只有 `io_in_tx_req_ready`(= txreq 子模块 `io_in_ready`)与 `io_in_rx_rsp_valid` /
  `io_in_rx_rsp_bits_opcode`(= rxrsp 子模块输出)经内部 wire 引出,因为它们还要参与本核
  的计数 / 输出逻辑。
- `io_out_rxsactive` 是悬空输入(golden 未用);`io_out_txsactive` 取本核 `txsactive_q`。

## 验证

- **UT**:`verif/ut/LinkMonitor/` golden `LinkMonitor` vs 可读 `LinkMonitor_xs` 双例化,逐拍
  比对全部输出。两侧共用 golden 的 6 个子模块(相同内部状态)。输入全随机:
  `io_out_tx_linkactiveack` / `io_out_rx_linkactivereq` 覆盖 4 态转换,flit/flitv/lcrdv/valid
  覆盖子模块与 `reclaim` 去激活路径。seed 1/7/42 各 200000 拍,**errors=0**(14.2M checks)。
- **FM**:ref = golden `LinkMonitor.sv`;impl = pkg + 可读核 + wrapper。6 个子模块两侧均不
  提供 ⇒ 自动黑盒同名配对,比对聚焦本核状态机 / 握手 / 计数逻辑。**Verification SUCCEEDED**。
