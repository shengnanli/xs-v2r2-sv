// =============================================================================
//  StorePipe_wrapper —— golden 同名顶层 `StorePipe`(本配置 firtool 裁剪后接口)
// -----------------------------------------------------------------------------
//  本顶层配置(KunmingHu V2R2)下 golden StorePipe 仅剩 input io_lsu_req_valid:
//  DCache 例化 StorePipe 时其所有输出悬空(DontCare) + EnableStorePrefetchAtIssue=false,
//  firtool 常量传播/死代码消除后只留这唯一端口。为与 golden 逐端口一致(供 FM / ST),
//  顶层只暴露这唯一端口, 内部直通 probe(无下游逻辑)。
//
//  StorePipe 完整三级流水(s0/s1/s2)的可读实现见 rtl/memblock/StorePipe.sv 的
//  xs_StorePipe_core, 学习文档见 docs/memblock/StorePipe.md —— 那才是本任务的设计载体;
//  本 wrapper 只是裁剪配置下的机械端口适配。
// =============================================================================
module StorePipe(
  input io_lsu_req_valid
);
  // golden 行为: 仅把请求 valid 透传(无下游逻辑, 与 golden 逐位一致)。
  wire io_lsu_req_valid_probe = io_lsu_req_valid;
endmodule
