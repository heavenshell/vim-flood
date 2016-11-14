" File: flood#version.vim
" Author: Shinya Ohyanagi <sohyanagi@gmail.com>
" WebPage:  http://github.com/heavenshell/vim-flood/
" Description: Vim plugin for Facebook FlowType.
" License: BSD, see LICENSE for more details.

let s:save_cpo = &cpo
set cpo&vim

function! s:parse(responses)
  let ver = a:responses['semver']
  return ver
endfunction

" Callback function for `flow version`.
function! s:version_callback(msg)
  try
    let responses = json_decode(a:msg)
    let ver = s:parse(responses)
    echomsg printf('Flow version is %s.', ver)
  catch
    echomsg 'Flow server is not running.'
    echomsg a:msg
  endtry
endfunction

" Execute `flow version` job.
function! flood#version#run() abort
  if exists('s:job') && job_version(s:job) != 'stop'
    call job_stop(s:job)
  endif

  let cmd = printf('%s version --json', flood#flowbin())
  let s:job = job_start(cmd, {
        \ 'callback': {c, m -> s:version_callback(m)},
        \ })
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
