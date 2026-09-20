# `verif/fm_target_config/` —— 每个 FM 目标自己那份证明数据

一个目标一份 `<FM_TOP>.tcl`。`scripts/fm_eq.tcl` 在进入任何证明语义之前，
**只 source 与 `FM_TOP` 同名的那一份**（不 glob、不 source 别的目标的文件）。

## 为什么有这个目录（量出来的，不是印象）

D57 把工具脚本算作证明输入，child 证书里记着 `scripts/fm_eq.tcl` 的 sha256。
但拆分前那个文件里**混着 per-target 数据**（vmucp 白名单 65 个名字 + 每个名字几十行
加入依据 + LoadQueueReplay 的专属 appvar 块），于是：

> ★任何一条 lane 往白名单里加一个名字，全仓所有 child 证书同时失效。★

实测（2026-09-20，基线 main `5c21fc56`，`verif/proof_certificates/*.json` 6 份）：

| script_closure 里的文件 | 6 份证书里的不同哈希 | 等于 HEAD 的份数 |
|---|---|---|
| `scripts/fm_eq.tcl` | **4** | **0 / 6** |
| `scripts/sidecar/fm_native_emit.tcl` | 2 | **4 / 6** |

两个文件受**同一条**绑定规则约束，一个全过期、一个多数不过期
⇒ 问题不在"绑定共享脚本"这个做法，而在 `fm_eq.tcl` 这一个文件的内容构成。

churn 的分布同样量过：最近 9 次非 merge 改动里 **8 次只碰 per-target 数据**
（7 次在白名单区，1 次在 LoadQueueReplay 的 appvar 块），只有 `cb2c646d`
改的是共享逻辑（`match_packed_payload` 把 field map 纳入字节快照）。

## ★这不是放宽★

绑定的总量没减，只是从"整个共享文件"换成"共享逻辑 + 本目标自己那份数据"：

    拆分前：证书绑 fm_eq.tcl（= 共享逻辑 + 全仓 65 个目标的数据）
    拆分后：证书绑 fm_eq.tcl（= 共享逻辑） + verif/fm_target_config/<top>.tcl

每一份**影响该目标**的字节仍然被某个 sha256 覆盖：

* 文件存在时：`fm_eq.tcl` 用 `source` 载入它，sidecar 的 source trace
  （`sidecar_source_trace` → `sidecar_register_script`）把它的原始字节快照进
  `sidecar/script_closure.list`，于是它进 receipt、进证书的 `script_closure.entries`，
  和 `fm_eq.tcl` 同等待遇。
* 文件**不存在**时（绝大多数目标）：这一情形不能靠"证书没记 ⇒ 本来就没有"糊过去 ——
  那样"事后给某个目标补一份配置"就会成为一条没人绑的缝。由
  `scripts/proof_certificate.py` 的 `green_child_target_config_added` 兜住：
  证书的 `script_closure` 里没有 `<child>.tcl` 时，**父 commit 上这个路径必须不存在**，
  否则 green_child 背书直接判红。

## 文件契约（fail-closed）

顶层只许出现三种东西，出现别的命令 `fm_eq.tcl` 立刻 `exit 3`：

```tcl
# 任意注释：本目标的加入依据、实测数字、复核判据，写多长都行
fm_target_vmucp_allow                                  ;# 在 vmucp 白名单上
fm_target_appvar verification_assume_reg_init none     ;# 本目标专属 appvar
```

* `fm_target_vmucp_allow`：有这一行 = 该目标允许开
  `FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=true`。没有文件、或文件里没有这一行，
  而调用方又开了 vmucp ⇒ 与拆分前**逐字同一条**报错 + `exit 3`。
* `fm_target_appvar <name> <value>`：只许改 sidecar 注册表里的 **OPTIONAL** 项
  （`verification_assume_reg_init` / `verification_set_undriven_signals` /
  `verification_propagate_const_reg_x` / `verification_blackbox_match_mode`）。
  `POLICY.json` 钉死的 required appvar **不许**被 per-target 覆盖 —— 那是全仓一致的
  证明语义，改它就不是"这个目标的数据"了。名字不在允许表内 ⇒ `exit 3`。
* per-target 文件里**不许有逻辑**（没有 `if`、没有 `proc`、没有 `set`）。逻辑只许在
  `scripts/fm_eq.tcl` 里，那样它才对所有目标一视同仁、一处 review 全仓生效。

## 怎么加一个目标

1. 新建 `verif/fm_target_config/<Top>.tcl`，把加入依据（基线数字、双射论证、
   **跑前预登记的复核判据**）写成注释，末尾 `fm_target_vmucp_allow`。
2. 跑 `python3 scripts/check_fm_eq_no_target_data.py`（顺带校验本目录）与
   `python3 scripts/test_fm_eq_wellformed.py`。
3. ★不要动 `scripts/fm_eq.tcl`★ —— 动了它就又把全仓证书打翻一遍，
   而且 `check_fm_eq_no_target_data.py` 会因为"按名字分支 / 新目标名"判红。

## 边界（如实记）

* 拆分本身的行为等价由 `scripts/fm_eq_split_equiv.py` 证过：12 个代表性
  (top, 环境) 的 **FM 调用序列逐字节相同**，外加 3 条判别性自证（白名单内/外必须不同、
  有/无 per-target appvar 必须不同、删掉数据文件里的声明 trace 必须变）。
* 那套差分用固定桩返回值，证的是**控制流与命令流一致**，不是"FM 会得出同样的结论"。
* sidecar 分支（`FM_SIDECAR_OUT` 非空）不在那套差分的覆盖内：拆分在 sidecar 一侧只多出
  一个 `source`，没有改 emitter 一个字节 —— 但**这是论证，不是那套差分测出来的**。
* 65 个目标里有 **15 个**（`DebugModule` `DuplicatedTagArray` `FTBBank`
  `ICacheCtrlUnit` `ICacheDataArray` `LinkMonitor` `Queue1_RegMapperInput_5`
  `SourceB` `TXDAT_4` `TXREQ` `TlbStorageWrapper{,_1,_2,_3}` `WritebackQueue`）
  **当初进白名单时就没把依据写进 `fm_eq.tcl`**；另有 `LoadQueueReplay` 只有 appvar
  的依据、没有白名单依据。拆分时如实照搬这个空缺，**没有补写**（补写就是编），
  它们的文件里写着到哪儿去找（`git log -S<Top> -- scripts/fm_eq.tcl`）。
  这是拆分**暴露**出来的既有缺口，不是拆分造成的。
