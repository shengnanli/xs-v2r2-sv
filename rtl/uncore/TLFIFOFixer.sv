// =============================================================================
//  TLFIFOFixer —— TileLink FIFO 序保持修正器 (MemMisc 外设/MMIO 通路上唯一一例)
// -----------------------------------------------------------------------------
//  对应 rocket-chip TLFIFOFixer (src/main/scala/tilelink/FIFOFixer.scala)。
//  在 MemMisc.sv 里以实例名 `fixer` 挂在 L3/LLC → 外设 xbar 的路径上
//  (widget → fixer → llc_to_peripheral_buffer)。
//
//  它要解决什么问题:
//    TileLink 的 "FIFO 域" (fifoId) 承诺: 同一个 master 发往**同一个域**的请求, D 响应
//    按 A 请求的顺序返回。但一个 master 可以在同一时刻对**多个不同域**有在飞请求, 而
//    不同域的返回延迟互不相干 —— 于是下游 xbar 看到的响应顺序可能乱掉, 破坏承诺。
//    修正办法很朴素: **不让它们同时在飞**。某个 master 对域 X 还有请求没回来时, 它发往
//    域 Y (或发往"无法判定是哪个域"的地址) 的新请求被 stall 在 A 通道口, 直到对 X 的
//    请求全部收完 D 响应为止。同域连发不受影响 —— 那本来就是有序的。
//
//  三件状态 (全部只服务于上面这一条规则):
//    [A] a_domain  : 由 A 通道地址译码出的 4 位 FIFO 域号 (0 = 无域/不可判定)。纯组合。
//    [B] flight[s] : 每个 source id 一位 —— 该 source 是否有请求在飞。A 首拍发出置 1,
//                    D 首拍 (非 ReleaseAck) 收到清 0。
//    [C] group_domain[g] : 每个 master (source 分组) 最近一次发出的请求打的是哪个域。
//
//  stall 判据 (逐 master 组求或):
//    本拍 A 属于该组 && 是首拍 && 该组还有在飞请求 && (本拍无域 || 本拍域 != 该组上次的域)
//
//  规模真相 (golden 89,271 行的去处, 见本文件末尾 "规模核算" 注释):
//    真逻辑约 250 行; 其余 99.7% 是 firtool 把 12,288 项 flight 向量**逐位展平**的结果
//    (12,288 条 reg 声明 + 49,368 行 always 赋值) 加上 24,697 行随机化初始化宏。
//
//  与 Chisel 的两处**不一致**(以 golden 为准, 原因见 xs_TLFIFOFixer_core 内注释):
//    1. Chisel 写 `flight(source) := !a_notFIFO`, golden 里恒为 1 —— a_notFIFO 常量折叠成 0。
//    2. Chisel 的 cover 属性 (SourceIdFIFOed / allIDs_FIFOed 等) 在 golden 里被 DCE 清光。
// =============================================================================
package tlfifofixer_pkg;

  // ---- TileLink 通道几何 (按 golden 端口实测, 非 Chisel 默认值) ----------------
  localparam int OPCODE_W = 4;
  localparam int SIZE_W   = 3;
  localparam int SOURCE_W = 14;   // auto_in_a_bits_source [13:0]
  localparam int ADDR_W   = 49;   // auto_in_a_bits_address [48:0]
  localparam int BEAT_W   = 3;    // 拍计数器宽度 (golden a_first_counter [2:0])

  // ---- source id 空间与 master 分组 -------------------------------------------
  //  golden 实测: flight_0 .. flight_12287  → END_SOURCE_ID = 12288;
  //  stalls_a_sel_i = source[13:7] == i, i = 0..95 → 96 个 master, 每个占 128 个
  //  连续 source id (96 * 128 = 12288, 正好铺满)。source >= 12288 不属于任何 master,
  //  既不置 flight 也不产生 stall (golden 里没有对应的比较器)。
  localparam int END_SOURCE_ID = 12288;
  localparam int NUM_MASTERS   = 96;
  localparam int GROUP_W       = 7;   // log2(128): source[13:7] 选组, source[6:0] 组内
  localparam int GROUP_SIZE    = 1 << GROUP_W;
  localparam int MASTER_IDX_W  = SOURCE_W - GROUP_W;   // = 7, 够放 0..95

  // ---- FIFO 域号 ---------------------------------------------------------------
  localparam int DOMAIN_W = 4;
  localparam logic [DOMAIN_W-1:0] DOMAIN_NONE    = 4'd0;  // a_noDomain: 判不出域
  localparam logic [DOMAIN_W-1:0] DOMAIN_DEFAULT = 4'd3;  // 地址表未命中时的域 (见下)

  // ---- D 通道 opcode: ReleaseAck 不算 "请求的响应", 不清 flight -----------------
  localparam logic [OPCODE_W-1:0] D_OPCODE_RELEASE_ACK = 4'h6;

  // =========================================================================
  //  地址 → FIFO 域 译码表
  // -------------------------------------------------------------------------
  //  golden 的 a_id 是 firtool 把 rocket-chip findFifoIdFast 展开后的 ~210 行
  //  位级异或/比较网络 (_a_id_T_351/_355 链)。它**只看** address[48] 和
  //  address[30:12] —— address[47:31] 与 address[11:0] 完全不参与 (已对 golden
  //  源文里全部 address 位选做过穷举确认)。所以译码输入压成 20 位 region key:
  //
  //      region_key = { address[48], address[30:12] }
  //
  //  下表是对 golden a_id 做 2^20 全枚举 (verif/ut/TLFIFOFixer/aid_sweep/) 反解
  //  出来的**精确等价**表: 16 条互不相交的区间 + 未命中默认 DOMAIN_DEFAULT(=3)。
  //  复跑方式见 aid_sweep/README。区间名字对照 XiangShan src/main/scala/system/SoC.scala。
  //
  //  为什么默认是 3 而不是 0: 域 3 是片外 AXI4 外设口 peripheralNode ——
  //  它的地址是 SoC.scala 的 peripheralRange = AddressSet(0x0, 0x7fffffff) 减去上面
  //  全部片内外设窗口, 再并上两个 UART (0x40600000 / 0x310b0000, 同一个 AXI4 从口
  //  故同域)。也就是说"没被片内外设认领的地址都归它", 于是默认域是 3。
  //  域 0 (无域) 反而只落在几个被掏空的窟窿上 (APLIC 两个 32K 域之外的保留区、BEU)。
  //  这跟直觉相反, 所以照 golden 抄, 别按"没查到就是 0"去写。
  // =========================================================================
  localparam int REGION_W   = 20;
  localparam int NUM_REGION = 16;

  typedef struct packed {
    logic [REGION_W-1:0] base;    // region key 的期望值 (don't-care 位已清零)
    logic [REGION_W-1:0] care;    // 1 = 该位必须匹配; 0 = don't-care
    logic [DOMAIN_W-1:0] domain;
  } fifo_region_t;

  // care 里的 bit19 就是 address[48]: 除第一条外都要求 address[48]==0。
  localparam fifo_region_t REGION_MAP [NUM_REGION] = '{
    // address[48]=1 的整个高半空间 = TLError 错误设备
    // (SoC.scala: AddressSet(0x1000000000000, 0xffffffffffff), 挂在 error_xbar 上)
    '{base: 20'h80000, care: 20'h80000, domain: 4'd1 },
    // APLIC (SoC.scala APLICRange = 0x31100000 + 256KB): 只有两个 32KB 的 domain
    // 窗口有 FIFO 域, 窗口之间的保留区判不出域 (DOMAIN_NONE)
    '{base: 20'h31100, care: 20'hFFFF8, domain: 4'd10},  // 0x3110_0000 +32K  APLIC M domain
    '{base: 20'h31108, care: 20'hFFFF8, domain: 4'd0 },  // 0x3110_8000 +32K  (保留)
    '{base: 20'h31110, care: 20'hFFFF0, domain: 4'd0 },  // 0x3111_0000 +64K  (保留)
    '{base: 20'h31120, care: 20'hFFFF8, domain: 4'd10},  // 0x3112_0000 +32K  APLIC S domain
    '{base: 20'h31128, care: 20'hFFFF8, domain: 4'd0 },  // 0x3112_8000 +32K  (保留)
    '{base: 20'h31130, care: 20'hFFFF0, domain: 4'd0 },  // 0x3113_0000 +64K  (保留)
    // 0x38xx_xxxx 一段: CLINT/TIMER、BEU、DebugModule、MMPMA、SYSCNT
    '{base: 20'h38000, care: 20'hFFFF0, domain: 4'd7 },  // 0x3800_0000 +64K  TIMERRange (CLINT)
    '{base: 20'h38010, care: 20'hFFFFF, domain: 4'd0 },  // 0x3801_0000 +4K   BEURange (无域)
    '{base: 20'h38020, care: 20'hFFFFF, domain: 4'd4 },  // 0x3802_0000 +4K   DebugModule
    '{base: 20'h38021, care: 20'hFFFFF, domain: 4'd9 },  // 0x3802_1000 +4K   MMPMA (TLPMA)
    '{base: 20'h38040, care: 20'hFFFF0, domain: 4'd6 },  // 0x3804_0000 +64K  SYSCNTRange
    // PLL 与 IMSIC: IMSIC 的 m 页与 sg 页共用同一个域 5
    '{base: 20'h3A000, care: 20'hFFFFF, domain: 4'd2 },  // 0x3A00_0000 +4K   PLLRange
    '{base: 20'h3A800, care: 20'hFFFFF, domain: 4'd5 },  // 0x3A80_0000 +4K   IMSIC mBaseAddr
    '{base: 20'h3B000, care: 20'hFFFF8, domain: 4'd5 },  // 0x3B00_0000 +32K  IMSIC sgBaseAddr
    // PLIC
    '{base: 20'h3C000, care: 20'hFC000, domain: 4'd8 }   // 0x3C00_0000 +64M  PLICRange
  };

