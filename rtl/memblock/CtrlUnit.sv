// =============================================================================
// CtrlUnit —— DCache 的"伪错误注入"控制器（L1DCacheCtrl，TileLink 寄存器外设）
//
// 对应 Chisel：xiangshan.cache.CtrlUnit（src/main/scala/xiangshan/cache/dcache/CtrlUnit.scala）
//
// 【它做什么】
//   DCache 的 tag / data SRAM 都带 ECC。为了验证"ECC 检错 → 上报 → 处理"这条通路，
//   软件可以通过这个外设让 DCache 在下一次读 tag 或 data 时**假装**读到了错误：
//   把一组"翻转掩码"送给 tag 阵列（io_pseudoError(0)）或 data 阵列（io_pseudoError(1)），
//   阵列在读出时按掩码翻转数据位，ECC 就会报错。
//
// 【寄存器映射】（TLRegisterNode，beatBytes=8，寄存器索引 = addr[6:3]）
//   index 0  ctrl  （控制字，字段见 ctrl_t）
//   index 1  delay （延迟拍数；写它的同时把 counter 也装成同一个值）
//   index 2..9  mask_0..7（8 个数据 bank 各一个 64 位翻转掩码；tag 注入只用 mask_0）
//   其它 index 读回 0、写无效。
//   只有"整 64 位写"（字节掩码全 1）才会写进寄存器（RegField 要求字段被完整覆盖）。
//
// 【注入流程】
//   ctrl.ese=1（error signaling enable）且（ede=0 或 counter 已减到 0）时，
//   按 ctrl.comp 选一个通道（0=tag，1=data）拉 valid，载荷是
//   {bank i 使能 = ctrl.bank[i], 掩码 = mask_i}；
//   ede=1（error delay enable）时 counter 每拍减 1，减到 0 才放行 → 实现"延迟 N 拍再注入"。
//   请求被接收（fire）后：persist=0 则清掉 ese（只注入一次）；persist=1 则保持 ese，
//   并在 ede=1 时把 counter 重装为 delay（周期性注入）。
//   两个通道各经一级 NewPipelineConnect（NewPipelineConnectPipe_27）打拍后送出。
//
// 【同拍冲突的优先级】（照 Chisel 的 when 书写顺序，golden 现读）
//   ctrl   ：软件写 ctrl  >  data 通道 fire  >  tag 通道 fire
//   counter：软件写 delay >  延迟递减       >  data 通道 fire 重装 > tag 通道 fire 重装
//
// 子模块：Queue1_RegMapperInput_6（A 通道深度 1 队列，TLRegisterNode 自动插入）、
//   NewPipelineConnectPipe_27 ×2（两个注入通道的出口打拍）。
// 复位：全部寄存器异步复位为 0（RegInit），照搬 golden。
// =============================================================================

