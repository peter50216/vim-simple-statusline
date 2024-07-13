if exists('g:loaded_simple_statusline') || v:version < 700
  finish
endif
let g:loaded_simple_statusline = 1

function! s:RequireStatusLine(host) abort
  let plugins = remote#host#PluginsForHost(a:host.name)
  if len(plugins) == 0
    throw 'vim-statusline not found'
  endif
  return provider#Poll(plugins[0].path, a:host.orig_name, '`TODO: error ENV`')
endfunction

function! s:SetColors() abort
  highlight StatusLine cterm=none ctermbg=235 gui=none guibg=#222222
  highlight StatusLineNC cterm=none ctermbg=233 gui=none guibg=#111111
  highlight Status1C ctermfg=blue ctermbg=235 guifg=#729FCF guibg=#222222
  highlight Status2C ctermfg=red ctermbg=235 guifg=#EF2929 guibg=#222222
  highlight Status3C ctermfg=yellow ctermbg=235 guifg=#FCE94F guibg=#222222
  highlight Status4C ctermfg=green ctermbg=235 guifg=#8AE234 guibg=#222222
  highlight Status1NC ctermfg=darkgray ctermbg=233 guifg=#A9A9A9 guibg=#111111
  highlight Status2NC ctermfg=124 ctermbg=233 guifg=#AF0000 guibg=#111111
  highlight Status3NC ctermfg=100 ctermbg=233 guifg=#878700 guibg=#111111
  highlight Status4NC ctermfg=70 ctermbg=233 guifg=#5FAF00 guibg=#111111
  highlight StatusLoadC ctermfg=253 ctermbg=19 guifg=#DADADA guibg=#0000AF
  highlight StatusLoadNC ctermfg=26 ctermbg=233 guifg=#005FD7 guibg=#111111
  highlight StatusGoodC ctermfg=green ctermbg=235 guifg=#8AE234 guibg=#222222
  highlight StatusGoodNC ctermfg=70 ctermbg=233 guifg=#5FAF00 guibg=#111111
  highlight StatusWarnC ctermfg=253 ctermbg=53 guifg=#DADADA guibg=#5F005F
  highlight StatusWarnNC ctermfg=90 ctermbg=233 guifg=#870087 guibg=#111111
  highlight StatusErrorC ctermfg=white ctermbg=88 guifg=#EEEEEE guibg=#870000
  highlight StatusErrorNC ctermfg=160 ctermbg=233 guifg=#D70000 guibg=#111111
endfunction

" To avoid status line blinking before the plugin is loaded.
autocmd ColorScheme * call s:SetColors()
call s:SetColors()
" call remote#host#Register('vim-statusline', 'vim-statusline', function('s:RequireStatusLine'))

" if has('nvim')
if 0

  set laststatus=2
  set statusline=%!BuildStatusLine()
else
  set laststatus=2
  function! SetHighlightGroups(nr)
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
    " let l:error = 0
    " let l:warning = 0
    let l:warning = luaeval('#vim.diagnostic.get(0, { severity = { vim.diagnostic.severity.WARN }})')
    let l:error = luaeval('#vim.diagnostic.get(0, { severity = { vim.diagnostic.severity.ERROR }})')
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
    return '%{SetHighlightGroups(' . a:nr . ')}' .
          \ '%#StatusCheck# %{GetCheckStatus()} %* ' .
          \ '%=%<%#Status1#%F %#Status2#[%{&encoding}/%{&fileformat}/%Y]%#Status3# %l,%c %#Status4#%4P '
  endfunction
  set statusline=%!BuildStatusLine(winnr())
endif
