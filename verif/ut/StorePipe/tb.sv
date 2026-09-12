// 自动生成：scripts/gen_storepipe.py —— 勿手改
`timescale 1ns/1ps
module tb;
  localparam int N_WAYS = 4;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  // ===== (1) golden StorePipe vs StorePipe_xs 直通比对(FM 对照) =====
  logic gp_valid;
  wire  g_probe, i_probe;
  // golden/impl 顶层都无输出端口；用层次探针比对内部 probe wire。
  StorePipe    u_g (.io_lsu_req_valid(gp_valid));
  StorePipe_xs u_i (.io_lsu_req_valid(gp_valid));

  // ===== (2) 完整可读核 xs_StorePipe_core 的行为参考模型自检 =====
  // ---- core 输入 ----
  logic        c_req_valid;
  logic [4:0]  c_req_cmd;
  logic [49:0] c_req_vaddr;
  logic [3:0]  c_req_instrtype;
  logic [47:0] c_s1_paddr;
  logic        c_s1_kill, c_s2_kill;
  logic [49:0] c_s2_pc;
  logic        c_meta_read_ready, c_tag_read_ready, c_miss_req_ready;
  logic [1:0]  c_meta_coh [N_WAYS];
  logic [42:0] c_tag_resp [N_WAYS];
  // ---- core 输出 ----
  wire         o_req_ready, o_meta_rd_valid, o_tag_rd_valid;
  wire [7:0]   o_meta_idx, o_tag_idx;
  wire         o_resp_valid, o_resp_miss, o_resp_replay, o_resp_tag_error;
  wire         o_miss_valid, o_miss_cancel;
  wire [4:0]   o_miss_cmd;
  wire [47:0]  o_miss_addr;
  wire [49:0]  o_miss_vaddr;
  wire [1:0]   o_miss_coh;


  // ---- 覆盖闸（防假绿）----------------------------------------------
  // errors=0 本身不是证据：激励若让 DUT 根本不动（握手永远握不上、状态机卡死），
  // 纯比对 tb 会给出一个漂亮的 0。所以另外统计"观测信号翻转过几个"与"握手成功
  // 几拍"，低于门限判 FAIL。门限取自标定跑（真实数字打折），不是自我实现。
  localparam int unsigned MIN_TOGGLED = 15;
  localparam int unsigned MIN_FIRES   = 40000;
  localparam int unsigned N_OBS       = 15;
  int     cov_toggled = 0;
  longint cov_fires = 0;
  logic p_o_req_ready;
  bit tog_o_req_ready;
  logic p_o_meta_rd_valid;
  bit tog_o_meta_rd_valid;
  logic p_o_tag_rd_valid;
  bit tog_o_tag_rd_valid;
  logic [7:0] p_o_meta_idx;
  bit tog_o_meta_idx;
  logic [7:0] p_o_tag_idx;
  bit tog_o_tag_idx;
  logic p_o_resp_valid;
  bit tog_o_resp_valid;
  logic p_o_resp_miss;
  bit tog_o_resp_miss;
  logic p_o_resp_replay;
  bit tog_o_resp_replay;
  logic p_o_resp_tag_error;
  bit tog_o_resp_tag_error;
  logic p_o_miss_valid;
  bit tog_o_miss_valid;
  logic p_o_miss_cancel;
  bit tog_o_miss_cancel;
  logic [4:0] p_o_miss_cmd;
  bit tog_o_miss_cmd;
  logic [47:0] p_o_miss_addr;
  bit tog_o_miss_addr;
  logic [49:0] p_o_miss_vaddr;
  bit tog_o_miss_vaddr;
  logic [1:0] p_o_miss_coh;
  bit tog_o_miss_coh;
  task automatic sample_cov();
    if (o_req_ready !== p_o_req_ready) tog_o_req_ready = 1'b1;
    p_o_req_ready = o_req_ready;
    if (o_meta_rd_valid !== p_o_meta_rd_valid) tog_o_meta_rd_valid = 1'b1;
    p_o_meta_rd_valid = o_meta_rd_valid;
    if (o_tag_rd_valid !== p_o_tag_rd_valid) tog_o_tag_rd_valid = 1'b1;
    p_o_tag_rd_valid = o_tag_rd_valid;
    if (o_meta_idx !== p_o_meta_idx) tog_o_meta_idx = 1'b1;
    p_o_meta_idx = o_meta_idx;
    if (o_tag_idx !== p_o_tag_idx) tog_o_tag_idx = 1'b1;
    p_o_tag_idx = o_tag_idx;
    if (o_resp_valid !== p_o_resp_valid) tog_o_resp_valid = 1'b1;
    p_o_resp_valid = o_resp_valid;
    if (o_resp_miss !== p_o_resp_miss) tog_o_resp_miss = 1'b1;
    p_o_resp_miss = o_resp_miss;
    if (o_resp_replay !== p_o_resp_replay) tog_o_resp_replay = 1'b1;
    p_o_resp_replay = o_resp_replay;
    if (o_resp_tag_error !== p_o_resp_tag_error) tog_o_resp_tag_error = 1'b1;
    p_o_resp_tag_error = o_resp_tag_error;
    if (o_miss_valid !== p_o_miss_valid) tog_o_miss_valid = 1'b1;
    p_o_miss_valid = o_miss_valid;
    if (o_miss_cancel !== p_o_miss_cancel) tog_o_miss_cancel = 1'b1;
    p_o_miss_cancel = o_miss_cancel;
    if (o_miss_cmd !== p_o_miss_cmd) tog_o_miss_cmd = 1'b1;
    p_o_miss_cmd = o_miss_cmd;
    if (o_miss_addr !== p_o_miss_addr) tog_o_miss_addr = 1'b1;
    p_o_miss_addr = o_miss_addr;
    if (o_miss_vaddr !== p_o_miss_vaddr) tog_o_miss_vaddr = 1'b1;
    p_o_miss_vaddr = o_miss_vaddr;
    if (o_miss_coh !== p_o_miss_coh) tog_o_miss_coh = 1'b1;
    p_o_miss_coh = o_miss_coh;
    if ((c_req_valid && o_req_ready)) cov_fires++;
  endtask
  task automatic cov_report_and_gate();
    if (tog_o_req_ready) cov_toggled++; else $display("COV: o_req_ready never toggled");
    if (tog_o_meta_rd_valid) cov_toggled++; else $display("COV: o_meta_rd_valid never toggled");
    if (tog_o_tag_rd_valid) cov_toggled++; else $display("COV: o_tag_rd_valid never toggled");
    if (tog_o_meta_idx) cov_toggled++; else $display("COV: o_meta_idx never toggled");
    if (tog_o_tag_idx) cov_toggled++; else $display("COV: o_tag_idx never toggled");
    if (tog_o_resp_valid) cov_toggled++; else $display("COV: o_resp_valid never toggled");
    if (tog_o_resp_miss) cov_toggled++; else $display("COV: o_resp_miss never toggled");
    if (tog_o_resp_replay) cov_toggled++; else $display("COV: o_resp_replay never toggled");
    if (tog_o_resp_tag_error) cov_toggled++; else $display("COV: o_resp_tag_error never toggled");
    if (tog_o_miss_valid) cov_toggled++; else $display("COV: o_miss_valid never toggled");
    if (tog_o_miss_cancel) cov_toggled++; else $display("COV: o_miss_cancel never toggled");
    if (tog_o_miss_cmd) cov_toggled++; else $display("COV: o_miss_cmd never toggled");
    if (tog_o_miss_addr) cov_toggled++; else $display("COV: o_miss_addr never toggled");
    if (tog_o_miss_vaddr) cov_toggled++; else $display("COV: o_miss_vaddr never toggled");
    if (tog_o_miss_coh) cov_toggled++; else $display("COV: o_miss_coh never toggled");
    $display("COV StorePipe: toggled=%0d/%0d fires=%0d", cov_toggled, N_OBS, cov_fires);
    if (cov_toggled < MIN_TOGGLED) begin
      $display("TEST FAILED (coverage: only %0d observed signals toggled, need >= %0d)", cov_toggled, MIN_TOGGLED); $fatal(1);
    end
    if (cov_fires < MIN_FIRES) begin
      $display("TEST FAILED (coverage: only %0d handshake fires, need >= %0d)", cov_fires, MIN_FIRES); $fatal(1);
    end
  endtask
  xs_StorePipe_core #(.EN_STORE_PF_AT_ISSUE(1'b0)) u_core (
    .clock(clk), .reset(rst),
    .io_lsu_req_valid(c_req_valid),
    .io_lsu_req_bits_cmd(c_req_cmd),
    .io_lsu_req_bits_vaddr(c_req_vaddr),
    .io_lsu_req_bits_instrtype(c_req_instrtype),
    .io_lsu_req_ready(o_req_ready),
    .io_lsu_s1_paddr(c_s1_paddr),
    .io_lsu_s1_kill(c_s1_kill),
    .io_lsu_s2_kill(c_s2_kill),
    .io_lsu_s2_pc(c_s2_pc),
    .io_lsu_resp_valid(o_resp_valid),
    .io_lsu_resp_bits_miss(o_resp_miss),
    .io_lsu_resp_bits_replay(o_resp_replay),
    .io_lsu_resp_bits_tag_error(o_resp_tag_error),
    .io_meta_read_ready(c_meta_read_ready),
    .io_meta_read_valid(o_meta_rd_valid),
    .io_meta_read_bits_idx(o_meta_idx),
    .io_meta_resp_coh_state(c_meta_coh),
    .io_tag_read_ready(c_tag_read_ready),
    .io_tag_read_valid(o_tag_rd_valid),
    .io_tag_read_bits_idx(o_tag_idx),
    .io_tag_resp(c_tag_resp),
    .io_miss_req_ready(c_miss_req_ready),
    .io_miss_req_valid(o_miss_valid),
    .io_miss_req_bits_cmd(o_miss_cmd),
    .io_miss_req_bits_addr(o_miss_addr),
    .io_miss_req_bits_vaddr(o_miss_vaddr),
    .io_miss_req_bits_req_coh_state(o_miss_coh),
    .io_miss_req_bits_cancel(o_miss_cancel)
  );

  // ---- 行为参考模型(StorePipe.scala 三级流水的独立重述) ----
  // onAccess(store)：有权限 = coh in {Trunk(2),Dirty(3)}；new_coh = Dirty?Dirty:Trunk
  function automatic logic ref_has_perm(input logic [1:0] coh);
    ref_has_perm = (coh==2'h2) || (coh==2'h3);
  endfunction
  function automatic logic [1:0] ref_new_coh(input logic [1:0] coh);
    ref_new_coh = (coh==2'h3) ? 2'h3 : 2'h2;
  endfunction

  // s0 fire
  wire        r_req_ready = c_meta_read_ready & c_tag_read_ready;
  wire        r_s0_fire   = c_req_valid & r_req_ready;
  // s1 寄存
  logic        r_s1_valid;
  logic [4:0]  r_s1_cmd;
  logic [49:0] r_s1_vaddr;
  logic [3:0]  r_s1_instrtype;
  // s1 命中(组合，用当拍 s1_paddr/meta/tag)
  logic [N_WAYS-1:0] r_match;
  logic [1:0]  r_hit_coh;
  always_comb begin
    r_hit_coh = 2'h0;
    for (int k=0;k<N_WAYS;k++) begin
      r_match[k] = (c_tag_resp[k][35:0]==c_s1_paddr[47:12]) & (|c_meta_coh[k]);
      if (r_match[k]) r_hit_coh = r_hit_coh | c_meta_coh[k];
    end
  end
  wire r_s1_hit = ref_has_perm(r_hit_coh) & (ref_new_coh(r_hit_coh)==r_hit_coh) & (|r_match);
  // s2 寄存
  logic        r_s2_valid;
  logic [4:0]  r_s2_cmd;
  logic [49:0] r_s2_vaddr;
  logic        r_s2_hit;
  logic [47:0] r_s2_paddr;
  logic [1:0]  r_s2_hit_coh;
  logic        r_s2_is_pf;

  always @(posedge clk or posedge rst) begin
    if (rst) begin r_s1_valid<=0; r_s2_valid<=0; end
    else begin
      r_s1_valid <= r_s0_fire;
      r_s2_valid <= r_s1_valid & ~c_s1_kill;
    end
  end
  always @(posedge clk) begin
    if (r_s0_fire) begin
      r_s1_cmd<=c_req_cmd; r_s1_vaddr<=c_req_vaddr; r_s1_instrtype<=c_req_instrtype;
    end
    if (r_s1_valid) begin
      r_s2_cmd<=r_s1_cmd; r_s2_vaddr<=r_s1_vaddr; r_s2_hit<=r_s1_hit;
      r_s2_paddr<=c_s1_paddr; r_s2_hit_coh<=r_hit_coh; r_s2_is_pf<=(r_s1_instrtype==4'h3);
    end
  end
  // 参考输出
  wire        rf_resp_valid = r_s2_valid;
  wire        rf_resp_miss  = ~r_s2_hit;
  wire        rf_miss_valid = r_s2_valid & ~r_s2_hit & r_s2_is_pf; // EN_PF_AT_ISSUE=0
  wire [47:0] rf_miss_addr  = {r_s2_paddr[47:6],6'h0};
  wire [1:0]  rf_miss_coh   = r_s2_hit_coh;

  // ---- 随机激励 ----
  always @(negedge clk) begin
    if (rst) begin gp_valid<=0; c_req_valid<=0; end
    else begin
      gp_valid        <= $urandom_range(0,1);
      c_req_valid     <= ($urandom_range(0,4)!=0);
      c_req_cmd       <= 5'($urandom_range(0,15));
      // 覆盖补洞：原 tb 漏驱 vaddr，meta/tag 组索引与 miss_vaddr 恒 0 从不翻转。
      c_req_vaddr     <= 50'($urandom);
      c_req_instrtype <= 4'($urandom_range(0,3));
      // paddr tag 区压窄(低 2 位)以提高 4 路命中概率
      c_s1_paddr      <= {34'h0, 2'($urandom_range(0,3)), 12'($urandom)};
      c_s1_kill       <= ($urandom_range(0,7)==0);
      c_s2_kill       <= ($urandom_range(0,7)==0);
      c_s2_pc         <= 50'($urandom);
      c_meta_read_ready <= ($urandom_range(0,4)!=0);
      c_tag_read_ready  <= ($urandom_range(0,4)!=0);
      c_miss_req_ready  <= ($urandom_range(0,4)!=0);
      for (int k=0;k<N_WAYS;k++) begin
        c_meta_coh[k] <= 2'($urandom_range(0,3));
        c_tag_resp[k] <= {7'($urandom), 34'h0, 2'($urandom_range(0,3))};
      end
    end
  end

  // ---- 比对 ----
  always @(negedge clk) if (!rst) begin
    #4; checks++;
    sample_cov();
    // (1) passthrough 直通
    if (u_g.io_lsu_req_valid_probe !== u_i.io_lsu_req_valid_probe) begin errors++;
      if(errors<=60) $display("[%0t] probe g=%b i=%b", $time, u_g.io_lsu_req_valid_probe, u_i.io_lsu_req_valid_probe); end
    // (2) core vs 参考模型
    if (o_resp_valid     !== rf_resp_valid) begin errors++; if(errors<=60) $display("[%0t] resp_valid c=%b r=%b",$time,o_resp_valid,rf_resp_valid); end
    if (rf_resp_valid && o_resp_miss !== rf_resp_miss) begin errors++; if(errors<=60) $display("[%0t] resp_miss c=%b r=%b",$time,o_resp_miss,rf_resp_miss); end
    if (o_miss_valid     !== rf_miss_valid) begin errors++; if(errors<=60) $display("[%0t] miss_valid c=%b r=%b",$time,o_miss_valid,rf_miss_valid); end
    if (rf_miss_valid && o_miss_addr !== rf_miss_addr) begin errors++; if(errors<=60) $display("[%0t] miss_addr c=%h r=%h",$time,o_miss_addr,rf_miss_addr); end
    if (rf_miss_valid && o_miss_coh  !== rf_miss_coh)  begin errors++; if(errors<=60) $display("[%0t] miss_coh c=%h r=%h",$time,o_miss_coh,rf_miss_coh); end
  end

  initial begin
    // 全工程统一拍数开关（ut_common.mk 下发 +ncycles=<n>）
    void'($value$plusargs("ncycles=%d", NCYCLES));
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    cov_report_and_gate();
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED");
    else begin $display("TEST FAILED"); $fatal(1); end
    $finish;
  end
endmodule
