if exists('g:loaded_simple_statusline') || v:version < 700
  finish
endif
let g:loaded_simple_statusline = 1

if has('nvim')
  " To avoid status line blinking before the plugin is loaded.
  highlight StatusLine cterm=none ctermbg=235 gui=none guibg=#222222
  highlight StatusLineNC cterm=none ctermbg=233 gui=none guibg=#111111

  set laststatus=2
  set statusline=%!BuildStatusLine()
else
  " For vim backward-compatible, may not be up-to-date
  highlight StatusLine cterm=none ctermbg=235
  highlight StatusLineNC cterm=none ctermbg=233
  highlight Status1C ctermfg=blue ctermbg=235
  highlight Status2C ctermfg=red ctermbg=235
  highlight Status3C ctermfg=yellow ctermbg=235
  highlight Status4C ctermfg=green ctermbg=235
  highlight Status1NC ctermfg=darkgray ctermbg=233
  highlight Status2NC ctermfg=124 ctermbg=233
  highlight Status3NC ctermfg=100 ctermbg=233
  highlight Status4NC ctermfg=70 ctermbg=233

  highlight StatusLoadC ctermfg=253 ctermbg=19
  highlight StatusLoadNC ctermfg=26 ctermbg=233
  highlight StatusGoodC ctermfg=green ctermbg=235
  highlight StatusGoodNC ctermfg=70 ctermbg=233
  highlight StatusWarnC ctermfg=253 ctermbg=53
  highlight StatusWarnNC ctermfg=90 ctermbg=233
  highlight StatusErrorC ctermfg=white ctermbg=88
  highlight StatusErrorNC ctermfg=160 ctermbg=233
  set laststatus=2
  function! SetHighlight(nr)
    for i in [1,2,3,4,"Load","Warn","Error","Good"]
      if (winnr() == a:nr)
        exec 'highlight! link Status'.i.' Status'.i.'C'
      else
        exec 'highlight! link Status'.i.' Status'.i.'NC'
      endif
    endfor
    return ''
  endfunction
  function! GetCheckStatus()
    let l:loading = 0
    let l:error = 0
    let l:warning = 0
    if exists('*ale#engine#IsCheckingBuffer')
      if ale#engine#IsCheckingBuffer(bufnr(''))
        let l:loading = 1
      else
        let l:counts = ale#statusline#Count(bufnr(''))
        let l:error = l:error + l:counts.error + l:counts.style_error
        let l:warning = l:warning + l:counts.warning + l:counts.style_warning
      endif
    endif
    if exists('*youcompleteme#GetErrorCount')
      let l:error = l:error + youcompleteme#GetErrorCount()
      let l:warning = l:warning + youcompleteme#GetWarningCount()
    endif
    if l:loading > 0
      let l:color = 'Load'
      let l:status = '.'
    elseif l:error > 0
      let l:color = 'Error'
      let l:status = 'x'
    elseif l:warning > 0
      let l:color = 'Warn'
      let l:status = 'w'
    else
      let l:color = 'Good'
      let l:status = 'o'
    endif
    exec 'highlight! link StatusCheck Status' . l:color
    return l:status
  endfunction
  function! BuildStatusLine(nr)
    " TODO: make this looks better.
    return '%{SetHighlight(' . a:nr . ')}' .
          \ '%#StatusCheck# %{GetCheckStatus()} %* ' .
          \ '%=%<%#Status1#%F %#Status2#[%{&encoding}/%{&fileformat}/%Y]%#Status3# %l,%c %#Status4#%4P '
  endfunction
  set statusline=%!BuildStatusLine(winnr())
endif
