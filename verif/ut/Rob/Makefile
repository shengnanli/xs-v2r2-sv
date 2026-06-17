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
