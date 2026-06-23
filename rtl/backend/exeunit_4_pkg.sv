// 自动生成:scripts/gen_exeunit.py（ExeUnit_4）—— 勿手改(逻辑为从设计意图的可读重写)

// ExeUnit_4 执行单元包装:FU 周围 glue 的配置常量与可读类型。
// 单态化(昆明湖)后 FU 个数 / 各 FU 延迟 / 控制位集合均为定值,可读核据此用
// struct + function + genvar 表达流水对齐、时钟门控使能、输出 one-hot 仲裁。
package exeunit_4_pkg;
  localparam int NUM_FU      = 1;   // 本执行单元里的功能单元个数
  localparam int LAT_MAX     = 0;   // 各 FU 中最大固定延迟(inPipe 深度)

  // ------------------------------------------------------------------------
  // §3 输出 one-hot 仲裁:各 FU 至多一个 valid,对每个输出字段做
  //   "选中则取该 FU 值、否则取 0" 的或归约(等价 Mux1H,综合为与-或选择)。
  //   下面给标量 1bit 与各数据位宽各一个纯函数,connect/logic 里逐字段调用。
  // ------------------------------------------------------------------------
  // 标量 1bit:sel & bit 的或归约由调用方按 FU 展开(见 logic.svh)。
endpackage : exeunit_4_pkg
