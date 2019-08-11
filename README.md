# SMA-Monitor
Monitoring the instantaneous values of an SMA Sunny Boy Inverter and publishing these to an mqtt topic. From there on they can be used by other applications, dashboards etc.

Each inverter has a web-interface that allows you to view the statistics of the solar installation. These values are grabbed and published via mqtt

## Details on the SMA inverter monitoring

Logging into the Inverter web-interface is done by a POST request including the role of the login and the password. You can do this as follows:
`curl -X POST -d '{"right": "usr", "pass": "YOURPASSWORD"}' "http://SMA-IP/dyn/login.json"`

As a result you'll receive a json file out of which the session value can be extracted using jq

`jq -r .result.sid`

Logging out is similar, and requires the session id in the URI:

`curl -X POST --data-binary {} http://SMA-IP/dyn/logout.json?sid=SESSION`

It's needed to explicitely to have the empty json as input or it wil fail.

If you whish to combine it all in one commandline request you could do it as follows (by putting the session-id in an environment variable:
```bash
SESSION=`curl -s -X POST -d '{"right": "usr", "pass": "YOURPASSWORD"}' "http://SMA-IP/dyn/login.json" | jq -r .result.sid` && curl.exe -s --data-binary {\"destDev\":[]} http://SMA-IP/dyn/getAllOnlValues.json?sid=$SESSION && curl -s -X POST --data-binary {} http://SMA-IP/dyn/logout.json?sid=$SESSION >>/dev/null
```

Running curl in silent mode `-s` and redirecting the output of the logout command to `/dev/null` as we don't use that response data (which is of the form `{"result":{"isLogin":false}}`
If you don't want the password to be visible in the commandline/shell (for example when someone does a ps and sees it in plaintext you can put them in a file and reference that file
`-d "@data.json`
where the file data.json contains the content `{"right": "usr", "pass": "YOURPASSWORD"}`

Obviously, replace YOURPASWORD with your password and SMA-IP with the IP or hostname of your inverter

Using this approach you'll login & out on every call.  Logging out is important as well as the inverter allows only a small number of simultaneous logins (approximately 3 or 4 it seems)

Getting a new session every time probably isn't needed either, but doing it minimizes the need to validate if the session is still alive.

## Docker image
The docker image that can be generated polls the interface of the SMA inverter and publishes the results to an mqtt topic.

Relevant environment variables to set:
```bash
INVERTER_PW=<YOURPASSWORD>
INVERTER_HOST=<HOSTNAME or IP of the inverter>
POLLING_INTERVAL=<amount of seconds between requests>
MQTT_HOST=<mqtt hostname or ip>
MQTT_TOPIC=<mqtt TOPIC to publish too>
LOCALE=en-US # other known supported locales are nl-NL, fr-FR, de-DE and probably more. Defaults to English
```
The json file reported by the SMA inverter is published flattened to the topic. Currently the json structure is made as flat as possible. The keys in the json file are translated using the suggested locale. These are gathered from the inverter on the first run.

An example file with all environment variables is included. This can be used with the --env-file parameter when running your docker container
