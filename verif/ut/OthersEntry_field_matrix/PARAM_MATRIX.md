# OthersEntry* 18 变体 × 核参数矩阵（机械生成，勿手改）

由 `verif/ut/OthersEntry_field_matrix/gen_param_matrix.py` 生成；`--check` 复算。
实参一列**从已生成的 wrapper 里抠出来**，不是再推一遍 ——
推一遍只能证明"生成器自洽"，抠出来才能证明"仓里那份就是它"。

## A. 家族形状（全部来自父级 `Entries_common/entries_gen.py` 的 `Variant`，
   而 `Variant` 构造时已断言 enq/simp/comp 三个 golden 模块共用同一套路由）

| 变体 | 父级 Entries | 角色 | 例化数 | NUM_REGSRC | NUM_WK_WB | NUM_WK_IQ | NUM_DEQ_PORTS | NUM_FU_BIT | LD_PIPES | LD_DEP_W | PL_DEQ_W | PL_TRANS_W | 端口数 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `OthersEntry` | `EntriesAluMulBkuBrhJmp` | simp | ×6 | 2 | 4 | 7 | 2 | 5 | 3 | 2 | 585 | 1362 | 580 |
| `OthersEntryVecMem` | `EntriesVlduVstuVseglduVsegstu` | simp | ×2 | 5 | 16 | 0 | 1 | 4 | 3 | 2 | 759 | 1330 | 705 |
| `OthersEntryVecMem_14` | `EntriesVlduVstu` | simp | ×2 | 5 | 16 | 0 | 1 | 2 | 3 | 2 | 759 | 1330 | 699 |
| `OthersEntryVecMem_16` | `EntriesVlduVstu` | comp | ×12 | 5 | 16 | 0 | 1 | 2 | 3 | 2 | 759 | 1330 | 327 |
| `OthersEntryVecMem_2` | `EntriesVlduVstuVseglduVsegstu` | comp | ×12 | 5 | 16 | 0 | 1 | 4 | 3 | 2 | 759 | 1330 | 331 |
| `OthersEntry_104` | `EntriesFaluFmacFdiv` | simp | ×2 | 3 | 6 | 3 | 2 | 3 | 3 | 2 | 546 | 1330 | 529 |
| `OthersEntry_106` | `EntriesFaluFmacFdiv` | comp | ×14 | 3 | 6 | 3 | 2 | 3 | 3 | 2 | 546 | 1330 | 143 |
| `OthersEntry_120` | `EntriesFaluFmac` | simp | ×2 | 3 | 6 | 3 | 1 | 2 | 3 | 2 | 546 | 1330 | 524 |
| `OthersEntry_122` | `EntriesFaluFmac` | comp | ×14 | 3 | 6 | 3 | 1 | 2 | 3 | 2 | 546 | 1330 | 138 |
| `OthersEntry_136` | `EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf` | simp | ×2 | 5 | 16 | 0 | 2 | 8 | 3 | 2 | 759 | 1345 | 627 |
| `OthersEntry_138` | `EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf` | comp | ×12 | 5 | 16 | 0 | 2 | 8 | 3 | 2 | 759 | 1345 | 257 |
| `OthersEntry_150` | `EntriesVfmaVialuFixVfalu` | simp | ×2 | 5 | 16 | 0 | 2 | 3 | 3 | 2 | 742 | 1330 | 607 |
| `OthersEntry_152` | `EntriesVfmaVialuFixVfalu` | comp | ×12 | 5 | 16 | 0 | 2 | 3 | 3 | 2 | 742 | 1330 | 241 |
| `OthersEntry_164` | `EntriesVfdivVidiv` | simp | ×2 | 5 | 16 | 0 | 1 | 2 | 3 | 2 | 741 | 1330 | 601 |
| `OthersEntry_166` | `EntriesVfdivVidiv` | comp | ×6 | 5 | 16 | 0 | 1 | 2 | 3 | 2 | 741 | 1330 | 234 |
| `OthersEntry_172` | `EntriesStaMou` | simp | ×2 | 1 | 4 | 7 | 1 | 2 | 3 | 2 | 574 | 1342 | 549 |
| `OthersEntry_174` | `EntriesStaMou` | comp | ×12 | 1 | 4 | 7 | 1 | 2 | 3 | 2 | 574 | 1342 | 187 |
| `OthersEntry_200` | `EntriesLdu` | simp | ×2 | 1 | 4 | 7 | 1 | 1 | 3 | 2 | 618 | 1362 | 558 |
| `OthersEntry_202` | `EntriesLdu` | comp | ×12 | 1 | 4 | 7 | 1 | 1 | 3 | 2 | 618 | 1362 | 209 |
| `OthersEntry_242` | `EntriesStdMoud` | simp | ×2 | 1 | 10 | 7 | 1 | 2 | 3 | 2 | 541 | 1330 | 569 |
| `OthersEntry_244` | `EntriesStdMoud` | comp | ×12 | 1 | 10 | 7 | 1 | 2 | 3 | 2 | 541 | 1330 | 201 |
| `OthersEntry_44` | `EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v` | simp | ×6 | 2 | 4 | 7 | 2 | 7 | 3 | 2 | 599 | 1362 | 595 |
| `OthersEntry_50` | `EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v` | comp | ×16 | 2 | 4 | 7 | 2 | 7 | 3 | 2 | 599 | 1362 | 229 |
| `OthersEntry_6` | `EntriesAluMulBkuBrhJmp` | comp | ×16 | 2 | 4 | 7 | 2 | 5 | 3 | 2 | 585 | 1362 | 207 |
| `OthersEntry_66` | `EntriesAluCsrFenceDiv` | simp | ×6 | 2 | 4 | 7 | 2 | 4 | 3 | 2 | 586 | 1362 | 578 |
| `OthersEntry_72` | `EntriesAluCsrFenceDiv` | comp | ×16 | 2 | 4 | 7 | 2 | 4 | 3 | 2 | 586 | 1362 | 207 |
| `OthersEntry_88` | `EntriesFaluFcvtF2vFmacFdiv` | simp | ×2 | 3 | 6 | 3 | 2 | 5 | 3 | 2 | 548 | 1330 | 537 |
| `OthersEntry_90` | `EntriesFaluFcvtF2vFmacFdiv` | comp | ×14 | 3 | 6 | 3 | 2 | 5 | 3 | 2 | 548 | 1330 | 151 |

