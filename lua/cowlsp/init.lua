local M = {}

M.hover_win = nil

local function hover(callback)
  if M.hover_win and vim.nvim_win_is_valid(M.hover_win) then
    vim.api.nvim_set_current_win(M.hover_win)
    M.hover_win = nil
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(bufnr)

  vim.lsp.buf_request_all(bufnr, "textDocument/hover", {
    textDocument = { uri = vim.uri_from_bufnr(bufnr) },
    position = { line = cursor[1] - 1, character = cursor[2] }
  }, function(responses)
    local results = {}
    if not callback then
      results = responses
    else
      results = callback(responses)
    end

    local cow_said = vim.system('cow say "' .. table.concat(result, "\n") .. '"')

    local _, hover_win = vim.lsp.util.open_floating_preview(
      vim.split(results, "\n"), "markdown"
    )

    M.hover_win = hover_win
  end)
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  vim.keymap.set(
    "n",
    M.config.key or "<S-k>",
    function()
      hover(M.config.callback or {})
    end,
    {
      desc = "Cow speaks for LSP",
      noremap = true,
      silent = true
    }
  )
end

return M
