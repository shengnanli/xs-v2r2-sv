// VSetRiWi —— 由 scripts/port_increment_migrate.py 迁移自上轮可读核
//
// 迁移依据（脚本已校验）：G0 与 G1 的 golden 去掉端口表后**逐字相同**，
// 即 G1 的改动只是接口增量（perfDebugInfo / debug.seqNum / ready 等透传字段），
// 运算逻辑未动。故核体沿用，wrapper 按 G1 端口重做，直通 assign 由 golden
// 文本机械提取（不手打）。
//
// vset 写 vtype/vl，本变体为 rs1-immediate(RiWi) 形态。


// =============================================================================
// vset_pkg —— 香山 V2R2(昆明湖)向量配置单元 VSet 的共享类型与计算函数包
// -----------------------------------------------------------------------------
// 设计源:
//   - src/main/scala/xiangshan/backend/fu/Vsetu.scala        (class VsetModule, vl/vtype 计算核)
//   - src/main/scala/xiangshan/backend/fu/wrapper/VSet.scala (VSetRiWi / VSetRvfWvf, AVL/vtype 选源)
//   - src/main/scala/xiangshan/package.scala                 (object VSETOpType, 运算码编码)
//   - src/main/scala/xiangshan/backend/fu/vector/Bundles.scala (VsetVType / VType / VConfig)
//
// 本包被 VSetRiWi 与 VSetRvfWvf 两个可读核共用,聚合三件事:
//   1) vset 运算码 fuOpType 的「位含义」枚举与解码函数(哪种 vset 变体);
//   2) vtype / vconfig 的结构(struct packed),替代 golden 展平的逐字段端口;
//   3) vl / vtype 合法性 / vlmax 的纯计算函数(对应 VsetModule 的组合逻辑)。
//
// 关键背景:RVV 的 vset{i}vl{i} 指令配置「向量长度 vl」与「向量类型 vtype」。
//   - vtype 编码 SEW(单元素位宽)、LMUL(寄存器组倍率)、ta/ma(尾/掩码策略);
//   - vl = min(AVL, VLMAX),其中 VLMAX = VLEN * LMUL / SEW;
//   - 若 vtype 非法(保留的 SEW/LMUL、SEW 超出 ELEN*LMUL 等),则 vl=0 且 vtype.vill=1。
// =============================================================================
package vset_pkg;

  // ---------------------------------------------------------------------------
  // 硬件参数(来自 XSCoreParameters,昆明湖默认配置)
  //   VLEN = 128:一个向量寄存器 128 bit;  ELEN = 64:单元素最大 64 bit。
  //   vlWidth = log2(VLEN)+1 = 8:vl/vlmax 端口位宽(最大 VLMAX=VLEN/最小SEW=128/8=16,
  //   留够余量用 8 位)。VsetModule 内部用 15 位中间量算 1<<log2Vlmax,输出截 8 位。
  // ---------------------------------------------------------------------------
  localparam int VLEN      = 128;
  localparam int ELEN      = 64;
  localparam int LOG2_VLEN = 7;   // log2Up(128)
  localparam int LOG2_ELEN = 6;   // log2Up(64)
  localparam int VL_WIDTH  = 8;   // vlWidth
  localparam int VLMAX_W   = 15;  // VsetModule 内部 vlmax 中间量位宽(1<<.. 的载体)

  // ---------------------------------------------------------------------------
  // fuOpType 的位语义(对应 Scala object VSETOpType)
  // fuOpType 共 9 位,关键位:
  //   bit0 setVlmaxBit:rs1==x0 且 rd!=x0,vl 取 VLMAX(vsetvl/vsetvli 的特例)。
  //   bit1 keepVlBit  :rs1==x0 且 rd==x0,保持旧 vl 只改 vtype。
  //   bit5 destTypeBit:0=写 vl 到整型 rd;1=写 vconfig(vtype+vl)。
  //   bit6            :isVsetvl —— vtype 来自整型寄存器 rs2(VtypeStruct),而非立即数。
  //   bit7            :isVsetvli —— vtype/avl 来自指令立即数(vsetvli)。
  //   bit[7:6]==00    :isVsetivli —— avl 也来自立即数(uimm5)。
  // 注意三者互斥:vsetivli(00)/vsetvli(10)/vsetvl(01)。
  // ---------------------------------------------------------------------------
  localparam int SET_VLMAX_BIT = 0;
  localparam int KEEP_VL_BIT   = 1;

  // csrrvl:用本执行单元读取当前 vl(读向量、写整型),保持旧 vl 不做配置。
  localparam logic [8:0] FUOP_CSRRVL = 9'h16;  // "b0001_0110"

  // 判断 vset 变体(对应 VSETOpType.isVsetvl/isVsetvli/isVsetivli/...)。
  function automatic logic is_vsetvl  (input logic [8:0] func); return func[6];          endfunction
  function automatic logic is_vsetvli (input logic [8:0] func); return func[7];          endfunction
  function automatic logic is_vsetivli(input logic [8:0] func); return func[7:6] == 2'b00; endfunction
  function automatic logic is_set_vlmax(input logic [8:0] func); return func[SET_VLMAX_BIT]; endfunction

  // ---------------------------------------------------------------------------
  // vset 三大变体(由 func[7:6] 区分),决定 AVL / vtype 的取源:
  //   VSETIVLI(00):AVL 与 vtype 全来自指令立即数(reserved 仅 2 位)。
  //   VSETVLI (10):vtype 来自立即数(reserved 3 位),AVL 来自整型 rs1。
  //   VSETVL  (01/11):vtype 来自整型 rs2 的 VtypeStruct(含 vill),AVL 来自 rs1。
  // 用 enum 表达这一离散选择,使核内 vtype 选源逻辑读起来即「按变体分派」。
  // ---------------------------------------------------------------------------
  typedef enum logic [1:0] {
    VSET_IVLI = 2'b00,  // vsetivli:立即 AVL + 立即 vtype
    VSET_VLI  = 2'b10,  // vsetvli :寄存器 AVL + 立即 vtype
    VSET_VL   = 2'b01,  // vsetvl  :寄存器 AVL + 寄存器 vtype
    VSET_VL2  = 2'b11   // vsetvl  的另一编码(func[7:6]==11,仍按 vsetvl 处理)
  } vset_kind_e;

  // 由 func[7:6] 得到变体。注意 func[6]=1 一律按 vsetvl 处理(取 VtypeStruct)。
  function automatic vset_kind_e classify(input logic [8:0] func);
    return vset_kind_e'(func[7:6]);
  endfunction

  // ---------------------------------------------------------------------------
  // vtype 结构(对应 VsetVType:从立即数/VtypeStruct 解码后送入 VsetModule 的输入)
  //   reserved 取 55 位:vsetvl 时 = VtypeStruct.reserved(XLEN-9=55);
  //   立即数路径只有 2~3 位有效,高位补 0。
  // 用 struct packed 聚合,替代 golden 的 io_in_vtype_{illegal,reserved,vma,vta,vsew,vlmul}。
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic                  illegal;   // vtypeStruct.vill(仅 vsetvl 路径可能为 1)
    logic [54:0]           reserved;  // 保留位:非 0 即非法
    logic                  vma;       // mask agnostic
    logic                  vta;       // tail agnostic
    logic [2:0]            vsew;      // SEW 编码(3 位输入,合法仅低 2 位)
    logic [2:0]            vlmul;     // LMUL 编码
  } vtype_in_t;

  // vconfig 输出中的 vtype 部分(对应 VType:写回 vtype 寄存器的字段)
  //   vsew 收窄为 2 位(VSew.width=2),非法时整体清零、vill 置位。
  typedef struct packed {
    logic        illegal;  // vill
    logic        vma;
    logic        vta;
    logic [1:0]  vsew;
    logic [2:0]  vlmul;
  } vtype_out_t;

  // ---------------------------------------------------------------------------
  // 核心计算函数(对应 VsetModule 的各组合表达式)
  // 设计意图见 Vsetu.scala:VLMAX = VLEN*LMUL/SEW,取对数后变加减:
  //   log2(VLMAX) = log2(VLEN) + log2(LMUL) - log2(SEW)
  // 其中 EncodedLMUL = log2(LMUL)(直接是 vlmul,补码表示分数 LMUL),
  //      log2(SEW)   = vsew + 3(SEW=8<<vsew ⇒ log2SEW = 3+vsew)。
  // ---------------------------------------------------------------------------

  // log2(SEW):3 位足够(SEW∈{8,16,32,64} ⇒ log2∈{3,4,5,6})。
  function automatic logic [2:0] calc_log2_sew(input logic [2:0] vsew);
    // 只取低 2 位参与(高位是非法判定用),+3。golden:{1'h0,vsew[1:0]} + 3
    return {1'b0, vsew[1:0]} + 3'd3;
  endfunction

  // VLMAX = 1 << (log2Vlen + log2Vlmul - log2Vsew)
  //   vlmul 为 3 位补码(LMUL=2^vlmul,vlmul∈[-3,+3] ⇒ 编码 101..011)。
  //   golden 用 3 位回绕算 (vlmul - 1) - log2Vsew 作为移位量,故内部用 15 位载体左移。
  function automatic logic [VLMAX_W-1:0] calc_vlmax(input logic [2:0] vlmul,
                                                    input logic [2:0] log2_sew);
    logic [2:0] sh;  // 移位量,3 位(与 golden 等价的回绕宽度)
    sh = (vlmul - 3'd1) - log2_sew;   // = log2Vlen(7) + vlmul - log2Vsew, 见下注
    // 说明:log2Vlen=7,而 (vlmul-1) 在 3 位下 = vlmul + 7(mod 8),
    //       故 (vlmul-1)-log2Vsew ≡ 7+vlmul-log2Vsew (mod 8),与 golden 完全一致。
    return {{(VLMAX_W-1){1'b0}}, 1'b1} << sh;
  endfunction

  // VLEN/SEW(最少元素数):用于 vlmax 输出取下界,= 1 << (7 - log2Vsew)
  function automatic logic [VLMAX_W-1:0] calc_vlen_div_sew(input logic [2:0] log2_sew);
    logic [2:0] sh;
    sh = 3'd7 - log2_sew;
    return {{(VLMAX_W-1){1'b0}}, 1'b1} << sh;
  endfunction

  // vtype 合法性判定(对应 VsetModule.illegal)
  //   lmulIllegal :vlmul == 100(VLmul 保留编码)
  //   sewIllegal  :vsew[2]==1(SEW 保留) 或 log2Vsew > log2VsewMax(SEW 超 ELEN*LMUL 上界)
  //                log2VsewMax = vlmul[2]? (log2Elen + vlmul) : log2Elen
  //                            = vlmul[2]? (vlmul - 2)        : 6   (3 位回绕,见 golden)
  //   reserved 非 0 或 输入 vill ⇒ 非法
  function automatic logic calc_illegal(input logic [2:0]  vlmul,
                                        input logic [2:0]  vsew,
                                        input logic [2:0]  log2_sew,
                                        input logic [54:0] reserved,
                                        input logic        in_illegal);
    logic [2:0] log2_sew_max;
    logic       lmul_illegal, sew_illegal;
    log2_sew_max = vlmul[2] ? (vlmul - 3'd2) : 3'd6;  // golden: vlmul[2]? vlmul-2 : 6
    lmul_illegal = (vlmul == 3'b100);
    sew_illegal  = vsew[2] | (log2_sew > log2_sew_max);
    return lmul_illegal | sew_illegal | (|reserved) | in_illegal;
  endfunction

  // 最终 vl(对应 VsetModule.io_out_vconfig_vl)
  //   非法 ⇒ 0;
  //   否则:setVlmax 路径(func 非 vsetivli 且 bit0=1)或 avl>vlmax ⇒ 取 vlmax,否则取 avl。
  //   golden 表达式:illegal?0 : ((|func[7:6])&func[0] | avl>vlmax) ? vlmax : avl
  //   其中 (|func[7:6]) = !isVsetivli,&func[0] = setVlmax。
  function automatic logic [VL_WIDTH-1:0] calc_vl(input logic                  illegal,
                                                  input logic [8:0]            func,
                                                  input logic [63:0]           avl,
                                                  input logic [VLMAX_W-1:0]    vlmax);
    logic take_vlmax;
    take_vlmax = ((|func[7:6]) & func[0]) | (avl > {{(64-VLMAX_W){1'b0}}, vlmax});
    if (illegal)         return '0;
    else if (take_vlmax) return vlmax[VL_WIDTH-1:0];
    else                 return avl[VL_WIDTH-1:0];
  endfunction

endpackage

// =============================================================================
// VSetRiWi —— 可读核 xs_VSetRiWi_core(向量配置单元:读两整型寄存器、写整型 rd)
// -----------------------------------------------------------------------------
// 设计源:src/main/scala/xiangshan/backend/fu/wrapper/VSet.scala (class VSetRiWi)
//         + class VSetBase(操作数/vtype 选源) + class VsetModule(vl 计算)。
//
// 角色:处理 vset 指令中「把新 vl 写到整型寄存器 rd」的那个 uop(uvsetrd_*)。
//   覆盖 uvsetrd_ii / uvsetrd_xi / uvsetrd_xx / uvsetrd_vlmax_{i,x} 等变体。
//   输出 res.data = 计算出的 vl(零扩展到 64 位)。本核 **不写 vtype 寄存器**
//   (那是 VSetRiWvf/VSetRvfWvf 的职责),故只产出 vl。
//
// 数据流(纯组合,单周期):
//   ┌── src0/src1 + fuOpType
//   │      │
//   │  ① 选 AVL    : vsetivli 用立即数(src1[14:10]),否则用整型 rs1=src0。
//   │  ② 选 vtype  : vsetvl 用 rs2 的 VtypeStruct(src1),否则用立即数解码的 vtype。
//   │      │
//   │  ③ VsetModule 计算: VLMAX、合法性、vl=min(AVL,VLMAX)。
//   └──> res.data = {56'b0, vl}
//
// VSetBase 的握手/控制位(valid/robIdx/pdest/rfWen/perfDebugInfo)由 wrapper 直通。
// =============================================================================
module xs_VSetRiWi_core
  import vset_pkg::*;
(
  input  logic [8:0]  func,    // fuOpType(vset 变体编码)
  input  logic [63:0] src0,    // 整型 rs1(普通 AVL)
  input  logic [63:0] src1,    // 整型 rs2 / 立即数载体(vtype、立即 AVL)
  output logic [63:0] res_data // 写回整型 rd 的 vl(零扩展)
);

  // ---------------------------------------------------------------------------
  // ① AVL 选源
  //   - vsetivli(func[7:6]==00):AVL 来自指令 uimm5,封装在 src1[14:10]。
  //   - 其余(vsetvli/vsetvl):AVL = 整型 rs1 = src0(rs1==x0 的 vlmax 特例由
  //     calc_vl 里的 setVlmax 位处理,这里仍取 src0)。
  //   判据 (|func[7:6]) == !isVsetivli,与 golden 一致。
  // ---------------------------------------------------------------------------
  logic [63:0] avl;
  assign avl = (|func[7:6]) ? src0 : {59'h0, src1[14:10]};

  // ---------------------------------------------------------------------------
  // ② vtype 选源 —— 三条路径解码成统一的 vtype_in_t
  //   - vsetvl(func[6]=1):vtype = rs2 的 VtypeStruct(src1),含 vill(src1[63])
  //     与 55 位 reserved(src1[62:8])。
  //   - vsetvli(func[7]=1):vtype = 11 位立即数 InstVType,reserved 仅 3 位(src1[10:8])。
  //   - vsetivli(func[7:6]=00):vtype = 10 位立即数 InstVType,reserved 仅 2 位(src1[9:8])。
  //   三路的 vma/vta/vsew/vlmul 位置相同(src1[7]/[6]/[5:3]/[2:0]),差异只在
  //   illegal 与 reserved 的来源与宽度。
  // ---------------------------------------------------------------------------
  vset_kind_e kind;
  vtype_in_t  vtype;
  assign kind = classify(func);
  always_comb begin
    vtype.vma   = src1[7];
    vtype.vta   = src1[6];
    vtype.vsew  = src1[5:3];
    vtype.vlmul = src1[2:0];
    unique case (kind)
      VSET_IVLI: begin  // 立即数 vtype,reserved 仅 2 位
        vtype.illegal  = 1'b0;
        vtype.reserved = {53'h0, src1[9:8]};
      end
      VSET_VLI: begin   // 立即数 vtype,reserved 3 位
        vtype.illegal  = 1'b0;
        vtype.reserved = {52'h0, src1[10:8]};
      end
      default: begin    // VSET_VL / VSET_VL2:寄存器 VtypeStruct(含 vill)
        vtype.illegal  = src1[63];
        vtype.reserved = src1[62:8];
      end
    endcase
  end

  // ---------------------------------------------------------------------------
  // ③ VsetModule 计算:VLMAX / 合法性 / vl
  // ---------------------------------------------------------------------------
  logic [2:0]          log2_sew;
  logic [VLMAX_W-1:0]  vlmax;
  logic                illegal;
  logic [VL_WIDTH-1:0] vl;

  assign log2_sew = calc_log2_sew(vtype.vsew);
  assign vlmax    = calc_vlmax(vtype.vlmul, log2_sew);
  assign illegal  = calc_illegal(vtype.vlmul, vtype.vsew, log2_sew,
                                 vtype.reserved, vtype.illegal);
  assign vl       = calc_vl(illegal, func, avl, vlmax);

  // 写回 rd:vl 零扩展到 64 位(VSetRiWi 只产出 vl)。
  assign res_data = {56'h0, vl};

endmodule

// ---------------------------------------------------------------------------
// golden 同名 wrapper：端口与 G1 golden VSetRiWi.sv 完全一致
// ---------------------------------------------------------------------------
module VSetRiWi(
  output        io_in_ready,
  input         io_in_valid,
  input  [8:0]  io_in_bits_ctrl_fuOpType,
  input         io_in_bits_ctrl_robIdx_flag,
  input  [7:0]  io_in_bits_ctrl_robIdx_value,
  input  [7:0]  io_in_bits_ctrl_pdest,
  input         io_in_bits_ctrl_rfWen,
  input  [63:0] io_in_bits_data_src_1,
  input  [63:0] io_in_bits_data_src_0,
  input         io_in_bits_perfDebugInfo_eliminatedMove,
  input  [63:0] io_in_bits_perfDebugInfo_renameTime,
  input  [63:0] io_in_bits_perfDebugInfo_dispatchTime,
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
  input  [63:0] io_in_bits_perfDebugInfo_writebackTime,
  input  [63:0] io_in_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0] io_in_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0] io_in_bits_perfDebugInfo_tlbRespTime,
  input  [55:0] io_in_bits_debug_seqNum_seqNum,
  input  [7:0]  io_in_bits_debug_seqNum_uopIdx,
  input         io_out_ready,
  output        io_out_valid,
  output        io_out_bits_ctrl_robIdx_flag,
  output [7:0]  io_out_bits_ctrl_robIdx_value,
  output [7:0]  io_out_bits_ctrl_pdest,
  output        io_out_bits_ctrl_rfWen,
  output [63:0] io_out_bits_res_data,
  output        io_out_bits_perfDebugInfo_eliminatedMove,
  output [63:0] io_out_bits_perfDebugInfo_renameTime,
  output [63:0] io_out_bits_perfDebugInfo_dispatchTime,
  output [63:0] io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_out_bits_perfDebugInfo_selectTime,
  output [63:0] io_out_bits_perfDebugInfo_issueTime,
  output [63:0] io_out_bits_perfDebugInfo_writebackTime,
  output [63:0] io_out_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0] io_out_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0] io_out_bits_perfDebugInfo_tlbRespTime,
  output [55:0] io_out_bits_debug_seqNum_seqNum,
  output [7:0]  io_out_bits_debug_seqNum_uopIdx
);

  // vset 计算核：func/src -> {vtype, vl} 打包结果
  xs_VSetRiWi_core u_core (
    .func     (io_in_bits_ctrl_fuOpType),
    .src0     (io_in_bits_data_src_0),
    .src1     (io_in_bits_data_src_1),
    .res_data (io_out_bits_res_data)
  );

  // 握手直通（无内部阻塞）
  assign io_in_ready                                      = io_out_ready;

  // 控制/调试旁路直通（Chisel PipedFuncUnit 的 out := in）
  assign io_out_valid                                     = io_in_valid;
  assign io_out_bits_ctrl_robIdx_flag                     = io_in_bits_ctrl_robIdx_flag;
  assign io_out_bits_ctrl_robIdx_value                    = io_in_bits_ctrl_robIdx_value;
  assign io_out_bits_ctrl_pdest                           = io_in_bits_ctrl_pdest;
  assign io_out_bits_ctrl_rfWen                           = io_in_bits_ctrl_rfWen;
  assign io_out_bits_perfDebugInfo_eliminatedMove         = io_in_bits_perfDebugInfo_eliminatedMove;
  assign io_out_bits_perfDebugInfo_renameTime             = io_in_bits_perfDebugInfo_renameTime;
  assign io_out_bits_perfDebugInfo_dispatchTime           = io_in_bits_perfDebugInfo_dispatchTime;
  assign io_out_bits_perfDebugInfo_enqRsTime              = io_in_bits_perfDebugInfo_enqRsTime;
  assign io_out_bits_perfDebugInfo_selectTime             = io_in_bits_perfDebugInfo_selectTime;
  assign io_out_bits_perfDebugInfo_issueTime              = io_in_bits_perfDebugInfo_issueTime;
  assign io_out_bits_perfDebugInfo_writebackTime          = io_in_bits_perfDebugInfo_writebackTime;
  assign io_out_bits_perfDebugInfo_runahead_checkpoint_id = io_in_bits_perfDebugInfo_runahead_checkpoint_id;
  assign io_out_bits_perfDebugInfo_tlbFirstReqTime        = io_in_bits_perfDebugInfo_tlbFirstReqTime;
  assign io_out_bits_perfDebugInfo_tlbRespTime            = io_in_bits_perfDebugInfo_tlbRespTime;
  assign io_out_bits_debug_seqNum_seqNum                  = io_in_bits_debug_seqNum_seqNum;
  assign io_out_bits_debug_seqNum_uopIdx                  = io_in_bits_debug_seqNum_uopIdx;

endmodule
