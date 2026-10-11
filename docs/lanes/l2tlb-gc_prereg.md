# agent/l2tlb-gc —— L2TLB 子树 exact green_child：处置、证据、待集成者登记项

基线 main `0fd433dd0`，认领 `62de21a18`。任务书 = codex 0228 问题 2（先例 0222 / 0224 / 0226）。
worktree `/home/eda/xs-env/wt-l2tlb-gc`。本 lane **没有改任何 RTL**（rtl/ 零 diff），只改 FM 证明输入、allow、钉点、登记。

## 0. 结论先行

| 步骤 | 状态 |
|---|---|
| 1. L2TLB 的 22 种直接 child + 证书闭包里的孙级 | **25 个目标全部重证/出证**；在本分支 HEAD 上 24/25 current-valid，**PtwCache 只差 3 行 MC 登记**（§3） |
| 2. MC 存储 | 3 行 derive 原文 + 可达性证据见 §3；ram_16x137 判为宽 filelist 假依赖，已从 Queue40 最小 FM filelist 清掉并重证 |
| 3. L2TLB exact green_child | canary 两轮完成、预测已登记并提交；**official 待 §3 三行进 main 并合入本分支后跑** |
| 4. L2TLBWrapper exact green_child | canary 完成（passing 5139 = 模型逐位）、预测已登记并提交；**official 待 L2TLB 证书** |
| 5. 整树 validate | 本分支 HEAD：24/25 True（只 PtwCache 缺 MC 行）；**临时加上 §3 三行后整条链预演（L2TLB / L2TLBWrapper 也跑 run_proof + 出证）27/27 True**（§6） |

阻塞点只有一个：`verif/mc_memory_registry.tsv` 是公共登记表，本 lane 不许改。PtwCache 的 impl 闭包共读
`sram_array_1p4x786m131s1h0l1b_ptw_l1` / `array_10`（MC_MEMORY_MODEL），其厂商叶子 `array_10_ext` 两侧对称黑盒；
三者未登记 ⇒ PtwCache 证书 `green_child_impl_golden_not_fm_target:PtwCache:sram_array_1p4x786m131s1h0l1b_ptw_l1`
⇒ L2TLB official 的 assembly 判决必为 PARTIAL。登记后 PtwCache **无需重跑 FM**（现有证书在加行后的提交上已复核为 True，§6）。

## 1. child 处置（每个 target）

判据：先用公共 current-valid 核心（`proof_certificate.validate_certificate_current`，脚本
`/home/eda/xs-env/tmp-l2/drycheck.py`：内存里由 receipt 造证书、对 HEAD 复核，不写文件）逐个核 main 上全部旧 receipt。
结果：除 Arbiter8_bitmapCacheReqBundle 外**全部陈旧**——绝大多数是 `script_closure_changed:scripts/fm_eq.tcl`
（fm_eq.tcl 2026-10-03 `28c7c3b90` 之后改过），另有：

- Bitmap（397a2bc9 receipt）：`impl_golden_uncertified:Arbiter8_bitmapCacheReqBundle`（孙级无证书）；
- BitmapCache（68d1a093）：`impl_golden_unexpected_path:array_9_ext.v`（impl 侧白盒读厂商叶子）；
- PtwCache（68d1a093）：`impl_golden_uncertified:SplittedSRAM_1`（impl 侧读 golden SplittedSRAM/SRAMTemplate 普通功能 RTL），
  且 impl 读 `array_10_ext.v` / `array_11_ext.v`（违反 0222 MC_MEMORY_BLACKBOX）；
- LLPTW：impl-golden 孙级 Arbiter2_LLPTW_Anon 无证书；
- Queue40_L2TlbMQBundle（3afabfed）：`impl_golden_mc_not_shared:ram_16x137`。

### 1.1 FM 输入改动（全部是 target-specific `fm-<T>:` 覆盖，UT 不变）

