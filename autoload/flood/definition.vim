" File: flood#definition.vim
" Author: Shinya Ohyanagi <sohyanagi@gmail.com>
" Version:  0.1
" WebPage:  http://github.com/heavenshell/vim-flood/
" Description: Vim plugin for Facebook FlowType.
" License: BSD, see LICENSE for more details.
let s:save_cpo = &cpo
set cpo&vim

function! s:parse(msg)
  let mode = 'edit'
  if g:flood_definition_split == 0
    " Do edit
  elseif g:flood_definition_split == 1
    " Do split
    let mode = 'split'
  elseif g:flood_definition_split == 2
    " Do vsplit
    let mode = 'vsplit'
  elseif g:flood_definition_split == 3
    " Do tabedit
    let mode = 'tabedit'
  endif

  if a:msg['path'] == ''
    return
  elseif a:msg['path'] == '-'
    " Jump to current file line and position
    let path = expand('%p')
  else
    " Jump to file line and position
    let path = a:msg['path']
  endif

  let cmd = printf('%s %s', mode, path)
  return cmd
endfunction

function! s:definition_callback(msg)
  try
    " JSON format is `{"path":"-","line":3,"endline":3,"start":10,"end":15}`.
    let json = json_decode(a:msg)
    let cmd = s:parse(json)
    execute cmd
    call cursor(json['line'], json['start'])
  catch
    echomsg 'Flow server is not running.'
    call flood#log(v:exception)
    call flood#log(a:msg)
  endtry
endfunction

" Execute `flow get-def foo.js 12 3`.
function! flood#definition#run()
  if exists('s:job') && job_status(s:job) != 'stop'
    call job_stop(s:job)
  endif

  let bin = flood#flowbin()
  let file = expand('%p')
  let line = line('.')
  let offset = col('.')
  let cmd = printf('%s get-def --json %d %d', bin, line, offset)

  let s:job = job_start(cmd, {
        \ 'callback': {c, m -> s:definition_callback(m)},
        \ 'in_io': 'buffer',
        \ 'in_name': file
        \ })
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

