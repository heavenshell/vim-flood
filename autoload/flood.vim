" File: flood.vim
" Author: Shinya Ohyanagi <sohyanagi@gmail.com>
" WebPage:  http://github.com/heavenshell/vim-flood/
" Description: Vim plugin for Facebook FlowType.
" License: BSD, see LICENSE for more details.

let s:save_cpo = &cpo
set cpo&vim

" If specific path is not set, use local flow.
let g:flood_flow_bin = get(g:, 'flood_flow_bin', '')
" Enable open quickfix.
let g:flood_enable_quickfix = get(g:, 'flood_enable_quickfix', 1)
" Currently, sync completions supported only.
let g:flood_complete_async = get(g:, 'flood_complete_async', 0)
" Jump definition with `:edit`, `:split', `:vsplit', `:tabedit`.
let g:flood_definition_split = get(g:, 'flood_definition_split', 0)
" Open suggest result at 'topleft'
let g:flood_suggest_window = get(g:, 'flood_suggest_window', 'topleft')
" Async complete command.
let g:flood_complete_async_popup_on_dot = get(g:, 'flood_complete_async_popup_on_dot', 0)
" Show log.
let g:flood_debug = get(g:, 'flood_debug', 0)

function! s:detect_flowbin(srcpath)
  let flow = ''
  if executable('flow') == 0
    let root_path = finddir('node_modules', a:srcpath . ';')
    let flow = root_path . '/.bin/flow'
  else
    let flow = exepath('flow')
  endif

  return flow
endfunction

function! flood#flowbin()
  let current_path = expand('%:p')
  if g:flood_flow_bin == ''
    let g:flood_flow_bin = s:detect_flowbin(current_path)
  else
    return g:flood_flow_bin
  endif

  " Do check only first time.
  if !executable(g:flood_flow_bin)
    throw 'flow not found.'
  endif
  return g:flood_flow_bin
endfunction

" Omnifunction
function! flood#complete(findstart, base)
  let s:complete_base = a:base
  if g:flood_complete_async == 1
    " -3 will cancel complete
    return a:findstart ? -3 : []
  endif

  let line = getline('.')
  let start = col('.') - 1
  " Check a-z, A-Z, 127 to 255 byte
  while start > 0 && line[start - 1] =~ '[a-zA-Z_0-9\x7f-\xff$]'
    let start -= 1
  endwhile
  if a:findstart
    return start
  endif

  let current_line = line('.')
  let lines = getline(1, '$')
  let offset = start + 1

  let completions = flood#complete#sync(lines, a:base, current_line, offset)

  return completions
endfunction

function! flood#log(msg)
  if g:flood_debug == 1
    echomsg printf('[Flood] %s', string(a:msg))
  endif
endfunction

" Initialize plugin settings.
function! flood#init() abort
  " Open quickfix window if error detect.
  if g:flood_enable_quickfix == 1
    augroup flood_enable_quickfix
      autocmd!
      autocmd BufWritePost *.js,*.jsx silent! call flood#check#run()
    augroup END
  endif

  if !hasmapto('<Plug>(FloodDefinition)')
    map <buffer> <C-]> <Plug>(FloodDefinition)
  endif

  if g:flood_complete_async == 1
    execute 'inoremap <buffer> <C-x><C-o> <C-R>=flood#complete#async()<CR>'
    if g:flood_complete_async_popup_on_dot == 1
      execute 'inoremap <buffer> . .<C-R>=flood#complete#async()<CR>'
    endif
  else
    setlocal omnifunc=flood#complete
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