| 目标 | 改动 | 提交 |
|---|---|---|
| PtwCache | impl 改读 SRAM 一路**重写件**（SplittedSRAM_1/2、SRAMTemplate_128/129/143 + 共享核）；两侧共读的 golden 只剩 MC_MEMORY_MODEL（sram_array_*_ptw_l0/l1、array_10/11）；array_10_ext/array_11_ext 两侧都不读 = 对称未解析黑盒。钉点字面计数 60→41（实测，见 `verif/ut/PtwCache/fm_pins.tcl` 的 `_expect` 处） | `2ed2792f8`、`f4c4c870f` |
| BitmapCache | array_9_ext.v 两侧都不进 FM（对称未解析黑盒） | `2ed2792f8` |
| Queue40_L2TlbMQBundle | FM 输入收窄为实际例化闭包（L2TlbMissQueue.sv + Queue40 薄 wrapper），清掉 ram_16x137 等假依赖（Queue78 先例） | `882209fe5` |

PtwCache 改读重写 SRAM 件而不是给 golden SplittedSRAM_1/2、SRAMTemplate_128/129/143 各补证书：后者要再重证 5 个孙级、
并改两个生成器（gen_sram_wrappers / SRAMTemplateNewForm gen.py）的宽 filelist；前者与 ICache/Frontend 先例同形，
且 passing 逐位等于模型（26599），说明 SRAM 一路在 PtwCache 证明里全部进了比较。

### 1.2 证据与证书（receipt / 证书均已 `git add -f` 提交）

predict：`ok` = fm_predict 对账通过；`unreg` = 老目标没有登记文件（不算失败）。

