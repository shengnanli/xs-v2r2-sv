# golden PreDecode 含 xs_assert_v2 断言(sim-verilog sed 产物), 无定义体;
# 同 RASStack/TLPLIC 精确先例: 定义 SYNTHESIS 关断言+随机初值(FM 侧本就带 SYNTHESIS)。
VCS += +define+SYNTHESIS
