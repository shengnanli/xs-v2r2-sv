#!/usr/bin/env python3
"""Generate the Iprio CSR-field family wrappers for NewCSR.

The golden Iprio family (AIA interrupt-priority CSRs) is NOT uniform per index;
the golden firtool output has three structurally distinct body shapes (see the
header of rtl/backend/newcsr_iprio.sv). This script emits one thin wrapper per
golden module that binds the golden per-instance port names and either:

  * instantiates xs_iprio_ext (reg_ALL + masked read) for Iprio{4..14}[_1], with
    gate_mask assembled from the per-instance interrupt-enable ports (64'h0 for
    the base machine flavor whose mie_* ports are unread; the eight {8{sie_*}}
    byte lanes for the _1 supervisor flavor), or
  * instantiates xs_iprio6 (six raw 8-bit fields) for Iprio{0,2}[_1] and applies
    the index-specific enable gating + rdata byte-packing in the wrapper.

Every mask/slice/pack is transcribed byte-for-byte from the golden module.
Outputs: rtl/backend/newcsr_iprio_wrappers.sv (16 wrappers).
FM-verified against golden per module in signoff-strict mode via the Iprio0Module
AUX UT family.
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, "rtl", "backend", "newcsr_iprio_wrappers.sv")

# Verbatim golden port blocks (shared across all indices per flavor).
BASE_PORTS = """  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         mie_SSIE,
  input         mie_VSSIE,
  input         mie_MSIE,
  input         mie_STIE,
  input         mie_VSTIE,
  input         mie_MTIE,
  input         mie_SEIE,
  input         mie_VSEIE,
  input         mie_MEIE,
  input         mie_SGEIE,
  input         mie_LCOFIE"""

SIE_SIGNALS = [
    "SSIE", "STIE", "SEIE", "LCOFIE",
    "LC14IE", "LC15IE", "LC16IE", "LC17IE", "LC18IE", "LC19IE", "LC20IE",
    "LC21IE", "LC22IE", "LC23IE", "LC24IE", "LC25IE", "LC26IE", "LC27IE",
    "LC28IE", "LC29IE", "LC30IE", "LC31IE", "LC32IE", "LC33IE", "LC34IE",
    "LPRASEIE", "LC36IE", "LC37IE", "LC38IE", "LC39IE", "LC40IE", "LC41IE",
    "LC42IE", "HPRASEIE", "LC44IE", "LC45IE", "LC46IE", "LC47IE", "LC48IE",
    "LC49IE", "LC50IE", "LC51IE", "LC52IE", "LC53IE", "LC54IE", "LC55IE",
    "LC56IE", "LC57IE", "LC58IE", "LC59IE", "LC60IE", "LC61IE", "LC62IE",
    "LC63IE",
]
SIE_PORTS = ("  input         clock,\n"
             "  input         reset,\n"
             "  input         w_wen,\n"
             "  input  [63:0] w_wdata,\n"
             "  output [63:0] rdata,\n"
             + ",\n".join(f"  input         sie_{s}" for s in SIE_SIGNALS))

HEADER = """// 自动生成: scripts/gen_newcsr_iprio.py —— 勿手改
// NewCSR Iprio family thin wrappers (16 golden modules).
// (A) xs_iprio_ext for Iprio{4,6,8,10,12,14}Module[_1] (reg_ALL & gate_mask).
// (B) xs_iprio6   for Iprio{0,2}Module[_1] (six raw 8-bit fields + index-specific
//     gating + rdata packing).
// Each transcribed byte-for-byte from golden; FM-verified in signoff-strict mode.
"""

# ---- (A) reg_ALL + masked read: base (mask=0) and _1 (per-index sie byte lanes).
# For each even group index N (4..14), the _1 flavor gates 8 byte-lanes with the
# eight sie_LC(8*(N/2)+k)IE enables for k=0..7, EXCEPT the two "PRASE" special
# names at LC35 (LPRASEIE) and LC43 (HPRASEIE).  We derive the lane names from
# the golden rdata expression to stay faithful (transcribed below).
EXT_LANES = {
    4:  ["LC16IE", "LC17IE", "LC18IE", "LC19IE", "LC20IE", "LC21IE", "LC22IE", "LC23IE"],
    6:  ["LC24IE", "LC25IE", "LC26IE", "LC27IE", "LC28IE", "LC29IE", "LC30IE", "LC31IE"],
    8:  ["LC32IE", "LC33IE", "LC34IE", "LPRASEIE", "LC36IE", "LC37IE", "LC38IE", "LC39IE"],
    10: ["LC40IE", "LC41IE", "LC42IE", "HPRASEIE", "LC44IE", "LC45IE", "LC46IE", "LC47IE"],
    12: ["LC48IE", "LC49IE", "LC50IE", "LC51IE", "LC52IE", "LC53IE", "LC54IE", "LC55IE"],
    14: ["LC56IE", "LC57IE", "LC58IE", "LC59IE", "LC60IE", "LC61IE", "LC62IE", "LC63IE"],
}

def ext_base(n):
    # base machine flavor: rdata = 64'h0 -> gate_mask = 64'h0 (mie_* unread).
    return f"""
