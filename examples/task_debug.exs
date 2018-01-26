strings = ["fast", "long string", "cool", "longer string", "there are many of these", "quick", "three", "too long"]
timeout = 20_000

lambda = (fn text ->
    chars = text |> String.codepoints |> Enum.count
    Process.sleep(chars*1000)

    chars
  end)

# WILL FAIL, timeout smaller than 23secs, the Task won't complete that quick
# stream = Task.async_stream(strings, lambda, timeout: timeout)
# Enum.map(stream, &(&1))

# FIRST SOLUTION

tasks = strings
        |> Enum.map(fn text ->
          Task.async(fn -> lambda.(text) end)
        end)

Process.sleep(timeout)

# Tempting to convert all these Enum calls to
# Flow, so we could do them in parallel, but the state of a task
# can only be obtained from the process which spawned the task.
# Since Flow spawns a process for each Flow stage, we would get
# an error like "Task must be queried from the owner" this:
#
# ** (exit) exited in: GenStage.close_stream(%{})
#     ** (EXIT) an exception was raised:
#         ** (ArgumentError) task %Task{owner: #PID<0.84.0>, pid: #PID<0.447.0>, ref: #Reference<0.3648480712.1815609347.163703>} must be queried from the owner but was queried from #PID<0.458.0>
#             (elixir) lib/task.ex:715: Task.shutdown/2
#             (flow) lib/flow/materialize.ex:547: anonymous fn/4 in Flow.Materialize.mapper/2
#             (flow) lib/flow/materialize.ex:516: Flow.Materialize."-mapper_ops/1-lists^foldl/2-1-"/3
#             (flow) lib/flow/materialize.ex:516: anonymous fn/5 in Flow.Materialize.mapper_ops/1
#             (flow) lib/flow/map_reducer.ex:49: Flow.MapReducer.handle_events/3
#             (gen_stage) lib/gen_stage.ex:2581: GenStage.consumer

tasks_result = tasks
               |> Enum.map(&Task.shutdown(&1))
               |> Enum.map(fn result ->
                 case result do
                   {:ok, result} -> result
                   _             -> nil
                 end
               end)
               |> Enum.to_list()
               |> Enum.reject(&is_nil(&1))

# IMPROVED SOLUTION, doesn't work
# We are waiting *sequentially* for each Task to yield,
# this is cumulative!
# We need the previous solution to wait once, and then try
# to get the results

# tasks_result = strings
#                |> Enum.map(fn text ->
#                  Task.async(fn -> lambda.(text) end)
#                end)
#                |> Enum.map(fn task ->
#                  case Task.yield(task, timeout) || Task.shutdown(task) do
#                    {:ok, result} -> result
#                    _             -> nil
#                  end
#                end)
#                |> Enum.to_list()
#                |> Enum.reject(&is_nil(&1))

IO.puts inspect(tasks_result)