## B. E1/E2 唤醒匹配参数（★本轮修的就是这几列★）

`SRC_MATCH_KIND[s]`：0=MK_GP（isFp&fpWen | isXp&rfWen | isVp&vecWen）、
1=MK_V0（isV0&v0Wen，★判据是 bit3 不是 bit2★）、2=MK_VL（isVp&vlWen）。
完全由 `NUM_REGSRC` 决定：==5 则 `0,0,0,1,2`，否则全 0（`EntryBundles.scala:185/241`）。

`*_WEN_PRESENT`：该总线**整条的并集**（位序 `{vlWen,v0Wen,vecWen,fpWen,rfWen}`），
核在 elaborate 期据此把不存在的项连同它的 srcType 位**整项剪掉** —— ★不是喂 0★。
延迟窗口（`*D_*`）OthersEntry 的 golden 根本没有那组端口，故一律空集。

| 变体 | SRC_MATCH_KIND | WB_WEN_PRESENT | WBD | IQ_WEN_PRESENT | IQD | WB 逐路 wen 分段 |
|---|---|---|---|---|---|---|
| `OthersEntry` | `{2'd0, 2'd0}` | `5'b00001` | `5'b00000` | `5'b00001` | `5'b00000` | rfWen@0..3 |
| `OthersEntryVecMem` | `{2'd2, 2'd1, 2'd0, 2'd0, 2'd0}` | `5'b11111` | `5'b00000` | `—(NUM_WK_IQ=0)` | `—` | fpWen,rfWen,v0Wen,vecWen,vlWen@0..15 |
| `OthersEntryVecMem_14` | `{2'd2, 2'd1, 2'd0, 2'd0, 2'd0}` | `5'b11111` | `5'b00000` | `—(NUM_WK_IQ=0)` | `—` | fpWen,rfWen,v0Wen,vecWen,vlWen@0..15 |
| `OthersEntryVecMem_16` | `{2'd2, 2'd1, 2'd0, 2'd0, 2'd0}` | `5'b11111` | `5'b00000` | `—(NUM_WK_IQ=0)` | `—` | fpWen,rfWen,v0Wen,vecWen,vlWen@0..15 |
| `OthersEntryVecMem_2` | `{2'd2, 2'd1, 2'd0, 2'd0, 2'd0}` | `5'b11111` | `5'b00000` | `—(NUM_WK_IQ=0)` | `—` | fpWen,rfWen,v0Wen,vecWen,vlWen@0..15 |
| `OthersEntry_104` | `{2'd0, 2'd0, 2'd0}` | `5'b00010` | `5'b00000` | `5'b00010` | `5'b00000` | fpWen@0..5 |
| `OthersEntry_106` | `{2'd0, 2'd0, 2'd0}` | `5'b00010` | `5'b00000` | `5'b00010` | `5'b00000` | fpWen@0..5 |
| `OthersEntry_120` | `{2'd0, 2'd0, 2'd0}` | `5'b00010` | `5'b00000` | `5'b00010` | `5'b00000` | fpWen@0..5 |
| `OthersEntry_122` | `{2'd0, 2'd0, 2'd0}` | `5'b00010` | `5'b00000` | `5'b00010` | `5'b00000` | fpWen@0..5 |
| `OthersEntry_136` | `{2'd2, 2'd1, 2'd0, 2'd0, 2'd0}` | `5'b11100` | `5'b00000` | `—(NUM_WK_IQ=0)` | `—` | vecWen@0..5; v0Wen@6..11; vlWen@12..15 |
| `OthersEntry_138` | `{2'd2, 2'd1, 2'd0, 2'd0, 2'd0}` | `5'b11100` | `5'b00000` | `—(NUM_WK_IQ=0)` | `—` | vecWen@0..5; v0Wen@6..11; vlWen@12..15 |
| `OthersEntry_150` | `{2'd2, 2'd1, 2'd0, 2'd0, 2'd0}` | `5'b11100` | `5'b00000` | `—(NUM_WK_IQ=0)` | `—` | vecWen@0..5; v0Wen@6..11; vlWen@12..15 |
| `OthersEntry_152` | `{2'd2, 2'd1, 2'd0, 2'd0, 2'd0}` | `5'b11100` | `5'b00000` | `—(NUM_WK_IQ=0)` | `—` | vecWen@0..5; v0Wen@6..11; vlWen@12..15 |
| `OthersEntry_164` | `{2'd2, 2'd1, 2'd0, 2'd0, 2'd0}` | `5'b11100` | `5'b00000` | `—(NUM_WK_IQ=0)` | `—` | vecWen@0..5; v0Wen@6..11; vlWen@12..15 |
| `OthersEntry_166` | `{2'd2, 2'd1, 2'd0, 2'd0, 2'd0}` | `5'b11100` | `5'b00000` | `—(NUM_WK_IQ=0)` | `—` | vecWen@0..5; v0Wen@6..11; vlWen@12..15 |
| `OthersEntry_172` | `{2'd0}` | `5'b00111` | `5'b00000` | `5'b00001` | `5'b00000` | fpWen,rfWen,vecWen@0..3 |
| `OthersEntry_174` | `{2'd0}` | `5'b00111` | `5'b00000` | `5'b00001` | `5'b00000` | fpWen,rfWen,vecWen@0..3 |
| `OthersEntry_200` | `{2'd0}` | `5'b00111` | `5'b00000` | `5'b00001` | `5'b00000` | fpWen,rfWen,vecWen@0..3 |
| `OthersEntry_202` | `{2'd0}` | `5'b00111` | `5'b00000` | `5'b00001` | `5'b00000` | fpWen,rfWen,vecWen@0..3 |
| `OthersEntry_242` | `{2'd0}` | `5'b00111` | `5'b00000` | `5'b00001` | `5'b00000` | fpWen,rfWen,vecWen@0..9 |
| `OthersEntry_244` | `{2'd0}` | `5'b00111` | `5'b00000` | `5'b00001` | `5'b00000` | fpWen,rfWen,vecWen@0..9 |
| `OthersEntry_44` | `{2'd0, 2'd0}` | `5'b00001` | `5'b00000` | `5'b00001` | `5'b00000` | rfWen@0..3 |
| `OthersEntry_50` | `{2'd0, 2'd0}` | `5'b00001` | `5'b00000` | `5'b00001` | `5'b00000` | rfWen@0..3 |
| `OthersEntry_6` | `{2'd0, 2'd0}` | `5'b00001` | `5'b00000` | `5'b00001` | `5'b00000` | rfWen@0..3 |
| `OthersEntry_66` | `{2'd0, 2'd0}` | `5'b00001` | `5'b00000` | `5'b00001` | `5'b00000` | rfWen@0..3 |
| `OthersEntry_72` | `{2'd0, 2'd0}` | `5'b00001` | `5'b00000` | `5'b00001` | `5'b00000` | rfWen@0..3 |
| `OthersEntry_88` | `{2'd0, 2'd0, 2'd0}` | `5'b00010` | `5'b00000` | `5'b00010` | `5'b00000` | fpWen@0..5 |
| `OthersEntry_90` | `{2'd0, 2'd0, 2'd0}` | `5'b00010` | `5'b00000` | `5'b00010` | `5'b00000` | fpWen@0..5 |