module Iprio{n}Module(
{BASE_PORTS}
);
  xs_iprio_ext #(.IDX({n})) u_core (
    .clock     (clock),
    .reset     (reset),
    .w_wen     (w_wen),
    .w_wdata   (w_wdata),
    .gate_mask (64'h0),
    .rdata     (rdata)
  );
endmodule
"""

def ext_sie(n):
    lanes = EXT_LANES[n]
    # rdata = reg_ALL & { {8{lane7}}, ..., {8{lane0}} }  (lane0 = byte 0 = LSB)
    mask = "{" + ",\n     ".join(f"{{8{{sie_{l}}}}}" for l in reversed(lanes)) + "}"
    return f"""
module Iprio{n}Module_1(
{SIE_PORTS}
);
  wire [63:0] gate_mask =
    {mask};
  xs_iprio_ext #(.IDX({n})) u_core (
    .clock     (clock),
    .reset     (reset),
    .w_wen     (w_wen),
    .w_wdata   (w_wdata),
    .gate_mask (gate_mask),
    .rdata     (rdata)
  );
endmodule
"""

# ---- (B) six raw 8-bit fields.  Four bespoke modules; each transcribed exactly.
# Iprio6 core ports reg0..reg5 map to golden reg_* in golden write order.

def iprio6_inst(woffs):
    w = ",\n".join(f"    .WOFF{i}({woffs[i]})" for i in range(6))
    return (f"  xs_iprio6 #(\n{w}\n  ) u_core (\n"
            "    .clock (clock),\n    .reset (reset),\n    .w_wen (w_wen),\n"
            "    .w_wdata (w_wdata),\n"
            "    .reg0 (r0), .reg1 (r1), .reg2 (r2),\n"
            "    .reg3 (r3), .reg4 (r4), .reg5 (r5)\n  );")

# Iprio0Module (base, mie): regs SSI/VSSI/MSI/STI/VSTI/MTI at woff 8/16/24/40/48/56
#   gates: SSI&SSIE, VSSI&VSSIE, MSI&MSIE, STI&STIE, VSTI&VSTIE, MTI&MTIE
#   rdata = {MTI_g, VSTI_g, STI_g, 8'h0, MSI_g, VSSI_g, SSI_g, 8'h0}
IPRIO0_BASE = f"""
module Iprio0Module(
{BASE_PORTS}
);
  wire [7:0] r0, r1, r2, r3, r4, r5; // SSI VSSI MSI STI VSTI MTI
{iprio6_inst([8,16,24,40,48,56])}
  wire [7:0] g_SSI  = r0 & {{8{{mie_SSIE}}}};
  wire [7:0] g_VSSI = r1 & {{8{{mie_VSSIE}}}};
  wire [7:0] g_MSI  = r2 & {{8{{mie_MSIE}}}};
  wire [7:0] g_STI  = r3 & {{8{{mie_STIE}}}};
  wire [7:0] g_VSTI = r4 & {{8{{mie_VSTIE}}}};
  wire [7:0] g_MTI  = r5 & {{8{{mie_MTIE}}}};
  assign rdata = {{g_MTI, g_VSTI, g_STI, 8'h0, g_MSI, g_VSSI, g_SSI, 8'h0}};
