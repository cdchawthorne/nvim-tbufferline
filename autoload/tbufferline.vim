" Get the data necessary for the statusline below a:window
function! s:GetBufferData() abort
  let l:shell_buffers = []
  let l:file_buffers = []

  for bufnum in range(1, bufnr('$'))
    if bufexists(l:bufnum) && buflisted(l:bufnum)
      let l:modified = getbufvar(l:bufnum, '&mod')

      let l:pid = getbufvar(l:bufnum, 'terminal_job_pid', 'NOPID')

      " WHY, VIM. WHY
      if l:pid ==# 'NOPID'
        let l:fname = bufname(l:bufnum)
        call add(l:file_buffers, [l:bufnum, l:modified, l:fname])
      else
        let l:cwd = system(['realpath',  '/proc/' . l:pid . '/cwd'])[0:-2]
        call add(l:shell_buffers, [l:bufnum, l:cwd])
      endif
    endif
  endfor
  return [l:file_buffers, l:shell_buffers]
endfunction

" Make a statusline entry for a file buffer
function! s:MakeFileName(index, file_data) abort
  let [l:bufnum, l:modified, l:fname] = a:file_data
  let l:name = a:index . ':'
  let l:name .= substitute(fnamemodify(l:fname, ':t'), '%', '%%', 'g')
  let l:name .= (l:modified ? '+' : '')
  return [l:bufnum, l:name]
endfunction

" Make a statusline entry for a shell buffer
function! s:MakeShellName(index, shell_data) abort
  let [l:bufnum, l:cwd] = a:shell_data
  let l:name = a:index . ':'
  let l:name .= l:cwd ==# $HOME ? '~' : fnamemodify(l:cwd, ':t')
  return [l:bufnum, l:name]
endfunction

function! s:GetWindowData(window) abort
  return [winbufnr(a:window),
      \ getwinvar(a:window, 'tbufferline_alternate_buffer', -1)]
endfunction

" Take a statusline entry and add window-specific information to it
function! s:AddWindowData(buf_and_name, current_buffer, alternate_buffer) abort
  let [l:bufnum, l:name] = a:buf_and_name
  if l:bufnum ==# a:current_buffer
    return '%#Tbufferline#[' . l:name . ']%#TbufferlineNC#'
  elseif l:bufnum ==# a:alternate_buffer
    return '(' . l:name . ')'
  else
    return l:name
  endif
endfunction

" Take the generic names and make a window-specific statusline
" Non-destructive, use of map notwithstanding
function! s:MakeStatusLine(file_names, shell_names, window)
  let [l:current_buffer, l:alternate_buffer] = s:GetWindowData(a:window)
  let l:line = '%#TbufferlineNC#'
  let l:line .= join(map(copy(a:file_names),
      \ 's:AddWindowData(v:val, l:current_buffer, l:alternate_buffer)'), '  ')
  let l:line .= '%='
  let l:line .= join(map(copy(a:shell_names),
      \ 's:AddWindowData(v:val, l:current_buffer, l:alternate_buffer)'), '  ')
  return l:line
endfunction

" Make sure all the window numbers are up-to-date; see comments in
" plugin/tbufferline.vim
function! tbufferline#Update() abort
  let [l:file_buffers, l:shell_buffers] = s:GetBufferData()
  let s:bufnummap = map(l:file_buffers + l:shell_buffers, 'v:val[0]')
  let w:tbufferline_alternate_buffer = bufnr('#')

  " map() is destructive; don't rely on file_buffers and shell_buffers anymore
  let l:file_names = map(l:file_buffers, 's:MakeFileName(v:key+1, v:val)')
  let l:shell_names = map(l:shell_buffers,
      \ 's:MakeShellName(v:key+len(file_buffers)+1, v:val)')

  for window in range(1, winnr('$'))
    let l:line = s:MakeStatusLine(l:file_names, l:shell_names, l:window)
    call setwinvar(l:window, '&statusline', l:line)
  endfor
endfunction

function! tbufferline#BufNumMap() abort
  return s:bufnummap
endfunction
