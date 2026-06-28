# SNXbar —— CHI Subordinate-Node 交叉开关 (4 主 × 1 从)

> 设计源:OpenLLC `SNXbar` (CHI 子节点侧交叉开关)
> 可读核:`rtl/uncore/SNXbar.sv`(`xs_SNXbar_core`)+ `rtl/uncore/snxbar_pkg.sv`
> 黑盒子模块:`FastArbiter_47`(TXREQ 仲裁)、`FastArbiter_46`(TXDAT 仲裁)
> 生成器:`scripts/gen_snxbar.py`;UT:`verif/ut/SNXbar/`

SNXbar 把 **4 个上游 Home-Node**(在本交叉开关中作为「主口 in_0..in_3」)对 **1 个
下游 Subordinate-Node**(SN,主存控制器)的访问做汇聚 / 分发。它是 CHI 网络里最简单的
一类交叉开关:**上行多对一仲裁,下行一对多解复用**,且解复用用的是事务 ID 而非地址。

## 拓扑与数据流

| 方向 | 通道 | 行为 |
|------|------|------|
| 上行 TX(主→从) | TXREQ / TXDAT | 4 主口各自的 flit 经一个 `FastArbiter`(黑盒)轮转仲裁,胜者载荷路由到唯一从口 `out` |
| 下行 RX(从→主) | RXRSP / RXDAT | `out` 回送的 flit 按 `txnID[10:9]` 解复用回对应主口;载荷广播,仅 valid 受路由门控 |

CHI flit 通道(OpenLLC `CHIBundleDownstream`/`Upstream` 子集):
- **TXREQ**:请求(读/写/CMO),含 `addr`/`size`/`memAttr`/`order`/`expCompAck` 等;
- **TXDAT**:写数据,含 256 位 `data` + 32 位 `be` + `dataCheck`;
- **RXRSP**:响应(Comp/DBIDResp/RetryAck…),含 `dbID`;
- **RXDAT**:读数据,含 256 位 `data` + `resp`/`dataID`。

## 上行 TX:仲裁 + ready 解复用

仲裁本体(round-robin + 胜者 payload 多路选择)由 `FastArbiter` 黑盒完成,**本核不重写
仲裁**。本核做两件事:

1. 把 4 个主口的 flit 打包成结构体数组 `tx_req[NUM_IN]` / `tx_dat[NUM_IN]`(按主口对齐),
   喂给两个仲裁器(`io_in_i_bits_* ← tx_*[i].*`);
2. **ready 解复用**:仲裁器只给出一个 `io_chosen`(2 位胜者编号)和 `io_out_valid`,本核
   据此把 ready 回送被选中主口:
   ```
   txreq_grant      = io_out_tx_req_ready & io_out_valid   // 本拍真正放行
   tx_req_ready[i]  = txreq_grant & (chosen == i)          // 仅胜者 ready
   ```
   胜者载荷由仲裁器内部选好,直接经结构体 `out_tx_req`/`out_tx_dat` 扇出到从口 `out`。

## 下行 RX:按 txnID 解复用

OpenLLC 在下发请求时把**源 HN 的 2 位编号塞进 `txnID[10:9]`**,从口回程的每个 flit 据此
还原归属。解复用用 `genvar` 循环表达 4 个对称主口:
```
rx_route(txnID) = txnID[10:9]                              // 0..3
rx_rsp_valid[i] = io_out_rx_rsp_valid & (rx_route == i)    // 仅命中主口拉 valid
rx_dat_valid[i] = io_out_rx_dat_valid & (rx_route == i)
// 载荷广播: 各主口 rx_*_bits 直接取 out 的 rx 载荷 (out_rx_rsp / out_rx_dat 结构体)
```
RX 通道**无 ready 背压**(主口侧 rx 只有 valid + bits),故从口的 `rx_*_ready` 退化为各
主口接受信号的 OR(2 位路由必命中其一,实际恒等于 `rx_*_valid`,但保留 OR 结构以忠实
对应 golden):
```
io_out_rx_rsp_ready = |rx_rsp_valid_o     // = |{valid & (route==i) : i∈0..3}
io_out_rx_dat_ready = |rx_dat_valid_o
```

## 与 SNXbar 的协议要点

- **路由靠 txnID 不靠地址**:不同于 TileLink 的 `AddressSet` 译码,CHI 子节点交叉开关用
  事务 ID 高 2 位回送应答,因为同一物理地址可能被多个 HN 访问,只有事务 ID 能唯一区分
  应答归属。
- **TXREQ/TXDAT 分开仲裁**:CHI 请求通道与数据通道独立流控,各有一个仲裁器(`io_chosen`
  互不相关),故写事务的 req 与 dat 可被仲裁到不同相位。
- **仲裁器即 payload 多路选择器**:`FastArbiter` 黑盒同时完成「选胜者」与「把胜者 flit
  搬到 `io_out_bits_*`」,所以本核 TX 侧没有显式的 one-hot mux。

## 验证

- **UT**:`verif/ut/SNXbar/` golden `SNXbar` vs 可读 `SNXbar_xs` 双例化,逐拍比对全部输出。
  两侧共用 golden 的 `FastArbiter_46/47`(同一仲裁内部状态),输入全随机(`txnID` 全宽随机
  即均匀覆盖 `[10:9]`=0..3 四条回程路由)。seed 1/7/42 各 200000 拍,**errors=0**
  (17.4M checks)。
- **FM**:ref = golden `SNXbar.sv`;impl = pkg + 可读核 + wrapper。`FastArbiter_46/47` 两侧
  均不提供 ⇒ `hdlin_unresolved_modules=black_box` 自动按同名黑盒配对,比对聚焦本核路由 /
  解复用逻辑。**Verification SUCCEEDED**。
