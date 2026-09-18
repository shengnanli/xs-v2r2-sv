// =============================================================================
// SSIT.sv —— Store Set Identifier Table（访存相关性预测器 store-set 表）
// -----------------------------------------------------------------------------
// 设计源: XiangShan src/main/scala/xiangshan/mem/mdp/StoreSet.scala (class SSIT)
// golden 对照: G1-canonical/golden-rtl/SSIT.sv（35,104 行，单变体）
// 层次位置: SimTop…backend.ctrlBlock.memCtrl.ssit
//
// ★ 它是什么 ★
// Chrysos&Emer 1998 的 store-set 算法。每条访存指令按 PC 折叠索引查一张 1024 项的
// 表，得到一个 store set id(ssid)。load 与 store 落进同一个 store set 就意味着
// 「历史上这两条撞过」，后端据此让 load 等 store。表由两块同步读存储承载：
//   valid_array : 1024×1bit  —— 该表项是否已分配 store set
//   data_array  : 1024×{ssid[4:0], strict} —— store set id 与「严格等待」标志
// 本模块自己只有控制逻辑：读口复用、三级更新流水、定期整表冲刷。
//
// ★ golden 的两个重要事实（先看这里，否则会读不懂本文件）★
// (1) **本模块没有任何输出端口**。Chisel 有 io.rdata(送 rename)，但 firtool
//     -O=release 把整条 rdata 链路当无用输出端口裁掉了（消费者那边没读）。
//     golden 端口 = **10 个，全 input，0 个 output**。于是本模块的全部可观测状态
//     与两块子存储的内容 —— UT 只能做层次探针比对，见 verif/ut/SSIT/tb.sv。
// (2) 那三组 1024 项的 debug_valid/debug_ssid/debug_strict 影子数组不是“调试残留
//     可以删”：Chisel 对它们加了 dontTouch，firtool 因此保留下来，它们是 golden
//     里实打实的 3072 个寄存器，也是 FM 的比较点。golden 35,104 行里 **96%**
//     就是这三组数组被逐项展平的结果（见下面的行数构成）。
//
// ★ golden 行数构成（行号边界见下；分类判据 = 每行的首词 + 两个 always 块与
//   initial 块的起止行，可用 awk/python 按下面的区间原样复算）★
//     firtool 宏头         L1    -L86        86 行  0.2%
//     端口表               L87   -L98         12 行  0.0%
//     声明区(3087 个 reg)  L99   -L3180     3082 行  8.8%
//     组合 _GEN 区 A       L3181 -L14501   11321 行 32.3%
//     always 异步复位块    L14502-L17599    3098 行  8.8%
//     组合 _GEN 区 B       L17600-L28863   11264 行 32.1%
//     always 无复位块      L28864-L30931    2068 行  5.9%
//     ENABLE_INITIAL_REG_  L30932-L35066    4135 行 11.8%
//     子实例+endmodule     L35067-L35103      37 行  0.1%
//   全文 35,103 行里 **33,788 行(96.3%)** 落在「重复 ≥1000 次的行模板」上，也就是
//   1024 路影子数组被逐项展开的产物。去掉 firtool 宏头与 initial 块这两段纯样板后，
//   **不同的行模板只有 177 条(0.50%)** —— 这就是本模块真正要重写的量。
//
// ★ 更新优先级（逐条对着 golden 核过）★
//   - 读口: io_update_valid 抢占 decode 读口（update 一来前端必被重定向，decode
//     的读没人要了）。见 §4。
//   - 写口 0 由「load 侧更新」与「冲刷」共用：两者同拍时 **load 更新赢地址与数据**，
//     但 wen 是两者相或。见 §6 的 ★1。
//   - 写口 1（store 侧）被「与写口 0 同址」无条件压掉（Chisel 注释 "make
//     SyncDataModuleTemplate happy"）。★注意 golden 比较的是写口 0 的**最终**地址，
//     也就是说冲刷地址撞上 store 更新地址时，store 那次写会被吃掉。见 §6 的 ★2。
//   - 影子数组: 同一拍「更新置位」压过「冲刷清位」（golden 是 set | keep 的形状）。
//
// ★ Chisel 与 golden 的差异 ★
//   本模块没有发现二者语义不一致的地方；但 golden 有若干 firtool 留下的冗余写法
//   （如 `(~state | ~(state & hit))` 等价于 `~(state & hit)`，
//     `~(sel==0 | sel==2 | sel==1) & (&sel)` 等价于 `sel==2'b11`），
//   本文件写成化简形，并在原处注明 golden 的原形状。
// =============================================================================

