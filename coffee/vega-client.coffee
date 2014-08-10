class (exports ? window).VegaClient
  @send: (websocket, message) ->
    message     = JSON.stringify(message)
    sendMessage = => websocket.send message

    if websocket.readyState is websocket.CONNECTING
      websocket.onopen = sendMessage
    else
      sendMessage()

  constructor: (@url, @roomId, @badge) ->
    throw new TypeError('url not provided') if @url is undefined
    throw new TypeError('roomId not provided') if @roomId is undefined
    throw new TypeError('badge not provided') if @badge is undefined

    @websocket = new WebSocket(@url)
    @callbacks = {}
    @websocket.onmessage = @onmessage

  onmessage: (message) =>
    parsedMessage = JSON.parse message
    data          = parsedMessage.data
    type          = data.type
    payload       = data.payload

    @trigger type, payload

  on: (type, callback) ->
    @callbacks[type] ||= []
    @callbacks[type].push callback

  trigger: (type, payload) ->
    return unless @callbacks[type]

    @callbacks[type].forEach (callback, idx, callbacks) =>
      callback.apply this, [payload]

  call: ->
    VegaClient.send @websocket,
      type: 'call'
      payload:
        roomId: @roomId
        badge: @badge

  offer: (offer, peerId) ->
    VegaClient.send @websocket,
      type: 'offer'
      payload:
        offer: offer
        peerId: peerId

  answer: (answer, peerId) ->
    VegaClient.send @websocket,
      type: 'answer'
      payload:
        answer: answer
        peerId: peerId

  candidate: (candidate, peerId) ->
    VegaClient.send @websocket,
      type: 'candidate'
      payload:
        candidate: candidate
        peerId: peerId

  hangUp: ->
    VegaClient.send @websocket,
      type: 'hangUp'
      payload: {}
