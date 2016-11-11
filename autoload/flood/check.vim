" File: flood#check.vim
" Author: Shinya Ohyanagi <sohyanagi@gmail.com>
" Version:  0.1
" WebPage:  http://github.com/heavenshell/vim-flood/
" Description: Vim plugin for Facebook FlowType.
" License: BSD, see LICENSE for more details.

let s:save_cpo = &cpo
set cpo&vim

function! s:parse(errors)
  let outputs = []
  for e in a:errors
    let text = ''
    let line = has_key(e, 'operation') ? e['operation']['line'] : -1
    "let start = has_key(e, 'operation') ? e['operation']['start'] : -1
    let start = -1
    for message in e['message']
      let text = text . ' ' . message['descr']
      if line == -1
        let line = message['line']
      endif
      if start == -1
        " Current file's error position
        if message['path'] == '-'
          let start = message['start']
        endif
      endif
    endfor

    let level = e['level'] ==# 'error' ? 'E' : 'W'
    call add(outputs, {
          \ 'filename': expand('%t'),
          \ 'lnum': line,
          \ 'col': start == -1 ? 0 : start,
          \ 'vcol': 0,
          \ 'text': text,
          \ 'type': level
          \})
  endfor
  return outputs
endfunction

" Callback function for `flow check-contents`.
" Create quickfix if error contains
function! s:check_callback(ch, msg)
  try
    let responses = json_decode(a:msg)
    if responses['passed']
      " No Errors. Clear quickfix then close window if exists.
      call setqflist([], 'r')
      cclose
      return
    endif

    let outputs = s:parse(responses['errors'])
    call flood#log('check_callback')
    " Create quickfix via setqflist().
    call setqflist(outputs, 'r')
    call flood#log('after setqflist')
    if len(outputs) > 0 && g:flood_enable_quickfix == 1
      cwindow
    else
      cclose
    endif
    call flood#log('check_callback end')
  catch
    echomsg 'Flow server is not running.'
    echomsg a:msg
  finally
    try
      call ch_close(a:ch)
    catch
    endtry
  endtry
endfunction

" Execute `flow check-contents` job.
function! flood#check#run() abort
  if exists('s:job') && job_status(s:job) != 'stop'
    call job_stop(s:job)
  endif

  let file = expand('%:p')
  let cmd = printf('%s --json', flood#flowbin())
  let s:job = job_start(cmd, {
        \ 'callback': {c, m -> s:check_callback(c, m)},
        \ })
  return ''
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

