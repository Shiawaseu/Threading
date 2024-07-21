# Threading
- Luau library for managing threads and signals.

## Usage

```lua
-- Declare the library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/shiawaseu/threading/main/Threading.luau", true))()

-- Example callback function
local function exampleCallback(...)
    print("Callback:", ...)
end

-- Run a while loop thread for callback with a delay
-- local thread = Library.CreateThread(1, exampleCallback, "test")

-- Connect a callback to any Signal
local HBthread = Library.CreateThread(game:GetService("RunService").Heartbeat, exampleCallback, "Hello", "World")

-- Getting threads
local activeThreads = Library:GetThreads()
for i, thread in pairs(activeThreads) do
    print("Thread:", i, thread.FunctionName)
end

print(Library:IsActiveThread(HBthread)) -- Output: true

-- Shutting down threads
HBthread:Destruct()

print(Library:IsActiveThread(HBthread)) -- Output: false
```
## Thread Object Reference
- `FunctionName <string>`
  - Function Name which was originally the callback name, `N/A` if the callback is anonymous

- `Runtime <number>`
  - The seconds that have passed since [epoch](https://en.wikipedia.org/wiki/Epoch)

- `ThreadAddressOrSignal <thread? | RBXScriptConnection? | nil>`
  - The thread the callback is running on if not a signal (delay loop) or the Signal the callback is connected to

- `<function> Destruct(<void>): <nil>`
## Library API Reference
- `Library.CreateThread(SignalOrDelay: <number> | <RBXScriptSignal>, callback: <function(...any)>, ...: <any>): <Thread>`
  - Creates a thread with a delay or signal. Returns a `Thread` object.

- `<function> Library:GetThreads(<void>): <Threads>`
  - Returns a table of active threads.
    - Destructed threads still remain, but no longer contain their thread/signal.

- `<function> Library:GetThreadCount(<void>): <number>`
  - Returns the count of active threads.

- `<function> Library:IsActiveThread(thread: <Thread>) <boolean>`
  - Returns wether the provided `Thread` object is active & running or not.

- `<function> Library:GetThreadRuntime(thread: <Thread>) <number>`
  - Returns the elapsed time since the thread has started.