★向量 6 个变体的 `WB 逐路 wen 分段` 一列就是"整条总线一个字段"那种旧写法错在哪★：
lane 0..5 只有 vecWen、6..11 只有 v0Wen、12..15 只有 vlWen，
连线必须**逐路**取集合，剪项才用整条并集（并集 ∩ kind 给出的项集与逐路等价，
因为 `SRC_WB_MASK` 已把每个源限制在带它那个字段的那几路上）。

## C. ★"按端口有无发参数"的逐条语义核对★

EnqEntry 族 `6ad7839a` 的真 bug 是：`HAS_LD_DEP` 按「enq 口有没有某输入」发，
而参数在核里管的是「条目里存不存那组影子寄存器」，两者语义不一致，
结果 6 个变体把一组**活的**输出钉成常量 0。本族逐条排查如下。

| 参数 | 生成器怎么量 | 核里的真实语义 | 交叉印证 | 结论 |
|---|---|---|---|---|
| `HAS_LD_DEP` | `io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_0` 在不在 | `if (HAS_LD_DEP) g_ld_dep / else g_no_ld_dep`：条目里存不存那组影子寄存器 | 父级实参 `HAS_LD_DEP && (L_IS_ENQ \|\| L_IS_TRANS \|\| COMP_HAS_LD_DEP)` 求值 + 本模块 simp 看 transEntry / comp 看 entry 出口 | **18/18 一致，本族没有那个 bug**；原因：OthersEntry 的 enq 口来自上一级的 transEntry，而 transEntry 带不带 srcLoadDependency 恰好等于「影子寄存器活不活」 |
| `HAS_LD1_CANCEL` | `io_commonIn_ldCancel_0_ld1Cancel` 在不在 | LoadShouldCancel 里 ld1 那一项在不在（留着会把 dep 的 bit0 留在锥里）| 断言 == 父级 `v.has_ld1` | 18/18 一致 |
| `LD_PIPES` | 数 `io_commonIn_ldCancel_<q>_ld2Cancel` 的条数 | 每源几条 load 流水影子 | 断言 == 父级 `v.n_ld_cancel` | 18/18 一致 |
| `NUM_DEQ_PORTS` | 父级 `v.n_deq` | deqPortIdx 寄存器存不存 | 断言 `io_commonOut_deqPortIdxRead` 在不在 == (n_deq==2) | 18/18 一致 |
| `IS_TRANS` | 角色（golden `Entries*` 里的实例名 `othersEntriesSimp_*`）| 产不产 transEntry / 有没有 trans_sel | 断言 `io_commonIn_transSel` 与 `io_commonOut_transEntry_valid` 都与角色相符 | 18/18 一致 |
| `HAS_DBG_OUT` | 恒 1 | 7 组 debug/perf 出口产不产 | 条目单独成模块时 golden 确有这 7 组端口（24/24） | — |
| `*_WEN_PRESENT` | **本模块自己的**端口表逐路量 | elaborate 期剪项 | (a) 与父级从 EnqEntry 量的那份逐路比对；(b) 模型展开的 (srcType 位, wen) 对表 == 本模块 golden 实测对表 | 18/18 零处不符 |

