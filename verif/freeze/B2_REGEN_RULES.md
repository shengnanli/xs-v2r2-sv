# B2:从 G0 源码快照 clean 重生规则(2026-07)

> 目的:在**全新物理目录**用 G0 的 canonical 源码快照 + 固定工具重生 golden,与 G0 逐字节比对,
> 判定 G0 是否**源码可复现**。字节一致 → G0 晋升 canonical;不一致 → 两份都留、再定 baseline。
> **绝不覆盖 G0**(隔离区 `/home/eda/xs-env/G0-quarantine/` 只读)。

## 输入(全部来自 G0 隔离区,不依赖坏掉的 xs-clean)

| 项 | 来源 | 校验 |
|----|------|------|
| canonical 源码 | `G0-quarantine/G0-source-canonical.tar.gz`(1639 文件,**无 out/构建缓存**) | tar sha256 见 `G0_DESCRIPTOR.tsv`;解包后比 `G0-source-canonical.manifest.tsv` |
| flow patch | 源码快照内的 `Makefile` / `build.sc`(已含 patch 状态)+ `tools/kunminghu_v2r2_flow.sh` | 与快照一致 |
| 工具链 | firtool **CIRCT firtool-1.62.1**、FIRRTL dialect 3.3.0、JDK Temurin 17.0.13+11 | B2 时定位 firtool 二进制/jar 记 hash,写回 descriptor |
| 配置/命令 | `KunminghuV2Config`,**非 difftest**,`make sim-verilog` | 见下命令 |

## 铁律

1. **新物理目录**(如 `/home/eda/xs-env/G0-rebuilt/`),与 xs-clean / 主仓 / G0 隔离区**互不硬链**。
2. **不复用** 任何 `.git` / `out/` / `build/` / `target/` / mill 缓存 —— 从 canonical tar 干净解包(canonical 已排除这些)。
3. 子模块:canonical 快照已含各子模块工作树**实际内容**(含 DRIFTED/DIRTY 的真实字节),**直接用快照内容**,**不跑 `git submodule update`**(那会取到 gitlink 的 7c9d4cbb 等 ≠ 实际用的 90aaf593)。
4. 环境变量 `NOOP_HOME`/`NEMU_HOME` 指向新目录;`JAVA_HOME` 指固定 JDK。
5. 生成后**只读锁定** candidate,再比对。

## 步骤

```bash
G0=/home/eda/xs-env/G0-quarantine
RB=/home/eda/xs-env/G0-rebuilt
mkdir -p "$RB" && cd "$RB"
# 1. 干净解包 canonical 源码(校验 tar hash 先)
sha256sum "$G0/G0-source-canonical.tar.gz"   # 须 == descriptor 记录
tar xzf "$G0/G0-source-canonical.tar.gz"
# 2. 校验解包内容 == manifest
while IFS=$'\t' read f sz h; do
  [ "$(sha256sum "$f"|cut -d' ' -f1)" = "$h" ] || echo "SRC-MISMATCH $f"
done < "$G0/G0-source-canonical.manifest.tsv"
# 3. 固定工具重生(非 difftest;不 submodule update)
export NOOP_HOME="$RB" NEMU_HOME="$RB"
export JAVA_HOME=/home/eda/xs-env/toolchain/jdk-17.0.13+11 PATH="$JAVA_HOME/bin:$PATH"
make sim-verilog CONFIG=KunminghuV2Config   # 与 G0 同命令
# 4. 生成 candidate 完整 manifest(同 A0 方法, LC_ALL=C)
#    比 G0-full-output.manifest.tsv 与 G0-formal-rtl.manifest.tsv
```

## 判定

```bash
# formal-rtl 逐字节比(权威)
diff <(LC_ALL=C sort "$G0/G0-formal-rtl.manifest.tsv") \
     <(cd "$RB/build/rtl" && for f in $(cat "$G0/G0-formal-rtl.list"); do
         printf '%s\t%s\t%s\n' "$f" "$(stat -c%s "$f")" "$(sha256sum "$f"|cut -d' ' -f1)"; done | LC_ALL=C sort)
```

- **完全一致(0 diff)** → G0 得源码可复现证明,`source_reproducible=true`,晋升 **canonical golden**;现有重写/FM 不因 baseline 变化返工。
- **不一致** → **两份都保留,绝不覆盖**。逐文件差异映射到 target ref closure;可先做 G0↔candidate 的 Formal 影响评估;再明确 canonical 目标(官方 c8bb+gitlinks 版 vs 版本化的实际 snapshot 版)。最终签核对**选定的** canonical 全跑 305 项。

## 双 artifact(杜绝双基线来源漂移)

从**同一 source lock** 产两个独立 artifact:
- **非 difftest** → 模块 Formal golden(305 项 FM 对标)。
- **difftest enabled** → CoreMark/Dhrystone ST golden(周期级 parity)。

两者同源,消除此前"FM 基线 vs ST 基线来源漂移"。命令区别仅 `--enable-difftest`(见 Makefile flow patch)。

## 前置门(未过不启动 B2)

- [x] A0 CLOSED(4 缺口补齐,descriptor 完整)
- [x] parser 全 P0 修订(24/24 负向测试)
- [ ] 唯一权威 FM 入口(fm_eq.tcl 读 FM_INTERFACE_ONLY + mode 分流)—— B2 本身不需要(B2 只重生+比字节),但**在 305 sweep 前**必须。
