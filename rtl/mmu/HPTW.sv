// HPTW.sv —— 客户机页表走表器（Hypervisor Page Table Walker）：H 扩展下的 G 阶段（第二阶段）
// 地址翻译，把客户机物理地址 gpaddr 经 hgatp 指向的页表翻成主机物理地址。
//
// 本文件含：xs_HPTW_core（可读重写核）+ HPTW（golden 同名 wrapper，79 端口透传）。
// 共享类型/PTE 判定函数来自 rtl/mmu/mmu_common_pkg.sv 的 xs_mmu_common_pkg。
// 对应 Chisel: xiangshan.cache.mmu.HPTW（PageTableWalker.scala 第 1187 行起）；
// 对照 golden = G1-canonical/golden-rtl/HPTW.sv（545 行，单变体）。
//
// 【它在 L2TLB 里的位置】
//   PTW / LLPTW 在两阶段翻译（allStage / onlyStage2）时，每读到一个中间 PTE 的地址都
//   是客户机物理地址，要先经本模块翻成主机物理地址才能真正访存。
//   L2TLB 用 hptw_req_arb 把 PTW 与 LLPTW 的请求仲裁给本模块（一次只服务一个），
//   本模块走完后把 HptwResp 回给 L2TLB 再分发回请求者，并同时把结果送 PtwCache 回填。
//
// 【一次走表（golden 的 s/w 状态位序列）】
//   idle ──req.fire──▶ s_pmp_check=0 ──发 PMP──▶ s_mem_req=0 ──mem.req.fire──▶ w_mem_resp=0
//        ──mem.resp──▶ (bitmap 使能：先 whether_need_bitmap_check → 叶子且无 gpf 时
//                        s_bitmap_check=0 → bitmap.req.fire → w_bitmap_resp=0 → bitmap.resp)
//        ──▶ mem_addr_update=1 ──非叶子且无故障──▶ level-1，回到发 PMP
//                                 ──叶子/故障──────▶ resp_valid，resp.fire 后回 idle
//   状态位是 Chisel 惯用的"s_ = 已发 / w_ = 已等到"反相编码：1 表示"此步不需做"。
//
// 【入口有两种请求】
//   · 普通走表（jmp_bitmap_check=0）：从 PtwCache 命中的最深一级往下走，
//     level/af_level 由 l3Hit/l2Hit/l1Hit 决定；hgatp.mode==Sv48 时才承认 l3Hit。
//   · bitmap 跳转（jmp_bitmap_check=1，G1 新增）：PtwCache 已经命中叶子（l0 或 sp），
//     只是还欠一次 bitmap 检查——把命中的 PTE 锁进 cache_pte_*，直接进 s_bitmap_check。
//
// 【地址生成（getVpnn / MakeGPAddr，照 golden 的位片）】
//   根级（Sv48 af_level==3 / Sv39 af_level==2）：hgatp.ppn<<12 + vpn 的顶层 11 位<<3
//   其余级：{ppn, vpn 第 level 级 9 位片, 3'b0}，ppn 取"该级在 PtwCache 已命中则用请求
//   带来的 req_ppn，否则用刚读回的 pte.ppn"——注意选择用 af_level 而不是 level。
//
// 【故障优先级】accessFault（PMP）> pageFault（gpf）> ppn_af（ppn 越界或 bitmap 检查失败）
//   gaf 时响应里的 ppn/perm/pbmt/n 全清 0（resp_pte = 0），只留 tag/vmid/level。
//
// 【复位域（golden 实测）】
//   异步复位：level/af_level（复位值 3）、6 个 s_/w_ 状态位、idle、mem_addr_update、
//   whether_need_bitmap_check、bitmap_checkfailed、way_info_REG。
//   不复位：gpaddr、req_ppn、l3Hit/l2Hit/l1Hit/bypassed、jmp_bitmap_check/fromSP、
//   cache_pte_*（★没有 rsw 字段——golden 只锁了用得到的位，多存两位就是两个 unread 寄存器★）、
//   accessFault、id、source、way_info_r、cache_hitway、cache_level。
//
// 【复用规则与命名】
//   寄存器沿用 golden 名字（level / af_level / s_pmp_check …），FM 可按名配对；
//   组合中间量按语义命名（req_fire / walk_req / jmp_req / mem_resp_take …），
//   头注释里逐个注明对应 golden 的 _GEN_ 编号，方便对照。
module xs_HPTW_core
  import xs_mmu_common_pkg::*;
