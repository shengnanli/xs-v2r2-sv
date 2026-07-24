// 自动生成:scripts/gen_exeunit.py（ExeUnit_8）—— 勿手改(逻辑为从设计意图的可读重写)

// ExeUnit_8 执行单元包装:FU 周围 glue 的配置常量与可读类型。
// 单态化(昆明湖)后 FU 个数 / 各 FU 延迟 / 控制位集合均为定值,可读核据此用
// struct + function + genvar 表达流水对齐、时钟门控使能、输出 one-hot 仲裁。
package exeunit_8_pkg;
  localparam int NUM_FU      = 4;   // 本执行单元里的功能单元个数
  localparam int LAT_MAX     = 3;   // 各 FU 中最大固定延迟(inPipe 深度)

  // ------------------------------------------------------------------------
  // §1 inPipe 控制位:随 uop 一同打拍、在 FU 出结果那拍交给该 FU 的控制信息。
  //   字段集合来自单态化后实际被下游 FU 消费的控制位(robIdx/pdest/写使能等)。
  // ------------------------------------------------------------------------
  // 注意:fuOpType / rfWen 只在浅级被下游 FU 消费(fuOpType 到 Fcvt=第1级、
  //   rfWen 到 Falu=第0级与 Fcvt=第1级),到最深级(Fmac=第2级)已无消费者,
  //   故不进本通用结构(否则最深级会多存这两字段=死位,偏离 golden)。它们由
  //   logic.svh 里各自 2 级专用链承载(镜像 golden inPipe_1_1/1_2 存、1_3 不存)。
  typedef struct packed {
    logic       robIdx_flag;
    logic [7:0] robIdx_value;
    logic [7:0] pdest;
    logic       fpWen;
    logic       fpu_wflags;
  } ctrl_t;

  // ------------------------------------------------------------------------
  // flush-kill:一条在飞 uop 是否被本次重定向(redirect)冲刷掉。
  //   Chisel: robIdx.needFlush(flush) = flush.valid &&
  //     (flush.level==flushItself && robIdx==flush.robIdx) || robIdx 比 flush 更年轻。
  //   {flag,value} 大小比较即 robIdx 的环形新旧:flag 不同则 value 大者为旧/新由异或定。
  // ------------------------------------------------------------------------
  function automatic logic need_flush(
      logic flush_valid, logic flush_level,
      logic flush_flag, logic [7:0] flush_value,
      logic rob_flag,   logic [7:0] rob_value);
    need_flush = flush_valid &
      ( (flush_level & ({rob_flag, rob_value} == {flush_flag, flush_value}))
        | (rob_flag ^ flush_flag ^ (rob_value > flush_value)) );
  endfunction

  // ------------------------------------------------------------------------
  // §3 输出 one-hot 仲裁:各 FU 至多一个 valid,对每个输出字段做
  //   "选中则取该 FU 值、否则取 0" 的或归约(等价 Mux1H,综合为与-或选择)。
  //   下面给标量 1bit 与各数据位宽各一个纯函数,connect/logic 里逐字段调用。
  // ------------------------------------------------------------------------
  // 标量 1bit:sel & bit 的或归约由调用方按 FU 展开(见 logic.svh)。
endpackage : exeunit_8_pkg
