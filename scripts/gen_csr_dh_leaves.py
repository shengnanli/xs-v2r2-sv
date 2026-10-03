#!/usr/bin/env python3
"""Generate readable DH hypervisor/debug CSR leaf wrappers.

The core text is hand-authored below; generated regions contain only a golden-derived
port table and identity wiring.  --check validates golden ports and generated regions.
"""
from pathlib import Path
import argparse, re, sys

ROOT = Path(__file__).resolve().parent.parent
GOLDEN = Path('/home/eda/xs-env/G1-canonical/golden-rtl')
OUT = ROOT / 'rtl' / 'backend'
BEGIN = '// BEGIN GENERATED(csr_dh)'
END = '// END GENERATED'
TARGETS = [
 'DpcModule','DretEventModule','HcounterenModule','HedelegModule','HenvcfgModule',
 'HgatpModule','HidelegModule','Hstateen0Module','Hstateen1Module','Hstateen2Module',
 'Hstateen3Module','HstatusModule','HtimedeltaModule','HtinstModule','HtvalModule',
 'HvictlModule','Hviprio1Module','Hviprio2Module']


def ports(name):
    text=(GOLDEN/(name+'.sv')).read_text()
    m=re.search(r'^module '+name+r'\(\n(.*?)\n\);', text, re.S|re.M)
    if not m: raise RuntimeError(f'{name}: golden module not found')
    ans=[]
    for line in m.group(1).splitlines():
        q=re.match(r'\s*(input|output)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+),?\s*$',line)
        if not q: raise RuntimeError(f'{name}: unrecognised golden port: {line!r}')
        ans.append((q.group(1), q.group(2), q.group(3), q.group(4)))
    return ans


SPECIAL_CORE = {
    'DpcModule': ('xs_CsrEpcTvec_core #(.IS_TVEC(1\'b0))', {
        'w_wen':'wen', 'w_wdata':'wdata', 'trapToD_dpc_valid':'trap_valid',
        'trapToD_dpc_bits_epc':'trap_epc', 'regOut_epc':'epc'}),
    'HtinstModule': ('xs_CsrTrapValue_core', {
        'w_wen':'wen', 'w_wdata':'wdata', 'trapToHS_htinst_valid':'trap_valid',
        'trapToHS_htinst_bits_ALL':'trap_wdata'}),
    'HtvalModule': ('xs_CsrTrapValue_core', {
        'w_wen':'wen', 'w_wdata':'wdata', 'trapToHS_htval_valid':'trap_valid',
        'trapToHS_htval_bits_ALL':'trap_wdata'}),
}

def wrapper(name):
    ps=ports(name)
    lines=[BEGIN, f'module {name}(']
    for i,(direction,hi,lo,pname) in enumerate(ps):
        width='' if hi is None else f'[{hi}:{lo}] '
        comma=',' if i+1<len(ps) else ''
        lines.append(f'  {direction} logic {width}{pname}{comma}')
    lines += [');','']
    if name in SPECIAL_CORE:
        core, mapping = SPECIAL_CORE[name]
        lines.append(f'  {core} u_core (')
        core_map = {'clock':'clock', 'reset':'reset', 'rdata':'rdata'}
        if name in ('HtinstModule', 'HtvalModule'):
            core_map['rdata'] = 'value'
        core_map.update(mapping)
        conns=[]
        for pname in ('clock','reset','w_wen','w_wdata','trapToD_dpc_valid','trapToD_dpc_bits_epc',
                      'trapToHS_htinst_valid','trapToHS_htinst_bits_ALL','trapToHS_htval_valid','trapToHS_htval_bits_ALL',
                      'rdata','regOut_epc','regOut_ALL'):
            if pname in core_map:
                cp=core_map[pname]
                conns.append(f'    .{cp}({pname})')
        if name == 'DpcModule':
            conns.extend(['    .mode()', '    .addr()'])
        lines += [',\n'.join(conns), '  );']
        if name in ('HtinstModule', 'HtvalModule'):
            lines.append('  assign regOut_ALL = rdata;')
    else:
        lines.append(f'  xs_{name}_core u_core (')
        for i,(_,_,_,pname) in enumerate(ps):
            comma=',' if i+1<len(ps) else ''
            lines.append(f'    .{pname}({pname}){comma}')
        lines.append('  );')
    lines += ['endmodule',END]
    return '\n'.join(lines)+'\n'


