 M.deps.dap.fn.dap_continue = function ()
    if vim.fn.filereadable(".vscode/launch.json") then
      M.deps.dap.internals.dap_vscode_launch_file_reader.module.load_launchjs(
        nil,
        {
          ["pwa-node"] = M.deps.dap.langs.js_based_langs,
          ["node"] = M.deps.dap.langs.js_based_langs,
        }
      )
    end

    M.deps.dap.package.continue()
end
