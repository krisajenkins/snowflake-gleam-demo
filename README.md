# snowflake-gleam-demo

A demonstration Gleam client for connecting to Snowflake's REST API.

## Configuration

Create a `config.json` file in the project root with your Snowflake credentials:

```json
{
  "account": "your-account",
  "warehouse": "your-warehouse",
  "database": "your-database",
  "schema": "your-schema",
  "token": "your-token-here"
}
```

See `config.json.example` for a template.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
