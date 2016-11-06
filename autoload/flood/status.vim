" File: flood#status.vim
" Author: Shinya Ohyanagi <sohyanagi@gmail.com>
" Version:  0.1
" WebPage:  http://github.com/heavenshell/vim-flood/
" Description: Vim plugin for Facebook FlowType.
" License: BSD, see LICENSE for more details.

let s:save_cpo = &cpo
set cpo&vim

" Callback function for `flow status`.
function! s:status_callback(msg)
  let response = json_decode(a:msg)
  try
    echomsg printf('Flow server is running. Flow version is %s.', response['flowVersion'])
  catch
  endtry
endfunction

" Execute `flow status` job.
function! flood#status#run() abort
  if exists('s:job') && job_status(s:job) != 'stop'
    call job_stop(s:job)
  endif

  let cmd = printf('%s status --json', flood#flowbin())
  let s:job = job_start(cmd, {
        \ 'callback': {c, m -> s:status_callback(m)},
        \ })
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

