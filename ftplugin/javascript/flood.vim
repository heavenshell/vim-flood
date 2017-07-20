" File: flood.vim
" Author: Shinya Ohyanagi <sohyanagi@gmail.com>
" Version:  0.5.5
" WebPage:  http://github.com/heavenshell/vim-flood/
" Description: Vim plugin for Facebook FlowType.
" License: BSD, see LICENSE for more details.

let s:save_cpo = &cpo
set cpo&vim

if get(b:, 'loaded_flood')
  finish
endif

" version check
if !has('channel') || !has('job')
  echoerr '+channel and +job are required for flood.vim'
  finish
endif

command! -buffer FloodCheck         :call flood#check#run()
command! -buffer FloodCheckContents :call flood#check_contents#run()
command! -buffer FloodDefinition    :call flood#definition#run()
command! -buffer FloodImporters     :call flood#importers#run()
command! -buffer FloodImports       :call flood#imports#run()
command! -buffer FloodStart         :call flood#start#run()
command! -buffer FloodStatus        :call flood#status#run()
command! -buffer FloodStop          :call flood#stop#run()
command! -buffer FloodSuggest       :call flood#suggest#run()
command! -buffer FloodTypeAtPos     :call flood#type_at_pos#run()
command! -buffer FloodVersion       :call flood#version#run()

noremap <silent> <buffer> <Plug>(FloodCheck)          :FloodCheck <CR>
noremap <silent> <buffer> <Plug>(FloodCheckContents)  :FloodCheckContents <CR>
noremap <silent> <buffer> <Plug>(FloodDefinition)     :FloodDefinition <CR>
noremap <silent> <buffer> <Plug>(FloodImporters)      :FloodImporters <CR>
noremap <silent> <buffer> <Plug>(FloodImports)        :FloodImports <CR>
noremap <silent> <buffer> <Plug>(FloodStart)          :FloodStart <CR>
noremap <silent> <buffer> <Plug>(FloodStatus)         :FloodStatus <CR>
noremap <silent> <buffer> <Plug>(FloodStop)           :FloodStop <CR>
noremap <silent> <buffer> <Plug>(FloodSuggest)        :FloodSuggest <CR>
noremap <silent> <buffer> <Plug>(FloodTypeAtPos)      :FloodTypeAtPos <CR>
noremap <silent> <buffer> <Plug>(FloodVersion)        :FloodVersion <CR>

let g:flood_enable_init_onstart = get(g:, 'flood_enable_init_onstart', 1)
if g:flood_enable_init_onstart == 1
  call flood#init()
endif

let b:loaded_flood = 1

let &cpo = s:save_cpo
unlet s:save_cpo
