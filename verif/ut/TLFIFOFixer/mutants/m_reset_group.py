import sys,re
p=sys.argv[1]; s=open(p).read()
old="""  always_ff @(posedge clock) begin
    for (int g = 0; g < NUM_MASTERS; g++)
      if (a_fire && group_sel[g])
        group_domain[g] <= a_domain;
  end"""
new="""  always_ff @(posedge clock or posedge reset) begin
    if (reset) for (int g = 0; g < NUM_MASTERS; g++) group_domain[g] <= '0;
    else for (int g = 0; g < NUM_MASTERS; g++)
      if (a_fire && group_sel[g])
        group_domain[g] <= a_domain;
  end"""
assert old in s; open(p,'w').write(s.replace(old,new))
