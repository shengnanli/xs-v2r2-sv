import sys
p=sys.argv[1]; s=open(p).read()
old="assign d_track_clr = d_first & (out_d_opcode != D_OPCODE_RELEASE_ACK) & d_fire;"
new="assign d_track_clr = d_first & d_fire;"
assert old in s; open(p,'w').write(s.replace(old,new))
