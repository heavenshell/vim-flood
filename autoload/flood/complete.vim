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

    " Async completions currently not work.
    " Sync completions is fast.
    if a:async == 1
      call complete_add(entry)
      if complete_check()
        break
      endif
    else
      call add(completions, entry)
    endif
  endfor

  return completions
endfunction

function! flood#complete#async(lines, base, current_line, offset)
  throw 'Not implemented.'
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
