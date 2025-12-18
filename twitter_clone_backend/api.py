from flask import Flask, jsonify, request
from flask_cors import CORS
import psycopg2

app = Flask(__name__)
CORS(app)  # Flutter'ın bu API'ye erişmesine izin ver


DB_HOST = "localhost"
DB_NAME = "twitter_db"
DB_USER = "postgres"
DB_PASS = "PASSWORD"  

def get_db_connection():
    conn = psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASS
    )
    return conn


@app.route('/', methods=['GET'])
def home():
    return jsonify({"message": "Twitter API Çalışıyor!"})


# TWEET ATMA
@app.route('/tweet', methods=['POST'])
def post_tweet():
    data = request.json
    user_id = data.get('user_id') 
    content = data.get('content')
    
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("INSERT INTO tweets (user_id, content) VALUES (%s, %s)", (user_id, content))
    conn.commit()
    cur.close()
    conn.close()
    
    return jsonify({"message": "Tweet başarıyla atıldı!"}), 201

@app.route('/user-tweets/<int:user_id>', methods=['GET'])
def get_user_tweets(user_id):
    conn = get_db_connection()
    cur = conn.cursor()
    
    
    query = """
        -- 1. KISIM: KULLANICININ KENDİ YAZDIĞI TWEETLER
        SELECT t.tweet_id, u.username, t.content, t.created_at, t.user_id,
        (SELECT COUNT(*) FROM likes WHERE tweet_id = t.tweet_id) AS like_count,
        (SELECT EXISTS(SELECT 1 FROM likes WHERE tweet_id = t.tweet_id AND user_id = %s)) AS is_liked,
        (SELECT COUNT(*) FROM comments WHERE tweet_id = t.tweet_id) AS comment_count,
        (SELECT COUNT(*) FROM retweets WHERE tweet_id = t.tweet_id) AS retweet_count,
        (SELECT EXISTS(SELECT 1 FROM retweets WHERE tweet_id = t.tweet_id AND user_id = %s)) AS is_retweeted,
        NULL AS retweeter_username,
        NULL AS retweeter_id -- <--- Kendi tweetinde RT id yok
        FROM tweets t
        JOIN users u ON t.user_id = u.user_id
        WHERE t.user_id = %s

        UNION

        -- 2. KISIM: KULLANICININ RETWEET YAPTIKLARI
        SELECT t.tweet_id, u.username, t.content, r.created_at, t.user_id,
        (SELECT COUNT(*) FROM likes WHERE tweet_id = t.tweet_id) AS like_count,
        (SELECT EXISTS(SELECT 1 FROM likes WHERE tweet_id = t.tweet_id AND user_id = %s)) AS is_liked,
        (SELECT COUNT(*) FROM comments WHERE tweet_id = t.tweet_id) AS comment_count,
        (SELECT COUNT(*) FROM retweets WHERE tweet_id = t.tweet_id) AS retweet_count,
        (SELECT EXISTS(SELECT 1 FROM retweets WHERE tweet_id = t.tweet_id AND user_id = %s)) AS is_retweeted,
        ru.username AS retweeter_username,
        ru.user_id AS retweeter_id -- <--- BURAYI EKLEDIK: RT yapanın ID'si
        FROM retweets r
        JOIN tweets t ON r.tweet_id = t.tweet_id
        JOIN users u ON t.user_id = u.user_id 
        JOIN users ru ON r.user_id = ru.user_id 
        WHERE r.user_id = %s

        ORDER BY created_at DESC
    """
    
    cur.execute(query, (user_id, user_id, user_id, user_id, user_id, user_id))
    rows = cur.fetchall()
    
    cur.close()
    conn.close()
    
    user_tweets = []
    for row in rows:
        user_tweets.append({
            "tweet_id": row[0],
            "username": row[1],
            "content": row[2],
            "date": str(row[3]),
            "user_id": row[4],
            "like_count": row[5],
            "is_liked": row[6],
            "comment_count": row[7],
            "retweet_count": row[8],
            "is_retweeted": row[9],
            "retweeter_username": row[10],
            "retweeter_id": row[11] 
        })
    return jsonify(user_tweets)


