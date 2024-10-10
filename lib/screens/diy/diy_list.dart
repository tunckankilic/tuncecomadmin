import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuncecomadmin/models/diy_panel.dart';
import 'package:tuncecomadmin/providers/diy_provider.dart';
import 'package:tuncecomadmin/screens/diy/diy_edit.dart';

class DIYListPage extends StatelessWidget {
  static const routeName = "/diy-list";

  const DIYListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DIY Recipes'),
        backgroundColor: Colors.teal,
      ),
      body: Consumer<DIYProvider>(
        builder: (ctx, diyProvider, child) {
          return FutureBuilder<List<DIYPanelClass>>(
            future: diyProvider.fetchDIYs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No DIY recipes found'));
              }

              final diyList = snapshot.data!;
              return ListView.builder(
                itemCount: diyList.length,
                itemBuilder: (ctx, index) {
                  final diy = diyList[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      leading: diy.imagePath.isNotEmpty
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(diy.imagePath))
                          : const CircleAvatar(child: Icon(Icons.image)),
                      title: Text(diy.title),
                      subtitle: Text(diy.description,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                _editDIY(context, diy, diyProvider),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteConfirmation(
                                context, diy, diyProvider),
                          ),
                        ],
                      ),
                      onTap: () => _showDIYDetails(context, diy),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.of(context).pushNamed(DIYEditPanel.routeName),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _editDIY(
      BuildContext context, DIYPanelClass diy, DIYProvider diyProvider) {
    diyProvider.titleController.text = diy.title;
    diyProvider.descriptionController.text = diy.description;
    diyProvider.imagePath = diy.imagePath;
    diyProvider.stepTextControllers =
        diy.steps.map((step) => TextEditingController(text: step)).toList();
    diyProvider.uuid = diy.id;
    diyProvider.isEditing = true;

    Navigator.of(context).pushNamed(DIYEditPanel.routeName);
  }

  void _showDeleteConfirmation(
      BuildContext context, DIYPanelClass diy, DIYProvider diyProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete DIY Recipe'),
        content: Text('Are you sure you want to delete "${diy.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Implement delete functionality in your DIYProvider
              // await diyProvider.deleteDIY(diy.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('DIY recipe deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDIYDetails(BuildContext context, DIYPanelClass diy) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(diy.title),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (diy.imagePath.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      diy.imagePath,
                      height: 200,
                      width: 300, // Sabit bir genişlik
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          width: 300,
                          color: Colors.grey[300],
                          child: Icon(Icons.error),
                        );
                      },
                    ),
                  ),
                SizedBox(height: 16),
                Text(diy.description),
                SizedBox(height: 16),
                Text('Steps:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...diy.steps.map((step) => Padding(
                      padding: EdgeInsets.only(left: 8.0, top: 4.0),
                      child: Text('• $step'),
                    )),
                SizedBox(height: 16),
                Text('Price: \$${diy.price.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
