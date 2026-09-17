// =============================================================================
// xs_BusyTable_core.sv —— 重命名级「物理寄存器忙位表」参数化可读核
//   (BusyTable / BusyTable_1 / BusyTable_2 / BusyTable_3 / VlBusyTable 共享核体)
// -----------------------------------------------------------------------------
// 设计源:XiangShan src/main/scala/xiangshan/backend/rename/BusyTable.scala
//        (class BusyTable + class VlBusyTable extends BusyTable)
// golden 对照:G1-canonical/golden-rtl/{BusyTable,BusyTable_1,BusyTable_2,
//        BusyTable_3,VlBusyTable}.sv —— 五个 KunminghuV2Config 单态化实例,
//        对应 Int(224) / Fp(192) / Vf(128) / V0(22) / Vl(32) 五个物理寄存器堆。
//
// ★ 它是什么 ★
// 每个物理寄存器一位「忙(busy)」状态。重命名分配 pdest 时置忙,写回/快速唤醒时清忙。
// Dispatch 拿读口问「这个 psrc 就绪了吗」,决定 uop 进发射队列时源算不算 ready。
//   置忙:io_allocPregs(重命名分配) 与 ldCancel(推测唤醒被撤销)
//   清忙:io_wbPregs(写回/ROB walk) 与 快速唤醒(wakeUp)   —— 压过置忙
//
// ★ 推测唤醒与 loadDependency(只有 Int 表有) ★
// load 在命中 DCache 之前就发唤醒(推测),两拍内可能被 ld2Cancel 撤销。所以每个 preg
// 额外存一份影子 loadDependency[3 条 load 流水][2 位年龄]:被 load 唤醒时置该流水
// 的最低位,此后每拍左移一位(年龄 +1),移出最高位即脱离取消窗口。ld2Cancel 到来时,
// 凡对应流水最高位仍置起的 preg 全部退回忙。
//
// ★ 更新优先级(逐条对着 golden 核过,见 §5)★
//   忙位次态 = ~(wakeUp | wb) & (alloc | ldCancel | 现值)
//   寄存器使能 = alloc | ldCancel | wakeUp | wb    (firtool 从 RegEnable 提出的时钟使能)
//
// ★ 三处 golden 与 Chisel 字面不一致,一律以 golden 为准 ★
//   (1) Int 表 0 号项不走通用式子(x0 恒就绪),见 §5
//   (2) is0Lat 是每个 exu 的编译期常数,firtool 折成 0 或 1,同一行 Chisel 在五个
//       变体里展开成三种形状,见 §4
//   (3) 读口越界:忙位读越界得 0,而 loadDependency 读越界得 **第 0 项**,见 §6
// =============================================================================

// -----------------------------------------------------------------------------
// §1 家族公共常量。变体差异全部走 parameter,所以这个包很薄。
// -----------------------------------------------------------------------------
package busytable_pkg;

  // PhyRegIdxWidth。五个变体表深 22~224 各不相同,但 golden 的 preg 索引端口
  // (allocPregs/wbPregs/wakeUp.pdest/read.req)**一律 8 位** —— 全后端共用同一个
  // PhyRegIdxWidth。于是 22 项的 V0 表也拿 8 位索引,大量取值落在表外,
  // 越界语义因此是真问题而不是纸上谈兵(见 §6)。
  localparam int PREG_IDX_W = 8;

  // LoadPipelineWidth / LoadDependencyWidth:3 条 load 流水,每条 2 位年龄。
  localparam int LD_PIPE_N = 3;
  localparam int LD_DEP_W  = 2;

  // 本家族最多的唤醒路数(Int 表 4 路 ALU + 3 路 LOAD)。只用来给参数数组定形状。
  localparam int MAX_WAKEUP = 8;

endpackage : busytable_pkg

// =============================================================================
// §2 xs_BusyTable_core —— 参数化核体
// =============================================================================
module xs_BusyTable_core
  import busytable_pkg::*;