# GİRİŞ YAPMA 
@app.route('/login', methods=['POST'])
def login():
    data = request.json
    username = data.get('username')
    
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT user_id, username, bio FROM users WHERE username = %s", (username,))
    user = cur.fetchone()
    cur.close()
    conn.close()
    
    if user:
        return jsonify({"id": user[0], "username": user[1], "bio": user[2]})
    else:
        return jsonify({"error": "Kullanıcı bulunamadı"}), 404
    
@app.route('/register', methods=['POST'])
def register():
    data = request.json
    username = data.get('username')
    password = data.get('password')
    email = data.get('email')
 

    if not username or not password or not email:
        return jsonify({"error": "Eksik bilgi"}), 400
    
    conn = get_db_connection()

    try:
        cur = conn.cursor()
        # Kullanıcı var mı kontrol et
        cur.execute("SELECT * FROM users WHERE username = %s", (username,))
        if cur.fetchone():
            return jsonify({"error": "Bu kullanıcı adı zaten alınmış"}), 409

        # Yeni kullanıcıyı ekle
        cur.execute(
            "INSERT INTO users (username, password, email, bio) VALUES (%s, %s, %s, %s) RETURNING user_id",
            (username, password, email, 'Merhaba, ben yeni bir kullanıcıyım!')
        )
        new_user_id = cur.fetchone()[0]
        conn.commit()
        cur.close()

        return jsonify({"message": "Kayıt başarılı", "user_id": new_user_id}), 201

    except Exception as e:
        conn.rollback()
        print(f"Hata: {e}")
        return jsonify({"error": str(e)}), 500
    

@app.route('/feed/<int:user_id>', methods=['GET'])
def get_home_feed(user_id):
    conn = get_db_connection()
    cur = conn.cursor()
    
    query = """
        -- 1. KISIM: TAKİP ETTİKLERİMİN (VE BENİM) YAZDIĞI TWEETLER
        SELECT t.tweet_id, u.username, t.content, t.created_at,
        (SELECT COUNT(*) FROM likes WHERE tweet_id = t.tweet_id) AS like_count,
        (SELECT EXISTS(SELECT 1 FROM likes WHERE tweet_id = t.tweet_id AND user_id = %s)) AS is_liked,
        (SELECT COUNT(*) FROM comments WHERE tweet_id = t.tweet_id) AS comment_count,
        t.user_id, -- DİKKAT: user_id burada 8. sırada
        (SELECT COUNT(*) FROM retweets WHERE tweet_id = t.tweet_id) AS retweet_count,
        (SELECT EXISTS(SELECT 1 FROM retweets WHERE tweet_id = t.tweet_id AND user_id = %s)) AS is_retweeted,
        NULL AS retweeter_username, 
        NULL AS retweeter_id
        FROM tweets t
        JOIN users u ON t.user_id = u.user_id
        WHERE t.user_id IN (SELECT followed_id FROM follows WHERE follower_id = %s)
           OR t.user_id = %s

        UNION

        -- 2. KISIM: TAKİP ETTİKLERİMİN (VE BENİM) RETWEETLEDİĞİ TWEETLER
        SELECT t.tweet_id, u.username, t.content, r.created_at,
        (SELECT COUNT(*) FROM likes WHERE tweet_id = t.tweet_id) AS like_count,
        (SELECT EXISTS(SELECT 1 FROM likes WHERE tweet_id = t.tweet_id AND user_id = %s)) AS is_liked,
        (SELECT COUNT(*) FROM comments WHERE tweet_id = t.tweet_id) AS comment_count,
        t.user_id, -- DÜZELTME BURADA: user_id'yi yukarıdakiyle aynı sıraya (8. sıraya) aldık
        (SELECT COUNT(*) FROM retweets WHERE tweet_id = t.tweet_id) AS retweet_count,
        (SELECT EXISTS(SELECT 1 FROM retweets WHERE tweet_id = t.tweet_id AND user_id = %s)) AS is_retweeted,
        ru.username AS retweeter_username,
        ru.user_id AS retweeter_id
        FROM retweets r
        JOIN tweets t ON r.tweet_id = t.tweet_id
        JOIN users u ON t.user_id = u.user_id 
        JOIN users ru ON r.user_id = ru.user_id 
        WHERE r.user_id IN (SELECT followed_id FROM follows WHERE follower_id = %s)
           OR r.user_id = %s

        ORDER BY created_at DESC
    """
    

    params = (user_id, user_id, user_id, user_id, user_id, user_id, user_id, user_id)
    
    try:
        cur.execute(query, params)
        rows = cur.fetchall()
        cur.close()
        conn.close()
        
        tweets = []
        for row in rows:
            tweets.append({
                "tweet_id": row[0],
                "username": row[1],
                "content": row[2],
                "date": str(row[3]),
                "like_count": row[4],
                "is_liked": row[5],
                "comment_count": row[6],
                "user_id": row[7],
                "retweet_count": row[8],
                "is_retweeted": row[9],
                "retweeter_username": row[10],
                "retweeter_id": row[11]
            })
        return jsonify(tweets)
        
    except Exception as e:
        print(f"HATA: {e}") 
        if conn: conn.close()
        return jsonify({"error": str(e)}), 500

