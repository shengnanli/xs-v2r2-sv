// FTBBank UT：golden FTBBank vs 可读 FTBBank_xs（均内部例化 golden SplittedSRAMTemplate_2）。
//
// 比对所有功能输出，逐拍：
//   - req_pc.ready
//   - read_resp（命中条目，全字段）、read_hits.{valid,bits}
//   - read_multi_entry（multi-hit 兜底条目）、read_multi_hits.{valid,bits}
//   - update_hits.{valid,bits}
//
// 激励要点：
//   - 单端口约束：io_req_pc_valid 与 io_u_req_pc_valid 绝不同拍有效（golden 有断言）。
//   - 三类访问（预测读 / 更新读 / 更新写）随机交错，覆盖 tag 命中、未命中、
//     替换路分配、multi-hit、HoldUnless 保持等路径。
//   - set 索引/tag 用窄范围 PC，提高同组 tag 命中与多路命中的概率。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
  int unsigned WARMUP  = 600;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  int unsigned cycle = 0;
  always #5 clk = ~clk;
  always @(posedge clk) cycle++;

  // ---- 驱动信号 ----
  logic        s1_fire;
  logic        req_valid;   logic [49:0] req_pc;
  logic        u_req_valid; logic [49:0] u_req_pc;
  logic        update_access;
  logic [49:0] update_pc;
  logic        uw_valid;
  logic        uw_isCall, uw_isRet, uw_isJalr, uw_evalid;
  logic [3:0]  uw_broff;  logic uw_brsh, uw_brv; logic [11:0] uw_brlo; logic [1:0] uw_brts;
  logic [3:0]  uw_tloff;  logic uw_tlsh, uw_tlv; logic [19:0] uw_tllo; logic [1:0] uw_tlts;
  logic [3:0]  uw_pft;    logic uw_carry, uw_lastrvi, uw_sb0, uw_sb1; logic [19:0] uw_tag;
  logic [1:0]  uw_way;    logic uw_alloc;

  // ---- 输出（g_ = golden, i_ = xs）----
  wire g_ready, i_ready;
  wire g_rh_v, i_rh_v;  wire [1:0] g_rh_b, i_rh_b;
  wire g_mh_v, i_mh_v;  wire [1:0] g_mh_b, i_mh_b;
  wire g_uh_v, i_uh_v;  wire [1:0] g_uh_b, i_uh_b;
  // read_resp 聚合
  wire g_rr_isCall,g_rr_isRet,g_rr_isJalr,g_rr_valid; wire [3:0] g_rr_broff; wire g_rr_brsh,g_rr_brv;
  wire [11:0] g_rr_brlo; wire [1:0] g_rr_brts; wire [3:0] g_rr_tloff; wire g_rr_tlsh,g_rr_tlv;
  wire [19:0] g_rr_tllo; wire [1:0] g_rr_tlts; wire [3:0] g_rr_pft; wire g_rr_carry,g_rr_lastrvi,g_rr_sb0,g_rr_sb1;
  wire i_rr_isCall,i_rr_isRet,i_rr_isJalr,i_rr_valid; wire [3:0] i_rr_broff; wire i_rr_brsh,i_rr_brv;
  wire [11:0] i_rr_brlo; wire [1:0] i_rr_brts; wire [3:0] i_rr_tloff; wire i_rr_tlsh,i_rr_tlv;
  wire [19:0] i_rr_tllo; wire [1:0] i_rr_tlts; wire [3:0] i_rr_pft; wire i_rr_carry,i_rr_lastrvi,i_rr_sb0,i_rr_sb1;
  // read_multi_entry 聚合
  wire g_me_isCall,g_me_isRet,g_me_isJalr,g_me_valid; wire [3:0] g_me_broff; wire g_me_brsh,g_me_brv;
  wire [11:0] g_me_brlo; wire [1:0] g_me_brts; wire [3:0] g_me_tloff; wire g_me_tlsh,g_me_tlv;
  wire [19:0] g_me_tllo; wire [1:0] g_me_tlts; wire [3:0] g_me_pft; wire g_me_carry,g_me_lastrvi,g_me_sb0,g_me_sb1;
  wire i_me_isCall,i_me_isRet,i_me_isJalr,i_me_valid; wire [3:0] i_me_broff; wire i_me_brsh,i_me_brv;
  wire [11:0] i_me_brlo; wire [1:0] i_me_brts; wire [3:0] i_me_tloff; wire i_me_tlsh,i_me_tlv;
  wire [19:0] i_me_tllo; wire [1:0] i_me_tlts; wire [3:0] i_me_pft; wire i_me_carry,i_me_lastrvi,i_me_sb0,i_me_sb1;

  // 模块级 bore 端口 tie-off 宏（MbistPipe 形态）+ sigFromSrams 8 套
  `define BORETOP \
    .boreChildrenBd_bore_array(6'h0), .boreChildrenBd_bore_all(1'b0), \
    .boreChildrenBd_bore_req(1'b0), .boreChildrenBd_bore_ack(), \
    .boreChildrenBd_bore_writeen(1'b0), .boreChildrenBd_bore_be(4'h0), \
    .boreChildrenBd_bore_addr(10'h0), .boreChildrenBd_bore_indata(40'h0), \
    .boreChildrenBd_bore_readen(1'b0), .boreChildrenBd_bore_addr_rd(10'h0), \
    .boreChildrenBd_bore_outdata()
  `define SIG(N) \
    .sigFromSrams_bore``N``_ram_hold(1'b0), .sigFromSrams_bore``N``_ram_bypass(1'b0), \
    .sigFromSrams_bore``N``_ram_bp_clken(1'b0), .sigFromSrams_bore``N``_ram_aux_clk(1'b0), \
    .sigFromSrams_bore``N``_ram_aux_ckbp(1'b0), .sigFromSrams_bore``N``_ram_mcp_hold(1'b0), \
    .sigFromSrams_bore``N``_cgen(1'b0)

  `define UWDATA \
    .io_update_write_data_valid(uw_valid), \
    .io_update_write_data_bits_entry_isCall(uw_isCall), \
    .io_update_write_data_bits_entry_isRet(uw_isRet), \
    .io_update_write_data_bits_entry_isJalr(uw_isJalr), \
    .io_update_write_data_bits_entry_valid(uw_evalid), \
    .io_update_write_data_bits_entry_brSlots_0_offset(uw_broff), \
    .io_update_write_data_bits_entry_brSlots_0_sharing(uw_brsh), \
    .io_update_write_data_bits_entry_brSlots_0_valid(uw_brv), \
    .io_update_write_data_bits_entry_brSlots_0_lower(uw_brlo), \
    .io_update_write_data_bits_entry_brSlots_0_tarStat(uw_brts), \
    .io_update_write_data_bits_entry_tailSlot_offset(uw_tloff), \
    .io_update_write_data_bits_entry_tailSlot_sharing(uw_tlsh), \
    .io_update_write_data_bits_entry_tailSlot_valid(uw_tlv), \
    .io_update_write_data_bits_entry_tailSlot_lower(uw_tllo), \
    .io_update_write_data_bits_entry_tailSlot_tarStat(uw_tlts), \
    .io_update_write_data_bits_entry_pftAddr(uw_pft), \
    .io_update_write_data_bits_entry_carry(uw_carry), \
    .io_update_write_data_bits_entry_last_may_be_rvi_call(uw_lastrvi), \
    .io_update_write_data_bits_entry_strong_bias_0(uw_sb0), \
    .io_update_write_data_bits_entry_strong_bias_1(uw_sb1), \
    .io_update_write_data_bits_tag(uw_tag), \
    .io_update_write_way(uw_way), .io_update_write_alloc(uw_alloc)

  `define RR(P) \
    .io_read_resp_isCall(P``rr_isCall), .io_read_resp_isRet(P``rr_isRet), \
    .io_read_resp_isJalr(P``rr_isJalr), .io_read_resp_valid(P``rr_valid), \
    .io_read_resp_brSlots_0_offset(P``rr_broff), .io_read_resp_brSlots_0_sharing(P``rr_brsh), \
    .io_read_resp_brSlots_0_valid(P``rr_brv), .io_read_resp_brSlots_0_lower(P``rr_brlo), \
    .io_read_resp_brSlots_0_tarStat(P``rr_brts), .io_read_resp_tailSlot_offset(P``rr_tloff), \
    .io_read_resp_tailSlot_sharing(P``rr_tlsh), .io_read_resp_tailSlot_valid(P``rr_tlv), \
    .io_read_resp_tailSlot_lower(P``rr_tllo), .io_read_resp_tailSlot_tarStat(P``rr_tlts), \
    .io_read_resp_pftAddr(P``rr_pft), .io_read_resp_carry(P``rr_carry), \
    .io_read_resp_last_may_be_rvi_call(P``rr_lastrvi), \
    .io_read_resp_strong_bias_0(P``rr_sb0), .io_read_resp_strong_bias_1(P``rr_sb1)
  `define ME(P) \
    .io_read_multi_entry_isCall(P``me_isCall), .io_read_multi_entry_isRet(P``me_isRet), \
    .io_read_multi_entry_isJalr(P``me_isJalr), .io_read_multi_entry_valid(P``me_valid), \
    .io_read_multi_entry_brSlots_0_offset(P``me_broff), .io_read_multi_entry_brSlots_0_sharing(P``me_brsh), \
    .io_read_multi_entry_brSlots_0_valid(P``me_brv), .io_read_multi_entry_brSlots_0_lower(P``me_brlo), \
    .io_read_multi_entry_brSlots_0_tarStat(P``me_brts), .io_read_multi_entry_tailSlot_offset(P``me_tloff), \
    .io_read_multi_entry_tailSlot_sharing(P``me_tlsh), .io_read_multi_entry_tailSlot_valid(P``me_tlv), \
    .io_read_multi_entry_tailSlot_lower(P``me_tllo), .io_read_multi_entry_tailSlot_tarStat(P``me_tlts), \
    .io_read_multi_entry_pftAddr(P``me_pft), .io_read_multi_entry_carry(P``me_carry), \
    .io_read_multi_entry_last_may_be_rvi_call(P``me_lastrvi), \
    .io_read_multi_entry_strong_bias_0(P``me_sb0), .io_read_multi_entry_strong_bias_1(P``me_sb1)

  `define PORTS(RDY,P) \
    .clock(clk), .reset(rst), .io_s1_fire(s1_fire), \
    .io_req_pc_ready(RDY), .io_req_pc_valid(req_valid), .io_req_pc_bits(req_pc), \
    `RR(P), .io_read_hits_valid(P``rh_v), .io_read_hits_bits(P``rh_b), \
    `ME(P), .io_read_multi_hits_valid(P``mh_v), .io_read_multi_hits_bits(P``mh_b), \
    .io_u_req_pc_valid(u_req_valid), .io_u_req_pc_bits(u_req_pc), \
    .io_update_hits_valid(P``uh_v), .io_update_hits_bits(P``uh_b), \
    .io_update_access(update_access), .io_update_pc(update_pc), \
    `UWDATA, \
    `BORETOP, `SIG(), `SIG(_1), `SIG(_2), `SIG(_3), `SIG(_4), `SIG(_5), `SIG(_6), `SIG(_7)

  FTBBank    u_g (`PORTS(g_ready, g_));
  FTBBank_xs u_i (`PORTS(i_ready, i_));

  // ---- 随机激励（窄 PC 提升 tag/set 命中概率） ----
  task automatic gen_pc(output logic [49:0] pc);
    // 仅低位随机，让 set index（pc[9:1]^pc[12:4]）与 tag（pc[29:10]）落在小集合内
    pc = {20'h0, 6'($urandom), 14'($urandom)};
  endtask

  logic [49:0] tmp;
  always @(negedge clk) begin
    if (rst) begin
      req_valid<=0; u_req_valid<=0; uw_valid<=0; update_access<=0; s1_fire<=0;
    end else begin
      // 预测读 / 更新读 互斥
      automatic int sel = $urandom_range(0,9);
      req_valid     <= (sel < 5);            // 50% 预测读
      u_req_valid   <= (sel >= 5 && sel < 7);// 20% 更新读
      update_access <= (sel >= 5 && sel < 7);// 更新读那拍 update_access 同步置位
      gen_pc(tmp); req_pc   <= tmp;
      gen_pc(tmp); u_req_pc <= tmp;
      s1_fire <= ($urandom_range(0,3) != 0);

      // 更新写（与读相互独立；上层不会和读同 set 冲突这里不约束，测纯逻辑等价即可）
      uw_valid <= ($urandom_range(0,2) == 0);
      gen_pc(tmp); update_pc <= tmp;
      uw_isCall<=$urandom; uw_isRet<=$urandom; uw_isJalr<=$urandom; uw_evalid<=$urandom;
      uw_broff<=4'($urandom); uw_brsh<=$urandom; uw_brv<=$urandom; uw_brlo<=12'($urandom); uw_brts<=2'($urandom);
      uw_tloff<=4'($urandom); uw_tlsh<=$urandom; uw_tlv<=$urandom; uw_tllo<=20'($urandom); uw_tlts<=2'($urandom);
      uw_pft<=4'($urandom); uw_carry<=$urandom; uw_lastrvi<=$urandom; uw_sb0<=$urandom; uw_sb1<=$urandom;
      uw_tag<=20'($urandom_range(0,15));   // 窄 tag，提升命中/多命中概率
      uw_way<=2'($urandom); uw_alloc<=$urandom;
    end
  end

  // ---- 逐拍比对（复位后、过 WARMUP） ----
  always @(negedge clk) if (!rst && cycle>WARMUP) begin
    #4; checks++;
    if (g_ready!==i_ready) begin errors++; if(errors<=20) $display("[%0t] ready mismatch g=%b i=%b",$time,g_ready,i_ready); end
    if (g_rh_v!==i_rh_v) begin errors++; if(errors<=20) $display("[%0t] read_hits.valid mismatch",$time); end
    if (g_rh_v && (g_rh_b!==i_rh_b)) begin errors++; if(errors<=20) $display("[%0t] read_hits.bits mismatch g=%h i=%h",$time,g_rh_b,i_rh_b); end
    if (g_mh_v!==i_mh_v) begin errors++; if(errors<=20) $display("[%0t] multi_hits.valid mismatch",$time); end
    if (g_mh_v && (g_mh_b!==i_mh_b)) begin errors++; if(errors<=20) $display("[%0t] multi_hits.bits mismatch g=%h i=%h",$time,g_mh_b,i_mh_b); end
    if (g_uh_v!==i_uh_v) begin errors++; if(errors<=20) $display("[%0t] update_hits.valid mismatch",$time); end
    if (g_uh_v && (g_uh_b!==i_uh_b)) begin errors++; if(errors<=20) $display("[%0t] update_hits.bits mismatch g=%h i=%h",$time,g_uh_b,i_uh_b); end
    // read_resp 全字段（仅命中时有意义；未命中两侧均为 0，也应一致）
    if ({g_rr_isCall,g_rr_isRet,g_rr_isJalr,g_rr_valid,g_rr_broff,g_rr_brsh,g_rr_brv,g_rr_brlo,g_rr_brts,
         g_rr_tloff,g_rr_tlsh,g_rr_tlv,g_rr_tllo,g_rr_tlts,g_rr_pft,g_rr_carry,g_rr_lastrvi,g_rr_sb0,g_rr_sb1} !==
        {i_rr_isCall,i_rr_isRet,i_rr_isJalr,i_rr_valid,i_rr_broff,i_rr_brsh,i_rr_brv,i_rr_brlo,i_rr_brts,
         i_rr_tloff,i_rr_tlsh,i_rr_tlv,i_rr_tllo,i_rr_tlts,i_rr_pft,i_rr_carry,i_rr_lastrvi,i_rr_sb0,i_rr_sb1})
      begin errors++; if(errors<=20) $display("[%0t] read_resp mismatch",$time); end
    // read_multi_entry 全字段（仅 multi_hit 时被上层使用；这里只在 multi_hit 时比对）
    if (g_mh_v &&
        ({g_me_isCall,g_me_isRet,g_me_isJalr,g_me_valid,g_me_broff,g_me_brsh,g_me_brv,g_me_brlo,g_me_brts,
          g_me_tloff,g_me_tlsh,g_me_tlv,g_me_tllo,g_me_tlts,g_me_pft,g_me_carry,g_me_lastrvi,g_me_sb0,g_me_sb1} !==
         {i_me_isCall,i_me_isRet,i_me_isJalr,i_me_valid,i_me_broff,i_me_brsh,i_me_brv,i_me_brlo,i_me_brts,
          i_me_tloff,i_me_tlsh,i_me_tlv,i_me_tllo,i_me_tlts,i_me_pft,i_me_carry,i_me_lastrvi,i_me_sb0,i_me_sb1}))
      begin errors++; if(errors<=20) $display("[%0t] read_multi_entry mismatch",$time); end
  end

  initial begin
    rst=1; repeat(8) @(posedge clk); rst=0;
    repeat(NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors==0 && checks>1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
