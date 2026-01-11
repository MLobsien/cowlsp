local M = {}

M.content_win = nil
M.content = ""

local function random_cow(args)
  if M.config.files then
    table.insert(args, #args, M.config.files[math.random(#M.config.files)])
  else
    table.insert(args, #args, "-r")
  end
end

local function get_cow()
  local args = { "cowsay", "-e", M.config.eyes or "oo", "-T", M.config.tongue or "  ", "Lorem ipsum" }
  if M.config.random then
    random_cow(args)
  else
    table.insert(args, #args, "-f")
    table.insert(args, #args, M.config.cow or "default")
  end

  return args
end

local function get_window_height(win_conf)
  if win_conf.anchor:find("N") then
    return win_conf.height
  else
    return -win_conf.height - 1
  end
end

function M.attach_cow_window(content_buf)
  vim.system(get_cow(), {}, function(result)
    if result.code == 0 then
      local cow_lines = vim.split(result.stdout, "\n")
      cow_lines = table.move(cow_lines, 4, #cow_lines, 1, {})

      vim.schedule(function()
        local config = vim.api.nvim_win_get_config(M.content_win)
        local width = 0
        for _, line in ipairs(cow_lines) do
          width = math.max(width, vim.fn.strdisplaywidth(line))
        end

        local cow_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(cow_buf, 0, -1, false, cow_lines)

        local content_height = get_window_height(config)
        vim.print(config.anchor)
        if content_height + config.row + 2 <= vim.o.lines - #cow_lines then
          local cow_win = vim.api.nvim_open_win(cow_buf, false, {
            relative = "editor",
            row = config.row + content_height + 2,
            col = config.col + 1,
            width = width,
            height = #cow_lines,
            border = "none",
            style = "minimal",
            focusable = false
          })

          vim.api.nvim_create_autocmd({ "WinClosed", "BufDelete" }, {
            buffer = content_buf,
            once = true,
            callback = function()
              if vim.api.nvim_win_is_valid(cow_win) then
                vim.api.nvim_win_close(cow_win, true)
              end
            end
          })
        end
      end)
    else
      vim.notify(result.stderr)
    end
  end)
end

function M.hover()
  if M.content_win and vim.api.nvim_win_is_valid(M.content_win) then
    vim.api.nvim_set_current_win(M.content_win)
    M.content_win = nil
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)

  vim.lsp.buf_request_all(bufnr, "textDocument/hover", {
    textDocument = { uri = vim.uri_from_bufnr(bufnr) },
    position = { line = cursor[1] - 1, character = cursor[2] }
  }, function(responses)
    local result = {}
    local callback = M.config.callback

    if not callback then
      for _, client in ipairs(responses) do
        if not client.err and client.result and client.result.contents then
          table.insert(result, client.result.contents.value)
        end
      end
    else
      result = callback(responses)
    end

    if #result > 0 and result[1] and string.len(result[1]) > 0 then
      local hover_buf, hover_win = vim.lsp.util.open_floating_preview(
        result, "markdown", {
          focusable = true,
          border = {
            "/",
            "-",
            "\\",
            "|",
            "/",
            "-",
            "\\",
            "|"
          }
        }
      )

      M.content_win = hover_win
      M.attach_cow_window(hover_buf)
    end
  end)
end

function M.setup(opts)
  M.config = opts or {}

  vim.keymap.set(
    "n",
    M.config.key or "<S-k>",
    M.hover,
    {
      desc = "Cow speaks for LSP",
      noremap = true,
      silent = true
    }
  )
end

return M
