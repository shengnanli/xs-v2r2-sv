// =============================================================================
// xs_PMPChecker_core —— PMP/PMA 权限检查器（PMPChecker 家族共用的可读核）
//
// 位置：每个要访问物理地址的口（DTLB 之后的访存口、ITLB 之后的取指口、页表遍历器的
//   访存口）各挂一个。输入是 CSR 侧分发过来的 PMP/PMA 表项副本（check_env）和一次
//   物理地址访问请求 req，输出是这次访问该不该报异常、是不是 MMIO、能不能做原子访问。
//   Scala：xiangshan/backend/fu/PMP.scala（class PMPChecker / PMPCheckMethod /
//   PMPMatchMethod）与 PMA.scala（PMACheckMethod）。
//
// 机制（三步）：
//   §1 逐项匹配：每个表项按 cfg.a 判这次地址是否落在它的范围里
//        a[1]=1（NAPOT/NA4）：  (paddr & ~mask) == (基址 & ~mask)，mask 是 CSR 侧预先算好的
//        a==1  （TOR）：        上一项基址 <= paddr < 本项基址（第 0 项的"上一项"基址为 0）
//        其余  （OFF）：        不匹配
//      基址 = {addr, 2'b00} 再把低 PLATFORM_GRAIN 位清零（平台粒度 4KB）。
//      调试模块地址段 [DEBUG_LO, DEBUG_HI] 只有 debug 模式才允许匹配。
//   §2 优先级选择：下标最小的命中项胜出；全不命中时用缺省项
//        PMP 缺省项：M 态（mode[1]=1）rwx 全放行，其余全禁止；
//        PMA 缺省项：全 0（不可读写执行、非 cacheable 即 MMIO、不可原子）。
//      PMP 项的 rwx 还要过一道"M 态且未锁定（!cfg.l）则忽略限制"。
//   §3 按访问类型 cmd 判违例：ld / st / instr 是 PMP 违例与 PMA 违例的或；
//      mmio = !pma.c；atomic = pma.atomic。
//
// 三种时序形态（Scala 构造参数 sameCycle / leaveHitMux，对应本核两个参数）：
//   SAME_CYCLE=1                 纯组合，当拍出结果（页表遍历器用）
//   LEAVE_HIT_MUX=1              §1 之后打一拍（命中位 + 各项权限 + cmd），§2/§3 在下一拍做
//                                —— 把 33 选 1 的优先级 mux 留到下一拍，给访存口减时序压力
//   两者皆 0                     §1~§3 组合做完，结果整体打一拍（取指口用）
//   寄存器都由 req_valid 使能；只有 LEAVE_HIT_MUX 的命中位带异步复位（复位成"不命中"），
//   其余寄存器不复位（照 golden）。
//
// 边界与怪癖（都照 golden，不"修"）：
//   * 本核只覆盖 lgMaxSize <= PlatformGrain 的配置（本工程 3/4 <= 12）：此时访问不可能
//     跨表项边界，Scala 里的 aligned 恒真、匹配不看访问大小，所以没有 size 口。
//   * TOR 的下界只看"上一项的基址"，不管上一项自己是什么模式。
//   * PMA 表最后一项不命中时得到全 0 缺省项 —— golden 里写成 `命中 & 字段`。
//   * LEAVE_HIT_MUX 形态下 PMP 缺省项的 rwx（= mode[1]）也跟着打一拍。
//   * keyID（内存加密）检查在本配置下 PMPKeyIDBits=0，整条被 firtool 消掉，不实现。
//   * RESP_USED：结果整体打拍的形态下，父模块没接的输出位 firtool 连寄存器一起删了；
//     本参数按位（{atomic,mmio,instr,st,ld}）指明哪些结果寄存器真的存在，不存在的输出恒 0。
// =============================================================================

