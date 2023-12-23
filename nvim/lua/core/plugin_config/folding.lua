local status_ok, ufo = pcall(require, 'ufo')
if not status_ok then
  M.deps.ufo = { package = nil, name = 'ufo' }
  return
end

vim.o.foldcolumn = '1'
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true

local handler = function(virtText, lnum, endLnum, width, truncate)
  local newVirtText = {}
  local suffix = (' ↙ %d'):format(endLnum - lnum)
  local sufWidth = vim.fn.strdisplaywidth(suffix)
  local targetWidth = width - sufWidth
  local curWidth = 0
  for _, chunk in ipairs(virtText) do
    local chunkText = chunk[1]
    local chunkWidth = vim.fn.strdisplaywidth(chunkText)
    if targetWidth > curWidth then
      table.insert(newVirtText, chunk)
    else
      chunkText = truncate(chunkText, targetWidth - curWidth)
      local hlGroup = chunk[2]
      table.insert(newVirtText, { chunk, hlGroup })
      chunkWidth = vim.fn.strdisplaywidth(chunkText)

      if curWidth + chunkWidth < targetWidth then
        suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
      end
      break
    end
    curWidth = curWidth + chunkWidth
  end
  table.insert(newVirtText, { suffix, 'MoreMsg' })
  return newVirtText
end

ufo.setup({
    open_fold_hl_timeout = 150,
    preview = {
      win_config = {
        border = {'', '─', '', '', '', '─', '', ''},
        winhighlight = 'Normal:Folded',
        winblend = 0
      }
    },
    fold_virt_text_handler = handler,
    provider_selector = function(_, _, _)
        return {'treesitter', 'indent'}
    end
})

M.deps.ufo = { package = ufo, name = 'ufo' }
