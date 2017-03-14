" File: flood#check.vim
" Author: Shinya Ohyanagi <sohyanagi@gmail.com>
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
    let path = has_key(e, 'operation') ? e['operation']['path'] : ''
    "let start = has_key(e, 'operation') ? e['operation']['start'] : -1
    let start = -1
    for message in e['message']
      let text = text . ' ' . message['descr']
      if line == -1
        let line = message['line']
      endif
      if path == ''
        let path = message['path']
      endif
      if start == -1
        let start = message['start']
      endif
    endfor

    let level = e['level'] ==# 'error' ? 'E' : 'W'
    call add(outputs, {
          \ 'filename': path,
          \ 'lnum': line,
          \ 'col': start == -1 ? 0 : start,
          \ 'vcol': 0,
          \ 'text': printf('[Flow] %s', text),
          \ 'type': level
          \})

  endfor

  return outputs
endfunction

" Callback function for `flow check-contents`.
" Create quickfix if error contains
function! s:check_callback(msg, mode)
  try
    call append(line('$'), a:msg)
    let responses = json_decode(a:msg)
  catch
    call append(line('$'), v:exception)
  finally
  endtry

  call append(line('$'), responses['errors'])
  let outputs = s:parse(responses['errors'])

  call append(line('$'), 'flood_enable_quickfix: ' . g:flood_enable_quickfix)
  call append(line('$'), 'passed: ' . responses['passed'])

  if g:flood_enable_quickfix == 1 && responses['passed'] && len(getqflist()) == 0
    if len(outputs) == 0
      " No Errors. Clear quickfix then close window if exists.
      call setqflist([], 'r')
      cclose
      return
    endif
  endif

  " Create quickfix via setqflist().
  " If quickfix mode is 'a', add outputs to existing quickfix list.
  call setqflist(outputs, a:mode)
  if len(outputs) > 0 && g:flood_enable_quickfix == 1
    cwindow
  endif
endfunction

function! s:after_check_callback()
  if flood#has_callback('check', 'after_run')
    call g:flood_callbacks['check']['after_run']()
  endif
endfunction

let g:chunks = {}

function! s:neovim_job_handler(job_id, data, event) dict
  if a:event == 'stdout'
    if !has_key(g:chunks, a:job_id)
      let g:chunks[a:job_id] = []
    endif

    call add(g:chunks[a:job_id], a:data)
  elseif a:event == 'exit'
    try
      let msg = join(remove(g:chunks, a:job_id))
      call s:check_callback(msg, self.mode)
    catch
    finally
      call s:after_check_callback()
    endtry
  else
    call flood#log(a:data)

    if has_key(g:chunks, a:job_id)
      remove(g:chunks, a:job_id)
    endif
  endif
endfunction

function! s:vim_job_handler(ch, msg, mode)
  try
    call s:check_callback(a:msg, a:mode)
  catch
  finally
    try
      call ch_close(a:ch)
    catch
    endtry

    call s:after_check_callback()
  endtry
endfunction

" Execute `flow check-contents` job.
function! flood#check#run(...) abort
  if exists('s:job') && job_status(s:job) != 'stop'
    call jobstop(s:job_id)
  endif
  if flood#has_callback('check', 'before_run')
    call g:flood_callbacks['check']['before_run']()
  endif

  let bufnum = bufnr('%')
  let input = join(getbufline(bufnum, 1, '$'), "\n") . "\n"
  if g:flood_detect_flow_statememt == 1 && input !~ '@flow'
    call flood#log('`@flow` statement not found.')
    return
  endif

  let mode = a:0 > 0 ? a:1 : 'r'
  let cmd = printf('%s --json', flood#flowbin())

  if has('nvim')
    let s:job_id = jobstart(cmd, {
          \ 'mode': mode,
          \ 'on_stdout': function('s:neovim_job_handler'),
          \ 'on_stderr': function('s:neovim_job_handler'),
          \ 'on_exit': function('s:neovim_job_handler')
          \ })
  else
    let s:job = job_start(cmd, {
          \ 'callback': {c, m -> s:vim_job_handler(c, m, mode)},
          \ })
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
