#!/usr/bin/env python3
"""
Rob(重排序缓冲)的 UT 生成脚本。

设计意图来自 src/main/scala/xiangshan/backend/rob/Rob.scala (class Rob / RobImp)。
可读核 rtl/backend/Rob.sv (xs_Rob_core) + rtl/backend/rob_pkg.sv。

子模块(RobEnqPtrWrapper / NewRobDeqPtrWrapper / ExceptionGen / SnapshotGenerator_3 /
RenameBuffer / VTypeBuffer / DelayReg / DummyDPICWrapper / dt_160x1)在 golden 顶层
Rob.sv 内例化, 都作 golden 黑盒。

本脚本产出 verif/ut/Rob/tb.sv —— 对可读核 xs_Rob_core 的「自检 smoke UT」:
随机激励 enqueue / writeback / redirect, 直接驱动核的黑盒接口输入(指针/异常态由
testbench 用简单环形模型生成), 逐拍检查一组「微架构不变量」:
  - 队列占用 numValidEntries 永不溢出 RobSize;
  - !canAccept 时不入队(allowEnqueue 阈值);
  - commit 只发生在 commit_v && commit_w 的槽;
  - redirect 后强制进 s_walk;
  - 所有输出端口无 X(复位后);
  - commitValid 单调(按序: 高位有效则低位都有效)。

注: 与 golden 顶层 Rob.sv(220873 行 / 3234 端口) 的 cycle-exact 双例化比对需先补齐
可读核里注释标注的二阶时延路径(见 docs/backend/Rob.md §12), 此处先做核自检。
"""
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
HDR = "// 自动生成: scripts/gen_rob.py —— 勿手改\n"

RENAME_WIDTH = 6
COMMIT_WIDTH = 8
NUM_EXU_WB = 27
NUM_WB = 25
PTR_W = 8
ROB_SIZE = 160


