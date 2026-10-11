# 认领（agent/l2tlb-gc，2026-10-11，Claude 集成者预建；codex 0228 问题 2）

本 lane 独占以下 target 的重证 / 制证 / green_child 组合，其他 agent 请勿领取：

- `L2TLBWrapper`、`L2TLB`
- L2TLB 的 22 个直接 child type：Arbiter1_L2TLBImp_Anon、Arbiter2_L2TLBImp_Anon、Arbiter2_L2TLBImp_Anon_1、
  Arbiter2_L2TlbWithHptwIdBundle、Arbiter2_PtwReq、Arbiter3_bitmapReqBundle、Arbiter3_L2TLBImp_Anon、
  Arbiter4_L2TlbMemReqBundle、Arbiter5_L2TlbWithHptwIdBundle、Bitmap、BitmapCache、DelayN_13、DelayN_220、
  DelayN_221、HPTW、L2TlbMissQueue、L2TlbPrefetch、LLPTW、PMP、PMPChecker、PTW、PtwCache
- 以及上述 child 证书闭包里需要重证的孙级 target

旧分支 agent/l2tlb-assembly（领先 main 13 提交，未合）只作参考，不再续做。
