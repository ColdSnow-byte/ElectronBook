import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/book_provider.dart';
import './book_detail_screen.dart';
import './upload_book_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 获取书籍列表
    Future.microtask(() => Provider.of<BookProvider>(context, listen: false).fetchBooks());
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bookProvider = Provider.of<BookProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('电子书阅读器'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              authProvider.logout();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UploadBookScreen()),
          );
        },
        child: Icon(Icons.add),
      ),
      body: _buildBody(bookProvider),
    );
  }

  Widget _buildBody(BookProvider bookProvider) {
    if (bookProvider.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (bookProvider.error != null) {
      return Center(child: Text('错误: ${bookProvider.error}'));
    }

    return GridView.builder(
      padding: EdgeInsets.all(8.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 0.7,
      ),
      itemCount: bookProvider.books.length,
      itemBuilder: (context, index) {
        final book = bookProvider.books[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookDetailScreen(book: book),
              ),
            );
          },
          child: Card(
            child: Column(
              children: [
                Expanded(
                  child: _buildBookCover(book['cover_image']),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    book['title'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  book['author'] ?? '未知作者',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookCover(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Icon(Icons.book, size: 100);
    }

    // 确保URL是完整的
    String fullUrl = imageUrl;
    if (!imageUrl.startsWith('http')) {
      fullUrl = 'http://localhost:5000${imageUrl.startsWith('/') ? '' : '/'}$imageUrl';
    }

    return CachedNetworkImage(
      imageUrl: fullUrl,
      httpHeaders: {"Accept": "image/*"},
      placeholder: (context, url) => Container(
        alignment: Alignment.center,
        child: CircularProgressIndicator(),
      ),
      errorWidget: (context, url, error) {
        print('图片加载错误: $error, URL: $url');
        return Container(
          alignment: Alignment.center,
          child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
        );
      },
      fit: BoxFit.cover,
      width: double.infinity,
    );
  }
}