# 2. KEŞFET 
@app.route('/explore-feed/<int:user_id>', methods=['GET'])
def get_explore_feed(user_id):
    conn = get_db_connection()
    cur = conn.cursor()
    
    
    query = """
        SELECT t.tweet_id, u.username, t.content, t.created_at, u.user_id,
        (SELECT COUNT(*) FROM likes WHERE tweet_id = t.tweet_id) AS like_count,
        (SELECT EXISTS(SELECT 1 FROM likes WHERE tweet_id = t.tweet_id AND user_id = %s)) AS is_liked,
        (SELECT COUNT(*) FROM comments WHERE tweet_id = t.tweet_id) AS comment_count,
        (SELECT EXISTS(SELECT 1 FROM follows WHERE follower_id = %s AND followed_id = u.user_id)) AS is_following
        FROM tweets t
        JOIN users u ON t.user_id = u.user_id
        ORDER BY t.created_at DESC
    """
    
    cur.execute(query, (user_id, user_id))
    rows = cur.fetchall()
    cur.close()
    conn.close()
    
    tweets = []
    for row in rows:
        tweets.append({
            "tweet_id": row[0],
            "username": row[1],
            "content": row[2],
            "date": str(row[3]),
            "user_id": row[4],   
            "like_count": row[5],
            "is_liked": row[6],
            "comment_count": row[7],
            "is_following": row[8] 
        })
    return jsonify(tweets)


@app.route('/follow', methods=['POST'])
def follow_user():
    data = request.json
    follower_id = data.get('follower_id')   
    followed_id = data.get('following_id') 
    
    if follower_id == followed_id:
         return jsonify({"error": "Kendini takip edemezsin"}), 400

    conn = get_db_connection()
    cur = conn.cursor()
    
    try:
     
        cur.execute("SELECT * FROM follows WHERE follower_id = %s AND followed_id = %s", (follower_id, followed_id))
        if cur.fetchone():
          
            return jsonify({"message": "Zaten takip ediyorsun"}), 200

       
        cur.execute("INSERT INTO follows (follower_id, followed_id) VALUES (%s, %s)", (follower_id, followed_id))
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({"message": "Takip edildi"}), 201
        
    except Exception as e:
        if conn: conn.rollback()
        return jsonify({"error": str(e)}), 500
    

@app.route('/unfollow', methods=['POST'])
def unfollow_user():
    data = request.json
    follower_id = data.get('follower_id')
    followed_id = data.get('following_id') 
    
    conn = get_db_connection()
    cur = conn.cursor()
    
    try:
       
        cur.execute("DELETE FROM follows WHERE follower_id = %s AND followed_id = %s", (follower_id, followed_id))
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({"message": "Takipten çıkıldı"}), 200
        
    except Exception as e:
        if conn: conn.rollback()
        return jsonify({"error": str(e)}), 500    
    
