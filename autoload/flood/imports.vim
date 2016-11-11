" File: flood#imports.vim
" Author: Shinya Ohyanagi <sohyanagi@gmail.com>
" Version:  0.1
" WebPage:  http://github.com/heavenshell/vim-flood/
" Description: Vim plugin for Facebook FlowType.
" License: BSD, see LICENSE for more details.

let s:save_cpo = &cpo
set cpo&vim

function! s:parse(responses)
  let outputs = []
  for k in keys(a:responses)
    for v in a:responses[k]['requirements']
      call add(outputs, {
        \ 'filename': v['import'],
        \ 'lnum': v['start'],
        \ 'text': v['path']
        \ })
    endfor
  endfor

  return outputs
endfunction

function! s:imports_callback(msg)
  try
    " {"current/buffer.js":["use/a.js, use/b.js"]}
    let responses = json_decode(a:msg)
    let outputs = s:parse(responses)

    call setloclist(0, outputs, 'r')
    if len(outputs) > 0 && g:flood_enable_quickfix == 1
      lwindow
    endif
  catch
    echomsg 'Flow server is not running.'
    call flood#log(a:msg)
  endtry
endfunction

" Execute `flow get-imports --json index.js`.
function! flood#imports#run() abort
  if exists('s:job') && job_status(s:job) != 'stop'
    call job_stop(s:job)
  endif

  let file = expand('%:p')
  let cmd = printf('%s get-imports --json %s', flood#flowbin(), file)
  let s:job = job_start(cmd, {
        \ 'callback': {c, m -> s:imports_callback(m)},
        \ })
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
