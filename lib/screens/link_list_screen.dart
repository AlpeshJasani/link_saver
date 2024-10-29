import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/link_model.dart';
import '../providers/link_provider.dart';
import '../widgets/link_dialog.dart';
import '../widgets/search_field.dart';

class LinkListScreen extends StatefulWidget {
  @override
  _LinkListScreenState createState() => _LinkListScreenState();
}

class _LinkListScreenState extends State<LinkListScreen> {
  List<LinkModel> _filteredLinks = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterLinks);
  }

  void _filterLinks() {
    final query = _searchController.text.toLowerCase();
    final linkProvider = Provider.of<LinkProvider>(context, listen: false);

    setState(() {
      _filteredLinks = linkProvider.links.where((link) {
        return link.title.toLowerCase().contains(query) ||
            link.url.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // If the search field is focused or not empty, clear the search
        if (_searchFocusNode.hasFocus || _searchController.text.isNotEmpty) {
          _searchController.clear();
          _searchFocusNode.unfocus();
          return false; // Prevents the default back navigation
        }
        return true; // Allows normal back navigation
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Link Saver'),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(50.0), // Set height as needed
            child: SearchField(
              controller: _searchController,
              focusNode: _searchFocusNode,
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

              return ListView.separated(
                itemCount: linksToDisplay.length + 1, // One additional item for padding
                separatorBuilder: (context, index) => Divider(
                  thickness: 0.8, // Adjust thickness of the divider
                  color: Colors.grey[900], // Change the color to match your theme
                  height: 1, // Height of the divider space
                ),
                itemBuilder: (context, index) {
                  if (index == linksToDisplay.length) {
                    return SizedBox(height: 80); // Padding at the end
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
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () {
                            int actualIndex = linkProvider.links.indexOf(link);
                            _showEditLinkDialog(context, link, actualIndex);
                          },
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () {
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
      ),
    );
  }

  void _showAddLinkDialog(BuildContext context) {
    final titleController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return LinkDialog(
          titleController: titleController,
          urlController: urlController,
          onSubmit: (title, url) {
            if (url.isNotEmpty) {
              Provider.of<LinkProvider>(context, listen: false).addLink(
                LinkModel(title: title.isEmpty ? 'Link' : title, url: url),
              );
              FocusScope.of(context).unfocus();
              Navigator.of(context).pop();
            }
          },
        );
      },
    );
  }

  void _showEditLinkDialog(BuildContext context, LinkModel link, int index) {
    final titleController = TextEditingController(text: link.title);
    final urlController = TextEditingController(text: link.url);

    showDialog(
      context: context,
      builder: (context) {
        return LinkDialog(
          titleController: titleController,
          urlController: urlController,
          onSubmit: (title, url) {
            if (url.isNotEmpty) {
              final updatedLink = LinkModel(
                title: title.isEmpty ? 'Link' : title,
                url: url,
              );
              Provider.of<LinkProvider>(context, listen: false)
                  .updateLink(index, updatedLink);
              Navigator.of(context).pop();
            }
          },
        );
      },
    );
  }
}
