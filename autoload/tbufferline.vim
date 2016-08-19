" Get the data necessary for the statusline below a:window
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

" Make a statusline entry for a shell buffer
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

" Make a statusline entry for a file buffer
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

" If the user moves the windows around, the statuslines move with the windows,
" but the window numbers don't. Hence sometimes we end up in a bad state; not
" much for it but to reset all the windows' statuslines.
" (It's important to reset the other windows now rather than wait for this
" function to be called on them as this function only gets called on the
" currently focused window; the statusline on inactive windows would remain
" out-of-date until they were focused.)
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
" s:bufnummap
function! tbufferline#Update(window) abort
  call s:UpdateVarsIfNecessary(a:window)
  let [shell_buffers, file_buffers, current_buffer, alternate_buffer]
      \ = s:GetBufferData(a:window)
  call setwinvar(a:window, 'alternate_buffer', alternate_buffer)
  let s:bufnummap
      \ = map(file_buffers + shell_buffers, 'v:val[0]')
  return s:MakeStatusLine(shell_buffers, file_buffers, current_buffer,
      \ alternate_buffer)
endfunction

" Unfortunately, we actually need to put the window in this string. Ideally,
" tbufferline#Update would fetch the window number; unfortunately, winnr()
" returns the currently focused window, whereas we want the number of the
" window we're trying to write a statusline for.
function! tbufferline#StatusLine(window) abort
  return '%!tbufferline#Update(' . a:window . ')'
endfunction

function! tbufferline#BufNumMap() abort
  return s:bufnummap
endfunction
