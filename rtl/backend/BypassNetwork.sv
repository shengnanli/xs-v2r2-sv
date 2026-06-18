// =============================================================================
// xs_BypassNetwork_core —— 香山 V2R2(昆明湖) 旁路网络 (可读重写)
// -----------------------------------------------------------------------------
// 设计源:src/main/scala/xiangshan/backend/datapath/BypassNetwork.scala
//        (class BypassNetwork) + DataSource.scala。
//
// 位置与角色:位于「读寄存器(DataPath)」与「执行单元(ExuBlock)」之间。它把各旁路源
//   EXU 的在飞结果(尚未写回物理寄存器堆)直接路由给正在准备发射的 uop 的源操作数,
//   从而省掉「写回再读回」的往返,缩短 RAW 关键路径。
//
//   关键认识:**旁路匹配早已由发射队列(IssueQueue)在唤醒阶段完成**。IQ 决定了某源
//   操作数将来自哪个旁路源 EXU,并把该决策编码进 DataPath 透传过来的两个字段:
//     * dataSources[*].value —— 该源操作数取哪种来源(forward/bypass/imm/reg/...,
//                               见 bypassnetwork_pkg::data_source_e)。
//     * exuSources[*].value  —— 若取 forward/bypass,旁路源 EXU 在「唤醒源组」内的序号
//                               (从 1 起;0 表示无该旁路源)。
//   因此本网络**不做 pdest==pdest 的比较**,只按这两个字段做选择。Scala 里用
//   forwardOrBypassValidVec3(one-hot)+ Mux1H 表达;firtool 把 one-hot 展平成长长的
//   OR-mux 链。这里还原成「按 exuSources.value 的一次索引选择」,语义等价且可读。
//
// 旁路源拓扑(本配置):27 个 EXU 中有 10 路是旁路源 = 整数 4 + 浮点 3 + 访存 3。
//   消费侧分两组、各自只监听一个子集:
//     * 整数/访存 消费者 → INT 组 7 路:{int0,int1,int2,int3, mem2,mem3,mem4}
//     * 浮点     消费者 → FP  组 3 路:{fp0,fp1,fp2}
//   每路有两份数据:forward(本拍直出)与 bypass(寄存一拍)。
//
// 二级旁路(bypass2):Scala 为 VF/Load 向量域预留了第二级旁路;在当前 BackendParams
//   下 readBypass2 对所有消费者恒为 false(golden 里无任何 4'h3 分支),故本核不实现
//   bypass2 数据通路(仅在 pkg 注释中说明),与 golden 完全一致。
//
// 结构:
//   1. 旁路数据向量:forward(组合) / bypass(寄存)各 10 路,用 genvar/for 生成。
//   2. RegCache 回写(toDataPath):7 路 wen/data,各打一拍,用 for 生成。
//   3. 源操作数选择:function automatic sel_*,按 data_source_e 做来源选择。
//   4. 端口级互联(bypassnetwork_body.svh):71 个源操作数调用 sel_*;其余 bits/valid
//      直通、ready 反向、各 EXU 异构(可读来源子集/立即数模块)由生成表给出。
//
// 验证:UT 与 golden BypassNetwork 双例化逐拍比对全部 643 输出;ImmExtractor 各变体
//       作两侧共享的 golden 黑盒。FM 以 ImmExtractor 为黑盒做签名等价。
// =============================================================================
module xs_BypassNetwork_core
  import bypassnetwork_pkg::*;
