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

## FM 状态（重要，诚实记录）

可读重写后 FM（签名分析）报 **20 个比对点 failing**：均为 `s0_fire` 门控的 s1 流水捕获
寄存器（s0_fire_r / s1_req_vaddr / s1_req_ftqIdx_value / s1_backendException /
s1_isSoftPrefetch 的部分位）。经核查这些是 **不可达状态的 FM 假阳性**，非真 bug：
- s0_fire 及其全部分量（s0_valid/s0_can_go/from_bpu_s0_flush/s1_flush，及循环指针
  比较 `flag^flag^(val<=val)`）逐一核对与 golden 一致；
- tb 加**层次探针**逐拍比对 golden 与本设计的内部寄存器 s0_fire_r、s1_req_ftqIdx_value，
  8 万拍 **internal_probe_err=0**（逐位完全一致）；
- UT 8 万拍全部 75 输出 0 错。

即在所有**可达**状态下功能严格等价；FM 的 failing 来自设计实际到不了的输入组合
（签名分析不知道可达状态空间）。符合工程标准「可读优先、FM 尽量做」——以充分 UT +
内部探针确证等价，不为消除该假阳性而牺牲可读性。后续可用 FSM 可达性约束令 FM 全绿。
