# golden 把 IMSIC 的 m 页与 sg 页放在同一个域 5; 拆成两个域是很自然的"手滑"
import sys
p=sys.argv[1]; s=open(p).read()
old="'{base: 20'h3B000, care: 20'hFFFF8, domain: 4'd5 },"
new="'{base: 20'h3B000, care: 20'hFFFF8, domain: 4'd11},"
assert old in s; open(p,'w').write(s.replace(old,new))
