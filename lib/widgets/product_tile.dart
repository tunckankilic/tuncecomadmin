// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tuncecomadmin/providers/products_provider.dart';
import 'package:tuncecomadmin/widgets/subtitle_text.dart';
import 'package:tuncecomadmin/widgets/title_text_widget.dart';

class ProductTile extends StatefulWidget {
  ProductTile(
      {Key? key, required this.productId, this.onTap, required this.choice})
      : super(key: key);
  final String productId;
  VoidCallback? onTap;
  final bool choice;

  @override
  State<ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends State<ProductTile> {
  @override
  Widget build(BuildContext context) {
    // final productModelProvider = Provider.of<ProductModel>(context);
    final productsProvider = Provider.of<ProductsProvider>(context);
    final getCurrProduct = productsProvider.findByProdId(widget.productId);
    Size size = MediaQuery.of(context).size;

    return getCurrProduct == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: widget.choice ? widget.onTap : null,
              child: Column(
                children: [
                  ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: FancyShimmerImage(
                        imageUrl: getCurrProduct.productImage,
                        height: 150,
                        width: 150,
                      ),
                    ),
                    title: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: TitlesTextWidget(
                        label: getCurrProduct.productTitle,
                        fontSize: 18,
                        maxLines: 2,
                      ),
                    ),
                    trailing: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: SubtitleTextWidget(
                        label: "${getCurrProduct.productPrice}\$",
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}