| target | UT | 处置 | verdict | passing | predict | receipt（sha256） | 证书 sha256 |
|---|---|---|---|---|---|---|---|
| Arbiter1_L2TLBImp_Anon | L2TlbArbLeaves | 重证 | SUCCEEDED | 272 | ok | evidence/62de21a18346/Arbiter1_L2TLBImp_Anon（3ab74053a8f3b1bb8252666907b1315c2cfd1a007893c4160f9f4ef4abd8c51b） | d6f86ead944d3b9da021f84d2760f2d048fb1d864f5f2d7eaae77112a049dd7e |
| Arbiter2_L2TLBImp_Anon | ArbiterLeaves5 | 重证 | SUCCEEDED | 46 | unreg | evidence/62de21a18346/Arbiter2_L2TLBImp_Anon（7047294687fc1328b3ad8f3e19a880b558784e59880d45a16c123e9c01ff548c） | 353284bc44a4ccb8de3273b1a778ae8c0cb197c76c80b97afa9f57b12924cf32 |
| Arbiter2_L2TLBImp_Anon_1 | L2TlbArbLeaves | 重证 | SUCCEEDED | 109 | ok | evidence/62de21a18346/Arbiter2_L2TLBImp_Anon_1（10285daf16e3de68025fb46ee17e56df813be28dd98e49e6a5edd2cb05230df9） | 5aa5a6f9833093da3ad9db75c6f2f369bb35127a3c535ce7569815135e0565ce |
| Arbiter2_L2TlbWithHptwIdBundle | ArbiterLeaves5 | 重证 | SUCCEEDED | 46 | unreg | evidence/62de21a18346/Arbiter2_L2TlbWithHptwIdBundle（45662caf97be9b1b98518183034da14d31b189b583b188c5d81667a84982b77c） | d227194f67b3ac518cfc1bb5925779708f3c05fb41d8a0a1657cdb9adf391c66 |
| Arbiter2_PtwReq | ArbiterLeaves5 | 重证 | SUCCEEDED | 44 | unreg | evidence/62de21a18346/Arbiter2_PtwReq（260b82366c05a936fbfa7f73257339972f746c832aead15d2c4cd72e73c0b337） | 0fc18dc6d9ad2551efd9c7f47375db3f15ad7ca74ab0fe87f5ff6605cd7dcf2b |
| Arbiter3_bitmapReqBundle | L2TlbArbLeaves | 重证 | SUCCEEDED | 91 | ok | evidence/62de21a18346/Arbiter3_bitmapReqBundle（f1d52b43b6fa656fbfff7be522c4dd22480efbb4aa58915d699091450d112ca7） | c99c02ed54b7b50b27ce25e42c5f62d869525a0aa5bac8dacdd35f734e2a170f |
| Arbiter3_L2TLBImp_Anon | BusArbLeaves | 重证 | SUCCEEDED | 1120 | ok | evidence/62de21a18346/Arbiter3_L2TLBImp_Anon（6d92bf1b2c6dec13dd688cf62ca96d3fd1d087915943a2a702bcbb32038a4745） | 64db8d907c81bf6cc7fc2b3c8c2149fca70b5891989f4d1be8faa5f0bdb963d5 |
| Arbiter4_L2TlbMemReqBundle | L2TlbArbLeaves | 重证 | SUCCEEDED | 58 | ok | evidence/62de21a18346/Arbiter4_L2TlbMemReqBundle（0a10d93088aa8cf3ce623f084253a1fa2e84a1731e70bb6c82fe4e45137e3494） | 073074916e4ea0ded2f5a91f931fb9cad2938bc7f9c2686521745c0ff4dc3452 |
| Arbiter5_L2TlbWithHptwIdBundle | L2TlbArbLeaves | 重证 | SUCCEEDED | 55 | ok | evidence/62de21a18346/Arbiter5_L2TlbWithHptwIdBundle（40544a7ec90540c328a781ca307431d7857a4e60f919a47d69318613fae30e4c） | 225cdcc6616cbc48dbc3f3f51b25ac2a56974ffeb151491422148a3bb031b8aa |
| Bitmap | Bitmap | 重证 | SUCCEEDED | 1777 | ok | evidence/62de21a18346/Bitmap（803439f9a904310d5d879f804121f375f5f0b4413b0115e7adb3c5ec3618f1a7） | d86029f62b6059b5d86fedb60a2589fa69d869b9106679e53abe8719e65c0a39 |
| BitmapCache | BitmapCache | 改输入 + 重证 | SUCCEEDED | 1925（= 模型） | ok | evidence/882209fe5798/BitmapCache（df7d243b47a05dcc77220844bd995e176e4badaa2a84bb63964884d1b1ea027b） | 5ddd82da9bc074b4b82196cbcc7423c8f0a3207baedceced8ea7e9e86d768f2f |
| DelayN_13 | DelayN | 重证（替换 main 上 script_closure 陈旧的那份） | SUCCEEDED | 2 | unreg | evidence/62de21a18346/DelayN_13（3af76f86f6e86422471a5c09d0fd2d77955ddc28cf6b743b35508f6506fc44ce） | 7061d6d7e2a717018581e23d0035409d3c712e14015bb2b492f4009fd6dc17a1 |
| DelayN_220 | DelayN | 重证 | SUCCEEDED | 142 | unreg | evidence/62de21a18346/DelayN_220（20dbdba1afc8b77a7069c5bc89cfe98044a3eafaf0e168b2afb663170b86f763） | 839d5a109143aa534957ace5e833d3e75d25d349e2a9be5ed6761b4c698aeb6e |
| DelayN_221 | DelayN | 重证 | SUCCEEDED | 522 | unreg | evidence/62de21a18346/DelayN_221（92bb459c4af411383774c3f1eddd155bc7a2f2ad3c57abaabc25cce2014c893a） | 99daa91f9008ba03689ed95e347eb605f85373fa0589bc342974e2601a053170 |
| HPTW | HPTW | 重证 | SUCCEEDED | 506 | ok | evidence/62de21a18346/HPTW（2e38e607bc9aac107520aec8930d433c116febcf5cd0f39a58e9b60309377416） | f9e55c0059739b91e5d51ba8f1752ba94b9255acf0cd8d3267952353a3b7372a |
| L2TlbMissQueue | L2TlbMissQueue | 重证 | SUCCEEDED | 125 | ok | evidence/62de21a18346/L2TlbMissQueue（e4894d7715c469bb4ff93d4c149476eb178e7719626024e8ffbe02348cc61f41） | cdf1fd0261c6f215e6d7cafc38fb4783cf67351fb135e4781351f94bd3cf7d64 |
| L2TlbPrefetch | L2TlbPrefetch | 重证 | PASS_DEAD_REF | 223 | ok | evidence/62de21a18346/L2TlbPrefetch（d8fdaec1e1931979993c6ebcd39838ee91c72524c80a19a9bd45e6f6249e7067） | efdb720d60fd989039b4dcd677303b52f80eb7b51edb486c1d49de55e9bff7a0 |
| LLPTW | LLPTW | 重证 | SUCCEEDED | 5598 | ok | evidence/62de21a18346/LLPTW（13ffb1800ff8e954978cf961b4c00529057af930f4ec3da6fd9ede2736b1bc54） | ec9632b6b849c0dd8b59f73a8e7d34b8b5dbce43cac01231182d5895ba473466 |
| PMP | PMP | 重证 | SUCCEEDED | 13096 | ok | evidence/62de21a18346/PMP（79c9e7586667f5ac36d8b5f5b937e7a17a42bcbc053f1cfb900ca021366de7ea） | a9f8753f4402439d25ce1add5a098b40180e1f843ee5bc731c9e86b322c68bc1 |
| PMPChecker | PMPChecker | 重证 | SUCCEEDED | 3 | ok | evidence/62de21a18346/PMPChecker（6a888bf4ad48884da7f7add1614a63acf3e505b7f5d032050f305c61a40500bb） | 15b65d9f3b9cef5fcb1533e29c8b40a086753ec97f7c47f6f08f756716ff02c8 |
| PTW | PTW | 重证 | SUCCEEDED | 2820 | ok | evidence/62de21a18346/PTW（3ae49069c848f48545f750d69ee9c7622179ea75b129fd8e8236ec2d62a795e7） | dc7c5de2971707b6f240ef47d9cb1f58a1d3dd7a9b02ca4c9fa0cee2ec928081 |
| PtwCache | PtwCache | 改输入 + 重证 | SUCCEEDED | 26599（= 模型逐位） | ok | evidence/f4c4c870f0d4/PtwCache（5fd2f83d44af5bf42476917f018e2c89db4a841470ceb77e2f539081f696a01a） | 52057089f31bc8868458575e6ebec65c1d98e7353ebe68525e951200da6c8542 |
| *孙级* Arbiter2_LLPTW_Anon（LLPTW impl-golden） | ArbiterLeaves5 | 重证 | SUCCEEDED | 52 | unreg | evidence/62de21a18346/Arbiter2_LLPTW_Anon（bef1dbd971bc7a1a2115abe22dc61941d8ecf73a72b76129fe841a1650b82da2） | 55025075ca7a4105f5398548f9b857932bbc22dabf6b185c504749fa926bf23a |
| *孙级* Arbiter8_bitmapCacheReqBundle（Bitmap impl-golden） | Arbiter8_bitmapCacheReqBundle | **直接出证**（receipt 仍 current） | SUCCEEDED | — | — | evidence/397a2bc9c8d3/Arbiter8_bitmapCacheReqBundle（34e3af9ffeef298e2a426f129e57f294699da6e55a5f4c0de5831851d12d06cb） | 02155e02697cb3cc23de36c6e5fb9590141733c8b45da0f207b38e22705a6c89 |
| Queue40_L2TlbMQBundle（ram_16x137 处置） | UncoreChiQueues | 收窄 filelist + 重证 | SUCCEEDED | 125 | ok | evidence/882209fe5798/Queue40_L2TlbMQBundle（c4332006ab68f34c0b961681154facf932d451aa793688a30717138bbd2bd4eb） | 8d9a113276dfcb8dec6b5e495ba60de3926b652b331613da1ea0c42699d15790 |

