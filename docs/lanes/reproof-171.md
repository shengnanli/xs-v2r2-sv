# Lane reproof-171（171 张 HISTORICAL 证书官方重证）

Base：main 2d1d134e0；claim 378ff69ae。工作树 /home/eda/xs-env/wt-reproof-171，分支 agent/reproof-171。
本文件的数字是实测值，写下不回改。

## 1. 名单复核（HEAD 378ff69ae，跑前）

`batch_reproof.py validate` 对 `verif/proof_certificates/` 全部 506 个文件：True 333；非 True 173 =
`docs/oldcert_triage.tsv` 的 171 张（全部 category=HISTORICAL、fail_reason=`green_child_script_closure_changed:<T>:scripts/fm_eq.tcl`、
proof_mode=signoff-strict、旧 verdict 165 SUCCEEDED + 6 PASS_DEAD_REF）+ POLICY.json + schema-v1.json（非证书）。
与 tsv 逐名一致（comm 无差异），16 个 ut_dir。

## 2. 跑前登记（commit a2b2c7eec = PROOF_COMMIT）

- 已有登记 3 张：DelayNWithValid_152（18）/ DelayNWithValid_155（100）/ MbistBitmapCache（661），merge_dup=false，按当前模型复算一致，未改。
- 缺登记 168 张，全部 `fm_predict.py register` 补登记，单独提交 a2b2c7eec（只含 docs/fm_predictions/），之后不再提交任何被证输入。
  - 38 张走 `--ut <ut_dir>`（from_ut 可用），merge_dup=true。
  - 130 张属于 CSRChildless26 / csr_dh / csr_m / HpmCounterTailLeaves / PmaCfgTailLeaves / PmpCfgTailLeaves：这些 Makefile 的
    `FM_VARIANTS = $(LEAVES)`，fm_predict 的 ut_of/from_ut 不展开变量（from_ut 拿 `$(LEAVES)` 当 top 报 FileNotFound），
    只能不带 --ut 登记 → 按 golden 单模块 compute_model 计算，`ut=null / merge_dup=null / model_applicable=false`；与 64f5633a1（Pma*cfg）先例同法。
    这 130 张都没有 bbox/deps_unexpanded 附加键（golden 均为无子模块叶子）。这是 fm_predict 工具局限，scripts/ 不在本 lane 范围，未改。
  - 每份登记 note 写明模型分解、merge_dup 口径、旧证书 passing。
- 跑前用旧 receipt 预演 _judge：全部 EXACT 或 merge 带内；34 张无旧 receipt（attestation_only），旧 passing ≤ expected。

## 3. 重证

`TMPDIR=/home/eda/xs-env/tmp-r171 python3 /home/eda/xs-env/tools/batch_reproof.py run --commit a2b2c7eec2d2 --list <171 行> --jobs 8 --tag r171`
（一波，171 目标互无父子依赖；license Formality 9999 空闲；机器 32 核，跑时 load ~18）。约 2 h 完成，`需关注 0 个`。
evidence/a2b2c7eec2d2/RUN_CONTEXT.tsv：171 个 run 块，commit/head_before/head_after 全为 a2b2c7eec，worktree_digest 前后一致。

## 4. 结果

- **171/171 通过**：rc=0；verdict 与旧证书相同（165 SUCCEEDED + 6 PASS_DEAD_REF）；native_verdict 全 SUCCEEDED；failing / unverified / aborted 0；
  unmatched 全零，6 张 PASS_DEAD_REF 只有 golden 侧 unread_ref（HPerfCounter×3 / Iprio2Module_1 = 8，Iprio0Module_1 / Iprio2Module = 16），与旧证书相同。
- **新证书 native_result 与旧证书逐字段相同**（passing 逐位等于旧证书）。
- `fm_predict.py check` 171 张：结论「全部对上」——3 张 EXACT（merge_dup=false 的三张），168 张 merge_dup=true 落在带内。
  其中 162 张 passing 与登记 expected 逐位相等；9 张低于 expected：
  - HPerfCounter / _13 / _8（74→66，unread 8）、Iprio0Module_1 / Iprio2Module（112→96，unread 16）、Iprio2Module_1（112→104，unread 8）：差额 = unread（dead ref），逐位被指认；
    但 model_applicable=false，check 仍按带内弱结论报。
  - SatpModule（192→184，constant_reg 1，余 7）、HgatpModule（188→178，constant_reg 1，余 9）、FreeList_5（940→724，constant_reg 4，余 212）：
    余额只能落在 merge_duplicated_registers 带内（regs 上界 Satp 64 / Hgatp 62 / FreeList_5 915；fm_predict 自报带宽 33.3% / 33.0% / 97.3%，标「近乎无信息」）解释，不是逐位指认；三者 passing 与旧证书一致，判定不变。
  「跑前登记逐位相等」按 fm_predict 判据（merge_dup=true 时为带内）满足；严格字面的 expected==passing 有上述 9 张不满足，原因如上，未改登记迁就。
