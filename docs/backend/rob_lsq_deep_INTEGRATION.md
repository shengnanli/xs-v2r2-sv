# Rob C_DEEP 出口交付 — lsq(5) + gpaddr/isForVS(2) + toDecode(1) + error(1)

owner: rob-lsq-deep (codex 0090 P2) · base: agent/rob @ 15d5d7d · golden: G0-canonical/golden-rtl/Rob.sv

## 交付物 (独立 patch, 不 merge Rob 主文件)
1. `rtl/backend/Rob.sv` (xs_Rob_core) 新增 4 组**组合全存储读 / 状态导出**输出口
   (只有拥有 rob_entries 的核能取; golden 用组合读非寄存 deqGroup, 见下 §忠实性):
     - `output logic [COMMIT_WIDTH-1:0] o_deq_entry_vls`   = rob_entries[deq_ptr_vec[N].value].vls
     - `output logic o_deq_entry_valid_0`                  = rob_entries[deq_ptr_vec[0].value].valid
     - `output logic o_deq_entry_mmio_0`                   = rob_entries[deq_ptr_vec[0].value].mmio
     - `output logic o_deqHasFlushed`                      = deqHasFlushed
2. `rtl/backend/rob_lsq_deep_outputs.sv` — 9 口忠实实现小模块 (可独立测/审)。
3. `docs/backend/rob_lsq_deep_ports.tsv` — 9 口逐口 {ref_port, 状态方程, 有效条件, 扇出, impl_source}。
4. `verif/ut/Rob/tb_lsq_deep.sv` — 局部 UT: golden Rob 全激励, DUT=本子模块由 golden 内部 tap 驱动,
   9 口 vs golden 同名端口逐拍比对 (独立 errors_deep 计数, 与他人 xs_Rob_core scaffold 隔离)。

## 集成方式 (Rob-integrator 在完整 wrapper body 里做)
在 Rob_wrapper.sv 例化 u_core / exceptionGen / vtypeBuffer / deqPtrGenModule 之后, 加:

```systemverilog
  // rawInfo_N = o_commit_info[N] (= golden robDeqGroup 寄存读)
  logic [2:0] rawInfo_commitType [COMMIT_WIDTH];
  always_comb for (int i=0;i<COMMIT_WIDTH;i++) rawInfo_commitType[i] = u_core.o_commit_info[i].commit_type;

  rob_lsq_deep_outputs #(.COMMIT_WIDTH(COMMIT_WIDTH), .PTR_W(PTR_W)) u_lsq_deep (
    .clock(clock), .reset(reset),
    .io_commits_isCommit_0   (u_core.o_commits_isCommit),
    .io_commits_commitValid_0(u_core.o_commits_commitValid),
    .rawInfo_commitType      (rawInfo_commitType),
    .rawInfo_0_commit_v      (u_core.o_commit_info[0].commit_v),
    .rawInfo_0_commit_w      (u_core.o_commit_info[0].commit_w),
    .rawInfo_0_mmio          (u_core.o_commit_info[0].mmio),
    .deq_entry_vls           (u_core.o_deq_entry_vls),
    .deq_entry_valid_0       (u_core.o_deq_entry_valid_0),
    .deq_entry_mmio_0        (u_core.o_deq_entry_mmio_0),
    .deqPtr0_flag            (deqPtrGenModule.io_out_0_flag),   // = u_core.deq_ptr_vec[0].flag
    .deqPtr0_value           (deqPtrGenModule.io_out_0_value),  // = u_core.deq_ptr_vec[0].value
    .deqHasFlushed           (u_core.o_deqHasFlushed),
    .exceptionGen_state_isVset(exceptionGen.io_state_bits_isVset),
    .vtypeBuffer_isResumeVType(vtypeBuffer.io_toDecode_isResumeVType),
    .io_readGPAMemData_gpaddr(io_readGPAMemData_gpaddr),
    .io_readGPAMemData_isForVSnonLeafPTE(io_readGPAMemData_isForVSnonLeafPTE),
    // → 直接驱动 9 个顶层输出口:
    .io_lsq_scommit(io_lsq_scommit), .io_lsq_pendingMMIOld(io_lsq_pendingMMIOld),
    .io_lsq_pendingst(io_lsq_pendingst), .io_lsq_pendingPtr_flag(io_lsq_pendingPtr_flag),
    .io_lsq_pendingPtr_value(io_lsq_pendingPtr_value),
    .io_exception_bits_gpaddr(io_exception_bits_gpaddr),
    .io_exception_bits_isForVSnonLeafPTE(io_exception_bits_isForVSnonLeafPTE),
    .io_toDecode_isResumeVType(io_toDecode_isResumeVType),
    .io_error_0(io_error_0)
  );
```

WRAPPER_SRCS / TAP_SRCS 需追加 `$(RTL_DIR)/backend/rob_lsq_deep_outputs.sv`。

## 忠实性 (bug-for-bug, 关键判定)
- **scommit / commitStuck 用组合全存储读, 非寄存 deqGroup**: golden
  `_GEN_8225[deqPtr_N_value]`(vls, 8 位全存储下标) / `_GEN_2611`/`_GEN_2622`(valid/mmio) 是对
  `robEntries[*]` 的**组合**读, 与寄存的 `robDeqGroup`(=rawInfo_N_isVls) 在行切换/写回拍可能不同,
  故必须用组合读 ⇒ 由核导出 o_deq_entry_*。而 pendingMMIOld 的 mmio 用 `_GEN_8546[deqPtr_0[2:0]]`
  (3 位下标) = 寄存 deqGroup 读 ⇒ 用 o_commit_info[0].mmio。二者刻意区分, 逐字对齐 golden。
- **寄存器复位语义分两族**: commitStuckCycle = 异步复位到 0
  (golden `always @(posedge clock or posedge reset)`); lsq 5 REG / isVsetFlushPipeReg /
  REG_8 / io_error_0_REG / io_error_0_REG_1 = **无复位自由跑块** (golden 靠 ENABLE_INITIAL_REG
  随机初值, 首次提交后收敛)。本模块照搬。
- gpaddr = {8'h0, io_readGPAMemData_gpaddr}(56→64 零扩展); isForVS 纯直通。
- 无 dont_verify / 无删端口 / 无 fake allowlist。

## 局部验证
- 编译: vcs elaborate OK (core+新口 / 子模块 / tb 全 0 error)。
- UT tb_lsq_deep seed 1/7/42 @200k: DEEP errors=0 (9 口全 match golden)。
  (同 log 里 u_i=xs_Rob_core scaffold 的 errors 属 A_CORE tier 他人范畴, 与本目标无关。)

## 边界 (honest)
- io_error_0 = &commitStuckCycle(21 位) 需连续 2^21 卡死拍才 fire, 200k 拍内 golden 与 DUT
  恒 0(值 match, 但 saturation 上升沿路径未被激励压满); 中间 commitStuckCycle/REG_8/io_error_0_REG
  的 +1/清零链已被激励覆盖。逻辑逐字复刻 golden, FM 会覆盖此锥。
- 集成后完整端口面 assembly FM 仍需其余 91 个 C_DEEP 口(perf/trace/csr/toVecExcpMod/debug)与
  A_CORE/B_SHALLOW 补齐, 非本 owner 范畴。