def splice(name, core, check):
    path=OUT/(name+'.sv')
    old=path.read_text() if path.exists() else ''
    if not old:
        old=core+'\n'+BEGIN+'\n'+END+'\n'
    if old.count(BEGIN)!=1 or old.count(END)!=1:
        raise RuntimeError(f'{name}: generated markers must occur once')
    # These three leaves must reuse the canonical shared cores rather than
    # quietly growing a duplicate/suffixed implementation in this family.
    if name in SPECIAL_CORE:
        before=old.split(BEGIN,1)[0]
        expected_core = SPECIAL_CORE[name][0].split()[0]
        if f'module xs_{name}_core' in before:
            raise RuntimeError(f'{name}: duplicate private core; use {expected_core}')
        if expected_core not in old:
            raise RuntimeError(f'{name}: missing canonical core instance {expected_core}')
    before=old.split(BEGIN,1)[0]
    after=old.split(END,1)[1]
    new=before+wrapper(name)+after
    if check:
        if new!=old: print('DRIFT',path)
    else:
        path.write_text(new)
        print('wrote',path.relative_to(ROOT))


def core_header(name, desc):
    return f'// {name}.sv — {desc}.\n// This readable core preserves the G1 golden reset, WARL, and write-priority behavior.\n'

CORES={}
CORES['HcounterenModule']=core_header('HcounterenModule','hypervisor counter-enable CSR')+r'''module xs_HcounterenModule_core (
  input logic clock, input logic reset, input logic w_wen, input logic [63:0] w_wdata,
  output logic [63:0] rdata, output logic regOut_CY, output logic regOut_TM,
  output logic regOut_IR, output logic [28:0] regOut_HPM
);
  logic cy_q, tm_q, ir_q; logic [28:0] hpm_q;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin cy_q<=0; tm_q<=0; ir_q<=0; hpm_q<=29'h0; end
    else if (w_wen) begin cy_q<=w_wdata[0]; tm_q<=w_wdata[1]; ir_q<=w_wdata[2]; hpm_q<=w_wdata[31:3]; end
  end
  assign rdata={32'h0,hpm_q,ir_q,tm_q,cy_q};
  assign regOut_CY=cy_q; assign regOut_TM=tm_q; assign regOut_IR=ir_q; assign regOut_HPM=hpm_q;
endmodule
'''
CORES['HedelegModule']=core_header('HedelegModule','hypervisor exception-delegation CSR')+r'''module xs_HedelegModule_core (
  input logic clock, input logic reset, input logic w_wen, input logic [63:0] w_wdata,
  output logic [63:0] rdata, output logic regOut_EX_IAM, output logic regOut_EX_IAF,
  output logic regOut_EX_II, output logic regOut_EX_BP, output logic regOut_EX_LAM,
  output logic regOut_EX_LAF, output logic regOut_EX_SAM, output logic regOut_EX_SAF,
  output logic regOut_EX_UCALL, output logic regOut_EX_IPF, output logic regOut_EX_LPF,
  output logic regOut_EX_SPF, output logic regOut_EX_SWC, output logic regOut_EX_HWE
);
  logic iam_q,iaf_q,ii_q,bp_q,lam_q,laf_q,sam_q,saf_q,ucall_q;
  logic ipf_q,lpf_q,spf_q,swc_q,hwe_q;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      iam_q<=0; iaf_q<=0; ii_q<=0; bp_q<=0; lam_q<=0; laf_q<=0; sam_q<=0; saf_q<=0; ucall_q<=0;
      ipf_q<=0; lpf_q<=0; spf_q<=0; swc_q<=0; hwe_q<=0;
    end else if (w_wen) begin
      iam_q<=w_wdata[0]; iaf_q<=w_wdata[1]; ii_q<=w_wdata[2]; bp_q<=w_wdata[3]; lam_q<=w_wdata[4];
      laf_q<=w_wdata[5]; sam_q<=w_wdata[6]; saf_q<=w_wdata[7]; ucall_q<=w_wdata[8]; ipf_q<=w_wdata[12];
      lpf_q<=w_wdata[13]; spf_q<=w_wdata[15]; swc_q<=w_wdata[18]; hwe_q<=w_wdata[19];
    end
  end
  assign rdata={44'h0,hwe_q,swc_q,2'h0,spf_q,1'h0,lpf_q,ipf_q,3'h0,ucall_q,saf_q,sam_q,laf_q,lam_q,bp_q,ii_q,iaf_q,iam_q};
  assign regOut_EX_IAM=iam_q; assign regOut_EX_IAF=iaf_q; assign regOut_EX_II=ii_q; assign regOut_EX_BP=bp_q;
  assign regOut_EX_LAM=lam_q; assign regOut_EX_LAF=laf_q; assign regOut_EX_SAM=sam_q; assign regOut_EX_SAF=saf_q;
  assign regOut_EX_UCALL=ucall_q; assign regOut_EX_IPF=ipf_q; assign regOut_EX_LPF=lpf_q; assign regOut_EX_SPF=spf_q;
  assign regOut_EX_SWC=swc_q; assign regOut_EX_HWE=hwe_q;
endmodule
'''
CORES['HenvcfgModule']=core_header('HenvcfgModule','hypervisor environment configuration CSR')+r'''module xs_HenvcfgModule_core (
  input logic clock, input logic reset, input logic w_wen, input logic [63:0] w_wdata,
  output logic [63:0] rdata, output logic regOut_STCE, output logic regOut_PBMTE, output logic regOut_DTE,
  output logic [1:0] regOut_PMM, output logic regOut_CBZE, output logic regOut_CBCFE, output logic [1:0] regOut_CBIE,
  input logic menvcfg_STCE, input logic menvcfg_PBMTE, input logic menvcfg_DTE
);
  logic stce_q,pbmte_q,dte_q,cbze_q,cbcfe_q; logic [1:0] pmm_q,cbie_q;
  wire pmm_legal=(w_wdata[33:32]==2'h0)||(w_wdata[33:32]==2'h2)||(&w_wdata[33:32]);
  wire cbie_legal=(w_wdata[5:4]==2'h0)||(w_wdata[5:4]==2'h1)||(&w_wdata[5:4]);
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin stce_q<=1; pbmte_q<=0; dte_q<=0; pmm_q<=0; cbze_q<=1; cbcfe_q<=1; cbie_q<=2'h3; end
    else begin
      if (w_wen) begin stce_q<=w_wdata[63]; pbmte_q<=w_wdata[62]; dte_q<=w_wdata[59]; cbze_q<=w_wdata[7]; cbcfe_q<=w_wdata[6]; end
      if (w_wen && pmm_legal) pmm_q<=w_wdata[33:32];
      if (w_wen && cbie_legal) cbie_q<=w_wdata[5:4];
    end
  end
  wire stce_out=menvcfg_STCE&stce_q, pbmte_out=menvcfg_PBMTE&pbmte_q, dte_out=menvcfg_DTE&dte_q;
  assign rdata={stce_out,pbmte_out,2'h0,dte_out,25'h0,pmm_q,24'h0,cbze_q,cbcfe_q,cbie_q,4'h0};
  assign regOut_STCE=stce_out; assign regOut_PBMTE=pbmte_out; assign regOut_DTE=dte_out; assign regOut_PMM=pmm_q;
  assign regOut_CBZE=cbze_q; assign regOut_CBCFE=cbcfe_q; assign regOut_CBIE=cbie_q;
endmodule
'''
CORES['HgatpModule']=core_header('HgatpModule','hypervisor address-translation root CSR')+r'''module xs_HgatpModule_core (
  input logic clock, input logic reset, input logic w_wen, input logic [63:0] w_wdata,
  output logic [63:0] rdata, output logic [3:0] regOut_MODE, output logic [13:0] regOut_VMID, output logic [43:0] regOut_PPN
);
  logic [3:0] mode_q; logic [13:0] vmid_q; logic [43:0] ppn_q;
  wire mode_legal=(w_wdata[63:60]==4'h0)||(w_wdata[63:60]==4'h8)||(w_wdata[63:60]==4'h9);
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin mode_q<=0; vmid_q<=0; ppn_q<=0; end
    else begin
      if (w_wen && mode_legal) mode_q<=w_wdata[63:60];
      if (w_wen) begin vmid_q<=w_wdata[57:44]; ppn_q<={8'h0,w_wdata[35:2],2'h0}; end
    end
  end
  assign rdata={mode_q,2'h0,vmid_q,ppn_q}; assign regOut_MODE=mode_q; assign regOut_VMID=vmid_q; assign regOut_PPN=ppn_q;
endmodule
'''
CORES['HidelegModule']=core_header('HidelegModule','hypervisor interrupt-delegation CSR')+r'''module xs_HidelegModule_core (
  input logic clock, input logic reset, input logic w_wen, input logic [63:0] w_wdata,
  output logic [63:0] rdata, output logic regOut_SSI, output logic regOut_VSSI, output logic regOut_MSI,
  output logic regOut_STI, output logic regOut_VSTI, output logic regOut_MTI, output logic regOut_SEI,
  output logic regOut_VSEI, output logic regOut_MEI, output logic regOut_SGEI, output logic regOut_LCOFI,
  input logic mideleg_SSI, input logic mideleg_STI, input logic mideleg_SEI, input logic mideleg_LCOFI
);
  logic vssi_q,vsti_q,vsei_q,lcofi_q;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin vssi_q<=0; vsti_q<=0; vsei_q<=0; lcofi_q<=0; end
    else if (w_wen) begin vssi_q<=w_wdata[2]; vsti_q<=w_wdata[6]; vsei_q<=w_wdata[10]; lcofi_q<=w_wdata[13]; end
  end
  wire lcofi_out=lcofi_q&mideleg_LCOFI;
  assign rdata={50'h0,lcofi_out,2'h0,vsei_q,3'h0,vsti_q,3'h0,vssi_q,2'h0};
  assign regOut_SSI=0; assign regOut_VSSI=vssi_q; assign regOut_MSI=0; assign regOut_STI=0; assign regOut_VSTI=vsti_q;
  assign regOut_MTI=0; assign regOut_SEI=0; assign regOut_VSEI=vsei_q; assign regOut_MEI=0; assign regOut_SGEI=0; assign regOut_LCOFI=lcofi_out;
endmodule
'''
CORES['Hstateen0Module']=core_header('Hstateen0Module','VS state-enable level 0')+r'''module xs_Hstateen0Module_core (
  input logic clock, input logic reset, input logic w_wen, input logic [63:0] w_wdata,
  output logic [63:0] rdata, output logic regOut_JVT, output logic regOut_FCSR, output logic regOut_C,
  output logic regOut_SE0, output logic regOut_ENVCFG, output logic regOut_CSRIND, output logic regOut_AIA,
  output logic regOut_IMSIC, output logic regOut_CONTEXT, input logic fromMstateen0_SE0, input logic fromMstateen0_ENVCFG,
  input logic fromMstateen0_CSRIND, input logic fromMstateen0_AIA, input logic fromMstateen0_IMSIC,
  input logic fromMstateen0_CONTEXT, input logic fromMstateen0_C
);
  logic c_q,se0_q,envcfg_q,csrind_q,aia_q,imsic_q,context_q;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin c_q<=0;se0_q<=0;envcfg_q<=0;csrind_q<=0;aia_q<=0;imsic_q<=0;context_q<=0; end
    else if (w_wen) begin c_q<=w_wdata[0];se0_q<=w_wdata[63];envcfg_q<=w_wdata[62];csrind_q<=w_wdata[60];aia_q<=w_wdata[59];imsic_q<=w_wdata[58];context_q<=w_wdata[57]; end
  end
  wire c_out=c_q&fromMstateen0_C, se0_out=se0_q&fromMstateen0_SE0, envcfg_out=envcfg_q&fromMstateen0_ENVCFG;
  wire csrind_out=csrind_q&fromMstateen0_CSRIND, aia_out=aia_q&fromMstateen0_AIA, imsic_out=imsic_q&fromMstateen0_IMSIC, context_out=context_q&fromMstateen0_CONTEXT;
  assign rdata={se0_out,envcfg_out,1'b0,csrind_out,aia_out,imsic_out,context_out,56'h0,c_out};
  assign regOut_JVT=0; assign regOut_FCSR=0; assign regOut_C=c_out; assign regOut_SE0=se0_out; assign regOut_ENVCFG=envcfg_out;
  assign regOut_CSRIND=csrind_out; assign regOut_AIA=aia_out; assign regOut_IMSIC=imsic_out; assign regOut_CONTEXT=context_out;
endmodule
'''
for n in ('1','2','3'):
    CORES[f'Hstateen{n}Module']=core_header(f'Hstateen{n}Module',f'VS state-enable level {n}')+f'''module xs_Hstateen{n}Module_core (\n  input logic clock, input logic w_wen, input logic [63:0] w_wdata, output logic [63:0] rdata,\n  output logic regOut_SE, input logic fromMstateen{n}_SE\n);\n  logic se_q;\n  always_ff @(posedge clock) if (w_wen) se_q<=w_wdata[63];\n  wire se_out=se_q&fromMstateen{n}_SE;\n  assign rdata={{se_out,63'h0}}; assign regOut_SE=se_out;\nendmodule\n'''
