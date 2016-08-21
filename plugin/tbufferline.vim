" TODO: different colours for modes?
" TODO: probably should have a less intrusive name than w:alternate_buffer
if exists('g:loaded_tbufferline')
  finish
endif
let g:loaded_tbufferline = 1
let s:tbufferline_enabled = 0

" Enabling and disabling

function! s:Enable() abort
  augroup tbufferline
    autocmd!
    autocmd CursorMovedI,CursorMoved,VimEnter,WinEnter,BufWinEnter,TermOpen *
        \ call tbufferline#Update()
    autocmd BufWritePost * call tbufferline#Update()
  augroup END

  call tbufferline#Update()
  let s:tbufferline_enabled = 1
endfunction

function! s:Disable() abort
  augroup tbufferline
    autocmd!
  augroup END
  let s:tbufferline_enabled = 0
  for i in range(1, winnr('$'))
    call setwinvar(i, '&statusline', '')
  endfor
endfunction

function! s:Toggle() abort
  if s:tbufferline_enabled
    call s:Disable()
  else
    call s:Enable()
  endif
endfunction

if exists('g:tbufferline_enable_on_startup') && g:tbufferline_enable_on_startup
  call s:Enable()
endif

" Commands

command TbufferlineEnable call s:Enable()
command TbufferlineDisable call s:Disable()
command TbufferlineToggle call s:Toggle()

" Mappings and mapping-related functions

function! s:SwitchBuffer(buffer_command) abort
  if v:count && v:count <= len(tbufferline#BufNumMap())
    execute a:buffer_command . ' ' . tbufferline#BufNumMap()[v:count-1]
  endif
endfunction

function! s:StepBuffer(multiplier) abort
  let l:steps = (v:count ? v:count : 1) * a:multiplier
  let l:idx = (index(tbufferline#BufNumMap(), bufnr('%')) + l:steps)
  execute 'buffer '
      \ . tbufferline#BufNumMap()[l:idx % len(tbufferline#BufNumMap())]
endfunction

nnoremap <silent> <Plug>tbufferline#Buffer
    \ :<C-u>call <SID>SwitchBuffer('buffer')<CR>
nnoremap <silent> <Plug>tbufferline#SplitBuffer
    \ :<C-u>call <SID>SwitchBuffer('sbuffer')<CR>
nnoremap <silent> <Plug>tbufferline#VSplitBuffer
    \ :<C-u>call <SID>SwitchBuffer('vertical sbuffer')<CR>
nnoremap <silent> <Plug>tbufferline#StepForward
    \ :<C-u>call <SID>StepBuffer(1)<CR>
nnoremap <silent> <Plug>tbufferline#StepBack :<C-u>call <SID>StepBuffer(-1)<CR>
