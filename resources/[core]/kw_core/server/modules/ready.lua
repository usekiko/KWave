---@module 'ready'
--- Provides an event-driven mechanism for deferring logic until core data (like Jobs) is loaded,
--- replacing inefficient while-true polling loops.

local Ready = {}

local jobsLoaded = false
local pendingCallbacks = {}

--- Registers a callback to run immediately if Jobs are loaded,
--- or queues it to run once Jobs finish loading.
---@param cb function
function Ready.OnJobsReady(cb)
    if jobsLoaded then
        cb()
    else
        table.insert(pendingCallbacks, cb)
    end
end

--- Mark jobs as loaded and fire all pending callbacks.
--- Only meant to be called by the job loader.
function Ready.SetJobsReady()
    if jobsLoaded then return end
    jobsLoaded = true

    for _, cb in ipairs(pendingCallbacks) do
        local ok, err = pcall(cb)
        if not ok then
            print(("[^1ERROR^7] OnJobsReady callback failed: %s"):format(err))
        end
    end

    -- Clear table to free memory
    pendingCallbacks = {}
end

return Ready
