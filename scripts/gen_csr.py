#!/usr/bin/env python3
# =============================================================================
# gen_csr.py —— 派生 CSR assembly parent 的可读核 xs_CSR_core + 端口壳 wrapper。
# -----------------------------------------------------------------------------
# CSR = assembly parent。顶层胶合逻辑 (暂存/流水寄存器 + 异常向量组合 + redirect/
#   error 打拍 + 输出直通) 由本脚本 **可读重写** (清晰命名/分段注释, 无 golden
#   _GEN_/_T_ 临时名), 例化 4 子:
#     NewCSR csrMod   —— 绿 305 (SIGNOFF_PASS); assembly 黑盒 (两侧未解析)
#     IMSIC  imsic    —— 绿 305 (SIGNOFF_PASS); assembly 黑盒 (两侧未解析)
#     TrapInstMod     —— 叶子逻辑, 两侧 elaborate 白盒受验
#     TrapTvalMod     —— 叶子逻辑, 两侧 elaborate 白盒受验
#   子模块的 546+ 行端口连线是 **同构接线** (接口契约, 非容器逻辑), 忠实保留;
#   输出 assign (78 个常量 0 / 其余直通) 同属接线, 忠实保留。
# 真正的容器时序/组合逻辑 (33 寄存器 + isEcall/isEbreak/exceptionVec/wdata mux)
#   在 CSR_LOGIC 中可读重写。
# =============================================================================
import re

GOLDEN     = '/home/eda/xs-env/G0-canonical/golden-rtl/CSR.sv'
CORE_OUT   = '/tmp/xs-signoff-csr-i2f/rtl/backend/CSR.sv'
WRAP_OUT   = '/tmp/xs-signoff-csr-i2f/rtl/backend/CSR_wrapper.sv'
XS_OUT     = '/tmp/xs-signoff-csr-i2f/verif/ut/CSR/variants_xs.sv'

