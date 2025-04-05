local scratchy = require 'scratchy'

vim.api.nvim_create_user_command('Scratchy', function(opts)
  scratchy.open_scratchpad(opts.args)
end, { nargs = 1 })

vim.keymap.set('n', '<leader>sjs', function()
  scratchy.open_scratchpad('javascript')
end)

vim.keymap.set('n', '<leader>srs', function()
  scratchy.open_scratchpad('rust')
end)

vim.keymap.set('n', '<leader>spy', function()
  scratchy.open_scratchpad('python')
end)

vim.keymap.set('n', '<leader>slua', function()
  scratchy.open_scratchpad('lua')
end)
