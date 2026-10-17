# xscore-xstile-asm lane（agent/xscore-xstile-asm）—— XSCore / XSTile 装配，"只差 official"

本文件各节在 official 起跑**之前**提交；official 跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | main `b16eafd75` + 认领 `eecc8a183`；工作树 `/home/eda/xs-env/wt-xscore-xstile-asm`，分支 `agent/xscore-xstile-asm` |
| golden | `G1-canonical/golden-rtl/XSCore.sv`（13,423 行 / 374 端口 / 3 实例 / sha256 c8c5b2c2…）、`XSTile.sv`（2,077 行 / 150 端口 / 6 实例 / sha256 03e1da00…），与 `XiangShan/build/rtl/` 同名文件逐字节相同（只读） |
| 证明形态 | codex 0226 exact green_child（同 MemBlock / Backend）：全部直接子模块两侧 `-interface_only`，`FM_MODE=assembly`，`FM_MERGE_DUP=false` |
| 口径 | 无 dont_verify / 无 vmucp / 无 dead_ref / 无钉点 / 无 set_mismatch_message_filter / 无放宽 appvar |

## 1. 重写件：纯连线，没有可读核

实测 golden 两个模块**本层没有任何逻辑**：0 个寄存器、0 个 always；XSCore 0 条 assign，子模块之间 2634 根线全部直连；
XSTile 408 根线 + 2 条直通 assign，接线形状只有直连 / 位截取（`_l2top_io_hartId_toCore[5:0]`、`robHeadPaddr_bits[35:0]`）/
高位补零（`{58'h0, io_hartId}`）/ 常量（`io_l2_flush_done = 1'h0`）/ 悬空（`io_l2_flush_en`、`io_power_down_en`）。

所以这里**没有 `xs_XSCore_core` / `xs_XSTile_core`，也没有钉点文件**（没有寄存器可钉）：按 Backend / MemBlock 的分工
"纯连线形状在 wrapper、有运算或寄存器的进 u_core"，这两层一样运算都没有，核只会是空壳。先例 `rtl/frontend/MbistIntfFrontend.sv`
（纯连线无核）。★任务书写的是"仿照 u_core 结构"，这里偏离了——理由如上，请集成者确认★。

- `rtl/xstile/XSCore.sv`、`rtl/xstile/XSTile.sv`：整份由 `scripts/gen_xscore_xstile.py` 生成（`--check` 幂等）。可读性落在分组与注释：
  子模块之间的线按"驱动实例 → 读者"分组声明，命名 `<驱动实例>_<端口>`；每个子模块的接线按"从谁来 / 到哪去"分组，
  每组一句手写说明（PEER_DESC，生成器要求每个出现的组合都有说明、每条说明都被用到），组内按总线前缀列位宽小计；大文件导航按
  `gen_file_nav.py` 同一算法生成。fail-closed 规则见生成器头（端口集合 / 位宽 / 来源形状 / 每根线一个驱动 / 顶层输出全覆盖）。
- `python3 scripts/readability_audit.py`：A~G 全 0（rc=0）。

## 2. 子实例证书清单（`batch_reproof.py validate`，HEAD `eecc8a183` 上逐个复核）

| 父 | 实例 | design | current-valid | 说明 |
|---|---|---|---|---|
| XSCore | frontend | Frontend | ✔ True | allow 已盖 sha d5730066… |
| XSCore | backend | Backend | ✘ `certificate_not_in_commit:Backend` | agent/backend-asm 收尾中（official 已 native SUCCEEDED 280043，verdict 卡在 CtrlBlock / ExuBlock 证书判据）；allow 两条为 `PENDING_CERTIFICATE` |
| XSCore | memBlock | MemBlock | ✔ True | allow 已盖 sha 1ed40e7e… |
| XSTile | core | XSCore | ✘ 无证书 | 本 lane，official 等 Backend 证书 |
| XSTile | l2top | L2Top | ✔ True | allow 已盖 sha fd732f50… |
| XSTile | intBuffer / intBuffer_3 | IntBuffer_1 | ✘ `certificate_not_in_commit:IntBuffer_1` | 已有 tracked receipt `evidence/64f5633a1e77/IntBuffer_1`（SUCCEEDED）；`make_proof_certificate.py --print-only` 通过 |
| XSTile | intBuffer_1 | IntBuffer_2 | ✘ `certificate_not_in_commit:IntBuffer_2` | 同上，`evidence/64f5633a1e77/IntBuffer_2` |
| XSTile | intBuffer_2 | IntBuffer | ✘ `certificate_not_in_commit:IntBuffer` | 同上，`evidence/1bf831352049/IntBuffer` |

