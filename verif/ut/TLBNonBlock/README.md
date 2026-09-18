# TLBNonBlock 家族 UT（dtlb_ld / dtlb_st / dtlb_pf）

三个 golden 顶层 `TLBNonBlock` / `TLBNonBlock_1` / `TLBNonBlock_2` 共用一个可读核
`rtl/memblock/xs_TLBNonBlock_core.sv`，三个薄 wrapper 由 `scripts/gen_tlbnb_family.py`
从 golden 端口表机械生成。本目录三份 tb 由 `gen_tb.py` 从 golden 端口表生成，
**勿手改 tb\*.sv**，改 `gen_tb.py` 再跑 `python3 gen_tb.py`。

## 怎么跑

```
make compile  && make run        # 变体 base (TLBNonBlock)
make compile1 && make run1       # 变体 _1   (TLBNonBlock_1)
make compile2 && make run2       # 变体 _2   (TLBNonBlock_2)
# 正式矩阵：3 变体 x 3 seed x 2 initreg x 200k
make run  SEED=<1|7|42> INITREG=<0|random> NCYCLES=200000
make mutants        # 判别力负测：注入真 bug 必须红
make mutants-cov    # 覆盖闸自身的负测：短拍数跑未变异基线必须判红
make fm             # 三个变体的 FM（一般走 scripts/run_proof.sh TLBNonBlock ...）
```

## 判绿的三条，缺一不可

1. `errors=0`
2. `checks` 非 0 —— 逐拍逐端口的比较次数。**编译坏了也会给出 errors=0 的假象**，
   这一项专门堵那个 fail-open；`checks==0` 直接判 TEST FAILED。
3. `bad_cov=0` —— 14 个覆盖桶全部 > 0。桶全部取 **golden 一侧**的状态
   （golden 内部层次 + golden 输出），量的是"激励把参考设计推到过哪些状态"，
   重写核错了也刷不绿它。

`TEST PASSED` 只在这三条同时成立时才打印，Makefile 也只认这一行。

## 覆盖桶为什么是这 14 个

| 桶 | 含义 |
|---|---|
| c_hit / c_miss | lane0 命中 / 未命中 |
| c_phit | PTW 旁路命中（p_hit 打拍后为真） |
| c_ptwreq | 向 PTW 发过请求 |
| c_needgpa / c_gparefill | 进入 need_gpa / 拿回 gpaddr |
| c_gpf | G-stage 故障 hasGpf |
| c_napot_sup | noS2 + s1.entry.n=1 的 PTW 响应把本拍 miss 压住 |
| c_sfence | sfence 冲刷 |
| c_ppnnz | 命中且译出非零 ppn |
| c_s2x0..3 | resp 拍四种 s2xlate 各走到 |

`c_napot_sup` 有来历：本轮唯一那个真 bug（核 `s1_hit()` 的 sector tag 切片上界
跟着下界一起减了 SECT_W）**只在这条路上显形**。没有这个桶，一份把
`s1.entry.n` 恒置 0 的激励可以让三个变体全绿而 bug 还在。

`c_gparefill` 也有来历：它在原始随机激励下 **200k 拍恒为 0** —— need_gpa 状态机的
收尾路径一次都没被测过，而 errors=0 照样打印。补它花了三件事，每件在
`gen_tb.py` 里都写了依据：need_gpa 时定向回一条对得上的 PTW 响应；s1 权限位偏向
合法、G-stage 偏向不合法（否则 pf/af 把 gpf 全盖住）；frm_mabuf 拉高、
kill/isPrefetch 压低（can_get_gpa 的唯一便宜入口）。

## 激励里两处"看起来不干净"的地方，都是故意的

- **定向激励读 `dut_g` 的内部状态**（`need_gpa` / `need_gpa_vpn` / `need_gpa_s2xlate`）。
  它是激励发生器的一部分：输入只依赖 **golden 一侧**的状态，两个 DUT 吃到的仍是同一组
  输入端口值，不构成"拿被测件当参考"。
- **各种概率不是均匀的**。纯随机下 entries 几乎永远 miss、mode 99% 落在"没开页表"、
  pf/af 把 gpf 全盖住 —— 主要控制路径根本走不到。每一处偏置在 `gen_tb.py` 里
  都注明了"偏它是为了走到哪条路"。

## 子模块：两侧同源 elaborate，不做黑盒

`DelayN_7/_9`、`TlbStorageWrapper_1/2/3`、`TLBFA_1/2/3` 都**不是本目标**。
UT 与 FM 两侧都用**同一份 golden 文件** elaborate（`RTL_GOLDEN_DEPS` 同时进
`FM_REF_SRCS` 与 `FM_IMPL_SRCS`），不声明任何黑盒。