# ---- 可读重写的容器逻辑 (取代 golden 展平体的 decls+always 段) ----------------
# 语义严格对齐 golden: 见每段注释。子例化引用的内部信号名与 golden 保持一致
# (_csrMod_* / _imsic_* / _trapInstMod_* / _trapTvalMod_*), 因接线块忠实保留。
CSR_LOGIC = r"""
  // ===========================================================================
  //  内部信号 (子模块输出线) —— 命名与接线块一致。
  // ===========================================================================
  wire        _imsic_toCSR_rdata_valid;
  wire [63:0] _imsic_toCSR_rdata_bits;
  wire        _imsic_toCSR_illegal;
  wire [6:0]  _imsic_toCSR_pendings;
  wire [31:0] _imsic_toCSR_topeis_0;
  wire [31:0] _imsic_toCSR_topeis_1;
  wire [31:0] _imsic_toCSR_topeis_2;
  wire [63:0] _trapTvalMod_io_tval;
  wire        _trapInstMod_io_currentTrapInst_valid;
  wire [31:0] _trapInstMod_io_currentTrapInst_bits;
  wire        _csrMod_io_in_ready;
  wire        _csrMod_io_out_valid;
  wire        _csrMod_io_out_bits_EX_II;
  wire        _csrMod_io_out_bits_EX_VI;
  wire        _csrMod_io_out_bits_targetPcUpdate;
  wire [63:0] _csrMod_io_out_bits_targetPc_pc;
  wire        _csrMod_io_out_bits_targetPc_raiseIPF;
  wire        _csrMod_io_out_bits_targetPc_raiseIAF;
  wire        _csrMod_io_out_bits_targetPc_raiseIGPF;
  wire [63:0] _csrMod_io_out_bits_regOut;
  wire        _csrMod_io_out_bits_isPerfCnt;
  wire [1:0]  _csrMod_io_status_privState_PRVM;
  wire        _csrMod_io_status_privState_V;
  wire [6:0]  _csrMod_io_status_vecState_vstart;
  wire [13:0] _csrMod_io_tlb_hgatp_VMID;
  wire        _csrMod_io_toDecode_illegalInst_fsIsOff;
  wire        _csrMod_toAIA_addr_valid;
  wire [11:0] _csrMod_toAIA_addr_bits_addr;
  wire        _csrMod_toAIA_addr_bits_v;
  wire [1:0]  _csrMod_toAIA_addr_bits_prvm;
  wire [5:0]  _csrMod_toAIA_vgein;
  wire        _csrMod_toAIA_wdata_valid;
  wire [1:0]  _csrMod_toAIA_wdata_bits_op;
  wire [63:0] _csrMod_toAIA_wdata_bits_data;
  wire        _csrMod_toAIA_mClaim;
  wire        _csrMod_toAIA_sClaim;
  wire        _csrMod_toAIA_vsClaim;
  wire        _csrMod_io_error_0;

  // ===========================================================================
  //  组合派生 —— CSRI 立即数 / ecall / ebreak / 发射握手。
  // ===========================================================================
  // csri = {59'h0, imm[16:12]} : csrrwi/csrrsi/csrrci 的 5 位 zimm。
  wire [63:0] csri     = {59'h0, io_in_bits_data_imm[16:12]};
  // fuOpType[4] = 系统指令 (ecall/ebreak/xret); imm[11:0]==0 -> ECALL, ==1 -> EBREAK。
  wire        isEcall  = io_in_bits_ctrl_fuOpType[4] & io_in_bits_data_imm[11:0] == 12'h0;
  wire        isEbreak = io_in_bits_ctrl_fuOpType[4] & io_in_bits_data_imm[11:0] == 12'h1;
  // 本拍有新请求进 NewCSR (ready&valid), 作为各暂存寄存器的更新使能。
  wire        fire     = _csrMod_io_in_ready & io_in_valid;

  // ===========================================================================
  //  暂存/流水寄存器。
  // ===========================================================================
  reg  [11:0] waddrReg;      // distribute CSR 写地址 (imm[11:0])
  reg  [63:0] wdataReg;      // distribute CSR 写数据 (按 fuOpType 选 set/clr/imm)
  reg         robIdxReg_flag;
  reg  [7:0]  robIdxReg_value;
  // 无请求时用锁存的 robIdx (与上游 flush 比较用)。
  wire        thisRobIdx_flag  = io_in_valid ? io_in_bits_ctrl_robIdx_flag  : robIdxReg_flag;
  wire [7:0]  thisRobIdx_value = io_in_valid ? io_in_bits_ctrl_robIdx_value : robIdxReg_value;

  // TrapInstMod 输入流水: fromDecode.trapInstInfo 打一拍 valid + 一拍 bits;
  //   faultCsrUop 各字段锁存 (fire 时锁当拍, 否则保持)。
  reg         trapInstMod_io_fromDecode_trapInstInfo_next_valid_last_REG;
  reg  [31:0] trapInstMod_io_fromDecode_trapInstInfo_next_bits_r_instr;
  reg         trapInstMod_io_fromDecode_trapInstInfo_next_bits_r_ftqPtr_flag;
  reg  [5:0]  trapInstMod_io_fromDecode_trapInstInfo_next_bits_r_ftqPtr_value;
  reg  [3:0]  trapInstMod_io_fromDecode_trapInstInfo_next_bits_r_ftqOffset;
  reg  [8:0]  trapInstMod_io_faultCsrUop_bits_fuOpType_r;
  reg  [63:0] trapInstMod_io_faultCsrUop_bits_imm_r;
  reg         trapInstMod_io_faultCsrUop_bits_ftqInfo_ftqPtr_r_flag;
  reg  [5:0]  trapInstMod_io_faultCsrUop_bits_ftqInfo_ftqPtr_r_value;
  reg  [3:0]  trapInstMod_io_faultCsrUop_bits_ftqInfo_ftqOffset_r;

  // ecall/ebreak 例外向量按当前特权态分派 (锁存旧值供无新请求拍读)。
  reg         exceptionVec_3_r;   // EBREAK
  wire        exceptionVec_11_isModeM  = &_csrMod_io_status_privState_PRVM;      // M 态
  wire        _exceptionVec_11_T = isEcall & exceptionVec_11_isModeM;
  reg         exceptionVec_11_r;  // ecall-from-M
  wire        PrvmIsS             = _csrMod_io_status_privState_PRVM == 2'h1;
  wire        exceptionVec_9_isModeHS  = ~_csrMod_io_status_privState_V & PrvmIsS; // HS 态
  wire        _exceptionVec_9_T  = isEcall & exceptionVec_9_isModeHS;
  reg         exceptionVec_9_r;   // ecall-from-HS
  wire        exceptionVec_10_isModeVS = _csrMod_io_status_privState_V & PrvmIsS;  // VS 态
  wire        _exceptionVec_10_T = isEcall & exceptionVec_10_isModeVS;
  reg         exceptionVec_10_r;  // ecall-from-VS
  wire        exceptionVec_8_PrvmIsU    = _csrMod_io_status_privState_PRVM == 2'h0; // U 态
  wire        _exceptionVec_8_T  = isEcall & exceptionVec_8_PrvmIsU;
  reg         exceptionVec_8_r;   // ecall-from-U

  // 输出流水锁存 (fire 时锁当拍输入)。
  reg         io_out_bits_res_redirect_valid_r;
  reg         io_out_bits_res_redirect_bits_ftqIdx_r_flag;
  reg  [5:0]  io_out_bits_res_redirect_bits_ftqIdx_r_value;
  reg  [3:0]  io_out_bits_res_redirect_bits_ftqOffset_r;
  reg         io_out_bits_ctrl_robIdx_r_flag;
  reg  [7:0]  io_out_bits_ctrl_robIdx_r_value;
  reg  [7:0]  io_out_bits_ctrl_pdest_r;
  reg         io_out_bits_ctrl_rfWen_r;
  reg  [63:0] io_out_bits_perfDebugInfo_r_enqRsTime;
  reg  [63:0] io_out_bits_perfDebugInfo_r_selectTime;
  reg  [63:0] io_out_bits_perfDebugInfo_r_issueTime;
  reg         io_error_0_REG;     // error 打两拍
  reg         io_error_0_REG_1;
  reg         io_csrio_isPerfCnt_r;

  // ---- 带异步 reset 的寄存器 ----
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      waddrReg                                                   <= 12'h0;
      wdataReg                                                   <= 64'h0;
      trapInstMod_io_fromDecode_trapInstInfo_next_valid_last_REG <= 1'h0;
      exceptionVec_3_r                                           <= 1'h0;
      exceptionVec_11_r                                          <= 1'h0;
      exceptionVec_9_r                                           <= 1'h0;
      exceptionVec_10_r                                          <= 1'h0;
      exceptionVec_8_r                                           <= 1'h0;
      io_out_bits_res_redirect_valid_r                           <= 1'h0;
      io_csrio_isPerfCnt_r                                       <= 1'h0;
    end
    else begin
      if (fire) begin
        waddrReg <= io_in_bits_data_imm[11:0];
        // wdata = 按 CSR 操作码 (fuOpType) 选择: 9=W(src), A=S(regOut|src),
        //   B=C(regOut&~src), D=WI(csri), E=SI(regOut|csri), F=CI(regOut&~csri)。
        wdataReg <=
            (io_in_bits_ctrl_fuOpType == 9'h9 ? io_in_bits_data_src_0 : 64'h0)
          | (io_in_bits_ctrl_fuOpType == 9'hA ? _csrMod_io_out_bits_regOut | io_in_bits_data_src_0 : 64'h0)
          | (io_in_bits_ctrl_fuOpType == 9'hB ? _csrMod_io_out_bits_regOut & ~io_in_bits_data_src_0 : 64'h0)
          | (io_in_bits_ctrl_fuOpType == 9'hD ? csri : 64'h0)
          | (io_in_bits_ctrl_fuOpType == 9'hE ? _csrMod_io_out_bits_regOut | csri : 64'h0)
          | (io_in_bits_ctrl_fuOpType == 9'hF
               ? _csrMod_io_out_bits_regOut & {59'h7FFFFFFFFFFFFFF, ~(io_in_bits_data_imm[16:12])} : 64'h0);
        exceptionVec_3_r  <= isEbreak;
        exceptionVec_11_r <= _exceptionVec_11_T;
        exceptionVec_9_r  <= _exceptionVec_9_T;
        exceptionVec_10_r <= _exceptionVec_10_T;
        exceptionVec_8_r  <= _exceptionVec_8_T;
        // redirect: fuOpType==0x10 (非 ecall/ebreak 的系统指令) 触发。
        io_out_bits_res_redirect_valid_r <=
          io_in_valid & io_in_bits_ctrl_fuOpType == 9'h10 & ~isEcall & ~isEbreak;
        io_csrio_isPerfCnt_r <= io_in_bits_ctrl_fuOpType != 9'h10;
      end
      // trapInstInfo valid 打一拍。
      trapInstMod_io_fromDecode_trapInstInfo_next_valid_last_REG <= io_csrin_trapInstInfo_valid;
    end
  end

  // ---- 无 reset 的寄存器 ----
  always @(posedge clock) begin
    if (fire) begin
      robIdxReg_flag                                        <= io_in_bits_ctrl_robIdx_flag;
      robIdxReg_value                                       <= io_in_bits_ctrl_robIdx_value;
      trapInstMod_io_faultCsrUop_bits_fuOpType_r            <= io_in_bits_ctrl_fuOpType;
      trapInstMod_io_faultCsrUop_bits_imm_r                 <= io_in_bits_data_imm;
      trapInstMod_io_faultCsrUop_bits_ftqInfo_ftqPtr_r_flag  <= io_in_bits_ctrl_ftqIdx_flag;
      trapInstMod_io_faultCsrUop_bits_ftqInfo_ftqPtr_r_value <= io_in_bits_ctrl_ftqIdx_value;
      trapInstMod_io_faultCsrUop_bits_ftqInfo_ftqOffset_r    <= io_in_bits_ctrl_ftqOffset;
      io_out_bits_res_redirect_bits_ftqIdx_r_flag  <= io_in_bits_ctrl_ftqIdx_flag;
      io_out_bits_res_redirect_bits_ftqIdx_r_value <= io_in_bits_ctrl_ftqIdx_value;
      io_out_bits_res_redirect_bits_ftqOffset_r    <= io_in_bits_ctrl_ftqOffset;
      io_out_bits_ctrl_robIdx_r_flag  <= io_in_bits_ctrl_robIdx_flag;
      io_out_bits_ctrl_robIdx_r_value <= io_in_bits_ctrl_robIdx_value;
      io_out_bits_ctrl_pdest_r        <= io_in_bits_ctrl_pdest;
      io_out_bits_ctrl_rfWen_r        <= io_in_bits_ctrl_rfWen;
      io_out_bits_perfDebugInfo_r_enqRsTime  <= io_in_bits_perfDebugInfo_enqRsTime;
      io_out_bits_perfDebugInfo_r_selectTime <= io_in_bits_perfDebugInfo_selectTime;
      io_out_bits_perfDebugInfo_r_issueTime  <= io_in_bits_perfDebugInfo_issueTime;
    end
    if (io_csrin_trapInstInfo_valid) begin
      trapInstMod_io_fromDecode_trapInstInfo_next_bits_r_instr        <= io_csrin_trapInstInfo_bits_instr;
      trapInstMod_io_fromDecode_trapInstInfo_next_bits_r_ftqPtr_flag  <= io_csrin_trapInstInfo_bits_ftqPtr_flag;
      trapInstMod_io_fromDecode_trapInstInfo_next_bits_r_ftqPtr_value <= io_csrin_trapInstInfo_bits_ftqPtr_value;
      trapInstMod_io_fromDecode_trapInstInfo_next_bits_r_ftqOffset    <= io_csrin_trapInstInfo_bits_ftqOffset;
    end
    io_error_0_REG   <= _csrMod_io_error_0;
    io_error_0_REG_1 <= io_error_0_REG;
  end
"""