(
  // BEGIN GENERATED(core_ports) —— 由 gen_mmu5.py 从 golden 端口表逐根抄出
  input  logic         clock,
  input  logic         reset,
  input  logic         io_sfence_valid,
  input  logic         io_csr_satp_changed,
  input  logic         io_csr_vsatp_changed,
  input  logic [3:0]   io_csr_hgatp_mode,
  input  logic [15:0]  io_csr_hgatp_vmid,
  input  logic [43:0]  io_csr_hgatp_ppn,
  input  logic         io_csr_hgatp_changed,
  input  logic         io_csr_mbmc_BME,
  input  logic         io_csr_mbmc_CMODE,
  input  logic         io_csr_priv_virt_changed,
  input  logic         io_csr_mPBMTE,
  output logic         io_req_ready,
  input  logic         io_req_valid,
  input  logic [1:0]   io_req_bits_source,
  input  logic [2:0]   io_req_bits_id,
  input  logic [37:0]  io_req_bits_gvpn,
  input  logic [35:0]  io_req_bits_ppn,
  input  logic         io_req_bits_l3Hit,
  input  logic         io_req_bits_l2Hit,
  input  logic         io_req_bits_l1Hit,
  input  logic         io_req_bits_bypassed,
  input  logic         io_req_bits_bitmapCheck_jmp_bitmap_check,
  input  logic [63:0]  io_req_bits_bitmapCheck_pte,
  input  logic [63:0]  io_req_bits_bitmapCheck_ptes_0,
  input  logic [63:0]  io_req_bits_bitmapCheck_ptes_1,
  input  logic [63:0]  io_req_bits_bitmapCheck_ptes_2,
  input  logic [63:0]  io_req_bits_bitmapCheck_ptes_3,
  input  logic [63:0]  io_req_bits_bitmapCheck_ptes_4,
  input  logic [63:0]  io_req_bits_bitmapCheck_ptes_5,
  input  logic [63:0]  io_req_bits_bitmapCheck_ptes_6,
  input  logic [63:0]  io_req_bits_bitmapCheck_ptes_7,
  input  logic [3:0]   io_req_bits_bitmapCheck_hitway,
  input  logic         io_req_bits_bitmapCheck_fromSP,
  input  logic [1:0]   io_req_bits_bitmapCheck_SPlevel,
  input  logic         io_resp_ready,
  output logic         io_resp_valid,
  output logic [37:0]  io_resp_bits_resp_entry_tag,
  output logic [13:0]  io_resp_bits_resp_entry_vmid,
  output logic         io_resp_bits_resp_entry_n,
  output logic [1:0]   io_resp_bits_resp_entry_pbmt,
  output logic [37:0]  io_resp_bits_resp_entry_ppn,
  output logic         io_resp_bits_resp_entry_perm_d,
  output logic         io_resp_bits_resp_entry_perm_a,
  output logic         io_resp_bits_resp_entry_perm_g,
  output logic         io_resp_bits_resp_entry_perm_u,
  output logic         io_resp_bits_resp_entry_perm_x,
  output logic         io_resp_bits_resp_entry_perm_w,
  output logic         io_resp_bits_resp_entry_perm_r,
  output logic [1:0]   io_resp_bits_resp_entry_level,
  output logic         io_resp_bits_resp_gpf,
  output logic         io_resp_bits_resp_gaf,
  output logic [3:0]   io_resp_bits_id,
  input  logic         io_mem_req_ready,
  output logic         io_mem_req_valid,
  output logic [47:0]  io_mem_req_bits_addr,
  output logic         io_mem_req_bits_hptw_bypassed,
  input  logic         io_mem_resp_valid,
  input  logic [63:0]  io_mem_resp_bits,
  input  logic         io_mem_mask,
  output logic [37:0]  io_refill_req_info_vpn,
  output logic [1:0]   io_refill_req_info_source,
  output logic [1:0]   io_refill_level,
  output logic [47:0]  io_pmp_req_bits_addr,
  input  logic         io_pmp_resp_ld,
  input  logic         io_pmp_resp_mmio,
  input  logic         io_bitmap_req_ready,
  output logic         io_bitmap_req_valid,
  output logic [35:0]  io_bitmap_req_bits_bmppn,
  output logic [37:0]  io_bitmap_req_bits_vpn,
  output logic [1:0]   io_bitmap_req_bits_level,
  output logic [3:0]   io_bitmap_req_bits_way_info,
  output logic         io_bitmap_req_bits_hptw_bypassed,
  output logic         io_bitmap_req_bits_n,
  output logic         io_bitmap_resp_ready,
  input  logic         io_bitmap_resp_valid,
  input  logic         io_bitmap_resp_bits_cf,
  input  logic [3:0]   io_l0_way_info
  // END GENERATED(core_ports)
);

  // ===========================================================================
  // §1 全局控制：flush、bitmap 使能、hgatp 模式
  // ===========================================================================
  logic flush;          // 任一栅栏/CSR 变化都把走表器打回 idle
  logic bitmap_enable;  // mbmc.BME=1 且 CMODE=0 才做 bitmap 检查
  logic is_sv48;        // hgatp.mode == Sv48（golden _GEN_1）

  assign flush = io_sfence_valid | io_csr_hgatp_changed | io_csr_satp_changed
               | io_csr_vsatp_changed | io_csr_priv_virt_changed;
  assign bitmap_enable = io_csr_mbmc_BME & ~io_csr_mbmc_CMODE;
  assign is_sv48       = (io_csr_hgatp_mode == MODE_SV48);

  // ===========================================================================
  // §2 寄存器声明（分两个复位域，见文件头）
  // ===========================================================================
  // ---- 异步复位域 ----
  logic [1:0] level;                      // 当前正在读的页表级（3=根级）
  logic [1:0] af_level;                   // access fault 时回报的级；也用来选地址（见 §3）
  logic       s_pmp_check;                // 0 = 还没把本级地址送 PMP
  logic       s_mem_req;                  // 0 = 还没发本级访存请求
  logic       w_mem_resp;                 // 0 = 正在等访存响应
  logic       idle;
  logic       mem_addr_update;            // 1 = 本级 PTE 已到手，决定"再下一级"还是"回应"
  logic       s_bitmap_check;             // 0 = 还没发 bitmap 检查请求
  logic       w_bitmap_resp;              // 0 = 正在等 bitmap 响应
  logic       whether_need_bitmap_check;  // 访存响应到了、还没判要不要做 bitmap 检查
  logic       bitmap_checkfailed;         // bitmap 检查失败 → 按 access fault 处理
  logic       way_info_REG;               // RegNext(io.mem.resp.fire)，DataHoldBypass 的 valid
  // ---- 不复位域 ----
  logic [49:0] gpaddr;                    // {gvpn, 12'h0}：被翻译的客户机物理地址
  logic [35:0] req_ppn;                   // PtwCache 已命中的那一级给出的 ppn
  logic        l3Hit, l2Hit, l1Hit;       // 请求进来时各级是否已在 PtwCache 命中
  logic        bypassed;                  // 1 = 结果不回填 PtwCache
  logic        jmp_bitmap_check;          // 本次是 bitmap 跳转请求
  logic        fromSP;                    // 跳转的 PTE 来自 sp（大页）而非 l0
  logic        cache_pte_n;               // 跳转请求锁住的 PTE（★无 rsw 字段★）
  logic [1:0]  cache_pte_pbmt;
  logic [6:0]  cache_pte_reserved;
  logic [7:0]  cache_pte_ppn_high;
  logic [35:0] cache_pte_ppn;
  pte_perm_t   cache_pte_perm;
  logic        accessFault;               // RegEnable(pmp.ld | pmp.mmio, sent_to_pmp)
  logic [2:0]  id;                        // 请求者的 LLPTW/PTW id
  logic [1:0]  source;
  logic [3:0]  way_info_r;                // DataHoldBypass 的保持寄存器
  logic [3:0]  cache_hitway;              // 跳转请求带来的 l0 命中路
  logic [1:0]  cache_level;               // 跳转请求带来的 sp 级别

  // ===========================================================================
  // §3 当前 PTE、页故障判定与访存地址
  // ===========================================================================
  pte_t  mem_pte;   // 访存响应按位图解释
  pte_t  pte;       // 跳转请求用锁住的那份，否则用刚读回的
  assign mem_pte = pte_t'(io_mem_resp_bits);
  always_comb begin
    pte = mem_pte;
    if (jmp_bitmap_check) begin
      pte.n        = cache_pte_n;
      pte.pbmt     = cache_pte_pbmt;
      pte.reserved = cache_pte_reserved;
      pte.ppn_high = cache_pte_ppn_high;
      pte.ppn      = cache_pte_ppn;
      pte.perm     = cache_pte_perm;
    end
  end

  logic [GVPN_W-1:0] vpn;
  assign vpn = gpaddr[GPADDR_W-1:OFF_W];

  // 本级 ppn：该级已在 PtwCache 命中就用请求带来的 req_ppn，否则用读回的 pte.ppn。
  // ★选择依据是 af_level，不是 level★（golden _GEN）；Sv39 下没有 l3 这一级。
  logic        level_hit_in_cache;
  logic [35:0] walk_ppn;
  assign level_hit_in_cache = is_sv48
      ? ((af_level == 2'd2) ? l3Hit : (af_level == 2'd1) ? l2Hit : l1Hit)
      : ((af_level == 2'd1) ? l2Hit : l1Hit);
  assign walk_ppn = level_hit_in_cache ? req_ppn : pte.ppn;

  // 根级页表基址：MakeGPAddr(hgatp.ppn, getGVpnn(vpn, 3/2, mode))，截到 48 位
  logic [47:0] hgatp_base;
  logic [47:0] pg_base_sv48, pg_base_sv39;
  logic [47:0] p_pte;      // MakeAddr(walk_ppn, getVpnn(vpn, level))
  logic [47:0] mem_addr;
  assign hgatp_base   = {io_csr_hgatp_ppn[35:0], 12'h0};
  assign pg_base_sv48 = 48'(hgatp_base + {34'h0, vpn[37:27], 3'h0});
  assign pg_base_sv39 = 48'(hgatp_base + {34'h0, vpn[28:18], 3'h0});
  assign p_pte        = {walk_ppn, vpn_slice(vpn, level), 3'h0};
  assign mem_addr     = is_sv48 ? ((af_level == 2'd3) ? pg_base_sv48 : p_pte)
                                : ((af_level == 2'd2) ? pg_base_sv39 : p_pte);

  // 故障判定
  logic pageFault;   // G 阶段页故障，或走到最底层还不是叶子
  logic ppn_af;      // ppn 越界；bitmap 使能时 bitmap 检查失败也算
  logic find_pte;    // 本级读回的 PTE 已经能给出结论（叶子或任一故障）
  assign pageFault = pte_is_gpf(pte, level, io_csr_mPBMTE) | (~pte_is_leaf(pte) & (level == 2'd0));
  assign ppn_af    = bitmap_enable ? (pte_is_af(pte) | bitmap_checkfailed) : pte_is_af(pte);
  assign find_pte  = pte_is_leaf(pte) | ppn_af | pageFault;

  // ===========================================================================
  // §4 握手与事件（每个都注明 golden 里的 _GEN_ 编号）
  // ===========================================================================
  logic req_fire;          // idle & io_req_valid           （_cache_level_T）
  logic jmp_req;           // 进来的是 bitmap 跳转请求       （_GEN_3）
  logic walk_req;          // 进来的是普通走表请求           （_GEN_4 / _GEN_5）
  logic sent_to_pmp;       // 本拍把 mem_addr 送 PMP 检查
  logic resp_valid;
  logic resp_fire;         // （_GEN_8）
  logic finish;            // 响应被接走，本次走表结束
  logic mem_req_fire;      // （_GEN_12）
  logic mem_resp_take;     // 收下访存响应                   （_GEN_13）
  logic need_bitmap_now;   // bitmap 使能 & 叶子 & 无 gpf     （_GEN_14）
  logic bitmap_req_fire;   // （_GEN_15）
  logic bitmap_resp_fire;  // （_GEN_16）
  logic af_active;         // accessFault & ~idle            （_GEN_11）
  logic step_down;         // mem_addr_update & 还没找到 PTE → 再下一级（_GEN_17）
  logic io_mem_req_valid_0;

  assign req_fire         = idle & io_req_valid;
  assign jmp_req          = req_fire & io_req_bits_bitmapCheck_jmp_bitmap_check;
  assign walk_req         = req_fire & ~io_req_bits_bitmapCheck_jmp_bitmap_check;
  assign sent_to_pmp      = ~idle & (~s_pmp_check | mem_addr_update) & ~finish;
  assign resp_valid       = ~idle & mem_addr_update
                          & ((w_mem_resp & find_pte) | (s_pmp_check & accessFault));
  assign resp_fire        = io_resp_ready & resp_valid;
  assign finish           = mem_addr_update & (find_pte | accessFault) & resp_valid;
  assign io_mem_req_valid_0 = ~s_mem_req & ~io_mem_mask & ~accessFault & s_pmp_check;
  assign mem_req_fire     = io_mem_req_ready & io_mem_req_valid_0;
  assign mem_resp_take    = io_mem_resp_valid & ~w_mem_resp;
  assign need_bitmap_now  = bitmap_enable & pte_is_leaf(pte) & ~pageFault;
  assign bitmap_req_fire  = io_bitmap_req_ready & ~s_bitmap_check;
  assign bitmap_resp_fire = ~w_bitmap_resp & io_bitmap_resp_valid;
  assign af_active        = accessFault & ~idle;
  assign step_down        = mem_addr_update & ~(find_pte | accessFault);

  // 普通走表的起始级：从 PtwCache 命中的最深一级往下一级开始（golden _GEN_9）
  logic [1:0] entry_level;
  assign entry_level = io_req_bits_l1Hit ? 2'd0
                     : io_req_bits_l2Hit ? 2'd1
                     : is_sv48           ? {1'b1, ~io_req_bits_l3Hit}   // l3Hit ? 2 : 3
                                         : 2'd2;

  // ===========================================================================
  // §5 状态机（异步复位域）—— 按 Chisel 的 when 顺序转写，后写者赢
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      level                     <= 2'd3;
      af_level                  <= 2'd3;
      s_pmp_check               <= 1'b1;
      s_mem_req                 <= 1'b1;
      w_mem_resp                <= 1'b1;
      idle                      <= 1'b1;
      mem_addr_update           <= 1'b0;
      s_bitmap_check            <= 1'b1;
      w_bitmap_resp             <= 1'b1;
      whether_need_bitmap_check <= 1'b0;
      bitmap_checkfailed        <= 1'b0;
      way_info_REG              <= 1'b0;
    end else begin
      // 接收请求
      if (jmp_req) begin
        idle           <= 1'b0;
        s_bitmap_check <= 1'b0;
        level          <= io_req_bits_bitmapCheck_fromSP ? io_req_bits_bitmapCheck_SPlevel : 2'd0;
      end
      if (walk_req) begin
        idle        <= 1'b0;
        s_pmp_check <= 1'b0;
        level       <= entry_level;
        af_level    <= entry_level;
      end
      // 地址送 PMP 的同一拍，标记"该发访存了"
      if (sent_to_pmp & ~mem_addr_update) begin
        s_mem_req   <= 1'b0;
        s_pmp_check <= 1'b1;
      end
      // PMP 报 access fault：跳过访存，直接进入回应
      if (af_active) begin
        s_pmp_check               <= 1'b1;
        s_mem_req                 <= 1'b1;
        w_mem_resp                <= 1'b1;
        mem_addr_update           <= 1'b1;
        s_bitmap_check            <= 1'b1;
        w_bitmap_resp             <= 1'b1;
        whether_need_bitmap_check <= 1'b0;
        bitmap_checkfailed        <= 1'b0;
      end
      if (mem_req_fire) begin
        s_mem_req  <= 1'b1;
        w_mem_resp <= 1'b0;
      end
      if (mem_resp_take) begin
        w_mem_resp <= 1'b1;
        af_level   <= 2'(af_level - 2'd1);
        if (bitmap_enable) begin
          whether_need_bitmap_check <= 1'b1;
        end else begin
          mem_addr_update           <= 1'b1;
          whether_need_bitmap_check <= 1'b0;
        end
      end
      // 访存响应到手后一拍：叶子且无 gpf 才去做 bitmap 检查，否则直接进入判定
      if (whether_need_bitmap_check) begin
        if (need_bitmap_now) begin
          s_bitmap_check            <= 1'b0;
          whether_need_bitmap_check <= 1'b0;
        end else begin
          mem_addr_update           <= 1'b1;
          whether_need_bitmap_check <= 1'b0;
        end
      end
      if (bitmap_req_fire) begin
        s_bitmap_check <= 1'b1;
        w_bitmap_resp  <= 1'b0;
      end
      if (bitmap_resp_fire) begin
        w_bitmap_resp      <= 1'b1;
        mem_addr_update    <= 1'b1;
        bitmap_checkfailed <= io_bitmap_resp_bits_cf;
      end
      // 判定：再下一级，或回应
      if (mem_addr_update) begin
        if (~(find_pte | accessFault)) begin
          level           <= 2'(level - 2'd1);
          s_mem_req       <= 1'b0;
          mem_addr_update <= 1'b0;
        end else if (resp_valid) begin
          if (resp_fire) begin
            idle               <= 1'b1;
            mem_addr_update    <= 1'b0;
            bitmap_checkfailed <= 1'b0;
          end
        end
      end
      if (flush) begin
        idle                      <= 1'b1;
        s_pmp_check               <= 1'b1;
        s_mem_req                 <= 1'b1;
        w_mem_resp                <= 1'b1;
        mem_addr_update           <= 1'b0;
        s_bitmap_check            <= 1'b1;
        w_bitmap_resp             <= 1'b1;
        whether_need_bitmap_check <= 1'b0;
        bitmap_checkfailed        <= 1'b0;
      end
      // io.mem.resp 是 ValidIO，fire 就是 valid
      way_info_REG <= io_mem_resp_valid;
    end
  end

  // ===========================================================================
  // §6 载荷寄存器（不复位域）
  // ===========================================================================
  // 跳转请求锁住的 PTE：fromSP 用单条 pte，否则从 8 条相邻 PTE 里按 gvpn[2:0] 选一条
  logic [63:0] jmp_pte_bits;
  pte_t        jmp_pte;
  always_comb begin
    case (io_req_bits_gvpn[SECTOR_W-1:0])
      3'd0: jmp_pte_bits = io_req_bits_bitmapCheck_ptes_0;
      3'd1: jmp_pte_bits = io_req_bits_bitmapCheck_ptes_1;
      3'd2: jmp_pte_bits = io_req_bits_bitmapCheck_ptes_2;
      3'd3: jmp_pte_bits = io_req_bits_bitmapCheck_ptes_3;
      3'd4: jmp_pte_bits = io_req_bits_bitmapCheck_ptes_4;
      3'd5: jmp_pte_bits = io_req_bits_bitmapCheck_ptes_5;
      3'd6: jmp_pte_bits = io_req_bits_bitmapCheck_ptes_6;
      default: jmp_pte_bits = io_req_bits_bitmapCheck_ptes_7;
    endcase
    jmp_pte = pte_t'(io_req_bits_bitmapCheck_fromSP ? io_req_bits_bitmapCheck_pte : jmp_pte_bits);
  end

  always_ff @(posedge clock) begin
    if (req_fire) begin
      gpaddr             <= {io_req_bits_gvpn, 12'h0};
      jmp_bitmap_check   <= io_req_bits_bitmapCheck_jmp_bitmap_check;
      fromSP             <= io_req_bits_bitmapCheck_fromSP;
      cache_pte_n        <= jmp_pte.n;
      cache_pte_pbmt     <= jmp_pte.pbmt;
      cache_pte_reserved <= jmp_pte.reserved;
      cache_pte_ppn_high <= jmp_pte.ppn_high;
      cache_pte_ppn      <= jmp_pte.ppn;
      cache_pte_perm     <= jmp_pte.perm;
      source             <= io_req_bits_source;
      cache_hitway       <= io_req_bits_bitmapCheck_hitway;
      cache_level        <= io_req_bits_bitmapCheck_SPlevel;
      id                 <= io_req_bits_id;
    end
    if (walk_req) begin
      req_ppn  <= io_req_bits_ppn;
      l3Hit    <= is_sv48 & io_req_bits_l3Hit;   // Sv39 下没有 l3
      l2Hit    <= io_req_bits_l2Hit;
      l1Hit    <= io_req_bits_l1Hit;
      bypassed <= io_req_bits_bypassed;
    end
    // accessFault：RegEnable(pmp, sent_to_pmp)，被新请求 / 响应被接走 / flush 清 0
    if (sent_to_pmp)
      accessFault <= io_pmp_resp_ld | io_pmp_resp_mmio;
    if (walk_req)
      accessFault <= 1'b0;
    if (mem_addr_update & (find_pte | accessFault) & resp_valid & resp_fire)
      accessFault <= 1'b0;
    if (flush)
      accessFault <= 1'b0;
    // DataHoldBypass(io.l0_way_info, RegNext(mem.resp.fire)) 的保持寄存器
    if (way_info_REG)
      way_info_r <= io_l0_way_info;
  end

  // ===========================================================================
  // §7 输出装配
  // ===========================================================================
  // 响应：accessFault > pageFault > ppn_af；gaf 时 PTE 载荷全清
  logic        resp_gaf;
  logic [1:0]  resp_entry_level;
  logic [35:0] resp_pte_ppn;
  assign resp_gaf         = accessFault | (ppn_af & ~pageFault);
  assign resp_entry_level = accessFault ? af_level : level;
  assign resp_pte_ppn     = resp_gaf ? 36'h0 : pte.ppn;

  assign io_req_ready                   = idle;
  assign io_resp_valid                  = resp_valid;
  assign io_resp_bits_resp_entry_tag    = vpn;
  assign io_resp_bits_resp_entry_vmid   = io_csr_hgatp_vmid[13:0];
  assign io_resp_bits_resp_entry_n      = ~resp_gaf & pte.n & (resp_pte_ppn[3:0] == 4'd8)
                                        & (resp_entry_level == 2'd0);
  assign io_resp_bits_resp_entry_pbmt   = resp_gaf ? 2'h0 : pte.pbmt;
  assign io_resp_bits_resp_entry_ppn    = {2'h0, resp_pte_ppn};
  assign io_resp_bits_resp_entry_perm_d = ~resp_gaf & pte.perm.d;
  assign io_resp_bits_resp_entry_perm_a = ~resp_gaf & pte.perm.a;
  assign io_resp_bits_resp_entry_perm_g = ~resp_gaf & pte.perm.g;
  assign io_resp_bits_resp_entry_perm_u = ~resp_gaf & pte.perm.u;
  assign io_resp_bits_resp_entry_perm_x = ~resp_gaf & pte.perm.x;
  assign io_resp_bits_resp_entry_perm_w = ~resp_gaf & pte.perm.w;
  assign io_resp_bits_resp_entry_perm_r = ~resp_gaf & pte.perm.r;
  assign io_resp_bits_resp_entry_level  = resp_entry_level;
  assign io_resp_bits_resp_gpf          = pageFault & ~accessFault;
  assign io_resp_bits_resp_gaf          = resp_gaf;
  assign io_resp_bits_id                = {1'b0, id};

  assign io_mem_req_valid               = io_mem_req_valid_0;
  assign io_mem_req_bits_addr           = mem_addr;
  assign io_mem_req_bits_hptw_bypassed  = bypassed;

  assign io_refill_req_info_vpn         = vpn;
  assign io_refill_req_info_source      = source;
  assign io_refill_level                = level;

  assign io_pmp_req_bits_addr           = mem_addr;

  assign io_bitmap_req_valid            = ~s_bitmap_check;
  assign io_bitmap_req_bits_bmppn       = pte.ppn;
  assign io_bitmap_req_bits_vpn         = vpn;
  assign io_bitmap_req_bits_level       = jmp_bitmap_check ? (fromSP ? cache_level : 2'd0) : level;
  // DataHoldBypass：mem 响应后一拍直接旁路 l0_way_info，之后用保持寄存器
  assign io_bitmap_req_bits_way_info    = jmp_bitmap_check ? cache_hitway
                                        : way_info_REG     ? io_l0_way_info : way_info_r;
  assign io_bitmap_req_bits_hptw_bypassed = bypassed;
  assign io_bitmap_req_bits_n           = pte.n;
  assign io_bitmap_resp_ready           = ~w_bitmap_resp;

endmodule

// BEGIN GENERATED(wrapper) —— 由 gen_mmu5.py 生成：HPTW 的 golden 同名 wrapper，
// 端口与 G1 golden 逐位同名，纯透传到 xs_HPTW_core（无任何逻辑）。
module HPTW(
  input  logic         clock,
  input  logic         reset,
  input  logic         io_sfence_valid,
  input  logic         io_csr_satp_changed,
  input  logic         io_csr_vsatp_changed,
  input  logic [3:0]   io_csr_hgatp_mode,
  input  logic [15:0]  io_csr_hgatp_vmid,
  input  logic [43:0]  io_csr_hgatp_ppn,
  input  logic         io_csr_hgatp_changed,
  input  logic         io_csr_mbmc_BME,
  input  logic         io_csr_mbmc_CMODE,
  input  logic         io_csr_priv_virt_changed,
  input  logic         io_csr_mPBMTE,
  output logic         io_req_ready,
  input  logic         io_req_valid,
  input  logic [1:0]   io_req_bits_source,
  input  logic [2:0]   io_req_bits_id,
  input  logic [37:0]  io_req_bits_gvpn,
  input  logic [35:0]  io_req_bits_ppn,
  input  logic         io_req_bits_l3Hit,
  input  logic         io_req_bits_l2Hit,
  input  logic         io_req_bits_l1Hit,
  input  logic         io_req_bits_bypassed,
  input  logic         io_req_bits_bitmapCheck_jmp_bitmap_check,
  input  logic [63:0]  io_req_bits_bitmapCheck_pte,
  input  logic [63:0]  io_req_bits_bitmapCheck_ptes_0,
  input  logic [63:0]  io_req_bits_bitmapCheck_ptes_1,
  input  logic [63:0]  io_req_bits_bitmapCheck_ptes_2,
  input  logic [63:0]  io_req_bits_bitmapCheck_ptes_3,
  input  logic [63:0]  io_req_bits_bitmapCheck_ptes_4,
  input  logic [63:0]  io_req_bits_bitmapCheck_ptes_5,
  input  logic [63:0]  io_req_bits_bitmapCheck_ptes_6,
  input  logic [63:0]  io_req_bits_bitmapCheck_ptes_7,
  input  logic [3:0]   io_req_bits_bitmapCheck_hitway,
  input  logic         io_req_bits_bitmapCheck_fromSP,
  input  logic [1:0]   io_req_bits_bitmapCheck_SPlevel,
  input  logic         io_resp_ready,
  output logic         io_resp_valid,
  output logic [37:0]  io_resp_bits_resp_entry_tag,
  output logic [13:0]  io_resp_bits_resp_entry_vmid,
  output logic         io_resp_bits_resp_entry_n,
  output logic [1:0]   io_resp_bits_resp_entry_pbmt,
  output logic [37:0]  io_resp_bits_resp_entry_ppn,
  output logic         io_resp_bits_resp_entry_perm_d,
  output logic         io_resp_bits_resp_entry_perm_a,
  output logic         io_resp_bits_resp_entry_perm_g,
  output logic         io_resp_bits_resp_entry_perm_u,
  output logic         io_resp_bits_resp_entry_perm_x,
  output logic         io_resp_bits_resp_entry_perm_w,
  output logic         io_resp_bits_resp_entry_perm_r,
  output logic [1:0]   io_resp_bits_resp_entry_level,
  output logic         io_resp_bits_resp_gpf,
  output logic         io_resp_bits_resp_gaf,
  output logic [3:0]   io_resp_bits_id,
  input  logic         io_mem_req_ready,
  output logic         io_mem_req_valid,
  output logic [47:0]  io_mem_req_bits_addr,
  output logic         io_mem_req_bits_hptw_bypassed,
  input  logic         io_mem_resp_valid,
  input  logic [63:0]  io_mem_resp_bits,
  input  logic         io_mem_mask,
  output logic [37:0]  io_refill_req_info_vpn,
  output logic [1:0]   io_refill_req_info_source,
  output logic [1:0]   io_refill_level,
  output logic [47:0]  io_pmp_req_bits_addr,
  input  logic         io_pmp_resp_ld,
  input  logic         io_pmp_resp_mmio,
  input  logic         io_bitmap_req_ready,
  output logic         io_bitmap_req_valid,
  output logic [35:0]  io_bitmap_req_bits_bmppn,
  output logic [37:0]  io_bitmap_req_bits_vpn,
  output logic [1:0]   io_bitmap_req_bits_level,
  output logic [3:0]   io_bitmap_req_bits_way_info,
  output logic         io_bitmap_req_bits_hptw_bypassed,
  output logic         io_bitmap_req_bits_n,
  output logic         io_bitmap_resp_ready,
  input  logic         io_bitmap_resp_valid,
  input  logic         io_bitmap_resp_bits_cf,
  input  logic [3:0]   io_l0_way_info
);
  xs_HPTW_core u_core (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_sfence_valid                          (io_sfence_valid),
    .io_csr_satp_changed                      (io_csr_satp_changed),
    .io_csr_vsatp_changed                     (io_csr_vsatp_changed),
    .io_csr_hgatp_mode                        (io_csr_hgatp_mode),
    .io_csr_hgatp_vmid                        (io_csr_hgatp_vmid),
    .io_csr_hgatp_ppn                         (io_csr_hgatp_ppn),
    .io_csr_hgatp_changed                     (io_csr_hgatp_changed),
    .io_csr_mbmc_BME                          (io_csr_mbmc_BME),
    .io_csr_mbmc_CMODE                        (io_csr_mbmc_CMODE),
    .io_csr_priv_virt_changed                 (io_csr_priv_virt_changed),
    .io_csr_mPBMTE                            (io_csr_mPBMTE),
    .io_req_ready                             (io_req_ready),
    .io_req_valid                             (io_req_valid),
    .io_req_bits_source                       (io_req_bits_source),
    .io_req_bits_id                           (io_req_bits_id),
    .io_req_bits_gvpn                         (io_req_bits_gvpn),
    .io_req_bits_ppn                          (io_req_bits_ppn),
    .io_req_bits_l3Hit                        (io_req_bits_l3Hit),
    .io_req_bits_l2Hit                        (io_req_bits_l2Hit),
    .io_req_bits_l1Hit                        (io_req_bits_l1Hit),
    .io_req_bits_bypassed                     (io_req_bits_bypassed),
    .io_req_bits_bitmapCheck_jmp_bitmap_check (io_req_bits_bitmapCheck_jmp_bitmap_check),
    .io_req_bits_bitmapCheck_pte              (io_req_bits_bitmapCheck_pte),
    .io_req_bits_bitmapCheck_ptes_0           (io_req_bits_bitmapCheck_ptes_0),
    .io_req_bits_bitmapCheck_ptes_1           (io_req_bits_bitmapCheck_ptes_1),
    .io_req_bits_bitmapCheck_ptes_2           (io_req_bits_bitmapCheck_ptes_2),
    .io_req_bits_bitmapCheck_ptes_3           (io_req_bits_bitmapCheck_ptes_3),
    .io_req_bits_bitmapCheck_ptes_4           (io_req_bits_bitmapCheck_ptes_4),
    .io_req_bits_bitmapCheck_ptes_5           (io_req_bits_bitmapCheck_ptes_5),
    .io_req_bits_bitmapCheck_ptes_6           (io_req_bits_bitmapCheck_ptes_6),
    .io_req_bits_bitmapCheck_ptes_7           (io_req_bits_bitmapCheck_ptes_7),
    .io_req_bits_bitmapCheck_hitway           (io_req_bits_bitmapCheck_hitway),
    .io_req_bits_bitmapCheck_fromSP           (io_req_bits_bitmapCheck_fromSP),
    .io_req_bits_bitmapCheck_SPlevel          (io_req_bits_bitmapCheck_SPlevel),
    .io_resp_ready                            (io_resp_ready),
    .io_resp_valid                            (io_resp_valid),
    .io_resp_bits_resp_entry_tag              (io_resp_bits_resp_entry_tag),
    .io_resp_bits_resp_entry_vmid             (io_resp_bits_resp_entry_vmid),
    .io_resp_bits_resp_entry_n                (io_resp_bits_resp_entry_n),
    .io_resp_bits_resp_entry_pbmt             (io_resp_bits_resp_entry_pbmt),
    .io_resp_bits_resp_entry_ppn              (io_resp_bits_resp_entry_ppn),
    .io_resp_bits_resp_entry_perm_d           (io_resp_bits_resp_entry_perm_d),
    .io_resp_bits_resp_entry_perm_a           (io_resp_bits_resp_entry_perm_a),
    .io_resp_bits_resp_entry_perm_g           (io_resp_bits_resp_entry_perm_g),
    .io_resp_bits_resp_entry_perm_u           (io_resp_bits_resp_entry_perm_u),
    .io_resp_bits_resp_entry_perm_x           (io_resp_bits_resp_entry_perm_x),
    .io_resp_bits_resp_entry_perm_w           (io_resp_bits_resp_entry_perm_w),
    .io_resp_bits_resp_entry_perm_r           (io_resp_bits_resp_entry_perm_r),
    .io_resp_bits_resp_entry_level            (io_resp_bits_resp_entry_level),
    .io_resp_bits_resp_gpf                    (io_resp_bits_resp_gpf),
    .io_resp_bits_resp_gaf                    (io_resp_bits_resp_gaf),
    .io_resp_bits_id                          (io_resp_bits_id),
    .io_mem_req_ready                         (io_mem_req_ready),
    .io_mem_req_valid                         (io_mem_req_valid),
    .io_mem_req_bits_addr                     (io_mem_req_bits_addr),
    .io_mem_req_bits_hptw_bypassed            (io_mem_req_bits_hptw_bypassed),
    .io_mem_resp_valid                        (io_mem_resp_valid),
    .io_mem_resp_bits                         (io_mem_resp_bits),
    .io_mem_mask                              (io_mem_mask),
    .io_refill_req_info_vpn                   (io_refill_req_info_vpn),
    .io_refill_req_info_source                (io_refill_req_info_source),
    .io_refill_level                          (io_refill_level),
    .io_pmp_req_bits_addr                     (io_pmp_req_bits_addr),
    .io_pmp_resp_ld                           (io_pmp_resp_ld),
    .io_pmp_resp_mmio                         (io_pmp_resp_mmio),
    .io_bitmap_req_ready                      (io_bitmap_req_ready),
    .io_bitmap_req_valid                      (io_bitmap_req_valid),
    .io_bitmap_req_bits_bmppn                 (io_bitmap_req_bits_bmppn),
    .io_bitmap_req_bits_vpn                   (io_bitmap_req_bits_vpn),
    .io_bitmap_req_bits_level                 (io_bitmap_req_bits_level),
    .io_bitmap_req_bits_way_info              (io_bitmap_req_bits_way_info),
    .io_bitmap_req_bits_hptw_bypassed         (io_bitmap_req_bits_hptw_bypassed),
    .io_bitmap_req_bits_n                     (io_bitmap_req_bits_n),
    .io_bitmap_resp_ready                     (io_bitmap_resp_ready),
    .io_bitmap_resp_valid                     (io_bitmap_resp_valid),
    .io_bitmap_resp_bits_cf                   (io_bitmap_resp_bits_cf),
    .io_l0_way_info                           (io_l0_way_info)
  );
endmodule
// END GENERATED(wrapper)