CORES['HstatusModule']=core_header('HstatusModule','hypervisor status CSR')+r'''module xs_HstatusModule_core (
  input logic clock, input logic reset, input logic w_wen, input logic [63:0] w_wdata, output logic [63:0] rdata,
  output logic regOut_GVA, output logic regOut_SPV, output logic regOut_SPVP, output logic regOut_HU, output logic [5:0] regOut_VGEIN,
  output logic regOut_VTVM, output logic regOut_VTW, output logic regOut_VTSR, output logic [1:0] regOut_HUPMM,
  input logic retFromS_hstatus_valid, input logic retFromS_hstatus_bits_SPV, input logic trapToHS_hstatus_valid,
  input logic trapToHS_hstatus_bits_GVA, input logic trapToHS_hstatus_bits_SPV, input logic trapToHS_hstatus_bits_SPVP
);
  logic gva_q,spv_q,spvp_q,hu_q,vtvm_q,vtw_q,vtsr_q; logic [5:0] vgein_q; logic [1:0] hupmm_q;
  wire hupmm_legal=(w_wdata[49:48]==2'h0)||(w_wdata[49:48]==2'h2)||(&w_wdata[49:48]);
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin gva_q<=0;spv_q<=0;spvp_q<=0;hu_q<=0;vgein_q<=0;vtvm_q<=0;vtw_q<=0;vtsr_q<=0;hupmm_q<=0; end
    else begin
      if (w_wen || trapToHS_hstatus_valid) begin gva_q<=(trapToHS_hstatus_valid&trapToHS_hstatus_bits_GVA)|(w_wen&w_wdata[6]); spvp_q<=(trapToHS_hstatus_valid&trapToHS_hstatus_bits_SPVP)|(w_wen&w_wdata[8]); end
      if (w_wen || retFromS_hstatus_valid || trapToHS_hstatus_valid) spv_q<=(retFromS_hstatus_valid&retFromS_hstatus_bits_SPV)|(trapToHS_hstatus_valid&trapToHS_hstatus_bits_SPV)|(w_wen&w_wdata[7]);
      if (w_wen) begin hu_q<=w_wdata[9];vgein_q<=w_wdata[17:12];vtvm_q<=w_wdata[20];vtw_q<=w_wdata[21];vtsr_q<=w_wdata[22]; end
      if (w_wen && hupmm_legal) hupmm_q<=w_wdata[49:48];
    end
  end
  assign rdata={14'h0,hupmm_q,25'h400,vtsr_q,vtw_q,vtvm_q,2'h0,vgein_q,2'h0,hu_q,spvp_q,spv_q,gva_q,6'h0};
  assign regOut_GVA=gva_q; assign regOut_SPV=spv_q; assign regOut_SPVP=spvp_q; assign regOut_HU=hu_q; assign regOut_VGEIN=vgein_q; assign regOut_VTVM=vtvm_q; assign regOut_VTW=vtw_q; assign regOut_VTSR=vtsr_q; assign regOut_HUPMM=hupmm_q;
endmodule
'''
for n in ('HtimedeltaModule','Hviprio2Module'):
    CORES[n]=core_header(n,'64-bit writable hypervisor CSR')+f'''module xs_{n}_core (input logic clock,input logic reset,input logic w_wen,input logic [63:0] w_wdata,output logic [63:0] rdata,output logic [63:0] regOut_ALL);\n  logic [63:0] value_q;\n  always_ff @(posedge clock or posedge reset) begin if(reset) value_q<=64'h0; else if(w_wen) value_q<=w_wdata; end\n  assign rdata=value_q; assign regOut_ALL=value_q;\nendmodule\n'''
