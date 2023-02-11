import 'package:customer/apis/api.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:customer/screens/main_screen.dart';
import 'package:lottie/lottie.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen(
      {super.key,
      required this.user,
      required this.login,
      required this.signInWithGoogle,
      required this.signInWithFacebook});

  final User? user;
  final Future<dynamic> Function(
      {String password, String? uid, String username}) login;
  final Future<UserCredential> Function() signInWithGoogle;
  final Future<UserCredential> Function() signInWithFacebook;

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameControl = TextEditingController();
  final TextEditingController _emailControl = TextEditingController();
  final TextEditingController _passwordControl = TextEditingController();
  final API api = API();
  bool registering = false;

  @override
  Widget build(BuildContext context) {
    return registering
        ? Center(
            child: Lottie.asset('assets/animations/colors-circle-loader.json'),
          )
        : Padding(
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
                    "Create an account",
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
                        prefixIcon: const Icon(
                          Icons.perm_identity,
                          color: Colors.black,
                        ),
                        hintStyle: const TextStyle(
                          fontSize: 15.0,
                          color: Colors.black,
                        ),
                      ),
                      maxLines: 1,
                      controller: _usernameControl,
                    ),
                  ),
                ),
                const SizedBox(height: 10.0),
                // Card(
                //   elevation: 3.0,
                //   child: Container(
                //     decoration: const BoxDecoration(
                //       color: Colors.white,
                //       borderRadius: BorderRadius.all(
                //         Radius.circular(5.0),
                //       ),
                //     ),
                //     child: TextField(
                //       style: const TextStyle(
                //         fontSize: 15.0,
                //         color: Colors.black,
                //       ),
                //       decoration: InputDecoration(
                //         contentPadding: const EdgeInsets.all(10.0),
                //         border: OutlineInputBorder(
                //           borderRadius: BorderRadius.circular(5.0),
                //           borderSide: const BorderSide(
                //             color: Colors.white,
                //           ),
                //         ),
                //         enabledBorder: OutlineInputBorder(
                //           borderSide: const BorderSide(
                //             color: Colors.white,
                //           ),
                //           borderRadius: BorderRadius.circular(5.0),
                //         ),
                //         hintText: "Email",
                //         prefixIcon: const Icon(
                //           Icons.mail_outline,
                //           color: Colors.black,
                //         ),
                //         hintStyle: const TextStyle(
                //           fontSize: 15.0,
                //           color: Colors.black,
                //         ),
                //       ),
                //       maxLines: 1,
                //       controller: _emailControl,
                //     ),
                //   ),
                // ),
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
                const SizedBox(height: 40.0),
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(width: 3),
                      borderRadius: BorderRadius.circular(12)),
                  height: 50.0,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        registering = true;
                      });
                      api
                          .register(
                              username: _usernameControl.text,
                              password: _passwordControl.text,
                              mode: 'Customer')
                          .then((value) {
                        setState(() {
                          registering = false;
                        });

                        print('Register Success: ${value.success}');
                      });
                    },
                    /* color: Theme.of(context).accentColor, */
                    child: Text(
                      "Register".toUpperCase(),
                      style: const TextStyle(
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10.0),
                Divider(
                  color: Theme.of(context).accentColor,
                ),
                const SizedBox(height: 10.0),
                Center(
                  child: Container(
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
