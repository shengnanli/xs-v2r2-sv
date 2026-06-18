// =============================================================================
// xs_WbDataPath_core —— 写回数据通路(可读核)
// -----------------------------------------------------------------------------
// 对应 Scala `class WbDataPath`(WbArbiter.scala)。详见 docs/backend/WbDataPath.md。
//
// 【本核 vs wrapper 的分工】
//   WbDataPath 顶层是一张巨大的"执行结果 → 写回端口"互联网, 内部例化:
//     · VldMergeUnit ×2          向量 load 结果按 vl 合并(黑盒)
//     · RealWBCollideChecker ×5  五个写回域(int/fp/vec/v0/vl)各一个写回仲裁器(黑盒)
//     · DummyDPICWrapper ×26      difftest 探针(纯 sink, 不驱动任何输出, 黑盒)
//   这些黑盒的例化与互联是机械接线, 放在结构性 wrapper(WbDataPath_wrapper.sv, 由
//   scripts/gen_wbdatapath.py 生成)。本可读核只承载**真正的微架构逻辑**:
//     1) accept-cond: 把每个 EXU 结果按 5 个 wen 位分流成各域仲裁器的输入 valid;
//     2) RegEnable 特例: 向量单元写整数寄存器需打一拍;
//     3) fire/ready: 不定延迟 EXU 的 ready 由命中仲裁器回授;
//     4) 输出格式化: 仲裁器胜出者 → 物理寄存器写口(toPreg); EXU 结果 → ROB(toCtrlBlock)。
//
// 本核按"写回域"+"流水方向"分节。仲裁器本体(优先级选择)在黑盒里, 本核给它喂输入、
// 收它的输出做格式化。
// =============================================================================
module xs_WbDataPath_core
  import wbdatapath_pkg::*;
