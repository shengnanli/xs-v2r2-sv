import sys
p=sys.argv[1]; s=open(p).read()
old="""      if (a_fire && group_sel[g])
        group_domain[g] <= a_domain;"""
new="""      if (a_fire)
        group_domain[g] <= a_domain;"""
assert old in s; open(p,'w').write(s.replace(old,new))
