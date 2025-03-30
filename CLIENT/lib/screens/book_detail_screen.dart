import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/book_provider.dart';
import 'package:provider/provider.dart';

class BookDetailScreen extends StatefulWidget {
  final Map<String, dynamic> book;

  const BookDetailScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  @override
  void initState() {
    super.initState();
    // 加载书籍内容
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookProvider>(context, listen: false)
          .getBookContent(widget.book['id']);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book['title']),
      ),
      body: _buildContent(bookProvider),
    );
  }

  Widget _buildContent(BookProvider bookProvider) {
    if (bookProvider.isLoading && bookProvider.currentBookContent == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (bookProvider.error != null) {
      return Center(
        child: Text(
          '加载失败: ${bookProvider.error}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (bookProvider.currentBookContent == null) {
      return const Center(child: Text('暂无内容'));
    }

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: MarkdownBody(
                data: bookProvider.pages.isNotEmpty
                    ? bookProvider.pages[bookProvider.currentPage]
                    : '无内容',
              ),
            ),
          ),
        ),
        _buildPageControls(bookProvider),
      ],
    );
  }

  Widget _buildPageControls(BookProvider bookProvider) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: bookProvider.currentPage > 0
                ? () => bookProvider.previousPage()
                : null,
          ),
          Text(
            '${bookProvider.currentPage + 1}/${bookProvider.pages.length}',
            style: const TextStyle(fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: bookProvider.currentPage < bookProvider.pages.length - 1
                ? () => bookProvider.nextPage()
                : null,
          ),
        ],
      ),
    );
  }
}