// xs_PmEntryHandle_core.sv — shared core of PMPEntryHandleModule and
// PMAEntryHandleModule (NewCSR): the write/read rules of the 32 PMP (or PMA)
// entries that cannot be expressed inside the individual pmpcfg/pmpaddr CSR
// leaves because they need to look at several entries at once.
// It does two independent jobs:
//   1. cfg write legalisation (combinational).  A write to one of the four
//      cfg CSRs (base, base+2, base+4, base+6; eight entries each) is turned
//      into the 64-bit value the cfg leaves should really store:
//        - a locked entry (old L=1) keeps its old byte;
//        - W is forced to W&R (W=1,R=0 is reserved);
//        - with the 4 KiB platform grain NA4 is not selectable, so A is
//          stored as {A[1], A[1]|A[0]}: OFF 00 and TOR 01 are kept, NA4 10
//          becomes NAPOT 11, NAPOT 11 stays.
//      When no cfg CSR is being written the output is all zero.
//   2. the 32 address registers (46 bits each, the pmpaddr payload).
//      Entry i is written by a CSR write to ADDR_CSR_BASE+i unless it is
//      locked: its own cfg.L is set, or the next entry is locked in TOR mode
//      (then this address is the bottom of the locked range).  The last entry
//      has no next entry.  Reading through the CSR port (ren + address hit)
//      applies the grain mask: NAPOT (A[1]=1) reads addr[8:0] as ones, OFF/TOR
//      reads addr[9:0] as zeros; without ren the raw register is shown.
// PMP and PMA differ only in CSR addresses, in the address reset values and
// in cfg bits 6:5 (reserved in PMP: plain wdata when unlocked, 0 when locked;
// C / ATOMIC in PMA) — all three come in through parameters / old_cfg.
// Scala keeps a pmpMask register too; nothing reads it in this configuration
// and golden has no such flop, so it is not modelled.
// Reset: asynchronous, address registers load ADDR_RESET.
module xs_PmEntryHandle_core #(
  parameter logic [11:0]       CFG_CSR_BASE  = 12'h3A0,
  parameter logic [11:0]       ADDR_CSR_BASE = 12'h3B0,
  parameter logic [31:0][45:0] ADDR_RESET    = '0
) (
  input  logic               clk,
  input  logic               rst,
  input  logic               wen,          // CSR write strobe
  input  logic               ren,          // CSR read strobe
  input  logic [11:0]        csr_addr,
  input  logic [63:0]        wdata,
  input  logic [31:0][7:0]   old_cfg,      // current cfg byte of every entry
  output logic [63:0]        cfg_wdata,    // legalised cfg CSR write value
  output logic [31:0][63:0]  addr_rdata    // pmpaddr read value per entry
);
  // cfg byte layout: {L, bit6, bit5, A[1:0], X, W, R}
  localparam int CFG_R = 0;
  localparam int CFG_W = 1;
  localparam int CFG_A_LO = 3;
  localparam int CFG_A_HI = 4;
  localparam int CFG_L = 7;
  localparam logic [1:0] A_TOR = 2'b01;

  // ===========================================================================
  // 1. cfg write legalisation
  // ===========================================================================
  // The four cfg CSRs sit at even offsets; group g covers entries 8g..8g+7.
  logic [3:0] cfg_group_wen;
  for (genvar g = 0; g < 4; g++) begin : g_cfg_group
    assign cfg_group_wen[g] = wen & (csr_addr == 12'(CFG_CSR_BASE + 2 * g));
  end

  for (genvar j = 0; j < 8; j++) begin : g_cfg_byte
    logic [7:0] old_byte;     // old cfg of the entry this byte addresses
    logic [7:0] new_byte;     // raw write data
    logic [7:0] legal_byte;   // write data after WARL legalisation

    // At most one group is selected (distinct CSR addresses).
    always_comb begin
      old_byte = 8'h0;
      for (int g = 0; g < 4; g++)
        if (cfg_group_wen[g]) old_byte = old_cfg[8 * g + j];
    end

    assign new_byte = wdata[8 * j +: 8];
    always_comb begin
      legal_byte           = new_byte;
      legal_byte[CFG_W]    = new_byte[CFG_W] & new_byte[CFG_R];
      legal_byte[CFG_A_LO] = new_byte[CFG_A_HI] | new_byte[CFG_A_LO];
    end

    assign cfg_wdata[8 * j +: 8] = !(|cfg_group_wen)  ? 8'h0
                                 : old_byte[CFG_L]    ? old_byte
                                 :                      legal_byte;
  end

  // ===========================================================================
  // 2. address registers
  // ===========================================================================
  for (genvar i = 0; i < 32; i++) begin : g_entry
    logic [45:0] addr_q;
    logic        csr_hit;
    logic        locked;

    assign csr_hit = (csr_addr == 12'(ADDR_CSR_BASE + i));

    if (i == 31) begin : g_last
      assign locked = old_cfg[i][CFG_L];
    end else begin : g_has_next
      assign locked = old_cfg[i][CFG_L]
                    | (old_cfg[i + 1][CFG_L] & (old_cfg[i + 1][CFG_A_HI:CFG_A_LO] == A_TOR));
    end

    always_ff @(posedge clk or posedge rst) begin
      if (rst)
        addr_q <= ADDR_RESET[i];
      else if (wen & csr_hit & ~locked)
        addr_q <= wdata[45:0];
    end

    // Grain-masked view only on a real CSR read of this entry.
    assign addr_rdata[i] = {18'h0,
                            !(ren & csr_hit)      ? addr_q
                            : old_cfg[i][CFG_A_HI] ? {addr_q[45:9], 9'h1FF}
                            :                        {addr_q[45:10], 10'h0}};
  end
endmodule
