// =============================================================================
// uopinfogen_pkg —— 香山 V2R2(昆明湖) UopInfoGen 的类型/常量定义
// -----------------------------------------------------------------------------
// 对应 Scala 源:xiangshan.backend.decode.UopInfoGen(含两张 QMC 真值表
//   strdiedLSNumOfUopTable / indexedLSNumOfUopTable)。
//
// 【UopInfoGen 在做什么】
//   译码阶段对一条**向量/特殊指令**算出它要拆成多少个微操作(uop):
//     numOfUop : 该指令展开的 uop 总数(向量按 LMUL/EMUL/NF 等展开,可达数十)。
//     numOfWB  : 写回(writeback)次数。除 AMOCAS 是 numOfUop>>1 外都等于 numOfUop。
//     lmul     : 译出的 LMUL 整数倍数(1/2/4/8),供下游展开使用。
//     isComplex: 该指令是否"复杂"(向量算术/向量访存/AMOCAS),需走拆分通道。
//   它只看一个 PreInfo(由前级译码给出的预解析信息),不看完整指令。
//
// 【为什么 numOfUop 这么多分支】
//   RVV 指令的 uop 数取决于 split 类型(vvv/vfv/load/store/slide/gather/...)与
//   LMUL/EMUL/NF/SEW 的组合。Scala 用一个大 MuxLookup(typeOfSplit -> 表达式)
//   罗列了每种 split 的 uop 数公式。这里按同一组公式重写(每个 split 一条 case)。
//
// 【两张 LS 表】
//   strided/indexed 向量访存的 uop 数是 (emul,nf)/(emul,lmul,nf) 的函数,Scala 用
//   QMCMinimizer 把生成规则压成真值表。这里**不抄真值表**,而是按 Scala 生成这些
//   表项的算法(见 strided_ls_uops / indexed_ls_uops 函数)直接计算,语义等价且可读。
// =============================================================================
package uopinfogen_pkg;

  localparam int unsigned MAX_UOP_SIZE = 65;
  localparam int unsigned UOP_W = $clog2(MAX_UOP_SIZE + 1); // 7

  // ---------------------------------------------------------------------------
  // UopSplitType(6 位):指令的微操作拆分类型。与 Scala object UopSplitType 同码。
  // (仅列出 numOfUop 表里用到/会出现的取值;命名沿用 Scala。)
  // ---------------------------------------------------------------------------
  typedef enum logic [5:0] {
    SPLIT_SCA_SIM        = 6'b000000, // 标量/简单(numOfUop=1)
    SPLIT_VEC_MVNR       = 6'b000100, // vmvnr (= 6'h04)
    SPLIT_VSET           = 6'b010001, // vset  (= 6'h11)
    SPLIT_VEC_VVV        = 6'b010010, // 6'h12
    SPLIT_VEC_VXV        = 6'b010011, // 6'h13
    SPLIT_VEC_0XV        = 6'b010100, // 6'h14
    SPLIT_VEC_VVW        = 6'b010101, // 6'h15
    SPLIT_VEC_WVW        = 6'b010110, // 6'h16
    SPLIT_VEC_VXW        = 6'b010111, // 6'h17
    SPLIT_VEC_WXW        = 6'b011000, // 6'h18
    SPLIT_VEC_WVV        = 6'b011001, // 6'h19
    SPLIT_VEC_WXV        = 6'b011010, // 6'h1A
    SPLIT_VEC_EXT2       = 6'b011011, // 6'h1B
    SPLIT_VEC_EXT4       = 6'b011100, // 6'h1C
    SPLIT_VEC_EXT8       = 6'b011101, // 6'h1D
    SPLIT_VEC_VVM        = 6'b011110, // 6'h1E
    SPLIT_VEC_VXM        = 6'b011111, // 6'h1F
    SPLIT_VEC_SLIDE1UP   = 6'b100000, // 6'h20
    SPLIT_VEC_FSLIDE1UP  = 6'b100001, // 6'h21
    SPLIT_VEC_SLIDE1DOWN = 6'b100010, // 6'h22
    SPLIT_VEC_FSLIDE1DOWN= 6'b100011, // 6'h23
    SPLIT_VEC_VRED       = 6'b100100, // 6'h24
    SPLIT_VEC_SLIDEUP    = 6'b100101, // 6'h25
    SPLIT_VEC_SLIDEDOWN  = 6'b100111, // 6'h27
    SPLIT_VEC_M0X        = 6'b101001, // 6'h29
    SPLIT_VEC_MVV        = 6'b101010, // 6'h2A
    SPLIT_VEC_VWW        = 6'b101100, // 6'h2C
    SPLIT_VEC_RGATHER    = 6'b101101, // 6'h2D
    SPLIT_VEC_RGATHER_VX = 6'b101110, // 6'h2E
    SPLIT_VEC_RGATHEREI16= 6'b101111, // 6'h2F
    SPLIT_VEC_COMPRESS   = 6'b110000, // 6'h30
    SPLIT_VEC_US_LDST    = 6'b110001, // 6'h31
    SPLIT_VEC_S_LDST     = 6'b110010, // 6'h32
    SPLIT_VEC_I_LDST     = 6'b110011, // 6'h33
    SPLIT_VEC_US_FF_LD   = 6'b110100, // 6'h34
    SPLIT_AMO_CAS_W      = 6'b110101, // 6'h35
    SPLIT_AMO_CAS_D      = 6'b110110, // 6'h36
    SPLIT_AMO_CAS_Q      = 6'b110111, // 6'h37
    SPLIT_VEC_VFV        = 6'b111000, // 6'h38
    SPLIT_VEC_VFW        = 6'b111001, // 6'h39
    SPLIT_VEC_WFW        = 6'b111010, // 6'h3A
    SPLIT_VEC_VFM        = 6'b111011, // 6'h3B
    SPLIT_VEC_VFRED      = 6'b111100, // 6'h3C
    SPLIT_VEC_VFREDOSUM  = 6'b111101  // 6'h3D
  } uop_split_e;

  // VLmul(3 位)编码。
  localparam logic [2:0] LMUL_M1 = 3'b000, LMUL_M2 = 3'b001, LMUL_M4 = 3'b010, LMUL_M8 = 3'b011;
  // VSew(2 位)编码。
  localparam logic [1:0] SEW_E8 = 2'b00, SEW_E16 = 2'b01, SEW_E32 = 2'b10, SEW_E64 = 2'b11;

  // 输入预解析信息(聚合 golden 扁平端口)。
  typedef struct packed {
    logic        isVecArith;
    logic        isVecMem;
    logic        isAmoCAS;
    logic [5:0]  typeOfSplit;
    logic [1:0]  vsew;
    logic [2:0]  vlmul;
    logic [2:0]  vwidth;   // eew
    logic [2:0]  nf;
    logic [2:0]  vmvn;     // vmvnr 的寄存器组数-1
    logic        isVlsr;   // 整寄存器 load/store
    logic        isVlsm;   // 掩码 load/store
  } preinfo_t;

  // 输出 uop 信息。
  typedef struct packed {
    logic [UOP_W-1:0] numOfUop;
    logic [UOP_W-1:0] numOfWB;
    logic [3:0]       lmul;
  } uopinfo_t;

