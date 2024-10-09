import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/products_provider.dart';
import '../screens/edit_upload_product_form.dart';
import 'subtitle_text.dart';
import 'title_text.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductWidget extends StatelessWidget {
  const ProductWidget({
    Key? key,
    required this.productId,
  }) : super(key: key);

  final String productId;

  @override
  Widget build(BuildContext context) {
    final productsProvider = Provider.of<ProductsProvider>(context);
    final getCurrProduct = productsProvider.findByProdId(productId);
    Size size = MediaQuery.of(context).size;

    if (getCurrProduct == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditOrUploadProductScreen(
                productModel: getCurrProduct,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: _buildProductImage(getCurrProduct.productImage, size),
            ),
            const SizedBox(height: 8.0),
            TitlesTextWidget(
              label: getCurrProduct.productTitle,
              fontSize: 16,
              maxLines: 2,
            ),
            const SizedBox(height: 4.0),
            SubtitleTextWidget(
              label: "${getCurrProduct.productPrice}\$",
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String imageUrl, Size size) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      height: size.height * 0.22,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey.shade300,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) {
        print("Error loading image: $error");
        return Container(
          color: Colors.grey.shade300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 40),
              SizedBox(height: 8),
              Text(
                "Image not available\nError: ${error.toString()}",
                style: TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
