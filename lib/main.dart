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
                hintStyle: TextStyle(color: Colors.grey[400]), // Change the hint text color here
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[400]),
                  onPressed: () {
                    _searchController.clear();
                    _searchFocusNode.unfocus(); // Optional: removes focus
                    // Notify any listeners of changes, if needed
                  },
                )
                    : null,
              ),
              style: TextStyle(color: Colors.white),
              onChanged: (text) {
                // Update to show or hide the suffix icon based on text input
                (context as Element).markNeedsBuild();
              },
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
              itemCount: linksToDisplay.length + 1, // Add an extra item for padding
              itemBuilder: (context, index) {
                if (index == linksToDisplay.length) {
                  // Return padding as the last item
                  return SizedBox(height: 80); // Adjust height based on your FAB size
                }

                final link = linksToDisplay[index];

                return ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  visualDensity: VisualDensity.compact,
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
                      SizedBox(
                        width: 40,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () {
                            // Find the actual index in the main list
                            int actualIndex = linkProvider.links.indexOf(link);
                            _showEditLinkDialog(context, link, actualIndex);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () {
                            // Find the actual index in the main list
                            int actualIndex = linkProvider.links.indexOf(link);
                            final deletedLink = linkProvider.links[actualIndex];
                            linkProvider.deleteLink(actualIndex);

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

                  // Unfocus the search field and hide the keyboard
                  FocusScope.of(context).unfocus();

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
