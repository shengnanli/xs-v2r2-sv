import sys
p=sys.argv[1]; s=open(p).read()
old="assign a_track_set = a_first & a_fire;"
new="assign a_track_set = a_first & a_fire & ~a_no_domain;"
assert old in s; open(p,'w').write(s.replace(old,new))
