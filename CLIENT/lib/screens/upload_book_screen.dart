import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;

import '../providers/book_provider.dart';

class UploadBookScreen extends StatefulWidget {
  const UploadBookScreen({Key? key}) : super(key: key);

  @override
  _UploadBookScreenState createState() => _UploadBookScreenState();
}

class _UploadBookScreenState extends State<UploadBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _publisherController = TextEditingController();
  final _typeController = TextEditingController();
  final _priceController = TextEditingController();

  PlatformFile? _bookFile;
  dynamic _coverImage; // 可以是 File (移动端) 或 XFile (Web)
  Uint8List? _coverImageBytes;
  String? _coverImageName;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _publisherController.dispose();
    _typeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickBook() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _bookFile = result.files.first;
          if (_titleController.text.isEmpty) {
            _titleController.text = _bookFile!.name.replaceAll('.txt', '');
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('选择文件失败: $e');
    }
  }

  Future<void> _pickCoverImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _coverImage = pickedFile;
          _coverImageBytes = bytes;
          _coverImageName = pickedFile.name;
        });
      }
    } catch (e) {
      _showErrorSnackBar('选择图片失败: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildCoverPreview() {
    if (_coverImageBytes == null) return const SizedBox.shrink();

    return Image.memory(
      _coverImageBytes!,
      height: 150,
      width: 100,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.broken_image, size: 100);
      },
    );
  }

  Future<void> _uploadBook() async {
    if (!_formKey.currentState!.validate()) return;
    if (_bookFile == null) {
      _showErrorSnackBar('请选择电子书文件');
      return;
    }

    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    try {
      await bookProvider.uploadBook(
        title: _titleController.text,
        author: _authorController.text,
        publisher: _publisherController.text,
        type: _typeController.text,
        price: double.tryParse(_priceController.text) ?? 0,
        bookFile: _bookFile!,
        coverImageBytes: _coverImageBytes,
        coverImageName: _coverImageName,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('上传成功')),
      );
      Navigator.pop(context);
    } catch (e) {
      _showErrorSnackBar('上传失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('上传电子书')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: '书名*'),
                validator: (value) => value?.isEmpty ?? true ? '请输入书名' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(labelText: '作者'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _publisherController,
                decoration: const InputDecoration(labelText: '出版社'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: '类型'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: '价格'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _pickBook,
                child: const Text('选择电子书文件 (.txt)'),
              ),
              if (_bookFile != null) ...[
                const SizedBox(height: 8),
                Text('已选择: ${_bookFile!.name}'),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _pickCoverImage,
                child: const Text('选择封面图片'),
              ),
              if (_coverImageBytes != null) ...[
                const SizedBox(height: 16),
                const Text('封面预览:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Center(child: _buildCoverPreview()),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _uploadBook,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('上传电子书', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}