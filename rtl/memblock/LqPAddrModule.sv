// =============================================================================
//  LqPAddrModule —— LoadQueueRAR 分区证明「块 2: entry 状态更新 / CAM」canary
// -----------------------------------------------------------------------------
//  可读重写。golden 里这就是独立子模块 `LqPAddrModule`(清晰端口)——即 RAR 队列的
//  paddr CAM 存储：每条目存 16-bit 折叠哈希(PartialPAddr, 由顶层算好后经 io_wdata
//  写入), 对若干查询口做**纯相等 CAM 比较**产出 matchMask。它就是 impl 顶层
//  `xs_LoadQueueRAR_core` 里 `entry[i].ppaddr` 存储 + `camHit`/`releaseHit` 相等比较
//  的那一块被 golden 单独例化的部分。本文件把它提取为**同名 standalone 模块**, 逐端口
//  对齐 golden(flat scalar port), 供块 2 canary FM 分别读入 r:/i: 两库比对
//  (镜像块 1 的 FreeList_3)。
//
//  设计意图来源(人写 Chisel, 非 firtool golden):
//      src/main/scala/xiangshan/mem/lsqueue/LoadQueueData.scala
//        (LqPAddrModule / SyncDataModuleTemplate)
//
//  ── 微架构语义 ────────────────────────────────────────────────────────────────
//   存储  : data[i]  (i∈[0,72))  = 16-bit 哈希 paddr, 每条目一份寄存器(golden data_N)。
//   写口  : 3 个(3 个 load 流水口), 每口 {wen_w, waddr_w[6:0], wdata_w[15:0]}。
//           waddr 经 one-hot 译码(golden: 128'h1<<waddr)+8bank×9slot 展开, 命中条目 i
//           时把 wdata 写入 data[i]。三口保证 freelist 分到互不相同的槽; 即便撞地址,
//           golden 是「各口 (en?wd:0) 按位 OR」, 本重写逐位复刻该 OR 语义(bug-for-bug)。
//   读口  : 4 个 CAM 相等比较口, 全组合(无寄存):
//             releaseMdata_2         → releaseMmask_2_i          (release1Cycle 命中)
//             releaseViolationMdata_w→ releaseViolationMmask_w_i (w=0/1/2, 3 个 load 口)
//           mask_i = (mdata == data[i])。**纯相等**, allocated/robIdx/released 门控在
//           顶层块外做(见 LoadQueueRAR 顶层), 不在本 CAM 内。
//
//  ── 块 2 关系 R2(golden 展平 ↔ impl 数组)────────────────────────────────────
//    golden.data_i  ≡  impl.data[i]   (i∈[0,72), 16-bit)
//    golden 的 3×24 个 DelayN{,WithValid} 子模块**均 delay=0 直通**(assign out=in),
//    故写路径无流水; golden banked 译码展开后 = 逐条目 `wen_P & (waddr_P==i)` 门控,
//    与本重写一致(证见 docs/memblock/LoadQueueRAR_EntryUpdate_block2_proof.md)。
// =============================================================================
module LqPAddrModule
  import loadqueuerar_pkg::*;
