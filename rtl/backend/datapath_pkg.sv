// =============================================================================
// datapath_pkg —— 香山 V2R2(昆明湖) 数据通路 DataPath 的参数与类型定义
// -----------------------------------------------------------------------------
// 设计源:src/main/scala/xiangshan/backend/datapath/DataPath.scala (class DataPathImp)
//
// 背景(DataPath 在后端的位置与职责):
//   发射队列(IssueQueue, Scheduler)在唤醒-选择后,把准备发射的 uop(IssueQueueIssueBundle)
//   送到 DataPath。DataPath 处于「发射」与「执行(ExuBlock/FU)」之间,负责一个流水级
//   (s0 -> s1)的「读寄存器 + 路由操作数」:
//
//     s0(发射拍): 对每条 uop 的每个源操作数:
//        * 若来源是物理寄存器(dataSources.readReg)→ 向对应域的「读口仲裁器」
//          (RFReadArbiter)申请一个 PRF 读口,带上 preg 地址。
//        * 同时按 rfWen/fpWen/... 向「写回冲突检查器」(RFWBCollideChecker)申请写口,
//          确认本拍发射不会与正在写回的端口在 regfile 写口上冲突。
//        * 仲裁/冲突都通过(notBlock)→ s0.ready=1,uop 被接收;否则回压并给 IQ
//          发 og0resp(block)。
//        把 uop 的控制信息(ExuInput,除源数据外)、addrOH、立即数信息打入 s1 流水寄存器。
//
//     s1(读回拍): 物理寄存器堆是同步读(地址打一拍,数据延迟一拍出),故读出数据在
//        s1 才有效。DataPath 在 s1:
//        * 把各域 regfile 的读出数据(intRfRdata/fpRfRdata/...)按该 EXU 端口的
//          rfrPortConfigs(端口→哪个域哪个读口)分发到 s1_*PregRData;
//        * 对每个源操作数,按 srcType(Xp/Fp/Vp/V0/Vec)用 Mux1H 在「整数/浮点/向量/
//          v0/vl 读出数据」里选出真正的源数据,送给执行单元(toExu.bits.src)。
//        * 把 s1_valid/s1_data 送 toExu;若 og1 仲裁失败或 redirect/ldCancel,取消并
//          给 IQ 发 og1resp。
//
//   旁路(forward/bypass)不在 DataPath 做,而在其后的 BypassNetwork;DataPath 只负责
//   「读 PRF + RegCache + 透传立即数信息(og1ImmInfo)」。立即数的最终扩展也在
//   BypassNetwork(ImmExtractor)完成,DataPath 仅把 imm/immType 打一拍透传出去。
//
//   RegCache(寄存器缓存)的读请求/读数据路由也在 DataPath:整数/访存 IQ 的整数源
//   按 rcIdx 发 RegCache 读,读出数据经 s1 送 BypassNetwork(toBypassNetworkRCData)。
//
// 子模块(本核全部作 golden 黑盒,见 datapath_blackbox.svh):
//   IntRegFilePart0..3 / FpRegFilePart0..3 / VfRegFilePart0..3 / V0RegFilePart0..1 /
//   VlRegFile           —— 物理寄存器堆(按数据位竖切的分片;见 RegFilePart.sv)
//   IntRFReadArbiter 等 —— 各域读口仲裁器(多 IQ 竞争有限 PRF 读口)
//   IntRFWBCollideChecker 等 —— 写回-发射写口冲突检查器
//   RegCache            —— 寄存器缓存(见 RegCache.sv)
//   UIntExtractor_27_*  —— exuSources one-hot 散布到 27 位全局 EXU 空间(s0_cancel 用)
//   DelayN_1 / DelayReg / DummyDPICWrapper —— top-down 性能延迟 / difftest 探针(黑盒)
// =============================================================================
package datapath_pkg;

  // ---- 全局位宽(昆明湖实例值)----
  localparam int XLEN     = 64;   // 整数数据通路位宽
  localparam int VLEN     = 128;  // 向量寄存器位宽
  localparam int IMM_W    = 32;   // 压缩立即数(minBits 载体)位宽
  localparam int IMMTYPE_W= 4;    // selImm 类型码位宽

  // ---- 物理寄存器地址位宽(各域 numPregs 推导)----
  localparam int INT_PREG_W = 8;  // 整数 PRF 地址位宽(224 pregs)
  localparam int FP_PREG_W  = 8;  // 浮点 PRF 地址位宽(192 pregs)
  localparam int VF_PREG_W  = 8;  // 向量 PRF 地址位宽
  localparam int V0_PREG_W  = 4;  // v0 PRF 地址位宽
  localparam int VL_PREG_W  = 4;  // vl PRF 地址位宽

  // ============================================================================
  // dataSources 编码(EntryBundles.scala 的 DataSource):决定某源操作数取哪种来源。
  //   firtool 把 readReg 等价成「value == 4'b1000」即 value[3];readRegCache=value[2]…
  //   DataPath 只关心 readReg(是否要占 PRF 读口)。完整来源在 BypassNetwork 用。
  // ----------------------------------------------------------------------------
  //   注:DataPath 里判断「该源是否读寄存器」用的是 dataSources.value 的 bit3
  //       (readReg)。这里给出 enum 仅作可读性参考,核内主要用 readReg() 帮助函数。
  // ============================================================================
  typedef enum logic [3:0] {
    DS_ZERO     = 4'h0,  // 源为 0(x0 等)
    DS_FORWARD  = 4'h1,  // 旁路:本拍直出(BypassNetwork 处理)
    DS_BYPASS   = 4'h2,  // 旁路:寄存一拍(BypassNetwork 处理)
    DS_IMM      = 4'h4,  // 立即数(BypassNetwork/ImmExtractor 处理)
    DS_V0       = 4'h5,  // v0 掩码源
    DS_REGCACHE = 4'h6,  // 寄存器缓存命中
    DS_REG      = 4'h8   // 物理寄存器堆(本模块 readReg() 关注)
  } data_source_e;

  // 该源是否需要读物理寄存器堆(占用一个 PRF 读口 + 走读口仲裁)。
  // 对应 Scala dataSources(src).readReg,firtool 实现为 value[3]。
  function automatic logic ds_read_reg(logic [3:0] value);
    return value[3];
  endfunction
  // 该源是否读 RegCache(对应 readRegCache,value[? ]——见 EntryBundles)。
  function automatic logic ds_read_regcache(logic [3:0] value);
    return value == DS_REGCACHE;
  endfunction

  // ============================================================================
  // srcType 编码(package.scala 的 SrcType):s1 选择从哪个域的 PRF 读出数据。
  //   isXp(整数)/isFp(浮点)/isVp(向量,含 vf)/isV0/isVec 等。Mux1H 用。
  //   这里给出与 SrcType 一致的判定帮助函数(reg 类型读出数据按 srcType 路由)。
  // ============================================================================
  // SrcType: imm=0, xp(int)=1, fp=2, vp(vec)=3, v0=... (具体编码见 SrcType 对象)
  // DataPath 的 s1 src Mux1H 用 SrcType.isXp / isFp / isVp / isV0 判定。下面三个
  // 帮助函数对齐 golden 里 firtool 展开的位判断(srcType 为 3~4 位编码)。
  function automatic logic srctype_is_int(logic [3:0] t); return t == 4'h1; endfunction
  function automatic logic srctype_is_fp (logic [3:0] t); return t == 4'h2; endfunction
  function automatic logic srctype_is_vec(logic [3:0] t); return t == 4'h3; endfunction

  // 访存 STD(store-data)类端口某源可同时读 int|fp,按 s1 寄存的 srcType 做 2 路 Mux1H。
  // SrcType 在该位置以低位 one-hot 表达:bit0=整数(xp), bit1=浮点(fp)。对应 Scala
  //   Mux1H(Seq(isXp -> intData, isFp -> fpData))。
  function automatic logic [XLEN-1:0] sel_src_intfp(
      logic [3:0] s1_srctype, logic [XLEN-1:0] int_data, logic [XLEN-1:0] fp_data);
    return ({XLEN{s1_srctype[0]}} & int_data) | ({XLEN{s1_srctype[1]}} & fp_data);
  endfunction

  // ============================================================================
  // og 响应类型 RespType(回送 IQ,决定该项如何处置)。
  //   success   -> IQ 项清除(发射成功);
  //   uncertain -> IQ 项不动(ld/st 地址、向量等要到 og2 才确定);
  //   block     -> 该项 issued 置 false,稍后重发(读口/写口抢占失败)。
  // ============================================================================
  typedef enum logic [1:0] {
    RESP_SUCCESS   = 2'h3,
    RESP_BLOCK     = 2'h0,
    RESP_UNCERTAIN = 2'h1
  } resp_type_e;

  // ============================================================================
  // flush 信息(Redirect 的相关字段):s1_flush 判定需当拍 io.flush 与打一拍的
  //   RegNext(io.flush)。把 {valid, level, robIdx} 聚成 struct,流水寄存更清晰。
  // ============================================================================
  typedef struct packed {
    logic       valid;        // 该 flush 有效
    logic       level;        // flushItself:level=1 含冲自身 robIdx
    logic       robIdx_flag;  // 环形队列指针 flag(翻转位)
    logic [7:0] robIdx_value; // 环形队列指针 value
  } flush_info_t;

  // ============================================================================
  // CircularQueuePtr.needFlush:robIdx 是否被某次 flush 冲掉。
  //   flushItself(同一 robIdx 且 level 含自身)或 「比 flush 的 robIdx 更新(year)」。
  //   robIdx = {flag, value};比较用 (flag ^ flag') ^ (value > value') 表达环形「更老/更新」。
  //   对应 Scala robIdx.needFlush(Seq(io.flush, RegNext(io.flush)))。
  // ============================================================================
  function automatic logic rob_need_flush(
      logic my_flag, logic [7:0] my_value, flush_info_t fl);
    logic same_rob, flush_self, is_after;
    same_rob   = (my_flag == fl.robIdx_flag) && (my_value == fl.robIdx_value);
    flush_self = fl.level && same_rob;                                  // level=1 含冲自身
    is_after   = (my_flag ^ fl.robIdx_flag) ^ (my_value > fl.robIdx_value); // 环形:my 更新
    return fl.valid && (flush_self || is_after);
  endfunction

  // is0latency(fuType):该 FU 是否 0 延迟(单拍出结果)。对应 FuType.is0latency,
  //   firtool 展开为 fuType 特定位的 OR(ALU/Branch/...等单周期 FU)。
  //   0 延迟唤醒源在 og0 失败时要广播取消(og0_cancel_delay)。
  function automatic logic is_0latency(logic [34:0] fuType);
    return fuType[0] | fuType[1] | fuType[3] | fuType[4] | fuType[6]
         | fuType[16] | fuType[17] | fuType[28] | fuType[29] | fuType[30];
  endfunction

  // ============================================================================
  // s0_cancel(0 延迟唤醒取消):某 uop 的某个源操作数若来自一个「0 延迟、非 load 的
  //   EXU 唤醒」(dataSources==4'h1,即上一拍被该 EXU 唤醒并预约转发),而该唤醒 EXU
  //   恰在上一拍 og0 失败(og0_cancel_delay 置位),则本拍这条 uop 的源数据将拿不到,
  //   必须取消接收(s0.ready 拉低)。
  //
  //   判定 = 「该源的唤醒 EXU ∈ 上拍 og0 失败的 0 延迟非 load EXU 集合」:
  //     exuOH = UIntExtractor(1<<exuSource) 把 EXU 编号解码并散布到 27 位全局空间;
  //     该全局空间的偶数位 {0,2,4,...} 一一对应 og0_cancel_delay 各路。两者按位与后
  //     OR 即「命中任一失败唤醒源」。Int/Mem 域唤醒源映射到 delay[6:0](全局偶位
  //     0/2/4/6),Fp 域映射到 delay[12:8](全局偶位 8/10/12)。
  //   与 golden firtool 展开的 {ext[2i],1'h0,..} & _GEN 窗口逐位等价(golden 把奇数位
  //   清零,等价于只取偶数位 2*i 与 og0_cancel_delay[2*i] 逐位与),这里直接用偶位索引
  //   表达,免去拼接。
  function automatic logic wakeup_failed_int(
      logic [26:0] exu_oh, logic [23:0] og0_cancel_delay);
    return (exu_oh[0] & og0_cancel_delay[0])
         | (exu_oh[2] & og0_cancel_delay[2])
         | (exu_oh[4] & og0_cancel_delay[4])
         | (exu_oh[6] & og0_cancel_delay[6]);
  endfunction

  function automatic logic wakeup_failed_fp(
      logic [26:0] exu_oh, logic [23:0] og0_cancel_delay);
    return (exu_oh[8]  & og0_cancel_delay[8])
         | (exu_oh[10] & og0_cancel_delay[10])
         | (exu_oh[12] & og0_cancel_delay[12]);
  endfunction

  // dataSources==4'h1:该源数据「将由上一拍的唤醒 EXU 转发」(forwardExu),只有这种来源
  //   才会被 og0 取消影响(读 PRF / RegCache 的源不受 0 延迟唤醒取消影响)。
  function automatic logic ds_from_forward(logic [3:0] value);
    return value == 4'h1;
  endfunction

endpackage : datapath_pkg
