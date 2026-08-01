MODULE = Rob

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 + 类型包。子模块(EnqPtr/DeqPtr/ExceptionGen/Snapshot/Rab/VTypeBuffer/
# DelayReg/DummyDPIC)均在 golden 顶层内例化, 作 golden 黑盒, 不进本 UT。
# 本 UT 为可读核 xs_Rob_core 的「不变量自检 smoke UT」(tb 用环形模型生成指针/异常态)。
RTL_SRCS = $(RTL_DIR)/backend/rob_pkg.sv \
           $(RTL_DIR)/backend/Rob.sv

TB_SRCS = tb.sv

GOLDEN_SRCS =

# ---------------------------------------------------------------------
# FM assembly 目标配置 (Rob) —— 见 docs/backend/Rob.md §FM
#   proof_mode = assembly (可读核只覆盖控制锥, 无法在 golden 端口面 port-for-port
#     驱动被省略的数据通路口 ⇒ strict 会产生大量 unmatched; 故走 assembly)。
# 装配壳 = rtl/backend/Rob_wrapper.sv (module Rob, golden 同名 pin)。
#
# ★ 7-child 黑盒契约(codex 0099 组合正解): 7 个已独立 SIGNOFF_PASS 的子模块
#   (RenameBuffer / SnapshotGenerator_3 / ExceptionGen / NewRobDeqPtrWrapper /
#    RobEnqPtrWrapper / DelayReg / SyncDataModuleTemplate__64entry_3)从两侧 srcs
#   移除 ⇒ hdlin_unresolved_modules=black_box 令其成对称 unresolved_blackbox 边界;
#   depends_on 已证 PASS(见 assembly_depends.tsv Rob→7 child)。
#   VTypeBuffer 保持白盒两侧 elaborate(其内 SyncDataModule 嵌套黑盒;
#   其内 SnapshotGenerator_1/_2 保持白盒故仍需提供)。
#   DummyDPICWrapper/_8 保持白盒, 其内 DiffExtInstrCommit/DiffExtTrapEvent 9 DPI
#   sink 仍为 unresolved_blackbox(无 synthesizable body)。
#   allow/Rob.json 精确声明全部 unresolved_blackbox 对(7 child 实例 + 9 DPI)。
FM_VARIANTS = Rob
WRAPPER_SRCS = $(RTL_DIR)/backend/Rob_wrapper.sv \
               $(RTL_DIR)/backend/Rob.sv $(RTL_DIR)/backend/rob_pkg.sv \
               $(RTL_DIR)/backend/rob_lsq_deep_outputs.sv \
               $(GOLDEN_RTL)/VTypeBuffer.sv \
               $(GOLDEN_RTL)/DummyDPICWrapper.sv \
               $(GOLDEN_RTL)/DummyDPICWrapper_8.sv $(GOLDEN_RTL)/dt_160x1.sv \
               $(GOLDEN_RTL)/SnapshotGenerator_1.sv \
               $(GOLDEN_RTL)/SnapshotGenerator_2.sv \
               $(GOLDEN_RTL)/DataModule__16entry_12.sv \
               $(RTL_DIR)/backend/Rob_difftest_stubs.sv
# ref 侧 golden 叶子依赖(与 impl WRAPPER_SRCS 对称提供, 两侧同 elaborate 受验白盒;
# 7 child 不在此列 = 两侧同黑盒):
FM_REF_DEPS_Rob = VTypeBuffer.sv \
                  DummyDPICWrapper.sv DummyDPICWrapper_8.sv dt_160x1.sv \
                  SnapshotGenerator_1.sv SnapshotGenerator_2.sv \
                  DataModule__16entry_12.sv
FM_MODE = assembly
FM_ALLOWLIST = ../../signoff/allow/Rob.json

include ../../../scripts/ut_common.mk

# 关断 golden XSError 风格断言(本 UT 无 golden, 保留以备后续接 cycle-exact)
VCS += +define+SYNTHESIS

# ---------------------------------------------------------------------
# golden 双例化的依赖闭包(已验证: VCS 可编译/elaborate golden Rob, ~14s)。
# difftest 叶子 sink(DiffExtInstrCommit/DiffExtTrapEvent)用本仓桩。
# 用法(接 cycle-exact hierarchical-tap UT 时): 把 GOLDEN_CLOSURE + DIFFTEST_STUB
# 与 tb_golden.sv 一起喂 VCS, -top tb_golden(详见 docs/backend/Rob.md §12)。
DIFFTEST_STUB = $(RTL_DIR)/backend/Rob_difftest_stubs.sv
GOLDEN_CLOSURE = \
  $(GOLDEN_RTL)/dt_160x1.sv $(GOLDEN_RTL)/DataModule__16entry_12.sv \
  $(GOLDEN_RTL)/DelayReg.sv $(GOLDEN_RTL)/DummyDPICWrapper.sv \
  $(GOLDEN_RTL)/DummyDPICWrapper_8.sv $(GOLDEN_RTL)/ExceptionGen.sv \
  $(GOLDEN_RTL)/NewRobDeqPtrWrapper.sv $(GOLDEN_RTL)/RenameBuffer.sv \
  $(GOLDEN_RTL)/RobEnqPtrWrapper.sv $(GOLDEN_RTL)/SnapshotGenerator.sv \
  $(GOLDEN_RTL)/SnapshotGenerator_1.sv $(GOLDEN_RTL)/SnapshotGenerator_2.sv \
  $(GOLDEN_RTL)/SnapshotGenerator_3.sv \
  $(GOLDEN_RTL)/SyncDataModuleTemplate__64entry_3.sv $(GOLDEN_RTL)/VTypeBuffer.sv \
  $(GOLDEN_RTL)/Rob.sv

# 验证 golden 顶层可编译(冒烟): 仅 elaborate, 不跑仿真。
.PHONY: golden-compile
golden-compile:
	$(VCS) $(DIFFTEST_STUB) $(GOLDEN_CLOSURE) -top Rob -o simv_golden -l golden_compile.log
	@echo "=== golden Rob elaborate OK ==="

# ---------------------------------------------------------------------
# hierarchical-tap 子集双例化 UT(tb_tap.sv): u_g=golden Rob 喂全激励,
# u_i=xs_Rob_core 从 u_g 层次探针取黑盒输出, 逐拍比对控制输出子集 + 状态探针。
TAP_SRCS = $(RTL_DIR)/backend/rob_pkg.sv $(RTL_DIR)/backend/Rob.sv \
           $(DIFFTEST_STUB) $(GOLDEN_CLOSURE)
.PHONY: tap-compile tap-run
tap-compile:
	$(VCS) $(TAP_SRCS) tb_tap.sv -top tb -o simv_tap +define+SYNTHESIS -l tap_compile.log
	@echo "=== tap UT elaborate OK ==="
tap-run: tap-compile
	./simv_tap +ntb_random_seed=$(SEED) -l tap_sim_$(SEED).log
	@grep -E "checks=|TEST" tap_sim_$(SEED).log

# ---------------------------------------------------------------------
# ROB_SIZE=160 边界定向 UT(tb_arr160.sv): 直接驱动 deq_ptr_vec[0] 到
# 158/159(合法, 读出正确 entry)与 160/255(越界, index_in_range guard → X,
# 不 clamp/wrap/取 entry-0)。验证 rob_entries[160] + guard。生成器:
# scripts/gen_rob_arr160_tb.py(需 /tmp/rob-arr160-evidence/ports.json+tb_body.svh)。
ARR160_SRCS = $(RTL_DIR)/backend/rob_pkg.sv $(RTL_DIR)/backend/Rob.sv
.PHONY: arr160-compile arr160-run
arr160-compile:
	$(VCS) $(ARR160_SRCS) tb_arr160.sv -top tb -o simv_arr160 -l arr160_compile.log
	@echo "=== arr160 boundary UT elaborate OK ==="
arr160-run: arr160-compile
	./simv_arr160 +ntb_random_seed=$(SEED) +vcs+initreg+0 -l arr160_sim_$(SEED).log
	@grep -E "boundary UT|MISMATCH|NOT-X|GAP|TEST" arr160_sim_$(SEED).log
