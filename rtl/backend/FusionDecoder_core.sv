// xs_FusionDecoder —— 可读重写核（指令融合解码器）
// ---------------------------------------------------------------------------
// 功能: 对 6 条连续取指(io_in_0..5)构成的 5 个相邻指令对(lane i = {in_i, in_{i+1}})
// 各自做「宏融合」模式匹配。每 lane 对指令对解码出 28 个融合候选 fusionVec[i][0..27]
// (硬 decode LUT), 打拍锁存, 组合产出:
//   - io_clear_{i+1}      = 本 lane 命中融合且未被前一 lane 抢占(优先级), 需清后一条指令
//   - io_out_i            = 融合后 uop 的 fuType/fuOpType/lsrc2/src2Type/selImm 覆写
//   - io_info_i           = rs2 来源(FromRs1/FromRs2/FromZero)
// 与 golden FusionDecoder.sv 逐位等价; lane 结构完全对称, 用 genvar 生成。
// decode LUT 常数与 golden firtool 输出一一对应(见各 fusionVec_* 表达式)。
// ---------------------------------------------------------------------------
module xs_FusionDecoder (
  input         clock,
  input         reset,
  input         disableFusion,
  // 6 条取指
  input         in_valid  [6],
  input  [31:0] in_bits   [6],
  // 5 个 lane 的下游 ready(决定本拍是否锁存新解码)
  input         inReady   [5],
  // 5 个 lane 的原始 fuOpType(用于 shift-add 类融合的 fuOpType 覆写)
  input  [8:0]  dec_fuOpType [5],
  // 输出: 5 lane
  output        out_valid                 [5],
  output        out_fuType_valid          [5],
  output        out_fuOpType_valid        [5],
  output [8:0]  out_fuOpType_bits         [5],
  output        out_lsrc2_valid           [5],
  output [5:0]  out_lsrc2_bits            [5],
  output        out_src2Type_valid        [5],
  output        out_selImm_valid          [5],
  output [3:0]  out_selImm_bits           [5],
  output        info_rs2FromRs1           [5],
  output        info_rs2FromRs2           [5],
  output        info_rs2FromZero          [5],
  // io_clear_1..5 (对应 in_1..5 是否被前面融合吃掉)
  output        clear                     [5]
);

  // ---- 每 lane 状态寄存器 ----
  reg          instrPairValid [5];
  reg          fusionVec      [5][28];
  reg          notHint        [5];
  reg          enabled        [5];
  reg          rs2FromRs1_r   [5];   // io_info_i_rs2FromRs1_r
  reg          rs2FromRs2_r   [5];   // io_info_i_rs2FromRs2_r
  reg  [4:0]   lsrc2_bits_r   [5];   // io_out_i_bits_lsrc2_bits_r
  reg          lastFire       [5];

  // ---- 组合信号 ----
  wire         fire         [5];   // 本 lane 本拍取指对被接收
  wire         clear_w      [5];   // io_clear_{i+1}_0
  wire [11:0]  src2WithMux  [5];   // 融合项子集: 需从 in_hi.rs2 取 src2
  wire [3:0]   src2WithZero [5];   // 融合项子集: src2 为 0
  wire         rs2FromRs2_T [5];

  genvar g;
  generate
    for (g = 0; g < 5; g = g + 1) begin : lane
      // lane g 处理 (in_g, in_{g+1})
      wire [31:0] lo = in_bits[g];
      wire [31:0] hi = in_bits[g+1];

      assign fire[g] = in_valid[g] & inReady[g];

      // ---- decode LUT: 28 个融合候选(组合, 打拍前的下一态) ----
      wire [15:0] loA = {lo[31:26], lo[14:12], lo[6:0]};  // _GEN_168 系
      wire [16:0] loB = {lo[31:25], lo[14:12], lo[6:0]};  // _GEN_169 系
      wire [9:0]  loC = {lo[14:12], lo[6:0]};             // _GEN_170 系
      wire [21:0] loD = {lo[31:20], lo[14:12], lo[6:0]};  // _GEN_171 系
      wire [15:0] hiA = {hi[31:26], hi[14:12], hi[6:0]};  // _GEN_176 系
      wire [16:0] hiB = {hi[31:25], hi[14:12], hi[6:0]};
      wire [9:0]  hiC = {hi[14:12], hi[6:0]};
      wire [21:0] hiD = {hi[31:20], hi[14:12], hi[6:0]};

      wire        rdEqRd  = lo[11:7] == hi[11:7];      // dest 相同
      wire        rdEqRs1 = lo[11:7] == hi[19:15];     // 前 dest = 后 rs1
      wire        rdEqRs2 = lo[11:7] == hi[24:20];     // 前 dest = 后 rs2
      wire        rs1NeRs2 = hi[19:15] != hi[24:20];
      wire        rdChain = rdEqRs1 | rdEqRs2;         // 后指令读前指令结果

      // 融合候选下一态
      wire [27:0] fv;
      assign fv[0]  = loA == 16'h93  & lo[25:20] == 6'h20 & hiA == 16'h293 & hi[25:20] == 6'h20 & rdEqRd & rdEqRs1;
      assign fv[1]  = loA == 16'h93  & lo[25:20] == 6'h30 & hiA == 16'h293 & hi[25:20] == 6'h30 & rdEqRd & rdEqRs1;
      assign fv[2]  = loB == 17'h9B  & lo[24:20] == 5'h10 & hiB == 17'h29B & hi[24:20] == 5'h10 & rdEqRd & rdEqRs1;
      assign fv[3]  = loB == 17'h9B  & lo[24:20] == 5'h10 & hiB == 17'h829B & hi[24:20] == 5'h10 & rdEqRd & rdEqRs1;
      assign fv[4]  = loA == 16'h93  & lo[25:20] == 6'h1  & hiB == 17'h33  & rs1NeRs2 & rdEqRd & rdChain;
      assign fv[5]  = loA == 16'h93  & lo[25:20] == 6'h2  & hiB == 17'h33  & rs1NeRs2 & rdEqRd & rdChain;
      assign fv[6]  = loA == 16'h93  & lo[25:20] == 6'h3  & hiB == 17'h33  & rs1NeRs2 & rdEqRd & rdChain;
      assign fv[7]  = loA == 16'h93  & lo[25:20] == 6'h20 & hiA == 16'h293 & hi[25:20] == 6'h1F & rdEqRd & rdEqRs1;
      assign fv[8]  = loA == 16'h93  & lo[25:20] == 6'h20 & hiA == 16'h293 & hi[25:20] == 6'h1E & rdEqRd & rdEqRs1;
      assign fv[9]  = loA == 16'h93  & lo[25:20] == 6'h20 & hiA == 16'h293 & hi[25:20] == 6'h1D & rdEqRd & rdEqRs1;
      assign fv[10] = loA == 16'h293 & lo[25:20] == 6'h8  & hiC == 10'h393 & hi[31:20] == 12'hFF & rdEqRd & rdEqRs1;
      assign fv[11] = loA == 16'h93  & lo[25:20] == 6'h4  & hiB == 17'h33  & rs1NeRs2 & rdEqRd & rdChain;
      assign fv[12] = loA == 16'h293 & lo[25:20] == 6'h1D & hiB == 17'h33  & rs1NeRs2 & rdEqRd & rdChain;
      assign fv[13] = loA == 16'h293 & lo[25:20] == 6'h1E & hiB == 17'h33  & rs1NeRs2 & rdEqRd & rdChain;
      assign fv[14] = loA == 16'h293 & lo[25:20] == 6'h1F & hiB == 17'h33  & rs1NeRs2 & rdEqRd & rdChain;
      assign fv[15] = loA == 16'h293 & lo[25:20] == 6'h20 & hiB == 17'h33  & rs1NeRs2 & rdEqRd & rdChain;
      assign fv[16] = loC == 10'h393 & lo[31:20] == 12'h1 & hiB == 17'h33  & rs1NeRs2 & rdEqRd & rdChain;
      assign fv[17] = loC == 10'h393 & lo[31:20] == 12'h1 & hiB == 17'h3B  & rs1NeRs2 & rdEqRd & rdChain;
      assign fv[18] = loC == 10'h393 & lo[31:20] == 12'hF00 & hiB == 17'h333 & rs1NeRs2 & rdEqRd & rdChain;
      assign fv[19] = loC == 10'h393 & lo[31:20] == 12'h7F & hiB == 17'h43B & rs1NeRs2 & rdEqRd & rdChain;
      assign fv[20] = (loC == 10'h1B | loB == 17'h3B) & hiC == 10'h393 & hi[31:20] == 12'hFF & rdEqRd & rdEqRs1;
      assign fv[21] = (loC == 10'h1B | loB == 17'h3B) & hiC == 10'h393 & hi[31:20] == 12'h1  & rdEqRd & rdEqRs1;
      assign fv[22] = (loC == 10'h1B | loB == 17'h3B) & hiD == 22'h2023B  & rdEqRd & rdEqRs1;
      assign fv[23] = (loC == 10'h1B | loB == 17'h3B) & hiD == 22'h181493 & rdEqRd & rdEqRs1;
      assign fv[24] = (|{loD == 22'hA1E93, loB == 17'h233, loC == 10'h213, loB == 17'h333,
                         loC == 10'h313, loB == 17'h3B3, loC == 10'h393})
                      & hiC == 10'h393 & hi[31:20] == 12'h1 & rdEqRd & rdEqRs1;
      assign fv[25] = (|{loD == 22'hA1E93, loB == 17'h233, loC == 10'h213, loB == 17'h333,
                         loC == 10'h313, loB == 17'h3B3, loC == 10'h393})
                      & hiD == 22'h2023B & rdEqRd & rdEqRs1;
      assign fv[26] = lo[6:0] == 7'h37 & hiC == 10'h13 & rdEqRd & rdEqRs1;
      assign fv[27] = lo[6:0] == 7'h37 & hiC == 10'h1B & rdEqRd & rdEqRs1;

      // ---- 打拍(无复位; instrPairValid 有异步复位) ----
      always @(posedge clock or posedge reset) begin
        if (reset)
          instrPairValid[g] <= 1'h0;
        else if (inReady[g])
          instrPairValid[g] <= in_valid[g] & in_valid[g+1];
      end

      integer k;
      always @(posedge clock) begin
        if (fire[g]) begin
          for (k = 0; k < 28; k = k + 1) fusionVec[g][k] <= fv[k];
          notHint[g]      <= (|hi[11:7]) & (|lo[11:7]);
          enabled[g]      <= ~disableFusion;
          rs2FromRs1_r[g] <= rdEqRs1;
          rs2FromRs2_r[g] <= rdEqRs1;
          lsrc2_bits_r[g] <= rdEqRs1 ? hi[24:20] : hi[19:15];
        end
        lastFire[g] <= fire[g];
      end

      // ---- 组合输出 ----
      // 本 lane 命中(有任一 fusionVec 置位)
      wire anyFusion = |{fusionVec[g][27], fusionVec[g][26], fusionVec[g][25], fusionVec[g][24],
                         fusionVec[g][23], fusionVec[g][22], fusionVec[g][21], fusionVec[g][20],
                         fusionVec[g][19], fusionVec[g][18], fusionVec[g][17], fusionVec[g][16],
                         fusionVec[g][15], fusionVec[g][14], fusionVec[g][13], fusionVec[g][12],
                         fusionVec[g][11], fusionVec[g][10], fusionVec[g][9],  fusionVec[g][8],
                         fusionVec[g][7],  fusionVec[g][6],  fusionVec[g][5],  fusionVec[g][4],
                         fusionVec[g][3],  fusionVec[g][2],  fusionVec[g][1],  fusionVec[g][0]};

      // clear_{g+1}: lane 0 无前置抢占; lane>0 需 ~clear[g-1]
      if (g == 0)
        assign clear_w[g] = instrPairValid[g] & anyFusion & notHint[g] & enabled[g];
      else
        assign clear_w[g] = instrPairValid[g] & ~clear_w[g-1] & anyFusion & notHint[g] & enabled[g];

      assign clear[g]     = clear_w[g];
      assign out_valid[g] = clear_w[g];

      // fuType 覆写 valid = fusionVec[19]
      assign out_fuType_valid[g] = fusionVec[g][19];

      // fuOpType_valid = anyFusion
      assign out_fuOpType_valid[g] = anyFusion;

      // ---- fuOpType_bits: constReplResult LUT ----
      // 复刻 golden 逐层 or-accumulate; 顺序/常数与 firtool 一致。
      wire [6:0] cr26 = {1'h0, fusionVec[g][0], 5'h0}
                      | ((|{fusionVec[g][2], fusionVec[g][1]}) ? 7'h4B : 7'h0)
                      | (fusionVec[g][3] ? 7'h4A : 7'h0);
      wire [6:0] cr33 = {cr26[6],
                         cr26[5:0] | (fusionVec[g][4] ? 6'h29 : 6'h0)
                                   | (fusionVec[g][5] ? 6'h2B : 6'h0)
                                   | (fusionVec[g][6] ? 6'h2D : 6'h0)}
                      | (fusionVec[g][7] ? 7'h58 : 7'h0) | (fusionVec[g][8] ? 7'h59 : 7'h0)
                      | (fusionVec[g][9] ? 7'h5A : 7'h0) | (fusionVec[g][10] ? 7'h5B : 7'h0);
      wire [5:0] cg1  = cr33[5:0] | (fusionVec[g][11] ? 6'h2F : 6'h0)
                                  | (fusionVec[g][12] ? 6'h24 : 6'h0) | (fusionVec[g][13] ? 6'h25 : 6'h0)
                                  | (fusionVec[g][14] ? 6'h26 : 6'h0) | (fusionVec[g][15] ? 6'h27 : 6'h0)
                                  | (fusionVec[g][16] ? 6'h22 : 6'h0);
      wire [6:0] cr41 = {cr33[6], cg1[5], cg1[4:0] | (fusionVec[g][17] ? 5'h11 : 5'h0)}
                      | (fusionVec[g][18] ? 7'h53 : 7'h0);
      wire [5:0] cg2  = {cr41[5],
                         {cr41[4], cr41[3:0] | (fusionVec[g][19] ? 4'hC : 4'h0)}
                           | (fusionVec[g][20] ? 5'h15 : 5'h0) | (fusionVec[g][21] ? 5'h14 : 5'h0)
                           | (fusionVec[g][22] ? 5'h16 : 5'h0) | (fusionVec[g][23] ? 5'h17 : 5'h0)}
                      | (fusionVec[g][26] ? 6'h23 : 6'h0);
      assign out_fuOpType_bits[g] =
        {2'h0,
         (|{fusionVec[g][25], fusionVec[g][24]})
           ? (fusionVec[g][24] ? {3'h6, dec_fuOpType[g][3:1], 1'h0} : 7'h0)
             | (fusionVec[g][25] ? {3'h6, dec_fuOpType[g][3:1], 1'h1} : 7'h0)
           : {cr41[6], cg2[5], cg2[4:0] | (fusionVec[g][27] ? 5'h13 : 5'h0)}};

      // ---- src2 / lsrc2 ----
      assign src2WithZero[g] = {fusionVec[g][3], fusionVec[g][2], fusionVec[g][1], fusionVec[g][0]};
      assign src2WithMux[g]  = {fusionVec[g][19], fusionVec[g][18], fusionVec[g][17], fusionVec[g][16],
                                fusionVec[g][15], fusionVec[g][14], fusionVec[g][13], fusionVec[g][12],
                                fusionVec[g][11], fusionVec[g][6],  fusionVec[g][5],  fusionVec[g][4]};

      assign out_lsrc2_valid[g] = enabled[g] & ((|src2WithMux[g]) | (|src2WithZero[g]));
      assign out_lsrc2_bits[g]  = (|src2WithMux[g]) ? {1'h0, lsrc2_bits_r[g]} : 6'h0;

      assign out_src2Type_valid[g] =
        |{fusionVec[g][19], fusionVec[g][18], fusionVec[g][17], fusionVec[g][16],
          fusionVec[g][15], fusionVec[g][14], fusionVec[g][13], fusionVec[g][12],
          fusionVec[g][11], fusionVec[g][6],  fusionVec[g][5],  fusionVec[g][4],
          fusionVec[g][2],  fusionVec[g][1],  fusionVec[g][0]};

      assign out_selImm_valid[g] = |{fusionVec[g][27], fusionVec[g][26]};
      assign out_selImm_bits[g]  = (fusionVec[g][26] | fusionVec[g][27]) ? 4'hB : 4'h0;

      // ---- info(rs2 来源) ----
      assign rs2FromRs2_T[g] = enabled[g] & (|src2WithMux[g]);
      assign info_rs2FromRs1[g]  = rs2FromRs2_T[g] & ~rs2FromRs1_r[g];
      assign info_rs2FromRs2[g]  = rs2FromRs2_T[g] & rs2FromRs2_r[g];
      assign info_rs2FromZero[g] = enabled[g] & (|src2WithZero[g]);
    end
  endgenerate

endmodule
