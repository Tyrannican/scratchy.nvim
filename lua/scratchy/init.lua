local M = {}

local runners = require 'scratchy.runner'

---@class scratchpad.Options
---@field window_config vim.api.keyset.win_config: The configuration for the floating window
---@field result_config vim.api.keyset.win_config: The configuration for the program output window
---@field runners table<string, function>: The runners to execute the code for languages

---@class scratchpad.State
---@field float table<string, number>: Float window and buffer

---@class scratchpad.ExecuteOpts
---@field bufnr number: Buffer containing the scratchpad text
---@field language string: Language of the buffer


---@type scratchpad.State
local state = {
  float = {}
}

---@type scratchpad.Options
local defaults = {
  window_config = {
    relative = "editor",
    border = "rounded",
    height = math.floor(vim.o.lines * 0.7),
    width = math.floor(vim.o.columns * 0.7),
    row = vim.o.lines - math.floor(vim.o.lines * 0.9),
    col = vim.o.columns - math.floor(vim.o.columns * 0.85),
    zindex = 1
  },
  result_config = {
    relative = "win",
    border = "rounded",
    style = "minimal",
    height = 10,
    width = math.floor(vim.o.columns * 0.5),
    row = 10,
    col = 20,
    zindex = 1,
    title = "Output",
    title_pos = "center"
  },
  runners = {
    rust = runners.rust_runner(),
    javascript = runners.generic_runner 'node',
    python = runners.generic_runner 'python3',
    lua = runners.lua_runner()
  }
}

---@type scratchpad.Options
local options = {
  window_config = {},
  result_config = {},
  runners = {}
}

---@param config vim.api.keyset.win_config: The configuration for the floating window
---@param enter boolean?: Whether to enter the buffer or not
---@return table<string, number>
local create_floating_window = function(config, enter)
  enter = enter or false
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, enter, config)

  return { buf = buf, win = win }
end

M.setup = function(opts)
  options = vim.tbl_deep_extend("force", defaults, opts or {})
end


--- Opens a scratch pad and lets the user write code into it
--- The scratchpad will have the language set and will be executed by `M.execute`
---@param language string: The target language of the scratchpad
M.open_scratchpad = function(language)
  if language == '' then
    vim.notify_once(
      '[Scratchy]: Need to specify a language for a scratchpad',
      vim.log.levels.ERROR,
      { title = 'scratchpad.nvim' }
    )
  end

  local float = create_floating_window(options.window_config, true)
  vim.bo[float.buf].filetype = language
  vim.api.nvim_win_set_config(float.win, { title = language .. ' scratchpad', title_pos = 'center' })
  state.float = float

  vim.keymap.set('n', '<leader><leader>sq', function()
    pcall(vim.api.nvim_win_close, state.float.win, true)
    state.float = {}
  end)

  vim.keymap.set('n', '<leader><leader>sr', function()
    M.execute({ bufnr = state.float.buf, language = language })
  end)
end

--- Executes the code in the currently open scratchpad
--- Depending on the language, will execute a different runner
---@param opts scratchpad.ExecuteOpts
M.execute = function(opts)
  local runner = options.runners[opts.language]
  local input = vim.api.nvim_buf_get_lines(opts.bufnr, 0, -1, false)
  local output = runner(input)
  local float = create_floating_window(options.result_config, true)
  vim.api.nvim_buf_set_lines(float.buf, 0, -1, false, output)
  vim.api.nvim_create_autocmd('BufLeave', {
    buffer = float.buf,
    callback = function()
      pcall(vim.api.nvim_win_close, float.win, true)
    end
  })
end

return M