#(
  // ---- 规模(全部从 golden 实测,每个 wrapper 文件头列了自己的一组) ----
  parameter int NUM_PREGS  = 224,  // 表项数 = 该 regfile 的物理寄存器数
  parameter int NUM_ALLOC  = 6,    // RenameWidth,五个变体都是 6
  parameter int NUM_WB     = 8,    // 写回口数
  parameter int NUM_READ   = 12,   // 读口数
  parameter int NUM_WAKEUP = 7,    // 快速唤醒路数(VlBusyTable 为 0)

  // ---- 变体开关 ----
  // 只有 Int 表 needLoadCancel 为真;其余变体 loadCancel 恒 0,于是 loadDependency
  // 影子整片没有读者、被 firtool 消掉 —— golden 里一个都不剩,所以这里也必须不生成
  // (多生成 = 凭空多出 N×3 个 impl 侧寄存器,FM 立刻失配)。
  parameter bit HAS_LOAD_DEP = 1,
  // Chisel:`if (idx == 0 && pregWB.isInstanceOf[IntWB]) update := false.B`
  // —— 整数 0 号物理寄存器恒就绪(x0)。只有 Int 表置 1。
  parameter bit ZERO_ALWAYS_READY = 1,
  // VlBusyTable 在忙位表之外再挂两张表(vl 是否非零 / 是否等于 vlmax)。
  parameter bit HAS_VL = 0,

  // ---- 每路唤醒的属性(wrapper 按 golden 实测填) ----
  // WK_FROM_LOAD[i]:第 i 路唤醒来自 load 单元。Chisel 里这两类写 loadDependency
  // 的方式不同:load 单元写「本流水的 onehot」,其余单元写「自己的依赖左移一位」。
  parameter logic [MAX_WAKEUP-1:0]                WK_FROM_LOAD = 8'b0111_0000,
  // WK_LD_ONEHOT[i]:第 i 路 load 唤醒占哪条 load 流水(onehot)。非 load 路忽略。
  parameter logic [MAX_WAKEUP-1:0][LD_PIPE_N-1:0] WK_LD_ONEHOT = '0,

  // 派生量,不要在例化时覆盖:SV 不允许 0 宽打包数组,NUM_WAKEUP=0 的变体按 1 路
  // 占位(wrapper 把这些端口全接 0),真正「有没有唤醒逻辑」由 NUM_WAKEUP>0 判。
  parameter int WK_SLOTS = (NUM_WAKEUP > 0) ? NUM_WAKEUP : 1
) (
  input  logic clock,
  input  logic reset,   // 异步高有效;golden 全家族一致,见 §5

  // 重命名分配:把新 pdest 置忙
  input  logic [NUM_ALLOC-1:0]                 alloc_valid,
  input  logic [NUM_ALLOC-1:0][PREG_IDX_W-1:0] alloc_preg,

  // 写回 / ROB walk:把 pdest 置就绪
  input  logic [NUM_WB-1:0]                    wb_valid,
  input  logic [NUM_WB-1:0][PREG_IDX_W-1:0]    wb_preg,

  // 快速(推测)唤醒
  input  logic [WK_SLOTS-1:0]                  wk_valid,
  input  logic [WK_SLOTS-1:0]                  wk_wen,        // rfWen/fpWen/vecWen/v0Wen
  input  logic [WK_SLOTS-1:0][PREG_IDX_W-1:0]  wk_pdest,
  input  logic [WK_SLOTS-1:0]                  wk_is0lat,     // 见 §4:多为编译期常数
  input  logic [WK_SLOTS-1:0]                  wk_og0cancel,  // 该 exu 对应的 og0Cancel 位
  input  logic [WK_SLOTS-1:0][LD_PIPE_N-1:0][LD_DEP_W-1:0] wk_load_dep,

  // load 取消(ld2Cancel):第 j 位 = 第 j 条 load 流水这拍宣告作废
  input  logic [LD_PIPE_N-1:0]                 ld_cancel,

  // 读口
  input  logic [NUM_READ-1:0][PREG_IDX_W-1:0]  read_req,
  output logic [NUM_READ-1:0]                  read_resp,      // 1 = 就绪(非忙)
  output logic [NUM_READ-1:0][LD_PIPE_N-1:0][LD_DEP_W-1:0] read_load_dep,

  // VlBusyTable 专属
  input  logic                                 vl_from_int_is_zero,
  input  logic                                 vl_from_int_is_vlmax,
  input  logic                                 vl_from_vf_is_zero,
  input  logic                                 vl_from_vf_is_vlmax,
  output logic [NUM_READ-1:0]                  vl_is_nonzero,
  output logic [NUM_READ-1:0]                  vl_is_vlmax
);

  // ---------------------------------------------------------------------------
  // §3 分配/写回掩码 —— 把若干 (valid, preg) 摊成一条表宽的位掩码
  //
  // golden(reqVecToMask):`256'h1 << bits` 先在 256 位域里移位,再截到表宽。
  // 先移后截是必须的:preg 索引 8 位而表最窄只有 22 项,先截宽再移会把本该落在表外
  // 的高位折回表内 —— 对 V0/Vl 这种小表就是真 bug。
  // ---------------------------------------------------------------------------
  logic [NUM_ALLOC-1:0][255:0] alloc_onehot;
  logic [NUM_WB-1:0][255:0]    wb_onehot;
  logic [NUM_PREGS-1:0]        alloc_mask;
  logic [NUM_PREGS-1:0]        wb_mask;

  for (genvar a = 0; a < NUM_ALLOC; a++) begin : g_alloc_onehot
    assign alloc_onehot[a] = 256'd1 << alloc_preg[a];
  end
  for (genvar w = 0; w < NUM_WB; w++) begin : g_wb_onehot
    assign wb_onehot[w] = 256'd1 << wb_preg[w];
  end

  always_comb begin
    alloc_mask = '0;
    for (int a = 0; a < NUM_ALLOC; a++)
      if (alloc_valid[a]) alloc_mask |= alloc_onehot[a][NUM_PREGS-1:0];
    wb_mask = '0;
    for (int w = 0; w < NUM_WB; w++)
      if (wb_valid[w]) wb_mask |= wb_onehot[w][NUM_PREGS-1:0];
  end

  // ---------------------------------------------------------------------------
  // §4 快速唤醒命中向量 wakeup_oh[p] —— 第 p 项这拍被哪几路唤醒(每路一位)
  //
  // Chisel(每路一项与):valid && wen && UIntToOH(pdest)(p)
  //                     && !LoadShouldCancel(唤醒方自带的 loadDependency, ldCancel)
  //                     && !(is0Lat && og0Cancel(exuIdx))
  //
  // ★ golden 与 Chisel 的形状差:is0Lat 是每个 exu 的编译期常数,firtool 折掉了它,
  //   于是同一行 Chisel 在 golden 里有三种形状:
  //     is0Lat 仍是端口 → `& ~(is0Lat & og0Cancel_k)`  Int wk0/wk1、Fp wk0、Vf/V0 wk0
  //     is0Lat 折成 1   → `& ~og0Cancel_k`(端口消失)   Int wk2(og0Cancel_4)、wk3(_6)
  //     is0Lat 折成 0   → 整项消失                      Fp wk1/wk2、以及全部 mem 唤醒
  //   这里不为三种形状开参数:核里统一算 `wk_is0lat[i] & wk_og0cancel[i]`,由 wrapper
  //   把被折掉的那一侧接成常数 1'b1 / 1'b0,常数传播后与 golden 逐字同形。
  //   照 Chisel 字面给每路都留一个 is0Lat 端口,就会凭空多出四个 golden 没有的端口。
  // ---------------------------------------------------------------------------
  logic [NUM_PREGS-1:0][WK_SLOTS-1:0] wakeup_oh;
  logic [NUM_PREGS-1:0]               wakeup_mask;   // |wakeup_oh[p]
  logic [WK_SLOTS-1:0]                wk_fires;      // 该路本拍有效且未被任何取消打掉

  if (NUM_WAKEUP > 0) begin : g_wakeup
    for (genvar i = 0; i < NUM_WAKEUP; i++) begin : g_wk
      logic [LD_PIPE_N-1:0] dep_cancel_per_pipe;
      for (genvar j = 0; j < LD_PIPE_N; j++) begin : g_pipe
        // LoadShouldCancel:依赖年龄已走到最高位,正好落在 ld2Cancel 宣告的那一拍
        assign dep_cancel_per_pipe[j] = ld_cancel[j] & wk_load_dep[i][j][LD_DEP_W-1];
      end
      assign wk_fires[i] = wk_valid[i] & wk_wen[i]
                           & ~(|dep_cancel_per_pipe)
                           & ~(wk_is0lat[i] & wk_og0cancel[i]);
    end
    for (genvar p = 0; p < NUM_PREGS; p++) begin : g_wk_oh
      for (genvar i = 0; i < NUM_WAKEUP; i++) begin : g_wk_oh_i
        assign wakeup_oh[p][i] = wk_fires[i] & (wk_pdest[i] == PREG_IDX_W'(p));
      end
      assign wakeup_mask[p] = |wakeup_oh[p];
    end
  end else begin : g_no_wakeup
    // VlBusyTable:Chisel 显式 `allWakeUp.filter(x => false)` —— vl 表不接快速唤醒
    // (源码注释给了原因:ldCancel 没接到 vl 表,接了 vsetvli 会出错)。
    assign wk_fires    = '0;
    assign wakeup_oh   = '0;
    assign wakeup_mask = '0;
  end

  // ---------------------------------------------------------------------------
  // §5 忙位表本体
  //
  // 复位域(逐个数过 golden 五个文件的复位臂):`always @(posedge clock or posedge
  // reset)` —— **异步高有效复位,表内寄存器无一例外全部复位到 0,没有不复位的寄存器**。
  //   BusyTable   896 = 224 忙位 + 224×3 依赖影子
  //   BusyTable_1 192 / BusyTable_2 128 / BusyTable_3 22  纯忙位
  //   VlBusyTable  96 = 32 × (忙位 + nonzero + vlmax)
  // ---------------------------------------------------------------------------
  logic [NUM_PREGS-1:0] busy;
  logic [NUM_PREGS-1:0] ld_cancel_mask;   // 由 §5a 驱动(无 loadDependency 的变体恒 0)
  logic [NUM_PREGS-1:0] busy_set;         // 置忙源:分配 / 依赖取消
  logic [NUM_PREGS-1:0] busy_clr;         // 清忙源:快速唤醒 / 写回
  logic [NUM_PREGS-1:0] busy_en;

  assign busy_set = alloc_mask | ld_cancel_mask;
  assign busy_clr = wakeup_mask | wb_mask;
  assign busy_en  = busy_set | busy_clr;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      busy <= '0;
    end else begin
      for (int p = 0; p < NUM_PREGS; p++) begin
        if (ZERO_ALWAYS_READY && p == 0) begin
          // ★ golden 的 0 号项不走通用式子 ★
          // golden(BusyTable.sv:18735)没有使能,写的是 `table_r <= (~en | ~en) & table_r`
          // ——「任何事件都清忙,永远不置忙」,对应 Chisel 的
          //   `if (idx == 0 && pregWB.isInstanceOf[IntWB]) update := false.B`
          //   (注释:Int RegFile 0 is always ready,即 x0)。
          // 复位后它其实恒为 0,但 golden 把寄存器留着了,这里照抄结构:
          // 并进通用式子会让「分配命中 0 号项」时次态变成 1,那是真失配。
          busy[p] <= ~busy_en[p] & busy[p];
        end else begin
          if (busy_en[p]) busy[p] <= ~busy_clr[p] & (busy_set[p] | busy[p]);
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // §5a loadDependency 影子寄存器(只有 Int 表有)
  //
  // 被唤醒时重新装载:命中路的 shiftLoadDependency 做 Mux1H(多路同时命中按位或)。
  //   load 单元唤醒 → 本流水 onehot(年龄 0)
  //   其余单元唤醒 → 把唤醒方自己的依赖整体左移一位(年龄 +1)
  // 没被唤醒但影子非零 → 每拍左移一位,移空即出取消窗口(这就是 2 位年龄的用法)。
  // ---------------------------------------------------------------------------
  if (HAS_LOAD_DEP) begin : g_load_dep
    logic [NUM_PREGS-1:0][LD_PIPE_N-1:0][LD_DEP_W-1:0] load_dep;
    logic [WK_SLOTS-1:0][LD_PIPE_N-1:0][LD_DEP_W-1:0]  shift_load_dep;
    logic [NUM_PREGS-1:0][LD_PIPE_N-1:0][LD_DEP_W-1:0] load_dep_on_wakeup;

    for (genvar i = 0; i < WK_SLOTS; i++) begin : g_shift
      for (genvar j = 0; j < LD_PIPE_N; j++) begin : g_pipe
        assign shift_load_dep[i][j] =
            WK_FROM_LOAD[i] ? LD_DEP_W'(WK_LD_ONEHOT[i][j])
                            : {wk_load_dep[i][j][LD_DEP_W-2:0], 1'b0};
      end
    end

    for (genvar p = 0; p < NUM_PREGS; p++) begin : g_dep_next
      for (genvar j = 0; j < LD_PIPE_N; j++) begin : g_pipe
        always_comb begin
          load_dep_on_wakeup[p][j] = '0;
          for (int i = 0; i < WK_SLOTS; i++)
            if (wakeup_oh[p][i]) load_dep_on_wakeup[p][j] |= shift_load_dep[i][j];
        end
      end
      // 这一项的就绪正依赖着某条本拍被取消的 load → 必须退回忙
      logic [LD_PIPE_N-1:0] cancel_per_pipe;
      for (genvar j = 0; j < LD_PIPE_N; j++) begin : g_cancel
        assign cancel_per_pipe[j] = ld_cancel[j] & load_dep[p][j][LD_DEP_W-1];
      end
      assign ld_cancel_mask[p] = |cancel_per_pipe;
    end

    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        load_dep <= '0;
      end else begin
        for (int p = 0; p < NUM_PREGS; p++) begin
          if (wakeup_mask[p]) begin
            load_dep[p] <= load_dep_on_wakeup[p];
          end else if (|load_dep[p]) begin
            for (int j = 0; j < LD_PIPE_N; j++)
              load_dep[p][j] <= {load_dep[p][j][LD_DEP_W-2:0], 1'b0};
          end
        end
      end
    end

    // ★ 越界语义:golden 的 `_GEN[req]` 是一个 **256 项** 打包数组,高 (256-N) 项
    //   被 firtool 全部填成 **第 0 项** —— 实测 BusyTable.sv 的 _GEN/_GEN_0/_GEN_1
    //   索引 255..224 三十二项全是 loadDependency_0_*。
    //   按「查不到就是 0」写这里就是静默 bug(本轮规范点名的第四个坑)。
    //   这里照抄 golden 的结构:先摊成 256 项(高位填第 0 项),读口直接按 8 位 req 取。
    //   不要改回「req < N ? load_dep[req] : load_dep[0]」那种写法 —— 功能一样,但
    //   索引变量的取值范围超出数组深度,Formality link 会报 FMR_ELAB-147(索引可能
    //   越界),而那条只能靠 set_mismatch_message_filter 抑制,属于本仓禁止的例外。
    logic [255:0][LD_PIPE_N-1:0][LD_DEP_W-1:0] dep_by_req;
    for (genvar q = 0; q < 256; q++) begin : g_dep_pad
      if (q < NUM_PREGS) begin : g_real
        assign dep_by_req[q] = load_dep[q];
      end else begin : g_pad
        assign dep_by_req[q] = load_dep[0];   // ★越界填第 0 项,不是 0★
      end
    end
    for (genvar r = 0; r < NUM_READ; r++) begin : g_dep_out
      assign read_load_dep[r] = dep_by_req[read_req[r]];
    end
  end else begin : g_no_load_dep
    // 其余变体 needLoadCancel=false:Chisel 把 loadCancel 整体换成 0.U,
    // ldCancelMask 恒 0、loadDependency 无人读 —— golden 里两者都不存在,
    // 对应 wrapper 也没有 io_read_*_loadDependency_* 端口。
    assign ld_cancel_mask = '0;
    assign read_load_dep  = '0;
  end

  // ---------------------------------------------------------------------------
  // §6 忙位读口
  //
  // golden:`(table >> req)[0]` —— req 落在表外时移出 0,读成「不忙」。
  // (注意这与上面 loadDependency 的越界语义**不一样**,两者都照 golden 抄。)
  // 写法上把表零扩展满整个 8 位索引空间再按 req 直接取:与移位逐位等价,而且索引
  // 恒在界内(理由见 §5a 里那段 FMR_ELAB-147 注释)。
  //
  // resp 还带一条本拍旁路:这拍刚被分配的 pdest 直接算忙,不等寄存器更新。
  // 旁路是**全 8 位比较、不看越界** —— golden 就是这样:越界的 req 撞上越界的
  // allocPregs.bits 照样算忙。
  // ---------------------------------------------------------------------------
  logic [255:0] busy_by_req;
  assign busy_by_req = {{(256 - NUM_PREGS){1'b0}}, busy};   // ★越界填 0 = 就绪★

  for (genvar r = 0; r < NUM_READ; r++) begin : g_read
    logic [NUM_ALLOC-1:0] alloc_bypass;
    for (genvar a = 0; a < NUM_ALLOC; a++) begin : g_bypass
      assign alloc_bypass[a] = alloc_valid[a] & (alloc_preg[a] == read_req[r]);
    end
    assign read_resp[r] = ~(busy_by_req[read_req[r]] | (|alloc_bypass));
  end

  // ---------------------------------------------------------------------------
  // §7 VlBusyTable 专属的两张附加表
  //
  // vl(向量长度)写回时才知道,而后级只关心两个谓词:vl 是否非零、是否 = vlmax。
  // 于是在忙位表之外再挂两张同深度的表,记「这一项的 vl 还**不是**非零 / 不是 vlmax」。
  // 谁写回决定语义(端口号从 golden 实测:intSchdVlWbPort=0、vfSchdVlWbPort=1):
  //   wbPregs[0] —— 带回 vlFromInt{IsZero,IsVlmax}
  //   wbPregs[1] —— 带回 vlFromVf{IsZero,IsVlmax}
  //   wbPregs[2..] —— 其它口不知道 vl 是多少,只能置成「未知 = 忙」
  // vlmax 表存的是**取反**后的值(golden:`~vlFromIntIsVlmax`),读口再取反一次,
  // 于是 is_vlmax=1 表示「确实等于 vlmax」。
  // ---------------------------------------------------------------------------
  if (HAS_VL) begin : g_vl
    logic [NUM_PREGS-1:0] int_vl_wb, vf_vl_wb, other_vl_wb;
    logic [NUM_PREGS-1:0] nonzero_table, vlmax_table;
    logic [NUM_PREGS-1:0] vl_en, vl_force_busy;

    assign int_vl_wb = wb_valid[0] ? wb_onehot[0][NUM_PREGS-1:0] : '0;
    assign vf_vl_wb  = wb_valid[1] ? wb_onehot[1][NUM_PREGS-1:0] : '0;
    always_comb begin
      other_vl_wb = '0;
      for (int w = 2; w < NUM_WB; w++)
        if (wb_valid[w]) other_vl_wb |= wb_onehot[w][NUM_PREGS-1:0];
    end

    // golden:使能 = allocMask | intVlWb | vfVlWb | otherPortsWb(ldCancelMask 恒 0)
    assign vl_en         = alloc_mask | int_vl_wb | vf_vl_wb | other_vl_wb;
    // golden 的 else 臂 = `(otherPortsWb | allocMask) | 现值`
    assign vl_force_busy = other_vl_wb | alloc_mask;

    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        nonzero_table <= '0;
        vlmax_table   <= '0;
      end else begin
        for (int p = 0; p < NUM_PREGS; p++) begin
          if (vl_en[p]) begin
            if (int_vl_wb[p]) begin
              nonzero_table[p] <= vl_from_int_is_zero;
              vlmax_table[p]   <= ~vl_from_int_is_vlmax;
            end else if (vf_vl_wb[p]) begin
              nonzero_table[p] <= vl_from_vf_is_zero;
              vlmax_table[p]   <= ~vl_from_vf_is_vlmax;
            end else begin
              nonzero_table[p] <= vl_force_busy[p] | nonzero_table[p];
              vlmax_table[p]   <= vl_force_busy[p] | vlmax_table[p];
            end
          end
        end
      end
    end

    // 读口与忙位同样的越界语义(零扩展后按 8 位 req 取),但**没有**分配旁路
    // —— golden 就是这样。
    logic [255:0] nonzero_by_req, vlmax_by_req;
    assign nonzero_by_req = {{(256 - NUM_PREGS){1'b0}}, nonzero_table};
    assign vlmax_by_req   = {{(256 - NUM_PREGS){1'b0}}, vlmax_table};
    for (genvar r = 0; r < NUM_READ; r++) begin : g_vl_read
      assign vl_is_nonzero[r] = ~nonzero_by_req[read_req[r]];
      assign vl_is_vlmax[r]   = ~vlmax_by_req[read_req[r]];
    end
  end else begin : g_no_vl
    assign vl_is_nonzero = '0;
    assign vl_is_vlmax   = '0;
  end

endmodule : xs_BusyTable_core
