local status_ok, npairs = pcall(require, "nvim-autopairs")
if not status_ok then
  M.deps.npairs = { package = nil, name = 'npairs' }
  return
end

npairs.setup({
    check_ts = true,
    ts_config = {
      lua = { "string", "source" },
      javascript = { "string", "template_string"},
    },
    fast_wrap = {
      map = '<M-e>',
      chars = { '{', '[', '(', '"', "'" },
      pattern = [=[[%'%"%>%]%)%}%,]]=],
      end_key = '$',
      keys = 'qwertyuiopzxcvbnmasdfghjkl',
      check_comma = true,
      highlight = 'Search',
      highlight_grey='Comment'
    },
})

M.deps.npairs = { package = npairs, name = 'npairs' }
