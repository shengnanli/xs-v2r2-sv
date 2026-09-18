import sys
p=sys.argv[1]; s=open(p).read()
old="""      if (a_track_set && in_a_source < SOURCE_W'(END_SOURCE_ID))
        flight[in_a_source] <= 1'b1;
      if (d_track_clr && out_d_source < SOURCE_W'(END_SOURCE_ID))
        flight[out_d_source] <= 1'b0;"""
new="""      if (d_track_clr && out_d_source < SOURCE_W'(END_SOURCE_ID))
        flight[out_d_source] <= 1'b0;
      if (a_track_set && in_a_source < SOURCE_W'(END_SOURCE_ID))
        flight[in_a_source] <= 1'b1;"""
assert old in s; open(p,'w').write(s.replace(old,new))
