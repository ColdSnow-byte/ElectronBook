from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from flask.views import MethodView
from werkzeug.utils import secure_filename
import os
from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash

from extension import db
from model import Book, User

app = Flask(__name__)
CORS(app)  # 修改为直接初始化CORS
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///books.sqlite'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['UPLOAD_FOLDER'] = 'uploads'
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max upload size

# 确保上传目录存在
os.makedirs(os.path.join(app.config['UPLOAD_FOLDER'], 'covers'), exist_ok=True)
os.makedirs(os.path.join(app.config['UPLOAD_FOLDER'], 'books'), exist_ok=True)

db.init_app(app)

@app.cli.command()
def create():
    """Initialize the database."""
    db.drop_all()
    db.create_all()
    # 初始化测试用户
    test_user = User(username='test', password_hash=generate_password_hash('test123'))
    db.session.add(test_user)
    db.session.commit()
    Book.init_db()

class UserApi(MethodView):
    def post(self):
        """User registration endpoint."""
        data = request.get_json()
        if not data:
            return {'status': 'fail', 'message': 'Invalid JSON'}, 400
            
        username = data.get('username')
        password = data.get('password')
        
        if not username or not password:
            return {'status': 'fail', 'message': '用户名和密码不能为空'}, 400
            
        if User.query.filter_by(username=username).first():
            return {'status': 'fail', 'message': '用户名已存在'}, 400
            
        user = User(username=username)
        user.set_password(password)
        db.session.add(user)
        db.session.commit()
        
        return {
            'status': 'success',
            'message': '用户注册成功',
            'user': {
                'id': user.id,
                'username': user.username
            }
        }

class AuthApi(MethodView):
    def post(self):
        """User login endpoint."""
        data = request.get_json()
        if not data:
            return {'status': 'fail', 'message': 'Invalid JSON'}, 400
            
        username = data.get('username')
        password = data.get('password')
        
        user = User.query.filter_by(username=username).first()
        
        if not user or not user.check_password(password):
            return {'status': 'fail', 'message': '用户名或密码错误'}, 401
            
        return {
            'status': 'success',
            'message': '登录成功',
            'user': {
                'id': user.id,
                'username': user.username
            }
        }

