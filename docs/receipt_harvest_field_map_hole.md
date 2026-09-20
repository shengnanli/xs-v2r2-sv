# ★证据 schema 的洞：FM_FIELD_MAP 的字节不在 receipt 里★

**这不是记账问题，是证据完整性问题。**
receipt 的整个契约是"这次证明的输入字节都在这里"。而实测有一类证明输入
**一个字节都没进去** —— 换掉那份文件，receipt 的每一个 sha256 都不变。

本文件是 `docs/receipt_harvest.tsv` 的附注：那张表把两个目标判成不可收，
理由就是这一条；理由不该只活在一次对话里。

---

## 机制：同一个 Makefile 块里，三个钉点输入，只有两个被留档

`scripts/ut_common.mk` 第 171-173 行，三行紧挨着：

```make
$(if $(wildcard fm_map/$*.txt),FM_FIELD_MAP=$(abspath fm_map/$*.txt),)   # ← 没留档
$(if $(wildcard fm_pins_pre.tcl),FM_PIN_PRE_TCL=$(abspath fm_pins_pre.tcl),)
$(if $(wildcard fm_pins.tcl),FM_PIN_TCL=$(abspath fm_pins.tcl),)
```

三个都是**钉点输入**，作用是一样的：决定 `set_user_match` 钉哪些点。
后两个进了字节快照，第一个没进。差别只在**怎么读进来的**：

| 输入 | fm_eq.tcl 里怎么读 | sidecar 挂在哪 | 进 `script_closure.list` |
|---|---|---|---|
| `FM_PIN_PRE_TCL` / `FM_PIN_TCL` | `source`（经 `sidecar_pin_source`） | `source` | ✔ 字节快照 + sha256 |
| `FM_FIELD_MAP` | `open`（`fm_eq.tcl:682`，`match_packed_payload`） | —— | ✘ **完全没有** |

`sidecar_register_script` / `sidecar_pin_source` 都是挂在 `source` 上的。
`match_packed_payload` 用 `open` 读这份文件、逐行解析成字段偏移，再据此
`set_user_match` —— 走的是数据路径，不是脚本路径，于是留档机制根本看不见它。

**这条比"判据看不见改变"更深一层**：前者是有输入、判据没盯住；
这里是**输入根本不在证据里**，连"它有没有变过"这个问题都问不出来。

---

## 实测（2026-09-20，扫全部 worktree 的 evidence/）

> 本节的数在**合 main（84 个 commit）之后逐条复核过一遍**，结论未变：
> 已进版本库的 receipt 里用了 field map 的仍然只有 `FauFTBWay` 一份（60 点）；
> `NewPipelineConnectPipe_35` 台账已绿但它**已收的那一份没用 field map**
> （`grep -acE '^PACKED_MATCH'` = 0），干净。
> 写这类"目前只影响 N 个"的话必须复核，因为 N 会随别人合并而变。

受影响 **14 份 receipt**（按 run+target 去重），两个家族：

| top | 钉了多少点 | `script_closure.list` 实际内容 |
|---|---|---|
| `FauFTBWay` | 60 | `sourced_000_fm_eq.tcl`, `sourced_001_fm_native_emit.tcl` |
| `NewPipelineConnectPipe_29` | 1023 | 同上（只有这两个） |
| `NewPipelineConnectPipe_34` | 760 | 同上 |
| `NewPipelineConnectPipe_35` | 1446 | 同上 |

判据是 `fm.log` 里**行首锚定**的那一行真实输出（不是脚本回显 —— `fm_shell`
把入口 Tcl 逐行回显进 log，不锚定行首会把源码里那句 `puts "PACKED_MATCH: ..."`
也数进来，实测不锚定是 469/469 全中，锚定后是 6 份）：

```
$ grep -aE '^PACKED_MATCH' evidence/40ec7fc36bb8/FauFTBWay/fm.log
PACKED_MATCH: 60 points pinned

$ cut -f2 evidence/40ec7fc36bb8/FauFTBWay/sidecar/script_closure.list
sourced_000_fm_eq.tcl
sourced_001_fm_native_emit.tcl
```

