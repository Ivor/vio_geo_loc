defmodule VioGeoLoc.Import do
  @moduledoc """
  This module is responsible for importing data from a URL or a file path.

  It accepts the url/file_path as well as a pid for the process that is interested in the feedback.

  Urls are streamed chuncked by line while files are streamed by line.

  Errors are reported by sending a message `{:error, error_message}` to the parent_pid.
  Successful inserts are reported by sending a message `:accepted` to the parent_pid.

  When the stream is done, a message `:done` is sent to the parent_pid.

  """

  alias VioGeoLoc.GeoLocations
  alias NimbleCSV.RFC4180, as: CSV

  @doc """

  Converts the url to a stream resource and processes the data by inseting the rows into the database.

  """
  @spec import_from_url(binary(), pid) :: :ok
  def import_from_url(url, parent_pid) do
    remote_stream(url)
    |> process_stream(parent_pid)
  end

  @spec import_from_path(binary(), pid) :: :ok
  def import_from_path(file_path, parent_pid) do
    File.stream!(file_path)
    |> process_stream(parent_pid)
  end

  @doc """
  Accepts a stream of CSV data. Parses the stream line by line, then inserts the data into the database.
  """
  @spec process_stream(Enumerable.t(), pid) :: :ok
  def process_stream(stream, parent_pid) do
    stream
    |> CSV.to_line_stream()
    |> CSV.parse_stream()
    |> Stream.with_index()
    |> Task.async_stream(&sanitize_and_insert(&1, parent_pid),
      max_concurrency: System.schedulers_online()
    )
    |> Stream.run()

    send(parent_pid, :done)
  end

  @doc """
  Accepts a list of strings an index and a pid for the parent process.
  Sanitizes the data and inserts it into the database.
  And sends a message to the parent process with the result.
  """
  @spec sanitize_and_insert({[binary()], integer}, pid) :: :ok
  def sanitize_and_insert({[_, _, _, _, _, _, _] = row, index}, parent_pid) do
    [
      ip_address,
      country_code,
      country,
      city,
      latitude,
      longitude,
      mystery_value
    ] = Enum.map(row, &String.trim/1)

    GeoLocations.create_geo_location(%{
      ip_address: ip_address,
      country_code: country_code,
      country: country,
      city: city,
      latitude: latitude,
      longitude: longitude,
      mystery_value: mystery_value
    })
    |> case do
      {:ok, _} ->
        send(parent_pid, :accepted)

      {:error, changeset} ->
        error_message =
          "Row #{index} is invalid: " <> VioGeoLoc.ErrorHelpers.full_error_string(changeset)

        send(parent_pid, {:error, error_message})
    end
  end

  def sanitize_and_insert({_, index}, parent_pid) do
    send(parent_pid, {:error, "Invalid row with index #{index}"})
  end

  defp remote_stream(url) do
    Stream.resource(
      fn -> Req.get!(url, into: :self) end,
      fn resp ->
        # Req function for processing streaming data.
        Req.parse_message(
          resp,
          receive do
            message -> message
          end
        )
        |> case do
          # These are the data chunks.
          {:ok, [data: data]} ->
            {[data], resp}

          # This is returned when the stream is done.
          {:ok, [:done]} ->
            {:halt, resp}

          # This is received inside Finch from a process that is not the socket.
          # Ideally Req should be able to handle this and return a proper error or ignore it.
          :unknown ->
            resp
        end
      end,
      fn resp -> resp end
    )
  end
end
