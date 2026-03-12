-- Run :Copilot auth to setup copilot directly with github copilot
local function get_visual()
  local curpos = vim.fn.getcurpos()
  local one = { row = curpos[2] - 1, col = curpos[3] - 1 }
  local two = { row = vim.fn.line("v") - 1, col = vim.fn.col("v") - 1 }

  if one.row == two.row then
    if one.col > two.col then
      one, two = two, one
    end
  elseif one.row > two.row then
    one, two = two, one
  end

  two.col = two.col + 1
  return { start = one, ["end"] = two }
end

local function relative_path(filepath)
  local dir = vim.fn.fnamemodify(filepath, ":h")
  local git_root = vim.trim(vim.fn.system("git -C" .. vim.fn.shellescape(dir) .. " rev-parse --show-toplevel 2>/dev/null"))
  if git_root == "" then
    return filepath:gsub("^" .. vim.env.HOME .. "/", "~/")
  end
  local root_name = vim.fn.fnamemodify(git_root, ":t")
  local rel = filepath:sub(#git_root + 2)
  return root_name .. "/" .. rel
end

local function send_to_opencode(prompt)
  vim.fn.system("tmux send-keys -t ai " .. vim.fn.shellescape(prompt))
  vim.fn.system("tmux select-window -t ai")
end

return {
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			require("copilot").setup({
				panel = { enabled = false },
				suggestion = {
					enabled = false,
				},
				filetypes = {
					markdown = true,
					help = true,
				},
				next_edit_suggestion = {
					enabled = true,
					keymap = "<C-j>",
				},
			})
		end,
	},
  {
    "NickvanDyke/opencode.nvim",
    dependencies = { "folke/snacks.nvim" },
    config = function()
      require("opencode.config").opts.server = {
        start = function()
          vim.fn.system("tmux select-window -t ai")
        end,
        stop = function() end,
        toggle = function()
          vim.fn.system("tmux select-window -t ai")
        end,
      }
    end,
    keys = {
      {
        "<leader>oa",
        function()
          local filepath = vim.fn.expand("%:p")
          local relpath = relative_path(filepath)

          vim.ui.input({ prompt = "Ask AI (" .. relpath .. "): " }, function(input)
            if not input or input == "" then return end
            local prompt = relpath .. "\n" .. input .. "\n"
            send_to_opencode(prompt)
          end)
        end,
        desc = "Open AI window",
        mode = "n",
      },
      {
        "<leader>oa",
        function()
          local range = get_visual()
          local filepath = vim.fn.expand("%:p")
          local relpath = relative_path(filepath)
          local start_line = range.start.row + 1
          local end_line = range["end"].row + 1

          vim.ui.input({ prompt = "Ask AI (" .. start_line .. "-" .. end_line .. "): " }, function(input)
            if not input or input == "" then return end
            local prompt = relpath .. " (" .. start_line .. "-" .. end_line .. ")\n" .. input .. "\n"
            send_to_opencode(prompt)
          end)
        end,
        desc = "Send selection to AI",
        mode = "v",
      },
    },
  }
}
