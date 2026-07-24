// Iprio family UT: golden vs 可读 primitive(_xs 变体)逐拍比对。
// 覆盖 3 种结构形态: (0) 六字段 mie 基态 Iprio0Module; (2_1) 六字段 sie 变态
// Iprio2Module_1; (8) reg_ALL&mask 基态 Iprio8Module(mask=0); (8_1) reg_ALL&mask
// sie 变态 Iprio8Module_1。全宽随机激励(w_wen/w_wdata + 全 mie/sie 使能位)。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
  int unsigned WARMUP  = 8;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic        w_wen;
  logic [63:0] w_wdata;
  logic [10:0] mie;   // 11 个 mie 使能位(顺序见下)
  logic [53:0] sie;   // 54 个 sie 使能位(顺序见下)

  // mie 位序: {SSIE,VSSIE,MSIE,STIE,VSTIE,MTIE,SEIE,VSEIE,MEIE,SGEIE,LCOFIE}
  wire mie_SSIE=mie[0], mie_VSSIE=mie[1], mie_MSIE=mie[2], mie_STIE=mie[3],
       mie_VSTIE=mie[4], mie_MTIE=mie[5], mie_SEIE=mie[6], mie_VSEIE=mie[7],
       mie_MEIE=mie[8], mie_SGEIE=mie[9], mie_LCOFIE=mie[10];

  // sie 位序(与 golden 端口声明顺序一致)
  wire sie_SSIE=sie[0], sie_STIE=sie[1], sie_SEIE=sie[2], sie_LCOFIE=sie[3],
       sie_LC14IE=sie[4], sie_LC15IE=sie[5], sie_LC16IE=sie[6], sie_LC17IE=sie[7],
       sie_LC18IE=sie[8], sie_LC19IE=sie[9], sie_LC20IE=sie[10], sie_LC21IE=sie[11],
       sie_LC22IE=sie[12], sie_LC23IE=sie[13], sie_LC24IE=sie[14], sie_LC25IE=sie[15],
       sie_LC26IE=sie[16], sie_LC27IE=sie[17], sie_LC28IE=sie[18], sie_LC29IE=sie[19],
       sie_LC30IE=sie[20], sie_LC31IE=sie[21], sie_LC32IE=sie[22], sie_LC33IE=sie[23],
       sie_LC34IE=sie[24], sie_LPRASEIE=sie[25], sie_LC36IE=sie[26], sie_LC37IE=sie[27],
       sie_LC38IE=sie[28], sie_LC39IE=sie[29], sie_LC40IE=sie[30], sie_LC41IE=sie[31],
       sie_LC42IE=sie[32], sie_HPRASEIE=sie[33], sie_LC44IE=sie[34], sie_LC45IE=sie[35],
       sie_LC46IE=sie[36], sie_LC47IE=sie[37], sie_LC48IE=sie[38], sie_LC49IE=sie[39],
       sie_LC50IE=sie[40], sie_LC51IE=sie[41], sie_LC52IE=sie[42], sie_LC53IE=sie[43],
       sie_LC54IE=sie[44], sie_LC55IE=sie[45], sie_LC56IE=sie[46], sie_LC57IE=sie[47],
       sie_LC58IE=sie[48], sie_LC59IE=sie[49], sie_LC60IE=sie[50], sie_LC61IE=sie[51],
       sie_LC62IE=sie[52], sie_LC63IE=sie[53];

  logic [63:0] g0, i0, g2, i2, g8, i8, g81, i81;

  // (0) Iprio0Module: 六字段 mie 基态
  Iprio0Module u_g0(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),.rdata(g0),
    .mie_SSIE(mie_SSIE),.mie_VSSIE(mie_VSSIE),.mie_MSIE(mie_MSIE),.mie_STIE(mie_STIE),
    .mie_VSTIE(mie_VSTIE),.mie_MTIE(mie_MTIE),.mie_SEIE(mie_SEIE),.mie_VSEIE(mie_VSEIE),
    .mie_MEIE(mie_MEIE),.mie_SGEIE(mie_SGEIE),.mie_LCOFIE(mie_LCOFIE));
  Iprio0Module_xs u_i0(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),.rdata(i0),
    .mie_SSIE(mie_SSIE),.mie_VSSIE(mie_VSSIE),.mie_MSIE(mie_MSIE),.mie_STIE(mie_STIE),
    .mie_VSTIE(mie_VSTIE),.mie_MTIE(mie_MTIE),.mie_SEIE(mie_SEIE),.mie_VSEIE(mie_VSEIE),
    .mie_MEIE(mie_MEIE),.mie_SGEIE(mie_SGEIE),.mie_LCOFIE(mie_LCOFIE));

  // (8) Iprio8Module: reg_ALL&mask 基态(mask=0)
  Iprio8Module u_g8(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),.rdata(g8),
    .mie_SSIE(mie_SSIE),.mie_VSSIE(mie_VSSIE),.mie_MSIE(mie_MSIE),.mie_STIE(mie_STIE),
    .mie_VSTIE(mie_VSTIE),.mie_MTIE(mie_MTIE),.mie_SEIE(mie_SEIE),.mie_VSEIE(mie_VSEIE),
    .mie_MEIE(mie_MEIE),.mie_SGEIE(mie_SGEIE),.mie_LCOFIE(mie_LCOFIE));
  Iprio8Module_xs u_i8(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),.rdata(i8),
    .mie_SSIE(mie_SSIE),.mie_VSSIE(mie_VSSIE),.mie_MSIE(mie_MSIE),.mie_STIE(mie_STIE),
    .mie_VSTIE(mie_VSTIE),.mie_MTIE(mie_MTIE),.mie_SEIE(mie_SEIE),.mie_VSEIE(mie_VSEIE),
    .mie_MEIE(mie_MEIE),.mie_SGEIE(mie_SGEIE),.mie_LCOFIE(mie_LCOFIE));

  // sie 端口连接宏(两个 _1 变态共用)
  `define SIE_CONN \
    .sie_SSIE(sie_SSIE),.sie_STIE(sie_STIE),.sie_SEIE(sie_SEIE),.sie_LCOFIE(sie_LCOFIE), \
    .sie_LC14IE(sie_LC14IE),.sie_LC15IE(sie_LC15IE),.sie_LC16IE(sie_LC16IE),.sie_LC17IE(sie_LC17IE), \
    .sie_LC18IE(sie_LC18IE),.sie_LC19IE(sie_LC19IE),.sie_LC20IE(sie_LC20IE),.sie_LC21IE(sie_LC21IE), \
    .sie_LC22IE(sie_LC22IE),.sie_LC23IE(sie_LC23IE),.sie_LC24IE(sie_LC24IE),.sie_LC25IE(sie_LC25IE), \
    .sie_LC26IE(sie_LC26IE),.sie_LC27IE(sie_LC27IE),.sie_LC28IE(sie_LC28IE),.sie_LC29IE(sie_LC29IE), \
    .sie_LC30IE(sie_LC30IE),.sie_LC31IE(sie_LC31IE),.sie_LC32IE(sie_LC32IE),.sie_LC33IE(sie_LC33IE), \
    .sie_LC34IE(sie_LC34IE),.sie_LPRASEIE(sie_LPRASEIE),.sie_LC36IE(sie_LC36IE),.sie_LC37IE(sie_LC37IE), \
    .sie_LC38IE(sie_LC38IE),.sie_LC39IE(sie_LC39IE),.sie_LC40IE(sie_LC40IE),.sie_LC41IE(sie_LC41IE), \
    .sie_LC42IE(sie_LC42IE),.sie_HPRASEIE(sie_HPRASEIE),.sie_LC44IE(sie_LC44IE),.sie_LC45IE(sie_LC45IE), \
    .sie_LC46IE(sie_LC46IE),.sie_LC47IE(sie_LC47IE),.sie_LC48IE(sie_LC48IE),.sie_LC49IE(sie_LC49IE), \
    .sie_LC50IE(sie_LC50IE),.sie_LC51IE(sie_LC51IE),.sie_LC52IE(sie_LC52IE),.sie_LC53IE(sie_LC53IE), \
    .sie_LC54IE(sie_LC54IE),.sie_LC55IE(sie_LC55IE),.sie_LC56IE(sie_LC56IE),.sie_LC57IE(sie_LC57IE), \
    .sie_LC58IE(sie_LC58IE),.sie_LC59IE(sie_LC59IE),.sie_LC60IE(sie_LC60IE),.sie_LC61IE(sie_LC61IE), \
    .sie_LC62IE(sie_LC62IE),.sie_LC63IE(sie_LC63IE)

  // (2_1) Iprio2Module_1: 六字段 sie 变态
  Iprio2Module_1    u_g2(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),.rdata(g2),`SIE_CONN);
  Iprio2Module_1_xs u_i2(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),.rdata(i2),`SIE_CONN);

  // (8_1) Iprio8Module_1: reg_ALL&mask sie 变态
  Iprio8Module_1    u_g81(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),.rdata(g81),`SIE_CONN);
  Iprio8Module_1_xs u_i81(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),.rdata(i81),`SIE_CONN);

  always @(negedge clk) begin
    if (rst) begin
      w_wen <= '0; w_wdata <= '0; mie <= '0; sie <= '0;
    end else begin
      w_wen   <= ($urandom_range(0,1)==0);
      w_wdata <= {$urandom, $urandom};
      mie     <= {$urandom} [10:0];
      sie     <= {$urandom, $urandom} [53:0];
    end
  end

  always @(negedge clk) if (!rst) begin
    cyc++;
    if (cyc > WARMUP) begin
      #4; checks++;
      if (g0!==i0 || g2!==i2 || g8!==i8 || g81!==i81) begin
        errors++;
        if (errors<=30) $display("[%0t] 0:g=%h i=%h 2_1:g=%h i=%h 8:g=%h i=%h 8_1:g=%h i=%h",
                                 $time, g0,i0, g2,i2, g8,i8, g81,i81);
      end
    end
  end

  initial begin
    rst = 1; repeat (5) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
