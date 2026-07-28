// =============================================================================
// xs_PTWRepeaterNB_core —— 单请求非阻塞 PTW 中继器（可读重写）
//
// 对应 Chisel: src/main/scala/xiangshan/cache/mmu/Repeater.scala
//   class PTWRepeaterNB(passReady=false, Width=1)
//
// 角色见 ptwrepeaternb_pkg.sv 头注释。本核实现全部逻辑；唯一子模块 DelayN_1（sfence/csr
//   变更延迟 2 拍产生 flush 脉冲）在外层 wrapper 里例化 golden，两侧同源 elaborate（纯逻辑
//   移位链，非黑盒）。
//
// 状态：
//   sent —— tlb 侧请求已接收、正等 ptw 侧接收（在途 req）。异步复位清 0。
//   recv —— ptw 侧响应已接收、正等 tlb 侧接收（在途 resp）。异步复位清 0。
// 握手：
//   tlb_req_ready  = ~sent          （sent 满时不再收新请求）
//   ptw_req_valid  = sent
//   ptw_resp_ready = ~recv
//   tlb_resp_valid = recv
// flush = DelayN_1 输出（sfence_valid | satp/vsatp/hgatp changed 延迟 2 拍），清 sent+recv。
//
// 寄存器命名与 golden 逐一对齐（resp_* 整包 + req_vpn/req_s2xlate），便于 FM 1:1 匹配。
// =============================================================================
module xs_PTWRepeaterNB_core (
  input  logic        clock,
  input  logic        reset,

  // flush 脉冲（外层 DelayN_1 产生）
  input  logic        io_flush,

  // ---- tlb 侧（L1 TLB → 本中继）----
  output logic        io_tlb_req_0_ready,
  input  logic        io_tlb_req_0_valid,
  input  logic [37:0] io_tlb_req_0_bits_vpn,
  input  logic [1:0]  io_tlb_req_0_bits_s2xlate,
  input  logic        io_tlb_resp_ready,
  output logic        io_tlb_resp_valid,
  output logic [1:0]  io_tlb_resp_bits_s2xlate,
  output logic [34:0] io_tlb_resp_bits_s1_entry_tag,
  output logic [15:0] io_tlb_resp_bits_s1_entry_asid,
  output logic [13:0] io_tlb_resp_bits_s1_entry_vmid,
  output logic        io_tlb_resp_bits_s1_entry_n,
  output logic [1:0]  io_tlb_resp_bits_s1_entry_pbmt,
  output logic        io_tlb_resp_bits_s1_entry_perm_d,
  output logic        io_tlb_resp_bits_s1_entry_perm_a,
  output logic        io_tlb_resp_bits_s1_entry_perm_g,
  output logic        io_tlb_resp_bits_s1_entry_perm_u,
  output logic        io_tlb_resp_bits_s1_entry_perm_x,
  output logic        io_tlb_resp_bits_s1_entry_perm_w,
  output logic        io_tlb_resp_bits_s1_entry_perm_r,
  output logic [1:0]  io_tlb_resp_bits_s1_entry_level,
  output logic        io_tlb_resp_bits_s1_entry_v,
  output logic [40:0] io_tlb_resp_bits_s1_entry_ppn,
  output logic [2:0]  io_tlb_resp_bits_s1_addr_low,
  output logic [2:0]  io_tlb_resp_bits_s1_ppn_low_0,
  output logic [2:0]  io_tlb_resp_bits_s1_ppn_low_1,
  output logic [2:0]  io_tlb_resp_bits_s1_ppn_low_2,
  output logic [2:0]  io_tlb_resp_bits_s1_ppn_low_3,
  output logic [2:0]  io_tlb_resp_bits_s1_ppn_low_4,
  output logic [2:0]  io_tlb_resp_bits_s1_ppn_low_5,
  output logic [2:0]  io_tlb_resp_bits_s1_ppn_low_6,
  output logic [2:0]  io_tlb_resp_bits_s1_ppn_low_7,
  output logic        io_tlb_resp_bits_s1_valididx_0,
  output logic        io_tlb_resp_bits_s1_valididx_1,
  output logic        io_tlb_resp_bits_s1_valididx_2,
  output logic        io_tlb_resp_bits_s1_valididx_3,
  output logic        io_tlb_resp_bits_s1_valididx_4,
  output logic        io_tlb_resp_bits_s1_valididx_5,
  output logic        io_tlb_resp_bits_s1_valididx_6,
  output logic        io_tlb_resp_bits_s1_valididx_7,
  output logic        io_tlb_resp_bits_s1_pteidx_0,
  output logic        io_tlb_resp_bits_s1_pteidx_1,
  output logic        io_tlb_resp_bits_s1_pteidx_2,
  output logic        io_tlb_resp_bits_s1_pteidx_3,
  output logic        io_tlb_resp_bits_s1_pteidx_4,
  output logic        io_tlb_resp_bits_s1_pteidx_5,
  output logic        io_tlb_resp_bits_s1_pteidx_6,
  output logic        io_tlb_resp_bits_s1_pteidx_7,
  output logic        io_tlb_resp_bits_s1_pf,
  output logic        io_tlb_resp_bits_s1_af,
  output logic [37:0] io_tlb_resp_bits_s2_entry_tag,
  output logic [13:0] io_tlb_resp_bits_s2_entry_vmid,
  output logic        io_tlb_resp_bits_s2_entry_n,
  output logic [1:0]  io_tlb_resp_bits_s2_entry_pbmt,
  output logic [37:0] io_tlb_resp_bits_s2_entry_ppn,
  output logic        io_tlb_resp_bits_s2_entry_perm_d,
  output logic        io_tlb_resp_bits_s2_entry_perm_a,
  output logic        io_tlb_resp_bits_s2_entry_perm_g,
  output logic        io_tlb_resp_bits_s2_entry_perm_u,
  output logic        io_tlb_resp_bits_s2_entry_perm_x,
  output logic        io_tlb_resp_bits_s2_entry_perm_w,
  output logic        io_tlb_resp_bits_s2_entry_perm_r,
  output logic [1:0]  io_tlb_resp_bits_s2_entry_level,
  output logic        io_tlb_resp_bits_s2_gpf,
  output logic        io_tlb_resp_bits_s2_gaf,

  // ---- ptw 侧（本中继 → 共享 L2 TLB）----
  input  logic        io_ptw_req_0_ready,
  output logic        io_ptw_req_0_valid,
  output logic [37:0] io_ptw_req_0_bits_vpn,
  output logic [1:0]  io_ptw_req_0_bits_s2xlate,
  output logic        io_ptw_resp_ready,
  input  logic        io_ptw_resp_valid,
  input  logic [1:0]  io_ptw_resp_bits_s2xlate,
  input  logic [34:0] io_ptw_resp_bits_s1_entry_tag,
  input  logic [15:0] io_ptw_resp_bits_s1_entry_asid,
  input  logic [13:0] io_ptw_resp_bits_s1_entry_vmid,
  input  logic        io_ptw_resp_bits_s1_entry_n,
  input  logic [1:0]  io_ptw_resp_bits_s1_entry_pbmt,
  input  logic        io_ptw_resp_bits_s1_entry_perm_d,
  input  logic        io_ptw_resp_bits_s1_entry_perm_a,
  input  logic        io_ptw_resp_bits_s1_entry_perm_g,
  input  logic        io_ptw_resp_bits_s1_entry_perm_u,
  input  logic        io_ptw_resp_bits_s1_entry_perm_x,
  input  logic        io_ptw_resp_bits_s1_entry_perm_w,
  input  logic        io_ptw_resp_bits_s1_entry_perm_r,
  input  logic [1:0]  io_ptw_resp_bits_s1_entry_level,
  input  logic        io_ptw_resp_bits_s1_entry_v,
  input  logic [40:0] io_ptw_resp_bits_s1_entry_ppn,
  input  logic [2:0]  io_ptw_resp_bits_s1_addr_low,
  input  logic [2:0]  io_ptw_resp_bits_s1_ppn_low_0,
  input  logic [2:0]  io_ptw_resp_bits_s1_ppn_low_1,
  input  logic [2:0]  io_ptw_resp_bits_s1_ppn_low_2,
  input  logic [2:0]  io_ptw_resp_bits_s1_ppn_low_3,
  input  logic [2:0]  io_ptw_resp_bits_s1_ppn_low_4,
  input  logic [2:0]  io_ptw_resp_bits_s1_ppn_low_5,
  input  logic [2:0]  io_ptw_resp_bits_s1_ppn_low_6,
  input  logic [2:0]  io_ptw_resp_bits_s1_ppn_low_7,
  input  logic        io_ptw_resp_bits_s1_valididx_0,
  input  logic        io_ptw_resp_bits_s1_valididx_1,
  input  logic        io_ptw_resp_bits_s1_valididx_2,
  input  logic        io_ptw_resp_bits_s1_valididx_3,
  input  logic        io_ptw_resp_bits_s1_valididx_4,
  input  logic        io_ptw_resp_bits_s1_valididx_5,
  input  logic        io_ptw_resp_bits_s1_valididx_6,
  input  logic        io_ptw_resp_bits_s1_valididx_7,
  input  logic        io_ptw_resp_bits_s1_pteidx_0,
  input  logic        io_ptw_resp_bits_s1_pteidx_1,
  input  logic        io_ptw_resp_bits_s1_pteidx_2,
  input  logic        io_ptw_resp_bits_s1_pteidx_3,
  input  logic        io_ptw_resp_bits_s1_pteidx_4,
  input  logic        io_ptw_resp_bits_s1_pteidx_5,
  input  logic        io_ptw_resp_bits_s1_pteidx_6,
  input  logic        io_ptw_resp_bits_s1_pteidx_7,
  input  logic        io_ptw_resp_bits_s1_pf,
  input  logic        io_ptw_resp_bits_s1_af,
  input  logic [37:0] io_ptw_resp_bits_s2_entry_tag,
  input  logic [13:0] io_ptw_resp_bits_s2_entry_vmid,
  input  logic        io_ptw_resp_bits_s2_entry_n,
  input  logic [1:0]  io_ptw_resp_bits_s2_entry_pbmt,
  input  logic [37:0] io_ptw_resp_bits_s2_entry_ppn,
  input  logic        io_ptw_resp_bits_s2_entry_perm_d,
  input  logic        io_ptw_resp_bits_s2_entry_perm_a,
  input  logic        io_ptw_resp_bits_s2_entry_perm_g,
  input  logic        io_ptw_resp_bits_s2_entry_perm_u,
  input  logic        io_ptw_resp_bits_s2_entry_perm_x,
  input  logic        io_ptw_resp_bits_s2_entry_perm_w,
  input  logic        io_ptw_resp_bits_s2_entry_perm_r,
  input  logic [1:0]  io_ptw_resp_bits_s2_entry_level,
  input  logic        io_ptw_resp_bits_s2_gpf,
  input  logic        io_ptw_resp_bits_s2_gaf
);

  // ---------------- 状态位 ----------------
  logic        sent, recv;

  // ---------------- 在途 req 寄存（{vpn,s2xlate}）----------------
  logic [37:0] req_vpn;
  logic [1:0]  req_s2xlate;

  // ---------------- 在途 resp 整包寄存 ----------------
  logic [1:0]  resp_s2xlate;
  logic [34:0] resp_s1_entry_tag;
  logic [15:0] resp_s1_entry_asid;
  logic [13:0] resp_s1_entry_vmid;
  logic        resp_s1_entry_n;
  logic [1:0]  resp_s1_entry_pbmt;
  logic        resp_s1_entry_perm_d, resp_s1_entry_perm_a, resp_s1_entry_perm_g;
  logic        resp_s1_entry_perm_u, resp_s1_entry_perm_x, resp_s1_entry_perm_w, resp_s1_entry_perm_r;
  logic [1:0]  resp_s1_entry_level;
  logic        resp_s1_entry_v;
  logic [40:0] resp_s1_entry_ppn;
  logic [2:0]  resp_s1_addr_low;
  logic [2:0]  resp_s1_ppn_low_0, resp_s1_ppn_low_1, resp_s1_ppn_low_2, resp_s1_ppn_low_3;
  logic [2:0]  resp_s1_ppn_low_4, resp_s1_ppn_low_5, resp_s1_ppn_low_6, resp_s1_ppn_low_7;
  logic        resp_s1_valididx_0, resp_s1_valididx_1, resp_s1_valididx_2, resp_s1_valididx_3;
  logic        resp_s1_valididx_4, resp_s1_valididx_5, resp_s1_valididx_6, resp_s1_valididx_7;
  logic        resp_s1_pteidx_0, resp_s1_pteidx_1, resp_s1_pteidx_2, resp_s1_pteidx_3;
  logic        resp_s1_pteidx_4, resp_s1_pteidx_5, resp_s1_pteidx_6, resp_s1_pteidx_7;
  logic        resp_s1_pf, resp_s1_af;
  logic [37:0] resp_s2_entry_tag;
  logic [13:0] resp_s2_entry_vmid;
  logic        resp_s2_entry_n;
  logic [1:0]  resp_s2_entry_pbmt;
  logic [37:0] resp_s2_entry_ppn;
  logic        resp_s2_entry_perm_d, resp_s2_entry_perm_a, resp_s2_entry_perm_g;
  logic        resp_s2_entry_perm_u, resp_s2_entry_perm_x, resp_s2_entry_perm_w, resp_s2_entry_perm_r;
  logic [1:0]  resp_s2_entry_level;
  logic        resp_s2_gpf, resp_s2_gaf;

  // ---------------- 关键组合条件 ----------------
  // 新请求进入（sent 空 + tlb 侧 req valid）→ 锁 req、置 sent。
  wire accept_req  = ~sent & io_tlb_req_0_valid;
  // 新响应进入（recv 空 + ptw 侧 resp valid）→ 锁 resp、置 recv。
  wire accept_resp = ~recv & io_ptw_resp_valid;
  // tlb 侧取走响应（resp valid=recv 且 tlb 侧 ready）。
  wire tlb_resp_fire = io_tlb_resp_ready & recv;

  // ---------------- 时序：req / resp 打拍锁存（无复位，条件使能）----------------
  always_ff @(posedge clock) begin
    if (accept_req) begin
      req_vpn     <= io_tlb_req_0_bits_vpn;
      req_s2xlate <= io_tlb_req_0_bits_s2xlate;
    end
    if (accept_resp) begin
      resp_s2xlate          <= io_ptw_resp_bits_s2xlate;
      resp_s1_entry_tag     <= io_ptw_resp_bits_s1_entry_tag;
      resp_s1_entry_asid    <= io_ptw_resp_bits_s1_entry_asid;
      resp_s1_entry_vmid    <= io_ptw_resp_bits_s1_entry_vmid;
      resp_s1_entry_n       <= io_ptw_resp_bits_s1_entry_n;
      resp_s1_entry_pbmt    <= io_ptw_resp_bits_s1_entry_pbmt;
      resp_s1_entry_perm_d  <= io_ptw_resp_bits_s1_entry_perm_d;
      resp_s1_entry_perm_a  <= io_ptw_resp_bits_s1_entry_perm_a;
      resp_s1_entry_perm_g  <= io_ptw_resp_bits_s1_entry_perm_g;
      resp_s1_entry_perm_u  <= io_ptw_resp_bits_s1_entry_perm_u;
      resp_s1_entry_perm_x  <= io_ptw_resp_bits_s1_entry_perm_x;
      resp_s1_entry_perm_w  <= io_ptw_resp_bits_s1_entry_perm_w;
      resp_s1_entry_perm_r  <= io_ptw_resp_bits_s1_entry_perm_r;
      resp_s1_entry_level   <= io_ptw_resp_bits_s1_entry_level;
      resp_s1_entry_v       <= io_ptw_resp_bits_s1_entry_v;
      resp_s1_entry_ppn     <= io_ptw_resp_bits_s1_entry_ppn;
      resp_s1_addr_low      <= io_ptw_resp_bits_s1_addr_low;
      resp_s1_ppn_low_0     <= io_ptw_resp_bits_s1_ppn_low_0;
      resp_s1_ppn_low_1     <= io_ptw_resp_bits_s1_ppn_low_1;
      resp_s1_ppn_low_2     <= io_ptw_resp_bits_s1_ppn_low_2;
      resp_s1_ppn_low_3     <= io_ptw_resp_bits_s1_ppn_low_3;
      resp_s1_ppn_low_4     <= io_ptw_resp_bits_s1_ppn_low_4;
      resp_s1_ppn_low_5     <= io_ptw_resp_bits_s1_ppn_low_5;
      resp_s1_ppn_low_6     <= io_ptw_resp_bits_s1_ppn_low_6;
      resp_s1_ppn_low_7     <= io_ptw_resp_bits_s1_ppn_low_7;
      resp_s1_valididx_0    <= io_ptw_resp_bits_s1_valididx_0;
      resp_s1_valididx_1    <= io_ptw_resp_bits_s1_valididx_1;
      resp_s1_valididx_2    <= io_ptw_resp_bits_s1_valididx_2;
      resp_s1_valididx_3    <= io_ptw_resp_bits_s1_valididx_3;
      resp_s1_valididx_4    <= io_ptw_resp_bits_s1_valididx_4;
      resp_s1_valididx_5    <= io_ptw_resp_bits_s1_valididx_5;
      resp_s1_valididx_6    <= io_ptw_resp_bits_s1_valididx_6;
      resp_s1_valididx_7    <= io_ptw_resp_bits_s1_valididx_7;
      resp_s1_pteidx_0      <= io_ptw_resp_bits_s1_pteidx_0;
      resp_s1_pteidx_1      <= io_ptw_resp_bits_s1_pteidx_1;
      resp_s1_pteidx_2      <= io_ptw_resp_bits_s1_pteidx_2;
      resp_s1_pteidx_3      <= io_ptw_resp_bits_s1_pteidx_3;
      resp_s1_pteidx_4      <= io_ptw_resp_bits_s1_pteidx_4;
      resp_s1_pteidx_5      <= io_ptw_resp_bits_s1_pteidx_5;
      resp_s1_pteidx_6      <= io_ptw_resp_bits_s1_pteidx_6;
      resp_s1_pteidx_7      <= io_ptw_resp_bits_s1_pteidx_7;
      resp_s1_pf            <= io_ptw_resp_bits_s1_pf;
      resp_s1_af            <= io_ptw_resp_bits_s1_af;
      resp_s2_entry_tag     <= io_ptw_resp_bits_s2_entry_tag;
      resp_s2_entry_vmid    <= io_ptw_resp_bits_s2_entry_vmid;
      resp_s2_entry_n       <= io_ptw_resp_bits_s2_entry_n;
      resp_s2_entry_pbmt    <= io_ptw_resp_bits_s2_entry_pbmt;
      resp_s2_entry_ppn     <= io_ptw_resp_bits_s2_entry_ppn;
      resp_s2_entry_perm_d  <= io_ptw_resp_bits_s2_entry_perm_d;
      resp_s2_entry_perm_a  <= io_ptw_resp_bits_s2_entry_perm_a;
      resp_s2_entry_perm_g  <= io_ptw_resp_bits_s2_entry_perm_g;
      resp_s2_entry_perm_u  <= io_ptw_resp_bits_s2_entry_perm_u;
      resp_s2_entry_perm_x  <= io_ptw_resp_bits_s2_entry_perm_x;
      resp_s2_entry_perm_w  <= io_ptw_resp_bits_s2_entry_perm_w;
      resp_s2_entry_perm_r  <= io_ptw_resp_bits_s2_entry_perm_r;
      resp_s2_entry_level   <= io_ptw_resp_bits_s2_entry_level;
      resp_s2_gpf           <= io_ptw_resp_bits_s2_gpf;
      resp_s2_gaf           <= io_ptw_resp_bits_s2_gaf;
    end
  end

  // ---------------- 时序：sent / recv 状态机（异步复位）----------------
  //   sent 下一拍 = ~(ptw 接收 sent | flush) & (accept_req | sent)
  //   recv 下一拍 = ~(tlb 取走 resp | flush) & (accept_resp | recv)
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      sent <= 1'b0;
      recv <= 1'b0;
    end else begin
      sent <= ~((io_ptw_req_0_ready & sent) | io_flush) & (accept_req  | sent);
      recv <= ~(tlb_resp_fire            | io_flush) & (accept_resp | recv);
    end
  end

  // ---------------- 输出握手 ----------------
  assign io_tlb_req_0_ready  = ~sent;
  assign io_tlb_resp_valid   = recv;
  assign io_ptw_req_0_valid  = sent;
  assign io_ptw_req_0_bits_vpn     = req_vpn;
  assign io_ptw_req_0_bits_s2xlate = req_s2xlate;
  assign io_ptw_resp_ready   = ~recv;

  // ---------------- 输出 resp 整包（直连寄存）----------------
  assign io_tlb_resp_bits_s2xlate         = resp_s2xlate;
  assign io_tlb_resp_bits_s1_entry_tag    = resp_s1_entry_tag;
  assign io_tlb_resp_bits_s1_entry_asid   = resp_s1_entry_asid;
  assign io_tlb_resp_bits_s1_entry_vmid   = resp_s1_entry_vmid;
  assign io_tlb_resp_bits_s1_entry_n      = resp_s1_entry_n;
  assign io_tlb_resp_bits_s1_entry_pbmt   = resp_s1_entry_pbmt;
  assign io_tlb_resp_bits_s1_entry_perm_d = resp_s1_entry_perm_d;
  assign io_tlb_resp_bits_s1_entry_perm_a = resp_s1_entry_perm_a;
  assign io_tlb_resp_bits_s1_entry_perm_g = resp_s1_entry_perm_g;
  assign io_tlb_resp_bits_s1_entry_perm_u = resp_s1_entry_perm_u;
  assign io_tlb_resp_bits_s1_entry_perm_x = resp_s1_entry_perm_x;
  assign io_tlb_resp_bits_s1_entry_perm_w = resp_s1_entry_perm_w;
  assign io_tlb_resp_bits_s1_entry_perm_r = resp_s1_entry_perm_r;
  assign io_tlb_resp_bits_s1_entry_level  = resp_s1_entry_level;
  assign io_tlb_resp_bits_s1_entry_v      = resp_s1_entry_v;
  assign io_tlb_resp_bits_s1_entry_ppn    = resp_s1_entry_ppn;
  assign io_tlb_resp_bits_s1_addr_low     = resp_s1_addr_low;
  assign io_tlb_resp_bits_s1_ppn_low_0    = resp_s1_ppn_low_0;
  assign io_tlb_resp_bits_s1_ppn_low_1    = resp_s1_ppn_low_1;
  assign io_tlb_resp_bits_s1_ppn_low_2    = resp_s1_ppn_low_2;
  assign io_tlb_resp_bits_s1_ppn_low_3    = resp_s1_ppn_low_3;
  assign io_tlb_resp_bits_s1_ppn_low_4    = resp_s1_ppn_low_4;
  assign io_tlb_resp_bits_s1_ppn_low_5    = resp_s1_ppn_low_5;
  assign io_tlb_resp_bits_s1_ppn_low_6    = resp_s1_ppn_low_6;
  assign io_tlb_resp_bits_s1_ppn_low_7    = resp_s1_ppn_low_7;
  assign io_tlb_resp_bits_s1_valididx_0   = resp_s1_valididx_0;
  assign io_tlb_resp_bits_s1_valididx_1   = resp_s1_valididx_1;
  assign io_tlb_resp_bits_s1_valididx_2   = resp_s1_valididx_2;
  assign io_tlb_resp_bits_s1_valididx_3   = resp_s1_valididx_3;
  assign io_tlb_resp_bits_s1_valididx_4   = resp_s1_valididx_4;
  assign io_tlb_resp_bits_s1_valididx_5   = resp_s1_valididx_5;
  assign io_tlb_resp_bits_s1_valididx_6   = resp_s1_valididx_6;
  assign io_tlb_resp_bits_s1_valididx_7   = resp_s1_valididx_7;
  assign io_tlb_resp_bits_s1_pteidx_0     = resp_s1_pteidx_0;
  assign io_tlb_resp_bits_s1_pteidx_1     = resp_s1_pteidx_1;
  assign io_tlb_resp_bits_s1_pteidx_2     = resp_s1_pteidx_2;
  assign io_tlb_resp_bits_s1_pteidx_3     = resp_s1_pteidx_3;
  assign io_tlb_resp_bits_s1_pteidx_4     = resp_s1_pteidx_4;
  assign io_tlb_resp_bits_s1_pteidx_5     = resp_s1_pteidx_5;
  assign io_tlb_resp_bits_s1_pteidx_6     = resp_s1_pteidx_6;
  assign io_tlb_resp_bits_s1_pteidx_7     = resp_s1_pteidx_7;
  assign io_tlb_resp_bits_s1_pf           = resp_s1_pf;
  assign io_tlb_resp_bits_s1_af           = resp_s1_af;
  assign io_tlb_resp_bits_s2_entry_tag    = resp_s2_entry_tag;
  assign io_tlb_resp_bits_s2_entry_vmid   = resp_s2_entry_vmid;
  assign io_tlb_resp_bits_s2_entry_n      = resp_s2_entry_n;
  assign io_tlb_resp_bits_s2_entry_pbmt   = resp_s2_entry_pbmt;
  assign io_tlb_resp_bits_s2_entry_ppn    = resp_s2_entry_ppn;
  assign io_tlb_resp_bits_s2_entry_perm_d = resp_s2_entry_perm_d;
  assign io_tlb_resp_bits_s2_entry_perm_a = resp_s2_entry_perm_a;
  assign io_tlb_resp_bits_s2_entry_perm_g = resp_s2_entry_perm_g;
  assign io_tlb_resp_bits_s2_entry_perm_u = resp_s2_entry_perm_u;
  assign io_tlb_resp_bits_s2_entry_perm_x = resp_s2_entry_perm_x;
  assign io_tlb_resp_bits_s2_entry_perm_w = resp_s2_entry_perm_w;
  assign io_tlb_resp_bits_s2_entry_perm_r = resp_s2_entry_perm_r;
  assign io_tlb_resp_bits_s2_entry_level  = resp_s2_entry_level;
  assign io_tlb_resp_bits_s2_gpf          = resp_s2_gpf;
  assign io_tlb_resp_bits_s2_gaf          = resp_s2_gaf;

endmodule