# golden 用到的 fire 别名 (_io_csrio_isPerfCnt_T_2) 在接线块里出现, 用 wire 别名对齐。
FIRE_ALIAS = "  wire _io_csrio_isPerfCnt_T_2 = fire;\n"


def parse():
    lines = open(GOLDEN).read().split('\n')
    mstart = next(i for i, l in enumerate(lines) if l.startswith('module CSR('))
    pend   = next(i for i in range(mstart, len(lines)) if lines[i].strip() == ');')
    eidx   = next(i for i in range(len(lines) - 1, 0, -1) if lines[i].strip() == 'endmodule')
    header = lines[mstart:pend + 1]
    # 忠实保留的接线区: 从 'NewCSR csrMod' 到 endmodule 前 (4 子例化 + 输出 assign)。
    newcsr = next(i for i in range(len(lines)) if lines[i].strip().startswith('NewCSR csrMod'))
    wiring = lines[newcsr:eidx]
    ports = []
    for l in lines[mstart + 1:pend]:
        m = re.match(r'\s*(input|output)\s+(?:\[[^\]]+\]\s+)?([A-Za-z_][A-Za-z0-9_]*)', l)
        if m:
            ports.append(m.group(2))
    return header, wiring, ports


def emit_core(header, wiring, modname):
    hdr = list(header)
    hdr[0] = hdr[0].replace('module CSR(', f'module {modname}(')
    banner = [
        '// =============================================================================',
        f'// {modname} —— CSR assembly parent 可读核。scripts/gen_csr.py 生成, 勿手改。',
        '// 容器胶合逻辑 (寄存器/组合) 可读重写; 4 子例化 + 输出 assign 为同构接线忠实保留。',
        '// 子: NewCSR(绿305黑盒)/IMSIC(绿305黑盒)/TrapInstMod(叶白盒)/TrapTvalMod(叶白盒)。',
        '// =============================================================================',
    ]
    return '\n'.join(banner + hdr) + '\n' + CSR_LOGIC + '\n' + FIRE_ALIAS + '\n' + '\n'.join(wiring) + '\nendmodule\n'


def emit_wrapper(header, ports, topname, coremod):
    hdr = list(header)
    hdr[0] = hdr[0].replace('module CSR(', f'module {topname}(')
    conn = ',\n'.join(f'    .{p}({p})' for p in ports)
    banner = [
        '// =============================================================================',
        f'// {topname} (wrapper) —— golden 同名顶层, 端口与 golden CSR.sv 完全一致。',
        f'// 机械端口适配: 全部交给可读核 {coremod} u_core。scripts/gen_csr.py 生成。',
        '// =============================================================================',
    ]
    body = ['', f'  {coremod} u_core (', conn, '  );', '', 'endmodule', '']
    return '\n'.join(banner + hdr + body) + '\n'


def main():
    header, wiring, ports = parse()
    open(CORE_OUT, 'w').write(emit_core(header, wiring, 'xs_CSR_core'))
    open(WRAP_OUT, 'w').write(emit_wrapper(header, ports, 'CSR', 'xs_CSR_core'))
    open(XS_OUT,  'w').write(emit_wrapper(header, ports, 'CSR_xs', 'xs_CSR_core'))
    print(f"wrote core ({len(wiring)} wiring lines kept), wrapper, xs; {len(ports)} ports")


if __name__ == '__main__':
    main()
