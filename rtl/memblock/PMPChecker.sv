// =============================================================================
// xs_PMPChecker_core —— PMP/PMA 物理地址权限与属性检查器（可读重写）
//
// 对应 Chisel: xiangshan.backend.fu.PMPChecker（trait PMPCheckMethod + PMACheckMethod）
//
// 角色：地址翻译链的“权限关卡”。ITLB/DTLB 完成虚实转换后，把物理地址 + 访问命令
// (读/写/取指/原子) 连同当前特权 mode 与一份 PMP/PMA 条目快照送进本模块，得到：
//   resp.ld    读访问越权（load access fault）
//   resp.st    写/原子访问越权（store access fault）
//   resp.instr 取指越权（instruction access fault）
//   resp.mmio  目标是不可缓存的 MMIO 区
//   resp.atomic 目标区域支持原子操作
//
// 算法（每周期对一个物理地址）：
//   1. 对 PMP/PMA 各 16 条目并行算 is_match（NAPOT 掩码匹配 / TOR 区间匹配）。
//   2. ParallelPriorityMux：序号最低的命中条目胜出（RISC-V PMP 优先级）；都不命中
//      则用“默认条目”——PMP 默认随 mode 放行(M 模式 passThrough)，PMA 默认全 0。
//   3. 用胜出条目的 r/w/x（PMP 还叠加 ignore：M 模式下未锁定条目视为放行）和访问
//      命令算出 ld/st/instr；PMA 额外给出 c(mmio) / atomic。
//   4. PMP 与 PMA 的 ld/st/instr 取“或”（任一拒绝即拒绝）。
//
// 简化前提（本配置 lgMaxSize=3 <= PlatformGrain=12）：匹配/对齐均与访问 size 无关，
//   aligned 恒为真，故无需 size 端口；torMatch/napotMatch 退化为简单地址比较/掩码。
//
// 两个变体（由 REGISTERED 参数区分，对应 Chisel sameCycle / leaveHitMux）：
//   REGISTERED=0 (golden PMPChecker)   ：纯组合，输出当拍给出（同周期检查）。
//   REGISTERED=1 (golden PMPChecker_10)：把“每条目匹配位 + 调整后 cfg + cmd”在
//                 io_req_valid 时打一拍，优先级选择与 resp 仍组合，输出延后一拍。
// =============================================================================
module xs_PMPChecker_core import xs_pmp_pkg::*; #(
  parameter bit REGISTERED = 1'b0
) (
  input  logic                       clock,
  input  logic                       reset,
  input  logic                       io_req_valid,        // REGISTERED=1 时作为打拍使能
  input  logic [PMP_ADDR_BITS-1:0]   io_req_bits_addr,    // 待检查物理地址(48 位)
  input  logic [2:0]                 io_req_bits_cmd,     // TlbCmd: 见下
  input  logic [1:0]                 io_check_env_mode,   // 当前特权模式 (M=3,S=1,U=0...)
  input  pmp_entry_t [NUM_PMP-1:0]   io_check_env_pmp,    // PMP 条目快照
  input  pmp_entry_t [NUM_PMA-1:0]   io_check_env_pma,    // PMA 条目快照
  output logic                       io_resp_ld,
  output logic                       io_resp_st,
  output logic                       io_resp_instr,
  output logic                       io_resp_mmio,
  output logic                       io_resp_atomic
);

  // ---- TlbCmd 编码（见 cache/mmu/MMUBundle.scala object TlbCmd）----
  //   read=000 write=001 exec=010   atom_read(lr)=100  atom_write(sc/amo)=101
  //   isRead = cmd[1:0]==00  isWrite = cmd[1:0]==01  isExec = cmd[1:0]==10
  //   isAmo  = cmd==101 (整 3 位)
  // M 模式判定：mode[1]（mode>1，即 mode∈{2,3}）。S/U 为 1/0。
  localparam logic [1:0] CMD_READ = 2'b00, CMD_WRITE = 2'b01, CMD_EXEC = 2'b10;

  // =========================================================================
  // 第 1 步：逐条目匹配 + 调整 cfg
  //
  // PMP：cfg_vec[i].rwx = pmp[i].rwx | ignore，其中 ignore = M 模式 && !locked
  //      （M 模式对未锁定条目放行——这正是 RISC-V “M 模式默认全权”的体现）。
  // PMA：cfg_vec[i] 直接取 pma[i]（aligned 恒真，无叠加），含 c/atomic。
  // “前一条目 compare_addr” 用于 TOR 下界；条目 0 的前一条目取全 0。
  // =========================================================================
  logic [NUM_PMP-1:0] pmp_match;   // 每条目是否命中
  logic [NUM_PMP-1:0] pmp_cfg_x, pmp_cfg_w, pmp_cfg_r;  // 调整后权限
  logic [NUM_PMA-1:0] pma_match;
  logic [NUM_PMA-1:0] pma_cfg_x, pma_cfg_w, pma_cfg_r, pma_cfg_c, pma_cfg_atomic;

  wire mode_is_m = io_check_env_mode[1];

  always_comb begin
    logic [PMP_ADDR_BITS-1:0] prev_cmp;
    // ----- PMP -----
    prev_cmp = '0;  // 条目 0 的“前一条目” compare_addr = 0
    for (int i = 0; i < NUM_PMP; i++) begin
      automatic pmp_entry_t e = io_check_env_pmp[i];
      automatic logic ignore = mode_is_m & ~e.cfg.l;
      pmp_match[i] = xs_is_match(io_req_bits_addr, e.cfg, e.addr, e.mask, prev_cmp);
      pmp_cfg_x[i] = e.cfg.x | ignore;
      pmp_cfg_w[i] = e.cfg.w | ignore;
      pmp_cfg_r[i] = e.cfg.r | ignore;
      prev_cmp = xs_compare_addr(e.addr);  // 供下一条目作 TOR 下界
    end
    // ----- PMA -----
    prev_cmp = '0;
    for (int i = 0; i < NUM_PMA; i++) begin
      automatic pmp_entry_t e = io_check_env_pma[i];
      pma_match[i]      = xs_is_match(io_req_bits_addr, e.cfg, e.addr, e.mask, prev_cmp);
      pma_cfg_x[i]      = e.cfg.x;
      pma_cfg_w[i]      = e.cfg.w;
      pma_cfg_r[i]      = e.cfg.r;
      pma_cfg_c[i]      = e.cfg.c;
      pma_cfg_atomic[i] = e.cfg.atomic;
      prev_cmp = xs_compare_addr(e.addr);
    end
  end

  // =========================================================================
  // 可选打拍（leaveHitMux）：把匹配向量、调整后 cfg、cmd 在 io_req_valid 时寄存。
  // 默认条目对应的“都不命中”分支在组合逻辑里用全 0 匹配 + mode_is_m 兜底体现。
  // =========================================================================
  // 寄存/直通后的“每条目匹配位”（命名对齐 golden res_pmp_r/res_pma_r 便于 FM 配对）
  logic [NUM_PMP-1:0] res_pmp_r, s_pmp_x, s_pmp_w, s_pmp_r;
  logic [NUM_PMA-1:0] res_pma_r, s_pma_x, s_pma_w, s_pma_r, s_pma_c, s_pma_atomic;
  logic [2:0]         s_cmd;
  logic [1:0]         s_mode;

  generate
    if (REGISTERED) begin : g_reg
      // 与 golden 一致：匹配位 res_pmp_r/res_pma_r 用异步复位清零（leaveHitMux 的
      // RegEnable(_, false.B, valid) 带复位初值 0）。
      always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
          res_pmp_r <= '0;
          res_pma_r <= '0;
        end else if (io_req_valid) begin
          res_pmp_r <= pmp_match;
          res_pma_r <= pma_match;
        end
      end
      // 其余打拍寄存器(cfg 权限/属性、cmd、mode) 无复位（golden 的 RegEnable(cfg,valid)
      // 与 cmd 寄存均无 reset），仅 io_req_valid 时更新。
      always_ff @(posedge clock) begin
        if (io_req_valid) begin
          s_pmp_x      <= pmp_cfg_x;
          s_pmp_w      <= pmp_cfg_w;
          s_pmp_r      <= pmp_cfg_r;
          s_pma_x      <= pma_cfg_x;
          s_pma_w      <= pma_cfg_w;
          s_pma_r      <= pma_cfg_r;
          s_pma_c      <= pma_cfg_c;
          s_pma_atomic <= pma_cfg_atomic;
          s_cmd        <= io_req_bits_cmd;
          s_mode       <= io_check_env_mode;
        end
      end
    end else begin : g_comb
      assign res_pmp_r    = pmp_match;
      assign s_pmp_x      = pmp_cfg_x;
      assign s_pmp_w      = pmp_cfg_w;
      assign s_pmp_r      = pmp_cfg_r;
      assign res_pma_r    = pma_match;
      assign s_pma_x      = pma_cfg_x;
      assign s_pma_w      = pma_cfg_w;
      assign s_pma_r      = pma_cfg_r;
      assign s_pma_c      = pma_cfg_c;
      assign s_pma_atomic = pma_cfg_atomic;
      assign s_cmd        = io_req_bits_cmd;
      assign s_mode       = io_check_env_mode;
    end
  endgenerate

  // =========================================================================
  // 第 2 步：优先级选择（低序号优先）。
  // 用纯函数从“匹配向量 + 候选位向量”里挑出最低命中位对应的值；都不命中返回 dflt。
  // =========================================================================
  function automatic logic prio_sel(
      input logic [NUM_PMP-1:0] match, input logic [NUM_PMP-1:0] vec, input logic dflt);
    for (int i = 0; i < NUM_PMP; i++) if (match[i]) return vec[i];
    return dflt;
  endfunction

  // PMP 选出的 r/w/x：命中则取该条目调整后权限；全不命中取默认 = M 模式放行(mode[1])
  wire sel_pmp_r = prio_sel(res_pmp_r, s_pmp_r, s_mode[1]);
  wire sel_pmp_w = prio_sel(res_pmp_r, s_pmp_w, s_mode[1]);
  wire sel_pmp_x = prio_sel(res_pmp_r, s_pmp_x, s_mode[1]);
  // PMA 选出的属性：全不命中取默认 = 全 0（pmaDefault）
  wire sel_pma_r      = prio_sel(res_pma_r, s_pma_r,      1'b0);
  wire sel_pma_w      = prio_sel(res_pma_r, s_pma_w,      1'b0);
  wire sel_pma_x      = prio_sel(res_pma_r, s_pma_x,      1'b0);
  wire sel_pma_c      = prio_sel(res_pma_r, s_pma_c,      1'b0);
  wire sel_pma_atomic = prio_sel(res_pma_r, s_pma_atomic, 1'b0);

  // =========================================================================
  // 第 3 步：按命令算 resp（pmp_check / pma_check），PMP|PMA 合并。
  // =========================================================================
  wire is_read  = (s_cmd[1:0] == CMD_READ);
  wire is_write = (s_cmd[1:0] == CMD_WRITE);
  wire is_exec  = (s_cmd[1:0] == CMD_EXEC);
  wire is_amo   = (s_cmd == 3'b101);

  // PMP：ld=读且无 r；st=(写或原子)且无 w；instr=取指且无 x
  wire pmp_ld    = is_read  & ~is_amo & ~sel_pmp_r;
  wire pmp_st    = (is_write | is_amo) & ~sel_pmp_w;
  wire pmp_instr = is_exec  & ~sel_pmp_x;

  // PMA：ld=读且无 r；st=原子时(无 atomic 或无 w)，否则写时无 w；instr=取指且无 x
  //      mmio = 非 cacheable 且本身未越权（越权优先报 fault 而非 mmio）
  wire pma_ld    = is_read & ~sel_pma_r;
  wire pma_st    = is_amo  ? (~sel_pma_atomic | ~sel_pma_w)
                           : (is_write ? ~sel_pma_w : 1'b0);
  wire pma_instr = is_exec & ~sel_pma_x;
  wire pma_mmio  = ~sel_pma_c & ~(pma_ld | pma_st | pma_instr);

  assign io_resp_ld     = pmp_ld    | pma_ld;
  assign io_resp_st     = pmp_st    | pma_st;
  assign io_resp_instr  = pmp_instr | pma_instr;
  assign io_resp_mmio   = pma_mmio;
  assign io_resp_atomic = sel_pma_atomic;

  // 抑制未用信号 lint（reset 在组合变体未用）
  wire _unused = &{1'b0, reset};

endmodule
