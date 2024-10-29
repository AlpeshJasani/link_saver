import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/link_provider.dart';
import 'models/link_model.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => LinkProvider())],
      child: LinkSaverApp(),
    ),
  );
}

class LinkSaverApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Link Saver',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.black,
        hintColor: Colors.purpleAccent,
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.deepPurpleAccent,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Colors.grey[800],
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.deepPurpleAccent),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
          ),
        ),
      ),
      home: LinkListScreen(),
    );
  }
}

class LinkListScreen extends StatefulWidget {
  @override
  _LinkListScreenState createState() => _LinkListScreenState();
}

class _LinkListScreenState extends State<LinkListScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<LinkModel> _filteredLinks = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterLinks);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _filterLinks() {
    final query = _searchController.text.toLowerCase();
    final linkProvider = Provider.of<LinkProvider>(context, listen: false);

    setState(() {
      _filteredLinks = linkProvider.links
          .where((link) =>
      link.title.toLowerCase().contains(query) ||
          link.url.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Link Saver'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search Links...',
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: Colors.white),
              onTap: () {
                _searchFocusNode.requestFocus();
              },
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.file_download),
            onPressed: () async {
              await Provider.of<LinkProvider>(context, listen: false).exportLinks();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Links exported successfully!')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.file_upload),
            onPressed: () async {
              await Provider.of<LinkProvider>(context, listen: false).importLinks();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Links imported successfully!')),
              );
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => _searchFocusNode.unfocus(),
        child: Consumer<LinkProvider>(
          builder: (context, linkProvider, child) {
            final linksToDisplay = _searchController.text.isEmpty
                ? linkProvider.links
                : _filteredLinks;

            return ListView.builder(
              itemCount: linksToDisplay.length,
              itemBuilder: (context, index) {
                final link = linksToDisplay[index];
                return ListTile(
                  title: Text(
                    link.title,
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    link.url,
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () {
                          _showEditLinkDialog(context, link, index);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () {
                          final deletedLink = linkProvider.links[index];
                          linkProvider.deleteLink(index);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Deleted ${deletedLink.title}'),
                              action: SnackBarAction(
                                label: 'Undo',
                                textColor: Colors.deepPurpleAccent,
                                onPressed: () {
                                  linkProvider.restoreLastDeletedLink();
                                },
                              ),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: link.url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Copied to clipboard!')),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLinkDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddLinkDialog(BuildContext context) {
    _titleController.clear();
    _urlController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Link', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.grey[900],
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title (optional)',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                ),
                style: TextStyle(color: Colors.white),
              ),
              TextField(
                controller: _urlController,
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
                if (_urlController.text.isNotEmpty) {
                  final title = _titleController.text.isEmpty
                      ? 'Link'
                      : _titleController.text;

                  Provider.of<LinkProvider>(context, listen: false).addLink(
                    LinkModel(
                      title: title,
                      url: _urlController.text,
                    ),
                  );

                  Navigator.of(context).pop();
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditLinkDialog(BuildContext context, LinkModel link, int index) {
    _titleController.text = link.title;
    _urlController.text = link.url;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Link', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.grey[900],
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title (optional)',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                ),
                style: TextStyle(color: Colors.white),
              ),
              TextField(
                controller: _urlController,
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
                if (_urlController.text.isNotEmpty) {
                  final title = _titleController.text.isEmpty
                      ? 'Link'
                      : _titleController.text;

                  final updatedLink = LinkModel(
                    title: title,
                    url: _urlController.text,
                  );

                  Provider.of<LinkProvider>(context, listen: false)
                      .updateLink(index, updatedLink);

                  Navigator.of(context).pop();
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
