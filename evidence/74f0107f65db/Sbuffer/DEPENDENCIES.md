# Sbuffer 签核依赖声明（挂在 receipt 旁边，和证据同 commit）

对应 `receipt.json`：
`run_id = Sbuffer-20260920T063720Z-74f0107f`，
`impl_commit = 74f0107f65db644825d4f25c755950423fbb84be`，
`g1_canonical_id = G1-a4ea14f2ddf612bb4ad023d26a2ca1bf33eddcaebe470b0c620e9fba0e7afcf0`，
`verdict = SUCCEEDED`，`impl_worktree_dirty = false`。

## ★完整目标 `Sbuffer` 的状态：UNPROVEN★

FM 本身是干净的绿（signoff-strict / passing 28,329 / failing 0 / unmatched 六类全 0 /
unread_notcompared 0 / 零黑盒 / 零 allowlist / 无 dont_verify / 无 relaxed appvar），
**但它是条件性的**，条件在下面这张表里。按 codex 0168 的裁定，
**不许**据此把 `Sbuffer` 记 `PROVEN_DIRECT`。

## 子依赖闭包

| child | impl 侧喂的是 | 本 target 对它的信息量 | 状态 | 机器可核处 |
|---|---|---|---|---|
| `SbufferData` | **重写件** `rtl/memblock/SbufferData.sv`（`df1ec7f762638157da7a1063d566b67c89b9afd9097b7b4e5aed1c6c8937d98c`） | **真比对**（ref 是 golden `SbufferData.sv`，两侧不同字节） | `REWRITTEN` / **`UNPROVEN`** —— 它**自己的** FM 目标（`verif/ut/SbufferData/`）还没跑过，`evidence/` 下无它的 receipt | `receipt.json` → `impl_closure[1].kind == "repo"` |
| `StorePfWrapper` | **golden 字节** `golden-rtl/StorePfWrapper.sv`（`6668f5b100d95192239c6ff430d888b037c4e2bf43324afdd50cc01e9b8277fc`） | **零** | `MISSING` / `UNPROVEN` · **`UNCHANGED_GOLDEN_DEP`** | `receipt.json` → `impl_closure[2].kind == "golden"` |
| `Serializer` | **golden 字节** `golden-rtl/Serializer.sv`（`e52772ba1969e9d9735b19a93cf6d39de95b68a5b7f82c00892da0dae8243456`） | **零** | `MISSING` / `UNPROVEN` · **`UNCHANGED_GOLDEN_DEP`** | `receipt.json` → `impl_closure[3].kind == "golden"` |

★`kind: "golden"` 就是"这一块 impl 侧用的是 golden 自己"的机器可核标记★ ——
不需要读这份文档也能查出来：

```
python3 -c "import json;print([(e['kind'],e['path']) for e in json.load(open('receipt.json'))['impl_closure']])"
```

改指之前，`golden-rtl/SbufferData.sv` 也在这张 `kind=golden` 的名单里 —— 那就是假绿。
现在它不在了。

## `StorePfWrapper` / `Serializer` 为什么两侧同喂 golden（而不是黑盒）

codex 0168 给了两条路，本 lane 选**两侧白盒展开真实 child 行为**，不扩黑盒。
理由是 KunminghuV2Config 下 firtool 已把这两个模块 DCE 成**没有任何功能端口的空壳**：
两者端口表都只有 `(clock, reset)`，`Serializer` 里那 5 bit 寄存器
（`enqPtrExt_0_flag` + `enqPtrExt_0_value[3:0]`）**没有任何 fanout 到端口**，
这棵子树对 `Sbuffer` 的任何输出都不可达。于是：

- 黑盒配对买不到东西（零输出的黑盒不向父级引入自由变量），
  却要付 `unresolved_blackbox` 非零 + 判决挂在两个未签核 child 上的代价；
- 白盒展开能把 glue（`prefetcher` 实例存在性与 clock/reset 接线）真的比出来，
  那 5 bit 两侧配对受验，一处不遮。

本次 `verdict_detail.constant_reg = 5` 正是这 5 bit（`constant_reg_toggle_assumed = false`）。

★但这**不构成**对这两个模块的证明★：impl 侧用的是 golden 字节，
换成任何别的实现都不会被本 target 发现。所以照实记 `UNCHANGED_GOLDEN_DEP`。

## 要把 `Sbuffer` 变成无条件已证，还差什么

1. `SbufferData` 跑自己的 FM 并拿到 `SIGNOFF_PASS`（`verif/ut/SbufferData/` 已就绪）；
2. `StorePfWrapper` 与 `Serializer` 各自写出重写件、跑自己的 FM；
   在此之前 `Sbuffer` 的 impl 侧对它们只能继续用 golden，
   或者按"独立签核目标条件黑盒"的路子挂在它们的绿目标上。

在 1、2 都闭合之前，`Sbuffer` 在台账里应保持 **UNPROVEN**，
本 receipt 只支持上面那句带前提的条件性结论。
