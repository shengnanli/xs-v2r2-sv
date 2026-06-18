// =============================================================================
// wbfubusytable_pkg —— 香山 V2R2(昆明湖) 写回 FU 忙表(WbFuBusyTable) 类型/参数定义
// -----------------------------------------------------------------------------
// 对应 Scala 源 `xiangshan.backend.datapath.WbFuBusyTable.scala`。
//
// 【WbFuBusyTable 在后端的位置与作用】
//   后端各执行单元(EXU)算完结果, 要经 WbDataPath 的写回仲裁器(RealWBArbiter)抢一个
//   物理寄存器写回端口。写回端口数量 < EXU 数量, 是稀缺资源, 必须避免冲突。
//   调度器(IssueQueue)在**发射**一条不定延迟指令前, 需预知它未来某拍出结果时,
//   目标写回端口是否已被别的、延迟确定的指令占用。
//
//   WbFuBusyTable 就是这张"未来占用预约表":
//     * 每个写回端口维护一张 busyTable("未来 N 拍占用位图", 由各 IssueQueue 产生送入,
//       本模块只做**按端口归并**)。
//     * 同一写回端口上所有延迟确定的源 EXU 的占用位图**按位 OR** → 该端口总占用表。
//     * 再把每个端口总表**读回**给挂在该端口上的各 IssueQueue, 供其发射时避让。
//   纯组合: 写入(归并) + 读出(扇出), 无状态。
//
// 【关键抽象】(对应 Scala writeBusyTable / readRes)
//   writeBusyTable: busyTable[port] = OR_{src 命中 port} src.busyTable (短源零扩展)
//   readRes       : reader.out = busyTable[reader 的 port], 截到/扩到 reader 宽度
//   忙表位 i 的物理含义: "从现在起第 i 拍, 该写回端口将被占用"; OR 即"任一源占用则占用"。
// =============================================================================
package wbfubusytable_pkg;

  // 端口总表的统一承载宽度: 本配置下最宽的写回端口忙表为 5 位, 取 8 位留裕量并便于截片。
  localparam int unsigned PORT_W = 8;

  // 读出对齐: 把端口忙表 src 取低 width 位作为某 reader 的可见忙表。
  // 对应 Scala readRes `src.asTypeOf(sink).asUInt` —— sink 比 src 窄则截断, 宽则零扩展。
  function automatic logic [PORT_W-1:0] busy_read(input logic [PORT_W-1:0] src,
                                                  input int unsigned width);
    logic [PORT_W-1:0] mask;
    mask = (width >= PORT_W) ? '1 : (({{(PORT_W-1){1'b0}}, 1'b1}) << width) - 1;
    return src & mask;
  endfunction

endpackage : wbfubusytable_pkg
