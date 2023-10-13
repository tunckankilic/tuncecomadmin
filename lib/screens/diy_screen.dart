import 'dart:developer';
import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tuncecomadmin/models/product_model.dart';
import 'package:tuncecomadmin/providers/diy_provider.dart';
import 'package:tuncecomadmin/providers/products_provider.dart';
import 'package:tuncecomadmin/widgets/product_tile.dart';
import 'package:tuncecomadmin/widgets/title_text_widget.dart';

class DIYPanel extends StatefulWidget {
  static const routeName = "/diy";

  const DIYPanel({Key? key}) : super(key: key);

  @override
  _DIYPanelState createState() => _DIYPanelState();
}

class _DIYPanelState extends State<DIYPanel> {
  final formKey = GlobalKey<FormState>();

  XFile? _pickedImage;

  @override
  Widget build(BuildContext context) {
    final diyProvider = Provider.of<DIYProvider>(context);
    final productsProvider = Provider.of<ProductsProvider>(context);
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('DIY Panel'),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 400,
                child: StreamBuilder<List<ProductModel>>(
                  stream: productsProvider.fetchProductsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: SelectableText(snapshot.error.toString()),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: SelectableText("No products have been added"),
                      );
                    }

                    final List<ProductModel> productList = snapshot.data!;

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 15.0,
                          ),
                          TextField(
                            controller: diyProvider.searchController,
                            decoration: InputDecoration(
                              hintText: "Search",
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    FocusScope.of(context).unfocus();
                                    diyProvider.searchController.clear();
                                  });
                                },
                                child: const Icon(
                                  Icons.clear,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                diyProvider.productListSearch =
                                    productsProvider.searchQuery(
                                  searchText: diyProvider.searchController.text,
                                  passedList: productList,
                                );
                              });
                            },
                          ),
                          const SizedBox(
                            height: 15.0,
                          ),
                          if (diyProvider.searchController.text.isNotEmpty &&
                              diyProvider.productListSearch.isEmpty) ...[
                            const Center(
                              child:
                                  TitlesTextWidget(label: "No products found"),
                            ),
                          ],
                          SizedBox(
                            height: 300,
                            child: ListView.builder(
                              itemCount:
                                  diyProvider.searchController.text.isNotEmpty
                                      ? diyProvider.productListSearch.length
                                      : productList.length,
                              itemBuilder: (context, index) {
                                final ProductModel product =
                                    diyProvider.searchController.text.isNotEmpty
                                        ? diyProvider.productListSearch[index]
                                        : productList[index];

                                return ProductTile(
                                  choice: true,
                                  productId: product.productId,
                                  onTap: () {
                                    setState(() {
                                      log("1");
                                      if (!diyProvider.productsCountList
                                          .contains(product.productId)) {
                                        diyProvider.productsCountList
                                            .add(product.productId);
                                      }
                                      log("2");
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (_pickedImage == null) ...[
                SizedBox(
                  width: size.width * 0.4 + 10,
                  height: size.width * 0.4,
                  child: DottedBorder(
                    child: Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.image_outlined,
                            size: 80,
                            color: Colors.blue,
                          ),
                          TextButton(
                            onPressed: () async {
                              localImagePicker();
                            },
                            child: const Text("Pick Product Image"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(
                      _pickedImage!.path,
                    ),
                    height: size.width * 0.5,
                    alignment: Alignment.center,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        localImagePicker();
                      },
                      child: const Text("Pick another image"),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _pickedImage = null;
                        });
                      },
                      child: const Text(
                        "Remove image",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(
                height: 25,
              ),
              TextFormField(
                controller: diyProvider.titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(
                height: 10,
              ),
              TextFormField(
                controller: diyProvider.descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 10,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const TitlesTextWidget(label: "Products"),
                      const SizedBox(
                        height: 15,
                      ),
                      SizedBox(
                        height: 200,
                        child: SingleChildScrollView(
                          child: Column(
                            children: diyProvider.productsCountList.isEmpty
                                ? [
                                    Text(
                                      "Add Products",
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall,
                                    )
                                  ]
                                : diyProvider.productsCountList
                                    .map((productId) {
                                    return ProductTile(
                                      choice: true,
                                      productId: productId,
                                      onTap: () {
                                        // Burada herhangi bir işlem yapmak istiyorsanız
                                      },
                                    );
                                  }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => diyProvider.clearForm(),
                child: const Text('Clear Form'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final form = formKey.currentState;
                  if (form != null && form.validate()) {
                    File imageFile = File("");

                    if (_pickedImage != null) {
                      imageFile = File(_pickedImage!.path);
                    }

                    await diyProvider
                        .uploadDIY(
                      context,
                      title: diyProvider.titleController.text,
                      description: diyProvider.descriptionController.text,
                      steps: diyProvider.productsCountList,
                      imageFile: imageFile,
                    )
                        .then(
                      (value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Item Uploaded"),
                          ),
                        );
                      },
                    ).catchError((error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Error: $error"),
                        ),
                      );
                    }).whenComplete(
                      () => Navigator.of(context).pop(),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please fill in all fields correctly."),
                      ),
                    );
                  }
                },
                child: const Text('Send Recipe'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void localImagePicker() async {
    final ImagePicker picker = ImagePicker();
    XFile? pickedImage;

    try {
      pickedImage = await picker.pickImage(source: ImageSource.camera);
    } catch (e) {
      log("Error picking image from camera: $e");
    }

    if (pickedImage == null) {
      try {
        pickedImage = await picker.pickImage(source: ImageSource.gallery);
      } catch (e) {
        log("Error picking image from gallery: $e");
      }
    }

    setState(() {
      _pickedImage = pickedImage; // Eğer null ise boş bir XFile oluştur
    });
  }
}