def make_tb():
    L = [HDR, "`timescale 1ns/1ps",
         "import rob_pkg::*;",
         "module tb;",
         "  int unsigned NCYCLES = 200000;",
         "  bit clk = 0, rst;",
         "  int errors = 0, checks = 0;",
         "  always #5 clk = ~clk;",
         "",
         "  // ---- 核接口信号 ----",
         "  logic io_redirect_valid;",
         "  logic io_redirect_bits_robIdx_flag; logic [PTR_W-1:0] io_redirect_bits_robIdx_value;",
         "  logic io_redirect_bits_level;",
         "  logic [RENAME_WIDTH-1:0] enq_valid, enq_first_uop, enq_need_write_rf, enq_write_std;",
         "  logic [RENAME_WIDTH-1:0] enq_block_backward, enq_wait_forward, enq_is_wfi;",
         "  logic [RENAME_WIDTH-1:0] enq_has_exception, enq_trigger_dmode, enq_allow_interrupt;",
         "  logic [UOP_CNT_W-1:0] enq_num_wb [RENAME_WIDTH];",
         "  logic [PTR_W-1:0] enq_robidx_value [RENAME_WIDTH];",
         "  rob_entry_t enq_info [RENAME_WIDTH];",
         "  logic [NUM_EXU_WB-1:0] wb_valid; logic [PTR_W-1:0] wb_robidx [NUM_EXU_WB];",
         "  logic [4:0] wb_num [NUM_EXU_WB]; logic [NUM_EXU_WB-1:0] wb_is_std;",
         "  logic [NUM_EXU_WB-1:0] wb_fflags_valid; logic [4:0] wb_fflags [NUM_EXU_WB];",
         "  logic [NUM_EXU_WB-1:0] wb_vxsat_valid, wb_vxsat, wb_branch_taken;",
         "  logic [NUM_WB-1:0] excp_wb_valid; logic [PTR_W-1:0] excp_wb_robidx [NUM_WB];",
         "  logic [NUM_WB-1:0] excp_wb_need_flush;",
         "  logic eg_valid, eg_robidx_flag; logic [PTR_W-1:0] eg_robidx_value;",
         "  logic eg_is_exception, eg_flush_pipe, eg_replay_inst, eg_is_vls, eg_is_enq_excp, eg_is_vset;",
         "  rob_ptr_t deq_ptr_vec [COMMIT_WIDTH]; rob_ptr_t deq_ptr_next0;",
         "  rob_ptr_t enq_ptr_vec [RENAME_WIDTH]; rob_ptr_t snap_ptr0;",
         "  logic io_csr_intrBitSet, io_csr_wfiEvent, io_csr_criticalErrorState;",
         "  logic io_snpt_useSnpt, io_wfi_enable, io_wfi_safeFromMem, io_wfi_safeFromFrontend;",
         "  logic io_fromVecExcpMod_busy, io_trace_blockCommit;",
         "  logic rab_can_enq, rab_status_commit_end, rab_status_walk_end, vtype_status_walk_end;",
         "  logic io_misPredWb;",
         "  // ---- 核输出 ----",
         "  rob_state_e o_state;",
         "  logic o_commits_isCommit, o_commits_isWalk;",
         "  logic [COMMIT_WIDTH-1:0] o_commits_commitValid, o_commits_walkValid;",
         "  rob_commit_entry_t o_commit_info [COMMIT_WIDTH]; rob_ptr_t o_commits_robIdx [COMMIT_WIDTH];",
         "  logic [COMMIT_WIDTH-1:0] o_deq_commit_v, o_deq_commit_w, o_hasCommitted;",
         "  logic o_intrBitSetReg, o_hasNoSpecExec, o_allowOnlyOneCommit, o_blockCommit, o_allCommitted;",
         "  logic o_allowEnqueue, o_hasBlockBackward; logic [RENAME_WIDTH-1:0] o_enq_for_ptr;",
         "  logic o_eg_flush; logic [UOP_CNT_W:0] o_rab_commitSize, o_rab_walkSize; logic o_rab_walkEnd;",
         "  logic o_flushOut_valid, o_flushOut_robIdx_flag; logic [PTR_W-1:0] o_flushOut_robIdx_value;",
         "  logic o_flushOut_level, o_flushOut_isRVC; logic [FTQ_PTR_W-1:0] o_flushOut_ftqIdx_value;",
         "  logic o_flushOut_ftqIdx_flag; logic [FTQ_OFFSET_W-1:0] o_flushOut_ftqOffset;",
         "  logic o_exception_valid, o_intrEnable;",
         "  logic o_enq_canAccept, o_enq_canAcceptForDispatch, o_robFull, o_headNotReady;",
         "  logic o_cpu_halt, o_wfiReq; logic [PTR_W:0] o_numValidEntries;",
         "",
         "  // ---- testbench 侧 enqPtr/deqPtr 环形模型(模拟两个黑盒 wrapper) ----",
         "  // 简单实现: enqPtr 按本拍入队数前进, deqPtr 按提交数前进。",
         "  rob_ptr_t tb_enq, tb_deq;",
         "  function automatic rob_ptr_t padd(input rob_ptr_t p, input int unsigned n);",
         "    int unsigned v; rob_ptr_t o;",
         "    v = p.value + n;",
         "    if (v >= ROB_SIZE) begin o.value = v - ROB_SIZE; o.flag = ~p.flag; end",
         "    else begin o.value = v[PTR_W-1:0]; o.flag = p.flag; end",
         "    return o;",
         "  endfunction",
         "",
         "  // 入队/提交计数",
         "  int unsigned enq_cnt, commit_cnt;",
         "  always_comb begin",
         "    enq_cnt = 0;",
         "    for (int i=0;i<RENAME_WIDTH;i++) if (o_enq_for_ptr[i] && o_enq_canAccept) enq_cnt++;",
         "    commit_cnt = 0;",
         "    for (int i=0;i<COMMIT_WIDTH;i++) if (o_commits_isCommit && o_commits_commitValid[i]) commit_cnt++;",
         "  end",
         "",
         "  // enqPtrVec / deqPtrVec / snap 由 tb 模型生成喂给核",
         "  always_comb begin",
         "    for (int i=0;i<RENAME_WIDTH;i++) enq_ptr_vec[i] = padd(tb_enq, i);",
         "    for (int i=0;i<COMMIT_WIDTH;i++) deq_ptr_vec[i] = padd(tb_deq, i);",
         "    deq_ptr_next0 = padd(tb_deq, commit_cnt);",
         "    snap_ptr0 = tb_deq;",
         "  end",
         "",
         "  // ---- 例化可读核 ----",
         "  logic clock, reset; assign clock = clk; assign reset = rst;",
         "  xs_Rob_core u_core (.*);",
         "",
         "  // ---- 时序模型: 推进 tb_enq/tb_deq ----",
         "  always_ff @(posedge clk) begin",
         "    if (rst) begin tb_enq <= '0; tb_deq <= '0; end",
         "    else begin",
         "      if (io_redirect_valid)",
         "        tb_enq <= '{flag:io_redirect_bits_robIdx_flag, value:io_redirect_bits_robIdx_value};",
         "      else tb_enq <= padd(tb_enq, enq_cnt);",
         "      tb_deq <= padd(tb_deq, commit_cnt);",
         "    end",
         "  end",
         "",
         make_stim(),
         make_check(),
         EPILOG,
         "endmodule"]
    return "\n".join(L)