module xs_PMPChecker_core #(
  parameter int unsigned NUM_ENTRY      = 32,       // PMP 与 PMA 表项数（本工程两者相同）
  parameter int unsigned PADDR_W        = 48,
  parameter int unsigned PLATFORM_GRAIN = 12,       // 平台粒度 log2（4KB）
  parameter bit          SAME_CYCLE     = 1'b0,
  parameter bit          LEAVE_HIT_MUX  = 1'b0,
  parameter bit [4:0]    RESP_USED      = 5'b11111, // {atomic, mmio, instr, st, ld}
  parameter logic [PADDR_W-1:0] DEBUG_LO = 48'h3802_0000,
  parameter logic [PADDR_W-1:0] DEBUG_HI = 48'h3802_0fff
) (
  input  logic                                  clock,
  input  logic                                  reset,
  // ---- 检查环境：特权级、debug 模式、PMP/PMA 表项副本 ----
  input  logic [1:0]                            env_mode,
  input  logic                                  env_debug,
  input  logic [NUM_ENTRY-1:0]                  pmp_l,
  input  logic [NUM_ENTRY-1:0][1:0]             pmp_a,
  input  logic [NUM_ENTRY-1:0]                  pmp_x,
  input  logic [NUM_ENTRY-1:0]                  pmp_w,
  input  logic [NUM_ENTRY-1:0]                  pmp_r,
  input  logic [NUM_ENTRY-1:0][PADDR_W-3:0]     pmp_addr,
  input  logic [NUM_ENTRY-1:0][PADDR_W-1:0]     pmp_mask,
  input  logic [NUM_ENTRY-1:0]                  pma_c,
  input  logic [NUM_ENTRY-1:0]                  pma_atomic,
  input  logic [NUM_ENTRY-1:0][1:0]             pma_a,
  input  logic [NUM_ENTRY-1:0]                  pma_x,
  input  logic [NUM_ENTRY-1:0]                  pma_w,
  input  logic [NUM_ENTRY-1:0]                  pma_r,
  input  logic [NUM_ENTRY-1:0][PADDR_W-3:0]     pma_addr,
  input  logic [NUM_ENTRY-1:0][PADDR_W-1:0]     pma_mask,
  // ---- 请求 ----
  input  logic                                  req_valid,
  input  logic [PADDR_W-1:0]                    req_addr,
  input  logic [2:0]                            req_cmd,
  // ---- 结果 ----
  output logic                                  resp_ld,
  output logic                                  resp_st,
  output logic                                  resp_instr,
  output logic                                  resp_mmio,
  output logic                                  resp_atomic
);

  // TlbCmd 编码（xiangshan/cache/mmu/MMUBundle.scala）
  localparam logic [2:0] CMD_ATOM_READ  = 3'b100;  // lr
  localparam logic [2:0] CMD_ATOM_WRITE = 3'b101;  // sc / amo
  localparam logic [2:0] CMD_READ_EXEC  = 3'b111;  // HLVX

  // ---------------------------------------------------------------------------
  // §1 逐项匹配
  // ---------------------------------------------------------------------------
  // 比较用基址：{addr, 2'b00}，低 PLATFORM_GRAIN 位清零
  function automatic logic [PADDR_W-1:0] compare_addr(input logic [PADDR_W-3:0] addr);
    logic [PADDR_W-1:0] full;
    full = {addr, 2'b00};
    full[PLATFORM_GRAIN-1:0] = '0;
    return full;
  endfunction

  // 调试模块地址段只对 debug 模式可见
  logic debug_range_ok;
  assign debug_range_ok = !(req_addr >= DEBUG_LO && req_addr <= DEBUG_HI) || env_debug;

  logic [NUM_ENTRY-1:0][PADDR_W-1:0] pmp_base;
  logic [NUM_ENTRY-1:0][PADDR_W-1:0] pma_base;
  logic [NUM_ENTRY-1:0]              pmp_match;
  logic [NUM_ENTRY-1:0]              pma_match;

  always_comb begin
    for (int i = 0; i < NUM_ENTRY; i++) begin
      pmp_base[i] = compare_addr(pmp_addr[i]);
      pma_base[i] = compare_addr(pma_addr[i]);
    end
  end

  always_comb begin
    for (int i = 0; i < NUM_ENTRY; i++) begin
      logic pmp_napot_hit, pmp_tor_hit;
      logic pma_napot_hit, pma_tor_hit;
      // NAPOT：掩掉 mask 标出的低位后相等
      pmp_napot_hit = (req_addr & ~pmp_mask[i]) == (pmp_base[i] & ~pmp_mask[i]);
      pma_napot_hit = (req_addr & ~pma_mask[i]) == (pma_base[i] & ~pma_mask[i]);
      // TOR：上一项基址 <= paddr < 本项基址；第 0 项没有上一项，下界为 0（恒成立）
      pmp_tor_hit = (req_addr < pmp_base[i]) && (i == 0 || req_addr >= pmp_base[(i == 0) ? 0 : i-1]);
      pma_tor_hit = (req_addr < pma_base[i]) && (i == 0 || req_addr >= pma_base[(i == 0) ? 0 : i-1]);
      pmp_match[i] = (pmp_a[i][1] ? pmp_napot_hit : (pmp_a[i] == 2'b01) && pmp_tor_hit) && debug_range_ok;
      pma_match[i] = (pma_a[i][1] ? pma_napot_hit : (pma_a[i] == 2'b01) && pma_tor_hit) && debug_range_ok;
    end
  end

  // 每项"若命中则生效"的权限。PMP：M 态且未锁定则 rwx 全放行。
  // 下标 NUM_ENTRY 是 PMP 缺省项（M 态全放行，否则全禁止）；PMA 缺省项全 0，不占位置。
  logic                 pass_through;
  logic [NUM_ENTRY:0]   pmp_eff_x, pmp_eff_w, pmp_eff_r;

  assign pass_through = env_mode[1];   // mode > 1，即 M 态

  always_comb begin
    for (int i = 0; i < NUM_ENTRY; i++) begin
      logic ignore;
      ignore       = pass_through && !pmp_l[i];
      pmp_eff_x[i] = pmp_x[i] || ignore;
      pmp_eff_w[i] = pmp_w[i] || ignore;
      pmp_eff_r[i] = pmp_r[i] || ignore;
    end
    pmp_eff_x[NUM_ENTRY] = pass_through;
    pmp_eff_w[NUM_ENTRY] = pass_through;
    pmp_eff_r[NUM_ENTRY] = pass_through;
  end

  // ---------------------------------------------------------------------------
  // §1 -> §2 之间的可选一拍（LEAVE_HIT_MUX）
  //   sel_* 是送进优先级选择的那一份：直通，或者打过一拍的。
  // ---------------------------------------------------------------------------
  logic [NUM_ENTRY-1:0] sel_pmp_match, sel_pma_match;
  logic [NUM_ENTRY:0]   sel_pmp_x, sel_pmp_w, sel_pmp_r;
  logic [NUM_ENTRY-1:0] sel_pma_c, sel_pma_atomic, sel_pma_x, sel_pma_w, sel_pma_r;
  logic [2:0]           sel_cmd;

  if (LEAVE_HIT_MUX) begin : g_hitmux
    // 命中位：异步复位成 0（复位后、第一次请求前，选中的是缺省项/最后一项）
    logic [NUM_ENTRY-1:0] pmp_match_q, pma_match_q;
    // 权限与 cmd：不复位
    logic [NUM_ENTRY:0]   pmp_x_q, pmp_w_q, pmp_r_q;
    logic [NUM_ENTRY-1:0] pma_c_q, pma_atomic_q, pma_x_q, pma_w_q, pma_r_q;
    logic [2:0]           cmd_q;

    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        pmp_match_q <= '0;
        pma_match_q <= '0;
      end else if (req_valid) begin
        pmp_match_q <= pmp_match;
        pma_match_q <= pma_match;
      end
    end

    always_ff @(posedge clock) begin
      if (req_valid) begin
        pmp_x_q      <= pmp_eff_x;
        pmp_w_q      <= pmp_eff_w;
        pmp_r_q      <= pmp_eff_r;
        pma_c_q      <= pma_c;
        pma_atomic_q <= pma_atomic;
        pma_x_q      <= pma_x;
        pma_w_q      <= pma_w;
        pma_r_q      <= pma_r;
        cmd_q        <= req_cmd;
      end
    end

    assign sel_pmp_match  = pmp_match_q;
    assign sel_pma_match  = pma_match_q;
    assign sel_pmp_x      = pmp_x_q;
    assign sel_pmp_w      = pmp_w_q;
    assign sel_pmp_r      = pmp_r_q;
    assign sel_pma_c      = pma_c_q;
    assign sel_pma_atomic = pma_atomic_q;
    assign sel_pma_x      = pma_x_q;
    assign sel_pma_w      = pma_w_q;
    assign sel_pma_r      = pma_r_q;
    assign sel_cmd        = cmd_q;
  end else begin : g_direct
    assign sel_pmp_match  = pmp_match;
    assign sel_pma_match  = pma_match;
    assign sel_pmp_x      = pmp_eff_x;
    assign sel_pmp_w      = pmp_eff_w;
    assign sel_pmp_r      = pmp_eff_r;
    assign sel_pma_c      = pma_c;
    assign sel_pma_atomic = pma_atomic;
    assign sel_pma_x      = pma_x;
    assign sel_pma_w      = pma_w;
    assign sel_pma_r      = pma_r;
    assign sel_cmd        = req_cmd;
  end

  // ---------------------------------------------------------------------------
  // §2 优先级选择：下标最小的命中项胜出，否则缺省项
  // ---------------------------------------------------------------------------
  logic hit_pmp_x, hit_pmp_w, hit_pmp_r;
  logic hit_pma_c, hit_pma_atomic, hit_pma_x, hit_pma_w, hit_pma_r;

  always_comb begin
    // 从缺省项起，下标由大到小覆盖 —— 最后写入的（下标最小的命中项）生效
    hit_pmp_x = sel_pmp_x[NUM_ENTRY];
    hit_pmp_w = sel_pmp_w[NUM_ENTRY];
    hit_pmp_r = sel_pmp_r[NUM_ENTRY];
    hit_pma_c      = 1'b0;
    hit_pma_atomic = 1'b0;
    hit_pma_x      = 1'b0;
    hit_pma_w      = 1'b0;
    hit_pma_r      = 1'b0;
    for (int i = NUM_ENTRY - 1; i >= 0; i--) begin
      if (sel_pmp_match[i]) begin
        hit_pmp_x = sel_pmp_x[i];
        hit_pmp_w = sel_pmp_w[i];
        hit_pmp_r = sel_pmp_r[i];
      end
      if (sel_pma_match[i]) begin
        hit_pma_c      = sel_pma_c[i];
        hit_pma_atomic = sel_pma_atomic[i];
        hit_pma_x      = sel_pma_x[i];
        hit_pma_w      = sel_pma_w[i];
        hit_pma_r      = sel_pma_r[i];
      end
    end
  end

  // ---------------------------------------------------------------------------
  // §3 按访问类型判违例
  //   cmd[1:0]：00 读 / 01 写 / 10 取指；cmd[2] 标原子：100 = lr，101 = sc/amo；111 = HLVX（读+执行）
  // ---------------------------------------------------------------------------
  logic is_read, is_write, is_exec, is_read_exec, is_amo;
  logic chk_ld, chk_st, chk_instr, chk_mmio, chk_atomic;

  assign is_read      = sel_cmd[1:0] == 2'b00;
  assign is_write     = sel_cmd[1:0] == 2'b01;
  assign is_exec      = sel_cmd[1:0] == 2'b10;
  assign is_read_exec = sel_cmd == CMD_READ_EXEC;
  assign is_amo       = sel_cmd == CMD_ATOM_WRITE;

  always_comb begin
    logic pmp_ld, pmp_st, pmp_instr;
    logic pma_ld, pma_st, pma_instr;
    // PMP：缺读 / 写 / 执行权限
    pmp_ld    = (is_read || is_read_exec) && !is_amo && !hit_pmp_r;
    pmp_st    = (is_write || is_amo) && !hit_pmp_w;
    pmp_instr = (is_exec || is_read_exec) && !hit_pmp_x;
    // PMA：同上，外加原子访问要求区域支持原子（lr 走 ld，sc/amo 走 st）
    pma_ld    = ((is_read || is_read_exec) && !hit_pma_r)
              || (sel_cmd == CMD_ATOM_READ && !hit_pma_atomic);
    pma_st    = is_amo ? (!hit_pma_atomic || !hit_pma_w) : (is_write && !hit_pma_w);
    pma_instr = (is_exec || is_read_exec) && !hit_pma_x;

    chk_ld     = pmp_ld || pma_ld;
    chk_st     = pmp_st || pma_st;
    chk_instr  = pmp_instr || pma_instr;
    chk_mmio   = !hit_pma_c;
    chk_atomic = hit_pma_atomic;
  end

  // ---------------------------------------------------------------------------
  // 输出：SAME_CYCLE / LEAVE_HIT_MUX 直接出；否则整体打一拍（req_valid 使能，不复位）
  // ---------------------------------------------------------------------------
  if (SAME_CYCLE || LEAVE_HIT_MUX) begin : g_resp_comb
    assign resp_ld     = chk_ld;
    assign resp_st     = chk_st;
    assign resp_instr  = chk_instr;
    assign resp_mmio   = chk_mmio;
    assign resp_atomic = chk_atomic;
  end else begin : g_resp_reg
    logic [4:0] chk_vec, resp_vec;
    assign chk_vec = {chk_atomic, chk_mmio, chk_instr, chk_st, chk_ld};
    for (genvar k = 0; k < 5; k++) begin : g_bit
      if (RESP_USED[k]) begin : g_used
        logic resp_q;
        always_ff @(posedge clock) begin
          if (req_valid) resp_q <= chk_vec[k];
        end
        assign resp_vec[k] = resp_q;
      end else begin : g_unused
        assign resp_vec[k] = 1'b0;
      end
    end
    assign {resp_atomic, resp_mmio, resp_instr, resp_st, resp_ld} = resp_vec;
  end

endmodule
