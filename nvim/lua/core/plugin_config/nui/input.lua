local status_ok, nui = pcall(require, "nui.input")
if not status_ok then
  M.deps.nui_input = { package = nil, name = "nui.input" }
end

M.deps.nui_input = { package = nui, name = "nui.input" }