(
  input logic clock,
  input logic reset,
  `include "bypassnetwork_ports.svh"
);

  // ==========================================================================
  // 0. 旁路源 EXU 的在飞结果(valid + data)集中成数组,便于按序号索引。
  // --------------------------------------------------------------------------
  // 顺序与「全局位号」对应,但消费侧按组监听:
  //   INT 组 7 路: int0..3, mem2..4
  //   FP  组 3 路: fp0..2
  // (fp0 的写回数据是 128bit,旁路只取低 64bit,与 golden 的 [63:0] 一致。)
  // ==========================================================================
  bypass_src_t int_src[INT_FWD_NUM];   // int0..3, mem2..4
  bypass_src_t fp_src [FP_FWD_NUM];     // fp0..2

  always_comb begin
    int_src[0] = '{io_fromExus_int_0_0_valid, io_fromExus_int_0_0_bits_intWen, io_fromExus_int_0_0_bits_data};
    int_src[1] = '{io_fromExus_int_1_0_valid, io_fromExus_int_1_0_bits_intWen, io_fromExus_int_1_0_bits_data};
    int_src[2] = '{io_fromExus_int_2_0_valid, io_fromExus_int_2_0_bits_intWen, io_fromExus_int_2_0_bits_data};
    int_src[3] = '{io_fromExus_int_3_0_valid, io_fromExus_int_3_0_bits_intWen, io_fromExus_int_3_0_bits_data};
    int_src[4] = '{io_fromExus_mem_2_0_valid, io_fromExus_mem_2_0_bits_intWen, io_fromExus_mem_2_0_bits_data};
    int_src[5] = '{io_fromExus_mem_3_0_valid, io_fromExus_mem_3_0_bits_intWen, io_fromExus_mem_3_0_bits_data};
    int_src[6] = '{io_fromExus_mem_4_0_valid, io_fromExus_mem_4_0_bits_intWen, io_fromExus_mem_4_0_bits_data};
    // fp0 写回为 128bit,旁路只取低 64bit(与 golden 的 [63:0] 一致);intWen 不适用,置 0。
    fp_src[0]  = '{io_fromExus_fp_0_0_valid, 1'b0, io_fromExus_fp_0_0_bits_data[XLEN-1:0]};
    fp_src[1]  = '{io_fromExus_fp_1_0_valid, 1'b0, io_fromExus_fp_1_0_bits_data};
    fp_src[2]  = '{io_fromExus_fp_2_0_valid, 1'b0, io_fromExus_fp_2_0_bits_data};
  end

  // ==========================================================================
  // 1. bypass 数据 = 旁路源结果寄存一拍(仅在该源 valid 时更新,省功耗)。
  // --------------------------------------------------------------------------
  // forward 直接用本拍的 *_src_data;bypass 用下面寄存后的副本。对应 Scala 的
  //   bypassDataVec = RegEnable(forwardData, valid)。
  // ==========================================================================
  // forward 用本拍数据;bypass 用寄存一拍后的数据。两者都打包成 packed 总线,
  // 既便于按序号选择,又能作为函数实参整体传入(packed 实参敏感性可靠,且不触发
  // FM 的「函数读非局部变量」告警——见 pick_* 注释)。
  logic [INT_FWD_NUM-1:0][XLEN-1:0] int_fwd_bus, int_byp_bus;
  logic [FP_FWD_NUM-1:0] [XLEN-1:0] fp_fwd_bus,  fp_byp_bus;

  for (genvar k = 0; k < INT_FWD_NUM; k++) begin : g_int_byp
    assign int_fwd_bus[k] = int_src[k].data;
    always_ff @(posedge clock) if (int_src[k].valid) int_byp_bus[k] <= int_src[k].data;
  end
  for (genvar k = 0; k < FP_FWD_NUM; k++) begin : g_fp_byp
    assign fp_fwd_bus[k] = fp_src[k].data;
    always_ff @(posedge clock) if (fp_src[k].valid) fp_byp_bus[k] <= fp_src[k].data;
  end

  // ==========================================================================
  // 2. 源操作数选择函数(按 data_source_e)。
  // --------------------------------------------------------------------------
  // 旁路匹配已退化为「按 exuSrc 序号索引」:exuSrc∈1..N 选第 (exuSrc-1) 路,0 表示无。
  // 用三元 mux 防止 array[越界/X 索引] 恒 X(X 铁律):exuSrc 超范围一律给 0。
  // 每个消费者实际允许的来源子集不同(int 有 imm/regcache,fp 没有……),故把所有
  // 可能来源都作实参传入,由调用点(生成的 body.svh)按该 EXU 的真实子集传 0 占位。
  // ==========================================================================

  // 按序号在 INT 组 7 路 packed 总线里选数据(越界给 0)。总线整体作实参传入
  // (而非读模块级变量),既保证连续/always_comb 求值敏感性,又避免 FM 把「函数读
  //  非局部变量」当作不可综合而拒读设计。
  function automatic logic [XLEN-1:0] pick_int(
      logic [2:0] exu_src, logic [INT_FWD_NUM-1:0][XLEN-1:0] bus);
    logic [XLEN-1:0] r;
    r = '0;
    for (int k = 0; k < INT_FWD_NUM; k++)
      if (exu_src == (k + 1)) r = bus[k];
    return r;
  endfunction
  function automatic logic [XLEN-1:0] pick_fp(
      logic [1:0] exu_src, logic [FP_FWD_NUM-1:0][XLEN-1:0] bus);
    logic [XLEN-1:0] r;
    r = '0;
    for (int k = 0; k < FP_FWD_NUM; k++)
      if (exu_src == (k + 1)) r = bus[k];
    return r;
  endfunction

  // Load EXU 的 src0 立即数(immLoadSrc0):直接对 immInfo.imm 取 U 型高 20 位、
  // 低 12 位补 0,再符号扩展到 XLEN。对应 Scala:
  //   SignExt(ImmUnion.U.toImm32(imm[31:I.len]), XLEN)
  // (Load 的有效地址 = base + 偏移,偏移来自 U 型立即数;此处不经 ImmExtractor 黑盒,
  //  与 golden 一致地内联展开。)
  function automatic logic [XLEN-1:0] load_imm_u(logic [31:0] imm);
    return {{32{imm[31]}}, imm[31:12], 12'h0};
  endfunction

  // 整数/访存消费者的标量源选择:forward/bypass(已由 pick_int 在调用点按 exuSrc
  // 选好,作 fwd_data/byp_data 传入)、立即数、寄存器缓存、物理寄存器堆;其余(zero
  // 等)落到默认 0。所有候选都作实参,函数不读任何模块级变量(综合/FM 友好)。
  function automatic logic [XLEN-1:0] sel_int_src(
      data_source_e ds, logic [XLEN-1:0] fwd_data, logic [XLEN-1:0] byp_data,
      logic [XLEN-1:0] reg_data, logic [XLEN-1:0] rc_data, logic [XLEN-1:0] imm_data);
    unique case (ds)
      DS_FORWARD : sel_int_src = fwd_data;
      DS_BYPASS  : sel_int_src = byp_data;
      DS_IMM     : sel_int_src = imm_data;
      DS_REGCACHE: sel_int_src = rc_data;
      DS_REG     : sel_int_src = reg_data;
      default    : sel_int_src = '0;   // DS_ZERO 等
    endcase
  endfunction

  // 浮点消费者的标量源选择:只支持 forward/bypass(已选好传入)与寄存器。
  function automatic logic [XLEN-1:0] sel_fp_src(
      data_source_e ds, logic [XLEN-1:0] fwd_data, logic [XLEN-1:0] byp_data,
      logic [XLEN-1:0] reg_data);
    unique case (ds)
      DS_FORWARD : sel_fp_src = fwd_data;
      DS_BYPASS  : sel_fp_src = byp_data;
      DS_REG     : sel_fp_src = reg_data;
      default    : sel_fp_src = '0;
    endcase
  endfunction

  // 向量(vf / load-vec mem)消费者的向量源选择(128bit)。来源只有:
  //   * V0    : 取该 EXU 已解析好的 v0 操作数(传入 v0_data,可能含 reg 或 imm 成分)。
  //   * IMM   : 立即数(部分 vf 端口支持)。
  //   * REG   : 物理(向量)寄存器堆读出。
  // 这里所有候选都作实参传入,不支持的来源由调用点传 0。
  function automatic logic [VLEN-1:0] sel_vec_src(
      data_source_e ds, logic [VLEN-1:0] v0_data,
      logic [VLEN-1:0] reg_data, logic [VLEN-1:0] imm_data);
    unique case (ds)
      DS_V0  : sel_vec_src = v0_data;
      DS_IMM : sel_vec_src = imm_data;
      DS_REG : sel_vec_src = reg_data;
      default: sel_vec_src = '0;
    endcase
  endfunction

  // ==========================================================================
  // 2b. 分支单元(Brh)专用:立即数与下一条 PC 偏移。
  // --------------------------------------------------------------------------
  // 含分支 FU 的发射端口(int_0_1 / int_1_1 / int_2_1)需要在旁路网络里就把分支
  // 立即数算成「相对当前 PC 的字节偏移」:
  //   immBJU = imm + (isJALR ? 0 : (ftqOffset << 1))
  // 其中 isJALR = isJump(fuType) & jalr(fuOpType),本配置编码为 fuType[0]&fuOpType[0];
  // ftqOffset << 1 把 FTQ 内的「2 字节为单位的指令槽偏移」换算成字节偏移(对应
  // instOffsetBits=1)。对应 Scala 的 hasBrhFu 分支块。
  function automatic logic [XLEN-1:0] brh_imm(
      logic [XLEN-1:0] imm, logic is_jalr, logic [3:0] ftq_offset);
    logic [4:0] off;
    off = is_jalr ? 5'h0 : {ftq_offset, 1'b0};
    return imm + {{(XLEN-5){1'b0}}, off};
  endfunction
  // 下一条指令的 PC 偏移(分支不跳时):RVC(压缩指令)+1,否则 +2(以 2 字节为单位)。
  function automatic logic [4:0] brh_next_pc_off(logic [3:0] ftq_offset, logic is_rvc);
    return {1'b0, ftq_offset} + (is_rvc ? 5'h1 : 5'h2);
  endfunction

  // ==========================================================================
  // 3. RegCache 回写(io_toDataPath):把会写 RegCache 的旁路源(int×4 + mem2/3/4,
  //    共 7 路)的 bypass 数据连同 wen 各打一拍写回 DataPath 的寄存器缓存。
  // --------------------------------------------------------------------------
  // 对应 Scala:bypassIntWenVec = RegNext(valid & intWen);data = bypassDataVec。
  // 7 路顺序与 INT 组前 7 路一致(int0..3, mem2..4)。
  // ==========================================================================
  logic            rc_wen [INT_FWD_NUM];
  logic [XLEN-1:0] rc_data[INT_FWD_NUM];

  for (genvar k = 0; k < INT_FWD_NUM; k++) begin : g_rc_wb
    always_ff @(posedge clock or posedge reset) begin
      if (reset) rc_wen[k] <= 1'b0;
      else       rc_wen[k] <= int_src[k].valid & int_src[k].int_wen;
    end
    // data 与 bypass 同源(寄存一拍),直接复用 int_byp_bus。
    assign rc_data[k] = int_byp_bus[k];
  end

  // ==========================================================================
  // 4. 端口级互联(自动生成):
  //    - 71 个源操作数:调用上面的 sel_* 函数;
  //    - valid 前向 / bits 直通 / ready 反向;
  //    - toDataPath 7 路接 rc_wen/rc_data;
  //    - 各 EXU 的来源子集差异、立即数模块(ImmExtractor 黑盒)实例化在此。
  // ==========================================================================
  `include "bypassnetwork_body.svh"

endmodule : xs_BypassNetwork_core
