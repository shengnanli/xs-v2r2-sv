// =============================================================================
//  TLPLIC —— RISC-V 平台级中断控制器 (可读重写核 xs_TLPLIC_core)
// -----------------------------------------------------------------------------
//  源自 rocket-chip devices/tilelink/Plic.scala (class TLPLIC) 经 firtool 生成的
//  TLPLIC.sv (2387 行)。本核为该模块的「设计意图重写」: 用 packed 数组 + genvar
//  循环 + 纯函数表达 PLIC 协议, 而非展开成上千条标量赋值。
//
//  本实例参数 (见 plic_pkg.sv):
//    nDevices = 65   外设中断源 (设备号 1..65, 0 号保留=无中断)
//    nHarts   = 2    目标 hart (每 hart 一个 threshold/claim/complete 接口)
//    prioBits = 3    优先级位宽 (nPriorities = 7)
//
//  ---------------------------------------------------------------------------
//  PLIC 中断协议 (本核实现的全部行为):
//
//  1) 中断接入 (LevelGateway):
//     每个外设的电平中断先过一个 LevelGateway (本核例化 xs_LevelGateway_core ×65)。
//     gateway 把电平中断转成「一次性挂起请求」io_plic_valid, 并用 inFlight 防止
//     同一中断在 claim 后、complete 前被重复挂起。gateway 的 ready = ~pending[d]
//     (设备尚未挂起时才接受新挂起), complete = 该设备被软件写 complete。
//
//  2) 挂起位 pending[d]:
//     置位: gateway.valid 拉高 (中断到来且未在途且未挂起) ⇒ pending<=1。
//     清零: 该设备被某 hart claim (claimedDevs[d]) ⇒ pending<=0 (claim 优先于 set)。
//     firtool 合并为: when(claimedDevs[d] | gw_valid[d]) pending[d] <= ~claimedDevs[d]。
//
//  3) 仲裁 (PLICFanIn): 每 hart 例化一个 xs_PLICFanIn_core。
//     输入 io_prio = priority[*], io_ip = enable[hart] & pendingUInt。
//     输出胜出设备号 fanin.dev → 锁存进 maxDevs[hart];
//          胜出优先级 fanin.max → 锁存进 intnodeOut_REG[hart]。
//     对外中断 int_out[hart] = (intnodeOut_REG[hart] > threshold[hart])。
//     注意: maxDevs / intnodeOut_REG 都是 fanin 输出的「打一拍寄存器版」。
//
//  4) Claim (软件读 hart 的 claim/complete 寄存器, oindex 0x100/0x140):
//     读触发 claimer[hart]=1; claiming = OR over harts (claimer?maxDevs:0);
//     claimedDevs = onehot(claiming) (设备号→独热, 设备 0 不清任何 pending)。
//     读返回值 = maxDevs[hart] (当前最高优先级设备号), 同时清其 pending。
//
//  5) Complete (软件写 hart 的 claim/complete 寄存器):
//     写数据低位 = completerDev (要 complete 的设备号);
//     completer[hart] = 写有效 & 该设备对该 hart 使能 (enableVec0[hart][completerDev]);
//     completedDevs = (任一 completer ? onehot(completerDev) : 0);
//     completedDevs[d] 拉高 ⇒ 对应 gateway.complete=1 (释放 inFlight, 可再次挂起)。
//
//  6) 寄存器读写 (TileLink RegMapper, 32 位寄存器, 8 字节 beat):
//     A 通道经 1 深寄存器队列 (out_back_q) 后, 取 index=addr[25:3], 压成 9 位
//     oindex 选寄存器; opcode==4 为读, 否则为写。读出 64 位数据 (两个 32 位字),
//     写按 byte-mask 选择性更新。详见下方 oindex 地址表注释。
//
//  本核例化的子模块 (均为已重写可读核):
//    xs_LevelGateway_core ×65, xs_PLICFanIn_core ×2, 以及内联的 1 深寄存器队列。
// =============================================================================
module xs_TLPLIC_core
  import plic_pkg::*;
