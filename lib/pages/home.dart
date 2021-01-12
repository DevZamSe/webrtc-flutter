import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:redsalud_video/utils/signaling.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  Signaling _signaling = Signaling();
  String _me, _username = '';

  @override
  void initState() {
    super.initState();

    this._localRenderer.initialize();
    this._remoteRenderer.initialize();
    this._signaling.init();
    this._signaling.onLocalStream = (MediaStream stream){
      this._localRenderer.srcObject = stream;
      this._localRenderer.mirror = true;
    };

    _signaling.onRemoteStream = (MediaStream stream){
      this._remoteRenderer.srcObject = stream;
      this._remoteRenderer.mirror = true;
    };
    _signaling.onJoined = (bool isOk){
      if(isOk){
        setState(() {
          this._me = this._username;
        });
      }
    };
  }

  @override
  void dispose() {
    this._signaling.dispose();
    this._localRenderer.dispose();
    this._remoteRenderer.dispose();
    super.dispose();
  }

  _inputCall(){
    var username = '';
    showCupertinoDialog(
      context: context,
      builder: (context){
        return CupertinoAlertDialog(
          content: CupertinoTextField(
            placeholder: 'Llamar a',
            onChanged: (text)=> username = text,
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: (){
                _signaling.call(username);
                Navigator.pop(context);
              },
              child: Text('Llamar')
            )
          ]
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        child: this._me == null ? Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CupertinoTextField(
                placeholder: 'tu usuario',
                textAlign: TextAlign.center,
                onChanged: (text){
                  setState(() {
                    this._username = text;
                  });
                },
              ),
              SizedBox(height: 20.0),
              CupertinoButton(
                child: Text('Iniciar reunión'),
                onPressed: (){
                  if(this._username.trim().length == 0){
                    return;
                  }
                  _signaling.emit('join', this._username);
                },
              )
            ],
          ),
        ) : Stack(
          children: [
            Positioned.fill(
              child: RTCVideoView(this._remoteRenderer),
            ),
            Positioned(
              left: 20.0,
              bottom: 40.0,
              child: Transform.scale(
                alignment: Alignment.bottomLeft,
                scale: 0.3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: Container(
                    width: 480.0,
                    height: 640.0,
                    color: Colors.black12,
                    child: RTCVideoView(this._localRenderer),
                  )
                )
              )
            ),
            Positioned(
              right: 20.0,
              bottom: 40.0,
              child: CupertinoButton(
                child: Text('Llamar'),
                onPressed: this._inputCall,
                color: Colors.blue,
              ),
            )
          ]
        )
      )
    );
  }
}
