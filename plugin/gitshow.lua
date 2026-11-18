vim.cmd([[
function! WhoWroteWhat()
  lua require('gitshow').show()
endfunction
]])

vim.api.nvim_set_keymap("n", "<M-C-G>", ":call WhoWroteWhat()<CR>", {})