class BookApi(MethodView):
    def get(self, book_id=None):
        """Get book(s) endpoint."""
        user_id = request.args.get('user_id')
        
        if not book_id:
            # 获取所有书籍或特定用户的书籍
            if user_id:
                books = Book.query.filter_by(user_id=user_id).all()
            else:
                books = Book.query.all()
                
            results = [
                {
                    'id': book.id,
                    'title': book.title,
                    'book_name': book.book_name,
                    'book_type': book.book_type,
                    'book_prize': book.book_prize,
                    'book_number': book.book_number,
                    'book_publisher': book.book_publisher,
                    'author': book.author,
                    'cover_image': f"/uploads/{book.cover_image}" if book.cover_image else None,
                    'upload_time': book.upload_time.isoformat() if book.upload_time else None
                } for book in books
            ]
            return {
                'status': 'success',
                'message': '数据查询成功',
                'results': results
            }
            
        book = Book.query.get(book_id)
        if not book:
            return {'status': 'fail', 'message': '书籍不存在'}, 404
            
        return {
            'status': 'success',
            'message': '数据查询成功',
            'result': {
                'id': book.id,
                'title': book.title,
                'book_name': book.book_name,
                'book_type': book.book_type,
                'book_prize': book.book_prize,
                'book_number': book.book_number,
                'book_publisher': book.book_publisher,
                'author': book.author,
                'cover_image': f"/uploads/{book.cover_image}" if book.cover_image else None,
                'file_path': f"/uploads/{book.file_path}",
                'upload_time': book.upload_time.isoformat() if book.upload_time else None
            }
        }

    def post(self):
        """Upload book endpoint."""
        try:
            # 检查文件是否存在
            if 'file' not in request.files:
                return {'status': 'fail', 'message': '未上传文件'}, 400
                
            file = request.files['file']
            if file.filename == '':
                return {'status': 'fail', 'message': '未选择文件'}, 400
                
            if not file.filename.lower().endswith('.txt'):
                return {'status': 'fail', 'message': '只支持txt格式文件'}, 400
                
            # 处理封面图片
            cover_image = request.files.get('cover_image')
            cover_filename = None
            if cover_image and cover_image.filename != '':
                cover_filename = f"covers/{secure_filename(cover_image.filename)}"
                cover_image.save(os.path.join(app.config['UPLOAD_FOLDER'], cover_filename))
                
            # 保存电子书文件
            filename = f"books/{secure_filename(file.filename)}"
            file.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))
            
            # 创建书籍记录
            book = Book()
            book.user_id = request.form.get('user_id', type=int)
            book.title = request.form.get('title', file.filename)
            book.book_number = request.form.get('book_number', '')
            book.book_name = request.form.get('book_name', '')
            book.book_type = request.form.get('book_type', '其他')
            book.book_prize = request.form.get('book_prize', 0, type=float)
            book.author = request.form.get('author', '未知')
            book.book_publisher = request.form.get('book_publisher', '')
            book.cover_image = cover_filename
            book.file_path = filename
            
            db.session.add(book)
            db.session.commit()
            
            return {
                'status': 'success',
                'message': '书籍上传成功',
                'book_id': book.id
            }
        except Exception as e:
            db.session.rollback()
            app.logger.error(f'上传失败: {str(e)}')
            return {'status': 'error', 'message': f'服务器错误: {str(e)}'}, 500

    def delete(self, book_id):
        """Delete book endpoint."""
        try:
            book = Book.query.get(book_id)
            if not book:
                return {'status': 'fail', 'message': '书籍不存在'}, 404
                
            # 删除文件
            try:
                if book.file_path:
                    os.remove(os.path.join(app.config['UPLOAD_FOLDER'], book.file_path))
                if book.cover_image:
                    os.remove(os.path.join(app.config['UPLOAD_FOLDER'], book.cover_image))
            except Exception as e:
                app.logger.warning(f'删除文件失败: {str(e)}')
                
            db.session.delete(book)
            db.session.commit()
            
            return {
                'status': 'success',
                'message': '书籍删除成功'
            }
        except Exception as e:
            db.session.rollback()
            app.logger.error(f'删除失败: {str(e)}')
            return {'status': 'error', 'message': f'服务器错误: {str(e)}'}, 500

class BookContentApi(MethodView):
    def get(self, book_id):
        """Get book content endpoint."""
        try:
            book = Book.query.get(book_id)
            if not book:
                return {'status': 'fail', 'message': '书籍不存在'}, 404
                
            file_path = os.path.join(app.config['UPLOAD_FOLDER'], book.file_path)
            if not os.path.exists(file_path):
                return {'status': 'fail', 'message': '文件不存在'}, 404
                
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                
            return {
                'status': 'success',
                'message': '获取内容成功',
                'content': content
            }
        except Exception as e:
            app.logger.error(f'读取内容失败: {str(e)}')
            return {'status': 'fail', 'message': f'读取文件失败: {str(e)}'}, 500

@app.route('/uploads/<path:filename>')
def uploaded_file(filename):
    """Serve uploaded files."""
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

# 注册路由 - 修正路由配置
user_view = UserApi.as_view('user_api')
auth_view = AuthApi.as_view('auth_api')
book_view = BookApi.as_view('book_api')
content_view = BookContentApi.as_view('content_api')

# 明确分开不同路由
app.add_url_rule('/api/users', view_func=user_view, methods=['POST'])
app.add_url_rule('/api/auth', view_func=auth_view, methods=['POST'])
app.add_url_rule('/api/books', view_func=book_view, methods=['GET', 'POST'])  # 不带book_id
app.add_url_rule('/api/books/<int:book_id>', view_func=book_view, methods=['GET', 'DELETE'])  # 带book_id
app.add_url_rule('/api/books/<int:book_id>/content', view_func=content_view, methods=['GET'])

@app.route('/')
def hello_world():
    return 'Welcome to E-Book Reader!'

if __name__ == '__main__':
    app.run(debug=True)