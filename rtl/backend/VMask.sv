// =============================================================================
// VMask.sv —— 向量掩码运算单元（yunsuan VMask，三级流水，VLEN=128）
//
// 位置：香山后端 VIAlu（向量整数 ALU）里专做"掩码类"指令的子单元。输入一条向量 uop
//   （128 位 vs1/vs2/old_vd/v0 掩码 + vl/vstart/vm/ma/ta/uopIdx + 元素宽度 vdType），
//   两拍后在 io_out_vd 给出 128 位结果。负责 7 条指令（opcode 见 vmask_pkg）：
//     vcpop.m   数 vs2 掩码里 1 的个数（结果放 vd 最低字节，借 vs1 低 8 位做"上一段累加值"）
//     vfirst.m  找 vs2 掩码里第一个 1 的下标（没有则全 1，即 -1）
//     vmsbf.m / vmsif.m / vmsof.m   set-before-first / set-including-first / set-only-first
//     viota.m   每个元素写"它之前掩码 1 的个数"（前缀计数，跨 uop 靠 vs1 传累加值）
//     vid.v     每个元素写自己的下标（= 对全 1 掩码做 viota）
// 流水：
//   §1 stage 0（组合，读输入）：算出"有效掩码位" vs2m（vs2 & v0 & 下标<vl）、本 uop 负责的
//      元素起点、剩余 vl/vstart，并把要用的东西打进 s1 寄存器。
//   §2 stage 1：vmsbf/vmsif/vmsof/vfirst 在 vs2m 上算；viota/vid/vcpop 做前缀 popcount；
//      结果写入 vd_reg。控制量再打一拍进 s2 寄存器。
//   §3 stage 2：按 vstart/vl/掩码/ma/ta 把 vd_reg 与 old_vd 拼成最终输出。
// 怪癖（照 golden 保留，都对着 Scala 源与 golden 逐条核过）：
//   · s1 寄存器只在 fire 时更新，s2 寄存器只在 fire_reg_s1 时更新；fire_reg_s1 本身不复位，
//     其余寄存器异步复位到 0；
//   · vs1 打满 128 位进 s1（只用低 8 位）—— 照 golden 位宽，不收窄；
//   · vcpop / uopIdx 奇数 的结果取 one_cnt[ele_cnt]；ele_cnt 寄存器取 17..31 时 golden
//     （firtool 越界展开）读 one_cnt[0]，这里同样处理；
//   · mask 类 (vmsbf/if/of) 的尾部是"全 1"而不是 old_vd（old_vd_vl_mask = ~0 << vl）；
//   · vd_vl_mask 的移位量是 8 位的 (128 - vl)，vl=0 时为 128（得 0），vl>128 时回绕。
// Chisel 源：yunsuan/src/main/scala/yunsuan/vector/VectorALU/VMask.scala（yunsuan@9559211）。
// golden 对照：G1-canonical/golden-rtl/VMask.sv（无子模块）。
// =============================================================================
package vmask_pkg;
  // VAluOpcode（yunsuan VAluDecode.scala）里本单元负责的 7 个编码
  localparam logic [5:0] OP_VCPOP  = 6'd39;
  localparam logic [5:0] OP_VFIRST = 6'd40;
  localparam logic [5:0] OP_VMSBF  = 6'd41;
  localparam logic [5:0] OP_VMSIF  = 6'd42;
  localparam logic [5:0] OP_VMSOF  = 6'd43;
  localparam logic [5:0] OP_VIOTA  = 6'd44;
  localparam logic [5:0] OP_VID    = 6'd45;

  localparam int VLEN  = 128;
  localparam int VLENB = VLEN / 8;  // 16 字节
endpackage

module xs_VMask_core
  import vmask_pkg::*;
