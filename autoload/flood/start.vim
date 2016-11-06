" File: flood#start.vim
" Author: Shinya Ohyanagi <sohyanagi@gmail.com>
" Version:  0.1
" WebPage:  http://github.com/heavenshell/vim-flood/
" Description: Vim plugin for Facebook FlowType.
" License: BSD, see LICENSE for more details.

let s:save_cpo = &cpo
set cpo&vim

" Callback function for `flow start`.
function! s:start_callback(msg)
  echomsg a:msg
  " {"pid":"38605","log_file":"/path/to/flow.log"}
  try
    let response = json_decode(a:msg)
    echomsg printf('Staring flow server pid is %s', response['pid'])
  catch
    echomsg a:msg
  endtry
endfunction

" Execute `flow start` job.
function! flood#start#run() abort
  if exists('s:job') && job_status(s:job) != 'stop'
    call job_stop(s:job)
  endif

  let file = expand('%:p')
  let cmd = printf('%s start --json', flood#flowbin())
  let s:job = job_start(cmd, {
        \ 'callback': {c, m -> s:start_callback(m)},
        \ })
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

