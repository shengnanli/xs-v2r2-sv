// 自动生成：scripts/gen_l2mbist.py —— 勿手改
// L2DataStorage 双例化逐拍比对：golden L2DataStorage vs 可读重写 L2DataStorage_xs。
// 激励：mbist 请求 (req/all/readen/writeen/array/addr/data/be) 随机，
//       array 偏向落在合法编号上以充分覆盖各 child 的 spread 分支；
//       下游回送 (*_ack/*_rdata/*_outdata) 随机驱动。逐拍比对全部 output。
`timescale 1ns/1ps
`define CHECK(SIG) begin \
  if (!$isunknown(g_``SIG)) begin \
    checks++; \
    if (g_``SIG !== i_``SIG) begin \
      errors++; \
      if (errors <= 20) $display("[%0t] MISMATCH %s g=%0h i=%0h", $time, `"SIG`", g_``SIG, i_``SIG); \
    end \
  end \
end
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  bit reset;
  int errors = 0;
  int checks = 0;
  always #5 clock = ~clock;

  logic [4:0] mbist_array;
  logic mbist_all;
  logic mbist_req;
  logic mbist_writeen;
  logic mbist_be;
  logic [12:0] mbist_addr;
  logic [68:0] mbist_indata;
  logic mbist_readen;
  logic [12:0] mbist_addr_rd;
  logic [68:0] toSRAM_0_rdata;
  logic [68:0] toSRAM_1_rdata;
  logic [68:0] toSRAM_2_rdata;
  logic [68:0] toSRAM_3_rdata;
  logic [68:0] toSRAM_4_rdata;
  logic [68:0] toSRAM_5_rdata;
  logic [68:0] toSRAM_6_rdata;
  logic [68:0] toSRAM_7_rdata;
  wire g_mbist_ack;
  wire i_mbist_ack;
  wire [68:0] g_mbist_outdata;
  wire [68:0] i_mbist_outdata;
  wire [12:0] g_toSRAM_0_addr;
  wire [12:0] i_toSRAM_0_addr;
  wire [12:0] g_toSRAM_0_addr_rd;
  wire [12:0] i_toSRAM_0_addr_rd;
  wire [68:0] g_toSRAM_0_wdata;
  wire [68:0] i_toSRAM_0_wdata;
  wire g_toSRAM_0_wmask;
  wire i_toSRAM_0_wmask;
  wire g_toSRAM_0_re;
  wire i_toSRAM_0_re;
  wire g_toSRAM_0_we;
  wire i_toSRAM_0_we;
  wire g_toSRAM_0_ack;
  wire i_toSRAM_0_ack;
  wire g_toSRAM_0_selectedOH;
  wire i_toSRAM_0_selectedOH;
  wire [3:0] g_toSRAM_0_array;
  wire [3:0] i_toSRAM_0_array;
  wire [12:0] g_toSRAM_1_addr;
  wire [12:0] i_toSRAM_1_addr;
  wire [12:0] g_toSRAM_1_addr_rd;
  wire [12:0] i_toSRAM_1_addr_rd;
  wire [68:0] g_toSRAM_1_wdata;
  wire [68:0] i_toSRAM_1_wdata;
  wire g_toSRAM_1_wmask;
  wire i_toSRAM_1_wmask;
  wire g_toSRAM_1_re;
  wire i_toSRAM_1_re;
  wire g_toSRAM_1_we;
  wire i_toSRAM_1_we;
  wire g_toSRAM_1_ack;
  wire i_toSRAM_1_ack;
  wire g_toSRAM_1_selectedOH;
  wire i_toSRAM_1_selectedOH;
  wire [3:0] g_toSRAM_1_array;
  wire [3:0] i_toSRAM_1_array;
  wire [12:0] g_toSRAM_2_addr;
  wire [12:0] i_toSRAM_2_addr;
  wire [12:0] g_toSRAM_2_addr_rd;
  wire [12:0] i_toSRAM_2_addr_rd;
  wire [68:0] g_toSRAM_2_wdata;
  wire [68:0] i_toSRAM_2_wdata;
  wire g_toSRAM_2_wmask;
  wire i_toSRAM_2_wmask;
  wire g_toSRAM_2_re;
  wire i_toSRAM_2_re;
  wire g_toSRAM_2_we;
  wire i_toSRAM_2_we;
  wire g_toSRAM_2_ack;
  wire i_toSRAM_2_ack;
  wire g_toSRAM_2_selectedOH;
  wire i_toSRAM_2_selectedOH;
  wire [3:0] g_toSRAM_2_array;
  wire [3:0] i_toSRAM_2_array;
  wire [12:0] g_toSRAM_3_addr;
  wire [12:0] i_toSRAM_3_addr;
  wire [12:0] g_toSRAM_3_addr_rd;
  wire [12:0] i_toSRAM_3_addr_rd;
  wire [68:0] g_toSRAM_3_wdata;
  wire [68:0] i_toSRAM_3_wdata;
  wire g_toSRAM_3_wmask;
  wire i_toSRAM_3_wmask;
  wire g_toSRAM_3_re;
  wire i_toSRAM_3_re;
  wire g_toSRAM_3_we;
  wire i_toSRAM_3_we;
  wire g_toSRAM_3_ack;
  wire i_toSRAM_3_ack;
  wire g_toSRAM_3_selectedOH;
  wire i_toSRAM_3_selectedOH;
  wire [3:0] g_toSRAM_3_array;
  wire [3:0] i_toSRAM_3_array;
  wire [12:0] g_toSRAM_4_addr;
  wire [12:0] i_toSRAM_4_addr;
  wire [12:0] g_toSRAM_4_addr_rd;
  wire [12:0] i_toSRAM_4_addr_rd;
  wire [68:0] g_toSRAM_4_wdata;
  wire [68:0] i_toSRAM_4_wdata;
  wire g_toSRAM_4_wmask;
  wire i_toSRAM_4_wmask;
  wire g_toSRAM_4_re;
  wire i_toSRAM_4_re;
  wire g_toSRAM_4_we;
  wire i_toSRAM_4_we;
  wire g_toSRAM_4_ack;
  wire i_toSRAM_4_ack;
  wire g_toSRAM_4_selectedOH;
  wire i_toSRAM_4_selectedOH;
  wire [3:0] g_toSRAM_4_array;
  wire [3:0] i_toSRAM_4_array;
  wire [12:0] g_toSRAM_5_addr;
  wire [12:0] i_toSRAM_5_addr;
  wire [12:0] g_toSRAM_5_addr_rd;
  wire [12:0] i_toSRAM_5_addr_rd;
  wire [68:0] g_toSRAM_5_wdata;
  wire [68:0] i_toSRAM_5_wdata;
  wire g_toSRAM_5_wmask;
  wire i_toSRAM_5_wmask;
  wire g_toSRAM_5_re;
  wire i_toSRAM_5_re;
  wire g_toSRAM_5_we;
  wire i_toSRAM_5_we;
  wire g_toSRAM_5_ack;
  wire i_toSRAM_5_ack;
  wire g_toSRAM_5_selectedOH;
  wire i_toSRAM_5_selectedOH;
  wire [3:0] g_toSRAM_5_array;
  wire [3:0] i_toSRAM_5_array;
  wire [12:0] g_toSRAM_6_addr;
  wire [12:0] i_toSRAM_6_addr;
  wire [12:0] g_toSRAM_6_addr_rd;
  wire [12:0] i_toSRAM_6_addr_rd;
  wire [68:0] g_toSRAM_6_wdata;
  wire [68:0] i_toSRAM_6_wdata;
  wire g_toSRAM_6_wmask;
  wire i_toSRAM_6_wmask;
  wire g_toSRAM_6_re;
  wire i_toSRAM_6_re;
  wire g_toSRAM_6_we;
  wire i_toSRAM_6_we;
  wire g_toSRAM_6_ack;
  wire i_toSRAM_6_ack;
  wire g_toSRAM_6_selectedOH;
  wire i_toSRAM_6_selectedOH;
  wire [3:0] g_toSRAM_6_array;
  wire [3:0] i_toSRAM_6_array;
  wire [12:0] g_toSRAM_7_addr;
  wire [12:0] i_toSRAM_7_addr;
  wire [12:0] g_toSRAM_7_addr_rd;
  wire [12:0] i_toSRAM_7_addr_rd;
  wire [68:0] g_toSRAM_7_wdata;
  wire [68:0] i_toSRAM_7_wdata;
  wire g_toSRAM_7_wmask;
  wire i_toSRAM_7_wmask;
  wire g_toSRAM_7_re;
  wire i_toSRAM_7_re;
  wire g_toSRAM_7_we;
  wire i_toSRAM_7_we;
  wire g_toSRAM_7_ack;
  wire i_toSRAM_7_ack;
  wire g_toSRAM_7_selectedOH;
  wire i_toSRAM_7_selectedOH;
  wire [4:0] g_toSRAM_7_array;
  wire [4:0] i_toSRAM_7_array;

  L2DataStorage u_g (
    .clock(clock),
    .reset(reset),
    .mbist_array(mbist_array),
    .mbist_all(mbist_all),
    .mbist_req(mbist_req),
    .mbist_ack(g_mbist_ack),
    .mbist_writeen(mbist_writeen),
    .mbist_be(mbist_be),
    .mbist_addr(mbist_addr),
    .mbist_indata(mbist_indata),
    .mbist_readen(mbist_readen),
    .mbist_addr_rd(mbist_addr_rd),
    .mbist_outdata(g_mbist_outdata),
    .toSRAM_0_addr(g_toSRAM_0_addr),
    .toSRAM_0_addr_rd(g_toSRAM_0_addr_rd),
    .toSRAM_0_wdata(g_toSRAM_0_wdata),
    .toSRAM_0_wmask(g_toSRAM_0_wmask),
    .toSRAM_0_re(g_toSRAM_0_re),
    .toSRAM_0_we(g_toSRAM_0_we),
    .toSRAM_0_rdata(toSRAM_0_rdata),
    .toSRAM_0_ack(g_toSRAM_0_ack),
    .toSRAM_0_selectedOH(g_toSRAM_0_selectedOH),
    .toSRAM_0_array(g_toSRAM_0_array),
    .toSRAM_1_addr(g_toSRAM_1_addr),
    .toSRAM_1_addr_rd(g_toSRAM_1_addr_rd),
    .toSRAM_1_wdata(g_toSRAM_1_wdata),
    .toSRAM_1_wmask(g_toSRAM_1_wmask),
    .toSRAM_1_re(g_toSRAM_1_re),
    .toSRAM_1_we(g_toSRAM_1_we),
    .toSRAM_1_rdata(toSRAM_1_rdata),
    .toSRAM_1_ack(g_toSRAM_1_ack),
    .toSRAM_1_selectedOH(g_toSRAM_1_selectedOH),
    .toSRAM_1_array(g_toSRAM_1_array),
    .toSRAM_2_addr(g_toSRAM_2_addr),
    .toSRAM_2_addr_rd(g_toSRAM_2_addr_rd),
    .toSRAM_2_wdata(g_toSRAM_2_wdata),
    .toSRAM_2_wmask(g_toSRAM_2_wmask),
    .toSRAM_2_re(g_toSRAM_2_re),
    .toSRAM_2_we(g_toSRAM_2_we),
    .toSRAM_2_rdata(toSRAM_2_rdata),
    .toSRAM_2_ack(g_toSRAM_2_ack),
    .toSRAM_2_selectedOH(g_toSRAM_2_selectedOH),
    .toSRAM_2_array(g_toSRAM_2_array),
    .toSRAM_3_addr(g_toSRAM_3_addr),
    .toSRAM_3_addr_rd(g_toSRAM_3_addr_rd),
    .toSRAM_3_wdata(g_toSRAM_3_wdata),
    .toSRAM_3_wmask(g_toSRAM_3_wmask),
    .toSRAM_3_re(g_toSRAM_3_re),
    .toSRAM_3_we(g_toSRAM_3_we),
    .toSRAM_3_rdata(toSRAM_3_rdata),
    .toSRAM_3_ack(g_toSRAM_3_ack),
    .toSRAM_3_selectedOH(g_toSRAM_3_selectedOH),
    .toSRAM_3_array(g_toSRAM_3_array),
    .toSRAM_4_addr(g_toSRAM_4_addr),
    .toSRAM_4_addr_rd(g_toSRAM_4_addr_rd),
    .toSRAM_4_wdata(g_toSRAM_4_wdata),
    .toSRAM_4_wmask(g_toSRAM_4_wmask),
    .toSRAM_4_re(g_toSRAM_4_re),
    .toSRAM_4_we(g_toSRAM_4_we),
    .toSRAM_4_rdata(toSRAM_4_rdata),
    .toSRAM_4_ack(g_toSRAM_4_ack),
    .toSRAM_4_selectedOH(g_toSRAM_4_selectedOH),
    .toSRAM_4_array(g_toSRAM_4_array),
    .toSRAM_5_addr(g_toSRAM_5_addr),
    .toSRAM_5_addr_rd(g_toSRAM_5_addr_rd),
    .toSRAM_5_wdata(g_toSRAM_5_wdata),
    .toSRAM_5_wmask(g_toSRAM_5_wmask),
    .toSRAM_5_re(g_toSRAM_5_re),
    .toSRAM_5_we(g_toSRAM_5_we),
    .toSRAM_5_rdata(toSRAM_5_rdata),
    .toSRAM_5_ack(g_toSRAM_5_ack),
    .toSRAM_5_selectedOH(g_toSRAM_5_selectedOH),
    .toSRAM_5_array(g_toSRAM_5_array),
    .toSRAM_6_addr(g_toSRAM_6_addr),
    .toSRAM_6_addr_rd(g_toSRAM_6_addr_rd),
    .toSRAM_6_wdata(g_toSRAM_6_wdata),
    .toSRAM_6_wmask(g_toSRAM_6_wmask),
    .toSRAM_6_re(g_toSRAM_6_re),
    .toSRAM_6_we(g_toSRAM_6_we),
    .toSRAM_6_rdata(toSRAM_6_rdata),
    .toSRAM_6_ack(g_toSRAM_6_ack),
    .toSRAM_6_selectedOH(g_toSRAM_6_selectedOH),
    .toSRAM_6_array(g_toSRAM_6_array),
    .toSRAM_7_addr(g_toSRAM_7_addr),
    .toSRAM_7_addr_rd(g_toSRAM_7_addr_rd),
    .toSRAM_7_wdata(g_toSRAM_7_wdata),
    .toSRAM_7_wmask(g_toSRAM_7_wmask),
    .toSRAM_7_re(g_toSRAM_7_re),
    .toSRAM_7_we(g_toSRAM_7_we),
    .toSRAM_7_rdata(toSRAM_7_rdata),
    .toSRAM_7_ack(g_toSRAM_7_ack),
    .toSRAM_7_selectedOH(g_toSRAM_7_selectedOH),
    .toSRAM_7_array(g_toSRAM_7_array)
  );

  L2DataStorage_xs u_i (
    .clock(clock),
    .reset(reset),
    .mbist_array(mbist_array),
    .mbist_all(mbist_all),
    .mbist_req(mbist_req),
    .mbist_ack(i_mbist_ack),
    .mbist_writeen(mbist_writeen),
    .mbist_be(mbist_be),
    .mbist_addr(mbist_addr),
    .mbist_indata(mbist_indata),
    .mbist_readen(mbist_readen),
    .mbist_addr_rd(mbist_addr_rd),
    .mbist_outdata(i_mbist_outdata),
    .toSRAM_0_addr(i_toSRAM_0_addr),
    .toSRAM_0_addr_rd(i_toSRAM_0_addr_rd),
    .toSRAM_0_wdata(i_toSRAM_0_wdata),
    .toSRAM_0_wmask(i_toSRAM_0_wmask),
    .toSRAM_0_re(i_toSRAM_0_re),
    .toSRAM_0_we(i_toSRAM_0_we),
    .toSRAM_0_rdata(toSRAM_0_rdata),
    .toSRAM_0_ack(i_toSRAM_0_ack),
    .toSRAM_0_selectedOH(i_toSRAM_0_selectedOH),
    .toSRAM_0_array(i_toSRAM_0_array),
    .toSRAM_1_addr(i_toSRAM_1_addr),
    .toSRAM_1_addr_rd(i_toSRAM_1_addr_rd),
    .toSRAM_1_wdata(i_toSRAM_1_wdata),
    .toSRAM_1_wmask(i_toSRAM_1_wmask),
    .toSRAM_1_re(i_toSRAM_1_re),
    .toSRAM_1_we(i_toSRAM_1_we),
    .toSRAM_1_rdata(toSRAM_1_rdata),
    .toSRAM_1_ack(i_toSRAM_1_ack),
    .toSRAM_1_selectedOH(i_toSRAM_1_selectedOH),
    .toSRAM_1_array(i_toSRAM_1_array),
    .toSRAM_2_addr(i_toSRAM_2_addr),
    .toSRAM_2_addr_rd(i_toSRAM_2_addr_rd),
    .toSRAM_2_wdata(i_toSRAM_2_wdata),
    .toSRAM_2_wmask(i_toSRAM_2_wmask),
    .toSRAM_2_re(i_toSRAM_2_re),
    .toSRAM_2_we(i_toSRAM_2_we),
    .toSRAM_2_rdata(toSRAM_2_rdata),
    .toSRAM_2_ack(i_toSRAM_2_ack),
    .toSRAM_2_selectedOH(i_toSRAM_2_selectedOH),
    .toSRAM_2_array(i_toSRAM_2_array),
    .toSRAM_3_addr(i_toSRAM_3_addr),
    .toSRAM_3_addr_rd(i_toSRAM_3_addr_rd),
    .toSRAM_3_wdata(i_toSRAM_3_wdata),
    .toSRAM_3_wmask(i_toSRAM_3_wmask),
    .toSRAM_3_re(i_toSRAM_3_re),
    .toSRAM_3_we(i_toSRAM_3_we),
    .toSRAM_3_rdata(toSRAM_3_rdata),
    .toSRAM_3_ack(i_toSRAM_3_ack),
    .toSRAM_3_selectedOH(i_toSRAM_3_selectedOH),
    .toSRAM_3_array(i_toSRAM_3_array),
    .toSRAM_4_addr(i_toSRAM_4_addr),
    .toSRAM_4_addr_rd(i_toSRAM_4_addr_rd),
    .toSRAM_4_wdata(i_toSRAM_4_wdata),
    .toSRAM_4_wmask(i_toSRAM_4_wmask),
    .toSRAM_4_re(i_toSRAM_4_re),
    .toSRAM_4_we(i_toSRAM_4_we),
    .toSRAM_4_rdata(toSRAM_4_rdata),
    .toSRAM_4_ack(i_toSRAM_4_ack),
    .toSRAM_4_selectedOH(i_toSRAM_4_selectedOH),
    .toSRAM_4_array(i_toSRAM_4_array),
    .toSRAM_5_addr(i_toSRAM_5_addr),
    .toSRAM_5_addr_rd(i_toSRAM_5_addr_rd),
    .toSRAM_5_wdata(i_toSRAM_5_wdata),
    .toSRAM_5_wmask(i_toSRAM_5_wmask),
    .toSRAM_5_re(i_toSRAM_5_re),
    .toSRAM_5_we(i_toSRAM_5_we),
    .toSRAM_5_rdata(toSRAM_5_rdata),
    .toSRAM_5_ack(i_toSRAM_5_ack),
    .toSRAM_5_selectedOH(i_toSRAM_5_selectedOH),
    .toSRAM_5_array(i_toSRAM_5_array),
    .toSRAM_6_addr(i_toSRAM_6_addr),
    .toSRAM_6_addr_rd(i_toSRAM_6_addr_rd),
    .toSRAM_6_wdata(i_toSRAM_6_wdata),
    .toSRAM_6_wmask(i_toSRAM_6_wmask),
    .toSRAM_6_re(i_toSRAM_6_re),
    .toSRAM_6_we(i_toSRAM_6_we),
    .toSRAM_6_rdata(toSRAM_6_rdata),
    .toSRAM_6_ack(i_toSRAM_6_ack),
    .toSRAM_6_selectedOH(i_toSRAM_6_selectedOH),
    .toSRAM_6_array(i_toSRAM_6_array),
    .toSRAM_7_addr(i_toSRAM_7_addr),
    .toSRAM_7_addr_rd(i_toSRAM_7_addr_rd),
    .toSRAM_7_wdata(i_toSRAM_7_wdata),
    .toSRAM_7_wmask(i_toSRAM_7_wmask),
    .toSRAM_7_re(i_toSRAM_7_re),
    .toSRAM_7_we(i_toSRAM_7_we),
    .toSRAM_7_rdata(toSRAM_7_rdata),
    .toSRAM_7_ack(i_toSRAM_7_ack),
    .toSRAM_7_selectedOH(i_toSRAM_7_selectedOH),
    .toSRAM_7_array(i_toSRAM_7_array)
  );

  function automatic logic [4:0] pick_array();
    case ($urandom_range(0, 8))
      0: return 5'h9;
      1: return 5'ha;
      2: return 5'hb;
      3: return 5'hc;
      4: return 5'hd;
      5: return 5'he;
      6: return 5'hf;
      7: return 5'h10;
      default: return 5'($urandom);  // 全随机：覆盖未命中路径
    endcase
  endfunction

  task automatic drive_random_inputs();
    mbist_array = pick_array();
    mbist_all = ($urandom_range(0, 3) != 0);
    mbist_req = ($urandom_range(0, 3) != 0);
    mbist_writeen = ($urandom_range(0, 3) != 0);
    mbist_be = $urandom_range(0, 1);
    mbist_addr = 13'({$urandom});
    mbist_indata = 69'({$urandom, $urandom, $urandom});
    mbist_readen = ($urandom_range(0, 3) != 0);
    mbist_addr_rd = 13'({$urandom});
    toSRAM_0_rdata = 69'({$urandom, $urandom, $urandom});
    toSRAM_1_rdata = 69'({$urandom, $urandom, $urandom});
    toSRAM_2_rdata = 69'({$urandom, $urandom, $urandom});
    toSRAM_3_rdata = 69'({$urandom, $urandom, $urandom});
    toSRAM_4_rdata = 69'({$urandom, $urandom, $urandom});
    toSRAM_5_rdata = 69'({$urandom, $urandom, $urandom});
    toSRAM_6_rdata = 69'({$urandom, $urandom, $urandom});
    toSRAM_7_rdata = 69'({$urandom, $urandom, $urandom});
  endtask

  task automatic check_outputs();
    `CHECK(mbist_ack)
    `CHECK(mbist_outdata)
    `CHECK(toSRAM_0_addr)
    `CHECK(toSRAM_0_addr_rd)
    `CHECK(toSRAM_0_wdata)
    `CHECK(toSRAM_0_wmask)
    `CHECK(toSRAM_0_re)
    `CHECK(toSRAM_0_we)
    `CHECK(toSRAM_0_ack)
    `CHECK(toSRAM_0_selectedOH)
    `CHECK(toSRAM_0_array)
    `CHECK(toSRAM_1_addr)
    `CHECK(toSRAM_1_addr_rd)
    `CHECK(toSRAM_1_wdata)
    `CHECK(toSRAM_1_wmask)
    `CHECK(toSRAM_1_re)
    `CHECK(toSRAM_1_we)
    `CHECK(toSRAM_1_ack)
    `CHECK(toSRAM_1_selectedOH)
    `CHECK(toSRAM_1_array)
    `CHECK(toSRAM_2_addr)
    `CHECK(toSRAM_2_addr_rd)
    `CHECK(toSRAM_2_wdata)
    `CHECK(toSRAM_2_wmask)
    `CHECK(toSRAM_2_re)
    `CHECK(toSRAM_2_we)
    `CHECK(toSRAM_2_ack)
    `CHECK(toSRAM_2_selectedOH)
    `CHECK(toSRAM_2_array)
    `CHECK(toSRAM_3_addr)
    `CHECK(toSRAM_3_addr_rd)
    `CHECK(toSRAM_3_wdata)
    `CHECK(toSRAM_3_wmask)
    `CHECK(toSRAM_3_re)
    `CHECK(toSRAM_3_we)
    `CHECK(toSRAM_3_ack)
    `CHECK(toSRAM_3_selectedOH)
    `CHECK(toSRAM_3_array)
    `CHECK(toSRAM_4_addr)
    `CHECK(toSRAM_4_addr_rd)
    `CHECK(toSRAM_4_wdata)
    `CHECK(toSRAM_4_wmask)
    `CHECK(toSRAM_4_re)
    `CHECK(toSRAM_4_we)
    `CHECK(toSRAM_4_ack)
    `CHECK(toSRAM_4_selectedOH)
    `CHECK(toSRAM_4_array)
    `CHECK(toSRAM_5_addr)
    `CHECK(toSRAM_5_addr_rd)
    `CHECK(toSRAM_5_wdata)
    `CHECK(toSRAM_5_wmask)
    `CHECK(toSRAM_5_re)
    `CHECK(toSRAM_5_we)
    `CHECK(toSRAM_5_ack)
    `CHECK(toSRAM_5_selectedOH)
    `CHECK(toSRAM_5_array)
    `CHECK(toSRAM_6_addr)
    `CHECK(toSRAM_6_addr_rd)
    `CHECK(toSRAM_6_wdata)
    `CHECK(toSRAM_6_wmask)
    `CHECK(toSRAM_6_re)
    `CHECK(toSRAM_6_we)
    `CHECK(toSRAM_6_ack)
    `CHECK(toSRAM_6_selectedOH)
    `CHECK(toSRAM_6_array)
    `CHECK(toSRAM_7_addr)
    `CHECK(toSRAM_7_addr_rd)
    `CHECK(toSRAM_7_wdata)
    `CHECK(toSRAM_7_wmask)
    `CHECK(toSRAM_7_re)
    `CHECK(toSRAM_7_we)
    `CHECK(toSRAM_7_ack)
    `CHECK(toSRAM_7_selectedOH)
    `CHECK(toSRAM_7_array)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    mbist_array = '0;
    mbist_all = '0;
    mbist_req = '0;
    mbist_writeen = '0;
    mbist_be = '0;
    mbist_addr = '0;
    mbist_indata = '0;
    mbist_readen = '0;
    mbist_addr_rd = '0;
    toSRAM_0_rdata = '0;
    toSRAM_1_rdata = '0;
    toSRAM_2_rdata = '0;
    toSRAM_3_rdata = '0;
    toSRAM_4_rdata = '0;
    toSRAM_5_rdata = '0;
    toSRAM_6_rdata = '0;
    toSRAM_7_rdata = '0;
    repeat (8) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
    end
    $display("L2DataStorage checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
