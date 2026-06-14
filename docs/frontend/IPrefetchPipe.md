# IPrefetchPipe —— ICache 预取流水

| | |
|---|---|
| 手写 SV | `rtl/frontend/IPrefetchPipe.sv`（`xs_IPrefetchPipe_core`）+ `rtl/frontend/IPrefetchPipe_wrapper.sv` |
| Scala 来源 | `src/main/scala/xiangshan/frontend/icache/IPrefetch.scala`（class IPrefetchPipe） |
| 生成器 | `scripts/gen_iprefetchpipe.py` |
| 验证状态 | UT ✅（多 seed 各 8 万拍 0 错）/ FM ✅（901 比对点全 matched by name） |

## 功能

ICache 预取流水（s0/s1/s2 三级状态机）：接收预取请求，经 ITLB 翻译、查 meta 判命中、
未命中向 MissUnit 发预取请求。内联了一个纯组合优先级仲裁器 `Arbiter2_ICacheMissReq`。

## 关键实现点

- 寄存器全部为标量、命名沿用 golden，无扁平打包 payload → FM 纯按名匹配即全过（无需 fm_map）。
- 子模块 `Arbiter2_ICacheMissReq`（优先级仲裁）逻辑内联进核；UT/FM 引入其 golden 源
  做参考，impl 侧由 FM 展平匹配。

## 验证

- **UT**（`verif/ut/IPrefetchPipe/`）：golden vs `IPrefetchPipe_xs`，随机激励（ITLB 异常
  pf/gpf/af 做 one-hot 化避免误触 golden 断言，paddr/tag/vSet 值域压窄提高覆盖），
  多 seed 各 8 万拍 0 错。
- **FM**：SUCCEEDED，901 比对点（468 DFF + 433 port）全 matched by name。

## 工程提示（踩坑）

golden 含 `ifndef SYNTHESIS` 的 multi-hit/one-hot 断言，随机激励会误触发 `$fatal`，
UT 需 `+define+SYNTHESIS` 屏蔽。**注意**：`ut_common.mk` 用 `VCS := ...` 简单赋值，
故 `VCS += +define+SYNTHESIS` 必须放在 `include` **之后**追加才生效（放之前会被覆盖）。

> 本模块由并行子 agent 重写，主线已独立复跑 UT+FM 核验通过。
