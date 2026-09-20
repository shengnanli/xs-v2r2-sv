import sys
p=sys.argv[1]; s=open(p).read()
old="""      group_stall[g] = group_sel[g] & a_first & group_busy[g]"""
new="""      group_stall[g] = group_sel[g] & group_busy[g]"""
assert old in s; open(p,'w').write(s.replace(old,new))