(
  input  logic             clock,
  input  logic             reset,
  input  logic             in_valid,   // fire
  input  logic [5:0]       op,
  input  logic             vm,         // 1 = 不受 v0 掩码约束
  input  logic             ma,         // mask-agnostic：被掩掉的元素写全 1
  input  logic             ta,         // tail-agnostic：尾部元素写全 1
  input  logic [7:0]       vl,
  input  logic [6:0]       vstart,
  input  logic [5:0]       uop_idx,
  input  logic [3:0]       vd_type,    // 低 2 位 = SEW（0/1/2/3 = 8/16/32/64 位）
  input  logic [VLEN-1:0]  vs1,
  input  logic [VLEN-1:0]  vs2,
  input  logic [VLEN-1:0]  old_vd,
  input  logic [VLEN-1:0]  mask,       // v0
  output logic [VLEN-1:0]  vd
);

  // ===========================================================================
  // §1 stage 0：译码 + 有效掩码位 + 本 uop 的元素范围
  // ===========================================================================
  logic       vcpop_m, vfirst_m, vmsbf_m, vmsif_m, vmsof_m, viota_m, vid_v;
  assign vcpop_m  = (op == OP_VCPOP);
  assign vfirst_m = (op == OP_VFIRST);
  assign vmsbf_m  = (op == OP_VMSBF);
  assign vmsif_m  = (op == OP_VMSIF);
  assign vmsof_m  = (op == OP_VMSOF);
  assign viota_m  = (op == OP_VIOTA);
  assign vid_v    = (op == OP_VID);

  logic [1:0] vsew;
  assign vsew = vd_type[1:0];

  // 一个 uop（128 位 vd）能放下的元素数 = 16 >> vsew = 1 << (4 - vsew)。
  // Scala 写成 Cat(0, ~vsew) + 1（3 位），即 4/3/2/1。
  logic [2:0] log2_elems_per_uop;
  assign log2_elems_per_uop = 3'({1'b0, ~vsew} + 3'd1);

  // 本 uop 负责的第一个元素的下标。vcpop 每个 uop 吃一段；viota/vid 的 uop 成对出现
  // （uopIdx 偶数写结果、奇数只算这一段的 1 的个数传给下一段），所以用 uopIdx[5:1]。
  logic [12:0] uop_first_elem;
  assign uop_first_elem = vcpop_m ? (13'(uop_idx)      << log2_elems_per_uop)
                                  : (13'(uop_idx[5:1]) << log2_elems_per_uop);

  // 本 uop 起点之后还剩多少个元素在 vl 之内（8 位截断，照 golden），再折成字节数。
  logic [7:0]  vl_remain;
  logic [10:0] vl_remain_bytes;
  assign vl_remain       = (13'(vl) >= uop_first_elem) ? 8'(13'(vl) - uop_first_elem) : 8'd0;
  assign vl_remain_bytes = 11'(vl_remain) << vsew;

  // vid 的 vstart 也要折算到本 uop 内（其他指令恒 0）
  logic [6:0] vstart_remain;
  assign vstart_remain = !vid_v ? 7'd0
                       : (13'(vstart) >= uop_first_elem) ? 7'(13'(vstart) - uop_first_elem)
                       : 7'd0;

  logic [4:0] ele_cnt;   // 一个 uop 的元素数：16/8/4/2
  assign ele_cnt = 5'd16 >> vsew;

  // 有效掩码位：vs2 的第 i 位，被 v0 选中（或 vm=1）且 i < vl 才算数。
  // （Scala 还额外用 fire 门控；但用到它的寄存器本来就只在 fire 时写，门控不可观测。）
  logic [VLEN-1:0] vs2m;
  always_comb begin
    for (int i = 0; i < VLEN; i++)
      vs2m[i] = vs2[i] & (mask[i] | vm) & (8'(i) < vl);
  end

  // viota/vid/vcpop：把本 uop 负责的那段掩码移到最低位，取 16 位；vid 视同全 1 掩码。
  logic [VLEN-1:0] vs2m_uop;
  logic [15:0]     vs2m_uop_vid;
  assign vs2m_uop     = vs2m >> uop_first_elem;
  assign vs2m_uop_vid = vid_v ? 16'hFFFF : vs2m_uop[15:0];

  // ---- s1 寄存器（fire 时更新） ----
  logic            fire_reg_s1;          // 不复位（Scala RegNext）
  logic [7:0]      vl_reg_s1;
  logic [6:0]      vstart_reg_s1;
  logic            vm_reg_s1, ma_reg_s1, ta_reg_s1;
  logic [1:0]      vsew_reg_s1;
  logic [5:0]      uopIdx_reg_s1;
  logic [10:0]     vlRemainBytes_reg_s1;
  logic [VLEN-1:0] vs1_reg_s1;           // 只读低 8 位（golden 照样打满 128 位）
  logic [4:0]      ele_cnt_reg_s1;
  logic [VLEN-1:0] old_vd_reg_s1;
  logic [VLEN-1:0] vmask_reg_s1;
  logic            vcpop_m_reg_s1, vfirst_m_reg_s1, vmsbf_m_reg_s1, vmsif_m_reg_s1;
  logic            vmsof_m_reg_s1, viota_m_reg_s1, vid_v_reg_s1;
  logic [VLEN-1:0] vs2m_reg_s1;
  logic [15:0]     vs2m_uop_vid_reg_s1;
  logic [6:0]      vstartRemain_reg_s1;

  always_ff @(posedge clock)
    fire_reg_s1 <= in_valid;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      vl_reg_s1            <= '0;
      vstart_reg_s1        <= '0;
      vm_reg_s1            <= 1'b0;
      ma_reg_s1            <= 1'b0;
      ta_reg_s1            <= 1'b0;
      vsew_reg_s1          <= '0;
      uopIdx_reg_s1        <= '0;
      vlRemainBytes_reg_s1 <= '0;
      vs1_reg_s1           <= '0;
      ele_cnt_reg_s1       <= '0;
      old_vd_reg_s1        <= '0;
      vmask_reg_s1         <= '0;
      vcpop_m_reg_s1       <= 1'b0;
      vfirst_m_reg_s1      <= 1'b0;
      vmsbf_m_reg_s1       <= 1'b0;
      vmsif_m_reg_s1       <= 1'b0;
      vmsof_m_reg_s1       <= 1'b0;
      viota_m_reg_s1       <= 1'b0;
      vid_v_reg_s1         <= 1'b0;
      vs2m_reg_s1          <= '0;
      vs2m_uop_vid_reg_s1  <= '0;
      vstartRemain_reg_s1  <= '0;
    end else if (in_valid) begin
      vl_reg_s1            <= vl;
      vstart_reg_s1        <= vstart;
      vm_reg_s1            <= vm;
      ma_reg_s1            <= ma;
      ta_reg_s1            <= ta;
      vsew_reg_s1          <= vsew;
      uopIdx_reg_s1        <= uop_idx;
      vlRemainBytes_reg_s1 <= vl_remain_bytes;
      vs1_reg_s1           <= vs1;
      ele_cnt_reg_s1       <= ele_cnt;
      old_vd_reg_s1        <= old_vd;
      vmask_reg_s1         <= mask;
      vcpop_m_reg_s1       <= vcpop_m;
      vfirst_m_reg_s1      <= vfirst_m;
      vmsbf_m_reg_s1       <= vmsbf_m;
      vmsif_m_reg_s1       <= vmsif_m;
      vmsof_m_reg_s1       <= vmsof_m;
      viota_m_reg_s1       <= viota_m;
      vid_v_reg_s1         <= vid_v;
      vs2m_reg_s1          <= vs2m;
      vs2m_uop_vid_reg_s1  <= vs2m_uop_vid;
      vstartRemain_reg_s1  <= vstart_remain;
    end
  end

  // ===========================================================================
  // §2 stage 1：在打过拍的 vs2m 上算各指令的原始结果，写进 vd_reg
  // ===========================================================================
  // vmsbf：第 i 位 = vs2m[i:0] 全 0（"第一个 1 之前"）；vmsif 多含第一个 1 本身；
  // vmsof = 只有第一个 1。vfirst = 第一个 1 的下标，没有则 64 位全 1。
  logic [VLEN-1:0] vmsbf, vmsif, vmsof;
  logic [63:0]     vmfirst;
  always_comb begin
    logic seen;
    seen = 1'b0;
    for (int i = 0; i < VLEN; i++) begin
      seen     = seen | vs2m_reg_s1[i];
      vmsbf[i] = ~seen;
    end
    vmfirst = '1;
    for (int i = VLEN - 1; i >= 0; i--)
      if (vs2m_reg_s1[i]) vmfirst = 64'(i);
  end
  assign vmsif = {vmsbf[VLEN-2:0], 1'b1};
  assign vmsof = ~vmsbf & vmsif;

  // viota/vid/vcpop：one_cnt[k] = 上一段累加值(vs1 低 8 位) + 本段前 k 个元素里 1 的个数。
  // 本段只有 16>>vsew 个元素，超出的 k 不计数（只剩累加值）。
  logic [4:0] one_cnt_uop [VLENB+1];
  logic [7:0] one_cnt     [VLENB+1];
  always_comb begin
    logic [4:0] prefix_pop;
    prefix_pop     = '0;
    one_cnt_uop[0] = '0;
    for (int k = 1; k <= VLENB; k++) begin
      prefix_pop     = prefix_pop + 5'(vs2m_uop_vid_reg_s1[k-1]);
      one_cnt_uop[k] = (k <= (VLENB >> vsew_reg_s1)) ? prefix_pop : 5'd0;
    end
    for (int k = 0; k <= VLENB; k++)
      one_cnt[k] = 8'(vs1_reg_s1[7:0] + 8'(one_cnt_uop[k]));
  end

  // 总数：one_cnt[ele_cnt]（ele_cnt 越界 17..31 时读 one_cnt[0]，同 golden）
  logic [7:0] one_cnt_total;
  always_comb begin
    one_cnt_total = one_cnt[0];
    for (int k = 1; k <= VLENB; k++)
      if (ele_cnt_reg_s1 == 5'(k)) one_cnt_total = one_cnt[k];
  end

  logic [VLEN-1:0] one_cnt_packed;   // 前 16 个前缀计数按字节拼成 128 位
  always_comb begin
    for (int k = 0; k < VLENB; k++)
      one_cnt_packed[8*k +: 8] = one_cnt[k];
  end

  logic vid_or_iota_s1;
  assign vid_or_iota_s1 = vid_v_reg_s1 | viota_m_reg_s1;

  logic [VLEN-1:0] vd_reg;   // stage 1 结果寄存器（优先级同 Scala when 链）
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      vd_reg <= '0;
    else if (vmsbf_m_reg_s1 & fire_reg_s1)
      vd_reg <= vmsbf;
    else if (vmsif_m_reg_s1 & fire_reg_s1)
      vd_reg <= vmsif;
    else if (vmsof_m_reg_s1 & fire_reg_s1)
      vd_reg <= vmsof;
    else if (vfirst_m_reg_s1 & fire_reg_s1)
      vd_reg <= {64'd0, vmfirst};
    else if (vid_or_iota_s1 & fire_reg_s1 & ~uopIdx_reg_s1[0])
      vd_reg <= one_cnt_packed;                         // 偶数 uop：逐元素前缀计数
    else if ((vid_or_iota_s1 & uopIdx_reg_s1[0] | vcpop_m_reg_s1) & fire_reg_s1)
      vd_reg <= {120'd0, one_cnt_total};                // 奇数 uop / vcpop：段总数
  end

  // ---- s2 寄存器（fire_reg_s1 时把 s1 控制量再打一拍） ----
  logic [7:0]      vl_reg;
  logic [6:0]      vstart_reg;
  logic            vm_reg, ma_reg, ta_reg;
  logic [1:0]      vsew_reg;
  logic [5:0]      uopIdx_reg;
  logic [10:0]     vlRemainBytes_reg;
  logic [6:0]      vstartRemain_reg;
  logic [VLEN-1:0] old_vd_reg;
  logic [VLEN-1:0] vmask_reg;
  logic            reg_vcpop_m, reg_vfirst_m, reg_vmsbf_m, reg_vmsif_m, reg_vmsof_m;
  logic            reg_viota_m, reg_vid_v;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      vl_reg            <= '0;
      vstart_reg        <= '0;
      vm_reg            <= 1'b0;
      ma_reg            <= 1'b0;
      ta_reg            <= 1'b0;
      vsew_reg          <= '0;
      uopIdx_reg        <= '0;
      vlRemainBytes_reg <= '0;
      vstartRemain_reg  <= '0;
      old_vd_reg        <= '0;
      vmask_reg         <= '0;
      reg_vcpop_m       <= 1'b0;
      reg_vfirst_m      <= 1'b0;
      reg_vmsbf_m       <= 1'b0;
      reg_vmsif_m       <= 1'b0;
      reg_vmsof_m       <= 1'b0;
      reg_viota_m       <= 1'b0;
      reg_vid_v         <= 1'b0;
    end else if (fire_reg_s1) begin
      vl_reg            <= vl_reg_s1;
      vstart_reg        <= vstart_reg_s1;
      vm_reg            <= vm_reg_s1;
      ma_reg            <= ma_reg_s1;
      ta_reg            <= ta_reg_s1;
      vsew_reg          <= vsew_reg_s1;
      uopIdx_reg        <= uopIdx_reg_s1;
      vlRemainBytes_reg <= vlRemainBytes_reg_s1;
      vstartRemain_reg  <= vstartRemain_reg_s1;
      old_vd_reg        <= old_vd_reg_s1;
      vmask_reg         <= vmask_reg_s1;
      reg_vcpop_m       <= vcpop_m_reg_s1;
      reg_vfirst_m      <= vfirst_m_reg_s1;
      reg_vmsbf_m       <= vmsbf_m_reg_s1;
      reg_vmsif_m       <= vmsif_m_reg_s1;
      reg_vmsof_m       <= vmsof_m_reg_s1;
      reg_viota_m       <= viota_m_reg_s1;
      reg_vid_v         <= vid_v_reg_s1;
    end
  end

  // ===========================================================================
  // §3 stage 2：按 vstart / vl / 掩码 / ma / ta 拼最终结果
  // ===========================================================================
  logic [2:0] log2_elems_per_uop_s2;
  assign log2_elems_per_uop_s2 = 3'({1'b0, ~vsew_reg} + 3'd1);

  // ---- viota/vid 偶数 uop：逐元素结果 ----
  // vd_reg 里是 16 个字节计数；按 SEW 摊到元素的最低字节（元素其余字节为 0）。
  logic [VLEN-1:0] vid_vd;
  always_comb begin
    vid_vd = '0;
    for (int i = 0; i < VLENB; i++) begin
      case (vsew_reg)
        2'd0: vid_vd[8*i +: 8] = vd_reg[8*i +: 8];
        2'd1: if (i % 2 == 0) vid_vd[8*i +: 8] = vd_reg[8*(i/2) +: 8];
        2'd2: if (i % 4 == 0) vid_vd[8*i +: 8] = vd_reg[8*(i/4) +: 8];
        default: if (i % 8 == 0) vid_vd[8*i +: 8] = vd_reg[8*(i/8) +: 8];
      endcase
    end
  end

  // 每个字节是否"活"：所属元素被 v0 选中（或 vm=1），且在本 uop 剩余 vl 之内。
  logic [VLEN-1:0] vmask_bits;     // 本 uop 那段 v0 移到最低位
  logic [15:0]     vmask_bits_lo;
  logic [VLEN-1:0] vmask_vd_bits;  // 活字节 = 0xFF
  assign vmask_bits    = vmask_reg >> (13'(uopIdx_reg[5:1]) << log2_elems_per_uop_s2);
  assign vmask_bits_lo = vmask_bits[15:0];
  always_comb begin
    for (int i = 0; i < VLENB; i++) begin
      logic elem_masked_off;
      logic [15:0] elem_bits;
      elem_bits       = vmask_bits_lo >> (4'(i) >> vsew_reg);   // 字节 i 属于元素 i>>vsew
      elem_masked_off = ~vm_reg & ~elem_bits[0];
      vmask_vd_bits[8*i +: 8] = (elem_masked_off | (11'(i) >= vlRemainBytes_reg)) ? 8'h00 : 8'hFF;
    end
  end

  // 被掩掉的字节：ma=1 写全 1，否则保留 old_vd
  logic [VLEN-1:0] vmask_vd, vid_mask_vd;
  assign vmask_vd    = ma_reg ? ~vmask_vd_bits : (old_vd_reg & ~vmask_vd_bits);
  assign vid_mask_vd = (vid_vd & vmask_vd_bits) | vmask_vd;

  // vstart 之前的字节保留 old_vd（vstart 字节数封顶 16）
  logic [9:0]      vstart_remain_bytes;
  logic [9:0]      vstart_bytes;
  logic [VLEN-1:0] vmask_vstart_bits, vstart_old_vd;
  assign vstart_remain_bytes = 10'(vstartRemain_reg) << vsew_reg;
  assign vstart_bytes        = (vstart_remain_bytes >= 10'd16) ? 10'd16 : vstart_remain_bytes;
  assign vmask_vstart_bits   = {VLEN{1'b1}} << {vstart_bytes, 3'b000};
  assign vstart_old_vd       = old_vd_reg & ~vmask_vstart_bits;

  // 尾部（本 uop 剩余 vl 之后）的字节：ta=1 写全 1，否则保留 old_vd
  logic [10:0]     tail_bytes;
  logic [VLEN-1:0] vmask_tail_bits, vid_tail_vd, vid_tail_mask_vd;
  assign tail_bytes      = (vlRemainBytes_reg >= 11'd16) ? 11'd0 : 11'(11'd16 - vlRemainBytes_reg);
  assign vmask_tail_bits = {VLEN{1'b1}} >> {tail_bytes, 3'b000};
  assign vid_tail_vd     = ta_reg ? ~vmask_tail_bits : (old_vd_reg & ~vmask_tail_bits);
  assign vid_tail_mask_vd =
      (vid_mask_vd & vmask_tail_bits & vmask_vstart_bits) | vid_tail_vd | vstart_old_vd;

  // ---- vmsbf/vmsif/vmsof：结果本身是掩码，按位处理 ----
  // 被 v0 掩掉的位：ma=1 写 1，否则保留 old_vd；vl 及以上的位一律写 1（不是 old_vd）。
  logic [VLEN-1:0] mask_on, vd_nmask, vd_mask, mask_vd;
  logic [VLEN-1:0] old_vd_vl_mask, vd_vl_mask, tail_vd;
  assign mask_on        = vmask_reg | {VLEN{vm_reg}};
  assign vd_nmask       = ma_reg ? ~mask_on : (old_vd_reg & ~mask_on);
  assign vd_mask        = vd_reg & mask_on;
  assign mask_vd        = vd_nmask | vd_mask;
  assign old_vd_vl_mask = {VLEN{1'b1}} << vl_reg;
  assign vd_vl_mask     = {VLEN{1'b1}} >> 8'(8'd128 - vl_reg);   // 8 位减法，照 golden 回绕
  assign tail_vd        = old_vd_vl_mask | (mask_vd & vd_vl_mask);

  // ---- 输出选择（优先级同 Scala） ----
  always_comb begin
    if (({1'b0, vstart_reg} >= vl_reg) & ~reg_vfirst_m & ~reg_vcpop_m)
      vd = old_vd_reg;                       // vstart >= vl：整条不执行
    else if (reg_vmsbf_m | reg_vmsif_m | reg_vmsof_m)
      vd = tail_vd;
    else if ((reg_vid_v | reg_viota_m) & ~uopIdx_reg[0])
      vd = vid_tail_mask_vd;
    else
      vd = vd_reg;                           // vfirst / vcpop / 奇数 uop：原样输出
  end

endmodule

module VMask (
  input          clock,
  input          reset,
  input          io_in_valid,
  input  [5:0]   io_in_bits_opcode_op,
  input          io_in_bits_info_vm,
  input          io_in_bits_info_ma,
  input          io_in_bits_info_ta,
  input  [7:0]   io_in_bits_info_vl,
  input  [6:0]   io_in_bits_info_vstart,
  input  [5:0]   io_in_bits_info_uopIdx,
  input  [3:0]   io_in_bits_vdType,
  input  [127:0] io_in_bits_vs1,
  input  [127:0] io_in_bits_vs2,
  input  [127:0] io_in_bits_old_vd,
  input  [127:0] io_in_bits_mask,
  output [127:0] io_out_vd
);
  xs_VMask_core u_core (
    .clock    (clock),
    .reset    (reset),
    .in_valid (io_in_valid),
    .op       (io_in_bits_opcode_op),
    .vm       (io_in_bits_info_vm),
    .ma       (io_in_bits_info_ma),
    .ta       (io_in_bits_info_ta),
    .vl       (io_in_bits_info_vl),
    .vstart   (io_in_bits_info_vstart),
    .uop_idx  (io_in_bits_info_uopIdx),
    .vd_type  (io_in_bits_vdType),
    .vs1      (io_in_bits_vs1),
    .vs2      (io_in_bits_vs2),
    .old_vd   (io_in_bits_old_vd),
    .mask     (io_in_bits_mask),
    .vd       (io_out_vd)
  );
endmodule
