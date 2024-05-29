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

The schema used in the GeoLocService module is based on the fields contained within the CSV file.
We could configure the fields to be used as well as the GeoLocation schema and pass that in. 
It was not clear to me how abstract we wanted to GeoLocService to be. 
If we want to do that we would configure these values as further options that get passed into the service. 

### Data validation

The data is parsed through the GeoLocation schema's changeset function which performs a number of checks. 
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

The GeoLocService is configured in `config.exs` like this: 

```elixir
config :geo_loc_service,
  repo: VioGeoLoc.Repo,
  error_file_path: "./errors.txt"
```

We can change the path to the file that we want to write to when we deploy by overriding this value in the `runtime.exs`.
As discussed earlier, we could also configure the schema to use and also the which fields to map and even the order in which they are found in the CSV file 
in a similar way and then we would pass these options in as well. 

```elixir
config :geo_loc_service,
  repo: VioGeoLoc.Repo,
  error_file_path: "./errors.txt",
  schema: GeoLocService.GeoLocation,
  fields: [:ip_address, :country, :city, :latitude, :longitude, :mystery_value]
```

In that case we would also need to change the `GeoLocService.import/1` function to use these options.
I opted not to do it because it seemed awkward to put the fetch_geo_location functionality in the library but give it the schema to use.
If the main application is in charge of the schema it seems simpler to fetch the records in the repo itself. 
I did not see a clear advantage to doing it the other way.

### API Endpoint

Refer to the API documentation at the top.

## Project Design Decisions:

### GeoLocService

#### Interaction with the ImportServer

The GeoLocService makes use of a GenServer to collate the results of the import process. 
It is started with all the options that are required for the import process.
If there is a problem with the options the GenServer will not start and will return an error message.

I implemented a handle_call/3 callback to handle the import of the CSV file.
To allow the GenServer to process the incoming messages from the tasks that are spawned to import the data I reply with a :no_reply 
from the initial handle_call function, while keeping the caller_pid in the state. 

When the GenServer receives the final :done message it will send the reply to the caller id with GenServer.reply/2 and then stop.

#### Importing

The path that is provided to the import function is converted to a stream. 
If the path is a url we do a GET request and stream the values from github. 
If the path is a file path we use `File.stream!`. 

We read the stream in lines and then use Task.async_stream to process the lines in parallel.
Each task to import a row into the database responds to the ImportServer with either an `:accepted` or `{:error, changeset_or_binary, index}` message.
When the stream has completed running we send a :done message to the ImportServer.

This allows for decoupling of the GenServer and the import process which means we can provide feedback to the user about the progress of the import.
Errors are continuously logged to the error file as they occur. This provides a report of errors with the row index where they occurred, which will allow us to fix the errors in the CSV file. I prefered this approach because it allows for an arbitrary number of errors to be logged. If I maintained the errors the GenServer staet would grow indefinitely.

### API Format

For the API I opted for the JSON API format. It is more verbose than might be necessary but it is well understood and supported and will be easy to communicate to someone who needs to integrate with our geo_location API. 

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

`VioGeoLoc.import/2` is a shorthand for `GeoLocService.import/2`. 

We could create a mix task to do this import or a `script.exs` which can be called from the command line by a cron job. 
A watcher that monitors a specific file location for the import file could be used as a trigger so that if that file changes we import the new data. Alternatively we can simple provide an API endpoint to trigger the import and pass the path to the file as a parameter.
This endpoint would need authentication to prevent unauthorized access.


