// =============================================================================
// DecodeUnitComp.sv —— 复杂指令译码单元：把一条向量/AMO-CAS 指令拆成多个 uop
// -----------------------------------------------------------------------------
// 设计源:XiangShan src/main/scala/xiangshan/backend/decode/DecodeUnitComp.scala
// golden 对照:G1-canonical/golden-rtl/DecodeUnitComp.sv
//             （45,149 行 / 748 端口 / 102 个寄存器 / 8 个子模块实例）
//
// ★ 它在流水线里的位置 ★
// 译码级 DecodeStage 前面有 6 个「简单译码器」DecodeUnit,每拍译 6 条。碰上
// **复杂指令**(一条要拆成多个 uop 的:向量算术/向量访存/vset/amocas)时,
// DecodeStage 把它交给本模块。本模块**一次只处理一条**复杂指令:
//   · in 握手时把整条 simpleDecodedInst 与 UopInfoGen 算好的 uopInfo 锁存下来;
//   · 组合逻辑按 uopSplitType 把它展开成 csBundle[0..64] 共最多 65 个 uop;
//   · 每拍按 Rename 的反压吐出最多 6 个(out.complexDecodedInsts(0..5)),
//     用 count 记「已经吐到第几组」。
//
// ★ 为什么 golden 有 45,149 行 ★（实测,见本文件头的规模表）
//   · 95.6% 的行(43,167 行)是 6,075 条 `wire … = 表达式;` —— firtool 把
//     「65 个 uop × 31 个逐 uop 变化的字段 × 43 种拆分方式 × vlmul/vsew 子分支」
//     整个展平成了每个字段一棵巨大的三元运算树;
//   · 其中 22 条 wire 就占掉一半行数,全是 `wire [15:0][W-1:0] _GEN_5xxx = {…}`,
//     即「某一路输出、某一个字段、16 组」的查找表(68 条这样的表);
//   · 真正的状态只有 102 个寄存器、2 个综合可见的 always 块
//     (另有 1 个 `ifndef SYNTHESIS` 下的断言块,本重写不含,见下)。
// 本重写把那棵树还原成它本来的样子:一个 `case (uopSplitType)`,每个分支照着
// Chisel 写 —— 本文件手写区约 2,300 行(1/20),机械生成区(端口表 + 结构体 +
// wrapper 接线)约 1,600 行,逻辑与 golden 逐位等价。
//
// ★本重写不含 golden 的那个断言★
// golden 有一条 `XSError(inValid && numOfUop === 0)`,firtool 把它放在
// `ifndef SYNTHESIS` 里。UT 与 FM 两侧都定义 SYNTHESIS,它不参与任何比对;
// 它也不是设计行为(断言不驱动任何输出)。**代价要说清楚**:
// docs/perf_bore_map.tsv 里有一条 ASSERT 探针指着 golden 的 _GEN_5323,
// 重写件里没有对应点 —— perf 重绑表因此会红,需要主集成者按台账口径处置。
//
// ★ 复位域（逐个数过 golden 的 always 块）★
//   · latchedInst_*（96 个）+ latchedUopInfo_*（3 个）= **99 个不带复位的寄存器**,
//     写使能 = `in_valid & in_ready`,golden 是一条 `always @(posedge clock)`,
//     里面**没有** reset 分支。照抄成「带复位」是真 bug,四道闸一个都不响。
//   · state / uopRes / count = **3 个异步高有效复位**寄存器,
//     golden 是 `always @(posedge clock or posedge reset)`,复位值**全 0**。
//   · 本模块没有任何非零复位值。
//
// ★ 更新优先级（同一状态被多源写）★
//   · 99 个锁存寄存器只有一个写源(in 握手),没有优先级问题。
//   · uopRes / count 的写源有三个,golden 的 if-else 链顺序是
//     `redirect` > `state(active) 且 thisAllOut` > `state(active) 且反压` >
//     `idle 且 in_valid`,本核逐字照抄这个顺序(见 §7)。
//   · csBundle 是组合量,优先级 = **Chisel 的赋值顺序,后写者胜**。SV 的
//     always_comb 过程赋值语义与它完全一致,所以本核按 Chisel 的书写顺序写,
//     不做任何重排。
//
// ★ golden 与 Chisel 字面不一致处（一律以 golden 为准）★
//   (a) DecodedInst 的 `lsrc` 是 Vec(5),golden 只剩 lsrc_0..2 三根端口。
//       Chisel 里两处 `csBundle(x).lsrc(4) := Vl_IDX.U`(VSET 与 VEC_US_FF_LD)
//       在 golden 里**完全不存在** —— 父模块把 lsrc_3/lsrc_4 驱成常数,firtool
//       整电路优化后把端口删了。本核照 golden 只建 3 根。
//   (b) 同理,`v0Wen` 在 golden 里没有端口(VEC_COMPRESS 里对它的赋值是死码),
//       `firstUop` 只有第 0 路输出有端口(其余 5 路恒 0,被删)。
//   (c) 有 8 个字段只有输出端口、没有输入端口(vlWen / uopIdx / firstUop /
//       lastUop / vlsInstr / vpu_fpu_isFoldTo1_{2,4,8})。它们的「锁存默认值」
//       因此是**常数 0**(父模块驱 0 被折进来),本核写死 0,不许凭空造输入端口。
//   (d) `isVset` 那个 Chisel 局部量在 VecExceptionGen 里没有读者,firtool 消掉了;
//       本工程的 VecExceptionGen 重写也没有它。
//
// ★ 子模块（golden 里 8 个实例，本核原样例化，不黑盒）★
//   · VecExceptionGen ×1        —— 向量非法指令判据(rtl/backend/VecExceptionGen.sv)
//   · indexedLSUopTable_1..7 ×7 —— 索引访存 uop 偏移表
//     (rtl/backend/xs_indexedLSUopTable_core.sv + 7 个薄文件)
//   golden 里没有 indexedLSUopTable_0:UOP_IDX=0 的输出恒 (0,0),被 firtool 删掉,
//   所以第 0 个 uop 的偏移在本核里也写成常数 0。
// =============================================================================
// 本文件导航（共 3935 行；按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   L21    设计源:XiangShan src/main/scala/xiangshan/backend/decode/DecodeUnit
//   L92    §1 decodeunitcomp_pkg —— 本模块私有的类型与编码常量
//   L307   §2 xs_DecodeUnitComp_core —— 可读核
//   L340   §3 输入修正与锁存
//   L342   vset 的操作码在进来之前要按 rd/rs1 是否为 x0 改两位：
//   L376   §4 从锁存指令派生出来的量
//   L378   寄存器号一律做成 6 位
//   L436   §5 子模块：非法指令判据 与 索引访存偏移表
//   L503   §5b 几个「每个分支自己的规模」——提成命名信号，别藏在 always_comb 里
//   L505   这几个量原本可以写成 always_comb 里的临时变量，但那样(a)读者要读进过程块才
//   L582   §6 csBundle —— 把一条指令展开成 65 个 uop
//   L584   这一整段是 golden 那 43,000 行的来源：下面 `case (split)` 的每个分支，firtool
//   L2298  §7 出口：修正、按路分组、状态机
//   L2300  Chisel 的 fixedDecodedInst：整体照抄 csBundle，只把**最后一个 uop** 的
//   L2392  §8 DecodeUnitComp —— golden 同名 wrapper
//

// -----------------------------------------------------------------------------
// §1 decodeunitcomp_pkg —— 本模块私有的类型与编码常量
// -----------------------------------------------------------------------------
package decodeunitcomp_pkg;

  // ---- 规模（KunminghuV2Config 实测） ----
  localparam int MAX_UOP    = 65;   // MaxUopSize：一条复杂指令最多拆 65 个 uop
  localparam int RENAME_W   = 6;    // RenameWidth：每拍最多吐 6 个
  localparam int MAX_VLMUL  = 8;    // LMUL 最大 8
  localparam int COUNT_W    = 4;    // log2Up(MAX_UOP/RENAME_W + 1) = log2Up(11)
  localparam int COUNT_N    = 1 << COUNT_W;   // 16：count 的完整取值空间

  // 临时向量寄存器区：v32..v46 用来放拆分过程中的中间结果（物理寄存器堆里有，
  // 架构上不可见）。Chisel 的 VECTOR_TMP_REG_LMUL。
  localparam logic [5:0] VTMP   = 6'd32;
  // vl 在向量寄存器编号空间里的位置（KunminghuV2Config 里 Vl_IDX = 0）
  localparam logic [5:0] VL_IDX = 6'd0;

  // ---- SrcType（4 位，one-hot-ish；imm / pc / no / DC 都是全 0） ----
  localparam logic [3:0] ST_IMM = 4'h0;
  localparam logic [3:0] ST_XP  = 4'h1;   // 整数寄存器（别名 reg）
  localparam logic [3:0] ST_FP  = 4'h2;
  localparam logic [3:0] ST_VP  = 4'h4;   // 向量寄存器

  // ---- FuType（35 位 one-hot，位号见 backend/fu/FuType.scala 的 addType 顺序） ----
  localparam logic [34:0] FU_I2V     = 35'd1 << 3;
  localparam logic [34:0] FU_F2V     = 35'd1 << 4;
  localparam logic [34:0] FU_VSETIWI = 35'd1 << 28;  // 读 rs 写 rd
  localparam logic [34:0] FU_VSETIWF = 35'd1 << 29;  // 读 rs 写 vconfig
  localparam logic [34:0] FU_VSETFWF = 35'd1 << 30;  // 读旧 vl 写 vconfig
  localparam int          FU_BIT_VSTU    = 32;
  localparam int          FU_BIT_VSEGSTU = 34;

  // ---- IF2VectorType：整数/浮点搬进向量的操作码高 3 位，低 2 位放 vsew ----
  localparam logic [2:0] IF2V_I2VEC      = 3'b000;
  localparam logic [2:0] IF2V_F2VEC      = 3'b001;
  localparam logic [2:0] IF2V_IMM2VEC    = 3'b010;
  localparam logic [2:0] IF2V_IDUP2VEC   = 3'b100;
  localparam logic [2:0] IF2V_FDUP2VEC   = 3'b101;
  localparam logic [2:0] IF2V_IMMDUP2VEC = 3'b110;
  localparam logic [1:0] E64             = 2'b11;   // Chisel 里的 `val e64`

  // ---- LSUOpType 的 amocas 三个操作码（高 3 位在拆分时另填） ----
  localparam logic [5:0] AMOCAS_W = 6'b101110;
  localparam logic [5:0] AMOCAS_D = 6'b101111;
  localparam logic [5:0] AMOCAS_Q = 6'b101100;

  // ---- VfaluType.vfwredosum：VEC_VFREDOSUM 分支靠它区分「加宽归约」 ----
  localparam logic [8:0] VFWREDOSUM = 9'h36;

  // ---- VSETOpType：只用到两个「改操作码」的位与两个判据位 ----
  localparam int VSET_SETVLMAX_BIT = 0;
  localparam int VSET_KEEPVL_BIT   = 1;
  localparam int VSET_ISVSETVL_BIT = 6;   // func(6)
  localparam int VSET_ISVSETVLI_BIT= 7;   // func(7)

  // ---- VSew / VLmul 编码 ----
  localparam logic [1:0] VSEW_E8 = 2'b00, VSEW_E16 = 2'b01,
                         VSEW_E32 = 2'b10, VSEW_E64 = 2'b11;
  localparam logic [2:0] VLMUL_M1 = 3'b000, VLMUL_M2 = 3'b001, VLMUL_M4 = 3'b010,
                         VLMUL_M8 = 3'b011, VLMUL_MF8 = 3'b101, VLMUL_MF4 = 3'b110,
                         VLMUL_MF2 = 3'b111;

  // ---- UopSplitType（6 位，见 xiangshan/package.scala 的 object UopSplitType） ----
  localparam logic [5:0]
    UST_SCA_SIM        = 6'h00, UST_VEC_MVNR       = 6'h04,
    UST_VSET           = 6'h11, UST_VEC_VVV        = 6'h12,
    UST_VEC_VXV        = 6'h13, UST_VEC_0XV        = 6'h14,
    UST_VEC_VVW        = 6'h15, UST_VEC_WVW        = 6'h16,
    UST_VEC_VXW        = 6'h17, UST_VEC_WXW        = 6'h18,
    UST_VEC_WVV        = 6'h19, UST_VEC_WXV        = 6'h1A,
    UST_VEC_EXT2       = 6'h1B, UST_VEC_EXT4       = 6'h1C,
    UST_VEC_EXT8       = 6'h1D, UST_VEC_VVM        = 6'h1E,
    UST_VEC_VXM        = 6'h1F, UST_VEC_SLIDE1UP   = 6'h20,
    UST_VEC_FSLIDE1UP  = 6'h21, UST_VEC_SLIDE1DOWN = 6'h22,
    UST_VEC_FSLIDE1DN  = 6'h23, UST_VEC_VRED       = 6'h24,
    UST_VEC_SLIDEUP    = 6'h25, UST_VEC_SLIDEDOWN  = 6'h27,
    UST_VEC_M0X        = 6'h29, UST_VEC_MVV        = 6'h2A,
    UST_VEC_VWW        = 6'h2C, UST_VEC_RGATHER    = 6'h2D,
    UST_VEC_RGATHER_VX = 6'h2E, UST_VEC_RGATHEREI16= 6'h2F,
    UST_VEC_COMPRESS   = 6'h30, UST_VEC_US_LDST    = 6'h31,
    UST_VEC_S_LDST     = 6'h32, UST_VEC_I_LDST     = 6'h33,
    UST_VEC_US_FF_LD   = 6'h34, UST_AMO_CAS_W      = 6'h35,
    UST_AMO_CAS_D      = 6'h36, UST_AMO_CAS_Q      = 6'h37,
    UST_VEC_VFV        = 6'h38, UST_VEC_VFW        = 6'h39,
    UST_VEC_WFW        = 6'h3A, UST_VEC_VFM        = 6'h3B,
    UST_VEC_VFRED      = 6'h3C, UST_VEC_VFREDOSUM  = 6'h3D;

  // ---- vtype 旁路（从 VTypeGen 直接送来的「本拍刚算出来的」vtype） ----
  typedef struct packed {
    logic       illegal;
    logic       vma;
    logic       vta;
    logic [1:0] vsew;
    logic [2:0] vlmul;
  } vtype_t;

  // ---- UopInfoGen 算好的拆分规模 ----
  typedef struct packed {
    logic [6:0] numOfUop;   // 本指令一共拆几个 uop
    logic [6:0] numOfWB;    // 其中几个会写回
    logic [3:0] lmul;       // 本指令的 LMUL（已解码成 1/2/4/8 这样的数值）
  } uop_info_t;

  // BEGIN GENERATED(struct)
  // 下面这一段由 verif/ut/DecodeUnitComp/gen.py 从 golden 的
  // io_in_bits_simpleDecodedInst_* 端口表机械生成，成员名与 golden 逐字同名
  // （便于与 golden 对照），位宽也取自 golden。不要手改。
  typedef struct packed {
    logic [31:0]        instr;
    logic [49:0]        pc;
    logic [9:0]         foldpc;
    logic [23:0]          exceptionVec;
    logic               isFetchMalAddr;
    logic [3:0]         trigger;
    logic               preDecodeInfo_valid;
    logic               preDecodeInfo_isRVC;
    logic [1:0]         preDecodeInfo_brType;
    logic               preDecodeInfo_isCall;
    logic               preDecodeInfo_isRet;
    logic               pred_taken;
    logic               crossPageIPFFix;
    logic               ftqPtr_flag;
    logic [5:0]         ftqPtr_value;
    logic [3:0]         ftqOffset;
    logic               satpFlushFirstFetchFault;
    logic [4:0][3:0]    srcType;
    logic [2:0][5:0]    lsrc;
    logic [5:0]         ldest;
    logic [34:0]        fuType;
    logic [8:0]         fuOpType;
    logic               rfWen;
    logic               fpWen;
    logic               vecWen;
    logic               isXSTrap;
    logic               waitForward;
    logic               blockBackward;
    logic               flushPipe;
    logic               canRobCompress;
    logic [3:0]         selImm;
    logic [21:0]        imm;
    logic [1:0]         fpu_typeTagOut;
    logic               fpu_wflags;
    logic [1:0]         fpu_typ;
    logic [1:0]         fpu_fmt;
    logic [2:0]         fpu_rm;
    logic               vpu_vill;
    logic               vpu_vma;
    logic               vpu_vta;
    logic [1:0]         vpu_vsew;
    logic [2:0]         vpu_vlmul;
    logic               vpu_specVill;
    logic               vpu_specVma;
    logic               vpu_specVta;
    logic [1:0]         vpu_specVsew;
    logic [2:0]         vpu_specVlmul;
    logic               vpu_vm;
    logic [7:0]         vpu_vstart;
    logic [2:0]         vpu_nf;
    logic [1:0]         vpu_veew;
    logic               vpu_isReverse;
    logic               vpu_isExt;
    logic               vpu_isNarrow;
    logic               vpu_isDstMask;
    logic               vpu_isOpMask;
    logic               vpu_isDependOldVd;
    logic               vpu_isWritePartVd;
    logic               vpu_isVleff;
    logic               wfflags;
    logic               isMove;
    logic [5:0]         uopSplitType;
    logic               isVset;
    logic [2:0]         commitType;
    logic [34:0]        debug_fuType;
    logic [55:0]        debug_seqNum_seqNum;
    logic [7:0]         debug_seqNum_uopIdx;
  } static_inst_t;
  // END GENERATED

  // BEGIN GENERATED(varstruct)
  // uop_var_t —— 逐 uop 变化的 31 个字段（其余 75 个字段整条指令共用，走
  // latched 直通）。这 31 个是从 golden 现场分类出来的：只有它们的输出
  // assign 形如 `_GEN_xxxx[count]`。
  typedef struct packed {
    logic [4:0][3:0]    srcType;   // 五个源操作数的类型(imm/xp/fp/vp)
    logic [2:0][5:0]    lsrc;   // 三个源逻辑寄存器号
    logic [5:0]         ldest;   // 目的逻辑寄存器号
    logic [34:0]        fuType;   // 功能单元 one-hot
    logic [8:0]         fuOpType;   // 功能单元内的操作码
    logic               rfWen;   // 写整数寄存器堆
    logic               fpWen;   // 写浮点寄存器堆
    logic               vecWen;   // 写向量寄存器堆
    logic               vlWen;   // 写 vl
    logic               waitForward;   // 等前面全部完成才发射
    logic               blockBackward;   // 挡住后面的指令
    logic               flushPipe;   // 提交时冲刷流水
    logic               vpu_vill;   // vtype.vill
    logic               vpu_vma;   // vtype.vma
    logic               vpu_vta;   // vtype.vta
    logic [1:0]         vpu_vsew;   // vtype.vsew
    logic [2:0]         vpu_vlmul;   // vtype.vlmul
    logic               vpu_fpu_isFoldTo1_2;   // 浮点归约折半
    logic               vpu_fpu_isFoldTo1_4;   // 浮点归约折四分之一
    logic               vpu_fpu_isFoldTo1_8;   // 浮点归约折八分之一
    logic               vpu_isReverse;   // 源操作数换位
    logic               vlsInstr;   // 属于向量访存指令
    logic [6:0]         uopIdx;   // 本 uop 在拆分序列里的序号
    logic               firstUop;   // 序列第一个
    logic               lastUop;   // 序列最后一个
  } uop_var_t;
  // END GENERATED

endpackage : decodeunitcomp_pkg


// =============================================================================
// §2 xs_DecodeUnitComp_core —— 可读核
// =============================================================================
module xs_DecodeUnitComp_core
  import decodeunitcomp_pkg::*;
