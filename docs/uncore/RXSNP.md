# RXSNP — CHI RX-Snoop 接收/阻塞路由核 (可读重写)

`rtl/uncore/RXSNP.sv`(`xs_RXSNP_core`) + `rtl/uncore/RXSNP_wrapper.sv`(顶层 `RXSNP`)。
对应 `coupledL2/tl2chi/RXSNP.scala`。golden `RXSNP.sv` = 1427 行(firtool 展平, 460 端口)。

## 功能
CHI RX 通道进来的 snoop 请求, 经 2 深缓冲后拆地址成 L2 内部 TaskBundle, 并根据 16 路
MSHR 快照决定该 snoop 应**阻塞 (stall)** 还是**放行 (fire)**、以及是否**嵌套 (nest)** 到
某个正在做 replace/CMO release 的 MSHR 上(驱动 `snpHitRelease*`)。

### 数据通路
- `queue`: golden `Queue2_CHISNP`(内含 `ram_2x98`), 2 深流水缓冲。本核**白盒例化**它,
  FM 两侧均引入同一 golden 子模块比对(非黑盒; Queue2_CHISNP 已在 shard E 独立签绿)。
- 地址拆分(CHI SNP addr 比全地址少 3 位, 补 `{addr,3'h0}` 再拆):
  `tag = addr[44:14]`, `set = addr[13:5]`, `off = {addr[2:0],3'h0}`。
  注意 `addr[4:3]` 从不被读 → 是 cone-dead(见下)。
- `srcID/fwdNID/fwdTxnID/retToSrc/traceTag` 由 queue 直连输出。

### 阻塞/嵌套匹配 (16 路组合, genvar + 显式 assign)
| 掩码 | tag 源 | 语义 |
|------|--------|------|
| `reqBlockSnpMask`   | reqTag  | 命中在飞请求, 需阻塞 (Scala [2][3][5][6]) |
| `cmoBlockSnpMask`   | metaTag | 命中脏命中 CMO/release 未完, 阻塞 |
| `replaceBlockSnpMask` | metaTag | 命中替换流 rProbe 未完, 阻塞 |
| `replaceNestSnpMask`  | metaTag | 命中替换流 rProbe 已完, 嵌套 |

`stall = |reqBlockSnpMask | |replaceBlockSnpMask | |cmoBlockSnpMask`;
`deq.ready = task.ready & ~stall`; `task.valid = deq.valid & ~stall`。

`snpHitRelease*` 由唯一命中的 nest 条目(golden 断言 `PopCount(replaceNestSnpMask)<=1`)之
`releaseToClean/replaceData/meta` OR-归约得出; `snpHitReleaseIdx = PriorityEncoder(mask)`(低位优先, 全 0 默认 15)。

### 32 个延迟寄存器
golden 把 `RegNext(w_replResp)` 复制成两份: `replaceBlockSnpMask_REG_N`(16) +
`replaceNestSnpMask_REG_N`(16), 逐位相同。本核只写单份 `replResp_d[15:0]`,
靠 `verification_merge_duplicated_registers=true` 与 golden 的 32 份配对(FM 内 16 passing DFF)。

## FM 签核
- native **Verification SUCCEEDED**, passing **407**(128 Port + 279 DFF), 0 failing, 0 unmatched, 0 blackbox。
- 权威判据: `fm.log` `FM_RESULT: Verification SUCCEEDED` + 末表 `Failing 0`, 无 unmatched/unread。
- 证据: `/tmp/rxsnp-evidence/RXSNP_fm_strengthened.log`(turnkey SUCCEEDED)、
  `RXSNP_fm_native_strict_unread68.log`(未加强 native SUCCEEDED 但 68 unread)、
  `unread_matched.rpt`(68 双射清单)。

### 对称死寄存器加强 (class-4, standing rule)
strict 下 `verify_unread_compare_points=false` ⇒ 完全 cone-dead 的 DFF 落 Unread。RXSNP 有 **68 个对称死** DFF, 全部 ref==impl 双射(去 `u_core/` 前缀后同名):
- `stallCnt_reg[0..63]`(64): 死锁监视计数器, 仅 `` `ifndef SYNTHESIS `` 断言里读; FM 用
  `-define {SYNTHESIS}` ⇒ 断言裁剪 ⇒ 无观测扇出。
- `queue/ram_ext/Memory_reg[{0,1}][{54,55}]`(4): golden Queue RAM 字里 `addr[4:3]` 的 2 位,
  RXSNP 从不读 ⇒ cone-dead; 两侧同 golden 子模块 ⇒ 天然对称。

`FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=true`(Makefile) + `fm_pins.tcl`(68 条显式
`set_user_match` 双射)让 FM **真正比较**这 68 点(证 ref==impl, **非 waiver**), Unread→Passing。

**★须 main 把 `RXSNP` 加入 `scripts/fm_eq.tcl` line-77 matched-unread 白名单方可绿**
(否则该 flag 触发 `FM_MODE_ERROR` 门控退出, fail-closed)。与已提交的 MemUnit/ResponseUnit
先例同型。allow/ 无需 RXSNP 条目(0 unmatched/0 unresolved-blackbox, strict allow 须空)。

## UT
`verif/ut/RXSNP/`: golden `RXSNP`(`u_g`) vs `RXSNP_xs`(`u_i`, 例化 `xs_RXSNP_core`) 双例化逐拍
对比全 26 输出。seed 1/7/42 各 200k 周期, checks 5,200,000 / errors 0。
共用单份 golden `Queue2_CHISNP` + `ram_2x98`。

## 真实 bug
无。可读核与 golden 逐拍一致(bug-for-bug), 未发现 golden RTL 缺陷。
