if exists('g:loaded_tbufferline')
  finish
endif
let g:loaded_tbufferline = 1
let s:tbufferline_enabled = 0

" Enabling and disabling

function! s:Enable() abort
  augroup tbufferline
    autocmd!

    " TODO: Do we need bufwinenter? Is this a bug in setlocal statusline?
    autocmd WinEnter,VimEnter,BufWinEnter *
        \ call setwinvar(winnr(), '&statusline',
        \     tbufferline#StatusLine(winnr()))
  augroup END
  let i = 1
  let last_window = winnr('$')
  while i <= last_window
    call setwinvar(i, '&statusline', tbufferline#StatusLine(i))
    let i += 1
  endwhile
  let s:tbufferline_enabled = 1
endfunction

function! s:Disable() abort
  augroup tbufferline
    autocmd!
  augroup END
  let s:tbufferline_enabled = 0
  let i = 1
  let last_window = winnr('$')
  while i <= last_window
    call setwinvar(i, '&statusline', '')
    let i += 1
  endwhile
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
  let steps = (v:count ? v:count : 1) * a:multiplier
  let idx = (index(tbufferline#BufNumMap(), bufnr('%')) + steps)
  execute 'buffer '
      \ . tbufferline#BufNumMap()[idx % len(tbufferline#BufNumMap())]
endfunction

nnoremap <silent> <Plug>TbufferlineBuffer
    \ :<C-u>call <SID>SwitchBuffer('buffer')<CR>
nnoremap <silent> <Plug>TbufferlineSplitBuffer
    \ :<C-u>call <SID>SwitchBuffer('sbuffer')<CR>
nnoremap <silent> <Plug>TbufferlineVSplitBuffer
    \ :<C-u>call <SID>SwitchBuffer('vertical sbuffer')<CR>
nnoremap <silent> <Plug>TbufferlineStepForward
    \ :<C-u>call <SID>StepBuffer(1)<CR>
nnoremap <silent> <Plug>TbufferlineStepBack
    \ :<C-u>call <SID>StepBuffer(-1)<CR>