@app.route('/search', methods=['GET'])
def search_users():
    query = request.args.get('q', '')
    current_user_id = request.args.get('user_id') 

    if not query or len(query) < 1:
        return jsonify([])

    conn = get_db_connection()
    cur = conn.cursor()
    
  
    sql = """
        SELECT u.user_id, u.username, u.bio,
        CASE WHEN f.follower_id IS NOT NULL THEN TRUE ELSE FALSE END AS is_following
        FROM users u
        LEFT JOIN follows f ON u.user_id = f.followed_id AND f.follower_id = %s
        WHERE u.username ILIKE %s
    """
    
    cur.execute(sql, (current_user_id, '%' + query + '%'))
    rows = cur.fetchall()
    cur.close()
    conn.close()
    
    results = []
    for row in rows:
        results.append({
            "id": row[0],
            "username": row[1],
            "bio": row[2],
            "is_following": row[3]
        })
        
    return jsonify(results)


    
@app.route('/tweet/<int:tweet_id>', methods=['DELETE'])
def delete_tweet(tweet_id):

    user_id = request.args.get('user_id')

    if not user_id:
        return jsonify({"error": "User ID gerekli"}), 400

    conn = get_db_connection()
    cur = conn.cursor()

    try:
       
        cur.execute("SELECT * FROM tweets WHERE tweet_id = %s AND user_id = %s", (tweet_id, user_id))
        tweet = cur.fetchone()

        if not tweet:
            cur.close()
            conn.close()
            return jsonify({"error": "Tweet bulunamadı veya silme yetkiniz yok"}), 404

       
        cur.execute("DELETE FROM tweets WHERE tweet_id = %s", (tweet_id,))
        conn.commit()
        
        cur.close()
        conn.close()
        return jsonify({"message": "Tweet silindi"}), 200

    except Exception as e:
        if conn:
            conn.rollback()
            conn.close()
        return jsonify({"error": str(e)}), 500    
    
@app.route('/toggle-like', methods=['POST'])
def toggle_like():
    data = request.json
    user_id = data.get('user_id')
    tweet_id = data.get('tweet_id')
    
    conn = get_db_connection()
    cur = conn.cursor()
    
    try:
       
        cur.execute("SELECT * FROM likes WHERE user_id = %s AND tweet_id = %s", (user_id, tweet_id))
        if cur.fetchone():
          
            cur.execute("DELETE FROM likes WHERE user_id = %s AND tweet_id = %s", (user_id, tweet_id))
            message = "Beğeni geri alındı"
            liked = False
        else:
          
            cur.execute("INSERT INTO likes (user_id, tweet_id) VALUES (%s, %s)", (user_id, tweet_id))
            message = "Beğenildi"
            liked = True
            
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({"message": message, "is_liked": liked}), 200
        
    except Exception as e:
        if conn: conn.rollback()
        return jsonify({"error": str(e)}), 500    
    


@app.route('/comments/<int:tweet_id>', methods=['GET'])
def get_comments(tweet_id):
    conn = get_db_connection()
    cur = conn.cursor()
    
   
    query = """
        SELECT c.content, u.username, c.user_id 
        FROM comments c
        JOIN users u ON c.user_id = u.user_id
        WHERE c.tweet_id = %s
        ORDER BY c.created_at ASC
    """
    cur.execute(query, (tweet_id,))
    rows = cur.fetchall()
    cur.close()
    conn.close()
    
    comments = []
    for row in rows:
        comments.append({
            "content": row[0],
            "username": row[1],
            "user_id": row[2] 
        })
    return jsonify(comments)


@app.route('/comment', methods=['POST'])
def post_comment():
    data = request.json
    user_id = data.get('user_id')
    tweet_id = data.get('tweet_id')
    content = data.get('content')
    
    if not content:
        return jsonify({"error": "Yorum boş olamaz"}), 400

    conn = get_db_connection()
    cur = conn.cursor()
    
    try:
        cur.execute("INSERT INTO comments (user_id, tweet_id, content) VALUES (%s, %s, %s)", 
                    (user_id, tweet_id, content))
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({"message": "Yorum yapıldı"}), 201
    except Exception as e:
        if conn: conn.rollback()
        return jsonify({"error": str(e)}), 500    
    
