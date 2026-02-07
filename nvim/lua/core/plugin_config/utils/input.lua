M.utils.input = {
  fn = {
    build_config = function (prompt, on_close, on_change, on_submit, default_value)
      return {
        popup = {
          position = {
            row = "10%",
            col = "50%"
          },
          size = {
            width = "60%"
          },
          border = {
            style = "rounded"
          },
          win_options = {
            winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
          },
        },
        input = {
          prompt = prompt,
          default_value = default_value ~= "" and default_value or "",
          on_change = on_change,
          on_close = on_close,
          on_submit = on_submit
        }
      }
    end,
    prepare_input = function (configs)
      return M.deps.nui_input.package(configs.popup, configs.input)
    end
  }
}

