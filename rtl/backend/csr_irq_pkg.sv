// csr_irq_pkg.sv — interrupt numbering shared by the AIA interrupt CSR leaves
// (sie/sip/vsie/vsip/mvien/mvip/hvien/hvip) of NewCSR.
// Every one of those CSRs is a 64-bit vector indexed by *interrupt number*
// (Scala: InterruptNO / InterruptBundle in NewCSR/InterruptBundle.scala), so
// the rewritten cores work on whole irq_vec_t vectors plus the group masks
// below instead of on the per-interrupt scalar ports that firtool emitted.
//   bit  1/5/9   supervisor software/timer/external      (the "HS" group)
//   bit  2/6/10  virtual-supervisor software/timer/ext.  (the "VS" group)
//   bit  3/7/11  machine software/timer/external         (the "M" group)
//   bit  12      supervisor guest external (SGEI)
//   bit  13      local counter-overflow (LCOFI, Sscofpmf)
//   bit  14..63  further local interrupts (35/43 = low/high-priority RAS)
// "Local" in the Scala sense (getLocal) is 13..63, i.e. it includes LCOFI.
package csr_irq_pkg;
  typedef logic [63:0] irq_vec_t;

  localparam int IRQ_SSI   = 1;
  localparam int IRQ_VSSI  = 2;
  localparam int IRQ_MSI   = 3;
  localparam int IRQ_STI   = 5;
  localparam int IRQ_VSTI  = 6;
  localparam int IRQ_MTI   = 7;
  localparam int IRQ_SEI   = 9;
  localparam int IRQ_VSEI  = 10;
  localparam int IRQ_MEI   = 11;
  localparam int IRQ_SGEI  = 12;
  localparam int IRQ_LCOFI = 13;

  localparam irq_vec_t IRQ_HS_MASK    = 64'h0000_0000_0000_0222;  // 1, 5, 9
  localparam irq_vec_t IRQ_VS_MASK    = 64'h0000_0000_0000_0444;  // 2, 6, 10
  localparam irq_vec_t IRQ_M_MASK     = 64'h0000_0000_0000_0888;  // 3, 7, 11
  localparam irq_vec_t IRQ_SGEI_MASK  = 64'h0000_0000_0000_1000;  // 12
  localparam irq_vec_t IRQ_LCOFI_MASK = 64'h0000_0000_0000_2000;  // 13
  localparam irq_vec_t IRQ_LOCAL_MASK = 64'hFFFF_FFFF_FFFF_E000;  // 13..63
  localparam irq_vec_t IRQ_LC14UP_MASK = 64'hFFFF_FFFF_FFFF_C000; // 14..63

  // Bits a supervisor-level view (sie/sip/vsie/vsip) can show at all: the HS
  // group and the locals. M, VS and SGEI positions are hard-wired zero there.
  localparam irq_vec_t IRQ_S_VIEW_MASK = IRQ_HS_MASK | IRQ_LOCAL_MASK;

  // VS-level CSRs present the VS interrupts at the *supervisor* positions:
  // vsie.SSIE (bit 1) is mie.VSSIE (bit 2), and so on.  This is the Scala
  //   Cat(x(63, COI), 0.U(1.W), x(SGEI, SSI))
  // i.e. bits 12..1 move down by one, bit 12 becomes 0, 13..63 stay put.
  function automatic irq_vec_t vs_to_s_view(input irq_vec_t x);
    return {x[63:13], 1'b0, x[12:1]};
  endfunction

  // The inverse for write data: a write to vsie/vsip bit 1/5/9 is really a
  // write to interrupt 2/6/10, every other bit keeps its own position.
  function automatic irq_vec_t s_to_vs_wdata(input irq_vec_t wdata);
    irq_vec_t r;
    r            = wdata;
    r[IRQ_VSSI]  = wdata[IRQ_SSI];
    r[IRQ_VSTI]  = wdata[IRQ_STI];
    r[IRQ_VSEI]  = wdata[IRQ_SEI];
    return r;
  endfunction
endpackage
