" Get the data necessary for the statusline below a:window
function! s:GetBufferData() abort
  let shell_buffers = []
  let file_buffers = []

  for i in range(1, bufnr('$'))
    if bufexists(i) && buflisted(i)
      let modified = getbufvar(i, '&mod')

      let pid = getbufvar(i, 'terminal_job_pid', 'NOPID')

      " WHY, VIM. WHY
      if pid ==# 'NOPID'
        let fname = bufname(i)
        call add(file_buffers, [i, modified, fname])
      else
        let cwd = system(["realpath",  "/proc/" . pid . "/cwd"])[0:-2]
        call add(shell_buffers, [i, cwd])
      endif
    endif
  endfor
  return [file_buffers, shell_buffers]
endfunction

" Make a statusline entry for a file buffer
function! s:MakeFileName(index, file_data) abort
  let [bufnum, modified, fname] = a:file_data
  let name = a:index . ':'
  let name .= substitute(fnamemodify(fname, ':t'), '%', '%%', 'g')
  let name .= (modified ? '+' : '')
  return [bufnum, name]
endfunction

" Make a statusline entry for a shell buffer
function! s:MakeShellName(index, shell_data) abort
  let [bufnum, cwd] = a:shell_data
  let name = a:index . ':' . (cwd ==# $HOME ? '~' : fnamemodify(cwd, ':t'))
  return [bufnum, name]
endfunction

function! s:GetWindowData(window) abort
  return [winbufnr(a:window), getwinvar(a:window, 'alternate_buffer', -1)]
endfunction

" Take a statusline entry and add window-specific information to it
function! s:AddWindowData(buf_and_name, current_buffer, alternate_buffer) abort
  let [bufnum, name] = a:buf_and_name
  if bufnum ==# a:current_buffer
    return '%#StatusLine#[' . name . ']%#StatusLineNC#'
  elseif bufnum ==# a:alternate_buffer
    return '(' . name . ')'
  else
    return name
  endif
endfunction

" Take the generic names and make a window-specific statusline
" Non-destructive, use of map notwithstanding
function! s:MakeStatusLine(file_names, shell_names, window)
  let [current_buffer, alternate_buffer] = s:GetWindowData(a:window)
  let line = '%#StatusLineNC#'
  let line .= join(map(copy(a:file_names),
      \ 's:AddWindowData(v:val, current_buffer, alternate_buffer)'), '  ')
  let line .= '%='
  let line .= join(map(copy(a:shell_names),
      \ 's:AddWindowData(v:val, current_buffer, alternate_buffer)'), '  ')
  return line
endfunction

" Make sure all the window numbers are up-to-date; see comments in
" plugin/tbufferline.vim
function! tbufferline#Update() abort
  let [file_buffers, shell_buffers] = s:GetBufferData()
  let s:bufnummap = map(file_buffers + shell_buffers, 'v:val[0]')
  let w:alternate_buffer = bufnr('#')

  " map() is destructive; don't rely on file_buffers and shell_buffers anymore
  let file_names = map(file_buffers, 's:MakeFileName(v:key+1, v:val)')
  let shell_names = map(shell_buffers,
      \ 's:MakeShellName(v:key+len(file_buffers)+1, v:val)')

  for window in range(1, winnr('$'))
    let line = s:MakeStatusLine(file_names, shell_names, window)
    call setwinvar(window, '&statusline', line)
  endfor
endfunction

function! tbufferline#BufNumMap() abort
  return s:bufnummap
endfunction
