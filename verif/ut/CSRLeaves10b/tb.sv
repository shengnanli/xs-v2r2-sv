`timescale 1ns/1ps
module tb;
 int unsigned NCYCLES=200000; int errors=0,vectors=0; logic [63:0] cfg;
 wire [31:0] s1,s1m,s2,s2m,s3,s3m; wire [63:0] z8,z8m,z10,z10m,z12,z12m,z14,z14m,p0,p0m,p2,p2m,p4,p4m;
 Sstateen1Module_xs u0(.rdata(s1),.regOut_ALL(s1m)); Sstateen2Module_xs u1(.rdata(s2),.regOut_ALL(s2m)); Sstateen3Module_xs u2(.rdata(s3),.regOut_ALL(s3m));
 Pmpcfg8Module_xs u3(.rdata(z8),.regOut_ALL(z8m)); Pmpcfg10Module_xs u4(.rdata(z10),.regOut_ALL(z10m)); Pmpcfg12Module_xs u5(.rdata(z12),.regOut_ALL(z12m)); Pmpcfg14Module_xs u6(.rdata(z14),.regOut_ALL(z14m));
 Pmpcfg0Module_xs u7(.rdata(p0),.regOut_ALL(p0m),.cfgRData(cfg)); Pmpcfg2Module_xs u8(.rdata(p2),.regOut_ALL(p2m),.cfgRData(cfg)); Pmpcfg4Module_xs u9(.rdata(p4),.regOut_ALL(p4m),.cfgRData(cfg));
 task automatic compare_now; #1; vectors++; if({s1,s1m,s2,s2m,s3,s3m,z8,z8m,z10,z10m,z12,z12m,z14,z14m}!=='0 || {p0,p0m,p2,p2m,p4,p4m}!={6{cfg}}) errors++; endtask
 initial begin cfg='0;compare_now();cfg='1;compare_now();repeat(NCYCLES)begin cfg={$urandom,$urandom};compare_now();end $display("CSRLeaves10b UT: vectors=%0d module_checks=%0d errors=%0d",vectors,vectors*10,errors);if(errors==0)$display("TEST PASSED");else $display("TEST FAILED");$finish;end
endmodule
