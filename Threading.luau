--!strict
--!native
--!optimize 2
--// Shiawase \\--

type Thread = {
	FunctionName: string,
	ThreadAddressOrSignal: (thread | RBXScriptConnection)?,
	Runtime: number,
	Destruct: () -> nil,
}

type Threads = {
	[number]: Thread
}

local HB = game:GetService("RunService").Heartbeat
local Task = task
local Type = typeof
local Tick = tick

local Library = {}
local ActiveThreads: Threads = {}
Library.__index = Library

function Library.CreateThread(SignalOrDelay: number | RBXScriptSignal, callback: (...any) -> (), ...: any): Thread
	local CallbackName: string = debug.info(callback, "n")
	local RunningThread = setmetatable({
		FunctionName = (Type(CallbackName) == "string" and #CallbackName >= 1 and CallbackName) or "N/A",
		Runtime = Tick(),
		ThreadAddressOrSignal = nil,
		Destruct = function(self)
			local ThreadOrConnection = self.ThreadAddressOrSignal

			if Type(ThreadOrConnection) == "thread" then
				Task.cancel(ThreadOrConnection)
			else
				ThreadOrConnection:Disconnect()
			end
			
			ThreadOrConnection = nil
		end,
	} :: Thread, Library :: typeof(Library))

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
			if Signal == HB then
				-- Rem time elapsed argument (default first arg for heartbeat) / oogway -- why
				table.remove(signalArgs, 1)
			end

			callback(unpack(table.move(signalArgs, 1, #signalArgs, #additionalArgs + 1, additionalArgs)))
		end)

		RunningThread.ThreadAddressOrSignal = Connection
	else
		error(debug.traceback(`expected type 'thread' or 'RBXScriptSignal' at argument #1, got '{Type(SignalOrDelay)}'`))
	end

	ActiveThreads[#ActiveThreads+1] = RunningThread
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
