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
