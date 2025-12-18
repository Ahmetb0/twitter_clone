import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../models.dart';
import 'api_helper.dart';
import 'auth_controller.dart';

class OtherProfileController extends GetxController {
  var isLoading = true.obs;
  var userTweets = <Tweet>[].obs;

  // Profil Bilgileri
  var username = ''.obs;
  var bio = ''.obs;
  var followersCount = 0.obs;
  var followingCount = 0.obs;
  var isFollowing = false.obs;

  final AuthController _authController = Get.find();

  Future<void> loadProfile(int targetUserId) async {
    isLoading.value = true;
    final myId = _authController.currentUser.value?.id;

    try {
      final responseInfo = await http.get(Uri.parse(
          '${ApiHelper.baseUrl}/user-summary?target_id=$targetUserId&current_id=$myId'));

      if (responseInfo.statusCode == 200) {
        final data = jsonDecode(responseInfo.body);
        username.value = data['username'];
        bio.value = data['bio'] ?? '';
        followersCount.value = data['followers'];
        followingCount.value = data['following'];
        isFollowing.value = data['is_following'];
      }

      final responseTweets = await http
          .get(Uri.parse('${ApiHelper.baseUrl}/user-tweets/$targetUserId'));

      if (responseTweets.statusCode == 200) {
        final List<dynamic> data = jsonDecode(responseTweets.body);
        userTweets.value = data.map((e) => Tweet.fromJson(e)).toList();
      }
    } catch (e) {
      print("Profil yükleme hatası: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Profil içinden takip etme / bırakma
  Future<void> toggleFollow(int targetUserId) async {
    final myId = _authController.currentUser.value?.id;
    if (myId == null) return;

    isFollowing.value = !isFollowing.value;
    if (isFollowing.value) {
      followersCount.value++;
    } else {
      followersCount.value--;
    }

    String endpoint = isFollowing.value ? '/follow' : '/unfollow';
    try {
      await http.post(
        Uri.parse('${ApiHelper.baseUrl}$endpoint'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"follower_id": myId, "following_id": targetUserId}),
      );
    } catch (e) {
      isFollowing.value = !isFollowing.value;
      Get.snackbar("Hata", "İşlem başarısız");
    }
  }

  Future<void> toggleRetweet(Tweet tweet) async {
    final myId = _authController.currentUser.value?.id;
    if (myId == null) return;

    bool originalState = tweet.isRetweeted;

    if (tweet.isRetweeted) {
      tweet.isRetweeted = false;
      tweet.retweetCount--;
    } else {
      tweet.isRetweeted = true;
      tweet.retweetCount++;
    }
    userTweets.refresh();

    try {
      final response = await http.post(
        Uri.parse('${ApiHelper.baseUrl}/retweet'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": myId, "tweet_id": tweet.id}),
      );

      if (response.statusCode != 200) {
        tweet.isRetweeted = originalState;
        tweet.retweetCount =
            originalState ? tweet.retweetCount + 1 : tweet.retweetCount - 1;
        userTweets.refresh();
        Get.snackbar("Hata", "İşlem başarısız");
      }
    } catch (e) {
      tweet.isRetweeted = originalState;
      tweet.retweetCount =
          originalState ? tweet.retweetCount + 1 : tweet.retweetCount - 1;
      userTweets.refresh();
      print("Retweet hatası: $e");
    }
  }

  Future<void> toggleLike(Tweet tweet) async {
    final myId = _authController.currentUser.value?.id;
    if (myId == null) return;

    bool originalLiked = tweet.isLiked;

    if (tweet.isLiked) {
      tweet.isLiked = false;
      tweet.likeCount--;
    } else {
      tweet.isLiked = true;
      tweet.likeCount++;
    }
    userTweets.refresh();

    try {
      final response = await http.post(
        Uri.parse('${ApiHelper.baseUrl}/toggle-like'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": myId,
          "tweet_id": tweet.id,
        }),
      );

      if (response.statusCode != 200) {
        tweet.isLiked = originalLiked;
        tweet.likeCount =
            originalLiked ? tweet.likeCount + 1 : tweet.likeCount - 1;
        userTweets.refresh();
      }
    } catch (e) {
      tweet.isLiked = originalLiked;
      tweet.likeCount =
          originalLiked ? tweet.likeCount + 1 : tweet.likeCount - 1;
      userTweets.refresh();
      print("Like hatası: $e");
    }
  }
}
