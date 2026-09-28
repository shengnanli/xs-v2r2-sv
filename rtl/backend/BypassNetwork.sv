// =============================================================================
// BypassNetwork.sv —— 后端旁路网络：给每个执行单元(EXU)的每个源操作数选出真正的数据
// -----------------------------------------------------------------------------
// 位置：IssueQueue(唤醒-选择) → DataPath(读寄存器堆/RegCache) → 【BypassNetwork】 → ExuBlock
// 设计源：src/main/scala/xiangshan/backend/datapath/BypassNetwork.scala
//         src/main/scala/xiangshan/backend/datapath/DataSource.scala
//
// 它解决的问题：一条 uop 发射时，它的源操作数的"生产者"可能刚刚算完、还没写回寄存器堆。
// 发射队列在唤醒时就已经决定好每个源从哪里取（这个决定随 uop 走过 DataPath 到这里）：
//   dataSources[s].value   —— 取哪一类来源（见下表 DS_*）；
//   exuSources[s].value    —— 若取 forward/bypass，生产者在"旁路组"里的序号(从 1 起，0=无)。
// 本模块只是一个**按这两个字段做选择的大型多路选择器**，加上两组很小的寄存器：
//   (1) bypass 寄存器：每个旁路源把自己的结果打一拍（valid 为使能），供"晚一拍"的消费者读；
//   (2) RegCache 写口：整数/load 生产者的结果打一拍后写进 RegCache（wen 带异步复位）。
//
// 每个源操作数的选择（Scala 里是 Mux1H；由于 dataSources.value 各码互斥，等价于按码 case）：
//   FORWARD(1)  生产者本拍的结果          （仅唤醒接收方：整数/浮点/标量访存）
//   BYPASS (2)  生产者上一拍的结果(寄存)   （同上）
//   IMM    (4)  立即数（ImmExtractor 还原；load 的 src0 是内联 U 型）
//   V0     (5)  向量 v0 掩码 = 本 uop 选好之后的 src3（仅向量单元的 src0..2）
//   REGCACHE(6) RegCache 读出             （整数与标量访存）
//   REG    (8)  物理寄存器堆读出
//   其它码(含 ZERO=0、本配置未接通的 BYPASS2=3) 一律给 0。
// 某类来源对某个 EXU 不存在时（例如浮点单元没有 RegCache），Chisel 把该项换成 false.B，
// 所以那个码在这个 EXU 上也落到 0 —— 下面的每-EXU 配置表 EXU_CFG 精确记录这件事。
//
// 分支/跳转单元(BJU)另有两项：imm 加上 ftqOffset<<1（JALR 除外），以及 nextPcOffset。
// 其余 ExuInput 字段（robIdx/pdest/fuType/...）与 valid/ready 都是直连，由 wrapper 接。
//
// 怪癖（均照 golden）：
//   * fp0 的旁路数据端口是 128 位（向量宽），但所有消费者只用低 64 位；本核的 bypass 寄存器
//     只存 64 位（golden 存 128，高 64 位没有任何读者）。
//   * RegCache 写口的 tag/addr 在本配置下被 firtool 删掉，只剩 wen/data。
//   * int_2_1 用 128 位的 ImmExtractor_12，结果截低 64 位用。
//
// 文件结构：bypassnetwork_pkg（参数/编码/每-EXU 配置表）→ xs_BypassNetwork_core（手写）
//           → golden 同名 wrapper BypassNetwork（由 scripts/gen_bypassnetwork.py 从 G1 golden
//           端口表生成；配置表也由它从 golden 的逐源表达式解析得到，带 --check）。
// 本文件导航（按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   L51    bypassnetwork_pkg：宽度参数 / DataSource 编码 / 旁路源与旁路组
//   L86    每-EXU 配置类型与 EXU_CFG 表（生成区）
//   L150   xs_BypassNetwork_core —— 可读核
//   L182   1. 旁路源：forward 直出 / bypass 寄存一拍
//   L207   2. 每个 EXU：立即数还原 + 逐源选择
//   L212   2a. 立即数（ImmExtractor 各变体 / load U 型）
//   L237   2b. 逐源按 dataSources 码选择
//   L269   2c. BJU：imm + ftqOffset、nextPcOffset
//   L283   3. RegCache 写口
//   L301   golden 同名 wrapper（生成区：端口表 / 打包 / 拆包 / 直连）
// =============================================================================
package bypassnetwork_pkg;

  localparam int XLEN    = 64;    // 标量数据宽度
  localparam int VLEN    = 128;   // 向量数据宽度（RegDataMaxWidth）
  localparam int NUM_EXU = 27;    // EXU 总数：int 8 + fp 5 + vf 5 + mem 9（顺序 = exuIdx）
  localparam int MAX_SRC = 5;     // 每个 EXU 至多 5 个源操作数（向量：vs1/vs2/old vd/v0/vl）

  // ---- DataSource.value 编码（DataSource.scala） ----
  localparam logic [3:0] DS_ZERO     = 4'b0000;  // 读 x0，恒 0
  localparam logic [3:0] DS_FORWARD  = 4'b0001;  // 生产者本拍结果
  localparam logic [3:0] DS_BYPASS   = 4'b0010;  // 生产者上一拍结果
  localparam logic [3:0] DS_BYPASS2  = 4'b0011;  // 二级旁路（本配置无源，恒 0）
  localparam logic [3:0] DS_IMM      = 4'b0100;  // 立即数
  localparam logic [3:0] DS_V0       = 4'b0101;  // 向量 v0
  localparam logic [3:0] DS_REGCACHE = 4'b0110;  // RegCache
  localparam logic [3:0] DS_REG      = 4'b1000;  // 物理寄存器堆

  // ---- 旁路源（生产者）：只有这 10 个 EXU 会把结果旁路出去 ----
  localparam int NUM_PROD = 10;
  localparam int P_INT0 = 0, P_INT1 = 1, P_INT2 = 2, P_INT3 = 3;  // 整数单元 int_0_0..int_3_0
  localparam int P_FP0  = 4, P_FP1  = 5, P_FP2  = 6;              // 浮点单元 fp_0_0..fp_2_0
  localparam int P_MEM2 = 7, P_MEM3 = 8, P_MEM4 = 9;              // load 单元 mem_2_0..mem_4_0

  // 两个旁路组：exuSources.value = v(≥1) 表示"本组第 v 个生产者"，v=0 表示无。
  //   整数组：整数与标量访存消费者监听（exuSources 3 位，v=1..7）
  //   浮点组：浮点消费者监听（exuSources 2 位，v=1..3）
  localparam int INT_GRP_N = 7;
  localparam int FP_GRP_N  = 3;
  localparam int INT_GRP [INT_GRP_N] = '{P_INT0, P_INT1, P_INT2, P_INT3, P_MEM2, P_MEM3, P_MEM4};
  localparam int FP_GRP  [FP_GRP_N]  = '{P_FP0, P_FP1, P_FP2};

  // RegCache 写口 k 的数据来源（整数组的 7 个生产者，顺序同上）
  localparam int NUM_RCW = 7;
  localparam int RCW_PROD [NUM_RCW] = '{P_INT0, P_INT1, P_INT2, P_INT3, P_MEM2, P_MEM3, P_MEM4};

  // ---- 每-EXU 配置 ----
  typedef enum logic [1:0] {
    FWD_NONE = 2'd0,   // 不是唤醒接收方：FORWARD/BYPASS 码落 0
    FWD_INT  = 2'd1,   // 监听整数组
    FWD_FP   = 2'd2    // 监听浮点组
  } fwd_grp_e;

  typedef enum logic [2:0] {
    IMM_NONE   = 3'd0, // 该 EXU 没有立即数：IMM 码落 0
    IMM_EXT    = 3'd1, // ImmExtractor    （整数 ALU 类：I/U/LUI32）
    IMM_EXT_2  = 3'd2, // ImmExtractor_2  （BJU：SB/U/UJ/I）
    IMM_EXT_12 = 3'd3, // ImmExtractor_12 （int_2_1：全类型，128 位）
    IMM_EXT_37 = 3'd4, // ImmExtractor_37 （vf_0_1：vset 类，128 位）
    IMM_EXT_57 = 3'd5, // ImmExtractor_57 （store 地址单元：S 型）
    IMM_LOAD_U = 3'd6  // load 单元 src0：内联 SignExt({imm[31:12], 12'b0})
  } imm_kind_e;

  typedef struct packed {
    logic [2:0] num_src;  // 源操作数个数
    fwd_grp_e   fwd;      // 旁路组
    logic       rc;       // 有 RegCache 读
    imm_kind_e  imm;      // 立即数来源
    logic       v0;       // 向量单元：src0..2 可读 v0（=本 uop 的 src3）
    logic       wide;     // 源操作数 128 位（向量）
    logic       bju;      // 分支/跳转单元：产出 imm(+ftqOffset) 与 nextPcOffset
  } exu_cfg_t;

  // BEGIN GENERATED(bypassnetwork_cfg)
  // 由 scripts/gen_bypassnetwork.py 从 G1 golden 的逐源 Mux1H 展开式解析得到（勿手改）。
  // 列：num_src / 旁路组 / RegCache / 立即数来源 / v0 / 128 位 / BJU
  localparam exu_cfg_t EXU_CFG [NUM_EXU] = '{
    '{3'd2, FWD_INT , 1'b1, IMM_EXT   , 1'b0, 1'b0, 1'b0},  //  0 int_0_0
    '{3'd2, FWD_INT , 1'b1, IMM_EXT_2 , 1'b0, 1'b0, 1'b1},  //  1 int_0_1
    '{3'd2, FWD_INT , 1'b1, IMM_EXT   , 1'b0, 1'b0, 1'b0},  //  2 int_1_0
    '{3'd2, FWD_INT , 1'b1, IMM_EXT_2 , 1'b0, 1'b0, 1'b1},  //  3 int_1_1
    '{3'd2, FWD_INT , 1'b1, IMM_EXT   , 1'b0, 1'b0, 1'b0},  //  4 int_2_0
    '{3'd2, FWD_INT , 1'b1, IMM_EXT_12, 1'b0, 1'b0, 1'b1},  //  5 int_2_1
    '{3'd2, FWD_INT , 1'b1, IMM_EXT   , 1'b0, 1'b0, 1'b0},  //  6 int_3_0
    '{3'd2, FWD_INT , 1'b1, IMM_NONE  , 1'b0, 1'b0, 1'b0},  //  7 int_3_1
    '{3'd3, FWD_FP  , 1'b0, IMM_NONE  , 1'b0, 1'b0, 1'b0},  //  8 fp_0_0
    '{3'd2, FWD_FP  , 1'b0, IMM_NONE  , 1'b0, 1'b0, 1'b0},  //  9 fp_0_1
    '{3'd3, FWD_FP  , 1'b0, IMM_NONE  , 1'b0, 1'b0, 1'b0},  // 10 fp_1_0
    '{3'd2, FWD_FP  , 1'b0, IMM_NONE  , 1'b0, 1'b0, 1'b0},  // 11 fp_1_1
    '{3'd3, FWD_FP  , 1'b0, IMM_NONE  , 1'b0, 1'b0, 1'b0},  // 12 fp_2_0
    '{3'd5, FWD_NONE, 1'b0, IMM_NONE  , 1'b1, 1'b1, 1'b0},  // 13 vf_0_0
    '{3'd5, FWD_NONE, 1'b0, IMM_EXT_37, 1'b1, 1'b1, 1'b0},  // 14 vf_0_1
    '{3'd5, FWD_NONE, 1'b0, IMM_NONE  , 1'b1, 1'b1, 1'b0},  // 15 vf_1_0
    '{3'd5, FWD_NONE, 1'b0, IMM_NONE  , 1'b1, 1'b1, 1'b0},  // 16 vf_1_1
    '{3'd5, FWD_NONE, 1'b0, IMM_NONE  , 1'b1, 1'b1, 1'b0},  // 17 vf_2_0
    '{3'd1, FWD_INT , 1'b1, IMM_EXT_57, 1'b0, 1'b0, 1'b0},  // 18 mem_0_0
    '{3'd1, FWD_INT , 1'b1, IMM_EXT_57, 1'b0, 1'b0, 1'b0},  // 19 mem_1_0
    '{3'd1, FWD_INT , 1'b1, IMM_LOAD_U, 1'b0, 1'b0, 1'b0},  // 20 mem_2_0
    '{3'd1, FWD_INT , 1'b1, IMM_LOAD_U, 1'b0, 1'b0, 1'b0},  // 21 mem_3_0
    '{3'd1, FWD_INT , 1'b1, IMM_LOAD_U, 1'b0, 1'b0, 1'b0},  // 22 mem_4_0
    '{3'd5, FWD_NONE, 1'b0, IMM_NONE  , 1'b1, 1'b1, 1'b0},  // 23 mem_5_0
    '{3'd5, FWD_NONE, 1'b0, IMM_NONE  , 1'b1, 1'b1, 1'b0},  // 24 mem_6_0
    '{3'd1, FWD_INT , 1'b1, IMM_NONE  , 1'b0, 1'b0, 1'b0},  // 25 mem_7_0
    '{3'd1, FWD_INT , 1'b1, IMM_NONE  , 1'b0, 1'b0, 1'b0}   // 26 mem_8_0
  };
  // END GENERATED

endpackage

// =============================================================================
// xs_BypassNetwork_core —— 可读核
// =============================================================================
module xs_BypassNetwork_core
  import bypassnetwork_pkg::*;
(
  input  logic                                clock,
  input  logic                                reset,
  // ---- 旁路源：10 个生产者本拍的结果 ----
  input  logic [NUM_PROD-1:0]                 prod_valid,
  input  logic [NUM_PROD-1:0][XLEN-1:0]       prod_data,
  input  logic [NUM_RCW-1:0]                  rcw_intWen,   // RegCache 写口对应生产者的 intWen
  // ---- 消费者：每个 EXU 的每个源 ----
  input  logic [3:0]                          ds       [NUM_EXU][MAX_SRC], // dataSources.value
  input  logic [2:0]                          exu_src  [NUM_EXU][MAX_SRC], // exuSources.value
  input  logic [VLEN-1:0]                     reg_data [NUM_EXU][MAX_SRC], // 寄存器堆读出
  input  logic [XLEN-1:0]                     rc_data  [NUM_EXU][MAX_SRC], // RegCache 读出
  input  logic [31:0]                         imm_raw  [NUM_EXU],          // 压缩立即数 immInfo.imm
  input  logic [3:0]                          imm_type [NUM_EXU],          // immInfo.immType
  // ---- BJU 专用输入 ----
  input  logic                                is_jump  [NUM_EXU],          // fuType 是 jmp
  input  logic                                op_jalr  [NUM_EXU],          // fuOpType 是 jalr
  input  logic [3:0]                          ftq_off  [NUM_EXU],          // ftqOffset
  input  logic                                is_rvc   [NUM_EXU],          // preDecode.isRVC
  // ---- 输出 ----
  output logic [VLEN-1:0]                     src_out  [NUM_EXU][MAX_SRC],
  output logic [XLEN-1:0]                     bju_imm  [NUM_EXU],
  output logic [4:0]                          bju_npc_off [NUM_EXU],
  output logic [NUM_RCW-1:0]                  rcw_wen,
  output logic [NUM_RCW-1:0][XLEN-1:0]        rcw_data
);

  // ---------------------------------------------------------------------------
  // 1. 旁路源的两份数据
  //    forward = 本拍直出；bypass = 上一拍 valid 时锁存（RegEnable，无复位）。
  // ---------------------------------------------------------------------------
  logic [NUM_PROD-1:0][XLEN-1:0] fwd_data;
  logic [NUM_PROD-1:0][XLEN-1:0] byp_data;

  assign fwd_data = prod_data;

  always_ff @(posedge clock) begin
    for (int p = 0; p < NUM_PROD; p++)
      if (prod_valid[p]) byp_data[p] <= prod_data[p];
  end

  // 从旁路组里按 exuSources 的序号取一路；序号 0 表示"无"，给 0。
  function automatic logic [XLEN-1:0] pick_int(input logic [NUM_PROD-1:0][XLEN-1:0] d,
                                               input logic [2:0] v);
    return (v == 3'd0) ? '0 : d[INT_GRP[v - 3'd1]];
  endfunction

  function automatic logic [XLEN-1:0] pick_fp(input logic [NUM_PROD-1:0][XLEN-1:0] d,
                                              input logic [1:0] v);
    return (v == 2'd0) ? '0 : d[FP_GRP[v - 2'd1]];
  endfunction

  // ---------------------------------------------------------------------------
  // 2. 每个 EXU：立即数还原 + 每个源的选择
  // ---------------------------------------------------------------------------
  for (genvar e = 0; e < NUM_EXU; e++) begin : g_exu
    localparam exu_cfg_t CFG = EXU_CFG[e];

    // 2a. 立即数：按该 EXU 的类型子集还原成数据宽度（ImmExtractor 各变体已独立签核）。
    logic [VLEN-1:0] imm;
    if (CFG.imm == IMM_EXT) begin : g_imm
      logic [XLEN-1:0] imm64;
      ImmExtractor    u_imm (.io_in_imm(imm_raw[e]), .io_in_immType(imm_type[e]), .io_out_imm(imm64));
      assign imm = VLEN'(imm64);
    end else if (CFG.imm == IMM_EXT_2) begin : g_imm
      logic [XLEN-1:0] imm64;
      ImmExtractor_2  u_imm (.io_in_imm(imm_raw[e]), .io_in_immType(imm_type[e]), .io_out_imm(imm64));
      assign imm = VLEN'(imm64);
    end else if (CFG.imm == IMM_EXT_12) begin : g_imm
      ImmExtractor_12 u_imm (.io_in_imm(imm_raw[e]), .io_in_immType(imm_type[e]), .io_out_imm(imm));
    end else if (CFG.imm == IMM_EXT_37) begin : g_imm
      ImmExtractor_37 u_imm (.io_in_imm(imm_raw[e]), .io_in_immType(imm_type[e]), .io_out_imm(imm));
    end else if (CFG.imm == IMM_EXT_57) begin : g_imm
      logic [XLEN-1:0] imm64;
      ImmExtractor_57 u_imm (.io_in_imm(imm_raw[e]), .io_in_immType(imm_type[e]), .io_out_imm(imm64));
      assign imm = VLEN'(imm64);
    end else if (CFG.imm == IMM_LOAD_U) begin : g_imm
      // load 的地址基 src0 读立即数时取 U 型高 20 位（lui+load 融合），符号扩展到 64 位
      assign imm = VLEN'({{(XLEN-32){imm_raw[e][31]}}, imm_raw[e][31:12], 12'b0});
    end else begin : g_imm
      assign imm = '0;
    end

    // 2b. 每个源：按 dataSources 码选择。
    //     src3 要先选（向量单元的 src0..2 读 v0 时，拿的是"已选好的 src3"）。
    for (genvar s = MAX_SRC - 1; s >= 0; s--) begin : g_src
      if (s < CFG.num_src) begin : g_on
        localparam int W = CFG.wide ? VLEN : XLEN;
        logic [W-1:0] sel;
        // v0 只对向量单元的 src0..2 存在，取的是本 uop 已选好的 src3
        logic [W-1:0] v0_data;
        if (CFG.v0 && s < 3) begin : g_v0
          assign v0_data = W'(src_out[e][3]);
        end else begin : g_nov0
          assign v0_data = '0;
        end
        always_comb begin
          unique case (ds[e][s])
            DS_FORWARD:  sel = (CFG.fwd == FWD_INT) ? W'(pick_int(fwd_data, exu_src[e][s]))      :
                               (CFG.fwd == FWD_FP)  ? W'(pick_fp (fwd_data, exu_src[e][s][1:0])) : '0;
            DS_BYPASS:   sel = (CFG.fwd == FWD_INT) ? W'(pick_int(byp_data, exu_src[e][s]))      :
                               (CFG.fwd == FWD_FP)  ? W'(pick_fp (byp_data, exu_src[e][s][1:0])) : '0;
            DS_IMM:      sel = W'(imm);
            DS_V0:       sel = v0_data;
            DS_REGCACHE: sel = CFG.rc ? W'(rc_data[e][s]) : '0;
            DS_REG:      sel = W'(reg_data[e][s]);
            default:     sel = '0;   // ZERO / BYPASS2(无源) / 未用码
          endcase
        end
        assign src_out[e][s] = VLEN'(sel);
      end else begin : g_off
        assign src_out[e][s] = '0;
      end
    end

    // 2c. 分支/跳转单元：目标偏移立即数与下一条指令的 PC 偏移
    //     imm = 还原立即数 + (JALR ? 0 : ftqOffset<<1)   —— 除 JALR 外都是 PC 相对
    //     nextPcOffset = ftqOffset + (RVC ? 1 : 2)      —— 以 2 字节为单位
    if (CFG.bju) begin : g_bju
      assign bju_imm[e]     = imm[XLEN-1:0]
                            + XLEN'((is_jump[e] & op_jalr[e]) ? 5'd0 : {ftq_off[e], 1'b0});
      assign bju_npc_off[e] = {1'b0, ftq_off[e]} + (is_rvc[e] ? 5'd1 : 5'd2);
    end else begin : g_nobju
      assign bju_imm[e]     = '0;
      assign bju_npc_off[e] = '0;
    end
  end

  // ---------------------------------------------------------------------------
  // 3. RegCache 写口：生产者 valid&intWen 打一拍作 wen（异步复位），数据取 bypass 寄存器
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      rcw_wen <= '0;
    else
      for (int k = 0; k < NUM_RCW; k++)
        rcw_wen[k] <= prod_valid[RCW_PROD[k]] & rcw_intWen[k];
  end

  for (genvar k = 0; k < NUM_RCW; k++) begin : g_rcw
    assign rcw_data[k] = byp_data[RCW_PROD[k]];
  end

endmodule

// BEGIN GENERATED(bypassnetwork_wrapper)
// =============================================================================
// BypassNetwork —— golden 同名 wrapper（由 scripts/gen_bypassnetwork.py 生成，勿手改）
// 端口逐行照抄 G1 golden；输入打包成核的数组接口，输出拆包；其余 ExuInput 字段直连。
// =============================================================================
module BypassNetwork
  import bypassnetwork_pkg::*;
(
  input          clock,
  input          reset,
  output         io_fromDataPath_int_3_1_ready,
  input          io_fromDataPath_int_3_1_valid,
  input  [34:0]  io_fromDataPath_int_3_1_bits_fuType,
  input  [8:0]   io_fromDataPath_int_3_1_bits_fuOpType,
  input  [63:0]  io_fromDataPath_int_3_1_bits_src_0,
  input  [63:0]  io_fromDataPath_int_3_1_bits_src_1,
  input  [63:0]  io_fromDataPath_int_3_1_bits_imm,
  input          io_fromDataPath_int_3_1_bits_robIdx_flag,
  input  [7:0]   io_fromDataPath_int_3_1_bits_robIdx_value,
  input  [7:0]   io_fromDataPath_int_3_1_bits_pdest,
  input          io_fromDataPath_int_3_1_bits_rfWen,
  input          io_fromDataPath_int_3_1_bits_flushPipe,
  input          io_fromDataPath_int_3_1_bits_preDecode_valid,
  input          io_fromDataPath_int_3_1_bits_preDecode_isRVC,
  input  [1:0]   io_fromDataPath_int_3_1_bits_preDecode_brType,
  input          io_fromDataPath_int_3_1_bits_preDecode_isCall,
  input          io_fromDataPath_int_3_1_bits_preDecode_isRet,
  input          io_fromDataPath_int_3_1_bits_ftqIdx_flag,
  input  [5:0]   io_fromDataPath_int_3_1_bits_ftqIdx_value,
  input  [3:0]   io_fromDataPath_int_3_1_bits_ftqOffset,
  input  [3:0]   io_fromDataPath_int_3_1_bits_dataSources_0_value,
  input  [3:0]   io_fromDataPath_int_3_1_bits_dataSources_1_value,
  input  [2:0]   io_fromDataPath_int_3_1_bits_exuSources_0_value,
  input  [2:0]   io_fromDataPath_int_3_1_bits_exuSources_1_value,
  input  [1:0]   io_fromDataPath_int_3_1_bits_loadDependency_0,
  input  [1:0]   io_fromDataPath_int_3_1_bits_loadDependency_1,
  input  [1:0]   io_fromDataPath_int_3_1_bits_loadDependency_2,
  input          io_fromDataPath_int_3_1_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromDataPath_int_3_1_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromDataPath_int_3_1_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromDataPath_int_3_1_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromDataPath_int_3_1_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromDataPath_int_3_1_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromDataPath_int_3_1_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromDataPath_int_3_1_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromDataPath_int_3_1_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromDataPath_int_3_1_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromDataPath_int_3_1_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromDataPath_int_3_1_bits_debug_seqNum_uopIdx,
  output         io_fromDataPath_int_3_0_ready,
  input          io_fromDataPath_int_3_0_valid,
  input  [34:0]  io_fromDataPath_int_3_0_bits_fuType,
  input  [8:0]   io_fromDataPath_int_3_0_bits_fuOpType,
  input  [63:0]  io_fromDataPath_int_3_0_bits_src_0,
  input  [63:0]  io_fromDataPath_int_3_0_bits_src_1,
  input          io_fromDataPath_int_3_0_bits_robIdx_flag,
  input  [7:0]   io_fromDataPath_int_3_0_bits_robIdx_value,
  input  [7:0]   io_fromDataPath_int_3_0_bits_pdest,
  input          io_fromDataPath_int_3_0_bits_rfWen,
  input  [3:0]   io_fromDataPath_int_3_0_bits_dataSources_0_value,
  input  [3:0]   io_fromDataPath_int_3_0_bits_dataSources_1_value,
  input  [2:0]   io_fromDataPath_int_3_0_bits_exuSources_0_value,
  input  [2:0]   io_fromDataPath_int_3_0_bits_exuSources_1_value,
  input  [1:0]   io_fromDataPath_int_3_0_bits_loadDependency_0,
  input  [1:0]   io_fromDataPath_int_3_0_bits_loadDependency_1,
  input  [1:0]   io_fromDataPath_int_3_0_bits_loadDependency_2,
  input          io_fromDataPath_int_3_0_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromDataPath_int_3_0_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromDataPath_int_3_0_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromDataPath_int_3_0_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromDataPath_int_3_0_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromDataPath_int_3_0_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromDataPath_int_3_0_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromDataPath_int_3_0_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromDataPath_int_3_0_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromDataPath_int_3_0_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromDataPath_int_3_0_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromDataPath_int_3_0_bits_debug_seqNum_uopIdx,
  output         io_fromDataPath_int_2_1_ready,
  input          io_fromDataPath_int_2_1_valid,
  input  [34:0]  io_fromDataPath_int_2_1_bits_fuType,
  input  [8:0]   io_fromDataPath_int_2_1_bits_fuOpType,
  input  [63:0]  io_fromDataPath_int_2_1_bits_src_0,
  input  [63:0]  io_fromDataPath_int_2_1_bits_src_1,
  input          io_fromDataPath_int_2_1_bits_robIdx_flag,
  input  [7:0]   io_fromDataPath_int_2_1_bits_robIdx_value,
  input  [7:0]   io_fromDataPath_int_2_1_bits_pdest,
  input          io_fromDataPath_int_2_1_bits_rfWen,
  input          io_fromDataPath_int_2_1_bits_fpWen,
  input          io_fromDataPath_int_2_1_bits_vecWen,
  input          io_fromDataPath_int_2_1_bits_v0Wen,
  input          io_fromDataPath_int_2_1_bits_vlWen,
  input  [1:0]   io_fromDataPath_int_2_1_bits_fpu_typeTagOut,
  input          io_fromDataPath_int_2_1_bits_fpu_wflags,
  input  [1:0]   io_fromDataPath_int_2_1_bits_fpu_typ,
  input  [2:0]   io_fromDataPath_int_2_1_bits_fpu_rm,
  input  [49:0]  io_fromDataPath_int_2_1_bits_pc,
  input          io_fromDataPath_int_2_1_bits_preDecode_valid,
  input          io_fromDataPath_int_2_1_bits_preDecode_isRVC,
  input  [1:0]   io_fromDataPath_int_2_1_bits_preDecode_brType,
  input          io_fromDataPath_int_2_1_bits_preDecode_isCall,
  input          io_fromDataPath_int_2_1_bits_preDecode_isRet,
  input          io_fromDataPath_int_2_1_bits_ftqIdx_flag,
  input  [5:0]   io_fromDataPath_int_2_1_bits_ftqIdx_value,
  input  [3:0]   io_fromDataPath_int_2_1_bits_ftqOffset,
  input  [49:0]  io_fromDataPath_int_2_1_bits_predictInfo_target,
  input          io_fromDataPath_int_2_1_bits_predictInfo_taken,
  input  [3:0]   io_fromDataPath_int_2_1_bits_dataSources_0_value,
  input  [3:0]   io_fromDataPath_int_2_1_bits_dataSources_1_value,
  input  [2:0]   io_fromDataPath_int_2_1_bits_exuSources_0_value,
  input  [2:0]   io_fromDataPath_int_2_1_bits_exuSources_1_value,
  input  [1:0]   io_fromDataPath_int_2_1_bits_loadDependency_0,
  input  [1:0]   io_fromDataPath_int_2_1_bits_loadDependency_1,
  input  [1:0]   io_fromDataPath_int_2_1_bits_loadDependency_2,
  input          io_fromDataPath_int_2_1_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromDataPath_int_2_1_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromDataPath_int_2_1_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromDataPath_int_2_1_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromDataPath_int_2_1_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromDataPath_int_2_1_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromDataPath_int_2_1_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromDataPath_int_2_1_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromDataPath_int_2_1_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromDataPath_int_2_1_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromDataPath_int_2_1_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromDataPath_int_2_1_bits_debug_seqNum_uopIdx,
  output         io_fromDataPath_int_2_0_ready,
  input          io_fromDataPath_int_2_0_valid,
  input  [34:0]  io_fromDataPath_int_2_0_bits_fuType,
  input  [8:0]   io_fromDataPath_int_2_0_bits_fuOpType,
  input  [63:0]  io_fromDataPath_int_2_0_bits_src_0,
  input  [63:0]  io_fromDataPath_int_2_0_bits_src_1,
  input          io_fromDataPath_int_2_0_bits_robIdx_flag,
  input  [7:0]   io_fromDataPath_int_2_0_bits_robIdx_value,
  input  [7:0]   io_fromDataPath_int_2_0_bits_pdest,
  input          io_fromDataPath_int_2_0_bits_rfWen,
  input  [3:0]   io_fromDataPath_int_2_0_bits_dataSources_0_value,
  input  [3:0]   io_fromDataPath_int_2_0_bits_dataSources_1_value,
  input  [2:0]   io_fromDataPath_int_2_0_bits_exuSources_0_value,
  input  [2:0]   io_fromDataPath_int_2_0_bits_exuSources_1_value,
  input  [1:0]   io_fromDataPath_int_2_0_bits_loadDependency_0,
  input  [1:0]   io_fromDataPath_int_2_0_bits_loadDependency_1,
  input  [1:0]   io_fromDataPath_int_2_0_bits_loadDependency_2,
  input          io_fromDataPath_int_2_0_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromDataPath_int_2_0_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromDataPath_int_2_0_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromDataPath_int_2_0_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromDataPath_int_2_0_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromDataPath_int_2_0_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromDataPath_int_2_0_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromDataPath_int_2_0_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromDataPath_int_2_0_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromDataPath_int_2_0_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromDataPath_int_2_0_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromDataPath_int_2_0_bits_debug_seqNum_uopIdx,
  output         io_fromDataPath_int_1_1_ready,
  input          io_fromDataPath_int_1_1_valid,
  input  [34:0]  io_fromDataPath_int_1_1_bits_fuType,
  input  [8:0]   io_fromDataPath_int_1_1_bits_fuOpType,
  input  [63:0]  io_fromDataPath_int_1_1_bits_src_0,
  input  [63:0]  io_fromDataPath_int_1_1_bits_src_1,
  input          io_fromDataPath_int_1_1_bits_robIdx_flag,
  input  [7:0]   io_fromDataPath_int_1_1_bits_robIdx_value,
  input  [7:0]   io_fromDataPath_int_1_1_bits_pdest,
  input          io_fromDataPath_int_1_1_bits_rfWen,
  input  [49:0]  io_fromDataPath_int_1_1_bits_pc,
  input          io_fromDataPath_int_1_1_bits_preDecode_valid,
  input          io_fromDataPath_int_1_1_bits_preDecode_isRVC,
  input  [1:0]   io_fromDataPath_int_1_1_bits_preDecode_brType,
  input          io_fromDataPath_int_1_1_bits_preDecode_isCall,
  input          io_fromDataPath_int_1_1_bits_preDecode_isRet,
  input          io_fromDataPath_int_1_1_bits_ftqIdx_flag,
  input  [5:0]   io_fromDataPath_int_1_1_bits_ftqIdx_value,
  input  [3:0]   io_fromDataPath_int_1_1_bits_ftqOffset,
  input  [49:0]  io_fromDataPath_int_1_1_bits_predictInfo_target,
  input          io_fromDataPath_int_1_1_bits_predictInfo_taken,
  input  [3:0]   io_fromDataPath_int_1_1_bits_dataSources_0_value,
  input  [3:0]   io_fromDataPath_int_1_1_bits_dataSources_1_value,
  input  [2:0]   io_fromDataPath_int_1_1_bits_exuSources_0_value,
  input  [2:0]   io_fromDataPath_int_1_1_bits_exuSources_1_value,
  input  [1:0]   io_fromDataPath_int_1_1_bits_loadDependency_0,
  input  [1:0]   io_fromDataPath_int_1_1_bits_loadDependency_1,
  input  [1:0]   io_fromDataPath_int_1_1_bits_loadDependency_2,
  input          io_fromDataPath_int_1_1_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromDataPath_int_1_1_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromDataPath_int_1_1_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromDataPath_int_1_1_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromDataPath_int_1_1_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromDataPath_int_1_1_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromDataPath_int_1_1_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromDataPath_int_1_1_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromDataPath_int_1_1_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromDataPath_int_1_1_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromDataPath_int_1_1_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromDataPath_int_1_1_bits_debug_seqNum_uopIdx,
  output         io_fromDataPath_int_1_0_ready,
  input          io_fromDataPath_int_1_0_valid,
  input  [34:0]  io_fromDataPath_int_1_0_bits_fuType,
  input  [8:0]   io_fromDataPath_int_1_0_bits_fuOpType,
  input  [63:0]  io_fromDataPath_int_1_0_bits_src_0,
  input  [63:0]  io_fromDataPath_int_1_0_bits_src_1,
  input          io_fromDataPath_int_1_0_bits_robIdx_flag,
  input  [7:0]   io_fromDataPath_int_1_0_bits_robIdx_value,
  input  [7:0]   io_fromDataPath_int_1_0_bits_pdest,
  input          io_fromDataPath_int_1_0_bits_rfWen,
  input  [3:0]   io_fromDataPath_int_1_0_bits_dataSources_0_value,
  input  [3:0]   io_fromDataPath_int_1_0_bits_dataSources_1_value,
  input  [2:0]   io_fromDataPath_int_1_0_bits_exuSources_0_value,
  input  [2:0]   io_fromDataPath_int_1_0_bits_exuSources_1_value,
  input  [1:0]   io_fromDataPath_int_1_0_bits_loadDependency_0,
  input  [1:0]   io_fromDataPath_int_1_0_bits_loadDependency_1,
  input  [1:0]   io_fromDataPath_int_1_0_bits_loadDependency_2,
  input          io_fromDataPath_int_1_0_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromDataPath_int_1_0_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromDataPath_int_1_0_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromDataPath_int_1_0_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromDataPath_int_1_0_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromDataPath_int_1_0_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromDataPath_int_1_0_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromDataPath_int_1_0_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromDataPath_int_1_0_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromDataPath_int_1_0_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromDataPath_int_1_0_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromDataPath_int_1_0_bits_debug_seqNum_uopIdx,
  output         io_fromDataPath_int_0_1_ready,
  input          io_fromDataPath_int_0_1_valid,
  input  [34:0]  io_fromDataPath_int_0_1_bits_fuType,
  input  [8:0]   io_fromDataPath_int_0_1_bits_fuOpType,
  input  [63:0]  io_fromDataPath_int_0_1_bits_src_0,
  input  [63:0]  io_fromDataPath_int_0_1_bits_src_1,
  input          io_fromDataPath_int_0_1_bits_robIdx_flag,
  input  [7:0]   io_fromDataPath_int_0_1_bits_robIdx_value,
  input  [7:0]   io_fromDataPath_int_0_1_bits_pdest,
  input          io_fromDataPath_int_0_1_bits_rfWen,
  input  [49:0]  io_fromDataPath_int_0_1_bits_pc,
  input          io_fromDataPath_int_0_1_bits_preDecode_valid,
  input          io_fromDataPath_int_0_1_bits_preDecode_isRVC,
  input  [1:0]   io_fromDataPath_int_0_1_bits_preDecode_brType,
  input          io_fromDataPath_int_0_1_bits_preDecode_isCall,
  input          io_fromDataPath_int_0_1_bits_preDecode_isRet,
  input          io_fromDataPath_int_0_1_bits_ftqIdx_flag,
  input  [5:0]   io_fromDataPath_int_0_1_bits_ftqIdx_value,
  input  [3:0]   io_fromDataPath_int_0_1_bits_ftqOffset,
  input  [49:0]  io_fromDataPath_int_0_1_bits_predictInfo_target,
  input          io_fromDataPath_int_0_1_bits_predictInfo_taken,
  input  [3:0]   io_fromDataPath_int_0_1_bits_dataSources_0_value,
  input  [3:0]   io_fromDataPath_int_0_1_bits_dataSources_1_value,
  input  [2:0]   io_fromDataPath_int_0_1_bits_exuSources_0_value,
  input  [2:0]   io_fromDataPath_int_0_1_bits_exuSources_1_value,
  input  [1:0]   io_fromDataPath_int_0_1_bits_loadDependency_0,
  input  [1:0]   io_fromDataPath_int_0_1_bits_loadDependency_1,
  input  [1:0]   io_fromDataPath_int_0_1_bits_loadDependency_2,
  input          io_fromDataPath_int_0_1_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromDataPath_int_0_1_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromDataPath_int_0_1_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromDataPath_int_0_1_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromDataPath_int_0_1_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromDataPath_int_0_1_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromDataPath_int_0_1_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromDataPath_int_0_1_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromDataPath_int_0_1_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromDataPath_int_0_1_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromDataPath_int_0_1_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromDataPath_int_0_1_bits_debug_seqNum_uopIdx,
  output         io_fromDataPath_int_0_0_ready,
  input          io_fromDataPath_int_0_0_valid,
  input  [34:0]  io_fromDataPath_int_0_0_bits_fuType,
  input  [8:0]   io_fromDataPath_int_0_0_bits_fuOpType,
  input  [63:0]  io_fromDataPath_int_0_0_bits_src_0,
  input  [63:0]  io_fromDataPath_int_0_0_bits_src_1,
  input          io_fromDataPath_int_0_0_bits_robIdx_flag,
  input  [7:0]   io_fromDataPath_int_0_0_bits_robIdx_value,
  input  [7:0]   io_fromDataPath_int_0_0_bits_pdest,
  input          io_fromDataPath_int_0_0_bits_rfWen,
  input  [3:0]   io_fromDataPath_int_0_0_bits_dataSources_0_value,
  input  [3:0]   io_fromDataPath_int_0_0_bits_dataSources_1_value,
  input  [2:0]   io_fromDataPath_int_0_0_bits_exuSources_0_value,
  input  [2:0]   io_fromDataPath_int_0_0_bits_exuSources_1_value,
  input  [1:0]   io_fromDataPath_int_0_0_bits_loadDependency_0,
  input  [1:0]   io_fromDataPath_int_0_0_bits_loadDependency_1,
  input  [1:0]   io_fromDataPath_int_0_0_bits_loadDependency_2,
  input          io_fromDataPath_int_0_0_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromDataPath_int_0_0_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromDataPath_int_0_0_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromDataPath_int_0_0_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromDataPath_int_0_0_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromDataPath_int_0_0_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromDataPath_int_0_0_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromDataPath_int_0_0_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromDataPath_int_0_0_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromDataPath_int_0_0_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromDataPath_int_0_0_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromDataPath_int_0_0_bits_debug_seqNum_uopIdx,
  output         io_fromDataPath_fp_2_0_ready,
  input          io_fromDataPath_fp_2_0_valid,
  input  [34:0]  io_fromDataPath_fp_2_0_bits_fuType,
  input  [8:0]   io_fromDataPath_fp_2_0_bits_fuOpType,
  input  [63:0]  io_fromDataPath_fp_2_0_bits_src_0,
  input  [63:0]  io_fromDataPath_fp_2_0_bits_src_1,
  input  [63:0]  io_fromDataPath_fp_2_0_bits_src_2,
  input          io_fromDataPath_fp_2_0_bits_robIdx_flag,
  input  [7:0]   io_fromDataPath_fp_2_0_bits_robIdx_value,
  input  [7:0]   io_fromDataPath_fp_2_0_bits_pdest,
  input          io_fromDataPath_fp_2_0_bits_rfWen,
  input          io_fromDataPath_fp_2_0_bits_fpWen,
  input          io_fromDataPath_fp_2_0_bits_fpu_wflags,
  input  [1:0]   io_fromDataPath_fp_2_0_bits_fpu_fmt,
  input  [2:0]   io_fromDataPath_fp_2_0_bits_fpu_rm,
  input  [3:0]   io_fromDataPath_fp_2_0_bits_dataSources_0_value,
  input  [3:0]   io_fromDataPath_fp_2_0_bits_dataSources_1_value,
  input  [3:0]   io_fromDataPath_fp_2_0_bits_dataSources_2_value,
  input  [1:0]   io_fromDataPath_fp_2_0_bits_exuSources_0_value,
  input  [1:0]   io_fromDataPath_fp_2_0_bits_exuSources_1_value,
  input  [1:0]   io_fromDataPath_fp_2_0_bits_exuSources_2_value,
  input          io_fromDataPath_fp_2_0_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromDataPath_fp_2_0_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromDataPath_fp_2_0_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromDataPath_fp_2_0_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromDataPath_fp_2_0_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromDataPath_fp_2_0_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromDataPath_fp_2_0_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromDataPath_fp_2_0_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromDataPath_fp_2_0_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromDataPath_fp_2_0_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromDataPath_fp_2_0_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromDataPath_fp_2_0_bits_debug_seqNum_uopIdx,
  output         io_fromDataPath_fp_1_1_ready,
  input          io_fromDataPath_fp_1_1_valid,
  input  [34:0]  io_fromDataPath_fp_1_1_bits_fuType,
  input  [8:0]   io_fromDataPath_fp_1_1_bits_fuOpType,
  input  [63:0]  io_fromDataPath_fp_1_1_bits_src_0,
  input  [63:0]  io_fromDataPath_fp_1_1_bits_src_1,
  input          io_fromDataPath_fp_1_1_bits_robIdx_flag,
  input  [7:0]   io_fromDataPath_fp_1_1_bits_robIdx_value,
  input  [7:0]   io_fromDataPath_fp_1_1_bits_pdest,
  input          io_fromDataPath_fp_1_1_bits_fpWen,
  input          io_fromDataPath_fp_1_1_bits_fpu_wflags,
  input  [1:0]   io_fromDataPath_fp_1_1_bits_fpu_fmt,
  input  [2:0]   io_fromDataPath_fp_1_1_bits_fpu_rm,
  input  [3:0]   io_fromDataPath_fp_1_1_bits_dataSources_0_value,
  input  [3:0]   io_fromDataPath_fp_1_1_bits_dataSources_1_value,
  input  [1:0]   io_fromDataPath_fp_1_1_bits_exuSources_0_value,
  input  [1:0]   io_fromDataPath_fp_1_1_bits_exuSources_1_value,
  input          io_fromDataPath_fp_1_1_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromDataPath_fp_1_1_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromDataPath_fp_1_1_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromDataPath_fp_1_1_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromDataPath_fp_1_1_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromDataPath_fp_1_1_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromDataPath_fp_1_1_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromDataPath_fp_1_1_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromDataPath_fp_1_1_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromDataPath_fp_1_1_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromDataPath_fp_1_1_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromDataPath_fp_1_1_bits_debug_seqNum_uopIdx,
  output         io_fromDataPath_fp_1_0_ready,
  input          io_fromDataPath_fp_1_0_valid,
  input  [34:0]  io_fromDataPath_fp_1_0_bits_fuType,
  input  [8:0]   io_fromDataPath_fp_1_0_bits_fuOpType,
  input  [63:0]  io_fromDataPath_fp_1_0_bits_src_0,
  input  [63:0]  io_fromDataPath_fp_1_0_bits_src_1,
  input  [63:0]  io_fromDataPath_fp_1_0_bits_src_2,
  input          io_fromDataPath_fp_1_0_bits_robIdx_flag,
  input  [7:0]   io_fromDataPath_fp_1_0_bits_robIdx_value,
  input  [7:0]   io_fromDataPath_fp_1_0_bits_pdest,
  input          io_fromDataPath_fp_1_0_bits_rfWen,
  input          io_fromDataPath_fp_1_0_bits_fpWen,
  input          io_fromDataPath_fp_1_0_bits_fpu_wflags,
  input  [1:0]   io_fromDataPath_fp_1_0_bits_fpu_fmt,
  input  [2:0]   io_fromDataPath_fp_1_0_bits_fpu_rm,
  input  [3:0]   io_fromDataPath_fp_1_0_bits_dataSources_0_value,
  input  [3:0]   io_fromDataPath_fp_1_0_bits_dataSources_1_value,
  input  [3:0]   io_fromDataPath_fp_1_0_bits_dataSources_2_value,
  input  [1:0]   io_fromDataPath_fp_1_0_bits_exuSources_0_value,
  input  [1:0]   io_fromDataPath_fp_1_0_bits_exuSources_1_value,
  input  [1:0]   io_fromDataPath_fp_1_0_bits_exuSources_2_value,
  input          io_fromDataPath_fp_1_0_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromDataPath_fp_1_0_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromDataPath_fp_1_0_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromDataPath_fp_1_0_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromDataPath_fp_1_0_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromDataPath_fp_1_0_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromDataPath_fp_1_0_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromDataPath_fp_1_0_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromDataPath_fp_1_0_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromDataPath_fp_1_0_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromDataPath_fp_1_0_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromDataPath_fp_1_0_bits_debug_seqNum_uopIdx,
  output         io_fromDataPath_fp_0_1_ready,
  input          io_fromDataPath_fp_0_1_valid,
  input  [34:0]  io_fromDataPath_fp_0_1_bits_fuType,
  input  [8:0]   io_fromDataPath_fp_0_1_bits_fuOpType,
  input  [63:0]  io_fromDataPath_fp_0_1_bits_src_0,
  input  [63:0]  io_fromDataPath_fp_0_1_bits_src_1,
  input          io_fromDataPath_fp_0_1_bits_robIdx_flag,
  input  [7:0]   io_fromDataPath_fp_0_1_bits_robIdx_value,
  input  [7:0]   io_fromDataPath_fp_0_1_bits_pdest,
  input          io_fromDataPath_fp_0_1_bits_fpWen,
  input          io_fromDataPath_fp_0_1_bits_fpu_wflags,
  input  [1:0]   io_fromDataPath_fp_0_1_bits_fpu_fmt,
  input  [2:0]   io_fromDataPath_fp_0_1_bits_fpu_rm,
  input  [3:0]   io_fromDataPath_fp_0_1_bits_dataSources_0_value,
  input  [3:0]   io_fromDataPath_fp_0_1_bits_dataSources_1_value,
  input  [1:0]   io_fromDataPath_fp_0_1_bits_exuSources_0_value,
  input  [1:0]   io_fromDataPath_fp_0_1_bits_exuSources_1_value,
  input          io_fromDataPath_fp_0_1_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromDataPath_fp_0_1_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromDataPath_fp_0_1_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromDataPath_fp_0_1_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromDataPath_fp_0_1_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromDataPath_fp_0_1_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromDataPath_fp_0_1_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromDataPath_fp_0_1_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromDataPath_fp_0_1_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromDataPath_fp_0_1_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromDataPath_fp_0_1_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromDataPath_fp_0_1_bits_debug_seqNum_uopIdx,
  output         io_fromDataPath_fp_0_0_ready,
  input          io_fromDataPath_fp_0_0_valid,
  input  [34:0]  io_fromDataPath_fp_0_0_bits_fuType,
  input  [8:0]   io_fromDataPath_fp_0_0_bits_fuOpType,
  input  [63:0]  io_fromDataPath_fp_0_0_bits_src_0,
  input  [63:0]  io_fromDataPath_fp_0_0_bits_src_1,
  input  [63:0]  io_fromDataPath_fp_0_0_bits_src_2,
  input          io_fromDataPath_fp_0_0_bits_robIdx_flag,
  input  [7:0]   io_fromDataPath_fp_0_0_bits_robIdx_value,
  input  [7:0]   io_fromDataPath_fp_0_0_bits_pdest,
  input          io_fromDataPath_fp_0_0_bits_rfWen,
  input          io_fromDataPath_fp_0_0_bits_fpWen,
  input          io_fromDataPath_fp_0_0_bits_vecWen,
  input          io_fromDataPath_fp_0_0_bits_v0Wen,
  input          io_fromDataPath_fp_0_0_bits_fpu_wflags,
  input  [1:0]   io_fromDataPath_fp_0_0_bits_fpu_fmt,
  input  [2:0]   io_fromDataPath_fp_0_0_bits_fpu_rm,
  input  [3:0]   io_fromDataPath_fp_0_0_bits_dataSources_0_value,
  input  [3:0]   io_fromDataPath_fp_0_0_bits_dataSources_1_value,
  input  [3:0]   io_fromDataPath_fp_0_0_bits_dataSources_2_value,
  input  [1:0]   io_fromDataPath_fp_0_0_bits_exuSources_0_value,
  input  [1:0]   io_fromDataPath_fp_0_0_bits_exuSources_1_value,
  input  [1:0]   io_fromDataPath_fp_0_0_bits_exuSources_2_value,
  input          io_fromDataPath_fp_0_0_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromDataPath_fp_0_0_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromDataPath_fp_0_0_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromDataPath_fp_0_0_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromDataPath_fp_0_0_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromDataPath_fp_0_0_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromDataPath_fp_0_0_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromDataPath_fp_0_0_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromDataPath_fp_0_0_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromDataPath_fp_0_0_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromDataPath_fp_0_0_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromDataPath_fp_0_0_bits_debug_seqNum_uopIdx,
  output         io_fromDataPath_vf_2_0_ready,
  input          io_fromDataPath_vf_2_0_valid,
  input  [34:0]  io_fromDataPath_vf_2_0_bits_fuType,
  input  [8:0]   io_fromDataPath_vf_2_0_bits_fuOpType,
  input  [127:0] io_fromDataPath_vf_2_0_bits_src_0,
  input  [127:0] io_fromDataPath_vf_2_0_bits_src_1,
  input  [127:0] io_fromDataPath_vf_2_0_bits_src_2,
  input  [127:0] io_fromDataPath_vf_2_0_bits_src_3,
  input  [127:0] io_fromDataPath_vf_2_0_bits_src_4,
  input          io_fromDataPath_vf_2_0_bits_robIdx_flag,
  input  [7:0]   io_fromDataPath_vf_2_0_bits_robIdx_value,
  input  [6:0]   io_fromDataPath_vf_2_0_bits_pdest,
  input          io_fromDataPath_vf_2_0_bits_vecWen,
  input          io_fromDataPath_vf_2_0_bits_v0Wen,
  input          io_fromDataPath_vf_2_0_bits_fpu_wflags,
  input          io_fromDataPath_vf_2_0_bits_vpu_vma,
  input          io_fromDataPath_vf_2_0_bits_vpu_vta,
  input  [1:0]   io_fromDataPath_vf_2_0_bits_vpu_vsew,
  input  [2:0]   io_fromDataPath_vf_2_0_bits_vpu_vlmul,
  input          io_fromDataPath_vf_2_0_bits_vpu_vm,
  input  [7:0]   io_fromDataPath_vf_2_0_bits_vpu_vstart,
  input  [6:0]   io_fromDataPath_vf_2_0_bits_vpu_vuopIdx,
  input          io_fromDataPath_vf_2_0_bits_vpu_isExt,
  input          io_fromDataPath_vf_2_0_bits_vpu_isNarrow,
  input          io_fromDataPath_vf_2_0_bits_vpu_isDstMask,
  input          io_fromDataPath_vf_2_0_bits_vpu_isOpMask,
  input  [3:0]   io_fromDataPath_vf_2_0_bits_dataSources_0_value,
  input  [3:0]   io_fromDataPath_vf_2_0_bits_dataSources_1_value,
  input  [3:0]   io_fromDataPath_vf_2_0_bits_dataSources_2_value,
  input  [3:0]   io_fromDataPath_vf_2_0_bits_dataSources_3_value,
  input  [3:0]   io_fromDataPath_vf_2_0_bits_dataSources_4_value,
  input          io_fromDataPath_vf_2_0_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromDataPath_vf_2_0_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromDataPath_vf_2_0_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromDataPath_vf_2_0_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromDataPath_vf_2_0_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromDataPath_vf_2_0_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromDataPath_vf_2_0_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromDataPath_vf_2_0_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromDataPath_vf_2_0_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromDataPath_vf_2_0_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromDataPath_vf_2_0_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromDataPath_vf_2_0_bits_debug_seqNum_uopIdx,
  output         io_fromDataPath_vf_1_1_ready,
  input          io_fromDataPath_vf_1_1_valid,
  input  [34:0]  io_fromDataPath_vf_1_1_bits_fuType,
  input  [8:0]   io_fromDataPath_vf_1_1_bits_fuOpType,
  input  [127:0] io_fromDataPath_vf_1_1_bits_src_0,
  input  [127:0] io_fromDataPath_vf_1_1_bits_src_1,
  input  [127:0] io_fromDataPath_vf_1_1_bits_src_2,
  input  [127:0] io_fromDataPath_vf_1_1_bits_src_3,
  input  [127:0] io_fromDataPath_vf_1_1_bits_src_4,
  input          io_fromDataPath_vf_1_1_bits_robIdx_flag,
  input  [7:0]   io_fromDataPath_vf_1_1_bits_robIdx_value,
  input  [7:0]   io_fromDataPath_vf_1_1_bits_pdest,
  input          io_fromDataPath_vf_1_1_bits_fpWen,
  input          io_fromDataPath_vf_1_1_bits_vecWen,
  input          io_fromDataPath_vf_1_1_bits_v0Wen,
  input          io_fromDataPath_vf_1_1_bits_fpu_wflags,
  input          io_fromDataPath_vf_1_1_bits_vpu_vma,
  input          io_fromDataPath_vf_1_1_bits_vpu_vta,
  input  [1:0]   io_fromDataPath_vf_1_1_bits_vpu_vsew,
  input  [2:0]   io_fromDataPath_vf_1_1_bits_vpu_vlmul,
  input          io_fromDataPath_vf_1_1_bits_vpu_vm,
  input  [7:0]   io_fromDataPath_vf_1_1_bits_vpu_vstart,
  input          io_fromDataPath_vf_1_1_bits_vpu_fpu_isFoldTo1_2,
  input          io_fromDataPath_vf_1_1_bits_vpu_fpu_isFoldTo1_4,
  input          io_fromDataPath_vf_1_1_bits_vpu_fpu_isFoldTo1_8,
  input  [6:0]   io_fromDataPath_vf_1_1_bits_vpu_vuopIdx,
  input          io_fromDataPath_vf_1_1_bits_vpu_lastUop,
  input          io_fromDataPath_vf_1_1_bits_vpu_isNarrow,
  input          io_fromDataPath_vf_1_1_bits_vpu_isDstMask,
  input  [3:0]   io_fromDataPath_vf_1_1_bits_dataSources_0_value,
  input  [3:0]   io_fromDataPath_vf_1_1_bits_dataSources_1_value,
  input  [3:0]   io_fromDataPath_vf_1_1_bits_dataSources_2_value,
  input  [3:0]   io_fromDataPath_vf_1_1_bits_dataSources_3_value,
  input  [3:0]   io_fromDataPath_vf_1_1_bits_dataSources_4_value,
  input          io_fromDataPath_vf_1_1_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromDataPath_vf_1_1_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromDataPath_vf_1_1_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromDataPath_vf_1_1_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromDataPath_vf_1_1_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromDataPath_vf_1_1_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromDataPath_vf_1_1_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromDataPath_vf_1_1_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromDataPath_vf_1_1_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromDataPath_vf_1_1_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromDataPath_vf_1_1_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromDataPath_vf_1_1_bits_debug_seqNum_uopIdx,
  output         io_fromDataPath_vf_1_0_ready,
  input          io_fromDataPath_vf_1_0_valid,
  input  [34:0]  io_fromDataPath_vf_1_0_bits_fuType,
  input  [8:0]   io_fromDataPath_vf_1_0_bits_fuOpType,
  input  [127:0] io_fromDataPath_vf_1_0_bits_src_0,
  input  [127:0] io_fromDataPath_vf_1_0_bits_src_1,
  input  [127:0] io_fromDataPath_vf_1_0_bits_src_2,
  input  [127:0] io_fromDataPath_vf_1_0_bits_src_3,
  input  [127:0] io_fromDataPath_vf_1_0_bits_src_4,
  input          io_fromDataPath_vf_1_0_bits_robIdx_flag,
  input  [7:0]   io_fromDataPath_vf_1_0_bits_robIdx_value,
  input  [6:0]   io_fromDataPath_vf_1_0_bits_pdest,
  input          io_fromDataPath_vf_1_0_bits_vecWen,
  input          io_fromDataPath_vf_1_0_bits_v0Wen,
  input          io_fromDataPath_vf_1_0_bits_fpu_wflags,
  input          io_fromDataPath_vf_1_0_bits_vpu_vma,
  input          io_fromDataPath_vf_1_0_bits_vpu_vta,
  input  [1:0]   io_fromDataPath_vf_1_0_bits_vpu_vsew,
  input  [2:0]   io_fromDataPath_vf_1_0_bits_vpu_vlmul,
  input          io_fromDataPath_vf_1_0_bits_vpu_vm,
  input  [7:0]   io_fromDataPath_vf_1_0_bits_vpu_vstart,
  input  [6:0]   io_fromDataPath_vf_1_0_bits_vpu_vuopIdx,
  input          io_fromDataPath_vf_1_0_bits_vpu_isExt,
  input          io_fromDataPath_vf_1_0_bits_vpu_isNarrow,
  input          io_fromDataPath_vf_1_0_bits_vpu_isDstMask,
  input          io_fromDataPath_vf_1_0_bits_vpu_isOpMask,
  input  [3:0]   io_fromDataPath_vf_1_0_bits_dataSources_0_value,
  input  [3:0]   io_fromDataPath_vf_1_0_bits_dataSources_1_value,
  input  [3:0]   io_fromDataPath_vf_1_0_bits_dataSources_2_value,
  input  [3:0]   io_fromDataPath_vf_1_0_bits_dataSources_3_value,
  input  [3:0]   io_fromDataPath_vf_1_0_bits_dataSources_4_value,
  input          io_fromDataPath_vf_1_0_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromDataPath_vf_1_0_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromDataPath_vf_1_0_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromDataPath_vf_1_0_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromDataPath_vf_1_0_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromDataPath_vf_1_0_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromDataPath_vf_1_0_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromDataPath_vf_1_0_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromDataPath_vf_1_0_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromDataPath_vf_1_0_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromDataPath_vf_1_0_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromDataPath_vf_1_0_bits_debug_seqNum_uopIdx,
  output         io_fromDataPath_vf_0_1_ready,
  input          io_fromDataPath_vf_0_1_valid,
  input  [34:0]  io_fromDataPath_vf_0_1_bits_fuType,
  input  [8:0]   io_fromDataPath_vf_0_1_bits_fuOpType,
  input  [127:0] io_fromDataPath_vf_0_1_bits_src_0,
  input  [127:0] io_fromDataPath_vf_0_1_bits_src_1,
  input  [127:0] io_fromDataPath_vf_0_1_bits_src_2,
  input  [127:0] io_fromDataPath_vf_0_1_bits_src_3,
  input  [127:0] io_fromDataPath_vf_0_1_bits_src_4,
  input          io_fromDataPath_vf_0_1_bits_robIdx_flag,
  input  [7:0]   io_fromDataPath_vf_0_1_bits_robIdx_value,
  input  [7:0]   io_fromDataPath_vf_0_1_bits_pdest,
  input          io_fromDataPath_vf_0_1_bits_rfWen,
  input          io_fromDataPath_vf_0_1_bits_fpWen,
  input          io_fromDataPath_vf_0_1_bits_vecWen,
  input          io_fromDataPath_vf_0_1_bits_v0Wen,
  input          io_fromDataPath_vf_0_1_bits_vlWen,
  input          io_fromDataPath_vf_0_1_bits_fpu_wflags,
  input          io_fromDataPath_vf_0_1_bits_vpu_vma,
  input          io_fromDataPath_vf_0_1_bits_vpu_vta,
  input  [1:0]   io_fromDataPath_vf_0_1_bits_vpu_vsew,
  input  [2:0]   io_fromDataPath_vf_0_1_bits_vpu_vlmul,
  input          io_fromDataPath_vf_0_1_bits_vpu_vm,
  input  [7:0]   io_fromDataPath_vf_0_1_bits_vpu_vstart,
  input          io_fromDataPath_vf_0_1_bits_vpu_fpu_isFoldTo1_2,
  input          io_fromDataPath_vf_0_1_bits_vpu_fpu_isFoldTo1_4,
  input          io_fromDataPath_vf_0_1_bits_vpu_fpu_isFoldTo1_8,
  input  [6:0]   io_fromDataPath_vf_0_1_bits_vpu_vuopIdx,
  input          io_fromDataPath_vf_0_1_bits_vpu_lastUop,
  input          io_fromDataPath_vf_0_1_bits_vpu_isNarrow,
  input          io_fromDataPath_vf_0_1_bits_vpu_isDstMask,
  input  [3:0]   io_fromDataPath_vf_0_1_bits_dataSources_0_value,
  input  [3:0]   io_fromDataPath_vf_0_1_bits_dataSources_1_value,
  input  [3:0]   io_fromDataPath_vf_0_1_bits_dataSources_2_value,
  input  [3:0]   io_fromDataPath_vf_0_1_bits_dataSources_3_value,
  input  [3:0]   io_fromDataPath_vf_0_1_bits_dataSources_4_value,
  input          io_fromDataPath_vf_0_1_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromDataPath_vf_0_1_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromDataPath_vf_0_1_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromDataPath_vf_0_1_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromDataPath_vf_0_1_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromDataPath_vf_0_1_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromDataPath_vf_0_1_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromDataPath_vf_0_1_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromDataPath_vf_0_1_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromDataPath_vf_0_1_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromDataPath_vf_0_1_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromDataPath_vf_0_1_bits_debug_seqNum_uopIdx,
  output         io_fromDataPath_vf_0_0_ready,
  input          io_fromDataPath_vf_0_0_valid,
  input  [34:0]  io_fromDataPath_vf_0_0_bits_fuType,
  input  [8:0]   io_fromDataPath_vf_0_0_bits_fuOpType,
  input  [127:0] io_fromDataPath_vf_0_0_bits_src_0,
  input  [127:0] io_fromDataPath_vf_0_0_bits_src_1,
  input  [127:0] io_fromDataPath_vf_0_0_bits_src_2,
  input  [127:0] io_fromDataPath_vf_0_0_bits_src_3,
  input  [127:0] io_fromDataPath_vf_0_0_bits_src_4,
  input          io_fromDataPath_vf_0_0_bits_robIdx_flag,
  input  [7:0]   io_fromDataPath_vf_0_0_bits_robIdx_value,
  input  [6:0]   io_fromDataPath_vf_0_0_bits_pdest,
  input          io_fromDataPath_vf_0_0_bits_vecWen,
  input          io_fromDataPath_vf_0_0_bits_v0Wen,
  input          io_fromDataPath_vf_0_0_bits_fpu_wflags,
  input          io_fromDataPath_vf_0_0_bits_vpu_vma,
  input          io_fromDataPath_vf_0_0_bits_vpu_vta,
  input  [1:0]   io_fromDataPath_vf_0_0_bits_vpu_vsew,
  input  [2:0]   io_fromDataPath_vf_0_0_bits_vpu_vlmul,
  input          io_fromDataPath_vf_0_0_bits_vpu_vm,
  input  [7:0]   io_fromDataPath_vf_0_0_bits_vpu_vstart,
  input  [6:0]   io_fromDataPath_vf_0_0_bits_vpu_vuopIdx,
  input          io_fromDataPath_vf_0_0_bits_vpu_isExt,
  input          io_fromDataPath_vf_0_0_bits_vpu_isNarrow,
  input          io_fromDataPath_vf_0_0_bits_vpu_isDstMask,
  input          io_fromDataPath_vf_0_0_bits_vpu_isOpMask,
  input  [3:0]   io_fromDataPath_vf_0_0_bits_dataSources_0_value,
  input  [3:0]   io_fromDataPath_vf_0_0_bits_dataSources_1_value,
  input  [3:0]   io_fromDataPath_vf_0_0_bits_dataSources_2_value,
  input  [3:0]   io_fromDataPath_vf_0_0_bits_dataSources_3_value,
  input  [3:0]   io_fromDataPath_vf_0_0_bits_dataSources_4_value,
  input          io_fromDataPath_vf_0_0_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromDataPath_vf_0_0_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromDataPath_vf_0_0_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromDataPath_vf_0_0_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromDataPath_vf_0_0_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromDataPath_vf_0_0_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromDataPath_vf_0_0_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromDataPath_vf_0_0_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromDataPath_vf_0_0_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromDataPath_vf_0_0_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromDataPath_vf_0_0_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromDataPath_vf_0_0_bits_debug_seqNum_uopIdx,
  output         io_fromDataPath_mem_8_0_ready,
  input          io_fromDataPath_mem_8_0_valid,
  input  [34:0]  io_fromDataPath_mem_8_0_bits_fuType,
  input  [8:0]   io_fromDataPath_mem_8_0_bits_fuOpType,
  input  [63:0]  io_fromDataPath_mem_8_0_bits_src_0,
  input          io_fromDataPath_mem_8_0_bits_robIdx_flag,
  input  [7:0]   io_fromDataPath_mem_8_0_bits_robIdx_value,
  input          io_fromDataPath_mem_8_0_bits_sqIdx_flag,
  input  [5:0]   io_fromDataPath_mem_8_0_bits_sqIdx_value,
  input  [3:0]   io_fromDataPath_mem_8_0_bits_dataSources_0_value,
  input  [2:0]   io_fromDataPath_mem_8_0_bits_exuSources_0_value,
  input  [1:0]   io_fromDataPath_mem_8_0_bits_loadDependency_0,
  input  [1:0]   io_fromDataPath_mem_8_0_bits_loadDependency_1,
  input  [1:0]   io_fromDataPath_mem_8_0_bits_loadDependency_2,
  output         io_fromDataPath_mem_7_0_ready,
  input          io_fromDataPath_mem_7_0_valid,
  input  [34:0]  io_fromDataPath_mem_7_0_bits_fuType,
  input  [8:0]   io_fromDataPath_mem_7_0_bits_fuOpType,
  input  [63:0]  io_fromDataPath_mem_7_0_bits_src_0,
  input          io_fromDataPath_mem_7_0_bits_robIdx_flag,
  input  [7:0]   io_fromDataPath_mem_7_0_bits_robIdx_value,
  input          io_fromDataPath_mem_7_0_bits_sqIdx_flag,
  input  [5:0]   io_fromDataPath_mem_7_0_bits_sqIdx_value,
  input  [3:0]   io_fromDataPath_mem_7_0_bits_dataSources_0_value,
  input  [2:0]   io_fromDataPath_mem_7_0_bits_exuSources_0_value,
  input  [1:0]   io_fromDataPath_mem_7_0_bits_loadDependency_0,
  input  [1:0]   io_fromDataPath_mem_7_0_bits_loadDependency_1,
  input  [1:0]   io_fromDataPath_mem_7_0_bits_loadDependency_2,
  output         io_fromDataPath_mem_6_0_ready,
  input          io_fromDataPath_mem_6_0_valid,
  input  [34:0]  io_fromDataPath_mem_6_0_bits_fuType,
  input  [8:0]   io_fromDataPath_mem_6_0_bits_fuOpType,
  input  [127:0] io_fromDataPath_mem_6_0_bits_src_0,
  input  [127:0] io_fromDataPath_mem_6_0_bits_src_1,
  input  [127:0] io_fromDataPath_mem_6_0_bits_src_2,
  input  [127:0] io_fromDataPath_mem_6_0_bits_src_3,
  input  [127:0] io_fromDataPath_mem_6_0_bits_src_4,
  input          io_fromDataPath_mem_6_0_bits_robIdx_flag,
  input  [7:0]   io_fromDataPath_mem_6_0_bits_robIdx_value,
  input  [6:0]   io_fromDataPath_mem_6_0_bits_pdest,
  input          io_fromDataPath_mem_6_0_bits_vecWen,
  input          io_fromDataPath_mem_6_0_bits_v0Wen,
  input          io_fromDataPath_mem_6_0_bits_vlWen,
  input          io_fromDataPath_mem_6_0_bits_vpu_vill,
  input          io_fromDataPath_mem_6_0_bits_vpu_vma,
  input          io_fromDataPath_mem_6_0_bits_vpu_vta,
  input  [1:0]   io_fromDataPath_mem_6_0_bits_vpu_vsew,
  input  [2:0]   io_fromDataPath_mem_6_0_bits_vpu_vlmul,
  input          io_fromDataPath_mem_6_0_bits_vpu_specVill,
  input          io_fromDataPath_mem_6_0_bits_vpu_specVma,
  input          io_fromDataPath_mem_6_0_bits_vpu_specVta,
  input  [1:0]   io_fromDataPath_mem_6_0_bits_vpu_specVsew,
  input  [2:0]   io_fromDataPath_mem_6_0_bits_vpu_specVlmul,
  input          io_fromDataPath_mem_6_0_bits_vpu_vm,
  input  [7:0]   io_fromDataPath_mem_6_0_bits_vpu_vstart,
  input  [2:0]   io_fromDataPath_mem_6_0_bits_vpu_frm,
  input          io_fromDataPath_mem_6_0_bits_vpu_fpu_isFpToVecInst,
  input          io_fromDataPath_mem_6_0_bits_vpu_fpu_isFP32Instr,
  input          io_fromDataPath_mem_6_0_bits_vpu_fpu_isFP64Instr,
  input          io_fromDataPath_mem_6_0_bits_vpu_fpu_isReduction,
  input          io_fromDataPath_mem_6_0_bits_vpu_fpu_isFoldTo1_2,
  input          io_fromDataPath_mem_6_0_bits_vpu_fpu_isFoldTo1_4,
  input          io_fromDataPath_mem_6_0_bits_vpu_fpu_isFoldTo1_8,
  input  [1:0]   io_fromDataPath_mem_6_0_bits_vpu_vxrm,
  input  [6:0]   io_fromDataPath_mem_6_0_bits_vpu_vuopIdx,
  input          io_fromDataPath_mem_6_0_bits_vpu_lastUop,
  input  [127:0] io_fromDataPath_mem_6_0_bits_vpu_vmask,
  input  [2:0]   io_fromDataPath_mem_6_0_bits_vpu_nf,
  input  [1:0]   io_fromDataPath_mem_6_0_bits_vpu_veew,
  input          io_fromDataPath_mem_6_0_bits_vpu_isReverse,
  input          io_fromDataPath_mem_6_0_bits_vpu_isExt,
  input          io_fromDataPath_mem_6_0_bits_vpu_isNarrow,
  input          io_fromDataPath_mem_6_0_bits_vpu_isDstMask,
  input          io_fromDataPath_mem_6_0_bits_vpu_isOpMask,
  input          io_fromDataPath_mem_6_0_bits_vpu_isMove,
  input          io_fromDataPath_mem_6_0_bits_vpu_isDependOldVd,
  input          io_fromDataPath_mem_6_0_bits_vpu_isWritePartVd,
  input          io_fromDataPath_mem_6_0_bits_vpu_isVleff,
  input          io_fromDataPath_mem_6_0_bits_ftqIdx_flag,
  input  [5:0]   io_fromDataPath_mem_6_0_bits_ftqIdx_value,
  input  [3:0]   io_fromDataPath_mem_6_0_bits_ftqOffset,
  input  [4:0]   io_fromDataPath_mem_6_0_bits_numLsElem,
  input          io_fromDataPath_mem_6_0_bits_sqIdx_flag,
  input  [5:0]   io_fromDataPath_mem_6_0_bits_sqIdx_value,
  input          io_fromDataPath_mem_6_0_bits_lqIdx_flag,
  input  [6:0]   io_fromDataPath_mem_6_0_bits_lqIdx_value,
  input  [3:0]   io_fromDataPath_mem_6_0_bits_dataSources_0_value,
  input  [3:0]   io_fromDataPath_mem_6_0_bits_dataSources_1_value,
  input  [3:0]   io_fromDataPath_mem_6_0_bits_dataSources_2_value,
  input  [3:0]   io_fromDataPath_mem_6_0_bits_dataSources_3_value,
  input  [3:0]   io_fromDataPath_mem_6_0_bits_dataSources_4_value,
  input          io_fromDataPath_mem_6_0_bits_isVecPartReplay,
  input  [15:0]  io_fromDataPath_mem_6_0_bits_vecReplayMask,
  input  [3:0]   io_fromDataPath_mem_6_0_bits_vecReplayMbIdx,
  input          io_fromDataPath_mem_6_0_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromDataPath_mem_6_0_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromDataPath_mem_6_0_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromDataPath_mem_6_0_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromDataPath_mem_6_0_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromDataPath_mem_6_0_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromDataPath_mem_6_0_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromDataPath_mem_6_0_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromDataPath_mem_6_0_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromDataPath_mem_6_0_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromDataPath_mem_6_0_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromDataPath_mem_6_0_bits_debug_seqNum_uopIdx,
  output         io_fromDataPath_mem_5_0_ready,
  input          io_fromDataPath_mem_5_0_valid,
  input  [34:0]  io_fromDataPath_mem_5_0_bits_fuType,
  input  [8:0]   io_fromDataPath_mem_5_0_bits_fuOpType,
  input  [127:0] io_fromDataPath_mem_5_0_bits_src_0,
  input  [127:0] io_fromDataPath_mem_5_0_bits_src_1,
  input  [127:0] io_fromDataPath_mem_5_0_bits_src_2,
  input  [127:0] io_fromDataPath_mem_5_0_bits_src_3,
  input  [127:0] io_fromDataPath_mem_5_0_bits_src_4,
  input          io_fromDataPath_mem_5_0_bits_robIdx_flag,
  input  [7:0]   io_fromDataPath_mem_5_0_bits_robIdx_value,
  input  [6:0]   io_fromDataPath_mem_5_0_bits_pdest,
  input          io_fromDataPath_mem_5_0_bits_vecWen,
  input          io_fromDataPath_mem_5_0_bits_v0Wen,
  input          io_fromDataPath_mem_5_0_bits_vlWen,
  input          io_fromDataPath_mem_5_0_bits_vpu_vill,
  input          io_fromDataPath_mem_5_0_bits_vpu_vma,
  input          io_fromDataPath_mem_5_0_bits_vpu_vta,
  input  [1:0]   io_fromDataPath_mem_5_0_bits_vpu_vsew,
  input  [2:0]   io_fromDataPath_mem_5_0_bits_vpu_vlmul,
  input          io_fromDataPath_mem_5_0_bits_vpu_specVill,
  input          io_fromDataPath_mem_5_0_bits_vpu_specVma,
  input          io_fromDataPath_mem_5_0_bits_vpu_specVta,
  input  [1:0]   io_fromDataPath_mem_5_0_bits_vpu_specVsew,
  input  [2:0]   io_fromDataPath_mem_5_0_bits_vpu_specVlmul,
  input          io_fromDataPath_mem_5_0_bits_vpu_vm,
  input  [7:0]   io_fromDataPath_mem_5_0_bits_vpu_vstart,
  input  [2:0]   io_fromDataPath_mem_5_0_bits_vpu_frm,
  input          io_fromDataPath_mem_5_0_bits_vpu_fpu_isFpToVecInst,
  input          io_fromDataPath_mem_5_0_bits_vpu_fpu_isFP32Instr,
  input          io_fromDataPath_mem_5_0_bits_vpu_fpu_isFP64Instr,
  input          io_fromDataPath_mem_5_0_bits_vpu_fpu_isReduction,
  input          io_fromDataPath_mem_5_0_bits_vpu_fpu_isFoldTo1_2,
  input          io_fromDataPath_mem_5_0_bits_vpu_fpu_isFoldTo1_4,
  input          io_fromDataPath_mem_5_0_bits_vpu_fpu_isFoldTo1_8,
  input  [1:0]   io_fromDataPath_mem_5_0_bits_vpu_vxrm,
  input  [6:0]   io_fromDataPath_mem_5_0_bits_vpu_vuopIdx,
  input          io_fromDataPath_mem_5_0_bits_vpu_lastUop,
  input  [127:0] io_fromDataPath_mem_5_0_bits_vpu_vmask,
  input  [2:0]   io_fromDataPath_mem_5_0_bits_vpu_nf,
  input  [1:0]   io_fromDataPath_mem_5_0_bits_vpu_veew,
  input          io_fromDataPath_mem_5_0_bits_vpu_isReverse,
  input          io_fromDataPath_mem_5_0_bits_vpu_isExt,
  input          io_fromDataPath_mem_5_0_bits_vpu_isNarrow,
  input          io_fromDataPath_mem_5_0_bits_vpu_isDstMask,
  input          io_fromDataPath_mem_5_0_bits_vpu_isOpMask,
  input          io_fromDataPath_mem_5_0_bits_vpu_isMove,
  input          io_fromDataPath_mem_5_0_bits_vpu_isDependOldVd,
  input          io_fromDataPath_mem_5_0_bits_vpu_isWritePartVd,
  input          io_fromDataPath_mem_5_0_bits_vpu_isVleff,
  input          io_fromDataPath_mem_5_0_bits_ftqIdx_flag,
  input  [5:0]   io_fromDataPath_mem_5_0_bits_ftqIdx_value,
  input  [3:0]   io_fromDataPath_mem_5_0_bits_ftqOffset,
  input  [4:0]   io_fromDataPath_mem_5_0_bits_numLsElem,
  input          io_fromDataPath_mem_5_0_bits_sqIdx_flag,
  input  [5:0]   io_fromDataPath_mem_5_0_bits_sqIdx_value,
  input          io_fromDataPath_mem_5_0_bits_lqIdx_flag,
  input  [6:0]   io_fromDataPath_mem_5_0_bits_lqIdx_value,
  input  [3:0]   io_fromDataPath_mem_5_0_bits_dataSources_0_value,
  input  [3:0]   io_fromDataPath_mem_5_0_bits_dataSources_1_value,
  input  [3:0]   io_fromDataPath_mem_5_0_bits_dataSources_2_value,
  input  [3:0]   io_fromDataPath_mem_5_0_bits_dataSources_3_value,
  input  [3:0]   io_fromDataPath_mem_5_0_bits_dataSources_4_value,
  input          io_fromDataPath_mem_5_0_bits_isVecPartReplay,
  input  [15:0]  io_fromDataPath_mem_5_0_bits_vecReplayMask,
  input  [3:0]   io_fromDataPath_mem_5_0_bits_vecReplayMbIdx,
  input          io_fromDataPath_mem_5_0_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromDataPath_mem_5_0_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromDataPath_mem_5_0_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromDataPath_mem_5_0_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromDataPath_mem_5_0_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromDataPath_mem_5_0_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromDataPath_mem_5_0_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromDataPath_mem_5_0_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromDataPath_mem_5_0_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromDataPath_mem_5_0_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromDataPath_mem_5_0_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromDataPath_mem_5_0_bits_debug_seqNum_uopIdx,
  output         io_fromDataPath_mem_4_0_ready,
  input          io_fromDataPath_mem_4_0_valid,
  input  [34:0]  io_fromDataPath_mem_4_0_bits_fuType,
  input  [8:0]   io_fromDataPath_mem_4_0_bits_fuOpType,
  input  [63:0]  io_fromDataPath_mem_4_0_bits_src_0,
  input  [63:0]  io_fromDataPath_mem_4_0_bits_imm,
  input          io_fromDataPath_mem_4_0_bits_robIdx_flag,
  input  [7:0]   io_fromDataPath_mem_4_0_bits_robIdx_value,
  input  [7:0]   io_fromDataPath_mem_4_0_bits_pdest,
  input          io_fromDataPath_mem_4_0_bits_rfWen,
  input          io_fromDataPath_mem_4_0_bits_fpWen,
  input  [49:0]  io_fromDataPath_mem_4_0_bits_pc,
  input          io_fromDataPath_mem_4_0_bits_preDecode_valid,
  input          io_fromDataPath_mem_4_0_bits_preDecode_isRVC,
  input  [1:0]   io_fromDataPath_mem_4_0_bits_preDecode_brType,
  input          io_fromDataPath_mem_4_0_bits_preDecode_isCall,
  input          io_fromDataPath_mem_4_0_bits_preDecode_isRet,
  input          io_fromDataPath_mem_4_0_bits_ftqIdx_flag,
  input  [5:0]   io_fromDataPath_mem_4_0_bits_ftqIdx_value,
  input  [3:0]   io_fromDataPath_mem_4_0_bits_ftqOffset,
  input          io_fromDataPath_mem_4_0_bits_loadWaitBit,
  input          io_fromDataPath_mem_4_0_bits_waitForRobIdx_flag,
  input  [7:0]   io_fromDataPath_mem_4_0_bits_waitForRobIdx_value,
  input          io_fromDataPath_mem_4_0_bits_storeSetHit,
  input          io_fromDataPath_mem_4_0_bits_loadWaitStrict,
  input  [4:0]   io_fromDataPath_mem_4_0_bits_ssid,
  input          io_fromDataPath_mem_4_0_bits_sqIdx_flag,
  input  [5:0]   io_fromDataPath_mem_4_0_bits_sqIdx_value,
  input          io_fromDataPath_mem_4_0_bits_lqIdx_flag,
  input  [6:0]   io_fromDataPath_mem_4_0_bits_lqIdx_value,
  input  [3:0]   io_fromDataPath_mem_4_0_bits_dataSources_0_value,
  input  [2:0]   io_fromDataPath_mem_4_0_bits_exuSources_0_value,
  input  [1:0]   io_fromDataPath_mem_4_0_bits_loadDependency_0,
  input  [1:0]   io_fromDataPath_mem_4_0_bits_loadDependency_1,
  input  [1:0]   io_fromDataPath_mem_4_0_bits_loadDependency_2,
  input          io_fromDataPath_mem_4_0_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromDataPath_mem_4_0_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromDataPath_mem_4_0_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromDataPath_mem_4_0_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromDataPath_mem_4_0_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromDataPath_mem_4_0_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromDataPath_mem_4_0_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromDataPath_mem_4_0_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromDataPath_mem_4_0_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromDataPath_mem_4_0_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromDataPath_mem_4_0_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromDataPath_mem_4_0_bits_debug_seqNum_uopIdx,
  output         io_fromDataPath_mem_3_0_ready,
  input          io_fromDataPath_mem_3_0_valid,
  input  [34:0]  io_fromDataPath_mem_3_0_bits_fuType,
  input  [8:0]   io_fromDataPath_mem_3_0_bits_fuOpType,
  input  [63:0]  io_fromDataPath_mem_3_0_bits_src_0,
  input  [63:0]  io_fromDataPath_mem_3_0_bits_imm,
  input          io_fromDataPath_mem_3_0_bits_robIdx_flag,
  input  [7:0]   io_fromDataPath_mem_3_0_bits_robIdx_value,
  input  [7:0]   io_fromDataPath_mem_3_0_bits_pdest,
  input          io_fromDataPath_mem_3_0_bits_rfWen,
  input          io_fromDataPath_mem_3_0_bits_fpWen,
  input  [49:0]  io_fromDataPath_mem_3_0_bits_pc,
  input          io_fromDataPath_mem_3_0_bits_preDecode_valid,
  input          io_fromDataPath_mem_3_0_bits_preDecode_isRVC,
  input  [1:0]   io_fromDataPath_mem_3_0_bits_preDecode_brType,
  input          io_fromDataPath_mem_3_0_bits_preDecode_isCall,
  input          io_fromDataPath_mem_3_0_bits_preDecode_isRet,
  input          io_fromDataPath_mem_3_0_bits_ftqIdx_flag,
  input  [5:0]   io_fromDataPath_mem_3_0_bits_ftqIdx_value,
  input  [3:0]   io_fromDataPath_mem_3_0_bits_ftqOffset,
  input          io_fromDataPath_mem_3_0_bits_loadWaitBit,
  input          io_fromDataPath_mem_3_0_bits_waitForRobIdx_flag,
  input  [7:0]   io_fromDataPath_mem_3_0_bits_waitForRobIdx_value,
  input          io_fromDataPath_mem_3_0_bits_storeSetHit,
  input          io_fromDataPath_mem_3_0_bits_loadWaitStrict,
  input  [4:0]   io_fromDataPath_mem_3_0_bits_ssid,
  input          io_fromDataPath_mem_3_0_bits_sqIdx_flag,
  input  [5:0]   io_fromDataPath_mem_3_0_bits_sqIdx_value,
  input          io_fromDataPath_mem_3_0_bits_lqIdx_flag,
  input  [6:0]   io_fromDataPath_mem_3_0_bits_lqIdx_value,
  input  [3:0]   io_fromDataPath_mem_3_0_bits_dataSources_0_value,
  input  [2:0]   io_fromDataPath_mem_3_0_bits_exuSources_0_value,
  input  [1:0]   io_fromDataPath_mem_3_0_bits_loadDependency_0,
  input  [1:0]   io_fromDataPath_mem_3_0_bits_loadDependency_1,
  input  [1:0]   io_fromDataPath_mem_3_0_bits_loadDependency_2,
  input          io_fromDataPath_mem_3_0_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromDataPath_mem_3_0_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromDataPath_mem_3_0_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromDataPath_mem_3_0_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromDataPath_mem_3_0_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromDataPath_mem_3_0_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromDataPath_mem_3_0_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromDataPath_mem_3_0_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromDataPath_mem_3_0_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromDataPath_mem_3_0_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromDataPath_mem_3_0_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromDataPath_mem_3_0_bits_debug_seqNum_uopIdx,
  output         io_fromDataPath_mem_2_0_ready,
  input          io_fromDataPath_mem_2_0_valid,
  input  [34:0]  io_fromDataPath_mem_2_0_bits_fuType,
  input  [8:0]   io_fromDataPath_mem_2_0_bits_fuOpType,
  input  [63:0]  io_fromDataPath_mem_2_0_bits_src_0,
  input  [63:0]  io_fromDataPath_mem_2_0_bits_imm,
  input          io_fromDataPath_mem_2_0_bits_robIdx_flag,
  input  [7:0]   io_fromDataPath_mem_2_0_bits_robIdx_value,
  input  [7:0]   io_fromDataPath_mem_2_0_bits_pdest,
  input          io_fromDataPath_mem_2_0_bits_rfWen,
  input          io_fromDataPath_mem_2_0_bits_fpWen,
  input  [49:0]  io_fromDataPath_mem_2_0_bits_pc,
  input          io_fromDataPath_mem_2_0_bits_preDecode_valid,
  input          io_fromDataPath_mem_2_0_bits_preDecode_isRVC,
  input  [1:0]   io_fromDataPath_mem_2_0_bits_preDecode_brType,
  input          io_fromDataPath_mem_2_0_bits_preDecode_isCall,
  input          io_fromDataPath_mem_2_0_bits_preDecode_isRet,
  input          io_fromDataPath_mem_2_0_bits_ftqIdx_flag,
  input  [5:0]   io_fromDataPath_mem_2_0_bits_ftqIdx_value,
  input  [3:0]   io_fromDataPath_mem_2_0_bits_ftqOffset,
  input          io_fromDataPath_mem_2_0_bits_loadWaitBit,
  input          io_fromDataPath_mem_2_0_bits_waitForRobIdx_flag,
  input  [7:0]   io_fromDataPath_mem_2_0_bits_waitForRobIdx_value,
  input          io_fromDataPath_mem_2_0_bits_storeSetHit,
  input          io_fromDataPath_mem_2_0_bits_loadWaitStrict,
  input  [4:0]   io_fromDataPath_mem_2_0_bits_ssid,
  input          io_fromDataPath_mem_2_0_bits_sqIdx_flag,
  input  [5:0]   io_fromDataPath_mem_2_0_bits_sqIdx_value,
  input          io_fromDataPath_mem_2_0_bits_lqIdx_flag,
  input  [6:0]   io_fromDataPath_mem_2_0_bits_lqIdx_value,
  input  [3:0]   io_fromDataPath_mem_2_0_bits_dataSources_0_value,
  input  [2:0]   io_fromDataPath_mem_2_0_bits_exuSources_0_value,
  input  [1:0]   io_fromDataPath_mem_2_0_bits_loadDependency_0,
  input  [1:0]   io_fromDataPath_mem_2_0_bits_loadDependency_1,
  input  [1:0]   io_fromDataPath_mem_2_0_bits_loadDependency_2,
  input          io_fromDataPath_mem_2_0_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromDataPath_mem_2_0_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromDataPath_mem_2_0_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromDataPath_mem_2_0_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromDataPath_mem_2_0_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromDataPath_mem_2_0_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromDataPath_mem_2_0_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromDataPath_mem_2_0_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromDataPath_mem_2_0_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromDataPath_mem_2_0_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromDataPath_mem_2_0_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromDataPath_mem_2_0_bits_debug_seqNum_uopIdx,
  output         io_fromDataPath_mem_1_0_ready,
  input          io_fromDataPath_mem_1_0_valid,
  input  [34:0]  io_fromDataPath_mem_1_0_bits_fuType,
  input  [8:0]   io_fromDataPath_mem_1_0_bits_fuOpType,
  input  [63:0]  io_fromDataPath_mem_1_0_bits_src_0,
  input  [63:0]  io_fromDataPath_mem_1_0_bits_imm,
  input          io_fromDataPath_mem_1_0_bits_robIdx_flag,
  input  [7:0]   io_fromDataPath_mem_1_0_bits_robIdx_value,
  input          io_fromDataPath_mem_1_0_bits_isFirstIssue,
  input  [7:0]   io_fromDataPath_mem_1_0_bits_pdest,
  input          io_fromDataPath_mem_1_0_bits_rfWen,
  input          io_fromDataPath_mem_1_0_bits_ftqIdx_flag,
  input  [5:0]   io_fromDataPath_mem_1_0_bits_ftqIdx_value,
  input  [3:0]   io_fromDataPath_mem_1_0_bits_ftqOffset,
  input          io_fromDataPath_mem_1_0_bits_sqIdx_flag,
  input  [5:0]   io_fromDataPath_mem_1_0_bits_sqIdx_value,
  input          io_fromDataPath_mem_1_0_bits_lqIdx_flag,
  input  [6:0]   io_fromDataPath_mem_1_0_bits_lqIdx_value,
  input  [3:0]   io_fromDataPath_mem_1_0_bits_dataSources_0_value,
  input  [2:0]   io_fromDataPath_mem_1_0_bits_exuSources_0_value,
  input  [1:0]   io_fromDataPath_mem_1_0_bits_loadDependency_0,
  input  [1:0]   io_fromDataPath_mem_1_0_bits_loadDependency_1,
  input  [1:0]   io_fromDataPath_mem_1_0_bits_loadDependency_2,
  input          io_fromDataPath_mem_1_0_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromDataPath_mem_1_0_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromDataPath_mem_1_0_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromDataPath_mem_1_0_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromDataPath_mem_1_0_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromDataPath_mem_1_0_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromDataPath_mem_1_0_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromDataPath_mem_1_0_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromDataPath_mem_1_0_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromDataPath_mem_1_0_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromDataPath_mem_1_0_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromDataPath_mem_1_0_bits_debug_seqNum_uopIdx,
  output         io_fromDataPath_mem_0_0_ready,
  input          io_fromDataPath_mem_0_0_valid,
  input  [34:0]  io_fromDataPath_mem_0_0_bits_fuType,
  input  [8:0]   io_fromDataPath_mem_0_0_bits_fuOpType,
  input  [63:0]  io_fromDataPath_mem_0_0_bits_src_0,
  input  [63:0]  io_fromDataPath_mem_0_0_bits_imm,
  input          io_fromDataPath_mem_0_0_bits_robIdx_flag,
  input  [7:0]   io_fromDataPath_mem_0_0_bits_robIdx_value,
  input          io_fromDataPath_mem_0_0_bits_isFirstIssue,
  input  [7:0]   io_fromDataPath_mem_0_0_bits_pdest,
  input          io_fromDataPath_mem_0_0_bits_rfWen,
  input          io_fromDataPath_mem_0_0_bits_ftqIdx_flag,
  input  [5:0]   io_fromDataPath_mem_0_0_bits_ftqIdx_value,
  input  [3:0]   io_fromDataPath_mem_0_0_bits_ftqOffset,
  input          io_fromDataPath_mem_0_0_bits_sqIdx_flag,
  input  [5:0]   io_fromDataPath_mem_0_0_bits_sqIdx_value,
  input          io_fromDataPath_mem_0_0_bits_lqIdx_flag,
  input  [6:0]   io_fromDataPath_mem_0_0_bits_lqIdx_value,
  input  [3:0]   io_fromDataPath_mem_0_0_bits_dataSources_0_value,
  input  [2:0]   io_fromDataPath_mem_0_0_bits_exuSources_0_value,
  input  [1:0]   io_fromDataPath_mem_0_0_bits_loadDependency_0,
  input  [1:0]   io_fromDataPath_mem_0_0_bits_loadDependency_1,
  input  [1:0]   io_fromDataPath_mem_0_0_bits_loadDependency_2,
  input          io_fromDataPath_mem_0_0_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_fromDataPath_mem_0_0_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_fromDataPath_mem_0_0_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_fromDataPath_mem_0_0_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_fromDataPath_mem_0_0_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_fromDataPath_mem_0_0_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_fromDataPath_mem_0_0_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_fromDataPath_mem_0_0_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_fromDataPath_mem_0_0_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_fromDataPath_mem_0_0_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_fromDataPath_mem_0_0_bits_debug_seqNum_seqNum,
  input  [7:0]   io_fromDataPath_mem_0_0_bits_debug_seqNum_uopIdx,
  input  [31:0]  io_fromDataPath_immInfo_0_imm,
  input  [3:0]   io_fromDataPath_immInfo_0_immType,
  input  [31:0]  io_fromDataPath_immInfo_1_imm,
  input  [3:0]   io_fromDataPath_immInfo_1_immType,
  input  [31:0]  io_fromDataPath_immInfo_2_imm,
  input  [3:0]   io_fromDataPath_immInfo_2_immType,
  input  [31:0]  io_fromDataPath_immInfo_3_imm,
  input  [3:0]   io_fromDataPath_immInfo_3_immType,
  input  [31:0]  io_fromDataPath_immInfo_4_imm,
  input  [3:0]   io_fromDataPath_immInfo_4_immType,
  input  [31:0]  io_fromDataPath_immInfo_5_imm,
  input  [3:0]   io_fromDataPath_immInfo_5_immType,
  input  [31:0]  io_fromDataPath_immInfo_6_imm,
  input  [3:0]   io_fromDataPath_immInfo_6_immType,
  input  [31:0]  io_fromDataPath_immInfo_14_imm,
  input  [3:0]   io_fromDataPath_immInfo_14_immType,
  input  [31:0]  io_fromDataPath_immInfo_18_imm,
  input  [3:0]   io_fromDataPath_immInfo_18_immType,
  input  [31:0]  io_fromDataPath_immInfo_19_imm,
  input  [3:0]   io_fromDataPath_immInfo_19_immType,
  input  [31:0]  io_fromDataPath_immInfo_20_imm,
  input  [31:0]  io_fromDataPath_immInfo_21_imm,
  input  [31:0]  io_fromDataPath_immInfo_22_imm,
  input  [63:0]  io_fromDataPath_rcData_18_0_0,
  input  [63:0]  io_fromDataPath_rcData_17_0_0,
  input  [63:0]  io_fromDataPath_rcData_14_0_0,
  input  [63:0]  io_fromDataPath_rcData_13_0_0,
  input  [63:0]  io_fromDataPath_rcData_12_0_0,
  input  [63:0]  io_fromDataPath_rcData_11_0_0,
  input  [63:0]  io_fromDataPath_rcData_10_0_0,
  input  [63:0]  io_fromDataPath_rcData_3_1_0,
  input  [63:0]  io_fromDataPath_rcData_3_1_1,
  input  [63:0]  io_fromDataPath_rcData_3_0_0,
  input  [63:0]  io_fromDataPath_rcData_3_0_1,
  input  [63:0]  io_fromDataPath_rcData_2_1_0,
  input  [63:0]  io_fromDataPath_rcData_2_1_1,
  input  [63:0]  io_fromDataPath_rcData_2_0_0,
  input  [63:0]  io_fromDataPath_rcData_2_0_1,
  input  [63:0]  io_fromDataPath_rcData_1_1_0,
  input  [63:0]  io_fromDataPath_rcData_1_1_1,
  input  [63:0]  io_fromDataPath_rcData_1_0_0,
  input  [63:0]  io_fromDataPath_rcData_1_0_1,
  input  [63:0]  io_fromDataPath_rcData_0_1_0,
  input  [63:0]  io_fromDataPath_rcData_0_1_1,
  input  [63:0]  io_fromDataPath_rcData_0_0_0,
  input  [63:0]  io_fromDataPath_rcData_0_0_1,
  input          io_toExus_int_3_1_ready,
  output         io_toExus_int_3_1_valid,
  output [34:0]  io_toExus_int_3_1_bits_fuType,
  output [8:0]   io_toExus_int_3_1_bits_fuOpType,
  output [63:0]  io_toExus_int_3_1_bits_src_0,
  output [63:0]  io_toExus_int_3_1_bits_src_1,
  output [63:0]  io_toExus_int_3_1_bits_imm,
  output         io_toExus_int_3_1_bits_robIdx_flag,
  output [7:0]   io_toExus_int_3_1_bits_robIdx_value,
  output [7:0]   io_toExus_int_3_1_bits_pdest,
  output         io_toExus_int_3_1_bits_rfWen,
  output         io_toExus_int_3_1_bits_flushPipe,
  output         io_toExus_int_3_1_bits_preDecode_valid,
  output         io_toExus_int_3_1_bits_preDecode_isRVC,
  output [1:0]   io_toExus_int_3_1_bits_preDecode_brType,
  output         io_toExus_int_3_1_bits_preDecode_isCall,
  output         io_toExus_int_3_1_bits_preDecode_isRet,
  output         io_toExus_int_3_1_bits_ftqIdx_flag,
  output [5:0]   io_toExus_int_3_1_bits_ftqIdx_value,
  output [3:0]   io_toExus_int_3_1_bits_ftqOffset,
  output [1:0]   io_toExus_int_3_1_bits_loadDependency_0,
  output [1:0]   io_toExus_int_3_1_bits_loadDependency_1,
  output [1:0]   io_toExus_int_3_1_bits_loadDependency_2,
  output         io_toExus_int_3_1_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toExus_int_3_1_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toExus_int_3_1_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toExus_int_3_1_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toExus_int_3_1_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toExus_int_3_1_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toExus_int_3_1_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toExus_int_3_1_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toExus_int_3_1_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toExus_int_3_1_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toExus_int_3_1_bits_debug_seqNum_seqNum,
  output [7:0]   io_toExus_int_3_1_bits_debug_seqNum_uopIdx,
  input          io_toExus_int_3_0_ready,
  output         io_toExus_int_3_0_valid,
  output [34:0]  io_toExus_int_3_0_bits_fuType,
  output [8:0]   io_toExus_int_3_0_bits_fuOpType,
  output [63:0]  io_toExus_int_3_0_bits_src_0,
  output [63:0]  io_toExus_int_3_0_bits_src_1,
  output         io_toExus_int_3_0_bits_robIdx_flag,
  output [7:0]   io_toExus_int_3_0_bits_robIdx_value,
  output [7:0]   io_toExus_int_3_0_bits_pdest,
  output         io_toExus_int_3_0_bits_rfWen,
  output [1:0]   io_toExus_int_3_0_bits_loadDependency_0,
  output [1:0]   io_toExus_int_3_0_bits_loadDependency_1,
  output [1:0]   io_toExus_int_3_0_bits_loadDependency_2,
  output         io_toExus_int_3_0_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toExus_int_3_0_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toExus_int_3_0_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toExus_int_3_0_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toExus_int_3_0_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toExus_int_3_0_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toExus_int_3_0_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toExus_int_3_0_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toExus_int_3_0_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toExus_int_3_0_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toExus_int_3_0_bits_debug_seqNum_seqNum,
  output [7:0]   io_toExus_int_3_0_bits_debug_seqNum_uopIdx,
  input          io_toExus_int_2_1_ready,
  output         io_toExus_int_2_1_valid,
  output [34:0]  io_toExus_int_2_1_bits_fuType,
  output [8:0]   io_toExus_int_2_1_bits_fuOpType,
  output [63:0]  io_toExus_int_2_1_bits_src_0,
  output [63:0]  io_toExus_int_2_1_bits_src_1,
  output [63:0]  io_toExus_int_2_1_bits_imm,
  output [4:0]   io_toExus_int_2_1_bits_nextPcOffset,
  output         io_toExus_int_2_1_bits_robIdx_flag,
  output [7:0]   io_toExus_int_2_1_bits_robIdx_value,
  output [7:0]   io_toExus_int_2_1_bits_pdest,
  output         io_toExus_int_2_1_bits_rfWen,
  output         io_toExus_int_2_1_bits_fpWen,
  output         io_toExus_int_2_1_bits_vecWen,
  output         io_toExus_int_2_1_bits_v0Wen,
  output         io_toExus_int_2_1_bits_vlWen,
  output [1:0]   io_toExus_int_2_1_bits_fpu_typeTagOut,
  output         io_toExus_int_2_1_bits_fpu_wflags,
  output [1:0]   io_toExus_int_2_1_bits_fpu_typ,
  output [2:0]   io_toExus_int_2_1_bits_fpu_rm,
  output [49:0]  io_toExus_int_2_1_bits_pc,
  output         io_toExus_int_2_1_bits_preDecode_valid,
  output         io_toExus_int_2_1_bits_preDecode_isRVC,
  output [1:0]   io_toExus_int_2_1_bits_preDecode_brType,
  output         io_toExus_int_2_1_bits_preDecode_isCall,
  output         io_toExus_int_2_1_bits_preDecode_isRet,
  output         io_toExus_int_2_1_bits_ftqIdx_flag,
  output [5:0]   io_toExus_int_2_1_bits_ftqIdx_value,
  output [3:0]   io_toExus_int_2_1_bits_ftqOffset,
  output [49:0]  io_toExus_int_2_1_bits_predictInfo_target,
  output         io_toExus_int_2_1_bits_predictInfo_taken,
  output [1:0]   io_toExus_int_2_1_bits_loadDependency_0,
  output [1:0]   io_toExus_int_2_1_bits_loadDependency_1,
  output [1:0]   io_toExus_int_2_1_bits_loadDependency_2,
  output         io_toExus_int_2_1_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toExus_int_2_1_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toExus_int_2_1_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toExus_int_2_1_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toExus_int_2_1_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toExus_int_2_1_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toExus_int_2_1_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toExus_int_2_1_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toExus_int_2_1_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toExus_int_2_1_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toExus_int_2_1_bits_debug_seqNum_seqNum,
  output [7:0]   io_toExus_int_2_1_bits_debug_seqNum_uopIdx,
  input          io_toExus_int_2_0_ready,
  output         io_toExus_int_2_0_valid,
  output [34:0]  io_toExus_int_2_0_bits_fuType,
  output [8:0]   io_toExus_int_2_0_bits_fuOpType,
  output [63:0]  io_toExus_int_2_0_bits_src_0,
  output [63:0]  io_toExus_int_2_0_bits_src_1,
  output         io_toExus_int_2_0_bits_robIdx_flag,
  output [7:0]   io_toExus_int_2_0_bits_robIdx_value,
  output [7:0]   io_toExus_int_2_0_bits_pdest,
  output         io_toExus_int_2_0_bits_rfWen,
  output [1:0]   io_toExus_int_2_0_bits_loadDependency_0,
  output [1:0]   io_toExus_int_2_0_bits_loadDependency_1,
  output [1:0]   io_toExus_int_2_0_bits_loadDependency_2,
  output         io_toExus_int_2_0_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toExus_int_2_0_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toExus_int_2_0_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toExus_int_2_0_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toExus_int_2_0_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toExus_int_2_0_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toExus_int_2_0_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toExus_int_2_0_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toExus_int_2_0_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toExus_int_2_0_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toExus_int_2_0_bits_debug_seqNum_seqNum,
  output [7:0]   io_toExus_int_2_0_bits_debug_seqNum_uopIdx,
  input          io_toExus_int_1_1_ready,
  output         io_toExus_int_1_1_valid,
  output [34:0]  io_toExus_int_1_1_bits_fuType,
  output [8:0]   io_toExus_int_1_1_bits_fuOpType,
  output [63:0]  io_toExus_int_1_1_bits_src_0,
  output [63:0]  io_toExus_int_1_1_bits_src_1,
  output [63:0]  io_toExus_int_1_1_bits_imm,
  output [4:0]   io_toExus_int_1_1_bits_nextPcOffset,
  output         io_toExus_int_1_1_bits_robIdx_flag,
  output [7:0]   io_toExus_int_1_1_bits_robIdx_value,
  output [7:0]   io_toExus_int_1_1_bits_pdest,
  output         io_toExus_int_1_1_bits_rfWen,
  output [49:0]  io_toExus_int_1_1_bits_pc,
  output         io_toExus_int_1_1_bits_preDecode_valid,
  output         io_toExus_int_1_1_bits_preDecode_isRVC,
  output [1:0]   io_toExus_int_1_1_bits_preDecode_brType,
  output         io_toExus_int_1_1_bits_preDecode_isCall,
  output         io_toExus_int_1_1_bits_preDecode_isRet,
  output         io_toExus_int_1_1_bits_ftqIdx_flag,
  output [5:0]   io_toExus_int_1_1_bits_ftqIdx_value,
  output [3:0]   io_toExus_int_1_1_bits_ftqOffset,
  output [49:0]  io_toExus_int_1_1_bits_predictInfo_target,
  output         io_toExus_int_1_1_bits_predictInfo_taken,
  output [1:0]   io_toExus_int_1_1_bits_loadDependency_0,
  output [1:0]   io_toExus_int_1_1_bits_loadDependency_1,
  output [1:0]   io_toExus_int_1_1_bits_loadDependency_2,
  output         io_toExus_int_1_1_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toExus_int_1_1_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toExus_int_1_1_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toExus_int_1_1_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toExus_int_1_1_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toExus_int_1_1_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toExus_int_1_1_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toExus_int_1_1_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toExus_int_1_1_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toExus_int_1_1_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toExus_int_1_1_bits_debug_seqNum_seqNum,
  output [7:0]   io_toExus_int_1_1_bits_debug_seqNum_uopIdx,
  input          io_toExus_int_1_0_ready,
  output         io_toExus_int_1_0_valid,
  output [34:0]  io_toExus_int_1_0_bits_fuType,
  output [8:0]   io_toExus_int_1_0_bits_fuOpType,
  output [63:0]  io_toExus_int_1_0_bits_src_0,
  output [63:0]  io_toExus_int_1_0_bits_src_1,
  output         io_toExus_int_1_0_bits_robIdx_flag,
  output [7:0]   io_toExus_int_1_0_bits_robIdx_value,
  output [7:0]   io_toExus_int_1_0_bits_pdest,
  output         io_toExus_int_1_0_bits_rfWen,
  output [1:0]   io_toExus_int_1_0_bits_loadDependency_0,
  output [1:0]   io_toExus_int_1_0_bits_loadDependency_1,
  output [1:0]   io_toExus_int_1_0_bits_loadDependency_2,
  output         io_toExus_int_1_0_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toExus_int_1_0_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toExus_int_1_0_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toExus_int_1_0_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toExus_int_1_0_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toExus_int_1_0_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toExus_int_1_0_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toExus_int_1_0_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toExus_int_1_0_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toExus_int_1_0_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toExus_int_1_0_bits_debug_seqNum_seqNum,
  output [7:0]   io_toExus_int_1_0_bits_debug_seqNum_uopIdx,
  input          io_toExus_int_0_1_ready,
  output         io_toExus_int_0_1_valid,
  output [34:0]  io_toExus_int_0_1_bits_fuType,
  output [8:0]   io_toExus_int_0_1_bits_fuOpType,
  output [63:0]  io_toExus_int_0_1_bits_src_0,
  output [63:0]  io_toExus_int_0_1_bits_src_1,
  output [63:0]  io_toExus_int_0_1_bits_imm,
  output [4:0]   io_toExus_int_0_1_bits_nextPcOffset,
  output         io_toExus_int_0_1_bits_robIdx_flag,
  output [7:0]   io_toExus_int_0_1_bits_robIdx_value,
  output [7:0]   io_toExus_int_0_1_bits_pdest,
  output         io_toExus_int_0_1_bits_rfWen,
  output [49:0]  io_toExus_int_0_1_bits_pc,
  output         io_toExus_int_0_1_bits_preDecode_valid,
  output         io_toExus_int_0_1_bits_preDecode_isRVC,
  output [1:0]   io_toExus_int_0_1_bits_preDecode_brType,
  output         io_toExus_int_0_1_bits_preDecode_isCall,
  output         io_toExus_int_0_1_bits_preDecode_isRet,
  output         io_toExus_int_0_1_bits_ftqIdx_flag,
  output [5:0]   io_toExus_int_0_1_bits_ftqIdx_value,
  output [3:0]   io_toExus_int_0_1_bits_ftqOffset,
  output [49:0]  io_toExus_int_0_1_bits_predictInfo_target,
  output         io_toExus_int_0_1_bits_predictInfo_taken,
  output [1:0]   io_toExus_int_0_1_bits_loadDependency_0,
  output [1:0]   io_toExus_int_0_1_bits_loadDependency_1,
  output [1:0]   io_toExus_int_0_1_bits_loadDependency_2,
  output         io_toExus_int_0_1_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toExus_int_0_1_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toExus_int_0_1_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toExus_int_0_1_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toExus_int_0_1_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toExus_int_0_1_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toExus_int_0_1_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toExus_int_0_1_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toExus_int_0_1_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toExus_int_0_1_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toExus_int_0_1_bits_debug_seqNum_seqNum,
  output [7:0]   io_toExus_int_0_1_bits_debug_seqNum_uopIdx,
  input          io_toExus_int_0_0_ready,
  output         io_toExus_int_0_0_valid,
  output [34:0]  io_toExus_int_0_0_bits_fuType,
  output [8:0]   io_toExus_int_0_0_bits_fuOpType,
  output [63:0]  io_toExus_int_0_0_bits_src_0,
  output [63:0]  io_toExus_int_0_0_bits_src_1,
  output         io_toExus_int_0_0_bits_robIdx_flag,
  output [7:0]   io_toExus_int_0_0_bits_robIdx_value,
  output [7:0]   io_toExus_int_0_0_bits_pdest,
  output         io_toExus_int_0_0_bits_rfWen,
  output [1:0]   io_toExus_int_0_0_bits_loadDependency_0,
  output [1:0]   io_toExus_int_0_0_bits_loadDependency_1,
  output [1:0]   io_toExus_int_0_0_bits_loadDependency_2,
  output         io_toExus_int_0_0_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toExus_int_0_0_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toExus_int_0_0_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toExus_int_0_0_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toExus_int_0_0_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toExus_int_0_0_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toExus_int_0_0_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toExus_int_0_0_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toExus_int_0_0_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toExus_int_0_0_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toExus_int_0_0_bits_debug_seqNum_seqNum,
  output [7:0]   io_toExus_int_0_0_bits_debug_seqNum_uopIdx,
  input          io_toExus_fp_2_0_ready,
  output         io_toExus_fp_2_0_valid,
  output [34:0]  io_toExus_fp_2_0_bits_fuType,
  output [8:0]   io_toExus_fp_2_0_bits_fuOpType,
  output [63:0]  io_toExus_fp_2_0_bits_src_0,
  output [63:0]  io_toExus_fp_2_0_bits_src_1,
  output [63:0]  io_toExus_fp_2_0_bits_src_2,
  output         io_toExus_fp_2_0_bits_robIdx_flag,
  output [7:0]   io_toExus_fp_2_0_bits_robIdx_value,
  output [7:0]   io_toExus_fp_2_0_bits_pdest,
  output         io_toExus_fp_2_0_bits_rfWen,
  output         io_toExus_fp_2_0_bits_fpWen,
  output         io_toExus_fp_2_0_bits_fpu_wflags,
  output [1:0]   io_toExus_fp_2_0_bits_fpu_fmt,
  output [2:0]   io_toExus_fp_2_0_bits_fpu_rm,
  output         io_toExus_fp_2_0_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toExus_fp_2_0_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toExus_fp_2_0_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toExus_fp_2_0_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toExus_fp_2_0_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toExus_fp_2_0_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toExus_fp_2_0_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toExus_fp_2_0_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toExus_fp_2_0_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toExus_fp_2_0_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toExus_fp_2_0_bits_debug_seqNum_seqNum,
  output [7:0]   io_toExus_fp_2_0_bits_debug_seqNum_uopIdx,
  input          io_toExus_fp_1_1_ready,
  output         io_toExus_fp_1_1_valid,
  output [34:0]  io_toExus_fp_1_1_bits_fuType,
  output [8:0]   io_toExus_fp_1_1_bits_fuOpType,
  output [63:0]  io_toExus_fp_1_1_bits_src_0,
  output [63:0]  io_toExus_fp_1_1_bits_src_1,
  output         io_toExus_fp_1_1_bits_robIdx_flag,
  output [7:0]   io_toExus_fp_1_1_bits_robIdx_value,
  output [7:0]   io_toExus_fp_1_1_bits_pdest,
  output         io_toExus_fp_1_1_bits_fpWen,
  output         io_toExus_fp_1_1_bits_fpu_wflags,
  output [1:0]   io_toExus_fp_1_1_bits_fpu_fmt,
  output [2:0]   io_toExus_fp_1_1_bits_fpu_rm,
  output         io_toExus_fp_1_1_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toExus_fp_1_1_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toExus_fp_1_1_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toExus_fp_1_1_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toExus_fp_1_1_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toExus_fp_1_1_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toExus_fp_1_1_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toExus_fp_1_1_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toExus_fp_1_1_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toExus_fp_1_1_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toExus_fp_1_1_bits_debug_seqNum_seqNum,
  output [7:0]   io_toExus_fp_1_1_bits_debug_seqNum_uopIdx,
  input          io_toExus_fp_1_0_ready,
  output         io_toExus_fp_1_0_valid,
  output [34:0]  io_toExus_fp_1_0_bits_fuType,
  output [8:0]   io_toExus_fp_1_0_bits_fuOpType,
  output [63:0]  io_toExus_fp_1_0_bits_src_0,
  output [63:0]  io_toExus_fp_1_0_bits_src_1,
  output [63:0]  io_toExus_fp_1_0_bits_src_2,
  output         io_toExus_fp_1_0_bits_robIdx_flag,
  output [7:0]   io_toExus_fp_1_0_bits_robIdx_value,
  output [7:0]   io_toExus_fp_1_0_bits_pdest,
  output         io_toExus_fp_1_0_bits_rfWen,
  output         io_toExus_fp_1_0_bits_fpWen,
  output         io_toExus_fp_1_0_bits_fpu_wflags,
  output [1:0]   io_toExus_fp_1_0_bits_fpu_fmt,
  output [2:0]   io_toExus_fp_1_0_bits_fpu_rm,
  output         io_toExus_fp_1_0_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toExus_fp_1_0_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toExus_fp_1_0_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toExus_fp_1_0_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toExus_fp_1_0_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toExus_fp_1_0_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toExus_fp_1_0_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toExus_fp_1_0_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toExus_fp_1_0_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toExus_fp_1_0_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toExus_fp_1_0_bits_debug_seqNum_seqNum,
  output [7:0]   io_toExus_fp_1_0_bits_debug_seqNum_uopIdx,
  input          io_toExus_fp_0_1_ready,
  output         io_toExus_fp_0_1_valid,
  output [34:0]  io_toExus_fp_0_1_bits_fuType,
  output [8:0]   io_toExus_fp_0_1_bits_fuOpType,
  output [63:0]  io_toExus_fp_0_1_bits_src_0,
  output [63:0]  io_toExus_fp_0_1_bits_src_1,
  output         io_toExus_fp_0_1_bits_robIdx_flag,
  output [7:0]   io_toExus_fp_0_1_bits_robIdx_value,
  output [7:0]   io_toExus_fp_0_1_bits_pdest,
  output         io_toExus_fp_0_1_bits_fpWen,
  output         io_toExus_fp_0_1_bits_fpu_wflags,
  output [1:0]   io_toExus_fp_0_1_bits_fpu_fmt,
  output [2:0]   io_toExus_fp_0_1_bits_fpu_rm,
  output         io_toExus_fp_0_1_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toExus_fp_0_1_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toExus_fp_0_1_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toExus_fp_0_1_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toExus_fp_0_1_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toExus_fp_0_1_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toExus_fp_0_1_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toExus_fp_0_1_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toExus_fp_0_1_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toExus_fp_0_1_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toExus_fp_0_1_bits_debug_seqNum_seqNum,
  output [7:0]   io_toExus_fp_0_1_bits_debug_seqNum_uopIdx,
  input          io_toExus_fp_0_0_ready,
  output         io_toExus_fp_0_0_valid,
  output [34:0]  io_toExus_fp_0_0_bits_fuType,
  output [8:0]   io_toExus_fp_0_0_bits_fuOpType,
  output [63:0]  io_toExus_fp_0_0_bits_src_0,
  output [63:0]  io_toExus_fp_0_0_bits_src_1,
  output [63:0]  io_toExus_fp_0_0_bits_src_2,
  output         io_toExus_fp_0_0_bits_robIdx_flag,
  output [7:0]   io_toExus_fp_0_0_bits_robIdx_value,
  output [7:0]   io_toExus_fp_0_0_bits_pdest,
  output         io_toExus_fp_0_0_bits_rfWen,
  output         io_toExus_fp_0_0_bits_fpWen,
  output         io_toExus_fp_0_0_bits_vecWen,
  output         io_toExus_fp_0_0_bits_v0Wen,
  output         io_toExus_fp_0_0_bits_fpu_wflags,
  output [1:0]   io_toExus_fp_0_0_bits_fpu_fmt,
  output [2:0]   io_toExus_fp_0_0_bits_fpu_rm,
  output         io_toExus_fp_0_0_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toExus_fp_0_0_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toExus_fp_0_0_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toExus_fp_0_0_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toExus_fp_0_0_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toExus_fp_0_0_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toExus_fp_0_0_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toExus_fp_0_0_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toExus_fp_0_0_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toExus_fp_0_0_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toExus_fp_0_0_bits_debug_seqNum_seqNum,
  output [7:0]   io_toExus_fp_0_0_bits_debug_seqNum_uopIdx,
  input          io_toExus_vf_2_0_ready,
  output         io_toExus_vf_2_0_valid,
  output [34:0]  io_toExus_vf_2_0_bits_fuType,
  output [8:0]   io_toExus_vf_2_0_bits_fuOpType,
  output [127:0] io_toExus_vf_2_0_bits_src_0,
  output [127:0] io_toExus_vf_2_0_bits_src_1,
  output [127:0] io_toExus_vf_2_0_bits_src_2,
  output [127:0] io_toExus_vf_2_0_bits_src_3,
  output [127:0] io_toExus_vf_2_0_bits_src_4,
  output         io_toExus_vf_2_0_bits_robIdx_flag,
  output [7:0]   io_toExus_vf_2_0_bits_robIdx_value,
  output [6:0]   io_toExus_vf_2_0_bits_pdest,
  output         io_toExus_vf_2_0_bits_vecWen,
  output         io_toExus_vf_2_0_bits_v0Wen,
  output         io_toExus_vf_2_0_bits_fpu_wflags,
  output         io_toExus_vf_2_0_bits_vpu_vma,
  output         io_toExus_vf_2_0_bits_vpu_vta,
  output [1:0]   io_toExus_vf_2_0_bits_vpu_vsew,
  output [2:0]   io_toExus_vf_2_0_bits_vpu_vlmul,
  output         io_toExus_vf_2_0_bits_vpu_vm,
  output [7:0]   io_toExus_vf_2_0_bits_vpu_vstart,
  output [6:0]   io_toExus_vf_2_0_bits_vpu_vuopIdx,
  output         io_toExus_vf_2_0_bits_vpu_isExt,
  output         io_toExus_vf_2_0_bits_vpu_isNarrow,
  output         io_toExus_vf_2_0_bits_vpu_isDstMask,
  output         io_toExus_vf_2_0_bits_vpu_isOpMask,
  output         io_toExus_vf_2_0_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toExus_vf_2_0_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toExus_vf_2_0_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toExus_vf_2_0_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toExus_vf_2_0_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toExus_vf_2_0_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toExus_vf_2_0_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toExus_vf_2_0_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toExus_vf_2_0_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toExus_vf_2_0_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toExus_vf_2_0_bits_debug_seqNum_seqNum,
  output [7:0]   io_toExus_vf_2_0_bits_debug_seqNum_uopIdx,
  input          io_toExus_vf_1_1_ready,
  output         io_toExus_vf_1_1_valid,
  output [34:0]  io_toExus_vf_1_1_bits_fuType,
  output [8:0]   io_toExus_vf_1_1_bits_fuOpType,
  output [127:0] io_toExus_vf_1_1_bits_src_0,
  output [127:0] io_toExus_vf_1_1_bits_src_1,
  output [127:0] io_toExus_vf_1_1_bits_src_2,
  output [127:0] io_toExus_vf_1_1_bits_src_3,
  output [127:0] io_toExus_vf_1_1_bits_src_4,
  output         io_toExus_vf_1_1_bits_robIdx_flag,
  output [7:0]   io_toExus_vf_1_1_bits_robIdx_value,
  output [7:0]   io_toExus_vf_1_1_bits_pdest,
  output         io_toExus_vf_1_1_bits_fpWen,
  output         io_toExus_vf_1_1_bits_vecWen,
  output         io_toExus_vf_1_1_bits_v0Wen,
  output         io_toExus_vf_1_1_bits_fpu_wflags,
  output         io_toExus_vf_1_1_bits_vpu_vma,
  output         io_toExus_vf_1_1_bits_vpu_vta,
  output [1:0]   io_toExus_vf_1_1_bits_vpu_vsew,
  output [2:0]   io_toExus_vf_1_1_bits_vpu_vlmul,
  output         io_toExus_vf_1_1_bits_vpu_vm,
  output [7:0]   io_toExus_vf_1_1_bits_vpu_vstart,
  output         io_toExus_vf_1_1_bits_vpu_fpu_isFoldTo1_2,
  output         io_toExus_vf_1_1_bits_vpu_fpu_isFoldTo1_4,
  output         io_toExus_vf_1_1_bits_vpu_fpu_isFoldTo1_8,
  output [6:0]   io_toExus_vf_1_1_bits_vpu_vuopIdx,
  output         io_toExus_vf_1_1_bits_vpu_lastUop,
  output         io_toExus_vf_1_1_bits_vpu_isNarrow,
  output         io_toExus_vf_1_1_bits_vpu_isDstMask,
  output         io_toExus_vf_1_1_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toExus_vf_1_1_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toExus_vf_1_1_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toExus_vf_1_1_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toExus_vf_1_1_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toExus_vf_1_1_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toExus_vf_1_1_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toExus_vf_1_1_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toExus_vf_1_1_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toExus_vf_1_1_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toExus_vf_1_1_bits_debug_seqNum_seqNum,
  output [7:0]   io_toExus_vf_1_1_bits_debug_seqNum_uopIdx,
  input          io_toExus_vf_1_0_ready,
  output         io_toExus_vf_1_0_valid,
  output [34:0]  io_toExus_vf_1_0_bits_fuType,
  output [8:0]   io_toExus_vf_1_0_bits_fuOpType,
  output [127:0] io_toExus_vf_1_0_bits_src_0,
  output [127:0] io_toExus_vf_1_0_bits_src_1,
  output [127:0] io_toExus_vf_1_0_bits_src_2,
  output [127:0] io_toExus_vf_1_0_bits_src_3,
  output [127:0] io_toExus_vf_1_0_bits_src_4,
  output         io_toExus_vf_1_0_bits_robIdx_flag,
  output [7:0]   io_toExus_vf_1_0_bits_robIdx_value,
  output [6:0]   io_toExus_vf_1_0_bits_pdest,
  output         io_toExus_vf_1_0_bits_vecWen,
  output         io_toExus_vf_1_0_bits_v0Wen,
  output         io_toExus_vf_1_0_bits_fpu_wflags,
  output         io_toExus_vf_1_0_bits_vpu_vma,
  output         io_toExus_vf_1_0_bits_vpu_vta,
  output [1:0]   io_toExus_vf_1_0_bits_vpu_vsew,
  output [2:0]   io_toExus_vf_1_0_bits_vpu_vlmul,
  output         io_toExus_vf_1_0_bits_vpu_vm,
  output [7:0]   io_toExus_vf_1_0_bits_vpu_vstart,
  output [6:0]   io_toExus_vf_1_0_bits_vpu_vuopIdx,
  output         io_toExus_vf_1_0_bits_vpu_isExt,
  output         io_toExus_vf_1_0_bits_vpu_isNarrow,
  output         io_toExus_vf_1_0_bits_vpu_isDstMask,
  output         io_toExus_vf_1_0_bits_vpu_isOpMask,
  output         io_toExus_vf_1_0_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toExus_vf_1_0_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toExus_vf_1_0_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toExus_vf_1_0_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toExus_vf_1_0_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toExus_vf_1_0_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toExus_vf_1_0_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toExus_vf_1_0_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toExus_vf_1_0_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toExus_vf_1_0_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toExus_vf_1_0_bits_debug_seqNum_seqNum,
  output [7:0]   io_toExus_vf_1_0_bits_debug_seqNum_uopIdx,
  input          io_toExus_vf_0_1_ready,
  output         io_toExus_vf_0_1_valid,
  output [34:0]  io_toExus_vf_0_1_bits_fuType,
  output [8:0]   io_toExus_vf_0_1_bits_fuOpType,
  output [127:0] io_toExus_vf_0_1_bits_src_0,
  output [127:0] io_toExus_vf_0_1_bits_src_1,
  output [127:0] io_toExus_vf_0_1_bits_src_2,
  output [127:0] io_toExus_vf_0_1_bits_src_3,
  output [127:0] io_toExus_vf_0_1_bits_src_4,
  output         io_toExus_vf_0_1_bits_robIdx_flag,
  output [7:0]   io_toExus_vf_0_1_bits_robIdx_value,
  output [7:0]   io_toExus_vf_0_1_bits_pdest,
  output         io_toExus_vf_0_1_bits_rfWen,
  output         io_toExus_vf_0_1_bits_fpWen,
  output         io_toExus_vf_0_1_bits_vecWen,
  output         io_toExus_vf_0_1_bits_v0Wen,
  output         io_toExus_vf_0_1_bits_vlWen,
  output         io_toExus_vf_0_1_bits_fpu_wflags,
  output         io_toExus_vf_0_1_bits_vpu_vma,
  output         io_toExus_vf_0_1_bits_vpu_vta,
  output [1:0]   io_toExus_vf_0_1_bits_vpu_vsew,
  output [2:0]   io_toExus_vf_0_1_bits_vpu_vlmul,
  output         io_toExus_vf_0_1_bits_vpu_vm,
  output [7:0]   io_toExus_vf_0_1_bits_vpu_vstart,
  output         io_toExus_vf_0_1_bits_vpu_fpu_isFoldTo1_2,
  output         io_toExus_vf_0_1_bits_vpu_fpu_isFoldTo1_4,
  output         io_toExus_vf_0_1_bits_vpu_fpu_isFoldTo1_8,
  output [6:0]   io_toExus_vf_0_1_bits_vpu_vuopIdx,
  output         io_toExus_vf_0_1_bits_vpu_lastUop,
  output         io_toExus_vf_0_1_bits_vpu_isNarrow,
  output         io_toExus_vf_0_1_bits_vpu_isDstMask,
  output         io_toExus_vf_0_1_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toExus_vf_0_1_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toExus_vf_0_1_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toExus_vf_0_1_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toExus_vf_0_1_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toExus_vf_0_1_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toExus_vf_0_1_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toExus_vf_0_1_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toExus_vf_0_1_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toExus_vf_0_1_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toExus_vf_0_1_bits_debug_seqNum_seqNum,
  output [7:0]   io_toExus_vf_0_1_bits_debug_seqNum_uopIdx,
  input          io_toExus_vf_0_0_ready,
  output         io_toExus_vf_0_0_valid,
  output [34:0]  io_toExus_vf_0_0_bits_fuType,
  output [8:0]   io_toExus_vf_0_0_bits_fuOpType,
  output [127:0] io_toExus_vf_0_0_bits_src_0,
  output [127:0] io_toExus_vf_0_0_bits_src_1,
  output [127:0] io_toExus_vf_0_0_bits_src_2,
  output [127:0] io_toExus_vf_0_0_bits_src_3,
  output [127:0] io_toExus_vf_0_0_bits_src_4,
  output         io_toExus_vf_0_0_bits_robIdx_flag,
  output [7:0]   io_toExus_vf_0_0_bits_robIdx_value,
  output [6:0]   io_toExus_vf_0_0_bits_pdest,
  output         io_toExus_vf_0_0_bits_vecWen,
  output         io_toExus_vf_0_0_bits_v0Wen,
  output         io_toExus_vf_0_0_bits_fpu_wflags,
  output         io_toExus_vf_0_0_bits_vpu_vma,
  output         io_toExus_vf_0_0_bits_vpu_vta,
  output [1:0]   io_toExus_vf_0_0_bits_vpu_vsew,
  output [2:0]   io_toExus_vf_0_0_bits_vpu_vlmul,
  output         io_toExus_vf_0_0_bits_vpu_vm,
  output [7:0]   io_toExus_vf_0_0_bits_vpu_vstart,
  output [6:0]   io_toExus_vf_0_0_bits_vpu_vuopIdx,
  output         io_toExus_vf_0_0_bits_vpu_isExt,
  output         io_toExus_vf_0_0_bits_vpu_isNarrow,
  output         io_toExus_vf_0_0_bits_vpu_isDstMask,
  output         io_toExus_vf_0_0_bits_vpu_isOpMask,
  output         io_toExus_vf_0_0_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toExus_vf_0_0_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toExus_vf_0_0_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toExus_vf_0_0_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toExus_vf_0_0_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toExus_vf_0_0_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toExus_vf_0_0_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toExus_vf_0_0_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toExus_vf_0_0_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toExus_vf_0_0_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toExus_vf_0_0_bits_debug_seqNum_seqNum,
  output [7:0]   io_toExus_vf_0_0_bits_debug_seqNum_uopIdx,
  input          io_toExus_mem_8_0_ready,
  output         io_toExus_mem_8_0_valid,
  output [34:0]  io_toExus_mem_8_0_bits_fuType,
  output [8:0]   io_toExus_mem_8_0_bits_fuOpType,
  output [63:0]  io_toExus_mem_8_0_bits_src_0,
  output         io_toExus_mem_8_0_bits_robIdx_flag,
  output [7:0]   io_toExus_mem_8_0_bits_robIdx_value,
  output         io_toExus_mem_8_0_bits_sqIdx_flag,
  output [5:0]   io_toExus_mem_8_0_bits_sqIdx_value,
  output [1:0]   io_toExus_mem_8_0_bits_loadDependency_0,
  output [1:0]   io_toExus_mem_8_0_bits_loadDependency_1,
  output [1:0]   io_toExus_mem_8_0_bits_loadDependency_2,
  input          io_toExus_mem_7_0_ready,
  output         io_toExus_mem_7_0_valid,
  output [34:0]  io_toExus_mem_7_0_bits_fuType,
  output [8:0]   io_toExus_mem_7_0_bits_fuOpType,
  output [63:0]  io_toExus_mem_7_0_bits_src_0,
  output         io_toExus_mem_7_0_bits_robIdx_flag,
  output [7:0]   io_toExus_mem_7_0_bits_robIdx_value,
  output         io_toExus_mem_7_0_bits_sqIdx_flag,
  output [5:0]   io_toExus_mem_7_0_bits_sqIdx_value,
  output [1:0]   io_toExus_mem_7_0_bits_loadDependency_0,
  output [1:0]   io_toExus_mem_7_0_bits_loadDependency_1,
  output [1:0]   io_toExus_mem_7_0_bits_loadDependency_2,
  input          io_toExus_mem_6_0_ready,
  output         io_toExus_mem_6_0_valid,
  output [34:0]  io_toExus_mem_6_0_bits_fuType,
  output [8:0]   io_toExus_mem_6_0_bits_fuOpType,
  output [127:0] io_toExus_mem_6_0_bits_src_0,
  output [127:0] io_toExus_mem_6_0_bits_src_1,
  output [127:0] io_toExus_mem_6_0_bits_src_2,
  output [127:0] io_toExus_mem_6_0_bits_src_3,
  output [127:0] io_toExus_mem_6_0_bits_src_4,
  output         io_toExus_mem_6_0_bits_robIdx_flag,
  output [7:0]   io_toExus_mem_6_0_bits_robIdx_value,
  output [6:0]   io_toExus_mem_6_0_bits_pdest,
  output         io_toExus_mem_6_0_bits_vecWen,
  output         io_toExus_mem_6_0_bits_v0Wen,
  output         io_toExus_mem_6_0_bits_vlWen,
  output         io_toExus_mem_6_0_bits_vpu_vill,
  output         io_toExus_mem_6_0_bits_vpu_vma,
  output         io_toExus_mem_6_0_bits_vpu_vta,
  output [1:0]   io_toExus_mem_6_0_bits_vpu_vsew,
  output [2:0]   io_toExus_mem_6_0_bits_vpu_vlmul,
  output         io_toExus_mem_6_0_bits_vpu_specVill,
  output         io_toExus_mem_6_0_bits_vpu_specVma,
  output         io_toExus_mem_6_0_bits_vpu_specVta,
  output [1:0]   io_toExus_mem_6_0_bits_vpu_specVsew,
  output [2:0]   io_toExus_mem_6_0_bits_vpu_specVlmul,
  output         io_toExus_mem_6_0_bits_vpu_vm,
  output [7:0]   io_toExus_mem_6_0_bits_vpu_vstart,
  output [2:0]   io_toExus_mem_6_0_bits_vpu_frm,
  output         io_toExus_mem_6_0_bits_vpu_fpu_isFpToVecInst,
  output         io_toExus_mem_6_0_bits_vpu_fpu_isFP32Instr,
  output         io_toExus_mem_6_0_bits_vpu_fpu_isFP64Instr,
  output         io_toExus_mem_6_0_bits_vpu_fpu_isReduction,
  output         io_toExus_mem_6_0_bits_vpu_fpu_isFoldTo1_2,
  output         io_toExus_mem_6_0_bits_vpu_fpu_isFoldTo1_4,
  output         io_toExus_mem_6_0_bits_vpu_fpu_isFoldTo1_8,
  output [1:0]   io_toExus_mem_6_0_bits_vpu_vxrm,
  output [6:0]   io_toExus_mem_6_0_bits_vpu_vuopIdx,
  output         io_toExus_mem_6_0_bits_vpu_lastUop,
  output [127:0] io_toExus_mem_6_0_bits_vpu_vmask,
  output [2:0]   io_toExus_mem_6_0_bits_vpu_nf,
  output [1:0]   io_toExus_mem_6_0_bits_vpu_veew,
  output         io_toExus_mem_6_0_bits_vpu_isReverse,
  output         io_toExus_mem_6_0_bits_vpu_isExt,
  output         io_toExus_mem_6_0_bits_vpu_isNarrow,
  output         io_toExus_mem_6_0_bits_vpu_isDstMask,
  output         io_toExus_mem_6_0_bits_vpu_isOpMask,
  output         io_toExus_mem_6_0_bits_vpu_isMove,
  output         io_toExus_mem_6_0_bits_vpu_isDependOldVd,
  output         io_toExus_mem_6_0_bits_vpu_isWritePartVd,
  output         io_toExus_mem_6_0_bits_vpu_isVleff,
  output         io_toExus_mem_6_0_bits_ftqIdx_flag,
  output [5:0]   io_toExus_mem_6_0_bits_ftqIdx_value,
  output [3:0]   io_toExus_mem_6_0_bits_ftqOffset,
  output [4:0]   io_toExus_mem_6_0_bits_numLsElem,
  output         io_toExus_mem_6_0_bits_sqIdx_flag,
  output [5:0]   io_toExus_mem_6_0_bits_sqIdx_value,
  output         io_toExus_mem_6_0_bits_lqIdx_flag,
  output [6:0]   io_toExus_mem_6_0_bits_lqIdx_value,
  output         io_toExus_mem_6_0_bits_isVecPartReplay,
  output [15:0]  io_toExus_mem_6_0_bits_vecReplayMask,
  output [3:0]   io_toExus_mem_6_0_bits_vecReplayMbIdx,
  output         io_toExus_mem_6_0_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toExus_mem_6_0_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toExus_mem_6_0_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toExus_mem_6_0_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toExus_mem_6_0_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toExus_mem_6_0_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toExus_mem_6_0_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toExus_mem_6_0_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toExus_mem_6_0_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toExus_mem_6_0_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toExus_mem_6_0_bits_debug_seqNum_seqNum,
  output [7:0]   io_toExus_mem_6_0_bits_debug_seqNum_uopIdx,
  input          io_toExus_mem_5_0_ready,
  output         io_toExus_mem_5_0_valid,
  output [34:0]  io_toExus_mem_5_0_bits_fuType,
  output [8:0]   io_toExus_mem_5_0_bits_fuOpType,
  output [127:0] io_toExus_mem_5_0_bits_src_0,
  output [127:0] io_toExus_mem_5_0_bits_src_1,
  output [127:0] io_toExus_mem_5_0_bits_src_2,
  output [127:0] io_toExus_mem_5_0_bits_src_3,
  output [127:0] io_toExus_mem_5_0_bits_src_4,
  output         io_toExus_mem_5_0_bits_robIdx_flag,
  output [7:0]   io_toExus_mem_5_0_bits_robIdx_value,
  output [6:0]   io_toExus_mem_5_0_bits_pdest,
  output         io_toExus_mem_5_0_bits_vecWen,
  output         io_toExus_mem_5_0_bits_v0Wen,
  output         io_toExus_mem_5_0_bits_vlWen,
  output         io_toExus_mem_5_0_bits_vpu_vill,
  output         io_toExus_mem_5_0_bits_vpu_vma,
  output         io_toExus_mem_5_0_bits_vpu_vta,
  output [1:0]   io_toExus_mem_5_0_bits_vpu_vsew,
  output [2:0]   io_toExus_mem_5_0_bits_vpu_vlmul,
  output         io_toExus_mem_5_0_bits_vpu_specVill,
  output         io_toExus_mem_5_0_bits_vpu_specVma,
  output         io_toExus_mem_5_0_bits_vpu_specVta,
  output [1:0]   io_toExus_mem_5_0_bits_vpu_specVsew,
  output [2:0]   io_toExus_mem_5_0_bits_vpu_specVlmul,
  output         io_toExus_mem_5_0_bits_vpu_vm,
  output [7:0]   io_toExus_mem_5_0_bits_vpu_vstart,
  output [2:0]   io_toExus_mem_5_0_bits_vpu_frm,
  output         io_toExus_mem_5_0_bits_vpu_fpu_isFpToVecInst,
  output         io_toExus_mem_5_0_bits_vpu_fpu_isFP32Instr,
  output         io_toExus_mem_5_0_bits_vpu_fpu_isFP64Instr,
  output         io_toExus_mem_5_0_bits_vpu_fpu_isReduction,
  output         io_toExus_mem_5_0_bits_vpu_fpu_isFoldTo1_2,
  output         io_toExus_mem_5_0_bits_vpu_fpu_isFoldTo1_4,
  output         io_toExus_mem_5_0_bits_vpu_fpu_isFoldTo1_8,
  output [1:0]   io_toExus_mem_5_0_bits_vpu_vxrm,
  output [6:0]   io_toExus_mem_5_0_bits_vpu_vuopIdx,
  output         io_toExus_mem_5_0_bits_vpu_lastUop,
  output [127:0] io_toExus_mem_5_0_bits_vpu_vmask,
  output [2:0]   io_toExus_mem_5_0_bits_vpu_nf,
  output [1:0]   io_toExus_mem_5_0_bits_vpu_veew,
  output         io_toExus_mem_5_0_bits_vpu_isReverse,
  output         io_toExus_mem_5_0_bits_vpu_isExt,
  output         io_toExus_mem_5_0_bits_vpu_isNarrow,
  output         io_toExus_mem_5_0_bits_vpu_isDstMask,
  output         io_toExus_mem_5_0_bits_vpu_isOpMask,
  output         io_toExus_mem_5_0_bits_vpu_isMove,
  output         io_toExus_mem_5_0_bits_vpu_isDependOldVd,
  output         io_toExus_mem_5_0_bits_vpu_isWritePartVd,
  output         io_toExus_mem_5_0_bits_vpu_isVleff,
  output         io_toExus_mem_5_0_bits_ftqIdx_flag,
  output [5:0]   io_toExus_mem_5_0_bits_ftqIdx_value,
  output [3:0]   io_toExus_mem_5_0_bits_ftqOffset,
  output [4:0]   io_toExus_mem_5_0_bits_numLsElem,
  output         io_toExus_mem_5_0_bits_sqIdx_flag,
  output [5:0]   io_toExus_mem_5_0_bits_sqIdx_value,
  output         io_toExus_mem_5_0_bits_lqIdx_flag,
  output [6:0]   io_toExus_mem_5_0_bits_lqIdx_value,
  output         io_toExus_mem_5_0_bits_isVecPartReplay,
  output [15:0]  io_toExus_mem_5_0_bits_vecReplayMask,
  output [3:0]   io_toExus_mem_5_0_bits_vecReplayMbIdx,
  output         io_toExus_mem_5_0_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toExus_mem_5_0_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toExus_mem_5_0_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toExus_mem_5_0_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toExus_mem_5_0_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toExus_mem_5_0_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toExus_mem_5_0_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toExus_mem_5_0_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toExus_mem_5_0_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toExus_mem_5_0_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toExus_mem_5_0_bits_debug_seqNum_seqNum,
  output [7:0]   io_toExus_mem_5_0_bits_debug_seqNum_uopIdx,
  input          io_toExus_mem_4_0_ready,
  output         io_toExus_mem_4_0_valid,
  output [34:0]  io_toExus_mem_4_0_bits_fuType,
  output [8:0]   io_toExus_mem_4_0_bits_fuOpType,
  output [63:0]  io_toExus_mem_4_0_bits_src_0,
  output [63:0]  io_toExus_mem_4_0_bits_imm,
  output         io_toExus_mem_4_0_bits_robIdx_flag,
  output [7:0]   io_toExus_mem_4_0_bits_robIdx_value,
  output [7:0]   io_toExus_mem_4_0_bits_pdest,
  output         io_toExus_mem_4_0_bits_rfWen,
  output         io_toExus_mem_4_0_bits_fpWen,
  output [49:0]  io_toExus_mem_4_0_bits_pc,
  output         io_toExus_mem_4_0_bits_preDecode_valid,
  output         io_toExus_mem_4_0_bits_preDecode_isRVC,
  output [1:0]   io_toExus_mem_4_0_bits_preDecode_brType,
  output         io_toExus_mem_4_0_bits_preDecode_isCall,
  output         io_toExus_mem_4_0_bits_preDecode_isRet,
  output         io_toExus_mem_4_0_bits_ftqIdx_flag,
  output [5:0]   io_toExus_mem_4_0_bits_ftqIdx_value,
  output [3:0]   io_toExus_mem_4_0_bits_ftqOffset,
  output         io_toExus_mem_4_0_bits_loadWaitBit,
  output         io_toExus_mem_4_0_bits_waitForRobIdx_flag,
  output [7:0]   io_toExus_mem_4_0_bits_waitForRobIdx_value,
  output         io_toExus_mem_4_0_bits_storeSetHit,
  output         io_toExus_mem_4_0_bits_loadWaitStrict,
  output [4:0]   io_toExus_mem_4_0_bits_ssid,
  output         io_toExus_mem_4_0_bits_sqIdx_flag,
  output [5:0]   io_toExus_mem_4_0_bits_sqIdx_value,
  output         io_toExus_mem_4_0_bits_lqIdx_flag,
  output [6:0]   io_toExus_mem_4_0_bits_lqIdx_value,
  output [1:0]   io_toExus_mem_4_0_bits_loadDependency_0,
  output [1:0]   io_toExus_mem_4_0_bits_loadDependency_1,
  output [1:0]   io_toExus_mem_4_0_bits_loadDependency_2,
  output         io_toExus_mem_4_0_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toExus_mem_4_0_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toExus_mem_4_0_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toExus_mem_4_0_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toExus_mem_4_0_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toExus_mem_4_0_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toExus_mem_4_0_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toExus_mem_4_0_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toExus_mem_4_0_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toExus_mem_4_0_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toExus_mem_4_0_bits_debug_seqNum_seqNum,
  output [7:0]   io_toExus_mem_4_0_bits_debug_seqNum_uopIdx,
  input          io_toExus_mem_3_0_ready,
  output         io_toExus_mem_3_0_valid,
  output [34:0]  io_toExus_mem_3_0_bits_fuType,
  output [8:0]   io_toExus_mem_3_0_bits_fuOpType,
  output [63:0]  io_toExus_mem_3_0_bits_src_0,
  output [63:0]  io_toExus_mem_3_0_bits_imm,
  output         io_toExus_mem_3_0_bits_robIdx_flag,
  output [7:0]   io_toExus_mem_3_0_bits_robIdx_value,
  output [7:0]   io_toExus_mem_3_0_bits_pdest,
  output         io_toExus_mem_3_0_bits_rfWen,
  output         io_toExus_mem_3_0_bits_fpWen,
  output [49:0]  io_toExus_mem_3_0_bits_pc,
  output         io_toExus_mem_3_0_bits_preDecode_valid,
  output         io_toExus_mem_3_0_bits_preDecode_isRVC,
  output [1:0]   io_toExus_mem_3_0_bits_preDecode_brType,
  output         io_toExus_mem_3_0_bits_preDecode_isCall,
  output         io_toExus_mem_3_0_bits_preDecode_isRet,
  output         io_toExus_mem_3_0_bits_ftqIdx_flag,
  output [5:0]   io_toExus_mem_3_0_bits_ftqIdx_value,
  output [3:0]   io_toExus_mem_3_0_bits_ftqOffset,
  output         io_toExus_mem_3_0_bits_loadWaitBit,
  output         io_toExus_mem_3_0_bits_waitForRobIdx_flag,
  output [7:0]   io_toExus_mem_3_0_bits_waitForRobIdx_value,
  output         io_toExus_mem_3_0_bits_storeSetHit,
  output         io_toExus_mem_3_0_bits_loadWaitStrict,
  output [4:0]   io_toExus_mem_3_0_bits_ssid,
  output         io_toExus_mem_3_0_bits_sqIdx_flag,
  output [5:0]   io_toExus_mem_3_0_bits_sqIdx_value,
  output         io_toExus_mem_3_0_bits_lqIdx_flag,
  output [6:0]   io_toExus_mem_3_0_bits_lqIdx_value,
  output [1:0]   io_toExus_mem_3_0_bits_loadDependency_0,
  output [1:0]   io_toExus_mem_3_0_bits_loadDependency_1,
  output [1:0]   io_toExus_mem_3_0_bits_loadDependency_2,
  output         io_toExus_mem_3_0_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toExus_mem_3_0_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toExus_mem_3_0_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toExus_mem_3_0_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toExus_mem_3_0_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toExus_mem_3_0_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toExus_mem_3_0_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toExus_mem_3_0_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toExus_mem_3_0_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toExus_mem_3_0_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toExus_mem_3_0_bits_debug_seqNum_seqNum,
  output [7:0]   io_toExus_mem_3_0_bits_debug_seqNum_uopIdx,
  input          io_toExus_mem_2_0_ready,
  output         io_toExus_mem_2_0_valid,
  output [34:0]  io_toExus_mem_2_0_bits_fuType,
  output [8:0]   io_toExus_mem_2_0_bits_fuOpType,
  output [63:0]  io_toExus_mem_2_0_bits_src_0,
  output [63:0]  io_toExus_mem_2_0_bits_imm,
  output         io_toExus_mem_2_0_bits_robIdx_flag,
  output [7:0]   io_toExus_mem_2_0_bits_robIdx_value,
  output [7:0]   io_toExus_mem_2_0_bits_pdest,
  output         io_toExus_mem_2_0_bits_rfWen,
  output         io_toExus_mem_2_0_bits_fpWen,
  output [49:0]  io_toExus_mem_2_0_bits_pc,
  output         io_toExus_mem_2_0_bits_preDecode_valid,
  output         io_toExus_mem_2_0_bits_preDecode_isRVC,
  output [1:0]   io_toExus_mem_2_0_bits_preDecode_brType,
  output         io_toExus_mem_2_0_bits_preDecode_isCall,
  output         io_toExus_mem_2_0_bits_preDecode_isRet,
  output         io_toExus_mem_2_0_bits_ftqIdx_flag,
  output [5:0]   io_toExus_mem_2_0_bits_ftqIdx_value,
  output [3:0]   io_toExus_mem_2_0_bits_ftqOffset,
  output         io_toExus_mem_2_0_bits_loadWaitBit,
  output         io_toExus_mem_2_0_bits_waitForRobIdx_flag,
  output [7:0]   io_toExus_mem_2_0_bits_waitForRobIdx_value,
  output         io_toExus_mem_2_0_bits_storeSetHit,
  output         io_toExus_mem_2_0_bits_loadWaitStrict,
  output [4:0]   io_toExus_mem_2_0_bits_ssid,
  output         io_toExus_mem_2_0_bits_sqIdx_flag,
  output [5:0]   io_toExus_mem_2_0_bits_sqIdx_value,
  output         io_toExus_mem_2_0_bits_lqIdx_flag,
  output [6:0]   io_toExus_mem_2_0_bits_lqIdx_value,
  output [1:0]   io_toExus_mem_2_0_bits_loadDependency_0,
  output [1:0]   io_toExus_mem_2_0_bits_loadDependency_1,
  output [1:0]   io_toExus_mem_2_0_bits_loadDependency_2,
  output         io_toExus_mem_2_0_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toExus_mem_2_0_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toExus_mem_2_0_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toExus_mem_2_0_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toExus_mem_2_0_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toExus_mem_2_0_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toExus_mem_2_0_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toExus_mem_2_0_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toExus_mem_2_0_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toExus_mem_2_0_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toExus_mem_2_0_bits_debug_seqNum_seqNum,
  output [7:0]   io_toExus_mem_2_0_bits_debug_seqNum_uopIdx,
  input          io_toExus_mem_1_0_ready,
  output         io_toExus_mem_1_0_valid,
  output [34:0]  io_toExus_mem_1_0_bits_fuType,
  output [8:0]   io_toExus_mem_1_0_bits_fuOpType,
  output [63:0]  io_toExus_mem_1_0_bits_src_0,
  output [63:0]  io_toExus_mem_1_0_bits_imm,
  output         io_toExus_mem_1_0_bits_robIdx_flag,
  output [7:0]   io_toExus_mem_1_0_bits_robIdx_value,
  output         io_toExus_mem_1_0_bits_isFirstIssue,
  output [7:0]   io_toExus_mem_1_0_bits_pdest,
  output         io_toExus_mem_1_0_bits_rfWen,
  output         io_toExus_mem_1_0_bits_ftqIdx_flag,
  output [5:0]   io_toExus_mem_1_0_bits_ftqIdx_value,
  output [3:0]   io_toExus_mem_1_0_bits_ftqOffset,
  output         io_toExus_mem_1_0_bits_sqIdx_flag,
  output [5:0]   io_toExus_mem_1_0_bits_sqIdx_value,
  output         io_toExus_mem_1_0_bits_lqIdx_flag,
  output [6:0]   io_toExus_mem_1_0_bits_lqIdx_value,
  output [1:0]   io_toExus_mem_1_0_bits_loadDependency_0,
  output [1:0]   io_toExus_mem_1_0_bits_loadDependency_1,
  output [1:0]   io_toExus_mem_1_0_bits_loadDependency_2,
  output         io_toExus_mem_1_0_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toExus_mem_1_0_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toExus_mem_1_0_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toExus_mem_1_0_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toExus_mem_1_0_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toExus_mem_1_0_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toExus_mem_1_0_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toExus_mem_1_0_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toExus_mem_1_0_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toExus_mem_1_0_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toExus_mem_1_0_bits_debug_seqNum_seqNum,
  output [7:0]   io_toExus_mem_1_0_bits_debug_seqNum_uopIdx,
  input          io_toExus_mem_0_0_ready,
  output         io_toExus_mem_0_0_valid,
  output [34:0]  io_toExus_mem_0_0_bits_fuType,
  output [8:0]   io_toExus_mem_0_0_bits_fuOpType,
  output [63:0]  io_toExus_mem_0_0_bits_src_0,
  output [63:0]  io_toExus_mem_0_0_bits_imm,
  output         io_toExus_mem_0_0_bits_robIdx_flag,
  output [7:0]   io_toExus_mem_0_0_bits_robIdx_value,
  output         io_toExus_mem_0_0_bits_isFirstIssue,
  output [7:0]   io_toExus_mem_0_0_bits_pdest,
  output         io_toExus_mem_0_0_bits_rfWen,
  output         io_toExus_mem_0_0_bits_ftqIdx_flag,
  output [5:0]   io_toExus_mem_0_0_bits_ftqIdx_value,
  output [3:0]   io_toExus_mem_0_0_bits_ftqOffset,
  output         io_toExus_mem_0_0_bits_sqIdx_flag,
  output [5:0]   io_toExus_mem_0_0_bits_sqIdx_value,
  output         io_toExus_mem_0_0_bits_lqIdx_flag,
  output [6:0]   io_toExus_mem_0_0_bits_lqIdx_value,
  output [1:0]   io_toExus_mem_0_0_bits_loadDependency_0,
  output [1:0]   io_toExus_mem_0_0_bits_loadDependency_1,
  output [1:0]   io_toExus_mem_0_0_bits_loadDependency_2,
  output         io_toExus_mem_0_0_bits_perfDebugInfo_eliminatedMove,
  output [63:0]  io_toExus_mem_0_0_bits_perfDebugInfo_renameTime,
  output [63:0]  io_toExus_mem_0_0_bits_perfDebugInfo_dispatchTime,
  output [63:0]  io_toExus_mem_0_0_bits_perfDebugInfo_enqRsTime,
  output [63:0]  io_toExus_mem_0_0_bits_perfDebugInfo_selectTime,
  output [63:0]  io_toExus_mem_0_0_bits_perfDebugInfo_issueTime,
  output [63:0]  io_toExus_mem_0_0_bits_perfDebugInfo_writebackTime,
  output [63:0]  io_toExus_mem_0_0_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_toExus_mem_0_0_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_toExus_mem_0_0_bits_perfDebugInfo_tlbRespTime,
  output [55:0]  io_toExus_mem_0_0_bits_debug_seqNum_seqNum,
  output [7:0]   io_toExus_mem_0_0_bits_debug_seqNum_uopIdx,
  input          io_fromExus_int_3_0_valid,
  input          io_fromExus_int_3_0_bits_intWen,
  input  [63:0]  io_fromExus_int_3_0_bits_data,
  input          io_fromExus_int_2_0_valid,
  input          io_fromExus_int_2_0_bits_intWen,
  input  [63:0]  io_fromExus_int_2_0_bits_data,
  input          io_fromExus_int_1_0_valid,
  input          io_fromExus_int_1_0_bits_intWen,
  input  [63:0]  io_fromExus_int_1_0_bits_data,
  input          io_fromExus_int_0_0_valid,
  input          io_fromExus_int_0_0_bits_intWen,
  input  [63:0]  io_fromExus_int_0_0_bits_data,
  input          io_fromExus_fp_2_0_valid,
  input  [63:0]  io_fromExus_fp_2_0_bits_data,
  input          io_fromExus_fp_1_0_valid,
  input  [63:0]  io_fromExus_fp_1_0_bits_data,
  input          io_fromExus_fp_0_0_valid,
  input  [127:0] io_fromExus_fp_0_0_bits_data,
  input          io_fromExus_mem_4_0_valid,
  input          io_fromExus_mem_4_0_bits_intWen,
  input  [63:0]  io_fromExus_mem_4_0_bits_data,
  input          io_fromExus_mem_3_0_valid,
  input          io_fromExus_mem_3_0_bits_intWen,
  input  [63:0]  io_fromExus_mem_3_0_bits_data,
  input          io_fromExus_mem_2_0_valid,
  input          io_fromExus_mem_2_0_bits_intWen,
  input  [63:0]  io_fromExus_mem_2_0_bits_data,
  output         io_toDataPath_0_wen,
  output [63:0]  io_toDataPath_0_data,
  output         io_toDataPath_1_wen,
  output [63:0]  io_toDataPath_1_data,
  output         io_toDataPath_2_wen,
  output [63:0]  io_toDataPath_2_data,
  output         io_toDataPath_3_wen,
  output [63:0]  io_toDataPath_3_data,
  output         io_toDataPath_4_wen,
  output [63:0]  io_toDataPath_4_data,
  output         io_toDataPath_5_wen,
  output [63:0]  io_toDataPath_5_data,
  output         io_toDataPath_6_wen,
  output [63:0]  io_toDataPath_6_data
);

  // ---- 核的数组接口 ----
  logic [NUM_PROD-1:0]           prod_valid;
  logic [NUM_PROD-1:0][XLEN-1:0] prod_data;
  logic [NUM_RCW-1:0]            rcw_intWen;
  logic [3:0]                    ds       [NUM_EXU][MAX_SRC];
  logic [2:0]                    exu_src  [NUM_EXU][MAX_SRC];
  logic [VLEN-1:0]               reg_data [NUM_EXU][MAX_SRC];
  logic [XLEN-1:0]               rc_data  [NUM_EXU][MAX_SRC];
  logic [31:0]                   imm_raw  [NUM_EXU];
  logic [3:0]                    imm_type [NUM_EXU];
  logic                          is_jump  [NUM_EXU];
  logic                          op_jalr  [NUM_EXU];
  logic [3:0]                    ftq_off  [NUM_EXU];
  logic                          is_rvc   [NUM_EXU];
  logic [VLEN-1:0]               src_out  [NUM_EXU][MAX_SRC];
  logic [XLEN-1:0]               bju_imm  [NUM_EXU];
  logic [4:0]                    bju_npc_off [NUM_EXU];
  logic [NUM_RCW-1:0]            rcw_wen;
  logic [NUM_RCW-1:0][XLEN-1:0]  rcw_data;

  // ---- 旁路源 ----
  assign prod_valid[P_INT0] = io_fromExus_int_0_0_valid;
  assign prod_data[P_INT0]  = io_fromExus_int_0_0_bits_data;
  assign prod_valid[P_INT1] = io_fromExus_int_1_0_valid;
  assign prod_data[P_INT1]  = io_fromExus_int_1_0_bits_data;
  assign prod_valid[P_INT2] = io_fromExus_int_2_0_valid;
  assign prod_data[P_INT2]  = io_fromExus_int_2_0_bits_data;
  assign prod_valid[P_INT3] = io_fromExus_int_3_0_valid;
  assign prod_data[P_INT3]  = io_fromExus_int_3_0_bits_data;
  assign prod_valid[P_FP0] = io_fromExus_fp_0_0_valid;
  assign prod_data[P_FP0]  = io_fromExus_fp_0_0_bits_data[63:0];
  assign prod_valid[P_FP1] = io_fromExus_fp_1_0_valid;
  assign prod_data[P_FP1]  = io_fromExus_fp_1_0_bits_data;
  assign prod_valid[P_FP2] = io_fromExus_fp_2_0_valid;
  assign prod_data[P_FP2]  = io_fromExus_fp_2_0_bits_data;
  assign prod_valid[P_MEM2] = io_fromExus_mem_2_0_valid;
  assign prod_data[P_MEM2]  = io_fromExus_mem_2_0_bits_data;
  assign prod_valid[P_MEM3] = io_fromExus_mem_3_0_valid;
  assign prod_data[P_MEM3]  = io_fromExus_mem_3_0_bits_data;
  assign prod_valid[P_MEM4] = io_fromExus_mem_4_0_valid;
  assign prod_data[P_MEM4]  = io_fromExus_mem_4_0_bits_data;
  assign rcw_intWen[0] = io_fromExus_int_0_0_bits_intWen;
  assign rcw_intWen[1] = io_fromExus_int_1_0_bits_intWen;
  assign rcw_intWen[2] = io_fromExus_int_2_0_bits_intWen;
  assign rcw_intWen[3] = io_fromExus_int_3_0_bits_intWen;
  assign rcw_intWen[4] = io_fromExus_mem_2_0_bits_intWen;
  assign rcw_intWen[5] = io_fromExus_mem_3_0_bits_intWen;
  assign rcw_intWen[6] = io_fromExus_mem_4_0_bits_intWen;

  // ---- 消费者：逐 EXU、逐源（该 EXU 没有的源/字段接 0）----
  // 0: int_0_0
  assign ds[0][0]       = io_fromDataPath_int_0_0_bits_dataSources_0_value;
  assign exu_src[0][0]  = 3'(io_fromDataPath_int_0_0_bits_exuSources_0_value);
  assign reg_data[0][0] = VLEN'(io_fromDataPath_int_0_0_bits_src_0);
  assign rc_data[0][0]  = io_fromDataPath_rcData_0_0_0;
  assign ds[0][1]       = io_fromDataPath_int_0_0_bits_dataSources_1_value;
  assign exu_src[0][1]  = 3'(io_fromDataPath_int_0_0_bits_exuSources_1_value);
  assign reg_data[0][1] = VLEN'(io_fromDataPath_int_0_0_bits_src_1);
  assign rc_data[0][1]  = io_fromDataPath_rcData_0_0_1;
  assign ds[0][2]       = 4'h0;
  assign exu_src[0][2]  = 3'h0;
  assign reg_data[0][2] = '0;
  assign rc_data[0][2]  = '0;
  assign ds[0][3]       = 4'h0;
  assign exu_src[0][3]  = 3'h0;
  assign reg_data[0][3] = '0;
  assign rc_data[0][3]  = '0;
  assign ds[0][4]       = 4'h0;
  assign exu_src[0][4]  = 3'h0;
  assign reg_data[0][4] = '0;
  assign rc_data[0][4]  = '0;
  assign imm_raw[0]  = io_fromDataPath_immInfo_0_imm;
  assign imm_type[0] = io_fromDataPath_immInfo_0_immType;
  assign is_jump[0]  = 1'b0;
  assign op_jalr[0]  = 1'b0;
  assign ftq_off[0]  = 4'h0;
  assign is_rvc[0]   = 1'b0;
  // 1: int_0_1
  assign ds[1][0]       = io_fromDataPath_int_0_1_bits_dataSources_0_value;
  assign exu_src[1][0]  = 3'(io_fromDataPath_int_0_1_bits_exuSources_0_value);
  assign reg_data[1][0] = VLEN'(io_fromDataPath_int_0_1_bits_src_0);
  assign rc_data[1][0]  = io_fromDataPath_rcData_0_1_0;
  assign ds[1][1]       = io_fromDataPath_int_0_1_bits_dataSources_1_value;
  assign exu_src[1][1]  = 3'(io_fromDataPath_int_0_1_bits_exuSources_1_value);
  assign reg_data[1][1] = VLEN'(io_fromDataPath_int_0_1_bits_src_1);
  assign rc_data[1][1]  = io_fromDataPath_rcData_0_1_1;
  assign ds[1][2]       = 4'h0;
  assign exu_src[1][2]  = 3'h0;
  assign reg_data[1][2] = '0;
  assign rc_data[1][2]  = '0;
  assign ds[1][3]       = 4'h0;
  assign exu_src[1][3]  = 3'h0;
  assign reg_data[1][3] = '0;
  assign rc_data[1][3]  = '0;
  assign ds[1][4]       = 4'h0;
  assign exu_src[1][4]  = 3'h0;
  assign reg_data[1][4] = '0;
  assign rc_data[1][4]  = '0;
  assign imm_raw[1]  = io_fromDataPath_immInfo_1_imm;
  assign imm_type[1] = io_fromDataPath_immInfo_1_immType;
  assign is_jump[1]  = io_fromDataPath_int_0_1_bits_fuType[0];
  assign op_jalr[1]  = io_fromDataPath_int_0_1_bits_fuOpType[0];
  assign ftq_off[1]  = io_fromDataPath_int_0_1_bits_ftqOffset;
  assign is_rvc[1]   = io_fromDataPath_int_0_1_bits_preDecode_isRVC;
  // 2: int_1_0
  assign ds[2][0]       = io_fromDataPath_int_1_0_bits_dataSources_0_value;
  assign exu_src[2][0]  = 3'(io_fromDataPath_int_1_0_bits_exuSources_0_value);
  assign reg_data[2][0] = VLEN'(io_fromDataPath_int_1_0_bits_src_0);
  assign rc_data[2][0]  = io_fromDataPath_rcData_1_0_0;
  assign ds[2][1]       = io_fromDataPath_int_1_0_bits_dataSources_1_value;
  assign exu_src[2][1]  = 3'(io_fromDataPath_int_1_0_bits_exuSources_1_value);
  assign reg_data[2][1] = VLEN'(io_fromDataPath_int_1_0_bits_src_1);
  assign rc_data[2][1]  = io_fromDataPath_rcData_1_0_1;
  assign ds[2][2]       = 4'h0;
  assign exu_src[2][2]  = 3'h0;
  assign reg_data[2][2] = '0;
  assign rc_data[2][2]  = '0;
  assign ds[2][3]       = 4'h0;
  assign exu_src[2][3]  = 3'h0;
  assign reg_data[2][3] = '0;
  assign rc_data[2][3]  = '0;
  assign ds[2][4]       = 4'h0;
  assign exu_src[2][4]  = 3'h0;
  assign reg_data[2][4] = '0;
  assign rc_data[2][4]  = '0;
  assign imm_raw[2]  = io_fromDataPath_immInfo_2_imm;
  assign imm_type[2] = io_fromDataPath_immInfo_2_immType;
  assign is_jump[2]  = 1'b0;
  assign op_jalr[2]  = 1'b0;
  assign ftq_off[2]  = 4'h0;
  assign is_rvc[2]   = 1'b0;
  // 3: int_1_1
  assign ds[3][0]       = io_fromDataPath_int_1_1_bits_dataSources_0_value;
  assign exu_src[3][0]  = 3'(io_fromDataPath_int_1_1_bits_exuSources_0_value);
  assign reg_data[3][0] = VLEN'(io_fromDataPath_int_1_1_bits_src_0);
  assign rc_data[3][0]  = io_fromDataPath_rcData_1_1_0;
  assign ds[3][1]       = io_fromDataPath_int_1_1_bits_dataSources_1_value;
  assign exu_src[3][1]  = 3'(io_fromDataPath_int_1_1_bits_exuSources_1_value);
  assign reg_data[3][1] = VLEN'(io_fromDataPath_int_1_1_bits_src_1);
  assign rc_data[3][1]  = io_fromDataPath_rcData_1_1_1;
  assign ds[3][2]       = 4'h0;
  assign exu_src[3][2]  = 3'h0;
  assign reg_data[3][2] = '0;
  assign rc_data[3][2]  = '0;
  assign ds[3][3]       = 4'h0;
  assign exu_src[3][3]  = 3'h0;
  assign reg_data[3][3] = '0;
  assign rc_data[3][3]  = '0;
  assign ds[3][4]       = 4'h0;
  assign exu_src[3][4]  = 3'h0;
  assign reg_data[3][4] = '0;
  assign rc_data[3][4]  = '0;
  assign imm_raw[3]  = io_fromDataPath_immInfo_3_imm;
  assign imm_type[3] = io_fromDataPath_immInfo_3_immType;
  assign is_jump[3]  = io_fromDataPath_int_1_1_bits_fuType[0];
  assign op_jalr[3]  = io_fromDataPath_int_1_1_bits_fuOpType[0];
  assign ftq_off[3]  = io_fromDataPath_int_1_1_bits_ftqOffset;
  assign is_rvc[3]   = io_fromDataPath_int_1_1_bits_preDecode_isRVC;
  // 4: int_2_0
  assign ds[4][0]       = io_fromDataPath_int_2_0_bits_dataSources_0_value;
  assign exu_src[4][0]  = 3'(io_fromDataPath_int_2_0_bits_exuSources_0_value);
  assign reg_data[4][0] = VLEN'(io_fromDataPath_int_2_0_bits_src_0);
  assign rc_data[4][0]  = io_fromDataPath_rcData_2_0_0;
  assign ds[4][1]       = io_fromDataPath_int_2_0_bits_dataSources_1_value;
  assign exu_src[4][1]  = 3'(io_fromDataPath_int_2_0_bits_exuSources_1_value);
  assign reg_data[4][1] = VLEN'(io_fromDataPath_int_2_0_bits_src_1);
  assign rc_data[4][1]  = io_fromDataPath_rcData_2_0_1;
  assign ds[4][2]       = 4'h0;
  assign exu_src[4][2]  = 3'h0;
  assign reg_data[4][2] = '0;
  assign rc_data[4][2]  = '0;
  assign ds[4][3]       = 4'h0;
  assign exu_src[4][3]  = 3'h0;
  assign reg_data[4][3] = '0;
  assign rc_data[4][3]  = '0;
  assign ds[4][4]       = 4'h0;
  assign exu_src[4][4]  = 3'h0;
  assign reg_data[4][4] = '0;
  assign rc_data[4][4]  = '0;
  assign imm_raw[4]  = io_fromDataPath_immInfo_4_imm;
  assign imm_type[4] = io_fromDataPath_immInfo_4_immType;
  assign is_jump[4]  = 1'b0;
  assign op_jalr[4]  = 1'b0;
  assign ftq_off[4]  = 4'h0;
  assign is_rvc[4]   = 1'b0;
  // 5: int_2_1
  assign ds[5][0]       = io_fromDataPath_int_2_1_bits_dataSources_0_value;
  assign exu_src[5][0]  = 3'(io_fromDataPath_int_2_1_bits_exuSources_0_value);
  assign reg_data[5][0] = VLEN'(io_fromDataPath_int_2_1_bits_src_0);
  assign rc_data[5][0]  = io_fromDataPath_rcData_2_1_0;
  assign ds[5][1]       = io_fromDataPath_int_2_1_bits_dataSources_1_value;
  assign exu_src[5][1]  = 3'(io_fromDataPath_int_2_1_bits_exuSources_1_value);
  assign reg_data[5][1] = VLEN'(io_fromDataPath_int_2_1_bits_src_1);
  assign rc_data[5][1]  = io_fromDataPath_rcData_2_1_1;
  assign ds[5][2]       = 4'h0;
  assign exu_src[5][2]  = 3'h0;
  assign reg_data[5][2] = '0;
  assign rc_data[5][2]  = '0;
  assign ds[5][3]       = 4'h0;
  assign exu_src[5][3]  = 3'h0;
  assign reg_data[5][3] = '0;
  assign rc_data[5][3]  = '0;
  assign ds[5][4]       = 4'h0;
  assign exu_src[5][4]  = 3'h0;
  assign reg_data[5][4] = '0;
  assign rc_data[5][4]  = '0;
  assign imm_raw[5]  = io_fromDataPath_immInfo_5_imm;
  assign imm_type[5] = io_fromDataPath_immInfo_5_immType;
  assign is_jump[5]  = io_fromDataPath_int_2_1_bits_fuType[0];
  assign op_jalr[5]  = io_fromDataPath_int_2_1_bits_fuOpType[0];
  assign ftq_off[5]  = io_fromDataPath_int_2_1_bits_ftqOffset;
  assign is_rvc[5]   = io_fromDataPath_int_2_1_bits_preDecode_isRVC;
  // 6: int_3_0
  assign ds[6][0]       = io_fromDataPath_int_3_0_bits_dataSources_0_value;
  assign exu_src[6][0]  = 3'(io_fromDataPath_int_3_0_bits_exuSources_0_value);
  assign reg_data[6][0] = VLEN'(io_fromDataPath_int_3_0_bits_src_0);
  assign rc_data[6][0]  = io_fromDataPath_rcData_3_0_0;
  assign ds[6][1]       = io_fromDataPath_int_3_0_bits_dataSources_1_value;
  assign exu_src[6][1]  = 3'(io_fromDataPath_int_3_0_bits_exuSources_1_value);
  assign reg_data[6][1] = VLEN'(io_fromDataPath_int_3_0_bits_src_1);
  assign rc_data[6][1]  = io_fromDataPath_rcData_3_0_1;
  assign ds[6][2]       = 4'h0;
  assign exu_src[6][2]  = 3'h0;
  assign reg_data[6][2] = '0;
  assign rc_data[6][2]  = '0;
  assign ds[6][3]       = 4'h0;
  assign exu_src[6][3]  = 3'h0;
  assign reg_data[6][3] = '0;
  assign rc_data[6][3]  = '0;
  assign ds[6][4]       = 4'h0;
  assign exu_src[6][4]  = 3'h0;
  assign reg_data[6][4] = '0;
  assign rc_data[6][4]  = '0;
  assign imm_raw[6]  = io_fromDataPath_immInfo_6_imm;
  assign imm_type[6] = io_fromDataPath_immInfo_6_immType;
  assign is_jump[6]  = 1'b0;
  assign op_jalr[6]  = 1'b0;
  assign ftq_off[6]  = 4'h0;
  assign is_rvc[6]   = 1'b0;
  // 7: int_3_1
  assign ds[7][0]       = io_fromDataPath_int_3_1_bits_dataSources_0_value;
  assign exu_src[7][0]  = 3'(io_fromDataPath_int_3_1_bits_exuSources_0_value);
  assign reg_data[7][0] = VLEN'(io_fromDataPath_int_3_1_bits_src_0);
  assign rc_data[7][0]  = io_fromDataPath_rcData_3_1_0;
  assign ds[7][1]       = io_fromDataPath_int_3_1_bits_dataSources_1_value;
  assign exu_src[7][1]  = 3'(io_fromDataPath_int_3_1_bits_exuSources_1_value);
  assign reg_data[7][1] = VLEN'(io_fromDataPath_int_3_1_bits_src_1);
  assign rc_data[7][1]  = io_fromDataPath_rcData_3_1_1;
  assign ds[7][2]       = 4'h0;
  assign exu_src[7][2]  = 3'h0;
  assign reg_data[7][2] = '0;
  assign rc_data[7][2]  = '0;
  assign ds[7][3]       = 4'h0;
  assign exu_src[7][3]  = 3'h0;
  assign reg_data[7][3] = '0;
  assign rc_data[7][3]  = '0;
  assign ds[7][4]       = 4'h0;
  assign exu_src[7][4]  = 3'h0;
  assign reg_data[7][4] = '0;
  assign rc_data[7][4]  = '0;
  assign imm_raw[7]  = '0;
  assign imm_type[7] = '0;
  assign is_jump[7]  = 1'b0;
  assign op_jalr[7]  = 1'b0;
  assign ftq_off[7]  = 4'h0;
  assign is_rvc[7]   = 1'b0;
  // 8: fp_0_0
  assign ds[8][0]       = io_fromDataPath_fp_0_0_bits_dataSources_0_value;
  assign exu_src[8][0]  = 3'(io_fromDataPath_fp_0_0_bits_exuSources_0_value);
  assign reg_data[8][0] = VLEN'(io_fromDataPath_fp_0_0_bits_src_0);
  assign rc_data[8][0]  = '0;
  assign ds[8][1]       = io_fromDataPath_fp_0_0_bits_dataSources_1_value;
  assign exu_src[8][1]  = 3'(io_fromDataPath_fp_0_0_bits_exuSources_1_value);
  assign reg_data[8][1] = VLEN'(io_fromDataPath_fp_0_0_bits_src_1);
  assign rc_data[8][1]  = '0;
  assign ds[8][2]       = io_fromDataPath_fp_0_0_bits_dataSources_2_value;
  assign exu_src[8][2]  = 3'(io_fromDataPath_fp_0_0_bits_exuSources_2_value);
  assign reg_data[8][2] = VLEN'(io_fromDataPath_fp_0_0_bits_src_2);
  assign rc_data[8][2]  = '0;
  assign ds[8][3]       = 4'h0;
  assign exu_src[8][3]  = 3'h0;
  assign reg_data[8][3] = '0;
  assign rc_data[8][3]  = '0;
  assign ds[8][4]       = 4'h0;
  assign exu_src[8][4]  = 3'h0;
  assign reg_data[8][4] = '0;
  assign rc_data[8][4]  = '0;
  assign imm_raw[8]  = '0;
  assign imm_type[8] = '0;
  assign is_jump[8]  = 1'b0;
  assign op_jalr[8]  = 1'b0;
  assign ftq_off[8]  = 4'h0;
  assign is_rvc[8]   = 1'b0;
  // 9: fp_0_1
  assign ds[9][0]       = io_fromDataPath_fp_0_1_bits_dataSources_0_value;
  assign exu_src[9][0]  = 3'(io_fromDataPath_fp_0_1_bits_exuSources_0_value);
  assign reg_data[9][0] = VLEN'(io_fromDataPath_fp_0_1_bits_src_0);
  assign rc_data[9][0]  = '0;
  assign ds[9][1]       = io_fromDataPath_fp_0_1_bits_dataSources_1_value;
  assign exu_src[9][1]  = 3'(io_fromDataPath_fp_0_1_bits_exuSources_1_value);
  assign reg_data[9][1] = VLEN'(io_fromDataPath_fp_0_1_bits_src_1);
  assign rc_data[9][1]  = '0;
  assign ds[9][2]       = 4'h0;
  assign exu_src[9][2]  = 3'h0;
  assign reg_data[9][2] = '0;
  assign rc_data[9][2]  = '0;
  assign ds[9][3]       = 4'h0;
  assign exu_src[9][3]  = 3'h0;
  assign reg_data[9][3] = '0;
  assign rc_data[9][3]  = '0;
  assign ds[9][4]       = 4'h0;
  assign exu_src[9][4]  = 3'h0;
  assign reg_data[9][4] = '0;
  assign rc_data[9][4]  = '0;
  assign imm_raw[9]  = '0;
  assign imm_type[9] = '0;
  assign is_jump[9]  = 1'b0;
  assign op_jalr[9]  = 1'b0;
  assign ftq_off[9]  = 4'h0;
  assign is_rvc[9]   = 1'b0;
  // 10: fp_1_0
  assign ds[10][0]       = io_fromDataPath_fp_1_0_bits_dataSources_0_value;
  assign exu_src[10][0]  = 3'(io_fromDataPath_fp_1_0_bits_exuSources_0_value);
  assign reg_data[10][0] = VLEN'(io_fromDataPath_fp_1_0_bits_src_0);
  assign rc_data[10][0]  = '0;
  assign ds[10][1]       = io_fromDataPath_fp_1_0_bits_dataSources_1_value;
  assign exu_src[10][1]  = 3'(io_fromDataPath_fp_1_0_bits_exuSources_1_value);
  assign reg_data[10][1] = VLEN'(io_fromDataPath_fp_1_0_bits_src_1);
  assign rc_data[10][1]  = '0;
  assign ds[10][2]       = io_fromDataPath_fp_1_0_bits_dataSources_2_value;
  assign exu_src[10][2]  = 3'(io_fromDataPath_fp_1_0_bits_exuSources_2_value);
  assign reg_data[10][2] = VLEN'(io_fromDataPath_fp_1_0_bits_src_2);
  assign rc_data[10][2]  = '0;
  assign ds[10][3]       = 4'h0;
  assign exu_src[10][3]  = 3'h0;
  assign reg_data[10][3] = '0;
  assign rc_data[10][3]  = '0;
  assign ds[10][4]       = 4'h0;
  assign exu_src[10][4]  = 3'h0;
  assign reg_data[10][4] = '0;
  assign rc_data[10][4]  = '0;
  assign imm_raw[10]  = '0;
  assign imm_type[10] = '0;
  assign is_jump[10]  = 1'b0;
  assign op_jalr[10]  = 1'b0;
  assign ftq_off[10]  = 4'h0;
  assign is_rvc[10]   = 1'b0;
  // 11: fp_1_1
  assign ds[11][0]       = io_fromDataPath_fp_1_1_bits_dataSources_0_value;
  assign exu_src[11][0]  = 3'(io_fromDataPath_fp_1_1_bits_exuSources_0_value);
  assign reg_data[11][0] = VLEN'(io_fromDataPath_fp_1_1_bits_src_0);
  assign rc_data[11][0]  = '0;
  assign ds[11][1]       = io_fromDataPath_fp_1_1_bits_dataSources_1_value;
  assign exu_src[11][1]  = 3'(io_fromDataPath_fp_1_1_bits_exuSources_1_value);
  assign reg_data[11][1] = VLEN'(io_fromDataPath_fp_1_1_bits_src_1);
  assign rc_data[11][1]  = '0;
  assign ds[11][2]       = 4'h0;
  assign exu_src[11][2]  = 3'h0;
  assign reg_data[11][2] = '0;
  assign rc_data[11][2]  = '0;
  assign ds[11][3]       = 4'h0;
  assign exu_src[11][3]  = 3'h0;
  assign reg_data[11][3] = '0;
  assign rc_data[11][3]  = '0;
  assign ds[11][4]       = 4'h0;
  assign exu_src[11][4]  = 3'h0;
  assign reg_data[11][4] = '0;
  assign rc_data[11][4]  = '0;
  assign imm_raw[11]  = '0;
  assign imm_type[11] = '0;
  assign is_jump[11]  = 1'b0;
  assign op_jalr[11]  = 1'b0;
  assign ftq_off[11]  = 4'h0;
  assign is_rvc[11]   = 1'b0;
  // 12: fp_2_0
  assign ds[12][0]       = io_fromDataPath_fp_2_0_bits_dataSources_0_value;
  assign exu_src[12][0]  = 3'(io_fromDataPath_fp_2_0_bits_exuSources_0_value);
  assign reg_data[12][0] = VLEN'(io_fromDataPath_fp_2_0_bits_src_0);
  assign rc_data[12][0]  = '0;
  assign ds[12][1]       = io_fromDataPath_fp_2_0_bits_dataSources_1_value;
  assign exu_src[12][1]  = 3'(io_fromDataPath_fp_2_0_bits_exuSources_1_value);
  assign reg_data[12][1] = VLEN'(io_fromDataPath_fp_2_0_bits_src_1);
  assign rc_data[12][1]  = '0;
  assign ds[12][2]       = io_fromDataPath_fp_2_0_bits_dataSources_2_value;
  assign exu_src[12][2]  = 3'(io_fromDataPath_fp_2_0_bits_exuSources_2_value);
  assign reg_data[12][2] = VLEN'(io_fromDataPath_fp_2_0_bits_src_2);
  assign rc_data[12][2]  = '0;
  assign ds[12][3]       = 4'h0;
  assign exu_src[12][3]  = 3'h0;
  assign reg_data[12][3] = '0;
  assign rc_data[12][3]  = '0;
  assign ds[12][4]       = 4'h0;
  assign exu_src[12][4]  = 3'h0;
  assign reg_data[12][4] = '0;
  assign rc_data[12][4]  = '0;
  assign imm_raw[12]  = '0;
  assign imm_type[12] = '0;
  assign is_jump[12]  = 1'b0;
  assign op_jalr[12]  = 1'b0;
  assign ftq_off[12]  = 4'h0;
  assign is_rvc[12]   = 1'b0;
  // 13: vf_0_0
  assign ds[13][0]       = io_fromDataPath_vf_0_0_bits_dataSources_0_value;
  assign exu_src[13][0]  = 3'h0;
  assign reg_data[13][0] = VLEN'(io_fromDataPath_vf_0_0_bits_src_0);
  assign rc_data[13][0]  = '0;
  assign ds[13][1]       = io_fromDataPath_vf_0_0_bits_dataSources_1_value;
  assign exu_src[13][1]  = 3'h0;
  assign reg_data[13][1] = VLEN'(io_fromDataPath_vf_0_0_bits_src_1);
  assign rc_data[13][1]  = '0;
  assign ds[13][2]       = io_fromDataPath_vf_0_0_bits_dataSources_2_value;
  assign exu_src[13][2]  = 3'h0;
  assign reg_data[13][2] = VLEN'(io_fromDataPath_vf_0_0_bits_src_2);
  assign rc_data[13][2]  = '0;
  assign ds[13][3]       = io_fromDataPath_vf_0_0_bits_dataSources_3_value;
  assign exu_src[13][3]  = 3'h0;
  assign reg_data[13][3] = VLEN'(io_fromDataPath_vf_0_0_bits_src_3);
  assign rc_data[13][3]  = '0;
  assign ds[13][4]       = io_fromDataPath_vf_0_0_bits_dataSources_4_value;
  assign exu_src[13][4]  = 3'h0;
  assign reg_data[13][4] = VLEN'(io_fromDataPath_vf_0_0_bits_src_4);
  assign rc_data[13][4]  = '0;
  assign imm_raw[13]  = '0;
  assign imm_type[13] = '0;
  assign is_jump[13]  = 1'b0;
  assign op_jalr[13]  = 1'b0;
  assign ftq_off[13]  = 4'h0;
  assign is_rvc[13]   = 1'b0;
  // 14: vf_0_1
  assign ds[14][0]       = io_fromDataPath_vf_0_1_bits_dataSources_0_value;
  assign exu_src[14][0]  = 3'h0;
  assign reg_data[14][0] = VLEN'(io_fromDataPath_vf_0_1_bits_src_0);
  assign rc_data[14][0]  = '0;
  assign ds[14][1]       = io_fromDataPath_vf_0_1_bits_dataSources_1_value;
  assign exu_src[14][1]  = 3'h0;
  assign reg_data[14][1] = VLEN'(io_fromDataPath_vf_0_1_bits_src_1);
  assign rc_data[14][1]  = '0;
  assign ds[14][2]       = io_fromDataPath_vf_0_1_bits_dataSources_2_value;
  assign exu_src[14][2]  = 3'h0;
  assign reg_data[14][2] = VLEN'(io_fromDataPath_vf_0_1_bits_src_2);
  assign rc_data[14][2]  = '0;
  assign ds[14][3]       = io_fromDataPath_vf_0_1_bits_dataSources_3_value;
  assign exu_src[14][3]  = 3'h0;
  assign reg_data[14][3] = VLEN'(io_fromDataPath_vf_0_1_bits_src_3);
  assign rc_data[14][3]  = '0;
  assign ds[14][4]       = io_fromDataPath_vf_0_1_bits_dataSources_4_value;
  assign exu_src[14][4]  = 3'h0;
  assign reg_data[14][4] = VLEN'(io_fromDataPath_vf_0_1_bits_src_4);
  assign rc_data[14][4]  = '0;
  assign imm_raw[14]  = io_fromDataPath_immInfo_14_imm;
  assign imm_type[14] = io_fromDataPath_immInfo_14_immType;
  assign is_jump[14]  = 1'b0;
  assign op_jalr[14]  = 1'b0;
  assign ftq_off[14]  = 4'h0;
  assign is_rvc[14]   = 1'b0;
  // 15: vf_1_0
  assign ds[15][0]       = io_fromDataPath_vf_1_0_bits_dataSources_0_value;
  assign exu_src[15][0]  = 3'h0;
  assign reg_data[15][0] = VLEN'(io_fromDataPath_vf_1_0_bits_src_0);
  assign rc_data[15][0]  = '0;
  assign ds[15][1]       = io_fromDataPath_vf_1_0_bits_dataSources_1_value;
  assign exu_src[15][1]  = 3'h0;
  assign reg_data[15][1] = VLEN'(io_fromDataPath_vf_1_0_bits_src_1);
  assign rc_data[15][1]  = '0;
  assign ds[15][2]       = io_fromDataPath_vf_1_0_bits_dataSources_2_value;
  assign exu_src[15][2]  = 3'h0;
  assign reg_data[15][2] = VLEN'(io_fromDataPath_vf_1_0_bits_src_2);
  assign rc_data[15][2]  = '0;
  assign ds[15][3]       = io_fromDataPath_vf_1_0_bits_dataSources_3_value;
  assign exu_src[15][3]  = 3'h0;
  assign reg_data[15][3] = VLEN'(io_fromDataPath_vf_1_0_bits_src_3);
  assign rc_data[15][3]  = '0;
  assign ds[15][4]       = io_fromDataPath_vf_1_0_bits_dataSources_4_value;
  assign exu_src[15][4]  = 3'h0;
  assign reg_data[15][4] = VLEN'(io_fromDataPath_vf_1_0_bits_src_4);
  assign rc_data[15][4]  = '0;
  assign imm_raw[15]  = '0;
  assign imm_type[15] = '0;
  assign is_jump[15]  = 1'b0;
  assign op_jalr[15]  = 1'b0;
  assign ftq_off[15]  = 4'h0;
  assign is_rvc[15]   = 1'b0;
  // 16: vf_1_1
  assign ds[16][0]       = io_fromDataPath_vf_1_1_bits_dataSources_0_value;
  assign exu_src[16][0]  = 3'h0;
  assign reg_data[16][0] = VLEN'(io_fromDataPath_vf_1_1_bits_src_0);
  assign rc_data[16][0]  = '0;
  assign ds[16][1]       = io_fromDataPath_vf_1_1_bits_dataSources_1_value;
  assign exu_src[16][1]  = 3'h0;
  assign reg_data[16][1] = VLEN'(io_fromDataPath_vf_1_1_bits_src_1);
  assign rc_data[16][1]  = '0;
  assign ds[16][2]       = io_fromDataPath_vf_1_1_bits_dataSources_2_value;
  assign exu_src[16][2]  = 3'h0;
  assign reg_data[16][2] = VLEN'(io_fromDataPath_vf_1_1_bits_src_2);
  assign rc_data[16][2]  = '0;
  assign ds[16][3]       = io_fromDataPath_vf_1_1_bits_dataSources_3_value;
  assign exu_src[16][3]  = 3'h0;
  assign reg_data[16][3] = VLEN'(io_fromDataPath_vf_1_1_bits_src_3);
  assign rc_data[16][3]  = '0;
  assign ds[16][4]       = io_fromDataPath_vf_1_1_bits_dataSources_4_value;
  assign exu_src[16][4]  = 3'h0;
  assign reg_data[16][4] = VLEN'(io_fromDataPath_vf_1_1_bits_src_4);
  assign rc_data[16][4]  = '0;
  assign imm_raw[16]  = '0;
  assign imm_type[16] = '0;
  assign is_jump[16]  = 1'b0;
  assign op_jalr[16]  = 1'b0;
  assign ftq_off[16]  = 4'h0;
  assign is_rvc[16]   = 1'b0;
  // 17: vf_2_0
  assign ds[17][0]       = io_fromDataPath_vf_2_0_bits_dataSources_0_value;
  assign exu_src[17][0]  = 3'h0;
  assign reg_data[17][0] = VLEN'(io_fromDataPath_vf_2_0_bits_src_0);
  assign rc_data[17][0]  = '0;
  assign ds[17][1]       = io_fromDataPath_vf_2_0_bits_dataSources_1_value;
  assign exu_src[17][1]  = 3'h0;
  assign reg_data[17][1] = VLEN'(io_fromDataPath_vf_2_0_bits_src_1);
  assign rc_data[17][1]  = '0;
  assign ds[17][2]       = io_fromDataPath_vf_2_0_bits_dataSources_2_value;
  assign exu_src[17][2]  = 3'h0;
  assign reg_data[17][2] = VLEN'(io_fromDataPath_vf_2_0_bits_src_2);
  assign rc_data[17][2]  = '0;
  assign ds[17][3]       = io_fromDataPath_vf_2_0_bits_dataSources_3_value;
  assign exu_src[17][3]  = 3'h0;
  assign reg_data[17][3] = VLEN'(io_fromDataPath_vf_2_0_bits_src_3);
  assign rc_data[17][3]  = '0;
  assign ds[17][4]       = io_fromDataPath_vf_2_0_bits_dataSources_4_value;
  assign exu_src[17][4]  = 3'h0;
  assign reg_data[17][4] = VLEN'(io_fromDataPath_vf_2_0_bits_src_4);
  assign rc_data[17][4]  = '0;
  assign imm_raw[17]  = '0;
  assign imm_type[17] = '0;
  assign is_jump[17]  = 1'b0;
  assign op_jalr[17]  = 1'b0;
  assign ftq_off[17]  = 4'h0;
  assign is_rvc[17]   = 1'b0;
  // 18: mem_0_0
  assign ds[18][0]       = io_fromDataPath_mem_0_0_bits_dataSources_0_value;
  assign exu_src[18][0]  = 3'(io_fromDataPath_mem_0_0_bits_exuSources_0_value);
  assign reg_data[18][0] = VLEN'(io_fromDataPath_mem_0_0_bits_src_0);
  assign rc_data[18][0]  = io_fromDataPath_rcData_10_0_0;
  assign ds[18][1]       = 4'h0;
  assign exu_src[18][1]  = 3'h0;
  assign reg_data[18][1] = '0;
  assign rc_data[18][1]  = '0;
  assign ds[18][2]       = 4'h0;
  assign exu_src[18][2]  = 3'h0;
  assign reg_data[18][2] = '0;
  assign rc_data[18][2]  = '0;
  assign ds[18][3]       = 4'h0;
  assign exu_src[18][3]  = 3'h0;
  assign reg_data[18][3] = '0;
  assign rc_data[18][3]  = '0;
  assign ds[18][4]       = 4'h0;
  assign exu_src[18][4]  = 3'h0;
  assign reg_data[18][4] = '0;
  assign rc_data[18][4]  = '0;
  assign imm_raw[18]  = io_fromDataPath_immInfo_18_imm;
  assign imm_type[18] = io_fromDataPath_immInfo_18_immType;
  assign is_jump[18]  = 1'b0;
  assign op_jalr[18]  = 1'b0;
  assign ftq_off[18]  = 4'h0;
  assign is_rvc[18]   = 1'b0;
  // 19: mem_1_0
  assign ds[19][0]       = io_fromDataPath_mem_1_0_bits_dataSources_0_value;
  assign exu_src[19][0]  = 3'(io_fromDataPath_mem_1_0_bits_exuSources_0_value);
  assign reg_data[19][0] = VLEN'(io_fromDataPath_mem_1_0_bits_src_0);
  assign rc_data[19][0]  = io_fromDataPath_rcData_11_0_0;
  assign ds[19][1]       = 4'h0;
  assign exu_src[19][1]  = 3'h0;
  assign reg_data[19][1] = '0;
  assign rc_data[19][1]  = '0;
  assign ds[19][2]       = 4'h0;
  assign exu_src[19][2]  = 3'h0;
  assign reg_data[19][2] = '0;
  assign rc_data[19][2]  = '0;
  assign ds[19][3]       = 4'h0;
  assign exu_src[19][3]  = 3'h0;
  assign reg_data[19][3] = '0;
  assign rc_data[19][3]  = '0;
  assign ds[19][4]       = 4'h0;
  assign exu_src[19][4]  = 3'h0;
  assign reg_data[19][4] = '0;
  assign rc_data[19][4]  = '0;
  assign imm_raw[19]  = io_fromDataPath_immInfo_19_imm;
  assign imm_type[19] = io_fromDataPath_immInfo_19_immType;
  assign is_jump[19]  = 1'b0;
  assign op_jalr[19]  = 1'b0;
  assign ftq_off[19]  = 4'h0;
  assign is_rvc[19]   = 1'b0;
  // 20: mem_2_0
  assign ds[20][0]       = io_fromDataPath_mem_2_0_bits_dataSources_0_value;
  assign exu_src[20][0]  = 3'(io_fromDataPath_mem_2_0_bits_exuSources_0_value);
  assign reg_data[20][0] = VLEN'(io_fromDataPath_mem_2_0_bits_src_0);
  assign rc_data[20][0]  = io_fromDataPath_rcData_12_0_0;
  assign ds[20][1]       = 4'h0;
  assign exu_src[20][1]  = 3'h0;
  assign reg_data[20][1] = '0;
  assign rc_data[20][1]  = '0;
  assign ds[20][2]       = 4'h0;
  assign exu_src[20][2]  = 3'h0;
  assign reg_data[20][2] = '0;
  assign rc_data[20][2]  = '0;
  assign ds[20][3]       = 4'h0;
  assign exu_src[20][3]  = 3'h0;
  assign reg_data[20][3] = '0;
  assign rc_data[20][3]  = '0;
  assign ds[20][4]       = 4'h0;
  assign exu_src[20][4]  = 3'h0;
  assign reg_data[20][4] = '0;
  assign rc_data[20][4]  = '0;
  assign imm_raw[20]  = io_fromDataPath_immInfo_20_imm;
  assign imm_type[20] = '0;
  assign is_jump[20]  = 1'b0;
  assign op_jalr[20]  = 1'b0;
  assign ftq_off[20]  = 4'h0;
  assign is_rvc[20]   = 1'b0;
  // 21: mem_3_0
  assign ds[21][0]       = io_fromDataPath_mem_3_0_bits_dataSources_0_value;
  assign exu_src[21][0]  = 3'(io_fromDataPath_mem_3_0_bits_exuSources_0_value);
  assign reg_data[21][0] = VLEN'(io_fromDataPath_mem_3_0_bits_src_0);
  assign rc_data[21][0]  = io_fromDataPath_rcData_13_0_0;
  assign ds[21][1]       = 4'h0;
  assign exu_src[21][1]  = 3'h0;
  assign reg_data[21][1] = '0;
  assign rc_data[21][1]  = '0;
  assign ds[21][2]       = 4'h0;
  assign exu_src[21][2]  = 3'h0;
  assign reg_data[21][2] = '0;
  assign rc_data[21][2]  = '0;
  assign ds[21][3]       = 4'h0;
  assign exu_src[21][3]  = 3'h0;
  assign reg_data[21][3] = '0;
  assign rc_data[21][3]  = '0;
  assign ds[21][4]       = 4'h0;
  assign exu_src[21][4]  = 3'h0;
  assign reg_data[21][4] = '0;
  assign rc_data[21][4]  = '0;
  assign imm_raw[21]  = io_fromDataPath_immInfo_21_imm;
  assign imm_type[21] = '0;
  assign is_jump[21]  = 1'b0;
  assign op_jalr[21]  = 1'b0;
  assign ftq_off[21]  = 4'h0;
  assign is_rvc[21]   = 1'b0;
  // 22: mem_4_0
  assign ds[22][0]       = io_fromDataPath_mem_4_0_bits_dataSources_0_value;
  assign exu_src[22][0]  = 3'(io_fromDataPath_mem_4_0_bits_exuSources_0_value);
  assign reg_data[22][0] = VLEN'(io_fromDataPath_mem_4_0_bits_src_0);
  assign rc_data[22][0]  = io_fromDataPath_rcData_14_0_0;
  assign ds[22][1]       = 4'h0;
  assign exu_src[22][1]  = 3'h0;
  assign reg_data[22][1] = '0;
  assign rc_data[22][1]  = '0;
  assign ds[22][2]       = 4'h0;
  assign exu_src[22][2]  = 3'h0;
  assign reg_data[22][2] = '0;
  assign rc_data[22][2]  = '0;
  assign ds[22][3]       = 4'h0;
  assign exu_src[22][3]  = 3'h0;
  assign reg_data[22][3] = '0;
  assign rc_data[22][3]  = '0;
  assign ds[22][4]       = 4'h0;
  assign exu_src[22][4]  = 3'h0;
  assign reg_data[22][4] = '0;
  assign rc_data[22][4]  = '0;
  assign imm_raw[22]  = io_fromDataPath_immInfo_22_imm;
  assign imm_type[22] = '0;
  assign is_jump[22]  = 1'b0;
  assign op_jalr[22]  = 1'b0;
  assign ftq_off[22]  = 4'h0;
  assign is_rvc[22]   = 1'b0;
  // 23: mem_5_0
  assign ds[23][0]       = io_fromDataPath_mem_5_0_bits_dataSources_0_value;
  assign exu_src[23][0]  = 3'h0;
  assign reg_data[23][0] = VLEN'(io_fromDataPath_mem_5_0_bits_src_0);
  assign rc_data[23][0]  = '0;
  assign ds[23][1]       = io_fromDataPath_mem_5_0_bits_dataSources_1_value;
  assign exu_src[23][1]  = 3'h0;
  assign reg_data[23][1] = VLEN'(io_fromDataPath_mem_5_0_bits_src_1);
  assign rc_data[23][1]  = '0;
  assign ds[23][2]       = io_fromDataPath_mem_5_0_bits_dataSources_2_value;
  assign exu_src[23][2]  = 3'h0;
  assign reg_data[23][2] = VLEN'(io_fromDataPath_mem_5_0_bits_src_2);
  assign rc_data[23][2]  = '0;
  assign ds[23][3]       = io_fromDataPath_mem_5_0_bits_dataSources_3_value;
  assign exu_src[23][3]  = 3'h0;
  assign reg_data[23][3] = VLEN'(io_fromDataPath_mem_5_0_bits_src_3);
  assign rc_data[23][3]  = '0;
  assign ds[23][4]       = io_fromDataPath_mem_5_0_bits_dataSources_4_value;
  assign exu_src[23][4]  = 3'h0;
  assign reg_data[23][4] = VLEN'(io_fromDataPath_mem_5_0_bits_src_4);
  assign rc_data[23][4]  = '0;
  assign imm_raw[23]  = '0;
  assign imm_type[23] = '0;
  assign is_jump[23]  = 1'b0;
  assign op_jalr[23]  = 1'b0;
  assign ftq_off[23]  = 4'h0;
  assign is_rvc[23]   = 1'b0;
  // 24: mem_6_0
  assign ds[24][0]       = io_fromDataPath_mem_6_0_bits_dataSources_0_value;
  assign exu_src[24][0]  = 3'h0;
  assign reg_data[24][0] = VLEN'(io_fromDataPath_mem_6_0_bits_src_0);
  assign rc_data[24][0]  = '0;
  assign ds[24][1]       = io_fromDataPath_mem_6_0_bits_dataSources_1_value;
  assign exu_src[24][1]  = 3'h0;
  assign reg_data[24][1] = VLEN'(io_fromDataPath_mem_6_0_bits_src_1);
  assign rc_data[24][1]  = '0;
  assign ds[24][2]       = io_fromDataPath_mem_6_0_bits_dataSources_2_value;
  assign exu_src[24][2]  = 3'h0;
  assign reg_data[24][2] = VLEN'(io_fromDataPath_mem_6_0_bits_src_2);
  assign rc_data[24][2]  = '0;
  assign ds[24][3]       = io_fromDataPath_mem_6_0_bits_dataSources_3_value;
  assign exu_src[24][3]  = 3'h0;
  assign reg_data[24][3] = VLEN'(io_fromDataPath_mem_6_0_bits_src_3);
  assign rc_data[24][3]  = '0;
  assign ds[24][4]       = io_fromDataPath_mem_6_0_bits_dataSources_4_value;
  assign exu_src[24][4]  = 3'h0;
  assign reg_data[24][4] = VLEN'(io_fromDataPath_mem_6_0_bits_src_4);
  assign rc_data[24][4]  = '0;
  assign imm_raw[24]  = '0;
  assign imm_type[24] = '0;
  assign is_jump[24]  = 1'b0;
  assign op_jalr[24]  = 1'b0;
  assign ftq_off[24]  = 4'h0;
  assign is_rvc[24]   = 1'b0;
  // 25: mem_7_0
  assign ds[25][0]       = io_fromDataPath_mem_7_0_bits_dataSources_0_value;
  assign exu_src[25][0]  = 3'(io_fromDataPath_mem_7_0_bits_exuSources_0_value);
  assign reg_data[25][0] = VLEN'(io_fromDataPath_mem_7_0_bits_src_0);
  assign rc_data[25][0]  = io_fromDataPath_rcData_17_0_0;
  assign ds[25][1]       = 4'h0;
  assign exu_src[25][1]  = 3'h0;
  assign reg_data[25][1] = '0;
  assign rc_data[25][1]  = '0;
  assign ds[25][2]       = 4'h0;
  assign exu_src[25][2]  = 3'h0;
  assign reg_data[25][2] = '0;
  assign rc_data[25][2]  = '0;
  assign ds[25][3]       = 4'h0;
  assign exu_src[25][3]  = 3'h0;
  assign reg_data[25][3] = '0;
  assign rc_data[25][3]  = '0;
  assign ds[25][4]       = 4'h0;
  assign exu_src[25][4]  = 3'h0;
  assign reg_data[25][4] = '0;
  assign rc_data[25][4]  = '0;
  assign imm_raw[25]  = '0;
  assign imm_type[25] = '0;
  assign is_jump[25]  = 1'b0;
  assign op_jalr[25]  = 1'b0;
  assign ftq_off[25]  = 4'h0;
  assign is_rvc[25]   = 1'b0;
  // 26: mem_8_0
  assign ds[26][0]       = io_fromDataPath_mem_8_0_bits_dataSources_0_value;
  assign exu_src[26][0]  = 3'(io_fromDataPath_mem_8_0_bits_exuSources_0_value);
  assign reg_data[26][0] = VLEN'(io_fromDataPath_mem_8_0_bits_src_0);
  assign rc_data[26][0]  = io_fromDataPath_rcData_18_0_0;
  assign ds[26][1]       = 4'h0;
  assign exu_src[26][1]  = 3'h0;
  assign reg_data[26][1] = '0;
  assign rc_data[26][1]  = '0;
  assign ds[26][2]       = 4'h0;
  assign exu_src[26][2]  = 3'h0;
  assign reg_data[26][2] = '0;
  assign rc_data[26][2]  = '0;
  assign ds[26][3]       = 4'h0;
  assign exu_src[26][3]  = 3'h0;
  assign reg_data[26][3] = '0;
  assign rc_data[26][3]  = '0;
  assign ds[26][4]       = 4'h0;
  assign exu_src[26][4]  = 3'h0;
  assign reg_data[26][4] = '0;
  assign rc_data[26][4]  = '0;
  assign imm_raw[26]  = '0;
  assign imm_type[26] = '0;
  assign is_jump[26]  = 1'b0;
  assign op_jalr[26]  = 1'b0;
  assign ftq_off[26]  = 4'h0;
  assign is_rvc[26]   = 1'b0;

  xs_BypassNetwork_core u_core (
    .clock       (clock),
    .reset       (reset),
    .prod_valid  (prod_valid),
    .prod_data   (prod_data),
    .rcw_intWen  (rcw_intWen),
    .ds          (ds),
    .exu_src     (exu_src),
    .reg_data    (reg_data),
    .rc_data     (rc_data),
    .imm_raw     (imm_raw),
    .imm_type    (imm_type),
    .is_jump     (is_jump),
    .op_jalr     (op_jalr),
    .ftq_off     (ftq_off),
    .is_rvc      (is_rvc),
    .src_out     (src_out),
    .bju_imm     (bju_imm),
    .bju_npc_off (bju_npc_off),
    .rcw_wen     (rcw_wen),
    .rcw_data    (rcw_data)
  );

  // ---- 核输出拆包 ----
  assign io_toExus_int_0_0_bits_src_0 = src_out[0][0][63:0];
  assign io_toExus_int_0_0_bits_src_1 = src_out[0][1][63:0];
  assign io_toExus_int_0_1_bits_src_0 = src_out[1][0][63:0];
  assign io_toExus_int_0_1_bits_src_1 = src_out[1][1][63:0];
  assign io_toExus_int_0_1_bits_imm = bju_imm[1];
  assign io_toExus_int_0_1_bits_nextPcOffset = bju_npc_off[1];
  assign io_toExus_int_1_0_bits_src_0 = src_out[2][0][63:0];
  assign io_toExus_int_1_0_bits_src_1 = src_out[2][1][63:0];
  assign io_toExus_int_1_1_bits_src_0 = src_out[3][0][63:0];
  assign io_toExus_int_1_1_bits_src_1 = src_out[3][1][63:0];
  assign io_toExus_int_1_1_bits_imm = bju_imm[3];
  assign io_toExus_int_1_1_bits_nextPcOffset = bju_npc_off[3];
  assign io_toExus_int_2_0_bits_src_0 = src_out[4][0][63:0];
  assign io_toExus_int_2_0_bits_src_1 = src_out[4][1][63:0];
  assign io_toExus_int_2_1_bits_src_0 = src_out[5][0][63:0];
  assign io_toExus_int_2_1_bits_src_1 = src_out[5][1][63:0];
  assign io_toExus_int_2_1_bits_imm = bju_imm[5];
  assign io_toExus_int_2_1_bits_nextPcOffset = bju_npc_off[5];
  assign io_toExus_int_3_0_bits_src_0 = src_out[6][0][63:0];
  assign io_toExus_int_3_0_bits_src_1 = src_out[6][1][63:0];
  assign io_toExus_int_3_1_bits_src_0 = src_out[7][0][63:0];
  assign io_toExus_int_3_1_bits_src_1 = src_out[7][1][63:0];
  assign io_toExus_fp_0_0_bits_src_0 = src_out[8][0][63:0];
  assign io_toExus_fp_0_0_bits_src_1 = src_out[8][1][63:0];
  assign io_toExus_fp_0_0_bits_src_2 = src_out[8][2][63:0];
  assign io_toExus_fp_0_1_bits_src_0 = src_out[9][0][63:0];
  assign io_toExus_fp_0_1_bits_src_1 = src_out[9][1][63:0];
  assign io_toExus_fp_1_0_bits_src_0 = src_out[10][0][63:0];
  assign io_toExus_fp_1_0_bits_src_1 = src_out[10][1][63:0];
  assign io_toExus_fp_1_0_bits_src_2 = src_out[10][2][63:0];
  assign io_toExus_fp_1_1_bits_src_0 = src_out[11][0][63:0];
  assign io_toExus_fp_1_1_bits_src_1 = src_out[11][1][63:0];
  assign io_toExus_fp_2_0_bits_src_0 = src_out[12][0][63:0];
  assign io_toExus_fp_2_0_bits_src_1 = src_out[12][1][63:0];
  assign io_toExus_fp_2_0_bits_src_2 = src_out[12][2][63:0];
  assign io_toExus_vf_0_0_bits_src_0 = src_out[13][0][127:0];
  assign io_toExus_vf_0_0_bits_src_1 = src_out[13][1][127:0];
  assign io_toExus_vf_0_0_bits_src_2 = src_out[13][2][127:0];
  assign io_toExus_vf_0_0_bits_src_3 = src_out[13][3][127:0];
  assign io_toExus_vf_0_0_bits_src_4 = src_out[13][4][127:0];
  assign io_toExus_vf_0_1_bits_src_0 = src_out[14][0][127:0];
  assign io_toExus_vf_0_1_bits_src_1 = src_out[14][1][127:0];
  assign io_toExus_vf_0_1_bits_src_2 = src_out[14][2][127:0];
  assign io_toExus_vf_0_1_bits_src_3 = src_out[14][3][127:0];
  assign io_toExus_vf_0_1_bits_src_4 = src_out[14][4][127:0];
  assign io_toExus_vf_1_0_bits_src_0 = src_out[15][0][127:0];
  assign io_toExus_vf_1_0_bits_src_1 = src_out[15][1][127:0];
  assign io_toExus_vf_1_0_bits_src_2 = src_out[15][2][127:0];
  assign io_toExus_vf_1_0_bits_src_3 = src_out[15][3][127:0];
  assign io_toExus_vf_1_0_bits_src_4 = src_out[15][4][127:0];
  assign io_toExus_vf_1_1_bits_src_0 = src_out[16][0][127:0];
  assign io_toExus_vf_1_1_bits_src_1 = src_out[16][1][127:0];
  assign io_toExus_vf_1_1_bits_src_2 = src_out[16][2][127:0];
  assign io_toExus_vf_1_1_bits_src_3 = src_out[16][3][127:0];
  assign io_toExus_vf_1_1_bits_src_4 = src_out[16][4][127:0];
  assign io_toExus_vf_2_0_bits_src_0 = src_out[17][0][127:0];
  assign io_toExus_vf_2_0_bits_src_1 = src_out[17][1][127:0];
  assign io_toExus_vf_2_0_bits_src_2 = src_out[17][2][127:0];
  assign io_toExus_vf_2_0_bits_src_3 = src_out[17][3][127:0];
  assign io_toExus_vf_2_0_bits_src_4 = src_out[17][4][127:0];
  assign io_toExus_mem_0_0_bits_src_0 = src_out[18][0][63:0];
  assign io_toExus_mem_1_0_bits_src_0 = src_out[19][0][63:0];
  assign io_toExus_mem_2_0_bits_src_0 = src_out[20][0][63:0];
  assign io_toExus_mem_3_0_bits_src_0 = src_out[21][0][63:0];
  assign io_toExus_mem_4_0_bits_src_0 = src_out[22][0][63:0];
  assign io_toExus_mem_5_0_bits_src_0 = src_out[23][0][127:0];
  assign io_toExus_mem_5_0_bits_src_1 = src_out[23][1][127:0];
  assign io_toExus_mem_5_0_bits_src_2 = src_out[23][2][127:0];
  assign io_toExus_mem_5_0_bits_src_3 = src_out[23][3][127:0];
  assign io_toExus_mem_5_0_bits_src_4 = src_out[23][4][127:0];
  assign io_toExus_mem_6_0_bits_src_0 = src_out[24][0][127:0];
  assign io_toExus_mem_6_0_bits_src_1 = src_out[24][1][127:0];
  assign io_toExus_mem_6_0_bits_src_2 = src_out[24][2][127:0];
  assign io_toExus_mem_6_0_bits_src_3 = src_out[24][3][127:0];
  assign io_toExus_mem_6_0_bits_src_4 = src_out[24][4][127:0];
  assign io_toExus_mem_7_0_bits_src_0 = src_out[25][0][63:0];
  assign io_toExus_mem_8_0_bits_src_0 = src_out[26][0][63:0];
  assign io_toDataPath_0_wen  = rcw_wen[0];
  assign io_toDataPath_0_data = rcw_data[0];
  assign io_toDataPath_1_wen  = rcw_wen[1];
  assign io_toDataPath_1_data = rcw_data[1];
  assign io_toDataPath_2_wen  = rcw_wen[2];
  assign io_toDataPath_2_data = rcw_data[2];
  assign io_toDataPath_3_wen  = rcw_wen[3];
  assign io_toDataPath_3_data = rcw_data[3];
  assign io_toDataPath_4_wen  = rcw_wen[4];
  assign io_toDataPath_4_data = rcw_data[4];
  assign io_toDataPath_5_wen  = rcw_wen[5];
  assign io_toDataPath_5_data = rcw_data[5];
  assign io_toDataPath_6_wen  = rcw_wen[6];
  assign io_toDataPath_6_data = rcw_data[6];

  // ---- 其余 ExuInput 字段与 valid：直连；ready：反向直连 ----
  assign io_toExus_int_3_1_valid = io_fromDataPath_int_3_1_valid;
  assign io_toExus_int_3_1_bits_fuType = io_fromDataPath_int_3_1_bits_fuType;
  assign io_toExus_int_3_1_bits_fuOpType = io_fromDataPath_int_3_1_bits_fuOpType;
  assign io_toExus_int_3_1_bits_imm = io_fromDataPath_int_3_1_bits_imm;
  assign io_toExus_int_3_1_bits_robIdx_flag = io_fromDataPath_int_3_1_bits_robIdx_flag;
  assign io_toExus_int_3_1_bits_robIdx_value = io_fromDataPath_int_3_1_bits_robIdx_value;
  assign io_toExus_int_3_1_bits_pdest = io_fromDataPath_int_3_1_bits_pdest;
  assign io_toExus_int_3_1_bits_rfWen = io_fromDataPath_int_3_1_bits_rfWen;
  assign io_toExus_int_3_1_bits_flushPipe = io_fromDataPath_int_3_1_bits_flushPipe;
  assign io_toExus_int_3_1_bits_preDecode_valid = io_fromDataPath_int_3_1_bits_preDecode_valid;
  assign io_toExus_int_3_1_bits_preDecode_isRVC = io_fromDataPath_int_3_1_bits_preDecode_isRVC;
  assign io_toExus_int_3_1_bits_preDecode_brType = io_fromDataPath_int_3_1_bits_preDecode_brType;
  assign io_toExus_int_3_1_bits_preDecode_isCall = io_fromDataPath_int_3_1_bits_preDecode_isCall;
  assign io_toExus_int_3_1_bits_preDecode_isRet = io_fromDataPath_int_3_1_bits_preDecode_isRet;
  assign io_toExus_int_3_1_bits_ftqIdx_flag = io_fromDataPath_int_3_1_bits_ftqIdx_flag;
  assign io_toExus_int_3_1_bits_ftqIdx_value = io_fromDataPath_int_3_1_bits_ftqIdx_value;
  assign io_toExus_int_3_1_bits_ftqOffset = io_fromDataPath_int_3_1_bits_ftqOffset;
  assign io_toExus_int_3_1_bits_loadDependency_0 = io_fromDataPath_int_3_1_bits_loadDependency_0;
  assign io_toExus_int_3_1_bits_loadDependency_1 = io_fromDataPath_int_3_1_bits_loadDependency_1;
  assign io_toExus_int_3_1_bits_loadDependency_2 = io_fromDataPath_int_3_1_bits_loadDependency_2;
  assign io_toExus_int_3_1_bits_perfDebugInfo_eliminatedMove = io_fromDataPath_int_3_1_bits_perfDebugInfo_eliminatedMove;
  assign io_toExus_int_3_1_bits_perfDebugInfo_renameTime = io_fromDataPath_int_3_1_bits_perfDebugInfo_renameTime;
  assign io_toExus_int_3_1_bits_perfDebugInfo_dispatchTime = io_fromDataPath_int_3_1_bits_perfDebugInfo_dispatchTime;
  assign io_toExus_int_3_1_bits_perfDebugInfo_enqRsTime = io_fromDataPath_int_3_1_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_int_3_1_bits_perfDebugInfo_selectTime = io_fromDataPath_int_3_1_bits_perfDebugInfo_selectTime;
  assign io_toExus_int_3_1_bits_perfDebugInfo_issueTime = io_fromDataPath_int_3_1_bits_perfDebugInfo_issueTime;
  assign io_toExus_int_3_1_bits_perfDebugInfo_writebackTime = io_fromDataPath_int_3_1_bits_perfDebugInfo_writebackTime;
  assign io_toExus_int_3_1_bits_perfDebugInfo_runahead_checkpoint_id = io_fromDataPath_int_3_1_bits_perfDebugInfo_runahead_checkpoint_id;
  assign io_toExus_int_3_1_bits_perfDebugInfo_tlbFirstReqTime = io_fromDataPath_int_3_1_bits_perfDebugInfo_tlbFirstReqTime;
  assign io_toExus_int_3_1_bits_perfDebugInfo_tlbRespTime = io_fromDataPath_int_3_1_bits_perfDebugInfo_tlbRespTime;
  assign io_toExus_int_3_1_bits_debug_seqNum_seqNum = io_fromDataPath_int_3_1_bits_debug_seqNum_seqNum;
  assign io_toExus_int_3_1_bits_debug_seqNum_uopIdx = io_fromDataPath_int_3_1_bits_debug_seqNum_uopIdx;
  assign io_toExus_int_3_0_valid = io_fromDataPath_int_3_0_valid;
  assign io_toExus_int_3_0_bits_fuType = io_fromDataPath_int_3_0_bits_fuType;
  assign io_toExus_int_3_0_bits_fuOpType = io_fromDataPath_int_3_0_bits_fuOpType;
  assign io_toExus_int_3_0_bits_robIdx_flag = io_fromDataPath_int_3_0_bits_robIdx_flag;
  assign io_toExus_int_3_0_bits_robIdx_value = io_fromDataPath_int_3_0_bits_robIdx_value;
  assign io_toExus_int_3_0_bits_pdest = io_fromDataPath_int_3_0_bits_pdest;
  assign io_toExus_int_3_0_bits_rfWen = io_fromDataPath_int_3_0_bits_rfWen;
  assign io_toExus_int_3_0_bits_loadDependency_0 = io_fromDataPath_int_3_0_bits_loadDependency_0;
  assign io_toExus_int_3_0_bits_loadDependency_1 = io_fromDataPath_int_3_0_bits_loadDependency_1;
  assign io_toExus_int_3_0_bits_loadDependency_2 = io_fromDataPath_int_3_0_bits_loadDependency_2;
  assign io_toExus_int_3_0_bits_perfDebugInfo_eliminatedMove = io_fromDataPath_int_3_0_bits_perfDebugInfo_eliminatedMove;
  assign io_toExus_int_3_0_bits_perfDebugInfo_renameTime = io_fromDataPath_int_3_0_bits_perfDebugInfo_renameTime;
  assign io_toExus_int_3_0_bits_perfDebugInfo_dispatchTime = io_fromDataPath_int_3_0_bits_perfDebugInfo_dispatchTime;
  assign io_toExus_int_3_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_int_3_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_int_3_0_bits_perfDebugInfo_selectTime = io_fromDataPath_int_3_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_int_3_0_bits_perfDebugInfo_issueTime = io_fromDataPath_int_3_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_int_3_0_bits_perfDebugInfo_writebackTime = io_fromDataPath_int_3_0_bits_perfDebugInfo_writebackTime;
  assign io_toExus_int_3_0_bits_perfDebugInfo_runahead_checkpoint_id = io_fromDataPath_int_3_0_bits_perfDebugInfo_runahead_checkpoint_id;
  assign io_toExus_int_3_0_bits_perfDebugInfo_tlbFirstReqTime = io_fromDataPath_int_3_0_bits_perfDebugInfo_tlbFirstReqTime;
  assign io_toExus_int_3_0_bits_perfDebugInfo_tlbRespTime = io_fromDataPath_int_3_0_bits_perfDebugInfo_tlbRespTime;
  assign io_toExus_int_3_0_bits_debug_seqNum_seqNum = io_fromDataPath_int_3_0_bits_debug_seqNum_seqNum;
  assign io_toExus_int_3_0_bits_debug_seqNum_uopIdx = io_fromDataPath_int_3_0_bits_debug_seqNum_uopIdx;
  assign io_toExus_int_2_1_valid = io_fromDataPath_int_2_1_valid;
  assign io_toExus_int_2_1_bits_fuType = io_fromDataPath_int_2_1_bits_fuType;
  assign io_toExus_int_2_1_bits_fuOpType = io_fromDataPath_int_2_1_bits_fuOpType;
  assign io_toExus_int_2_1_bits_robIdx_flag = io_fromDataPath_int_2_1_bits_robIdx_flag;
  assign io_toExus_int_2_1_bits_robIdx_value = io_fromDataPath_int_2_1_bits_robIdx_value;
  assign io_toExus_int_2_1_bits_pdest = io_fromDataPath_int_2_1_bits_pdest;
  assign io_toExus_int_2_1_bits_rfWen = io_fromDataPath_int_2_1_bits_rfWen;
  assign io_toExus_int_2_1_bits_fpWen = io_fromDataPath_int_2_1_bits_fpWen;
  assign io_toExus_int_2_1_bits_vecWen = io_fromDataPath_int_2_1_bits_vecWen;
  assign io_toExus_int_2_1_bits_v0Wen = io_fromDataPath_int_2_1_bits_v0Wen;
  assign io_toExus_int_2_1_bits_vlWen = io_fromDataPath_int_2_1_bits_vlWen;
  assign io_toExus_int_2_1_bits_fpu_typeTagOut = io_fromDataPath_int_2_1_bits_fpu_typeTagOut;
  assign io_toExus_int_2_1_bits_fpu_wflags = io_fromDataPath_int_2_1_bits_fpu_wflags;
  assign io_toExus_int_2_1_bits_fpu_typ = io_fromDataPath_int_2_1_bits_fpu_typ;
  assign io_toExus_int_2_1_bits_fpu_rm = io_fromDataPath_int_2_1_bits_fpu_rm;
  assign io_toExus_int_2_1_bits_pc = io_fromDataPath_int_2_1_bits_pc;
  assign io_toExus_int_2_1_bits_preDecode_valid = io_fromDataPath_int_2_1_bits_preDecode_valid;
  assign io_toExus_int_2_1_bits_preDecode_isRVC = io_fromDataPath_int_2_1_bits_preDecode_isRVC;
  assign io_toExus_int_2_1_bits_preDecode_brType = io_fromDataPath_int_2_1_bits_preDecode_brType;
  assign io_toExus_int_2_1_bits_preDecode_isCall = io_fromDataPath_int_2_1_bits_preDecode_isCall;
  assign io_toExus_int_2_1_bits_preDecode_isRet = io_fromDataPath_int_2_1_bits_preDecode_isRet;
  assign io_toExus_int_2_1_bits_ftqIdx_flag = io_fromDataPath_int_2_1_bits_ftqIdx_flag;
  assign io_toExus_int_2_1_bits_ftqIdx_value = io_fromDataPath_int_2_1_bits_ftqIdx_value;
  assign io_toExus_int_2_1_bits_ftqOffset = io_fromDataPath_int_2_1_bits_ftqOffset;
  assign io_toExus_int_2_1_bits_predictInfo_target = io_fromDataPath_int_2_1_bits_predictInfo_target;
  assign io_toExus_int_2_1_bits_predictInfo_taken = io_fromDataPath_int_2_1_bits_predictInfo_taken;
  assign io_toExus_int_2_1_bits_loadDependency_0 = io_fromDataPath_int_2_1_bits_loadDependency_0;
  assign io_toExus_int_2_1_bits_loadDependency_1 = io_fromDataPath_int_2_1_bits_loadDependency_1;
  assign io_toExus_int_2_1_bits_loadDependency_2 = io_fromDataPath_int_2_1_bits_loadDependency_2;
  assign io_toExus_int_2_1_bits_perfDebugInfo_eliminatedMove = io_fromDataPath_int_2_1_bits_perfDebugInfo_eliminatedMove;
  assign io_toExus_int_2_1_bits_perfDebugInfo_renameTime = io_fromDataPath_int_2_1_bits_perfDebugInfo_renameTime;
  assign io_toExus_int_2_1_bits_perfDebugInfo_dispatchTime = io_fromDataPath_int_2_1_bits_perfDebugInfo_dispatchTime;
  assign io_toExus_int_2_1_bits_perfDebugInfo_enqRsTime = io_fromDataPath_int_2_1_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_int_2_1_bits_perfDebugInfo_selectTime = io_fromDataPath_int_2_1_bits_perfDebugInfo_selectTime;
  assign io_toExus_int_2_1_bits_perfDebugInfo_issueTime = io_fromDataPath_int_2_1_bits_perfDebugInfo_issueTime;
  assign io_toExus_int_2_1_bits_perfDebugInfo_writebackTime = io_fromDataPath_int_2_1_bits_perfDebugInfo_writebackTime;
  assign io_toExus_int_2_1_bits_perfDebugInfo_runahead_checkpoint_id = io_fromDataPath_int_2_1_bits_perfDebugInfo_runahead_checkpoint_id;
  assign io_toExus_int_2_1_bits_perfDebugInfo_tlbFirstReqTime = io_fromDataPath_int_2_1_bits_perfDebugInfo_tlbFirstReqTime;
  assign io_toExus_int_2_1_bits_perfDebugInfo_tlbRespTime = io_fromDataPath_int_2_1_bits_perfDebugInfo_tlbRespTime;
  assign io_toExus_int_2_1_bits_debug_seqNum_seqNum = io_fromDataPath_int_2_1_bits_debug_seqNum_seqNum;
  assign io_toExus_int_2_1_bits_debug_seqNum_uopIdx = io_fromDataPath_int_2_1_bits_debug_seqNum_uopIdx;
  assign io_toExus_int_2_0_valid = io_fromDataPath_int_2_0_valid;
  assign io_toExus_int_2_0_bits_fuType = io_fromDataPath_int_2_0_bits_fuType;
  assign io_toExus_int_2_0_bits_fuOpType = io_fromDataPath_int_2_0_bits_fuOpType;
  assign io_toExus_int_2_0_bits_robIdx_flag = io_fromDataPath_int_2_0_bits_robIdx_flag;
  assign io_toExus_int_2_0_bits_robIdx_value = io_fromDataPath_int_2_0_bits_robIdx_value;
  assign io_toExus_int_2_0_bits_pdest = io_fromDataPath_int_2_0_bits_pdest;
  assign io_toExus_int_2_0_bits_rfWen = io_fromDataPath_int_2_0_bits_rfWen;
  assign io_toExus_int_2_0_bits_loadDependency_0 = io_fromDataPath_int_2_0_bits_loadDependency_0;
  assign io_toExus_int_2_0_bits_loadDependency_1 = io_fromDataPath_int_2_0_bits_loadDependency_1;
  assign io_toExus_int_2_0_bits_loadDependency_2 = io_fromDataPath_int_2_0_bits_loadDependency_2;
  assign io_toExus_int_2_0_bits_perfDebugInfo_eliminatedMove = io_fromDataPath_int_2_0_bits_perfDebugInfo_eliminatedMove;
  assign io_toExus_int_2_0_bits_perfDebugInfo_renameTime = io_fromDataPath_int_2_0_bits_perfDebugInfo_renameTime;
  assign io_toExus_int_2_0_bits_perfDebugInfo_dispatchTime = io_fromDataPath_int_2_0_bits_perfDebugInfo_dispatchTime;
  assign io_toExus_int_2_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_int_2_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_int_2_0_bits_perfDebugInfo_selectTime = io_fromDataPath_int_2_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_int_2_0_bits_perfDebugInfo_issueTime = io_fromDataPath_int_2_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_int_2_0_bits_perfDebugInfo_writebackTime = io_fromDataPath_int_2_0_bits_perfDebugInfo_writebackTime;
  assign io_toExus_int_2_0_bits_perfDebugInfo_runahead_checkpoint_id = io_fromDataPath_int_2_0_bits_perfDebugInfo_runahead_checkpoint_id;
  assign io_toExus_int_2_0_bits_perfDebugInfo_tlbFirstReqTime = io_fromDataPath_int_2_0_bits_perfDebugInfo_tlbFirstReqTime;
  assign io_toExus_int_2_0_bits_perfDebugInfo_tlbRespTime = io_fromDataPath_int_2_0_bits_perfDebugInfo_tlbRespTime;
  assign io_toExus_int_2_0_bits_debug_seqNum_seqNum = io_fromDataPath_int_2_0_bits_debug_seqNum_seqNum;
  assign io_toExus_int_2_0_bits_debug_seqNum_uopIdx = io_fromDataPath_int_2_0_bits_debug_seqNum_uopIdx;
  assign io_toExus_int_1_1_valid = io_fromDataPath_int_1_1_valid;
  assign io_toExus_int_1_1_bits_fuType = io_fromDataPath_int_1_1_bits_fuType;
  assign io_toExus_int_1_1_bits_fuOpType = io_fromDataPath_int_1_1_bits_fuOpType;
  assign io_toExus_int_1_1_bits_robIdx_flag = io_fromDataPath_int_1_1_bits_robIdx_flag;
  assign io_toExus_int_1_1_bits_robIdx_value = io_fromDataPath_int_1_1_bits_robIdx_value;
  assign io_toExus_int_1_1_bits_pdest = io_fromDataPath_int_1_1_bits_pdest;
  assign io_toExus_int_1_1_bits_rfWen = io_fromDataPath_int_1_1_bits_rfWen;
  assign io_toExus_int_1_1_bits_pc = io_fromDataPath_int_1_1_bits_pc;
  assign io_toExus_int_1_1_bits_preDecode_valid = io_fromDataPath_int_1_1_bits_preDecode_valid;
  assign io_toExus_int_1_1_bits_preDecode_isRVC = io_fromDataPath_int_1_1_bits_preDecode_isRVC;
  assign io_toExus_int_1_1_bits_preDecode_brType = io_fromDataPath_int_1_1_bits_preDecode_brType;
  assign io_toExus_int_1_1_bits_preDecode_isCall = io_fromDataPath_int_1_1_bits_preDecode_isCall;
  assign io_toExus_int_1_1_bits_preDecode_isRet = io_fromDataPath_int_1_1_bits_preDecode_isRet;
  assign io_toExus_int_1_1_bits_ftqIdx_flag = io_fromDataPath_int_1_1_bits_ftqIdx_flag;
  assign io_toExus_int_1_1_bits_ftqIdx_value = io_fromDataPath_int_1_1_bits_ftqIdx_value;
  assign io_toExus_int_1_1_bits_ftqOffset = io_fromDataPath_int_1_1_bits_ftqOffset;
  assign io_toExus_int_1_1_bits_predictInfo_target = io_fromDataPath_int_1_1_bits_predictInfo_target;
  assign io_toExus_int_1_1_bits_predictInfo_taken = io_fromDataPath_int_1_1_bits_predictInfo_taken;
  assign io_toExus_int_1_1_bits_loadDependency_0 = io_fromDataPath_int_1_1_bits_loadDependency_0;
  assign io_toExus_int_1_1_bits_loadDependency_1 = io_fromDataPath_int_1_1_bits_loadDependency_1;
  assign io_toExus_int_1_1_bits_loadDependency_2 = io_fromDataPath_int_1_1_bits_loadDependency_2;
  assign io_toExus_int_1_1_bits_perfDebugInfo_eliminatedMove = io_fromDataPath_int_1_1_bits_perfDebugInfo_eliminatedMove;
  assign io_toExus_int_1_1_bits_perfDebugInfo_renameTime = io_fromDataPath_int_1_1_bits_perfDebugInfo_renameTime;
  assign io_toExus_int_1_1_bits_perfDebugInfo_dispatchTime = io_fromDataPath_int_1_1_bits_perfDebugInfo_dispatchTime;
  assign io_toExus_int_1_1_bits_perfDebugInfo_enqRsTime = io_fromDataPath_int_1_1_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_int_1_1_bits_perfDebugInfo_selectTime = io_fromDataPath_int_1_1_bits_perfDebugInfo_selectTime;
  assign io_toExus_int_1_1_bits_perfDebugInfo_issueTime = io_fromDataPath_int_1_1_bits_perfDebugInfo_issueTime;
  assign io_toExus_int_1_1_bits_perfDebugInfo_writebackTime = io_fromDataPath_int_1_1_bits_perfDebugInfo_writebackTime;
  assign io_toExus_int_1_1_bits_perfDebugInfo_runahead_checkpoint_id = io_fromDataPath_int_1_1_bits_perfDebugInfo_runahead_checkpoint_id;
  assign io_toExus_int_1_1_bits_perfDebugInfo_tlbFirstReqTime = io_fromDataPath_int_1_1_bits_perfDebugInfo_tlbFirstReqTime;
  assign io_toExus_int_1_1_bits_perfDebugInfo_tlbRespTime = io_fromDataPath_int_1_1_bits_perfDebugInfo_tlbRespTime;
  assign io_toExus_int_1_1_bits_debug_seqNum_seqNum = io_fromDataPath_int_1_1_bits_debug_seqNum_seqNum;
  assign io_toExus_int_1_1_bits_debug_seqNum_uopIdx = io_fromDataPath_int_1_1_bits_debug_seqNum_uopIdx;
  assign io_toExus_int_1_0_valid = io_fromDataPath_int_1_0_valid;
  assign io_toExus_int_1_0_bits_fuType = io_fromDataPath_int_1_0_bits_fuType;
  assign io_toExus_int_1_0_bits_fuOpType = io_fromDataPath_int_1_0_bits_fuOpType;
  assign io_toExus_int_1_0_bits_robIdx_flag = io_fromDataPath_int_1_0_bits_robIdx_flag;
  assign io_toExus_int_1_0_bits_robIdx_value = io_fromDataPath_int_1_0_bits_robIdx_value;
  assign io_toExus_int_1_0_bits_pdest = io_fromDataPath_int_1_0_bits_pdest;
  assign io_toExus_int_1_0_bits_rfWen = io_fromDataPath_int_1_0_bits_rfWen;
  assign io_toExus_int_1_0_bits_loadDependency_0 = io_fromDataPath_int_1_0_bits_loadDependency_0;
  assign io_toExus_int_1_0_bits_loadDependency_1 = io_fromDataPath_int_1_0_bits_loadDependency_1;
  assign io_toExus_int_1_0_bits_loadDependency_2 = io_fromDataPath_int_1_0_bits_loadDependency_2;
  assign io_toExus_int_1_0_bits_perfDebugInfo_eliminatedMove = io_fromDataPath_int_1_0_bits_perfDebugInfo_eliminatedMove;
  assign io_toExus_int_1_0_bits_perfDebugInfo_renameTime = io_fromDataPath_int_1_0_bits_perfDebugInfo_renameTime;
  assign io_toExus_int_1_0_bits_perfDebugInfo_dispatchTime = io_fromDataPath_int_1_0_bits_perfDebugInfo_dispatchTime;
  assign io_toExus_int_1_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_int_1_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_int_1_0_bits_perfDebugInfo_selectTime = io_fromDataPath_int_1_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_int_1_0_bits_perfDebugInfo_issueTime = io_fromDataPath_int_1_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_int_1_0_bits_perfDebugInfo_writebackTime = io_fromDataPath_int_1_0_bits_perfDebugInfo_writebackTime;
  assign io_toExus_int_1_0_bits_perfDebugInfo_runahead_checkpoint_id = io_fromDataPath_int_1_0_bits_perfDebugInfo_runahead_checkpoint_id;
  assign io_toExus_int_1_0_bits_perfDebugInfo_tlbFirstReqTime = io_fromDataPath_int_1_0_bits_perfDebugInfo_tlbFirstReqTime;
  assign io_toExus_int_1_0_bits_perfDebugInfo_tlbRespTime = io_fromDataPath_int_1_0_bits_perfDebugInfo_tlbRespTime;
  assign io_toExus_int_1_0_bits_debug_seqNum_seqNum = io_fromDataPath_int_1_0_bits_debug_seqNum_seqNum;
  assign io_toExus_int_1_0_bits_debug_seqNum_uopIdx = io_fromDataPath_int_1_0_bits_debug_seqNum_uopIdx;
  assign io_toExus_int_0_1_valid = io_fromDataPath_int_0_1_valid;
  assign io_toExus_int_0_1_bits_fuType = io_fromDataPath_int_0_1_bits_fuType;
  assign io_toExus_int_0_1_bits_fuOpType = io_fromDataPath_int_0_1_bits_fuOpType;
  assign io_toExus_int_0_1_bits_robIdx_flag = io_fromDataPath_int_0_1_bits_robIdx_flag;
  assign io_toExus_int_0_1_bits_robIdx_value = io_fromDataPath_int_0_1_bits_robIdx_value;
  assign io_toExus_int_0_1_bits_pdest = io_fromDataPath_int_0_1_bits_pdest;
  assign io_toExus_int_0_1_bits_rfWen = io_fromDataPath_int_0_1_bits_rfWen;
  assign io_toExus_int_0_1_bits_pc = io_fromDataPath_int_0_1_bits_pc;
  assign io_toExus_int_0_1_bits_preDecode_valid = io_fromDataPath_int_0_1_bits_preDecode_valid;
  assign io_toExus_int_0_1_bits_preDecode_isRVC = io_fromDataPath_int_0_1_bits_preDecode_isRVC;
  assign io_toExus_int_0_1_bits_preDecode_brType = io_fromDataPath_int_0_1_bits_preDecode_brType;
  assign io_toExus_int_0_1_bits_preDecode_isCall = io_fromDataPath_int_0_1_bits_preDecode_isCall;
  assign io_toExus_int_0_1_bits_preDecode_isRet = io_fromDataPath_int_0_1_bits_preDecode_isRet;
  assign io_toExus_int_0_1_bits_ftqIdx_flag = io_fromDataPath_int_0_1_bits_ftqIdx_flag;
  assign io_toExus_int_0_1_bits_ftqIdx_value = io_fromDataPath_int_0_1_bits_ftqIdx_value;
  assign io_toExus_int_0_1_bits_ftqOffset = io_fromDataPath_int_0_1_bits_ftqOffset;
  assign io_toExus_int_0_1_bits_predictInfo_target = io_fromDataPath_int_0_1_bits_predictInfo_target;
  assign io_toExus_int_0_1_bits_predictInfo_taken = io_fromDataPath_int_0_1_bits_predictInfo_taken;
  assign io_toExus_int_0_1_bits_loadDependency_0 = io_fromDataPath_int_0_1_bits_loadDependency_0;
  assign io_toExus_int_0_1_bits_loadDependency_1 = io_fromDataPath_int_0_1_bits_loadDependency_1;
  assign io_toExus_int_0_1_bits_loadDependency_2 = io_fromDataPath_int_0_1_bits_loadDependency_2;
  assign io_toExus_int_0_1_bits_perfDebugInfo_eliminatedMove = io_fromDataPath_int_0_1_bits_perfDebugInfo_eliminatedMove;
  assign io_toExus_int_0_1_bits_perfDebugInfo_renameTime = io_fromDataPath_int_0_1_bits_perfDebugInfo_renameTime;
  assign io_toExus_int_0_1_bits_perfDebugInfo_dispatchTime = io_fromDataPath_int_0_1_bits_perfDebugInfo_dispatchTime;
  assign io_toExus_int_0_1_bits_perfDebugInfo_enqRsTime = io_fromDataPath_int_0_1_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_int_0_1_bits_perfDebugInfo_selectTime = io_fromDataPath_int_0_1_bits_perfDebugInfo_selectTime;
  assign io_toExus_int_0_1_bits_perfDebugInfo_issueTime = io_fromDataPath_int_0_1_bits_perfDebugInfo_issueTime;
  assign io_toExus_int_0_1_bits_perfDebugInfo_writebackTime = io_fromDataPath_int_0_1_bits_perfDebugInfo_writebackTime;
  assign io_toExus_int_0_1_bits_perfDebugInfo_runahead_checkpoint_id = io_fromDataPath_int_0_1_bits_perfDebugInfo_runahead_checkpoint_id;
  assign io_toExus_int_0_1_bits_perfDebugInfo_tlbFirstReqTime = io_fromDataPath_int_0_1_bits_perfDebugInfo_tlbFirstReqTime;
  assign io_toExus_int_0_1_bits_perfDebugInfo_tlbRespTime = io_fromDataPath_int_0_1_bits_perfDebugInfo_tlbRespTime;
  assign io_toExus_int_0_1_bits_debug_seqNum_seqNum = io_fromDataPath_int_0_1_bits_debug_seqNum_seqNum;
  assign io_toExus_int_0_1_bits_debug_seqNum_uopIdx = io_fromDataPath_int_0_1_bits_debug_seqNum_uopIdx;
  assign io_toExus_int_0_0_valid = io_fromDataPath_int_0_0_valid;
  assign io_toExus_int_0_0_bits_fuType = io_fromDataPath_int_0_0_bits_fuType;
  assign io_toExus_int_0_0_bits_fuOpType = io_fromDataPath_int_0_0_bits_fuOpType;
  assign io_toExus_int_0_0_bits_robIdx_flag = io_fromDataPath_int_0_0_bits_robIdx_flag;
  assign io_toExus_int_0_0_bits_robIdx_value = io_fromDataPath_int_0_0_bits_robIdx_value;
  assign io_toExus_int_0_0_bits_pdest = io_fromDataPath_int_0_0_bits_pdest;
  assign io_toExus_int_0_0_bits_rfWen = io_fromDataPath_int_0_0_bits_rfWen;
  assign io_toExus_int_0_0_bits_loadDependency_0 = io_fromDataPath_int_0_0_bits_loadDependency_0;
  assign io_toExus_int_0_0_bits_loadDependency_1 = io_fromDataPath_int_0_0_bits_loadDependency_1;
  assign io_toExus_int_0_0_bits_loadDependency_2 = io_fromDataPath_int_0_0_bits_loadDependency_2;
  assign io_toExus_int_0_0_bits_perfDebugInfo_eliminatedMove = io_fromDataPath_int_0_0_bits_perfDebugInfo_eliminatedMove;
  assign io_toExus_int_0_0_bits_perfDebugInfo_renameTime = io_fromDataPath_int_0_0_bits_perfDebugInfo_renameTime;
  assign io_toExus_int_0_0_bits_perfDebugInfo_dispatchTime = io_fromDataPath_int_0_0_bits_perfDebugInfo_dispatchTime;
  assign io_toExus_int_0_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_int_0_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_int_0_0_bits_perfDebugInfo_selectTime = io_fromDataPath_int_0_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_int_0_0_bits_perfDebugInfo_issueTime = io_fromDataPath_int_0_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_int_0_0_bits_perfDebugInfo_writebackTime = io_fromDataPath_int_0_0_bits_perfDebugInfo_writebackTime;
  assign io_toExus_int_0_0_bits_perfDebugInfo_runahead_checkpoint_id = io_fromDataPath_int_0_0_bits_perfDebugInfo_runahead_checkpoint_id;
  assign io_toExus_int_0_0_bits_perfDebugInfo_tlbFirstReqTime = io_fromDataPath_int_0_0_bits_perfDebugInfo_tlbFirstReqTime;
  assign io_toExus_int_0_0_bits_perfDebugInfo_tlbRespTime = io_fromDataPath_int_0_0_bits_perfDebugInfo_tlbRespTime;
  assign io_toExus_int_0_0_bits_debug_seqNum_seqNum = io_fromDataPath_int_0_0_bits_debug_seqNum_seqNum;
  assign io_toExus_int_0_0_bits_debug_seqNum_uopIdx = io_fromDataPath_int_0_0_bits_debug_seqNum_uopIdx;
  assign io_toExus_fp_2_0_valid = io_fromDataPath_fp_2_0_valid;
  assign io_toExus_fp_2_0_bits_fuType = io_fromDataPath_fp_2_0_bits_fuType;
  assign io_toExus_fp_2_0_bits_fuOpType = io_fromDataPath_fp_2_0_bits_fuOpType;
  assign io_toExus_fp_2_0_bits_robIdx_flag = io_fromDataPath_fp_2_0_bits_robIdx_flag;
  assign io_toExus_fp_2_0_bits_robIdx_value = io_fromDataPath_fp_2_0_bits_robIdx_value;
  assign io_toExus_fp_2_0_bits_pdest = io_fromDataPath_fp_2_0_bits_pdest;
  assign io_toExus_fp_2_0_bits_rfWen = io_fromDataPath_fp_2_0_bits_rfWen;
  assign io_toExus_fp_2_0_bits_fpWen = io_fromDataPath_fp_2_0_bits_fpWen;
  assign io_toExus_fp_2_0_bits_fpu_wflags = io_fromDataPath_fp_2_0_bits_fpu_wflags;
  assign io_toExus_fp_2_0_bits_fpu_fmt = io_fromDataPath_fp_2_0_bits_fpu_fmt;
  assign io_toExus_fp_2_0_bits_fpu_rm = io_fromDataPath_fp_2_0_bits_fpu_rm;
  assign io_toExus_fp_2_0_bits_perfDebugInfo_eliminatedMove = io_fromDataPath_fp_2_0_bits_perfDebugInfo_eliminatedMove;
  assign io_toExus_fp_2_0_bits_perfDebugInfo_renameTime = io_fromDataPath_fp_2_0_bits_perfDebugInfo_renameTime;
  assign io_toExus_fp_2_0_bits_perfDebugInfo_dispatchTime = io_fromDataPath_fp_2_0_bits_perfDebugInfo_dispatchTime;
  assign io_toExus_fp_2_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_fp_2_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_fp_2_0_bits_perfDebugInfo_selectTime = io_fromDataPath_fp_2_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_fp_2_0_bits_perfDebugInfo_issueTime = io_fromDataPath_fp_2_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_fp_2_0_bits_perfDebugInfo_writebackTime = io_fromDataPath_fp_2_0_bits_perfDebugInfo_writebackTime;
  assign io_toExus_fp_2_0_bits_perfDebugInfo_runahead_checkpoint_id = io_fromDataPath_fp_2_0_bits_perfDebugInfo_runahead_checkpoint_id;
  assign io_toExus_fp_2_0_bits_perfDebugInfo_tlbFirstReqTime = io_fromDataPath_fp_2_0_bits_perfDebugInfo_tlbFirstReqTime;
  assign io_toExus_fp_2_0_bits_perfDebugInfo_tlbRespTime = io_fromDataPath_fp_2_0_bits_perfDebugInfo_tlbRespTime;
  assign io_toExus_fp_2_0_bits_debug_seqNum_seqNum = io_fromDataPath_fp_2_0_bits_debug_seqNum_seqNum;
  assign io_toExus_fp_2_0_bits_debug_seqNum_uopIdx = io_fromDataPath_fp_2_0_bits_debug_seqNum_uopIdx;
  assign io_toExus_fp_1_1_valid = io_fromDataPath_fp_1_1_valid;
  assign io_toExus_fp_1_1_bits_fuType = io_fromDataPath_fp_1_1_bits_fuType;
  assign io_toExus_fp_1_1_bits_fuOpType = io_fromDataPath_fp_1_1_bits_fuOpType;
  assign io_toExus_fp_1_1_bits_robIdx_flag = io_fromDataPath_fp_1_1_bits_robIdx_flag;
  assign io_toExus_fp_1_1_bits_robIdx_value = io_fromDataPath_fp_1_1_bits_robIdx_value;
  assign io_toExus_fp_1_1_bits_pdest = io_fromDataPath_fp_1_1_bits_pdest;
  assign io_toExus_fp_1_1_bits_fpWen = io_fromDataPath_fp_1_1_bits_fpWen;
  assign io_toExus_fp_1_1_bits_fpu_wflags = io_fromDataPath_fp_1_1_bits_fpu_wflags;
  assign io_toExus_fp_1_1_bits_fpu_fmt = io_fromDataPath_fp_1_1_bits_fpu_fmt;
  assign io_toExus_fp_1_1_bits_fpu_rm = io_fromDataPath_fp_1_1_bits_fpu_rm;
  assign io_toExus_fp_1_1_bits_perfDebugInfo_eliminatedMove = io_fromDataPath_fp_1_1_bits_perfDebugInfo_eliminatedMove;
  assign io_toExus_fp_1_1_bits_perfDebugInfo_renameTime = io_fromDataPath_fp_1_1_bits_perfDebugInfo_renameTime;
  assign io_toExus_fp_1_1_bits_perfDebugInfo_dispatchTime = io_fromDataPath_fp_1_1_bits_perfDebugInfo_dispatchTime;
  assign io_toExus_fp_1_1_bits_perfDebugInfo_enqRsTime = io_fromDataPath_fp_1_1_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_fp_1_1_bits_perfDebugInfo_selectTime = io_fromDataPath_fp_1_1_bits_perfDebugInfo_selectTime;
  assign io_toExus_fp_1_1_bits_perfDebugInfo_issueTime = io_fromDataPath_fp_1_1_bits_perfDebugInfo_issueTime;
  assign io_toExus_fp_1_1_bits_perfDebugInfo_writebackTime = io_fromDataPath_fp_1_1_bits_perfDebugInfo_writebackTime;
  assign io_toExus_fp_1_1_bits_perfDebugInfo_runahead_checkpoint_id = io_fromDataPath_fp_1_1_bits_perfDebugInfo_runahead_checkpoint_id;
  assign io_toExus_fp_1_1_bits_perfDebugInfo_tlbFirstReqTime = io_fromDataPath_fp_1_1_bits_perfDebugInfo_tlbFirstReqTime;
  assign io_toExus_fp_1_1_bits_perfDebugInfo_tlbRespTime = io_fromDataPath_fp_1_1_bits_perfDebugInfo_tlbRespTime;
  assign io_toExus_fp_1_1_bits_debug_seqNum_seqNum = io_fromDataPath_fp_1_1_bits_debug_seqNum_seqNum;
  assign io_toExus_fp_1_1_bits_debug_seqNum_uopIdx = io_fromDataPath_fp_1_1_bits_debug_seqNum_uopIdx;
  assign io_toExus_fp_1_0_valid = io_fromDataPath_fp_1_0_valid;
  assign io_toExus_fp_1_0_bits_fuType = io_fromDataPath_fp_1_0_bits_fuType;
  assign io_toExus_fp_1_0_bits_fuOpType = io_fromDataPath_fp_1_0_bits_fuOpType;
  assign io_toExus_fp_1_0_bits_robIdx_flag = io_fromDataPath_fp_1_0_bits_robIdx_flag;
  assign io_toExus_fp_1_0_bits_robIdx_value = io_fromDataPath_fp_1_0_bits_robIdx_value;
  assign io_toExus_fp_1_0_bits_pdest = io_fromDataPath_fp_1_0_bits_pdest;
  assign io_toExus_fp_1_0_bits_rfWen = io_fromDataPath_fp_1_0_bits_rfWen;
  assign io_toExus_fp_1_0_bits_fpWen = io_fromDataPath_fp_1_0_bits_fpWen;
  assign io_toExus_fp_1_0_bits_fpu_wflags = io_fromDataPath_fp_1_0_bits_fpu_wflags;
  assign io_toExus_fp_1_0_bits_fpu_fmt = io_fromDataPath_fp_1_0_bits_fpu_fmt;
  assign io_toExus_fp_1_0_bits_fpu_rm = io_fromDataPath_fp_1_0_bits_fpu_rm;
  assign io_toExus_fp_1_0_bits_perfDebugInfo_eliminatedMove = io_fromDataPath_fp_1_0_bits_perfDebugInfo_eliminatedMove;
  assign io_toExus_fp_1_0_bits_perfDebugInfo_renameTime = io_fromDataPath_fp_1_0_bits_perfDebugInfo_renameTime;
  assign io_toExus_fp_1_0_bits_perfDebugInfo_dispatchTime = io_fromDataPath_fp_1_0_bits_perfDebugInfo_dispatchTime;
  assign io_toExus_fp_1_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_fp_1_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_fp_1_0_bits_perfDebugInfo_selectTime = io_fromDataPath_fp_1_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_fp_1_0_bits_perfDebugInfo_issueTime = io_fromDataPath_fp_1_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_fp_1_0_bits_perfDebugInfo_writebackTime = io_fromDataPath_fp_1_0_bits_perfDebugInfo_writebackTime;
  assign io_toExus_fp_1_0_bits_perfDebugInfo_runahead_checkpoint_id = io_fromDataPath_fp_1_0_bits_perfDebugInfo_runahead_checkpoint_id;
  assign io_toExus_fp_1_0_bits_perfDebugInfo_tlbFirstReqTime = io_fromDataPath_fp_1_0_bits_perfDebugInfo_tlbFirstReqTime;
  assign io_toExus_fp_1_0_bits_perfDebugInfo_tlbRespTime = io_fromDataPath_fp_1_0_bits_perfDebugInfo_tlbRespTime;
  assign io_toExus_fp_1_0_bits_debug_seqNum_seqNum = io_fromDataPath_fp_1_0_bits_debug_seqNum_seqNum;
  assign io_toExus_fp_1_0_bits_debug_seqNum_uopIdx = io_fromDataPath_fp_1_0_bits_debug_seqNum_uopIdx;
  assign io_toExus_fp_0_1_valid = io_fromDataPath_fp_0_1_valid;
  assign io_toExus_fp_0_1_bits_fuType = io_fromDataPath_fp_0_1_bits_fuType;
  assign io_toExus_fp_0_1_bits_fuOpType = io_fromDataPath_fp_0_1_bits_fuOpType;
  assign io_toExus_fp_0_1_bits_robIdx_flag = io_fromDataPath_fp_0_1_bits_robIdx_flag;
  assign io_toExus_fp_0_1_bits_robIdx_value = io_fromDataPath_fp_0_1_bits_robIdx_value;
  assign io_toExus_fp_0_1_bits_pdest = io_fromDataPath_fp_0_1_bits_pdest;
  assign io_toExus_fp_0_1_bits_fpWen = io_fromDataPath_fp_0_1_bits_fpWen;
  assign io_toExus_fp_0_1_bits_fpu_wflags = io_fromDataPath_fp_0_1_bits_fpu_wflags;
  assign io_toExus_fp_0_1_bits_fpu_fmt = io_fromDataPath_fp_0_1_bits_fpu_fmt;
  assign io_toExus_fp_0_1_bits_fpu_rm = io_fromDataPath_fp_0_1_bits_fpu_rm;
  assign io_toExus_fp_0_1_bits_perfDebugInfo_eliminatedMove = io_fromDataPath_fp_0_1_bits_perfDebugInfo_eliminatedMove;
  assign io_toExus_fp_0_1_bits_perfDebugInfo_renameTime = io_fromDataPath_fp_0_1_bits_perfDebugInfo_renameTime;
  assign io_toExus_fp_0_1_bits_perfDebugInfo_dispatchTime = io_fromDataPath_fp_0_1_bits_perfDebugInfo_dispatchTime;
  assign io_toExus_fp_0_1_bits_perfDebugInfo_enqRsTime = io_fromDataPath_fp_0_1_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_fp_0_1_bits_perfDebugInfo_selectTime = io_fromDataPath_fp_0_1_bits_perfDebugInfo_selectTime;
  assign io_toExus_fp_0_1_bits_perfDebugInfo_issueTime = io_fromDataPath_fp_0_1_bits_perfDebugInfo_issueTime;
  assign io_toExus_fp_0_1_bits_perfDebugInfo_writebackTime = io_fromDataPath_fp_0_1_bits_perfDebugInfo_writebackTime;
  assign io_toExus_fp_0_1_bits_perfDebugInfo_runahead_checkpoint_id = io_fromDataPath_fp_0_1_bits_perfDebugInfo_runahead_checkpoint_id;
  assign io_toExus_fp_0_1_bits_perfDebugInfo_tlbFirstReqTime = io_fromDataPath_fp_0_1_bits_perfDebugInfo_tlbFirstReqTime;
  assign io_toExus_fp_0_1_bits_perfDebugInfo_tlbRespTime = io_fromDataPath_fp_0_1_bits_perfDebugInfo_tlbRespTime;
  assign io_toExus_fp_0_1_bits_debug_seqNum_seqNum = io_fromDataPath_fp_0_1_bits_debug_seqNum_seqNum;
  assign io_toExus_fp_0_1_bits_debug_seqNum_uopIdx = io_fromDataPath_fp_0_1_bits_debug_seqNum_uopIdx;
  assign io_toExus_fp_0_0_valid = io_fromDataPath_fp_0_0_valid;
  assign io_toExus_fp_0_0_bits_fuType = io_fromDataPath_fp_0_0_bits_fuType;
  assign io_toExus_fp_0_0_bits_fuOpType = io_fromDataPath_fp_0_0_bits_fuOpType;
  assign io_toExus_fp_0_0_bits_robIdx_flag = io_fromDataPath_fp_0_0_bits_robIdx_flag;
  assign io_toExus_fp_0_0_bits_robIdx_value = io_fromDataPath_fp_0_0_bits_robIdx_value;
  assign io_toExus_fp_0_0_bits_pdest = io_fromDataPath_fp_0_0_bits_pdest;
  assign io_toExus_fp_0_0_bits_rfWen = io_fromDataPath_fp_0_0_bits_rfWen;
  assign io_toExus_fp_0_0_bits_fpWen = io_fromDataPath_fp_0_0_bits_fpWen;
  assign io_toExus_fp_0_0_bits_vecWen = io_fromDataPath_fp_0_0_bits_vecWen;
  assign io_toExus_fp_0_0_bits_v0Wen = io_fromDataPath_fp_0_0_bits_v0Wen;
  assign io_toExus_fp_0_0_bits_fpu_wflags = io_fromDataPath_fp_0_0_bits_fpu_wflags;
  assign io_toExus_fp_0_0_bits_fpu_fmt = io_fromDataPath_fp_0_0_bits_fpu_fmt;
  assign io_toExus_fp_0_0_bits_fpu_rm = io_fromDataPath_fp_0_0_bits_fpu_rm;
  assign io_toExus_fp_0_0_bits_perfDebugInfo_eliminatedMove = io_fromDataPath_fp_0_0_bits_perfDebugInfo_eliminatedMove;
  assign io_toExus_fp_0_0_bits_perfDebugInfo_renameTime = io_fromDataPath_fp_0_0_bits_perfDebugInfo_renameTime;
  assign io_toExus_fp_0_0_bits_perfDebugInfo_dispatchTime = io_fromDataPath_fp_0_0_bits_perfDebugInfo_dispatchTime;
  assign io_toExus_fp_0_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_fp_0_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_fp_0_0_bits_perfDebugInfo_selectTime = io_fromDataPath_fp_0_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_fp_0_0_bits_perfDebugInfo_issueTime = io_fromDataPath_fp_0_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_fp_0_0_bits_perfDebugInfo_writebackTime = io_fromDataPath_fp_0_0_bits_perfDebugInfo_writebackTime;
  assign io_toExus_fp_0_0_bits_perfDebugInfo_runahead_checkpoint_id = io_fromDataPath_fp_0_0_bits_perfDebugInfo_runahead_checkpoint_id;
  assign io_toExus_fp_0_0_bits_perfDebugInfo_tlbFirstReqTime = io_fromDataPath_fp_0_0_bits_perfDebugInfo_tlbFirstReqTime;
  assign io_toExus_fp_0_0_bits_perfDebugInfo_tlbRespTime = io_fromDataPath_fp_0_0_bits_perfDebugInfo_tlbRespTime;
  assign io_toExus_fp_0_0_bits_debug_seqNum_seqNum = io_fromDataPath_fp_0_0_bits_debug_seqNum_seqNum;
  assign io_toExus_fp_0_0_bits_debug_seqNum_uopIdx = io_fromDataPath_fp_0_0_bits_debug_seqNum_uopIdx;
  assign io_toExus_vf_2_0_valid = io_fromDataPath_vf_2_0_valid;
  assign io_toExus_vf_2_0_bits_fuType = io_fromDataPath_vf_2_0_bits_fuType;
  assign io_toExus_vf_2_0_bits_fuOpType = io_fromDataPath_vf_2_0_bits_fuOpType;
  assign io_toExus_vf_2_0_bits_robIdx_flag = io_fromDataPath_vf_2_0_bits_robIdx_flag;
  assign io_toExus_vf_2_0_bits_robIdx_value = io_fromDataPath_vf_2_0_bits_robIdx_value;
  assign io_toExus_vf_2_0_bits_pdest = io_fromDataPath_vf_2_0_bits_pdest;
  assign io_toExus_vf_2_0_bits_vecWen = io_fromDataPath_vf_2_0_bits_vecWen;
  assign io_toExus_vf_2_0_bits_v0Wen = io_fromDataPath_vf_2_0_bits_v0Wen;
  assign io_toExus_vf_2_0_bits_fpu_wflags = io_fromDataPath_vf_2_0_bits_fpu_wflags;
  assign io_toExus_vf_2_0_bits_vpu_vma = io_fromDataPath_vf_2_0_bits_vpu_vma;
  assign io_toExus_vf_2_0_bits_vpu_vta = io_fromDataPath_vf_2_0_bits_vpu_vta;
  assign io_toExus_vf_2_0_bits_vpu_vsew = io_fromDataPath_vf_2_0_bits_vpu_vsew;
  assign io_toExus_vf_2_0_bits_vpu_vlmul = io_fromDataPath_vf_2_0_bits_vpu_vlmul;
  assign io_toExus_vf_2_0_bits_vpu_vm = io_fromDataPath_vf_2_0_bits_vpu_vm;
  assign io_toExus_vf_2_0_bits_vpu_vstart = io_fromDataPath_vf_2_0_bits_vpu_vstart;
  assign io_toExus_vf_2_0_bits_vpu_vuopIdx = io_fromDataPath_vf_2_0_bits_vpu_vuopIdx;
  assign io_toExus_vf_2_0_bits_vpu_isExt = io_fromDataPath_vf_2_0_bits_vpu_isExt;
  assign io_toExus_vf_2_0_bits_vpu_isNarrow = io_fromDataPath_vf_2_0_bits_vpu_isNarrow;
  assign io_toExus_vf_2_0_bits_vpu_isDstMask = io_fromDataPath_vf_2_0_bits_vpu_isDstMask;
  assign io_toExus_vf_2_0_bits_vpu_isOpMask = io_fromDataPath_vf_2_0_bits_vpu_isOpMask;
  assign io_toExus_vf_2_0_bits_perfDebugInfo_eliminatedMove = io_fromDataPath_vf_2_0_bits_perfDebugInfo_eliminatedMove;
  assign io_toExus_vf_2_0_bits_perfDebugInfo_renameTime = io_fromDataPath_vf_2_0_bits_perfDebugInfo_renameTime;
  assign io_toExus_vf_2_0_bits_perfDebugInfo_dispatchTime = io_fromDataPath_vf_2_0_bits_perfDebugInfo_dispatchTime;
  assign io_toExus_vf_2_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_vf_2_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_vf_2_0_bits_perfDebugInfo_selectTime = io_fromDataPath_vf_2_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_vf_2_0_bits_perfDebugInfo_issueTime = io_fromDataPath_vf_2_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_vf_2_0_bits_perfDebugInfo_writebackTime = io_fromDataPath_vf_2_0_bits_perfDebugInfo_writebackTime;
  assign io_toExus_vf_2_0_bits_perfDebugInfo_runahead_checkpoint_id = io_fromDataPath_vf_2_0_bits_perfDebugInfo_runahead_checkpoint_id;
  assign io_toExus_vf_2_0_bits_perfDebugInfo_tlbFirstReqTime = io_fromDataPath_vf_2_0_bits_perfDebugInfo_tlbFirstReqTime;
  assign io_toExus_vf_2_0_bits_perfDebugInfo_tlbRespTime = io_fromDataPath_vf_2_0_bits_perfDebugInfo_tlbRespTime;
  assign io_toExus_vf_2_0_bits_debug_seqNum_seqNum = io_fromDataPath_vf_2_0_bits_debug_seqNum_seqNum;
  assign io_toExus_vf_2_0_bits_debug_seqNum_uopIdx = io_fromDataPath_vf_2_0_bits_debug_seqNum_uopIdx;
  assign io_toExus_vf_1_1_valid = io_fromDataPath_vf_1_1_valid;
  assign io_toExus_vf_1_1_bits_fuType = io_fromDataPath_vf_1_1_bits_fuType;
  assign io_toExus_vf_1_1_bits_fuOpType = io_fromDataPath_vf_1_1_bits_fuOpType;
  assign io_toExus_vf_1_1_bits_robIdx_flag = io_fromDataPath_vf_1_1_bits_robIdx_flag;
  assign io_toExus_vf_1_1_bits_robIdx_value = io_fromDataPath_vf_1_1_bits_robIdx_value;
  assign io_toExus_vf_1_1_bits_pdest = io_fromDataPath_vf_1_1_bits_pdest;
  assign io_toExus_vf_1_1_bits_fpWen = io_fromDataPath_vf_1_1_bits_fpWen;
  assign io_toExus_vf_1_1_bits_vecWen = io_fromDataPath_vf_1_1_bits_vecWen;
  assign io_toExus_vf_1_1_bits_v0Wen = io_fromDataPath_vf_1_1_bits_v0Wen;
  assign io_toExus_vf_1_1_bits_fpu_wflags = io_fromDataPath_vf_1_1_bits_fpu_wflags;
  assign io_toExus_vf_1_1_bits_vpu_vma = io_fromDataPath_vf_1_1_bits_vpu_vma;
  assign io_toExus_vf_1_1_bits_vpu_vta = io_fromDataPath_vf_1_1_bits_vpu_vta;
  assign io_toExus_vf_1_1_bits_vpu_vsew = io_fromDataPath_vf_1_1_bits_vpu_vsew;
  assign io_toExus_vf_1_1_bits_vpu_vlmul = io_fromDataPath_vf_1_1_bits_vpu_vlmul;
  assign io_toExus_vf_1_1_bits_vpu_vm = io_fromDataPath_vf_1_1_bits_vpu_vm;
  assign io_toExus_vf_1_1_bits_vpu_vstart = io_fromDataPath_vf_1_1_bits_vpu_vstart;
  assign io_toExus_vf_1_1_bits_vpu_fpu_isFoldTo1_2 = io_fromDataPath_vf_1_1_bits_vpu_fpu_isFoldTo1_2;
  assign io_toExus_vf_1_1_bits_vpu_fpu_isFoldTo1_4 = io_fromDataPath_vf_1_1_bits_vpu_fpu_isFoldTo1_4;
  assign io_toExus_vf_1_1_bits_vpu_fpu_isFoldTo1_8 = io_fromDataPath_vf_1_1_bits_vpu_fpu_isFoldTo1_8;
  assign io_toExus_vf_1_1_bits_vpu_vuopIdx = io_fromDataPath_vf_1_1_bits_vpu_vuopIdx;
  assign io_toExus_vf_1_1_bits_vpu_lastUop = io_fromDataPath_vf_1_1_bits_vpu_lastUop;
  assign io_toExus_vf_1_1_bits_vpu_isNarrow = io_fromDataPath_vf_1_1_bits_vpu_isNarrow;
  assign io_toExus_vf_1_1_bits_vpu_isDstMask = io_fromDataPath_vf_1_1_bits_vpu_isDstMask;
  assign io_toExus_vf_1_1_bits_perfDebugInfo_eliminatedMove = io_fromDataPath_vf_1_1_bits_perfDebugInfo_eliminatedMove;
  assign io_toExus_vf_1_1_bits_perfDebugInfo_renameTime = io_fromDataPath_vf_1_1_bits_perfDebugInfo_renameTime;
  assign io_toExus_vf_1_1_bits_perfDebugInfo_dispatchTime = io_fromDataPath_vf_1_1_bits_perfDebugInfo_dispatchTime;
  assign io_toExus_vf_1_1_bits_perfDebugInfo_enqRsTime = io_fromDataPath_vf_1_1_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_vf_1_1_bits_perfDebugInfo_selectTime = io_fromDataPath_vf_1_1_bits_perfDebugInfo_selectTime;
  assign io_toExus_vf_1_1_bits_perfDebugInfo_issueTime = io_fromDataPath_vf_1_1_bits_perfDebugInfo_issueTime;
  assign io_toExus_vf_1_1_bits_perfDebugInfo_writebackTime = io_fromDataPath_vf_1_1_bits_perfDebugInfo_writebackTime;
  assign io_toExus_vf_1_1_bits_perfDebugInfo_runahead_checkpoint_id = io_fromDataPath_vf_1_1_bits_perfDebugInfo_runahead_checkpoint_id;
  assign io_toExus_vf_1_1_bits_perfDebugInfo_tlbFirstReqTime = io_fromDataPath_vf_1_1_bits_perfDebugInfo_tlbFirstReqTime;
  assign io_toExus_vf_1_1_bits_perfDebugInfo_tlbRespTime = io_fromDataPath_vf_1_1_bits_perfDebugInfo_tlbRespTime;
  assign io_toExus_vf_1_1_bits_debug_seqNum_seqNum = io_fromDataPath_vf_1_1_bits_debug_seqNum_seqNum;
  assign io_toExus_vf_1_1_bits_debug_seqNum_uopIdx = io_fromDataPath_vf_1_1_bits_debug_seqNum_uopIdx;
  assign io_toExus_vf_1_0_valid = io_fromDataPath_vf_1_0_valid;
  assign io_toExus_vf_1_0_bits_fuType = io_fromDataPath_vf_1_0_bits_fuType;
  assign io_toExus_vf_1_0_bits_fuOpType = io_fromDataPath_vf_1_0_bits_fuOpType;
  assign io_toExus_vf_1_0_bits_robIdx_flag = io_fromDataPath_vf_1_0_bits_robIdx_flag;
  assign io_toExus_vf_1_0_bits_robIdx_value = io_fromDataPath_vf_1_0_bits_robIdx_value;
  assign io_toExus_vf_1_0_bits_pdest = io_fromDataPath_vf_1_0_bits_pdest;
  assign io_toExus_vf_1_0_bits_vecWen = io_fromDataPath_vf_1_0_bits_vecWen;
  assign io_toExus_vf_1_0_bits_v0Wen = io_fromDataPath_vf_1_0_bits_v0Wen;
  assign io_toExus_vf_1_0_bits_fpu_wflags = io_fromDataPath_vf_1_0_bits_fpu_wflags;
  assign io_toExus_vf_1_0_bits_vpu_vma = io_fromDataPath_vf_1_0_bits_vpu_vma;
  assign io_toExus_vf_1_0_bits_vpu_vta = io_fromDataPath_vf_1_0_bits_vpu_vta;
  assign io_toExus_vf_1_0_bits_vpu_vsew = io_fromDataPath_vf_1_0_bits_vpu_vsew;
  assign io_toExus_vf_1_0_bits_vpu_vlmul = io_fromDataPath_vf_1_0_bits_vpu_vlmul;
  assign io_toExus_vf_1_0_bits_vpu_vm = io_fromDataPath_vf_1_0_bits_vpu_vm;
  assign io_toExus_vf_1_0_bits_vpu_vstart = io_fromDataPath_vf_1_0_bits_vpu_vstart;
  assign io_toExus_vf_1_0_bits_vpu_vuopIdx = io_fromDataPath_vf_1_0_bits_vpu_vuopIdx;
  assign io_toExus_vf_1_0_bits_vpu_isExt = io_fromDataPath_vf_1_0_bits_vpu_isExt;
  assign io_toExus_vf_1_0_bits_vpu_isNarrow = io_fromDataPath_vf_1_0_bits_vpu_isNarrow;
  assign io_toExus_vf_1_0_bits_vpu_isDstMask = io_fromDataPath_vf_1_0_bits_vpu_isDstMask;
  assign io_toExus_vf_1_0_bits_vpu_isOpMask = io_fromDataPath_vf_1_0_bits_vpu_isOpMask;
  assign io_toExus_vf_1_0_bits_perfDebugInfo_eliminatedMove = io_fromDataPath_vf_1_0_bits_perfDebugInfo_eliminatedMove;
  assign io_toExus_vf_1_0_bits_perfDebugInfo_renameTime = io_fromDataPath_vf_1_0_bits_perfDebugInfo_renameTime;
  assign io_toExus_vf_1_0_bits_perfDebugInfo_dispatchTime = io_fromDataPath_vf_1_0_bits_perfDebugInfo_dispatchTime;
  assign io_toExus_vf_1_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_vf_1_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_vf_1_0_bits_perfDebugInfo_selectTime = io_fromDataPath_vf_1_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_vf_1_0_bits_perfDebugInfo_issueTime = io_fromDataPath_vf_1_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_vf_1_0_bits_perfDebugInfo_writebackTime = io_fromDataPath_vf_1_0_bits_perfDebugInfo_writebackTime;
  assign io_toExus_vf_1_0_bits_perfDebugInfo_runahead_checkpoint_id = io_fromDataPath_vf_1_0_bits_perfDebugInfo_runahead_checkpoint_id;
  assign io_toExus_vf_1_0_bits_perfDebugInfo_tlbFirstReqTime = io_fromDataPath_vf_1_0_bits_perfDebugInfo_tlbFirstReqTime;
  assign io_toExus_vf_1_0_bits_perfDebugInfo_tlbRespTime = io_fromDataPath_vf_1_0_bits_perfDebugInfo_tlbRespTime;
  assign io_toExus_vf_1_0_bits_debug_seqNum_seqNum = io_fromDataPath_vf_1_0_bits_debug_seqNum_seqNum;
  assign io_toExus_vf_1_0_bits_debug_seqNum_uopIdx = io_fromDataPath_vf_1_0_bits_debug_seqNum_uopIdx;
  assign io_toExus_vf_0_1_valid = io_fromDataPath_vf_0_1_valid;
  assign io_toExus_vf_0_1_bits_fuType = io_fromDataPath_vf_0_1_bits_fuType;
  assign io_toExus_vf_0_1_bits_fuOpType = io_fromDataPath_vf_0_1_bits_fuOpType;
  assign io_toExus_vf_0_1_bits_robIdx_flag = io_fromDataPath_vf_0_1_bits_robIdx_flag;
  assign io_toExus_vf_0_1_bits_robIdx_value = io_fromDataPath_vf_0_1_bits_robIdx_value;
  assign io_toExus_vf_0_1_bits_pdest = io_fromDataPath_vf_0_1_bits_pdest;
  assign io_toExus_vf_0_1_bits_rfWen = io_fromDataPath_vf_0_1_bits_rfWen;
  assign io_toExus_vf_0_1_bits_fpWen = io_fromDataPath_vf_0_1_bits_fpWen;
  assign io_toExus_vf_0_1_bits_vecWen = io_fromDataPath_vf_0_1_bits_vecWen;
  assign io_toExus_vf_0_1_bits_v0Wen = io_fromDataPath_vf_0_1_bits_v0Wen;
  assign io_toExus_vf_0_1_bits_vlWen = io_fromDataPath_vf_0_1_bits_vlWen;
  assign io_toExus_vf_0_1_bits_fpu_wflags = io_fromDataPath_vf_0_1_bits_fpu_wflags;
  assign io_toExus_vf_0_1_bits_vpu_vma = io_fromDataPath_vf_0_1_bits_vpu_vma;
  assign io_toExus_vf_0_1_bits_vpu_vta = io_fromDataPath_vf_0_1_bits_vpu_vta;
  assign io_toExus_vf_0_1_bits_vpu_vsew = io_fromDataPath_vf_0_1_bits_vpu_vsew;
  assign io_toExus_vf_0_1_bits_vpu_vlmul = io_fromDataPath_vf_0_1_bits_vpu_vlmul;
  assign io_toExus_vf_0_1_bits_vpu_vm = io_fromDataPath_vf_0_1_bits_vpu_vm;
  assign io_toExus_vf_0_1_bits_vpu_vstart = io_fromDataPath_vf_0_1_bits_vpu_vstart;
  assign io_toExus_vf_0_1_bits_vpu_fpu_isFoldTo1_2 = io_fromDataPath_vf_0_1_bits_vpu_fpu_isFoldTo1_2;
  assign io_toExus_vf_0_1_bits_vpu_fpu_isFoldTo1_4 = io_fromDataPath_vf_0_1_bits_vpu_fpu_isFoldTo1_4;
  assign io_toExus_vf_0_1_bits_vpu_fpu_isFoldTo1_8 = io_fromDataPath_vf_0_1_bits_vpu_fpu_isFoldTo1_8;
  assign io_toExus_vf_0_1_bits_vpu_vuopIdx = io_fromDataPath_vf_0_1_bits_vpu_vuopIdx;
  assign io_toExus_vf_0_1_bits_vpu_lastUop = io_fromDataPath_vf_0_1_bits_vpu_lastUop;
  assign io_toExus_vf_0_1_bits_vpu_isNarrow = io_fromDataPath_vf_0_1_bits_vpu_isNarrow;
  assign io_toExus_vf_0_1_bits_vpu_isDstMask = io_fromDataPath_vf_0_1_bits_vpu_isDstMask;
  assign io_toExus_vf_0_1_bits_perfDebugInfo_eliminatedMove = io_fromDataPath_vf_0_1_bits_perfDebugInfo_eliminatedMove;
  assign io_toExus_vf_0_1_bits_perfDebugInfo_renameTime = io_fromDataPath_vf_0_1_bits_perfDebugInfo_renameTime;
  assign io_toExus_vf_0_1_bits_perfDebugInfo_dispatchTime = io_fromDataPath_vf_0_1_bits_perfDebugInfo_dispatchTime;
  assign io_toExus_vf_0_1_bits_perfDebugInfo_enqRsTime = io_fromDataPath_vf_0_1_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_vf_0_1_bits_perfDebugInfo_selectTime = io_fromDataPath_vf_0_1_bits_perfDebugInfo_selectTime;
  assign io_toExus_vf_0_1_bits_perfDebugInfo_issueTime = io_fromDataPath_vf_0_1_bits_perfDebugInfo_issueTime;
  assign io_toExus_vf_0_1_bits_perfDebugInfo_writebackTime = io_fromDataPath_vf_0_1_bits_perfDebugInfo_writebackTime;
  assign io_toExus_vf_0_1_bits_perfDebugInfo_runahead_checkpoint_id = io_fromDataPath_vf_0_1_bits_perfDebugInfo_runahead_checkpoint_id;
  assign io_toExus_vf_0_1_bits_perfDebugInfo_tlbFirstReqTime = io_fromDataPath_vf_0_1_bits_perfDebugInfo_tlbFirstReqTime;
  assign io_toExus_vf_0_1_bits_perfDebugInfo_tlbRespTime = io_fromDataPath_vf_0_1_bits_perfDebugInfo_tlbRespTime;
  assign io_toExus_vf_0_1_bits_debug_seqNum_seqNum = io_fromDataPath_vf_0_1_bits_debug_seqNum_seqNum;
  assign io_toExus_vf_0_1_bits_debug_seqNum_uopIdx = io_fromDataPath_vf_0_1_bits_debug_seqNum_uopIdx;
  assign io_toExus_vf_0_0_valid = io_fromDataPath_vf_0_0_valid;
  assign io_toExus_vf_0_0_bits_fuType = io_fromDataPath_vf_0_0_bits_fuType;
  assign io_toExus_vf_0_0_bits_fuOpType = io_fromDataPath_vf_0_0_bits_fuOpType;
  assign io_toExus_vf_0_0_bits_robIdx_flag = io_fromDataPath_vf_0_0_bits_robIdx_flag;
  assign io_toExus_vf_0_0_bits_robIdx_value = io_fromDataPath_vf_0_0_bits_robIdx_value;
  assign io_toExus_vf_0_0_bits_pdest = io_fromDataPath_vf_0_0_bits_pdest;
  assign io_toExus_vf_0_0_bits_vecWen = io_fromDataPath_vf_0_0_bits_vecWen;
  assign io_toExus_vf_0_0_bits_v0Wen = io_fromDataPath_vf_0_0_bits_v0Wen;
  assign io_toExus_vf_0_0_bits_fpu_wflags = io_fromDataPath_vf_0_0_bits_fpu_wflags;
  assign io_toExus_vf_0_0_bits_vpu_vma = io_fromDataPath_vf_0_0_bits_vpu_vma;
  assign io_toExus_vf_0_0_bits_vpu_vta = io_fromDataPath_vf_0_0_bits_vpu_vta;
  assign io_toExus_vf_0_0_bits_vpu_vsew = io_fromDataPath_vf_0_0_bits_vpu_vsew;
  assign io_toExus_vf_0_0_bits_vpu_vlmul = io_fromDataPath_vf_0_0_bits_vpu_vlmul;
  assign io_toExus_vf_0_0_bits_vpu_vm = io_fromDataPath_vf_0_0_bits_vpu_vm;
  assign io_toExus_vf_0_0_bits_vpu_vstart = io_fromDataPath_vf_0_0_bits_vpu_vstart;
  assign io_toExus_vf_0_0_bits_vpu_vuopIdx = io_fromDataPath_vf_0_0_bits_vpu_vuopIdx;
  assign io_toExus_vf_0_0_bits_vpu_isExt = io_fromDataPath_vf_0_0_bits_vpu_isExt;
  assign io_toExus_vf_0_0_bits_vpu_isNarrow = io_fromDataPath_vf_0_0_bits_vpu_isNarrow;
  assign io_toExus_vf_0_0_bits_vpu_isDstMask = io_fromDataPath_vf_0_0_bits_vpu_isDstMask;
  assign io_toExus_vf_0_0_bits_vpu_isOpMask = io_fromDataPath_vf_0_0_bits_vpu_isOpMask;
  assign io_toExus_vf_0_0_bits_perfDebugInfo_eliminatedMove = io_fromDataPath_vf_0_0_bits_perfDebugInfo_eliminatedMove;
  assign io_toExus_vf_0_0_bits_perfDebugInfo_renameTime = io_fromDataPath_vf_0_0_bits_perfDebugInfo_renameTime;
  assign io_toExus_vf_0_0_bits_perfDebugInfo_dispatchTime = io_fromDataPath_vf_0_0_bits_perfDebugInfo_dispatchTime;
  assign io_toExus_vf_0_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_vf_0_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_vf_0_0_bits_perfDebugInfo_selectTime = io_fromDataPath_vf_0_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_vf_0_0_bits_perfDebugInfo_issueTime = io_fromDataPath_vf_0_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_vf_0_0_bits_perfDebugInfo_writebackTime = io_fromDataPath_vf_0_0_bits_perfDebugInfo_writebackTime;
  assign io_toExus_vf_0_0_bits_perfDebugInfo_runahead_checkpoint_id = io_fromDataPath_vf_0_0_bits_perfDebugInfo_runahead_checkpoint_id;
  assign io_toExus_vf_0_0_bits_perfDebugInfo_tlbFirstReqTime = io_fromDataPath_vf_0_0_bits_perfDebugInfo_tlbFirstReqTime;
  assign io_toExus_vf_0_0_bits_perfDebugInfo_tlbRespTime = io_fromDataPath_vf_0_0_bits_perfDebugInfo_tlbRespTime;
  assign io_toExus_vf_0_0_bits_debug_seqNum_seqNum = io_fromDataPath_vf_0_0_bits_debug_seqNum_seqNum;
  assign io_toExus_vf_0_0_bits_debug_seqNum_uopIdx = io_fromDataPath_vf_0_0_bits_debug_seqNum_uopIdx;
  assign io_toExus_mem_8_0_valid = io_fromDataPath_mem_8_0_valid;
  assign io_toExus_mem_8_0_bits_fuType = io_fromDataPath_mem_8_0_bits_fuType;
  assign io_toExus_mem_8_0_bits_fuOpType = io_fromDataPath_mem_8_0_bits_fuOpType;
  assign io_toExus_mem_8_0_bits_robIdx_flag = io_fromDataPath_mem_8_0_bits_robIdx_flag;
  assign io_toExus_mem_8_0_bits_robIdx_value = io_fromDataPath_mem_8_0_bits_robIdx_value;
  assign io_toExus_mem_8_0_bits_sqIdx_flag = io_fromDataPath_mem_8_0_bits_sqIdx_flag;
  assign io_toExus_mem_8_0_bits_sqIdx_value = io_fromDataPath_mem_8_0_bits_sqIdx_value;
  assign io_toExus_mem_8_0_bits_loadDependency_0 = io_fromDataPath_mem_8_0_bits_loadDependency_0;
  assign io_toExus_mem_8_0_bits_loadDependency_1 = io_fromDataPath_mem_8_0_bits_loadDependency_1;
  assign io_toExus_mem_8_0_bits_loadDependency_2 = io_fromDataPath_mem_8_0_bits_loadDependency_2;
  assign io_toExus_mem_7_0_valid = io_fromDataPath_mem_7_0_valid;
  assign io_toExus_mem_7_0_bits_fuType = io_fromDataPath_mem_7_0_bits_fuType;
  assign io_toExus_mem_7_0_bits_fuOpType = io_fromDataPath_mem_7_0_bits_fuOpType;
  assign io_toExus_mem_7_0_bits_robIdx_flag = io_fromDataPath_mem_7_0_bits_robIdx_flag;
  assign io_toExus_mem_7_0_bits_robIdx_value = io_fromDataPath_mem_7_0_bits_robIdx_value;
  assign io_toExus_mem_7_0_bits_sqIdx_flag = io_fromDataPath_mem_7_0_bits_sqIdx_flag;
  assign io_toExus_mem_7_0_bits_sqIdx_value = io_fromDataPath_mem_7_0_bits_sqIdx_value;
  assign io_toExus_mem_7_0_bits_loadDependency_0 = io_fromDataPath_mem_7_0_bits_loadDependency_0;
  assign io_toExus_mem_7_0_bits_loadDependency_1 = io_fromDataPath_mem_7_0_bits_loadDependency_1;
  assign io_toExus_mem_7_0_bits_loadDependency_2 = io_fromDataPath_mem_7_0_bits_loadDependency_2;
  assign io_toExus_mem_6_0_valid = io_fromDataPath_mem_6_0_valid;
  assign io_toExus_mem_6_0_bits_fuType = io_fromDataPath_mem_6_0_bits_fuType;
  assign io_toExus_mem_6_0_bits_fuOpType = io_fromDataPath_mem_6_0_bits_fuOpType;
  assign io_toExus_mem_6_0_bits_robIdx_flag = io_fromDataPath_mem_6_0_bits_robIdx_flag;
  assign io_toExus_mem_6_0_bits_robIdx_value = io_fromDataPath_mem_6_0_bits_robIdx_value;
  assign io_toExus_mem_6_0_bits_pdest = io_fromDataPath_mem_6_0_bits_pdest;
  assign io_toExus_mem_6_0_bits_vecWen = io_fromDataPath_mem_6_0_bits_vecWen;
  assign io_toExus_mem_6_0_bits_v0Wen = io_fromDataPath_mem_6_0_bits_v0Wen;
  assign io_toExus_mem_6_0_bits_vlWen = io_fromDataPath_mem_6_0_bits_vlWen;
  assign io_toExus_mem_6_0_bits_vpu_vill = io_fromDataPath_mem_6_0_bits_vpu_vill;
  assign io_toExus_mem_6_0_bits_vpu_vma = io_fromDataPath_mem_6_0_bits_vpu_vma;
  assign io_toExus_mem_6_0_bits_vpu_vta = io_fromDataPath_mem_6_0_bits_vpu_vta;
  assign io_toExus_mem_6_0_bits_vpu_vsew = io_fromDataPath_mem_6_0_bits_vpu_vsew;
  assign io_toExus_mem_6_0_bits_vpu_vlmul = io_fromDataPath_mem_6_0_bits_vpu_vlmul;
  assign io_toExus_mem_6_0_bits_vpu_specVill = io_fromDataPath_mem_6_0_bits_vpu_specVill;
  assign io_toExus_mem_6_0_bits_vpu_specVma = io_fromDataPath_mem_6_0_bits_vpu_specVma;
  assign io_toExus_mem_6_0_bits_vpu_specVta = io_fromDataPath_mem_6_0_bits_vpu_specVta;
  assign io_toExus_mem_6_0_bits_vpu_specVsew = io_fromDataPath_mem_6_0_bits_vpu_specVsew;
  assign io_toExus_mem_6_0_bits_vpu_specVlmul = io_fromDataPath_mem_6_0_bits_vpu_specVlmul;
  assign io_toExus_mem_6_0_bits_vpu_vm = io_fromDataPath_mem_6_0_bits_vpu_vm;
  assign io_toExus_mem_6_0_bits_vpu_vstart = io_fromDataPath_mem_6_0_bits_vpu_vstart;
  assign io_toExus_mem_6_0_bits_vpu_frm = io_fromDataPath_mem_6_0_bits_vpu_frm;
  assign io_toExus_mem_6_0_bits_vpu_fpu_isFpToVecInst = io_fromDataPath_mem_6_0_bits_vpu_fpu_isFpToVecInst;
  assign io_toExus_mem_6_0_bits_vpu_fpu_isFP32Instr = io_fromDataPath_mem_6_0_bits_vpu_fpu_isFP32Instr;
  assign io_toExus_mem_6_0_bits_vpu_fpu_isFP64Instr = io_fromDataPath_mem_6_0_bits_vpu_fpu_isFP64Instr;
  assign io_toExus_mem_6_0_bits_vpu_fpu_isReduction = io_fromDataPath_mem_6_0_bits_vpu_fpu_isReduction;
  assign io_toExus_mem_6_0_bits_vpu_fpu_isFoldTo1_2 = io_fromDataPath_mem_6_0_bits_vpu_fpu_isFoldTo1_2;
  assign io_toExus_mem_6_0_bits_vpu_fpu_isFoldTo1_4 = io_fromDataPath_mem_6_0_bits_vpu_fpu_isFoldTo1_4;
  assign io_toExus_mem_6_0_bits_vpu_fpu_isFoldTo1_8 = io_fromDataPath_mem_6_0_bits_vpu_fpu_isFoldTo1_8;
  assign io_toExus_mem_6_0_bits_vpu_vxrm = io_fromDataPath_mem_6_0_bits_vpu_vxrm;
  assign io_toExus_mem_6_0_bits_vpu_vuopIdx = io_fromDataPath_mem_6_0_bits_vpu_vuopIdx;
  assign io_toExus_mem_6_0_bits_vpu_lastUop = io_fromDataPath_mem_6_0_bits_vpu_lastUop;
  assign io_toExus_mem_6_0_bits_vpu_vmask = io_fromDataPath_mem_6_0_bits_vpu_vmask;
  assign io_toExus_mem_6_0_bits_vpu_nf = io_fromDataPath_mem_6_0_bits_vpu_nf;
  assign io_toExus_mem_6_0_bits_vpu_veew = io_fromDataPath_mem_6_0_bits_vpu_veew;
  assign io_toExus_mem_6_0_bits_vpu_isReverse = io_fromDataPath_mem_6_0_bits_vpu_isReverse;
  assign io_toExus_mem_6_0_bits_vpu_isExt = io_fromDataPath_mem_6_0_bits_vpu_isExt;
  assign io_toExus_mem_6_0_bits_vpu_isNarrow = io_fromDataPath_mem_6_0_bits_vpu_isNarrow;
  assign io_toExus_mem_6_0_bits_vpu_isDstMask = io_fromDataPath_mem_6_0_bits_vpu_isDstMask;
  assign io_toExus_mem_6_0_bits_vpu_isOpMask = io_fromDataPath_mem_6_0_bits_vpu_isOpMask;
  assign io_toExus_mem_6_0_bits_vpu_isMove = io_fromDataPath_mem_6_0_bits_vpu_isMove;
  assign io_toExus_mem_6_0_bits_vpu_isDependOldVd = io_fromDataPath_mem_6_0_bits_vpu_isDependOldVd;
  assign io_toExus_mem_6_0_bits_vpu_isWritePartVd = io_fromDataPath_mem_6_0_bits_vpu_isWritePartVd;
  assign io_toExus_mem_6_0_bits_vpu_isVleff = io_fromDataPath_mem_6_0_bits_vpu_isVleff;
  assign io_toExus_mem_6_0_bits_ftqIdx_flag = io_fromDataPath_mem_6_0_bits_ftqIdx_flag;
  assign io_toExus_mem_6_0_bits_ftqIdx_value = io_fromDataPath_mem_6_0_bits_ftqIdx_value;
  assign io_toExus_mem_6_0_bits_ftqOffset = io_fromDataPath_mem_6_0_bits_ftqOffset;
  assign io_toExus_mem_6_0_bits_numLsElem = io_fromDataPath_mem_6_0_bits_numLsElem;
  assign io_toExus_mem_6_0_bits_sqIdx_flag = io_fromDataPath_mem_6_0_bits_sqIdx_flag;
  assign io_toExus_mem_6_0_bits_sqIdx_value = io_fromDataPath_mem_6_0_bits_sqIdx_value;
  assign io_toExus_mem_6_0_bits_lqIdx_flag = io_fromDataPath_mem_6_0_bits_lqIdx_flag;
  assign io_toExus_mem_6_0_bits_lqIdx_value = io_fromDataPath_mem_6_0_bits_lqIdx_value;
  assign io_toExus_mem_6_0_bits_isVecPartReplay = io_fromDataPath_mem_6_0_bits_isVecPartReplay;
  assign io_toExus_mem_6_0_bits_vecReplayMask = io_fromDataPath_mem_6_0_bits_vecReplayMask;
  assign io_toExus_mem_6_0_bits_vecReplayMbIdx = io_fromDataPath_mem_6_0_bits_vecReplayMbIdx;
  assign io_toExus_mem_6_0_bits_perfDebugInfo_eliminatedMove = io_fromDataPath_mem_6_0_bits_perfDebugInfo_eliminatedMove;
  assign io_toExus_mem_6_0_bits_perfDebugInfo_renameTime = io_fromDataPath_mem_6_0_bits_perfDebugInfo_renameTime;
  assign io_toExus_mem_6_0_bits_perfDebugInfo_dispatchTime = io_fromDataPath_mem_6_0_bits_perfDebugInfo_dispatchTime;
  assign io_toExus_mem_6_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_mem_6_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_mem_6_0_bits_perfDebugInfo_selectTime = io_fromDataPath_mem_6_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_mem_6_0_bits_perfDebugInfo_issueTime = io_fromDataPath_mem_6_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_mem_6_0_bits_perfDebugInfo_writebackTime = io_fromDataPath_mem_6_0_bits_perfDebugInfo_writebackTime;
  assign io_toExus_mem_6_0_bits_perfDebugInfo_runahead_checkpoint_id = io_fromDataPath_mem_6_0_bits_perfDebugInfo_runahead_checkpoint_id;
  assign io_toExus_mem_6_0_bits_perfDebugInfo_tlbFirstReqTime = io_fromDataPath_mem_6_0_bits_perfDebugInfo_tlbFirstReqTime;
  assign io_toExus_mem_6_0_bits_perfDebugInfo_tlbRespTime = io_fromDataPath_mem_6_0_bits_perfDebugInfo_tlbRespTime;
  assign io_toExus_mem_6_0_bits_debug_seqNum_seqNum = io_fromDataPath_mem_6_0_bits_debug_seqNum_seqNum;
  assign io_toExus_mem_6_0_bits_debug_seqNum_uopIdx = io_fromDataPath_mem_6_0_bits_debug_seqNum_uopIdx;
  assign io_toExus_mem_5_0_valid = io_fromDataPath_mem_5_0_valid;
  assign io_toExus_mem_5_0_bits_fuType = io_fromDataPath_mem_5_0_bits_fuType;
  assign io_toExus_mem_5_0_bits_fuOpType = io_fromDataPath_mem_5_0_bits_fuOpType;
  assign io_toExus_mem_5_0_bits_robIdx_flag = io_fromDataPath_mem_5_0_bits_robIdx_flag;
  assign io_toExus_mem_5_0_bits_robIdx_value = io_fromDataPath_mem_5_0_bits_robIdx_value;
  assign io_toExus_mem_5_0_bits_pdest = io_fromDataPath_mem_5_0_bits_pdest;
  assign io_toExus_mem_5_0_bits_vecWen = io_fromDataPath_mem_5_0_bits_vecWen;
  assign io_toExus_mem_5_0_bits_v0Wen = io_fromDataPath_mem_5_0_bits_v0Wen;
  assign io_toExus_mem_5_0_bits_vlWen = io_fromDataPath_mem_5_0_bits_vlWen;
  assign io_toExus_mem_5_0_bits_vpu_vill = io_fromDataPath_mem_5_0_bits_vpu_vill;
  assign io_toExus_mem_5_0_bits_vpu_vma = io_fromDataPath_mem_5_0_bits_vpu_vma;
  assign io_toExus_mem_5_0_bits_vpu_vta = io_fromDataPath_mem_5_0_bits_vpu_vta;
  assign io_toExus_mem_5_0_bits_vpu_vsew = io_fromDataPath_mem_5_0_bits_vpu_vsew;
  assign io_toExus_mem_5_0_bits_vpu_vlmul = io_fromDataPath_mem_5_0_bits_vpu_vlmul;
  assign io_toExus_mem_5_0_bits_vpu_specVill = io_fromDataPath_mem_5_0_bits_vpu_specVill;
  assign io_toExus_mem_5_0_bits_vpu_specVma = io_fromDataPath_mem_5_0_bits_vpu_specVma;
  assign io_toExus_mem_5_0_bits_vpu_specVta = io_fromDataPath_mem_5_0_bits_vpu_specVta;
  assign io_toExus_mem_5_0_bits_vpu_specVsew = io_fromDataPath_mem_5_0_bits_vpu_specVsew;
  assign io_toExus_mem_5_0_bits_vpu_specVlmul = io_fromDataPath_mem_5_0_bits_vpu_specVlmul;
  assign io_toExus_mem_5_0_bits_vpu_vm = io_fromDataPath_mem_5_0_bits_vpu_vm;
  assign io_toExus_mem_5_0_bits_vpu_vstart = io_fromDataPath_mem_5_0_bits_vpu_vstart;
  assign io_toExus_mem_5_0_bits_vpu_frm = io_fromDataPath_mem_5_0_bits_vpu_frm;
  assign io_toExus_mem_5_0_bits_vpu_fpu_isFpToVecInst = io_fromDataPath_mem_5_0_bits_vpu_fpu_isFpToVecInst;
  assign io_toExus_mem_5_0_bits_vpu_fpu_isFP32Instr = io_fromDataPath_mem_5_0_bits_vpu_fpu_isFP32Instr;
  assign io_toExus_mem_5_0_bits_vpu_fpu_isFP64Instr = io_fromDataPath_mem_5_0_bits_vpu_fpu_isFP64Instr;
  assign io_toExus_mem_5_0_bits_vpu_fpu_isReduction = io_fromDataPath_mem_5_0_bits_vpu_fpu_isReduction;
  assign io_toExus_mem_5_0_bits_vpu_fpu_isFoldTo1_2 = io_fromDataPath_mem_5_0_bits_vpu_fpu_isFoldTo1_2;
  assign io_toExus_mem_5_0_bits_vpu_fpu_isFoldTo1_4 = io_fromDataPath_mem_5_0_bits_vpu_fpu_isFoldTo1_4;
  assign io_toExus_mem_5_0_bits_vpu_fpu_isFoldTo1_8 = io_fromDataPath_mem_5_0_bits_vpu_fpu_isFoldTo1_8;
  assign io_toExus_mem_5_0_bits_vpu_vxrm = io_fromDataPath_mem_5_0_bits_vpu_vxrm;
  assign io_toExus_mem_5_0_bits_vpu_vuopIdx = io_fromDataPath_mem_5_0_bits_vpu_vuopIdx;
  assign io_toExus_mem_5_0_bits_vpu_lastUop = io_fromDataPath_mem_5_0_bits_vpu_lastUop;
  assign io_toExus_mem_5_0_bits_vpu_vmask = io_fromDataPath_mem_5_0_bits_vpu_vmask;
  assign io_toExus_mem_5_0_bits_vpu_nf = io_fromDataPath_mem_5_0_bits_vpu_nf;
  assign io_toExus_mem_5_0_bits_vpu_veew = io_fromDataPath_mem_5_0_bits_vpu_veew;
  assign io_toExus_mem_5_0_bits_vpu_isReverse = io_fromDataPath_mem_5_0_bits_vpu_isReverse;
  assign io_toExus_mem_5_0_bits_vpu_isExt = io_fromDataPath_mem_5_0_bits_vpu_isExt;
  assign io_toExus_mem_5_0_bits_vpu_isNarrow = io_fromDataPath_mem_5_0_bits_vpu_isNarrow;
  assign io_toExus_mem_5_0_bits_vpu_isDstMask = io_fromDataPath_mem_5_0_bits_vpu_isDstMask;
  assign io_toExus_mem_5_0_bits_vpu_isOpMask = io_fromDataPath_mem_5_0_bits_vpu_isOpMask;
  assign io_toExus_mem_5_0_bits_vpu_isMove = io_fromDataPath_mem_5_0_bits_vpu_isMove;
  assign io_toExus_mem_5_0_bits_vpu_isDependOldVd = io_fromDataPath_mem_5_0_bits_vpu_isDependOldVd;
  assign io_toExus_mem_5_0_bits_vpu_isWritePartVd = io_fromDataPath_mem_5_0_bits_vpu_isWritePartVd;
  assign io_toExus_mem_5_0_bits_vpu_isVleff = io_fromDataPath_mem_5_0_bits_vpu_isVleff;
  assign io_toExus_mem_5_0_bits_ftqIdx_flag = io_fromDataPath_mem_5_0_bits_ftqIdx_flag;
  assign io_toExus_mem_5_0_bits_ftqIdx_value = io_fromDataPath_mem_5_0_bits_ftqIdx_value;
  assign io_toExus_mem_5_0_bits_ftqOffset = io_fromDataPath_mem_5_0_bits_ftqOffset;
  assign io_toExus_mem_5_0_bits_numLsElem = io_fromDataPath_mem_5_0_bits_numLsElem;
  assign io_toExus_mem_5_0_bits_sqIdx_flag = io_fromDataPath_mem_5_0_bits_sqIdx_flag;
  assign io_toExus_mem_5_0_bits_sqIdx_value = io_fromDataPath_mem_5_0_bits_sqIdx_value;
  assign io_toExus_mem_5_0_bits_lqIdx_flag = io_fromDataPath_mem_5_0_bits_lqIdx_flag;
  assign io_toExus_mem_5_0_bits_lqIdx_value = io_fromDataPath_mem_5_0_bits_lqIdx_value;
  assign io_toExus_mem_5_0_bits_isVecPartReplay = io_fromDataPath_mem_5_0_bits_isVecPartReplay;
  assign io_toExus_mem_5_0_bits_vecReplayMask = io_fromDataPath_mem_5_0_bits_vecReplayMask;
  assign io_toExus_mem_5_0_bits_vecReplayMbIdx = io_fromDataPath_mem_5_0_bits_vecReplayMbIdx;
  assign io_toExus_mem_5_0_bits_perfDebugInfo_eliminatedMove = io_fromDataPath_mem_5_0_bits_perfDebugInfo_eliminatedMove;
  assign io_toExus_mem_5_0_bits_perfDebugInfo_renameTime = io_fromDataPath_mem_5_0_bits_perfDebugInfo_renameTime;
  assign io_toExus_mem_5_0_bits_perfDebugInfo_dispatchTime = io_fromDataPath_mem_5_0_bits_perfDebugInfo_dispatchTime;
  assign io_toExus_mem_5_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_mem_5_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_mem_5_0_bits_perfDebugInfo_selectTime = io_fromDataPath_mem_5_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_mem_5_0_bits_perfDebugInfo_issueTime = io_fromDataPath_mem_5_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_mem_5_0_bits_perfDebugInfo_writebackTime = io_fromDataPath_mem_5_0_bits_perfDebugInfo_writebackTime;
  assign io_toExus_mem_5_0_bits_perfDebugInfo_runahead_checkpoint_id = io_fromDataPath_mem_5_0_bits_perfDebugInfo_runahead_checkpoint_id;
  assign io_toExus_mem_5_0_bits_perfDebugInfo_tlbFirstReqTime = io_fromDataPath_mem_5_0_bits_perfDebugInfo_tlbFirstReqTime;
  assign io_toExus_mem_5_0_bits_perfDebugInfo_tlbRespTime = io_fromDataPath_mem_5_0_bits_perfDebugInfo_tlbRespTime;
  assign io_toExus_mem_5_0_bits_debug_seqNum_seqNum = io_fromDataPath_mem_5_0_bits_debug_seqNum_seqNum;
  assign io_toExus_mem_5_0_bits_debug_seqNum_uopIdx = io_fromDataPath_mem_5_0_bits_debug_seqNum_uopIdx;
  assign io_toExus_mem_4_0_valid = io_fromDataPath_mem_4_0_valid;
  assign io_toExus_mem_4_0_bits_fuType = io_fromDataPath_mem_4_0_bits_fuType;
  assign io_toExus_mem_4_0_bits_fuOpType = io_fromDataPath_mem_4_0_bits_fuOpType;
  assign io_toExus_mem_4_0_bits_imm = io_fromDataPath_mem_4_0_bits_imm;
  assign io_toExus_mem_4_0_bits_robIdx_flag = io_fromDataPath_mem_4_0_bits_robIdx_flag;
  assign io_toExus_mem_4_0_bits_robIdx_value = io_fromDataPath_mem_4_0_bits_robIdx_value;
  assign io_toExus_mem_4_0_bits_pdest = io_fromDataPath_mem_4_0_bits_pdest;
  assign io_toExus_mem_4_0_bits_rfWen = io_fromDataPath_mem_4_0_bits_rfWen;
  assign io_toExus_mem_4_0_bits_fpWen = io_fromDataPath_mem_4_0_bits_fpWen;
  assign io_toExus_mem_4_0_bits_pc = io_fromDataPath_mem_4_0_bits_pc;
  assign io_toExus_mem_4_0_bits_preDecode_valid = io_fromDataPath_mem_4_0_bits_preDecode_valid;
  assign io_toExus_mem_4_0_bits_preDecode_isRVC = io_fromDataPath_mem_4_0_bits_preDecode_isRVC;
  assign io_toExus_mem_4_0_bits_preDecode_brType = io_fromDataPath_mem_4_0_bits_preDecode_brType;
  assign io_toExus_mem_4_0_bits_preDecode_isCall = io_fromDataPath_mem_4_0_bits_preDecode_isCall;
  assign io_toExus_mem_4_0_bits_preDecode_isRet = io_fromDataPath_mem_4_0_bits_preDecode_isRet;
  assign io_toExus_mem_4_0_bits_ftqIdx_flag = io_fromDataPath_mem_4_0_bits_ftqIdx_flag;
  assign io_toExus_mem_4_0_bits_ftqIdx_value = io_fromDataPath_mem_4_0_bits_ftqIdx_value;
  assign io_toExus_mem_4_0_bits_ftqOffset = io_fromDataPath_mem_4_0_bits_ftqOffset;
  assign io_toExus_mem_4_0_bits_loadWaitBit = io_fromDataPath_mem_4_0_bits_loadWaitBit;
  assign io_toExus_mem_4_0_bits_waitForRobIdx_flag = io_fromDataPath_mem_4_0_bits_waitForRobIdx_flag;
  assign io_toExus_mem_4_0_bits_waitForRobIdx_value = io_fromDataPath_mem_4_0_bits_waitForRobIdx_value;
  assign io_toExus_mem_4_0_bits_storeSetHit = io_fromDataPath_mem_4_0_bits_storeSetHit;
  assign io_toExus_mem_4_0_bits_loadWaitStrict = io_fromDataPath_mem_4_0_bits_loadWaitStrict;
  assign io_toExus_mem_4_0_bits_ssid = io_fromDataPath_mem_4_0_bits_ssid;
  assign io_toExus_mem_4_0_bits_sqIdx_flag = io_fromDataPath_mem_4_0_bits_sqIdx_flag;
  assign io_toExus_mem_4_0_bits_sqIdx_value = io_fromDataPath_mem_4_0_bits_sqIdx_value;
  assign io_toExus_mem_4_0_bits_lqIdx_flag = io_fromDataPath_mem_4_0_bits_lqIdx_flag;
  assign io_toExus_mem_4_0_bits_lqIdx_value = io_fromDataPath_mem_4_0_bits_lqIdx_value;
  assign io_toExus_mem_4_0_bits_loadDependency_0 = io_fromDataPath_mem_4_0_bits_loadDependency_0;
  assign io_toExus_mem_4_0_bits_loadDependency_1 = io_fromDataPath_mem_4_0_bits_loadDependency_1;
  assign io_toExus_mem_4_0_bits_loadDependency_2 = io_fromDataPath_mem_4_0_bits_loadDependency_2;
  assign io_toExus_mem_4_0_bits_perfDebugInfo_eliminatedMove = io_fromDataPath_mem_4_0_bits_perfDebugInfo_eliminatedMove;
  assign io_toExus_mem_4_0_bits_perfDebugInfo_renameTime = io_fromDataPath_mem_4_0_bits_perfDebugInfo_renameTime;
  assign io_toExus_mem_4_0_bits_perfDebugInfo_dispatchTime = io_fromDataPath_mem_4_0_bits_perfDebugInfo_dispatchTime;
  assign io_toExus_mem_4_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_mem_4_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_mem_4_0_bits_perfDebugInfo_selectTime = io_fromDataPath_mem_4_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_mem_4_0_bits_perfDebugInfo_issueTime = io_fromDataPath_mem_4_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_mem_4_0_bits_perfDebugInfo_writebackTime = io_fromDataPath_mem_4_0_bits_perfDebugInfo_writebackTime;
  assign io_toExus_mem_4_0_bits_perfDebugInfo_runahead_checkpoint_id = io_fromDataPath_mem_4_0_bits_perfDebugInfo_runahead_checkpoint_id;
  assign io_toExus_mem_4_0_bits_perfDebugInfo_tlbFirstReqTime = io_fromDataPath_mem_4_0_bits_perfDebugInfo_tlbFirstReqTime;
  assign io_toExus_mem_4_0_bits_perfDebugInfo_tlbRespTime = io_fromDataPath_mem_4_0_bits_perfDebugInfo_tlbRespTime;
  assign io_toExus_mem_4_0_bits_debug_seqNum_seqNum = io_fromDataPath_mem_4_0_bits_debug_seqNum_seqNum;
  assign io_toExus_mem_4_0_bits_debug_seqNum_uopIdx = io_fromDataPath_mem_4_0_bits_debug_seqNum_uopIdx;
  assign io_toExus_mem_3_0_valid = io_fromDataPath_mem_3_0_valid;
  assign io_toExus_mem_3_0_bits_fuType = io_fromDataPath_mem_3_0_bits_fuType;
  assign io_toExus_mem_3_0_bits_fuOpType = io_fromDataPath_mem_3_0_bits_fuOpType;
  assign io_toExus_mem_3_0_bits_imm = io_fromDataPath_mem_3_0_bits_imm;
  assign io_toExus_mem_3_0_bits_robIdx_flag = io_fromDataPath_mem_3_0_bits_robIdx_flag;
  assign io_toExus_mem_3_0_bits_robIdx_value = io_fromDataPath_mem_3_0_bits_robIdx_value;
  assign io_toExus_mem_3_0_bits_pdest = io_fromDataPath_mem_3_0_bits_pdest;
  assign io_toExus_mem_3_0_bits_rfWen = io_fromDataPath_mem_3_0_bits_rfWen;
  assign io_toExus_mem_3_0_bits_fpWen = io_fromDataPath_mem_3_0_bits_fpWen;
  assign io_toExus_mem_3_0_bits_pc = io_fromDataPath_mem_3_0_bits_pc;
  assign io_toExus_mem_3_0_bits_preDecode_valid = io_fromDataPath_mem_3_0_bits_preDecode_valid;
  assign io_toExus_mem_3_0_bits_preDecode_isRVC = io_fromDataPath_mem_3_0_bits_preDecode_isRVC;
  assign io_toExus_mem_3_0_bits_preDecode_brType = io_fromDataPath_mem_3_0_bits_preDecode_brType;
  assign io_toExus_mem_3_0_bits_preDecode_isCall = io_fromDataPath_mem_3_0_bits_preDecode_isCall;
  assign io_toExus_mem_3_0_bits_preDecode_isRet = io_fromDataPath_mem_3_0_bits_preDecode_isRet;
  assign io_toExus_mem_3_0_bits_ftqIdx_flag = io_fromDataPath_mem_3_0_bits_ftqIdx_flag;
  assign io_toExus_mem_3_0_bits_ftqIdx_value = io_fromDataPath_mem_3_0_bits_ftqIdx_value;
  assign io_toExus_mem_3_0_bits_ftqOffset = io_fromDataPath_mem_3_0_bits_ftqOffset;
  assign io_toExus_mem_3_0_bits_loadWaitBit = io_fromDataPath_mem_3_0_bits_loadWaitBit;
  assign io_toExus_mem_3_0_bits_waitForRobIdx_flag = io_fromDataPath_mem_3_0_bits_waitForRobIdx_flag;
  assign io_toExus_mem_3_0_bits_waitForRobIdx_value = io_fromDataPath_mem_3_0_bits_waitForRobIdx_value;
  assign io_toExus_mem_3_0_bits_storeSetHit = io_fromDataPath_mem_3_0_bits_storeSetHit;
  assign io_toExus_mem_3_0_bits_loadWaitStrict = io_fromDataPath_mem_3_0_bits_loadWaitStrict;
  assign io_toExus_mem_3_0_bits_ssid = io_fromDataPath_mem_3_0_bits_ssid;
  assign io_toExus_mem_3_0_bits_sqIdx_flag = io_fromDataPath_mem_3_0_bits_sqIdx_flag;
  assign io_toExus_mem_3_0_bits_sqIdx_value = io_fromDataPath_mem_3_0_bits_sqIdx_value;
  assign io_toExus_mem_3_0_bits_lqIdx_flag = io_fromDataPath_mem_3_0_bits_lqIdx_flag;
  assign io_toExus_mem_3_0_bits_lqIdx_value = io_fromDataPath_mem_3_0_bits_lqIdx_value;
  assign io_toExus_mem_3_0_bits_loadDependency_0 = io_fromDataPath_mem_3_0_bits_loadDependency_0;
  assign io_toExus_mem_3_0_bits_loadDependency_1 = io_fromDataPath_mem_3_0_bits_loadDependency_1;
  assign io_toExus_mem_3_0_bits_loadDependency_2 = io_fromDataPath_mem_3_0_bits_loadDependency_2;
  assign io_toExus_mem_3_0_bits_perfDebugInfo_eliminatedMove = io_fromDataPath_mem_3_0_bits_perfDebugInfo_eliminatedMove;
  assign io_toExus_mem_3_0_bits_perfDebugInfo_renameTime = io_fromDataPath_mem_3_0_bits_perfDebugInfo_renameTime;
  assign io_toExus_mem_3_0_bits_perfDebugInfo_dispatchTime = io_fromDataPath_mem_3_0_bits_perfDebugInfo_dispatchTime;
  assign io_toExus_mem_3_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_mem_3_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_mem_3_0_bits_perfDebugInfo_selectTime = io_fromDataPath_mem_3_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_mem_3_0_bits_perfDebugInfo_issueTime = io_fromDataPath_mem_3_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_mem_3_0_bits_perfDebugInfo_writebackTime = io_fromDataPath_mem_3_0_bits_perfDebugInfo_writebackTime;
  assign io_toExus_mem_3_0_bits_perfDebugInfo_runahead_checkpoint_id = io_fromDataPath_mem_3_0_bits_perfDebugInfo_runahead_checkpoint_id;
  assign io_toExus_mem_3_0_bits_perfDebugInfo_tlbFirstReqTime = io_fromDataPath_mem_3_0_bits_perfDebugInfo_tlbFirstReqTime;
  assign io_toExus_mem_3_0_bits_perfDebugInfo_tlbRespTime = io_fromDataPath_mem_3_0_bits_perfDebugInfo_tlbRespTime;
  assign io_toExus_mem_3_0_bits_debug_seqNum_seqNum = io_fromDataPath_mem_3_0_bits_debug_seqNum_seqNum;
  assign io_toExus_mem_3_0_bits_debug_seqNum_uopIdx = io_fromDataPath_mem_3_0_bits_debug_seqNum_uopIdx;
  assign io_toExus_mem_2_0_valid = io_fromDataPath_mem_2_0_valid;
  assign io_toExus_mem_2_0_bits_fuType = io_fromDataPath_mem_2_0_bits_fuType;
  assign io_toExus_mem_2_0_bits_fuOpType = io_fromDataPath_mem_2_0_bits_fuOpType;
  assign io_toExus_mem_2_0_bits_imm = io_fromDataPath_mem_2_0_bits_imm;
  assign io_toExus_mem_2_0_bits_robIdx_flag = io_fromDataPath_mem_2_0_bits_robIdx_flag;
  assign io_toExus_mem_2_0_bits_robIdx_value = io_fromDataPath_mem_2_0_bits_robIdx_value;
  assign io_toExus_mem_2_0_bits_pdest = io_fromDataPath_mem_2_0_bits_pdest;
  assign io_toExus_mem_2_0_bits_rfWen = io_fromDataPath_mem_2_0_bits_rfWen;
  assign io_toExus_mem_2_0_bits_fpWen = io_fromDataPath_mem_2_0_bits_fpWen;
  assign io_toExus_mem_2_0_bits_pc = io_fromDataPath_mem_2_0_bits_pc;
  assign io_toExus_mem_2_0_bits_preDecode_valid = io_fromDataPath_mem_2_0_bits_preDecode_valid;
  assign io_toExus_mem_2_0_bits_preDecode_isRVC = io_fromDataPath_mem_2_0_bits_preDecode_isRVC;
  assign io_toExus_mem_2_0_bits_preDecode_brType = io_fromDataPath_mem_2_0_bits_preDecode_brType;
  assign io_toExus_mem_2_0_bits_preDecode_isCall = io_fromDataPath_mem_2_0_bits_preDecode_isCall;
  assign io_toExus_mem_2_0_bits_preDecode_isRet = io_fromDataPath_mem_2_0_bits_preDecode_isRet;
  assign io_toExus_mem_2_0_bits_ftqIdx_flag = io_fromDataPath_mem_2_0_bits_ftqIdx_flag;
  assign io_toExus_mem_2_0_bits_ftqIdx_value = io_fromDataPath_mem_2_0_bits_ftqIdx_value;
  assign io_toExus_mem_2_0_bits_ftqOffset = io_fromDataPath_mem_2_0_bits_ftqOffset;
  assign io_toExus_mem_2_0_bits_loadWaitBit = io_fromDataPath_mem_2_0_bits_loadWaitBit;
  assign io_toExus_mem_2_0_bits_waitForRobIdx_flag = io_fromDataPath_mem_2_0_bits_waitForRobIdx_flag;
  assign io_toExus_mem_2_0_bits_waitForRobIdx_value = io_fromDataPath_mem_2_0_bits_waitForRobIdx_value;
  assign io_toExus_mem_2_0_bits_storeSetHit = io_fromDataPath_mem_2_0_bits_storeSetHit;
  assign io_toExus_mem_2_0_bits_loadWaitStrict = io_fromDataPath_mem_2_0_bits_loadWaitStrict;
  assign io_toExus_mem_2_0_bits_ssid = io_fromDataPath_mem_2_0_bits_ssid;
  assign io_toExus_mem_2_0_bits_sqIdx_flag = io_fromDataPath_mem_2_0_bits_sqIdx_flag;
  assign io_toExus_mem_2_0_bits_sqIdx_value = io_fromDataPath_mem_2_0_bits_sqIdx_value;
  assign io_toExus_mem_2_0_bits_lqIdx_flag = io_fromDataPath_mem_2_0_bits_lqIdx_flag;
  assign io_toExus_mem_2_0_bits_lqIdx_value = io_fromDataPath_mem_2_0_bits_lqIdx_value;
  assign io_toExus_mem_2_0_bits_loadDependency_0 = io_fromDataPath_mem_2_0_bits_loadDependency_0;
  assign io_toExus_mem_2_0_bits_loadDependency_1 = io_fromDataPath_mem_2_0_bits_loadDependency_1;
  assign io_toExus_mem_2_0_bits_loadDependency_2 = io_fromDataPath_mem_2_0_bits_loadDependency_2;
  assign io_toExus_mem_2_0_bits_perfDebugInfo_eliminatedMove = io_fromDataPath_mem_2_0_bits_perfDebugInfo_eliminatedMove;
  assign io_toExus_mem_2_0_bits_perfDebugInfo_renameTime = io_fromDataPath_mem_2_0_bits_perfDebugInfo_renameTime;
  assign io_toExus_mem_2_0_bits_perfDebugInfo_dispatchTime = io_fromDataPath_mem_2_0_bits_perfDebugInfo_dispatchTime;
  assign io_toExus_mem_2_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_mem_2_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_mem_2_0_bits_perfDebugInfo_selectTime = io_fromDataPath_mem_2_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_mem_2_0_bits_perfDebugInfo_issueTime = io_fromDataPath_mem_2_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_mem_2_0_bits_perfDebugInfo_writebackTime = io_fromDataPath_mem_2_0_bits_perfDebugInfo_writebackTime;
  assign io_toExus_mem_2_0_bits_perfDebugInfo_runahead_checkpoint_id = io_fromDataPath_mem_2_0_bits_perfDebugInfo_runahead_checkpoint_id;
  assign io_toExus_mem_2_0_bits_perfDebugInfo_tlbFirstReqTime = io_fromDataPath_mem_2_0_bits_perfDebugInfo_tlbFirstReqTime;
  assign io_toExus_mem_2_0_bits_perfDebugInfo_tlbRespTime = io_fromDataPath_mem_2_0_bits_perfDebugInfo_tlbRespTime;
  assign io_toExus_mem_2_0_bits_debug_seqNum_seqNum = io_fromDataPath_mem_2_0_bits_debug_seqNum_seqNum;
  assign io_toExus_mem_2_0_bits_debug_seqNum_uopIdx = io_fromDataPath_mem_2_0_bits_debug_seqNum_uopIdx;
  assign io_toExus_mem_1_0_valid = io_fromDataPath_mem_1_0_valid;
  assign io_toExus_mem_1_0_bits_fuType = io_fromDataPath_mem_1_0_bits_fuType;
  assign io_toExus_mem_1_0_bits_fuOpType = io_fromDataPath_mem_1_0_bits_fuOpType;
  assign io_toExus_mem_1_0_bits_imm = io_fromDataPath_mem_1_0_bits_imm;
  assign io_toExus_mem_1_0_bits_robIdx_flag = io_fromDataPath_mem_1_0_bits_robIdx_flag;
  assign io_toExus_mem_1_0_bits_robIdx_value = io_fromDataPath_mem_1_0_bits_robIdx_value;
  assign io_toExus_mem_1_0_bits_isFirstIssue = io_fromDataPath_mem_1_0_bits_isFirstIssue;
  assign io_toExus_mem_1_0_bits_pdest = io_fromDataPath_mem_1_0_bits_pdest;
  assign io_toExus_mem_1_0_bits_rfWen = io_fromDataPath_mem_1_0_bits_rfWen;
  assign io_toExus_mem_1_0_bits_ftqIdx_flag = io_fromDataPath_mem_1_0_bits_ftqIdx_flag;
  assign io_toExus_mem_1_0_bits_ftqIdx_value = io_fromDataPath_mem_1_0_bits_ftqIdx_value;
  assign io_toExus_mem_1_0_bits_ftqOffset = io_fromDataPath_mem_1_0_bits_ftqOffset;
  assign io_toExus_mem_1_0_bits_sqIdx_flag = io_fromDataPath_mem_1_0_bits_sqIdx_flag;
  assign io_toExus_mem_1_0_bits_sqIdx_value = io_fromDataPath_mem_1_0_bits_sqIdx_value;
  assign io_toExus_mem_1_0_bits_lqIdx_flag = io_fromDataPath_mem_1_0_bits_lqIdx_flag;
  assign io_toExus_mem_1_0_bits_lqIdx_value = io_fromDataPath_mem_1_0_bits_lqIdx_value;
  assign io_toExus_mem_1_0_bits_loadDependency_0 = io_fromDataPath_mem_1_0_bits_loadDependency_0;
  assign io_toExus_mem_1_0_bits_loadDependency_1 = io_fromDataPath_mem_1_0_bits_loadDependency_1;
  assign io_toExus_mem_1_0_bits_loadDependency_2 = io_fromDataPath_mem_1_0_bits_loadDependency_2;
  assign io_toExus_mem_1_0_bits_perfDebugInfo_eliminatedMove = io_fromDataPath_mem_1_0_bits_perfDebugInfo_eliminatedMove;
  assign io_toExus_mem_1_0_bits_perfDebugInfo_renameTime = io_fromDataPath_mem_1_0_bits_perfDebugInfo_renameTime;
  assign io_toExus_mem_1_0_bits_perfDebugInfo_dispatchTime = io_fromDataPath_mem_1_0_bits_perfDebugInfo_dispatchTime;
  assign io_toExus_mem_1_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_mem_1_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_mem_1_0_bits_perfDebugInfo_selectTime = io_fromDataPath_mem_1_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_mem_1_0_bits_perfDebugInfo_issueTime = io_fromDataPath_mem_1_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_mem_1_0_bits_perfDebugInfo_writebackTime = io_fromDataPath_mem_1_0_bits_perfDebugInfo_writebackTime;
  assign io_toExus_mem_1_0_bits_perfDebugInfo_runahead_checkpoint_id = io_fromDataPath_mem_1_0_bits_perfDebugInfo_runahead_checkpoint_id;
  assign io_toExus_mem_1_0_bits_perfDebugInfo_tlbFirstReqTime = io_fromDataPath_mem_1_0_bits_perfDebugInfo_tlbFirstReqTime;
  assign io_toExus_mem_1_0_bits_perfDebugInfo_tlbRespTime = io_fromDataPath_mem_1_0_bits_perfDebugInfo_tlbRespTime;
  assign io_toExus_mem_1_0_bits_debug_seqNum_seqNum = io_fromDataPath_mem_1_0_bits_debug_seqNum_seqNum;
  assign io_toExus_mem_1_0_bits_debug_seqNum_uopIdx = io_fromDataPath_mem_1_0_bits_debug_seqNum_uopIdx;
  assign io_toExus_mem_0_0_valid = io_fromDataPath_mem_0_0_valid;
  assign io_toExus_mem_0_0_bits_fuType = io_fromDataPath_mem_0_0_bits_fuType;
  assign io_toExus_mem_0_0_bits_fuOpType = io_fromDataPath_mem_0_0_bits_fuOpType;
  assign io_toExus_mem_0_0_bits_imm = io_fromDataPath_mem_0_0_bits_imm;
  assign io_toExus_mem_0_0_bits_robIdx_flag = io_fromDataPath_mem_0_0_bits_robIdx_flag;
  assign io_toExus_mem_0_0_bits_robIdx_value = io_fromDataPath_mem_0_0_bits_robIdx_value;
  assign io_toExus_mem_0_0_bits_isFirstIssue = io_fromDataPath_mem_0_0_bits_isFirstIssue;
  assign io_toExus_mem_0_0_bits_pdest = io_fromDataPath_mem_0_0_bits_pdest;
  assign io_toExus_mem_0_0_bits_rfWen = io_fromDataPath_mem_0_0_bits_rfWen;
  assign io_toExus_mem_0_0_bits_ftqIdx_flag = io_fromDataPath_mem_0_0_bits_ftqIdx_flag;
  assign io_toExus_mem_0_0_bits_ftqIdx_value = io_fromDataPath_mem_0_0_bits_ftqIdx_value;
  assign io_toExus_mem_0_0_bits_ftqOffset = io_fromDataPath_mem_0_0_bits_ftqOffset;
  assign io_toExus_mem_0_0_bits_sqIdx_flag = io_fromDataPath_mem_0_0_bits_sqIdx_flag;
  assign io_toExus_mem_0_0_bits_sqIdx_value = io_fromDataPath_mem_0_0_bits_sqIdx_value;
  assign io_toExus_mem_0_0_bits_lqIdx_flag = io_fromDataPath_mem_0_0_bits_lqIdx_flag;
  assign io_toExus_mem_0_0_bits_lqIdx_value = io_fromDataPath_mem_0_0_bits_lqIdx_value;
  assign io_toExus_mem_0_0_bits_loadDependency_0 = io_fromDataPath_mem_0_0_bits_loadDependency_0;
  assign io_toExus_mem_0_0_bits_loadDependency_1 = io_fromDataPath_mem_0_0_bits_loadDependency_1;
  assign io_toExus_mem_0_0_bits_loadDependency_2 = io_fromDataPath_mem_0_0_bits_loadDependency_2;
  assign io_toExus_mem_0_0_bits_perfDebugInfo_eliminatedMove = io_fromDataPath_mem_0_0_bits_perfDebugInfo_eliminatedMove;
  assign io_toExus_mem_0_0_bits_perfDebugInfo_renameTime = io_fromDataPath_mem_0_0_bits_perfDebugInfo_renameTime;
  assign io_toExus_mem_0_0_bits_perfDebugInfo_dispatchTime = io_fromDataPath_mem_0_0_bits_perfDebugInfo_dispatchTime;
  assign io_toExus_mem_0_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_mem_0_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_mem_0_0_bits_perfDebugInfo_selectTime = io_fromDataPath_mem_0_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_mem_0_0_bits_perfDebugInfo_issueTime = io_fromDataPath_mem_0_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_mem_0_0_bits_perfDebugInfo_writebackTime = io_fromDataPath_mem_0_0_bits_perfDebugInfo_writebackTime;
  assign io_toExus_mem_0_0_bits_perfDebugInfo_runahead_checkpoint_id = io_fromDataPath_mem_0_0_bits_perfDebugInfo_runahead_checkpoint_id;
  assign io_toExus_mem_0_0_bits_perfDebugInfo_tlbFirstReqTime = io_fromDataPath_mem_0_0_bits_perfDebugInfo_tlbFirstReqTime;
  assign io_toExus_mem_0_0_bits_perfDebugInfo_tlbRespTime = io_fromDataPath_mem_0_0_bits_perfDebugInfo_tlbRespTime;
  assign io_toExus_mem_0_0_bits_debug_seqNum_seqNum = io_fromDataPath_mem_0_0_bits_debug_seqNum_seqNum;
  assign io_toExus_mem_0_0_bits_debug_seqNum_uopIdx = io_fromDataPath_mem_0_0_bits_debug_seqNum_uopIdx;
  assign io_fromDataPath_int_3_1_ready = io_toExus_int_3_1_ready;
  assign io_fromDataPath_int_3_0_ready = io_toExus_int_3_0_ready;
  assign io_fromDataPath_int_2_1_ready = io_toExus_int_2_1_ready;
  assign io_fromDataPath_int_2_0_ready = io_toExus_int_2_0_ready;
  assign io_fromDataPath_int_1_1_ready = io_toExus_int_1_1_ready;
  assign io_fromDataPath_int_1_0_ready = io_toExus_int_1_0_ready;
  assign io_fromDataPath_int_0_1_ready = io_toExus_int_0_1_ready;
  assign io_fromDataPath_int_0_0_ready = io_toExus_int_0_0_ready;
  assign io_fromDataPath_fp_2_0_ready = io_toExus_fp_2_0_ready;
  assign io_fromDataPath_fp_1_1_ready = io_toExus_fp_1_1_ready;
  assign io_fromDataPath_fp_1_0_ready = io_toExus_fp_1_0_ready;
  assign io_fromDataPath_fp_0_1_ready = io_toExus_fp_0_1_ready;
  assign io_fromDataPath_fp_0_0_ready = io_toExus_fp_0_0_ready;
  assign io_fromDataPath_vf_2_0_ready = io_toExus_vf_2_0_ready;
  assign io_fromDataPath_vf_1_1_ready = io_toExus_vf_1_1_ready;
  assign io_fromDataPath_vf_1_0_ready = io_toExus_vf_1_0_ready;
  assign io_fromDataPath_vf_0_1_ready = io_toExus_vf_0_1_ready;
  assign io_fromDataPath_vf_0_0_ready = io_toExus_vf_0_0_ready;
  assign io_fromDataPath_mem_8_0_ready = io_toExus_mem_8_0_ready;
  assign io_fromDataPath_mem_7_0_ready = io_toExus_mem_7_0_ready;
  assign io_fromDataPath_mem_6_0_ready = io_toExus_mem_6_0_ready;
  assign io_fromDataPath_mem_5_0_ready = io_toExus_mem_5_0_ready;
  assign io_fromDataPath_mem_4_0_ready = io_toExus_mem_4_0_ready;
  assign io_fromDataPath_mem_3_0_ready = io_toExus_mem_3_0_ready;
  assign io_fromDataPath_mem_2_0_ready = io_toExus_mem_2_0_ready;
  assign io_fromDataPath_mem_1_0_ready = io_toExus_mem_1_0_ready;
  assign io_fromDataPath_mem_0_0_ready = io_toExus_mem_0_0_ready;
endmodule
// END GENERATED
