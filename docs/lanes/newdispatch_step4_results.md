# NewDispatch 步骤 4 跑后对账（逐条对 `newdispatch_step4_prereg.md`，登记不改）

登记 commit `3c62e43804b77cfcb10af03525946eea6d5d25e0`。登记之后、起跑之前还改了两处**形状**（功能不变，见 §0），
最终 RTL = `58e3ebcc430357142c79ca3c98c32cd568a3db61`（`639bbfb0` 只是导航行号注释；`git diff 58e3ebcc 639bbfb0 -- rtl/` 非注释行 0）。

## 0. 登记之后的两处补改（都在起跑前提交，都是 FM 形状不是功能）
1. `c90f4598`：conserveFlowTotal 的常量位改成 always_ff 里的字面 0（选择放里面、字面 0 放外面，照 golden
   `{1'h0, sel ? .. : ..}`）。登记时用函数返回 `{1'b0,..}` 再过 `?:`，第一次诊断跑（`ND4-diag`，commit 66175efe）
   显示 FM 能折成 DFF0，但 6 个常量位各自来自不同 mux 输出网，merge_dup 不合并，仍是 6 个 unmatched impl 点。
2. `58e3ebcc`：`verif/ut/NewDispatch/fm_pins.tcl`，唯一一条 set_user_match：golden intBusyTable 的 x0 位
   `table_r_reg`（单独一个 reg，在本上下文被 FM 判 DFF0X）↔ 重写核 `busy_reg[0]`（DFF0）。标准 BusyTable 签核时
   两者按签名配上；在父上下文两类常量寄存器不互配，故显式钉一次。只配对不约束 ref，FM 仍证明二者等价（passing 里）。

## 1. FM 对账（诊断跑 `ND4b-diag`，evidence/58e3ebcc4303/NewDispatch-diag，receipt sha256 b6619f305880941312e1c06c6e3365501cc37b475cdafd9bf04760a19df77e30）

| 量 | 登记预测 | 实测 | 裁决 |
|---|---|---|---|
| failing | 0 | **0** | ★PASS★ |
| unmatched_ref / unmatched_impl | 0 / 0 | **0 / 0** | ★PASS★（第一次跑是 1/7，见 §0） |
| unread_impl | 0 | **0** | ★PASS★ |
| unread_ref | 72 | **72**（与 dead_ref 声明逐条相等） | ★PASS★ |
| matched_nc | 0 | **0**（unread_points.txt 只有 72 行 ref） | ★PASS★ |
| passing | [58500, 59100]，点估计 58837 | **58820**（Port 51563 + DFF 7257） | ★PASS★（差 17，来自 constant-reg 18 个不计入） |
| native | SUCCEEDED | **SUCCEEDED** | ★PASS★ |

    cd verif/ut/NewDispatch && XSSV_HOME=<wt> FM_MODE=diagnostic-full FM_FAILING_LIMIT=0 make fm-NewDispatch

**签核跑**（`scripts/run_proof.sh NewDispatch NewDispatch`，detached worktree @ `639bbfb0`，dirty=false）：
`evidence/639bbfb0d9c6/NewDispatch/receipt.json`，sha256 **593b4733ea6f20c90424c137a18485f270e502c18e3fc00f6bcb2ed5d62dbb68**，
verdict **PASS_DEAD_REF**：native SUCCEEDED，passing 58820 / failing 0 / unverified 0 / unmatched 0 / aborted 0，
blackbox 0，dont_verify false，唯一残余 = golden 侧 72 个 `decodeReason_REG_<l>`/`decodeReason_<l>`（topdown stallReason
死流水，本模块内无消费者）与 `verif/dead_ref/NewDispatch.json` 精确相等，impl 侧 unread 0。
没有 dont_verify / 放松 appvar / 白名单 / 加宽黑盒 / set_mismatch_message_filter；黑盒 0 个（9 个 child 两侧 elaborate）。

## 2. UT 对账（最终 RTL，simv 编译于 58e3ebcc）

    cd verif/ut/NewDispatch && make compile && ./simv +ntb_random_seed=<1|7|42> +ncycles=200000 +vcs+initreg+<0|1> -l sim_<seed>_initreg<0|1>.log

| seed | initreg | A 恒等 | B 悬空 | A 违反 | B 违反 | checks | lane0..5 被选中拍数 golden/重写 |
|---|---|---|---|---|---|---|---|
| 1 | 0 | 6699 位 | 0 位 | 0 | 0 | checks=199944 | 43256/43256 86178/86178 124018/124018 152738/152738 172620/172620 184645/184645 |
| 1 | 1 | 6699 位 | 0 位 | 0 | 0 | checks=199944 | 43256/43256 86178/86178 124018/124018 152738/152738 172620/172620 184645/184645 |
| 7 | 0 | 6699 位 | 0 位 | 0 | 0 | checks=199944 | 43563/43563 84280/84280 122448/122448 152379/152379 172455/172455 184982/184982 |
| 7 | 1 | 6699 位 | 0 位 | 0 | 0 | checks=199944 | 43563/43563 84280/84280 122448/122448 152379/152379 172455/172455 184982/184982 |
| 42 | 0 | 6699 位 | 0 位 | 0 | 0 | checks=199944 | 40971/40971 82823/82823 121303/121303 152881/152881 173666/173666 184550/184550 |
| 42 | 1 | 6699 位 | 0 位 | 0 | 0 | checks=199944 | 40971/40971 82823/82823 121303/121303 152881/152881 173666/173666 184550/184550 |

六档全 TEST PASSED；判据 A 覆盖**全部 6699 位**（悬空清单 536 → **0**，登记如此，实测如此）；六条 lane 被选中拍数与步骤 2/3 同 seed 逐个相同。

## 3. 整芯片对账（`perfbind2_diag_nd3.sh`，不排除任何件：NewDispatch/Rob/PtwCache 全用重写件，JOBS=16）

| TAG | commit | 结果 |
|---|---|---|
| nd4 | 3c62e438（登记 commit） | BUILD ok；**The first instruction of core 0 has commited. Difftest enabled.**；EXCEEDED MAX CYCLE 20000；DIFFTEST FAILED 0 |
| nd4b | 58e3ebcc（最终 RTL） | 同上：第一条指令提交，difftest 20000 拍无失配 |

与 golden 对照组 diag2 的日志形状一致。★登记 §3 PASS★。证据 evidence/3c62e43804b7/chip-nd4、evidence/58e3ebcc4303/chip-nd4b（sim_noperf.log + 文件清单 + simv sha256 + MANIFEST）。
对照：步骤 3 的 nd3fix（未接 1488 bit）同配置 instrCnt=0 —— 变绿的唯一改动就是本轮接上的 1488 bit。

## 4. 台账措辞（codex 0168 §1）
本 target ref 走 golden child、impl 走重写 child（9 个 child 两侧各自 elaborate、0 黑盒）。本轮 NewDispatch 转绿
（PASS_DEAD_REF）只记「9 个 child **在 NewDispatch 上下文中**已被覆盖」，不记它们各自的独立 SIGNOFF_PASS。
