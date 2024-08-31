local status_ok, github = pcall(require, "github-theme")
if not status_ok then
   M.deps.nightfox = { package = nil, name = 'github-theme' }
   return
end

github.setup({
  options = {
    transparent = true
  }
})

M.deps.fox = { package = github, name = 'github-theme' }

