# RNXbar —— CHI Request-Node 交叉开关 (1 RN × 4 HN)

> 设计源:OpenLLC `RNXbar` (CHI 请求节点侧交叉开关)
> 可读核:`rtl/uncore/RNXbar.sv`(`xs_RNXbar_core`)+ `rtl/uncore/rnxbar_pkg.sv`
> 黑盒子模块(15 个 FastArbiter,6 种类型):
> · TX:`FastArbiter_30`×4(txreq)、`FastArbiter_36`×4(txrsp)、`FastArbiter_31`×4(txdat)
> · RX:`FastArbiter_44`×1(rxsnp)、`FastArbiter_27`×1(rxrsp)、`FastArbiter_46`×1(rxdat)
> 生成器:`scripts/gen_rnxbar.py`;UT:`verif/ut/RNXbar/`

RNXbar 把 **1 个上游 Request-Node**(`io_in_0`,携带完整 `CHIBundleUpstream` 全字段)
与 **4 个下游 Home-Node bank**(`io_out_0..3`,携带精简的 `CHIBundleDownstream` 字段)
互连。相比 SNXbar(纯连线 + 仲裁),它**自带一个真状态机**:`snpReqs_*` / `snpMasks_*`
快照寄存器构成 snoop 请求跟踪逻辑。

## 拓扑与数据流(全 6 通道)

| 方向 | 通道 | 行为 |
|------|------|------|
| 上行 TX(RN→HN,1→4 拆分) | TXREQ | 按 `addr[7:6]` 选目标 bank;4 个 `FastArbiter_30`(单输入透传黑盒)各驱动一个 `io_out_j` |
| | TXRSP | 按 `txnID[10:9]` 选 bank;4 个 `FastArbiter_36` |
| | TXDAT | 按 `txnID[10:9]` 选 bank;4 个 `FastArbiter_31` |
| 下行 RX(HN→RN,4→1 仲裁) | RXRSP | 4 输入 `FastArbiter_27`,输入按 `srcID==0` 门控,`io_chosen` 决定 ready 回送 |
| | RXDAT | 4 输入 `FastArbiter_46`,同上 |
| | RXSNP | 4 输入 `FastArbiter_44`,但输入先经 **snoop 跟踪状态机**缓存一拍 |

上下游 bundle 字段集不同:RN 侧 TXREQ 有 29 个字段(`qos/returnNID/stashNIDValid/mpam/...`),
HN 侧只取其中 15 个;TXDAT 同理(22 → 6)。仲裁器内部透传全字段,本核只把 HN 消费的
子集扇出到 `io_out_j` 端口(其余为未读黑盒输出引脚,FM 中表现为无观测影响的 unmatched
impl 点,不影响等价性)。

## 上行 TX:路由拆分 + ready 或归约

每个通道用 `genvar` 循环例化 4 个单输入仲裁器,输入 `valid` 由路由位门控到目标 bank:
```
txreqArbs[j].io_in_0_valid = io_in_0_tx_req_valid & (route_req(addr) == j)   // addr[7:6]
txrspArbs[j].io_in_0_valid = io_in_0_tx_rsp_valid & (route_txnid(txnID) == j) // txnID[10:9]
txdatArbs[j].io_in_0_valid = io_in_0_tx_dat_valid & (route_txnid(txnID) == j)
```
RN 侧 ready 是各 bank 输出 valid 的或归约(只有 TXREQ 的 HN 侧有 ready 背压,RSP/DAT
被 HN 视作恒接收):
```
io_in_0_tx_req_ready = |(hn_txreq_ready & txreq_out_valid)   // 仅 REQ & 该 bank out_ready
io_in_0_tx_rsp_ready = |txrsp_out_valid
io_in_0_tx_dat_ready = |txdat_out_valid
```

## 下行 RX:RXRSP / RXDAT 仲裁 + ready 解复用

4 个 HN bank 的 flit 打包成结构体数组喂给 4 输入仲裁器,输入按 `srcID==0`(目标 RN 编号)
门控。仲裁器 `io_chosen` 指出胜者 bank,ready 据此解复用回去:
```
rxrsp_in_valid[j]    = io_out_j_rx_rsp_valid & (srcID == 0)
io_out_j_rx_rsp_ready = (io_in_0_rx_rsp_ready & rxrsp_out_valid) & (rxrsp_chosen == j)
```
RXRSP 通道里 HN 不存在的字段(`qos/respErr/cBusy/tagOp/traceTag`)由仲裁器注入常量 0;
RXDAT 输出端丢弃 `tgtID/srcID`。

## snoop 跟踪状态机(本核相对 SNXbar 的核心增量)

