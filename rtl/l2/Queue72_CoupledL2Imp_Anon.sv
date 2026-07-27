// Queue72_CoupledL2Imp_Anon —— 手写可读实现(TL2 shard 4, AUX signoff)。
//
// 深度 72 的循环缓冲队列(CoupledL2 内 PCredit/srcID 匿名 bundle 队列)。载荷 15 位:
// {srcID[10:0], pCrdType[3:0]}。存储走同步写 / 同步读的 ram_72x15 存储宏(与 golden
// 同一模块两侧 elaborate, 非黑盒), 本核只重写指针 + full 控制 FSM(队列真逻辑)。
//
// 控制语义(与 golden Queue72_CoupledL2Imp_Anon 逐位一致):
//   - enq_ptr_value / deq_ptr_value: 7 位读写指针, 计到 71(7'h47) 回绕 0(非 2 的幂
//     深度, 故显式比较回绕而非模掩码)。异步 reset 清 0。
//   - maybe_full: enq==deq 时区分满/空的辅助位(异步 reset 清 0)。
//   - ptr_match = (enq==deq); empty = ptr_match & ~maybe_full; full = ptr_match & maybe_full。
//   - do_enq = ~full & io_enq_valid; do_deq = io_deq_ready & ~empty。
//   - 指针在各自 do_* 时前进/回绕; maybe_full 仅当 do_enq != do_deq 时更新为 do_enq。
//   - ram: W 端口 addr=enq_ptr, en=do_enq, data={srcID,pCrdType}; R 端口 addr=deq_ptr,
//     en 恒真, data 组合读回。
//   - io_enq_ready = ~full; io_deq_valid = ~empty;
//     io_deq_bits_pCrdType = R0_data[3:0]; io_deq_bits_srcID = R0_data[14:4]。
//
// golden 同名扁平端口包装在 rtl/l2/Queue72_CoupledL2Imp_Anon_wrapper.sv。
module xs_Queue72_CoupledL2Imp_Anon_core(
  input         clock,
  input         reset,
  output        io_enq_ready,
  input         io_enq_valid,
  input  [3:0]  io_enq_bits_pCrdType,
  input  [10:0] io_enq_bits_srcID,
  input         io_deq_ready,
  output        io_deq_valid,
  output [3:0]  io_deq_bits_pCrdType,
  output [10:0] io_deq_bits_srcID
);

  reg  [6:0]  enq_ptr_value;
  reg  [6:0]  deq_ptr_value;
  reg         maybe_full;

  wire        ptr_match = enq_ptr_value == deq_ptr_value;
  wire        empty     = ptr_match & ~maybe_full;
  wire        full      = ptr_match & maybe_full;
  wire        do_enq    = ~full & io_enq_valid;
  wire        do_deq    = io_deq_ready & ~empty;

  wire [14:0] ram_rdata;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      enq_ptr_value <= 7'h0;
      deq_ptr_value <= 7'h0;
      maybe_full    <= 1'h0;
    end
    else begin
      if (do_enq) begin
        if (enq_ptr_value == 7'h47)
          enq_ptr_value <= 7'h0;
        else
          enq_ptr_value <= 7'(enq_ptr_value + 7'h1);
      end
      if (do_deq) begin
        if (deq_ptr_value == 7'h47)
          deq_ptr_value <= 7'h0;
        else
          deq_ptr_value <= 7'(deq_ptr_value + 7'h1);
      end
      if (~(do_enq == do_deq))
        maybe_full <= do_enq;
    end
  end

  ram_72x15 ram_ext (
    .R0_addr (deq_ptr_value),
    .R0_en   (1'h1),
    .R0_clk  (clock),
    .R0_data (ram_rdata),
    .W0_addr (enq_ptr_value),
    .W0_en   (do_enq),
    .W0_clk  (clock),
    .W0_data ({io_enq_bits_srcID, io_enq_bits_pCrdType})
  );

  assign io_enq_ready         = ~full;
  assign io_deq_valid         = ~empty;
  assign io_deq_bits_pCrdType = ram_rdata[3:0];
  assign io_deq_bits_srcID    = ram_rdata[14:4];

endmodule
