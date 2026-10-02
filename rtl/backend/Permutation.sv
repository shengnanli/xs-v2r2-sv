// =============================================================================
// Permutation.sv —— 向量置换单元（yunsuan Permutation，三级流水，VLEN=128）
//
// 位置：香山后端 VPPU（向量置换 FU）的运算核。输入一条向量 uop（128 位 vs1/vs2/old_vd/v0 +
//   vl/vstart/vm/ma/ta/vlmul/uopIdx + vs1/vs2 元素宽度 srcType），两拍后在 io_out_vd 给出 128 位结果。
//   LMUL>1 的指令由译码拆成多个 uop，每个 uop 只产出目的寄存器组里的一个 vd；本单元靠
//   uopIdx 算出"这一拍读 vs2 组的第几个寄存器（vs2Id）、写 vd 组的第几个（vdId）"。
// 负责 8 条指令（opcode 见 permutation_pkg）：
//   vslideup / vslidedown        按 vs1(rs1) 个元素整体上/下滑（uop 拆分查 slide*Vs2VdTable）
//   vslide1up / vslide1down      滑 1 个元素，空出的位置填 rs1（rs1 值放在 vs1 里送进来）
//   vrgather.vv / .vx / ei16     按下标从 vs2 组里取元素（ei16 + SEW8 是特殊拆法 vrgather16_sew8）
//   vcompress                    把 v0(=vs1) 选中的 vs2 元素按序压紧
//   vmvNr                        整寄存器搬移
// 统一把元素拆成字节处理：下标先换算成"字节下标"，按字节从 vs2 取数。
// 流水：
//   §1 stage 0（组合，读输入）：译码、uop 拆分、本 uop 剩余 vl/vstart、各指令的字节下标与
//      vcompress 的前缀计数；全部打进 reg0 寄存器。
//   §2 stage 1（读 reg0）：vcompress 压紧；slide/gather 逐字节取数，结果写 vd_reg；
//      算 tail / vstart 掩码，打进 reg1 寄存器。
//   §3 stage 2（读 reg1 与 vd_reg）：vcompress 的 ta 处理与"计数 uop"，slide/gather 的
//      tail / vstart 合成，vstart>=vl 时整体保留 old_vd。
// 怪癖（照 golden 保留，均对着 Scala 源与 golden 逐条核过）：
//   · 寄存器分两类复位域：一部分（指令类型、vl/vstart、vs1/vs2/old_vd、vd_reg 等）异步复位到 0，
//     其余 RegEnable 不复位 —— 逐个照 golden；fire_reg0 是 GatedValidRegNext（异步复位）；
//   · vs2/vs1 同时以 128 位整体（vs2_reg0/vs1_reg0）和按字节（vs2_bytes_reg0/vs1_bytes_reg0）各打一份；
//   · Chisel 用宽于 log2(16) 的 UInt 去索引 16 项 Vec 时截低 4 位（不是越界读 0）：
//     vcompress 的 out_previous_ones_sum 取 (elements-1)[3:0]、vslide1down 取 (vsew_bytes+i)[3:0]；
//   · current_ones_sum 的条件是 i < (elements-1)（5 位减法）：elements=0 时回绕成 31，条件恒真；
//   · vcompress 的 elements 是 5 位：vlRemain_vcompress / vl（8 位）赋进去被截低 5 位；
//   · vrgather 的 vrgather_vd 只在 (vrgather|vrgather_vx)&fire_reg0 时非 0，vrgather16_sew8 的半边合并照用它。
// Chisel 源：yunsuan/src/main/scala/yunsuan/vector/VectorPerm/Permutation.scala（yunsuan@9559211）。
// golden 对照：G1-canonical/golden-rtl/Permutation.sv；子模块 slideupVs2VdTable / slidednVs2VdTable
//   用本仓重写件（rtl/backend/ 同名文件，两侧白盒）。
// =============================================================================
package permutation_pkg;
  // VPermOpcode（yunsuan VPermDecode.scala）
  localparam logic [5:0] OP_VSLIDEUP    = 6'd0;
  localparam logic [5:0] OP_VSLIDEDOWN  = 6'd1;
  localparam logic [5:0] OP_VSLIDE1UP   = 6'd2;
  localparam logic [5:0] OP_VSLIDE1DOWN = 6'd3;
  localparam logic [5:0] OP_VRGATHER    = 6'd4;
  localparam logic [5:0] OP_VRGATHER_VX = 6'd5;
  localparam logic [5:0] OP_VCOMPRESS   = 6'd6;
  localparam logic [5:0] OP_VMVNR       = 6'd7;

  localparam int VLEN  = 128;
  localparam int VLENB = VLEN / 8;   // 16 字节

  // vcompress 的 uop 编排（LMUL=L 时共 L(L+1)/2+... 个 uop，按"目的 vd 组"分 8 组）：
  //   第 g 组从 uopIdx = CMPRS_GROUP_START[g] 开始，共 CMPRS_GROUP_SIZE[g] 个 uop；
  //   组内第 k 个 uop 处理 vs2 的第 k 段（k < CMPRS_GROUP_DATA[g]），
  //   第 0..6 组的最后一个 uop（1,4,8,13,19,26,34）只负责输出"累计压了多少个"。
  localparam int CMPRS_GROUP_START [8] = '{0, 2, 5, 9, 14, 20, 27, 35};
  localparam int CMPRS_GROUP_SIZE  [8] = '{2, 3, 4, 5, 6, 7, 8, 8};
  localparam int CMPRS_GROUP_DATA  [8] = '{1, 2, 3, 4, 5, 6, 7, 8};
endpackage

module xs_Permutation_core
  import permutation_pkg::*;
