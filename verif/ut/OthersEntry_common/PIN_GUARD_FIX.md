# 钉点守卫修复：为什么 18 份 receipt 不必重跑（★证据，不是声明★）

## 改了什么

`verif/ut/OthersEntry_common/gen_fm_pins.py` 的钉点循环：
`if {[catch {set_user_match ...} _msg]}` → `if {[set_user_match ...]}`，
并加 `OE_PIN_BEGIN/END` 标记。**没有改任何一对钉点。**

## 为什么旧写法是空守卫（真 fm_shell 实测）

2026-09-20，`fm_shell -64`（V-2023.12-SP3），ref/impl 都读真文件：

| 调用 | 返回值 | 日志 |
|---|---|---|
| 名字存在 | `1` | 无 |
| 名字不存在 | `0` | `Error: Unknown name: ... (FM-036)` |
| `catch {set_user_match ...}` | `0`（**从不抛**） | 同上 |

⇒ 旧写法里 `else` 支恒成立：`_miss` 恒 0、`_n` 恒等于总数，
**两道守卫（含我后来"加强"的那道 `_n != expect`）都是空的。**

## 前后对照：同一个注入 typo、同一个 fm_shell

把 `OthersEntry_166` 钉点表里第一对的 ref 名改一个字母：

| 版本 | 输出 | 判决 |
|---|---|---|
| 旧（catch 计数） | `OE_PINS: 822 / 822 tried, 0 threw` | ★完全没响★ |
| 新（返回值计数） | `OE_PIN_FAIL: ...` / `n=821 miss=1 expect=822` / `error` 真的抛出 | 红 |

两次日志里都有且仅有 1 条 `FM-036` —— 错误一直被报，只是旧版不采取行动。

## ★调用序列逐字节相同（这才是"不必重跑"的依据）★

`fm_pins*.tcl` 在证明闭包里，改了它先前的 receipt 就成了旧前提。
判据不是"我觉得只动了守卫"，是把 `set_user_match` 换成记录参数的桩、
用 tclsh 真跑两版、逐字节比对**实际发生的调用序列**（含顺序与重复）：

复算：`python3 verif/ut/OthersEntry_common/prove_pin_calls_equal.py <旧文件目录> <变体...>`

| 变体 | 调用数 | 调用序列 sha256（新旧相同） |
|---|---|---|
| `OthersEntry_44` | 1428 | `891157120130bdbf` |
| `OthersEntry_50` | 665 | `adb1a5c10dc2ebb4` |
| `OthersEntry_66` | 1428 | `dc8ecd6ce257a14a` |
| `OthersEntry_72` | 652 | `1f43a8af27f02ed9` |
| `OthersEntry` | 1428 | `44472d3fb07ec89a` |
| `OthersEntry_6` | 651 | `fc4500f61e3b00f6` |
| `OthersEntry_88` | 1407 | `1bb4e7971e544100` |
| `OthersEntry_90` | 607 | `a70d32b0fa4a5080` |
| `OthersEntry_104` | 1407 | `5dfc3387c09a8c78` |
| `OthersEntry_106` | 605 | `2fb05dc8f3da468c` |
| `OthersEntry_120` | 1407 | `cfd501386e10b708` |
| `OthersEntry_122` | 604 | `48226bc406741450` |
| `OthersEntry_164` | 1442 | `55a56941b1dfbd50` |
| `OthersEntry_166` | 822 | `06c2228cab5dd102` |
| `OthersEntry_150` | 1442 | `e1674c91685cd32c` |
| `OthersEntry_152` | 824 | `1acb8eeb6ef9ca85` |
| `OthersEntry_136` | 1457 | `e6d93514a20fbb80` |
| `OthersEntry_138` | 841 | `01321779d2907505` |

18/18 逐字节相同 ⇒ 「钉了哪些点」这一维度上闭包没变，
`evidence/9c2517d9*/` 那 18 份 receipt 继续有效。

★诚实标注★：receipt 里记的 `proof_config.pin_scripts` sha256 与当前工作树**已不同**
（因为守卫文本变了）。桥接它的就是上面这张表，不是口头保证。
如果哪天调用序列真的变了，按规矩必须在一个 commit 上重出全部 receipt。
