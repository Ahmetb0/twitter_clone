class User {
  final int id;
  final String username;
  final String bio; // Bio eklemiştik
  bool
      isFollowing; // <--- YENİ: Takip ediyor muyum? (Değişebileceği için final değil)

  User(
      {required this.id,
      required this.username,
      this.bio = '',
      this.isFollowing = false // Varsayılan false
      });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      bio: json['bio'] ?? '',
      isFollowing:
          json['is_following'] ?? false, // Backend'den bu isimle gelecek
    );
  }
}

class Tweet {
  final int id;
  final int userId;
  final String username;
  final String content;
  final String date;

  // YENİ ALANLAR
  int likeCount; // Değişebilir (artıp azalacak)
  bool isLiked; // Değişebilir (kalp kırmızı olacak)
  int commentCount;
  bool isFollowing;
  int retweetCount;
  bool isRetweeted;
  String? retweeterUsername;
  int? retweeterId;

  Tweet({
    required this.id,
    required this.userId,
    required this.username,
    required this.content,
    required this.date,
    this.likeCount = 0, // Varsayılan 0
    this.isLiked = false, // Varsayılan false
    this.commentCount = 0, // Varsayılan 0
    this.isFollowing = false, // Varsayılan false
    this.retweetCount = 0, // Varsayılan 0
    this.isRetweeted = false, // Varsayılan false
    this.retweeterUsername,
    this.retweeterId,
  });

  factory Tweet.fromJson(Map<String, dynamic> json) {
    return Tweet(
      id: json['tweet_id'] ?? json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? 'Anonim',
      content: json['content'] ?? '',
      date: json['date'] ?? '',
      likeCount: json['like_count'] ?? 0, // Backend'den gelen
      isLiked: json['is_liked'] ?? false, // Backend'den gelen
      commentCount: json['comment_count'] ?? 0, // Backend'den gelen
      isFollowing: json['is_following'] ?? false, // Backend'den gelen
      retweetCount: json['retweet_count'] ?? 0, // Backend'den gelen
      isRetweeted: json['is_retweeted'] ?? false, // Backend'den gelen
      retweeterUsername: json['retweeter_username'],
      retweeterId: json['retweeter_id'],
    );
  }
}