endmodule
"""

# Iprio0Module_1 (sie): same write map; only SSI & STI read-gated
#   rdata = {16'h0, STI_g, 24'h0, SSI_g, 8'h0}
IPRIO0_SIE = f"""
module Iprio0Module_1(
{SIE_PORTS}
);
  wire [7:0] r0, r1, r2, r3, r4, r5; // SSI VSSI MSI STI VSTI MTI
{iprio6_inst([8,16,24,40,48,56])}
  wire [7:0] g_SSI = r0 & {{8{{sie_SSIE}}}};
  wire [7:0] g_STI = r3 & {{8{{sie_STIE}}}};
  assign rdata = {{16'h0, g_STI, 24'h0, g_SSI, 8'h0}};
endmodule
"""

# Iprio2Module (base, mie): regs SEI/VSEI/SGEI/LCOFI/Prio14/Prio15
#   write woff: SEI[15:8]=8, VSEI[23:16]=16, SGEI[39:32]=32, LCOFI[47:40]=40,
#               Prio14[55:48]=48, Prio15[63:56]=56
#   gates: SEI&SEIE, VSEI&VSEIE, SGEI&SGEIE, LCOFI&LCOFIE  (Prio14/15 unread)
#   rdata = {16'h0, LCOFI_g, SGEI_g, 8'h0, VSEI_g, SEI_g, 8'h0}
IPRIO2_BASE = f"""
module Iprio2Module(
{BASE_PORTS}
);
  wire [7:0] r0, r1, r2, r3, r4, r5; // SEI VSEI SGEI LCOFI Prio14 Prio15
{iprio6_inst([8,16,32,40,48,56])}
  wire [7:0] g_SEI   = r0 & {{8{{mie_SEIE}}}};
  wire [7:0] g_VSEI  = r1 & {{8{{mie_VSEIE}}}};
  wire [7:0] g_SGEI  = r2 & {{8{{mie_SGEIE}}}};
  wire [7:0] g_LCOFI = r3 & {{8{{mie_LCOFIE}}}};
  assign rdata = {{16'h0, g_LCOFI, g_SGEI, 8'h0, g_VSEI, g_SEI, 8'h0}};
endmodule
"""

# Iprio2Module_1 (sie): regs VSEI/MEI/SGEI/LCOFI/Prio14/Prio15
#   write woff: VSEI[23:16]=16, MEI[31:24]=24, SGEI[39:32]=32, LCOFI[47:40]=40,
#               Prio14[55:48]=48, Prio15[63:56]=56
#   gates: LCOFI&sie_LCOFIE, Prio14&sie_LC14IE, Prio15&sie_LC15IE
#   rdata = {Prio15_g, Prio14_g, LCOFI_g, 40'h0}
IPRIO2_SIE = f"""
module Iprio2Module_1(
{SIE_PORTS}
);
  wire [7:0] r0, r1, r2, r3, r4, r5; // VSEI MEI SGEI LCOFI Prio14 Prio15
{iprio6_inst([16,24,32,40,48,56])}
  wire [7:0] g_LCOFI  = r3 & {{8{{sie_LCOFIE}}}};
  wire [7:0] g_Prio14 = r4 & {{8{{sie_LC14IE}}}};
  wire [7:0] g_Prio15 = r5 & {{8{{sie_LC15IE}}}};
  assign rdata = {{g_Prio15, g_Prio14, g_LCOFI, 40'h0}};
endmodule
"""


def main():
    parts = [HEADER]
    parts.append(IPRIO0_BASE)
    parts.append(IPRIO0_SIE)
    parts.append(IPRIO2_BASE)
    parts.append(IPRIO2_SIE)
    for n in (4, 6, 8, 10, 12, 14):
        parts.append(ext_base(n))
        parts.append(ext_sie(n))
    with open(OUT, "w") as f:
        f.write("".join(parts))
    print(f"wrote {OUT} (16 wrappers)")


if __name__ == "__main__":
    main()
