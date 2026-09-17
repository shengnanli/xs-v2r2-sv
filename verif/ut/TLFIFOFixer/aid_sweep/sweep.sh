#!/bin/bash
# 从 golden 截取 a_id 组合逻辑 → VCS 全枚举 2^20 → 与 REGION_MAP 逐点核对。
set -e
GOLDEN=${GOLDEN_RTL:-/home/eda/xs-env/G1-canonical/golden-rtl}/TLFIFOFixer.sv
HERE=$(cd "$(dirname "$0")" && pwd)
WORK=${WORK:-$HERE/work}
mkdir -p "$WORK"; cd "$WORK"

sha256sum "$GOLDEN"

{
  echo "module aid_probe(input [48:0] auto_in_a_bits_address, output [3:0] id);"
  sed -n '139,347p' "$GOLDEN"          # golden a_id 定义，原样不改
  echo "  assign id = a_id;"
  echo "endmodule"
} > aid_probe.sv

cat > tb_aid.sv <<'TBEOF'
module tb;
  reg [48:0] addr; wire [3:0] id; integer f, k;
  aid_probe u(.auto_in_a_bits_address(addr), .id(id));
  initial begin
    f = $fopen("aid_table.txt","w");
    for (k = 0; k < (1<<20); k = k + 1) begin
      addr = 49'b0;
      addr[48]    = k[19];
      addr[30]    = k[18];
      addr[29:12] = k[17:0];
      #1;
      if (id != 4'h0) $fwrite(f, "%05x %x\n", k, id);
    end
    $fclose(f); $display("SWEEP DONE"); $finish;
  end
endmodule
TBEOF

export VCS_ARCH_OVERRIDE=linux
vcs -full64 -sverilog -q -o simv aid_probe.sv tb_aid.sv -l comp.log > /dev/null
./simv -q | tail -2
python3 "$HERE/check_table.py" aid_table.txt
