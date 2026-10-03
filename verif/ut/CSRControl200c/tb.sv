`timescale 1ns/1ps
module tb;
  logic clock = 1'b0;
  logic reset = 1'b1;
  always #5 clock = ~clock;

  logic wen;
  logic [63:0] wdata;
  wire [63:0] ip0_rdata;
  wire [63:0] ip2_rdata;
  Iprio0Module_xs ip0(.clock, .reset, .w_wen(wen), .w_wdata(wdata), .rdata(ip0_rdata));
  Iprio2Module_xs ip2(.clock, .reset, .w_wen(wen), .w_wdata(wdata), .rdata(ip2_rdata));

  // All 200c priority-window variants share the interrupt-enable/delegation inputs.
  logic mideleg_SSI;
  logic mideleg_STI;
  logic mideleg_SEI;
  logic mideleg_LCOFI;
  logic mvien_SSIE;
  logic mvien_SEIE;
  logic mvien_LC14IE;
  logic mvien_LC15IE;
  logic mvien_LC16IE;
  logic mvien_LC17IE;
  logic mvien_LC18IE;
  logic mvien_LC19IE;
  logic mvien_LC20IE;
  logic mvien_LC21IE;
  logic mvien_LC22IE;
  logic mvien_LC23IE;
  logic mvien_LC24IE;
  logic mvien_LC25IE;
  logic mvien_LC26IE;
  logic mvien_LC27IE;
  logic mvien_LC28IE;
  logic mvien_LC29IE;
  logic mvien_LC30IE;
  logic mvien_LC31IE;
  logic mvien_LC32IE;
  logic mvien_LC33IE;
  logic mvien_LC34IE;
  logic mvien_LPRASEIE;
  logic mvien_LC36IE;
  logic mvien_LC37IE;
  logic mvien_LC38IE;
  logic mvien_LC39IE;
  logic mvien_LC40IE;
  logic mvien_LC41IE;
  logic mvien_LC42IE;
  logic mvien_HPRASEIE;
  logic mvien_LC44IE;
  logic mvien_LC45IE;
  logic mvien_LC46IE;
  logic mvien_LC47IE;
  logic mvien_LC48IE;
  logic mvien_LC49IE;
  logic mvien_LC50IE;
  logic mvien_LC51IE;
  logic mvien_LC52IE;
  logic mvien_LC53IE;
  logic mvien_LC54IE;
  logic mvien_LC55IE;
  logic mvien_LC56IE;
  logic mvien_LC57IE;
  logic mvien_LC58IE;
  logic mvien_LC59IE;
  logic mvien_LC60IE;
  logic mvien_LC61IE;
  logic mvien_LC62IE;
  logic mvien_LC63IE;
  wire [63:0] iprio0_1_rdata;
  Iprio0Module_1_xs u_iprio0_1(.clock(clock), .reset(reset), .w_wen(wen), .w_wdata(wdata), .rdata(iprio0_1_rdata),
    .mideleg_SSI(mideleg_SSI), .mideleg_STI(mideleg_STI), .mideleg_SEI(mideleg_SEI), .mideleg_LCOFI(mideleg_LCOFI), .mvien_SSIE(mvien_SSIE), .mvien_SEIE(mvien_SEIE), .mvien_LC14IE(mvien_LC14IE), .mvien_LC15IE(mvien_LC15IE), .mvien_LC16IE(mvien_LC16IE), .mvien_LC17IE(mvien_LC17IE), .mvien_LC18IE(mvien_LC18IE), .mvien_LC19IE(mvien_LC19IE), .mvien_LC20IE(mvien_LC20IE), .mvien_LC21IE(mvien_LC21IE), .mvien_LC22IE(mvien_LC22IE), .mvien_LC23IE(mvien_LC23IE), .mvien_LC24IE(mvien_LC24IE), .mvien_LC25IE(mvien_LC25IE), .mvien_LC26IE(mvien_LC26IE), .mvien_LC27IE(mvien_LC27IE), .mvien_LC28IE(mvien_LC28IE), .mvien_LC29IE(mvien_LC29IE), .mvien_LC30IE(mvien_LC30IE), .mvien_LC31IE(mvien_LC31IE), .mvien_LC32IE(mvien_LC32IE), .mvien_LC33IE(mvien_LC33IE), .mvien_LC34IE(mvien_LC34IE), .mvien_LPRASEIE(mvien_LPRASEIE), .mvien_LC36IE(mvien_LC36IE), .mvien_LC37IE(mvien_LC37IE), .mvien_LC38IE(mvien_LC38IE), .mvien_LC39IE(mvien_LC39IE), .mvien_LC40IE(mvien_LC40IE), .mvien_LC41IE(mvien_LC41IE), .mvien_LC42IE(mvien_LC42IE), .mvien_HPRASEIE(mvien_HPRASEIE), .mvien_LC44IE(mvien_LC44IE), .mvien_LC45IE(mvien_LC45IE), .mvien_LC46IE(mvien_LC46IE), .mvien_LC47IE(mvien_LC47IE), .mvien_LC48IE(mvien_LC48IE), .mvien_LC49IE(mvien_LC49IE), .mvien_LC50IE(mvien_LC50IE), .mvien_LC51IE(mvien_LC51IE), .mvien_LC52IE(mvien_LC52IE), .mvien_LC53IE(mvien_LC53IE), .mvien_LC54IE(mvien_LC54IE), .mvien_LC55IE(mvien_LC55IE), .mvien_LC56IE(mvien_LC56IE), .mvien_LC57IE(mvien_LC57IE), .mvien_LC58IE(mvien_LC58IE), .mvien_LC59IE(mvien_LC59IE), .mvien_LC60IE(mvien_LC60IE), .mvien_LC61IE(mvien_LC61IE), .mvien_LC62IE(mvien_LC62IE), .mvien_LC63IE(mvien_LC63IE));

  wire [63:0] iprio2_1_rdata;
  Iprio2Module_1_xs u_iprio2_1(.clock(clock), .reset(reset), .w_wen(wen), .w_wdata(wdata), .rdata(iprio2_1_rdata),
    .mideleg_SSI(mideleg_SSI), .mideleg_STI(mideleg_STI), .mideleg_SEI(mideleg_SEI), .mideleg_LCOFI(mideleg_LCOFI), .mvien_SSIE(mvien_SSIE), .mvien_SEIE(mvien_SEIE), .mvien_LC14IE(mvien_LC14IE), .mvien_LC15IE(mvien_LC15IE), .mvien_LC16IE(mvien_LC16IE), .mvien_LC17IE(mvien_LC17IE), .mvien_LC18IE(mvien_LC18IE), .mvien_LC19IE(mvien_LC19IE), .mvien_LC20IE(mvien_LC20IE), .mvien_LC21IE(mvien_LC21IE), .mvien_LC22IE(mvien_LC22IE), .mvien_LC23IE(mvien_LC23IE), .mvien_LC24IE(mvien_LC24IE), .mvien_LC25IE(mvien_LC25IE), .mvien_LC26IE(mvien_LC26IE), .mvien_LC27IE(mvien_LC27IE), .mvien_LC28IE(mvien_LC28IE), .mvien_LC29IE(mvien_LC29IE), .mvien_LC30IE(mvien_LC30IE), .mvien_LC31IE(mvien_LC31IE), .mvien_LC32IE(mvien_LC32IE), .mvien_LC33IE(mvien_LC33IE), .mvien_LC34IE(mvien_LC34IE), .mvien_LPRASEIE(mvien_LPRASEIE), .mvien_LC36IE(mvien_LC36IE), .mvien_LC37IE(mvien_LC37IE), .mvien_LC38IE(mvien_LC38IE), .mvien_LC39IE(mvien_LC39IE), .mvien_LC40IE(mvien_LC40IE), .mvien_LC41IE(mvien_LC41IE), .mvien_LC42IE(mvien_LC42IE), .mvien_HPRASEIE(mvien_HPRASEIE), .mvien_LC44IE(mvien_LC44IE), .mvien_LC45IE(mvien_LC45IE), .mvien_LC46IE(mvien_LC46IE), .mvien_LC47IE(mvien_LC47IE), .mvien_LC48IE(mvien_LC48IE), .mvien_LC49IE(mvien_LC49IE), .mvien_LC50IE(mvien_LC50IE), .mvien_LC51IE(mvien_LC51IE), .mvien_LC52IE(mvien_LC52IE), .mvien_LC53IE(mvien_LC53IE), .mvien_LC54IE(mvien_LC54IE), .mvien_LC55IE(mvien_LC55IE), .mvien_LC56IE(mvien_LC56IE), .mvien_LC57IE(mvien_LC57IE), .mvien_LC58IE(mvien_LC58IE), .mvien_LC59IE(mvien_LC59IE), .mvien_LC60IE(mvien_LC60IE), .mvien_LC61IE(mvien_LC61IE), .mvien_LC62IE(mvien_LC62IE), .mvien_LC63IE(mvien_LC63IE));

  wire [63:0] iprio4_1_rdata;
  Iprio4Module_1_xs u_iprio4_1(.clock(clock), .reset(reset), .w_wen(wen), .w_wdata(wdata), .rdata(iprio4_1_rdata),
    .mideleg_SSI(mideleg_SSI), .mideleg_STI(mideleg_STI), .mideleg_SEI(mideleg_SEI), .mideleg_LCOFI(mideleg_LCOFI), .mvien_SSIE(mvien_SSIE), .mvien_SEIE(mvien_SEIE), .mvien_LC14IE(mvien_LC14IE), .mvien_LC15IE(mvien_LC15IE), .mvien_LC16IE(mvien_LC16IE), .mvien_LC17IE(mvien_LC17IE), .mvien_LC18IE(mvien_LC18IE), .mvien_LC19IE(mvien_LC19IE), .mvien_LC20IE(mvien_LC20IE), .mvien_LC21IE(mvien_LC21IE), .mvien_LC22IE(mvien_LC22IE), .mvien_LC23IE(mvien_LC23IE), .mvien_LC24IE(mvien_LC24IE), .mvien_LC25IE(mvien_LC25IE), .mvien_LC26IE(mvien_LC26IE), .mvien_LC27IE(mvien_LC27IE), .mvien_LC28IE(mvien_LC28IE), .mvien_LC29IE(mvien_LC29IE), .mvien_LC30IE(mvien_LC30IE), .mvien_LC31IE(mvien_LC31IE), .mvien_LC32IE(mvien_LC32IE), .mvien_LC33IE(mvien_LC33IE), .mvien_LC34IE(mvien_LC34IE), .mvien_LPRASEIE(mvien_LPRASEIE), .mvien_LC36IE(mvien_LC36IE), .mvien_LC37IE(mvien_LC37IE), .mvien_LC38IE(mvien_LC38IE), .mvien_LC39IE(mvien_LC39IE), .mvien_LC40IE(mvien_LC40IE), .mvien_LC41IE(mvien_LC41IE), .mvien_LC42IE(mvien_LC42IE), .mvien_HPRASEIE(mvien_HPRASEIE), .mvien_LC44IE(mvien_LC44IE), .mvien_LC45IE(mvien_LC45IE), .mvien_LC46IE(mvien_LC46IE), .mvien_LC47IE(mvien_LC47IE), .mvien_LC48IE(mvien_LC48IE), .mvien_LC49IE(mvien_LC49IE), .mvien_LC50IE(mvien_LC50IE), .mvien_LC51IE(mvien_LC51IE), .mvien_LC52IE(mvien_LC52IE), .mvien_LC53IE(mvien_LC53IE), .mvien_LC54IE(mvien_LC54IE), .mvien_LC55IE(mvien_LC55IE), .mvien_LC56IE(mvien_LC56IE), .mvien_LC57IE(mvien_LC57IE), .mvien_LC58IE(mvien_LC58IE), .mvien_LC59IE(mvien_LC59IE), .mvien_LC60IE(mvien_LC60IE), .mvien_LC61IE(mvien_LC61IE), .mvien_LC62IE(mvien_LC62IE), .mvien_LC63IE(mvien_LC63IE));

  wire [63:0] iprio6_1_rdata;
  Iprio6Module_1_xs u_iprio6_1(.clock(clock), .reset(reset), .w_wen(wen), .w_wdata(wdata), .rdata(iprio6_1_rdata),
    .mideleg_SSI(mideleg_SSI), .mideleg_STI(mideleg_STI), .mideleg_SEI(mideleg_SEI), .mideleg_LCOFI(mideleg_LCOFI), .mvien_SSIE(mvien_SSIE), .mvien_SEIE(mvien_SEIE), .mvien_LC14IE(mvien_LC14IE), .mvien_LC15IE(mvien_LC15IE), .mvien_LC16IE(mvien_LC16IE), .mvien_LC17IE(mvien_LC17IE), .mvien_LC18IE(mvien_LC18IE), .mvien_LC19IE(mvien_LC19IE), .mvien_LC20IE(mvien_LC20IE), .mvien_LC21IE(mvien_LC21IE), .mvien_LC22IE(mvien_LC22IE), .mvien_LC23IE(mvien_LC23IE), .mvien_LC24IE(mvien_LC24IE), .mvien_LC25IE(mvien_LC25IE), .mvien_LC26IE(mvien_LC26IE), .mvien_LC27IE(mvien_LC27IE), .mvien_LC28IE(mvien_LC28IE), .mvien_LC29IE(mvien_LC29IE), .mvien_LC30IE(mvien_LC30IE), .mvien_LC31IE(mvien_LC31IE), .mvien_LC32IE(mvien_LC32IE), .mvien_LC33IE(mvien_LC33IE), .mvien_LC34IE(mvien_LC34IE), .mvien_LPRASEIE(mvien_LPRASEIE), .mvien_LC36IE(mvien_LC36IE), .mvien_LC37IE(mvien_LC37IE), .mvien_LC38IE(mvien_LC38IE), .mvien_LC39IE(mvien_LC39IE), .mvien_LC40IE(mvien_LC40IE), .mvien_LC41IE(mvien_LC41IE), .mvien_LC42IE(mvien_LC42IE), .mvien_HPRASEIE(mvien_HPRASEIE), .mvien_LC44IE(mvien_LC44IE), .mvien_LC45IE(mvien_LC45IE), .mvien_LC46IE(mvien_LC46IE), .mvien_LC47IE(mvien_LC47IE), .mvien_LC48IE(mvien_LC48IE), .mvien_LC49IE(mvien_LC49IE), .mvien_LC50IE(mvien_LC50IE), .mvien_LC51IE(mvien_LC51IE), .mvien_LC52IE(mvien_LC52IE), .mvien_LC53IE(mvien_LC53IE), .mvien_LC54IE(mvien_LC54IE), .mvien_LC55IE(mvien_LC55IE), .mvien_LC56IE(mvien_LC56IE), .mvien_LC57IE(mvien_LC57IE), .mvien_LC58IE(mvien_LC58IE), .mvien_LC59IE(mvien_LC59IE), .mvien_LC60IE(mvien_LC60IE), .mvien_LC61IE(mvien_LC61IE), .mvien_LC62IE(mvien_LC62IE), .mvien_LC63IE(mvien_LC63IE));

  wire [63:0] iprio8_1_rdata;
  Iprio8Module_1_xs u_iprio8_1(.clock(clock), .reset(reset), .w_wen(wen), .w_wdata(wdata), .rdata(iprio8_1_rdata),
    .mideleg_SSI(mideleg_SSI), .mideleg_STI(mideleg_STI), .mideleg_SEI(mideleg_SEI), .mideleg_LCOFI(mideleg_LCOFI), .mvien_SSIE(mvien_SSIE), .mvien_SEIE(mvien_SEIE), .mvien_LC14IE(mvien_LC14IE), .mvien_LC15IE(mvien_LC15IE), .mvien_LC16IE(mvien_LC16IE), .mvien_LC17IE(mvien_LC17IE), .mvien_LC18IE(mvien_LC18IE), .mvien_LC19IE(mvien_LC19IE), .mvien_LC20IE(mvien_LC20IE), .mvien_LC21IE(mvien_LC21IE), .mvien_LC22IE(mvien_LC22IE), .mvien_LC23IE(mvien_LC23IE), .mvien_LC24IE(mvien_LC24IE), .mvien_LC25IE(mvien_LC25IE), .mvien_LC26IE(mvien_LC26IE), .mvien_LC27IE(mvien_LC27IE), .mvien_LC28IE(mvien_LC28IE), .mvien_LC29IE(mvien_LC29IE), .mvien_LC30IE(mvien_LC30IE), .mvien_LC31IE(mvien_LC31IE), .mvien_LC32IE(mvien_LC32IE), .mvien_LC33IE(mvien_LC33IE), .mvien_LC34IE(mvien_LC34IE), .mvien_LPRASEIE(mvien_LPRASEIE), .mvien_LC36IE(mvien_LC36IE), .mvien_LC37IE(mvien_LC37IE), .mvien_LC38IE(mvien_LC38IE), .mvien_LC39IE(mvien_LC39IE), .mvien_LC40IE(mvien_LC40IE), .mvien_LC41IE(mvien_LC41IE), .mvien_LC42IE(mvien_LC42IE), .mvien_HPRASEIE(mvien_HPRASEIE), .mvien_LC44IE(mvien_LC44IE), .mvien_LC45IE(mvien_LC45IE), .mvien_LC46IE(mvien_LC46IE), .mvien_LC47IE(mvien_LC47IE), .mvien_LC48IE(mvien_LC48IE), .mvien_LC49IE(mvien_LC49IE), .mvien_LC50IE(mvien_LC50IE), .mvien_LC51IE(mvien_LC51IE), .mvien_LC52IE(mvien_LC52IE), .mvien_LC53IE(mvien_LC53IE), .mvien_LC54IE(mvien_LC54IE), .mvien_LC55IE(mvien_LC55IE), .mvien_LC56IE(mvien_LC56IE), .mvien_LC57IE(mvien_LC57IE), .mvien_LC58IE(mvien_LC58IE), .mvien_LC59IE(mvien_LC59IE), .mvien_LC60IE(mvien_LC60IE), .mvien_LC61IE(mvien_LC61IE), .mvien_LC62IE(mvien_LC62IE), .mvien_LC63IE(mvien_LC63IE));

  wire [63:0] iprio10_1_rdata;
  Iprio10Module_1_xs u_iprio10_1(.clock(clock), .reset(reset), .w_wen(wen), .w_wdata(wdata), .rdata(iprio10_1_rdata),
    .mideleg_SSI(mideleg_SSI), .mideleg_STI(mideleg_STI), .mideleg_SEI(mideleg_SEI), .mideleg_LCOFI(mideleg_LCOFI), .mvien_SSIE(mvien_SSIE), .mvien_SEIE(mvien_SEIE), .mvien_LC14IE(mvien_LC14IE), .mvien_LC15IE(mvien_LC15IE), .mvien_LC16IE(mvien_LC16IE), .mvien_LC17IE(mvien_LC17IE), .mvien_LC18IE(mvien_LC18IE), .mvien_LC19IE(mvien_LC19IE), .mvien_LC20IE(mvien_LC20IE), .mvien_LC21IE(mvien_LC21IE), .mvien_LC22IE(mvien_LC22IE), .mvien_LC23IE(mvien_LC23IE), .mvien_LC24IE(mvien_LC24IE), .mvien_LC25IE(mvien_LC25IE), .mvien_LC26IE(mvien_LC26IE), .mvien_LC27IE(mvien_LC27IE), .mvien_LC28IE(mvien_LC28IE), .mvien_LC29IE(mvien_LC29IE), .mvien_LC30IE(mvien_LC30IE), .mvien_LC31IE(mvien_LC31IE), .mvien_LC32IE(mvien_LC32IE), .mvien_LC33IE(mvien_LC33IE), .mvien_LC34IE(mvien_LC34IE), .mvien_LPRASEIE(mvien_LPRASEIE), .mvien_LC36IE(mvien_LC36IE), .mvien_LC37IE(mvien_LC37IE), .mvien_LC38IE(mvien_LC38IE), .mvien_LC39IE(mvien_LC39IE), .mvien_LC40IE(mvien_LC40IE), .mvien_LC41IE(mvien_LC41IE), .mvien_LC42IE(mvien_LC42IE), .mvien_HPRASEIE(mvien_HPRASEIE), .mvien_LC44IE(mvien_LC44IE), .mvien_LC45IE(mvien_LC45IE), .mvien_LC46IE(mvien_LC46IE), .mvien_LC47IE(mvien_LC47IE), .mvien_LC48IE(mvien_LC48IE), .mvien_LC49IE(mvien_LC49IE), .mvien_LC50IE(mvien_LC50IE), .mvien_LC51IE(mvien_LC51IE), .mvien_LC52IE(mvien_LC52IE), .mvien_LC53IE(mvien_LC53IE), .mvien_LC54IE(mvien_LC54IE), .mvien_LC55IE(mvien_LC55IE), .mvien_LC56IE(mvien_LC56IE), .mvien_LC57IE(mvien_LC57IE), .mvien_LC58IE(mvien_LC58IE), .mvien_LC59IE(mvien_LC59IE), .mvien_LC60IE(mvien_LC60IE), .mvien_LC61IE(mvien_LC61IE), .mvien_LC62IE(mvien_LC62IE), .mvien_LC63IE(mvien_LC63IE));

  wire [63:0] iprio12_1_rdata;
  Iprio12Module_1_xs u_iprio12_1(.clock(clock), .reset(reset), .w_wen(wen), .w_wdata(wdata), .rdata(iprio12_1_rdata),
    .mideleg_SSI(mideleg_SSI), .mideleg_STI(mideleg_STI), .mideleg_SEI(mideleg_SEI), .mideleg_LCOFI(mideleg_LCOFI), .mvien_SSIE(mvien_SSIE), .mvien_SEIE(mvien_SEIE), .mvien_LC14IE(mvien_LC14IE), .mvien_LC15IE(mvien_LC15IE), .mvien_LC16IE(mvien_LC16IE), .mvien_LC17IE(mvien_LC17IE), .mvien_LC18IE(mvien_LC18IE), .mvien_LC19IE(mvien_LC19IE), .mvien_LC20IE(mvien_LC20IE), .mvien_LC21IE(mvien_LC21IE), .mvien_LC22IE(mvien_LC22IE), .mvien_LC23IE(mvien_LC23IE), .mvien_LC24IE(mvien_LC24IE), .mvien_LC25IE(mvien_LC25IE), .mvien_LC26IE(mvien_LC26IE), .mvien_LC27IE(mvien_LC27IE), .mvien_LC28IE(mvien_LC28IE), .mvien_LC29IE(mvien_LC29IE), .mvien_LC30IE(mvien_LC30IE), .mvien_LC31IE(mvien_LC31IE), .mvien_LC32IE(mvien_LC32IE), .mvien_LC33IE(mvien_LC33IE), .mvien_LC34IE(mvien_LC34IE), .mvien_LPRASEIE(mvien_LPRASEIE), .mvien_LC36IE(mvien_LC36IE), .mvien_LC37IE(mvien_LC37IE), .mvien_LC38IE(mvien_LC38IE), .mvien_LC39IE(mvien_LC39IE), .mvien_LC40IE(mvien_LC40IE), .mvien_LC41IE(mvien_LC41IE), .mvien_LC42IE(mvien_LC42IE), .mvien_HPRASEIE(mvien_HPRASEIE), .mvien_LC44IE(mvien_LC44IE), .mvien_LC45IE(mvien_LC45IE), .mvien_LC46IE(mvien_LC46IE), .mvien_LC47IE(mvien_LC47IE), .mvien_LC48IE(mvien_LC48IE), .mvien_LC49IE(mvien_LC49IE), .mvien_LC50IE(mvien_LC50IE), .mvien_LC51IE(mvien_LC51IE), .mvien_LC52IE(mvien_LC52IE), .mvien_LC53IE(mvien_LC53IE), .mvien_LC54IE(mvien_LC54IE), .mvien_LC55IE(mvien_LC55IE), .mvien_LC56IE(mvien_LC56IE), .mvien_LC57IE(mvien_LC57IE), .mvien_LC58IE(mvien_LC58IE), .mvien_LC59IE(mvien_LC59IE), .mvien_LC60IE(mvien_LC60IE), .mvien_LC61IE(mvien_LC61IE), .mvien_LC62IE(mvien_LC62IE), .mvien_LC63IE(mvien_LC63IE));

  wire [63:0] iprio14_1_rdata;
  Iprio14Module_1_xs u_iprio14_1(.clock(clock), .reset(reset), .w_wen(wen), .w_wdata(wdata), .rdata(iprio14_1_rdata),
    .mideleg_SSI(mideleg_SSI), .mideleg_STI(mideleg_STI), .mideleg_SEI(mideleg_SEI), .mideleg_LCOFI(mideleg_LCOFI), .mvien_SSIE(mvien_SSIE), .mvien_SEIE(mvien_SEIE), .mvien_LC14IE(mvien_LC14IE), .mvien_LC15IE(mvien_LC15IE), .mvien_LC16IE(mvien_LC16IE), .mvien_LC17IE(mvien_LC17IE), .mvien_LC18IE(mvien_LC18IE), .mvien_LC19IE(mvien_LC19IE), .mvien_LC20IE(mvien_LC20IE), .mvien_LC21IE(mvien_LC21IE), .mvien_LC22IE(mvien_LC22IE), .mvien_LC23IE(mvien_LC23IE), .mvien_LC24IE(mvien_LC24IE), .mvien_LC25IE(mvien_LC25IE), .mvien_LC26IE(mvien_LC26IE), .mvien_LC27IE(mvien_LC27IE), .mvien_LC28IE(mvien_LC28IE), .mvien_LC29IE(mvien_LC29IE), .mvien_LC30IE(mvien_LC30IE), .mvien_LC31IE(mvien_LC31IE), .mvien_LC32IE(mvien_LC32IE), .mvien_LC33IE(mvien_LC33IE), .mvien_LC34IE(mvien_LC34IE), .mvien_LPRASEIE(mvien_LPRASEIE), .mvien_LC36IE(mvien_LC36IE), .mvien_LC37IE(mvien_LC37IE), .mvien_LC38IE(mvien_LC38IE), .mvien_LC39IE(mvien_LC39IE), .mvien_LC40IE(mvien_LC40IE), .mvien_LC41IE(mvien_LC41IE), .mvien_LC42IE(mvien_LC42IE), .mvien_HPRASEIE(mvien_HPRASEIE), .mvien_LC44IE(mvien_LC44IE), .mvien_LC45IE(mvien_LC45IE), .mvien_LC46IE(mvien_LC46IE), .mvien_LC47IE(mvien_LC47IE), .mvien_LC48IE(mvien_LC48IE), .mvien_LC49IE(mvien_LC49IE), .mvien_LC50IE(mvien_LC50IE), .mvien_LC51IE(mvien_LC51IE), .mvien_LC52IE(mvien_LC52IE), .mvien_LC53IE(mvien_LC53IE), .mvien_LC54IE(mvien_LC54IE), .mvien_LC55IE(mvien_LC55IE), .mvien_LC56IE(mvien_LC56IE), .mvien_LC57IE(mvien_LC57IE), .mvien_LC58IE(mvien_LC58IE), .mvien_LC59IE(mvien_LC59IE), .mvien_LC60IE(mvien_LC60IE), .mvien_LC61IE(mvien_LC61IE), .mvien_LC62IE(mvien_LC62IE), .mvien_LC63IE(mvien_LC63IE));

  wire [63:0] hpm_rdata;
  wire hpm_of, hpm_minh, hpm_sinh, hpm_uinh, hpm_vsinh, hpm_vuinh;
  wire [4:0] hpm_op2, hpm_op1, hpm_op0;
  wire [9:0] hpm_e3, hpm_e2, hpm_e1, hpm_e0;
  logic of_perf;
  MhpmeventModule_xs hpm(
    .clock, .reset, .w_wen(wen), .w_wdata(wdata), .rdata(hpm_rdata),
    .regOut_OF(hpm_of), .regOut_MINH(hpm_minh), .regOut_SINH(hpm_sinh),
    .regOut_UINH(hpm_uinh), .regOut_VSINH(hpm_vsinh), .regOut_VUINH(hpm_vuinh),
    .regOut_OPTYPE2(hpm_op2), .regOut_OPTYPE1(hpm_op1), .regOut_OPTYPE0(hpm_op0),
    .regOut_EVENT3(hpm_e3), .regOut_EVENT2(hpm_e2), .regOut_EVENT1(hpm_e1), .regOut_EVENT0(hpm_e0),
    .ofFromPerfCnt(of_perf));

  logic stime_valid, vstime_valid, stimecmp_wen, vstimecmp_wen, hdelta_wen;
  logic menvcfg_wen, menvcfg_stce, henvcfg_wen, henvcfg_stce;
  logic [63:0] stime, vstime, stimecmp, vstimecmp;
  wire stip, vstip;
  SstcInterruptGen_xs sstc(
    .clock, .reset, .i_stime_valid(stime_valid), .i_stime_bits(stime),
    .i_vstime_valid(vstime_valid), .i_vstime_bits(vstime),
    .i_stimecmp_wen(stimecmp_wen), .i_stimecmp_rdata(stimecmp),
    .i_vstimecmp_wen(vstimecmp_wen), .i_vstimecmp_rdata(vstimecmp),
    .i_htimedeltaWen(hdelta_wen), .i_menvcfg_wen(menvcfg_wen),
    .i_menvcfg_STCE(menvcfg_stce), .i_henvcfg_wen(henvcfg_wen),
    .i_henvcfg_STCE(henvcfg_stce), .o_STIP(stip), .o_VSTIP(vstip));

  task automatic fail(input string msg);
    $display("FAIL: %s", msg);
    $finish(1);
  endtask

  task automatic check(input logic condition, input string msg);
    if (!condition) fail(msg);
  endtask

  initial begin
    wen = 0; wdata = 0; of_perf = 0;
    stime_valid = 0; vstime_valid = 0; stimecmp_wen = 0; vstimecmp_wen = 0;
    hdelta_wen = 0; menvcfg_wen = 0; menvcfg_stce = 0; henvcfg_wen = 0; henvcfg_stce = 0;
    stime = 0; vstime = 0; stimecmp = 0; vstimecmp = 0;
    mideleg_SSI = 1;
    mideleg_STI = 1;
    mideleg_SEI = 1;
    mideleg_LCOFI = 1;
    mvien_SSIE = 1;
    mvien_SEIE = 1;
    mvien_LC14IE = 1;
    mvien_LC15IE = 1;
    mvien_LC16IE = 1;
    mvien_LC17IE = 1;
    mvien_LC18IE = 1;
    mvien_LC19IE = 1;
    mvien_LC20IE = 1;
    mvien_LC21IE = 1;
    mvien_LC22IE = 1;
    mvien_LC23IE = 1;
    mvien_LC24IE = 1;
    mvien_LC25IE = 1;
    mvien_LC26IE = 1;
    mvien_LC27IE = 1;
    mvien_LC28IE = 1;
    mvien_LC29IE = 1;
    mvien_LC30IE = 1;
    mvien_LC31IE = 1;
    mvien_LC32IE = 1;
    mvien_LC33IE = 1;
    mvien_LC34IE = 1;
    mvien_LPRASEIE = 1;
    mvien_LC36IE = 1;
    mvien_LC37IE = 1;
    mvien_LC38IE = 1;
    mvien_LC39IE = 1;
    mvien_LC40IE = 1;
    mvien_LC41IE = 1;
    mvien_LC42IE = 1;
    mvien_HPRASEIE = 1;
    mvien_LC44IE = 1;
    mvien_LC45IE = 1;
    mvien_LC46IE = 1;
    mvien_LC47IE = 1;
    mvien_LC48IE = 1;
    mvien_LC49IE = 1;
    mvien_LC50IE = 1;
    mvien_LC51IE = 1;
    mvien_LC52IE = 1;
    mvien_LC53IE = 1;
    mvien_LC54IE = 1;
    mvien_LC55IE = 1;
    mvien_LC56IE = 1;
    mvien_LC57IE = 1;
    mvien_LC58IE = 1;
    mvien_LC59IE = 1;
    mvien_LC60IE = 1;
    mvien_LC61IE = 1;
    mvien_LC62IE = 1;
    mvien_LC63IE = 1;
    repeat (2) @(posedge clock);
    #1;
    reset = 1'b0;
    #1;
    check(ip0_rdata == 64'h0, "Iprio0 reset");
    check(ip2_rdata == 64'h0, "Iprio2 reset");
    check(hpm_rdata == 64'h0, "mhpmevent reset");
    check(!stip && !vstip, "sstc reset");

    // Priority byte placement follows the CSR map.
    @(negedge clock); wdata = 64'h66554433221100aa; wen = 1;
    @(posedge clock); #1; wen = 0;
    check(ip0_rdata == 64'h6655440022110000, "Iprio0 byte map");
    check(ip2_rdata == 64'h0000443300110000, "Iprio2 byte map");
    check(iprio0_1_rdata == 64'h0055440000110000, "Iprio0Module_1 masked map");
    check(iprio2_1_rdata == 64'h6655443300110000, "Iprio2Module_1 masked map");
    check(iprio4_1_rdata == 64'h66554433221100aa, "Iprio4Module_1 masked map");
    check(iprio6_1_rdata == 64'h66554433221100aa, "Iprio6Module_1 masked map");
    check(iprio8_1_rdata == 64'h66554433221100aa, "Iprio8Module_1 masked map");
    check(iprio10_1_rdata == 64'h66554433221100aa, "Iprio10Module_1 masked map");
    check(iprio12_1_rdata == 64'h66554433221100aa, "Iprio12Module_1 masked map");
    check(iprio14_1_rdata == 64'h66554433221100aa, "Iprio14Module_1 masked map");

    // HPM event fields and legal operation-type WARL.
    @(negedge clock); wdata = 64'hfc00816789abcdef; wen = 1;
    @(posedge clock); #1; wen = 0;
    check(hpm_rdata[63:58] == 6'h3f, "mhpmevent inhibit fields");
    check(hpm_rdata[39:0] == 40'h6789abcdef, "mhpmevent event fields");
    check(hpm_op2 == 5'h0, "illegal optype2 rejected");
    check(hpm_op1 == 5'h4, "legal optype1 accepted");
    check(hpm_op0 == 5'h1, "legal optype0 accepted");
    of_perf = 1; @(posedge clock); #1; of_perf = 0;
    check(hpm_of, "overflow event sets OF");

    // Sstc outputs only update on valid/write/config events.
    @(negedge clock); stime = 64'd9; stimecmp = 64'd8; menvcfg_stce = 1; stime_valid = 1; menvcfg_wen = 1;
    @(posedge clock); #1; stime_valid = 0; menvcfg_wen = 0;
    check(stip, "STIP compare true");
    @(negedge clock); stime = 64'd7; stime_valid = 0;
    @(posedge clock); #1;
    check(stip, "STIP holds without event");
    @(negedge clock); stime_valid = 1;
    @(posedge clock); #1; stime_valid = 0;
    check(!stip, "STIP clears on time update");

    $display("TEST PASSED");
    $finish(0);
  end
endmodule
