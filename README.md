# apisix-secret-casdoor

[Casdoor](https://casdoor.org/docs/basic/public-api
) Secret Manager Plugin for [Apache Apisix](https://apisix.apache.org/)

**⚠️ WARNING: Casdoor does not encrypt the storage of secret.**

## Schema

| Name   | Type   | Requirement | Description                                    |
| ------ | ------ | ----------- | ---------------------------------------------- |
| uri    | string | required    | URI of the Casdoor Public API.                 |
| prefix | string | required    | `user` Use Casdoor User API as Secret Storage. |
| token  | string | required    | The Casdoor Public API Authorization Header.   |

## Usage

Step 1: Create the apisix application with `Client ID` and `Client secret` in Casdoor.

Step 2: Create the user with custom `properties` in Casdoor.

The user schema should like be:

```json
{
  "owner": "testorg",
  "name": "jack",
  "id": "e9e80827-1c50-49c4-87ca-023c0e3f08a6",
  "properties": {
    "auth-key": "foobar"
  },
}
```

Step 3: Add APISIX Secrets resources through the Admin API, configure the Casdoor address and other connection information:

```sh
curl http://127.0.0.1:9180/apisix/admin/secrets/casdoor/1 \
-H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1' -X PUT -d '
{
    "uri": "https://127.0.0.1:8200"，
    "prefix": "user",
    "token": "Basic Mjk0YjA5ZmJjMTdmOTVkYWYyZmU6ZGQ4OTgyZjcwNDZjY2JhMWJiZDc4NTFkNWMxZWNlNGU1MmJmMDM5ZA==",
}'
```

Step 4: Reference the APISIX Secrets resource in the key-auth plugin and fill in the key information:

```sh
curl http://127.0.0.1:9180/apisix/admin/consumers \
-H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1' -X PUT -d '
{
    "username": "jack",
    "plugins": {
        "key-auth": {
            "key": "$secret://casdoor/1/e9e80827-1c50-49c4-87ca-023c0e3f08a6/properties/auth-key"
        }
    }
}'
```

NOTE: `e9e80827-1c50-49c4-87ca-023c0e3f08a6` is the userId in Casdoor.

NOTE: You can use other exists fields of the Casdoor User. like `owner` | `name` | `password` etc. Insteadof the `properties/auth-key`. **But please remember, Casdoor does not encrypt the field.**

Through the above steps, when the user request hits the key-auth plugin, the real value of the key in the Casdoor will be obtained through the APISIX Secret component.

## Install

```sh
git clone https://github.com/Lensual/apisix-secret-casdoor
cp apisix-plugin-aws-auth/apisix/secret/casdoor.lua /path/to/apisix/secret
```

## License

[Apache 2.0 License](./LICENSE)