(
  input  logic clock,
  input  logic reset,

  // ---- 3 个写口(one-hot 地址译码) ----
  input  logic               io_wen_0,
  input  logic               io_wen_1,
  input  logic               io_wen_2,
  input  logic [6:0]        io_waddr_0,
  input  logic [6:0]        io_waddr_1,
  input  logic [6:0]        io_waddr_2,
  input  logic [15:0]        io_wdata_0,
  input  logic [15:0]        io_wdata_1,
  input  logic [15:0]        io_wdata_2,

  // ---- release1Cycle CAM 口(golden 只用第 3 个 mdata) ----
  input  logic [15:0]        io_releaseMdata_2,
  output logic               io_releaseMmask_2_0,
  output logic               io_releaseMmask_2_1,
  output logic               io_releaseMmask_2_2,
  output logic               io_releaseMmask_2_3,
  output logic               io_releaseMmask_2_4,
  output logic               io_releaseMmask_2_5,
  output logic               io_releaseMmask_2_6,
  output logic               io_releaseMmask_2_7,
  output logic               io_releaseMmask_2_8,
  output logic               io_releaseMmask_2_9,
  output logic               io_releaseMmask_2_10,
  output logic               io_releaseMmask_2_11,
  output logic               io_releaseMmask_2_12,
  output logic               io_releaseMmask_2_13,
  output logic               io_releaseMmask_2_14,
  output logic               io_releaseMmask_2_15,
  output logic               io_releaseMmask_2_16,
  output logic               io_releaseMmask_2_17,
  output logic               io_releaseMmask_2_18,
  output logic               io_releaseMmask_2_19,
  output logic               io_releaseMmask_2_20,
  output logic               io_releaseMmask_2_21,
  output logic               io_releaseMmask_2_22,
  output logic               io_releaseMmask_2_23,
  output logic               io_releaseMmask_2_24,
  output logic               io_releaseMmask_2_25,
  output logic               io_releaseMmask_2_26,
  output logic               io_releaseMmask_2_27,
  output logic               io_releaseMmask_2_28,
  output logic               io_releaseMmask_2_29,
  output logic               io_releaseMmask_2_30,
  output logic               io_releaseMmask_2_31,
  output logic               io_releaseMmask_2_32,
  output logic               io_releaseMmask_2_33,
  output logic               io_releaseMmask_2_34,
  output logic               io_releaseMmask_2_35,
  output logic               io_releaseMmask_2_36,
  output logic               io_releaseMmask_2_37,
  output logic               io_releaseMmask_2_38,
  output logic               io_releaseMmask_2_39,
  output logic               io_releaseMmask_2_40,
  output logic               io_releaseMmask_2_41,
  output logic               io_releaseMmask_2_42,
  output logic               io_releaseMmask_2_43,
  output logic               io_releaseMmask_2_44,
  output logic               io_releaseMmask_2_45,
  output logic               io_releaseMmask_2_46,
  output logic               io_releaseMmask_2_47,
  output logic               io_releaseMmask_2_48,
  output logic               io_releaseMmask_2_49,
  output logic               io_releaseMmask_2_50,
  output logic               io_releaseMmask_2_51,
  output logic               io_releaseMmask_2_52,
  output logic               io_releaseMmask_2_53,
  output logic               io_releaseMmask_2_54,
  output logic               io_releaseMmask_2_55,
  output logic               io_releaseMmask_2_56,
  output logic               io_releaseMmask_2_57,
  output logic               io_releaseMmask_2_58,
  output logic               io_releaseMmask_2_59,
  output logic               io_releaseMmask_2_60,
  output logic               io_releaseMmask_2_61,
  output logic               io_releaseMmask_2_62,
  output logic               io_releaseMmask_2_63,
  output logic               io_releaseMmask_2_64,
  output logic               io_releaseMmask_2_65,
  output logic               io_releaseMmask_2_66,
  output logic               io_releaseMmask_2_67,
  output logic               io_releaseMmask_2_68,
  output logic               io_releaseMmask_2_69,
  output logic               io_releaseMmask_2_70,
  output logic               io_releaseMmask_2_71,

  // ---- 3 个 load 查询 CAM 口 ----
  input  logic [15:0]        io_releaseViolationMdata_0,
  input  logic [15:0]        io_releaseViolationMdata_1,
  input  logic [15:0]        io_releaseViolationMdata_2,
  output logic               io_releaseViolationMmask_0_0,
  output logic               io_releaseViolationMmask_0_1,
  output logic               io_releaseViolationMmask_0_2,
  output logic               io_releaseViolationMmask_0_3,
  output logic               io_releaseViolationMmask_0_4,
  output logic               io_releaseViolationMmask_0_5,
  output logic               io_releaseViolationMmask_0_6,
  output logic               io_releaseViolationMmask_0_7,
  output logic               io_releaseViolationMmask_0_8,
  output logic               io_releaseViolationMmask_0_9,
  output logic               io_releaseViolationMmask_0_10,
  output logic               io_releaseViolationMmask_0_11,
  output logic               io_releaseViolationMmask_0_12,
  output logic               io_releaseViolationMmask_0_13,
  output logic               io_releaseViolationMmask_0_14,
  output logic               io_releaseViolationMmask_0_15,
  output logic               io_releaseViolationMmask_0_16,
  output logic               io_releaseViolationMmask_0_17,
  output logic               io_releaseViolationMmask_0_18,
  output logic               io_releaseViolationMmask_0_19,
  output logic               io_releaseViolationMmask_0_20,
  output logic               io_releaseViolationMmask_0_21,
  output logic               io_releaseViolationMmask_0_22,
  output logic               io_releaseViolationMmask_0_23,
  output logic               io_releaseViolationMmask_0_24,
  output logic               io_releaseViolationMmask_0_25,
  output logic               io_releaseViolationMmask_0_26,
  output logic               io_releaseViolationMmask_0_27,
  output logic               io_releaseViolationMmask_0_28,
  output logic               io_releaseViolationMmask_0_29,
  output logic               io_releaseViolationMmask_0_30,
  output logic               io_releaseViolationMmask_0_31,
  output logic               io_releaseViolationMmask_0_32,
  output logic               io_releaseViolationMmask_0_33,
  output logic               io_releaseViolationMmask_0_34,
  output logic               io_releaseViolationMmask_0_35,
  output logic               io_releaseViolationMmask_0_36,
  output logic               io_releaseViolationMmask_0_37,
  output logic               io_releaseViolationMmask_0_38,
  output logic               io_releaseViolationMmask_0_39,
  output logic               io_releaseViolationMmask_0_40,
  output logic               io_releaseViolationMmask_0_41,
  output logic               io_releaseViolationMmask_0_42,
  output logic               io_releaseViolationMmask_0_43,
  output logic               io_releaseViolationMmask_0_44,
  output logic               io_releaseViolationMmask_0_45,
  output logic               io_releaseViolationMmask_0_46,
  output logic               io_releaseViolationMmask_0_47,
  output logic               io_releaseViolationMmask_0_48,
  output logic               io_releaseViolationMmask_0_49,
  output logic               io_releaseViolationMmask_0_50,
  output logic               io_releaseViolationMmask_0_51,
  output logic               io_releaseViolationMmask_0_52,
  output logic               io_releaseViolationMmask_0_53,
  output logic               io_releaseViolationMmask_0_54,
  output logic               io_releaseViolationMmask_0_55,
  output logic               io_releaseViolationMmask_0_56,
  output logic               io_releaseViolationMmask_0_57,
  output logic               io_releaseViolationMmask_0_58,
  output logic               io_releaseViolationMmask_0_59,
  output logic               io_releaseViolationMmask_0_60,
  output logic               io_releaseViolationMmask_0_61,
  output logic               io_releaseViolationMmask_0_62,
  output logic               io_releaseViolationMmask_0_63,
  output logic               io_releaseViolationMmask_0_64,
  output logic               io_releaseViolationMmask_0_65,
  output logic               io_releaseViolationMmask_0_66,
  output logic               io_releaseViolationMmask_0_67,
  output logic               io_releaseViolationMmask_0_68,
  output logic               io_releaseViolationMmask_0_69,
  output logic               io_releaseViolationMmask_0_70,
  output logic               io_releaseViolationMmask_0_71,
  output logic               io_releaseViolationMmask_1_0,
  output logic               io_releaseViolationMmask_1_1,
  output logic               io_releaseViolationMmask_1_2,
  output logic               io_releaseViolationMmask_1_3,
  output logic               io_releaseViolationMmask_1_4,
  output logic               io_releaseViolationMmask_1_5,
  output logic               io_releaseViolationMmask_1_6,
  output logic               io_releaseViolationMmask_1_7,
  output logic               io_releaseViolationMmask_1_8,
  output logic               io_releaseViolationMmask_1_9,
  output logic               io_releaseViolationMmask_1_10,
  output logic               io_releaseViolationMmask_1_11,
  output logic               io_releaseViolationMmask_1_12,
  output logic               io_releaseViolationMmask_1_13,
  output logic               io_releaseViolationMmask_1_14,
  output logic               io_releaseViolationMmask_1_15,
  output logic               io_releaseViolationMmask_1_16,
  output logic               io_releaseViolationMmask_1_17,
  output logic               io_releaseViolationMmask_1_18,
  output logic               io_releaseViolationMmask_1_19,
  output logic               io_releaseViolationMmask_1_20,
  output logic               io_releaseViolationMmask_1_21,
  output logic               io_releaseViolationMmask_1_22,
  output logic               io_releaseViolationMmask_1_23,
  output logic               io_releaseViolationMmask_1_24,
  output logic               io_releaseViolationMmask_1_25,
  output logic               io_releaseViolationMmask_1_26,
  output logic               io_releaseViolationMmask_1_27,
  output logic               io_releaseViolationMmask_1_28,
  output logic               io_releaseViolationMmask_1_29,
  output logic               io_releaseViolationMmask_1_30,
  output logic               io_releaseViolationMmask_1_31,
  output logic               io_releaseViolationMmask_1_32,
  output logic               io_releaseViolationMmask_1_33,
  output logic               io_releaseViolationMmask_1_34,
  output logic               io_releaseViolationMmask_1_35,
  output logic               io_releaseViolationMmask_1_36,
  output logic               io_releaseViolationMmask_1_37,
  output logic               io_releaseViolationMmask_1_38,
  output logic               io_releaseViolationMmask_1_39,
  output logic               io_releaseViolationMmask_1_40,
  output logic               io_releaseViolationMmask_1_41,
  output logic               io_releaseViolationMmask_1_42,
  output logic               io_releaseViolationMmask_1_43,
  output logic               io_releaseViolationMmask_1_44,
  output logic               io_releaseViolationMmask_1_45,
  output logic               io_releaseViolationMmask_1_46,
  output logic               io_releaseViolationMmask_1_47,
  output logic               io_releaseViolationMmask_1_48,
  output logic               io_releaseViolationMmask_1_49,
  output logic               io_releaseViolationMmask_1_50,
  output logic               io_releaseViolationMmask_1_51,
  output logic               io_releaseViolationMmask_1_52,
  output logic               io_releaseViolationMmask_1_53,
  output logic               io_releaseViolationMmask_1_54,
  output logic               io_releaseViolationMmask_1_55,
  output logic               io_releaseViolationMmask_1_56,
  output logic               io_releaseViolationMmask_1_57,
  output logic               io_releaseViolationMmask_1_58,
  output logic               io_releaseViolationMmask_1_59,
  output logic               io_releaseViolationMmask_1_60,
  output logic               io_releaseViolationMmask_1_61,
  output logic               io_releaseViolationMmask_1_62,
  output logic               io_releaseViolationMmask_1_63,
  output logic               io_releaseViolationMmask_1_64,
  output logic               io_releaseViolationMmask_1_65,
  output logic               io_releaseViolationMmask_1_66,
  output logic               io_releaseViolationMmask_1_67,
  output logic               io_releaseViolationMmask_1_68,
  output logic               io_releaseViolationMmask_1_69,
  output logic               io_releaseViolationMmask_1_70,
  output logic               io_releaseViolationMmask_1_71,
  output logic               io_releaseViolationMmask_2_0,
  output logic               io_releaseViolationMmask_2_1,
  output logic               io_releaseViolationMmask_2_2,
  output logic               io_releaseViolationMmask_2_3,
  output logic               io_releaseViolationMmask_2_4,
  output logic               io_releaseViolationMmask_2_5,
  output logic               io_releaseViolationMmask_2_6,
  output logic               io_releaseViolationMmask_2_7,
  output logic               io_releaseViolationMmask_2_8,
  output logic               io_releaseViolationMmask_2_9,
  output logic               io_releaseViolationMmask_2_10,
  output logic               io_releaseViolationMmask_2_11,
  output logic               io_releaseViolationMmask_2_12,
  output logic               io_releaseViolationMmask_2_13,
  output logic               io_releaseViolationMmask_2_14,
  output logic               io_releaseViolationMmask_2_15,
  output logic               io_releaseViolationMmask_2_16,
  output logic               io_releaseViolationMmask_2_17,
  output logic               io_releaseViolationMmask_2_18,
  output logic               io_releaseViolationMmask_2_19,
  output logic               io_releaseViolationMmask_2_20,
  output logic               io_releaseViolationMmask_2_21,
  output logic               io_releaseViolationMmask_2_22,
  output logic               io_releaseViolationMmask_2_23,
  output logic               io_releaseViolationMmask_2_24,
  output logic               io_releaseViolationMmask_2_25,
  output logic               io_releaseViolationMmask_2_26,
  output logic               io_releaseViolationMmask_2_27,
  output logic               io_releaseViolationMmask_2_28,
  output logic               io_releaseViolationMmask_2_29,
  output logic               io_releaseViolationMmask_2_30,
  output logic               io_releaseViolationMmask_2_31,
  output logic               io_releaseViolationMmask_2_32,
  output logic               io_releaseViolationMmask_2_33,
  output logic               io_releaseViolationMmask_2_34,
  output logic               io_releaseViolationMmask_2_35,
  output logic               io_releaseViolationMmask_2_36,
  output logic               io_releaseViolationMmask_2_37,
  output logic               io_releaseViolationMmask_2_38,
  output logic               io_releaseViolationMmask_2_39,
  output logic               io_releaseViolationMmask_2_40,
  output logic               io_releaseViolationMmask_2_41,
  output logic               io_releaseViolationMmask_2_42,
  output logic               io_releaseViolationMmask_2_43,
  output logic               io_releaseViolationMmask_2_44,
  output logic               io_releaseViolationMmask_2_45,
  output logic               io_releaseViolationMmask_2_46,
  output logic               io_releaseViolationMmask_2_47,
  output logic               io_releaseViolationMmask_2_48,
  output logic               io_releaseViolationMmask_2_49,
  output logic               io_releaseViolationMmask_2_50,
  output logic               io_releaseViolationMmask_2_51,
  output logic               io_releaseViolationMmask_2_52,
  output logic               io_releaseViolationMmask_2_53,
  output logic               io_releaseViolationMmask_2_54,
  output logic               io_releaseViolationMmask_2_55,
  output logic               io_releaseViolationMmask_2_56,
  output logic               io_releaseViolationMmask_2_57,
  output logic               io_releaseViolationMmask_2_58,
  output logic               io_releaseViolationMmask_2_59,
  output logic               io_releaseViolationMmask_2_60,
  output logic               io_releaseViolationMmask_2_61,
  output logic               io_releaseViolationMmask_2_62,
  output logic               io_releaseViolationMmask_2_63,
  output logic               io_releaseViolationMmask_2_64,
  output logic               io_releaseViolationMmask_2_65,
  output logic               io_releaseViolationMmask_2_66,
  output logic               io_releaseViolationMmask_2_67,
  output logic               io_releaseViolationMmask_2_68,
  output logic               io_releaseViolationMmask_2_69,
  output logic               io_releaseViolationMmask_2_70,
  output logic               io_releaseViolationMmask_2_71
);

  // ---- 数据存储: 72 条目 × 16-bit 哈希 paddr(golden data_N) ----
  logic [15:0] data [72];

  // ---- 写: 逐条目按 3 口 one-hot 命中 OR 写入 ----
  //   golden: `if (|{en2,en1,en0}) data_i <= (en0?wd0:0)|(en1?wd1:0)|(en2?wd2:0)`
  //   其中 en_w = wen_w & (waddr_w == i)。写门控与写值都逐位复刻(未命中口贡献 0)。
  //   golden data_N 无复位(SyncDataModuleTemplate 存储 SYNTHESIS 下不初始化)——照搬。
  for (genvar i = 0; i < 72; i++) begin : g_data
    logic en0, en1, en2, wr;
    logic [15:0] wval;
    always_comb begin
      en0  = io_wen_0 & (io_waddr_0 == 7'(i));
      en1  = io_wen_1 & (io_waddr_1 == 7'(i));
      en2  = io_wen_2 & (io_waddr_2 == 7'(i));
      wr   = en0 | en1 | en2;
      wval = (en0 ? io_wdata_0 : '0)
           | (en1 ? io_wdata_1 : '0)
           | (en2 ? io_wdata_2 : '0);
    end
    always_ff @(posedge clock) begin
      if (wr) data[i] <= wval;
    end
  end

  // ---- 读: 4 个纯相等 CAM 比较口(全组合) ----
  assign io_releaseMmask_2_0 = (io_releaseMdata_2 == data[0]);
  assign io_releaseMmask_2_1 = (io_releaseMdata_2 == data[1]);
  assign io_releaseMmask_2_2 = (io_releaseMdata_2 == data[2]);
  assign io_releaseMmask_2_3 = (io_releaseMdata_2 == data[3]);
  assign io_releaseMmask_2_4 = (io_releaseMdata_2 == data[4]);
  assign io_releaseMmask_2_5 = (io_releaseMdata_2 == data[5]);
  assign io_releaseMmask_2_6 = (io_releaseMdata_2 == data[6]);
  assign io_releaseMmask_2_7 = (io_releaseMdata_2 == data[7]);
  assign io_releaseMmask_2_8 = (io_releaseMdata_2 == data[8]);
  assign io_releaseMmask_2_9 = (io_releaseMdata_2 == data[9]);
  assign io_releaseMmask_2_10 = (io_releaseMdata_2 == data[10]);
  assign io_releaseMmask_2_11 = (io_releaseMdata_2 == data[11]);
  assign io_releaseMmask_2_12 = (io_releaseMdata_2 == data[12]);
  assign io_releaseMmask_2_13 = (io_releaseMdata_2 == data[13]);
  assign io_releaseMmask_2_14 = (io_releaseMdata_2 == data[14]);
  assign io_releaseMmask_2_15 = (io_releaseMdata_2 == data[15]);
  assign io_releaseMmask_2_16 = (io_releaseMdata_2 == data[16]);
  assign io_releaseMmask_2_17 = (io_releaseMdata_2 == data[17]);
  assign io_releaseMmask_2_18 = (io_releaseMdata_2 == data[18]);
  assign io_releaseMmask_2_19 = (io_releaseMdata_2 == data[19]);
  assign io_releaseMmask_2_20 = (io_releaseMdata_2 == data[20]);
  assign io_releaseMmask_2_21 = (io_releaseMdata_2 == data[21]);
  assign io_releaseMmask_2_22 = (io_releaseMdata_2 == data[22]);
  assign io_releaseMmask_2_23 = (io_releaseMdata_2 == data[23]);
  assign io_releaseMmask_2_24 = (io_releaseMdata_2 == data[24]);
  assign io_releaseMmask_2_25 = (io_releaseMdata_2 == data[25]);
  assign io_releaseMmask_2_26 = (io_releaseMdata_2 == data[26]);
  assign io_releaseMmask_2_27 = (io_releaseMdata_2 == data[27]);
  assign io_releaseMmask_2_28 = (io_releaseMdata_2 == data[28]);
  assign io_releaseMmask_2_29 = (io_releaseMdata_2 == data[29]);
  assign io_releaseMmask_2_30 = (io_releaseMdata_2 == data[30]);
  assign io_releaseMmask_2_31 = (io_releaseMdata_2 == data[31]);
  assign io_releaseMmask_2_32 = (io_releaseMdata_2 == data[32]);
  assign io_releaseMmask_2_33 = (io_releaseMdata_2 == data[33]);
  assign io_releaseMmask_2_34 = (io_releaseMdata_2 == data[34]);
  assign io_releaseMmask_2_35 = (io_releaseMdata_2 == data[35]);
  assign io_releaseMmask_2_36 = (io_releaseMdata_2 == data[36]);
  assign io_releaseMmask_2_37 = (io_releaseMdata_2 == data[37]);
  assign io_releaseMmask_2_38 = (io_releaseMdata_2 == data[38]);
  assign io_releaseMmask_2_39 = (io_releaseMdata_2 == data[39]);
  assign io_releaseMmask_2_40 = (io_releaseMdata_2 == data[40]);
  assign io_releaseMmask_2_41 = (io_releaseMdata_2 == data[41]);
  assign io_releaseMmask_2_42 = (io_releaseMdata_2 == data[42]);
  assign io_releaseMmask_2_43 = (io_releaseMdata_2 == data[43]);
  assign io_releaseMmask_2_44 = (io_releaseMdata_2 == data[44]);
  assign io_releaseMmask_2_45 = (io_releaseMdata_2 == data[45]);
  assign io_releaseMmask_2_46 = (io_releaseMdata_2 == data[46]);
  assign io_releaseMmask_2_47 = (io_releaseMdata_2 == data[47]);
  assign io_releaseMmask_2_48 = (io_releaseMdata_2 == data[48]);
  assign io_releaseMmask_2_49 = (io_releaseMdata_2 == data[49]);
  assign io_releaseMmask_2_50 = (io_releaseMdata_2 == data[50]);
  assign io_releaseMmask_2_51 = (io_releaseMdata_2 == data[51]);
  assign io_releaseMmask_2_52 = (io_releaseMdata_2 == data[52]);
  assign io_releaseMmask_2_53 = (io_releaseMdata_2 == data[53]);
  assign io_releaseMmask_2_54 = (io_releaseMdata_2 == data[54]);
  assign io_releaseMmask_2_55 = (io_releaseMdata_2 == data[55]);
  assign io_releaseMmask_2_56 = (io_releaseMdata_2 == data[56]);
  assign io_releaseMmask_2_57 = (io_releaseMdata_2 == data[57]);
  assign io_releaseMmask_2_58 = (io_releaseMdata_2 == data[58]);
  assign io_releaseMmask_2_59 = (io_releaseMdata_2 == data[59]);
  assign io_releaseMmask_2_60 = (io_releaseMdata_2 == data[60]);
  assign io_releaseMmask_2_61 = (io_releaseMdata_2 == data[61]);
  assign io_releaseMmask_2_62 = (io_releaseMdata_2 == data[62]);
  assign io_releaseMmask_2_63 = (io_releaseMdata_2 == data[63]);
  assign io_releaseMmask_2_64 = (io_releaseMdata_2 == data[64]);
  assign io_releaseMmask_2_65 = (io_releaseMdata_2 == data[65]);
  assign io_releaseMmask_2_66 = (io_releaseMdata_2 == data[66]);
  assign io_releaseMmask_2_67 = (io_releaseMdata_2 == data[67]);
  assign io_releaseMmask_2_68 = (io_releaseMdata_2 == data[68]);
  assign io_releaseMmask_2_69 = (io_releaseMdata_2 == data[69]);
  assign io_releaseMmask_2_70 = (io_releaseMdata_2 == data[70]);
  assign io_releaseMmask_2_71 = (io_releaseMdata_2 == data[71]);
  assign io_releaseViolationMmask_0_0 = (io_releaseViolationMdata_0 == data[0]);
  assign io_releaseViolationMmask_0_1 = (io_releaseViolationMdata_0 == data[1]);
  assign io_releaseViolationMmask_0_2 = (io_releaseViolationMdata_0 == data[2]);
  assign io_releaseViolationMmask_0_3 = (io_releaseViolationMdata_0 == data[3]);
  assign io_releaseViolationMmask_0_4 = (io_releaseViolationMdata_0 == data[4]);
  assign io_releaseViolationMmask_0_5 = (io_releaseViolationMdata_0 == data[5]);
  assign io_releaseViolationMmask_0_6 = (io_releaseViolationMdata_0 == data[6]);
  assign io_releaseViolationMmask_0_7 = (io_releaseViolationMdata_0 == data[7]);
  assign io_releaseViolationMmask_0_8 = (io_releaseViolationMdata_0 == data[8]);
  assign io_releaseViolationMmask_0_9 = (io_releaseViolationMdata_0 == data[9]);
  assign io_releaseViolationMmask_0_10 = (io_releaseViolationMdata_0 == data[10]);
  assign io_releaseViolationMmask_0_11 = (io_releaseViolationMdata_0 == data[11]);
  assign io_releaseViolationMmask_0_12 = (io_releaseViolationMdata_0 == data[12]);
  assign io_releaseViolationMmask_0_13 = (io_releaseViolationMdata_0 == data[13]);
  assign io_releaseViolationMmask_0_14 = (io_releaseViolationMdata_0 == data[14]);
  assign io_releaseViolationMmask_0_15 = (io_releaseViolationMdata_0 == data[15]);
  assign io_releaseViolationMmask_0_16 = (io_releaseViolationMdata_0 == data[16]);
  assign io_releaseViolationMmask_0_17 = (io_releaseViolationMdata_0 == data[17]);
  assign io_releaseViolationMmask_0_18 = (io_releaseViolationMdata_0 == data[18]);
  assign io_releaseViolationMmask_0_19 = (io_releaseViolationMdata_0 == data[19]);
  assign io_releaseViolationMmask_0_20 = (io_releaseViolationMdata_0 == data[20]);
  assign io_releaseViolationMmask_0_21 = (io_releaseViolationMdata_0 == data[21]);
  assign io_releaseViolationMmask_0_22 = (io_releaseViolationMdata_0 == data[22]);
  assign io_releaseViolationMmask_0_23 = (io_releaseViolationMdata_0 == data[23]);
  assign io_releaseViolationMmask_0_24 = (io_releaseViolationMdata_0 == data[24]);
  assign io_releaseViolationMmask_0_25 = (io_releaseViolationMdata_0 == data[25]);
  assign io_releaseViolationMmask_0_26 = (io_releaseViolationMdata_0 == data[26]);
  assign io_releaseViolationMmask_0_27 = (io_releaseViolationMdata_0 == data[27]);
  assign io_releaseViolationMmask_0_28 = (io_releaseViolationMdata_0 == data[28]);
  assign io_releaseViolationMmask_0_29 = (io_releaseViolationMdata_0 == data[29]);
  assign io_releaseViolationMmask_0_30 = (io_releaseViolationMdata_0 == data[30]);
  assign io_releaseViolationMmask_0_31 = (io_releaseViolationMdata_0 == data[31]);
  assign io_releaseViolationMmask_0_32 = (io_releaseViolationMdata_0 == data[32]);
  assign io_releaseViolationMmask_0_33 = (io_releaseViolationMdata_0 == data[33]);
  assign io_releaseViolationMmask_0_34 = (io_releaseViolationMdata_0 == data[34]);
  assign io_releaseViolationMmask_0_35 = (io_releaseViolationMdata_0 == data[35]);
  assign io_releaseViolationMmask_0_36 = (io_releaseViolationMdata_0 == data[36]);
  assign io_releaseViolationMmask_0_37 = (io_releaseViolationMdata_0 == data[37]);
  assign io_releaseViolationMmask_0_38 = (io_releaseViolationMdata_0 == data[38]);
  assign io_releaseViolationMmask_0_39 = (io_releaseViolationMdata_0 == data[39]);
  assign io_releaseViolationMmask_0_40 = (io_releaseViolationMdata_0 == data[40]);
  assign io_releaseViolationMmask_0_41 = (io_releaseViolationMdata_0 == data[41]);
  assign io_releaseViolationMmask_0_42 = (io_releaseViolationMdata_0 == data[42]);
  assign io_releaseViolationMmask_0_43 = (io_releaseViolationMdata_0 == data[43]);
  assign io_releaseViolationMmask_0_44 = (io_releaseViolationMdata_0 == data[44]);
  assign io_releaseViolationMmask_0_45 = (io_releaseViolationMdata_0 == data[45]);
  assign io_releaseViolationMmask_0_46 = (io_releaseViolationMdata_0 == data[46]);
  assign io_releaseViolationMmask_0_47 = (io_releaseViolationMdata_0 == data[47]);
  assign io_releaseViolationMmask_0_48 = (io_releaseViolationMdata_0 == data[48]);
  assign io_releaseViolationMmask_0_49 = (io_releaseViolationMdata_0 == data[49]);
  assign io_releaseViolationMmask_0_50 = (io_releaseViolationMdata_0 == data[50]);
  assign io_releaseViolationMmask_0_51 = (io_releaseViolationMdata_0 == data[51]);
  assign io_releaseViolationMmask_0_52 = (io_releaseViolationMdata_0 == data[52]);
  assign io_releaseViolationMmask_0_53 = (io_releaseViolationMdata_0 == data[53]);
  assign io_releaseViolationMmask_0_54 = (io_releaseViolationMdata_0 == data[54]);
  assign io_releaseViolationMmask_0_55 = (io_releaseViolationMdata_0 == data[55]);
  assign io_releaseViolationMmask_0_56 = (io_releaseViolationMdata_0 == data[56]);
  assign io_releaseViolationMmask_0_57 = (io_releaseViolationMdata_0 == data[57]);
  assign io_releaseViolationMmask_0_58 = (io_releaseViolationMdata_0 == data[58]);
  assign io_releaseViolationMmask_0_59 = (io_releaseViolationMdata_0 == data[59]);
  assign io_releaseViolationMmask_0_60 = (io_releaseViolationMdata_0 == data[60]);
  assign io_releaseViolationMmask_0_61 = (io_releaseViolationMdata_0 == data[61]);
  assign io_releaseViolationMmask_0_62 = (io_releaseViolationMdata_0 == data[62]);
  assign io_releaseViolationMmask_0_63 = (io_releaseViolationMdata_0 == data[63]);
  assign io_releaseViolationMmask_0_64 = (io_releaseViolationMdata_0 == data[64]);
  assign io_releaseViolationMmask_0_65 = (io_releaseViolationMdata_0 == data[65]);
  assign io_releaseViolationMmask_0_66 = (io_releaseViolationMdata_0 == data[66]);
  assign io_releaseViolationMmask_0_67 = (io_releaseViolationMdata_0 == data[67]);
  assign io_releaseViolationMmask_0_68 = (io_releaseViolationMdata_0 == data[68]);
  assign io_releaseViolationMmask_0_69 = (io_releaseViolationMdata_0 == data[69]);
  assign io_releaseViolationMmask_0_70 = (io_releaseViolationMdata_0 == data[70]);
  assign io_releaseViolationMmask_0_71 = (io_releaseViolationMdata_0 == data[71]);
  assign io_releaseViolationMmask_1_0 = (io_releaseViolationMdata_1 == data[0]);
  assign io_releaseViolationMmask_1_1 = (io_releaseViolationMdata_1 == data[1]);
  assign io_releaseViolationMmask_1_2 = (io_releaseViolationMdata_1 == data[2]);
  assign io_releaseViolationMmask_1_3 = (io_releaseViolationMdata_1 == data[3]);
  assign io_releaseViolationMmask_1_4 = (io_releaseViolationMdata_1 == data[4]);
  assign io_releaseViolationMmask_1_5 = (io_releaseViolationMdata_1 == data[5]);
  assign io_releaseViolationMmask_1_6 = (io_releaseViolationMdata_1 == data[6]);
  assign io_releaseViolationMmask_1_7 = (io_releaseViolationMdata_1 == data[7]);
  assign io_releaseViolationMmask_1_8 = (io_releaseViolationMdata_1 == data[8]);
  assign io_releaseViolationMmask_1_9 = (io_releaseViolationMdata_1 == data[9]);
  assign io_releaseViolationMmask_1_10 = (io_releaseViolationMdata_1 == data[10]);
  assign io_releaseViolationMmask_1_11 = (io_releaseViolationMdata_1 == data[11]);
  assign io_releaseViolationMmask_1_12 = (io_releaseViolationMdata_1 == data[12]);
  assign io_releaseViolationMmask_1_13 = (io_releaseViolationMdata_1 == data[13]);
  assign io_releaseViolationMmask_1_14 = (io_releaseViolationMdata_1 == data[14]);
  assign io_releaseViolationMmask_1_15 = (io_releaseViolationMdata_1 == data[15]);
  assign io_releaseViolationMmask_1_16 = (io_releaseViolationMdata_1 == data[16]);
  assign io_releaseViolationMmask_1_17 = (io_releaseViolationMdata_1 == data[17]);
  assign io_releaseViolationMmask_1_18 = (io_releaseViolationMdata_1 == data[18]);
  assign io_releaseViolationMmask_1_19 = (io_releaseViolationMdata_1 == data[19]);
  assign io_releaseViolationMmask_1_20 = (io_releaseViolationMdata_1 == data[20]);
  assign io_releaseViolationMmask_1_21 = (io_releaseViolationMdata_1 == data[21]);
  assign io_releaseViolationMmask_1_22 = (io_releaseViolationMdata_1 == data[22]);
  assign io_releaseViolationMmask_1_23 = (io_releaseViolationMdata_1 == data[23]);
  assign io_releaseViolationMmask_1_24 = (io_releaseViolationMdata_1 == data[24]);
  assign io_releaseViolationMmask_1_25 = (io_releaseViolationMdata_1 == data[25]);
  assign io_releaseViolationMmask_1_26 = (io_releaseViolationMdata_1 == data[26]);
  assign io_releaseViolationMmask_1_27 = (io_releaseViolationMdata_1 == data[27]);
  assign io_releaseViolationMmask_1_28 = (io_releaseViolationMdata_1 == data[28]);
  assign io_releaseViolationMmask_1_29 = (io_releaseViolationMdata_1 == data[29]);
  assign io_releaseViolationMmask_1_30 = (io_releaseViolationMdata_1 == data[30]);
  assign io_releaseViolationMmask_1_31 = (io_releaseViolationMdata_1 == data[31]);
  assign io_releaseViolationMmask_1_32 = (io_releaseViolationMdata_1 == data[32]);
  assign io_releaseViolationMmask_1_33 = (io_releaseViolationMdata_1 == data[33]);
  assign io_releaseViolationMmask_1_34 = (io_releaseViolationMdata_1 == data[34]);
  assign io_releaseViolationMmask_1_35 = (io_releaseViolationMdata_1 == data[35]);
  assign io_releaseViolationMmask_1_36 = (io_releaseViolationMdata_1 == data[36]);
  assign io_releaseViolationMmask_1_37 = (io_releaseViolationMdata_1 == data[37]);
  assign io_releaseViolationMmask_1_38 = (io_releaseViolationMdata_1 == data[38]);
  assign io_releaseViolationMmask_1_39 = (io_releaseViolationMdata_1 == data[39]);
  assign io_releaseViolationMmask_1_40 = (io_releaseViolationMdata_1 == data[40]);
  assign io_releaseViolationMmask_1_41 = (io_releaseViolationMdata_1 == data[41]);
  assign io_releaseViolationMmask_1_42 = (io_releaseViolationMdata_1 == data[42]);
  assign io_releaseViolationMmask_1_43 = (io_releaseViolationMdata_1 == data[43]);
  assign io_releaseViolationMmask_1_44 = (io_releaseViolationMdata_1 == data[44]);
  assign io_releaseViolationMmask_1_45 = (io_releaseViolationMdata_1 == data[45]);
  assign io_releaseViolationMmask_1_46 = (io_releaseViolationMdata_1 == data[46]);
  assign io_releaseViolationMmask_1_47 = (io_releaseViolationMdata_1 == data[47]);
  assign io_releaseViolationMmask_1_48 = (io_releaseViolationMdata_1 == data[48]);
  assign io_releaseViolationMmask_1_49 = (io_releaseViolationMdata_1 == data[49]);
  assign io_releaseViolationMmask_1_50 = (io_releaseViolationMdata_1 == data[50]);
  assign io_releaseViolationMmask_1_51 = (io_releaseViolationMdata_1 == data[51]);
  assign io_releaseViolationMmask_1_52 = (io_releaseViolationMdata_1 == data[52]);
  assign io_releaseViolationMmask_1_53 = (io_releaseViolationMdata_1 == data[53]);
  assign io_releaseViolationMmask_1_54 = (io_releaseViolationMdata_1 == data[54]);
  assign io_releaseViolationMmask_1_55 = (io_releaseViolationMdata_1 == data[55]);
  assign io_releaseViolationMmask_1_56 = (io_releaseViolationMdata_1 == data[56]);
  assign io_releaseViolationMmask_1_57 = (io_releaseViolationMdata_1 == data[57]);
  assign io_releaseViolationMmask_1_58 = (io_releaseViolationMdata_1 == data[58]);
  assign io_releaseViolationMmask_1_59 = (io_releaseViolationMdata_1 == data[59]);
  assign io_releaseViolationMmask_1_60 = (io_releaseViolationMdata_1 == data[60]);
  assign io_releaseViolationMmask_1_61 = (io_releaseViolationMdata_1 == data[61]);
  assign io_releaseViolationMmask_1_62 = (io_releaseViolationMdata_1 == data[62]);
  assign io_releaseViolationMmask_1_63 = (io_releaseViolationMdata_1 == data[63]);
  assign io_releaseViolationMmask_1_64 = (io_releaseViolationMdata_1 == data[64]);
  assign io_releaseViolationMmask_1_65 = (io_releaseViolationMdata_1 == data[65]);
  assign io_releaseViolationMmask_1_66 = (io_releaseViolationMdata_1 == data[66]);
  assign io_releaseViolationMmask_1_67 = (io_releaseViolationMdata_1 == data[67]);
  assign io_releaseViolationMmask_1_68 = (io_releaseViolationMdata_1 == data[68]);
  assign io_releaseViolationMmask_1_69 = (io_releaseViolationMdata_1 == data[69]);
  assign io_releaseViolationMmask_1_70 = (io_releaseViolationMdata_1 == data[70]);
  assign io_releaseViolationMmask_1_71 = (io_releaseViolationMdata_1 == data[71]);
  assign io_releaseViolationMmask_2_0 = (io_releaseViolationMdata_2 == data[0]);
  assign io_releaseViolationMmask_2_1 = (io_releaseViolationMdata_2 == data[1]);
  assign io_releaseViolationMmask_2_2 = (io_releaseViolationMdata_2 == data[2]);
  assign io_releaseViolationMmask_2_3 = (io_releaseViolationMdata_2 == data[3]);
  assign io_releaseViolationMmask_2_4 = (io_releaseViolationMdata_2 == data[4]);
  assign io_releaseViolationMmask_2_5 = (io_releaseViolationMdata_2 == data[5]);
  assign io_releaseViolationMmask_2_6 = (io_releaseViolationMdata_2 == data[6]);
  assign io_releaseViolationMmask_2_7 = (io_releaseViolationMdata_2 == data[7]);
  assign io_releaseViolationMmask_2_8 = (io_releaseViolationMdata_2 == data[8]);
  assign io_releaseViolationMmask_2_9 = (io_releaseViolationMdata_2 == data[9]);
  assign io_releaseViolationMmask_2_10 = (io_releaseViolationMdata_2 == data[10]);
  assign io_releaseViolationMmask_2_11 = (io_releaseViolationMdata_2 == data[11]);
  assign io_releaseViolationMmask_2_12 = (io_releaseViolationMdata_2 == data[12]);
  assign io_releaseViolationMmask_2_13 = (io_releaseViolationMdata_2 == data[13]);
  assign io_releaseViolationMmask_2_14 = (io_releaseViolationMdata_2 == data[14]);
  assign io_releaseViolationMmask_2_15 = (io_releaseViolationMdata_2 == data[15]);
  assign io_releaseViolationMmask_2_16 = (io_releaseViolationMdata_2 == data[16]);
  assign io_releaseViolationMmask_2_17 = (io_releaseViolationMdata_2 == data[17]);
  assign io_releaseViolationMmask_2_18 = (io_releaseViolationMdata_2 == data[18]);
  assign io_releaseViolationMmask_2_19 = (io_releaseViolationMdata_2 == data[19]);
  assign io_releaseViolationMmask_2_20 = (io_releaseViolationMdata_2 == data[20]);
  assign io_releaseViolationMmask_2_21 = (io_releaseViolationMdata_2 == data[21]);
  assign io_releaseViolationMmask_2_22 = (io_releaseViolationMdata_2 == data[22]);
  assign io_releaseViolationMmask_2_23 = (io_releaseViolationMdata_2 == data[23]);
  assign io_releaseViolationMmask_2_24 = (io_releaseViolationMdata_2 == data[24]);
  assign io_releaseViolationMmask_2_25 = (io_releaseViolationMdata_2 == data[25]);
  assign io_releaseViolationMmask_2_26 = (io_releaseViolationMdata_2 == data[26]);
  assign io_releaseViolationMmask_2_27 = (io_releaseViolationMdata_2 == data[27]);
  assign io_releaseViolationMmask_2_28 = (io_releaseViolationMdata_2 == data[28]);
  assign io_releaseViolationMmask_2_29 = (io_releaseViolationMdata_2 == data[29]);
  assign io_releaseViolationMmask_2_30 = (io_releaseViolationMdata_2 == data[30]);
  assign io_releaseViolationMmask_2_31 = (io_releaseViolationMdata_2 == data[31]);
  assign io_releaseViolationMmask_2_32 = (io_releaseViolationMdata_2 == data[32]);
  assign io_releaseViolationMmask_2_33 = (io_releaseViolationMdata_2 == data[33]);
  assign io_releaseViolationMmask_2_34 = (io_releaseViolationMdata_2 == data[34]);
  assign io_releaseViolationMmask_2_35 = (io_releaseViolationMdata_2 == data[35]);
  assign io_releaseViolationMmask_2_36 = (io_releaseViolationMdata_2 == data[36]);
  assign io_releaseViolationMmask_2_37 = (io_releaseViolationMdata_2 == data[37]);
  assign io_releaseViolationMmask_2_38 = (io_releaseViolationMdata_2 == data[38]);
  assign io_releaseViolationMmask_2_39 = (io_releaseViolationMdata_2 == data[39]);
  assign io_releaseViolationMmask_2_40 = (io_releaseViolationMdata_2 == data[40]);
  assign io_releaseViolationMmask_2_41 = (io_releaseViolationMdata_2 == data[41]);
  assign io_releaseViolationMmask_2_42 = (io_releaseViolationMdata_2 == data[42]);
  assign io_releaseViolationMmask_2_43 = (io_releaseViolationMdata_2 == data[43]);
  assign io_releaseViolationMmask_2_44 = (io_releaseViolationMdata_2 == data[44]);
  assign io_releaseViolationMmask_2_45 = (io_releaseViolationMdata_2 == data[45]);
  assign io_releaseViolationMmask_2_46 = (io_releaseViolationMdata_2 == data[46]);
  assign io_releaseViolationMmask_2_47 = (io_releaseViolationMdata_2 == data[47]);
  assign io_releaseViolationMmask_2_48 = (io_releaseViolationMdata_2 == data[48]);
  assign io_releaseViolationMmask_2_49 = (io_releaseViolationMdata_2 == data[49]);
  assign io_releaseViolationMmask_2_50 = (io_releaseViolationMdata_2 == data[50]);
  assign io_releaseViolationMmask_2_51 = (io_releaseViolationMdata_2 == data[51]);
  assign io_releaseViolationMmask_2_52 = (io_releaseViolationMdata_2 == data[52]);
  assign io_releaseViolationMmask_2_53 = (io_releaseViolationMdata_2 == data[53]);
  assign io_releaseViolationMmask_2_54 = (io_releaseViolationMdata_2 == data[54]);
  assign io_releaseViolationMmask_2_55 = (io_releaseViolationMdata_2 == data[55]);
  assign io_releaseViolationMmask_2_56 = (io_releaseViolationMdata_2 == data[56]);
  assign io_releaseViolationMmask_2_57 = (io_releaseViolationMdata_2 == data[57]);
  assign io_releaseViolationMmask_2_58 = (io_releaseViolationMdata_2 == data[58]);
  assign io_releaseViolationMmask_2_59 = (io_releaseViolationMdata_2 == data[59]);
  assign io_releaseViolationMmask_2_60 = (io_releaseViolationMdata_2 == data[60]);
  assign io_releaseViolationMmask_2_61 = (io_releaseViolationMdata_2 == data[61]);
  assign io_releaseViolationMmask_2_62 = (io_releaseViolationMdata_2 == data[62]);
  assign io_releaseViolationMmask_2_63 = (io_releaseViolationMdata_2 == data[63]);
  assign io_releaseViolationMmask_2_64 = (io_releaseViolationMdata_2 == data[64]);
  assign io_releaseViolationMmask_2_65 = (io_releaseViolationMdata_2 == data[65]);
  assign io_releaseViolationMmask_2_66 = (io_releaseViolationMdata_2 == data[66]);
  assign io_releaseViolationMmask_2_67 = (io_releaseViolationMdata_2 == data[67]);
  assign io_releaseViolationMmask_2_68 = (io_releaseViolationMdata_2 == data[68]);
  assign io_releaseViolationMmask_2_69 = (io_releaseViolationMdata_2 == data[69]);
  assign io_releaseViolationMmask_2_70 = (io_releaseViolationMdata_2 == data[70]);
  assign io_releaseViolationMmask_2_71 = (io_releaseViolationMdata_2 == data[71]);

endmodule