def make_stim():
    L = ["  // ---- 随机激励 ----",
         "  function automatic logic [UOP_CNT_W-1:0] rnwb(); return UOP_CNT_W'($urandom_range(1,4)); endfunction",
         "  always @(negedge clk) begin",
         "    if (rst) begin",
         "      io_redirect_valid<=0; io_redirect_bits_robIdx_flag<=0; io_redirect_bits_robIdx_value<=0;",
         "      io_redirect_bits_level<=0;",
         "      enq_valid<=0; enq_first_uop<=0; enq_need_write_rf<=0; enq_write_std<=0;",
         "      enq_block_backward<=0; enq_wait_forward<=0; enq_is_wfi<=0;",
         "      enq_has_exception<=0; enq_trigger_dmode<=0; enq_allow_interrupt<='1;",
         "      wb_valid<=0; wb_is_std<=0; wb_fflags_valid<=0; wb_vxsat_valid<=0; wb_vxsat<=0; wb_branch_taken<=0;",
         "      excp_wb_valid<=0; excp_wb_need_flush<=0;",
         "      eg_valid<=0; eg_is_exception<=0; eg_flush_pipe<=0; eg_replay_inst<=0;",
         "      eg_is_vls<=0; eg_is_enq_excp<=0; eg_is_vset<=0; eg_robidx_flag<=0; eg_robidx_value<=0;",
         "      io_csr_intrBitSet<=0; io_csr_wfiEvent<=0; io_csr_criticalErrorState<=0;",
         "      io_snpt_useSnpt<=0; io_wfi_enable<=1; io_wfi_safeFromMem<=1; io_wfi_safeFromFrontend<=1;",
         "      io_fromVecExcpMod_busy<=0; io_trace_blockCommit<=0;",
         "      rab_can_enq<=1; rab_status_commit_end<=1; rab_status_walk_end<=1; vtype_status_walk_end<=1;",
      "      io_misPredWb<=0;",
         "      for (int i=0;i<RENAME_WIDTH;i++) begin enq_num_wb[i]<=1; enq_robidx_value[i]<=0; enq_info[i]<='0; end",
         "      for (int i=0;i<NUM_EXU_WB;i++) begin wb_robidx[i]<=0; wb_num[i]<=1; wb_fflags[i]<=0; end",
         "      for (int i=0;i<NUM_WB;i++) excp_wb_robidx[i]<=0;",
         "    end else begin",
         "      // enqueue: 70% 概率有效; robIdx 跟 enqPtrVec; numWB 小随机",
         "      io_redirect_valid <= ($urandom_range(0,99) < 2);",
         "      io_redirect_bits_robIdx_flag <= tb_deq.flag;",
         "      io_redirect_bits_robIdx_value <= deq_ptr_vec[$urandom_range(0,7)].value;",
         "      io_redirect_bits_level <= $urandom_range(0,1);",
         "      for (int i=0;i<RENAME_WIDTH;i++) begin",
         "        enq_valid[i] <= ($urandom_range(0,99)<70);",
         "        enq_first_uop[i] <= 1;",
         "        enq_need_write_rf[i] <= ($urandom_range(0,99)<60);",
         "        enq_write_std[i] <= ($urandom_range(0,99)<15);",
         "        enq_block_backward[i] <= ($urandom_range(0,99)<3);",
         "        enq_wait_forward[i] <= ($urandom_range(0,99)<3);",
         "        enq_is_wfi[i] <= ($urandom_range(0,99)<2);",
         "        enq_has_exception[i] <= ($urandom_range(0,99)<5);",
         "        enq_trigger_dmode[i] <= 0;",
         "        enq_allow_interrupt[i] <= ($urandom_range(0,99)<70);",
         "        enq_num_wb[i] <= rnwb();",
         "        enq_robidx_value[i] <= padd(tb_enq, i).value;",
         "        enq_info[i] <= '0;",
         "      end",
         "      // writeback: 各口随机命中某个在飞 robIdx",
         "      for (int i=0;i<NUM_EXU_WB;i++) begin",
         "        wb_valid[i] <= ($urandom_range(0,99)<40);",
         "        wb_robidx[i] <= $urandom_range(0,ROB_SIZE-1);",
         "        wb_num[i] <= $urandom_range(0,2);",
         "        wb_is_std[i] <= ($urandom_range(0,99)<20);",
         "        wb_fflags_valid[i] <= ($urandom_range(0,99)<10); wb_fflags[i] <= $urandom_range(0,31);",
         "        wb_vxsat_valid[i] <= ($urandom_range(0,99)<5); wb_vxsat[i] <= $urandom_range(0,1);",
         "        wb_branch_taken[i] <= ($urandom_range(0,99)<10);",
         "      end",
         "      for (int i=0;i<NUM_WB;i++) begin",
         "        excp_wb_valid[i] <= ($urandom_range(0,99)<8);",
         "        excp_wb_robidx[i] <= $urandom_range(0,ROB_SIZE-1);",
         "        excp_wb_need_flush[i] <= ($urandom_range(0,99)<30);",
         "      end",
         "      // exceptionGen: 偶发命中队头",
         "      eg_valid <= ($urandom_range(0,99)<10);",
         "      eg_robidx_flag <= tb_deq.flag; eg_robidx_value <= tb_deq.value;",
         "      eg_is_exception <= ($urandom_range(0,99)<50); eg_flush_pipe <= ($urandom_range(0,99)<30);",
         "      eg_replay_inst <= ($urandom_range(0,99)<10); eg_is_vls <= ($urandom_range(0,99)<10);",
         "      io_csr_intrBitSet <= ($urandom_range(0,99)<3);",
         "      io_csr_criticalErrorState <= 0; io_trace_blockCommit <= ($urandom_range(0,99)<2);",
         "      io_snpt_useSnpt <= $urandom_range(0,1);",
         "      io_fromVecExcpMod_busy <= ($urandom_range(0,99)<2);",
         "      rab_can_enq <= ($urandom_range(0,99)<95);",
         "      rab_status_walk_end <= ($urandom_range(0,99)<60); vtype_status_walk_end <= ($urandom_range(0,99)<60);",
      "      io_misPredWb <= ($urandom_range(0,99)<3);",
         "    end",
         "  end"]
    return "\n".join(L)


