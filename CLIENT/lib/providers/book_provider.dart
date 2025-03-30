import 'dart:io';
import 'dart:core';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class BookProvider with ChangeNotifier {
  List<Map<String, dynamic>> _books = [];
  bool _isLoading = false;
  String? _error;
  int? _currentBookId;
  String? _currentBookContent;
  int _currentPage = 0;
  List<String> _pages = [];

  List<Map<String, dynamic>> get books => _books;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get currentBookId => _currentBookId;
  String? get currentBookContent => _currentBookContent;
  int get currentPage => _currentPage;
  List<String> get pages => _pages;

  Future<void> fetchBooks({int? userId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uri = userId != null
          ? Uri.parse('m,.>V?user_id=$userId')
          : Uri.parse('http://localhost:5000/api/books');

      final response = await http.get(uri);
      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        _books = List<Map<String, dynamic>>.from(responseData['results'])
          ..forEach((book) {
            if (book['cover_image'] != null && !book['cover_image'].startsWith('http')) {
              book['cover_image'] = 'http://localhost:5000${book['cover_image']}';
            }
          });
        _error = null;
      } else {
        _error = responseData['message'] ?? '获取书籍列表失败';
      }
    } catch (err) {
      _error = '连接服务器失败: $err';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getBookContent(int bookId) async {
    _isLoading = true;
    _currentBookId = bookId;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/books/$bookId/content'),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        _currentBookContent = responseData['content'];
        _error = null;

        _pages = [];
        for (int i = 0; i < _currentBookContent!.length; i += 1000) {
          int end = i + 1000;
          if (end > _currentBookContent!.length) end = _currentBookContent!.length;
          _pages.add(_currentBookContent!.substring(i, end));
        }
        _currentPage = 0;
      } else {
        _error = responseData['message'] ?? '获取书籍内容失败';
      }
    } catch (err) {
      _error = '连接服务器失败: $err';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadBook({
    required String title,
    required String author,
    required String publisher,
    required String type,
    required double price,
    required PlatformFile bookFile,
    Uint8List? coverImageBytes,
    String? coverImageName,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      if (userId == null) throw Exception('用户未登录');

      // 在Flutter的Dio配置中
      final dio =Dio()
;      final formData = FormData();

      // 添加文本字段
      formData.fields.addAll([
        MapEntry('user_id', userId.toString()),
        MapEntry('title', title),
        MapEntry('book_name', title),
        MapEntry('author', author),
        MapEntry('book_publisher', publisher),
        MapEntry('book_type', type),
        MapEntry('book_prize', price.toString()),
        MapEntry('book_number', 'UPL${DateTime.now().millisecondsSinceEpoch}'),
      ]);

      // 添加电子书文件
      Uint8List bookBytes;
      if (kIsWeb) {
        bookBytes = bookFile.bytes!;
      } else {
        bookBytes = await File(bookFile.path!).readAsBytes();
      }

      formData.files.add(MapEntry(
        'file',
        MultipartFile.fromBytes(
          bookBytes,
          filename: bookFile.name,
        ),
      ));

      // 添加封面图片
      if (coverImageBytes != null && coverImageBytes.isNotEmpty) {
        formData.files.add(MapEntry(
          'cover_image',
          MultipartFile.fromBytes(
            coverImageBytes,
            filename: coverImageName ?? 'cover.jpg',
          ),
        ));
      }

      final response = await dio.post(
        'http://localhost:5000/api/books',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {'Accept': 'application/json'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchBooks(userId: userId);
        _error = null;
      } else {
        throw Exception(response.data['message'] ?? '上传失败');
      }
    } catch (err) {
      _error = err.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void nextPage() {
    if (_currentPage < _pages.length - 1) {
      _currentPage++;
      notifyListeners();
    }
  }

  void previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      notifyListeners();
    }
  }

  Future<void> deleteBook(int bookId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      if (userId == null) throw Exception('用户未登录');

      final response = await http.delete(
        Uri.parse('http://localhost:5000/api/books/$bookId'),
      );

      if (response.statusCode == 200) {
        await fetchBooks(userId: userId);
        _error = null;
      } else {
        final responseData = json.decode(response.body);
        throw Exception(responseData['message'] ?? '删除失败');
      }
    } catch (err) {
      _error = err.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearContent() {
    _currentBookContent = null;
    _currentBookId = null;
    _pages = [];
    _currentPage = 0;
    notifyListeners();
  }
}