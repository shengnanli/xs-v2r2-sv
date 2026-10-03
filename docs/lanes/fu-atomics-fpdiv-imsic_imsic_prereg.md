# fu-atomics-fpdiv-imsic lane · sub=imsic（IntFile → IMSIC）—— 跑前登记

FM 起跑之前提交；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。
口径同 `docs/lanes/fu-atomics-fpdiv-imsic_prereg.md` §0（signoff-strict，FM_MERGE_DUP=false，allowlist 空）。

## 1. IntFile（IMSIC 的一个中断文件，golden 863 行 / 16 端口 / 10 reg×64 位，无子模块）

- 核 `rtl/uncore/IntFile.sv`：§1 CSR 间接访问（wdata/wmask 按 op、10 个地址查表、illegal 奇数号）/
  §2 MSI 置位 / §3 topei 优先级（256 位最小置位序号 + 阈值过滤）与 pending、claim；
  eip 一拍内写优先级 claim > seteipnum > CSR（照 golden）。寄存器 10 个 ×64 位全部异步复位 0，与 golden 逐字对齐。
- UT `verif/ut/IntFile`：9 档全部 checks=1000000 errors=0；覆盖 10 地址 × 3 合法 op 写各桶 ≥ 200，
  claim 命中 / topei 非 0 / 被阈值滤 0 / pending / illegal / illegal_priv 单独拉起 rdata_valid 各 ≥ 200。
- 变异自证（seed 7 × 20k）：M1 阈值比较 <= 改 < errors=99；M2 eip0.bit0 不清零 errors=305；M3 illegal 不看奇偶 errors=11392；
  M4 优先级取最大序号 errors=21847；M5 pending 不看 eidelivery[63:1] errors=0 —— ★等价变异★（eidelivery[63:1] 恒 0，
  golden 与核都只写 bit0；UT 按构造不可达，FM 两侧同为常量寄存器）。
- **预测**：模型 expected=715（寄存器 640 + 输出 75）。可指认缺口：eidelivery[63:1] 两侧都恒 0 ⇒ constant_reg **63**；
  预测 passing = **652**，failing / unverified / unread / unmatched 全 0，无黑盒，SUCCEEDED。登记 `docs/fm_predictions/IntFile.json`。
- 可能出错处：核用数组 eips[4]/eies[4]，golden 扁平 eips_0..3；共 8 个 64 位寄存器靠名字/签名匹配，若 unmatched 先查配对。

## 2. IMSIC（per-hart AIA 中断控制器，golden 526 行 / 23 端口 / 28 reg）

- 核 `rtl/uncore/IMSIC.sv`：§1 illegal_priv 与文件选择 one-hot / §2 网关 + 9 个 IntFile（seteipnum 两拍拉宽、guest claim 按 vgein+1）/
  §3 rdata/illegal 打一拍后按位或、topeis 包装（guest 按 vgein[2:0]-1 回绕选）。寄存器：rdata 打拍 9×65 位（无复位）、
  msi_valid_delayed 9 位（异步复位 0）、illegal 打拍 1 位（无复位），与 golden 逐字对齐。
- child：IntFile ×9（本 sub 重写）、IMSICGateWay（本仓 PROVEN_DIRECT）两侧白盒；网关内 AsyncResetSynchronizer* 两侧同源 elaborate
  （与 verif/ut/IMSICGateWay 同做法）。无黑盒。
- UT `verif/ut/IMSIC`：seed7×20k 快跑 checks=199980 errors=0；9 档读数在对账节追加。覆盖：9 个文件各自读命中/收 MSI/claim 命中、
  7 个 guest topei 选择各非 0、illegal。复位撤销后前 2 拍不比（无复位打拍寄存器）。
- 变异自证（seed 7 × 20k）：M1 MSI 置位不拉宽两拍 errors=141；M2 guest claim 不查 vgein+1 errors=21545；M3 vgein<8 放宽成 <9 errors=17；
  M4 guest 选择改用 3'(vgein-1) errors=0 ★数学等价（低 3 位减法）★；M5 写选择不要求 op!=0 errors=0 ★等价（op=0 时 IntFile 的 wmask=0 本就不写）★。
- **预测**：模型 expected=6548（寄存器 6376 + 输出 172）。可指认缺口：9 个 IntFile 的 eidelivery[63:1] ⇒ constant_reg **567**；
  预测 passing = **5981**；其余全 0；无黑盒；SUCCEEDED。登记 `docs/fm_predictions/IMSIC.json`。
- 可能出错处：核内部 topeis 用 unpacked 数组端口、九个文件用 generate 命名 g_file[i].intFile 对 golden intFile_i，靠签名匹配。

## 对账（跑后追加；上文数字不改）

| 目标 | 预测 passing | 实测 passing | 预测 constant_reg | 实测 constant_reg | failing/unmatched/黑盒/dont_verify | verdict |
|---|---|---|---|---|---|---|
| IntFile | 652 | **651** | 63 | **64** | 0/0/0/否 | SUCCEEDED（证明 commit d18495248b31） |
| IMSIC | 5981 | **5972** | 567 | **576** | 0/0/0/否 | SUCCEEDED（证明 commit d18495248b31） |

- **差额指认**：每个 IntFile 多 1 个常量寄存器，登记时漏数了 **eies_0[0]**。golden 里它的复位值为 0，唯一写入口是
  CSR 写 `& 64'hFFFF_FFFF_FFFF_FFFE`（bit0ReadOnlyZero），没有任何别的通路置位它，所以两侧都恒 0。
  对照组 eips_0[0] 虽然 CSR 写同样清 bit0，但 seteipnum=0 能置位它，所以不是常量；漏数的原因就是把两者当成了同一类。
  IMSIC 的差额 9 = 9 个 IntFile × 1，同一原因，没有其他差额。
- `fm_predict.py check` 两目标 rc=0（差额 = constant_reg，全部被指认）。
- IMSIC UT 9 档：全部 checks=1999980 errors=0 bad_cov=0（seed 1/7/42 × initreg 0/random/<seed>017 × 200k）。
- receipt sha256：IntFile `57e0d1d4aebfc6bd8080f09d6af5b961caaa8706c8ddc88756b40e186523fab3`，
  IMSIC `5685941138380d672c4e36022acb83e26d759ad76bd77b193b15a160cc1bc122`。
