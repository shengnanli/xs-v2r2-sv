# xstop_bbox3 —— boundary universe 提取产物（可复算输入，非日志）

`docs/g1_boundary_ledger.tsv` 头部 `hierarchy_sha256=8bbf2b1bb1bf3f13` 指的就是本目录
`xstop_hierarchy.txt.gz` **解压后**的文件。三轴口径里 95/44 这个劈分只能由它算出。

## 为什么必须入库

这份产物是 4.11 小时、23.3 GB 峰值的一次 Formality elaborate 的唯一输出（前两次
`xstop_bbox` / `xstop_bbox2` 都失败了，各只有 4KB，见 MANIFEST 对比）。此前它只存在于
**会话临时目录**，仓库里一份没有：

- 有它  → `provenance=fm_hierarchy`，`1814(WORK) + 95(BBOX) + 44(BEHIND) = 1953`
- 没有它 → `provenance=static_only`，`1814(WORK) + 139(BBOX) + 0(BEHIND) = 1953`

总数和 1814 两版都稳定，**只有 95/44 的劈分会动**。也就是说 clean clone 此前根本重算
不出 D71 条件 4 要的那两个数——这与"证明输入未跟踪 / 日志被 gitignore 导致 clean clone
不可复现"是同一个病（codex 0152 §5 本就要求保留 raw hierarchy/report 以保证可复算）。

注意 `evidence/` 在 .gitignore 第 21 行，所以**不能**放那里，否则等于没入库。

## 复算

```
gunzip -c verif/universe/xstop_bbox3/xstop_hierarchy.txt.gz > /tmp/h.txt
sha256sum /tmp/h.txt            # 前16位须为 8bbf2b1bb1bf3f13
python3 scripts/boundary_ledger.py --repo . --hierarchy /tmp/h.txt
# → 守恒: 1814(WORK) + 95(BBOX) + 44(BEHIND) = 1953 == 静态闭包 1953
```

`MANIFEST.tsv` 记的是**解压后**的 sha256（台账绑定的是未压缩指纹），gz 只是存储形式。

## 仍未闭合

`boundary_ledger.py` 除本产物外还读 `docs/receipt_index.tsv`（当前 **untracked**）。
本目录只解决了 hierarchy 这一半；receipt_index 那一半仍是 D66 缺陷，该生成器仍无 owner。
另：`docs/g1_boundary_ledger.tsv` 头部 `registry_sha256=e9709ae3d7788632` 相对当前
registry（26 条）已过期，待 owner 重生成时一并更新。
