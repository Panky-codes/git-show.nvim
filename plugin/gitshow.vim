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

-- TODO: Use a specific format for git blame
-- using root doesn't differetiate a the boundary commit
local blame_cmd = string.format("git --no-pager blame --root -L %s,+1 -- %s", linenum, filename)

local grep_and_show = ' | grep -Po \"^([\\w]+)\" | xargs git show'

local final_cmd = switch_dir .. " && " .. blame_cmd .. grep_and_show


local current_ui = vim.api.nvim_list_uis()
-- TODO: change these into options
local width = current_ui[1]["width"] / 2
local height = current_ui[1]["height"] / 2

local col = current_ui[1]["width"] / 2 - (width / 2)
local row = current_ui[1]["height"] / 2 - (height / 2)

local buf = vim.api.nvim_create_buf(false, true)

vim.api.nvim_buf_set_option(buf, 'filetype', 'diff')

local id = vim.fn.jobstart(final_cmd, {
    stdout_buffered = true,
    on_stdout = function (_, data, _)
    local i = 0
    for _, line in ipairs(data) do
        vim.api.nvim_buf_set_lines(buf, i , i, false, {line})
	i = i + 1
    end
    -- Make sure the buffer is not modifiable and move the cursor to the top
        vim.api.nvim_buf_set_option(buf, 'modifiable', false)
	vim.api.nvim_win_set_cursor(win, {1, 0})
end})

local win = vim.api.nvim_open_win(buf, true, {relative='editor', width=width, 
row = row , col = col,
bufpos = {200, 0},
height = height, style= 'minimal'})

vim.api.nvim_win_set_option(win, "number", true)

EOF
endfunction

nmap <M-C-G> :call WhoWroteWhat()<CR>

