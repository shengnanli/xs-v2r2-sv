// Iprio _xs UT variants —— 与 wrapper 同, 仅模块名改 _xs, 例化可读 primitive。
module Iprio0Module_xs(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         mie_SSIE,
  input         mie_VSSIE,
  input         mie_MSIE,
  input         mie_STIE,
  input         mie_VSTIE,
  input         mie_MTIE,
  input         mie_SEIE,
  input         mie_VSEIE,
  input         mie_MEIE,
  input         mie_SGEIE,
  input         mie_LCOFIE
);
  wire [7:0] r0, r1, r2, r3, r4, r5; // SSI VSSI MSI STI VSTI MTI
  xs_iprio6 #(
    .WOFF0(8),
    .WOFF1(16),
    .WOFF2(24),
    .WOFF3(40),
    .WOFF4(48),
    .WOFF5(56)
  ) u_core (
    .clock (clock),
    .reset (reset),
    .w_wen (w_wen),
    .w_wdata (w_wdata),
    .reg0 (r0), .reg1 (r1), .reg2 (r2),
    .reg3 (r3), .reg4 (r4), .reg5 (r5)
  );
  wire [7:0] g_SSI  = r0 & {8{mie_SSIE}};
  wire [7:0] g_VSSI = r1 & {8{mie_VSSIE}};
  wire [7:0] g_MSI  = r2 & {8{mie_MSIE}};
  wire [7:0] g_STI  = r3 & {8{mie_STIE}};
  wire [7:0] g_VSTI = r4 & {8{mie_VSTIE}};
  wire [7:0] g_MTI  = r5 & {8{mie_MTIE}};
  assign rdata = {g_MTI, g_VSTI, g_STI, 8'h0, g_MSI, g_VSSI, g_SSI, 8'h0};
endmodule

module Iprio2Module_1_xs(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         sie_SSIE,
  input         sie_STIE,
  input         sie_SEIE,
  input         sie_LCOFIE,
  input         sie_LC14IE,
  input         sie_LC15IE,
  input         sie_LC16IE,
  input         sie_LC17IE,
  input         sie_LC18IE,
  input         sie_LC19IE,
  input         sie_LC20IE,
  input         sie_LC21IE,
  input         sie_LC22IE,
  input         sie_LC23IE,
  input         sie_LC24IE,
  input         sie_LC25IE,
  input         sie_LC26IE,
  input         sie_LC27IE,
  input         sie_LC28IE,
  input         sie_LC29IE,
  input         sie_LC30IE,
  input         sie_LC31IE,
  input         sie_LC32IE,
  input         sie_LC33IE,
  input         sie_LC34IE,
  input         sie_LPRASEIE,
  input         sie_LC36IE,
  input         sie_LC37IE,
  input         sie_LC38IE,
  input         sie_LC39IE,
  input         sie_LC40IE,
  input         sie_LC41IE,
  input         sie_LC42IE,
  input         sie_HPRASEIE,
  input         sie_LC44IE,
  input         sie_LC45IE,
  input         sie_LC46IE,
  input         sie_LC47IE,
  input         sie_LC48IE,
  input         sie_LC49IE,
  input         sie_LC50IE,
  input         sie_LC51IE,
  input         sie_LC52IE,
  input         sie_LC53IE,
  input         sie_LC54IE,
  input         sie_LC55IE,
  input         sie_LC56IE,
  input         sie_LC57IE,
  input         sie_LC58IE,
  input         sie_LC59IE,
  input         sie_LC60IE,
  input         sie_LC61IE,
  input         sie_LC62IE,
  input         sie_LC63IE
);
  wire [7:0] r0, r1, r2, r3, r4, r5; // VSEI MEI SGEI LCOFI Prio14 Prio15
  xs_iprio6 #(
    .WOFF0(16),
    .WOFF1(24),
    .WOFF2(32),
    .WOFF3(40),
    .WOFF4(48),
    .WOFF5(56)
  ) u_core (
    .clock (clock),
    .reset (reset),
    .w_wen (w_wen),
    .w_wdata (w_wdata),
    .reg0 (r0), .reg1 (r1), .reg2 (r2),
    .reg3 (r3), .reg4 (r4), .reg5 (r5)
  );
  wire [7:0] g_LCOFI  = r3 & {8{sie_LCOFIE}};
  wire [7:0] g_Prio14 = r4 & {8{sie_LC14IE}};
  wire [7:0] g_Prio15 = r5 & {8{sie_LC15IE}};
  assign rdata = {g_Prio15, g_Prio14, g_LCOFI, 40'h0};
endmodule

module Iprio8Module_xs(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         mie_SSIE,
  input         mie_VSSIE,
  input         mie_MSIE,
  input         mie_STIE,
  input         mie_VSTIE,
  input         mie_MTIE,
  input         mie_SEIE,
  input         mie_VSEIE,
  input         mie_MEIE,
  input         mie_SGEIE,
  input         mie_LCOFIE
);
  xs_iprio_ext #(.IDX(8)) u_core (
    .clock     (clock),
    .reset     (reset),
    .w_wen     (w_wen),
    .w_wdata   (w_wdata),
    .gate_mask (64'h0),
    .rdata     (rdata)
  );
endmodule

module Iprio8Module_1_xs(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         sie_SSIE,
  input         sie_STIE,
  input         sie_SEIE,
  input         sie_LCOFIE,
  input         sie_LC14IE,
  input         sie_LC15IE,
  input         sie_LC16IE,
  input         sie_LC17IE,
  input         sie_LC18IE,
  input         sie_LC19IE,
  input         sie_LC20IE,
  input         sie_LC21IE,
  input         sie_LC22IE,
  input         sie_LC23IE,
  input         sie_LC24IE,
  input         sie_LC25IE,
  input         sie_LC26IE,
  input         sie_LC27IE,
  input         sie_LC28IE,
  input         sie_LC29IE,
  input         sie_LC30IE,
  input         sie_LC31IE,
  input         sie_LC32IE,
  input         sie_LC33IE,
  input         sie_LC34IE,
  input         sie_LPRASEIE,
  input         sie_LC36IE,
  input         sie_LC37IE,
  input         sie_LC38IE,
  input         sie_LC39IE,
  input         sie_LC40IE,
  input         sie_LC41IE,
  input         sie_LC42IE,
  input         sie_HPRASEIE,
  input         sie_LC44IE,
  input         sie_LC45IE,
  input         sie_LC46IE,
  input         sie_LC47IE,
  input         sie_LC48IE,
  input         sie_LC49IE,
  input         sie_LC50IE,
  input         sie_LC51IE,
  input         sie_LC52IE,
  input         sie_LC53IE,
  input         sie_LC54IE,
  input         sie_LC55IE,
  input         sie_LC56IE,
  input         sie_LC57IE,
  input         sie_LC58IE,
  input         sie_LC59IE,
  input         sie_LC60IE,
  input         sie_LC61IE,
  input         sie_LC62IE,
  input         sie_LC63IE
);
  wire [63:0] gate_mask =
    {{8{sie_LC39IE}},
     {8{sie_LC38IE}},
     {8{sie_LC37IE}},
     {8{sie_LC36IE}},
     {8{sie_LPRASEIE}},
     {8{sie_LC34IE}},
     {8{sie_LC33IE}},
     {8{sie_LC32IE}}};
  xs_iprio_ext #(.IDX(8)) u_core (
    .clock     (clock),
    .reset     (reset),
    .w_wen     (w_wen),
    .w_wdata   (w_wdata),
    .gate_mask (gate_mask),
    .rdata     (rdata)
  );
endmodule

