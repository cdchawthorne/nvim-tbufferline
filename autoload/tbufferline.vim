function! s:GetBufferData(window) abort
  let shell_buffers = []
  let file_buffers = []

  let i = 1
  let last_buffer = bufnr('$')
  while i <= last_buffer
    if bufexists(i) && buflisted(i)
      let modified = getbufvar(i, '&mod')

      let pid = getbufvar(i, 'terminal_job_pid', 'NOPID')

      " WHY, VIM. WHY
      if pid !=# 'NOPID'
        let cwd = system(["realpath",  "/proc/" . pid . "/cwd"])[0:-2]
        call add(shell_buffers, [i, cwd])
      else
        let fname = bufname(i)
        call add(file_buffers, [i, modified, fname])
      endif
    endif
    let i += 1
  endwhile
  let alternate_buffer = a:window ==# winnr() ? bufnr('#')
      \ : getwinvar(a:window, 'alternate_buffer', -1)
  let current_buffer = winbufnr(a:window)
  return [shell_buffers, file_buffers, current_buffer, alternate_buffer]
endfunction

function! s:MakeShellName(index, shell_data, current_buffer, alternate_buffer)
    \ abort
  let [bufnum, cwd] = a:shell_data
  let line = a:index . ':' . (cwd ==# $HOME ? '~' : fnamemodify(cwd, ':t'))
  if bufnum ==# a:current_buffer
    let line = '%#StatusLine#[' . line . ']%#StatusLineNC#'
  elseif bufnum ==# a:alternate_buffer
    return '(' . line . ')'
  endif
  return line
endfunction

function! s:MakeFileName(index, file_data, current_buffer, alternate_buffer)
    \ abort
  let [bufnum, modified, fname] = a:file_data
  let line = a:index . ':'
  let line .= substitute(fnamemodify(fname, ':t'), '%', '%%', 'g')
  let line .= (modified ? '+' : '')
  if bufnum ==# a:current_buffer
    let line = '%#StatusLine#[' . line . ']%#StatusLineNC#'
  elseif bufnum ==# a:alternate_buffer
    let line = '(' . line . ')'
  endif
  return line
endfunction

function! s:MakeStatusLine(shell_buffers, file_buffers, current_buffer,
    \ alternate_buffer) abort
  let shell_names = map(a:shell_buffers,
      \ 's:MakeShellName(v:key+len(a:file_buffers)+1, v:val,'
      \ . ' a:current_buffer, a:alternate_buffer)')
  let file_names = map(a:file_buffers,
      \ 's:MakeFileName(v:key+1, v:val, a:current_buffer, a:alternate_buffer)')
  return '%#StatusLineNC#' . join(file_names, '  ') . '%='
      \ . join(shell_names, '  ')
endfunction

" This is frightening on *so* many levels...
function! s:UpdateVarsIfNecessary(window) abort
  if getwinvar(a:window, '&statusline') ==# tbufferline#StatusLine(a:window)
    return
  endif
  " Well, something got confused
  " Update EVERYTHING
  let i = 1
  let last_window = winnr('$')
  while i <= last_window
    call setwinvar(i, '&statusline', tbufferline#StatusLine(i))
    let i += 1
  endwhile
  return
endfunction

" Convenience function for returning new status line and updating
" g:tbufferline#bufnummap
function! tbufferline#Update(window) abort
  call s:UpdateVarsIfNecessary(a:window)
  let [shell_buffers, file_buffers, current_buffer, alternate_buffer]
      \ = s:GetBufferData(a:window)
  call setwinvar(a:window, 'alternate_buffer', alternate_buffer)
  let g:tbufferline#bufnummap
      \ = map(file_buffers + shell_buffers, 'v:val[0]')
  return s:MakeStatusLine(shell_buffers, file_buffers, current_buffer,
      \ alternate_buffer)
endfunction

function! tbufferline#StatusLine(window) abort
  return '%!tbufferline#Update(' . a:window . ')'
endfunction
