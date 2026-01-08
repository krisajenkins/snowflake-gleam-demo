import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/io
import gleam/json
import gleam/list
import gleam/string
import simplifile

// Config
type SnowflakeConfig {
  SnowflakeConfig(
    account: String,
    warehouse: String,
    database: String,
    schema: String,
    token: String,
  )
}

fn config_decoder() -> decode.Decoder(SnowflakeConfig) {
  use account <- decode.field("account", decode.string)
  use warehouse <- decode.field("warehouse", decode.string)
  use database <- decode.field("database", decode.string)
  use schema <- decode.field("schema", decode.string)
  use token <- decode.field("token", decode.string)
  decode.success(SnowflakeConfig(account, warehouse, database, schema, token))
}

// Request/Repsonse workflow.
pub fn main() {
  let assert Ok(cfg_file) = simplifile.read("config.json")
  let assert Ok(cfg) = json.parse(cfg_file, config_decoder())
  io.println("Loaded config for: " <> cfg.account)

  let body =
    json.object([
      #("database", json.string(cfg.database)),
      #("schema", json.string(cfg.schema)),
      #("warehouse", json.string(cfg.warehouse)),
      #("timeout", json.int(60)),
      #("statement", json.string("SELECT CURRENT_DATE()::STRING")),
    ])

  // Build HTTP request
  let assert Ok(req) =
    request.to(
      "https://" <> cfg.account <> ".snowflakecomputing.com/api/v2/statements",
    )

  let req =
    req
    |> request.set_method(http.Post)
    |> request.set_header("content-type", "application/json")
    |> request.set_header("accept", "application/json")
    |> request.set_header("user-agent", "gleam-snowflake/0.1.0")
    |> request.set_header("authorization", "Bearer " <> cfg.token)
    |> request.set_body(json.to_string(body))

  // Send request and print response
  io.println("Sending request...")
  let assert Ok(resp) = httpc.send(req)
  io.println("Status: " <> string.inspect(resp.status))
  io.println("Full response:\n" <> resp.body)

  // Parse and print data rows
  let assert Ok(rows) =
    json.parse(
      resp.body,
      decode.at(["data"], decode.list(decode.list(decode.dynamic))),
    )
  list.each(rows, fn(row) { io.println("\nRow: " <> string.inspect(row)) })
}