(
  input  logic             clock,
  input  logic             reset,
  input  logic             in_valid,     // fire
  input  logic [5:0]       op,
  input  logic             vm,
  input  logic             ma,
  input  logic             ta,
  input  logic [2:0]       vlmul,        // 0..3 = LMUL 1/2/4/8；5/6/7 = 1/8、1/4、1/2；4 保留
  input  logic [7:0]       vl,
  input  logic [6:0]       vstart,
  input  logic [5:0]       uop_idx,
  input  logic [3:0]       vs2_type,     // srcType(0)：低 2 位 = vs2 的 SEW
  input  logic [3:0]       vs1_type,     // srcType(1)：低 2 位 = vs1 的 SEW（vrgather 的下标宽度）
  input  logic [VLEN-1:0]  vs1,
  input  logic [VLEN-1:0]  vs2,
  input  logic [VLEN-1:0]  old_vd,
  input  logic [VLEN-1:0]  mask,
  output logic [VLEN-1:0]  vd
);

  localparam logic [VLEN-1:0] ALL_ONES = {VLEN{1'b1}};

  // ===========================================================================
  // §1 stage 0：译码与 uop 拆分
  // ===========================================================================
  logic vcompress, vslideup, vslidedn, vslide1up, vslide1dn, vrgather, vrgather_vx, vmvnr;
  logic vrgather16_sew8, vslide;
  assign vcompress   = (op == OP_VCOMPRESS);
  assign vslideup    = (op == OP_VSLIDEUP);
  assign vslidedn    = (op == OP_VSLIDEDOWN);
  assign vslide1up   = (op == OP_VSLIDE1UP);
  assign vslide1dn   = (op == OP_VSLIDE1DOWN);
  assign vrgather    = (op == OP_VRGATHER);
  assign vrgather_vx = (op == OP_VRGATHER_VX);
  assign vmvnr       = (op == OP_VMVNR);
  // vrgatherei16 且数据 SEW=8：下标 16 位、数据 8 位，一个 vs1 只装得下半个 vd 的下标，拆法特殊
  assign vrgather16_sew8 = vrgather & (vs1_type == 4'd1) & (vs2_type == 4'd0);
  assign vslide          = vslideup | vslide1up | vslidedn | vslide1dn;

  logic [1:0] vsew;          // 数据元素宽度（取 vs2 的）
  logic [2:0] log2_elems_per_uop;
  logic [3:0] vsew_bytes;    // 1/2/4/8
  logic [4:0] ele_cnt;       // 一个 vd 的元素数 16/8/4/2
  logic [2:0] lmul;          // 分数/保留 LMUL 折成 0
  assign vsew               = vs2_type[1:0];
  assign log2_elems_per_uop = 3'({1'b0, ~vsew} + 3'd1);
  assign vsew_bytes         = 4'd1 << vsew;
  assign ele_cnt            = 5'd16 >> vsew;
  assign lmul               = (vlmul > 3'd4) ? 3'd0 : vlmul;

  // ---- slideup / slidedown：查表得 (vs2 偏移, vd 偏移) ----
  logic [2:0] vslideup_vs2_id, vslideup_vd_id, vslidedn_vs2_id, vslidedn_vd_id;
  logic       vslidedn_is_first;
  slideupVs2VdTable vslideupOffset (
    .src          ({lmul[1:0], uop_idx}),
    .outOffsetVs2 (vslideup_vs2_id),
    .outOffsetVd  (vslideup_vd_id)
  );
  slidednVs2VdTable vslidednOffset (
    .src          ({lmul[1:0], uop_idx}),
    .outOffsetVs2 (vslidedn_vs2_id),
    .outOffsetVd  (vslidedn_vd_id),
    .outIsFirst   (vslidedn_is_first)
  );

  // ---- vrgather：LMUL=L 时 L×L 个 uop，uopIdx = vdId*L + vs2Id ----
  logic [2:0] vrgather_vd_id, vrgather_vs2_id;
  logic [1:0] vrgather16_vd_id, vrgather16_vs2_id;
  always_comb begin
    case (vlmul)
      3'd1:    begin vrgather_vd_id = 3'(uop_idx[1]);   vrgather_vs2_id = 3'(uop_idx[0]);   end
      3'd2:    begin vrgather_vd_id = 3'(uop_idx[3:2]); vrgather_vs2_id = 3'(uop_idx[1:0]); end
      3'd3:    begin vrgather_vd_id = uop_idx[5:3];     vrgather_vs2_id = uop_idx[2:0];     end
      default: begin vrgather_vd_id = 3'd0;             vrgather_vs2_id = 3'd0;             end
    endcase
    // ei16+SEW8：每个 vd 要两个 vs1，故 uopIdx 多一位（最低位选 vd 的上/下半）
    case (vlmul)
      3'd1:    begin vrgather16_vd_id = 2'(uop_idx[2]); vrgather16_vs2_id = 2'(uop_idx[1]);   end
      3'd2:    begin vrgather16_vd_id = uop_idx[4:3];   vrgather16_vs2_id = uop_idx[2:1];     end
      default: begin vrgather16_vd_id = 2'd0;           vrgather16_vs2_id = 2'd0;             end
    endcase
  end

  // 本 uop 写哪个 vd（vdId）、读哪个 vs2（vs2Id）；其他指令为 0（Scala Mux1H）
  logic [2:0] vd_id, vs2_id;
  always_comb begin
    vd_id  = 3'd0;
    vs2_id = 3'd0;
    if ((vrgather & ~vrgather16_sew8) | vrgather_vx) begin
      vd_id = vrgather_vd_id;           vs2_id = vrgather_vs2_id;
    end else if (vrgather16_sew8) begin
      vd_id = 3'(vrgather16_vd_id);     vs2_id = 3'(vrgather16_vs2_id);
    end else if (vslideup) begin
      vd_id = vslideup_vd_id;           vs2_id = vslideup_vs2_id;
    end else if (vslidedn) begin
      vd_id = vslidedn_vd_id;           vs2_id = vslidedn_vs2_id;
    end
  end

  // ---- 本 uop 剩余的 vl / v0 段（vslide1up/1down 按 uopIdx 线性切，其余按 vdId 切） ----
  logic [12:0]     slide1up_first, slide1dn_first;   // 本 uop 第一个元素的下标
  logic [7:0]      vl_remain;
  logic [VLEN-1:0] vmask_uop;
  assign slide1up_first = 13'(uop_idx)      << log2_elems_per_uop;
  assign slide1dn_first = 13'(uop_idx[5:1]) << log2_elems_per_uop;
  always_comb begin
    if (vslide1up) begin
      vl_remain = (13'(vl) >= slide1up_first) ? 8'(13'(vl) - slide1up_first) : 8'd0;
      vmask_uop = mask >> slide1up_first;
    end else if (vslide1dn) begin
      vl_remain = (13'(vl) >= slide1dn_first) ? 8'(13'(vl) - slide1dn_first) : 8'd0;
      vmask_uop = mask >> slide1dn_first;
    end else begin
      logic [7:0] vd_first;          // vdId * ele_cnt <= 7*16
      vd_first  = 8'(vd_id) * 8'(ele_cnt);
      vl_remain = (vl >= vd_first) ? 8'(vl - vd_first) : 8'd0;
      vmask_uop = mask >> vd_first;
    end
  end

  // ---- 本 uop 剩余的 vstart（vslideup 额外把 vstart 抬到 min(滑动量, 128)） ----
  logic [63:0] slide_ele;            // 滑动元素数：vslide1* 为 1，其余为 rs1（vs1 低 64 位）
  logic [66:0] slide_bytes;
  logic [7:0]  vslideup_vstart, vstart_remain;
  assign slide_ele       = (vslide1up | vslide1dn) ? 64'd1 : vs1[63:0];
  assign slide_bytes     = 67'(slide_ele) << vsew;
  assign vslideup_vstart = (vslideup & (slide_ele > 64'(vstart)))
                         ? ((slide_ele > 64'd128) ? 8'd128 : 8'(slide_ele))
                         : 8'(vstart);
  always_comb begin
    if (vslide1up)
      vstart_remain = (13'(vstart) >= slide1up_first) ? 8'(13'(vstart) - slide1up_first) : 8'd0;
    else if (vslide1dn)
      vstart_remain = (13'(vstart) >= slide1dn_first) ? 8'(13'(vstart) - slide1dn_first) : 8'd0;
    else begin
      logic [7:0] vd_first;
      vd_first      = 8'(vd_id) * 8'(ele_cnt);
      vstart_remain = (vd_id == 3'd0) ? vslideup_vstart
                    : (vslideup_vstart >= vd_first) ? 8'(vslideup_vstart - vd_first) : 8'd0;
    end
  end

  // ---- 本 uop 读的 vs2 寄存器覆盖的字节区间 [vs2_bytes_min, vs2_bytes_max) ----
  logic [6:0] base;                  // = vs2Id * 16
  logic [4:0] vlmax_bytes;           // 一个 vs2 寄存器里有效的字节数（分数 LMUL 只用一部分）
  logic [6:0] vs2_bytes_min;
  logic [7:0] vs2_bytes_max;
  logic       first_gather;          // 本 vd 的第一个 gather uop：越界下标写 0（后续 uop 保留）
  assign base          = 7'(vs2_id) << 4;
  assign vs2_bytes_min = base;
  always_comb begin
    case (vlmul)
      3'd5:    vlmax_bytes = 5'd2;
      3'd6:    vlmax_bytes = 5'd4;
      3'd7:    vlmax_bytes = 5'd8;
      default: vlmax_bytes = 5'd16;
    endcase
  end
  assign vs2_bytes_max = (vs2_id == 3'd0) ? 8'(vlmax_bytes) : (8'(vs2_id) + 8'd1) << 4;
  assign first_gather  = (vlmul >= 3'd4) | (vs2_id == 3'd0);

  // ---- vrgather：每个目的字节要读的源字节下标（67 位：64 位下标左移至多 3 位） ----
  // 下标是"元素下标 × 元素字节数 + 字节在元素内的位置"。.vx 所有元素同一下标 rs1；
  // .vv 下标来自 vs1，宽度由 vs1 的 SEW 决定（ei16 时 16 位）。
  logic [66:0] vrgather_byte_sel [VLENB];
  always_comb begin
    for (int i = 0; i < VLENB; i++) begin
      vrgather_byte_sel[i] = '0;
      if (vrgather_vx) begin
        case (vs2_type[1:0])
          2'd0: vrgather_byte_sel[i] = 67'(vs1[63:0]);
          2'd1: vrgather_byte_sel[i] = {vs1[63:0], 1'b0} | 67'(i % 2);
          2'd2: vrgather_byte_sel[i] = {vs1[63:0], 2'b0} | 67'(i % 4);
          2'd3: vrgather_byte_sel[i] = {vs1[63:0], 3'b0} | 67'(i % 8);
        endcase
      end else begin
        case (vs1_type[1:0])
          2'd0: vrgather_byte_sel[i] = 67'(vs1[8*i +: 8]);
          2'd1: begin
            // ei16：vs1 的第 k 个 16 位下标
            case (vs2_type[1:0])
              2'd0: begin
                // SEW8：一个 vs1 只装 8 个下标，uopIdx 奇/偶分别产出 vd 的上/下半
                if ((i < VLENB / 2) == !uop_idx[0])
                  vrgather_byte_sel[i] = 67'(vs1[16*(i % 8) +: 16]);
              end
              2'd1: vrgather_byte_sel[i] = 67'({vs1[16*(i/2) +: 16], 1'b0} | 17'(i % 2));
              2'd2: vrgather_byte_sel[i] = vd_id[0]
                      ? 67'({vs1[16*(i/4 + 4) +: 16], 2'b0} | 18'(i % 4))
                      : 67'({vs1[16*(i/4) +: 16], 2'b0} | 18'(i % 4));
              2'd3: case (vd_id[1:0])
                      2'd0: vrgather_byte_sel[i] = 67'({vs1[16*(i/8)     +: 16], 3'b0} | 19'(i % 8));
                      2'd1: vrgather_byte_sel[i] = 67'({vs1[16*(i/8 + 2) +: 16], 3'b0} | 19'(i % 8));
                      2'd2: vrgather_byte_sel[i] = 67'({vs1[16*(i/8 + 4) +: 16], 3'b0} | 19'(i % 8));
                      2'd3: vrgather_byte_sel[i] = 67'({vs1[16*(i/8 + 6) +: 16], 3'b0} | 19'(i % 8));
                    endcase
            endcase
          end
          2'd2: vrgather_byte_sel[i] = 67'({vs1[32*(i/4) +: 32], 2'b0} | 34'(i % 4));
          2'd3: vrgather_byte_sel[i] = {vs1[64*(i/8) +: 64], 3'b0} | 67'(i % 8);
        endcase
      end
    end
  end

  // ---- vslide1down 的 rs1 插入时机：每个 vd 的最后一个 uop ----
  logic load_rs1;
  assign load_rs1 = (((vlmul >= 3'd4) | (vlmul == 3'd0)) & (uop_idx == 6'd0))
                  | ((vlmul == 3'd1) & (uop_idx == 6'd2))
                  | ((vlmul == 3'd2) & (uop_idx == 6'd6))
                  | (uop_idx == 6'd14);

  // ---- vcompress：本 uop 在第几组、组内第几段 ----
  logic [7:0] cmprs_group_oh;        // vlRemain1H：uopIdx 属于第 g 组
  logic [7:0] cmprs_part_oh;         // baseUopIdx1H：uopIdx 是本组第 k 个数据 uop
  always_comb begin
    cmprs_group_oh = '0;
    cmprs_part_oh  = '0;
    for (int g = 0; g < 8; g++) begin
      for (int k = 0; k < CMPRS_GROUP_SIZE[g]; k++)
        if (uop_idx == 6'(CMPRS_GROUP_START[g] + k)) cmprs_group_oh[g] = 1'b1;
      for (int k = 0; k < CMPRS_GROUP_DATA[g]; k++)
        if (uop_idx == 6'(CMPRS_GROUP_START[g] + k)) cmprs_part_oh[k] = 1'b1;
    end
  end

  // 第 g 组对应目的寄存器组的第 g 个 vd：本 vd 内还剩几个元素 = clamp(vl - g*ele_cnt, 0, ele_cnt)
  // （第 7 组不封顶，照 golden）
  logic [7:0] vl_remain_vcompress;
  always_comb begin
    vl_remain_vcompress = '0;
    for (int g = 0; g < 8; g++) begin
      if (cmprs_group_oh[g]) begin
        logic [7:0] lo, hi;
        lo = 8'(g) * 8'(ele_cnt);
        hi = 8'(g + 1) * 8'(ele_cnt);
        if (g == 7)
          vl_remain_vcompress = (vl > lo) ? 8'(vl - lo) : 8'd0;
        else
          vl_remain_vcompress = (vl > hi) ? 8'(ele_cnt) : (vl > lo) ? 8'(vl - lo) : 8'd0;
      end
    end
  end

  // 本 uop 要扫描的 vs1 掩码位数 elements（5 位，赋值时截断照 golden），以及每段的元素数 base_ele
  logic [4:0] elements, base_ele;
  always_comb begin
    case (vlmul)
      3'd5:    elements = (vl < 8'(ele_cnt >> 3)) ? 5'(vl) : (ele_cnt >> 3);
      3'd6:    elements = (vl < 8'(ele_cnt >> 2)) ? 5'(vl) : (ele_cnt >> 2);
      3'd7:    elements = (vl < 8'(ele_cnt >> 1)) ? 5'(vl) : (ele_cnt >> 1);
      3'd1:    elements = (vl < (8'(ele_cnt) << 1)) ? 5'(vl_remain_vcompress) : ele_cnt;
      3'd2:    elements = (vl < (8'(ele_cnt) << 2)) ? 5'(vl_remain_vcompress) : ele_cnt;
      3'd3:    elements = (vl < (8'(ele_cnt) << 3)) ? 5'(vl_remain_vcompress) : ele_cnt;
      default: elements = (vl < 8'(ele_cnt)) ? 5'(vl) : ele_cnt;
    endcase
    case (vlmul)
      3'd5:    base_ele = ele_cnt >> 3;
      3'd6:    base_ele = ele_cnt >> 2;
      3'd7:    base_ele = ele_cnt >> 1;
      default: base_ele = ele_cnt;
    endcase
  end

  // 本段压出来的元素在目的 vd 组里的起始编号 = 段号 k × 每段元素数
  logic [7:0] ones_sum_base;
  always_comb begin
    ones_sum_base = '0;
    for (int k = 0; k < 8; k++)
      if (cmprs_part_oh[k]) ones_sum_base = 8'(k) * 8'(base_ele);
  end

  // 前缀计数：current_uop_ones_sum[i] = vs1[i:0] 里 1 的个数（i < elements）；
  // current_ones_sum[i] = 前面各段累计（vs1[127:120] 送进来）+ 上式（i < elements-1，5 位减法）。
  logic [7:0] in_previous_ones_sum, out_previous_ones_sum;
  logic [4:0] current_uop_ones_sum [VLENB];
  logic [7:0] current_ones_sum     [VLENB-1];   // [15] 无人读（golden 已删），这里不建
  logic [4:0] elements_minus1;
  assign in_previous_ones_sum = ((uop_idx == 6'd0) | (uop_idx == 6'd1)) ? 8'd0 : vs1[127:120];
  assign elements_minus1      = 5'(elements - 5'd1);
  always_comb begin
    logic [4:0] pop;
    pop = '0;
    for (int i = 0; i < VLENB; i++) begin
      pop                     = pop + 5'(vs1[i]);
      current_uop_ones_sum[i] = (5'(i) < elements) ? pop : 5'd0;
    end
    for (int i = 0; i < VLENB - 1; i++)
      current_ones_sum[i] = (5'(i) < elements_minus1)
                          ? 8'(in_previous_ones_sum + 8'(current_uop_ones_sum[i])) : 8'd0;
  end
  // Chisel 以 5 位下标索引 16 项 Vec：截低 4 位
  assign out_previous_ones_sum = 8'(current_uop_ones_sum[elements_minus1[3:0]]);

  // vmvNr：vl 换成 evl = ele_cnt << LMUL
  logic [7:0] evl;
  assign evl = 8'(ele_cnt) << vlmul[1:0];

  // ---- reg0 寄存器（fire 时更新） ----
  // 异步复位的一组
  logic            fire_reg0;
  logic [1:0]      vsew_reg0;
  logic [4:0]      elements_reg0;
  logic [VLEN-1:0] vs1_reg0, vs1_next_reg0, vs2_reg0, old_vd_reg0;
  logic [7:0]      vlRemain_reg0;
  logic            is_vrgather_reg0, is_vrgather_vx_reg0;
  logic [5:0]      uopIdx_reg0;
  logic            is_vslide1up_reg0, is_vslide1dn_reg0, is_vcompress_reg0, is_vslideup_reg0;
  logic            is_vslidedn_reg0, is_vrgather16_sew8_reg0, is_vmvnr_reg0, is_vslide_reg0;
  logic            ta_reg0;
  logic [7:0]      vstartRemain_reg0;
  logic [6:0]      vstart_reg0;
  logic [7:0]      vl_reg0;
  logic [VLEN-1:0] vd_reg;
  // 不复位的一组
  logic [7:0]      current_ones_sum_reg0 [VLENB-1];
  logic [7:0]      in_previous_ones_sum_reg0, out_previous_ones_sum_reg0, ones_sum_base_reg0;
  logic [4:0]      ele_cnt_reg0;
  logic [VLEN-1:0] vmask_uop_reg0;
  logic            vm_reg0;
  logic [6:0]      base_reg0;
  logic [66:0]     vrgather_byte_sel_reg0 [VLENB];
  logic            ma_reg0;
  logic [6:0]      vs2_bytes_min_reg0;
  logic [7:0]      vs2_bytes_max_reg0;
  logic [7:0]      vs2_bytes_reg0 [VLENB];
  logic [7:0]      vs1_bytes_reg0 [VLENB];
  logic            first_gather_reg0, load_rs1_reg0, first_slidedn_reg0;
  logic [66:0]     slide_bytes_reg0;
  logic [4:0]      vlmax_bytes_reg0;
  logic [3:0]      vsew_bytes_reg0;

  // fire_reg0 = GatedValidRegNext(fire)：只在 fire 或自身为 1 时采样（等价于打一拍）
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      fire_reg0 <= 1'b0;
    else if (in_valid | fire_reg0)
      fire_reg0 <= in_valid;
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      vsew_reg0               <= '0;
      elements_reg0           <= '0;
      vs1_reg0                <= '0;
      vs1_next_reg0           <= '0;
      vs2_reg0                <= '0;
      old_vd_reg0             <= '0;
      vlRemain_reg0           <= '0;
      is_vrgather_reg0        <= 1'b0;
      is_vrgather_vx_reg0     <= 1'b0;
      uopIdx_reg0             <= '0;
      is_vslide1up_reg0       <= 1'b0;
      is_vslide1dn_reg0       <= 1'b0;
      is_vcompress_reg0       <= 1'b0;
      is_vslideup_reg0        <= 1'b0;
      is_vslidedn_reg0        <= 1'b0;
      is_vrgather16_sew8_reg0 <= 1'b0;
      is_vmvnr_reg0           <= 1'b0;
      is_vslide_reg0          <= 1'b0;
      ta_reg0                 <= 1'b0;
      vstartRemain_reg0       <= '0;
      vstart_reg0             <= '0;
      vl_reg0                 <= '0;
    end else if (in_valid) begin
      vsew_reg0               <= vsew;
      elements_reg0           <= elements;
      vs1_reg0                <= vs1;
      vs1_next_reg0           <= vs1 >> ele_cnt;     // 下一段 vcompress 用的 v0（mask_start_idx = ele_cnt）
      vs2_reg0                <= vs2;
      old_vd_reg0             <= old_vd;
      vlRemain_reg0           <= vl_remain;
      is_vrgather_reg0        <= vrgather;
      is_vrgather_vx_reg0     <= vrgather_vx;
      uopIdx_reg0             <= uop_idx;
      is_vslide1up_reg0       <= vslide1up;
      is_vslide1dn_reg0       <= vslide1dn;
      is_vcompress_reg0       <= vcompress;
      is_vslideup_reg0        <= vslideup;
      is_vslidedn_reg0        <= vslidedn;
      is_vrgather16_sew8_reg0 <= vrgather16_sew8;
      is_vmvnr_reg0           <= vmvnr;
      is_vslide_reg0          <= vslide;
      ta_reg0                 <= ta;
      vstartRemain_reg0       <= vstart_remain;
      vstart_reg0             <= vstart;
      vl_reg0                 <= vmvnr ? evl : vl;
    end
  end

  always_ff @(posedge clock) begin
    if (in_valid) begin
      current_ones_sum_reg0      <= current_ones_sum;
      in_previous_ones_sum_reg0  <= in_previous_ones_sum;
      out_previous_ones_sum_reg0 <= out_previous_ones_sum;
      ones_sum_base_reg0         <= ones_sum_base;
      ele_cnt_reg0               <= ele_cnt;
      vmask_uop_reg0             <= vmask_uop;
      vm_reg0                    <= vm;
      base_reg0                  <= base;
      vrgather_byte_sel_reg0     <= vrgather_byte_sel;
      ma_reg0                    <= ma;
      vs2_bytes_min_reg0         <= vs2_bytes_min;
      vs2_bytes_max_reg0         <= vs2_bytes_max;
      for (int i = 0; i < VLENB; i++) begin
        vs2_bytes_reg0[i] <= vs2[8*i +: 8];
        vs1_bytes_reg0[i] <= vs1[8*i +: 8];
      end
      first_gather_reg0          <= first_gather;
      load_rs1_reg0              <= load_rs1;
      slide_bytes_reg0           <= slide_bytes;
      vlmax_bytes_reg0           <= vlmax_bytes;
      first_slidedn_reg0         <= vslidedn & vslidedn_is_first;
      vsew_bytes_reg0            <= vsew_bytes;
    end
  end

  // ===========================================================================
  // §2 stage 1：逐字节取数
  // ===========================================================================
  logic [10:0] vlRemainBytes_reg0;
  assign vlRemainBytes_reg0 = 11'(vlRemain_reg0) << vsew_reg0;

  // 每个目的字节是否"活"：在剩余 vl 内，且所属元素被 v0 选中（或 vm=1）
  logic [VLENB-1:0] vmask_byte_strb;
  always_comb begin
    for (int i = 0; i < VLENB; i++) begin
      logic [15:0] elem_bits;
      elem_bits          = vmask_uop_reg0[15:0] >> (4'(i) >> vsew_reg0);
      vmask_byte_strb[i] = (11'(i) < vlRemainBytes_reg0) & (elem_bits[0] | vm_reg0);
    end
  end

  // 不活的字节：ma=1 写全 1，否则保留 old_vd
  logic [VLENB-1:0][7:0] inactive_byte;
  always_comb begin
    for (int i = 0; i < VLENB; i++)
      inactive_byte[i] = ma_reg0 ? 8'hFF : old_vd_reg0[8*i +: 8];
  end

  // ---- vrgather：源字节下标落在本 uop 的 vs2 区间内就取，否则首个 uop 写 0、其余保留 ----
  logic [VLENB-1:0][7:0] vrgather_vd;
  always_comb begin
    for (int i = 0; i < VLENB; i++) begin
      vrgather_vd[i] = 8'd0;
      if ((is_vrgather_reg0 | is_vrgather_vx_reg0) & fire_reg0) begin
        vrgather_vd[i] = inactive_byte[i];
        if (vmask_byte_strb[i]) begin
          if ((vrgather_byte_sel_reg0[i] >= 67'(vs2_bytes_min_reg0)) &&
              (vrgather_byte_sel_reg0[i] <  67'(vs2_bytes_max_reg0)))
            vrgather_vd[i] = vs2_bytes_reg0[4'(vrgather_byte_sel_reg0[i][3:0] - vs2_bytes_min_reg0[3:0])];
          else if (first_gather_reg0)
            vrgather_vd[i] = 8'd0;
          else
            vrgather_vd[i] = old_vd_reg0[8*i +: 8];
        end
      end
    end
  end

  // ---- vslideup：目的字节 base+i 取源字节 base+i-slide ----
  logic [VLENB-1:0][7:0] vslideup_vd;
  always_comb begin
    for (int i = 0; i < VLENB; i++) begin
      logic [7:0]  dst;
      logic [66:0] src_byte;
      dst            = 8'(base_reg0) + 8'(i);
      src_byte       = 67'(dst) - slide_bytes_reg0;
      vslideup_vd[i] = inactive_byte[i];
      if (vmask_byte_strb[i]) begin
        if ((67'(dst) >= slide_bytes_reg0) && (src_byte < 67'(vlmax_bytes_reg0)))
          vslideup_vd[i] = vs2_bytes_reg0[src_byte[3:0]];
        else
          vslideup_vd[i] = old_vd_reg0[8*i +: 8];
      end
    end
  end

  // ---- vslidedown：目的字节 i 取源字节 i+slide-base；首个 uop 把越界写 0 ----
  logic [VLENB-1:0][7:0] vslidedn_vd;
  always_comb begin
    for (int i = 0; i < VLENB; i++) begin
      logic [67:0] src_all, src_byte;
      src_all        = 68'(i) + 68'(slide_bytes_reg0);
      src_byte       = src_all - 68'(base_reg0);
      vslidedn_vd[i] = inactive_byte[i];
      if (vmask_byte_strb[i]) begin
        if ((src_all >= 68'(base_reg0)) && (src_byte < 68'(vlmax_bytes_reg0)))
          vslidedn_vd[i] = vs2_bytes_reg0[src_byte[3:0]];
        else if (first_slidedn_reg0)
          vslidedn_vd[i] = 8'd0;
        else
          vslidedn_vd[i] = old_vd_reg0[8*i +: 8];
      end
    end
  end

  // ---- vslide1up：低 vsew_bytes 个字节放 rs1 的元素（取上一段 vs1 的最高元素），其余取 vs2 下移 ----
  // 两路的源下标都是 (i - vsew_bytes) mod 16
  logic [VLENB-1:0][7:0] vslide1up_vd;
  always_comb begin
    for (int i = 0; i < VLENB; i++) begin
      logic [3:0] src_idx;
      src_idx         = 4'(4'(i) - vsew_bytes_reg0);
      vslide1up_vd[i] = inactive_byte[i];
      if (is_vslide1up_reg0 & vmask_byte_strb[i])
        vslide1up_vd[i] = (5'(i) < 5'(vsew_bytes_reg0)) ? vs1_bytes_reg0[src_idx] : vs2_bytes_reg0[src_idx];
    end
  end

  // ---- vslide1down（不含 rs1 插入）：字节 i 取 (i + vsew_bytes) mod 16，越过 16 的取 vs1 ----
  logic [VLENB-1:0][7:0] vslide1dn_wo_rs1;
  logic [4:0] vslide1dn_split;     // 16 - vsew_bytes（5 位）
  assign vslide1dn_split = 5'(5'd16 - 5'(vsew_bytes_reg0));
  always_comb begin
    for (int i = 0; i < VLENB; i++) begin
      logic [3:0] src_idx;
      src_idx             = 4'(vsew_bytes_reg0 + 4'(i));
      vslide1dn_wo_rs1[i] = inactive_byte[i];
      if (is_vslide1dn_reg0 & ~uopIdx_reg0[0] & vmask_byte_strb[i])
        vslide1dn_wo_rs1[i] = (5'(i) < vslide1dn_split) ? vs2_bytes_reg0[src_idx] : vs1_bytes_reg0[src_idx];
    end
  end

  // ---- vslide1down 的 rs1 插入：在 vd 的最后一个有效元素位置写 rs1（vs1 里已按位置备好） ----
  logic [VLEN-1:0] rs1_old_vd, vslide1dn_vd_rs1, vslide1dn_vd;
  logic [10:0]     rs1_byte_pos;     // 插入点字节偏移 = 剩余字节 - 元素字节（11 位回绕照 golden）
  logic [13:0]     rs1_bit_pos;
  logic [10:0]     last_byte;
  assign rs1_old_vd   = load_rs1_reg0 ? vslide1dn_wo_rs1 : old_vd_reg0;
  assign rs1_byte_pos = 11'(vlRemainBytes_reg0 - 11'(vsew_bytes_reg0));
  assign rs1_bit_pos  = {rs1_byte_pos, 3'b000};
  assign last_byte    = 11'(vlRemainBytes_reg0 - 11'd1);
  always_comb begin
    vslide1dn_vd_rs1 = rs1_old_vd;
    if ((load_rs1_reg0 | uopIdx_reg0[0]) && (vlRemainBytes_reg0 > 11'd0) &&
        (vlRemainBytes_reg0 <= 11'd16) && vmask_byte_strb[last_byte[3:0]])
      vslide1dn_vd_rs1 = (rs1_old_vd & (ALL_ONES >> 14'(14'd128 - rs1_bit_pos)))
                       | (vs1_reg0 & (ALL_ONES << rs1_bit_pos));
  end
  assign vslide1dn_vd = (load_rs1_reg0 | uopIdx_reg0[0]) ? vslide1dn_vd_rs1 : vslide1dn_wo_rs1;

  // ---- vd_reg：stage 1 结果（优先级同 Scala when 链） ----
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      vd_reg <= '0;
    else if (is_vmvnr_reg0 & fire_reg0)
      vd_reg <= vs2_reg0;
    else if (is_vslideup_reg0 & fire_reg0)
      vd_reg <= vslideup_vd;
    else if (is_vslide1up_reg0 & fire_reg0)
      vd_reg <= vslide1up_vd;
    else if (is_vslidedn_reg0 & fire_reg0)
      vd_reg <= vslidedn_vd;
    else if (is_vslide1dn_reg0 & fire_reg0)
      vd_reg <= vslide1dn_vd;
    else if ((is_vrgather_reg0 | is_vrgather_vx_reg0) & ~is_vrgather16_sew8_reg0 & fire_reg0)
      vd_reg <= vrgather_vd;
    else if (is_vrgather16_sew8_reg0 & fire_reg0)
      vd_reg <= uopIdx_reg0[0] ? {vrgather_vd[15:8], old_vd_reg0[VLEN/2-1:0]}      // 上半来自本 uop
                               : {old_vd_reg0[VLEN-1:VLEN/2], vrgather_vd[7:0]};   // 下半来自本 uop
  end

  // ---- vcompress stage 1：把选中的元素平移到"它是第几个被选中的"位置 ----
  // ones_sum[i] = 元素 i 之前被选中的个数（含前面各段）；减去本段起始编号 ones_sum_base 得目的位置。
  logic [7:0]      ones_sum_reg0 [VLENB];
  logic [7:0]      ones_sum_eles_reg0;
  logic [15:0]     select_compressed_vs2;   // 目的元素 k 有人写入
  logic [VLEN-1:0] compressed_vs2_merged;   // 各源元素平移后按位或
  logic [VLEN-1:0] compressed_res_reg0;
  assign ones_sum_eles_reg0 = 8'(in_previous_ones_sum_reg0 + out_previous_ones_sum_reg0);
  always_comb begin
    ones_sum_reg0[0] = in_previous_ones_sum_reg0;
    for (int i = 1; i < VLENB; i++)
      ones_sum_reg0[i] = (5'(i) < elements_reg0) ? current_ones_sum_reg0[i-1] : 8'd0;
  end
  // 源元素 i（i < 本 SEW 元素数且 i < elements）被选中且目的位置 dst 在本段内，就平移到 dst。
  logic [7:0] cmprs_dst [VLENB];
  logic       cmprs_en  [VLENB];
  always_comb begin
    for (int i = 0; i < VLENB; i++) begin
      cmprs_dst[i] = 8'(ones_sum_reg0[i] - ones_sum_base_reg0);
      cmprs_en[i]  = vs1_reg0[i] & (cmprs_dst[i] < 8'(ele_cnt_reg0)) & (5'(i) < elements_reg0);
    end
  end
  always_comb begin
    select_compressed_vs2 = '0;
    compressed_vs2_merged = '0;
    case (vsew_reg0)
      2'd0: for (int i = 0; i < 16; i++) if (cmprs_en[i]) begin
              select_compressed_vs2 |= 16'd1 << cmprs_dst[i][3:0];
              compressed_vs2_merged |= VLEN'(vs2_reg0[8*i +: 8]) << (12'(cmprs_dst[i][3:0]) << 3);
            end
      2'd1: for (int i = 0; i < 8; i++) if (cmprs_en[i]) begin
              select_compressed_vs2 |= 16'd1 << cmprs_dst[i][3:0];
              compressed_vs2_merged |= VLEN'(vs2_reg0[16*i +: 16]) << (12'(cmprs_dst[i][3:0]) << 4);
            end
      2'd2: for (int i = 0; i < 4; i++) if (cmprs_en[i]) begin
              select_compressed_vs2 |= 16'd1 << cmprs_dst[i][3:0];
              compressed_vs2_merged |= VLEN'(vs2_reg0[32*i +: 32]) << (12'(cmprs_dst[i][3:0]) << 5);
            end
      default: for (int i = 0; i < 2; i++) if (cmprs_en[i]) begin
              select_compressed_vs2 |= 16'd1 << cmprs_dst[i][3:0];
              compressed_vs2_merged |= VLEN'(vs2_reg0[64*i +: 64]) << (12'(cmprs_dst[i][3:0]) << 6);
            end
    endcase
  end
  // 有人写入的目的元素取压紧值，否则保留 old_vd
  always_comb begin
    case (vsew_reg0)
      2'd0: for (int k = 0; k < 16; k++)
              compressed_res_reg0[8*k +: 8]   = select_compressed_vs2[k] ? compressed_vs2_merged[8*k +: 8]   : old_vd_reg0[8*k +: 8];
      2'd1: for (int k = 0; k < 8; k++)
              compressed_res_reg0[16*k +: 16] = select_compressed_vs2[k] ? compressed_vs2_merged[16*k +: 16] : old_vd_reg0[16*k +: 16];
      2'd2: for (int k = 0; k < 4; k++)
              compressed_res_reg0[32*k +: 32] = select_compressed_vs2[k] ? compressed_vs2_merged[32*k +: 32] : old_vd_reg0[32*k +: 32];
      default: for (int k = 0; k < 2; k++)
              compressed_res_reg0[64*k +: 64] = select_compressed_vs2[k] ? compressed_vs2_merged[64*k +: 64] : old_vd_reg0[64*k +: 64];
    endcase
  end

  // ---- slide/gather 的 tail 与 vstart 掩码（按字节） ----
  logic [10:0]     vstartRemainBytes_reg0, tail_bytes, vstart_bytes;
  logic [VLEN-1:0] vmask_tail_bits, tail_vd, vmask_vstart_bits, vstart_old_vd;
  assign vstartRemainBytes_reg0 = 11'(vstartRemain_reg0) << vsew_reg0;
  assign tail_bytes        = (vlRemainBytes_reg0 >= 11'd16) ? 11'd0 : 11'(11'd16 - vlRemainBytes_reg0);
  assign vmask_tail_bits   = ALL_ONES >> {tail_bytes, 3'b000};
  assign tail_vd           = ta_reg0 ? ~vmask_tail_bits : (old_vd_reg0 & ~vmask_tail_bits);
  assign vstart_bytes      = (vstartRemainBytes_reg0 >= 11'd16) ? 11'd16 : vstartRemainBytes_reg0;
  assign vmask_vstart_bits = ALL_ONES << {vstart_bytes, 3'b000};
  assign vstart_old_vd     = old_vd_reg0 & ~vmask_vstart_bits;

  // ---- reg1 寄存器（fire_reg0 时更新，均不复位） ----
  logic            is_vcompress_reg1, is_vrgather_reg1, is_vrgather_vx_reg1, is_vslide_reg1;
  logic [5:0]      uopIdx_reg1;
  logic [VLEN-1:0] old_vd_reg1;
  logic            ta_reg1;
  logic [6:0]      vstart_reg1;
  logic [7:0]      vl_reg1;
  logic [1:0]      vsew_reg1;
  logic [7:0]      ones_sum_eles_reg1, ones_sum_base_reg1;
  logic [VLEN-1:0] compressed_res_reg1, vs1_next_reg1;
  logic [VLEN-1:0] vmask_tail_bits_reg1, vmask_vstart_bits_reg1, tail_vd_reg1, vstart_old_vd_reg1;

  always_ff @(posedge clock) begin
    if (fire_reg0) begin
      is_vcompress_reg1      <= is_vcompress_reg0;
      is_vrgather_reg1       <= is_vrgather_reg0;
      is_vrgather_vx_reg1    <= is_vrgather_vx_reg0;
      is_vslide_reg1         <= is_vslide_reg0;
      uopIdx_reg1            <= uopIdx_reg0;
      old_vd_reg1            <= old_vd_reg0;
      ta_reg1                <= ta_reg0;
      vstart_reg1            <= vstart_reg0;
      vl_reg1                <= vl_reg0;
      vsew_reg1              <= vsew_reg0;
      ones_sum_eles_reg1     <= ones_sum_eles_reg0;
      ones_sum_base_reg1     <= ones_sum_base_reg0;
      compressed_res_reg1    <= compressed_res_reg0;
      vs1_next_reg1          <= vs1_next_reg0;
      vmask_tail_bits_reg1   <= vmask_tail_bits;
      vmask_vstart_bits_reg1 <= vmask_vstart_bits;
      tail_vd_reg1           <= tail_vd;
      vstart_old_vd_reg1     <= vstart_old_vd;
    end
  end

  // ===========================================================================
  // §3 stage 2：拼最终结果
  // ===========================================================================
  // vcompress：编号 >= 总数的目的元素是尾部，ta=1 时写全 1
  logic [VLEN-1:0] cmprs_vd;
  always_comb begin
    case (vsew_reg1)
      2'd0: for (int k = 0; k < 16; k++)
              cmprs_vd[8*k +: 8]   = ((8'(ones_sum_base_reg1 + 8'(k)) >= ones_sum_eles_reg1) & ta_reg1)
                                     ? '1 : compressed_res_reg1[8*k +: 8];
      2'd1: for (int k = 0; k < 8; k++)
              cmprs_vd[16*k +: 16] = ((8'(ones_sum_base_reg1 + 8'(k)) >= ones_sum_eles_reg1) & ta_reg1)
                                     ? '1 : compressed_res_reg1[16*k +: 16];
      2'd2: for (int k = 0; k < 4; k++)
              cmprs_vd[32*k +: 32] = ((8'(ones_sum_base_reg1 + 8'(k)) >= ones_sum_eles_reg1) & ta_reg1)
                                     ? '1 : compressed_res_reg1[32*k +: 32];
      default: for (int k = 0; k < 2; k++)
              cmprs_vd[64*k +: 64] = ((8'(ones_sum_base_reg1 + 8'(k)) >= ones_sum_eles_reg1) & ta_reg1)
                                     ? '1 : compressed_res_reg1[64*k +: 64];
    endcase
  end

  // 每组最后那个 uop 只输出累计个数（放最高字节）与下一段要用的 v0
  logic cmprs_count_uop;
  assign cmprs_count_uop = (uopIdx_reg1 == 6'd1)  | (uopIdx_reg1 == 6'd4)  | (uopIdx_reg1 == 6'd8)  |
                           (uopIdx_reg1 == 6'd13) | (uopIdx_reg1 == 6'd19) | (uopIdx_reg1 == 6'd26) |
                           (uopIdx_reg1 == 6'd34);

  logic [VLEN-1:0] perm_tail_mask_vd;
  assign perm_tail_mask_vd = (is_vslide_reg1 | is_vrgather_reg1 | is_vrgather_vx_reg1)
      ? ((vd_reg & vmask_tail_bits_reg1 & vmask_vstart_bits_reg1) | tail_vd_reg1 | vstart_old_vd_reg1)
      : vd_reg;

  always_comb begin
    if ({1'b0, vstart_reg1} >= vl_reg1)
      vd = old_vd_reg1;
    else if (is_vcompress_reg1)
      vd = cmprs_count_uop ? {ones_sum_eles_reg1, vs1_next_reg1[119:0]} : cmprs_vd;
    else
      vd = perm_tail_mask_vd;
  end

endmodule

module Permutation (
  input          clock,
  input          reset,
  input          io_in_valid,
  input  [5:0]   io_in_bits_opcode_op,
  input          io_in_bits_info_vm,
  input          io_in_bits_info_ma,
  input          io_in_bits_info_ta,
  input  [2:0]   io_in_bits_info_vlmul,
  input  [7:0]   io_in_bits_info_vl,
  input  [6:0]   io_in_bits_info_vstart,
  input  [5:0]   io_in_bits_info_uopIdx,
  input  [3:0]   io_in_bits_srcType_0,
  input  [3:0]   io_in_bits_srcType_1,
  input  [127:0] io_in_bits_vs1,
  input  [127:0] io_in_bits_vs2,
  input  [127:0] io_in_bits_old_vd,
  input  [127:0] io_in_bits_mask,
  output [127:0] io_out_vd
);
  xs_Permutation_core u_core (
    .clock    (clock),
    .reset    (reset),
    .in_valid (io_in_valid),
    .op       (io_in_bits_opcode_op),
    .vm       (io_in_bits_info_vm),
    .ma       (io_in_bits_info_ma),
    .ta       (io_in_bits_info_ta),
    .vlmul    (io_in_bits_info_vlmul),
    .vl       (io_in_bits_info_vl),
    .vstart   (io_in_bits_info_vstart),
    .uop_idx  (io_in_bits_info_uopIdx),
    .vs2_type (io_in_bits_srcType_0),
    .vs1_type (io_in_bits_srcType_1),
    .vs1      (io_in_bits_vs1),
    .vs2      (io_in_bits_vs2),
    .old_vd   (io_in_bits_old_vd),
    .mask     (io_in_bits_mask),
    .vd       (io_out_vd)
  );
endmodule