## ★更糟的一点：receipt 不是"没说"，是**说了相反的话**★

```
$ python3 -c "import json;print(json.load(open(
      'evidence/40ec7fc36bb8/FauFTBWay/receipt.json'))['proof_config']['pin_scripts'])"
{}
```

`pin_scripts = {}` 读起来是"这次证明没有钉点脚本"。而这次证明钉了 60 个点。
读表的人不会去翻 `fm.log`，他会信 receipt。
**缺失与否定在这里又一次长得一模一样** —— 空字典既可能是"真没钉"，
也可能是"钉了但这个字段管不着那种钉法"，从字段本身分不出来。

## ★而且它已经在承重★

`FauFTBWay`（golden 252 行）**不是待收目标，是已经算进 `proven` 的目标**：

```
$ git ls-files 'evidence/*/FauFTBWay/receipt.json'
evidence/40ec7fc36bb8/FauFTBWay/receipt.json          ← 已进版本库
$ grep -P '^FauFTBWay\t' docs/fm_round_20260917.tsv | cut -f1-2
FauFTBWay	SUCCEEDED                                  ← 台账已绿
$ python3 -c "import sys;sys.path.insert(0,'scripts');import rewrite_coverage as rc;
              print('FauFTBWay' in rc.proven_modules())"
True                                                   ← 计进头条数字
```

也就是说：今天的 `proven` 里，有一个目标的 60 个钉点来自一份**没有任何 receipt
绑定过版本**的文件。`verif/ut/*/fm_map/*.txt` 这 4 份确实被 git 跟踪
（字节可以从 git 里找回来），但**没有任何东西把某一份 receipt 和它当时读的那一版
绑在一起** —— 跟踪≠绑定，这正是本仓一直在防的那个差别。

`NewPipelineConnectPipe_29/_34/_35`：**已进版本库的那一份（`40ec7fc36bb8`）
没用 field map**（`grep -acE '^PACKED_MATCH'` = 0），干净；
用了 field map 的是 `wt-mismatch` 的两轮 lane 证据，尚未收录。
所以目前**承重的只有 `FauFTBWay` 一个**，但机制上任何用 `fm_map/` 的目标都一样。

---

## 修法（方向，排期不在本 lane）

1. `match_packed_payload` 读 `FM_FIELD_MAP` 之前，调一次和 `sidecar_pin_source`
   同源的字节留档（`sidecar_snapshot_buffer` 已经是按"原始字节 → digest"写的，
   直接复用即可），让它进 `script_closure.list`；
2. `proof_config` 里给它一个**自己的**字段（别塞进 `pin_scripts`，那是 Tcl 脚本的位置），
   例如 `field_maps: {"<top>.txt": "<sha256>"}`；没有就写明"本次未使用"，
   而不是留一个既表示"没有"又表示"管不着"的空字典；
3. 上面两条落地前，`FauFTBWay` 这类目标的 receipt **不能当成闭包完整**；
   `scripts/gen_receipt_harvest.py` 已经按这一条把它们判成不可收
   （`judge()` 里的 `r['packed']` 分支），但它只管**待收**的，
   管不到**已经收进去的** —— 已收的那一个要靠重跑补齐。

## 复算

```
python3 - <<'EOF'
import os, re, subprocess
P = re.compile(r'^PACKED_MATCH: (\d+) points pinned', re.M)
wts = [l.split()[0] for l in subprocess.run(['git','worktree','list'],
       stdout=subprocess.PIPE).stdout.decode().splitlines()]
for wt in sorted(wts):
    ev = os.path.join(wt, 'evidence')
    for run in sorted(os.listdir(ev)) if os.path.isdir(ev) else []:
        for tgt in sorted(os.listdir(os.path.join(ev, run))):
            fl = os.path.join(ev, run, tgt, 'fm.log')
            if not os.path.isfile(fl): continue
            m = P.search(open(fl, errors='replace').read())
            if m: print(run, tgt, m.group(1))
EOF
```
