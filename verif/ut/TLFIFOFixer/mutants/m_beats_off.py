import sys
p=sys.argv[1]; s=open(p).read()
old="    shifted = 13'h3F << size;"
new="    shifted = 13'h1F << size;"
assert old in s; open(p,'w').write(s.replace(old,new))
