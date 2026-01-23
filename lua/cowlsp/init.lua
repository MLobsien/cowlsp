local M = {}

M.content_win = nil

local utils = require("cowlsp.utils")

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
          vim.list_extend(result, vim.lsp.util.convert_input_to_markdown_lines(client.result.contents))
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
      utils.attach_cow_window(hover_buf, hover_win, M.config)
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
