import 'package:flutter/material.dart';

class LinkDialog extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController urlController;
  final void Function(String title, String url) onSubmit;

  LinkDialog({
    required this.titleController,
    required this.urlController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Link', style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.grey[900],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleController,
            decoration: InputDecoration(
              labelText: 'Title (optional)',
              labelStyle: TextStyle(color: Colors.grey[400]),
            ),
            style: TextStyle(color: Colors.white),
          ),
          TextField(
            controller: urlController,
            decoration: InputDecoration(
              labelText: 'URL',
              labelStyle: TextStyle(color: Colors.grey[400]),
            ),
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            onSubmit(titleController.text, urlController.text);
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}