endpackage

// =============================================================================
//  xs_TLFIFOFixer_core —— 可读重写核
// -----------------------------------------------------------------------------
//  本核只处理 "A 通道该不该放行" 这件事: 吃 A/D 的控制字段 (valid/ready/opcode/
//  size/source/address), 吐出 in_a_ready 与 out_a_valid。A/D 的载荷 (data/mask/
//  address/prot/denied/corrupt ...) 修正器**一个比特都不碰**, 由 wrapper 直连,
//  这跟 Chisel 里的 `out.a <> in.a` / `in.d <> out.d` 是一回事。
//
//  复位域 (照 golden 抄, 三类各不相同, 别统一):
//    · a_beats_left / d_beats_left / flight[*]  —— **异步**复位清 0
//      (golden: always @(posedge clock or posedge reset))
//    · group_domain[*] (96 个) —— **完全不复位**, 纯 RegEnable
//      (golden: 单独一个 always @(posedge clock), 无 reset 分支)
//      → UT 必须 +vcs+initreg+random 与 +vcs+initreg+0 两轮都过。
// =============================================================================
module xs_TLFIFOFixer_core
  import tlfifofixer_pkg::*;
(
  input  logic                clock,
  input  logic                reset,

  // A 通道 (上游 in → 下游 out) 的控制字段
  input  logic                in_a_valid,
  input  logic [OPCODE_W-1:0] in_a_opcode,
  input  logic [SIZE_W-1:0]   in_a_size,
  input  logic [SOURCE_W-1:0] in_a_source,
  input  logic [ADDR_W-1:0]   in_a_address,
  input  logic                out_a_ready,
  output logic                in_a_ready,
  output logic                out_a_valid,

  // D 通道 (下游 out → 上游 in) 的控制字段
  input  logic                in_d_ready,
  input  logic                out_d_valid,
  input  logic [OPCODE_W-1:0] out_d_opcode,
  input  logic [SIZE_W-1:0]   out_d_size,
  input  logic [SOURCE_W-1:0] out_d_source
);

  // ---------------------------------------------------------------------------
  //  1. 地址 → FIFO 域 (纯组合, 无状态)
  // ---------------------------------------------------------------------------
  //  见 tlfifofixer_pkg 里 REGION_MAP 的说明: 只看 address[48] 与 address[30:12]。
  //  16 条区间互不相交, 所以"先命中先赢"与"全匹配求或"等价; 这里写成优先级形式
  //  纯粹是好读。
  logic [REGION_W-1:0] a_region_key;
  logic [DOMAIN_W-1:0] a_domain;
  logic                a_no_domain;

  assign a_region_key = {in_a_address[48], in_a_address[30:12]};

  always_comb begin
    a_domain = DOMAIN_DEFAULT;
    for (int r = 0; r < NUM_REGION; r++) begin
      if ((a_region_key & REGION_MAP[r].care) == REGION_MAP[r].base) begin
        a_domain = REGION_MAP[r].domain;
        break;
      end
    end
  end

  assign a_no_domain = (a_domain == DOMAIN_NONE);

  // ---------------------------------------------------------------------------
  //  2. 拍计数: 认出每条消息的首拍
  // ---------------------------------------------------------------------------
  //  TileLink 的一条消息可能占多拍 (size > log2(beatBytes))。只有**首拍**才代表
  //  "一次新请求/新响应", 中间拍不能重复置/清 flight, 也不该触发 stall 判定。
  //
  //  beats-1 的算法照搬 golden: ~((13'h3F << size)[5:3])。beatBytes = 8 (data 64 位),
  //  故 size<=3 → 1 拍 (计数 0), size=4 → 2 拍, ... size=6 → 8 拍。
  //  A 侧 opcode[2]=1 (Get/Intent/Acquire*) 表示无数据 → 恒 1 拍;
  //  D 侧 opcode[0]=1 (AccessAckData/GrantData) 表示有数据 → 才多拍。
  //  注意两边的 opcode 判据**极性相反**, 是 TileLink 编码使然, 不是笔误。
  logic [BEAT_W-1:0] a_beats_left, d_beats_left;
  logic              a_first, d_first;
  logic              a_fire,  d_fire;

  function automatic logic [BEAT_W-1:0] beats_minus_one(input logic [SIZE_W-1:0] size);
    logic [12:0] shifted;
    shifted = 13'h3F << size;
    return ~shifted[5:3];
  endfunction

  assign a_first = (a_beats_left == '0);
  assign d_first = (d_beats_left == '0);

  // in_a_ready 由本核自己驱动 (= out_a_ready & ~stall), 所以 a_fire 无组合环:
  // stall 只依赖寄存器和 A 通道输入, 不依赖 in_a_valid/ready。
  assign a_fire = in_a_ready & in_a_valid;
  // D 通道全程直通 (in.d <> out.d), 所以 in.d.fire 就是 in_d_ready & out_d_valid;
  // golden 也正是写成 auto_in_d_ready & auto_out_d_valid。
  assign d_fire = in_d_ready & out_d_valid;

  // ---------------------------------------------------------------------------
  //  3. flight: 每个 source id 一位 "有请求在飞"
  // ---------------------------------------------------------------------------
  //  ★ golden 的更新方程是
  //        flight[i] <= ~(clr & d_source==i) & ((set & a_source==i) | flight[i])
  //    —— 清**包在最外层**, 所以同一拍既置又清时**清赢**。下面写成"先置后清"的
  //    两条 if, 语义与之逐位相同, 但比 96×128 条展平表达式好读得多。
  logic                    flight [END_SOURCE_ID];
  logic                    a_track_set, d_track_clr;

  // ★ Chisel 写的是 `flight(source) := !a_notFIFO`, 但 golden 里置入的是常数 1:
  //   a_notFIFO = edgeIn.manager.fastProperty(addr, _.fifoId != Some(0)) 在本例化下
  //   被常量折叠成 0 (证据: golden 的 auto_out_a_valid = auto_in_a_valid & ~stall,
  //   若 a_notFIFO 非常数, Chisel 的 `in.a.valid && (a_notFIFO || !stall)` 会留下它)。
  //   以 golden 为准 → 置 1, 且 group_domain 的写使能里也没有 !a_notFIFO 这一项。
  assign a_track_set = a_first & a_fire;
  // ReleaseAck 是 C 通道 Release 的应答, 不对应任何 A 请求, 不能拿它清 flight。
  assign d_track_clr = d_first & (out_d_opcode != D_OPCODE_RELEASE_ACK) & d_fire;

  // ---------------------------------------------------------------------------
  //  4. 每个 master 组的 "上次打的域" 与 stall 判定
  // ---------------------------------------------------------------------------
  logic                     group_sel   [NUM_MASTERS];
  logic                     group_busy  [NUM_MASTERS];
  logic                     group_stall [NUM_MASTERS];
  logic [DOMAIN_W-1:0]      group_domain[NUM_MASTERS];   // ★ 无复位寄存器
  logic                     stall;

  always_comb begin
    stall = 1'b0;
    for (int g = 0; g < NUM_MASTERS; g++) begin
      group_sel[g]  = (in_a_source[SOURCE_W-1:GROUP_W] == MASTER_IDX_W'(g));
      group_busy[g] = 1'b0;
      for (int k = 0; k < GROUP_SIZE; k++)
        group_busy[g] |= flight[g * GROUP_SIZE + k];
      // "这组还有在飞请求, 而本拍要打的是另一个域(或压根判不出域)" → 必须等
      group_stall[g] = group_sel[g] & a_first & group_busy[g]
                     & (a_no_domain | (group_domain[g] != a_domain));
      stall |= group_stall[g];
    end
  end

  assign in_a_ready  = out_a_ready & ~stall;
  assign out_a_valid = in_a_valid  & ~stall;

  // ---------------------------------------------------------------------------
  //  5. 时序: 异步复位域 (拍计数 + flight)
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      a_beats_left <= '0;
      d_beats_left <= '0;
      for (int i = 0; i < END_SOURCE_ID; i++) flight[i] <= 1'b0;
    end
    else begin
      if (a_fire)
        a_beats_left <= a_first
                      ? (in_a_opcode[2] ? BEAT_W'(0) : beats_minus_one(in_a_size))
                      : BEAT_W'(a_beats_left - 1'b1);
      // ★ D 侧计数器**不看** ReleaseAck: golden 的使能只有 in.d.fire。
      //   ReleaseAck 无数据 (opcode[0]=0) → 载入 0, 本来也就是一拍。
      if (d_fire)
        d_beats_left <= d_first
                      ? (out_d_opcode[0] ? beats_minus_one(out_d_size) : BEAT_W'(0))
                      : BEAT_W'(d_beats_left - 1'b1);

      // 先置后清: 同拍冲突时清赢 (与 golden 的 ~clr & (set|q) 一致)
      if (a_track_set && in_a_source < SOURCE_W'(END_SOURCE_ID))
        flight[in_a_source] <= 1'b1;
      if (d_track_clr && out_d_source < SOURCE_W'(END_SOURCE_ID))
        flight[out_d_source] <= 1'b0;
    end
  end

  // ---------------------------------------------------------------------------
  //  6. 时序: 无复位域 (group_domain)
  // ---------------------------------------------------------------------------
  //  ★ golden 把这 96 个寄存器放在**另一个** always @(posedge clock) 里, 没有 reset
  //    分支 —— 它们复位后是 X/随机。这不要紧: 只有 group_busy[g] 为真时才读它, 而
  //    group_busy[g] 为真意味着此前至少发生过一次本组的 A fire, 那一拍就写过它。
  //    照抄这个复位域, 不要"顺手"给它加复位。
  always_ff @(posedge clock) begin
    for (int g = 0; g < NUM_MASTERS; g++)
      if (a_fire && group_sel[g])
        group_domain[g] <= a_domain;
  end

endmodule

// =============================================================================
//  TLFIFOFixer —— golden 同名 wrapper
// -----------------------------------------------------------------------------
//  端口与 golden TLFIFOFixer 逐位同名同宽 (48 个端口, 由 port_contract_lint 把关)。
//  本层只做两件事:
//    1. 把 A/D 的**载荷**原样短接 —— 修正器只管"放不放行", 不改任何数据位。
//    2. 把 A/D 的**控制**字段接给 u_core, 由它算 in_a_ready / out_a_valid。
//  golden 里这层同样是 29 行纯 assign (TLFIFOFixer.sv 尾部)。
// =============================================================================
module TLFIFOFixer (
  input  logic        clock,
  input  logic        reset,
  output logic        auto_in_a_ready,
  input  logic        auto_in_a_valid,
  input  logic [3:0]  auto_in_a_bits_opcode,
  input  logic [2:0]  auto_in_a_bits_size,
  input  logic [13:0] auto_in_a_bits_source,
  input  logic [48:0] auto_in_a_bits_address,
  input  logic        auto_in_a_bits_user_amba_prot_bufferable,
  input  logic        auto_in_a_bits_user_amba_prot_modifiable,
  input  logic        auto_in_a_bits_user_amba_prot_readalloc,
  input  logic        auto_in_a_bits_user_amba_prot_writealloc,
  input  logic        auto_in_a_bits_user_amba_prot_privileged,
  input  logic        auto_in_a_bits_user_amba_prot_secure,
  input  logic        auto_in_a_bits_user_amba_prot_fetch,
  input  logic [7:0]  auto_in_a_bits_mask,
  input  logic [63:0] auto_in_a_bits_data,
  input  logic        auto_in_d_ready,
  output logic        auto_in_d_valid,
  output logic [3:0]  auto_in_d_bits_opcode,
  output logic [2:0]  auto_in_d_bits_size,
  output logic [13:0] auto_in_d_bits_source,
  output logic        auto_in_d_bits_denied,
  output logic [63:0] auto_in_d_bits_data,
  output logic        auto_in_d_bits_corrupt,
  input  logic        auto_out_a_ready,
  output logic        auto_out_a_valid,
  output logic [3:0]  auto_out_a_bits_opcode,
  output logic [2:0]  auto_out_a_bits_size,
  output logic [13:0] auto_out_a_bits_source,
  output logic [48:0] auto_out_a_bits_address,
  output logic        auto_out_a_bits_user_amba_prot_bufferable,
  output logic        auto_out_a_bits_user_amba_prot_modifiable,
  output logic        auto_out_a_bits_user_amba_prot_readalloc,
  output logic        auto_out_a_bits_user_amba_prot_writealloc,
  output logic        auto_out_a_bits_user_amba_prot_privileged,
  output logic        auto_out_a_bits_user_amba_prot_secure,
  output logic        auto_out_a_bits_user_amba_prot_fetch,
  output logic [7:0]  auto_out_a_bits_mask,
  output logic [63:0] auto_out_a_bits_data,
  output logic        auto_out_d_ready,
  input  logic        auto_out_d_valid,
  input  logic [3:0]  auto_out_d_bits_opcode,
  input  logic [2:0]  auto_out_d_bits_size,
  input  logic [13:0] auto_out_d_bits_source,
  input  logic        auto_out_d_bits_denied,
  input  logic [63:0] auto_out_d_bits_data,
  input  logic        auto_out_d_bits_corrupt
);

  // ---- A 载荷: 修正器一位不改, 原样透传 (Chisel: out.a <> in.a) ----
  assign auto_out_a_bits_opcode = auto_in_a_bits_opcode;
  assign auto_out_a_bits_size = auto_in_a_bits_size;
  assign auto_out_a_bits_source = auto_in_a_bits_source;
  assign auto_out_a_bits_address = auto_in_a_bits_address;
  assign auto_out_a_bits_user_amba_prot_bufferable = auto_in_a_bits_user_amba_prot_bufferable;
  assign auto_out_a_bits_user_amba_prot_modifiable = auto_in_a_bits_user_amba_prot_modifiable;
  assign auto_out_a_bits_user_amba_prot_readalloc = auto_in_a_bits_user_amba_prot_readalloc;
  assign auto_out_a_bits_user_amba_prot_writealloc = auto_in_a_bits_user_amba_prot_writealloc;
  assign auto_out_a_bits_user_amba_prot_privileged = auto_in_a_bits_user_amba_prot_privileged;
  assign auto_out_a_bits_user_amba_prot_secure = auto_in_a_bits_user_amba_prot_secure;
  assign auto_out_a_bits_user_amba_prot_fetch = auto_in_a_bits_user_amba_prot_fetch;
  assign auto_out_a_bits_mask = auto_in_a_bits_mask;
  assign auto_out_a_bits_data = auto_in_a_bits_data;

  // ---- D 通道: 完全直通, 修正器不参与 (Chisel: in.d <> out.d) ----
  assign auto_in_d_valid  = auto_out_d_valid;
  assign auto_in_d_bits_opcode = auto_out_d_bits_opcode;
  assign auto_in_d_bits_size = auto_out_d_bits_size;
  assign auto_in_d_bits_source = auto_out_d_bits_source;
  assign auto_in_d_bits_denied = auto_out_d_bits_denied;
  assign auto_in_d_bits_data = auto_out_d_bits_data;
  assign auto_in_d_bits_corrupt = auto_out_d_bits_corrupt;
  assign auto_out_d_ready = auto_in_d_ready;

  // ---- A 通道握手: 唯一被修正器动过手脚的地方 ----
  xs_TLFIFOFixer_core u_core (
    .clock        (clock),
    .reset        (reset),
    .in_a_valid   (auto_in_a_valid),
    .in_a_opcode  (auto_in_a_bits_opcode),
    .in_a_size    (auto_in_a_bits_size),
    .in_a_source  (auto_in_a_bits_source),
    .in_a_address (auto_in_a_bits_address),
    .out_a_ready  (auto_out_a_ready),
    .in_a_ready   (auto_in_a_ready),
    .out_a_valid  (auto_out_a_valid),
    .in_d_ready   (auto_in_d_ready),
    .out_d_valid  (auto_out_d_valid),
    .out_d_opcode (auto_out_d_bits_opcode),
    .out_d_size   (auto_out_d_bits_size),
    .out_d_source (auto_out_d_bits_source)
  );

endmodule

// =============================================================================
//  规模核算 —— golden TLFIFOFixer.sv 89,271 行都去哪了
// -----------------------------------------------------------------------------
//  (行号区间对 G1-canonical/golden-rtl/TLFIFOFixer.sv,
//   sha256 e9c9e2b505805a50896362d9db6d17e079076fcaf0085a41c260cbcc3c92c6d7)
//
//      1 -    86      86 行   0.10 pct  firtool 随机化宏头 (每个文件都一样的样板)
//     87 -   135      49 行   0.05 pct  端口表 (48 个端口)
//    138 -   347     210 行   0.24 pct  ★ a_id 地址译码 —— 真逻辑, 已反解成 16 条区间表
//    348 -   351       4 行             a_noDomain / 拍计数器声明
//    352 - 12640  12,289 行  13.77 pct  flight_0..flight_12287 的 reg 声明 (一位一条)
//  12641 - 12832     192 行   0.22 pct  96 组的 stalls_a_sel 线 + stalls_id 寄存器
//  12833 - 15176   2,344 行   2.63 pct  stall 的或树 (96 组 x 128 项 flight 求或)
//  15177 - 64544  49,368 行  55.30 pct  ★ always 块: 12,288 条 flight 复位 + 12,288 条
//                                        更新 (每条 3 行) + 96 条 stalls_id RegEnable
//  64545 - 89241  24,697 行  27.66 pct  `ifdef ENABLE_INITIAL_REG_ 随机化初始化 (仿真专用)
//  89242 - 89270      29 行   0.03 pct  输出直通 assign
//
//  → **真正不同的逻辑约 250 行 (0.3 pct)**。其余 99.7 pct 全是 firtool 把一个 12,288 位
//    向量按位展平 + 随机化样板。这跟 Predictor(2 pct 真逻辑)/LoadQueueReplay 同类:
//    "大得可疑" 先量再动手, 不要被行数吓到。
//
//  子模块: **零个**。本文件只有 module TLFIFOFixer 一个模块 (grep '^module' 命中 1 条),
//  没有任何实例化, 也没有厂商宏。是一个真叶子。
// =============================================================================