PtwCache / BitmapCache 证书带 `external_dependency=MC_MEMORY_CONTRACT`。
PtwCache 第一跑（evidence/882209fe5798/PtwCache，**未收、未提交**）在钉点脚本字面计数 60 处 fail-closed：两侧 unmatched unread
实测 41，五族解析 A32/B4/C4/D1/E0、41 条 set_user_match 全部成功；按实测改 `_expect=41`（`f4c4c870f`）后第二跑 passing 26599
= 模型逐位，matched_nc 0、unread 0。

## 2. ram_16x137（not_shared）判定

- 可达性：G1 golden 里例化 `ram_16x137` 的只有 `Queue16_CHIREQ.sv`；`Queue40_L2TlbMQBundle.sv:169` 只例化 `ram_40x47 ram_ext`。
- 旧 receipt evidence/3afabfed181d/Queue40_L2TlbMQBundle 判 `green_child_impl_golden_mc_not_shared:Queue40_L2TlbMQBundle:ram_16x137`
  ——UncoreChiQueues 目录共用的 RTL_GOLDEN_DEPS（ram_16x137/ram_16x62/ram_4x115/ram_2x15）被记进了 Queue40 的 impl 闭包。
- 处置：**宽 filelist 假依赖，不登记 MC**；`fm-Queue40_L2TlbMQBundle:` 收窄为 L2TlbMissQueue.sv + Queue40 薄 wrapper（`882209fe5`），重证 SUCCEEDED 125。
- 附注：green_child 组合下 Queue40 / ram_40x47 都不在 L2TLB、L2TLBWrapper 的证明里（随 L2TlbMissQueue 黑盒化），
  ram_40x47 仍由 L2TlbMissQueue 自己的证明按 APPROVED_MEMORY_MACRO_MODEL（attrs `u`，对称未解析黑盒）承担，未进任何 hdlin_interface_only。

