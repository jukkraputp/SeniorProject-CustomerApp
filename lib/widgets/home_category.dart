import 'package:flutter/material.dart';
import 'package:customer/screens/categories_screen.dart';

class HomeCategory extends StatefulWidget {
  final IconData icon;
  final String title;
  final String items;
  final Function? tap;
  final bool isHome;

  const HomeCategory(
      {Key? key,
      required this.icon,
      required this.title,
      required this.items,
      this.tap,
      required this.isHome})
      : super(key: key);

  @override
  _HomeCategoryState createState() => _HomeCategoryState();
}

class _HomeCategoryState extends State<HomeCategory> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => widget.isHome
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) {
                    return CategoriesScreen();
                  },
                ),
              );
            }
          : widget.tap,
      child: Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        elevation: 4.0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
          child: Row(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 0.0, right: 10.0),
                child: Icon(
                  widget.icon,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 5),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(height: 10.0),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    "${widget.items} Items",
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
              ),
              const SizedBox(width: 5),
            ],
          ),
        ),
      ),
    );
  }
}
