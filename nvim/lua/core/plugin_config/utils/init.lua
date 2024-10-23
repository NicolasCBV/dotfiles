M.utils = {}

require('core.plugin_config.utils.command-bar')

M.keys.add({
  {
    shortcut = ':',
    cmd = M.utils.command_bar.open,
    desc = 'Open command bar'
  }
})