- 提交 5af6ca613：evidence/a2b2c7eec2d2（git add -f，同 a1d118812 先例）+ 171 张新证书。

### 逐张结果

| target | ut_dir | verdict（新/旧） | passing（新/旧） | 预测 expected | constant_reg / unread | 新证书 sha256 | 旧证书 sha256 |
|---|---|---|---|---|---|---|---|
| AgeDetector_38 | AgeDetector_38 | SUCCEEDED / SUCCEEDED | 324 / 324 | 324 | 0 / 0 | `75381735bab8e67e…` | `7df86b34e0f975d4…` |
| BusErrorUnit | BusHPerfCounter200c | SUCCEEDED / SUCCEEDED | 145 / 145 | 145 | 0 / 0 | `e9a39412e1682237…` | `7fea6912c1b4ebae…` |
| HPerfCounter | BusHPerfCounter200c | PASS_DEAD_REF / PASS_DEAD_REF | 66 / 66 | 74 | 0 / 8 | `1720fad9d92dd490…` | `43292528183dbe41…` |
| HPerfCounter_13 | BusHPerfCounter200c | PASS_DEAD_REF / PASS_DEAD_REF | 66 / 66 | 74 | 0 / 8 | `6a879d3f388ac71c…` | `cf7ca47c538249a6…` |
| HPerfCounter_8 | BusHPerfCounter200c | PASS_DEAD_REF / PASS_DEAD_REF | 66 / 66 | 74 | 0 / 8 | `e8076589ff90b3f2…` | `9356e05fa14bbfdd…` |
| Mgtu | CSRChildless26 | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `a978f392c6329dfd…` | `7657a5a629b77d00…` |
| MidelegModule | CSRChildless26 | SUCCEEDED / SUCCEEDED | 72 / 72 | 72 | 0 / 0 | `f073f2cc84fe2a70…` | `247de1bad3a68d3a…` |
| MipModule | CSRChildless26 | SUCCEEDED / SUCCEEDED | 93 / 93 | 93 | 0 / 0 | `9ce25e9266edbf2a…` | `42434969d6769609…` |
| MiselectModule | CSRChildless26 | SUCCEEDED / SUCCEEDED | 83 / 83 | 83 | 0 / 0 | `dd012b777cf2cadc…` | `94f6ac7922a04729…` |
| MnstatusModule | CSRChildless26 | SUCCEEDED / SUCCEEDED | 72 / 72 | 72 | 0 / 0 | `fb1771b2b48d7419…` | `418206ff920c215f…` |
| MretEventModule | CSRChildless26 | SUCCEEDED / SUCCEEDED | 121 / 121 | 121 | 0 / 0 | `e8d2ff481a823156…` | `443688c0970f039d…` |
| MseccfgModule | CSRChildless26 | SUCCEEDED / SUCCEEDED | 68 / 68 | 68 | 0 / 0 | `1b308e3cccc8f277…` | `60ce0d0973076e9e…` |
| Mstateen0Module | CSRChildless26 | SUCCEEDED / SUCCEEDED | 78 / 78 | 78 | 0 / 0 | `962033a149b3240e…` | `f5c2a2ec94904953…` |
| Mstateen1Module | CSRChildless26 | SUCCEEDED / SUCCEEDED | 66 / 66 | 66 | 0 / 0 | `2004d1f8255836a7…` | `53c0649d2b0ef452…` |
| Mstateen2Module | CSRChildless26 | SUCCEEDED / SUCCEEDED | 66 / 66 | 66 | 0 / 0 | `112e8e44bfcbe3cd…` | `6a68616b090e3f5a…` |
| Mstateen3Module | CSRChildless26 | SUCCEEDED / SUCCEEDED | 66 / 66 | 66 | 0 / 0 | `42ee174325217336…` | `e40caafd73baae22…` |
| MtinstModule | CSRChildless26 | SUCCEEDED / SUCCEEDED | 192 / 192 | 192 | 0 / 0 | `fcbe9342333d5665…` | `ee596e7e2851c392…` |
| SatpModule | CSRChildless26 | SUCCEEDED / SUCCEEDED | 184 / 184 | 192 | 1 / 0 | `3092c7f943e33077…` | `38dbea36459f79b9…` |
| SbpctlModule | CSRChildless26 | SUCCEEDED / SUCCEEDED | 78 / 78 | 78 | 0 / 0 | `70f70f49b25b2ae7…` | `8d9e94d84e788a96…` |
| ScounterenModule | CSRChildless26 | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `bae8c5c81c3d41ce…` | `82df4f9f4b76ad8e…` |
| SenvcfgModule | CSRChildless26 | SUCCEEDED / SUCCEEDED | 76 / 76 | 76 | 0 / 0 | `d16b07cc34c90729…` | `0a7a77786f374f31…` |
| SiselectModule | CSRChildless26 | SUCCEEDED / SUCCEEDED | 91 / 91 | 91 | 0 / 0 | `4f4ed0437f62e845…` | `1b5f5bc8907683f7…` |
| SlvpredctlModule | CSRChildless26 | SUCCEEDED / SUCCEEDED | 82 / 82 | 82 | 0 / 0 | `99e04ff5eed595c6…` | `6873afcecfa4d356…` |
| SmblockctlModule | CSRChildless26 | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `1c272ee07075af45…` | `7aa1d2c5d7c6fe1d…` |
| SpfctlModule | CSRChildless26 | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `4d4c36b431fdec4c…` | `37f51c2348ccadfa…` |
| SretEventModule | CSRChildless26 | SUCCEEDED / SUCCEEDED | 141 / 141 | 141 | 0 / 0 | `97517cf641a1388d…` | `5916351f947cbd93…` |
| SrnctlModule | CSRChildless26 | SUCCEEDED / SUCCEEDED | 68 / 68 | 68 | 0 / 0 | `044a0dc7574bfd4e…` | `8ed2e712cd7871ff…` |
| Sstateen0Module | CSRChildless26 | SUCCEEDED / SUCCEEDED | 36 / 36 | 36 | 0 / 0 | `3d4d49820b8b630e…` | `7f64a86133d3cde4…` |
| StimecmpModule | CSRChildless26 | SUCCEEDED / SUCCEEDED | 192 / 192 | 192 | 0 / 0 | `16f57ef2ac3d8091…` | `89529bda7cd6556b…` |
| TrapInstMod | CSRChildless26 | SUCCEEDED / SUCCEEDED | 89 / 89 | 89 | 0 / 0 | `d4ef1984aa1ab3ff…` | `2df4d443dcd18897…` |
| TrapTvalMod | CSRChildless26 | SUCCEEDED / SUCCEEDED | 138 / 138 | 138 | 0 / 0 | `d0d04455fb1d3142…` | `81a94205a5787ed0…` |
| Iprio0Module | CSRControl200c | SUCCEEDED / SUCCEEDED | 112 / 112 | 112 | 0 / 0 | `cf26e00114e8ace7…` | `4eaff3abd89fb70a…` |
| Iprio0Module_1 | CSRControl200c | PASS_DEAD_REF / PASS_DEAD_REF | 96 / 96 | 112 | 0 / 16 | `a28206500397b8d9…` | `7c37856f64466a78…` |
| Iprio10Module_1 | CSRControl200c | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `415db56f9f036b43…` | `f3683a95d84c15a2…` |
| Iprio12Module_1 | CSRControl200c | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `dcad753d11249432…` | `05239094982cbca7…` |
| Iprio14Module_1 | CSRControl200c | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `1746e4663a183f4d…` | `84fddb5483006978…` |
| Iprio2Module | CSRControl200c | PASS_DEAD_REF / PASS_DEAD_REF | 96 / 96 | 112 | 0 / 16 | `e8fa08b90a2b586c…` | `5860053b19f4a283…` |
| Iprio2Module_1 | CSRControl200c | PASS_DEAD_REF / PASS_DEAD_REF | 104 / 104 | 112 | 0 / 8 | `e0fb106584fc39ec…` | `54b33b9f932be87c…` |
| Iprio4Module_1 | CSRControl200c | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `d4b5ddfcf813a0b3…` | `639287a48ddb6087…` |
| Iprio6Module_1 | CSRControl200c | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `3c9e4069df20b33f…` | `72f3acaef69316ed…` |
| Iprio8Module_1 | CSRControl200c | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `f5ec099ede166dee…` | `9586acb5340ea190…` |
| MNretEventModule | CSRControl200c | SUCCEEDED / SUCCEEDED | 127 / 127 | 127 | 0 / 0 | `7b2afe7edf2d57a4…` | `59a1a622fc8bcbe7…` |
| MhpmeventModule | CSRControl200c | SUCCEEDED / SUCCEEDED | 186 / 186 | 186 | 0 / 0 | `693e8f5f2892af4b…` | `a9727618b7423ff7…` |
| SstcInterruptGen | CSRControl200c | SUCCEEDED / SUCCEEDED | 4 / 4 | 4 | 0 / 0 | `f587d9c973fa3c06…` | `31925e3c07f44e92…` |
| DelayNWithValid_152 | DelayNWithValid | SUCCEEDED / SUCCEEDED | 18 / 18 | 18 | 0 / 0 | `7122f6e31673feb4…` | `8b9305fdcae7e2eb…` |
| DelayNWithValid_155 | DelayNWithValid | SUCCEEDED / SUCCEEDED | 100 / 100 | 100 | 0 / 0 | `2a249382275e0759…` | `a7efefa60693fe24…` |
| Dispatcher | Dispatcher200c | SUCCEEDED / SUCCEEDED | 1954 / 1954 | 1954 | 0 / 0 | `4655198a6205a110…` | `2d1515cae06c125b…` |
| Dispatcher_1 | Dispatcher200c | SUCCEEDED / SUCCEEDED | 1662 / 1662 | 1662 | 0 / 0 | `07ca28e26756ebc2…` | `1535fbb696fe5b17…` |
| Dispatcher_10 | Dispatcher200c | SUCCEEDED / SUCCEEDED | 1313 / 1313 | 1313 | 0 / 0 | `0de244cfa8c2b3d8…` | `ed7ecd9bf78939f7…` |
| Dispatcher_13 | Dispatcher200c | SUCCEEDED / SUCCEEDED | 2660 / 2660 | 2660 | 0 / 0 | `49c78653d9c93b5a…` | `959bb211dc069bfc…` |
| Dispatcher_14 | Dispatcher200c | SUCCEEDED / SUCCEEDED | 2676 / 2676 | 2676 | 0 / 0 | `d3afda172d4656f5…` | `9ec269c97f46331f…` |
| Dispatcher_15 | Dispatcher200c | SUCCEEDED / SUCCEEDED | 1326 / 1326 | 1326 | 0 / 0 | `ef89a167459f355b…` | `872dd18bed2d9503…` |
| Dispatcher_16 | Dispatcher200c | SUCCEEDED / SUCCEEDED | 668 / 668 | 668 | 0 / 0 | `468c0050fbf7e13f…` | `80b9bbc1fe11f62f…` |
| Dispatcher_17 | Dispatcher200c | SUCCEEDED / SUCCEEDED | 1387 / 1387 | 1387 | 0 / 0 | `ee8cedea065c8612…` | `0acb8ae954cd7d80…` |
| Dispatcher_4 | Dispatcher200c | SUCCEEDED / SUCCEEDED | 652 / 652 | 652 | 0 / 0 | `33a0f72167144bc7…` | `9a18f6c9ca8d8ea2…` |
| Dispatcher_5 | Dispatcher200c | SUCCEEDED / SUCCEEDED | 4321 / 4321 | 4321 | 0 / 0 | `051256e19cc2f6f0…` | `b8321faa8f816f81…` |
| Dispatcher_7 | Dispatcher200c | SUCCEEDED / SUCCEEDED | 2153 / 2153 | 2153 | 0 / 0 | `78610c538f6e94c2…` | `c0d5c8d199d3d5a5…` |
| Dispatcher_8 | Dispatcher200c | SUCCEEDED / SUCCEEDED | 2640 / 2640 | 2640 | 0 / 0 | `c5527167b94b3c03…` | `f1ab2652b3300c56…` |
| Dispatcher_9 | Dispatcher200c | SUCCEEDED / SUCCEEDED | 676 / 676 | 676 | 0 / 0 | `3ecea32b83a4a5ce…` | `57e2473f44883c9d…` |
| FreeList_5 | FreeList_5 | SUCCEEDED / SUCCEEDED | 724 / 724 | 940 | 4 / 0 | `d4cc15523e18f818…` | `3e987bcb84422733…` |
| Hpmcounter11Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `1ddb5bd650f855ab…` | `8934bca379d776e0…` |
| Hpmcounter12Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `5214b86a3658d142…` | `01593e099de0eabd…` |
| Hpmcounter13Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `0377fd418fc368ba…` | `f6665a3d8b815cf4…` |
| Hpmcounter14Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `76377e1412bc0a09…` | `f9066723ba29369c…` |
| Hpmcounter15Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `f429280ade619d07…` | `13d75f197505f60d…` |
| Hpmcounter16Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `fd1c3758fa7b30a6…` | `96cff0b0e17e8b7a…` |
| Hpmcounter17Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `e576b915a2b61854…` | `1f5acb445ca87dd9…` |
| Hpmcounter18Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `307bbf69d5b27656…` | `cb19ac4810bdf329…` |
| Hpmcounter19Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `ecd2d4281066c8a9…` | `e0b198c5baf4d8d8…` |
| Hpmcounter20Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `4eb40ac9b3d2fb18…` | `f5f4bcd656e09643…` |
| Hpmcounter21Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `5133972ac31ca447…` | `ec46b32456dc8d17…` |
| Hpmcounter22Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `1520b081b73a5497…` | `f6c124847445e57f…` |
| Hpmcounter23Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `9165aff244b241d9…` | `24aa5e0177ddcaeb…` |
| Hpmcounter24Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `cda329ee1c0d2c0d…` | `c5664d5391a25203…` |
| Hpmcounter25Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `ab97874e39b6b5f6…` | `b0538c7314fca80e…` |
| Hpmcounter26Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `0a4cd0eec5310067…` | `35eb1d7df403294d…` |
| Hpmcounter27Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `ae25adf109668821…` | `cbb618988853030a…` |
| Hpmcounter28Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `7058a8d88ffd811f…` | `e61521df1776d113…` |
| Hpmcounter29Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `da151a351cbd82e9…` | `a91b173e67928f8f…` |
| Hpmcounter30Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `04e4b93f820187e6…` | `9ac5121db2b4ee09…` |
| Hpmcounter31Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `c293fc30b73886f9…` | `8b8a846b2fb1c1c2…` |
| Mhpmcounter10Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 193 / 193 | 193 | 0 / 0 | `bd4728950824135f…` | `682a47cac6d6e43f…` |
| Mhpmcounter11Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 193 / 193 | 193 | 0 / 0 | `8eb1ff3266f6ce20…` | `a0aa381812e0474a…` |
| Mhpmcounter12Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 193 / 193 | 193 | 0 / 0 | `7f2616a5fd93de79…` | `3f8e7f9985eac1cb…` |
| Mhpmcounter13Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 193 / 193 | 193 | 0 / 0 | `8ccb0bfdbe09018d…` | `fc7a1df381dd2d29…` |
| Mhpmcounter14Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 193 / 193 | 193 | 0 / 0 | `cc139e8358126d75…` | `077418f64dd6105f…` |
| Mhpmcounter15Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 193 / 193 | 193 | 0 / 0 | `0ac6e905b8ff246d…` | `8c9e1d1f88bfe495…` |
| Mhpmcounter16Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 193 / 193 | 193 | 0 / 0 | `8cfe84c6a26e1994…` | `ced54412c9fc8d26…` |
| Mhpmcounter17Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 193 / 193 | 193 | 0 / 0 | `a078c87c3bab6e98…` | `89529801c682e220…` |
| Mhpmcounter18Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 193 / 193 | 193 | 0 / 0 | `fbba62872a24301d…` | `9c5eefa2dd258c15…` |
| Mhpmcounter19Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 193 / 193 | 193 | 0 / 0 | `e87092aec47889ca…` | `73949f0e91a7d25e…` |
| Mhpmcounter20Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 193 / 193 | 193 | 0 / 0 | `76096a7f9cbe4a5d…` | `7a95e32db93ff214…` |
| Mhpmcounter21Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 193 / 193 | 193 | 0 / 0 | `0ca1f0b2ad192a64…` | `80aa8b9996c281a3…` |
| Mhpmcounter22Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 193 / 193 | 193 | 0 / 0 | `0805887e83546b17…` | `0340e61d65996d33…` |
| Mhpmcounter23Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 193 / 193 | 193 | 0 / 0 | `2cd23578b7abd981…` | `67f4f4e8cf9fbe00…` |
| Mhpmcounter24Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 193 / 193 | 193 | 0 / 0 | `b05ac4d42473f314…` | `77c8469a7296f24c…` |
| Mhpmcounter25Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 193 / 193 | 193 | 0 / 0 | `fe09cf0d8b73b09b…` | `24818a8a85817002…` |
| Mhpmcounter26Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 193 / 193 | 193 | 0 / 0 | `d611926352bbedcc…` | `9e39d4bb0f122d03…` |
| Mhpmcounter27Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 193 / 193 | 193 | 0 / 0 | `36260abc15501b41…` | `2dfdc0c09bba858d…` |
| Mhpmcounter28Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 193 / 193 | 193 | 0 / 0 | `e1e53b28dcccceda…` | `f977457e58bbc90c…` |
| Mhpmcounter29Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 193 / 193 | 193 | 0 / 0 | `914760f22fc2a993…` | `ba97ac934aec274c…` |
| Mhpmcounter30Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 193 / 193 | 193 | 0 / 0 | `dd9dd7ab474b1c8f…` | `efbbfb5a48e1afc5…` |
| Mhpmcounter31Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 193 / 193 | 193 | 0 / 0 | `89773a9fa95e0b7a…` | `75d5ce353fc726fe…` |
| Mhpmcounter3Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 193 / 193 | 193 | 0 / 0 | `04ce078e1b5627c7…` | `5855e3ec7194b352…` |
| Mhpmcounter4Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 193 / 193 | 193 | 0 / 0 | `53b05cf08f405531…` | `4a30dbfff0b5556f…` |
| Mhpmcounter5Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 193 / 193 | 193 | 0 / 0 | `8dd989870dd025e4…` | `28f795d1c2117751…` |
| Mhpmcounter6Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 193 / 193 | 193 | 0 / 0 | `40345c640d289cf1…` | `95fd38dac4be213f…` |
| Mhpmcounter7Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 193 / 193 | 193 | 0 / 0 | `13709344d802fe8d…` | `620afc2b6ffdff33…` |
| Mhpmcounter8Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 193 / 193 | 193 | 0 / 0 | `fd38191cc1063259…` | `d7078e53f9e2b081…` |
| Mhpmcounter9Module | HpmCounterTailLeaves | SUCCEEDED / SUCCEEDED | 193 / 193 | 193 | 0 / 0 | `3d82fe2910482484…` | `f6748fd4e9523d6f…` |
| LqVAddrModule | LqVAddrModule | SUCCEEDED / SUCCEEDED | 5340 / 5340 | 5340 | 0 / 0 | `a2a2b3ea137c06ee…` | `833ac5662353c750…` |
| MbistBitmapCache | MbistBitmapCache | SUCCEEDED / SUCCEEDED | 661 / 661 | 661 | 0 / 0 | `45ec63fb79598f22…` | `96831382aada0526…` |
| Pma16cfgModule | PmaCfgTailLeaves | SUCCEEDED / SUCCEEDED | 24 / 24 | 24 | 0 / 0 | `f01a48fe0ff402d6…` | `a366569ae6f551dd…` |
| Pma17cfgModule | PmaCfgTailLeaves | SUCCEEDED / SUCCEEDED | 24 / 24 | 24 | 0 / 0 | `2af7f3ee67af90e3…` | `a4874f04ee98906c…` |
| Pma18cfgModule | PmaCfgTailLeaves | SUCCEEDED / SUCCEEDED | 24 / 24 | 24 | 0 / 0 | `40d56754dc99c8a2…` | `00ae4fe892e97326…` |
| Pma19cfgModule | PmaCfgTailLeaves | SUCCEEDED / SUCCEEDED | 24 / 24 | 24 | 0 / 0 | `03a06fe506508b25…` | `b191b927854f055a…` |
| Pma20cfgModule | PmaCfgTailLeaves | SUCCEEDED / SUCCEEDED | 24 / 24 | 24 | 0 / 0 | `99b8aa89245b5910…` | `688b4997a426738a…` |
| Pma21cfgModule | PmaCfgTailLeaves | SUCCEEDED / SUCCEEDED | 24 / 24 | 24 | 0 / 0 | `8723941cbb037234…` | `a1518ef57668a357…` |
| Pma22cfgModule | PmaCfgTailLeaves | SUCCEEDED / SUCCEEDED | 24 / 24 | 24 | 0 / 0 | `24c8f0c8c22a95b5…` | `af5b5e82f13c1799…` |
| Pma23cfgModule | PmaCfgTailLeaves | SUCCEEDED / SUCCEEDED | 24 / 24 | 24 | 0 / 0 | `d578f1b51ee20080…` | `20d0f5da01f65db5…` |
| Pma24cfgModule | PmaCfgTailLeaves | SUCCEEDED / SUCCEEDED | 24 / 24 | 24 | 0 / 0 | `3aa488bb921e45d0…` | `a6a21fe67650881d…` |
| Pma25cfgModule | PmaCfgTailLeaves | SUCCEEDED / SUCCEEDED | 24 / 24 | 24 | 0 / 0 | `ee6ccb37df4f5c93…` | `87fbcc513180b633…` |
| Pma26cfgModule | PmaCfgTailLeaves | SUCCEEDED / SUCCEEDED | 24 / 24 | 24 | 0 / 0 | `fd25d3f32c42050f…` | `e08797f2f309f3ce…` |
| Pma27cfgModule | PmaCfgTailLeaves | SUCCEEDED / SUCCEEDED | 24 / 24 | 24 | 0 / 0 | `7dff188185719a1e…` | `5640d780402c16a8…` |
| Pma28cfgModule | PmaCfgTailLeaves | SUCCEEDED / SUCCEEDED | 24 / 24 | 24 | 0 / 0 | `d4e19d7e26a8482b…` | `bde3559464ef0e22…` |
| Pma29cfgModule | PmaCfgTailLeaves | SUCCEEDED / SUCCEEDED | 24 / 24 | 24 | 0 / 0 | `e01dd97f7c1ea364…` | `a455851c5f0d5e7a…` |
| Pma30cfgModule | PmaCfgTailLeaves | SUCCEEDED / SUCCEEDED | 24 / 24 | 24 | 0 / 0 | `63d3ac87cd9d115b…` | `0444366d5b6ec148…` |
| Pma31cfgModule | PmaCfgTailLeaves | SUCCEEDED / SUCCEEDED | 24 / 24 | 24 | 0 / 0 | `5cf4abbabeb7a518…` | `4d42695d592ef8d5…` |
| Pmp21cfgModule | PmpCfgTailLeaves | SUCCEEDED / SUCCEEDED | 20 / 20 | 20 | 0 / 0 | `a37cda5e27ca8840…` | `f56c15f5bc7ee208…` |
| Pmp22cfgModule | PmpCfgTailLeaves | SUCCEEDED / SUCCEEDED | 20 / 20 | 20 | 0 / 0 | `5ba5609e1c80846c…` | `d4848fd26c0a03af…` |
| Pmp23cfgModule | PmpCfgTailLeaves | SUCCEEDED / SUCCEEDED | 20 / 20 | 20 | 0 / 0 | `417ab8b59afeb71f…` | `9cdaaa878de8c678…` |
| Pmp24cfgModule | PmpCfgTailLeaves | SUCCEEDED / SUCCEEDED | 20 / 20 | 20 | 0 / 0 | `8e5fe0fd4f5698be…` | `54a67accd7026fcd…` |
| Pmp25cfgModule | PmpCfgTailLeaves | SUCCEEDED / SUCCEEDED | 20 / 20 | 20 | 0 / 0 | `ec655221dedbefe4…` | `3776f0f0abba0581…` |
| Pmp26cfgModule | PmpCfgTailLeaves | SUCCEEDED / SUCCEEDED | 20 / 20 | 20 | 0 / 0 | `a58884a9e157c1e9…` | `178d72e448a0c86e…` |
| Pmp27cfgModule | PmpCfgTailLeaves | SUCCEEDED / SUCCEEDED | 20 / 20 | 20 | 0 / 0 | `319a127b39870676…` | `22ffd8be79f7360f…` |
| Pmp28cfgModule | PmpCfgTailLeaves | SUCCEEDED / SUCCEEDED | 20 / 20 | 20 | 0 / 0 | `71fa4bc9d3cfc8f9…` | `b8b046f06e956615…` |
| Pmp29cfgModule | PmpCfgTailLeaves | SUCCEEDED / SUCCEEDED | 20 / 20 | 20 | 0 / 0 | `512508089fc44f37…` | `99f8f638fa67bce6…` |
| Pmp30cfgModule | PmpCfgTailLeaves | SUCCEEDED / SUCCEEDED | 20 / 20 | 20 | 0 / 0 | `c5dcd643af3767cc…` | `e0fdec540e9a4062…` |
| Pmp31cfgModule | PmpCfgTailLeaves | SUCCEEDED / SUCCEEDED | 20 / 20 | 20 | 0 / 0 | `0f27ea961244bea5…` | `44646d6592ea9428…` |
| Queue1_CHIDAT | QueueChiSpillLogger200c | SUCCEEDED / SUCCEEDED | 847 / 847 | 847 | 0 / 0 | `d8fcd06f49b6ac3c…` | `bd18a5320dd90b17…` |
| Queue1_CHIRSP | QueueChiSpillLogger200c | SUCCEEDED / SUCCEEDED | 149 / 149 | 149 | 0 / 0 | `fcc3fe5c60b73f6f…` | `432cbc527380564c…` |
| TLLogger_1 | QueueChiSpillLogger200c | SUCCEEDED / SUCCEEDED | 644 / 644 | 644 | 0 / 0 | `af1a6a9481733825…` | `baf2f9e5e86469bb…` |
| TLLogger_2 | QueueChiSpillLogger200c | SUCCEEDED / SUCCEEDED | 641 / 641 | 641 | 0 / 0 | `c7e9817186627af7…` | `cf10c3c8b9c8ea10…` |
| DpcModule | csr_dh | SUCCEEDED / SUCCEEDED | 190 / 190 | 190 | 0 / 0 | `f332bbeed3c3bd00…` | `0417cb98936cec09…` |
| DretEventModule | csr_dh | SUCCEEDED / SUCCEEDED | 151 / 151 | 151 | 0 / 0 | `b52ed1021641c57c…` | `9bd32d5e5a93bac8…` |
| HcounterenModule | csr_dh | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `dfbb9cc5ccfbbed7…` | `2b64283ff166b2b6…` |
| HedelegModule | csr_dh | SUCCEEDED / SUCCEEDED | 92 / 92 | 92 | 0 / 0 | `d5ceca51b2e4589d…` | `4ceac23392448428…` |
| HenvcfgModule | csr_dh | SUCCEEDED / SUCCEEDED | 82 / 82 | 82 | 0 / 0 | `bbba6aa4ef3154ec…` | `f154dc94f09f92e0…` |
| HgatpModule | csr_dh | SUCCEEDED / SUCCEEDED | 178 / 178 | 188 | 1 / 0 | `6b26dd340102fc51…` | `e2861fb93f67f396…` |
| HidelegModule | csr_dh | SUCCEEDED / SUCCEEDED | 79 / 79 | 79 | 0 / 0 | `bc441832f86c7196…` | `dfb9167f6cc3a7cb…` |
| Hstateen0Module | csr_dh | SUCCEEDED / SUCCEEDED | 80 / 80 | 80 | 0 / 0 | `cb7d789e8f891db4…` | `2f37f64fd4f23a42…` |
| Hstateen1Module | csr_dh | SUCCEEDED / SUCCEEDED | 66 / 66 | 66 | 0 / 0 | `1c4282961fa61165…` | `186830b8290136a5…` |
| Hstateen2Module | csr_dh | SUCCEEDED / SUCCEEDED | 66 / 66 | 66 | 0 / 0 | `b633fb18155e9c2e…` | `a14f92f5bca4d85c…` |
| Hstateen3Module | csr_dh | SUCCEEDED / SUCCEEDED | 66 / 66 | 66 | 0 / 0 | `4c7073c4b0858586…` | `b72e0b6355238b92…` |
| HstatusModule | csr_dh | SUCCEEDED / SUCCEEDED | 94 / 94 | 94 | 0 / 0 | `1bb404fcc89a8357…` | `74e7dd6d75612554…` |
| HtimedeltaModule | csr_dh | SUCCEEDED / SUCCEEDED | 192 / 192 | 192 | 0 / 0 | `867b3f63911c34e2…` | `dab2846c2090b40c…` |
| HtinstModule | csr_dh | SUCCEEDED / SUCCEEDED | 192 / 192 | 192 | 0 / 0 | `b3773be7ff48d359…` | `d3c49dd9aae0ebee…` |
| HtvalModule | csr_dh | SUCCEEDED / SUCCEEDED | 192 / 192 | 192 | 0 / 0 | `c7d48364ecbf9b7a…` | `0dfefb82f532a203…` |
| HvictlModule | csr_dh | SUCCEEDED / SUCCEEDED | 110 / 110 | 110 | 0 / 0 | `c6d844257890e096…` | `1a294b3d2afe4343…` |
| Hviprio1Module | csr_dh | SUCCEEDED / SUCCEEDED | 144 / 144 | 144 | 0 / 0 | `fa6395d209c7888d…` | `173e308de84f00e0…` |
| Hviprio2Module | csr_dh | SUCCEEDED / SUCCEEDED | 192 / 192 | 192 | 0 / 0 | `1ea60a811a9fdfa4…` | `e5ba9e4567c0a4ec…` |
| MLevelPermitModule | csr_m | SUCCEEDED / SUCCEEDED | 3 / 3 | 3 | 0 / 0 | `a66d4518861188f4…` | `db3e0f0e6679bf64…` |
| MbmcModule | csr_m | SUCCEEDED / SUCCEEDED | 188 / 188 | 188 | 0 / 0 | `e89bf08f3db10f5b…` | `cff6230067b16cba…` |
| McontextModule | csr_m | SUCCEEDED / SUCCEEDED | 56 / 56 | 56 | 0 / 0 | `45cd53d38d68cd70…` | `86b8f7b8354d2d56…` |
| McorepwrModule | csr_m | SUCCEEDED / SUCCEEDED | 68 / 68 | 68 | 0 / 0 | `08b01070a9d38097…` | `e8cb26cc32fb7344…` |
| McounterenModule | csr_m | SUCCEEDED / SUCCEEDED | 128 / 128 | 128 | 0 / 0 | `b370b8ef0752a82d…` | `543241486888097d…` |
| McountinhibitModule | csr_m | SUCCEEDED / SUCCEEDED | 126 / 126 | 126 | 0 / 0 | `d442d94c661a83c2…` | `0041aa2561e636cf…` |
| MedelegModule | csr_m | SUCCEEDED / SUCCEEDED | 104 / 104 | 104 | 0 / 0 | `e94d5e8296c481f3…` | `60c789540cf61764…` |
| MenvcfgModule | csr_m | SUCCEEDED / SUCCEEDED | 82 / 82 | 82 | 0 / 0 | `809d4ac449f8c230…` | `8d3064af82fb5ec9…` |
| MflushpwrModule | csr_m | SUCCEEDED / SUCCEEDED | 67 / 67 | 67 | 0 / 0 | `d70576a85b790238…` | `9b5fdca2e6e1b1ac…` |
| IndirectCSRPermitModule | csr_permit | SUCCEEDED / SUCCEEDED | 2 / 2 | 2 | 0 / 0 | `09668dc41e9e1bd2…` | `7d29162ed5c9f075…` |

