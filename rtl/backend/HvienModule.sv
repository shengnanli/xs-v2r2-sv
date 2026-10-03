// HvienModule.sv — hypervisor virtual-interrupt-enable CSR (hvien, AIA 6.3.2).
// hvien[i]=1 with hideleg[i]=0 turns interrupt i into a virtual interrupt for
// VS level: vsie[i]/vsip[i] become bits the hypervisor controls through hvip
// (see VSieModule / VSipModule).
// Writable bits: locals 14..63 only; bits 13:0 are read-only zero.
// The logic is the shared xs_CsrVien_core in rtl/backend/xs_CsrVien_core.sv;
// this file is only the golden-named wrapper.  Reset: asynchronous, 0.

// BEGIN GENERATED(csr-irq-handle)
module HvienModule (
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_LC14IE,
  output        regOut_LC15IE,
  output        regOut_LC16IE,
  output        regOut_LC17IE,
  output        regOut_LC18IE,
  output        regOut_LC19IE,
  output        regOut_LC20IE,
  output        regOut_LC21IE,
  output        regOut_LC22IE,
  output        regOut_LC23IE,
  output        regOut_LC24IE,
  output        regOut_LC25IE,
  output        regOut_LC26IE,
  output        regOut_LC27IE,
  output        regOut_LC28IE,
  output        regOut_LC29IE,
  output        regOut_LC30IE,
  output        regOut_LC31IE,
  output        regOut_LC32IE,
  output        regOut_LC33IE,
  output        regOut_LC34IE,
  output        regOut_LPRASEIE,
  output        regOut_LC36IE,
  output        regOut_LC37IE,
  output        regOut_LC38IE,
  output        regOut_LC39IE,
  output        regOut_LC40IE,
  output        regOut_LC41IE,
  output        regOut_LC42IE,
  output        regOut_HPRASEIE,
  output        regOut_LC44IE,
  output        regOut_LC45IE,
  output        regOut_LC46IE,
  output        regOut_LC47IE,
  output        regOut_LC48IE,
  output        regOut_LC49IE,
  output        regOut_LC50IE,
  output        regOut_LC51IE,
  output        regOut_LC52IE,
  output        regOut_LC53IE,
  output        regOut_LC54IE,
  output        regOut_LC55IE,
  output        regOut_LC56IE,
  output        regOut_LC57IE,
  output        regOut_LC58IE,
  output        regOut_LC59IE,
  output        regOut_LC60IE,
  output        regOut_LC61IE,
  output        regOut_LC62IE,
  output        regOut_LC63IE
);
  logic [63:0] value;

  xs_CsrVien_core #(.WRITABLE(64'hFFFF_FFFF_FFFF_C000)) u_core (
    .clk   (clock),
    .rst   (reset),
    .wen   (w_wen),
    .wdata (w_wdata),
    .value (value)
  );

  // Outputs spread back to one port per interrupt number.
  assign rdata = value;
  assign regOut_LC14IE = value[14];
  assign regOut_LC15IE = value[15];
  assign regOut_LC16IE = value[16];
  assign regOut_LC17IE = value[17];
  assign regOut_LC18IE = value[18];
  assign regOut_LC19IE = value[19];
  assign regOut_LC20IE = value[20];
  assign regOut_LC21IE = value[21];
  assign regOut_LC22IE = value[22];
  assign regOut_LC23IE = value[23];
  assign regOut_LC24IE = value[24];
  assign regOut_LC25IE = value[25];
  assign regOut_LC26IE = value[26];
  assign regOut_LC27IE = value[27];
  assign regOut_LC28IE = value[28];
  assign regOut_LC29IE = value[29];
  assign regOut_LC30IE = value[30];
  assign regOut_LC31IE = value[31];
  assign regOut_LC32IE = value[32];
  assign regOut_LC33IE = value[33];
  assign regOut_LC34IE = value[34];
  assign regOut_LPRASEIE = value[35];
  assign regOut_LC36IE = value[36];
  assign regOut_LC37IE = value[37];
  assign regOut_LC38IE = value[38];
  assign regOut_LC39IE = value[39];
  assign regOut_LC40IE = value[40];
  assign regOut_LC41IE = value[41];
  assign regOut_LC42IE = value[42];
  assign regOut_HPRASEIE = value[43];
  assign regOut_LC44IE = value[44];
  assign regOut_LC45IE = value[45];
  assign regOut_LC46IE = value[46];
  assign regOut_LC47IE = value[47];
  assign regOut_LC48IE = value[48];
  assign regOut_LC49IE = value[49];
  assign regOut_LC50IE = value[50];
  assign regOut_LC51IE = value[51];
  assign regOut_LC52IE = value[52];
  assign regOut_LC53IE = value[53];
  assign regOut_LC54IE = value[54];
  assign regOut_LC55IE = value[55];
  assign regOut_LC56IE = value[56];
  assign regOut_LC57IE = value[57];
  assign regOut_LC58IE = value[58];
  assign regOut_LC59IE = value[59];
  assign regOut_LC60IE = value[60];
  assign regOut_LC61IE = value[61];
  assign regOut_LC62IE = value[62];
  assign regOut_LC63IE = value[63];
endmodule
// END GENERATED
