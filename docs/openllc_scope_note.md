# OpenLLC：**核外目标，本轮不重写、不签核**（范围标注 + 旧登记病因纠正）

## 一、范围结论（2026-09-21，coordinator 裁定）

用户的长期约束是「核外面的文件不重写」，重写范围是 **XSTile 闭包之内**。
OpenLLC 例化在 **XSTop**，不在 XSTile 里 —— 它是外挂 L3 / SoC 层的 IP：

    $ grep -n 'OpenLLC' /home/eda/xs-env/G1-canonical/golden-rtl/XSTop.sv
    2210:  OpenLLC chi_openllc_opt (

所以本轮 **OpenLLC 不做**。这与「没做完」不是一回事：
不是缺工时、不是卡在判据上，是**不在范围内**，后续 lane 不必接。

本文件保留的是**诊断结论**，不是待办。

## 二、被纠正的旧登记

`docs/fastlane_ledger.tsv` / `docs/ledger_normalized.tsv` 里 OpenLLC 记的是

    UNRUNNABLE_RESOURCE_LIMIT_CURRENT_HOST
    「本机 cgroup-v1、无可信 memory containment，不得在此运行 OpenLLC XL」

**这条登记的病因写错了**。它把原因归给"目标太大 / 本机没有内存隔离"，
真因在闭包清单里：`scripts/gen_zj_ut.py` 的零判断批把厂商 SRAM 宏的行为模型
`*_ext.v` 一并列进了两侧 elaboration 闭包，而

    $ grep -n 'reg \[511:0\] ram' /home/eda/xs-env/G1-canonical/golden-rtl/array_0_1_ext.v
    18:  reg [511:0] ram [65535:0];

一个实例 65536 × 512 bit = 3355 万 flop；LLC 四个 slice 各一份、ref/impl 两侧再各一份
≈ 2.6 亿比较点。厂商 SRAM 宏本来就属于"无条件绿黑盒"那一类（与 ICacheDataArray /
SRAMTemplate 家族同处置），根本不该进 elaboration 闭包。

把这 9 个存储叶子（`array_*_ext.v` ×6 + `ram_15x{162,422,73}.sv`）从**两侧**闭包移出、
成为对称 unresolved 黑盒之后，本机实跑得到：

    Verification FAILED
    167323 Passing / 20 Failing(20 matched) / 0 Aborted / 7 Unverified
    6(0) Unmatched reference(implementation) compare points
    峰值 RSS 3.0 GB，fm_shell 用时约 70 分钟

**3 GB / 70 分钟是 NORMAL 量级，不是 XL。** 证据：`evidence/probe-openllc-mergedup-true-07e6b07e/`
（★探针，不是 signoff receipt：没有 run_proof.sh 的 RUN_CONTEXT，不得当证书用★）。
输入 commit = `07e6b07eeb47f77ea2ed4810ae1784294deb2437`。

## 三、那 20 个 failing 是 FM 建模伪影，不是重写 bug

失败点全部落在 `io_rn_0_rx_snp_flit[27..46]`（RN 侧 snoop flit 输出），
6 个 ref-only 未配对寄存器是

    r:/WORK/OpenLLC/rnXbar/snpReqs_{0,1,2,3}_bits_opcode_reg[4]
    r:/WORK/OpenLLC/rnLinkMonitor/Decoupled2LCredit_txsnp/out_flit_r_reg[27] 与 [54]

—— 四个 bank 的同值复制寄存器 + 一个 flit 寄存器的两位。

不靠读代码下结论，写了可复跑的机械判定 `scripts/openllc_topology_diff.py`
（实例集合 / 每条端口绑定 / 网声明位宽 / assign 右值，四项逐字比）：

    $ python3 scripts/openllc_topology_diff.py ; echo rc=$?
    ... 11 个实例（mmioDiverger 293 端口 / rnXbar 349 / slices_N 189×4 / topDown 323 …）
        绑定全同；1181 条网声明 0 处差异；3 条 assign 相同
    结论: 顶层拓扑同构（实例/端口绑定/网声明/assign 四项全等）
    rc=0

顶层与 golden 同构 ⇒ 失配不可能来自这一层。真因是 impl 侧比 ref 多一层 `u_core`，
FM 的 `verification_merge_duplicated_registers`（默认 true）按名合并复制寄存器时
两侧合并深度不对称，被合掉的几个在 ref 侧成了未配对点，下游 snp flit 位跟着判失配。
上一轮 G0 的已签核配置写过同一条结论，本轮是**独立重现**它。

`verif/ut/OpenLLC/Makefile` 里已按此改成 `FM_MERGE_DUP = false` + `FM_MODE = assembly`，
`verif/allow/OpenLLC.json` 逐条声明了 58 个存储宏黑盒对象。
★这套配置**没有跑完过**★ —— 范围裁定下来时 run_proof 刚起、fm_shell 还没启动就按 PID 停了。
所以它是**未验证的配置**，不得据此声称 OpenLLC 有任何 PASS。

## 四、另一条顺带查到的、与范围无关的事实（留给写 tb 的人）

`verif/ut/OpenLLC/tb.sv` 第 4 行写着「收尾判 errors / checks / toggled / fires 四项，
后三项是覆盖闸（防假绿）」，但 `fires` 这个变量**从声明到打印之间一次都没有被 ++**，
收尾判定里也没有它。它是个死计数器，那句注释描述的闸不存在。

而且 `MIN_TOGGLED = 22`、`N_OUT = 29`，三个 seed 实测恰好 `toggled=22`：
没有 toggle 的 7 个全是 RN 侧回程（`io_rn_0_rx_rsp_flitv/flit`、`rx_dat_flitv/flit`、
`rx_snp_flitv/flit`、`io_debugTopDown_addrMatch_0`）—— 也就是说这个 UT 从来没让
LLC 回过一次响应，门限恰好卡在"实际能过的那个数"。
（本轮 UT 实测：seed 1/7/42 各 200000 拍，`checks=5800000 errors=0 toggled=22/29`，
  日志 `verif/ut/OpenLLC/sim_{1,7,42}.log`。）