## 5. 依赖复核

- 全部 verif/allow/*.json 与 docs/、evidence/ 中检索这 171 张旧证书的 sha256：只有 `verif/allow/LoadQueueReplay.json` 引用
  AgeDetector_38（6 处，7df86b34… → 新 75381735…）、FreeList_5（2 处，3e987bcb… → 新 d4cc1552…）、LqVAddrModule（2 处，833ac566… → 新 a2a2b3ea…）。
  LoadQueueReplay **没有 tracked 证书**，按要求只报告，allow 未改。其余 168 张不被任何 allow 引用。
- 重证后 HEAD 5af6ca613 全量 validate：**True 504**（= 原 333 全部仍 True + 本 lane 171），非 True 只剩 POLICY / schema-v1（非证书）。

## 6. gate_all

\`TMPDIR=/home/eda/xs-env/tmp-r171 timeout 9000 bash scripts/gate_all.sh\` @ 5af6ca613：**GATE_RC=1**，263 道闸中唯一红项：

- \`round 台账幂等 ★FAIL\`：\`harvest_round_ledger --check: docs/fm_round_20260917.tsv 与 receipt 不一致\`——新增 171 份 receipt，
  派生表 docs/fm_round_20260917.tsv 待 integrator 重出（本 lane 不提交派生表）。同段的 WARN（TageTable* / L2TLB / Bku / FDivSqrt /
  Predictor / BitmapCache / Composer / PtwCache 多份 receipt 数字不一致）均为本 lane 之外的既有目标。
- \`receipt 收录表复算\`、\`覆盖率台账幂等\` 均 PASS（新 receipt 与旧 receipt 数字相同、目标集合不变）。
