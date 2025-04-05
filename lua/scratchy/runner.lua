local M = {}

---Generates a generic runner that runs scripts with the
---supplied program
---@param program string: The name of the program to execute
---@return function
M.generic_runner = function(program)
  return function(code)
    local infile = vim.fn.tempname()
    vim.fn.writefile(code, infile)
    local result = vim.system({ program, infile }, { text = true }):wait()
    return vim.split(result.stdout, "\n")
  end
end

---Generates a runner to execute Rust code with Rustc
---@return function
M.rust_runner = function()
  return function(code)
    local infile = vim.fn.tempname() .. ".rs"
    local outfile = infile:sub(1, -4)
    vim.fn.writefile(code, infile)
    local result = vim.system({ "rustc", infile, "-o", outfile }, { text = true }):wait()
    if result.code ~= 0 then
      return vim.split(result.stderr, "\n")
    end

    result = vim.system({ outfile }, { text = true }):wait()
    return vim.split(result.stdout, "\n")
  end
end

---Generates a runner to execute Lua code
---@return function
M.lua_runner = function()
  return function(code)
    local og_print = print
    local output = {}
    print = function(...)
      local args = { ... }
      local message = table.concat(vim.tbl_map(tostring, args), "\t")
      table.insert(output, message)
    end

    local luablock = loadstring(vim.fn.join(code, "\n"))
    pcall(function()
      if not luablock then
        table.insert(output, "Invalid Lua Code")
      else
        luablock()
      end
    end)

    print = og_print

    return output
  end
end

return M
