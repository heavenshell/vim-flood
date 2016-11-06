" File: flood#stop.vim
" Author: Shinya Ohyanagi <sohyanagi@gmail.com>
" Version:  0.1
" WebPage:  http://github.com/heavenshell/vim-flood/
" Description: Vim plugin for Facebook FlowType.
" License: BSD, see LICENSE for more details.

let s:save_cpo = &cpo
set cpo&vim

" Callback function for `flow status`.
function! s:stop_callback(msg)
  echomsg a:msg
endfunction

" Execute `flow status` job.
function! flood#stop#run() abort
  if exists('s:job') && job_status(s:job) != 'stop'
    call job_stop(s:job)
  endif

  let file = expand('%:p')
  let cmd = printf('%s stop', flood#flowbin())
  let s:job = job_start(cmd, {
        \ 'callback': {c, m -> s:stop_callback(m)},
        \ })
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