## 3. ★需集成者登记的 MC 行（verif/mc_memory_registry.tsv，追加 3 行）★

`python3 scripts/mc_memory_registry.py --derive <design>` 原文（class / audit 两列 derive 输出为 `?`）：

```
sram_array_1p4x786m131s1h0l1b_ptw_l1	?	sram_array_1p4x786m131s1h0l1b_ptw_l1.sv	12b982ce66cef8f888260e0fa1411988033043a620a736a1dc8be54a36a60c96	input mbist_dft_ram_bypass;input mbist_dft_ram_bp_clken;input RW0_clk;input [1:0] RW0_addr;input RW0_en;input RW0_wmode;input [5:0] RW0_wmask;input [785:0] RW0_wdata;output [785:0] RW0_rdata	4	786	131	1RW	child	child	child	wmode=en&wmode&|wmask;mask_i=wmode&wmask[i]	child	bypass,bp_clken:unconnected	array_10	?
array_10	?	array_10.sv	281c2817af3c21798a260c35a3cbafcdba2e61bc9d9940a729ba43c27c6b0b2f	input [1:0] RW0_addr;input RW0_en;input RW0_clk;input RW0_wmode;input [785:0] RW0_wdata;output [785:0] RW0_rdata;input [5:0] RW0_wmask	-	786	-	1RW	child	child	child	passthrough	child	-	array_10_ext	?
array_10_ext	?	array_10_ext.v	fe8f6db403ae1d8778c5778c3acb63dce6408dd57c521ca80715a30a7ae72f07	input RW0_clk;input [1:0] RW0_addr;input RW0_en;input RW0_wmode;input [5:0] RW0_wmask;input [785:0] RW0_wdata;output [785:0] RW0_rdata	4	786	131	1RW	sync	1	posedge RW0_clk	write=en&&wmode&&wmask[i];ren=en&&!wmode	write_cycle_no_read;rdata=ram[last_read_addr]	-	-	?
```

