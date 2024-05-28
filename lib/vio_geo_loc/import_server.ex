defmodule VioGeoLoc.ImportServer do
  use GenServer

  alias VioGeoLoc.Import

  @state %{
    error_file_path: nil,
    error_log_file: nil,
    start_time: nil,
    source: nil,
    accepted: 0,
    rejected: 0
  }

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    source = Keyword.fetch!(opts, :source)
    error_file_path = Keyword.get(opts, :error_file_path, "./errors.txt")
    start_time = System.monotonic_time()

    {:ok, error_file} = File.open(error_file_path, [:write, :utf8])

    state = %{
      @state
      | error_file_path: error_file_path,
        error_log_file: error_file,
        start_time: start_time,
        source: source
    }

    {:ok, state, {:continue, :import}}
  end

  @impl true
  def handle_continue(:import, state) do
    function =
      state.source
      |> case do
        "http" <> _ -> :import_from_url
        _ -> :import_from_path
      end

    server_pid = self()

    Task.async(Import, function, [state.source, server_pid])

    {:noreply, state}
  end

  @impl true
  def handle_info({:error, error}, state) do
    IO.write(state.error_log_file, "#{inspect(error)}\n")

    state = Map.update!(state, :rejected, &(&1 + 1))

    {:noreply, state}
  end

  @impl true
  def handle_info(:accepted, state) do
    state = Map.update!(state, :accepted, &(&1 + 1))

    {:noreply, state}
  end

  @impl true
  def handle_info(:done, state) do
    File.close(state.error_log_file)

    print_state(state)

    {:stop, :normal, state}
  end

  def print_state(state) do
    IO.puts(~s"""
    Elapsed time: #{System.monotonic_time() - state.start_time} ms
    Accepted: #{state.accepted}
    Rejected: #{state.rejected}
    Total: #{state.accepted + state.rejected}

    Errors written to: #{state.error_file_path}
    """)
  end
end
