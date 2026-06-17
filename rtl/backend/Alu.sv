// =============================================================================
// xs_Alu_core —— 香山 V2R2(昆明湖) 整数算术逻辑单元 (可读重写)
// -----------------------------------------------------------------------------
// 设计源:src/main/scala/xiangshan/backend/fu/Alu.scala 的 AluDataModule,
//        以及 src/main/scala/xiangshan/package.scala 的 object ALUOpType。
//
// 位置与角色:ALU 位于后端 ExuBlock 内,是整数发射端口最常用的执行单元。
//   它是 **单周期纯组合** 的叶子 FU:输入两个 64bit 操作数 src1/src2 与 7 位
//   运算码 func,输出 64bit 结果 result。流水寄存/握手由外层 PipedFuncUnit
//   (golden 顶层 Alu)负责,本核只做组合运算。
//
// 结构(对齐 Scala 设计意图,而非 firtool 展平 RTL):
//   ALU 把所有运算并行算出,再按 func 选择。为利于时序,选择被组织成两级:
//     1) 每条"结果通道"内部:由低位 func 选出该通道结果(本文件 6 个 function)。
//     2) 顶层:由 func[6:4] 在 6 条通道间做最终 6 选 1 (sel_result)。
//   通道:shift / word / add / compare / misc / cond,见 alu_pkg 注释。
//
// 与 golden 的差异:golden 把每种基本运算拆成一个小 Module(AddModule/
//   ShiftResultSelect/...)。这些都是平凡叶子,这里改用 `function automatic`
//   表达,逻辑更聚合、可读;字节/位级并行(orcb/revb/rev8/shadd 表)用 for。
// =============================================================================
module xs_Alu_core
  import alu_pkg::*;
