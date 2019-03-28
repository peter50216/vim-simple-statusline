require 'neovim'

class Helper
  def self.parse_color(rgb)
    rgb.scan(/#(..)(..)(..)/)[0].map { |s| s.to_i(16) }
  end

  COLOR_256 = [
    '#000000', '#800000', '#008000', '#808000', '#000080', '#800080', '#008080', '#c0c0c0',
    '#808080', '#ff0000', '#00ff00', '#ffff00', '#0000ff', '#ff00ff', '#00ffff', '#ffffff',
    '#000000', '#00005f', '#000087', '#0000af', '#0000d7', '#0000ff', '#005f00', '#005f5f',
    '#005f87', '#005faf', '#005fd7', '#005fff', '#008700', '#00875f', '#008787', '#0087af',
    '#0087d7', '#0087ff', '#00af00', '#00af5f', '#00af87', '#00afaf', '#00afd7', '#00afff',
    '#00d700', '#00d75f', '#00d787', '#00d7af', '#00d7d7', '#00d7ff', '#00ff00', '#00ff5f',
    '#00ff87', '#00ffaf', '#00ffd7', '#00ffff', '#5f0000', '#5f005f', '#5f0087', '#5f00af',
    '#5f00d7', '#5f00ff', '#5f5f00', '#5f5f5f', '#5f5f87', '#5f5faf', '#5f5fd7', '#5f5fff',
    '#5f8700', '#5f875f', '#5f8787', '#5f87af', '#5f87d7', '#5f87ff', '#5faf00', '#5faf5f',
    '#5faf87', '#5fafaf', '#5fafd7', '#5fafff', '#5fd700', '#5fd75f', '#5fd787', '#5fd7af',
    '#5fd7d7', '#5fd7ff', '#5fff00', '#5fff5f', '#5fff87', '#5fffaf', '#5fffd7', '#5fffff',
    '#870000', '#87005f', '#870087', '#8700af', '#8700d7', '#8700ff', '#875f00', '#875f5f',
    '#875f87', '#875faf', '#875fd7', '#875fff', '#878700', '#87875f', '#878787', '#8787af',
    '#8787d7', '#8787ff', '#87af00', '#87af5f', '#87af87', '#87afaf', '#87afd7', '#87afff',
    '#87d700', '#87d75f', '#87d787', '#87d7af', '#87d7d7', '#87d7ff', '#87ff00', '#87ff5f',
    '#87ff87', '#87ffaf', '#87ffd7', '#87ffff', '#af0000', '#af005f', '#af0087', '#af00af',
    '#af00d7', '#af00ff', '#af5f00', '#af5f5f', '#af5f87', '#af5faf', '#af5fd7', '#af5fff',
    '#af8700', '#af875f', '#af8787', '#af87af', '#af87d7', '#af87ff', '#afaf00', '#afaf5f',
    '#afaf87', '#afafaf', '#afafd7', '#afafff', '#afd700', '#afd75f', '#afd787', '#afd7af',
    '#afd7d7', '#afd7ff', '#afff00', '#afff5f', '#afff87', '#afffaf', '#afffd7', '#afffff',
    '#d70000', '#d7005f', '#d70087', '#d700af', '#d700d7', '#d700ff', '#d75f00', '#d75f5f',
    '#d75f87', '#d75faf', '#d75fd7', '#d75fff', '#d78700', '#d7875f', '#d78787', '#d787af',
    '#d787d7', '#d787ff', '#d7af00', '#d7af5f', '#d7af87', '#d7afaf', '#d7afd7', '#d7afff',
    '#d7d700', '#d7d75f', '#d7d787', '#d7d7af', '#d7d7d7', '#d7d7ff', '#d7ff00', '#d7ff5f',
    '#d7ff87', '#d7ffaf', '#d7ffd7', '#d7ffff', '#ff0000', '#ff005f', '#ff0087', '#ff00af',
    '#ff00d7', '#ff00ff', '#ff5f00', '#ff5f5f', '#ff5f87', '#ff5faf', '#ff5fd7', '#ff5fff',
    '#ff8700', '#ff875f', '#ff8787', '#ff87af', '#ff87d7', '#ff87ff', '#ffaf00', '#ffaf5f',
    '#ffaf87', '#ffafaf', '#ffafd7', '#ffafff', '#ffd700', '#ffd75f', '#ffd787', '#ffd7af',
    '#ffd7d7', '#ffd7ff', '#ffff00', '#ffff5f', '#ffff87', '#ffffaf', '#ffffd7', '#ffffff',
    '#080808', '#121212', '#1c1c1c', '#262626', '#303030', '#3a3a3a', '#444444', '#4e4e4e',
    '#585858', '#606060', '#666666', '#767676', '#808080', '#8a8a8a', '#949494', '#9e9e9e',
    '#a8a8a8', '#b2b2b2', '#bcbcbc', '#c6c6c6', '#d0d0d0', '#dadada', '#e4e4e4', '#eeeeee'
  ].map { |s| parse_color(s) }

  class << self
    def color_diff(c1, c2)
      c1.zip(c2).map { |x, y| (x - y).abs }.inject(0, :+)
    end

    def to_256_color(rgb)
      s = parse_color(rgb)
      COLOR_256.each_with_index.min_by { |c, _i| color_diff(c, s) }[1]
    end

    def gen_highlight_cmd(name, fg, bg, term = nil)
      ret = "highlight #{name}"
      if fg
        cfg = to_256_color(fg)
        ret << " ctermfg=#{cfg} guifg=#{fg}"
      end
      if bg
        cbg = to_256_color(bg)
        ret << " ctermbg=#{cbg} guibg=#{bg}"
      end
      ret << " cterm=#{term} gui=#{term}" if term
      ret
    end

    def gen_link_cmd(name1, name2)
      "highlight! link #{name1} #{name2}"
    end
  end
end

PREFIX = 'StatusLine_'.freeze
BG_ACTIVE = '#222222'.freeze
BG_INACTIVE = '#111111'.freeze
ACTIVE_SUFFIX = '_C'.freeze
INACTIVE_SUFFIX = '_NC'.freeze

class ItemSimple
  def initialize(name, str, active, inactive)
    @name = name
    @str = str
    @active = active.is_a?(Array) ? active : [active, BG_ACTIVE]
    @inactive = inactive.is_a?(Array) ? inactive : [inactive, BG_INACTIVE]
  end

  def get_highlight_groups
    [[@name, @active, @inactive]]
  end

  def get_str
    [@name, @str]
  end
end

class ItemLint
  NAME = 'LintStatus'.freeze
  LOAD = NAME + '_LINT_LOAD'
  GOOD = NAME + '_LINT_GOOD'
  WARN = NAME + '_LINT_WARN'
  ERROR = NAME + '_LINT_ERROR'
  class << self
    def get_highlight_groups
      [
        [LOAD, ['#DADADA', '#0000AF'], ['#005FD7', BG_INACTIVE]],
        [GOOD, ['#8AE234', BG_ACTIVE], ['#5FAF00', BG_INACTIVE]],
        [WARN, ['#DADADA', '#5F005F'], ['#870087', BG_INACTIVE]],
        [ERROR, ['#EEEEEE', '#870000'], ['#D70000', BG_INACTIVE]]
      ]
    end

    def get_str
      [NAME, '%{GetLintStatus()}']
    end

    # TODO: helper to register this onto neovim
    def get_lint_status(nvim)
      buf = nvim.get_current_buf.number
      loading = false
      error_cnt = 0
      warning_cnt = 0
      begin
        if nvim.call_function('ale#engine#IsCheckingBuffer', [buf]) != 0
          loading = true
        else
          cnts = nvim.call_function('ale#statusline#Count', [buf])
          error_cnt += cnts['error'] + cnts['style_error']
          warning_cnt += cnts['warning'] + cnts['style_warning']
        end
      rescue StandardError
      end
      begin
        error_cnt += nvim.call_function('youcompleteme#GetErrorCount', [])
        warning_cnt += nvim.call_function('youcompleteme#GetWarningCount', [])
      rescue StandardError
      end
      color, status = if loading then [LOAD, '.']
                      elsif error_cnt > 0 then [ERROR, 'x']
                      elsif warning_cnt > 0 then [WARN, 'w']
                      else [GOOD, 'o']
                      end
      nvim.command(Helper.gen_link_cmd(PREFIX + NAME, PREFIX + color))
      # Something strip the space before...
      "\u00a0#{status} "
    end
  end
end

ITEMS_LEFT = [
  ItemLint
].freeze

ITEMS_RIGHT = [
  ItemSimple.new('FN', '%F ', '#729FCF', '#A9A9A9'),
  ItemSimple.new('FF', '[%{&encoding}/%{&fileformat}/%Y] ', '#EF2929', '#AF0000'),
  ItemSimple.new('LC', '%l,%c ', '#FCE94F', '#878700'),
  ItemSimple.new('PS', '%4P ', '#8AE234', '#5FAF00')
].freeze

def init_highlights
  cmds = []
  grps = []
  (ITEMS_LEFT + ITEMS_RIGHT).each do |it|
    it.get_highlight_groups.each do |name, active, inactive|
      cmds << Helper.gen_highlight_cmd(PREFIX + name + ACTIVE_SUFFIX, *active)
      cmds << Helper.gen_highlight_cmd(PREFIX + name + INACTIVE_SUFFIX, *inactive)
      grps << name
    end
  end
  cmds << Helper.gen_highlight_cmd('StatusLine', nil, BG_ACTIVE, 'none')
  cmds << Helper.gen_highlight_cmd('StatusLineNC', nil, BG_INACTIVE, 'none')
  [cmds, grps]
end

HIGHLIGHT_CMDS, HIGHLIGHT_GRPS = init_highlights

def set_highlight_groups(nvim, active)
  current = nvim.get_current_buf.number
  HIGHLIGHT_GRPS.each do |name|
    if current == active
      nvim.command(Helper.gen_link_cmd(PREFIX + name, PREFIX + name + ACTIVE_SUFFIX))
    else
      nvim.command(Helper.gen_link_cmd(PREFIX + name, PREFIX + name + INACTIVE_SUFFIX))
    end
  end
  ''
end

def build_status_line(nvim)
  ret = "%{SetHighlightGroups(#{nvim.get_current_buf.number})}"
  ITEMS_LEFT.each do |it|
    hi, s = it.get_str
    ret << "%##{PREFIX}#{hi}##{s}"
  end
  ret << '%*'
  ret << '%=%<'
  ITEMS_RIGHT.each do |it|
    hi, s = it.get_str
    ret << "%##{PREFIX}#{hi}##{s}"
  end
  ret << '%*'
  ret
end

Neovim.plugin do |plug|
  # plug.function(:BuildStatusLine, sync: true) do |nvim|
  #   build_status_line(nvim)
  # end
  # plug.autocmd('VimEnter,ColorScheme') do |nvim|
  #   HIGHLIGHT_CMDS.each { |c| nvim.command(c) }
  # end
  # plug.function(:SetHighlightGroups, nargs: 1, sync: true) do |nvim, active|
  #   set_highlight_groups(nvim, active)
  # end
  # plug.function(:GetLintStatus, sync: true) do |nvim|
  #   ItemLint.get_lint_status(nvim)
  # end
end
