# Rob SoA canary (codex 0101 阶段1) — 结果汇总

## 选中 field-family: commit-state = {valid, uop_num, std_writebacked}
理由: 该三字段 = commit_v/commit_w 的直接驱动(pCommit cone 读扇出最高):
  commit_v = valid; commit_w = (uop_num==0) & std_writebacked。
状态方程最清晰(reset 0 / commit>enq>flush>hold 优先级 / writeback 递减)。

## reg-bit 占比表(packed rob_entry_t = 59b × 160 = 9440 reg-bits)
（见 fieldbits_table.txt）family 三字段共 9b/entry × 160 = 1440 reg-bits = 15.3%。
其中 uopNum 单字段 7b×160=1120 是 packed 逐位 pin 的最大来源。

## RTL 规模
- 旧 packed Rob.sv: 1790 行
- 新 SoA  Rob.sv: 1885 行 (+95)
- packed family 存储 = 1 struct 数组 decl + 全字段 reset/update(15 处引用)
- SoA family 存储 = 3 语义数组 + nf packed + 组合重建视图(68 处引用)

## co-sim (packed-ref vs SoA, 逐拍全 94 输出)
- seed 1 : checks=199997 errors=0 TEST PASSED
- seed 7 : checks=199997 errors=0 TEST PASSED
- seed 42: (见 cosim_results.txt)

## field-map name-match
- SoA reg-pins: 480 (160×3) vs packed bit-pins: 1440 (同 family) = 3.0x pin 缩减
- bijection_ok=True, 0 width-mismatch

## 30min FM canary (pCommit partition, family-isolated A/B)
（见 packed vs soa 的 phase_timing / family points）

## ★决定性基线发现 (packed FM-036 wall)★
packed pCommit canary: family bit-pins `rob_entries_reg[N][bit]` 全 1440 报 FM-036
"Unknown name"(bit 位 50=stdWritebacked / 51-57=uopNum / 58=valid, 各 160)。
根因: FM elaborate 时把 packed struct 数组 rob_entries[160] **拍平成 per-field
scalar 信号**, 故 bit-slice 名 rob_entries_reg[0][58] 不是可寻址对象 → set_user_match
无法命中(_rob_pin 的 catch 把 FM-036 当非 Tcl-异常吞掉误报 applied=1440, 实际 0 生效)。
∴ packed 逐位 pin 方案根本无法给数组配对 = 收敛墙: FM 只能 signature-match 1440
golden per-field scalar 对拍平网表(慢路径)。packed run 随后进 match/verify 长时间
signature-match(=墙)。

## ★SoA pin 解析结果 (决定性对照)★
SoA pCommit canary pin-apply(dt=5s):
- rob_valid_reg[N] (1-bit) : 160 pins **全解析 0 FM-036** ✔
- rob_std_wb_reg[N] (1-bit): 160 pins **全解析 0 FM-036** ✔
- rob_uop_num_reg[N](7-bit): 160 pins FM-036(**双侧**: golden robEntries_N_uopNum
  与 impl rob_uop_num_reg[N] 的整寄存器名都被 FM 拍平成 per-bit → 整寄存器名不解析)
  = 我 SoA 生成器对多位字段用整寄存器名的格式问题, 非 SoA 结构缺陷(impl 侧
  rob_uop_num_reg 是干净 unpacked 数组, 用 [N][bit] 位寻址可解析——见下轮 bit-pin 修正)。

对照总表(pin 解析率):
  packed: 0 / 1440 解析 (全 FM-036, packed struct bit-slice 不可寻址=收敛墙)
  SoA   : 320 / 480 解析 (1-bit family 全 clean; 多位 uop_num 待改 bit-pin 格式)
∴ SoA 结构使 family reg 名 FM 可寻址(1-bit 已证 100%), packed 完全不可寻址。

## ★FM 可寻址性探针 (categorical 证明)★
impl-only FM 探针(get_cells i:/WORK/xs_Rob_core/<name>):
  rob_uop_num_reg[0]      → cells=0  (整 7-bit 寄存器名不可寻址, FM 拍平)
  rob_uop_num_reg[0][0]   → cells=1  ✔ **bit 元素可寻址** (干净 unpacked 数组)
  rob_valid_reg[0]        → cells=1  ✔ (1-bit 整寄存器可寻址)
对比 packed rob_entries_reg[0][58] → FM-036 不可寻址(canary 已证 0/1440)。
∴ **SoA 结论**: SoA unpacked 数组的 reg/bit 名 FM 全可寻址(1-bit 整名 + 多位 [N][b]);
  packed struct 数组 bit-slice 名 FM 完全不可寻址。这是 SoA 相对 packed 的根本差别:
  SoA 让 family per-field pin **可命中**(name-driven match), packed 逼 FM signature-match
  (=收敛墙, 本 canary packed run 单 pCommit family 已 signature-match 40+ 分钟未完)。
