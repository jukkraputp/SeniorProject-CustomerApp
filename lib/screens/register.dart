import 'package:customer/interfaces/register.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:customer/apis/api.dart';

class RegisterScreen extends StatefulWidget {
  final bool auth;
  final Future<RegisterResult> Function(
      {String username,
      String email,
      String password,
      String phoneNumber}) register;

  const RegisterScreen({super.key, required this.auth, required this.register});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameControl = TextEditingController();
  final TextEditingController _emailControl = TextEditingController();
  final TextEditingController _passwordControl = TextEditingController();
  final TextEditingController _phoneNumberControl = TextEditingController();
  final API api = API();

  bool _registering = false;
  bool _showingLoader = false;

  bool checkData() {
    if (_passwordControl.text.length < 6) return false;
    if (_usernameControl.text.isEmpty) return false;
    if (_emailControl.text.isEmpty) return false;
    if (_phoneNumberControl.text.isEmpty) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
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
                  hintText: "Email",
                  prefixIcon: const Icon(
                    Icons.mail_outline,
                    color: Colors.black,
                  ),
                  hintStyle: const TextStyle(
                    fontSize: 15.0,
                    color: Colors.black,
                  ),
                ),
                maxLines: 1,
                controller: _emailControl,
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
                  hintText: "Phone (ที่เชื่อมต่อกับ PromptPay)",
                  prefixIcon: const Icon(
                    Icons.phone,
                    color: Colors.black,
                  ),
                  hintStyle: const TextStyle(
                    fontSize: 15.0,
                    color: Colors.black,
                  ),
                ),
                maxLines: 1,
                controller: _phoneNumberControl,
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
                if (checkData()) {
                  showDialog(
                      context: context,
                      builder: ((context) {
                        return Center(
                          child: Lottie.asset(
                              'assets/animations/colors-circle-loader.json'),
                        );
                      }),
                      routeSettings: const RouteSettings(name: 'Loader'));
                  setState(() {
                    _registering = true;
                  });
                  widget
                      .register(
                          username: _usernameControl.text,
                          password: _passwordControl.text,
                          email: _emailControl.text,
                          phoneNumber: _phoneNumberControl.text)
                      .then((value) {
                    setState(() {
                      _registering = false;
                    });
                    print(value);
                  });
                } else {
                  showDialog(
                      context: context,
                      builder: ((context) {
                        return AlertDialog(
                          title: const Text('Registeration failed'),
                          content: const Text(
                              'Your password must have 6 or more characters'),
                          actions: <Widget>[
                            TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'))
                          ],
                        );
                      }));
                }
              },
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
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 10.0),
        ],
      ),
    );
  }
}
