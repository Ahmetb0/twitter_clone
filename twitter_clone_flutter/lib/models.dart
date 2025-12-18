class User {
  final int id;
  final String username;
  final String bio;
  bool isFollowing;

  User(
      {required this.id,
      required this.username,
      this.bio = '',
      this.isFollowing = false});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      bio: json['bio'] ?? '',
      isFollowing: json['is_following'] ?? false,
    );
  }
}

class Tweet {
  final int id;
  final int userId;
  final String username;
  final String content;
  final String date;
  int likeCount;
  bool isLiked;
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
    this.likeCount = 0,
    this.isLiked = false,
    this.commentCount = 0,
    this.isFollowing = false,
    this.retweetCount = 0,
    this.isRetweeted = false,
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
      likeCount: json['like_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      commentCount: json['comment_count'] ?? 0,
      isFollowing: json['is_following'] ?? false,
      retweetCount: json['retweet_count'] ?? 0,
      isRetweeted: json['is_retweeted'] ?? false,
      retweeterUsername: json['retweeter_username'],
      retweeterId: json['retweeter_id'],
    );
  }
}
