# Sbuffer FM 跑前预登记（写在跑之前，跑完逐条对账）

登记时间点：`rtl/memblock/Sbuffer.sv` 与本目录 `Makefile` 已定稿、UT 已过，
**本轮 FM 一次都还没跑**。下面每条都是可被证伪的数字或断言。

## 证明配置

| 项 | 值 |
|---|---|
| ref | `G1-canonical/golden-rtl/` 的 `Sbuffer.sv` + `SbufferData.sv` + `StorePfWrapper.sv` + `Serializer.sv` |
| impl | `rtl/memblock/Sbuffer.sv` + **同一组** golden 子模块文件（`RTL_GOLDEN_DEPS`） |
| FM_MODE | `signoff-strict`（默认，Makefile 未设 FM_MODE） |
| FM_ALLOWLIST | 0 |
| FM_MERGE_DUP | 未设 → `fm_eq.tcl` 默认 `true` |
| 黑盒 | **0 个**（两侧闭包完全对称、全部白盒展开；`check_closure_symmetry.py --only Sbuffer` 已 PASS） |

## 预测

| # | 预测 | 依据 |
|---|---|---|
| P1 | native verdict = `SUCCEEDED` | UT 3 seed × 2 initreg × 200k 拍 errors=0，10 个变异体全被抓 |
| P2 | failing = 0 | 同上 |
| P3 | unmatched（六类全部）= 0 | 两侧子模块同源同名，层次结构一一对应 |
| P4 | 黑盒对数 = 0、`unresolved_blackbox` = 0 | 闭包对称、SbufferData 内无厂商硬宏 |
| P5 | `unread_notcompared` = 0 | 重写核没有 golden 没有的寄存器；`always_ff` 里没有 automatic 临时量 |
| P6 | 无 `dont_verify`、无 relaxed appvar | 未设任何放宽开关 |
| P7 | passing ∈ **[27 000, 30 500]** | 见下面的锚定推算 |

### P7 的锚定（不是凭空估，是拿上一轮同配置的实测数外推）

上一轮 `xs-v2r2-sv` 的 Sbuffer 有一份**通过**的签核证据
（`scripts/sidecar/signoff-evidence-delta/Sbuffer`，run_id `SGN-Sbuffer-1784809239`，
impl_commit `36c3ca03a241a2f64419d46c8156c15f0c6b0117`）：

```
native SUCCEEDED   passing=26797  failing=0  unverified=0  unread_notcompared=0
unmatched 六类全 0   relaxed_appvars=[]   verification_merge_duplicated_registers=true
```

那一跑的 appvar 与本轮默认完全一致（merge_dup=true），比较点集合也可比：
两轮的寄存器集合相同（上一轮把 SbufferData 的存储摊平进了核，本轮把它作为真正的
子实例白盒展开——**匹配上的寄存器对数不变**）。差的只是 G0→G1 的端口增删：

| 项 | 位数 |
|---|---|
| `gatewayIn_packed_49/50/51/52_bore`（G1 新增输出） | +657 + 325×3 = **+1632** |
| `io_sbFull`（新增输出 + 它的 1 个寄存器） | +2 |
| `io_store_prefetch_0/1_bits_vaddr`（G1 删除） | −100 |

26797 + 1632 + 2 − 100 = **28331**。取 ±5% 余量（merge_dup 在新的层次结构下
可能多合/少合几组）得 [26 914, 29 748]，向外取整为 **[27 000, 30 500]**。

**对账规矩**：P1~P6 是硬判据，任意一条不符按 fail 报。
P7 落在区间外也按 fail 报——那说明我对「比较点集合 = 两侧匹配寄存器 + 顶层输出位」
这个模型的理解与工具看到的不是一回事，必须查清楚，**不许事后改区间**。
