# REST API
This app has a REST API that can allow easy access of functions through automation.

The REST API is documented internally using openapi. You can access swagger docs by going to "/api/docs".

## Docs Routes
- `/api/docs`
- `/api/redocs`
- `/api/openapi.json`

## API Routes
### GET /api/is-healthy
Get the status of the server


#### Response, 200
```
🆗
```


### POST /api/pastes
Create a new paste.

#### Request
```json
{
  "content": "string",
  "expire_dt": "2022-07-28T11:21:19.839Z",
  "long_id": false
}
```

#### Response, 201
```json
{
  "creation_dt": "2022-07-28T11:22:20.080Z",
  "expire_dt": "2022-07-28T11:22:20.080Z",
  "paste_id": "string"
}
```


### POST /api/pastes/simple
Create a new paste without any settings, suitable for easier use with curl from the command line.

#### Request
```
Hello World!
```

#### Response, 201
```
1a00222g
```


### GET /api/pastes/
Returns a stream of paste id's, requires `ENABLE_PUBLIC_LIST` config to be True.

#### Response, 200
```
1a00222g
1a00dfda
...
```
#### Response, 403
The public list has been disabled.


### GET /api/pastes/{paste id}
Get the pastes raw content.

#### Response, 200
The pastes raw content.
#### Response, 404
Paste with given id not found, or expired


### GET /api/pastes{paste id}/meta
Returns the paste's meta as JSON.

#### Response, 200
The paste's meta for given id.

```json
{
  "creation_dt": "2022-07-28T11:22:20.080Z",
  "expire_dt": "2022-07-28T11:22:20.080Z",
  "paste_id": "string"
}
```
#### Response, 404
Paste with given id not found, or expired