endpackage

// =============================================================================
// xs_UopInfoGen_core —— 香山 V2R2(昆明湖) UopInfoGen 核(可读重写)
// -----------------------------------------------------------------------------
// 对应 Scala 源:xiangshan.backend.decode.UopInfoGen(及其内联的两张 LS 真值表)。
// 纯组合叶子。语义见 uopinfogen_pkg 头注。
//
// 结构:
//   1) 由 vlmul/vsew/vwidth 推出 lmul/emul 及其"简化 2 位"形式;
//   2) 计算各 split 专用的 uop 数中间量(VFRED/VFREDOSUM/vslide/vrgather/
//      vcompress/WV/WX/strided/indexed 等);
//   3) 大 case:typeOfSplit -> numOfUop;
//   4) numOfWB(AMOCAS 减半)、isComplex、lmul 输出。
// =============================================================================

module xs_UopInfoGen_core
  import uopinfogen_pkg::*;
(
  input  preinfo_t  pre,
  output logic      is_complex,
  output uopinfo_t  uop_info
);

  // ---------------------------------------------------------------------------
  // 1. LMUL / EMUL 推导。
  //    lmul:VLmul -> 整数倍(分数 LMUL 取 1)。simple_lmul:取 log2 形式(0..3)。
  //    vemul = veew + 1 + vlmul + ~vsew(Scala 的 EMUL 计算,模 8)。
  // ---------------------------------------------------------------------------
  wire [2:0] vsew3  = {1'b0, pre.vsew};            // 0 扩展到 3 位(与 Scala 一致)
  wire [2:0] veew3  = {1'b0, pre.vwidth[1:0]};
  wire [2:0] vlmul  = pre.vlmul;

  // lmul:VLmul=000/001/010/011 -> 1/2/4/8;分数 LMUL(1xx)-> 1
  function automatic logic [3:0] lmul_of(input logic [2:0] m);
    case (m)
      LMUL_M2: return 4'd2;
      LMUL_M4: return 4'd4;
      LMUL_M8: return 4'd8;
      default: return 4'd1;
    endcase
  endfunction
  wire [3:0] lmul = lmul_of(vlmul);

  // simple_lmul:000/001/010/011 -> 0/1/2/3;否则 0
  function automatic logic [1:0] simple_of(input logic [2:0] m);
    case (m)
      LMUL_M2: return 2'd1;
      LMUL_M4: return 2'd2;
      LMUL_M8: return 2'd3;
      default: return 2'd0;
    endcase
  endfunction
  wire [1:0] simple_lmul = simple_of(vlmul);

  // vemul = veew + 1 + vlmul + ~vsew (3 位模运算,与 Scala/golden 一致)
  wire [2:0] vemul = veew3 + 3'd1 + vlmul + (~vsew3);
  // emul:vemul=001/010/011 -> 2/4/8;否则 1
  wire [3:0] emul = (vemul == 3'b011) ? 4'd8 :
                    (vemul == 3'b010) ? 4'd4 :
                    (vemul == 3'b001) ? 4'd2 : 4'd1;
  // simple_emul:vemul=001/010/011 -> 1/2/3;否则 0
  wire [1:0] simple_emul = (vemul == 3'b011) ? 2'd3 :
                           (vemul == 3'b010) ? 2'd2 :
                           (vemul == 3'b001) ? 2'd1 : 2'd0;

  // ---------------------------------------------------------------------------
  // 2. 各 split 专用 uop 数中间量(逐一对应 Scala 的同名 val)。
  // ---------------------------------------------------------------------------
  // slide / rgather:按 vlmul 的固定阶梯。
  wire [UOP_W-1:0] num_vslide = (vlmul == LMUL_M8) ? 7'd36 :
                                (vlmul == LMUL_M4) ? 7'd10 :
                                (vlmul == LMUL_M2) ? 7'd3  : 7'd1;
  wire [UOP_W-1:0] num_vrgather = (vlmul == LMUL_M8) ? 7'd64 :
                                  (vlmul == LMUL_M4) ? 7'd16 :
                                  (vlmul == LMUL_M2) ? 7'd4  : 7'd1;
  // vrgatherei16:vsew==0 且 vlmul!=m8 时翻倍(<<1)。
  wire [UOP_W-1:0] num_vrgatherei16 = (pre.vsew == 2'b00 && vlmul != LMUL_M8)
                                      ? {num_vrgather[UOP_W-2:0], 1'b0} : num_vrgather;
  // vcompress(1/4/13/43)直接在下面的 case 里按 8 位给出(43 超出 4 位)。

  // WV / WX(展宽/收窄 V/X):1<=lmul<=4 范围内的阶梯。
  wire [3:0] num_wv = (vlmul == LMUL_M4) ? 4'd8 :
                      (vlmul == LMUL_M2) ? 4'd4 :
                      (vlmul == LMUL_M1) ? 4'd2 : 4'd1;   // 否则 1
  wire [3:0] num_wx = (vlmul == LMUL_M4) ? 4'd9 :
                      (vlmul == LMUL_M2) ? 4'd5 :
                      (vlmul == LMUL_M1) ? 4'd3 : 4'd2;   // 否则 2(多一条 move)

  // VFRED:addTime(按 lmul) + foldTime(按 vsew 折叠),至少 1。
  function automatic logic [3:0] vfred_addtime(input logic [2:0] m);
    case (m)
      LMUL_M2: return 4'd2;
      LMUL_M4: return 4'd4;
      LMUL_M8: return 4'd8;
      default: return 4'd1;
    endcase
  endfunction
  // foldLastVlmul:vsew e16/e32/e64 -> mf8/mf4/mf2(3 位编码 101/110/111),否则 000
  function automatic logic [2:0] fold_last_vlmul(input logic [1:0] sew);
    case (sew)
      SEW_E16: return 3'b101; // mf8
      SEW_E32: return 3'b110; // mf4
      SEW_E64: return 3'b111; // mf2
      default: return 3'b000;
    endcase
  endfunction
  // foldTime = (vlmul[2]?vlmul:0) - foldLastVlmul  (3 位模运算)
  wire [2:0] vfred_foldtime = (vlmul[2] ? vlmul : 3'b000) - fold_last_vlmul(pre.vsew);
  wire [3:0] vfred_sum = vfred_addtime(vlmul) + {1'b0, vfred_foldtime};
  wire [3:0] num_vfred = (|vfred_sum) ? vfred_sum : 4'd1;

  // VFREDOSUM:vlMax = uvlMax(按 vsew) << / >> vlmul,至少 1。
  function automatic logic [6:0] vfredo_uvlmax(input logic [1:0] sew);
    case (sew)
      SEW_E16: return 7'd8;
      SEW_E32: return 7'd4;
      SEW_E64: return 7'd2;
      default: return 7'd1;
    endcase
  endfunction
  wire [6:0] vfredo_uvl = vfredo_uvlmax(pre.vsew);
  // vlmul[2]=1 表示分数 LMUL:右移 (-vlmul)[1:0];否则左移 vlmul[1:0]
  wire [6:0] vfredo_vlmax = vlmul[2]
                          ? (vfredo_uvl >> ((3'd0 - vlmul) & 3'b011))
                          : (vfredo_uvl << (vlmul & 3'b011));
  wire [6:0] num_vfredosum = (|vfredo_vlmax) ? vfredo_vlmax : 7'd1;

  // ---------------------------------------------------------------------------
  // 两张向量访存 LS 表(按 Scala 生成算法直接计算,等价于 QMC 真值表)。
  // ---------------------------------------------------------------------------
  // strided:src={simple_emul[1:0], nf[2:0]};
  //   uop = ((1<<emul)*(nf+1) <= 8) ? (1<<emul)*(nf+1) : 0
  function automatic logic [3:0] strided_ls_uops(input logic [1:0] emul2, input logic [2:0] nf3);
    int ev, prod;
    ev   = 1 << emul2;          // 1/2/4/8
    prod = ev * (int'(nf3) + 1);
    return (prod <= 8) ? 4'(prod) : 4'd0;
  endfunction
  wire [3:0] num_strided = strided_ls_uops(simple_emul, pre.nf);

  // indexed:src={simple_emul[1:0], simple_lmul[1:0], nf[2:0]};
  //   nf==0: uop = max(1<<emul,1<<lmul)(lmul<=8 恒真)
  //   nf>0 : up = max((1<<lmul)*(nf+1), 1<<emul); uop = ((1<<lmul)*(nf+1)<=8)?up:0
  function automatic logic [3:0] indexed_ls_uops(input logic [1:0] emul2,
                                                 input logic [1:0] lmul2,
                                                 input logic [2:0] nf3);
    int ev, lv, mul_max, lp, up;
    ev = 1 << emul2;
    lv = 1 << lmul2;
    mul_max = (ev > lv) ? ev : lv;
    if (nf3 == 3'd0) begin
      return 4'(mul_max);
    end else begin
      lp = lv * (int'(nf3) + 1);
      up = (lp > ev) ? lp : ev;
      return (lp <= 8) ? 4'(up) : 4'd0;
    end
  endfunction
  wire [3:0] num_indexed = indexed_ls_uops(simple_emul, simple_lmul, pre.nf);

  // ---------------------------------------------------------------------------
  // 3. 大 case:typeOfSplit -> numOfUop(8 位,输出取低 7 位)。
  //    每条 case 直接对应 Scala MuxLookup 的一项。
  // ---------------------------------------------------------------------------
  logic [7:0] num_uop;
  uop_split_e split;
  assign split = uop_split_e'(pre.typeOfSplit);

  // 常用复合量(都先零扩展到 8 位)。
  wire [7:0] lmul8        = {4'd0, lmul};
  wire [7:0] lmul_plus1   = {3'd0, ({1'b0, lmul} + 5'd1)};   // lmul + 1
  wire [7:0] lmul_x2      = {3'd0, lmul, 1'b0};              // lmul * 2
  wire [7:0] lmul_x2_m1   = {3'd0, ({lmul, 1'b0} - 5'd1)};   // lmul*2 - 1

  always_comb begin
    unique case (split)
      SPLIT_VSET:            num_uop = 8'd2;
      SPLIT_VEC_0XV:         num_uop = 8'd2;
      SPLIT_VEC_VVV:         num_uop = lmul8;
      SPLIT_VEC_VFV:         num_uop = lmul_plus1;
      SPLIT_VEC_EXT2:        num_uop = lmul8;
      SPLIT_VEC_EXT4:        num_uop = lmul8;
      SPLIT_VEC_EXT8:        num_uop = lmul8;
      SPLIT_VEC_VVM:         num_uop = lmul8;
      SPLIT_VEC_VFM:         num_uop = lmul_plus1;
      SPLIT_VEC_VFRED:       num_uop = {4'd0, num_vfred};
      SPLIT_VEC_VFREDOSUM:   num_uop = {1'b0, num_vfredosum};
      SPLIT_VEC_VXM:         num_uop = lmul_plus1;
      SPLIT_VEC_VXV:         num_uop = lmul_plus1;
      SPLIT_VEC_VFW:         num_uop = {4'd0, num_wx};
      SPLIT_VEC_WFW:         num_uop = {4'd0, num_wx};
      SPLIT_VEC_VVW:         num_uop = {4'd0, num_wv};
      SPLIT_VEC_WVW:         num_uop = {4'd0, num_wv};
      SPLIT_VEC_VXW:         num_uop = {4'd0, num_wx};
      SPLIT_VEC_WXW:         num_uop = {4'd0, num_wx};
      SPLIT_VEC_WVV:         num_uop = {4'd0, num_wv};
      SPLIT_VEC_WXV:         num_uop = {4'd0, num_wx};
      SPLIT_VEC_SLIDE1UP:    num_uop = lmul_plus1;
      SPLIT_VEC_FSLIDE1UP:   num_uop = lmul_plus1;
      SPLIT_VEC_SLIDE1DOWN:  num_uop = lmul_x2;
      SPLIT_VEC_FSLIDE1DOWN: num_uop = lmul_x2;
      SPLIT_VEC_VRED:        num_uop = lmul8;
      SPLIT_VEC_SLIDEUP:     num_uop = {1'b0, num_vslide} + 8'd1;
      SPLIT_VEC_SLIDEDOWN:   num_uop = {1'b0, num_vslide} + 8'd1;
      SPLIT_VEC_M0X:         num_uop = lmul8;
      SPLIT_VEC_MVV:         num_uop = lmul_x2_m1;
      SPLIT_VEC_VWW:         num_uop = lmul_x2;
      SPLIT_VEC_RGATHER:     num_uop = {1'b0, num_vrgather};
      SPLIT_VEC_RGATHER_VX:  num_uop = {1'b0, num_vrgather} + 8'd1;
      SPLIT_VEC_RGATHEREI16: num_uop = {1'b0, num_vrgatherei16};
      SPLIT_VEC_COMPRESS:    num_uop = (vlmul == LMUL_M8) ? 8'd43 :
                                       (vlmul == LMUL_M4) ? 8'd13 :
                                       (vlmul == LMUL_M2) ? 8'd4  : 8'd1;
      SPLIT_VEC_MVNR:        num_uop = {4'd0, ({1'b0, pre.vmvn} + 4'd1)};
      SPLIT_VEC_US_LDST:     num_uop = pre.isVlsr ? {3'd0, ({1'b0, pre.nf} + 4'd2)} :
                                       pre.isVlsm ? 8'd2 :
                                                    {3'd0, ({1'b0, num_strided} + 5'd1)};
      SPLIT_VEC_US_FF_LD:    num_uop = {3'd0, ({1'b0, num_strided} + 5'd2)};
      SPLIT_VEC_S_LDST:      num_uop = {3'd0, ({1'b0, num_strided} + 5'd2)};
      SPLIT_VEC_I_LDST:      num_uop = {3'd0, ({1'b0, num_indexed} + 5'd1)};
      SPLIT_AMO_CAS_W:       num_uop = 8'd2;
      SPLIT_AMO_CAS_D:       num_uop = 8'd2;
      SPLIT_AMO_CAS_Q:       num_uop = 8'd4;
      default:               num_uop = 8'd1; // SCA_SIM 及其它:1
    endcase
  end

  // ---------------------------------------------------------------------------
  // 4. numOfWB / isComplex / lmul 输出。
  //    isAMOCAS(W/D/Q)时 numOfWB = numOfUop >> 1,否则等于 numOfUop。
  // ---------------------------------------------------------------------------
  wire is_amocas = (split == SPLIT_AMO_CAS_W) ||
                   (split == SPLIT_AMO_CAS_D) ||
                   (split == SPLIT_AMO_CAS_Q);

  assign uop_info.numOfUop = num_uop[UOP_W-1:0];
  assign uop_info.numOfWB  = is_amocas ? num_uop[UOP_W:1] : num_uop[UOP_W-1:0];
  assign uop_info.lmul     = lmul;
  assign is_complex        = pre.isVecArith | pre.isVecMem | pre.isAmoCAS;

endmodule

// =============================================================================
// UopInfoGen (wrapper) —— golden 同名顶层,端口与 golden/chisel-rtl/UopInfoGen.sv 一致。
// 机械适配层:把 golden 扁平端口聚合成可读核 xs_UopInfoGen_core 的 struct。
// 注意:golden 顶层会例化 strdiedLSNumOfUopTable / indexedLSNumOfUopTable 两个子
//   模块,而可读核把这两张表用 function 内联(语义等价),故 wrapper 无子模块。
// =============================================================================

// ---------------------------------------------------------------------------
// golden 同名 wrapper
// ---------------------------------------------------------------------------

module UopInfoGen
  import uopinfogen_pkg::*;
(
  input        io_in_preInfo_isVecArith,
  input        io_in_preInfo_isVecMem,
  input        io_in_preInfo_isAmoCAS,
  input  [5:0] io_in_preInfo_typeOfSplit,
  input  [1:0] io_in_preInfo_vsew,
  input  [2:0] io_in_preInfo_vlmul,
  input  [2:0] io_in_preInfo_vwidth,
  input  [2:0] io_in_preInfo_nf,
  input  [2:0] io_in_preInfo_vmvn,
  input        io_in_preInfo_isVlsr,
  input        io_in_preInfo_isVlsm,
  output       io_out_isComplex,
  output [6:0] io_out_uopInfo_numOfUop,
  output [6:0] io_out_uopInfo_numOfWB,
  output [3:0] io_out_uopInfo_lmul
);

  preinfo_t pre;
  uopinfo_t info;
  logic     cplx;

  assign pre = '{
    isVecArith:  io_in_preInfo_isVecArith,
    isVecMem:    io_in_preInfo_isVecMem,
    isAmoCAS:    io_in_preInfo_isAmoCAS,
    typeOfSplit: io_in_preInfo_typeOfSplit,
    vsew:        io_in_preInfo_vsew,
    vlmul:       io_in_preInfo_vlmul,
    vwidth:      io_in_preInfo_vwidth,
    nf:          io_in_preInfo_nf,
    vmvn:        io_in_preInfo_vmvn,
    isVlsr:      io_in_preInfo_isVlsr,
    isVlsm:      io_in_preInfo_isVlsm
  };

  xs_UopInfoGen_core u_core (.pre(pre), .is_complex(cplx), .uop_info(info));

  assign io_out_isComplex        = cplx;
  assign io_out_uopInfo_numOfUop = info.numOfUop;
  assign io_out_uopInfo_numOfWB  = info.numOfWB;
  assign io_out_uopInfo_lmul     = info.lmul;

endmodule
