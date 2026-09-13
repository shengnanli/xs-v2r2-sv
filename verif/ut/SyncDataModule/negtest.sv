// 负测台：证明 xs_SyncDataModule 的分 bank 不变式**真的**会在 elaborate 期拦下。
//
// 对照原型 = SyncDataModuleTemplate__64entry（golden 里例化 4 个 DataModule__16entry
// 子模块 => G1_NUM_BANKS=4）。三个负例：
//   +define+NEG_SDM_ENTRIES    NUM_ENTRIES 64→128 —— 条目数抄错。128 会跨过
//        MAX_BANK_ENTRIES 的 64/16 跳变门槛, 只分出 2 个 bank；逻辑一行不改, UT 也
//        未必打得到边界。期望命中「分出 2 个 bank, 但 golden 里是 4 个」。
//   +define+NEG_SDM_NO_ANCHOR  不传 G1_NUM_BANKS —— 期望命中 fail-closed 那条。
//   +define+NEG_SDM_ODD        NUM_ENTRIES=48 —— 分 3 个 bank, 但 bank 下标有 2 位
//        (能表示 4 个)。期望命中「bank_index() 会越界」这条纯派生算术自检
//        （它不依赖 G1 锚点, 挡的是 bank_rdata[] 静默越界）。
//
// 判据：三个都必须让 VCS 在 elaborate 期非零退出（Error-[FEST]）。
module neg_sdm_probe;
`ifdef NEG_SDM_ENTRIES
  localparam int unsigned N = 128;   // <-- 抄错：golden 是 64 项 / 4 bank
`elsif NEG_SDM_ODD
  localparam int unsigned N = 48;    // <-- 3 个 bank, 但下标 2 位能表示 4 个
`else
  localparam int unsigned N = 64;
`endif
  localparam int unsigned NR = 3, NW = 1, DW = 86;
  localparam int unsigned AW = $clog2(N);

  logic clock = 1'b0, reset = 1'b0;
  logic [NR-1:0]           ren   = '0;
  logic [NR-1:0][AW-1:0]   raddr = '0;
  logic [NR-1:0][DW-1:0]   rdata;
  logic [NW-1:0]           wen   = '0;
  logic [NW-1:0][AW-1:0]   waddr = '0;
  logic [NW-1:0][DW-1:0]   wdata = '0;

  xs_SyncDataModule #(
    .NUM_ENTRIES(N), .NUM_READ(NR), .NUM_WRITE(NW), .DATA_WIDTH(DW),
    .HAS_REN(1), .BYPASS_EN(3'b111)
`ifndef NEG_SDM_NO_ANCHOR
    , .G1_NUM_BANKS(4)
`endif
  ) u_core (
    .clock(clock), .reset(reset),
    .io_ren(ren), .io_raddr(raddr), .io_rdata(rdata),
    .io_wen(wen), .io_waddr(waddr), .io_wdata(wdata)
  );

  initial begin
    $display("NEGTEST_UNREACHED: 分 bank 参数抄错没有被 elaborate 期不变式拦下");
    $finish;
  end
endmodule