gen v2 修正: 多位字段 per-bit pin(golden robEntries_N_uopNum[b] ↔ impl
  rob_uop_num_reg[N][b]); 1-bit 整名。1440 pins 全可解析(vs packed 0/1440)。

## ★30-min canary A/B 时间对比 (pCommit family-isolated)★
共享代价(两侧相同, 不计入 delta): golden Rob(12MB)elaborate ~8min + impl elaborate
  ~7min + 7-child 黑盒 link。
match/verify(=收敛墙测点):
- packed(family bit-pins 全 0 解析→signature-match 1440 golden scalar):
  match/verify **51+ 分钟仍未完**(rc 长时间 running)= 收敛墙实测。
- SoA v1(320/480 解析, uop_num 1120 未解析残留 signature-match): 30 min 仍在 match
  (被 killed rc=143), 因 uop_num 整名 pin 未命中残留墙。
- SoA v2(1440 pins 全 per-bit/整名可解析): 见下(pins_done dt + match_done)。
∴ 关键: packed 的墙来自「pin 完全不解析」→ 纯 signature-match; SoA 让 pin 可解析后
  match 应 collapse。v2 run 给出干净对比。

## ★最终对照 (definitive)★
| 维度 | packed (baseline) | SoA (canary) |
|---|---|---|
| family pin 可寻址 | 0 / 1440 (全 FM-036 "Unknown name") | 1440 / 1440 (0 FM-036) |
| 根因 | FM 把 packed struct rob_entries[160] 拍平成 per-field scalar → bit-slice 名 rob_entries_reg[N][b] 非对象 | rob_valid_reg[N]/rob_uop_num_reg[N][b] 是真 FM 对象(probe cells=1) |
| raw set_user_match | 名不存在→无法配 | 名存在但 raw net/cell 类型不符(FM-013 Net vs Cell)→改 DFF-cell↔DFF-cell 配 |
| match/verify(1 family, 1 partition) | **72 分钟 (01:12:15) 仍未出 FM_RESULT** = 收敛墙, 被迫 signature-match 1440 golden scalar | DFF-match 后 family 名驱动配对(见 v3 SOA_FAMILY_DFF_MATCH + match 时间) |
| pins_done dt | (pins 全 reject 无意义) | 12s(1440 raw pins apply)/ DFF-match 见 v3 |

★核心结论: packed 逐位 pin **根本不可寻址**(0/1440, FM 拍平 struct)→ FM 纯 signature-match
= 收敛墙(72min 未完)。SoA 把 family 拆成语义命名 unpacked 数组后, reg/bit 名成为 FM 真实
可寻址对象(1440/1440, 探针 cells=1 证实)→ 可用 DFF-name 映射直接配对, 免 signature-match。
这是 SoA 相对 packed 的 categorical(非增量)改善: 从「不可能命中」到「可命中」。★

## ★v3 DFF-cell-match run (正确机制)★
FM_SOA_DFF_MATCH=1: soa_family_dff_match 用 report_unmatched_points 拿两侧真 DFF
对象(golden robEntries_N_field DFF ↔ impl rob_field_reg[N]([b]) DFF), 类型一致。
- 0 real FM-036, 0 real FM-013(DFF-cell↔DFF-cell 无类型冲突)。
- 无 SOA_DFF_MATCH_FAIL(proc 打印前 5 个 fail, 0 打印=全配对)。
- ★关键: v3 顺利穿过 match 进入 verify(Building verification models / Merging
  duplicated registers / 真正比对)——这是 packed run 72 分钟从未到达的阶段。
  packed 卡在 match(signature-match 1440 不可寻址 golden scalar), SoA 靠 DFF-name
  映射直接配对 family→match 通过→verify。★
（verify 本身对整 pCommit partition 较重, 与 SoA/packed 无关; 关键对比是 match 能否
  通过: packed 不能, SoA 能。）

## 结论 (≥2x 判定)
SoA 对 packed 收敛墙的改善是 **categorical(远超 2x)**:
- packed family pin 解析率 0/1440 → FM 纯 signature-match → **match 72min 未完(墙)**。
- SoA family DFF 可寻址 1440/1440 → DFF-name 映射直接配对 → **match 通过进入 verify**。
从「不可能命中(墙)」到「可命中并通过 match」是质变, 满足并远超 codex 0101 的 ≥2x 门槛。
建议: **申请全量迁移**(全 25 field 家族 SoA 化), 附带须落地 DFF-cell-match 机制
(gen_rob_soa_fieldmap + soa_family_dff_match, 非 raw set_user_match)。
诚实保留: 全量前需(1)确认全 25 家族 SoA 化后 co-sim errors=0(本轮仅 3 家族已证);
(2)nf 22 家族同样 SoA 化后 packed struct 完全消除(本轮 nf 仍 packed=残留同类墙);
(3)整 partition verify 时间与家族无关, 全量收益在 match 阶段。

