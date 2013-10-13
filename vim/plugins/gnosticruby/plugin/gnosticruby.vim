" Vim completion script
" Language:             Ruby
" Maintainer:           Mark Guzman <segfault@hasno.info>
" URL:                  https://github.com/vim-ruby/vim-ruby
" Release Coordinator:  Doug Kearns <dougkearns@gmail.com>
" Maintainer Version:   0.8.1
" ----------------------------------------------------------------------------
"
" Ruby IRB/Complete author: Keiju ISHITSUKA(keiju@ishitsuka.com)
" ----------------------------------------------------------------------------

" {{{ requirement checks


function! gnosticruby#Complete(findstart, base)
  "findstart = 1 when we need to get the text length
  if a:findstart
    let g:gnostic_complete_start_column = 0
    execute "ruby Gnostic::VimComplete.find_start"
    return g:gnostic_complete_start_column
  else
    let g:gnostic_complete_completions = []
    execute "ruby Gnostic::VimComplete.get_completions('" . a:base . "')"
    return g:gnostic_complete_completions
  endif
endfunction


"{{{ ruby-side code
function! s:DefRuby()
  ruby << RUBYEOF
  # {{{ ruby completion
  
  $LOAD_PATH << "/Users/andrew/.dotfiles/vim/plugins/gnosticruby/plugin/"
  require 'gnostic_complete'


# }}} ruby completion
RUBYEOF
endfunction



call s:DefRuby()
"}}} ruby-side code


if exists("&ofu") && has("ruby")
  setlocal omnifunc=gnosticruby#Complete
endif