CORES['HvictlModule']=core_header('HvictlModule','virtual interrupt-control CSR')+r'''module xs_HvictlModule_core (input logic clock,input logic reset,input logic w_wen,input logic [63:0] w_wdata,output logic [63:0] rdata,output logic regOut_VTI,output logic [11:0] regOut_IID,output logic regOut_DPR,output logic regOut_IPRIOM,output logic [7:0] regOut_IPRIO);
  logic vti_q,dpr_q,ipriom_q; logic [11:0] iid_q; logic [7:0] iprio_q;
  always_ff @(posedge clock or posedge reset) begin if(reset) begin vti_q<=0;iid_q<=0;dpr_q<=0;ipriom_q<=0;iprio_q<=0; end else if(w_wen) begin vti_q<=w_wdata[30];iid_q<=w_wdata[27:16];dpr_q<=w_wdata[9];ipriom_q<=w_wdata[8];iprio_q<=w_wdata[7:0]; end end
  assign rdata={33'h0,vti_q,2'h0,iid_q,6'h0,dpr_q,ipriom_q,iprio_q}; assign regOut_VTI=vti_q; assign regOut_IID=iid_q; assign regOut_DPR=dpr_q; assign regOut_IPRIOM=ipriom_q; assign regOut_IPRIO=iprio_q;
endmodule
'''
CORES['Hviprio1Module']=core_header('Hviprio1Module','virtual interrupt-priority bytes')+r'''module xs_Hviprio1Module_core (input logic clock,input logic reset,input logic w_wen,input logic [63:0] w_wdata,output logic [63:0] rdata,output logic [7:0] regOut_PrioSSI,output logic [7:0] regOut_PrioSTI,output logic [7:0] regOut_PrioCOI,output logic [7:0] regOut_Prio14,output logic [7:0] regOut_Prio15);
  logic [7:0] ssi_q,sti_q,coi_q,irq14_q,irq15_q;
  always_ff @(posedge clock or posedge reset) begin if(reset) begin ssi_q<=0;sti_q<=0;coi_q<=0;irq14_q<=0;irq15_q<=0; end else if(w_wen) begin ssi_q<=w_wdata[15:8];sti_q<=w_wdata[31:24];coi_q<=w_wdata[47:40];irq14_q<=w_wdata[55:48];irq15_q<=w_wdata[63:56]; end end
  assign rdata={irq15_q,irq14_q,coi_q,8'h0,sti_q,8'h0,ssi_q,8'h0}; assign regOut_PrioSSI=ssi_q; assign regOut_PrioSTI=sti_q; assign regOut_PrioCOI=coi_q; assign regOut_Prio14=irq14_q; assign regOut_Prio15=irq15_q;
endmodule
'''

