// NewCSR interrupt enable/pending alias CSRs — readable transcriptions.
//   SieModule / SipModule   : supervisor {enable,pending} = the mie/mip bits that
//                             are delegated to S (mideleg) plus mvien/mvip-aliased
//                             local interrupts, masked per bit.
//   VSieModule / VSipModule : VS-mode views, gated by hideleg / hvien / hvip.
//
// The golden bodies are structural alias logic (mostly combinational). The
// readable rewrite drops the sim randomize-init block and renames the CIRCT
// intermediate wires to readable names:
//   aliasVec / aliasVec2  = the assembled 62/63-bit effective sip/sie vector
//   <FIELD>_masked        = one delegated/aliased bit sliced from aliasVec
//   lcofiDelegated        = hideleg_LCOFI & mideleg_LCOFI (VS LCOFI reachability)
// FM-verified strict golden-vs-impl SUCCEEDED, no black box, no dont_verify.


module SieModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SSIE,
  output        regOut_STIE,
  output        regOut_SEIE,
  output        regOut_LCOFIE,
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
  output        regOut_LC63IE,
  input         mideleg_SSI,
  input         mideleg_STI,
  input         mideleg_SEI,
  input         mideleg_LCOFI,
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
  input         mie_LCOFIE,
  input         mvien_SSIE,
  input         mvien_SEIE,
  input         mvien_LC14IE,
  input         mvien_LC15IE,
  input         mvien_LC16IE,
  input         mvien_LC17IE,
  input         mvien_LC18IE,
  input         mvien_LC19IE,
  input         mvien_LC20IE,
  input         mvien_LC21IE,
  input         mvien_LC22IE,
  input         mvien_LC23IE,
  input         mvien_LC24IE,
  input         mvien_LC25IE,
  input         mvien_LC26IE,
  input         mvien_LC27IE,
  input         mvien_LC28IE,
  input         mvien_LC29IE,
  input         mvien_LC30IE,
  input         mvien_LC31IE,
  input         mvien_LC32IE,
  input         mvien_LC33IE,
  input         mvien_LC34IE,
  input         mvien_LPRASEIE,
  input         mvien_LC36IE,
  input         mvien_LC37IE,
  input         mvien_LC38IE,
  input         mvien_LC39IE,
  input         mvien_LC40IE,
  input         mvien_LC41IE,
  input         mvien_LC42IE,
  input         mvien_HPRASEIE,
  input         mvien_LC44IE,
  input         mvien_LC45IE,
  input         mvien_LC46IE,
  input         mvien_LC47IE,
  input         mvien_LC48IE,
  input         mvien_LC49IE,
  input         mvien_LC50IE,
  input         mvien_LC51IE,
  input         mvien_LC52IE,
  input         mvien_LC53IE,
  input         mvien_LC54IE,
  input         mvien_LC55IE,
  input         mvien_LC56IE,
  input         mvien_LC57IE,
  input         mvien_LC58IE,
  input         mvien_LC59IE,
  input         mvien_LC60IE,
  input         mvien_LC61IE,
  input         mvien_LC62IE,
  input         mvien_LC63IE,
  output        toMie_SSIE_valid,
  output        toMie_SSIE_bits,
  output        toMie_STIE_valid,
  output        toMie_STIE_bits,
  output        toMie_SEIE_valid,
  output        toMie_SEIE_bits,
  output        toMie_LCOFIE_valid,
  output        toMie_LCOFIE_bits,
  input         fromVSie_VSSIE_valid,
  input         fromVSie_VSSIE_bits,
  input         fromVSie_VSTIE_valid,
  input         fromVSie_VSTIE_bits,
  input         fromVSie_VSEIE_valid,
  input         fromVSie_VSEIE_bits,
  input         fromVSie_LCOFIE_valid,
  input         fromVSie_LCOFIE_bits,
  input         fromVSie_LC14IE_valid,
  input         fromVSie_LC14IE_bits,
  input         fromVSie_LC15IE_valid,
  input         fromVSie_LC15IE_bits,
  input         fromVSie_LC16IE_valid,
  input         fromVSie_LC16IE_bits,
  input         fromVSie_LC17IE_valid,
  input         fromVSie_LC17IE_bits,
  input         fromVSie_LC18IE_valid,
  input         fromVSie_LC18IE_bits,
  input         fromVSie_LC19IE_valid,
  input         fromVSie_LC19IE_bits,
  input         fromVSie_LC20IE_valid,
  input         fromVSie_LC20IE_bits,
  input         fromVSie_LC21IE_valid,
  input         fromVSie_LC21IE_bits,
  input         fromVSie_LC22IE_valid,
  input         fromVSie_LC22IE_bits,
  input         fromVSie_LC23IE_valid,
  input         fromVSie_LC23IE_bits,
  input         fromVSie_LC24IE_valid,
  input         fromVSie_LC24IE_bits,
  input         fromVSie_LC25IE_valid,
  input         fromVSie_LC25IE_bits,
  input         fromVSie_LC26IE_valid,
  input         fromVSie_LC26IE_bits,
  input         fromVSie_LC27IE_valid,
  input         fromVSie_LC27IE_bits,
  input         fromVSie_LC28IE_valid,
  input         fromVSie_LC28IE_bits,
  input         fromVSie_LC29IE_valid,
  input         fromVSie_LC29IE_bits,
  input         fromVSie_LC30IE_valid,
  input         fromVSie_LC30IE_bits,
  input         fromVSie_LC31IE_valid,
  input         fromVSie_LC31IE_bits,
  input         fromVSie_LC32IE_valid,
  input         fromVSie_LC32IE_bits,
  input         fromVSie_LC33IE_valid,
  input         fromVSie_LC33IE_bits,
  input         fromVSie_LC34IE_valid,
  input         fromVSie_LC34IE_bits,
  input         fromVSie_LPRASEIE_valid,
  input         fromVSie_LPRASEIE_bits,
  input         fromVSie_LC36IE_valid,
  input         fromVSie_LC36IE_bits,
  input         fromVSie_LC37IE_valid,
  input         fromVSie_LC37IE_bits,
  input         fromVSie_LC38IE_valid,
  input         fromVSie_LC38IE_bits,
  input         fromVSie_LC39IE_valid,
  input         fromVSie_LC39IE_bits,
  input         fromVSie_LC40IE_valid,
  input         fromVSie_LC40IE_bits,
  input         fromVSie_LC41IE_valid,
  input         fromVSie_LC41IE_bits,
  input         fromVSie_LC42IE_valid,
  input         fromVSie_LC42IE_bits,
  input         fromVSie_HPRASEIE_valid,
  input         fromVSie_HPRASEIE_bits,
  input         fromVSie_LC44IE_valid,
  input         fromVSie_LC44IE_bits,
  input         fromVSie_LC45IE_valid,
  input         fromVSie_LC45IE_bits,
  input         fromVSie_LC46IE_valid,
  input         fromVSie_LC46IE_bits,
  input         fromVSie_LC47IE_valid,
  input         fromVSie_LC47IE_bits,
  input         fromVSie_LC48IE_valid,
  input         fromVSie_LC48IE_bits,
  input         fromVSie_LC49IE_valid,
  input         fromVSie_LC49IE_bits,
  input         fromVSie_LC50IE_valid,
  input         fromVSie_LC50IE_bits,
  input         fromVSie_LC51IE_valid,
  input         fromVSie_LC51IE_bits,
  input         fromVSie_LC52IE_valid,
  input         fromVSie_LC52IE_bits,
  input         fromVSie_LC53IE_valid,
  input         fromVSie_LC53IE_bits,
  input         fromVSie_LC54IE_valid,
  input         fromVSie_LC54IE_bits,
  input         fromVSie_LC55IE_valid,
  input         fromVSie_LC55IE_bits,
  input         fromVSie_LC56IE_valid,
  input         fromVSie_LC56IE_bits,
  input         fromVSie_LC57IE_valid,
  input         fromVSie_LC57IE_bits,
  input         fromVSie_LC58IE_valid,
  input         fromVSie_LC58IE_bits,
  input         fromVSie_LC59IE_valid,
  input         fromVSie_LC59IE_bits,
  input         fromVSie_LC60IE_valid,
  input         fromVSie_LC60IE_bits,
  input         fromVSie_LC61IE_valid,
  input         fromVSie_LC61IE_bits,
  input         fromVSie_LC62IE_valid,
  input         fromVSie_LC62IE_bits,
  input         fromVSie_LC63IE_valid,
  input         fromVSie_LC63IE_bits
);

  wire        SSIE_masked;
  wire        STIE_masked;
  wire        SEIE_masked;
  wire [62:0] aliasVec;
  reg         reg_SSIE;
  reg         reg_SEIE;
  reg         reg_LC14IE;
  reg         reg_LC15IE;
  reg         reg_LC16IE;
  reg         reg_LC17IE;
  reg         reg_LC18IE;
  reg         reg_LC19IE;
  reg         reg_LC20IE;
  reg         reg_LC21IE;
  reg         reg_LC22IE;
  reg         reg_LC23IE;
  reg         reg_LC24IE;
  reg         reg_LC25IE;
  reg         reg_LC26IE;
  reg         reg_LC27IE;
  reg         reg_LC28IE;
  reg         reg_LC29IE;
  reg         reg_LC30IE;
  reg         reg_LC31IE;
  reg         reg_LC32IE;
  reg         reg_LC33IE;
  reg         reg_LC34IE;
  reg         reg_LPRASEIE;
  reg         reg_LC36IE;
  reg         reg_LC37IE;
  reg         reg_LC38IE;
  reg         reg_LC39IE;
  reg         reg_LC40IE;
  reg         reg_LC41IE;
  reg         reg_LC42IE;
  reg         reg_HPRASEIE;
  reg         reg_LC44IE;
  reg         reg_LC45IE;
  reg         reg_LC46IE;
  reg         reg_LC47IE;
  reg         reg_LC48IE;
  reg         reg_LC49IE;
  reg         reg_LC50IE;
  reg         reg_LC51IE;
  reg         reg_LC52IE;
  reg         reg_LC53IE;
  reg         reg_LC54IE;
  reg         reg_LC55IE;
  reg         reg_LC56IE;
  reg         reg_LC57IE;
  reg         reg_LC58IE;
  reg         reg_LC59IE;
  reg         reg_LC60IE;
  reg         reg_LC61IE;
  reg         reg_LC62IE;
  reg         reg_LC63IE;
  assign aliasVec =
    {50'h0, mideleg_LCOFI, 3'h5, mideleg_SEI, 3'h1, mideleg_STI, 3'h1, mideleg_SSI}
    & {50'h0,
       mie_LCOFIE,
       mie_SGEIE,
       mie_MEIE,
       mie_VSEIE,
       mie_SEIE,
       1'h0,
       mie_MTIE,
       mie_VSTIE,
       mie_STIE,
       1'h0,
       mie_MSIE,
       mie_VSSIE,
       mie_SSIE}
    | {50'h3FFFFFFFFFFFF,
       ~mideleg_LCOFI,
       3'h2,
       ~mideleg_SEI,
       3'h6,
       ~mideleg_STI,
       3'h6,
       ~mideleg_SSI}
    & {mvien_LC63IE,
       mvien_LC62IE,
       mvien_LC61IE,
       mvien_LC60IE,
       mvien_LC59IE,
       mvien_LC58IE,
       mvien_LC57IE,
       mvien_LC56IE,
       mvien_LC55IE,
       mvien_LC54IE,
       mvien_LC53IE,
       mvien_LC52IE,
       mvien_LC51IE,
       mvien_LC50IE,
       mvien_LC49IE,
       mvien_LC48IE,
       mvien_LC47IE,
       mvien_LC46IE,
       mvien_LC45IE,
       mvien_LC44IE,
       mvien_HPRASEIE,
       mvien_LC42IE,
       mvien_LC41IE,
       mvien_LC40IE,
       mvien_LC39IE,
       mvien_LC38IE,
       mvien_LC37IE,
       mvien_LC36IE,
       mvien_LPRASEIE,
       mvien_LC34IE,
       mvien_LC33IE,
       mvien_LC32IE,
       mvien_LC31IE,
       mvien_LC30IE,
       mvien_LC29IE,
       mvien_LC28IE,
       mvien_LC27IE,
       mvien_LC26IE,
       mvien_LC25IE,
       mvien_LC24IE,
       mvien_LC23IE,
       mvien_LC22IE,
       mvien_LC21IE,
       mvien_LC20IE,
       mvien_LC19IE,
       mvien_LC18IE,
       mvien_LC17IE,
       mvien_LC16IE,
       mvien_LC15IE,
       mvien_LC14IE,
       4'h0,
       mvien_SEIE,
       7'h0,
       mvien_SSIE}
    & {reg_LC63IE,
       reg_LC62IE,
       reg_LC61IE,
       reg_LC60IE,
       reg_LC59IE,
       reg_LC58IE,
       reg_LC57IE,
       reg_LC56IE,
       reg_LC55IE,
       reg_LC54IE,
       reg_LC53IE,
       reg_LC52IE,
       reg_LC51IE,
       reg_LC50IE,
       reg_LC49IE,
       reg_LC48IE,
       reg_LC47IE,
       reg_LC46IE,
       reg_LC45IE,
       reg_LC44IE,
       reg_HPRASEIE,
       reg_LC42IE,
       reg_LC41IE,
       reg_LC40IE,
       reg_LC39IE,
       reg_LC38IE,
       reg_LC37IE,
       reg_LC36IE,
       reg_LPRASEIE,
       reg_LC34IE,
       reg_LC33IE,
       reg_LC32IE,
       reg_LC31IE,
       reg_LC30IE,
       reg_LC29IE,
       reg_LC28IE,
       reg_LC27IE,
       reg_LC26IE,
       reg_LC25IE,
       reg_LC24IE,
       reg_LC23IE,
       reg_LC22IE,
       reg_LC21IE,
       reg_LC20IE,
       reg_LC19IE,
       reg_LC18IE,
       reg_LC17IE,
       reg_LC16IE,
       reg_LC15IE,
       reg_LC14IE,
       4'h0,
       reg_SEIE,
       7'h0,
       reg_SSIE};
  assign SEIE_masked = aliasVec[8];
  assign STIE_masked = aliasVec[4];
  assign SSIE_masked = aliasVec[0];
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_SSIE <= 1'h0;
      reg_SEIE <= 1'h0;
      reg_LC14IE <= 1'h0;
      reg_LC15IE <= 1'h0;
      reg_LC16IE <= 1'h0;
      reg_LC17IE <= 1'h0;
      reg_LC18IE <= 1'h0;
      reg_LC19IE <= 1'h0;
      reg_LC20IE <= 1'h0;
      reg_LC21IE <= 1'h0;
      reg_LC22IE <= 1'h0;
      reg_LC23IE <= 1'h0;
      reg_LC24IE <= 1'h0;
      reg_LC25IE <= 1'h0;
      reg_LC26IE <= 1'h0;
      reg_LC27IE <= 1'h0;
      reg_LC28IE <= 1'h0;
      reg_LC29IE <= 1'h0;
      reg_LC30IE <= 1'h0;
      reg_LC31IE <= 1'h0;
      reg_LC32IE <= 1'h0;
      reg_LC33IE <= 1'h0;
      reg_LC34IE <= 1'h0;
      reg_LPRASEIE <= 1'h0;
      reg_LC36IE <= 1'h0;
      reg_LC37IE <= 1'h0;
      reg_LC38IE <= 1'h0;
      reg_LC39IE <= 1'h0;
      reg_LC40IE <= 1'h0;
      reg_LC41IE <= 1'h0;
      reg_LC42IE <= 1'h0;
      reg_HPRASEIE <= 1'h0;
      reg_LC44IE <= 1'h0;
      reg_LC45IE <= 1'h0;
      reg_LC46IE <= 1'h0;
      reg_LC47IE <= 1'h0;
      reg_LC48IE <= 1'h0;
      reg_LC49IE <= 1'h0;
      reg_LC50IE <= 1'h0;
      reg_LC51IE <= 1'h0;
      reg_LC52IE <= 1'h0;
      reg_LC53IE <= 1'h0;
      reg_LC54IE <= 1'h0;
      reg_LC55IE <= 1'h0;
      reg_LC56IE <= 1'h0;
      reg_LC57IE <= 1'h0;
      reg_LC58IE <= 1'h0;
      reg_LC59IE <= 1'h0;
      reg_LC60IE <= 1'h0;
      reg_LC61IE <= 1'h0;
      reg_LC62IE <= 1'h0;
      reg_LC63IE <= 1'h0;
    end
    else begin
      if (w_wen & ~mideleg_SSI & mvien_SSIE)
        reg_SSIE <= w_wen & w_wdata[1];
      if (w_wen & ~mideleg_SEI & mvien_SEIE)
        reg_SEIE <= w_wen & w_wdata[9];
      if (w_wen & mvien_LC14IE | fromVSie_LC14IE_valid & mvien_LC14IE)
        reg_LC14IE <= w_wen & w_wdata[14] | fromVSie_LC14IE_valid & fromVSie_LC14IE_bits;
      if (w_wen & mvien_LC15IE | fromVSie_LC15IE_valid & mvien_LC15IE)
        reg_LC15IE <= w_wen & w_wdata[15] | fromVSie_LC15IE_valid & fromVSie_LC15IE_bits;
      if (w_wen & mvien_LC16IE | fromVSie_LC16IE_valid & mvien_LC16IE)
        reg_LC16IE <= w_wen & w_wdata[16] | fromVSie_LC16IE_valid & fromVSie_LC16IE_bits;
      if (w_wen & mvien_LC17IE | fromVSie_LC17IE_valid & mvien_LC17IE)
        reg_LC17IE <= w_wen & w_wdata[17] | fromVSie_LC17IE_valid & fromVSie_LC17IE_bits;
      if (w_wen & mvien_LC18IE | fromVSie_LC18IE_valid & mvien_LC18IE)
        reg_LC18IE <= w_wen & w_wdata[18] | fromVSie_LC18IE_valid & fromVSie_LC18IE_bits;
      if (w_wen & mvien_LC19IE | fromVSie_LC19IE_valid & mvien_LC19IE)
        reg_LC19IE <= w_wen & w_wdata[19] | fromVSie_LC19IE_valid & fromVSie_LC19IE_bits;
      if (w_wen & mvien_LC20IE | fromVSie_LC20IE_valid & mvien_LC20IE)
        reg_LC20IE <= w_wen & w_wdata[20] | fromVSie_LC20IE_valid & fromVSie_LC20IE_bits;
      if (w_wen & mvien_LC21IE | fromVSie_LC21IE_valid & mvien_LC21IE)
        reg_LC21IE <= w_wen & w_wdata[21] | fromVSie_LC21IE_valid & fromVSie_LC21IE_bits;
      if (w_wen & mvien_LC22IE | fromVSie_LC22IE_valid & mvien_LC22IE)
        reg_LC22IE <= w_wen & w_wdata[22] | fromVSie_LC22IE_valid & fromVSie_LC22IE_bits;
      if (w_wen & mvien_LC23IE | fromVSie_LC23IE_valid & mvien_LC23IE)
        reg_LC23IE <= w_wen & w_wdata[23] | fromVSie_LC23IE_valid & fromVSie_LC23IE_bits;
      if (w_wen & mvien_LC24IE | fromVSie_LC24IE_valid & mvien_LC24IE)
        reg_LC24IE <= w_wen & w_wdata[24] | fromVSie_LC24IE_valid & fromVSie_LC24IE_bits;
      if (w_wen & mvien_LC25IE | fromVSie_LC25IE_valid & mvien_LC25IE)
        reg_LC25IE <= w_wen & w_wdata[25] | fromVSie_LC25IE_valid & fromVSie_LC25IE_bits;
      if (w_wen & mvien_LC26IE | fromVSie_LC26IE_valid & mvien_LC26IE)
        reg_LC26IE <= w_wen & w_wdata[26] | fromVSie_LC26IE_valid & fromVSie_LC26IE_bits;
      if (w_wen & mvien_LC27IE | fromVSie_LC27IE_valid & mvien_LC27IE)
        reg_LC27IE <= w_wen & w_wdata[27] | fromVSie_LC27IE_valid & fromVSie_LC27IE_bits;
      if (w_wen & mvien_LC28IE | fromVSie_LC28IE_valid & mvien_LC28IE)
        reg_LC28IE <= w_wen & w_wdata[28] | fromVSie_LC28IE_valid & fromVSie_LC28IE_bits;
      if (w_wen & mvien_LC29IE | fromVSie_LC29IE_valid & mvien_LC29IE)
        reg_LC29IE <= w_wen & w_wdata[29] | fromVSie_LC29IE_valid & fromVSie_LC29IE_bits;
      if (w_wen & mvien_LC30IE | fromVSie_LC30IE_valid & mvien_LC30IE)
        reg_LC30IE <= w_wen & w_wdata[30] | fromVSie_LC30IE_valid & fromVSie_LC30IE_bits;
      if (w_wen & mvien_LC31IE | fromVSie_LC31IE_valid & mvien_LC31IE)
        reg_LC31IE <= w_wen & w_wdata[31] | fromVSie_LC31IE_valid & fromVSie_LC31IE_bits;
      if (w_wen & mvien_LC32IE | fromVSie_LC32IE_valid & mvien_LC32IE)
        reg_LC32IE <= w_wen & w_wdata[32] | fromVSie_LC32IE_valid & fromVSie_LC32IE_bits;
      if (w_wen & mvien_LC33IE | fromVSie_LC33IE_valid & mvien_LC33IE)
        reg_LC33IE <= w_wen & w_wdata[33] | fromVSie_LC33IE_valid & fromVSie_LC33IE_bits;
      if (w_wen & mvien_LC34IE | fromVSie_LC34IE_valid & mvien_LC34IE)
        reg_LC34IE <= w_wen & w_wdata[34] | fromVSie_LC34IE_valid & fromVSie_LC34IE_bits;
      if (w_wen & mvien_LPRASEIE | fromVSie_LPRASEIE_valid & mvien_LPRASEIE)
        reg_LPRASEIE <=
          w_wen & w_wdata[35] | fromVSie_LPRASEIE_valid & fromVSie_LPRASEIE_bits;
      if (w_wen & mvien_LC36IE | fromVSie_LC36IE_valid & mvien_LC36IE)
        reg_LC36IE <= w_wen & w_wdata[36] | fromVSie_LC36IE_valid & fromVSie_LC36IE_bits;
      if (w_wen & mvien_LC37IE | fromVSie_LC37IE_valid & mvien_LC37IE)
        reg_LC37IE <= w_wen & w_wdata[37] | fromVSie_LC37IE_valid & fromVSie_LC37IE_bits;
      if (w_wen & mvien_LC38IE | fromVSie_LC38IE_valid & mvien_LC38IE)
        reg_LC38IE <= w_wen & w_wdata[38] | fromVSie_LC38IE_valid & fromVSie_LC38IE_bits;
      if (w_wen & mvien_LC39IE | fromVSie_LC39IE_valid & mvien_LC39IE)
        reg_LC39IE <= w_wen & w_wdata[39] | fromVSie_LC39IE_valid & fromVSie_LC39IE_bits;
      if (w_wen & mvien_LC40IE | fromVSie_LC40IE_valid & mvien_LC40IE)
        reg_LC40IE <= w_wen & w_wdata[40] | fromVSie_LC40IE_valid & fromVSie_LC40IE_bits;
      if (w_wen & mvien_LC41IE | fromVSie_LC41IE_valid & mvien_LC41IE)
        reg_LC41IE <= w_wen & w_wdata[41] | fromVSie_LC41IE_valid & fromVSie_LC41IE_bits;
      if (w_wen & mvien_LC42IE | fromVSie_LC42IE_valid & mvien_LC42IE)
        reg_LC42IE <= w_wen & w_wdata[42] | fromVSie_LC42IE_valid & fromVSie_LC42IE_bits;
      if (w_wen & mvien_HPRASEIE | fromVSie_HPRASEIE_valid & mvien_HPRASEIE)
        reg_HPRASEIE <=
          w_wen & w_wdata[43] | fromVSie_HPRASEIE_valid & fromVSie_HPRASEIE_bits;
      if (w_wen & mvien_LC44IE | fromVSie_LC44IE_valid & mvien_LC44IE)
        reg_LC44IE <= w_wen & w_wdata[44] | fromVSie_LC44IE_valid & fromVSie_LC44IE_bits;
      if (w_wen & mvien_LC45IE | fromVSie_LC45IE_valid & mvien_LC45IE)
        reg_LC45IE <= w_wen & w_wdata[45] | fromVSie_LC45IE_valid & fromVSie_LC45IE_bits;
      if (w_wen & mvien_LC46IE | fromVSie_LC46IE_valid & mvien_LC46IE)
        reg_LC46IE <= w_wen & w_wdata[46] | fromVSie_LC46IE_valid & fromVSie_LC46IE_bits;
      if (w_wen & mvien_LC47IE | fromVSie_LC47IE_valid & mvien_LC47IE)
        reg_LC47IE <= w_wen & w_wdata[47] | fromVSie_LC47IE_valid & fromVSie_LC47IE_bits;
      if (w_wen & mvien_LC48IE | fromVSie_LC48IE_valid & mvien_LC48IE)
        reg_LC48IE <= w_wen & w_wdata[48] | fromVSie_LC48IE_valid & fromVSie_LC48IE_bits;
      if (w_wen & mvien_LC49IE | fromVSie_LC49IE_valid & mvien_LC49IE)
        reg_LC49IE <= w_wen & w_wdata[49] | fromVSie_LC49IE_valid & fromVSie_LC49IE_bits;
      if (w_wen & mvien_LC50IE | fromVSie_LC50IE_valid & mvien_LC50IE)
        reg_LC50IE <= w_wen & w_wdata[50] | fromVSie_LC50IE_valid & fromVSie_LC50IE_bits;
      if (w_wen & mvien_LC51IE | fromVSie_LC51IE_valid & mvien_LC51IE)
        reg_LC51IE <= w_wen & w_wdata[51] | fromVSie_LC51IE_valid & fromVSie_LC51IE_bits;
      if (w_wen & mvien_LC52IE | fromVSie_LC52IE_valid & mvien_LC52IE)
        reg_LC52IE <= w_wen & w_wdata[52] | fromVSie_LC52IE_valid & fromVSie_LC52IE_bits;
      if (w_wen & mvien_LC53IE | fromVSie_LC53IE_valid & mvien_LC53IE)
        reg_LC53IE <= w_wen & w_wdata[53] | fromVSie_LC53IE_valid & fromVSie_LC53IE_bits;
      if (w_wen & mvien_LC54IE | fromVSie_LC54IE_valid & mvien_LC54IE)
        reg_LC54IE <= w_wen & w_wdata[54] | fromVSie_LC54IE_valid & fromVSie_LC54IE_bits;
      if (w_wen & mvien_LC55IE | fromVSie_LC55IE_valid & mvien_LC55IE)
        reg_LC55IE <= w_wen & w_wdata[55] | fromVSie_LC55IE_valid & fromVSie_LC55IE_bits;
      if (w_wen & mvien_LC56IE | fromVSie_LC56IE_valid & mvien_LC56IE)
        reg_LC56IE <= w_wen & w_wdata[56] | fromVSie_LC56IE_valid & fromVSie_LC56IE_bits;
      if (w_wen & mvien_LC57IE | fromVSie_LC57IE_valid & mvien_LC57IE)
        reg_LC57IE <= w_wen & w_wdata[57] | fromVSie_LC57IE_valid & fromVSie_LC57IE_bits;
      if (w_wen & mvien_LC58IE | fromVSie_LC58IE_valid & mvien_LC58IE)
        reg_LC58IE <= w_wen & w_wdata[58] | fromVSie_LC58IE_valid & fromVSie_LC58IE_bits;
      if (w_wen & mvien_LC59IE | fromVSie_LC59IE_valid & mvien_LC59IE)
        reg_LC59IE <= w_wen & w_wdata[59] | fromVSie_LC59IE_valid & fromVSie_LC59IE_bits;
      if (w_wen & mvien_LC60IE | fromVSie_LC60IE_valid & mvien_LC60IE)
        reg_LC60IE <= w_wen & w_wdata[60] | fromVSie_LC60IE_valid & fromVSie_LC60IE_bits;
      if (w_wen & mvien_LC61IE | fromVSie_LC61IE_valid & mvien_LC61IE)
        reg_LC61IE <= w_wen & w_wdata[61] | fromVSie_LC61IE_valid & fromVSie_LC61IE_bits;
      if (w_wen & mvien_LC62IE | fromVSie_LC62IE_valid & mvien_LC62IE)
        reg_LC62IE <= w_wen & w_wdata[62] | fromVSie_LC62IE_valid & fromVSie_LC62IE_bits;
      if (w_wen & mvien_LC63IE | fromVSie_LC63IE_valid & mvien_LC63IE)
        reg_LC63IE <= w_wen & w_wdata[63] | fromVSie_LC63IE_valid & fromVSie_LC63IE_bits;
    end
  end
  assign rdata =
    {aliasVec[62:12], 3'h0, SEIE_masked, 3'h0, STIE_masked, 3'h0, SSIE_masked, 1'h0};
  assign regOut_SSIE = SSIE_masked;
  assign regOut_STIE = STIE_masked;
  assign regOut_SEIE = SEIE_masked;
  assign regOut_LCOFIE = aliasVec[12];
  assign regOut_LC14IE = aliasVec[13];
  assign regOut_LC15IE = aliasVec[14];
  assign regOut_LC16IE = aliasVec[15];
  assign regOut_LC17IE = aliasVec[16];
  assign regOut_LC18IE = aliasVec[17];
  assign regOut_LC19IE = aliasVec[18];
  assign regOut_LC20IE = aliasVec[19];
  assign regOut_LC21IE = aliasVec[20];
  assign regOut_LC22IE = aliasVec[21];
  assign regOut_LC23IE = aliasVec[22];
  assign regOut_LC24IE = aliasVec[23];
  assign regOut_LC25IE = aliasVec[24];
  assign regOut_LC26IE = aliasVec[25];
  assign regOut_LC27IE = aliasVec[26];
  assign regOut_LC28IE = aliasVec[27];
  assign regOut_LC29IE = aliasVec[28];
  assign regOut_LC30IE = aliasVec[29];
  assign regOut_LC31IE = aliasVec[30];
  assign regOut_LC32IE = aliasVec[31];
  assign regOut_LC33IE = aliasVec[32];
  assign regOut_LC34IE = aliasVec[33];
  assign regOut_LPRASEIE = aliasVec[34];
  assign regOut_LC36IE = aliasVec[35];
  assign regOut_LC37IE = aliasVec[36];
  assign regOut_LC38IE = aliasVec[37];
  assign regOut_LC39IE = aliasVec[38];
  assign regOut_LC40IE = aliasVec[39];
  assign regOut_LC41IE = aliasVec[40];
  assign regOut_LC42IE = aliasVec[41];
  assign regOut_HPRASEIE = aliasVec[42];
  assign regOut_LC44IE = aliasVec[43];
  assign regOut_LC45IE = aliasVec[44];
  assign regOut_LC46IE = aliasVec[45];
  assign regOut_LC47IE = aliasVec[46];
  assign regOut_LC48IE = aliasVec[47];
  assign regOut_LC49IE = aliasVec[48];
  assign regOut_LC50IE = aliasVec[49];
  assign regOut_LC51IE = aliasVec[50];
  assign regOut_LC52IE = aliasVec[51];
  assign regOut_LC53IE = aliasVec[52];
  assign regOut_LC54IE = aliasVec[53];
  assign regOut_LC55IE = aliasVec[54];
  assign regOut_LC56IE = aliasVec[55];
  assign regOut_LC57IE = aliasVec[56];
  assign regOut_LC58IE = aliasVec[57];
  assign regOut_LC59IE = aliasVec[58];
  assign regOut_LC60IE = aliasVec[59];
  assign regOut_LC61IE = aliasVec[60];
  assign regOut_LC62IE = aliasVec[61];
  assign regOut_LC63IE = aliasVec[62];
  assign toMie_SSIE_valid = w_wen & mideleg_SSI;
  assign toMie_SSIE_bits = w_wen & mideleg_SSI & w_wdata[1];
  assign toMie_STIE_valid = w_wen & mideleg_STI;
  assign toMie_STIE_bits = w_wen & mideleg_STI & w_wdata[5];
  assign toMie_SEIE_valid = w_wen & mideleg_SEI;
  assign toMie_SEIE_bits = w_wen & mideleg_SEI & w_wdata[9];
  assign toMie_LCOFIE_valid = w_wen & mideleg_LCOFI;
  assign toMie_LCOFIE_bits = w_wen & mideleg_LCOFI & w_wdata[13];
