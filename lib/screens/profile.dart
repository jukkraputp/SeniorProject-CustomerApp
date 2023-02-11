import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer/util/confirmation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:customer/providers/app_provider.dart';
import 'package:customer/screens/splash.dart';
import 'package:customer/util/const.dart';

class Profile extends StatefulWidget {
  const Profile({super.key, required this.user});

  final User user;
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double imgSize = screenSize.width / 4;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 10, 10.0, 0),
        child: ListView(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                if (widget.user.photoURL != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                    child: CachedNetworkImage(
                        width: imgSize,
                        height: imgSize,
                        fit: BoxFit.cover,
                        imageUrl: widget.user.photoURL!),
                  ),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            widget.user.displayName!,
                            style: const TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            widget.user.email!,
                            style: const TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          InkWell(
                            onTap: () => confirmation(context,
                                onNo: () => Navigator.of(context).pop(false),
                                onYes: () => FirebaseAuth.instance.signOut(),
                                title: const Text('Logout'),
                                content: const Text('Are you sure?')),
                            child: Text(
                              "Logout",
                              style: TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w400,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            Container(height: 15.0),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Text(
                "Account Information".toUpperCase(),
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              title: const Text(
                "Full Name",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                widget.user.displayName!,
              ),
              /* trailing: IconButton(
                icon: const Icon(
                  Icons.edit,
                  size: 20.0,
                ),
                onPressed: () {},
                tooltip: "Edit",
              ), */
            ),
            ListTile(
              title: const Text(
                "Email",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                widget.user.email!,
              ),
            ),
            if (widget.user.phoneNumber != null)
              ListTile(
                title: const Text(
                  "Phone",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  widget.user.phoneNumber!,
                ),
              ),
            /* const ListTile(
              title: Text(
                "Address",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                "1278 Loving Acres RoadKansas City, MO 64110",
              ),
            ), */
            /* const ListTile(
              title: Text(
                "Gender",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                "Female",
              ),
            ), */
            /* const ListTile(
              title: Text(
                "Date of Birth",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                "Jan 1, 2000",
              ),
            ), */
            MediaQuery.of(context).platformBrightness == Brightness.dark
                ? const SizedBox()
                : ListTile(
                    title: const Text(
                      "Dark Theme",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    trailing: Switch(
                      value: Provider.of<AppProvider>(context).theme ==
                              Constants.lightTheme
                          ? false
                          : true,
                      onChanged: (v) async {
                        if (v) {
                          Provider.of<AppProvider>(context, listen: false)
                              .setTheme(Constants.darkTheme, "dark");
                        } else {
                          Provider.of<AppProvider>(context, listen: false)
                              .setTheme(Constants.lightTheme, "light");
                        }
                      },
                      activeColor: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
