# vega-client

A drop-in WebRTC signaling client.
Use with [VegaServer](https://github.com/davejachimiak/vega_server).

## Development

vega-client is built in CoffeeScript. The relevant files are located at
`coffee/vega-client.coffee` and `test/coffee/vega-client-test.coffee`.

To install the development dependencies: `$ npm install`.

To build the library: `$ npm build`

To build the tests: `$ npm run built-test`

To run the tests: `$ npm test`

Running the tests builds the tests, the library, and the minified library.
