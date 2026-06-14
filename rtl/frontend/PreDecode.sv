// =============================================================================
// xs_PreDecode_core —— 取指包预解码（纯组合）
//
// 对应 Chisel: xiangshan.frontend.PreDecode（KunminghuV2Config：PredictWidth=16,
// XLEN=64, HasCExtension=true）
//
// 对一个取指包（PredictWidth+1=17 个 16-bit 半字）逐字节地址做预解码：
//   - 取每个半字位置的 32-bit 指令 inst[i] = {data[i+1], data[i]}
//   - 判 RVC（inst[1:0]!=2'b11）、分支类型（br/jal/jalr/notCFI）、isCall/isRet
//   - 算 jal/branch 的符号扩展跳转偏移
//   - 用两段式 RVC/RVI 边界检测得到每个位置是否为「有效指令起点」(valid) 及
//     half-valid（用于跨包 last-half 匹配）
//
// 两段式边界：前半 [0,8) 直接链式推导；后半 [8,16) 同时算两种假设——half（假设 8
// 是有效起点）与 halfPlus1（假设 8 是上一条 RVI 的后半、9 才是起点），最后按前半
// 是否在 7 处干净结束(validEnd[7]) 选择。如此在中点打断长依赖链，改善时序。
// =============================================================================
module xs_PreDecode_core #(
  parameter int unsigned PW   = 16,   // PredictWidth
  parameter int unsigned XLEN = 64
)(
  // 取指数据：PW+1 个半字
  input  logic [PW:0][15:0]        io_data,
  // 逐位置输出
  output logic [PW-1:0]            pd_valid,
  output logic [PW-1:0]            pd_isRVC,
  output logic [PW-1:0][1:0]       pd_brType,
  output logic [PW-1:0]            pd_isCall,
  output logic [PW-1:0]            pd_isRet,
  output logic [PW-1:0]            hasHalfValid,
  output logic [PW-1:0][31:0]      instr,
  output logic [PW-1:0][XLEN-1:0]  jumpOffset
);
  localparam int unsigned HALF = PW / 2;

  // BrType 编码（与 Chisel object BrType 一致）
  localparam logic [1:0] BR_NOTCFI = 2'b00, BR_BRANCH = 2'b01,
                         BR_JAL = 2'b10, BR_JALR = 2'b11;

  function automatic logic is_link(input logic [4:0] r);
    return (r == 5'd1) || (r == 5'd5);
  endfunction

  // jal 偏移：RVC(C.J) / RVI(JAL) 立即数，符号扩展到 XLEN（显式符号位复制）
  function automatic logic [XLEN-1:0] jal_offset(input logic [31:0] inst, input logic rvc);
    logic [11:0] rvc_off;  // C.J: 12 bit
    logic [20:0] rvi_off;  // JAL: 21 bit
    logic [20:0] sel;
    rvc_off = {inst[12], inst[8], inst[10:9], inst[6], inst[7], inst[2], inst[11], inst[5:3], 1'b0};
    rvi_off = {inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
    sel = rvc ? {{9{rvc_off[11]}}, rvc_off} : rvi_off;
    return {{(XLEN-21){sel[20]}}, sel};
  endfunction

  // branch 偏移
  function automatic logic [XLEN-1:0] br_offset(input logic [31:0] inst, input logic rvc);
    logic [8:0]  rvc_off;  // C.B: 9 bit
    logic [12:0] rvi_off;  // B: 13 bit
    logic [12:0] sel;
    rvc_off = {inst[12], inst[6:5], inst[2], inst[11:10], inst[4:3], 1'b0};
    rvi_off = {inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
    sel = rvc ? {{4{rvc_off[8]}}, rvc_off} : rvi_off;
    return {{(XLEN-13){sel[12]}}, sel};
  endfunction

  // 分支类型译码（优先级：C.EBREAK→notCFI 高于 C.JALR；其余互斥）
  function automatic logic [1:0] br_type(input logic [31:0] inst);
    logic c_ebreak, c_j, c_jalr, c_branch, i_jal, i_jalr, i_branch;
    c_ebreak = (inst[15:13] == 3'b100) && (inst[11:2] == 10'b0) && (inst[1:0] == 2'b10);
    c_j      = (inst[15:13] == 3'b101) && (inst[1:0] == 2'b01);
    c_jalr   = (inst[15:13] == 3'b100) && (inst[6:2] == 5'b0) && (inst[1:0] == 2'b10);
    c_branch = (inst[15:14] == 2'b11) && (inst[1:0] == 2'b01);
    i_jal    = (inst[6:0] == 7'b1101111);
    i_jalr   = (inst[14:12] == 3'b000) && (inst[6:0] == 7'b1100111);
    i_branch = (inst[6:0] == 7'b1100011);
    if (c_ebreak)            return BR_NOTCFI;
    else if (c_j || i_jal)   return BR_JAL;
    else if (c_jalr || i_jalr) return BR_JALR;
    else if (c_branch || i_branch) return BR_BRANCH;
    else                     return BR_NOTCFI;
  endfunction

  // ---- 逐位置：指令、RVC、类型、call/ret、偏移 ----
  logic [PW-1:0]      isRVCv;
  logic [PW-1:0][1:0] brTypev;
  logic [PW-1:0]      isCallv, isRetv;

  for (genvar i = 0; i < PW; i++) begin : g_dec
    wire [31:0] inst = {io_data[i+1], io_data[i]};
    wire        rvc  = (inst[1:0] != 2'b11);
    wire [1:0]  bt   = br_type(inst);
    wire [4:0]  rd   = rvc ? {4'b0, inst[12]} : inst[11:7];
    wire [4:0]  rs   = rvc ? (bt == BR_JAL ? 5'b0 : inst[11:7]) : inst[19:15];
    wire        call = ((bt == BR_JAL && !rvc) || bt == BR_JALR) && is_link(rd);
    wire        ret  = (bt == BR_JALR) && is_link(rs) && !call;

    assign isRVCv[i]   = rvc;
    assign brTypev[i]  = bt;
    assign isCallv[i]  = call;
    assign isRetv[i]   = ret;
    assign instr[i]    = inst;
    assign jumpOffset[i] = (bt == BR_BRANCH) ? br_offset(inst, rvc) : jal_offset(inst, rvc);

    assign pd_isRVC[i]  = rvc;
    assign pd_brType[i] = bt;
    assign pd_isCall[i] = call;
    assign pd_isRet[i]  = ret;
  end

  // ---- 两段式有效起点/结束边界检测 ----
  // 各链用运行标量推进（避免 always_comb 内读写同一数组），分块计算，块间互不读写。
  logic [PW-1:0] vStart, vEnd, hStart, hEnd;
  logic [HALF-1:0] vS_lo, vE_lo, hS_lo, hE_lo;       // 前半 [0,HALF)
  logic [PW-1:0] vS_half, vE_half, hS_half, hE_half; // 后半假设 half
  logic [PW-1:0] vS_hp1,  vE_hp1,  hS_hp1,  hE_hp1;  // 后半假设 halfPlus1

  // 前半链式 [0,HALF)
  always_comb begin
    logic vpe, hpe, vs, hs;
    vpe = 1'b1; hpe = 1'b0;  // i==0: v 起点恒 1；h 起点 0
    for (int i = 0; i < HALF; i++) begin
      vs = (i == 0) ? 1'b1 : vpe;
      vS_lo[i] = vs;  vE_lo[i] = (vs & isRVCv[i]) | ~vs;  vpe = vE_lo[i];
      hs = (i == 0) ? 1'b0 : hpe;
      hS_lo[i] = hs;  hE_lo[i] = (hs & isRVCv[i]) | ~hs;  hpe = hE_lo[i];
    end
  end

  // 后半假设 half：HALF 是有效起点
  always_comb begin
    logic vpe, hpe, vs, hs;
    vS_half = '0; vE_half = '0; hS_half = '0; hE_half = '0;
    vpe = 1'b0; hpe = 1'b0;
    for (int i = HALF; i < PW; i++) begin
      vs = (i == HALF) ? 1'b1 : vpe;
      vS_half[i] = vs; vE_half[i] = (vs & isRVCv[i]) | ~vs; vpe = vE_half[i];
      hs = (i == HALF) ? 1'b1 : hpe;
      hS_half[i] = hs; hE_half[i] = (hs & isRVCv[i]) | ~hs; hpe = hE_half[i];
    end
  end

  // 后半假设 halfPlus1：HALF 是上条 RVI 后半，HALF+1 才是起点
  always_comb begin
    logic vpe, hpe, vs, hs;
    vS_hp1 = '0; vE_hp1 = '0; hS_hp1 = '0; hE_hp1 = '0;
    vS_hp1[HALF] = 1'b0; vE_hp1[HALF] = 1'b1;
    hS_hp1[HALF] = 1'b0; hE_hp1[HALF] = 1'b1;
    vpe = 1'b1; hpe = 1'b1;  // i==HALF+1 起点恒 1
    for (int i = HALF + 1; i < PW; i++) begin
      vs = (i == HALF + 1) ? 1'b1 : vpe;
      vS_hp1[i] = vs; vE_hp1[i] = (vs & isRVCv[i]) | ~vs; vpe = vE_hp1[i];
      hs = (i == HALF + 1) ? 1'b1 : hpe;
      hS_hp1[i] = hs; hE_hp1[i] = (hs & isRVCv[i]) | ~hs; hpe = hE_hp1[i];
    end
  end

  // 合并：前半直接用；后半按 validEnd[HALF-1]/h_validEnd[HALF-1] 选假设
  always_comb begin
    for (int i = 0; i < HALF; i++) begin
      vStart[i] = vS_lo[i]; vEnd[i] = vE_lo[i];
      hStart[i] = hS_lo[i]; hEnd[i] = hE_lo[i];
    end
    for (int i = HALF; i < PW; i++) begin
      vStart[i] = vE_lo[HALF-1] ? vS_half[i] : vS_hp1[i];
      vEnd[i]   = vE_lo[HALF-1] ? vE_half[i] : vE_hp1[i];
      hStart[i] = hE_lo[HALF-1] ? hS_half[i] : hS_hp1[i];
      hEnd[i]   = hE_lo[HALF-1] ? hE_half[i] : hE_hp1[i];
    end
  end

  assign pd_valid     = vStart;
  assign hasHalfValid = hStart;

endmodule
