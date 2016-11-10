" File: flood#suggest.vim
" Author: Shinya Ohyanagi <sohyanagi@gmail.com>
" Version:  0.1
" WebPage:  http://github.com/heavenshell/vim-flood/
" Description: Vim plugin for Facebook FlowType.
" License: BSD, see LICENSE for more details.

let s:save_cpo = &cpo
set cpo&vim

function! s:suggest_callback(msg)
endfunction

" Execute `flow suggest index.js` and show diff window.
function! flood#suggest#run() abort
  if exists('s:job') && job_status(s:job) != 'stop'
    call job_stop(s:job)
  endif

  " TODO use win_getid()
  let winnum = bufwinnr(bufnr('^flow-suggest$'))
  if winnum != -1
    if winnum != bufwinnr('%')
      execute winnum 'wincmd w'
      " Clear buffer
      execute 'bdelete'
    endif
  endif
  execute 'silent ' . g:flood_suggest_window . ' noautocmd new flow-suggest'

  setlocal buftype=nofile bufhidden=delete noswapfile
  setlocal nomodified
  setlocal nomodifiable
  nnoremap <buffer> q <C-w>c
  setlocal filetype=diff

  " Show diff buffer and then forcus cursor to current buffer.
  if winnum != -1
    if winnum != bufwinnr('%')
      execute winnum 'wincmd w'
    else
      execute 'wincmd w'
    endif
  else
    execute 'wincmd w'
  endif

  let file = expand('%:p')
  let tmp_file = tempname()
  let cmd = printf('%s suggest %s', flood#flowbin(), file)

  let s:job = job_start(cmd, {
        \ 'callback': {c, m -> s:suggest_callback(m)},
        \ 'out_io': 'buffer',
        \ 'out_name': 'flow-suggest',
        \ 'out_modifiable': 0,
        \ 'out_msg': 1
        \ })
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
