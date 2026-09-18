#!/usr/bin/env python3
"""gen_lqreplay_ut.py —— 生成 LoadQueueReplay 的 UT testbench。

golden 有 1391 个端口（802 输入 / 589 输出），其中 786 个是纯 payload。逐个手写
端口表既没意义也留不住——所以 tb 的**接线**（信号声明、两侧例化、输出逐位比对、
payload 随机驱动）由本脚本从 golden 端口表生成，而**激励模型**（相位轮转、
各 cause 的构造、暖机窗口、覆盖分桶）是手写的常量块，就在下面 STIMULUS 里。

输出: verif/ut/LoadQueueReplay/tb.sv

★暖机窗口★ 是本 tb 最要紧的一处设计，理由见 STIMULUS 里的注释。
"""
import argparse
import os
import re
import sys

GOLDEN = "/home/eda/xs-env/G1-canonical/golden-rtl/LoadQueueReplay.sv"
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "verif", "ut", "LoadQueueReplay", "tb.sv"))

# 参与控制通路、由激励模型显式驱动的输入（其余输入一律每拍随机）。
CTRL_INPUTS = set("""
io_redirect_valid io_redirect_bits_robIdx_flag io_redirect_bits_robIdx_value
io_redirect_bits_level
io_tl_d_channel_valid io_tl_d_channel_mshrid
io_stAddrReadySqPtr_flag io_stAddrReadySqPtr_value
io_stDataReadySqPtr_flag io_stDataReadySqPtr_value
io_sqEmpty io_ldWbPtr_flag io_ldWbPtr_value
io_robDeqPtr_flag io_robDeqPtr_value io_rarFull io_rawFull
io_l2_hint_valid io_l2_hint_bits_sourceId io_l2_hint_bits_isKeyword
io_tlb_hint_resp_valid io_tlb_hint_resp_bits_id io_tlb_hint_resp_bits_replay_all
io_debugTopDown_robHeadVaddr_valid io_debugTopDown_robHeadVaddr_bits
io_debugTopDown_robHeadMissInDTlb
""".split())

# 逐口（w=0..2）显式驱动的输入模式
CTRL_PER_PORT = [
    "io_enq_%d_valid", "io_enq_%d_bits_isLoadReplay", "io_enq_%d_bits_handledByMSHR",
    "io_enq_%d_bits_schedIndex", "io_enq_%d_bits_vaddr",
    "io_enq_%d_bits_rep_info_mshr_id", "io_enq_%d_bits_rep_info_full_fwd",
    "io_enq_%d_bits_rep_info_data_inv_sq_idx_flag",
    "io_enq_%d_bits_rep_info_data_inv_sq_idx_value",
    "io_enq_%d_bits_rep_info_addr_inv_sq_idx_flag",
    "io_enq_%d_bits_rep_info_addr_inv_sq_idx_value",
    "io_enq_%d_bits_rep_info_last_beat", "io_enq_%d_bits_rep_info_tlb_id",
    "io_enq_%d_bits_rep_info_tlb_full",
    "io_enq_%d_bits_uop_robIdx_flag", "io_enq_%d_bits_uop_robIdx_value",
    "io_enq_%d_bits_uop_lqIdx_flag", "io_enq_%d_bits_uop_lqIdx_value",
    "io_enq_%d_bits_uop_sqIdx_flag", "io_enq_%d_bits_uop_sqIdx_value",
    "io_enq_%d_bits_uop_uopIdx", "io_enq_%d_bits_uop_loadWaitStrict",
    "io_replay_%d_ready",
] + ["io_enq_%%d_bits_rep_info_cause_%d" % c for c in range(11)] \
  + ["io_vecFeedback_%d_valid", "io_vecFeedback_%d_bits_robidx_flag",
     "io_vecFeedback_%d_bits_robidx_value", "io_vecFeedback_%d_bits_uopidx",
     "io_vecFeedback_%d_bits_feedback_0", "io_vecFeedback_%d_bits_feedback_1",
     "io_storeAddrIn_%d_valid", "io_storeAddrIn_%d_bits_uop_sqIdx_flag",
     "io_storeAddrIn_%d_bits_uop_sqIdx_value", "io_storeAddrIn_%d_bits_miss",
     "io_storeDataIn_%d_valid", "io_storeDataIn_%d_bits_uop_sqIdx_flag",
     "io_storeDataIn_%d_bits_uop_sqIdx_value"]


def ports():
    lines = open(GOLDEN).read().split("\n")
    s = next(i for i, l in enumerate(lines) if l.startswith("module LoadQueueReplay("))
    e = s
    while not lines[e].startswith(");"):
        e += 1
    out = []
    pat = re.compile(r"\s*(input|output)\s+(?:\[(\d+):(\d+)\]\s*)?([A-Za-z_]\w*)\s*,?\s*$")
    for l in lines[s + 1:e]:
        m = pat.match(l)
        if m:
            w = (int(m.group(2)) - int(m.group(3)) + 1) if m.group(2) else 1
            out.append((m.group(1), w, m.group(4)))
    return out


