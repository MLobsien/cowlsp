local M = {}

M.content_win = nil
M.content = ""

require("cmp").event:on("menu_opened", function(evt)
  local win_id = evt.window.entries_win.win
  M.attach_cow_window(vim.api.nvim_win_get_buf(win_id), win_id)
end)

local function random_cow(args)
  if M.config.files then
    table.insert(args, #args, "-f")
    table.insert(args, #args, M.config.files[math.random(#M.config.files)])
  else
    table.insert(args, #args, "-r")
  end
end

local function get_cow()
  local cow_args = { "cowsay", "-e", M.config.eyes, "-T", M.config.tongue, "Lorem ipsum" }

  if M.config.random then
    random_cow(cow_args)
  else
    table.insert(cow_args, #cow_args, "-f")
    table.insert(cow_args, #cow_args, M.config.cow)
  end

  return cow_args
end

local function get_window_last_row(win_conf)
  if win_conf.anchor:find("N") then
    return win_conf.row + win_conf.height + 2
  else
    return win_conf.row
  end
end

function M.attach_cow_window(content_buf, content_win)
  vim.system(get_cow(), {}, function(result)
    if result.code == 0 then
      local cow_lines = vim.split(result.stdout, "\n")
      cow_lines = table.move(cow_lines, 4, #cow_lines, 1, {})

      vim.schedule(function()
        local config = vim.api.nvim_win_get_config(content_win)

        local cow_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(cow_buf, 0, -1, false, cow_lines)

        local cow_width = 0
        for _, line in ipairs(cow_lines) do
          cow_width = math.max(cow_width, vim.fn.strdisplaywidth(line))
        end

        local content_end = get_window_last_row(config)
        local editor_end = vim.api.nvim_win_get_config(0).height

        local cow_height = #cow_lines - 1
        local remaining = editor_end - content_end

        if remaining < cow_height then
          if config.row == content_end then
            cow_height = remaining
          else
            content_end = content_end - cow_height - 1

            vim.api.nvim_win_set_config(content_win, {
              height = config.height - cow_height - 1
            })
          end
        end

        if cow_height > 0 and cow_width > 0 then
          local cow_win = vim.api.nvim_open_win(cow_buf, false, {
            relative = "editor",
            row = content_end,
            col = config.col + 1,
            width = cow_width,
            height = cow_height,
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
        if not client.err and client.result and client.result.contents and client.result.contents.value then
          table.insert(result, client.result.contents.value)
        end
      end
    else
      result = callback(responses)
    end

    if #result > 0 then
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
      M.attach_cow_window(hover_buf, hover_win)
    else
      print("No information available")
    end
  end)
end

function M.setup(opts)
  M.config = vim.tbl_extend("keep", opts, {
    cow = "default",
    key = "<S-k>",
    eyes = "oo",
    tongue = "  ",
    random = false,
    files = nil,
  })

  vim.keymap.set(
    "n",
    M.config.key,
    M.hover,
    {
      desc = "Cow speaks for LSP",
      noremap = true,
      silent = true
    }
  )
end

return M