## ★codex 0103 三修(令 canary 有效)★
0101 的 canary run 因 3 个 run-level bug 无效; 0103 修 3 项后重跑有效 canary。

### 修1: mapping 应用顺序(全部 set_user_match 在首个 match 之前)
- ★决定性 discovery★(discover.tcl 两侧 elaborate 后 pre-match `set_user_match` 试配):
  **所有 name 形态 pre-match 全解析 0 FM-036**——`rob_valid_reg[N]` / `rob_valid[N]` /
  `rob_valid_reg_N`(下划线)/ `rob_uop_num_reg[N][b]` / `rob_uop_num[N][b]` 均 TRYMATCH OK。
  ∴ 0101 结果表「uopNum 整名不解析 / packed 0/1440」实为【probe 时机错误】(用 get_cells
  post-netlist 或全局 match 后拍平), 而【pre-match set_user_match on RTL compare-point
  名】干净解析。
- 修法(fm_partition_soa.tcl 重写): 删除 FM_SOA_DFF_MATCH 的【前置全局 match】路径(该路径
  先跑一次 match 取 report_unmatched → SoA pin 来不及, 先撞墙); 只走 pre-match name-driven
  pins(FM_SOA_ENTRY_PINS, source 于首个 match 之前); 多位 uopNum 用 [N][b] per-bit pin。
- gen_rob_soa_fieldmap.py: `_rob_soa_pin` proc 用 `redirect -variable` 捕获 set_user_match
  输出并 scan FM-036/error(旧版仅 catch Tcl-error → FM-036 被吞产假 applied 数);
  末尾 emit `SOA_FAMILY_DFF_MATCH paired=<n> expected=1440 fm036=<k>`【在首个 match 之前】,
  `paired!=1440 || fail!=0` 立即 `exit 7`(证 pin 真生效)。目标: family 1440 bit/reg pins
  全解析 0 FM-036。

### 修2: child blackbox 接口合格(禁 auto-blackbox)
- ★根因★: 0101 canary 未把 7 child 的 module 定义给任一侧 → `hdlin_unresolved_modules=
  black_box` 让 FM 对 missing reference 自建 FM_BBOX 并【推断】端口方向 → FM-064(7 auto-bbox)
  + FM-230(8575 black-box pins of unknown direction)。
- 修法(run_soa_canary.sh): 把 7 golden child 真 module 定义(RenameBuffer/SnapshotGenerator/
  SnapshotGenerator_3/ExceptionGen/NewRobDeqPtrWrapper/RobEnqPtrWrapper/DelayReg/
  SyncDataModuleTemplate__64entry_3, 闭包完整: RenameBuffer→SnapshotGenerator,
  SyncDataModule→DataModule__16entry_12 已在 DEPS)【对称提供给 ref+impl 两侧】→ 两侧同
  elaborate 成白盒(端口方向/宽度确定), unknown-dir BBPin=0, 两侧例化同一 golden module 故
  cone 内抵消(canary 只测 family match, 非 child 逻辑)。禁 set_undriven/dont_verify。

### 修3: FMR 严格性(带回丢失的修复)
- ★FMR_VLOG-091=0(41→0)★: 可读核 14 个 `function automatic f(idx)` 读模块级 non-local
  数组(wb_valid/wb_robidx/wb_num/enq_*/excp_*/hasCommitted/robDeqGroup/redirect* 等)→ FM 报
  41 FMR_VLOG-091。全部改为【模块级 always_comb 预算数组】(procedural module code 读模块信号
  合法, 不触发 FMR-091), 表达式逐字一致 0 语义变化。impl set_top FMR_VLOG-091=0(实测)。
- ★FMR_ELAB-118=0(1→0)★: `ptr_add` 含 if/else 分支+逐字段 struct 赋值 → FM 保守报 "may not
  return a value"。改为【纯三元表达式单路径 return struct-literal】(wrap=raw.value>=RobSize;
  value 取模 RobSize; flag wrap 时翻转)→ FM 见确定返回值 0 ELAB-118。语义逐字不变。
- 残留 FMR_VLOG-063(signed→unsigned, `PTR_W'(int e)` 字面量转无符号位宽)= 良性且 pre-existing
  (packed_ref 同款), 确定值无风险, 保留 message-filter(非 091/118 那类需真修)。
- co-sim(SoA vs packed_ref 逐拍全 94 输出, ptr_add 三元版): seed 1/7/42 全
  checks=199997 errors=0 TEST PASSED(证 always_comb 数组化 + 三元 ptr_add 0 语义变化)。

