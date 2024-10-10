import 'dart:developer';
import 'dart:io';
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
        elevation: 0,
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProductList(diyProvider, productsProvider, size),
                const SizedBox(height: 24),
                _buildImagePicker(size),
                const SizedBox(height: 24),
                _buildTextFields(diyProvider),
                const SizedBox(height: 24),
                _buildSelectedProducts(diyProvider),
                const SizedBox(height: 24),
                _buildButtons(diyProvider, context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductList(
      DIYProvider diyProvider, ProductsProvider productsProvider, Size size) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Products',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
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
                  child: const Icon(Icons.clear, color: Colors.red),
                ),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (value) {
                setState(() {
                  diyProvider.productListSearch = productsProvider.searchQuery(
                    searchText: diyProvider.searchController.text,
                    passedList: productsProvider.getProducts,
                  );
                });
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: StreamBuilder<List<ProductModel>>(
                stream: productsProvider.fetchProductsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No products available"));
                  }

                  final List<ProductModel> productList =
                      diyProvider.searchController.text.isNotEmpty
                          ? diyProvider.productListSearch
                          : snapshot.data!;

                  return ListView.builder(
                    itemCount: productList.length,
                    itemBuilder: (context, index) {
                      final ProductModel product = productList[index];
                      return ProductTile(
                        choice: true,
                        productId: product.productId,
                        onTap: () {
                          setState(() {
                            if (!diyProvider.productsCountList
                                .contains(product.productId)) {
                              diyProvider.productsCountList
                                  .add(product.productId);
                            }
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(Size size) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recipe Image', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (_pickedImage == null)
              GestureDetector(
                onTap: localImagePicker,
                child: Container(
                  width: double.infinity,
                  height: size.width * 0.4,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate,
                          size: 50, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text('Add Image', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_pickedImage!.path),
                      height: size.width * 0.4,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: localImagePicker,
                        icon: Icon(Icons.photo_library),
                        label: Text('Change'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _pickedImage = null),
                        icon: Icon(Icons.delete),
                        label: Text('Remove'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFields(DIYProvider diyProvider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recipe Details',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: diyProvider.titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: diyProvider.descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              maxLines: 5,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a description' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedProducts(DIYProvider diyProvider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selected Products',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: diyProvider.productsCountList.isEmpty
                  ? Center(
                      child: Text('No products selected',
                          style: TextStyle(color: Colors.grey)))
                  : ListView(
                      children: diyProvider.productsCountList.map((productId) {
                        return ProductTile(
                          choice: true,
                          productId: productId,
                          onTap: () {
                            setState(() {
                              diyProvider.productsCountList.remove(productId);
                            });
                          },
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons(DIYProvider diyProvider, BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => diyProvider.clearForm(),
            child: const Text('Clear Form'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _submitForm(diyProvider, context),
            child: const Text('Send Recipe'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  void _submitForm(DIYProvider diyProvider, BuildContext context) async {
    final form = formKey.currentState;
    if (form != null && form.validate()) {
      File imageFile = File(_pickedImage?.path ?? "");

      try {
        await diyProvider.uploadDIY(
          context,
          title: diyProvider.titleController.text,
          description: diyProvider.descriptionController.text,
          steps: diyProvider.productsCountList,
          imageFile: imageFile,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Recipe Uploaded Successfully"),
              backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $error"), backgroundColor: Colors.red),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please fill in all fields correctly."),
            backgroundColor: Colors.orange),
      );
    }
  }

  void localImagePicker() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedImage =
          await picker.pickImage(source: ImageSource.gallery);
      setState(() {
        _pickedImage = pickedImage;
      });
    } catch (e) {
      log("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Error selecting image"),
            backgroundColor: Colors.red),
      );
    }
  }
}
