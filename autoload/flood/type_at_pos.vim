" File: flood#type_at_pos.vim
" Author: Shinya Ohyanagi <sohyanagi@gmail.com>
" WebPage:  http://github.com/heavenshell/vim-flood/
" Description: Vim plugin for Facebook FlowType.
" License: BSD, see LICENSE for more details.
let s:save_cpo = &cpo
set cpo&vim

function! s:type_at_pos_callback(msg, cword)
  try
    let json = json_decode(a:msg)
    let msg = a:cword . ': ' . json['type']
    let size = &columns
    if len(msg) >= size
      echo msg[0: size - 5] . '...'
    else
      echo msg
    endif
  catch
    echomsg '[Flood] type-at-pos raised exception.'
    call flood#log(v:exception)
    call flood#log(a:msg)
  endtry
endfunction

function! flood#type_at_pos#run()
  if exists('s:job') && job_status(s:job) != 'stop'
    call job_stop(s:job)
  endif

  let bin = flood#flowbin()
  let file = expand('%:p')
  let line = line('.')
  let offset = col('.')
  let cmd = printf('%s type-at-pos %s %d %d --json', bin, file, line, offset)
  let variable = expand('<cword>')

  let s:job = job_start(cmd, {
        \ 'callback': {c, m -> s:type_at_pos_callback(m, variable)},
        \ })
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