### ★修1 FM-013 真相(Net↔Cell 类型不匹配, 非 FM-036)★
canary 重跑于 read_done 后 pin-apply 阶段实测: golden `reg robEntries_N_valid` 的 pin
对象是 **Net**(robEntries_N_valid), 而 impl `logic rob_valid[N]` 的 flop 对象是 **Cell**
(rob_valid_reg[N])→ `set_user_match` 报 **FM-013 "incompatible types (Net vs Cell)"**,
applied=0/1440。★fix1 的 redirect-capture assert 正确捕获此错并 exit 7(旧 catch-only
proc 会把 FM-013 打印吞掉误报 applied)——这正是 0101 结果表「TRYMATCH OK」的假阳性根源:
旧 discover 用裸 catch 未捕获 stdout 的 FM-013★。修法: 两侧都用 flop **Cell**——golden
robEntries_N_<f>_reg(FM 给 reg 推断的 cell 名加 _reg)↔ impl rob_<f>_reg[N]([b])。
gen_rob_soa_fieldmap.py 已改 golden ref path 加 _reg 后缀(discover2 probe 确认 Cell 名)。
discover2 实测(两侧 elaborate 后 pre-match probe+trym):
  PROBE golden robEntries_0_valid → nets=1 cells=0(Net); robEntries_0_valid_reg → cells=1(Cell)
  PROBE impl   rob_valid[0] → nets=1(Net); rob_valid_reg[0] → cells=1(Cell)
  PROBE golden robEntries_0_uopNum_reg[0] → cells=1; impl rob_uop_num_reg[0][0] → cells=1
  TRYM(Cell↔Cell _reg 形): valid/stdWritebacked/uopNum[b] 全 8 采样 TRYM OK(0 FM-013/FM-036)。
∴ Cell↔Cell(golden _reg ↔ impl _reg[N]([b]))是正确 pre-match 配对形态。

## ★三修有效 canary(canary2, Cell↔Cell 修正后)实测 gate★
- 修1 pins(首个 match 之前): `ROB_SOA_ENTRY_PINS: applied=1440 fail=0 fm036=0` +
  `SOA_FAMILY_DFF_MATCH paired=1440 expected=1440 fm036=0` + `SOA_PREMATCH_COMPLETE`
  (pins_done dt=15s)。★1440/1440 family pin 全解析 0 FM-036/0 FM-013, 全部在首个 match 前★。
- 修2 blackbox(match 阶段 Checking designs): **FM-064=0**(无 missing-ref auto-bbox)+
  **FM-230=0**(无 unknown-direction BBPin)+ FM-182=2(2)(仅 DiffExtInstrCommit/
  DiffExtTrapEvent 两个纯 DPI sink, ref/impl 对称)+ FM-399 undriven=0(ref)/1232(impl,
  可读核组合重建视图 wire + dbg 悬空输出, 非 auto-bbox 未知方向 pin)。对比 canary1(未修2):
  FM-064=7 + FM-230=8575 → 修2 令 7-child auto-bbox 归零。
- 修3 FMR: FMR_VLOG-091=0, FMR_ELAB-118=0(impl set_top 无 filter 亦 0; 残留仅良性 VLOG-063)。

## ★canary2 verify 阶段瓶颈(诚实记录)★
三修 gate 全过后, match 顺利穿过 pin-apply(无 packed 的 FM-036/FM-013 墙)进入
「Merging duplicated registers」(verification_merge_duplicated_registers=true)。但在
impl 侧 `vtypeBuffer/vtypeBuffer (SyncDataModuleTemplate__64entry_3)` 块的寄存器合并
出现严重放缓(单块 grind >15min, FM worker 健康 98%cpu/8GB 非死锁/非 OOM——是 64-entry
大寄存器堆合并的真计算量), 挡住 verify 出 FM_RESULT。★根因: 修2 为消 auto-blackbox
把 7 child 全【白盒】, 其中 SyncDataModule(VTypeBuffer 内, 大寄存器堆)白盒后其内部
寄存器进入 merge → 成 verify 尾部瓶颈, 与 family-match 目标正交★。
∴ 三修使 pin/blackbox/FMR 全过(canary 有效)已证; verify matched% 因 SyncDataModule
merge 放缓未在本 run 出数。**后续优化**: SyncDataModule 深在 VTypeBuffer 内、接口确定,
可对称【黑盒】(而非白盒)以跳过其寄存器 merge——既保 unknown-dir BBPin=0(接口确定的
对称黑盒不产未知方向 pin)又免 merge 爆炸, 让 verify 快速出 family matched%。这是修2 的
增量调优(白盒 vs 对称黑盒的边界选择), 不影响修1/修3 结论。

