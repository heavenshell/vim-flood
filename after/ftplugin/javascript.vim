let s:save_cpo = &cpo
set cpo&vim

if flood#is_flow_project() == 1
  setlocal omnifunc=flood#complete
endif

let &cpo = s:save_cpo
unlet s:save_cpo

