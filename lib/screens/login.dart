import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:customer/apis/api.dart';
import 'package:customer/interfaces/customer/user.dart' as AppUser;
import 'package:customer/screens/main_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  final bool auth;
  final Future<dynamic> Function(
      {String username, String password, String? uid}) login;
  final Future<UserCredential> Function() signInWithGoogle;
  final Future<UserCredential> Function() signInWithFacebook;

  const LoginScreen(
      {super.key,
      required this.auth,
      required this.login,
      required this.signInWithGoogle,
      required this.signInWithFacebook});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameControl = TextEditingController();
  final TextEditingController _passwordControl = TextEditingController();
  final API api = API();

  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String username = '';
    String password = '';
    String? uid;
    if (_loggedIn & (FirebaseAuth.instance.currentUser != null)) {
      User user = FirebaseAuth.instance.currentUser!;
      uid = user.uid;
    } else {
      username = _usernameControl.text;
      password = _passwordControl.text;
    }
    if (widget.auth & !_loggedIn) {
      widget.login(username: username, password: password, uid: uid);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 0, 20, 0),
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          const SizedBox(height: 10.0),
          Container(
            alignment: Alignment.center,
            margin: const EdgeInsets.only(
              top: 25.0,
            ),
            child: Text(
              "Log in to your account",
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
          const SizedBox(height: 30.0),
          Card(
            elevation: 3.0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(
                  Radius.circular(5.0),
                ),
              ),
              child: TextField(
                style: const TextStyle(
                  fontSize: 15.0,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(10.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                    borderSide: const BorderSide(
                      color: Colors.white,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.white,
                    ),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  hintText: "Username",
                  hintStyle: const TextStyle(
                    fontSize: 15.0,
                    color: Colors.black,
                  ),
                  prefixIcon: const Icon(
                    Icons.perm_identity,
                    color: Colors.black,
                  ),
                ),
                maxLines: 1,
                controller: _usernameControl,
              ),
            ),
          ),
          const SizedBox(height: 10.0),
          Card(
            elevation: 3.0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(
                  Radius.circular(5.0),
                ),
              ),
              child: TextField(
                style: const TextStyle(
                  fontSize: 15.0,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(10.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                    borderSide: const BorderSide(
                      color: Colors.white,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.white,
                    ),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  hintText: "Password",
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Colors.black,
                  ),
                  hintStyle: const TextStyle(
                    fontSize: 15.0,
                    color: Colors.black,
                  ),
                ),
                obscureText: true,
                maxLines: 1,
                controller: _passwordControl,
              ),
            ),
          ),
          const SizedBox(height: 10.0),
          Container(
            alignment: Alignment.centerRight,
            child: TextButton(
              child: Text(
                "Forgot Password?",
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              onPressed: () {},
            ),
          ),
          const SizedBox(height: 30.0),
          Container(
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(width: 3),
                borderRadius: BorderRadius.circular(12)),
            height: 50.0,
            child: TextButton(
              onPressed: () {
                String username = '';
                String password = '';
                String? uid;
                if (_loggedIn & (FirebaseAuth.instance.currentUser != null)) {
                  User user = FirebaseAuth.instance.currentUser!;
                  uid = user.uid;
                } else {
                  username = _usernameControl.text;
                  password = _passwordControl.text;
                }
                widget
                    .login(username: username, password: password, uid: uid)
                    .then((value) {
                  setState(() {
                    _loggedIn = true;
                  });
                });
                /* User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  api.getUserInfo(user.uid).then((manager) {
                    if (manager != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext context) {
                            return MainScreen(
                              userInfo: AppUser.User(
                                  manager.username, manager.shopList),
                            );
                          },
                        ),
                      );
                    } else {
                      print('manager data is empty');
                    }
                  });
                } else {
                  print('please sign in!');
                } */
              },
              child: Text(
                "LOGIN".toUpperCase(),
                style: const TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10.0),
          Divider(
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 10.0),
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
//                   RawMaterialButton(
//                     onPressed: () async {
//                       await widget.signInWithFacebook();
//                     },
//                     fillColor: Colors.blue[800],
//                     shape: const CircleBorder(),
//                     elevation: 4.0,
//                     child: const Padding(
//                       padding: EdgeInsets.all(15),
//                       child: Icon(
//                         FontAwesomeIcons.facebookF,
//                         color: Colors.white,
// //              size: 24.0,
//                       ),
//                     ),
//                   ),
                  RawMaterialButton(
                    onPressed: () async {
                      await widget.signInWithGoogle();
                    },
                    fillColor: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 4.0,
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Icon(
                        FontAwesomeIcons.google,
                        color: Colors.blue[800],
//              size: 24.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20.0),
        ],
      ),
    );
  }
}
