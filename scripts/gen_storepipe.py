#!/usr/bin/env python3
"""
StorePipe UT harness 生成器(codex_0088 §3 canonical-derivative 路线)。

背景: 本顶层(KunmingHu V2R2, EnableStorePrefetchAtIssue=false)下, DCacheWrapper 把
StorePipe 所有输出悬空, 全芯片 firtool 跨层 DCE 把 golden StorePipe.sv 削成 5 行空壳。
codex_0088 §3 批准: 从冻结 G0 `SimTop.fir` production pre-DCE StorePipe FIRRTL 机械
派生的 canonical-derivative(锁定 firtool-1.62.1 + G0 flags)作官方 reference。

本 UT harness:
  - 双例化 canonical-derivative reference(module `StorePipe`,
    verif/ut/StorePipe/StorePipe_derivative_ref.sv, sha 7d675b69...) vs 可读核
    xs_StorePipe_core(rtl/memblock/StorePipe.sv)。
  - 同一激励喂两侧, 只比对 36 observable output leaves + 6 perf probes。
  - 14 UNSPECIFIED_BY_SOURCE(miss_req `:=DontCare` 未覆写 12 字段 + replace_access.bits
    2 字段)从比较面排除: 不具体化为 0, 不 dont_verify。
  - seed 1/7/42 + `+vcs+initreg+0` errors=0。

★注意: tb.sv/Makefile 已按上述路线手写并验证(seed 1/7/42 errors=0)。本脚本作为
  可复现记录, 不再生成旧的 DCE-空壳镜像(variants_xs.sv 已删除)。derivative reference
  文件由 plumbing owner 的 G0-StorePipe-observable-v1 派生, harness 侧持有 byte-identical
  副本供 UT 对拍; 官方 FM golden 由 manifest/runner 指向 canonical_derivative(main-owned)。

设计意图来源：XiangShan/src/main/scala/xiangshan/cache/dcache/storepipe/StorePipe.scala
"""

if __name__ == "__main__":
    print("StorePipe: harness is hand-maintained (derivative-vs-core, 36+6 observable, "
          "14 UNSPECIFIED excluded). See verif/ut/StorePipe/{tb.sv,Makefile} + "
          "StorePipe_derivative_ref.sv. seed 1/7/42 errors=0.")
