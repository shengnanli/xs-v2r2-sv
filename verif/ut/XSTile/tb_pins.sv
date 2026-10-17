// 自动生成：scripts/gen_xscore_xstile.py render_pin_check(XSTile) —— 勿手改（gen.py 调用）
// 两侧每个子模块的每个输入引脚逐拍 4 态比较（356 个引脚，5445 位）；bind 进 tb。
module tb_pins_XSTile;
  longint pin_checks = 0, pin_errors = 0;
  bit armed = 0;
  bit [355:0] tog;
  logic v0;
  logic v1;
  logic [3:0] v2;
  logic [1:0] v3;
  logic [1:0] v4;
  logic [3:0] v5;
  logic v6;
  logic v7;
  logic [63:0] v8;
  logic v9;
  logic v10;
  logic v11;
  logic [3:0] v12;
  logic [1:0] v13;
  logic [1:0] v14;
  logic v15;
  logic v16;
  logic v17;
  logic [63:0] v18;
  logic v19;
  logic v20;
  logic [3:0] v21;
  logic [2:0] v22;
  logic [1:0] v23;
  logic [4:0] v24;
  logic [29:0] v25;
  logic [7:0] v26;
  logic [63:0] v27;
  logic v28;
  logic v29;
  logic v30;
  logic v31;
  logic [3:0] v32;
  logic [1:0] v33;
  logic [2:0] v34;
  logic [3:0] v35;
  logic [9:0] v36;
  logic v37;
  logic [255:0] v38;
  logic v39;
  logic v40;
  logic v41;
  logic [3:0] v42;
  logic [1:0] v43;
  logic [2:0] v44;
  logic [3:0] v45;
  logic [9:0] v46;
  logic v47;
  logic [255:0] v48;
  logic v49;
  logic v50;
  logic v51;
  logic v52;
  logic v53;
  logic v54;
  logic v55;
  logic v56;
  logic v57;
  logic v58;
  logic v59;
  logic [2:0] v60;
  logic [1:0] v61;
  logic [2:0] v62;
  logic [5:0] v63;
  logic [47:0] v64;
  logic [31:0] v65;
  logic [255:0] v66;
  logic v67;
  logic v68;
  logic v69;
  logic [3:0] v70;
  logic [1:0] v71;
  logic [2:0] v72;
  logic [5:0] v73;
  logic [9:0] v74;
  logic v75;
  logic v76;
  logic [255:0] v77;
  logic v78;
  logic v79;
  logic [5:0] v80;
  logic v81;
  logic [11:0] v82;
  logic v83;
  logic [63:0] v84;
  logic [47:0] v85;
  logic v86;
  logic v87;
  logic v88;
  logic [5:0] v89;
  logic [5:0] v90;
  logic [5:0] v91;
  logic [5:0] v92;
  logic [5:0] v93;
  logic [5:0] v94;
  logic [5:0] v95;
  logic [5:0] v96;
  logic [5:0] v97;
  logic [5:0] v98;
  logic [5:0] v99;
  logic [5:0] v100;
  logic [5:0] v101;
  logic [5:0] v102;
  logic [5:0] v103;
  logic [5:0] v104;
  logic [5:0] v105;
  logic [5:0] v106;
  logic [5:0] v107;
  logic [5:0] v108;
  logic [5:0] v109;
  logic [5:0] v110;
  logic [5:0] v111;
  logic [5:0] v112;
  logic [5:0] v113;
  logic [5:0] v114;
  logic [5:0] v115;
  logic [5:0] v116;
  logic [5:0] v117;
  logic [5:0] v118;
  logic [5:0] v119;
  logic [5:0] v120;
  logic [5:0] v121;
  logic [5:0] v122;
  logic [5:0] v123;
  logic [5:0] v124;
  logic [5:0] v125;
  logic [5:0] v126;
  logic [5:0] v127;
  logic [5:0] v128;
  logic [5:0] v129;
  logic [5:0] v130;
  logic [5:0] v131;
  logic [5:0] v132;
  logic [5:0] v133;
  logic [5:0] v134;
  logic [5:0] v135;
  logic [5:0] v136;
  logic [5:0] v137;
  logic [5:0] v138;
  logic [5:0] v139;
  logic [5:0] v140;
  logic [5:0] v141;
  logic [5:0] v142;
  logic [5:0] v143;
  logic [5:0] v144;
  logic [5:0] v145;
  logic [5:0] v146;
  logic [5:0] v147;
  logic [5:0] v148;
  logic [5:0] v149;
  logic [5:0] v150;
  logic [5:0] v151;
  logic [5:0] v152;
  logic [5:0] v153;
  logic [5:0] v154;
  logic [5:0] v155;
  logic [5:0] v156;
  logic v157;
  logic [3:0] v158;
  logic v159;
  logic v160;
  logic [49:0] v161;
  logic [2:0] v162;
  logic v163;
  logic v164;
  logic v165;
  logic v166;
  logic v167;
  logic v168;
  logic v169;
  logic v170;
  logic v171;
  logic v172;
  logic v173;
  logic v174;
  logic v175;
  logic v176;
  logic v177;
  logic v178;
  logic [3:0] v179;
  logic [1:0] v180;
  logic [1:0] v181;
  logic [4:0] v182;
  logic v183;
  logic v184;
  logic [63:0] v185;
  logic v186;
  logic v187;
  logic [3:0] v188;
  logic [2:0] v189;
  logic [1:0] v190;
  logic [3:0] v191;
  logic [47:0] v192;
  logic v193;
  logic v194;
  logic [7:0] v195;
  logic [63:0] v196;
  logic v197;
  logic v198;
  logic [63:0] v199;
  logic [4:0] v200;
  logic v201;
  logic v202;
  logic [2:0] v203;
  logic [47:0] v204;
  logic v205;
  logic v206;
  logic v207;
  logic v208;
  logic v209;
  logic [3:0] v210;
  logic [2:0] v211;
  logic [2:0] v212;
  logic [3:0] v213;
  logic [47:0] v214;
  logic [4:0] v215;
  logic [31:0] v216;
  logic [255:0] v217;
  logic v218;
  logic v219;
  logic v220;
  logic [3:0] v221;
  logic [2:0] v222;
  logic [2:0] v223;
  logic [3:0] v224;
  logic [47:0] v225;
  logic [1:0] v226;
  logic [4:0] v227;
  logic v228;
  logic [31:0] v229;
  logic [255:0] v230;
  logic v231;
  logic v232;
  logic v233;
  logic [3:0] v234;
  logic [2:0] v235;
  logic [2:0] v236;
  logic [5:0] v237;
  logic [47:0] v238;
  logic [1:0] v239;
  logic [43:0] v240;
  logic [4:0] v241;
  logic v242;
  logic v243;
  logic [31:0] v244;
  logic [255:0] v245;
  logic v246;
  logic v247;
  logic v248;
  logic [2:0] v249;
  logic [2:0] v250;
  logic [2:0] v251;
  logic [5:0] v252;
  logic [47:0] v253;
  logic [1:0] v254;
  logic [43:0] v255;
  logic [4:0] v256;
  logic v257;
  logic v258;
  logic [255:0] v259;
  logic v260;
  logic v261;
  logic v262;
  logic [9:0] v263;
  logic v264;
  logic v265;
  logic v266;
  logic v267;
  logic v268;
  logic v269;
  logic v270;
  logic v271;
  logic [47:0] v272;
  logic v273;
  logic [47:0] v274;
  logic v275;
  logic [47:0] v276;
  logic [47:0] v277;
  logic [63:0] v278;
  logic v279;
  logic [11:0] v280;
  logic v281;
  logic v282;
  logic v283;
  logic v284;
  logic [2:0] v285;
  logic [63:0] v286;
  logic [63:0] v287;
  logic [49:0] v288;
  logic v289;
  logic [49:0] v290;
  logic [3:0] v291;
  logic [6:0] v292;
  logic v293;
  logic v294;
  logic [49:0] v295;
  logic [3:0] v296;
  logic [6:0] v297;
  logic v298;
  logic v299;
  logic [49:0] v300;
  logic [3:0] v301;
  logic [6:0] v302;
  logic v303;
  logic v304;
  logic v305;
  logic v306;
  logic [35:0] v307;
  logic v308;
  logic v309;
  logic [63:0] v310;
  logic v311;
  logic v312;
  logic v313;
  logic v314;
  logic v315;
  logic v316;
  logic v317;
  logic v318;
  logic v319;
  logic [72:0] v320;
  logic v321;
  logic v322;
  logic [421:0] v323;
  logic v324;
  logic v325;
  logic [114:0] v326;
  logic [10:0] v327;
  logic v328;
  logic v329;
  logic v330;
  logic v331;
  logic [9:0] v332;
  logic v333;
  logic [47:0] v334;
  logic [1:0] v335;
  logic v336;
  logic v337;
  logic v338;
  logic v339;
  logic v340;
  logic v341;
  logic v342;
  logic v343;
  logic v344;
  logic v345;
  logic v346;
  logic v347;
  logic v348;
  logic v349;
  logic v350;
  logic v351;
  logic v352;
  logic v353;
  logic v354;
  logic v355;
  always @(posedge tb.clock) begin
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_a_ready !== tb.u_i_XSTile.core.auto_memBlock_inner_buffers_out_a_ready) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_buffers_out_a_ready g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_a_ready, tb.u_i_XSTile.core.auto_memBlock_inner_buffers_out_a_ready); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_a_ready !== v0) tog[0] = 1'b1; v0 = tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_a_ready;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_valid !== tb.u_i_XSTile.core.auto_memBlock_inner_buffers_out_d_valid) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_buffers_out_d_valid g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_valid, tb.u_i_XSTile.core.auto_memBlock_inner_buffers_out_d_valid); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_valid !== v1) tog[1] = 1'b1; v1 = tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_valid;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_opcode !== tb.u_i_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_opcode) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_buffers_out_d_bits_opcode g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_opcode, tb.u_i_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_opcode); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_opcode !== v2) tog[2] = 1'b1; v2 = tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_opcode;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_param !== tb.u_i_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_param) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_buffers_out_d_bits_param g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_param, tb.u_i_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_param); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_param !== v3) tog[3] = 1'b1; v3 = tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_param;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_size !== tb.u_i_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_size) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_buffers_out_d_bits_size g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_size, tb.u_i_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_size); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_size !== v4) tog[4] = 1'b1; v4 = tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_size;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_source !== tb.u_i_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_source) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_buffers_out_d_bits_source g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_source, tb.u_i_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_source); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_source !== v5) tog[5] = 1'b1; v5 = tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_source;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_sink !== tb.u_i_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_sink) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_buffers_out_d_bits_sink g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_sink, tb.u_i_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_sink); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_sink !== v6) tog[6] = 1'b1; v6 = tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_sink;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_denied !== tb.u_i_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_denied) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_buffers_out_d_bits_denied g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_denied, tb.u_i_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_denied); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_denied !== v7) tog[7] = 1'b1; v7 = tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_denied;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_data !== tb.u_i_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_data) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_buffers_out_d_bits_data g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_data, tb.u_i_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_data); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_data !== v8) tog[8] = 1'b1; v8 = tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_data;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_corrupt !== tb.u_i_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_corrupt) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_buffers_out_d_bits_corrupt g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_corrupt, tb.u_i_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_corrupt); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_corrupt !== v9) tog[9] = 1'b1; v9 = tb.u_g_XSTile.core.auto_memBlock_inner_buffers_out_d_bits_corrupt;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_a_ready !== tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_a_ready) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_frontendBridge_instr_uncache_out_a_ready g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_a_ready, tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_a_ready); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_a_ready !== v10) tog[10] = 1'b1; v10 = tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_a_ready;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_valid !== tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_valid) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_valid g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_valid, tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_valid); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_valid !== v11) tog[11] = 1'b1; v11 = tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_valid;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_opcode !== tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_opcode) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_opcode g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_opcode, tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_opcode); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_opcode !== v12) tog[12] = 1'b1; v12 = tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_opcode;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_param !== tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_param) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_param g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_param, tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_param); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_param !== v13) tog[13] = 1'b1; v13 = tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_param;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_size !== tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_size) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_size g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_size, tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_size); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_size !== v14) tog[14] = 1'b1; v14 = tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_size;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_source !== tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_source) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_source g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_source, tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_source); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_source !== v15) tog[15] = 1'b1; v15 = tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_source;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_sink !== tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_sink) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_sink g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_sink, tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_sink); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_sink !== v16) tog[16] = 1'b1; v16 = tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_sink;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_denied !== tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_denied) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_denied g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_denied, tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_denied); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_denied !== v17) tog[17] = 1'b1; v17 = tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_denied;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_data !== tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_data) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_data g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_data, tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_data); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_data !== v18) tog[18] = 1'b1; v18 = tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_data;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_corrupt !== tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_corrupt) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_corrupt g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_corrupt, tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_corrupt); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_corrupt !== v19) tog[19] = 1'b1; v19 = tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_corrupt;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_valid !== tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_valid) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_valid g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_valid, tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_valid); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_valid !== v20) tog[20] = 1'b1; v20 = tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_valid;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_opcode !== tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_opcode) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_opcode g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_opcode, tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_opcode); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_opcode !== v21) tog[21] = 1'b1; v21 = tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_opcode;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_param !== tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_param) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_param g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_param, tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_param); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_param !== v22) tog[22] = 1'b1; v22 = tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_param;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_size !== tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_size) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_size g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_size, tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_size); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_size !== v23) tog[23] = 1'b1; v23 = tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_size;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_source !== tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_source) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_source g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_source, tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_source); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_source !== v24) tog[24] = 1'b1; v24 = tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_source;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_address !== tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_address) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_address g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_address, tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_address); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_address !== v25) tog[25] = 1'b1; v25 = tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_address;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_mask !== tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_mask) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_mask g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_mask, tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_mask); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_mask !== v26) tog[26] = 1'b1; v26 = tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_mask;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_data !== tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_data) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_data g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_data, tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_data); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_data !== v27) tog[27] = 1'b1; v27 = tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_data;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_corrupt !== tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_corrupt) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_corrupt g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_corrupt, tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_corrupt); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_corrupt !== v28) tog[28] = 1'b1; v28 = tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_corrupt;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_d_ready !== tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_d_ready) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_frontendBridge_icachectrl_in_d_ready g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_d_ready, tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_d_ready); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_d_ready !== v29) tog[29] = 1'b1; v29 = tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icachectrl_in_d_ready;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_a_ready !== tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_a_ready) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_frontendBridge_icache_out_a_ready g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_a_ready, tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_a_ready); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_a_ready !== v30) tog[30] = 1'b1; v30 = tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_a_ready;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_valid !== tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_valid) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_frontendBridge_icache_out_d_valid g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_valid, tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_valid); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_valid !== v31) tog[31] = 1'b1; v31 = tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_valid;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_opcode !== tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_opcode) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_opcode g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_opcode, tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_opcode); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_opcode !== v32) tog[32] = 1'b1; v32 = tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_opcode;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_param !== tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_param) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_param g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_param, tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_param); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_param !== v33) tog[33] = 1'b1; v33 = tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_param;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_size !== tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_size) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_size g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_size, tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_size); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_size !== v34) tog[34] = 1'b1; v34 = tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_size;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_source !== tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_source) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_source g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_source, tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_source); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_source !== v35) tog[35] = 1'b1; v35 = tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_source;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_sink !== tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_sink) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_sink g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_sink, tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_sink); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_sink !== v36) tog[36] = 1'b1; v36 = tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_sink;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_denied !== tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_denied) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_denied g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_denied, tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_denied); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_denied !== v37) tog[37] = 1'b1; v37 = tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_denied;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_data !== tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_data) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_data g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_data, tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_data); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_data !== v38) tog[38] = 1'b1; v38 = tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_data;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_corrupt !== tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_corrupt) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_corrupt g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_corrupt, tb.u_i_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_corrupt); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_corrupt !== v39) tog[39] = 1'b1; v39 = tb.u_g_XSTile.core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_corrupt;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_a_ready !== tb.u_i_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_a_ready) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_ptw_to_l2_buffer_out_a_ready g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_a_ready, tb.u_i_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_a_ready); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_a_ready !== v40) tog[40] = 1'b1; v40 = tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_a_ready;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_valid !== tb.u_i_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_valid) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_valid g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_valid, tb.u_i_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_valid); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_valid !== v41) tog[41] = 1'b1; v41 = tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_valid;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_opcode !== tb.u_i_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_opcode) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_opcode g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_opcode, tb.u_i_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_opcode); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_opcode !== v42) tog[42] = 1'b1; v42 = tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_opcode;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_param !== tb.u_i_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_param) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_param g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_param, tb.u_i_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_param); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_param !== v43) tog[43] = 1'b1; v43 = tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_param;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_size !== tb.u_i_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_size) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_size g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_size, tb.u_i_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_size); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_size !== v44) tog[44] = 1'b1; v44 = tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_size;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_source !== tb.u_i_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_source) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_source g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_source, tb.u_i_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_source); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_source !== v45) tog[45] = 1'b1; v45 = tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_source;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_sink !== tb.u_i_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_sink) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_sink g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_sink, tb.u_i_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_sink); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_sink !== v46) tog[46] = 1'b1; v46 = tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_sink;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_denied !== tb.u_i_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_denied) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_denied g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_denied, tb.u_i_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_denied); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_denied !== v47) tog[47] = 1'b1; v47 = tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_denied;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_data !== tb.u_i_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_data) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_data g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_data, tb.u_i_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_data); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_data !== v48) tog[48] = 1'b1; v48 = tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_data;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_corrupt !== tb.u_i_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_corrupt) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_corrupt g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_corrupt, tb.u_i_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_corrupt); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_corrupt !== v49) tog[49] = 1'b1; v49 = tb.u_g_XSTile.core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_corrupt;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_beu_local_int_sink_in_0 !== tb.u_i_XSTile.core.auto_memBlock_inner_beu_local_int_sink_in_0) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_beu_local_int_sink_in_0 g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_beu_local_int_sink_in_0, tb.u_i_XSTile.core.auto_memBlock_inner_beu_local_int_sink_in_0); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_beu_local_int_sink_in_0 !== v50) tog[50] = 1'b1; v50 = tb.u_g_XSTile.core.auto_memBlock_inner_beu_local_int_sink_in_0;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_nmi_int_sink_in_0 !== tb.u_i_XSTile.core.auto_memBlock_inner_nmi_int_sink_in_0) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_nmi_int_sink_in_0 g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_nmi_int_sink_in_0, tb.u_i_XSTile.core.auto_memBlock_inner_nmi_int_sink_in_0); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_nmi_int_sink_in_0 !== v51) tog[51] = 1'b1; v51 = tb.u_g_XSTile.core.auto_memBlock_inner_nmi_int_sink_in_0;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_nmi_int_sink_in_1 !== tb.u_i_XSTile.core.auto_memBlock_inner_nmi_int_sink_in_1) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_nmi_int_sink_in_1 g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_nmi_int_sink_in_1, tb.u_i_XSTile.core.auto_memBlock_inner_nmi_int_sink_in_1); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_nmi_int_sink_in_1 !== v52) tog[52] = 1'b1; v52 = tb.u_g_XSTile.core.auto_memBlock_inner_nmi_int_sink_in_1;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_plic_int_sink_in_1_0 !== tb.u_i_XSTile.core.auto_memBlock_inner_plic_int_sink_in_1_0) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_plic_int_sink_in_1_0 g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_plic_int_sink_in_1_0, tb.u_i_XSTile.core.auto_memBlock_inner_plic_int_sink_in_1_0); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_plic_int_sink_in_1_0 !== v53) tog[53] = 1'b1; v53 = tb.u_g_XSTile.core.auto_memBlock_inner_plic_int_sink_in_1_0;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_plic_int_sink_in_0_0 !== tb.u_i_XSTile.core.auto_memBlock_inner_plic_int_sink_in_0_0) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_plic_int_sink_in_0_0 g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_plic_int_sink_in_0_0, tb.u_i_XSTile.core.auto_memBlock_inner_plic_int_sink_in_0_0); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_plic_int_sink_in_0_0 !== v54) tog[54] = 1'b1; v54 = tb.u_g_XSTile.core.auto_memBlock_inner_plic_int_sink_in_0_0;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_debug_int_sink_in_0 !== tb.u_i_XSTile.core.auto_memBlock_inner_debug_int_sink_in_0) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_debug_int_sink_in_0 g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_debug_int_sink_in_0, tb.u_i_XSTile.core.auto_memBlock_inner_debug_int_sink_in_0); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_debug_int_sink_in_0 !== v55) tog[55] = 1'b1; v55 = tb.u_g_XSTile.core.auto_memBlock_inner_debug_int_sink_in_0;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_clint_int_sink_in_0 !== tb.u_i_XSTile.core.auto_memBlock_inner_clint_int_sink_in_0) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_clint_int_sink_in_0 g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_clint_int_sink_in_0, tb.u_i_XSTile.core.auto_memBlock_inner_clint_int_sink_in_0); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_clint_int_sink_in_0 !== v56) tog[56] = 1'b1; v56 = tb.u_g_XSTile.core.auto_memBlock_inner_clint_int_sink_in_0;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_clint_int_sink_in_1 !== tb.u_i_XSTile.core.auto_memBlock_inner_clint_int_sink_in_1) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_clint_int_sink_in_1 g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_clint_int_sink_in_1, tb.u_i_XSTile.core.auto_memBlock_inner_clint_int_sink_in_1); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_clint_int_sink_in_1 !== v57) tog[57] = 1'b1; v57 = tb.u_g_XSTile.core.auto_memBlock_inner_clint_int_sink_in_1;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_a_ready !== tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_a_ready) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_dcache_client_out_a_ready g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_a_ready, tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_a_ready); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_a_ready !== v58) tog[58] = 1'b1; v58 = tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_a_ready;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_valid !== tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_b_valid) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_dcache_client_out_b_valid g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_valid, tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_b_valid); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_valid !== v59) tog[59] = 1'b1; v59 = tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_valid;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_opcode !== tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_opcode) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_dcache_client_out_b_bits_opcode g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_opcode, tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_opcode); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_opcode !== v60) tog[60] = 1'b1; v60 = tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_opcode;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_param !== tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_param) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_dcache_client_out_b_bits_param g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_param, tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_param); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_param !== v61) tog[61] = 1'b1; v61 = tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_param;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_size !== tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_size) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_dcache_client_out_b_bits_size g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_size, tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_size); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_size !== v62) tog[62] = 1'b1; v62 = tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_size;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_source !== tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_source) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_dcache_client_out_b_bits_source g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_source, tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_source); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_source !== v63) tog[63] = 1'b1; v63 = tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_source;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_address !== tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_address) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_dcache_client_out_b_bits_address g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_address, tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_address); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_address !== v64) tog[64] = 1'b1; v64 = tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_address;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_mask !== tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_mask) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_dcache_client_out_b_bits_mask g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_mask, tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_mask); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_mask !== v65) tog[65] = 1'b1; v65 = tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_mask;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_data !== tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_data) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_dcache_client_out_b_bits_data g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_data, tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_data); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_data !== v66) tog[66] = 1'b1; v66 = tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_data;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_corrupt !== tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_corrupt) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_dcache_client_out_b_bits_corrupt g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_corrupt, tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_corrupt); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_corrupt !== v67) tog[67] = 1'b1; v67 = tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_b_bits_corrupt;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_c_ready !== tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_c_ready) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_dcache_client_out_c_ready g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_c_ready, tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_c_ready); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_c_ready !== v68) tog[68] = 1'b1; v68 = tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_c_ready;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_valid !== tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_d_valid) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_dcache_client_out_d_valid g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_valid, tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_d_valid); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_valid !== v69) tog[69] = 1'b1; v69 = tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_valid;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_opcode !== tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_opcode) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_dcache_client_out_d_bits_opcode g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_opcode, tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_opcode); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_opcode !== v70) tog[70] = 1'b1; v70 = tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_opcode;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_param !== tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_param) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_dcache_client_out_d_bits_param g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_param, tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_param); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_param !== v71) tog[71] = 1'b1; v71 = tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_param;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_size !== tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_size) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_dcache_client_out_d_bits_size g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_size, tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_size); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_size !== v72) tog[72] = 1'b1; v72 = tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_size;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_source !== tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_source) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_dcache_client_out_d_bits_source g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_source, tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_source); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_source !== v73) tog[73] = 1'b1; v73 = tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_source;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_sink !== tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_sink) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_dcache_client_out_d_bits_sink g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_sink, tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_sink); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_sink !== v74) tog[74] = 1'b1; v74 = tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_sink;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_denied !== tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_denied) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_dcache_client_out_d_bits_denied g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_denied, tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_denied); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_denied !== v75) tog[75] = 1'b1; v75 = tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_denied;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_echo_isKeyword !== tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_echo_isKeyword) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_dcache_client_out_d_bits_echo_isKeyword g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_echo_isKeyword, tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_echo_isKeyword); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_echo_isKeyword !== v76) tog[76] = 1'b1; v76 = tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_echo_isKeyword;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_data !== tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_data) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_dcache_client_out_d_bits_data g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_data, tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_data); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_data !== v77) tog[77] = 1'b1; v77 = tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_data;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_corrupt !== tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_corrupt) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_dcache_client_out_d_bits_corrupt g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_corrupt, tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_corrupt); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_corrupt !== v78) tog[78] = 1'b1; v78 = tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_d_bits_corrupt;
    pin_checks++; if (tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_e_ready !== tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_e_ready) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.auto_memBlock_inner_dcache_client_out_e_ready g=%h i=%h", $time, tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_e_ready, tb.u_i_XSTile.core.auto_memBlock_inner_dcache_client_out_e_ready); end
    if (armed && tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_e_ready !== v79) tog[79] = 1'b1; v79 = tb.u_g_XSTile.core.auto_memBlock_inner_dcache_client_out_e_ready;
    pin_checks++; if (tb.u_g_XSTile.core.io_hartId !== tb.u_i_XSTile.core.io_hartId) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_hartId g=%h i=%h", $time, tb.u_g_XSTile.core.io_hartId, tb.u_i_XSTile.core.io_hartId); end
    if (armed && tb.u_g_XSTile.core.io_hartId !== v80) tog[80] = 1'b1; v80 = tb.u_g_XSTile.core.io_hartId;
    pin_checks++; if (tb.u_g_XSTile.core.io_msiInfo_valid !== tb.u_i_XSTile.core.io_msiInfo_valid) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_msiInfo_valid g=%h i=%h", $time, tb.u_g_XSTile.core.io_msiInfo_valid, tb.u_i_XSTile.core.io_msiInfo_valid); end
    if (armed && tb.u_g_XSTile.core.io_msiInfo_valid !== v81) tog[81] = 1'b1; v81 = tb.u_g_XSTile.core.io_msiInfo_valid;
    pin_checks++; if (tb.u_g_XSTile.core.io_msiInfo_bits !== tb.u_i_XSTile.core.io_msiInfo_bits) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_msiInfo_bits g=%h i=%h", $time, tb.u_g_XSTile.core.io_msiInfo_bits, tb.u_i_XSTile.core.io_msiInfo_bits); end
    if (armed && tb.u_g_XSTile.core.io_msiInfo_bits !== v82) tog[82] = 1'b1; v82 = tb.u_g_XSTile.core.io_msiInfo_bits;
    pin_checks++; if (tb.u_g_XSTile.core.io_clintTime_valid !== tb.u_i_XSTile.core.io_clintTime_valid) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_clintTime_valid g=%h i=%h", $time, tb.u_g_XSTile.core.io_clintTime_valid, tb.u_i_XSTile.core.io_clintTime_valid); end
    if (armed && tb.u_g_XSTile.core.io_clintTime_valid !== v83) tog[83] = 1'b1; v83 = tb.u_g_XSTile.core.io_clintTime_valid;
    pin_checks++; if (tb.u_g_XSTile.core.io_clintTime_bits !== tb.u_i_XSTile.core.io_clintTime_bits) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_clintTime_bits g=%h i=%h", $time, tb.u_g_XSTile.core.io_clintTime_bits, tb.u_i_XSTile.core.io_clintTime_bits); end
    if (armed && tb.u_g_XSTile.core.io_clintTime_bits !== v84) tog[84] = 1'b1; v84 = tb.u_g_XSTile.core.io_clintTime_bits;
    pin_checks++; if (tb.u_g_XSTile.core.io_reset_vector !== tb.u_i_XSTile.core.io_reset_vector) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_reset_vector g=%h i=%h", $time, tb.u_g_XSTile.core.io_reset_vector, tb.u_i_XSTile.core.io_reset_vector); end
    if (armed && tb.u_g_XSTile.core.io_reset_vector !== v85) tog[85] = 1'b1; v85 = tb.u_g_XSTile.core.io_reset_vector;
    pin_checks++; if (tb.u_g_XSTile.core.io_l2_flush_done !== tb.u_i_XSTile.core.io_l2_flush_done) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_l2_flush_done g=%h i=%h", $time, tb.u_g_XSTile.core.io_l2_flush_done, tb.u_i_XSTile.core.io_l2_flush_done); end
    if (armed && tb.u_g_XSTile.core.io_l2_flush_done !== v86) tog[86] = 1'b1; v86 = tb.u_g_XSTile.core.io_l2_flush_done;
    pin_checks++; if (tb.u_g_XSTile.core.io_traceCoreInterface_fromEncoder_enable !== tb.u_i_XSTile.core.io_traceCoreInterface_fromEncoder_enable) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_traceCoreInterface_fromEncoder_enable g=%h i=%h", $time, tb.u_g_XSTile.core.io_traceCoreInterface_fromEncoder_enable, tb.u_i_XSTile.core.io_traceCoreInterface_fromEncoder_enable); end
    if (armed && tb.u_g_XSTile.core.io_traceCoreInterface_fromEncoder_enable !== v87) tog[87] = 1'b1; v87 = tb.u_g_XSTile.core.io_traceCoreInterface_fromEncoder_enable;
    pin_checks++; if (tb.u_g_XSTile.core.io_traceCoreInterface_fromEncoder_stall !== tb.u_i_XSTile.core.io_traceCoreInterface_fromEncoder_stall) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_traceCoreInterface_fromEncoder_stall g=%h i=%h", $time, tb.u_g_XSTile.core.io_traceCoreInterface_fromEncoder_stall, tb.u_i_XSTile.core.io_traceCoreInterface_fromEncoder_stall); end
    if (armed && tb.u_g_XSTile.core.io_traceCoreInterface_fromEncoder_stall !== v88) tog[88] = 1'b1; v88 = tb.u_g_XSTile.core.io_traceCoreInterface_fromEncoder_stall;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_1_value !== tb.u_i_XSTile.core.io_perfEvents_1_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_1_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_1_value, tb.u_i_XSTile.core.io_perfEvents_1_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_1_value !== v89) tog[89] = 1'b1; v89 = tb.u_g_XSTile.core.io_perfEvents_1_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_2_value !== tb.u_i_XSTile.core.io_perfEvents_2_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_2_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_2_value, tb.u_i_XSTile.core.io_perfEvents_2_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_2_value !== v90) tog[90] = 1'b1; v90 = tb.u_g_XSTile.core.io_perfEvents_2_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_3_value !== tb.u_i_XSTile.core.io_perfEvents_3_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_3_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_3_value, tb.u_i_XSTile.core.io_perfEvents_3_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_3_value !== v91) tog[91] = 1'b1; v91 = tb.u_g_XSTile.core.io_perfEvents_3_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_4_value !== tb.u_i_XSTile.core.io_perfEvents_4_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_4_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_4_value, tb.u_i_XSTile.core.io_perfEvents_4_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_4_value !== v92) tog[92] = 1'b1; v92 = tb.u_g_XSTile.core.io_perfEvents_4_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_5_value !== tb.u_i_XSTile.core.io_perfEvents_5_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_5_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_5_value, tb.u_i_XSTile.core.io_perfEvents_5_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_5_value !== v93) tog[93] = 1'b1; v93 = tb.u_g_XSTile.core.io_perfEvents_5_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_6_value !== tb.u_i_XSTile.core.io_perfEvents_6_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_6_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_6_value, tb.u_i_XSTile.core.io_perfEvents_6_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_6_value !== v94) tog[94] = 1'b1; v94 = tb.u_g_XSTile.core.io_perfEvents_6_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_7_value !== tb.u_i_XSTile.core.io_perfEvents_7_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_7_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_7_value, tb.u_i_XSTile.core.io_perfEvents_7_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_7_value !== v95) tog[95] = 1'b1; v95 = tb.u_g_XSTile.core.io_perfEvents_7_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_8_value !== tb.u_i_XSTile.core.io_perfEvents_8_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_8_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_8_value, tb.u_i_XSTile.core.io_perfEvents_8_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_8_value !== v96) tog[96] = 1'b1; v96 = tb.u_g_XSTile.core.io_perfEvents_8_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_9_value !== tb.u_i_XSTile.core.io_perfEvents_9_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_9_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_9_value, tb.u_i_XSTile.core.io_perfEvents_9_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_9_value !== v97) tog[97] = 1'b1; v97 = tb.u_g_XSTile.core.io_perfEvents_9_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_10_value !== tb.u_i_XSTile.core.io_perfEvents_10_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_10_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_10_value, tb.u_i_XSTile.core.io_perfEvents_10_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_10_value !== v98) tog[98] = 1'b1; v98 = tb.u_g_XSTile.core.io_perfEvents_10_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_11_value !== tb.u_i_XSTile.core.io_perfEvents_11_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_11_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_11_value, tb.u_i_XSTile.core.io_perfEvents_11_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_11_value !== v99) tog[99] = 1'b1; v99 = tb.u_g_XSTile.core.io_perfEvents_11_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_12_value !== tb.u_i_XSTile.core.io_perfEvents_12_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_12_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_12_value, tb.u_i_XSTile.core.io_perfEvents_12_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_12_value !== v100) tog[100] = 1'b1; v100 = tb.u_g_XSTile.core.io_perfEvents_12_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_13_value !== tb.u_i_XSTile.core.io_perfEvents_13_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_13_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_13_value, tb.u_i_XSTile.core.io_perfEvents_13_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_13_value !== v101) tog[101] = 1'b1; v101 = tb.u_g_XSTile.core.io_perfEvents_13_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_14_value !== tb.u_i_XSTile.core.io_perfEvents_14_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_14_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_14_value, tb.u_i_XSTile.core.io_perfEvents_14_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_14_value !== v102) tog[102] = 1'b1; v102 = tb.u_g_XSTile.core.io_perfEvents_14_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_15_value !== tb.u_i_XSTile.core.io_perfEvents_15_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_15_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_15_value, tb.u_i_XSTile.core.io_perfEvents_15_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_15_value !== v103) tog[103] = 1'b1; v103 = tb.u_g_XSTile.core.io_perfEvents_15_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_16_value !== tb.u_i_XSTile.core.io_perfEvents_16_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_16_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_16_value, tb.u_i_XSTile.core.io_perfEvents_16_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_16_value !== v104) tog[104] = 1'b1; v104 = tb.u_g_XSTile.core.io_perfEvents_16_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_17_value !== tb.u_i_XSTile.core.io_perfEvents_17_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_17_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_17_value, tb.u_i_XSTile.core.io_perfEvents_17_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_17_value !== v105) tog[105] = 1'b1; v105 = tb.u_g_XSTile.core.io_perfEvents_17_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_18_value !== tb.u_i_XSTile.core.io_perfEvents_18_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_18_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_18_value, tb.u_i_XSTile.core.io_perfEvents_18_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_18_value !== v106) tog[106] = 1'b1; v106 = tb.u_g_XSTile.core.io_perfEvents_18_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_19_value !== tb.u_i_XSTile.core.io_perfEvents_19_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_19_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_19_value, tb.u_i_XSTile.core.io_perfEvents_19_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_19_value !== v107) tog[107] = 1'b1; v107 = tb.u_g_XSTile.core.io_perfEvents_19_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_20_value !== tb.u_i_XSTile.core.io_perfEvents_20_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_20_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_20_value, tb.u_i_XSTile.core.io_perfEvents_20_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_20_value !== v108) tog[108] = 1'b1; v108 = tb.u_g_XSTile.core.io_perfEvents_20_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_21_value !== tb.u_i_XSTile.core.io_perfEvents_21_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_21_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_21_value, tb.u_i_XSTile.core.io_perfEvents_21_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_21_value !== v109) tog[109] = 1'b1; v109 = tb.u_g_XSTile.core.io_perfEvents_21_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_22_value !== tb.u_i_XSTile.core.io_perfEvents_22_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_22_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_22_value, tb.u_i_XSTile.core.io_perfEvents_22_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_22_value !== v110) tog[110] = 1'b1; v110 = tb.u_g_XSTile.core.io_perfEvents_22_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_23_value !== tb.u_i_XSTile.core.io_perfEvents_23_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_23_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_23_value, tb.u_i_XSTile.core.io_perfEvents_23_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_23_value !== v111) tog[111] = 1'b1; v111 = tb.u_g_XSTile.core.io_perfEvents_23_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_24_value !== tb.u_i_XSTile.core.io_perfEvents_24_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_24_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_24_value, tb.u_i_XSTile.core.io_perfEvents_24_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_24_value !== v112) tog[112] = 1'b1; v112 = tb.u_g_XSTile.core.io_perfEvents_24_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_25_value !== tb.u_i_XSTile.core.io_perfEvents_25_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_25_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_25_value, tb.u_i_XSTile.core.io_perfEvents_25_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_25_value !== v113) tog[113] = 1'b1; v113 = tb.u_g_XSTile.core.io_perfEvents_25_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_26_value !== tb.u_i_XSTile.core.io_perfEvents_26_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_26_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_26_value, tb.u_i_XSTile.core.io_perfEvents_26_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_26_value !== v114) tog[114] = 1'b1; v114 = tb.u_g_XSTile.core.io_perfEvents_26_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_27_value !== tb.u_i_XSTile.core.io_perfEvents_27_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_27_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_27_value, tb.u_i_XSTile.core.io_perfEvents_27_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_27_value !== v115) tog[115] = 1'b1; v115 = tb.u_g_XSTile.core.io_perfEvents_27_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_28_value !== tb.u_i_XSTile.core.io_perfEvents_28_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_28_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_28_value, tb.u_i_XSTile.core.io_perfEvents_28_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_28_value !== v116) tog[116] = 1'b1; v116 = tb.u_g_XSTile.core.io_perfEvents_28_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_29_value !== tb.u_i_XSTile.core.io_perfEvents_29_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_29_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_29_value, tb.u_i_XSTile.core.io_perfEvents_29_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_29_value !== v117) tog[117] = 1'b1; v117 = tb.u_g_XSTile.core.io_perfEvents_29_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_30_value !== tb.u_i_XSTile.core.io_perfEvents_30_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_30_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_30_value, tb.u_i_XSTile.core.io_perfEvents_30_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_30_value !== v118) tog[118] = 1'b1; v118 = tb.u_g_XSTile.core.io_perfEvents_30_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_31_value !== tb.u_i_XSTile.core.io_perfEvents_31_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_31_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_31_value, tb.u_i_XSTile.core.io_perfEvents_31_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_31_value !== v119) tog[119] = 1'b1; v119 = tb.u_g_XSTile.core.io_perfEvents_31_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_32_value !== tb.u_i_XSTile.core.io_perfEvents_32_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_32_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_32_value, tb.u_i_XSTile.core.io_perfEvents_32_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_32_value !== v120) tog[120] = 1'b1; v120 = tb.u_g_XSTile.core.io_perfEvents_32_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_33_value !== tb.u_i_XSTile.core.io_perfEvents_33_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_33_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_33_value, tb.u_i_XSTile.core.io_perfEvents_33_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_33_value !== v121) tog[121] = 1'b1; v121 = tb.u_g_XSTile.core.io_perfEvents_33_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_34_value !== tb.u_i_XSTile.core.io_perfEvents_34_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_34_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_34_value, tb.u_i_XSTile.core.io_perfEvents_34_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_34_value !== v122) tog[122] = 1'b1; v122 = tb.u_g_XSTile.core.io_perfEvents_34_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_35_value !== tb.u_i_XSTile.core.io_perfEvents_35_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_35_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_35_value, tb.u_i_XSTile.core.io_perfEvents_35_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_35_value !== v123) tog[123] = 1'b1; v123 = tb.u_g_XSTile.core.io_perfEvents_35_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_36_value !== tb.u_i_XSTile.core.io_perfEvents_36_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_36_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_36_value, tb.u_i_XSTile.core.io_perfEvents_36_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_36_value !== v124) tog[124] = 1'b1; v124 = tb.u_g_XSTile.core.io_perfEvents_36_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_37_value !== tb.u_i_XSTile.core.io_perfEvents_37_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_37_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_37_value, tb.u_i_XSTile.core.io_perfEvents_37_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_37_value !== v125) tog[125] = 1'b1; v125 = tb.u_g_XSTile.core.io_perfEvents_37_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_38_value !== tb.u_i_XSTile.core.io_perfEvents_38_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_38_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_38_value, tb.u_i_XSTile.core.io_perfEvents_38_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_38_value !== v126) tog[126] = 1'b1; v126 = tb.u_g_XSTile.core.io_perfEvents_38_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_39_value !== tb.u_i_XSTile.core.io_perfEvents_39_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_39_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_39_value, tb.u_i_XSTile.core.io_perfEvents_39_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_39_value !== v127) tog[127] = 1'b1; v127 = tb.u_g_XSTile.core.io_perfEvents_39_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_40_value !== tb.u_i_XSTile.core.io_perfEvents_40_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_40_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_40_value, tb.u_i_XSTile.core.io_perfEvents_40_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_40_value !== v128) tog[128] = 1'b1; v128 = tb.u_g_XSTile.core.io_perfEvents_40_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_41_value !== tb.u_i_XSTile.core.io_perfEvents_41_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_41_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_41_value, tb.u_i_XSTile.core.io_perfEvents_41_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_41_value !== v129) tog[129] = 1'b1; v129 = tb.u_g_XSTile.core.io_perfEvents_41_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_42_value !== tb.u_i_XSTile.core.io_perfEvents_42_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_42_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_42_value, tb.u_i_XSTile.core.io_perfEvents_42_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_42_value !== v130) tog[130] = 1'b1; v130 = tb.u_g_XSTile.core.io_perfEvents_42_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_43_value !== tb.u_i_XSTile.core.io_perfEvents_43_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_43_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_43_value, tb.u_i_XSTile.core.io_perfEvents_43_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_43_value !== v131) tog[131] = 1'b1; v131 = tb.u_g_XSTile.core.io_perfEvents_43_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_44_value !== tb.u_i_XSTile.core.io_perfEvents_44_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_44_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_44_value, tb.u_i_XSTile.core.io_perfEvents_44_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_44_value !== v132) tog[132] = 1'b1; v132 = tb.u_g_XSTile.core.io_perfEvents_44_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_45_value !== tb.u_i_XSTile.core.io_perfEvents_45_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_45_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_45_value, tb.u_i_XSTile.core.io_perfEvents_45_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_45_value !== v133) tog[133] = 1'b1; v133 = tb.u_g_XSTile.core.io_perfEvents_45_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_46_value !== tb.u_i_XSTile.core.io_perfEvents_46_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_46_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_46_value, tb.u_i_XSTile.core.io_perfEvents_46_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_46_value !== v134) tog[134] = 1'b1; v134 = tb.u_g_XSTile.core.io_perfEvents_46_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_47_value !== tb.u_i_XSTile.core.io_perfEvents_47_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_47_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_47_value, tb.u_i_XSTile.core.io_perfEvents_47_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_47_value !== v135) tog[135] = 1'b1; v135 = tb.u_g_XSTile.core.io_perfEvents_47_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_48_value !== tb.u_i_XSTile.core.io_perfEvents_48_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_48_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_48_value, tb.u_i_XSTile.core.io_perfEvents_48_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_48_value !== v136) tog[136] = 1'b1; v136 = tb.u_g_XSTile.core.io_perfEvents_48_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_49_value !== tb.u_i_XSTile.core.io_perfEvents_49_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_49_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_49_value, tb.u_i_XSTile.core.io_perfEvents_49_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_49_value !== v137) tog[137] = 1'b1; v137 = tb.u_g_XSTile.core.io_perfEvents_49_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_50_value !== tb.u_i_XSTile.core.io_perfEvents_50_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_50_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_50_value, tb.u_i_XSTile.core.io_perfEvents_50_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_50_value !== v138) tog[138] = 1'b1; v138 = tb.u_g_XSTile.core.io_perfEvents_50_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_51_value !== tb.u_i_XSTile.core.io_perfEvents_51_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_51_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_51_value, tb.u_i_XSTile.core.io_perfEvents_51_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_51_value !== v139) tog[139] = 1'b1; v139 = tb.u_g_XSTile.core.io_perfEvents_51_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_52_value !== tb.u_i_XSTile.core.io_perfEvents_52_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_52_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_52_value, tb.u_i_XSTile.core.io_perfEvents_52_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_52_value !== v140) tog[140] = 1'b1; v140 = tb.u_g_XSTile.core.io_perfEvents_52_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_53_value !== tb.u_i_XSTile.core.io_perfEvents_53_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_53_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_53_value, tb.u_i_XSTile.core.io_perfEvents_53_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_53_value !== v141) tog[141] = 1'b1; v141 = tb.u_g_XSTile.core.io_perfEvents_53_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_54_value !== tb.u_i_XSTile.core.io_perfEvents_54_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_54_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_54_value, tb.u_i_XSTile.core.io_perfEvents_54_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_54_value !== v142) tog[142] = 1'b1; v142 = tb.u_g_XSTile.core.io_perfEvents_54_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_55_value !== tb.u_i_XSTile.core.io_perfEvents_55_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_55_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_55_value, tb.u_i_XSTile.core.io_perfEvents_55_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_55_value !== v143) tog[143] = 1'b1; v143 = tb.u_g_XSTile.core.io_perfEvents_55_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_56_value !== tb.u_i_XSTile.core.io_perfEvents_56_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_56_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_56_value, tb.u_i_XSTile.core.io_perfEvents_56_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_56_value !== v144) tog[144] = 1'b1; v144 = tb.u_g_XSTile.core.io_perfEvents_56_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_57_value !== tb.u_i_XSTile.core.io_perfEvents_57_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_57_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_57_value, tb.u_i_XSTile.core.io_perfEvents_57_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_57_value !== v145) tog[145] = 1'b1; v145 = tb.u_g_XSTile.core.io_perfEvents_57_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_58_value !== tb.u_i_XSTile.core.io_perfEvents_58_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_58_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_58_value, tb.u_i_XSTile.core.io_perfEvents_58_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_58_value !== v146) tog[146] = 1'b1; v146 = tb.u_g_XSTile.core.io_perfEvents_58_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_59_value !== tb.u_i_XSTile.core.io_perfEvents_59_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_59_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_59_value, tb.u_i_XSTile.core.io_perfEvents_59_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_59_value !== v147) tog[147] = 1'b1; v147 = tb.u_g_XSTile.core.io_perfEvents_59_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_60_value !== tb.u_i_XSTile.core.io_perfEvents_60_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_60_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_60_value, tb.u_i_XSTile.core.io_perfEvents_60_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_60_value !== v148) tog[148] = 1'b1; v148 = tb.u_g_XSTile.core.io_perfEvents_60_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_61_value !== tb.u_i_XSTile.core.io_perfEvents_61_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_61_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_61_value, tb.u_i_XSTile.core.io_perfEvents_61_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_61_value !== v149) tog[149] = 1'b1; v149 = tb.u_g_XSTile.core.io_perfEvents_61_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_62_value !== tb.u_i_XSTile.core.io_perfEvents_62_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_62_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_62_value, tb.u_i_XSTile.core.io_perfEvents_62_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_62_value !== v150) tog[150] = 1'b1; v150 = tb.u_g_XSTile.core.io_perfEvents_62_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_63_value !== tb.u_i_XSTile.core.io_perfEvents_63_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_63_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_63_value, tb.u_i_XSTile.core.io_perfEvents_63_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_63_value !== v151) tog[151] = 1'b1; v151 = tb.u_g_XSTile.core.io_perfEvents_63_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_64_value !== tb.u_i_XSTile.core.io_perfEvents_64_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_64_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_64_value, tb.u_i_XSTile.core.io_perfEvents_64_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_64_value !== v152) tog[152] = 1'b1; v152 = tb.u_g_XSTile.core.io_perfEvents_64_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_65_value !== tb.u_i_XSTile.core.io_perfEvents_65_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_65_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_65_value, tb.u_i_XSTile.core.io_perfEvents_65_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_65_value !== v153) tog[153] = 1'b1; v153 = tb.u_g_XSTile.core.io_perfEvents_65_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_66_value !== tb.u_i_XSTile.core.io_perfEvents_66_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_66_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_66_value, tb.u_i_XSTile.core.io_perfEvents_66_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_66_value !== v154) tog[154] = 1'b1; v154 = tb.u_g_XSTile.core.io_perfEvents_66_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_67_value !== tb.u_i_XSTile.core.io_perfEvents_67_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_67_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_67_value, tb.u_i_XSTile.core.io_perfEvents_67_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_67_value !== v155) tog[155] = 1'b1; v155 = tb.u_g_XSTile.core.io_perfEvents_67_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_perfEvents_68_value !== tb.u_i_XSTile.core.io_perfEvents_68_value) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_perfEvents_68_value g=%h i=%h", $time, tb.u_g_XSTile.core.io_perfEvents_68_value, tb.u_i_XSTile.core.io_perfEvents_68_value); end
    if (armed && tb.u_g_XSTile.core.io_perfEvents_68_value !== v156) tog[156] = 1'b1; v156 = tb.u_g_XSTile.core.io_perfEvents_68_value;
    pin_checks++; if (tb.u_g_XSTile.core.io_l2_hint_valid !== tb.u_i_XSTile.core.io_l2_hint_valid) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_l2_hint_valid g=%h i=%h", $time, tb.u_g_XSTile.core.io_l2_hint_valid, tb.u_i_XSTile.core.io_l2_hint_valid); end
    if (armed && tb.u_g_XSTile.core.io_l2_hint_valid !== v157) tog[157] = 1'b1; v157 = tb.u_g_XSTile.core.io_l2_hint_valid;
    pin_checks++; if (tb.u_g_XSTile.core.io_l2_hint_bits_sourceId !== tb.u_i_XSTile.core.io_l2_hint_bits_sourceId) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_l2_hint_bits_sourceId g=%h i=%h", $time, tb.u_g_XSTile.core.io_l2_hint_bits_sourceId, tb.u_i_XSTile.core.io_l2_hint_bits_sourceId); end
    if (armed && tb.u_g_XSTile.core.io_l2_hint_bits_sourceId !== v158) tog[158] = 1'b1; v158 = tb.u_g_XSTile.core.io_l2_hint_bits_sourceId;
    pin_checks++; if (tb.u_g_XSTile.core.io_l2_hint_bits_isKeyword !== tb.u_i_XSTile.core.io_l2_hint_bits_isKeyword) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_l2_hint_bits_isKeyword g=%h i=%h", $time, tb.u_g_XSTile.core.io_l2_hint_bits_isKeyword, tb.u_i_XSTile.core.io_l2_hint_bits_isKeyword); end
    if (armed && tb.u_g_XSTile.core.io_l2_hint_bits_isKeyword !== v159) tog[159] = 1'b1; v159 = tb.u_g_XSTile.core.io_l2_hint_bits_isKeyword;
    pin_checks++; if (tb.u_g_XSTile.core.io_l2_tlb_req_req_valid !== tb.u_i_XSTile.core.io_l2_tlb_req_req_valid) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_l2_tlb_req_req_valid g=%h i=%h", $time, tb.u_g_XSTile.core.io_l2_tlb_req_req_valid, tb.u_i_XSTile.core.io_l2_tlb_req_req_valid); end
    if (armed && tb.u_g_XSTile.core.io_l2_tlb_req_req_valid !== v160) tog[160] = 1'b1; v160 = tb.u_g_XSTile.core.io_l2_tlb_req_req_valid;
    pin_checks++; if (tb.u_g_XSTile.core.io_l2_tlb_req_req_bits_vaddr !== tb.u_i_XSTile.core.io_l2_tlb_req_req_bits_vaddr) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_l2_tlb_req_req_bits_vaddr g=%h i=%h", $time, tb.u_g_XSTile.core.io_l2_tlb_req_req_bits_vaddr, tb.u_i_XSTile.core.io_l2_tlb_req_req_bits_vaddr); end
    if (armed && tb.u_g_XSTile.core.io_l2_tlb_req_req_bits_vaddr !== v161) tog[161] = 1'b1; v161 = tb.u_g_XSTile.core.io_l2_tlb_req_req_bits_vaddr;
    pin_checks++; if (tb.u_g_XSTile.core.io_l2_tlb_req_req_bits_cmd !== tb.u_i_XSTile.core.io_l2_tlb_req_req_bits_cmd) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_l2_tlb_req_req_bits_cmd g=%h i=%h", $time, tb.u_g_XSTile.core.io_l2_tlb_req_req_bits_cmd, tb.u_i_XSTile.core.io_l2_tlb_req_req_bits_cmd); end
    if (armed && tb.u_g_XSTile.core.io_l2_tlb_req_req_bits_cmd !== v162) tog[162] = 1'b1; v162 = tb.u_g_XSTile.core.io_l2_tlb_req_req_bits_cmd;
    pin_checks++; if (tb.u_g_XSTile.core.io_l2_tlb_req_req_bits_kill !== tb.u_i_XSTile.core.io_l2_tlb_req_req_bits_kill) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_l2_tlb_req_req_bits_kill g=%h i=%h", $time, tb.u_g_XSTile.core.io_l2_tlb_req_req_bits_kill, tb.u_i_XSTile.core.io_l2_tlb_req_req_bits_kill); end
    if (armed && tb.u_g_XSTile.core.io_l2_tlb_req_req_bits_kill !== v163) tog[163] = 1'b1; v163 = tb.u_g_XSTile.core.io_l2_tlb_req_req_bits_kill;
    pin_checks++; if (tb.u_g_XSTile.core.io_l2_tlb_req_req_bits_isPrefetch !== tb.u_i_XSTile.core.io_l2_tlb_req_req_bits_isPrefetch) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_l2_tlb_req_req_bits_isPrefetch g=%h i=%h", $time, tb.u_g_XSTile.core.io_l2_tlb_req_req_bits_isPrefetch, tb.u_i_XSTile.core.io_l2_tlb_req_req_bits_isPrefetch); end
    if (armed && tb.u_g_XSTile.core.io_l2_tlb_req_req_bits_isPrefetch !== v164) tog[164] = 1'b1; v164 = tb.u_g_XSTile.core.io_l2_tlb_req_req_bits_isPrefetch;
    pin_checks++; if (tb.u_g_XSTile.core.io_l2_tlb_req_req_bits_no_translate !== tb.u_i_XSTile.core.io_l2_tlb_req_req_bits_no_translate) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_l2_tlb_req_req_bits_no_translate g=%h i=%h", $time, tb.u_g_XSTile.core.io_l2_tlb_req_req_bits_no_translate, tb.u_i_XSTile.core.io_l2_tlb_req_req_bits_no_translate); end
    if (armed && tb.u_g_XSTile.core.io_l2_tlb_req_req_bits_no_translate !== v165) tog[165] = 1'b1; v165 = tb.u_g_XSTile.core.io_l2_tlb_req_req_bits_no_translate;
    pin_checks++; if (tb.u_g_XSTile.core.io_debugTopDown_l2MissMatch !== tb.u_i_XSTile.core.io_debugTopDown_l2MissMatch) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_debugTopDown_l2MissMatch g=%h i=%h", $time, tb.u_g_XSTile.core.io_debugTopDown_l2MissMatch, tb.u_i_XSTile.core.io_debugTopDown_l2MissMatch); end
    if (armed && tb.u_g_XSTile.core.io_debugTopDown_l2MissMatch !== v166) tog[166] = 1'b1; v166 = tb.u_g_XSTile.core.io_debugTopDown_l2MissMatch;
    pin_checks++; if (tb.u_g_XSTile.core.io_debugTopDown_l3MissMatch !== tb.u_i_XSTile.core.io_debugTopDown_l3MissMatch) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_debugTopDown_l3MissMatch g=%h i=%h", $time, tb.u_g_XSTile.core.io_debugTopDown_l3MissMatch, tb.u_i_XSTile.core.io_debugTopDown_l3MissMatch); end
    if (armed && tb.u_g_XSTile.core.io_debugTopDown_l3MissMatch !== v167) tog[167] = 1'b1; v167 = tb.u_g_XSTile.core.io_debugTopDown_l3MissMatch;
    pin_checks++; if (tb.u_g_XSTile.core.io_topDownInfo_l2Miss !== tb.u_i_XSTile.core.io_topDownInfo_l2Miss) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_topDownInfo_l2Miss g=%h i=%h", $time, tb.u_g_XSTile.core.io_topDownInfo_l2Miss, tb.u_i_XSTile.core.io_topDownInfo_l2Miss); end
    if (armed && tb.u_g_XSTile.core.io_topDownInfo_l2Miss !== v168) tog[168] = 1'b1; v168 = tb.u_g_XSTile.core.io_topDownInfo_l2Miss;
    pin_checks++; if (tb.u_g_XSTile.core.io_topDownInfo_l3Miss !== tb.u_i_XSTile.core.io_topDownInfo_l3Miss) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_topDownInfo_l3Miss g=%h i=%h", $time, tb.u_g_XSTile.core.io_topDownInfo_l3Miss, tb.u_i_XSTile.core.io_topDownInfo_l3Miss); end
    if (armed && tb.u_g_XSTile.core.io_topDownInfo_l3Miss !== v169) tog[169] = 1'b1; v169 = tb.u_g_XSTile.core.io_topDownInfo_l3Miss;
    pin_checks++; if (tb.u_g_XSTile.core.io_dft_ram_hold !== tb.u_i_XSTile.core.io_dft_ram_hold) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_dft_ram_hold g=%h i=%h", $time, tb.u_g_XSTile.core.io_dft_ram_hold, tb.u_i_XSTile.core.io_dft_ram_hold); end
    if (armed && tb.u_g_XSTile.core.io_dft_ram_hold !== v170) tog[170] = 1'b1; v170 = tb.u_g_XSTile.core.io_dft_ram_hold;
    pin_checks++; if (tb.u_g_XSTile.core.io_dft_ram_bypass !== tb.u_i_XSTile.core.io_dft_ram_bypass) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_dft_ram_bypass g=%h i=%h", $time, tb.u_g_XSTile.core.io_dft_ram_bypass, tb.u_i_XSTile.core.io_dft_ram_bypass); end
    if (armed && tb.u_g_XSTile.core.io_dft_ram_bypass !== v171) tog[171] = 1'b1; v171 = tb.u_g_XSTile.core.io_dft_ram_bypass;
    pin_checks++; if (tb.u_g_XSTile.core.io_dft_ram_bp_clken !== tb.u_i_XSTile.core.io_dft_ram_bp_clken) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_dft_ram_bp_clken g=%h i=%h", $time, tb.u_g_XSTile.core.io_dft_ram_bp_clken, tb.u_i_XSTile.core.io_dft_ram_bp_clken); end
    if (armed && tb.u_g_XSTile.core.io_dft_ram_bp_clken !== v172) tog[172] = 1'b1; v172 = tb.u_g_XSTile.core.io_dft_ram_bp_clken;
    pin_checks++; if (tb.u_g_XSTile.core.io_dft_ram_aux_clk !== tb.u_i_XSTile.core.io_dft_ram_aux_clk) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_dft_ram_aux_clk g=%h i=%h", $time, tb.u_g_XSTile.core.io_dft_ram_aux_clk, tb.u_i_XSTile.core.io_dft_ram_aux_clk); end
    if (armed && tb.u_g_XSTile.core.io_dft_ram_aux_clk !== v173) tog[173] = 1'b1; v173 = tb.u_g_XSTile.core.io_dft_ram_aux_clk;
    pin_checks++; if (tb.u_g_XSTile.core.io_dft_ram_aux_ckbp !== tb.u_i_XSTile.core.io_dft_ram_aux_ckbp) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_dft_ram_aux_ckbp g=%h i=%h", $time, tb.u_g_XSTile.core.io_dft_ram_aux_ckbp, tb.u_i_XSTile.core.io_dft_ram_aux_ckbp); end
    if (armed && tb.u_g_XSTile.core.io_dft_ram_aux_ckbp !== v174) tog[174] = 1'b1; v174 = tb.u_g_XSTile.core.io_dft_ram_aux_ckbp;
    pin_checks++; if (tb.u_g_XSTile.core.io_dft_ram_mcp_hold !== tb.u_i_XSTile.core.io_dft_ram_mcp_hold) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_dft_ram_mcp_hold g=%h i=%h", $time, tb.u_g_XSTile.core.io_dft_ram_mcp_hold, tb.u_i_XSTile.core.io_dft_ram_mcp_hold); end
    if (armed && tb.u_g_XSTile.core.io_dft_ram_mcp_hold !== v175) tog[175] = 1'b1; v175 = tb.u_g_XSTile.core.io_dft_ram_mcp_hold;
    pin_checks++; if (tb.u_g_XSTile.core.io_dft_cgen !== tb.u_i_XSTile.core.io_dft_cgen) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH core.io_dft_cgen g=%h i=%h", $time, tb.u_g_XSTile.core.io_dft_cgen, tb.u_i_XSTile.core.io_dft_cgen); end
    if (armed && tb.u_g_XSTile.core.io_dft_cgen !== v176) tog[176] = 1'b1; v176 = tb.u_g_XSTile.core.io_dft_cgen;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_buffers_out_a_ready !== tb.u_i_XSTile.l2top.auto_inner_buffers_out_a_ready) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_buffers_out_a_ready g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_buffers_out_a_ready, tb.u_i_XSTile.l2top.auto_inner_buffers_out_a_ready); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_buffers_out_a_ready !== v177) tog[177] = 1'b1; v177 = tb.u_g_XSTile.l2top.auto_inner_buffers_out_a_ready;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_valid !== tb.u_i_XSTile.l2top.auto_inner_buffers_out_d_valid) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_buffers_out_d_valid g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_valid, tb.u_i_XSTile.l2top.auto_inner_buffers_out_d_valid); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_valid !== v178) tog[178] = 1'b1; v178 = tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_valid;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_opcode !== tb.u_i_XSTile.l2top.auto_inner_buffers_out_d_bits_opcode) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_buffers_out_d_bits_opcode g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_opcode, tb.u_i_XSTile.l2top.auto_inner_buffers_out_d_bits_opcode); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_opcode !== v179) tog[179] = 1'b1; v179 = tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_opcode;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_param !== tb.u_i_XSTile.l2top.auto_inner_buffers_out_d_bits_param) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_buffers_out_d_bits_param g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_param, tb.u_i_XSTile.l2top.auto_inner_buffers_out_d_bits_param); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_param !== v180) tog[180] = 1'b1; v180 = tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_param;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_size !== tb.u_i_XSTile.l2top.auto_inner_buffers_out_d_bits_size) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_buffers_out_d_bits_size g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_size, tb.u_i_XSTile.l2top.auto_inner_buffers_out_d_bits_size); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_size !== v181) tog[181] = 1'b1; v181 = tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_size;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_source !== tb.u_i_XSTile.l2top.auto_inner_buffers_out_d_bits_source) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_buffers_out_d_bits_source g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_source, tb.u_i_XSTile.l2top.auto_inner_buffers_out_d_bits_source); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_source !== v182) tog[182] = 1'b1; v182 = tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_source;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_sink !== tb.u_i_XSTile.l2top.auto_inner_buffers_out_d_bits_sink) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_buffers_out_d_bits_sink g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_sink, tb.u_i_XSTile.l2top.auto_inner_buffers_out_d_bits_sink); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_sink !== v183) tog[183] = 1'b1; v183 = tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_sink;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_denied !== tb.u_i_XSTile.l2top.auto_inner_buffers_out_d_bits_denied) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_buffers_out_d_bits_denied g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_denied, tb.u_i_XSTile.l2top.auto_inner_buffers_out_d_bits_denied); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_denied !== v184) tog[184] = 1'b1; v184 = tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_denied;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_data !== tb.u_i_XSTile.l2top.auto_inner_buffers_out_d_bits_data) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_buffers_out_d_bits_data g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_data, tb.u_i_XSTile.l2top.auto_inner_buffers_out_d_bits_data); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_data !== v185) tog[185] = 1'b1; v185 = tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_data;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_corrupt !== tb.u_i_XSTile.l2top.auto_inner_buffers_out_d_bits_corrupt) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_buffers_out_d_bits_corrupt g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_corrupt, tb.u_i_XSTile.l2top.auto_inner_buffers_out_d_bits_corrupt); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_corrupt !== v186) tog[186] = 1'b1; v186 = tb.u_g_XSTile.l2top.auto_inner_buffers_out_d_bits_corrupt;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_valid !== tb.u_i_XSTile.l2top.auto_inner_buffers_in_a_valid) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_buffers_in_a_valid g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_valid, tb.u_i_XSTile.l2top.auto_inner_buffers_in_a_valid); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_valid !== v187) tog[187] = 1'b1; v187 = tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_valid;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_opcode !== tb.u_i_XSTile.l2top.auto_inner_buffers_in_a_bits_opcode) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_buffers_in_a_bits_opcode g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_opcode, tb.u_i_XSTile.l2top.auto_inner_buffers_in_a_bits_opcode); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_opcode !== v188) tog[188] = 1'b1; v188 = tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_opcode;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_param !== tb.u_i_XSTile.l2top.auto_inner_buffers_in_a_bits_param) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_buffers_in_a_bits_param g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_param, tb.u_i_XSTile.l2top.auto_inner_buffers_in_a_bits_param); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_param !== v189) tog[189] = 1'b1; v189 = tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_param;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_size !== tb.u_i_XSTile.l2top.auto_inner_buffers_in_a_bits_size) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_buffers_in_a_bits_size g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_size, tb.u_i_XSTile.l2top.auto_inner_buffers_in_a_bits_size); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_size !== v190) tog[190] = 1'b1; v190 = tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_size;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_source !== tb.u_i_XSTile.l2top.auto_inner_buffers_in_a_bits_source) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_buffers_in_a_bits_source g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_source, tb.u_i_XSTile.l2top.auto_inner_buffers_in_a_bits_source); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_source !== v191) tog[191] = 1'b1; v191 = tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_source;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_address !== tb.u_i_XSTile.l2top.auto_inner_buffers_in_a_bits_address) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_buffers_in_a_bits_address g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_address, tb.u_i_XSTile.l2top.auto_inner_buffers_in_a_bits_address); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_address !== v192) tog[192] = 1'b1; v192 = tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_address;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_user_memBackType_MM !== tb.u_i_XSTile.l2top.auto_inner_buffers_in_a_bits_user_memBackType_MM) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_buffers_in_a_bits_user_memBackType_MM g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_user_memBackType_MM, tb.u_i_XSTile.l2top.auto_inner_buffers_in_a_bits_user_memBackType_MM); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_user_memBackType_MM !== v193) tog[193] = 1'b1; v193 = tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_user_memBackType_MM;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_user_memPageType_NC !== tb.u_i_XSTile.l2top.auto_inner_buffers_in_a_bits_user_memPageType_NC) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_buffers_in_a_bits_user_memPageType_NC g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_user_memPageType_NC, tb.u_i_XSTile.l2top.auto_inner_buffers_in_a_bits_user_memPageType_NC); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_user_memPageType_NC !== v194) tog[194] = 1'b1; v194 = tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_user_memPageType_NC;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_mask !== tb.u_i_XSTile.l2top.auto_inner_buffers_in_a_bits_mask) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_buffers_in_a_bits_mask g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_mask, tb.u_i_XSTile.l2top.auto_inner_buffers_in_a_bits_mask); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_mask !== v195) tog[195] = 1'b1; v195 = tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_mask;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_data !== tb.u_i_XSTile.l2top.auto_inner_buffers_in_a_bits_data) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_buffers_in_a_bits_data g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_data, tb.u_i_XSTile.l2top.auto_inner_buffers_in_a_bits_data); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_data !== v196) tog[196] = 1'b1; v196 = tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_data;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_corrupt !== tb.u_i_XSTile.l2top.auto_inner_buffers_in_a_bits_corrupt) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_buffers_in_a_bits_corrupt g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_corrupt, tb.u_i_XSTile.l2top.auto_inner_buffers_in_a_bits_corrupt); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_corrupt !== v197) tog[197] = 1'b1; v197 = tb.u_g_XSTile.l2top.auto_inner_buffers_in_a_bits_corrupt;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_buffers_in_d_ready !== tb.u_i_XSTile.l2top.auto_inner_buffers_in_d_ready) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_buffers_in_d_ready g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_buffers_in_d_ready, tb.u_i_XSTile.l2top.auto_inner_buffers_in_d_ready); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_buffers_in_d_ready !== v198) tog[198] = 1'b1; v198 = tb.u_g_XSTile.l2top.auto_inner_buffers_in_d_ready;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_l2cache_pf_recv_in_addr !== tb.u_i_XSTile.l2top.auto_inner_l2cache_pf_recv_in_addr) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_l2cache_pf_recv_in_addr g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_l2cache_pf_recv_in_addr, tb.u_i_XSTile.l2top.auto_inner_l2cache_pf_recv_in_addr); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_l2cache_pf_recv_in_addr !== v199) tog[199] = 1'b1; v199 = tb.u_g_XSTile.l2top.auto_inner_l2cache_pf_recv_in_addr;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_l2cache_pf_recv_in_pf_source !== tb.u_i_XSTile.l2top.auto_inner_l2cache_pf_recv_in_pf_source) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_l2cache_pf_recv_in_pf_source g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_l2cache_pf_recv_in_pf_source, tb.u_i_XSTile.l2top.auto_inner_l2cache_pf_recv_in_pf_source); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_l2cache_pf_recv_in_pf_source !== v200) tog[200] = 1'b1; v200 = tb.u_g_XSTile.l2top.auto_inner_l2cache_pf_recv_in_pf_source;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_l2cache_pf_recv_in_addr_valid !== tb.u_i_XSTile.l2top.auto_inner_l2cache_pf_recv_in_addr_valid) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_l2cache_pf_recv_in_addr_valid g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_l2cache_pf_recv_in_addr_valid, tb.u_i_XSTile.l2top.auto_inner_l2cache_pf_recv_in_addr_valid); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_l2cache_pf_recv_in_addr_valid !== v201) tog[201] = 1'b1; v201 = tb.u_g_XSTile.l2top.auto_inner_l2cache_pf_recv_in_addr_valid;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_valid !== tb.u_i_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_valid) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_i_mmio_buffer_in_a_valid g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_valid, tb.u_i_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_valid); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_valid !== v202) tog[202] = 1'b1; v202 = tb.u_g_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_valid;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_bits_param !== tb.u_i_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_bits_param) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_i_mmio_buffer_in_a_bits_param g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_bits_param, tb.u_i_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_bits_param); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_bits_param !== v203) tog[203] = 1'b1; v203 = tb.u_g_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_bits_param;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_bits_address !== tb.u_i_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_bits_address) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_i_mmio_buffer_in_a_bits_address g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_bits_address, tb.u_i_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_bits_address); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_bits_address !== v204) tog[204] = 1'b1; v204 = tb.u_g_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_bits_address;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_bits_user_memPageType_NC !== tb.u_i_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_bits_user_memPageType_NC) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_i_mmio_buffer_in_a_bits_user_memPageType_NC g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_bits_user_memPageType_NC, tb.u_i_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_bits_user_memPageType_NC); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_bits_user_memPageType_NC !== v205) tog[205] = 1'b1; v205 = tb.u_g_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_bits_user_memPageType_NC;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_bits_user_memBackType_MM !== tb.u_i_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_bits_user_memBackType_MM) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_i_mmio_buffer_in_a_bits_user_memBackType_MM g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_bits_user_memBackType_MM, tb.u_i_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_bits_user_memBackType_MM); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_bits_user_memBackType_MM !== v206) tog[206] = 1'b1; v206 = tb.u_g_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_bits_user_memBackType_MM;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_bits_corrupt !== tb.u_i_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_bits_corrupt) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_i_mmio_buffer_in_a_bits_corrupt g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_bits_corrupt, tb.u_i_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_bits_corrupt); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_bits_corrupt !== v207) tog[207] = 1'b1; v207 = tb.u_g_XSTile.l2top.auto_inner_i_mmio_buffer_in_a_bits_corrupt;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_i_mmio_buffer_in_d_ready !== tb.u_i_XSTile.l2top.auto_inner_i_mmio_buffer_in_d_ready) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_i_mmio_buffer_in_d_ready g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_i_mmio_buffer_in_d_ready, tb.u_i_XSTile.l2top.auto_inner_i_mmio_buffer_in_d_ready); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_i_mmio_buffer_in_d_ready !== v208) tog[208] = 1'b1; v208 = tb.u_g_XSTile.l2top.auto_inner_i_mmio_buffer_in_d_ready;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_valid !== tb.u_i_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_valid) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_ptw_to_l2_buffer_in_a_valid g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_valid, tb.u_i_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_valid); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_valid !== v209) tog[209] = 1'b1; v209 = tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_valid;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_opcode !== tb.u_i_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_opcode) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_opcode g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_opcode, tb.u_i_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_opcode); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_opcode !== v210) tog[210] = 1'b1; v210 = tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_opcode;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_param !== tb.u_i_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_param) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_param g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_param, tb.u_i_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_param); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_param !== v211) tog[211] = 1'b1; v211 = tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_param;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_size !== tb.u_i_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_size) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_size g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_size, tb.u_i_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_size); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_size !== v212) tog[212] = 1'b1; v212 = tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_size;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_source !== tb.u_i_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_source) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_source g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_source, tb.u_i_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_source); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_source !== v213) tog[213] = 1'b1; v213 = tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_source;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_address !== tb.u_i_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_address) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_address g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_address, tb.u_i_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_address); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_address !== v214) tog[214] = 1'b1; v214 = tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_address;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_user_reqSource !== tb.u_i_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_user_reqSource) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_user_reqSource g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_user_reqSource, tb.u_i_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_user_reqSource); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_user_reqSource !== v215) tog[215] = 1'b1; v215 = tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_user_reqSource;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_mask !== tb.u_i_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_mask) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_mask g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_mask, tb.u_i_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_mask); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_mask !== v216) tog[216] = 1'b1; v216 = tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_mask;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_data !== tb.u_i_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_data) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_data g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_data, tb.u_i_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_data); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_data !== v217) tog[217] = 1'b1; v217 = tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_data;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_corrupt !== tb.u_i_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_corrupt) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_corrupt g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_corrupt, tb.u_i_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_corrupt); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_corrupt !== v218) tog[218] = 1'b1; v218 = tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_corrupt;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_d_ready !== tb.u_i_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_d_ready) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_ptw_to_l2_buffer_in_d_ready g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_d_ready, tb.u_i_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_d_ready); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_d_ready !== v219) tog[219] = 1'b1; v219 = tb.u_g_XSTile.l2top.auto_inner_ptw_to_l2_buffer_in_d_ready;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_valid !== tb.u_i_XSTile.l2top.auto_inner_logger_in_1_a_valid) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_1_a_valid g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_valid, tb.u_i_XSTile.l2top.auto_inner_logger_in_1_a_valid); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_valid !== v220) tog[220] = 1'b1; v220 = tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_valid;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_opcode !== tb.u_i_XSTile.l2top.auto_inner_logger_in_1_a_bits_opcode) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_1_a_bits_opcode g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_opcode, tb.u_i_XSTile.l2top.auto_inner_logger_in_1_a_bits_opcode); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_opcode !== v221) tog[221] = 1'b1; v221 = tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_opcode;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_param !== tb.u_i_XSTile.l2top.auto_inner_logger_in_1_a_bits_param) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_1_a_bits_param g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_param, tb.u_i_XSTile.l2top.auto_inner_logger_in_1_a_bits_param); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_param !== v222) tog[222] = 1'b1; v222 = tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_param;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_size !== tb.u_i_XSTile.l2top.auto_inner_logger_in_1_a_bits_size) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_1_a_bits_size g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_size, tb.u_i_XSTile.l2top.auto_inner_logger_in_1_a_bits_size); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_size !== v223) tog[223] = 1'b1; v223 = tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_size;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_source !== tb.u_i_XSTile.l2top.auto_inner_logger_in_1_a_bits_source) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_1_a_bits_source g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_source, tb.u_i_XSTile.l2top.auto_inner_logger_in_1_a_bits_source); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_source !== v224) tog[224] = 1'b1; v224 = tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_source;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_address !== tb.u_i_XSTile.l2top.auto_inner_logger_in_1_a_bits_address) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_1_a_bits_address g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_address, tb.u_i_XSTile.l2top.auto_inner_logger_in_1_a_bits_address); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_address !== v225) tog[225] = 1'b1; v225 = tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_address;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_user_alias !== tb.u_i_XSTile.l2top.auto_inner_logger_in_1_a_bits_user_alias) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_1_a_bits_user_alias g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_user_alias, tb.u_i_XSTile.l2top.auto_inner_logger_in_1_a_bits_user_alias); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_user_alias !== v226) tog[226] = 1'b1; v226 = tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_user_alias;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_user_reqSource !== tb.u_i_XSTile.l2top.auto_inner_logger_in_1_a_bits_user_reqSource) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_1_a_bits_user_reqSource g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_user_reqSource, tb.u_i_XSTile.l2top.auto_inner_logger_in_1_a_bits_user_reqSource); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_user_reqSource !== v227) tog[227] = 1'b1; v227 = tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_user_reqSource;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_user_needHint !== tb.u_i_XSTile.l2top.auto_inner_logger_in_1_a_bits_user_needHint) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_1_a_bits_user_needHint g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_user_needHint, tb.u_i_XSTile.l2top.auto_inner_logger_in_1_a_bits_user_needHint); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_user_needHint !== v228) tog[228] = 1'b1; v228 = tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_user_needHint;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_mask !== tb.u_i_XSTile.l2top.auto_inner_logger_in_1_a_bits_mask) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_1_a_bits_mask g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_mask, tb.u_i_XSTile.l2top.auto_inner_logger_in_1_a_bits_mask); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_mask !== v229) tog[229] = 1'b1; v229 = tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_mask;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_data !== tb.u_i_XSTile.l2top.auto_inner_logger_in_1_a_bits_data) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_1_a_bits_data g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_data, tb.u_i_XSTile.l2top.auto_inner_logger_in_1_a_bits_data); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_data !== v230) tog[230] = 1'b1; v230 = tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_data;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_corrupt !== tb.u_i_XSTile.l2top.auto_inner_logger_in_1_a_bits_corrupt) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_1_a_bits_corrupt g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_corrupt, tb.u_i_XSTile.l2top.auto_inner_logger_in_1_a_bits_corrupt); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_corrupt !== v231) tog[231] = 1'b1; v231 = tb.u_g_XSTile.l2top.auto_inner_logger_in_1_a_bits_corrupt;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_1_d_ready !== tb.u_i_XSTile.l2top.auto_inner_logger_in_1_d_ready) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_1_d_ready g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_1_d_ready, tb.u_i_XSTile.l2top.auto_inner_logger_in_1_d_ready); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_1_d_ready !== v232) tog[232] = 1'b1; v232 = tb.u_g_XSTile.l2top.auto_inner_logger_in_1_d_ready;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_valid !== tb.u_i_XSTile.l2top.auto_inner_logger_in_0_a_valid) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_0_a_valid g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_valid, tb.u_i_XSTile.l2top.auto_inner_logger_in_0_a_valid); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_valid !== v233) tog[233] = 1'b1; v233 = tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_valid;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_opcode !== tb.u_i_XSTile.l2top.auto_inner_logger_in_0_a_bits_opcode) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_0_a_bits_opcode g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_opcode, tb.u_i_XSTile.l2top.auto_inner_logger_in_0_a_bits_opcode); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_opcode !== v234) tog[234] = 1'b1; v234 = tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_opcode;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_param !== tb.u_i_XSTile.l2top.auto_inner_logger_in_0_a_bits_param) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_0_a_bits_param g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_param, tb.u_i_XSTile.l2top.auto_inner_logger_in_0_a_bits_param); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_param !== v235) tog[235] = 1'b1; v235 = tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_param;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_size !== tb.u_i_XSTile.l2top.auto_inner_logger_in_0_a_bits_size) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_0_a_bits_size g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_size, tb.u_i_XSTile.l2top.auto_inner_logger_in_0_a_bits_size); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_size !== v236) tog[236] = 1'b1; v236 = tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_size;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_source !== tb.u_i_XSTile.l2top.auto_inner_logger_in_0_a_bits_source) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_0_a_bits_source g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_source, tb.u_i_XSTile.l2top.auto_inner_logger_in_0_a_bits_source); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_source !== v237) tog[237] = 1'b1; v237 = tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_source;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_address !== tb.u_i_XSTile.l2top.auto_inner_logger_in_0_a_bits_address) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_0_a_bits_address g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_address, tb.u_i_XSTile.l2top.auto_inner_logger_in_0_a_bits_address); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_address !== v238) tog[238] = 1'b1; v238 = tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_address;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_user_alias !== tb.u_i_XSTile.l2top.auto_inner_logger_in_0_a_bits_user_alias) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_0_a_bits_user_alias g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_user_alias, tb.u_i_XSTile.l2top.auto_inner_logger_in_0_a_bits_user_alias); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_user_alias !== v239) tog[239] = 1'b1; v239 = tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_user_alias;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_user_vaddr !== tb.u_i_XSTile.l2top.auto_inner_logger_in_0_a_bits_user_vaddr) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_0_a_bits_user_vaddr g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_user_vaddr, tb.u_i_XSTile.l2top.auto_inner_logger_in_0_a_bits_user_vaddr); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_user_vaddr !== v240) tog[240] = 1'b1; v240 = tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_user_vaddr;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_user_reqSource !== tb.u_i_XSTile.l2top.auto_inner_logger_in_0_a_bits_user_reqSource) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_0_a_bits_user_reqSource g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_user_reqSource, tb.u_i_XSTile.l2top.auto_inner_logger_in_0_a_bits_user_reqSource); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_user_reqSource !== v241) tog[241] = 1'b1; v241 = tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_user_reqSource;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_user_needHint !== tb.u_i_XSTile.l2top.auto_inner_logger_in_0_a_bits_user_needHint) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_0_a_bits_user_needHint g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_user_needHint, tb.u_i_XSTile.l2top.auto_inner_logger_in_0_a_bits_user_needHint); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_user_needHint !== v242) tog[242] = 1'b1; v242 = tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_user_needHint;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_echo_isKeyword !== tb.u_i_XSTile.l2top.auto_inner_logger_in_0_a_bits_echo_isKeyword) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_0_a_bits_echo_isKeyword g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_echo_isKeyword, tb.u_i_XSTile.l2top.auto_inner_logger_in_0_a_bits_echo_isKeyword); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_echo_isKeyword !== v243) tog[243] = 1'b1; v243 = tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_echo_isKeyword;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_mask !== tb.u_i_XSTile.l2top.auto_inner_logger_in_0_a_bits_mask) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_0_a_bits_mask g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_mask, tb.u_i_XSTile.l2top.auto_inner_logger_in_0_a_bits_mask); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_mask !== v244) tog[244] = 1'b1; v244 = tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_mask;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_data !== tb.u_i_XSTile.l2top.auto_inner_logger_in_0_a_bits_data) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_0_a_bits_data g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_data, tb.u_i_XSTile.l2top.auto_inner_logger_in_0_a_bits_data); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_data !== v245) tog[245] = 1'b1; v245 = tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_data;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_corrupt !== tb.u_i_XSTile.l2top.auto_inner_logger_in_0_a_bits_corrupt) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_0_a_bits_corrupt g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_corrupt, tb.u_i_XSTile.l2top.auto_inner_logger_in_0_a_bits_corrupt); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_corrupt !== v246) tog[246] = 1'b1; v246 = tb.u_g_XSTile.l2top.auto_inner_logger_in_0_a_bits_corrupt;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_0_b_ready !== tb.u_i_XSTile.l2top.auto_inner_logger_in_0_b_ready) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_0_b_ready g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_0_b_ready, tb.u_i_XSTile.l2top.auto_inner_logger_in_0_b_ready); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_0_b_ready !== v247) tog[247] = 1'b1; v247 = tb.u_g_XSTile.l2top.auto_inner_logger_in_0_b_ready;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_valid !== tb.u_i_XSTile.l2top.auto_inner_logger_in_0_c_valid) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_0_c_valid g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_valid, tb.u_i_XSTile.l2top.auto_inner_logger_in_0_c_valid); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_valid !== v248) tog[248] = 1'b1; v248 = tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_valid;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_opcode !== tb.u_i_XSTile.l2top.auto_inner_logger_in_0_c_bits_opcode) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_0_c_bits_opcode g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_opcode, tb.u_i_XSTile.l2top.auto_inner_logger_in_0_c_bits_opcode); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_opcode !== v249) tog[249] = 1'b1; v249 = tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_opcode;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_param !== tb.u_i_XSTile.l2top.auto_inner_logger_in_0_c_bits_param) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_0_c_bits_param g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_param, tb.u_i_XSTile.l2top.auto_inner_logger_in_0_c_bits_param); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_param !== v250) tog[250] = 1'b1; v250 = tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_param;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_size !== tb.u_i_XSTile.l2top.auto_inner_logger_in_0_c_bits_size) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_0_c_bits_size g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_size, tb.u_i_XSTile.l2top.auto_inner_logger_in_0_c_bits_size); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_size !== v251) tog[251] = 1'b1; v251 = tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_size;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_source !== tb.u_i_XSTile.l2top.auto_inner_logger_in_0_c_bits_source) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_0_c_bits_source g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_source, tb.u_i_XSTile.l2top.auto_inner_logger_in_0_c_bits_source); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_source !== v252) tog[252] = 1'b1; v252 = tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_source;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_address !== tb.u_i_XSTile.l2top.auto_inner_logger_in_0_c_bits_address) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_0_c_bits_address g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_address, tb.u_i_XSTile.l2top.auto_inner_logger_in_0_c_bits_address); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_address !== v253) tog[253] = 1'b1; v253 = tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_address;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_user_alias !== tb.u_i_XSTile.l2top.auto_inner_logger_in_0_c_bits_user_alias) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_0_c_bits_user_alias g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_user_alias, tb.u_i_XSTile.l2top.auto_inner_logger_in_0_c_bits_user_alias); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_user_alias !== v254) tog[254] = 1'b1; v254 = tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_user_alias;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_user_vaddr !== tb.u_i_XSTile.l2top.auto_inner_logger_in_0_c_bits_user_vaddr) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_0_c_bits_user_vaddr g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_user_vaddr, tb.u_i_XSTile.l2top.auto_inner_logger_in_0_c_bits_user_vaddr); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_user_vaddr !== v255) tog[255] = 1'b1; v255 = tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_user_vaddr;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_user_reqSource !== tb.u_i_XSTile.l2top.auto_inner_logger_in_0_c_bits_user_reqSource) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_0_c_bits_user_reqSource g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_user_reqSource, tb.u_i_XSTile.l2top.auto_inner_logger_in_0_c_bits_user_reqSource); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_user_reqSource !== v256) tog[256] = 1'b1; v256 = tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_user_reqSource;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_user_needHint !== tb.u_i_XSTile.l2top.auto_inner_logger_in_0_c_bits_user_needHint) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_0_c_bits_user_needHint g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_user_needHint, tb.u_i_XSTile.l2top.auto_inner_logger_in_0_c_bits_user_needHint); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_user_needHint !== v257) tog[257] = 1'b1; v257 = tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_user_needHint;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_echo_isKeyword !== tb.u_i_XSTile.l2top.auto_inner_logger_in_0_c_bits_echo_isKeyword) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_0_c_bits_echo_isKeyword g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_echo_isKeyword, tb.u_i_XSTile.l2top.auto_inner_logger_in_0_c_bits_echo_isKeyword); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_echo_isKeyword !== v258) tog[258] = 1'b1; v258 = tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_echo_isKeyword;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_data !== tb.u_i_XSTile.l2top.auto_inner_logger_in_0_c_bits_data) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_0_c_bits_data g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_data, tb.u_i_XSTile.l2top.auto_inner_logger_in_0_c_bits_data); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_data !== v259) tog[259] = 1'b1; v259 = tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_data;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_corrupt !== tb.u_i_XSTile.l2top.auto_inner_logger_in_0_c_bits_corrupt) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_0_c_bits_corrupt g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_corrupt, tb.u_i_XSTile.l2top.auto_inner_logger_in_0_c_bits_corrupt); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_corrupt !== v260) tog[260] = 1'b1; v260 = tb.u_g_XSTile.l2top.auto_inner_logger_in_0_c_bits_corrupt;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_0_d_ready !== tb.u_i_XSTile.l2top.auto_inner_logger_in_0_d_ready) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_0_d_ready g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_0_d_ready, tb.u_i_XSTile.l2top.auto_inner_logger_in_0_d_ready); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_0_d_ready !== v261) tog[261] = 1'b1; v261 = tb.u_g_XSTile.l2top.auto_inner_logger_in_0_d_ready;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_0_e_valid !== tb.u_i_XSTile.l2top.auto_inner_logger_in_0_e_valid) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_0_e_valid g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_0_e_valid, tb.u_i_XSTile.l2top.auto_inner_logger_in_0_e_valid); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_0_e_valid !== v262) tog[262] = 1'b1; v262 = tb.u_g_XSTile.l2top.auto_inner_logger_in_0_e_valid;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_logger_in_0_e_bits_sink !== tb.u_i_XSTile.l2top.auto_inner_logger_in_0_e_bits_sink) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_logger_in_0_e_bits_sink g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_logger_in_0_e_bits_sink, tb.u_i_XSTile.l2top.auto_inner_logger_in_0_e_bits_sink); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_logger_in_0_e_bits_sink !== v263) tog[263] = 1'b1; v263 = tb.u_g_XSTile.l2top.auto_inner_logger_in_0_e_bits_sink;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_nmi_int_in_0 !== tb.u_i_XSTile.l2top.auto_inner_nmi_int_in_0) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_nmi_int_in_0 g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_nmi_int_in_0, tb.u_i_XSTile.l2top.auto_inner_nmi_int_in_0); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_nmi_int_in_0 !== v264) tog[264] = 1'b1; v264 = tb.u_g_XSTile.l2top.auto_inner_nmi_int_in_0;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_nmi_int_in_1 !== tb.u_i_XSTile.l2top.auto_inner_nmi_int_in_1) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_nmi_int_in_1 g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_nmi_int_in_1, tb.u_i_XSTile.l2top.auto_inner_nmi_int_in_1); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_nmi_int_in_1 !== v265) tog[265] = 1'b1; v265 = tb.u_g_XSTile.l2top.auto_inner_nmi_int_in_1;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_plic_int_in_1_0 !== tb.u_i_XSTile.l2top.auto_inner_plic_int_in_1_0) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_plic_int_in_1_0 g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_plic_int_in_1_0, tb.u_i_XSTile.l2top.auto_inner_plic_int_in_1_0); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_plic_int_in_1_0 !== v266) tog[266] = 1'b1; v266 = tb.u_g_XSTile.l2top.auto_inner_plic_int_in_1_0;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_plic_int_in_0_0 !== tb.u_i_XSTile.l2top.auto_inner_plic_int_in_0_0) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_plic_int_in_0_0 g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_plic_int_in_0_0, tb.u_i_XSTile.l2top.auto_inner_plic_int_in_0_0); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_plic_int_in_0_0 !== v267) tog[267] = 1'b1; v267 = tb.u_g_XSTile.l2top.auto_inner_plic_int_in_0_0;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_debug_int_in_0 !== tb.u_i_XSTile.l2top.auto_inner_debug_int_in_0) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_debug_int_in_0 g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_debug_int_in_0, tb.u_i_XSTile.l2top.auto_inner_debug_int_in_0); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_debug_int_in_0 !== v268) tog[268] = 1'b1; v268 = tb.u_g_XSTile.l2top.auto_inner_debug_int_in_0;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_clint_int_in_0 !== tb.u_i_XSTile.l2top.auto_inner_clint_int_in_0) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_clint_int_in_0 g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_clint_int_in_0, tb.u_i_XSTile.l2top.auto_inner_clint_int_in_0); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_clint_int_in_0 !== v269) tog[269] = 1'b1; v269 = tb.u_g_XSTile.l2top.auto_inner_clint_int_in_0;
    pin_checks++; if (tb.u_g_XSTile.l2top.auto_inner_clint_int_in_1 !== tb.u_i_XSTile.l2top.auto_inner_clint_int_in_1) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.auto_inner_clint_int_in_1 g=%h i=%h", $time, tb.u_g_XSTile.l2top.auto_inner_clint_int_in_1, tb.u_i_XSTile.l2top.auto_inner_clint_int_in_1); end
    if (armed && tb.u_g_XSTile.l2top.auto_inner_clint_int_in_1 !== v270) tog[270] = 1'b1; v270 = tb.u_g_XSTile.l2top.auto_inner_clint_int_in_1;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_beu_errors_icache_ecc_error_valid !== tb.u_i_XSTile.l2top.io_beu_errors_icache_ecc_error_valid) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_beu_errors_icache_ecc_error_valid g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_beu_errors_icache_ecc_error_valid, tb.u_i_XSTile.l2top.io_beu_errors_icache_ecc_error_valid); end
    if (armed && tb.u_g_XSTile.l2top.io_beu_errors_icache_ecc_error_valid !== v271) tog[271] = 1'b1; v271 = tb.u_g_XSTile.l2top.io_beu_errors_icache_ecc_error_valid;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_beu_errors_icache_ecc_error_bits !== tb.u_i_XSTile.l2top.io_beu_errors_icache_ecc_error_bits) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_beu_errors_icache_ecc_error_bits g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_beu_errors_icache_ecc_error_bits, tb.u_i_XSTile.l2top.io_beu_errors_icache_ecc_error_bits); end
    if (armed && tb.u_g_XSTile.l2top.io_beu_errors_icache_ecc_error_bits !== v272) tog[272] = 1'b1; v272 = tb.u_g_XSTile.l2top.io_beu_errors_icache_ecc_error_bits;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_beu_errors_dcache_ecc_error_valid !== tb.u_i_XSTile.l2top.io_beu_errors_dcache_ecc_error_valid) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_beu_errors_dcache_ecc_error_valid g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_beu_errors_dcache_ecc_error_valid, tb.u_i_XSTile.l2top.io_beu_errors_dcache_ecc_error_valid); end
    if (armed && tb.u_g_XSTile.l2top.io_beu_errors_dcache_ecc_error_valid !== v273) tog[273] = 1'b1; v273 = tb.u_g_XSTile.l2top.io_beu_errors_dcache_ecc_error_valid;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_beu_errors_dcache_ecc_error_bits !== tb.u_i_XSTile.l2top.io_beu_errors_dcache_ecc_error_bits) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_beu_errors_dcache_ecc_error_bits g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_beu_errors_dcache_ecc_error_bits, tb.u_i_XSTile.l2top.io_beu_errors_dcache_ecc_error_bits); end
    if (armed && tb.u_g_XSTile.l2top.io_beu_errors_dcache_ecc_error_bits !== v274) tog[274] = 1'b1; v274 = tb.u_g_XSTile.l2top.io_beu_errors_dcache_ecc_error_bits;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_beu_errors_uncache_ecc_error_valid !== tb.u_i_XSTile.l2top.io_beu_errors_uncache_ecc_error_valid) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_beu_errors_uncache_ecc_error_valid g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_beu_errors_uncache_ecc_error_valid, tb.u_i_XSTile.l2top.io_beu_errors_uncache_ecc_error_valid); end
    if (armed && tb.u_g_XSTile.l2top.io_beu_errors_uncache_ecc_error_valid !== v275) tog[275] = 1'b1; v275 = tb.u_g_XSTile.l2top.io_beu_errors_uncache_ecc_error_valid;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_beu_errors_uncache_ecc_error_bits !== tb.u_i_XSTile.l2top.io_beu_errors_uncache_ecc_error_bits) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_beu_errors_uncache_ecc_error_bits g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_beu_errors_uncache_ecc_error_bits, tb.u_i_XSTile.l2top.io_beu_errors_uncache_ecc_error_bits); end
    if (armed && tb.u_g_XSTile.l2top.io_beu_errors_uncache_ecc_error_bits !== v276) tog[276] = 1'b1; v276 = tb.u_g_XSTile.l2top.io_beu_errors_uncache_ecc_error_bits;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_reset_vector_fromTile !== tb.u_i_XSTile.l2top.io_reset_vector_fromTile) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_reset_vector_fromTile g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_reset_vector_fromTile, tb.u_i_XSTile.l2top.io_reset_vector_fromTile); end
    if (armed && tb.u_g_XSTile.l2top.io_reset_vector_fromTile !== v277) tog[277] = 1'b1; v277 = tb.u_g_XSTile.l2top.io_reset_vector_fromTile;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_hartId_fromTile !== tb.u_i_XSTile.l2top.io_hartId_fromTile) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_hartId_fromTile g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_hartId_fromTile, tb.u_i_XSTile.l2top.io_hartId_fromTile); end
    if (armed && tb.u_g_XSTile.l2top.io_hartId_fromTile !== v278) tog[278] = 1'b1; v278 = tb.u_g_XSTile.l2top.io_hartId_fromTile;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_msiInfo_fromTile_valid !== tb.u_i_XSTile.l2top.io_msiInfo_fromTile_valid) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_msiInfo_fromTile_valid g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_msiInfo_fromTile_valid, tb.u_i_XSTile.l2top.io_msiInfo_fromTile_valid); end
    if (armed && tb.u_g_XSTile.l2top.io_msiInfo_fromTile_valid !== v279) tog[279] = 1'b1; v279 = tb.u_g_XSTile.l2top.io_msiInfo_fromTile_valid;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_msiInfo_fromTile_bits !== tb.u_i_XSTile.l2top.io_msiInfo_fromTile_bits) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_msiInfo_fromTile_bits g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_msiInfo_fromTile_bits, tb.u_i_XSTile.l2top.io_msiInfo_fromTile_bits); end
    if (armed && tb.u_g_XSTile.l2top.io_msiInfo_fromTile_bits !== v280) tog[280] = 1'b1; v280 = tb.u_g_XSTile.l2top.io_msiInfo_fromTile_bits;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_msiAck_fromCore !== tb.u_i_XSTile.l2top.io_msiAck_fromCore) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_msiAck_fromCore g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_msiAck_fromCore, tb.u_i_XSTile.l2top.io_msiAck_fromCore); end
    if (armed && tb.u_g_XSTile.l2top.io_msiAck_fromCore !== v281) tog[281] = 1'b1; v281 = tb.u_g_XSTile.l2top.io_msiAck_fromCore;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_cpu_halt_fromCore !== tb.u_i_XSTile.l2top.io_cpu_halt_fromCore) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_cpu_halt_fromCore g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_cpu_halt_fromCore, tb.u_i_XSTile.l2top.io_cpu_halt_fromCore); end
    if (armed && tb.u_g_XSTile.l2top.io_cpu_halt_fromCore !== v282) tog[282] = 1'b1; v282 = tb.u_g_XSTile.l2top.io_cpu_halt_fromCore;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_cpu_critical_error_fromCore !== tb.u_i_XSTile.l2top.io_cpu_critical_error_fromCore) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_cpu_critical_error_fromCore g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_cpu_critical_error_fromCore, tb.u_i_XSTile.l2top.io_cpu_critical_error_fromCore); end
    if (armed && tb.u_g_XSTile.l2top.io_cpu_critical_error_fromCore !== v283) tog[283] = 1'b1; v283 = tb.u_g_XSTile.l2top.io_cpu_critical_error_fromCore;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_hartIsInReset_resetInFrontend !== tb.u_i_XSTile.l2top.io_hartIsInReset_resetInFrontend) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_hartIsInReset_resetInFrontend g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_hartIsInReset_resetInFrontend, tb.u_i_XSTile.l2top.io_hartIsInReset_resetInFrontend); end
    if (armed && tb.u_g_XSTile.l2top.io_hartIsInReset_resetInFrontend !== v284) tog[284] = 1'b1; v284 = tb.u_g_XSTile.l2top.io_hartIsInReset_resetInFrontend;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_priv !== tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_priv) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_traceCoreInterface_fromCore_toEncoder_priv g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_priv, tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_priv); end
    if (armed && tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_priv !== v285) tog[285] = 1'b1; v285 = tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_priv;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_mstatus !== tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_mstatus) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_traceCoreInterface_fromCore_toEncoder_mstatus g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_mstatus, tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_mstatus); end
    if (armed && tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_mstatus !== v286) tog[286] = 1'b1; v286 = tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_mstatus;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_trap_cause !== tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_trap_cause) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_traceCoreInterface_fromCore_toEncoder_trap_cause g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_trap_cause, tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_trap_cause); end
    if (armed && tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_trap_cause !== v287) tog[287] = 1'b1; v287 = tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_trap_cause;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_trap_tval !== tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_trap_tval) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_traceCoreInterface_fromCore_toEncoder_trap_tval g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_trap_tval, tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_trap_tval); end
    if (armed && tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_trap_tval !== v288) tog[288] = 1'b1; v288 = tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_trap_tval;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_valid !== tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_valid) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_valid g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_valid, tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_valid); end
    if (armed && tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_valid !== v289) tog[289] = 1'b1; v289 = tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_valid;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iaddr !== tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iaddr) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iaddr g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iaddr, tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iaddr); end
    if (armed && tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iaddr !== v290) tog[290] = 1'b1; v290 = tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iaddr;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_itype !== tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_itype) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_itype g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_itype, tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_itype); end
    if (armed && tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_itype !== v291) tog[291] = 1'b1; v291 = tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_itype;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iretire !== tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iretire) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iretire g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iretire, tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iretire); end
    if (armed && tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iretire !== v292) tog[292] = 1'b1; v292 = tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iretire;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_ilastsize !== tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_ilastsize) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_ilastsize g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_ilastsize, tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_ilastsize); end
    if (armed && tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_ilastsize !== v293) tog[293] = 1'b1; v293 = tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_ilastsize;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_valid !== tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_valid) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_valid g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_valid, tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_valid); end
    if (armed && tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_valid !== v294) tog[294] = 1'b1; v294 = tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_valid;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iaddr !== tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iaddr) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iaddr g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iaddr, tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iaddr); end
    if (armed && tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iaddr !== v295) tog[295] = 1'b1; v295 = tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iaddr;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_itype !== tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_itype) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_itype g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_itype, tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_itype); end
    if (armed && tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_itype !== v296) tog[296] = 1'b1; v296 = tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_itype;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iretire !== tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iretire) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iretire g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iretire, tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iretire); end
    if (armed && tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iretire !== v297) tog[297] = 1'b1; v297 = tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iretire;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_ilastsize !== tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_ilastsize) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_ilastsize g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_ilastsize, tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_ilastsize); end
    if (armed && tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_ilastsize !== v298) tog[298] = 1'b1; v298 = tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_ilastsize;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_valid !== tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_valid) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_valid g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_valid, tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_valid); end
    if (armed && tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_valid !== v299) tog[299] = 1'b1; v299 = tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_valid;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iaddr !== tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iaddr) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iaddr g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iaddr, tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iaddr); end
    if (armed && tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iaddr !== v300) tog[300] = 1'b1; v300 = tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iaddr;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_itype !== tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_itype) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_itype g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_itype, tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_itype); end
    if (armed && tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_itype !== v301) tog[301] = 1'b1; v301 = tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_itype;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iretire !== tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iretire) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iretire g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iretire, tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iretire); end
    if (armed && tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iretire !== v302) tog[302] = 1'b1; v302 = tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iretire;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_ilastsize !== tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_ilastsize) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_ilastsize g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_ilastsize, tb.u_i_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_ilastsize); end
    if (armed && tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_ilastsize !== v303) tog[303] = 1'b1; v303 = tb.u_g_XSTile.l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_ilastsize;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_traceCoreInterface_toTile_fromEncoder_enable !== tb.u_i_XSTile.l2top.io_traceCoreInterface_toTile_fromEncoder_enable) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_traceCoreInterface_toTile_fromEncoder_enable g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_traceCoreInterface_toTile_fromEncoder_enable, tb.u_i_XSTile.l2top.io_traceCoreInterface_toTile_fromEncoder_enable); end
    if (armed && tb.u_g_XSTile.l2top.io_traceCoreInterface_toTile_fromEncoder_enable !== v304) tog[304] = 1'b1; v304 = tb.u_g_XSTile.l2top.io_traceCoreInterface_toTile_fromEncoder_enable;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_traceCoreInterface_toTile_fromEncoder_stall !== tb.u_i_XSTile.l2top.io_traceCoreInterface_toTile_fromEncoder_stall) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_traceCoreInterface_toTile_fromEncoder_stall g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_traceCoreInterface_toTile_fromEncoder_stall, tb.u_i_XSTile.l2top.io_traceCoreInterface_toTile_fromEncoder_stall); end
    if (armed && tb.u_g_XSTile.l2top.io_traceCoreInterface_toTile_fromEncoder_stall !== v305) tog[305] = 1'b1; v305 = tb.u_g_XSTile.l2top.io_traceCoreInterface_toTile_fromEncoder_stall;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_debugTopDown_robHeadPaddr_valid !== tb.u_i_XSTile.l2top.io_debugTopDown_robHeadPaddr_valid) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_debugTopDown_robHeadPaddr_valid g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_debugTopDown_robHeadPaddr_valid, tb.u_i_XSTile.l2top.io_debugTopDown_robHeadPaddr_valid); end
    if (armed && tb.u_g_XSTile.l2top.io_debugTopDown_robHeadPaddr_valid !== v306) tog[306] = 1'b1; v306 = tb.u_g_XSTile.l2top.io_debugTopDown_robHeadPaddr_valid;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_debugTopDown_robHeadPaddr_bits !== tb.u_i_XSTile.l2top.io_debugTopDown_robHeadPaddr_bits) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_debugTopDown_robHeadPaddr_bits g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_debugTopDown_robHeadPaddr_bits, tb.u_i_XSTile.l2top.io_debugTopDown_robHeadPaddr_bits); end
    if (armed && tb.u_g_XSTile.l2top.io_debugTopDown_robHeadPaddr_bits !== v307) tog[307] = 1'b1; v307 = tb.u_g_XSTile.l2top.io_debugTopDown_robHeadPaddr_bits;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_l3Miss_fromTile !== tb.u_i_XSTile.l2top.io_l3Miss_fromTile) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_l3Miss_fromTile g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_l3Miss_fromTile, tb.u_i_XSTile.l2top.io_l3Miss_fromTile); end
    if (armed && tb.u_g_XSTile.l2top.io_l3Miss_fromTile !== v308) tog[308] = 1'b1; v308 = tb.u_g_XSTile.l2top.io_l3Miss_fromTile;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_clintTime_fromTile_valid !== tb.u_i_XSTile.l2top.io_clintTime_fromTile_valid) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_clintTime_fromTile_valid g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_clintTime_fromTile_valid, tb.u_i_XSTile.l2top.io_clintTime_fromTile_valid); end
    if (armed && tb.u_g_XSTile.l2top.io_clintTime_fromTile_valid !== v309) tog[309] = 1'b1; v309 = tb.u_g_XSTile.l2top.io_clintTime_fromTile_valid;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_clintTime_fromTile_bits !== tb.u_i_XSTile.l2top.io_clintTime_fromTile_bits) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_clintTime_fromTile_bits g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_clintTime_fromTile_bits, tb.u_i_XSTile.l2top.io_clintTime_fromTile_bits); end
    if (armed && tb.u_g_XSTile.l2top.io_clintTime_fromTile_bits !== v310) tog[310] = 1'b1; v310 = tb.u_g_XSTile.l2top.io_clintTime_fromTile_bits;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_chi_rxsactive !== tb.u_i_XSTile.l2top.io_chi_rxsactive) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_chi_rxsactive g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_chi_rxsactive, tb.u_i_XSTile.l2top.io_chi_rxsactive); end
    if (armed && tb.u_g_XSTile.l2top.io_chi_rxsactive !== v311) tog[311] = 1'b1; v311 = tb.u_g_XSTile.l2top.io_chi_rxsactive;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_chi_syscoack !== tb.u_i_XSTile.l2top.io_chi_syscoack) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_chi_syscoack g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_chi_syscoack, tb.u_i_XSTile.l2top.io_chi_syscoack); end
    if (armed && tb.u_g_XSTile.l2top.io_chi_syscoack !== v312) tog[312] = 1'b1; v312 = tb.u_g_XSTile.l2top.io_chi_syscoack;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_chi_tx_linkactiveack !== tb.u_i_XSTile.l2top.io_chi_tx_linkactiveack) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_chi_tx_linkactiveack g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_chi_tx_linkactiveack, tb.u_i_XSTile.l2top.io_chi_tx_linkactiveack); end
    if (armed && tb.u_g_XSTile.l2top.io_chi_tx_linkactiveack !== v313) tog[313] = 1'b1; v313 = tb.u_g_XSTile.l2top.io_chi_tx_linkactiveack;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_chi_tx_req_lcrdv !== tb.u_i_XSTile.l2top.io_chi_tx_req_lcrdv) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_chi_tx_req_lcrdv g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_chi_tx_req_lcrdv, tb.u_i_XSTile.l2top.io_chi_tx_req_lcrdv); end
    if (armed && tb.u_g_XSTile.l2top.io_chi_tx_req_lcrdv !== v314) tog[314] = 1'b1; v314 = tb.u_g_XSTile.l2top.io_chi_tx_req_lcrdv;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_chi_tx_rsp_lcrdv !== tb.u_i_XSTile.l2top.io_chi_tx_rsp_lcrdv) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_chi_tx_rsp_lcrdv g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_chi_tx_rsp_lcrdv, tb.u_i_XSTile.l2top.io_chi_tx_rsp_lcrdv); end
    if (armed && tb.u_g_XSTile.l2top.io_chi_tx_rsp_lcrdv !== v315) tog[315] = 1'b1; v315 = tb.u_g_XSTile.l2top.io_chi_tx_rsp_lcrdv;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_chi_tx_dat_lcrdv !== tb.u_i_XSTile.l2top.io_chi_tx_dat_lcrdv) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_chi_tx_dat_lcrdv g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_chi_tx_dat_lcrdv, tb.u_i_XSTile.l2top.io_chi_tx_dat_lcrdv); end
    if (armed && tb.u_g_XSTile.l2top.io_chi_tx_dat_lcrdv !== v316) tog[316] = 1'b1; v316 = tb.u_g_XSTile.l2top.io_chi_tx_dat_lcrdv;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_chi_rx_linkactivereq !== tb.u_i_XSTile.l2top.io_chi_rx_linkactivereq) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_chi_rx_linkactivereq g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_chi_rx_linkactivereq, tb.u_i_XSTile.l2top.io_chi_rx_linkactivereq); end
    if (armed && tb.u_g_XSTile.l2top.io_chi_rx_linkactivereq !== v317) tog[317] = 1'b1; v317 = tb.u_g_XSTile.l2top.io_chi_rx_linkactivereq;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_chi_rx_rsp_flitpend !== tb.u_i_XSTile.l2top.io_chi_rx_rsp_flitpend) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_chi_rx_rsp_flitpend g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_chi_rx_rsp_flitpend, tb.u_i_XSTile.l2top.io_chi_rx_rsp_flitpend); end
    if (armed && tb.u_g_XSTile.l2top.io_chi_rx_rsp_flitpend !== v318) tog[318] = 1'b1; v318 = tb.u_g_XSTile.l2top.io_chi_rx_rsp_flitpend;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_chi_rx_rsp_flitv !== tb.u_i_XSTile.l2top.io_chi_rx_rsp_flitv) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_chi_rx_rsp_flitv g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_chi_rx_rsp_flitv, tb.u_i_XSTile.l2top.io_chi_rx_rsp_flitv); end
    if (armed && tb.u_g_XSTile.l2top.io_chi_rx_rsp_flitv !== v319) tog[319] = 1'b1; v319 = tb.u_g_XSTile.l2top.io_chi_rx_rsp_flitv;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_chi_rx_rsp_flit !== tb.u_i_XSTile.l2top.io_chi_rx_rsp_flit) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_chi_rx_rsp_flit g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_chi_rx_rsp_flit, tb.u_i_XSTile.l2top.io_chi_rx_rsp_flit); end
    if (armed && tb.u_g_XSTile.l2top.io_chi_rx_rsp_flit !== v320) tog[320] = 1'b1; v320 = tb.u_g_XSTile.l2top.io_chi_rx_rsp_flit;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_chi_rx_dat_flitpend !== tb.u_i_XSTile.l2top.io_chi_rx_dat_flitpend) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_chi_rx_dat_flitpend g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_chi_rx_dat_flitpend, tb.u_i_XSTile.l2top.io_chi_rx_dat_flitpend); end
    if (armed && tb.u_g_XSTile.l2top.io_chi_rx_dat_flitpend !== v321) tog[321] = 1'b1; v321 = tb.u_g_XSTile.l2top.io_chi_rx_dat_flitpend;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_chi_rx_dat_flitv !== tb.u_i_XSTile.l2top.io_chi_rx_dat_flitv) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_chi_rx_dat_flitv g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_chi_rx_dat_flitv, tb.u_i_XSTile.l2top.io_chi_rx_dat_flitv); end
    if (armed && tb.u_g_XSTile.l2top.io_chi_rx_dat_flitv !== v322) tog[322] = 1'b1; v322 = tb.u_g_XSTile.l2top.io_chi_rx_dat_flitv;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_chi_rx_dat_flit !== tb.u_i_XSTile.l2top.io_chi_rx_dat_flit) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_chi_rx_dat_flit g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_chi_rx_dat_flit, tb.u_i_XSTile.l2top.io_chi_rx_dat_flit); end
    if (armed && tb.u_g_XSTile.l2top.io_chi_rx_dat_flit !== v323) tog[323] = 1'b1; v323 = tb.u_g_XSTile.l2top.io_chi_rx_dat_flit;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_chi_rx_snp_flitpend !== tb.u_i_XSTile.l2top.io_chi_rx_snp_flitpend) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_chi_rx_snp_flitpend g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_chi_rx_snp_flitpend, tb.u_i_XSTile.l2top.io_chi_rx_snp_flitpend); end
    if (armed && tb.u_g_XSTile.l2top.io_chi_rx_snp_flitpend !== v324) tog[324] = 1'b1; v324 = tb.u_g_XSTile.l2top.io_chi_rx_snp_flitpend;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_chi_rx_snp_flitv !== tb.u_i_XSTile.l2top.io_chi_rx_snp_flitv) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_chi_rx_snp_flitv g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_chi_rx_snp_flitv, tb.u_i_XSTile.l2top.io_chi_rx_snp_flitv); end
    if (armed && tb.u_g_XSTile.l2top.io_chi_rx_snp_flitv !== v325) tog[325] = 1'b1; v325 = tb.u_g_XSTile.l2top.io_chi_rx_snp_flitv;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_chi_rx_snp_flit !== tb.u_i_XSTile.l2top.io_chi_rx_snp_flit) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_chi_rx_snp_flit g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_chi_rx_snp_flit, tb.u_i_XSTile.l2top.io_chi_rx_snp_flit); end
    if (armed && tb.u_g_XSTile.l2top.io_chi_rx_snp_flit !== v326) tog[326] = 1'b1; v326 = tb.u_g_XSTile.l2top.io_chi_rx_snp_flit;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_nodeID !== tb.u_i_XSTile.l2top.io_nodeID) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_nodeID g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_nodeID, tb.u_i_XSTile.l2top.io_nodeID); end
    if (armed && tb.u_g_XSTile.l2top.io_nodeID !== v327) tog[327] = 1'b1; v327 = tb.u_g_XSTile.l2top.io_nodeID;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_pfCtrlFromCore_l2_pf_master_en !== tb.u_i_XSTile.l2top.io_pfCtrlFromCore_l2_pf_master_en) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_pfCtrlFromCore_l2_pf_master_en g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_pfCtrlFromCore_l2_pf_master_en, tb.u_i_XSTile.l2top.io_pfCtrlFromCore_l2_pf_master_en); end
    if (armed && tb.u_g_XSTile.l2top.io_pfCtrlFromCore_l2_pf_master_en !== v328) tog[328] = 1'b1; v328 = tb.u_g_XSTile.l2top.io_pfCtrlFromCore_l2_pf_master_en;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_pfCtrlFromCore_l2_pf_recv_en !== tb.u_i_XSTile.l2top.io_pfCtrlFromCore_l2_pf_recv_en) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_pfCtrlFromCore_l2_pf_recv_en g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_pfCtrlFromCore_l2_pf_recv_en, tb.u_i_XSTile.l2top.io_pfCtrlFromCore_l2_pf_recv_en); end
    if (armed && tb.u_g_XSTile.l2top.io_pfCtrlFromCore_l2_pf_recv_en !== v329) tog[329] = 1'b1; v329 = tb.u_g_XSTile.l2top.io_pfCtrlFromCore_l2_pf_recv_en;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_pfCtrlFromCore_l2_pbop_en !== tb.u_i_XSTile.l2top.io_pfCtrlFromCore_l2_pbop_en) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_pfCtrlFromCore_l2_pbop_en g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_pfCtrlFromCore_l2_pbop_en, tb.u_i_XSTile.l2top.io_pfCtrlFromCore_l2_pbop_en); end
    if (armed && tb.u_g_XSTile.l2top.io_pfCtrlFromCore_l2_pbop_en !== v330) tog[330] = 1'b1; v330 = tb.u_g_XSTile.l2top.io_pfCtrlFromCore_l2_pbop_en;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_pfCtrlFromCore_l2_vbop_en !== tb.u_i_XSTile.l2top.io_pfCtrlFromCore_l2_vbop_en) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_pfCtrlFromCore_l2_vbop_en g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_pfCtrlFromCore_l2_vbop_en, tb.u_i_XSTile.l2top.io_pfCtrlFromCore_l2_vbop_en); end
    if (armed && tb.u_g_XSTile.l2top.io_pfCtrlFromCore_l2_vbop_en !== v331) tog[331] = 1'b1; v331 = tb.u_g_XSTile.l2top.io_pfCtrlFromCore_l2_vbop_en;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_pfCtrlFromCore_l2_pf_delay_latency !== tb.u_i_XSTile.l2top.io_pfCtrlFromCore_l2_pf_delay_latency) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_pfCtrlFromCore_l2_pf_delay_latency g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_pfCtrlFromCore_l2_pf_delay_latency, tb.u_i_XSTile.l2top.io_pfCtrlFromCore_l2_pf_delay_latency); end
    if (armed && tb.u_g_XSTile.l2top.io_pfCtrlFromCore_l2_pf_delay_latency !== v332) tog[332] = 1'b1; v332 = tb.u_g_XSTile.l2top.io_pfCtrlFromCore_l2_pf_delay_latency;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_l2_tlb_req_resp_valid !== tb.u_i_XSTile.l2top.io_l2_tlb_req_resp_valid) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_l2_tlb_req_resp_valid g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_l2_tlb_req_resp_valid, tb.u_i_XSTile.l2top.io_l2_tlb_req_resp_valid); end
    if (armed && tb.u_g_XSTile.l2top.io_l2_tlb_req_resp_valid !== v333) tog[333] = 1'b1; v333 = tb.u_g_XSTile.l2top.io_l2_tlb_req_resp_valid;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_l2_tlb_req_resp_bits_paddr_0 !== tb.u_i_XSTile.l2top.io_l2_tlb_req_resp_bits_paddr_0) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_l2_tlb_req_resp_bits_paddr_0 g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_l2_tlb_req_resp_bits_paddr_0, tb.u_i_XSTile.l2top.io_l2_tlb_req_resp_bits_paddr_0); end
    if (armed && tb.u_g_XSTile.l2top.io_l2_tlb_req_resp_bits_paddr_0 !== v334) tog[334] = 1'b1; v334 = tb.u_g_XSTile.l2top.io_l2_tlb_req_resp_bits_paddr_0;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_l2_tlb_req_resp_bits_pbmt_0 !== tb.u_i_XSTile.l2top.io_l2_tlb_req_resp_bits_pbmt_0) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_l2_tlb_req_resp_bits_pbmt_0 g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_l2_tlb_req_resp_bits_pbmt_0, tb.u_i_XSTile.l2top.io_l2_tlb_req_resp_bits_pbmt_0); end
    if (armed && tb.u_g_XSTile.l2top.io_l2_tlb_req_resp_bits_pbmt_0 !== v335) tog[335] = 1'b1; v335 = tb.u_g_XSTile.l2top.io_l2_tlb_req_resp_bits_pbmt_0;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_l2_tlb_req_resp_bits_miss !== tb.u_i_XSTile.l2top.io_l2_tlb_req_resp_bits_miss) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_l2_tlb_req_resp_bits_miss g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_l2_tlb_req_resp_bits_miss, tb.u_i_XSTile.l2top.io_l2_tlb_req_resp_bits_miss); end
    if (armed && tb.u_g_XSTile.l2top.io_l2_tlb_req_resp_bits_miss !== v336) tog[336] = 1'b1; v336 = tb.u_g_XSTile.l2top.io_l2_tlb_req_resp_bits_miss;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_l2_tlb_req_resp_bits_excp_0_gpf_ld !== tb.u_i_XSTile.l2top.io_l2_tlb_req_resp_bits_excp_0_gpf_ld) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_l2_tlb_req_resp_bits_excp_0_gpf_ld g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_l2_tlb_req_resp_bits_excp_0_gpf_ld, tb.u_i_XSTile.l2top.io_l2_tlb_req_resp_bits_excp_0_gpf_ld); end
    if (armed && tb.u_g_XSTile.l2top.io_l2_tlb_req_resp_bits_excp_0_gpf_ld !== v337) tog[337] = 1'b1; v337 = tb.u_g_XSTile.l2top.io_l2_tlb_req_resp_bits_excp_0_gpf_ld;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_l2_tlb_req_resp_bits_excp_0_pf_ld !== tb.u_i_XSTile.l2top.io_l2_tlb_req_resp_bits_excp_0_pf_ld) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_l2_tlb_req_resp_bits_excp_0_pf_ld g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_l2_tlb_req_resp_bits_excp_0_pf_ld, tb.u_i_XSTile.l2top.io_l2_tlb_req_resp_bits_excp_0_pf_ld); end
    if (armed && tb.u_g_XSTile.l2top.io_l2_tlb_req_resp_bits_excp_0_pf_ld !== v338) tog[338] = 1'b1; v338 = tb.u_g_XSTile.l2top.io_l2_tlb_req_resp_bits_excp_0_pf_ld;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_l2_tlb_req_resp_bits_excp_0_af_ld !== tb.u_i_XSTile.l2top.io_l2_tlb_req_resp_bits_excp_0_af_ld) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_l2_tlb_req_resp_bits_excp_0_af_ld g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_l2_tlb_req_resp_bits_excp_0_af_ld, tb.u_i_XSTile.l2top.io_l2_tlb_req_resp_bits_excp_0_af_ld); end
    if (armed && tb.u_g_XSTile.l2top.io_l2_tlb_req_resp_bits_excp_0_af_ld !== v339) tog[339] = 1'b1; v339 = tb.u_g_XSTile.l2top.io_l2_tlb_req_resp_bits_excp_0_af_ld;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_l2_pmp_resp_ld !== tb.u_i_XSTile.l2top.io_l2_pmp_resp_ld) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_l2_pmp_resp_ld g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_l2_pmp_resp_ld, tb.u_i_XSTile.l2top.io_l2_pmp_resp_ld); end
    if (armed && tb.u_g_XSTile.l2top.io_l2_pmp_resp_ld !== v340) tog[340] = 1'b1; v340 = tb.u_g_XSTile.l2top.io_l2_pmp_resp_ld;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_l2_pmp_resp_mmio !== tb.u_i_XSTile.l2top.io_l2_pmp_resp_mmio) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_l2_pmp_resp_mmio g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_l2_pmp_resp_mmio, tb.u_i_XSTile.l2top.io_l2_pmp_resp_mmio); end
    if (armed && tb.u_g_XSTile.l2top.io_l2_pmp_resp_mmio !== v341) tog[341] = 1'b1; v341 = tb.u_g_XSTile.l2top.io_l2_pmp_resp_mmio;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_dft_ram_hold !== tb.u_i_XSTile.l2top.io_dft_ram_hold) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_dft_ram_hold g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_dft_ram_hold, tb.u_i_XSTile.l2top.io_dft_ram_hold); end
    if (armed && tb.u_g_XSTile.l2top.io_dft_ram_hold !== v342) tog[342] = 1'b1; v342 = tb.u_g_XSTile.l2top.io_dft_ram_hold;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_dft_ram_bypass !== tb.u_i_XSTile.l2top.io_dft_ram_bypass) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_dft_ram_bypass g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_dft_ram_bypass, tb.u_i_XSTile.l2top.io_dft_ram_bypass); end
    if (armed && tb.u_g_XSTile.l2top.io_dft_ram_bypass !== v343) tog[343] = 1'b1; v343 = tb.u_g_XSTile.l2top.io_dft_ram_bypass;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_dft_ram_bp_clken !== tb.u_i_XSTile.l2top.io_dft_ram_bp_clken) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_dft_ram_bp_clken g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_dft_ram_bp_clken, tb.u_i_XSTile.l2top.io_dft_ram_bp_clken); end
    if (armed && tb.u_g_XSTile.l2top.io_dft_ram_bp_clken !== v344) tog[344] = 1'b1; v344 = tb.u_g_XSTile.l2top.io_dft_ram_bp_clken;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_dft_ram_aux_clk !== tb.u_i_XSTile.l2top.io_dft_ram_aux_clk) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_dft_ram_aux_clk g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_dft_ram_aux_clk, tb.u_i_XSTile.l2top.io_dft_ram_aux_clk); end
    if (armed && tb.u_g_XSTile.l2top.io_dft_ram_aux_clk !== v345) tog[345] = 1'b1; v345 = tb.u_g_XSTile.l2top.io_dft_ram_aux_clk;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_dft_ram_aux_ckbp !== tb.u_i_XSTile.l2top.io_dft_ram_aux_ckbp) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_dft_ram_aux_ckbp g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_dft_ram_aux_ckbp, tb.u_i_XSTile.l2top.io_dft_ram_aux_ckbp); end
    if (armed && tb.u_g_XSTile.l2top.io_dft_ram_aux_ckbp !== v346) tog[346] = 1'b1; v346 = tb.u_g_XSTile.l2top.io_dft_ram_aux_ckbp;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_dft_ram_mcp_hold !== tb.u_i_XSTile.l2top.io_dft_ram_mcp_hold) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_dft_ram_mcp_hold g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_dft_ram_mcp_hold, tb.u_i_XSTile.l2top.io_dft_ram_mcp_hold); end
    if (armed && tb.u_g_XSTile.l2top.io_dft_ram_mcp_hold !== v347) tog[347] = 1'b1; v347 = tb.u_g_XSTile.l2top.io_dft_ram_mcp_hold;
    pin_checks++; if (tb.u_g_XSTile.l2top.io_dft_cgen !== tb.u_i_XSTile.l2top.io_dft_cgen) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH l2top.io_dft_cgen g=%h i=%h", $time, tb.u_g_XSTile.l2top.io_dft_cgen, tb.u_i_XSTile.l2top.io_dft_cgen); end
    if (armed && tb.u_g_XSTile.l2top.io_dft_cgen !== v348) tog[348] = 1'b1; v348 = tb.u_g_XSTile.l2top.io_dft_cgen;
    pin_checks++; if (tb.u_g_XSTile.intBuffer.auto_in_0 !== tb.u_i_XSTile.intBuffer.auto_in_0) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH intBuffer.auto_in_0 g=%h i=%h", $time, tb.u_g_XSTile.intBuffer.auto_in_0, tb.u_i_XSTile.intBuffer.auto_in_0); end
    if (armed && tb.u_g_XSTile.intBuffer.auto_in_0 !== v349) tog[349] = 1'b1; v349 = tb.u_g_XSTile.intBuffer.auto_in_0;
    pin_checks++; if (tb.u_g_XSTile.intBuffer.auto_in_1 !== tb.u_i_XSTile.intBuffer.auto_in_1) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH intBuffer.auto_in_1 g=%h i=%h", $time, tb.u_g_XSTile.intBuffer.auto_in_1, tb.u_i_XSTile.intBuffer.auto_in_1); end
    if (armed && tb.u_g_XSTile.intBuffer.auto_in_1 !== v350) tog[350] = 1'b1; v350 = tb.u_g_XSTile.intBuffer.auto_in_1;
    pin_checks++; if (tb.u_g_XSTile.intBuffer_1.auto_in_1_0 !== tb.u_i_XSTile.intBuffer_1.auto_in_1_0) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH intBuffer_1.auto_in_1_0 g=%h i=%h", $time, tb.u_g_XSTile.intBuffer_1.auto_in_1_0, tb.u_i_XSTile.intBuffer_1.auto_in_1_0); end
    if (armed && tb.u_g_XSTile.intBuffer_1.auto_in_1_0 !== v351) tog[351] = 1'b1; v351 = tb.u_g_XSTile.intBuffer_1.auto_in_1_0;
    pin_checks++; if (tb.u_g_XSTile.intBuffer_1.auto_in_0_0 !== tb.u_i_XSTile.intBuffer_1.auto_in_0_0) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH intBuffer_1.auto_in_0_0 g=%h i=%h", $time, tb.u_g_XSTile.intBuffer_1.auto_in_0_0, tb.u_i_XSTile.intBuffer_1.auto_in_0_0); end
    if (armed && tb.u_g_XSTile.intBuffer_1.auto_in_0_0 !== v352) tog[352] = 1'b1; v352 = tb.u_g_XSTile.intBuffer_1.auto_in_0_0;
    pin_checks++; if (tb.u_g_XSTile.intBuffer_2.auto_in_0 !== tb.u_i_XSTile.intBuffer_2.auto_in_0) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH intBuffer_2.auto_in_0 g=%h i=%h", $time, tb.u_g_XSTile.intBuffer_2.auto_in_0, tb.u_i_XSTile.intBuffer_2.auto_in_0); end
    if (armed && tb.u_g_XSTile.intBuffer_2.auto_in_0 !== v353) tog[353] = 1'b1; v353 = tb.u_g_XSTile.intBuffer_2.auto_in_0;
    pin_checks++; if (tb.u_g_XSTile.intBuffer_3.auto_in_0 !== tb.u_i_XSTile.intBuffer_3.auto_in_0) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH intBuffer_3.auto_in_0 g=%h i=%h", $time, tb.u_g_XSTile.intBuffer_3.auto_in_0, tb.u_i_XSTile.intBuffer_3.auto_in_0); end
    if (armed && tb.u_g_XSTile.intBuffer_3.auto_in_0 !== v354) tog[354] = 1'b1; v354 = tb.u_g_XSTile.intBuffer_3.auto_in_0;
    pin_checks++; if (tb.u_g_XSTile.intBuffer_3.auto_in_1 !== tb.u_i_XSTile.intBuffer_3.auto_in_1) begin pin_errors++; if (pin_errors <= 40) $display("[t %0t] PIN MISMATCH intBuffer_3.auto_in_1 g=%h i=%h", $time, tb.u_g_XSTile.intBuffer_3.auto_in_1, tb.u_i_XSTile.intBuffer_3.auto_in_1); end
    if (armed && tb.u_g_XSTile.intBuffer_3.auto_in_1 !== v355) tog[355] = 1'b1; v355 = tb.u_g_XSTile.intBuffer_3.auto_in_1;
    armed = 1;
  end
  final begin
    int nt; nt = 0;
    if (!tog[0]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_buffers_out_a_ready never toggled"); end
    if (!tog[1]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_buffers_out_d_valid never toggled"); end
    if (!tog[2]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_buffers_out_d_bits_opcode never toggled"); end
    if (!tog[3]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_buffers_out_d_bits_param never toggled"); end
    if (!tog[4]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_buffers_out_d_bits_size never toggled"); end
    if (!tog[5]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_buffers_out_d_bits_source never toggled"); end
    if (!tog[6]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_buffers_out_d_bits_sink never toggled"); end
    if (!tog[7]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_buffers_out_d_bits_denied never toggled"); end
    if (!tog[8]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_buffers_out_d_bits_data never toggled"); end
    if (!tog[9]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_buffers_out_d_bits_corrupt never toggled"); end
    if (!tog[10]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_frontendBridge_instr_uncache_out_a_ready never toggled"); end
    if (!tog[11]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_valid never toggled"); end
    if (!tog[12]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_opcode never toggled"); end
    if (!tog[13]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_param never toggled"); end
    if (!tog[14]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_size never toggled"); end
    if (!tog[15]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_source never toggled"); end
    if (!tog[16]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_sink never toggled"); end
    if (!tog[17]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_denied never toggled"); end
    if (!tog[18]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_data never toggled"); end
    if (!tog[19]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_corrupt never toggled"); end
    if (!tog[20]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_valid never toggled"); end
    if (!tog[21]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_opcode never toggled"); end
    if (!tog[22]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_param never toggled"); end
    if (!tog[23]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_size never toggled"); end
    if (!tog[24]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_source never toggled"); end
    if (!tog[25]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_address never toggled"); end
    if (!tog[26]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_mask never toggled"); end
    if (!tog[27]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_data never toggled"); end
    if (!tog[28]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_corrupt never toggled"); end
    if (!tog[29]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_frontendBridge_icachectrl_in_d_ready never toggled"); end
    if (!tog[30]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_frontendBridge_icache_out_a_ready never toggled"); end
    if (!tog[31]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_frontendBridge_icache_out_d_valid never toggled"); end
    if (!tog[32]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_opcode never toggled"); end
    if (!tog[33]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_param never toggled"); end
    if (!tog[34]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_size never toggled"); end
    if (!tog[35]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_source never toggled"); end
    if (!tog[36]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_sink never toggled"); end
    if (!tog[37]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_denied never toggled"); end
    if (!tog[38]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_data never toggled"); end
    if (!tog[39]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_frontendBridge_icache_out_d_bits_corrupt never toggled"); end
    if (!tog[40]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_ptw_to_l2_buffer_out_a_ready never toggled"); end
    if (!tog[41]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_valid never toggled"); end
    if (!tog[42]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_opcode never toggled"); end
    if (!tog[43]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_param never toggled"); end
    if (!tog[44]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_size never toggled"); end
    if (!tog[45]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_source never toggled"); end
    if (!tog[46]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_sink never toggled"); end
    if (!tog[47]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_denied never toggled"); end
    if (!tog[48]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_data never toggled"); end
    if (!tog[49]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_corrupt never toggled"); end
    if (!tog[50]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_beu_local_int_sink_in_0 never toggled"); end
    if (!tog[51]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_nmi_int_sink_in_0 never toggled"); end
    if (!tog[52]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_nmi_int_sink_in_1 never toggled"); end
    if (!tog[53]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_plic_int_sink_in_1_0 never toggled"); end
    if (!tog[54]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_plic_int_sink_in_0_0 never toggled"); end
    if (!tog[55]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_debug_int_sink_in_0 never toggled"); end
    if (!tog[56]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_clint_int_sink_in_0 never toggled"); end
    if (!tog[57]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_clint_int_sink_in_1 never toggled"); end
    if (!tog[58]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_dcache_client_out_a_ready never toggled"); end
    if (!tog[59]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_dcache_client_out_b_valid never toggled"); end
    if (!tog[60]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_dcache_client_out_b_bits_opcode never toggled"); end
    if (!tog[61]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_dcache_client_out_b_bits_param never toggled"); end
    if (!tog[62]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_dcache_client_out_b_bits_size never toggled"); end
    if (!tog[63]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_dcache_client_out_b_bits_source never toggled"); end
    if (!tog[64]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_dcache_client_out_b_bits_address never toggled"); end
    if (!tog[65]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_dcache_client_out_b_bits_mask never toggled"); end
    if (!tog[66]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_dcache_client_out_b_bits_data never toggled"); end
    if (!tog[67]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_dcache_client_out_b_bits_corrupt never toggled"); end
    if (!tog[68]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_dcache_client_out_c_ready never toggled"); end
    if (!tog[69]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_dcache_client_out_d_valid never toggled"); end
    if (!tog[70]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_dcache_client_out_d_bits_opcode never toggled"); end
    if (!tog[71]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_dcache_client_out_d_bits_param never toggled"); end
    if (!tog[72]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_dcache_client_out_d_bits_size never toggled"); end
    if (!tog[73]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_dcache_client_out_d_bits_source never toggled"); end
    if (!tog[74]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_dcache_client_out_d_bits_sink never toggled"); end
    if (!tog[75]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_dcache_client_out_d_bits_denied never toggled"); end
    if (!tog[76]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_dcache_client_out_d_bits_echo_isKeyword never toggled"); end
    if (!tog[77]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_dcache_client_out_d_bits_data never toggled"); end
    if (!tog[78]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_dcache_client_out_d_bits_corrupt never toggled"); end
    if (!tog[79]) begin nt++; $display("PINCOV: core.auto_memBlock_inner_dcache_client_out_e_ready never toggled"); end
    if (!tog[80]) begin nt++; $display("PINCOV: core.io_hartId never toggled"); end
    if (!tog[81]) begin nt++; $display("PINCOV: core.io_msiInfo_valid never toggled"); end
    if (!tog[82]) begin nt++; $display("PINCOV: core.io_msiInfo_bits never toggled"); end
    if (!tog[83]) begin nt++; $display("PINCOV: core.io_clintTime_valid never toggled"); end
    if (!tog[84]) begin nt++; $display("PINCOV: core.io_clintTime_bits never toggled"); end
    if (!tog[85]) begin nt++; $display("PINCOV: core.io_reset_vector never toggled"); end
    if (!tog[86]) begin nt++; $display("PINCOV: core.io_l2_flush_done never toggled"); end
    if (!tog[87]) begin nt++; $display("PINCOV: core.io_traceCoreInterface_fromEncoder_enable never toggled"); end
    if (!tog[88]) begin nt++; $display("PINCOV: core.io_traceCoreInterface_fromEncoder_stall never toggled"); end
    if (!tog[89]) begin nt++; $display("PINCOV: core.io_perfEvents_1_value never toggled"); end
    if (!tog[90]) begin nt++; $display("PINCOV: core.io_perfEvents_2_value never toggled"); end
    if (!tog[91]) begin nt++; $display("PINCOV: core.io_perfEvents_3_value never toggled"); end
    if (!tog[92]) begin nt++; $display("PINCOV: core.io_perfEvents_4_value never toggled"); end
    if (!tog[93]) begin nt++; $display("PINCOV: core.io_perfEvents_5_value never toggled"); end
    if (!tog[94]) begin nt++; $display("PINCOV: core.io_perfEvents_6_value never toggled"); end
    if (!tog[95]) begin nt++; $display("PINCOV: core.io_perfEvents_7_value never toggled"); end
    if (!tog[96]) begin nt++; $display("PINCOV: core.io_perfEvents_8_value never toggled"); end
    if (!tog[97]) begin nt++; $display("PINCOV: core.io_perfEvents_9_value never toggled"); end
    if (!tog[98]) begin nt++; $display("PINCOV: core.io_perfEvents_10_value never toggled"); end
    if (!tog[99]) begin nt++; $display("PINCOV: core.io_perfEvents_11_value never toggled"); end
    if (!tog[100]) begin nt++; $display("PINCOV: core.io_perfEvents_12_value never toggled"); end
    if (!tog[101]) begin nt++; $display("PINCOV: core.io_perfEvents_13_value never toggled"); end
    if (!tog[102]) begin nt++; $display("PINCOV: core.io_perfEvents_14_value never toggled"); end
    if (!tog[103]) begin nt++; $display("PINCOV: core.io_perfEvents_15_value never toggled"); end
    if (!tog[104]) begin nt++; $display("PINCOV: core.io_perfEvents_16_value never toggled"); end
    if (!tog[105]) begin nt++; $display("PINCOV: core.io_perfEvents_17_value never toggled"); end
    if (!tog[106]) begin nt++; $display("PINCOV: core.io_perfEvents_18_value never toggled"); end
    if (!tog[107]) begin nt++; $display("PINCOV: core.io_perfEvents_19_value never toggled"); end
    if (!tog[108]) begin nt++; $display("PINCOV: core.io_perfEvents_20_value never toggled"); end
    if (!tog[109]) begin nt++; $display("PINCOV: core.io_perfEvents_21_value never toggled"); end
    if (!tog[110]) begin nt++; $display("PINCOV: core.io_perfEvents_22_value never toggled"); end
    if (!tog[111]) begin nt++; $display("PINCOV: core.io_perfEvents_23_value never toggled"); end
    if (!tog[112]) begin nt++; $display("PINCOV: core.io_perfEvents_24_value never toggled"); end
    if (!tog[113]) begin nt++; $display("PINCOV: core.io_perfEvents_25_value never toggled"); end
    if (!tog[114]) begin nt++; $display("PINCOV: core.io_perfEvents_26_value never toggled"); end
    if (!tog[115]) begin nt++; $display("PINCOV: core.io_perfEvents_27_value never toggled"); end
    if (!tog[116]) begin nt++; $display("PINCOV: core.io_perfEvents_28_value never toggled"); end
    if (!tog[117]) begin nt++; $display("PINCOV: core.io_perfEvents_29_value never toggled"); end
    if (!tog[118]) begin nt++; $display("PINCOV: core.io_perfEvents_30_value never toggled"); end
    if (!tog[119]) begin nt++; $display("PINCOV: core.io_perfEvents_31_value never toggled"); end
    if (!tog[120]) begin nt++; $display("PINCOV: core.io_perfEvents_32_value never toggled"); end
    if (!tog[121]) begin nt++; $display("PINCOV: core.io_perfEvents_33_value never toggled"); end
    if (!tog[122]) begin nt++; $display("PINCOV: core.io_perfEvents_34_value never toggled"); end
    if (!tog[123]) begin nt++; $display("PINCOV: core.io_perfEvents_35_value never toggled"); end
    if (!tog[124]) begin nt++; $display("PINCOV: core.io_perfEvents_36_value never toggled"); end
    if (!tog[125]) begin nt++; $display("PINCOV: core.io_perfEvents_37_value never toggled"); end
    if (!tog[126]) begin nt++; $display("PINCOV: core.io_perfEvents_38_value never toggled"); end
    if (!tog[127]) begin nt++; $display("PINCOV: core.io_perfEvents_39_value never toggled"); end
    if (!tog[128]) begin nt++; $display("PINCOV: core.io_perfEvents_40_value never toggled"); end
    if (!tog[129]) begin nt++; $display("PINCOV: core.io_perfEvents_41_value never toggled"); end
    if (!tog[130]) begin nt++; $display("PINCOV: core.io_perfEvents_42_value never toggled"); end
    if (!tog[131]) begin nt++; $display("PINCOV: core.io_perfEvents_43_value never toggled"); end
    if (!tog[132]) begin nt++; $display("PINCOV: core.io_perfEvents_44_value never toggled"); end
    if (!tog[133]) begin nt++; $display("PINCOV: core.io_perfEvents_45_value never toggled"); end
    if (!tog[134]) begin nt++; $display("PINCOV: core.io_perfEvents_46_value never toggled"); end
    if (!tog[135]) begin nt++; $display("PINCOV: core.io_perfEvents_47_value never toggled"); end
    if (!tog[136]) begin nt++; $display("PINCOV: core.io_perfEvents_48_value never toggled"); end
    if (!tog[137]) begin nt++; $display("PINCOV: core.io_perfEvents_49_value never toggled"); end
    if (!tog[138]) begin nt++; $display("PINCOV: core.io_perfEvents_50_value never toggled"); end
    if (!tog[139]) begin nt++; $display("PINCOV: core.io_perfEvents_51_value never toggled"); end
    if (!tog[140]) begin nt++; $display("PINCOV: core.io_perfEvents_52_value never toggled"); end
    if (!tog[141]) begin nt++; $display("PINCOV: core.io_perfEvents_53_value never toggled"); end
    if (!tog[142]) begin nt++; $display("PINCOV: core.io_perfEvents_54_value never toggled"); end
    if (!tog[143]) begin nt++; $display("PINCOV: core.io_perfEvents_55_value never toggled"); end
    if (!tog[144]) begin nt++; $display("PINCOV: core.io_perfEvents_56_value never toggled"); end
    if (!tog[145]) begin nt++; $display("PINCOV: core.io_perfEvents_57_value never toggled"); end
    if (!tog[146]) begin nt++; $display("PINCOV: core.io_perfEvents_58_value never toggled"); end
    if (!tog[147]) begin nt++; $display("PINCOV: core.io_perfEvents_59_value never toggled"); end
    if (!tog[148]) begin nt++; $display("PINCOV: core.io_perfEvents_60_value never toggled"); end
    if (!tog[149]) begin nt++; $display("PINCOV: core.io_perfEvents_61_value never toggled"); end
    if (!tog[150]) begin nt++; $display("PINCOV: core.io_perfEvents_62_value never toggled"); end
    if (!tog[151]) begin nt++; $display("PINCOV: core.io_perfEvents_63_value never toggled"); end
    if (!tog[152]) begin nt++; $display("PINCOV: core.io_perfEvents_64_value never toggled"); end
    if (!tog[153]) begin nt++; $display("PINCOV: core.io_perfEvents_65_value never toggled"); end
    if (!tog[154]) begin nt++; $display("PINCOV: core.io_perfEvents_66_value never toggled"); end
    if (!tog[155]) begin nt++; $display("PINCOV: core.io_perfEvents_67_value never toggled"); end
    if (!tog[156]) begin nt++; $display("PINCOV: core.io_perfEvents_68_value never toggled"); end
    if (!tog[157]) begin nt++; $display("PINCOV: core.io_l2_hint_valid never toggled"); end
    if (!tog[158]) begin nt++; $display("PINCOV: core.io_l2_hint_bits_sourceId never toggled"); end
    if (!tog[159]) begin nt++; $display("PINCOV: core.io_l2_hint_bits_isKeyword never toggled"); end
    if (!tog[160]) begin nt++; $display("PINCOV: core.io_l2_tlb_req_req_valid never toggled"); end
    if (!tog[161]) begin nt++; $display("PINCOV: core.io_l2_tlb_req_req_bits_vaddr never toggled"); end
    if (!tog[162]) begin nt++; $display("PINCOV: core.io_l2_tlb_req_req_bits_cmd never toggled"); end
    if (!tog[163]) begin nt++; $display("PINCOV: core.io_l2_tlb_req_req_bits_kill never toggled"); end
    if (!tog[164]) begin nt++; $display("PINCOV: core.io_l2_tlb_req_req_bits_isPrefetch never toggled"); end
    if (!tog[165]) begin nt++; $display("PINCOV: core.io_l2_tlb_req_req_bits_no_translate never toggled"); end
    if (!tog[166]) begin nt++; $display("PINCOV: core.io_debugTopDown_l2MissMatch never toggled"); end
    if (!tog[167]) begin nt++; $display("PINCOV: core.io_debugTopDown_l3MissMatch never toggled"); end
    if (!tog[168]) begin nt++; $display("PINCOV: core.io_topDownInfo_l2Miss never toggled"); end
    if (!tog[169]) begin nt++; $display("PINCOV: core.io_topDownInfo_l3Miss never toggled"); end
    if (!tog[170]) begin nt++; $display("PINCOV: core.io_dft_ram_hold never toggled"); end
    if (!tog[171]) begin nt++; $display("PINCOV: core.io_dft_ram_bypass never toggled"); end
    if (!tog[172]) begin nt++; $display("PINCOV: core.io_dft_ram_bp_clken never toggled"); end
    if (!tog[173]) begin nt++; $display("PINCOV: core.io_dft_ram_aux_clk never toggled"); end
    if (!tog[174]) begin nt++; $display("PINCOV: core.io_dft_ram_aux_ckbp never toggled"); end
    if (!tog[175]) begin nt++; $display("PINCOV: core.io_dft_ram_mcp_hold never toggled"); end
    if (!tog[176]) begin nt++; $display("PINCOV: core.io_dft_cgen never toggled"); end
    if (!tog[177]) begin nt++; $display("PINCOV: l2top.auto_inner_buffers_out_a_ready never toggled"); end
    if (!tog[178]) begin nt++; $display("PINCOV: l2top.auto_inner_buffers_out_d_valid never toggled"); end
    if (!tog[179]) begin nt++; $display("PINCOV: l2top.auto_inner_buffers_out_d_bits_opcode never toggled"); end
    if (!tog[180]) begin nt++; $display("PINCOV: l2top.auto_inner_buffers_out_d_bits_param never toggled"); end
    if (!tog[181]) begin nt++; $display("PINCOV: l2top.auto_inner_buffers_out_d_bits_size never toggled"); end
    if (!tog[182]) begin nt++; $display("PINCOV: l2top.auto_inner_buffers_out_d_bits_source never toggled"); end
    if (!tog[183]) begin nt++; $display("PINCOV: l2top.auto_inner_buffers_out_d_bits_sink never toggled"); end
    if (!tog[184]) begin nt++; $display("PINCOV: l2top.auto_inner_buffers_out_d_bits_denied never toggled"); end
    if (!tog[185]) begin nt++; $display("PINCOV: l2top.auto_inner_buffers_out_d_bits_data never toggled"); end
    if (!tog[186]) begin nt++; $display("PINCOV: l2top.auto_inner_buffers_out_d_bits_corrupt never toggled"); end
    if (!tog[187]) begin nt++; $display("PINCOV: l2top.auto_inner_buffers_in_a_valid never toggled"); end
    if (!tog[188]) begin nt++; $display("PINCOV: l2top.auto_inner_buffers_in_a_bits_opcode never toggled"); end
    if (!tog[189]) begin nt++; $display("PINCOV: l2top.auto_inner_buffers_in_a_bits_param never toggled"); end
    if (!tog[190]) begin nt++; $display("PINCOV: l2top.auto_inner_buffers_in_a_bits_size never toggled"); end
    if (!tog[191]) begin nt++; $display("PINCOV: l2top.auto_inner_buffers_in_a_bits_source never toggled"); end
    if (!tog[192]) begin nt++; $display("PINCOV: l2top.auto_inner_buffers_in_a_bits_address never toggled"); end
    if (!tog[193]) begin nt++; $display("PINCOV: l2top.auto_inner_buffers_in_a_bits_user_memBackType_MM never toggled"); end
    if (!tog[194]) begin nt++; $display("PINCOV: l2top.auto_inner_buffers_in_a_bits_user_memPageType_NC never toggled"); end
    if (!tog[195]) begin nt++; $display("PINCOV: l2top.auto_inner_buffers_in_a_bits_mask never toggled"); end
    if (!tog[196]) begin nt++; $display("PINCOV: l2top.auto_inner_buffers_in_a_bits_data never toggled"); end
    if (!tog[197]) begin nt++; $display("PINCOV: l2top.auto_inner_buffers_in_a_bits_corrupt never toggled"); end
    if (!tog[198]) begin nt++; $display("PINCOV: l2top.auto_inner_buffers_in_d_ready never toggled"); end
    if (!tog[199]) begin nt++; $display("PINCOV: l2top.auto_inner_l2cache_pf_recv_in_addr never toggled"); end
    if (!tog[200]) begin nt++; $display("PINCOV: l2top.auto_inner_l2cache_pf_recv_in_pf_source never toggled"); end
    if (!tog[201]) begin nt++; $display("PINCOV: l2top.auto_inner_l2cache_pf_recv_in_addr_valid never toggled"); end
    if (!tog[202]) begin nt++; $display("PINCOV: l2top.auto_inner_i_mmio_buffer_in_a_valid never toggled"); end
    if (!tog[203]) begin nt++; $display("PINCOV: l2top.auto_inner_i_mmio_buffer_in_a_bits_param never toggled"); end
    if (!tog[204]) begin nt++; $display("PINCOV: l2top.auto_inner_i_mmio_buffer_in_a_bits_address never toggled"); end
    if (!tog[205]) begin nt++; $display("PINCOV: l2top.auto_inner_i_mmio_buffer_in_a_bits_user_memPageType_NC never toggled"); end
    if (!tog[206]) begin nt++; $display("PINCOV: l2top.auto_inner_i_mmio_buffer_in_a_bits_user_memBackType_MM never toggled"); end
    if (!tog[207]) begin nt++; $display("PINCOV: l2top.auto_inner_i_mmio_buffer_in_a_bits_corrupt never toggled"); end
    if (!tog[208]) begin nt++; $display("PINCOV: l2top.auto_inner_i_mmio_buffer_in_d_ready never toggled"); end
    if (!tog[209]) begin nt++; $display("PINCOV: l2top.auto_inner_ptw_to_l2_buffer_in_a_valid never toggled"); end
    if (!tog[210]) begin nt++; $display("PINCOV: l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_opcode never toggled"); end
    if (!tog[211]) begin nt++; $display("PINCOV: l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_param never toggled"); end
    if (!tog[212]) begin nt++; $display("PINCOV: l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_size never toggled"); end
    if (!tog[213]) begin nt++; $display("PINCOV: l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_source never toggled"); end
    if (!tog[214]) begin nt++; $display("PINCOV: l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_address never toggled"); end
    if (!tog[215]) begin nt++; $display("PINCOV: l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_user_reqSource never toggled"); end
    if (!tog[216]) begin nt++; $display("PINCOV: l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_mask never toggled"); end
    if (!tog[217]) begin nt++; $display("PINCOV: l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_data never toggled"); end
    if (!tog[218]) begin nt++; $display("PINCOV: l2top.auto_inner_ptw_to_l2_buffer_in_a_bits_corrupt never toggled"); end
    if (!tog[219]) begin nt++; $display("PINCOV: l2top.auto_inner_ptw_to_l2_buffer_in_d_ready never toggled"); end
    if (!tog[220]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_1_a_valid never toggled"); end
    if (!tog[221]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_1_a_bits_opcode never toggled"); end
    if (!tog[222]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_1_a_bits_param never toggled"); end
    if (!tog[223]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_1_a_bits_size never toggled"); end
    if (!tog[224]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_1_a_bits_source never toggled"); end
    if (!tog[225]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_1_a_bits_address never toggled"); end
    if (!tog[226]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_1_a_bits_user_alias never toggled"); end
    if (!tog[227]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_1_a_bits_user_reqSource never toggled"); end
    if (!tog[228]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_1_a_bits_user_needHint never toggled"); end
    if (!tog[229]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_1_a_bits_mask never toggled"); end
    if (!tog[230]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_1_a_bits_data never toggled"); end
    if (!tog[231]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_1_a_bits_corrupt never toggled"); end
    if (!tog[232]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_1_d_ready never toggled"); end
    if (!tog[233]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_0_a_valid never toggled"); end
    if (!tog[234]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_0_a_bits_opcode never toggled"); end
    if (!tog[235]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_0_a_bits_param never toggled"); end
    if (!tog[236]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_0_a_bits_size never toggled"); end
    if (!tog[237]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_0_a_bits_source never toggled"); end
    if (!tog[238]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_0_a_bits_address never toggled"); end
    if (!tog[239]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_0_a_bits_user_alias never toggled"); end
    if (!tog[240]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_0_a_bits_user_vaddr never toggled"); end
    if (!tog[241]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_0_a_bits_user_reqSource never toggled"); end
    if (!tog[242]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_0_a_bits_user_needHint never toggled"); end
    if (!tog[243]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_0_a_bits_echo_isKeyword never toggled"); end
    if (!tog[244]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_0_a_bits_mask never toggled"); end
    if (!tog[245]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_0_a_bits_data never toggled"); end
    if (!tog[246]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_0_a_bits_corrupt never toggled"); end
    if (!tog[247]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_0_b_ready never toggled"); end
    if (!tog[248]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_0_c_valid never toggled"); end
    if (!tog[249]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_0_c_bits_opcode never toggled"); end
    if (!tog[250]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_0_c_bits_param never toggled"); end
    if (!tog[251]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_0_c_bits_size never toggled"); end
    if (!tog[252]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_0_c_bits_source never toggled"); end
    if (!tog[253]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_0_c_bits_address never toggled"); end
    if (!tog[254]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_0_c_bits_user_alias never toggled"); end
    if (!tog[255]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_0_c_bits_user_vaddr never toggled"); end
    if (!tog[256]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_0_c_bits_user_reqSource never toggled"); end
    if (!tog[257]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_0_c_bits_user_needHint never toggled"); end
    if (!tog[258]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_0_c_bits_echo_isKeyword never toggled"); end
    if (!tog[259]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_0_c_bits_data never toggled"); end
    if (!tog[260]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_0_c_bits_corrupt never toggled"); end
    if (!tog[261]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_0_d_ready never toggled"); end
    if (!tog[262]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_0_e_valid never toggled"); end
    if (!tog[263]) begin nt++; $display("PINCOV: l2top.auto_inner_logger_in_0_e_bits_sink never toggled"); end
    if (!tog[264]) begin nt++; $display("PINCOV: l2top.auto_inner_nmi_int_in_0 never toggled"); end
    if (!tog[265]) begin nt++; $display("PINCOV: l2top.auto_inner_nmi_int_in_1 never toggled"); end
    if (!tog[266]) begin nt++; $display("PINCOV: l2top.auto_inner_plic_int_in_1_0 never toggled"); end
    if (!tog[267]) begin nt++; $display("PINCOV: l2top.auto_inner_plic_int_in_0_0 never toggled"); end
    if (!tog[268]) begin nt++; $display("PINCOV: l2top.auto_inner_debug_int_in_0 never toggled"); end
    if (!tog[269]) begin nt++; $display("PINCOV: l2top.auto_inner_clint_int_in_0 never toggled"); end
    if (!tog[270]) begin nt++; $display("PINCOV: l2top.auto_inner_clint_int_in_1 never toggled"); end
    if (!tog[271]) begin nt++; $display("PINCOV: l2top.io_beu_errors_icache_ecc_error_valid never toggled"); end
    if (!tog[272]) begin nt++; $display("PINCOV: l2top.io_beu_errors_icache_ecc_error_bits never toggled"); end
    if (!tog[273]) begin nt++; $display("PINCOV: l2top.io_beu_errors_dcache_ecc_error_valid never toggled"); end
    if (!tog[274]) begin nt++; $display("PINCOV: l2top.io_beu_errors_dcache_ecc_error_bits never toggled"); end
    if (!tog[275]) begin nt++; $display("PINCOV: l2top.io_beu_errors_uncache_ecc_error_valid never toggled"); end
    if (!tog[276]) begin nt++; $display("PINCOV: l2top.io_beu_errors_uncache_ecc_error_bits never toggled"); end
    if (!tog[277]) begin nt++; $display("PINCOV: l2top.io_reset_vector_fromTile never toggled"); end
    if (!tog[278]) begin nt++; $display("PINCOV: l2top.io_hartId_fromTile never toggled"); end
    if (!tog[279]) begin nt++; $display("PINCOV: l2top.io_msiInfo_fromTile_valid never toggled"); end
    if (!tog[280]) begin nt++; $display("PINCOV: l2top.io_msiInfo_fromTile_bits never toggled"); end
    if (!tog[281]) begin nt++; $display("PINCOV: l2top.io_msiAck_fromCore never toggled"); end
    if (!tog[282]) begin nt++; $display("PINCOV: l2top.io_cpu_halt_fromCore never toggled"); end
    if (!tog[283]) begin nt++; $display("PINCOV: l2top.io_cpu_critical_error_fromCore never toggled"); end
    if (!tog[284]) begin nt++; $display("PINCOV: l2top.io_hartIsInReset_resetInFrontend never toggled"); end
    if (!tog[285]) begin nt++; $display("PINCOV: l2top.io_traceCoreInterface_fromCore_toEncoder_priv never toggled"); end
    if (!tog[286]) begin nt++; $display("PINCOV: l2top.io_traceCoreInterface_fromCore_toEncoder_mstatus never toggled"); end
    if (!tog[287]) begin nt++; $display("PINCOV: l2top.io_traceCoreInterface_fromCore_toEncoder_trap_cause never toggled"); end
    if (!tog[288]) begin nt++; $display("PINCOV: l2top.io_traceCoreInterface_fromCore_toEncoder_trap_tval never toggled"); end
    if (!tog[289]) begin nt++; $display("PINCOV: l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_valid never toggled"); end
    if (!tog[290]) begin nt++; $display("PINCOV: l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iaddr never toggled"); end
    if (!tog[291]) begin nt++; $display("PINCOV: l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_itype never toggled"); end
    if (!tog[292]) begin nt++; $display("PINCOV: l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iretire never toggled"); end
    if (!tog[293]) begin nt++; $display("PINCOV: l2top.io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_ilastsize never toggled"); end
    if (!tog[294]) begin nt++; $display("PINCOV: l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_valid never toggled"); end
    if (!tog[295]) begin nt++; $display("PINCOV: l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iaddr never toggled"); end
    if (!tog[296]) begin nt++; $display("PINCOV: l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_itype never toggled"); end
    if (!tog[297]) begin nt++; $display("PINCOV: l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iretire never toggled"); end
    if (!tog[298]) begin nt++; $display("PINCOV: l2top.io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_ilastsize never toggled"); end
    if (!tog[299]) begin nt++; $display("PINCOV: l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_valid never toggled"); end
    if (!tog[300]) begin nt++; $display("PINCOV: l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iaddr never toggled"); end
    if (!tog[301]) begin nt++; $display("PINCOV: l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_itype never toggled"); end
    if (!tog[302]) begin nt++; $display("PINCOV: l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iretire never toggled"); end
    if (!tog[303]) begin nt++; $display("PINCOV: l2top.io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_ilastsize never toggled"); end
    if (!tog[304]) begin nt++; $display("PINCOV: l2top.io_traceCoreInterface_toTile_fromEncoder_enable never toggled"); end
    if (!tog[305]) begin nt++; $display("PINCOV: l2top.io_traceCoreInterface_toTile_fromEncoder_stall never toggled"); end
    if (!tog[306]) begin nt++; $display("PINCOV: l2top.io_debugTopDown_robHeadPaddr_valid never toggled"); end
    if (!tog[307]) begin nt++; $display("PINCOV: l2top.io_debugTopDown_robHeadPaddr_bits never toggled"); end
    if (!tog[308]) begin nt++; $display("PINCOV: l2top.io_l3Miss_fromTile never toggled"); end
    if (!tog[309]) begin nt++; $display("PINCOV: l2top.io_clintTime_fromTile_valid never toggled"); end
    if (!tog[310]) begin nt++; $display("PINCOV: l2top.io_clintTime_fromTile_bits never toggled"); end
    if (!tog[311]) begin nt++; $display("PINCOV: l2top.io_chi_rxsactive never toggled"); end
    if (!tog[312]) begin nt++; $display("PINCOV: l2top.io_chi_syscoack never toggled"); end
    if (!tog[313]) begin nt++; $display("PINCOV: l2top.io_chi_tx_linkactiveack never toggled"); end
    if (!tog[314]) begin nt++; $display("PINCOV: l2top.io_chi_tx_req_lcrdv never toggled"); end
    if (!tog[315]) begin nt++; $display("PINCOV: l2top.io_chi_tx_rsp_lcrdv never toggled"); end
    if (!tog[316]) begin nt++; $display("PINCOV: l2top.io_chi_tx_dat_lcrdv never toggled"); end
    if (!tog[317]) begin nt++; $display("PINCOV: l2top.io_chi_rx_linkactivereq never toggled"); end
    if (!tog[318]) begin nt++; $display("PINCOV: l2top.io_chi_rx_rsp_flitpend never toggled"); end
    if (!tog[319]) begin nt++; $display("PINCOV: l2top.io_chi_rx_rsp_flitv never toggled"); end
    if (!tog[320]) begin nt++; $display("PINCOV: l2top.io_chi_rx_rsp_flit never toggled"); end
    if (!tog[321]) begin nt++; $display("PINCOV: l2top.io_chi_rx_dat_flitpend never toggled"); end
    if (!tog[322]) begin nt++; $display("PINCOV: l2top.io_chi_rx_dat_flitv never toggled"); end
    if (!tog[323]) begin nt++; $display("PINCOV: l2top.io_chi_rx_dat_flit never toggled"); end
    if (!tog[324]) begin nt++; $display("PINCOV: l2top.io_chi_rx_snp_flitpend never toggled"); end
    if (!tog[325]) begin nt++; $display("PINCOV: l2top.io_chi_rx_snp_flitv never toggled"); end
    if (!tog[326]) begin nt++; $display("PINCOV: l2top.io_chi_rx_snp_flit never toggled"); end
    if (!tog[327]) begin nt++; $display("PINCOV: l2top.io_nodeID never toggled"); end
    if (!tog[328]) begin nt++; $display("PINCOV: l2top.io_pfCtrlFromCore_l2_pf_master_en never toggled"); end
    if (!tog[329]) begin nt++; $display("PINCOV: l2top.io_pfCtrlFromCore_l2_pf_recv_en never toggled"); end
    if (!tog[330]) begin nt++; $display("PINCOV: l2top.io_pfCtrlFromCore_l2_pbop_en never toggled"); end
    if (!tog[331]) begin nt++; $display("PINCOV: l2top.io_pfCtrlFromCore_l2_vbop_en never toggled"); end
    if (!tog[332]) begin nt++; $display("PINCOV: l2top.io_pfCtrlFromCore_l2_pf_delay_latency never toggled"); end
    if (!tog[333]) begin nt++; $display("PINCOV: l2top.io_l2_tlb_req_resp_valid never toggled"); end
    if (!tog[334]) begin nt++; $display("PINCOV: l2top.io_l2_tlb_req_resp_bits_paddr_0 never toggled"); end
    if (!tog[335]) begin nt++; $display("PINCOV: l2top.io_l2_tlb_req_resp_bits_pbmt_0 never toggled"); end
    if (!tog[336]) begin nt++; $display("PINCOV: l2top.io_l2_tlb_req_resp_bits_miss never toggled"); end
    if (!tog[337]) begin nt++; $display("PINCOV: l2top.io_l2_tlb_req_resp_bits_excp_0_gpf_ld never toggled"); end
    if (!tog[338]) begin nt++; $display("PINCOV: l2top.io_l2_tlb_req_resp_bits_excp_0_pf_ld never toggled"); end
    if (!tog[339]) begin nt++; $display("PINCOV: l2top.io_l2_tlb_req_resp_bits_excp_0_af_ld never toggled"); end
    if (!tog[340]) begin nt++; $display("PINCOV: l2top.io_l2_pmp_resp_ld never toggled"); end
    if (!tog[341]) begin nt++; $display("PINCOV: l2top.io_l2_pmp_resp_mmio never toggled"); end
    if (!tog[342]) begin nt++; $display("PINCOV: l2top.io_dft_ram_hold never toggled"); end
    if (!tog[343]) begin nt++; $display("PINCOV: l2top.io_dft_ram_bypass never toggled"); end
    if (!tog[344]) begin nt++; $display("PINCOV: l2top.io_dft_ram_bp_clken never toggled"); end
    if (!tog[345]) begin nt++; $display("PINCOV: l2top.io_dft_ram_aux_clk never toggled"); end
    if (!tog[346]) begin nt++; $display("PINCOV: l2top.io_dft_ram_aux_ckbp never toggled"); end
    if (!tog[347]) begin nt++; $display("PINCOV: l2top.io_dft_ram_mcp_hold never toggled"); end
    if (!tog[348]) begin nt++; $display("PINCOV: l2top.io_dft_cgen never toggled"); end
    if (!tog[349]) begin nt++; $display("PINCOV: intBuffer.auto_in_0 never toggled"); end
    if (!tog[350]) begin nt++; $display("PINCOV: intBuffer.auto_in_1 never toggled"); end
    if (!tog[351]) begin nt++; $display("PINCOV: intBuffer_1.auto_in_1_0 never toggled"); end
    if (!tog[352]) begin nt++; $display("PINCOV: intBuffer_1.auto_in_0_0 never toggled"); end
    if (!tog[353]) begin nt++; $display("PINCOV: intBuffer_2.auto_in_0 never toggled"); end
    if (!tog[354]) begin nt++; $display("PINCOV: intBuffer_3.auto_in_0 never toggled"); end
    if (!tog[355]) begin nt++; $display("PINCOV: intBuffer_3.auto_in_1 never toggled"); end
    $display("PINCHECK XSTile: pins=356 checks=%0d errors=%0d never_toggled=%0d", pin_checks, pin_errors, nt);
  end
endmodule
bind tb tb_pins_XSTile u_tb_pins_XSTile ();
