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

" Make sure all the window numbers are up-to-date; see comments in
" plugin/tbufferline.vim
function! tbufferline#UpdateStatuslineOptions() abort
  for i in range(1, winnr('$'))
    call setwinvar(i, '&statusline', s:StatusLineOption(i))
  endfor
endfunction

" Return the content to be displayed in the statusline below a:window
function! tbufferline#StatusLineContent(window) abort
  call tbufferline#UpdateStatuslineOptions()
  let [shell_buffers, file_buffers, current_buffer, alternate_buffer]
      \ = s:GetBufferData(a:window)
  call setwinvar(a:window, 'alternate_buffer', alternate_buffer)
  let s:bufnummap
      \ = map(file_buffers + shell_buffers, 'v:val[0]')
  return s:MakeStatusLine(shell_buffers, file_buffers, current_buffer,
      \ alternate_buffer)
endfunction

" The string to be stored in the statusline option
function! s:StatusLineOption(window) abort
  return '%!tbufferline#StatusLineContent(' . a:window . ')'
endfunction

function! tbufferline#BufNumMap() abort
  return s:bufnummap
endfunction