| `HAS_LD_DEP` 逐变体读数 | 角色 | 自量(enq 口) | 父级 `has_ld_dep` | 父级 `comp_has_ld_dep` | 父级传给本角色的实参 | 一致 |
|---|---|---|---|---|---|---|
| `OthersEntry` | simp | 1 | 1 | 1 | 1 | ✔ |
| `OthersEntryVecMem` | simp | 1 | 1 | 0 | 1 | ✔ |
| `OthersEntryVecMem_14` | simp | 1 | 1 | 0 | 1 | ✔ |
| `OthersEntryVecMem_16` | comp | 0 | 1 | 0 | 0 | ✔ |
| `OthersEntryVecMem_2` | comp | 0 | 1 | 0 | 0 | ✔ |
| `OthersEntry_104` | simp | 1 | 1 | 0 | 1 | ✔ |
| `OthersEntry_106` | comp | 0 | 1 | 0 | 0 | ✔ |
| `OthersEntry_120` | simp | 1 | 1 | 0 | 1 | ✔ |
| `OthersEntry_122` | comp | 0 | 1 | 0 | 0 | ✔ |
| `OthersEntry_136` | simp | 1 | 1 | 0 | 1 | ✔ |
| `OthersEntry_138` | comp | 0 | 1 | 0 | 0 | ✔ |
| `OthersEntry_150` | simp | 1 | 1 | 0 | 1 | ✔ |
| `OthersEntry_152` | comp | 0 | 1 | 0 | 0 | ✔ |
| `OthersEntry_164` | simp | 1 | 1 | 0 | 1 | ✔ |
| `OthersEntry_166` | comp | 0 | 1 | 0 | 0 | ✔ |
| `OthersEntry_172` | simp | 1 | 1 | 1 | 1 | ✔ |
| `OthersEntry_174` | comp | 1 | 1 | 1 | 1 | ✔ |
| `OthersEntry_200` | simp | 1 | 1 | 1 | 1 | ✔ |
| `OthersEntry_202` | comp | 1 | 1 | 1 | 1 | ✔ |
| `OthersEntry_242` | simp | 1 | 1 | 1 | 1 | ✔ |
| `OthersEntry_244` | comp | 1 | 1 | 1 | 1 | ✔ |
| `OthersEntry_44` | simp | 1 | 1 | 1 | 1 | ✔ |
| `OthersEntry_50` | comp | 1 | 1 | 1 | 1 | ✔ |
| `OthersEntry_6` | comp | 1 | 1 | 1 | 1 | ✔ |
| `OthersEntry_66` | simp | 1 | 1 | 1 | 1 | ✔ |
| `OthersEntry_72` | comp | 1 | 1 | 1 | 1 | ✔ |
| `OthersEntry_88` | simp | 1 | 1 | 0 | 1 | ✔ |
| `OthersEntry_90` | comp | 0 | 1 | 0 | 0 | ✔ |

