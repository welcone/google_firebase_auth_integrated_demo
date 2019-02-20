import 'package:flutter/material.dart';
import 'reactive_refresh_indicator.dart';
import 'google_sign_in_btn.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:baby_names/logger.dart';

class Auth extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _State4Auth();
  }
}

/// 提供社交登陆， 电话登陆， 短信登陆以及PROFILE_AUTH
enum AuthStatus { SOCIAL_AUTH, PHONE_AUTH, SMS_AUTH, PROFILE_AUTH }

class _State4Auth extends State<Auth> {
  var _authStatus = AuthStatus.SOCIAL_AUTH;
  var _isRefreshing = false;
  final TAG = 'Auth';
  GoogleSignInAccount _googleUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: ReactiveRefreshIndicator(
        child: _showBody,
        onRefresh: _onRefresh,
        isRefreshing: _isRefreshing,
      ),
    );
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<Null> _onRefresh() async {
    switch (this._authStatus) {
      case AuthStatus.SOCIAL_AUTH:
        {
          // todo-wk 1>  done 在这里加载社交验证
          return await _googleSignIn();
        }
      case AuthStatus.PHONE_AUTH:
        {
          break;
        }
      case AuthStatus.SMS_AUTH:
        {
          break;
        }
      case AuthStatus.PROFILE_AUTH:
        {
          break;
        }
      default:
        {
          return null;
        }
    }
  }

  var _googleSignInClient = GoogleSignIn();

  Future<Null> _googleSignIn() async {
    var currentUser = _googleSignInClient.currentUser;
    // 初次或者重新登陆
    if (currentUser == null) {
      await _googleSignInClient.signIn().then(
        (account) {
          currentUser = account;
        },
        onError: (errorMessage) {
          Logger.log(TAG,
              message: 'error occur in _googleSignIn:$errorMessage');
          _showErrorSnackBar('error occur in _googleSignIn:$errorMessage');
        },
      );
    }
    // 当前状态稳定，更新状态
    if (currentUser != null) {
      this._googleUser = currentUser;
      Logger.log(TAG, message: '$this._googleUser');
      _updateIsRefreshing(false);
      setState(() {
        this._authStatus = AuthStatus.PHONE_AUTH;
        Logger.log(TAG, message: 'Satus switch to $_authStatus');
      });
    }
  }

  /// 刷新更新状态，如果本身是true 那么进行重置
  /// 如果是在非刷新状态，更新状态
  Future<Null> _updateIsRefreshing(bool isRefreshing) async {
    Logger.log(TAG,
        message: "Setting _isRefreshing ($_isRefreshing) to $isRefreshing");
    if (this._isRefreshing) {
      setState(() {
        this._isRefreshing = false;
      });
    }
    setState(() {
      this._isRefreshing = isRefreshing;
    });
  }

  void _showErrorSnackBar(String errorMessage) {
    this._updateIsRefreshing(false);
    this
        ._scaffoldKey
        .currentState
        .showSnackBar(SnackBar(content: Text(errorMessage)));
  }

  get _showBody {
    switch (this._authStatus) {
      case AuthStatus.SOCIAL_AUTH:
        {
          return _showSocialAuth;
        }
      case AuthStatus.PHONE_AUTH:
        {
          return _showPhoneAuth;
        }
      case AuthStatus.SMS_AUTH:
      case AuthStatus.PROFILE_AUTH:
        {
          return _showSmsAuth;
        }
      default:
        {
          break;
        }
    }
  }

  get _showSocialAuth {
    return Center(
      child: GoogleSignInButton(
        onPressed: () => this._updateIsRefreshing(true),
      ),
    );
  }

  get _showPhoneAuth => Text('PhoneAuth');

  get _showSmsAuth => Text('SMS ');
}
