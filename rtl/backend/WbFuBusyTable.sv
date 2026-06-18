// =============================================================================
// xs_WbFuBusyTable_core —— 写回 FU 忙表(可读核)
// -----------------------------------------------------------------------------
// 对应 Scala `WbFuBusyTableImp`(WbFuBusyTable.scala)。详见 docs/backend/WbFuBusyTable.md。
//
// 【本核做什么】纯组合的"按写回端口归并忙表 + 扇出读回"(无状态):
//   1) writeBusyTable: 每个物理寄存器写回端口(WB port)上, 把挂在它下面、延迟确定的
//      源 IssueQueue 送来的"未来占用位图"逐位 OR, 得到该端口总占用表。短源零扩展再 OR。
//   2) readRes: 把每个端口总表读回给挂在该端口上的各 IssueQueue, 按其读取位宽截/扩,
//      reader 用它在发射不定延迟指令时避让该端口的未来冲突。
//
// 【端口拓扑是 elaboration 期固定的】
//   "哪个源 OR 进哪个端口、哪个 reader 读哪个端口"在 Chisel 展开时由各 EXU 的 wbPortConfig
//   静态确定 → 一组固定接线, 无运行期判断。本核按"WB 端口"分节: 先 OR 出端口总表, 再
//   经 busy_read 扇出给 reader。命名用 域(int/fp/vf/v0/vl)+端口序号, 而非 golden 展平名。
//
// 【为什么没有 conflict 路】Scala 还有 writeConflict/deqRespSet 一路(多源同拍写回冲突),
//   当前昆明湖配置下相关端口经 latCertain 过滤后均为 None(OptionWrapper 退化), golden 不
//   含任何 *Conflict / deqRespSet 端口。本核与 golden 一致, 不实现该路(详见文档)。
// =============================================================================
module xs_WbFuBusyTable_core
  import wbfubusytable_pkg::*;
