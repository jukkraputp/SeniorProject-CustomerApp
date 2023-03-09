import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:customer/interfaces/register.dart';
import 'package:customer/main.dart';
import 'package:customer/util/const.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:customer/apis/api.dart';
import 'package:customer/interfaces/network.dart';
import 'package:customer/screens/login.dart';
import 'package:customer/screens/main_screen.dart';
import 'package:customer/screens/register.dart';
import 'package:flutter/services.dart';
import 'package:customer/interfaces/customer/user.dart' as AppUser;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class JoinApp extends StatefulWidget {
  const JoinApp({super.key, this.bgMessageData});

  final Map<String, dynamic>? bgMessageData;

  @override
  _JoinAppState createState() => _JoinAppState();
}

class _JoinAppState extends State<JoinApp> with SingleTickerProviderStateMixin {
  final API api = API();

  late TabController _tabController;
  User? _user;
  bool _auth = false;
  bool _loggedIn = false;

  /* Map _source = {ConnectivityResult.none: false};
  final NetworkConnectivity _networkConnectivity = NetworkConnectivity.instance;
  String string = ''; */

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, initialIndex: 0, length: 2);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);

    /* _networkConnectivity.initialise();
    _networkConnectivity.myStream.listen((source) {
      _source = source;
      print('source $_source');
      // 1.
      switch (_source.keys.toList()[0]) {
        case ConnectivityResult.mobile:
          string =
              _source.values.toList()[0] ? 'Mobile: Online' : 'Mobile: Offline';
          break;
        case ConnectivityResult.wifi:
          string =
              _source.values.toList()[0] ? 'WiFi: Online' : 'WiFi: Offline';
          break;
        case ConnectivityResult.none:
        default:
          string = 'Offline';
      }
      // 2.
      setState(() {});
      // 3.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            string,
            style: TextStyle(fontSize: 30),
          ),
        ),
      );
    }); */
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        print('User is currently signed out!');
        setState(() {
          _user = null;
        });

        if (_auth) {
          Navigator.of(context).popUntil((route) {
            if (route.settings.name == 'JoinApp') {
              setState(() {
                _loggedIn = false;
              });
              return true;
            }
            return false;
          });
        }
        setState(() {
          _auth = false;
        });
      } else {
        print('User is sign in! :: ${user}');
        setState(() {
          _user = user;
          _auth = true;
        });
      }
    });
  }

  Future<dynamic> anonymousLogin() async {
    try {
      final UserCredential credential =
          await FirebaseAuth.instance.signInAnonymously();
      return credential;
    } catch (e) {
      print('anonymous');
      print(e);
    }
  }

  Future<dynamic> login(
      {String username = '', String password = '', String? uid}) async {
    if (uid == null) {
      try {
        print('logging in as $username');
        final UserCredential credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
                email: '$username@gmail.com', password: password);
        print('logged in');
        if (credential.user != null) {
          uid = credential.user!.uid;
        } else {
          print('sign in error');
          return false;
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          print('No user found for that email.');
          return 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          print('Wrong password provided for that user.');
          return 'Wrong password provided for that user.';
        }
      } catch (e) {
        print('login');
        print(e);
      }
    }

    if (uid != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (BuildContext context) {
                      return MainScreen(
                        user: _user!,
                        bgMessageData: widget.bgMessageData,
                      );
                    },
                    settings: const RouteSettings(name: 'MainScreen')),
              ));
    }
  }

  Future<RegisterResult> register(
      {String? username,
      String? email,
      String? password,
      String? phoneNumber}) async {
    if (username == null ||
        email == null ||
        password == null ||
        phoneNumber == null) return RegisterResult();
    print('registering');
    try {
      var res = await api.register(
          username: username,
          email: email,
          password: password,
          phoneNumber: phoneNumber);
      Map<String, dynamic> resBody = json.decode(res.body);
      if (!resBody['status']) {
        bool _stop = false;
        showDialog(
            context: context,
            builder: ((context) {
              return AlertDialog(
                title: const Text('Registration Error'),
                content: Text(resBody['message']),
                actions: <Widget>[
                  TextButton(
                      onPressed: () => Navigator.of(context).popUntil((route) {
                            if (route.settings.name == 'Loader') {
                              _stop = true;
                              return false;
                            }
                            return _stop;
                          }),
                      child: const Text('Close'))
                ],
              );
            }));
      }
      print(resBody);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      }
      return RegisterResult(success: false, message: e.code);
    } catch (e) {
      print(e);
      return RegisterResult(success: false, message: e.toString());
    }
    User? user = await login(username: username, password: password);
    return RegisterResult(success: true);
  }

  /// Used to trigger an event when the widget has been built
  Future<bool> initializeController() {
    Completer<bool> completer = new Completer<bool>();

    /// Callback called after widget has been fully built
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      completer.complete(true);
    });

    return completer.future;
  }

  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    print(googleUser);

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;
    print(googleAuth);

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithFacebook() async {
    // Trigger the sign-in flow
    final LoginResult loginResult = await FacebookAuth.instance.login();

    // Create a credential from the access token
    late String token;
    if (loginResult.accessToken != null) {
      token = loginResult.accessToken!.token;
    } else {
      token = '';
    }
    final OAuthCredential facebookAuthCredential =
        FacebookAuthProvider.credential(token);

    // Once signed in, return the UserCredential
    return FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);
  }

  @override
  Widget build(BuildContext context) {
    if (_auth & (FirebaseAuth.instance.currentUser != null) & !_loggedIn) {
      login(uid: FirebaseAuth.instance.currentUser!.uid);
      setState(() {
        _loggedIn = true;
      });
    }
    return WillPopScope(
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Center(
                child: Text(
              Constants.appName,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).textSelectionTheme.selectionColor),
            )),
            bottom: _loggedIn
                ? null
                : TabBar(
                    controller: _tabController,
                    indicatorColor: Theme.of(context).primaryColor,
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor:
                        Theme.of(context).secondaryHeaderColor,
                    labelStyle: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w800,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w800,
                    ),
                    tabs: const <Widget>[
                      Tab(
                        text: "Login",
                      ),
                      Tab(
                        text: "Register",
                      ),
                    ],
                  ),
          ),
          body: _loggedIn
              ? null
              : TabBarView(
                  controller: _tabController,
                  children: <Widget>[
                    LoginScreen(
                      auth: _auth,
                      login: login,
                      signInWithGoogle: signInWithGoogle,
                      signInWithFacebook: signInWithFacebook,
                    ),
                    RegisterScreen(
                      auth: _auth,
                      register: register,
                    ),
                  ],
                ),
        ),
        onWillPop: () => Future.value(false));
  }
}