结论：XSCore 只缺 Backend（与预期一致）；XSTile 缺 XSCore（本 lane）与三个 IntBuffer 的证书。三个 IntBuffer 都**不需要重写或重证**，
只差从现有 receipt 出证——它们不在本 lane 认领范围，本 lane 没有出证、没有提交它们的证书，交集成者（命令见 §6）。
L2Top 用的不是全黑盒组合（`FM_INTERFACE_ONLY = TL2CHICoupledL2`），但证书 current-valid，作 green_child 引用不受影响。

## 3. UT（verif/ut/XSCore、verif/ut/XSTile）

双例化 golden `<T>` 对派生 `<T>_xs`，**两侧子模块是同一份 golden 定义**（RTL_GOLDEN_DEPS = golden 的整棵子树：XSCore 1450 个文件，
XSTile 1660 个（含 golden XSCore）；ClockGate 用本地件；清单由 `gen_xstile_closure.closure()` 算）——只比本层接线，与 FM 的
green_child 组合同构（取舍同 MemBlock UT）。初值只跑 `+vcs+initreg+0 / +1`（双例化不用 random）。每档 200k 拍。

一档的判据（`make ut SEED=<s> INITREG=<v>` = run + `gen.py --covcheck`，两条都过才算）：
1. tb：顶层全部输出逐拍 4 态 `!==` 比较 errors=0，且 COVERS 每项 >0；
2. **tb_pins.sv（本 lane 新加）**：两侧每个子模块的**每个输入引脚**逐拍 4 态比较 errors=0（XSCore 2616 个引脚 / XSTile 356 个）。
   纯连线层的接错只要源端动过就当拍可见，不必等它传到顶层输出（输出比对对接线的可观测性很差：例如 perf 事件、中断线接反，
   输出可能几万拍都不变）。

翻转数**只报告、不设门限**：门限贴着实测值设是假闸（CONVENTIONS「门限卡在实际能过的那个数」），按名字逐条写豁免原因又需要逐条观测
（没做）。未翻转的输出 / 引脚全部是 FM 的比较点（本层没有一个点不在比较锥里），接线正确性由 FM 证明。

COVERS（跨子模块主通路，golden 内部线 >0 拍）：
- XSCore：icache_req（frontend→memBlock TL A）、icache_resp（memBlock→frontend TL D）、cfvec（frontend→backend）、redirect（backend→frontend）、
  lsq_enq（backend→memBlock）。
- XSTile：immio_a（core→l2top 指令 uncache A）、trace_v（core→l2top）、msi_v（l2top→core）、int_clint / int_plic / int_debug / int_nmi（IntBuffer→core）。

UT 走不到的（20k 拍探针实测为 0，已从 COVERS 拿掉，★原因没有查明，不在这里猜★，记为待办）：
- XSCore：ITLB→PTW 请求 / 回应、load 发射 / 写回 / 唤醒——LSQ 入队有几百次但没有一条 load 走到发射；
- XSTile：核只走指令 uncache 取指，ICache / L1D / PTW 的 TileLink A 一次都没有（同样的复位向量在 XSCore UT 里会走 ICache），
  L2 拿不到合法 CHI 回包、D 通道无回包。

结果见 §7（UT 在 commit 2051e19c1 及其后 XSTile 覆盖项调整的 tb 上跑；RTL 自 885a1decf 起未改）。

## 4. allow

- `verif/allow/XSCore.json`：6 条 green_child（3 实例 × r/i），frontend / memBlock 证书 sha 已 `--stamp-allow` 盖；backend 两条
  `certificate_sha256 = PENDING_CERTIFICATE`（★待填★：Backend 证书入库后回填）。
- `verif/allow/XSTile.json`：12 条 green_child（6 实例 × r/i），l2top 已盖；core（XSCore）与 4 个 IntBuffer 实例为 `PENDING_CERTIFICATE`（★待填★）。
- 占位值不是合法 sha256，fm_verdict 在证书判据上 fail-closed（canary 实测 PARTIAL，见 §5）。

## 5. FM canary（工作树、不产 receipt）