// -----------------------------------------------------------------------------
// §1 参数包：全部从 golden 实测（不从 Chisel 抄，Chisel 侧是 Parameters 推导）
// -----------------------------------------------------------------------------
package ssit_pkg;

  // SSITSize=1024：debug_* 三组数组各 1024 项；raddr/waddr 10 位。
  localparam int SSIT_SIZE = 1024;
  localparam int PC_W      = 10;          // MemPredPCWidth（已折叠过的 PC）
  localparam int SSID_W    = 5;           // SSIDWidth：32 个 store set

  // 冲刷定时器。ResetTimeMax2Pow=20（resetCounter 20 位），
  // ResetTimeMin2Pow=10（取 resetCounter[19:10] 做超时判据）。
  localparam int RST_CNT_W = 20;
  localparam int RST_CNT_LO = 10;

  // log2Up(SSITSize+1)=11。★11 位不是 10 位★：整表走完的判据是
  // resetStepCounter == 1023 用的是全 11 位比较，位 10 结构上存在（复位为 0，
  // 正常运行中恒 0），照抄 golden 的位宽，不缩。
  localparam int STEP_W = 11;

  localparam int TIMEOUT_W = 5;           // csrCtrl.lvpred_timeout

  // golden 保留下来的读口数。Chisel 是 DecodeWidth 个读口，firtool 把 2..N
  // 号读口连同 io.rdata 一起裁了，只剩 0/1 两个（更新流水要用）。
  localparam int RD_PORTS = 2;

  // s_idle/s_flush。复位值是 s_flush（上电先把整表冲一遍）。
  typedef enum logic {
    S_IDLE  = 1'b0,
    S_FLUSH = 1'b1
  } ssit_state_e;

endpackage : ssit_pkg

// =============================================================================
// §2 xs_SSIT_core —— 可读核
// =============================================================================
module xs_SSIT_core
  import ssit_pkg::*;
