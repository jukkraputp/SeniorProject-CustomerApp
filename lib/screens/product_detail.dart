import 'dart:html';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer/interfaces/item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

class ProductDetail extends StatefulWidget {
  const ProductDetail({super.key, required this.item});

  final Item item;

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  final TextEditingController _commentControl = TextEditingController();

  int _counter = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double imgSize = screenSize.width * 0.5;
    double spaceBetween = screenSize.height * 0.05;
    return Scaffold(
      appBar: AppBar(title: const Text('Product Detail')),
      body: ListView(
        children: <Widget>[
          // Product Name
          Text(widget.item.name),

          // Product Image
          SizedBox(
            height: spaceBetween,
          ),
          CachedNetworkImage(
              width: imgSize,
              height: imgSize,
              fit: BoxFit.cover,
              imageUrl: widget.item.image),

          // Product Detail
          SizedBox(
            height: spaceBetween,
          ),
          if (widget.item.productDetail != null)
            Text(widget.item.productDetail!),

          // Comment
          SizedBox(
            height: spaceBetween,
          ),
          const Center(
            child: Text('Comment'),
          ),
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
                  hintText: "Comment (Minute)",
                ),
                maxLines: 1,
                controller: _commentControl,
              ),
            ),
          ),
          // adjustment buttons
          Row(
            children: <Widget>[
              IconButton(
                  onPressed: () {
                    if (_counter > 0) {
                      setState(() {
                        _counter -= 1;
                      });
                    }
                  },
                  color: Colors.black,
                  icon: const Icon(Icons.remove_circle)),
              Text(
                '$_counter',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
              IconButton(
                  onPressed: () => setState(() {
                        _counter += 1;
                      }),
                  color: Colors.black,
                  icon: const Icon(Icons.add_circle))
            ],
          )
        ],
      ),
    );
  }
}
