--!strict
--!native
--!optimize 2
--// Shiawase \\--

type Thread = {
	FunctionName: string,
	ThreadAddressOrSignal: (thread | RBXScriptConnection)?,
	Runtime: number,
	Destruct: (self: Thread) -> nil,
}

type Threads = {
	[number]: Thread
}

local Stepped = game:GetService("RunService").Stepped
local Task = task
local Type = typeof
local Tick = tick

local Library = {}
local ActiveThreads: Threads = {}
Library.__index = Library

function Library.CreateThread(SignalOrDelay: number | RBXScriptSignal, callback: (...any) -> (), PerserveRuntimeParameters: boolean, ...: any): Thread
	local CallbackName: string = debug.info(callback, "n")
	local RunningThread = setmetatable({} :: any, Library) :: Thread
	RunningThread.FunctionName = (Type(CallbackName) == "string" and #CallbackName >= 1 and CallbackName) or "N/A"
	RunningThread.Runtime = Tick()
	RunningThread.ThreadAddressOrSignal = nil
	RunningThread.Destruct = function(self)
		local ThreadOrConnection: (RBXScriptConnection | thread)? = self.ThreadAddressOrSignal

		if typeof(ThreadOrConnection) == "thread" then
			Task.cancel(ThreadOrConnection)
		elseif typeof(ThreadOrConnection) == "RBXScriptConnection" then
			ThreadOrConnection:Disconnect()
		end

		ThreadOrConnection = nil
	end

	local additionalArgs = {...}

	if Type(SignalOrDelay) == "number" then
		local delay = SignalOrDelay :: number
		RunningThread.ThreadAddressOrSignal = Task.spawn(function()
			while Task.wait(delay) do
				callback(unpack(additionalArgs))
			end
		end)
	elseif Type(SignalOrDelay) == "RBXScriptSignal" then
		local Signal = SignalOrDelay :: RBXScriptSignal
		local Connection

		Connection = Signal:Connect(function(...)
			local signalArgs = {...}

			-- Deltas
			if not PerserveRuntimeParameters then
				if Signal == Stepped then
					table.remove(signalArgs, 2)
			    else
					table.remove(signalArgs, 1)
				end
			end

			callback(unpack(table.move(signalArgs, 1, #signalArgs, #additionalArgs + 1, additionalArgs)))
		end)

		RunningThread.ThreadAddressOrSignal = Connection
	else
		error(debug.traceback(`expected type 'thread' or 'RBXScriptSignal' at argument #1, got '{Type(SignalOrDelay)}'`))
	end

	ActiveThreads[#ActiveThreads + 1] = RunningThread
	return RunningThread
end

function Library:GetThreads(): Threads
	return ActiveThreads
end

function Library:GetThreadCount(): number
	return #ActiveThreads
end

function Library:GetThreadRuntime(thread: Thread): number
	return (Tick() - thread.Runtime)
end

function Library:IsActiveThread(thread: Thread): boolean
	local ThreadIdx = table.find(ActiveThreads, thread)
	
	if ThreadIdx and ActiveThreads[ThreadIdx].ThreadAddressOrSignal ~= nil then
		return true
	end
	
	return false
end

return Library