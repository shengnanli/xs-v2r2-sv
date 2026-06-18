// 自动生成:scripts/gen_newdispatch.py —— 勿手改(逻辑为从 NewDispatch.scala 设计意图的可读重写)

// =====================================================================
// 派遣级核心逻辑(从 NewDispatch.scala 设计意图重写,非 golden 网表抽取)。
// 全部为命名网线 / generate-for / 纯函数;无 _GEN_/_T_ 临时名。
// 子模块(BusyTable×4 / VlBusyTable / RegCacheTagTable / LsqEnqCtrl)的「读端口
// 驱动」「allocPregs」在此算好,例化与连线见 newdispatch_connect.svh。
// =====================================================================
import newdispatch_pkg::*;

  // ---- 0. 把 6 条 uop 的关键标量字段聚成数组(便于 generate 遍历)----
  logic [RENAME_WIDTH-1:0] rn_valid, ri_valid, rn_ready;
  logic [RENAME_WIDTH-1:0] rn_rfWen, rn_elimMove, rn_hasExc, rn_blockBkwd, rn_waitFwd;
  logic [3:0] rn_srcType [RENAME_WIDTH][NUM_REG_SRC];
  logic [PREG_W-1:0] rn_pdest [RENAME_WIDTH];
  assign rn_valid[0]    = io_fromRename_0_valid;
  assign ri_valid[0]    = io_renameIn_0_valid;
  assign rn_rfWen[0]    = io_fromRename_0_bits_rfWen;
  assign rn_elimMove[0] = io_fromRename_0_bits_eliminatedMove;
  assign rn_hasExc[0]   = io_fromRename_0_bits_hasException;
  assign rn_blockBkwd[0]= io_fromRename_0_bits_blockBackward;
  assign rn_waitFwd[0]  = io_fromRename_0_bits_waitForward;
  assign rn_pdest[0]    = io_fromRename_0_bits_pdest;
  assign rn_srcType[0][0] = io_fromRename_0_bits_srcType_0;
  assign rn_srcType[0][1] = io_fromRename_0_bits_srcType_1;
  assign rn_srcType[0][2] = io_fromRename_0_bits_srcType_2;
  assign rn_srcType[0][3] = io_fromRename_0_bits_srcType_3;
  assign rn_srcType[0][4] = io_fromRename_0_bits_srcType_4;
  assign rn_valid[1]    = io_fromRename_1_valid;
  assign ri_valid[1]    = io_renameIn_1_valid;
  assign rn_rfWen[1]    = io_fromRename_1_bits_rfWen;
  assign rn_elimMove[1] = io_fromRename_1_bits_eliminatedMove;
  assign rn_hasExc[1]   = io_fromRename_1_bits_hasException;
  assign rn_blockBkwd[1]= io_fromRename_1_bits_blockBackward;
  assign rn_waitFwd[1]  = io_fromRename_1_bits_waitForward;
  assign rn_pdest[1]    = io_fromRename_1_bits_pdest;
  assign rn_srcType[1][0] = io_fromRename_1_bits_srcType_0;
  assign rn_srcType[1][1] = io_fromRename_1_bits_srcType_1;
  assign rn_srcType[1][2] = io_fromRename_1_bits_srcType_2;
  assign rn_srcType[1][3] = io_fromRename_1_bits_srcType_3;
  assign rn_srcType[1][4] = io_fromRename_1_bits_srcType_4;
  assign rn_valid[2]    = io_fromRename_2_valid;
  assign ri_valid[2]    = io_renameIn_2_valid;
  assign rn_rfWen[2]    = io_fromRename_2_bits_rfWen;
  assign rn_elimMove[2] = io_fromRename_2_bits_eliminatedMove;
  assign rn_hasExc[2]   = io_fromRename_2_bits_hasException;
  assign rn_blockBkwd[2]= io_fromRename_2_bits_blockBackward;
  assign rn_waitFwd[2]  = io_fromRename_2_bits_waitForward;
  assign rn_pdest[2]    = io_fromRename_2_bits_pdest;
  assign rn_srcType[2][0] = io_fromRename_2_bits_srcType_0;
  assign rn_srcType[2][1] = io_fromRename_2_bits_srcType_1;
  assign rn_srcType[2][2] = io_fromRename_2_bits_srcType_2;
  assign rn_srcType[2][3] = io_fromRename_2_bits_srcType_3;
  assign rn_srcType[2][4] = io_fromRename_2_bits_srcType_4;
  assign rn_valid[3]    = io_fromRename_3_valid;
  assign ri_valid[3]    = io_renameIn_3_valid;
  assign rn_rfWen[3]    = io_fromRename_3_bits_rfWen;
  assign rn_elimMove[3] = io_fromRename_3_bits_eliminatedMove;
  assign rn_hasExc[3]   = io_fromRename_3_bits_hasException;
  assign rn_blockBkwd[3]= io_fromRename_3_bits_blockBackward;
  assign rn_waitFwd[3]  = io_fromRename_3_bits_waitForward;
  assign rn_pdest[3]    = io_fromRename_3_bits_pdest;
  assign rn_srcType[3][0] = io_fromRename_3_bits_srcType_0;
  assign rn_srcType[3][1] = io_fromRename_3_bits_srcType_1;
  assign rn_srcType[3][2] = io_fromRename_3_bits_srcType_2;
  assign rn_srcType[3][3] = io_fromRename_3_bits_srcType_3;
  assign rn_srcType[3][4] = io_fromRename_3_bits_srcType_4;
  assign rn_valid[4]    = io_fromRename_4_valid;
  assign ri_valid[4]    = io_renameIn_4_valid;
  assign rn_rfWen[4]    = io_fromRename_4_bits_rfWen;
  assign rn_elimMove[4] = io_fromRename_4_bits_eliminatedMove;
  assign rn_hasExc[4]   = io_fromRename_4_bits_hasException;
  assign rn_blockBkwd[4]= io_fromRename_4_bits_blockBackward;
  assign rn_waitFwd[4]  = io_fromRename_4_bits_waitForward;
  assign rn_pdest[4]    = io_fromRename_4_bits_pdest;
  assign rn_srcType[4][0] = io_fromRename_4_bits_srcType_0;
  assign rn_srcType[4][1] = io_fromRename_4_bits_srcType_1;
  assign rn_srcType[4][2] = io_fromRename_4_bits_srcType_2;
  assign rn_srcType[4][3] = io_fromRename_4_bits_srcType_3;
  assign rn_srcType[4][4] = io_fromRename_4_bits_srcType_4;
  assign rn_valid[5]    = io_fromRename_5_valid;
  assign ri_valid[5]    = io_renameIn_5_valid;
  assign rn_rfWen[5]    = io_fromRename_5_bits_rfWen;
  assign rn_elimMove[5] = io_fromRename_5_bits_eliminatedMove;
  assign rn_hasExc[5]   = io_fromRename_5_bits_hasException;
  assign rn_blockBkwd[5]= io_fromRename_5_bits_blockBackward;
  assign rn_waitFwd[5]  = io_fromRename_5_bits_waitForward;
  assign rn_pdest[5]    = io_fromRename_5_bits_pdest;
  assign rn_srcType[5][0] = io_fromRename_5_bits_srcType_0;
  assign rn_srcType[5][1] = io_fromRename_5_bits_srcType_1;
  assign rn_srcType[5][2] = io_fromRename_5_bits_srcType_2;
  assign rn_srcType[5][3] = io_fromRename_5_bits_srcType_3;
  assign rn_srcType[5][4] = io_fromRename_5_bits_srcType_4;

  // ---- 1. fire / toRenameAllFire ----
  // firedVec[i] = ready & valid;toRenameAllFire = 每条 uop 「无效或已 fire」。
  logic [RENAME_WIDTH-1:0] firedVec;
  logic toRenameAllFire;
  always_comb begin
    logic acc;
    acc = 1'b1;
    for (int i = 0; i < RENAME_WIDTH; i++)
      acc = acc & (~rn_valid[i] | (rn_ready[i] & rn_valid[i]));
    toRenameAllFire = acc;
  end
  assign firedVec[0] = rn_ready[0] & io_fromRename_0_valid;
  assign firedVec[1] = rn_ready[1] & io_fromRename_1_valid;
  assign firedVec[2] = rn_ready[2] & io_fromRename_2_valid;
  assign firedVec[3] = rn_ready[3] & io_fromRename_3_valid;
  assign firedVec[4] = rn_ready[4] & io_fromRename_4_valid;
  assign firedVec[5] = rn_ready[5] & io_fromRename_5_valid;
  assign io_toRenameAllFire = toRenameAllFire;

  // ---- 2. allocPregs valid(写 5 个 BusyTable / RegCacheTagTable 的分配端口)----
  // 每域:valid = uop.valid & 对应写使能(int 额外排除 eliminatedMove)。
  logic [RENAME_WIDTH-1:0] allocPregsValid [NUM_REG_TYPE];
  assign allocPregsValid[0][0] = io_fromRename_0_valid & io_fromRename_0_bits_rfWen & ~io_fromRename_0_bits_eliminatedMove;
  assign allocPregsValid[0][1] = io_fromRename_1_valid & io_fromRename_1_bits_rfWen & ~io_fromRename_1_bits_eliminatedMove;
  assign allocPregsValid[0][2] = io_fromRename_2_valid & io_fromRename_2_bits_rfWen & ~io_fromRename_2_bits_eliminatedMove;
  assign allocPregsValid[0][3] = io_fromRename_3_valid & io_fromRename_3_bits_rfWen & ~io_fromRename_3_bits_eliminatedMove;
  assign allocPregsValid[0][4] = io_fromRename_4_valid & io_fromRename_4_bits_rfWen & ~io_fromRename_4_bits_eliminatedMove;
  assign allocPregsValid[0][5] = io_fromRename_5_valid & io_fromRename_5_bits_rfWen & ~io_fromRename_5_bits_eliminatedMove;
  assign allocPregsValid[1][0] = io_fromRename_0_valid & io_fromRename_0_bits_fpWen;
  assign allocPregsValid[1][1] = io_fromRename_1_valid & io_fromRename_1_bits_fpWen;
  assign allocPregsValid[1][2] = io_fromRename_2_valid & io_fromRename_2_bits_fpWen;
  assign allocPregsValid[1][3] = io_fromRename_3_valid & io_fromRename_3_bits_fpWen;
  assign allocPregsValid[1][4] = io_fromRename_4_valid & io_fromRename_4_bits_fpWen;
  assign allocPregsValid[1][5] = io_fromRename_5_valid & io_fromRename_5_bits_fpWen;
  assign allocPregsValid[2][0] = io_fromRename_0_valid & io_fromRename_0_bits_vecWen;
  assign allocPregsValid[2][1] = io_fromRename_1_valid & io_fromRename_1_bits_vecWen;
  assign allocPregsValid[2][2] = io_fromRename_2_valid & io_fromRename_2_bits_vecWen;
  assign allocPregsValid[2][3] = io_fromRename_3_valid & io_fromRename_3_bits_vecWen;
  assign allocPregsValid[2][4] = io_fromRename_4_valid & io_fromRename_4_bits_vecWen;
  assign allocPregsValid[2][5] = io_fromRename_5_valid & io_fromRename_5_bits_vecWen;
  assign allocPregsValid[3][0] = io_fromRename_0_valid & io_fromRename_0_bits_v0Wen;
  assign allocPregsValid[3][1] = io_fromRename_1_valid & io_fromRename_1_bits_v0Wen;
  assign allocPregsValid[3][2] = io_fromRename_2_valid & io_fromRename_2_bits_v0Wen;
  assign allocPregsValid[3][3] = io_fromRename_3_valid & io_fromRename_3_bits_v0Wen;
  assign allocPregsValid[3][4] = io_fromRename_4_valid & io_fromRename_4_bits_v0Wen;
  assign allocPregsValid[3][5] = io_fromRename_5_valid & io_fromRename_5_bits_v0Wen;
  assign allocPregsValid[4][0] = io_fromRename_0_valid & io_fromRename_0_bits_vlWen;
  assign allocPregsValid[4][1] = io_fromRename_1_valid & io_fromRename_1_bits_vlWen;
  assign allocPregsValid[4][2] = io_fromRename_2_valid & io_fromRename_2_bits_vlWen;
  assign allocPregsValid[4][3] = io_fromRename_3_valid & io_fromRename_3_bits_vlWen;
  assign allocPregsValid[4][4] = io_fromRename_4_valid & io_fromRename_4_bits_vlWen;
  assign allocPregsValid[4][5] = io_fromRename_5_valid & io_fromRename_5_bits_vlWen;

  // ---- 3. BusyTable / RegCacheTagTable 读端口驱动 ----
  // 读地址 = uop 对应源的 psrc;读使能 = 该源属于该域(SrcType 对应位)。
  // 读端口索引 idx = i*len(idxRegType) + 域内位置(见 docs §2.1)。

  // ---- 4. allSrcState[i][j][k]:第 i 条 uop 第 j 源在第 k 域的就绪 ----
  // allSrcState = (srcType 命中该域位) & busyTable.resp | (srcType==imm 恒就绪)。
  // 仅 (j,k) 合法组合存在(int:j∈{0,1};fp/vec:j∈{0,1,2};v0:j=3;vl:j=4)。
  // 向量 old-vd(j=2,k=vec)额外或上 ignoreOldVd。busyTable.resp 见 connect.svh。
  logic allSrcState [RENAME_WIDTH][NUM_REG_SRC][NUM_REG_TYPE];
  logic ignoreOldVd [RENAME_WIDTH];   // 向量 old_vd 可忽略
  // busyTable.resp 数组(由 connect.svh 从子模块输出填入)
  logic bt_resp_int [RENAME_WIDTH*2];
  logic bt_resp_fp  [RENAME_WIDTH*3];
  logic bt_resp_vec [RENAME_WIDTH*3];
  logic bt_resp_v0  [RENAME_WIDTH];
  logic bt_resp_vl  [RENAME_WIDTH];
  // vlBusyTable 读出的 vl 信息(is_vlmax / is_nonzero)
  logic vl_is_vlmax [RENAME_WIDTH];
  logic vl_is_nonzero [RENAME_WIDTH];
  // vpu 字段数组(供 ignoreOldVd)
  logic vpu_isDependOldVd [RENAME_WIDTH], vpu_isWritePartVd [RENAME_WIDTH];
  logic vpu_vta [RENAME_WIDTH], vpu_vma [RENAME_WIDTH], vpu_vm [RENAME_WIDTH];
  assign vpu_isDependOldVd[0] = io_fromRename_0_bits_vpu_isDependOldVd;
  assign vpu_isWritePartVd[0] = io_fromRename_0_bits_vpu_isWritePartVd;
  assign vpu_vta[0] = io_fromRename_0_bits_vpu_vta;
  assign vpu_vma[0] = io_fromRename_0_bits_vpu_vma;
  assign vpu_vm[0]  = io_fromRename_0_bits_vpu_vm;
  assign vpu_isDependOldVd[1] = io_fromRename_1_bits_vpu_isDependOldVd;
  assign vpu_isWritePartVd[1] = io_fromRename_1_bits_vpu_isWritePartVd;
  assign vpu_vta[1] = io_fromRename_1_bits_vpu_vta;
  assign vpu_vma[1] = io_fromRename_1_bits_vpu_vma;
  assign vpu_vm[1]  = io_fromRename_1_bits_vpu_vm;
  assign vpu_isDependOldVd[2] = io_fromRename_2_bits_vpu_isDependOldVd;
  assign vpu_isWritePartVd[2] = io_fromRename_2_bits_vpu_isWritePartVd;
  assign vpu_vta[2] = io_fromRename_2_bits_vpu_vta;
  assign vpu_vma[2] = io_fromRename_2_bits_vpu_vma;
  assign vpu_vm[2]  = io_fromRename_2_bits_vpu_vm;
  assign vpu_isDependOldVd[3] = io_fromRename_3_bits_vpu_isDependOldVd;
  assign vpu_isWritePartVd[3] = io_fromRename_3_bits_vpu_isWritePartVd;
  assign vpu_vta[3] = io_fromRename_3_bits_vpu_vta;
  assign vpu_vma[3] = io_fromRename_3_bits_vpu_vma;
  assign vpu_vm[3]  = io_fromRename_3_bits_vpu_vm;
  assign vpu_isDependOldVd[4] = io_fromRename_4_bits_vpu_isDependOldVd;
  assign vpu_isWritePartVd[4] = io_fromRename_4_bits_vpu_isWritePartVd;
  assign vpu_vta[4] = io_fromRename_4_bits_vpu_vta;
  assign vpu_vma[4] = io_fromRename_4_bits_vpu_vma;
  assign vpu_vm[4]  = io_fromRename_4_bits_vpu_vm;
  assign vpu_isDependOldVd[5] = io_fromRename_5_bits_vpu_isDependOldVd;
  assign vpu_isWritePartVd[5] = io_fromRename_5_bits_vpu_isWritePartVd;
  assign vpu_vta[5] = io_fromRename_5_bits_vpu_vta;
  assign vpu_vma[5] = io_fromRename_5_bits_vpu_vma;
  assign vpu_vm[5]  = io_fromRename_5_bits_vpu_vm;
  always_comb begin
    for (int i = 0; i < RENAME_WIDTH; i++)
      for (int j = 0; j < NUM_REG_SRC; j++)
        for (int k = 0; k < NUM_REG_TYPE; k++)
          allSrcState[i][j][k] = 1'b0;
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      // imm 恒就绪标志(srcType==0)
      logic [4:0] immJ;  // 每源是否立即数
      for (int j = 0; j < NUM_REG_SRC; j++)
        immJ[j] = (rn_srcType[i][j] == 4'h0);
      // src0/src1:可落 int(bit0)/fp(bit1)/vec(bit2)三域
      for (int j = 0; j < 2; j++) begin
        allSrcState[i][j][0] = rn_srcType[i][j][0] & bt_resp_int[i*2+j] | immJ[j];
        allSrcState[i][j][1] = rn_srcType[i][j][1] & bt_resp_fp [i*3+j] | immJ[j];
        allSrcState[i][j][2] = rn_srcType[i][j][2] & bt_resp_vec[i*3+j] | immJ[j];
      end
      // src2:fp(bit1)/vec(bit2,含 ignoreOldVd);old_vd 是 vec 第 3 源(j=2)
      allSrcState[i][2][1] = rn_srcType[i][2][1] & bt_resp_fp [i*3+2] | immJ[2];
      allSrcState[i][2][2] = rn_srcType[i][2][2] & (bt_resp_vec[i*3+2] | ignoreOldVd[i]) | immJ[2];
      // src3:v0(bit3);src4:vl(恒读)
      allSrcState[i][3][3] = rn_srcType[i][3][3] & bt_resp_v0[i] | immJ[3];
      allSrcState[i][4][4] = bt_resp_vl[i] | immJ[4];
    end
  end
  // ignoreOldVd:vl 已就绪且非零、不依赖 old_vd,且(尾被 mask 或整体被 mask)→ 可忽略 old_vd。
  always_comb for (int i = 0; i < RENAME_WIDTH; i++)
    ignoreOldVd[i] = nd_ignore_old_vd(
      bt_resp_vl[i], vl_is_nonzero[i], vl_is_vlmax[i],
      vpu_isDependOldVd[i], vpu_isWritePartVd[i], vpu_vta[i], vpu_vma[i], vpu_vm[i]);

  // ---- 5. 负载均衡(needMultiExu):compareMatrix→IQSort 排序→各 uop 轮选最空 IQ ----
  // 对每个「多同质 EXU」组:compareMatrix 两两比 IQValidNum;IQSort[row] = 表项数
  // 第 (iqNum-1-row) 多的那个 IQ 的 one-hot(寄存一拍);uop i 落到 IQSort[i%iqNum]。
  logic [4:0] iqvld [25];   // IQValidNumVec 数组化(部分 EXU 无负载均衡需求,端口缺省)
  assign iqvld[0] = io_IQValidNumVec_0;
  assign iqvld[1] = io_IQValidNumVec_1;
  assign iqvld[2] = io_IQValidNumVec_2;
  assign iqvld[3] = io_IQValidNumVec_3;
  assign iqvld[4] = io_IQValidNumVec_4;
  assign iqvld[5] = io_IQValidNumVec_5;
  assign iqvld[6] = io_IQValidNumVec_6;
  assign iqvld[8] = io_IQValidNumVec_8;
  assign iqvld[9] = io_IQValidNumVec_9;
  assign iqvld[10] = io_IQValidNumVec_10;
  assign iqvld[11] = io_IQValidNumVec_11;
  assign iqvld[12] = io_IQValidNumVec_12;
  assign iqvld[13] = io_IQValidNumVec_13;
  assign iqvld[14] = io_IQValidNumVec_14;
  assign iqvld[15] = io_IQValidNumVec_15;
  assign iqvld[16] = io_IQValidNumVec_16;
  assign iqvld[18] = io_IQValidNumVec_18;
  assign iqvld[19] = io_IQValidNumVec_19;
  assign iqvld[20] = io_IQValidNumVec_20;
  assign iqvld[21] = io_IQValidNumVec_21;
  assign iqvld[22] = io_IQValidNumVec_22;
  assign iqvld[23] = io_IQValidNumVec_23;
  assign iqvld[24] = io_IQValidNumVec_24;
  // -- 组 jmp_brh:3 个 EXU(IQValidNumVec 索引 [1, 3, 5])--
  localparam int unsigned EXU_jmp_brh [3] = '{1, 3, 5};
  logic cmp_jmp_brh [3][3];   // compareMatrix(i<j:vld[i]<vld[j])
  logic [2-1:0] cmpcnt_jmp_brh [3];
  logic sort_jmp_brh [8][3];  // IQSort 寄存器(8 行,row r = IQSort[r%3],寄一拍)
  always_comb begin
    for (int i = 0; i < 3; i++)
      for (int j = 0; j < 3; j++) begin
        if (i == j) cmp_jmp_brh[i][j] = 1'b0;
        else if (i < j) cmp_jmp_brh[i][j] = iqvld[EXU_jmp_brh[i]] < iqvld[EXU_jmp_brh[j]];
        else cmp_jmp_brh[i][j] = ~cmp_jmp_brh[j][i];
      end
    for (int i = 0; i < 3; i++) begin
      cmpcnt_jmp_brh[i] = '0;
      for (int j = 0; j < 3; j++) cmpcnt_jmp_brh[i] += cmp_jmp_brh[i][j];
    end
  end
  always_ff @(posedge clock)
    for (int r = 0; r < 8; r++)
      for (int j = 0; j < 3; j++)
        sort_jmp_brh[r][j] <= (cmpcnt_jmp_brh[j] == (3-1-(r % 3)));
  // -- 组 alu:4 个 EXU(IQValidNumVec 索引 [0, 2, 4, 6])--
  localparam int unsigned EXU_alu [4] = '{0, 2, 4, 6};
  logic cmp_alu [4][4];   // compareMatrix(i<j:vld[i]<vld[j])
  logic [2-1:0] cmpcnt_alu [4];
  logic sort_alu [8][4];  // IQSort 寄存器(8 行,row r = IQSort[r%4],寄一拍)
  always_comb begin
    for (int i = 0; i < 4; i++)
      for (int j = 0; j < 4; j++) begin
        if (i == j) cmp_alu[i][j] = 1'b0;
        else if (i < j) cmp_alu[i][j] = iqvld[EXU_alu[i]] < iqvld[EXU_alu[j]];
        else cmp_alu[i][j] = ~cmp_alu[j][i];
      end
    for (int i = 0; i < 4; i++) begin
      cmpcnt_alu[i] = '0;
      for (int j = 0; j < 4; j++) cmpcnt_alu[i] += cmp_alu[i][j];
    end
  end
  always_ff @(posedge clock)
    for (int r = 0; r < 8; r++)
      for (int j = 0; j < 4; j++)
        sort_alu[r][j] <= (cmpcnt_alu[j] == (4-1-(r % 4)));
  // -- 组 mul_bku:2 个 EXU(IQValidNumVec 索引 [0, 2])--
  localparam int unsigned EXU_mul_bku [2] = '{0, 2};
  logic cmp_mul_bku [2][2];   // compareMatrix(i<j:vld[i]<vld[j])
  logic [1-1:0] cmpcnt_mul_bku [2];
  logic sort_mul_bku [8][2];  // IQSort 寄存器(8 行,row r = IQSort[r%2],寄一拍)
  always_comb begin
    for (int i = 0; i < 2; i++)
      for (int j = 0; j < 2; j++) begin
        if (i == j) cmp_mul_bku[i][j] = 1'b0;
        else if (i < j) cmp_mul_bku[i][j] = iqvld[EXU_mul_bku[i]] < iqvld[EXU_mul_bku[j]];
        else cmp_mul_bku[i][j] = ~cmp_mul_bku[j][i];
      end
    for (int i = 0; i < 2; i++) begin
      cmpcnt_mul_bku[i] = '0;
      for (int j = 0; j < 2; j++) cmpcnt_mul_bku[i] += cmp_mul_bku[i][j];
    end
  end
  always_ff @(posedge clock)
    for (int r = 0; r < 8; r++)
      for (int j = 0; j < 2; j++)
        sort_mul_bku[r][j] <= (cmpcnt_mul_bku[j] == (2-1-(r % 2)));
  // -- 组 falu_fmac:3 个 EXU(IQValidNumVec 索引 [8, 10, 12])--
  localparam int unsigned EXU_falu_fmac [3] = '{8, 10, 12};
  logic cmp_falu_fmac [3][3];   // compareMatrix(i<j:vld[i]<vld[j])
  logic [2-1:0] cmpcnt_falu_fmac [3];
  logic sort_falu_fmac [8][3];  // IQSort 寄存器(8 行,row r = IQSort[r%3],寄一拍)
  always_comb begin
    for (int i = 0; i < 3; i++)
      for (int j = 0; j < 3; j++) begin
        if (i == j) cmp_falu_fmac[i][j] = 1'b0;
        else if (i < j) cmp_falu_fmac[i][j] = iqvld[EXU_falu_fmac[i]] < iqvld[EXU_falu_fmac[j]];
        else cmp_falu_fmac[i][j] = ~cmp_falu_fmac[j][i];
      end
    for (int i = 0; i < 3; i++) begin
      cmpcnt_falu_fmac[i] = '0;
      for (int j = 0; j < 3; j++) cmpcnt_falu_fmac[i] += cmp_falu_fmac[i][j];
    end
  end
  always_ff @(posedge clock)
    for (int r = 0; r < 8; r++)
      for (int j = 0; j < 3; j++)
        sort_falu_fmac[r][j] <= (cmpcnt_falu_fmac[j] == (3-1-(r % 3)));
  // -- 组 fdiv:2 个 EXU(IQValidNumVec 索引 [9, 11])--
  localparam int unsigned EXU_fdiv [2] = '{9, 11};
  logic cmp_fdiv [2][2];   // compareMatrix(i<j:vld[i]<vld[j])
  logic [1-1:0] cmpcnt_fdiv [2];
  logic sort_fdiv [8][2];  // IQSort 寄存器(8 行,row r = IQSort[r%2],寄一拍)
  always_comb begin
    for (int i = 0; i < 2; i++)
      for (int j = 0; j < 2; j++) begin
        if (i == j) cmp_fdiv[i][j] = 1'b0;
        else if (i < j) cmp_fdiv[i][j] = iqvld[EXU_fdiv[i]] < iqvld[EXU_fdiv[j]];
        else cmp_fdiv[i][j] = ~cmp_fdiv[j][i];
      end
    for (int i = 0; i < 2; i++) begin
      cmpcnt_fdiv[i] = '0;
      for (int j = 0; j < 2; j++) cmpcnt_fdiv[i] += cmp_fdiv[i][j];
    end
  end
  always_ff @(posedge clock)
    for (int r = 0; r < 8; r++)
      for (int j = 0; j < 2; j++)
        sort_fdiv[r][j] <= (cmpcnt_fdiv[j] == (2-1-(r % 2)));
  // -- 组 ldu:3 个 EXU(IQValidNumVec 索引 [20, 21, 22])--
  localparam int unsigned EXU_ldu [3] = '{20, 21, 22};
  logic cmp_ldu [3][3];   // compareMatrix(i<j:vld[i]<vld[j])
  logic [2-1:0] cmpcnt_ldu [3];
  logic sort_ldu [8][3];  // IQSort 寄存器(8 行,row r = IQSort[r%3],寄一拍)
  always_comb begin
    for (int i = 0; i < 3; i++)
      for (int j = 0; j < 3; j++) begin
        if (i == j) cmp_ldu[i][j] = 1'b0;
        else if (i < j) cmp_ldu[i][j] = iqvld[EXU_ldu[i]] < iqvld[EXU_ldu[j]];
        else cmp_ldu[i][j] = ~cmp_ldu[j][i];
      end
    for (int i = 0; i < 3; i++) begin
      cmpcnt_ldu[i] = '0;
      for (int j = 0; j < 3; j++) cmpcnt_ldu[i] += cmp_ldu[i][j];
    end
  end
  always_ff @(posedge clock)
    for (int r = 0; r < 8; r++)
      for (int j = 0; j < 3; j++)
        sort_ldu[r][j] <= (cmpcnt_ldu[j] == (3-1-(r % 3)));
  // -- 组 sta_mou:2 个 EXU(IQValidNumVec 索引 [18, 19])--
  localparam int unsigned EXU_sta_mou [2] = '{18, 19};
  logic cmp_sta_mou [2][2];   // compareMatrix(i<j:vld[i]<vld[j])
  logic [1-1:0] cmpcnt_sta_mou [2];
  logic sort_sta_mou [8][2];  // IQSort 寄存器(8 行,row r = IQSort[r%2],寄一拍)
  always_comb begin
    for (int i = 0; i < 2; i++)
      for (int j = 0; j < 2; j++) begin
        if (i == j) cmp_sta_mou[i][j] = 1'b0;
        else if (i < j) cmp_sta_mou[i][j] = iqvld[EXU_sta_mou[i]] < iqvld[EXU_sta_mou[j]];
        else cmp_sta_mou[i][j] = ~cmp_sta_mou[j][i];
      end
    for (int i = 0; i < 2; i++) begin
      cmpcnt_sta_mou[i] = '0;
      for (int j = 0; j < 2; j++) cmpcnt_sta_mou[i] += cmp_sta_mou[i][j];
    end
  end
  always_ff @(posedge clock)
    for (int r = 0; r < 8; r++)
      for (int j = 0; j < 2; j++)
        sort_sta_mou[r][j] <= (cmpcnt_sta_mou[j] == (2-1-(r % 2)));
  // -- 组 vialuFix_vfma:2 个 EXU(IQValidNumVec 索引 [13, 15])--
  localparam int unsigned EXU_vialuFix_vfma [2] = '{13, 15};
  logic cmp_vialuFix_vfma [2][2];   // compareMatrix(i<j:vld[i]<vld[j])
  logic [1-1:0] cmpcnt_vialuFix_vfma [2];
  logic sort_vialuFix_vfma [8][2];  // IQSort 寄存器(8 行,row r = IQSort[r%2],寄一拍)
  always_comb begin
    for (int i = 0; i < 2; i++)
      for (int j = 0; j < 2; j++) begin
        if (i == j) cmp_vialuFix_vfma[i][j] = 1'b0;
        else if (i < j) cmp_vialuFix_vfma[i][j] = iqvld[EXU_vialuFix_vfma[i]] < iqvld[EXU_vialuFix_vfma[j]];
        else cmp_vialuFix_vfma[i][j] = ~cmp_vialuFix_vfma[j][i];
      end
    for (int i = 0; i < 2; i++) begin
      cmpcnt_vialuFix_vfma[i] = '0;
      for (int j = 0; j < 2; j++) cmpcnt_vialuFix_vfma[i] += cmp_vialuFix_vfma[i][j];
    end
  end
  always_ff @(posedge clock)
    for (int r = 0; r < 8; r++)
      for (int j = 0; j < 2; j++)
        sort_vialuFix_vfma[r][j] <= (cmpcnt_vialuFix_vfma[j] == (2-1-(r % 2)));
  // -- 组 vfalu:2 个 EXU(IQValidNumVec 索引 [14, 16])--
  localparam int unsigned EXU_vfalu [2] = '{14, 16};
  logic cmp_vfalu [2][2];   // compareMatrix(i<j:vld[i]<vld[j])
  logic [1-1:0] cmpcnt_vfalu [2];
  logic sort_vfalu [8][2];  // IQSort 寄存器(8 行,row r = IQSort[r%2],寄一拍)
  always_comb begin
    for (int i = 0; i < 2; i++)
      for (int j = 0; j < 2; j++) begin
        if (i == j) cmp_vfalu[i][j] = 1'b0;
        else if (i < j) cmp_vfalu[i][j] = iqvld[EXU_vfalu[i]] < iqvld[EXU_vfalu[j]];
        else cmp_vfalu[i][j] = ~cmp_vfalu[j][i];
      end
    for (int i = 0; i < 2; i++) begin
      cmpcnt_vfalu[i] = '0;
      for (int j = 0; j < 2; j++) cmpcnt_vfalu[i] += cmp_vfalu[i][j];
    end
  end
  always_ff @(posedge clock)
    for (int r = 0; r < 8; r++)
      for (int j = 0; j < 2; j++)
        sort_vfalu[r][j] <= (cmpcnt_vfalu[j] == (2-1-(r % 2)));
  // -- 组 vldu_vstu:2 个 EXU(IQValidNumVec 索引 [23, 24])--
  localparam int unsigned EXU_vldu_vstu [2] = '{23, 24};
  logic cmp_vldu_vstu [2][2];   // compareMatrix(i<j:vld[i]<vld[j])
  logic [1-1:0] cmpcnt_vldu_vstu [2];
  logic sort_vldu_vstu [8][2];  // IQSort 寄存器(8 行,row r = IQSort[r%2],寄一拍)
  always_comb begin
    for (int i = 0; i < 2; i++)
      for (int j = 0; j < 2; j++) begin
        if (i == j) cmp_vldu_vstu[i][j] = 1'b0;
        else if (i < j) cmp_vldu_vstu[i][j] = iqvld[EXU_vldu_vstu[i]] < iqvld[EXU_vldu_vstu[j]];
        else cmp_vldu_vstu[i][j] = ~cmp_vldu_vstu[j][i];
      end
    for (int i = 0; i < 2; i++) begin
      cmpcnt_vldu_vstu[i] = '0;
      for (int j = 0; j < 2; j++) cmpcnt_vldu_vstu[i] += cmp_vldu_vstu[i][j];
    end
  end
  always_ff @(posedge clock)
    for (int r = 0; r < 8; r++)
      for (int j = 0; j < 2; j++)
        sort_vldu_vstu[r][j] <= (cmpcnt_vldu_vstu[j] == (2-1-(r % 2)));

  // ---- 6. fuTypeOH:renameIn 每条 uop 命中哪个 needMultiExu 组 ----
  logic [34:0] ri_fuType [RENAME_WIDTH];
  assign ri_fuType[0] = io_renameIn_0_bits_fuType;
  assign ri_fuType[1] = io_renameIn_1_bits_fuType;
  assign ri_fuType[2] = io_renameIn_2_bits_fuType;
  assign ri_fuType[3] = io_renameIn_3_bits_fuType;
  assign ri_fuType[4] = io_renameIn_4_bits_fuType;
  assign ri_fuType[5] = io_renameIn_5_bits_fuType;
  logic fuTypeOH [RENAME_WIDTH][10];
  logic [RENAME_WIDTH-1:0] multiHit;   // 该 uop 命中任一多 EXU 组
  always_comb for (int i = 0; i < RENAME_WIDTH; i++) begin
    logic mh;
    mh = 1'b0;
    fuTypeOH[i][0] = (ri_fuType[i][0] | ri_fuType[i][1]) & ri_valid[i];
    mh = mh | fuTypeOH[i][0];
    fuTypeOH[i][1] = (ri_fuType[i][6]) & ri_valid[i];
    mh = mh | fuTypeOH[i][1];
    fuTypeOH[i][2] = (ri_fuType[i][7] | ri_fuType[i][10]) & ri_valid[i];
    mh = mh | fuTypeOH[i][2];
    fuTypeOH[i][3] = (ri_fuType[i][11] | ri_fuType[i][12]) & ri_valid[i];
    mh = mh | fuTypeOH[i][3];
    fuTypeOH[i][4] = (ri_fuType[i][14]) & ri_valid[i];
    mh = mh | fuTypeOH[i][4];
    fuTypeOH[i][5] = (ri_fuType[i][15]) & ri_valid[i];
    mh = mh | fuTypeOH[i][5];
    fuTypeOH[i][6] = (ri_fuType[i][16] | ri_fuType[i][17]) & ri_valid[i];
    mh = mh | fuTypeOH[i][6];
    fuTypeOH[i][7] = (ri_fuType[i][19] | ri_fuType[i][25]) & ri_valid[i];
    mh = mh | fuTypeOH[i][7];
    fuTypeOH[i][8] = (ri_fuType[i][24]) & ri_valid[i];
    mh = mh | fuTypeOH[i][8];
    fuTypeOH[i][9] = (ri_fuType[i][31] | ri_fuType[i][32]) & ri_valid[i];
    mh = mh | fuTypeOH[i][9];
    multiHit[i] = mh;
  end

  // ---- 7. uopSelIQ:每条 uop 选中的 IQ(one-hot,寄一拍)----
  // toRenameAllFire 时更新:命中多 EXU 组→取该组 IQSort[i%iqNum] 对应列;否则单 IQ 直接译码。
  // 否则若本条已 fire→清零。
  logic uopSelIQ [RENAME_WIDTH][NUM_IQ];
  logic uopSelIQ_next [RENAME_WIDTH][NUM_IQ];
  // popFuTypeOH[i][g]:前 i 条 uop 命中组 g 的累计数(决定本条用 IQSort 第几行)
  logic [2:0] popFuTypeOH [RENAME_WIDTH][10];
  always_comb for (int g = 0; g < 10; g++) begin
    logic [2:0] acc;
    acc = '0;
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      popFuTypeOH[i][g] = acc;   // 不含自己
      acc += fuTypeOH[i][g];
    end
  end
  // selPop[i] = Mux1H(fuTypeOH[i], popFuTypeOH[i]):本条命中组的 pop 计数(OR 合成,
  //   与 golden _GEN_600 一致;正常 one-hot 时即唯一命中组的 pop)。所有组共用此行索引。
  logic [2:0] selPop [RENAME_WIDTH];
  always_comb for (int i = 0; i < RENAME_WIDTH; i++) begin
    logic [2:0] sp;
    sp = '0;
    for (int g = 0; g < 10; g++) sp = sp | (fuTypeOH[i][g] ? popFuTypeOH[i][g] : 3'h0);
    selPop[i] = sp;
  end
  logic rowsel_jmp_brh [RENAME_WIDTH][3];
  logic rowsel_alu [RENAME_WIDTH][4];
  logic rowsel_mul_bku [RENAME_WIDTH][2];
  logic rowsel_falu_fmac [RENAME_WIDTH][3];
  logic rowsel_fdiv [RENAME_WIDTH][2];
  logic rowsel_ldu [RENAME_WIDTH][3];
  logic rowsel_sta_mou [RENAME_WIDTH][2];
  logic rowsel_vialuFix_vfma [RENAME_WIDTH][2];
  logic rowsel_vfalu [RENAME_WIDTH][2];
  logic rowsel_vldu_vstu [RENAME_WIDTH][2];
  always_comb for (int i = 0; i < RENAME_WIDTH; i++) begin
    for (int c = 0; c < 3; c++) begin
      case (selPop[i])
        3'd0: rowsel_jmp_brh[i][c] = sort_jmp_brh[0][c];
        3'd1: rowsel_jmp_brh[i][c] = sort_jmp_brh[1][c];
        3'd2: rowsel_jmp_brh[i][c] = sort_jmp_brh[2][c];
        3'd3: rowsel_jmp_brh[i][c] = sort_jmp_brh[3][c];
        3'd4: rowsel_jmp_brh[i][c] = sort_jmp_brh[4][c];
        3'd5: rowsel_jmp_brh[i][c] = sort_jmp_brh[5][c];
        default: rowsel_jmp_brh[i][c] = sort_jmp_brh[0][c];
      endcase
    end
    for (int c = 0; c < 4; c++) begin
      case (selPop[i])
        3'd0: rowsel_alu[i][c] = sort_alu[0][c];
        3'd1: rowsel_alu[i][c] = sort_alu[1][c];
        3'd2: rowsel_alu[i][c] = sort_alu[2][c];
        3'd3: rowsel_alu[i][c] = sort_alu[3][c];
        3'd4: rowsel_alu[i][c] = sort_alu[4][c];
        3'd5: rowsel_alu[i][c] = sort_alu[5][c];
        default: rowsel_alu[i][c] = sort_alu[0][c];
      endcase
    end
    for (int c = 0; c < 2; c++) begin
      case (selPop[i])
        3'd0: rowsel_mul_bku[i][c] = sort_mul_bku[0][c];
        3'd1: rowsel_mul_bku[i][c] = sort_mul_bku[1][c];
        3'd2: rowsel_mul_bku[i][c] = sort_mul_bku[2][c];
        3'd3: rowsel_mul_bku[i][c] = sort_mul_bku[3][c];
        3'd4: rowsel_mul_bku[i][c] = sort_mul_bku[4][c];
        3'd5: rowsel_mul_bku[i][c] = sort_mul_bku[5][c];
        default: rowsel_mul_bku[i][c] = sort_mul_bku[0][c];
      endcase
    end
    for (int c = 0; c < 3; c++) begin
      case (selPop[i])
        3'd0: rowsel_falu_fmac[i][c] = sort_falu_fmac[0][c];
        3'd1: rowsel_falu_fmac[i][c] = sort_falu_fmac[1][c];
        3'd2: rowsel_falu_fmac[i][c] = sort_falu_fmac[2][c];
        3'd3: rowsel_falu_fmac[i][c] = sort_falu_fmac[3][c];
        3'd4: rowsel_falu_fmac[i][c] = sort_falu_fmac[4][c];
        3'd5: rowsel_falu_fmac[i][c] = sort_falu_fmac[5][c];
        default: rowsel_falu_fmac[i][c] = sort_falu_fmac[0][c];
      endcase
    end
    for (int c = 0; c < 2; c++) begin
      case (selPop[i])
        3'd0: rowsel_fdiv[i][c] = sort_fdiv[0][c];
        3'd1: rowsel_fdiv[i][c] = sort_fdiv[1][c];
        3'd2: rowsel_fdiv[i][c] = sort_fdiv[2][c];
        3'd3: rowsel_fdiv[i][c] = sort_fdiv[3][c];
        3'd4: rowsel_fdiv[i][c] = sort_fdiv[4][c];
        3'd5: rowsel_fdiv[i][c] = sort_fdiv[5][c];
        default: rowsel_fdiv[i][c] = sort_fdiv[0][c];
      endcase
    end
    for (int c = 0; c < 3; c++) begin
      case (selPop[i])
        3'd0: rowsel_ldu[i][c] = sort_ldu[0][c];
        3'd1: rowsel_ldu[i][c] = sort_ldu[1][c];
        3'd2: rowsel_ldu[i][c] = sort_ldu[2][c];
        3'd3: rowsel_ldu[i][c] = sort_ldu[3][c];
        3'd4: rowsel_ldu[i][c] = sort_ldu[4][c];
        3'd5: rowsel_ldu[i][c] = sort_ldu[5][c];
        default: rowsel_ldu[i][c] = sort_ldu[0][c];
      endcase
    end
    for (int c = 0; c < 2; c++) begin
      case (selPop[i])
        3'd0: rowsel_sta_mou[i][c] = sort_sta_mou[0][c];
        3'd1: rowsel_sta_mou[i][c] = sort_sta_mou[1][c];
        3'd2: rowsel_sta_mou[i][c] = sort_sta_mou[2][c];
        3'd3: rowsel_sta_mou[i][c] = sort_sta_mou[3][c];
        3'd4: rowsel_sta_mou[i][c] = sort_sta_mou[4][c];
        3'd5: rowsel_sta_mou[i][c] = sort_sta_mou[5][c];
        default: rowsel_sta_mou[i][c] = sort_sta_mou[0][c];
      endcase
    end
    for (int c = 0; c < 2; c++) begin
      case (selPop[i])
        3'd0: rowsel_vialuFix_vfma[i][c] = sort_vialuFix_vfma[0][c];
        3'd1: rowsel_vialuFix_vfma[i][c] = sort_vialuFix_vfma[1][c];
        3'd2: rowsel_vialuFix_vfma[i][c] = sort_vialuFix_vfma[2][c];
        3'd3: rowsel_vialuFix_vfma[i][c] = sort_vialuFix_vfma[3][c];
        3'd4: rowsel_vialuFix_vfma[i][c] = sort_vialuFix_vfma[4][c];
        3'd5: rowsel_vialuFix_vfma[i][c] = sort_vialuFix_vfma[5][c];
        default: rowsel_vialuFix_vfma[i][c] = sort_vialuFix_vfma[0][c];
      endcase
    end
    for (int c = 0; c < 2; c++) begin
      case (selPop[i])
        3'd0: rowsel_vfalu[i][c] = sort_vfalu[0][c];
        3'd1: rowsel_vfalu[i][c] = sort_vfalu[1][c];
        3'd2: rowsel_vfalu[i][c] = sort_vfalu[2][c];
        3'd3: rowsel_vfalu[i][c] = sort_vfalu[3][c];
        3'd4: rowsel_vfalu[i][c] = sort_vfalu[4][c];
        3'd5: rowsel_vfalu[i][c] = sort_vfalu[5][c];
        default: rowsel_vfalu[i][c] = sort_vfalu[0][c];
      endcase
    end
    for (int c = 0; c < 2; c++) begin
      case (selPop[i])
        3'd0: rowsel_vldu_vstu[i][c] = sort_vldu_vstu[0][c];
        3'd1: rowsel_vldu_vstu[i][c] = sort_vldu_vstu[1][c];
        3'd2: rowsel_vldu_vstu[i][c] = sort_vldu_vstu[2][c];
        3'd3: rowsel_vldu_vstu[i][c] = sort_vldu_vstu[3][c];
        3'd4: rowsel_vldu_vstu[i][c] = sort_vldu_vstu[4][c];
        3'd5: rowsel_vldu_vstu[i][c] = sort_vldu_vstu[5][c];
        default: rowsel_vldu_vstu[i][c] = sort_vldu_vstu[0][c];
      endcase
    end
  end
  always_comb for (int i = 0; i < RENAME_WIDTH; i++) begin
    for (int q = 0; q < NUM_IQ; q++) uopSelIQ_next[i][q] = 1'b0;
    uopSelIQ_next[i][0] = ri_valid[i] & multiHit[i] & (fuTypeOH[i][0] & rowsel_jmp_brh[i][0] | fuTypeOH[i][1] & rowsel_alu[i][0] | fuTypeOH[i][2] & rowsel_mul_bku[i][0]);
    uopSelIQ_next[i][1] = ri_valid[i] & multiHit[i] & (fuTypeOH[i][0] & rowsel_jmp_brh[i][1] | fuTypeOH[i][1] & rowsel_alu[i][1] | fuTypeOH[i][2] & rowsel_mul_bku[i][1]);
    uopSelIQ_next[i][2] = ri_valid[i] & (multiHit[i] ? (fuTypeOH[i][0] & rowsel_jmp_brh[i][2] | fuTypeOH[i][1] & rowsel_alu[i][2]) : (ri_fuType[i][2] | ri_fuType[i][3] | ri_fuType[i][28] | ri_fuType[i][29]));
    uopSelIQ_next[i][3] = ri_valid[i] & (multiHit[i] ? (fuTypeOH[i][1] & rowsel_alu[i][3]) : (ri_fuType[i][5] | ri_fuType[i][8] | ri_fuType[i][9]));
    uopSelIQ_next[i][4] = ri_valid[i] & (multiHit[i] ? (fuTypeOH[i][3] & rowsel_falu_fmac[i][0] | fuTypeOH[i][4] & rowsel_fdiv[i][0]) : (ri_fuType[i][4] | ri_fuType[i][13]));
    uopSelIQ_next[i][5] = ri_valid[i] & multiHit[i] & (fuTypeOH[i][3] & rowsel_falu_fmac[i][1] | fuTypeOH[i][4] & rowsel_fdiv[i][1]);
    uopSelIQ_next[i][6] = ri_valid[i] & multiHit[i] & (fuTypeOH[i][3] & rowsel_falu_fmac[i][2]);
    uopSelIQ_next[i][7] = ri_valid[i] & (multiHit[i] ? (fuTypeOH[i][7] & rowsel_vialuFix_vfma[i][0] | fuTypeOH[i][8] & rowsel_vfalu[i][0]) : (ri_fuType[i][18] | ri_fuType[i][20] | ri_fuType[i][21] | ri_fuType[i][27] | ri_fuType[i][30]));
    uopSelIQ_next[i][8] = ri_valid[i] & multiHit[i] & (fuTypeOH[i][7] & rowsel_vialuFix_vfma[i][1] | fuTypeOH[i][8] & rowsel_vfalu[i][1]);
    uopSelIQ_next[i][9] = ri_valid[i] & ~multiHit[i] & (ri_fuType[i][22] | ri_fuType[i][26]);
    uopSelIQ_next[i][10] = ri_valid[i] & multiHit[i] & (fuTypeOH[i][6] & rowsel_sta_mou[i][0]);
    uopSelIQ_next[i][11] = ri_valid[i] & multiHit[i] & (fuTypeOH[i][6] & rowsel_sta_mou[i][1]);
    uopSelIQ_next[i][12] = ri_valid[i] & multiHit[i] & (fuTypeOH[i][5] & rowsel_ldu[i][0]);
    uopSelIQ_next[i][13] = ri_valid[i] & multiHit[i] & (fuTypeOH[i][5] & rowsel_ldu[i][1]);
    uopSelIQ_next[i][14] = ri_valid[i] & multiHit[i] & (fuTypeOH[i][5] & rowsel_ldu[i][2]);
    uopSelIQ_next[i][15] = ri_valid[i] & (multiHit[i] ? (fuTypeOH[i][9] & rowsel_vldu_vstu[i][0]) : (ri_fuType[i][33] | ri_fuType[i][34]));
    uopSelIQ_next[i][16] = ri_valid[i] & multiHit[i] & (fuTypeOH[i][9] & rowsel_vldu_vstu[i][1]);
  end
  always_ff @(posedge clock)
    for (int i = 0; i < RENAME_WIDTH; i++)
      for (int q = 0; q < NUM_IQ; q++)
        if (toRenameAllFire) uopSelIQ[i][q] <= uopSelIQ_next[i][q];
        else if (firedVec[i]) uopSelIQ[i][q] <= 1'b0;

  // ---- 8. uopSelIQMatrix[i][q]:前 i+1 条 uop 里选了 IQ q 的累计数(前缀 popcount)----
  // body 据此为每个 enq 端口(q,enq)挑出 matrix==enq+1 的那条 uop(PriorityMux)。
  logic [2:0] uopSelIQMatrix [RENAME_WIDTH][NUM_IQ];
  always_comb for (int q = 0; q < NUM_IQ; q++) begin
    logic [2:0] acc;
    acc = '0;
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      acc += uopSelIQ[i][q];
      uopSelIQMatrix[i][q] = acc;
    end
  end
  // 每个 enq 端口的选择 one-hot:oh[p][i] = (matrix[i][iq(p)] == enq(p)+1)
  logic ohSel [IQ_ENQ_SUM][RENAME_WIDTH];
  always_comb for (int p = 0; p < IQ_ENQ_SUM; p++)
    for (int i = 0; i < RENAME_WIDTH; i++)
      ohSel[p][i] = (uopSelIQMatrix[i][p/NUM_ENQ] == (p%NUM_ENQ)+1);

  // ---- 9. singleStep(单步)FSM:dret 后只许提交一条机器指令 ----
  // S_HOLD:已锁存可提交 robIdx;redirect 时翻转 flag。见 docs §2.4。
  sstep_state_e sstepState;
  logic robidxStepReg_flag;  logic [7:0] robidxStepReg_value;
  logic robidxStepHold_flag; logic [7:0] robidxStepHold_value;
  logic robidxCommit_flag;   logic [7:0] robidxCommit_value;
  logic ss_hold;  // 本拍进入 hold(singleStep & uop0 fire)
  assign ss_hold = io_singleStep & firedVec[0];
  always_comb begin
    robidxStepHold_flag  = io_singleStep & ss_hold & io_fromRename_0_bits_robIdx_flag;
    robidxStepHold_value = (io_singleStep & ss_hold) ? io_fromRename_0_bits_robIdx_value : 8'h0;
    // 可提交点:UPDATE 态取 hold;HOLD 态 redirect 翻 flag 否则取 reg
    if (sstepState == S_UPDATE_ROBIDX) begin
      robidxCommit_flag  = robidxStepHold_flag;
      robidxCommit_value = robidxStepHold_value;
    end else if (io_redirect_valid) begin
      robidxCommit_flag  = ~robidxStepReg_flag;
      robidxCommit_value = 8'h0;
    end else begin
      robidxCommit_flag  = robidxStepReg_flag;
      robidxCommit_value = robidxStepReg_value;
    end
  end
  always_ff @(posedge clock or posedge reset)
    if (reset) begin
      sstepState <= S_UPDATE_ROBIDX;
      robidxStepReg_flag <= 1'b0; robidxStepReg_value <= 8'h0;
    end else begin
      if (!io_singleStep) sstepState <= S_UPDATE_ROBIDX;
      else if (ss_hold & io_enqRob_req_0_valid) sstepState <= S_HOLD_ROBIDX;
      robidxStepReg_flag  <= robidxCommit_flag;
      robidxStepReg_value <= robidxCommit_value;
    end
  // 每条 uop 的 singleStep 标志 = singleStep & (robIdx != 可提交点)
  logic [RENAME_WIDTH-1:0] uopSingleStep;
  assign uopSingleStep[0] = io_singleStep & ({io_fromRename_0_bits_robIdx_flag, io_fromRename_0_bits_robIdx_value} != {robidxCommit_flag, robidxCommit_value});
  assign uopSingleStep[1] = io_singleStep & ({io_fromRename_1_bits_robIdx_flag, io_fromRename_1_bits_robIdx_value} != {robidxCommit_flag, robidxCommit_value});
  assign uopSingleStep[2] = io_singleStep & ({io_fromRename_2_bits_robIdx_flag, io_fromRename_2_bits_robIdx_value} != {robidxCommit_flag, robidxCommit_value});
  assign uopSingleStep[3] = io_singleStep & ({io_fromRename_3_bits_robIdx_flag, io_fromRename_3_bits_robIdx_value} != {robidxCommit_flag, robidxCommit_value});
  assign uopSingleStep[4] = io_singleStep & ({io_fromRename_4_bits_robIdx_flag, io_fromRename_4_bits_robIdx_value} != {robidxCommit_flag, robidxCommit_value});
  assign uopSingleStep[5] = io_singleStep & ({io_fromRename_5_bits_robIdx_flag, io_fromRename_5_bits_robIdx_value} != {robidxCommit_flag, robidxCommit_value});

  // ---- 10. conserveFlow:LSQ 流数保守上界(标量=1 / unit-stride=2 / 其他向量=16)----
  // 见 docs §2.3。conserveFlowTotal = {highCount(is16 前缀和), lowCount({is2,is1} 前缀和)}。
  // toRenameAllFire 时用 renameIn 早一拍的值,否则用 fromRename 当拍值,寄一拍。
  logic [RENAME_WIDTH-1:0] is16_d, is2_d, is1_d;   // dispatch 侧(fromRename)
  logic [RENAME_WIDTH-1:0] is16_r, is2_r, is1_r;   // rename 侧(renameIn)
  logic [3:0] rn_fuOpType_lo [RENAME_WIDTH];  // fuOpType[8:5] 判 unit-stride
  assign rn_fuOpType_lo[0] = io_fromRename_0_bits_fuOpType[8:5];
  assign rn_fuOpType_lo[1] = io_fromRename_1_bits_fuOpType[8:5];
  assign rn_fuOpType_lo[2] = io_fromRename_2_bits_fuOpType[8:5];
  assign rn_fuOpType_lo[3] = io_fromRename_3_bits_fuOpType[8:5];
  assign rn_fuOpType_lo[4] = io_fromRename_4_bits_fuOpType[8:5];
  assign rn_fuOpType_lo[5] = io_fromRename_5_bits_fuOpType[8:5];
  logic [34:0] rn_fuType [RENAME_WIDTH];
  logic [3:0]  ri_fuOpType_lo [RENAME_WIDTH];
  assign rn_fuType[0] = io_fromRename_0_bits_fuType;
  assign ri_fuOpType_lo[0] = io_renameIn_0_bits_fuOpType[8:5];
  assign rn_fuType[1] = io_fromRename_1_bits_fuType;
  assign ri_fuOpType_lo[1] = io_renameIn_1_bits_fuOpType[8:5];
  assign rn_fuType[2] = io_fromRename_2_bits_fuType;
  assign ri_fuOpType_lo[2] = io_renameIn_2_bits_fuOpType[8:5];
  assign rn_fuType[3] = io_fromRename_3_bits_fuType;
  assign ri_fuOpType_lo[3] = io_renameIn_3_bits_fuOpType[8:5];
  assign rn_fuType[4] = io_fromRename_4_bits_fuType;
  assign ri_fuOpType_lo[4] = io_renameIn_4_bits_fuOpType[8:5];
  assign rn_fuType[5] = io_fromRename_5_bits_fuType;
  assign ri_fuOpType_lo[5] = io_renameIn_5_bits_fuOpType[8:5];
  // isVlsType_N:向量访存判定(LsqEnqCtrl numLsElem mux 引用)
  wire isVlsType_0 = (io_fromRename_0_bits_fuType[31] | io_fromRename_0_bits_fuType[32] | io_fromRename_0_bits_fuType[33] | io_fromRename_0_bits_fuType[34]) & io_fromRename_0_valid;
  wire isVlsType_1 = (io_fromRename_1_bits_fuType[31] | io_fromRename_1_bits_fuType[32] | io_fromRename_1_bits_fuType[33] | io_fromRename_1_bits_fuType[34]) & io_fromRename_1_valid;
  wire isVlsType_2 = (io_fromRename_2_bits_fuType[31] | io_fromRename_2_bits_fuType[32] | io_fromRename_2_bits_fuType[33] | io_fromRename_2_bits_fuType[34]) & io_fromRename_2_valid;
  wire isVlsType_3 = (io_fromRename_3_bits_fuType[31] | io_fromRename_3_bits_fuType[32] | io_fromRename_3_bits_fuType[33] | io_fromRename_3_bits_fuType[34]) & io_fromRename_3_valid;
  wire isVlsType_4 = (io_fromRename_4_bits_fuType[31] | io_fromRename_4_bits_fuType[32] | io_fromRename_4_bits_fuType[33] | io_fromRename_4_bits_fuType[34]) & io_fromRename_4_valid;
  wire isVlsType_5 = (io_fromRename_5_bits_fuType[31] | io_fromRename_5_bits_fuType[32] | io_fromRename_5_bits_fuType[33] | io_fromRename_5_bits_fuType[34]) & io_fromRename_5_valid;
  always_comb for (int i = 0; i < RENAME_WIDTH; i++) begin
    logic vls_d, ls_d, us_d, vls_r, ls_r, us_r;
    // fromRename 侧:isVls=fuType[31..34];isLS=fuType[15]|[16];unit-stride 见 nd_is_unit_stride
    vls_d = (rn_fuType[i][31]|rn_fuType[i][32]|rn_fuType[i][33]|rn_fuType[i][34]) & rn_valid[i];
    ls_d  = (rn_fuType[i][15]|rn_fuType[i][16]) & rn_valid[i];
    us_d  = nd_is_unit_stride(rn_fuOpType_lo[i]);
    is16_d[i] = vls_d & ~us_d;
    is2_d[i]  = vls_d & us_d;
    is1_d[i]  = ls_d;
    // renameIn 侧(注意 golden/Scala 里 isLSTypeRename 的括号 bug:valid&[15] | [16])
    vls_r = ri_valid[i] & (ri_fuType[i][31]|ri_fuType[i][32]|ri_fuType[i][33]|ri_fuType[i][34]);
    ls_r  = (ri_valid[i] & ri_fuType[i][15]) | ri_fuType[i][16];
    us_r  = nd_is_unit_stride(ri_fuOpType_lo[i]);
    is16_r[i] = vls_r & ~us_r;
    is2_r[i]  = vls_r & us_r;
    is1_r[i]  = ls_r;
  end
  logic [6:0] conserveFlowTotal [RENAME_WIDTH];
  logic [6:0] cft_d [RENAME_WIDTH], cft_r [RENAME_WIDTH];
  always_comb begin
    logic [2:0] hi_d, hi_r; logic [3:0] lo_d, lo_r;
    hi_d = '0; lo_d = '0; hi_r = '0; lo_r = '0;
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      hi_d += is16_d[i]; lo_d += {is2_d[i], is1_d[i]};
      hi_r += is16_r[i]; lo_r += {is2_r[i], is1_r[i]};
      cft_d[i] = {hi_d, lo_d};
      cft_r[i] = {hi_r, lo_r};
    end
  end
  always_ff @(posedge clock)
    for (int i = 0; i < RENAME_WIDTH; i++)
      conserveFlowTotal[i] <= toRenameAllFire ? cft_r[i] : cft_d[i];

  // ---- 11. allowDispatch:LSQ 空闲表项是否够本条保守流数(前缀串行依赖前一条)----
  // lsq_sqFreeCount/lqFreeCount/canAccept 来自 LsqEnqCtrl(connect.svh 填入)。
  logic [5:0] lsq_sqFreeCount;  logic [6:0] lsq_lqFreeCount;  logic lsq_canAccept;
  logic [RENAME_WIDTH-1:0] allowDispatch;
  logic [6:0] sqFree7, lqFree7;
  assign sqFree7 = {1'b0, lsq_sqFreeCount};   // sqFreeCount 6bit → 补 0 到 7bit
  assign lqFree7 = lsq_lqFreeCount;           // lqFreeCount 已 7bit
  logic [RENAME_WIDTH-1:0] isVStoreUop, isVLoadUop;
  assign isVStoreUop[0] = io_fromRename_0_valid & (io_fromRename_0_bits_fuType[16] | io_fromRename_0_bits_fuType[32] | io_fromRename_0_bits_fuType[34]);
  assign isVLoadUop[0]  = io_fromRename_0_valid & (io_fromRename_0_bits_fuType[15] | io_fromRename_0_bits_fuType[31] | io_fromRename_0_bits_fuType[33]);
  assign isVStoreUop[1] = io_fromRename_1_valid & (io_fromRename_1_bits_fuType[16] | io_fromRename_1_bits_fuType[32] | io_fromRename_1_bits_fuType[34]);
  assign isVLoadUop[1]  = io_fromRename_1_valid & (io_fromRename_1_bits_fuType[15] | io_fromRename_1_bits_fuType[31] | io_fromRename_1_bits_fuType[33]);
  assign isVStoreUop[2] = io_fromRename_2_valid & (io_fromRename_2_bits_fuType[16] | io_fromRename_2_bits_fuType[32] | io_fromRename_2_bits_fuType[34]);
  assign isVLoadUop[2]  = io_fromRename_2_valid & (io_fromRename_2_bits_fuType[15] | io_fromRename_2_bits_fuType[31] | io_fromRename_2_bits_fuType[33]);
  assign isVStoreUop[3] = io_fromRename_3_valid & (io_fromRename_3_bits_fuType[16] | io_fromRename_3_bits_fuType[32] | io_fromRename_3_bits_fuType[34]);
  assign isVLoadUop[3]  = io_fromRename_3_valid & (io_fromRename_3_bits_fuType[15] | io_fromRename_3_bits_fuType[31] | io_fromRename_3_bits_fuType[33]);
  assign isVStoreUop[4] = io_fromRename_4_valid & (io_fromRename_4_bits_fuType[16] | io_fromRename_4_bits_fuType[32] | io_fromRename_4_bits_fuType[34]);
  assign isVLoadUop[4]  = io_fromRename_4_valid & (io_fromRename_4_bits_fuType[15] | io_fromRename_4_bits_fuType[31] | io_fromRename_4_bits_fuType[33]);
  assign isVStoreUop[5] = io_fromRename_5_valid & (io_fromRename_5_bits_fuType[16] | io_fromRename_5_bits_fuType[32] | io_fromRename_5_bits_fuType[34]);
  assign isVLoadUop[5]  = io_fromRename_5_valid & (io_fromRename_5_bits_fuType[15] | io_fromRename_5_bits_fuType[31] | io_fromRename_5_bits_fuType[33]);
  // golden:vstore→sqFree>cft;否则→(~vload | lqFree>cft);均 & 前一条 allowDispatch。
  // 先算每条「自身条件」self,再用独立 prefix 变量做前缀与(避免在 always_comb 里
  // 同时读写 allowDispatch,绕开 FMR_VLOG-929)。
  logic [RENAME_WIDTH-1:0] allowSelf;
  always_comb for (int i = 0; i < RENAME_WIDTH; i++)
    allowSelf[i] = isVStoreUop[i] ? (sqFree7 > conserveFlowTotal[i])
                                  : (~isVLoadUop[i] | (lqFree7 > conserveFlowTotal[i]));
  always_comb begin
    logic pfx;
    pfx = 1'b1;
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      pfx = pfx & allowSelf[i];
      allowDispatch[i] = pfx;
    end
  end

  // ---- 12. uopBlockByIQ:落到某 IQ 的 uop 数超过其 enq 数(或该 IQ 当拍 not-ready)→ 挡住 ----
  // 只看每 IQ 第 0 个 enq 端口的 ready(偶数号 toIssueQueues_ready);见 docs §5。
  logic [NUM_IQ-1:0] iq_ready0;   // 每 IQ enq0 端口 ready
  assign iq_ready0[0] = io_toIssueQueues_0_ready;
  assign iq_ready0[1] = io_toIssueQueues_2_ready;
  assign iq_ready0[2] = io_toIssueQueues_4_ready;
  assign iq_ready0[3] = io_toIssueQueues_6_ready;
  assign iq_ready0[4] = io_toIssueQueues_8_ready;
  assign iq_ready0[5] = io_toIssueQueues_10_ready;
  assign iq_ready0[6] = io_toIssueQueues_12_ready;
  assign iq_ready0[7] = io_toIssueQueues_14_ready;
  assign iq_ready0[8] = io_toIssueQueues_16_ready;
  assign iq_ready0[9] = io_toIssueQueues_18_ready;
  assign iq_ready0[10] = io_toIssueQueues_20_ready;
  assign iq_ready0[11] = io_toIssueQueues_22_ready;
  assign iq_ready0[12] = io_toIssueQueues_24_ready;
  assign iq_ready0[13] = io_toIssueQueues_26_ready;
  assign iq_ready0[14] = io_toIssueQueues_28_ready;
  assign iq_ready0[15] = io_toIssueQueues_30_ready;
  assign iq_ready0[16] = io_toIssueQueues_32_ready;
  logic [RENAME_WIDTH-1:0] uopBlockByIQ;
  always_comb for (int i = 0; i < RENAME_WIDTH; i++) begin
    logic blkAcc;
    blkAcc = 1'b0;
    for (int q = 0; q < NUM_IQ; q++)
      // ready 时:matrix>numEnq(=2) 才超容量;not-ready 时:有任意 uop(matrix!=0)就挡。
      blkAcc = blkAcc | (iq_ready0[q] ? (uopSelIQMatrix[i][q] > NUM_ENQ) : (uopSelIQMatrix[i][q] != 0));
    uopBlockByIQ[i] = blkAcc;
  end

  // ---- 13. 按序入队约束 ----
  // blockedByWaitForward[i]:本条 waitForward 且(ROB 非空或前面有 valid)→ 自己被挡(前缀或)。
  // notBlockedByPrevious[i]:前面无 blockBackward。thisCanActualOut = ~waitFwd & notBlocked & canAccept。
  logic [RENAME_WIDTH-1:0] isBlockBackward, blockedByWaitForward, thisCanActualOut;
  always_comb for (int i = 0; i < RENAME_WIDTH; i++)
    isBlockBackward[i] = rn_valid[i] & rn_blockBkwd[i];
  // 用独立 prefix 变量做前缀或(避免 always_comb 内同时读写 blockedByWaitForward)。
  always_comb begin
    logic prevValidOr, pfxBlk;
    pfxBlk = 1'b0;
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      prevValidOr = ~io_enqRob_isEmpty;
      for (int j = 0; j < i; j++) prevValidOr |= rn_valid[j];
      pfxBlk = pfxBlk | (prevValidOr & rn_valid[i] & rn_waitFwd[i]);
      blockedByWaitForward[i] = pfxBlk;
    end
  end
  always_comb for (int i = 0; i < RENAME_WIDTH; i++) begin
    logic notBlk;
    notBlk = 1'b1;
    for (int j = 0; j < i; j++) notBlk &= ~isBlockBackward[j];
    thisCanActualOut[i] = ~blockedByWaitForward[i] & notBlk & io_enqRob_canAccept;
  end

  // ---- 14. ready 反压 + fromRenameUpdate.valid ----
  // 把四个反压条件聚成 dispatch_gate_t(见 pkg);ready = 四者与。
  // update.valid 在 ready 基础上再 & valid & ~elimMove & ~hasException & ~singleStep。
  logic [RENAME_WIDTH-1:0] fromRenameUpdate_valid;
  dispatch_gate_t gate [RENAME_WIDTH];
  always_comb for (int i = 0; i < RENAME_WIDTH; i++) begin
    gate[i].allow_dispatch  = allowDispatch[i];
    gate[i].not_block_by_iq = ~uopBlockByIQ[i];
    gate[i].can_actual_out  = thisCanActualOut[i];
    gate[i].lsq_can_accept  = lsq_canAccept;
    rn_ready[i] = nd_dispatch_ready(gate[i]);
    fromRenameUpdate_valid[i] = rn_ready[i] & rn_valid[i]
      & ~rn_elimMove[i] & ~rn_hasExc[i] & ~uopSingleStep[i];
  end
  assign io_fromRename_0_ready = rn_ready[0];
  assign io_fromRename_1_ready = rn_ready[1];
  assign io_fromRename_2_ready = rn_ready[2];
  assign io_fromRename_3_ready = rn_ready[3];
  assign io_fromRename_4_ready = rn_ready[4];
  assign io_fromRename_5_ready = rn_ready[5];

  // ---- 15. fromRenameUpdate 改写字段(其余字段直通 fromRename,见 connect.svh)----
  // srcType_2:ignoreOldVd 时改 SrcType.no(0);isDropAmocasSta:AMOCAS 且 uopIdx[0]==0;
  // singleStep 见上;srcLoadDependency:int 源取 busyTable.loadDependency,否则 0。
  logic [3:0] fru_srcType2 [RENAME_WIDTH];
  logic [RENAME_WIDTH-1:0] fru_isDropAmocasSta;
  always_comb for (int i = 0; i < RENAME_WIDTH; i++)
    fru_srcType2[i] = (rn_srcType[i][2][2] & ignoreOldVd[i]) ? SRCTYPE_NO_VAL : rn_srcType[i][2];
  assign fru_isDropAmocasSta[0] = io_fromRename_0_bits_fuType[17] & (io_fromRename_0_bits_fuOpType[5:2] == 4'hB) & ~io_fromRename_0_bits_uopIdx[0];
  assign fru_isDropAmocasSta[1] = io_fromRename_1_bits_fuType[17] & (io_fromRename_1_bits_fuOpType[5:2] == 4'hB) & ~io_fromRename_1_bits_uopIdx[0];
  assign fru_isDropAmocasSta[2] = io_fromRename_2_bits_fuType[17] & (io_fromRename_2_bits_fuOpType[5:2] == 4'hB) & ~io_fromRename_2_bits_uopIdx[0];
  assign fru_isDropAmocasSta[3] = io_fromRename_3_bits_fuType[17] & (io_fromRename_3_bits_fuOpType[5:2] == 4'hB) & ~io_fromRename_3_bits_uopIdx[0];
  assign fru_isDropAmocasSta[4] = io_fromRename_4_bits_fuType[17] & (io_fromRename_4_bits_fuOpType[5:2] == 4'hB) & ~io_fromRename_4_bits_uopIdx[0];
  assign fru_isDropAmocasSta[5] = io_fromRename_5_bits_fuType[17] & (io_fromRename_5_bits_fuOpType[5:2] == 4'hB) & ~io_fromRename_5_bits_uopIdx[0];
  // srcLoadDependency:仅 int 两源(j=0,1),取对应 busyTable 读端口 loadDependency(若该源是 int)。
  // 维度 [uop][srcsel(0|1)][ldep(0..2)];busyTable loadDependency 由 connect.svh 填入。
  logic [LDEP_W-1:0] bt_int_ldep [RENAME_WIDTH*2][LDEP_N];
  logic [LDEP_W-1:0] fru_srcLoadDep [RENAME_WIDTH][2][LDEP_N];
  always_comb for (int i = 0; i < RENAME_WIDTH; i++)
    for (int s = 0; s < 2; s++)
      for (int d = 0; d < LDEP_N; d++)
        fru_srcLoadDep[i][s][d] = rn_srcType[i][s][0] ? bt_int_ldep[i*2+s][d] : '0;

  // ---- 16. enqRob:valid=fire;needAlloc=valid;hasException/numWB/singleStep 改写 ----
  logic [RENAME_WIDTH-1:0] enqRob_hasExc, enqRob_singleStep;
  logic [6:0] enqRob_numWB [RENAME_WIDTH];
  assign io_enqRob_req_0_valid = firedVec[0];
  assign enqRob_singleStep[0] = uopSingleStep[0];
  assign enqRob_hasExc[0] = io_fromRename_0_bits_hasException | uopSingleStep[0];
  assign enqRob_numWB[0] = uopSingleStep[0] ? 7'h0 : io_fromRename_0_bits_numWB;
  assign io_enqRob_req_0_bits_hasException = enqRob_hasExc[0];
  assign io_enqRob_req_0_bits_singleStep   = enqRob_singleStep[0];
  assign io_enqRob_req_0_bits_numWB        = enqRob_numWB[0];
  assign io_enqRob_req_1_valid = firedVec[1];
  assign enqRob_singleStep[1] = uopSingleStep[1];
  assign enqRob_hasExc[1] = io_fromRename_1_bits_hasException | uopSingleStep[1];
  assign enqRob_numWB[1] = uopSingleStep[1] ? 7'h0 : io_fromRename_1_bits_numWB;
  assign io_enqRob_req_1_bits_hasException = enqRob_hasExc[1];
  assign io_enqRob_req_1_bits_singleStep   = enqRob_singleStep[1];
  assign io_enqRob_req_1_bits_numWB        = enqRob_numWB[1];
  assign io_enqRob_req_2_valid = firedVec[2];
  assign enqRob_singleStep[2] = uopSingleStep[2];
  assign enqRob_hasExc[2] = io_fromRename_2_bits_hasException | uopSingleStep[2];
  assign enqRob_numWB[2] = uopSingleStep[2] ? 7'h0 : io_fromRename_2_bits_numWB;
  assign io_enqRob_req_2_bits_hasException = enqRob_hasExc[2];
  assign io_enqRob_req_2_bits_singleStep   = enqRob_singleStep[2];
  assign io_enqRob_req_2_bits_numWB        = enqRob_numWB[2];
  assign io_enqRob_req_3_valid = firedVec[3];
  assign enqRob_singleStep[3] = uopSingleStep[3];
  assign enqRob_hasExc[3] = io_fromRename_3_bits_hasException | uopSingleStep[3];
  assign enqRob_numWB[3] = uopSingleStep[3] ? 7'h0 : io_fromRename_3_bits_numWB;
  assign io_enqRob_req_3_bits_hasException = enqRob_hasExc[3];
  assign io_enqRob_req_3_bits_singleStep   = enqRob_singleStep[3];
  assign io_enqRob_req_3_bits_numWB        = enqRob_numWB[3];
  assign io_enqRob_req_4_valid = firedVec[4];
  assign enqRob_singleStep[4] = uopSingleStep[4];
  assign enqRob_hasExc[4] = io_fromRename_4_bits_hasException | uopSingleStep[4];
  assign enqRob_numWB[4] = uopSingleStep[4] ? 7'h0 : io_fromRename_4_bits_numWB;
  assign io_enqRob_req_4_bits_hasException = enqRob_hasExc[4];
  assign io_enqRob_req_4_bits_singleStep   = enqRob_singleStep[4];
  assign io_enqRob_req_4_bits_numWB        = enqRob_numWB[4];
  assign io_enqRob_req_5_valid = firedVec[5];
  assign enqRob_singleStep[5] = uopSingleStep[5];
  assign enqRob_hasExc[5] = io_fromRename_5_bits_hasException | uopSingleStep[5];
  assign enqRob_numWB[5] = uopSingleStep[5] ? 7'h0 : io_fromRename_5_bits_numWB;
  assign io_enqRob_req_5_bits_hasException = enqRob_hasExc[5];
  assign io_enqRob_req_5_bits_singleStep   = enqRob_singleStep[5];
  assign io_enqRob_req_5_bits_numWB        = enqRob_numWB[5];

  // ---- 17. canAccept / stallReason / perf 计数 ----
  // canAccept = 无 valid 指令,或(无 blockBackward 且 ROB 可入队)。
  logic hasValidInstr, hasSpecialInstr, canAccept;
  always_comb begin
    hasValidInstr = 1'b0; hasSpecialInstr = 1'b0;
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      hasValidInstr   |= rn_valid[i];
      hasSpecialInstr |= isBlockBackward[i];
    end
    canAccept = ~hasValidInstr | (~hasSpecialInstr & io_enqRob_canAccept);
  end
  assign io_stallReason_backReason_valid = ~canAccept;
  // stall 探针
  logic stall_rob, stall_fp_dq;
  assign stall_rob   = hasValidInstr & ~io_enqRob_canAccept;
  assign stall_fp_dq = hasValidInstr & io_enqRob_canAccept;
  // perf 事件:dispatch_in(valid&ready0) / dispatch_empty / dispatch_utili(valid) /
  //   dispatch_waitinstr(~valid&canAccept) / stall_rob / stall_*_dq(=stall_fp_dq)。HasPerfEvents 双拍寄存。
  logic [2:0] cnt_in, cnt_util, cnt_wait;
  always_comb begin
    cnt_in = '0; cnt_util = '0; cnt_wait = '0;
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      cnt_in   += (rn_valid[i] & rn_ready[0]);
      cnt_util += rn_valid[i];
      cnt_wait += (~rn_valid[i] & canAccept);
    end
  end
  logic [2:0] perf0_r, perf0_rr, perf2_r, perf2_rr, perf3_r, perf3_rr;
  logic perf1_r, perf1_rr, perf5_r, perf5_rr, perf6_r, perf6_rr, perf7_r, perf7_rr, perf8_r, perf8_rr;
  always_ff @(posedge clock) begin
    perf0_r <= cnt_in;   perf0_rr <= perf0_r;
    perf1_r <= ~hasValidInstr; perf1_rr <= perf1_r;
    perf2_r <= cnt_util; perf2_rr <= perf2_r;
    perf3_r <= cnt_wait; perf3_rr <= perf3_r;
    perf5_r <= stall_rob;   perf5_rr <= perf5_r;
    perf6_r <= stall_fp_dq; perf6_rr <= perf6_r;
    perf7_r <= stall_fp_dq; perf7_rr <= perf7_r;
    perf8_r <= stall_fp_dq; perf8_rr <= perf8_r;
  end
  assign io_perf_0_value = {3'h0, perf0_rr};
  assign io_perf_1_value = {5'h0, perf1_rr};
  assign io_perf_2_value = {3'h0, perf2_rr};
  assign io_perf_3_value = {3'h0, perf3_rr};
  assign io_perf_5_value = {5'h0, perf5_rr};
  assign io_perf_6_value = {5'h0, perf6_rr};
  assign io_perf_7_value = {5'h0, perf7_rr};
  assign io_perf_8_value = {5'h0, perf8_rr};
