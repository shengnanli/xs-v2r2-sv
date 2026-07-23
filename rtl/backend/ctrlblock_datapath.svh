// 手写(从 CtrlBlock.scala 设计意图重写,非 golden 转写)。
// ============================================================================
// CtrlBlock 数据通路 glue(round3)。本文件实现两条「打一拍 + 字段直通」宽通路:
//
//   块 3(写回回流 Rob):io.fromWB.wbData[i]  --打一拍-->  delayedNotFlushedWriteBack[i]
//     ・valid = GatedValidRegNext(wbData[i].valid && !killedByOlder)
//              killedByOlder = robIdx.needFlush({s1_s3, s2_s4})  (块1 已算 wbKilledByOlder)
//     ・bits  = RegEnable(wbData[i].bits, wbData[i].valid)        (整 struct 一拍)
//     ・delayedWriteBack[i].valid = GatedValidRegNext(wbData[i].valid)（不杀,送 exuWriteback)
//     ・delayedNotFlushedWriteBackNums[i] = RegEnable(PopCount(同 robIdx 且都未被
//              {s1_s3,s2_s4,s3_s5} 冲掉的同组写回路数), wbData[i].valid)  —— 压缩计数
//
//   块 6(派遣入队 Rob):dispatch.io.enqRob.req[i] --打一拍--> rob.io.enq.req[i]
//     ・valid = RegNext(dispatch.req[i].valid && !io_redirect_valid)
//     ・bits  = RegEnable(dispatch.req[i].bits, dispatch.req[i].valid)  (整 struct 一拍)
//
// 可读化手段:每路全字段收进 struct(wb_exu_output_t / rob_enq_uop_t,见 pkg),
// 整 struct 一条 RegEnable 打拍;多路用 genvar 平铺;压缩计数用纯函数 + PopCount。
// 输入端口 -> struct 的「装包」(机械、逐字段)由 gen 脚本生成到
//   ctrlblock_wbpack.svh / ctrlblock_enqpack.svh,本文件只放真逻辑。
// 输出 struct 字段 -> 子模块输入引脚的连线由 ctrlblock_inst.svh 完成。
// ============================================================================

  genvar gj;

  // ==========================================================================
  // 块 3-A:写回打拍(valid + bits struct)
  // --------------------------------------------------------------------------
  // wbData 27 路(WbNum)。0..24 暴露完整 robIdx,25/26 为 Std FU。
  // 装包信号:wbInValid[i] / wbInBits[i](由 ctrlblock_wbpack.svh 从顶层 io 填)。
  // ==========================================================================
  logic            wbInValid [0:ctrlblock_pkg::WbNum-1];
  wb_exu_output_t  wbInBits  [0:ctrlblock_pkg::WbNum-1];
  `include "ctrlblock_wbpack.svh"   // wbInValid/wbInBits <- 顶层 io_fromWB_wbData_*

  // killedByOlder:仅 0..24 有完整 robIdx 可判;25/26(Std)无 flag,恒不杀(robIdx 不暴露,
  // 其写回不参与异常/压缩,只透传 valid)。块1 已算 wbKilledByOlder[0..24]。
  logic [ctrlblock_pkg::WbNum-1:0] wbKilled;   // 27 路打拍前的「被老 redirect 杀掉」
  generate
    for (gj = 0; gj < ctrlblock_pkg::WbNum; gj++) begin : g_wbkilled
      if (gj < WbRobNum) assign wbKilled[gj] = wbKilledByOlder[gj];
      else               assign wbKilled[gj] = 1'b0;   // Std FU:不参与杀
    end
  endgenerate

  // delayedNotFlushedWriteBack[i]:杀过的 valid + 打拍 bits
  logic            wbDelayedValid [0:ctrlblock_pkg::WbNum-1]; // 送 rob.io.writeback
  logic            wbDelayedValidRaw [0:ctrlblock_pkg::WbNum-1]; // 送 rob.io.exuWriteback(不杀)
  wb_exu_output_t  wbDelayedBits  [0:ctrlblock_pkg::WbNum-1];
  generate
    for (gj = 0; gj < ctrlblock_pkg::WbNum; gj++) begin : g_wbpipe
      // valid:GatedValidRegNext(复位清 0)
      // golden 把这两条 valid 流水放在异步复位块(always @(posedge clock or posedge reset)),
      // 与 FM 对齐须用异步复位而非同步复位,否则 DFF 类型不同 -> not equivalent。
      always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
          wbDelayedValid[gj]    <= 1'b0;
          wbDelayedValidRaw[gj] <= 1'b0;
        end else begin
          wbDelayedValid[gj]    <= wbInValid[gj] & ~wbKilled[gj];
          wbDelayedValidRaw[gj] <= wbInValid[gj];
        end
      end
      // bits:RegEnable(整 struct,enable=输入 valid)
      always_ff @(posedge clock) begin
        if (wbInValid[gj]) wbDelayedBits[gj] <= wbInBits[gj];
      end
    end
  endgenerate

  // ==========================================================================
  // 块 3-B:同 robIdx 压缩计数 delayedNotFlushedWriteBackNums[0..24]
  // --------------------------------------------------------------------------
  // 对每个非 Std 写回口 x,统计「与 x 同 robIdx、x/该口都有效、且两者都未被
  // {s1_s3,s2_s4,s3_s5} 三级 redirect 冲掉」的同组写回路数(PopCount)。
  // 同组成员 canSameRobidxWbData 由调度类型(Int/Fp/Vf/MemVload + i2v/f2v 互通)决定,
  // 与配置强相关;此处直接用从设计提取的固定分组表(每路一组 wbData 下标)。
  //   - 组大,则该口可能同拍收到多条同 robIdx 写回(向量分片/压缩),计数 >1。
  //   - 组为 {自己},则计数恒为 0/1。
  // killedByOlder3[i] = needFlush({s1_s3,s2_s4,s3_s5})(块1 已算 wbKilledByOlder3)。
  // ==========================================================================
  // 每路的三级 killed(0..24);Nums 比较用「两者都未被杀」。
  // 「同 robIdx」判定:两路 robIdx 完全相等(flag+value)。
  function automatic logic same_robidx(
      input logic a_flag, input logic [7:0] a_value,
      input logic b_flag, input logic [7:0] b_value);
    same_robidx = (a_flag == b_flag) && (a_value == b_value);
  endfunction

  // 单条「同组某成员 wb 与本口 x 算作同一条」的布尔:
  //   robIdx 相等 && 两路都有效 && 两路都未被三级 redirect 冲掉
  function automatic logic same_robidx_bool(
      input logic        x_flag,  input logic [7:0] x_value,
      input logic        x_valid, input logic        x_killed3,
      input logic        w_flag,  input logic [7:0] w_value,
      input logic        w_valid, input logic        w_killed3);
    same_robidx_bool = same_robidx(w_flag, w_value, x_flag, x_value)
                       && w_valid && x_valid && !w_killed3 && !x_killed3;
  endfunction

  // 为方便组内引用,先把 0..24 的 robIdx / valid / killed3 收成数组(0 在核内已有,
  // 1..24 在 ctrlblock_wb_robidx.svh 已聚合 wbRobFlag/wbRobValue)。
  // valid 用 wbInValid,killed3 用 wbKilledByOlder3。

  // 各 Nums 口的同组成员下标表(从设计提取,见上注释)。用 localparam 数组表达,
  // genvar 不便索引变长数组,故用 always_comb 累加 + 显式列出每组成员。
  // 计数结果寄存器宽度按组大小取 ceil(log2(size+1))。
  // 组 A(11 路):{0,2,4,6,7,9,10,11,12} ∪ {5,8} —— intCanCompress+fp,宽 4
  // 组 B(16 路):组 A ∪ {13,14,15,16,17}        —— +vf,宽 5
  // 组 C(7 路) :{5,8,13,14,15,16,17}            —— vf 自身组,宽 3
  // 组 D(1 路) :{self}                            —— 宽 1/2
  // 组 E(2 路) :{23,24}                           —— mem vload,宽 2
  // 具体每口归属(self -> 组)见下 case。

  // 把 0..24 的 valid / killed3 / robIdx 统一成数组别名,供压缩计数引用。
  logic        wbV   [0:WbRobNum-1];
  logic        wbK3  [0:WbRobNum-1];
  generate
    for (gj = 0; gj < WbRobNum; gj++) begin : g_wbalias
      assign wbV[gj]  = wbInValid[gj];
      assign wbK3[gj] = wbKilledByOlder3[gj];
    end
  endgenerate

  // 通用:对给定「本口 x」与一组成员下标,累加 same_robidx_bool。
  // 由于 SV function 不能传变长下标集,这里为每种组写一个 PopCount 表达式,
  // 在 always_comb 里按 self 分派。下标集合即上面 A/B/C/D/E。
  // 纯函数:把 0..24 路的 robIdx/valid/killed3 数组作显式入参(不读非局部 -> 避免 FMR_VLOG-091)。
  //   gf/gv = 组成员 robIdx flag/value 数组;gV/gK = 组成员 valid/killed3 数组。
  function automatic logic [4:0] count_group_A(
      input logic [4:0] self,
      input logic gf[0:WbRobNum-1], input logic [7:0] gv[0:WbRobNum-1],
      input logic gV[0:WbRobNum-1], input logic gK[0:WbRobNum-1]); // 11 路
    logic [4:0] n; int unsigned idxs[11]; int k;
    idxs = '{0,2,4,5,6,7,8,9,10,11,12};
    n = '0;
    for (k = 0; k < 11; k++)
      n += same_robidx_bool(gf[self], gv[self], gV[self], gK[self],
                            gf[idxs[k]], gv[idxs[k]], gV[idxs[k]], gK[idxs[k]]);
    count_group_A = n;
  endfunction
  function automatic logic [4:0] count_group_B(
      input logic [4:0] self,
      input logic gf[0:WbRobNum-1], input logic [7:0] gv[0:WbRobNum-1],
      input logic gV[0:WbRobNum-1], input logic gK[0:WbRobNum-1]); // 16 路
    logic [4:0] n; int unsigned idxs[16]; int k;
    idxs = '{0,2,4,5,6,7,8,9,10,11,12,13,14,15,16,17};
    n = '0;
    for (k = 0; k < 16; k++)
      n += same_robidx_bool(gf[self], gv[self], gV[self], gK[self],
                            gf[idxs[k]], gv[idxs[k]], gV[idxs[k]], gK[idxs[k]]);
    count_group_B = n;
  endfunction
  function automatic logic [4:0] count_group_C(
      input logic [4:0] self,
      input logic gf[0:WbRobNum-1], input logic [7:0] gv[0:WbRobNum-1],
      input logic gV[0:WbRobNum-1], input logic gK[0:WbRobNum-1]); // 7 路
    logic [4:0] n; int unsigned idxs[7]; int k;
    idxs = '{5,8,13,14,15,16,17};
    n = '0;
    for (k = 0; k < 7; k++)
      n += same_robidx_bool(gf[self], gv[self], gV[self], gK[self],
                            gf[idxs[k]], gv[idxs[k]], gV[idxs[k]], gK[idxs[k]]);
    count_group_C = n;
  endfunction
  function automatic logic [4:0] count_group_E(
      input logic [4:0] self,
      input logic gf[0:WbRobNum-1], input logic [7:0] gv[0:WbRobNum-1],
      input logic gV[0:WbRobNum-1], input logic gK[0:WbRobNum-1]); // {23,24}
    logic [4:0] n; int unsigned idxs[2]; int k;
    idxs = '{23,24};
    n = '0;
    for (k = 0; k < 2; k++)
      n += same_robidx_bool(gf[self], gv[self], gV[self], gK[self],
                            gf[idxs[k]], gv[idxs[k]], gV[idxs[k]], gK[idxs[k]]);
    count_group_E = n;
  endfunction
  // 组 D({self}):就是 self 自己有效且未被杀。
  function automatic logic [4:0] count_group_D(
      input logic [4:0] self,
      input logic gV[0:WbRobNum-1], input logic gK[0:WbRobNum-1]);
    count_group_D = {4'd0, (gV[self] & ~gK[self])};
  endfunction

  // 每口 self -> 组的归属(从设计提取):
  //   组 A:0,2,4,6,7,9,10,11,12   组 B:5,8   组 C:13,14,15,16,17
  //   组 D:1,3,18,19,20,21,22      组 E:23,24
  function automatic logic [4:0] wb_compress_count(
      input logic [4:0] self,
      input logic gf[0:WbRobNum-1], input logic [7:0] gv[0:WbRobNum-1],
      input logic gV[0:WbRobNum-1], input logic gK[0:WbRobNum-1]);
    case (self)
      5'd0,5'd2,5'd4,5'd6,5'd7,5'd9,5'd10,5'd11,5'd12: wb_compress_count = count_group_A(self, gf, gv, gV, gK);
      5'd5,5'd8:                                        wb_compress_count = count_group_B(self, gf, gv, gV, gK);
      5'd13,5'd14,5'd15,5'd16,5'd17:                    wb_compress_count = count_group_C(self, gf, gv, gV, gK);
      5'd23,5'd24:                                      wb_compress_count = count_group_E(self, gf, gv, gV, gK);
      default:                                          wb_compress_count = count_group_D(self, gV, gK);
    endcase
  endfunction

  // 计数寄存器:RegEnable(PopCount, wbData[self].valid);valid 同样打一拍(杀三级)。
  logic [4:0]  wbNumsBits  [0:WbRobNum-1];
  logic        wbNumsValid [0:WbRobNum-1];
  generate
    for (gj = 0; gj < WbRobNum; gj++) begin : g_wbnums
      always_ff @(posedge clock) begin
        if (reset) wbNumsValid[gj] <= 1'b0;
        else       wbNumsValid[gj] <= wbInValid[gj] & ~wbKilledByOlder3[gj];
        if (wbInValid[gj]) wbNumsBits[gj] <= wb_compress_count(gj[4:0], wbRobFlag, wbRobValue, wbV, wbK3);
      end
    end
  endgenerate

  // ==========================================================================
  // 块 3-C:exuWriteback 路的 writebackTime 自由计数器(debug 用)
  // --------------------------------------------------------------------------
  // golden 对每条 exuWriteback(0..24)用一个 64 位「自由奔跑」计数器作 writebackTime,
  // 每拍 +1(与具体写回无关,纯做时间戳基准)。送 rob.io.exuWriteback[i].debugInfo.writebackTime。
  // (注意:这与 wbDelayedBits[i].debugInfo.writebackTime 不同 —— 后者是从输入锁存的值,
  //  用于 enqRob 侧;这里是 exuWriteback 侧专用的自由计数。)
  // ==========================================================================
  logic [63:0] wbWritebackTimeCnt [0:WbRobNum-1];
  generate
    for (gj = 0; gj < WbRobNum; gj++) begin : g_wbtime
      always_ff @(posedge clock) begin
        if (reset) wbWritebackTimeCnt[gj] <= 64'h0;
        else       wbWritebackTimeCnt[gj] <= wbWritebackTimeCnt[gj] + 64'h1;
      end
    end
  endgenerate

  // ==========================================================================
  // 块 6:派遣 -> Rob 入队打拍(enqRob)
  // --------------------------------------------------------------------------
  // 源:dispatch.io.enqRob.req[i](NewDispatch 黑盒输出)。
  //   valid    = RegNext(dispatch.req[i].valid && !io_redirect_valid)
  //   bits     = RegEnable(dispatch.req[i].bits, dispatch.req[i].valid)
  //   needAlloc= RegNext(dispatch.io.enqRob.needAlloc)   (在 inst.svh 直接打拍)
  // 装包(dispatch 黑盒输出 -> struct)由 ctrlblock_enqpack.svh 完成。
  // io_redirect_valid 即本核重定向输出(= s1_s3_redirect_valid,见块5 末尾驱动)。
  // ==========================================================================
  logic            enqInValid [0:ctrlblock_pkg::RenameWidth-1];
  rob_enq_uop_t    enqInBits  [0:ctrlblock_pkg::RenameWidth-1];
  `include "ctrlblock_enqpack.svh"  // enqInValid/enqInBits <- _dispatch_io_enqRob_req_*

  logic            enqRobValid [0:ctrlblock_pkg::RenameWidth-1];  // -> rob.io.enq.req[i].valid
  rob_enq_uop_t    enqRobBits  [0:ctrlblock_pkg::RenameWidth-1];  // -> rob.io.enq.req[i].bits
  generate
    for (gj = 0; gj < ctrlblock_pkg::RenameWidth; gj++) begin : g_enqpipe
      // golden enqRob_req_<i>_valid_REG 无复位(在 always @(posedge clock) 普通块,
      // 每拍无条件写 dispatch.req.valid & ~redirect)。impl 若加同步复位则 DFF 不等价,
      // 故这里去掉 reset,保持无复位以对齐 golden(初值由 +vcs+initreg+0 提供)。
      always_ff @(posedge clock) begin
        enqRobValid[gj] <= enqInValid[gj] & ~s1_s3_redirect_valid;
        if (enqInValid[gj]) enqRobBits[gj] <= enqInBits[gj];
      end
    end
  endgenerate

  // ==========================================================================
  // 块 5 补:重定向广播输出端口(io.redirect = s1_s3_redirect)
  // --------------------------------------------------------------------------
  // CtrlBlock 把 s1_s3_redirect 作为后端统一 redirect 广播给 IssueQueue/ExuBlock
  // (它们各自再 RegNext)。enqRob.valid 也用它清掉被 flush 的入队。
  // ==========================================================================
  assign io_redirect_valid          = s1_s3_redirect_valid;
  assign io_redirect_bits_robIdx_flag  = s1_s3_redirect_robFlag;
  assign io_redirect_bits_robIdx_value = s1_s3_redirect_robValue;
  assign io_redirect_bits_level     = s1_s3_redirect_level;

  // ==========================================================================
  // pcMem 写口打拍(frontend.fromFtq -> pcMem 单写口,head)
  // --------------------------------------------------------------------------
  // Scala:pcMem.io.wen.head   = GatedValidRegNext(io.frontend.fromFtq.pc_mem_wen)
  //       pcMem.io.waddr.head = RegEnable(pc_mem_waddr, pc_mem_wen)
  //       pcMem.io.wdata.head = RegEnable(pc_mem_wdata, pc_mem_wen)
  // 输入全是顶层 io 端口;输出具名信号 pcMemWen/pcMemWaddr/pcMemWdataStartAddr 由
  // ctrlblock_inst.svh 连到 pcMem 黑盒写口。FTQ 在写 PC 表前一拍给出地址/数据,本核打拍对齐。
  // ==========================================================================
  logic        pcMemWen;                 // -> pcMem.io.wen_0
  logic [5:0]  pcMemWaddr;               // -> pcMem.io.waddr_0
  logic [49:0] pcMemWdataStartAddr;      // -> pcMem.io.wdata_0_startAddr
  // golden pcMem_io_wen_0_last_REG 在异步复位块;waddr/wdata 是无复位 RegEnable。
  // 拆两块以对齐 golden 复位域(wen 异步复位,waddr/wdata 无复位)。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) pcMemWen <= 1'b0;
    else       pcMemWen <= io_frontend_fromFtq_pc_mem_wen;
  end
  always_ff @(posedge clock) begin
    if (io_frontend_fromFtq_pc_mem_wen) begin
      pcMemWaddr          <= io_frontend_fromFtq_pc_mem_waddr;
      pcMemWdataStartAddr <= io_frontend_fromFtq_pc_mem_wdata_startAddr;
    end
  end
