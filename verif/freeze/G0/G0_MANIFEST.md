# G0 隔离归档 manifest(2026-07-18)

> 回应二审:当前 golden(G0)provenance 有根本缺陷,**不能作正式签核基线**。本目录是
> **内容寻址的只读证据归档**,保住 G0 及其源码输入,供后续 B2(clean 重生验证)对比。
> 最终签核走 **B**(clean 重生):A0 隔离(本目录)→ B2 clean 重生 → 字节一致才晋升 canonical。

## 状态标记(硬约束)

```
baseline_id           = G0-89fe69e83a4f2ea8   (= sha256(canonical LC_ALL=C 排序的 G0-formal-rtl.manifest.tsv) 前16;
                        旧 b71c15e1 为 pre-canonical-sort, 内容同仅行序不同)
source_reproducible   = false
release_signoff_eligible = false
```

**所有旧 Formal 证据绑定 baseline_id = G0-89fe69e8。** A0 状态 = **CLOSED**(4 闭环缺口已补; 完整 descriptor 见 G0_DESCRIPTOR.tsv)。 在 B2 晋升 canonical 前,
任何 FM 结果都只是"对 G0 的待审证据",不构成 release 签核。

## 为什么 source_reproducible = false

golden 在 `xs-clean`(硬链拷贝主仓子模块的 worktree)中生成,provenance 破损:
- **仅 5/10 子模块**能由单一 clean commit 描述。
- coupledL2 / difftest / rocket-chip / utility = **dirty snapshot**(git 链接损坏,`rev-parse HEAD` 返回超级项目 commit)。
- ChiselAIA 缺可验证 git 元数据。
- 影响 RTL 的 huancun / openLLC 实际用 commit(90aaf593 / 614ceb4c)**≠ 超级项目 gitlink**(7c9d4cbb / e41f5393)。

→ "记录几个 SHA 后即可 clean clone 重建"**不成立**。字节 hash 只能证明"拿到的 golden 是否相同",
不能证明"如何从源码生成它"。

## 归档内容

| 文件/目录 | 内容 |
|-----------|------|
| `G0-full-output/` | 完整生成产物 1860 文件(含 SimTop.fir/conf/filelist/metadata)真实拷贝(非硬链),只读 |
| `G0-formal-rtl.list` | FM golden 子集:1854 文件(1802 .sv + 52 .v) |
| `G0-formal-rtl.manifest.tsv` | path⟂size⟂sha256,稳定排序;**总 155,100,650 字节** |
| `G0-full-output.list` | 完整 1860 文件清单 |
| `G0-source-snapshot.tar.gz` | **实际源码输入快照**(主仓+全子模块工作树 tracked+untracked+dirty,断开硬链的真实字节;排除 build/.git/sim 产物) |
| `G0-source-provenance/` | superproject HEAD/status/diff、submodule status、各子模块实际 HEAD+dirty、工具版本 |
| `BASELINE_ID` | `G0-b71c15e1a2f084c5` |

## 工具链(源码锁的一部分)

- JDK Temurin 17.0.13+11
- **firtool → FIRRTL version 3.3.0**(SimTop.fir 头确认;审查提及 firtool 1.62.1 对应此 FIRRTL 版本)
- mill / Chisel:随源码快照的 build.sc 锁定
- VCS/Verdi W-2024.09-SP1,Formality V-2023.12-SP3
- 配置 KunminghuV2Config,非 difftest,`make sim-verilog`(经 flow patch)

## 校验方法

```bash
cd G0-full-output && while IFS=$'\t' read f sz h; do
  [ "$(sha256sum "$f"|cut -d' ' -f1)" = "$h" ] || echo "MISMATCH $f"
done < ../G0-formal-rtl.manifest.tsv
```

## 下一步(B2)

从 `G0-source-snapshot.tar.gz` + 精确 patch + 固定工具在**全新目录** clean 重生 → 得 candidate `G0-rebuilt`
→ 比完整 tree manifest:
- **逐字节相同** → G0 得源码可复现证明,晋升 canonical golden,现有重写不返工。
- **不同** → 两份都留,再定 canonical(官方 c8bb+gitlinks 还是版本化实际 snapshot);经 G0↔G1 Formal 评估影响;最终签核对选定 canonical 全跑 305 项。
- 同一 source lock 同时产**两个** artifact:非 difftest(模块 Formal golden)+ difftest(CoreMark/Dhrystone ST golden),杜绝双基线来源漂移。
