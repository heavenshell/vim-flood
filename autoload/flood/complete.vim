" File: flood#complete.vim
" Author: Shinya Ohyanagi <sohyanagi@gmail.com>
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

function! s:detect_input_offset(line)
  " Find `dot` positon. Insert selected candidate after `dot`.
  let offset = strridx(a:line, '.')
  if offset != -1
    " `dot` found.
    return offset + 1
  endif

  " If `dot` is not found. There were no `dot` in line.
  " Maybe user input something like `wor<C-x><C-o>`.
  " Insert selected candidate after `space'.
  let offset = strridx(a:line, ' ')
  if offset != -1
    return offset + 1
  endif

  " Same as `tab`.
  let offset = strridx(a:line, '\t')
  if offset != -1
    return offset + 1
  endif

  " Maybe offset is ahead of the line.
  return 0
endfunction

function! s:detect_base(line, col)
  let offset = s:detect_input_offset(a:line)
  let base = strpart(a:line, offset, a:col)
  return base
endfunction

" Parse autocomplete and create candiates.
function! s:create_candidate(result, input_word)
  " Following code is from vim-flow a lot.
  " `https://github.com/flowtype/vim-flow/blob/master/autoload/flowcomplete.vim`
  let completions = []
  let candidates = [] " For avoid dupricat candidate.
  for v in a:result
    " Flow autocomplete' result content current inputing word too.
    " So filter it.
    if a:input_word != ''
      if stridx(v['name'], a:input_word) != 0
        continue
      endif
    endif
    " If candidate word already exists, skip it.
    if index(candidates, v['name']) >= 0
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
    call add(candidates, v['name'])
  endfor

  return completions
endfunction

function! s:complete_callback(ch, msg, input_word, offset)
  " Following code is from vim-flow a lot.
  " `https://github.com/flowtype/vim-flow/blob/master/autoload/flowcomplete.vim`
  let completions = []
  try
    let json = json_decode(a:msg)
    let result = json['result']

    let completions = s:create_candidate(result, a:input_word)

    " completeopt's noinsert, noselect
    let flg = 0
    if len(completions) == 1
      " completeopt's noselect and noinsert
      let _completeopt = &completeopt
      let pattern = '\(noinsert\|noselect\)'
      let flg = &completeopt =~ pattern
      if flg
        let options = split(&completeopt, ',')
        let option = ''
        for o in options
          if o == 'noselect' || o == 'noinsert'
            continue
          endif
          if option == ''
            let option = option . o
          else
            let option = option . ','. o
          endif
        endfor
        execute 'set completeopt=' . option
      endif
    endif

    call complete(a:offset, completions)

    " Restore completeopt.
    if flg
      execute 'set completeopt=' . _completeopt
    endif
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

" Async completion.
function! flood#complete#async()
  " Clear gabage on buffer.
  redraw!
  if exists('s:job') && job_status(s:job) != 'stop'
    call job_stop(s:job)
  endif

  let current_line = line('.')
  let offset = col('.')
  let current_path = expand('%p')

  " Find `.` positon.
  " Below is same as omnifunction's `a:base`.
  let line = getline(current_line)
  let base = s:detect_base(line, offset)
  let start = s:detect_input_offset(line)
  let start = start + 1

  let file = expand('%:p')
  let cmd = printf(
        \ '%s autocomplete --json %d %d',
        \ flood#flowbin(),
        \ current_line,
        \ offset
        \ )

  let s:job = job_start(cmd, {
        \ 'callback': {c, m -> s:complete_callback(c, m, base, start)},
        \ 'in_io': 'buffer',
        \ 'in_name': file,
        \ 'timeout': 1000
        \ })

  return ''
endfunction

" Execute `flow autocomplete --json` with magic token.
function! flood#complete#sync(lines, base, current_line, offset)
  " Clear gabage on buffer.
  redraw!
  let buffer = s:insert_autocomplete_token(a:lines, a:base, a:current_line, a:offset)
  let current_path = expand('%p')
  let cmd = printf('%s autocomplete --json %s', flood#flowbin(), current_path)
  let completions = []
  try
    let result = system(cmd, buffer)
    let json = json_decode(result)
    let result = json['result']

    let completions = s:create_candidate(result, a:base)
  catch
    call flood#log(v:exception)
  endtry

  return completions
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
