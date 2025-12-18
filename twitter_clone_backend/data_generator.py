import psycopg2
from faker import Faker
import random

# --- AYARLAR ---
DB_HOST = "localhost"
DB_NAME = "twitter_db"
DB_USER = "postgres"
DB_PASS = "PASSWORD"  

fake = Faker()

def connect_db():
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASS
        )
        return conn
    except Exception as e:
        print("Veritabanına bağlanırken hata oluştu:", e)
        return None

def generate_data():
    conn = connect_db()
    if not conn:
        return
    
    cur = conn.cursor()
    
    print("Veri üretimi başladı...")

    # 1. KULLANICILAR (USERS) - 15 Tane
    user_ids = []
    print("-> Kullanıcılar ekleniyor...")
    for _ in range(15):
        username = fake.user_name()
        email = fake.email()
        password = "password123"
        bio = fake.text(max_nb_chars=100)
        
        # Çakışmayı önlemek için try-except
        try:
            cur.execute(
                "INSERT INTO users (username, email, password, bio) VALUES (%s, %s, %s, %s) RETURNING user_id",
                (username, email, password, bio)
            )
            user_id = cur.fetchone()[0]
            user_ids.append(user_id)
        except:
            conn.rollback() 
            continue
        conn.commit()

    # 2. TWEETLER (TWEETS) 
    tweet_ids = []
    print("-> Tweetler ekleniyor...")
    for uid in user_ids:
        for _ in range(random.randint(1, 3)):
            content = fake.text(max_nb_chars=200)
            cur.execute(
                "INSERT INTO tweets (user_id, content) VALUES (%s, %s) RETURNING tweet_id",
                (uid, content)
            )
            tweet_ids.append(cur.fetchone()[0])
    conn.commit()

    # 3. TAKİPLEŞME (FOLLOWS) 
    print("-> Takipler oluşturuluyor...")
    for follower in user_ids:
       
        others = [u for u in user_ids if u != follower]
        targets = random.sample(others, k=min(len(others), 3))
        
        for target in targets:
            try:
                cur.execute(
                    "INSERT INTO follows (follower_id, followed_id) VALUES (%s, %s)",
                    (follower, target)
                )
            except:
                conn.rollback()
                continue
    conn.commit()

    # 4. BEĞENİLER (LIKES)
    print("-> Beğeniler atılıyor...")
    for _ in range(30): 
        uid = random.choice(user_ids)
        tid = random.choice(tweet_ids)
        try:
            cur.execute("INSERT INTO likes (user_id, tweet_id) VALUES (%s, %s)", (uid, tid))
        except:
            conn.rollback()
    conn.commit()
    
    # 5. YORUMLAR (COMMENTS)
    print("-> Yorumlar yapılıyor...")
    for _ in range(20):
        uid = random.choice(user_ids)
        tid = random.choice(tweet_ids)
        content = fake.sentence()
        cur.execute("INSERT INTO comments (user_id, tweet_id, content) VALUES (%s, %s, %s)", (uid, tid, content))
    conn.commit()

    # 6. RETWEETS
    print("-> Retweetler yapılıyor...")
    for _ in range(15):
        uid = random.choice(user_ids)
        tid = random.choice(tweet_ids)
        try:
            cur.execute("INSERT INTO retweets (user_id, tweet_id) VALUES (%s, %s)", (uid, tid))
        except:
            conn.rollback()
    conn.commit()

    print("İşlem tamamlandı! Veritabanın doldu.")
    cur.close()
    conn.close()

if __name__ == "__main__":
    generate_data()