--!strict
--// Shiawase \\--

type Thread = {
    FunctionName: string,
    ThreadAddressOrSignal: thread? | RBXScriptConnection?,
    Runtime: number,
    Destruct: () -> nil,
}

type Threads = {
    [number]: Thread
}


local Task = task
local Type = type
local String = string
local Tick = tick

local Library = {}
local ActiveThreads: Threads = {}
Library.__index = Library

function Library.CreateThread(SignalOrDelay: number | RBXScriptSignal, callback: (...any) -> (), ...: any): Thread
    local CallbackName: string | nil = debug.info(callback, "n");
    local RunningThread: Thread = setmetatable({
        FunctionName = (Type(CallbackName) == "string" and String.len(CallbackName) >= 1 and CallbackName) or "N/A",
        Runtime = Tick(),
        ThreadAddressOrSignal = nil,
        Destruct = function(self)
            local connection = self.ThreadAddressOrSignal;
            if Type(connection) == "thread" then
                Task.cancel(connection);
            elseif connection and connection.Disconnect then
                connection:Disconnect();
            end
            self.ThreadAddressOrSignal = nil; --// self:Destroy() ?
        end,
    }, Library)

    local additionalArgs = {...};

    if Type(SignalOrDelay) == "number" then
        local delay = SignalOrDelay;
        RunningThread.ThreadAddressOrSignal = Task.spawn(function()
            while true do
                Task.wait(delay);
                callback(unpack(additionalArgs));
            end
        end)
    elseif Type(SignalOrDelay) == "userdata" and SignalOrDelay.Connect then
        local connection
        connection = SignalOrDelay:Connect(function(...)
            local signalArgs = {...}
            if SignalOrDelay == game:GetService("RunService").Heartbeat then
                -- Rem time elapsed argument (default first arg for heartbeat)
                table.remove(signalArgs, 1);
            end
            callback(unpack(additionalArgs), unpack(signalArgs));
        end)
        RunningThread.ThreadAddressOrSignal = connection;
    else
        error("[TYPE-ERROR] Invalid SignalOrDelay type");
    end

    ActiveThreads[#ActiveThreads+1] = RunningThread
    return RunningThread;
end

function Library:GetThreads(): Threads
    return ActiveThreads;
end

function Library:GetThreadCount(): number
    return #ActiveThreads;
end

function Library:GetThreadRuntime(thread: Thread): number
    return (Tick() - thread.Runtime);
end

function Library:IsActiveThread(thread: Thread): boolean
    for index,ActiveThread in pairs(ActiveThreads) do
        if (thread == ActiveThread and ActiveThread.ThreadAddressOrSignal ~= nil) then
            return true;
        end
    end
    return false;
end

return Library;