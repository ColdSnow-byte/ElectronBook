# -*- coding: utf-8 -*-
from extension import db
from werkzeug.security import generate_password_hash, check_password_hash

class User(db.Model):
    __tablename__ = 'user'
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    password_hash = db.Column(db.String(128), nullable=False)
    
    def set_password(self, password):
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

class Book(db.Model):
    __tablename__ = 'book'
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    title = db.Column(db.String(255), nullable=False)
    book_number = db.Column(db.String(255), nullable=False)
    book_name = db.Column(db.String(255), nullable=False)
    book_type = db.Column(db.String(255), nullable=False)
    book_prize = db.Column(db.Float, nullable=False)
    author = db.Column(db.String(255))
    book_publisher = db.Column(db.String(255))
    cover_image = db.Column(db.String(255))  # 存储封面图片路径
    file_path = db.Column(db.String(255), nullable=False)  # 存储电子书文件路径
    upload_time = db.Column(db.DateTime, default=db.func.current_timestamp())

    @staticmethod
    def init_db():
        rets = [
            (1, 1, '活着', '001', '活着', '小说', 39.9, '余华', '某某出版社', 'covers/huozhe.jpg', 'books/huozhe.txt'),
            (2, 1, '三体', '002', '三体', '科幻', 99.8, '刘慈欣', '重庆出版社', 'covers/santi.jpg', 'books/santi.txt')
        ]
        for ret in rets:
            book = Book()
            book.id = ret[0]
            book.user_id = ret[1]
            book.title = ret[2]
            book.book_number = ret[3]
            book.book_name = ret[4]
            book.book_type = ret[5]
            book.book_prize = ret[6]
            book.author = ret[7]
            book.book_publisher = ret[8]
            book.cover_image = ret[9]
            book.file_path = ret[10]
            db.session.add(book)
        db.session.commit()