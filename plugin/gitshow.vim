" TODO: Error handling
" TODO: Move it to separate lua files
function! WhoWroteWhat()
lua <<EOF
local filename = vim.api.nvim_buf_get_name(0)

if filename == "" then 
    print ("Give a filename")
end

local linenum = vim.api.nvim_win_get_cursor(0)[1]

if linenum == "" then 
    print ("Error parsing linenum")
end


local switch_dir = string.format("cd $(dirname %s)", filename)

local git_root = string.format("git rev-parse --show-toplevel")

-- TODO: Use a specific format for git blame
-- using root doesn't differetiate a the boundary commit
local blame_cmd = string.format("git blame --root -L %s,+1 -- %s", linenum, filename)

local grep_and_show = ' | grep -Po \"^([\\w]+)\" | xargs git show'

local final_cmd = switch_dir .. " && " .. git_root .. " && " .. blame_cmd .. grep_and_show

local width = 90
local height = 40

local current_ui = vim.api.nvim_list_uis()
local col = current_ui[1]["width"] / 2 - (width / 2)
local row = current_ui[1]["height"] / 2 - (height / 2)

local buf = vim.api.nvim_create_buf(false, true)

vim.api.nvim_buf_set_option(buf, 'filetype', 'diff')

local id = vim.fn.jobstart(final_cmd, {
    stdout_buffered = true,
    on_stdout = function (_, data, _)
    for i, line in ipairs(data) do
        vim.api.nvim_buf_set_lines(buf, i -1 , i  -1, false, {line})
    end
end})

local win = vim.api.nvim_open_win(buf, true, {relative='editor', width=width, 
row = row , col = col,
bufpos = {200, 0},
height = height, style= 'minimal'})

vim.api.nvim_win_set_option(win, "number", true)

EOF
endfunction

" FIXME: The floating window goes to EOF. How to make it point to the top?
map <M-C-G> :call WhoWroteWhat()<CR>

