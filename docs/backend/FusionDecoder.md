# FusionDecoder（指令宏融合解码器）

## 功能
对 6 条连续取指构成的 5 个相邻指令对（lane i = {io_in_i, io_in_{i+1}}）各自做宏融合
模式匹配。每 lane 对指令对硬 decode 出 28 个融合候选 `fusionVec[i][0..27]`，打拍锁存后
组合产出：
- `io_clear_{i+1}`：本 lane 命中融合且未被前一 lane 抢占（优先级链）→ 需清后一条指令
- `io_out_i`：融合后 uop 的 fuType/fuOpType/lsrc2/src2Type/selImm 覆写
- `io_info_i`：rs2 来源（FromRs1 / FromRs2 / FromZero）

lane 结构完全对称，可读核用 `genvar` 生成 5 个 lane。decode LUT 常数与 golden firtool
输出逐项对应（见各 `fv[k]` 表达式）。

## 文件
- 可读核：`rtl/backend/FusionDecoder_core.sv`（`xs_FusionDecoder`，数组端口）
- 包装层：`rtl/backend/FusionDecoder_wrapper.sv`（golden 同名扁平端口 ↔ 核数组端口）
- UT：`verif/ut/FusionDecoder/`（双例化 golden vs `FusionDecoder_xs`）

## FM 签核
**strict SUCCEEDED**：passing 335 / failing 0 / unmatched 0 / unread 0，无 dont_verify/黑盒。

### 对称死寄存器（vmucp 双射）
golden 每 lane 有 `lastFire_N` 与 `REG_N` 两个逐拍 `<= fire_N` 的寄存器，仅被 firtool 为
SYNTHESIS 断言生成的死 wire（`_GEN_3..` / `_GEN_167`）读取；关 SYNTHESIS 后读者全裁剪
→ 均 cone-dead。`merge_duplicated_registers=true` 把每 lane 的 lastFire_N/REG_N 合并成
代表寄存器 `REG_N_reg`。可读核保留语义等价的 `lastFire[N]`（同 `<= fire[g]`）。二者同源
同逻辑完美双射，经 `fm_pins_pre.tcl` 显式钉配 + `verify_matched_unread_compare_points=true`
令 FM 实际逐位证明等价（passing 330→335），unread 归 0。

### main 待做
FusionDecoder 须加入 `scripts/fm_eq.tcl` 的 vmucp 白名单（L77 的 `ni {...}` 集）+
`scripts/sidecar/run_signoff_target.sh` 的 case 白名单（两处均 main-owned 共享文件）。
worker 用 evidence 目录的 fm_eq.tcl 副本（加了 FusionDecoder 白名单）跑出 authoritative
native SUCCEEDED（见 `/tmp/cb-children2-evidence/FusionDecoder/fm.log`）。

## UT
seed 1/7/42 各 199992 checks，errors 0。
