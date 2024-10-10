import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import "package:cloud_firestore/cloud_firestore.dart";
import 'package:tuncecomadmin/models/diy_panel.dart';
import 'package:tuncecomadmin/models/product_model.dart';
import 'package:tuncecomadmin/services/my_app_functions.dart';
import 'package:uuid/uuid.dart';

class DIYProvider extends ChangeNotifier {
  List<ProductModel> productListSearch = [];
  List<String> productsCountList = [];
  TextEditingController searchController = TextEditingController();
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  List<TextEditingController> stepTextControllers = [];
  final List<String> productsToAdd = [];
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String? productNetworkImage;
  XFile? pickedImage;
  String? imagePath;
  bool isEditing = false;
  bool isLoading = false;
  String uuid = const Uuid().v4();
  List<String> productSearchResults = [];
  String? selectedProduct;
  String? selectedLetter;

  void setSelectedLetter(String letter) {
    selectedLetter = letter;
    notifyListeners();
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void addTextField() {
    stepTextControllers.add(TextEditingController());
    notifyListeners();
  }

  void removeTextField(int index) {
    stepTextControllers[index].dispose();
    stepTextControllers.removeAt(index);
    notifyListeners();
  }

  Future<void> searchProducts(String query) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('productTitle', isGreaterThanOrEqualTo: query)
          .get();

      // Ensure that querySnapshot is not null and has documents
      if (querySnapshot.docs.isNotEmpty) {
        productSearchResults =
            querySnapshot.docs.map((doc) => doc['name'] as String).toList();
      } else {
        productSearchResults = []; // No results found
      }

      notifyListeners();
    } catch (error) {
      log('Error searching products: $error');
      // Handle the error as needed
    }
  }

  Future<void> localImagePicker(
      {XFile? pickedImage, required BuildContext context}) async {
    final ImagePicker picker = ImagePicker();
    await MyAppFunctions.imagePickerDialog(
      context: context,
      cameraFCT: () async {
        pickedImage = (await picker.pickImage(source: ImageSource.camera))!;
        productNetworkImage == null;
        notifyListeners();
      },
      galleryFCT: () async {
        pickedImage = (await picker.pickImage(source: ImageSource.gallery))!;
        productNetworkImage == null;
        notifyListeners();
      },
      removeFCT: () {
        pickedImage = null;
      },
    );
  }

  void addProductsToCountList(List<String> productIds) {
    final List<String> productsToAdd = [];

    for (final productId in productIds) {
      productsToAdd.add(productId);
    }

    for (final productId in productsToAdd) {
      productsCountList.add(productId);
      log("2");

      // Eğer bu ürünü steps listesine eklemek isterseniz:
      stepTextControllers.add(TextEditingController(text: productId));
    }

    notifyListeners();
  }

  Future<void> sendRecipeToFirestore({
    XFile? pickedImage,
    String? title,
    String? description,
    required List<String> steps,
  }) async {
    try {
      final CollectionReference recipes =
          FirebaseFirestore.instance.collection('recipes');

      // Resmi Firestore Storage'a yükleyin ve URL'yi alın
      String imageUrl = await uploadImageToFirestoreStorage(pickedImage);

      // Adımları Firestore'a eklemek için kullanılacak dizi
      List<Map<String, dynamic>> stepsList =
          steps.map((step) => {'description': step}).toList();

      // Firestore'a veriyi ekleyin
      await recipes.add({
        'title': title,
        'description': description,
        'steps': stepsList, // Adımları bu şekilde ekleyin
        'image_url': imageUrl,
      });

      // Başarı mesajı
      print('Recipe added to Firestore');
    } catch (e) {
      // Hata mesajı
      print('Error adding recipe to Firestore: $e');
    }
  }

  Future<String> uploadImageToFirestoreStorage(XFile? pickedImage) async {
    if (pickedImage == null) {
      return ''; // Eğer resim yoksa boş bir URL döndürülebilir veya hata yönetimi yapılabilir
    }

    try {
      // Firestore Storage referansını alın
      final storageRef = FirebaseStorage.instance.ref();

      // Resmi yükleyin ve indirme URL'sini alın
      final TaskSnapshot uploadTask = await storageRef
          .child('recipe_images/${DateTime.now().millisecondsSinceEpoch}.jpg')
          .putFile(File(pickedImage.path));

      final String imageUrl = await uploadTask.ref.getDownloadURL();

      return imageUrl;
    } catch (e) {
      log('Error uploading image to Firestore Storage: $e');
      return ''; // Hata durumunda boş bir URL döndürülebilir veya hata yönetimi yapılabilir
    }
  }

  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    for (var controller in stepTextControllers) {
      controller.clear();
    }
    pickedImage = null;
    imagePath = null;
    notifyListeners();
  }

  Future<void> uploadDIY(
    BuildContext context, {
    required String title,
    required String description,
    required List<String> steps,
    required File imageFile,
  }) async {
    try {
      setLoading(true);

      // Resmi Firebase Storage'a yükle
      final storageRef =
          FirebaseStorage.instance.ref().child("diyImages").child("$title.jpg");
      await storageRef.putFile(imageFile);
      final imageUrl = await storageRef.getDownloadURL();

      // Firebase'e DIY verilerini yükle veya ihtiyaca göre kaydet
      // Firestore koleksiyon referansını ve alan adlarını kendi DIY veri yapınızla değiştirin
      // Örnek:
      await FirebaseFirestore.instance
          .collection("diyCollection")
          .doc(uuid) // Bu.uuid'yi belge kimliği olarak kullanın
          .set({
        'id': uuid,
        'title': title,
        'description': description,
        'imagePath': imageUrl,
        'steps': steps,
      });

      // Formu temizle
      clearForm();

      // Başarılı bir şekilde yüklendiğinde kullanıcıya geri bildirim verin
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Item Uploaded"),
        ),
      );
    } catch (error) {
      // Hataları işleyin ve kullanıcıya bildirin
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $error"),
        ),
      );
    } finally {
      setLoading(false);
    }
  }

  Future<void> editDIY(BuildContext context) async {
    final isValid = formKey.currentState!.validate();
    FocusScope.of(context).unfocus();

    if (pickedImage == null && imagePath == null) {
      // Handle image not selected error for DIY editing
      return;
    }

    if (isValid) {
      try {
        setLoading(true);

        // Upload the image to Firebase Storage if a new image is picked
        if (pickedImage != null) {
          final ref = FirebaseStorage.instance
              .ref()
              .child("diyImages")
              .child("${titleController.text}.jpg");
          await ref.putFile(File(pickedImage!.path));
          imagePath = await ref.getDownloadURL();
        }

        // Handle updating DIY data in Firebase or save as needed
        // Replace Firestore collection reference and field names with your DIY data structure
        // Example:
        await FirebaseFirestore.instance
            .collection("diyCollection")
            .doc(uuid) // Use this.uuid as the document ID
            .update({
          'title': titleController.text,
          'description': descriptionController.text,
          'imagePath': imagePath ?? '',
          'steps':
              stepTextControllers.map((controller) => controller.text).toList(),
        });

        // Clear the form
        clearForm();
      } catch (error) {
        // Handle errors specific to your DIY panel editing
      } finally {
        setLoading(false);
      }
    }
  }

  Future<List<DIYPanelClass>> fetchDIYs() async {
    try {
      final QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('diyCollection').get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return DIYPanelClass(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          imagePath: data['imagePath'] ?? '',
          steps:
              (data['steps'] as List?)?.map((e) => e.toString()).toList() ?? [],
          price: (data['price'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    } catch (error) {
      print('Error fetching DIYs: $error');
      return [];
    }
  }

  Future<void> deleteDIY(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('diyCollection')
          .doc(id)
          .delete();
      notifyListeners();
    } catch (error) {
      print('Error deleting DIY: $error');
      throw error; // Hata yönetimi için hatayı yeniden fırlatıyoruz
    }
  }
}
