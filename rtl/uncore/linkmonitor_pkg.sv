// =============================================================================
//  linkmonitor_pkg —— LinkMonitor (CHI 链路层监视器) 常量与类型
// -----------------------------------------------------------------------------
//  对应 OpenLLC 的 LinkMonitor (chi/LinkLayer.scala): CHI 链路层的「激活/去激活
//  握手 + L-Credit 流控」管理层。它把上层 Decoupled(ready/valid) 接口与下层
//  CHI 物理链路的 flit + L-Credit 协议互转 (互转由 6 个子模块黑盒完成), 自身负责:
//
//    1. LINKACTIVE 状态机 (txState / rxState): 由对端 {linkactivereq, linkactiveack}
//       两根握手线译码出 4 态 STOP→ACTIVATE→RUN→DEACTIVATE→STOP, 下发给各
//       flit 转换子模块 (子模块据此决定能否发/收 flit 及何时回收 L-Credit)。
//    2. L-Credit 回收 (reclaim): 去激活时必须等三个 RX 子模块把欠对端的 L-Credit
//       全部归还 (reclaimLCredit 全 1), 才允许撤下 rx.linkactiveack。
//    3. 系统一致性握手 (syscoreq / syscoack) 与 txsactive 指示。
//    4. 性能计数器 (RetryAck / PCrdGrant / no-allowRetry 请求计数, 仅监测无输出)。
//    5. 给上行 flit 注入本节点 srcID (= nodeID)。
//
//  L-Credit 协议要点 (子模块内部, 本层只摆链路态): 发送方每收到对端一个
//  lcrdv 脉冲即获得 1 个信用, 有信用才可拉 flitv 发一个 flit; 链路去激活流程要求
//  把未用信用如数 "归还" (发 NULL flit / 撤信用), 即此处的 reclaim 条件。
// =============================================================================
package linkmonitor_pkg;

  // ---------------------------------------------------------------------------
  //  LINKACTIVE 链路态 (CHI-B 链路层 4 态)。编码同 OpenLLC LinkStates。
  // ---------------------------------------------------------------------------
  typedef enum logic [1:0] {
    STOP       = 2'd0,  // 链路停止 (req=0, ack=0)
    ACTIVATE   = 2'd1,  // 激活中   (req=1, ack=0): 已请求, 待对端确认
    RUN        = 2'd2,  // 运行     (req=1, ack=1): 可正常收发 flit
    DEACTIVATE = 2'd3   // 去激活中 (req=0, ack=1): 已撤请求, 待对端撤确认
  } link_state_e;

  // 链路方向 (TX=发送侧 / RX=接收侧), 用于把两个对称的状态机折叠成数组循环。
  typedef enum int unsigned {
    DIR_TX = 0,
    DIR_RX = 1
  } link_dir_e;

  // ---------------------------------------------------------------------------
  //  LINKACTIVE 状态译码: 由对端的 {linkactivereq, linkactiveack} 直接映射链路态。
  //  (OpenLLC: MuxLookup(Cat(req, ack)) → ACTIVATE/RUN/DEACTIVATE/STOP)
  //    {1,0}=ACTIVATE  {1,1}=RUN  {0,1}=DEACTIVATE  {0,0}=STOP
  // ---------------------------------------------------------------------------
  function automatic link_state_e link_state(input logic req, input logic ack);
    unique case ({req, ack})
      2'b10:   link_state = ACTIVATE;
      2'b11:   link_state = RUN;
      2'b01:   link_state = DEACTIVATE;
      default: link_state = STOP;     // 2'b00
    endcase
  endfunction

  // ---------------------------------------------------------------------------
  //  RX RSP 通道关注的 CHI 响应 opcode (供性能计数器识别)。
  // ---------------------------------------------------------------------------
  localparam logic [4:0] RSP_OP_RETRYACK  = 5'h3;  // RetryAck: 目标忙, 需重试
  localparam logic [4:0] RSP_OP_PCRDGRANT = 5'h7;  // PCrdGrant: 协议层信用授予

endpackage
