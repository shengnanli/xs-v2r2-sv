// 自动生成:scripts/gen_newdispatch.py —— 勿手改(逻辑为从 NewDispatch.scala 设计意图的可读重写)

// =====================================================================
// 机械互联表(豁免结构闸门):7 个真子模块黑盒例化 + 34 enq 端口输出选择展开。
// 子模块两侧共用 golden 定义(UT/FM)。输入引脚「驱动值」已在 newdispatch_logic.svh
// 算好(allSrcState/路由/反压/...);本表只做例化、连线、统一 PriorityMux 展开。
// =====================================================================

  // ---- 子模块输出网线(golden 同名,桥接到可读核 clean 网)----
  wire _lsqEnqCtrl_io_enq_canAccept;
  wire _lsqEnqCtrl_io_enq_resp_0_lqIdx_flag;
  wire [6:0] _lsqEnqCtrl_io_enq_resp_0_lqIdx_value;
  wire _lsqEnqCtrl_io_enq_resp_0_sqIdx_flag;
  wire [5:0] _lsqEnqCtrl_io_enq_resp_0_sqIdx_value;
  wire _lsqEnqCtrl_io_enq_resp_1_lqIdx_flag;
  wire [6:0] _lsqEnqCtrl_io_enq_resp_1_lqIdx_value;
  wire _lsqEnqCtrl_io_enq_resp_1_sqIdx_flag;
  wire [5:0] _lsqEnqCtrl_io_enq_resp_1_sqIdx_value;
  wire _lsqEnqCtrl_io_enq_resp_2_lqIdx_flag;
  wire [6:0] _lsqEnqCtrl_io_enq_resp_2_lqIdx_value;
  wire _lsqEnqCtrl_io_enq_resp_2_sqIdx_flag;
  wire [5:0] _lsqEnqCtrl_io_enq_resp_2_sqIdx_value;
  wire _lsqEnqCtrl_io_enq_resp_3_lqIdx_flag;
  wire [6:0] _lsqEnqCtrl_io_enq_resp_3_lqIdx_value;
  wire _lsqEnqCtrl_io_enq_resp_3_sqIdx_flag;
  wire [5:0] _lsqEnqCtrl_io_enq_resp_3_sqIdx_value;
  wire _lsqEnqCtrl_io_enq_resp_4_lqIdx_flag;
  wire [6:0] _lsqEnqCtrl_io_enq_resp_4_lqIdx_value;
  wire _lsqEnqCtrl_io_enq_resp_4_sqIdx_flag;
  wire [5:0] _lsqEnqCtrl_io_enq_resp_4_sqIdx_value;
  wire _lsqEnqCtrl_io_enq_resp_5_lqIdx_flag;
  wire [6:0] _lsqEnqCtrl_io_enq_resp_5_lqIdx_value;
  wire _lsqEnqCtrl_io_enq_resp_5_sqIdx_flag;
  wire [5:0] _lsqEnqCtrl_io_enq_resp_5_sqIdx_value;
  wire [6:0] _lsqEnqCtrl_io_lqFreeCount;
  wire [5:0] _lsqEnqCtrl_io_sqFreeCount;
  wire _vlBusyTable_io_read_0_resp;
  wire _vlBusyTable_io_read_1_resp;
  wire _vlBusyTable_io_read_2_resp;
  wire _vlBusyTable_io_read_3_resp;
  wire _vlBusyTable_io_read_4_resp;
  wire _vlBusyTable_io_read_5_resp;
  wire _vlBusyTable_io_vl_read_vlReadInfo_0_is_nonzero;
  wire _vlBusyTable_io_vl_read_vlReadInfo_0_is_vlmax;
  wire _vlBusyTable_io_vl_read_vlReadInfo_1_is_nonzero;
  wire _vlBusyTable_io_vl_read_vlReadInfo_1_is_vlmax;
  wire _vlBusyTable_io_vl_read_vlReadInfo_2_is_nonzero;
  wire _vlBusyTable_io_vl_read_vlReadInfo_2_is_vlmax;
  wire _vlBusyTable_io_vl_read_vlReadInfo_3_is_nonzero;
  wire _vlBusyTable_io_vl_read_vlReadInfo_3_is_vlmax;
  wire _vlBusyTable_io_vl_read_vlReadInfo_4_is_nonzero;
  wire _vlBusyTable_io_vl_read_vlReadInfo_4_is_vlmax;
  wire _vlBusyTable_io_vl_read_vlReadInfo_5_is_nonzero;
  wire _vlBusyTable_io_vl_read_vlReadInfo_5_is_vlmax;
  wire _v0BusyTable_io_read_0_resp;
  wire _v0BusyTable_io_read_1_resp;
  wire _v0BusyTable_io_read_2_resp;
  wire _v0BusyTable_io_read_3_resp;
  wire _v0BusyTable_io_read_4_resp;
  wire _v0BusyTable_io_read_5_resp;
  wire _vecBusyTable_io_read_0_resp;
  wire _vecBusyTable_io_read_1_resp;
  wire _vecBusyTable_io_read_2_resp;
  wire _vecBusyTable_io_read_3_resp;
  wire _vecBusyTable_io_read_4_resp;
  wire _vecBusyTable_io_read_5_resp;
  wire _vecBusyTable_io_read_6_resp;
  wire _vecBusyTable_io_read_7_resp;
  wire _vecBusyTable_io_read_8_resp;
  wire _vecBusyTable_io_read_9_resp;
  wire _vecBusyTable_io_read_10_resp;
  wire _vecBusyTable_io_read_11_resp;
  wire _vecBusyTable_io_read_12_resp;
  wire _vecBusyTable_io_read_13_resp;
  wire _vecBusyTable_io_read_14_resp;
  wire _vecBusyTable_io_read_15_resp;
  wire _vecBusyTable_io_read_16_resp;
  wire _vecBusyTable_io_read_17_resp;
  wire _fpBusyTable_io_read_0_resp;
  wire _fpBusyTable_io_read_1_resp;
  wire _fpBusyTable_io_read_2_resp;
  wire _fpBusyTable_io_read_3_resp;
  wire _fpBusyTable_io_read_4_resp;
  wire _fpBusyTable_io_read_5_resp;
  wire _fpBusyTable_io_read_6_resp;
  wire _fpBusyTable_io_read_7_resp;
  wire _fpBusyTable_io_read_8_resp;
  wire _fpBusyTable_io_read_9_resp;
  wire _fpBusyTable_io_read_10_resp;
  wire _fpBusyTable_io_read_11_resp;
  wire _fpBusyTable_io_read_12_resp;
  wire _fpBusyTable_io_read_13_resp;
  wire _fpBusyTable_io_read_14_resp;
  wire _fpBusyTable_io_read_15_resp;
  wire _fpBusyTable_io_read_16_resp;
  wire _fpBusyTable_io_read_17_resp;
  wire _intBusyTable_io_read_0_resp;
  wire [1:0] _intBusyTable_io_read_0_loadDependency_0;
  wire [1:0] _intBusyTable_io_read_0_loadDependency_1;
  wire [1:0] _intBusyTable_io_read_0_loadDependency_2;
  wire _intBusyTable_io_read_1_resp;
  wire [1:0] _intBusyTable_io_read_1_loadDependency_0;
  wire [1:0] _intBusyTable_io_read_1_loadDependency_1;
  wire [1:0] _intBusyTable_io_read_1_loadDependency_2;
  wire _intBusyTable_io_read_2_resp;
  wire [1:0] _intBusyTable_io_read_2_loadDependency_0;
  wire [1:0] _intBusyTable_io_read_2_loadDependency_1;
  wire [1:0] _intBusyTable_io_read_2_loadDependency_2;
  wire _intBusyTable_io_read_3_resp;
  wire [1:0] _intBusyTable_io_read_3_loadDependency_0;
  wire [1:0] _intBusyTable_io_read_3_loadDependency_1;
  wire [1:0] _intBusyTable_io_read_3_loadDependency_2;
  wire _intBusyTable_io_read_4_resp;
  wire [1:0] _intBusyTable_io_read_4_loadDependency_0;
  wire [1:0] _intBusyTable_io_read_4_loadDependency_1;
  wire [1:0] _intBusyTable_io_read_4_loadDependency_2;
  wire _intBusyTable_io_read_5_resp;
  wire [1:0] _intBusyTable_io_read_5_loadDependency_0;
  wire [1:0] _intBusyTable_io_read_5_loadDependency_1;
  wire [1:0] _intBusyTable_io_read_5_loadDependency_2;
  wire _intBusyTable_io_read_6_resp;
  wire [1:0] _intBusyTable_io_read_6_loadDependency_0;
  wire [1:0] _intBusyTable_io_read_6_loadDependency_1;
  wire [1:0] _intBusyTable_io_read_6_loadDependency_2;
  wire _intBusyTable_io_read_7_resp;
  wire [1:0] _intBusyTable_io_read_7_loadDependency_0;
  wire [1:0] _intBusyTable_io_read_7_loadDependency_1;
  wire [1:0] _intBusyTable_io_read_7_loadDependency_2;
  wire _intBusyTable_io_read_8_resp;
  wire [1:0] _intBusyTable_io_read_8_loadDependency_0;
  wire [1:0] _intBusyTable_io_read_8_loadDependency_1;
  wire [1:0] _intBusyTable_io_read_8_loadDependency_2;
  wire _intBusyTable_io_read_9_resp;
  wire [1:0] _intBusyTable_io_read_9_loadDependency_0;
  wire [1:0] _intBusyTable_io_read_9_loadDependency_1;
  wire [1:0] _intBusyTable_io_read_9_loadDependency_2;
  wire _intBusyTable_io_read_10_resp;
  wire [1:0] _intBusyTable_io_read_10_loadDependency_0;
  wire [1:0] _intBusyTable_io_read_10_loadDependency_1;
  wire [1:0] _intBusyTable_io_read_10_loadDependency_2;
  wire _intBusyTable_io_read_11_resp;
  wire [1:0] _intBusyTable_io_read_11_loadDependency_0;
  wire [1:0] _intBusyTable_io_read_11_loadDependency_1;
  wire [1:0] _intBusyTable_io_read_11_loadDependency_2;
  wire _rcTagTable_io_readPorts_0_valid;
  wire [4:0] _rcTagTable_io_readPorts_0_addr;
  wire _rcTagTable_io_readPorts_1_valid;
  wire [4:0] _rcTagTable_io_readPorts_1_addr;
  wire _rcTagTable_io_readPorts_2_valid;
  wire [4:0] _rcTagTable_io_readPorts_2_addr;
  wire _rcTagTable_io_readPorts_3_valid;
  wire [4:0] _rcTagTable_io_readPorts_3_addr;
  wire _rcTagTable_io_readPorts_4_valid;
  wire [4:0] _rcTagTable_io_readPorts_4_addr;
  wire _rcTagTable_io_readPorts_5_valid;
  wire [4:0] _rcTagTable_io_readPorts_5_addr;
  wire _rcTagTable_io_readPorts_6_valid;
  wire [4:0] _rcTagTable_io_readPorts_6_addr;
  wire _rcTagTable_io_readPorts_7_valid;
  wire [4:0] _rcTagTable_io_readPorts_7_addr;
  wire _rcTagTable_io_readPorts_8_valid;
  wire [4:0] _rcTagTable_io_readPorts_8_addr;
  wire _rcTagTable_io_readPorts_9_valid;
  wire [4:0] _rcTagTable_io_readPorts_9_addr;
  wire _rcTagTable_io_readPorts_10_valid;
  wire [4:0] _rcTagTable_io_readPorts_10_addr;
  wire _rcTagTable_io_readPorts_11_valid;
  wire [4:0] _rcTagTable_io_readPorts_11_addr;

  // ---- 桥接:子模块输出 → 可读核就绪查询/反压用网 ----
  assign bt_resp_int[0] = _intBusyTable_io_read_0_resp;
  assign bt_int_ldep[0][0] = _intBusyTable_io_read_0_loadDependency_0;
  assign bt_int_ldep[0][1] = _intBusyTable_io_read_0_loadDependency_1;
  assign bt_int_ldep[0][2] = _intBusyTable_io_read_0_loadDependency_2;
  assign bt_resp_int[1] = _intBusyTable_io_read_1_resp;
  assign bt_int_ldep[1][0] = _intBusyTable_io_read_1_loadDependency_0;
  assign bt_int_ldep[1][1] = _intBusyTable_io_read_1_loadDependency_1;
  assign bt_int_ldep[1][2] = _intBusyTable_io_read_1_loadDependency_2;
  assign bt_resp_int[2] = _intBusyTable_io_read_2_resp;
  assign bt_int_ldep[2][0] = _intBusyTable_io_read_2_loadDependency_0;
  assign bt_int_ldep[2][1] = _intBusyTable_io_read_2_loadDependency_1;
  assign bt_int_ldep[2][2] = _intBusyTable_io_read_2_loadDependency_2;
  assign bt_resp_int[3] = _intBusyTable_io_read_3_resp;
  assign bt_int_ldep[3][0] = _intBusyTable_io_read_3_loadDependency_0;
  assign bt_int_ldep[3][1] = _intBusyTable_io_read_3_loadDependency_1;
  assign bt_int_ldep[3][2] = _intBusyTable_io_read_3_loadDependency_2;
  assign bt_resp_int[4] = _intBusyTable_io_read_4_resp;
  assign bt_int_ldep[4][0] = _intBusyTable_io_read_4_loadDependency_0;
  assign bt_int_ldep[4][1] = _intBusyTable_io_read_4_loadDependency_1;
  assign bt_int_ldep[4][2] = _intBusyTable_io_read_4_loadDependency_2;
  assign bt_resp_int[5] = _intBusyTable_io_read_5_resp;
  assign bt_int_ldep[5][0] = _intBusyTable_io_read_5_loadDependency_0;
  assign bt_int_ldep[5][1] = _intBusyTable_io_read_5_loadDependency_1;
  assign bt_int_ldep[5][2] = _intBusyTable_io_read_5_loadDependency_2;
  assign bt_resp_int[6] = _intBusyTable_io_read_6_resp;
  assign bt_int_ldep[6][0] = _intBusyTable_io_read_6_loadDependency_0;
  assign bt_int_ldep[6][1] = _intBusyTable_io_read_6_loadDependency_1;
  assign bt_int_ldep[6][2] = _intBusyTable_io_read_6_loadDependency_2;
  assign bt_resp_int[7] = _intBusyTable_io_read_7_resp;
  assign bt_int_ldep[7][0] = _intBusyTable_io_read_7_loadDependency_0;
  assign bt_int_ldep[7][1] = _intBusyTable_io_read_7_loadDependency_1;
  assign bt_int_ldep[7][2] = _intBusyTable_io_read_7_loadDependency_2;
  assign bt_resp_int[8] = _intBusyTable_io_read_8_resp;
  assign bt_int_ldep[8][0] = _intBusyTable_io_read_8_loadDependency_0;
  assign bt_int_ldep[8][1] = _intBusyTable_io_read_8_loadDependency_1;
  assign bt_int_ldep[8][2] = _intBusyTable_io_read_8_loadDependency_2;
  assign bt_resp_int[9] = _intBusyTable_io_read_9_resp;
  assign bt_int_ldep[9][0] = _intBusyTable_io_read_9_loadDependency_0;
  assign bt_int_ldep[9][1] = _intBusyTable_io_read_9_loadDependency_1;
  assign bt_int_ldep[9][2] = _intBusyTable_io_read_9_loadDependency_2;
  assign bt_resp_int[10] = _intBusyTable_io_read_10_resp;
  assign bt_int_ldep[10][0] = _intBusyTable_io_read_10_loadDependency_0;
  assign bt_int_ldep[10][1] = _intBusyTable_io_read_10_loadDependency_1;
  assign bt_int_ldep[10][2] = _intBusyTable_io_read_10_loadDependency_2;
  assign bt_resp_int[11] = _intBusyTable_io_read_11_resp;
  assign bt_int_ldep[11][0] = _intBusyTable_io_read_11_loadDependency_0;
  assign bt_int_ldep[11][1] = _intBusyTable_io_read_11_loadDependency_1;
  assign bt_int_ldep[11][2] = _intBusyTable_io_read_11_loadDependency_2;
  assign bt_resp_fp[0]  = _fpBusyTable_io_read_0_resp;
  assign bt_resp_vec[0] = _vecBusyTable_io_read_0_resp;
  assign bt_resp_fp[1]  = _fpBusyTable_io_read_1_resp;
  assign bt_resp_vec[1] = _vecBusyTable_io_read_1_resp;
  assign bt_resp_fp[2]  = _fpBusyTable_io_read_2_resp;
  assign bt_resp_vec[2] = _vecBusyTable_io_read_2_resp;
  assign bt_resp_fp[3]  = _fpBusyTable_io_read_3_resp;
  assign bt_resp_vec[3] = _vecBusyTable_io_read_3_resp;
  assign bt_resp_fp[4]  = _fpBusyTable_io_read_4_resp;
  assign bt_resp_vec[4] = _vecBusyTable_io_read_4_resp;
  assign bt_resp_fp[5]  = _fpBusyTable_io_read_5_resp;
  assign bt_resp_vec[5] = _vecBusyTable_io_read_5_resp;
  assign bt_resp_fp[6]  = _fpBusyTable_io_read_6_resp;
  assign bt_resp_vec[6] = _vecBusyTable_io_read_6_resp;
  assign bt_resp_fp[7]  = _fpBusyTable_io_read_7_resp;
  assign bt_resp_vec[7] = _vecBusyTable_io_read_7_resp;
  assign bt_resp_fp[8]  = _fpBusyTable_io_read_8_resp;
  assign bt_resp_vec[8] = _vecBusyTable_io_read_8_resp;
  assign bt_resp_fp[9]  = _fpBusyTable_io_read_9_resp;
  assign bt_resp_vec[9] = _vecBusyTable_io_read_9_resp;
  assign bt_resp_fp[10]  = _fpBusyTable_io_read_10_resp;
  assign bt_resp_vec[10] = _vecBusyTable_io_read_10_resp;
  assign bt_resp_fp[11]  = _fpBusyTable_io_read_11_resp;
  assign bt_resp_vec[11] = _vecBusyTable_io_read_11_resp;
  assign bt_resp_fp[12]  = _fpBusyTable_io_read_12_resp;
  assign bt_resp_vec[12] = _vecBusyTable_io_read_12_resp;
  assign bt_resp_fp[13]  = _fpBusyTable_io_read_13_resp;
  assign bt_resp_vec[13] = _vecBusyTable_io_read_13_resp;
  assign bt_resp_fp[14]  = _fpBusyTable_io_read_14_resp;
  assign bt_resp_vec[14] = _vecBusyTable_io_read_14_resp;
  assign bt_resp_fp[15]  = _fpBusyTable_io_read_15_resp;
  assign bt_resp_vec[15] = _vecBusyTable_io_read_15_resp;
  assign bt_resp_fp[16]  = _fpBusyTable_io_read_16_resp;
  assign bt_resp_vec[16] = _vecBusyTable_io_read_16_resp;
  assign bt_resp_fp[17]  = _fpBusyTable_io_read_17_resp;
  assign bt_resp_vec[17] = _vecBusyTable_io_read_17_resp;
  assign bt_resp_v0[0] = _v0BusyTable_io_read_0_resp;
  assign bt_resp_vl[0] = _vlBusyTable_io_read_0_resp;
  assign vl_is_vlmax[0]   = _vlBusyTable_io_vl_read_vlReadInfo_0_is_vlmax;
  assign vl_is_nonzero[0] = _vlBusyTable_io_vl_read_vlReadInfo_0_is_nonzero;
  assign bt_resp_v0[1] = _v0BusyTable_io_read_1_resp;
  assign bt_resp_vl[1] = _vlBusyTable_io_read_1_resp;
  assign vl_is_vlmax[1]   = _vlBusyTable_io_vl_read_vlReadInfo_1_is_vlmax;
  assign vl_is_nonzero[1] = _vlBusyTable_io_vl_read_vlReadInfo_1_is_nonzero;
  assign bt_resp_v0[2] = _v0BusyTable_io_read_2_resp;
  assign bt_resp_vl[2] = _vlBusyTable_io_read_2_resp;
  assign vl_is_vlmax[2]   = _vlBusyTable_io_vl_read_vlReadInfo_2_is_vlmax;
  assign vl_is_nonzero[2] = _vlBusyTable_io_vl_read_vlReadInfo_2_is_nonzero;
  assign bt_resp_v0[3] = _v0BusyTable_io_read_3_resp;
  assign bt_resp_vl[3] = _vlBusyTable_io_read_3_resp;
  assign vl_is_vlmax[3]   = _vlBusyTable_io_vl_read_vlReadInfo_3_is_vlmax;
  assign vl_is_nonzero[3] = _vlBusyTable_io_vl_read_vlReadInfo_3_is_nonzero;
  assign bt_resp_v0[4] = _v0BusyTable_io_read_4_resp;
  assign bt_resp_vl[4] = _vlBusyTable_io_read_4_resp;
  assign vl_is_vlmax[4]   = _vlBusyTable_io_vl_read_vlReadInfo_4_is_vlmax;
  assign vl_is_nonzero[4] = _vlBusyTable_io_vl_read_vlReadInfo_4_is_nonzero;
  assign bt_resp_v0[5] = _v0BusyTable_io_read_5_resp;
  assign bt_resp_vl[5] = _vlBusyTable_io_read_5_resp;
  assign vl_is_vlmax[5]   = _vlBusyTable_io_vl_read_vlReadInfo_5_is_vlmax;
  assign vl_is_nonzero[5] = _vlBusyTable_io_vl_read_vlReadInfo_5_is_nonzero;
  assign lsq_canAccept    = _lsqEnqCtrl_io_enq_canAccept;
  assign lsq_lqFreeCount  = _lsqEnqCtrl_io_lqFreeCount;
  assign lsq_sqFreeCount  = _lsqEnqCtrl_io_sqFreeCount;

  // ---- allocPregsValid(int 域,intBusyTable / rcTagTable 引用的命名网)----
  wire allocPregsValid_0_0 = allocPregsValid[0][0];
  wire allocPregsValid_0_1 = allocPregsValid[0][1];
  wire allocPregsValid_0_2 = allocPregsValid[0][2];
  wire allocPregsValid_0_3 = allocPregsValid[0][3];
  wire allocPregsValid_0_4 = allocPregsValid[0][4];
  wire allocPregsValid_0_5 = allocPregsValid[0][5];

  // ---- lsqEnqCtrl 用 RegNext(redirect)(派遣比 dispatch2iq 早一拍)----
  reg lsqEnqCtrl_io_redirect_REG_valid;
  always_ff @(posedge clock) lsqEnqCtrl_io_redirect_REG_valid <= io_redirect_valid;

  // ---- 7 个真子模块黑盒例化(两侧共用 golden 定义)----
  RegCacheTagTable rcTagTable (
    .clock                                   (clock),
    .reset                                   (reset),
    .io_readPorts_0_ren
      (io_fromRename_0_valid & io_fromRename_0_bits_srcType_0[0]),
    .io_readPorts_0_tag                      (io_fromRename_0_bits_psrc_0),
    .io_readPorts_0_valid                    (_rcTagTable_io_readPorts_0_valid),
    .io_readPorts_0_addr                     (_rcTagTable_io_readPorts_0_addr),
    .io_readPorts_1_ren
      (io_fromRename_0_valid & io_fromRename_0_bits_srcType_1[0]),
    .io_readPorts_1_tag                      (io_fromRename_0_bits_psrc_1),
    .io_readPorts_1_valid                    (_rcTagTable_io_readPorts_1_valid),
    .io_readPorts_1_addr                     (_rcTagTable_io_readPorts_1_addr),
    .io_readPorts_2_ren
      (io_fromRename_1_valid & io_fromRename_1_bits_srcType_0[0]),
    .io_readPorts_2_tag                      (io_fromRename_1_bits_psrc_0),
    .io_readPorts_2_valid                    (_rcTagTable_io_readPorts_2_valid),
    .io_readPorts_2_addr                     (_rcTagTable_io_readPorts_2_addr),
    .io_readPorts_3_ren
      (io_fromRename_1_valid & io_fromRename_1_bits_srcType_1[0]),
    .io_readPorts_3_tag                      (io_fromRename_1_bits_psrc_1),
    .io_readPorts_3_valid                    (_rcTagTable_io_readPorts_3_valid),
    .io_readPorts_3_addr                     (_rcTagTable_io_readPorts_3_addr),
    .io_readPorts_4_ren
      (io_fromRename_2_valid & io_fromRename_2_bits_srcType_0[0]),
    .io_readPorts_4_tag                      (io_fromRename_2_bits_psrc_0),
    .io_readPorts_4_valid                    (_rcTagTable_io_readPorts_4_valid),
    .io_readPorts_4_addr                     (_rcTagTable_io_readPorts_4_addr),
    .io_readPorts_5_ren
      (io_fromRename_2_valid & io_fromRename_2_bits_srcType_1[0]),
    .io_readPorts_5_tag                      (io_fromRename_2_bits_psrc_1),
    .io_readPorts_5_valid                    (_rcTagTable_io_readPorts_5_valid),
    .io_readPorts_5_addr                     (_rcTagTable_io_readPorts_5_addr),
    .io_readPorts_6_ren
      (io_fromRename_3_valid & io_fromRename_3_bits_srcType_0[0]),
    .io_readPorts_6_tag                      (io_fromRename_3_bits_psrc_0),
    .io_readPorts_6_valid                    (_rcTagTable_io_readPorts_6_valid),
    .io_readPorts_6_addr                     (_rcTagTable_io_readPorts_6_addr),
    .io_readPorts_7_ren
      (io_fromRename_3_valid & io_fromRename_3_bits_srcType_1[0]),
    .io_readPorts_7_tag                      (io_fromRename_3_bits_psrc_1),
    .io_readPorts_7_valid                    (_rcTagTable_io_readPorts_7_valid),
    .io_readPorts_7_addr                     (_rcTagTable_io_readPorts_7_addr),
    .io_readPorts_8_ren
      (io_fromRename_4_valid & io_fromRename_4_bits_srcType_0[0]),
    .io_readPorts_8_tag                      (io_fromRename_4_bits_psrc_0),
    .io_readPorts_8_valid                    (_rcTagTable_io_readPorts_8_valid),
    .io_readPorts_8_addr                     (_rcTagTable_io_readPorts_8_addr),
    .io_readPorts_9_ren
      (io_fromRename_4_valid & io_fromRename_4_bits_srcType_1[0]),
    .io_readPorts_9_tag                      (io_fromRename_4_bits_psrc_1),
    .io_readPorts_9_valid                    (_rcTagTable_io_readPorts_9_valid),
    .io_readPorts_9_addr                     (_rcTagTable_io_readPorts_9_addr),
    .io_readPorts_10_ren
      (io_fromRename_5_valid & io_fromRename_5_bits_srcType_0[0]),
    .io_readPorts_10_tag                     (io_fromRename_5_bits_psrc_0),
    .io_readPorts_10_valid                   (_rcTagTable_io_readPorts_10_valid),
    .io_readPorts_10_addr                    (_rcTagTable_io_readPorts_10_addr),
    .io_readPorts_11_ren
      (io_fromRename_5_valid & io_fromRename_5_bits_srcType_1[0]),
    .io_readPorts_11_tag                     (io_fromRename_5_bits_psrc_1),
    .io_readPorts_11_valid                   (_rcTagTable_io_readPorts_11_valid),
    .io_readPorts_11_addr                    (_rcTagTable_io_readPorts_11_addr),
    .io_wakeupFromIQ_6_valid                 (io_wakeUpAll_wakeUpMem_2_valid),
    .io_wakeupFromIQ_6_bits_rfWen            (io_wakeUpAll_wakeUpMem_2_bits_rfWen),
    .io_wakeupFromIQ_6_bits_pdest            (io_wakeUpAll_wakeUpMem_2_bits_pdest),
    .io_wakeupFromIQ_6_bits_rcDest           (io_wakeUpAll_wakeUpMem_2_bits_rcDest),
    .io_wakeupFromIQ_5_valid                 (io_wakeUpAll_wakeUpMem_1_valid),
    .io_wakeupFromIQ_5_bits_rfWen            (io_wakeUpAll_wakeUpMem_1_bits_rfWen),
    .io_wakeupFromIQ_5_bits_pdest            (io_wakeUpAll_wakeUpMem_1_bits_pdest),
    .io_wakeupFromIQ_5_bits_rcDest           (io_wakeUpAll_wakeUpMem_1_bits_rcDest),
    .io_wakeupFromIQ_4_valid                 (io_wakeUpAll_wakeUpMem_0_valid),
    .io_wakeupFromIQ_4_bits_rfWen            (io_wakeUpAll_wakeUpMem_0_bits_rfWen),
    .io_wakeupFromIQ_4_bits_pdest            (io_wakeUpAll_wakeUpMem_0_bits_pdest),
    .io_wakeupFromIQ_4_bits_rcDest           (io_wakeUpAll_wakeUpMem_0_bits_rcDest),
    .io_wakeupFromIQ_3_valid                 (io_wakeUpAll_wakeUpInt_3_valid),
    .io_wakeupFromIQ_3_bits_rfWen            (io_wakeUpAll_wakeUpInt_3_bits_rfWen),
    .io_wakeupFromIQ_3_bits_pdest            (io_wakeUpAll_wakeUpInt_3_bits_pdest),
    .io_wakeupFromIQ_3_bits_loadDependency_0
      (io_wakeUpAll_wakeUpInt_3_bits_loadDependency_0),
    .io_wakeupFromIQ_3_bits_loadDependency_1
      (io_wakeUpAll_wakeUpInt_3_bits_loadDependency_1),
    .io_wakeupFromIQ_3_bits_loadDependency_2
      (io_wakeUpAll_wakeUpInt_3_bits_loadDependency_2),
    .io_wakeupFromIQ_3_bits_rcDest           (io_wakeUpAll_wakeUpInt_3_bits_rcDest),
    .io_wakeupFromIQ_2_valid                 (io_wakeUpAll_wakeUpInt_2_valid),
    .io_wakeupFromIQ_2_bits_rfWen            (io_wakeUpAll_wakeUpInt_2_bits_rfWen),
    .io_wakeupFromIQ_2_bits_pdest            (io_wakeUpAll_wakeUpInt_2_bits_pdest),
    .io_wakeupFromIQ_2_bits_loadDependency_0
      (io_wakeUpAll_wakeUpInt_2_bits_loadDependency_0),
    .io_wakeupFromIQ_2_bits_loadDependency_1
      (io_wakeUpAll_wakeUpInt_2_bits_loadDependency_1),
    .io_wakeupFromIQ_2_bits_loadDependency_2
      (io_wakeUpAll_wakeUpInt_2_bits_loadDependency_2),
    .io_wakeupFromIQ_2_bits_rcDest           (io_wakeUpAll_wakeUpInt_2_bits_rcDest),
    .io_wakeupFromIQ_1_valid                 (io_wakeUpAll_wakeUpInt_1_valid),
    .io_wakeupFromIQ_1_bits_rfWen            (io_wakeUpAll_wakeUpInt_1_bits_rfWen),
    .io_wakeupFromIQ_1_bits_pdest            (io_wakeUpAll_wakeUpInt_1_bits_pdest),
    .io_wakeupFromIQ_1_bits_loadDependency_0
      (io_wakeUpAll_wakeUpInt_1_bits_loadDependency_0),
    .io_wakeupFromIQ_1_bits_loadDependency_1
      (io_wakeUpAll_wakeUpInt_1_bits_loadDependency_1),
    .io_wakeupFromIQ_1_bits_loadDependency_2
      (io_wakeUpAll_wakeUpInt_1_bits_loadDependency_2),
    .io_wakeupFromIQ_1_bits_is0Lat           (io_wakeUpAll_wakeUpInt_1_bits_is0Lat),
    .io_wakeupFromIQ_1_bits_rcDest           (io_wakeUpAll_wakeUpInt_1_bits_rcDest),
    .io_wakeupFromIQ_0_valid                 (io_wakeUpAll_wakeUpInt_0_valid),
    .io_wakeupFromIQ_0_bits_rfWen            (io_wakeUpAll_wakeUpInt_0_bits_rfWen),
    .io_wakeupFromIQ_0_bits_pdest            (io_wakeUpAll_wakeUpInt_0_bits_pdest),
    .io_wakeupFromIQ_0_bits_loadDependency_0
      (io_wakeUpAll_wakeUpInt_0_bits_loadDependency_0),
    .io_wakeupFromIQ_0_bits_loadDependency_1
      (io_wakeUpAll_wakeUpInt_0_bits_loadDependency_1),
    .io_wakeupFromIQ_0_bits_loadDependency_2
      (io_wakeUpAll_wakeUpInt_0_bits_loadDependency_2),
    .io_wakeupFromIQ_0_bits_is0Lat           (io_wakeUpAll_wakeUpInt_0_bits_is0Lat),
    .io_wakeupFromIQ_0_bits_rcDest           (io_wakeUpAll_wakeUpInt_0_bits_rcDest),
    .io_allocPregs_0_valid                   (allocPregsValid_0_0),
    .io_allocPregs_0_bits                    (io_fromRename_0_bits_pdest),
    .io_allocPregs_1_valid                   (allocPregsValid_0_1),
    .io_allocPregs_1_bits                    (io_fromRename_1_bits_pdest),
    .io_allocPregs_2_valid                   (allocPregsValid_0_2),
    .io_allocPregs_2_bits                    (io_fromRename_2_bits_pdest),
    .io_allocPregs_3_valid                   (allocPregsValid_0_3),
    .io_allocPregs_3_bits                    (io_fromRename_3_bits_pdest),
    .io_allocPregs_4_valid                   (allocPregsValid_0_4),
    .io_allocPregs_4_bits                    (io_fromRename_4_bits_pdest),
    .io_allocPregs_5_valid                   (allocPregsValid_0_5),
    .io_allocPregs_5_bits                    (io_fromRename_5_bits_pdest),
    .io_og0Cancel_0                          (io_og0Cancel_0),
    .io_og0Cancel_2                          (io_og0Cancel_2),
    .io_og0Cancel_4                          (io_og0Cancel_4),
    .io_og0Cancel_6                          (io_og0Cancel_6),
    .io_ldCancel_0_ld2Cancel                 (io_ldCancel_0_ld2Cancel),
    .io_ldCancel_1_ld2Cancel                 (io_ldCancel_1_ld2Cancel),
    .io_ldCancel_2_ld2Cancel                 (io_ldCancel_2_ld2Cancel)
  );

  BusyTable intBusyTable (
    .clock                                (clock),
    .reset                                (reset),
    .io_allocPregs_0_valid                (allocPregsValid_0_0),
    .io_allocPregs_0_bits                 (io_fromRename_0_bits_pdest),
    .io_allocPregs_1_valid                (allocPregsValid_0_1),
    .io_allocPregs_1_bits                 (io_fromRename_1_bits_pdest),
    .io_allocPregs_2_valid                (allocPregsValid_0_2),
    .io_allocPregs_2_bits                 (io_fromRename_2_bits_pdest),
    .io_allocPregs_3_valid                (allocPregsValid_0_3),
    .io_allocPregs_3_bits                 (io_fromRename_3_bits_pdest),
    .io_allocPregs_4_valid                (allocPregsValid_0_4),
    .io_allocPregs_4_bits                 (io_fromRename_4_bits_pdest),
    .io_allocPregs_5_valid                (allocPregsValid_0_5),
    .io_allocPregs_5_bits                 (io_fromRename_5_bits_pdest),
    .io_wbPregs_0_valid                   (io_wbPregsInt_0_valid),
    .io_wbPregs_0_bits                    (io_wbPregsInt_0_bits),
    .io_wbPregs_1_valid                   (io_wbPregsInt_1_valid),
    .io_wbPregs_1_bits                    (io_wbPregsInt_1_bits),
    .io_wbPregs_2_valid                   (io_wbPregsInt_2_valid),
    .io_wbPregs_2_bits                    (io_wbPregsInt_2_bits),
    .io_wbPregs_3_valid                   (io_wbPregsInt_3_valid),
    .io_wbPregs_3_bits                    (io_wbPregsInt_3_bits),
    .io_wbPregs_4_valid                   (io_wbPregsInt_4_valid),
    .io_wbPregs_4_bits                    (io_wbPregsInt_4_bits),
    .io_wbPregs_5_valid                   (io_wbPregsInt_5_valid),
    .io_wbPregs_5_bits                    (io_wbPregsInt_5_bits),
    .io_wbPregs_6_valid                   (io_wbPregsInt_6_valid),
    .io_wbPregs_6_bits                    (io_wbPregsInt_6_bits),
    .io_wbPregs_7_valid                   (io_wbPregsInt_7_valid),
    .io_wbPregs_7_bits                    (io_wbPregsInt_7_bits),
    .io_wakeUpInt_3_valid                 (io_wakeUpAll_wakeUpInt_3_valid),
    .io_wakeUpInt_3_bits_rfWen            (io_wakeUpAll_wakeUpInt_3_bits_rfWen),
    .io_wakeUpInt_3_bits_pdest            (io_wakeUpAll_wakeUpInt_3_bits_pdest),
    .io_wakeUpInt_3_bits_loadDependency_0
      (io_wakeUpAll_wakeUpInt_3_bits_loadDependency_0),
    .io_wakeUpInt_3_bits_loadDependency_1
      (io_wakeUpAll_wakeUpInt_3_bits_loadDependency_1),
    .io_wakeUpInt_3_bits_loadDependency_2
      (io_wakeUpAll_wakeUpInt_3_bits_loadDependency_2),
    .io_wakeUpInt_2_valid                 (io_wakeUpAll_wakeUpInt_2_valid),
    .io_wakeUpInt_2_bits_rfWen            (io_wakeUpAll_wakeUpInt_2_bits_rfWen),
    .io_wakeUpInt_2_bits_pdest            (io_wakeUpAll_wakeUpInt_2_bits_pdest),
    .io_wakeUpInt_2_bits_loadDependency_0
      (io_wakeUpAll_wakeUpInt_2_bits_loadDependency_0),
    .io_wakeUpInt_2_bits_loadDependency_1
      (io_wakeUpAll_wakeUpInt_2_bits_loadDependency_1),
    .io_wakeUpInt_2_bits_loadDependency_2
      (io_wakeUpAll_wakeUpInt_2_bits_loadDependency_2),
    .io_wakeUpInt_1_valid                 (io_wakeUpAll_wakeUpInt_1_valid),
    .io_wakeUpInt_1_bits_rfWen            (io_wakeUpAll_wakeUpInt_1_bits_rfWen),
    .io_wakeUpInt_1_bits_pdest            (io_wakeUpAll_wakeUpInt_1_bits_pdest),
    .io_wakeUpInt_1_bits_loadDependency_0
      (io_wakeUpAll_wakeUpInt_1_bits_loadDependency_0),
    .io_wakeUpInt_1_bits_loadDependency_1
      (io_wakeUpAll_wakeUpInt_1_bits_loadDependency_1),
    .io_wakeUpInt_1_bits_loadDependency_2
      (io_wakeUpAll_wakeUpInt_1_bits_loadDependency_2),
    .io_wakeUpInt_1_bits_is0Lat           (io_wakeUpAll_wakeUpInt_1_bits_is0Lat),
    .io_wakeUpInt_0_valid                 (io_wakeUpAll_wakeUpInt_0_valid),
    .io_wakeUpInt_0_bits_rfWen            (io_wakeUpAll_wakeUpInt_0_bits_rfWen),
    .io_wakeUpInt_0_bits_pdest            (io_wakeUpAll_wakeUpInt_0_bits_pdest),
    .io_wakeUpInt_0_bits_loadDependency_0
      (io_wakeUpAll_wakeUpInt_0_bits_loadDependency_0),
    .io_wakeUpInt_0_bits_loadDependency_1
      (io_wakeUpAll_wakeUpInt_0_bits_loadDependency_1),
    .io_wakeUpInt_0_bits_loadDependency_2
      (io_wakeUpAll_wakeUpInt_0_bits_loadDependency_2),
    .io_wakeUpInt_0_bits_is0Lat           (io_wakeUpAll_wakeUpInt_0_bits_is0Lat),
    .io_wakeUpMem_2_valid                 (io_wakeUpAll_wakeUpMem_2_valid),
    .io_wakeUpMem_2_bits_rfWen            (io_wakeUpAll_wakeUpMem_2_bits_rfWen),
    .io_wakeUpMem_2_bits_pdest            (io_wakeUpAll_wakeUpMem_2_bits_pdest),
    .io_wakeUpMem_1_valid                 (io_wakeUpAll_wakeUpMem_1_valid),
    .io_wakeUpMem_1_bits_rfWen            (io_wakeUpAll_wakeUpMem_1_bits_rfWen),
    .io_wakeUpMem_1_bits_pdest            (io_wakeUpAll_wakeUpMem_1_bits_pdest),
    .io_wakeUpMem_0_valid                 (io_wakeUpAll_wakeUpMem_0_valid),
    .io_wakeUpMem_0_bits_rfWen            (io_wakeUpAll_wakeUpMem_0_bits_rfWen),
    .io_wakeUpMem_0_bits_pdest            (io_wakeUpAll_wakeUpMem_0_bits_pdest),
    .io_og0Cancel_0                       (io_og0Cancel_0),
    .io_og0Cancel_2                       (io_og0Cancel_2),
    .io_og0Cancel_4                       (io_og0Cancel_4),
    .io_og0Cancel_6                       (io_og0Cancel_6),
    .io_ldCancel_0_ld2Cancel              (io_ldCancel_0_ld2Cancel),
    .io_ldCancel_1_ld2Cancel              (io_ldCancel_1_ld2Cancel),
    .io_ldCancel_2_ld2Cancel              (io_ldCancel_2_ld2Cancel),
    .io_read_0_req                        (io_fromRename_0_bits_psrc_0),
    .io_read_0_resp                       (_intBusyTable_io_read_0_resp),
    .io_read_0_loadDependency_0           (_intBusyTable_io_read_0_loadDependency_0),
    .io_read_0_loadDependency_1           (_intBusyTable_io_read_0_loadDependency_1),
    .io_read_0_loadDependency_2           (_intBusyTable_io_read_0_loadDependency_2),
    .io_read_1_req                        (io_fromRename_0_bits_psrc_1),
    .io_read_1_resp                       (_intBusyTable_io_read_1_resp),
    .io_read_1_loadDependency_0           (_intBusyTable_io_read_1_loadDependency_0),
    .io_read_1_loadDependency_1           (_intBusyTable_io_read_1_loadDependency_1),
    .io_read_1_loadDependency_2           (_intBusyTable_io_read_1_loadDependency_2),
    .io_read_2_req                        (io_fromRename_1_bits_psrc_0),
    .io_read_2_resp                       (_intBusyTable_io_read_2_resp),
    .io_read_2_loadDependency_0           (_intBusyTable_io_read_2_loadDependency_0),
    .io_read_2_loadDependency_1           (_intBusyTable_io_read_2_loadDependency_1),
    .io_read_2_loadDependency_2           (_intBusyTable_io_read_2_loadDependency_2),
    .io_read_3_req                        (io_fromRename_1_bits_psrc_1),
    .io_read_3_resp                       (_intBusyTable_io_read_3_resp),
    .io_read_3_loadDependency_0           (_intBusyTable_io_read_3_loadDependency_0),
    .io_read_3_loadDependency_1           (_intBusyTable_io_read_3_loadDependency_1),
    .io_read_3_loadDependency_2           (_intBusyTable_io_read_3_loadDependency_2),
    .io_read_4_req                        (io_fromRename_2_bits_psrc_0),
    .io_read_4_resp                       (_intBusyTable_io_read_4_resp),
    .io_read_4_loadDependency_0           (_intBusyTable_io_read_4_loadDependency_0),
    .io_read_4_loadDependency_1           (_intBusyTable_io_read_4_loadDependency_1),
    .io_read_4_loadDependency_2           (_intBusyTable_io_read_4_loadDependency_2),
    .io_read_5_req                        (io_fromRename_2_bits_psrc_1),
    .io_read_5_resp                       (_intBusyTable_io_read_5_resp),
    .io_read_5_loadDependency_0           (_intBusyTable_io_read_5_loadDependency_0),
    .io_read_5_loadDependency_1           (_intBusyTable_io_read_5_loadDependency_1),
    .io_read_5_loadDependency_2           (_intBusyTable_io_read_5_loadDependency_2),
    .io_read_6_req                        (io_fromRename_3_bits_psrc_0),
    .io_read_6_resp                       (_intBusyTable_io_read_6_resp),
    .io_read_6_loadDependency_0           (_intBusyTable_io_read_6_loadDependency_0),
    .io_read_6_loadDependency_1           (_intBusyTable_io_read_6_loadDependency_1),
    .io_read_6_loadDependency_2           (_intBusyTable_io_read_6_loadDependency_2),
    .io_read_7_req                        (io_fromRename_3_bits_psrc_1),
    .io_read_7_resp                       (_intBusyTable_io_read_7_resp),
    .io_read_7_loadDependency_0           (_intBusyTable_io_read_7_loadDependency_0),
    .io_read_7_loadDependency_1           (_intBusyTable_io_read_7_loadDependency_1),
    .io_read_7_loadDependency_2           (_intBusyTable_io_read_7_loadDependency_2),
    .io_read_8_req                        (io_fromRename_4_bits_psrc_0),
    .io_read_8_resp                       (_intBusyTable_io_read_8_resp),
    .io_read_8_loadDependency_0           (_intBusyTable_io_read_8_loadDependency_0),
    .io_read_8_loadDependency_1           (_intBusyTable_io_read_8_loadDependency_1),
    .io_read_8_loadDependency_2           (_intBusyTable_io_read_8_loadDependency_2),
    .io_read_9_req                        (io_fromRename_4_bits_psrc_1),
    .io_read_9_resp                       (_intBusyTable_io_read_9_resp),
    .io_read_9_loadDependency_0           (_intBusyTable_io_read_9_loadDependency_0),
    .io_read_9_loadDependency_1           (_intBusyTable_io_read_9_loadDependency_1),
    .io_read_9_loadDependency_2           (_intBusyTable_io_read_9_loadDependency_2),
    .io_read_10_req                       (io_fromRename_5_bits_psrc_0),
    .io_read_10_resp                      (_intBusyTable_io_read_10_resp),
    .io_read_10_loadDependency_0          (_intBusyTable_io_read_10_loadDependency_0),
    .io_read_10_loadDependency_1          (_intBusyTable_io_read_10_loadDependency_1),
    .io_read_10_loadDependency_2          (_intBusyTable_io_read_10_loadDependency_2),
    .io_read_11_req                       (io_fromRename_5_bits_psrc_1),
    .io_read_11_resp                      (_intBusyTable_io_read_11_resp),
    .io_read_11_loadDependency_0          (_intBusyTable_io_read_11_loadDependency_0),
    .io_read_11_loadDependency_1          (_intBusyTable_io_read_11_loadDependency_1),
    .io_read_11_loadDependency_2          (_intBusyTable_io_read_11_loadDependency_2)
  );

  BusyTable_1 fpBusyTable (
    .clock                     (clock),
    .reset                     (reset),
    .io_allocPregs_0_valid     (io_fromRename_0_valid & io_fromRename_0_bits_fpWen),
    .io_allocPregs_0_bits      (io_fromRename_0_bits_pdest),
    .io_allocPregs_1_valid     (io_fromRename_1_valid & io_fromRename_1_bits_fpWen),
    .io_allocPregs_1_bits      (io_fromRename_1_bits_pdest),
    .io_allocPregs_2_valid     (io_fromRename_2_valid & io_fromRename_2_bits_fpWen),
    .io_allocPregs_2_bits      (io_fromRename_2_bits_pdest),
    .io_allocPregs_3_valid     (io_fromRename_3_valid & io_fromRename_3_bits_fpWen),
    .io_allocPregs_3_bits      (io_fromRename_3_bits_pdest),
    .io_allocPregs_4_valid     (io_fromRename_4_valid & io_fromRename_4_bits_fpWen),
    .io_allocPregs_4_bits      (io_fromRename_4_bits_pdest),
    .io_allocPregs_5_valid     (io_fromRename_5_valid & io_fromRename_5_bits_fpWen),
    .io_allocPregs_5_bits      (io_fromRename_5_bits_pdest),
    .io_wbPregs_0_valid        (io_wbPregsFp_0_valid),
    .io_wbPregs_0_bits         (io_wbPregsFp_0_bits),
    .io_wbPregs_1_valid        (io_wbPregsFp_1_valid),
    .io_wbPregs_1_bits         (io_wbPregsFp_1_bits),
    .io_wbPregs_2_valid        (io_wbPregsFp_2_valid),
    .io_wbPregs_2_bits         (io_wbPregsFp_2_bits),
    .io_wbPregs_3_valid        (io_wbPregsFp_3_valid),
    .io_wbPregs_3_bits         (io_wbPregsFp_3_bits),
    .io_wbPregs_4_valid        (io_wbPregsFp_4_valid),
    .io_wbPregs_4_bits         (io_wbPregsFp_4_bits),
    .io_wbPregs_5_valid        (io_wbPregsFp_5_valid),
    .io_wbPregs_5_bits         (io_wbPregsFp_5_bits),
    .io_wakeUpFp_2_valid       (io_wakeUpAll_wakeUpFp_2_valid),
    .io_wakeUpFp_2_bits_fpWen  (io_wakeUpAll_wakeUpFp_2_bits_fpWen),
    .io_wakeUpFp_2_bits_pdest  (io_wakeUpAll_wakeUpFp_2_bits_pdest),
    .io_wakeUpFp_1_valid       (io_wakeUpAll_wakeUpFp_1_valid),
    .io_wakeUpFp_1_bits_fpWen  (io_wakeUpAll_wakeUpFp_1_bits_fpWen),
    .io_wakeUpFp_1_bits_pdest  (io_wakeUpAll_wakeUpFp_1_bits_pdest),
    .io_wakeUpFp_0_valid       (io_wakeUpAll_wakeUpFp_0_valid),
    .io_wakeUpFp_0_bits_fpWen  (io_wakeUpAll_wakeUpFp_0_bits_fpWen),
    .io_wakeUpFp_0_bits_pdest  (io_wakeUpAll_wakeUpFp_0_bits_pdest),
    .io_wakeUpFp_0_bits_is0Lat (io_wakeUpAll_wakeUpFp_0_bits_is0Lat),
    .io_og0Cancel_8            (io_og0Cancel_8),
    .io_read_0_req             (io_fromRename_0_bits_psrc_0),
    .io_read_0_resp            (_fpBusyTable_io_read_0_resp),
    .io_read_1_req             (io_fromRename_0_bits_psrc_1),
    .io_read_1_resp            (_fpBusyTable_io_read_1_resp),
    .io_read_2_req             (io_fromRename_0_bits_psrc_2),
    .io_read_2_resp            (_fpBusyTable_io_read_2_resp),
    .io_read_3_req             (io_fromRename_1_bits_psrc_0),
    .io_read_3_resp            (_fpBusyTable_io_read_3_resp),
    .io_read_4_req             (io_fromRename_1_bits_psrc_1),
    .io_read_4_resp            (_fpBusyTable_io_read_4_resp),
    .io_read_5_req             (io_fromRename_1_bits_psrc_2),
    .io_read_5_resp            (_fpBusyTable_io_read_5_resp),
    .io_read_6_req             (io_fromRename_2_bits_psrc_0),
    .io_read_6_resp            (_fpBusyTable_io_read_6_resp),
    .io_read_7_req             (io_fromRename_2_bits_psrc_1),
    .io_read_7_resp            (_fpBusyTable_io_read_7_resp),
    .io_read_8_req             (io_fromRename_2_bits_psrc_2),
    .io_read_8_resp            (_fpBusyTable_io_read_8_resp),
    .io_read_9_req             (io_fromRename_3_bits_psrc_0),
    .io_read_9_resp            (_fpBusyTable_io_read_9_resp),
    .io_read_10_req            (io_fromRename_3_bits_psrc_1),
    .io_read_10_resp           (_fpBusyTable_io_read_10_resp),
    .io_read_11_req            (io_fromRename_3_bits_psrc_2),
    .io_read_11_resp           (_fpBusyTable_io_read_11_resp),
    .io_read_12_req            (io_fromRename_4_bits_psrc_0),
    .io_read_12_resp           (_fpBusyTable_io_read_12_resp),
    .io_read_13_req            (io_fromRename_4_bits_psrc_1),
    .io_read_13_resp           (_fpBusyTable_io_read_13_resp),
    .io_read_14_req            (io_fromRename_4_bits_psrc_2),
    .io_read_14_resp           (_fpBusyTable_io_read_14_resp),
    .io_read_15_req            (io_fromRename_5_bits_psrc_0),
    .io_read_15_resp           (_fpBusyTable_io_read_15_resp),
    .io_read_16_req            (io_fromRename_5_bits_psrc_1),
    .io_read_16_resp           (_fpBusyTable_io_read_16_resp),
    .io_read_17_req            (io_fromRename_5_bits_psrc_2),
    .io_read_17_resp           (_fpBusyTable_io_read_17_resp)
  );

  BusyTable_2 vecBusyTable (
    .clock                     (clock),
    .reset                     (reset),
    .io_allocPregs_0_valid     (io_fromRename_0_valid & io_fromRename_0_bits_vecWen),
    .io_allocPregs_0_bits      (io_fromRename_0_bits_pdest),
    .io_allocPregs_1_valid     (io_fromRename_1_valid & io_fromRename_1_bits_vecWen),
    .io_allocPregs_1_bits      (io_fromRename_1_bits_pdest),
    .io_allocPregs_2_valid     (io_fromRename_2_valid & io_fromRename_2_bits_vecWen),
    .io_allocPregs_2_bits      (io_fromRename_2_bits_pdest),
    .io_allocPregs_3_valid     (io_fromRename_3_valid & io_fromRename_3_bits_vecWen),
    .io_allocPregs_3_bits      (io_fromRename_3_bits_pdest),
    .io_allocPregs_4_valid     (io_fromRename_4_valid & io_fromRename_4_bits_vecWen),
    .io_allocPregs_4_bits      (io_fromRename_4_bits_pdest),
    .io_allocPregs_5_valid     (io_fromRename_5_valid & io_fromRename_5_bits_vecWen),
    .io_allocPregs_5_bits      (io_fromRename_5_bits_pdest),
    .io_wbPregs_0_valid        (io_wbPregsVec_0_valid),
    .io_wbPregs_0_bits         (io_wbPregsVec_0_bits),
    .io_wbPregs_1_valid        (io_wbPregsVec_1_valid),
    .io_wbPregs_1_bits         (io_wbPregsVec_1_bits),
    .io_wbPregs_2_valid        (io_wbPregsVec_2_valid),
    .io_wbPregs_2_bits         (io_wbPregsVec_2_bits),
    .io_wbPregs_3_valid        (io_wbPregsVec_3_valid),
    .io_wbPregs_3_bits         (io_wbPregsVec_3_bits),
    .io_wbPregs_4_valid        (io_wbPregsVec_4_valid),
    .io_wbPregs_4_bits         (io_wbPregsVec_4_bits),
    .io_wbPregs_5_valid        (io_wbPregsVec_5_valid),
    .io_wbPregs_5_bits         (io_wbPregsVec_5_bits),
    .io_wakeUpFp_0_valid       (io_wakeUpAll_wakeUpFp_0_valid),
    .io_wakeUpFp_0_bits_vecWen (io_wakeUpAll_wakeUpFp_0_bits_vecWen),
    .io_wakeUpFp_0_bits_pdest  (io_wakeUpAll_wakeUpFp_0_bits_pdest),
    .io_wakeUpFp_0_bits_is0Lat (io_wakeUpAll_wakeUpFp_0_bits_is0Lat),
    .io_og0Cancel_8            (io_og0Cancel_8),
    .io_read_0_req             (io_fromRename_0_bits_psrc_0),
    .io_read_0_resp            (_vecBusyTable_io_read_0_resp),
    .io_read_1_req             (io_fromRename_0_bits_psrc_1),
    .io_read_1_resp            (_vecBusyTable_io_read_1_resp),
    .io_read_2_req             (io_fromRename_0_bits_psrc_2),
    .io_read_2_resp            (_vecBusyTable_io_read_2_resp),
    .io_read_3_req             (io_fromRename_1_bits_psrc_0),
    .io_read_3_resp            (_vecBusyTable_io_read_3_resp),
    .io_read_4_req             (io_fromRename_1_bits_psrc_1),
    .io_read_4_resp            (_vecBusyTable_io_read_4_resp),
    .io_read_5_req             (io_fromRename_1_bits_psrc_2),
    .io_read_5_resp            (_vecBusyTable_io_read_5_resp),
    .io_read_6_req             (io_fromRename_2_bits_psrc_0),
    .io_read_6_resp            (_vecBusyTable_io_read_6_resp),
    .io_read_7_req             (io_fromRename_2_bits_psrc_1),
    .io_read_7_resp            (_vecBusyTable_io_read_7_resp),
    .io_read_8_req             (io_fromRename_2_bits_psrc_2),
    .io_read_8_resp            (_vecBusyTable_io_read_8_resp),
    .io_read_9_req             (io_fromRename_3_bits_psrc_0),
    .io_read_9_resp            (_vecBusyTable_io_read_9_resp),
    .io_read_10_req            (io_fromRename_3_bits_psrc_1),
    .io_read_10_resp           (_vecBusyTable_io_read_10_resp),
    .io_read_11_req            (io_fromRename_3_bits_psrc_2),
    .io_read_11_resp           (_vecBusyTable_io_read_11_resp),
    .io_read_12_req            (io_fromRename_4_bits_psrc_0),
    .io_read_12_resp           (_vecBusyTable_io_read_12_resp),
    .io_read_13_req            (io_fromRename_4_bits_psrc_1),
    .io_read_13_resp           (_vecBusyTable_io_read_13_resp),
    .io_read_14_req            (io_fromRename_4_bits_psrc_2),
    .io_read_14_resp           (_vecBusyTable_io_read_14_resp),
    .io_read_15_req            (io_fromRename_5_bits_psrc_0),
    .io_read_15_resp           (_vecBusyTable_io_read_15_resp),
    .io_read_16_req            (io_fromRename_5_bits_psrc_1),
    .io_read_16_resp           (_vecBusyTable_io_read_16_resp),
    .io_read_17_req            (io_fromRename_5_bits_psrc_2),
    .io_read_17_resp           (_vecBusyTable_io_read_17_resp)
  );

  BusyTable_3 v0BusyTable (
    .clock                     (clock),
    .reset                     (reset),
    .io_allocPregs_0_valid     (io_fromRename_0_valid & io_fromRename_0_bits_v0Wen),
    .io_allocPregs_0_bits      (io_fromRename_0_bits_pdest),
    .io_allocPregs_1_valid     (io_fromRename_1_valid & io_fromRename_1_bits_v0Wen),
    .io_allocPregs_1_bits      (io_fromRename_1_bits_pdest),
    .io_allocPregs_2_valid     (io_fromRename_2_valid & io_fromRename_2_bits_v0Wen),
    .io_allocPregs_2_bits      (io_fromRename_2_bits_pdest),
    .io_allocPregs_3_valid     (io_fromRename_3_valid & io_fromRename_3_bits_v0Wen),
    .io_allocPregs_3_bits      (io_fromRename_3_bits_pdest),
    .io_allocPregs_4_valid     (io_fromRename_4_valid & io_fromRename_4_bits_v0Wen),
    .io_allocPregs_4_bits      (io_fromRename_4_bits_pdest),
    .io_allocPregs_5_valid     (io_fromRename_5_valid & io_fromRename_5_bits_v0Wen),
    .io_allocPregs_5_bits      (io_fromRename_5_bits_pdest),
    .io_wbPregs_0_valid        (io_wbPregsV0_0_valid),
    .io_wbPregs_0_bits         (io_wbPregsV0_0_bits),
    .io_wbPregs_1_valid        (io_wbPregsV0_1_valid),
    .io_wbPregs_1_bits         (io_wbPregsV0_1_bits),
    .io_wbPregs_2_valid        (io_wbPregsV0_2_valid),
    .io_wbPregs_2_bits         (io_wbPregsV0_2_bits),
    .io_wbPregs_3_valid        (io_wbPregsV0_3_valid),
    .io_wbPregs_3_bits         (io_wbPregsV0_3_bits),
    .io_wbPregs_4_valid        (io_wbPregsV0_4_valid),
    .io_wbPregs_4_bits         (io_wbPregsV0_4_bits),
    .io_wbPregs_5_valid        (io_wbPregsV0_5_valid),
    .io_wbPregs_5_bits         (io_wbPregsV0_5_bits),
    .io_wakeUpFp_0_valid       (io_wakeUpAll_wakeUpFp_0_valid),
    .io_wakeUpFp_0_bits_v0Wen  (io_wakeUpAll_wakeUpFp_0_bits_v0Wen),
    .io_wakeUpFp_0_bits_pdest  (io_wakeUpAll_wakeUpFp_0_bits_pdest),
    .io_wakeUpFp_0_bits_is0Lat (io_wakeUpAll_wakeUpFp_0_bits_is0Lat),
    .io_og0Cancel_8            (io_og0Cancel_8),
    .io_read_0_req             (io_fromRename_0_bits_psrc_3),
    .io_read_0_resp            (_v0BusyTable_io_read_0_resp),
    .io_read_1_req             (io_fromRename_1_bits_psrc_3),
    .io_read_1_resp            (_v0BusyTable_io_read_1_resp),
    .io_read_2_req             (io_fromRename_2_bits_psrc_3),
    .io_read_2_resp            (_v0BusyTable_io_read_2_resp),
    .io_read_3_req             (io_fromRename_3_bits_psrc_3),
    .io_read_3_resp            (_v0BusyTable_io_read_3_resp),
    .io_read_4_req             (io_fromRename_4_bits_psrc_3),
    .io_read_4_resp            (_v0BusyTable_io_read_4_resp),
    .io_read_5_req             (io_fromRename_5_bits_psrc_3),
    .io_read_5_resp            (_v0BusyTable_io_read_5_resp)
  );

  VlBusyTable vlBusyTable (
    .clock                                     (clock),
    .reset                                     (reset),
    .io_allocPregs_0_valid
      (io_fromRename_0_valid & io_fromRename_0_bits_vlWen),
    .io_allocPregs_0_bits                      (io_fromRename_0_bits_pdest),
    .io_allocPregs_1_valid
      (io_fromRename_1_valid & io_fromRename_1_bits_vlWen),
    .io_allocPregs_1_bits                      (io_fromRename_1_bits_pdest),
    .io_allocPregs_2_valid
      (io_fromRename_2_valid & io_fromRename_2_bits_vlWen),
    .io_allocPregs_2_bits                      (io_fromRename_2_bits_pdest),
    .io_allocPregs_3_valid
      (io_fromRename_3_valid & io_fromRename_3_bits_vlWen),
    .io_allocPregs_3_bits                      (io_fromRename_3_bits_pdest),
    .io_allocPregs_4_valid
      (io_fromRename_4_valid & io_fromRename_4_bits_vlWen),
    .io_allocPregs_4_bits                      (io_fromRename_4_bits_pdest),
    .io_allocPregs_5_valid
      (io_fromRename_5_valid & io_fromRename_5_bits_vlWen),
    .io_allocPregs_5_bits                      (io_fromRename_5_bits_pdest),
    .io_wbPregs_0_valid                        (io_wbPregsVl_0_valid),
    .io_wbPregs_0_bits                         (io_wbPregsVl_0_bits),
    .io_wbPregs_1_valid                        (io_wbPregsVl_1_valid),
    .io_wbPregs_1_bits                         (io_wbPregsVl_1_bits),
    .io_wbPregs_2_valid                        (io_wbPregsVl_2_valid),
    .io_wbPregs_2_bits                         (io_wbPregsVl_2_bits),
    .io_wbPregs_3_valid                        (io_wbPregsVl_3_valid),
    .io_wbPregs_3_bits                         (io_wbPregsVl_3_bits),
    .io_read_0_req                             (io_fromRename_0_bits_psrc_4),
    .io_read_0_resp                            (_vlBusyTable_io_read_0_resp),
    .io_read_1_req                             (io_fromRename_1_bits_psrc_4),
    .io_read_1_resp                            (_vlBusyTable_io_read_1_resp),
    .io_read_2_req                             (io_fromRename_2_bits_psrc_4),
    .io_read_2_resp                            (_vlBusyTable_io_read_2_resp),
    .io_read_3_req                             (io_fromRename_3_bits_psrc_4),
    .io_read_3_resp                            (_vlBusyTable_io_read_3_resp),
    .io_read_4_req                             (io_fromRename_4_bits_psrc_4),
    .io_read_4_resp                            (_vlBusyTable_io_read_4_resp),
    .io_read_5_req                             (io_fromRename_5_bits_psrc_4),
    .io_read_5_resp                            (_vlBusyTable_io_read_5_resp),
    .io_vl_Wb_vlWriteBackInfo_vlFromIntIsZero  (io_vlWriteBackInfo_vlFromIntIsZero),
    .io_vl_Wb_vlWriteBackInfo_vlFromIntIsVlmax (io_vlWriteBackInfo_vlFromIntIsVlmax),
    .io_vl_Wb_vlWriteBackInfo_vlFromVfIsZero   (io_vlWriteBackInfo_vlFromVfIsZero),
    .io_vl_Wb_vlWriteBackInfo_vlFromVfIsVlmax  (io_vlWriteBackInfo_vlFromVfIsVlmax),
    .io_vl_read_vlReadInfo_0_is_nonzero
      (_vlBusyTable_io_vl_read_vlReadInfo_0_is_nonzero),
    .io_vl_read_vlReadInfo_0_is_vlmax
      (_vlBusyTable_io_vl_read_vlReadInfo_0_is_vlmax),
    .io_vl_read_vlReadInfo_1_is_nonzero
      (_vlBusyTable_io_vl_read_vlReadInfo_1_is_nonzero),
    .io_vl_read_vlReadInfo_1_is_vlmax
      (_vlBusyTable_io_vl_read_vlReadInfo_1_is_vlmax),
    .io_vl_read_vlReadInfo_2_is_nonzero
      (_vlBusyTable_io_vl_read_vlReadInfo_2_is_nonzero),
    .io_vl_read_vlReadInfo_2_is_vlmax
      (_vlBusyTable_io_vl_read_vlReadInfo_2_is_vlmax),
    .io_vl_read_vlReadInfo_3_is_nonzero
      (_vlBusyTable_io_vl_read_vlReadInfo_3_is_nonzero),
    .io_vl_read_vlReadInfo_3_is_vlmax
      (_vlBusyTable_io_vl_read_vlReadInfo_3_is_vlmax),
    .io_vl_read_vlReadInfo_4_is_nonzero
      (_vlBusyTable_io_vl_read_vlReadInfo_4_is_nonzero),
    .io_vl_read_vlReadInfo_4_is_vlmax
      (_vlBusyTable_io_vl_read_vlReadInfo_4_is_vlmax),
    .io_vl_read_vlReadInfo_5_is_nonzero
      (_vlBusyTable_io_vl_read_vlReadInfo_5_is_nonzero),
    .io_vl_read_vlReadInfo_5_is_vlmax
      (_vlBusyTable_io_vl_read_vlReadInfo_5_is_vlmax)
  );

  LsqEnqCtrl lsqEnqCtrl (
    .clock                                     (clock),
    .reset                                     (reset),
    .io_redirect_valid                         (lsqEnqCtrl_io_redirect_REG_valid),
    .io_enq_canAccept                          (_lsqEnqCtrl_io_enq_canAccept),
    .io_enq_needAlloc_0
      (firedVec[0] ? (isVStoreUop[0] ? 2'h2 : {1'h0, isVLoadUop[0]}) : 2'h0),
    .io_enq_needAlloc_1
      (firedVec[1] ? (isVStoreUop[1] ? 2'h2 : {1'h0, isVLoadUop[1]}) : 2'h0),
    .io_enq_needAlloc_2
      (firedVec[2] ? (isVStoreUop[2] ? 2'h2 : {1'h0, isVLoadUop[2]}) : 2'h0),
    .io_enq_needAlloc_3
      (firedVec[3] ? (isVStoreUop[3] ? 2'h2 : {1'h0, isVLoadUop[3]}) : 2'h0),
    .io_enq_needAlloc_4
      (firedVec[4] ? (isVStoreUop[4] ? 2'h2 : {1'h0, isVLoadUop[4]}) : 2'h0),
    .io_enq_needAlloc_5
      (firedVec[5] ? (isVStoreUop[5] ? 2'h2 : {1'h0, isVLoadUop[5]}) : 2'h0),
    .io_enq_req_0_valid
      (firedVec[0] & ~(io_fromRename_0_valid & io_fromRename_0_bits_fuType[17])
       & ~((io_fromRename_0_bits_fuType[33] | io_fromRename_0_bits_fuType[34])
           & io_fromRename_0_valid)
       & ~(io_fromRename_0_bits_vpu_isVleff & io_fromRename_0_bits_lastUop)),
    .io_enq_req_0_bits_exceptionVec_0          (io_fromRename_0_bits_exceptionVec_0),
    .io_enq_req_0_bits_exceptionVec_1          (io_fromRename_0_bits_exceptionVec_1),
    .io_enq_req_0_bits_exceptionVec_2          (io_fromRename_0_bits_exceptionVec_2),
    .io_enq_req_0_bits_exceptionVec_3          (io_fromRename_0_bits_exceptionVec_3),
    .io_enq_req_0_bits_exceptionVec_4          (io_fromRename_0_bits_exceptionVec_4),
    .io_enq_req_0_bits_exceptionVec_5          (io_fromRename_0_bits_exceptionVec_5),
    .io_enq_req_0_bits_exceptionVec_6          (io_fromRename_0_bits_exceptionVec_6),
    .io_enq_req_0_bits_exceptionVec_7          (io_fromRename_0_bits_exceptionVec_7),
    .io_enq_req_0_bits_exceptionVec_8          (io_fromRename_0_bits_exceptionVec_8),
    .io_enq_req_0_bits_exceptionVec_9          (io_fromRename_0_bits_exceptionVec_9),
    .io_enq_req_0_bits_exceptionVec_10         (io_fromRename_0_bits_exceptionVec_10),
    .io_enq_req_0_bits_exceptionVec_11         (io_fromRename_0_bits_exceptionVec_11),
    .io_enq_req_0_bits_exceptionVec_12         (io_fromRename_0_bits_exceptionVec_12),
    .io_enq_req_0_bits_exceptionVec_13         (io_fromRename_0_bits_exceptionVec_13),
    .io_enq_req_0_bits_exceptionVec_14         (io_fromRename_0_bits_exceptionVec_14),
    .io_enq_req_0_bits_exceptionVec_15         (io_fromRename_0_bits_exceptionVec_15),
    .io_enq_req_0_bits_exceptionVec_16         (io_fromRename_0_bits_exceptionVec_16),
    .io_enq_req_0_bits_exceptionVec_17         (io_fromRename_0_bits_exceptionVec_17),
    .io_enq_req_0_bits_exceptionVec_18         (io_fromRename_0_bits_exceptionVec_18),
    .io_enq_req_0_bits_exceptionVec_19         (io_fromRename_0_bits_exceptionVec_19),
    .io_enq_req_0_bits_exceptionVec_20         (io_fromRename_0_bits_exceptionVec_20),
    .io_enq_req_0_bits_exceptionVec_21         (io_fromRename_0_bits_exceptionVec_21),
    .io_enq_req_0_bits_exceptionVec_22         (io_fromRename_0_bits_exceptionVec_22),
    .io_enq_req_0_bits_exceptionVec_23         (io_fromRename_0_bits_exceptionVec_23),
    .io_enq_req_0_bits_trigger                 (io_fromRename_0_bits_trigger),
    .io_enq_req_0_bits_fuType                  (io_fromRename_0_bits_fuType),
    .io_enq_req_0_bits_fuOpType                (io_fromRename_0_bits_fuOpType),
    .io_enq_req_0_bits_flushPipe               (io_fromRename_0_bits_flushPipe),
    .io_enq_req_0_bits_uopIdx                  (io_fromRename_0_bits_uopIdx),
    .io_enq_req_0_bits_lastUop                 (io_fromRename_0_bits_lastUop),
    .io_enq_req_0_bits_robIdx_flag             (io_fromRename_0_bits_robIdx_flag),
    .io_enq_req_0_bits_robIdx_value            (io_fromRename_0_bits_robIdx_value),
    .io_enq_req_0_bits_numLsElem
      (isVlsType_0 ? io_fromRename_0_bits_numLsElem : 5'h1),
    .io_enq_req_1_valid
      (firedVec[1] & ~(io_fromRename_1_valid & io_fromRename_1_bits_fuType[17])
       & ~((io_fromRename_1_bits_fuType[33] | io_fromRename_1_bits_fuType[34])
           & io_fromRename_1_valid)
       & ~(io_fromRename_1_bits_vpu_isVleff & io_fromRename_1_bits_lastUop)),
    .io_enq_req_1_bits_exceptionVec_0          (io_fromRename_1_bits_exceptionVec_0),
    .io_enq_req_1_bits_exceptionVec_1          (io_fromRename_1_bits_exceptionVec_1),
    .io_enq_req_1_bits_exceptionVec_2          (io_fromRename_1_bits_exceptionVec_2),
    .io_enq_req_1_bits_exceptionVec_3          (io_fromRename_1_bits_exceptionVec_3),
    .io_enq_req_1_bits_exceptionVec_4          (io_fromRename_1_bits_exceptionVec_4),
    .io_enq_req_1_bits_exceptionVec_5          (io_fromRename_1_bits_exceptionVec_5),
    .io_enq_req_1_bits_exceptionVec_6          (io_fromRename_1_bits_exceptionVec_6),
    .io_enq_req_1_bits_exceptionVec_7          (io_fromRename_1_bits_exceptionVec_7),
    .io_enq_req_1_bits_exceptionVec_8          (io_fromRename_1_bits_exceptionVec_8),
    .io_enq_req_1_bits_exceptionVec_9          (io_fromRename_1_bits_exceptionVec_9),
    .io_enq_req_1_bits_exceptionVec_10         (io_fromRename_1_bits_exceptionVec_10),
    .io_enq_req_1_bits_exceptionVec_11         (io_fromRename_1_bits_exceptionVec_11),
    .io_enq_req_1_bits_exceptionVec_12         (io_fromRename_1_bits_exceptionVec_12),
    .io_enq_req_1_bits_exceptionVec_13         (io_fromRename_1_bits_exceptionVec_13),
    .io_enq_req_1_bits_exceptionVec_14         (io_fromRename_1_bits_exceptionVec_14),
    .io_enq_req_1_bits_exceptionVec_15         (io_fromRename_1_bits_exceptionVec_15),
    .io_enq_req_1_bits_exceptionVec_16         (io_fromRename_1_bits_exceptionVec_16),
    .io_enq_req_1_bits_exceptionVec_17         (io_fromRename_1_bits_exceptionVec_17),
    .io_enq_req_1_bits_exceptionVec_18         (io_fromRename_1_bits_exceptionVec_18),
    .io_enq_req_1_bits_exceptionVec_19         (io_fromRename_1_bits_exceptionVec_19),
    .io_enq_req_1_bits_exceptionVec_20         (io_fromRename_1_bits_exceptionVec_20),
    .io_enq_req_1_bits_exceptionVec_21         (io_fromRename_1_bits_exceptionVec_21),
    .io_enq_req_1_bits_exceptionVec_22         (io_fromRename_1_bits_exceptionVec_22),
    .io_enq_req_1_bits_exceptionVec_23         (io_fromRename_1_bits_exceptionVec_23),
    .io_enq_req_1_bits_trigger                 (io_fromRename_1_bits_trigger),
    .io_enq_req_1_bits_fuType                  (io_fromRename_1_bits_fuType),
    .io_enq_req_1_bits_fuOpType                (io_fromRename_1_bits_fuOpType),
    .io_enq_req_1_bits_flushPipe               (io_fromRename_1_bits_flushPipe),
    .io_enq_req_1_bits_uopIdx                  (io_fromRename_1_bits_uopIdx),
    .io_enq_req_1_bits_lastUop                 (io_fromRename_1_bits_lastUop),
    .io_enq_req_1_bits_robIdx_flag             (io_fromRename_1_bits_robIdx_flag),
    .io_enq_req_1_bits_robIdx_value            (io_fromRename_1_bits_robIdx_value),
    .io_enq_req_1_bits_numLsElem
      (isVlsType_1 ? io_fromRename_1_bits_numLsElem : 5'h1),
    .io_enq_req_2_valid
      (firedVec[2] & ~(io_fromRename_2_valid & io_fromRename_2_bits_fuType[17])
       & ~((io_fromRename_2_bits_fuType[33] | io_fromRename_2_bits_fuType[34])
           & io_fromRename_2_valid)
       & ~(io_fromRename_2_bits_vpu_isVleff & io_fromRename_2_bits_lastUop)),
    .io_enq_req_2_bits_exceptionVec_0          (io_fromRename_2_bits_exceptionVec_0),
    .io_enq_req_2_bits_exceptionVec_1          (io_fromRename_2_bits_exceptionVec_1),
    .io_enq_req_2_bits_exceptionVec_2          (io_fromRename_2_bits_exceptionVec_2),
    .io_enq_req_2_bits_exceptionVec_3          (io_fromRename_2_bits_exceptionVec_3),
    .io_enq_req_2_bits_exceptionVec_4          (io_fromRename_2_bits_exceptionVec_4),
    .io_enq_req_2_bits_exceptionVec_5          (io_fromRename_2_bits_exceptionVec_5),
    .io_enq_req_2_bits_exceptionVec_6          (io_fromRename_2_bits_exceptionVec_6),
    .io_enq_req_2_bits_exceptionVec_7          (io_fromRename_2_bits_exceptionVec_7),
    .io_enq_req_2_bits_exceptionVec_8          (io_fromRename_2_bits_exceptionVec_8),
    .io_enq_req_2_bits_exceptionVec_9          (io_fromRename_2_bits_exceptionVec_9),
    .io_enq_req_2_bits_exceptionVec_10         (io_fromRename_2_bits_exceptionVec_10),
    .io_enq_req_2_bits_exceptionVec_11         (io_fromRename_2_bits_exceptionVec_11),
    .io_enq_req_2_bits_exceptionVec_12         (io_fromRename_2_bits_exceptionVec_12),
    .io_enq_req_2_bits_exceptionVec_13         (io_fromRename_2_bits_exceptionVec_13),
    .io_enq_req_2_bits_exceptionVec_14         (io_fromRename_2_bits_exceptionVec_14),
    .io_enq_req_2_bits_exceptionVec_15         (io_fromRename_2_bits_exceptionVec_15),
    .io_enq_req_2_bits_exceptionVec_16         (io_fromRename_2_bits_exceptionVec_16),
    .io_enq_req_2_bits_exceptionVec_17         (io_fromRename_2_bits_exceptionVec_17),
    .io_enq_req_2_bits_exceptionVec_18         (io_fromRename_2_bits_exceptionVec_18),
    .io_enq_req_2_bits_exceptionVec_19         (io_fromRename_2_bits_exceptionVec_19),
    .io_enq_req_2_bits_exceptionVec_20         (io_fromRename_2_bits_exceptionVec_20),
    .io_enq_req_2_bits_exceptionVec_21         (io_fromRename_2_bits_exceptionVec_21),
    .io_enq_req_2_bits_exceptionVec_22         (io_fromRename_2_bits_exceptionVec_22),
    .io_enq_req_2_bits_exceptionVec_23         (io_fromRename_2_bits_exceptionVec_23),
    .io_enq_req_2_bits_trigger                 (io_fromRename_2_bits_trigger),
    .io_enq_req_2_bits_fuType                  (io_fromRename_2_bits_fuType),
    .io_enq_req_2_bits_fuOpType                (io_fromRename_2_bits_fuOpType),
    .io_enq_req_2_bits_flushPipe               (io_fromRename_2_bits_flushPipe),
    .io_enq_req_2_bits_uopIdx                  (io_fromRename_2_bits_uopIdx),
    .io_enq_req_2_bits_lastUop                 (io_fromRename_2_bits_lastUop),
    .io_enq_req_2_bits_robIdx_flag             (io_fromRename_2_bits_robIdx_flag),
    .io_enq_req_2_bits_robIdx_value            (io_fromRename_2_bits_robIdx_value),
    .io_enq_req_2_bits_numLsElem
      (isVlsType_2 ? io_fromRename_2_bits_numLsElem : 5'h1),
    .io_enq_req_3_valid
      (firedVec[3] & ~(io_fromRename_3_valid & io_fromRename_3_bits_fuType[17])
       & ~((io_fromRename_3_bits_fuType[33] | io_fromRename_3_bits_fuType[34])
           & io_fromRename_3_valid)
       & ~(io_fromRename_3_bits_vpu_isVleff & io_fromRename_3_bits_lastUop)),
    .io_enq_req_3_bits_exceptionVec_0          (io_fromRename_3_bits_exceptionVec_0),
    .io_enq_req_3_bits_exceptionVec_1          (io_fromRename_3_bits_exceptionVec_1),
    .io_enq_req_3_bits_exceptionVec_2          (io_fromRename_3_bits_exceptionVec_2),
    .io_enq_req_3_bits_exceptionVec_3          (io_fromRename_3_bits_exceptionVec_3),
    .io_enq_req_3_bits_exceptionVec_4          (io_fromRename_3_bits_exceptionVec_4),
    .io_enq_req_3_bits_exceptionVec_5          (io_fromRename_3_bits_exceptionVec_5),
    .io_enq_req_3_bits_exceptionVec_6          (io_fromRename_3_bits_exceptionVec_6),
    .io_enq_req_3_bits_exceptionVec_7          (io_fromRename_3_bits_exceptionVec_7),
    .io_enq_req_3_bits_exceptionVec_8          (io_fromRename_3_bits_exceptionVec_8),
    .io_enq_req_3_bits_exceptionVec_9          (io_fromRename_3_bits_exceptionVec_9),
    .io_enq_req_3_bits_exceptionVec_10         (io_fromRename_3_bits_exceptionVec_10),
    .io_enq_req_3_bits_exceptionVec_11         (io_fromRename_3_bits_exceptionVec_11),
    .io_enq_req_3_bits_exceptionVec_12         (io_fromRename_3_bits_exceptionVec_12),
    .io_enq_req_3_bits_exceptionVec_13         (io_fromRename_3_bits_exceptionVec_13),
    .io_enq_req_3_bits_exceptionVec_14         (io_fromRename_3_bits_exceptionVec_14),
    .io_enq_req_3_bits_exceptionVec_15         (io_fromRename_3_bits_exceptionVec_15),
    .io_enq_req_3_bits_exceptionVec_16         (io_fromRename_3_bits_exceptionVec_16),
    .io_enq_req_3_bits_exceptionVec_17         (io_fromRename_3_bits_exceptionVec_17),
    .io_enq_req_3_bits_exceptionVec_18         (io_fromRename_3_bits_exceptionVec_18),
    .io_enq_req_3_bits_exceptionVec_19         (io_fromRename_3_bits_exceptionVec_19),
    .io_enq_req_3_bits_exceptionVec_20         (io_fromRename_3_bits_exceptionVec_20),
    .io_enq_req_3_bits_exceptionVec_21         (io_fromRename_3_bits_exceptionVec_21),
    .io_enq_req_3_bits_exceptionVec_22         (io_fromRename_3_bits_exceptionVec_22),
    .io_enq_req_3_bits_exceptionVec_23         (io_fromRename_3_bits_exceptionVec_23),
    .io_enq_req_3_bits_trigger                 (io_fromRename_3_bits_trigger),
    .io_enq_req_3_bits_fuType                  (io_fromRename_3_bits_fuType),
    .io_enq_req_3_bits_fuOpType                (io_fromRename_3_bits_fuOpType),
    .io_enq_req_3_bits_flushPipe               (io_fromRename_3_bits_flushPipe),
    .io_enq_req_3_bits_uopIdx                  (io_fromRename_3_bits_uopIdx),
    .io_enq_req_3_bits_lastUop                 (io_fromRename_3_bits_lastUop),
    .io_enq_req_3_bits_robIdx_flag             (io_fromRename_3_bits_robIdx_flag),
    .io_enq_req_3_bits_robIdx_value            (io_fromRename_3_bits_robIdx_value),
    .io_enq_req_3_bits_numLsElem
      (isVlsType_3 ? io_fromRename_3_bits_numLsElem : 5'h1),
    .io_enq_req_4_valid
      (firedVec[4] & ~(io_fromRename_4_valid & io_fromRename_4_bits_fuType[17])
       & ~((io_fromRename_4_bits_fuType[33] | io_fromRename_4_bits_fuType[34])
           & io_fromRename_4_valid)
       & ~(io_fromRename_4_bits_vpu_isVleff & io_fromRename_4_bits_lastUop)),
    .io_enq_req_4_bits_exceptionVec_0          (io_fromRename_4_bits_exceptionVec_0),
    .io_enq_req_4_bits_exceptionVec_1          (io_fromRename_4_bits_exceptionVec_1),
    .io_enq_req_4_bits_exceptionVec_2          (io_fromRename_4_bits_exceptionVec_2),
    .io_enq_req_4_bits_exceptionVec_3          (io_fromRename_4_bits_exceptionVec_3),
    .io_enq_req_4_bits_exceptionVec_4          (io_fromRename_4_bits_exceptionVec_4),
    .io_enq_req_4_bits_exceptionVec_5          (io_fromRename_4_bits_exceptionVec_5),
    .io_enq_req_4_bits_exceptionVec_6          (io_fromRename_4_bits_exceptionVec_6),
    .io_enq_req_4_bits_exceptionVec_7          (io_fromRename_4_bits_exceptionVec_7),
    .io_enq_req_4_bits_exceptionVec_8          (io_fromRename_4_bits_exceptionVec_8),
    .io_enq_req_4_bits_exceptionVec_9          (io_fromRename_4_bits_exceptionVec_9),
    .io_enq_req_4_bits_exceptionVec_10         (io_fromRename_4_bits_exceptionVec_10),
    .io_enq_req_4_bits_exceptionVec_11         (io_fromRename_4_bits_exceptionVec_11),
    .io_enq_req_4_bits_exceptionVec_12         (io_fromRename_4_bits_exceptionVec_12),
    .io_enq_req_4_bits_exceptionVec_13         (io_fromRename_4_bits_exceptionVec_13),
    .io_enq_req_4_bits_exceptionVec_14         (io_fromRename_4_bits_exceptionVec_14),
    .io_enq_req_4_bits_exceptionVec_15         (io_fromRename_4_bits_exceptionVec_15),
    .io_enq_req_4_bits_exceptionVec_16         (io_fromRename_4_bits_exceptionVec_16),
    .io_enq_req_4_bits_exceptionVec_17         (io_fromRename_4_bits_exceptionVec_17),
    .io_enq_req_4_bits_exceptionVec_18         (io_fromRename_4_bits_exceptionVec_18),
    .io_enq_req_4_bits_exceptionVec_19         (io_fromRename_4_bits_exceptionVec_19),
    .io_enq_req_4_bits_exceptionVec_20         (io_fromRename_4_bits_exceptionVec_20),
    .io_enq_req_4_bits_exceptionVec_21         (io_fromRename_4_bits_exceptionVec_21),
    .io_enq_req_4_bits_exceptionVec_22         (io_fromRename_4_bits_exceptionVec_22),
    .io_enq_req_4_bits_exceptionVec_23         (io_fromRename_4_bits_exceptionVec_23),
    .io_enq_req_4_bits_trigger                 (io_fromRename_4_bits_trigger),
    .io_enq_req_4_bits_fuType                  (io_fromRename_4_bits_fuType),
    .io_enq_req_4_bits_fuOpType                (io_fromRename_4_bits_fuOpType),
    .io_enq_req_4_bits_flushPipe               (io_fromRename_4_bits_flushPipe),
    .io_enq_req_4_bits_uopIdx                  (io_fromRename_4_bits_uopIdx),
    .io_enq_req_4_bits_lastUop                 (io_fromRename_4_bits_lastUop),
    .io_enq_req_4_bits_robIdx_flag             (io_fromRename_4_bits_robIdx_flag),
    .io_enq_req_4_bits_robIdx_value            (io_fromRename_4_bits_robIdx_value),
    .io_enq_req_4_bits_numLsElem
      (isVlsType_4 ? io_fromRename_4_bits_numLsElem : 5'h1),
    .io_enq_req_5_valid
      (firedVec[5] & ~(io_fromRename_5_valid & io_fromRename_5_bits_fuType[17])
       & ~((io_fromRename_5_bits_fuType[33] | io_fromRename_5_bits_fuType[34])
           & io_fromRename_5_valid)
       & ~(io_fromRename_5_bits_vpu_isVleff & io_fromRename_5_bits_lastUop)),
    .io_enq_req_5_bits_exceptionVec_0          (io_fromRename_5_bits_exceptionVec_0),
    .io_enq_req_5_bits_exceptionVec_1          (io_fromRename_5_bits_exceptionVec_1),
    .io_enq_req_5_bits_exceptionVec_2          (io_fromRename_5_bits_exceptionVec_2),
    .io_enq_req_5_bits_exceptionVec_3          (io_fromRename_5_bits_exceptionVec_3),
    .io_enq_req_5_bits_exceptionVec_4          (io_fromRename_5_bits_exceptionVec_4),
    .io_enq_req_5_bits_exceptionVec_5          (io_fromRename_5_bits_exceptionVec_5),
    .io_enq_req_5_bits_exceptionVec_6          (io_fromRename_5_bits_exceptionVec_6),
    .io_enq_req_5_bits_exceptionVec_7          (io_fromRename_5_bits_exceptionVec_7),
    .io_enq_req_5_bits_exceptionVec_8          (io_fromRename_5_bits_exceptionVec_8),
    .io_enq_req_5_bits_exceptionVec_9          (io_fromRename_5_bits_exceptionVec_9),
    .io_enq_req_5_bits_exceptionVec_10         (io_fromRename_5_bits_exceptionVec_10),
    .io_enq_req_5_bits_exceptionVec_11         (io_fromRename_5_bits_exceptionVec_11),
    .io_enq_req_5_bits_exceptionVec_12         (io_fromRename_5_bits_exceptionVec_12),
    .io_enq_req_5_bits_exceptionVec_13         (io_fromRename_5_bits_exceptionVec_13),
    .io_enq_req_5_bits_exceptionVec_14         (io_fromRename_5_bits_exceptionVec_14),
    .io_enq_req_5_bits_exceptionVec_15         (io_fromRename_5_bits_exceptionVec_15),
    .io_enq_req_5_bits_exceptionVec_16         (io_fromRename_5_bits_exceptionVec_16),
    .io_enq_req_5_bits_exceptionVec_17         (io_fromRename_5_bits_exceptionVec_17),
    .io_enq_req_5_bits_exceptionVec_18         (io_fromRename_5_bits_exceptionVec_18),
    .io_enq_req_5_bits_exceptionVec_19         (io_fromRename_5_bits_exceptionVec_19),
    .io_enq_req_5_bits_exceptionVec_20         (io_fromRename_5_bits_exceptionVec_20),
    .io_enq_req_5_bits_exceptionVec_21         (io_fromRename_5_bits_exceptionVec_21),
    .io_enq_req_5_bits_exceptionVec_22         (io_fromRename_5_bits_exceptionVec_22),
    .io_enq_req_5_bits_exceptionVec_23         (io_fromRename_5_bits_exceptionVec_23),
    .io_enq_req_5_bits_trigger                 (io_fromRename_5_bits_trigger),
    .io_enq_req_5_bits_fuType                  (io_fromRename_5_bits_fuType),
    .io_enq_req_5_bits_fuOpType                (io_fromRename_5_bits_fuOpType),
    .io_enq_req_5_bits_flushPipe               (io_fromRename_5_bits_flushPipe),
    .io_enq_req_5_bits_uopIdx                  (io_fromRename_5_bits_uopIdx),
    .io_enq_req_5_bits_lastUop                 (io_fromRename_5_bits_lastUop),
    .io_enq_req_5_bits_robIdx_flag             (io_fromRename_5_bits_robIdx_flag),
    .io_enq_req_5_bits_robIdx_value            (io_fromRename_5_bits_robIdx_value),
    .io_enq_req_5_bits_numLsElem
      (isVlsType_5 ? io_fromRename_5_bits_numLsElem : 5'h1),
    .io_enq_iqAccept_0                         (~io_fromRename_0_valid | firedVec[0]),
    .io_enq_iqAccept_1                         (~io_fromRename_1_valid | firedVec[1]),
    .io_enq_iqAccept_2                         (~io_fromRename_2_valid | firedVec[2]),
    .io_enq_iqAccept_3                         (~io_fromRename_3_valid | firedVec[3]),
    .io_enq_iqAccept_4                         (~io_fromRename_4_valid | firedVec[4]),
    .io_enq_iqAccept_5                         (~io_fromRename_5_valid | firedVec[5]),
    .io_enq_resp_0_lqIdx_flag                  (_lsqEnqCtrl_io_enq_resp_0_lqIdx_flag),
    .io_enq_resp_0_lqIdx_value                 (_lsqEnqCtrl_io_enq_resp_0_lqIdx_value),
    .io_enq_resp_0_sqIdx_flag                  (_lsqEnqCtrl_io_enq_resp_0_sqIdx_flag),
    .io_enq_resp_0_sqIdx_value                 (_lsqEnqCtrl_io_enq_resp_0_sqIdx_value),
    .io_enq_resp_1_lqIdx_flag                  (_lsqEnqCtrl_io_enq_resp_1_lqIdx_flag),
    .io_enq_resp_1_lqIdx_value                 (_lsqEnqCtrl_io_enq_resp_1_lqIdx_value),
    .io_enq_resp_1_sqIdx_flag                  (_lsqEnqCtrl_io_enq_resp_1_sqIdx_flag),
    .io_enq_resp_1_sqIdx_value                 (_lsqEnqCtrl_io_enq_resp_1_sqIdx_value),
    .io_enq_resp_2_lqIdx_flag                  (_lsqEnqCtrl_io_enq_resp_2_lqIdx_flag),
    .io_enq_resp_2_lqIdx_value                 (_lsqEnqCtrl_io_enq_resp_2_lqIdx_value),
    .io_enq_resp_2_sqIdx_flag                  (_lsqEnqCtrl_io_enq_resp_2_sqIdx_flag),
    .io_enq_resp_2_sqIdx_value                 (_lsqEnqCtrl_io_enq_resp_2_sqIdx_value),
    .io_enq_resp_3_lqIdx_flag                  (_lsqEnqCtrl_io_enq_resp_3_lqIdx_flag),
    .io_enq_resp_3_lqIdx_value                 (_lsqEnqCtrl_io_enq_resp_3_lqIdx_value),
    .io_enq_resp_3_sqIdx_flag                  (_lsqEnqCtrl_io_enq_resp_3_sqIdx_flag),
    .io_enq_resp_3_sqIdx_value                 (_lsqEnqCtrl_io_enq_resp_3_sqIdx_value),
    .io_enq_resp_4_lqIdx_flag                  (_lsqEnqCtrl_io_enq_resp_4_lqIdx_flag),
    .io_enq_resp_4_lqIdx_value                 (_lsqEnqCtrl_io_enq_resp_4_lqIdx_value),
    .io_enq_resp_4_sqIdx_flag                  (_lsqEnqCtrl_io_enq_resp_4_sqIdx_flag),
    .io_enq_resp_4_sqIdx_value                 (_lsqEnqCtrl_io_enq_resp_4_sqIdx_value),
    .io_enq_resp_5_lqIdx_flag                  (_lsqEnqCtrl_io_enq_resp_5_lqIdx_flag),
    .io_enq_resp_5_lqIdx_value                 (_lsqEnqCtrl_io_enq_resp_5_lqIdx_value),
    .io_enq_resp_5_sqIdx_flag                  (_lsqEnqCtrl_io_enq_resp_5_sqIdx_flag),
    .io_enq_resp_5_sqIdx_value                 (_lsqEnqCtrl_io_enq_resp_5_sqIdx_value),
    .io_lcommit                                (io_fromMem_lcommit),
    .io_scommit                                (io_fromMem_scommit),
    .io_lqCancelCnt                            (io_fromMem_lqCancelCnt),
    .io_sqCancelCnt                            (io_fromMem_sqCancelCnt),
    .io_lqFreeCount                            (_lsqEnqCtrl_io_lqFreeCount),
    .io_sqFreeCount                            (_lsqEnqCtrl_io_sqFreeCount),
    .io_enqLsq_needAlloc_0                     (io_toMem_lsqEnqIO_needAlloc_0),
    .io_enqLsq_needAlloc_1                     (io_toMem_lsqEnqIO_needAlloc_1),
    .io_enqLsq_needAlloc_2                     (io_toMem_lsqEnqIO_needAlloc_2),
    .io_enqLsq_needAlloc_3                     (io_toMem_lsqEnqIO_needAlloc_3),
    .io_enqLsq_needAlloc_4                     (io_toMem_lsqEnqIO_needAlloc_4),
    .io_enqLsq_needAlloc_5                     (io_toMem_lsqEnqIO_needAlloc_5),
    .io_enqLsq_req_0_valid                     (io_toMem_lsqEnqIO_req_0_valid),
    .io_enqLsq_req_0_bits_exceptionVec_0
      (io_toMem_lsqEnqIO_req_0_bits_exceptionVec_0),
    .io_enqLsq_req_0_bits_exceptionVec_1
      (io_toMem_lsqEnqIO_req_0_bits_exceptionVec_1),
    .io_enqLsq_req_0_bits_exceptionVec_2
      (io_toMem_lsqEnqIO_req_0_bits_exceptionVec_2),
    .io_enqLsq_req_0_bits_exceptionVec_3
      (io_toMem_lsqEnqIO_req_0_bits_exceptionVec_3),
    .io_enqLsq_req_0_bits_exceptionVec_4
      (io_toMem_lsqEnqIO_req_0_bits_exceptionVec_4),
    .io_enqLsq_req_0_bits_exceptionVec_5
      (io_toMem_lsqEnqIO_req_0_bits_exceptionVec_5),
    .io_enqLsq_req_0_bits_exceptionVec_6
      (io_toMem_lsqEnqIO_req_0_bits_exceptionVec_6),
    .io_enqLsq_req_0_bits_exceptionVec_7
      (io_toMem_lsqEnqIO_req_0_bits_exceptionVec_7),
    .io_enqLsq_req_0_bits_exceptionVec_8
      (io_toMem_lsqEnqIO_req_0_bits_exceptionVec_8),
    .io_enqLsq_req_0_bits_exceptionVec_9
      (io_toMem_lsqEnqIO_req_0_bits_exceptionVec_9),
    .io_enqLsq_req_0_bits_exceptionVec_10
      (io_toMem_lsqEnqIO_req_0_bits_exceptionVec_10),
    .io_enqLsq_req_0_bits_exceptionVec_11
      (io_toMem_lsqEnqIO_req_0_bits_exceptionVec_11),
    .io_enqLsq_req_0_bits_exceptionVec_12
      (io_toMem_lsqEnqIO_req_0_bits_exceptionVec_12),
    .io_enqLsq_req_0_bits_exceptionVec_13
      (io_toMem_lsqEnqIO_req_0_bits_exceptionVec_13),
    .io_enqLsq_req_0_bits_exceptionVec_14
      (io_toMem_lsqEnqIO_req_0_bits_exceptionVec_14),
    .io_enqLsq_req_0_bits_exceptionVec_15
      (io_toMem_lsqEnqIO_req_0_bits_exceptionVec_15),
    .io_enqLsq_req_0_bits_exceptionVec_16
      (io_toMem_lsqEnqIO_req_0_bits_exceptionVec_16),
    .io_enqLsq_req_0_bits_exceptionVec_17
      (io_toMem_lsqEnqIO_req_0_bits_exceptionVec_17),
    .io_enqLsq_req_0_bits_exceptionVec_18
      (io_toMem_lsqEnqIO_req_0_bits_exceptionVec_18),
    .io_enqLsq_req_0_bits_exceptionVec_19
      (io_toMem_lsqEnqIO_req_0_bits_exceptionVec_19),
    .io_enqLsq_req_0_bits_exceptionVec_20
      (io_toMem_lsqEnqIO_req_0_bits_exceptionVec_20),
    .io_enqLsq_req_0_bits_exceptionVec_21
      (io_toMem_lsqEnqIO_req_0_bits_exceptionVec_21),
    .io_enqLsq_req_0_bits_exceptionVec_22
      (io_toMem_lsqEnqIO_req_0_bits_exceptionVec_22),
    .io_enqLsq_req_0_bits_exceptionVec_23
      (io_toMem_lsqEnqIO_req_0_bits_exceptionVec_23),
    .io_enqLsq_req_0_bits_trigger              (io_toMem_lsqEnqIO_req_0_bits_trigger),
    .io_enqLsq_req_0_bits_fuType               (io_toMem_lsqEnqIO_req_0_bits_fuType),
    .io_enqLsq_req_0_bits_fuOpType             (io_toMem_lsqEnqIO_req_0_bits_fuOpType),
    .io_enqLsq_req_0_bits_flushPipe            (io_toMem_lsqEnqIO_req_0_bits_flushPipe),
    .io_enqLsq_req_0_bits_uopIdx               (io_toMem_lsqEnqIO_req_0_bits_uopIdx),
    .io_enqLsq_req_0_bits_lastUop              (io_toMem_lsqEnqIO_req_0_bits_lastUop),
    .io_enqLsq_req_0_bits_robIdx_flag          (io_toMem_lsqEnqIO_req_0_bits_robIdx_flag),
    .io_enqLsq_req_0_bits_robIdx_value
      (io_toMem_lsqEnqIO_req_0_bits_robIdx_value),
    .io_enqLsq_req_0_bits_debugInfo_enqRsTime
      (io_toMem_lsqEnqIO_req_0_bits_debugInfo_enqRsTime),
    .io_enqLsq_req_0_bits_debugInfo_selectTime
      (io_toMem_lsqEnqIO_req_0_bits_debugInfo_selectTime),
    .io_enqLsq_req_0_bits_debugInfo_issueTime
      (io_toMem_lsqEnqIO_req_0_bits_debugInfo_issueTime),
    .io_enqLsq_req_0_bits_lqIdx_flag           (io_toMem_lsqEnqIO_req_0_bits_lqIdx_flag),
    .io_enqLsq_req_0_bits_lqIdx_value          (io_toMem_lsqEnqIO_req_0_bits_lqIdx_value),
    .io_enqLsq_req_0_bits_sqIdx_flag           (io_toMem_lsqEnqIO_req_0_bits_sqIdx_flag),
    .io_enqLsq_req_0_bits_sqIdx_value          (io_toMem_lsqEnqIO_req_0_bits_sqIdx_value),
    .io_enqLsq_req_0_bits_numLsElem            (io_toMem_lsqEnqIO_req_0_bits_numLsElem),
    .io_enqLsq_req_1_valid                     (io_toMem_lsqEnqIO_req_1_valid),
    .io_enqLsq_req_1_bits_exceptionVec_0
      (io_toMem_lsqEnqIO_req_1_bits_exceptionVec_0),
    .io_enqLsq_req_1_bits_exceptionVec_1
      (io_toMem_lsqEnqIO_req_1_bits_exceptionVec_1),
    .io_enqLsq_req_1_bits_exceptionVec_2
      (io_toMem_lsqEnqIO_req_1_bits_exceptionVec_2),
    .io_enqLsq_req_1_bits_exceptionVec_3
      (io_toMem_lsqEnqIO_req_1_bits_exceptionVec_3),
    .io_enqLsq_req_1_bits_exceptionVec_4
      (io_toMem_lsqEnqIO_req_1_bits_exceptionVec_4),
    .io_enqLsq_req_1_bits_exceptionVec_5
      (io_toMem_lsqEnqIO_req_1_bits_exceptionVec_5),
    .io_enqLsq_req_1_bits_exceptionVec_6
      (io_toMem_lsqEnqIO_req_1_bits_exceptionVec_6),
    .io_enqLsq_req_1_bits_exceptionVec_7
      (io_toMem_lsqEnqIO_req_1_bits_exceptionVec_7),
    .io_enqLsq_req_1_bits_exceptionVec_8
      (io_toMem_lsqEnqIO_req_1_bits_exceptionVec_8),
    .io_enqLsq_req_1_bits_exceptionVec_9
      (io_toMem_lsqEnqIO_req_1_bits_exceptionVec_9),
    .io_enqLsq_req_1_bits_exceptionVec_10
      (io_toMem_lsqEnqIO_req_1_bits_exceptionVec_10),
    .io_enqLsq_req_1_bits_exceptionVec_11
      (io_toMem_lsqEnqIO_req_1_bits_exceptionVec_11),
    .io_enqLsq_req_1_bits_exceptionVec_12
      (io_toMem_lsqEnqIO_req_1_bits_exceptionVec_12),
    .io_enqLsq_req_1_bits_exceptionVec_13
      (io_toMem_lsqEnqIO_req_1_bits_exceptionVec_13),
    .io_enqLsq_req_1_bits_exceptionVec_14
      (io_toMem_lsqEnqIO_req_1_bits_exceptionVec_14),
    .io_enqLsq_req_1_bits_exceptionVec_15
      (io_toMem_lsqEnqIO_req_1_bits_exceptionVec_15),
    .io_enqLsq_req_1_bits_exceptionVec_16
      (io_toMem_lsqEnqIO_req_1_bits_exceptionVec_16),
    .io_enqLsq_req_1_bits_exceptionVec_17
      (io_toMem_lsqEnqIO_req_1_bits_exceptionVec_17),
    .io_enqLsq_req_1_bits_exceptionVec_18
      (io_toMem_lsqEnqIO_req_1_bits_exceptionVec_18),
    .io_enqLsq_req_1_bits_exceptionVec_19
      (io_toMem_lsqEnqIO_req_1_bits_exceptionVec_19),
    .io_enqLsq_req_1_bits_exceptionVec_20
      (io_toMem_lsqEnqIO_req_1_bits_exceptionVec_20),
    .io_enqLsq_req_1_bits_exceptionVec_21
      (io_toMem_lsqEnqIO_req_1_bits_exceptionVec_21),
    .io_enqLsq_req_1_bits_exceptionVec_22
      (io_toMem_lsqEnqIO_req_1_bits_exceptionVec_22),
    .io_enqLsq_req_1_bits_exceptionVec_23
      (io_toMem_lsqEnqIO_req_1_bits_exceptionVec_23),
    .io_enqLsq_req_1_bits_trigger              (io_toMem_lsqEnqIO_req_1_bits_trigger),
    .io_enqLsq_req_1_bits_fuType               (io_toMem_lsqEnqIO_req_1_bits_fuType),
    .io_enqLsq_req_1_bits_fuOpType             (io_toMem_lsqEnqIO_req_1_bits_fuOpType),
    .io_enqLsq_req_1_bits_flushPipe            (io_toMem_lsqEnqIO_req_1_bits_flushPipe),
    .io_enqLsq_req_1_bits_uopIdx               (io_toMem_lsqEnqIO_req_1_bits_uopIdx),
    .io_enqLsq_req_1_bits_lastUop              (io_toMem_lsqEnqIO_req_1_bits_lastUop),
    .io_enqLsq_req_1_bits_robIdx_flag          (io_toMem_lsqEnqIO_req_1_bits_robIdx_flag),
    .io_enqLsq_req_1_bits_robIdx_value
      (io_toMem_lsqEnqIO_req_1_bits_robIdx_value),
    .io_enqLsq_req_1_bits_debugInfo_enqRsTime
      (io_toMem_lsqEnqIO_req_1_bits_debugInfo_enqRsTime),
    .io_enqLsq_req_1_bits_debugInfo_selectTime
      (io_toMem_lsqEnqIO_req_1_bits_debugInfo_selectTime),
    .io_enqLsq_req_1_bits_debugInfo_issueTime
      (io_toMem_lsqEnqIO_req_1_bits_debugInfo_issueTime),
    .io_enqLsq_req_1_bits_lqIdx_flag           (io_toMem_lsqEnqIO_req_1_bits_lqIdx_flag),
    .io_enqLsq_req_1_bits_lqIdx_value          (io_toMem_lsqEnqIO_req_1_bits_lqIdx_value),
    .io_enqLsq_req_1_bits_sqIdx_flag           (io_toMem_lsqEnqIO_req_1_bits_sqIdx_flag),
    .io_enqLsq_req_1_bits_sqIdx_value          (io_toMem_lsqEnqIO_req_1_bits_sqIdx_value),
    .io_enqLsq_req_1_bits_numLsElem            (io_toMem_lsqEnqIO_req_1_bits_numLsElem),
    .io_enqLsq_req_2_valid                     (io_toMem_lsqEnqIO_req_2_valid),
    .io_enqLsq_req_2_bits_exceptionVec_0
      (io_toMem_lsqEnqIO_req_2_bits_exceptionVec_0),
    .io_enqLsq_req_2_bits_exceptionVec_1
      (io_toMem_lsqEnqIO_req_2_bits_exceptionVec_1),
    .io_enqLsq_req_2_bits_exceptionVec_2
      (io_toMem_lsqEnqIO_req_2_bits_exceptionVec_2),
    .io_enqLsq_req_2_bits_exceptionVec_3
      (io_toMem_lsqEnqIO_req_2_bits_exceptionVec_3),
    .io_enqLsq_req_2_bits_exceptionVec_4
      (io_toMem_lsqEnqIO_req_2_bits_exceptionVec_4),
    .io_enqLsq_req_2_bits_exceptionVec_5
      (io_toMem_lsqEnqIO_req_2_bits_exceptionVec_5),
    .io_enqLsq_req_2_bits_exceptionVec_6
      (io_toMem_lsqEnqIO_req_2_bits_exceptionVec_6),
    .io_enqLsq_req_2_bits_exceptionVec_7
      (io_toMem_lsqEnqIO_req_2_bits_exceptionVec_7),
    .io_enqLsq_req_2_bits_exceptionVec_8
      (io_toMem_lsqEnqIO_req_2_bits_exceptionVec_8),
    .io_enqLsq_req_2_bits_exceptionVec_9
      (io_toMem_lsqEnqIO_req_2_bits_exceptionVec_9),
    .io_enqLsq_req_2_bits_exceptionVec_10
      (io_toMem_lsqEnqIO_req_2_bits_exceptionVec_10),
    .io_enqLsq_req_2_bits_exceptionVec_11
      (io_toMem_lsqEnqIO_req_2_bits_exceptionVec_11),
    .io_enqLsq_req_2_bits_exceptionVec_12
      (io_toMem_lsqEnqIO_req_2_bits_exceptionVec_12),
    .io_enqLsq_req_2_bits_exceptionVec_13
      (io_toMem_lsqEnqIO_req_2_bits_exceptionVec_13),
    .io_enqLsq_req_2_bits_exceptionVec_14
      (io_toMem_lsqEnqIO_req_2_bits_exceptionVec_14),
    .io_enqLsq_req_2_bits_exceptionVec_15
      (io_toMem_lsqEnqIO_req_2_bits_exceptionVec_15),
    .io_enqLsq_req_2_bits_exceptionVec_16
      (io_toMem_lsqEnqIO_req_2_bits_exceptionVec_16),
    .io_enqLsq_req_2_bits_exceptionVec_17
      (io_toMem_lsqEnqIO_req_2_bits_exceptionVec_17),
    .io_enqLsq_req_2_bits_exceptionVec_18
      (io_toMem_lsqEnqIO_req_2_bits_exceptionVec_18),
    .io_enqLsq_req_2_bits_exceptionVec_19
      (io_toMem_lsqEnqIO_req_2_bits_exceptionVec_19),
    .io_enqLsq_req_2_bits_exceptionVec_20
      (io_toMem_lsqEnqIO_req_2_bits_exceptionVec_20),
    .io_enqLsq_req_2_bits_exceptionVec_21
      (io_toMem_lsqEnqIO_req_2_bits_exceptionVec_21),
    .io_enqLsq_req_2_bits_exceptionVec_22
      (io_toMem_lsqEnqIO_req_2_bits_exceptionVec_22),
    .io_enqLsq_req_2_bits_exceptionVec_23
      (io_toMem_lsqEnqIO_req_2_bits_exceptionVec_23),
    .io_enqLsq_req_2_bits_trigger              (io_toMem_lsqEnqIO_req_2_bits_trigger),
    .io_enqLsq_req_2_bits_fuType               (io_toMem_lsqEnqIO_req_2_bits_fuType),
    .io_enqLsq_req_2_bits_fuOpType             (io_toMem_lsqEnqIO_req_2_bits_fuOpType),
    .io_enqLsq_req_2_bits_flushPipe            (io_toMem_lsqEnqIO_req_2_bits_flushPipe),
    .io_enqLsq_req_2_bits_uopIdx               (io_toMem_lsqEnqIO_req_2_bits_uopIdx),
    .io_enqLsq_req_2_bits_lastUop              (io_toMem_lsqEnqIO_req_2_bits_lastUop),
    .io_enqLsq_req_2_bits_robIdx_flag          (io_toMem_lsqEnqIO_req_2_bits_robIdx_flag),
    .io_enqLsq_req_2_bits_robIdx_value
      (io_toMem_lsqEnqIO_req_2_bits_robIdx_value),
    .io_enqLsq_req_2_bits_debugInfo_enqRsTime
      (io_toMem_lsqEnqIO_req_2_bits_debugInfo_enqRsTime),
    .io_enqLsq_req_2_bits_debugInfo_selectTime
      (io_toMem_lsqEnqIO_req_2_bits_debugInfo_selectTime),
    .io_enqLsq_req_2_bits_debugInfo_issueTime
      (io_toMem_lsqEnqIO_req_2_bits_debugInfo_issueTime),
    .io_enqLsq_req_2_bits_lqIdx_flag           (io_toMem_lsqEnqIO_req_2_bits_lqIdx_flag),
    .io_enqLsq_req_2_bits_lqIdx_value          (io_toMem_lsqEnqIO_req_2_bits_lqIdx_value),
    .io_enqLsq_req_2_bits_sqIdx_flag           (io_toMem_lsqEnqIO_req_2_bits_sqIdx_flag),
    .io_enqLsq_req_2_bits_sqIdx_value          (io_toMem_lsqEnqIO_req_2_bits_sqIdx_value),
    .io_enqLsq_req_2_bits_numLsElem            (io_toMem_lsqEnqIO_req_2_bits_numLsElem),
    .io_enqLsq_req_3_valid                     (io_toMem_lsqEnqIO_req_3_valid),
    .io_enqLsq_req_3_bits_exceptionVec_0
      (io_toMem_lsqEnqIO_req_3_bits_exceptionVec_0),
    .io_enqLsq_req_3_bits_exceptionVec_1
      (io_toMem_lsqEnqIO_req_3_bits_exceptionVec_1),
    .io_enqLsq_req_3_bits_exceptionVec_2
      (io_toMem_lsqEnqIO_req_3_bits_exceptionVec_2),
    .io_enqLsq_req_3_bits_exceptionVec_3
      (io_toMem_lsqEnqIO_req_3_bits_exceptionVec_3),
    .io_enqLsq_req_3_bits_exceptionVec_4
      (io_toMem_lsqEnqIO_req_3_bits_exceptionVec_4),
    .io_enqLsq_req_3_bits_exceptionVec_5
      (io_toMem_lsqEnqIO_req_3_bits_exceptionVec_5),
    .io_enqLsq_req_3_bits_exceptionVec_6
      (io_toMem_lsqEnqIO_req_3_bits_exceptionVec_6),
    .io_enqLsq_req_3_bits_exceptionVec_7
      (io_toMem_lsqEnqIO_req_3_bits_exceptionVec_7),
    .io_enqLsq_req_3_bits_exceptionVec_8
      (io_toMem_lsqEnqIO_req_3_bits_exceptionVec_8),
    .io_enqLsq_req_3_bits_exceptionVec_9
      (io_toMem_lsqEnqIO_req_3_bits_exceptionVec_9),
    .io_enqLsq_req_3_bits_exceptionVec_10
      (io_toMem_lsqEnqIO_req_3_bits_exceptionVec_10),
    .io_enqLsq_req_3_bits_exceptionVec_11
      (io_toMem_lsqEnqIO_req_3_bits_exceptionVec_11),
    .io_enqLsq_req_3_bits_exceptionVec_12
      (io_toMem_lsqEnqIO_req_3_bits_exceptionVec_12),
    .io_enqLsq_req_3_bits_exceptionVec_13
      (io_toMem_lsqEnqIO_req_3_bits_exceptionVec_13),
    .io_enqLsq_req_3_bits_exceptionVec_14
      (io_toMem_lsqEnqIO_req_3_bits_exceptionVec_14),
    .io_enqLsq_req_3_bits_exceptionVec_15
      (io_toMem_lsqEnqIO_req_3_bits_exceptionVec_15),
    .io_enqLsq_req_3_bits_exceptionVec_16
      (io_toMem_lsqEnqIO_req_3_bits_exceptionVec_16),
    .io_enqLsq_req_3_bits_exceptionVec_17
      (io_toMem_lsqEnqIO_req_3_bits_exceptionVec_17),
    .io_enqLsq_req_3_bits_exceptionVec_18
      (io_toMem_lsqEnqIO_req_3_bits_exceptionVec_18),
    .io_enqLsq_req_3_bits_exceptionVec_19
      (io_toMem_lsqEnqIO_req_3_bits_exceptionVec_19),
    .io_enqLsq_req_3_bits_exceptionVec_20
      (io_toMem_lsqEnqIO_req_3_bits_exceptionVec_20),
    .io_enqLsq_req_3_bits_exceptionVec_21
      (io_toMem_lsqEnqIO_req_3_bits_exceptionVec_21),
    .io_enqLsq_req_3_bits_exceptionVec_22
      (io_toMem_lsqEnqIO_req_3_bits_exceptionVec_22),
    .io_enqLsq_req_3_bits_exceptionVec_23
      (io_toMem_lsqEnqIO_req_3_bits_exceptionVec_23),
    .io_enqLsq_req_3_bits_trigger              (io_toMem_lsqEnqIO_req_3_bits_trigger),
    .io_enqLsq_req_3_bits_fuType               (io_toMem_lsqEnqIO_req_3_bits_fuType),
    .io_enqLsq_req_3_bits_fuOpType             (io_toMem_lsqEnqIO_req_3_bits_fuOpType),
    .io_enqLsq_req_3_bits_flushPipe            (io_toMem_lsqEnqIO_req_3_bits_flushPipe),
    .io_enqLsq_req_3_bits_uopIdx               (io_toMem_lsqEnqIO_req_3_bits_uopIdx),
    .io_enqLsq_req_3_bits_lastUop              (io_toMem_lsqEnqIO_req_3_bits_lastUop),
    .io_enqLsq_req_3_bits_robIdx_flag          (io_toMem_lsqEnqIO_req_3_bits_robIdx_flag),
    .io_enqLsq_req_3_bits_robIdx_value
      (io_toMem_lsqEnqIO_req_3_bits_robIdx_value),
    .io_enqLsq_req_3_bits_debugInfo_enqRsTime
      (io_toMem_lsqEnqIO_req_3_bits_debugInfo_enqRsTime),
    .io_enqLsq_req_3_bits_debugInfo_selectTime
      (io_toMem_lsqEnqIO_req_3_bits_debugInfo_selectTime),
    .io_enqLsq_req_3_bits_debugInfo_issueTime
      (io_toMem_lsqEnqIO_req_3_bits_debugInfo_issueTime),
    .io_enqLsq_req_3_bits_lqIdx_flag           (io_toMem_lsqEnqIO_req_3_bits_lqIdx_flag),
    .io_enqLsq_req_3_bits_lqIdx_value          (io_toMem_lsqEnqIO_req_3_bits_lqIdx_value),
    .io_enqLsq_req_3_bits_sqIdx_flag           (io_toMem_lsqEnqIO_req_3_bits_sqIdx_flag),
    .io_enqLsq_req_3_bits_sqIdx_value          (io_toMem_lsqEnqIO_req_3_bits_sqIdx_value),
    .io_enqLsq_req_3_bits_numLsElem            (io_toMem_lsqEnqIO_req_3_bits_numLsElem),
    .io_enqLsq_req_4_valid                     (io_toMem_lsqEnqIO_req_4_valid),
    .io_enqLsq_req_4_bits_exceptionVec_0
      (io_toMem_lsqEnqIO_req_4_bits_exceptionVec_0),
    .io_enqLsq_req_4_bits_exceptionVec_1
      (io_toMem_lsqEnqIO_req_4_bits_exceptionVec_1),
    .io_enqLsq_req_4_bits_exceptionVec_2
      (io_toMem_lsqEnqIO_req_4_bits_exceptionVec_2),
    .io_enqLsq_req_4_bits_exceptionVec_3
      (io_toMem_lsqEnqIO_req_4_bits_exceptionVec_3),
    .io_enqLsq_req_4_bits_exceptionVec_4
      (io_toMem_lsqEnqIO_req_4_bits_exceptionVec_4),
    .io_enqLsq_req_4_bits_exceptionVec_5
      (io_toMem_lsqEnqIO_req_4_bits_exceptionVec_5),
    .io_enqLsq_req_4_bits_exceptionVec_6
      (io_toMem_lsqEnqIO_req_4_bits_exceptionVec_6),
    .io_enqLsq_req_4_bits_exceptionVec_7
      (io_toMem_lsqEnqIO_req_4_bits_exceptionVec_7),
    .io_enqLsq_req_4_bits_exceptionVec_8
      (io_toMem_lsqEnqIO_req_4_bits_exceptionVec_8),
    .io_enqLsq_req_4_bits_exceptionVec_9
      (io_toMem_lsqEnqIO_req_4_bits_exceptionVec_9),
    .io_enqLsq_req_4_bits_exceptionVec_10
      (io_toMem_lsqEnqIO_req_4_bits_exceptionVec_10),
    .io_enqLsq_req_4_bits_exceptionVec_11
      (io_toMem_lsqEnqIO_req_4_bits_exceptionVec_11),
    .io_enqLsq_req_4_bits_exceptionVec_12
      (io_toMem_lsqEnqIO_req_4_bits_exceptionVec_12),
    .io_enqLsq_req_4_bits_exceptionVec_13
      (io_toMem_lsqEnqIO_req_4_bits_exceptionVec_13),
    .io_enqLsq_req_4_bits_exceptionVec_14
      (io_toMem_lsqEnqIO_req_4_bits_exceptionVec_14),
    .io_enqLsq_req_4_bits_exceptionVec_15
      (io_toMem_lsqEnqIO_req_4_bits_exceptionVec_15),
    .io_enqLsq_req_4_bits_exceptionVec_16
      (io_toMem_lsqEnqIO_req_4_bits_exceptionVec_16),
    .io_enqLsq_req_4_bits_exceptionVec_17
      (io_toMem_lsqEnqIO_req_4_bits_exceptionVec_17),
    .io_enqLsq_req_4_bits_exceptionVec_18
      (io_toMem_lsqEnqIO_req_4_bits_exceptionVec_18),
    .io_enqLsq_req_4_bits_exceptionVec_19
      (io_toMem_lsqEnqIO_req_4_bits_exceptionVec_19),
    .io_enqLsq_req_4_bits_exceptionVec_20
      (io_toMem_lsqEnqIO_req_4_bits_exceptionVec_20),
    .io_enqLsq_req_4_bits_exceptionVec_21
      (io_toMem_lsqEnqIO_req_4_bits_exceptionVec_21),
    .io_enqLsq_req_4_bits_exceptionVec_22
      (io_toMem_lsqEnqIO_req_4_bits_exceptionVec_22),
    .io_enqLsq_req_4_bits_exceptionVec_23
      (io_toMem_lsqEnqIO_req_4_bits_exceptionVec_23),
    .io_enqLsq_req_4_bits_trigger              (io_toMem_lsqEnqIO_req_4_bits_trigger),
    .io_enqLsq_req_4_bits_fuType               (io_toMem_lsqEnqIO_req_4_bits_fuType),
    .io_enqLsq_req_4_bits_fuOpType             (io_toMem_lsqEnqIO_req_4_bits_fuOpType),
    .io_enqLsq_req_4_bits_flushPipe            (io_toMem_lsqEnqIO_req_4_bits_flushPipe),
    .io_enqLsq_req_4_bits_uopIdx               (io_toMem_lsqEnqIO_req_4_bits_uopIdx),
    .io_enqLsq_req_4_bits_lastUop              (io_toMem_lsqEnqIO_req_4_bits_lastUop),
    .io_enqLsq_req_4_bits_robIdx_flag          (io_toMem_lsqEnqIO_req_4_bits_robIdx_flag),
    .io_enqLsq_req_4_bits_robIdx_value
      (io_toMem_lsqEnqIO_req_4_bits_robIdx_value),
    .io_enqLsq_req_4_bits_debugInfo_enqRsTime
      (io_toMem_lsqEnqIO_req_4_bits_debugInfo_enqRsTime),
    .io_enqLsq_req_4_bits_debugInfo_selectTime
      (io_toMem_lsqEnqIO_req_4_bits_debugInfo_selectTime),
    .io_enqLsq_req_4_bits_debugInfo_issueTime
      (io_toMem_lsqEnqIO_req_4_bits_debugInfo_issueTime),
    .io_enqLsq_req_4_bits_lqIdx_flag           (io_toMem_lsqEnqIO_req_4_bits_lqIdx_flag),
    .io_enqLsq_req_4_bits_lqIdx_value          (io_toMem_lsqEnqIO_req_4_bits_lqIdx_value),
    .io_enqLsq_req_4_bits_sqIdx_flag           (io_toMem_lsqEnqIO_req_4_bits_sqIdx_flag),
    .io_enqLsq_req_4_bits_sqIdx_value          (io_toMem_lsqEnqIO_req_4_bits_sqIdx_value),
    .io_enqLsq_req_4_bits_numLsElem            (io_toMem_lsqEnqIO_req_4_bits_numLsElem),
    .io_enqLsq_req_5_valid                     (io_toMem_lsqEnqIO_req_5_valid),
    .io_enqLsq_req_5_bits_exceptionVec_0
      (io_toMem_lsqEnqIO_req_5_bits_exceptionVec_0),
    .io_enqLsq_req_5_bits_exceptionVec_1
      (io_toMem_lsqEnqIO_req_5_bits_exceptionVec_1),
    .io_enqLsq_req_5_bits_exceptionVec_2
      (io_toMem_lsqEnqIO_req_5_bits_exceptionVec_2),
    .io_enqLsq_req_5_bits_exceptionVec_3
      (io_toMem_lsqEnqIO_req_5_bits_exceptionVec_3),
    .io_enqLsq_req_5_bits_exceptionVec_4
      (io_toMem_lsqEnqIO_req_5_bits_exceptionVec_4),
    .io_enqLsq_req_5_bits_exceptionVec_5
      (io_toMem_lsqEnqIO_req_5_bits_exceptionVec_5),
    .io_enqLsq_req_5_bits_exceptionVec_6
      (io_toMem_lsqEnqIO_req_5_bits_exceptionVec_6),
    .io_enqLsq_req_5_bits_exceptionVec_7
      (io_toMem_lsqEnqIO_req_5_bits_exceptionVec_7),
    .io_enqLsq_req_5_bits_exceptionVec_8
      (io_toMem_lsqEnqIO_req_5_bits_exceptionVec_8),
    .io_enqLsq_req_5_bits_exceptionVec_9
      (io_toMem_lsqEnqIO_req_5_bits_exceptionVec_9),
    .io_enqLsq_req_5_bits_exceptionVec_10
      (io_toMem_lsqEnqIO_req_5_bits_exceptionVec_10),
    .io_enqLsq_req_5_bits_exceptionVec_11
      (io_toMem_lsqEnqIO_req_5_bits_exceptionVec_11),
    .io_enqLsq_req_5_bits_exceptionVec_12
      (io_toMem_lsqEnqIO_req_5_bits_exceptionVec_12),
    .io_enqLsq_req_5_bits_exceptionVec_13
      (io_toMem_lsqEnqIO_req_5_bits_exceptionVec_13),
    .io_enqLsq_req_5_bits_exceptionVec_14
      (io_toMem_lsqEnqIO_req_5_bits_exceptionVec_14),
    .io_enqLsq_req_5_bits_exceptionVec_15
      (io_toMem_lsqEnqIO_req_5_bits_exceptionVec_15),
    .io_enqLsq_req_5_bits_exceptionVec_16
      (io_toMem_lsqEnqIO_req_5_bits_exceptionVec_16),
    .io_enqLsq_req_5_bits_exceptionVec_17
      (io_toMem_lsqEnqIO_req_5_bits_exceptionVec_17),
    .io_enqLsq_req_5_bits_exceptionVec_18
      (io_toMem_lsqEnqIO_req_5_bits_exceptionVec_18),
    .io_enqLsq_req_5_bits_exceptionVec_19
      (io_toMem_lsqEnqIO_req_5_bits_exceptionVec_19),
    .io_enqLsq_req_5_bits_exceptionVec_20
      (io_toMem_lsqEnqIO_req_5_bits_exceptionVec_20),
    .io_enqLsq_req_5_bits_exceptionVec_21
      (io_toMem_lsqEnqIO_req_5_bits_exceptionVec_21),
    .io_enqLsq_req_5_bits_exceptionVec_22
      (io_toMem_lsqEnqIO_req_5_bits_exceptionVec_22),
    .io_enqLsq_req_5_bits_exceptionVec_23
      (io_toMem_lsqEnqIO_req_5_bits_exceptionVec_23),
    .io_enqLsq_req_5_bits_trigger              (io_toMem_lsqEnqIO_req_5_bits_trigger),
    .io_enqLsq_req_5_bits_fuType               (io_toMem_lsqEnqIO_req_5_bits_fuType),
    .io_enqLsq_req_5_bits_fuOpType             (io_toMem_lsqEnqIO_req_5_bits_fuOpType),
    .io_enqLsq_req_5_bits_flushPipe            (io_toMem_lsqEnqIO_req_5_bits_flushPipe),
    .io_enqLsq_req_5_bits_uopIdx               (io_toMem_lsqEnqIO_req_5_bits_uopIdx),
    .io_enqLsq_req_5_bits_lastUop              (io_toMem_lsqEnqIO_req_5_bits_lastUop),
    .io_enqLsq_req_5_bits_robIdx_flag          (io_toMem_lsqEnqIO_req_5_bits_robIdx_flag),
    .io_enqLsq_req_5_bits_robIdx_value
      (io_toMem_lsqEnqIO_req_5_bits_robIdx_value),
    .io_enqLsq_req_5_bits_debugInfo_enqRsTime
      (io_toMem_lsqEnqIO_req_5_bits_debugInfo_enqRsTime),
    .io_enqLsq_req_5_bits_debugInfo_selectTime
      (io_toMem_lsqEnqIO_req_5_bits_debugInfo_selectTime),
    .io_enqLsq_req_5_bits_debugInfo_issueTime
      (io_toMem_lsqEnqIO_req_5_bits_debugInfo_issueTime),
    .io_enqLsq_req_5_bits_lqIdx_flag           (io_toMem_lsqEnqIO_req_5_bits_lqIdx_flag),
    .io_enqLsq_req_5_bits_lqIdx_value          (io_toMem_lsqEnqIO_req_5_bits_lqIdx_value),
    .io_enqLsq_req_5_bits_sqIdx_flag           (io_toMem_lsqEnqIO_req_5_bits_sqIdx_flag),
    .io_enqLsq_req_5_bits_sqIdx_value          (io_toMem_lsqEnqIO_req_5_bits_sqIdx_value),
    .io_enqLsq_req_5_bits_numLsElem            (io_toMem_lsqEnqIO_req_5_bits_numLsElem)
  );

  // ---- 34 个发射队列 enq 端口输出:对每端口 oh = uopSelIQMatrix[i][iq]==enq+1,
  //      在 6 条 uop 中 PriorityMux 选源(四来源:RENAME/UPDATE/SRCSTATE/SUBMOD)。
  // -- 端口 0(IQ 0 enq 0)--
  assign io_toIssueQueues_0_valid = (ohSel[0][0] ? fromRenameUpdate_valid[0] : (ohSel[0][1] ? fromRenameUpdate_valid[1] : (ohSel[0][2] ? fromRenameUpdate_valid[2] : (ohSel[0][3] ? fromRenameUpdate_valid[3] : (ohSel[0][4] ? fromRenameUpdate_valid[4] : (ohSel[0][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_0_bits_preDecodeInfo_isRVC = (ohSel[0][0] ? io_fromRename_0_bits_preDecodeInfo_isRVC : (ohSel[0][1] ? io_fromRename_1_bits_preDecodeInfo_isRVC : (ohSel[0][2] ? io_fromRename_2_bits_preDecodeInfo_isRVC : (ohSel[0][3] ? io_fromRename_3_bits_preDecodeInfo_isRVC : (ohSel[0][4] ? io_fromRename_4_bits_preDecodeInfo_isRVC : io_fromRename_5_bits_preDecodeInfo_isRVC)))));
  assign io_toIssueQueues_0_bits_pred_taken = (ohSel[0][0] ? io_fromRename_0_bits_pred_taken : (ohSel[0][1] ? io_fromRename_1_bits_pred_taken : (ohSel[0][2] ? io_fromRename_2_bits_pred_taken : (ohSel[0][3] ? io_fromRename_3_bits_pred_taken : (ohSel[0][4] ? io_fromRename_4_bits_pred_taken : io_fromRename_5_bits_pred_taken)))));
  assign io_toIssueQueues_0_bits_ftqPtr_flag = (ohSel[0][0] ? io_fromRename_0_bits_ftqPtr_flag : (ohSel[0][1] ? io_fromRename_1_bits_ftqPtr_flag : (ohSel[0][2] ? io_fromRename_2_bits_ftqPtr_flag : (ohSel[0][3] ? io_fromRename_3_bits_ftqPtr_flag : (ohSel[0][4] ? io_fromRename_4_bits_ftqPtr_flag : io_fromRename_5_bits_ftqPtr_flag)))));
  assign io_toIssueQueues_0_bits_ftqPtr_value = (ohSel[0][0] ? io_fromRename_0_bits_ftqPtr_value : (ohSel[0][1] ? io_fromRename_1_bits_ftqPtr_value : (ohSel[0][2] ? io_fromRename_2_bits_ftqPtr_value : (ohSel[0][3] ? io_fromRename_3_bits_ftqPtr_value : (ohSel[0][4] ? io_fromRename_4_bits_ftqPtr_value : io_fromRename_5_bits_ftqPtr_value)))));
  assign io_toIssueQueues_0_bits_ftqOffset = (ohSel[0][0] ? io_fromRename_0_bits_ftqOffset : (ohSel[0][1] ? io_fromRename_1_bits_ftqOffset : (ohSel[0][2] ? io_fromRename_2_bits_ftqOffset : (ohSel[0][3] ? io_fromRename_3_bits_ftqOffset : (ohSel[0][4] ? io_fromRename_4_bits_ftqOffset : io_fromRename_5_bits_ftqOffset)))));
  assign io_toIssueQueues_0_bits_srcType_0 = (ohSel[0][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[0][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[0][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[0][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[0][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_0_bits_srcType_1 = (ohSel[0][0] ? io_fromRename_0_bits_srcType_1 : (ohSel[0][1] ? io_fromRename_1_bits_srcType_1 : (ohSel[0][2] ? io_fromRename_2_bits_srcType_1 : (ohSel[0][3] ? io_fromRename_3_bits_srcType_1 : (ohSel[0][4] ? io_fromRename_4_bits_srcType_1 : io_fromRename_5_bits_srcType_1)))));
  assign io_toIssueQueues_0_bits_fuType = (ohSel[0][0] ? io_fromRename_0_bits_fuType : (ohSel[0][1] ? io_fromRename_1_bits_fuType : (ohSel[0][2] ? io_fromRename_2_bits_fuType : (ohSel[0][3] ? io_fromRename_3_bits_fuType : (ohSel[0][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_0_bits_fuOpType = (ohSel[0][0] ? io_fromRename_0_bits_fuOpType : (ohSel[0][1] ? io_fromRename_1_bits_fuOpType : (ohSel[0][2] ? io_fromRename_2_bits_fuOpType : (ohSel[0][3] ? io_fromRename_3_bits_fuOpType : (ohSel[0][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_0_bits_rfWen = (ohSel[0][0] ? io_fromRename_0_bits_rfWen : (ohSel[0][1] ? io_fromRename_1_bits_rfWen : (ohSel[0][2] ? io_fromRename_2_bits_rfWen : (ohSel[0][3] ? io_fromRename_3_bits_rfWen : (ohSel[0][4] ? io_fromRename_4_bits_rfWen : io_fromRename_5_bits_rfWen)))));
  assign io_toIssueQueues_0_bits_selImm = (ohSel[0][0] ? io_fromRename_0_bits_selImm : (ohSel[0][1] ? io_fromRename_1_bits_selImm : (ohSel[0][2] ? io_fromRename_2_bits_selImm : (ohSel[0][3] ? io_fromRename_3_bits_selImm : (ohSel[0][4] ? io_fromRename_4_bits_selImm : io_fromRename_5_bits_selImm)))));
  assign io_toIssueQueues_0_bits_imm = (ohSel[0][0] ? io_fromRename_0_bits_imm : (ohSel[0][1] ? io_fromRename_1_bits_imm : (ohSel[0][2] ? io_fromRename_2_bits_imm : (ohSel[0][3] ? io_fromRename_3_bits_imm : (ohSel[0][4] ? io_fromRename_4_bits_imm : io_fromRename_5_bits_imm)))));
  assign io_toIssueQueues_0_bits_srcState_0 = (ohSel[0][0] ? (allSrcState[0][0][0]) : (ohSel[0][1] ? (allSrcState[1][0][0]) : (ohSel[0][2] ? (allSrcState[2][0][0]) : (ohSel[0][3] ? (allSrcState[3][0][0]) : (ohSel[0][4] ? (allSrcState[4][0][0]) : (allSrcState[5][0][0]))))));
  assign io_toIssueQueues_0_bits_srcState_1 = (ohSel[0][0] ? (allSrcState[0][1][0]) : (ohSel[0][1] ? (allSrcState[1][1][0]) : (ohSel[0][2] ? (allSrcState[2][1][0]) : (ohSel[0][3] ? (allSrcState[3][1][0]) : (ohSel[0][4] ? (allSrcState[4][1][0]) : (allSrcState[5][1][0]))))));
  assign io_toIssueQueues_0_bits_srcLoadDependency_0_0 = (ohSel[0][0] ? fru_srcLoadDep[0][0][0] : (ohSel[0][1] ? fru_srcLoadDep[1][0][0] : (ohSel[0][2] ? fru_srcLoadDep[2][0][0] : (ohSel[0][3] ? fru_srcLoadDep[3][0][0] : (ohSel[0][4] ? fru_srcLoadDep[4][0][0] : fru_srcLoadDep[5][0][0])))));
  assign io_toIssueQueues_0_bits_srcLoadDependency_0_1 = (ohSel[0][0] ? fru_srcLoadDep[0][0][1] : (ohSel[0][1] ? fru_srcLoadDep[1][0][1] : (ohSel[0][2] ? fru_srcLoadDep[2][0][1] : (ohSel[0][3] ? fru_srcLoadDep[3][0][1] : (ohSel[0][4] ? fru_srcLoadDep[4][0][1] : fru_srcLoadDep[5][0][1])))));
  assign io_toIssueQueues_0_bits_srcLoadDependency_0_2 = (ohSel[0][0] ? fru_srcLoadDep[0][0][2] : (ohSel[0][1] ? fru_srcLoadDep[1][0][2] : (ohSel[0][2] ? fru_srcLoadDep[2][0][2] : (ohSel[0][3] ? fru_srcLoadDep[3][0][2] : (ohSel[0][4] ? fru_srcLoadDep[4][0][2] : fru_srcLoadDep[5][0][2])))));
  assign io_toIssueQueues_0_bits_srcLoadDependency_1_0 = (ohSel[0][0] ? fru_srcLoadDep[0][1][0] : (ohSel[0][1] ? fru_srcLoadDep[1][1][0] : (ohSel[0][2] ? fru_srcLoadDep[2][1][0] : (ohSel[0][3] ? fru_srcLoadDep[3][1][0] : (ohSel[0][4] ? fru_srcLoadDep[4][1][0] : fru_srcLoadDep[5][1][0])))));
  assign io_toIssueQueues_0_bits_srcLoadDependency_1_1 = (ohSel[0][0] ? fru_srcLoadDep[0][1][1] : (ohSel[0][1] ? fru_srcLoadDep[1][1][1] : (ohSel[0][2] ? fru_srcLoadDep[2][1][1] : (ohSel[0][3] ? fru_srcLoadDep[3][1][1] : (ohSel[0][4] ? fru_srcLoadDep[4][1][1] : fru_srcLoadDep[5][1][1])))));
  assign io_toIssueQueues_0_bits_srcLoadDependency_1_2 = (ohSel[0][0] ? fru_srcLoadDep[0][1][2] : (ohSel[0][1] ? fru_srcLoadDep[1][1][2] : (ohSel[0][2] ? fru_srcLoadDep[2][1][2] : (ohSel[0][3] ? fru_srcLoadDep[3][1][2] : (ohSel[0][4] ? fru_srcLoadDep[4][1][2] : fru_srcLoadDep[5][1][2])))));
  assign io_toIssueQueues_0_bits_psrc_0 = (ohSel[0][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[0][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[0][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[0][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[0][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_0_bits_psrc_1 = (ohSel[0][0] ? io_fromRename_0_bits_psrc_1 : (ohSel[0][1] ? io_fromRename_1_bits_psrc_1 : (ohSel[0][2] ? io_fromRename_2_bits_psrc_1 : (ohSel[0][3] ? io_fromRename_3_bits_psrc_1 : (ohSel[0][4] ? io_fromRename_4_bits_psrc_1 : io_fromRename_5_bits_psrc_1)))));
  assign io_toIssueQueues_0_bits_pdest = (ohSel[0][0] ? io_fromRename_0_bits_pdest : (ohSel[0][1] ? io_fromRename_1_bits_pdest : (ohSel[0][2] ? io_fromRename_2_bits_pdest : (ohSel[0][3] ? io_fromRename_3_bits_pdest : (ohSel[0][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_0_bits_useRegCache_0 = (ohSel[0][0] ? _rcTagTable_io_readPorts_0_valid : (ohSel[0][1] ? _rcTagTable_io_readPorts_2_valid : (ohSel[0][2] ? _rcTagTable_io_readPorts_4_valid : (ohSel[0][3] ? _rcTagTable_io_readPorts_6_valid : (ohSel[0][4] ? _rcTagTable_io_readPorts_8_valid : _rcTagTable_io_readPorts_10_valid)))));
  assign io_toIssueQueues_0_bits_useRegCache_1 = (ohSel[0][0] ? _rcTagTable_io_readPorts_1_valid : (ohSel[0][1] ? _rcTagTable_io_readPorts_3_valid : (ohSel[0][2] ? _rcTagTable_io_readPorts_5_valid : (ohSel[0][3] ? _rcTagTable_io_readPorts_7_valid : (ohSel[0][4] ? _rcTagTable_io_readPorts_9_valid : _rcTagTable_io_readPorts_11_valid)))));
  assign io_toIssueQueues_0_bits_regCacheIdx_0 = (ohSel[0][0] ? _rcTagTable_io_readPorts_0_addr : (ohSel[0][1] ? _rcTagTable_io_readPorts_2_addr : (ohSel[0][2] ? _rcTagTable_io_readPorts_4_addr : (ohSel[0][3] ? _rcTagTable_io_readPorts_6_addr : (ohSel[0][4] ? _rcTagTable_io_readPorts_8_addr : _rcTagTable_io_readPorts_10_addr)))));
  assign io_toIssueQueues_0_bits_regCacheIdx_1 = (ohSel[0][0] ? _rcTagTable_io_readPorts_1_addr : (ohSel[0][1] ? _rcTagTable_io_readPorts_3_addr : (ohSel[0][2] ? _rcTagTable_io_readPorts_5_addr : (ohSel[0][3] ? _rcTagTable_io_readPorts_7_addr : (ohSel[0][4] ? _rcTagTable_io_readPorts_9_addr : _rcTagTable_io_readPorts_11_addr)))));
  assign io_toIssueQueues_0_bits_robIdx_flag = (ohSel[0][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[0][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[0][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[0][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[0][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_0_bits_robIdx_value = (ohSel[0][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[0][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[0][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[0][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[0][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  // -- 端口 1(IQ 0 enq 1)--
  assign io_toIssueQueues_1_valid = (ohSel[1][0] ? fromRenameUpdate_valid[0] : (ohSel[1][1] ? fromRenameUpdate_valid[1] : (ohSel[1][2] ? fromRenameUpdate_valid[2] : (ohSel[1][3] ? fromRenameUpdate_valid[3] : (ohSel[1][4] ? fromRenameUpdate_valid[4] : (ohSel[1][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_1_bits_preDecodeInfo_isRVC = (ohSel[1][0] ? io_fromRename_0_bits_preDecodeInfo_isRVC : (ohSel[1][1] ? io_fromRename_1_bits_preDecodeInfo_isRVC : (ohSel[1][2] ? io_fromRename_2_bits_preDecodeInfo_isRVC : (ohSel[1][3] ? io_fromRename_3_bits_preDecodeInfo_isRVC : (ohSel[1][4] ? io_fromRename_4_bits_preDecodeInfo_isRVC : io_fromRename_5_bits_preDecodeInfo_isRVC)))));
  assign io_toIssueQueues_1_bits_pred_taken = (ohSel[1][0] ? io_fromRename_0_bits_pred_taken : (ohSel[1][1] ? io_fromRename_1_bits_pred_taken : (ohSel[1][2] ? io_fromRename_2_bits_pred_taken : (ohSel[1][3] ? io_fromRename_3_bits_pred_taken : (ohSel[1][4] ? io_fromRename_4_bits_pred_taken : io_fromRename_5_bits_pred_taken)))));
  assign io_toIssueQueues_1_bits_ftqPtr_flag = (ohSel[1][0] ? io_fromRename_0_bits_ftqPtr_flag : (ohSel[1][1] ? io_fromRename_1_bits_ftqPtr_flag : (ohSel[1][2] ? io_fromRename_2_bits_ftqPtr_flag : (ohSel[1][3] ? io_fromRename_3_bits_ftqPtr_flag : (ohSel[1][4] ? io_fromRename_4_bits_ftqPtr_flag : io_fromRename_5_bits_ftqPtr_flag)))));
  assign io_toIssueQueues_1_bits_ftqPtr_value = (ohSel[1][0] ? io_fromRename_0_bits_ftqPtr_value : (ohSel[1][1] ? io_fromRename_1_bits_ftqPtr_value : (ohSel[1][2] ? io_fromRename_2_bits_ftqPtr_value : (ohSel[1][3] ? io_fromRename_3_bits_ftqPtr_value : (ohSel[1][4] ? io_fromRename_4_bits_ftqPtr_value : io_fromRename_5_bits_ftqPtr_value)))));
  assign io_toIssueQueues_1_bits_ftqOffset = (ohSel[1][0] ? io_fromRename_0_bits_ftqOffset : (ohSel[1][1] ? io_fromRename_1_bits_ftqOffset : (ohSel[1][2] ? io_fromRename_2_bits_ftqOffset : (ohSel[1][3] ? io_fromRename_3_bits_ftqOffset : (ohSel[1][4] ? io_fromRename_4_bits_ftqOffset : io_fromRename_5_bits_ftqOffset)))));
  assign io_toIssueQueues_1_bits_srcType_0 = (ohSel[1][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[1][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[1][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[1][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[1][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_1_bits_srcType_1 = (ohSel[1][0] ? io_fromRename_0_bits_srcType_1 : (ohSel[1][1] ? io_fromRename_1_bits_srcType_1 : (ohSel[1][2] ? io_fromRename_2_bits_srcType_1 : (ohSel[1][3] ? io_fromRename_3_bits_srcType_1 : (ohSel[1][4] ? io_fromRename_4_bits_srcType_1 : io_fromRename_5_bits_srcType_1)))));
  assign io_toIssueQueues_1_bits_fuType = (ohSel[1][0] ? io_fromRename_0_bits_fuType : (ohSel[1][1] ? io_fromRename_1_bits_fuType : (ohSel[1][2] ? io_fromRename_2_bits_fuType : (ohSel[1][3] ? io_fromRename_3_bits_fuType : (ohSel[1][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_1_bits_fuOpType = (ohSel[1][0] ? io_fromRename_0_bits_fuOpType : (ohSel[1][1] ? io_fromRename_1_bits_fuOpType : (ohSel[1][2] ? io_fromRename_2_bits_fuOpType : (ohSel[1][3] ? io_fromRename_3_bits_fuOpType : (ohSel[1][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_1_bits_rfWen = (ohSel[1][0] ? io_fromRename_0_bits_rfWen : (ohSel[1][1] ? io_fromRename_1_bits_rfWen : (ohSel[1][2] ? io_fromRename_2_bits_rfWen : (ohSel[1][3] ? io_fromRename_3_bits_rfWen : (ohSel[1][4] ? io_fromRename_4_bits_rfWen : io_fromRename_5_bits_rfWen)))));
  assign io_toIssueQueues_1_bits_selImm = (ohSel[1][0] ? io_fromRename_0_bits_selImm : (ohSel[1][1] ? io_fromRename_1_bits_selImm : (ohSel[1][2] ? io_fromRename_2_bits_selImm : (ohSel[1][3] ? io_fromRename_3_bits_selImm : (ohSel[1][4] ? io_fromRename_4_bits_selImm : io_fromRename_5_bits_selImm)))));
  assign io_toIssueQueues_1_bits_imm = (ohSel[1][0] ? io_fromRename_0_bits_imm : (ohSel[1][1] ? io_fromRename_1_bits_imm : (ohSel[1][2] ? io_fromRename_2_bits_imm : (ohSel[1][3] ? io_fromRename_3_bits_imm : (ohSel[1][4] ? io_fromRename_4_bits_imm : io_fromRename_5_bits_imm)))));
  assign io_toIssueQueues_1_bits_srcState_0 = (ohSel[1][0] ? (allSrcState[0][0][0]) : (ohSel[1][1] ? (allSrcState[1][0][0]) : (ohSel[1][2] ? (allSrcState[2][0][0]) : (ohSel[1][3] ? (allSrcState[3][0][0]) : (ohSel[1][4] ? (allSrcState[4][0][0]) : (allSrcState[5][0][0]))))));
  assign io_toIssueQueues_1_bits_srcState_1 = (ohSel[1][0] ? (allSrcState[0][1][0]) : (ohSel[1][1] ? (allSrcState[1][1][0]) : (ohSel[1][2] ? (allSrcState[2][1][0]) : (ohSel[1][3] ? (allSrcState[3][1][0]) : (ohSel[1][4] ? (allSrcState[4][1][0]) : (allSrcState[5][1][0]))))));
  assign io_toIssueQueues_1_bits_srcLoadDependency_0_0 = (ohSel[1][0] ? fru_srcLoadDep[0][0][0] : (ohSel[1][1] ? fru_srcLoadDep[1][0][0] : (ohSel[1][2] ? fru_srcLoadDep[2][0][0] : (ohSel[1][3] ? fru_srcLoadDep[3][0][0] : (ohSel[1][4] ? fru_srcLoadDep[4][0][0] : fru_srcLoadDep[5][0][0])))));
  assign io_toIssueQueues_1_bits_srcLoadDependency_0_1 = (ohSel[1][0] ? fru_srcLoadDep[0][0][1] : (ohSel[1][1] ? fru_srcLoadDep[1][0][1] : (ohSel[1][2] ? fru_srcLoadDep[2][0][1] : (ohSel[1][3] ? fru_srcLoadDep[3][0][1] : (ohSel[1][4] ? fru_srcLoadDep[4][0][1] : fru_srcLoadDep[5][0][1])))));
  assign io_toIssueQueues_1_bits_srcLoadDependency_0_2 = (ohSel[1][0] ? fru_srcLoadDep[0][0][2] : (ohSel[1][1] ? fru_srcLoadDep[1][0][2] : (ohSel[1][2] ? fru_srcLoadDep[2][0][2] : (ohSel[1][3] ? fru_srcLoadDep[3][0][2] : (ohSel[1][4] ? fru_srcLoadDep[4][0][2] : fru_srcLoadDep[5][0][2])))));
  assign io_toIssueQueues_1_bits_srcLoadDependency_1_0 = (ohSel[1][0] ? fru_srcLoadDep[0][1][0] : (ohSel[1][1] ? fru_srcLoadDep[1][1][0] : (ohSel[1][2] ? fru_srcLoadDep[2][1][0] : (ohSel[1][3] ? fru_srcLoadDep[3][1][0] : (ohSel[1][4] ? fru_srcLoadDep[4][1][0] : fru_srcLoadDep[5][1][0])))));
  assign io_toIssueQueues_1_bits_srcLoadDependency_1_1 = (ohSel[1][0] ? fru_srcLoadDep[0][1][1] : (ohSel[1][1] ? fru_srcLoadDep[1][1][1] : (ohSel[1][2] ? fru_srcLoadDep[2][1][1] : (ohSel[1][3] ? fru_srcLoadDep[3][1][1] : (ohSel[1][4] ? fru_srcLoadDep[4][1][1] : fru_srcLoadDep[5][1][1])))));
  assign io_toIssueQueues_1_bits_srcLoadDependency_1_2 = (ohSel[1][0] ? fru_srcLoadDep[0][1][2] : (ohSel[1][1] ? fru_srcLoadDep[1][1][2] : (ohSel[1][2] ? fru_srcLoadDep[2][1][2] : (ohSel[1][3] ? fru_srcLoadDep[3][1][2] : (ohSel[1][4] ? fru_srcLoadDep[4][1][2] : fru_srcLoadDep[5][1][2])))));
  assign io_toIssueQueues_1_bits_psrc_0 = (ohSel[1][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[1][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[1][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[1][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[1][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_1_bits_psrc_1 = (ohSel[1][0] ? io_fromRename_0_bits_psrc_1 : (ohSel[1][1] ? io_fromRename_1_bits_psrc_1 : (ohSel[1][2] ? io_fromRename_2_bits_psrc_1 : (ohSel[1][3] ? io_fromRename_3_bits_psrc_1 : (ohSel[1][4] ? io_fromRename_4_bits_psrc_1 : io_fromRename_5_bits_psrc_1)))));
  assign io_toIssueQueues_1_bits_pdest = (ohSel[1][0] ? io_fromRename_0_bits_pdest : (ohSel[1][1] ? io_fromRename_1_bits_pdest : (ohSel[1][2] ? io_fromRename_2_bits_pdest : (ohSel[1][3] ? io_fromRename_3_bits_pdest : (ohSel[1][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_1_bits_useRegCache_0 = (ohSel[1][0] ? _rcTagTable_io_readPorts_0_valid : (ohSel[1][1] ? _rcTagTable_io_readPorts_2_valid : (ohSel[1][2] ? _rcTagTable_io_readPorts_4_valid : (ohSel[1][3] ? _rcTagTable_io_readPorts_6_valid : (ohSel[1][4] ? _rcTagTable_io_readPorts_8_valid : _rcTagTable_io_readPorts_10_valid)))));
  assign io_toIssueQueues_1_bits_useRegCache_1 = (ohSel[1][0] ? _rcTagTable_io_readPorts_1_valid : (ohSel[1][1] ? _rcTagTable_io_readPorts_3_valid : (ohSel[1][2] ? _rcTagTable_io_readPorts_5_valid : (ohSel[1][3] ? _rcTagTable_io_readPorts_7_valid : (ohSel[1][4] ? _rcTagTable_io_readPorts_9_valid : _rcTagTable_io_readPorts_11_valid)))));
  assign io_toIssueQueues_1_bits_regCacheIdx_0 = (ohSel[1][0] ? _rcTagTable_io_readPorts_0_addr : (ohSel[1][1] ? _rcTagTable_io_readPorts_2_addr : (ohSel[1][2] ? _rcTagTable_io_readPorts_4_addr : (ohSel[1][3] ? _rcTagTable_io_readPorts_6_addr : (ohSel[1][4] ? _rcTagTable_io_readPorts_8_addr : _rcTagTable_io_readPorts_10_addr)))));
  assign io_toIssueQueues_1_bits_regCacheIdx_1 = (ohSel[1][0] ? _rcTagTable_io_readPorts_1_addr : (ohSel[1][1] ? _rcTagTable_io_readPorts_3_addr : (ohSel[1][2] ? _rcTagTable_io_readPorts_5_addr : (ohSel[1][3] ? _rcTagTable_io_readPorts_7_addr : (ohSel[1][4] ? _rcTagTable_io_readPorts_9_addr : _rcTagTable_io_readPorts_11_addr)))));
  assign io_toIssueQueues_1_bits_robIdx_flag = (ohSel[1][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[1][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[1][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[1][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[1][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_1_bits_robIdx_value = (ohSel[1][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[1][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[1][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[1][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[1][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  // -- 端口 2(IQ 1 enq 0)--
  assign io_toIssueQueues_2_valid = (ohSel[2][0] ? fromRenameUpdate_valid[0] : (ohSel[2][1] ? fromRenameUpdate_valid[1] : (ohSel[2][2] ? fromRenameUpdate_valid[2] : (ohSel[2][3] ? fromRenameUpdate_valid[3] : (ohSel[2][4] ? fromRenameUpdate_valid[4] : (ohSel[2][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_2_bits_preDecodeInfo_isRVC = (ohSel[2][0] ? io_fromRename_0_bits_preDecodeInfo_isRVC : (ohSel[2][1] ? io_fromRename_1_bits_preDecodeInfo_isRVC : (ohSel[2][2] ? io_fromRename_2_bits_preDecodeInfo_isRVC : (ohSel[2][3] ? io_fromRename_3_bits_preDecodeInfo_isRVC : (ohSel[2][4] ? io_fromRename_4_bits_preDecodeInfo_isRVC : io_fromRename_5_bits_preDecodeInfo_isRVC)))));
  assign io_toIssueQueues_2_bits_pred_taken = (ohSel[2][0] ? io_fromRename_0_bits_pred_taken : (ohSel[2][1] ? io_fromRename_1_bits_pred_taken : (ohSel[2][2] ? io_fromRename_2_bits_pred_taken : (ohSel[2][3] ? io_fromRename_3_bits_pred_taken : (ohSel[2][4] ? io_fromRename_4_bits_pred_taken : io_fromRename_5_bits_pred_taken)))));
  assign io_toIssueQueues_2_bits_ftqPtr_flag = (ohSel[2][0] ? io_fromRename_0_bits_ftqPtr_flag : (ohSel[2][1] ? io_fromRename_1_bits_ftqPtr_flag : (ohSel[2][2] ? io_fromRename_2_bits_ftqPtr_flag : (ohSel[2][3] ? io_fromRename_3_bits_ftqPtr_flag : (ohSel[2][4] ? io_fromRename_4_bits_ftqPtr_flag : io_fromRename_5_bits_ftqPtr_flag)))));
  assign io_toIssueQueues_2_bits_ftqPtr_value = (ohSel[2][0] ? io_fromRename_0_bits_ftqPtr_value : (ohSel[2][1] ? io_fromRename_1_bits_ftqPtr_value : (ohSel[2][2] ? io_fromRename_2_bits_ftqPtr_value : (ohSel[2][3] ? io_fromRename_3_bits_ftqPtr_value : (ohSel[2][4] ? io_fromRename_4_bits_ftqPtr_value : io_fromRename_5_bits_ftqPtr_value)))));
  assign io_toIssueQueues_2_bits_ftqOffset = (ohSel[2][0] ? io_fromRename_0_bits_ftqOffset : (ohSel[2][1] ? io_fromRename_1_bits_ftqOffset : (ohSel[2][2] ? io_fromRename_2_bits_ftqOffset : (ohSel[2][3] ? io_fromRename_3_bits_ftqOffset : (ohSel[2][4] ? io_fromRename_4_bits_ftqOffset : io_fromRename_5_bits_ftqOffset)))));
  assign io_toIssueQueues_2_bits_srcType_0 = (ohSel[2][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[2][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[2][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[2][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[2][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_2_bits_srcType_1 = (ohSel[2][0] ? io_fromRename_0_bits_srcType_1 : (ohSel[2][1] ? io_fromRename_1_bits_srcType_1 : (ohSel[2][2] ? io_fromRename_2_bits_srcType_1 : (ohSel[2][3] ? io_fromRename_3_bits_srcType_1 : (ohSel[2][4] ? io_fromRename_4_bits_srcType_1 : io_fromRename_5_bits_srcType_1)))));
  assign io_toIssueQueues_2_bits_fuType = (ohSel[2][0] ? io_fromRename_0_bits_fuType : (ohSel[2][1] ? io_fromRename_1_bits_fuType : (ohSel[2][2] ? io_fromRename_2_bits_fuType : (ohSel[2][3] ? io_fromRename_3_bits_fuType : (ohSel[2][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_2_bits_fuOpType = (ohSel[2][0] ? io_fromRename_0_bits_fuOpType : (ohSel[2][1] ? io_fromRename_1_bits_fuOpType : (ohSel[2][2] ? io_fromRename_2_bits_fuOpType : (ohSel[2][3] ? io_fromRename_3_bits_fuOpType : (ohSel[2][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_2_bits_rfWen = (ohSel[2][0] ? io_fromRename_0_bits_rfWen : (ohSel[2][1] ? io_fromRename_1_bits_rfWen : (ohSel[2][2] ? io_fromRename_2_bits_rfWen : (ohSel[2][3] ? io_fromRename_3_bits_rfWen : (ohSel[2][4] ? io_fromRename_4_bits_rfWen : io_fromRename_5_bits_rfWen)))));
  assign io_toIssueQueues_2_bits_selImm = (ohSel[2][0] ? io_fromRename_0_bits_selImm : (ohSel[2][1] ? io_fromRename_1_bits_selImm : (ohSel[2][2] ? io_fromRename_2_bits_selImm : (ohSel[2][3] ? io_fromRename_3_bits_selImm : (ohSel[2][4] ? io_fromRename_4_bits_selImm : io_fromRename_5_bits_selImm)))));
  assign io_toIssueQueues_2_bits_imm = (ohSel[2][0] ? io_fromRename_0_bits_imm : (ohSel[2][1] ? io_fromRename_1_bits_imm : (ohSel[2][2] ? io_fromRename_2_bits_imm : (ohSel[2][3] ? io_fromRename_3_bits_imm : (ohSel[2][4] ? io_fromRename_4_bits_imm : io_fromRename_5_bits_imm)))));
  assign io_toIssueQueues_2_bits_srcState_0 = (ohSel[2][0] ? (allSrcState[0][0][0]) : (ohSel[2][1] ? (allSrcState[1][0][0]) : (ohSel[2][2] ? (allSrcState[2][0][0]) : (ohSel[2][3] ? (allSrcState[3][0][0]) : (ohSel[2][4] ? (allSrcState[4][0][0]) : (allSrcState[5][0][0]))))));
  assign io_toIssueQueues_2_bits_srcState_1 = (ohSel[2][0] ? (allSrcState[0][1][0]) : (ohSel[2][1] ? (allSrcState[1][1][0]) : (ohSel[2][2] ? (allSrcState[2][1][0]) : (ohSel[2][3] ? (allSrcState[3][1][0]) : (ohSel[2][4] ? (allSrcState[4][1][0]) : (allSrcState[5][1][0]))))));
  assign io_toIssueQueues_2_bits_srcLoadDependency_0_0 = (ohSel[2][0] ? fru_srcLoadDep[0][0][0] : (ohSel[2][1] ? fru_srcLoadDep[1][0][0] : (ohSel[2][2] ? fru_srcLoadDep[2][0][0] : (ohSel[2][3] ? fru_srcLoadDep[3][0][0] : (ohSel[2][4] ? fru_srcLoadDep[4][0][0] : fru_srcLoadDep[5][0][0])))));
  assign io_toIssueQueues_2_bits_srcLoadDependency_0_1 = (ohSel[2][0] ? fru_srcLoadDep[0][0][1] : (ohSel[2][1] ? fru_srcLoadDep[1][0][1] : (ohSel[2][2] ? fru_srcLoadDep[2][0][1] : (ohSel[2][3] ? fru_srcLoadDep[3][0][1] : (ohSel[2][4] ? fru_srcLoadDep[4][0][1] : fru_srcLoadDep[5][0][1])))));
  assign io_toIssueQueues_2_bits_srcLoadDependency_0_2 = (ohSel[2][0] ? fru_srcLoadDep[0][0][2] : (ohSel[2][1] ? fru_srcLoadDep[1][0][2] : (ohSel[2][2] ? fru_srcLoadDep[2][0][2] : (ohSel[2][3] ? fru_srcLoadDep[3][0][2] : (ohSel[2][4] ? fru_srcLoadDep[4][0][2] : fru_srcLoadDep[5][0][2])))));
  assign io_toIssueQueues_2_bits_srcLoadDependency_1_0 = (ohSel[2][0] ? fru_srcLoadDep[0][1][0] : (ohSel[2][1] ? fru_srcLoadDep[1][1][0] : (ohSel[2][2] ? fru_srcLoadDep[2][1][0] : (ohSel[2][3] ? fru_srcLoadDep[3][1][0] : (ohSel[2][4] ? fru_srcLoadDep[4][1][0] : fru_srcLoadDep[5][1][0])))));
  assign io_toIssueQueues_2_bits_srcLoadDependency_1_1 = (ohSel[2][0] ? fru_srcLoadDep[0][1][1] : (ohSel[2][1] ? fru_srcLoadDep[1][1][1] : (ohSel[2][2] ? fru_srcLoadDep[2][1][1] : (ohSel[2][3] ? fru_srcLoadDep[3][1][1] : (ohSel[2][4] ? fru_srcLoadDep[4][1][1] : fru_srcLoadDep[5][1][1])))));
  assign io_toIssueQueues_2_bits_srcLoadDependency_1_2 = (ohSel[2][0] ? fru_srcLoadDep[0][1][2] : (ohSel[2][1] ? fru_srcLoadDep[1][1][2] : (ohSel[2][2] ? fru_srcLoadDep[2][1][2] : (ohSel[2][3] ? fru_srcLoadDep[3][1][2] : (ohSel[2][4] ? fru_srcLoadDep[4][1][2] : fru_srcLoadDep[5][1][2])))));
  assign io_toIssueQueues_2_bits_psrc_0 = (ohSel[2][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[2][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[2][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[2][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[2][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_2_bits_psrc_1 = (ohSel[2][0] ? io_fromRename_0_bits_psrc_1 : (ohSel[2][1] ? io_fromRename_1_bits_psrc_1 : (ohSel[2][2] ? io_fromRename_2_bits_psrc_1 : (ohSel[2][3] ? io_fromRename_3_bits_psrc_1 : (ohSel[2][4] ? io_fromRename_4_bits_psrc_1 : io_fromRename_5_bits_psrc_1)))));
  assign io_toIssueQueues_2_bits_pdest = (ohSel[2][0] ? io_fromRename_0_bits_pdest : (ohSel[2][1] ? io_fromRename_1_bits_pdest : (ohSel[2][2] ? io_fromRename_2_bits_pdest : (ohSel[2][3] ? io_fromRename_3_bits_pdest : (ohSel[2][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_2_bits_useRegCache_0 = (ohSel[2][0] ? _rcTagTable_io_readPorts_0_valid : (ohSel[2][1] ? _rcTagTable_io_readPorts_2_valid : (ohSel[2][2] ? _rcTagTable_io_readPorts_4_valid : (ohSel[2][3] ? _rcTagTable_io_readPorts_6_valid : (ohSel[2][4] ? _rcTagTable_io_readPorts_8_valid : _rcTagTable_io_readPorts_10_valid)))));
  assign io_toIssueQueues_2_bits_useRegCache_1 = (ohSel[2][0] ? _rcTagTable_io_readPorts_1_valid : (ohSel[2][1] ? _rcTagTable_io_readPorts_3_valid : (ohSel[2][2] ? _rcTagTable_io_readPorts_5_valid : (ohSel[2][3] ? _rcTagTable_io_readPorts_7_valid : (ohSel[2][4] ? _rcTagTable_io_readPorts_9_valid : _rcTagTable_io_readPorts_11_valid)))));
  assign io_toIssueQueues_2_bits_regCacheIdx_0 = (ohSel[2][0] ? _rcTagTable_io_readPorts_0_addr : (ohSel[2][1] ? _rcTagTable_io_readPorts_2_addr : (ohSel[2][2] ? _rcTagTable_io_readPorts_4_addr : (ohSel[2][3] ? _rcTagTable_io_readPorts_6_addr : (ohSel[2][4] ? _rcTagTable_io_readPorts_8_addr : _rcTagTable_io_readPorts_10_addr)))));
  assign io_toIssueQueues_2_bits_regCacheIdx_1 = (ohSel[2][0] ? _rcTagTable_io_readPorts_1_addr : (ohSel[2][1] ? _rcTagTable_io_readPorts_3_addr : (ohSel[2][2] ? _rcTagTable_io_readPorts_5_addr : (ohSel[2][3] ? _rcTagTable_io_readPorts_7_addr : (ohSel[2][4] ? _rcTagTable_io_readPorts_9_addr : _rcTagTable_io_readPorts_11_addr)))));
  assign io_toIssueQueues_2_bits_robIdx_flag = (ohSel[2][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[2][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[2][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[2][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[2][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_2_bits_robIdx_value = (ohSel[2][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[2][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[2][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[2][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[2][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  // -- 端口 3(IQ 1 enq 1)--
  assign io_toIssueQueues_3_valid = (ohSel[3][0] ? fromRenameUpdate_valid[0] : (ohSel[3][1] ? fromRenameUpdate_valid[1] : (ohSel[3][2] ? fromRenameUpdate_valid[2] : (ohSel[3][3] ? fromRenameUpdate_valid[3] : (ohSel[3][4] ? fromRenameUpdate_valid[4] : (ohSel[3][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_3_bits_preDecodeInfo_isRVC = (ohSel[3][0] ? io_fromRename_0_bits_preDecodeInfo_isRVC : (ohSel[3][1] ? io_fromRename_1_bits_preDecodeInfo_isRVC : (ohSel[3][2] ? io_fromRename_2_bits_preDecodeInfo_isRVC : (ohSel[3][3] ? io_fromRename_3_bits_preDecodeInfo_isRVC : (ohSel[3][4] ? io_fromRename_4_bits_preDecodeInfo_isRVC : io_fromRename_5_bits_preDecodeInfo_isRVC)))));
  assign io_toIssueQueues_3_bits_pred_taken = (ohSel[3][0] ? io_fromRename_0_bits_pred_taken : (ohSel[3][1] ? io_fromRename_1_bits_pred_taken : (ohSel[3][2] ? io_fromRename_2_bits_pred_taken : (ohSel[3][3] ? io_fromRename_3_bits_pred_taken : (ohSel[3][4] ? io_fromRename_4_bits_pred_taken : io_fromRename_5_bits_pred_taken)))));
  assign io_toIssueQueues_3_bits_ftqPtr_flag = (ohSel[3][0] ? io_fromRename_0_bits_ftqPtr_flag : (ohSel[3][1] ? io_fromRename_1_bits_ftqPtr_flag : (ohSel[3][2] ? io_fromRename_2_bits_ftqPtr_flag : (ohSel[3][3] ? io_fromRename_3_bits_ftqPtr_flag : (ohSel[3][4] ? io_fromRename_4_bits_ftqPtr_flag : io_fromRename_5_bits_ftqPtr_flag)))));
  assign io_toIssueQueues_3_bits_ftqPtr_value = (ohSel[3][0] ? io_fromRename_0_bits_ftqPtr_value : (ohSel[3][1] ? io_fromRename_1_bits_ftqPtr_value : (ohSel[3][2] ? io_fromRename_2_bits_ftqPtr_value : (ohSel[3][3] ? io_fromRename_3_bits_ftqPtr_value : (ohSel[3][4] ? io_fromRename_4_bits_ftqPtr_value : io_fromRename_5_bits_ftqPtr_value)))));
  assign io_toIssueQueues_3_bits_ftqOffset = (ohSel[3][0] ? io_fromRename_0_bits_ftqOffset : (ohSel[3][1] ? io_fromRename_1_bits_ftqOffset : (ohSel[3][2] ? io_fromRename_2_bits_ftqOffset : (ohSel[3][3] ? io_fromRename_3_bits_ftqOffset : (ohSel[3][4] ? io_fromRename_4_bits_ftqOffset : io_fromRename_5_bits_ftqOffset)))));
  assign io_toIssueQueues_3_bits_srcType_0 = (ohSel[3][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[3][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[3][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[3][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[3][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_3_bits_srcType_1 = (ohSel[3][0] ? io_fromRename_0_bits_srcType_1 : (ohSel[3][1] ? io_fromRename_1_bits_srcType_1 : (ohSel[3][2] ? io_fromRename_2_bits_srcType_1 : (ohSel[3][3] ? io_fromRename_3_bits_srcType_1 : (ohSel[3][4] ? io_fromRename_4_bits_srcType_1 : io_fromRename_5_bits_srcType_1)))));
  assign io_toIssueQueues_3_bits_fuType = (ohSel[3][0] ? io_fromRename_0_bits_fuType : (ohSel[3][1] ? io_fromRename_1_bits_fuType : (ohSel[3][2] ? io_fromRename_2_bits_fuType : (ohSel[3][3] ? io_fromRename_3_bits_fuType : (ohSel[3][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_3_bits_fuOpType = (ohSel[3][0] ? io_fromRename_0_bits_fuOpType : (ohSel[3][1] ? io_fromRename_1_bits_fuOpType : (ohSel[3][2] ? io_fromRename_2_bits_fuOpType : (ohSel[3][3] ? io_fromRename_3_bits_fuOpType : (ohSel[3][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_3_bits_rfWen = (ohSel[3][0] ? io_fromRename_0_bits_rfWen : (ohSel[3][1] ? io_fromRename_1_bits_rfWen : (ohSel[3][2] ? io_fromRename_2_bits_rfWen : (ohSel[3][3] ? io_fromRename_3_bits_rfWen : (ohSel[3][4] ? io_fromRename_4_bits_rfWen : io_fromRename_5_bits_rfWen)))));
  assign io_toIssueQueues_3_bits_selImm = (ohSel[3][0] ? io_fromRename_0_bits_selImm : (ohSel[3][1] ? io_fromRename_1_bits_selImm : (ohSel[3][2] ? io_fromRename_2_bits_selImm : (ohSel[3][3] ? io_fromRename_3_bits_selImm : (ohSel[3][4] ? io_fromRename_4_bits_selImm : io_fromRename_5_bits_selImm)))));
  assign io_toIssueQueues_3_bits_imm = (ohSel[3][0] ? io_fromRename_0_bits_imm : (ohSel[3][1] ? io_fromRename_1_bits_imm : (ohSel[3][2] ? io_fromRename_2_bits_imm : (ohSel[3][3] ? io_fromRename_3_bits_imm : (ohSel[3][4] ? io_fromRename_4_bits_imm : io_fromRename_5_bits_imm)))));
  assign io_toIssueQueues_3_bits_srcState_0 = (ohSel[3][0] ? (allSrcState[0][0][0]) : (ohSel[3][1] ? (allSrcState[1][0][0]) : (ohSel[3][2] ? (allSrcState[2][0][0]) : (ohSel[3][3] ? (allSrcState[3][0][0]) : (ohSel[3][4] ? (allSrcState[4][0][0]) : (allSrcState[5][0][0]))))));
  assign io_toIssueQueues_3_bits_srcState_1 = (ohSel[3][0] ? (allSrcState[0][1][0]) : (ohSel[3][1] ? (allSrcState[1][1][0]) : (ohSel[3][2] ? (allSrcState[2][1][0]) : (ohSel[3][3] ? (allSrcState[3][1][0]) : (ohSel[3][4] ? (allSrcState[4][1][0]) : (allSrcState[5][1][0]))))));
  assign io_toIssueQueues_3_bits_srcLoadDependency_0_0 = (ohSel[3][0] ? fru_srcLoadDep[0][0][0] : (ohSel[3][1] ? fru_srcLoadDep[1][0][0] : (ohSel[3][2] ? fru_srcLoadDep[2][0][0] : (ohSel[3][3] ? fru_srcLoadDep[3][0][0] : (ohSel[3][4] ? fru_srcLoadDep[4][0][0] : fru_srcLoadDep[5][0][0])))));
  assign io_toIssueQueues_3_bits_srcLoadDependency_0_1 = (ohSel[3][0] ? fru_srcLoadDep[0][0][1] : (ohSel[3][1] ? fru_srcLoadDep[1][0][1] : (ohSel[3][2] ? fru_srcLoadDep[2][0][1] : (ohSel[3][3] ? fru_srcLoadDep[3][0][1] : (ohSel[3][4] ? fru_srcLoadDep[4][0][1] : fru_srcLoadDep[5][0][1])))));
  assign io_toIssueQueues_3_bits_srcLoadDependency_0_2 = (ohSel[3][0] ? fru_srcLoadDep[0][0][2] : (ohSel[3][1] ? fru_srcLoadDep[1][0][2] : (ohSel[3][2] ? fru_srcLoadDep[2][0][2] : (ohSel[3][3] ? fru_srcLoadDep[3][0][2] : (ohSel[3][4] ? fru_srcLoadDep[4][0][2] : fru_srcLoadDep[5][0][2])))));
  assign io_toIssueQueues_3_bits_srcLoadDependency_1_0 = (ohSel[3][0] ? fru_srcLoadDep[0][1][0] : (ohSel[3][1] ? fru_srcLoadDep[1][1][0] : (ohSel[3][2] ? fru_srcLoadDep[2][1][0] : (ohSel[3][3] ? fru_srcLoadDep[3][1][0] : (ohSel[3][4] ? fru_srcLoadDep[4][1][0] : fru_srcLoadDep[5][1][0])))));
  assign io_toIssueQueues_3_bits_srcLoadDependency_1_1 = (ohSel[3][0] ? fru_srcLoadDep[0][1][1] : (ohSel[3][1] ? fru_srcLoadDep[1][1][1] : (ohSel[3][2] ? fru_srcLoadDep[2][1][1] : (ohSel[3][3] ? fru_srcLoadDep[3][1][1] : (ohSel[3][4] ? fru_srcLoadDep[4][1][1] : fru_srcLoadDep[5][1][1])))));
  assign io_toIssueQueues_3_bits_srcLoadDependency_1_2 = (ohSel[3][0] ? fru_srcLoadDep[0][1][2] : (ohSel[3][1] ? fru_srcLoadDep[1][1][2] : (ohSel[3][2] ? fru_srcLoadDep[2][1][2] : (ohSel[3][3] ? fru_srcLoadDep[3][1][2] : (ohSel[3][4] ? fru_srcLoadDep[4][1][2] : fru_srcLoadDep[5][1][2])))));
  assign io_toIssueQueues_3_bits_psrc_0 = (ohSel[3][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[3][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[3][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[3][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[3][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_3_bits_psrc_1 = (ohSel[3][0] ? io_fromRename_0_bits_psrc_1 : (ohSel[3][1] ? io_fromRename_1_bits_psrc_1 : (ohSel[3][2] ? io_fromRename_2_bits_psrc_1 : (ohSel[3][3] ? io_fromRename_3_bits_psrc_1 : (ohSel[3][4] ? io_fromRename_4_bits_psrc_1 : io_fromRename_5_bits_psrc_1)))));
  assign io_toIssueQueues_3_bits_pdest = (ohSel[3][0] ? io_fromRename_0_bits_pdest : (ohSel[3][1] ? io_fromRename_1_bits_pdest : (ohSel[3][2] ? io_fromRename_2_bits_pdest : (ohSel[3][3] ? io_fromRename_3_bits_pdest : (ohSel[3][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_3_bits_useRegCache_0 = (ohSel[3][0] ? _rcTagTable_io_readPorts_0_valid : (ohSel[3][1] ? _rcTagTable_io_readPorts_2_valid : (ohSel[3][2] ? _rcTagTable_io_readPorts_4_valid : (ohSel[3][3] ? _rcTagTable_io_readPorts_6_valid : (ohSel[3][4] ? _rcTagTable_io_readPorts_8_valid : _rcTagTable_io_readPorts_10_valid)))));
  assign io_toIssueQueues_3_bits_useRegCache_1 = (ohSel[3][0] ? _rcTagTable_io_readPorts_1_valid : (ohSel[3][1] ? _rcTagTable_io_readPorts_3_valid : (ohSel[3][2] ? _rcTagTable_io_readPorts_5_valid : (ohSel[3][3] ? _rcTagTable_io_readPorts_7_valid : (ohSel[3][4] ? _rcTagTable_io_readPorts_9_valid : _rcTagTable_io_readPorts_11_valid)))));
  assign io_toIssueQueues_3_bits_regCacheIdx_0 = (ohSel[3][0] ? _rcTagTable_io_readPorts_0_addr : (ohSel[3][1] ? _rcTagTable_io_readPorts_2_addr : (ohSel[3][2] ? _rcTagTable_io_readPorts_4_addr : (ohSel[3][3] ? _rcTagTable_io_readPorts_6_addr : (ohSel[3][4] ? _rcTagTable_io_readPorts_8_addr : _rcTagTable_io_readPorts_10_addr)))));
  assign io_toIssueQueues_3_bits_regCacheIdx_1 = (ohSel[3][0] ? _rcTagTable_io_readPorts_1_addr : (ohSel[3][1] ? _rcTagTable_io_readPorts_3_addr : (ohSel[3][2] ? _rcTagTable_io_readPorts_5_addr : (ohSel[3][3] ? _rcTagTable_io_readPorts_7_addr : (ohSel[3][4] ? _rcTagTable_io_readPorts_9_addr : _rcTagTable_io_readPorts_11_addr)))));
  assign io_toIssueQueues_3_bits_robIdx_flag = (ohSel[3][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[3][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[3][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[3][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[3][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_3_bits_robIdx_value = (ohSel[3][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[3][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[3][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[3][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[3][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  // -- 端口 4(IQ 2 enq 0)--
  assign io_toIssueQueues_4_valid = (ohSel[4][0] ? fromRenameUpdate_valid[0] : (ohSel[4][1] ? fromRenameUpdate_valid[1] : (ohSel[4][2] ? fromRenameUpdate_valid[2] : (ohSel[4][3] ? fromRenameUpdate_valid[3] : (ohSel[4][4] ? fromRenameUpdate_valid[4] : (ohSel[4][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_4_bits_preDecodeInfo_isRVC = (ohSel[4][0] ? io_fromRename_0_bits_preDecodeInfo_isRVC : (ohSel[4][1] ? io_fromRename_1_bits_preDecodeInfo_isRVC : (ohSel[4][2] ? io_fromRename_2_bits_preDecodeInfo_isRVC : (ohSel[4][3] ? io_fromRename_3_bits_preDecodeInfo_isRVC : (ohSel[4][4] ? io_fromRename_4_bits_preDecodeInfo_isRVC : io_fromRename_5_bits_preDecodeInfo_isRVC)))));
  assign io_toIssueQueues_4_bits_pred_taken = (ohSel[4][0] ? io_fromRename_0_bits_pred_taken : (ohSel[4][1] ? io_fromRename_1_bits_pred_taken : (ohSel[4][2] ? io_fromRename_2_bits_pred_taken : (ohSel[4][3] ? io_fromRename_3_bits_pred_taken : (ohSel[4][4] ? io_fromRename_4_bits_pred_taken : io_fromRename_5_bits_pred_taken)))));
  assign io_toIssueQueues_4_bits_ftqPtr_flag = (ohSel[4][0] ? io_fromRename_0_bits_ftqPtr_flag : (ohSel[4][1] ? io_fromRename_1_bits_ftqPtr_flag : (ohSel[4][2] ? io_fromRename_2_bits_ftqPtr_flag : (ohSel[4][3] ? io_fromRename_3_bits_ftqPtr_flag : (ohSel[4][4] ? io_fromRename_4_bits_ftqPtr_flag : io_fromRename_5_bits_ftqPtr_flag)))));
  assign io_toIssueQueues_4_bits_ftqPtr_value = (ohSel[4][0] ? io_fromRename_0_bits_ftqPtr_value : (ohSel[4][1] ? io_fromRename_1_bits_ftqPtr_value : (ohSel[4][2] ? io_fromRename_2_bits_ftqPtr_value : (ohSel[4][3] ? io_fromRename_3_bits_ftqPtr_value : (ohSel[4][4] ? io_fromRename_4_bits_ftqPtr_value : io_fromRename_5_bits_ftqPtr_value)))));
  assign io_toIssueQueues_4_bits_ftqOffset = (ohSel[4][0] ? io_fromRename_0_bits_ftqOffset : (ohSel[4][1] ? io_fromRename_1_bits_ftqOffset : (ohSel[4][2] ? io_fromRename_2_bits_ftqOffset : (ohSel[4][3] ? io_fromRename_3_bits_ftqOffset : (ohSel[4][4] ? io_fromRename_4_bits_ftqOffset : io_fromRename_5_bits_ftqOffset)))));
  assign io_toIssueQueues_4_bits_srcType_0 = (ohSel[4][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[4][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[4][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[4][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[4][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_4_bits_srcType_1 = (ohSel[4][0] ? io_fromRename_0_bits_srcType_1 : (ohSel[4][1] ? io_fromRename_1_bits_srcType_1 : (ohSel[4][2] ? io_fromRename_2_bits_srcType_1 : (ohSel[4][3] ? io_fromRename_3_bits_srcType_1 : (ohSel[4][4] ? io_fromRename_4_bits_srcType_1 : io_fromRename_5_bits_srcType_1)))));
  assign io_toIssueQueues_4_bits_fuType = (ohSel[4][0] ? io_fromRename_0_bits_fuType : (ohSel[4][1] ? io_fromRename_1_bits_fuType : (ohSel[4][2] ? io_fromRename_2_bits_fuType : (ohSel[4][3] ? io_fromRename_3_bits_fuType : (ohSel[4][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_4_bits_fuOpType = (ohSel[4][0] ? io_fromRename_0_bits_fuOpType : (ohSel[4][1] ? io_fromRename_1_bits_fuOpType : (ohSel[4][2] ? io_fromRename_2_bits_fuOpType : (ohSel[4][3] ? io_fromRename_3_bits_fuOpType : (ohSel[4][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_4_bits_rfWen = (ohSel[4][0] ? io_fromRename_0_bits_rfWen : (ohSel[4][1] ? io_fromRename_1_bits_rfWen : (ohSel[4][2] ? io_fromRename_2_bits_rfWen : (ohSel[4][3] ? io_fromRename_3_bits_rfWen : (ohSel[4][4] ? io_fromRename_4_bits_rfWen : io_fromRename_5_bits_rfWen)))));
  assign io_toIssueQueues_4_bits_fpWen = (ohSel[4][0] ? io_fromRename_0_bits_fpWen : (ohSel[4][1] ? io_fromRename_1_bits_fpWen : (ohSel[4][2] ? io_fromRename_2_bits_fpWen : (ohSel[4][3] ? io_fromRename_3_bits_fpWen : (ohSel[4][4] ? io_fromRename_4_bits_fpWen : io_fromRename_5_bits_fpWen)))));
  assign io_toIssueQueues_4_bits_vecWen = (ohSel[4][0] ? io_fromRename_0_bits_vecWen : (ohSel[4][1] ? io_fromRename_1_bits_vecWen : (ohSel[4][2] ? io_fromRename_2_bits_vecWen : (ohSel[4][3] ? io_fromRename_3_bits_vecWen : (ohSel[4][4] ? io_fromRename_4_bits_vecWen : io_fromRename_5_bits_vecWen)))));
  assign io_toIssueQueues_4_bits_v0Wen = (ohSel[4][0] ? io_fromRename_0_bits_v0Wen : (ohSel[4][1] ? io_fromRename_1_bits_v0Wen : (ohSel[4][2] ? io_fromRename_2_bits_v0Wen : (ohSel[4][3] ? io_fromRename_3_bits_v0Wen : (ohSel[4][4] ? io_fromRename_4_bits_v0Wen : io_fromRename_5_bits_v0Wen)))));
  assign io_toIssueQueues_4_bits_vlWen = (ohSel[4][0] ? io_fromRename_0_bits_vlWen : (ohSel[4][1] ? io_fromRename_1_bits_vlWen : (ohSel[4][2] ? io_fromRename_2_bits_vlWen : (ohSel[4][3] ? io_fromRename_3_bits_vlWen : (ohSel[4][4] ? io_fromRename_4_bits_vlWen : io_fromRename_5_bits_vlWen)))));
  assign io_toIssueQueues_4_bits_selImm = (ohSel[4][0] ? io_fromRename_0_bits_selImm : (ohSel[4][1] ? io_fromRename_1_bits_selImm : (ohSel[4][2] ? io_fromRename_2_bits_selImm : (ohSel[4][3] ? io_fromRename_3_bits_selImm : (ohSel[4][4] ? io_fromRename_4_bits_selImm : io_fromRename_5_bits_selImm)))));
  assign io_toIssueQueues_4_bits_imm = (ohSel[4][0] ? io_fromRename_0_bits_imm : (ohSel[4][1] ? io_fromRename_1_bits_imm : (ohSel[4][2] ? io_fromRename_2_bits_imm : (ohSel[4][3] ? io_fromRename_3_bits_imm : (ohSel[4][4] ? io_fromRename_4_bits_imm : io_fromRename_5_bits_imm)))));
  assign io_toIssueQueues_4_bits_fpu_typeTagOut = (ohSel[4][0] ? io_fromRename_0_bits_fpu_typeTagOut : (ohSel[4][1] ? io_fromRename_1_bits_fpu_typeTagOut : (ohSel[4][2] ? io_fromRename_2_bits_fpu_typeTagOut : (ohSel[4][3] ? io_fromRename_3_bits_fpu_typeTagOut : (ohSel[4][4] ? io_fromRename_4_bits_fpu_typeTagOut : io_fromRename_5_bits_fpu_typeTagOut)))));
  assign io_toIssueQueues_4_bits_fpu_wflags = (ohSel[4][0] ? io_fromRename_0_bits_fpu_wflags : (ohSel[4][1] ? io_fromRename_1_bits_fpu_wflags : (ohSel[4][2] ? io_fromRename_2_bits_fpu_wflags : (ohSel[4][3] ? io_fromRename_3_bits_fpu_wflags : (ohSel[4][4] ? io_fromRename_4_bits_fpu_wflags : io_fromRename_5_bits_fpu_wflags)))));
  assign io_toIssueQueues_4_bits_fpu_typ = (ohSel[4][0] ? io_fromRename_0_bits_fpu_typ : (ohSel[4][1] ? io_fromRename_1_bits_fpu_typ : (ohSel[4][2] ? io_fromRename_2_bits_fpu_typ : (ohSel[4][3] ? io_fromRename_3_bits_fpu_typ : (ohSel[4][4] ? io_fromRename_4_bits_fpu_typ : io_fromRename_5_bits_fpu_typ)))));
  assign io_toIssueQueues_4_bits_fpu_rm = (ohSel[4][0] ? io_fromRename_0_bits_fpu_rm : (ohSel[4][1] ? io_fromRename_1_bits_fpu_rm : (ohSel[4][2] ? io_fromRename_2_bits_fpu_rm : (ohSel[4][3] ? io_fromRename_3_bits_fpu_rm : (ohSel[4][4] ? io_fromRename_4_bits_fpu_rm : io_fromRename_5_bits_fpu_rm)))));
  assign io_toIssueQueues_4_bits_srcState_0 = (ohSel[4][0] ? (allSrcState[0][0][0]) : (ohSel[4][1] ? (allSrcState[1][0][0]) : (ohSel[4][2] ? (allSrcState[2][0][0]) : (ohSel[4][3] ? (allSrcState[3][0][0]) : (ohSel[4][4] ? (allSrcState[4][0][0]) : (allSrcState[5][0][0]))))));
  assign io_toIssueQueues_4_bits_srcState_1 = (ohSel[4][0] ? (allSrcState[0][1][0]) : (ohSel[4][1] ? (allSrcState[1][1][0]) : (ohSel[4][2] ? (allSrcState[2][1][0]) : (ohSel[4][3] ? (allSrcState[3][1][0]) : (ohSel[4][4] ? (allSrcState[4][1][0]) : (allSrcState[5][1][0]))))));
  assign io_toIssueQueues_4_bits_srcLoadDependency_0_0 = (ohSel[4][0] ? fru_srcLoadDep[0][0][0] : (ohSel[4][1] ? fru_srcLoadDep[1][0][0] : (ohSel[4][2] ? fru_srcLoadDep[2][0][0] : (ohSel[4][3] ? fru_srcLoadDep[3][0][0] : (ohSel[4][4] ? fru_srcLoadDep[4][0][0] : fru_srcLoadDep[5][0][0])))));
  assign io_toIssueQueues_4_bits_srcLoadDependency_0_1 = (ohSel[4][0] ? fru_srcLoadDep[0][0][1] : (ohSel[4][1] ? fru_srcLoadDep[1][0][1] : (ohSel[4][2] ? fru_srcLoadDep[2][0][1] : (ohSel[4][3] ? fru_srcLoadDep[3][0][1] : (ohSel[4][4] ? fru_srcLoadDep[4][0][1] : fru_srcLoadDep[5][0][1])))));
  assign io_toIssueQueues_4_bits_srcLoadDependency_0_2 = (ohSel[4][0] ? fru_srcLoadDep[0][0][2] : (ohSel[4][1] ? fru_srcLoadDep[1][0][2] : (ohSel[4][2] ? fru_srcLoadDep[2][0][2] : (ohSel[4][3] ? fru_srcLoadDep[3][0][2] : (ohSel[4][4] ? fru_srcLoadDep[4][0][2] : fru_srcLoadDep[5][0][2])))));
  assign io_toIssueQueues_4_bits_srcLoadDependency_1_0 = (ohSel[4][0] ? fru_srcLoadDep[0][1][0] : (ohSel[4][1] ? fru_srcLoadDep[1][1][0] : (ohSel[4][2] ? fru_srcLoadDep[2][1][0] : (ohSel[4][3] ? fru_srcLoadDep[3][1][0] : (ohSel[4][4] ? fru_srcLoadDep[4][1][0] : fru_srcLoadDep[5][1][0])))));
  assign io_toIssueQueues_4_bits_srcLoadDependency_1_1 = (ohSel[4][0] ? fru_srcLoadDep[0][1][1] : (ohSel[4][1] ? fru_srcLoadDep[1][1][1] : (ohSel[4][2] ? fru_srcLoadDep[2][1][1] : (ohSel[4][3] ? fru_srcLoadDep[3][1][1] : (ohSel[4][4] ? fru_srcLoadDep[4][1][1] : fru_srcLoadDep[5][1][1])))));
  assign io_toIssueQueues_4_bits_srcLoadDependency_1_2 = (ohSel[4][0] ? fru_srcLoadDep[0][1][2] : (ohSel[4][1] ? fru_srcLoadDep[1][1][2] : (ohSel[4][2] ? fru_srcLoadDep[2][1][2] : (ohSel[4][3] ? fru_srcLoadDep[3][1][2] : (ohSel[4][4] ? fru_srcLoadDep[4][1][2] : fru_srcLoadDep[5][1][2])))));
  assign io_toIssueQueues_4_bits_psrc_0 = (ohSel[4][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[4][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[4][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[4][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[4][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_4_bits_psrc_1 = (ohSel[4][0] ? io_fromRename_0_bits_psrc_1 : (ohSel[4][1] ? io_fromRename_1_bits_psrc_1 : (ohSel[4][2] ? io_fromRename_2_bits_psrc_1 : (ohSel[4][3] ? io_fromRename_3_bits_psrc_1 : (ohSel[4][4] ? io_fromRename_4_bits_psrc_1 : io_fromRename_5_bits_psrc_1)))));
  assign io_toIssueQueues_4_bits_pdest = (ohSel[4][0] ? io_fromRename_0_bits_pdest : (ohSel[4][1] ? io_fromRename_1_bits_pdest : (ohSel[4][2] ? io_fromRename_2_bits_pdest : (ohSel[4][3] ? io_fromRename_3_bits_pdest : (ohSel[4][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_4_bits_useRegCache_0 = (ohSel[4][0] ? _rcTagTable_io_readPorts_0_valid : (ohSel[4][1] ? _rcTagTable_io_readPorts_2_valid : (ohSel[4][2] ? _rcTagTable_io_readPorts_4_valid : (ohSel[4][3] ? _rcTagTable_io_readPorts_6_valid : (ohSel[4][4] ? _rcTagTable_io_readPorts_8_valid : _rcTagTable_io_readPorts_10_valid)))));
  assign io_toIssueQueues_4_bits_useRegCache_1 = (ohSel[4][0] ? _rcTagTable_io_readPorts_1_valid : (ohSel[4][1] ? _rcTagTable_io_readPorts_3_valid : (ohSel[4][2] ? _rcTagTable_io_readPorts_5_valid : (ohSel[4][3] ? _rcTagTable_io_readPorts_7_valid : (ohSel[4][4] ? _rcTagTable_io_readPorts_9_valid : _rcTagTable_io_readPorts_11_valid)))));
  assign io_toIssueQueues_4_bits_regCacheIdx_0 = (ohSel[4][0] ? _rcTagTable_io_readPorts_0_addr : (ohSel[4][1] ? _rcTagTable_io_readPorts_2_addr : (ohSel[4][2] ? _rcTagTable_io_readPorts_4_addr : (ohSel[4][3] ? _rcTagTable_io_readPorts_6_addr : (ohSel[4][4] ? _rcTagTable_io_readPorts_8_addr : _rcTagTable_io_readPorts_10_addr)))));
  assign io_toIssueQueues_4_bits_regCacheIdx_1 = (ohSel[4][0] ? _rcTagTable_io_readPorts_1_addr : (ohSel[4][1] ? _rcTagTable_io_readPorts_3_addr : (ohSel[4][2] ? _rcTagTable_io_readPorts_5_addr : (ohSel[4][3] ? _rcTagTable_io_readPorts_7_addr : (ohSel[4][4] ? _rcTagTable_io_readPorts_9_addr : _rcTagTable_io_readPorts_11_addr)))));
  assign io_toIssueQueues_4_bits_robIdx_flag = (ohSel[4][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[4][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[4][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[4][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[4][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_4_bits_robIdx_value = (ohSel[4][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[4][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[4][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[4][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[4][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  // -- 端口 5(IQ 2 enq 1)--
  assign io_toIssueQueues_5_valid = (ohSel[5][0] ? fromRenameUpdate_valid[0] : (ohSel[5][1] ? fromRenameUpdate_valid[1] : (ohSel[5][2] ? fromRenameUpdate_valid[2] : (ohSel[5][3] ? fromRenameUpdate_valid[3] : (ohSel[5][4] ? fromRenameUpdate_valid[4] : (ohSel[5][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_5_bits_preDecodeInfo_isRVC = (ohSel[5][0] ? io_fromRename_0_bits_preDecodeInfo_isRVC : (ohSel[5][1] ? io_fromRename_1_bits_preDecodeInfo_isRVC : (ohSel[5][2] ? io_fromRename_2_bits_preDecodeInfo_isRVC : (ohSel[5][3] ? io_fromRename_3_bits_preDecodeInfo_isRVC : (ohSel[5][4] ? io_fromRename_4_bits_preDecodeInfo_isRVC : io_fromRename_5_bits_preDecodeInfo_isRVC)))));
  assign io_toIssueQueues_5_bits_pred_taken = (ohSel[5][0] ? io_fromRename_0_bits_pred_taken : (ohSel[5][1] ? io_fromRename_1_bits_pred_taken : (ohSel[5][2] ? io_fromRename_2_bits_pred_taken : (ohSel[5][3] ? io_fromRename_3_bits_pred_taken : (ohSel[5][4] ? io_fromRename_4_bits_pred_taken : io_fromRename_5_bits_pred_taken)))));
  assign io_toIssueQueues_5_bits_ftqPtr_flag = (ohSel[5][0] ? io_fromRename_0_bits_ftqPtr_flag : (ohSel[5][1] ? io_fromRename_1_bits_ftqPtr_flag : (ohSel[5][2] ? io_fromRename_2_bits_ftqPtr_flag : (ohSel[5][3] ? io_fromRename_3_bits_ftqPtr_flag : (ohSel[5][4] ? io_fromRename_4_bits_ftqPtr_flag : io_fromRename_5_bits_ftqPtr_flag)))));
  assign io_toIssueQueues_5_bits_ftqPtr_value = (ohSel[5][0] ? io_fromRename_0_bits_ftqPtr_value : (ohSel[5][1] ? io_fromRename_1_bits_ftqPtr_value : (ohSel[5][2] ? io_fromRename_2_bits_ftqPtr_value : (ohSel[5][3] ? io_fromRename_3_bits_ftqPtr_value : (ohSel[5][4] ? io_fromRename_4_bits_ftqPtr_value : io_fromRename_5_bits_ftqPtr_value)))));
  assign io_toIssueQueues_5_bits_ftqOffset = (ohSel[5][0] ? io_fromRename_0_bits_ftqOffset : (ohSel[5][1] ? io_fromRename_1_bits_ftqOffset : (ohSel[5][2] ? io_fromRename_2_bits_ftqOffset : (ohSel[5][3] ? io_fromRename_3_bits_ftqOffset : (ohSel[5][4] ? io_fromRename_4_bits_ftqOffset : io_fromRename_5_bits_ftqOffset)))));
  assign io_toIssueQueues_5_bits_srcType_0 = (ohSel[5][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[5][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[5][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[5][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[5][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_5_bits_srcType_1 = (ohSel[5][0] ? io_fromRename_0_bits_srcType_1 : (ohSel[5][1] ? io_fromRename_1_bits_srcType_1 : (ohSel[5][2] ? io_fromRename_2_bits_srcType_1 : (ohSel[5][3] ? io_fromRename_3_bits_srcType_1 : (ohSel[5][4] ? io_fromRename_4_bits_srcType_1 : io_fromRename_5_bits_srcType_1)))));
  assign io_toIssueQueues_5_bits_fuType = (ohSel[5][0] ? io_fromRename_0_bits_fuType : (ohSel[5][1] ? io_fromRename_1_bits_fuType : (ohSel[5][2] ? io_fromRename_2_bits_fuType : (ohSel[5][3] ? io_fromRename_3_bits_fuType : (ohSel[5][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_5_bits_fuOpType = (ohSel[5][0] ? io_fromRename_0_bits_fuOpType : (ohSel[5][1] ? io_fromRename_1_bits_fuOpType : (ohSel[5][2] ? io_fromRename_2_bits_fuOpType : (ohSel[5][3] ? io_fromRename_3_bits_fuOpType : (ohSel[5][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_5_bits_rfWen = (ohSel[5][0] ? io_fromRename_0_bits_rfWen : (ohSel[5][1] ? io_fromRename_1_bits_rfWen : (ohSel[5][2] ? io_fromRename_2_bits_rfWen : (ohSel[5][3] ? io_fromRename_3_bits_rfWen : (ohSel[5][4] ? io_fromRename_4_bits_rfWen : io_fromRename_5_bits_rfWen)))));
  assign io_toIssueQueues_5_bits_fpWen = (ohSel[5][0] ? io_fromRename_0_bits_fpWen : (ohSel[5][1] ? io_fromRename_1_bits_fpWen : (ohSel[5][2] ? io_fromRename_2_bits_fpWen : (ohSel[5][3] ? io_fromRename_3_bits_fpWen : (ohSel[5][4] ? io_fromRename_4_bits_fpWen : io_fromRename_5_bits_fpWen)))));
  assign io_toIssueQueues_5_bits_vecWen = (ohSel[5][0] ? io_fromRename_0_bits_vecWen : (ohSel[5][1] ? io_fromRename_1_bits_vecWen : (ohSel[5][2] ? io_fromRename_2_bits_vecWen : (ohSel[5][3] ? io_fromRename_3_bits_vecWen : (ohSel[5][4] ? io_fromRename_4_bits_vecWen : io_fromRename_5_bits_vecWen)))));
  assign io_toIssueQueues_5_bits_v0Wen = (ohSel[5][0] ? io_fromRename_0_bits_v0Wen : (ohSel[5][1] ? io_fromRename_1_bits_v0Wen : (ohSel[5][2] ? io_fromRename_2_bits_v0Wen : (ohSel[5][3] ? io_fromRename_3_bits_v0Wen : (ohSel[5][4] ? io_fromRename_4_bits_v0Wen : io_fromRename_5_bits_v0Wen)))));
  assign io_toIssueQueues_5_bits_vlWen = (ohSel[5][0] ? io_fromRename_0_bits_vlWen : (ohSel[5][1] ? io_fromRename_1_bits_vlWen : (ohSel[5][2] ? io_fromRename_2_bits_vlWen : (ohSel[5][3] ? io_fromRename_3_bits_vlWen : (ohSel[5][4] ? io_fromRename_4_bits_vlWen : io_fromRename_5_bits_vlWen)))));
  assign io_toIssueQueues_5_bits_selImm = (ohSel[5][0] ? io_fromRename_0_bits_selImm : (ohSel[5][1] ? io_fromRename_1_bits_selImm : (ohSel[5][2] ? io_fromRename_2_bits_selImm : (ohSel[5][3] ? io_fromRename_3_bits_selImm : (ohSel[5][4] ? io_fromRename_4_bits_selImm : io_fromRename_5_bits_selImm)))));
  assign io_toIssueQueues_5_bits_imm = (ohSel[5][0] ? io_fromRename_0_bits_imm : (ohSel[5][1] ? io_fromRename_1_bits_imm : (ohSel[5][2] ? io_fromRename_2_bits_imm : (ohSel[5][3] ? io_fromRename_3_bits_imm : (ohSel[5][4] ? io_fromRename_4_bits_imm : io_fromRename_5_bits_imm)))));
  assign io_toIssueQueues_5_bits_fpu_typeTagOut = (ohSel[5][0] ? io_fromRename_0_bits_fpu_typeTagOut : (ohSel[5][1] ? io_fromRename_1_bits_fpu_typeTagOut : (ohSel[5][2] ? io_fromRename_2_bits_fpu_typeTagOut : (ohSel[5][3] ? io_fromRename_3_bits_fpu_typeTagOut : (ohSel[5][4] ? io_fromRename_4_bits_fpu_typeTagOut : io_fromRename_5_bits_fpu_typeTagOut)))));
  assign io_toIssueQueues_5_bits_fpu_wflags = (ohSel[5][0] ? io_fromRename_0_bits_fpu_wflags : (ohSel[5][1] ? io_fromRename_1_bits_fpu_wflags : (ohSel[5][2] ? io_fromRename_2_bits_fpu_wflags : (ohSel[5][3] ? io_fromRename_3_bits_fpu_wflags : (ohSel[5][4] ? io_fromRename_4_bits_fpu_wflags : io_fromRename_5_bits_fpu_wflags)))));
  assign io_toIssueQueues_5_bits_fpu_typ = (ohSel[5][0] ? io_fromRename_0_bits_fpu_typ : (ohSel[5][1] ? io_fromRename_1_bits_fpu_typ : (ohSel[5][2] ? io_fromRename_2_bits_fpu_typ : (ohSel[5][3] ? io_fromRename_3_bits_fpu_typ : (ohSel[5][4] ? io_fromRename_4_bits_fpu_typ : io_fromRename_5_bits_fpu_typ)))));
  assign io_toIssueQueues_5_bits_fpu_rm = (ohSel[5][0] ? io_fromRename_0_bits_fpu_rm : (ohSel[5][1] ? io_fromRename_1_bits_fpu_rm : (ohSel[5][2] ? io_fromRename_2_bits_fpu_rm : (ohSel[5][3] ? io_fromRename_3_bits_fpu_rm : (ohSel[5][4] ? io_fromRename_4_bits_fpu_rm : io_fromRename_5_bits_fpu_rm)))));
  assign io_toIssueQueues_5_bits_srcState_0 = (ohSel[5][0] ? (allSrcState[0][0][0]) : (ohSel[5][1] ? (allSrcState[1][0][0]) : (ohSel[5][2] ? (allSrcState[2][0][0]) : (ohSel[5][3] ? (allSrcState[3][0][0]) : (ohSel[5][4] ? (allSrcState[4][0][0]) : (allSrcState[5][0][0]))))));
  assign io_toIssueQueues_5_bits_srcState_1 = (ohSel[5][0] ? (allSrcState[0][1][0]) : (ohSel[5][1] ? (allSrcState[1][1][0]) : (ohSel[5][2] ? (allSrcState[2][1][0]) : (ohSel[5][3] ? (allSrcState[3][1][0]) : (ohSel[5][4] ? (allSrcState[4][1][0]) : (allSrcState[5][1][0]))))));
  assign io_toIssueQueues_5_bits_srcLoadDependency_0_0 = (ohSel[5][0] ? fru_srcLoadDep[0][0][0] : (ohSel[5][1] ? fru_srcLoadDep[1][0][0] : (ohSel[5][2] ? fru_srcLoadDep[2][0][0] : (ohSel[5][3] ? fru_srcLoadDep[3][0][0] : (ohSel[5][4] ? fru_srcLoadDep[4][0][0] : fru_srcLoadDep[5][0][0])))));
  assign io_toIssueQueues_5_bits_srcLoadDependency_0_1 = (ohSel[5][0] ? fru_srcLoadDep[0][0][1] : (ohSel[5][1] ? fru_srcLoadDep[1][0][1] : (ohSel[5][2] ? fru_srcLoadDep[2][0][1] : (ohSel[5][3] ? fru_srcLoadDep[3][0][1] : (ohSel[5][4] ? fru_srcLoadDep[4][0][1] : fru_srcLoadDep[5][0][1])))));
  assign io_toIssueQueues_5_bits_srcLoadDependency_0_2 = (ohSel[5][0] ? fru_srcLoadDep[0][0][2] : (ohSel[5][1] ? fru_srcLoadDep[1][0][2] : (ohSel[5][2] ? fru_srcLoadDep[2][0][2] : (ohSel[5][3] ? fru_srcLoadDep[3][0][2] : (ohSel[5][4] ? fru_srcLoadDep[4][0][2] : fru_srcLoadDep[5][0][2])))));
  assign io_toIssueQueues_5_bits_srcLoadDependency_1_0 = (ohSel[5][0] ? fru_srcLoadDep[0][1][0] : (ohSel[5][1] ? fru_srcLoadDep[1][1][0] : (ohSel[5][2] ? fru_srcLoadDep[2][1][0] : (ohSel[5][3] ? fru_srcLoadDep[3][1][0] : (ohSel[5][4] ? fru_srcLoadDep[4][1][0] : fru_srcLoadDep[5][1][0])))));
  assign io_toIssueQueues_5_bits_srcLoadDependency_1_1 = (ohSel[5][0] ? fru_srcLoadDep[0][1][1] : (ohSel[5][1] ? fru_srcLoadDep[1][1][1] : (ohSel[5][2] ? fru_srcLoadDep[2][1][1] : (ohSel[5][3] ? fru_srcLoadDep[3][1][1] : (ohSel[5][4] ? fru_srcLoadDep[4][1][1] : fru_srcLoadDep[5][1][1])))));
  assign io_toIssueQueues_5_bits_srcLoadDependency_1_2 = (ohSel[5][0] ? fru_srcLoadDep[0][1][2] : (ohSel[5][1] ? fru_srcLoadDep[1][1][2] : (ohSel[5][2] ? fru_srcLoadDep[2][1][2] : (ohSel[5][3] ? fru_srcLoadDep[3][1][2] : (ohSel[5][4] ? fru_srcLoadDep[4][1][2] : fru_srcLoadDep[5][1][2])))));
  assign io_toIssueQueues_5_bits_psrc_0 = (ohSel[5][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[5][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[5][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[5][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[5][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_5_bits_psrc_1 = (ohSel[5][0] ? io_fromRename_0_bits_psrc_1 : (ohSel[5][1] ? io_fromRename_1_bits_psrc_1 : (ohSel[5][2] ? io_fromRename_2_bits_psrc_1 : (ohSel[5][3] ? io_fromRename_3_bits_psrc_1 : (ohSel[5][4] ? io_fromRename_4_bits_psrc_1 : io_fromRename_5_bits_psrc_1)))));
  assign io_toIssueQueues_5_bits_pdest = (ohSel[5][0] ? io_fromRename_0_bits_pdest : (ohSel[5][1] ? io_fromRename_1_bits_pdest : (ohSel[5][2] ? io_fromRename_2_bits_pdest : (ohSel[5][3] ? io_fromRename_3_bits_pdest : (ohSel[5][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_5_bits_useRegCache_0 = (ohSel[5][0] ? _rcTagTable_io_readPorts_0_valid : (ohSel[5][1] ? _rcTagTable_io_readPorts_2_valid : (ohSel[5][2] ? _rcTagTable_io_readPorts_4_valid : (ohSel[5][3] ? _rcTagTable_io_readPorts_6_valid : (ohSel[5][4] ? _rcTagTable_io_readPorts_8_valid : _rcTagTable_io_readPorts_10_valid)))));
  assign io_toIssueQueues_5_bits_useRegCache_1 = (ohSel[5][0] ? _rcTagTable_io_readPorts_1_valid : (ohSel[5][1] ? _rcTagTable_io_readPorts_3_valid : (ohSel[5][2] ? _rcTagTable_io_readPorts_5_valid : (ohSel[5][3] ? _rcTagTable_io_readPorts_7_valid : (ohSel[5][4] ? _rcTagTable_io_readPorts_9_valid : _rcTagTable_io_readPorts_11_valid)))));
  assign io_toIssueQueues_5_bits_regCacheIdx_0 = (ohSel[5][0] ? _rcTagTable_io_readPorts_0_addr : (ohSel[5][1] ? _rcTagTable_io_readPorts_2_addr : (ohSel[5][2] ? _rcTagTable_io_readPorts_4_addr : (ohSel[5][3] ? _rcTagTable_io_readPorts_6_addr : (ohSel[5][4] ? _rcTagTable_io_readPorts_8_addr : _rcTagTable_io_readPorts_10_addr)))));
  assign io_toIssueQueues_5_bits_regCacheIdx_1 = (ohSel[5][0] ? _rcTagTable_io_readPorts_1_addr : (ohSel[5][1] ? _rcTagTable_io_readPorts_3_addr : (ohSel[5][2] ? _rcTagTable_io_readPorts_5_addr : (ohSel[5][3] ? _rcTagTable_io_readPorts_7_addr : (ohSel[5][4] ? _rcTagTable_io_readPorts_9_addr : _rcTagTable_io_readPorts_11_addr)))));
  assign io_toIssueQueues_5_bits_robIdx_flag = (ohSel[5][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[5][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[5][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[5][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[5][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_5_bits_robIdx_value = (ohSel[5][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[5][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[5][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[5][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[5][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  // -- 端口 6(IQ 3 enq 0)--
  assign io_toIssueQueues_6_valid = (ohSel[6][0] ? fromRenameUpdate_valid[0] : (ohSel[6][1] ? fromRenameUpdate_valid[1] : (ohSel[6][2] ? fromRenameUpdate_valid[2] : (ohSel[6][3] ? fromRenameUpdate_valid[3] : (ohSel[6][4] ? fromRenameUpdate_valid[4] : (ohSel[6][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_6_bits_ftqPtr_flag = (ohSel[6][0] ? io_fromRename_0_bits_ftqPtr_flag : (ohSel[6][1] ? io_fromRename_1_bits_ftqPtr_flag : (ohSel[6][2] ? io_fromRename_2_bits_ftqPtr_flag : (ohSel[6][3] ? io_fromRename_3_bits_ftqPtr_flag : (ohSel[6][4] ? io_fromRename_4_bits_ftqPtr_flag : io_fromRename_5_bits_ftqPtr_flag)))));
  assign io_toIssueQueues_6_bits_ftqPtr_value = (ohSel[6][0] ? io_fromRename_0_bits_ftqPtr_value : (ohSel[6][1] ? io_fromRename_1_bits_ftqPtr_value : (ohSel[6][2] ? io_fromRename_2_bits_ftqPtr_value : (ohSel[6][3] ? io_fromRename_3_bits_ftqPtr_value : (ohSel[6][4] ? io_fromRename_4_bits_ftqPtr_value : io_fromRename_5_bits_ftqPtr_value)))));
  assign io_toIssueQueues_6_bits_ftqOffset = (ohSel[6][0] ? io_fromRename_0_bits_ftqOffset : (ohSel[6][1] ? io_fromRename_1_bits_ftqOffset : (ohSel[6][2] ? io_fromRename_2_bits_ftqOffset : (ohSel[6][3] ? io_fromRename_3_bits_ftqOffset : (ohSel[6][4] ? io_fromRename_4_bits_ftqOffset : io_fromRename_5_bits_ftqOffset)))));
  assign io_toIssueQueues_6_bits_srcType_0 = (ohSel[6][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[6][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[6][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[6][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[6][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_6_bits_srcType_1 = (ohSel[6][0] ? io_fromRename_0_bits_srcType_1 : (ohSel[6][1] ? io_fromRename_1_bits_srcType_1 : (ohSel[6][2] ? io_fromRename_2_bits_srcType_1 : (ohSel[6][3] ? io_fromRename_3_bits_srcType_1 : (ohSel[6][4] ? io_fromRename_4_bits_srcType_1 : io_fromRename_5_bits_srcType_1)))));
  assign io_toIssueQueues_6_bits_fuType = (ohSel[6][0] ? io_fromRename_0_bits_fuType : (ohSel[6][1] ? io_fromRename_1_bits_fuType : (ohSel[6][2] ? io_fromRename_2_bits_fuType : (ohSel[6][3] ? io_fromRename_3_bits_fuType : (ohSel[6][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_6_bits_fuOpType = (ohSel[6][0] ? io_fromRename_0_bits_fuOpType : (ohSel[6][1] ? io_fromRename_1_bits_fuOpType : (ohSel[6][2] ? io_fromRename_2_bits_fuOpType : (ohSel[6][3] ? io_fromRename_3_bits_fuOpType : (ohSel[6][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_6_bits_rfWen = (ohSel[6][0] ? io_fromRename_0_bits_rfWen : (ohSel[6][1] ? io_fromRename_1_bits_rfWen : (ohSel[6][2] ? io_fromRename_2_bits_rfWen : (ohSel[6][3] ? io_fromRename_3_bits_rfWen : (ohSel[6][4] ? io_fromRename_4_bits_rfWen : io_fromRename_5_bits_rfWen)))));
  assign io_toIssueQueues_6_bits_flushPipe = (ohSel[6][0] ? io_fromRename_0_bits_flushPipe : (ohSel[6][1] ? io_fromRename_1_bits_flushPipe : (ohSel[6][2] ? io_fromRename_2_bits_flushPipe : (ohSel[6][3] ? io_fromRename_3_bits_flushPipe : (ohSel[6][4] ? io_fromRename_4_bits_flushPipe : io_fromRename_5_bits_flushPipe)))));
  assign io_toIssueQueues_6_bits_selImm = (ohSel[6][0] ? io_fromRename_0_bits_selImm : (ohSel[6][1] ? io_fromRename_1_bits_selImm : (ohSel[6][2] ? io_fromRename_2_bits_selImm : (ohSel[6][3] ? io_fromRename_3_bits_selImm : (ohSel[6][4] ? io_fromRename_4_bits_selImm : io_fromRename_5_bits_selImm)))));
  assign io_toIssueQueues_6_bits_imm = (ohSel[6][0] ? io_fromRename_0_bits_imm : (ohSel[6][1] ? io_fromRename_1_bits_imm : (ohSel[6][2] ? io_fromRename_2_bits_imm : (ohSel[6][3] ? io_fromRename_3_bits_imm : (ohSel[6][4] ? io_fromRename_4_bits_imm : io_fromRename_5_bits_imm)))));
  assign io_toIssueQueues_6_bits_srcState_0 = (ohSel[6][0] ? (allSrcState[0][0][0]) : (ohSel[6][1] ? (allSrcState[1][0][0]) : (ohSel[6][2] ? (allSrcState[2][0][0]) : (ohSel[6][3] ? (allSrcState[3][0][0]) : (ohSel[6][4] ? (allSrcState[4][0][0]) : (allSrcState[5][0][0]))))));
  assign io_toIssueQueues_6_bits_srcState_1 = (ohSel[6][0] ? (allSrcState[0][1][0]) : (ohSel[6][1] ? (allSrcState[1][1][0]) : (ohSel[6][2] ? (allSrcState[2][1][0]) : (ohSel[6][3] ? (allSrcState[3][1][0]) : (ohSel[6][4] ? (allSrcState[4][1][0]) : (allSrcState[5][1][0]))))));
  assign io_toIssueQueues_6_bits_srcLoadDependency_0_0 = (ohSel[6][0] ? fru_srcLoadDep[0][0][0] : (ohSel[6][1] ? fru_srcLoadDep[1][0][0] : (ohSel[6][2] ? fru_srcLoadDep[2][0][0] : (ohSel[6][3] ? fru_srcLoadDep[3][0][0] : (ohSel[6][4] ? fru_srcLoadDep[4][0][0] : fru_srcLoadDep[5][0][0])))));
  assign io_toIssueQueues_6_bits_srcLoadDependency_0_1 = (ohSel[6][0] ? fru_srcLoadDep[0][0][1] : (ohSel[6][1] ? fru_srcLoadDep[1][0][1] : (ohSel[6][2] ? fru_srcLoadDep[2][0][1] : (ohSel[6][3] ? fru_srcLoadDep[3][0][1] : (ohSel[6][4] ? fru_srcLoadDep[4][0][1] : fru_srcLoadDep[5][0][1])))));
  assign io_toIssueQueues_6_bits_srcLoadDependency_0_2 = (ohSel[6][0] ? fru_srcLoadDep[0][0][2] : (ohSel[6][1] ? fru_srcLoadDep[1][0][2] : (ohSel[6][2] ? fru_srcLoadDep[2][0][2] : (ohSel[6][3] ? fru_srcLoadDep[3][0][2] : (ohSel[6][4] ? fru_srcLoadDep[4][0][2] : fru_srcLoadDep[5][0][2])))));
  assign io_toIssueQueues_6_bits_srcLoadDependency_1_0 = (ohSel[6][0] ? fru_srcLoadDep[0][1][0] : (ohSel[6][1] ? fru_srcLoadDep[1][1][0] : (ohSel[6][2] ? fru_srcLoadDep[2][1][0] : (ohSel[6][3] ? fru_srcLoadDep[3][1][0] : (ohSel[6][4] ? fru_srcLoadDep[4][1][0] : fru_srcLoadDep[5][1][0])))));
  assign io_toIssueQueues_6_bits_srcLoadDependency_1_1 = (ohSel[6][0] ? fru_srcLoadDep[0][1][1] : (ohSel[6][1] ? fru_srcLoadDep[1][1][1] : (ohSel[6][2] ? fru_srcLoadDep[2][1][1] : (ohSel[6][3] ? fru_srcLoadDep[3][1][1] : (ohSel[6][4] ? fru_srcLoadDep[4][1][1] : fru_srcLoadDep[5][1][1])))));
  assign io_toIssueQueues_6_bits_srcLoadDependency_1_2 = (ohSel[6][0] ? fru_srcLoadDep[0][1][2] : (ohSel[6][1] ? fru_srcLoadDep[1][1][2] : (ohSel[6][2] ? fru_srcLoadDep[2][1][2] : (ohSel[6][3] ? fru_srcLoadDep[3][1][2] : (ohSel[6][4] ? fru_srcLoadDep[4][1][2] : fru_srcLoadDep[5][1][2])))));
  assign io_toIssueQueues_6_bits_psrc_0 = (ohSel[6][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[6][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[6][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[6][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[6][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_6_bits_psrc_1 = (ohSel[6][0] ? io_fromRename_0_bits_psrc_1 : (ohSel[6][1] ? io_fromRename_1_bits_psrc_1 : (ohSel[6][2] ? io_fromRename_2_bits_psrc_1 : (ohSel[6][3] ? io_fromRename_3_bits_psrc_1 : (ohSel[6][4] ? io_fromRename_4_bits_psrc_1 : io_fromRename_5_bits_psrc_1)))));
  assign io_toIssueQueues_6_bits_pdest = (ohSel[6][0] ? io_fromRename_0_bits_pdest : (ohSel[6][1] ? io_fromRename_1_bits_pdest : (ohSel[6][2] ? io_fromRename_2_bits_pdest : (ohSel[6][3] ? io_fromRename_3_bits_pdest : (ohSel[6][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_6_bits_useRegCache_0 = (ohSel[6][0] ? _rcTagTable_io_readPorts_0_valid : (ohSel[6][1] ? _rcTagTable_io_readPorts_2_valid : (ohSel[6][2] ? _rcTagTable_io_readPorts_4_valid : (ohSel[6][3] ? _rcTagTable_io_readPorts_6_valid : (ohSel[6][4] ? _rcTagTable_io_readPorts_8_valid : _rcTagTable_io_readPorts_10_valid)))));
  assign io_toIssueQueues_6_bits_useRegCache_1 = (ohSel[6][0] ? _rcTagTable_io_readPorts_1_valid : (ohSel[6][1] ? _rcTagTable_io_readPorts_3_valid : (ohSel[6][2] ? _rcTagTable_io_readPorts_5_valid : (ohSel[6][3] ? _rcTagTable_io_readPorts_7_valid : (ohSel[6][4] ? _rcTagTable_io_readPorts_9_valid : _rcTagTable_io_readPorts_11_valid)))));
  assign io_toIssueQueues_6_bits_regCacheIdx_0 = (ohSel[6][0] ? _rcTagTable_io_readPorts_0_addr : (ohSel[6][1] ? _rcTagTable_io_readPorts_2_addr : (ohSel[6][2] ? _rcTagTable_io_readPorts_4_addr : (ohSel[6][3] ? _rcTagTable_io_readPorts_6_addr : (ohSel[6][4] ? _rcTagTable_io_readPorts_8_addr : _rcTagTable_io_readPorts_10_addr)))));
  assign io_toIssueQueues_6_bits_regCacheIdx_1 = (ohSel[6][0] ? _rcTagTable_io_readPorts_1_addr : (ohSel[6][1] ? _rcTagTable_io_readPorts_3_addr : (ohSel[6][2] ? _rcTagTable_io_readPorts_5_addr : (ohSel[6][3] ? _rcTagTable_io_readPorts_7_addr : (ohSel[6][4] ? _rcTagTable_io_readPorts_9_addr : _rcTagTable_io_readPorts_11_addr)))));
  assign io_toIssueQueues_6_bits_robIdx_flag = (ohSel[6][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[6][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[6][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[6][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[6][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_6_bits_robIdx_value = (ohSel[6][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[6][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[6][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[6][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[6][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  // -- 端口 7(IQ 3 enq 1)--
  assign io_toIssueQueues_7_valid = (ohSel[7][0] ? fromRenameUpdate_valid[0] : (ohSel[7][1] ? fromRenameUpdate_valid[1] : (ohSel[7][2] ? fromRenameUpdate_valid[2] : (ohSel[7][3] ? fromRenameUpdate_valid[3] : (ohSel[7][4] ? fromRenameUpdate_valid[4] : (ohSel[7][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_7_bits_ftqPtr_flag = (ohSel[7][0] ? io_fromRename_0_bits_ftqPtr_flag : (ohSel[7][1] ? io_fromRename_1_bits_ftqPtr_flag : (ohSel[7][2] ? io_fromRename_2_bits_ftqPtr_flag : (ohSel[7][3] ? io_fromRename_3_bits_ftqPtr_flag : (ohSel[7][4] ? io_fromRename_4_bits_ftqPtr_flag : io_fromRename_5_bits_ftqPtr_flag)))));
  assign io_toIssueQueues_7_bits_ftqPtr_value = (ohSel[7][0] ? io_fromRename_0_bits_ftqPtr_value : (ohSel[7][1] ? io_fromRename_1_bits_ftqPtr_value : (ohSel[7][2] ? io_fromRename_2_bits_ftqPtr_value : (ohSel[7][3] ? io_fromRename_3_bits_ftqPtr_value : (ohSel[7][4] ? io_fromRename_4_bits_ftqPtr_value : io_fromRename_5_bits_ftqPtr_value)))));
  assign io_toIssueQueues_7_bits_ftqOffset = (ohSel[7][0] ? io_fromRename_0_bits_ftqOffset : (ohSel[7][1] ? io_fromRename_1_bits_ftqOffset : (ohSel[7][2] ? io_fromRename_2_bits_ftqOffset : (ohSel[7][3] ? io_fromRename_3_bits_ftqOffset : (ohSel[7][4] ? io_fromRename_4_bits_ftqOffset : io_fromRename_5_bits_ftqOffset)))));
  assign io_toIssueQueues_7_bits_srcType_0 = (ohSel[7][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[7][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[7][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[7][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[7][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_7_bits_srcType_1 = (ohSel[7][0] ? io_fromRename_0_bits_srcType_1 : (ohSel[7][1] ? io_fromRename_1_bits_srcType_1 : (ohSel[7][2] ? io_fromRename_2_bits_srcType_1 : (ohSel[7][3] ? io_fromRename_3_bits_srcType_1 : (ohSel[7][4] ? io_fromRename_4_bits_srcType_1 : io_fromRename_5_bits_srcType_1)))));
  assign io_toIssueQueues_7_bits_fuType = (ohSel[7][0] ? io_fromRename_0_bits_fuType : (ohSel[7][1] ? io_fromRename_1_bits_fuType : (ohSel[7][2] ? io_fromRename_2_bits_fuType : (ohSel[7][3] ? io_fromRename_3_bits_fuType : (ohSel[7][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_7_bits_fuOpType = (ohSel[7][0] ? io_fromRename_0_bits_fuOpType : (ohSel[7][1] ? io_fromRename_1_bits_fuOpType : (ohSel[7][2] ? io_fromRename_2_bits_fuOpType : (ohSel[7][3] ? io_fromRename_3_bits_fuOpType : (ohSel[7][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_7_bits_rfWen = (ohSel[7][0] ? io_fromRename_0_bits_rfWen : (ohSel[7][1] ? io_fromRename_1_bits_rfWen : (ohSel[7][2] ? io_fromRename_2_bits_rfWen : (ohSel[7][3] ? io_fromRename_3_bits_rfWen : (ohSel[7][4] ? io_fromRename_4_bits_rfWen : io_fromRename_5_bits_rfWen)))));
  assign io_toIssueQueues_7_bits_flushPipe = (ohSel[7][0] ? io_fromRename_0_bits_flushPipe : (ohSel[7][1] ? io_fromRename_1_bits_flushPipe : (ohSel[7][2] ? io_fromRename_2_bits_flushPipe : (ohSel[7][3] ? io_fromRename_3_bits_flushPipe : (ohSel[7][4] ? io_fromRename_4_bits_flushPipe : io_fromRename_5_bits_flushPipe)))));
  assign io_toIssueQueues_7_bits_selImm = (ohSel[7][0] ? io_fromRename_0_bits_selImm : (ohSel[7][1] ? io_fromRename_1_bits_selImm : (ohSel[7][2] ? io_fromRename_2_bits_selImm : (ohSel[7][3] ? io_fromRename_3_bits_selImm : (ohSel[7][4] ? io_fromRename_4_bits_selImm : io_fromRename_5_bits_selImm)))));
  assign io_toIssueQueues_7_bits_imm = (ohSel[7][0] ? io_fromRename_0_bits_imm : (ohSel[7][1] ? io_fromRename_1_bits_imm : (ohSel[7][2] ? io_fromRename_2_bits_imm : (ohSel[7][3] ? io_fromRename_3_bits_imm : (ohSel[7][4] ? io_fromRename_4_bits_imm : io_fromRename_5_bits_imm)))));
  assign io_toIssueQueues_7_bits_srcState_0 = (ohSel[7][0] ? (allSrcState[0][0][0]) : (ohSel[7][1] ? (allSrcState[1][0][0]) : (ohSel[7][2] ? (allSrcState[2][0][0]) : (ohSel[7][3] ? (allSrcState[3][0][0]) : (ohSel[7][4] ? (allSrcState[4][0][0]) : (allSrcState[5][0][0]))))));
  assign io_toIssueQueues_7_bits_srcState_1 = (ohSel[7][0] ? (allSrcState[0][1][0]) : (ohSel[7][1] ? (allSrcState[1][1][0]) : (ohSel[7][2] ? (allSrcState[2][1][0]) : (ohSel[7][3] ? (allSrcState[3][1][0]) : (ohSel[7][4] ? (allSrcState[4][1][0]) : (allSrcState[5][1][0]))))));
  assign io_toIssueQueues_7_bits_srcLoadDependency_0_0 = (ohSel[7][0] ? fru_srcLoadDep[0][0][0] : (ohSel[7][1] ? fru_srcLoadDep[1][0][0] : (ohSel[7][2] ? fru_srcLoadDep[2][0][0] : (ohSel[7][3] ? fru_srcLoadDep[3][0][0] : (ohSel[7][4] ? fru_srcLoadDep[4][0][0] : fru_srcLoadDep[5][0][0])))));
  assign io_toIssueQueues_7_bits_srcLoadDependency_0_1 = (ohSel[7][0] ? fru_srcLoadDep[0][0][1] : (ohSel[7][1] ? fru_srcLoadDep[1][0][1] : (ohSel[7][2] ? fru_srcLoadDep[2][0][1] : (ohSel[7][3] ? fru_srcLoadDep[3][0][1] : (ohSel[7][4] ? fru_srcLoadDep[4][0][1] : fru_srcLoadDep[5][0][1])))));
  assign io_toIssueQueues_7_bits_srcLoadDependency_0_2 = (ohSel[7][0] ? fru_srcLoadDep[0][0][2] : (ohSel[7][1] ? fru_srcLoadDep[1][0][2] : (ohSel[7][2] ? fru_srcLoadDep[2][0][2] : (ohSel[7][3] ? fru_srcLoadDep[3][0][2] : (ohSel[7][4] ? fru_srcLoadDep[4][0][2] : fru_srcLoadDep[5][0][2])))));
  assign io_toIssueQueues_7_bits_srcLoadDependency_1_0 = (ohSel[7][0] ? fru_srcLoadDep[0][1][0] : (ohSel[7][1] ? fru_srcLoadDep[1][1][0] : (ohSel[7][2] ? fru_srcLoadDep[2][1][0] : (ohSel[7][3] ? fru_srcLoadDep[3][1][0] : (ohSel[7][4] ? fru_srcLoadDep[4][1][0] : fru_srcLoadDep[5][1][0])))));
  assign io_toIssueQueues_7_bits_srcLoadDependency_1_1 = (ohSel[7][0] ? fru_srcLoadDep[0][1][1] : (ohSel[7][1] ? fru_srcLoadDep[1][1][1] : (ohSel[7][2] ? fru_srcLoadDep[2][1][1] : (ohSel[7][3] ? fru_srcLoadDep[3][1][1] : (ohSel[7][4] ? fru_srcLoadDep[4][1][1] : fru_srcLoadDep[5][1][1])))));
  assign io_toIssueQueues_7_bits_srcLoadDependency_1_2 = (ohSel[7][0] ? fru_srcLoadDep[0][1][2] : (ohSel[7][1] ? fru_srcLoadDep[1][1][2] : (ohSel[7][2] ? fru_srcLoadDep[2][1][2] : (ohSel[7][3] ? fru_srcLoadDep[3][1][2] : (ohSel[7][4] ? fru_srcLoadDep[4][1][2] : fru_srcLoadDep[5][1][2])))));
  assign io_toIssueQueues_7_bits_psrc_0 = (ohSel[7][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[7][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[7][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[7][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[7][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_7_bits_psrc_1 = (ohSel[7][0] ? io_fromRename_0_bits_psrc_1 : (ohSel[7][1] ? io_fromRename_1_bits_psrc_1 : (ohSel[7][2] ? io_fromRename_2_bits_psrc_1 : (ohSel[7][3] ? io_fromRename_3_bits_psrc_1 : (ohSel[7][4] ? io_fromRename_4_bits_psrc_1 : io_fromRename_5_bits_psrc_1)))));
  assign io_toIssueQueues_7_bits_pdest = (ohSel[7][0] ? io_fromRename_0_bits_pdest : (ohSel[7][1] ? io_fromRename_1_bits_pdest : (ohSel[7][2] ? io_fromRename_2_bits_pdest : (ohSel[7][3] ? io_fromRename_3_bits_pdest : (ohSel[7][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_7_bits_useRegCache_0 = (ohSel[7][0] ? _rcTagTable_io_readPorts_0_valid : (ohSel[7][1] ? _rcTagTable_io_readPorts_2_valid : (ohSel[7][2] ? _rcTagTable_io_readPorts_4_valid : (ohSel[7][3] ? _rcTagTable_io_readPorts_6_valid : (ohSel[7][4] ? _rcTagTable_io_readPorts_8_valid : _rcTagTable_io_readPorts_10_valid)))));
  assign io_toIssueQueues_7_bits_useRegCache_1 = (ohSel[7][0] ? _rcTagTable_io_readPorts_1_valid : (ohSel[7][1] ? _rcTagTable_io_readPorts_3_valid : (ohSel[7][2] ? _rcTagTable_io_readPorts_5_valid : (ohSel[7][3] ? _rcTagTable_io_readPorts_7_valid : (ohSel[7][4] ? _rcTagTable_io_readPorts_9_valid : _rcTagTable_io_readPorts_11_valid)))));
  assign io_toIssueQueues_7_bits_regCacheIdx_0 = (ohSel[7][0] ? _rcTagTable_io_readPorts_0_addr : (ohSel[7][1] ? _rcTagTable_io_readPorts_2_addr : (ohSel[7][2] ? _rcTagTable_io_readPorts_4_addr : (ohSel[7][3] ? _rcTagTable_io_readPorts_6_addr : (ohSel[7][4] ? _rcTagTable_io_readPorts_8_addr : _rcTagTable_io_readPorts_10_addr)))));
  assign io_toIssueQueues_7_bits_regCacheIdx_1 = (ohSel[7][0] ? _rcTagTable_io_readPorts_1_addr : (ohSel[7][1] ? _rcTagTable_io_readPorts_3_addr : (ohSel[7][2] ? _rcTagTable_io_readPorts_5_addr : (ohSel[7][3] ? _rcTagTable_io_readPorts_7_addr : (ohSel[7][4] ? _rcTagTable_io_readPorts_9_addr : _rcTagTable_io_readPorts_11_addr)))));
  assign io_toIssueQueues_7_bits_robIdx_flag = (ohSel[7][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[7][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[7][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[7][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[7][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_7_bits_robIdx_value = (ohSel[7][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[7][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[7][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[7][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[7][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  // -- 端口 8(IQ 4 enq 0)--
  assign io_toIssueQueues_8_valid = (ohSel[8][0] ? fromRenameUpdate_valid[0] : (ohSel[8][1] ? fromRenameUpdate_valid[1] : (ohSel[8][2] ? fromRenameUpdate_valid[2] : (ohSel[8][3] ? fromRenameUpdate_valid[3] : (ohSel[8][4] ? fromRenameUpdate_valid[4] : (ohSel[8][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_8_bits_srcType_0 = (ohSel[8][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[8][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[8][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[8][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[8][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_8_bits_srcType_1 = (ohSel[8][0] ? io_fromRename_0_bits_srcType_1 : (ohSel[8][1] ? io_fromRename_1_bits_srcType_1 : (ohSel[8][2] ? io_fromRename_2_bits_srcType_1 : (ohSel[8][3] ? io_fromRename_3_bits_srcType_1 : (ohSel[8][4] ? io_fromRename_4_bits_srcType_1 : io_fromRename_5_bits_srcType_1)))));
  assign io_toIssueQueues_8_bits_srcType_2 = (ohSel[8][0] ? fru_srcType2[0] : (ohSel[8][1] ? fru_srcType2[1] : (ohSel[8][2] ? fru_srcType2[2] : (ohSel[8][3] ? fru_srcType2[3] : (ohSel[8][4] ? fru_srcType2[4] : fru_srcType2[5])))));
  assign io_toIssueQueues_8_bits_fuType = (ohSel[8][0] ? io_fromRename_0_bits_fuType : (ohSel[8][1] ? io_fromRename_1_bits_fuType : (ohSel[8][2] ? io_fromRename_2_bits_fuType : (ohSel[8][3] ? io_fromRename_3_bits_fuType : (ohSel[8][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_8_bits_fuOpType = (ohSel[8][0] ? io_fromRename_0_bits_fuOpType : (ohSel[8][1] ? io_fromRename_1_bits_fuOpType : (ohSel[8][2] ? io_fromRename_2_bits_fuOpType : (ohSel[8][3] ? io_fromRename_3_bits_fuOpType : (ohSel[8][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_8_bits_rfWen = (ohSel[8][0] ? io_fromRename_0_bits_rfWen : (ohSel[8][1] ? io_fromRename_1_bits_rfWen : (ohSel[8][2] ? io_fromRename_2_bits_rfWen : (ohSel[8][3] ? io_fromRename_3_bits_rfWen : (ohSel[8][4] ? io_fromRename_4_bits_rfWen : io_fromRename_5_bits_rfWen)))));
  assign io_toIssueQueues_8_bits_fpWen = (ohSel[8][0] ? io_fromRename_0_bits_fpWen : (ohSel[8][1] ? io_fromRename_1_bits_fpWen : (ohSel[8][2] ? io_fromRename_2_bits_fpWen : (ohSel[8][3] ? io_fromRename_3_bits_fpWen : (ohSel[8][4] ? io_fromRename_4_bits_fpWen : io_fromRename_5_bits_fpWen)))));
  assign io_toIssueQueues_8_bits_vecWen = (ohSel[8][0] ? io_fromRename_0_bits_vecWen : (ohSel[8][1] ? io_fromRename_1_bits_vecWen : (ohSel[8][2] ? io_fromRename_2_bits_vecWen : (ohSel[8][3] ? io_fromRename_3_bits_vecWen : (ohSel[8][4] ? io_fromRename_4_bits_vecWen : io_fromRename_5_bits_vecWen)))));
  assign io_toIssueQueues_8_bits_v0Wen = (ohSel[8][0] ? io_fromRename_0_bits_v0Wen : (ohSel[8][1] ? io_fromRename_1_bits_v0Wen : (ohSel[8][2] ? io_fromRename_2_bits_v0Wen : (ohSel[8][3] ? io_fromRename_3_bits_v0Wen : (ohSel[8][4] ? io_fromRename_4_bits_v0Wen : io_fromRename_5_bits_v0Wen)))));
  assign io_toIssueQueues_8_bits_fpu_wflags = (ohSel[8][0] ? io_fromRename_0_bits_fpu_wflags : (ohSel[8][1] ? io_fromRename_1_bits_fpu_wflags : (ohSel[8][2] ? io_fromRename_2_bits_fpu_wflags : (ohSel[8][3] ? io_fromRename_3_bits_fpu_wflags : (ohSel[8][4] ? io_fromRename_4_bits_fpu_wflags : io_fromRename_5_bits_fpu_wflags)))));
  assign io_toIssueQueues_8_bits_fpu_fmt = (ohSel[8][0] ? io_fromRename_0_bits_fpu_fmt : (ohSel[8][1] ? io_fromRename_1_bits_fpu_fmt : (ohSel[8][2] ? io_fromRename_2_bits_fpu_fmt : (ohSel[8][3] ? io_fromRename_3_bits_fpu_fmt : (ohSel[8][4] ? io_fromRename_4_bits_fpu_fmt : io_fromRename_5_bits_fpu_fmt)))));
  assign io_toIssueQueues_8_bits_fpu_rm = (ohSel[8][0] ? io_fromRename_0_bits_fpu_rm : (ohSel[8][1] ? io_fromRename_1_bits_fpu_rm : (ohSel[8][2] ? io_fromRename_2_bits_fpu_rm : (ohSel[8][3] ? io_fromRename_3_bits_fpu_rm : (ohSel[8][4] ? io_fromRename_4_bits_fpu_rm : io_fromRename_5_bits_fpu_rm)))));
  assign io_toIssueQueues_8_bits_srcState_0 = (ohSel[8][0] ? (allSrcState[0][0][1]) : (ohSel[8][1] ? (allSrcState[1][0][1]) : (ohSel[8][2] ? (allSrcState[2][0][1]) : (ohSel[8][3] ? (allSrcState[3][0][1]) : (ohSel[8][4] ? (allSrcState[4][0][1]) : (allSrcState[5][0][1]))))));
  assign io_toIssueQueues_8_bits_srcState_1 = (ohSel[8][0] ? (allSrcState[0][1][1]) : (ohSel[8][1] ? (allSrcState[1][1][1]) : (ohSel[8][2] ? (allSrcState[2][1][1]) : (ohSel[8][3] ? (allSrcState[3][1][1]) : (ohSel[8][4] ? (allSrcState[4][1][1]) : (allSrcState[5][1][1]))))));
  assign io_toIssueQueues_8_bits_srcState_2 = (ohSel[8][0] ? (allSrcState[0][2][1]) : (ohSel[8][1] ? (allSrcState[1][2][1]) : (ohSel[8][2] ? (allSrcState[2][2][1]) : (ohSel[8][3] ? (allSrcState[3][2][1]) : (ohSel[8][4] ? (allSrcState[4][2][1]) : (allSrcState[5][2][1]))))));
  assign io_toIssueQueues_8_bits_psrc_0 = (ohSel[8][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[8][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[8][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[8][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[8][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_8_bits_psrc_1 = (ohSel[8][0] ? io_fromRename_0_bits_psrc_1 : (ohSel[8][1] ? io_fromRename_1_bits_psrc_1 : (ohSel[8][2] ? io_fromRename_2_bits_psrc_1 : (ohSel[8][3] ? io_fromRename_3_bits_psrc_1 : (ohSel[8][4] ? io_fromRename_4_bits_psrc_1 : io_fromRename_5_bits_psrc_1)))));
  assign io_toIssueQueues_8_bits_psrc_2 = (ohSel[8][0] ? io_fromRename_0_bits_psrc_2 : (ohSel[8][1] ? io_fromRename_1_bits_psrc_2 : (ohSel[8][2] ? io_fromRename_2_bits_psrc_2 : (ohSel[8][3] ? io_fromRename_3_bits_psrc_2 : (ohSel[8][4] ? io_fromRename_4_bits_psrc_2 : io_fromRename_5_bits_psrc_2)))));
  assign io_toIssueQueues_8_bits_pdest = (ohSel[8][0] ? io_fromRename_0_bits_pdest : (ohSel[8][1] ? io_fromRename_1_bits_pdest : (ohSel[8][2] ? io_fromRename_2_bits_pdest : (ohSel[8][3] ? io_fromRename_3_bits_pdest : (ohSel[8][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_8_bits_robIdx_flag = (ohSel[8][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[8][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[8][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[8][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[8][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_8_bits_robIdx_value = (ohSel[8][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[8][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[8][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[8][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[8][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  // -- 端口 9(IQ 4 enq 1)--
  assign io_toIssueQueues_9_valid = (ohSel[9][0] ? fromRenameUpdate_valid[0] : (ohSel[9][1] ? fromRenameUpdate_valid[1] : (ohSel[9][2] ? fromRenameUpdate_valid[2] : (ohSel[9][3] ? fromRenameUpdate_valid[3] : (ohSel[9][4] ? fromRenameUpdate_valid[4] : (ohSel[9][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_9_bits_srcType_0 = (ohSel[9][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[9][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[9][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[9][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[9][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_9_bits_srcType_1 = (ohSel[9][0] ? io_fromRename_0_bits_srcType_1 : (ohSel[9][1] ? io_fromRename_1_bits_srcType_1 : (ohSel[9][2] ? io_fromRename_2_bits_srcType_1 : (ohSel[9][3] ? io_fromRename_3_bits_srcType_1 : (ohSel[9][4] ? io_fromRename_4_bits_srcType_1 : io_fromRename_5_bits_srcType_1)))));
  assign io_toIssueQueues_9_bits_srcType_2 = (ohSel[9][0] ? fru_srcType2[0] : (ohSel[9][1] ? fru_srcType2[1] : (ohSel[9][2] ? fru_srcType2[2] : (ohSel[9][3] ? fru_srcType2[3] : (ohSel[9][4] ? fru_srcType2[4] : fru_srcType2[5])))));
  assign io_toIssueQueues_9_bits_fuType = (ohSel[9][0] ? io_fromRename_0_bits_fuType : (ohSel[9][1] ? io_fromRename_1_bits_fuType : (ohSel[9][2] ? io_fromRename_2_bits_fuType : (ohSel[9][3] ? io_fromRename_3_bits_fuType : (ohSel[9][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_9_bits_fuOpType = (ohSel[9][0] ? io_fromRename_0_bits_fuOpType : (ohSel[9][1] ? io_fromRename_1_bits_fuOpType : (ohSel[9][2] ? io_fromRename_2_bits_fuOpType : (ohSel[9][3] ? io_fromRename_3_bits_fuOpType : (ohSel[9][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_9_bits_rfWen = (ohSel[9][0] ? io_fromRename_0_bits_rfWen : (ohSel[9][1] ? io_fromRename_1_bits_rfWen : (ohSel[9][2] ? io_fromRename_2_bits_rfWen : (ohSel[9][3] ? io_fromRename_3_bits_rfWen : (ohSel[9][4] ? io_fromRename_4_bits_rfWen : io_fromRename_5_bits_rfWen)))));
  assign io_toIssueQueues_9_bits_fpWen = (ohSel[9][0] ? io_fromRename_0_bits_fpWen : (ohSel[9][1] ? io_fromRename_1_bits_fpWen : (ohSel[9][2] ? io_fromRename_2_bits_fpWen : (ohSel[9][3] ? io_fromRename_3_bits_fpWen : (ohSel[9][4] ? io_fromRename_4_bits_fpWen : io_fromRename_5_bits_fpWen)))));
  assign io_toIssueQueues_9_bits_vecWen = (ohSel[9][0] ? io_fromRename_0_bits_vecWen : (ohSel[9][1] ? io_fromRename_1_bits_vecWen : (ohSel[9][2] ? io_fromRename_2_bits_vecWen : (ohSel[9][3] ? io_fromRename_3_bits_vecWen : (ohSel[9][4] ? io_fromRename_4_bits_vecWen : io_fromRename_5_bits_vecWen)))));
  assign io_toIssueQueues_9_bits_v0Wen = (ohSel[9][0] ? io_fromRename_0_bits_v0Wen : (ohSel[9][1] ? io_fromRename_1_bits_v0Wen : (ohSel[9][2] ? io_fromRename_2_bits_v0Wen : (ohSel[9][3] ? io_fromRename_3_bits_v0Wen : (ohSel[9][4] ? io_fromRename_4_bits_v0Wen : io_fromRename_5_bits_v0Wen)))));
  assign io_toIssueQueues_9_bits_fpu_wflags = (ohSel[9][0] ? io_fromRename_0_bits_fpu_wflags : (ohSel[9][1] ? io_fromRename_1_bits_fpu_wflags : (ohSel[9][2] ? io_fromRename_2_bits_fpu_wflags : (ohSel[9][3] ? io_fromRename_3_bits_fpu_wflags : (ohSel[9][4] ? io_fromRename_4_bits_fpu_wflags : io_fromRename_5_bits_fpu_wflags)))));
  assign io_toIssueQueues_9_bits_fpu_fmt = (ohSel[9][0] ? io_fromRename_0_bits_fpu_fmt : (ohSel[9][1] ? io_fromRename_1_bits_fpu_fmt : (ohSel[9][2] ? io_fromRename_2_bits_fpu_fmt : (ohSel[9][3] ? io_fromRename_3_bits_fpu_fmt : (ohSel[9][4] ? io_fromRename_4_bits_fpu_fmt : io_fromRename_5_bits_fpu_fmt)))));
  assign io_toIssueQueues_9_bits_fpu_rm = (ohSel[9][0] ? io_fromRename_0_bits_fpu_rm : (ohSel[9][1] ? io_fromRename_1_bits_fpu_rm : (ohSel[9][2] ? io_fromRename_2_bits_fpu_rm : (ohSel[9][3] ? io_fromRename_3_bits_fpu_rm : (ohSel[9][4] ? io_fromRename_4_bits_fpu_rm : io_fromRename_5_bits_fpu_rm)))));
  assign io_toIssueQueues_9_bits_srcState_0 = (ohSel[9][0] ? (allSrcState[0][0][1]) : (ohSel[9][1] ? (allSrcState[1][0][1]) : (ohSel[9][2] ? (allSrcState[2][0][1]) : (ohSel[9][3] ? (allSrcState[3][0][1]) : (ohSel[9][4] ? (allSrcState[4][0][1]) : (allSrcState[5][0][1]))))));
  assign io_toIssueQueues_9_bits_srcState_1 = (ohSel[9][0] ? (allSrcState[0][1][1]) : (ohSel[9][1] ? (allSrcState[1][1][1]) : (ohSel[9][2] ? (allSrcState[2][1][1]) : (ohSel[9][3] ? (allSrcState[3][1][1]) : (ohSel[9][4] ? (allSrcState[4][1][1]) : (allSrcState[5][1][1]))))));
  assign io_toIssueQueues_9_bits_srcState_2 = (ohSel[9][0] ? (allSrcState[0][2][1]) : (ohSel[9][1] ? (allSrcState[1][2][1]) : (ohSel[9][2] ? (allSrcState[2][2][1]) : (ohSel[9][3] ? (allSrcState[3][2][1]) : (ohSel[9][4] ? (allSrcState[4][2][1]) : (allSrcState[5][2][1]))))));
  assign io_toIssueQueues_9_bits_psrc_0 = (ohSel[9][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[9][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[9][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[9][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[9][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_9_bits_psrc_1 = (ohSel[9][0] ? io_fromRename_0_bits_psrc_1 : (ohSel[9][1] ? io_fromRename_1_bits_psrc_1 : (ohSel[9][2] ? io_fromRename_2_bits_psrc_1 : (ohSel[9][3] ? io_fromRename_3_bits_psrc_1 : (ohSel[9][4] ? io_fromRename_4_bits_psrc_1 : io_fromRename_5_bits_psrc_1)))));
  assign io_toIssueQueues_9_bits_psrc_2 = (ohSel[9][0] ? io_fromRename_0_bits_psrc_2 : (ohSel[9][1] ? io_fromRename_1_bits_psrc_2 : (ohSel[9][2] ? io_fromRename_2_bits_psrc_2 : (ohSel[9][3] ? io_fromRename_3_bits_psrc_2 : (ohSel[9][4] ? io_fromRename_4_bits_psrc_2 : io_fromRename_5_bits_psrc_2)))));
  assign io_toIssueQueues_9_bits_pdest = (ohSel[9][0] ? io_fromRename_0_bits_pdest : (ohSel[9][1] ? io_fromRename_1_bits_pdest : (ohSel[9][2] ? io_fromRename_2_bits_pdest : (ohSel[9][3] ? io_fromRename_3_bits_pdest : (ohSel[9][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_9_bits_robIdx_flag = (ohSel[9][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[9][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[9][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[9][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[9][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_9_bits_robIdx_value = (ohSel[9][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[9][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[9][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[9][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[9][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  // -- 端口 10(IQ 5 enq 0)--
  assign io_toIssueQueues_10_valid = (ohSel[10][0] ? fromRenameUpdate_valid[0] : (ohSel[10][1] ? fromRenameUpdate_valid[1] : (ohSel[10][2] ? fromRenameUpdate_valid[2] : (ohSel[10][3] ? fromRenameUpdate_valid[3] : (ohSel[10][4] ? fromRenameUpdate_valid[4] : (ohSel[10][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_10_bits_srcType_0 = (ohSel[10][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[10][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[10][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[10][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[10][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_10_bits_srcType_1 = (ohSel[10][0] ? io_fromRename_0_bits_srcType_1 : (ohSel[10][1] ? io_fromRename_1_bits_srcType_1 : (ohSel[10][2] ? io_fromRename_2_bits_srcType_1 : (ohSel[10][3] ? io_fromRename_3_bits_srcType_1 : (ohSel[10][4] ? io_fromRename_4_bits_srcType_1 : io_fromRename_5_bits_srcType_1)))));
  assign io_toIssueQueues_10_bits_srcType_2 = (ohSel[10][0] ? fru_srcType2[0] : (ohSel[10][1] ? fru_srcType2[1] : (ohSel[10][2] ? fru_srcType2[2] : (ohSel[10][3] ? fru_srcType2[3] : (ohSel[10][4] ? fru_srcType2[4] : fru_srcType2[5])))));
  assign io_toIssueQueues_10_bits_fuType = (ohSel[10][0] ? io_fromRename_0_bits_fuType : (ohSel[10][1] ? io_fromRename_1_bits_fuType : (ohSel[10][2] ? io_fromRename_2_bits_fuType : (ohSel[10][3] ? io_fromRename_3_bits_fuType : (ohSel[10][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_10_bits_fuOpType = (ohSel[10][0] ? io_fromRename_0_bits_fuOpType : (ohSel[10][1] ? io_fromRename_1_bits_fuOpType : (ohSel[10][2] ? io_fromRename_2_bits_fuOpType : (ohSel[10][3] ? io_fromRename_3_bits_fuOpType : (ohSel[10][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_10_bits_rfWen = (ohSel[10][0] ? io_fromRename_0_bits_rfWen : (ohSel[10][1] ? io_fromRename_1_bits_rfWen : (ohSel[10][2] ? io_fromRename_2_bits_rfWen : (ohSel[10][3] ? io_fromRename_3_bits_rfWen : (ohSel[10][4] ? io_fromRename_4_bits_rfWen : io_fromRename_5_bits_rfWen)))));
  assign io_toIssueQueues_10_bits_fpWen = (ohSel[10][0] ? io_fromRename_0_bits_fpWen : (ohSel[10][1] ? io_fromRename_1_bits_fpWen : (ohSel[10][2] ? io_fromRename_2_bits_fpWen : (ohSel[10][3] ? io_fromRename_3_bits_fpWen : (ohSel[10][4] ? io_fromRename_4_bits_fpWen : io_fromRename_5_bits_fpWen)))));
  assign io_toIssueQueues_10_bits_fpu_wflags = (ohSel[10][0] ? io_fromRename_0_bits_fpu_wflags : (ohSel[10][1] ? io_fromRename_1_bits_fpu_wflags : (ohSel[10][2] ? io_fromRename_2_bits_fpu_wflags : (ohSel[10][3] ? io_fromRename_3_bits_fpu_wflags : (ohSel[10][4] ? io_fromRename_4_bits_fpu_wflags : io_fromRename_5_bits_fpu_wflags)))));
  assign io_toIssueQueues_10_bits_fpu_fmt = (ohSel[10][0] ? io_fromRename_0_bits_fpu_fmt : (ohSel[10][1] ? io_fromRename_1_bits_fpu_fmt : (ohSel[10][2] ? io_fromRename_2_bits_fpu_fmt : (ohSel[10][3] ? io_fromRename_3_bits_fpu_fmt : (ohSel[10][4] ? io_fromRename_4_bits_fpu_fmt : io_fromRename_5_bits_fpu_fmt)))));
  assign io_toIssueQueues_10_bits_fpu_rm = (ohSel[10][0] ? io_fromRename_0_bits_fpu_rm : (ohSel[10][1] ? io_fromRename_1_bits_fpu_rm : (ohSel[10][2] ? io_fromRename_2_bits_fpu_rm : (ohSel[10][3] ? io_fromRename_3_bits_fpu_rm : (ohSel[10][4] ? io_fromRename_4_bits_fpu_rm : io_fromRename_5_bits_fpu_rm)))));
  assign io_toIssueQueues_10_bits_srcState_0 = (ohSel[10][0] ? (allSrcState[0][0][1]) : (ohSel[10][1] ? (allSrcState[1][0][1]) : (ohSel[10][2] ? (allSrcState[2][0][1]) : (ohSel[10][3] ? (allSrcState[3][0][1]) : (ohSel[10][4] ? (allSrcState[4][0][1]) : (allSrcState[5][0][1]))))));
  assign io_toIssueQueues_10_bits_srcState_1 = (ohSel[10][0] ? (allSrcState[0][1][1]) : (ohSel[10][1] ? (allSrcState[1][1][1]) : (ohSel[10][2] ? (allSrcState[2][1][1]) : (ohSel[10][3] ? (allSrcState[3][1][1]) : (ohSel[10][4] ? (allSrcState[4][1][1]) : (allSrcState[5][1][1]))))));
  assign io_toIssueQueues_10_bits_srcState_2 = (ohSel[10][0] ? (allSrcState[0][2][1]) : (ohSel[10][1] ? (allSrcState[1][2][1]) : (ohSel[10][2] ? (allSrcState[2][2][1]) : (ohSel[10][3] ? (allSrcState[3][2][1]) : (ohSel[10][4] ? (allSrcState[4][2][1]) : (allSrcState[5][2][1]))))));
  assign io_toIssueQueues_10_bits_psrc_0 = (ohSel[10][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[10][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[10][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[10][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[10][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_10_bits_psrc_1 = (ohSel[10][0] ? io_fromRename_0_bits_psrc_1 : (ohSel[10][1] ? io_fromRename_1_bits_psrc_1 : (ohSel[10][2] ? io_fromRename_2_bits_psrc_1 : (ohSel[10][3] ? io_fromRename_3_bits_psrc_1 : (ohSel[10][4] ? io_fromRename_4_bits_psrc_1 : io_fromRename_5_bits_psrc_1)))));
  assign io_toIssueQueues_10_bits_psrc_2 = (ohSel[10][0] ? io_fromRename_0_bits_psrc_2 : (ohSel[10][1] ? io_fromRename_1_bits_psrc_2 : (ohSel[10][2] ? io_fromRename_2_bits_psrc_2 : (ohSel[10][3] ? io_fromRename_3_bits_psrc_2 : (ohSel[10][4] ? io_fromRename_4_bits_psrc_2 : io_fromRename_5_bits_psrc_2)))));
  assign io_toIssueQueues_10_bits_pdest = (ohSel[10][0] ? io_fromRename_0_bits_pdest : (ohSel[10][1] ? io_fromRename_1_bits_pdest : (ohSel[10][2] ? io_fromRename_2_bits_pdest : (ohSel[10][3] ? io_fromRename_3_bits_pdest : (ohSel[10][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_10_bits_robIdx_flag = (ohSel[10][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[10][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[10][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[10][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[10][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_10_bits_robIdx_value = (ohSel[10][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[10][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[10][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[10][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[10][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  // -- 端口 11(IQ 5 enq 1)--
  assign io_toIssueQueues_11_valid = (ohSel[11][0] ? fromRenameUpdate_valid[0] : (ohSel[11][1] ? fromRenameUpdate_valid[1] : (ohSel[11][2] ? fromRenameUpdate_valid[2] : (ohSel[11][3] ? fromRenameUpdate_valid[3] : (ohSel[11][4] ? fromRenameUpdate_valid[4] : (ohSel[11][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_11_bits_srcType_0 = (ohSel[11][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[11][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[11][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[11][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[11][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_11_bits_srcType_1 = (ohSel[11][0] ? io_fromRename_0_bits_srcType_1 : (ohSel[11][1] ? io_fromRename_1_bits_srcType_1 : (ohSel[11][2] ? io_fromRename_2_bits_srcType_1 : (ohSel[11][3] ? io_fromRename_3_bits_srcType_1 : (ohSel[11][4] ? io_fromRename_4_bits_srcType_1 : io_fromRename_5_bits_srcType_1)))));
  assign io_toIssueQueues_11_bits_srcType_2 = (ohSel[11][0] ? fru_srcType2[0] : (ohSel[11][1] ? fru_srcType2[1] : (ohSel[11][2] ? fru_srcType2[2] : (ohSel[11][3] ? fru_srcType2[3] : (ohSel[11][4] ? fru_srcType2[4] : fru_srcType2[5])))));
  assign io_toIssueQueues_11_bits_fuType = (ohSel[11][0] ? io_fromRename_0_bits_fuType : (ohSel[11][1] ? io_fromRename_1_bits_fuType : (ohSel[11][2] ? io_fromRename_2_bits_fuType : (ohSel[11][3] ? io_fromRename_3_bits_fuType : (ohSel[11][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_11_bits_fuOpType = (ohSel[11][0] ? io_fromRename_0_bits_fuOpType : (ohSel[11][1] ? io_fromRename_1_bits_fuOpType : (ohSel[11][2] ? io_fromRename_2_bits_fuOpType : (ohSel[11][3] ? io_fromRename_3_bits_fuOpType : (ohSel[11][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_11_bits_rfWen = (ohSel[11][0] ? io_fromRename_0_bits_rfWen : (ohSel[11][1] ? io_fromRename_1_bits_rfWen : (ohSel[11][2] ? io_fromRename_2_bits_rfWen : (ohSel[11][3] ? io_fromRename_3_bits_rfWen : (ohSel[11][4] ? io_fromRename_4_bits_rfWen : io_fromRename_5_bits_rfWen)))));
  assign io_toIssueQueues_11_bits_fpWen = (ohSel[11][0] ? io_fromRename_0_bits_fpWen : (ohSel[11][1] ? io_fromRename_1_bits_fpWen : (ohSel[11][2] ? io_fromRename_2_bits_fpWen : (ohSel[11][3] ? io_fromRename_3_bits_fpWen : (ohSel[11][4] ? io_fromRename_4_bits_fpWen : io_fromRename_5_bits_fpWen)))));
  assign io_toIssueQueues_11_bits_fpu_wflags = (ohSel[11][0] ? io_fromRename_0_bits_fpu_wflags : (ohSel[11][1] ? io_fromRename_1_bits_fpu_wflags : (ohSel[11][2] ? io_fromRename_2_bits_fpu_wflags : (ohSel[11][3] ? io_fromRename_3_bits_fpu_wflags : (ohSel[11][4] ? io_fromRename_4_bits_fpu_wflags : io_fromRename_5_bits_fpu_wflags)))));
  assign io_toIssueQueues_11_bits_fpu_fmt = (ohSel[11][0] ? io_fromRename_0_bits_fpu_fmt : (ohSel[11][1] ? io_fromRename_1_bits_fpu_fmt : (ohSel[11][2] ? io_fromRename_2_bits_fpu_fmt : (ohSel[11][3] ? io_fromRename_3_bits_fpu_fmt : (ohSel[11][4] ? io_fromRename_4_bits_fpu_fmt : io_fromRename_5_bits_fpu_fmt)))));
  assign io_toIssueQueues_11_bits_fpu_rm = (ohSel[11][0] ? io_fromRename_0_bits_fpu_rm : (ohSel[11][1] ? io_fromRename_1_bits_fpu_rm : (ohSel[11][2] ? io_fromRename_2_bits_fpu_rm : (ohSel[11][3] ? io_fromRename_3_bits_fpu_rm : (ohSel[11][4] ? io_fromRename_4_bits_fpu_rm : io_fromRename_5_bits_fpu_rm)))));
  assign io_toIssueQueues_11_bits_srcState_0 = (ohSel[11][0] ? (allSrcState[0][0][1]) : (ohSel[11][1] ? (allSrcState[1][0][1]) : (ohSel[11][2] ? (allSrcState[2][0][1]) : (ohSel[11][3] ? (allSrcState[3][0][1]) : (ohSel[11][4] ? (allSrcState[4][0][1]) : (allSrcState[5][0][1]))))));
  assign io_toIssueQueues_11_bits_srcState_1 = (ohSel[11][0] ? (allSrcState[0][1][1]) : (ohSel[11][1] ? (allSrcState[1][1][1]) : (ohSel[11][2] ? (allSrcState[2][1][1]) : (ohSel[11][3] ? (allSrcState[3][1][1]) : (ohSel[11][4] ? (allSrcState[4][1][1]) : (allSrcState[5][1][1]))))));
  assign io_toIssueQueues_11_bits_srcState_2 = (ohSel[11][0] ? (allSrcState[0][2][1]) : (ohSel[11][1] ? (allSrcState[1][2][1]) : (ohSel[11][2] ? (allSrcState[2][2][1]) : (ohSel[11][3] ? (allSrcState[3][2][1]) : (ohSel[11][4] ? (allSrcState[4][2][1]) : (allSrcState[5][2][1]))))));
  assign io_toIssueQueues_11_bits_psrc_0 = (ohSel[11][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[11][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[11][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[11][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[11][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_11_bits_psrc_1 = (ohSel[11][0] ? io_fromRename_0_bits_psrc_1 : (ohSel[11][1] ? io_fromRename_1_bits_psrc_1 : (ohSel[11][2] ? io_fromRename_2_bits_psrc_1 : (ohSel[11][3] ? io_fromRename_3_bits_psrc_1 : (ohSel[11][4] ? io_fromRename_4_bits_psrc_1 : io_fromRename_5_bits_psrc_1)))));
  assign io_toIssueQueues_11_bits_psrc_2 = (ohSel[11][0] ? io_fromRename_0_bits_psrc_2 : (ohSel[11][1] ? io_fromRename_1_bits_psrc_2 : (ohSel[11][2] ? io_fromRename_2_bits_psrc_2 : (ohSel[11][3] ? io_fromRename_3_bits_psrc_2 : (ohSel[11][4] ? io_fromRename_4_bits_psrc_2 : io_fromRename_5_bits_psrc_2)))));
  assign io_toIssueQueues_11_bits_pdest = (ohSel[11][0] ? io_fromRename_0_bits_pdest : (ohSel[11][1] ? io_fromRename_1_bits_pdest : (ohSel[11][2] ? io_fromRename_2_bits_pdest : (ohSel[11][3] ? io_fromRename_3_bits_pdest : (ohSel[11][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_11_bits_robIdx_flag = (ohSel[11][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[11][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[11][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[11][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[11][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_11_bits_robIdx_value = (ohSel[11][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[11][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[11][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[11][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[11][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  // -- 端口 12(IQ 6 enq 0)--
  assign io_toIssueQueues_12_valid = (ohSel[12][0] ? fromRenameUpdate_valid[0] : (ohSel[12][1] ? fromRenameUpdate_valid[1] : (ohSel[12][2] ? fromRenameUpdate_valid[2] : (ohSel[12][3] ? fromRenameUpdate_valid[3] : (ohSel[12][4] ? fromRenameUpdate_valid[4] : (ohSel[12][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_12_bits_srcType_0 = (ohSel[12][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[12][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[12][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[12][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[12][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_12_bits_srcType_1 = (ohSel[12][0] ? io_fromRename_0_bits_srcType_1 : (ohSel[12][1] ? io_fromRename_1_bits_srcType_1 : (ohSel[12][2] ? io_fromRename_2_bits_srcType_1 : (ohSel[12][3] ? io_fromRename_3_bits_srcType_1 : (ohSel[12][4] ? io_fromRename_4_bits_srcType_1 : io_fromRename_5_bits_srcType_1)))));
  assign io_toIssueQueues_12_bits_srcType_2 = (ohSel[12][0] ? fru_srcType2[0] : (ohSel[12][1] ? fru_srcType2[1] : (ohSel[12][2] ? fru_srcType2[2] : (ohSel[12][3] ? fru_srcType2[3] : (ohSel[12][4] ? fru_srcType2[4] : fru_srcType2[5])))));
  assign io_toIssueQueues_12_bits_fuType = (ohSel[12][0] ? io_fromRename_0_bits_fuType : (ohSel[12][1] ? io_fromRename_1_bits_fuType : (ohSel[12][2] ? io_fromRename_2_bits_fuType : (ohSel[12][3] ? io_fromRename_3_bits_fuType : (ohSel[12][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_12_bits_fuOpType = (ohSel[12][0] ? io_fromRename_0_bits_fuOpType : (ohSel[12][1] ? io_fromRename_1_bits_fuOpType : (ohSel[12][2] ? io_fromRename_2_bits_fuOpType : (ohSel[12][3] ? io_fromRename_3_bits_fuOpType : (ohSel[12][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_12_bits_rfWen = (ohSel[12][0] ? io_fromRename_0_bits_rfWen : (ohSel[12][1] ? io_fromRename_1_bits_rfWen : (ohSel[12][2] ? io_fromRename_2_bits_rfWen : (ohSel[12][3] ? io_fromRename_3_bits_rfWen : (ohSel[12][4] ? io_fromRename_4_bits_rfWen : io_fromRename_5_bits_rfWen)))));
  assign io_toIssueQueues_12_bits_fpWen = (ohSel[12][0] ? io_fromRename_0_bits_fpWen : (ohSel[12][1] ? io_fromRename_1_bits_fpWen : (ohSel[12][2] ? io_fromRename_2_bits_fpWen : (ohSel[12][3] ? io_fromRename_3_bits_fpWen : (ohSel[12][4] ? io_fromRename_4_bits_fpWen : io_fromRename_5_bits_fpWen)))));
  assign io_toIssueQueues_12_bits_fpu_wflags = (ohSel[12][0] ? io_fromRename_0_bits_fpu_wflags : (ohSel[12][1] ? io_fromRename_1_bits_fpu_wflags : (ohSel[12][2] ? io_fromRename_2_bits_fpu_wflags : (ohSel[12][3] ? io_fromRename_3_bits_fpu_wflags : (ohSel[12][4] ? io_fromRename_4_bits_fpu_wflags : io_fromRename_5_bits_fpu_wflags)))));
  assign io_toIssueQueues_12_bits_fpu_fmt = (ohSel[12][0] ? io_fromRename_0_bits_fpu_fmt : (ohSel[12][1] ? io_fromRename_1_bits_fpu_fmt : (ohSel[12][2] ? io_fromRename_2_bits_fpu_fmt : (ohSel[12][3] ? io_fromRename_3_bits_fpu_fmt : (ohSel[12][4] ? io_fromRename_4_bits_fpu_fmt : io_fromRename_5_bits_fpu_fmt)))));
  assign io_toIssueQueues_12_bits_fpu_rm = (ohSel[12][0] ? io_fromRename_0_bits_fpu_rm : (ohSel[12][1] ? io_fromRename_1_bits_fpu_rm : (ohSel[12][2] ? io_fromRename_2_bits_fpu_rm : (ohSel[12][3] ? io_fromRename_3_bits_fpu_rm : (ohSel[12][4] ? io_fromRename_4_bits_fpu_rm : io_fromRename_5_bits_fpu_rm)))));
  assign io_toIssueQueues_12_bits_srcState_0 = (ohSel[12][0] ? (allSrcState[0][0][1]) : (ohSel[12][1] ? (allSrcState[1][0][1]) : (ohSel[12][2] ? (allSrcState[2][0][1]) : (ohSel[12][3] ? (allSrcState[3][0][1]) : (ohSel[12][4] ? (allSrcState[4][0][1]) : (allSrcState[5][0][1]))))));
  assign io_toIssueQueues_12_bits_srcState_1 = (ohSel[12][0] ? (allSrcState[0][1][1]) : (ohSel[12][1] ? (allSrcState[1][1][1]) : (ohSel[12][2] ? (allSrcState[2][1][1]) : (ohSel[12][3] ? (allSrcState[3][1][1]) : (ohSel[12][4] ? (allSrcState[4][1][1]) : (allSrcState[5][1][1]))))));
  assign io_toIssueQueues_12_bits_srcState_2 = (ohSel[12][0] ? (allSrcState[0][2][1]) : (ohSel[12][1] ? (allSrcState[1][2][1]) : (ohSel[12][2] ? (allSrcState[2][2][1]) : (ohSel[12][3] ? (allSrcState[3][2][1]) : (ohSel[12][4] ? (allSrcState[4][2][1]) : (allSrcState[5][2][1]))))));
  assign io_toIssueQueues_12_bits_psrc_0 = (ohSel[12][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[12][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[12][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[12][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[12][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_12_bits_psrc_1 = (ohSel[12][0] ? io_fromRename_0_bits_psrc_1 : (ohSel[12][1] ? io_fromRename_1_bits_psrc_1 : (ohSel[12][2] ? io_fromRename_2_bits_psrc_1 : (ohSel[12][3] ? io_fromRename_3_bits_psrc_1 : (ohSel[12][4] ? io_fromRename_4_bits_psrc_1 : io_fromRename_5_bits_psrc_1)))));
  assign io_toIssueQueues_12_bits_psrc_2 = (ohSel[12][0] ? io_fromRename_0_bits_psrc_2 : (ohSel[12][1] ? io_fromRename_1_bits_psrc_2 : (ohSel[12][2] ? io_fromRename_2_bits_psrc_2 : (ohSel[12][3] ? io_fromRename_3_bits_psrc_2 : (ohSel[12][4] ? io_fromRename_4_bits_psrc_2 : io_fromRename_5_bits_psrc_2)))));
  assign io_toIssueQueues_12_bits_pdest = (ohSel[12][0] ? io_fromRename_0_bits_pdest : (ohSel[12][1] ? io_fromRename_1_bits_pdest : (ohSel[12][2] ? io_fromRename_2_bits_pdest : (ohSel[12][3] ? io_fromRename_3_bits_pdest : (ohSel[12][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_12_bits_robIdx_flag = (ohSel[12][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[12][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[12][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[12][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[12][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_12_bits_robIdx_value = (ohSel[12][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[12][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[12][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[12][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[12][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  // -- 端口 13(IQ 6 enq 1)--
  assign io_toIssueQueues_13_valid = (ohSel[13][0] ? fromRenameUpdate_valid[0] : (ohSel[13][1] ? fromRenameUpdate_valid[1] : (ohSel[13][2] ? fromRenameUpdate_valid[2] : (ohSel[13][3] ? fromRenameUpdate_valid[3] : (ohSel[13][4] ? fromRenameUpdate_valid[4] : (ohSel[13][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_13_bits_srcType_0 = (ohSel[13][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[13][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[13][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[13][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[13][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_13_bits_srcType_1 = (ohSel[13][0] ? io_fromRename_0_bits_srcType_1 : (ohSel[13][1] ? io_fromRename_1_bits_srcType_1 : (ohSel[13][2] ? io_fromRename_2_bits_srcType_1 : (ohSel[13][3] ? io_fromRename_3_bits_srcType_1 : (ohSel[13][4] ? io_fromRename_4_bits_srcType_1 : io_fromRename_5_bits_srcType_1)))));
  assign io_toIssueQueues_13_bits_srcType_2 = (ohSel[13][0] ? fru_srcType2[0] : (ohSel[13][1] ? fru_srcType2[1] : (ohSel[13][2] ? fru_srcType2[2] : (ohSel[13][3] ? fru_srcType2[3] : (ohSel[13][4] ? fru_srcType2[4] : fru_srcType2[5])))));
  assign io_toIssueQueues_13_bits_fuType = (ohSel[13][0] ? io_fromRename_0_bits_fuType : (ohSel[13][1] ? io_fromRename_1_bits_fuType : (ohSel[13][2] ? io_fromRename_2_bits_fuType : (ohSel[13][3] ? io_fromRename_3_bits_fuType : (ohSel[13][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_13_bits_fuOpType = (ohSel[13][0] ? io_fromRename_0_bits_fuOpType : (ohSel[13][1] ? io_fromRename_1_bits_fuOpType : (ohSel[13][2] ? io_fromRename_2_bits_fuOpType : (ohSel[13][3] ? io_fromRename_3_bits_fuOpType : (ohSel[13][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_13_bits_rfWen = (ohSel[13][0] ? io_fromRename_0_bits_rfWen : (ohSel[13][1] ? io_fromRename_1_bits_rfWen : (ohSel[13][2] ? io_fromRename_2_bits_rfWen : (ohSel[13][3] ? io_fromRename_3_bits_rfWen : (ohSel[13][4] ? io_fromRename_4_bits_rfWen : io_fromRename_5_bits_rfWen)))));
  assign io_toIssueQueues_13_bits_fpWen = (ohSel[13][0] ? io_fromRename_0_bits_fpWen : (ohSel[13][1] ? io_fromRename_1_bits_fpWen : (ohSel[13][2] ? io_fromRename_2_bits_fpWen : (ohSel[13][3] ? io_fromRename_3_bits_fpWen : (ohSel[13][4] ? io_fromRename_4_bits_fpWen : io_fromRename_5_bits_fpWen)))));
  assign io_toIssueQueues_13_bits_fpu_wflags = (ohSel[13][0] ? io_fromRename_0_bits_fpu_wflags : (ohSel[13][1] ? io_fromRename_1_bits_fpu_wflags : (ohSel[13][2] ? io_fromRename_2_bits_fpu_wflags : (ohSel[13][3] ? io_fromRename_3_bits_fpu_wflags : (ohSel[13][4] ? io_fromRename_4_bits_fpu_wflags : io_fromRename_5_bits_fpu_wflags)))));
  assign io_toIssueQueues_13_bits_fpu_fmt = (ohSel[13][0] ? io_fromRename_0_bits_fpu_fmt : (ohSel[13][1] ? io_fromRename_1_bits_fpu_fmt : (ohSel[13][2] ? io_fromRename_2_bits_fpu_fmt : (ohSel[13][3] ? io_fromRename_3_bits_fpu_fmt : (ohSel[13][4] ? io_fromRename_4_bits_fpu_fmt : io_fromRename_5_bits_fpu_fmt)))));
  assign io_toIssueQueues_13_bits_fpu_rm = (ohSel[13][0] ? io_fromRename_0_bits_fpu_rm : (ohSel[13][1] ? io_fromRename_1_bits_fpu_rm : (ohSel[13][2] ? io_fromRename_2_bits_fpu_rm : (ohSel[13][3] ? io_fromRename_3_bits_fpu_rm : (ohSel[13][4] ? io_fromRename_4_bits_fpu_rm : io_fromRename_5_bits_fpu_rm)))));
  assign io_toIssueQueues_13_bits_srcState_0 = (ohSel[13][0] ? (allSrcState[0][0][1]) : (ohSel[13][1] ? (allSrcState[1][0][1]) : (ohSel[13][2] ? (allSrcState[2][0][1]) : (ohSel[13][3] ? (allSrcState[3][0][1]) : (ohSel[13][4] ? (allSrcState[4][0][1]) : (allSrcState[5][0][1]))))));
  assign io_toIssueQueues_13_bits_srcState_1 = (ohSel[13][0] ? (allSrcState[0][1][1]) : (ohSel[13][1] ? (allSrcState[1][1][1]) : (ohSel[13][2] ? (allSrcState[2][1][1]) : (ohSel[13][3] ? (allSrcState[3][1][1]) : (ohSel[13][4] ? (allSrcState[4][1][1]) : (allSrcState[5][1][1]))))));
  assign io_toIssueQueues_13_bits_srcState_2 = (ohSel[13][0] ? (allSrcState[0][2][1]) : (ohSel[13][1] ? (allSrcState[1][2][1]) : (ohSel[13][2] ? (allSrcState[2][2][1]) : (ohSel[13][3] ? (allSrcState[3][2][1]) : (ohSel[13][4] ? (allSrcState[4][2][1]) : (allSrcState[5][2][1]))))));
  assign io_toIssueQueues_13_bits_psrc_0 = (ohSel[13][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[13][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[13][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[13][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[13][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_13_bits_psrc_1 = (ohSel[13][0] ? io_fromRename_0_bits_psrc_1 : (ohSel[13][1] ? io_fromRename_1_bits_psrc_1 : (ohSel[13][2] ? io_fromRename_2_bits_psrc_1 : (ohSel[13][3] ? io_fromRename_3_bits_psrc_1 : (ohSel[13][4] ? io_fromRename_4_bits_psrc_1 : io_fromRename_5_bits_psrc_1)))));
  assign io_toIssueQueues_13_bits_psrc_2 = (ohSel[13][0] ? io_fromRename_0_bits_psrc_2 : (ohSel[13][1] ? io_fromRename_1_bits_psrc_2 : (ohSel[13][2] ? io_fromRename_2_bits_psrc_2 : (ohSel[13][3] ? io_fromRename_3_bits_psrc_2 : (ohSel[13][4] ? io_fromRename_4_bits_psrc_2 : io_fromRename_5_bits_psrc_2)))));
  assign io_toIssueQueues_13_bits_pdest = (ohSel[13][0] ? io_fromRename_0_bits_pdest : (ohSel[13][1] ? io_fromRename_1_bits_pdest : (ohSel[13][2] ? io_fromRename_2_bits_pdest : (ohSel[13][3] ? io_fromRename_3_bits_pdest : (ohSel[13][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_13_bits_robIdx_flag = (ohSel[13][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[13][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[13][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[13][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[13][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_13_bits_robIdx_value = (ohSel[13][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[13][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[13][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[13][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[13][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  // -- 端口 14(IQ 7 enq 0)--
  assign io_toIssueQueues_14_valid = (ohSel[14][0] ? fromRenameUpdate_valid[0] : (ohSel[14][1] ? fromRenameUpdate_valid[1] : (ohSel[14][2] ? fromRenameUpdate_valid[2] : (ohSel[14][3] ? fromRenameUpdate_valid[3] : (ohSel[14][4] ? fromRenameUpdate_valid[4] : (ohSel[14][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_14_bits_srcType_0 = (ohSel[14][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[14][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[14][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[14][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[14][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_14_bits_srcType_1 = (ohSel[14][0] ? io_fromRename_0_bits_srcType_1 : (ohSel[14][1] ? io_fromRename_1_bits_srcType_1 : (ohSel[14][2] ? io_fromRename_2_bits_srcType_1 : (ohSel[14][3] ? io_fromRename_3_bits_srcType_1 : (ohSel[14][4] ? io_fromRename_4_bits_srcType_1 : io_fromRename_5_bits_srcType_1)))));
  assign io_toIssueQueues_14_bits_srcType_2 = (ohSel[14][0] ? fru_srcType2[0] : (ohSel[14][1] ? fru_srcType2[1] : (ohSel[14][2] ? fru_srcType2[2] : (ohSel[14][3] ? fru_srcType2[3] : (ohSel[14][4] ? fru_srcType2[4] : fru_srcType2[5])))));
  assign io_toIssueQueues_14_bits_srcType_3 = (ohSel[14][0] ? io_fromRename_0_bits_srcType_3 : (ohSel[14][1] ? io_fromRename_1_bits_srcType_3 : (ohSel[14][2] ? io_fromRename_2_bits_srcType_3 : (ohSel[14][3] ? io_fromRename_3_bits_srcType_3 : (ohSel[14][4] ? io_fromRename_4_bits_srcType_3 : io_fromRename_5_bits_srcType_3)))));
  assign io_toIssueQueues_14_bits_srcType_4 = (ohSel[14][0] ? io_fromRename_0_bits_srcType_4 : (ohSel[14][1] ? io_fromRename_1_bits_srcType_4 : (ohSel[14][2] ? io_fromRename_2_bits_srcType_4 : (ohSel[14][3] ? io_fromRename_3_bits_srcType_4 : (ohSel[14][4] ? io_fromRename_4_bits_srcType_4 : io_fromRename_5_bits_srcType_4)))));
  assign io_toIssueQueues_14_bits_fuType = (ohSel[14][0] ? io_fromRename_0_bits_fuType : (ohSel[14][1] ? io_fromRename_1_bits_fuType : (ohSel[14][2] ? io_fromRename_2_bits_fuType : (ohSel[14][3] ? io_fromRename_3_bits_fuType : (ohSel[14][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_14_bits_fuOpType = (ohSel[14][0] ? io_fromRename_0_bits_fuOpType : (ohSel[14][1] ? io_fromRename_1_bits_fuOpType : (ohSel[14][2] ? io_fromRename_2_bits_fuOpType : (ohSel[14][3] ? io_fromRename_3_bits_fuOpType : (ohSel[14][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_14_bits_rfWen = (ohSel[14][0] ? io_fromRename_0_bits_rfWen : (ohSel[14][1] ? io_fromRename_1_bits_rfWen : (ohSel[14][2] ? io_fromRename_2_bits_rfWen : (ohSel[14][3] ? io_fromRename_3_bits_rfWen : (ohSel[14][4] ? io_fromRename_4_bits_rfWen : io_fromRename_5_bits_rfWen)))));
  assign io_toIssueQueues_14_bits_fpWen = (ohSel[14][0] ? io_fromRename_0_bits_fpWen : (ohSel[14][1] ? io_fromRename_1_bits_fpWen : (ohSel[14][2] ? io_fromRename_2_bits_fpWen : (ohSel[14][3] ? io_fromRename_3_bits_fpWen : (ohSel[14][4] ? io_fromRename_4_bits_fpWen : io_fromRename_5_bits_fpWen)))));
  assign io_toIssueQueues_14_bits_vecWen = (ohSel[14][0] ? io_fromRename_0_bits_vecWen : (ohSel[14][1] ? io_fromRename_1_bits_vecWen : (ohSel[14][2] ? io_fromRename_2_bits_vecWen : (ohSel[14][3] ? io_fromRename_3_bits_vecWen : (ohSel[14][4] ? io_fromRename_4_bits_vecWen : io_fromRename_5_bits_vecWen)))));
  assign io_toIssueQueues_14_bits_v0Wen = (ohSel[14][0] ? io_fromRename_0_bits_v0Wen : (ohSel[14][1] ? io_fromRename_1_bits_v0Wen : (ohSel[14][2] ? io_fromRename_2_bits_v0Wen : (ohSel[14][3] ? io_fromRename_3_bits_v0Wen : (ohSel[14][4] ? io_fromRename_4_bits_v0Wen : io_fromRename_5_bits_v0Wen)))));
  assign io_toIssueQueues_14_bits_vlWen = (ohSel[14][0] ? io_fromRename_0_bits_vlWen : (ohSel[14][1] ? io_fromRename_1_bits_vlWen : (ohSel[14][2] ? io_fromRename_2_bits_vlWen : (ohSel[14][3] ? io_fromRename_3_bits_vlWen : (ohSel[14][4] ? io_fromRename_4_bits_vlWen : io_fromRename_5_bits_vlWen)))));
  assign io_toIssueQueues_14_bits_selImm = (ohSel[14][0] ? io_fromRename_0_bits_selImm : (ohSel[14][1] ? io_fromRename_1_bits_selImm : (ohSel[14][2] ? io_fromRename_2_bits_selImm : (ohSel[14][3] ? io_fromRename_3_bits_selImm : (ohSel[14][4] ? io_fromRename_4_bits_selImm : io_fromRename_5_bits_selImm)))));
  assign io_toIssueQueues_14_bits_imm = (ohSel[14][0] ? io_fromRename_0_bits_imm : (ohSel[14][1] ? io_fromRename_1_bits_imm : (ohSel[14][2] ? io_fromRename_2_bits_imm : (ohSel[14][3] ? io_fromRename_3_bits_imm : (ohSel[14][4] ? io_fromRename_4_bits_imm : io_fromRename_5_bits_imm)))));
  assign io_toIssueQueues_14_bits_fpu_wflags = (ohSel[14][0] ? io_fromRename_0_bits_fpu_wflags : (ohSel[14][1] ? io_fromRename_1_bits_fpu_wflags : (ohSel[14][2] ? io_fromRename_2_bits_fpu_wflags : (ohSel[14][3] ? io_fromRename_3_bits_fpu_wflags : (ohSel[14][4] ? io_fromRename_4_bits_fpu_wflags : io_fromRename_5_bits_fpu_wflags)))));
  assign io_toIssueQueues_14_bits_vpu_vma = (ohSel[14][0] ? io_fromRename_0_bits_vpu_vma : (ohSel[14][1] ? io_fromRename_1_bits_vpu_vma : (ohSel[14][2] ? io_fromRename_2_bits_vpu_vma : (ohSel[14][3] ? io_fromRename_3_bits_vpu_vma : (ohSel[14][4] ? io_fromRename_4_bits_vpu_vma : io_fromRename_5_bits_vpu_vma)))));
  assign io_toIssueQueues_14_bits_vpu_vta = (ohSel[14][0] ? io_fromRename_0_bits_vpu_vta : (ohSel[14][1] ? io_fromRename_1_bits_vpu_vta : (ohSel[14][2] ? io_fromRename_2_bits_vpu_vta : (ohSel[14][3] ? io_fromRename_3_bits_vpu_vta : (ohSel[14][4] ? io_fromRename_4_bits_vpu_vta : io_fromRename_5_bits_vpu_vta)))));
  assign io_toIssueQueues_14_bits_vpu_vsew = (ohSel[14][0] ? io_fromRename_0_bits_vpu_vsew : (ohSel[14][1] ? io_fromRename_1_bits_vpu_vsew : (ohSel[14][2] ? io_fromRename_2_bits_vpu_vsew : (ohSel[14][3] ? io_fromRename_3_bits_vpu_vsew : (ohSel[14][4] ? io_fromRename_4_bits_vpu_vsew : io_fromRename_5_bits_vpu_vsew)))));
  assign io_toIssueQueues_14_bits_vpu_vlmul = (ohSel[14][0] ? io_fromRename_0_bits_vpu_vlmul : (ohSel[14][1] ? io_fromRename_1_bits_vpu_vlmul : (ohSel[14][2] ? io_fromRename_2_bits_vpu_vlmul : (ohSel[14][3] ? io_fromRename_3_bits_vpu_vlmul : (ohSel[14][4] ? io_fromRename_4_bits_vpu_vlmul : io_fromRename_5_bits_vpu_vlmul)))));
  assign io_toIssueQueues_14_bits_vpu_vm = (ohSel[14][0] ? io_fromRename_0_bits_vpu_vm : (ohSel[14][1] ? io_fromRename_1_bits_vpu_vm : (ohSel[14][2] ? io_fromRename_2_bits_vpu_vm : (ohSel[14][3] ? io_fromRename_3_bits_vpu_vm : (ohSel[14][4] ? io_fromRename_4_bits_vpu_vm : io_fromRename_5_bits_vpu_vm)))));
  assign io_toIssueQueues_14_bits_vpu_vstart = (ohSel[14][0] ? io_fromRename_0_bits_vpu_vstart : (ohSel[14][1] ? io_fromRename_1_bits_vpu_vstart : (ohSel[14][2] ? io_fromRename_2_bits_vpu_vstart : (ohSel[14][3] ? io_fromRename_3_bits_vpu_vstart : (ohSel[14][4] ? io_fromRename_4_bits_vpu_vstart : io_fromRename_5_bits_vpu_vstart)))));
  assign io_toIssueQueues_14_bits_vpu_fpu_isFoldTo1_2 = (ohSel[14][0] ? io_fromRename_0_bits_vpu_fpu_isFoldTo1_2 : (ohSel[14][1] ? io_fromRename_1_bits_vpu_fpu_isFoldTo1_2 : (ohSel[14][2] ? io_fromRename_2_bits_vpu_fpu_isFoldTo1_2 : (ohSel[14][3] ? io_fromRename_3_bits_vpu_fpu_isFoldTo1_2 : (ohSel[14][4] ? io_fromRename_4_bits_vpu_fpu_isFoldTo1_2 : io_fromRename_5_bits_vpu_fpu_isFoldTo1_2)))));
  assign io_toIssueQueues_14_bits_vpu_fpu_isFoldTo1_4 = (ohSel[14][0] ? io_fromRename_0_bits_vpu_fpu_isFoldTo1_4 : (ohSel[14][1] ? io_fromRename_1_bits_vpu_fpu_isFoldTo1_4 : (ohSel[14][2] ? io_fromRename_2_bits_vpu_fpu_isFoldTo1_4 : (ohSel[14][3] ? io_fromRename_3_bits_vpu_fpu_isFoldTo1_4 : (ohSel[14][4] ? io_fromRename_4_bits_vpu_fpu_isFoldTo1_4 : io_fromRename_5_bits_vpu_fpu_isFoldTo1_4)))));
  assign io_toIssueQueues_14_bits_vpu_fpu_isFoldTo1_8 = (ohSel[14][0] ? io_fromRename_0_bits_vpu_fpu_isFoldTo1_8 : (ohSel[14][1] ? io_fromRename_1_bits_vpu_fpu_isFoldTo1_8 : (ohSel[14][2] ? io_fromRename_2_bits_vpu_fpu_isFoldTo1_8 : (ohSel[14][3] ? io_fromRename_3_bits_vpu_fpu_isFoldTo1_8 : (ohSel[14][4] ? io_fromRename_4_bits_vpu_fpu_isFoldTo1_8 : io_fromRename_5_bits_vpu_fpu_isFoldTo1_8)))));
  assign io_toIssueQueues_14_bits_vpu_isExt = (ohSel[14][0] ? io_fromRename_0_bits_vpu_isExt : (ohSel[14][1] ? io_fromRename_1_bits_vpu_isExt : (ohSel[14][2] ? io_fromRename_2_bits_vpu_isExt : (ohSel[14][3] ? io_fromRename_3_bits_vpu_isExt : (ohSel[14][4] ? io_fromRename_4_bits_vpu_isExt : io_fromRename_5_bits_vpu_isExt)))));
  assign io_toIssueQueues_14_bits_vpu_isNarrow = (ohSel[14][0] ? io_fromRename_0_bits_vpu_isNarrow : (ohSel[14][1] ? io_fromRename_1_bits_vpu_isNarrow : (ohSel[14][2] ? io_fromRename_2_bits_vpu_isNarrow : (ohSel[14][3] ? io_fromRename_3_bits_vpu_isNarrow : (ohSel[14][4] ? io_fromRename_4_bits_vpu_isNarrow : io_fromRename_5_bits_vpu_isNarrow)))));
  assign io_toIssueQueues_14_bits_vpu_isDstMask = (ohSel[14][0] ? io_fromRename_0_bits_vpu_isDstMask : (ohSel[14][1] ? io_fromRename_1_bits_vpu_isDstMask : (ohSel[14][2] ? io_fromRename_2_bits_vpu_isDstMask : (ohSel[14][3] ? io_fromRename_3_bits_vpu_isDstMask : (ohSel[14][4] ? io_fromRename_4_bits_vpu_isDstMask : io_fromRename_5_bits_vpu_isDstMask)))));
  assign io_toIssueQueues_14_bits_vpu_isOpMask = (ohSel[14][0] ? io_fromRename_0_bits_vpu_isOpMask : (ohSel[14][1] ? io_fromRename_1_bits_vpu_isOpMask : (ohSel[14][2] ? io_fromRename_2_bits_vpu_isOpMask : (ohSel[14][3] ? io_fromRename_3_bits_vpu_isOpMask : (ohSel[14][4] ? io_fromRename_4_bits_vpu_isOpMask : io_fromRename_5_bits_vpu_isOpMask)))));
  assign io_toIssueQueues_14_bits_vpu_isDependOldVd = (ohSel[14][0] ? io_fromRename_0_bits_vpu_isDependOldVd : (ohSel[14][1] ? io_fromRename_1_bits_vpu_isDependOldVd : (ohSel[14][2] ? io_fromRename_2_bits_vpu_isDependOldVd : (ohSel[14][3] ? io_fromRename_3_bits_vpu_isDependOldVd : (ohSel[14][4] ? io_fromRename_4_bits_vpu_isDependOldVd : io_fromRename_5_bits_vpu_isDependOldVd)))));
  assign io_toIssueQueues_14_bits_vpu_isWritePartVd = (ohSel[14][0] ? io_fromRename_0_bits_vpu_isWritePartVd : (ohSel[14][1] ? io_fromRename_1_bits_vpu_isWritePartVd : (ohSel[14][2] ? io_fromRename_2_bits_vpu_isWritePartVd : (ohSel[14][3] ? io_fromRename_3_bits_vpu_isWritePartVd : (ohSel[14][4] ? io_fromRename_4_bits_vpu_isWritePartVd : io_fromRename_5_bits_vpu_isWritePartVd)))));
  assign io_toIssueQueues_14_bits_uopIdx = (ohSel[14][0] ? io_fromRename_0_bits_uopIdx : (ohSel[14][1] ? io_fromRename_1_bits_uopIdx : (ohSel[14][2] ? io_fromRename_2_bits_uopIdx : (ohSel[14][3] ? io_fromRename_3_bits_uopIdx : (ohSel[14][4] ? io_fromRename_4_bits_uopIdx : io_fromRename_5_bits_uopIdx)))));
  assign io_toIssueQueues_14_bits_lastUop = (ohSel[14][0] ? io_fromRename_0_bits_lastUop : (ohSel[14][1] ? io_fromRename_1_bits_lastUop : (ohSel[14][2] ? io_fromRename_2_bits_lastUop : (ohSel[14][3] ? io_fromRename_3_bits_lastUop : (ohSel[14][4] ? io_fromRename_4_bits_lastUop : io_fromRename_5_bits_lastUop)))));
  assign io_toIssueQueues_14_bits_srcState_0 = (ohSel[14][0] ? (allSrcState[0][0][2]) : (ohSel[14][1] ? (allSrcState[1][0][2]) : (ohSel[14][2] ? (allSrcState[2][0][2]) : (ohSel[14][3] ? (allSrcState[3][0][2]) : (ohSel[14][4] ? (allSrcState[4][0][2]) : (allSrcState[5][0][2]))))));
  assign io_toIssueQueues_14_bits_srcState_1 = (ohSel[14][0] ? (allSrcState[0][1][2]) : (ohSel[14][1] ? (allSrcState[1][1][2]) : (ohSel[14][2] ? (allSrcState[2][1][2]) : (ohSel[14][3] ? (allSrcState[3][1][2]) : (ohSel[14][4] ? (allSrcState[4][1][2]) : (allSrcState[5][1][2]))))));
  assign io_toIssueQueues_14_bits_srcState_2 = (ohSel[14][0] ? (allSrcState[0][2][2]) : (ohSel[14][1] ? (allSrcState[1][2][2]) : (ohSel[14][2] ? (allSrcState[2][2][2]) : (ohSel[14][3] ? (allSrcState[3][2][2]) : (ohSel[14][4] ? (allSrcState[4][2][2]) : (allSrcState[5][2][2]))))));
  assign io_toIssueQueues_14_bits_srcState_3 = (ohSel[14][0] ? (allSrcState[0][3][3]) : (ohSel[14][1] ? (allSrcState[1][3][3]) : (ohSel[14][2] ? (allSrcState[2][3][3]) : (ohSel[14][3] ? (allSrcState[3][3][3]) : (ohSel[14][4] ? (allSrcState[4][3][3]) : (allSrcState[5][3][3]))))));
  assign io_toIssueQueues_14_bits_srcState_4 = (ohSel[14][0] ? (allSrcState[0][4][4]) : (ohSel[14][1] ? (allSrcState[1][4][4]) : (ohSel[14][2] ? (allSrcState[2][4][4]) : (ohSel[14][3] ? (allSrcState[3][4][4]) : (ohSel[14][4] ? (allSrcState[4][4][4]) : (allSrcState[5][4][4]))))));
  assign io_toIssueQueues_14_bits_psrc_0 = (ohSel[14][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[14][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[14][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[14][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[14][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_14_bits_psrc_1 = (ohSel[14][0] ? io_fromRename_0_bits_psrc_1 : (ohSel[14][1] ? io_fromRename_1_bits_psrc_1 : (ohSel[14][2] ? io_fromRename_2_bits_psrc_1 : (ohSel[14][3] ? io_fromRename_3_bits_psrc_1 : (ohSel[14][4] ? io_fromRename_4_bits_psrc_1 : io_fromRename_5_bits_psrc_1)))));
  assign io_toIssueQueues_14_bits_psrc_2 = (ohSel[14][0] ? io_fromRename_0_bits_psrc_2 : (ohSel[14][1] ? io_fromRename_1_bits_psrc_2 : (ohSel[14][2] ? io_fromRename_2_bits_psrc_2 : (ohSel[14][3] ? io_fromRename_3_bits_psrc_2 : (ohSel[14][4] ? io_fromRename_4_bits_psrc_2 : io_fromRename_5_bits_psrc_2)))));
  assign io_toIssueQueues_14_bits_psrc_3 = (ohSel[14][0] ? io_fromRename_0_bits_psrc_3 : (ohSel[14][1] ? io_fromRename_1_bits_psrc_3 : (ohSel[14][2] ? io_fromRename_2_bits_psrc_3 : (ohSel[14][3] ? io_fromRename_3_bits_psrc_3 : (ohSel[14][4] ? io_fromRename_4_bits_psrc_3 : io_fromRename_5_bits_psrc_3)))));
  assign io_toIssueQueues_14_bits_psrc_4 = (ohSel[14][0] ? io_fromRename_0_bits_psrc_4 : (ohSel[14][1] ? io_fromRename_1_bits_psrc_4 : (ohSel[14][2] ? io_fromRename_2_bits_psrc_4 : (ohSel[14][3] ? io_fromRename_3_bits_psrc_4 : (ohSel[14][4] ? io_fromRename_4_bits_psrc_4 : io_fromRename_5_bits_psrc_4)))));
  assign io_toIssueQueues_14_bits_pdest = (ohSel[14][0] ? io_fromRename_0_bits_pdest : (ohSel[14][1] ? io_fromRename_1_bits_pdest : (ohSel[14][2] ? io_fromRename_2_bits_pdest : (ohSel[14][3] ? io_fromRename_3_bits_pdest : (ohSel[14][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_14_bits_robIdx_flag = (ohSel[14][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[14][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[14][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[14][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[14][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_14_bits_robIdx_value = (ohSel[14][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[14][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[14][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[14][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[14][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  // -- 端口 15(IQ 7 enq 1)--
  assign io_toIssueQueues_15_valid = (ohSel[15][0] ? fromRenameUpdate_valid[0] : (ohSel[15][1] ? fromRenameUpdate_valid[1] : (ohSel[15][2] ? fromRenameUpdate_valid[2] : (ohSel[15][3] ? fromRenameUpdate_valid[3] : (ohSel[15][4] ? fromRenameUpdate_valid[4] : (ohSel[15][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_15_bits_srcType_0 = (ohSel[15][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[15][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[15][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[15][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[15][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_15_bits_srcType_1 = (ohSel[15][0] ? io_fromRename_0_bits_srcType_1 : (ohSel[15][1] ? io_fromRename_1_bits_srcType_1 : (ohSel[15][2] ? io_fromRename_2_bits_srcType_1 : (ohSel[15][3] ? io_fromRename_3_bits_srcType_1 : (ohSel[15][4] ? io_fromRename_4_bits_srcType_1 : io_fromRename_5_bits_srcType_1)))));
  assign io_toIssueQueues_15_bits_srcType_2 = (ohSel[15][0] ? fru_srcType2[0] : (ohSel[15][1] ? fru_srcType2[1] : (ohSel[15][2] ? fru_srcType2[2] : (ohSel[15][3] ? fru_srcType2[3] : (ohSel[15][4] ? fru_srcType2[4] : fru_srcType2[5])))));
  assign io_toIssueQueues_15_bits_srcType_3 = (ohSel[15][0] ? io_fromRename_0_bits_srcType_3 : (ohSel[15][1] ? io_fromRename_1_bits_srcType_3 : (ohSel[15][2] ? io_fromRename_2_bits_srcType_3 : (ohSel[15][3] ? io_fromRename_3_bits_srcType_3 : (ohSel[15][4] ? io_fromRename_4_bits_srcType_3 : io_fromRename_5_bits_srcType_3)))));
  assign io_toIssueQueues_15_bits_srcType_4 = (ohSel[15][0] ? io_fromRename_0_bits_srcType_4 : (ohSel[15][1] ? io_fromRename_1_bits_srcType_4 : (ohSel[15][2] ? io_fromRename_2_bits_srcType_4 : (ohSel[15][3] ? io_fromRename_3_bits_srcType_4 : (ohSel[15][4] ? io_fromRename_4_bits_srcType_4 : io_fromRename_5_bits_srcType_4)))));
  assign io_toIssueQueues_15_bits_fuType = (ohSel[15][0] ? io_fromRename_0_bits_fuType : (ohSel[15][1] ? io_fromRename_1_bits_fuType : (ohSel[15][2] ? io_fromRename_2_bits_fuType : (ohSel[15][3] ? io_fromRename_3_bits_fuType : (ohSel[15][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_15_bits_fuOpType = (ohSel[15][0] ? io_fromRename_0_bits_fuOpType : (ohSel[15][1] ? io_fromRename_1_bits_fuOpType : (ohSel[15][2] ? io_fromRename_2_bits_fuOpType : (ohSel[15][3] ? io_fromRename_3_bits_fuOpType : (ohSel[15][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_15_bits_rfWen = (ohSel[15][0] ? io_fromRename_0_bits_rfWen : (ohSel[15][1] ? io_fromRename_1_bits_rfWen : (ohSel[15][2] ? io_fromRename_2_bits_rfWen : (ohSel[15][3] ? io_fromRename_3_bits_rfWen : (ohSel[15][4] ? io_fromRename_4_bits_rfWen : io_fromRename_5_bits_rfWen)))));
  assign io_toIssueQueues_15_bits_fpWen = (ohSel[15][0] ? io_fromRename_0_bits_fpWen : (ohSel[15][1] ? io_fromRename_1_bits_fpWen : (ohSel[15][2] ? io_fromRename_2_bits_fpWen : (ohSel[15][3] ? io_fromRename_3_bits_fpWen : (ohSel[15][4] ? io_fromRename_4_bits_fpWen : io_fromRename_5_bits_fpWen)))));
  assign io_toIssueQueues_15_bits_vecWen = (ohSel[15][0] ? io_fromRename_0_bits_vecWen : (ohSel[15][1] ? io_fromRename_1_bits_vecWen : (ohSel[15][2] ? io_fromRename_2_bits_vecWen : (ohSel[15][3] ? io_fromRename_3_bits_vecWen : (ohSel[15][4] ? io_fromRename_4_bits_vecWen : io_fromRename_5_bits_vecWen)))));
  assign io_toIssueQueues_15_bits_v0Wen = (ohSel[15][0] ? io_fromRename_0_bits_v0Wen : (ohSel[15][1] ? io_fromRename_1_bits_v0Wen : (ohSel[15][2] ? io_fromRename_2_bits_v0Wen : (ohSel[15][3] ? io_fromRename_3_bits_v0Wen : (ohSel[15][4] ? io_fromRename_4_bits_v0Wen : io_fromRename_5_bits_v0Wen)))));
  assign io_toIssueQueues_15_bits_vlWen = (ohSel[15][0] ? io_fromRename_0_bits_vlWen : (ohSel[15][1] ? io_fromRename_1_bits_vlWen : (ohSel[15][2] ? io_fromRename_2_bits_vlWen : (ohSel[15][3] ? io_fromRename_3_bits_vlWen : (ohSel[15][4] ? io_fromRename_4_bits_vlWen : io_fromRename_5_bits_vlWen)))));
  assign io_toIssueQueues_15_bits_selImm = (ohSel[15][0] ? io_fromRename_0_bits_selImm : (ohSel[15][1] ? io_fromRename_1_bits_selImm : (ohSel[15][2] ? io_fromRename_2_bits_selImm : (ohSel[15][3] ? io_fromRename_3_bits_selImm : (ohSel[15][4] ? io_fromRename_4_bits_selImm : io_fromRename_5_bits_selImm)))));
  assign io_toIssueQueues_15_bits_imm = (ohSel[15][0] ? io_fromRename_0_bits_imm : (ohSel[15][1] ? io_fromRename_1_bits_imm : (ohSel[15][2] ? io_fromRename_2_bits_imm : (ohSel[15][3] ? io_fromRename_3_bits_imm : (ohSel[15][4] ? io_fromRename_4_bits_imm : io_fromRename_5_bits_imm)))));
  assign io_toIssueQueues_15_bits_fpu_wflags = (ohSel[15][0] ? io_fromRename_0_bits_fpu_wflags : (ohSel[15][1] ? io_fromRename_1_bits_fpu_wflags : (ohSel[15][2] ? io_fromRename_2_bits_fpu_wflags : (ohSel[15][3] ? io_fromRename_3_bits_fpu_wflags : (ohSel[15][4] ? io_fromRename_4_bits_fpu_wflags : io_fromRename_5_bits_fpu_wflags)))));
  assign io_toIssueQueues_15_bits_vpu_vma = (ohSel[15][0] ? io_fromRename_0_bits_vpu_vma : (ohSel[15][1] ? io_fromRename_1_bits_vpu_vma : (ohSel[15][2] ? io_fromRename_2_bits_vpu_vma : (ohSel[15][3] ? io_fromRename_3_bits_vpu_vma : (ohSel[15][4] ? io_fromRename_4_bits_vpu_vma : io_fromRename_5_bits_vpu_vma)))));
  assign io_toIssueQueues_15_bits_vpu_vta = (ohSel[15][0] ? io_fromRename_0_bits_vpu_vta : (ohSel[15][1] ? io_fromRename_1_bits_vpu_vta : (ohSel[15][2] ? io_fromRename_2_bits_vpu_vta : (ohSel[15][3] ? io_fromRename_3_bits_vpu_vta : (ohSel[15][4] ? io_fromRename_4_bits_vpu_vta : io_fromRename_5_bits_vpu_vta)))));
  assign io_toIssueQueues_15_bits_vpu_vsew = (ohSel[15][0] ? io_fromRename_0_bits_vpu_vsew : (ohSel[15][1] ? io_fromRename_1_bits_vpu_vsew : (ohSel[15][2] ? io_fromRename_2_bits_vpu_vsew : (ohSel[15][3] ? io_fromRename_3_bits_vpu_vsew : (ohSel[15][4] ? io_fromRename_4_bits_vpu_vsew : io_fromRename_5_bits_vpu_vsew)))));
  assign io_toIssueQueues_15_bits_vpu_vlmul = (ohSel[15][0] ? io_fromRename_0_bits_vpu_vlmul : (ohSel[15][1] ? io_fromRename_1_bits_vpu_vlmul : (ohSel[15][2] ? io_fromRename_2_bits_vpu_vlmul : (ohSel[15][3] ? io_fromRename_3_bits_vpu_vlmul : (ohSel[15][4] ? io_fromRename_4_bits_vpu_vlmul : io_fromRename_5_bits_vpu_vlmul)))));
  assign io_toIssueQueues_15_bits_vpu_vm = (ohSel[15][0] ? io_fromRename_0_bits_vpu_vm : (ohSel[15][1] ? io_fromRename_1_bits_vpu_vm : (ohSel[15][2] ? io_fromRename_2_bits_vpu_vm : (ohSel[15][3] ? io_fromRename_3_bits_vpu_vm : (ohSel[15][4] ? io_fromRename_4_bits_vpu_vm : io_fromRename_5_bits_vpu_vm)))));
  assign io_toIssueQueues_15_bits_vpu_vstart = (ohSel[15][0] ? io_fromRename_0_bits_vpu_vstart : (ohSel[15][1] ? io_fromRename_1_bits_vpu_vstart : (ohSel[15][2] ? io_fromRename_2_bits_vpu_vstart : (ohSel[15][3] ? io_fromRename_3_bits_vpu_vstart : (ohSel[15][4] ? io_fromRename_4_bits_vpu_vstart : io_fromRename_5_bits_vpu_vstart)))));
  assign io_toIssueQueues_15_bits_vpu_fpu_isFoldTo1_2 = (ohSel[15][0] ? io_fromRename_0_bits_vpu_fpu_isFoldTo1_2 : (ohSel[15][1] ? io_fromRename_1_bits_vpu_fpu_isFoldTo1_2 : (ohSel[15][2] ? io_fromRename_2_bits_vpu_fpu_isFoldTo1_2 : (ohSel[15][3] ? io_fromRename_3_bits_vpu_fpu_isFoldTo1_2 : (ohSel[15][4] ? io_fromRename_4_bits_vpu_fpu_isFoldTo1_2 : io_fromRename_5_bits_vpu_fpu_isFoldTo1_2)))));
  assign io_toIssueQueues_15_bits_vpu_fpu_isFoldTo1_4 = (ohSel[15][0] ? io_fromRename_0_bits_vpu_fpu_isFoldTo1_4 : (ohSel[15][1] ? io_fromRename_1_bits_vpu_fpu_isFoldTo1_4 : (ohSel[15][2] ? io_fromRename_2_bits_vpu_fpu_isFoldTo1_4 : (ohSel[15][3] ? io_fromRename_3_bits_vpu_fpu_isFoldTo1_4 : (ohSel[15][4] ? io_fromRename_4_bits_vpu_fpu_isFoldTo1_4 : io_fromRename_5_bits_vpu_fpu_isFoldTo1_4)))));
  assign io_toIssueQueues_15_bits_vpu_fpu_isFoldTo1_8 = (ohSel[15][0] ? io_fromRename_0_bits_vpu_fpu_isFoldTo1_8 : (ohSel[15][1] ? io_fromRename_1_bits_vpu_fpu_isFoldTo1_8 : (ohSel[15][2] ? io_fromRename_2_bits_vpu_fpu_isFoldTo1_8 : (ohSel[15][3] ? io_fromRename_3_bits_vpu_fpu_isFoldTo1_8 : (ohSel[15][4] ? io_fromRename_4_bits_vpu_fpu_isFoldTo1_8 : io_fromRename_5_bits_vpu_fpu_isFoldTo1_8)))));
  assign io_toIssueQueues_15_bits_vpu_isExt = (ohSel[15][0] ? io_fromRename_0_bits_vpu_isExt : (ohSel[15][1] ? io_fromRename_1_bits_vpu_isExt : (ohSel[15][2] ? io_fromRename_2_bits_vpu_isExt : (ohSel[15][3] ? io_fromRename_3_bits_vpu_isExt : (ohSel[15][4] ? io_fromRename_4_bits_vpu_isExt : io_fromRename_5_bits_vpu_isExt)))));
  assign io_toIssueQueues_15_bits_vpu_isNarrow = (ohSel[15][0] ? io_fromRename_0_bits_vpu_isNarrow : (ohSel[15][1] ? io_fromRename_1_bits_vpu_isNarrow : (ohSel[15][2] ? io_fromRename_2_bits_vpu_isNarrow : (ohSel[15][3] ? io_fromRename_3_bits_vpu_isNarrow : (ohSel[15][4] ? io_fromRename_4_bits_vpu_isNarrow : io_fromRename_5_bits_vpu_isNarrow)))));
  assign io_toIssueQueues_15_bits_vpu_isDstMask = (ohSel[15][0] ? io_fromRename_0_bits_vpu_isDstMask : (ohSel[15][1] ? io_fromRename_1_bits_vpu_isDstMask : (ohSel[15][2] ? io_fromRename_2_bits_vpu_isDstMask : (ohSel[15][3] ? io_fromRename_3_bits_vpu_isDstMask : (ohSel[15][4] ? io_fromRename_4_bits_vpu_isDstMask : io_fromRename_5_bits_vpu_isDstMask)))));
  assign io_toIssueQueues_15_bits_vpu_isOpMask = (ohSel[15][0] ? io_fromRename_0_bits_vpu_isOpMask : (ohSel[15][1] ? io_fromRename_1_bits_vpu_isOpMask : (ohSel[15][2] ? io_fromRename_2_bits_vpu_isOpMask : (ohSel[15][3] ? io_fromRename_3_bits_vpu_isOpMask : (ohSel[15][4] ? io_fromRename_4_bits_vpu_isOpMask : io_fromRename_5_bits_vpu_isOpMask)))));
  assign io_toIssueQueues_15_bits_vpu_isDependOldVd = (ohSel[15][0] ? io_fromRename_0_bits_vpu_isDependOldVd : (ohSel[15][1] ? io_fromRename_1_bits_vpu_isDependOldVd : (ohSel[15][2] ? io_fromRename_2_bits_vpu_isDependOldVd : (ohSel[15][3] ? io_fromRename_3_bits_vpu_isDependOldVd : (ohSel[15][4] ? io_fromRename_4_bits_vpu_isDependOldVd : io_fromRename_5_bits_vpu_isDependOldVd)))));
  assign io_toIssueQueues_15_bits_vpu_isWritePartVd = (ohSel[15][0] ? io_fromRename_0_bits_vpu_isWritePartVd : (ohSel[15][1] ? io_fromRename_1_bits_vpu_isWritePartVd : (ohSel[15][2] ? io_fromRename_2_bits_vpu_isWritePartVd : (ohSel[15][3] ? io_fromRename_3_bits_vpu_isWritePartVd : (ohSel[15][4] ? io_fromRename_4_bits_vpu_isWritePartVd : io_fromRename_5_bits_vpu_isWritePartVd)))));
  assign io_toIssueQueues_15_bits_uopIdx = (ohSel[15][0] ? io_fromRename_0_bits_uopIdx : (ohSel[15][1] ? io_fromRename_1_bits_uopIdx : (ohSel[15][2] ? io_fromRename_2_bits_uopIdx : (ohSel[15][3] ? io_fromRename_3_bits_uopIdx : (ohSel[15][4] ? io_fromRename_4_bits_uopIdx : io_fromRename_5_bits_uopIdx)))));
  assign io_toIssueQueues_15_bits_lastUop = (ohSel[15][0] ? io_fromRename_0_bits_lastUop : (ohSel[15][1] ? io_fromRename_1_bits_lastUop : (ohSel[15][2] ? io_fromRename_2_bits_lastUop : (ohSel[15][3] ? io_fromRename_3_bits_lastUop : (ohSel[15][4] ? io_fromRename_4_bits_lastUop : io_fromRename_5_bits_lastUop)))));
  assign io_toIssueQueues_15_bits_srcState_0 = (ohSel[15][0] ? (allSrcState[0][0][2]) : (ohSel[15][1] ? (allSrcState[1][0][2]) : (ohSel[15][2] ? (allSrcState[2][0][2]) : (ohSel[15][3] ? (allSrcState[3][0][2]) : (ohSel[15][4] ? (allSrcState[4][0][2]) : (allSrcState[5][0][2]))))));
  assign io_toIssueQueues_15_bits_srcState_1 = (ohSel[15][0] ? (allSrcState[0][1][2]) : (ohSel[15][1] ? (allSrcState[1][1][2]) : (ohSel[15][2] ? (allSrcState[2][1][2]) : (ohSel[15][3] ? (allSrcState[3][1][2]) : (ohSel[15][4] ? (allSrcState[4][1][2]) : (allSrcState[5][1][2]))))));
  assign io_toIssueQueues_15_bits_srcState_2 = (ohSel[15][0] ? (allSrcState[0][2][2]) : (ohSel[15][1] ? (allSrcState[1][2][2]) : (ohSel[15][2] ? (allSrcState[2][2][2]) : (ohSel[15][3] ? (allSrcState[3][2][2]) : (ohSel[15][4] ? (allSrcState[4][2][2]) : (allSrcState[5][2][2]))))));
  assign io_toIssueQueues_15_bits_srcState_3 = (ohSel[15][0] ? (allSrcState[0][3][3]) : (ohSel[15][1] ? (allSrcState[1][3][3]) : (ohSel[15][2] ? (allSrcState[2][3][3]) : (ohSel[15][3] ? (allSrcState[3][3][3]) : (ohSel[15][4] ? (allSrcState[4][3][3]) : (allSrcState[5][3][3]))))));
  assign io_toIssueQueues_15_bits_srcState_4 = (ohSel[15][0] ? (allSrcState[0][4][4]) : (ohSel[15][1] ? (allSrcState[1][4][4]) : (ohSel[15][2] ? (allSrcState[2][4][4]) : (ohSel[15][3] ? (allSrcState[3][4][4]) : (ohSel[15][4] ? (allSrcState[4][4][4]) : (allSrcState[5][4][4]))))));
  assign io_toIssueQueues_15_bits_psrc_0 = (ohSel[15][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[15][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[15][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[15][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[15][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_15_bits_psrc_1 = (ohSel[15][0] ? io_fromRename_0_bits_psrc_1 : (ohSel[15][1] ? io_fromRename_1_bits_psrc_1 : (ohSel[15][2] ? io_fromRename_2_bits_psrc_1 : (ohSel[15][3] ? io_fromRename_3_bits_psrc_1 : (ohSel[15][4] ? io_fromRename_4_bits_psrc_1 : io_fromRename_5_bits_psrc_1)))));
  assign io_toIssueQueues_15_bits_psrc_2 = (ohSel[15][0] ? io_fromRename_0_bits_psrc_2 : (ohSel[15][1] ? io_fromRename_1_bits_psrc_2 : (ohSel[15][2] ? io_fromRename_2_bits_psrc_2 : (ohSel[15][3] ? io_fromRename_3_bits_psrc_2 : (ohSel[15][4] ? io_fromRename_4_bits_psrc_2 : io_fromRename_5_bits_psrc_2)))));
  assign io_toIssueQueues_15_bits_psrc_3 = (ohSel[15][0] ? io_fromRename_0_bits_psrc_3 : (ohSel[15][1] ? io_fromRename_1_bits_psrc_3 : (ohSel[15][2] ? io_fromRename_2_bits_psrc_3 : (ohSel[15][3] ? io_fromRename_3_bits_psrc_3 : (ohSel[15][4] ? io_fromRename_4_bits_psrc_3 : io_fromRename_5_bits_psrc_3)))));
  assign io_toIssueQueues_15_bits_psrc_4 = (ohSel[15][0] ? io_fromRename_0_bits_psrc_4 : (ohSel[15][1] ? io_fromRename_1_bits_psrc_4 : (ohSel[15][2] ? io_fromRename_2_bits_psrc_4 : (ohSel[15][3] ? io_fromRename_3_bits_psrc_4 : (ohSel[15][4] ? io_fromRename_4_bits_psrc_4 : io_fromRename_5_bits_psrc_4)))));
  assign io_toIssueQueues_15_bits_pdest = (ohSel[15][0] ? io_fromRename_0_bits_pdest : (ohSel[15][1] ? io_fromRename_1_bits_pdest : (ohSel[15][2] ? io_fromRename_2_bits_pdest : (ohSel[15][3] ? io_fromRename_3_bits_pdest : (ohSel[15][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_15_bits_robIdx_flag = (ohSel[15][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[15][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[15][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[15][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[15][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_15_bits_robIdx_value = (ohSel[15][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[15][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[15][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[15][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[15][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  // -- 端口 16(IQ 8 enq 0)--
  assign io_toIssueQueues_16_valid = (ohSel[16][0] ? fromRenameUpdate_valid[0] : (ohSel[16][1] ? fromRenameUpdate_valid[1] : (ohSel[16][2] ? fromRenameUpdate_valid[2] : (ohSel[16][3] ? fromRenameUpdate_valid[3] : (ohSel[16][4] ? fromRenameUpdate_valid[4] : (ohSel[16][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_16_bits_srcType_0 = (ohSel[16][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[16][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[16][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[16][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[16][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_16_bits_srcType_1 = (ohSel[16][0] ? io_fromRename_0_bits_srcType_1 : (ohSel[16][1] ? io_fromRename_1_bits_srcType_1 : (ohSel[16][2] ? io_fromRename_2_bits_srcType_1 : (ohSel[16][3] ? io_fromRename_3_bits_srcType_1 : (ohSel[16][4] ? io_fromRename_4_bits_srcType_1 : io_fromRename_5_bits_srcType_1)))));
  assign io_toIssueQueues_16_bits_srcType_2 = (ohSel[16][0] ? fru_srcType2[0] : (ohSel[16][1] ? fru_srcType2[1] : (ohSel[16][2] ? fru_srcType2[2] : (ohSel[16][3] ? fru_srcType2[3] : (ohSel[16][4] ? fru_srcType2[4] : fru_srcType2[5])))));
  assign io_toIssueQueues_16_bits_srcType_3 = (ohSel[16][0] ? io_fromRename_0_bits_srcType_3 : (ohSel[16][1] ? io_fromRename_1_bits_srcType_3 : (ohSel[16][2] ? io_fromRename_2_bits_srcType_3 : (ohSel[16][3] ? io_fromRename_3_bits_srcType_3 : (ohSel[16][4] ? io_fromRename_4_bits_srcType_3 : io_fromRename_5_bits_srcType_3)))));
  assign io_toIssueQueues_16_bits_srcType_4 = (ohSel[16][0] ? io_fromRename_0_bits_srcType_4 : (ohSel[16][1] ? io_fromRename_1_bits_srcType_4 : (ohSel[16][2] ? io_fromRename_2_bits_srcType_4 : (ohSel[16][3] ? io_fromRename_3_bits_srcType_4 : (ohSel[16][4] ? io_fromRename_4_bits_srcType_4 : io_fromRename_5_bits_srcType_4)))));
  assign io_toIssueQueues_16_bits_fuType = (ohSel[16][0] ? io_fromRename_0_bits_fuType : (ohSel[16][1] ? io_fromRename_1_bits_fuType : (ohSel[16][2] ? io_fromRename_2_bits_fuType : (ohSel[16][3] ? io_fromRename_3_bits_fuType : (ohSel[16][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_16_bits_fuOpType = (ohSel[16][0] ? io_fromRename_0_bits_fuOpType : (ohSel[16][1] ? io_fromRename_1_bits_fuOpType : (ohSel[16][2] ? io_fromRename_2_bits_fuOpType : (ohSel[16][3] ? io_fromRename_3_bits_fuOpType : (ohSel[16][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_16_bits_fpWen = (ohSel[16][0] ? io_fromRename_0_bits_fpWen : (ohSel[16][1] ? io_fromRename_1_bits_fpWen : (ohSel[16][2] ? io_fromRename_2_bits_fpWen : (ohSel[16][3] ? io_fromRename_3_bits_fpWen : (ohSel[16][4] ? io_fromRename_4_bits_fpWen : io_fromRename_5_bits_fpWen)))));
  assign io_toIssueQueues_16_bits_vecWen = (ohSel[16][0] ? io_fromRename_0_bits_vecWen : (ohSel[16][1] ? io_fromRename_1_bits_vecWen : (ohSel[16][2] ? io_fromRename_2_bits_vecWen : (ohSel[16][3] ? io_fromRename_3_bits_vecWen : (ohSel[16][4] ? io_fromRename_4_bits_vecWen : io_fromRename_5_bits_vecWen)))));
  assign io_toIssueQueues_16_bits_v0Wen = (ohSel[16][0] ? io_fromRename_0_bits_v0Wen : (ohSel[16][1] ? io_fromRename_1_bits_v0Wen : (ohSel[16][2] ? io_fromRename_2_bits_v0Wen : (ohSel[16][3] ? io_fromRename_3_bits_v0Wen : (ohSel[16][4] ? io_fromRename_4_bits_v0Wen : io_fromRename_5_bits_v0Wen)))));
  assign io_toIssueQueues_16_bits_fpu_wflags = (ohSel[16][0] ? io_fromRename_0_bits_fpu_wflags : (ohSel[16][1] ? io_fromRename_1_bits_fpu_wflags : (ohSel[16][2] ? io_fromRename_2_bits_fpu_wflags : (ohSel[16][3] ? io_fromRename_3_bits_fpu_wflags : (ohSel[16][4] ? io_fromRename_4_bits_fpu_wflags : io_fromRename_5_bits_fpu_wflags)))));
  assign io_toIssueQueues_16_bits_vpu_vma = (ohSel[16][0] ? io_fromRename_0_bits_vpu_vma : (ohSel[16][1] ? io_fromRename_1_bits_vpu_vma : (ohSel[16][2] ? io_fromRename_2_bits_vpu_vma : (ohSel[16][3] ? io_fromRename_3_bits_vpu_vma : (ohSel[16][4] ? io_fromRename_4_bits_vpu_vma : io_fromRename_5_bits_vpu_vma)))));
  assign io_toIssueQueues_16_bits_vpu_vta = (ohSel[16][0] ? io_fromRename_0_bits_vpu_vta : (ohSel[16][1] ? io_fromRename_1_bits_vpu_vta : (ohSel[16][2] ? io_fromRename_2_bits_vpu_vta : (ohSel[16][3] ? io_fromRename_3_bits_vpu_vta : (ohSel[16][4] ? io_fromRename_4_bits_vpu_vta : io_fromRename_5_bits_vpu_vta)))));
  assign io_toIssueQueues_16_bits_vpu_vsew = (ohSel[16][0] ? io_fromRename_0_bits_vpu_vsew : (ohSel[16][1] ? io_fromRename_1_bits_vpu_vsew : (ohSel[16][2] ? io_fromRename_2_bits_vpu_vsew : (ohSel[16][3] ? io_fromRename_3_bits_vpu_vsew : (ohSel[16][4] ? io_fromRename_4_bits_vpu_vsew : io_fromRename_5_bits_vpu_vsew)))));
  assign io_toIssueQueues_16_bits_vpu_vlmul = (ohSel[16][0] ? io_fromRename_0_bits_vpu_vlmul : (ohSel[16][1] ? io_fromRename_1_bits_vpu_vlmul : (ohSel[16][2] ? io_fromRename_2_bits_vpu_vlmul : (ohSel[16][3] ? io_fromRename_3_bits_vpu_vlmul : (ohSel[16][4] ? io_fromRename_4_bits_vpu_vlmul : io_fromRename_5_bits_vpu_vlmul)))));
  assign io_toIssueQueues_16_bits_vpu_vm = (ohSel[16][0] ? io_fromRename_0_bits_vpu_vm : (ohSel[16][1] ? io_fromRename_1_bits_vpu_vm : (ohSel[16][2] ? io_fromRename_2_bits_vpu_vm : (ohSel[16][3] ? io_fromRename_3_bits_vpu_vm : (ohSel[16][4] ? io_fromRename_4_bits_vpu_vm : io_fromRename_5_bits_vpu_vm)))));
  assign io_toIssueQueues_16_bits_vpu_vstart = (ohSel[16][0] ? io_fromRename_0_bits_vpu_vstart : (ohSel[16][1] ? io_fromRename_1_bits_vpu_vstart : (ohSel[16][2] ? io_fromRename_2_bits_vpu_vstart : (ohSel[16][3] ? io_fromRename_3_bits_vpu_vstart : (ohSel[16][4] ? io_fromRename_4_bits_vpu_vstart : io_fromRename_5_bits_vpu_vstart)))));
  assign io_toIssueQueues_16_bits_vpu_fpu_isFoldTo1_2 = (ohSel[16][0] ? io_fromRename_0_bits_vpu_fpu_isFoldTo1_2 : (ohSel[16][1] ? io_fromRename_1_bits_vpu_fpu_isFoldTo1_2 : (ohSel[16][2] ? io_fromRename_2_bits_vpu_fpu_isFoldTo1_2 : (ohSel[16][3] ? io_fromRename_3_bits_vpu_fpu_isFoldTo1_2 : (ohSel[16][4] ? io_fromRename_4_bits_vpu_fpu_isFoldTo1_2 : io_fromRename_5_bits_vpu_fpu_isFoldTo1_2)))));
  assign io_toIssueQueues_16_bits_vpu_fpu_isFoldTo1_4 = (ohSel[16][0] ? io_fromRename_0_bits_vpu_fpu_isFoldTo1_4 : (ohSel[16][1] ? io_fromRename_1_bits_vpu_fpu_isFoldTo1_4 : (ohSel[16][2] ? io_fromRename_2_bits_vpu_fpu_isFoldTo1_4 : (ohSel[16][3] ? io_fromRename_3_bits_vpu_fpu_isFoldTo1_4 : (ohSel[16][4] ? io_fromRename_4_bits_vpu_fpu_isFoldTo1_4 : io_fromRename_5_bits_vpu_fpu_isFoldTo1_4)))));
  assign io_toIssueQueues_16_bits_vpu_fpu_isFoldTo1_8 = (ohSel[16][0] ? io_fromRename_0_bits_vpu_fpu_isFoldTo1_8 : (ohSel[16][1] ? io_fromRename_1_bits_vpu_fpu_isFoldTo1_8 : (ohSel[16][2] ? io_fromRename_2_bits_vpu_fpu_isFoldTo1_8 : (ohSel[16][3] ? io_fromRename_3_bits_vpu_fpu_isFoldTo1_8 : (ohSel[16][4] ? io_fromRename_4_bits_vpu_fpu_isFoldTo1_8 : io_fromRename_5_bits_vpu_fpu_isFoldTo1_8)))));
  assign io_toIssueQueues_16_bits_vpu_isExt = (ohSel[16][0] ? io_fromRename_0_bits_vpu_isExt : (ohSel[16][1] ? io_fromRename_1_bits_vpu_isExt : (ohSel[16][2] ? io_fromRename_2_bits_vpu_isExt : (ohSel[16][3] ? io_fromRename_3_bits_vpu_isExt : (ohSel[16][4] ? io_fromRename_4_bits_vpu_isExt : io_fromRename_5_bits_vpu_isExt)))));
  assign io_toIssueQueues_16_bits_vpu_isNarrow = (ohSel[16][0] ? io_fromRename_0_bits_vpu_isNarrow : (ohSel[16][1] ? io_fromRename_1_bits_vpu_isNarrow : (ohSel[16][2] ? io_fromRename_2_bits_vpu_isNarrow : (ohSel[16][3] ? io_fromRename_3_bits_vpu_isNarrow : (ohSel[16][4] ? io_fromRename_4_bits_vpu_isNarrow : io_fromRename_5_bits_vpu_isNarrow)))));
  assign io_toIssueQueues_16_bits_vpu_isDstMask = (ohSel[16][0] ? io_fromRename_0_bits_vpu_isDstMask : (ohSel[16][1] ? io_fromRename_1_bits_vpu_isDstMask : (ohSel[16][2] ? io_fromRename_2_bits_vpu_isDstMask : (ohSel[16][3] ? io_fromRename_3_bits_vpu_isDstMask : (ohSel[16][4] ? io_fromRename_4_bits_vpu_isDstMask : io_fromRename_5_bits_vpu_isDstMask)))));
  assign io_toIssueQueues_16_bits_vpu_isOpMask = (ohSel[16][0] ? io_fromRename_0_bits_vpu_isOpMask : (ohSel[16][1] ? io_fromRename_1_bits_vpu_isOpMask : (ohSel[16][2] ? io_fromRename_2_bits_vpu_isOpMask : (ohSel[16][3] ? io_fromRename_3_bits_vpu_isOpMask : (ohSel[16][4] ? io_fromRename_4_bits_vpu_isOpMask : io_fromRename_5_bits_vpu_isOpMask)))));
  assign io_toIssueQueues_16_bits_vpu_isDependOldVd = (ohSel[16][0] ? io_fromRename_0_bits_vpu_isDependOldVd : (ohSel[16][1] ? io_fromRename_1_bits_vpu_isDependOldVd : (ohSel[16][2] ? io_fromRename_2_bits_vpu_isDependOldVd : (ohSel[16][3] ? io_fromRename_3_bits_vpu_isDependOldVd : (ohSel[16][4] ? io_fromRename_4_bits_vpu_isDependOldVd : io_fromRename_5_bits_vpu_isDependOldVd)))));
  assign io_toIssueQueues_16_bits_vpu_isWritePartVd = (ohSel[16][0] ? io_fromRename_0_bits_vpu_isWritePartVd : (ohSel[16][1] ? io_fromRename_1_bits_vpu_isWritePartVd : (ohSel[16][2] ? io_fromRename_2_bits_vpu_isWritePartVd : (ohSel[16][3] ? io_fromRename_3_bits_vpu_isWritePartVd : (ohSel[16][4] ? io_fromRename_4_bits_vpu_isWritePartVd : io_fromRename_5_bits_vpu_isWritePartVd)))));
  assign io_toIssueQueues_16_bits_uopIdx = (ohSel[16][0] ? io_fromRename_0_bits_uopIdx : (ohSel[16][1] ? io_fromRename_1_bits_uopIdx : (ohSel[16][2] ? io_fromRename_2_bits_uopIdx : (ohSel[16][3] ? io_fromRename_3_bits_uopIdx : (ohSel[16][4] ? io_fromRename_4_bits_uopIdx : io_fromRename_5_bits_uopIdx)))));
  assign io_toIssueQueues_16_bits_lastUop = (ohSel[16][0] ? io_fromRename_0_bits_lastUop : (ohSel[16][1] ? io_fromRename_1_bits_lastUop : (ohSel[16][2] ? io_fromRename_2_bits_lastUop : (ohSel[16][3] ? io_fromRename_3_bits_lastUop : (ohSel[16][4] ? io_fromRename_4_bits_lastUop : io_fromRename_5_bits_lastUop)))));
  assign io_toIssueQueues_16_bits_srcState_0 = (ohSel[16][0] ? (allSrcState[0][0][2]) : (ohSel[16][1] ? (allSrcState[1][0][2]) : (ohSel[16][2] ? (allSrcState[2][0][2]) : (ohSel[16][3] ? (allSrcState[3][0][2]) : (ohSel[16][4] ? (allSrcState[4][0][2]) : (allSrcState[5][0][2]))))));
  assign io_toIssueQueues_16_bits_srcState_1 = (ohSel[16][0] ? (allSrcState[0][1][2]) : (ohSel[16][1] ? (allSrcState[1][1][2]) : (ohSel[16][2] ? (allSrcState[2][1][2]) : (ohSel[16][3] ? (allSrcState[3][1][2]) : (ohSel[16][4] ? (allSrcState[4][1][2]) : (allSrcState[5][1][2]))))));
  assign io_toIssueQueues_16_bits_srcState_2 = (ohSel[16][0] ? (allSrcState[0][2][2]) : (ohSel[16][1] ? (allSrcState[1][2][2]) : (ohSel[16][2] ? (allSrcState[2][2][2]) : (ohSel[16][3] ? (allSrcState[3][2][2]) : (ohSel[16][4] ? (allSrcState[4][2][2]) : (allSrcState[5][2][2]))))));
  assign io_toIssueQueues_16_bits_srcState_3 = (ohSel[16][0] ? (allSrcState[0][3][3]) : (ohSel[16][1] ? (allSrcState[1][3][3]) : (ohSel[16][2] ? (allSrcState[2][3][3]) : (ohSel[16][3] ? (allSrcState[3][3][3]) : (ohSel[16][4] ? (allSrcState[4][3][3]) : (allSrcState[5][3][3]))))));
  assign io_toIssueQueues_16_bits_srcState_4 = (ohSel[16][0] ? (allSrcState[0][4][4]) : (ohSel[16][1] ? (allSrcState[1][4][4]) : (ohSel[16][2] ? (allSrcState[2][4][4]) : (ohSel[16][3] ? (allSrcState[3][4][4]) : (ohSel[16][4] ? (allSrcState[4][4][4]) : (allSrcState[5][4][4]))))));
  assign io_toIssueQueues_16_bits_psrc_0 = (ohSel[16][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[16][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[16][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[16][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[16][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_16_bits_psrc_1 = (ohSel[16][0] ? io_fromRename_0_bits_psrc_1 : (ohSel[16][1] ? io_fromRename_1_bits_psrc_1 : (ohSel[16][2] ? io_fromRename_2_bits_psrc_1 : (ohSel[16][3] ? io_fromRename_3_bits_psrc_1 : (ohSel[16][4] ? io_fromRename_4_bits_psrc_1 : io_fromRename_5_bits_psrc_1)))));
  assign io_toIssueQueues_16_bits_psrc_2 = (ohSel[16][0] ? io_fromRename_0_bits_psrc_2 : (ohSel[16][1] ? io_fromRename_1_bits_psrc_2 : (ohSel[16][2] ? io_fromRename_2_bits_psrc_2 : (ohSel[16][3] ? io_fromRename_3_bits_psrc_2 : (ohSel[16][4] ? io_fromRename_4_bits_psrc_2 : io_fromRename_5_bits_psrc_2)))));
  assign io_toIssueQueues_16_bits_psrc_3 = (ohSel[16][0] ? io_fromRename_0_bits_psrc_3 : (ohSel[16][1] ? io_fromRename_1_bits_psrc_3 : (ohSel[16][2] ? io_fromRename_2_bits_psrc_3 : (ohSel[16][3] ? io_fromRename_3_bits_psrc_3 : (ohSel[16][4] ? io_fromRename_4_bits_psrc_3 : io_fromRename_5_bits_psrc_3)))));
  assign io_toIssueQueues_16_bits_psrc_4 = (ohSel[16][0] ? io_fromRename_0_bits_psrc_4 : (ohSel[16][1] ? io_fromRename_1_bits_psrc_4 : (ohSel[16][2] ? io_fromRename_2_bits_psrc_4 : (ohSel[16][3] ? io_fromRename_3_bits_psrc_4 : (ohSel[16][4] ? io_fromRename_4_bits_psrc_4 : io_fromRename_5_bits_psrc_4)))));
  assign io_toIssueQueues_16_bits_pdest = (ohSel[16][0] ? io_fromRename_0_bits_pdest : (ohSel[16][1] ? io_fromRename_1_bits_pdest : (ohSel[16][2] ? io_fromRename_2_bits_pdest : (ohSel[16][3] ? io_fromRename_3_bits_pdest : (ohSel[16][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_16_bits_robIdx_flag = (ohSel[16][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[16][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[16][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[16][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[16][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_16_bits_robIdx_value = (ohSel[16][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[16][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[16][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[16][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[16][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  // -- 端口 17(IQ 8 enq 1)--
  assign io_toIssueQueues_17_valid = (ohSel[17][0] ? fromRenameUpdate_valid[0] : (ohSel[17][1] ? fromRenameUpdate_valid[1] : (ohSel[17][2] ? fromRenameUpdate_valid[2] : (ohSel[17][3] ? fromRenameUpdate_valid[3] : (ohSel[17][4] ? fromRenameUpdate_valid[4] : (ohSel[17][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_17_bits_srcType_0 = (ohSel[17][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[17][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[17][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[17][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[17][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_17_bits_srcType_1 = (ohSel[17][0] ? io_fromRename_0_bits_srcType_1 : (ohSel[17][1] ? io_fromRename_1_bits_srcType_1 : (ohSel[17][2] ? io_fromRename_2_bits_srcType_1 : (ohSel[17][3] ? io_fromRename_3_bits_srcType_1 : (ohSel[17][4] ? io_fromRename_4_bits_srcType_1 : io_fromRename_5_bits_srcType_1)))));
  assign io_toIssueQueues_17_bits_srcType_2 = (ohSel[17][0] ? fru_srcType2[0] : (ohSel[17][1] ? fru_srcType2[1] : (ohSel[17][2] ? fru_srcType2[2] : (ohSel[17][3] ? fru_srcType2[3] : (ohSel[17][4] ? fru_srcType2[4] : fru_srcType2[5])))));
  assign io_toIssueQueues_17_bits_srcType_3 = (ohSel[17][0] ? io_fromRename_0_bits_srcType_3 : (ohSel[17][1] ? io_fromRename_1_bits_srcType_3 : (ohSel[17][2] ? io_fromRename_2_bits_srcType_3 : (ohSel[17][3] ? io_fromRename_3_bits_srcType_3 : (ohSel[17][4] ? io_fromRename_4_bits_srcType_3 : io_fromRename_5_bits_srcType_3)))));
  assign io_toIssueQueues_17_bits_srcType_4 = (ohSel[17][0] ? io_fromRename_0_bits_srcType_4 : (ohSel[17][1] ? io_fromRename_1_bits_srcType_4 : (ohSel[17][2] ? io_fromRename_2_bits_srcType_4 : (ohSel[17][3] ? io_fromRename_3_bits_srcType_4 : (ohSel[17][4] ? io_fromRename_4_bits_srcType_4 : io_fromRename_5_bits_srcType_4)))));
  assign io_toIssueQueues_17_bits_fuType = (ohSel[17][0] ? io_fromRename_0_bits_fuType : (ohSel[17][1] ? io_fromRename_1_bits_fuType : (ohSel[17][2] ? io_fromRename_2_bits_fuType : (ohSel[17][3] ? io_fromRename_3_bits_fuType : (ohSel[17][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_17_bits_fuOpType = (ohSel[17][0] ? io_fromRename_0_bits_fuOpType : (ohSel[17][1] ? io_fromRename_1_bits_fuOpType : (ohSel[17][2] ? io_fromRename_2_bits_fuOpType : (ohSel[17][3] ? io_fromRename_3_bits_fuOpType : (ohSel[17][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_17_bits_fpWen = (ohSel[17][0] ? io_fromRename_0_bits_fpWen : (ohSel[17][1] ? io_fromRename_1_bits_fpWen : (ohSel[17][2] ? io_fromRename_2_bits_fpWen : (ohSel[17][3] ? io_fromRename_3_bits_fpWen : (ohSel[17][4] ? io_fromRename_4_bits_fpWen : io_fromRename_5_bits_fpWen)))));
  assign io_toIssueQueues_17_bits_vecWen = (ohSel[17][0] ? io_fromRename_0_bits_vecWen : (ohSel[17][1] ? io_fromRename_1_bits_vecWen : (ohSel[17][2] ? io_fromRename_2_bits_vecWen : (ohSel[17][3] ? io_fromRename_3_bits_vecWen : (ohSel[17][4] ? io_fromRename_4_bits_vecWen : io_fromRename_5_bits_vecWen)))));
  assign io_toIssueQueues_17_bits_v0Wen = (ohSel[17][0] ? io_fromRename_0_bits_v0Wen : (ohSel[17][1] ? io_fromRename_1_bits_v0Wen : (ohSel[17][2] ? io_fromRename_2_bits_v0Wen : (ohSel[17][3] ? io_fromRename_3_bits_v0Wen : (ohSel[17][4] ? io_fromRename_4_bits_v0Wen : io_fromRename_5_bits_v0Wen)))));
  assign io_toIssueQueues_17_bits_fpu_wflags = (ohSel[17][0] ? io_fromRename_0_bits_fpu_wflags : (ohSel[17][1] ? io_fromRename_1_bits_fpu_wflags : (ohSel[17][2] ? io_fromRename_2_bits_fpu_wflags : (ohSel[17][3] ? io_fromRename_3_bits_fpu_wflags : (ohSel[17][4] ? io_fromRename_4_bits_fpu_wflags : io_fromRename_5_bits_fpu_wflags)))));
  assign io_toIssueQueues_17_bits_vpu_vma = (ohSel[17][0] ? io_fromRename_0_bits_vpu_vma : (ohSel[17][1] ? io_fromRename_1_bits_vpu_vma : (ohSel[17][2] ? io_fromRename_2_bits_vpu_vma : (ohSel[17][3] ? io_fromRename_3_bits_vpu_vma : (ohSel[17][4] ? io_fromRename_4_bits_vpu_vma : io_fromRename_5_bits_vpu_vma)))));
  assign io_toIssueQueues_17_bits_vpu_vta = (ohSel[17][0] ? io_fromRename_0_bits_vpu_vta : (ohSel[17][1] ? io_fromRename_1_bits_vpu_vta : (ohSel[17][2] ? io_fromRename_2_bits_vpu_vta : (ohSel[17][3] ? io_fromRename_3_bits_vpu_vta : (ohSel[17][4] ? io_fromRename_4_bits_vpu_vta : io_fromRename_5_bits_vpu_vta)))));
  assign io_toIssueQueues_17_bits_vpu_vsew = (ohSel[17][0] ? io_fromRename_0_bits_vpu_vsew : (ohSel[17][1] ? io_fromRename_1_bits_vpu_vsew : (ohSel[17][2] ? io_fromRename_2_bits_vpu_vsew : (ohSel[17][3] ? io_fromRename_3_bits_vpu_vsew : (ohSel[17][4] ? io_fromRename_4_bits_vpu_vsew : io_fromRename_5_bits_vpu_vsew)))));
  assign io_toIssueQueues_17_bits_vpu_vlmul = (ohSel[17][0] ? io_fromRename_0_bits_vpu_vlmul : (ohSel[17][1] ? io_fromRename_1_bits_vpu_vlmul : (ohSel[17][2] ? io_fromRename_2_bits_vpu_vlmul : (ohSel[17][3] ? io_fromRename_3_bits_vpu_vlmul : (ohSel[17][4] ? io_fromRename_4_bits_vpu_vlmul : io_fromRename_5_bits_vpu_vlmul)))));
  assign io_toIssueQueues_17_bits_vpu_vm = (ohSel[17][0] ? io_fromRename_0_bits_vpu_vm : (ohSel[17][1] ? io_fromRename_1_bits_vpu_vm : (ohSel[17][2] ? io_fromRename_2_bits_vpu_vm : (ohSel[17][3] ? io_fromRename_3_bits_vpu_vm : (ohSel[17][4] ? io_fromRename_4_bits_vpu_vm : io_fromRename_5_bits_vpu_vm)))));
  assign io_toIssueQueues_17_bits_vpu_vstart = (ohSel[17][0] ? io_fromRename_0_bits_vpu_vstart : (ohSel[17][1] ? io_fromRename_1_bits_vpu_vstart : (ohSel[17][2] ? io_fromRename_2_bits_vpu_vstart : (ohSel[17][3] ? io_fromRename_3_bits_vpu_vstart : (ohSel[17][4] ? io_fromRename_4_bits_vpu_vstart : io_fromRename_5_bits_vpu_vstart)))));
  assign io_toIssueQueues_17_bits_vpu_fpu_isFoldTo1_2 = (ohSel[17][0] ? io_fromRename_0_bits_vpu_fpu_isFoldTo1_2 : (ohSel[17][1] ? io_fromRename_1_bits_vpu_fpu_isFoldTo1_2 : (ohSel[17][2] ? io_fromRename_2_bits_vpu_fpu_isFoldTo1_2 : (ohSel[17][3] ? io_fromRename_3_bits_vpu_fpu_isFoldTo1_2 : (ohSel[17][4] ? io_fromRename_4_bits_vpu_fpu_isFoldTo1_2 : io_fromRename_5_bits_vpu_fpu_isFoldTo1_2)))));
  assign io_toIssueQueues_17_bits_vpu_fpu_isFoldTo1_4 = (ohSel[17][0] ? io_fromRename_0_bits_vpu_fpu_isFoldTo1_4 : (ohSel[17][1] ? io_fromRename_1_bits_vpu_fpu_isFoldTo1_4 : (ohSel[17][2] ? io_fromRename_2_bits_vpu_fpu_isFoldTo1_4 : (ohSel[17][3] ? io_fromRename_3_bits_vpu_fpu_isFoldTo1_4 : (ohSel[17][4] ? io_fromRename_4_bits_vpu_fpu_isFoldTo1_4 : io_fromRename_5_bits_vpu_fpu_isFoldTo1_4)))));
  assign io_toIssueQueues_17_bits_vpu_fpu_isFoldTo1_8 = (ohSel[17][0] ? io_fromRename_0_bits_vpu_fpu_isFoldTo1_8 : (ohSel[17][1] ? io_fromRename_1_bits_vpu_fpu_isFoldTo1_8 : (ohSel[17][2] ? io_fromRename_2_bits_vpu_fpu_isFoldTo1_8 : (ohSel[17][3] ? io_fromRename_3_bits_vpu_fpu_isFoldTo1_8 : (ohSel[17][4] ? io_fromRename_4_bits_vpu_fpu_isFoldTo1_8 : io_fromRename_5_bits_vpu_fpu_isFoldTo1_8)))));
  assign io_toIssueQueues_17_bits_vpu_isExt = (ohSel[17][0] ? io_fromRename_0_bits_vpu_isExt : (ohSel[17][1] ? io_fromRename_1_bits_vpu_isExt : (ohSel[17][2] ? io_fromRename_2_bits_vpu_isExt : (ohSel[17][3] ? io_fromRename_3_bits_vpu_isExt : (ohSel[17][4] ? io_fromRename_4_bits_vpu_isExt : io_fromRename_5_bits_vpu_isExt)))));
  assign io_toIssueQueues_17_bits_vpu_isNarrow = (ohSel[17][0] ? io_fromRename_0_bits_vpu_isNarrow : (ohSel[17][1] ? io_fromRename_1_bits_vpu_isNarrow : (ohSel[17][2] ? io_fromRename_2_bits_vpu_isNarrow : (ohSel[17][3] ? io_fromRename_3_bits_vpu_isNarrow : (ohSel[17][4] ? io_fromRename_4_bits_vpu_isNarrow : io_fromRename_5_bits_vpu_isNarrow)))));
  assign io_toIssueQueues_17_bits_vpu_isDstMask = (ohSel[17][0] ? io_fromRename_0_bits_vpu_isDstMask : (ohSel[17][1] ? io_fromRename_1_bits_vpu_isDstMask : (ohSel[17][2] ? io_fromRename_2_bits_vpu_isDstMask : (ohSel[17][3] ? io_fromRename_3_bits_vpu_isDstMask : (ohSel[17][4] ? io_fromRename_4_bits_vpu_isDstMask : io_fromRename_5_bits_vpu_isDstMask)))));
  assign io_toIssueQueues_17_bits_vpu_isOpMask = (ohSel[17][0] ? io_fromRename_0_bits_vpu_isOpMask : (ohSel[17][1] ? io_fromRename_1_bits_vpu_isOpMask : (ohSel[17][2] ? io_fromRename_2_bits_vpu_isOpMask : (ohSel[17][3] ? io_fromRename_3_bits_vpu_isOpMask : (ohSel[17][4] ? io_fromRename_4_bits_vpu_isOpMask : io_fromRename_5_bits_vpu_isOpMask)))));
  assign io_toIssueQueues_17_bits_vpu_isDependOldVd = (ohSel[17][0] ? io_fromRename_0_bits_vpu_isDependOldVd : (ohSel[17][1] ? io_fromRename_1_bits_vpu_isDependOldVd : (ohSel[17][2] ? io_fromRename_2_bits_vpu_isDependOldVd : (ohSel[17][3] ? io_fromRename_3_bits_vpu_isDependOldVd : (ohSel[17][4] ? io_fromRename_4_bits_vpu_isDependOldVd : io_fromRename_5_bits_vpu_isDependOldVd)))));
  assign io_toIssueQueues_17_bits_vpu_isWritePartVd = (ohSel[17][0] ? io_fromRename_0_bits_vpu_isWritePartVd : (ohSel[17][1] ? io_fromRename_1_bits_vpu_isWritePartVd : (ohSel[17][2] ? io_fromRename_2_bits_vpu_isWritePartVd : (ohSel[17][3] ? io_fromRename_3_bits_vpu_isWritePartVd : (ohSel[17][4] ? io_fromRename_4_bits_vpu_isWritePartVd : io_fromRename_5_bits_vpu_isWritePartVd)))));
  assign io_toIssueQueues_17_bits_uopIdx = (ohSel[17][0] ? io_fromRename_0_bits_uopIdx : (ohSel[17][1] ? io_fromRename_1_bits_uopIdx : (ohSel[17][2] ? io_fromRename_2_bits_uopIdx : (ohSel[17][3] ? io_fromRename_3_bits_uopIdx : (ohSel[17][4] ? io_fromRename_4_bits_uopIdx : io_fromRename_5_bits_uopIdx)))));
  assign io_toIssueQueues_17_bits_lastUop = (ohSel[17][0] ? io_fromRename_0_bits_lastUop : (ohSel[17][1] ? io_fromRename_1_bits_lastUop : (ohSel[17][2] ? io_fromRename_2_bits_lastUop : (ohSel[17][3] ? io_fromRename_3_bits_lastUop : (ohSel[17][4] ? io_fromRename_4_bits_lastUop : io_fromRename_5_bits_lastUop)))));
  assign io_toIssueQueues_17_bits_srcState_0 = (ohSel[17][0] ? (allSrcState[0][0][2]) : (ohSel[17][1] ? (allSrcState[1][0][2]) : (ohSel[17][2] ? (allSrcState[2][0][2]) : (ohSel[17][3] ? (allSrcState[3][0][2]) : (ohSel[17][4] ? (allSrcState[4][0][2]) : (allSrcState[5][0][2]))))));
  assign io_toIssueQueues_17_bits_srcState_1 = (ohSel[17][0] ? (allSrcState[0][1][2]) : (ohSel[17][1] ? (allSrcState[1][1][2]) : (ohSel[17][2] ? (allSrcState[2][1][2]) : (ohSel[17][3] ? (allSrcState[3][1][2]) : (ohSel[17][4] ? (allSrcState[4][1][2]) : (allSrcState[5][1][2]))))));
  assign io_toIssueQueues_17_bits_srcState_2 = (ohSel[17][0] ? (allSrcState[0][2][2]) : (ohSel[17][1] ? (allSrcState[1][2][2]) : (ohSel[17][2] ? (allSrcState[2][2][2]) : (ohSel[17][3] ? (allSrcState[3][2][2]) : (ohSel[17][4] ? (allSrcState[4][2][2]) : (allSrcState[5][2][2]))))));
  assign io_toIssueQueues_17_bits_srcState_3 = (ohSel[17][0] ? (allSrcState[0][3][3]) : (ohSel[17][1] ? (allSrcState[1][3][3]) : (ohSel[17][2] ? (allSrcState[2][3][3]) : (ohSel[17][3] ? (allSrcState[3][3][3]) : (ohSel[17][4] ? (allSrcState[4][3][3]) : (allSrcState[5][3][3]))))));
  assign io_toIssueQueues_17_bits_srcState_4 = (ohSel[17][0] ? (allSrcState[0][4][4]) : (ohSel[17][1] ? (allSrcState[1][4][4]) : (ohSel[17][2] ? (allSrcState[2][4][4]) : (ohSel[17][3] ? (allSrcState[3][4][4]) : (ohSel[17][4] ? (allSrcState[4][4][4]) : (allSrcState[5][4][4]))))));
  assign io_toIssueQueues_17_bits_psrc_0 = (ohSel[17][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[17][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[17][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[17][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[17][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_17_bits_psrc_1 = (ohSel[17][0] ? io_fromRename_0_bits_psrc_1 : (ohSel[17][1] ? io_fromRename_1_bits_psrc_1 : (ohSel[17][2] ? io_fromRename_2_bits_psrc_1 : (ohSel[17][3] ? io_fromRename_3_bits_psrc_1 : (ohSel[17][4] ? io_fromRename_4_bits_psrc_1 : io_fromRename_5_bits_psrc_1)))));
  assign io_toIssueQueues_17_bits_psrc_2 = (ohSel[17][0] ? io_fromRename_0_bits_psrc_2 : (ohSel[17][1] ? io_fromRename_1_bits_psrc_2 : (ohSel[17][2] ? io_fromRename_2_bits_psrc_2 : (ohSel[17][3] ? io_fromRename_3_bits_psrc_2 : (ohSel[17][4] ? io_fromRename_4_bits_psrc_2 : io_fromRename_5_bits_psrc_2)))));
  assign io_toIssueQueues_17_bits_psrc_3 = (ohSel[17][0] ? io_fromRename_0_bits_psrc_3 : (ohSel[17][1] ? io_fromRename_1_bits_psrc_3 : (ohSel[17][2] ? io_fromRename_2_bits_psrc_3 : (ohSel[17][3] ? io_fromRename_3_bits_psrc_3 : (ohSel[17][4] ? io_fromRename_4_bits_psrc_3 : io_fromRename_5_bits_psrc_3)))));
  assign io_toIssueQueues_17_bits_psrc_4 = (ohSel[17][0] ? io_fromRename_0_bits_psrc_4 : (ohSel[17][1] ? io_fromRename_1_bits_psrc_4 : (ohSel[17][2] ? io_fromRename_2_bits_psrc_4 : (ohSel[17][3] ? io_fromRename_3_bits_psrc_4 : (ohSel[17][4] ? io_fromRename_4_bits_psrc_4 : io_fromRename_5_bits_psrc_4)))));
  assign io_toIssueQueues_17_bits_pdest = (ohSel[17][0] ? io_fromRename_0_bits_pdest : (ohSel[17][1] ? io_fromRename_1_bits_pdest : (ohSel[17][2] ? io_fromRename_2_bits_pdest : (ohSel[17][3] ? io_fromRename_3_bits_pdest : (ohSel[17][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_17_bits_robIdx_flag = (ohSel[17][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[17][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[17][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[17][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[17][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_17_bits_robIdx_value = (ohSel[17][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[17][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[17][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[17][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[17][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  // -- 端口 18(IQ 9 enq 0)--
  assign io_toIssueQueues_18_valid = (ohSel[18][0] ? fromRenameUpdate_valid[0] : (ohSel[18][1] ? fromRenameUpdate_valid[1] : (ohSel[18][2] ? fromRenameUpdate_valid[2] : (ohSel[18][3] ? fromRenameUpdate_valid[3] : (ohSel[18][4] ? fromRenameUpdate_valid[4] : (ohSel[18][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_18_bits_srcType_0 = (ohSel[18][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[18][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[18][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[18][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[18][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_18_bits_srcType_1 = (ohSel[18][0] ? io_fromRename_0_bits_srcType_1 : (ohSel[18][1] ? io_fromRename_1_bits_srcType_1 : (ohSel[18][2] ? io_fromRename_2_bits_srcType_1 : (ohSel[18][3] ? io_fromRename_3_bits_srcType_1 : (ohSel[18][4] ? io_fromRename_4_bits_srcType_1 : io_fromRename_5_bits_srcType_1)))));
  assign io_toIssueQueues_18_bits_srcType_2 = (ohSel[18][0] ? fru_srcType2[0] : (ohSel[18][1] ? fru_srcType2[1] : (ohSel[18][2] ? fru_srcType2[2] : (ohSel[18][3] ? fru_srcType2[3] : (ohSel[18][4] ? fru_srcType2[4] : fru_srcType2[5])))));
  assign io_toIssueQueues_18_bits_srcType_3 = (ohSel[18][0] ? io_fromRename_0_bits_srcType_3 : (ohSel[18][1] ? io_fromRename_1_bits_srcType_3 : (ohSel[18][2] ? io_fromRename_2_bits_srcType_3 : (ohSel[18][3] ? io_fromRename_3_bits_srcType_3 : (ohSel[18][4] ? io_fromRename_4_bits_srcType_3 : io_fromRename_5_bits_srcType_3)))));
  assign io_toIssueQueues_18_bits_srcType_4 = (ohSel[18][0] ? io_fromRename_0_bits_srcType_4 : (ohSel[18][1] ? io_fromRename_1_bits_srcType_4 : (ohSel[18][2] ? io_fromRename_2_bits_srcType_4 : (ohSel[18][3] ? io_fromRename_3_bits_srcType_4 : (ohSel[18][4] ? io_fromRename_4_bits_srcType_4 : io_fromRename_5_bits_srcType_4)))));
  assign io_toIssueQueues_18_bits_fuType = (ohSel[18][0] ? io_fromRename_0_bits_fuType : (ohSel[18][1] ? io_fromRename_1_bits_fuType : (ohSel[18][2] ? io_fromRename_2_bits_fuType : (ohSel[18][3] ? io_fromRename_3_bits_fuType : (ohSel[18][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_18_bits_fuOpType = (ohSel[18][0] ? io_fromRename_0_bits_fuOpType : (ohSel[18][1] ? io_fromRename_1_bits_fuOpType : (ohSel[18][2] ? io_fromRename_2_bits_fuOpType : (ohSel[18][3] ? io_fromRename_3_bits_fuOpType : (ohSel[18][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_18_bits_vecWen = (ohSel[18][0] ? io_fromRename_0_bits_vecWen : (ohSel[18][1] ? io_fromRename_1_bits_vecWen : (ohSel[18][2] ? io_fromRename_2_bits_vecWen : (ohSel[18][3] ? io_fromRename_3_bits_vecWen : (ohSel[18][4] ? io_fromRename_4_bits_vecWen : io_fromRename_5_bits_vecWen)))));
  assign io_toIssueQueues_18_bits_v0Wen = (ohSel[18][0] ? io_fromRename_0_bits_v0Wen : (ohSel[18][1] ? io_fromRename_1_bits_v0Wen : (ohSel[18][2] ? io_fromRename_2_bits_v0Wen : (ohSel[18][3] ? io_fromRename_3_bits_v0Wen : (ohSel[18][4] ? io_fromRename_4_bits_v0Wen : io_fromRename_5_bits_v0Wen)))));
  assign io_toIssueQueues_18_bits_fpu_wflags = (ohSel[18][0] ? io_fromRename_0_bits_fpu_wflags : (ohSel[18][1] ? io_fromRename_1_bits_fpu_wflags : (ohSel[18][2] ? io_fromRename_2_bits_fpu_wflags : (ohSel[18][3] ? io_fromRename_3_bits_fpu_wflags : (ohSel[18][4] ? io_fromRename_4_bits_fpu_wflags : io_fromRename_5_bits_fpu_wflags)))));
  assign io_toIssueQueues_18_bits_vpu_vma = (ohSel[18][0] ? io_fromRename_0_bits_vpu_vma : (ohSel[18][1] ? io_fromRename_1_bits_vpu_vma : (ohSel[18][2] ? io_fromRename_2_bits_vpu_vma : (ohSel[18][3] ? io_fromRename_3_bits_vpu_vma : (ohSel[18][4] ? io_fromRename_4_bits_vpu_vma : io_fromRename_5_bits_vpu_vma)))));
  assign io_toIssueQueues_18_bits_vpu_vta = (ohSel[18][0] ? io_fromRename_0_bits_vpu_vta : (ohSel[18][1] ? io_fromRename_1_bits_vpu_vta : (ohSel[18][2] ? io_fromRename_2_bits_vpu_vta : (ohSel[18][3] ? io_fromRename_3_bits_vpu_vta : (ohSel[18][4] ? io_fromRename_4_bits_vpu_vta : io_fromRename_5_bits_vpu_vta)))));
  assign io_toIssueQueues_18_bits_vpu_vsew = (ohSel[18][0] ? io_fromRename_0_bits_vpu_vsew : (ohSel[18][1] ? io_fromRename_1_bits_vpu_vsew : (ohSel[18][2] ? io_fromRename_2_bits_vpu_vsew : (ohSel[18][3] ? io_fromRename_3_bits_vpu_vsew : (ohSel[18][4] ? io_fromRename_4_bits_vpu_vsew : io_fromRename_5_bits_vpu_vsew)))));
  assign io_toIssueQueues_18_bits_vpu_vlmul = (ohSel[18][0] ? io_fromRename_0_bits_vpu_vlmul : (ohSel[18][1] ? io_fromRename_1_bits_vpu_vlmul : (ohSel[18][2] ? io_fromRename_2_bits_vpu_vlmul : (ohSel[18][3] ? io_fromRename_3_bits_vpu_vlmul : (ohSel[18][4] ? io_fromRename_4_bits_vpu_vlmul : io_fromRename_5_bits_vpu_vlmul)))));
  assign io_toIssueQueues_18_bits_vpu_vm = (ohSel[18][0] ? io_fromRename_0_bits_vpu_vm : (ohSel[18][1] ? io_fromRename_1_bits_vpu_vm : (ohSel[18][2] ? io_fromRename_2_bits_vpu_vm : (ohSel[18][3] ? io_fromRename_3_bits_vpu_vm : (ohSel[18][4] ? io_fromRename_4_bits_vpu_vm : io_fromRename_5_bits_vpu_vm)))));
  assign io_toIssueQueues_18_bits_vpu_vstart = (ohSel[18][0] ? io_fromRename_0_bits_vpu_vstart : (ohSel[18][1] ? io_fromRename_1_bits_vpu_vstart : (ohSel[18][2] ? io_fromRename_2_bits_vpu_vstart : (ohSel[18][3] ? io_fromRename_3_bits_vpu_vstart : (ohSel[18][4] ? io_fromRename_4_bits_vpu_vstart : io_fromRename_5_bits_vpu_vstart)))));
  assign io_toIssueQueues_18_bits_vpu_isExt = (ohSel[18][0] ? io_fromRename_0_bits_vpu_isExt : (ohSel[18][1] ? io_fromRename_1_bits_vpu_isExt : (ohSel[18][2] ? io_fromRename_2_bits_vpu_isExt : (ohSel[18][3] ? io_fromRename_3_bits_vpu_isExt : (ohSel[18][4] ? io_fromRename_4_bits_vpu_isExt : io_fromRename_5_bits_vpu_isExt)))));
  assign io_toIssueQueues_18_bits_vpu_isNarrow = (ohSel[18][0] ? io_fromRename_0_bits_vpu_isNarrow : (ohSel[18][1] ? io_fromRename_1_bits_vpu_isNarrow : (ohSel[18][2] ? io_fromRename_2_bits_vpu_isNarrow : (ohSel[18][3] ? io_fromRename_3_bits_vpu_isNarrow : (ohSel[18][4] ? io_fromRename_4_bits_vpu_isNarrow : io_fromRename_5_bits_vpu_isNarrow)))));
  assign io_toIssueQueues_18_bits_vpu_isDstMask = (ohSel[18][0] ? io_fromRename_0_bits_vpu_isDstMask : (ohSel[18][1] ? io_fromRename_1_bits_vpu_isDstMask : (ohSel[18][2] ? io_fromRename_2_bits_vpu_isDstMask : (ohSel[18][3] ? io_fromRename_3_bits_vpu_isDstMask : (ohSel[18][4] ? io_fromRename_4_bits_vpu_isDstMask : io_fromRename_5_bits_vpu_isDstMask)))));
  assign io_toIssueQueues_18_bits_vpu_isOpMask = (ohSel[18][0] ? io_fromRename_0_bits_vpu_isOpMask : (ohSel[18][1] ? io_fromRename_1_bits_vpu_isOpMask : (ohSel[18][2] ? io_fromRename_2_bits_vpu_isOpMask : (ohSel[18][3] ? io_fromRename_3_bits_vpu_isOpMask : (ohSel[18][4] ? io_fromRename_4_bits_vpu_isOpMask : io_fromRename_5_bits_vpu_isOpMask)))));
  assign io_toIssueQueues_18_bits_vpu_isDependOldVd = (ohSel[18][0] ? io_fromRename_0_bits_vpu_isDependOldVd : (ohSel[18][1] ? io_fromRename_1_bits_vpu_isDependOldVd : (ohSel[18][2] ? io_fromRename_2_bits_vpu_isDependOldVd : (ohSel[18][3] ? io_fromRename_3_bits_vpu_isDependOldVd : (ohSel[18][4] ? io_fromRename_4_bits_vpu_isDependOldVd : io_fromRename_5_bits_vpu_isDependOldVd)))));
  assign io_toIssueQueues_18_bits_vpu_isWritePartVd = (ohSel[18][0] ? io_fromRename_0_bits_vpu_isWritePartVd : (ohSel[18][1] ? io_fromRename_1_bits_vpu_isWritePartVd : (ohSel[18][2] ? io_fromRename_2_bits_vpu_isWritePartVd : (ohSel[18][3] ? io_fromRename_3_bits_vpu_isWritePartVd : (ohSel[18][4] ? io_fromRename_4_bits_vpu_isWritePartVd : io_fromRename_5_bits_vpu_isWritePartVd)))));
  assign io_toIssueQueues_18_bits_uopIdx = (ohSel[18][0] ? io_fromRename_0_bits_uopIdx : (ohSel[18][1] ? io_fromRename_1_bits_uopIdx : (ohSel[18][2] ? io_fromRename_2_bits_uopIdx : (ohSel[18][3] ? io_fromRename_3_bits_uopIdx : (ohSel[18][4] ? io_fromRename_4_bits_uopIdx : io_fromRename_5_bits_uopIdx)))));
  assign io_toIssueQueues_18_bits_srcState_0 = (ohSel[18][0] ? (allSrcState[0][0][2]) : (ohSel[18][1] ? (allSrcState[1][0][2]) : (ohSel[18][2] ? (allSrcState[2][0][2]) : (ohSel[18][3] ? (allSrcState[3][0][2]) : (ohSel[18][4] ? (allSrcState[4][0][2]) : (allSrcState[5][0][2]))))));
  assign io_toIssueQueues_18_bits_srcState_1 = (ohSel[18][0] ? (allSrcState[0][1][2]) : (ohSel[18][1] ? (allSrcState[1][1][2]) : (ohSel[18][2] ? (allSrcState[2][1][2]) : (ohSel[18][3] ? (allSrcState[3][1][2]) : (ohSel[18][4] ? (allSrcState[4][1][2]) : (allSrcState[5][1][2]))))));
  assign io_toIssueQueues_18_bits_srcState_2 = (ohSel[18][0] ? (allSrcState[0][2][2]) : (ohSel[18][1] ? (allSrcState[1][2][2]) : (ohSel[18][2] ? (allSrcState[2][2][2]) : (ohSel[18][3] ? (allSrcState[3][2][2]) : (ohSel[18][4] ? (allSrcState[4][2][2]) : (allSrcState[5][2][2]))))));
  assign io_toIssueQueues_18_bits_srcState_3 = (ohSel[18][0] ? (allSrcState[0][3][3]) : (ohSel[18][1] ? (allSrcState[1][3][3]) : (ohSel[18][2] ? (allSrcState[2][3][3]) : (ohSel[18][3] ? (allSrcState[3][3][3]) : (ohSel[18][4] ? (allSrcState[4][3][3]) : (allSrcState[5][3][3]))))));
  assign io_toIssueQueues_18_bits_srcState_4 = (ohSel[18][0] ? (allSrcState[0][4][4]) : (ohSel[18][1] ? (allSrcState[1][4][4]) : (ohSel[18][2] ? (allSrcState[2][4][4]) : (ohSel[18][3] ? (allSrcState[3][4][4]) : (ohSel[18][4] ? (allSrcState[4][4][4]) : (allSrcState[5][4][4]))))));
  assign io_toIssueQueues_18_bits_psrc_0 = (ohSel[18][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[18][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[18][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[18][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[18][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_18_bits_psrc_1 = (ohSel[18][0] ? io_fromRename_0_bits_psrc_1 : (ohSel[18][1] ? io_fromRename_1_bits_psrc_1 : (ohSel[18][2] ? io_fromRename_2_bits_psrc_1 : (ohSel[18][3] ? io_fromRename_3_bits_psrc_1 : (ohSel[18][4] ? io_fromRename_4_bits_psrc_1 : io_fromRename_5_bits_psrc_1)))));
  assign io_toIssueQueues_18_bits_psrc_2 = (ohSel[18][0] ? io_fromRename_0_bits_psrc_2 : (ohSel[18][1] ? io_fromRename_1_bits_psrc_2 : (ohSel[18][2] ? io_fromRename_2_bits_psrc_2 : (ohSel[18][3] ? io_fromRename_3_bits_psrc_2 : (ohSel[18][4] ? io_fromRename_4_bits_psrc_2 : io_fromRename_5_bits_psrc_2)))));
  assign io_toIssueQueues_18_bits_psrc_3 = (ohSel[18][0] ? io_fromRename_0_bits_psrc_3 : (ohSel[18][1] ? io_fromRename_1_bits_psrc_3 : (ohSel[18][2] ? io_fromRename_2_bits_psrc_3 : (ohSel[18][3] ? io_fromRename_3_bits_psrc_3 : (ohSel[18][4] ? io_fromRename_4_bits_psrc_3 : io_fromRename_5_bits_psrc_3)))));
  assign io_toIssueQueues_18_bits_psrc_4 = (ohSel[18][0] ? io_fromRename_0_bits_psrc_4 : (ohSel[18][1] ? io_fromRename_1_bits_psrc_4 : (ohSel[18][2] ? io_fromRename_2_bits_psrc_4 : (ohSel[18][3] ? io_fromRename_3_bits_psrc_4 : (ohSel[18][4] ? io_fromRename_4_bits_psrc_4 : io_fromRename_5_bits_psrc_4)))));
  assign io_toIssueQueues_18_bits_pdest = (ohSel[18][0] ? io_fromRename_0_bits_pdest : (ohSel[18][1] ? io_fromRename_1_bits_pdest : (ohSel[18][2] ? io_fromRename_2_bits_pdest : (ohSel[18][3] ? io_fromRename_3_bits_pdest : (ohSel[18][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_18_bits_robIdx_flag = (ohSel[18][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[18][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[18][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[18][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[18][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_18_bits_robIdx_value = (ohSel[18][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[18][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[18][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[18][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[18][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  // -- 端口 19(IQ 9 enq 1)--
  assign io_toIssueQueues_19_valid = (ohSel[19][0] ? fromRenameUpdate_valid[0] : (ohSel[19][1] ? fromRenameUpdate_valid[1] : (ohSel[19][2] ? fromRenameUpdate_valid[2] : (ohSel[19][3] ? fromRenameUpdate_valid[3] : (ohSel[19][4] ? fromRenameUpdate_valid[4] : (ohSel[19][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_19_bits_srcType_0 = (ohSel[19][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[19][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[19][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[19][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[19][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_19_bits_srcType_1 = (ohSel[19][0] ? io_fromRename_0_bits_srcType_1 : (ohSel[19][1] ? io_fromRename_1_bits_srcType_1 : (ohSel[19][2] ? io_fromRename_2_bits_srcType_1 : (ohSel[19][3] ? io_fromRename_3_bits_srcType_1 : (ohSel[19][4] ? io_fromRename_4_bits_srcType_1 : io_fromRename_5_bits_srcType_1)))));
  assign io_toIssueQueues_19_bits_srcType_2 = (ohSel[19][0] ? fru_srcType2[0] : (ohSel[19][1] ? fru_srcType2[1] : (ohSel[19][2] ? fru_srcType2[2] : (ohSel[19][3] ? fru_srcType2[3] : (ohSel[19][4] ? fru_srcType2[4] : fru_srcType2[5])))));
  assign io_toIssueQueues_19_bits_srcType_3 = (ohSel[19][0] ? io_fromRename_0_bits_srcType_3 : (ohSel[19][1] ? io_fromRename_1_bits_srcType_3 : (ohSel[19][2] ? io_fromRename_2_bits_srcType_3 : (ohSel[19][3] ? io_fromRename_3_bits_srcType_3 : (ohSel[19][4] ? io_fromRename_4_bits_srcType_3 : io_fromRename_5_bits_srcType_3)))));
  assign io_toIssueQueues_19_bits_srcType_4 = (ohSel[19][0] ? io_fromRename_0_bits_srcType_4 : (ohSel[19][1] ? io_fromRename_1_bits_srcType_4 : (ohSel[19][2] ? io_fromRename_2_bits_srcType_4 : (ohSel[19][3] ? io_fromRename_3_bits_srcType_4 : (ohSel[19][4] ? io_fromRename_4_bits_srcType_4 : io_fromRename_5_bits_srcType_4)))));
  assign io_toIssueQueues_19_bits_fuType = (ohSel[19][0] ? io_fromRename_0_bits_fuType : (ohSel[19][1] ? io_fromRename_1_bits_fuType : (ohSel[19][2] ? io_fromRename_2_bits_fuType : (ohSel[19][3] ? io_fromRename_3_bits_fuType : (ohSel[19][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_19_bits_fuOpType = (ohSel[19][0] ? io_fromRename_0_bits_fuOpType : (ohSel[19][1] ? io_fromRename_1_bits_fuOpType : (ohSel[19][2] ? io_fromRename_2_bits_fuOpType : (ohSel[19][3] ? io_fromRename_3_bits_fuOpType : (ohSel[19][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_19_bits_vecWen = (ohSel[19][0] ? io_fromRename_0_bits_vecWen : (ohSel[19][1] ? io_fromRename_1_bits_vecWen : (ohSel[19][2] ? io_fromRename_2_bits_vecWen : (ohSel[19][3] ? io_fromRename_3_bits_vecWen : (ohSel[19][4] ? io_fromRename_4_bits_vecWen : io_fromRename_5_bits_vecWen)))));
  assign io_toIssueQueues_19_bits_v0Wen = (ohSel[19][0] ? io_fromRename_0_bits_v0Wen : (ohSel[19][1] ? io_fromRename_1_bits_v0Wen : (ohSel[19][2] ? io_fromRename_2_bits_v0Wen : (ohSel[19][3] ? io_fromRename_3_bits_v0Wen : (ohSel[19][4] ? io_fromRename_4_bits_v0Wen : io_fromRename_5_bits_v0Wen)))));
  assign io_toIssueQueues_19_bits_fpu_wflags = (ohSel[19][0] ? io_fromRename_0_bits_fpu_wflags : (ohSel[19][1] ? io_fromRename_1_bits_fpu_wflags : (ohSel[19][2] ? io_fromRename_2_bits_fpu_wflags : (ohSel[19][3] ? io_fromRename_3_bits_fpu_wflags : (ohSel[19][4] ? io_fromRename_4_bits_fpu_wflags : io_fromRename_5_bits_fpu_wflags)))));
  assign io_toIssueQueues_19_bits_vpu_vma = (ohSel[19][0] ? io_fromRename_0_bits_vpu_vma : (ohSel[19][1] ? io_fromRename_1_bits_vpu_vma : (ohSel[19][2] ? io_fromRename_2_bits_vpu_vma : (ohSel[19][3] ? io_fromRename_3_bits_vpu_vma : (ohSel[19][4] ? io_fromRename_4_bits_vpu_vma : io_fromRename_5_bits_vpu_vma)))));
  assign io_toIssueQueues_19_bits_vpu_vta = (ohSel[19][0] ? io_fromRename_0_bits_vpu_vta : (ohSel[19][1] ? io_fromRename_1_bits_vpu_vta : (ohSel[19][2] ? io_fromRename_2_bits_vpu_vta : (ohSel[19][3] ? io_fromRename_3_bits_vpu_vta : (ohSel[19][4] ? io_fromRename_4_bits_vpu_vta : io_fromRename_5_bits_vpu_vta)))));
  assign io_toIssueQueues_19_bits_vpu_vsew = (ohSel[19][0] ? io_fromRename_0_bits_vpu_vsew : (ohSel[19][1] ? io_fromRename_1_bits_vpu_vsew : (ohSel[19][2] ? io_fromRename_2_bits_vpu_vsew : (ohSel[19][3] ? io_fromRename_3_bits_vpu_vsew : (ohSel[19][4] ? io_fromRename_4_bits_vpu_vsew : io_fromRename_5_bits_vpu_vsew)))));
  assign io_toIssueQueues_19_bits_vpu_vlmul = (ohSel[19][0] ? io_fromRename_0_bits_vpu_vlmul : (ohSel[19][1] ? io_fromRename_1_bits_vpu_vlmul : (ohSel[19][2] ? io_fromRename_2_bits_vpu_vlmul : (ohSel[19][3] ? io_fromRename_3_bits_vpu_vlmul : (ohSel[19][4] ? io_fromRename_4_bits_vpu_vlmul : io_fromRename_5_bits_vpu_vlmul)))));
  assign io_toIssueQueues_19_bits_vpu_vm = (ohSel[19][0] ? io_fromRename_0_bits_vpu_vm : (ohSel[19][1] ? io_fromRename_1_bits_vpu_vm : (ohSel[19][2] ? io_fromRename_2_bits_vpu_vm : (ohSel[19][3] ? io_fromRename_3_bits_vpu_vm : (ohSel[19][4] ? io_fromRename_4_bits_vpu_vm : io_fromRename_5_bits_vpu_vm)))));
  assign io_toIssueQueues_19_bits_vpu_vstart = (ohSel[19][0] ? io_fromRename_0_bits_vpu_vstart : (ohSel[19][1] ? io_fromRename_1_bits_vpu_vstart : (ohSel[19][2] ? io_fromRename_2_bits_vpu_vstart : (ohSel[19][3] ? io_fromRename_3_bits_vpu_vstart : (ohSel[19][4] ? io_fromRename_4_bits_vpu_vstart : io_fromRename_5_bits_vpu_vstart)))));
  assign io_toIssueQueues_19_bits_vpu_isExt = (ohSel[19][0] ? io_fromRename_0_bits_vpu_isExt : (ohSel[19][1] ? io_fromRename_1_bits_vpu_isExt : (ohSel[19][2] ? io_fromRename_2_bits_vpu_isExt : (ohSel[19][3] ? io_fromRename_3_bits_vpu_isExt : (ohSel[19][4] ? io_fromRename_4_bits_vpu_isExt : io_fromRename_5_bits_vpu_isExt)))));
  assign io_toIssueQueues_19_bits_vpu_isNarrow = (ohSel[19][0] ? io_fromRename_0_bits_vpu_isNarrow : (ohSel[19][1] ? io_fromRename_1_bits_vpu_isNarrow : (ohSel[19][2] ? io_fromRename_2_bits_vpu_isNarrow : (ohSel[19][3] ? io_fromRename_3_bits_vpu_isNarrow : (ohSel[19][4] ? io_fromRename_4_bits_vpu_isNarrow : io_fromRename_5_bits_vpu_isNarrow)))));
  assign io_toIssueQueues_19_bits_vpu_isDstMask = (ohSel[19][0] ? io_fromRename_0_bits_vpu_isDstMask : (ohSel[19][1] ? io_fromRename_1_bits_vpu_isDstMask : (ohSel[19][2] ? io_fromRename_2_bits_vpu_isDstMask : (ohSel[19][3] ? io_fromRename_3_bits_vpu_isDstMask : (ohSel[19][4] ? io_fromRename_4_bits_vpu_isDstMask : io_fromRename_5_bits_vpu_isDstMask)))));
  assign io_toIssueQueues_19_bits_vpu_isOpMask = (ohSel[19][0] ? io_fromRename_0_bits_vpu_isOpMask : (ohSel[19][1] ? io_fromRename_1_bits_vpu_isOpMask : (ohSel[19][2] ? io_fromRename_2_bits_vpu_isOpMask : (ohSel[19][3] ? io_fromRename_3_bits_vpu_isOpMask : (ohSel[19][4] ? io_fromRename_4_bits_vpu_isOpMask : io_fromRename_5_bits_vpu_isOpMask)))));
  assign io_toIssueQueues_19_bits_vpu_isDependOldVd = (ohSel[19][0] ? io_fromRename_0_bits_vpu_isDependOldVd : (ohSel[19][1] ? io_fromRename_1_bits_vpu_isDependOldVd : (ohSel[19][2] ? io_fromRename_2_bits_vpu_isDependOldVd : (ohSel[19][3] ? io_fromRename_3_bits_vpu_isDependOldVd : (ohSel[19][4] ? io_fromRename_4_bits_vpu_isDependOldVd : io_fromRename_5_bits_vpu_isDependOldVd)))));
  assign io_toIssueQueues_19_bits_vpu_isWritePartVd = (ohSel[19][0] ? io_fromRename_0_bits_vpu_isWritePartVd : (ohSel[19][1] ? io_fromRename_1_bits_vpu_isWritePartVd : (ohSel[19][2] ? io_fromRename_2_bits_vpu_isWritePartVd : (ohSel[19][3] ? io_fromRename_3_bits_vpu_isWritePartVd : (ohSel[19][4] ? io_fromRename_4_bits_vpu_isWritePartVd : io_fromRename_5_bits_vpu_isWritePartVd)))));
  assign io_toIssueQueues_19_bits_uopIdx = (ohSel[19][0] ? io_fromRename_0_bits_uopIdx : (ohSel[19][1] ? io_fromRename_1_bits_uopIdx : (ohSel[19][2] ? io_fromRename_2_bits_uopIdx : (ohSel[19][3] ? io_fromRename_3_bits_uopIdx : (ohSel[19][4] ? io_fromRename_4_bits_uopIdx : io_fromRename_5_bits_uopIdx)))));
  assign io_toIssueQueues_19_bits_srcState_0 = (ohSel[19][0] ? (allSrcState[0][0][2]) : (ohSel[19][1] ? (allSrcState[1][0][2]) : (ohSel[19][2] ? (allSrcState[2][0][2]) : (ohSel[19][3] ? (allSrcState[3][0][2]) : (ohSel[19][4] ? (allSrcState[4][0][2]) : (allSrcState[5][0][2]))))));
  assign io_toIssueQueues_19_bits_srcState_1 = (ohSel[19][0] ? (allSrcState[0][1][2]) : (ohSel[19][1] ? (allSrcState[1][1][2]) : (ohSel[19][2] ? (allSrcState[2][1][2]) : (ohSel[19][3] ? (allSrcState[3][1][2]) : (ohSel[19][4] ? (allSrcState[4][1][2]) : (allSrcState[5][1][2]))))));
  assign io_toIssueQueues_19_bits_srcState_2 = (ohSel[19][0] ? (allSrcState[0][2][2]) : (ohSel[19][1] ? (allSrcState[1][2][2]) : (ohSel[19][2] ? (allSrcState[2][2][2]) : (ohSel[19][3] ? (allSrcState[3][2][2]) : (ohSel[19][4] ? (allSrcState[4][2][2]) : (allSrcState[5][2][2]))))));
  assign io_toIssueQueues_19_bits_srcState_3 = (ohSel[19][0] ? (allSrcState[0][3][3]) : (ohSel[19][1] ? (allSrcState[1][3][3]) : (ohSel[19][2] ? (allSrcState[2][3][3]) : (ohSel[19][3] ? (allSrcState[3][3][3]) : (ohSel[19][4] ? (allSrcState[4][3][3]) : (allSrcState[5][3][3]))))));
  assign io_toIssueQueues_19_bits_srcState_4 = (ohSel[19][0] ? (allSrcState[0][4][4]) : (ohSel[19][1] ? (allSrcState[1][4][4]) : (ohSel[19][2] ? (allSrcState[2][4][4]) : (ohSel[19][3] ? (allSrcState[3][4][4]) : (ohSel[19][4] ? (allSrcState[4][4][4]) : (allSrcState[5][4][4]))))));
  assign io_toIssueQueues_19_bits_psrc_0 = (ohSel[19][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[19][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[19][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[19][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[19][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_19_bits_psrc_1 = (ohSel[19][0] ? io_fromRename_0_bits_psrc_1 : (ohSel[19][1] ? io_fromRename_1_bits_psrc_1 : (ohSel[19][2] ? io_fromRename_2_bits_psrc_1 : (ohSel[19][3] ? io_fromRename_3_bits_psrc_1 : (ohSel[19][4] ? io_fromRename_4_bits_psrc_1 : io_fromRename_5_bits_psrc_1)))));
  assign io_toIssueQueues_19_bits_psrc_2 = (ohSel[19][0] ? io_fromRename_0_bits_psrc_2 : (ohSel[19][1] ? io_fromRename_1_bits_psrc_2 : (ohSel[19][2] ? io_fromRename_2_bits_psrc_2 : (ohSel[19][3] ? io_fromRename_3_bits_psrc_2 : (ohSel[19][4] ? io_fromRename_4_bits_psrc_2 : io_fromRename_5_bits_psrc_2)))));
  assign io_toIssueQueues_19_bits_psrc_3 = (ohSel[19][0] ? io_fromRename_0_bits_psrc_3 : (ohSel[19][1] ? io_fromRename_1_bits_psrc_3 : (ohSel[19][2] ? io_fromRename_2_bits_psrc_3 : (ohSel[19][3] ? io_fromRename_3_bits_psrc_3 : (ohSel[19][4] ? io_fromRename_4_bits_psrc_3 : io_fromRename_5_bits_psrc_3)))));
  assign io_toIssueQueues_19_bits_psrc_4 = (ohSel[19][0] ? io_fromRename_0_bits_psrc_4 : (ohSel[19][1] ? io_fromRename_1_bits_psrc_4 : (ohSel[19][2] ? io_fromRename_2_bits_psrc_4 : (ohSel[19][3] ? io_fromRename_3_bits_psrc_4 : (ohSel[19][4] ? io_fromRename_4_bits_psrc_4 : io_fromRename_5_bits_psrc_4)))));
  assign io_toIssueQueues_19_bits_pdest = (ohSel[19][0] ? io_fromRename_0_bits_pdest : (ohSel[19][1] ? io_fromRename_1_bits_pdest : (ohSel[19][2] ? io_fromRename_2_bits_pdest : (ohSel[19][3] ? io_fromRename_3_bits_pdest : (ohSel[19][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_19_bits_robIdx_flag = (ohSel[19][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[19][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[19][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[19][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[19][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_19_bits_robIdx_value = (ohSel[19][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[19][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[19][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[19][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[19][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  // -- 端口 20(IQ 10 enq 0)--
  assign io_toIssueQueues_20_valid = (ohSel[20][0] ? fromRenameUpdate_valid[0] : (ohSel[20][1] ? fromRenameUpdate_valid[1] : (ohSel[20][2] ? fromRenameUpdate_valid[2] : (ohSel[20][3] ? fromRenameUpdate_valid[3] : (ohSel[20][4] ? fromRenameUpdate_valid[4] : (ohSel[20][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_20_bits_ftqPtr_value = (ohSel[20][0] ? io_fromRename_0_bits_ftqPtr_value : (ohSel[20][1] ? io_fromRename_1_bits_ftqPtr_value : (ohSel[20][2] ? io_fromRename_2_bits_ftqPtr_value : (ohSel[20][3] ? io_fromRename_3_bits_ftqPtr_value : (ohSel[20][4] ? io_fromRename_4_bits_ftqPtr_value : io_fromRename_5_bits_ftqPtr_value)))));
  assign io_toIssueQueues_20_bits_ftqOffset = (ohSel[20][0] ? io_fromRename_0_bits_ftqOffset : (ohSel[20][1] ? io_fromRename_1_bits_ftqOffset : (ohSel[20][2] ? io_fromRename_2_bits_ftqOffset : (ohSel[20][3] ? io_fromRename_3_bits_ftqOffset : (ohSel[20][4] ? io_fromRename_4_bits_ftqOffset : io_fromRename_5_bits_ftqOffset)))));
  assign io_toIssueQueues_20_bits_srcType_0 = (ohSel[20][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[20][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[20][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[20][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[20][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_20_bits_srcType_1 = (ohSel[20][0] ? io_fromRename_0_bits_srcType_1 : (ohSel[20][1] ? io_fromRename_1_bits_srcType_1 : (ohSel[20][2] ? io_fromRename_2_bits_srcType_1 : (ohSel[20][3] ? io_fromRename_3_bits_srcType_1 : (ohSel[20][4] ? io_fromRename_4_bits_srcType_1 : io_fromRename_5_bits_srcType_1)))));
  assign io_toIssueQueues_20_bits_fuType = (ohSel[20][0] ? io_fromRename_0_bits_fuType : (ohSel[20][1] ? io_fromRename_1_bits_fuType : (ohSel[20][2] ? io_fromRename_2_bits_fuType : (ohSel[20][3] ? io_fromRename_3_bits_fuType : (ohSel[20][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_20_bits_fuOpType = (ohSel[20][0] ? io_fromRename_0_bits_fuOpType : (ohSel[20][1] ? io_fromRename_1_bits_fuOpType : (ohSel[20][2] ? io_fromRename_2_bits_fuOpType : (ohSel[20][3] ? io_fromRename_3_bits_fuOpType : (ohSel[20][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_20_bits_rfWen = (ohSel[20][0] ? io_fromRename_0_bits_rfWen : (ohSel[20][1] ? io_fromRename_1_bits_rfWen : (ohSel[20][2] ? io_fromRename_2_bits_rfWen : (ohSel[20][3] ? io_fromRename_3_bits_rfWen : (ohSel[20][4] ? io_fromRename_4_bits_rfWen : io_fromRename_5_bits_rfWen)))));
  assign io_toIssueQueues_20_bits_selImm = (ohSel[20][0] ? io_fromRename_0_bits_selImm : (ohSel[20][1] ? io_fromRename_1_bits_selImm : (ohSel[20][2] ? io_fromRename_2_bits_selImm : (ohSel[20][3] ? io_fromRename_3_bits_selImm : (ohSel[20][4] ? io_fromRename_4_bits_selImm : io_fromRename_5_bits_selImm)))));
  assign io_toIssueQueues_20_bits_imm = (ohSel[20][0] ? io_fromRename_0_bits_imm : (ohSel[20][1] ? io_fromRename_1_bits_imm : (ohSel[20][2] ? io_fromRename_2_bits_imm : (ohSel[20][3] ? io_fromRename_3_bits_imm : (ohSel[20][4] ? io_fromRename_4_bits_imm : io_fromRename_5_bits_imm)))));
  assign io_toIssueQueues_20_bits_isDropAmocasSta = (ohSel[20][0] ? fru_isDropAmocasSta[0] : (ohSel[20][1] ? fru_isDropAmocasSta[1] : (ohSel[20][2] ? fru_isDropAmocasSta[2] : (ohSel[20][3] ? fru_isDropAmocasSta[3] : (ohSel[20][4] ? fru_isDropAmocasSta[4] : fru_isDropAmocasSta[5])))));
  assign io_toIssueQueues_20_bits_srcState_0 = (ohSel[20][0] ? (allSrcState[0][0][0]) : (ohSel[20][1] ? (allSrcState[1][0][0]) : (ohSel[20][2] ? (allSrcState[2][0][0]) : (ohSel[20][3] ? (allSrcState[3][0][0]) : (ohSel[20][4] ? (allSrcState[4][0][0]) : (allSrcState[5][0][0]))))));
  assign io_toIssueQueues_20_bits_srcState_1 = (ohSel[20][0] ? (allSrcState[0][1][0] | allSrcState[0][1][1]) : (ohSel[20][1] ? (allSrcState[1][1][0] | allSrcState[1][1][1]) : (ohSel[20][2] ? (allSrcState[2][1][0] | allSrcState[2][1][1]) : (ohSel[20][3] ? (allSrcState[3][1][0] | allSrcState[3][1][1]) : (ohSel[20][4] ? (allSrcState[4][1][0] | allSrcState[4][1][1]) : (allSrcState[5][1][0] | allSrcState[5][1][1]))))));
  assign io_toIssueQueues_20_bits_srcLoadDependency_0_0 = (ohSel[20][0] ? fru_srcLoadDep[0][0][0] : (ohSel[20][1] ? fru_srcLoadDep[1][0][0] : (ohSel[20][2] ? fru_srcLoadDep[2][0][0] : (ohSel[20][3] ? fru_srcLoadDep[3][0][0] : (ohSel[20][4] ? fru_srcLoadDep[4][0][0] : fru_srcLoadDep[5][0][0])))));
  assign io_toIssueQueues_20_bits_srcLoadDependency_0_1 = (ohSel[20][0] ? fru_srcLoadDep[0][0][1] : (ohSel[20][1] ? fru_srcLoadDep[1][0][1] : (ohSel[20][2] ? fru_srcLoadDep[2][0][1] : (ohSel[20][3] ? fru_srcLoadDep[3][0][1] : (ohSel[20][4] ? fru_srcLoadDep[4][0][1] : fru_srcLoadDep[5][0][1])))));
  assign io_toIssueQueues_20_bits_srcLoadDependency_0_2 = (ohSel[20][0] ? fru_srcLoadDep[0][0][2] : (ohSel[20][1] ? fru_srcLoadDep[1][0][2] : (ohSel[20][2] ? fru_srcLoadDep[2][0][2] : (ohSel[20][3] ? fru_srcLoadDep[3][0][2] : (ohSel[20][4] ? fru_srcLoadDep[4][0][2] : fru_srcLoadDep[5][0][2])))));
  assign io_toIssueQueues_20_bits_srcLoadDependency_1_0 = (ohSel[20][0] ? fru_srcLoadDep[0][1][0] : (ohSel[20][1] ? fru_srcLoadDep[1][1][0] : (ohSel[20][2] ? fru_srcLoadDep[2][1][0] : (ohSel[20][3] ? fru_srcLoadDep[3][1][0] : (ohSel[20][4] ? fru_srcLoadDep[4][1][0] : fru_srcLoadDep[5][1][0])))));
  assign io_toIssueQueues_20_bits_srcLoadDependency_1_1 = (ohSel[20][0] ? fru_srcLoadDep[0][1][1] : (ohSel[20][1] ? fru_srcLoadDep[1][1][1] : (ohSel[20][2] ? fru_srcLoadDep[2][1][1] : (ohSel[20][3] ? fru_srcLoadDep[3][1][1] : (ohSel[20][4] ? fru_srcLoadDep[4][1][1] : fru_srcLoadDep[5][1][1])))));
  assign io_toIssueQueues_20_bits_srcLoadDependency_1_2 = (ohSel[20][0] ? fru_srcLoadDep[0][1][2] : (ohSel[20][1] ? fru_srcLoadDep[1][1][2] : (ohSel[20][2] ? fru_srcLoadDep[2][1][2] : (ohSel[20][3] ? fru_srcLoadDep[3][1][2] : (ohSel[20][4] ? fru_srcLoadDep[4][1][2] : fru_srcLoadDep[5][1][2])))));
  assign io_toIssueQueues_20_bits_psrc_0 = (ohSel[20][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[20][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[20][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[20][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[20][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_20_bits_psrc_1 = (ohSel[20][0] ? io_fromRename_0_bits_psrc_1 : (ohSel[20][1] ? io_fromRename_1_bits_psrc_1 : (ohSel[20][2] ? io_fromRename_2_bits_psrc_1 : (ohSel[20][3] ? io_fromRename_3_bits_psrc_1 : (ohSel[20][4] ? io_fromRename_4_bits_psrc_1 : io_fromRename_5_bits_psrc_1)))));
  assign io_toIssueQueues_20_bits_pdest = (ohSel[20][0] ? io_fromRename_0_bits_pdest : (ohSel[20][1] ? io_fromRename_1_bits_pdest : (ohSel[20][2] ? io_fromRename_2_bits_pdest : (ohSel[20][3] ? io_fromRename_3_bits_pdest : (ohSel[20][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_20_bits_useRegCache_0 = (ohSel[20][0] ? _rcTagTable_io_readPorts_0_valid : (ohSel[20][1] ? _rcTagTable_io_readPorts_2_valid : (ohSel[20][2] ? _rcTagTable_io_readPorts_4_valid : (ohSel[20][3] ? _rcTagTable_io_readPorts_6_valid : (ohSel[20][4] ? _rcTagTable_io_readPorts_8_valid : _rcTagTable_io_readPorts_10_valid)))));
  assign io_toIssueQueues_20_bits_useRegCache_1 = (ohSel[20][0] ? _rcTagTable_io_readPorts_1_valid : (ohSel[20][1] ? _rcTagTable_io_readPorts_3_valid : (ohSel[20][2] ? _rcTagTable_io_readPorts_5_valid : (ohSel[20][3] ? _rcTagTable_io_readPorts_7_valid : (ohSel[20][4] ? _rcTagTable_io_readPorts_9_valid : _rcTagTable_io_readPorts_11_valid)))));
  assign io_toIssueQueues_20_bits_regCacheIdx_0 = (ohSel[20][0] ? _rcTagTable_io_readPorts_0_addr : (ohSel[20][1] ? _rcTagTable_io_readPorts_2_addr : (ohSel[20][2] ? _rcTagTable_io_readPorts_4_addr : (ohSel[20][3] ? _rcTagTable_io_readPorts_6_addr : (ohSel[20][4] ? _rcTagTable_io_readPorts_8_addr : _rcTagTable_io_readPorts_10_addr)))));
  assign io_toIssueQueues_20_bits_regCacheIdx_1 = (ohSel[20][0] ? _rcTagTable_io_readPorts_1_addr : (ohSel[20][1] ? _rcTagTable_io_readPorts_3_addr : (ohSel[20][2] ? _rcTagTable_io_readPorts_5_addr : (ohSel[20][3] ? _rcTagTable_io_readPorts_7_addr : (ohSel[20][4] ? _rcTagTable_io_readPorts_9_addr : _rcTagTable_io_readPorts_11_addr)))));
  assign io_toIssueQueues_20_bits_robIdx_flag = (ohSel[20][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[20][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[20][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[20][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[20][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_20_bits_robIdx_value = (ohSel[20][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[20][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[20][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[20][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[20][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  assign io_toIssueQueues_20_bits_sqIdx_flag = (ohSel[20][0] ? _lsqEnqCtrl_io_enq_resp_0_sqIdx_flag : (ohSel[20][1] ? _lsqEnqCtrl_io_enq_resp_1_sqIdx_flag : (ohSel[20][2] ? _lsqEnqCtrl_io_enq_resp_2_sqIdx_flag : (ohSel[20][3] ? _lsqEnqCtrl_io_enq_resp_3_sqIdx_flag : (ohSel[20][4] ? _lsqEnqCtrl_io_enq_resp_4_sqIdx_flag : _lsqEnqCtrl_io_enq_resp_5_sqIdx_flag)))));
  assign io_toIssueQueues_20_bits_sqIdx_value = (ohSel[20][0] ? _lsqEnqCtrl_io_enq_resp_0_sqIdx_value : (ohSel[20][1] ? _lsqEnqCtrl_io_enq_resp_1_sqIdx_value : (ohSel[20][2] ? _lsqEnqCtrl_io_enq_resp_2_sqIdx_value : (ohSel[20][3] ? _lsqEnqCtrl_io_enq_resp_3_sqIdx_value : (ohSel[20][4] ? _lsqEnqCtrl_io_enq_resp_4_sqIdx_value : _lsqEnqCtrl_io_enq_resp_5_sqIdx_value)))));
  // -- 端口 21(IQ 10 enq 1)--
  assign io_toIssueQueues_21_valid = (ohSel[21][0] ? fromRenameUpdate_valid[0] : (ohSel[21][1] ? fromRenameUpdate_valid[1] : (ohSel[21][2] ? fromRenameUpdate_valid[2] : (ohSel[21][3] ? fromRenameUpdate_valid[3] : (ohSel[21][4] ? fromRenameUpdate_valid[4] : (ohSel[21][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_21_bits_ftqPtr_value = (ohSel[21][0] ? io_fromRename_0_bits_ftqPtr_value : (ohSel[21][1] ? io_fromRename_1_bits_ftqPtr_value : (ohSel[21][2] ? io_fromRename_2_bits_ftqPtr_value : (ohSel[21][3] ? io_fromRename_3_bits_ftqPtr_value : (ohSel[21][4] ? io_fromRename_4_bits_ftqPtr_value : io_fromRename_5_bits_ftqPtr_value)))));
  assign io_toIssueQueues_21_bits_ftqOffset = (ohSel[21][0] ? io_fromRename_0_bits_ftqOffset : (ohSel[21][1] ? io_fromRename_1_bits_ftqOffset : (ohSel[21][2] ? io_fromRename_2_bits_ftqOffset : (ohSel[21][3] ? io_fromRename_3_bits_ftqOffset : (ohSel[21][4] ? io_fromRename_4_bits_ftqOffset : io_fromRename_5_bits_ftqOffset)))));
  assign io_toIssueQueues_21_bits_srcType_0 = (ohSel[21][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[21][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[21][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[21][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[21][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_21_bits_srcType_1 = (ohSel[21][0] ? io_fromRename_0_bits_srcType_1 : (ohSel[21][1] ? io_fromRename_1_bits_srcType_1 : (ohSel[21][2] ? io_fromRename_2_bits_srcType_1 : (ohSel[21][3] ? io_fromRename_3_bits_srcType_1 : (ohSel[21][4] ? io_fromRename_4_bits_srcType_1 : io_fromRename_5_bits_srcType_1)))));
  assign io_toIssueQueues_21_bits_fuType = (ohSel[21][0] ? io_fromRename_0_bits_fuType : (ohSel[21][1] ? io_fromRename_1_bits_fuType : (ohSel[21][2] ? io_fromRename_2_bits_fuType : (ohSel[21][3] ? io_fromRename_3_bits_fuType : (ohSel[21][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_21_bits_fuOpType = (ohSel[21][0] ? io_fromRename_0_bits_fuOpType : (ohSel[21][1] ? io_fromRename_1_bits_fuOpType : (ohSel[21][2] ? io_fromRename_2_bits_fuOpType : (ohSel[21][3] ? io_fromRename_3_bits_fuOpType : (ohSel[21][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_21_bits_rfWen = (ohSel[21][0] ? io_fromRename_0_bits_rfWen : (ohSel[21][1] ? io_fromRename_1_bits_rfWen : (ohSel[21][2] ? io_fromRename_2_bits_rfWen : (ohSel[21][3] ? io_fromRename_3_bits_rfWen : (ohSel[21][4] ? io_fromRename_4_bits_rfWen : io_fromRename_5_bits_rfWen)))));
  assign io_toIssueQueues_21_bits_selImm = (ohSel[21][0] ? io_fromRename_0_bits_selImm : (ohSel[21][1] ? io_fromRename_1_bits_selImm : (ohSel[21][2] ? io_fromRename_2_bits_selImm : (ohSel[21][3] ? io_fromRename_3_bits_selImm : (ohSel[21][4] ? io_fromRename_4_bits_selImm : io_fromRename_5_bits_selImm)))));
  assign io_toIssueQueues_21_bits_imm = (ohSel[21][0] ? io_fromRename_0_bits_imm : (ohSel[21][1] ? io_fromRename_1_bits_imm : (ohSel[21][2] ? io_fromRename_2_bits_imm : (ohSel[21][3] ? io_fromRename_3_bits_imm : (ohSel[21][4] ? io_fromRename_4_bits_imm : io_fromRename_5_bits_imm)))));
  assign io_toIssueQueues_21_bits_isDropAmocasSta = (ohSel[21][0] ? fru_isDropAmocasSta[0] : (ohSel[21][1] ? fru_isDropAmocasSta[1] : (ohSel[21][2] ? fru_isDropAmocasSta[2] : (ohSel[21][3] ? fru_isDropAmocasSta[3] : (ohSel[21][4] ? fru_isDropAmocasSta[4] : fru_isDropAmocasSta[5])))));
  assign io_toIssueQueues_21_bits_srcState_0 = (ohSel[21][0] ? (allSrcState[0][0][0]) : (ohSel[21][1] ? (allSrcState[1][0][0]) : (ohSel[21][2] ? (allSrcState[2][0][0]) : (ohSel[21][3] ? (allSrcState[3][0][0]) : (ohSel[21][4] ? (allSrcState[4][0][0]) : (allSrcState[5][0][0]))))));
  assign io_toIssueQueues_21_bits_srcState_1 = (ohSel[21][0] ? (allSrcState[0][1][0] | allSrcState[0][1][1]) : (ohSel[21][1] ? (allSrcState[1][1][0] | allSrcState[1][1][1]) : (ohSel[21][2] ? (allSrcState[2][1][0] | allSrcState[2][1][1]) : (ohSel[21][3] ? (allSrcState[3][1][0] | allSrcState[3][1][1]) : (ohSel[21][4] ? (allSrcState[4][1][0] | allSrcState[4][1][1]) : (allSrcState[5][1][0] | allSrcState[5][1][1]))))));
  assign io_toIssueQueues_21_bits_srcLoadDependency_0_0 = (ohSel[21][0] ? fru_srcLoadDep[0][0][0] : (ohSel[21][1] ? fru_srcLoadDep[1][0][0] : (ohSel[21][2] ? fru_srcLoadDep[2][0][0] : (ohSel[21][3] ? fru_srcLoadDep[3][0][0] : (ohSel[21][4] ? fru_srcLoadDep[4][0][0] : fru_srcLoadDep[5][0][0])))));
  assign io_toIssueQueues_21_bits_srcLoadDependency_0_1 = (ohSel[21][0] ? fru_srcLoadDep[0][0][1] : (ohSel[21][1] ? fru_srcLoadDep[1][0][1] : (ohSel[21][2] ? fru_srcLoadDep[2][0][1] : (ohSel[21][3] ? fru_srcLoadDep[3][0][1] : (ohSel[21][4] ? fru_srcLoadDep[4][0][1] : fru_srcLoadDep[5][0][1])))));
  assign io_toIssueQueues_21_bits_srcLoadDependency_0_2 = (ohSel[21][0] ? fru_srcLoadDep[0][0][2] : (ohSel[21][1] ? fru_srcLoadDep[1][0][2] : (ohSel[21][2] ? fru_srcLoadDep[2][0][2] : (ohSel[21][3] ? fru_srcLoadDep[3][0][2] : (ohSel[21][4] ? fru_srcLoadDep[4][0][2] : fru_srcLoadDep[5][0][2])))));
  assign io_toIssueQueues_21_bits_srcLoadDependency_1_0 = (ohSel[21][0] ? fru_srcLoadDep[0][1][0] : (ohSel[21][1] ? fru_srcLoadDep[1][1][0] : (ohSel[21][2] ? fru_srcLoadDep[2][1][0] : (ohSel[21][3] ? fru_srcLoadDep[3][1][0] : (ohSel[21][4] ? fru_srcLoadDep[4][1][0] : fru_srcLoadDep[5][1][0])))));
  assign io_toIssueQueues_21_bits_srcLoadDependency_1_1 = (ohSel[21][0] ? fru_srcLoadDep[0][1][1] : (ohSel[21][1] ? fru_srcLoadDep[1][1][1] : (ohSel[21][2] ? fru_srcLoadDep[2][1][1] : (ohSel[21][3] ? fru_srcLoadDep[3][1][1] : (ohSel[21][4] ? fru_srcLoadDep[4][1][1] : fru_srcLoadDep[5][1][1])))));
  assign io_toIssueQueues_21_bits_srcLoadDependency_1_2 = (ohSel[21][0] ? fru_srcLoadDep[0][1][2] : (ohSel[21][1] ? fru_srcLoadDep[1][1][2] : (ohSel[21][2] ? fru_srcLoadDep[2][1][2] : (ohSel[21][3] ? fru_srcLoadDep[3][1][2] : (ohSel[21][4] ? fru_srcLoadDep[4][1][2] : fru_srcLoadDep[5][1][2])))));
  assign io_toIssueQueues_21_bits_psrc_0 = (ohSel[21][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[21][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[21][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[21][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[21][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_21_bits_psrc_1 = (ohSel[21][0] ? io_fromRename_0_bits_psrc_1 : (ohSel[21][1] ? io_fromRename_1_bits_psrc_1 : (ohSel[21][2] ? io_fromRename_2_bits_psrc_1 : (ohSel[21][3] ? io_fromRename_3_bits_psrc_1 : (ohSel[21][4] ? io_fromRename_4_bits_psrc_1 : io_fromRename_5_bits_psrc_1)))));
  assign io_toIssueQueues_21_bits_pdest = (ohSel[21][0] ? io_fromRename_0_bits_pdest : (ohSel[21][1] ? io_fromRename_1_bits_pdest : (ohSel[21][2] ? io_fromRename_2_bits_pdest : (ohSel[21][3] ? io_fromRename_3_bits_pdest : (ohSel[21][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_21_bits_useRegCache_0 = (ohSel[21][0] ? _rcTagTable_io_readPorts_0_valid : (ohSel[21][1] ? _rcTagTable_io_readPorts_2_valid : (ohSel[21][2] ? _rcTagTable_io_readPorts_4_valid : (ohSel[21][3] ? _rcTagTable_io_readPorts_6_valid : (ohSel[21][4] ? _rcTagTable_io_readPorts_8_valid : _rcTagTable_io_readPorts_10_valid)))));
  assign io_toIssueQueues_21_bits_useRegCache_1 = (ohSel[21][0] ? _rcTagTable_io_readPorts_1_valid : (ohSel[21][1] ? _rcTagTable_io_readPorts_3_valid : (ohSel[21][2] ? _rcTagTable_io_readPorts_5_valid : (ohSel[21][3] ? _rcTagTable_io_readPorts_7_valid : (ohSel[21][4] ? _rcTagTable_io_readPorts_9_valid : _rcTagTable_io_readPorts_11_valid)))));
  assign io_toIssueQueues_21_bits_regCacheIdx_0 = (ohSel[21][0] ? _rcTagTable_io_readPorts_0_addr : (ohSel[21][1] ? _rcTagTable_io_readPorts_2_addr : (ohSel[21][2] ? _rcTagTable_io_readPorts_4_addr : (ohSel[21][3] ? _rcTagTable_io_readPorts_6_addr : (ohSel[21][4] ? _rcTagTable_io_readPorts_8_addr : _rcTagTable_io_readPorts_10_addr)))));
  assign io_toIssueQueues_21_bits_regCacheIdx_1 = (ohSel[21][0] ? _rcTagTable_io_readPorts_1_addr : (ohSel[21][1] ? _rcTagTable_io_readPorts_3_addr : (ohSel[21][2] ? _rcTagTable_io_readPorts_5_addr : (ohSel[21][3] ? _rcTagTable_io_readPorts_7_addr : (ohSel[21][4] ? _rcTagTable_io_readPorts_9_addr : _rcTagTable_io_readPorts_11_addr)))));
  assign io_toIssueQueues_21_bits_robIdx_flag = (ohSel[21][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[21][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[21][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[21][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[21][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_21_bits_robIdx_value = (ohSel[21][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[21][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[21][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[21][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[21][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  assign io_toIssueQueues_21_bits_sqIdx_flag = (ohSel[21][0] ? _lsqEnqCtrl_io_enq_resp_0_sqIdx_flag : (ohSel[21][1] ? _lsqEnqCtrl_io_enq_resp_1_sqIdx_flag : (ohSel[21][2] ? _lsqEnqCtrl_io_enq_resp_2_sqIdx_flag : (ohSel[21][3] ? _lsqEnqCtrl_io_enq_resp_3_sqIdx_flag : (ohSel[21][4] ? _lsqEnqCtrl_io_enq_resp_4_sqIdx_flag : _lsqEnqCtrl_io_enq_resp_5_sqIdx_flag)))));
  assign io_toIssueQueues_21_bits_sqIdx_value = (ohSel[21][0] ? _lsqEnqCtrl_io_enq_resp_0_sqIdx_value : (ohSel[21][1] ? _lsqEnqCtrl_io_enq_resp_1_sqIdx_value : (ohSel[21][2] ? _lsqEnqCtrl_io_enq_resp_2_sqIdx_value : (ohSel[21][3] ? _lsqEnqCtrl_io_enq_resp_3_sqIdx_value : (ohSel[21][4] ? _lsqEnqCtrl_io_enq_resp_4_sqIdx_value : _lsqEnqCtrl_io_enq_resp_5_sqIdx_value)))));
  // -- 端口 22(IQ 11 enq 0)--
  assign io_toIssueQueues_22_valid = (ohSel[22][0] ? fromRenameUpdate_valid[0] : (ohSel[22][1] ? fromRenameUpdate_valid[1] : (ohSel[22][2] ? fromRenameUpdate_valid[2] : (ohSel[22][3] ? fromRenameUpdate_valid[3] : (ohSel[22][4] ? fromRenameUpdate_valid[4] : (ohSel[22][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_22_bits_ftqPtr_value = (ohSel[22][0] ? io_fromRename_0_bits_ftqPtr_value : (ohSel[22][1] ? io_fromRename_1_bits_ftqPtr_value : (ohSel[22][2] ? io_fromRename_2_bits_ftqPtr_value : (ohSel[22][3] ? io_fromRename_3_bits_ftqPtr_value : (ohSel[22][4] ? io_fromRename_4_bits_ftqPtr_value : io_fromRename_5_bits_ftqPtr_value)))));
  assign io_toIssueQueues_22_bits_ftqOffset = (ohSel[22][0] ? io_fromRename_0_bits_ftqOffset : (ohSel[22][1] ? io_fromRename_1_bits_ftqOffset : (ohSel[22][2] ? io_fromRename_2_bits_ftqOffset : (ohSel[22][3] ? io_fromRename_3_bits_ftqOffset : (ohSel[22][4] ? io_fromRename_4_bits_ftqOffset : io_fromRename_5_bits_ftqOffset)))));
  assign io_toIssueQueues_22_bits_srcType_0 = (ohSel[22][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[22][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[22][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[22][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[22][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_22_bits_srcType_1 = (ohSel[22][0] ? io_fromRename_0_bits_srcType_1 : (ohSel[22][1] ? io_fromRename_1_bits_srcType_1 : (ohSel[22][2] ? io_fromRename_2_bits_srcType_1 : (ohSel[22][3] ? io_fromRename_3_bits_srcType_1 : (ohSel[22][4] ? io_fromRename_4_bits_srcType_1 : io_fromRename_5_bits_srcType_1)))));
  assign io_toIssueQueues_22_bits_fuType = (ohSel[22][0] ? io_fromRename_0_bits_fuType : (ohSel[22][1] ? io_fromRename_1_bits_fuType : (ohSel[22][2] ? io_fromRename_2_bits_fuType : (ohSel[22][3] ? io_fromRename_3_bits_fuType : (ohSel[22][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_22_bits_fuOpType = (ohSel[22][0] ? io_fromRename_0_bits_fuOpType : (ohSel[22][1] ? io_fromRename_1_bits_fuOpType : (ohSel[22][2] ? io_fromRename_2_bits_fuOpType : (ohSel[22][3] ? io_fromRename_3_bits_fuOpType : (ohSel[22][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_22_bits_rfWen = (ohSel[22][0] ? io_fromRename_0_bits_rfWen : (ohSel[22][1] ? io_fromRename_1_bits_rfWen : (ohSel[22][2] ? io_fromRename_2_bits_rfWen : (ohSel[22][3] ? io_fromRename_3_bits_rfWen : (ohSel[22][4] ? io_fromRename_4_bits_rfWen : io_fromRename_5_bits_rfWen)))));
  assign io_toIssueQueues_22_bits_selImm = (ohSel[22][0] ? io_fromRename_0_bits_selImm : (ohSel[22][1] ? io_fromRename_1_bits_selImm : (ohSel[22][2] ? io_fromRename_2_bits_selImm : (ohSel[22][3] ? io_fromRename_3_bits_selImm : (ohSel[22][4] ? io_fromRename_4_bits_selImm : io_fromRename_5_bits_selImm)))));
  assign io_toIssueQueues_22_bits_imm = (ohSel[22][0] ? io_fromRename_0_bits_imm : (ohSel[22][1] ? io_fromRename_1_bits_imm : (ohSel[22][2] ? io_fromRename_2_bits_imm : (ohSel[22][3] ? io_fromRename_3_bits_imm : (ohSel[22][4] ? io_fromRename_4_bits_imm : io_fromRename_5_bits_imm)))));
  assign io_toIssueQueues_22_bits_isDropAmocasSta = (ohSel[22][0] ? fru_isDropAmocasSta[0] : (ohSel[22][1] ? fru_isDropAmocasSta[1] : (ohSel[22][2] ? fru_isDropAmocasSta[2] : (ohSel[22][3] ? fru_isDropAmocasSta[3] : (ohSel[22][4] ? fru_isDropAmocasSta[4] : fru_isDropAmocasSta[5])))));
  assign io_toIssueQueues_22_bits_srcState_0 = (ohSel[22][0] ? (allSrcState[0][0][0]) : (ohSel[22][1] ? (allSrcState[1][0][0]) : (ohSel[22][2] ? (allSrcState[2][0][0]) : (ohSel[22][3] ? (allSrcState[3][0][0]) : (ohSel[22][4] ? (allSrcState[4][0][0]) : (allSrcState[5][0][0]))))));
  assign io_toIssueQueues_22_bits_srcState_1 = (ohSel[22][0] ? (allSrcState[0][1][0] | allSrcState[0][1][1]) : (ohSel[22][1] ? (allSrcState[1][1][0] | allSrcState[1][1][1]) : (ohSel[22][2] ? (allSrcState[2][1][0] | allSrcState[2][1][1]) : (ohSel[22][3] ? (allSrcState[3][1][0] | allSrcState[3][1][1]) : (ohSel[22][4] ? (allSrcState[4][1][0] | allSrcState[4][1][1]) : (allSrcState[5][1][0] | allSrcState[5][1][1]))))));
  assign io_toIssueQueues_22_bits_srcLoadDependency_0_0 = (ohSel[22][0] ? fru_srcLoadDep[0][0][0] : (ohSel[22][1] ? fru_srcLoadDep[1][0][0] : (ohSel[22][2] ? fru_srcLoadDep[2][0][0] : (ohSel[22][3] ? fru_srcLoadDep[3][0][0] : (ohSel[22][4] ? fru_srcLoadDep[4][0][0] : fru_srcLoadDep[5][0][0])))));
  assign io_toIssueQueues_22_bits_srcLoadDependency_0_1 = (ohSel[22][0] ? fru_srcLoadDep[0][0][1] : (ohSel[22][1] ? fru_srcLoadDep[1][0][1] : (ohSel[22][2] ? fru_srcLoadDep[2][0][1] : (ohSel[22][3] ? fru_srcLoadDep[3][0][1] : (ohSel[22][4] ? fru_srcLoadDep[4][0][1] : fru_srcLoadDep[5][0][1])))));
  assign io_toIssueQueues_22_bits_srcLoadDependency_0_2 = (ohSel[22][0] ? fru_srcLoadDep[0][0][2] : (ohSel[22][1] ? fru_srcLoadDep[1][0][2] : (ohSel[22][2] ? fru_srcLoadDep[2][0][2] : (ohSel[22][3] ? fru_srcLoadDep[3][0][2] : (ohSel[22][4] ? fru_srcLoadDep[4][0][2] : fru_srcLoadDep[5][0][2])))));
  assign io_toIssueQueues_22_bits_srcLoadDependency_1_0 = (ohSel[22][0] ? fru_srcLoadDep[0][1][0] : (ohSel[22][1] ? fru_srcLoadDep[1][1][0] : (ohSel[22][2] ? fru_srcLoadDep[2][1][0] : (ohSel[22][3] ? fru_srcLoadDep[3][1][0] : (ohSel[22][4] ? fru_srcLoadDep[4][1][0] : fru_srcLoadDep[5][1][0])))));
  assign io_toIssueQueues_22_bits_srcLoadDependency_1_1 = (ohSel[22][0] ? fru_srcLoadDep[0][1][1] : (ohSel[22][1] ? fru_srcLoadDep[1][1][1] : (ohSel[22][2] ? fru_srcLoadDep[2][1][1] : (ohSel[22][3] ? fru_srcLoadDep[3][1][1] : (ohSel[22][4] ? fru_srcLoadDep[4][1][1] : fru_srcLoadDep[5][1][1])))));
  assign io_toIssueQueues_22_bits_srcLoadDependency_1_2 = (ohSel[22][0] ? fru_srcLoadDep[0][1][2] : (ohSel[22][1] ? fru_srcLoadDep[1][1][2] : (ohSel[22][2] ? fru_srcLoadDep[2][1][2] : (ohSel[22][3] ? fru_srcLoadDep[3][1][2] : (ohSel[22][4] ? fru_srcLoadDep[4][1][2] : fru_srcLoadDep[5][1][2])))));
  assign io_toIssueQueues_22_bits_psrc_0 = (ohSel[22][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[22][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[22][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[22][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[22][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_22_bits_psrc_1 = (ohSel[22][0] ? io_fromRename_0_bits_psrc_1 : (ohSel[22][1] ? io_fromRename_1_bits_psrc_1 : (ohSel[22][2] ? io_fromRename_2_bits_psrc_1 : (ohSel[22][3] ? io_fromRename_3_bits_psrc_1 : (ohSel[22][4] ? io_fromRename_4_bits_psrc_1 : io_fromRename_5_bits_psrc_1)))));
  assign io_toIssueQueues_22_bits_pdest = (ohSel[22][0] ? io_fromRename_0_bits_pdest : (ohSel[22][1] ? io_fromRename_1_bits_pdest : (ohSel[22][2] ? io_fromRename_2_bits_pdest : (ohSel[22][3] ? io_fromRename_3_bits_pdest : (ohSel[22][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_22_bits_useRegCache_0 = (ohSel[22][0] ? _rcTagTable_io_readPorts_0_valid : (ohSel[22][1] ? _rcTagTable_io_readPorts_2_valid : (ohSel[22][2] ? _rcTagTable_io_readPorts_4_valid : (ohSel[22][3] ? _rcTagTable_io_readPorts_6_valid : (ohSel[22][4] ? _rcTagTable_io_readPorts_8_valid : _rcTagTable_io_readPorts_10_valid)))));
  assign io_toIssueQueues_22_bits_useRegCache_1 = (ohSel[22][0] ? _rcTagTable_io_readPorts_1_valid : (ohSel[22][1] ? _rcTagTable_io_readPorts_3_valid : (ohSel[22][2] ? _rcTagTable_io_readPorts_5_valid : (ohSel[22][3] ? _rcTagTable_io_readPorts_7_valid : (ohSel[22][4] ? _rcTagTable_io_readPorts_9_valid : _rcTagTable_io_readPorts_11_valid)))));
  assign io_toIssueQueues_22_bits_regCacheIdx_0 = (ohSel[22][0] ? _rcTagTable_io_readPorts_0_addr : (ohSel[22][1] ? _rcTagTable_io_readPorts_2_addr : (ohSel[22][2] ? _rcTagTable_io_readPorts_4_addr : (ohSel[22][3] ? _rcTagTable_io_readPorts_6_addr : (ohSel[22][4] ? _rcTagTable_io_readPorts_8_addr : _rcTagTable_io_readPorts_10_addr)))));
  assign io_toIssueQueues_22_bits_regCacheIdx_1 = (ohSel[22][0] ? _rcTagTable_io_readPorts_1_addr : (ohSel[22][1] ? _rcTagTable_io_readPorts_3_addr : (ohSel[22][2] ? _rcTagTable_io_readPorts_5_addr : (ohSel[22][3] ? _rcTagTable_io_readPorts_7_addr : (ohSel[22][4] ? _rcTagTable_io_readPorts_9_addr : _rcTagTable_io_readPorts_11_addr)))));
  assign io_toIssueQueues_22_bits_robIdx_flag = (ohSel[22][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[22][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[22][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[22][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[22][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_22_bits_robIdx_value = (ohSel[22][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[22][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[22][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[22][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[22][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  assign io_toIssueQueues_22_bits_sqIdx_flag = (ohSel[22][0] ? _lsqEnqCtrl_io_enq_resp_0_sqIdx_flag : (ohSel[22][1] ? _lsqEnqCtrl_io_enq_resp_1_sqIdx_flag : (ohSel[22][2] ? _lsqEnqCtrl_io_enq_resp_2_sqIdx_flag : (ohSel[22][3] ? _lsqEnqCtrl_io_enq_resp_3_sqIdx_flag : (ohSel[22][4] ? _lsqEnqCtrl_io_enq_resp_4_sqIdx_flag : _lsqEnqCtrl_io_enq_resp_5_sqIdx_flag)))));
  assign io_toIssueQueues_22_bits_sqIdx_value = (ohSel[22][0] ? _lsqEnqCtrl_io_enq_resp_0_sqIdx_value : (ohSel[22][1] ? _lsqEnqCtrl_io_enq_resp_1_sqIdx_value : (ohSel[22][2] ? _lsqEnqCtrl_io_enq_resp_2_sqIdx_value : (ohSel[22][3] ? _lsqEnqCtrl_io_enq_resp_3_sqIdx_value : (ohSel[22][4] ? _lsqEnqCtrl_io_enq_resp_4_sqIdx_value : _lsqEnqCtrl_io_enq_resp_5_sqIdx_value)))));
  // -- 端口 23(IQ 11 enq 1)--
  assign io_toIssueQueues_23_valid = (ohSel[23][0] ? fromRenameUpdate_valid[0] : (ohSel[23][1] ? fromRenameUpdate_valid[1] : (ohSel[23][2] ? fromRenameUpdate_valid[2] : (ohSel[23][3] ? fromRenameUpdate_valid[3] : (ohSel[23][4] ? fromRenameUpdate_valid[4] : (ohSel[23][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_23_bits_ftqPtr_value = (ohSel[23][0] ? io_fromRename_0_bits_ftqPtr_value : (ohSel[23][1] ? io_fromRename_1_bits_ftqPtr_value : (ohSel[23][2] ? io_fromRename_2_bits_ftqPtr_value : (ohSel[23][3] ? io_fromRename_3_bits_ftqPtr_value : (ohSel[23][4] ? io_fromRename_4_bits_ftqPtr_value : io_fromRename_5_bits_ftqPtr_value)))));
  assign io_toIssueQueues_23_bits_ftqOffset = (ohSel[23][0] ? io_fromRename_0_bits_ftqOffset : (ohSel[23][1] ? io_fromRename_1_bits_ftqOffset : (ohSel[23][2] ? io_fromRename_2_bits_ftqOffset : (ohSel[23][3] ? io_fromRename_3_bits_ftqOffset : (ohSel[23][4] ? io_fromRename_4_bits_ftqOffset : io_fromRename_5_bits_ftqOffset)))));
  assign io_toIssueQueues_23_bits_srcType_0 = (ohSel[23][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[23][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[23][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[23][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[23][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_23_bits_srcType_1 = (ohSel[23][0] ? io_fromRename_0_bits_srcType_1 : (ohSel[23][1] ? io_fromRename_1_bits_srcType_1 : (ohSel[23][2] ? io_fromRename_2_bits_srcType_1 : (ohSel[23][3] ? io_fromRename_3_bits_srcType_1 : (ohSel[23][4] ? io_fromRename_4_bits_srcType_1 : io_fromRename_5_bits_srcType_1)))));
  assign io_toIssueQueues_23_bits_fuType = (ohSel[23][0] ? io_fromRename_0_bits_fuType : (ohSel[23][1] ? io_fromRename_1_bits_fuType : (ohSel[23][2] ? io_fromRename_2_bits_fuType : (ohSel[23][3] ? io_fromRename_3_bits_fuType : (ohSel[23][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_23_bits_fuOpType = (ohSel[23][0] ? io_fromRename_0_bits_fuOpType : (ohSel[23][1] ? io_fromRename_1_bits_fuOpType : (ohSel[23][2] ? io_fromRename_2_bits_fuOpType : (ohSel[23][3] ? io_fromRename_3_bits_fuOpType : (ohSel[23][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_23_bits_rfWen = (ohSel[23][0] ? io_fromRename_0_bits_rfWen : (ohSel[23][1] ? io_fromRename_1_bits_rfWen : (ohSel[23][2] ? io_fromRename_2_bits_rfWen : (ohSel[23][3] ? io_fromRename_3_bits_rfWen : (ohSel[23][4] ? io_fromRename_4_bits_rfWen : io_fromRename_5_bits_rfWen)))));
  assign io_toIssueQueues_23_bits_selImm = (ohSel[23][0] ? io_fromRename_0_bits_selImm : (ohSel[23][1] ? io_fromRename_1_bits_selImm : (ohSel[23][2] ? io_fromRename_2_bits_selImm : (ohSel[23][3] ? io_fromRename_3_bits_selImm : (ohSel[23][4] ? io_fromRename_4_bits_selImm : io_fromRename_5_bits_selImm)))));
  assign io_toIssueQueues_23_bits_imm = (ohSel[23][0] ? io_fromRename_0_bits_imm : (ohSel[23][1] ? io_fromRename_1_bits_imm : (ohSel[23][2] ? io_fromRename_2_bits_imm : (ohSel[23][3] ? io_fromRename_3_bits_imm : (ohSel[23][4] ? io_fromRename_4_bits_imm : io_fromRename_5_bits_imm)))));
  assign io_toIssueQueues_23_bits_isDropAmocasSta = (ohSel[23][0] ? fru_isDropAmocasSta[0] : (ohSel[23][1] ? fru_isDropAmocasSta[1] : (ohSel[23][2] ? fru_isDropAmocasSta[2] : (ohSel[23][3] ? fru_isDropAmocasSta[3] : (ohSel[23][4] ? fru_isDropAmocasSta[4] : fru_isDropAmocasSta[5])))));
  assign io_toIssueQueues_23_bits_srcState_0 = (ohSel[23][0] ? (allSrcState[0][0][0]) : (ohSel[23][1] ? (allSrcState[1][0][0]) : (ohSel[23][2] ? (allSrcState[2][0][0]) : (ohSel[23][3] ? (allSrcState[3][0][0]) : (ohSel[23][4] ? (allSrcState[4][0][0]) : (allSrcState[5][0][0]))))));
  assign io_toIssueQueues_23_bits_srcState_1 = (ohSel[23][0] ? (allSrcState[0][1][0] | allSrcState[0][1][1]) : (ohSel[23][1] ? (allSrcState[1][1][0] | allSrcState[1][1][1]) : (ohSel[23][2] ? (allSrcState[2][1][0] | allSrcState[2][1][1]) : (ohSel[23][3] ? (allSrcState[3][1][0] | allSrcState[3][1][1]) : (ohSel[23][4] ? (allSrcState[4][1][0] | allSrcState[4][1][1]) : (allSrcState[5][1][0] | allSrcState[5][1][1]))))));
  assign io_toIssueQueues_23_bits_srcLoadDependency_0_0 = (ohSel[23][0] ? fru_srcLoadDep[0][0][0] : (ohSel[23][1] ? fru_srcLoadDep[1][0][0] : (ohSel[23][2] ? fru_srcLoadDep[2][0][0] : (ohSel[23][3] ? fru_srcLoadDep[3][0][0] : (ohSel[23][4] ? fru_srcLoadDep[4][0][0] : fru_srcLoadDep[5][0][0])))));
  assign io_toIssueQueues_23_bits_srcLoadDependency_0_1 = (ohSel[23][0] ? fru_srcLoadDep[0][0][1] : (ohSel[23][1] ? fru_srcLoadDep[1][0][1] : (ohSel[23][2] ? fru_srcLoadDep[2][0][1] : (ohSel[23][3] ? fru_srcLoadDep[3][0][1] : (ohSel[23][4] ? fru_srcLoadDep[4][0][1] : fru_srcLoadDep[5][0][1])))));
  assign io_toIssueQueues_23_bits_srcLoadDependency_0_2 = (ohSel[23][0] ? fru_srcLoadDep[0][0][2] : (ohSel[23][1] ? fru_srcLoadDep[1][0][2] : (ohSel[23][2] ? fru_srcLoadDep[2][0][2] : (ohSel[23][3] ? fru_srcLoadDep[3][0][2] : (ohSel[23][4] ? fru_srcLoadDep[4][0][2] : fru_srcLoadDep[5][0][2])))));
  assign io_toIssueQueues_23_bits_srcLoadDependency_1_0 = (ohSel[23][0] ? fru_srcLoadDep[0][1][0] : (ohSel[23][1] ? fru_srcLoadDep[1][1][0] : (ohSel[23][2] ? fru_srcLoadDep[2][1][0] : (ohSel[23][3] ? fru_srcLoadDep[3][1][0] : (ohSel[23][4] ? fru_srcLoadDep[4][1][0] : fru_srcLoadDep[5][1][0])))));
  assign io_toIssueQueues_23_bits_srcLoadDependency_1_1 = (ohSel[23][0] ? fru_srcLoadDep[0][1][1] : (ohSel[23][1] ? fru_srcLoadDep[1][1][1] : (ohSel[23][2] ? fru_srcLoadDep[2][1][1] : (ohSel[23][3] ? fru_srcLoadDep[3][1][1] : (ohSel[23][4] ? fru_srcLoadDep[4][1][1] : fru_srcLoadDep[5][1][1])))));
  assign io_toIssueQueues_23_bits_srcLoadDependency_1_2 = (ohSel[23][0] ? fru_srcLoadDep[0][1][2] : (ohSel[23][1] ? fru_srcLoadDep[1][1][2] : (ohSel[23][2] ? fru_srcLoadDep[2][1][2] : (ohSel[23][3] ? fru_srcLoadDep[3][1][2] : (ohSel[23][4] ? fru_srcLoadDep[4][1][2] : fru_srcLoadDep[5][1][2])))));
  assign io_toIssueQueues_23_bits_psrc_0 = (ohSel[23][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[23][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[23][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[23][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[23][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_23_bits_psrc_1 = (ohSel[23][0] ? io_fromRename_0_bits_psrc_1 : (ohSel[23][1] ? io_fromRename_1_bits_psrc_1 : (ohSel[23][2] ? io_fromRename_2_bits_psrc_1 : (ohSel[23][3] ? io_fromRename_3_bits_psrc_1 : (ohSel[23][4] ? io_fromRename_4_bits_psrc_1 : io_fromRename_5_bits_psrc_1)))));
  assign io_toIssueQueues_23_bits_pdest = (ohSel[23][0] ? io_fromRename_0_bits_pdest : (ohSel[23][1] ? io_fromRename_1_bits_pdest : (ohSel[23][2] ? io_fromRename_2_bits_pdest : (ohSel[23][3] ? io_fromRename_3_bits_pdest : (ohSel[23][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_23_bits_useRegCache_0 = (ohSel[23][0] ? _rcTagTable_io_readPorts_0_valid : (ohSel[23][1] ? _rcTagTable_io_readPorts_2_valid : (ohSel[23][2] ? _rcTagTable_io_readPorts_4_valid : (ohSel[23][3] ? _rcTagTable_io_readPorts_6_valid : (ohSel[23][4] ? _rcTagTable_io_readPorts_8_valid : _rcTagTable_io_readPorts_10_valid)))));
  assign io_toIssueQueues_23_bits_useRegCache_1 = (ohSel[23][0] ? _rcTagTable_io_readPorts_1_valid : (ohSel[23][1] ? _rcTagTable_io_readPorts_3_valid : (ohSel[23][2] ? _rcTagTable_io_readPorts_5_valid : (ohSel[23][3] ? _rcTagTable_io_readPorts_7_valid : (ohSel[23][4] ? _rcTagTable_io_readPorts_9_valid : _rcTagTable_io_readPorts_11_valid)))));
  assign io_toIssueQueues_23_bits_regCacheIdx_0 = (ohSel[23][0] ? _rcTagTable_io_readPorts_0_addr : (ohSel[23][1] ? _rcTagTable_io_readPorts_2_addr : (ohSel[23][2] ? _rcTagTable_io_readPorts_4_addr : (ohSel[23][3] ? _rcTagTable_io_readPorts_6_addr : (ohSel[23][4] ? _rcTagTable_io_readPorts_8_addr : _rcTagTable_io_readPorts_10_addr)))));
  assign io_toIssueQueues_23_bits_regCacheIdx_1 = (ohSel[23][0] ? _rcTagTable_io_readPorts_1_addr : (ohSel[23][1] ? _rcTagTable_io_readPorts_3_addr : (ohSel[23][2] ? _rcTagTable_io_readPorts_5_addr : (ohSel[23][3] ? _rcTagTable_io_readPorts_7_addr : (ohSel[23][4] ? _rcTagTable_io_readPorts_9_addr : _rcTagTable_io_readPorts_11_addr)))));
  assign io_toIssueQueues_23_bits_robIdx_flag = (ohSel[23][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[23][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[23][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[23][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[23][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_23_bits_robIdx_value = (ohSel[23][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[23][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[23][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[23][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[23][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  assign io_toIssueQueues_23_bits_sqIdx_flag = (ohSel[23][0] ? _lsqEnqCtrl_io_enq_resp_0_sqIdx_flag : (ohSel[23][1] ? _lsqEnqCtrl_io_enq_resp_1_sqIdx_flag : (ohSel[23][2] ? _lsqEnqCtrl_io_enq_resp_2_sqIdx_flag : (ohSel[23][3] ? _lsqEnqCtrl_io_enq_resp_3_sqIdx_flag : (ohSel[23][4] ? _lsqEnqCtrl_io_enq_resp_4_sqIdx_flag : _lsqEnqCtrl_io_enq_resp_5_sqIdx_flag)))));
  assign io_toIssueQueues_23_bits_sqIdx_value = (ohSel[23][0] ? _lsqEnqCtrl_io_enq_resp_0_sqIdx_value : (ohSel[23][1] ? _lsqEnqCtrl_io_enq_resp_1_sqIdx_value : (ohSel[23][2] ? _lsqEnqCtrl_io_enq_resp_2_sqIdx_value : (ohSel[23][3] ? _lsqEnqCtrl_io_enq_resp_3_sqIdx_value : (ohSel[23][4] ? _lsqEnqCtrl_io_enq_resp_4_sqIdx_value : _lsqEnqCtrl_io_enq_resp_5_sqIdx_value)))));
  // -- 端口 24(IQ 12 enq 0)--
  assign io_toIssueQueues_24_valid = (ohSel[24][0] ? fromRenameUpdate_valid[0] : (ohSel[24][1] ? fromRenameUpdate_valid[1] : (ohSel[24][2] ? fromRenameUpdate_valid[2] : (ohSel[24][3] ? fromRenameUpdate_valid[3] : (ohSel[24][4] ? fromRenameUpdate_valid[4] : (ohSel[24][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_24_bits_preDecodeInfo_isRVC = (ohSel[24][0] ? io_fromRename_0_bits_preDecodeInfo_isRVC : (ohSel[24][1] ? io_fromRename_1_bits_preDecodeInfo_isRVC : (ohSel[24][2] ? io_fromRename_2_bits_preDecodeInfo_isRVC : (ohSel[24][3] ? io_fromRename_3_bits_preDecodeInfo_isRVC : (ohSel[24][4] ? io_fromRename_4_bits_preDecodeInfo_isRVC : io_fromRename_5_bits_preDecodeInfo_isRVC)))));
  assign io_toIssueQueues_24_bits_ftqPtr_flag = (ohSel[24][0] ? io_fromRename_0_bits_ftqPtr_flag : (ohSel[24][1] ? io_fromRename_1_bits_ftqPtr_flag : (ohSel[24][2] ? io_fromRename_2_bits_ftqPtr_flag : (ohSel[24][3] ? io_fromRename_3_bits_ftqPtr_flag : (ohSel[24][4] ? io_fromRename_4_bits_ftqPtr_flag : io_fromRename_5_bits_ftqPtr_flag)))));
  assign io_toIssueQueues_24_bits_ftqPtr_value = (ohSel[24][0] ? io_fromRename_0_bits_ftqPtr_value : (ohSel[24][1] ? io_fromRename_1_bits_ftqPtr_value : (ohSel[24][2] ? io_fromRename_2_bits_ftqPtr_value : (ohSel[24][3] ? io_fromRename_3_bits_ftqPtr_value : (ohSel[24][4] ? io_fromRename_4_bits_ftqPtr_value : io_fromRename_5_bits_ftqPtr_value)))));
  assign io_toIssueQueues_24_bits_ftqOffset = (ohSel[24][0] ? io_fromRename_0_bits_ftqOffset : (ohSel[24][1] ? io_fromRename_1_bits_ftqOffset : (ohSel[24][2] ? io_fromRename_2_bits_ftqOffset : (ohSel[24][3] ? io_fromRename_3_bits_ftqOffset : (ohSel[24][4] ? io_fromRename_4_bits_ftqOffset : io_fromRename_5_bits_ftqOffset)))));
  assign io_toIssueQueues_24_bits_srcType_0 = (ohSel[24][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[24][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[24][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[24][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[24][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_24_bits_fuType = (ohSel[24][0] ? io_fromRename_0_bits_fuType : (ohSel[24][1] ? io_fromRename_1_bits_fuType : (ohSel[24][2] ? io_fromRename_2_bits_fuType : (ohSel[24][3] ? io_fromRename_3_bits_fuType : (ohSel[24][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_24_bits_fuOpType = (ohSel[24][0] ? io_fromRename_0_bits_fuOpType : (ohSel[24][1] ? io_fromRename_1_bits_fuOpType : (ohSel[24][2] ? io_fromRename_2_bits_fuOpType : (ohSel[24][3] ? io_fromRename_3_bits_fuOpType : (ohSel[24][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_24_bits_rfWen = (ohSel[24][0] ? io_fromRename_0_bits_rfWen : (ohSel[24][1] ? io_fromRename_1_bits_rfWen : (ohSel[24][2] ? io_fromRename_2_bits_rfWen : (ohSel[24][3] ? io_fromRename_3_bits_rfWen : (ohSel[24][4] ? io_fromRename_4_bits_rfWen : io_fromRename_5_bits_rfWen)))));
  assign io_toIssueQueues_24_bits_fpWen = (ohSel[24][0] ? io_fromRename_0_bits_fpWen : (ohSel[24][1] ? io_fromRename_1_bits_fpWen : (ohSel[24][2] ? io_fromRename_2_bits_fpWen : (ohSel[24][3] ? io_fromRename_3_bits_fpWen : (ohSel[24][4] ? io_fromRename_4_bits_fpWen : io_fromRename_5_bits_fpWen)))));
  assign io_toIssueQueues_24_bits_imm = (ohSel[24][0] ? io_fromRename_0_bits_imm : (ohSel[24][1] ? io_fromRename_1_bits_imm : (ohSel[24][2] ? io_fromRename_2_bits_imm : (ohSel[24][3] ? io_fromRename_3_bits_imm : (ohSel[24][4] ? io_fromRename_4_bits_imm : io_fromRename_5_bits_imm)))));
  assign io_toIssueQueues_24_bits_srcState_0 = (ohSel[24][0] ? (allSrcState[0][0][0]) : (ohSel[24][1] ? (allSrcState[1][0][0]) : (ohSel[24][2] ? (allSrcState[2][0][0]) : (ohSel[24][3] ? (allSrcState[3][0][0]) : (ohSel[24][4] ? (allSrcState[4][0][0]) : (allSrcState[5][0][0]))))));
  assign io_toIssueQueues_24_bits_srcLoadDependency_0_0 = (ohSel[24][0] ? fru_srcLoadDep[0][0][0] : (ohSel[24][1] ? fru_srcLoadDep[1][0][0] : (ohSel[24][2] ? fru_srcLoadDep[2][0][0] : (ohSel[24][3] ? fru_srcLoadDep[3][0][0] : (ohSel[24][4] ? fru_srcLoadDep[4][0][0] : fru_srcLoadDep[5][0][0])))));
  assign io_toIssueQueues_24_bits_srcLoadDependency_0_1 = (ohSel[24][0] ? fru_srcLoadDep[0][0][1] : (ohSel[24][1] ? fru_srcLoadDep[1][0][1] : (ohSel[24][2] ? fru_srcLoadDep[2][0][1] : (ohSel[24][3] ? fru_srcLoadDep[3][0][1] : (ohSel[24][4] ? fru_srcLoadDep[4][0][1] : fru_srcLoadDep[5][0][1])))));
  assign io_toIssueQueues_24_bits_srcLoadDependency_0_2 = (ohSel[24][0] ? fru_srcLoadDep[0][0][2] : (ohSel[24][1] ? fru_srcLoadDep[1][0][2] : (ohSel[24][2] ? fru_srcLoadDep[2][0][2] : (ohSel[24][3] ? fru_srcLoadDep[3][0][2] : (ohSel[24][4] ? fru_srcLoadDep[4][0][2] : fru_srcLoadDep[5][0][2])))));
  assign io_toIssueQueues_24_bits_psrc_0 = (ohSel[24][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[24][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[24][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[24][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[24][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_24_bits_pdest = (ohSel[24][0] ? io_fromRename_0_bits_pdest : (ohSel[24][1] ? io_fromRename_1_bits_pdest : (ohSel[24][2] ? io_fromRename_2_bits_pdest : (ohSel[24][3] ? io_fromRename_3_bits_pdest : (ohSel[24][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_24_bits_useRegCache_0 = (ohSel[24][0] ? _rcTagTable_io_readPorts_0_valid : (ohSel[24][1] ? _rcTagTable_io_readPorts_2_valid : (ohSel[24][2] ? _rcTagTable_io_readPorts_4_valid : (ohSel[24][3] ? _rcTagTable_io_readPorts_6_valid : (ohSel[24][4] ? _rcTagTable_io_readPorts_8_valid : _rcTagTable_io_readPorts_10_valid)))));
  assign io_toIssueQueues_24_bits_regCacheIdx_0 = (ohSel[24][0] ? _rcTagTable_io_readPorts_0_addr : (ohSel[24][1] ? _rcTagTable_io_readPorts_2_addr : (ohSel[24][2] ? _rcTagTable_io_readPorts_4_addr : (ohSel[24][3] ? _rcTagTable_io_readPorts_6_addr : (ohSel[24][4] ? _rcTagTable_io_readPorts_8_addr : _rcTagTable_io_readPorts_10_addr)))));
  assign io_toIssueQueues_24_bits_robIdx_flag = (ohSel[24][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[24][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[24][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[24][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[24][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_24_bits_robIdx_value = (ohSel[24][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[24][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[24][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[24][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[24][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  assign io_toIssueQueues_24_bits_lqIdx_flag = (ohSel[24][0] ? _lsqEnqCtrl_io_enq_resp_0_lqIdx_flag : (ohSel[24][1] ? _lsqEnqCtrl_io_enq_resp_1_lqIdx_flag : (ohSel[24][2] ? _lsqEnqCtrl_io_enq_resp_2_lqIdx_flag : (ohSel[24][3] ? _lsqEnqCtrl_io_enq_resp_3_lqIdx_flag : (ohSel[24][4] ? _lsqEnqCtrl_io_enq_resp_4_lqIdx_flag : _lsqEnqCtrl_io_enq_resp_5_lqIdx_flag)))));
  assign io_toIssueQueues_24_bits_lqIdx_value = (ohSel[24][0] ? _lsqEnqCtrl_io_enq_resp_0_lqIdx_value : (ohSel[24][1] ? _lsqEnqCtrl_io_enq_resp_1_lqIdx_value : (ohSel[24][2] ? _lsqEnqCtrl_io_enq_resp_2_lqIdx_value : (ohSel[24][3] ? _lsqEnqCtrl_io_enq_resp_3_lqIdx_value : (ohSel[24][4] ? _lsqEnqCtrl_io_enq_resp_4_lqIdx_value : _lsqEnqCtrl_io_enq_resp_5_lqIdx_value)))));
  assign io_toIssueQueues_24_bits_sqIdx_flag = (ohSel[24][0] ? _lsqEnqCtrl_io_enq_resp_0_sqIdx_flag : (ohSel[24][1] ? _lsqEnqCtrl_io_enq_resp_1_sqIdx_flag : (ohSel[24][2] ? _lsqEnqCtrl_io_enq_resp_2_sqIdx_flag : (ohSel[24][3] ? _lsqEnqCtrl_io_enq_resp_3_sqIdx_flag : (ohSel[24][4] ? _lsqEnqCtrl_io_enq_resp_4_sqIdx_flag : _lsqEnqCtrl_io_enq_resp_5_sqIdx_flag)))));
  assign io_toIssueQueues_24_bits_sqIdx_value = (ohSel[24][0] ? _lsqEnqCtrl_io_enq_resp_0_sqIdx_value : (ohSel[24][1] ? _lsqEnqCtrl_io_enq_resp_1_sqIdx_value : (ohSel[24][2] ? _lsqEnqCtrl_io_enq_resp_2_sqIdx_value : (ohSel[24][3] ? _lsqEnqCtrl_io_enq_resp_3_sqIdx_value : (ohSel[24][4] ? _lsqEnqCtrl_io_enq_resp_4_sqIdx_value : _lsqEnqCtrl_io_enq_resp_5_sqIdx_value)))));
  // -- 端口 25(IQ 12 enq 1)--
  assign io_toIssueQueues_25_valid = (ohSel[25][0] ? fromRenameUpdate_valid[0] : (ohSel[25][1] ? fromRenameUpdate_valid[1] : (ohSel[25][2] ? fromRenameUpdate_valid[2] : (ohSel[25][3] ? fromRenameUpdate_valid[3] : (ohSel[25][4] ? fromRenameUpdate_valid[4] : (ohSel[25][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_25_bits_preDecodeInfo_isRVC = (ohSel[25][0] ? io_fromRename_0_bits_preDecodeInfo_isRVC : (ohSel[25][1] ? io_fromRename_1_bits_preDecodeInfo_isRVC : (ohSel[25][2] ? io_fromRename_2_bits_preDecodeInfo_isRVC : (ohSel[25][3] ? io_fromRename_3_bits_preDecodeInfo_isRVC : (ohSel[25][4] ? io_fromRename_4_bits_preDecodeInfo_isRVC : io_fromRename_5_bits_preDecodeInfo_isRVC)))));
  assign io_toIssueQueues_25_bits_ftqPtr_flag = (ohSel[25][0] ? io_fromRename_0_bits_ftqPtr_flag : (ohSel[25][1] ? io_fromRename_1_bits_ftqPtr_flag : (ohSel[25][2] ? io_fromRename_2_bits_ftqPtr_flag : (ohSel[25][3] ? io_fromRename_3_bits_ftqPtr_flag : (ohSel[25][4] ? io_fromRename_4_bits_ftqPtr_flag : io_fromRename_5_bits_ftqPtr_flag)))));
  assign io_toIssueQueues_25_bits_ftqPtr_value = (ohSel[25][0] ? io_fromRename_0_bits_ftqPtr_value : (ohSel[25][1] ? io_fromRename_1_bits_ftqPtr_value : (ohSel[25][2] ? io_fromRename_2_bits_ftqPtr_value : (ohSel[25][3] ? io_fromRename_3_bits_ftqPtr_value : (ohSel[25][4] ? io_fromRename_4_bits_ftqPtr_value : io_fromRename_5_bits_ftqPtr_value)))));
  assign io_toIssueQueues_25_bits_ftqOffset = (ohSel[25][0] ? io_fromRename_0_bits_ftqOffset : (ohSel[25][1] ? io_fromRename_1_bits_ftqOffset : (ohSel[25][2] ? io_fromRename_2_bits_ftqOffset : (ohSel[25][3] ? io_fromRename_3_bits_ftqOffset : (ohSel[25][4] ? io_fromRename_4_bits_ftqOffset : io_fromRename_5_bits_ftqOffset)))));
  assign io_toIssueQueues_25_bits_srcType_0 = (ohSel[25][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[25][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[25][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[25][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[25][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_25_bits_fuType = (ohSel[25][0] ? io_fromRename_0_bits_fuType : (ohSel[25][1] ? io_fromRename_1_bits_fuType : (ohSel[25][2] ? io_fromRename_2_bits_fuType : (ohSel[25][3] ? io_fromRename_3_bits_fuType : (ohSel[25][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_25_bits_fuOpType = (ohSel[25][0] ? io_fromRename_0_bits_fuOpType : (ohSel[25][1] ? io_fromRename_1_bits_fuOpType : (ohSel[25][2] ? io_fromRename_2_bits_fuOpType : (ohSel[25][3] ? io_fromRename_3_bits_fuOpType : (ohSel[25][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_25_bits_rfWen = (ohSel[25][0] ? io_fromRename_0_bits_rfWen : (ohSel[25][1] ? io_fromRename_1_bits_rfWen : (ohSel[25][2] ? io_fromRename_2_bits_rfWen : (ohSel[25][3] ? io_fromRename_3_bits_rfWen : (ohSel[25][4] ? io_fromRename_4_bits_rfWen : io_fromRename_5_bits_rfWen)))));
  assign io_toIssueQueues_25_bits_fpWen = (ohSel[25][0] ? io_fromRename_0_bits_fpWen : (ohSel[25][1] ? io_fromRename_1_bits_fpWen : (ohSel[25][2] ? io_fromRename_2_bits_fpWen : (ohSel[25][3] ? io_fromRename_3_bits_fpWen : (ohSel[25][4] ? io_fromRename_4_bits_fpWen : io_fromRename_5_bits_fpWen)))));
  assign io_toIssueQueues_25_bits_imm = (ohSel[25][0] ? io_fromRename_0_bits_imm : (ohSel[25][1] ? io_fromRename_1_bits_imm : (ohSel[25][2] ? io_fromRename_2_bits_imm : (ohSel[25][3] ? io_fromRename_3_bits_imm : (ohSel[25][4] ? io_fromRename_4_bits_imm : io_fromRename_5_bits_imm)))));
  assign io_toIssueQueues_25_bits_srcState_0 = (ohSel[25][0] ? (allSrcState[0][0][0]) : (ohSel[25][1] ? (allSrcState[1][0][0]) : (ohSel[25][2] ? (allSrcState[2][0][0]) : (ohSel[25][3] ? (allSrcState[3][0][0]) : (ohSel[25][4] ? (allSrcState[4][0][0]) : (allSrcState[5][0][0]))))));
  assign io_toIssueQueues_25_bits_srcLoadDependency_0_0 = (ohSel[25][0] ? fru_srcLoadDep[0][0][0] : (ohSel[25][1] ? fru_srcLoadDep[1][0][0] : (ohSel[25][2] ? fru_srcLoadDep[2][0][0] : (ohSel[25][3] ? fru_srcLoadDep[3][0][0] : (ohSel[25][4] ? fru_srcLoadDep[4][0][0] : fru_srcLoadDep[5][0][0])))));
  assign io_toIssueQueues_25_bits_srcLoadDependency_0_1 = (ohSel[25][0] ? fru_srcLoadDep[0][0][1] : (ohSel[25][1] ? fru_srcLoadDep[1][0][1] : (ohSel[25][2] ? fru_srcLoadDep[2][0][1] : (ohSel[25][3] ? fru_srcLoadDep[3][0][1] : (ohSel[25][4] ? fru_srcLoadDep[4][0][1] : fru_srcLoadDep[5][0][1])))));
  assign io_toIssueQueues_25_bits_srcLoadDependency_0_2 = (ohSel[25][0] ? fru_srcLoadDep[0][0][2] : (ohSel[25][1] ? fru_srcLoadDep[1][0][2] : (ohSel[25][2] ? fru_srcLoadDep[2][0][2] : (ohSel[25][3] ? fru_srcLoadDep[3][0][2] : (ohSel[25][4] ? fru_srcLoadDep[4][0][2] : fru_srcLoadDep[5][0][2])))));
  assign io_toIssueQueues_25_bits_psrc_0 = (ohSel[25][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[25][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[25][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[25][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[25][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_25_bits_pdest = (ohSel[25][0] ? io_fromRename_0_bits_pdest : (ohSel[25][1] ? io_fromRename_1_bits_pdest : (ohSel[25][2] ? io_fromRename_2_bits_pdest : (ohSel[25][3] ? io_fromRename_3_bits_pdest : (ohSel[25][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_25_bits_useRegCache_0 = (ohSel[25][0] ? _rcTagTable_io_readPorts_0_valid : (ohSel[25][1] ? _rcTagTable_io_readPorts_2_valid : (ohSel[25][2] ? _rcTagTable_io_readPorts_4_valid : (ohSel[25][3] ? _rcTagTable_io_readPorts_6_valid : (ohSel[25][4] ? _rcTagTable_io_readPorts_8_valid : _rcTagTable_io_readPorts_10_valid)))));
  assign io_toIssueQueues_25_bits_regCacheIdx_0 = (ohSel[25][0] ? _rcTagTable_io_readPorts_0_addr : (ohSel[25][1] ? _rcTagTable_io_readPorts_2_addr : (ohSel[25][2] ? _rcTagTable_io_readPorts_4_addr : (ohSel[25][3] ? _rcTagTable_io_readPorts_6_addr : (ohSel[25][4] ? _rcTagTable_io_readPorts_8_addr : _rcTagTable_io_readPorts_10_addr)))));
  assign io_toIssueQueues_25_bits_robIdx_flag = (ohSel[25][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[25][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[25][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[25][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[25][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_25_bits_robIdx_value = (ohSel[25][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[25][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[25][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[25][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[25][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  assign io_toIssueQueues_25_bits_lqIdx_flag = (ohSel[25][0] ? _lsqEnqCtrl_io_enq_resp_0_lqIdx_flag : (ohSel[25][1] ? _lsqEnqCtrl_io_enq_resp_1_lqIdx_flag : (ohSel[25][2] ? _lsqEnqCtrl_io_enq_resp_2_lqIdx_flag : (ohSel[25][3] ? _lsqEnqCtrl_io_enq_resp_3_lqIdx_flag : (ohSel[25][4] ? _lsqEnqCtrl_io_enq_resp_4_lqIdx_flag : _lsqEnqCtrl_io_enq_resp_5_lqIdx_flag)))));
  assign io_toIssueQueues_25_bits_lqIdx_value = (ohSel[25][0] ? _lsqEnqCtrl_io_enq_resp_0_lqIdx_value : (ohSel[25][1] ? _lsqEnqCtrl_io_enq_resp_1_lqIdx_value : (ohSel[25][2] ? _lsqEnqCtrl_io_enq_resp_2_lqIdx_value : (ohSel[25][3] ? _lsqEnqCtrl_io_enq_resp_3_lqIdx_value : (ohSel[25][4] ? _lsqEnqCtrl_io_enq_resp_4_lqIdx_value : _lsqEnqCtrl_io_enq_resp_5_lqIdx_value)))));
  assign io_toIssueQueues_25_bits_sqIdx_flag = (ohSel[25][0] ? _lsqEnqCtrl_io_enq_resp_0_sqIdx_flag : (ohSel[25][1] ? _lsqEnqCtrl_io_enq_resp_1_sqIdx_flag : (ohSel[25][2] ? _lsqEnqCtrl_io_enq_resp_2_sqIdx_flag : (ohSel[25][3] ? _lsqEnqCtrl_io_enq_resp_3_sqIdx_flag : (ohSel[25][4] ? _lsqEnqCtrl_io_enq_resp_4_sqIdx_flag : _lsqEnqCtrl_io_enq_resp_5_sqIdx_flag)))));
  assign io_toIssueQueues_25_bits_sqIdx_value = (ohSel[25][0] ? _lsqEnqCtrl_io_enq_resp_0_sqIdx_value : (ohSel[25][1] ? _lsqEnqCtrl_io_enq_resp_1_sqIdx_value : (ohSel[25][2] ? _lsqEnqCtrl_io_enq_resp_2_sqIdx_value : (ohSel[25][3] ? _lsqEnqCtrl_io_enq_resp_3_sqIdx_value : (ohSel[25][4] ? _lsqEnqCtrl_io_enq_resp_4_sqIdx_value : _lsqEnqCtrl_io_enq_resp_5_sqIdx_value)))));
  // -- 端口 26(IQ 13 enq 0)--
  assign io_toIssueQueues_26_valid = (ohSel[26][0] ? fromRenameUpdate_valid[0] : (ohSel[26][1] ? fromRenameUpdate_valid[1] : (ohSel[26][2] ? fromRenameUpdate_valid[2] : (ohSel[26][3] ? fromRenameUpdate_valid[3] : (ohSel[26][4] ? fromRenameUpdate_valid[4] : (ohSel[26][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_26_bits_preDecodeInfo_isRVC = (ohSel[26][0] ? io_fromRename_0_bits_preDecodeInfo_isRVC : (ohSel[26][1] ? io_fromRename_1_bits_preDecodeInfo_isRVC : (ohSel[26][2] ? io_fromRename_2_bits_preDecodeInfo_isRVC : (ohSel[26][3] ? io_fromRename_3_bits_preDecodeInfo_isRVC : (ohSel[26][4] ? io_fromRename_4_bits_preDecodeInfo_isRVC : io_fromRename_5_bits_preDecodeInfo_isRVC)))));
  assign io_toIssueQueues_26_bits_ftqPtr_flag = (ohSel[26][0] ? io_fromRename_0_bits_ftqPtr_flag : (ohSel[26][1] ? io_fromRename_1_bits_ftqPtr_flag : (ohSel[26][2] ? io_fromRename_2_bits_ftqPtr_flag : (ohSel[26][3] ? io_fromRename_3_bits_ftqPtr_flag : (ohSel[26][4] ? io_fromRename_4_bits_ftqPtr_flag : io_fromRename_5_bits_ftqPtr_flag)))));
  assign io_toIssueQueues_26_bits_ftqPtr_value = (ohSel[26][0] ? io_fromRename_0_bits_ftqPtr_value : (ohSel[26][1] ? io_fromRename_1_bits_ftqPtr_value : (ohSel[26][2] ? io_fromRename_2_bits_ftqPtr_value : (ohSel[26][3] ? io_fromRename_3_bits_ftqPtr_value : (ohSel[26][4] ? io_fromRename_4_bits_ftqPtr_value : io_fromRename_5_bits_ftqPtr_value)))));
  assign io_toIssueQueues_26_bits_ftqOffset = (ohSel[26][0] ? io_fromRename_0_bits_ftqOffset : (ohSel[26][1] ? io_fromRename_1_bits_ftqOffset : (ohSel[26][2] ? io_fromRename_2_bits_ftqOffset : (ohSel[26][3] ? io_fromRename_3_bits_ftqOffset : (ohSel[26][4] ? io_fromRename_4_bits_ftqOffset : io_fromRename_5_bits_ftqOffset)))));
  assign io_toIssueQueues_26_bits_srcType_0 = (ohSel[26][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[26][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[26][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[26][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[26][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_26_bits_fuType = (ohSel[26][0] ? io_fromRename_0_bits_fuType : (ohSel[26][1] ? io_fromRename_1_bits_fuType : (ohSel[26][2] ? io_fromRename_2_bits_fuType : (ohSel[26][3] ? io_fromRename_3_bits_fuType : (ohSel[26][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_26_bits_fuOpType = (ohSel[26][0] ? io_fromRename_0_bits_fuOpType : (ohSel[26][1] ? io_fromRename_1_bits_fuOpType : (ohSel[26][2] ? io_fromRename_2_bits_fuOpType : (ohSel[26][3] ? io_fromRename_3_bits_fuOpType : (ohSel[26][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_26_bits_rfWen = (ohSel[26][0] ? io_fromRename_0_bits_rfWen : (ohSel[26][1] ? io_fromRename_1_bits_rfWen : (ohSel[26][2] ? io_fromRename_2_bits_rfWen : (ohSel[26][3] ? io_fromRename_3_bits_rfWen : (ohSel[26][4] ? io_fromRename_4_bits_rfWen : io_fromRename_5_bits_rfWen)))));
  assign io_toIssueQueues_26_bits_fpWen = (ohSel[26][0] ? io_fromRename_0_bits_fpWen : (ohSel[26][1] ? io_fromRename_1_bits_fpWen : (ohSel[26][2] ? io_fromRename_2_bits_fpWen : (ohSel[26][3] ? io_fromRename_3_bits_fpWen : (ohSel[26][4] ? io_fromRename_4_bits_fpWen : io_fromRename_5_bits_fpWen)))));
  assign io_toIssueQueues_26_bits_imm = (ohSel[26][0] ? io_fromRename_0_bits_imm : (ohSel[26][1] ? io_fromRename_1_bits_imm : (ohSel[26][2] ? io_fromRename_2_bits_imm : (ohSel[26][3] ? io_fromRename_3_bits_imm : (ohSel[26][4] ? io_fromRename_4_bits_imm : io_fromRename_5_bits_imm)))));
  assign io_toIssueQueues_26_bits_srcState_0 = (ohSel[26][0] ? (allSrcState[0][0][0]) : (ohSel[26][1] ? (allSrcState[1][0][0]) : (ohSel[26][2] ? (allSrcState[2][0][0]) : (ohSel[26][3] ? (allSrcState[3][0][0]) : (ohSel[26][4] ? (allSrcState[4][0][0]) : (allSrcState[5][0][0]))))));
  assign io_toIssueQueues_26_bits_srcLoadDependency_0_0 = (ohSel[26][0] ? fru_srcLoadDep[0][0][0] : (ohSel[26][1] ? fru_srcLoadDep[1][0][0] : (ohSel[26][2] ? fru_srcLoadDep[2][0][0] : (ohSel[26][3] ? fru_srcLoadDep[3][0][0] : (ohSel[26][4] ? fru_srcLoadDep[4][0][0] : fru_srcLoadDep[5][0][0])))));
  assign io_toIssueQueues_26_bits_srcLoadDependency_0_1 = (ohSel[26][0] ? fru_srcLoadDep[0][0][1] : (ohSel[26][1] ? fru_srcLoadDep[1][0][1] : (ohSel[26][2] ? fru_srcLoadDep[2][0][1] : (ohSel[26][3] ? fru_srcLoadDep[3][0][1] : (ohSel[26][4] ? fru_srcLoadDep[4][0][1] : fru_srcLoadDep[5][0][1])))));
  assign io_toIssueQueues_26_bits_srcLoadDependency_0_2 = (ohSel[26][0] ? fru_srcLoadDep[0][0][2] : (ohSel[26][1] ? fru_srcLoadDep[1][0][2] : (ohSel[26][2] ? fru_srcLoadDep[2][0][2] : (ohSel[26][3] ? fru_srcLoadDep[3][0][2] : (ohSel[26][4] ? fru_srcLoadDep[4][0][2] : fru_srcLoadDep[5][0][2])))));
  assign io_toIssueQueues_26_bits_psrc_0 = (ohSel[26][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[26][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[26][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[26][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[26][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_26_bits_pdest = (ohSel[26][0] ? io_fromRename_0_bits_pdest : (ohSel[26][1] ? io_fromRename_1_bits_pdest : (ohSel[26][2] ? io_fromRename_2_bits_pdest : (ohSel[26][3] ? io_fromRename_3_bits_pdest : (ohSel[26][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_26_bits_useRegCache_0 = (ohSel[26][0] ? _rcTagTable_io_readPorts_0_valid : (ohSel[26][1] ? _rcTagTable_io_readPorts_2_valid : (ohSel[26][2] ? _rcTagTable_io_readPorts_4_valid : (ohSel[26][3] ? _rcTagTable_io_readPorts_6_valid : (ohSel[26][4] ? _rcTagTable_io_readPorts_8_valid : _rcTagTable_io_readPorts_10_valid)))));
  assign io_toIssueQueues_26_bits_regCacheIdx_0 = (ohSel[26][0] ? _rcTagTable_io_readPorts_0_addr : (ohSel[26][1] ? _rcTagTable_io_readPorts_2_addr : (ohSel[26][2] ? _rcTagTable_io_readPorts_4_addr : (ohSel[26][3] ? _rcTagTable_io_readPorts_6_addr : (ohSel[26][4] ? _rcTagTable_io_readPorts_8_addr : _rcTagTable_io_readPorts_10_addr)))));
  assign io_toIssueQueues_26_bits_robIdx_flag = (ohSel[26][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[26][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[26][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[26][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[26][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_26_bits_robIdx_value = (ohSel[26][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[26][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[26][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[26][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[26][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  assign io_toIssueQueues_26_bits_lqIdx_flag = (ohSel[26][0] ? _lsqEnqCtrl_io_enq_resp_0_lqIdx_flag : (ohSel[26][1] ? _lsqEnqCtrl_io_enq_resp_1_lqIdx_flag : (ohSel[26][2] ? _lsqEnqCtrl_io_enq_resp_2_lqIdx_flag : (ohSel[26][3] ? _lsqEnqCtrl_io_enq_resp_3_lqIdx_flag : (ohSel[26][4] ? _lsqEnqCtrl_io_enq_resp_4_lqIdx_flag : _lsqEnqCtrl_io_enq_resp_5_lqIdx_flag)))));
  assign io_toIssueQueues_26_bits_lqIdx_value = (ohSel[26][0] ? _lsqEnqCtrl_io_enq_resp_0_lqIdx_value : (ohSel[26][1] ? _lsqEnqCtrl_io_enq_resp_1_lqIdx_value : (ohSel[26][2] ? _lsqEnqCtrl_io_enq_resp_2_lqIdx_value : (ohSel[26][3] ? _lsqEnqCtrl_io_enq_resp_3_lqIdx_value : (ohSel[26][4] ? _lsqEnqCtrl_io_enq_resp_4_lqIdx_value : _lsqEnqCtrl_io_enq_resp_5_lqIdx_value)))));
  assign io_toIssueQueues_26_bits_sqIdx_flag = (ohSel[26][0] ? _lsqEnqCtrl_io_enq_resp_0_sqIdx_flag : (ohSel[26][1] ? _lsqEnqCtrl_io_enq_resp_1_sqIdx_flag : (ohSel[26][2] ? _lsqEnqCtrl_io_enq_resp_2_sqIdx_flag : (ohSel[26][3] ? _lsqEnqCtrl_io_enq_resp_3_sqIdx_flag : (ohSel[26][4] ? _lsqEnqCtrl_io_enq_resp_4_sqIdx_flag : _lsqEnqCtrl_io_enq_resp_5_sqIdx_flag)))));
  assign io_toIssueQueues_26_bits_sqIdx_value = (ohSel[26][0] ? _lsqEnqCtrl_io_enq_resp_0_sqIdx_value : (ohSel[26][1] ? _lsqEnqCtrl_io_enq_resp_1_sqIdx_value : (ohSel[26][2] ? _lsqEnqCtrl_io_enq_resp_2_sqIdx_value : (ohSel[26][3] ? _lsqEnqCtrl_io_enq_resp_3_sqIdx_value : (ohSel[26][4] ? _lsqEnqCtrl_io_enq_resp_4_sqIdx_value : _lsqEnqCtrl_io_enq_resp_5_sqIdx_value)))));
  // -- 端口 27(IQ 13 enq 1)--
  assign io_toIssueQueues_27_valid = (ohSel[27][0] ? fromRenameUpdate_valid[0] : (ohSel[27][1] ? fromRenameUpdate_valid[1] : (ohSel[27][2] ? fromRenameUpdate_valid[2] : (ohSel[27][3] ? fromRenameUpdate_valid[3] : (ohSel[27][4] ? fromRenameUpdate_valid[4] : (ohSel[27][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_27_bits_preDecodeInfo_isRVC = (ohSel[27][0] ? io_fromRename_0_bits_preDecodeInfo_isRVC : (ohSel[27][1] ? io_fromRename_1_bits_preDecodeInfo_isRVC : (ohSel[27][2] ? io_fromRename_2_bits_preDecodeInfo_isRVC : (ohSel[27][3] ? io_fromRename_3_bits_preDecodeInfo_isRVC : (ohSel[27][4] ? io_fromRename_4_bits_preDecodeInfo_isRVC : io_fromRename_5_bits_preDecodeInfo_isRVC)))));
  assign io_toIssueQueues_27_bits_ftqPtr_flag = (ohSel[27][0] ? io_fromRename_0_bits_ftqPtr_flag : (ohSel[27][1] ? io_fromRename_1_bits_ftqPtr_flag : (ohSel[27][2] ? io_fromRename_2_bits_ftqPtr_flag : (ohSel[27][3] ? io_fromRename_3_bits_ftqPtr_flag : (ohSel[27][4] ? io_fromRename_4_bits_ftqPtr_flag : io_fromRename_5_bits_ftqPtr_flag)))));
  assign io_toIssueQueues_27_bits_ftqPtr_value = (ohSel[27][0] ? io_fromRename_0_bits_ftqPtr_value : (ohSel[27][1] ? io_fromRename_1_bits_ftqPtr_value : (ohSel[27][2] ? io_fromRename_2_bits_ftqPtr_value : (ohSel[27][3] ? io_fromRename_3_bits_ftqPtr_value : (ohSel[27][4] ? io_fromRename_4_bits_ftqPtr_value : io_fromRename_5_bits_ftqPtr_value)))));
  assign io_toIssueQueues_27_bits_ftqOffset = (ohSel[27][0] ? io_fromRename_0_bits_ftqOffset : (ohSel[27][1] ? io_fromRename_1_bits_ftqOffset : (ohSel[27][2] ? io_fromRename_2_bits_ftqOffset : (ohSel[27][3] ? io_fromRename_3_bits_ftqOffset : (ohSel[27][4] ? io_fromRename_4_bits_ftqOffset : io_fromRename_5_bits_ftqOffset)))));
  assign io_toIssueQueues_27_bits_srcType_0 = (ohSel[27][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[27][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[27][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[27][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[27][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_27_bits_fuType = (ohSel[27][0] ? io_fromRename_0_bits_fuType : (ohSel[27][1] ? io_fromRename_1_bits_fuType : (ohSel[27][2] ? io_fromRename_2_bits_fuType : (ohSel[27][3] ? io_fromRename_3_bits_fuType : (ohSel[27][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_27_bits_fuOpType = (ohSel[27][0] ? io_fromRename_0_bits_fuOpType : (ohSel[27][1] ? io_fromRename_1_bits_fuOpType : (ohSel[27][2] ? io_fromRename_2_bits_fuOpType : (ohSel[27][3] ? io_fromRename_3_bits_fuOpType : (ohSel[27][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_27_bits_rfWen = (ohSel[27][0] ? io_fromRename_0_bits_rfWen : (ohSel[27][1] ? io_fromRename_1_bits_rfWen : (ohSel[27][2] ? io_fromRename_2_bits_rfWen : (ohSel[27][3] ? io_fromRename_3_bits_rfWen : (ohSel[27][4] ? io_fromRename_4_bits_rfWen : io_fromRename_5_bits_rfWen)))));
  assign io_toIssueQueues_27_bits_fpWen = (ohSel[27][0] ? io_fromRename_0_bits_fpWen : (ohSel[27][1] ? io_fromRename_1_bits_fpWen : (ohSel[27][2] ? io_fromRename_2_bits_fpWen : (ohSel[27][3] ? io_fromRename_3_bits_fpWen : (ohSel[27][4] ? io_fromRename_4_bits_fpWen : io_fromRename_5_bits_fpWen)))));
  assign io_toIssueQueues_27_bits_imm = (ohSel[27][0] ? io_fromRename_0_bits_imm : (ohSel[27][1] ? io_fromRename_1_bits_imm : (ohSel[27][2] ? io_fromRename_2_bits_imm : (ohSel[27][3] ? io_fromRename_3_bits_imm : (ohSel[27][4] ? io_fromRename_4_bits_imm : io_fromRename_5_bits_imm)))));
  assign io_toIssueQueues_27_bits_srcState_0 = (ohSel[27][0] ? (allSrcState[0][0][0]) : (ohSel[27][1] ? (allSrcState[1][0][0]) : (ohSel[27][2] ? (allSrcState[2][0][0]) : (ohSel[27][3] ? (allSrcState[3][0][0]) : (ohSel[27][4] ? (allSrcState[4][0][0]) : (allSrcState[5][0][0]))))));
  assign io_toIssueQueues_27_bits_srcLoadDependency_0_0 = (ohSel[27][0] ? fru_srcLoadDep[0][0][0] : (ohSel[27][1] ? fru_srcLoadDep[1][0][0] : (ohSel[27][2] ? fru_srcLoadDep[2][0][0] : (ohSel[27][3] ? fru_srcLoadDep[3][0][0] : (ohSel[27][4] ? fru_srcLoadDep[4][0][0] : fru_srcLoadDep[5][0][0])))));
  assign io_toIssueQueues_27_bits_srcLoadDependency_0_1 = (ohSel[27][0] ? fru_srcLoadDep[0][0][1] : (ohSel[27][1] ? fru_srcLoadDep[1][0][1] : (ohSel[27][2] ? fru_srcLoadDep[2][0][1] : (ohSel[27][3] ? fru_srcLoadDep[3][0][1] : (ohSel[27][4] ? fru_srcLoadDep[4][0][1] : fru_srcLoadDep[5][0][1])))));
  assign io_toIssueQueues_27_bits_srcLoadDependency_0_2 = (ohSel[27][0] ? fru_srcLoadDep[0][0][2] : (ohSel[27][1] ? fru_srcLoadDep[1][0][2] : (ohSel[27][2] ? fru_srcLoadDep[2][0][2] : (ohSel[27][3] ? fru_srcLoadDep[3][0][2] : (ohSel[27][4] ? fru_srcLoadDep[4][0][2] : fru_srcLoadDep[5][0][2])))));
  assign io_toIssueQueues_27_bits_psrc_0 = (ohSel[27][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[27][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[27][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[27][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[27][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_27_bits_pdest = (ohSel[27][0] ? io_fromRename_0_bits_pdest : (ohSel[27][1] ? io_fromRename_1_bits_pdest : (ohSel[27][2] ? io_fromRename_2_bits_pdest : (ohSel[27][3] ? io_fromRename_3_bits_pdest : (ohSel[27][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_27_bits_useRegCache_0 = (ohSel[27][0] ? _rcTagTable_io_readPorts_0_valid : (ohSel[27][1] ? _rcTagTable_io_readPorts_2_valid : (ohSel[27][2] ? _rcTagTable_io_readPorts_4_valid : (ohSel[27][3] ? _rcTagTable_io_readPorts_6_valid : (ohSel[27][4] ? _rcTagTable_io_readPorts_8_valid : _rcTagTable_io_readPorts_10_valid)))));
  assign io_toIssueQueues_27_bits_regCacheIdx_0 = (ohSel[27][0] ? _rcTagTable_io_readPorts_0_addr : (ohSel[27][1] ? _rcTagTable_io_readPorts_2_addr : (ohSel[27][2] ? _rcTagTable_io_readPorts_4_addr : (ohSel[27][3] ? _rcTagTable_io_readPorts_6_addr : (ohSel[27][4] ? _rcTagTable_io_readPorts_8_addr : _rcTagTable_io_readPorts_10_addr)))));
  assign io_toIssueQueues_27_bits_robIdx_flag = (ohSel[27][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[27][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[27][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[27][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[27][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_27_bits_robIdx_value = (ohSel[27][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[27][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[27][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[27][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[27][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  assign io_toIssueQueues_27_bits_lqIdx_flag = (ohSel[27][0] ? _lsqEnqCtrl_io_enq_resp_0_lqIdx_flag : (ohSel[27][1] ? _lsqEnqCtrl_io_enq_resp_1_lqIdx_flag : (ohSel[27][2] ? _lsqEnqCtrl_io_enq_resp_2_lqIdx_flag : (ohSel[27][3] ? _lsqEnqCtrl_io_enq_resp_3_lqIdx_flag : (ohSel[27][4] ? _lsqEnqCtrl_io_enq_resp_4_lqIdx_flag : _lsqEnqCtrl_io_enq_resp_5_lqIdx_flag)))));
  assign io_toIssueQueues_27_bits_lqIdx_value = (ohSel[27][0] ? _lsqEnqCtrl_io_enq_resp_0_lqIdx_value : (ohSel[27][1] ? _lsqEnqCtrl_io_enq_resp_1_lqIdx_value : (ohSel[27][2] ? _lsqEnqCtrl_io_enq_resp_2_lqIdx_value : (ohSel[27][3] ? _lsqEnqCtrl_io_enq_resp_3_lqIdx_value : (ohSel[27][4] ? _lsqEnqCtrl_io_enq_resp_4_lqIdx_value : _lsqEnqCtrl_io_enq_resp_5_lqIdx_value)))));
  assign io_toIssueQueues_27_bits_sqIdx_flag = (ohSel[27][0] ? _lsqEnqCtrl_io_enq_resp_0_sqIdx_flag : (ohSel[27][1] ? _lsqEnqCtrl_io_enq_resp_1_sqIdx_flag : (ohSel[27][2] ? _lsqEnqCtrl_io_enq_resp_2_sqIdx_flag : (ohSel[27][3] ? _lsqEnqCtrl_io_enq_resp_3_sqIdx_flag : (ohSel[27][4] ? _lsqEnqCtrl_io_enq_resp_4_sqIdx_flag : _lsqEnqCtrl_io_enq_resp_5_sqIdx_flag)))));
  assign io_toIssueQueues_27_bits_sqIdx_value = (ohSel[27][0] ? _lsqEnqCtrl_io_enq_resp_0_sqIdx_value : (ohSel[27][1] ? _lsqEnqCtrl_io_enq_resp_1_sqIdx_value : (ohSel[27][2] ? _lsqEnqCtrl_io_enq_resp_2_sqIdx_value : (ohSel[27][3] ? _lsqEnqCtrl_io_enq_resp_3_sqIdx_value : (ohSel[27][4] ? _lsqEnqCtrl_io_enq_resp_4_sqIdx_value : _lsqEnqCtrl_io_enq_resp_5_sqIdx_value)))));
  // -- 端口 28(IQ 14 enq 0)--
  assign io_toIssueQueues_28_valid = (ohSel[28][0] ? fromRenameUpdate_valid[0] : (ohSel[28][1] ? fromRenameUpdate_valid[1] : (ohSel[28][2] ? fromRenameUpdate_valid[2] : (ohSel[28][3] ? fromRenameUpdate_valid[3] : (ohSel[28][4] ? fromRenameUpdate_valid[4] : (ohSel[28][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_28_bits_preDecodeInfo_isRVC = (ohSel[28][0] ? io_fromRename_0_bits_preDecodeInfo_isRVC : (ohSel[28][1] ? io_fromRename_1_bits_preDecodeInfo_isRVC : (ohSel[28][2] ? io_fromRename_2_bits_preDecodeInfo_isRVC : (ohSel[28][3] ? io_fromRename_3_bits_preDecodeInfo_isRVC : (ohSel[28][4] ? io_fromRename_4_bits_preDecodeInfo_isRVC : io_fromRename_5_bits_preDecodeInfo_isRVC)))));
  assign io_toIssueQueues_28_bits_ftqPtr_flag = (ohSel[28][0] ? io_fromRename_0_bits_ftqPtr_flag : (ohSel[28][1] ? io_fromRename_1_bits_ftqPtr_flag : (ohSel[28][2] ? io_fromRename_2_bits_ftqPtr_flag : (ohSel[28][3] ? io_fromRename_3_bits_ftqPtr_flag : (ohSel[28][4] ? io_fromRename_4_bits_ftqPtr_flag : io_fromRename_5_bits_ftqPtr_flag)))));
  assign io_toIssueQueues_28_bits_ftqPtr_value = (ohSel[28][0] ? io_fromRename_0_bits_ftqPtr_value : (ohSel[28][1] ? io_fromRename_1_bits_ftqPtr_value : (ohSel[28][2] ? io_fromRename_2_bits_ftqPtr_value : (ohSel[28][3] ? io_fromRename_3_bits_ftqPtr_value : (ohSel[28][4] ? io_fromRename_4_bits_ftqPtr_value : io_fromRename_5_bits_ftqPtr_value)))));
  assign io_toIssueQueues_28_bits_ftqOffset = (ohSel[28][0] ? io_fromRename_0_bits_ftqOffset : (ohSel[28][1] ? io_fromRename_1_bits_ftqOffset : (ohSel[28][2] ? io_fromRename_2_bits_ftqOffset : (ohSel[28][3] ? io_fromRename_3_bits_ftqOffset : (ohSel[28][4] ? io_fromRename_4_bits_ftqOffset : io_fromRename_5_bits_ftqOffset)))));
  assign io_toIssueQueues_28_bits_srcType_0 = (ohSel[28][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[28][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[28][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[28][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[28][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_28_bits_fuType = (ohSel[28][0] ? io_fromRename_0_bits_fuType : (ohSel[28][1] ? io_fromRename_1_bits_fuType : (ohSel[28][2] ? io_fromRename_2_bits_fuType : (ohSel[28][3] ? io_fromRename_3_bits_fuType : (ohSel[28][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_28_bits_fuOpType = (ohSel[28][0] ? io_fromRename_0_bits_fuOpType : (ohSel[28][1] ? io_fromRename_1_bits_fuOpType : (ohSel[28][2] ? io_fromRename_2_bits_fuOpType : (ohSel[28][3] ? io_fromRename_3_bits_fuOpType : (ohSel[28][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_28_bits_rfWen = (ohSel[28][0] ? io_fromRename_0_bits_rfWen : (ohSel[28][1] ? io_fromRename_1_bits_rfWen : (ohSel[28][2] ? io_fromRename_2_bits_rfWen : (ohSel[28][3] ? io_fromRename_3_bits_rfWen : (ohSel[28][4] ? io_fromRename_4_bits_rfWen : io_fromRename_5_bits_rfWen)))));
  assign io_toIssueQueues_28_bits_fpWen = (ohSel[28][0] ? io_fromRename_0_bits_fpWen : (ohSel[28][1] ? io_fromRename_1_bits_fpWen : (ohSel[28][2] ? io_fromRename_2_bits_fpWen : (ohSel[28][3] ? io_fromRename_3_bits_fpWen : (ohSel[28][4] ? io_fromRename_4_bits_fpWen : io_fromRename_5_bits_fpWen)))));
  assign io_toIssueQueues_28_bits_imm = (ohSel[28][0] ? io_fromRename_0_bits_imm : (ohSel[28][1] ? io_fromRename_1_bits_imm : (ohSel[28][2] ? io_fromRename_2_bits_imm : (ohSel[28][3] ? io_fromRename_3_bits_imm : (ohSel[28][4] ? io_fromRename_4_bits_imm : io_fromRename_5_bits_imm)))));
  assign io_toIssueQueues_28_bits_srcState_0 = (ohSel[28][0] ? (allSrcState[0][0][0]) : (ohSel[28][1] ? (allSrcState[1][0][0]) : (ohSel[28][2] ? (allSrcState[2][0][0]) : (ohSel[28][3] ? (allSrcState[3][0][0]) : (ohSel[28][4] ? (allSrcState[4][0][0]) : (allSrcState[5][0][0]))))));
  assign io_toIssueQueues_28_bits_srcLoadDependency_0_0 = (ohSel[28][0] ? fru_srcLoadDep[0][0][0] : (ohSel[28][1] ? fru_srcLoadDep[1][0][0] : (ohSel[28][2] ? fru_srcLoadDep[2][0][0] : (ohSel[28][3] ? fru_srcLoadDep[3][0][0] : (ohSel[28][4] ? fru_srcLoadDep[4][0][0] : fru_srcLoadDep[5][0][0])))));
  assign io_toIssueQueues_28_bits_srcLoadDependency_0_1 = (ohSel[28][0] ? fru_srcLoadDep[0][0][1] : (ohSel[28][1] ? fru_srcLoadDep[1][0][1] : (ohSel[28][2] ? fru_srcLoadDep[2][0][1] : (ohSel[28][3] ? fru_srcLoadDep[3][0][1] : (ohSel[28][4] ? fru_srcLoadDep[4][0][1] : fru_srcLoadDep[5][0][1])))));
  assign io_toIssueQueues_28_bits_srcLoadDependency_0_2 = (ohSel[28][0] ? fru_srcLoadDep[0][0][2] : (ohSel[28][1] ? fru_srcLoadDep[1][0][2] : (ohSel[28][2] ? fru_srcLoadDep[2][0][2] : (ohSel[28][3] ? fru_srcLoadDep[3][0][2] : (ohSel[28][4] ? fru_srcLoadDep[4][0][2] : fru_srcLoadDep[5][0][2])))));
  assign io_toIssueQueues_28_bits_psrc_0 = (ohSel[28][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[28][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[28][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[28][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[28][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_28_bits_pdest = (ohSel[28][0] ? io_fromRename_0_bits_pdest : (ohSel[28][1] ? io_fromRename_1_bits_pdest : (ohSel[28][2] ? io_fromRename_2_bits_pdest : (ohSel[28][3] ? io_fromRename_3_bits_pdest : (ohSel[28][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_28_bits_useRegCache_0 = (ohSel[28][0] ? _rcTagTable_io_readPorts_0_valid : (ohSel[28][1] ? _rcTagTable_io_readPorts_2_valid : (ohSel[28][2] ? _rcTagTable_io_readPorts_4_valid : (ohSel[28][3] ? _rcTagTable_io_readPorts_6_valid : (ohSel[28][4] ? _rcTagTable_io_readPorts_8_valid : _rcTagTable_io_readPorts_10_valid)))));
  assign io_toIssueQueues_28_bits_regCacheIdx_0 = (ohSel[28][0] ? _rcTagTable_io_readPorts_0_addr : (ohSel[28][1] ? _rcTagTable_io_readPorts_2_addr : (ohSel[28][2] ? _rcTagTable_io_readPorts_4_addr : (ohSel[28][3] ? _rcTagTable_io_readPorts_6_addr : (ohSel[28][4] ? _rcTagTable_io_readPorts_8_addr : _rcTagTable_io_readPorts_10_addr)))));
  assign io_toIssueQueues_28_bits_robIdx_flag = (ohSel[28][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[28][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[28][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[28][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[28][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_28_bits_robIdx_value = (ohSel[28][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[28][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[28][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[28][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[28][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  assign io_toIssueQueues_28_bits_lqIdx_flag = (ohSel[28][0] ? _lsqEnqCtrl_io_enq_resp_0_lqIdx_flag : (ohSel[28][1] ? _lsqEnqCtrl_io_enq_resp_1_lqIdx_flag : (ohSel[28][2] ? _lsqEnqCtrl_io_enq_resp_2_lqIdx_flag : (ohSel[28][3] ? _lsqEnqCtrl_io_enq_resp_3_lqIdx_flag : (ohSel[28][4] ? _lsqEnqCtrl_io_enq_resp_4_lqIdx_flag : _lsqEnqCtrl_io_enq_resp_5_lqIdx_flag)))));
  assign io_toIssueQueues_28_bits_lqIdx_value = (ohSel[28][0] ? _lsqEnqCtrl_io_enq_resp_0_lqIdx_value : (ohSel[28][1] ? _lsqEnqCtrl_io_enq_resp_1_lqIdx_value : (ohSel[28][2] ? _lsqEnqCtrl_io_enq_resp_2_lqIdx_value : (ohSel[28][3] ? _lsqEnqCtrl_io_enq_resp_3_lqIdx_value : (ohSel[28][4] ? _lsqEnqCtrl_io_enq_resp_4_lqIdx_value : _lsqEnqCtrl_io_enq_resp_5_lqIdx_value)))));
  assign io_toIssueQueues_28_bits_sqIdx_flag = (ohSel[28][0] ? _lsqEnqCtrl_io_enq_resp_0_sqIdx_flag : (ohSel[28][1] ? _lsqEnqCtrl_io_enq_resp_1_sqIdx_flag : (ohSel[28][2] ? _lsqEnqCtrl_io_enq_resp_2_sqIdx_flag : (ohSel[28][3] ? _lsqEnqCtrl_io_enq_resp_3_sqIdx_flag : (ohSel[28][4] ? _lsqEnqCtrl_io_enq_resp_4_sqIdx_flag : _lsqEnqCtrl_io_enq_resp_5_sqIdx_flag)))));
  assign io_toIssueQueues_28_bits_sqIdx_value = (ohSel[28][0] ? _lsqEnqCtrl_io_enq_resp_0_sqIdx_value : (ohSel[28][1] ? _lsqEnqCtrl_io_enq_resp_1_sqIdx_value : (ohSel[28][2] ? _lsqEnqCtrl_io_enq_resp_2_sqIdx_value : (ohSel[28][3] ? _lsqEnqCtrl_io_enq_resp_3_sqIdx_value : (ohSel[28][4] ? _lsqEnqCtrl_io_enq_resp_4_sqIdx_value : _lsqEnqCtrl_io_enq_resp_5_sqIdx_value)))));
  // -- 端口 29(IQ 14 enq 1)--
  assign io_toIssueQueues_29_valid = (ohSel[29][0] ? fromRenameUpdate_valid[0] : (ohSel[29][1] ? fromRenameUpdate_valid[1] : (ohSel[29][2] ? fromRenameUpdate_valid[2] : (ohSel[29][3] ? fromRenameUpdate_valid[3] : (ohSel[29][4] ? fromRenameUpdate_valid[4] : (ohSel[29][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_29_bits_preDecodeInfo_isRVC = (ohSel[29][0] ? io_fromRename_0_bits_preDecodeInfo_isRVC : (ohSel[29][1] ? io_fromRename_1_bits_preDecodeInfo_isRVC : (ohSel[29][2] ? io_fromRename_2_bits_preDecodeInfo_isRVC : (ohSel[29][3] ? io_fromRename_3_bits_preDecodeInfo_isRVC : (ohSel[29][4] ? io_fromRename_4_bits_preDecodeInfo_isRVC : io_fromRename_5_bits_preDecodeInfo_isRVC)))));
  assign io_toIssueQueues_29_bits_ftqPtr_flag = (ohSel[29][0] ? io_fromRename_0_bits_ftqPtr_flag : (ohSel[29][1] ? io_fromRename_1_bits_ftqPtr_flag : (ohSel[29][2] ? io_fromRename_2_bits_ftqPtr_flag : (ohSel[29][3] ? io_fromRename_3_bits_ftqPtr_flag : (ohSel[29][4] ? io_fromRename_4_bits_ftqPtr_flag : io_fromRename_5_bits_ftqPtr_flag)))));
  assign io_toIssueQueues_29_bits_ftqPtr_value = (ohSel[29][0] ? io_fromRename_0_bits_ftqPtr_value : (ohSel[29][1] ? io_fromRename_1_bits_ftqPtr_value : (ohSel[29][2] ? io_fromRename_2_bits_ftqPtr_value : (ohSel[29][3] ? io_fromRename_3_bits_ftqPtr_value : (ohSel[29][4] ? io_fromRename_4_bits_ftqPtr_value : io_fromRename_5_bits_ftqPtr_value)))));
  assign io_toIssueQueues_29_bits_ftqOffset = (ohSel[29][0] ? io_fromRename_0_bits_ftqOffset : (ohSel[29][1] ? io_fromRename_1_bits_ftqOffset : (ohSel[29][2] ? io_fromRename_2_bits_ftqOffset : (ohSel[29][3] ? io_fromRename_3_bits_ftqOffset : (ohSel[29][4] ? io_fromRename_4_bits_ftqOffset : io_fromRename_5_bits_ftqOffset)))));
  assign io_toIssueQueues_29_bits_srcType_0 = (ohSel[29][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[29][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[29][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[29][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[29][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_29_bits_fuType = (ohSel[29][0] ? io_fromRename_0_bits_fuType : (ohSel[29][1] ? io_fromRename_1_bits_fuType : (ohSel[29][2] ? io_fromRename_2_bits_fuType : (ohSel[29][3] ? io_fromRename_3_bits_fuType : (ohSel[29][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_29_bits_fuOpType = (ohSel[29][0] ? io_fromRename_0_bits_fuOpType : (ohSel[29][1] ? io_fromRename_1_bits_fuOpType : (ohSel[29][2] ? io_fromRename_2_bits_fuOpType : (ohSel[29][3] ? io_fromRename_3_bits_fuOpType : (ohSel[29][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_29_bits_rfWen = (ohSel[29][0] ? io_fromRename_0_bits_rfWen : (ohSel[29][1] ? io_fromRename_1_bits_rfWen : (ohSel[29][2] ? io_fromRename_2_bits_rfWen : (ohSel[29][3] ? io_fromRename_3_bits_rfWen : (ohSel[29][4] ? io_fromRename_4_bits_rfWen : io_fromRename_5_bits_rfWen)))));
  assign io_toIssueQueues_29_bits_fpWen = (ohSel[29][0] ? io_fromRename_0_bits_fpWen : (ohSel[29][1] ? io_fromRename_1_bits_fpWen : (ohSel[29][2] ? io_fromRename_2_bits_fpWen : (ohSel[29][3] ? io_fromRename_3_bits_fpWen : (ohSel[29][4] ? io_fromRename_4_bits_fpWen : io_fromRename_5_bits_fpWen)))));
  assign io_toIssueQueues_29_bits_imm = (ohSel[29][0] ? io_fromRename_0_bits_imm : (ohSel[29][1] ? io_fromRename_1_bits_imm : (ohSel[29][2] ? io_fromRename_2_bits_imm : (ohSel[29][3] ? io_fromRename_3_bits_imm : (ohSel[29][4] ? io_fromRename_4_bits_imm : io_fromRename_5_bits_imm)))));
  assign io_toIssueQueues_29_bits_srcState_0 = (ohSel[29][0] ? (allSrcState[0][0][0]) : (ohSel[29][1] ? (allSrcState[1][0][0]) : (ohSel[29][2] ? (allSrcState[2][0][0]) : (ohSel[29][3] ? (allSrcState[3][0][0]) : (ohSel[29][4] ? (allSrcState[4][0][0]) : (allSrcState[5][0][0]))))));
  assign io_toIssueQueues_29_bits_srcLoadDependency_0_0 = (ohSel[29][0] ? fru_srcLoadDep[0][0][0] : (ohSel[29][1] ? fru_srcLoadDep[1][0][0] : (ohSel[29][2] ? fru_srcLoadDep[2][0][0] : (ohSel[29][3] ? fru_srcLoadDep[3][0][0] : (ohSel[29][4] ? fru_srcLoadDep[4][0][0] : fru_srcLoadDep[5][0][0])))));
  assign io_toIssueQueues_29_bits_srcLoadDependency_0_1 = (ohSel[29][0] ? fru_srcLoadDep[0][0][1] : (ohSel[29][1] ? fru_srcLoadDep[1][0][1] : (ohSel[29][2] ? fru_srcLoadDep[2][0][1] : (ohSel[29][3] ? fru_srcLoadDep[3][0][1] : (ohSel[29][4] ? fru_srcLoadDep[4][0][1] : fru_srcLoadDep[5][0][1])))));
  assign io_toIssueQueues_29_bits_srcLoadDependency_0_2 = (ohSel[29][0] ? fru_srcLoadDep[0][0][2] : (ohSel[29][1] ? fru_srcLoadDep[1][0][2] : (ohSel[29][2] ? fru_srcLoadDep[2][0][2] : (ohSel[29][3] ? fru_srcLoadDep[3][0][2] : (ohSel[29][4] ? fru_srcLoadDep[4][0][2] : fru_srcLoadDep[5][0][2])))));
  assign io_toIssueQueues_29_bits_psrc_0 = (ohSel[29][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[29][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[29][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[29][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[29][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_29_bits_pdest = (ohSel[29][0] ? io_fromRename_0_bits_pdest : (ohSel[29][1] ? io_fromRename_1_bits_pdest : (ohSel[29][2] ? io_fromRename_2_bits_pdest : (ohSel[29][3] ? io_fromRename_3_bits_pdest : (ohSel[29][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_29_bits_useRegCache_0 = (ohSel[29][0] ? _rcTagTable_io_readPorts_0_valid : (ohSel[29][1] ? _rcTagTable_io_readPorts_2_valid : (ohSel[29][2] ? _rcTagTable_io_readPorts_4_valid : (ohSel[29][3] ? _rcTagTable_io_readPorts_6_valid : (ohSel[29][4] ? _rcTagTable_io_readPorts_8_valid : _rcTagTable_io_readPorts_10_valid)))));
  assign io_toIssueQueues_29_bits_regCacheIdx_0 = (ohSel[29][0] ? _rcTagTable_io_readPorts_0_addr : (ohSel[29][1] ? _rcTagTable_io_readPorts_2_addr : (ohSel[29][2] ? _rcTagTable_io_readPorts_4_addr : (ohSel[29][3] ? _rcTagTable_io_readPorts_6_addr : (ohSel[29][4] ? _rcTagTable_io_readPorts_8_addr : _rcTagTable_io_readPorts_10_addr)))));
  assign io_toIssueQueues_29_bits_robIdx_flag = (ohSel[29][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[29][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[29][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[29][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[29][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_29_bits_robIdx_value = (ohSel[29][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[29][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[29][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[29][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[29][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  assign io_toIssueQueues_29_bits_lqIdx_flag = (ohSel[29][0] ? _lsqEnqCtrl_io_enq_resp_0_lqIdx_flag : (ohSel[29][1] ? _lsqEnqCtrl_io_enq_resp_1_lqIdx_flag : (ohSel[29][2] ? _lsqEnqCtrl_io_enq_resp_2_lqIdx_flag : (ohSel[29][3] ? _lsqEnqCtrl_io_enq_resp_3_lqIdx_flag : (ohSel[29][4] ? _lsqEnqCtrl_io_enq_resp_4_lqIdx_flag : _lsqEnqCtrl_io_enq_resp_5_lqIdx_flag)))));
  assign io_toIssueQueues_29_bits_lqIdx_value = (ohSel[29][0] ? _lsqEnqCtrl_io_enq_resp_0_lqIdx_value : (ohSel[29][1] ? _lsqEnqCtrl_io_enq_resp_1_lqIdx_value : (ohSel[29][2] ? _lsqEnqCtrl_io_enq_resp_2_lqIdx_value : (ohSel[29][3] ? _lsqEnqCtrl_io_enq_resp_3_lqIdx_value : (ohSel[29][4] ? _lsqEnqCtrl_io_enq_resp_4_lqIdx_value : _lsqEnqCtrl_io_enq_resp_5_lqIdx_value)))));
  assign io_toIssueQueues_29_bits_sqIdx_flag = (ohSel[29][0] ? _lsqEnqCtrl_io_enq_resp_0_sqIdx_flag : (ohSel[29][1] ? _lsqEnqCtrl_io_enq_resp_1_sqIdx_flag : (ohSel[29][2] ? _lsqEnqCtrl_io_enq_resp_2_sqIdx_flag : (ohSel[29][3] ? _lsqEnqCtrl_io_enq_resp_3_sqIdx_flag : (ohSel[29][4] ? _lsqEnqCtrl_io_enq_resp_4_sqIdx_flag : _lsqEnqCtrl_io_enq_resp_5_sqIdx_flag)))));
  assign io_toIssueQueues_29_bits_sqIdx_value = (ohSel[29][0] ? _lsqEnqCtrl_io_enq_resp_0_sqIdx_value : (ohSel[29][1] ? _lsqEnqCtrl_io_enq_resp_1_sqIdx_value : (ohSel[29][2] ? _lsqEnqCtrl_io_enq_resp_2_sqIdx_value : (ohSel[29][3] ? _lsqEnqCtrl_io_enq_resp_3_sqIdx_value : (ohSel[29][4] ? _lsqEnqCtrl_io_enq_resp_4_sqIdx_value : _lsqEnqCtrl_io_enq_resp_5_sqIdx_value)))));
  // -- 端口 30(IQ 15 enq 0)--
  assign io_toIssueQueues_30_valid = (ohSel[30][0] ? fromRenameUpdate_valid[0] : (ohSel[30][1] ? fromRenameUpdate_valid[1] : (ohSel[30][2] ? fromRenameUpdate_valid[2] : (ohSel[30][3] ? fromRenameUpdate_valid[3] : (ohSel[30][4] ? fromRenameUpdate_valid[4] : (ohSel[30][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_30_bits_ftqPtr_flag = (ohSel[30][0] ? io_fromRename_0_bits_ftqPtr_flag : (ohSel[30][1] ? io_fromRename_1_bits_ftqPtr_flag : (ohSel[30][2] ? io_fromRename_2_bits_ftqPtr_flag : (ohSel[30][3] ? io_fromRename_3_bits_ftqPtr_flag : (ohSel[30][4] ? io_fromRename_4_bits_ftqPtr_flag : io_fromRename_5_bits_ftqPtr_flag)))));
  assign io_toIssueQueues_30_bits_ftqPtr_value = (ohSel[30][0] ? io_fromRename_0_bits_ftqPtr_value : (ohSel[30][1] ? io_fromRename_1_bits_ftqPtr_value : (ohSel[30][2] ? io_fromRename_2_bits_ftqPtr_value : (ohSel[30][3] ? io_fromRename_3_bits_ftqPtr_value : (ohSel[30][4] ? io_fromRename_4_bits_ftqPtr_value : io_fromRename_5_bits_ftqPtr_value)))));
  assign io_toIssueQueues_30_bits_ftqOffset = (ohSel[30][0] ? io_fromRename_0_bits_ftqOffset : (ohSel[30][1] ? io_fromRename_1_bits_ftqOffset : (ohSel[30][2] ? io_fromRename_2_bits_ftqOffset : (ohSel[30][3] ? io_fromRename_3_bits_ftqOffset : (ohSel[30][4] ? io_fromRename_4_bits_ftqOffset : io_fromRename_5_bits_ftqOffset)))));
  assign io_toIssueQueues_30_bits_srcType_0 = (ohSel[30][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[30][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[30][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[30][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[30][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_30_bits_srcType_1 = (ohSel[30][0] ? io_fromRename_0_bits_srcType_1 : (ohSel[30][1] ? io_fromRename_1_bits_srcType_1 : (ohSel[30][2] ? io_fromRename_2_bits_srcType_1 : (ohSel[30][3] ? io_fromRename_3_bits_srcType_1 : (ohSel[30][4] ? io_fromRename_4_bits_srcType_1 : io_fromRename_5_bits_srcType_1)))));
  assign io_toIssueQueues_30_bits_srcType_2 = (ohSel[30][0] ? fru_srcType2[0] : (ohSel[30][1] ? fru_srcType2[1] : (ohSel[30][2] ? fru_srcType2[2] : (ohSel[30][3] ? fru_srcType2[3] : (ohSel[30][4] ? fru_srcType2[4] : fru_srcType2[5])))));
  assign io_toIssueQueues_30_bits_srcType_3 = (ohSel[30][0] ? io_fromRename_0_bits_srcType_3 : (ohSel[30][1] ? io_fromRename_1_bits_srcType_3 : (ohSel[30][2] ? io_fromRename_2_bits_srcType_3 : (ohSel[30][3] ? io_fromRename_3_bits_srcType_3 : (ohSel[30][4] ? io_fromRename_4_bits_srcType_3 : io_fromRename_5_bits_srcType_3)))));
  assign io_toIssueQueues_30_bits_srcType_4 = (ohSel[30][0] ? io_fromRename_0_bits_srcType_4 : (ohSel[30][1] ? io_fromRename_1_bits_srcType_4 : (ohSel[30][2] ? io_fromRename_2_bits_srcType_4 : (ohSel[30][3] ? io_fromRename_3_bits_srcType_4 : (ohSel[30][4] ? io_fromRename_4_bits_srcType_4 : io_fromRename_5_bits_srcType_4)))));
  assign io_toIssueQueues_30_bits_fuType = (ohSel[30][0] ? io_fromRename_0_bits_fuType : (ohSel[30][1] ? io_fromRename_1_bits_fuType : (ohSel[30][2] ? io_fromRename_2_bits_fuType : (ohSel[30][3] ? io_fromRename_3_bits_fuType : (ohSel[30][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_30_bits_fuOpType = (ohSel[30][0] ? io_fromRename_0_bits_fuOpType : (ohSel[30][1] ? io_fromRename_1_bits_fuOpType : (ohSel[30][2] ? io_fromRename_2_bits_fuOpType : (ohSel[30][3] ? io_fromRename_3_bits_fuOpType : (ohSel[30][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_30_bits_vecWen = (ohSel[30][0] ? io_fromRename_0_bits_vecWen : (ohSel[30][1] ? io_fromRename_1_bits_vecWen : (ohSel[30][2] ? io_fromRename_2_bits_vecWen : (ohSel[30][3] ? io_fromRename_3_bits_vecWen : (ohSel[30][4] ? io_fromRename_4_bits_vecWen : io_fromRename_5_bits_vecWen)))));
  assign io_toIssueQueues_30_bits_v0Wen = (ohSel[30][0] ? io_fromRename_0_bits_v0Wen : (ohSel[30][1] ? io_fromRename_1_bits_v0Wen : (ohSel[30][2] ? io_fromRename_2_bits_v0Wen : (ohSel[30][3] ? io_fromRename_3_bits_v0Wen : (ohSel[30][4] ? io_fromRename_4_bits_v0Wen : io_fromRename_5_bits_v0Wen)))));
  assign io_toIssueQueues_30_bits_vlWen = (ohSel[30][0] ? io_fromRename_0_bits_vlWen : (ohSel[30][1] ? io_fromRename_1_bits_vlWen : (ohSel[30][2] ? io_fromRename_2_bits_vlWen : (ohSel[30][3] ? io_fromRename_3_bits_vlWen : (ohSel[30][4] ? io_fromRename_4_bits_vlWen : io_fromRename_5_bits_vlWen)))));
  assign io_toIssueQueues_30_bits_vpu_vma = (ohSel[30][0] ? io_fromRename_0_bits_vpu_vma : (ohSel[30][1] ? io_fromRename_1_bits_vpu_vma : (ohSel[30][2] ? io_fromRename_2_bits_vpu_vma : (ohSel[30][3] ? io_fromRename_3_bits_vpu_vma : (ohSel[30][4] ? io_fromRename_4_bits_vpu_vma : io_fromRename_5_bits_vpu_vma)))));
  assign io_toIssueQueues_30_bits_vpu_vta = (ohSel[30][0] ? io_fromRename_0_bits_vpu_vta : (ohSel[30][1] ? io_fromRename_1_bits_vpu_vta : (ohSel[30][2] ? io_fromRename_2_bits_vpu_vta : (ohSel[30][3] ? io_fromRename_3_bits_vpu_vta : (ohSel[30][4] ? io_fromRename_4_bits_vpu_vta : io_fromRename_5_bits_vpu_vta)))));
  assign io_toIssueQueues_30_bits_vpu_vsew = (ohSel[30][0] ? io_fromRename_0_bits_vpu_vsew : (ohSel[30][1] ? io_fromRename_1_bits_vpu_vsew : (ohSel[30][2] ? io_fromRename_2_bits_vpu_vsew : (ohSel[30][3] ? io_fromRename_3_bits_vpu_vsew : (ohSel[30][4] ? io_fromRename_4_bits_vpu_vsew : io_fromRename_5_bits_vpu_vsew)))));
  assign io_toIssueQueues_30_bits_vpu_vlmul = (ohSel[30][0] ? io_fromRename_0_bits_vpu_vlmul : (ohSel[30][1] ? io_fromRename_1_bits_vpu_vlmul : (ohSel[30][2] ? io_fromRename_2_bits_vpu_vlmul : (ohSel[30][3] ? io_fromRename_3_bits_vpu_vlmul : (ohSel[30][4] ? io_fromRename_4_bits_vpu_vlmul : io_fromRename_5_bits_vpu_vlmul)))));
  assign io_toIssueQueues_30_bits_vpu_vm = (ohSel[30][0] ? io_fromRename_0_bits_vpu_vm : (ohSel[30][1] ? io_fromRename_1_bits_vpu_vm : (ohSel[30][2] ? io_fromRename_2_bits_vpu_vm : (ohSel[30][3] ? io_fromRename_3_bits_vpu_vm : (ohSel[30][4] ? io_fromRename_4_bits_vpu_vm : io_fromRename_5_bits_vpu_vm)))));
  assign io_toIssueQueues_30_bits_vpu_vstart = (ohSel[30][0] ? io_fromRename_0_bits_vpu_vstart : (ohSel[30][1] ? io_fromRename_1_bits_vpu_vstart : (ohSel[30][2] ? io_fromRename_2_bits_vpu_vstart : (ohSel[30][3] ? io_fromRename_3_bits_vpu_vstart : (ohSel[30][4] ? io_fromRename_4_bits_vpu_vstart : io_fromRename_5_bits_vpu_vstart)))));
  assign io_toIssueQueues_30_bits_vpu_vmask = (ohSel[30][0] ? io_fromRename_0_bits_vpu_vmask : (ohSel[30][1] ? io_fromRename_1_bits_vpu_vmask : (ohSel[30][2] ? io_fromRename_2_bits_vpu_vmask : (ohSel[30][3] ? io_fromRename_3_bits_vpu_vmask : (ohSel[30][4] ? io_fromRename_4_bits_vpu_vmask : io_fromRename_5_bits_vpu_vmask)))));
  assign io_toIssueQueues_30_bits_vpu_nf = (ohSel[30][0] ? io_fromRename_0_bits_vpu_nf : (ohSel[30][1] ? io_fromRename_1_bits_vpu_nf : (ohSel[30][2] ? io_fromRename_2_bits_vpu_nf : (ohSel[30][3] ? io_fromRename_3_bits_vpu_nf : (ohSel[30][4] ? io_fromRename_4_bits_vpu_nf : io_fromRename_5_bits_vpu_nf)))));
  assign io_toIssueQueues_30_bits_vpu_veew = (ohSel[30][0] ? io_fromRename_0_bits_vpu_veew : (ohSel[30][1] ? io_fromRename_1_bits_vpu_veew : (ohSel[30][2] ? io_fromRename_2_bits_vpu_veew : (ohSel[30][3] ? io_fromRename_3_bits_vpu_veew : (ohSel[30][4] ? io_fromRename_4_bits_vpu_veew : io_fromRename_5_bits_vpu_veew)))));
  assign io_toIssueQueues_30_bits_vpu_isDependOldVd = (ohSel[30][0] ? io_fromRename_0_bits_vpu_isDependOldVd : (ohSel[30][1] ? io_fromRename_1_bits_vpu_isDependOldVd : (ohSel[30][2] ? io_fromRename_2_bits_vpu_isDependOldVd : (ohSel[30][3] ? io_fromRename_3_bits_vpu_isDependOldVd : (ohSel[30][4] ? io_fromRename_4_bits_vpu_isDependOldVd : io_fromRename_5_bits_vpu_isDependOldVd)))));
  assign io_toIssueQueues_30_bits_vpu_isWritePartVd = (ohSel[30][0] ? io_fromRename_0_bits_vpu_isWritePartVd : (ohSel[30][1] ? io_fromRename_1_bits_vpu_isWritePartVd : (ohSel[30][2] ? io_fromRename_2_bits_vpu_isWritePartVd : (ohSel[30][3] ? io_fromRename_3_bits_vpu_isWritePartVd : (ohSel[30][4] ? io_fromRename_4_bits_vpu_isWritePartVd : io_fromRename_5_bits_vpu_isWritePartVd)))));
  assign io_toIssueQueues_30_bits_vpu_isVleff = (ohSel[30][0] ? io_fromRename_0_bits_vpu_isVleff : (ohSel[30][1] ? io_fromRename_1_bits_vpu_isVleff : (ohSel[30][2] ? io_fromRename_2_bits_vpu_isVleff : (ohSel[30][3] ? io_fromRename_3_bits_vpu_isVleff : (ohSel[30][4] ? io_fromRename_4_bits_vpu_isVleff : io_fromRename_5_bits_vpu_isVleff)))));
  assign io_toIssueQueues_30_bits_uopIdx = (ohSel[30][0] ? io_fromRename_0_bits_uopIdx : (ohSel[30][1] ? io_fromRename_1_bits_uopIdx : (ohSel[30][2] ? io_fromRename_2_bits_uopIdx : (ohSel[30][3] ? io_fromRename_3_bits_uopIdx : (ohSel[30][4] ? io_fromRename_4_bits_uopIdx : io_fromRename_5_bits_uopIdx)))));
  assign io_toIssueQueues_30_bits_lastUop = (ohSel[30][0] ? io_fromRename_0_bits_lastUop : (ohSel[30][1] ? io_fromRename_1_bits_lastUop : (ohSel[30][2] ? io_fromRename_2_bits_lastUop : (ohSel[30][3] ? io_fromRename_3_bits_lastUop : (ohSel[30][4] ? io_fromRename_4_bits_lastUop : io_fromRename_5_bits_lastUop)))));
  assign io_toIssueQueues_30_bits_srcState_0 = (ohSel[30][0] ? (allSrcState[0][0][2]) : (ohSel[30][1] ? (allSrcState[1][0][2]) : (ohSel[30][2] ? (allSrcState[2][0][2]) : (ohSel[30][3] ? (allSrcState[3][0][2]) : (ohSel[30][4] ? (allSrcState[4][0][2]) : (allSrcState[5][0][2]))))));
  assign io_toIssueQueues_30_bits_srcState_1 = (ohSel[30][0] ? (allSrcState[0][1][2]) : (ohSel[30][1] ? (allSrcState[1][1][2]) : (ohSel[30][2] ? (allSrcState[2][1][2]) : (ohSel[30][3] ? (allSrcState[3][1][2]) : (ohSel[30][4] ? (allSrcState[4][1][2]) : (allSrcState[5][1][2]))))));
  assign io_toIssueQueues_30_bits_srcState_2 = (ohSel[30][0] ? (allSrcState[0][2][2]) : (ohSel[30][1] ? (allSrcState[1][2][2]) : (ohSel[30][2] ? (allSrcState[2][2][2]) : (ohSel[30][3] ? (allSrcState[3][2][2]) : (ohSel[30][4] ? (allSrcState[4][2][2]) : (allSrcState[5][2][2]))))));
  assign io_toIssueQueues_30_bits_srcState_3 = (ohSel[30][0] ? (allSrcState[0][3][3]) : (ohSel[30][1] ? (allSrcState[1][3][3]) : (ohSel[30][2] ? (allSrcState[2][3][3]) : (ohSel[30][3] ? (allSrcState[3][3][3]) : (ohSel[30][4] ? (allSrcState[4][3][3]) : (allSrcState[5][3][3]))))));
  assign io_toIssueQueues_30_bits_srcState_4 = (ohSel[30][0] ? (allSrcState[0][4][4]) : (ohSel[30][1] ? (allSrcState[1][4][4]) : (ohSel[30][2] ? (allSrcState[2][4][4]) : (ohSel[30][3] ? (allSrcState[3][4][4]) : (ohSel[30][4] ? (allSrcState[4][4][4]) : (allSrcState[5][4][4]))))));
  assign io_toIssueQueues_30_bits_psrc_0 = (ohSel[30][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[30][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[30][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[30][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[30][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_30_bits_psrc_1 = (ohSel[30][0] ? io_fromRename_0_bits_psrc_1 : (ohSel[30][1] ? io_fromRename_1_bits_psrc_1 : (ohSel[30][2] ? io_fromRename_2_bits_psrc_1 : (ohSel[30][3] ? io_fromRename_3_bits_psrc_1 : (ohSel[30][4] ? io_fromRename_4_bits_psrc_1 : io_fromRename_5_bits_psrc_1)))));
  assign io_toIssueQueues_30_bits_psrc_2 = (ohSel[30][0] ? io_fromRename_0_bits_psrc_2 : (ohSel[30][1] ? io_fromRename_1_bits_psrc_2 : (ohSel[30][2] ? io_fromRename_2_bits_psrc_2 : (ohSel[30][3] ? io_fromRename_3_bits_psrc_2 : (ohSel[30][4] ? io_fromRename_4_bits_psrc_2 : io_fromRename_5_bits_psrc_2)))));
  assign io_toIssueQueues_30_bits_psrc_3 = (ohSel[30][0] ? io_fromRename_0_bits_psrc_3 : (ohSel[30][1] ? io_fromRename_1_bits_psrc_3 : (ohSel[30][2] ? io_fromRename_2_bits_psrc_3 : (ohSel[30][3] ? io_fromRename_3_bits_psrc_3 : (ohSel[30][4] ? io_fromRename_4_bits_psrc_3 : io_fromRename_5_bits_psrc_3)))));
  assign io_toIssueQueues_30_bits_psrc_4 = (ohSel[30][0] ? io_fromRename_0_bits_psrc_4 : (ohSel[30][1] ? io_fromRename_1_bits_psrc_4 : (ohSel[30][2] ? io_fromRename_2_bits_psrc_4 : (ohSel[30][3] ? io_fromRename_3_bits_psrc_4 : (ohSel[30][4] ? io_fromRename_4_bits_psrc_4 : io_fromRename_5_bits_psrc_4)))));
  assign io_toIssueQueues_30_bits_pdest = (ohSel[30][0] ? io_fromRename_0_bits_pdest : (ohSel[30][1] ? io_fromRename_1_bits_pdest : (ohSel[30][2] ? io_fromRename_2_bits_pdest : (ohSel[30][3] ? io_fromRename_3_bits_pdest : (ohSel[30][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_30_bits_robIdx_flag = (ohSel[30][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[30][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[30][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[30][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[30][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_30_bits_robIdx_value = (ohSel[30][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[30][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[30][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[30][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[30][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  assign io_toIssueQueues_30_bits_lqIdx_flag = (ohSel[30][0] ? _lsqEnqCtrl_io_enq_resp_0_lqIdx_flag : (ohSel[30][1] ? _lsqEnqCtrl_io_enq_resp_1_lqIdx_flag : (ohSel[30][2] ? _lsqEnqCtrl_io_enq_resp_2_lqIdx_flag : (ohSel[30][3] ? _lsqEnqCtrl_io_enq_resp_3_lqIdx_flag : (ohSel[30][4] ? _lsqEnqCtrl_io_enq_resp_4_lqIdx_flag : _lsqEnqCtrl_io_enq_resp_5_lqIdx_flag)))));
  assign io_toIssueQueues_30_bits_lqIdx_value = (ohSel[30][0] ? _lsqEnqCtrl_io_enq_resp_0_lqIdx_value : (ohSel[30][1] ? _lsqEnqCtrl_io_enq_resp_1_lqIdx_value : (ohSel[30][2] ? _lsqEnqCtrl_io_enq_resp_2_lqIdx_value : (ohSel[30][3] ? _lsqEnqCtrl_io_enq_resp_3_lqIdx_value : (ohSel[30][4] ? _lsqEnqCtrl_io_enq_resp_4_lqIdx_value : _lsqEnqCtrl_io_enq_resp_5_lqIdx_value)))));
  assign io_toIssueQueues_30_bits_sqIdx_flag = (ohSel[30][0] ? _lsqEnqCtrl_io_enq_resp_0_sqIdx_flag : (ohSel[30][1] ? _lsqEnqCtrl_io_enq_resp_1_sqIdx_flag : (ohSel[30][2] ? _lsqEnqCtrl_io_enq_resp_2_sqIdx_flag : (ohSel[30][3] ? _lsqEnqCtrl_io_enq_resp_3_sqIdx_flag : (ohSel[30][4] ? _lsqEnqCtrl_io_enq_resp_4_sqIdx_flag : _lsqEnqCtrl_io_enq_resp_5_sqIdx_flag)))));
  assign io_toIssueQueues_30_bits_sqIdx_value = (ohSel[30][0] ? _lsqEnqCtrl_io_enq_resp_0_sqIdx_value : (ohSel[30][1] ? _lsqEnqCtrl_io_enq_resp_1_sqIdx_value : (ohSel[30][2] ? _lsqEnqCtrl_io_enq_resp_2_sqIdx_value : (ohSel[30][3] ? _lsqEnqCtrl_io_enq_resp_3_sqIdx_value : (ohSel[30][4] ? _lsqEnqCtrl_io_enq_resp_4_sqIdx_value : _lsqEnqCtrl_io_enq_resp_5_sqIdx_value)))));
  assign io_toIssueQueues_30_bits_numLsElem = (ohSel[30][0] ? io_fromRename_0_bits_numLsElem : (ohSel[30][1] ? io_fromRename_1_bits_numLsElem : (ohSel[30][2] ? io_fromRename_2_bits_numLsElem : (ohSel[30][3] ? io_fromRename_3_bits_numLsElem : (ohSel[30][4] ? io_fromRename_4_bits_numLsElem : io_fromRename_5_bits_numLsElem)))));
  // -- 端口 31(IQ 15 enq 1)--
  assign io_toIssueQueues_31_valid = (ohSel[31][0] ? fromRenameUpdate_valid[0] : (ohSel[31][1] ? fromRenameUpdate_valid[1] : (ohSel[31][2] ? fromRenameUpdate_valid[2] : (ohSel[31][3] ? fromRenameUpdate_valid[3] : (ohSel[31][4] ? fromRenameUpdate_valid[4] : (ohSel[31][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_31_bits_ftqPtr_flag = (ohSel[31][0] ? io_fromRename_0_bits_ftqPtr_flag : (ohSel[31][1] ? io_fromRename_1_bits_ftqPtr_flag : (ohSel[31][2] ? io_fromRename_2_bits_ftqPtr_flag : (ohSel[31][3] ? io_fromRename_3_bits_ftqPtr_flag : (ohSel[31][4] ? io_fromRename_4_bits_ftqPtr_flag : io_fromRename_5_bits_ftqPtr_flag)))));
  assign io_toIssueQueues_31_bits_ftqPtr_value = (ohSel[31][0] ? io_fromRename_0_bits_ftqPtr_value : (ohSel[31][1] ? io_fromRename_1_bits_ftqPtr_value : (ohSel[31][2] ? io_fromRename_2_bits_ftqPtr_value : (ohSel[31][3] ? io_fromRename_3_bits_ftqPtr_value : (ohSel[31][4] ? io_fromRename_4_bits_ftqPtr_value : io_fromRename_5_bits_ftqPtr_value)))));
  assign io_toIssueQueues_31_bits_ftqOffset = (ohSel[31][0] ? io_fromRename_0_bits_ftqOffset : (ohSel[31][1] ? io_fromRename_1_bits_ftqOffset : (ohSel[31][2] ? io_fromRename_2_bits_ftqOffset : (ohSel[31][3] ? io_fromRename_3_bits_ftqOffset : (ohSel[31][4] ? io_fromRename_4_bits_ftqOffset : io_fromRename_5_bits_ftqOffset)))));
  assign io_toIssueQueues_31_bits_srcType_0 = (ohSel[31][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[31][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[31][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[31][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[31][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_31_bits_srcType_1 = (ohSel[31][0] ? io_fromRename_0_bits_srcType_1 : (ohSel[31][1] ? io_fromRename_1_bits_srcType_1 : (ohSel[31][2] ? io_fromRename_2_bits_srcType_1 : (ohSel[31][3] ? io_fromRename_3_bits_srcType_1 : (ohSel[31][4] ? io_fromRename_4_bits_srcType_1 : io_fromRename_5_bits_srcType_1)))));
  assign io_toIssueQueues_31_bits_srcType_2 = (ohSel[31][0] ? fru_srcType2[0] : (ohSel[31][1] ? fru_srcType2[1] : (ohSel[31][2] ? fru_srcType2[2] : (ohSel[31][3] ? fru_srcType2[3] : (ohSel[31][4] ? fru_srcType2[4] : fru_srcType2[5])))));
  assign io_toIssueQueues_31_bits_srcType_3 = (ohSel[31][0] ? io_fromRename_0_bits_srcType_3 : (ohSel[31][1] ? io_fromRename_1_bits_srcType_3 : (ohSel[31][2] ? io_fromRename_2_bits_srcType_3 : (ohSel[31][3] ? io_fromRename_3_bits_srcType_3 : (ohSel[31][4] ? io_fromRename_4_bits_srcType_3 : io_fromRename_5_bits_srcType_3)))));
  assign io_toIssueQueues_31_bits_srcType_4 = (ohSel[31][0] ? io_fromRename_0_bits_srcType_4 : (ohSel[31][1] ? io_fromRename_1_bits_srcType_4 : (ohSel[31][2] ? io_fromRename_2_bits_srcType_4 : (ohSel[31][3] ? io_fromRename_3_bits_srcType_4 : (ohSel[31][4] ? io_fromRename_4_bits_srcType_4 : io_fromRename_5_bits_srcType_4)))));
  assign io_toIssueQueues_31_bits_fuType = (ohSel[31][0] ? io_fromRename_0_bits_fuType : (ohSel[31][1] ? io_fromRename_1_bits_fuType : (ohSel[31][2] ? io_fromRename_2_bits_fuType : (ohSel[31][3] ? io_fromRename_3_bits_fuType : (ohSel[31][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_31_bits_fuOpType = (ohSel[31][0] ? io_fromRename_0_bits_fuOpType : (ohSel[31][1] ? io_fromRename_1_bits_fuOpType : (ohSel[31][2] ? io_fromRename_2_bits_fuOpType : (ohSel[31][3] ? io_fromRename_3_bits_fuOpType : (ohSel[31][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_31_bits_vecWen = (ohSel[31][0] ? io_fromRename_0_bits_vecWen : (ohSel[31][1] ? io_fromRename_1_bits_vecWen : (ohSel[31][2] ? io_fromRename_2_bits_vecWen : (ohSel[31][3] ? io_fromRename_3_bits_vecWen : (ohSel[31][4] ? io_fromRename_4_bits_vecWen : io_fromRename_5_bits_vecWen)))));
  assign io_toIssueQueues_31_bits_v0Wen = (ohSel[31][0] ? io_fromRename_0_bits_v0Wen : (ohSel[31][1] ? io_fromRename_1_bits_v0Wen : (ohSel[31][2] ? io_fromRename_2_bits_v0Wen : (ohSel[31][3] ? io_fromRename_3_bits_v0Wen : (ohSel[31][4] ? io_fromRename_4_bits_v0Wen : io_fromRename_5_bits_v0Wen)))));
  assign io_toIssueQueues_31_bits_vlWen = (ohSel[31][0] ? io_fromRename_0_bits_vlWen : (ohSel[31][1] ? io_fromRename_1_bits_vlWen : (ohSel[31][2] ? io_fromRename_2_bits_vlWen : (ohSel[31][3] ? io_fromRename_3_bits_vlWen : (ohSel[31][4] ? io_fromRename_4_bits_vlWen : io_fromRename_5_bits_vlWen)))));
  assign io_toIssueQueues_31_bits_vpu_vma = (ohSel[31][0] ? io_fromRename_0_bits_vpu_vma : (ohSel[31][1] ? io_fromRename_1_bits_vpu_vma : (ohSel[31][2] ? io_fromRename_2_bits_vpu_vma : (ohSel[31][3] ? io_fromRename_3_bits_vpu_vma : (ohSel[31][4] ? io_fromRename_4_bits_vpu_vma : io_fromRename_5_bits_vpu_vma)))));
  assign io_toIssueQueues_31_bits_vpu_vta = (ohSel[31][0] ? io_fromRename_0_bits_vpu_vta : (ohSel[31][1] ? io_fromRename_1_bits_vpu_vta : (ohSel[31][2] ? io_fromRename_2_bits_vpu_vta : (ohSel[31][3] ? io_fromRename_3_bits_vpu_vta : (ohSel[31][4] ? io_fromRename_4_bits_vpu_vta : io_fromRename_5_bits_vpu_vta)))));
  assign io_toIssueQueues_31_bits_vpu_vsew = (ohSel[31][0] ? io_fromRename_0_bits_vpu_vsew : (ohSel[31][1] ? io_fromRename_1_bits_vpu_vsew : (ohSel[31][2] ? io_fromRename_2_bits_vpu_vsew : (ohSel[31][3] ? io_fromRename_3_bits_vpu_vsew : (ohSel[31][4] ? io_fromRename_4_bits_vpu_vsew : io_fromRename_5_bits_vpu_vsew)))));
  assign io_toIssueQueues_31_bits_vpu_vlmul = (ohSel[31][0] ? io_fromRename_0_bits_vpu_vlmul : (ohSel[31][1] ? io_fromRename_1_bits_vpu_vlmul : (ohSel[31][2] ? io_fromRename_2_bits_vpu_vlmul : (ohSel[31][3] ? io_fromRename_3_bits_vpu_vlmul : (ohSel[31][4] ? io_fromRename_4_bits_vpu_vlmul : io_fromRename_5_bits_vpu_vlmul)))));
  assign io_toIssueQueues_31_bits_vpu_vm = (ohSel[31][0] ? io_fromRename_0_bits_vpu_vm : (ohSel[31][1] ? io_fromRename_1_bits_vpu_vm : (ohSel[31][2] ? io_fromRename_2_bits_vpu_vm : (ohSel[31][3] ? io_fromRename_3_bits_vpu_vm : (ohSel[31][4] ? io_fromRename_4_bits_vpu_vm : io_fromRename_5_bits_vpu_vm)))));
  assign io_toIssueQueues_31_bits_vpu_vstart = (ohSel[31][0] ? io_fromRename_0_bits_vpu_vstart : (ohSel[31][1] ? io_fromRename_1_bits_vpu_vstart : (ohSel[31][2] ? io_fromRename_2_bits_vpu_vstart : (ohSel[31][3] ? io_fromRename_3_bits_vpu_vstart : (ohSel[31][4] ? io_fromRename_4_bits_vpu_vstart : io_fromRename_5_bits_vpu_vstart)))));
  assign io_toIssueQueues_31_bits_vpu_vmask = (ohSel[31][0] ? io_fromRename_0_bits_vpu_vmask : (ohSel[31][1] ? io_fromRename_1_bits_vpu_vmask : (ohSel[31][2] ? io_fromRename_2_bits_vpu_vmask : (ohSel[31][3] ? io_fromRename_3_bits_vpu_vmask : (ohSel[31][4] ? io_fromRename_4_bits_vpu_vmask : io_fromRename_5_bits_vpu_vmask)))));
  assign io_toIssueQueues_31_bits_vpu_nf = (ohSel[31][0] ? io_fromRename_0_bits_vpu_nf : (ohSel[31][1] ? io_fromRename_1_bits_vpu_nf : (ohSel[31][2] ? io_fromRename_2_bits_vpu_nf : (ohSel[31][3] ? io_fromRename_3_bits_vpu_nf : (ohSel[31][4] ? io_fromRename_4_bits_vpu_nf : io_fromRename_5_bits_vpu_nf)))));
  assign io_toIssueQueues_31_bits_vpu_veew = (ohSel[31][0] ? io_fromRename_0_bits_vpu_veew : (ohSel[31][1] ? io_fromRename_1_bits_vpu_veew : (ohSel[31][2] ? io_fromRename_2_bits_vpu_veew : (ohSel[31][3] ? io_fromRename_3_bits_vpu_veew : (ohSel[31][4] ? io_fromRename_4_bits_vpu_veew : io_fromRename_5_bits_vpu_veew)))));
  assign io_toIssueQueues_31_bits_vpu_isDependOldVd = (ohSel[31][0] ? io_fromRename_0_bits_vpu_isDependOldVd : (ohSel[31][1] ? io_fromRename_1_bits_vpu_isDependOldVd : (ohSel[31][2] ? io_fromRename_2_bits_vpu_isDependOldVd : (ohSel[31][3] ? io_fromRename_3_bits_vpu_isDependOldVd : (ohSel[31][4] ? io_fromRename_4_bits_vpu_isDependOldVd : io_fromRename_5_bits_vpu_isDependOldVd)))));
  assign io_toIssueQueues_31_bits_vpu_isWritePartVd = (ohSel[31][0] ? io_fromRename_0_bits_vpu_isWritePartVd : (ohSel[31][1] ? io_fromRename_1_bits_vpu_isWritePartVd : (ohSel[31][2] ? io_fromRename_2_bits_vpu_isWritePartVd : (ohSel[31][3] ? io_fromRename_3_bits_vpu_isWritePartVd : (ohSel[31][4] ? io_fromRename_4_bits_vpu_isWritePartVd : io_fromRename_5_bits_vpu_isWritePartVd)))));
  assign io_toIssueQueues_31_bits_vpu_isVleff = (ohSel[31][0] ? io_fromRename_0_bits_vpu_isVleff : (ohSel[31][1] ? io_fromRename_1_bits_vpu_isVleff : (ohSel[31][2] ? io_fromRename_2_bits_vpu_isVleff : (ohSel[31][3] ? io_fromRename_3_bits_vpu_isVleff : (ohSel[31][4] ? io_fromRename_4_bits_vpu_isVleff : io_fromRename_5_bits_vpu_isVleff)))));
  assign io_toIssueQueues_31_bits_uopIdx = (ohSel[31][0] ? io_fromRename_0_bits_uopIdx : (ohSel[31][1] ? io_fromRename_1_bits_uopIdx : (ohSel[31][2] ? io_fromRename_2_bits_uopIdx : (ohSel[31][3] ? io_fromRename_3_bits_uopIdx : (ohSel[31][4] ? io_fromRename_4_bits_uopIdx : io_fromRename_5_bits_uopIdx)))));
  assign io_toIssueQueues_31_bits_lastUop = (ohSel[31][0] ? io_fromRename_0_bits_lastUop : (ohSel[31][1] ? io_fromRename_1_bits_lastUop : (ohSel[31][2] ? io_fromRename_2_bits_lastUop : (ohSel[31][3] ? io_fromRename_3_bits_lastUop : (ohSel[31][4] ? io_fromRename_4_bits_lastUop : io_fromRename_5_bits_lastUop)))));
  assign io_toIssueQueues_31_bits_srcState_0 = (ohSel[31][0] ? (allSrcState[0][0][2]) : (ohSel[31][1] ? (allSrcState[1][0][2]) : (ohSel[31][2] ? (allSrcState[2][0][2]) : (ohSel[31][3] ? (allSrcState[3][0][2]) : (ohSel[31][4] ? (allSrcState[4][0][2]) : (allSrcState[5][0][2]))))));
  assign io_toIssueQueues_31_bits_srcState_1 = (ohSel[31][0] ? (allSrcState[0][1][2]) : (ohSel[31][1] ? (allSrcState[1][1][2]) : (ohSel[31][2] ? (allSrcState[2][1][2]) : (ohSel[31][3] ? (allSrcState[3][1][2]) : (ohSel[31][4] ? (allSrcState[4][1][2]) : (allSrcState[5][1][2]))))));
  assign io_toIssueQueues_31_bits_srcState_2 = (ohSel[31][0] ? (allSrcState[0][2][2]) : (ohSel[31][1] ? (allSrcState[1][2][2]) : (ohSel[31][2] ? (allSrcState[2][2][2]) : (ohSel[31][3] ? (allSrcState[3][2][2]) : (ohSel[31][4] ? (allSrcState[4][2][2]) : (allSrcState[5][2][2]))))));
  assign io_toIssueQueues_31_bits_srcState_3 = (ohSel[31][0] ? (allSrcState[0][3][3]) : (ohSel[31][1] ? (allSrcState[1][3][3]) : (ohSel[31][2] ? (allSrcState[2][3][3]) : (ohSel[31][3] ? (allSrcState[3][3][3]) : (ohSel[31][4] ? (allSrcState[4][3][3]) : (allSrcState[5][3][3]))))));
  assign io_toIssueQueues_31_bits_srcState_4 = (ohSel[31][0] ? (allSrcState[0][4][4]) : (ohSel[31][1] ? (allSrcState[1][4][4]) : (ohSel[31][2] ? (allSrcState[2][4][4]) : (ohSel[31][3] ? (allSrcState[3][4][4]) : (ohSel[31][4] ? (allSrcState[4][4][4]) : (allSrcState[5][4][4]))))));
  assign io_toIssueQueues_31_bits_psrc_0 = (ohSel[31][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[31][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[31][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[31][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[31][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_31_bits_psrc_1 = (ohSel[31][0] ? io_fromRename_0_bits_psrc_1 : (ohSel[31][1] ? io_fromRename_1_bits_psrc_1 : (ohSel[31][2] ? io_fromRename_2_bits_psrc_1 : (ohSel[31][3] ? io_fromRename_3_bits_psrc_1 : (ohSel[31][4] ? io_fromRename_4_bits_psrc_1 : io_fromRename_5_bits_psrc_1)))));
  assign io_toIssueQueues_31_bits_psrc_2 = (ohSel[31][0] ? io_fromRename_0_bits_psrc_2 : (ohSel[31][1] ? io_fromRename_1_bits_psrc_2 : (ohSel[31][2] ? io_fromRename_2_bits_psrc_2 : (ohSel[31][3] ? io_fromRename_3_bits_psrc_2 : (ohSel[31][4] ? io_fromRename_4_bits_psrc_2 : io_fromRename_5_bits_psrc_2)))));
  assign io_toIssueQueues_31_bits_psrc_3 = (ohSel[31][0] ? io_fromRename_0_bits_psrc_3 : (ohSel[31][1] ? io_fromRename_1_bits_psrc_3 : (ohSel[31][2] ? io_fromRename_2_bits_psrc_3 : (ohSel[31][3] ? io_fromRename_3_bits_psrc_3 : (ohSel[31][4] ? io_fromRename_4_bits_psrc_3 : io_fromRename_5_bits_psrc_3)))));
  assign io_toIssueQueues_31_bits_psrc_4 = (ohSel[31][0] ? io_fromRename_0_bits_psrc_4 : (ohSel[31][1] ? io_fromRename_1_bits_psrc_4 : (ohSel[31][2] ? io_fromRename_2_bits_psrc_4 : (ohSel[31][3] ? io_fromRename_3_bits_psrc_4 : (ohSel[31][4] ? io_fromRename_4_bits_psrc_4 : io_fromRename_5_bits_psrc_4)))));
  assign io_toIssueQueues_31_bits_pdest = (ohSel[31][0] ? io_fromRename_0_bits_pdest : (ohSel[31][1] ? io_fromRename_1_bits_pdest : (ohSel[31][2] ? io_fromRename_2_bits_pdest : (ohSel[31][3] ? io_fromRename_3_bits_pdest : (ohSel[31][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_31_bits_robIdx_flag = (ohSel[31][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[31][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[31][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[31][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[31][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_31_bits_robIdx_value = (ohSel[31][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[31][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[31][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[31][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[31][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  assign io_toIssueQueues_31_bits_lqIdx_flag = (ohSel[31][0] ? _lsqEnqCtrl_io_enq_resp_0_lqIdx_flag : (ohSel[31][1] ? _lsqEnqCtrl_io_enq_resp_1_lqIdx_flag : (ohSel[31][2] ? _lsqEnqCtrl_io_enq_resp_2_lqIdx_flag : (ohSel[31][3] ? _lsqEnqCtrl_io_enq_resp_3_lqIdx_flag : (ohSel[31][4] ? _lsqEnqCtrl_io_enq_resp_4_lqIdx_flag : _lsqEnqCtrl_io_enq_resp_5_lqIdx_flag)))));
  assign io_toIssueQueues_31_bits_lqIdx_value = (ohSel[31][0] ? _lsqEnqCtrl_io_enq_resp_0_lqIdx_value : (ohSel[31][1] ? _lsqEnqCtrl_io_enq_resp_1_lqIdx_value : (ohSel[31][2] ? _lsqEnqCtrl_io_enq_resp_2_lqIdx_value : (ohSel[31][3] ? _lsqEnqCtrl_io_enq_resp_3_lqIdx_value : (ohSel[31][4] ? _lsqEnqCtrl_io_enq_resp_4_lqIdx_value : _lsqEnqCtrl_io_enq_resp_5_lqIdx_value)))));
  assign io_toIssueQueues_31_bits_sqIdx_flag = (ohSel[31][0] ? _lsqEnqCtrl_io_enq_resp_0_sqIdx_flag : (ohSel[31][1] ? _lsqEnqCtrl_io_enq_resp_1_sqIdx_flag : (ohSel[31][2] ? _lsqEnqCtrl_io_enq_resp_2_sqIdx_flag : (ohSel[31][3] ? _lsqEnqCtrl_io_enq_resp_3_sqIdx_flag : (ohSel[31][4] ? _lsqEnqCtrl_io_enq_resp_4_sqIdx_flag : _lsqEnqCtrl_io_enq_resp_5_sqIdx_flag)))));
  assign io_toIssueQueues_31_bits_sqIdx_value = (ohSel[31][0] ? _lsqEnqCtrl_io_enq_resp_0_sqIdx_value : (ohSel[31][1] ? _lsqEnqCtrl_io_enq_resp_1_sqIdx_value : (ohSel[31][2] ? _lsqEnqCtrl_io_enq_resp_2_sqIdx_value : (ohSel[31][3] ? _lsqEnqCtrl_io_enq_resp_3_sqIdx_value : (ohSel[31][4] ? _lsqEnqCtrl_io_enq_resp_4_sqIdx_value : _lsqEnqCtrl_io_enq_resp_5_sqIdx_value)))));
  assign io_toIssueQueues_31_bits_numLsElem = (ohSel[31][0] ? io_fromRename_0_bits_numLsElem : (ohSel[31][1] ? io_fromRename_1_bits_numLsElem : (ohSel[31][2] ? io_fromRename_2_bits_numLsElem : (ohSel[31][3] ? io_fromRename_3_bits_numLsElem : (ohSel[31][4] ? io_fromRename_4_bits_numLsElem : io_fromRename_5_bits_numLsElem)))));
  // -- 端口 32(IQ 16 enq 0)--
  assign io_toIssueQueues_32_valid = (ohSel[32][0] ? fromRenameUpdate_valid[0] : (ohSel[32][1] ? fromRenameUpdate_valid[1] : (ohSel[32][2] ? fromRenameUpdate_valid[2] : (ohSel[32][3] ? fromRenameUpdate_valid[3] : (ohSel[32][4] ? fromRenameUpdate_valid[4] : (ohSel[32][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_32_bits_ftqPtr_flag = (ohSel[32][0] ? io_fromRename_0_bits_ftqPtr_flag : (ohSel[32][1] ? io_fromRename_1_bits_ftqPtr_flag : (ohSel[32][2] ? io_fromRename_2_bits_ftqPtr_flag : (ohSel[32][3] ? io_fromRename_3_bits_ftqPtr_flag : (ohSel[32][4] ? io_fromRename_4_bits_ftqPtr_flag : io_fromRename_5_bits_ftqPtr_flag)))));
  assign io_toIssueQueues_32_bits_ftqPtr_value = (ohSel[32][0] ? io_fromRename_0_bits_ftqPtr_value : (ohSel[32][1] ? io_fromRename_1_bits_ftqPtr_value : (ohSel[32][2] ? io_fromRename_2_bits_ftqPtr_value : (ohSel[32][3] ? io_fromRename_3_bits_ftqPtr_value : (ohSel[32][4] ? io_fromRename_4_bits_ftqPtr_value : io_fromRename_5_bits_ftqPtr_value)))));
  assign io_toIssueQueues_32_bits_ftqOffset = (ohSel[32][0] ? io_fromRename_0_bits_ftqOffset : (ohSel[32][1] ? io_fromRename_1_bits_ftqOffset : (ohSel[32][2] ? io_fromRename_2_bits_ftqOffset : (ohSel[32][3] ? io_fromRename_3_bits_ftqOffset : (ohSel[32][4] ? io_fromRename_4_bits_ftqOffset : io_fromRename_5_bits_ftqOffset)))));
  assign io_toIssueQueues_32_bits_srcType_0 = (ohSel[32][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[32][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[32][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[32][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[32][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_32_bits_srcType_1 = (ohSel[32][0] ? io_fromRename_0_bits_srcType_1 : (ohSel[32][1] ? io_fromRename_1_bits_srcType_1 : (ohSel[32][2] ? io_fromRename_2_bits_srcType_1 : (ohSel[32][3] ? io_fromRename_3_bits_srcType_1 : (ohSel[32][4] ? io_fromRename_4_bits_srcType_1 : io_fromRename_5_bits_srcType_1)))));
  assign io_toIssueQueues_32_bits_srcType_2 = (ohSel[32][0] ? fru_srcType2[0] : (ohSel[32][1] ? fru_srcType2[1] : (ohSel[32][2] ? fru_srcType2[2] : (ohSel[32][3] ? fru_srcType2[3] : (ohSel[32][4] ? fru_srcType2[4] : fru_srcType2[5])))));
  assign io_toIssueQueues_32_bits_srcType_3 = (ohSel[32][0] ? io_fromRename_0_bits_srcType_3 : (ohSel[32][1] ? io_fromRename_1_bits_srcType_3 : (ohSel[32][2] ? io_fromRename_2_bits_srcType_3 : (ohSel[32][3] ? io_fromRename_3_bits_srcType_3 : (ohSel[32][4] ? io_fromRename_4_bits_srcType_3 : io_fromRename_5_bits_srcType_3)))));
  assign io_toIssueQueues_32_bits_srcType_4 = (ohSel[32][0] ? io_fromRename_0_bits_srcType_4 : (ohSel[32][1] ? io_fromRename_1_bits_srcType_4 : (ohSel[32][2] ? io_fromRename_2_bits_srcType_4 : (ohSel[32][3] ? io_fromRename_3_bits_srcType_4 : (ohSel[32][4] ? io_fromRename_4_bits_srcType_4 : io_fromRename_5_bits_srcType_4)))));
  assign io_toIssueQueues_32_bits_fuType = (ohSel[32][0] ? io_fromRename_0_bits_fuType : (ohSel[32][1] ? io_fromRename_1_bits_fuType : (ohSel[32][2] ? io_fromRename_2_bits_fuType : (ohSel[32][3] ? io_fromRename_3_bits_fuType : (ohSel[32][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_32_bits_fuOpType = (ohSel[32][0] ? io_fromRename_0_bits_fuOpType : (ohSel[32][1] ? io_fromRename_1_bits_fuOpType : (ohSel[32][2] ? io_fromRename_2_bits_fuOpType : (ohSel[32][3] ? io_fromRename_3_bits_fuOpType : (ohSel[32][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_32_bits_vecWen = (ohSel[32][0] ? io_fromRename_0_bits_vecWen : (ohSel[32][1] ? io_fromRename_1_bits_vecWen : (ohSel[32][2] ? io_fromRename_2_bits_vecWen : (ohSel[32][3] ? io_fromRename_3_bits_vecWen : (ohSel[32][4] ? io_fromRename_4_bits_vecWen : io_fromRename_5_bits_vecWen)))));
  assign io_toIssueQueues_32_bits_v0Wen = (ohSel[32][0] ? io_fromRename_0_bits_v0Wen : (ohSel[32][1] ? io_fromRename_1_bits_v0Wen : (ohSel[32][2] ? io_fromRename_2_bits_v0Wen : (ohSel[32][3] ? io_fromRename_3_bits_v0Wen : (ohSel[32][4] ? io_fromRename_4_bits_v0Wen : io_fromRename_5_bits_v0Wen)))));
  assign io_toIssueQueues_32_bits_vlWen = (ohSel[32][0] ? io_fromRename_0_bits_vlWen : (ohSel[32][1] ? io_fromRename_1_bits_vlWen : (ohSel[32][2] ? io_fromRename_2_bits_vlWen : (ohSel[32][3] ? io_fromRename_3_bits_vlWen : (ohSel[32][4] ? io_fromRename_4_bits_vlWen : io_fromRename_5_bits_vlWen)))));
  assign io_toIssueQueues_32_bits_vpu_vma = (ohSel[32][0] ? io_fromRename_0_bits_vpu_vma : (ohSel[32][1] ? io_fromRename_1_bits_vpu_vma : (ohSel[32][2] ? io_fromRename_2_bits_vpu_vma : (ohSel[32][3] ? io_fromRename_3_bits_vpu_vma : (ohSel[32][4] ? io_fromRename_4_bits_vpu_vma : io_fromRename_5_bits_vpu_vma)))));
  assign io_toIssueQueues_32_bits_vpu_vta = (ohSel[32][0] ? io_fromRename_0_bits_vpu_vta : (ohSel[32][1] ? io_fromRename_1_bits_vpu_vta : (ohSel[32][2] ? io_fromRename_2_bits_vpu_vta : (ohSel[32][3] ? io_fromRename_3_bits_vpu_vta : (ohSel[32][4] ? io_fromRename_4_bits_vpu_vta : io_fromRename_5_bits_vpu_vta)))));
  assign io_toIssueQueues_32_bits_vpu_vsew = (ohSel[32][0] ? io_fromRename_0_bits_vpu_vsew : (ohSel[32][1] ? io_fromRename_1_bits_vpu_vsew : (ohSel[32][2] ? io_fromRename_2_bits_vpu_vsew : (ohSel[32][3] ? io_fromRename_3_bits_vpu_vsew : (ohSel[32][4] ? io_fromRename_4_bits_vpu_vsew : io_fromRename_5_bits_vpu_vsew)))));
  assign io_toIssueQueues_32_bits_vpu_vlmul = (ohSel[32][0] ? io_fromRename_0_bits_vpu_vlmul : (ohSel[32][1] ? io_fromRename_1_bits_vpu_vlmul : (ohSel[32][2] ? io_fromRename_2_bits_vpu_vlmul : (ohSel[32][3] ? io_fromRename_3_bits_vpu_vlmul : (ohSel[32][4] ? io_fromRename_4_bits_vpu_vlmul : io_fromRename_5_bits_vpu_vlmul)))));
  assign io_toIssueQueues_32_bits_vpu_vm = (ohSel[32][0] ? io_fromRename_0_bits_vpu_vm : (ohSel[32][1] ? io_fromRename_1_bits_vpu_vm : (ohSel[32][2] ? io_fromRename_2_bits_vpu_vm : (ohSel[32][3] ? io_fromRename_3_bits_vpu_vm : (ohSel[32][4] ? io_fromRename_4_bits_vpu_vm : io_fromRename_5_bits_vpu_vm)))));
  assign io_toIssueQueues_32_bits_vpu_vstart = (ohSel[32][0] ? io_fromRename_0_bits_vpu_vstart : (ohSel[32][1] ? io_fromRename_1_bits_vpu_vstart : (ohSel[32][2] ? io_fromRename_2_bits_vpu_vstart : (ohSel[32][3] ? io_fromRename_3_bits_vpu_vstart : (ohSel[32][4] ? io_fromRename_4_bits_vpu_vstart : io_fromRename_5_bits_vpu_vstart)))));
  assign io_toIssueQueues_32_bits_vpu_vmask = (ohSel[32][0] ? io_fromRename_0_bits_vpu_vmask : (ohSel[32][1] ? io_fromRename_1_bits_vpu_vmask : (ohSel[32][2] ? io_fromRename_2_bits_vpu_vmask : (ohSel[32][3] ? io_fromRename_3_bits_vpu_vmask : (ohSel[32][4] ? io_fromRename_4_bits_vpu_vmask : io_fromRename_5_bits_vpu_vmask)))));
  assign io_toIssueQueues_32_bits_vpu_nf = (ohSel[32][0] ? io_fromRename_0_bits_vpu_nf : (ohSel[32][1] ? io_fromRename_1_bits_vpu_nf : (ohSel[32][2] ? io_fromRename_2_bits_vpu_nf : (ohSel[32][3] ? io_fromRename_3_bits_vpu_nf : (ohSel[32][4] ? io_fromRename_4_bits_vpu_nf : io_fromRename_5_bits_vpu_nf)))));
  assign io_toIssueQueues_32_bits_vpu_veew = (ohSel[32][0] ? io_fromRename_0_bits_vpu_veew : (ohSel[32][1] ? io_fromRename_1_bits_vpu_veew : (ohSel[32][2] ? io_fromRename_2_bits_vpu_veew : (ohSel[32][3] ? io_fromRename_3_bits_vpu_veew : (ohSel[32][4] ? io_fromRename_4_bits_vpu_veew : io_fromRename_5_bits_vpu_veew)))));
  assign io_toIssueQueues_32_bits_vpu_isDependOldVd = (ohSel[32][0] ? io_fromRename_0_bits_vpu_isDependOldVd : (ohSel[32][1] ? io_fromRename_1_bits_vpu_isDependOldVd : (ohSel[32][2] ? io_fromRename_2_bits_vpu_isDependOldVd : (ohSel[32][3] ? io_fromRename_3_bits_vpu_isDependOldVd : (ohSel[32][4] ? io_fromRename_4_bits_vpu_isDependOldVd : io_fromRename_5_bits_vpu_isDependOldVd)))));
  assign io_toIssueQueues_32_bits_vpu_isWritePartVd = (ohSel[32][0] ? io_fromRename_0_bits_vpu_isWritePartVd : (ohSel[32][1] ? io_fromRename_1_bits_vpu_isWritePartVd : (ohSel[32][2] ? io_fromRename_2_bits_vpu_isWritePartVd : (ohSel[32][3] ? io_fromRename_3_bits_vpu_isWritePartVd : (ohSel[32][4] ? io_fromRename_4_bits_vpu_isWritePartVd : io_fromRename_5_bits_vpu_isWritePartVd)))));
  assign io_toIssueQueues_32_bits_vpu_isVleff = (ohSel[32][0] ? io_fromRename_0_bits_vpu_isVleff : (ohSel[32][1] ? io_fromRename_1_bits_vpu_isVleff : (ohSel[32][2] ? io_fromRename_2_bits_vpu_isVleff : (ohSel[32][3] ? io_fromRename_3_bits_vpu_isVleff : (ohSel[32][4] ? io_fromRename_4_bits_vpu_isVleff : io_fromRename_5_bits_vpu_isVleff)))));
  assign io_toIssueQueues_32_bits_uopIdx = (ohSel[32][0] ? io_fromRename_0_bits_uopIdx : (ohSel[32][1] ? io_fromRename_1_bits_uopIdx : (ohSel[32][2] ? io_fromRename_2_bits_uopIdx : (ohSel[32][3] ? io_fromRename_3_bits_uopIdx : (ohSel[32][4] ? io_fromRename_4_bits_uopIdx : io_fromRename_5_bits_uopIdx)))));
  assign io_toIssueQueues_32_bits_lastUop = (ohSel[32][0] ? io_fromRename_0_bits_lastUop : (ohSel[32][1] ? io_fromRename_1_bits_lastUop : (ohSel[32][2] ? io_fromRename_2_bits_lastUop : (ohSel[32][3] ? io_fromRename_3_bits_lastUop : (ohSel[32][4] ? io_fromRename_4_bits_lastUop : io_fromRename_5_bits_lastUop)))));
  assign io_toIssueQueues_32_bits_srcState_0 = (ohSel[32][0] ? (allSrcState[0][0][2]) : (ohSel[32][1] ? (allSrcState[1][0][2]) : (ohSel[32][2] ? (allSrcState[2][0][2]) : (ohSel[32][3] ? (allSrcState[3][0][2]) : (ohSel[32][4] ? (allSrcState[4][0][2]) : (allSrcState[5][0][2]))))));
  assign io_toIssueQueues_32_bits_srcState_1 = (ohSel[32][0] ? (allSrcState[0][1][2]) : (ohSel[32][1] ? (allSrcState[1][1][2]) : (ohSel[32][2] ? (allSrcState[2][1][2]) : (ohSel[32][3] ? (allSrcState[3][1][2]) : (ohSel[32][4] ? (allSrcState[4][1][2]) : (allSrcState[5][1][2]))))));
  assign io_toIssueQueues_32_bits_srcState_2 = (ohSel[32][0] ? (allSrcState[0][2][2]) : (ohSel[32][1] ? (allSrcState[1][2][2]) : (ohSel[32][2] ? (allSrcState[2][2][2]) : (ohSel[32][3] ? (allSrcState[3][2][2]) : (ohSel[32][4] ? (allSrcState[4][2][2]) : (allSrcState[5][2][2]))))));
  assign io_toIssueQueues_32_bits_srcState_3 = (ohSel[32][0] ? (allSrcState[0][3][3]) : (ohSel[32][1] ? (allSrcState[1][3][3]) : (ohSel[32][2] ? (allSrcState[2][3][3]) : (ohSel[32][3] ? (allSrcState[3][3][3]) : (ohSel[32][4] ? (allSrcState[4][3][3]) : (allSrcState[5][3][3]))))));
  assign io_toIssueQueues_32_bits_srcState_4 = (ohSel[32][0] ? (allSrcState[0][4][4]) : (ohSel[32][1] ? (allSrcState[1][4][4]) : (ohSel[32][2] ? (allSrcState[2][4][4]) : (ohSel[32][3] ? (allSrcState[3][4][4]) : (ohSel[32][4] ? (allSrcState[4][4][4]) : (allSrcState[5][4][4]))))));
  assign io_toIssueQueues_32_bits_psrc_0 = (ohSel[32][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[32][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[32][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[32][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[32][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_32_bits_psrc_1 = (ohSel[32][0] ? io_fromRename_0_bits_psrc_1 : (ohSel[32][1] ? io_fromRename_1_bits_psrc_1 : (ohSel[32][2] ? io_fromRename_2_bits_psrc_1 : (ohSel[32][3] ? io_fromRename_3_bits_psrc_1 : (ohSel[32][4] ? io_fromRename_4_bits_psrc_1 : io_fromRename_5_bits_psrc_1)))));
  assign io_toIssueQueues_32_bits_psrc_2 = (ohSel[32][0] ? io_fromRename_0_bits_psrc_2 : (ohSel[32][1] ? io_fromRename_1_bits_psrc_2 : (ohSel[32][2] ? io_fromRename_2_bits_psrc_2 : (ohSel[32][3] ? io_fromRename_3_bits_psrc_2 : (ohSel[32][4] ? io_fromRename_4_bits_psrc_2 : io_fromRename_5_bits_psrc_2)))));
  assign io_toIssueQueues_32_bits_psrc_3 = (ohSel[32][0] ? io_fromRename_0_bits_psrc_3 : (ohSel[32][1] ? io_fromRename_1_bits_psrc_3 : (ohSel[32][2] ? io_fromRename_2_bits_psrc_3 : (ohSel[32][3] ? io_fromRename_3_bits_psrc_3 : (ohSel[32][4] ? io_fromRename_4_bits_psrc_3 : io_fromRename_5_bits_psrc_3)))));
  assign io_toIssueQueues_32_bits_psrc_4 = (ohSel[32][0] ? io_fromRename_0_bits_psrc_4 : (ohSel[32][1] ? io_fromRename_1_bits_psrc_4 : (ohSel[32][2] ? io_fromRename_2_bits_psrc_4 : (ohSel[32][3] ? io_fromRename_3_bits_psrc_4 : (ohSel[32][4] ? io_fromRename_4_bits_psrc_4 : io_fromRename_5_bits_psrc_4)))));
  assign io_toIssueQueues_32_bits_pdest = (ohSel[32][0] ? io_fromRename_0_bits_pdest : (ohSel[32][1] ? io_fromRename_1_bits_pdest : (ohSel[32][2] ? io_fromRename_2_bits_pdest : (ohSel[32][3] ? io_fromRename_3_bits_pdest : (ohSel[32][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_32_bits_robIdx_flag = (ohSel[32][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[32][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[32][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[32][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[32][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_32_bits_robIdx_value = (ohSel[32][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[32][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[32][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[32][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[32][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  assign io_toIssueQueues_32_bits_lqIdx_flag = (ohSel[32][0] ? _lsqEnqCtrl_io_enq_resp_0_lqIdx_flag : (ohSel[32][1] ? _lsqEnqCtrl_io_enq_resp_1_lqIdx_flag : (ohSel[32][2] ? _lsqEnqCtrl_io_enq_resp_2_lqIdx_flag : (ohSel[32][3] ? _lsqEnqCtrl_io_enq_resp_3_lqIdx_flag : (ohSel[32][4] ? _lsqEnqCtrl_io_enq_resp_4_lqIdx_flag : _lsqEnqCtrl_io_enq_resp_5_lqIdx_flag)))));
  assign io_toIssueQueues_32_bits_lqIdx_value = (ohSel[32][0] ? _lsqEnqCtrl_io_enq_resp_0_lqIdx_value : (ohSel[32][1] ? _lsqEnqCtrl_io_enq_resp_1_lqIdx_value : (ohSel[32][2] ? _lsqEnqCtrl_io_enq_resp_2_lqIdx_value : (ohSel[32][3] ? _lsqEnqCtrl_io_enq_resp_3_lqIdx_value : (ohSel[32][4] ? _lsqEnqCtrl_io_enq_resp_4_lqIdx_value : _lsqEnqCtrl_io_enq_resp_5_lqIdx_value)))));
  assign io_toIssueQueues_32_bits_sqIdx_flag = (ohSel[32][0] ? _lsqEnqCtrl_io_enq_resp_0_sqIdx_flag : (ohSel[32][1] ? _lsqEnqCtrl_io_enq_resp_1_sqIdx_flag : (ohSel[32][2] ? _lsqEnqCtrl_io_enq_resp_2_sqIdx_flag : (ohSel[32][3] ? _lsqEnqCtrl_io_enq_resp_3_sqIdx_flag : (ohSel[32][4] ? _lsqEnqCtrl_io_enq_resp_4_sqIdx_flag : _lsqEnqCtrl_io_enq_resp_5_sqIdx_flag)))));
  assign io_toIssueQueues_32_bits_sqIdx_value = (ohSel[32][0] ? _lsqEnqCtrl_io_enq_resp_0_sqIdx_value : (ohSel[32][1] ? _lsqEnqCtrl_io_enq_resp_1_sqIdx_value : (ohSel[32][2] ? _lsqEnqCtrl_io_enq_resp_2_sqIdx_value : (ohSel[32][3] ? _lsqEnqCtrl_io_enq_resp_3_sqIdx_value : (ohSel[32][4] ? _lsqEnqCtrl_io_enq_resp_4_sqIdx_value : _lsqEnqCtrl_io_enq_resp_5_sqIdx_value)))));
  assign io_toIssueQueues_32_bits_numLsElem = (ohSel[32][0] ? io_fromRename_0_bits_numLsElem : (ohSel[32][1] ? io_fromRename_1_bits_numLsElem : (ohSel[32][2] ? io_fromRename_2_bits_numLsElem : (ohSel[32][3] ? io_fromRename_3_bits_numLsElem : (ohSel[32][4] ? io_fromRename_4_bits_numLsElem : io_fromRename_5_bits_numLsElem)))));
  // -- 端口 33(IQ 16 enq 1)--
  assign io_toIssueQueues_33_valid = (ohSel[33][0] ? fromRenameUpdate_valid[0] : (ohSel[33][1] ? fromRenameUpdate_valid[1] : (ohSel[33][2] ? fromRenameUpdate_valid[2] : (ohSel[33][3] ? fromRenameUpdate_valid[3] : (ohSel[33][4] ? fromRenameUpdate_valid[4] : (ohSel[33][5] ? fromRenameUpdate_valid[5] : 1'b0))))));
  assign io_toIssueQueues_33_bits_ftqPtr_flag = (ohSel[33][0] ? io_fromRename_0_bits_ftqPtr_flag : (ohSel[33][1] ? io_fromRename_1_bits_ftqPtr_flag : (ohSel[33][2] ? io_fromRename_2_bits_ftqPtr_flag : (ohSel[33][3] ? io_fromRename_3_bits_ftqPtr_flag : (ohSel[33][4] ? io_fromRename_4_bits_ftqPtr_flag : io_fromRename_5_bits_ftqPtr_flag)))));
  assign io_toIssueQueues_33_bits_ftqPtr_value = (ohSel[33][0] ? io_fromRename_0_bits_ftqPtr_value : (ohSel[33][1] ? io_fromRename_1_bits_ftqPtr_value : (ohSel[33][2] ? io_fromRename_2_bits_ftqPtr_value : (ohSel[33][3] ? io_fromRename_3_bits_ftqPtr_value : (ohSel[33][4] ? io_fromRename_4_bits_ftqPtr_value : io_fromRename_5_bits_ftqPtr_value)))));
  assign io_toIssueQueues_33_bits_ftqOffset = (ohSel[33][0] ? io_fromRename_0_bits_ftqOffset : (ohSel[33][1] ? io_fromRename_1_bits_ftqOffset : (ohSel[33][2] ? io_fromRename_2_bits_ftqOffset : (ohSel[33][3] ? io_fromRename_3_bits_ftqOffset : (ohSel[33][4] ? io_fromRename_4_bits_ftqOffset : io_fromRename_5_bits_ftqOffset)))));
  assign io_toIssueQueues_33_bits_srcType_0 = (ohSel[33][0] ? io_fromRename_0_bits_srcType_0 : (ohSel[33][1] ? io_fromRename_1_bits_srcType_0 : (ohSel[33][2] ? io_fromRename_2_bits_srcType_0 : (ohSel[33][3] ? io_fromRename_3_bits_srcType_0 : (ohSel[33][4] ? io_fromRename_4_bits_srcType_0 : io_fromRename_5_bits_srcType_0)))));
  assign io_toIssueQueues_33_bits_srcType_1 = (ohSel[33][0] ? io_fromRename_0_bits_srcType_1 : (ohSel[33][1] ? io_fromRename_1_bits_srcType_1 : (ohSel[33][2] ? io_fromRename_2_bits_srcType_1 : (ohSel[33][3] ? io_fromRename_3_bits_srcType_1 : (ohSel[33][4] ? io_fromRename_4_bits_srcType_1 : io_fromRename_5_bits_srcType_1)))));
  assign io_toIssueQueues_33_bits_srcType_2 = (ohSel[33][0] ? fru_srcType2[0] : (ohSel[33][1] ? fru_srcType2[1] : (ohSel[33][2] ? fru_srcType2[2] : (ohSel[33][3] ? fru_srcType2[3] : (ohSel[33][4] ? fru_srcType2[4] : fru_srcType2[5])))));
  assign io_toIssueQueues_33_bits_srcType_3 = (ohSel[33][0] ? io_fromRename_0_bits_srcType_3 : (ohSel[33][1] ? io_fromRename_1_bits_srcType_3 : (ohSel[33][2] ? io_fromRename_2_bits_srcType_3 : (ohSel[33][3] ? io_fromRename_3_bits_srcType_3 : (ohSel[33][4] ? io_fromRename_4_bits_srcType_3 : io_fromRename_5_bits_srcType_3)))));
  assign io_toIssueQueues_33_bits_srcType_4 = (ohSel[33][0] ? io_fromRename_0_bits_srcType_4 : (ohSel[33][1] ? io_fromRename_1_bits_srcType_4 : (ohSel[33][2] ? io_fromRename_2_bits_srcType_4 : (ohSel[33][3] ? io_fromRename_3_bits_srcType_4 : (ohSel[33][4] ? io_fromRename_4_bits_srcType_4 : io_fromRename_5_bits_srcType_4)))));
  assign io_toIssueQueues_33_bits_fuType = (ohSel[33][0] ? io_fromRename_0_bits_fuType : (ohSel[33][1] ? io_fromRename_1_bits_fuType : (ohSel[33][2] ? io_fromRename_2_bits_fuType : (ohSel[33][3] ? io_fromRename_3_bits_fuType : (ohSel[33][4] ? io_fromRename_4_bits_fuType : io_fromRename_5_bits_fuType)))));
  assign io_toIssueQueues_33_bits_fuOpType = (ohSel[33][0] ? io_fromRename_0_bits_fuOpType : (ohSel[33][1] ? io_fromRename_1_bits_fuOpType : (ohSel[33][2] ? io_fromRename_2_bits_fuOpType : (ohSel[33][3] ? io_fromRename_3_bits_fuOpType : (ohSel[33][4] ? io_fromRename_4_bits_fuOpType : io_fromRename_5_bits_fuOpType)))));
  assign io_toIssueQueues_33_bits_vecWen = (ohSel[33][0] ? io_fromRename_0_bits_vecWen : (ohSel[33][1] ? io_fromRename_1_bits_vecWen : (ohSel[33][2] ? io_fromRename_2_bits_vecWen : (ohSel[33][3] ? io_fromRename_3_bits_vecWen : (ohSel[33][4] ? io_fromRename_4_bits_vecWen : io_fromRename_5_bits_vecWen)))));
  assign io_toIssueQueues_33_bits_v0Wen = (ohSel[33][0] ? io_fromRename_0_bits_v0Wen : (ohSel[33][1] ? io_fromRename_1_bits_v0Wen : (ohSel[33][2] ? io_fromRename_2_bits_v0Wen : (ohSel[33][3] ? io_fromRename_3_bits_v0Wen : (ohSel[33][4] ? io_fromRename_4_bits_v0Wen : io_fromRename_5_bits_v0Wen)))));
  assign io_toIssueQueues_33_bits_vlWen = (ohSel[33][0] ? io_fromRename_0_bits_vlWen : (ohSel[33][1] ? io_fromRename_1_bits_vlWen : (ohSel[33][2] ? io_fromRename_2_bits_vlWen : (ohSel[33][3] ? io_fromRename_3_bits_vlWen : (ohSel[33][4] ? io_fromRename_4_bits_vlWen : io_fromRename_5_bits_vlWen)))));
  assign io_toIssueQueues_33_bits_vpu_vma = (ohSel[33][0] ? io_fromRename_0_bits_vpu_vma : (ohSel[33][1] ? io_fromRename_1_bits_vpu_vma : (ohSel[33][2] ? io_fromRename_2_bits_vpu_vma : (ohSel[33][3] ? io_fromRename_3_bits_vpu_vma : (ohSel[33][4] ? io_fromRename_4_bits_vpu_vma : io_fromRename_5_bits_vpu_vma)))));
  assign io_toIssueQueues_33_bits_vpu_vta = (ohSel[33][0] ? io_fromRename_0_bits_vpu_vta : (ohSel[33][1] ? io_fromRename_1_bits_vpu_vta : (ohSel[33][2] ? io_fromRename_2_bits_vpu_vta : (ohSel[33][3] ? io_fromRename_3_bits_vpu_vta : (ohSel[33][4] ? io_fromRename_4_bits_vpu_vta : io_fromRename_5_bits_vpu_vta)))));
  assign io_toIssueQueues_33_bits_vpu_vsew = (ohSel[33][0] ? io_fromRename_0_bits_vpu_vsew : (ohSel[33][1] ? io_fromRename_1_bits_vpu_vsew : (ohSel[33][2] ? io_fromRename_2_bits_vpu_vsew : (ohSel[33][3] ? io_fromRename_3_bits_vpu_vsew : (ohSel[33][4] ? io_fromRename_4_bits_vpu_vsew : io_fromRename_5_bits_vpu_vsew)))));
  assign io_toIssueQueues_33_bits_vpu_vlmul = (ohSel[33][0] ? io_fromRename_0_bits_vpu_vlmul : (ohSel[33][1] ? io_fromRename_1_bits_vpu_vlmul : (ohSel[33][2] ? io_fromRename_2_bits_vpu_vlmul : (ohSel[33][3] ? io_fromRename_3_bits_vpu_vlmul : (ohSel[33][4] ? io_fromRename_4_bits_vpu_vlmul : io_fromRename_5_bits_vpu_vlmul)))));
  assign io_toIssueQueues_33_bits_vpu_vm = (ohSel[33][0] ? io_fromRename_0_bits_vpu_vm : (ohSel[33][1] ? io_fromRename_1_bits_vpu_vm : (ohSel[33][2] ? io_fromRename_2_bits_vpu_vm : (ohSel[33][3] ? io_fromRename_3_bits_vpu_vm : (ohSel[33][4] ? io_fromRename_4_bits_vpu_vm : io_fromRename_5_bits_vpu_vm)))));
  assign io_toIssueQueues_33_bits_vpu_vstart = (ohSel[33][0] ? io_fromRename_0_bits_vpu_vstart : (ohSel[33][1] ? io_fromRename_1_bits_vpu_vstart : (ohSel[33][2] ? io_fromRename_2_bits_vpu_vstart : (ohSel[33][3] ? io_fromRename_3_bits_vpu_vstart : (ohSel[33][4] ? io_fromRename_4_bits_vpu_vstart : io_fromRename_5_bits_vpu_vstart)))));
  assign io_toIssueQueues_33_bits_vpu_vmask = (ohSel[33][0] ? io_fromRename_0_bits_vpu_vmask : (ohSel[33][1] ? io_fromRename_1_bits_vpu_vmask : (ohSel[33][2] ? io_fromRename_2_bits_vpu_vmask : (ohSel[33][3] ? io_fromRename_3_bits_vpu_vmask : (ohSel[33][4] ? io_fromRename_4_bits_vpu_vmask : io_fromRename_5_bits_vpu_vmask)))));
  assign io_toIssueQueues_33_bits_vpu_nf = (ohSel[33][0] ? io_fromRename_0_bits_vpu_nf : (ohSel[33][1] ? io_fromRename_1_bits_vpu_nf : (ohSel[33][2] ? io_fromRename_2_bits_vpu_nf : (ohSel[33][3] ? io_fromRename_3_bits_vpu_nf : (ohSel[33][4] ? io_fromRename_4_bits_vpu_nf : io_fromRename_5_bits_vpu_nf)))));
  assign io_toIssueQueues_33_bits_vpu_veew = (ohSel[33][0] ? io_fromRename_0_bits_vpu_veew : (ohSel[33][1] ? io_fromRename_1_bits_vpu_veew : (ohSel[33][2] ? io_fromRename_2_bits_vpu_veew : (ohSel[33][3] ? io_fromRename_3_bits_vpu_veew : (ohSel[33][4] ? io_fromRename_4_bits_vpu_veew : io_fromRename_5_bits_vpu_veew)))));
  assign io_toIssueQueues_33_bits_vpu_isDependOldVd = (ohSel[33][0] ? io_fromRename_0_bits_vpu_isDependOldVd : (ohSel[33][1] ? io_fromRename_1_bits_vpu_isDependOldVd : (ohSel[33][2] ? io_fromRename_2_bits_vpu_isDependOldVd : (ohSel[33][3] ? io_fromRename_3_bits_vpu_isDependOldVd : (ohSel[33][4] ? io_fromRename_4_bits_vpu_isDependOldVd : io_fromRename_5_bits_vpu_isDependOldVd)))));
  assign io_toIssueQueues_33_bits_vpu_isWritePartVd = (ohSel[33][0] ? io_fromRename_0_bits_vpu_isWritePartVd : (ohSel[33][1] ? io_fromRename_1_bits_vpu_isWritePartVd : (ohSel[33][2] ? io_fromRename_2_bits_vpu_isWritePartVd : (ohSel[33][3] ? io_fromRename_3_bits_vpu_isWritePartVd : (ohSel[33][4] ? io_fromRename_4_bits_vpu_isWritePartVd : io_fromRename_5_bits_vpu_isWritePartVd)))));
  assign io_toIssueQueues_33_bits_vpu_isVleff = (ohSel[33][0] ? io_fromRename_0_bits_vpu_isVleff : (ohSel[33][1] ? io_fromRename_1_bits_vpu_isVleff : (ohSel[33][2] ? io_fromRename_2_bits_vpu_isVleff : (ohSel[33][3] ? io_fromRename_3_bits_vpu_isVleff : (ohSel[33][4] ? io_fromRename_4_bits_vpu_isVleff : io_fromRename_5_bits_vpu_isVleff)))));
  assign io_toIssueQueues_33_bits_uopIdx = (ohSel[33][0] ? io_fromRename_0_bits_uopIdx : (ohSel[33][1] ? io_fromRename_1_bits_uopIdx : (ohSel[33][2] ? io_fromRename_2_bits_uopIdx : (ohSel[33][3] ? io_fromRename_3_bits_uopIdx : (ohSel[33][4] ? io_fromRename_4_bits_uopIdx : io_fromRename_5_bits_uopIdx)))));
  assign io_toIssueQueues_33_bits_lastUop = (ohSel[33][0] ? io_fromRename_0_bits_lastUop : (ohSel[33][1] ? io_fromRename_1_bits_lastUop : (ohSel[33][2] ? io_fromRename_2_bits_lastUop : (ohSel[33][3] ? io_fromRename_3_bits_lastUop : (ohSel[33][4] ? io_fromRename_4_bits_lastUop : io_fromRename_5_bits_lastUop)))));
  assign io_toIssueQueues_33_bits_srcState_0 = (ohSel[33][0] ? (allSrcState[0][0][2]) : (ohSel[33][1] ? (allSrcState[1][0][2]) : (ohSel[33][2] ? (allSrcState[2][0][2]) : (ohSel[33][3] ? (allSrcState[3][0][2]) : (ohSel[33][4] ? (allSrcState[4][0][2]) : (allSrcState[5][0][2]))))));
  assign io_toIssueQueues_33_bits_srcState_1 = (ohSel[33][0] ? (allSrcState[0][1][2]) : (ohSel[33][1] ? (allSrcState[1][1][2]) : (ohSel[33][2] ? (allSrcState[2][1][2]) : (ohSel[33][3] ? (allSrcState[3][1][2]) : (ohSel[33][4] ? (allSrcState[4][1][2]) : (allSrcState[5][1][2]))))));
  assign io_toIssueQueues_33_bits_srcState_2 = (ohSel[33][0] ? (allSrcState[0][2][2]) : (ohSel[33][1] ? (allSrcState[1][2][2]) : (ohSel[33][2] ? (allSrcState[2][2][2]) : (ohSel[33][3] ? (allSrcState[3][2][2]) : (ohSel[33][4] ? (allSrcState[4][2][2]) : (allSrcState[5][2][2]))))));
  assign io_toIssueQueues_33_bits_srcState_3 = (ohSel[33][0] ? (allSrcState[0][3][3]) : (ohSel[33][1] ? (allSrcState[1][3][3]) : (ohSel[33][2] ? (allSrcState[2][3][3]) : (ohSel[33][3] ? (allSrcState[3][3][3]) : (ohSel[33][4] ? (allSrcState[4][3][3]) : (allSrcState[5][3][3]))))));
  assign io_toIssueQueues_33_bits_srcState_4 = (ohSel[33][0] ? (allSrcState[0][4][4]) : (ohSel[33][1] ? (allSrcState[1][4][4]) : (ohSel[33][2] ? (allSrcState[2][4][4]) : (ohSel[33][3] ? (allSrcState[3][4][4]) : (ohSel[33][4] ? (allSrcState[4][4][4]) : (allSrcState[5][4][4]))))));
  assign io_toIssueQueues_33_bits_psrc_0 = (ohSel[33][0] ? io_fromRename_0_bits_psrc_0 : (ohSel[33][1] ? io_fromRename_1_bits_psrc_0 : (ohSel[33][2] ? io_fromRename_2_bits_psrc_0 : (ohSel[33][3] ? io_fromRename_3_bits_psrc_0 : (ohSel[33][4] ? io_fromRename_4_bits_psrc_0 : io_fromRename_5_bits_psrc_0)))));
  assign io_toIssueQueues_33_bits_psrc_1 = (ohSel[33][0] ? io_fromRename_0_bits_psrc_1 : (ohSel[33][1] ? io_fromRename_1_bits_psrc_1 : (ohSel[33][2] ? io_fromRename_2_bits_psrc_1 : (ohSel[33][3] ? io_fromRename_3_bits_psrc_1 : (ohSel[33][4] ? io_fromRename_4_bits_psrc_1 : io_fromRename_5_bits_psrc_1)))));
  assign io_toIssueQueues_33_bits_psrc_2 = (ohSel[33][0] ? io_fromRename_0_bits_psrc_2 : (ohSel[33][1] ? io_fromRename_1_bits_psrc_2 : (ohSel[33][2] ? io_fromRename_2_bits_psrc_2 : (ohSel[33][3] ? io_fromRename_3_bits_psrc_2 : (ohSel[33][4] ? io_fromRename_4_bits_psrc_2 : io_fromRename_5_bits_psrc_2)))));
  assign io_toIssueQueues_33_bits_psrc_3 = (ohSel[33][0] ? io_fromRename_0_bits_psrc_3 : (ohSel[33][1] ? io_fromRename_1_bits_psrc_3 : (ohSel[33][2] ? io_fromRename_2_bits_psrc_3 : (ohSel[33][3] ? io_fromRename_3_bits_psrc_3 : (ohSel[33][4] ? io_fromRename_4_bits_psrc_3 : io_fromRename_5_bits_psrc_3)))));
  assign io_toIssueQueues_33_bits_psrc_4 = (ohSel[33][0] ? io_fromRename_0_bits_psrc_4 : (ohSel[33][1] ? io_fromRename_1_bits_psrc_4 : (ohSel[33][2] ? io_fromRename_2_bits_psrc_4 : (ohSel[33][3] ? io_fromRename_3_bits_psrc_4 : (ohSel[33][4] ? io_fromRename_4_bits_psrc_4 : io_fromRename_5_bits_psrc_4)))));
  assign io_toIssueQueues_33_bits_pdest = (ohSel[33][0] ? io_fromRename_0_bits_pdest : (ohSel[33][1] ? io_fromRename_1_bits_pdest : (ohSel[33][2] ? io_fromRename_2_bits_pdest : (ohSel[33][3] ? io_fromRename_3_bits_pdest : (ohSel[33][4] ? io_fromRename_4_bits_pdest : io_fromRename_5_bits_pdest)))));
  assign io_toIssueQueues_33_bits_robIdx_flag = (ohSel[33][0] ? io_fromRename_0_bits_robIdx_flag : (ohSel[33][1] ? io_fromRename_1_bits_robIdx_flag : (ohSel[33][2] ? io_fromRename_2_bits_robIdx_flag : (ohSel[33][3] ? io_fromRename_3_bits_robIdx_flag : (ohSel[33][4] ? io_fromRename_4_bits_robIdx_flag : io_fromRename_5_bits_robIdx_flag)))));
  assign io_toIssueQueues_33_bits_robIdx_value = (ohSel[33][0] ? io_fromRename_0_bits_robIdx_value : (ohSel[33][1] ? io_fromRename_1_bits_robIdx_value : (ohSel[33][2] ? io_fromRename_2_bits_robIdx_value : (ohSel[33][3] ? io_fromRename_3_bits_robIdx_value : (ohSel[33][4] ? io_fromRename_4_bits_robIdx_value : io_fromRename_5_bits_robIdx_value)))));
  assign io_toIssueQueues_33_bits_lqIdx_flag = (ohSel[33][0] ? _lsqEnqCtrl_io_enq_resp_0_lqIdx_flag : (ohSel[33][1] ? _lsqEnqCtrl_io_enq_resp_1_lqIdx_flag : (ohSel[33][2] ? _lsqEnqCtrl_io_enq_resp_2_lqIdx_flag : (ohSel[33][3] ? _lsqEnqCtrl_io_enq_resp_3_lqIdx_flag : (ohSel[33][4] ? _lsqEnqCtrl_io_enq_resp_4_lqIdx_flag : _lsqEnqCtrl_io_enq_resp_5_lqIdx_flag)))));
  assign io_toIssueQueues_33_bits_lqIdx_value = (ohSel[33][0] ? _lsqEnqCtrl_io_enq_resp_0_lqIdx_value : (ohSel[33][1] ? _lsqEnqCtrl_io_enq_resp_1_lqIdx_value : (ohSel[33][2] ? _lsqEnqCtrl_io_enq_resp_2_lqIdx_value : (ohSel[33][3] ? _lsqEnqCtrl_io_enq_resp_3_lqIdx_value : (ohSel[33][4] ? _lsqEnqCtrl_io_enq_resp_4_lqIdx_value : _lsqEnqCtrl_io_enq_resp_5_lqIdx_value)))));
  assign io_toIssueQueues_33_bits_sqIdx_flag = (ohSel[33][0] ? _lsqEnqCtrl_io_enq_resp_0_sqIdx_flag : (ohSel[33][1] ? _lsqEnqCtrl_io_enq_resp_1_sqIdx_flag : (ohSel[33][2] ? _lsqEnqCtrl_io_enq_resp_2_sqIdx_flag : (ohSel[33][3] ? _lsqEnqCtrl_io_enq_resp_3_sqIdx_flag : (ohSel[33][4] ? _lsqEnqCtrl_io_enq_resp_4_sqIdx_flag : _lsqEnqCtrl_io_enq_resp_5_sqIdx_flag)))));
  assign io_toIssueQueues_33_bits_sqIdx_value = (ohSel[33][0] ? _lsqEnqCtrl_io_enq_resp_0_sqIdx_value : (ohSel[33][1] ? _lsqEnqCtrl_io_enq_resp_1_sqIdx_value : (ohSel[33][2] ? _lsqEnqCtrl_io_enq_resp_2_sqIdx_value : (ohSel[33][3] ? _lsqEnqCtrl_io_enq_resp_3_sqIdx_value : (ohSel[33][4] ? _lsqEnqCtrl_io_enq_resp_4_sqIdx_value : _lsqEnqCtrl_io_enq_resp_5_sqIdx_value)))));
  assign io_toIssueQueues_33_bits_numLsElem = (ohSel[33][0] ? io_fromRename_0_bits_numLsElem : (ohSel[33][1] ? io_fromRename_1_bits_numLsElem : (ohSel[33][2] ? io_fromRename_2_bits_numLsElem : (ohSel[33][3] ? io_fromRename_3_bits_numLsElem : (ohSel[33][4] ? io_fromRename_4_bits_numLsElem : io_fromRename_5_bits_numLsElem)))));

  // ---- enqRob.req 直通字段 + toRenameAllFire(计算字段已在 logic)----
  assign io_enqRob_req_0_bits_instr = io_fromRename_0_bits_instr;
  assign io_enqRob_req_0_bits_exceptionVec_0 = io_fromRename_0_bits_exceptionVec_0;
  assign io_enqRob_req_0_bits_exceptionVec_1 = io_fromRename_0_bits_exceptionVec_1;
  assign io_enqRob_req_0_bits_exceptionVec_2 = io_fromRename_0_bits_exceptionVec_2;
  assign io_enqRob_req_0_bits_exceptionVec_3 = io_fromRename_0_bits_exceptionVec_3;
  assign io_enqRob_req_0_bits_exceptionVec_12 = io_fromRename_0_bits_exceptionVec_12;
  assign io_enqRob_req_0_bits_exceptionVec_20 = io_fromRename_0_bits_exceptionVec_20;
  assign io_enqRob_req_0_bits_exceptionVec_22 = io_fromRename_0_bits_exceptionVec_22;
  assign io_enqRob_req_0_bits_isFetchMalAddr = io_fromRename_0_bits_isFetchMalAddr;
  assign io_enqRob_req_0_bits_trigger = io_fromRename_0_bits_trigger;
  assign io_enqRob_req_0_bits_preDecodeInfo_isRVC = io_fromRename_0_bits_preDecodeInfo_isRVC;
  assign io_enqRob_req_0_bits_crossPageIPFFix = io_fromRename_0_bits_crossPageIPFFix;
  assign io_enqRob_req_0_bits_ftqPtr_flag = io_fromRename_0_bits_ftqPtr_flag;
  assign io_enqRob_req_0_bits_ftqPtr_value = io_fromRename_0_bits_ftqPtr_value;
  assign io_enqRob_req_0_bits_ftqOffset = io_fromRename_0_bits_ftqOffset;
  assign io_enqRob_req_0_bits_ldest = io_fromRename_0_bits_ldest;
  assign io_enqRob_req_0_bits_fuType = io_fromRename_0_bits_fuType;
  assign io_enqRob_req_0_bits_fuOpType = io_fromRename_0_bits_fuOpType;
  assign io_enqRob_req_0_bits_rfWen = io_fromRename_0_bits_rfWen;
  assign io_enqRob_req_0_bits_fpWen = io_fromRename_0_bits_fpWen;
  assign io_enqRob_req_0_bits_vecWen = io_fromRename_0_bits_vecWen;
  assign io_enqRob_req_0_bits_v0Wen = io_fromRename_0_bits_v0Wen;
  assign io_enqRob_req_0_bits_vlWen = io_fromRename_0_bits_vlWen;
  assign io_enqRob_req_0_bits_isXSTrap = io_fromRename_0_bits_isXSTrap;
  assign io_enqRob_req_0_bits_waitForward = io_fromRename_0_bits_waitForward;
  assign io_enqRob_req_0_bits_blockBackward = io_fromRename_0_bits_blockBackward;
  assign io_enqRob_req_0_bits_flushPipe = io_fromRename_0_bits_flushPipe;
  assign io_enqRob_req_0_bits_vpu_vill = io_fromRename_0_bits_vpu_vill;
  assign io_enqRob_req_0_bits_vpu_vma = io_fromRename_0_bits_vpu_vma;
  assign io_enqRob_req_0_bits_vpu_vta = io_fromRename_0_bits_vpu_vta;
  assign io_enqRob_req_0_bits_vpu_vsew = io_fromRename_0_bits_vpu_vsew;
  assign io_enqRob_req_0_bits_vpu_vlmul = io_fromRename_0_bits_vpu_vlmul;
  assign io_enqRob_req_0_bits_vpu_specVill = io_fromRename_0_bits_vpu_specVill;
  assign io_enqRob_req_0_bits_vpu_specVma = io_fromRename_0_bits_vpu_specVma;
  assign io_enqRob_req_0_bits_vpu_specVta = io_fromRename_0_bits_vpu_specVta;
  assign io_enqRob_req_0_bits_vpu_specVsew = io_fromRename_0_bits_vpu_specVsew;
  assign io_enqRob_req_0_bits_vpu_specVlmul = io_fromRename_0_bits_vpu_specVlmul;
  assign io_enqRob_req_0_bits_vlsInstr = io_fromRename_0_bits_vlsInstr;
  assign io_enqRob_req_0_bits_wfflags = io_fromRename_0_bits_wfflags;
  assign io_enqRob_req_0_bits_isMove = io_fromRename_0_bits_isMove;
  assign io_enqRob_req_0_bits_isVset = io_fromRename_0_bits_isVset;
  assign io_enqRob_req_0_bits_firstUop = io_fromRename_0_bits_firstUop;
  assign io_enqRob_req_0_bits_lastUop = io_fromRename_0_bits_lastUop;
  assign io_enqRob_req_0_bits_commitType = io_fromRename_0_bits_commitType;
  assign io_enqRob_req_0_bits_pdest = io_fromRename_0_bits_pdest;
  assign io_enqRob_req_0_bits_robIdx_flag = io_fromRename_0_bits_robIdx_flag;
  assign io_enqRob_req_0_bits_robIdx_value = io_fromRename_0_bits_robIdx_value;
  assign io_enqRob_req_0_bits_instrSize = io_fromRename_0_bits_instrSize;
  assign io_enqRob_req_0_bits_dirtyFs = io_fromRename_0_bits_dirtyFs;
  assign io_enqRob_req_0_bits_dirtyVs = io_fromRename_0_bits_dirtyVs;
  assign io_enqRob_req_0_bits_traceBlockInPipe_itype = io_fromRename_0_bits_traceBlockInPipe_itype;
  assign io_enqRob_req_0_bits_traceBlockInPipe_iretire = io_fromRename_0_bits_traceBlockInPipe_iretire;
  assign io_enqRob_req_0_bits_traceBlockInPipe_ilastsize = io_fromRename_0_bits_traceBlockInPipe_ilastsize;
  assign io_enqRob_req_0_bits_eliminatedMove = io_fromRename_0_bits_eliminatedMove;
  assign io_enqRob_req_0_bits_snapshot = io_fromRename_0_bits_snapshot;
  assign io_enqRob_req_0_bits_debugInfo_renameTime = io_fromRename_0_bits_debugInfo_renameTime;
  assign io_enqRob_req_1_bits_instr = io_fromRename_1_bits_instr;
  assign io_enqRob_req_1_bits_exceptionVec_0 = io_fromRename_1_bits_exceptionVec_0;
  assign io_enqRob_req_1_bits_exceptionVec_1 = io_fromRename_1_bits_exceptionVec_1;
  assign io_enqRob_req_1_bits_exceptionVec_2 = io_fromRename_1_bits_exceptionVec_2;
  assign io_enqRob_req_1_bits_exceptionVec_3 = io_fromRename_1_bits_exceptionVec_3;
  assign io_enqRob_req_1_bits_exceptionVec_12 = io_fromRename_1_bits_exceptionVec_12;
  assign io_enqRob_req_1_bits_exceptionVec_20 = io_fromRename_1_bits_exceptionVec_20;
  assign io_enqRob_req_1_bits_exceptionVec_22 = io_fromRename_1_bits_exceptionVec_22;
  assign io_enqRob_req_1_bits_isFetchMalAddr = io_fromRename_1_bits_isFetchMalAddr;
  assign io_enqRob_req_1_bits_trigger = io_fromRename_1_bits_trigger;
  assign io_enqRob_req_1_bits_preDecodeInfo_isRVC = io_fromRename_1_bits_preDecodeInfo_isRVC;
  assign io_enqRob_req_1_bits_crossPageIPFFix = io_fromRename_1_bits_crossPageIPFFix;
  assign io_enqRob_req_1_bits_ftqPtr_flag = io_fromRename_1_bits_ftqPtr_flag;
  assign io_enqRob_req_1_bits_ftqPtr_value = io_fromRename_1_bits_ftqPtr_value;
  assign io_enqRob_req_1_bits_ftqOffset = io_fromRename_1_bits_ftqOffset;
  assign io_enqRob_req_1_bits_ldest = io_fromRename_1_bits_ldest;
  assign io_enqRob_req_1_bits_fuType = io_fromRename_1_bits_fuType;
  assign io_enqRob_req_1_bits_fuOpType = io_fromRename_1_bits_fuOpType;
  assign io_enqRob_req_1_bits_rfWen = io_fromRename_1_bits_rfWen;
  assign io_enqRob_req_1_bits_fpWen = io_fromRename_1_bits_fpWen;
  assign io_enqRob_req_1_bits_vecWen = io_fromRename_1_bits_vecWen;
  assign io_enqRob_req_1_bits_v0Wen = io_fromRename_1_bits_v0Wen;
  assign io_enqRob_req_1_bits_vlWen = io_fromRename_1_bits_vlWen;
  assign io_enqRob_req_1_bits_isXSTrap = io_fromRename_1_bits_isXSTrap;
  assign io_enqRob_req_1_bits_waitForward = io_fromRename_1_bits_waitForward;
  assign io_enqRob_req_1_bits_blockBackward = io_fromRename_1_bits_blockBackward;
  assign io_enqRob_req_1_bits_flushPipe = io_fromRename_1_bits_flushPipe;
  assign io_enqRob_req_1_bits_vpu_vill = io_fromRename_1_bits_vpu_vill;
  assign io_enqRob_req_1_bits_vpu_vma = io_fromRename_1_bits_vpu_vma;
  assign io_enqRob_req_1_bits_vpu_vta = io_fromRename_1_bits_vpu_vta;
  assign io_enqRob_req_1_bits_vpu_vsew = io_fromRename_1_bits_vpu_vsew;
  assign io_enqRob_req_1_bits_vpu_vlmul = io_fromRename_1_bits_vpu_vlmul;
  assign io_enqRob_req_1_bits_vpu_specVill = io_fromRename_1_bits_vpu_specVill;
  assign io_enqRob_req_1_bits_vpu_specVma = io_fromRename_1_bits_vpu_specVma;
  assign io_enqRob_req_1_bits_vpu_specVta = io_fromRename_1_bits_vpu_specVta;
  assign io_enqRob_req_1_bits_vpu_specVsew = io_fromRename_1_bits_vpu_specVsew;
  assign io_enqRob_req_1_bits_vpu_specVlmul = io_fromRename_1_bits_vpu_specVlmul;
  assign io_enqRob_req_1_bits_vlsInstr = io_fromRename_1_bits_vlsInstr;
  assign io_enqRob_req_1_bits_wfflags = io_fromRename_1_bits_wfflags;
  assign io_enqRob_req_1_bits_isMove = io_fromRename_1_bits_isMove;
  assign io_enqRob_req_1_bits_isVset = io_fromRename_1_bits_isVset;
  assign io_enqRob_req_1_bits_firstUop = io_fromRename_1_bits_firstUop;
  assign io_enqRob_req_1_bits_lastUop = io_fromRename_1_bits_lastUop;
  assign io_enqRob_req_1_bits_commitType = io_fromRename_1_bits_commitType;
  assign io_enqRob_req_1_bits_pdest = io_fromRename_1_bits_pdest;
  assign io_enqRob_req_1_bits_robIdx_flag = io_fromRename_1_bits_robIdx_flag;
  assign io_enqRob_req_1_bits_robIdx_value = io_fromRename_1_bits_robIdx_value;
  assign io_enqRob_req_1_bits_instrSize = io_fromRename_1_bits_instrSize;
  assign io_enqRob_req_1_bits_dirtyFs = io_fromRename_1_bits_dirtyFs;
  assign io_enqRob_req_1_bits_dirtyVs = io_fromRename_1_bits_dirtyVs;
  assign io_enqRob_req_1_bits_traceBlockInPipe_itype = io_fromRename_1_bits_traceBlockInPipe_itype;
  assign io_enqRob_req_1_bits_traceBlockInPipe_iretire = io_fromRename_1_bits_traceBlockInPipe_iretire;
  assign io_enqRob_req_1_bits_traceBlockInPipe_ilastsize = io_fromRename_1_bits_traceBlockInPipe_ilastsize;
  assign io_enqRob_req_1_bits_eliminatedMove = io_fromRename_1_bits_eliminatedMove;
  assign io_enqRob_req_1_bits_debugInfo_renameTime = io_fromRename_1_bits_debugInfo_renameTime;
  assign io_enqRob_req_2_bits_instr = io_fromRename_2_bits_instr;
  assign io_enqRob_req_2_bits_exceptionVec_0 = io_fromRename_2_bits_exceptionVec_0;
  assign io_enqRob_req_2_bits_exceptionVec_1 = io_fromRename_2_bits_exceptionVec_1;
  assign io_enqRob_req_2_bits_exceptionVec_2 = io_fromRename_2_bits_exceptionVec_2;
  assign io_enqRob_req_2_bits_exceptionVec_3 = io_fromRename_2_bits_exceptionVec_3;
  assign io_enqRob_req_2_bits_exceptionVec_12 = io_fromRename_2_bits_exceptionVec_12;
  assign io_enqRob_req_2_bits_exceptionVec_20 = io_fromRename_2_bits_exceptionVec_20;
  assign io_enqRob_req_2_bits_exceptionVec_22 = io_fromRename_2_bits_exceptionVec_22;
  assign io_enqRob_req_2_bits_isFetchMalAddr = io_fromRename_2_bits_isFetchMalAddr;
  assign io_enqRob_req_2_bits_trigger = io_fromRename_2_bits_trigger;
  assign io_enqRob_req_2_bits_preDecodeInfo_isRVC = io_fromRename_2_bits_preDecodeInfo_isRVC;
  assign io_enqRob_req_2_bits_crossPageIPFFix = io_fromRename_2_bits_crossPageIPFFix;
  assign io_enqRob_req_2_bits_ftqPtr_flag = io_fromRename_2_bits_ftqPtr_flag;
  assign io_enqRob_req_2_bits_ftqPtr_value = io_fromRename_2_bits_ftqPtr_value;
  assign io_enqRob_req_2_bits_ftqOffset = io_fromRename_2_bits_ftqOffset;
  assign io_enqRob_req_2_bits_ldest = io_fromRename_2_bits_ldest;
  assign io_enqRob_req_2_bits_fuType = io_fromRename_2_bits_fuType;
  assign io_enqRob_req_2_bits_fuOpType = io_fromRename_2_bits_fuOpType;
  assign io_enqRob_req_2_bits_rfWen = io_fromRename_2_bits_rfWen;
  assign io_enqRob_req_2_bits_fpWen = io_fromRename_2_bits_fpWen;
  assign io_enqRob_req_2_bits_vecWen = io_fromRename_2_bits_vecWen;
  assign io_enqRob_req_2_bits_v0Wen = io_fromRename_2_bits_v0Wen;
  assign io_enqRob_req_2_bits_vlWen = io_fromRename_2_bits_vlWen;
  assign io_enqRob_req_2_bits_isXSTrap = io_fromRename_2_bits_isXSTrap;
  assign io_enqRob_req_2_bits_waitForward = io_fromRename_2_bits_waitForward;
  assign io_enqRob_req_2_bits_blockBackward = io_fromRename_2_bits_blockBackward;
  assign io_enqRob_req_2_bits_flushPipe = io_fromRename_2_bits_flushPipe;
  assign io_enqRob_req_2_bits_vpu_vill = io_fromRename_2_bits_vpu_vill;
  assign io_enqRob_req_2_bits_vpu_vma = io_fromRename_2_bits_vpu_vma;
  assign io_enqRob_req_2_bits_vpu_vta = io_fromRename_2_bits_vpu_vta;
  assign io_enqRob_req_2_bits_vpu_vsew = io_fromRename_2_bits_vpu_vsew;
  assign io_enqRob_req_2_bits_vpu_vlmul = io_fromRename_2_bits_vpu_vlmul;
  assign io_enqRob_req_2_bits_vpu_specVill = io_fromRename_2_bits_vpu_specVill;
  assign io_enqRob_req_2_bits_vpu_specVma = io_fromRename_2_bits_vpu_specVma;
  assign io_enqRob_req_2_bits_vpu_specVta = io_fromRename_2_bits_vpu_specVta;
  assign io_enqRob_req_2_bits_vpu_specVsew = io_fromRename_2_bits_vpu_specVsew;
  assign io_enqRob_req_2_bits_vpu_specVlmul = io_fromRename_2_bits_vpu_specVlmul;
  assign io_enqRob_req_2_bits_vlsInstr = io_fromRename_2_bits_vlsInstr;
  assign io_enqRob_req_2_bits_wfflags = io_fromRename_2_bits_wfflags;
  assign io_enqRob_req_2_bits_isMove = io_fromRename_2_bits_isMove;
  assign io_enqRob_req_2_bits_isVset = io_fromRename_2_bits_isVset;
  assign io_enqRob_req_2_bits_firstUop = io_fromRename_2_bits_firstUop;
  assign io_enqRob_req_2_bits_lastUop = io_fromRename_2_bits_lastUop;
  assign io_enqRob_req_2_bits_commitType = io_fromRename_2_bits_commitType;
  assign io_enqRob_req_2_bits_pdest = io_fromRename_2_bits_pdest;
  assign io_enqRob_req_2_bits_robIdx_flag = io_fromRename_2_bits_robIdx_flag;
  assign io_enqRob_req_2_bits_robIdx_value = io_fromRename_2_bits_robIdx_value;
  assign io_enqRob_req_2_bits_instrSize = io_fromRename_2_bits_instrSize;
  assign io_enqRob_req_2_bits_dirtyFs = io_fromRename_2_bits_dirtyFs;
  assign io_enqRob_req_2_bits_dirtyVs = io_fromRename_2_bits_dirtyVs;
  assign io_enqRob_req_2_bits_traceBlockInPipe_itype = io_fromRename_2_bits_traceBlockInPipe_itype;
  assign io_enqRob_req_2_bits_traceBlockInPipe_iretire = io_fromRename_2_bits_traceBlockInPipe_iretire;
  assign io_enqRob_req_2_bits_traceBlockInPipe_ilastsize = io_fromRename_2_bits_traceBlockInPipe_ilastsize;
  assign io_enqRob_req_2_bits_eliminatedMove = io_fromRename_2_bits_eliminatedMove;
  assign io_enqRob_req_2_bits_debugInfo_renameTime = io_fromRename_2_bits_debugInfo_renameTime;
  assign io_enqRob_req_3_bits_instr = io_fromRename_3_bits_instr;
  assign io_enqRob_req_3_bits_exceptionVec_0 = io_fromRename_3_bits_exceptionVec_0;
  assign io_enqRob_req_3_bits_exceptionVec_1 = io_fromRename_3_bits_exceptionVec_1;
  assign io_enqRob_req_3_bits_exceptionVec_2 = io_fromRename_3_bits_exceptionVec_2;
  assign io_enqRob_req_3_bits_exceptionVec_3 = io_fromRename_3_bits_exceptionVec_3;
  assign io_enqRob_req_3_bits_exceptionVec_12 = io_fromRename_3_bits_exceptionVec_12;
  assign io_enqRob_req_3_bits_exceptionVec_20 = io_fromRename_3_bits_exceptionVec_20;
  assign io_enqRob_req_3_bits_exceptionVec_22 = io_fromRename_3_bits_exceptionVec_22;
  assign io_enqRob_req_3_bits_isFetchMalAddr = io_fromRename_3_bits_isFetchMalAddr;
  assign io_enqRob_req_3_bits_trigger = io_fromRename_3_bits_trigger;
  assign io_enqRob_req_3_bits_preDecodeInfo_isRVC = io_fromRename_3_bits_preDecodeInfo_isRVC;
  assign io_enqRob_req_3_bits_crossPageIPFFix = io_fromRename_3_bits_crossPageIPFFix;
  assign io_enqRob_req_3_bits_ftqPtr_flag = io_fromRename_3_bits_ftqPtr_flag;
  assign io_enqRob_req_3_bits_ftqPtr_value = io_fromRename_3_bits_ftqPtr_value;
  assign io_enqRob_req_3_bits_ftqOffset = io_fromRename_3_bits_ftqOffset;
  assign io_enqRob_req_3_bits_ldest = io_fromRename_3_bits_ldest;
  assign io_enqRob_req_3_bits_fuType = io_fromRename_3_bits_fuType;
  assign io_enqRob_req_3_bits_fuOpType = io_fromRename_3_bits_fuOpType;
  assign io_enqRob_req_3_bits_rfWen = io_fromRename_3_bits_rfWen;
  assign io_enqRob_req_3_bits_fpWen = io_fromRename_3_bits_fpWen;
  assign io_enqRob_req_3_bits_vecWen = io_fromRename_3_bits_vecWen;
  assign io_enqRob_req_3_bits_v0Wen = io_fromRename_3_bits_v0Wen;
  assign io_enqRob_req_3_bits_vlWen = io_fromRename_3_bits_vlWen;
  assign io_enqRob_req_3_bits_isXSTrap = io_fromRename_3_bits_isXSTrap;
  assign io_enqRob_req_3_bits_waitForward = io_fromRename_3_bits_waitForward;
  assign io_enqRob_req_3_bits_blockBackward = io_fromRename_3_bits_blockBackward;
  assign io_enqRob_req_3_bits_flushPipe = io_fromRename_3_bits_flushPipe;
  assign io_enqRob_req_3_bits_vpu_vill = io_fromRename_3_bits_vpu_vill;
  assign io_enqRob_req_3_bits_vpu_vma = io_fromRename_3_bits_vpu_vma;
  assign io_enqRob_req_3_bits_vpu_vta = io_fromRename_3_bits_vpu_vta;
  assign io_enqRob_req_3_bits_vpu_vsew = io_fromRename_3_bits_vpu_vsew;
  assign io_enqRob_req_3_bits_vpu_vlmul = io_fromRename_3_bits_vpu_vlmul;
  assign io_enqRob_req_3_bits_vpu_specVill = io_fromRename_3_bits_vpu_specVill;
  assign io_enqRob_req_3_bits_vpu_specVma = io_fromRename_3_bits_vpu_specVma;
  assign io_enqRob_req_3_bits_vpu_specVta = io_fromRename_3_bits_vpu_specVta;
  assign io_enqRob_req_3_bits_vpu_specVsew = io_fromRename_3_bits_vpu_specVsew;
  assign io_enqRob_req_3_bits_vpu_specVlmul = io_fromRename_3_bits_vpu_specVlmul;
  assign io_enqRob_req_3_bits_vlsInstr = io_fromRename_3_bits_vlsInstr;
  assign io_enqRob_req_3_bits_wfflags = io_fromRename_3_bits_wfflags;
  assign io_enqRob_req_3_bits_isMove = io_fromRename_3_bits_isMove;
  assign io_enqRob_req_3_bits_isVset = io_fromRename_3_bits_isVset;
  assign io_enqRob_req_3_bits_firstUop = io_fromRename_3_bits_firstUop;
  assign io_enqRob_req_3_bits_lastUop = io_fromRename_3_bits_lastUop;
  assign io_enqRob_req_3_bits_commitType = io_fromRename_3_bits_commitType;
  assign io_enqRob_req_3_bits_pdest = io_fromRename_3_bits_pdest;
  assign io_enqRob_req_3_bits_robIdx_flag = io_fromRename_3_bits_robIdx_flag;
  assign io_enqRob_req_3_bits_robIdx_value = io_fromRename_3_bits_robIdx_value;
  assign io_enqRob_req_3_bits_instrSize = io_fromRename_3_bits_instrSize;
  assign io_enqRob_req_3_bits_dirtyFs = io_fromRename_3_bits_dirtyFs;
  assign io_enqRob_req_3_bits_dirtyVs = io_fromRename_3_bits_dirtyVs;
  assign io_enqRob_req_3_bits_traceBlockInPipe_itype = io_fromRename_3_bits_traceBlockInPipe_itype;
  assign io_enqRob_req_3_bits_traceBlockInPipe_iretire = io_fromRename_3_bits_traceBlockInPipe_iretire;
  assign io_enqRob_req_3_bits_traceBlockInPipe_ilastsize = io_fromRename_3_bits_traceBlockInPipe_ilastsize;
  assign io_enqRob_req_3_bits_eliminatedMove = io_fromRename_3_bits_eliminatedMove;
  assign io_enqRob_req_3_bits_debugInfo_renameTime = io_fromRename_3_bits_debugInfo_renameTime;
  assign io_enqRob_req_4_bits_instr = io_fromRename_4_bits_instr;
  assign io_enqRob_req_4_bits_exceptionVec_0 = io_fromRename_4_bits_exceptionVec_0;
  assign io_enqRob_req_4_bits_exceptionVec_1 = io_fromRename_4_bits_exceptionVec_1;
  assign io_enqRob_req_4_bits_exceptionVec_2 = io_fromRename_4_bits_exceptionVec_2;
  assign io_enqRob_req_4_bits_exceptionVec_3 = io_fromRename_4_bits_exceptionVec_3;
  assign io_enqRob_req_4_bits_exceptionVec_12 = io_fromRename_4_bits_exceptionVec_12;
  assign io_enqRob_req_4_bits_exceptionVec_20 = io_fromRename_4_bits_exceptionVec_20;
  assign io_enqRob_req_4_bits_exceptionVec_22 = io_fromRename_4_bits_exceptionVec_22;
  assign io_enqRob_req_4_bits_isFetchMalAddr = io_fromRename_4_bits_isFetchMalAddr;
  assign io_enqRob_req_4_bits_trigger = io_fromRename_4_bits_trigger;
  assign io_enqRob_req_4_bits_preDecodeInfo_isRVC = io_fromRename_4_bits_preDecodeInfo_isRVC;
  assign io_enqRob_req_4_bits_crossPageIPFFix = io_fromRename_4_bits_crossPageIPFFix;
  assign io_enqRob_req_4_bits_ftqPtr_flag = io_fromRename_4_bits_ftqPtr_flag;
  assign io_enqRob_req_4_bits_ftqPtr_value = io_fromRename_4_bits_ftqPtr_value;
  assign io_enqRob_req_4_bits_ftqOffset = io_fromRename_4_bits_ftqOffset;
  assign io_enqRob_req_4_bits_ldest = io_fromRename_4_bits_ldest;
  assign io_enqRob_req_4_bits_fuType = io_fromRename_4_bits_fuType;
  assign io_enqRob_req_4_bits_fuOpType = io_fromRename_4_bits_fuOpType;
  assign io_enqRob_req_4_bits_rfWen = io_fromRename_4_bits_rfWen;
  assign io_enqRob_req_4_bits_fpWen = io_fromRename_4_bits_fpWen;
  assign io_enqRob_req_4_bits_vecWen = io_fromRename_4_bits_vecWen;
  assign io_enqRob_req_4_bits_v0Wen = io_fromRename_4_bits_v0Wen;
  assign io_enqRob_req_4_bits_vlWen = io_fromRename_4_bits_vlWen;
  assign io_enqRob_req_4_bits_isXSTrap = io_fromRename_4_bits_isXSTrap;
  assign io_enqRob_req_4_bits_waitForward = io_fromRename_4_bits_waitForward;
  assign io_enqRob_req_4_bits_blockBackward = io_fromRename_4_bits_blockBackward;
  assign io_enqRob_req_4_bits_flushPipe = io_fromRename_4_bits_flushPipe;
  assign io_enqRob_req_4_bits_vpu_vill = io_fromRename_4_bits_vpu_vill;
  assign io_enqRob_req_4_bits_vpu_vma = io_fromRename_4_bits_vpu_vma;
  assign io_enqRob_req_4_bits_vpu_vta = io_fromRename_4_bits_vpu_vta;
  assign io_enqRob_req_4_bits_vpu_vsew = io_fromRename_4_bits_vpu_vsew;
  assign io_enqRob_req_4_bits_vpu_vlmul = io_fromRename_4_bits_vpu_vlmul;
  assign io_enqRob_req_4_bits_vpu_specVill = io_fromRename_4_bits_vpu_specVill;
  assign io_enqRob_req_4_bits_vpu_specVma = io_fromRename_4_bits_vpu_specVma;
  assign io_enqRob_req_4_bits_vpu_specVta = io_fromRename_4_bits_vpu_specVta;
  assign io_enqRob_req_4_bits_vpu_specVsew = io_fromRename_4_bits_vpu_specVsew;
  assign io_enqRob_req_4_bits_vpu_specVlmul = io_fromRename_4_bits_vpu_specVlmul;
  assign io_enqRob_req_4_bits_vlsInstr = io_fromRename_4_bits_vlsInstr;
  assign io_enqRob_req_4_bits_wfflags = io_fromRename_4_bits_wfflags;
  assign io_enqRob_req_4_bits_isMove = io_fromRename_4_bits_isMove;
  assign io_enqRob_req_4_bits_isVset = io_fromRename_4_bits_isVset;
  assign io_enqRob_req_4_bits_firstUop = io_fromRename_4_bits_firstUop;
  assign io_enqRob_req_4_bits_lastUop = io_fromRename_4_bits_lastUop;
  assign io_enqRob_req_4_bits_commitType = io_fromRename_4_bits_commitType;
  assign io_enqRob_req_4_bits_pdest = io_fromRename_4_bits_pdest;
  assign io_enqRob_req_4_bits_robIdx_flag = io_fromRename_4_bits_robIdx_flag;
  assign io_enqRob_req_4_bits_robIdx_value = io_fromRename_4_bits_robIdx_value;
  assign io_enqRob_req_4_bits_instrSize = io_fromRename_4_bits_instrSize;
  assign io_enqRob_req_4_bits_dirtyFs = io_fromRename_4_bits_dirtyFs;
  assign io_enqRob_req_4_bits_dirtyVs = io_fromRename_4_bits_dirtyVs;
  assign io_enqRob_req_4_bits_traceBlockInPipe_itype = io_fromRename_4_bits_traceBlockInPipe_itype;
  assign io_enqRob_req_4_bits_traceBlockInPipe_iretire = io_fromRename_4_bits_traceBlockInPipe_iretire;
  assign io_enqRob_req_4_bits_traceBlockInPipe_ilastsize = io_fromRename_4_bits_traceBlockInPipe_ilastsize;
  assign io_enqRob_req_4_bits_eliminatedMove = io_fromRename_4_bits_eliminatedMove;
  assign io_enqRob_req_4_bits_debugInfo_renameTime = io_fromRename_4_bits_debugInfo_renameTime;
  assign io_enqRob_req_5_bits_instr = io_fromRename_5_bits_instr;
  assign io_enqRob_req_5_bits_exceptionVec_0 = io_fromRename_5_bits_exceptionVec_0;
  assign io_enqRob_req_5_bits_exceptionVec_1 = io_fromRename_5_bits_exceptionVec_1;
  assign io_enqRob_req_5_bits_exceptionVec_2 = io_fromRename_5_bits_exceptionVec_2;
  assign io_enqRob_req_5_bits_exceptionVec_3 = io_fromRename_5_bits_exceptionVec_3;
  assign io_enqRob_req_5_bits_exceptionVec_12 = io_fromRename_5_bits_exceptionVec_12;
  assign io_enqRob_req_5_bits_exceptionVec_20 = io_fromRename_5_bits_exceptionVec_20;
  assign io_enqRob_req_5_bits_exceptionVec_22 = io_fromRename_5_bits_exceptionVec_22;
  assign io_enqRob_req_5_bits_isFetchMalAddr = io_fromRename_5_bits_isFetchMalAddr;
  assign io_enqRob_req_5_bits_trigger = io_fromRename_5_bits_trigger;
  assign io_enqRob_req_5_bits_preDecodeInfo_isRVC = io_fromRename_5_bits_preDecodeInfo_isRVC;
  assign io_enqRob_req_5_bits_crossPageIPFFix = io_fromRename_5_bits_crossPageIPFFix;
  assign io_enqRob_req_5_bits_ftqPtr_flag = io_fromRename_5_bits_ftqPtr_flag;
  assign io_enqRob_req_5_bits_ftqPtr_value = io_fromRename_5_bits_ftqPtr_value;
  assign io_enqRob_req_5_bits_ftqOffset = io_fromRename_5_bits_ftqOffset;
  assign io_enqRob_req_5_bits_ldest = io_fromRename_5_bits_ldest;
  assign io_enqRob_req_5_bits_fuType = io_fromRename_5_bits_fuType;
  assign io_enqRob_req_5_bits_fuOpType = io_fromRename_5_bits_fuOpType;
  assign io_enqRob_req_5_bits_rfWen = io_fromRename_5_bits_rfWen;
  assign io_enqRob_req_5_bits_fpWen = io_fromRename_5_bits_fpWen;
  assign io_enqRob_req_5_bits_vecWen = io_fromRename_5_bits_vecWen;
  assign io_enqRob_req_5_bits_v0Wen = io_fromRename_5_bits_v0Wen;
  assign io_enqRob_req_5_bits_vlWen = io_fromRename_5_bits_vlWen;
  assign io_enqRob_req_5_bits_isXSTrap = io_fromRename_5_bits_isXSTrap;
  assign io_enqRob_req_5_bits_waitForward = io_fromRename_5_bits_waitForward;
  assign io_enqRob_req_5_bits_blockBackward = io_fromRename_5_bits_blockBackward;
  assign io_enqRob_req_5_bits_flushPipe = io_fromRename_5_bits_flushPipe;
  assign io_enqRob_req_5_bits_vpu_vill = io_fromRename_5_bits_vpu_vill;
  assign io_enqRob_req_5_bits_vpu_vma = io_fromRename_5_bits_vpu_vma;
  assign io_enqRob_req_5_bits_vpu_vta = io_fromRename_5_bits_vpu_vta;
  assign io_enqRob_req_5_bits_vpu_vsew = io_fromRename_5_bits_vpu_vsew;
  assign io_enqRob_req_5_bits_vpu_vlmul = io_fromRename_5_bits_vpu_vlmul;
  assign io_enqRob_req_5_bits_vpu_specVill = io_fromRename_5_bits_vpu_specVill;
  assign io_enqRob_req_5_bits_vpu_specVma = io_fromRename_5_bits_vpu_specVma;
  assign io_enqRob_req_5_bits_vpu_specVta = io_fromRename_5_bits_vpu_specVta;
  assign io_enqRob_req_5_bits_vpu_specVsew = io_fromRename_5_bits_vpu_specVsew;
  assign io_enqRob_req_5_bits_vpu_specVlmul = io_fromRename_5_bits_vpu_specVlmul;
  assign io_enqRob_req_5_bits_vlsInstr = io_fromRename_5_bits_vlsInstr;
  assign io_enqRob_req_5_bits_wfflags = io_fromRename_5_bits_wfflags;
  assign io_enqRob_req_5_bits_isMove = io_fromRename_5_bits_isMove;
  assign io_enqRob_req_5_bits_isVset = io_fromRename_5_bits_isVset;
  assign io_enqRob_req_5_bits_firstUop = io_fromRename_5_bits_firstUop;
  assign io_enqRob_req_5_bits_lastUop = io_fromRename_5_bits_lastUop;
  assign io_enqRob_req_5_bits_commitType = io_fromRename_5_bits_commitType;
  assign io_enqRob_req_5_bits_pdest = io_fromRename_5_bits_pdest;
  assign io_enqRob_req_5_bits_robIdx_flag = io_fromRename_5_bits_robIdx_flag;
  assign io_enqRob_req_5_bits_robIdx_value = io_fromRename_5_bits_robIdx_value;
  assign io_enqRob_req_5_bits_instrSize = io_fromRename_5_bits_instrSize;
  assign io_enqRob_req_5_bits_dirtyFs = io_fromRename_5_bits_dirtyFs;
  assign io_enqRob_req_5_bits_dirtyVs = io_fromRename_5_bits_dirtyVs;
  assign io_enqRob_req_5_bits_traceBlockInPipe_itype = io_fromRename_5_bits_traceBlockInPipe_itype;
  assign io_enqRob_req_5_bits_traceBlockInPipe_iretire = io_fromRename_5_bits_traceBlockInPipe_iretire;
  assign io_enqRob_req_5_bits_traceBlockInPipe_ilastsize = io_fromRename_5_bits_traceBlockInPipe_ilastsize;
  assign io_enqRob_req_5_bits_eliminatedMove = io_fromRename_5_bits_eliminatedMove;
  assign io_enqRob_req_5_bits_debugInfo_renameTime = io_fromRename_5_bits_debugInfo_renameTime;
