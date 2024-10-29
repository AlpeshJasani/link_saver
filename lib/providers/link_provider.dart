import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path; // for handling file paths
import '../models/link_model.dart';

class LinkProvider with ChangeNotifier {
  List<LinkModel> _links = [];
  LinkModel? _lastDeletedLink;
  int? _lastDeletedLinkIndex;

  List<LinkModel> get links => _links;

  LinkProvider() {
    loadLinks();
  }

  Future<void> loadLinks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? linkData = prefs.getString('links');
    if (linkData != null) {
      List jsonList = json.decode(linkData);
      _links = jsonList.map((json) => LinkModel.fromJson(json)).toList();
      notifyListeners();
    }
  }

  Future<void> saveLinks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String linkData = json.encode(_links.map((link) => link.toJson()).toList());
    await prefs.setString('links', linkData);
  }

  void addLink(LinkModel link) {
    // _links.add(link); // Insert at Last
    _links.insert(0, link);  // Insert the new link at the top (index 0)
    saveLinks();
    notifyListeners();
  }

  void updateLink(int index, LinkModel link) {
    _links[index] = link;
    saveLinks();
    notifyListeners();
  }

  void deleteLink(int index) {
    _lastDeletedLink = _links[index];
    _lastDeletedLinkIndex = index;
    _links.removeAt(index);
    saveLinks();
    notifyListeners();
  }

  void restoreLastDeletedLink() {
    if (_lastDeletedLink != null && _lastDeletedLinkIndex != null) {
      _links.insert(_lastDeletedLinkIndex!, _lastDeletedLink!);
      saveLinks();
      notifyListeners();
      _lastDeletedLink = null;
      _lastDeletedLinkIndex = null;
    }
  }

  // Export links to a chosen directory
  Future<void> exportLinks() async {
    // Use FilePicker to select the directory for export
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      // Define the file path in the selected directory
      final filePath = path.join(selectedDirectory, 'links_export.json');
      final linkData = json.encode(_links.map((link) => link.toJson()).toList());

      // Write the JSON data to the file
      final file = File(filePath);
      await file.writeAsString(linkData);

      print('Exported links to $filePath');
    } else {
      print('Export cancelled');
    }
  }

  // Import links from a JSON file
  Future<void> importLinks() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final linkData = await file.readAsString();
      List jsonList = json.decode(linkData);
      _links = jsonList.map((json) => LinkModel.fromJson(json)).toList();
      saveLinks();
      notifyListeners();
      print('Links imported from ${result.files.single.path}');
    } else {
      print('Import cancelled');
    }
  }
}
