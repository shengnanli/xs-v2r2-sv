// 自动生成:scripts/gen_exublock.py（ExuBlock_1）—— 勿手改(逻辑为从设计意图的可读重写)

// ExuBlock_1 容器配置 + critical-error 流水类型。
// 这些是 SchdBlockParams 单态化(昆明湖)后定死的实例常量与流水级数,
// 可读核据此用 genvar/struct 重新表达 frm 打拍与 error 聚合(非组合算法)。
package exublock_1_pkg;
  // §1 需要 frm(动态舍入模式)打拍的 vf-exu 个数;每个各打一拍喂给对应 exu。
  localparam int NUM_FRM_PIPE = 5;

  // frm 是 3 bit 浮点动态舍入模式。用 struct 显式表达「一拍延迟级」这一寄存语义,
  // 配合 frm_step() 纯函数描述 RegNext(每拍采样输入),而非散落的 *_REG 标量。
  typedef struct packed {
    logic [2:0] rm;   // 已寄存一拍的舍入模式
  } frm_pipe_t;

  // 推进一拍:采样当前 io_frm(等价 RegNext(io.frm))。
  function automatic frm_pipe_t frm_step(logic [2:0] nin);
    frm_step.rm = nin;
  endfunction
endpackage : exublock_1_pkg
