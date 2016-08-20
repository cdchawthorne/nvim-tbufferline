" TODO: different colours for modes?
if exists('g:loaded_tbufferline')
  finish
endif
let g:loaded_tbufferline = 1
let s:tbufferline_enabled = 0

" Enabling and disabling

function! s:Enable() abort
  augroup tbufferline
    autocmd!

    " The main difficulty implementing this plugin is that when we have
    " multiple windows open, we want a correct statusline below each window;
    " unfortunately, for statuslines returned by a function (via %! in the
    " statusline option), there appears to be no way to detect which window
    " the statusline corresponds to. The current solution is to include the
    " window number as a parameter to the function generating the statusline.
    " Since the window number isn't static, this means whenever the user
    " messes with the window layout, we need to make sure each window still
    " has the correct window number in its statusline; this is the autocmd
    " below. (This also ensures that any new windows have their statuslines
    " set to use tbufferline.)
    "
    " Double-unfortunately, I can't find an autocmd to cover the case where
    " the user swaps two windows. The current way around this is to also
    " update the window numbers every time the statusline gets displayed. (See
    " the call to tbufferline#UpdateStatuslineOptions() in
    " tbufferline#StatusLineContent().
    "
    " TODO: Why do we need BufWinEnter?
    "       It seems to be behaving like a buffer-local variable.
    autocmd WinEnter,VimEnter,BufWinEnter *
        \ call tbufferline#UpdateStatuslineOptions()
  augroup END
  call tbufferline#UpdateStatuslineOptions()
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
