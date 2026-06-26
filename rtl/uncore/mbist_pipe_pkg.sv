// =============================================================================
//  MBIST 流水分发节点 类型/常量包 (mbist_pipe_pkg)
// -----------------------------------------------------------------------------
//  L2Slice / L2Directory / L2DataStorage 三者本质上是**同一个** Chisel 模块
//  utility.mbist.MbistPipeline 的三个单态化实例，由香山 coupledL2 (L2 缓存) 的
//  Slice / Directory / DataStorage 三层在综合时自动插入，用于把芯片级 MBIST
//  (Memory Built-In Self Test，内存自测试) 总线请求**逐层分发**到一棵以 SRAM
//  为叶子的测试树。它们并不是 L2 的数据/目录功能逻辑，而是 SRAM 测试互联。
//
//  ---- MBIST 标准请求/响应总线 (MbitsStandardInterface / MbistBus) ----
//    array     : 本次请求的目标 array 编号 (一棵子树内 SRAM 从 0 起编号)
//    all       : 广播位，置 1 时对子树内**所有** array 同时操作 (不看 array 匹配)
//    req       : 请求有效
//    ack       : 响应 (= reqReg & 子流水 ack)
//    writeen   : 写使能
//    be        : 字节写选通 (byte-enable / write mask)
//    addr      : 写地址 (单口 SRAM 读写共用，双口另给 addr_rd)
//    indata    : 写数据
//    readen    : 读使能
//    addr_rd   : 读地址 (双口 SRAM 用)
//    outdata   : 读数据 (从子树 OR 归约上来)
//
//  ---- MbistPipeline 节点的统一行为 (utility/mbist/MbistPipeline.scala) ----
//    一个节点有若干 child，每个 child 是"下游流水节点"或"SRAM 节点"，并各自
//    认领一组 array 编号 (array_id)。节点把上游请求打一拍寄存，再按 arrayReg
//    匹配把请求**铺开** (spread) 给被选中的 child：
//
//      arrayHit  = (mbist.array ∈ 本节点所有 array_id)
//      activated = mbist.all | (mbist.req & arrayHit)        // 是否吃下本请求
//      dataValid = activated & (readen | writeen)            // 是否锁存数据/地址
//
//      arrayReg  = RegEnable(array,   activated)             // 寄存目标 array
//      allReg    = RegEnable(all,     activated)
//      wenReg    = RegEnable(writeen, activated)
//      renReg    = RegEnable(readen,  activated)
//      reqReg    = RegNext(req)                              // req 每拍都寄存
//      beReg/addrReg/dataInReg/addrRdReg = RegEnable(..., dataValid)
//
//      // 每个 child：
//      selected = (arrayReg ∈ child.array_id)
//      doSpread = selected | allReg                          // 广播或命中才下发
//      该 child 的 addr/addr_rd/re/we/all/... 仅在 doSpread 时透传，否则清零
//      selectedOH = Fill(allReg) | (reqReg ? selectedVec : 全 1)   // 选中 one-hot
//      读数据回程 = selected ? child.rdata : 0，再在节点处 OR 归约
//
//    对 extraHold=true 的 SRAM child，读/写使能改用 2 位"展宽寄存器"的低位：
//      activated&sig 时置 2'b11，否则每拍右移 (>>1)，使 re/we 维持 2 拍。
//
//  本包仅放公共常量；各变体的端口位宽/array 编号差异在各自模块内显式写出，
//  共用的"输入寄存器+控制门控"逻辑封装在 xs_mbist_pipe_ctrl。
// =============================================================================
package mbist_pipe_pkg;
  // MBIST array 广播判定中用到的"未选中即清零"约定无需额外常量；
  // 这里仅声明展宽寄存器宽度，供 extraHold SRAM 使用。
  localparam int MBIST_HOLD_W = 2;  // 读/写使能展宽寄存器位宽 (维持 2 拍)
endpackage
