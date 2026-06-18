// =============================================================================
// wbdatapath_pkg —— 香山 V2R2(昆明湖) 写回数据通路(WbDataPath) 类型/参数定义
// -----------------------------------------------------------------------------
// 对应 Scala 源 `xiangshan.backend.datapath.WbArbiter.scala`(class WbDataPath)。
//
// 【WbDataPath 在后端的位置】
//   它是"执行 → 写回"的总枢纽: 收集所有执行单元(EXU)算出的结果(ExuOutput), 按各结果
//   要写的物理寄存器域(int/fp/vec/v0/vl)分流, 经各域的写回仲裁器(RealWBCollideChecker)
//   抢占有限的物理寄存器写回端口, 最终把胜出者写回物理寄存器堆(toXxxPreg), 同时把所有
//   完成的写回汇报给控制块 ROB(toCtrlBlock.writeback)用于按序提交。
//
// 【五个写回域】每个 EXU 结果可能要写若干物理寄存器域, 由其 wen 位指示:
//   int : 整数寄存器   (rfWen / intWen)
//   fp  : 浮点寄存器   (fpWen)
//   vec : 向量数据寄存器(vecWen)
//   v0  : 向量 v0 寄存器(v0Wen, 掩码寄存器)
//   vl  : 向量长度寄存器(vlWen)
//
// 【accept-cond(写使能分流)】对应 Scala acceptCond / intArbiterInputsWire 等:
//   每个 EXU 的结果在 valid 时, 按它的 5 个 wen 位"扇出"到对应域的仲裁输入:
//     <dom>Write = exu.valid & exu.bits.<dom>Wen
//   一个结果可同时写多个域(如向量指令同写 vec+vl)。Scala 断言"一个 EXU 至多命中一个
//   域类别"仅对 acceptVec 的互斥性而言; 此处 5 个 wen 独立, 分别进各自仲裁器。
//
// 【fire 语义】
//   * 不定延迟 EXU(hasUncertainLatency): 其 ready = 命中域仲裁器 ready(可背压, 结果可
//     在 EXU 口停留重试)。toCtrlBlock 该路 valid = exu.valid & ready (= fire)。
//   * 确定延迟 EXU: ready 恒 1(结果不可丢, 否则数据永久丢失, 故 golden 带 assert);
//     toCtrlBlock valid = exu.valid。
//
// 【VfExe 写 Int 的打拍特例】对应 Scala:
//   `if (writeIntRf && isVfExeUnit) { intWrite := RegNext(...); bits := RegEnable(...) }`
//   向量执行单元若要写整数寄存器, 结果晚一拍进入 int 仲裁器(跨域写回的时序对齐)。
//   本配置仅 VfExu_0_1(=intArbiterInputsWire_14)命中此特例。
// =============================================================================
package wbdatapath_pkg;

  localparam int unsigned ROB_IDX_W   = 8;   // robIdx.value 位宽
  localparam int unsigned PDEST_W     = 8;   // 物理寄存器号位宽(整数域最大)
  localparam int unsigned DATA_W      = 64;  // 标量数据位宽
  localparam int unsigned VDATA_W     = 128; // 向量数据位宽(两个 64 拼)
  localparam int unsigned PERF_TIME_W = 64;  // perfDebugInfo 各时间戳位宽

  // 五个写回域 —— 一个 EXU 结果按 wen 位扇出到这些域各自的写回仲裁器。
  // 对应 Scala 的 PregWB 子类(IntWB/FpWB/VfWB/V0WB/VlWB)。
  typedef enum logic [2:0] {
    WB_INT = 3'd0,  // 整数物理寄存器
    WB_FP  = 3'd1,  // 浮点物理寄存器
    WB_VEC = 3'd2,  // 向量数据物理寄存器
    WB_V0  = 3'd3,  // 向量 v0(掩码)物理寄存器
    WB_VL  = 3'd4   // 向量长度物理寄存器
  } wb_dom_e;

  // 一个写回仲裁器出口 → 物理寄存器写口的有效载荷(标量域: 64 位数据, 8 位地址)。
  // 对应 Scala WriteBackBundle 的 {valid, wen, pdest, data} 字段聚合。各域位宽不同,
  // 此处用最宽(int)定义统一 struct, 窄域(如 v0 的 5 位 pdest)在核里按本域宽截取。
  typedef struct packed {
    logic                  valid;  // 仲裁出口胜出
    logic                  wen;    // 该出口结果确实要写本域(rfWen/fpWen/...)
    logic [PDEST_W-1:0]    pdest;  // 目的物理寄存器号
    logic [VDATA_W-1:0]    data;   // 写回数据(标量域只用低 64 位)
  } wb_payload_t;

  // 一个 EXU 结果到某写回域仲裁器的"接受判定": valid 且该域 wen 置位。
  // 对应 Scala `<dom>Write := exuOut.valid && acceptCond._1(<dom>)`。
  function automatic logic accept(input logic exu_valid, input logic dom_wen);
    return exu_valid & dom_wen;
  endfunction

  // 物理寄存器写口的实际写使能: 仲裁器该出口胜出(valid)且其结果确实要写该域。
  // 对应 Scala `asXxxRfWriteBundle(fire)` 里 wen = bits.<wen> & out.fire (fire=valid,
  // 因为这些仲裁出口 ready 恒 1)。
  function automatic logic preg_wen(input logic arb_out_valid, input logic arb_out_wen);
    return arb_out_valid & arb_out_wen;
  endfunction

endpackage : wbdatapath_pkg
