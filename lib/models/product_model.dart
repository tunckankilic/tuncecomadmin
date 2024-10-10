import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductModel {
  final String productId;
  final String productTitle;
  final String productPrice;
  final String productCategory;
  final String productDescription;
  final String productImage;
  final String productQuantity;
  final Timestamp createdAt;

  ProductModel({
    required this.productId,
    required this.productTitle,
    required this.productPrice,
    required this.productCategory,
    required this.productDescription,
    required this.productImage,
    required this.productQuantity,
    required this.createdAt,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      productId: data['productId'] ?? '',
      productTitle: data['productTitle'] ?? '',
      productPrice: data['productPrice'] ?? '',
      productCategory: data['productCategory'] ?? '',
      productDescription: data['productDescription'] ?? '',
      productImage: data['productImage'] ?? '',
      productQuantity: data['productQuantity'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}

class Product {
  final String title;
  final String imagePath;

  Product({
    required this.title,
    required this.imagePath,
  });
}