# Dret is kept separate for readability because it is a pure event transform, not state.
CORES['DretEventModule']=core_header('DretEventModule','debug return event transform')+r'''module xs_DretEventModule_core (
  input logic valid,input logic in_dcsr_V,input logic [1:0] in_dcsr_PRV,input logic [62:0] in_dpc_epc,
  input logic in_mstatus_MPRV,input logic in_mstatus_SDT,input logic in_mstatus_MDT,input logic in_vsstatus_SDT,
  input logic [3:0] in_satp_MODE,input logic [3:0] in_vsatp_MODE,input logic [3:0] in_hgatp_MODE,
  output logic out_privState_valid,output logic [1:0] out_privState_bits_PRVM,output logic out_privState_bits_V,
  output logic out_dcsr_valid,output logic [3:0] out_dcsr_bits_DEBUGVER,output logic [2:0] out_dcsr_bits_EXTCAUSE,
  output logic out_dcsr_bits_CETRIG,output logic out_dcsr_bits_EBREAKVS,output logic out_dcsr_bits_EBREAKVU,output logic out_dcsr_bits_EBREAKM,
  output logic out_dcsr_bits_EBREAKS,output logic out_dcsr_bits_EBREAKU,output logic out_dcsr_bits_STEPIE,output logic out_dcsr_bits_STOPCOUNT,
  output logic out_dcsr_bits_STOPTIME,output logic [2:0] out_dcsr_bits_CAUSE,output logic out_dcsr_bits_V,output logic out_dcsr_bits_MPRVEN,
  output logic out_dcsr_bits_NMIP,output logic out_dcsr_bits_STEP,output logic [1:0] out_dcsr_bits_PRV,
  output logic out_mstatus_valid,output logic out_mstatus_bits_SIE,output logic out_mstatus_bits_MIE,output logic out_mstatus_bits_SPIE,
  output logic out_mstatus_bits_UBE,output logic out_mstatus_bits_MPIE,output logic out_mstatus_bits_SPP,output logic [1:0] out_mstatus_bits_VS,
  output logic [1:0] out_mstatus_bits_MPP,output logic [1:0] out_mstatus_bits_FS,output logic [1:0] out_mstatus_bits_XS,output logic out_mstatus_bits_MPRV,
  output logic out_mstatus_bits_SUM,output logic out_mstatus_bits_MXR,output logic out_mstatus_bits_TVM,output logic out_mstatus_bits_TW,output logic out_mstatus_bits_TSR,
  output logic out_mstatus_bits_SDT,output logic [1:0] out_mstatus_bits_UXL,output logic [1:0] out_mstatus_bits_SXL,output logic out_mstatus_bits_SBE,
  output logic out_mstatus_bits_MBE,output logic out_mstatus_bits_GVA,output logic out_mstatus_bits_MPV,output logic out_mstatus_bits_MDT,output logic out_mstatus_bits_SD,
  output logic out_vsstatus_valid,output logic out_vsstatus_bits_SIE,output logic out_vsstatus_bits_SPIE,output logic out_vsstatus_bits_UBE,output logic out_vsstatus_bits_SPP,
  output logic [1:0] out_vsstatus_bits_VS,output logic [1:0] out_vsstatus_bits_FS,output logic [1:0] out_vsstatus_bits_XS,output logic out_vsstatus_bits_SUM,
  output logic out_vsstatus_bits_MXR,output logic out_vsstatus_bits_SDT,output logic [1:0] out_vsstatus_bits_UXL,output logic out_vsstatus_bits_SD,
  output logic out_debugMode_valid,output logic out_debugMode_bits,output logic out_debugIntrEnable_valid,output logic out_debugIntrEnable_bits,
  output logic out_targetPc_valid,output logic [63:0] out_targetPc_bits_pc,output logic out_targetPc_bits_raiseIPF,output logic out_targetPc_bits_raiseIAF,output logic out_targetPc_bits_raiseIGPF
);
  wire is_machine=&in_dcsr_PRV;
  wire is_virtual=(in_dcsr_PRV!=2'h3)&in_dcsr_V;
  wire is_hu=!is_virtual&(in_dcsr_PRV==2'h0);
  wire is_vu=is_virtual&(in_dcsr_PRV==2'h0);
  wire vsatp_bare=(in_vsatp_MODE==4'h0);
  assign out_privState_valid=valid; assign out_privState_bits_PRVM=in_dcsr_PRV; assign out_privState_bits_V=is_virtual;
  assign out_dcsr_valid=valid; assign out_dcsr_bits_DEBUGVER=0; assign out_dcsr_bits_EXTCAUSE=0; assign out_dcsr_bits_CETRIG=0; assign out_dcsr_bits_EBREAKVS=0; assign out_dcsr_bits_EBREAKVU=0; assign out_dcsr_bits_EBREAKM=0; assign out_dcsr_bits_EBREAKS=0; assign out_dcsr_bits_EBREAKU=0; assign out_dcsr_bits_STEPIE=0; assign out_dcsr_bits_STOPCOUNT=0; assign out_dcsr_bits_STOPTIME=0; assign out_dcsr_bits_CAUSE=0; assign out_dcsr_bits_V=0; assign out_dcsr_bits_MPRVEN=0; assign out_dcsr_bits_NMIP=0; assign out_dcsr_bits_STEP=0; assign out_dcsr_bits_PRV=0;
  assign out_mstatus_valid=valid; assign out_mstatus_bits_SIE=0; assign out_mstatus_bits_MIE=0; assign out_mstatus_bits_SPIE=0; assign out_mstatus_bits_UBE=0; assign out_mstatus_bits_MPIE=0; assign out_mstatus_bits_SPP=0; assign out_mstatus_bits_VS=0; assign out_mstatus_bits_MPP=0; assign out_mstatus_bits_FS=0; assign out_mstatus_bits_XS=0; assign out_mstatus_bits_MPRV=is_machine&in_mstatus_MPRV; assign out_mstatus_bits_SUM=0; assign out_mstatus_bits_MXR=0; assign out_mstatus_bits_TVM=0; assign out_mstatus_bits_TW=0; assign out_mstatus_bits_TSR=0;
  assign out_mstatus_bits_SDT=!(is_virtual|is_hu)&in_mstatus_SDT; assign out_mstatus_bits_UXL=0; assign out_mstatus_bits_SXL=0; assign out_mstatus_bits_SBE=0; assign out_mstatus_bits_MBE=0; assign out_mstatus_bits_GVA=0; assign out_mstatus_bits_MPV=0; assign out_mstatus_bits_MDT=is_machine&in_mstatus_MDT; assign out_mstatus_bits_SD=0;
  assign out_vsstatus_valid=valid; assign out_vsstatus_bits_SIE=0; assign out_vsstatus_bits_SPIE=0; assign out_vsstatus_bits_UBE=0; assign out_vsstatus_bits_SPP=0; assign out_vsstatus_bits_VS=0; assign out_vsstatus_bits_FS=0; assign out_vsstatus_bits_XS=0; assign out_vsstatus_bits_SUM=0; assign out_vsstatus_bits_MXR=0; assign out_vsstatus_bits_SDT=!is_vu&in_vsstatus_SDT; assign out_vsstatus_bits_UXL=0; assign out_vsstatus_bits_SD=0;
  assign out_debugMode_valid=valid; assign out_debugMode_bits=0; assign out_debugIntrEnable_valid=valid; assign out_debugIntrEnable_bits=1;
  assign out_targetPc_valid=valid; assign out_targetPc_bits_pc={in_dpc_epc,1'b0};
  assign out_targetPc_bits_raiseIPF= ((!is_machine&&!is_virtual&&in_satp_MODE==4'h8&&in_dpc_epc[62:38]!={25{in_dpc_epc[37]}})||(is_virtual&&in_vsatp_MODE==4'h8&&in_dpc_epc[62:38]!={25{in_dpc_epc[37]}})||(!is_machine&&!is_virtual&&in_satp_MODE==4'h9&&in_dpc_epc[62:47]!={16{in_dpc_epc[46]}})||(is_virtual&&in_vsatp_MODE==4'h9&&in_dpc_epc[62:47]!={16{in_dpc_epc[46]}}));
  assign out_targetPc_bits_raiseIAF=(is_machine||(!is_virtual&&in_satp_MODE==4'h0)||(is_virtual&&vsatp_bare&&in_hgatp_MODE==4'h0))&(|in_dpc_epc[62:47]);
  assign out_targetPc_bits_raiseIGPF=(is_virtual&&vsatp_bare&&in_hgatp_MODE==4'h8&&( |in_dpc_epc[62:40]))||(is_virtual&&vsatp_bare&&in_hgatp_MODE==4'h9&&( |in_dpc_epc[62:49]));
endmodule
'''


def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--check',action='store_true'); a=ap.parse_args()
    bad=0
    for name in TARGETS:
        path=OUT/(name+'.sv')
        if not path.exists():
            if a.check:
                print('MISSING', path)
                bad += 1
                continue
            if name in SPECIAL_CORE:
                # Shared-core wrappers are intentionally coreless; the shared
                # implementation is listed by the family Makefile.
                path.write_text(core_header(name, 'wrapper around canonical shared CSR core') + BEGIN + '\n' + END + '\n')
            elif name not in CORES:
                raise RuntimeError(f'missing hand-authored core/wrapper {name}')
            else:
                path.write_text(CORES[name]+'\n'+BEGIN+'\n'+END+'\n')
        current=path.read_text()
        before=current.split(BEGIN,1)[0]
        suffix=current.split(END,1)[1].lstrip('\n')
        expected=before+wrapper(name)+suffix
        if a.check:
            if expected!=current: print('DRIFT',path); bad+=1
        else:
            path.write_text(expected); print('wrote',path.relative_to(ROOT))
    if a.check and bad: return 1
    print('gen_csr_dh_leaves: '+('OK' if a.check else 'generated'))
    return 0
if __name__=='__main__': sys.exit(main())
