import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../models.dart';
import 'api_helper.dart';
import 'auth_controller.dart';

class HomeController extends GetxController {
  var tweets = <Tweet>[].obs;
  var isLoading = true.obs;

  final AuthController authController = Get.find();

  @override
  void onInit() {
    fetchFeed();
    super.onInit();
  }

  Future<void> fetchFeed() async {
    isLoading.value = true;

    final userId = authController.currentUser.value?.id;

    if (userId == null) {
      isLoading.value = false;
      return;
    }

    try {
      final response =
          await http.get(Uri.parse('${ApiHelper.baseUrl}/feed/$userId'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        tweets.value = data.map((e) => Tweet.fromJson(e)).toList();
      }
    } catch (e) {
      Get.snackbar("Hata", "Tweetler çekilemedi: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> postTweet(String content) async {
    if (content.isEmpty) return;

    await http.post(
      Uri.parse('${ApiHelper.baseUrl}/tweet'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": authController.currentUser.value!.id,
        "content": content,
      }),
    );

    fetchFeed();
  }

  Future<void> toggleLike(Tweet tweet) async {
    final myId = authController.currentUser.value?.id;
    if (myId == null) return;

    bool originalLiked = tweet.isLiked;

    if (tweet.isLiked) {
      tweet.isLiked = false;
      tweet.likeCount--;
    } else {
      tweet.isLiked = true;
      tweet.likeCount++;
    }
    tweets.refresh();

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
        tweets.refresh();
      }
    } catch (e) {
      tweet.isLiked = originalLiked;
      tweet.likeCount =
          originalLiked ? tweet.likeCount + 1 : tweet.likeCount - 1;
      tweets.refresh();
      print("Like hatası: $e");
    }
  }

  Future<void> toggleRetweet(Tweet tweet) async {
    final myId = authController.currentUser.value?.id;
    if (myId == null) return;

    bool originalState = tweet.isRetweeted;
    if (tweet.isRetweeted) {
      tweet.isRetweeted = false;
      tweet.retweetCount--;
    } else {
      tweet.isRetweeted = true;
      tweet.retweetCount++;
    }
    tweets.refresh();

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
        tweets.refresh();
      }
    } catch (e) {
      tweet.isRetweeted = originalState;
      tweet.retweetCount =
          originalState ? tweet.retweetCount + 1 : tweet.retweetCount - 1;
      tweets.refresh();
      print("Retweet hatası: $e");
    }
  }
}
