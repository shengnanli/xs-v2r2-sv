import sys
p=sys.argv[1]; s=open(p).read()
old="localparam logic [DOMAIN_W-1:0] DOMAIN_DEFAULT = 4'd3;"
new="localparam logic [DOMAIN_W-1:0] DOMAIN_DEFAULT = 4'd0;"
assert old in s; open(p,'w').write(s.replace(old,new))