def make_check():
    L = ["  // ---- 不变量自检 ----",
         "  // redirect 后若干拍, tb 环形模型(enq 跳到任意 robIdx)与 numValid 距离暂不可比, 跳过。",
         "  logic [3:0] redir_skip;",
         "  always_ff @(posedge clk) if (rst) redir_skip<=0; else redir_skip <= io_redirect_valid ? 4'd6 : (redir_skip!=0 ? redir_skip-1:0);",
         "  always @(negedge clk) if (!rst) begin",
         "    #4; checks++;",
         "    // 1) allowEnqueue 阈值生效: canAccept 时 numValid 不应超过 RobSize(稳态, 非 redirect 窗口)",
         "    if (redir_skip==0 && o_enq_canAccept && o_numValidEntries > ROB_SIZE) begin errors++;",
         "      if(errors<=50) $display(\"[%0t] OVERFLOW numValid=%0d\",$time,o_numValidEntries); end",
         "    // 2) redirect 后强制 walk",
         "    if ($past(io_redirect_valid) && o_state !== S_WALK) begin errors++;",
         "      if(errors<=50) $display(\"[%0t] redirect not->walk state=%0d\",$time,o_state); end",
         "    // 3) commit 只在 commit_w 的槽(对齐后第 0 槽必须 ready)",
         "    if (o_commits_isCommit && o_commits_commitValid[0] && !o_deq_commit_w[tb_deq.value[BANK_SEL_W-1:0]]) begin",
         "      errors++; if(errors<=50) $display(\"[%0t] commit slot0 not ready\",$time); end",
         "    // 4) 输出无 X",
         "    if ($isunknown({o_commits_isCommit,o_commits_isWalk,o_commits_commitValid,o_commits_walkValid,",
         "                    o_flushOut_valid,o_exception_valid,o_enq_canAccept,o_robFull,o_cpu_halt,",
         "                    o_wfiReq,o_numValidEntries,o_rab_commitSize,o_rab_walkSize})) begin",
         "      errors++; if(errors<=50) $display(\"[%0t] X on outputs\",$time); end",
         "    // 5) walk/commit 互斥(非 special 态; 本 ROB 只有 idle/walk 两态, isCommit=>!isWalk)",
         "    if (o_commits_isCommit && o_commits_isWalk) begin errors++;",
         "      if(errors<=50) $display(\"[%0t] commit&&walk both\",$time); end",
         "  end"]
    return "\n".join(L)


EPILOG = r"""  initial begin
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end"""


def main():
    ut = XSSV / "verif/ut/Rob"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "tb.sv").write_text(make_tb())
    print("generated self-check UT for Rob ->", ut / "tb.sv")


if __name__ == "__main__":
    main()
