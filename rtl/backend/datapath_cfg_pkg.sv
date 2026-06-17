// 自动生成:scripts/gen_datapath.py —— 勿手改(逻辑为从设计意图的可读重写)

// DataPath 实例拓扑配置(昆明湖单态化值)。BackendParams 弹性化定死的实例常量,
// 非组合逻辑;可读核用 genvar 在其上重新实现五条数据流。
package datapath_cfg_pkg;
  localparam int NUM_EXU = 27;   // 全局 EXU 总数(Int8 + Fp5 + Vec5 + Mem9)
  localparam int MAX_SRC = 5;    // 单 EXU 最多源操作数(vd/vs1/vs2/v0/vl)
  localparam int unsigned NUM_REG_SRC [NUM_EXU] = '{2, 2, 2, 2, 2, 2, 2, 2, 3, 2, 3, 2, 3, 5, 5, 5, 5, 5, 1, 1, 1, 1, 1, 5, 5, 1, 1};
  localparam int INT_RD=8, INT_WR=8;
  localparam int FP_RD=4,  FP_WR=6;
  localparam int VF_RD=12, VF_WR=6;
  localparam int V0_RD=4,  V0_WR=6;
  localparam int VL_RD=0,  VL_WR=4;
  localparam int VF_SPLIT=4, V0_SPLIT=2;  // 向量域写使能按 VLEN/XLEN 竖切复制
endpackage : datapath_cfg_pkg