| 跑 | 字节 | 黑盒 | native | passing | failing | unmatched | verdict（首个原因） | 用时 |
|---|---|---|---|---|---|---|---|---|
| XSCore canary | 885a1decf；impl 侧 Backend 读 agent/backend-asm `4dc41afc6` 的 `rtl/backend/Backend.sv` 快照（sha256 45450124…，interface-only） | 3 实例 × r/i，Frontend / Backend / MemBlock | **SUCCEEDED** | **99241**（BBPin 31381 / Port 67860） | 0 | 0(0) | PARTIAL：`assembly_green_child_certificate_not_in_commit:Backend` | 73.6 min |
| XSTile canary | 052f7bc9b | 6 实例 × r/i，XSCore（读本 lane 重写 wrapper）/ L2Top / IntBuffer×3 种 | **SUCCEEDED** | **71909**（BBPin 5457 / Port 66452） | 0 | 0(0) | PARTIAL：`assembly_green_child_certificate_not_in_commit:XSCore` | 22.4 min |

两跑 make_receipt 均拒绝出 receipt（工作树 dirty），证据目录未提交。verdict 已走到证书判据，说明观测黑盒集合与 allow 逐对象相等、
无 dont_verify / elab147 / relaxed appvar。

预测（`docs/fm_predictions/XSCore.json`、`XSTile.json`，在 052f7bc9b 登记，模型 = 寄存器 0 + 顶层输出位 + 黑盒输入位）：

| 目标 | 预测 | canary 实测 | 差 |
|---|---|---|---|
| XSCore | 99241 = 输出 67860 + 黑盒输入 31381（Backend 13504 / MemBlock 16104 / Frontend 1773） | 99241 | **0** |
| XSTile | 71909 = 输出 66452 + 黑盒输入 5457（L2Top 3331 / XSCore 2111 / IntBuffer_1 8 / IntBuffer_2 4 / IntBuffer 3） | 71909 | **0** |

official 预期：native SUCCEEDED，passing 同上、constant_reg / unread / failing / unmatched / blackbox_out 全 0；verdict 在全部
child 证书 current-valid 后为 SUCCEEDED。

## 6. 剩余依赖与 official 启动命令（★本 lane 未跑 official★）

XSCore（等 Backend）：
1. agent/backend-asm 合入 main（带 `rtl/backend/Backend.sv` 与 `verif/proof_certificates/Backend.json`），再把 main 合进本分支（merge，不 rebase）；
2. `python3 scripts/make_proof_certificate.py --repo . --stamp-allow verif/allow/XSCore.json`（回填 Backend sha）并提交；
3. `python3 /home/eda/xs-env/tools/batch_reproof.py validate --list <frontend/backend/memBlock 三行>` 全 True；
4. `TMPDIR=/home/eda/xs-env/tmp-xsc PROOF_COMMIT=<c> bash scripts/run_proof.sh XSCore XSCore < /dev/null`；
5. `python3 scripts/fm_predict.py check XSCore`；`python3 scripts/make_proof_certificate.py --repo . --evidence evidence/<c12>/XSCore`；
   receipt 由 lane `git add -f`。

XSTile（等 XSCore + 3 个 IntBuffer 证书）：
1. 集成者从现有 receipt 出 IntBuffer 证书（未重跑 FM）：
   `python3 scripts/make_proof_certificate.py --repo . --evidence evidence/1bf831352049/IntBuffer`、
   `… --evidence evidence/64f5633a1e77/IntBuffer_1`、`… --evidence evidence/64f5633a1e77/IntBuffer_2`，再 validate 三者 current；
2. XSCore 证书入库后 `--stamp-allow verif/allow/XSTile.json`；
3. `PROOF_COMMIT=<c> bash scripts/run_proof.sh XSTile XSTile < /dev/null`，`fm_predict.py check XSTile`，出证书。

## 7. UT 结果

每档 200k 拍；复跑：`cd verif/ut/<T> && make ut SEED=<s> INITREG=<v>`（6 档并行时直接 `./simv +ntb_random_seed=<s> +ncycles=200000
+vcs+initreg+<v> -l sim_<s>_initreg<v>.log` 再 `python3 gen.py --covcheck sim_<s>_initreg<v>.log`，避免并行 make 争同一个 sim_<s>.log）。

### XSCore（tb / tb_pins @2051e19c1，RTL @885a1decf 起未改；输出 checks = 200k × 195）

