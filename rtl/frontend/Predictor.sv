// =============================================================================
// xs_Predictor_core —— BPU 顶层流水的可读控制核（手写）
//
// 位置：前端 BPU（Predictor）顶层。Predictor 例化 Composer（5 预测器菊花链）产生
//       s1/s2/s3 三版覆盖式预测，本核负责把这条 3 级流水“开起来”并与 FTQ 握手：
//         · 维护 s1/s2/s3 三级 valid 寄存器（哪一级当前装着有效预测）；
//         · 生成各级 fire / flush；
//         · 把后级（更准）预测器对前级的“覆盖”表达为 s2_redirect / s3_redirect 冲刷；
//         · 向 FTQ 发 resp.valid（首次预测 or 覆盖发生时）；
//         · 维护 topdown 气泡原因 3 级流水（性能分析用，逐级 shift-and-OR）。
//
// 为什么是“覆盖式”：地址一产生，最快的 uFTB 在 s1 当拍出第一版预测让取指立刻动；
//   s2 的 FTB/TAGE、s3 的 ITTAGE/RAS 若与前级结论不同，就在对应级发出 redirect 冲刷
//   流水里更早的请求、用新结果重取。redirect 越晚代表预测器越准、覆盖优先级越高。
//
// 本核是 golden 44818 行里**唯一的真控制逻辑**（其余全是 256 位 ghv 移位、折叠历史
//   扇出、Composer/优先级 mux 黑盒接线）。golden 同名 wrapper 逐字照搬 body 保证等价，
//   本核作为可读再实现 + UT 影子校验存在（详见 docs/frontend/Predictor.md）。
//
// 命名对照（Scala BPU.scala ↔ 本核）：
//   s{1,2,3}_valid_dup / s0_fire_dup / s1_fire_dup / s{1,2}_flush_dup / topdown_stages
//   香山把每个控制信号做了 numDup=4 份复制（dup0..3）以缓解高扇出时序；它们逻辑等价，
//   firtool 把恒等的 dup 合并成 s{1,2,3}_valid_dup_3 一份。本核保留 4 份 fire/flush
//   入口（与 wrapper net 对齐），valid 用单份（与 golden 合并后一致）。
// =============================================================================
module xs_Predictor_core (
  input  logic clock,
  input  logic reset,

  // ---- 组合输入：流水握手 + 覆盖 redirect 判定（来自 Composer 输出 / redirect 判定）----
  input  logic s1_ready,        // Composer 三大带 SRAM 预测器都就绪（放行 s1 新请求）
  input  logic resp_ready,      // FTQ 能收预测（io_bpu_to_ftq_resp.ready）
  input  logic redirect_valid,  // FTQ 来的（已打一拍的）redirect 有效，冲刷整条流水

  input  logic s2_redirect_0, s2_redirect_1, s2_redirect_2, s2_redirect_3, // s2 覆盖（4 dup）
  input  logic s3_redirect_0, s3_redirect_1, s3_redirect_2, s3_redirect_3, // s3 覆盖（4 dup）

  // ---- 组合输入：topdown 气泡原因解码（来自 redirect payload 寄存器）----
  input  logic control_btb_miss,   // 控制流 redirect 且 BTB/FTB 没命中分支
  input  logic control_redirect,   // 这是一次“控制流类” redirect（debugIsCtrl）
  input  logic tage_miss,          // 控制流 redirect 且 TAGE 方向错
  input  logic sc_miss,            // 控制流 redirect 且 SC 统计校正错
  input  logic ittage_miss,        // 控制流 redirect 且 ITTAGE 间接目标错
  input  logic ras_miss_pre,       // = isJalr & jr_hit（与 isRet 相与得 RAS miss）
  input  logic redirect_is_ret,    // redirect 的 cfi 是 ret
  input  logic mem_vio_bubble,     // 访存违例 redirect 气泡
  input  logic other_bubble,       // 其它（非控制/非访存）redirect 气泡
  input  logic btb_miss_bubble,    // BTB miss 气泡（BTBMissBubble 标志）

  // ---- 输出：FSM 状态 + 握手 ----
  output logic s1_valid, s2_valid, s3_valid,   // 三级流水 valid
  output logic resp_valid,                     // 给 FTQ 的 resp.valid
  output logic s0_fire_0, s0_fire_1, s0_fire_2, s0_fire_3, // s0 发射（4 dup）
  output logic s1_fire_0, s1_fire_1, s1_fire_2, s1_fire_3, // s1 发射（4 dup）

  // ---- 输出：topdown 第 3 级（最后一级）气泡原因，直送 FTQ ----
  output logic topdown2_reason_1,  output logic topdown2_reason_2,
  output logic topdown2_reason_3,  output logic topdown2_reason_4,
  output logic topdown2_reason_5,  output logic topdown2_reason_6,
  output logic topdown2_reason_7,  output logic topdown2_reason_8,
  output logic topdown2_reason_9,  output logic topdown2_reason_12
);

  // ---------------------------------------------------------------------------
  // 1. 各级 redirect 的 dup 聚合
  //    s2/s3 覆盖 redirect 各有 4 份 dup；下游分别按 dup 使用（flush 用对应 dup）。
  // ---------------------------------------------------------------------------
  logic [3:0] s2_redirect, s3_redirect;
  assign s2_redirect = {s2_redirect_3, s2_redirect_2, s2_redirect_1, s2_redirect_0};
  assign s3_redirect = {s3_redirect_3, s3_redirect_2, s3_redirect_1, s3_redirect_0};

  // ---------------------------------------------------------------------------
  // 2. flush 链（组合）
  //    s3 冲刷 = FTQ redirect（外部强冲刷）。
  //    s2 冲刷 = s3 冲刷 ∨ s3 覆盖（更晚的 s3 一旦覆盖，s2 在管的旧请求作废）。
  //    s1 冲刷 = s2 冲刷 ∨ s2 覆盖。
  //    每一项都按 dup 展开（高扇出复制）。
  // ---------------------------------------------------------------------------
  logic [3:0] s2_flush, s1_flush;
  for (genvar d = 0; d < 4; d++) begin : g_flush
    // s3_flush 对所有 dup 都等于 redirect_valid
    assign s2_flush[d] = redirect_valid | s3_redirect[d];
    assign s1_flush[d] = s2_flush[d]    | s2_redirect[d];
  end

  // ---------------------------------------------------------------------------
  // 3. fire（组合）
  //    s1_fire = s1 有有效预测且 FTQ 能收（把 s1 这一拍的结果推下去）。
  //    s0_fire = Composer 就绪 且 (s1 即将让位 | s1 当前为空)：可以发新 s0 请求。
  //    （golden 里 s1_fire/ s0_fire 都做了 4 dup；valid 用合并后的单份。）
  // ---------------------------------------------------------------------------
  logic [3:0] s0_fire, s1_fire;
  for (genvar d = 0; d < 4; d++) begin : g_fire
    assign s1_fire[d] = s1_valid & resp_ready;
    assign s0_fire[d] = s1_ready & (s1_fire[d] | ~s1_valid);
  end
  assign {s0_fire_3, s0_fire_2, s0_fire_1, s0_fire_0} = s0_fire;
  assign {s1_fire_3, s1_fire_2, s1_fire_1, s1_fire_0} = s1_fire;

  // ---------------------------------------------------------------------------
  // 4. 三级 valid 寄存器（同步推进 / 冲刷；async reset 清 0）
  //
  //  s1_valid' : redirect 强清；否则任一 dup 发了 s0（进新请求）则置 1；
  //              已被 flush 或已 fire 走则清 0；否则保持。
  //              （golden 把 4 dup 的 set/keep 条件做成嵌套 or，等价于“任一 dup s0_fire
  //               则 set；在未 flush/fire/redirect 时保持”。）
  //  s2_valid' : s2 被冲刷则清；否则 s1 fire 进来（且该拍未被 s1_flush）则装入；
  //              s2 自己 fire 走则清。
  //  s3_valid' : redirect 清；否则 s2 有效且未被 s2_flush 则推进到 s3；
  //              s3 fire（= s3_valid 自身，见下）走则清。
  //
  //  注：s2_fire/s3_fire 在 golden 里因 Composer 的 s2/s3 always-ready 退化为
  //      s2_fire=s2_valid、s3_fire=s3_valid，故 valid 的“fire 后清零”表现为自然流动。
  // ---------------------------------------------------------------------------
  logic next_s1_valid, next_s2_valid, next_s3_valid;

  always_comb begin
    // s1：redirect 优先清零；否则按 dup 优先级链（任一 s0_fire 置位，未冲刷/未fire保持）
    next_s1_valid =
      ~redirect_valid
      & ( s0_fire_3
        | ~(s1_flush[3] | s1_fire[3] | redirect_valid)
          & ( s0_fire_2
            | ~(s1_flush[2] | s1_fire[2] | redirect_valid)
              & ( s0_fire_1
                | ~(s1_flush[1] | s1_fire[1] | redirect_valid)
                  & ( s0_fire_0
                    | ~(s1_flush[0] | s1_fire[0]) & s1_valid ))));

    // s2：被冲刷清零；否则 s1 fire 装入（未被 s1_flush）；s2 已有则按链保持
    next_s2_valid =
      ~s2_flush[3]
      & ( s1_fire[3] ? ~s1_flush[3]
        : ~(s2_valid | s2_flush[2])
          & ( s1_fire[2] ? ~s1_flush[2]
            : ~(s2_valid | s2_flush[1])
              & ( s1_fire[1] ? ~s1_flush[1]
                : ~(s2_valid | s2_flush[0]) & s1_fire[0] & ~s1_flush[0] )));

    // s3：redirect 清零；否则 s2 推进到 s3（未被 s2_flush）
    //     （s3_keep 项在 s3_valid|redirect 时为 0，自然清零）
    next_s3_valid =
      ~redirect_valid
      & ( s2_valid ? ~s2_flush[3]
        : ~(s3_valid | redirect_valid)
          & ( s2_valid ? ~s2_flush[2]
            : ~(s3_valid | redirect_valid)
              & ( s2_valid ? ~s2_flush[1]
                : ~(s3_valid | redirect_valid) & s2_valid & ~s2_flush[0] )));
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s1_valid <= 1'b0;
      s2_valid <= 1'b0;
      s3_valid <= 1'b0;
    end else begin
      s1_valid <= next_s1_valid;
      s2_valid <= next_s2_valid;
      s3_valid <= next_s3_valid;
    end
  end

  // ---------------------------------------------------------------------------
  // 5. 向 FTQ 的 resp.valid（组合）
  //    三种情形给 FTQ 送预测：
  //      ① s1 当拍有有效预测（首版预测，最常见）；
  //      ② s2 有效且 s2 发生覆盖（s2 用新结果重发）；
  //      ③ s3 有效且 s3 发生覆盖。
  //    覆盖判定用 dup_2（与 golden resp.valid 取的 dup 一致）。
  // ---------------------------------------------------------------------------
  assign resp_valid = s1_valid
                    | (s2_valid & s2_redirect_2)
                    | (s3_valid & s3_redirect_2);

  // ---------------------------------------------------------------------------
  // 6. topdown 气泡原因 3 级流水（性能分析）
  //    每个原因是一比特“本拍是否因该原因产生气泡”。3 级寄存器把 stage0 的判定
  //    沿流水逐级 shift，并在每级 OR 上本级新发生的同类原因，最后一级（stage2）
  //    送 FTQ。reason 编号沿用 TopDownCounters：
  //      1=Override/ControlRedirect  2=FtqUpdate(s1_ready=0) 3=TAGEMiss 4=SCMiss
  //      5=ITTAGEMiss 6=RASMiss 7=MemVio 8=Other 9=FtqFullStall(resp 不 ready)
  //      12=BTBMiss
  //    stage0 的源（组合）：
  // ---------------------------------------------------------------------------
  logic src_r1, src_r2, src_r3, src_r4, src_r5, src_r6, src_r7, src_r8, src_r9, src_r12;
  assign src_r1  = s3_redirect_0 | s2_redirect_0;            // override 气泡
  assign src_r2  = ~s1_ready;                                // s1 组件没就绪（FtqUpdate 气泡）
  assign src_r3  = control_redirect & ~control_btb_miss & tage_miss;
  assign src_r4  = control_redirect & ~(control_btb_miss | tage_miss) & sc_miss;
  assign src_r5  = control_redirect & ~(control_btb_miss | tage_miss | sc_miss) & ittage_miss;
  assign src_r6  = control_redirect
                 & ~(control_btb_miss | tage_miss | sc_miss | ittage_miss)
                 & ras_miss_pre & redirect_is_ret;           // RAS miss
  assign src_r7  = mem_vio_bubble;
  assign src_r8  = other_bubble;
  assign src_r9  = ~resp_ready;                              // FTQ 满，stall
  assign src_r12 = btb_miss_bubble | (control_redirect & control_btb_miss);

  // 3 级 shift-and-OR：stage_i+1 = (本级新源) | stage_i。注意 golden 各 reason 的
  // 累积深度不同（有的从 stage0 起累、有的只在某些级注入），逐位照搬其递推式。
  logic [9:0] td0, td1, td2; // 位序: {r12,r9,r8,r7,r6,r5,r4,r3,r2,r1}
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      td0 <= '0; td1 <= '0; td2 <= '0;
    end else begin
      // stage0：本拍直接判定
      td0[0] <= src_r1;  td0[1] <= src_r2;  td0[2] <= src_r3;  td0[3] <= src_r4;
      td0[4] <= src_r5;  td0[5] <= src_r6;  td0[6] <= src_r7;  td0[7] <= src_r8;
      td0[8] <= src_r9;  td0[9] <= src_r12;
      // stage1：r1 注入 s3_redirect；r3..r6/r12 注入本级新源；其余纯搬运
      td1[0] <= s3_redirect_0 | td0[0];
      td1[1] <= td0[1];
      td1[2] <= src_r3  | td0[2];
      td1[3] <= src_r4  | td0[3];
      td1[4] <= src_r5  | td0[4];
      td1[5] <= src_r6  | td0[5];
      td1[6] <= mem_vio_bubble | td0[6];
      td1[7] <= other_bubble   | td0[7];
      td1[8] <= td0[8];
      td1[9] <= src_r12 | td0[9];
      // stage2：同 stage1 的注入规律继续累积
      td2[0] <= td1[0];
      td2[1] <= td1[1];
      td2[2] <= src_r3  | td1[2];
      td2[3] <= src_r4  | td1[3];
      td2[4] <= src_r5  | td1[4];
      td2[5] <= src_r6  | td1[5];
      td2[6] <= mem_vio_bubble | td1[6];
      td2[7] <= other_bubble   | td1[7];
      td2[8] <= td1[8];
      td2[9] <= src_r12 | td1[9];
    end
  end

  assign topdown2_reason_1  = td2[0];
  assign topdown2_reason_2  = td2[1];
  assign topdown2_reason_3  = td2[2];
  assign topdown2_reason_4  = td2[3];
  assign topdown2_reason_5  = td2[4];
  assign topdown2_reason_6  = td2[5];
  assign topdown2_reason_7  = td2[6];
  assign topdown2_reason_8  = td2[7];
  assign topdown2_reason_9  = td2[8];
  assign topdown2_reason_12 = td2[9];

endmodule