(
  input  logic clock,
  input  logic reset,

  // 外设电平中断输入: int_in[0..63] 来自源端口 0 (64 路), int_in[64] 来自源端口 1。
  // golden 端口名 auto_int_in_0_0..63 + auto_int_in_1_0, 在 wrapper 中拼成本向量。
  input  logic [PLIC_N_DEVICES-1:0]            int_in,

  // 对外中断输出: 每 hart 一根。golden = auto_int_out_0_0 / auto_int_out_1_0。
  output logic [PLIC_N_HARTS-1:0]              int_out,

  // ---- TileLink-UL 从机 A 通道 (寄存器访问请求) ----
  output logic                                 in_a_ready,
  input  logic                                 in_a_valid,
  input  logic [3:0]                           in_a_bits_opcode,
  input  logic [1:0]                           in_a_bits_size,
  input  logic [14:0]                          in_a_bits_source,
  input  logic [29:0]                          in_a_bits_address,
  input  logic [7:0]                           in_a_bits_mask,
  input  logic [63:0]                          in_a_bits_data,

  // ---- TileLink-UL 从机 D 通道 (寄存器访问响应) ----
  input  logic                                 in_d_ready,
  output logic                                 in_d_valid,
  output logic [3:0]                           in_d_bits_opcode,
  output logic [1:0]                           in_d_bits_size,
  output logic [14:0]                          in_d_bits_source,
  output logic [63:0]                          in_d_bits_data
);

  localparam int NDEV   = PLIC_N_DEVICES;   // 65
  localparam int NHART  = PLIC_N_HARTS;     // 2
  localparam int PB     = PLIC_PRIO_BITS;   // 3
  localparam int DEVB   = PLIC_DEV_BITS;    // 7 = log2Ceil(nDevices+1)

  // ===========================================================================
  //  寄存器状态
  // ===========================================================================
  logic [PB-1:0]   priority_q   [NDEV];   // 各源优先级 (源 d ↔ 中断号 d+1)
  logic [PB-1:0]   threshold_q  [NHART];  // 各 hart 阈值
  logic            pending_q    [NDEV];   // 各源挂起位
  // 使能位: 每 hart 一个 65 位向量, enable[h][d]=1 表示 hart h 使能源 d。
  logic [NDEV-1:0] enable_q     [NHART];
  logic [DEVB-1:0] maxDevs_q    [NHART];  // fanin 胜出设备号 (打一拍)
  logic [PB-1:0]   intnodeOut_q [NHART];  // fanin 胜出优先级 (打一拍)

  // 挂起位打包成向量 (bit d = pending_q[d]), 喂给 fanin 和读出 mux。
  logic [NDEV-1:0] pendingUInt;
  always_comb
    for (int d = 0; d < NDEV; d++) pendingUInt[d] = pending_q[d];

  // ===========================================================================
  //  TileLink A 通道: 1 深寄存器队列 (out_back_q)
  // ---------------------------------------------------------------------------
  //  与 golden Queue1_RegMapperInput 同构: 满则不收, 空则收; deq 在 full 时有效。
  //  保存的关键字段: read(是否读)、index(字索引)、data、mask、source、size。
  // ===========================================================================
  logic            q_full;
  logic            q_read;
  logic [22:0]     q_index;
  logic [63:0]     q_data;
  logic [7:0]      q_mask;
  logic [14:0]     q_source;
  logic [1:0]      q_size;

  wire   enq_read = (in_a_bits_opcode == 4'h4);     // Get=4 为读, 其余为写
  wire   do_enq   = ~q_full & in_a_valid;
  assign in_a_ready = ~q_full;

  always_ff @(posedge clock) begin
    if (do_enq) begin
      q_read   <= enq_read;
      q_index  <= in_a_bits_address[25:3];
      q_data   <= in_a_bits_data;
      q_mask   <= in_a_bits_mask;
      q_source <= in_a_bits_source;
      q_size   <= in_a_bits_size;
    end
  end
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      q_full <= 1'b0;
    else if (do_enq != (in_d_ready & q_full))  // enq/deq 不同时发生才改变满状态
      q_full <= do_enq;
  end

  wire        deq_valid = q_full;
  wire        deq_fire  = deq_valid & in_d_ready;        // 本拍 D 通道握手
  wire        is_read   = deq_fire &  q_read;            // 读 fire
  wire        is_write  = deq_fire & ~q_read;            // 写 fire

  // ===========================================================================
  //  地址译码
  // ---------------------------------------------------------------------------
  //  index = q_index (字索引, addr[25:3])。firtool 把它压成两部分:
  //   * oindex (9 位) = {index[18], index[10:9], index[5:0]} : 选具体寄存器
  //   * hi0 : index 的其余高位必须全 0 才算命中合法寄存器区
  //  oindex 寄存器表:
  //    0x000              : priority 字 0 (低 32b 保留=源0, 高 32b=priority[0]→源1)
  //    0x001..0x020       : priority 字 k, 低=priority[2k-1], 高=priority[2k]
  //    0x040              : pending 字 0  (bit 1.. = pending[0..62])
  //    0x041              : pending 字 1  (bit 0,1 = pending[63],pending[64])
  //    0x080 / 0x081      : hart0 enable 字 0 / 字 1
  //    0x090 / 0x091      : hart1 enable 字 0 / 字 1
  //    0x100 / 0x140      : hart0 / hart1 的 {claim/complete(高32b), threshold(低32b)}
  // ===========================================================================
  wire [8:0] oindex = {q_index[18], q_index[10:9], q_index[5:0]};
  // 高位区 (必须为 0 才命中): index[22:19], index[17:11], index[8:6]
  wire       hi0    = ({q_index[22:19], q_index[17:11], q_index[8:6]} == 14'h0);

  // 每字节通道写掩码展开 (mask[i] 控制 data 的第 i 字节是否写)。
  wire [31:0] womask_hi = {{8{q_mask[7]}}, {8{q_mask[6]}}, {8{q_mask[5]}}, {8{q_mask[4]}}};

  // hart i 的 claim/complete 字命中 (oindex 0x100 + i*0x40)
  wire [NHART-1:0] hartSel;
  generate
    for (genvar h = 0; h < NHART; h++) begin : g_hartsel
      assign hartSel[h] = (oindex == (9'h100 + 9'(h) * 9'h40));
    end
  endgenerate

  // ===========================================================================
  //  Claim: 软件读 hart 的 claim/complete 寄存器 ⇒ 该 hart 的最高优先级设备被认领
  // ---------------------------------------------------------------------------
  //  claimer[h] = 读 fire & 命中该 hart claim 字 & hi0 & 有读字节使能(womask 非 0)。
  //  claiming   = OR_h (claimer[h] ? maxDevs[h] : 0) (实际只有一个 hart 同时 claim)。
  //  claimedDevs[d] = (claiming == d) (设备号→独热; d=0 不清任何 pending)。
  // ===========================================================================
  logic [NHART-1:0] claimer;
  generate
    for (genvar h = 0; h < NHART; h++) begin : g_claimer
      assign claimer[h] = is_read & hartSel[h] & hi0 & (|womask_hi);
    end
  endgenerate

  logic [DEVB-1:0] claiming;
  always_comb begin
    claiming = '0;
    for (int h = 0; h < NHART; h++)
      if (claimer[h]) claiming |= maxDevs_q[h];
  end
  // claimedDevs[d]: 设备 d (1..NDEV) 是否被本拍 claim。下标 0..NDEV-1 对应设备号 1..NDEV。
  logic [NDEV-1:0] claimedDevs;
  always_comb
    for (int d = 0; d < NDEV; d++)
      claimedDevs[d] = (claiming == DEVB'(d + 1));

  // ===========================================================================
  //  Complete: 软件写 hart 的 claim/complete 寄存器 ⇒ 写入的设备被标记完成
  // ---------------------------------------------------------------------------
  //  completerDev = 写数据 [38:32] (设备号, 取低 log2(nDevices+1)=7 位)。
  //  enableVec0[h] = {enable[h], 1'b0}: 在最低位补 0 (设备 0 永不使能), 故
  //                  enableVec0[h][completerDev] = 该设备对 hart h 是否使能。
  //  completer[h] = 写 fire & 命中该 hart claim 字 & hi0 & 全字节写 & 该设备使能。
  //  completedDevs[d] = (任一 completer ? onehot(completerDev) : 0) 的设备 d 位。
  // ===========================================================================
  wire [DEVB-1:0] completerDev = q_data[38:32];

  // f_woready: 写 fire 且命中该 hart claim 字 & hi0; completer 额外要求全字节写 + 使能。
  logic [NHART-1:0] hart_woready;       // 写命中该 hart claim 字
  logic [NHART-1:0] completer;
  generate
    for (genvar h = 0; h < NHART; h++) begin : g_completer
      assign hart_woready[h] = is_write & hartSel[h] & hi0;
      // enableVec0[h][completerDev] = {enable_q[h], 1'b0} 右移 completerDev 后取最低位。
      // 用移位而非变址 (与 golden 同构), 避免静态越界推断告警。
      wire [NDEV:0] env0     = {enable_q[h], 1'b0};
      wire [NDEV:0] env0_shr = env0 >> completerDev;
      assign completer[h]    = hart_woready[h] & (&womask_hi) & env0_shr[0];
    end
  endgenerate

  // completedDevs[d]: 设备 d (1..NDEV) 本拍是否被 complete。
  wire any_completer = |completer;
  logic [NDEV-1:0] completedDevs;
  always_comb
    for (int d = 0; d < NDEV; d++)
      completedDevs[d] = any_completer & (completerDev == DEVB'(d + 1));

  // ===========================================================================
  //  LevelGateway ×65: 把电平中断转成挂起请求
  // ===========================================================================
  logic [NDEV-1:0] gw_valid;
  generate
    for (genvar d = 0; d < NDEV; d++) begin : g_gateways
      xs_LevelGateway_core u_gw (
        .clock           (clock),
        .reset           (reset),
        .io_interrupt    (int_in[d]),
        .io_plic_valid   (gw_valid[d]),
        .io_plic_ready   (~pending_q[d]),       // 未挂起时才接受新挂起
        .io_plic_complete(completedDevs[d])     // 软件 complete 释放在途
      );
    end
  endgenerate

  // ===========================================================================
  //  PLICFanIn ×2: 每 hart 一棵优先级仲裁树
  // ---------------------------------------------------------------------------
  //  io_prio = 全部源优先级 (打包); io_ip = enable[hart] & pendingUInt。
  //  输出胜出设备号 fanin_dev / 优先级 fanin_max, 下一拍锁进 maxDevs/intnodeOut。
  // ===========================================================================
  logic [NDEV-1:0][PB-1:0] prio_packed;
  always_comb
    for (int d = 0; d < NDEV; d++) prio_packed[d] = priority_q[d];

  logic [DEVB-1:0] fanin_dev [NHART];
  logic [PB-1:0]   fanin_max [NHART];
  generate
    for (genvar h = 0; h < NHART; h++) begin : g_fanin
      xs_PLICFanIn_core u_fanin (
        .io_prio (prio_packed),
        .io_ip   (enable_q[h] & pendingUInt),
        .io_dev  (fanin_dev[h]),
        .io_max  (fanin_max[h])
      );
    end
  endgenerate

  // ===========================================================================
  //  读出数据 mux (按 oindex 拼 64 位读数据)
  // ---------------------------------------------------------------------------
  //  priority 字 0 (oindex 0): 高 32b = priority[0] (源1), 低 32b = 保留(源0)。
  //  priority 字 k (1..32):    低 32b = priority[2k-1], 高 32b = priority[2k]。
  //  pending  字 0/1, enable 字, hart 字: 见各分支注释。
  //  对未命中地址返回 0 (与 golden 一致: 仅命中合法寄存器索引才给值)。
  //  注意: 此 mux 纯组合于队列输出 q_*, 与读/写无关 (golden 行为相同);
  //        真正给到 D 通道的数据再按 hi0 选通 (见 in_d_bits_data 赋值)。
  // ===========================================================================
  logic [63:0] rdata;
  always_comb begin
    rdata = 64'h0;
    if (oindex == 9'h0) begin
      // 字 0: 低 32b 保留 (源0 无优先级寄存器), 高 32b = priority[0]
      rdata = {29'h0, priority_q[0], 32'h0};
    end else if (oindex >= 9'h1 && oindex <= 9'h20) begin
      // 字 k (1..32): 低半字 = priority[2k-1], 高半字 = priority[2k]。
      // 用 for 遍历源对并按 oindex 命中, 索引为编译期常量, 避免越界推断告警。
      for (int k = 1; k <= 32; k++) begin
        if (oindex == 9'(k)) begin
          rdata[2:0]   = priority_q[2*k-1];
          if (2*k < NDEV) rdata[34:32] = priority_q[2*k];
        end
      end
    end else if (oindex == 9'h40) begin
      // pending 字 0: bit 0 保留, bit (d+1) = pending[d], d=0..62
      rdata[0] = 1'b0;
      for (int d = 0; d < 63; d++) rdata[d+1] = pending_q[d];
    end else if (oindex == 9'h41) begin
      // pending 字 1: bit 0 = pending[63], bit 1 = pending[64]
      rdata[0] = pending_q[63];
      rdata[1] = pending_q[64];
    end else if (oindex == 9'h80 || oindex == 9'h90) begin
      // enable hart h 字 0: bit 0 保留, bit (d+1) = enable[h][d], d=0..62
      automatic int h = (oindex == 9'h80) ? 0 : 1;
      rdata[0] = 1'b0;
      for (int d = 0; d < 63; d++) rdata[d+1] = enable_q[h][d];
    end else if (oindex == 9'h81 || oindex == 9'h91) begin
      // enable hart h 字 1: bit 0 = enable[h][63], bit 1 = enable[h][64]
      automatic int h = (oindex == 9'h81) ? 0 : 1;
      rdata[0] = enable_q[h][63];
      rdata[1] = enable_q[h][64];
    end else if (hartSel != '0) begin
      // hart 字: 低 32b = threshold, 高 32b = maxDevs (claim 读返回值)
      for (int h = 0; h < NHART; h++) begin
        if (hartSel[h]) begin
          rdata[2:0]   = threshold_q[h];
          rdata[38:32] = maxDevs_q[h];
        end
      end
    end
  end

  // ===========================================================================
  //  寄存器更新 (写路径 + 挂起位 + fanin 锁存)
  // ===========================================================================
  // priority 写命中: oindex 选字, womask 低/高半字分别写源 2k-1 / 2k。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int d = 0; d < NDEV;  d++) priority_q[d]   <= '0;
      for (int h = 0; h < NHART; h++) threshold_q[h]  <= '0;
      for (int d = 0; d < NDEV;  d++) pending_q[d]    <= 1'b0;
      for (int h = 0; h < NHART; h++) enable_q[h]     <= '0;
      for (int h = 0; h < NHART; h++) maxDevs_q[h]    <= '0;
      for (int h = 0; h < NHART; h++) intnodeOut_q[h] <= '0;
    end else begin
      // ---- priority 写 ----
      // 字 0: 仅高半字 (mask[4]) → priority[0]
      if (is_write && oindex == 9'h0 && hi0 && q_mask[4])
        priority_q[0] <= q_data[34:32];
      // 字 k (1..32): 低半字 (mask[0]) → 源 2k-1; 高半字 (mask[4]) → 源 2k
      for (int k = 1; k <= 32; k++) begin
        if (is_write && oindex == 9'(k) && hi0) begin
          if (q_mask[0])                 priority_q[2*k-1] <= q_data[2:0];
          if (q_mask[4] && (2*k < NDEV)) priority_q[2*k]   <= q_data[34:32];
        end
      end

      // ---- threshold 写 (hart claim 字低半字 mask[0]) ----
      for (int h = 0; h < NHART; h++)
        if (is_write && hartSel[h] && hi0 && q_mask[0])
          threshold_q[h] <= q_data[2:0];

      // ---- 挂起位 pending: claim 清零优先, 否则 gateway.valid 置位 ----
      for (int d = 0; d < NDEV; d++)
        if (claimedDevs[d] | gw_valid[d])
          pending_q[d] <= ~claimedDevs[d];

      // ---- enable 写 ----
      // hart h 字 0 (oindex 0x80+h*0x10): 9 个字节块分别由 mask[0..7] 选写。
      //   块0 = enable[h][6:0]  来自 data[7:1] (bit0 保留, mask[0])
      //   块j(1..7) = enable[h][8j+6:8j-1] 来自 data[8j+7:8j] (mask[j])
      // hart h 字 1 (oindex 0x81+h*0x10): enable[h][64:63] 来自 data[1:0] (mask[0])
      for (int h = 0; h < NHART; h++) begin
        if (is_write && oindex == 9'(9'h80 + h*9'h10) && hi0) begin
          if (q_mask[0]) enable_q[h][6:0]   <= q_data[7:1];
          if (q_mask[1]) enable_q[h][14:7]  <= q_data[15:8];
          if (q_mask[2]) enable_q[h][22:15] <= q_data[23:16];
          if (q_mask[3]) enable_q[h][30:23] <= q_data[31:24];
          if (q_mask[4]) enable_q[h][38:31] <= q_data[39:32];
          if (q_mask[5]) enable_q[h][46:39] <= q_data[47:40];
          if (q_mask[6]) enable_q[h][54:47] <= q_data[55:48];
          if (q_mask[7]) enable_q[h][62:55] <= q_data[63:56];
        end
        if (is_write && oindex == 9'(9'h81 + h*9'h10) && hi0 && q_mask[0])
          enable_q[h][64:63] <= q_data[1:0];
      end

      // ---- fanin 输出锁存 (打一拍) ----
      for (int h = 0; h < NHART; h++) begin
        maxDevs_q[h]    <= fanin_dev[h];
        intnodeOut_q[h] <= fanin_max[h];
      end
    end
  end

  // ===========================================================================
  //  对外中断: hart 的最高优先级 > 阈值 时拉高
  // ===========================================================================
  generate
    for (genvar h = 0; h < NHART; h++) begin : g_intout
      assign int_out[h] = intnodeOut_q[h] > threshold_q[h];
    end
  endgenerate

  // ===========================================================================
  //  D 通道响应
  // ===========================================================================
  assign in_d_valid       = deq_valid;
  assign in_d_bits_opcode = {3'h0, q_read};   // AccessAckData=1(读) / AccessAck=0(写)
  assign in_d_bits_size   = q_size;
  assign in_d_bits_source = q_source;
  // D 通道读数据: 仅当地址命中合法寄存器区 (hi0) 才给寄存器值, 否则 0。
  // 与 golden 一致: 不按读/写选通 (写响应也会驱动同一组合 mux)。
  assign in_d_bits_data   = hi0 ? rdata : 64'h0;

endmodule
