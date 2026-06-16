// =============================================================================
// xs_StorePfWrapper_core —— store 预取薄包装层的可读重写核
// -----------------------------------------------------------------------------
// 设计意图来源：
//   XiangShan/src/main/scala/xiangshan/mem/sbuffer/StorePrefetchBursts.scala
//
// StorePfWrapper 在 Sbuffer 旁边，把每拍最多两路已提交 store 训练流接到
// Serializer，再把串行化后的一路训练送入 StorePrefetchBursts(SPB)。SPB 观察连续
// store 的 cache block 步长：store_count 超过阈值 N=48 且“store_count/8 等于累积
// block 差值、差值非负”时，认为出现顺序 store burst，并向 DCache 发起后续行预取。
//
// 当前 V2R2 golden 配置里 EnableStorePrefetchSPB=false。Chisel 常量传播后，wrapper
// 对外只剩 clock/reset 和两路 prefetch vaddr；store 输入、valid/ready 握手被裁掉。
// 因此本可读核保留“SPB 输出经 wrapper 透传”的结构，具体 Serializer/SPB 子模块在
// StorePfWrapper_wrapper.sv 与 UT variant 中作为 golden 黑盒例化，确保两侧共享同一
// 份子模块行为。
// =============================================================================
module xs_StorePfWrapper_core
  import storepfwrapper_pkg::*;
(
  input  logic [VADDR_BITS-1:0] spb_prefetch_vaddr [PREFETCH_REQ_LANES],
  output logic [VADDR_BITS-1:0] io_prefetch_vaddr  [PREFETCH_REQ_LANES]
);

  // 把 SPB 的扁平输出聚合成有语义的请求 bundle。即便当前配置没有 valid 端口，
  // “每个 lane 是一个 StorePrefetchReq”这个事实仍然比散落的 50 位 wire 更容易读。
  store_prefetch_req_t spb_req [PREFETCH_REQ_LANES];
  store_prefetch_req_t out_req [PREFETCH_REQ_LANES];
  prefetch_source_e    source_for_lane [PREFETCH_REQ_LANES];

  function automatic store_prefetch_req_t make_prefetch_req(
      input logic [VADDR_BITS-1:0] vaddr);
    store_prefetch_req_t req;
    req.vaddr = vaddr;
    return req;
  endfunction

  function automatic store_prefetch_req_t select_prefetch_req(
      input prefetch_source_e source,
      input store_prefetch_req_t spb);
    store_prefetch_req_t selected;
    selected = '0;
    priority case (source)
      PF_SRC_SPB:      selected = spb;
      PF_SRC_DISABLED: selected = '0;
      default:         selected = '0;
    endcase
    return selected;
  endfunction

  genvar lane;
  generate
    for (lane = 0; lane < PREFETCH_REQ_LANES; lane++) begin : g_prefetch_lane
      always_comb begin
        // Scala 中 io.prefetch_req <> spb.io.prefetch_req 是纯 Decoupled 连接。
        // 在本配置下 valid/ready 被常量裁掉，只留下 bits.vaddr；因此这里是无状态透传。
        spb_req[lane] = make_prefetch_req(spb_prefetch_vaddr[lane]);

        // lane1 在 PrefetchBurstGenerator 中表示 lane0 的下一条 cacheline。wrapper 不
        // 重新生成地址；它只保持 SPB 的两路请求和 DCache store prefetch 端口一一对应。
        source_for_lane[lane] = PF_SRC_SPB;
        out_req[lane] = select_prefetch_req(source_for_lane[lane], spb_req[lane]);
        io_prefetch_vaddr[lane] = out_req[lane].vaddr;
      end
    end
  endgenerate

endmodule