#(
    parameter int unsigned N_INT_OUT = 8,   // int 写回仲裁器出口数 = int 物理寄存器写口数
    parameter int unsigned N_FP_OUT  = 6,
    parameter int unsigned N_VF_OUT  = 6,
    parameter int unsigned N_V0_OUT  = 6,
    parameter int unsigned N_VL_OUT  = 4,
    // 各域物理寄存器号位宽不同(整数/浮点 8 位, 向量数据 7 位, 向量 v0 仅 5 位)。
    parameter int unsigned INT_PD_W  = 8,
    parameter int unsigned FP_PD_W   = 8,
    parameter int unsigned VF_PD_W   = 7,
    parameter int unsigned V0_PD_W   = 5
) (
    input  logic clock,

    // =====================================================================
    // (1) accept-cond: EXU 结果 → 各域仲裁器输入的写使能分流
    //     每个 EXU 一组 {valid, intWen, fpWen, vecWen, v0Wen, vlWen}, 本核算出
    //     该 EXU 对各域的 <dom>Write = valid & <dom>Wen 供 wrapper 接到仲裁器 in.valid。
    //     这里给出"通用单 EXU 分流"函数化接口: wrapper 对每个 EXU 各调一次。
    // =====================================================================
    // 单 EXU 分流端口(wrapper 对每个有写回的 EXU 实例化一份组合, 见下方 accept 用法)。
    // 为保持核可读且与黑盒解耦, 分流逻辑以 accept() 纯函数表达(见 pkg)。

    // =====================================================================
    // (2) VfExe 写 Int 的打拍特例(本配置唯一一例: VfExu_0_1)
    //     向量执行单元写整数寄存器, 结果晚一拍进入 int 仲裁器。
    // =====================================================================
    input  logic                  vfe2int_in_valid,   // VfExu_0_1.valid
    input  logic                  vfe2int_in_intWen,  // VfExu_0_1.bits.intWen
    input  logic [INT_PD_W-1:0]   vfe2int_in_pdest,
    input  logic [DATA_W-1:0]     vfe2int_in_data,    // bits.data_1[63:0]
    output logic                  vfe2int_reg_write,  // RegNext(valid & intWen) → 仲裁 in.valid
    output logic                  vfe2int_reg_intWen, // RegEnable(intWen)
    output logic [INT_PD_W-1:0]   vfe2int_reg_pdest,
    output logic [DATA_W-1:0]     vfe2int_reg_data,

    // =====================================================================
    // (3) 输出格式化: int 域仲裁器出口 → 整数物理寄存器写口
    //     wen = arb.valid & arb.rfWen; addr/data/intWen 直传。genvar 展开 N_INT_OUT 路。
    // =====================================================================
    input  logic [N_INT_OUT-1:0]               int_arb_valid,
    input  logic [N_INT_OUT-1:0]               int_arb_rfWen,
    input  logic [N_INT_OUT-1:0][INT_PD_W-1:0] int_arb_pdest,
    input  logic [N_INT_OUT-1:0][DATA_W-1:0]   int_arb_data,
    output logic [N_INT_OUT-1:0]               int_preg_wen,
    output logic [N_INT_OUT-1:0]               int_preg_intWen,
    output logic [N_INT_OUT-1:0][INT_PD_W-1:0] int_preg_addr,
    output logic [N_INT_OUT-1:0][DATA_W-1:0]   int_preg_data,

    // fp 域
    input  logic [N_FP_OUT-1:0]                fp_arb_valid,
    input  logic [N_FP_OUT-1:0]                fp_arb_fpWen,
    input  logic [N_FP_OUT-1:0][FP_PD_W-1:0]   fp_arb_pdest,
    input  logic [N_FP_OUT-1:0][DATA_W-1:0]    fp_arb_data,
    output logic [N_FP_OUT-1:0]                fp_preg_wen,
    output logic [N_FP_OUT-1:0]                fp_preg_fpWen,
    output logic [N_FP_OUT-1:0][FP_PD_W-1:0]   fp_preg_addr,
    output logic [N_FP_OUT-1:0][DATA_W-1:0]    fp_preg_data,

    // vec 域(数据 128 位, pdest 7 位)
    input  logic [N_VF_OUT-1:0]                vf_arb_valid,
    input  logic [N_VF_OUT-1:0]                vf_arb_vecWen,
    input  logic [N_VF_OUT-1:0][VF_PD_W-1:0]   vf_arb_pdest,
    input  logic [N_VF_OUT-1:0][VDATA_W-1:0]   vf_arb_data,
    output logic [N_VF_OUT-1:0]                vf_preg_wen,
    output logic [N_VF_OUT-1:0]                vf_preg_vecWen,
    output logic [N_VF_OUT-1:0][VF_PD_W-1:0]   vf_preg_addr,
    output logic [N_VF_OUT-1:0][VDATA_W-1:0]   vf_preg_data,

    // v0 域(数据 128 位, pdest 5 位)
    input  logic [N_V0_OUT-1:0]                v0_arb_valid,
    input  logic [N_V0_OUT-1:0]                v0_arb_v0Wen,
    input  logic [N_V0_OUT-1:0][V0_PD_W-1:0]   v0_arb_pdest,
    input  logic [N_V0_OUT-1:0][VDATA_W-1:0]   v0_arb_data,
    output logic [N_V0_OUT-1:0]                v0_preg_wen,
    output logic [N_V0_OUT-1:0]                v0_preg_v0Wen,
    output logic [N_V0_OUT-1:0][V0_PD_W-1:0]   v0_preg_addr,
    output logic [N_V0_OUT-1:0][VDATA_W-1:0]   v0_preg_data,

    // vl 域(只有 wen/vlWen, 无 pdest/data —— vl 寄存器极小, golden 不导出 addr/data)
    input  logic [N_VL_OUT-1:0]                vl_arb_valid,
    input  logic [N_VL_OUT-1:0]                vl_arb_vlWen,
    output logic [N_VL_OUT-1:0]                vl_preg_wen,
    output logic [N_VL_OUT-1:0]                vl_preg_vlWen
);

  // ===========================================================================
  // (2) VfExe→Int 打拍: RegNext(valid & intWen) + RegEnable(bits, valid)
  // ===========================================================================
  always_ff @(posedge clock) begin
    vfe2int_reg_write <= accept(vfe2int_in_valid, vfe2int_in_intWen);
    if (vfe2int_in_valid) begin
      vfe2int_reg_intWen <= vfe2int_in_intWen;
      vfe2int_reg_pdest  <= vfe2int_in_pdest;
      vfe2int_reg_data   <= vfe2int_in_data;
    end
  end

  // ===========================================================================
  // (3) 输出格式化: 各域仲裁器出口 → 物理寄存器写口
  //     先把每个仲裁出口的 {valid,wen,pdest,data} 聚合成 wb_payload_t(对应 Scala
  //     WriteBackBundle), 再统一格式化: 写口 wen = preg_wen(valid, wen); 地址/数据直传。
  //     五个写回域(wb_dom_e: WB_INT/FP/VEC/V0/VL)结构同构, 各用 genvar 展开本域出口数。
  // ===========================================================================
  // 各域把扁平的 arb_* 输入聚合成结构化 payload 数组(窄域 pdest/data 零扩展进统一 struct)。
  wb_payload_t int_wb [N_INT_OUT];
  wb_payload_t fp_wb  [N_FP_OUT];
  wb_payload_t vf_wb  [N_VF_OUT];
  wb_payload_t v0_wb  [N_V0_OUT];
  wb_payload_t vl_wb  [N_VL_OUT];

  genvar i;
  generate
    // ---- WB_INT ----
    for (i = 0; i < N_INT_OUT; i++) begin : g_int_preg
      assign int_wb[i] = '{valid: int_arb_valid[i], wen: int_arb_rfWen[i],
                           pdest: {{(PDEST_W-INT_PD_W){1'b0}}, int_arb_pdest[i]},
                           data:  {{(VDATA_W-DATA_W){1'b0}}, int_arb_data[i]}};
      assign int_preg_wen[i]    = preg_wen(int_wb[i].valid, int_wb[i].wen);
      assign int_preg_intWen[i] = int_wb[i].wen;
      assign int_preg_addr[i]   = int_wb[i].pdest[INT_PD_W-1:0];
      assign int_preg_data[i]   = int_wb[i].data[DATA_W-1:0];
    end
    // ---- WB_FP ----
    for (i = 0; i < N_FP_OUT; i++) begin : g_fp_preg
      assign fp_wb[i] = '{valid: fp_arb_valid[i], wen: fp_arb_fpWen[i],
                          pdest: {{(PDEST_W-FP_PD_W){1'b0}}, fp_arb_pdest[i]},
                          data:  {{(VDATA_W-DATA_W){1'b0}}, fp_arb_data[i]}};
      assign fp_preg_wen[i]    = preg_wen(fp_wb[i].valid, fp_wb[i].wen);
      assign fp_preg_fpWen[i]  = fp_wb[i].wen;
      assign fp_preg_addr[i]   = fp_wb[i].pdest[FP_PD_W-1:0];
      assign fp_preg_data[i]   = fp_wb[i].data[DATA_W-1:0];
    end
    // ---- WB_VEC(数据 128 位) ----
    for (i = 0; i < N_VF_OUT; i++) begin : g_vf_preg
      assign vf_wb[i] = '{valid: vf_arb_valid[i], wen: vf_arb_vecWen[i],
                          pdest: {{(PDEST_W-VF_PD_W){1'b0}}, vf_arb_pdest[i]},
                          data:  vf_arb_data[i]};
      assign vf_preg_wen[i]    = preg_wen(vf_wb[i].valid, vf_wb[i].wen);
      assign vf_preg_vecWen[i] = vf_wb[i].wen;
      assign vf_preg_addr[i]   = vf_wb[i].pdest[VF_PD_W-1:0];
      assign vf_preg_data[i]   = vf_wb[i].data;
    end
    // ---- WB_V0(数据 128 位, pdest 5 位) ----
    for (i = 0; i < N_V0_OUT; i++) begin : g_v0_preg
      assign v0_wb[i] = '{valid: v0_arb_valid[i], wen: v0_arb_v0Wen[i],
                          pdest: {{(PDEST_W-V0_PD_W){1'b0}}, v0_arb_pdest[i]},
                          data:  v0_arb_data[i]};
      assign v0_preg_wen[i]    = preg_wen(v0_wb[i].valid, v0_wb[i].wen);
      assign v0_preg_v0Wen[i]  = v0_wb[i].wen;
      assign v0_preg_addr[i]   = v0_wb[i].pdest[V0_PD_W-1:0];
      assign v0_preg_data[i]   = v0_wb[i].data;
    end
    // ---- WB_VL(只有 wen/vlWen; vl 寄存器极小, golden 不导出 addr/data) ----
    for (i = 0; i < N_VL_OUT; i++) begin : g_vl_preg
      assign vl_wb[i] = '{valid: vl_arb_valid[i], wen: vl_arb_vlWen[i],
                          pdest: '0, data: '0};
      assign vl_preg_wen[i]   = preg_wen(vl_wb[i].valid, vl_wb[i].wen);
      assign vl_preg_vlWen[i] = vl_wb[i].wen;
    end
  endgenerate

endmodule
