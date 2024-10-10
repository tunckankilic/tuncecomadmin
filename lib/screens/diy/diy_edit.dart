import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuncecomadmin/providers/diy_provider.dart';
import 'package:tuncecomadmin/screens/loading_manager.dart';

class DIYEditPanel extends StatelessWidget {
  static const routeName = "/diy-edit";

  const DIYEditPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final diyProvider = Provider.of<DIYProvider>(context);

    return LoadingManager(
      isLoading: diyProvider.isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              diyProvider.isEditing ? 'Edit DIY Recipe' : 'Create DIY Recipe'),
          backgroundColor: Colors.teal,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: diyProvider.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: diyProvider.descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildImagePicker(context, diyProvider),
                const SizedBox(height: 16),
                Text('Steps', style: Theme.of(context).textTheme.titleLarge),
                ..._buildStepFields(diyProvider),
                ElevatedButton(
                  onPressed: () => diyProvider.addTextField(),
                  child: const Text('Add Step'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _submitForm(context, diyProvider),
                  child: Text(diyProvider.isEditing
                      ? 'Update Recipe'
                      : 'Create Recipe'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(BuildContext context, DIYProvider diyProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recipe Image', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (diyProvider.pickedImage != null)
          Image.file(
            File(diyProvider.pickedImage!.path),
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          )
        else if (diyProvider.imagePath != null &&
            diyProvider.imagePath!.isNotEmpty)
          Image.network(
            diyProvider.imagePath!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          )
        else
          Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[300],
            child: const Icon(Icons.add_photo_alternate, size: 50),
          ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => diyProvider.localImagePicker(context: context),
          child: const Text('Pick Image'),
        ),
      ],
    );
  }

  List<Widget> _buildStepFields(DIYProvider diyProvider) {
    return List.generate(
      diyProvider.stepTextControllers.length,
      (index) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: diyProvider.stepTextControllers[index],
                decoration: InputDecoration(labelText: 'Step ${index + 1}'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a step';
                  }
                  return null;
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => diyProvider.removeTextField(index),
            ),
          ],
        ),
      ),
    );
  }

  void _submitForm(BuildContext context, DIYProvider diyProvider) async {
    if (diyProvider.formKey.currentState!.validate()) {
      try {
        if (diyProvider.isEditing) {
          await diyProvider.editDIY(context);
        } else {
          await diyProvider.uploadDIY(
            context,
            title: diyProvider.titleController.text,
            description: diyProvider.descriptionController.text,
            steps: diyProvider.stepTextControllers
                .map((controller) => controller.text)
                .toList(),
            imageFile: diyProvider.pickedImage != null
                ? File(diyProvider.pickedImage!.path)
                : File(''),
          );
        }
        Navigator.of(context).pop();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    }
  }
}
