import sys
p=sys.argv[1]; s=open(p).read()
old="assign a_region_key = {in_a_address[48], in_a_address[30:12]};"
new="assign a_region_key = {in_a_address[48], in_a_address[31:13]};"
assert old in s; open(p,'w').write(s.replace(old,new))
