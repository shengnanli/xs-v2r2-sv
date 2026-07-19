# B2_REGEN_ATTEMPT 结果(2026-07-18)

## 结论:1854 formal RTL 源码可复现 ✓(但**不**自动晋升 canonical)

从 G0 canonical 源码快照(1639 文件,无构建缓存)+ 锁定工具(firtool-1.62.1 / mill 0.12.3 /
JDK17)+ fail-closed git shim,在**全新目录** `/home/eda/xs-env/G0-rebuilt/` clean 重生:

- **全 1854 formal RTL(.sv/.v)逐字节差异 = 0**,含:
  - DUT 1853 文件(XSTop 及以下)差异 0;
  - **NewCSR.sv**(含 git 派生硬件常量 `gitCommitSHA=40'hC8BBD5C6AC`/`gitDirty=1'h1`)—— git shim 冻结 rev-parse/status 后逐字节复现;
  - **SimTop.sv**(harness,含 git 头 + `.__diff__`)—— shim 冻结 log/diff 后 hash 完全一致。
- 0 多余、0 缺失文件。
- diagnostic 价值:第一次跑 fail-closed shim 精确暴露漏的 `git rev-list <sha> --count`(VcsVersion 用解析后 SHA),补上重跑即全绿。

## 为什么仍不晋升 canonical(二审晋升门)

B2 只证 **1854 .sv/.v RTL artifact 可复现**,尚未证完整 source closure:
1. ~~未比完整 1860~~ **已比**: 1859 原始字节一致 + SimTop.fir 规范化(candidate-root→G0-root 单向替换, 断言 6,759,209 处)后一致 → **B2_CONTENT_REPRODUCED=true**。但 canonical 打包(chmod 0644 + 规范 manifest)未做 → **CANONICAL_PROMOTION=NO-GO**。
2. mill 锁的是下载 wrapper,非实际 Mill distribution/Coursier 依赖闭包 hash。
3. DTS/publishVersion artifact 尚未冻结(若 ST/启动流程用 DTS)。
4. A0 descriptor 状态/旧字段待统一。

→ 这四门全闭环后才 `source_reproducible=true` 并晋升 canonical,再启动正式 305 sweep。

## 意义

即便有上述待办,B2 已强力证明:**当前 golden 的功能 RTL(1854 文件)不是"某台机器的偶然产物",
而是从冻结源码 + 固定工具确定性可重建的**。这是签核可信度的基石——之前"source_reproducible=false"
是因 provenance 破损无法证明,现在 clean 重生逐字节一致把这一步做实了(在 1854 RTL 范围内)。
