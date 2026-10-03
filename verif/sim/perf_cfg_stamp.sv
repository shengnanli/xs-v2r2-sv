// perf_cfg_stamp —— perf 比对的「仿真初值设定」自报印章（codex 0207 P1，Z0 口径）
//
// 这不是 RTL，只是整芯片 perf 仿真时与 tb_top 并列的第二个 top（-top perf_cfg_stamp），
// 不连任何信号。它在 t=1 往 stderr（= assert.log，与 [PERF ] 行同一个文件、
// 同一个 sha256）打印一行 [PERFCFG]，内容全部由仿真器**现场测得**，不靠人填：
//
//   randomize_defines  编译期实际定义了哪些 RANDOMIZE_* 宏（`ifdef 现查）；none = 都没定义
//   initreg_plusarg    运行期 +vcs+initreg+<v> 的 <v>（VCS 未给时报 random）
//   initreg_probe_reg  一个 64 位无初值 reg 在 t=1 的值：
//                        0…0 ⇔ 编译期有 +vcs+initreg+random 且运行期 +vcs+initreg+0
//                        x…x ⇔ 编译期没开 initreg；f…f ⇔ +vcs+initreg+1；其它 ⇔ random
//   initreg_probe_mem  一个无初值存储阵列表项的值（initreg 同样要覆盖 unpacked 阵列）
//   workload / seed / max_cycles  运行期 plusarg 原样回显（seed 未给时报 default）
//
// 判据（两侧都要满足 + 两侧逐字段一致）在 scripts/perf_compare.py 的 init_contract()。
// 为什么要这条：firtool 的 RANDOMIZE_*_INIT 用无种子 `$random`，它是全设计共用的一条
// 随机流，换掉任何一个带 $random initial 块的 golden 模块，后面所有 golden 寄存器的
// 初值都会平移（与 +ntb_random_seed 无关）。见 docs/lanes/tage-initmem.md。
module perf_cfg_stamp;
  reg  [63:0] initreg_probe_reg;
  reg  [31:0] initreg_probe_mem [0:3];
  string      defs, ireg, wl, seed_s;
  integer     seed, maxc;

  initial begin
    #1;
    defs = "";
`ifdef RANDOMIZE_REG_INIT
    defs = {defs, "REG_INIT,"};
`endif
`ifdef RANDOMIZE_MEM_INIT
    defs = {defs, "MEM_INIT,"};
`endif
`ifdef RANDOMIZE_GARBAGE_ASSIGN
    defs = {defs, "GARBAGE_ASSIGN,"};
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
    defs = {defs, "INVALID_ASSIGN,"};
`endif
`ifdef RANDOMIZE_DELAY
    defs = {defs, "DELAY,"};
`endif
`ifdef RANDOMIZE
    defs = {defs, "RANDOMIZE,"};
`endif
    if (defs == "") defs = "none";
    if (!$value$plusargs("vcs+initreg+%s", ireg)) ireg = "absent";
    if (!$value$plusargs("workload=%s", wl)) wl = "absent";
    if ($value$plusargs("ntb_random_seed=%d", seed)) seed_s = $sformatf("%0d", seed);
    else seed_s = "default";
    if (!$value$plusargs("max-cycles=%d", maxc)) maxc = -1;
    $fwrite(32'h80000002,
            "[PERFCFG] randomize_defines=%s initreg_plusarg=%s initreg_probe_reg=%h initreg_probe_mem=%h workload=%s seed=%s max_cycles=%0d\n",
            defs, ireg, initreg_probe_reg, initreg_probe_mem[2], wl, seed_s, maxc);
  end
endmodule
