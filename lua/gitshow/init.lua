local M = {}

local function notify(msg, level)
    vim.notify("git-show: " .. msg, level or vim.log.levels.ERROR)
end

-- Buffered job output ends with an empty item for the final newline.
local function strip_trailing_empty(lines)
    if lines[#lines] == "" then
        table.remove(lines)
    end
    return lines
end

-- Run `cmd` (a list, so no shell is involved) in `cwd`, optionally writing
-- `input` (a list of lines) to its stdin. Calls on_done(code, stdout, stderr).
local function run(cmd, cwd, input, on_done)
    local stdout, stderr = {}, {}
    local id = vim.fn.jobstart(cmd, {
        cwd = cwd,
        stdout_buffered = true,
        stderr_buffered = true,
        on_stdout = function(_, data)
            stdout = data
        end,
        on_stderr = function(_, data)
            stderr = data
        end,
        on_exit = function(_, code)
            on_done(code, strip_trailing_empty(stdout), strip_trailing_empty(stderr))
        end,
    })
    if id <= 0 then
        notify("failed to run " .. cmd[1])
        return
    end
    if input then
        vim.fn.chansend(id, input)
    end
    vim.fn.chanclose(id, "stdin")
end

local function open_window(buf)
    local width = math.floor(vim.o.columns / 2)
    local height = math.floor(vim.o.lines / 2)

    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
        style = "minimal",
    })
    vim.wo[win].number = true
end

local function show_commit(hash, cwd)
    run({ "git", "--no-pager", "show", hash }, cwd, nil, function(code, out, err)
        if code ~= 0 then
            notify(table.concat(err, "\n"))
            return
        end

        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)
        vim.bo[buf].bufhidden = "wipe"
        vim.bo[buf].modifiable = false
        vim.bo[buf].filetype = "diff"

        open_window(buf)
    end)
end

function M.show()
    local filename = vim.api.nvim_buf_get_name(0)
    if filename == "" or vim.bo.buftype ~= "" then
        notify("current buffer is not a file")
        return
    end

    local cwd = vim.fn.fnamemodify(filename, ":p:h")
    if vim.fn.isdirectory(cwd) ~= 1 then
        notify("directory does not exist: " .. cwd)
        return
    end

    local linenum = vim.api.nvim_win_get_cursor(0)[1]

    -- Blame the buffer contents rather than the file on disk, so unsaved
    -- edits don't shift the line numbers.
    local contents = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    table.insert(contents, "")

    local blame_cmd = {
        "git", "--no-pager", "blame", "--root", "--porcelain",
        "--contents", "-",
        "-L", linenum .. ",+1",
        "--", filename,
    }

    run(blame_cmd, cwd, contents, function(code, out, err)
        if code ~= 0 then
            notify(table.concat(err, "\n"))
            return
        end

        -- First porcelain line: "<hash> <orig-line> <final-line> <count>"
        local hash = out[1] and out[1]:match("^(%x+) ")
        if not hash then
            notify("could not parse git blame output")
            return
        end
        if hash:match("^0+$") then
            notify("line is not committed yet", vim.log.levels.WARN)
            return
        end

        show_commit(hash, cwd)
    end)
end

return M