建议填法（与既有 array_11 / ptw_l0 / array_11_ext 行同形）：class 依次 `MC_MEMORY_MODEL` / `MC_MEMORY_MODEL` / `MC_MEMORY_BLACKBOX`；
audit `codex_0228;l2tlb-gc;PtwCache`。填好的三行（tab 分隔，可直接追加；也在 `/home/eda/xs-env/tmp-l2/mc_rows.tsv`）：

```
sram_array_1p4x786m131s1h0l1b_ptw_l1	MC_MEMORY_MODEL	sram_array_1p4x786m131s1h0l1b_ptw_l1.sv	12b982ce66cef8f888260e0fa1411988033043a620a736a1dc8be54a36a60c96	input mbist_dft_ram_bypass;input mbist_dft_ram_bp_clken;input RW0_clk;input [1:0] RW0_addr;input RW0_en;input RW0_wmode;input [5:0] RW0_wmask;input [785:0] RW0_wdata;output [785:0] RW0_rdata	4	786	131	1RW	child	child	child	wmode=en&wmode&|wmask;mask_i=wmode&wmask[i]	child	bypass,bp_clken:unconnected	array_10	codex_0228;l2tlb-gc;PtwCache
array_10	MC_MEMORY_MODEL	array_10.sv	281c2817af3c21798a260c35a3cbafcdba2e61bc9d9940a729ba43c27c6b0b2f	input [1:0] RW0_addr;input RW0_en;input RW0_clk;input RW0_wmode;input [785:0] RW0_wdata;output [785:0] RW0_rdata;input [5:0] RW0_wmask	-	786	-	1RW	child	child	child	passthrough	child	-	array_10_ext	codex_0228;l2tlb-gc;PtwCache
array_10_ext	MC_MEMORY_BLACKBOX	array_10_ext.v	fe8f6db403ae1d8778c5778c3acb63dce6408dd57c521ca80715a30a7ae72f07	input RW0_clk;input [1:0] RW0_addr;input RW0_en;input RW0_wmode;input [5:0] RW0_wmask;input [785:0] RW0_wdata;output [785:0] RW0_rdata	4	786	131	1RW	sync	1	posedge RW0_clk	write=en&&wmode&&wmask[i];ren=en&&!wmode	write_cycle_no_read;rdata=ram[last_read_addr]	-	-	codex_0228;l2tlb-gc;PtwCache
```

`array_10_ext` 已在 `verif/vendor_boundary.tsv:156`（vendor_sram_leaf，fm_blackbox_both_sides）。

试验（临时 worktree `/home/eda/xs-env/tmp-l2/wt-l2tlbgc-mctest`，临时提交 `7b4fa4aec`，不合并）：追加这三行后
`mc_memory_registry.py` → 93 行全部复算一致（array_10 / array_10_ext / ptw_l1 均 OK）；`test_mc_memory_registry.py` 全过（4 正 + 17 负）。

**可达性（G1 golden 实例图，两侧同一存储层实例）**：

```
L2TLB.sv:12347            PtwCache cache (
PtwCache.sv:43164         SplittedSRAM_1 l1 (
SplittedSRAM_1.sv:142     SRAMTemplate_128 array_0_0_0 (
SRAMTemplate_128.sv:120   sram_array_1p4x786m131s1h0l1b_ptw_l1 array (
sram_array_..._ptw_l1.sv:25  array_10 array (
array_10.sv:11            array_10_ext array_10_ext (
```

impl 侧：`rtl/common/SRAMTemplate_128.sv:79` 例化同一个 `sram_array_1p4x786m131s1h0l1b_ptw_l1 array (`（G1 同一字节，两侧共读），
其下 array_10 → array_10_ext 同链。PtwCache 证书的 impl 闭包 golden 条目恰为 sram_array_*_ptw_l0/l1 + array_10/11
（同 sha 也在 ref 闭包里 = shared），array_*_ext 不在任何一侧闭包里（对称未解析黑盒）。
不是宽 filelist 假依赖：PtwCache 的 FM 输入已按实际例化收窄（§1.1）。