(
  input  logic           clock,
  input  logic           reset,          // 异步高有效，只复位 3 个状态机寄存器
  input  logic           redirect,       // 后端冲刷：丢掉正在拆的这条指令
  input  vtype_t         vtype_bypass,   // VTypeGen 本拍算出的 vtype（只有 VSET 用）

  input  logic           in_valid,
  output logic           in_ready,
  input  static_inst_t   in_inst,        // 简单译码器给出的整条 DecodedInst
  input  uop_info_t      in_uop_info,    // UopInfoGen 给出的拆分规模

  // golden 里只有第 0 路有 ready 端口：Chisel 的 readyCounter 只看 head，
  // 其余 5 路的 ready 没有任何读者，被 firtool 删掉了。
  input  logic           out0_ready,

  output logic [5:0]     out_valid,
  output logic [2:0]     complex_num,    // 本拍吐了几个（idle 时报 0）

  // 整条指令共用的直通字段（75 个），6 路输出共享同一份
  output static_inst_t   latched,
  output logic [6:0]     latched_num_of_uop,
  output logic [6:0]     latched_num_of_wb,
  output logic           exception_ii,   // exceptionVec(EX_II)，全部 uop 同值

  // 逐 uop 变化的 31 个字段，每路一份
  output uop_var_t [5:0] out_var
);

  // ---------------------------------------------------------------------------
  // §3 输入修正与锁存
  // ---------------------------------------------------------------------------
  // vset 的操作码在进来之前要按 rd/rs1 是否为 x0 改两位：
  //   rd==0 且 rs1==0 → keepVl  （不改 vl，只改 vtype）
  //   rs1==0          → setVlmax（vl 置为 vlmax）
  // Chisel 写成 `when(io.in.fire && isVset)`，而 fire 与锁存使能是同一个条件，
  // golden 照样把这个条件展开进了锁存值里，这里也照抄（不化简）。
  logic [4:0] in_rd, in_rs1;
  assign in_rd  = in_inst.instr[11:7];
  assign in_rs1 = in_inst.instr[19:15];

  static_inst_t in_fixed;
  always_comb begin
    in_fixed = in_inst;
    if (in_valid && in_ready && in_inst.isVset) begin
      if (in_rd == 5'h0 && in_rs1 == 5'h0)
        in_fixed.fuOpType = in_inst.fuOpType | (9'd1 << VSET_KEEPVL_BIT);
      else if (in_rs1 == 5'h0)
        in_fixed.fuOpType = in_inst.fuOpType | (9'd1 << VSET_SETVLMAX_BIT);
    end
  end

  // ★99 个锁存寄存器：无复位★（golden 是一条不带 reset 分支的 always @(posedge)）
  static_inst_t latched_q;
  uop_info_t    latched_uop_info_q;
  always_ff @(posedge clock) begin
    if (in_valid && in_ready) begin
      latched_q          <= in_fixed;
      latched_uop_info_q <= in_uop_info;
    end
  end
  assign latched            = latched_q;
  assign latched_num_of_uop = latched_uop_info_q.numOfUop;
  assign latched_num_of_wb  = latched_uop_info_q.numOfWB;

  // ---------------------------------------------------------------------------
  // §4 从锁存指令派生出来的量
  // ---------------------------------------------------------------------------
  // 寄存器号一律做成 6 位（DecodedInst 的逻辑寄存器号是 6 位：32 个整数/浮点
  // 寄存器 + 32 个向量寄存器共用编号空间，临时区 v32.. 也落在这 6 位里）。
  logic [5:0] src1, src2, vdst;
  assign src1 = {1'b0, latched_q.instr[19:15]};
  assign src2 = {1'b0, latched_q.instr[24:20]};
  assign vdst = {1'b0, latched_q.instr[11:7]};

  logic [2:0] nf;        // NF：段访存的 field 数减一
  logic [1:0] width;     // WIDTH(1,0)：访存 EEW 编码
  logic [1:0] mop;       // MOP：访存寻址模式
  logic [4:0] lumop;     // LUMOP：unit-stride 的子类型
  assign nf    = latched_q.instr[31:29];
  assign width = latched_q.instr[13:12];
  assign mop   = latched_q.instr[27:26];
  assign lumop = latched_q.instr[24:20];

  logic [6:0] num_of_uop;
  logic [3:0] lmul;
  logic [2:0] vlmul_r;
  logic [1:0] vsew_r;
  logic [7:0] vstart_r;
  logic [5:0] split;
  assign num_of_uop = latched_uop_info_q.numOfUop;
  assign lmul       = latched_uop_info_q.lmul;
  assign vlmul_r    = latched_q.vpu_vlmul;
  assign vsew_r     = latched_q.vpu_vsew;
  assign vstart_r   = latched_q.vpu_vstart;
  assign split      = latched_q.uopSplitType;

  // 最后一个 uop 的下标。num_of_uop 是 7 位，可能大于 65（非法输入），
  // 所以下面所有「写最后一个 uop」的地方都写成「逐项比较下标」而不是数组动态
  // 索引写 —— 越界时 Chisel 的语义是**什么都不写**，逐项比较天然就是这个语义，
  // 而 SV 的动态索引越界写是「实现定义」，FM 也不做范围传播。
  logic [6:0] last_uop_idx;
  assign last_uop_idx = num_of_uop - 7'd1;

  logic src1_is_imm, src1_is_fp, is_vstore;
  assign src1_is_imm = (latched_q.srcType[0] == ST_IMM);
  assign src1_is_fp  = (latched_q.srcType[0] == ST_FP);
  assign is_vstore   = latched_q.fuType[FU_BIT_VSTU] | latched_q.fuType[FU_BIT_VSEGSTU];

  // 三种「段访存」：它们要把整条指令做成不可打断的一段（waitForward/blockBackward）
  logic is_us_segment, is_ix_segment, is_sd_segment;
  assign is_us_segment = (mop == 2'b00)
                       && (((nf != 3'h0) && (lumop == 5'h00)) || (lumop == 5'h10));
  assign is_ix_segment = mop[0] && (nf != 3'h0);
  assign is_sd_segment = (mop == 2'b10) && (nf != 3'h0);

  // VSET 的三个判据（VSETOpType 的位定义）
  logic is_vsetvl, is_vsetvli;
  assign is_vsetvl  = latched_q.fuOpType[VSET_ISVSETVL_BIT];
  assign is_vsetvli = latched_q.fuOpType[VSET_ISVSETVLI_BIT];

  // VEC_VFREDOSUM 里区分「加宽归约 vfwredosum」与普通有序归约
  logic is_widen_ordered_red;
  assign is_widen_ordered_red = (latched_q.fuOpType == VFWREDOSUM);

  // ---------------------------------------------------------------------------
  // §5 子模块：非法指令判据 与 索引访存偏移表
  // ---------------------------------------------------------------------------
  logic illegal_inst;
  VecExceptionGen vecException (
    .io_inst                  (latched_q.instr),
    .io_decodedInst_srcType_0 (latched_q.srcType[0]),
    .io_decodedInst_srcType_1 (latched_q.srcType[1]),
    .io_decodedInst_srcType_2 (latched_q.srcType[2]),
    .io_decodedInst_fuType    (latched_q.fuType),
    .io_decodedInst_vecWen    (latched_q.vecWen),
    .io_vtype_illegal         (latched_q.vpu_vill),
    .io_vtype_vsew            (latched_q.vpu_vsew),
    .io_vtype_vlmul           (latched_q.vpu_vlmul),
    .io_vstart                (latched_q.vpu_vstart),
    .io_illegalInst           (illegal_inst)
  );

  // 索引访存：EMUL 与 LMUL 不等时，第 i 个 uop 读 vs2 的第几个、写 vd 的第几个。
  // 8 个 uop 位置各一张表；第 0 个恒 (0,0)（golden 里连模块带实例一起被删掉了）。
  logic [3:0] simple_lmul_sel;   // {simple_emul, simple_lmul}
  logic [2:0] idx_off_vs2 [MAX_VLMUL];
  logic [2:0] idx_off_vd  [MAX_VLMUL];
  assign idx_off_vs2[0] = 3'd0;
  assign idx_off_vd [0] = 3'd0;
  indexedLSUopTable_1 indexedLSRegOffset_1 (.src(simple_lmul_sel),
      .outOffsetVs2(idx_off_vs2[1]), .outOffsetVd(idx_off_vd[1]));
  indexedLSUopTable_2 indexedLSRegOffset_2 (.src(simple_lmul_sel),
      .outOffsetVs2(idx_off_vs2[2]), .outOffsetVd(idx_off_vd[2]));
  indexedLSUopTable_3 indexedLSRegOffset_3 (.src(simple_lmul_sel),
      .outOffsetVs2(idx_off_vs2[3]), .outOffsetVd(idx_off_vd[3]));
  indexedLSUopTable_4 indexedLSRegOffset_4 (.src(simple_lmul_sel),
      .outOffsetVs2(idx_off_vs2[4]), .outOffsetVd(idx_off_vd[4]));
  indexedLSUopTable_5 indexedLSRegOffset_5 (.src(simple_lmul_sel),
      .outOffsetVs2(idx_off_vs2[5]), .outOffsetVd(idx_off_vd[5]));
  indexedLSUopTable_6 indexedLSRegOffset_6 (.src(simple_lmul_sel),
      .outOffsetVs2(idx_off_vs2[6]), .outOffsetVd(idx_off_vd[6]));
  indexedLSUopTable_7 indexedLSRegOffset_7 (.src(simple_lmul_sel),
      .outOffsetVs2(idx_off_vs2[7]), .outOffsetVd(idx_off_vd[7]));

  // 索引访存的 EMUL = EEW + 1 + LMUL - SEW（全是以 2 为底的对数，所以加减即可）。
  // simple_lmul / simple_emul 把 3 位编码压成 2 位（只有 1/2/4/8 四档有意义，
  // 分数倍数一律当 1 处理）—— Chisel 的 MuxLookup，不命中取 0。
  // ★位宽：vemul 是 3 位★ —— Chisel 的 `+` 取两侧最大位宽，veew/vlmul/vsew 都是
  // 3 位，所以整条式子在 3 位上做模运算，不进位到第 4 位。写宽一位就不是 golden 了。
  logic [2:0] vemul_raw;
  logic [1:0] simple_lmul, simple_emul;
  assign vemul_raw = ({1'b0, width} + vlmul_r) + (~{1'b0, vsew_r} + 3'd1);
  always_comb begin
    case (vlmul_r)
      3'b001:  simple_lmul = 2'd1;
      3'b010:  simple_lmul = 2'd2;
      3'b011:  simple_lmul = 2'd3;
      default: simple_lmul = 2'd0;   // 分数 LMUL 与 m1 一律当 1 组寄存器
    endcase
    case (vemul_raw)
      3'b001:  simple_emul = 2'd1;
      3'b010:  simple_emul = 2'd2;
      3'b011:  simple_emul = 2'd3;
      default: simple_emul = 2'd0;
    endcase
  end
  // 这 7 张表只在 VEC_I_LDST 且非段访存（nf==0）时才被喂真值；其余情况下 Chisel
  // 的 `indexedLSRegOffset.map(_.src := 0.U)` 默认值有效，golden 也是这么折的。
  assign simple_lmul_sel = (split == UST_VEC_I_LDST && nf == 3'h0)
                         ? {simple_emul, simple_lmul} : 4'h0;

  // ---------------------------------------------------------------------------
  // §5b 几个「每个分支自己的规模」——提成命名信号，别藏在 always_comb 里
  // ---------------------------------------------------------------------------
  // 这几个量原本可以写成 always_comb 里的临时变量，但那样(a)读者要读进过程块才
  // 知道它们是什么,(b)FM 对过程块里的 automatic 变量比对综合器挑剔。提出来之后
  // 每个都有名字、有注释、有位宽,而且全是纯组合。

  // vfredosum（有序浮点归约）的 uop 总数 = LMUL 覆盖的寄存器数 × 每个寄存器折几次
  // （e64 折 2、e32 折 4、e16 折 8）。不足 2 个 uop 的组合 Chisel 里根本没有分支，记 0。
  logic [6:0] vfredosum_len;
  always_comb begin
    vfredosum_len = 7'd0;
    case (vsew_r)
      VSEW_E64: case (vlmul_r)
                  VLMUL_M8:  vfredosum_len = 7'd16;
                  VLMUL_M4:  vfredosum_len = 7'd8;
                  VLMUL_M2:  vfredosum_len = 7'd4;
                  VLMUL_M1:  vfredosum_len = 7'd2;
                  default:   vfredosum_len = 7'd0;
                endcase
      VSEW_E32: case (vlmul_r)
                  VLMUL_M8:  vfredosum_len = 7'd32;
                  VLMUL_M4:  vfredosum_len = 7'd16;
                  VLMUL_M2:  vfredosum_len = 7'd8;
                  VLMUL_M1:  vfredosum_len = 7'd4;
                  VLMUL_MF2: vfredosum_len = 7'd2;
                  default:   vfredosum_len = 7'd0;
                endcase
      VSEW_E16: case (vlmul_r)
                  VLMUL_M8:  vfredosum_len = 7'd64;
                  VLMUL_M4:  vfredosum_len = 7'd32;
                  VLMUL_M2:  vfredosum_len = 7'd16;
                  VLMUL_M1:  vfredosum_len = 7'd8;
                  VLMUL_MF2: vfredosum_len = 7'd4;
                  VLMUL_MF4: vfredosum_len = 7'd2;
                  default:   vfredosum_len = 7'd0;
                endcase
      default: vfredosum_len = 7'd0;   // e8：Chisel 无对应分支
    endcase
  end

  // vcompress 的「组数」= LMUL 覆盖的寄存器数（LMUL≤1 时 Chisel 没有分支，记 0）
  logic [3:0] compress_len;
  always_comb begin
    case (vlmul_r)
      VLMUL_M2: compress_len = 4'd2;
      VLMUL_M4: compress_len = 4'd4;
      VLMUL_M8: compress_len = 4'd8;
      default:  compress_len = 4'd0;
    endcase
  end

  // 段索引访存：数据侧一共占几个向量寄存器 = lmul × (nf+1)。
  // Chisel 把合法组合逐个列出来（其余组合什么都不生成），这里照抄那张表。
  logic [3:0] seg_data_regs;
  always_comb begin
    seg_data_regs = 4'd0;
    case (simple_lmul)
      2'd0: case (nf)
              3'd1: seg_data_regs = 4'd2;  3'd2: seg_data_regs = 4'd3;
              3'd3: seg_data_regs = 4'd4;  3'd4: seg_data_regs = 4'd5;
              3'd5: seg_data_regs = 4'd6;  3'd6: seg_data_regs = 4'd7;
              3'd7: seg_data_regs = 4'd8;  default: seg_data_regs = 4'd0;
            endcase
      2'd1: case (nf)
              3'd1: seg_data_regs = 4'd4;  3'd2: seg_data_regs = 4'd6;
              3'd3: seg_data_regs = 4'd8;  default: seg_data_regs = 4'd0;
            endcase
      2'd2: case (nf)
              3'd1: seg_data_regs = 4'd8;  default: seg_data_regs = 4'd0;
            endcase
      default: seg_data_regs = 4'd0;
    endcase
  end

  // 段索引访存：下标侧占几个向量寄存器 = 2^simple_emul
  logic [3:0] seg_index_regs;
  assign seg_index_regs = 4'd1 << simple_emul;

  // ---------------------------------------------------------------------------
  // §6 csBundle —— 把一条指令展开成 65 个 uop
  // ---------------------------------------------------------------------------
  // 这一整段是 golden 那 43,000 行的来源：下面 `case (split)` 的每个分支，firtool
  // 都要为 65 个 uop × 31 个字段各展开一棵三元树。这里按 Chisel 的原样写。
  //
  // ★语义要点：后写者胜★
  // Chisel 的 `:=` 与 SV always_comb 的过程赋值都是「同一目标后写覆盖先写」。
  // 所以下面的顺序**不能重排**：先全体填默认值，再打 firstUop/lastUop/
  // blockBackward/flushPipe，最后才进 case —— case 里写到的字段会盖掉前面的。
  //
  // ★「写最后一个 uop」为什么写成循环比较★
  // Chisel 的 `csBundle(numOfUop - 1.U) := x` 在下标越界时**什么都不写**。
  // num_of_uop 是 7 位、可以大于 65（上游给非法值时），所以这里一律写成
  // `for (i) if (i == last_uop_idx)`，天然就是那个语义；写成 SV 动态索引写则
  // 越界行为是实现定义的，FM 也不做范围传播。
  uop_var_t cs [MAX_UOP];

  always_comb begin
    // ---- 默认：每个 uop 都是「原指令」的副本 ----
    for (int i = 0; i < MAX_UOP; i++) begin
      cs[i].srcType             = latched_q.srcType;
      cs[i].lsrc                = latched_q.lsrc;
      cs[i].ldest               = latched_q.ldest;
      cs[i].fuType              = latched_q.fuType;
      cs[i].fuOpType            = latched_q.fuOpType;
      cs[i].rfWen               = latched_q.rfWen;
      cs[i].fpWen               = latched_q.fpWen;
      cs[i].vecWen              = latched_q.vecWen;
      cs[i].waitForward         = latched_q.waitForward;
      cs[i].blockBackward       = latched_q.blockBackward;
      cs[i].flushPipe           = latched_q.flushPipe;
      cs[i].vpu_vill            = latched_q.vpu_vill;
      cs[i].vpu_vma             = latched_q.vpu_vma;
      cs[i].vpu_vta             = latched_q.vpu_vta;
      cs[i].vpu_vsew            = latched_q.vpu_vsew;
      cs[i].vpu_vlmul           = latched_q.vpu_vlmul;
      cs[i].vpu_isReverse       = latched_q.vpu_isReverse;
      // ★下面五组没有输入端口：父模块把它们驱成常数 0，firtool 把端口删了。
      //   所以「原指令的副本」在这几个字段上就是常数 0（见文件头 (c)）。
      cs[i].vlWen               = 1'b0;
      cs[i].uopIdx              = 7'd0;
      cs[i].vpu_fpu_isFoldTo1_2 = 1'b0;
      cs[i].vpu_fpu_isFoldTo1_4 = 1'b0;
      cs[i].vpu_fpu_isFoldTo1_8 = 1'b0;
      // 这三个是 Chisel 里显式写死的默认值
      cs[i].firstUop            = 1'b0;
      cs[i].lastUop             = 1'b0;
      cs[i].vlsInstr            = 1'b0;
    end

    // ---- 序列首尾标记 + vstart≠0 时的流水控制 ----
    cs[0].firstUop  = 1'b1;
    cs[0].flushPipe = (vstart_r != 8'd0);
    for (int i = 0; i < MAX_UOP; i++) begin
      if (7'(i) == last_uop_idx) begin
        cs[i].lastUop       = 1'b1;
        // vstart≠0 时最后一个 uop 要把 vstart 清零，所以它必须挡住后面的指令
        cs[i].blockBackward = (vstart_r != 8'd0);
      end
    end

    // ---- 按拆分方式展开 ----
    case (split)

      // ===== AMO-CAS：把一条 amocas 拆成 2 个（w/d）或 4 个（q）uop =====
      // 每个 uop 搬一个 64 位寄存器对的一半；uop0 要 waitForward（等前面清空），
      // 最后一个要 blockBackward（挡住后面），中间的两头都放开。
      UST_AMO_CAS_W: begin
        cs[0].uopIdx        = 7'd0;
        cs[0].fuOpType      = {3'd1, AMOCAS_W};
        cs[0].lsrc[0]       = 6'd0;
        cs[0].lsrc[1]       = src2;
        cs[0].rfWen         = 1'b0;
        cs[0].waitForward   = 1'b1;
        cs[0].blockBackward = 1'b0;
        cs[0].flushPipe     = 1'b0;

        cs[1].uopIdx        = 7'd1;
        cs[1].fuOpType      = {3'd0, AMOCAS_W};
        cs[1].lsrc[0]       = src1;
        cs[1].lsrc[1]       = vdst;
        cs[1].waitForward   = 1'b0;
        cs[1].blockBackward = 1'b1;
      end

      UST_AMO_CAS_D: begin
        cs[0].uopIdx        = 7'd0;
        cs[0].fuOpType      = {3'd1, AMOCAS_D};
        cs[0].lsrc[0]       = 6'd0;
        cs[0].lsrc[1]       = src2;
        cs[0].rfWen         = 1'b0;
        cs[0].waitForward   = 1'b1;
        cs[0].blockBackward = 1'b0;
        cs[0].flushPipe     = 1'b0;

        cs[1].uopIdx        = 7'd1;
        cs[1].fuOpType      = {3'd0, AMOCAS_D};
        cs[1].lsrc[0]       = src1;
        cs[1].lsrc[1]       = vdst;
        cs[1].waitForward   = 1'b0;
        cs[1].blockBackward = 1'b1;
      end

      UST_AMO_CAS_Q: begin
        cs[0].uopIdx        = 7'd0;
        cs[0].fuOpType      = {3'd1, AMOCAS_Q};
        cs[0].lsrc[0]       = 6'd0;
        cs[0].lsrc[1]       = src2;
        cs[0].rfWen         = 1'b0;
        cs[0].waitForward   = 1'b1;
        cs[0].blockBackward = 1'b0;
        cs[0].flushPipe     = 1'b0;

        cs[1].uopIdx        = 7'd1;
        cs[1].fuOpType      = {3'd0, AMOCAS_Q};
        cs[1].lsrc[0]       = src1;
        cs[1].lsrc[1]       = vdst;
        cs[1].waitForward   = 1'b0;
        cs[1].blockBackward = 1'b0;

        cs[2].uopIdx        = 7'd2;
        cs[2].fuOpType      = {3'd3, AMOCAS_Q};
        cs[2].lsrc[0]       = 6'd0;
        // rs2 是寄存器对的低号，对 x0 特判（x0+1 不是合法的对）
        cs[2].lsrc[1]       = (src2 == 6'd0) ? 6'd0 : (src2 + 6'd1);
        cs[2].rfWen         = 1'b0;
        cs[2].waitForward   = 1'b0;
        cs[2].blockBackward = 1'b0;

        cs[3].uopIdx        = 7'd3;
        cs[3].fuOpType      = {3'd2, AMOCAS_Q};
        cs[3].lsrc[0]       = 6'd0;
        cs[3].lsrc[1]       = (vdst == 6'd0) ? 6'd0 : (vdst + 6'd1);
        cs[3].ldest         = (vdst == 6'd0) ? 6'd0 : (vdst + 6'd1);
        cs[3].waitForward   = 1'b0;
        cs[3].blockBackward = 1'b1;
      end

      // ===== VSET：一条 vset* 拆成两个 uop（一个写 rd、一个写 vl/vtype）=====
      // 四条子路径按 (是 vsetvli/vsetvl) × (rd 是否 x0) × (rs1 是否 x0) 分。
      // 简单译码器不设 rfWen/vecWen，所以这里全靠本模块补。
      UST_VSET: begin
        if (latched_q.isVset) begin
          // 默认：uop0 写 rd（vsetiwi，永不 flushPipe）；uop1 写 vl（vsetvl 才挡后）
          cs[0].fuType        = FU_VSETIWI;
          cs[0].flushPipe     = is_vsetvl ? 1'b1 : (vstart_r != 8'd0);
          cs[0].blockBackward = 1'b0;
          cs[0].rfWen         = 1'b1;
          cs[1].ldest         = VL_IDX;
          cs[1].vecWen        = 1'b0;
          cs[1].vlWen         = 1'b1;
          cs[1].flushPipe     = 1'b0;
          cs[1].blockBackward = is_vsetvl ? 1'b1 : (vstart_r != 8'd0);

          if (is_vsetvli && vdst == 6'd0 && src1 == 6'd0) begin
            // vsetvli x0, x0, vtypei —— 什么都不写，uop0 退化成 nop，
            // uop1 从旧 vl 读、写回 vconfig（vsetfwf）。
            cs[0].rfWen      = 1'b0;
            cs[0].fpWen      = 1'b0;
            cs[0].vecWen     = 1'b0;
            cs[0].vlWen      = 1'b0;
            cs[1].fuType     = FU_VSETFWF;
            cs[1].srcType[0] = ST_IMM;   // SrcType.no 与 imm 同为全 0
            cs[1].srcType[2] = ST_IMM;
            cs[1].srcType[3] = ST_IMM;
            cs[1].srcType[4] = ST_VP;
            // ★Chisel 这里还有一句 `csBundle(1).lsrc(4) := Vl_IDX.U`，
            //   而 golden 的 lsrc 只有 0..2 三根线（见文件头 (a)），所以这句
            //   在 golden 里不存在，本核也不写。
          end else if (is_vsetvl && vdst == 6'd0 && src1 == 6'd0) begin
            // vsetvl x0, x0, rs2 —— 先把 rs2（新 vtype）搬进向量临时区，
            // 再由 uop1 拿「旧 vl + 新 vtype」写回 vconfig。
            cs[0].srcType[0] = ST_XP;
            cs[0].srcType[1] = ST_IMM;
            cs[0].lsrc[0]    = src2;
            cs[0].lsrc[1]    = 6'd0;
            cs[0].ldest      = VTMP;
            cs[0].fuType     = FU_I2V;
            cs[0].fuOpType   = {4'd0, IF2V_I2VEC, E64};
            cs[0].rfWen      = 1'b0;
            cs[0].fpWen      = 1'b0;
            cs[0].vecWen     = 1'b1;
            cs[0].vlWen      = 1'b0;

            cs[1].fuType     = FU_VSETFWF;
            cs[1].srcType[0] = ST_IMM;
            cs[1].srcType[2] = ST_IMM;
            cs[1].srcType[3] = ST_IMM;
            cs[1].srcType[4] = ST_VP;
            cs[1].srcType[1] = ST_VP;
            cs[1].lsrc[1]    = VTMP;
            cs[1].vecWen     = 1'b0;
            cs[1].vlWen      = 1'b1;
            cs[1].ldest      = VL_IDX;
          end else if (vdst == 6'd0) begin
            // rd 是 x0：uop0 不写任何寄存器堆
            cs[0].rfWen  = 1'b0;
            cs[0].fpWen  = 1'b0;
            cs[0].vecWen = 1'b0;
            cs[0].vlWen  = 1'b0;
          end else if (is_vsetvl) begin
            // vsetvl 的 rs2 可能就是 rd：先写 vl 再写 rd，避免后一个 uop 的
            // 源被前一个 uop 改掉。
            cs[0].fuType = FU_VSETIWF;
            cs[0].ldest  = VL_IDX;
            cs[0].rfWen  = 1'b0;
            cs[0].vlWen  = 1'b1;
            cs[1].fuType = FU_VSETIWI;
            cs[1].ldest  = vdst;
            cs[1].rfWen  = 1'b1;
            cs[1].vlWen  = 1'b0;
          end
          // 两个 uop 的 vtype 都用 VTypeGen 本拍旁路过来的值（不是锁存的那份）
          cs[0].vpu_vill  = vtype_bypass.illegal;
          cs[0].vpu_vma   = vtype_bypass.vma;
          cs[0].vpu_vta   = vtype_bypass.vta;
          cs[0].vpu_vsew  = vtype_bypass.vsew;
          cs[0].vpu_vlmul = vtype_bypass.vlmul;
          cs[1].vpu_vill  = vtype_bypass.illegal;
          cs[1].vpu_vma   = vtype_bypass.vma;
          cs[1].vpu_vta   = vtype_bypass.vta;
          cs[1].vpu_vsew  = vtype_bypass.vsew;
          cs[1].vpu_vlmul = vtype_bypass.vlmul;
        end
      end

      // ===== 最规则的一族：LMUL 组里第 i 个 uop 各读各的、各写各的 =====
      // VEC_VVV  = 向量-向量-向量（vadd.vv 这种）
      // VEC_MVNR = vmv<N>r.v（整寄存器搬运），展开形状与 VVV 完全一样
      UST_VEC_VVV, UST_VEC_MVNR: begin
        for (int i = 0; i < MAX_VLMUL; i++) begin
          cs[i].lsrc[0] = src1 + 6'(i);
          cs[i].lsrc[1] = src2 + 6'(i);
          cs[i].lsrc[2] = vdst + 6'(i);
          cs[i].ldest   = vdst + 6'(i);
          cs[i].uopIdx  = 7'(i);
        end
      end

      // ===== 需要先把标量/浮点源「广播」进向量临时寄存器的一族 =====
      // 这一族的 uop0 都是一条 i2v/f2v：把 x[rs1] 或 f[rs1] 复制满一个向量寄存器
      // （放在临时区 v32），后面的 uop 再拿 v32 当向量源。
      // 差别只在：源是浮点还是整数、是否要 dup、以及后面 LMUL 循环的形状。

      // VEC_VFV：浮点标量 + 向量 → 向量
      UST_VEC_VFV: begin
        cs[0].srcType[0]   = ST_FP;
        cs[0].srcType[1]   = ST_IMM;
        cs[0].srcType[2]   = ST_IMM;
        cs[0].lsrc[1]      = 6'd0;
        cs[0].ldest        = VTMP;
        cs[0].fuType       = FU_F2V;
        cs[0].fuOpType     = {4'd0, IF2V_FDUP2VEC, vsew_r};
        cs[0].vecWen       = 1'b1;
        cs[0].vpu_isReverse= 1'b0;
        for (int i = 0; i < MAX_VLMUL; i++) begin
          cs[i + 1].srcType[0] = ST_VP;
          cs[i + 1].lsrc[0]    = VTMP;
          cs[i + 1].lsrc[1]    = src2 + 6'(i);
          cs[i + 1].lsrc[2]    = vdst + 6'(i);
          cs[i + 1].ldest      = vdst + 6'(i);
          cs[i + 1].uopIdx     = 7'(i);
        end
      end

      // VEC_EXT2/4/8：vsext/vzext.vf2/vf4/vf8 —— 一个源寄存器喂 2/4/8 个目的寄存器
      UST_VEC_EXT2: begin
        for (int i = 0; i < MAX_VLMUL / 2; i++) begin
          for (int k = 0; k < 2; k++) begin
            cs[2 * i + k].lsrc[1] = src2 + 6'(i);
            cs[2 * i + k].lsrc[2] = vdst + 6'(2 * i + k);
            cs[2 * i + k].ldest   = vdst + 6'(2 * i + k);
            cs[2 * i + k].uopIdx  = 7'(2 * i + k);
          end
        end
      end

      UST_VEC_EXT4: begin
        for (int i = 0; i < MAX_VLMUL / 4; i++) begin
          for (int k = 0; k < 4; k++) begin
            cs[4 * i + k].lsrc[1] = src2 + 6'(i);
            cs[4 * i + k].lsrc[2] = vdst + 6'(4 * i + k);
            cs[4 * i + k].ldest   = vdst + 6'(4 * i + k);
            cs[4 * i + k].uopIdx  = 7'(4 * i + k);
          end
        end
      end

      UST_VEC_EXT8: begin
        for (int i = 0; i < MAX_VLMUL; i++) begin
          cs[i].lsrc[1] = src2;
          cs[i].lsrc[2] = vdst + 6'(i);
          cs[i].ldest   = vdst + 6'(i);
          cs[i].uopIdx  = 7'(i);
        end
      end

      // VEC_0XV：整数/浮点 → 向量单元素（vmv.s.x / vfmv.s.f）。只有 2 个 uop。
      UST_VEC_0XV: begin
        cs[0].srcType[0] = src1_is_fp ? ST_FP : ST_XP;
        cs[0].srcType[1] = ST_IMM;
        cs[0].srcType[2] = ST_IMM;
        cs[0].lsrc[1]    = 6'd0;
        cs[0].ldest      = VTMP;
        cs[0].fuType     = src1_is_fp ? FU_F2V : FU_I2V;
        cs[0].fuOpType   = {4'd0, src1_is_fp ? IF2V_FDUP2VEC : IF2V_I2VEC, vsew_r};
        cs[0].rfWen      = 1'b0;
        cs[0].fpWen      = 1'b0;
        cs[0].vecWen     = 1'b1;

        cs[1].srcType[0] = ST_VP;
        cs[1].srcType[1] = ST_IMM;
        cs[1].srcType[2] = ST_VP;
        cs[1].lsrc[0]    = VTMP;
        cs[1].lsrc[1]    = 6'd0;
        cs[1].lsrc[2]    = vdst;
        cs[1].ldest      = vdst;
        cs[1].rfWen      = 1'b0;
        cs[1].fpWen      = 1'b0;
        cs[1].vecWen     = 1'b1;
        cs[1].uopIdx     = 7'd0;
      end

      // VEC_VXV：整数标量（或立即数）+ 向量 → 向量
      UST_VEC_VXV: begin
        cs[0].srcType[0]   = src1_is_imm ? ST_IMM : ST_XP;
        cs[0].srcType[1]   = ST_IMM;
        cs[0].srcType[2]   = ST_IMM;
        cs[0].lsrc[1]      = 6'd0;
        cs[0].ldest        = VTMP;
        cs[0].fuType       = FU_I2V;
        cs[0].fuOpType     = {4'd0, src1_is_imm ? IF2V_IMMDUP2VEC : IF2V_IDUP2VEC, vsew_r};
        cs[0].vecWen       = 1'b1;
        cs[0].vpu_isReverse= 1'b0;
        for (int i = 0; i < MAX_VLMUL; i++) begin
          cs[i + 1].srcType[0] = ST_VP;
          cs[i + 1].lsrc[0]    = VTMP;
          cs[i + 1].lsrc[1]    = src2 + 6'(i);
          cs[i + 1].lsrc[2]    = vdst + 6'(i);
          cs[i + 1].ldest      = vdst + 6'(i);
          cs[i + 1].uopIdx     = 7'(i);
        end
      end

      // ===== 加宽一族（目的宽一倍，所以 vd 占的寄存器是源的两倍）=====
      // VEC_VVW：两个窄源 → 一个宽目的，每个源寄存器喂两个目的寄存器
      UST_VEC_VVW: begin
        for (int i = 0; i < MAX_VLMUL / 2; i++) begin
          for (int k = 0; k < 2; k++) begin
            cs[2 * i + k].lsrc[0] = src1 + 6'(i);
            cs[2 * i + k].lsrc[1] = src2 + 6'(i);
            cs[2 * i + k].lsrc[2] = vdst + 6'(2 * i + k);
            cs[2 * i + k].ldest   = vdst + 6'(2 * i + k);
            cs[2 * i + k].uopIdx  = 7'(2 * i + k);
          end
        end
      end

      // VEC_VFW：浮点标量 + 窄向量 → 宽向量
      UST_VEC_VFW: begin
        cs[0].srcType[0] = ST_FP;
        cs[0].srcType[1] = ST_IMM;
        cs[0].srcType[2] = ST_IMM;
        cs[0].lsrc[1]    = 6'd0;
        cs[0].ldest      = VTMP;
        cs[0].fuType     = FU_F2V;
        cs[0].fuOpType   = {4'd0, IF2V_FDUP2VEC, vsew_r};
        cs[0].rfWen      = 1'b0;
        cs[0].fpWen      = 1'b0;
        cs[0].vecWen     = 1'b1;
        for (int i = 0; i < MAX_VLMUL / 2; i++) begin
          for (int k = 0; k < 2; k++) begin
            cs[2 * i + k + 1].srcType[0] = ST_VP;
            cs[2 * i + k + 1].lsrc[0]    = VTMP;
            cs[2 * i + k + 1].lsrc[1]    = src2 + 6'(i);
            cs[2 * i + k + 1].lsrc[2]    = vdst + 6'(2 * i + k);
            cs[2 * i + k + 1].ldest      = vdst + 6'(2 * i + k);
            cs[2 * i + k + 1].uopIdx     = 7'(2 * i + k);
          end
        end
      end

      // VEC_WVW：宽源 + 窄源 → 宽目的（.wv 形态）
      UST_VEC_WVW: begin
        for (int i = 0; i < MAX_VLMUL / 2; i++) begin
          for (int k = 0; k < 2; k++) begin
            cs[2 * i + k].lsrc[0] = src1 + 6'(i);
            cs[2 * i + k].lsrc[1] = src2 + 6'(2 * i + k);
            cs[2 * i + k].lsrc[2] = vdst + 6'(2 * i + k);
            cs[2 * i + k].ldest   = vdst + 6'(2 * i + k);
            cs[2 * i + k].uopIdx  = 7'(2 * i + k);
          end
        end
      end

      // VEC_VXW：整数标量/立即数 + 窄向量 → 宽向量
      UST_VEC_VXW: begin
        cs[0].srcType[0] = src1_is_imm ? ST_IMM : ST_XP;
        cs[0].srcType[1] = ST_IMM;
        cs[0].srcType[2] = ST_IMM;
        cs[0].lsrc[1]    = 6'd0;
        cs[0].ldest      = VTMP;
        cs[0].fuType     = FU_I2V;
        cs[0].fuOpType   = {4'd0, src1_is_imm ? IF2V_IMMDUP2VEC : IF2V_IDUP2VEC, vsew_r};
        cs[0].vecWen     = 1'b1;
        for (int i = 0; i < MAX_VLMUL / 2; i++) begin
          for (int k = 0; k < 2; k++) begin
            cs[2 * i + k + 1].srcType[0] = ST_VP;
            cs[2 * i + k + 1].lsrc[0]    = VTMP;
            cs[2 * i + k + 1].lsrc[1]    = src2 + 6'(i);
            cs[2 * i + k + 1].lsrc[2]    = vdst + 6'(2 * i + k);
            cs[2 * i + k + 1].ldest      = vdst + 6'(2 * i + k);
            cs[2 * i + k + 1].uopIdx     = 7'(2 * i + k);
          end
        end
      end

      // VEC_WXW：整数标量 + 宽向量 → 宽向量（源已经是宽的，所以 vs2 也按 2i 走）
      UST_VEC_WXW: begin
        cs[0].srcType[0] = ST_XP;
        cs[0].srcType[1] = ST_IMM;
        cs[0].srcType[2] = ST_IMM;
        cs[0].lsrc[1]    = 6'd0;
        cs[0].ldest      = VTMP;
        cs[0].fuType     = FU_I2V;
        cs[0].fuOpType   = {4'd0, IF2V_IDUP2VEC, vsew_r};
        cs[0].vecWen     = 1'b1;
        for (int i = 0; i < MAX_VLMUL / 2; i++) begin
          for (int k = 0; k < 2; k++) begin
            cs[2 * i + k + 1].srcType[0] = ST_VP;
            cs[2 * i + k + 1].lsrc[0]    = VTMP;
            cs[2 * i + k + 1].lsrc[1]    = src2 + 6'(2 * i + k);
            cs[2 * i + k + 1].lsrc[2]    = vdst + 6'(2 * i + k);
            cs[2 * i + k + 1].ldest      = vdst + 6'(2 * i + k);
            cs[2 * i + k + 1].uopIdx     = 7'(2 * i + k);
          end
        end
      end

      // ===== 收窄一族（源宽一倍，目的窄）=====
      // VEC_WVV：宽 vs2 + 窄 vs1 → 窄 vd，两个源寄存器合出一个目的寄存器
      UST_VEC_WVV: begin
        for (int i = 0; i < MAX_VLMUL / 2; i++) begin
          for (int k = 0; k < 2; k++) begin
            cs[2 * i + k].lsrc[0] = src1 + 6'(i);
            cs[2 * i + k].lsrc[1] = src2 + 6'(2 * i + k);
            cs[2 * i + k].lsrc[2] = vdst + 6'(i);
            cs[2 * i + k].ldest   = vdst + 6'(i);
            cs[2 * i + k].uopIdx  = 7'(2 * i + k);
          end
        end
      end

      // VEC_WFW：浮点标量 + 宽向量 → 宽向量
      UST_VEC_WFW: begin
        cs[0].srcType[0] = ST_FP;
        cs[0].srcType[1] = ST_IMM;
        cs[0].srcType[2] = ST_IMM;
        cs[0].lsrc[1]    = 6'd0;
        cs[0].ldest      = VTMP;
        cs[0].fuType     = FU_F2V;
        cs[0].fuOpType   = {4'd0, IF2V_FDUP2VEC, vsew_r};
        cs[0].rfWen      = 1'b0;
        cs[0].fpWen      = 1'b0;
        cs[0].vecWen     = 1'b1;
        for (int i = 0; i < MAX_VLMUL / 2; i++) begin
          for (int k = 0; k < 2; k++) begin
            cs[2 * i + k + 1].srcType[0] = ST_VP;
            cs[2 * i + k + 1].lsrc[0]    = VTMP;
            cs[2 * i + k + 1].lsrc[1]    = src2 + 6'(2 * i + k);
            cs[2 * i + k + 1].lsrc[2]    = vdst + 6'(2 * i + k);
            cs[2 * i + k + 1].ldest      = vdst + 6'(2 * i + k);
            cs[2 * i + k + 1].uopIdx     = 7'(2 * i + k);
          end
        end
      end

      // VEC_WXV：整数标量 + 宽向量 → 窄向量
      UST_VEC_WXV: begin
        cs[0].srcType[0] = src1_is_imm ? ST_IMM : ST_XP;
        cs[0].srcType[1] = ST_IMM;
        cs[0].srcType[2] = ST_IMM;
        cs[0].lsrc[1]    = 6'd0;
        cs[0].ldest      = VTMP;
        cs[0].fuType     = FU_I2V;
        cs[0].fuOpType   = {4'd0, src1_is_imm ? IF2V_IMMDUP2VEC : IF2V_IDUP2VEC, vsew_r};
        cs[0].vecWen     = 1'b1;
        for (int i = 0; i < MAX_VLMUL / 2; i++) begin
          for (int k = 0; k < 2; k++) begin
            cs[2 * i + k + 1].srcType[0] = ST_VP;
            cs[2 * i + k + 1].lsrc[0]    = VTMP;
            cs[2 * i + k + 1].lsrc[1]    = src2 + 6'(2 * i + k);
            cs[2 * i + k + 1].lsrc[2]    = vdst + 6'(i);
            cs[2 * i + k + 1].ldest      = vdst + 6'(i);
            cs[2 * i + k + 1].uopIdx     = 7'(2 * i + k);
          end
        end
      end

      // ===== 结果是掩码的一族（vd 只占 1 个寄存器，所有 uop 写同一个 vd）=====
      UST_VEC_VVM: begin
        cs[0].lsrc[2] = vdst;
        cs[0].ldest   = vdst;
        cs[0].uopIdx  = 7'd0;
        for (int i = 1; i < MAX_VLMUL; i++) begin
          cs[i].lsrc[0] = src1 + 6'(i);
          cs[i].lsrc[1] = src2 + 6'(i);
          cs[i].lsrc[2] = vdst;
          cs[i].ldest   = vdst;
          cs[i].uopIdx  = 7'(i);
        end
      end

      UST_VEC_VFM: begin
        cs[0].srcType[0] = ST_FP;
        cs[0].srcType[1] = ST_IMM;
        cs[0].srcType[2] = ST_IMM;
        cs[0].lsrc[1]    = 6'd0;
        cs[0].ldest      = VTMP;
        cs[0].fuType     = FU_F2V;
        cs[0].fuOpType   = {4'd0, IF2V_FDUP2VEC, vsew_r};
        cs[0].rfWen      = 1'b0;
        cs[0].fpWen      = 1'b0;
        cs[0].vecWen     = 1'b1;
        cs[1].srcType[0] = ST_VP;
        cs[1].lsrc[0]    = VTMP;
        cs[1].lsrc[2]    = vdst;
        cs[1].ldest      = vdst;
        cs[1].uopIdx     = 7'd0;
        for (int i = 1; i < MAX_VLMUL; i++) begin
          cs[i + 1].srcType[0] = ST_VP;
          cs[i + 1].lsrc[0]    = VTMP;
          cs[i + 1].lsrc[1]    = src2 + 6'(i);
          cs[i + 1].lsrc[2]    = vdst;
          cs[i + 1].ldest      = vdst;
          cs[i + 1].uopIdx     = 7'(i);
        end
        for (int i = 0; i < MAX_UOP; i++)
          if (7'(i) == last_uop_idx) cs[i].ldest = vdst;
      end

      UST_VEC_VXM: begin
        cs[0].srcType[0] = src1_is_imm ? ST_IMM : ST_XP;
        cs[0].srcType[1] = ST_IMM;
        cs[0].srcType[2] = ST_IMM;
        cs[0].lsrc[1]    = 6'd0;
        cs[0].ldest      = VTMP;
        cs[0].fuType     = FU_I2V;
        cs[0].fuOpType   = {4'd0, src1_is_imm ? IF2V_IMMDUP2VEC : IF2V_IDUP2VEC, vsew_r};
        cs[0].vecWen     = 1'b1;
        cs[1].srcType[0] = ST_VP;
        cs[1].lsrc[0]    = VTMP;
        cs[1].lsrc[2]    = vdst;
        cs[1].ldest      = vdst;
        cs[1].uopIdx     = 7'd0;
        for (int i = 1; i < MAX_VLMUL; i++) begin
          cs[i + 1].srcType[0] = ST_VP;
          cs[i + 1].lsrc[0]    = VTMP;
          cs[i + 1].lsrc[1]    = src2 + 6'(i);
          cs[i + 1].lsrc[2]    = vdst;
          cs[i + 1].ldest      = vdst;
          cs[i + 1].uopIdx     = 7'(i);
        end
        for (int i = 0; i < MAX_UOP; i++)
          if (7'(i) == last_uop_idx) cs[i].ldest = vdst;
      end

      // ===== vslide1up/vfslide1up：整条向量往上挪一格，最低位补标量 =====
      // uop0 把标量搬进 v32；第 1 个 uop 处理最低那组（新元素来自 v32），
      // 其余每组的「上一格」来自前一个源寄存器。
      UST_VEC_SLIDE1UP: begin
        cs[0].srcType[0] = ST_XP;
        cs[0].srcType[1] = ST_IMM;
        cs[0].srcType[2] = ST_IMM;
        cs[0].lsrc[1]    = 6'd0;
        cs[0].ldest      = VTMP;
        cs[0].fuType     = FU_I2V;
        cs[0].fuOpType   = {4'd0, IF2V_IDUP2VEC, vsew_r};
        cs[0].vecWen     = 1'b1;
        cs[1].srcType[0] = ST_VP;
        cs[1].lsrc[0]    = VTMP;
        cs[1].lsrc[2]    = vdst;
        cs[1].ldest      = vdst;
        cs[1].uopIdx     = 7'd0;
        for (int i = 1; i < MAX_VLMUL; i++) begin
          cs[i + 1].srcType[0] = ST_VP;
          cs[i + 1].lsrc[0]    = src2 + 6'(i - 1);
          cs[i + 1].lsrc[1]    = src2 + 6'(i);
          cs[i + 1].lsrc[2]    = vdst + 6'(i);
          cs[i + 1].ldest      = vdst + 6'(i);
          cs[i + 1].uopIdx     = 7'(i);
        end
      end

      UST_VEC_FSLIDE1UP: begin
        cs[0].srcType[0] = ST_FP;
        cs[0].srcType[1] = ST_IMM;
        cs[0].srcType[2] = ST_IMM;
        cs[0].lsrc[1]    = 6'd0;
        cs[0].ldest      = VTMP;
        cs[0].fuType     = FU_F2V;
        cs[0].fuOpType   = {4'd0, IF2V_FDUP2VEC, vsew_r};
        cs[0].rfWen      = 1'b0;
        cs[0].fpWen      = 1'b0;
        cs[0].vecWen     = 1'b1;
        cs[1].srcType[0] = ST_VP;
        cs[1].lsrc[0]    = VTMP;
        cs[1].lsrc[1]    = src2;        // ★整数版没有这一行，浮点版有★
        cs[1].lsrc[2]    = vdst;
        cs[1].ldest      = vdst;
        cs[1].uopIdx     = 7'd0;
        for (int i = 1; i < MAX_VLMUL; i++) begin
          cs[i + 1].srcType[0] = ST_VP;
          cs[i + 1].lsrc[0]    = src2 + 6'(i - 1);
          cs[i + 1].lsrc[1]    = src2 + 6'(i);
          cs[i + 1].lsrc[2]    = vdst + 6'(i);
          cs[i + 1].ldest      = vdst + 6'(i);
          cs[i + 1].uopIdx     = 7'(i);
        end
      end

      // ===== vslide1down/vfslide1down：往下挪一格，最高位补标量 =====
      // 每组要两个 uop：先算出「本组结果」放进 v33，再把 v33 搬到真正的 vd。
      // 这么绕是因为 vd 与 vs2 可能重叠，不能边读边写。
      // 最后一个 uop 另外覆盖：它的源固定是 v32（那个标量），目的是最高一组。
      UST_VEC_SLIDE1DOWN: begin
        cs[0].srcType[0] = ST_XP;
        cs[0].srcType[1] = ST_IMM;
        cs[0].srcType[2] = ST_IMM;
        cs[0].lsrc[1]    = 6'd0;
        cs[0].ldest      = VTMP;
        cs[0].fuType     = FU_I2V;
        cs[0].fuOpType   = {4'd0, IF2V_IDUP2VEC, vsew_r};
        cs[0].vecWen     = 1'b1;
        for (int i = 0; i < MAX_VLMUL; i++) begin
          cs[2 * i + 1].srcType[0] = ST_VP;
          cs[2 * i + 1].srcType[1] = ST_VP;
          cs[2 * i + 1].lsrc[0]    = src2 + 6'(i + 1);
          cs[2 * i + 1].lsrc[1]    = src2 + 6'(i);
          cs[2 * i + 1].lsrc[2]    = vdst + 6'(i);
          cs[2 * i + 1].ldest      = VTMP + 6'd1;
          cs[2 * i + 1].uopIdx     = 7'(2 * i);
          // 2*i+2 == 16 时越过本分支的 uop 上限，Chisel 用编译期 if 挡掉
          if (2 * i + 2 < MAX_VLMUL * 2) begin
            cs[2 * i + 2].srcType[0] = ST_VP;
            cs[2 * i + 2].lsrc[0]    = VTMP;
            cs[2 * i + 2].lsrc[2]    = VTMP + 6'd1;
            cs[2 * i + 2].ldest      = vdst + 6'(i);
            cs[2 * i + 2].uopIdx     = 7'(2 * i + 1);
          end
        end
        for (int i = 0; i < MAX_UOP; i++) begin
          if (7'(i) == last_uop_idx) begin
            cs[i].srcType[0] = ST_VP;
            cs[i].lsrc[0]    = VTMP;
            cs[i].ldest      = vdst + {2'b00, lmul} - 6'd1;
          end
        end
      end

      UST_VEC_FSLIDE1DN: begin
        cs[0].srcType[0] = ST_FP;
        cs[0].srcType[1] = ST_IMM;
        cs[0].srcType[2] = ST_IMM;
        cs[0].lsrc[1]    = 6'd0;
        cs[0].ldest      = VTMP;
        cs[0].fuType     = FU_F2V;
        cs[0].fuOpType   = {4'd0, IF2V_FDUP2VEC, vsew_r};
        cs[0].rfWen      = 1'b0;
        cs[0].fpWen      = 1'b0;
        cs[0].vecWen     = 1'b1;
        for (int i = 0; i < MAX_VLMUL; i++) begin
          cs[2 * i + 1].srcType[0] = ST_VP;
          cs[2 * i + 1].srcType[1] = ST_VP;
          cs[2 * i + 1].lsrc[0]    = src2 + 6'(i + 1);
          cs[2 * i + 1].lsrc[1]    = src2 + 6'(i);
          cs[2 * i + 1].lsrc[2]    = vdst + 6'(i);
          cs[2 * i + 1].ldest      = VTMP + 6'd1;
          cs[2 * i + 1].uopIdx     = 7'(2 * i);
          if (2 * i + 2 < MAX_VLMUL * 2) begin
            cs[2 * i + 2].srcType[0] = ST_VP;
            cs[2 * i + 2].lsrc[0]    = VTMP;
            cs[2 * i + 2].lsrc[2]    = VTMP + 6'd1;
            cs[2 * i + 2].ldest      = vdst + 6'(i);
            cs[2 * i + 2].uopIdx     = 7'(2 * i + 1);
          end
        end
        for (int i = 0; i < MAX_UOP; i++) begin
          if (7'(i) == last_uop_idx) begin
            cs[i].srcType[0] = ST_VP;
            cs[i].lsrc[0]    = VTMP;
            cs[i].ldest      = vdst + {2'b00, lmul} - 6'd1;
          end
        end
      end

      // ===== 整数归约 vredsum 等：两两相加成一棵树，最后再并进 vd[0] =====
      // LMUL=1 时不需要树（一个寄存器直接归约），所以只有 m2/m4/m8 有树。
      UST_VEC_VRED: begin
        if (vlmul_r == VLMUL_M2) begin
          cs[0].srcType[2] = ST_IMM;      // SrcType.DC：旧 vd 不参与
          cs[0].lsrc[0]    = src2 + 6'd1;
          cs[0].lsrc[1]    = src2;
          cs[0].ldest      = VTMP;
          cs[0].uopIdx     = 7'd0;
        end
        if (vlmul_r == VLMUL_M4) begin
          cs[0].srcType[2] = ST_IMM;
          cs[0].lsrc[0]    = src2 + 6'd1;
          cs[0].lsrc[1]    = src2;
          cs[0].ldest      = VTMP;
          cs[0].uopIdx     = 7'd0;

          cs[1].srcType[2] = ST_IMM;
          cs[1].lsrc[0]    = src2 + 6'd3;
          cs[1].lsrc[1]    = src2 + 6'd2;
          cs[1].ldest      = VTMP + 6'd1;
          cs[1].uopIdx     = 7'd1;

          cs[2].srcType[2] = ST_IMM;
          cs[2].lsrc[0]    = VTMP + 6'd1;
          cs[2].lsrc[1]    = VTMP;
          cs[2].ldest      = VTMP + 6'd2;
          cs[2].uopIdx     = 7'd2;
        end
        if (vlmul_r == VLMUL_M8) begin
          // 8 个寄存器 → 4 + 2 + 1 = 7 个树节点（第 8 个位置 i=7 只填公共字段）
          for (int i = 0; i < MAX_VLMUL; i++) begin
            if (i < 4) begin                         // 第一层：直接读 vs2
              cs[i].lsrc[0] = src2 + 6'(i * 2 + 1);
              cs[i].lsrc[1] = src2 + 6'(i * 2);
              cs[i].ldest   = VTMP + 6'(i);
            end else if (i < 6) begin                // 第二层：读第一层的结果
              cs[i].lsrc[0] = VTMP + 6'((i - 4) * 2 + 1);
              cs[i].lsrc[1] = VTMP + 6'((i - 4) * 2);
              cs[i].ldest   = VTMP + 6'(i);
            end else if (i < 7) begin                // 第三层：只有 i==6 这一个
              cs[6].lsrc[0] = VTMP + 6'd5;
              cs[6].lsrc[1] = VTMP + 6'd4;
              cs[6].ldest   = VTMP + 6'd6;
            end
            cs[i].srcType[2] = ST_IMM;
            cs[i].uopIdx     = 7'(i);
          end
        end
        // LMUL ≥ 2（编码 001/010/011）时，最后一个 uop 把树顶与 vs1[0] 合并写 vd
        if (vlmul_r[2] == 1'b0 && (|vlmul_r[1:0])) begin
          for (int i = 0; i < MAX_UOP; i++) begin
            if (7'(i) == last_uop_idx) begin
              cs[i].srcType[2] = ST_VP;
              cs[i].lsrc[0]    = src1;
              // ★位宽：VTMP(6) + numOfUop(7) 在 Chisel 里按 7 位算，再截回 6 位★
              cs[i].lsrc[1]    = 6'({1'b0, VTMP} + num_of_uop - 7'd2);
              cs[i].lsrc[2]    = vdst;
              cs[i].ldest      = vdst;
              cs[i].uopIdx     = last_uop_idx;
            end
          end
        end
      end

      // ===== 浮点归约 vfredusum/vfredmax 等：树 + 「折叠」链 + 收尾 =====
      // 浮点归约比整数多一层：树把 LMUL 组归约成一个寄存器之后，还要在**寄存器
      // 内部**把 VLEN 个元素一路折半，直到只剩一个元素。折几次由 SEW 定：
      //   e64 折 1 次(1/2)、e32 折 2 次(1/2→1/4)、e16 折 3 次(1/2→1/4→1/8)。
      // 分数 LMUL 起步就窄，折叠从更深的一级开始：mf2 从 1/4 起、mf4 从 1/8 起。
      // 所以 (vlmul, vsew) 的每个组合都有自己的一串 uop —— 下面逐个写出来，
      // 与 Chisel 的 when 链一一对应（Chisel 也是逐个写的）。
      UST_VEC_VFRED: begin
        // ---- 树：把 LMUL 组两两归约进 v32.. ----
        case (vlmul_r)
          VLMUL_M8: begin
            for (int i = 0; i < 4; i++) begin          // 第一层：8 → 4
              cs[i].lsrc[0] = src2 + 6'(i * 2 + 1);
              cs[i].lsrc[1] = src2 + 6'(i * 2);
              cs[i].ldest   = VTMP + 6'(i);
              cs[i].uopIdx  = 7'(i);
            end
            for (int i = 4; i < 6; i++) begin          // 第二层：4 → 2
              cs[i].lsrc[0] = VTMP + 6'((i - 4) * 2 + 1);
              cs[i].lsrc[1] = VTMP + 6'((i - 4) * 2);
              cs[i].ldest   = VTMP + 6'(i);
              cs[i].uopIdx  = 7'(i);
            end
            cs[6].lsrc[0] = VTMP + 6'd5;               // 第三层：2 → 1
            cs[6].lsrc[1] = VTMP + 6'd4;
            cs[6].ldest   = VTMP + 6'd6;
            cs[6].uopIdx  = 7'd6;
          end
          VLMUL_M4: begin
            for (int i = 0; i < 2; i++) begin
              cs[i].lsrc[0] = src2 + 6'(i * 2 + 1);
              cs[i].lsrc[1] = src2 + 6'(i * 2);
              cs[i].ldest   = VTMP + 6'(i);
              cs[i].uopIdx  = 7'(i);
            end
            cs[2].lsrc[0] = VTMP + 6'd1;
            cs[2].lsrc[1] = VTMP;
            cs[2].ldest   = VTMP + 6'd2;
            cs[2].uopIdx  = 7'd2;
          end
          VLMUL_M2: begin
            cs[0].lsrc[0] = src2 + 6'd1;
            cs[0].lsrc[1] = src2;
            cs[0].ldest   = VTMP;
            cs[0].uopIdx  = 7'd0;
          end
          default: ;                                   // m1 与分数 LMUL 不需要树
        endcase

        // ---- 折叠链 + 收尾（uop 下标接在树后面）----
        case (vlmul_r)
          VLMUL_M8: begin
            case (vsew_r)
              VSEW_E64: begin
                cs[7].lsrc[0] = VTMP + 6'd6;
                cs[7].lsrc[1] = VTMP + 6'd6;
                cs[7].ldest   = VTMP + 6'd7;
                cs[7].vpu_fpu_isFoldTo1_2 = 1'b1;
                cs[7].uopIdx  = 7'd7;
                cs[8].lsrc[0] = src1;        // 收尾：与 vs1[0] 合并写 vd
                cs[8].lsrc[1] = VTMP + 6'd7;
                cs[8].ldest   = vdst;
                cs[8].uopIdx  = 7'd8;
              end
              VSEW_E32: begin
                cs[7].lsrc[0] = VTMP + 6'd6;
                cs[7].lsrc[1] = VTMP + 6'd6;
                cs[7].ldest   = VTMP + 6'd7;
                cs[7].vpu_fpu_isFoldTo1_2 = 1'b1;
                cs[7].uopIdx  = 7'd7;
                cs[8].lsrc[0] = VTMP + 6'd7;
                cs[8].lsrc[1] = VTMP + 6'd7;
                cs[8].ldest   = VTMP + 6'd8;
                cs[8].vpu_fpu_isFoldTo1_4 = 1'b1;
                cs[8].uopIdx  = 7'd8;
                cs[9].lsrc[0] = src1;        // 收尾：与 vs1[0] 合并写 vd
                cs[9].lsrc[1] = VTMP + 6'd8;
                cs[9].ldest   = vdst;
                cs[9].uopIdx  = 7'd9;
              end
              VSEW_E16: begin
                cs[7].lsrc[0] = VTMP + 6'd6;
                cs[7].lsrc[1] = VTMP + 6'd6;
                cs[7].ldest   = VTMP + 6'd7;
                cs[7].vpu_fpu_isFoldTo1_2 = 1'b1;
                cs[7].uopIdx  = 7'd7;
                cs[8].lsrc[0] = VTMP + 6'd7;
                cs[8].lsrc[1] = VTMP + 6'd7;
                cs[8].ldest   = VTMP + 6'd8;
                cs[8].vpu_fpu_isFoldTo1_4 = 1'b1;
                cs[8].uopIdx  = 7'd8;
                cs[9].lsrc[0] = VTMP + 6'd8;
                cs[9].lsrc[1] = VTMP + 6'd8;
                cs[9].ldest   = VTMP + 6'd9;
                cs[9].vpu_fpu_isFoldTo1_8 = 1'b1;
                cs[9].uopIdx  = 7'd9;
                cs[10].lsrc[0] = src1;        // 收尾：与 vs1[0] 合并写 vd
                cs[10].lsrc[1] = VTMP + 6'd9;
                cs[10].ldest   = vdst;
                cs[10].uopIdx  = 7'd10;
              end
              default: ;
            endcase
          end
          VLMUL_M4: begin
            case (vsew_r)
              VSEW_E64: begin
                cs[3].lsrc[0] = VTMP + 6'd2;
                cs[3].lsrc[1] = VTMP + 6'd2;
                cs[3].ldest   = VTMP + 6'd3;
                cs[3].vpu_fpu_isFoldTo1_2 = 1'b1;
                cs[3].uopIdx  = 7'd3;
                cs[4].lsrc[0] = src1;        // 收尾：与 vs1[0] 合并写 vd
                cs[4].lsrc[1] = VTMP + 6'd3;
                cs[4].ldest   = vdst;
                cs[4].uopIdx  = 7'd4;
              end
              VSEW_E32: begin
                cs[3].lsrc[0] = VTMP + 6'd2;
                cs[3].lsrc[1] = VTMP + 6'd2;
                cs[3].ldest   = VTMP + 6'd3;
                cs[3].vpu_fpu_isFoldTo1_2 = 1'b1;
                cs[3].uopIdx  = 7'd3;
                cs[4].lsrc[0] = VTMP + 6'd3;
                cs[4].lsrc[1] = VTMP + 6'd3;
                cs[4].ldest   = VTMP + 6'd4;
                cs[4].vpu_fpu_isFoldTo1_4 = 1'b1;
                cs[4].uopIdx  = 7'd4;
                cs[5].lsrc[0] = src1;        // 收尾：与 vs1[0] 合并写 vd
                cs[5].lsrc[1] = VTMP + 6'd4;
                cs[5].ldest   = vdst;
                cs[5].uopIdx  = 7'd5;
              end
              VSEW_E16: begin
                cs[3].lsrc[0] = VTMP + 6'd2;
                cs[3].lsrc[1] = VTMP + 6'd2;
                cs[3].ldest   = VTMP + 6'd3;
                cs[3].vpu_fpu_isFoldTo1_2 = 1'b1;
                cs[3].uopIdx  = 7'd3;
                cs[4].lsrc[0] = VTMP + 6'd3;
                cs[4].lsrc[1] = VTMP + 6'd3;
                cs[4].ldest   = VTMP + 6'd4;
                cs[4].vpu_fpu_isFoldTo1_4 = 1'b1;
                cs[4].uopIdx  = 7'd4;
                cs[5].lsrc[0] = VTMP + 6'd4;
                cs[5].lsrc[1] = VTMP + 6'd4;
                cs[5].ldest   = VTMP + 6'd5;
                cs[5].vpu_fpu_isFoldTo1_8 = 1'b1;
                cs[5].uopIdx  = 7'd5;
                cs[6].lsrc[0] = src1;        // 收尾：与 vs1[0] 合并写 vd
                cs[6].lsrc[1] = VTMP + 6'd5;
                cs[6].ldest   = vdst;
                cs[6].uopIdx  = 7'd6;
              end
              default: ;
            endcase
          end
          VLMUL_M2: begin
            case (vsew_r)
              VSEW_E64: begin
                cs[1].lsrc[0] = VTMP;
                cs[1].lsrc[1] = VTMP;
                cs[1].ldest   = VTMP + 6'd1;
                cs[1].vpu_fpu_isFoldTo1_2 = 1'b1;
                cs[1].uopIdx  = 7'd1;
                cs[2].lsrc[0] = src1;        // 收尾：与 vs1[0] 合并写 vd
                cs[2].lsrc[1] = VTMP + 6'd1;
                cs[2].ldest   = vdst;
                cs[2].uopIdx  = 7'd2;
              end
              VSEW_E32: begin
                cs[1].lsrc[0] = VTMP;
                cs[1].lsrc[1] = VTMP;
                cs[1].ldest   = VTMP + 6'd1;
                cs[1].vpu_fpu_isFoldTo1_2 = 1'b1;
                cs[1].uopIdx  = 7'd1;
                cs[2].lsrc[0] = VTMP + 6'd1;
                cs[2].lsrc[1] = VTMP + 6'd1;
                cs[2].ldest   = VTMP + 6'd2;
                cs[2].vpu_fpu_isFoldTo1_4 = 1'b1;
                cs[2].uopIdx  = 7'd2;
                cs[3].lsrc[0] = src1;        // 收尾：与 vs1[0] 合并写 vd
                cs[3].lsrc[1] = VTMP + 6'd2;
                cs[3].ldest   = vdst;
                cs[3].uopIdx  = 7'd3;
              end
              VSEW_E16: begin
                cs[1].lsrc[0] = VTMP;
                cs[1].lsrc[1] = VTMP;
                cs[1].ldest   = VTMP + 6'd1;
                cs[1].vpu_fpu_isFoldTo1_2 = 1'b1;
                cs[1].uopIdx  = 7'd1;
                cs[2].lsrc[0] = VTMP + 6'd1;
                cs[2].lsrc[1] = VTMP + 6'd1;
                cs[2].ldest   = VTMP + 6'd2;
                cs[2].vpu_fpu_isFoldTo1_4 = 1'b1;
                cs[2].uopIdx  = 7'd2;
                cs[3].lsrc[0] = VTMP + 6'd2;
                cs[3].lsrc[1] = VTMP + 6'd2;
                cs[3].ldest   = VTMP + 6'd3;
                cs[3].vpu_fpu_isFoldTo1_8 = 1'b1;
                cs[3].uopIdx  = 7'd3;
                cs[4].lsrc[0] = src1;        // 收尾：与 vs1[0] 合并写 vd
                cs[4].lsrc[1] = VTMP + 6'd3;
                cs[4].ldest   = vdst;
                cs[4].uopIdx  = 7'd4;
              end
              default: ;
            endcase
          end
          VLMUL_M1: begin
            case (vsew_r)
              VSEW_E64: begin
                cs[0].lsrc[0] = src2;
                cs[0].lsrc[1] = src2;
                cs[0].ldest   = VTMP;
                cs[0].vpu_fpu_isFoldTo1_2 = 1'b1;
                cs[0].uopIdx  = 7'd0;
                cs[1].lsrc[0] = src1;        // 收尾：与 vs1[0] 合并写 vd
                cs[1].lsrc[1] = VTMP;
                cs[1].ldest   = vdst;
                cs[1].uopIdx  = 7'd1;
              end
              VSEW_E32: begin
                cs[0].lsrc[0] = src2;
                cs[0].lsrc[1] = src2;
                cs[0].ldest   = VTMP;
                cs[0].vpu_fpu_isFoldTo1_2 = 1'b1;
                cs[0].uopIdx  = 7'd0;
                cs[1].lsrc[0] = VTMP;
                cs[1].lsrc[1] = VTMP;
                cs[1].ldest   = VTMP + 6'd1;
                cs[1].vpu_fpu_isFoldTo1_4 = 1'b1;
                cs[1].uopIdx  = 7'd1;
                cs[2].lsrc[0] = src1;        // 收尾：与 vs1[0] 合并写 vd
                cs[2].lsrc[1] = VTMP + 6'd1;
                cs[2].ldest   = vdst;
                cs[2].uopIdx  = 7'd2;
              end
              VSEW_E16: begin
                cs[0].lsrc[0] = src2;
                cs[0].lsrc[1] = src2;
                cs[0].ldest   = VTMP;
                cs[0].vpu_fpu_isFoldTo1_2 = 1'b1;
                cs[0].uopIdx  = 7'd0;
                cs[1].lsrc[0] = VTMP;
                cs[1].lsrc[1] = VTMP;
                cs[1].ldest   = VTMP + 6'd1;
                cs[1].vpu_fpu_isFoldTo1_4 = 1'b1;
                cs[1].uopIdx  = 7'd1;
                cs[2].lsrc[0] = VTMP + 6'd1;
                cs[2].lsrc[1] = VTMP + 6'd1;
                cs[2].ldest   = VTMP + 6'd2;
                cs[2].vpu_fpu_isFoldTo1_8 = 1'b1;
                cs[2].uopIdx  = 7'd2;
                cs[3].lsrc[0] = src1;        // 收尾：与 vs1[0] 合并写 vd
                cs[3].lsrc[1] = VTMP + 6'd2;
                cs[3].ldest   = vdst;
                cs[3].uopIdx  = 7'd3;
              end
              default: ;
            endcase
          end
          VLMUL_MF2: begin
            case (vsew_r)
              VSEW_E32: begin
                cs[0].lsrc[0] = src2;
                cs[0].lsrc[1] = src2;
                cs[0].ldest   = VTMP;
                cs[0].vpu_fpu_isFoldTo1_4 = 1'b1;
                cs[0].uopIdx  = 7'd0;
                cs[1].lsrc[0] = src1;        // 收尾：与 vs1[0] 合并写 vd
                cs[1].lsrc[1] = VTMP;
                cs[1].ldest   = vdst;
                cs[1].uopIdx  = 7'd1;
              end
              VSEW_E16: begin
                cs[0].lsrc[0] = src2;
                cs[0].lsrc[1] = src2;
                cs[0].ldest   = VTMP;
                cs[0].vpu_fpu_isFoldTo1_4 = 1'b1;
                cs[0].uopIdx  = 7'd0;
                cs[1].lsrc[0] = VTMP;
                cs[1].lsrc[1] = VTMP;
                cs[1].ldest   = VTMP + 6'd1;
                cs[1].vpu_fpu_isFoldTo1_8 = 1'b1;
                cs[1].uopIdx  = 7'd1;
                cs[2].lsrc[0] = src1;        // 收尾：与 vs1[0] 合并写 vd
                cs[2].lsrc[1] = VTMP + 6'd1;
                cs[2].ldest   = vdst;
                cs[2].uopIdx  = 7'd2;
              end
              default: ;
            endcase
          end
          VLMUL_MF4: begin
            case (vsew_r)
              VSEW_E16: begin
                cs[0].lsrc[0] = src2;
                cs[0].lsrc[1] = src2;
                cs[0].ldest   = VTMP;
                cs[0].vpu_fpu_isFoldTo1_8 = 1'b1;
                cs[0].uopIdx  = 7'd0;
                cs[1].lsrc[0] = src1;        // 收尾：与 vs1[0] 合并写 vd
                cs[1].lsrc[1] = VTMP;
                cs[1].ldest   = vdst;
                cs[1].uopIdx  = 7'd1;
              end
              default: ;
            endcase
          end
          default: ;                                   // mf8 与保留编码：无分支
        endcase
      end

      // ===== 有序浮点归约 vfredosum/vfwredosum：必须严格按元素顺序累加 =====
      // 不能用树（顺序会变），只能一个元素一个元素串起来，所以 uop 数 = 参与归约的
      // 元素组数 = LMUL 覆盖的寄存器数 × 每个寄存器折几次（e64 折 2、e32 折 4、
      // e16 折 8）。最多 8×8 = 64 个 uop —— 这是本模块 65 个 uop 上限的由来。
      // 每 STEP 个 uop 换一个源寄存器；第 0 个 uop 的 vs1 是标量初值，
      // 最后一个 uop 才写真正的 vd，中间结果一律走 v32。
      UST_VEC_VFREDOSUM: begin
        // uop 总数见 §5b 的 vfredosum_len。
        // 三种 SEW 的循环体形状完全一样，只差「每几个 uop 换一个源寄存器」(STEP)
        // 与折叠标志落在哪一级。STEP 必须是编译期常数（要拿它做 i/STEP 下标），
        // 所以按 vsew 分三段写；osum_len 只出现在比较里，可以是运行期量。
        case (vsew_r)
          VSEW_E64:
            for (int i = 0; i < 16; i++) if (i < int'(vfredosum_len)) begin
              cs[i].lsrc[0] = (i == 0) ? src1 : VTMP;
              cs[i].lsrc[1] = (i % 2 == 0) ? (src2 + 6'(i / 2)) : VTMP;
              cs[i].lsrc[2] = (i % 2 == 0) ? (src2 + 6'(i / 2))
                            : (i == int'(vfredosum_len) - 1) ? vdst : VTMP;
              cs[i].ldest   = (i == int'(vfredosum_len) - 1) ? vdst : VTMP;
              cs[i].vpu_fpu_isFoldTo1_2 = (i % 2 != 0);
              cs[i].uopIdx  = 7'(i);
            end
          VSEW_E32:
            for (int i = 0; i < 32; i++) if (i < int'(vfredosum_len)) begin
              cs[i].lsrc[0] = (i == 0) ? src1 : VTMP;
              cs[i].lsrc[1] = (i % 4 == 0) ? (src2 + 6'(i / 4)) : VTMP;
              cs[i].lsrc[2] = (i % 4 == 0) ? (src2 + 6'(i / 4))
                            : (i == int'(vfredosum_len) - 1) ? vdst
                            : (i % 4 == 1) ? (is_widen_ordered_red ? (src2 + 6'(i / 4)) : VTMP)
                            : VTMP;
              cs[i].ldest   = (i == int'(vfredosum_len) - 1) ? vdst : VTMP;
              cs[i].vpu_fpu_isFoldTo1_2 =  is_widen_ordered_red && (i % 4 != 0);
              cs[i].vpu_fpu_isFoldTo1_4 = !is_widen_ordered_red && (i % 4 != 0);
              cs[i].uopIdx  = 7'(i);
            end
          VSEW_E16:
            for (int i = 0; i < 64; i++) if (i < int'(vfredosum_len)) begin
              cs[i].lsrc[0] = (i == 0) ? src1 : VTMP;
              cs[i].lsrc[1] = (i % 8 == 0) ? (src2 + 6'(i / 8)) : VTMP;
              cs[i].lsrc[2] = (i % 8 == 0) ? (src2 + 6'(i / 8))
                            : (i == int'(vfredosum_len) - 1) ? vdst
                            : (i % 8 == 1) ? (is_widen_ordered_red ? (src2 + 6'(i / 8)) : VTMP)
                            : VTMP;
              cs[i].ldest   = (i == int'(vfredosum_len) - 1) ? vdst : VTMP;
              cs[i].vpu_fpu_isFoldTo1_4 =  is_widen_ordered_red && (i % 8 != 0);
              cs[i].vpu_fpu_isFoldTo1_8 = !is_widen_ordered_red && (i % 8 != 0);
              cs[i].uopIdx  = 7'(i);
            end
          default: ;
        endcase
      end

      // ===== vslideup：每个目的寄存器要把「若干个源寄存器」依次叠进来 =====
      // 第 i 个目的寄存器需要 i+1 个 uop（源 j = 0..i），中间结果在 v32+j 之间接力，
      // 最后一个 uop 才写 vd+i。uop 总数 = 1 + 8*9/2 = 37。
      UST_VEC_SLIDEUP: begin
        cs[0].srcType[0] = src1_is_imm ? ST_IMM : ST_XP;
        cs[0].srcType[1] = ST_IMM;
        cs[0].srcType[2] = ST_IMM;
        cs[0].lsrc[1]    = 6'd0;
        cs[0].ldest      = VTMP;
        cs[0].fuType     = FU_I2V;
        // ★这里是 imm2Vec/i2Vec（不 dup），与上面 VEC_VXV 那族的 Dup 版本不同★
        cs[0].fuOpType   = {4'd0, src1_is_imm ? IF2V_IMM2VEC : IF2V_I2VEC, vsew_r};
        cs[0].vecWen     = 1'b1;
        for (int i = 0; i < MAX_VLMUL; i++) begin
          for (int j = 0; j <= i; j++) begin
            cs[i * (i + 1) / 2 + j + 1].srcType[0] = ST_VP;
            cs[i * (i + 1) / 2 + j + 1].lsrc[0]    = VTMP;
            cs[i * (i + 1) / 2 + j + 1].lsrc[1]    = src2 + 6'(j);
            // 第一个 uop 读旧 vd，之后读上一个 uop 留在 v32+j 的中间结果
            cs[i * (i + 1) / 2 + j + 1].lsrc[2]    = (j == 0) ? (vdst + 6'(i))
                                                              : (VTMP + 6'(j));
            // 最后一个 uop 写 vd，之前的写 v32+j+1
            cs[i * (i + 1) / 2 + j + 1].ldest      = (j == i) ? (vdst + 6'(i))
                                                              : (VTMP + 6'(j + 1));
            cs[i * (i + 1) / 2 + j + 1].uopIdx     = 7'(i * (i + 1) / 2 + j);
          end
        end
      end

      // ===== vslidedown：形状与 vslideup 对称，但**从后往前**排 uop =====
      // Chisel 写的是 `csBundle(numOfUop - K)`，K 是编译期常数而 numOfUop 是运行期
      // 量 —— 下标越界时 Chisel 什么都不写，所以这里写成「逐项比较下标」。
      // 另外这一族还带 `when(i.U < lmul)`：LMUL 小于 8 时后面几组根本不产生 uop。
      UST_VEC_SLIDEDOWN: begin
        cs[0].srcType[0] = src1_is_imm ? ST_IMM : ST_XP;
        cs[0].srcType[1] = ST_IMM;
        cs[0].srcType[2] = ST_IMM;
        cs[0].lsrc[1]    = 6'd0;
        cs[0].ldest      = VTMP;
        cs[0].fuType     = FU_I2V;
        cs[0].fuOpType   = {4'd0, src1_is_imm ? IF2V_IMM2VEC : IF2V_I2VEC, vsew_r};
        cs[0].vecWen     = 1'b1;
        for (int i = 0; i < MAX_VLMUL; i++) begin
          for (int j = i; j >= 0; j--) begin
            if (i < int'(lmul)) begin
              for (int t = 0; t < MAX_UOP; t++) begin
                if (7'(t) == num_of_uop - 7'(i * (i + 1) / 2 + i - j + 1)) begin
                  cs[t].srcType[0] = ST_VP;
                  cs[t].lsrc[0]    = VTMP;
                  cs[t].lsrc[1]    = src2 + {2'b00, lmul} - 6'd1 - 6'(j);
                  cs[t].lsrc[2]    = (j == 0) ? (vdst + {2'b00, lmul} - 6'd1 - 6'(i))
                                              : (VTMP + 6'(j));
                  cs[t].ldest      = (j == i) ? (vdst + {2'b00, lmul} - 6'd1 - 6'(i))
                                              : (VTMP + 6'(j + 1));
                  cs[t].uopIdx     = num_of_uop - 7'(i * (i + 1) / 2 + i - j + 2);
                end
              end
            end
          end
        end
      end

      // ===== VEC_M0X：掩码 → 整数（vcpop.m / vfirst.m）=====
      // 8 个 uop 串成一条链（第 i 个读第 i-1 个的结果），最后一个把结果写进整数
      // 寄存器 rd。★i=0 时 lsrc(0) 是 VTMP-1 = v31★ —— Chisel 在**详细描述期**算
      // `VECTOR_TMP_REG_LMUL + i - 1`，i=0 得 31，不是「回绕」也不是 DontCare。
      UST_VEC_M0X: begin
        for (int i = 0; i < MAX_VLMUL; i++) begin
          cs[i].srcType[0] = (i == 0) ? ST_IMM : ST_VP;   // 第 0 个没有前驱：DC
          cs[i].srcType[1] = ST_VP;
          cs[i].rfWen      = 1'b0;
          cs[i].fpWen      = 1'b0;
          cs[i].vecWen     = 1'b1;
          cs[i].lsrc[0]    = VTMP + 6'(i) - 6'd1;
          cs[i].lsrc[1]    = src2;
          cs[i].ldest      = VTMP + 6'(i);
          cs[i].uopIdx     = 7'(i);
        end
        for (int i = 0; i < MAX_UOP; i++) begin
          if (7'(i) == last_uop_idx) begin
            cs[i].rfWen  = (vdst != 6'd0);   // rd 是 x0 就别写了
            cs[i].fpWen  = 1'b0;
            cs[i].vecWen = 1'b0;
            cs[i].ldest  = vdst;
          end
        end
      end

      // ===== VEC_MVV：掩码 → 向量（viota.m）=====
      // 每组两个 uop：一个写 vd+i（真正的结果），一个写 v32+i（给下一组当前缀和）。
      UST_VEC_MVV: begin
        for (int i = 0; i < MAX_VLMUL; i++) begin
          cs[i * 2 + 0].srcType[0] = (i == 0) ? ST_IMM : ST_VP;
          cs[i * 2 + 0].srcType[1] = ST_VP;
          cs[i * 2 + 0].lsrc[0]    = VTMP + 6'(i) - 6'd1;
          cs[i * 2 + 0].lsrc[1]    = src2;
          cs[i * 2 + 0].lsrc[2]    = vdst + 6'(i);
          cs[i * 2 + 0].ldest      = vdst + 6'(i);
          cs[i * 2 + 0].uopIdx     = 7'(i * 2 + 0);

          cs[i * 2 + 1].srcType[0] = (i == 0) ? ST_IMM : ST_VP;
          cs[i * 2 + 1].srcType[1] = ST_VP;
          cs[i * 2 + 1].lsrc[0]    = VTMP + 6'(i) - 6'd1;
          cs[i * 2 + 1].lsrc[1]    = src2;
          cs[i * 2 + 1].ldest      = VTMP + 6'(i);
          cs[i * 2 + 1].uopIdx     = 7'(i * 2 + 1);
        end
      end

      // ===== VEC_VWW：加宽归约 vwredsum 等 =====
      // 前 lmul 个 uop 把每个源寄存器自己归约一次；之后的 uop 两两合并中间结果；
      // 最后一个 uop 再与 vs1[0] 合并写 vd。
      UST_VEC_VWW: begin
        for (int i = 0; i < MAX_VLMUL * 2; i++) begin
          cs[i].srcType[2] = ST_IMM;                    // SrcType.DC
          if (i < int'(lmul)) begin
            cs[i].lsrc[0] = src2 + 6'(i);
            cs[i].lsrc[1] = src2 + 6'(i);
          end else begin
            // 第 (i-lmul) 对中间结果：v32 + 2*(i-lmul) 与 +1
            cs[i].lsrc[0] = VTMP + {1'b0, 4'(4'(i) - lmul), 1'b0} + 6'd1;
            cs[i].lsrc[1] = VTMP + {1'b0, 4'(4'(i) - lmul), 1'b0};
          end
          cs[i].ldest  = VTMP + 6'(i);
          cs[i].uopIdx = 7'(i);
        end
        for (int i = 0; i < MAX_UOP; i++) begin
          if (7'(i) == last_uop_idx) begin
            cs[i].srcType[2] = ST_VP;
            cs[i].lsrc[0]    = src1;
            cs[i].lsrc[2]    = vdst;
            cs[i].ldest      = vdst;
          end
        end
      end

      // ===== vrgather.vv/.vi：每个目的寄存器都要扫过**全部**源寄存器 =====
      // 所以 uop 数是 LMUL 的平方（8×8 = 64，本模块 65 的上限也卡在这里）。
      // 内层 j 走完一圈才写一次真 vd，中间接力用 v32+j。
      UST_VEC_RGATHER: begin
        case (vlmul_r)
          VLMUL_M2: for (int i = 0; i < 2; i++) for (int j = 0; j < 2; j++) begin
            cs[i * 2 + j].lsrc[0] = src1 + 6'(i);
            cs[i * 2 + j].lsrc[1] = src2 + 6'(j);
            cs[i * 2 + j].lsrc[2] = (j == 0) ? (vdst + 6'(i)) : (VTMP + 6'(j - 1));
            cs[i * 2 + j].ldest   = (j == 1) ? (vdst + 6'(i)) : (VTMP + 6'(j));
            cs[i * 2 + j].uopIdx  = 7'(i * 2 + j);
          end
          VLMUL_M4: for (int i = 0; i < 4; i++) for (int j = 0; j < 4; j++) begin
            cs[i * 4 + j].lsrc[0] = src1 + 6'(i);
            cs[i * 4 + j].lsrc[1] = src2 + 6'(j);
            cs[i * 4 + j].lsrc[2] = (j == 0) ? (vdst + 6'(i)) : (VTMP + 6'(j - 1));
            cs[i * 4 + j].ldest   = (j == 3) ? (vdst + 6'(i)) : (VTMP + 6'(j));
            cs[i * 4 + j].uopIdx  = 7'(i * 4 + j);
          end
          VLMUL_M8: for (int i = 0; i < 8; i++) for (int j = 0; j < 8; j++) begin
            cs[i * 8 + j].lsrc[0] = src1 + 6'(i);
            cs[i * 8 + j].lsrc[1] = src2 + 6'(j);
            cs[i * 8 + j].lsrc[2] = (j == 0) ? (vdst + 6'(i)) : (VTMP + 6'(j - 1));
            cs[i * 8 + j].ldest   = (j == 7) ? (vdst + 6'(i)) : (VTMP + 6'(j));
            cs[i * 8 + j].uopIdx  = 7'(i * 8 + j);
          end
          default: ;                                  // LMUL≤1：一个 uop 就够，用默认值
        endcase
      end

      // ===== vrgather.vx/.vi：下标是标量，先搬进 v32，再按 LMUL 平方展开 =====
      // ★注意 Chisel 先无条件调用 len=1 的展开，再按 vlmul 用 len=2/4/8 覆盖★
      // 后写者胜，所以 len=1 只在 LMUL≤1 时留下痕迹。这里照抄这个顺序。
      UST_VEC_RGATHER_VX: begin
        cs[0].srcType[0] = src1_is_imm ? ST_IMM : ST_XP;
        cs[0].srcType[1] = ST_IMM;
        cs[0].srcType[2] = ST_IMM;
        cs[0].lsrc[1]    = 6'd0;
        cs[0].ldest      = VTMP;
        cs[0].fuType     = FU_I2V;
        cs[0].fuOpType   = {4'd0, src1_is_imm ? IF2V_IMM2VEC : IF2V_I2VEC, vsew_r};
        cs[0].rfWen      = 1'b0;
        cs[0].fpWen      = 1'b0;
        cs[0].vecWen     = 1'b1;
        // len = 1（无条件）
        cs[1].srcType[0] = ST_VP;
        cs[1].lsrc[0]    = VTMP;
        cs[1].lsrc[1]    = src2;
        cs[1].lsrc[2]    = vdst;
        cs[1].ldest      = vdst;
        cs[1].uopIdx     = 7'd0;
        case (vlmul_r)
          VLMUL_M2: for (int i = 0; i < 2; i++) for (int j = 0; j < 2; j++) begin
            cs[i * 2 + j + 1].srcType[0] = ST_VP;
            cs[i * 2 + j + 1].lsrc[0]    = VTMP;
            cs[i * 2 + j + 1].lsrc[1]    = src2 + 6'(j);
            cs[i * 2 + j + 1].lsrc[2]    = (j == 0) ? (vdst + 6'(i)) : (VTMP + 6'(j));
            cs[i * 2 + j + 1].ldest      = (j == 1) ? (vdst + 6'(i)) : (VTMP + 6'(j + 1));
            cs[i * 2 + j + 1].uopIdx     = 7'(i * 2 + j);
          end
          VLMUL_M4: for (int i = 0; i < 4; i++) for (int j = 0; j < 4; j++) begin
            cs[i * 4 + j + 1].srcType[0] = ST_VP;
            cs[i * 4 + j + 1].lsrc[0]    = VTMP;
            cs[i * 4 + j + 1].lsrc[1]    = src2 + 6'(j);
            cs[i * 4 + j + 1].lsrc[2]    = (j == 0) ? (vdst + 6'(i)) : (VTMP + 6'(j));
            cs[i * 4 + j + 1].ldest      = (j == 3) ? (vdst + 6'(i)) : (VTMP + 6'(j + 1));
            cs[i * 4 + j + 1].uopIdx     = 7'(i * 4 + j);
          end
          VLMUL_M8: for (int i = 0; i < 8; i++) for (int j = 0; j < 8; j++) begin
            cs[i * 8 + j + 1].srcType[0] = ST_VP;
            cs[i * 8 + j + 1].lsrc[0]    = VTMP;
            cs[i * 8 + j + 1].lsrc[1]    = src2 + 6'(j);
            cs[i * 8 + j + 1].lsrc[2]    = (j == 0) ? (vdst + 6'(i)) : (VTMP + 6'(j));
            cs[i * 8 + j + 1].ldest      = (j == 7) ? (vdst + 6'(i)) : (VTMP + 6'(j + 1));
            cs[i * 8 + j + 1].uopIdx     = 7'(i * 8 + j);
          end
          default: ;
        endcase
      end

      // ===== vrgatherei16.vv：下标 EEW 固定 16，与 SEW 不一定相等 =====
      // 下标寄存器组的规模 = LMUL×16/SEW，所以 SEW=8 时一个数据寄存器要配两个
      // 下标寄存器（每组拆成两个 uop），SEW=32/64 时反过来几个数据寄存器共用
      // 一个下标寄存器（src1 用 i/2、i/4）。
      // ★与 vrgather 一样，Chisel 先无条件跑 len=1，再按 vlmul 覆盖★
      // ★m8 那一支**没有** SEW=8 的分支★（下标要 16 组，超了），落到通用形态。
      UST_VEC_RGATHEREI16: begin
        // len = 1（无条件）
        case (vsew_r)
          VSEW_E8: begin
            cs[0].lsrc[0] = src1;
            cs[0].lsrc[1] = src2;
            cs[0].lsrc[2] = vdst;
            cs[0].ldest   = VTMP;
            cs[0].uopIdx  = 7'd0;
            cs[1].lsrc[0] = src1 + 6'd1;
            cs[1].lsrc[1] = src2;
            cs[1].lsrc[2] = VTMP;
            cs[1].ldest   = vdst;
            cs[1].uopIdx  = 7'd1;
          end
          VSEW_E32, VSEW_E64: begin
            cs[0].lsrc[0] = src1;        // i/2 与 i/4 在 len=1 时都是 0
            cs[0].lsrc[1] = src2;
            cs[0].lsrc[2] = vdst;
            cs[0].ldest   = vdst;
            cs[0].uopIdx  = 7'd0;
          end
          default: begin                 // e16：通用形态
            cs[0].lsrc[0] = src1;
            cs[0].lsrc[1] = src2;
            cs[0].lsrc[2] = vdst;
            cs[0].ldest   = vdst;
            cs[0].uopIdx  = 7'd0;
          end
        endcase
        // 下面按 (vlmul, vsew) 逐个组合展开：uop 下标里的 len（= LMUL 覆盖的
        // 寄存器数）必须是编译期常数，所以不能把它写成变量，只能一档一档写。
        case (vlmul_r)
          VLMUL_M2: begin      // LMUL = 2
            case (vsew_r)
              // SEW=8：下标寄存器组是数据的两倍，每个 (i,j) 拆成两个 uop
              VSEW_E8:
                for (int i = 0; i < 2; i++) for (int j = 0; j < 2; j++) begin
                  cs[(i * 2 + j) * 2 + 0].lsrc[0] = src1 + 6'(i * 2 + 0);
                  cs[(i * 2 + j) * 2 + 0].lsrc[1] = src2 + 6'(j);
                  cs[(i * 2 + j) * 2 + 0].lsrc[2] = (j == 0) ? (vdst + 6'(i))
                                                              : (VTMP + 6'(j * 2 - 1));
                  cs[(i * 2 + j) * 2 + 0].ldest   = VTMP + 6'(j * 2);
                  cs[(i * 2 + j) * 2 + 0].uopIdx  = 7'((i * 2 + j) * 2 + 0);
                  cs[(i * 2 + j) * 2 + 1].lsrc[0] = src1 + 6'(i * 2 + 1);
                  cs[(i * 2 + j) * 2 + 1].lsrc[1] = src2 + 6'(j);
                  cs[(i * 2 + j) * 2 + 1].lsrc[2] = VTMP + 6'(j * 2);
                  cs[(i * 2 + j) * 2 + 1].ldest   = (j == 2 - 1) ? (vdst + 6'(i))
                                                                  : (VTMP + 6'(j * 2 + 1));
                  cs[(i * 2 + j) * 2 + 1].uopIdx  = 7'((i * 2 + j) * 2 + 1);
                end
              // 两个数据寄存器共用一个下标寄存器
              VSEW_E32:
                for (int i = 0; i < 2; i++) for (int j = 0; j < 2; j++) begin
                  cs[i * 2 + j].lsrc[0] = src1 + 6'(i / 2);
                  cs[i * 2 + j].lsrc[1] = src2 + 6'(j);
                  cs[i * 2 + j].lsrc[2] = (j == 0) ? (vdst + 6'(i)) : (VTMP + 6'(j - 1));
                  cs[i * 2 + j].ldest   = (j == 2 - 1) ? (vdst + 6'(i)) : (VTMP + 6'(j));
                  cs[i * 2 + j].uopIdx  = 7'(i * 2 + j);
                end
              // 四个数据寄存器共用一个下标寄存器
              VSEW_E64:
                for (int i = 0; i < 2; i++) for (int j = 0; j < 2; j++) begin
                  cs[i * 2 + j].lsrc[0] = src1 + 6'(i / 4);
                  cs[i * 2 + j].lsrc[1] = src2 + 6'(j);
                  cs[i * 2 + j].lsrc[2] = (j == 0) ? (vdst + 6'(i)) : (VTMP + 6'(j - 1));
                  cs[i * 2 + j].ldest   = (j == 2 - 1) ? (vdst + 6'(i)) : (VTMP + 6'(j));
                  cs[i * 2 + j].uopIdx  = 7'(i * 2 + j);
                end
              // e16：下标与数据一一对应
              default:
                for (int i = 0; i < 2; i++) for (int j = 0; j < 2; j++) begin
                  cs[i * 2 + j].lsrc[0] = src1 + 6'(i);
                  cs[i * 2 + j].lsrc[1] = src2 + 6'(j);
                  cs[i * 2 + j].lsrc[2] = (j == 0) ? (vdst + 6'(i)) : (VTMP + 6'(j - 1));
                  cs[i * 2 + j].ldest   = (j == 2 - 1) ? (vdst + 6'(i)) : (VTMP + 6'(j));
                  cs[i * 2 + j].uopIdx  = 7'(i * 2 + j);
                end
            endcase
          end
          VLMUL_M4: begin      // LMUL = 4
            case (vsew_r)
              // SEW=8：下标寄存器组是数据的两倍，每个 (i,j) 拆成两个 uop
              VSEW_E8:
                for (int i = 0; i < 4; i++) for (int j = 0; j < 4; j++) begin
                  cs[(i * 4 + j) * 2 + 0].lsrc[0] = src1 + 6'(i * 2 + 0);
                  cs[(i * 4 + j) * 2 + 0].lsrc[1] = src2 + 6'(j);
                  cs[(i * 4 + j) * 2 + 0].lsrc[2] = (j == 0) ? (vdst + 6'(i))
                                                              : (VTMP + 6'(j * 2 - 1));
                  cs[(i * 4 + j) * 2 + 0].ldest   = VTMP + 6'(j * 2);
                  cs[(i * 4 + j) * 2 + 0].uopIdx  = 7'((i * 4 + j) * 2 + 0);
                  cs[(i * 4 + j) * 2 + 1].lsrc[0] = src1 + 6'(i * 2 + 1);
                  cs[(i * 4 + j) * 2 + 1].lsrc[1] = src2 + 6'(j);
                  cs[(i * 4 + j) * 2 + 1].lsrc[2] = VTMP + 6'(j * 2);
                  cs[(i * 4 + j) * 2 + 1].ldest   = (j == 4 - 1) ? (vdst + 6'(i))
                                                                  : (VTMP + 6'(j * 2 + 1));
                  cs[(i * 4 + j) * 2 + 1].uopIdx  = 7'((i * 4 + j) * 2 + 1);
                end
              // 两个数据寄存器共用一个下标寄存器
              VSEW_E32:
                for (int i = 0; i < 4; i++) for (int j = 0; j < 4; j++) begin
                  cs[i * 4 + j].lsrc[0] = src1 + 6'(i / 2);
                  cs[i * 4 + j].lsrc[1] = src2 + 6'(j);
                  cs[i * 4 + j].lsrc[2] = (j == 0) ? (vdst + 6'(i)) : (VTMP + 6'(j - 1));
                  cs[i * 4 + j].ldest   = (j == 4 - 1) ? (vdst + 6'(i)) : (VTMP + 6'(j));
                  cs[i * 4 + j].uopIdx  = 7'(i * 4 + j);
                end
              // 四个数据寄存器共用一个下标寄存器
              VSEW_E64:
                for (int i = 0; i < 4; i++) for (int j = 0; j < 4; j++) begin
                  cs[i * 4 + j].lsrc[0] = src1 + 6'(i / 4);
                  cs[i * 4 + j].lsrc[1] = src2 + 6'(j);
                  cs[i * 4 + j].lsrc[2] = (j == 0) ? (vdst + 6'(i)) : (VTMP + 6'(j - 1));
                  cs[i * 4 + j].ldest   = (j == 4 - 1) ? (vdst + 6'(i)) : (VTMP + 6'(j));
                  cs[i * 4 + j].uopIdx  = 7'(i * 4 + j);
                end
              // e16：下标与数据一一对应
              default:
                for (int i = 0; i < 4; i++) for (int j = 0; j < 4; j++) begin
                  cs[i * 4 + j].lsrc[0] = src1 + 6'(i);
                  cs[i * 4 + j].lsrc[1] = src2 + 6'(j);
                  cs[i * 4 + j].lsrc[2] = (j == 0) ? (vdst + 6'(i)) : (VTMP + 6'(j - 1));
                  cs[i * 4 + j].ldest   = (j == 4 - 1) ? (vdst + 6'(i)) : (VTMP + 6'(j));
                  cs[i * 4 + j].uopIdx  = 7'(i * 4 + j);
                end
            endcase
          end
          VLMUL_M8: begin      // LMUL = 8
            case (vsew_r)
              // 两个数据寄存器共用一个下标寄存器
              VSEW_E32:
                for (int i = 0; i < 8; i++) for (int j = 0; j < 8; j++) begin
                  cs[i * 8 + j].lsrc[0] = src1 + 6'(i / 2);
                  cs[i * 8 + j].lsrc[1] = src2 + 6'(j);
                  cs[i * 8 + j].lsrc[2] = (j == 0) ? (vdst + 6'(i)) : (VTMP + 6'(j - 1));
                  cs[i * 8 + j].ldest   = (j == 8 - 1) ? (vdst + 6'(i)) : (VTMP + 6'(j));
                  cs[i * 8 + j].uopIdx  = 7'(i * 8 + j);
                end
              // 四个数据寄存器共用一个下标寄存器
              VSEW_E64:
                for (int i = 0; i < 8; i++) for (int j = 0; j < 8; j++) begin
                  cs[i * 8 + j].lsrc[0] = src1 + 6'(i / 4);
                  cs[i * 8 + j].lsrc[1] = src2 + 6'(j);
                  cs[i * 8 + j].lsrc[2] = (j == 0) ? (vdst + 6'(i)) : (VTMP + 6'(j - 1));
                  cs[i * 8 + j].ldest   = (j == 8 - 1) ? (vdst + 6'(i)) : (VTMP + 6'(j));
                  cs[i * 8 + j].uopIdx  = 7'(i * 8 + j);
                end
              // e16：下标与数据一一对应（m8 下 e8 也走这里，没有专门分支）
              default:
                for (int i = 0; i < 8; i++) for (int j = 0; j < 8; j++) begin
                  cs[i * 8 + j].lsrc[0] = src1 + 6'(i);
                  cs[i * 8 + j].lsrc[1] = src2 + 6'(j);
                  cs[i * 8 + j].lsrc[2] = (j == 0) ? (vdst + 6'(i)) : (VTMP + 6'(j - 1));
                  cs[i * 8 + j].ldest   = (j == 8 - 1) ? (vdst + 6'(i)) : (VTMP + 6'(j));
                  cs[i * 8 + j].uopIdx  = 7'(i * 8 + j);
                end
            endcase
          end
          default: ;                    // LMUL≤1：上面 len=1 那段已经写完
        endcase
      end

      // ===== vcompress.vm：把被掩码选中的元素压到一起 =====
      // 第 i 组要读前 i+1 个源寄存器（加一个「进位」寄存器），uop 数是三角形数。
      UST_VEC_COMPRESS: begin
        // 组数见 §5b 的 compress_len（LMUL≤1 时为 0，本分支什么都不写）
        for (int i = 0; i < 8; i++) begin
          for (int j = 0; j < 9; j++) begin
            // jlen：最后一组不需要那个多出来的「进位」uop
            if (i < int'(compress_len)
                && j < ((i == int'(compress_len) - 1) ? (i + 1) : (i + 2))) begin
              cs[i * (i + 3) / 2 + j].vecWen     = 1'b1;
              // ★j == i+1 的那个 uop 是「进位」uop，Chisel 把它的 srcType(0)/(2)
              //   赋成 DontCare —— 条件赋值里的 DontCare 在 FIRRTL 里等于**不赋值**,
              //   所以这里保持默认（= 原指令的 srcType），与 golden 一致。
              if (j != i + 1) begin
                cs[i * (i + 3) / 2 + j].srcType[0] = ST_VP;
                cs[i * (i + 3) / 2 + j].srcType[2] = ST_VP;
              end
              cs[i * (i + 3) / 2 + j].srcType[1] = ST_VP;
              cs[i * (i + 3) / 2 + j].lsrc[0]    = (i == 0) ? src1 : VTMP;
              cs[i * (i + 3) / 2 + j].lsrc[1]    = src2 + 6'(i);
              cs[i * (i + 3) / 2 + j].lsrc[2]    = (i == j) ? (vdst + 6'(i))
                                                            : (VTMP + 6'(j + 1));
              cs[i * (i + 3) / 2 + j].ldest      = (i == int'(compress_len) - 1) ? (vdst + 6'(j))
                                                 : (j == i + 1) ? VTMP
                                                                : (VTMP + 6'(j + 1));
              cs[i * (i + 3) / 2 + j].uopIdx     = 7'(i * (i + 3) / 2 + j);
            end
          end
        end
      end
      // ===== 向量访存四族：unit-stride / fault-only-first / strided / indexed =====
      // 共同点：uop0 先把基地址（整数 rs1）搬进 v32（fuOpType 固定按 e64 搬，
      // 因为地址是 64 位），后面每个 uop 处理一组数据寄存器。全部 uop 都要打
      // vlsInstr（后端据此把它们送进 LSU 而不是向量算术单元）。
      // 段访存（一条指令访问多个 field）要把整段做成不可打断：第一个 uop
      // waitForward、最后一个 uop blockBackward。

      UST_VEC_US_LDST: begin
        cs[0].srcType[0] = ST_XP;
        cs[0].srcType[1] = ST_IMM;
        cs[0].lsrc[1]    = 6'd0;
        cs[0].ldest      = VTMP;
        cs[0].fuType     = FU_I2V;
        cs[0].fuOpType   = {4'd0, IF2V_I2VEC, E64};
        cs[0].rfWen      = 1'b0;
        cs[0].fpWen      = 1'b0;
        cs[0].vecWen     = 1'b1;
        cs[0].vlsInstr   = 1'b1;
        for (int i = 0; i < MAX_VLMUL; i++) begin
          cs[i + 1].srcType[0] = ST_VP;
          cs[i + 1].lsrc[0]    = VTMP;
          cs[i + 1].lsrc[2]    = vdst + 6'(i);   // 旧 vd（load 要按掩码保留）
          cs[i + 1].ldest      = vdst + 6'(i);
          cs[i + 1].uopIdx     = 7'(i);
          cs[i + 1].vlsInstr   = 1'b1;
        end
        cs[0].waitForward = is_us_segment;
        for (int i = 0; i < MAX_UOP; i++)
          if (7'(i) == last_uop_idx) cs[i].blockBackward = is_us_segment;
      end

      UST_VEC_US_FF_LD: begin
        cs[0].srcType[0] = ST_XP;
        cs[0].srcType[1] = ST_IMM;
        cs[0].lsrc[1]    = 6'd0;
        cs[0].ldest      = VTMP;
        cs[0].fuType     = FU_I2V;
        cs[0].fuOpType   = {4'd0, IF2V_I2VEC, E64};
        cs[0].rfWen      = 1'b0;
        cs[0].fpWen      = 1'b0;
        cs[0].vecWen     = 1'b1;
        cs[0].vlsInstr   = 1'b1;
        for (int i = 0; i < MAX_VLMUL; i++) begin
          cs[i + 1].srcType[0] = ST_VP;
          cs[i + 1].lsrc[0]    = VTMP;
          cs[i + 1].lsrc[2]    = vdst + 6'(i);
          cs[i + 1].ldest      = vdst + 6'(i);
          cs[i + 1].uopIdx     = 7'(i);
          cs[i + 1].vlsInstr   = 1'b1;
        end
        cs[0].waitForward = is_us_segment;
        for (int i = 0; i < MAX_UOP; i++) begin
          if (7'(i) == last_uop_idx) begin
            cs[i].blockBackward = is_us_segment;
            // fault-only-first：最后一个 uop 负责读旧 vl、写新 vl
            cs[i].srcType[0] = ST_IMM;   // SrcType.no
            cs[i].srcType[1] = ST_IMM;
            cs[i].srcType[2] = ST_IMM;
            cs[i].srcType[3] = ST_IMM;
            cs[i].srcType[4] = ST_VP;
            // ★Chisel 这里还有 `lsrc(4) := Vl_IDX.U`，golden 无 lsrc_4 端口（见文件头 (a)）
            cs[i].vecWen     = 1'b0;
            cs[i].vlWen      = 1'b1;
            cs[i].ldest      = VL_IDX;
          end
        end
      end

      UST_VEC_S_LDST: begin
        cs[0].srcType[0] = ST_XP;
        cs[0].srcType[1] = ST_IMM;
        cs[0].lsrc[1]    = 6'd0;
        cs[0].ldest      = VTMP;
        cs[0].fuType     = FU_I2V;
        cs[0].fuOpType   = {4'd0, IF2V_I2VEC, E64};
        cs[0].rfWen      = 1'b0;
        cs[0].fpWen      = 1'b0;
        cs[0].vecWen     = 1'b1;
        cs[0].vlsInstr   = 1'b1;
        // uop1 再把「跨距」（也是整数寄存器）搬进 v33
        // ★源取的是**原指令译码出的 lsrc(1)**，不是指令字里的 rs2 域★
        cs[1].srcType[0] = ST_XP;
        cs[1].srcType[1] = ST_IMM;
        cs[1].lsrc[0]    = latched_q.lsrc[1];
        cs[1].lsrc[1]    = 6'd0;
        cs[1].ldest      = VTMP + 6'd1;
        cs[1].fuType     = FU_I2V;
        cs[1].fuOpType   = {4'd0, IF2V_I2VEC, E64};
        cs[1].rfWen      = 1'b0;
        cs[1].fpWen      = 1'b0;
        cs[1].vecWen     = 1'b1;
        cs[1].vlsInstr   = 1'b1;
        for (int i = 0; i < MAX_VLMUL; i++) begin
          cs[i + 2].srcType[0] = ST_VP;
          cs[i + 2].srcType[1] = ST_VP;
          cs[i + 2].lsrc[0]    = VTMP;
          cs[i + 2].lsrc[1]    = VTMP + 6'd1;
          cs[i + 2].lsrc[2]    = vdst + 6'(i);
          cs[i + 2].ldest      = vdst + 6'(i);
          cs[i + 2].uopIdx     = 7'(i);
          cs[i + 2].vlsInstr   = 1'b1;
        end
        cs[0].waitForward = is_sd_segment;
        for (int i = 0; i < MAX_UOP; i++)
          if (7'(i) == last_uop_idx) cs[i].blockBackward = is_sd_segment;
      end

      UST_VEC_I_LDST: begin
        cs[0].srcType[0] = ST_XP;
        cs[0].srcType[1] = ST_IMM;
        cs[0].lsrc[1]    = 6'd0;
        cs[0].ldest      = VTMP;
        cs[0].fuType     = FU_I2V;
        cs[0].fuOpType   = {4'd0, IF2V_I2VEC, E64};
        cs[0].rfWen      = 1'b0;
        cs[0].fpWen      = 1'b0;
        cs[0].vecWen     = 1'b1;
        cs[0].vlsInstr   = 1'b1;

        if (nf == 3'd0) begin
          // 非段索引访存：下标组与数据组的倍数可能不同，第 i 个 uop 该读 vs2 的
          // 第几个、写 vd 的第几个由 indexedLSUopTable 查出来（见那个模块的说明）。
          // Chisel 写成 Mux1H(UIntToOH(offset), src2+j)，就是「src2 + offset」。
          for (int i = 0; i < MAX_VLMUL; i++) begin
            cs[i + 1].srcType[0] = ST_VP;
            cs[i + 1].lsrc[0]    = VTMP;
            cs[i + 1].lsrc[1]    = src2 + {3'b000, idx_off_vs2[i]};
            cs[i + 1].srcType[2] = ST_VP;
            cs[i + 1].lsrc[2]    = vdst + {3'b000, idx_off_vd[i]};   // 旧 vd
            cs[i + 1].ldest      = vdst + {3'b000, idx_off_vd[i]};
            cs[i + 1].uopIdx     = 7'(i);
            cs[i + 1].vlsInstr   = 1'b1;
          end
        end else begin
          // 段索引访存：nf+1 个 field × lmul 组，总共用掉 lmul*nf 个数据寄存器；
          // 超出的那些 uop 不写向量寄存器堆（vecWen=0、srcType(2)=no）。
          // 参与的 (lmul, nf) 组合是有限的几种，Chisel 逐个列出来，这里照抄。
          // seg_data_regs 见 §5b：它为 0 表示这个 (lmul, nf) 组合 Chisel 里
          // 根本没有对应的展开，本段什么都不写。
          for (int i = 0; i < MAX_VLMUL; i++) begin
            if (seg_data_regs != 4'd0) begin
              cs[i + 1].srcType[0] = ST_VP;
              cs[i + 1].lsrc[0]    = VTMP;
              cs[i + 1].srcType[1] = ST_IMM;             // SrcType.no（下面还会被改）
              cs[i + 1].lsrc[1]    = src2 + 6'(i);
              cs[i + 1].srcType[2] = (i < int'(seg_data_regs)) ? ST_VP : ST_IMM;
              cs[i + 1].lsrc[2]    = vdst + 6'(i);
              cs[i + 1].ldest      = vdst + 6'(i);
              cs[i + 1].rfWen      = 1'b0;
              cs[i + 1].fpWen      = 1'b0;
              cs[i + 1].vecWen     = (i < int'(seg_data_regs));
              cs[i + 1].uopIdx     = 7'(i);
              cs[i + 1].vlsInstr   = 1'b1;
            end
          end
          // 再按下标组的倍数（simple_emul）决定前几个 uop 真的读下标寄存器
          for (int i = 0; i < MAX_VLMUL; i++) begin
            cs[i + 1].srcType[1] = (i < int'(seg_index_regs)) ? ST_VP : ST_IMM;
            cs[i + 1].lsrc[1]    = src2 + 6'(i);
          end
          // store 不写向量寄存器堆
          if (is_vstore)
            for (int i = 0; i < MAX_VLMUL; i++) cs[i + 1].vecWen = 1'b0;
        end
        cs[0].waitForward = is_ix_segment;
        for (int i = 0; i < MAX_UOP; i++)
          if (7'(i) == last_uop_idx) cs[i].blockBackward = is_ix_segment;
      end

      default: ;   // SCA_SIM / dummy / 未定义编码：整条指令就是一个 uop，用默认值
    endcase
  end

  // ---------------------------------------------------------------------------
  // §7 出口：修正、按路分组、状态机
  // ---------------------------------------------------------------------------
  // Chisel 的 fixedDecodedInst：整体照抄 csBundle，只把**最后一个 uop** 的
  // flushPipe 改回原指令的值 —— 前面 §6 开头为了「vstart≠0 要清 vstart」把
  // csBundle(0).flushPipe 打开过，这里是给最后一个 uop 的回收。
  uop_var_t fixed [MAX_UOP];
  always_comb begin
    for (int i = 0; i < MAX_UOP; i++) begin
      fixed[i] = cs[i];
      if (7'(i) == last_uop_idx) fixed[i].flushPipe = latched_q.flushPipe;
    end
  end

  // 65 个 uop 每拍吐 6 个：第 s 路固定吐下标 ≡ s (mod 6) 的那些，
  // 第 count 组就是下标 count*6 + s。count 是 4 位（0..15），而每一路最多只有
  // 11 组（第 5 路只有 10 组），越界的组 **Chisel 的 Vec 越界读语义 = 取第 0 项**，
  // golden 里也确实是拿该路的第 0 项去填 —— 不是 0，也不是最后一项。
  uop_var_t slot_tab [RENAME_W][COUNT_N];
  always_comb begin
    for (int s = 0; s < RENAME_W; s++) begin
      for (int k = 0; k < COUNT_N; k++) begin
        slot_tab[s][k] = (k * RENAME_W + s < MAX_UOP) ? fixed[k * RENAME_W + s]
                                                      : fixed[s];
      end
    end
  end

  // ---- 状态机：idle / active ----
  // uopRes 记「这条指令还剩几个 uop 没吐」，count 记「已经吐到第几组」。
  // 只有第 0 路的 ready 被看：Rename 要么收 6 个要么一个不收。
  logic       state_q;
  logic [6:0] uop_res_q;
  logic [3:0] count_q;

  logic [6:0] ready_counter, complex_num_full;
  logic       this_all_out;
  assign ready_counter    = out0_ready ? 7'd6 : 7'd0;
  assign this_all_out     = (uop_res_q <= ready_counter);
  assign complex_num_full = (uop_res_q > ready_counter) ? ready_counter : uop_res_q;

  assign in_ready    = ~state_q | (state_q & this_all_out);
  assign complex_num = state_q ? complex_num_full[2:0] : 3'd0;
  // ★golden 在「要不要 state 门控」上是不对称的，两边都照抄★
  //   complexNum 有一层 `state ? … : 0`，out_valid 没有（Chisel 就是 `complexNum > i`）。
  //   而**两层门控其实都是冗余的**：idle 态下 uopRes 恒为 0（复位清 0 / 离开 active
  //   时写 0 / redirect 时写 0 / idle 无新指令时保持 0），于是 complexNum 也恒为 0。
  //   负测把这件事钉成了断言：给 out_valid 加门控、或把 complexNum 的门控去掉，
  //   UT 都抓不到（verif/ut/DecodeUnitComp/mutants.py 的 EXPECTED_MISSED X1/X2）。
  //   既然抓不到，就更要**逐字照抄 golden**，不替它补齐也不替它化简。
  always_comb
    for (int i = 0; i < RENAME_W; i++)
      out_valid[i] = (complex_num_full > 7'(i));

  // ★3 个异步高有效复位寄存器，复位值全 0；本模块没有非零复位值★
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      state_q   <= 1'b0;
      uop_res_q <= 7'd0;
      count_q   <= 4'd0;
    end else begin
      state_q <= ~redirect & (state_q ? (~this_all_out | in_valid)
                                      : (in_valid | state_q));
      // 优先级逐条照抄 golden 的 if-else 链：冲刷 > 本拍吐完 > 反压 > 空闲进新指令
      if (redirect) begin
        uop_res_q <= 7'd0;
        count_q   <= 4'd0;
      end else if (state_q) begin
        if (this_all_out) begin
          uop_res_q <= in_valid ? in_uop_info.numOfUop : 7'd0;
          count_q   <= 4'd0;
        end else begin
          uop_res_q <= uop_res_q - ready_counter;
          count_q   <= count_q + {3'b000, out0_ready};
        end
      end else if (in_valid) begin
        uop_res_q <= in_uop_info.numOfUop;
        count_q   <= 4'd0;
      end
    end
  end

  // ---- 输出 ----
  always_comb
    for (int s = 0; s < RENAME_W; s++)
      out_var[s] = slot_tab[s][count_q];

  // exceptionVec(EX_II)：原指令的非法位或上本模块自己判出来的向量非法。
  // 所有 uop 同值，所以只有一根线（golden 也只留了一根）。
  assign exception_ii = latched_q.exceptionVec[2] | illegal_inst;

endmodule : xs_DecodeUnitComp_core


// =============================================================================
// §8 DecodeUnitComp —— golden 同名 wrapper（748 个端口，与 G1 golden 逐位同名同序）
// =============================================================================
module DecodeUnitComp
  import decodeunitcomp_pkg::*;
(
  // BEGIN GENERATED(ports)
  input         clock,
  input         reset,
  input         io_redirect,
  input         io_vtypeBypass_illegal,
  input         io_vtypeBypass_vma,
  input         io_vtypeBypass_vta,
  input  [1:0]  io_vtypeBypass_vsew,
  input  [2:0]  io_vtypeBypass_vlmul,
  output        io_in_ready,
  input         io_in_valid,
  input  [31:0] io_in_bits_simpleDecodedInst_instr,
  input  [49:0] io_in_bits_simpleDecodedInst_pc,
  input  [9:0]  io_in_bits_simpleDecodedInst_foldpc,
  input         io_in_bits_simpleDecodedInst_exceptionVec_0,
  input         io_in_bits_simpleDecodedInst_exceptionVec_1,
  input         io_in_bits_simpleDecodedInst_exceptionVec_2,
  input         io_in_bits_simpleDecodedInst_exceptionVec_3,
  input         io_in_bits_simpleDecodedInst_exceptionVec_4,
  input         io_in_bits_simpleDecodedInst_exceptionVec_5,
  input         io_in_bits_simpleDecodedInst_exceptionVec_6,
  input         io_in_bits_simpleDecodedInst_exceptionVec_7,
  input         io_in_bits_simpleDecodedInst_exceptionVec_8,
  input         io_in_bits_simpleDecodedInst_exceptionVec_9,
  input         io_in_bits_simpleDecodedInst_exceptionVec_10,
  input         io_in_bits_simpleDecodedInst_exceptionVec_11,
  input         io_in_bits_simpleDecodedInst_exceptionVec_12,
  input         io_in_bits_simpleDecodedInst_exceptionVec_13,
  input         io_in_bits_simpleDecodedInst_exceptionVec_14,
  input         io_in_bits_simpleDecodedInst_exceptionVec_15,
  input         io_in_bits_simpleDecodedInst_exceptionVec_16,
  input         io_in_bits_simpleDecodedInst_exceptionVec_17,
  input         io_in_bits_simpleDecodedInst_exceptionVec_18,
  input         io_in_bits_simpleDecodedInst_exceptionVec_19,
  input         io_in_bits_simpleDecodedInst_exceptionVec_20,
  input         io_in_bits_simpleDecodedInst_exceptionVec_21,
  input         io_in_bits_simpleDecodedInst_exceptionVec_22,
  input         io_in_bits_simpleDecodedInst_exceptionVec_23,
  input         io_in_bits_simpleDecodedInst_isFetchMalAddr,
  input  [3:0]  io_in_bits_simpleDecodedInst_trigger,
  input         io_in_bits_simpleDecodedInst_preDecodeInfo_valid,
  input         io_in_bits_simpleDecodedInst_preDecodeInfo_isRVC,
  input  [1:0]  io_in_bits_simpleDecodedInst_preDecodeInfo_brType,
  input         io_in_bits_simpleDecodedInst_preDecodeInfo_isCall,
  input         io_in_bits_simpleDecodedInst_preDecodeInfo_isRet,
  input         io_in_bits_simpleDecodedInst_pred_taken,
  input         io_in_bits_simpleDecodedInst_crossPageIPFFix,
  input         io_in_bits_simpleDecodedInst_ftqPtr_flag,
  input  [5:0]  io_in_bits_simpleDecodedInst_ftqPtr_value,
  input  [3:0]  io_in_bits_simpleDecodedInst_ftqOffset,
  input         io_in_bits_simpleDecodedInst_satpFlushFirstFetchFault,
  input  [3:0]  io_in_bits_simpleDecodedInst_srcType_0,
  input  [3:0]  io_in_bits_simpleDecodedInst_srcType_1,
  input  [3:0]  io_in_bits_simpleDecodedInst_srcType_2,
  input  [3:0]  io_in_bits_simpleDecodedInst_srcType_3,
  input  [3:0]  io_in_bits_simpleDecodedInst_srcType_4,
  input  [5:0]  io_in_bits_simpleDecodedInst_lsrc_0,
  input  [5:0]  io_in_bits_simpleDecodedInst_lsrc_1,
  input  [5:0]  io_in_bits_simpleDecodedInst_lsrc_2,
  input  [5:0]  io_in_bits_simpleDecodedInst_ldest,
  input  [34:0] io_in_bits_simpleDecodedInst_fuType,
  input  [8:0]  io_in_bits_simpleDecodedInst_fuOpType,
  input         io_in_bits_simpleDecodedInst_rfWen,
  input         io_in_bits_simpleDecodedInst_fpWen,
  input         io_in_bits_simpleDecodedInst_vecWen,
  input         io_in_bits_simpleDecodedInst_isXSTrap,
  input         io_in_bits_simpleDecodedInst_waitForward,
  input         io_in_bits_simpleDecodedInst_blockBackward,
  input         io_in_bits_simpleDecodedInst_flushPipe,
  input         io_in_bits_simpleDecodedInst_canRobCompress,
  input  [3:0]  io_in_bits_simpleDecodedInst_selImm,
  input  [21:0] io_in_bits_simpleDecodedInst_imm,
  input  [1:0]  io_in_bits_simpleDecodedInst_fpu_typeTagOut,
  input         io_in_bits_simpleDecodedInst_fpu_wflags,
  input  [1:0]  io_in_bits_simpleDecodedInst_fpu_typ,
  input  [1:0]  io_in_bits_simpleDecodedInst_fpu_fmt,
  input  [2:0]  io_in_bits_simpleDecodedInst_fpu_rm,
  input         io_in_bits_simpleDecodedInst_vpu_vill,
  input         io_in_bits_simpleDecodedInst_vpu_vma,
  input         io_in_bits_simpleDecodedInst_vpu_vta,
  input  [1:0]  io_in_bits_simpleDecodedInst_vpu_vsew,
  input  [2:0]  io_in_bits_simpleDecodedInst_vpu_vlmul,
  input         io_in_bits_simpleDecodedInst_vpu_specVill,
  input         io_in_bits_simpleDecodedInst_vpu_specVma,
  input         io_in_bits_simpleDecodedInst_vpu_specVta,
  input  [1:0]  io_in_bits_simpleDecodedInst_vpu_specVsew,
  input  [2:0]  io_in_bits_simpleDecodedInst_vpu_specVlmul,
  input         io_in_bits_simpleDecodedInst_vpu_vm,
  input  [7:0]  io_in_bits_simpleDecodedInst_vpu_vstart,
  input  [2:0]  io_in_bits_simpleDecodedInst_vpu_nf,
  input  [1:0]  io_in_bits_simpleDecodedInst_vpu_veew,
  input         io_in_bits_simpleDecodedInst_vpu_isReverse,
  input         io_in_bits_simpleDecodedInst_vpu_isExt,
  input         io_in_bits_simpleDecodedInst_vpu_isNarrow,
  input         io_in_bits_simpleDecodedInst_vpu_isDstMask,
  input         io_in_bits_simpleDecodedInst_vpu_isOpMask,
  input         io_in_bits_simpleDecodedInst_vpu_isDependOldVd,
  input         io_in_bits_simpleDecodedInst_vpu_isWritePartVd,
  input         io_in_bits_simpleDecodedInst_vpu_isVleff,
  input         io_in_bits_simpleDecodedInst_wfflags,
  input         io_in_bits_simpleDecodedInst_isMove,
  input  [5:0]  io_in_bits_simpleDecodedInst_uopSplitType,
  input         io_in_bits_simpleDecodedInst_isVset,
  input  [2:0]  io_in_bits_simpleDecodedInst_commitType,
  input  [34:0] io_in_bits_simpleDecodedInst_debug_fuType,
  input  [55:0] io_in_bits_simpleDecodedInst_debug_seqNum_seqNum,
  input  [7:0]  io_in_bits_simpleDecodedInst_debug_seqNum_uopIdx,
  input  [6:0]  io_in_bits_uopInfo_numOfUop,
  input  [6:0]  io_in_bits_uopInfo_numOfWB,
  input  [3:0]  io_in_bits_uopInfo_lmul,
  input         io_out_complexDecodedInsts_0_ready,
  output        io_out_complexDecodedInsts_0_valid,
  output [31:0] io_out_complexDecodedInsts_0_bits_instr,
  output [49:0] io_out_complexDecodedInsts_0_bits_pc,
  output [9:0]  io_out_complexDecodedInsts_0_bits_foldpc,
  output        io_out_complexDecodedInsts_0_bits_exceptionVec_0,
  output        io_out_complexDecodedInsts_0_bits_exceptionVec_1,
  output        io_out_complexDecodedInsts_0_bits_exceptionVec_2,
  output        io_out_complexDecodedInsts_0_bits_exceptionVec_3,
  output        io_out_complexDecodedInsts_0_bits_exceptionVec_4,
  output        io_out_complexDecodedInsts_0_bits_exceptionVec_5,
  output        io_out_complexDecodedInsts_0_bits_exceptionVec_6,
  output        io_out_complexDecodedInsts_0_bits_exceptionVec_7,
  output        io_out_complexDecodedInsts_0_bits_exceptionVec_8,
  output        io_out_complexDecodedInsts_0_bits_exceptionVec_9,
  output        io_out_complexDecodedInsts_0_bits_exceptionVec_10,
  output        io_out_complexDecodedInsts_0_bits_exceptionVec_11,
  output        io_out_complexDecodedInsts_0_bits_exceptionVec_12,
  output        io_out_complexDecodedInsts_0_bits_exceptionVec_13,
  output        io_out_complexDecodedInsts_0_bits_exceptionVec_14,
  output        io_out_complexDecodedInsts_0_bits_exceptionVec_15,
  output        io_out_complexDecodedInsts_0_bits_exceptionVec_16,
  output        io_out_complexDecodedInsts_0_bits_exceptionVec_17,
  output        io_out_complexDecodedInsts_0_bits_exceptionVec_18,
  output        io_out_complexDecodedInsts_0_bits_exceptionVec_19,
  output        io_out_complexDecodedInsts_0_bits_exceptionVec_20,
  output        io_out_complexDecodedInsts_0_bits_exceptionVec_21,
  output        io_out_complexDecodedInsts_0_bits_exceptionVec_22,
  output        io_out_complexDecodedInsts_0_bits_exceptionVec_23,
  output        io_out_complexDecodedInsts_0_bits_isFetchMalAddr,
  output [3:0]  io_out_complexDecodedInsts_0_bits_trigger,
  output        io_out_complexDecodedInsts_0_bits_preDecodeInfo_valid,
  output        io_out_complexDecodedInsts_0_bits_preDecodeInfo_isRVC,
  output [1:0]  io_out_complexDecodedInsts_0_bits_preDecodeInfo_brType,
  output        io_out_complexDecodedInsts_0_bits_preDecodeInfo_isCall,
  output        io_out_complexDecodedInsts_0_bits_preDecodeInfo_isRet,
  output        io_out_complexDecodedInsts_0_bits_pred_taken,
  output        io_out_complexDecodedInsts_0_bits_crossPageIPFFix,
  output        io_out_complexDecodedInsts_0_bits_ftqPtr_flag,
  output [5:0]  io_out_complexDecodedInsts_0_bits_ftqPtr_value,
  output [3:0]  io_out_complexDecodedInsts_0_bits_ftqOffset,
  output        io_out_complexDecodedInsts_0_bits_satpFlushFirstFetchFault,
  output [3:0]  io_out_complexDecodedInsts_0_bits_srcType_0,
  output [3:0]  io_out_complexDecodedInsts_0_bits_srcType_1,
  output [3:0]  io_out_complexDecodedInsts_0_bits_srcType_2,
  output [3:0]  io_out_complexDecodedInsts_0_bits_srcType_3,
  output [3:0]  io_out_complexDecodedInsts_0_bits_srcType_4,
  output [5:0]  io_out_complexDecodedInsts_0_bits_lsrc_0,
  output [5:0]  io_out_complexDecodedInsts_0_bits_lsrc_1,
  output [5:0]  io_out_complexDecodedInsts_0_bits_lsrc_2,
  output [5:0]  io_out_complexDecodedInsts_0_bits_ldest,
  output [34:0] io_out_complexDecodedInsts_0_bits_fuType,
  output [8:0]  io_out_complexDecodedInsts_0_bits_fuOpType,
  output        io_out_complexDecodedInsts_0_bits_rfWen,
  output        io_out_complexDecodedInsts_0_bits_fpWen,
  output        io_out_complexDecodedInsts_0_bits_vecWen,
  output        io_out_complexDecodedInsts_0_bits_vlWen,
  output        io_out_complexDecodedInsts_0_bits_isXSTrap,
  output        io_out_complexDecodedInsts_0_bits_waitForward,
  output        io_out_complexDecodedInsts_0_bits_blockBackward,
  output        io_out_complexDecodedInsts_0_bits_flushPipe,
  output        io_out_complexDecodedInsts_0_bits_canRobCompress,
  output [3:0]  io_out_complexDecodedInsts_0_bits_selImm,
  output [21:0] io_out_complexDecodedInsts_0_bits_imm,
  output [1:0]  io_out_complexDecodedInsts_0_bits_fpu_typeTagOut,
  output        io_out_complexDecodedInsts_0_bits_fpu_wflags,
  output [1:0]  io_out_complexDecodedInsts_0_bits_fpu_typ,
  output [1:0]  io_out_complexDecodedInsts_0_bits_fpu_fmt,
  output [2:0]  io_out_complexDecodedInsts_0_bits_fpu_rm,
  output        io_out_complexDecodedInsts_0_bits_vpu_vill,
  output        io_out_complexDecodedInsts_0_bits_vpu_vma,
  output        io_out_complexDecodedInsts_0_bits_vpu_vta,
  output [1:0]  io_out_complexDecodedInsts_0_bits_vpu_vsew,
  output [2:0]  io_out_complexDecodedInsts_0_bits_vpu_vlmul,
  output        io_out_complexDecodedInsts_0_bits_vpu_specVill,
  output        io_out_complexDecodedInsts_0_bits_vpu_specVma,
  output        io_out_complexDecodedInsts_0_bits_vpu_specVta,
  output [1:0]  io_out_complexDecodedInsts_0_bits_vpu_specVsew,
  output [2:0]  io_out_complexDecodedInsts_0_bits_vpu_specVlmul,
  output        io_out_complexDecodedInsts_0_bits_vpu_vm,
  output [7:0]  io_out_complexDecodedInsts_0_bits_vpu_vstart,
  output        io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_2,
  output        io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_4,
  output        io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_8,
  output [2:0]  io_out_complexDecodedInsts_0_bits_vpu_nf,
  output [1:0]  io_out_complexDecodedInsts_0_bits_vpu_veew,
  output        io_out_complexDecodedInsts_0_bits_vpu_isReverse,
  output        io_out_complexDecodedInsts_0_bits_vpu_isExt,
  output        io_out_complexDecodedInsts_0_bits_vpu_isNarrow,
  output        io_out_complexDecodedInsts_0_bits_vpu_isDstMask,
  output        io_out_complexDecodedInsts_0_bits_vpu_isOpMask,
  output        io_out_complexDecodedInsts_0_bits_vpu_isDependOldVd,
  output        io_out_complexDecodedInsts_0_bits_vpu_isWritePartVd,
  output        io_out_complexDecodedInsts_0_bits_vpu_isVleff,
  output        io_out_complexDecodedInsts_0_bits_vlsInstr,
  output        io_out_complexDecodedInsts_0_bits_wfflags,
  output        io_out_complexDecodedInsts_0_bits_isMove,
  output [6:0]  io_out_complexDecodedInsts_0_bits_uopIdx,
  output [5:0]  io_out_complexDecodedInsts_0_bits_uopSplitType,
  output        io_out_complexDecodedInsts_0_bits_isVset,
  output        io_out_complexDecodedInsts_0_bits_firstUop,
  output        io_out_complexDecodedInsts_0_bits_lastUop,
  output [6:0]  io_out_complexDecodedInsts_0_bits_numUops,
  output [6:0]  io_out_complexDecodedInsts_0_bits_numWB,
  output [2:0]  io_out_complexDecodedInsts_0_bits_commitType,
  output [34:0] io_out_complexDecodedInsts_0_bits_debug_fuType,
  output [55:0] io_out_complexDecodedInsts_0_bits_debug_seqNum_seqNum,
  output [7:0]  io_out_complexDecodedInsts_0_bits_debug_seqNum_uopIdx,
  output        io_out_complexDecodedInsts_1_valid,
  output [31:0] io_out_complexDecodedInsts_1_bits_instr,
  output [49:0] io_out_complexDecodedInsts_1_bits_pc,
  output [9:0]  io_out_complexDecodedInsts_1_bits_foldpc,
  output        io_out_complexDecodedInsts_1_bits_exceptionVec_0,
  output        io_out_complexDecodedInsts_1_bits_exceptionVec_1,
  output        io_out_complexDecodedInsts_1_bits_exceptionVec_2,
  output        io_out_complexDecodedInsts_1_bits_exceptionVec_3,
  output        io_out_complexDecodedInsts_1_bits_exceptionVec_4,
  output        io_out_complexDecodedInsts_1_bits_exceptionVec_5,
  output        io_out_complexDecodedInsts_1_bits_exceptionVec_6,
  output        io_out_complexDecodedInsts_1_bits_exceptionVec_7,
  output        io_out_complexDecodedInsts_1_bits_exceptionVec_8,
  output        io_out_complexDecodedInsts_1_bits_exceptionVec_9,
  output        io_out_complexDecodedInsts_1_bits_exceptionVec_10,
  output        io_out_complexDecodedInsts_1_bits_exceptionVec_11,
  output        io_out_complexDecodedInsts_1_bits_exceptionVec_12,
  output        io_out_complexDecodedInsts_1_bits_exceptionVec_13,
  output        io_out_complexDecodedInsts_1_bits_exceptionVec_14,
  output        io_out_complexDecodedInsts_1_bits_exceptionVec_15,
  output        io_out_complexDecodedInsts_1_bits_exceptionVec_16,
  output        io_out_complexDecodedInsts_1_bits_exceptionVec_17,
  output        io_out_complexDecodedInsts_1_bits_exceptionVec_18,
  output        io_out_complexDecodedInsts_1_bits_exceptionVec_19,
  output        io_out_complexDecodedInsts_1_bits_exceptionVec_20,
  output        io_out_complexDecodedInsts_1_bits_exceptionVec_21,
  output        io_out_complexDecodedInsts_1_bits_exceptionVec_22,
  output        io_out_complexDecodedInsts_1_bits_exceptionVec_23,
  output        io_out_complexDecodedInsts_1_bits_isFetchMalAddr,
  output [3:0]  io_out_complexDecodedInsts_1_bits_trigger,
  output        io_out_complexDecodedInsts_1_bits_preDecodeInfo_valid,
  output        io_out_complexDecodedInsts_1_bits_preDecodeInfo_isRVC,
  output [1:0]  io_out_complexDecodedInsts_1_bits_preDecodeInfo_brType,
  output        io_out_complexDecodedInsts_1_bits_preDecodeInfo_isCall,
  output        io_out_complexDecodedInsts_1_bits_preDecodeInfo_isRet,
  output        io_out_complexDecodedInsts_1_bits_pred_taken,
  output        io_out_complexDecodedInsts_1_bits_crossPageIPFFix,
  output        io_out_complexDecodedInsts_1_bits_ftqPtr_flag,
  output [5:0]  io_out_complexDecodedInsts_1_bits_ftqPtr_value,
  output [3:0]  io_out_complexDecodedInsts_1_bits_ftqOffset,
  output        io_out_complexDecodedInsts_1_bits_satpFlushFirstFetchFault,
  output [3:0]  io_out_complexDecodedInsts_1_bits_srcType_0,
  output [3:0]  io_out_complexDecodedInsts_1_bits_srcType_1,
  output [3:0]  io_out_complexDecodedInsts_1_bits_srcType_2,
  output [3:0]  io_out_complexDecodedInsts_1_bits_srcType_3,
  output [3:0]  io_out_complexDecodedInsts_1_bits_srcType_4,
  output [5:0]  io_out_complexDecodedInsts_1_bits_lsrc_0,
  output [5:0]  io_out_complexDecodedInsts_1_bits_lsrc_1,
  output [5:0]  io_out_complexDecodedInsts_1_bits_lsrc_2,
  output [5:0]  io_out_complexDecodedInsts_1_bits_ldest,
  output [34:0] io_out_complexDecodedInsts_1_bits_fuType,
  output [8:0]  io_out_complexDecodedInsts_1_bits_fuOpType,
  output        io_out_complexDecodedInsts_1_bits_rfWen,
  output        io_out_complexDecodedInsts_1_bits_fpWen,
  output        io_out_complexDecodedInsts_1_bits_vecWen,
  output        io_out_complexDecodedInsts_1_bits_vlWen,
  output        io_out_complexDecodedInsts_1_bits_isXSTrap,
  output        io_out_complexDecodedInsts_1_bits_waitForward,
  output        io_out_complexDecodedInsts_1_bits_blockBackward,
  output        io_out_complexDecodedInsts_1_bits_flushPipe,
  output        io_out_complexDecodedInsts_1_bits_canRobCompress,
  output [3:0]  io_out_complexDecodedInsts_1_bits_selImm,
  output [21:0] io_out_complexDecodedInsts_1_bits_imm,
  output [1:0]  io_out_complexDecodedInsts_1_bits_fpu_typeTagOut,
  output        io_out_complexDecodedInsts_1_bits_fpu_wflags,
  output [1:0]  io_out_complexDecodedInsts_1_bits_fpu_typ,
  output [1:0]  io_out_complexDecodedInsts_1_bits_fpu_fmt,
  output [2:0]  io_out_complexDecodedInsts_1_bits_fpu_rm,
  output        io_out_complexDecodedInsts_1_bits_vpu_vill,
  output        io_out_complexDecodedInsts_1_bits_vpu_vma,
  output        io_out_complexDecodedInsts_1_bits_vpu_vta,
  output [1:0]  io_out_complexDecodedInsts_1_bits_vpu_vsew,
  output [2:0]  io_out_complexDecodedInsts_1_bits_vpu_vlmul,
  output        io_out_complexDecodedInsts_1_bits_vpu_specVill,
  output        io_out_complexDecodedInsts_1_bits_vpu_specVma,
  output        io_out_complexDecodedInsts_1_bits_vpu_specVta,
  output [1:0]  io_out_complexDecodedInsts_1_bits_vpu_specVsew,
  output [2:0]  io_out_complexDecodedInsts_1_bits_vpu_specVlmul,
  output        io_out_complexDecodedInsts_1_bits_vpu_vm,
  output [7:0]  io_out_complexDecodedInsts_1_bits_vpu_vstart,
  output        io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_2,
  output        io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_4,
  output        io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_8,
  output [2:0]  io_out_complexDecodedInsts_1_bits_vpu_nf,
  output [1:0]  io_out_complexDecodedInsts_1_bits_vpu_veew,
  output        io_out_complexDecodedInsts_1_bits_vpu_isReverse,
  output        io_out_complexDecodedInsts_1_bits_vpu_isExt,
  output        io_out_complexDecodedInsts_1_bits_vpu_isNarrow,
  output        io_out_complexDecodedInsts_1_bits_vpu_isDstMask,
  output        io_out_complexDecodedInsts_1_bits_vpu_isOpMask,
  output        io_out_complexDecodedInsts_1_bits_vpu_isDependOldVd,
  output        io_out_complexDecodedInsts_1_bits_vpu_isWritePartVd,
  output        io_out_complexDecodedInsts_1_bits_vpu_isVleff,
  output        io_out_complexDecodedInsts_1_bits_vlsInstr,
  output        io_out_complexDecodedInsts_1_bits_wfflags,
  output        io_out_complexDecodedInsts_1_bits_isMove,
  output [6:0]  io_out_complexDecodedInsts_1_bits_uopIdx,
  output [5:0]  io_out_complexDecodedInsts_1_bits_uopSplitType,
  output        io_out_complexDecodedInsts_1_bits_isVset,
  output        io_out_complexDecodedInsts_1_bits_lastUop,
  output [6:0]  io_out_complexDecodedInsts_1_bits_numUops,
  output [6:0]  io_out_complexDecodedInsts_1_bits_numWB,
  output [2:0]  io_out_complexDecodedInsts_1_bits_commitType,
  output [34:0] io_out_complexDecodedInsts_1_bits_debug_fuType,
  output [55:0] io_out_complexDecodedInsts_1_bits_debug_seqNum_seqNum,
  output [7:0]  io_out_complexDecodedInsts_1_bits_debug_seqNum_uopIdx,
  output        io_out_complexDecodedInsts_2_valid,
  output [31:0] io_out_complexDecodedInsts_2_bits_instr,
  output [49:0] io_out_complexDecodedInsts_2_bits_pc,
  output [9:0]  io_out_complexDecodedInsts_2_bits_foldpc,
  output        io_out_complexDecodedInsts_2_bits_exceptionVec_0,
  output        io_out_complexDecodedInsts_2_bits_exceptionVec_1,
  output        io_out_complexDecodedInsts_2_bits_exceptionVec_2,
  output        io_out_complexDecodedInsts_2_bits_exceptionVec_3,
  output        io_out_complexDecodedInsts_2_bits_exceptionVec_4,
  output        io_out_complexDecodedInsts_2_bits_exceptionVec_5,
  output        io_out_complexDecodedInsts_2_bits_exceptionVec_6,
  output        io_out_complexDecodedInsts_2_bits_exceptionVec_7,
  output        io_out_complexDecodedInsts_2_bits_exceptionVec_8,
  output        io_out_complexDecodedInsts_2_bits_exceptionVec_9,
  output        io_out_complexDecodedInsts_2_bits_exceptionVec_10,
  output        io_out_complexDecodedInsts_2_bits_exceptionVec_11,
  output        io_out_complexDecodedInsts_2_bits_exceptionVec_12,
  output        io_out_complexDecodedInsts_2_bits_exceptionVec_13,
  output        io_out_complexDecodedInsts_2_bits_exceptionVec_14,
  output        io_out_complexDecodedInsts_2_bits_exceptionVec_15,
  output        io_out_complexDecodedInsts_2_bits_exceptionVec_16,
  output        io_out_complexDecodedInsts_2_bits_exceptionVec_17,
  output        io_out_complexDecodedInsts_2_bits_exceptionVec_18,
  output        io_out_complexDecodedInsts_2_bits_exceptionVec_19,
  output        io_out_complexDecodedInsts_2_bits_exceptionVec_20,
  output        io_out_complexDecodedInsts_2_bits_exceptionVec_21,
  output        io_out_complexDecodedInsts_2_bits_exceptionVec_22,
  output        io_out_complexDecodedInsts_2_bits_exceptionVec_23,
  output        io_out_complexDecodedInsts_2_bits_isFetchMalAddr,
  output [3:0]  io_out_complexDecodedInsts_2_bits_trigger,
  output        io_out_complexDecodedInsts_2_bits_preDecodeInfo_valid,
  output        io_out_complexDecodedInsts_2_bits_preDecodeInfo_isRVC,
  output [1:0]  io_out_complexDecodedInsts_2_bits_preDecodeInfo_brType,
  output        io_out_complexDecodedInsts_2_bits_preDecodeInfo_isCall,
  output        io_out_complexDecodedInsts_2_bits_preDecodeInfo_isRet,
  output        io_out_complexDecodedInsts_2_bits_pred_taken,
  output        io_out_complexDecodedInsts_2_bits_crossPageIPFFix,
  output        io_out_complexDecodedInsts_2_bits_ftqPtr_flag,
  output [5:0]  io_out_complexDecodedInsts_2_bits_ftqPtr_value,
  output [3:0]  io_out_complexDecodedInsts_2_bits_ftqOffset,
  output        io_out_complexDecodedInsts_2_bits_satpFlushFirstFetchFault,
  output [3:0]  io_out_complexDecodedInsts_2_bits_srcType_0,
  output [3:0]  io_out_complexDecodedInsts_2_bits_srcType_1,
  output [3:0]  io_out_complexDecodedInsts_2_bits_srcType_2,
  output [3:0]  io_out_complexDecodedInsts_2_bits_srcType_3,
  output [3:0]  io_out_complexDecodedInsts_2_bits_srcType_4,
  output [5:0]  io_out_complexDecodedInsts_2_bits_lsrc_0,
  output [5:0]  io_out_complexDecodedInsts_2_bits_lsrc_1,
  output [5:0]  io_out_complexDecodedInsts_2_bits_lsrc_2,
  output [5:0]  io_out_complexDecodedInsts_2_bits_ldest,
  output [34:0] io_out_complexDecodedInsts_2_bits_fuType,
  output [8:0]  io_out_complexDecodedInsts_2_bits_fuOpType,
  output        io_out_complexDecodedInsts_2_bits_rfWen,
  output        io_out_complexDecodedInsts_2_bits_fpWen,
  output        io_out_complexDecodedInsts_2_bits_vecWen,
  output        io_out_complexDecodedInsts_2_bits_vlWen,
  output        io_out_complexDecodedInsts_2_bits_isXSTrap,
  output        io_out_complexDecodedInsts_2_bits_waitForward,
  output        io_out_complexDecodedInsts_2_bits_blockBackward,
  output        io_out_complexDecodedInsts_2_bits_flushPipe,
  output        io_out_complexDecodedInsts_2_bits_canRobCompress,
  output [3:0]  io_out_complexDecodedInsts_2_bits_selImm,
  output [21:0] io_out_complexDecodedInsts_2_bits_imm,
  output [1:0]  io_out_complexDecodedInsts_2_bits_fpu_typeTagOut,
  output        io_out_complexDecodedInsts_2_bits_fpu_wflags,
  output [1:0]  io_out_complexDecodedInsts_2_bits_fpu_typ,
  output [1:0]  io_out_complexDecodedInsts_2_bits_fpu_fmt,
  output [2:0]  io_out_complexDecodedInsts_2_bits_fpu_rm,
  output        io_out_complexDecodedInsts_2_bits_vpu_vill,
  output        io_out_complexDecodedInsts_2_bits_vpu_vma,
  output        io_out_complexDecodedInsts_2_bits_vpu_vta,
  output [1:0]  io_out_complexDecodedInsts_2_bits_vpu_vsew,
  output [2:0]  io_out_complexDecodedInsts_2_bits_vpu_vlmul,
  output        io_out_complexDecodedInsts_2_bits_vpu_specVill,
  output        io_out_complexDecodedInsts_2_bits_vpu_specVma,
  output        io_out_complexDecodedInsts_2_bits_vpu_specVta,
  output [1:0]  io_out_complexDecodedInsts_2_bits_vpu_specVsew,
  output [2:0]  io_out_complexDecodedInsts_2_bits_vpu_specVlmul,
  output        io_out_complexDecodedInsts_2_bits_vpu_vm,
  output [7:0]  io_out_complexDecodedInsts_2_bits_vpu_vstart,
  output        io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_2,
  output        io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_4,
  output        io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_8,
  output [2:0]  io_out_complexDecodedInsts_2_bits_vpu_nf,
  output [1:0]  io_out_complexDecodedInsts_2_bits_vpu_veew,
  output        io_out_complexDecodedInsts_2_bits_vpu_isReverse,
  output        io_out_complexDecodedInsts_2_bits_vpu_isExt,
  output        io_out_complexDecodedInsts_2_bits_vpu_isNarrow,
  output        io_out_complexDecodedInsts_2_bits_vpu_isDstMask,
  output        io_out_complexDecodedInsts_2_bits_vpu_isOpMask,
  output        io_out_complexDecodedInsts_2_bits_vpu_isDependOldVd,
  output        io_out_complexDecodedInsts_2_bits_vpu_isWritePartVd,
  output        io_out_complexDecodedInsts_2_bits_vpu_isVleff,
  output        io_out_complexDecodedInsts_2_bits_vlsInstr,
  output        io_out_complexDecodedInsts_2_bits_wfflags,
  output        io_out_complexDecodedInsts_2_bits_isMove,
  output [6:0]  io_out_complexDecodedInsts_2_bits_uopIdx,
  output [5:0]  io_out_complexDecodedInsts_2_bits_uopSplitType,
  output        io_out_complexDecodedInsts_2_bits_isVset,
  output        io_out_complexDecodedInsts_2_bits_lastUop,
  output [6:0]  io_out_complexDecodedInsts_2_bits_numUops,
  output [6:0]  io_out_complexDecodedInsts_2_bits_numWB,
  output [2:0]  io_out_complexDecodedInsts_2_bits_commitType,
  output [34:0] io_out_complexDecodedInsts_2_bits_debug_fuType,
  output [55:0] io_out_complexDecodedInsts_2_bits_debug_seqNum_seqNum,
  output [7:0]  io_out_complexDecodedInsts_2_bits_debug_seqNum_uopIdx,
  output        io_out_complexDecodedInsts_3_valid,
  output [31:0] io_out_complexDecodedInsts_3_bits_instr,
  output [49:0] io_out_complexDecodedInsts_3_bits_pc,
  output [9:0]  io_out_complexDecodedInsts_3_bits_foldpc,
  output        io_out_complexDecodedInsts_3_bits_exceptionVec_0,
  output        io_out_complexDecodedInsts_3_bits_exceptionVec_1,
  output        io_out_complexDecodedInsts_3_bits_exceptionVec_2,
  output        io_out_complexDecodedInsts_3_bits_exceptionVec_3,
  output        io_out_complexDecodedInsts_3_bits_exceptionVec_4,
  output        io_out_complexDecodedInsts_3_bits_exceptionVec_5,
  output        io_out_complexDecodedInsts_3_bits_exceptionVec_6,
  output        io_out_complexDecodedInsts_3_bits_exceptionVec_7,
  output        io_out_complexDecodedInsts_3_bits_exceptionVec_8,
  output        io_out_complexDecodedInsts_3_bits_exceptionVec_9,
  output        io_out_complexDecodedInsts_3_bits_exceptionVec_10,
  output        io_out_complexDecodedInsts_3_bits_exceptionVec_11,
  output        io_out_complexDecodedInsts_3_bits_exceptionVec_12,
  output        io_out_complexDecodedInsts_3_bits_exceptionVec_13,
  output        io_out_complexDecodedInsts_3_bits_exceptionVec_14,
  output        io_out_complexDecodedInsts_3_bits_exceptionVec_15,
  output        io_out_complexDecodedInsts_3_bits_exceptionVec_16,
  output        io_out_complexDecodedInsts_3_bits_exceptionVec_17,
  output        io_out_complexDecodedInsts_3_bits_exceptionVec_18,
  output        io_out_complexDecodedInsts_3_bits_exceptionVec_19,
  output        io_out_complexDecodedInsts_3_bits_exceptionVec_20,
  output        io_out_complexDecodedInsts_3_bits_exceptionVec_21,
  output        io_out_complexDecodedInsts_3_bits_exceptionVec_22,
  output        io_out_complexDecodedInsts_3_bits_exceptionVec_23,
  output        io_out_complexDecodedInsts_3_bits_isFetchMalAddr,
  output [3:0]  io_out_complexDecodedInsts_3_bits_trigger,
  output        io_out_complexDecodedInsts_3_bits_preDecodeInfo_valid,
  output        io_out_complexDecodedInsts_3_bits_preDecodeInfo_isRVC,
  output [1:0]  io_out_complexDecodedInsts_3_bits_preDecodeInfo_brType,
  output        io_out_complexDecodedInsts_3_bits_preDecodeInfo_isCall,
  output        io_out_complexDecodedInsts_3_bits_preDecodeInfo_isRet,
  output        io_out_complexDecodedInsts_3_bits_pred_taken,
  output        io_out_complexDecodedInsts_3_bits_crossPageIPFFix,
  output        io_out_complexDecodedInsts_3_bits_ftqPtr_flag,
  output [5:0]  io_out_complexDecodedInsts_3_bits_ftqPtr_value,
  output [3:0]  io_out_complexDecodedInsts_3_bits_ftqOffset,
  output        io_out_complexDecodedInsts_3_bits_satpFlushFirstFetchFault,
  output [3:0]  io_out_complexDecodedInsts_3_bits_srcType_0,
  output [3:0]  io_out_complexDecodedInsts_3_bits_srcType_1,
  output [3:0]  io_out_complexDecodedInsts_3_bits_srcType_2,
  output [3:0]  io_out_complexDecodedInsts_3_bits_srcType_3,
  output [3:0]  io_out_complexDecodedInsts_3_bits_srcType_4,
  output [5:0]  io_out_complexDecodedInsts_3_bits_lsrc_0,
  output [5:0]  io_out_complexDecodedInsts_3_bits_lsrc_1,
  output [5:0]  io_out_complexDecodedInsts_3_bits_lsrc_2,
  output [5:0]  io_out_complexDecodedInsts_3_bits_ldest,
  output [34:0] io_out_complexDecodedInsts_3_bits_fuType,
  output [8:0]  io_out_complexDecodedInsts_3_bits_fuOpType,
  output        io_out_complexDecodedInsts_3_bits_rfWen,
  output        io_out_complexDecodedInsts_3_bits_fpWen,
  output        io_out_complexDecodedInsts_3_bits_vecWen,
  output        io_out_complexDecodedInsts_3_bits_vlWen,
  output        io_out_complexDecodedInsts_3_bits_isXSTrap,
  output        io_out_complexDecodedInsts_3_bits_waitForward,
  output        io_out_complexDecodedInsts_3_bits_blockBackward,
  output        io_out_complexDecodedInsts_3_bits_flushPipe,
  output        io_out_complexDecodedInsts_3_bits_canRobCompress,
  output [3:0]  io_out_complexDecodedInsts_3_bits_selImm,
  output [21:0] io_out_complexDecodedInsts_3_bits_imm,
  output [1:0]  io_out_complexDecodedInsts_3_bits_fpu_typeTagOut,
  output        io_out_complexDecodedInsts_3_bits_fpu_wflags,
  output [1:0]  io_out_complexDecodedInsts_3_bits_fpu_typ,
  output [1:0]  io_out_complexDecodedInsts_3_bits_fpu_fmt,
  output [2:0]  io_out_complexDecodedInsts_3_bits_fpu_rm,
  output        io_out_complexDecodedInsts_3_bits_vpu_vill,
  output        io_out_complexDecodedInsts_3_bits_vpu_vma,
  output        io_out_complexDecodedInsts_3_bits_vpu_vta,
  output [1:0]  io_out_complexDecodedInsts_3_bits_vpu_vsew,
  output [2:0]  io_out_complexDecodedInsts_3_bits_vpu_vlmul,
  output        io_out_complexDecodedInsts_3_bits_vpu_specVill,
  output        io_out_complexDecodedInsts_3_bits_vpu_specVma,
  output        io_out_complexDecodedInsts_3_bits_vpu_specVta,
  output [1:0]  io_out_complexDecodedInsts_3_bits_vpu_specVsew,
  output [2:0]  io_out_complexDecodedInsts_3_bits_vpu_specVlmul,
  output        io_out_complexDecodedInsts_3_bits_vpu_vm,
  output [7:0]  io_out_complexDecodedInsts_3_bits_vpu_vstart,
  output        io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_2,
  output        io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_4,
  output        io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_8,
  output [2:0]  io_out_complexDecodedInsts_3_bits_vpu_nf,
  output [1:0]  io_out_complexDecodedInsts_3_bits_vpu_veew,
  output        io_out_complexDecodedInsts_3_bits_vpu_isReverse,
  output        io_out_complexDecodedInsts_3_bits_vpu_isExt,
  output        io_out_complexDecodedInsts_3_bits_vpu_isNarrow,
  output        io_out_complexDecodedInsts_3_bits_vpu_isDstMask,
  output        io_out_complexDecodedInsts_3_bits_vpu_isOpMask,
  output        io_out_complexDecodedInsts_3_bits_vpu_isDependOldVd,
  output        io_out_complexDecodedInsts_3_bits_vpu_isWritePartVd,
  output        io_out_complexDecodedInsts_3_bits_vpu_isVleff,
  output        io_out_complexDecodedInsts_3_bits_vlsInstr,
  output        io_out_complexDecodedInsts_3_bits_wfflags,
  output        io_out_complexDecodedInsts_3_bits_isMove,
  output [6:0]  io_out_complexDecodedInsts_3_bits_uopIdx,
  output [5:0]  io_out_complexDecodedInsts_3_bits_uopSplitType,
  output        io_out_complexDecodedInsts_3_bits_isVset,
  output        io_out_complexDecodedInsts_3_bits_lastUop,
  output [6:0]  io_out_complexDecodedInsts_3_bits_numUops,
  output [6:0]  io_out_complexDecodedInsts_3_bits_numWB,
  output [2:0]  io_out_complexDecodedInsts_3_bits_commitType,
  output [34:0] io_out_complexDecodedInsts_3_bits_debug_fuType,
  output [55:0] io_out_complexDecodedInsts_3_bits_debug_seqNum_seqNum,
  output [7:0]  io_out_complexDecodedInsts_3_bits_debug_seqNum_uopIdx,
  output        io_out_complexDecodedInsts_4_valid,
  output [31:0] io_out_complexDecodedInsts_4_bits_instr,
  output [49:0] io_out_complexDecodedInsts_4_bits_pc,
  output [9:0]  io_out_complexDecodedInsts_4_bits_foldpc,
  output        io_out_complexDecodedInsts_4_bits_exceptionVec_0,
  output        io_out_complexDecodedInsts_4_bits_exceptionVec_1,
  output        io_out_complexDecodedInsts_4_bits_exceptionVec_2,
  output        io_out_complexDecodedInsts_4_bits_exceptionVec_3,
  output        io_out_complexDecodedInsts_4_bits_exceptionVec_4,
  output        io_out_complexDecodedInsts_4_bits_exceptionVec_5,
  output        io_out_complexDecodedInsts_4_bits_exceptionVec_6,
  output        io_out_complexDecodedInsts_4_bits_exceptionVec_7,
  output        io_out_complexDecodedInsts_4_bits_exceptionVec_8,
  output        io_out_complexDecodedInsts_4_bits_exceptionVec_9,
  output        io_out_complexDecodedInsts_4_bits_exceptionVec_10,
  output        io_out_complexDecodedInsts_4_bits_exceptionVec_11,
  output        io_out_complexDecodedInsts_4_bits_exceptionVec_12,
  output        io_out_complexDecodedInsts_4_bits_exceptionVec_13,
  output        io_out_complexDecodedInsts_4_bits_exceptionVec_14,
  output        io_out_complexDecodedInsts_4_bits_exceptionVec_15,
  output        io_out_complexDecodedInsts_4_bits_exceptionVec_16,
  output        io_out_complexDecodedInsts_4_bits_exceptionVec_17,
  output        io_out_complexDecodedInsts_4_bits_exceptionVec_18,
  output        io_out_complexDecodedInsts_4_bits_exceptionVec_19,
  output        io_out_complexDecodedInsts_4_bits_exceptionVec_20,
  output        io_out_complexDecodedInsts_4_bits_exceptionVec_21,
  output        io_out_complexDecodedInsts_4_bits_exceptionVec_22,
  output        io_out_complexDecodedInsts_4_bits_exceptionVec_23,
  output        io_out_complexDecodedInsts_4_bits_isFetchMalAddr,
  output [3:0]  io_out_complexDecodedInsts_4_bits_trigger,
  output        io_out_complexDecodedInsts_4_bits_preDecodeInfo_valid,
  output        io_out_complexDecodedInsts_4_bits_preDecodeInfo_isRVC,
  output [1:0]  io_out_complexDecodedInsts_4_bits_preDecodeInfo_brType,
  output        io_out_complexDecodedInsts_4_bits_preDecodeInfo_isCall,
  output        io_out_complexDecodedInsts_4_bits_preDecodeInfo_isRet,
  output        io_out_complexDecodedInsts_4_bits_pred_taken,
  output        io_out_complexDecodedInsts_4_bits_crossPageIPFFix,
  output        io_out_complexDecodedInsts_4_bits_ftqPtr_flag,
  output [5:0]  io_out_complexDecodedInsts_4_bits_ftqPtr_value,
  output [3:0]  io_out_complexDecodedInsts_4_bits_ftqOffset,
  output        io_out_complexDecodedInsts_4_bits_satpFlushFirstFetchFault,
  output [3:0]  io_out_complexDecodedInsts_4_bits_srcType_0,
  output [3:0]  io_out_complexDecodedInsts_4_bits_srcType_1,
  output [3:0]  io_out_complexDecodedInsts_4_bits_srcType_2,
  output [3:0]  io_out_complexDecodedInsts_4_bits_srcType_3,
  output [3:0]  io_out_complexDecodedInsts_4_bits_srcType_4,
  output [5:0]  io_out_complexDecodedInsts_4_bits_lsrc_0,
  output [5:0]  io_out_complexDecodedInsts_4_bits_lsrc_1,
  output [5:0]  io_out_complexDecodedInsts_4_bits_lsrc_2,
  output [5:0]  io_out_complexDecodedInsts_4_bits_ldest,
  output [34:0] io_out_complexDecodedInsts_4_bits_fuType,
  output [8:0]  io_out_complexDecodedInsts_4_bits_fuOpType,
  output        io_out_complexDecodedInsts_4_bits_rfWen,
  output        io_out_complexDecodedInsts_4_bits_fpWen,
  output        io_out_complexDecodedInsts_4_bits_vecWen,
  output        io_out_complexDecodedInsts_4_bits_vlWen,
  output        io_out_complexDecodedInsts_4_bits_isXSTrap,
  output        io_out_complexDecodedInsts_4_bits_waitForward,
  output        io_out_complexDecodedInsts_4_bits_blockBackward,
  output        io_out_complexDecodedInsts_4_bits_flushPipe,
  output        io_out_complexDecodedInsts_4_bits_canRobCompress,
  output [3:0]  io_out_complexDecodedInsts_4_bits_selImm,
  output [21:0] io_out_complexDecodedInsts_4_bits_imm,
  output [1:0]  io_out_complexDecodedInsts_4_bits_fpu_typeTagOut,
  output        io_out_complexDecodedInsts_4_bits_fpu_wflags,
  output [1:0]  io_out_complexDecodedInsts_4_bits_fpu_typ,
  output [1:0]  io_out_complexDecodedInsts_4_bits_fpu_fmt,
  output [2:0]  io_out_complexDecodedInsts_4_bits_fpu_rm,
  output        io_out_complexDecodedInsts_4_bits_vpu_vill,
  output        io_out_complexDecodedInsts_4_bits_vpu_vma,
  output        io_out_complexDecodedInsts_4_bits_vpu_vta,
  output [1:0]  io_out_complexDecodedInsts_4_bits_vpu_vsew,
  output [2:0]  io_out_complexDecodedInsts_4_bits_vpu_vlmul,
  output        io_out_complexDecodedInsts_4_bits_vpu_specVill,
  output        io_out_complexDecodedInsts_4_bits_vpu_specVma,
  output        io_out_complexDecodedInsts_4_bits_vpu_specVta,
  output [1:0]  io_out_complexDecodedInsts_4_bits_vpu_specVsew,
  output [2:0]  io_out_complexDecodedInsts_4_bits_vpu_specVlmul,
  output        io_out_complexDecodedInsts_4_bits_vpu_vm,
  output [7:0]  io_out_complexDecodedInsts_4_bits_vpu_vstart,
  output        io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_2,
  output        io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_4,
  output        io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_8,
  output [2:0]  io_out_complexDecodedInsts_4_bits_vpu_nf,
  output [1:0]  io_out_complexDecodedInsts_4_bits_vpu_veew,
  output        io_out_complexDecodedInsts_4_bits_vpu_isReverse,
  output        io_out_complexDecodedInsts_4_bits_vpu_isExt,
  output        io_out_complexDecodedInsts_4_bits_vpu_isNarrow,
  output        io_out_complexDecodedInsts_4_bits_vpu_isDstMask,
  output        io_out_complexDecodedInsts_4_bits_vpu_isOpMask,
  output        io_out_complexDecodedInsts_4_bits_vpu_isDependOldVd,
  output        io_out_complexDecodedInsts_4_bits_vpu_isWritePartVd,
  output        io_out_complexDecodedInsts_4_bits_vpu_isVleff,
  output        io_out_complexDecodedInsts_4_bits_vlsInstr,
  output        io_out_complexDecodedInsts_4_bits_wfflags,
  output        io_out_complexDecodedInsts_4_bits_isMove,
  output [6:0]  io_out_complexDecodedInsts_4_bits_uopIdx,
  output [5:0]  io_out_complexDecodedInsts_4_bits_uopSplitType,
  output        io_out_complexDecodedInsts_4_bits_isVset,
  output        io_out_complexDecodedInsts_4_bits_lastUop,
  output [6:0]  io_out_complexDecodedInsts_4_bits_numUops,
  output [6:0]  io_out_complexDecodedInsts_4_bits_numWB,
  output [2:0]  io_out_complexDecodedInsts_4_bits_commitType,
  output [34:0] io_out_complexDecodedInsts_4_bits_debug_fuType,
  output [55:0] io_out_complexDecodedInsts_4_bits_debug_seqNum_seqNum,
  output [7:0]  io_out_complexDecodedInsts_4_bits_debug_seqNum_uopIdx,
  output        io_out_complexDecodedInsts_5_valid,
  output [31:0] io_out_complexDecodedInsts_5_bits_instr,
  output [49:0] io_out_complexDecodedInsts_5_bits_pc,
  output [9:0]  io_out_complexDecodedInsts_5_bits_foldpc,
  output        io_out_complexDecodedInsts_5_bits_exceptionVec_0,
  output        io_out_complexDecodedInsts_5_bits_exceptionVec_1,
  output        io_out_complexDecodedInsts_5_bits_exceptionVec_2,
  output        io_out_complexDecodedInsts_5_bits_exceptionVec_3,
  output        io_out_complexDecodedInsts_5_bits_exceptionVec_4,
  output        io_out_complexDecodedInsts_5_bits_exceptionVec_5,
  output        io_out_complexDecodedInsts_5_bits_exceptionVec_6,
  output        io_out_complexDecodedInsts_5_bits_exceptionVec_7,
  output        io_out_complexDecodedInsts_5_bits_exceptionVec_8,
  output        io_out_complexDecodedInsts_5_bits_exceptionVec_9,
  output        io_out_complexDecodedInsts_5_bits_exceptionVec_10,
  output        io_out_complexDecodedInsts_5_bits_exceptionVec_11,
  output        io_out_complexDecodedInsts_5_bits_exceptionVec_12,
  output        io_out_complexDecodedInsts_5_bits_exceptionVec_13,
  output        io_out_complexDecodedInsts_5_bits_exceptionVec_14,
  output        io_out_complexDecodedInsts_5_bits_exceptionVec_15,
  output        io_out_complexDecodedInsts_5_bits_exceptionVec_16,
  output        io_out_complexDecodedInsts_5_bits_exceptionVec_17,
  output        io_out_complexDecodedInsts_5_bits_exceptionVec_18,
  output        io_out_complexDecodedInsts_5_bits_exceptionVec_19,
  output        io_out_complexDecodedInsts_5_bits_exceptionVec_20,
  output        io_out_complexDecodedInsts_5_bits_exceptionVec_21,
  output        io_out_complexDecodedInsts_5_bits_exceptionVec_22,
  output        io_out_complexDecodedInsts_5_bits_exceptionVec_23,
  output        io_out_complexDecodedInsts_5_bits_isFetchMalAddr,
  output [3:0]  io_out_complexDecodedInsts_5_bits_trigger,
  output        io_out_complexDecodedInsts_5_bits_preDecodeInfo_valid,
  output        io_out_complexDecodedInsts_5_bits_preDecodeInfo_isRVC,
  output [1:0]  io_out_complexDecodedInsts_5_bits_preDecodeInfo_brType,
  output        io_out_complexDecodedInsts_5_bits_preDecodeInfo_isCall,
  output        io_out_complexDecodedInsts_5_bits_preDecodeInfo_isRet,
  output        io_out_complexDecodedInsts_5_bits_pred_taken,
  output        io_out_complexDecodedInsts_5_bits_crossPageIPFFix,
  output        io_out_complexDecodedInsts_5_bits_ftqPtr_flag,
  output [5:0]  io_out_complexDecodedInsts_5_bits_ftqPtr_value,
  output [3:0]  io_out_complexDecodedInsts_5_bits_ftqOffset,
  output        io_out_complexDecodedInsts_5_bits_satpFlushFirstFetchFault,
  output [3:0]  io_out_complexDecodedInsts_5_bits_srcType_0,
  output [3:0]  io_out_complexDecodedInsts_5_bits_srcType_1,
  output [3:0]  io_out_complexDecodedInsts_5_bits_srcType_2,
  output [3:0]  io_out_complexDecodedInsts_5_bits_srcType_3,
  output [3:0]  io_out_complexDecodedInsts_5_bits_srcType_4,
  output [5:0]  io_out_complexDecodedInsts_5_bits_lsrc_0,
  output [5:0]  io_out_complexDecodedInsts_5_bits_lsrc_1,
  output [5:0]  io_out_complexDecodedInsts_5_bits_lsrc_2,
  output [5:0]  io_out_complexDecodedInsts_5_bits_ldest,
  output [34:0] io_out_complexDecodedInsts_5_bits_fuType,
  output [8:0]  io_out_complexDecodedInsts_5_bits_fuOpType,
  output        io_out_complexDecodedInsts_5_bits_rfWen,
  output        io_out_complexDecodedInsts_5_bits_fpWen,
  output        io_out_complexDecodedInsts_5_bits_vecWen,
  output        io_out_complexDecodedInsts_5_bits_vlWen,
  output        io_out_complexDecodedInsts_5_bits_isXSTrap,
  output        io_out_complexDecodedInsts_5_bits_waitForward,
  output        io_out_complexDecodedInsts_5_bits_blockBackward,
  output        io_out_complexDecodedInsts_5_bits_flushPipe,
  output        io_out_complexDecodedInsts_5_bits_canRobCompress,
  output [3:0]  io_out_complexDecodedInsts_5_bits_selImm,
  output [21:0] io_out_complexDecodedInsts_5_bits_imm,
  output [1:0]  io_out_complexDecodedInsts_5_bits_fpu_typeTagOut,
  output        io_out_complexDecodedInsts_5_bits_fpu_wflags,
  output [1:0]  io_out_complexDecodedInsts_5_bits_fpu_typ,
  output [1:0]  io_out_complexDecodedInsts_5_bits_fpu_fmt,
  output [2:0]  io_out_complexDecodedInsts_5_bits_fpu_rm,
  output        io_out_complexDecodedInsts_5_bits_vpu_vill,
  output        io_out_complexDecodedInsts_5_bits_vpu_vma,
  output        io_out_complexDecodedInsts_5_bits_vpu_vta,
  output [1:0]  io_out_complexDecodedInsts_5_bits_vpu_vsew,
  output [2:0]  io_out_complexDecodedInsts_5_bits_vpu_vlmul,
  output        io_out_complexDecodedInsts_5_bits_vpu_specVill,
  output        io_out_complexDecodedInsts_5_bits_vpu_specVma,
  output        io_out_complexDecodedInsts_5_bits_vpu_specVta,
  output [1:0]  io_out_complexDecodedInsts_5_bits_vpu_specVsew,
  output [2:0]  io_out_complexDecodedInsts_5_bits_vpu_specVlmul,
  output        io_out_complexDecodedInsts_5_bits_vpu_vm,
  output [7:0]  io_out_complexDecodedInsts_5_bits_vpu_vstart,
  output        io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_2,
  output        io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_4,
  output        io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_8,
  output [2:0]  io_out_complexDecodedInsts_5_bits_vpu_nf,
  output [1:0]  io_out_complexDecodedInsts_5_bits_vpu_veew,
  output        io_out_complexDecodedInsts_5_bits_vpu_isReverse,
  output        io_out_complexDecodedInsts_5_bits_vpu_isExt,
  output        io_out_complexDecodedInsts_5_bits_vpu_isNarrow,
  output        io_out_complexDecodedInsts_5_bits_vpu_isDstMask,
  output        io_out_complexDecodedInsts_5_bits_vpu_isOpMask,
  output        io_out_complexDecodedInsts_5_bits_vpu_isDependOldVd,
  output        io_out_complexDecodedInsts_5_bits_vpu_isWritePartVd,
  output        io_out_complexDecodedInsts_5_bits_vpu_isVleff,
  output        io_out_complexDecodedInsts_5_bits_vlsInstr,
  output        io_out_complexDecodedInsts_5_bits_wfflags,
  output        io_out_complexDecodedInsts_5_bits_isMove,
  output [6:0]  io_out_complexDecodedInsts_5_bits_uopIdx,
  output [5:0]  io_out_complexDecodedInsts_5_bits_uopSplitType,
  output        io_out_complexDecodedInsts_5_bits_isVset,
  output        io_out_complexDecodedInsts_5_bits_lastUop,
  output [6:0]  io_out_complexDecodedInsts_5_bits_numUops,
  output [6:0]  io_out_complexDecodedInsts_5_bits_numWB,
  output [2:0]  io_out_complexDecodedInsts_5_bits_commitType,
  output [34:0] io_out_complexDecodedInsts_5_bits_debug_fuType,
  output [55:0] io_out_complexDecodedInsts_5_bits_debug_seqNum_seqNum,
  output [7:0]  io_out_complexDecodedInsts_5_bits_debug_seqNum_uopIdx,
  output [2:0]  io_complexNum
  
  // END GENERATED
);

  // BEGIN GENERATED(wrapper)
  // 下面这一段由 verif/ut/DecodeUnitComp/gen.py 生成：输入打包成 struct、
  // 核的输出摊回 748 根扁平线。每根线走哪条路由 golden 的 assign 现场分类，
  // 分类结果与脚本里的期望集合逐个核对，golden 一变这里立刻红。不要手改。

  static_inst_t  in_inst;
  uop_info_t     in_uop_info;
  vtype_t        vtype_bypass;
  static_inst_t  latched;
  uop_var_t [5:0] out_var;
  logic           exception_ii;
  logic [6:0]     latched_num_of_uop, latched_num_of_wb;
  logic [5:0]     out_valid;

  // ---- 输入打包 ----
  assign in_inst.instr = io_in_bits_simpleDecodedInst_instr;
  assign in_inst.pc = io_in_bits_simpleDecodedInst_pc;
  assign in_inst.foldpc = io_in_bits_simpleDecodedInst_foldpc;
  assign in_inst.exceptionVec[0] = io_in_bits_simpleDecodedInst_exceptionVec_0;
  assign in_inst.exceptionVec[1] = io_in_bits_simpleDecodedInst_exceptionVec_1;
  assign in_inst.exceptionVec[2] = io_in_bits_simpleDecodedInst_exceptionVec_2;
  assign in_inst.exceptionVec[3] = io_in_bits_simpleDecodedInst_exceptionVec_3;
  assign in_inst.exceptionVec[4] = io_in_bits_simpleDecodedInst_exceptionVec_4;
  assign in_inst.exceptionVec[5] = io_in_bits_simpleDecodedInst_exceptionVec_5;
  assign in_inst.exceptionVec[6] = io_in_bits_simpleDecodedInst_exceptionVec_6;
  assign in_inst.exceptionVec[7] = io_in_bits_simpleDecodedInst_exceptionVec_7;
  assign in_inst.exceptionVec[8] = io_in_bits_simpleDecodedInst_exceptionVec_8;
  assign in_inst.exceptionVec[9] = io_in_bits_simpleDecodedInst_exceptionVec_9;
  assign in_inst.exceptionVec[10] = io_in_bits_simpleDecodedInst_exceptionVec_10;
  assign in_inst.exceptionVec[11] = io_in_bits_simpleDecodedInst_exceptionVec_11;
  assign in_inst.exceptionVec[12] = io_in_bits_simpleDecodedInst_exceptionVec_12;
  assign in_inst.exceptionVec[13] = io_in_bits_simpleDecodedInst_exceptionVec_13;
  assign in_inst.exceptionVec[14] = io_in_bits_simpleDecodedInst_exceptionVec_14;
  assign in_inst.exceptionVec[15] = io_in_bits_simpleDecodedInst_exceptionVec_15;
  assign in_inst.exceptionVec[16] = io_in_bits_simpleDecodedInst_exceptionVec_16;
  assign in_inst.exceptionVec[17] = io_in_bits_simpleDecodedInst_exceptionVec_17;
  assign in_inst.exceptionVec[18] = io_in_bits_simpleDecodedInst_exceptionVec_18;
  assign in_inst.exceptionVec[19] = io_in_bits_simpleDecodedInst_exceptionVec_19;
  assign in_inst.exceptionVec[20] = io_in_bits_simpleDecodedInst_exceptionVec_20;
  assign in_inst.exceptionVec[21] = io_in_bits_simpleDecodedInst_exceptionVec_21;
  assign in_inst.exceptionVec[22] = io_in_bits_simpleDecodedInst_exceptionVec_22;
  assign in_inst.exceptionVec[23] = io_in_bits_simpleDecodedInst_exceptionVec_23;
  assign in_inst.isFetchMalAddr = io_in_bits_simpleDecodedInst_isFetchMalAddr;
  assign in_inst.trigger = io_in_bits_simpleDecodedInst_trigger;
  assign in_inst.preDecodeInfo_valid = io_in_bits_simpleDecodedInst_preDecodeInfo_valid;
  assign in_inst.preDecodeInfo_isRVC = io_in_bits_simpleDecodedInst_preDecodeInfo_isRVC;
  assign in_inst.preDecodeInfo_brType = io_in_bits_simpleDecodedInst_preDecodeInfo_brType;
  assign in_inst.preDecodeInfo_isCall = io_in_bits_simpleDecodedInst_preDecodeInfo_isCall;
  assign in_inst.preDecodeInfo_isRet = io_in_bits_simpleDecodedInst_preDecodeInfo_isRet;
  assign in_inst.pred_taken = io_in_bits_simpleDecodedInst_pred_taken;
  assign in_inst.crossPageIPFFix = io_in_bits_simpleDecodedInst_crossPageIPFFix;
  assign in_inst.ftqPtr_flag = io_in_bits_simpleDecodedInst_ftqPtr_flag;
  assign in_inst.ftqPtr_value = io_in_bits_simpleDecodedInst_ftqPtr_value;
  assign in_inst.ftqOffset = io_in_bits_simpleDecodedInst_ftqOffset;
  assign in_inst.satpFlushFirstFetchFault = io_in_bits_simpleDecodedInst_satpFlushFirstFetchFault;
  assign in_inst.srcType[0] = io_in_bits_simpleDecodedInst_srcType_0;
  assign in_inst.srcType[1] = io_in_bits_simpleDecodedInst_srcType_1;
  assign in_inst.srcType[2] = io_in_bits_simpleDecodedInst_srcType_2;
  assign in_inst.srcType[3] = io_in_bits_simpleDecodedInst_srcType_3;
  assign in_inst.srcType[4] = io_in_bits_simpleDecodedInst_srcType_4;
  assign in_inst.lsrc[0] = io_in_bits_simpleDecodedInst_lsrc_0;
  assign in_inst.lsrc[1] = io_in_bits_simpleDecodedInst_lsrc_1;
  assign in_inst.lsrc[2] = io_in_bits_simpleDecodedInst_lsrc_2;
  assign in_inst.ldest = io_in_bits_simpleDecodedInst_ldest;
  assign in_inst.fuType = io_in_bits_simpleDecodedInst_fuType;
  assign in_inst.fuOpType = io_in_bits_simpleDecodedInst_fuOpType;
  assign in_inst.rfWen = io_in_bits_simpleDecodedInst_rfWen;
  assign in_inst.fpWen = io_in_bits_simpleDecodedInst_fpWen;
  assign in_inst.vecWen = io_in_bits_simpleDecodedInst_vecWen;
  assign in_inst.isXSTrap = io_in_bits_simpleDecodedInst_isXSTrap;
  assign in_inst.waitForward = io_in_bits_simpleDecodedInst_waitForward;
  assign in_inst.blockBackward = io_in_bits_simpleDecodedInst_blockBackward;
  assign in_inst.flushPipe = io_in_bits_simpleDecodedInst_flushPipe;
  assign in_inst.canRobCompress = io_in_bits_simpleDecodedInst_canRobCompress;
  assign in_inst.selImm = io_in_bits_simpleDecodedInst_selImm;
  assign in_inst.imm = io_in_bits_simpleDecodedInst_imm;
  assign in_inst.fpu_typeTagOut = io_in_bits_simpleDecodedInst_fpu_typeTagOut;
  assign in_inst.fpu_wflags = io_in_bits_simpleDecodedInst_fpu_wflags;
  assign in_inst.fpu_typ = io_in_bits_simpleDecodedInst_fpu_typ;
  assign in_inst.fpu_fmt = io_in_bits_simpleDecodedInst_fpu_fmt;
  assign in_inst.fpu_rm = io_in_bits_simpleDecodedInst_fpu_rm;
  assign in_inst.vpu_vill = io_in_bits_simpleDecodedInst_vpu_vill;
  assign in_inst.vpu_vma = io_in_bits_simpleDecodedInst_vpu_vma;
  assign in_inst.vpu_vta = io_in_bits_simpleDecodedInst_vpu_vta;
  assign in_inst.vpu_vsew = io_in_bits_simpleDecodedInst_vpu_vsew;
  assign in_inst.vpu_vlmul = io_in_bits_simpleDecodedInst_vpu_vlmul;
  assign in_inst.vpu_specVill = io_in_bits_simpleDecodedInst_vpu_specVill;
  assign in_inst.vpu_specVma = io_in_bits_simpleDecodedInst_vpu_specVma;
  assign in_inst.vpu_specVta = io_in_bits_simpleDecodedInst_vpu_specVta;
  assign in_inst.vpu_specVsew = io_in_bits_simpleDecodedInst_vpu_specVsew;
  assign in_inst.vpu_specVlmul = io_in_bits_simpleDecodedInst_vpu_specVlmul;
  assign in_inst.vpu_vm = io_in_bits_simpleDecodedInst_vpu_vm;
  assign in_inst.vpu_vstart = io_in_bits_simpleDecodedInst_vpu_vstart;
  assign in_inst.vpu_nf = io_in_bits_simpleDecodedInst_vpu_nf;
  assign in_inst.vpu_veew = io_in_bits_simpleDecodedInst_vpu_veew;
  assign in_inst.vpu_isReverse = io_in_bits_simpleDecodedInst_vpu_isReverse;
  assign in_inst.vpu_isExt = io_in_bits_simpleDecodedInst_vpu_isExt;
  assign in_inst.vpu_isNarrow = io_in_bits_simpleDecodedInst_vpu_isNarrow;
  assign in_inst.vpu_isDstMask = io_in_bits_simpleDecodedInst_vpu_isDstMask;
  assign in_inst.vpu_isOpMask = io_in_bits_simpleDecodedInst_vpu_isOpMask;
  assign in_inst.vpu_isDependOldVd = io_in_bits_simpleDecodedInst_vpu_isDependOldVd;
  assign in_inst.vpu_isWritePartVd = io_in_bits_simpleDecodedInst_vpu_isWritePartVd;
  assign in_inst.vpu_isVleff = io_in_bits_simpleDecodedInst_vpu_isVleff;
  assign in_inst.wfflags = io_in_bits_simpleDecodedInst_wfflags;
  assign in_inst.isMove = io_in_bits_simpleDecodedInst_isMove;
  assign in_inst.uopSplitType = io_in_bits_simpleDecodedInst_uopSplitType;
  assign in_inst.isVset = io_in_bits_simpleDecodedInst_isVset;
  assign in_inst.commitType = io_in_bits_simpleDecodedInst_commitType;
  assign in_inst.debug_fuType = io_in_bits_simpleDecodedInst_debug_fuType;
  assign in_inst.debug_seqNum_seqNum = io_in_bits_simpleDecodedInst_debug_seqNum_seqNum;
  assign in_inst.debug_seqNum_uopIdx = io_in_bits_simpleDecodedInst_debug_seqNum_uopIdx;
  assign in_uop_info.numOfUop = io_in_bits_uopInfo_numOfUop;
  assign in_uop_info.numOfWB  = io_in_bits_uopInfo_numOfWB;
  assign in_uop_info.lmul     = io_in_bits_uopInfo_lmul;
  assign vtype_bypass.illegal = io_vtypeBypass_illegal;
  assign vtype_bypass.vma     = io_vtypeBypass_vma;
  assign vtype_bypass.vta     = io_vtypeBypass_vta;
  assign vtype_bypass.vsew    = io_vtypeBypass_vsew;
  assign vtype_bypass.vlmul   = io_vtypeBypass_vlmul;

  xs_DecodeUnitComp_core u_core (
    .clock              (clock),
    .reset              (reset),
    .redirect           (io_redirect),
    .vtype_bypass       (vtype_bypass),
    .in_valid           (io_in_valid),
    .in_ready           (io_in_ready),
    .in_inst            (in_inst),
    .in_uop_info        (in_uop_info),
    .out0_ready         (io_out_complexDecodedInsts_0_ready),
    .out_valid          (out_valid),
    .complex_num        (io_complexNum),
    .latched            (latched),
    .latched_num_of_uop (latched_num_of_uop),
    .latched_num_of_wb  (latched_num_of_wb),
    .exception_ii       (exception_ii),
    .out_var            (out_var)
  );

  // ---- 输出摊平 ----
  assign io_out_complexDecodedInsts_0_valid = out_valid[0];
  assign io_out_complexDecodedInsts_0_bits_instr = latched.instr;
  assign io_out_complexDecodedInsts_0_bits_pc = latched.pc;
  assign io_out_complexDecodedInsts_0_bits_foldpc = latched.foldpc;
  assign io_out_complexDecodedInsts_0_bits_exceptionVec_0 = latched.exceptionVec[0];
  assign io_out_complexDecodedInsts_0_bits_exceptionVec_1 = latched.exceptionVec[1];
  assign io_out_complexDecodedInsts_0_bits_exceptionVec_2 = exception_ii;
  assign io_out_complexDecodedInsts_0_bits_exceptionVec_3 = latched.exceptionVec[3];
  assign io_out_complexDecodedInsts_0_bits_exceptionVec_4 = latched.exceptionVec[4];
  assign io_out_complexDecodedInsts_0_bits_exceptionVec_5 = latched.exceptionVec[5];
  assign io_out_complexDecodedInsts_0_bits_exceptionVec_6 = latched.exceptionVec[6];
  assign io_out_complexDecodedInsts_0_bits_exceptionVec_7 = latched.exceptionVec[7];
  assign io_out_complexDecodedInsts_0_bits_exceptionVec_8 = latched.exceptionVec[8];
  assign io_out_complexDecodedInsts_0_bits_exceptionVec_9 = latched.exceptionVec[9];
  assign io_out_complexDecodedInsts_0_bits_exceptionVec_10 = latched.exceptionVec[10];
  assign io_out_complexDecodedInsts_0_bits_exceptionVec_11 = latched.exceptionVec[11];
  assign io_out_complexDecodedInsts_0_bits_exceptionVec_12 = latched.exceptionVec[12];
  assign io_out_complexDecodedInsts_0_bits_exceptionVec_13 = latched.exceptionVec[13];
  assign io_out_complexDecodedInsts_0_bits_exceptionVec_14 = latched.exceptionVec[14];
  assign io_out_complexDecodedInsts_0_bits_exceptionVec_15 = latched.exceptionVec[15];
  assign io_out_complexDecodedInsts_0_bits_exceptionVec_16 = latched.exceptionVec[16];
  assign io_out_complexDecodedInsts_0_bits_exceptionVec_17 = latched.exceptionVec[17];
  assign io_out_complexDecodedInsts_0_bits_exceptionVec_18 = latched.exceptionVec[18];
  assign io_out_complexDecodedInsts_0_bits_exceptionVec_19 = latched.exceptionVec[19];
  assign io_out_complexDecodedInsts_0_bits_exceptionVec_20 = latched.exceptionVec[20];
  assign io_out_complexDecodedInsts_0_bits_exceptionVec_21 = latched.exceptionVec[21];
  assign io_out_complexDecodedInsts_0_bits_exceptionVec_22 = latched.exceptionVec[22];
  assign io_out_complexDecodedInsts_0_bits_exceptionVec_23 = latched.exceptionVec[23];
  assign io_out_complexDecodedInsts_0_bits_isFetchMalAddr = latched.isFetchMalAddr;
  assign io_out_complexDecodedInsts_0_bits_trigger = latched.trigger;
  assign io_out_complexDecodedInsts_0_bits_preDecodeInfo_valid = latched.preDecodeInfo_valid;
  assign io_out_complexDecodedInsts_0_bits_preDecodeInfo_isRVC = latched.preDecodeInfo_isRVC;
  assign io_out_complexDecodedInsts_0_bits_preDecodeInfo_brType = latched.preDecodeInfo_brType;
  assign io_out_complexDecodedInsts_0_bits_preDecodeInfo_isCall = latched.preDecodeInfo_isCall;
  assign io_out_complexDecodedInsts_0_bits_preDecodeInfo_isRet = latched.preDecodeInfo_isRet;
  assign io_out_complexDecodedInsts_0_bits_pred_taken = latched.pred_taken;
  assign io_out_complexDecodedInsts_0_bits_crossPageIPFFix = latched.crossPageIPFFix;
  assign io_out_complexDecodedInsts_0_bits_ftqPtr_flag = latched.ftqPtr_flag;
  assign io_out_complexDecodedInsts_0_bits_ftqPtr_value = latched.ftqPtr_value;
  assign io_out_complexDecodedInsts_0_bits_ftqOffset = latched.ftqOffset;
  assign io_out_complexDecodedInsts_0_bits_satpFlushFirstFetchFault = latched.satpFlushFirstFetchFault;
  assign io_out_complexDecodedInsts_0_bits_srcType_0 = out_var[0].srcType[0];
  assign io_out_complexDecodedInsts_0_bits_srcType_1 = out_var[0].srcType[1];
  assign io_out_complexDecodedInsts_0_bits_srcType_2 = out_var[0].srcType[2];
  assign io_out_complexDecodedInsts_0_bits_srcType_3 = out_var[0].srcType[3];
  assign io_out_complexDecodedInsts_0_bits_srcType_4 = out_var[0].srcType[4];
  assign io_out_complexDecodedInsts_0_bits_lsrc_0 = out_var[0].lsrc[0];
  assign io_out_complexDecodedInsts_0_bits_lsrc_1 = out_var[0].lsrc[1];
  assign io_out_complexDecodedInsts_0_bits_lsrc_2 = out_var[0].lsrc[2];
  assign io_out_complexDecodedInsts_0_bits_ldest = out_var[0].ldest;
  assign io_out_complexDecodedInsts_0_bits_fuType = out_var[0].fuType;
  assign io_out_complexDecodedInsts_0_bits_fuOpType = out_var[0].fuOpType;
  assign io_out_complexDecodedInsts_0_bits_rfWen = out_var[0].rfWen;
  assign io_out_complexDecodedInsts_0_bits_fpWen = out_var[0].fpWen;
  assign io_out_complexDecodedInsts_0_bits_vecWen = out_var[0].vecWen;
  assign io_out_complexDecodedInsts_0_bits_vlWen = out_var[0].vlWen;
  assign io_out_complexDecodedInsts_0_bits_isXSTrap = latched.isXSTrap;
  assign io_out_complexDecodedInsts_0_bits_waitForward = out_var[0].waitForward;
  assign io_out_complexDecodedInsts_0_bits_blockBackward = out_var[0].blockBackward;
  assign io_out_complexDecodedInsts_0_bits_flushPipe = out_var[0].flushPipe;
  assign io_out_complexDecodedInsts_0_bits_canRobCompress = latched.canRobCompress;
  assign io_out_complexDecodedInsts_0_bits_selImm = latched.selImm;
  assign io_out_complexDecodedInsts_0_bits_imm = latched.imm;
  assign io_out_complexDecodedInsts_0_bits_fpu_typeTagOut = latched.fpu_typeTagOut;
  assign io_out_complexDecodedInsts_0_bits_fpu_wflags = latched.fpu_wflags;
  assign io_out_complexDecodedInsts_0_bits_fpu_typ = latched.fpu_typ;
  assign io_out_complexDecodedInsts_0_bits_fpu_fmt = latched.fpu_fmt;
  assign io_out_complexDecodedInsts_0_bits_fpu_rm = latched.fpu_rm;
  assign io_out_complexDecodedInsts_0_bits_vpu_vill = out_var[0].vpu_vill;
  assign io_out_complexDecodedInsts_0_bits_vpu_vma = out_var[0].vpu_vma;
  assign io_out_complexDecodedInsts_0_bits_vpu_vta = out_var[0].vpu_vta;
  assign io_out_complexDecodedInsts_0_bits_vpu_vsew = out_var[0].vpu_vsew;
  assign io_out_complexDecodedInsts_0_bits_vpu_vlmul = out_var[0].vpu_vlmul;
  assign io_out_complexDecodedInsts_0_bits_vpu_specVill = latched.vpu_specVill;
  assign io_out_complexDecodedInsts_0_bits_vpu_specVma = latched.vpu_specVma;
  assign io_out_complexDecodedInsts_0_bits_vpu_specVta = latched.vpu_specVta;
  assign io_out_complexDecodedInsts_0_bits_vpu_specVsew = latched.vpu_specVsew;
  assign io_out_complexDecodedInsts_0_bits_vpu_specVlmul = latched.vpu_specVlmul;
  assign io_out_complexDecodedInsts_0_bits_vpu_vm = latched.vpu_vm;
  assign io_out_complexDecodedInsts_0_bits_vpu_vstart = latched.vpu_vstart;
  assign io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_2 = out_var[0].vpu_fpu_isFoldTo1_2;
  assign io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_4 = out_var[0].vpu_fpu_isFoldTo1_4;
  assign io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_8 = out_var[0].vpu_fpu_isFoldTo1_8;
  assign io_out_complexDecodedInsts_0_bits_vpu_nf = latched.vpu_nf;
  assign io_out_complexDecodedInsts_0_bits_vpu_veew = latched.vpu_veew;
  assign io_out_complexDecodedInsts_0_bits_vpu_isReverse = out_var[0].vpu_isReverse;
  assign io_out_complexDecodedInsts_0_bits_vpu_isExt = latched.vpu_isExt;
  assign io_out_complexDecodedInsts_0_bits_vpu_isNarrow = latched.vpu_isNarrow;
  assign io_out_complexDecodedInsts_0_bits_vpu_isDstMask = latched.vpu_isDstMask;
  assign io_out_complexDecodedInsts_0_bits_vpu_isOpMask = latched.vpu_isOpMask;
  assign io_out_complexDecodedInsts_0_bits_vpu_isDependOldVd = latched.vpu_isDependOldVd;
  assign io_out_complexDecodedInsts_0_bits_vpu_isWritePartVd = latched.vpu_isWritePartVd;
  assign io_out_complexDecodedInsts_0_bits_vpu_isVleff = latched.vpu_isVleff;
  assign io_out_complexDecodedInsts_0_bits_vlsInstr = out_var[0].vlsInstr;
  assign io_out_complexDecodedInsts_0_bits_wfflags = latched.wfflags;
  assign io_out_complexDecodedInsts_0_bits_isMove = latched.isMove;
  assign io_out_complexDecodedInsts_0_bits_uopIdx = out_var[0].uopIdx;
  assign io_out_complexDecodedInsts_0_bits_uopSplitType = latched.uopSplitType;
  assign io_out_complexDecodedInsts_0_bits_isVset = latched.isVset;
  assign io_out_complexDecodedInsts_0_bits_firstUop = out_var[0].firstUop;
  assign io_out_complexDecodedInsts_0_bits_lastUop = out_var[0].lastUop;
  assign io_out_complexDecodedInsts_0_bits_numUops = latched_num_of_uop;
  assign io_out_complexDecodedInsts_0_bits_numWB = latched_num_of_wb;
  assign io_out_complexDecodedInsts_0_bits_commitType = latched.commitType;
  assign io_out_complexDecodedInsts_0_bits_debug_fuType = latched.debug_fuType;
  assign io_out_complexDecodedInsts_0_bits_debug_seqNum_seqNum = latched.debug_seqNum_seqNum;
  assign io_out_complexDecodedInsts_0_bits_debug_seqNum_uopIdx = latched.debug_seqNum_uopIdx;

  assign io_out_complexDecodedInsts_1_valid = out_valid[1];
  assign io_out_complexDecodedInsts_1_bits_instr = latched.instr;
  assign io_out_complexDecodedInsts_1_bits_pc = latched.pc;
  assign io_out_complexDecodedInsts_1_bits_foldpc = latched.foldpc;
  assign io_out_complexDecodedInsts_1_bits_exceptionVec_0 = latched.exceptionVec[0];
  assign io_out_complexDecodedInsts_1_bits_exceptionVec_1 = latched.exceptionVec[1];
  assign io_out_complexDecodedInsts_1_bits_exceptionVec_2 = exception_ii;
  assign io_out_complexDecodedInsts_1_bits_exceptionVec_3 = latched.exceptionVec[3];
  assign io_out_complexDecodedInsts_1_bits_exceptionVec_4 = latched.exceptionVec[4];
  assign io_out_complexDecodedInsts_1_bits_exceptionVec_5 = latched.exceptionVec[5];
  assign io_out_complexDecodedInsts_1_bits_exceptionVec_6 = latched.exceptionVec[6];
  assign io_out_complexDecodedInsts_1_bits_exceptionVec_7 = latched.exceptionVec[7];
  assign io_out_complexDecodedInsts_1_bits_exceptionVec_8 = latched.exceptionVec[8];
  assign io_out_complexDecodedInsts_1_bits_exceptionVec_9 = latched.exceptionVec[9];
  assign io_out_complexDecodedInsts_1_bits_exceptionVec_10 = latched.exceptionVec[10];
  assign io_out_complexDecodedInsts_1_bits_exceptionVec_11 = latched.exceptionVec[11];
  assign io_out_complexDecodedInsts_1_bits_exceptionVec_12 = latched.exceptionVec[12];
  assign io_out_complexDecodedInsts_1_bits_exceptionVec_13 = latched.exceptionVec[13];
  assign io_out_complexDecodedInsts_1_bits_exceptionVec_14 = latched.exceptionVec[14];
  assign io_out_complexDecodedInsts_1_bits_exceptionVec_15 = latched.exceptionVec[15];
  assign io_out_complexDecodedInsts_1_bits_exceptionVec_16 = latched.exceptionVec[16];
  assign io_out_complexDecodedInsts_1_bits_exceptionVec_17 = latched.exceptionVec[17];
  assign io_out_complexDecodedInsts_1_bits_exceptionVec_18 = latched.exceptionVec[18];
  assign io_out_complexDecodedInsts_1_bits_exceptionVec_19 = latched.exceptionVec[19];
  assign io_out_complexDecodedInsts_1_bits_exceptionVec_20 = latched.exceptionVec[20];
  assign io_out_complexDecodedInsts_1_bits_exceptionVec_21 = latched.exceptionVec[21];
  assign io_out_complexDecodedInsts_1_bits_exceptionVec_22 = latched.exceptionVec[22];
  assign io_out_complexDecodedInsts_1_bits_exceptionVec_23 = latched.exceptionVec[23];
  assign io_out_complexDecodedInsts_1_bits_isFetchMalAddr = latched.isFetchMalAddr;
  assign io_out_complexDecodedInsts_1_bits_trigger = latched.trigger;
  assign io_out_complexDecodedInsts_1_bits_preDecodeInfo_valid = latched.preDecodeInfo_valid;
  assign io_out_complexDecodedInsts_1_bits_preDecodeInfo_isRVC = latched.preDecodeInfo_isRVC;
  assign io_out_complexDecodedInsts_1_bits_preDecodeInfo_brType = latched.preDecodeInfo_brType;
  assign io_out_complexDecodedInsts_1_bits_preDecodeInfo_isCall = latched.preDecodeInfo_isCall;
  assign io_out_complexDecodedInsts_1_bits_preDecodeInfo_isRet = latched.preDecodeInfo_isRet;
  assign io_out_complexDecodedInsts_1_bits_pred_taken = latched.pred_taken;
  assign io_out_complexDecodedInsts_1_bits_crossPageIPFFix = latched.crossPageIPFFix;
  assign io_out_complexDecodedInsts_1_bits_ftqPtr_flag = latched.ftqPtr_flag;
  assign io_out_complexDecodedInsts_1_bits_ftqPtr_value = latched.ftqPtr_value;
  assign io_out_complexDecodedInsts_1_bits_ftqOffset = latched.ftqOffset;
  assign io_out_complexDecodedInsts_1_bits_satpFlushFirstFetchFault = latched.satpFlushFirstFetchFault;
  assign io_out_complexDecodedInsts_1_bits_srcType_0 = out_var[1].srcType[0];
  assign io_out_complexDecodedInsts_1_bits_srcType_1 = out_var[1].srcType[1];
  assign io_out_complexDecodedInsts_1_bits_srcType_2 = out_var[1].srcType[2];
  assign io_out_complexDecodedInsts_1_bits_srcType_3 = out_var[1].srcType[3];
  assign io_out_complexDecodedInsts_1_bits_srcType_4 = out_var[1].srcType[4];
  assign io_out_complexDecodedInsts_1_bits_lsrc_0 = out_var[1].lsrc[0];
  assign io_out_complexDecodedInsts_1_bits_lsrc_1 = out_var[1].lsrc[1];
  assign io_out_complexDecodedInsts_1_bits_lsrc_2 = out_var[1].lsrc[2];
  assign io_out_complexDecodedInsts_1_bits_ldest = out_var[1].ldest;
  assign io_out_complexDecodedInsts_1_bits_fuType = out_var[1].fuType;
  assign io_out_complexDecodedInsts_1_bits_fuOpType = out_var[1].fuOpType;
  assign io_out_complexDecodedInsts_1_bits_rfWen = out_var[1].rfWen;
  assign io_out_complexDecodedInsts_1_bits_fpWen = out_var[1].fpWen;
  assign io_out_complexDecodedInsts_1_bits_vecWen = out_var[1].vecWen;
  assign io_out_complexDecodedInsts_1_bits_vlWen = out_var[1].vlWen;
  assign io_out_complexDecodedInsts_1_bits_isXSTrap = latched.isXSTrap;
  assign io_out_complexDecodedInsts_1_bits_waitForward = out_var[1].waitForward;
  assign io_out_complexDecodedInsts_1_bits_blockBackward = out_var[1].blockBackward;
  assign io_out_complexDecodedInsts_1_bits_flushPipe = out_var[1].flushPipe;
  assign io_out_complexDecodedInsts_1_bits_canRobCompress = latched.canRobCompress;
  assign io_out_complexDecodedInsts_1_bits_selImm = latched.selImm;
  assign io_out_complexDecodedInsts_1_bits_imm = latched.imm;
  assign io_out_complexDecodedInsts_1_bits_fpu_typeTagOut = latched.fpu_typeTagOut;
  assign io_out_complexDecodedInsts_1_bits_fpu_wflags = latched.fpu_wflags;
  assign io_out_complexDecodedInsts_1_bits_fpu_typ = latched.fpu_typ;
  assign io_out_complexDecodedInsts_1_bits_fpu_fmt = latched.fpu_fmt;
  assign io_out_complexDecodedInsts_1_bits_fpu_rm = latched.fpu_rm;
  assign io_out_complexDecodedInsts_1_bits_vpu_vill = out_var[1].vpu_vill;
  assign io_out_complexDecodedInsts_1_bits_vpu_vma = out_var[1].vpu_vma;
  assign io_out_complexDecodedInsts_1_bits_vpu_vta = out_var[1].vpu_vta;
  assign io_out_complexDecodedInsts_1_bits_vpu_vsew = out_var[1].vpu_vsew;
  assign io_out_complexDecodedInsts_1_bits_vpu_vlmul = out_var[1].vpu_vlmul;
  assign io_out_complexDecodedInsts_1_bits_vpu_specVill = latched.vpu_specVill;
  assign io_out_complexDecodedInsts_1_bits_vpu_specVma = latched.vpu_specVma;
  assign io_out_complexDecodedInsts_1_bits_vpu_specVta = latched.vpu_specVta;
  assign io_out_complexDecodedInsts_1_bits_vpu_specVsew = latched.vpu_specVsew;
  assign io_out_complexDecodedInsts_1_bits_vpu_specVlmul = latched.vpu_specVlmul;
  assign io_out_complexDecodedInsts_1_bits_vpu_vm = latched.vpu_vm;
  assign io_out_complexDecodedInsts_1_bits_vpu_vstart = latched.vpu_vstart;
  assign io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_2 = out_var[1].vpu_fpu_isFoldTo1_2;
  assign io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_4 = out_var[1].vpu_fpu_isFoldTo1_4;
  assign io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_8 = out_var[1].vpu_fpu_isFoldTo1_8;
  assign io_out_complexDecodedInsts_1_bits_vpu_nf = latched.vpu_nf;
  assign io_out_complexDecodedInsts_1_bits_vpu_veew = latched.vpu_veew;
  assign io_out_complexDecodedInsts_1_bits_vpu_isReverse = out_var[1].vpu_isReverse;
  assign io_out_complexDecodedInsts_1_bits_vpu_isExt = latched.vpu_isExt;
  assign io_out_complexDecodedInsts_1_bits_vpu_isNarrow = latched.vpu_isNarrow;
  assign io_out_complexDecodedInsts_1_bits_vpu_isDstMask = latched.vpu_isDstMask;
  assign io_out_complexDecodedInsts_1_bits_vpu_isOpMask = latched.vpu_isOpMask;
  assign io_out_complexDecodedInsts_1_bits_vpu_isDependOldVd = latched.vpu_isDependOldVd;
  assign io_out_complexDecodedInsts_1_bits_vpu_isWritePartVd = latched.vpu_isWritePartVd;
  assign io_out_complexDecodedInsts_1_bits_vpu_isVleff = latched.vpu_isVleff;
  assign io_out_complexDecodedInsts_1_bits_vlsInstr = out_var[1].vlsInstr;
  assign io_out_complexDecodedInsts_1_bits_wfflags = latched.wfflags;
  assign io_out_complexDecodedInsts_1_bits_isMove = latched.isMove;
  assign io_out_complexDecodedInsts_1_bits_uopIdx = out_var[1].uopIdx;
  assign io_out_complexDecodedInsts_1_bits_uopSplitType = latched.uopSplitType;
  assign io_out_complexDecodedInsts_1_bits_isVset = latched.isVset;
  assign io_out_complexDecodedInsts_1_bits_lastUop = out_var[1].lastUop;
  assign io_out_complexDecodedInsts_1_bits_numUops = latched_num_of_uop;
  assign io_out_complexDecodedInsts_1_bits_numWB = latched_num_of_wb;
  assign io_out_complexDecodedInsts_1_bits_commitType = latched.commitType;
  assign io_out_complexDecodedInsts_1_bits_debug_fuType = latched.debug_fuType;
  assign io_out_complexDecodedInsts_1_bits_debug_seqNum_seqNum = latched.debug_seqNum_seqNum;
  assign io_out_complexDecodedInsts_1_bits_debug_seqNum_uopIdx = latched.debug_seqNum_uopIdx;

  assign io_out_complexDecodedInsts_2_valid = out_valid[2];
  assign io_out_complexDecodedInsts_2_bits_instr = latched.instr;
  assign io_out_complexDecodedInsts_2_bits_pc = latched.pc;
  assign io_out_complexDecodedInsts_2_bits_foldpc = latched.foldpc;
  assign io_out_complexDecodedInsts_2_bits_exceptionVec_0 = latched.exceptionVec[0];
  assign io_out_complexDecodedInsts_2_bits_exceptionVec_1 = latched.exceptionVec[1];
  assign io_out_complexDecodedInsts_2_bits_exceptionVec_2 = exception_ii;
  assign io_out_complexDecodedInsts_2_bits_exceptionVec_3 = latched.exceptionVec[3];
  assign io_out_complexDecodedInsts_2_bits_exceptionVec_4 = latched.exceptionVec[4];
  assign io_out_complexDecodedInsts_2_bits_exceptionVec_5 = latched.exceptionVec[5];
  assign io_out_complexDecodedInsts_2_bits_exceptionVec_6 = latched.exceptionVec[6];
  assign io_out_complexDecodedInsts_2_bits_exceptionVec_7 = latched.exceptionVec[7];
  assign io_out_complexDecodedInsts_2_bits_exceptionVec_8 = latched.exceptionVec[8];
  assign io_out_complexDecodedInsts_2_bits_exceptionVec_9 = latched.exceptionVec[9];
  assign io_out_complexDecodedInsts_2_bits_exceptionVec_10 = latched.exceptionVec[10];
  assign io_out_complexDecodedInsts_2_bits_exceptionVec_11 = latched.exceptionVec[11];
  assign io_out_complexDecodedInsts_2_bits_exceptionVec_12 = latched.exceptionVec[12];
  assign io_out_complexDecodedInsts_2_bits_exceptionVec_13 = latched.exceptionVec[13];
  assign io_out_complexDecodedInsts_2_bits_exceptionVec_14 = latched.exceptionVec[14];
  assign io_out_complexDecodedInsts_2_bits_exceptionVec_15 = latched.exceptionVec[15];
  assign io_out_complexDecodedInsts_2_bits_exceptionVec_16 = latched.exceptionVec[16];
  assign io_out_complexDecodedInsts_2_bits_exceptionVec_17 = latched.exceptionVec[17];
  assign io_out_complexDecodedInsts_2_bits_exceptionVec_18 = latched.exceptionVec[18];
  assign io_out_complexDecodedInsts_2_bits_exceptionVec_19 = latched.exceptionVec[19];
  assign io_out_complexDecodedInsts_2_bits_exceptionVec_20 = latched.exceptionVec[20];
  assign io_out_complexDecodedInsts_2_bits_exceptionVec_21 = latched.exceptionVec[21];
  assign io_out_complexDecodedInsts_2_bits_exceptionVec_22 = latched.exceptionVec[22];
  assign io_out_complexDecodedInsts_2_bits_exceptionVec_23 = latched.exceptionVec[23];
  assign io_out_complexDecodedInsts_2_bits_isFetchMalAddr = latched.isFetchMalAddr;
  assign io_out_complexDecodedInsts_2_bits_trigger = latched.trigger;
  assign io_out_complexDecodedInsts_2_bits_preDecodeInfo_valid = latched.preDecodeInfo_valid;
  assign io_out_complexDecodedInsts_2_bits_preDecodeInfo_isRVC = latched.preDecodeInfo_isRVC;
  assign io_out_complexDecodedInsts_2_bits_preDecodeInfo_brType = latched.preDecodeInfo_brType;
  assign io_out_complexDecodedInsts_2_bits_preDecodeInfo_isCall = latched.preDecodeInfo_isCall;
  assign io_out_complexDecodedInsts_2_bits_preDecodeInfo_isRet = latched.preDecodeInfo_isRet;
  assign io_out_complexDecodedInsts_2_bits_pred_taken = latched.pred_taken;
  assign io_out_complexDecodedInsts_2_bits_crossPageIPFFix = latched.crossPageIPFFix;
  assign io_out_complexDecodedInsts_2_bits_ftqPtr_flag = latched.ftqPtr_flag;
  assign io_out_complexDecodedInsts_2_bits_ftqPtr_value = latched.ftqPtr_value;
  assign io_out_complexDecodedInsts_2_bits_ftqOffset = latched.ftqOffset;
  assign io_out_complexDecodedInsts_2_bits_satpFlushFirstFetchFault = latched.satpFlushFirstFetchFault;
  assign io_out_complexDecodedInsts_2_bits_srcType_0 = out_var[2].srcType[0];
  assign io_out_complexDecodedInsts_2_bits_srcType_1 = out_var[2].srcType[1];
  assign io_out_complexDecodedInsts_2_bits_srcType_2 = out_var[2].srcType[2];
  assign io_out_complexDecodedInsts_2_bits_srcType_3 = out_var[2].srcType[3];
  assign io_out_complexDecodedInsts_2_bits_srcType_4 = out_var[2].srcType[4];
  assign io_out_complexDecodedInsts_2_bits_lsrc_0 = out_var[2].lsrc[0];
  assign io_out_complexDecodedInsts_2_bits_lsrc_1 = out_var[2].lsrc[1];
  assign io_out_complexDecodedInsts_2_bits_lsrc_2 = out_var[2].lsrc[2];
  assign io_out_complexDecodedInsts_2_bits_ldest = out_var[2].ldest;
  assign io_out_complexDecodedInsts_2_bits_fuType = out_var[2].fuType;
  assign io_out_complexDecodedInsts_2_bits_fuOpType = out_var[2].fuOpType;
  assign io_out_complexDecodedInsts_2_bits_rfWen = out_var[2].rfWen;
  assign io_out_complexDecodedInsts_2_bits_fpWen = out_var[2].fpWen;
  assign io_out_complexDecodedInsts_2_bits_vecWen = out_var[2].vecWen;
  assign io_out_complexDecodedInsts_2_bits_vlWen = out_var[2].vlWen;
  assign io_out_complexDecodedInsts_2_bits_isXSTrap = latched.isXSTrap;
  assign io_out_complexDecodedInsts_2_bits_waitForward = out_var[2].waitForward;
  assign io_out_complexDecodedInsts_2_bits_blockBackward = out_var[2].blockBackward;
  assign io_out_complexDecodedInsts_2_bits_flushPipe = out_var[2].flushPipe;
  assign io_out_complexDecodedInsts_2_bits_canRobCompress = latched.canRobCompress;
  assign io_out_complexDecodedInsts_2_bits_selImm = latched.selImm;
  assign io_out_complexDecodedInsts_2_bits_imm = latched.imm;
  assign io_out_complexDecodedInsts_2_bits_fpu_typeTagOut = latched.fpu_typeTagOut;
  assign io_out_complexDecodedInsts_2_bits_fpu_wflags = latched.fpu_wflags;
  assign io_out_complexDecodedInsts_2_bits_fpu_typ = latched.fpu_typ;
  assign io_out_complexDecodedInsts_2_bits_fpu_fmt = latched.fpu_fmt;
  assign io_out_complexDecodedInsts_2_bits_fpu_rm = latched.fpu_rm;
  assign io_out_complexDecodedInsts_2_bits_vpu_vill = out_var[2].vpu_vill;
  assign io_out_complexDecodedInsts_2_bits_vpu_vma = out_var[2].vpu_vma;
  assign io_out_complexDecodedInsts_2_bits_vpu_vta = out_var[2].vpu_vta;
  assign io_out_complexDecodedInsts_2_bits_vpu_vsew = out_var[2].vpu_vsew;
  assign io_out_complexDecodedInsts_2_bits_vpu_vlmul = out_var[2].vpu_vlmul;
  assign io_out_complexDecodedInsts_2_bits_vpu_specVill = latched.vpu_specVill;
  assign io_out_complexDecodedInsts_2_bits_vpu_specVma = latched.vpu_specVma;
  assign io_out_complexDecodedInsts_2_bits_vpu_specVta = latched.vpu_specVta;
  assign io_out_complexDecodedInsts_2_bits_vpu_specVsew = latched.vpu_specVsew;
  assign io_out_complexDecodedInsts_2_bits_vpu_specVlmul = latched.vpu_specVlmul;
  assign io_out_complexDecodedInsts_2_bits_vpu_vm = latched.vpu_vm;
  assign io_out_complexDecodedInsts_2_bits_vpu_vstart = latched.vpu_vstart;
  assign io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_2 = out_var[2].vpu_fpu_isFoldTo1_2;
  assign io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_4 = out_var[2].vpu_fpu_isFoldTo1_4;
  assign io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_8 = out_var[2].vpu_fpu_isFoldTo1_8;
  assign io_out_complexDecodedInsts_2_bits_vpu_nf = latched.vpu_nf;
  assign io_out_complexDecodedInsts_2_bits_vpu_veew = latched.vpu_veew;
  assign io_out_complexDecodedInsts_2_bits_vpu_isReverse = out_var[2].vpu_isReverse;
  assign io_out_complexDecodedInsts_2_bits_vpu_isExt = latched.vpu_isExt;
  assign io_out_complexDecodedInsts_2_bits_vpu_isNarrow = latched.vpu_isNarrow;
  assign io_out_complexDecodedInsts_2_bits_vpu_isDstMask = latched.vpu_isDstMask;
  assign io_out_complexDecodedInsts_2_bits_vpu_isOpMask = latched.vpu_isOpMask;
  assign io_out_complexDecodedInsts_2_bits_vpu_isDependOldVd = latched.vpu_isDependOldVd;
  assign io_out_complexDecodedInsts_2_bits_vpu_isWritePartVd = latched.vpu_isWritePartVd;
  assign io_out_complexDecodedInsts_2_bits_vpu_isVleff = latched.vpu_isVleff;
  assign io_out_complexDecodedInsts_2_bits_vlsInstr = out_var[2].vlsInstr;
  assign io_out_complexDecodedInsts_2_bits_wfflags = latched.wfflags;
  assign io_out_complexDecodedInsts_2_bits_isMove = latched.isMove;
  assign io_out_complexDecodedInsts_2_bits_uopIdx = out_var[2].uopIdx;
  assign io_out_complexDecodedInsts_2_bits_uopSplitType = latched.uopSplitType;
  assign io_out_complexDecodedInsts_2_bits_isVset = latched.isVset;
  assign io_out_complexDecodedInsts_2_bits_lastUop = out_var[2].lastUop;
  assign io_out_complexDecodedInsts_2_bits_numUops = latched_num_of_uop;
  assign io_out_complexDecodedInsts_2_bits_numWB = latched_num_of_wb;
  assign io_out_complexDecodedInsts_2_bits_commitType = latched.commitType;
  assign io_out_complexDecodedInsts_2_bits_debug_fuType = latched.debug_fuType;
  assign io_out_complexDecodedInsts_2_bits_debug_seqNum_seqNum = latched.debug_seqNum_seqNum;
  assign io_out_complexDecodedInsts_2_bits_debug_seqNum_uopIdx = latched.debug_seqNum_uopIdx;

  assign io_out_complexDecodedInsts_3_valid = out_valid[3];
  assign io_out_complexDecodedInsts_3_bits_instr = latched.instr;
  assign io_out_complexDecodedInsts_3_bits_pc = latched.pc;
  assign io_out_complexDecodedInsts_3_bits_foldpc = latched.foldpc;
  assign io_out_complexDecodedInsts_3_bits_exceptionVec_0 = latched.exceptionVec[0];
  assign io_out_complexDecodedInsts_3_bits_exceptionVec_1 = latched.exceptionVec[1];
  assign io_out_complexDecodedInsts_3_bits_exceptionVec_2 = exception_ii;
  assign io_out_complexDecodedInsts_3_bits_exceptionVec_3 = latched.exceptionVec[3];
  assign io_out_complexDecodedInsts_3_bits_exceptionVec_4 = latched.exceptionVec[4];
  assign io_out_complexDecodedInsts_3_bits_exceptionVec_5 = latched.exceptionVec[5];
  assign io_out_complexDecodedInsts_3_bits_exceptionVec_6 = latched.exceptionVec[6];
  assign io_out_complexDecodedInsts_3_bits_exceptionVec_7 = latched.exceptionVec[7];
  assign io_out_complexDecodedInsts_3_bits_exceptionVec_8 = latched.exceptionVec[8];
  assign io_out_complexDecodedInsts_3_bits_exceptionVec_9 = latched.exceptionVec[9];
  assign io_out_complexDecodedInsts_3_bits_exceptionVec_10 = latched.exceptionVec[10];
  assign io_out_complexDecodedInsts_3_bits_exceptionVec_11 = latched.exceptionVec[11];
  assign io_out_complexDecodedInsts_3_bits_exceptionVec_12 = latched.exceptionVec[12];
  assign io_out_complexDecodedInsts_3_bits_exceptionVec_13 = latched.exceptionVec[13];
  assign io_out_complexDecodedInsts_3_bits_exceptionVec_14 = latched.exceptionVec[14];
  assign io_out_complexDecodedInsts_3_bits_exceptionVec_15 = latched.exceptionVec[15];
  assign io_out_complexDecodedInsts_3_bits_exceptionVec_16 = latched.exceptionVec[16];
  assign io_out_complexDecodedInsts_3_bits_exceptionVec_17 = latched.exceptionVec[17];
  assign io_out_complexDecodedInsts_3_bits_exceptionVec_18 = latched.exceptionVec[18];
  assign io_out_complexDecodedInsts_3_bits_exceptionVec_19 = latched.exceptionVec[19];
  assign io_out_complexDecodedInsts_3_bits_exceptionVec_20 = latched.exceptionVec[20];
  assign io_out_complexDecodedInsts_3_bits_exceptionVec_21 = latched.exceptionVec[21];
  assign io_out_complexDecodedInsts_3_bits_exceptionVec_22 = latched.exceptionVec[22];
  assign io_out_complexDecodedInsts_3_bits_exceptionVec_23 = latched.exceptionVec[23];
  assign io_out_complexDecodedInsts_3_bits_isFetchMalAddr = latched.isFetchMalAddr;
  assign io_out_complexDecodedInsts_3_bits_trigger = latched.trigger;
  assign io_out_complexDecodedInsts_3_bits_preDecodeInfo_valid = latched.preDecodeInfo_valid;
  assign io_out_complexDecodedInsts_3_bits_preDecodeInfo_isRVC = latched.preDecodeInfo_isRVC;
  assign io_out_complexDecodedInsts_3_bits_preDecodeInfo_brType = latched.preDecodeInfo_brType;
  assign io_out_complexDecodedInsts_3_bits_preDecodeInfo_isCall = latched.preDecodeInfo_isCall;
  assign io_out_complexDecodedInsts_3_bits_preDecodeInfo_isRet = latched.preDecodeInfo_isRet;
  assign io_out_complexDecodedInsts_3_bits_pred_taken = latched.pred_taken;
  assign io_out_complexDecodedInsts_3_bits_crossPageIPFFix = latched.crossPageIPFFix;
  assign io_out_complexDecodedInsts_3_bits_ftqPtr_flag = latched.ftqPtr_flag;
  assign io_out_complexDecodedInsts_3_bits_ftqPtr_value = latched.ftqPtr_value;
  assign io_out_complexDecodedInsts_3_bits_ftqOffset = latched.ftqOffset;
  assign io_out_complexDecodedInsts_3_bits_satpFlushFirstFetchFault = latched.satpFlushFirstFetchFault;
  assign io_out_complexDecodedInsts_3_bits_srcType_0 = out_var[3].srcType[0];
  assign io_out_complexDecodedInsts_3_bits_srcType_1 = out_var[3].srcType[1];
  assign io_out_complexDecodedInsts_3_bits_srcType_2 = out_var[3].srcType[2];
  assign io_out_complexDecodedInsts_3_bits_srcType_3 = out_var[3].srcType[3];
  assign io_out_complexDecodedInsts_3_bits_srcType_4 = out_var[3].srcType[4];
  assign io_out_complexDecodedInsts_3_bits_lsrc_0 = out_var[3].lsrc[0];
  assign io_out_complexDecodedInsts_3_bits_lsrc_1 = out_var[3].lsrc[1];
  assign io_out_complexDecodedInsts_3_bits_lsrc_2 = out_var[3].lsrc[2];
  assign io_out_complexDecodedInsts_3_bits_ldest = out_var[3].ldest;
  assign io_out_complexDecodedInsts_3_bits_fuType = out_var[3].fuType;
  assign io_out_complexDecodedInsts_3_bits_fuOpType = out_var[3].fuOpType;
  assign io_out_complexDecodedInsts_3_bits_rfWen = out_var[3].rfWen;
  assign io_out_complexDecodedInsts_3_bits_fpWen = out_var[3].fpWen;
  assign io_out_complexDecodedInsts_3_bits_vecWen = out_var[3].vecWen;
  assign io_out_complexDecodedInsts_3_bits_vlWen = out_var[3].vlWen;
  assign io_out_complexDecodedInsts_3_bits_isXSTrap = latched.isXSTrap;
  assign io_out_complexDecodedInsts_3_bits_waitForward = out_var[3].waitForward;
  assign io_out_complexDecodedInsts_3_bits_blockBackward = out_var[3].blockBackward;
  assign io_out_complexDecodedInsts_3_bits_flushPipe = out_var[3].flushPipe;
  assign io_out_complexDecodedInsts_3_bits_canRobCompress = latched.canRobCompress;
  assign io_out_complexDecodedInsts_3_bits_selImm = latched.selImm;
  assign io_out_complexDecodedInsts_3_bits_imm = latched.imm;
  assign io_out_complexDecodedInsts_3_bits_fpu_typeTagOut = latched.fpu_typeTagOut;
  assign io_out_complexDecodedInsts_3_bits_fpu_wflags = latched.fpu_wflags;
  assign io_out_complexDecodedInsts_3_bits_fpu_typ = latched.fpu_typ;
  assign io_out_complexDecodedInsts_3_bits_fpu_fmt = latched.fpu_fmt;
  assign io_out_complexDecodedInsts_3_bits_fpu_rm = latched.fpu_rm;
  assign io_out_complexDecodedInsts_3_bits_vpu_vill = out_var[3].vpu_vill;
  assign io_out_complexDecodedInsts_3_bits_vpu_vma = out_var[3].vpu_vma;
  assign io_out_complexDecodedInsts_3_bits_vpu_vta = out_var[3].vpu_vta;
  assign io_out_complexDecodedInsts_3_bits_vpu_vsew = out_var[3].vpu_vsew;
  assign io_out_complexDecodedInsts_3_bits_vpu_vlmul = out_var[3].vpu_vlmul;
  assign io_out_complexDecodedInsts_3_bits_vpu_specVill = latched.vpu_specVill;
  assign io_out_complexDecodedInsts_3_bits_vpu_specVma = latched.vpu_specVma;
  assign io_out_complexDecodedInsts_3_bits_vpu_specVta = latched.vpu_specVta;
  assign io_out_complexDecodedInsts_3_bits_vpu_specVsew = latched.vpu_specVsew;
  assign io_out_complexDecodedInsts_3_bits_vpu_specVlmul = latched.vpu_specVlmul;
  assign io_out_complexDecodedInsts_3_bits_vpu_vm = latched.vpu_vm;
  assign io_out_complexDecodedInsts_3_bits_vpu_vstart = latched.vpu_vstart;
  assign io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_2 = out_var[3].vpu_fpu_isFoldTo1_2;
  assign io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_4 = out_var[3].vpu_fpu_isFoldTo1_4;
  assign io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_8 = out_var[3].vpu_fpu_isFoldTo1_8;
  assign io_out_complexDecodedInsts_3_bits_vpu_nf = latched.vpu_nf;
  assign io_out_complexDecodedInsts_3_bits_vpu_veew = latched.vpu_veew;
  assign io_out_complexDecodedInsts_3_bits_vpu_isReverse = out_var[3].vpu_isReverse;
  assign io_out_complexDecodedInsts_3_bits_vpu_isExt = latched.vpu_isExt;
  assign io_out_complexDecodedInsts_3_bits_vpu_isNarrow = latched.vpu_isNarrow;
  assign io_out_complexDecodedInsts_3_bits_vpu_isDstMask = latched.vpu_isDstMask;
  assign io_out_complexDecodedInsts_3_bits_vpu_isOpMask = latched.vpu_isOpMask;
  assign io_out_complexDecodedInsts_3_bits_vpu_isDependOldVd = latched.vpu_isDependOldVd;
  assign io_out_complexDecodedInsts_3_bits_vpu_isWritePartVd = latched.vpu_isWritePartVd;
  assign io_out_complexDecodedInsts_3_bits_vpu_isVleff = latched.vpu_isVleff;
  assign io_out_complexDecodedInsts_3_bits_vlsInstr = out_var[3].vlsInstr;
  assign io_out_complexDecodedInsts_3_bits_wfflags = latched.wfflags;
  assign io_out_complexDecodedInsts_3_bits_isMove = latched.isMove;
  assign io_out_complexDecodedInsts_3_bits_uopIdx = out_var[3].uopIdx;
  assign io_out_complexDecodedInsts_3_bits_uopSplitType = latched.uopSplitType;
  assign io_out_complexDecodedInsts_3_bits_isVset = latched.isVset;
  assign io_out_complexDecodedInsts_3_bits_lastUop = out_var[3].lastUop;
  assign io_out_complexDecodedInsts_3_bits_numUops = latched_num_of_uop;
  assign io_out_complexDecodedInsts_3_bits_numWB = latched_num_of_wb;
  assign io_out_complexDecodedInsts_3_bits_commitType = latched.commitType;
  assign io_out_complexDecodedInsts_3_bits_debug_fuType = latched.debug_fuType;
  assign io_out_complexDecodedInsts_3_bits_debug_seqNum_seqNum = latched.debug_seqNum_seqNum;
  assign io_out_complexDecodedInsts_3_bits_debug_seqNum_uopIdx = latched.debug_seqNum_uopIdx;

  assign io_out_complexDecodedInsts_4_valid = out_valid[4];
  assign io_out_complexDecodedInsts_4_bits_instr = latched.instr;
  assign io_out_complexDecodedInsts_4_bits_pc = latched.pc;
  assign io_out_complexDecodedInsts_4_bits_foldpc = latched.foldpc;
  assign io_out_complexDecodedInsts_4_bits_exceptionVec_0 = latched.exceptionVec[0];
  assign io_out_complexDecodedInsts_4_bits_exceptionVec_1 = latched.exceptionVec[1];
  assign io_out_complexDecodedInsts_4_bits_exceptionVec_2 = exception_ii;
  assign io_out_complexDecodedInsts_4_bits_exceptionVec_3 = latched.exceptionVec[3];
  assign io_out_complexDecodedInsts_4_bits_exceptionVec_4 = latched.exceptionVec[4];
  assign io_out_complexDecodedInsts_4_bits_exceptionVec_5 = latched.exceptionVec[5];
  assign io_out_complexDecodedInsts_4_bits_exceptionVec_6 = latched.exceptionVec[6];
  assign io_out_complexDecodedInsts_4_bits_exceptionVec_7 = latched.exceptionVec[7];
  assign io_out_complexDecodedInsts_4_bits_exceptionVec_8 = latched.exceptionVec[8];
  assign io_out_complexDecodedInsts_4_bits_exceptionVec_9 = latched.exceptionVec[9];
  assign io_out_complexDecodedInsts_4_bits_exceptionVec_10 = latched.exceptionVec[10];
  assign io_out_complexDecodedInsts_4_bits_exceptionVec_11 = latched.exceptionVec[11];
  assign io_out_complexDecodedInsts_4_bits_exceptionVec_12 = latched.exceptionVec[12];
  assign io_out_complexDecodedInsts_4_bits_exceptionVec_13 = latched.exceptionVec[13];
  assign io_out_complexDecodedInsts_4_bits_exceptionVec_14 = latched.exceptionVec[14];
  assign io_out_complexDecodedInsts_4_bits_exceptionVec_15 = latched.exceptionVec[15];
  assign io_out_complexDecodedInsts_4_bits_exceptionVec_16 = latched.exceptionVec[16];
  assign io_out_complexDecodedInsts_4_bits_exceptionVec_17 = latched.exceptionVec[17];
  assign io_out_complexDecodedInsts_4_bits_exceptionVec_18 = latched.exceptionVec[18];
  assign io_out_complexDecodedInsts_4_bits_exceptionVec_19 = latched.exceptionVec[19];
  assign io_out_complexDecodedInsts_4_bits_exceptionVec_20 = latched.exceptionVec[20];
  assign io_out_complexDecodedInsts_4_bits_exceptionVec_21 = latched.exceptionVec[21];
  assign io_out_complexDecodedInsts_4_bits_exceptionVec_22 = latched.exceptionVec[22];
  assign io_out_complexDecodedInsts_4_bits_exceptionVec_23 = latched.exceptionVec[23];
  assign io_out_complexDecodedInsts_4_bits_isFetchMalAddr = latched.isFetchMalAddr;
  assign io_out_complexDecodedInsts_4_bits_trigger = latched.trigger;
  assign io_out_complexDecodedInsts_4_bits_preDecodeInfo_valid = latched.preDecodeInfo_valid;
  assign io_out_complexDecodedInsts_4_bits_preDecodeInfo_isRVC = latched.preDecodeInfo_isRVC;
  assign io_out_complexDecodedInsts_4_bits_preDecodeInfo_brType = latched.preDecodeInfo_brType;
  assign io_out_complexDecodedInsts_4_bits_preDecodeInfo_isCall = latched.preDecodeInfo_isCall;
  assign io_out_complexDecodedInsts_4_bits_preDecodeInfo_isRet = latched.preDecodeInfo_isRet;
  assign io_out_complexDecodedInsts_4_bits_pred_taken = latched.pred_taken;
  assign io_out_complexDecodedInsts_4_bits_crossPageIPFFix = latched.crossPageIPFFix;
  assign io_out_complexDecodedInsts_4_bits_ftqPtr_flag = latched.ftqPtr_flag;
  assign io_out_complexDecodedInsts_4_bits_ftqPtr_value = latched.ftqPtr_value;
  assign io_out_complexDecodedInsts_4_bits_ftqOffset = latched.ftqOffset;
  assign io_out_complexDecodedInsts_4_bits_satpFlushFirstFetchFault = latched.satpFlushFirstFetchFault;
  assign io_out_complexDecodedInsts_4_bits_srcType_0 = out_var[4].srcType[0];
  assign io_out_complexDecodedInsts_4_bits_srcType_1 = out_var[4].srcType[1];
  assign io_out_complexDecodedInsts_4_bits_srcType_2 = out_var[4].srcType[2];
  assign io_out_complexDecodedInsts_4_bits_srcType_3 = out_var[4].srcType[3];
  assign io_out_complexDecodedInsts_4_bits_srcType_4 = out_var[4].srcType[4];
  assign io_out_complexDecodedInsts_4_bits_lsrc_0 = out_var[4].lsrc[0];
  assign io_out_complexDecodedInsts_4_bits_lsrc_1 = out_var[4].lsrc[1];
  assign io_out_complexDecodedInsts_4_bits_lsrc_2 = out_var[4].lsrc[2];
  assign io_out_complexDecodedInsts_4_bits_ldest = out_var[4].ldest;
  assign io_out_complexDecodedInsts_4_bits_fuType = out_var[4].fuType;
  assign io_out_complexDecodedInsts_4_bits_fuOpType = out_var[4].fuOpType;
  assign io_out_complexDecodedInsts_4_bits_rfWen = out_var[4].rfWen;
  assign io_out_complexDecodedInsts_4_bits_fpWen = out_var[4].fpWen;
  assign io_out_complexDecodedInsts_4_bits_vecWen = out_var[4].vecWen;
  assign io_out_complexDecodedInsts_4_bits_vlWen = out_var[4].vlWen;
  assign io_out_complexDecodedInsts_4_bits_isXSTrap = latched.isXSTrap;
  assign io_out_complexDecodedInsts_4_bits_waitForward = out_var[4].waitForward;
  assign io_out_complexDecodedInsts_4_bits_blockBackward = out_var[4].blockBackward;
  assign io_out_complexDecodedInsts_4_bits_flushPipe = out_var[4].flushPipe;
  assign io_out_complexDecodedInsts_4_bits_canRobCompress = latched.canRobCompress;
  assign io_out_complexDecodedInsts_4_bits_selImm = latched.selImm;
  assign io_out_complexDecodedInsts_4_bits_imm = latched.imm;
  assign io_out_complexDecodedInsts_4_bits_fpu_typeTagOut = latched.fpu_typeTagOut;
  assign io_out_complexDecodedInsts_4_bits_fpu_wflags = latched.fpu_wflags;
  assign io_out_complexDecodedInsts_4_bits_fpu_typ = latched.fpu_typ;
  assign io_out_complexDecodedInsts_4_bits_fpu_fmt = latched.fpu_fmt;
  assign io_out_complexDecodedInsts_4_bits_fpu_rm = latched.fpu_rm;
  assign io_out_complexDecodedInsts_4_bits_vpu_vill = out_var[4].vpu_vill;
  assign io_out_complexDecodedInsts_4_bits_vpu_vma = out_var[4].vpu_vma;
  assign io_out_complexDecodedInsts_4_bits_vpu_vta = out_var[4].vpu_vta;
  assign io_out_complexDecodedInsts_4_bits_vpu_vsew = out_var[4].vpu_vsew;
  assign io_out_complexDecodedInsts_4_bits_vpu_vlmul = out_var[4].vpu_vlmul;
  assign io_out_complexDecodedInsts_4_bits_vpu_specVill = latched.vpu_specVill;
  assign io_out_complexDecodedInsts_4_bits_vpu_specVma = latched.vpu_specVma;
  assign io_out_complexDecodedInsts_4_bits_vpu_specVta = latched.vpu_specVta;
  assign io_out_complexDecodedInsts_4_bits_vpu_specVsew = latched.vpu_specVsew;
  assign io_out_complexDecodedInsts_4_bits_vpu_specVlmul = latched.vpu_specVlmul;
  assign io_out_complexDecodedInsts_4_bits_vpu_vm = latched.vpu_vm;
  assign io_out_complexDecodedInsts_4_bits_vpu_vstart = latched.vpu_vstart;
  assign io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_2 = out_var[4].vpu_fpu_isFoldTo1_2;
  assign io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_4 = out_var[4].vpu_fpu_isFoldTo1_4;
  assign io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_8 = out_var[4].vpu_fpu_isFoldTo1_8;
  assign io_out_complexDecodedInsts_4_bits_vpu_nf = latched.vpu_nf;
  assign io_out_complexDecodedInsts_4_bits_vpu_veew = latched.vpu_veew;
  assign io_out_complexDecodedInsts_4_bits_vpu_isReverse = out_var[4].vpu_isReverse;
  assign io_out_complexDecodedInsts_4_bits_vpu_isExt = latched.vpu_isExt;
  assign io_out_complexDecodedInsts_4_bits_vpu_isNarrow = latched.vpu_isNarrow;
  assign io_out_complexDecodedInsts_4_bits_vpu_isDstMask = latched.vpu_isDstMask;
  assign io_out_complexDecodedInsts_4_bits_vpu_isOpMask = latched.vpu_isOpMask;
  assign io_out_complexDecodedInsts_4_bits_vpu_isDependOldVd = latched.vpu_isDependOldVd;
  assign io_out_complexDecodedInsts_4_bits_vpu_isWritePartVd = latched.vpu_isWritePartVd;
  assign io_out_complexDecodedInsts_4_bits_vpu_isVleff = latched.vpu_isVleff;
  assign io_out_complexDecodedInsts_4_bits_vlsInstr = out_var[4].vlsInstr;
  assign io_out_complexDecodedInsts_4_bits_wfflags = latched.wfflags;
  assign io_out_complexDecodedInsts_4_bits_isMove = latched.isMove;
  assign io_out_complexDecodedInsts_4_bits_uopIdx = out_var[4].uopIdx;
  assign io_out_complexDecodedInsts_4_bits_uopSplitType = latched.uopSplitType;
  assign io_out_complexDecodedInsts_4_bits_isVset = latched.isVset;
  assign io_out_complexDecodedInsts_4_bits_lastUop = out_var[4].lastUop;
  assign io_out_complexDecodedInsts_4_bits_numUops = latched_num_of_uop;
  assign io_out_complexDecodedInsts_4_bits_numWB = latched_num_of_wb;
  assign io_out_complexDecodedInsts_4_bits_commitType = latched.commitType;
  assign io_out_complexDecodedInsts_4_bits_debug_fuType = latched.debug_fuType;
  assign io_out_complexDecodedInsts_4_bits_debug_seqNum_seqNum = latched.debug_seqNum_seqNum;
  assign io_out_complexDecodedInsts_4_bits_debug_seqNum_uopIdx = latched.debug_seqNum_uopIdx;

  assign io_out_complexDecodedInsts_5_valid = out_valid[5];
  assign io_out_complexDecodedInsts_5_bits_instr = latched.instr;
  assign io_out_complexDecodedInsts_5_bits_pc = latched.pc;
  assign io_out_complexDecodedInsts_5_bits_foldpc = latched.foldpc;
  assign io_out_complexDecodedInsts_5_bits_exceptionVec_0 = latched.exceptionVec[0];
  assign io_out_complexDecodedInsts_5_bits_exceptionVec_1 = latched.exceptionVec[1];
  assign io_out_complexDecodedInsts_5_bits_exceptionVec_2 = exception_ii;
  assign io_out_complexDecodedInsts_5_bits_exceptionVec_3 = latched.exceptionVec[3];
  assign io_out_complexDecodedInsts_5_bits_exceptionVec_4 = latched.exceptionVec[4];
  assign io_out_complexDecodedInsts_5_bits_exceptionVec_5 = latched.exceptionVec[5];
  assign io_out_complexDecodedInsts_5_bits_exceptionVec_6 = latched.exceptionVec[6];
  assign io_out_complexDecodedInsts_5_bits_exceptionVec_7 = latched.exceptionVec[7];
  assign io_out_complexDecodedInsts_5_bits_exceptionVec_8 = latched.exceptionVec[8];
  assign io_out_complexDecodedInsts_5_bits_exceptionVec_9 = latched.exceptionVec[9];
  assign io_out_complexDecodedInsts_5_bits_exceptionVec_10 = latched.exceptionVec[10];
  assign io_out_complexDecodedInsts_5_bits_exceptionVec_11 = latched.exceptionVec[11];
  assign io_out_complexDecodedInsts_5_bits_exceptionVec_12 = latched.exceptionVec[12];
  assign io_out_complexDecodedInsts_5_bits_exceptionVec_13 = latched.exceptionVec[13];
  assign io_out_complexDecodedInsts_5_bits_exceptionVec_14 = latched.exceptionVec[14];
  assign io_out_complexDecodedInsts_5_bits_exceptionVec_15 = latched.exceptionVec[15];
  assign io_out_complexDecodedInsts_5_bits_exceptionVec_16 = latched.exceptionVec[16];
  assign io_out_complexDecodedInsts_5_bits_exceptionVec_17 = latched.exceptionVec[17];
  assign io_out_complexDecodedInsts_5_bits_exceptionVec_18 = latched.exceptionVec[18];
  assign io_out_complexDecodedInsts_5_bits_exceptionVec_19 = latched.exceptionVec[19];
  assign io_out_complexDecodedInsts_5_bits_exceptionVec_20 = latched.exceptionVec[20];
  assign io_out_complexDecodedInsts_5_bits_exceptionVec_21 = latched.exceptionVec[21];
  assign io_out_complexDecodedInsts_5_bits_exceptionVec_22 = latched.exceptionVec[22];
  assign io_out_complexDecodedInsts_5_bits_exceptionVec_23 = latched.exceptionVec[23];
  assign io_out_complexDecodedInsts_5_bits_isFetchMalAddr = latched.isFetchMalAddr;
  assign io_out_complexDecodedInsts_5_bits_trigger = latched.trigger;
  assign io_out_complexDecodedInsts_5_bits_preDecodeInfo_valid = latched.preDecodeInfo_valid;
  assign io_out_complexDecodedInsts_5_bits_preDecodeInfo_isRVC = latched.preDecodeInfo_isRVC;
  assign io_out_complexDecodedInsts_5_bits_preDecodeInfo_brType = latched.preDecodeInfo_brType;
  assign io_out_complexDecodedInsts_5_bits_preDecodeInfo_isCall = latched.preDecodeInfo_isCall;
  assign io_out_complexDecodedInsts_5_bits_preDecodeInfo_isRet = latched.preDecodeInfo_isRet;
  assign io_out_complexDecodedInsts_5_bits_pred_taken = latched.pred_taken;
  assign io_out_complexDecodedInsts_5_bits_crossPageIPFFix = latched.crossPageIPFFix;
  assign io_out_complexDecodedInsts_5_bits_ftqPtr_flag = latched.ftqPtr_flag;
  assign io_out_complexDecodedInsts_5_bits_ftqPtr_value = latched.ftqPtr_value;
  assign io_out_complexDecodedInsts_5_bits_ftqOffset = latched.ftqOffset;
  assign io_out_complexDecodedInsts_5_bits_satpFlushFirstFetchFault = latched.satpFlushFirstFetchFault;
  assign io_out_complexDecodedInsts_5_bits_srcType_0 = out_var[5].srcType[0];
  assign io_out_complexDecodedInsts_5_bits_srcType_1 = out_var[5].srcType[1];
  assign io_out_complexDecodedInsts_5_bits_srcType_2 = out_var[5].srcType[2];
  assign io_out_complexDecodedInsts_5_bits_srcType_3 = out_var[5].srcType[3];
  assign io_out_complexDecodedInsts_5_bits_srcType_4 = out_var[5].srcType[4];
  assign io_out_complexDecodedInsts_5_bits_lsrc_0 = out_var[5].lsrc[0];
  assign io_out_complexDecodedInsts_5_bits_lsrc_1 = out_var[5].lsrc[1];
  assign io_out_complexDecodedInsts_5_bits_lsrc_2 = out_var[5].lsrc[2];
  assign io_out_complexDecodedInsts_5_bits_ldest = out_var[5].ldest;
  assign io_out_complexDecodedInsts_5_bits_fuType = out_var[5].fuType;
  assign io_out_complexDecodedInsts_5_bits_fuOpType = out_var[5].fuOpType;
  assign io_out_complexDecodedInsts_5_bits_rfWen = out_var[5].rfWen;
  assign io_out_complexDecodedInsts_5_bits_fpWen = out_var[5].fpWen;
  assign io_out_complexDecodedInsts_5_bits_vecWen = out_var[5].vecWen;
  assign io_out_complexDecodedInsts_5_bits_vlWen = out_var[5].vlWen;
  assign io_out_complexDecodedInsts_5_bits_isXSTrap = latched.isXSTrap;
  assign io_out_complexDecodedInsts_5_bits_waitForward = out_var[5].waitForward;
  assign io_out_complexDecodedInsts_5_bits_blockBackward = out_var[5].blockBackward;
  assign io_out_complexDecodedInsts_5_bits_flushPipe = out_var[5].flushPipe;
  assign io_out_complexDecodedInsts_5_bits_canRobCompress = latched.canRobCompress;
  assign io_out_complexDecodedInsts_5_bits_selImm = latched.selImm;
  assign io_out_complexDecodedInsts_5_bits_imm = latched.imm;
  assign io_out_complexDecodedInsts_5_bits_fpu_typeTagOut = latched.fpu_typeTagOut;
  assign io_out_complexDecodedInsts_5_bits_fpu_wflags = latched.fpu_wflags;
  assign io_out_complexDecodedInsts_5_bits_fpu_typ = latched.fpu_typ;
  assign io_out_complexDecodedInsts_5_bits_fpu_fmt = latched.fpu_fmt;
  assign io_out_complexDecodedInsts_5_bits_fpu_rm = latched.fpu_rm;
  assign io_out_complexDecodedInsts_5_bits_vpu_vill = out_var[5].vpu_vill;
  assign io_out_complexDecodedInsts_5_bits_vpu_vma = out_var[5].vpu_vma;
  assign io_out_complexDecodedInsts_5_bits_vpu_vta = out_var[5].vpu_vta;
  assign io_out_complexDecodedInsts_5_bits_vpu_vsew = out_var[5].vpu_vsew;
  assign io_out_complexDecodedInsts_5_bits_vpu_vlmul = out_var[5].vpu_vlmul;
  assign io_out_complexDecodedInsts_5_bits_vpu_specVill = latched.vpu_specVill;
  assign io_out_complexDecodedInsts_5_bits_vpu_specVma = latched.vpu_specVma;
  assign io_out_complexDecodedInsts_5_bits_vpu_specVta = latched.vpu_specVta;
  assign io_out_complexDecodedInsts_5_bits_vpu_specVsew = latched.vpu_specVsew;
  assign io_out_complexDecodedInsts_5_bits_vpu_specVlmul = latched.vpu_specVlmul;
  assign io_out_complexDecodedInsts_5_bits_vpu_vm = latched.vpu_vm;
  assign io_out_complexDecodedInsts_5_bits_vpu_vstart = latched.vpu_vstart;
  assign io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_2 = out_var[5].vpu_fpu_isFoldTo1_2;
  assign io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_4 = out_var[5].vpu_fpu_isFoldTo1_4;
  assign io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_8 = out_var[5].vpu_fpu_isFoldTo1_8;
  assign io_out_complexDecodedInsts_5_bits_vpu_nf = latched.vpu_nf;
  assign io_out_complexDecodedInsts_5_bits_vpu_veew = latched.vpu_veew;
  assign io_out_complexDecodedInsts_5_bits_vpu_isReverse = out_var[5].vpu_isReverse;
  assign io_out_complexDecodedInsts_5_bits_vpu_isExt = latched.vpu_isExt;
  assign io_out_complexDecodedInsts_5_bits_vpu_isNarrow = latched.vpu_isNarrow;
  assign io_out_complexDecodedInsts_5_bits_vpu_isDstMask = latched.vpu_isDstMask;
  assign io_out_complexDecodedInsts_5_bits_vpu_isOpMask = latched.vpu_isOpMask;
  assign io_out_complexDecodedInsts_5_bits_vpu_isDependOldVd = latched.vpu_isDependOldVd;
  assign io_out_complexDecodedInsts_5_bits_vpu_isWritePartVd = latched.vpu_isWritePartVd;
  assign io_out_complexDecodedInsts_5_bits_vpu_isVleff = latched.vpu_isVleff;
  assign io_out_complexDecodedInsts_5_bits_vlsInstr = out_var[5].vlsInstr;
  assign io_out_complexDecodedInsts_5_bits_wfflags = latched.wfflags;
  assign io_out_complexDecodedInsts_5_bits_isMove = latched.isMove;
  assign io_out_complexDecodedInsts_5_bits_uopIdx = out_var[5].uopIdx;
  assign io_out_complexDecodedInsts_5_bits_uopSplitType = latched.uopSplitType;
  assign io_out_complexDecodedInsts_5_bits_isVset = latched.isVset;
  assign io_out_complexDecodedInsts_5_bits_lastUop = out_var[5].lastUop;
  assign io_out_complexDecodedInsts_5_bits_numUops = latched_num_of_uop;
  assign io_out_complexDecodedInsts_5_bits_numWB = latched_num_of_wb;
  assign io_out_complexDecodedInsts_5_bits_commitType = latched.commitType;
  assign io_out_complexDecodedInsts_5_bits_debug_fuType = latched.debug_fuType;
  assign io_out_complexDecodedInsts_5_bits_debug_seqNum_seqNum = latched.debug_seqNum_seqNum;
  assign io_out_complexDecodedInsts_5_bits_debug_seqNum_uopIdx = latched.debug_seqNum_uopIdx;

  // END GENERATED

endmodule : DecodeUnitComp
