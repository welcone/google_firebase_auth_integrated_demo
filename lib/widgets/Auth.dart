import 'package:flutter/material.dart';

class Auth extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return _State4Auth();
  }

}

/// 提供社交登陆， 电话登陆， 短信登陆以及PROFILE_AUTH
enum AuthStatus{SOCIAL_AUTH, PHONE_AUTH, SMS_AUTH, PROFILE_AUTH }
class _State4Auth extends State<Auth> {

  var authStatus = AuthStatus.PHONE_AUTH;


  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Text('Google FireBase'),
      ),
      body: RefreshIndicator(child: _showBody, onRefresh: _onRefresh),
    );
  }

  get _showBody => null;

  get _onRefresh {
   switch(this.authStatus){
     case AuthStatus.SOCIAL_AUTH:{
       // todo-wk 1>  在这里加载社交验证
       break;
     }
     case AuthStatus.PHONE_AUTH:{
       break;
     }
     case AuthStatus.SMS_AUTH:{
       break;
     }
     case AuthStatus.PROFILE_AUTH:{
       break;
     }
     default:{
       break;
     }
   }
  }


}