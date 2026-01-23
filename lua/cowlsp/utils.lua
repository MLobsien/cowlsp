local M = {}

function M.random_cow(args, config)
  if config.files then
    table.insert(args, #args, "-f")
    table.insert(args, #args, config.files[math.random(#config.files)])
  else
    table.insert(args, #args, "-r")
  end
end

function M.get_cow_config(config)
  local cow_args = { "cowsay", "-e", config.eyes, "-T", config.tongue, "Lorem ipsum" }

  if config.random then
    M.random_cow(cow_args, config)
  else
    table.insert(cow_args, #cow_args, "-f")
    table.insert(cow_args, #cow_args, config.cow)
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

function M.attach_cow_window(base_buf, base_win, plugin_config)
  vim.system(M.get_cow_config(plugin_config), {}, function(result)
    if result.code == 0 then
      local cow = vim.split(result.stdout, "\n")
      -- Remove speech bubble and trailing line
      cow = table.move(cow, 4, #cow - 1, 1, {})

      vim.schedule(function()
        local config = vim.api.nvim_win_get_config(base_win)

        local cow_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(cow_buf, 0, -1, false, cow)

        local cow_width = 0
        for _, line in ipairs(cow) do
          cow_width = math.max(cow_width, vim.fn.strdisplaywidth(line))
        end

        local content_end = get_window_last_row(config)
        local editor_end = vim.api.nvim_win_get_config(0).height

        local cow_height = #cow
        local remaining = editor_end - content_end

        if remaining < cow_height then
          if config.row == content_end then
            cow_height = remaining
          else
            content_end = content_end - cow_height - 1

            local height = config.height - cow_height - 1

            if height > 0 then
              vim.api.nvim_win_set_config(base_win, {
                height = height
              })
            end
          end
        end

        if cow_height > 0 and cow_width > 0 then
          local cow_win = vim.api.nvim_open_win(cow_buf, false, {
            relative = "win",
            row = content_end,
            col = config.col + 1,
            width = cow_width,
            height = cow_height,
            border = "none",
            style = "minimal",
            focusable = false
          })

          vim.api.nvim_create_autocmd({ "WinClosed", "BufDelete" }, {
            buffer = base_buf,
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

return M
