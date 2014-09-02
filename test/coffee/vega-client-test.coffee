describe 'VegaClient', ->
  beforeEach ->
    @url    = 'ws:0.0.0.0:9292'
    @roomId = '/chat/abc123'
    @badge  = { name: 'Dave' }
    @client = new VegaClient(@url, @roomId, @badge)

  afterEach ->
    sinon.collection.restore()

  describe '.send', ->
    beforeEach ->
      @message =
        type: 'hangUp'
        payload: {}

      @stringifiedMessage = JSON.stringify @message

    describe 'when WebSocket is connecting', ->
      beforeEach ->
        @websocket =
          readyState: 0
          CONNECTING: 0
          send: ->
        @send = sinon.collection.stub @websocket, 'send'

      it 'sends the message when the websocket becomes open', ->
        VegaClient.send(@websocket, @message)
        expect(@send).to.not.have.been.called

        @websocket.onopen()
        expect(@send).to.have.been.calledWith @stringifiedMessage

    describe 'when WebSocket is not connecting', ->
      beforeEach ->
        @websocket =
          readyState: 1
          CONNECTING: 0
          send: ->
        @send = sinon.collection.stub @websocket, 'send'

      it 'sends the message immediately', ->
        VegaClient.send(@websocket, @message)
        expect(@send).to.have.been.calledWith @stringifiedMessage

  describe '#constructor', ->
    describe 'arguments are satisfied', ->
      beforeEach ->
        @websocket = @client.websocket

      it 'sets the onmessage callback', ->
        expect(@websocket.onmessage).to.equal @client.onmessage

      it 'sets the onerror callback', ->
        expect(@websocket.onerror).to.equal @client.onerror

    describe 'zero arguments are passed', ->
      it 'throws an error', ->
        expect(=> new VegaClient()).to.throw TypeError

    describe 'one argument is passed', ->
      it 'throws an error', ->
        expect(=> new VegaClient(@url)).to.throw TypeError

    describe 'two arguments are passed', ->
      it 'throws an error', ->
        expect(=> new VegaClient(@url, @roomId)).to.throw TypeError

  describe '#onmessage', ->
    it 'triggers callbacks set on the type and the payload', ->
      payload =
        offer: {}
        peerId: 'f4321169-131c-4ae9-93f5-177fafe02e59'
        peerBadge:
          name: 'Allie'

      data = JSON.stringify
        type: 'offer'
        payload: payload
      message = { data: data }

      offer1 = []
      offer2 = []

      @client.on 'offer', (pload) =>
        offer1.push pload

      @client.on 'offer', (pload) =>
        offer2.push pload

      @client.onmessage(message)

      expect(offer1).to.include payload
      expect(offer2).to.include payload

  describe '#onerror', ->
    it 'triggers an error event with the error', ->
      trigger = sinon.collection.stub @client, 'trigger'

      @client.onerror(error = new Object)

      expect(trigger).to.have.been.calledWith 'websocketError', error

  describe 'messages to server', ->
    beforeEach ->
      @stubSendWith = (message) =>
        @send = sinon.collection.stub(VegaClient, 'send').
          withArgs(@client.websocket, message)

      @assertMessageSent = =>
        expect(@send).to.have.been.called

    describe '#call', ->
      it 'sends a call message', ->
        @stubSendWith
          type: 'call'
          payload:
            roomId: @roomId
            badge: @badge

        @client.call()

        @assertMessageSent()

    describe '#offer', ->
      it 'sends an offer message', ->
        offer = {}
        peerId = 'f4321169-131c-4ae9-93f5-177fafe02e59'

        @stubSendWith
          type: 'offer'
          payload:
            offer: offer
            peerId: peerId

        @client.offer(offer, peerId)

        @assertMessageSent()

    describe '#answer', ->
      it 'sends an answer message', ->
        answer = {}
        peerId = 'f4321169-131c-4ae9-93f5-177fafe02e59'

        @stubSendWith
          type: 'answer'
          payload:
            answer: answer
            peerId: peerId

        @client.answer(answer, peerId)

        @assertMessageSent()

    describe '#candidate', ->
      it 'sends a candidate message', ->
        candidate = {}
        peerId = 'f4321169-131c-4ae9-93f5-177fafe02e59'

        @stubSendWith
          type: 'candidate'
          payload:
            candidate: candidate
            peerId: peerId

        @client.candidate(candidate, peerId)

        @assertMessageSent()

    describe '#hangUp', ->
      it 'sends a hangUp message', ->
        @stubSendWith
          type: 'hangUp'
          payload: {}

        @client.hangUp()

        @assertMessageSent()
