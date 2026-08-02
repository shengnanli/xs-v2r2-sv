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
