" File: flood#complete.vim
" Author: Shinya Ohyanagi <sohyanagi@gmail.com>
" Version:  0.1
" WebPage:  http://github.com/heavenshell/vim-flood/
" Description: Vim plugin for Facebook FlowType.
" License: BSD, see LICENSE for more details.

let s:save_cpo = &cpo
set cpo&vim

function! s:insert_autocomplete_token(buffer, base, line, offset)
  " Following code is from vim-flow a lot.
  " `https://github.com/flowtype/vim-flow/blob/master/autoload/flowcomplete.vim`
  " Magical flow autocomplete token.
  let lines = a:buffer
  let current_line = lines[a:line - 1]
  let lines[a:line - 1] = current_line[:a:offset - 1]
    \ . a:base . 'AUTO332' . current_line[a:offset :]

  return join(lines, "\n")
endfunction

" Parse autocomplete and create candiates.
function! s:parse(result, input_word, async)
  " Following code is from vim-flow a lot.
  " `https://github.com/flowtype/vim-flow/blob/master/autoload/flowcomplete.vim`
  let completions = []
  for v in a:result
    " Flow returns current inputing word. So filter it.
    if stridx(v['name'], a:input_word) != 0
      continue
    endif

    let kind = 'v'
    if v['type'] =~ '^(.*) =>'
      let kind = 'm'
    elseif v['type'] =~ '^[class:'
      let kind = 'c'
    endif
    let entry = {'word': v['name'], 'kind': kind, 'menu': v['type']}

    call add(completions, entry)
  endfor

  return completions
endfunction

function! s:complete_callback(ch, msg)
  call flood#log('flood#complete#complete_callback')
  let completions = []
  try
    let json = json_decode(a:msg)
    let result = json['result']

    for v in result
      let kind = 'v'
      if v['type'] =~ '^(.*) =>'
        let kind = 'm'
      elseif v['type'] =~ '^[class:'
        let kind = 'c'
      endif
      let entry = {'word': v['name'], 'kind': kind, 'menu': v['type']}

      call add(completions, entry)
    endfor
    call complete(col('.'), completions)
  catch
    echomsg 'Flow server is not running.'
    call flood#log(v:exception)
    call flood#log(a:msg)
  finally
    try
      call ch_close(a:ch)
    catch
    endtry
  endtry

  return completions
endfunction

function! flood#complete#async()
  " Clear gabage on buffer.
  redraw!
  if exists('s:job') && job_status(s:job) != 'stop'
    call job_stop(s:job)
  endif

  let current_line = line('.')
  let offset = col('.')
  let current_path = expand('%p')

  let file = expand('%:p')
  let cmd = printf(
        \ '%s autocomplete --json %d %d',
        \ flood#flowbin(),
        \ current_line,
        \ offset
        \ )

  call flood#log('flood#complete#async cmd is ' . cmd)
  let s:job = job_start(cmd, {
        \ 'callback': {c, m -> s:complete_callback(c, m)},
        \ 'in_io': 'buffer',
        \ 'in_name': file,
        \ 'timeout': 1000
        \ })

  call flood#log(string(s:job))
  return ''
endfunction

" Execute `flow autocomplete --json` with magic token.
function! flood#complete#sync(lines, base, current_line, offset)
  let buffer = s:insert_autocomplete_token(a:lines, a:base, a:current_line, a:offset)
  let current_path = expand('%p')
  let cmd = printf('%s autocomplete --json %s', flood#flowbin(), current_path)
  let result = system(cmd, buffer)
  let json = json_decode(result)
  let result = json['result']
  let async = 0

  return s:parse(result, a:base, async)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
