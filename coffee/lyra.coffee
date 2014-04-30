class Lyra
  constructor: (@url, @roomId, @badge, @localStream) ->
    @vc = new VegaClient(@url, @roomId, @badge)
    @pcConfig = { 'iceServers': [{'url': 'stun:stun.l.google.com:19302'}] }
    @callbacks = {}
    @peerConnections = {}

  init: ->
    @setupCallbacks()
    @vc.call()

  setupCallbacks: ->
    @vc.on 'callAccepted', (payload) =>
      _.each payload.peerIds, (peerId) =>
        pc = @addPeerConection(peerId)
        @initiateOffer(pc, peerId)

    @vc.on 'roomFull', (payload) =>
      @vc.close()
      console.error 'room is full'

    @vc.on 'offer', (payload) =>
      peerId            = payload.peerId
      badge             = payload.badge
      pc                = @addPeerConection(peerId)
      remoteDescription = new RTCSessionDescription(payload.offer)

      pc.setRemoteDescription(remoteDescription)
      @initiateAnswer(pc, peerId)

    @vc.on 'answer', (payload) =>
      pc                = @peerConnections[payload.peerId]
      remoteDescription = new RTCSessionDescription(payload.answer)

      pc.setRemoteDescription(remoteDescription)

    @vc.on 'candidate', (payload) =>
      pc        = @peerConnections[payload.peerId]
      candidate = new RTCIceCandidate(payload.candidate)

      pc.addIceCandidate(candidate)

    @vc.on 'peerHangUp', (payload) =>
      peerId = payload.peerId

      @trigger 'peerHangUp', peerId

      delete @peerConnections[peerId]

    @vc.on 'unexpectedPeerHangUp', (payload) =>
      peerId = payload.peerId

      @trigger 'unexpectedPeerHangUp', peerId

      delete @peerConnections[peerId]

  addPeerConection: (peerId) ->
    pc = @peerConnection(peerId)

    pc.addStream @localStream

    pc.onaddstream = (event) =>
      @trigger 'remoteStreamAdded', peerId, event.stream

    @peerConnections[peerId] = pc
    pc

  peerConnection: (peerId) ->
    pc = new webkitRTCPeerConnection(@pcConfig)

    pc.onicecandidate = (event) =>
      if candidate = event.candidate
        @vc.candidate candidate, peerId

    #pc.onaddstream = (event) =>
    pc

  initiateOffer: (pc, peerId) ->
    success = (desc) =>
      pc.setLocalDescription desc, =>
        @vc.offer(pc.localDescription, peerId)
      , @logError

    pc.createOffer success, @logError

  initiateAnswer: (pc, peerId) ->
    success = (desc) =>
      pc.setLocalDescription desc, =>
        @vc.answer(pc.localDescription, peerId)
      , @logError

    pc.createAnswer success, @logError

  trigger: (event) ->
    args = _.tail arguments

    if callbacks = @callbacks[event]
      _.each callbacks, (callback) =>
        callback.apply(this, args)

  on: (event, callback) ->
    @callbacks[event] ||= []
    @callbacks[event].push callback

  logError: (error) ->
    console.error error

window.Lyra = Lyra