## 4. 钉点登记

| 文件 | 生成器 | 计数 | 性质 |
|---|---|---|---|
| verif/ut/L2TLB/fm_pins.tcl | scripts/gen_l2tlb_pins.py（`--check` 幂等） | 128（字面 fail-closed，`L2TLB_PIN_END ok=128 bad=0`） | resp_pte_sector 8 槽×2 半×4 PTE×PTE[9:8]，精确一对一；集合与 canary 实测两侧 unread 名逐字相等（机检） |
| verif/ut/PtwCache/fm_pins.tcl | 手写（五族规则） | 41（字面 fail-closed，族 32/4/4/1/0） | 改前 60；依据 §1.2 |
| verif/ut/L2TLBWrapper/fm_pins.tcl | — | **删除** | green_child 下 L2TLB 整体黑盒，无需钉点 |

上一轮白盒路线的 147 条（含 PtwCache merge 一对多 3 条、sfence/PTE-r/sel_pte）全部作废，没有 many-to-many。

## 5. L2TLB / L2TLBWrapper 组合

配置（提交 `0f29994c8`，allow 回填 `e0f18fde2`）：

- **L2TLB**：22 种直接 child 中 21 种（28 实例）两侧 -interface_only，`FM_INTERFACE_ONLY` = 这 21 个 design，
  allow 56 个对象（r/i 各 28）逐实例写死路径 + child_target + 证书 sha256；merge_dup=true（csr/sfence 复制字段裁剪，沿用）；vmucp 开。
  **arb1（Arbiter2_PtwReq）两侧白盒**：canary 1 唯一 failing = `arb2.io_in_3_valid`（golden 接 arb1.io_out_ready & arb1.io_out_valid，
  重写核写 `tlb0_req_fire | tlb1_req_fire` 即 arb1 输入 fire 之或，依赖仲裁器内部语义）；白盒后由 FM 直接证，不改 RTL。
  FM 自动配对的 28 对黑盒实例（native_facts matched_blackbox_pairs）与 golden/重写实例表逐一对应（PMPChecker_1↔u_pmp_chk_llptw0 等）。
- **L2TLBWrapper**：ptw（L2TLB）两侧 -interface_only，allow 2 个对象；merge_dup=false；vmucp 开（无可转化点）。

| | canary 1（L2TLB，全 22 黑盒，无钉点） | canary 2（L2TLB，arb1 白盒 + 128 钉点） | canary 3（L2TLB，临时加 MC 行的试验提交） | 预测（已登记） | official |
|---|---|---|---|---|---|
| native | FAILED | SUCCEEDED | SUCCEEDED | SUCCEEDED | 待跑 |
| passing | 63006 | 63052 | 63052 | 63052 | |
| failing | 1（arb2.io_in_3_valid） | 0 | 0 | 0 | |
| constant_reg | 16 | 16 | 16 | 16 | |
| unread | 128↔128 unmatched | 0 | 0（matched_nc 0） | 0 | |
| unmatched（比较点/黑盒输出） | 0 | 0 | 0 | 0 | |
| 黑盒对象 | 58 | 56 | 56（bbox_objects=56，28 对 matched） | 56 | |
| verdict | FAILED | PARTIAL（仅因 allow 未填证书 sha） | **SUCCEEDED**（assembly 全判据：21 个 green_child 证书递归 current-valid、hdlin_interface_only 回读 = 21 design 集合） | SUCCEEDED | |

账：63052 = 63006 + 1（failing 转 passing）+ 128（钉点对经 vmucp 实比）− 83（arb1 输入引脚 83 位不再是黑盒引脚；
golden Arbiter2_PtwReq 输入 1+38+2+1+38+2+1 = 83）。fm_predict 模型 64151（merge_dup=true，只给带；63052 在带内）。

