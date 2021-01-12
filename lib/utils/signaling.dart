import 'package:flutter_webrtc/webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

// https://backend-simple-webrtc.herokuapp.com/

typedef OnLocalStream(MediaStream stream);
typedef OnRemoteStream(MediaStream stream);
typedef OnJoined(bool isOk);

class Signaling{

  String _url = 'https://web-rtc-rs.herokuapp.com/';
  IO.Socket _socket;
  OnLocalStream onLocalStream;
  OnRemoteStream onRemoteStream;
  OnJoined onJoined;
  RTCPeerConnection _peer;
  MediaStream _localStream;
  String _him;

  init() async{
    MediaStream stream = await navigator.getUserMedia({
      'audio': true,
      'video': {
        'mandatory':{
          'minWidth':'480',
          'minHeight':'640',
          'minFrameRate': '30'
        },
        'facingMode':'user',
        'optional':[]
      }
    });

    _localStream = stream;
    onLocalStream(stream);
    this._connect();
  }

  _createPeer() async{
    this._peer = await createPeerConnection({
      'iceServers':[
        {
          'urls':['stun:stun1.l.google.com:19302']
        }
      ]
    }, {

    });

    await this._peer.addStream(this._localStream);
    this._peer.onIceCandidate = (RTCIceCandidate candidate){
      if(candidate == null){
        return;
      }

      print('enviando el iceCandidate');

    //  enviar el iceCandidate
      emit('candidate', {
        'username': this._him,
        'candidate': candidate.toMap()
      });
    };

    this._peer.onAddStream = (MediaStream remoteStream){
      this.onRemoteStream(remoteStream);
    };

  }

  _connect(){
    this._socket = IO.io(
      this._url, <String, dynamic>{
        'transports':['websocket'],
        // 'extraHeaders':{'foo': 'bar'}
      }
    );

    this._socket.on('on-join', (isOk){
      print('socket status connected $isOk');
      onJoined(isOk);
    });

    this._socket.on('on-call', (data) async{
      print('on-call socket status connected $data');
      await this._createPeer();
      final String username = data['username'];
      this._him = username;
      final offer = data['offer'];
      final RTCSessionDescription desc = RTCSessionDescription(offer, offer['type']);
      await this._peer.setRemoteDescription(desc);
      final sdpConstraints = {
        'mandatory':{
          'OfferToReceiveAudio':true,
          'OfferToReceiveVideo':true
        },
        'optional':[]
      };
      final RTCSessionDescription answer = await this._peer.createAnswer(sdpConstraints);
      await this._peer.setLocalDescription(answer);

      emit('answer', {
        'username': this._him,
        'answer': answer.toMap()
      });
    });

    this._socket.on('on-answer', (answer){
      print('on-answer $answer');
      final RTCSessionDescription desc = RTCSessionDescription(answer['sdp'], answer['type']);
      this._peer.setRemoteDescription(desc);
    });

    this._socket.on('on-candidate', (data) async{
      print('on-candidate $data');

      final RTCIceCandidate candidate = RTCIceCandidate(data['candidate'], data['sdpMide'], data['sdpMlineIndex']);
      
      await this._peer.addCandidate(candidate);
    });

  }

  emit(String eventName, dynamic data){
    _socket?.emit(eventName, data);
  }

  call(String username) async{

    this._him = username;
    await this._createPeer();
    final sdpConstraints = {
      'mandatory':{
        'OfferToReceiveAudio':true,
        'OfferToReceiveVideo':true
      },
      'optional':[]
    };

    final RTCSessionDescription offer = await this._peer.createOffer(sdpConstraints);
    this._peer.setLocalDescription(offer);

    emit('call', {
      'username': username,
      'offer': offer.toMap()
    });
  }

  dispose(){
    this._socket?.disconnect();
  }


}