@app.route('/update-profile', methods=['PUT'])
def update_profile():
    data = request.json
    user_id = data.get('user_id')
    bio = data.get('bio')
    
    conn = get_db_connection()
    cur = conn.cursor()
    
    try:
        cur.execute("UPDATE users SET bio = %s WHERE user_id = %s", (bio, user_id))
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({"message": "Profil güncellendi"}), 200
    except Exception as e:
        if conn: conn.rollback()
        return jsonify({"error": str(e)}), 500    
    
@app.route('/user-summary', methods=['GET'])
def get_user_summary():
    target_id = request.args.get('target_id')   
    current_id = request.args.get('current_id') 
    
    conn = get_db_connection()
    cur = conn.cursor()
    
    try:
        
        cur.execute("SELECT username, bio FROM users WHERE user_id = %s", (target_id,))
        user_row = cur.fetchone()
        
        if not user_row:
            return jsonify({"error": "Kullanıcı bulunamadı"}), 404
            
        username = user_row[0]
        bio = user_row[1]
        
      
        cur.execute("SELECT COUNT(*) FROM follows WHERE followed_id = %s", (target_id,))
        followers_count = cur.fetchone()[0]
        
     
        cur.execute("SELECT COUNT(*) FROM follows WHERE follower_id = %s", (target_id,))
        following_count = cur.fetchone()[0]
        
    
        is_following = False
        if current_id:
            cur.execute("SELECT * FROM follows WHERE follower_id = %s AND followed_id = %s", (current_id, target_id))
            if cur.fetchone():
                is_following = True

        cur.close()
        conn.close()
        
        return jsonify({
            "username": username,
            "bio": bio,
            "followers": followers_count,
            "following": following_count,
            "is_following": is_following
        }), 200

    except Exception as e:
        if conn: conn.rollback()
        return jsonify({"error": str(e)}), 500    

@app.route('/retweet', methods=['POST'])
def toggle_retweet():
    data = request.json
    user_id = data.get('user_id')
    tweet_id = data.get('tweet_id')
    
    conn = get_db_connection()
    cur = conn.cursor()
    
    try:
        
        cur.execute("SELECT * FROM retweets WHERE user_id = %s AND tweet_id = %s", (user_id, tweet_id))
        if cur.fetchone():
           
            cur.execute("DELETE FROM retweets WHERE user_id = %s AND tweet_id = %s", (user_id, tweet_id))
            is_retweeted = False
            message = "Retweet geri alındı"
        else:
          
            cur.execute("INSERT INTO retweets (user_id, tweet_id) VALUES (%s, %s)", (user_id, tweet_id))
            is_retweeted = True
            message = "Retweetlendi"
            
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({"message": message, "is_retweeted": is_retweeted}), 200
        
    except Exception as e:
        if conn: conn.rollback()
        return jsonify({"error": str(e)}), 500
    
@app.route('/users/<int:user_id>/<string:list_type>', methods=['GET'])
def get_follow_list(user_id, list_type):
    conn = get_db_connection()
    cur = conn.cursor()
    
    if list_type == 'followers':
        
        query = """
            SELECT u.user_id, u.username, u.bio 
            FROM users u
            JOIN follows f ON u.user_id = f.follower_id
            WHERE f.followed_id = %s
        """
    elif list_type == 'following':
       
        query = """
            SELECT u.user_id, u.username, u.bio 
            FROM users u
            JOIN follows f ON u.user_id = f.followed_id
            WHERE f.follower_id = %s
        """
    else:
        return jsonify({"error": "Geçersiz tip"}), 400

    cur.execute(query, (user_id,))
    rows = cur.fetchall()
    cur.close()
    conn.close()
    
    users = []
    for row in rows:
        users.append({
            "id": row[0],
            "username": row[1],
            "bio": row[2]
        })
    return jsonify(users)    

if __name__ == '__main__':
  
    app.run(debug=True, host='0.0.0.0', port=5032)