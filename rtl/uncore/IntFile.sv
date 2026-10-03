// =============================================================================
// IntFile.sv —— IMSIC 的一个中断文件（interrupt file）：256 个 MSI 中断源的 pending/enable 位
//               与 eidelivery / eithreshold 两个控制 CSR，以及 topei 优先级选择
//
// 在哪一层：uncore IMSIC（AIA 的 per-hart 外部中断控制器）里例化 9 份：
//   M 文件、S 文件、7 个 guest（VS）文件。IMSIC 按特权级/vgein 把 CSR 间接访问
//   （miselect/siselect/vsiselect + *ireg）与 MSI 写入分发到某一个文件，本件只管自己这 256 位。
// 设计源：ChiselAIA/src/main/scala/IMSIC.scala class IntFile（params: imsicIntSrcWidth=8 → 256 源，
//   xlen=64 → eip/eie 各 4 个 64 位寄存器）。
//
// 寄存器（全部异步复位为 0，与 golden 一一对应）：
//   eidelivery  (64)  只有 bit0 可写（写入值 & 1），其余 63 位恒 0；
//   eithreshold (64)  阈值；
//   eips[0..3]  (64)  pending 位；eips[0] 的 bit0 经 CSR 写恒为 0（bit0ReadOnlyZero），
//                     ★但 seteipnum=0 仍能把它置 1、claim 到 topei=0 时也会清它★（golden 如此）；
//   eies[0..3]  (64)  enable 位；eies[0].bit0 经 CSR 写恒为 0。
//
// 三条通路：
//   §1 CSR 间接访问（地址 = *iselect）：0x70 eidelivery / 0x72 eithreshold / 0x80,82,84,86 eip0..3 /
//      0xC0,C2,C4,C6 eie0..3。写由 op 决定 wdata/wmask：CSRRW 全写，CSRRS 置位，CSRRC 清位；
//      illegal_priv 为 1 时不写。读：addr.valid 时查表（未命中给 0），rdata.valid = addr.valid | illegal_priv。
//      toCSR.illegal：地址落在 [0x80,0xFF] 且为奇数（eip/eie 的奇数号在 RV64 下不存在）。
//   §2 MSI 置位：seteipnum.valid 时置 eips[id[7:6]] 的第 id[5:0] 位。
//   §3 topei：在 256 位 (eip & eie) 中找最小的置位序号（没有则 256），再过阈值：
//      序号 <= eithreshold-1（64 位无符号，eithreshold=0 时回绕成全 1 ⇒ 全部放行）才送出，否则 0。
//      pending = (eidelivery == 1) && topei != 0。claim 清掉 topei 所指的 pending 位。
//   同一个 eips 寄存器一拍内的写优先级（golden 顺序）：claim > seteipnum > CSR 写。
// golden 对照：G1-canonical/golden-rtl/IntFile.sv
// =============================================================================
module xs_IntFile_core (
  input  logic        clock,
  input  logic        reset,
  // MSI 置位
  input  logic        seteipnum_valid,
  input  logic [7:0]  seteipnum_id,
  // CSR 间接访问
  input  logic        addr_valid,
  input  logic [11:0] addr,
  input  logic        wdata_valid,
  input  logic [1:0]  wdata_op,        // 0 非法 / 1 CSRRW / 2 CSRRS / 3 CSRRC
  input  logic [63:0] wdata_data,
  input  logic        claim,
  input  logic        illegal_priv,    // IMSIC 顶层判出的特权级非法
  output logic        rdata_valid,
  output logic [63:0] rdata,
  output logic        illegal,
  output logic        pending,
  output logic [7:0]  topei
);
  localparam int N_SRC = 256;
  localparam int N_WORD = N_SRC / 64;

  logic [63:0] eidelivery, eithreshold;
  logic [63:0] eips [N_WORD];
  logic [63:0] eies [N_WORD];

  // ---- §1 CSR 写数据/掩码 ----
  logic [63:0] wdata, wmask;
  always_comb begin
    wdata = '0; wmask = '0;
    if (wdata_valid) begin
      case (wdata_op)
        2'd1: begin wdata = wdata_data; wmask = '1;         end  // CSRRW
        2'd2: begin wdata = '1;         wmask = wdata_data; end  // CSRRS
        2'd3: begin wdata = '0;         wmask = wdata_data; end  // CSRRC
        default: ;                                               // 非法 op：不写
      endcase
    end
  end

  function automatic logic [63:0] merge(input logic [63:0] old_v, input logic [63:0] d,
                                        input logic [63:0] m);
    merge = (d & m) | (old_v & ~m);
  endfunction

  logic csr_write;
  assign csr_write = wdata_valid & ~illegal_priv;

  // ---- §3 topei：256 位 (eip & eie) 的最小置位序号 ----
  logic [N_SRC-1:0] ready_bits;
  for (genvar w = 0; w < N_WORD; w++) begin : g_ready
    assign ready_bits[w*64 +: 64] = eips[w] & eies[w];
  end

  logic [8:0] first_ready;   // 0..255，无则 256
  always_comb begin
    first_ready = 9'd256;
    for (int i = N_SRC - 1; i >= 0; i--)
      if (ready_bits[i]) first_ready = 9'(i);
  end

  // 阈值过滤：序号 <= eithreshold-1 才放行（64 位无符号，阈值 0 回绕成全 1 ⇒ 全放行）
  assign topei = ({55'b0, first_ready} <= (eithreshold - 64'd1)) ? first_ready[7:0] : 8'd0;
  assign pending = (eidelivery[63:1] == '0) & eidelivery[0] & (topei != 8'd0);

  // ---- 寄存器更新 ----
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      eidelivery  <= '0;
      eithreshold <= '0;
      for (int w = 0; w < N_WORD; w++) begin eips[w] <= '0; eies[w] <= '0; end
    end else begin
      if (csr_write && addr == 12'h070) eidelivery  <= {63'b0, merge(eidelivery, wdata, wmask) & 64'd1};
      if (csr_write && addr == 12'h072) eithreshold <= merge(eithreshold, wdata, wmask);
      for (int w = 0; w < N_WORD; w++) begin
        // eip：claim > seteipnum > CSR 写
        if (claim && topei[7:6] == 2'(w))
          eips[w] <= eips[w] & ~(64'd1 << topei[5:0]);
        else if (seteipnum_valid && seteipnum_id[7:6] == 2'(w))
          eips[w] <= eips[w] | (64'd1 << seteipnum_id[5:0]);
        else if (csr_write && addr == 12'h080 + 12'(2 * w))
          eips[w] <= (w == 0) ? (merge(eips[w], wdata, wmask) & ~64'd1)
                              :  merge(eips[w], wdata, wmask);
        // eie：只有 CSR 写
        if (csr_write && addr == 12'h0C0 + 12'(2 * w))
          eies[w] <= (w == 0) ? (merge(eies[w], wdata, wmask) & ~64'd1)
                              :  merge(eies[w], wdata, wmask);
      end
    end
  end

  // ---- §1 读 ----
  always_comb begin
    rdata = '0;
    if (addr_valid) begin
      case (addr)
        12'h070: rdata = eidelivery;
        12'h072: rdata = eithreshold;
        12'h080: rdata = eips[0];
        12'h082: rdata = eips[1];
        12'h084: rdata = eips[2];
        12'h086: rdata = eips[3];
        12'h0C0: rdata = eies[0];
        12'h0C2: rdata = eies[1];
        12'h0C4: rdata = eies[2];
        12'h0C6: rdata = eies[3];
        default: rdata = '0;
      endcase
    end
  end
  assign rdata_valid = addr_valid | illegal_priv;
  assign illegal = (addr >= 12'h080) & (addr <= 12'h0FF) & addr[0];
endmodule

module IntFile (
  input         clock,
  input         reset,
  input         fromCSR_seteipnum_valid,
  input  [7:0]  fromCSR_seteipnum_bits,
  input         fromCSR_addr_valid,
  input  [11:0] fromCSR_addr_bits,
  input         fromCSR_wdata_valid,
  input  [1:0]  fromCSR_wdata_bits_op,
  input  [63:0] fromCSR_wdata_bits_data,
  input         fromCSR_claim,
  output        toCSR_rdata_valid,
  output [63:0] toCSR_rdata_bits,
  output        toCSR_illegal,
  output        toCSR_pending,
  output [7:0]  toCSR_topei,
  input         illegal_io_illegal_priv
);
  xs_IntFile_core u_core (
    .clock           (clock),
    .reset           (reset),
    .seteipnum_valid (fromCSR_seteipnum_valid),
    .seteipnum_id    (fromCSR_seteipnum_bits),
    .addr_valid      (fromCSR_addr_valid),
    .addr            (fromCSR_addr_bits),
    .wdata_valid     (fromCSR_wdata_valid),
    .wdata_op        (fromCSR_wdata_bits_op),
    .wdata_data      (fromCSR_wdata_bits_data),
    .claim           (fromCSR_claim),
    .illegal_priv    (illegal_io_illegal_priv),
    .rdata_valid     (toCSR_rdata_valid),
    .rdata           (toCSR_rdata_bits),
    .illegal         (toCSR_illegal),
    .pending         (toCSR_pending),
    .topei           (toCSR_topei)
  );
endmodule
