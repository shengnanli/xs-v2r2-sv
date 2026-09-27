# NewDispatch 步骤 4 跑前登记（接完最后 1488 bit）★先提交，再起跑 FM / 整芯片★

lane：agent/newdispatch3（接步骤 3，`docs/lanes/newdispatch_step3_reachability.md`）。改动已提交在
`5ed7107fa2e23aae336d6cba5b7d1da66899e656`（接线 + srcState 逻辑）与本文件同批的 conserve_total 位宽字面化。
本文件在任何一次本轮 FM / 整芯片起跑之前提交，跑完只对账、**不改预测**。

## 0. 改了什么（复述，便于对账时核对前提）
* 组 C 接线 1182 bit：lqIdx/sqIdx ← `lsqEnqCtrl.io_enq_resp_<l>`；useRegCache/regCacheIdx ← `rcTagTable.io_readPorts_<2l+j>`；
  srcLoadDependency_{0,1}_k ← `srcType_s[0] ? intBusyTable.io_read_<2l+s>_loadDependency_k : 0`（src2..4 照 golden 常量 0）。
* srcType_2（136 bit）：`srcType_2[2] & ignoreOldVd[l] ? 0 : srcType_2`，ignoreOldVd 照 golden 原式。
* srcState（170 bit）：wrapper 算 `allSrcState[l][j][k]` → 核新口 `srcStateAll` → 节 2.7 按 SRC_CLASS 逐 IQ 用同一组 oh 再选（IQ 10/11 src1 = int|fp 两路 OR）。
* conserve_total：位宽逐 lane 照 golden 字面形状（lane0 1+2、lane1 2+3、lane2 2+4、lane3+ 3+4），消掉 6 个 DFF0 unmatched。功能不变。
* `verif/dead_ref/NewDispatch.json`：golden 侧 72 个 `decodeReason_REG_<l>` / `decodeReason_<l>` 寄存器（topdown stallReason 死流水）。

## 1. FM 预测（对比基线 = 步骤 3 post-fix 诊断跑 `ND3fix-diag`：passing 55027 / failing 1416 / unmatched_ref 2006 / unmatched_impl 6 / unread_ref 72 / unread_impl 2006 / matched_nc 388）

| 量 | 预测 | 依据 |
|---|---|---|
| failing | **0** | 1416 个失败点全是那 20 个 leaf 的 `io_toIssueQueues_*` 端口位，现已逐条照 golden 接上；若 >0，失败点应全在这 20 个 leaf 内（=接错），不在别处 |
| unmatched_ref | 2006 → **0** | 2006 全是 5 个 busy table 的寄存器（int 1568 / fp 192 / vec 128 / vl 96 / v0 22），它们在 impl 侧原本 unread（读口输出没人消费）故配不上；现在 srcState / loadDependency / ignoreOldVd 消费了全部读口 |
| unmatched_impl | 6 → **0** | 6 个 DFF0（conserveFlowTotal 高位结构常量）改成字面 0 后读入即折，与 golden 同 |
| unread_impl | 2006 → **0** | 同 unmatched_ref 那 2006 个 |
| unread_ref | 72 → **72** | golden 独有的死流水，impl 不实现；靠 dead_ref 声明走 PASS_DEAD_REF |
| matched_nc | 388 → **0** | rcTagTable 的 388 个寄存器原来"配上但 impl 侧未读"，useRegCache/regCacheIdx 接上后两侧都读 |
| passing | **[58500, 59100]**，点估计 58837 | = 55027 + 1416（端口）+ 2006（busy table 寄存器）+ 388（rcTagTable 寄存器） |
| signoff-strict verdict | **PASS_DEAD_REF**（native SUCCEEDED，unread 只剩 72 个 ref 且与声明精确相等） | 上表全部成立时 fm_verdict 的 strict 例外分支 |

反向出口：failing>0 且失败点落在 20 个 leaf 之外 ⇒ 本轮改动波及了别的通路，停下来查；
unread_impl>0 ⇒ 还有读口没消费，照实报剩多少；unread_ref≠72 ⇒ 死流水判断有误，dead_ref 声明作废不改。

## 2. UT 预测
3 seed × 200k × {initreg+0, initreg+1}：A 组 = **6699 位（全部端口）**全一致，B 组 = 0，A/B 违反 0，六条 lane 被选中拍数与步骤 3 表逐个相同。
悬空清单：536 → **0**。

## 3. 整芯片预测（`perfbind2_diag_nd3.sh`，TAG=nd4，COMMIT=本文件所在 commit，**不排除任何件**，JOBS=16）
**第一条指令提交**（结果行出现 `instrCnt = N`、N>0，或 `EXCEEDED MAX CYCLE` 而非 `does not commit`）。
依据：diag2（golden NewDispatch + 重写 Rob/PtwCache）能提交；步骤 3 §5 证明重写 NewDispatch 的握手逐拍同 golden、
唯一差异是那 1488 bit 的随机常量；现已接上。若仍不提交 ⇒ 用 §5 同法采样 payload 逐位对照，照实报。

## 4. 台账措辞（codex 0168 §1）
ref 走 golden child、impl 走重写 child；转绿只记「**在 NewDispatch 上下文中**已被覆盖」，不记 9 个 child 各自独立 SIGNOFF_PASS。