依据两条：
- 这正是 `TlbStorageWrapper_1` 那一轮对 `TLBFA` 用过的办法
  （`evidence/f40deba9439d/TlbStorageWrapper_1/receipt.json`：impl_closure 里有
  golden `TLBFA.sv`/`TLBFA_1.sv`，`matched_blackbox_pairs` 为空，passing 8682 / failing 0）。
- **闭包里没有厂商 SRAM 宏**：TLBFA 是寄存器实现的全相联 CAM（golden TLBFA_1 实测
  2650 个 `reg` 声明 / 8275 个触发器位），整棵闭包 `grep` 不到任何 `*_ext` 例化。
  所以本目标不声明、也不需要任何黑盒。

## 复位后的热身窗口（为什么 UT 不从第 1 拍就开始比）

golden 与重写核里有一批**无复位**寄存器（RegEnable：`req_out_*` / `resp_fullva_r` /
`ptw_resp_bits_reg_*` / `p_*` …）。`+vcs+initreg+random` 给两侧的是**各自独立的
随机初值**，在它们被第一次写之前逐拍比较，比的是模拟器的初值、不是电路。

实测（commit 2c90a2c，200k 拍）：
```
TLBNonBlock seed=1  initreg=0       errors=0
TLBNonBlock seed=1  initreg=random  errors=0
TLBNonBlock seed=7  initreg=0       errors=2      <- resp_fullva / gpaddr 的 X
TLBNonBlock seed=7  initreg=random  errors=857
TLBNonBlock seed=42 initreg=0       errors=2
TLBNonBlock seed=42 initreg=random  errors=493
```
所以 tb 分两个阶段热身，**热身期不计 checks、不采覆盖桶**：

- **阶段一（`WARMUP_CYCLES=8` 拍）** 把所有 `req_valid` 与 `ptw_resp_valid` 拉满
  （`gen_tb.py` 的 `warmup_drive()`），让每个 **enable 门控**的无复位寄存器都被写一次。
- **阶段二（等事件，上限 `WARMUP_MAX=20000` 拍，超时判 FAILED）** 阶段一治不了
  **自保持**的那一个：`resp_gpa_gvpn` 的次态默认是它自己，拉 enable 没用，只有一次真的
  getGpa 往返（golden 的 `resp_gpa_refill` 拉高那一拍）才会写它。所以阶段二一直跑随机
  激励，直到 golden 侧 `resp_gpa_refill` 出现过一次为止。
  实测等待拍数：base 4146/6263/7010，`_1` 10719/322/488（seed 1/7/42）。
  `TLBNonBlock_2` **没有** `resp.gpaddr` 端口，golden 里根本没有 `resp_gpa_gvpn`
  这个寄存器，阶段二无对象、直接跳过（`gen_tb.py` 按 golden 端口表自动判定）。

  另外三个自保持寄存器 `need_gpa_vpn` / `need_gpa_robidx_{flag,value}` 不需要等：
  它们的读者都被 `need_gpa` / `need_gpa_robidx_valid` 门控，而这两个是**带异步复位**的，
  复位后为 0，所以陈旧值到不了任何输出。

无复位寄存器的初值本来就归 FM 管（FM 把它们当自由变量，配对后逐点证等价），
这正是"UT 与 FM 分工"那条：**UT 看不见的东西先问 FM**，反过来也一样 ——
UT 不该把模拟器初值当 bug 报。

## 一个只有 UT 能抓的坑：unpacked 数组的混合驱动会关掉 `+vcs+initreg`

核里"父级没接这个输入的 lane 不生成寄存器"是用 generate 的 else 分支给常量。
**那个常量必须用 `always_comb`，不能用 `assign`**：

```systemverilog
logic [63:0] arr [2];
always_ff @(posedge clock) if (en) arr[0] <= d;
assign arr[1] = '0;          // ★毒★ 整个 arr 都不再被 +vcs+initreg 初始化
```
最小复现（本轮实测，VCS W-2024.09-SP1）：同一个数组里只要有一个元素是连续赋值，
`+vcs+initreg+0` 下 `arr[0]` 仍然是 X；把 `assign` 换成 `always_comb` 就恢复正常
（initreg+0 得 0、initreg+random 得随机值）。generate-for + if/else 的形状同样中招。

golden 那边是普通标量 `reg`，照常被初始化成 0，于是表现为 `g=0 / x=X`。
FM 看不见它（无复位寄存器两侧都是自由变量），**这条只有 UT 抓得到**。