(
    // ---- 输入: 各 IssueQueue 写入各写回端口的"未来占用位图" ----
    input  logic [2:0] in_intSchd_0_0_intWb,   // intSchd blk0 exu0 → INT 端口α
    input  logic [2:0] in_intSchd_1_0_intWb,   // intSchd blk1 exu0 → INT 端口β
    input  logic [2:0] in_intSchd_2_1_fpWb,    // intSchd blk2 exu1 → FP  端口 fp0
    input  logic [2:0] in_fpSchd_0_0_intWb,    // → INT 端口α
    input  logic [3:0] in_fpSchd_0_0_fpWb,     // → FP  端口 fp1
    input  logic [1:0] in_fpSchd_1_0_intWb,    // → INT 端口β
    input  logic [3:0] in_fpSchd_1_0_fpWb,     // → FP  端口 fp2
    input  logic [1:0] in_fpSchd_2_0_intWb,    // → INT 端口γ (独占)
    input  logic [3:0] in_fpSchd_2_0_fpWb,     // → FP  端口 fp0
    input  logic [2:0] in_vfSchd_1_1_fpWb,     // → FP 端口 fp2
    input  logic [2:0] in_vfSchd_1_1_vfWb,     // → VF 端口 vf1 (独占)
    input  logic [2:0] in_vfSchd_1_1_v0Wb,     // → V0 端口 v01 (独占)
    input  logic [4:0] in_vfSchd_1_0_vfWb,     // → VF 端口 vf2 (独占)
    input  logic [4:0] in_vfSchd_1_0_v0Wb,     // → V0 端口 v02 (独占)
    input  logic [4:0] in_vfSchd_0_1_intWb,    // → INT 端口β
    input  logic [2:0] in_vfSchd_0_1_fpWb,     // → FP 端口 fp1
    input  logic [3:0] in_vfSchd_0_1_vfWb,     // → VF 端口 vf0
    input  logic [3:0] in_vfSchd_0_1_v0Wb,     // → V0 端口 v00
    input  logic [1:0] in_vfSchd_0_1_vlWb,     // → VL 端口 vl0 (独占)
    input  logic [4:0] in_vfSchd_0_0_vfWb,     // → VF 端口 vf0
    input  logic [4:0] in_vfSchd_0_0_v0Wb,     // → V0 端口 v00

    // ---- 输出: 读回给各 IssueQueue 的端口总占用表 ----
    output logic [2:0] out_intResp_2_1_fpWb,
    output logic       out_intResp_2_1_vfWb,
    output logic       out_intResp_2_1_v0Wb,
    output logic       out_intResp_2_0_intWb,
    output logic       out_intResp_1_1_intWb,
    output logic [2:0] out_intResp_1_0_intWb,
    output logic       out_intResp_0_1_intWb,
    output logic [2:0] out_intResp_0_0_intWb,
    output logic [1:0] out_fpResp_2_0_intWb,
    output logic [3:0] out_fpResp_2_0_fpWb,
    output logic [1:0] out_fpResp_1_0_intWb,
    output logic [3:0] out_fpResp_1_0_fpWb,
    output logic [2:0] out_fpResp_0_0_intWb,
    output logic [3:0] out_fpResp_0_0_fpWb,
    output logic [2:0] out_vfResp_1_1_fpWb,
    output logic [2:0] out_vfResp_1_1_vfWb,
    output logic [2:0] out_vfResp_1_1_v0Wb,
    output logic [4:0] out_vfResp_1_0_vfWb,
    output logic [4:0] out_vfResp_1_0_v0Wb,
    output logic [4:0] out_vfResp_0_1_intWb,
    output logic [2:0] out_vfResp_0_1_fpWb,
    output logic [3:0] out_vfResp_0_1_vfWb,
    output logic [3:0] out_vfResp_0_1_v0Wb,
    output logic [1:0] out_vfResp_0_1_vlWb,
    output logic [4:0] out_vfResp_0_0_vfWb,
    output logic [4:0] out_vfResp_0_0_v0Wb
);

  // 端口总表的有效位宽(写回延迟最大值+1)。用 struct 聚合"一个域的全部 WB 端口",
  // 让端口集合作为一个整体被构造/读取, 而非散落的标量。
  typedef struct packed {
    logic [PORT_W-1:0] port_a;   // INT 端口α  (有效 3b)
    logic [PORT_W-1:0] port_b;   // INT 端口β  (有效 5b)
    logic [PORT_W-1:0] port_g;   // INT 端口γ  (有效 2b)
  } int_ports_t;

  typedef struct packed {
    logic [PORT_W-1:0] port_0;   // FP 端口 fp0 (有效 4b)
    logic [PORT_W-1:0] port_1;   // FP 端口 fp1 (有效 4b)
    logic [PORT_W-1:0] port_2;   // FP 端口 fp2 (有效 4b)
  } fp_ports_t;

  // VF 与 V0 两域端口拓扑完全同构(同样三个端口、同样的源 IssueQueue), 用同一 struct,
  // 并在下方用 genvar 对 {VF,V0} 两域统一构造端口 0(两源 OR)。
  typedef struct packed {
    logic [PORT_W-1:0] port_0;   // 端口 0 (有效 5b, 两源 OR)
    logic [PORT_W-1:0] port_1;   // 端口 1 (有效 3b, 独占)
    logic [PORT_W-1:0] port_2;   // 端口 2 (有效 5b, 独占)
  } vec_ports_t;

  int_ports_t int_p;
  fp_ports_t  fp_p;
  vec_ports_t vf_p, v0_p;
  logic [PORT_W-1:0] vl_port_0;  // VL 端口 vl0 (有效 2b, 独占)

  // ===========================================================================
  // 1) writeBusyTable —— 按写回端口 OR 归并各源忙表(短源零扩展到 PORT_W 再 OR)
  // ===========================================================================
  // INT α: intSchd_0_0 | fpSchd_0_0
  assign int_p.port_a = {{(PORT_W-3){1'b0}}, in_intSchd_0_0_intWb}
                      | {{(PORT_W-3){1'b0}}, in_fpSchd_0_0_intWb};
  // INT β: intSchd_1_0 | fpSchd_1_0 | vfSchd_0_1  (三源)
  assign int_p.port_b = {{(PORT_W-3){1'b0}}, in_intSchd_1_0_intWb}
                      | {{(PORT_W-2){1'b0}}, in_fpSchd_1_0_intWb}
                      | {{(PORT_W-5){1'b0}}, in_vfSchd_0_1_intWb};
  // INT γ: fpSchd_2_0 独占
  assign int_p.port_g = {{(PORT_W-2){1'b0}}, in_fpSchd_2_0_intWb};

  // FP fp0: intSchd_2_1 | fpSchd_2_0
  assign fp_p.port_0 = {{(PORT_W-3){1'b0}}, in_intSchd_2_1_fpWb}
                     | {{(PORT_W-4){1'b0}}, in_fpSchd_2_0_fpWb};
  // FP fp1: fpSchd_0_0[低3] | vfSchd_0_1, 第[3]位仅 fpSchd_0_0 贡献(vf 源仅 3 位)
  assign fp_p.port_1 = {{(PORT_W-4){1'b0}}, in_fpSchd_0_0_fpWb[3],
                        (in_fpSchd_0_0_fpWb[2:0] | in_vfSchd_0_1_fpWb)};
  // FP fp2: fpSchd_1_0[低3] | vfSchd_1_1, 第[3]位仅 fpSchd_1_0
  assign fp_p.port_2 = {{(PORT_W-4){1'b0}}, in_fpSchd_1_0_fpWb[3],
                        (in_fpSchd_1_0_fpWb[2:0] | in_vfSchd_1_1_fpWb)};

  // VF/V0 同构: 端口0 两源 OR(vfSchd_0_0[低4] | vfSchd_0_1, 第[4]位仅 vfSchd_0_0);
  //             端口1 = vfSchd_1_1 独占; 端口2 = vfSchd_1_0 独占。
  // 用 genvar 对两域统一表达"端口 0 = 5 源中 [4]位单源 + [低4]两源 OR"的同构结构。
  // (两域源信号不同, 故端口 0 用 for-generate 选择对应源; 1/2 直接接独占源。)
  logic [4:0] vec_p0_lo_src [2];   // [0]=vf, [1]=v0  各自的"低 4 + 高 1"两源
  logic [4:0] vec_p0_hi_src [2];
  assign vec_p0_lo_src[0] = in_vfSchd_0_1_vfWb;          assign vec_p0_hi_src[0] = in_vfSchd_0_0_vfWb;
  assign vec_p0_lo_src[1] = in_vfSchd_0_1_v0Wb;          assign vec_p0_hi_src[1] = in_vfSchd_0_0_v0Wb;

  logic [PORT_W-1:0] vec_port_0 [2];
  genvar d;
  generate
    for (d = 0; d < 2; d++) begin : g_vec_port0
      // 端口0[4] 仅 hi_src 贡献; [3:0] = hi_src[3:0] | lo_src[3:0]
      assign vec_port_0[d] = {{(PORT_W-5){1'b0}}, vec_p0_hi_src[d][4],
                              (vec_p0_hi_src[d][3:0] | vec_p0_lo_src[d][3:0])};
    end
  endgenerate

  assign vf_p.port_0 = vec_port_0[0];
  assign vf_p.port_1 = {{(PORT_W-3){1'b0}}, in_vfSchd_1_1_vfWb};
  assign vf_p.port_2 = {{(PORT_W-5){1'b0}}, in_vfSchd_1_0_vfWb};
  assign v0_p.port_0 = vec_port_0[1];
  assign v0_p.port_1 = {{(PORT_W-3){1'b0}}, in_vfSchd_1_1_v0Wb};
  assign v0_p.port_2 = {{(PORT_W-5){1'b0}}, in_vfSchd_1_0_v0Wb};

  assign vl_port_0 = {{(PORT_W-2){1'b0}}, in_vfSchd_0_1_vlWb};

  // ===========================================================================
  // 2) readRes —— 把端口总表读回给该端口上的各 reader(busy_read 按位宽截/扩)
  // ===========================================================================
  // 读 INT 端口
  assign out_intResp_0_0_intWb = busy_read(int_p.port_a, 3);
  assign out_intResp_0_1_intWb = busy_read(int_p.port_a, 1);
  assign out_fpResp_0_0_intWb  = busy_read(int_p.port_a, 3);
  assign out_intResp_1_0_intWb = busy_read(int_p.port_b, 3);
  assign out_intResp_1_1_intWb = busy_read(int_p.port_b, 1);
  assign out_fpResp_1_0_intWb  = busy_read(int_p.port_b, 2);
  assign out_vfResp_0_1_intWb  = busy_read(int_p.port_b, 5);
  assign out_intResp_2_0_intWb = busy_read(int_p.port_g, 1);
  assign out_fpResp_2_0_intWb  = busy_read(int_p.port_g, 2);

  // 读 FP 端口
  assign out_intResp_2_1_fpWb = busy_read(fp_p.port_0, 3);
  assign out_fpResp_2_0_fpWb  = busy_read(fp_p.port_0, 4);
  assign out_fpResp_0_0_fpWb  = busy_read(fp_p.port_1, 4);
  assign out_vfResp_0_1_fpWb  = busy_read(fp_p.port_1, 3);
  assign out_fpResp_1_0_fpWb  = busy_read(fp_p.port_2, 4);
  assign out_vfResp_1_1_fpWb  = busy_read(fp_p.port_2, 3);

  // 读 VF 端口
  assign out_vfResp_0_0_vfWb = busy_read(vf_p.port_0, 5);
  assign out_vfResp_0_1_vfWb = busy_read(vf_p.port_0, 4);
  assign out_vfResp_1_1_vfWb = busy_read(vf_p.port_1, 3);
  assign out_vfResp_1_0_vfWb = busy_read(vf_p.port_2, 5);

  // 读 V0 端口
  assign out_vfResp_0_0_v0Wb  = busy_read(v0_p.port_0, 5);
  assign out_vfResp_0_1_v0Wb  = busy_read(v0_p.port_0, 4);
  assign out_intResp_2_1_v0Wb = busy_read(v0_p.port_1, 1);
  assign out_vfResp_1_1_v0Wb  = busy_read(v0_p.port_1, 3);
  assign out_vfResp_1_0_v0Wb  = busy_read(v0_p.port_2, 5);

  // intResp_2_1 跨域读 VF 端口 vf1 的占用低位
  assign out_intResp_2_1_vfWb = busy_read(vf_p.port_1, 1);

  // 读 VL 端口
  assign out_vfResp_0_1_vlWb = busy_read(vl_port_0, 2);

endmodule