| seed / initreg | 输出 checks / errors | 引脚 checks / errors | 输出翻转 | 引脚翻转 | icache_req / icache_resp / cfvec / redirect / lsq_enq |
|---|---|---|---|---|---|
| 1 / 0  | 39000000 / **0** | 523213080 / **0** | 135/195 | 784/2616  | 108 / 99858 / 1771 / 1199 / 1557 |
| 1 / 1  | 39000000 / **0** | 523213080 / **0** | 161/195 | 1386/2616 | 108 / 99858 / 1294 / 834 / 1104 |
| 7 / 0  | 39000000 / **0** | 523213080 / **0** | 132/195 | 780/2616  | 62 / 99807 / 2606 / 1916 / 2419 |
| 7 / 1  | 39000000 / **0** | 523213080 / **0** | 172/195 | 1325/2616 | 62 / 99807 / 2606 / 1916 / 2419 |
| 42 / 0 | 39000000 / **0** | 523213080 / **0** | 134/195 | 797/2616  | 136 / 99969 / 2874 / 2067 / 2625 |
| 42 / 1 | 39000000 / **0** | 523213080 / **0** | 172/195 | 1363/2616 | 136 / 99969 / 2874 / 2067 / 2625 |

6/6 COVCHECK OK（TEST PASSED + PINCHECK errors=0）。

### XSTile（tb / tb_pins @e059456d1，RTL 同上；输出 checks = 200k × 103）

| seed / initreg | 输出 checks / errors | 引脚 checks / errors | 输出翻转 | 引脚翻转 | immio_a / trace_v / msi_v / 四路中断（约） |
|---|---|---|---|---|---|
| 1 / 0  | 20600000 / **0** | 71201780 / **0** | 83/103 | 122/356 | 5 / 6 / 99899 / ≈1.0e5 各 |
| 1 / 1  | 20600000 / **0** | 71201780 / **0** | 98/103 | 188/356 | 5 / 6 / 99899 / 同上 |
| 7 / 0  | 20600000 / **0** | 71201780 / **0** | 83/103 | 123/356 | 3 / 4 / 99756 / ≈1.0e5 各 |
| 7 / 1  | 20600000 / **0** | 71201780 / **0** | 98/103 | 188/356 | 3 / 4 / 99756 / 同上 |
| 42 / 0 | 20600000 / **0** | 71201780 / **0** | 83/103 | 117/356 | 6 / 9 / 99749 / ≈1.0e5 各 |
| 42 / 1 | 20600000 / **0** | 71201780 / **0** | 98/103 | 186/356 | 6 / 9 / 99749 / 同上 |

6/6 COVCHECK OK。immio_a / trace_v 只有个位数——tile 里核几乎没跑起来（见 §3 待办），这是本 UT 的真实深度，不粉饰。

### 判据自证（变异体，scratchpad，不进库）

XSTile M1：派生副本 `ut_gen/XSTile.sv` 里把核的 `clint_int_sink_in_0 / _1` 两根来源对调（只改核那一侧的两行，diff 2 行），
同一份 tb / tb_pins 重新编译，seed 7 initreg 0、5000 拍：**PINCHECK errors=5100**（首个 `[t 85000] PIN MISMATCH
core.auto_memBlock_inner_clint_int_sink_in_0 g=0 i=1`），输出 errors=5100（difftest 网关 gatewayIn_packed_31/37 在第 4 拍起不同），TEST FAILED。
covcheck 反向自证：对一份没有 TEST PASSED / 没有 PINCHECK 行的探针日志，`gen.py --covcheck` rc=1。

## 8. 待集成者处理

1. **裁定**：两个顶层没有可读核 / 钉点（纯连线，理由 §1），与任务书"仿照 u_core 结构"不同。
2. Backend 证书入库（agent/backend-asm）→ 合 main 进本分支 → 回填 `verif/allow/XSCore.json` → XSCore official（§6）。
3. 三个 IntBuffer 从现有 receipt 出证（§6 命令；本 lane 未认领、未出证）。
4. 派生表由集成者统一重出：新增 `rtl/xstile/XSCore.sv`、`rtl/xstile/XSTile.sv` 会影响 rewrite_coverage / hier_rebind_map /
   g1_universe / coverage_three_axis 等（本 lane 未改）。
5. 本 lane 新增公共位置的文件只有 `scripts/gen_xscore_xstile.py`（新文件，未改任何既有共享脚本 / 共享核）；UT 用到
   `parent_wrapper_lib` / `gen_file_nav` / `gen_l2slice_ut` / `gen_xstile_closure` 只作 import / 调用。
6. UT 深度待办（不阻塞 official，FM 是权威）：XSCore 里 load 不发射、XSTile 里 ICache 不发请求的原因没查明。