module CtrlUnit(
  input         clock,
  input         reset,
  output        auto_in_a_ready,
  input         auto_in_a_valid,
  input  [3:0]  auto_in_a_bits_opcode,
  input  [1:0]  auto_in_a_bits_size,
  input  [3:0]  auto_in_a_bits_source,
  input  [29:0] auto_in_a_bits_address,
  input  [7:0]  auto_in_a_bits_mask,
  input  [63:0] auto_in_a_bits_data,
  input         auto_in_d_ready,
  output        auto_in_d_valid,
  output [3:0]  auto_in_d_bits_opcode,
  output [1:0]  auto_in_d_bits_size,
  output [3:0]  auto_in_d_bits_source,
  output [63:0] auto_in_d_bits_data,
  input         io_pseudoError_0_ready,
  output        io_pseudoError_0_valid,
  output        io_pseudoError_0_bits_0_valid,
  output [63:0] io_pseudoError_0_bits_0_mask,
  input         io_pseudoError_1_ready,
  output        io_pseudoError_1_valid,
  output        io_pseudoError_1_bits_0_valid,
  output [63:0] io_pseudoError_1_bits_0_mask,
  output        io_pseudoError_1_bits_1_valid,
  output [63:0] io_pseudoError_1_bits_1_mask,
  output        io_pseudoError_1_bits_2_valid,
  output [63:0] io_pseudoError_1_bits_2_mask,
  output        io_pseudoError_1_bits_3_valid,
  output [63:0] io_pseudoError_1_bits_3_mask,
  output        io_pseudoError_1_bits_4_valid,
  output [63:0] io_pseudoError_1_bits_4_mask,
  output        io_pseudoError_1_bits_5_valid,
  output [63:0] io_pseudoError_1_bits_5_mask,
  output        io_pseudoError_1_bits_6_valid,
  output [63:0] io_pseudoError_1_bits_6_mask,
  output        io_pseudoError_1_bits_7_valid,
  output [63:0] io_pseudoError_1_bits_7_mask
);

  localparam int N_BANKS = 8;   // DCacheBanks

  // ctrl 寄存器的字段（CtrlUnitCtrlBundle，最后声明的字段在最低位）
  typedef struct packed {
    logic [51:0]        zero0;    // 填充
    logic [N_BANKS-1:0] bank;     // 各 bank 是否注入
    logic               comp;     // 注入对象：0 = tag，1 = data
    logic               ede;      // error delay enable：等 counter 减到 0 再注入
    logic               persist;  // 注入后保持 ese（周期性注入）
    logic               ese;      // error signaling enable：注入总开关
  } ctrl_t;

  localparam logic [3:0] IDX_CTRL   = 4'd0;
  localparam logic [3:0] IDX_DELAY  = 4'd1;
  localparam logic [3:0] IDX_MASK_0 = 4'd2;   // mask_i 在 index 2+i
  localparam logic [3:0] TL_GET     = 4'd4;   // TileLink A 通道 Get 操作码

  // ---- 寄存器 ----
  ctrl_t       ctrlRegs_0;
  logic [63:0] delayRegs_0;
  logic [63:0] counterRegs_0;
  logic [63:0] maskRegs_0, maskRegs_1, maskRegs_2, maskRegs_3,
               maskRegs_4, maskRegs_5, maskRegs_6, maskRegs_7;
  logic [63:0] mask_regs [N_BANKS];
  assign mask_regs = '{maskRegs_0, maskRegs_1, maskRegs_2, maskRegs_3,
                       maskRegs_4, maskRegs_5, maskRegs_6, maskRegs_7};

  // ===========================================================================
  //  §1 寄存器访问：A 通道 → 深度 1 队列 → 队头请求在 D 握手那拍生效
  // ===========================================================================
  logic        req_valid;      // 队头有请求（= D 通道 valid）
  logic        req_is_read;
  logic [3:0]  req_index;
  logic [63:0] req_wdata;
  logic [7:0]  req_byte_mask;

  Queue1_RegMapperInput_6 out_back_q (
    .clock                               (clock),
    .reset                               (reset),
    .io_enq_ready                        (auto_in_a_ready),
    .io_enq_valid                        (auto_in_a_valid),
    .io_enq_bits_read                    (auto_in_a_bits_opcode == TL_GET),
    .io_enq_bits_index                   (auto_in_a_bits_address[6:3]),
    .io_enq_bits_data                    (auto_in_a_bits_data),
    .io_enq_bits_mask                    (auto_in_a_bits_mask),
    .io_enq_bits_extra_tlrr_extra_source (auto_in_a_bits_source),
    .io_enq_bits_extra_tlrr_extra_size   (auto_in_a_bits_size),
    .io_deq_ready                        (auto_in_d_ready),
    .io_deq_valid                        (req_valid),
    .io_deq_bits_read                    (req_is_read),
    .io_deq_bits_index                   (req_index),
    .io_deq_bits_data                    (req_wdata),
    .io_deq_bits_mask                    (req_byte_mask),
    .io_deq_bits_extra_tlrr_extra_source (auto_in_d_bits_source),
    .io_deq_bits_extra_tlrr_extra_size   (auto_in_d_bits_size)
  );

  // 一次"写"生效 = D 握手 & 非读 & 8 个字节全写（字段被完整覆盖）
  wire reg_write = req_valid & auto_in_d_ready & ~req_is_read & (&req_byte_mask);
  wire write_ctrl  = reg_write & (req_index == IDX_CTRL);
  wire write_delay = reg_write & (req_index == IDX_DELAY);
  logic [N_BANKS-1:0] write_mask;
  always_comb
    for (int i = 0; i < N_BANKS; i++)
      write_mask[i] = reg_write & (req_index == IDX_MASK_0 + 4'(i));

  // D 通道：读回 AccessAckData(1)，写回 AccessAck(0)；读数据按 index 选寄存器
  logic [63:0] read_data;
  always_comb begin
    read_data = '0;
    if (req_index == IDX_CTRL)  read_data = ctrlRegs_0;
    if (req_index == IDX_DELAY) read_data = delayRegs_0;
    for (int i = 0; i < N_BANKS; i++)
      if (req_index == IDX_MASK_0 + 4'(i)) read_data = mask_regs[i];
  end
  assign auto_in_d_valid       = req_valid;
  assign auto_in_d_bits_opcode = {3'b000, req_is_read};
  assign auto_in_d_bits_data   = read_data;

  // ===========================================================================
  //  §2 注入请求生成：两个通道（0 = tag，1 = data）
  // ===========================================================================
  wire delay_done = ~ctrlRegs_0.ede | (counterRegs_0 == 64'd0);
  wire gen_valid_tag  = ctrlRegs_0.ese & (ctrlRegs_0.comp == 1'b0) & delay_done;
  wire gen_valid_data = ctrlRegs_0.ese & (ctrlRegs_0.comp == 1'b1) & delay_done;

  logic gen_ready_tag, gen_ready_data;
  wire fire_tag  = gen_ready_tag  & gen_valid_tag;
  wire fire_data = gen_ready_data & gen_valid_data;

  // fire 之后的 ctrl：persist=0 时清 ese；其余字段不变
  wire   next_ese = ctrlRegs_0.persist & ctrlRegs_0.ese;
  ctrl_t ctrl_after_fire;
  always_comb begin
    ctrl_after_fire     = ctrlRegs_0;
    ctrl_after_fire.ese = next_ese;
  end
  // fire 后若仍在注入且开了延迟：counter 重装（persist ? delay : 0）
  wire reload_counter = next_ese & ctrlRegs_0.ede;
  wire [63:0] counter_reload_value = ctrlRegs_0.persist ? delayRegs_0 : 64'd0;
  // 延迟递减：ese & ede & counter != 0
  wire counting_down = ctrlRegs_0.ese & ctrlRegs_0.ede & (counterRegs_0 != 64'd0);

  // ===========================================================================
  //  §3 寄存器更新（优先级见文件头）
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      ctrlRegs_0    <= '0;
      delayRegs_0   <= '0;
      counterRegs_0 <= '0;
      maskRegs_0    <= '0;
      maskRegs_1    <= '0;
      maskRegs_2    <= '0;
      maskRegs_3    <= '0;
      maskRegs_4    <= '0;
      maskRegs_5    <= '0;
      maskRegs_6    <= '0;
      maskRegs_7    <= '0;
    end
    else begin
      if (write_ctrl)
        ctrlRegs_0 <= ctrl_t'(req_wdata);
      else if (fire_data | fire_tag)
        ctrlRegs_0 <= ctrl_after_fire;

      if (write_delay) begin
        delayRegs_0   <= req_wdata;
        counterRegs_0 <= req_wdata;
      end
      else if (counting_down)
        counterRegs_0 <= counterRegs_0 - 64'd1;
      else if ((fire_data | fire_tag) & reload_counter)
        counterRegs_0 <= counter_reload_value;

      if (write_mask[0]) maskRegs_0 <= req_wdata;
      if (write_mask[1]) maskRegs_1 <= req_wdata;
      if (write_mask[2]) maskRegs_2 <= req_wdata;
      if (write_mask[3]) maskRegs_3 <= req_wdata;
      if (write_mask[4]) maskRegs_4 <= req_wdata;
      if (write_mask[5]) maskRegs_5 <= req_wdata;
      if (write_mask[6]) maskRegs_6 <= req_wdata;
      if (write_mask[7]) maskRegs_7 <= req_wdata;
    end
  end

  // ===========================================================================
  //  §4 出口打拍：两个通道各一级 NewPipelineConnect，载荷 = {bank 使能, 掩码} × 8
  //     （tag 通道只用第 0 组，其余输出在 golden 里就没有端口）
  // ===========================================================================
  logic tag_out_valid, data_out_valid;

  NewPipelineConnectPipe_27 CtrlUnitPseudoErrorPipelineConnect0 (
    .clock               (clock),
    .reset               (reset),
    .io_in_ready         (gen_ready_tag),
    .io_in_valid         (gen_valid_tag),
    .io_in_bits_0_valid  (ctrlRegs_0.bank[0]),
    .io_in_bits_0_mask   (maskRegs_0),
    .io_in_bits_1_valid  (ctrlRegs_0.bank[1]),
    .io_in_bits_1_mask   (maskRegs_1),
    .io_in_bits_2_valid  (ctrlRegs_0.bank[2]),
    .io_in_bits_2_mask   (maskRegs_2),
    .io_in_bits_3_valid  (ctrlRegs_0.bank[3]),
    .io_in_bits_3_mask   (maskRegs_3),
    .io_in_bits_4_valid  (ctrlRegs_0.bank[4]),
    .io_in_bits_4_mask   (maskRegs_4),
    .io_in_bits_5_valid  (ctrlRegs_0.bank[5]),
    .io_in_bits_5_mask   (maskRegs_5),
    .io_in_bits_6_valid  (ctrlRegs_0.bank[6]),
    .io_in_bits_6_mask   (maskRegs_6),
    .io_in_bits_7_valid  (ctrlRegs_0.bank[7]),
    .io_in_bits_7_mask   (maskRegs_7),
    .io_out_ready        (io_pseudoError_0_ready),
    .io_out_valid        (tag_out_valid),
    .io_out_bits_0_valid (io_pseudoError_0_bits_0_valid),
    .io_out_bits_0_mask  (io_pseudoError_0_bits_0_mask),
    .io_out_bits_1_valid (),
    .io_out_bits_1_mask  (),
    .io_out_bits_2_valid (),
    .io_out_bits_2_mask  (),
    .io_out_bits_3_valid (),
    .io_out_bits_3_mask  (),
    .io_out_bits_4_valid (),
    .io_out_bits_4_mask  (),
    .io_out_bits_5_valid (),
    .io_out_bits_5_mask  (),
    .io_out_bits_6_valid (),
    .io_out_bits_6_mask  (),
    .io_out_bits_7_valid (),
    .io_out_bits_7_mask  (),
    .io_rightOutFire     (io_pseudoError_0_ready & tag_out_valid)
  );

  NewPipelineConnectPipe_27 CtrlUnitPseudoErrorPipelineConnect1 (
    .clock               (clock),
    .reset               (reset),
    .io_in_ready         (gen_ready_data),
    .io_in_valid         (gen_valid_data),
    .io_in_bits_0_valid  (ctrlRegs_0.bank[0]),
    .io_in_bits_0_mask   (maskRegs_0),
    .io_in_bits_1_valid  (ctrlRegs_0.bank[1]),
    .io_in_bits_1_mask   (maskRegs_1),
    .io_in_bits_2_valid  (ctrlRegs_0.bank[2]),
    .io_in_bits_2_mask   (maskRegs_2),
    .io_in_bits_3_valid  (ctrlRegs_0.bank[3]),
    .io_in_bits_3_mask   (maskRegs_3),
    .io_in_bits_4_valid  (ctrlRegs_0.bank[4]),
    .io_in_bits_4_mask   (maskRegs_4),
    .io_in_bits_5_valid  (ctrlRegs_0.bank[5]),
    .io_in_bits_5_mask   (maskRegs_5),
    .io_in_bits_6_valid  (ctrlRegs_0.bank[6]),
    .io_in_bits_6_mask   (maskRegs_6),
    .io_in_bits_7_valid  (ctrlRegs_0.bank[7]),
    .io_in_bits_7_mask   (maskRegs_7),
    .io_out_ready        (io_pseudoError_1_ready),
    .io_out_valid        (data_out_valid),
    .io_out_bits_0_valid (io_pseudoError_1_bits_0_valid),
    .io_out_bits_0_mask  (io_pseudoError_1_bits_0_mask),
    .io_out_bits_1_valid (io_pseudoError_1_bits_1_valid),
    .io_out_bits_1_mask  (io_pseudoError_1_bits_1_mask),
    .io_out_bits_2_valid (io_pseudoError_1_bits_2_valid),
    .io_out_bits_2_mask  (io_pseudoError_1_bits_2_mask),
    .io_out_bits_3_valid (io_pseudoError_1_bits_3_valid),
    .io_out_bits_3_mask  (io_pseudoError_1_bits_3_mask),
    .io_out_bits_4_valid (io_pseudoError_1_bits_4_valid),
    .io_out_bits_4_mask  (io_pseudoError_1_bits_4_mask),
    .io_out_bits_5_valid (io_pseudoError_1_bits_5_valid),
    .io_out_bits_5_mask  (io_pseudoError_1_bits_5_mask),
    .io_out_bits_6_valid (io_pseudoError_1_bits_6_valid),
    .io_out_bits_6_mask  (io_pseudoError_1_bits_6_mask),
    .io_out_bits_7_valid (io_pseudoError_1_bits_7_valid),
    .io_out_bits_7_mask  (io_pseudoError_1_bits_7_mask),
    .io_rightOutFire     (io_pseudoError_1_ready & data_out_valid)
  );

  assign io_pseudoError_0_valid = tag_out_valid;
  assign io_pseudoError_1_valid = data_out_valid;

endmodule