endmodule


module SipModule(
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SSIP,
  output        regOut_STIP,
  output        regOut_SEIP,
  output        regOut_LCOFIP,
  output        regOut_LC14IP,
  output        regOut_LC15IP,
  output        regOut_LC16IP,
  output        regOut_LC17IP,
  output        regOut_LC18IP,
  output        regOut_LC19IP,
  output        regOut_LC20IP,
  output        regOut_LC21IP,
  output        regOut_LC22IP,
  output        regOut_LC23IP,
  output        regOut_LC24IP,
  output        regOut_LC25IP,
  output        regOut_LC26IP,
  output        regOut_LC27IP,
  output        regOut_LC28IP,
  output        regOut_LC29IP,
  output        regOut_LC30IP,
  output        regOut_LC31IP,
  output        regOut_LC32IP,
  output        regOut_LC33IP,
  output        regOut_LC34IP,
  output        regOut_LPRASEIP,
  output        regOut_LC36IP,
  output        regOut_LC37IP,
  output        regOut_LC38IP,
  output        regOut_LC39IP,
  output        regOut_LC40IP,
  output        regOut_LC41IP,
  output        regOut_LC42IP,
  output        regOut_HPRASEIP,
  output        regOut_LC44IP,
  output        regOut_LC45IP,
  output        regOut_LC46IP,
  output        regOut_LC47IP,
  output        regOut_LC48IP,
  output        regOut_LC49IP,
  output        regOut_LC50IP,
  output        regOut_LC51IP,
  output        regOut_LC52IP,
  output        regOut_LC53IP,
  output        regOut_LC54IP,
  output        regOut_LC55IP,
  output        regOut_LC56IP,
  output        regOut_LC57IP,
  output        regOut_LC58IP,
  output        regOut_LC59IP,
  output        regOut_LC60IP,
  output        regOut_LC61IP,
  output        regOut_LC62IP,
  output        regOut_LC63IP,
  input         mideleg_SSI,
  input         mideleg_STI,
  input         mideleg_SEI,
  input         mideleg_LCOFI,
  input         mip_SSIP,
  input         mip_VSSIP,
  input         mip_MSIP,
  input         mip_STIP,
  input         mip_VSTIP,
  input         mip_MTIP,
  input         mip_SEIP,
  input         mip_VSEIP,
  input         mip_MEIP,
  input         mip_SGEIP,
  input         mip_LCOFIP,
  input         mip_LC14IP,
  input         mip_LC15IP,
  input         mip_LC16IP,
  input         mip_LC17IP,
  input         mip_LC18IP,
  input         mip_LC19IP,
  input         mip_LC20IP,
  input         mip_LC21IP,
  input         mip_LC22IP,
  input         mip_LC23IP,
  input         mip_LC24IP,
  input         mip_LC25IP,
  input         mip_LC26IP,
  input         mip_LC27IP,
  input         mip_LC28IP,
  input         mip_LC29IP,
  input         mip_LC30IP,
  input         mip_LC31IP,
  input         mip_LC32IP,
  input         mip_LC33IP,
  input         mip_LC34IP,
  input         mip_LPRASEIP,
  input         mip_LC36IP,
  input         mip_LC37IP,
  input         mip_LC38IP,
  input         mip_LC39IP,
  input         mip_LC40IP,
  input         mip_LC41IP,
  input         mip_LC42IP,
  input         mip_HPRASEIP,
  input         mip_LC44IP,
  input         mip_LC45IP,
  input         mip_LC46IP,
  input         mip_LC47IP,
  input         mip_LC48IP,
  input         mip_LC49IP,
  input         mip_LC50IP,
  input         mip_LC51IP,
  input         mip_LC52IP,
  input         mip_LC53IP,
  input         mip_LC54IP,
  input         mip_LC55IP,
  input         mip_LC56IP,
  input         mip_LC57IP,
  input         mip_LC58IP,
  input         mip_LC59IP,
  input         mip_LC60IP,
  input         mip_LC61IP,
  input         mip_LC62IP,
  input         mip_LC63IP,
  input         mvip_SSIP,
  input         mvip_STIP,
  input         mvip_SEIP,
  input         mvip_LCOFIP,
  input         mvip_LC14IP,
  input         mvip_LC15IP,
  input         mvip_LC16IP,
  input         mvip_LC17IP,
  input         mvip_LC18IP,
  input         mvip_LC19IP,
  input         mvip_LC20IP,
  input         mvip_LC21IP,
  input         mvip_LC22IP,
  input         mvip_LC23IP,
  input         mvip_LC24IP,
  input         mvip_LC25IP,
  input         mvip_LC26IP,
  input         mvip_LC27IP,
  input         mvip_LC28IP,
  input         mvip_LC29IP,
  input         mvip_LC30IP,
  input         mvip_LC31IP,
  input         mvip_LC32IP,
  input         mvip_LC33IP,
  input         mvip_LC34IP,
  input         mvip_LPRASEIP,
  input         mvip_LC36IP,
  input         mvip_LC37IP,
  input         mvip_LC38IP,
  input         mvip_LC39IP,
  input         mvip_LC40IP,
  input         mvip_LC41IP,
  input         mvip_LC42IP,
  input         mvip_HPRASEIP,
  input         mvip_LC44IP,
  input         mvip_LC45IP,
  input         mvip_LC46IP,
  input         mvip_LC47IP,
  input         mvip_LC48IP,
  input         mvip_LC49IP,
  input         mvip_LC50IP,
  input         mvip_LC51IP,
  input         mvip_LC52IP,
  input         mvip_LC53IP,
  input         mvip_LC54IP,
  input         mvip_LC55IP,
  input         mvip_LC56IP,
  input         mvip_LC57IP,
  input         mvip_LC58IP,
  input         mvip_LC59IP,
  input         mvip_LC60IP,
  input         mvip_LC61IP,
  input         mvip_LC62IP,
  input         mvip_LC63IP,
  input         mvien_SSIE,
  input         mvien_SEIE,
  input         mvien_LC14IE,
  input         mvien_LC15IE,
  input         mvien_LC16IE,
  input         mvien_LC17IE,
  input         mvien_LC18IE,
  input         mvien_LC19IE,
  input         mvien_LC20IE,
  input         mvien_LC21IE,
  input         mvien_LC22IE,
  input         mvien_LC23IE,
  input         mvien_LC24IE,
  input         mvien_LC25IE,
  input         mvien_LC26IE,
  input         mvien_LC27IE,
  input         mvien_LC28IE,
  input         mvien_LC29IE,
  input         mvien_LC30IE,
  input         mvien_LC31IE,
  input         mvien_LC32IE,
  input         mvien_LC33IE,
  input         mvien_LC34IE,
  input         mvien_LPRASEIE,
  input         mvien_LC36IE,
  input         mvien_LC37IE,
  input         mvien_LC38IE,
  input         mvien_LC39IE,
  input         mvien_LC40IE,
  input         mvien_LC41IE,
  input         mvien_LC42IE,
  input         mvien_HPRASEIE,
  input         mvien_LC44IE,
  input         mvien_LC45IE,
  input         mvien_LC46IE,
  input         mvien_LC47IE,
  input         mvien_LC48IE,
  input         mvien_LC49IE,
  input         mvien_LC50IE,
  input         mvien_LC51IE,
  input         mvien_LC52IE,
  input         mvien_LC53IE,
  input         mvien_LC54IE,
  input         mvien_LC55IE,
  input         mvien_LC56IE,
  input         mvien_LC57IE,
  input         mvien_LC58IE,
  input         mvien_LC59IE,
  input         mvien_LC60IE,
  input         mvien_LC61IE,
  input         mvien_LC62IE,
  input         mvien_LC63IE,
  output        toMip_SSIP_valid,
  output        toMip_SSIP_bits,
  output        toMip_LCOFIP_valid,
  output        toMip_LCOFIP_bits,
  output        toMvip_SSIP_valid,
  output        toMvip_SSIP_bits,
  output        toMvip_LCOFIP_valid,
  output        toMvip_LCOFIP_bits,
  output        toMvip_LC14IP_valid,
  output        toMvip_LC14IP_bits,
  output        toMvip_LC15IP_valid,
  output        toMvip_LC15IP_bits,
  output        toMvip_LC16IP_valid,
  output        toMvip_LC16IP_bits,
  output        toMvip_LC17IP_valid,
  output        toMvip_LC17IP_bits,
  output        toMvip_LC18IP_valid,
  output        toMvip_LC18IP_bits,
  output        toMvip_LC19IP_valid,
  output        toMvip_LC19IP_bits,
  output        toMvip_LC20IP_valid,
  output        toMvip_LC20IP_bits,
  output        toMvip_LC21IP_valid,
  output        toMvip_LC21IP_bits,
  output        toMvip_LC22IP_valid,
  output        toMvip_LC22IP_bits,
  output        toMvip_LC23IP_valid,
  output        toMvip_LC23IP_bits,
  output        toMvip_LC24IP_valid,
  output        toMvip_LC24IP_bits,
  output        toMvip_LC25IP_valid,
  output        toMvip_LC25IP_bits,
  output        toMvip_LC26IP_valid,
  output        toMvip_LC26IP_bits,
  output        toMvip_LC27IP_valid,
  output        toMvip_LC27IP_bits,
  output        toMvip_LC28IP_valid,
  output        toMvip_LC28IP_bits,
  output        toMvip_LC29IP_valid,
  output        toMvip_LC29IP_bits,
  output        toMvip_LC30IP_valid,
  output        toMvip_LC30IP_bits,
  output        toMvip_LC31IP_valid,
  output        toMvip_LC31IP_bits,
  output        toMvip_LC32IP_valid,
  output        toMvip_LC32IP_bits,
  output        toMvip_LC33IP_valid,
  output        toMvip_LC33IP_bits,
  output        toMvip_LC34IP_valid,
  output        toMvip_LC34IP_bits,
  output        toMvip_LPRASEIP_valid,
  output        toMvip_LPRASEIP_bits,
  output        toMvip_LC36IP_valid,
  output        toMvip_LC36IP_bits,
  output        toMvip_LC37IP_valid,
  output        toMvip_LC37IP_bits,
  output        toMvip_LC38IP_valid,
  output        toMvip_LC38IP_bits,
  output        toMvip_LC39IP_valid,
  output        toMvip_LC39IP_bits,
  output        toMvip_LC40IP_valid,
  output        toMvip_LC40IP_bits,
  output        toMvip_LC41IP_valid,
  output        toMvip_LC41IP_bits,
  output        toMvip_LC42IP_valid,
  output        toMvip_LC42IP_bits,
  output        toMvip_HPRASEIP_valid,
  output        toMvip_HPRASEIP_bits,
  output        toMvip_LC44IP_valid,
  output        toMvip_LC44IP_bits,
  output        toMvip_LC45IP_valid,
  output        toMvip_LC45IP_bits,
  output        toMvip_LC46IP_valid,
  output        toMvip_LC46IP_bits,
  output        toMvip_LC47IP_valid,
  output        toMvip_LC47IP_bits,
  output        toMvip_LC48IP_valid,
  output        toMvip_LC48IP_bits,
  output        toMvip_LC49IP_valid,
  output        toMvip_LC49IP_bits,
  output        toMvip_LC50IP_valid,
  output        toMvip_LC50IP_bits,
  output        toMvip_LC51IP_valid,
  output        toMvip_LC51IP_bits,
  output        toMvip_LC52IP_valid,
  output        toMvip_LC52IP_bits,
  output        toMvip_LC53IP_valid,
  output        toMvip_LC53IP_bits,
  output        toMvip_LC54IP_valid,
  output        toMvip_LC54IP_bits,
  output        toMvip_LC55IP_valid,
  output        toMvip_LC55IP_bits,
  output        toMvip_LC56IP_valid,
  output        toMvip_LC56IP_bits,
  output        toMvip_LC57IP_valid,
  output        toMvip_LC57IP_bits,
  output        toMvip_LC58IP_valid,
  output        toMvip_LC58IP_bits,
  output        toMvip_LC59IP_valid,
  output        toMvip_LC59IP_bits,
  output        toMvip_LC60IP_valid,
  output        toMvip_LC60IP_bits,
  output        toMvip_LC61IP_valid,
  output        toMvip_LC61IP_bits,
  output        toMvip_LC62IP_valid,
  output        toMvip_LC62IP_bits,
  output        toMvip_LC63IP_valid,
  output        toMvip_LC63IP_bits
);

  wire        SSIP_masked;
  wire        STIP_masked;
  wire        SEIP_masked;
  wire [62:0] aliasVec;
  wire [63:0] mvipIsAlias =
    {50'h3FFFFFFFFFFFF,
     ~mideleg_LCOFI,
     3'h2,
     ~mideleg_SEI,
     3'h6,
     ~mideleg_STI,
     3'h6,
     ~mideleg_SSI,
     1'h1}
    & {mvien_LC63IE,
       mvien_LC62IE,
       mvien_LC61IE,
       mvien_LC60IE,
       mvien_LC59IE,
       mvien_LC58IE,
       mvien_LC57IE,
       mvien_LC56IE,
       mvien_LC55IE,
       mvien_LC54IE,
       mvien_LC53IE,
       mvien_LC52IE,
       mvien_LC51IE,
       mvien_LC50IE,
       mvien_LC49IE,
       mvien_LC48IE,
       mvien_LC47IE,
       mvien_LC46IE,
       mvien_LC45IE,
       mvien_LC44IE,
       mvien_HPRASEIE,
       mvien_LC42IE,
       mvien_LC41IE,
       mvien_LC40IE,
       mvien_LC39IE,
       mvien_LC38IE,
       mvien_LC37IE,
       mvien_LC36IE,
       mvien_LPRASEIE,
       mvien_LC34IE,
       mvien_LC33IE,
       mvien_LC32IE,
       mvien_LC31IE,
       mvien_LC30IE,
       mvien_LC29IE,
       mvien_LC28IE,
       mvien_LC27IE,
       mvien_LC26IE,
       mvien_LC25IE,
       mvien_LC24IE,
       mvien_LC23IE,
       mvien_LC22IE,
       mvien_LC21IE,
       mvien_LC20IE,
       mvien_LC19IE,
       mvien_LC18IE,
       mvien_LC17IE,
       mvien_LC16IE,
       mvien_LC15IE,
       mvien_LC14IE,
       4'h0,
       mvien_SEIE,
       7'h0,
       mvien_SSIE,
       1'h0};
  assign aliasVec =
    {50'h0, mideleg_LCOFI, 3'h5, mideleg_SEI, 3'h1, mideleg_STI, 3'h1, mideleg_SSI}
    & {mip_LC63IP,
       mip_LC62IP,
       mip_LC61IP,
       mip_LC60IP,
       mip_LC59IP,
       mip_LC58IP,
       mip_LC57IP,
       mip_LC56IP,
       mip_LC55IP,
       mip_LC54IP,
       mip_LC53IP,
       mip_LC52IP,
       mip_LC51IP,
       mip_LC50IP,
       mip_LC49IP,
       mip_LC48IP,
       mip_LC47IP,
       mip_LC46IP,
       mip_LC45IP,
       mip_LC44IP,
       mip_HPRASEIP,
       mip_LC42IP,
       mip_LC41IP,
       mip_LC40IP,
       mip_LC39IP,
       mip_LC38IP,
       mip_LC37IP,
       mip_LC36IP,
       mip_LPRASEIP,
       mip_LC34IP,
       mip_LC33IP,
       mip_LC32IP,
       mip_LC31IP,
       mip_LC30IP,
       mip_LC29IP,
       mip_LC28IP,
       mip_LC27IP,
       mip_LC26IP,
       mip_LC25IP,
       mip_LC24IP,
       mip_LC23IP,
       mip_LC22IP,
       mip_LC21IP,
       mip_LC20IP,
       mip_LC19IP,
       mip_LC18IP,
       mip_LC17IP,
       mip_LC16IP,
       mip_LC15IP,
       mip_LC14IP,
       mip_LCOFIP,
       mip_SGEIP,
       mip_MEIP,
       mip_VSEIP,
       mip_SEIP,
       1'h0,
       mip_MTIP,
       mip_VSTIP,
       mip_STIP,
       1'h0,
       mip_MSIP,
       mip_VSSIP,
       mip_SSIP} | mvipIsAlias[63:1]
    & {mvip_LC63IP,
       mvip_LC62IP,
       mvip_LC61IP,
       mvip_LC60IP,
       mvip_LC59IP,
       mvip_LC58IP,
       mvip_LC57IP,
       mvip_LC56IP,
       mvip_LC55IP,
       mvip_LC54IP,
       mvip_LC53IP,
       mvip_LC52IP,
       mvip_LC51IP,
       mvip_LC50IP,
       mvip_LC49IP,
       mvip_LC48IP,
       mvip_LC47IP,
       mvip_LC46IP,
       mvip_LC45IP,
       mvip_LC44IP,
       mvip_HPRASEIP,
       mvip_LC42IP,
       mvip_LC41IP,
       mvip_LC40IP,
       mvip_LC39IP,
       mvip_LC38IP,
       mvip_LC37IP,
       mvip_LC36IP,
       mvip_LPRASEIP,
       mvip_LC34IP,
       mvip_LC33IP,
       mvip_LC32IP,
       mvip_LC31IP,
       mvip_LC30IP,
       mvip_LC29IP,
       mvip_LC28IP,
       mvip_LC27IP,
       mvip_LC26IP,
       mvip_LC25IP,
       mvip_LC24IP,
       mvip_LC23IP,
       mvip_LC22IP,
       mvip_LC21IP,
       mvip_LC20IP,
       mvip_LC19IP,
       mvip_LC18IP,
       mvip_LC17IP,
       mvip_LC16IP,
       mvip_LC15IP,
       mvip_LC14IP,
       mvip_LCOFIP,
       3'h0,
       mvip_SEIP,
       3'h0,
       mvip_STIP,
       3'h0,
       mvip_SSIP};
  assign SEIP_masked = aliasVec[8];
  assign STIP_masked = aliasVec[4];
  assign SSIP_masked = aliasVec[0];
  assign rdata =
    {aliasVec[62:12], 3'h0, SEIP_masked, 3'h0, STIP_masked, 3'h0, SSIP_masked, 1'h0};
  assign regOut_SSIP = SSIP_masked;
  assign regOut_STIP = STIP_masked;
  assign regOut_SEIP = SEIP_masked;
  assign regOut_LCOFIP = aliasVec[12];
  assign regOut_LC14IP = aliasVec[13];
  assign regOut_LC15IP = aliasVec[14];
  assign regOut_LC16IP = aliasVec[15];
  assign regOut_LC17IP = aliasVec[16];
  assign regOut_LC18IP = aliasVec[17];
  assign regOut_LC19IP = aliasVec[18];
  assign regOut_LC20IP = aliasVec[19];
  assign regOut_LC21IP = aliasVec[20];
  assign regOut_LC22IP = aliasVec[21];
  assign regOut_LC23IP = aliasVec[22];
  assign regOut_LC24IP = aliasVec[23];
  assign regOut_LC25IP = aliasVec[24];
  assign regOut_LC26IP = aliasVec[25];
  assign regOut_LC27IP = aliasVec[26];
  assign regOut_LC28IP = aliasVec[27];
  assign regOut_LC29IP = aliasVec[28];
  assign regOut_LC30IP = aliasVec[29];
  assign regOut_LC31IP = aliasVec[30];
  assign regOut_LC32IP = aliasVec[31];
  assign regOut_LC33IP = aliasVec[32];
  assign regOut_LC34IP = aliasVec[33];
  assign regOut_LPRASEIP = aliasVec[34];
  assign regOut_LC36IP = aliasVec[35];
  assign regOut_LC37IP = aliasVec[36];
  assign regOut_LC38IP = aliasVec[37];
  assign regOut_LC39IP = aliasVec[38];
  assign regOut_LC40IP = aliasVec[39];
  assign regOut_LC41IP = aliasVec[40];
  assign regOut_LC42IP = aliasVec[41];
  assign regOut_HPRASEIP = aliasVec[42];
  assign regOut_LC44IP = aliasVec[43];
  assign regOut_LC45IP = aliasVec[44];
  assign regOut_LC46IP = aliasVec[45];
  assign regOut_LC47IP = aliasVec[46];
  assign regOut_LC48IP = aliasVec[47];
  assign regOut_LC49IP = aliasVec[48];
  assign regOut_LC50IP = aliasVec[49];
  assign regOut_LC51IP = aliasVec[50];
  assign regOut_LC52IP = aliasVec[51];
  assign regOut_LC53IP = aliasVec[52];
  assign regOut_LC54IP = aliasVec[53];
  assign regOut_LC55IP = aliasVec[54];
  assign regOut_LC56IP = aliasVec[55];
  assign regOut_LC57IP = aliasVec[56];
  assign regOut_LC58IP = aliasVec[57];
  assign regOut_LC59IP = aliasVec[58];
  assign regOut_LC60IP = aliasVec[59];
  assign regOut_LC61IP = aliasVec[60];
  assign regOut_LC62IP = aliasVec[61];
  assign regOut_LC63IP = aliasVec[62];
  assign toMip_SSIP_valid = w_wen & mideleg_SSI;
  assign toMip_SSIP_bits = w_wen & mideleg_SSI & w_wdata[1];
  assign toMip_LCOFIP_valid = w_wen & mideleg_LCOFI;
  assign toMip_LCOFIP_bits = w_wen & mideleg_LCOFI & w_wdata[13];
  assign toMvip_SSIP_valid = w_wen & mvipIsAlias[1];
  assign toMvip_SSIP_bits = w_wen & mvipIsAlias[1] & w_wdata[1];
  assign toMvip_LCOFIP_valid = w_wen & mvipIsAlias[13];
  assign toMvip_LCOFIP_bits = w_wen & mvipIsAlias[13] & w_wdata[13];
  assign toMvip_LC14IP_valid = w_wen & mvipIsAlias[14];
  assign toMvip_LC14IP_bits = w_wen & mvipIsAlias[14] & w_wdata[14];
  assign toMvip_LC15IP_valid = w_wen & mvipIsAlias[15];
  assign toMvip_LC15IP_bits = w_wen & mvipIsAlias[15] & w_wdata[15];
  assign toMvip_LC16IP_valid = w_wen & mvipIsAlias[16];
  assign toMvip_LC16IP_bits = w_wen & mvipIsAlias[16] & w_wdata[16];
  assign toMvip_LC17IP_valid = w_wen & mvipIsAlias[17];
  assign toMvip_LC17IP_bits = w_wen & mvipIsAlias[17] & w_wdata[17];
  assign toMvip_LC18IP_valid = w_wen & mvipIsAlias[18];
  assign toMvip_LC18IP_bits = w_wen & mvipIsAlias[18] & w_wdata[18];
  assign toMvip_LC19IP_valid = w_wen & mvipIsAlias[19];
  assign toMvip_LC19IP_bits = w_wen & mvipIsAlias[19] & w_wdata[19];
  assign toMvip_LC20IP_valid = w_wen & mvipIsAlias[20];
  assign toMvip_LC20IP_bits = w_wen & mvipIsAlias[20] & w_wdata[20];
  assign toMvip_LC21IP_valid = w_wen & mvipIsAlias[21];
  assign toMvip_LC21IP_bits = w_wen & mvipIsAlias[21] & w_wdata[21];
  assign toMvip_LC22IP_valid = w_wen & mvipIsAlias[22];
  assign toMvip_LC22IP_bits = w_wen & mvipIsAlias[22] & w_wdata[22];
  assign toMvip_LC23IP_valid = w_wen & mvipIsAlias[23];
  assign toMvip_LC23IP_bits = w_wen & mvipIsAlias[23] & w_wdata[23];
  assign toMvip_LC24IP_valid = w_wen & mvipIsAlias[24];
  assign toMvip_LC24IP_bits = w_wen & mvipIsAlias[24] & w_wdata[24];
  assign toMvip_LC25IP_valid = w_wen & mvipIsAlias[25];
  assign toMvip_LC25IP_bits = w_wen & mvipIsAlias[25] & w_wdata[25];
  assign toMvip_LC26IP_valid = w_wen & mvipIsAlias[26];
  assign toMvip_LC26IP_bits = w_wen & mvipIsAlias[26] & w_wdata[26];
  assign toMvip_LC27IP_valid = w_wen & mvipIsAlias[27];
  assign toMvip_LC27IP_bits = w_wen & mvipIsAlias[27] & w_wdata[27];
  assign toMvip_LC28IP_valid = w_wen & mvipIsAlias[28];
  assign toMvip_LC28IP_bits = w_wen & mvipIsAlias[28] & w_wdata[28];
  assign toMvip_LC29IP_valid = w_wen & mvipIsAlias[29];
  assign toMvip_LC29IP_bits = w_wen & mvipIsAlias[29] & w_wdata[29];
  assign toMvip_LC30IP_valid = w_wen & mvipIsAlias[30];
  assign toMvip_LC30IP_bits = w_wen & mvipIsAlias[30] & w_wdata[30];
  assign toMvip_LC31IP_valid = w_wen & mvipIsAlias[31];
  assign toMvip_LC31IP_bits = w_wen & mvipIsAlias[31] & w_wdata[31];
  assign toMvip_LC32IP_valid = w_wen & mvipIsAlias[32];
  assign toMvip_LC32IP_bits = w_wen & mvipIsAlias[32] & w_wdata[32];
  assign toMvip_LC33IP_valid = w_wen & mvipIsAlias[33];
  assign toMvip_LC33IP_bits = w_wen & mvipIsAlias[33] & w_wdata[33];
  assign toMvip_LC34IP_valid = w_wen & mvipIsAlias[34];
  assign toMvip_LC34IP_bits = w_wen & mvipIsAlias[34] & w_wdata[34];
  assign toMvip_LPRASEIP_valid = w_wen & mvipIsAlias[35];
  assign toMvip_LPRASEIP_bits = w_wen & mvipIsAlias[35] & w_wdata[35];
  assign toMvip_LC36IP_valid = w_wen & mvipIsAlias[36];
  assign toMvip_LC36IP_bits = w_wen & mvipIsAlias[36] & w_wdata[36];
  assign toMvip_LC37IP_valid = w_wen & mvipIsAlias[37];
  assign toMvip_LC37IP_bits = w_wen & mvipIsAlias[37] & w_wdata[37];
  assign toMvip_LC38IP_valid = w_wen & mvipIsAlias[38];
  assign toMvip_LC38IP_bits = w_wen & mvipIsAlias[38] & w_wdata[38];
  assign toMvip_LC39IP_valid = w_wen & mvipIsAlias[39];
  assign toMvip_LC39IP_bits = w_wen & mvipIsAlias[39] & w_wdata[39];
  assign toMvip_LC40IP_valid = w_wen & mvipIsAlias[40];
  assign toMvip_LC40IP_bits = w_wen & mvipIsAlias[40] & w_wdata[40];
  assign toMvip_LC41IP_valid = w_wen & mvipIsAlias[41];
  assign toMvip_LC41IP_bits = w_wen & mvipIsAlias[41] & w_wdata[41];
  assign toMvip_LC42IP_valid = w_wen & mvipIsAlias[42];
  assign toMvip_LC42IP_bits = w_wen & mvipIsAlias[42] & w_wdata[42];
  assign toMvip_HPRASEIP_valid = w_wen & mvipIsAlias[43];
  assign toMvip_HPRASEIP_bits = w_wen & mvipIsAlias[43] & w_wdata[43];
  assign toMvip_LC44IP_valid = w_wen & mvipIsAlias[44];
  assign toMvip_LC44IP_bits = w_wen & mvipIsAlias[44] & w_wdata[44];
  assign toMvip_LC45IP_valid = w_wen & mvipIsAlias[45];
  assign toMvip_LC45IP_bits = w_wen & mvipIsAlias[45] & w_wdata[45];
  assign toMvip_LC46IP_valid = w_wen & mvipIsAlias[46];
  assign toMvip_LC46IP_bits = w_wen & mvipIsAlias[46] & w_wdata[46];
  assign toMvip_LC47IP_valid = w_wen & mvipIsAlias[47];
  assign toMvip_LC47IP_bits = w_wen & mvipIsAlias[47] & w_wdata[47];
  assign toMvip_LC48IP_valid = w_wen & mvipIsAlias[48];
  assign toMvip_LC48IP_bits = w_wen & mvipIsAlias[48] & w_wdata[48];
  assign toMvip_LC49IP_valid = w_wen & mvipIsAlias[49];
  assign toMvip_LC49IP_bits = w_wen & mvipIsAlias[49] & w_wdata[49];
  assign toMvip_LC50IP_valid = w_wen & mvipIsAlias[50];
  assign toMvip_LC50IP_bits = w_wen & mvipIsAlias[50] & w_wdata[50];
  assign toMvip_LC51IP_valid = w_wen & mvipIsAlias[51];
  assign toMvip_LC51IP_bits = w_wen & mvipIsAlias[51] & w_wdata[51];
  assign toMvip_LC52IP_valid = w_wen & mvipIsAlias[52];
  assign toMvip_LC52IP_bits = w_wen & mvipIsAlias[52] & w_wdata[52];
  assign toMvip_LC53IP_valid = w_wen & mvipIsAlias[53];
  assign toMvip_LC53IP_bits = w_wen & mvipIsAlias[53] & w_wdata[53];
  assign toMvip_LC54IP_valid = w_wen & mvipIsAlias[54];
  assign toMvip_LC54IP_bits = w_wen & mvipIsAlias[54] & w_wdata[54];
  assign toMvip_LC55IP_valid = w_wen & mvipIsAlias[55];
  assign toMvip_LC55IP_bits = w_wen & mvipIsAlias[55] & w_wdata[55];
  assign toMvip_LC56IP_valid = w_wen & mvipIsAlias[56];
  assign toMvip_LC56IP_bits = w_wen & mvipIsAlias[56] & w_wdata[56];
  assign toMvip_LC57IP_valid = w_wen & mvipIsAlias[57];
  assign toMvip_LC57IP_bits = w_wen & mvipIsAlias[57] & w_wdata[57];
  assign toMvip_LC58IP_valid = w_wen & mvipIsAlias[58];
  assign toMvip_LC58IP_bits = w_wen & mvipIsAlias[58] & w_wdata[58];
  assign toMvip_LC59IP_valid = w_wen & mvipIsAlias[59];
  assign toMvip_LC59IP_bits = w_wen & mvipIsAlias[59] & w_wdata[59];
  assign toMvip_LC60IP_valid = w_wen & mvipIsAlias[60];
  assign toMvip_LC60IP_bits = w_wen & mvipIsAlias[60] & w_wdata[60];
  assign toMvip_LC61IP_valid = w_wen & mvipIsAlias[61];
  assign toMvip_LC61IP_bits = w_wen & mvipIsAlias[61] & w_wdata[61];
  assign toMvip_LC62IP_valid = w_wen & mvipIsAlias[62];
  assign toMvip_LC62IP_bits = w_wen & mvipIsAlias[62] & w_wdata[62];
  assign toMvip_LC63IP_valid = w_wen & mvipIsAlias[63];
  assign toMvip_LC63IP_bits = w_wen & mvipIsAlias[63] & w_wdata[63];
endmodule


module VSieModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SSIE,
  output        regOut_STIE,
  output        regOut_SEIE,
  output        regOut_LCOFIE,
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
  output        regOut_LC63IE,
  input         mideleg_SSI,
  input         mideleg_STI,
  input         mideleg_SEI,
  input         mideleg_LCOFI,
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
  input         mie_LCOFIE,
  input         mvien_SSIE,
  input         mvien_SEIE,
  input         mvien_LC14IE,
  input         mvien_LC15IE,
  input         mvien_LC16IE,
  input         mvien_LC17IE,
  input         mvien_LC18IE,
  input         mvien_LC19IE,
  input         mvien_LC20IE,
  input         mvien_LC21IE,
  input         mvien_LC22IE,
  input         mvien_LC23IE,
  input         mvien_LC24IE,
  input         mvien_LC25IE,
  input         mvien_LC26IE,
  input         mvien_LC27IE,
  input         mvien_LC28IE,
  input         mvien_LC29IE,
  input         mvien_LC30IE,
  input         mvien_LC31IE,
  input         mvien_LC32IE,
  input         mvien_LC33IE,
  input         mvien_LC34IE,
  input         mvien_LPRASEIE,
  input         mvien_LC36IE,
  input         mvien_LC37IE,
  input         mvien_LC38IE,
  input         mvien_LC39IE,
  input         mvien_LC40IE,
  input         mvien_LC41IE,
  input         mvien_LC42IE,
  input         mvien_HPRASEIE,
  input         mvien_LC44IE,
  input         mvien_LC45IE,
  input         mvien_LC46IE,
  input         mvien_LC47IE,
  input         mvien_LC48IE,
  input         mvien_LC49IE,
  input         mvien_LC50IE,
  input         mvien_LC51IE,
  input         mvien_LC52IE,
  input         mvien_LC53IE,
  input         mvien_LC54IE,
  input         mvien_LC55IE,
  input         mvien_LC56IE,
  input         mvien_LC57IE,
  input         mvien_LC58IE,
  input         mvien_LC59IE,
  input         mvien_LC60IE,
  input         mvien_LC61IE,
  input         mvien_LC62IE,
  input         mvien_LC63IE,
  input         hideleg_SSI,
  input         hideleg_VSSI,
  input         hideleg_MSI,
  input         hideleg_STI,
  input         hideleg_VSTI,
  input         hideleg_MTI,
  input         hideleg_SEI,
  input         hideleg_VSEI,
  input         hideleg_MEI,
  input         hideleg_SGEI,
  input         hideleg_LCOFI,
  input         hvien_LC14IE,
  input         hvien_LC15IE,
  input         hvien_LC16IE,
  input         hvien_LC17IE,
  input         hvien_LC18IE,
  input         hvien_LC19IE,
  input         hvien_LC20IE,
  input         hvien_LC21IE,
  input         hvien_LC22IE,
  input         hvien_LC23IE,
  input         hvien_LC24IE,
  input         hvien_LC25IE,
  input         hvien_LC26IE,
  input         hvien_LC27IE,
  input         hvien_LC28IE,
  input         hvien_LC29IE,
  input         hvien_LC30IE,
  input         hvien_LC31IE,
  input         hvien_LC32IE,
  input         hvien_LC33IE,
  input         hvien_LC34IE,
  input         hvien_LPRASEIE,
  input         hvien_LC36IE,
  input         hvien_LC37IE,
  input         hvien_LC38IE,
  input         hvien_LC39IE,
  input         hvien_LC40IE,
  input         hvien_LC41IE,
  input         hvien_LC42IE,
  input         hvien_HPRASEIE,
  input         hvien_LC44IE,
  input         hvien_LC45IE,
  input         hvien_LC46IE,
  input         hvien_LC47IE,
  input         hvien_LC48IE,
  input         hvien_LC49IE,
  input         hvien_LC50IE,
  input         hvien_LC51IE,
  input         hvien_LC52IE,
  input         hvien_LC53IE,
  input         hvien_LC54IE,
  input         hvien_LC55IE,
  input         hvien_LC56IE,
  input         hvien_LC57IE,
  input         hvien_LC58IE,
  input         hvien_LC59IE,
  input         hvien_LC60IE,
  input         hvien_LC61IE,
  input         hvien_LC62IE,
  input         hvien_LC63IE,
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
  input         sie_LC63IE,
  output        toMie_VSSIE_valid,
  output        toMie_VSSIE_bits,
  output        toMie_VSTIE_valid,
  output        toMie_VSTIE_bits,
  output        toMie_VSEIE_valid,
  output        toMie_VSEIE_bits,
  output        toMie_LCOFIE_valid,
  output        toMie_LCOFIE_bits,
  output        toSie_VSSIE_valid,
  output        toSie_VSSIE_bits,
  output        toSie_VSTIE_valid,
  output        toSie_VSTIE_bits,
  output        toSie_VSEIE_valid,
  output        toSie_VSEIE_bits,
  output        toSie_LCOFIE_valid,
  output        toSie_LCOFIE_bits,
  output        toSie_LC14IE_valid,
  output        toSie_LC14IE_bits,
  output        toSie_LC15IE_valid,
  output        toSie_LC15IE_bits,
  output        toSie_LC16IE_valid,
  output        toSie_LC16IE_bits,
  output        toSie_LC17IE_valid,
  output        toSie_LC17IE_bits,
  output        toSie_LC18IE_valid,
  output        toSie_LC18IE_bits,
  output        toSie_LC19IE_valid,
  output        toSie_LC19IE_bits,
  output        toSie_LC20IE_valid,
  output        toSie_LC20IE_bits,
  output        toSie_LC21IE_valid,
  output        toSie_LC21IE_bits,
  output        toSie_LC22IE_valid,
  output        toSie_LC22IE_bits,
  output        toSie_LC23IE_valid,
  output        toSie_LC23IE_bits,
  output        toSie_LC24IE_valid,
  output        toSie_LC24IE_bits,
  output        toSie_LC25IE_valid,
  output        toSie_LC25IE_bits,
  output        toSie_LC26IE_valid,
  output        toSie_LC26IE_bits,
  output        toSie_LC27IE_valid,
  output        toSie_LC27IE_bits,
  output        toSie_LC28IE_valid,
  output        toSie_LC28IE_bits,
  output        toSie_LC29IE_valid,
  output        toSie_LC29IE_bits,
  output        toSie_LC30IE_valid,
  output        toSie_LC30IE_bits,
  output        toSie_LC31IE_valid,
  output        toSie_LC31IE_bits,
  output        toSie_LC32IE_valid,
  output        toSie_LC32IE_bits,
  output        toSie_LC33IE_valid,
  output        toSie_LC33IE_bits,
  output        toSie_LC34IE_valid,
  output        toSie_LC34IE_bits,
  output        toSie_LPRASEIE_valid,
  output        toSie_LPRASEIE_bits,
  output        toSie_LC36IE_valid,
  output        toSie_LC36IE_bits,
  output        toSie_LC37IE_valid,
  output        toSie_LC37IE_bits,
  output        toSie_LC38IE_valid,
  output        toSie_LC38IE_bits,
  output        toSie_LC39IE_valid,
  output        toSie_LC39IE_bits,
  output        toSie_LC40IE_valid,
  output        toSie_LC40IE_bits,
  output        toSie_LC41IE_valid,
  output        toSie_LC41IE_bits,
  output        toSie_LC42IE_valid,
  output        toSie_LC42IE_bits,
  output        toSie_HPRASEIE_valid,
  output        toSie_HPRASEIE_bits,
  output        toSie_LC44IE_valid,
  output        toSie_LC44IE_bits,
  output        toSie_LC45IE_valid,
  output        toSie_LC45IE_bits,
  output        toSie_LC46IE_valid,
  output        toSie_LC46IE_bits,
  output        toSie_LC47IE_valid,
  output        toSie_LC47IE_bits,
  output        toSie_LC48IE_valid,
  output        toSie_LC48IE_bits,
  output        toSie_LC49IE_valid,
  output        toSie_LC49IE_bits,
  output        toSie_LC50IE_valid,
  output        toSie_LC50IE_bits,
  output        toSie_LC51IE_valid,
  output        toSie_LC51IE_bits,
  output        toSie_LC52IE_valid,
  output        toSie_LC52IE_bits,
  output        toSie_LC53IE_valid,
  output        toSie_LC53IE_bits,
  output        toSie_LC54IE_valid,
  output        toSie_LC54IE_bits,
  output        toSie_LC55IE_valid,
  output        toSie_LC55IE_bits,
  output        toSie_LC56IE_valid,
  output        toSie_LC56IE_bits,
  output        toSie_LC57IE_valid,
  output        toSie_LC57IE_bits,
  output        toSie_LC58IE_valid,
  output        toSie_LC58IE_bits,
  output        toSie_LC59IE_valid,
  output        toSie_LC59IE_bits,
  output        toSie_LC60IE_valid,
  output        toSie_LC60IE_bits,
  output        toSie_LC61IE_valid,
  output        toSie_LC61IE_bits,
  output        toSie_LC62IE_valid,
  output        toSie_LC62IE_bits,
  output        toSie_LC63IE_valid,
  output        toSie_LC63IE_bits
);

  wire        SSIE_masked;
  wire        STIE_masked;
  wire        SEIE_masked;
  wire [62:0] aliasVec;
  reg         reg_LC14IE;
  reg         reg_LC15IE;
  reg         reg_LC16IE;
  reg         reg_LC17IE;
  reg         reg_LC18IE;
  reg         reg_LC19IE;
  reg         reg_LC20IE;
  reg         reg_LC21IE;
  reg         reg_LC22IE;
  reg         reg_LC23IE;
  reg         reg_LC24IE;
  reg         reg_LC25IE;
  reg         reg_LC26IE;
  reg         reg_LC27IE;
  reg         reg_LC28IE;
  reg         reg_LC29IE;
  reg         reg_LC30IE;
  reg         reg_LC31IE;
  reg         reg_LC32IE;
  reg         reg_LC33IE;
  reg         reg_LC34IE;
  reg         reg_LPRASEIE;
  reg         reg_LC36IE;
  reg         reg_LC37IE;
  reg         reg_LC38IE;
  reg         reg_LC39IE;
  reg         reg_LC40IE;
  reg         reg_LC41IE;
  reg         reg_LC42IE;
  reg         reg_HPRASEIE;
  reg         reg_LC44IE;
  reg         reg_LC45IE;
  reg         reg_LC46IE;
  reg         reg_LC47IE;
  reg         reg_LC48IE;
  reg         reg_LC49IE;
  reg         reg_LC50IE;
  reg         reg_LC51IE;
  reg         reg_LC52IE;
  reg         reg_LC53IE;
  reg         reg_LC54IE;
  reg         reg_LC55IE;
  reg         reg_LC56IE;
  reg         reg_LC57IE;
  reg         reg_LC58IE;
  reg         reg_LC59IE;
  reg         reg_LC60IE;
  reg         reg_LC61IE;
  reg         reg_LC62IE;
  reg         reg_LC63IE;
  wire [61:0] aliasVec2 =
    {50'h0,
     hideleg_LCOFI,
     hideleg_SGEI,
     hideleg_MEI,
     hideleg_VSEI,
     hideleg_SEI,
     1'h0,
     hideleg_MTI,
     hideleg_VSTI,
     hideleg_STI,
     1'h0,
     hideleg_MSI,
     hideleg_VSSI};
  wire [61:0] originAliasIE =
    aliasVec2 & {50'h0, mideleg_LCOFI, 3'h5, mideleg_SEI, 3'h1, mideleg_STI, 3'h1}
    & {50'h0,
       mie_LCOFIE,
       mie_SGEIE,
       mie_MEIE,
       mie_VSEIE,
       mie_SEIE,
       1'h0,
       mie_MTIE,
       mie_VSTIE,
       mie_STIE,
       1'h0,
       mie_MSIE,
       mie_VSSIE} | aliasVec2
    & {50'h3FFFFFFFFFFFF, ~mideleg_LCOFI, 3'h2, ~mideleg_SEI, 3'h6, ~mideleg_STI, 3'h6}
    & {mvien_LC63IE,
       mvien_LC62IE,
       mvien_LC61IE,
       mvien_LC60IE,
       mvien_LC59IE,
       mvien_LC58IE,
       mvien_LC57IE,
       mvien_LC56IE,
       mvien_LC55IE,
       mvien_LC54IE,
       mvien_LC53IE,
       mvien_LC52IE,
       mvien_LC51IE,
       mvien_LC50IE,
       mvien_LC49IE,
       mvien_LC48IE,
       mvien_LC47IE,
       mvien_LC46IE,
       mvien_LC45IE,
       mvien_LC44IE,
       mvien_HPRASEIE,
       mvien_LC42IE,
       mvien_LC41IE,
       mvien_LC40IE,
       mvien_LC39IE,
       mvien_LC38IE,
       mvien_LC37IE,
       mvien_LC36IE,
       mvien_LPRASEIE,
       mvien_LC34IE,
       mvien_LC33IE,
       mvien_LC32IE,
       mvien_LC31IE,
       mvien_LC30IE,
       mvien_LC29IE,
       mvien_LC28IE,
       mvien_LC27IE,
       mvien_LC26IE,
       mvien_LC25IE,
       mvien_LC24IE,
       mvien_LC23IE,
       mvien_LC22IE,
       mvien_LC21IE,
       mvien_LC20IE,
       mvien_LC19IE,
       mvien_LC18IE,
       mvien_LC17IE,
       mvien_LC16IE,
       mvien_LC15IE,
       mvien_LC14IE,
       4'h0,
       mvien_SEIE,
       7'h0}
    & {sie_LC63IE,
       sie_LC62IE,
       sie_LC61IE,
       sie_LC60IE,
       sie_LC59IE,
       sie_LC58IE,
       sie_LC57IE,
       sie_LC56IE,
       sie_LC55IE,
       sie_LC54IE,
       sie_LC53IE,
       sie_LC52IE,
       sie_LC51IE,
       sie_LC50IE,
       sie_LC49IE,
       sie_LC48IE,
       sie_LC47IE,
       sie_LC46IE,
       sie_LC45IE,
       sie_LC44IE,
       sie_HPRASEIE,
       sie_LC42IE,
       sie_LC41IE,
       sie_LC40IE,
       sie_LC39IE,
       sie_LC38IE,
       sie_LC37IE,
       sie_LC36IE,
       sie_LPRASEIE,
       sie_LC34IE,
       sie_LC33IE,
       sie_LC32IE,
       sie_LC31IE,
       sie_LC30IE,
       sie_LC29IE,
       sie_LC28IE,
       sie_LC27IE,
       sie_LC26IE,
       sie_LC25IE,
       sie_LC24IE,
       sie_LC23IE,
       sie_LC22IE,
       sie_LC21IE,
       sie_LC20IE,
       sie_LC19IE,
       sie_LC18IE,
       sie_LC17IE,
       sie_LC16IE,
       sie_LC15IE,
       sie_LC14IE,
       sie_LCOFIE,
       3'h0,
       sie_SEIE,
       3'h0,
       sie_STIE,
       3'h0};
  assign aliasVec =
    {originAliasIE[61:11], 1'h0, originAliasIE[10:0]}
    | {{50'h3FFFFFFFFFFFF, ~hideleg_LCOFI}
         & {hvien_LC63IE,
            hvien_LC62IE,
            hvien_LC61IE,
            hvien_LC60IE,
            hvien_LC59IE,
            hvien_LC58IE,
            hvien_LC57IE,
            hvien_LC56IE,
            hvien_LC55IE,
            hvien_LC54IE,
            hvien_LC53IE,
            hvien_LC52IE,
            hvien_LC51IE,
            hvien_LC50IE,
            hvien_LC49IE,
            hvien_LC48IE,
            hvien_LC47IE,
            hvien_LC46IE,
            hvien_LC45IE,
            hvien_LC44IE,
            hvien_HPRASEIE,
            hvien_LC42IE,
            hvien_LC41IE,
            hvien_LC40IE,
            hvien_LC39IE,
            hvien_LC38IE,
            hvien_LC37IE,
            hvien_LC36IE,
            hvien_LPRASEIE,
            hvien_LC34IE,
            hvien_LC33IE,
            hvien_LC32IE,
            hvien_LC31IE,
            hvien_LC30IE,
            hvien_LC29IE,
            hvien_LC28IE,
            hvien_LC27IE,
            hvien_LC26IE,
            hvien_LC25IE,
            hvien_LC24IE,
            hvien_LC23IE,
            hvien_LC22IE,
            hvien_LC21IE,
            hvien_LC20IE,
            hvien_LC19IE,
            hvien_LC18IE,
            hvien_LC17IE,
            hvien_LC16IE,
            hvien_LC15IE,
            hvien_LC14IE,
            1'h0},
       12'h0}
    & {reg_LC63IE,
       reg_LC62IE,
       reg_LC61IE,
       reg_LC60IE,
       reg_LC59IE,
       reg_LC58IE,
       reg_LC57IE,
       reg_LC56IE,
       reg_LC55IE,
       reg_LC54IE,
       reg_LC53IE,
       reg_LC52IE,
       reg_LC51IE,
       reg_LC50IE,
       reg_LC49IE,
       reg_LC48IE,
       reg_LC47IE,
       reg_LC46IE,
       reg_LC45IE,
       reg_LC44IE,
       reg_HPRASEIE,
       reg_LC42IE,
       reg_LC41IE,
       reg_LC40IE,
       reg_LC39IE,
       reg_LC38IE,
       reg_LC37IE,
       reg_LC36IE,
       reg_LPRASEIE,
       reg_LC34IE,
       reg_LC33IE,
       reg_LC32IE,
       reg_LC31IE,
       reg_LC30IE,
       reg_LC29IE,
       reg_LC28IE,
       reg_LC27IE,
       reg_LC26IE,
       reg_LC25IE,
       reg_LC24IE,
       reg_LC23IE,
       reg_LC22IE,
       reg_LC21IE,
       reg_LC20IE,
       reg_LC19IE,
       reg_LC18IE,
       reg_LC17IE,
       reg_LC16IE,
       reg_LC15IE,
       reg_LC14IE,
       13'h0};
  assign SEIE_masked = aliasVec[8];
  assign STIE_masked = aliasVec[4];
  assign SSIE_masked = aliasVec[0];
  wire        lcofiDelegated = hideleg_LCOFI & mideleg_LCOFI;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_LC14IE <= 1'h0;
      reg_LC15IE <= 1'h0;
      reg_LC16IE <= 1'h0;
      reg_LC17IE <= 1'h0;
      reg_LC18IE <= 1'h0;
      reg_LC19IE <= 1'h0;
      reg_LC20IE <= 1'h0;
      reg_LC21IE <= 1'h0;
      reg_LC22IE <= 1'h0;
      reg_LC23IE <= 1'h0;
      reg_LC24IE <= 1'h0;
      reg_LC25IE <= 1'h0;
      reg_LC26IE <= 1'h0;
      reg_LC27IE <= 1'h0;
      reg_LC28IE <= 1'h0;
      reg_LC29IE <= 1'h0;
      reg_LC30IE <= 1'h0;
      reg_LC31IE <= 1'h0;
      reg_LC32IE <= 1'h0;
      reg_LC33IE <= 1'h0;
      reg_LC34IE <= 1'h0;
      reg_LPRASEIE <= 1'h0;
      reg_LC36IE <= 1'h0;
      reg_LC37IE <= 1'h0;
      reg_LC38IE <= 1'h0;
      reg_LC39IE <= 1'h0;
      reg_LC40IE <= 1'h0;
      reg_LC41IE <= 1'h0;
      reg_LC42IE <= 1'h0;
      reg_HPRASEIE <= 1'h0;
      reg_LC44IE <= 1'h0;
      reg_LC45IE <= 1'h0;
      reg_LC46IE <= 1'h0;
      reg_LC47IE <= 1'h0;
      reg_LC48IE <= 1'h0;
      reg_LC49IE <= 1'h0;
      reg_LC50IE <= 1'h0;
      reg_LC51IE <= 1'h0;
      reg_LC52IE <= 1'h0;
      reg_LC53IE <= 1'h0;
      reg_LC54IE <= 1'h0;
      reg_LC55IE <= 1'h0;
      reg_LC56IE <= 1'h0;
      reg_LC57IE <= 1'h0;
      reg_LC58IE <= 1'h0;
      reg_LC59IE <= 1'h0;
      reg_LC60IE <= 1'h0;
      reg_LC61IE <= 1'h0;
      reg_LC62IE <= 1'h0;
      reg_LC63IE <= 1'h0;
    end
    else begin
      if (w_wen & hvien_LC14IE)
        reg_LC14IE <= w_wdata[14];
      if (w_wen & hvien_LC15IE)
        reg_LC15IE <= w_wdata[15];
      if (w_wen & hvien_LC16IE)
        reg_LC16IE <= w_wdata[16];
      if (w_wen & hvien_LC17IE)
        reg_LC17IE <= w_wdata[17];
      if (w_wen & hvien_LC18IE)
        reg_LC18IE <= w_wdata[18];
      if (w_wen & hvien_LC19IE)
        reg_LC19IE <= w_wdata[19];
      if (w_wen & hvien_LC20IE)
        reg_LC20IE <= w_wdata[20];
      if (w_wen & hvien_LC21IE)
        reg_LC21IE <= w_wdata[21];
      if (w_wen & hvien_LC22IE)
        reg_LC22IE <= w_wdata[22];
      if (w_wen & hvien_LC23IE)
        reg_LC23IE <= w_wdata[23];
      if (w_wen & hvien_LC24IE)
        reg_LC24IE <= w_wdata[24];
      if (w_wen & hvien_LC25IE)
        reg_LC25IE <= w_wdata[25];
      if (w_wen & hvien_LC26IE)
        reg_LC26IE <= w_wdata[26];
      if (w_wen & hvien_LC27IE)
        reg_LC27IE <= w_wdata[27];
      if (w_wen & hvien_LC28IE)
        reg_LC28IE <= w_wdata[28];
      if (w_wen & hvien_LC29IE)
        reg_LC29IE <= w_wdata[29];
      if (w_wen & hvien_LC30IE)
        reg_LC30IE <= w_wdata[30];
      if (w_wen & hvien_LC31IE)
        reg_LC31IE <= w_wdata[31];
      if (w_wen & hvien_LC32IE)
        reg_LC32IE <= w_wdata[32];
      if (w_wen & hvien_LC33IE)
        reg_LC33IE <= w_wdata[33];
      if (w_wen & hvien_LC34IE)
        reg_LC34IE <= w_wdata[34];
      if (w_wen & hvien_LPRASEIE)
        reg_LPRASEIE <= w_wdata[35];
      if (w_wen & hvien_LC36IE)
        reg_LC36IE <= w_wdata[36];
      if (w_wen & hvien_LC37IE)
        reg_LC37IE <= w_wdata[37];
      if (w_wen & hvien_LC38IE)
        reg_LC38IE <= w_wdata[38];
      if (w_wen & hvien_LC39IE)
        reg_LC39IE <= w_wdata[39];
      if (w_wen & hvien_LC40IE)
        reg_LC40IE <= w_wdata[40];
      if (w_wen & hvien_LC41IE)
        reg_LC41IE <= w_wdata[41];
      if (w_wen & hvien_LC42IE)
        reg_LC42IE <= w_wdata[42];
      if (w_wen & hvien_HPRASEIE)
        reg_HPRASEIE <= w_wdata[43];
      if (w_wen & hvien_LC44IE)
        reg_LC44IE <= w_wdata[44];
      if (w_wen & hvien_LC45IE)
        reg_LC45IE <= w_wdata[45];
      if (w_wen & hvien_LC46IE)
        reg_LC46IE <= w_wdata[46];
      if (w_wen & hvien_LC47IE)
        reg_LC47IE <= w_wdata[47];
      if (w_wen & hvien_LC48IE)
        reg_LC48IE <= w_wdata[48];
      if (w_wen & hvien_LC49IE)
        reg_LC49IE <= w_wdata[49];
      if (w_wen & hvien_LC50IE)
        reg_LC50IE <= w_wdata[50];
      if (w_wen & hvien_LC51IE)
        reg_LC51IE <= w_wdata[51];
      if (w_wen & hvien_LC52IE)
        reg_LC52IE <= w_wdata[52];
      if (w_wen & hvien_LC53IE)
        reg_LC53IE <= w_wdata[53];
      if (w_wen & hvien_LC54IE)
        reg_LC54IE <= w_wdata[54];
      if (w_wen & hvien_LC55IE)
        reg_LC55IE <= w_wdata[55];
      if (w_wen & hvien_LC56IE)
        reg_LC56IE <= w_wdata[56];
      if (w_wen & hvien_LC57IE)
        reg_LC57IE <= w_wdata[57];
      if (w_wen & hvien_LC58IE)
        reg_LC58IE <= w_wdata[58];
      if (w_wen & hvien_LC59IE)
        reg_LC59IE <= w_wdata[59];
      if (w_wen & hvien_LC60IE)
        reg_LC60IE <= w_wdata[60];
      if (w_wen & hvien_LC61IE)
        reg_LC61IE <= w_wdata[61];
      if (w_wen & hvien_LC62IE)
        reg_LC62IE <= w_wdata[62];
      if (w_wen & hvien_LC63IE)
        reg_LC63IE <= w_wdata[63];
    end
  end
  assign rdata =
    {aliasVec[62:12], 3'h0, SEIE_masked, 3'h0, STIE_masked, 3'h0, SSIE_masked, 1'h0};
  assign regOut_SSIE = SSIE_masked;
  assign regOut_STIE = STIE_masked;
  assign regOut_SEIE = SEIE_masked;
  assign regOut_LCOFIE = aliasVec[12];
  assign regOut_LC14IE = aliasVec[13];
  assign regOut_LC15IE = aliasVec[14];
  assign regOut_LC16IE = aliasVec[15];
  assign regOut_LC17IE = aliasVec[16];
  assign regOut_LC18IE = aliasVec[17];
  assign regOut_LC19IE = aliasVec[18];
  assign regOut_LC20IE = aliasVec[19];
  assign regOut_LC21IE = aliasVec[20];
  assign regOut_LC22IE = aliasVec[21];
  assign regOut_LC23IE = aliasVec[22];
  assign regOut_LC24IE = aliasVec[23];
  assign regOut_LC25IE = aliasVec[24];
  assign regOut_LC26IE = aliasVec[25];
  assign regOut_LC27IE = aliasVec[26];
  assign regOut_LC28IE = aliasVec[27];
  assign regOut_LC29IE = aliasVec[28];
  assign regOut_LC30IE = aliasVec[29];
  assign regOut_LC31IE = aliasVec[30];
  assign regOut_LC32IE = aliasVec[31];
  assign regOut_LC33IE = aliasVec[32];
  assign regOut_LC34IE = aliasVec[33];
  assign regOut_LPRASEIE = aliasVec[34];
  assign regOut_LC36IE = aliasVec[35];
  assign regOut_LC37IE = aliasVec[36];
  assign regOut_LC38IE = aliasVec[37];
  assign regOut_LC39IE = aliasVec[38];
  assign regOut_LC40IE = aliasVec[39];
  assign regOut_LC41IE = aliasVec[40];
  assign regOut_LC42IE = aliasVec[41];
  assign regOut_HPRASEIE = aliasVec[42];
  assign regOut_LC44IE = aliasVec[43];
  assign regOut_LC45IE = aliasVec[44];
  assign regOut_LC46IE = aliasVec[45];
  assign regOut_LC47IE = aliasVec[46];
  assign regOut_LC48IE = aliasVec[47];
  assign regOut_LC49IE = aliasVec[48];
  assign regOut_LC50IE = aliasVec[49];
  assign regOut_LC51IE = aliasVec[50];
  assign regOut_LC52IE = aliasVec[51];
  assign regOut_LC53IE = aliasVec[52];
  assign regOut_LC54IE = aliasVec[53];
  assign regOut_LC55IE = aliasVec[54];
  assign regOut_LC56IE = aliasVec[55];
  assign regOut_LC57IE = aliasVec[56];
  assign regOut_LC58IE = aliasVec[57];
  assign regOut_LC59IE = aliasVec[58];
  assign regOut_LC60IE = aliasVec[59];
  assign regOut_LC61IE = aliasVec[60];
  assign regOut_LC62IE = aliasVec[61];
  assign regOut_LC63IE = aliasVec[62];
  assign toMie_VSSIE_valid = hideleg_VSSI & w_wen;
  assign toMie_VSSIE_bits = hideleg_VSSI & w_wen & w_wdata[1];
  assign toMie_VSTIE_valid = hideleg_VSTI & w_wen;
  assign toMie_VSTIE_bits = hideleg_VSTI & w_wen & w_wdata[5];
  assign toMie_VSEIE_valid = hideleg_VSEI & w_wen;
  assign toMie_VSEIE_bits = hideleg_VSEI & w_wen & w_wdata[9];
  assign toMie_LCOFIE_valid = lcofiDelegated & w_wen;
  assign toMie_LCOFIE_bits = lcofiDelegated & w_wen & w_wdata[13];
  assign toSie_VSSIE_valid = 1'h0;
  assign toSie_VSSIE_bits = 1'h0;
  assign toSie_VSTIE_valid = 1'h0;
  assign toSie_VSTIE_bits = 1'h0;
  assign toSie_VSEIE_valid = 1'h0;
  assign toSie_VSEIE_bits = 1'h0;
  assign toSie_LCOFIE_valid = 1'h0;
  assign toSie_LCOFIE_bits = 1'h0;
  assign toSie_LC14IE_valid = 1'h0;
  assign toSie_LC14IE_bits = 1'h0;
  assign toSie_LC15IE_valid = 1'h0;
  assign toSie_LC15IE_bits = 1'h0;
  assign toSie_LC16IE_valid = 1'h0;
  assign toSie_LC16IE_bits = 1'h0;
  assign toSie_LC17IE_valid = 1'h0;
  assign toSie_LC17IE_bits = 1'h0;
  assign toSie_LC18IE_valid = 1'h0;
  assign toSie_LC18IE_bits = 1'h0;
  assign toSie_LC19IE_valid = 1'h0;
  assign toSie_LC19IE_bits = 1'h0;
  assign toSie_LC20IE_valid = 1'h0;
  assign toSie_LC20IE_bits = 1'h0;
  assign toSie_LC21IE_valid = 1'h0;
  assign toSie_LC21IE_bits = 1'h0;
  assign toSie_LC22IE_valid = 1'h0;
  assign toSie_LC22IE_bits = 1'h0;
  assign toSie_LC23IE_valid = 1'h0;
  assign toSie_LC23IE_bits = 1'h0;
  assign toSie_LC24IE_valid = 1'h0;
  assign toSie_LC24IE_bits = 1'h0;
  assign toSie_LC25IE_valid = 1'h0;
  assign toSie_LC25IE_bits = 1'h0;
  assign toSie_LC26IE_valid = 1'h0;
  assign toSie_LC26IE_bits = 1'h0;
  assign toSie_LC27IE_valid = 1'h0;
  assign toSie_LC27IE_bits = 1'h0;
  assign toSie_LC28IE_valid = 1'h0;
  assign toSie_LC28IE_bits = 1'h0;
  assign toSie_LC29IE_valid = 1'h0;
  assign toSie_LC29IE_bits = 1'h0;
  assign toSie_LC30IE_valid = 1'h0;
  assign toSie_LC30IE_bits = 1'h0;
  assign toSie_LC31IE_valid = 1'h0;
  assign toSie_LC31IE_bits = 1'h0;
  assign toSie_LC32IE_valid = 1'h0;
  assign toSie_LC32IE_bits = 1'h0;
  assign toSie_LC33IE_valid = 1'h0;
  assign toSie_LC33IE_bits = 1'h0;
  assign toSie_LC34IE_valid = 1'h0;
  assign toSie_LC34IE_bits = 1'h0;
  assign toSie_LPRASEIE_valid = 1'h0;
  assign toSie_LPRASEIE_bits = 1'h0;
  assign toSie_LC36IE_valid = 1'h0;
  assign toSie_LC36IE_bits = 1'h0;
  assign toSie_LC37IE_valid = 1'h0;
  assign toSie_LC37IE_bits = 1'h0;
  assign toSie_LC38IE_valid = 1'h0;
  assign toSie_LC38IE_bits = 1'h0;
  assign toSie_LC39IE_valid = 1'h0;
  assign toSie_LC39IE_bits = 1'h0;
  assign toSie_LC40IE_valid = 1'h0;
  assign toSie_LC40IE_bits = 1'h0;
  assign toSie_LC41IE_valid = 1'h0;
  assign toSie_LC41IE_bits = 1'h0;
  assign toSie_LC42IE_valid = 1'h0;
  assign toSie_LC42IE_bits = 1'h0;
  assign toSie_HPRASEIE_valid = 1'h0;
  assign toSie_HPRASEIE_bits = 1'h0;
  assign toSie_LC44IE_valid = 1'h0;
  assign toSie_LC44IE_bits = 1'h0;
  assign toSie_LC45IE_valid = 1'h0;
  assign toSie_LC45IE_bits = 1'h0;
  assign toSie_LC46IE_valid = 1'h0;
  assign toSie_LC46IE_bits = 1'h0;
  assign toSie_LC47IE_valid = 1'h0;
  assign toSie_LC47IE_bits = 1'h0;
  assign toSie_LC48IE_valid = 1'h0;
  assign toSie_LC48IE_bits = 1'h0;
  assign toSie_LC49IE_valid = 1'h0;
  assign toSie_LC49IE_bits = 1'h0;
  assign toSie_LC50IE_valid = 1'h0;
  assign toSie_LC50IE_bits = 1'h0;
  assign toSie_LC51IE_valid = 1'h0;
  assign toSie_LC51IE_bits = 1'h0;
  assign toSie_LC52IE_valid = 1'h0;
  assign toSie_LC52IE_bits = 1'h0;
  assign toSie_LC53IE_valid = 1'h0;
  assign toSie_LC53IE_bits = 1'h0;
  assign toSie_LC54IE_valid = 1'h0;
  assign toSie_LC54IE_bits = 1'h0;
  assign toSie_LC55IE_valid = 1'h0;
  assign toSie_LC55IE_bits = 1'h0;
  assign toSie_LC56IE_valid = 1'h0;
  assign toSie_LC56IE_bits = 1'h0;
  assign toSie_LC57IE_valid = 1'h0;
  assign toSie_LC57IE_bits = 1'h0;
  assign toSie_LC58IE_valid = 1'h0;
  assign toSie_LC58IE_bits = 1'h0;
  assign toSie_LC59IE_valid = 1'h0;
  assign toSie_LC59IE_bits = 1'h0;
  assign toSie_LC60IE_valid = 1'h0;
  assign toSie_LC60IE_bits = 1'h0;
  assign toSie_LC61IE_valid = 1'h0;
  assign toSie_LC61IE_bits = 1'h0;
  assign toSie_LC62IE_valid = 1'h0;
  assign toSie_LC62IE_bits = 1'h0;
  assign toSie_LC63IE_valid = 1'h0;
  assign toSie_LC63IE_bits = 1'h0;
endmodule


module VSipModule(
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SSIP,
  output        regOut_STIP,
  output        regOut_SEIP,
  output        regOut_LCOFIP,
  output        regOut_LC14IP,
  output        regOut_LC15IP,
  output        regOut_LC16IP,
  output        regOut_LC17IP,
  output        regOut_LC18IP,
  output        regOut_LC19IP,
  output        regOut_LC20IP,
  output        regOut_LC21IP,
  output        regOut_LC22IP,
  output        regOut_LC23IP,
  output        regOut_LC24IP,
  output        regOut_LC25IP,
  output        regOut_LC26IP,
  output        regOut_LC27IP,
  output        regOut_LC28IP,
  output        regOut_LC29IP,
  output        regOut_LC30IP,
  output        regOut_LC31IP,
  output        regOut_LC32IP,
  output        regOut_LC33IP,
  output        regOut_LC34IP,
  output        regOut_LPRASEIP,
  output        regOut_LC36IP,
  output        regOut_LC37IP,
  output        regOut_LC38IP,
  output        regOut_LC39IP,
  output        regOut_LC40IP,
  output        regOut_LC41IP,
  output        regOut_LC42IP,
  output        regOut_HPRASEIP,
  output        regOut_LC44IP,
  output        regOut_LC45IP,
  output        regOut_LC46IP,
  output        regOut_LC47IP,
  output        regOut_LC48IP,
  output        regOut_LC49IP,
  output        regOut_LC50IP,
  output        regOut_LC51IP,
  output        regOut_LC52IP,
  output        regOut_LC53IP,
  output        regOut_LC54IP,
  output        regOut_LC55IP,
  output        regOut_LC56IP,
  output        regOut_LC57IP,
  output        regOut_LC58IP,
  output        regOut_LC59IP,
  output        regOut_LC60IP,
  output        regOut_LC61IP,
  output        regOut_LC62IP,
  output        regOut_LC63IP,
  input         mideleg_SSI,
  input         mideleg_STI,
  input         mideleg_SEI,
  input         mideleg_LCOFI,
  input         mip_SSIP,
  input         mip_VSSIP,
  input         mip_MSIP,
  input         mip_STIP,
  input         mip_VSTIP,
  input         mip_MTIP,
  input         mip_SEIP,
  input         mip_VSEIP,
  input         mip_MEIP,
  input         mip_SGEIP,
  input         mip_LCOFIP,
  input         mip_LC14IP,
  input         mip_LC15IP,
  input         mip_LC16IP,
  input         mip_LC17IP,
  input         mip_LC18IP,
  input         mip_LC19IP,
  input         mip_LC20IP,
  input         mip_LC21IP,
  input         mip_LC22IP,
  input         mip_LC23IP,
  input         mip_LC24IP,
  input         mip_LC25IP,
  input         mip_LC26IP,
  input         mip_LC27IP,
  input         mip_LC28IP,
  input         mip_LC29IP,
  input         mip_LC30IP,
  input         mip_LC31IP,
  input         mip_LC32IP,
  input         mip_LC33IP,
  input         mip_LC34IP,
  input         mip_LPRASEIP,
  input         mip_LC36IP,
  input         mip_LC37IP,
  input         mip_LC38IP,
  input         mip_LC39IP,
  input         mip_LC40IP,
  input         mip_LC41IP,
  input         mip_LC42IP,
  input         mip_HPRASEIP,
  input         mip_LC44IP,
  input         mip_LC45IP,
  input         mip_LC46IP,
  input         mip_LC47IP,
  input         mip_LC48IP,
  input         mip_LC49IP,
  input         mip_LC50IP,
  input         mip_LC51IP,
  input         mip_LC52IP,
  input         mip_LC53IP,
  input         mip_LC54IP,
  input         mip_LC55IP,
  input         mip_LC56IP,
  input         mip_LC57IP,
  input         mip_LC58IP,
  input         mip_LC59IP,
  input         mip_LC60IP,
  input         mip_LC61IP,
  input         mip_LC62IP,
  input         mip_LC63IP,
  input         mvip_SSIP,
  input         mvip_STIP,
  input         mvip_SEIP,
  input         mvip_LCOFIP,
  input         mvip_LC14IP,
  input         mvip_LC15IP,
  input         mvip_LC16IP,
  input         mvip_LC17IP,
  input         mvip_LC18IP,
  input         mvip_LC19IP,
  input         mvip_LC20IP,
  input         mvip_LC21IP,
  input         mvip_LC22IP,
  input         mvip_LC23IP,
  input         mvip_LC24IP,
  input         mvip_LC25IP,
  input         mvip_LC26IP,
  input         mvip_LC27IP,
  input         mvip_LC28IP,
  input         mvip_LC29IP,
  input         mvip_LC30IP,
  input         mvip_LC31IP,
  input         mvip_LC32IP,
  input         mvip_LC33IP,
  input         mvip_LC34IP,
  input         mvip_LPRASEIP,
  input         mvip_LC36IP,
  input         mvip_LC37IP,
  input         mvip_LC38IP,
  input         mvip_LC39IP,
  input         mvip_LC40IP,
  input         mvip_LC41IP,
  input         mvip_LC42IP,
  input         mvip_HPRASEIP,
  input         mvip_LC44IP,
  input         mvip_LC45IP,
  input         mvip_LC46IP,
  input         mvip_LC47IP,
  input         mvip_LC48IP,
  input         mvip_LC49IP,
  input         mvip_LC50IP,
  input         mvip_LC51IP,
  input         mvip_LC52IP,
  input         mvip_LC53IP,
  input         mvip_LC54IP,
  input         mvip_LC55IP,
  input         mvip_LC56IP,
  input         mvip_LC57IP,
  input         mvip_LC58IP,
  input         mvip_LC59IP,
  input         mvip_LC60IP,
  input         mvip_LC61IP,
  input         mvip_LC62IP,
  input         mvip_LC63IP,
  input         mvien_SSIE,
  input         mvien_SEIE,
  input         mvien_LC14IE,
  input         mvien_LC15IE,
  input         mvien_LC16IE,
  input         mvien_LC17IE,
  input         mvien_LC18IE,
  input         mvien_LC19IE,
  input         mvien_LC20IE,
  input         mvien_LC21IE,
  input         mvien_LC22IE,
  input         mvien_LC23IE,
  input         mvien_LC24IE,
  input         mvien_LC25IE,
  input         mvien_LC26IE,
  input         mvien_LC27IE,
  input         mvien_LC28IE,
  input         mvien_LC29IE,
  input         mvien_LC30IE,
  input         mvien_LC31IE,
  input         mvien_LC32IE,
  input         mvien_LC33IE,
  input         mvien_LC34IE,
  input         mvien_LPRASEIE,
  input         mvien_LC36IE,
  input         mvien_LC37IE,
  input         mvien_LC38IE,
  input         mvien_LC39IE,
  input         mvien_LC40IE,
  input         mvien_LC41IE,
  input         mvien_LC42IE,
  input         mvien_HPRASEIE,
  input         mvien_LC44IE,
  input         mvien_LC45IE,
  input         mvien_LC46IE,
  input         mvien_LC47IE,
  input         mvien_LC48IE,
  input         mvien_LC49IE,
  input         mvien_LC50IE,
  input         mvien_LC51IE,
  input         mvien_LC52IE,
  input         mvien_LC53IE,
  input         mvien_LC54IE,
  input         mvien_LC55IE,
  input         mvien_LC56IE,
  input         mvien_LC57IE,
  input         mvien_LC58IE,
  input         mvien_LC59IE,
  input         mvien_LC60IE,
  input         mvien_LC61IE,
  input         mvien_LC62IE,
  input         mvien_LC63IE,
  input         hideleg_SSI,
  input         hideleg_VSSI,
  input         hideleg_MSI,
  input         hideleg_STI,
  input         hideleg_VSTI,
  input         hideleg_MTI,
  input         hideleg_SEI,
  input         hideleg_VSEI,
  input         hideleg_MEI,
  input         hideleg_SGEI,
  input         hideleg_LCOFI,
  input         hvien_LC14IE,
  input         hvien_LC15IE,
  input         hvien_LC16IE,
  input         hvien_LC17IE,
  input         hvien_LC18IE,
  input         hvien_LC19IE,
  input         hvien_LC20IE,
  input         hvien_LC21IE,
  input         hvien_LC22IE,
  input         hvien_LC23IE,
  input         hvien_LC24IE,
  input         hvien_LC25IE,
  input         hvien_LC26IE,
  input         hvien_LC27IE,
  input         hvien_LC28IE,
  input         hvien_LC29IE,
  input         hvien_LC30IE,
  input         hvien_LC31IE,
  input         hvien_LC32IE,
  input         hvien_LC33IE,
  input         hvien_LC34IE,
  input         hvien_LPRASEIE,
  input         hvien_LC36IE,
  input         hvien_LC37IE,
  input         hvien_LC38IE,
  input         hvien_LC39IE,
  input         hvien_LC40IE,
  input         hvien_LC41IE,
  input         hvien_LC42IE,
  input         hvien_HPRASEIE,
  input         hvien_LC44IE,
  input         hvien_LC45IE,
  input         hvien_LC46IE,
  input         hvien_LC47IE,
  input         hvien_LC48IE,
  input         hvien_LC49IE,
  input         hvien_LC50IE,
  input         hvien_LC51IE,
  input         hvien_LC52IE,
  input         hvien_LC53IE,
  input         hvien_LC54IE,
  input         hvien_LC55IE,
  input         hvien_LC56IE,
  input         hvien_LC57IE,
  input         hvien_LC58IE,
  input         hvien_LC59IE,
  input         hvien_LC60IE,
  input         hvien_LC61IE,
  input         hvien_LC62IE,
  input         hvien_LC63IE,
  input         hvip_VSSIP,
  input         hvip_VSTIP,
  input         hvip_VSEIP,
  input         hvip_LCOFIP,
  input         hvip_LC14IP,
  input         hvip_LC15IP,
  input         hvip_LC16IP,
  input         hvip_LC17IP,
  input         hvip_LC18IP,
  input         hvip_LC19IP,
  input         hvip_LC20IP,
  input         hvip_LC21IP,
  input         hvip_LC22IP,
  input         hvip_LC23IP,
  input         hvip_LC24IP,
  input         hvip_LC25IP,
  input         hvip_LC26IP,
  input         hvip_LC27IP,
  input         hvip_LC28IP,
  input         hvip_LC29IP,
  input         hvip_LC30IP,
  input         hvip_LC31IP,
  input         hvip_LC32IP,
  input         hvip_LC33IP,
  input         hvip_LC34IP,
  input         hvip_LPRASEIP,
  input         hvip_LC36IP,
  input         hvip_LC37IP,
  input         hvip_LC38IP,
  input         hvip_LC39IP,
  input         hvip_LC40IP,
  input         hvip_LC41IP,
  input         hvip_LC42IP,
  input         hvip_HPRASEIP,
  input         hvip_LC44IP,
  input         hvip_LC45IP,
  input         hvip_LC46IP,
  input         hvip_LC47IP,
  input         hvip_LC48IP,
  input         hvip_LC49IP,
  input         hvip_LC50IP,
  input         hvip_LC51IP,
  input         hvip_LC52IP,
  input         hvip_LC53IP,
  input         hvip_LC54IP,
  input         hvip_LC55IP,
  input         hvip_LC56IP,
  input         hvip_LC57IP,
  input         hvip_LC58IP,
  input         hvip_LC59IP,
  input         hvip_LC60IP,
  input         hvip_LC61IP,
  input         hvip_LC62IP,
  input         hvip_LC63IP,
  output        toMip_LCOFIP_valid,
  output        toMip_LCOFIP_bits,
  output        toHvip_VSSIP_valid,
  output        toHvip_VSSIP_bits,
  output        toHvip_LCOFIP_bits,
  output        toHvip_LC14IP_valid,
  output        toHvip_LC14IP_bits,
  output        toHvip_LC15IP_valid,
  output        toHvip_LC15IP_bits,
  output        toHvip_LC16IP_valid,
  output        toHvip_LC16IP_bits,
  output        toHvip_LC17IP_valid,
  output        toHvip_LC17IP_bits,
  output        toHvip_LC18IP_valid,
  output        toHvip_LC18IP_bits,
  output        toHvip_LC19IP_valid,
  output        toHvip_LC19IP_bits,
  output        toHvip_LC20IP_valid,
  output        toHvip_LC20IP_bits,
  output        toHvip_LC21IP_valid,
  output        toHvip_LC21IP_bits,
  output        toHvip_LC22IP_valid,
  output        toHvip_LC22IP_bits,
  output        toHvip_LC23IP_valid,
  output        toHvip_LC23IP_bits,
  output        toHvip_LC24IP_valid,
  output        toHvip_LC24IP_bits,
  output        toHvip_LC25IP_valid,
  output        toHvip_LC25IP_bits,
  output        toHvip_LC26IP_valid,
  output        toHvip_LC26IP_bits,
  output        toHvip_LC27IP_valid,
  output        toHvip_LC27IP_bits,
  output        toHvip_LC28IP_valid,
  output        toHvip_LC28IP_bits,
  output        toHvip_LC29IP_valid,
  output        toHvip_LC29IP_bits,
  output        toHvip_LC30IP_valid,
  output        toHvip_LC30IP_bits,
  output        toHvip_LC31IP_valid,
  output        toHvip_LC31IP_bits,
  output        toHvip_LC32IP_valid,
  output        toHvip_LC32IP_bits,
  output        toHvip_LC33IP_valid,
  output        toHvip_LC33IP_bits,
  output        toHvip_LC34IP_valid,
  output        toHvip_LC34IP_bits,
  output        toHvip_LPRASEIP_valid,
  output        toHvip_LPRASEIP_bits,
  output        toHvip_LC36IP_valid,
  output        toHvip_LC36IP_bits,
  output        toHvip_LC37IP_valid,
  output        toHvip_LC37IP_bits,
  output        toHvip_LC38IP_valid,
  output        toHvip_LC38IP_bits,
  output        toHvip_LC39IP_valid,
  output        toHvip_LC39IP_bits,
  output        toHvip_LC40IP_valid,
  output        toHvip_LC40IP_bits,
  output        toHvip_LC41IP_valid,
  output        toHvip_LC41IP_bits,
  output        toHvip_LC42IP_valid,
  output        toHvip_LC42IP_bits,
  output        toHvip_HPRASEIP_valid,
  output        toHvip_HPRASEIP_bits,
  output        toHvip_LC44IP_valid,
  output        toHvip_LC44IP_bits,
  output        toHvip_LC45IP_valid,
  output        toHvip_LC45IP_bits,
  output        toHvip_LC46IP_valid,
  output        toHvip_LC46IP_bits,
  output        toHvip_LC47IP_valid,
  output        toHvip_LC47IP_bits,
  output        toHvip_LC48IP_valid,
  output        toHvip_LC48IP_bits,
  output        toHvip_LC49IP_valid,
  output        toHvip_LC49IP_bits,
  output        toHvip_LC50IP_valid,
  output        toHvip_LC50IP_bits,
  output        toHvip_LC51IP_valid,
  output        toHvip_LC51IP_bits,
  output        toHvip_LC52IP_valid,
  output        toHvip_LC52IP_bits,
  output        toHvip_LC53IP_valid,
  output        toHvip_LC53IP_bits,
  output        toHvip_LC54IP_valid,
  output        toHvip_LC54IP_bits,
  output        toHvip_LC55IP_valid,
  output        toHvip_LC55IP_bits,
  output        toHvip_LC56IP_valid,
  output        toHvip_LC56IP_bits,
  output        toHvip_LC57IP_valid,
  output        toHvip_LC57IP_bits,
  output        toHvip_LC58IP_valid,
  output        toHvip_LC58IP_bits,
  output        toHvip_LC59IP_valid,
  output        toHvip_LC59IP_bits,
  output        toHvip_LC60IP_valid,
  output        toHvip_LC60IP_bits,
  output        toHvip_LC61IP_valid,
  output        toHvip_LC61IP_bits,
  output        toHvip_LC62IP_valid,
  output        toHvip_LC62IP_bits,
  output        toHvip_LC63IP_valid,
  output        toHvip_LC63IP_bits
);

  wire        SSIP_masked;
  wire        STIP_masked;
  wire        SEIP_masked;
  wire [61:0] originIP;
  wire [61:0] aliasVec =
    {50'h0,
     hideleg_LCOFI,
     hideleg_SGEI,
     hideleg_MEI,
     hideleg_VSEI,
     hideleg_SEI,
     1'h0,
     hideleg_MTI,
     hideleg_VSTI,
     hideleg_STI,
     1'h0,
     hideleg_MSI,
     hideleg_VSSI};
  assign originIP =
    {50'h0, mideleg_LCOFI, 3'h5, mideleg_SEI, 3'h1, mideleg_STI, 3'h1} & aliasVec
    & {mip_LC63IP,
       mip_LC62IP,
       mip_LC61IP,
       mip_LC60IP,
       mip_LC59IP,
       mip_LC58IP,
       mip_LC57IP,
       mip_LC56IP,
       mip_LC55IP,
       mip_LC54IP,
       mip_LC53IP,
       mip_LC52IP,
       mip_LC51IP,
       mip_LC50IP,
       mip_LC49IP,
       mip_LC48IP,
       mip_LC47IP,
       mip_LC46IP,
       mip_LC45IP,
       mip_LC44IP,
       mip_HPRASEIP,
       mip_LC42IP,
       mip_LC41IP,
       mip_LC40IP,
       mip_LC39IP,
       mip_LC38IP,
       mip_LC37IP,
       mip_LC36IP,
       mip_LPRASEIP,
       mip_LC34IP,
       mip_LC33IP,
       mip_LC32IP,
       mip_LC31IP,
       mip_LC30IP,
       mip_LC29IP,
       mip_LC28IP,
       mip_LC27IP,
       mip_LC26IP,
       mip_LC25IP,
       mip_LC24IP,
       mip_LC23IP,
       mip_LC22IP,
       mip_LC21IP,
       mip_LC20IP,
       mip_LC19IP,
       mip_LC18IP,
       mip_LC17IP,
       mip_LC16IP,
       mip_LC15IP,
       mip_LC14IP,
       mip_LCOFIP,
       mip_SGEIP,
       mip_MEIP,
       mip_VSEIP,
       mip_SEIP,
       1'h0,
       mip_MTIP,
       mip_VSTIP,
       mip_STIP,
       1'h0,
       mip_MSIP,
       mip_VSSIP}
    | {50'h3FFFFFFFFFFFF, ~mideleg_LCOFI, 3'h2, ~mideleg_SEI, 3'h6, ~mideleg_STI, 3'h6}
    & aliasVec
    & {mvien_LC63IE,
       mvien_LC62IE,
       mvien_LC61IE,
       mvien_LC60IE,
       mvien_LC59IE,
       mvien_LC58IE,
       mvien_LC57IE,
       mvien_LC56IE,
       mvien_LC55IE,
       mvien_LC54IE,
       mvien_LC53IE,
       mvien_LC52IE,
       mvien_LC51IE,
       mvien_LC50IE,
       mvien_LC49IE,
       mvien_LC48IE,
       mvien_LC47IE,
       mvien_LC46IE,
       mvien_LC45IE,
       mvien_LC44IE,
       mvien_HPRASEIE,
       mvien_LC42IE,
       mvien_LC41IE,
       mvien_LC40IE,
       mvien_LC39IE,
       mvien_LC38IE,
       mvien_LC37IE,
       mvien_LC36IE,
       mvien_LPRASEIE,
       mvien_LC34IE,
       mvien_LC33IE,
       mvien_LC32IE,
       mvien_LC31IE,
       mvien_LC30IE,
       mvien_LC29IE,
       mvien_LC28IE,
       mvien_LC27IE,
       mvien_LC26IE,
       mvien_LC25IE,
       mvien_LC24IE,
       mvien_LC23IE,
       mvien_LC22IE,
       mvien_LC21IE,
       mvien_LC20IE,
       mvien_LC19IE,
       mvien_LC18IE,
       mvien_LC17IE,
       mvien_LC16IE,
       mvien_LC15IE,
       mvien_LC14IE,
       4'h0,
       mvien_SEIE,
       7'h0}
    & {mvip_LC63IP,
       mvip_LC62IP,
       mvip_LC61IP,
       mvip_LC60IP,
       mvip_LC59IP,
       mvip_LC58IP,
       mvip_LC57IP,
       mvip_LC56IP,
       mvip_LC55IP,
       mvip_LC54IP,
       mvip_LC53IP,
       mvip_LC52IP,
       mvip_LC51IP,
       mvip_LC50IP,
       mvip_LC49IP,
       mvip_LC48IP,
       mvip_LC47IP,
       mvip_LC46IP,
       mvip_LC45IP,
       mvip_LC44IP,
       mvip_HPRASEIP,
       mvip_LC42IP,
       mvip_LC41IP,
       mvip_LC40IP,
       mvip_LC39IP,
       mvip_LC38IP,
       mvip_LC37IP,
       mvip_LC36IP,
       mvip_LPRASEIP,
       mvip_LC34IP,
       mvip_LC33IP,
       mvip_LC32IP,
       mvip_LC31IP,
       mvip_LC30IP,
       mvip_LC29IP,
       mvip_LC28IP,
       mvip_LC27IP,
       mvip_LC26IP,
       mvip_LC25IP,
       mvip_LC24IP,
       mvip_LC23IP,
       mvip_LC22IP,
       mvip_LC21IP,
       mvip_LC20IP,
       mvip_LC19IP,
       mvip_LC18IP,
       mvip_LC17IP,
       mvip_LC16IP,
       mvip_LC15IP,
       mvip_LC14IP,
       mvip_LCOFIP,
       3'h0,
       mvip_SEIP,
       3'h0,
       mvip_STIP,
       3'h0}
    | {50'h3FFFFFFFFFFFF,
       ~hideleg_LCOFI,
       ~hideleg_SGEI,
       ~hideleg_MEI,
       ~hideleg_VSEI,
       ~hideleg_SEI,
       1'h1,
       ~hideleg_MTI,
       ~hideleg_VSTI,
       ~hideleg_STI,
       1'h1,
       ~hideleg_MSI,
       ~hideleg_VSSI}
    & {hvien_LC63IE,
       hvien_LC62IE,
       hvien_LC61IE,
       hvien_LC60IE,
       hvien_LC59IE,
       hvien_LC58IE,
       hvien_LC57IE,
       hvien_LC56IE,
       hvien_LC55IE,
       hvien_LC54IE,
       hvien_LC53IE,
       hvien_LC52IE,
       hvien_LC51IE,
       hvien_LC50IE,
       hvien_LC49IE,
       hvien_LC48IE,
       hvien_LC47IE,
       hvien_LC46IE,
       hvien_LC45IE,
       hvien_LC44IE,
       hvien_HPRASEIE,
       hvien_LC42IE,
       hvien_LC41IE,
       hvien_LC40IE,
       hvien_LC39IE,
       hvien_LC38IE,
       hvien_LC37IE,
       hvien_LC36IE,
       hvien_LPRASEIE,
       hvien_LC34IE,
       hvien_LC33IE,
       hvien_LC32IE,
       hvien_LC31IE,
       hvien_LC30IE,
       hvien_LC29IE,
       hvien_LC28IE,
       hvien_LC27IE,
       hvien_LC26IE,
       hvien_LC25IE,
       hvien_LC24IE,
       hvien_LC23IE,
       hvien_LC22IE,
       hvien_LC21IE,
       hvien_LC20IE,
       hvien_LC19IE,
       hvien_LC18IE,
       hvien_LC17IE,
       hvien_LC16IE,
       hvien_LC15IE,
       hvien_LC14IE,
       12'h0}
    & {hvip_LC63IP,
       hvip_LC62IP,
       hvip_LC61IP,
       hvip_LC60IP,
       hvip_LC59IP,
       hvip_LC58IP,
       hvip_LC57IP,
       hvip_LC56IP,
       hvip_LC55IP,
       hvip_LC54IP,
       hvip_LC53IP,
       hvip_LC52IP,
       hvip_LC51IP,
       hvip_LC50IP,
       hvip_LC49IP,
       hvip_LC48IP,
       hvip_LC47IP,
       hvip_LC46IP,
       hvip_LC45IP,
       hvip_LC44IP,
       hvip_HPRASEIP,
       hvip_LC42IP,
       hvip_LC41IP,
       hvip_LC40IP,
       hvip_LC39IP,
       hvip_LC38IP,
       hvip_LC37IP,
       hvip_LC36IP,
       hvip_LPRASEIP,
       hvip_LC34IP,
       hvip_LC33IP,
       hvip_LC32IP,
       hvip_LC31IP,
       hvip_LC30IP,
       hvip_LC29IP,
       hvip_LC28IP,
       hvip_LC27IP,
       hvip_LC26IP,
       hvip_LC25IP,
       hvip_LC24IP,
       hvip_LC23IP,
       hvip_LC22IP,
       hvip_LC21IP,
       hvip_LC20IP,
       hvip_LC19IP,
       hvip_LC18IP,
       hvip_LC17IP,
       hvip_LC16IP,
       hvip_LC15IP,
       hvip_LC14IP,
       hvip_LCOFIP,
       2'h0,
       hvip_VSEIP,
       3'h0,
       hvip_VSTIP,
       3'h0,
       hvip_VSSIP};
  assign SEIP_masked = originIP[8];
  assign STIP_masked = originIP[4];
  assign SSIP_masked = originIP[0];
  assign rdata =
    {originIP[61:11],
     3'h0,
     SEIP_masked,
     3'h0,
     STIP_masked,
     3'h0,
     SSIP_masked,
     1'h0};
  assign regOut_SSIP = SSIP_masked;
  assign regOut_STIP = STIP_masked;
  assign regOut_SEIP = SEIP_masked;
  assign regOut_LCOFIP = originIP[11];
  assign regOut_LC14IP = originIP[12];
  assign regOut_LC15IP = originIP[13];
  assign regOut_LC16IP = originIP[14];
  assign regOut_LC17IP = originIP[15];
  assign regOut_LC18IP = originIP[16];
  assign regOut_LC19IP = originIP[17];
  assign regOut_LC20IP = originIP[18];
  assign regOut_LC21IP = originIP[19];
  assign regOut_LC22IP = originIP[20];
  assign regOut_LC23IP = originIP[21];
  assign regOut_LC24IP = originIP[22];
  assign regOut_LC25IP = originIP[23];
  assign regOut_LC26IP = originIP[24];
  assign regOut_LC27IP = originIP[25];
  assign regOut_LC28IP = originIP[26];
  assign regOut_LC29IP = originIP[27];
  assign regOut_LC30IP = originIP[28];
  assign regOut_LC31IP = originIP[29];
  assign regOut_LC32IP = originIP[30];
  assign regOut_LC33IP = originIP[31];
  assign regOut_LC34IP = originIP[32];
  assign regOut_LPRASEIP = originIP[33];
  assign regOut_LC36IP = originIP[34];
  assign regOut_LC37IP = originIP[35];
  assign regOut_LC38IP = originIP[36];
  assign regOut_LC39IP = originIP[37];
  assign regOut_LC40IP = originIP[38];
  assign regOut_LC41IP = originIP[39];
  assign regOut_LC42IP = originIP[40];
  assign regOut_HPRASEIP = originIP[41];
  assign regOut_LC44IP = originIP[42];
  assign regOut_LC45IP = originIP[43];
  assign regOut_LC46IP = originIP[44];
  assign regOut_LC47IP = originIP[45];
  assign regOut_LC48IP = originIP[46];
  assign regOut_LC49IP = originIP[47];
  assign regOut_LC50IP = originIP[48];
  assign regOut_LC51IP = originIP[49];
  assign regOut_LC52IP = originIP[50];
  assign regOut_LC53IP = originIP[51];
  assign regOut_LC54IP = originIP[52];
  assign regOut_LC55IP = originIP[53];
  assign regOut_LC56IP = originIP[54];
  assign regOut_LC57IP = originIP[55];
  assign regOut_LC58IP = originIP[56];
  assign regOut_LC59IP = originIP[57];
  assign regOut_LC60IP = originIP[58];
  assign regOut_LC61IP = originIP[59];
  assign regOut_LC62IP = originIP[60];
  assign regOut_LC63IP = originIP[61];
  assign toMip_LCOFIP_valid = w_wen & hideleg_LCOFI & mideleg_LCOFI;
  assign toMip_LCOFIP_bits = w_wdata[13];
  assign toHvip_VSSIP_valid = w_wen & hideleg_VSSI;
  assign toHvip_VSSIP_bits = w_wdata[1];
  assign toHvip_LCOFIP_bits = w_wdata[13];
  assign toHvip_LC14IP_valid = w_wen & hvien_LC14IE;
  assign toHvip_LC14IP_bits = w_wdata[14];
  assign toHvip_LC15IP_valid = w_wen & hvien_LC15IE;
  assign toHvip_LC15IP_bits = w_wdata[15];
  assign toHvip_LC16IP_valid = w_wen & hvien_LC16IE;
  assign toHvip_LC16IP_bits = w_wdata[16];
  assign toHvip_LC17IP_valid = w_wen & hvien_LC17IE;
  assign toHvip_LC17IP_bits = w_wdata[17];
  assign toHvip_LC18IP_valid = w_wen & hvien_LC18IE;
  assign toHvip_LC18IP_bits = w_wdata[18];
  assign toHvip_LC19IP_valid = w_wen & hvien_LC19IE;
  assign toHvip_LC19IP_bits = w_wdata[19];
  assign toHvip_LC20IP_valid = w_wen & hvien_LC20IE;
  assign toHvip_LC20IP_bits = w_wdata[20];
  assign toHvip_LC21IP_valid = w_wen & hvien_LC21IE;
  assign toHvip_LC21IP_bits = w_wdata[21];
  assign toHvip_LC22IP_valid = w_wen & hvien_LC22IE;
  assign toHvip_LC22IP_bits = w_wdata[22];
  assign toHvip_LC23IP_valid = w_wen & hvien_LC23IE;
  assign toHvip_LC23IP_bits = w_wdata[23];
  assign toHvip_LC24IP_valid = w_wen & hvien_LC24IE;
  assign toHvip_LC24IP_bits = w_wdata[24];
  assign toHvip_LC25IP_valid = w_wen & hvien_LC25IE;
  assign toHvip_LC25IP_bits = w_wdata[25];
  assign toHvip_LC26IP_valid = w_wen & hvien_LC26IE;
  assign toHvip_LC26IP_bits = w_wdata[26];
  assign toHvip_LC27IP_valid = w_wen & hvien_LC27IE;
  assign toHvip_LC27IP_bits = w_wdata[27];
  assign toHvip_LC28IP_valid = w_wen & hvien_LC28IE;
  assign toHvip_LC28IP_bits = w_wdata[28];
  assign toHvip_LC29IP_valid = w_wen & hvien_LC29IE;
  assign toHvip_LC29IP_bits = w_wdata[29];
  assign toHvip_LC30IP_valid = w_wen & hvien_LC30IE;
  assign toHvip_LC30IP_bits = w_wdata[30];
  assign toHvip_LC31IP_valid = w_wen & hvien_LC31IE;
  assign toHvip_LC31IP_bits = w_wdata[31];
  assign toHvip_LC32IP_valid = w_wen & hvien_LC32IE;
  assign toHvip_LC32IP_bits = w_wdata[32];
  assign toHvip_LC33IP_valid = w_wen & hvien_LC33IE;
  assign toHvip_LC33IP_bits = w_wdata[33];
  assign toHvip_LC34IP_valid = w_wen & hvien_LC34IE;
  assign toHvip_LC34IP_bits = w_wdata[34];
  assign toHvip_LPRASEIP_valid = w_wen & hvien_LPRASEIE;
  assign toHvip_LPRASEIP_bits = w_wdata[35];
  assign toHvip_LC36IP_valid = w_wen & hvien_LC36IE;
  assign toHvip_LC36IP_bits = w_wdata[36];
  assign toHvip_LC37IP_valid = w_wen & hvien_LC37IE;
  assign toHvip_LC37IP_bits = w_wdata[37];
  assign toHvip_LC38IP_valid = w_wen & hvien_LC38IE;
  assign toHvip_LC38IP_bits = w_wdata[38];
  assign toHvip_LC39IP_valid = w_wen & hvien_LC39IE;
  assign toHvip_LC39IP_bits = w_wdata[39];
  assign toHvip_LC40IP_valid = w_wen & hvien_LC40IE;
  assign toHvip_LC40IP_bits = w_wdata[40];
  assign toHvip_LC41IP_valid = w_wen & hvien_LC41IE;
  assign toHvip_LC41IP_bits = w_wdata[41];
  assign toHvip_LC42IP_valid = w_wen & hvien_LC42IE;
  assign toHvip_LC42IP_bits = w_wdata[42];
  assign toHvip_HPRASEIP_valid = w_wen & hvien_HPRASEIE;
  assign toHvip_HPRASEIP_bits = w_wdata[43];
  assign toHvip_LC44IP_valid = w_wen & hvien_LC44IE;
  assign toHvip_LC44IP_bits = w_wdata[44];
  assign toHvip_LC45IP_valid = w_wen & hvien_LC45IE;
  assign toHvip_LC45IP_bits = w_wdata[45];
  assign toHvip_LC46IP_valid = w_wen & hvien_LC46IE;
  assign toHvip_LC46IP_bits = w_wdata[46];
  assign toHvip_LC47IP_valid = w_wen & hvien_LC47IE;
  assign toHvip_LC47IP_bits = w_wdata[47];
  assign toHvip_LC48IP_valid = w_wen & hvien_LC48IE;
  assign toHvip_LC48IP_bits = w_wdata[48];
  assign toHvip_LC49IP_valid = w_wen & hvien_LC49IE;
  assign toHvip_LC49IP_bits = w_wdata[49];
  assign toHvip_LC50IP_valid = w_wen & hvien_LC50IE;
  assign toHvip_LC50IP_bits = w_wdata[50];
  assign toHvip_LC51IP_valid = w_wen & hvien_LC51IE;
  assign toHvip_LC51IP_bits = w_wdata[51];
  assign toHvip_LC52IP_valid = w_wen & hvien_LC52IE;
  assign toHvip_LC52IP_bits = w_wdata[52];
  assign toHvip_LC53IP_valid = w_wen & hvien_LC53IE;
  assign toHvip_LC53IP_bits = w_wdata[53];
  assign toHvip_LC54IP_valid = w_wen & hvien_LC54IE;
  assign toHvip_LC54IP_bits = w_wdata[54];
  assign toHvip_LC55IP_valid = w_wen & hvien_LC55IE;
  assign toHvip_LC55IP_bits = w_wdata[55];
  assign toHvip_LC56IP_valid = w_wen & hvien_LC56IE;
  assign toHvip_LC56IP_bits = w_wdata[56];
  assign toHvip_LC57IP_valid = w_wen & hvien_LC57IE;
  assign toHvip_LC57IP_bits = w_wdata[57];
  assign toHvip_LC58IP_valid = w_wen & hvien_LC58IE;
  assign toHvip_LC58IP_bits = w_wdata[58];
  assign toHvip_LC59IP_valid = w_wen & hvien_LC59IE;
  assign toHvip_LC59IP_bits = w_wdata[59];
  assign toHvip_LC60IP_valid = w_wen & hvien_LC60IE;
  assign toHvip_LC60IP_bits = w_wdata[60];
  assign toHvip_LC61IP_valid = w_wen & hvien_LC61IE;
  assign toHvip_LC61IP_bits = w_wdata[61];
  assign toHvip_LC62IP_valid = w_wen & hvien_LC62IE;
  assign toHvip_LC62IP_bits = w_wdata[62];
  assign toHvip_LC63IP_valid = w_wen & hvien_LC63IE;
  assign toHvip_LC63IP_bits = w_wdata[63];
endmodule