(
  input  logic                      clock,
  input  logic                      reset,     // ★异步、高有效（golden 是
                                               //  always @(posedge clock or posedge reset)）
  // decode 级读口
  input  logic [RD_PORTS-1:0]             io_ren,
  input  logic [RD_PORTS-1:0][PC_W-1:0]   io_raddr,
  // 访存相关性违例上报（外部已打过一拍）
  input  logic                      io_update_valid,
  input  logic [PC_W-1:0]           io_update_ldpc,
  input  logic [PC_W-1:0]           io_update_stpc,
  // CSR：冲刷周期 = 2^(10+lvpred_timeout) 拍
  input  logic [TIMEOUT_W-1:0]      io_csrCtrl_lvpred_timeout
);

  // ---------------------------------------------------------------------------
  // §3 状态元素一览（复位域是本模块最容易抄错的地方，先集中列清）
  // ---------------------------------------------------------------------------
  // 【异步复位域】golden 的 always @(posedge clock or posedge reset) 里只有这 4 组：
  //     debug_valid[1024] → 0 ，resetCounter → 0 ，resetStepCounter → 0 ，state → S_FLUSH
  // 【无复位域】golden 的 always @(posedge clock) 里的一切，上电值不确定：
  //     debug_ssid[1024]、debug_strict[1024]、timeout_q、s1_*、s2_*
  //   —— 不许好心给它们补复位：那会改变上电后若干拍的行为，是真 bug（且 elaborate
  //      与 lint 都不会响）。影子 ssid/strict 不复位是安全的，因为 debug_valid
  //      复位为 0，没有 valid 的项其 ssid/strict 没有意义。
  logic [SSIT_SIZE-1:0]             debug_valid;    // 异步复位 → 0
  logic [SSIT_SIZE-1:0][SSID_W-1:0] debug_ssid;     // 无复位
  logic [SSIT_SIZE-1:0]             debug_strict;   // 无复位

  logic [RST_CNT_W-1:0]  reset_counter;   // 异步复位 → 0
  logic [STEP_W-1:0]     reset_step;      // 异步复位 → 0
  ssit_state_e           state;           // 异步复位 → S_FLUSH

  logic [TIMEOUT_W-1:0]  timeout_q;       // 无复位（golden 名 REG）

  logic                  s1_valid;        // 无复位
  logic [PC_W-1:0]       s1_ldpc, s1_stpc;

  logic                  s2_valid;        // 无复位
  logic [PC_W-1:0]       s2_ldpc, s2_stpc;
  logic                  s2_load_assigned, s2_store_assigned;
  logic [SSID_W-1:0]     s2_load_old_ssid, s2_store_old_ssid;
  logic                  s2_load_strict;

  // ---------------------------------------------------------------------------
  // §4 两块同步读存储与读口复用
  // ---------------------------------------------------------------------------
  // update 一旦有效，前端会被重定向，decode 这一拍的读结果没人要，于是更新流水
  // 直接抢占 0/1 两个读口去读 ldpc/stpc 的旧表项（Chisel: `when (io.update.valid)`）。
  // ★ren 不受抢占影响★：golden 把 io_ren 原样接给存储，没有跟 update_valid 或一起，
  // 也就是说 update 撞上 ren=0 时这次读**不会发生**（读地址寄存器不更新）。
  logic [PC_W-1:0] rd_addr_0, rd_addr_1;
  assign rd_addr_0 = io_update_valid ? io_update_ldpc : io_raddr[0];
  assign rd_addr_1 = io_update_valid ? io_update_stpc : io_raddr[1];

  logic                  va_rdata_0, va_rdata_1;     // valid_array 读回
  logic [SSID_W-1:0]     da_rdata_0_ssid, da_rdata_1_ssid;
  logic                  da_rdata_0_strict;

  logic                  va_wen_0, va_wen_1;
  logic [PC_W-1:0]       va_waddr_0, va_waddr_1;
  logic                  va_wdata_0, va_wdata_1;
  logic                  da_wen_0, da_wen_1;
  logic [PC_W-1:0]       da_waddr_0, da_waddr_1;
  logic [SSID_W-1:0]     da_wdata_0_ssid, da_wdata_1_ssid;
  logic                  da_wdata_0_strict;

  // ---------------------------------------------------------------------------
  // §5 更新流水 s0 → s1 → s2
  // ---------------------------------------------------------------------------
  // s0: 发读（上面的读口复用）。s1: 收读回。s2: 算新值并写回。
  // 载荷寄存器都是 RegEnable（无复位、带使能），使能是**上一级的 valid**。
  // ★golden 实测：s2 的 ldpc/stpc 用的是 s1 的载荷寄存器，而 s1 的载荷使能是
  //  io_update_valid —— 也就是说连续两拍 update 时，第二拍会覆盖 s1 载荷，
  //  但 s2 已经在上一拍把值抓走了，不丢。★
  always_ff @(posedge clock) begin
    timeout_q <= io_csrCtrl_lvpred_timeout;

    s1_valid <= io_update_valid;
    if (io_update_valid) begin
      s1_ldpc <= io_update_ldpc;
      s1_stpc <= io_update_stpc;
    end

    s2_valid <= s1_valid;
    if (s1_valid) begin
      s2_ldpc            <= s1_ldpc;
      s2_stpc            <= s1_stpc;
      s2_load_assigned   <= va_rdata_0;
      s2_store_assigned  <= va_rdata_1;
      s2_load_old_ssid   <= da_rdata_0_ssid;
      s2_store_old_ssid  <= da_rdata_1_ssid;
      s2_load_strict     <= da_rdata_0_strict;
    end
  end

  // -- store-set 算法本体（Chrysos&Emer 表 1 的四种情形）--------------------
  // sel = {load 已有 store set, store 已有 store set}
  logic [1:0] sel;
  assign sel = {s2_load_assigned, s2_store_assigned};

  // 新 ssid 的来源：把 10 位折叠 PC 异或折成 5 位（utility.XORFold）。
  logic [SSID_W-1:0] ld_alloc_ssid, st_alloc_ssid, alloc_ssid, winner_ssid;
  assign ld_alloc_ssid = s2_ldpc[SSID_W-1:0] ^ s2_ldpc[PC_W-1:SSID_W];
  assign st_alloc_ssid = s2_stpc[SSID_W-1:0] ^ s2_stpc[PC_W-1:SSID_W];
  // 情形 1（两边都没有）时两条指令要分进同一个 set，取两者中较小的那个 id。
  assign alloc_ssid  = (ld_alloc_ssid < st_alloc_ssid) ? ld_alloc_ssid : st_alloc_ssid;
  // 情形 4（两边都有）时「小 id 者胜」，输家改投赢家的 set。
  assign winner_ssid = (s2_load_old_ssid < s2_store_old_ssid) ? s2_load_old_ssid
                                                              : s2_store_old_ssid;
  logic ssid_is_same;
  assign ssid_is_same = (s2_load_old_ssid == s2_store_old_ssid);

  // 四种情形各写哪一侧：
  //   sel=00 两边都没有 → 两侧都写（各自分配，同一个 alloc_ssid）
  //   sel=01 只有 store 有 → 只写 load 侧，沿用 store 的 set
  //   sel=10 只有 load  有 → 只写 store 侧，沿用 load 的 set
  //   sel=11 两边都有   → 两侧都写成 winner
  logic writes_ld, writes_st;
  assign writes_ld = ~s2_load_assigned  | s2_store_assigned;   // sel ∈ {00,01,11}
  assign writes_st = ~s2_store_assigned | s2_load_assigned;    // sel ∈ {00,10,11}

  logic upd_ld_en, upd_st_en;
  assign upd_ld_en = s2_valid & writes_ld;
  assign upd_st_en = s2_valid & writes_st;

  // 写进 load 侧 / store 侧的 ssid。两张表**取值不同**（不能合并成一条）：
  // 不写的那一侧 golden 明确驱 0 而不是悬空，照抄。
  logic [SSID_W-1:0] ld_port_ssid, st_port_ssid;
  always_comb begin
    // 不用 unique：s2_load/store_assigned 是**无复位**寄存器，上电为 X 时
    // unique 会每拍报一次「no matching condition」，把真警告淹掉。
    case (sel)
      2'b00:   begin ld_port_ssid = alloc_ssid;    st_port_ssid = alloc_ssid;    end
      2'b01:   begin ld_port_ssid = st_alloc_ssid; st_port_ssid = '0;            end
      2'b10:   begin ld_port_ssid = '0;            st_port_ssid = ld_alloc_ssid; end
      default: begin ld_port_ssid = winner_ssid;   st_port_ssid = winner_ssid;   end
    endcase
  end

  // ---------------------------------------------------------------------------
  // §6 定期整表冲刷 FSM 与两块存储的写口
  // ---------------------------------------------------------------------------
  // s_idle 里 resetCounter 一直自增；resetCounter[19:10] 右移 lvpred_timeout 拍
  // 之后最低位变 1 就算超时（等价于「计到 2^(10+timeout)」），转 s_flush 并清零计数。
  // s_flush 里每拍把 resetStepCounter 指向的那一项 valid 清 0，走满 1024 项回 s_idle。
  // golden 的形状是 `(resetCounter[19:10] >> REG)[0]`：先移位再取最低位，
  // 移出去就恒 0（timeout 最大 31，被移的只有 10 位）。两步照抄，别写成比较式。
  logic [RST_CNT_W-RST_CNT_LO-1:0] timeout_shifted;   // golden _GEN_4121
  logic flush_timeout;                                // golden _GEN_4121[0]
  logic flush_done;                                   // golden _GEN_4120
  assign timeout_shifted = reset_counter[RST_CNT_W-1:RST_CNT_LO] >> timeout_q;
  assign flush_timeout   = timeout_shifted[0];
  // ★11 位整宽比较，不是 10 位★（golden: resetStepCounter == 11'h3FF）
  assign flush_done      = (reset_step == STEP_W'(SSIT_SIZE - 1));

  logic in_flush;
  assign in_flush = (state == S_FLUSH);

  // ★1 写口 0 是「load 侧更新」与「冲刷」共用的口（Chisel 的 SSIT_MISC_WRITE_PORT
  //    与 SSIT_UPDATE_LOAD_WRITE_PORT 是同一个 0 号口）。golden 展开出来的优先级是：
  //      wen   = 更新 | 冲刷          （两者相或）
  //      waddr = 更新 ? ldpc : 冲刷 ? step : 0    （★更新赢★）
  //      wdata = 更新                （更新写 1，冲刷写 0）
  //    所以两者同拍时，冲刷对 valid_array 的那次写**被吃掉**：该清的那一项没被清。
  //    ★而影子数组 debug_valid 照清不误★（§7 的 valid_keep 无条件带上 step_hit）——
  //    也就是说这一拍之后影子与真存储**不一致**。Chisel 里这两件事是两条独立的
  //    赋值（valid_array 只有一个 0 号写口、debug_valid 是可随便写的 Vec），
  //    golden 展开后原样保留了这个不一致。不是笔误，照抄。
  assign va_wen_0   = upd_ld_en | in_flush;
  assign va_waddr_0 = upd_ld_en ? s2_ldpc : (in_flush ? reset_step[PC_W-1:0] : '0);
  assign va_wdata_0 = upd_ld_en;

  assign va_waddr_1 = upd_st_en ? s2_stpc : '0;
  assign va_wdata_1 = upd_st_en;
  // ★2 "make SyncDataModuleTemplate happy"：两个写口同址时压掉 1 号口。
  //    ★比较的是写口 0 的**最终**地址（含冲刷地址那一支）★ —— 于是 sel=10
  //    （只写 store 侧）又恰好在冲刷、且 step 撞上 stpc 时，这次 store 更新会被吞掉。
  //    Chisel 里看不出这一条（那边是对 io.waddr 信号比较，展平后才暴露）。
  assign va_wen_1   = (va_waddr_0 != va_waddr_1) & upd_st_en;

  // data_array 不参与冲刷（冲刷只清 valid 位），所以 0 号口没有 in_flush 那一支。
  assign da_wen_0   = upd_ld_en;
  assign da_waddr_0 = upd_ld_en ? s2_ldpc : '0;
  assign da_waddr_1 = upd_st_en ? s2_stpc : '0;
  assign da_wen_1   = (da_waddr_0 != da_waddr_1) & upd_st_en;

  assign da_wdata_0_ssid = s2_valid ? ld_port_ssid : '0;
  assign da_wdata_1_ssid = s2_valid ? st_port_ssid : '0;
  // strict = 「两边本来就在同一个 set 里还是撞了」→ 下次这条 load 必须严格等待。
  // 只写 load 侧（golden 原形 ~(sel==0|sel==2|sel==1) & (&sel)，即 sel==2'b11）。
  assign da_wdata_0_strict = s2_valid & (sel == 2'b11) & ssid_is_same;
  // data_array 没有 io_wdata_1_strict 端口：store 侧的 strict 恒 0，firtool 裁掉了。

  // ---------------------------------------------------------------------------
  // §7 影子数组（debug_valid / debug_ssid / debug_strict）
  // ---------------------------------------------------------------------------
  // 这三组是 Chisel 里 dontTouch 的镜像副本，内容应当与两块存储一致。它们是本模块
  // 仅有的可观测状态，也是 FM 的 3072 个比较点，所以每一项的次态都要跟 golden 对齐。
  logic [SSIT_SIZE-1:0] ld_hit, st_hit, wr_hit, step_hit, valid_keep;

  for (genvar i = 0; i < SSIT_SIZE; i++) begin : g_entry
    // 本项是不是这次更新的 load / store 目标项
    assign ld_hit[i] = (s2_ldpc == PC_W'(i));
    assign st_hit[i] = (s2_stpc == PC_W'(i));
    // 本项这次被写 = 该侧要写 且 该侧地址命中本项（与 §5 的 writes_* 同一套判据）
    assign wr_hit[i] = (writes_ld & ld_hit[i]) | (writes_st & st_hit[i]);
    // 冲刷指针是不是正指着本项
    assign step_hit[i] = in_flush & (reset_step[PC_W-1:0] == PC_W'(i));
    // 冲刷清位后的保持值。golden 写成 (~state | ~(state & step==i)) & valid，同义。
    assign valid_keep[i] = ~step_hit[i] & debug_valid[i];
  end

  // 本项这次要写进去的 ssid：只取决于 sel（四种情形各一个常量来源），
  // 与 §5 的 ld_port_ssid/st_port_ssid **不是同一张表**（那两张是按口分的，
  // 不写的口驱 0；这一张是按项分的，写哪一侧就取哪一侧的值）。
  logic [SSID_W-1:0] entry_wr_ssid;
  always_comb begin
    case (sel)
      2'b00:   entry_wr_ssid = alloc_ssid;
      2'b01:   entry_wr_ssid = st_alloc_ssid;   // 只写 load 侧，沿用 store 的 set
      2'b10:   entry_wr_ssid = ld_alloc_ssid;   // 只写 store 侧，沿用 load 的 set
      default: entry_wr_ssid = winner_ssid;     // 2'b11
    endcase
  end

  // ---------------------------------------------------------------------------
  // §8 时序：异步复位域
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      debug_valid   <= '0;
      reset_counter <= '0;
      reset_step    <= '0;
      state         <= S_FLUSH;     // 上电先冲一遍整表
    end
    else begin
      // ★置位压过冲刷清位★（golden 是 `slot | keep` 的形状）
      for (int i = 0; i < SSIT_SIZE; i++)
        debug_valid[i] <= (s2_valid & wr_hit[i]) | valid_keep[i];

      // 计数器无条件自增，只有在 s_idle 撞上超时那一拍清零。
      reset_counter <= (~in_flush & flush_timeout) ? '0
                                                   : RST_CNT_W'(reset_counter + 1'b1);

      if (in_flush) begin
        reset_step <= flush_done ? '0 : STEP_W'(reset_step + 1'b1);
        state      <= flush_done ? S_IDLE : S_FLUSH;
      end
      else if (flush_timeout) begin
        state <= S_FLUSH;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // §9 时序：无复位域（影子 ssid / strict）
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock) begin
    if (s2_valid) begin
      for (int i = 0; i < SSIT_SIZE; i++) begin
        debug_ssid[i]   <= wr_hit[i] ? entry_wr_ssid : debug_ssid[i];
        // strict 只在情形 4 且 ssid 本来就相同时置起，且**只置 load 那一项**；
        // 其余被写的项一律清 0（含 store 项，即使 ldpc==stpc 也是先清后置，置赢）。
        debug_strict[i] <= ((sel == 2'b11) & ssid_is_same & ld_hit[i])
                           | (~wr_hit[i] & debug_strict[i]);
      end
    end
  end

  // ---------------------------------------------------------------------------
  // §10 性能观测点（XSPerfAccumulate；golden 里是 _GEN/_GEN_4112…_GEN_4119）
  //   本模块内**无读者**：整芯片里由 SimTop 用绝对层次引用把它们引到
  //   LogPerfEndpoint（docs/perf_bore_map.tsv 里 SSIT 有 7 条 bore）。留成具名
  //   wire 是为了让 scripts/perf_rebind.py 有东西可绑，也让读者知道 golden 那几个
  //   悬空的 _GEN 是干什么的。综合会把它们优化掉，FM 里也不是比较点。
  // ---------------------------------------------------------------------------
  logic perf_reset_timeout;              // golden _GEN
  logic perf_update_lxsx, perf_update_lysx, perf_update_lxsy, perf_update_lysy;
  logic perf_update_should_strict, perf_update_strict_failed;
  assign perf_reset_timeout        = in_flush & (reset_counter == '0);
  assign perf_update_lxsx          = s2_valid & ~s2_load_assigned & ~s2_store_assigned;
  assign perf_update_lysx          = s2_valid &  s2_load_assigned & ~s2_store_assigned;
  assign perf_update_lxsy          = s2_valid & ~s2_load_assigned &  s2_store_assigned;
  assign perf_update_lysy          = s2_valid &  s2_load_assigned &  s2_store_assigned;
  assign perf_update_should_strict = s2_valid & ssid_is_same
                                     & s2_load_assigned & s2_store_assigned;
  // 这一条 golden 注释写着 "should be zero"：严格等待已经置起还是撞了。
  assign perf_update_strict_failed = s2_valid & ssid_is_same & s2_load_strict
                                     & s2_load_assigned & s2_store_assigned;

  // ---------------------------------------------------------------------------
  // §11 两块同步读存储
  //   整芯片里这两个模块名解析到本仓已签核的重写件
  //   rtl/common/SyncDataModuleTemplate__1024entry.sv 与 ..._1.sv（本目标只读引用，
  //   不改它们）。而 SSIT 自己的 UT/FM 两侧都读 **golden** 的那两份（见
  //   verif/ut/SSIT/Makefile 的 RTL_GOLDEN_DEPS / FM_REF_DEPS_SSIT）：本目标要证的
  //   是 SSIT 的控制逻辑，子存储是另一个已经单独证过的目标，不重复卷进来。
  // ---------------------------------------------------------------------------
  SyncDataModuleTemplate__1024entry valid_array (
    .clock      (clock),
    .reset      (reset),
    .io_ren_0   (io_ren[0]),
    .io_ren_1   (io_ren[1]),
    .io_raddr_0 (rd_addr_0),
    .io_raddr_1 (rd_addr_1),
    .io_rdata_0 (va_rdata_0),
    .io_rdata_1 (va_rdata_1),
    .io_wen_0   (va_wen_0),
    .io_wen_1   (va_wen_1),
    .io_waddr_0 (va_waddr_0),
    .io_waddr_1 (va_waddr_1),
    .io_wdata_0 (va_wdata_0),
    .io_wdata_1 (va_wdata_1)
  );

  SyncDataModuleTemplate__1024entry_1 data_array (
    .clock             (clock),
    .reset             (reset),
    .io_ren_0          (io_ren[0]),
    .io_ren_1          (io_ren[1]),
    .io_raddr_0        (rd_addr_0),
    .io_raddr_1        (rd_addr_1),
    .io_rdata_0_ssid   (da_rdata_0_ssid),
    .io_rdata_0_strict (da_rdata_0_strict),
    .io_rdata_1_ssid   (da_rdata_1_ssid),
    .io_wen_0          (da_wen_0),
    .io_wen_1          (da_wen_1),
    .io_waddr_0        (da_waddr_0),
    .io_waddr_1        (da_waddr_1),
    .io_wdata_0_ssid   (da_wdata_0_ssid),
    .io_wdata_0_strict (da_wdata_0_strict),
    .io_wdata_1_ssid   (da_wdata_1_ssid)
  );

endmodule : xs_SSIT_core

// =============================================================================
// §12 SSIT —— 与 golden 逐位同名同序的 wrapper（只做端口展平）
// =============================================================================
module SSIT(
  input       clock,
  input       reset,
  input       io_ren_0,
  input       io_ren_1,
  input [9:0] io_raddr_0,
  input [9:0] io_raddr_1,
  input       io_update_valid,
  input [9:0] io_update_ldpc,
  input [9:0] io_update_stpc,
  input [4:0] io_csrCtrl_lvpred_timeout
);
  xs_SSIT_core u_core (
    .clock                     (clock),
    .reset                     (reset),
    .io_ren                    ({io_ren_1, io_ren_0}),
    .io_raddr                  ({io_raddr_1, io_raddr_0}),
    .io_update_valid           (io_update_valid),
    .io_update_ldpc            (io_update_ldpc),
    .io_update_stpc            (io_update_stpc),
    .io_csrCtrl_lvpred_timeout (io_csrCtrl_lvpred_timeout)
  );
endmodule