(
  input  logic [XLEN-1:0] src1,
  input  logic [XLEN-1:0] src2,
  input  logic [6:0]      func,   // fuOpType 低 7 位
  output logic [XLEN-1:0] result
);

  // ---------------------------------------------------------------------------
  // 0. 公共量:移位量 shamt 与其"反向移位量"revShamt。
  //    循环移位 rol/ror 用 (左移 shamt) | (右移 64-shamt) 实现,而 64-shamt 在
  //    6 位下恰好等于 (~shamt + 1)(二进制补码),省一个减法器,故称 revShamt。
  // ---------------------------------------------------------------------------
  logic [5:0] shamt;
  logic [5:0] rev_shamt;
  assign shamt     = src2[5:0];
  assign rev_shamt = (~src2[5:0]) + 6'd1;

  // func[0]=1 时(slliuw/adduw 等)左移与加法的源要先 ZEXT 到 32 位:
  // 高 32 位清零,低 32 位保留。用一个公共掩码表达。
  logic [XLEN-1:0] uw_mask;        // func[0]? {32'h0,32'hFFFFFFFF} : 全 1
  logic [XLEN-1:0] left_shift_src; // 左移(sll/rol/ror 的 sll 项)共享的源
  assign uw_mask        = {{32{func[0]}}, 32'hFFFF_FFFF};
  assign left_shift_src = uw_mask & src1;

  // ===========================================================================
  // 1. 移位通道 shiftRes —— func[6:4]==000 且 func[4]==0
  //    含 sll/srl/sra 三类移位,rol/ror 两类循环移位,
  //    以及 Zbs 单 bit 操作 bclr/bset/binv/bext。
  //    通道内由 func[3:0] 选择(见 Scala ShiftResultSelect)。
  // ===========================================================================
  // 单 bit 掩码:1 左移到 src2[5:0] 指定位,用于 bclr/bset/binv。
  logic [XLEN-1:0] bit_mask;
  assign bit_mask = {{(XLEN-1){1'b0}}, 1'b1} << src2[5:0];

  // 所有共享量(shamt/rev_shamt/ls_src/b_mask)经实参传入,不读模块网,
  // 既保证组合敏感正确,又避免 FM 的 non-local-variable 误判。
  function automatic logic [XLEN-1:0] shift_channel(
      logic [3:0] f, logic [XLEN-1:0] s1,
      logic [5:0] sh, logic [5:0] rsh,
      logic [XLEN-1:0] ls_src, logic [XLEN-1:0] b_mask);
    logic [XLEN-1:0] sll, srl, sra, rol, ror_v;
    logic [XLEN-1:0] simple;
    sll   = ls_src << sh;
    srl   = s1 >> sh;
    sra   = $signed(s1) >>> sh;
    // 循环 = 正向 | 反向。注意循环移位的两项都用同一个左移源 ls_src。
    rol   = (s1 >> rsh) | (ls_src << sh);
    ror_v = (s1 >> sh)  | (ls_src << rsh);
    // func[2:0] 在非循环情形下选 8 选 1:
    //   0/1:sll  2:bclr 3:bset 4:binv 5:srl 6:bext 7:sra
    unique case (f[2:0])
      3'd0, 3'd1: simple = sll;
      3'd2:       simple = s1 & ~b_mask;              // bclr
      3'd3:       simple = s1 |  b_mask;              // bset
      3'd4:       simple = s1 ^  b_mask;              // binv
      3'd5:       simple = srl;
      3'd6:       simple = {{(XLEN-1){1'b0}}, srl[0]};// bext
      default:    simple = sra;                       // 3'd7
    endcase
    // func[3]=1 → 循环移位:func[1] 选 rol/ror。
    return f[3] ? (f[1] ? ror_v : rol) : simple;
  endfunction

  // ===========================================================================
  // 2. 杂项通道 miscRes —— func[6:4]∈{100,101,110}
  //    逻辑运算(and/or/xor 及其取反 andn/orn/xnor、orcb)与 Zbb 字节/半字
  //    操作(sextb/packh/sexth/packw/revb/rev8/pack/orh48 及 LSB/ZEXTH 变体)。
  //    对应 Scala MiscResultSelect。
  // ===========================================================================
  // 逻辑第二操作数:andn/orn/xnor(func[0]=1 且 func[5]=0)时取反 src2。
  logic [XLEN-1:0] logic_src2;
  assign logic_src2 = ({XLEN{~func[5] & func[0]}}) ^ src2;

  // orcb:每字节内若有任一 bit 为 1,则该字节置全 1。逐字节并行。
  function automatic logic [XLEN-1:0] orc_b(logic [XLEN-1:0] x);
    logic [XLEN-1:0] r;
    for (int b = 0; b < XLEN/8; b++)
      r[b*8 +: 8] = {8{|x[b*8 +: 8]}};
    return r;
  endfunction

  // revb:每字节内部 bit 翻转(字节位置不变)。
  function automatic logic [XLEN-1:0] rev_b(logic [XLEN-1:0] x);
    logic [XLEN-1:0] r;
    for (int b = 0; b < XLEN/8; b++)
      for (int i = 0; i < 8; i++)
        r[b*8 + i] = x[b*8 + (7-i)];
    return r;
  endfunction

  // rev8:整字的字节序翻转(byte0<->byte7 ...)。
  function automatic logic [XLEN-1:0] rev_8(logic [XLEN-1:0] x);
    logic [XLEN-1:0] r;
    for (int b = 0; b < XLEN/8; b++)
      r[b*8 +: 8] = x[(XLEN/8-1-b)*8 +: 8];
    return r;
  endfunction

  function automatic logic [XLEN-1:0] misc_channel(
      logic [5:0] f, logic [XLEN-1:0] s1, logic [XLEN-1:0] s2,
      logic [XLEN-1:0] lsrc2);
    logic [XLEN-1:0] l_and, l_or, l_xor, l_orcb;
    logic [XLEN-1:0] logic_res;        // 4 选 1: and/or/xor/orcb
    logic [XLEN-1:0] ext_res;          // 4 选 1: sextb/packh/sexth/packw
    logic [XLEN-1:0] logic_base;       // func[3] 选 logic_res / ext_res
    logic [XLEN-1:0] rev_res, custom_res, logic_adv;
    logic [XLEN-1:0] mask, masked_logic;
    l_and  = s1 & lsrc2;
    l_or   = s1 | lsrc2;
    l_xor  = s1 ^ lsrc2;
    l_orcb = orc_b(s1);
    // func[2:1] 选基本逻辑;func[1:0] 选符号/打包扩展。
    unique case (f[2:1])
      2'd0: logic_res = l_and;
      2'd1: logic_res = l_or;
      2'd2: logic_res = l_xor;
      default: logic_res = l_orcb;
    endcase
    unique case (f[1:0])
      2'd0: ext_res = {{(XLEN-8){s1[7]}},  s1[7:0]};               // sextb
      2'd1: ext_res = {{(XLEN-16){1'b0}},  s2[7:0],  s1[7:0]};     // packh
      2'd2: ext_res = {{(XLEN-16){s1[15]}}, s1[15:0]};             // sexth
      default: ext_res = {{(XLEN-32){s2[15]}}, s2[15:0], s1[15:0]};// packw
    endcase
    logic_base = f[3] ? ext_res : logic_res;
    // func[4]=1 的高级杂项:revb/rev8/pack/orh48,或带 0/1/2/3 位左移的 szewl/byte2。
    unique case (f[1:0])
      2'd0: rev_res = rev_b(s1);
      2'd1: rev_res = rev_8(s1);
      2'd2: rev_res = {s2[31:0], s1[31:0]};                        // pack
      default: rev_res = {s1[63:8], 8'h0} | s2;                    // orh48
    endcase
    unique case (f[1:0])
      2'd0: custom_res = {31'h0, s1[31:0], 1'b0};                  // szewl1
      2'd1: custom_res = {30'h0, s1[31:0], 2'b0};                  // szewl2
      2'd2: custom_res = {29'h0, s1[31:0], 3'b0};                  // szewl3
      default: custom_res = {56'h0, s1[15:8]};                     // byte2
    endcase
    logic_adv = f[3] ? custom_res : rev_res;
    // func[5]=1 的 LSB/ZEXTH 变体(110xxxx):对基本逻辑结果加掩码,
    // func[0]=0 取 bit0(andlsb 等),func[0]=1 取低 16 位(andzexth 等)。
    mask         = {{15{f[0]}}, 1'b1};       // 顶层会零扩展到 64
    masked_logic = {{(XLEN-16){1'b0}}, mask} & logic_res;
    return f[5] ? masked_logic : (f[4] ? logic_adv : logic_base);
  endfunction

  // ===========================================================================
  // 3. 加法通道 addRes —— func[6:4]==010
  //    一个 64bit 加法器服务于 add/adduw/oddadd/lui32add/srNadd/shNadd 等多种
  //    变体,差别只在两个加数的预处理。对应 Scala AddModule + AluDataModule。
  // ===========================================================================
  // shadd 源:把(可 ZEXT 的)src1 左移 1..4 位,作为加数 0。
  function automatic logic [XLEN-1:0] shadd_src(logic [1:0] sh,
      logic [XLEN-1:0] masked_s1);
    // func[2:1]: 0->左移1, 1->左移2, 2->左移3, 3->左移4
    // 注意移位量用 3 位避免 2+2 位相加溢出回绕(3+1 在 2 位下会变 0)。
    return masked_s1 << ({1'b0, sh} + 3'd1);
  endfunction

  // srNadd 源:取 src1 高位段并 ZEXT(sr29add 取 [63:29] 等)。
  function automatic logic [XLEN-1:0] sradd_src(logic [1:0] sr,
      logic [XLEN-1:0] s1);
    unique case (sr)
      2'd0: return {29'h0, s1[63:29]}; // sr29add
      2'd1: return {30'h0, s1[63:30]}; // sr30add
      2'd2: return {31'h0, s1[63:31]}; // sr31add
      default: return {32'h0, s1[63:32]}; // sr32add
    endcase
  endfunction

  logic [XLEN-1:0] add_operand0;
  logic [XLEN-1:0] add_operand1;
  logic [XLEN-1:0] add_res;
  always_comb begin
    // 加数 0:四级优先(shadd > srNadd > odd/lui > 普通 ZEXT)。
    if (func[3])
      add_operand0 = shadd_src(func[2:1], left_shift_src);
    else if (func[2])
      add_operand0 = sradd_src(func[1:0], src1);
    else if (func[1])
      add_operand0 = func[0] ? {{(XLEN-12){src2[11]}}, src2[11:0]}  // lui32add: SEXT(src2[11:0])
                             : {{(XLEN-1){1'b0}}, src1[0]};         // oddadd: src1[0]
    else
      add_operand0 = left_shift_src;                                // add/adduw
    // 加数 1:lui32add(func[3:0]==0011) 用 {src2[63:12],12'b0},否则原 src2。
    add_operand1 = (func[3:0] == 4'b0011) ? {src2[63:12], 12'h0} : src2;
  end
  assign add_res = add_operand0 + add_operand1;

  // ===========================================================================
  // 4. 比较通道 compareRes —— func[6:4]==011
  //    基于一个带借位的减法器 sub = src1 + ~src2 + 1 (65 位)。
  //    sub[64] 是进位:无借位⇒src1>=src2(无符号)。据此派生 sltu/slt/max/min。
  //    对应 Scala SubModule + AluDataModule 的 compareRes。
  // ===========================================================================
  logic [XLEN:0]   sub_ext;   // 65 位:含进位
  logic            sltu, slt;
  logic [XLEN-1:0] compare_res;
  assign sub_ext = {1'b0, src1} + {1'b0, ~src2} + 65'd1;
  assign sltu    = ~sub_ext[XLEN];                       // 无进位 ⇒ 借位 ⇒ src1<src2
  assign slt     = src1[XLEN-1] ^ src2[XLEN-1] ^ sltu;  // 有符号比较修正
  always_comb begin
    logic [XLEN-1:0] max_min, max_min_u;
    // max/min:func[0] 区分 max(0)/min(1);选 src2 还是 src1。
    max_min   = (slt  ^ func[0]) ? src2 : src1;
    max_min_u = (sltu ^ func[0]) ? src2 : src1;
    unique case ({func[2], func[1]})
      2'b00: compare_res = func[0] ? {{(XLEN-1){1'b0}}, sltu} : sub_ext[XLEN-1:0]; // sltu / sub
      2'b01: compare_res = {{(XLEN-1){1'b0}}, slt};                                 // slt
      2'b10: compare_res = max_min_u;                                               // maxu/minu
      default: compare_res = max_min;                                               // max/min
    endcase
  end

  // ===========================================================================
  // 5. 字(32bit)通道 wordRes —— func[6:4]==001
  //    RV64 的 *W 指令:在低 32 位上算 add/sub/shift/rotate,结果 SEXT 到 64。
  //    对应 Scala WordResultSelect + 各 *WordModule。
  // ===========================================================================
  // addw 用的字加法器:srcw + 第二加数低 32 位。srcw 在 oddaddw/lui32addw 时
  // 特殊处理;第二加数复用 64bit 加法的 add_operand1(已处理 lui32addw 的
  // {src2[63:12],12'b0} 情形),取其低 32 位,与 golden AddModule 共用一致。
  logic [31:0] addw_srcw;
  logic [31:0] addw_raw;
  assign addw_srcw = (~func[2] & func[0])
                       ? (func[1] ? {{20{src2[11]}}, src2[11:0]}   // lui32addw: SEXT(src2[11:0])
                                  : {31'h0, src1[0]})              // oddaddw:   src1[0]
                       : src1[31:0];                                // addw
  assign addw_raw  = addw_srcw + add_operand1[31:0];

  function automatic logic [XLEN-1:0] word_channel(
      logic [6:0] f, logic [31:0] addw, logic [31:0] s1_lo,
      logic [31:0] sub_lo,
      logic [4:0] sh, logic [4:0] rsh, logic [31:0] ls_src_lo);
    logic [31:0] sllw, srlw, sraw, rolw, rorw, subw;
    logic [31:0] addw_var;     // func[2]=1 的字节/半字加法变体
    logic [31:0] addsub, shift_w, word;
    sllw   = ls_src_lo << sh;
    srlw   = s1_lo >> sh;
    sraw   = $signed(s1_lo) >>> sh;
    rolw   = (s1_lo >> rsh) | (ls_src_lo << sh);
    rorw   = (s1_lo >> sh)  | (ls_src_lo << rsh);
    subw   = sub_lo;
    // addwbit/byte/zexth/sexth:取加法结果不同位段。
    unique case (f[1:0])
      2'd0: addw_var = {31'h0, addw[0]};                  // addwbit
      2'd1: addw_var = {24'h0, addw[7:0]};                // addwbyte
      2'd2: addw_var = {16'h0, addw[15:0]};               // addwzexth
      default: addw_var = {{16{addw[15]}}, addw[15:0]};   // addwsexth
    endcase
    addsub  = (~f[2] & f[1] & ~f[0]) ? subw : (f[2] ? addw_var : addw);
    shift_w = f[2] ? (f[0] ? rorw : rolw)
                   : (f[1] ? sraw : (f[0] ? srlw : sllw));
    word    = f[3] ? shift_w : addsub;
    return {{(XLEN-32){word[31]}}, word};                 // SEXT 到 64
  endfunction

  // ===========================================================================
  // 6. Zicond 通道 condRes —— func[6:4]==111
  //    czero.eqz:src2==0?0:src1   czero.nez:src2!=0?0:src1。
  //    func[1] 选 eqz(0)/nez(1)。对应 Scala ConditionalZeroModule。
  // ===========================================================================
  logic [XLEN-1:0] cond_res;
  always_comb begin
    logic cond_is_zero, use_zero;
    cond_is_zero = (src2 == '0);
    use_zero     = (~func[1] &  cond_is_zero)    // eqz: 条件为 0 → 输出 0
                 | ( func[1] & ~cond_is_zero);   // nez: 条件非 0 → 输出 0
    cond_res     = use_zero ? '0 : src1;
  end

  // ===========================================================================
  // 7. 顶层通道选择 —— 由 func[6:4] 在 6 条通道间做 6 选 1。
  //    见 alu_pkg 的 alu_chan_e / Scala AluResSel。
  // ===========================================================================
  // 用 always_comb 调用各通道函数:这样敏感列表会自动包含函数内部读到的所有
  // 模块信号(shamt/rev_shamt/left_shift_src/bit_mask 等),避免仅靠显式实参
  // 触发求值而漏掉 src2 变化。
  logic [XLEN-1:0] shift_res, misc_res, word_res;
  always_comb shift_res = shift_channel(func[3:0], src1, shamt, rev_shamt,
                                        left_shift_src, bit_mask);
  always_comb misc_res  = misc_channel(func[5:0], src1, src2, logic_src2);
  always_comb word_res  = word_channel(func, addw_raw, src1[31:0], sub_ext[31:0],
                                       shamt[4:0], rev_shamt[4:0], left_shift_src[31:0]);

  always_comb begin
    unique case (alu_chan_e'(func[6:4]))
      CH_SHIFT:   result = shift_res;   // 000
      CH_WORD:    result = word_res;    // 001
      CH_ADD:     result = add_res;     // 010
      CH_COMPARE: result = compare_res; // 011
      CH_COND:    result = cond_res;    // 111
      default:    result = misc_res;    // 100/101/110 杂项通道
    endcase
  end

endmodule : xs_Alu_core
