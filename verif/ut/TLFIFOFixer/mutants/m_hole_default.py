# 把 APLIC 的保留洞按"没查到就走默认域"处理 (删掉 4 条 domain=0 的洞)
import sys
p=sys.argv[1]; s=open(p).read()
for k in ["'{base: 20'h31108, care: 20'hFFFF8, domain: 4'd0 },",
          "'{base: 20'h31110, care: 20'hFFFF0, domain: 4'd0 },",
          "'{base: 20'h31128, care: 20'hFFFF8, domain: 4'd0 },",
          "'{base: 20'h31130, care: 20'hFFFF0, domain: 4'd0 },"]:
    assert k in s
    s=s.replace(k, k.replace("4'd0 }","4'd3 }"))
s=s.replace("localparam int NUM_REGION = 16;","localparam int NUM_REGION = 16;")
open(p,'w').write(s)