def is_ctrl(name):
    if name in CTRL_INPUTS:
        return True
    for p in CTRL_PER_PORT:
        for w in range(3):
            if name == (p % w):
                return True
    if re.match(r"^io_(stAddrReadyVec|stDataReadyVec)_\d+$", name):
        return True
    return False


STIMULUS = r'''
  // ===========================================================================
  //  激励模型
  // ===========================================================================
  //  ★暖机窗口（本 tb 最要紧的一处）★
  //  72 条 entry 的 uop / vecReplay / blockSqIdx 在 golden 里是**不复位**寄存器
  //  （契约靠 allocated 有效位保证：没写过就不会被选中）。两侧各自例化、各抽各的
  //  上电值，所以只要比较窗口在它们被写之前就打开，某些输出（尤其 s2 无条件按
  //  s1 下标读出来的 replay payload，valid=0 时照样往外送）必然不等 ——
  //  ★这时红的是 tb 不是 RTL★。
  //  做法：开头 WARM 拍只灌入队、不发 redirect、不回流（于是没有任何槽被释放），
  //  freelist 3 拍分 3 个槽，24 拍就把 72 个槽全部写满；比较从第 WARM 拍才开始。
  //  入队 cause 里固定带上 C_MA|C_FF，好让 blockSqIdx 这个不复位寄存器也被写到。
  //  同理 s1/s2 的下标与 payload 寄存器在暖机期内也都被写过至少一次。
  localparam int WARM = 400;

  // ★topdown 的地址池★：topdown 要求「某条 allocated entry 的 debug_vaddr 恰好等于
  //  robHeadVaddr」才会点亮，如果两边都在 50 位空间里随机，命中概率是 72/2^50 ——
  //  实测把 vaddr 限到 18 位时 5000 拍只命中 1 次，那条 143 节点的归约树等于没测
  //  （变异体 M11 就是打这棵树的）。把入队 vaddr 与 robHeadVaddr 抽自同一个小池子，
  //  命中率提到每拍都可能，同时保留高位比特的多样性（池里的值是稀疏撒开的）。
  localparam int VA_POOL = 24;
  function automatic logic [49:0] vaddr_pool(input int k);
    // 稀疏撒开：低位取 k，高位按 k 摆到不同的位段，保证 50 位里各段都被比较到
    return {k[4:0], 15'h0, k[4:0], 10'h0, k[4:0], 5'h0, k[4:0]};
  endfunction

  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cyc = 0;

  // ---- 覆盖分桶（★errors=0 单独不算数：这些桶必须非零★）----
  int cov_cause [11];      // 各 cause 入队次数
  int cov_replay_fire;     // 重放发射
  int cov_replay_stall;    // valid & ~ready
  int cov_lqfull;          // freelist 空
  int cov_redirect;        // redirect 有效
  int cov_flush_hit;       // redirect 真的刷掉了队里的项（lqFull 从空->非空之外的证据）
  int cov_loadreplay;      // isLoadReplay 回流
  int cov_lr_free;         // 回流且不再需重放（释放路径）
  int cov_l2hint;          // l2 hint 唤醒
  int cov_tlbhint;         // tlb hint 回填
  int cov_tld;             // D-channel 响应
  int cov_tld_prev;        // ★G1 新增：入队时命中「上一拍」的 D-channel
  int cov_mf_block;        // C_MF 入队（robDeqPtr 解除路径）
  int cov_mf_release;      // C_MF 项的 robIdx 追上 robDeqPtr
  int cov_cold;            // 连续发射（冷却计数器爬升）
  int cov_vecfb;           // vecFeedback 有效
  int cov_topdown;         // topdown 命中
  int cov_allocate;        // replayAllocate=1

  int phase;
  // 回流用的 schedIndex 池：从重放输出里捞，保证回流的下标确实是分配过的槽
  int lr_pool [$];

  // 上一拍的 D-channel（用来构造「命中上一拍」的场景）
  bit       prev_tld_v;
  bit [3:0] prev_tld_id;

  function automatic bit [10:0] gen_cause(input int ph, input int w);
    bit [10:0] c;
    c = '0;
    case (ph)
      0: c = $urandom_range(1, 11'h7FF);            // 全随机（至少一个 cause）
      1: begin c[4] = 1'b1;                          // C_DM 为主
           if ($urandom_range(0,3) == 0) c[2] = 1'b1; end
      2: begin c[0] = 1'b1; c[2] = 1'b1; end         // C_MA + C_FF
      3: c = $urandom_range(1, 11'h7FF);
      4: begin c[1] = 1'b1; end                      // C_TM
      5: begin c[10] = 1'b1;                         // C_MF（G1 新解除条件）
           if ($urandom_range(0,2) == 0) c[8] = 1'b1; end
      6: begin c[3] = 1'b1; c[6] = 1'b1; end         // C_DR + C_BC（入队即不 block）
      7: begin c[7] = 1'b1; c[8] = 1'b1; end         // C_RAR + C_RAW
      default: c = $urandom_range(1, 11'h7FF);
    endcase
    return c;
  endfunction

  // 把一条入队请求的控制字段灌进第 w 口
  task automatic drive_enq(input int w, input bit warm);
    bit do_lr;
    bit [10:0] c;
    do_lr = 0;
    if (!warm && lr_pool.size() > 8 && $urandom_range(0, 3) == 0) do_lr = 1;
    c = warm ? 11'b000_0000_0101 : gen_cause(phase, w);   // 暖机固定 C_MA|C_FF
    case (w)
      0: begin
        io_enq_0_valid                = warm ? 1'b1 : ($urandom_range(0,3) != 0);
        io_enq_0_bits_isLoadReplay    = do_lr;
        // 回流且 cause 全 0 = 释放路径（不再需要重放）
        {io_enq_0_bits_rep_info_cause_10, io_enq_0_bits_rep_info_cause_9,
         io_enq_0_bits_rep_info_cause_8,  io_enq_0_bits_rep_info_cause_7,
         io_enq_0_bits_rep_info_cause_6,  io_enq_0_bits_rep_info_cause_5,
         io_enq_0_bits_rep_info_cause_4,  io_enq_0_bits_rep_info_cause_3,
         io_enq_0_bits_rep_info_cause_2,  io_enq_0_bits_rep_info_cause_1,
         io_enq_0_bits_rep_info_cause_0} = (do_lr && $urandom_range(0,2) == 0) ? 11'h0 : c;
        io_enq_0_bits_schedIndex      = do_lr ? lr_pool[$urandom_range(0, lr_pool.size()-1)]
                                              : $urandom_range(0, 71);
        io_enq_0_bits_handledByMSHR   = $urandom_range(0, 1);
        io_enq_0_bits_rep_info_mshr_id= $urandom_range(0, 15);
        io_enq_0_bits_rep_info_tlb_id = $urandom_range(0, 15);
        io_enq_0_bits_rep_info_tlb_full    = $urandom_range(0, 1);
        io_enq_0_bits_rep_info_full_fwd    = $urandom_range(0, 1);
        io_enq_0_bits_rep_info_last_beat   = $urandom_range(0, 1);
        io_enq_0_bits_rep_info_data_inv_sq_idx_flag  = $urandom_range(0, 1);
        io_enq_0_bits_rep_info_data_inv_sq_idx_value = $urandom_range(0, 63);
        io_enq_0_bits_rep_info_addr_inv_sq_idx_flag  = $urandom_range(0, 1);
        io_enq_0_bits_rep_info_addr_inv_sq_idx_value = $urandom_range(0, 63);
        io_enq_0_bits_vaddr           = vaddr_pool($urandom_range(0, VA_POOL-1));  // 窄地址空间→topdown 易命中
        io_enq_0_bits_uop_robIdx_flag = $urandom_range(0, 1);
        io_enq_0_bits_uop_robIdx_value= $urandom_range(0, 255);
        io_enq_0_bits_uop_lqIdx_flag  = $urandom_range(0, 1);
        io_enq_0_bits_uop_lqIdx_value = $urandom_range(0, 71);
        io_enq_0_bits_uop_sqIdx_flag  = $urandom_range(0, 1);
        io_enq_0_bits_uop_sqIdx_value = $urandom_range(0, 63);
        io_enq_0_bits_uop_uopIdx      = $urandom_range(0, 127);
        io_enq_0_bits_uop_loadWaitStrict = $urandom_range(0, 1);
      end
      1: begin
        io_enq_1_valid                = warm ? 1'b1 : ($urandom_range(0,3) != 0);
        io_enq_1_bits_isLoadReplay    = do_lr;
        {io_enq_1_bits_rep_info_cause_10, io_enq_1_bits_rep_info_cause_9,
         io_enq_1_bits_rep_info_cause_8,  io_enq_1_bits_rep_info_cause_7,
         io_enq_1_bits_rep_info_cause_6,  io_enq_1_bits_rep_info_cause_5,
         io_enq_1_bits_rep_info_cause_4,  io_enq_1_bits_rep_info_cause_3,
         io_enq_1_bits_rep_info_cause_2,  io_enq_1_bits_rep_info_cause_1,
         io_enq_1_bits_rep_info_cause_0} = (do_lr && $urandom_range(0,2) == 0) ? 11'h0 : c;
        io_enq_1_bits_schedIndex      = do_lr ? lr_pool[$urandom_range(0, lr_pool.size()-1)]
                                              : $urandom_range(0, 71);
        io_enq_1_bits_handledByMSHR   = $urandom_range(0, 1);
        io_enq_1_bits_rep_info_mshr_id= $urandom_range(0, 15);
        io_enq_1_bits_rep_info_tlb_id = $urandom_range(0, 15);
        io_enq_1_bits_rep_info_tlb_full    = $urandom_range(0, 1);
        io_enq_1_bits_rep_info_full_fwd    = $urandom_range(0, 1);
        io_enq_1_bits_rep_info_last_beat   = $urandom_range(0, 1);
        io_enq_1_bits_rep_info_data_inv_sq_idx_flag  = $urandom_range(0, 1);
        io_enq_1_bits_rep_info_data_inv_sq_idx_value = $urandom_range(0, 63);
        io_enq_1_bits_rep_info_addr_inv_sq_idx_flag  = $urandom_range(0, 1);
        io_enq_1_bits_rep_info_addr_inv_sq_idx_value = $urandom_range(0, 63);
        io_enq_1_bits_vaddr           = vaddr_pool($urandom_range(0, VA_POOL-1));
        io_enq_1_bits_uop_robIdx_flag = $urandom_range(0, 1);
        io_enq_1_bits_uop_robIdx_value= $urandom_range(0, 255);
        io_enq_1_bits_uop_lqIdx_flag  = $urandom_range(0, 1);
        io_enq_1_bits_uop_lqIdx_value = $urandom_range(0, 71);
        io_enq_1_bits_uop_sqIdx_flag  = $urandom_range(0, 1);
        io_enq_1_bits_uop_sqIdx_value = $urandom_range(0, 63);
        io_enq_1_bits_uop_uopIdx      = $urandom_range(0, 127);
        io_enq_1_bits_uop_loadWaitStrict = $urandom_range(0, 1);
      end
      default: begin
        io_enq_2_valid                = warm ? 1'b1 : ($urandom_range(0,3) != 0);
        io_enq_2_bits_isLoadReplay    = do_lr;
        {io_enq_2_bits_rep_info_cause_10, io_enq_2_bits_rep_info_cause_9,
         io_enq_2_bits_rep_info_cause_8,  io_enq_2_bits_rep_info_cause_7,
         io_enq_2_bits_rep_info_cause_6,  io_enq_2_bits_rep_info_cause_5,
         io_enq_2_bits_rep_info_cause_4,  io_enq_2_bits_rep_info_cause_3,
         io_enq_2_bits_rep_info_cause_2,  io_enq_2_bits_rep_info_cause_1,
         io_enq_2_bits_rep_info_cause_0} = (do_lr && $urandom_range(0,2) == 0) ? 11'h0 : c;
        io_enq_2_bits_schedIndex      = do_lr ? lr_pool[$urandom_range(0, lr_pool.size()-1)]
                                              : $urandom_range(0, 71);
        io_enq_2_bits_handledByMSHR   = $urandom_range(0, 1);
        io_enq_2_bits_rep_info_mshr_id= $urandom_range(0, 15);
        io_enq_2_bits_rep_info_tlb_id = $urandom_range(0, 15);
        io_enq_2_bits_rep_info_tlb_full    = $urandom_range(0, 1);
        io_enq_2_bits_rep_info_full_fwd    = $urandom_range(0, 1);
        io_enq_2_bits_rep_info_last_beat   = $urandom_range(0, 1);
        io_enq_2_bits_rep_info_data_inv_sq_idx_flag  = $urandom_range(0, 1);
        io_enq_2_bits_rep_info_data_inv_sq_idx_value = $urandom_range(0, 63);
        io_enq_2_bits_rep_info_addr_inv_sq_idx_flag  = $urandom_range(0, 1);
        io_enq_2_bits_rep_info_addr_inv_sq_idx_value = $urandom_range(0, 63);
        io_enq_2_bits_vaddr           = vaddr_pool($urandom_range(0, VA_POOL-1));
        io_enq_2_bits_uop_robIdx_flag = $urandom_range(0, 1);
        io_enq_2_bits_uop_robIdx_value= $urandom_range(0, 255);
        io_enq_2_bits_uop_lqIdx_flag  = $urandom_range(0, 1);
        io_enq_2_bits_uop_lqIdx_value = $urandom_range(0, 71);
        io_enq_2_bits_uop_sqIdx_flag  = $urandom_range(0, 1);
        io_enq_2_bits_uop_sqIdx_value = $urandom_range(0, 63);
        io_enq_2_bits_uop_uopIdx      = $urandom_range(0, 127);
        io_enq_2_bits_uop_loadWaitStrict = $urandom_range(0, 1);
      end
    endcase
  endtask

  task automatic drive_env(input bit warm);
    automatic int r;
    // ---- redirect：暖机期内一律关掉（否则会释放槽，暖机就填不满 72 条）----
    if (warm) begin
      io_redirect_valid = 1'b0;
    end else begin
      io_redirect_valid = (phase == 3) ? ($urandom_range(0, 3) == 0)
                                       : ($urandom_range(0, 63) == 0);
    end
    io_redirect_bits_robIdx_flag  = $urandom_range(0, 1);
    io_redirect_bits_robIdx_value = $urandom_range(0, 255);
    io_redirect_bits_level        = $urandom_range(0, 1);

    // ---- D-channel：phase 1 里高密度，并且**刻意重复上一拍的 id**，
    //      好把 G1 新增的「命中上一拍 D-channel」那一项打出来 ----
    prev_tld_v  = io_tl_d_channel_valid;
    prev_tld_id = io_tl_d_channel_mshrid;
    io_tl_d_channel_valid  = warm ? 1'b0 : ((phase == 1) ? ($urandom_range(0,1) == 0)
                                                         : ($urandom_range(0,7) == 0));
    io_tl_d_channel_mshrid = $urandom_range(0, 15);

    // ---- l2 hint ----
    io_l2_hint_valid           = warm ? 1'b0 : ((phase == 1) ? ($urandom_range(0,3) == 0)
                                                             : ($urandom_range(0,15) == 0));
    io_l2_hint_bits_sourceId   = $urandom_range(0, 15);
    io_l2_hint_bits_isKeyword  = $urandom_range(0, 1);

    // ---- tlb hint ----
    io_tlb_hint_resp_valid            = warm ? 1'b0 : ((phase == 4) ? ($urandom_range(0,3) == 0)
                                                                    : ($urandom_range(0,15) == 0));
    io_tlb_hint_resp_bits_id          = $urandom_range(0, 15);
    io_tlb_hint_resp_bits_replay_all  = ($urandom_range(0, 7) == 0);

    // ---- StoreQueue 就绪指针/向量 ----
    io_stAddrReadySqPtr_flag  = $urandom_range(0, 1);
    io_stAddrReadySqPtr_value = $urandom_range(0, 63);
    io_stDataReadySqPtr_flag  = $urandom_range(0, 1);
    io_stDataReadySqPtr_value = $urandom_range(0, 63);
    io_sqEmpty                = ($urandom_range(0, 15) == 0);
    for (int k = 0; k < 56; k++) begin
      st_addr_rdy[k] = (phase == 2) ? $urandom_range(0,1) : ($urandom_range(0,3) != 0);
      st_data_rdy[k] = (phase == 2) ? $urandom_range(0,1) : ($urandom_range(0,3) != 0);
    end

    // ---- STA / STD ----
    for (int w = 0; w < 2; w++) begin
      sta_v[w]  = (phase == 2) ? ($urandom_range(0,1) == 0) : ($urandom_range(0,3) == 0);
      sta_f[w]  = $urandom_range(0, 1);
      sta_i[w]  = $urandom_range(0, 63);
      sta_m[w]  = ($urandom_range(0, 3) == 0);
      std_v[w]  = (phase == 2) ? ($urandom_range(0,1) == 0) : ($urandom_range(0,3) == 0);
      std_f[w]  = $urandom_range(0, 1);
      std_i[w]  = $urandom_range(0, 63);
    end

    // ---- vecFeedback（本模块解码后不使用，仍然要打满以防真的接错）----
    for (int w = 0; w < 2; w++) begin
      vfb_v[w]  = ($urandom_range(0, 7) == 0);
      vfb_f[w]  = $urandom_range(0, 1);
      vfb_r[w]  = $urandom_range(0, 255);
      vfb_u[w]  = $urandom_range(0, 127);
      vfb_c[w]  = $urandom_range(0, 1);
      vfb_l[w]  = $urandom_range(0, 1);
    end

    // ---- 指针/满标志 ----
    io_ldWbPtr_flag   = $urandom_range(0, 1);
    io_ldWbPtr_value  = $urandom_range(0, 71);
    // ★phase 5 让 robDeqPtr 扫过整个 rob 空间，把 C_MF 的解除条件真正打出来★
    if (phase == 5) begin
      io_robDeqPtr_value = cyc[7:0];
      io_robDeqPtr_flag  = cyc[8];
    end else begin
      io_robDeqPtr_flag  = $urandom_range(0, 1);
      io_robDeqPtr_value = $urandom_range(0, 255);
    end
    io_rarFull = ($urandom_range(0, 3) == 0);
    io_rawFull = ($urandom_range(0, 3) == 0);

    // ---- 重放背压：phase 6 制造连发/卡死，驱动冷却计数器 ----
    for (int w = 0; w < 3; w++)
      rep_rdy[w] = warm ? 1'b1
                        : ((phase == 6) ? ($urandom_range(0, 7) != 0) : ($urandom_range(0, 3) != 0));

    // ---- topdown ----
    io_debugTopDown_robHeadVaddr_valid = ($urandom_range(0, 1) == 0);
    io_debugTopDown_robHeadVaddr_bits  = vaddr_pool($urandom_range(0, VA_POOL-1));
    io_debugTopDown_robHeadMissInDTlb  = $urandom_range(0, 1);
  endtask
'''


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="只比对不写；有差异 exit 1")
    args = ap.parse_args()
    ps = ports()
    ins = [p for p in ps if p[0] == "input" and p[2] not in ("clock", "reset")]
    outs = [p for p in ps if p[0] == "output"]
    rnd = [p for p in ins if not is_ctrl(p[2])]
    L = []
    L.append("// LoadQueueReplay UT —— golden 与重写件双例化，逐拍比对**全部 589 个输出端口**。")
    L.append("//")
    L.append("// 本文件由 scripts/gen_lqreplay_ut.py 生成（接线部分机械，激励模型是脚本里的手写常量块）。")
    L.append("// 手改这里会被下一次跑生成器覆盖 —— 要改激励请改生成器。")
    L.append("`timescale 1ns/1ps")
    L.append("module tb;")
    L.append("  bit clk = 0, rst;")
    L.append("  always #5 clk = ~clk;")
    L.append("")
    L.append("  // ---- 输入信号（两侧共用一套激励）----")
    for d, w, n in ins:
        L.append("  logic %-10s %s;" % ("" if w == 1 else "[%d:0]" % (w - 1), n))
    L.append("")
    L.append("  // ---- 便于按数组驱动的中间量（下面 assign 散到扁平端口）----")
    L.append("  logic [55:0] st_addr_rdy, st_data_rdy;")
    L.append("  logic [1:0]  sta_v, sta_f, sta_m, std_v, std_f;")
    L.append("  logic [1:0][5:0] sta_i, std_i;")
    L.append("  logic [1:0]  vfb_v, vfb_f, vfb_c, vfb_l;")
    L.append("  logic [1:0][7:0] vfb_r;")
    L.append("  logic [1:0][6:0] vfb_u;")
    L.append("  logic [2:0]  rep_rdy;")
    for k in range(56):
        L.append("  assign io_stAddrReadyVec_%d = st_addr_rdy[%d];" % (k, k))
        L.append("  assign io_stDataReadyVec_%d = st_data_rdy[%d];" % (k, k))
    for w in range(2):
        L.append("  assign io_storeAddrIn_%d_valid = sta_v[%d];" % (w, w))
        L.append("  assign io_storeAddrIn_%d_bits_uop_sqIdx_flag = sta_f[%d];" % (w, w))
        L.append("  assign io_storeAddrIn_%d_bits_uop_sqIdx_value = sta_i[%d];" % (w, w))
        L.append("  assign io_storeAddrIn_%d_bits_miss = sta_m[%d];" % (w, w))
        L.append("  assign io_storeDataIn_%d_valid = std_v[%d];" % (w, w))
        L.append("  assign io_storeDataIn_%d_bits_uop_sqIdx_flag = std_f[%d];" % (w, w))
        L.append("  assign io_storeDataIn_%d_bits_uop_sqIdx_value = std_i[%d];" % (w, w))
        L.append("  assign io_vecFeedback_%d_valid = vfb_v[%d];" % (w, w))
        L.append("  assign io_vecFeedback_%d_bits_robidx_flag = vfb_f[%d];" % (w, w))
        L.append("  assign io_vecFeedback_%d_bits_robidx_value = vfb_r[%d];" % (w, w))
        L.append("  assign io_vecFeedback_%d_bits_uopidx = vfb_u[%d];" % (w, w))
        L.append("  assign io_vecFeedback_%d_bits_feedback_0 = vfb_c[%d];" % (w, w))
        L.append("  assign io_vecFeedback_%d_bits_feedback_1 = vfb_l[%d];" % (w, w))
    for w in range(3):
        L.append("  assign io_replay_%d_ready = rep_rdy[%d];" % (w, w))
    L.append("")
    L.append("  // ---- 输出信号：g_=golden, i_=重写件 ----")
    for d, w, n in outs:
        L.append("  logic %-10s g_%s, i_%s;" % ("" if w == 1 else "[%d:0]" % (w - 1), n, n))
    L.append("")
    for tag, mod in (("g_", "LoadQueueReplay"), ("i_", "LoadQueueReplay_xs")):
        L.append("  %s %sdut (" % (mod, tag))
        conns = ["    .clock(clk), .reset(rst)"]
        for d, w, n in ins:
            conns.append("    .%s(%s)" % (n, n))
        for d, w, n in outs:
            conns.append("    .%s(%s%s)" % (n, tag, n))
        L.append(",\n".join(conns))
        L.append("  );")
        L.append("")
    L.append(STIMULUS)
    L.append("")
    L.append("  // ---- 每拍随机的 payload 输入（%d 个，纯存-转发，不进控制通路）----" % len(rnd))
    L.append("  task automatic drive_payload();")
    for d, w, n in rnd:
        if w <= 32:
            L.append("    %s = $urandom;" % n)
        else:
            chunks = (w + 31) // 32
            L.append("    %s = {%s};" % (n, ", ".join(["$urandom"] * chunks)))
    L.append("  endtask")
    L.append("")
    L.append("  // ---- 逐拍比对全部输出 ----")
    L.append("  task automatic check_outputs();")
    for d, w, n in outs:
        L.append("    if (g_%s !== i_%s) begin errors++;" % (n, n))
        L.append("      if (errors < 20) $display(\"[%%0d] MISMATCH %s: g=%%h i=%%h\", cyc, g_%s, i_%s); end"
                 % (n, n, n))
        L.append("    checks++;")
    L.append("  endtask")
    L.append("")
    L.append(r'''  // ---- 覆盖统计 ----
  task automatic sample_cov();
    for (int c = 0; c < 11; c++) begin
      if (io_enq_0_valid && cause_bit(0, c)) cov_cause[c]++;
      if (io_enq_1_valid && cause_bit(1, c)) cov_cause[c]++;
      if (io_enq_2_valid && cause_bit(2, c)) cov_cause[c]++;
    end
    if (g_io_replay_0_valid && rep_rdy[0]) cov_replay_fire++;
    if (g_io_replay_1_valid && rep_rdy[1]) cov_replay_fire++;
    if (g_io_replay_2_valid && rep_rdy[2]) cov_replay_fire++;
    if (g_io_replay_0_valid && !rep_rdy[0]) cov_replay_stall++;
    if (g_io_lqFull)          cov_lqfull++;
    if (g_io_replayAllocate)  cov_allocate++;
    if (io_redirect_valid)    cov_redirect++;
    if (io_enq_0_bits_isLoadReplay && io_enq_0_valid) cov_loadreplay++;
    if (io_enq_0_bits_isLoadReplay && io_enq_0_valid && !any_cause(0)) cov_lr_free++;
    if (io_l2_hint_valid)     cov_l2hint++;
    if (io_tlb_hint_resp_valid) cov_tlbhint++;
    if (io_tl_d_channel_valid)  cov_tld++;
    if (prev_tld_v && io_enq_0_valid && io_enq_0_bits_handledByMSHR
        && cause_bit(0, 4) && prev_tld_id == io_enq_0_bits_rep_info_mshr_id) cov_tld_prev++;
    if (io_enq_0_valid && cause_bit(0, 10)) cov_mf_block++;
    if (io_enq_0_valid && cause_bit(0, 10)
        && !((io_enq_0_bits_uop_robIdx_flag ^ io_robDeqPtr_flag)
             ^ (io_enq_0_bits_uop_robIdx_value > io_robDeqPtr_value))) cov_mf_release++;
    if (vfb_v[0] || vfb_v[1]) cov_vecfb++;
    if (g_io_debugTopDown_robHeadTlbReplay || g_io_debugTopDown_robHeadTlbMiss
        || g_io_debugTopDown_robHeadLoadVio || g_io_debugTopDown_robHeadLoadMSHR) cov_topdown++;
  endtask

  function automatic bit cause_bit(input int w, input int c);
    bit [10:0] v;
    case (w)
      0: v = {io_enq_0_bits_rep_info_cause_10, io_enq_0_bits_rep_info_cause_9,
              io_enq_0_bits_rep_info_cause_8,  io_enq_0_bits_rep_info_cause_7,
              io_enq_0_bits_rep_info_cause_6,  io_enq_0_bits_rep_info_cause_5,
              io_enq_0_bits_rep_info_cause_4,  io_enq_0_bits_rep_info_cause_3,
              io_enq_0_bits_rep_info_cause_2,  io_enq_0_bits_rep_info_cause_1,
              io_enq_0_bits_rep_info_cause_0};
      1: v = {io_enq_1_bits_rep_info_cause_10, io_enq_1_bits_rep_info_cause_9,
              io_enq_1_bits_rep_info_cause_8,  io_enq_1_bits_rep_info_cause_7,
              io_enq_1_bits_rep_info_cause_6,  io_enq_1_bits_rep_info_cause_5,
              io_enq_1_bits_rep_info_cause_4,  io_enq_1_bits_rep_info_cause_3,
              io_enq_1_bits_rep_info_cause_2,  io_enq_1_bits_rep_info_cause_1,
              io_enq_1_bits_rep_info_cause_0};
      default: v = {io_enq_2_bits_rep_info_cause_10, io_enq_2_bits_rep_info_cause_9,
              io_enq_2_bits_rep_info_cause_8,  io_enq_2_bits_rep_info_cause_7,
              io_enq_2_bits_rep_info_cause_6,  io_enq_2_bits_rep_info_cause_5,
              io_enq_2_bits_rep_info_cause_4,  io_enq_2_bits_rep_info_cause_3,
              io_enq_2_bits_rep_info_cause_2,  io_enq_2_bits_rep_info_cause_1,
              io_enq_2_bits_rep_info_cause_0};
    endcase
    return v[c];
  endfunction

  function automatic bit any_cause(input int w);
    bit r;
    r = 1'b0;
    for (int c = 0; c < 11; c++) if (cause_bit(w, c)) r = 1'b1;
    return r;
  endfunction

  // ---- 主循环 ----
  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int c = 0; c < 11; c++) cov_cause[c] = 0;
    rst = 1'b1;
    phase = 0;
    drive_payload();
    drive_env(1'b1);
    for (int w = 0; w < 3; w++) drive_enq(w, 1'b1);
    repeat (6) @(posedge clk);
    rst = 1'b0;

    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      automatic bit warm;
      warm = (cyc < WARM);
      // 相位每 2000 拍轮转一次（8 个相位）
      phase = warm ? 0 : ((cyc / 2000) % 8);
      @(negedge clk);
      // 从重放输出里回收 schedIndex，供 isLoadReplay 回流用
      if (g_io_replay_0_valid && rep_rdy[0]) lr_pool.push_back(g_io_replay_0_bits_schedIndex);
      if (g_io_replay_1_valid && rep_rdy[1]) lr_pool.push_back(g_io_replay_1_bits_schedIndex);
      if (g_io_replay_2_valid && rep_rdy[2]) lr_pool.push_back(g_io_replay_2_bits_schedIndex);
      while (lr_pool.size() > 64) void'(lr_pool.pop_front());
      if (!warm) begin
        check_outputs();
        sample_cov();
      end
      drive_payload();
      drive_env(warm);
      for (int w = 0; w < 3; w++) drive_enq(w, warm);
      @(posedge clk);
    end

    $display("=== LoadQueueReplay UT: cycles=%0d checks=%0d errors=%0d ===", NCYCLES, checks, errors);
    $display("--- coverage ---");
    for (int c = 0; c < 11; c++) $display("  cov_cause[%0d]      = %0d", c, cov_cause[c]);
    $display("  cov_replay_fire   = %0d", cov_replay_fire);
    $display("  cov_replay_stall  = %0d", cov_replay_stall);
    $display("  cov_lqfull        = %0d", cov_lqfull);
    $display("  cov_allocate      = %0d", cov_allocate);
    $display("  cov_redirect      = %0d", cov_redirect);
    $display("  cov_loadreplay    = %0d", cov_loadreplay);
    $display("  cov_lr_free       = %0d", cov_lr_free);
    $display("  cov_l2hint        = %0d", cov_l2hint);
    $display("  cov_tlbhint       = %0d", cov_tlbhint);
    $display("  cov_tld           = %0d", cov_tld);
    $display("  cov_tld_prev      = %0d", cov_tld_prev);
    $display("  cov_mf_block      = %0d", cov_mf_block);
    $display("  cov_mf_release    = %0d", cov_mf_release);
    $display("  cov_vecfb         = %0d", cov_vecfb);
    $display("  cov_topdown       = %0d", cov_topdown);
    begin
      automatic bit cov_ok = 1'b1;
      for (int c = 0; c < 11; c++) if (cov_cause[c] == 0) cov_ok = 1'b0;
      if (cov_replay_fire == 0 || cov_replay_stall == 0 || cov_lqfull == 0
          || cov_redirect == 0 || cov_loadreplay == 0 || cov_lr_free == 0
          || cov_l2hint == 0 || cov_tlbhint == 0 || cov_tld == 0 || cov_tld_prev == 0
          || cov_mf_block == 0 || cov_mf_release == 0 || cov_vecfb == 0
          || cov_topdown == 0 || cov_allocate == 0) cov_ok = 1'b0;
      // ★errors=0 单独不算数：覆盖闸有任何一个桶为 0 就判 FAIL★
      if (errors == 0 && checks > 0 && cov_ok) $display("TEST PASSED");
      else $display("TEST FAILED (errors=%0d checks=%0d cov_ok=%0b)", errors, checks, cov_ok);
    end
    $finish;
  end
endmodule''')
    text = "\n".join(L) + "\n"
    if args.check:
        cur = open(OUT).read() if os.path.exists(OUT) else None
        if cur != text:
            sys.stderr.write("DRIFT: %s 与生成器输出不一致，请重跑 %s\n" % (OUT, __file__))
            return 1
        print("gen_lqreplay_ut: tb 与生成器输出一致 (in=%d out=%d payload_random=%d)"
              % (len(ins), len(outs), len(rnd)))
        return 0
    with open(OUT, "w") as f:
        f.write(text)
    print("gen_lqreplay_ut: 已写入 %s (in=%d out=%d payload_random=%d)"
          % (OUT, len(ins), len(outs), len(rnd)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
