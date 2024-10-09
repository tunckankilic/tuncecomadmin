import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../consts/app_constants.dart';
import '../consts/validator.dart';
import '../models/product_model.dart';
import '../services/my_app_functions.dart';
import '../widgets/subtitle_text.dart';
import '../widgets/title_text.dart';
import 'loading_manager.dart';

class EditOrUploadProductScreen extends StatefulWidget {
  static const routeName = '/EditOrUploadProductScreen';

  const EditOrUploadProductScreen({super.key, this.productModel});
  final ProductModel? productModel;
  @override
  State<EditOrUploadProductScreen> createState() =>
      _EditOrUploadProductScreenState();
}

class _EditOrUploadProductScreenState extends State<EditOrUploadProductScreen> {
  final _formKey = GlobalKey<FormState>();
  XFile? _pickedImage;
  String? productNetworkImage;
  late TextEditingController _titleController,
      _priceController,
      _descriptionController,
      _quantityController;
  String? _categoryValue;
  bool isEditing = false;
  bool _isLoading = false;
  String? productImageUrl;

  @override
  void initState() {
    if (widget.productModel != null) {
      isEditing = true;
      productNetworkImage = widget.productModel!.productImage;
      _categoryValue = widget.productModel!.productCategory;
    }
    _titleController =
        TextEditingController(text: widget.productModel?.productTitle);
    _priceController =
        TextEditingController(text: widget.productModel?.productPrice);
    _descriptionController =
        TextEditingController(text: widget.productModel?.productDescription);
    _quantityController =
        TextEditingController(text: widget.productModel?.productQuantity);

    super.initState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void clearForm() {
    _titleController.clear();
    _priceController.clear();
    _descriptionController.clear();
    _quantityController.clear();
    removePickedImage();
  }

  void removePickedImage() {
    setState(() {
      _pickedImage = null;
      productNetworkImage = null;
    });
  }

  Widget _buildImageWidget() {
    final size = MediaQuery.of(context).size;
    if (isEditing && productNetworkImage != null) {
      return _buildNetworkImage(productNetworkImage!, size);
    } else if (_pickedImage != null) {
      return _buildPickedImage(_pickedImage!, size);
    } else {
      return SizedBox(
        width: size.width * 0.4 + 10,
        height: size.width * 0.4,
        child: DottedBorder(
          color: Colors.blue,
          strokeWidth: 2,
          borderType: BorderType.RRect,
          radius: const Radius.circular(12),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate, size: 80, color: Colors.blue),
                TextButton(
                  onPressed: localImagePicker,
                  child: Text("Pick Product Image"),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildNetworkImage(String imageUrl, Size size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        height: size.width * 0.5,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print("Error loading image: $error");
          return Container(
            height: size.width * 0.5,
            width: double.infinity,
            color: Colors.grey.shade300,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red, size: 40),
                SizedBox(height: 8),
                Text(
                  "Image not available",
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
        loadingBuilder: (BuildContext context, Widget child,
            ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: size.width * 0.5,
            width: double.infinity,
            color: Colors.grey.shade200,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPickedImage(XFile image, Size size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: kIsWeb
          ? Image.network(
              image.path,
              height: size.width * 0.5,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print("Error loading picked image: $error");
                return Container(
                  height: size.width * 0.5,
                  width: double.infinity,
                  color: Colors.grey.shade300,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 40),
                      SizedBox(height: 8),
                      Text(
                        "Error loading selected image",
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            )
          : Image.file(
              File(image.path),
              height: size.width * 0.5,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
    );
  }

  Future<void> _uploadProduct() async {
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();
    if (_pickedImage == null) {
      MyAppFunctions.showErrorOrWarningDialog(
          context: context, subtitle: "Please select an image", fct: () {});
      return;
    }
    if (isValid) {
      try {
        setState(() {
          _isLoading = true;
        });

        String imageUrl;
        if (kIsWeb) {
          // Web için
          final ref = FirebaseStorage.instance
              .ref()
              .child("productsImages")
              .child("${_titleController.text}.jpg");
          await ref.putData(await _pickedImage!.readAsBytes());
          imageUrl = await ref.getDownloadURL();
        } else {
          // Mobil için
          final ref = FirebaseStorage.instance
              .ref()
              .child("productsImages")
              .child("${_titleController.text}.jpg");
          await ref.putFile(File(_pickedImage!.path));
          imageUrl = await ref.getDownloadURL();
        }

        final productId = const Uuid().v4();
        await FirebaseFirestore.instance
            .collection("products")
            .doc(productId)
            .set({
          'productId': productId,
          'productTitle': _titleController.text,
          'productPrice': _priceController.text,
          'productImage': imageUrl,
          'productCategory': _categoryValue,
          'productDescription': _descriptionController.text,
          'productQuantity': _quantityController.text,
          'createdAt': Timestamp.now(),
        });

        Fluttertoast.showToast(
          msg: "Product has been added successfully",
          textColor: Colors.white,
          backgroundColor: Colors.green,
        );
        if (!mounted) return;
        MyAppFunctions.showErrorOrWarningDialog(
            isError: false,
            context: context,
            subtitle: "Would you like to clear the form?",
            fct: () {
              clearForm();
            });
      } catch (error) {
        await MyAppFunctions.showErrorOrWarningDialog(
          context: context,
          subtitle: error.toString(),
          fct: () {},
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _editProduct() async {
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();
    if (_pickedImage == null && productNetworkImage == null) {
      MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: "Please select an image",
        fct: () {},
      );
      return;
    }
    if (isValid) {
      try {
        setState(() {
          _isLoading = true;
        });
        final productIdFixed = widget.productModel!.productId;
        String? imageUrl = productNetworkImage;

        if (_pickedImage != null) {
          if (kIsWeb) {
            // Web için
            final ref = FirebaseStorage.instance
                .ref()
                .child("productsImages")
                .child("$productIdFixed.jpg");
            await ref.putData(await _pickedImage!.readAsBytes());
            imageUrl = await ref.getDownloadURL();
          } else {
            // Mobil için
            final ref = FirebaseStorage.instance
                .ref()
                .child("productsImages")
                .child("$productIdFixed.jpg");
            await ref.putFile(File(_pickedImage!.path));
            imageUrl = await ref.getDownloadURL();
          }
        }

        await FirebaseFirestore.instance
            .collection("products")
            .doc(productIdFixed)
            .update({
          'productTitle': _titleController.text,
          'productPrice': _priceController.text,
          'productImage': imageUrl,
          'productCategory': _categoryValue,
          'productDescription': _descriptionController.text,
          'productQuantity': _quantityController.text,
        });

        Fluttertoast.showToast(
          msg: "Product has been updated successfully",
          textColor: Colors.white,
          backgroundColor: Colors.green,
        );
        if (!mounted) return;
        Navigator.pop(context);
      } catch (error) {
        await MyAppFunctions.showErrorOrWarningDialog(
          context: context,
          subtitle: error.toString(),
          fct: () {},
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> localImagePicker() async {
    final ImagePicker picker = ImagePicker();
    await MyAppFunctions.imagePickerDialog(
      context: context,
      cameraFCT: () async {
        final XFile? image = await picker.pickImage(source: ImageSource.camera);
        if (image != null) {
          setState(() {
            _pickedImage = image;
            productNetworkImage = null;
          });
        }
      },
      galleryFCT: () async {
        final XFile? image =
            await picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          setState(() {
            _pickedImage = image;
            productNetworkImage = null;
          });
        }
      },
      removeFCT: () {
        setState(() {
          _pickedImage = null;
          productNetworkImage = null;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return LoadingManager(
      isLoading: _isLoading,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: TitlesTextWidget(
              label: isEditing ? "Edit Product" : "Upload New Product",
            ),
            leading: IconButton(
              onPressed: () =>
                  Navigator.canPop(context) ? Navigator.pop(context) : null,
              icon: const Icon(Icons.arrow_back_ios, size: 18),
            ),
            actions: [
              IconButton(
                onPressed: clearForm,
                icon: const Icon(Icons.clear),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildImageWidget(),
                  if (_pickedImage != null || productNetworkImage != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => localImagePicker(),
                          child: const Text("Pick another image"),
                        ),
                        TextButton(
                          onPressed: removePickedImage,
                          child: const Text(
                            "Remove image",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 25),
                  DropdownButton<String>(
                    value: _categoryValue,
                    hint: const Text("Select a Category"),
                    items: AppConstants.categoriesDropDownList,
                    onChanged: (String? value) {
                      setState(() {
                        _categoryValue = value;
                      });
                    },
                  ),
                  const SizedBox(height: 25),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _titleController,
                            key: const ValueKey('Title'),
                            maxLength: 80,
                            minLines: 1,
                            maxLines: 2,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            decoration: const InputDecoration(
                              hintText: 'Product Title',
                            ),
                            validator: (value) {
                              return MyValidators.uploadProdTexts(
                                value: value,
                                toBeReturnedString:
                                    "Please enter a valid title",
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Flexible(
                                flex: 1,
                                child: TextFormField(
                                  controller: _priceController,
                                  key: const ValueKey('Price \$'),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^(\d+)?\.?\d{0,2}'),
                                    ),
                                  ],
                                  decoration: const InputDecoration(
                                    hintText: 'Price',
                                    prefix: SubtitleTextWidget(
                                      label: "\$ ",
                                      color: Colors.blue,
                                      fontSize: 16,
                                    ),
                                  ),
                                  validator: (value) {
                                    return MyValidators.uploadProdTexts(
                                      value: value,
                                      toBeReturnedString: "Price is required",
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                flex: 1,
                                child: TextFormField(
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  controller: _quantityController,
                                  keyboardType: TextInputType.number,
                                  key: const ValueKey('Quantity'),
                                  decoration: const InputDecoration(
                                    hintText: 'Qty',
                                  ),
                                  validator: (value) {
                                    return MyValidators.uploadProdTexts(
                                      value: value,
                                      toBeReturnedString:
                                          "Quantity is required",
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            key: const ValueKey('Description'),
                            controller: _descriptionController,
                            minLines: 5,
                            maxLines: 8,
                            maxLength: 1000,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: 'Product description',
                            ),
                            validator: (value) {
                              return MyValidators.uploadProdTexts(
                                value: value,
                                toBeReturnedString: "Description is required",
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomSheet: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.upload),
              label: Text(isEditing ? "Edit Product" : "Upload Product"),
              onPressed: () {
                if (isEditing) {
                  _editProduct();
                } else {
                  _uploadProduct();
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
