import 'dart:async';

import 'package:flutter/material.dart';
import 'reactive_refresh_indicator.dart';
import 'google_sign_in_btn.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:baby_names/logger.dart';
import 'masked_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_screen.dart';

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

  GlobalKey<MaskedTextFieldState> _maskedPhoneKey =
      GlobalKey<MaskedTextFieldState>();

  var _phoneNumberController = TextEditingController();

  String _errorMessage;

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
          return await _firePhoneAuth();
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

  /***GoogleSignIn****/
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
      Logger.log(TAG,
          message: '**************Name:${this._googleUser.displayName}'
              '${this._googleUser.email}'
              '${this._googleUser.photoUrl}');
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

  /****firebase auth***/
  Future<Null> _firePhoneAuth() async {
    // 验证输入的有效性
    var validateResult = _isPhoneInputValidated();
    // 提交错误
    if (validateResult != null) {
      this._updateIsRefreshing(false);
      setState(() {
        this._errorMessage = validateResult;
      });
    } else {
      this._updateIsRefreshing(false);
      setState(() {
        this._errorMessage = null;
      });
      // 提交验证
      var result = await _verifyPhoneNumber();
      return result;
    }
  }

  var _fireBaseClient = FirebaseAuth.instance;
  var _verifyPhoneNumTimeOut = Duration(minutes: 1);

  Future<Null> _verifyPhoneNumber() async {
    var result = _isPhoneInputValidated();
    if (result == null) {
      await this._fireBaseClient.verifyPhoneNumber(
          phoneNumber: this._phoneNumber,
          timeout: _verifyPhoneNumTimeOut,
          verificationCompleted: _onVerificationCompleted,
          verificationFailed: _onVerificationFailed,
          codeSent: _verifyCodeSent,
          codeAutoRetrievalTimeout: _onCodeAutoRetriveTimeout);
    } else {}
    // get the unmasked phonenumber
    // summit and verified phone
  }

  bool _codeSendTimeOut = false;
  String _verificationID;

  _verifyCodeSent(String verificationID, [int forceResendingToken]) {
    // log
    Logger.log(TAG,
        message:
            'VerificationCode is sendint to ${this._phoneNumberController.text}');
    // start a timer
    Timer(this._verifyPhoneNumTimeOut, () {
      setState(() {
        this._codeSendTimeOut = true;
      });
    });
    // 设置更新状态
    this._updateIsRefreshing(false);
    // 切换到短信验证
    setState(() {
      this._verificationID = verificationID;
      this._authStatus = AuthStatus.SMS_AUTH;
      Logger.log(TAG, message: 'Auth status changed to $_authStatus');
    });
  }

  void _onCodeAutoRetriveTimeout(String verificationId) {
    Logger.log(TAG, message: '_onCodeAutoRetriveTimeout');
    this._updateIsRefreshing(false);
    setState(() {
      this._verificationID = verificationId;
      this._codeSendTimeOut = true;
    });
  }

  _onVerificationCompleted(FirebaseUser firebaseUser) async {
    Logger.log(TAG, message: "_onVerificationCompleted, user:${firebaseUser}");
    if (await _onCodeVerified(firebaseUser)) {
      await _finishSignIn(firebaseUser);
    }else{
      setState(() {
        _authStatus = AuthStatus.PROFILE_AUTH;
        Logger.log(TAG, message: 'changed status to $_authStatus');
      });
    }
  }

  Future<bool> _onCodeVerified(FirebaseUser firebaseUser) async {
    final isValid = firebaseUser != null &&
        firebaseUser.phoneNumber != null &&
        firebaseUser.phoneNumber.isNotEmpty;
    if (isValid) {
      setState(() {
//        _updateIsRefreshing(true);
        _authStatus = AuthStatus.PROFILE_AUTH;
        Logger.log(TAG, message: 'Changed status to $_authStatus');
      });
    } else {
      _showErrorSnackBar('无法验证您的输入');
    }
    return isValid;
  }

  _finishSignIn(FirebaseUser firebaseUser) async {
    await _onCodeVerified(firebaseUser).then((result) {
      if (result) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => MainScreen(
                googleUser: _googleUser, firebaseUser: firebaseUser)));
      }else{
        setState(() {
          _authStatus =  AuthStatus.PROFILE_AUTH;
        });
        _showErrorSnackBar('无法创建，，，');
      }
    });
  }

  void _onVerificationFailed(AuthException error) {
    Logger.log(TAG, message: '_onVerificationFailed:${error}');
    _showErrorSnackBar('我们无法验证您的输入，请重新尝试');
  }

  /// 获得用户输入的电话号码
  get _phoneNumber {
    var unmaskedText = _maskedPhoneKey.currentState.unmaskedText;
    return '+86$unmaskedText'.trim();
  }

  String _isPhoneInputValidated() {
    if (_phoneNumberController.text.isEmpty) {
      return '输入的电话号码为空';
    } else if (this._phoneNumberController.text.length < 13) {
      return '输入的电话号码位数不正确，请重新输入';
    }
    return null;
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

  get _showPhoneAuth {
    return Center(
      child: Column(
        children: <Widget>[
          Text('请输入电话号码，收到验证码后，填入并通过验证登陆'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8,horizontal: 24),
            child: Flex(
              direction: Axis.horizontal,
              children: <Widget>[
                Flexible(
                  child: _showPhoneNumberInput,
                  flex: 5,
                ),
                Flexible(
                  child: _showConfirm,
                  flex: 1,
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  get _showPhoneNumberInput {
    return MaskedTextField(
      key: _maskedPhoneKey,
      mask: 'xxx-xxxx-xxxx',
      keyboardType: TextInputType.number,
      maxLength: 13,
      maskedTextFieldController: _phoneNumberController,
      onSubmitted: (reuslt) => _updateIsRefreshing(true),
    );
  }

  get _showConfirm {
    return IconButton(
      icon: Icon(Icons.check),
      onPressed: this._authStatus == AuthStatus.PROFILE_AUTH
          ? null
          : () => this._updateIsRefreshing(true),
    );
  }

  get _showSmsAuth => Text('SMS ');
}
