# VioGeoLoc

VioGeoLoc is an API for fetching the geolocation of a given IP address.

## API 

### Endpoint

`GET /api/geo_locations/<ip_address>`

### Response Format

The response is in JSON API format:

```json
{
  "data": {
    "type": "geo_locations",
    "id": "1",
    "attributes": {
      "ip_address": "1.1.1.1",
      "country": "Australia",
      "city": "Sydney",
      "latitude": -33.8612,
      "longitude": 151.1982
    }
  }
}
```

## Project Requirements

### Data Format

The schema in the GeoLocService module is based on the fields in the CSV file. Fields can be configured, and the GeoLocation schema can be passed in. The abstraction level of GeoLocService is flexible, and configurations can be provided as options.

### Data Validation

Data is validated using the GeoLocation schema's changeset function:
- `ip_address`: Must be a valid IP address.
- `latitude` and `longitude`: Must be within valid ranges.
- `country`: Must be a valid ISO 3166-1 (alpha 2) country code, and it overrides the CSV file value with our configured list of countries.
- `city`: Must be a string.
- `mystery_value`: Must be castable as a bigint.

### Import Report

During the CSV data import, progress is logged to `:info`. At the end of the import, a final update and error file path are logged.

#### Example Report

```
Elapsed time: <elapsed time since start of import> ms
Accepted: <number of rows accepted>
Rejected: <number of rows rejected> (<percentage of rows rejected>)
Total: <total number of rows imported>
Errors written to: <path to error file>
```

### GeoLocService Configuration

GeoLocService is configured in `config.exs`:

```elixir
config :geo_loc_service,
  repo: VioGeoLoc.Repo,
  error_file_path: "./errors.txt"
```

For deployment, override this value in `runtime.exs`:

```elixir
config :geo_loc_service,
  repo: VioGeoLoc.Repo,
  error_file_path: "./errors.txt",
  schema: GeoLocService.GeoLocation,
  fields: [:ip_address, :country, :city, :latitude, :longitude, :mystery_value]
```

### API Endpoint

Refer to the API documentation at the top.

## Project Design Decisions

### GeoLocService

#### Interaction with ImportServer

GeoLocService uses a GenServer to manage the import process. The GenServer starts with the required options, and on error, it returns an error message. The `handle_call/3` function manages the CSV import, using `:no_reply` to process incoming messages and replying with `GenServer.reply/2` on completion.

#### Importing

The import function converts the provided path to a stream (GET request for URLs or `File.stream` for files). It processes lines in parallel with `Task.async_stream`. Import tasks respond to ImportServer with `:accepted` or `{:error, changeset_or_binary, index}` messages. Errors are logged continuously, allowing for a detailed error report.

### API Format

The API uses the JSON API format for clarity and compatibility with other systems.

## Hosting and Repositories

- Running application: `https://vio-geo-loc.fly.dev`
- API endpoint: `https://vio-geo-loc.fly.dev/api/geo_locations/<ip_address>`
- GitHub repositories:
  - [GeoLocService](https://github.com/Ivor/geo_loc_service)
  - [VioGeoLoc](https://github.com/Ivor/vio_geo_loc)

## Development

A `docker-compose.yml` file is included to start a Postgres database. Configure `config/dev.exs` for database settings.

To set up the repo:

```bash
mix ecto.setup
```

To import a dump file:

```bash
mix run -e "VioGeoLoc.import(\"https://raw.githubusercontent.com/viodotcom/backend-assignment-elixir/master/cloud_data_dump.csv\")"
```

Or from IEX console:

```elixir
path = "https://raw.githubusercontent.com/viodotcom/backend-assignment-elixir/master/cloud_data_dump.csv"
VioGeoLoc.import(path)
```

`VioGeoLoc.import/2` is a shorthand for `GeoLocService.import/2`. Consider creating a mix task or a `script.exs` for command line execution or cron job scheduling. A file watcher could trigger imports based on file changes.

---