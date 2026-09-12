verdiSetActWin -dock widgetDock_<Decl._Tree>
simSetSimulator "-vcssv" -exec \
           "/home/eda/xs-env/xs-v2-sv/verif/study/ExeUnit_int0/simv" -args
debImport "-dbdir" \
          "/home/eda/xs-env/xs-v2-sv/verif/study/ExeUnit_int0/simv.daidir"
debLoadSimResult /home/eda/xs-env/xs-v2-sv/verif/study/ExeUnit_int0/novas.fsdb
wvCreateWindow
verdiSetActWin -win $_nWave2
verdiWindowResize -win $_Verdi_1 "510" "153" "900" "700"
srcHBSelect "tb.u_exe" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBSelect "tb.u_exe" -win $_nTrace1
srcSetScope "tb.u_exe" -delim "." -win $_nTrace1
srcHBSelect "tb.u_exe" -win $_nTrace1
srcDeselectAll -win $_nTrace1
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
verdiSetActWin -dock widgetDock_<Inst._Tree>
verdiWindowResize -win $_Verdi_1 "868" "123" "900" "700"
srcDeselectAll -win $_nTrace1
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
verdiWindowResize -win $_Verdi_1 "868" "27" "900" "798"
verdiWindowResize -win $_Verdi_1 "868" "27" "900" "998"
verdiWindowResize -win $_Verdi_1 "868" "27" "1050" "998"
verdiWindowResize -win $_Verdi_1 "868" "27" "1049" "998"
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -win $_nTrace1 -range {89 94 3 1 6 1} -backward
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