| | L2TLBWrapper canary | 预测（已登记，EXACT） | official |
|---|---|---|---|
| native | SUCCEEDED | SUCCEEDED | 待跑 |
| passing | 5139（= regs 228 + outs 3589 + 黑盒输入 1322） | 5139 | |
| failing / unread / unmatched | 0 / 0 / 0 | 0 | |
| verdict | PARTIAL（仅因 L2TLB 证书未入库） | SUCCEEDED | |

### 5.1 canary 3

在临时试验提交 `7b4fa4aec`（本分支 `e0f18fde2` + §3 三行 MC）的 worktree 里 `make fm-L2TLB`：fm_verdict 判 **SUCCEEDED**
（passing 63052 / const 16 / failing 0 / unmatched 0 / bbox_objects 56 / L2TLB_PIN ok=128 bad=0 / 无 dont_verify）。
即 §3 三行登记之后，本分支配置的 L2TLB official 预期直接 SUCCEEDED。

## 6. validate

本分支 HEAD（`e0f18fde2`）：`batch_reproof.py validate --list vall.txt`（25 目标 = 22 child + 2 孙级 + Queue40）→
24 True，PtwCache = `certificate:green_child_impl_golden_not_fm_target:PtwCache:sram_array_1p4x786m131s1h0l1b_ptw_l1`。

临时试验提交 `7b4fa4aec`（= `e0f18fde2` + §3 三行）：**25/25 True**，`不通过 0 个`。

### 6.1 整条链预演（临时 worktree，临时提交，不合并、证据不收）

在 `7b4fa4aec` 上用 run_proof.sh 跑 L2TLB（与正式流程完全相同，只是钉在临时提交上）→ 出证 → stamp L2TLBWrapper allow →
临时提交 `3eac7b235` → run_proof.sh L2TLBWrapper → 出证 → 临时提交 `14944628a`：

| | L2TLB 预演 | L2TLBWrapper 预演 |
|---|---|---|
| fm_verdict | SUCCEEDED（assembly，bbox_objects 56） | SUCCEEDED（assembly，bbox_objects 2） |
| passing | 63052 | 5139 |
| constant_reg / failing / unmatched / unread | 16 / 0 / 0 / 0 | 0 / 0 / 0 / 0 |
| 证书 external_dependency | MC_MEMORY_CONTRACT（via BitmapCache, PtwCache） | MC_MEMORY_CONTRACT（via L2TLB） |

`batch_reproof.py validate`（27 目标 = 25 + L2TLB + L2TLBWrapper）在 `14944628a` 上 **全部 True，不通过 0 个**。
即：§3 三行登记后，按 §7 在本分支上重跑一遍即得正式证书，数字应与上表逐项相同。
（预演证据与临时 worktree 已删除；临时提交未进任何分支。）

## 7. 剩余步骤（§3 三行进 main 之后）

1. 把含三行的 main 合入 `agent/l2tlb-gc`（或集成者在合并本分支时一并处理）；`batch_reproof.py validate` 25/25 True。
2. 在该提交 P 上：`PROOF_COMMIT=P TMPDIR=… bash scripts/run_proof.sh L2TLB L2TLB < /dev/null`
   → 须与预测逐项相同（native SUCCEEDED / passing 63052 / const 16 / 全零 / 56 黑盒对象 / ok=128）→ `fm_predict.py check L2TLB`
   → `make_proof_certificate.py --repo . --evidence evidence/<P12>/L2TLB` → `--stamp-allow verif/allow/L2TLBWrapper.json` → 提交（evidence `git add -f`）。
3. 在新提交 Q 上：official L2TLBWrapper → 须 passing 5139 EXACT → 证书 → 提交。
4. validate 整树（25 + L2TLB + L2TLBWrapper）在 HEAD 上全部 True。
任何 official 与上表不同即 STOP。