每个 HN bank `j` 有一个 **1 深 snoop 槽**,由两组寄存器构成:

- **`snpReqs_j`**:锁存进来的 snoop 载荷(`txnID/fwdNID/fwdTxnID/opcode/addr/doNotGoToSD/
  retToSrc`)。`snpReqs_j_valid` 是**粘滞位**(一旦收过 snoop 就恒 1,表示槽内 bits 已是
  真实快照而非复位 0;只在复位清 0)。
- **`snpMasks_j`**:「该 snoop 仍需投递给 RN」的**挂起位**(本设计 1 个 RN ⇒ 1 位)。

逐拍协议:
```
snp_deliver_fire = io_in_0_rx_snp_ready & rxsnp_out_valid          // RN 取走仲裁后的 snoop
snp_mask_next[j] = ~(snp_deliver_fire & chosen==j) & snpMasks_j    // 取走则清挂起
snp_in_ready[j]  = (snpReqs_j_valid & ~snp_mask_next[j]) | ~snpMasks_j  // 1 深槽接收背压
snp_accept[j]    = snp_in_ready[j] & io_out_j_rx_snp_valid         // 本拍接收新 snoop 进槽
```
寄存器更新(`always @(posedge clock or posedge reset)`):
- 接收新 snoop(`snp_accept[j]`):锁存载荷,**挂起位 ← 外部输入 `io_snp_mask_set_j`**;
- 否则:`snpMasks_j ← snp_mask_next[j]`(被 RN 取走则清);
- `snpReqs_j_valid` 粘滞置位。

仲裁器输入 `valid = snpReqs_j_valid & snpMasks_j`,**只有「挂起」的 snoop 才参与仲裁、
投递给 RN**。这是 CHI snoop 摸到的关键协议点:

- **`io_snp_mask_set_j` 决定 snoop 命运**:它是上游(Home-Node / LLC)算出的目标掩码
  ——`1` 表示该 snoop 真需投递给 RN(挂起位置 1,进仲裁);`0` 表示该 snoop 可直接过滤
  丢弃(挂起位置 0,`snp_in_ready` 立即拉高释放槽,仲裁器输入 valid 恒 0 ⇒ snoop 被吞掉
  不投递)。即 snoop **接收-过滤**在一拍内完成。
- **挂起位是真「在飞」标志,valid 只是「槽已用过」**:二者分离,使被过滤的 snoop(valid=1
  / mask=0)能立刻释放槽接收下一条,而真需投递的 snoop(mask=1)占住槽直到 RN 取走。
- **快照锁存而非组合直通**:snoop 进槽后载荷被寄存一拍再仲裁,解耦 HN 侧 snoop 时序与 RN
  侧接收时序(对比 RXRSP/RXDAT 是组合直通仲裁)。

> 命名说明:golden 把 snoop 掩码 `Vec[4]`×`Vec[1]` 展平成 `io_snpMasks_j_0`(`io_*_N_M`
> 形态),可读核改名为 `io_snp_mask_set_j`;`snpReqs_*`/`snpMasks_*` 寄存器沿用 golden 展平
> 标量名(非 `io_` 前缀,不触发命名闸门)以便 FM 按名/签名稳健配对,组合逻辑则用按 bank
> 索引的结构体/数组视图重写。

## 验证

- **UT**:`verif/ut/RNXbar/` golden `RNXbar` vs 可读 `RNXbar_xs` 双例化,逐拍比对全部输出。
  两侧共用 golden 的 6 种 FastArbiter(同一仲裁内部状态)。激励:RN 三个 TX 通道
  `valid`+载荷全随机(`addr[7:6]`/`txnID[10:9]` 全宽随机 ⇒ 均匀覆盖 4 路 TX 拆分);4 个
  HN bank 的 RXSNP/RXRSP/RXDAT `valid`+载荷全随机;`io_snp_mask_set` 与各侧 ready 随机背压。
  **内部探针**:对 golden 与可读核同名的 36 个 snoop 寄存器(`snpMasks_j_0` / `snpReqs_j_*`)
  逐拍对拍。seed 1/7/42 各 200000 拍,**errors=0**(31.6M 输出 checks + 7.2M 探针 pchecks)。
- **FM**:ref = golden `RNXbar.sv`;impl = pkg + 可读核 + wrapper。6 种 FastArbiter 两侧均不
  提供 ⇒ `hdlin_unresolved_modules=black_box` 自动黑盒化并按连接配对。**Verification
  SUCCEEDED**:7309 passing,0 failing,0 unmatched reference 点;356 个 snoop 寄存器位
  全部 DFF 配对。764 个 unmatched impl 点均为 TX 仲裁器未被 HN 消费的输出引脚(无观测影响)。
