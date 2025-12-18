import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../models.dart';
import 'api_helper.dart';
import 'auth_controller.dart';

class ProfileController extends GetxController {
  var myTweets = <Tweet>[].obs;
  var isLoading = true.obs;
  var followersCount = 0.obs;
  var followingCount = 0.obs;

  final AuthController _authController = Get.find();

  @override
  void onInit() {
    fetchMyTweets();
    fetchMyStats();
    super.onInit();
  }

  Future<void> fetchMyTweets() async {
    final userId = _authController.currentUser.value?.id;
    if (userId == null) return;

    isLoading.value = true;
    try {
      final response =
          await http.get(Uri.parse('${ApiHelper.baseUrl}/user-tweets/$userId'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        myTweets.value = data.map((e) => Tweet.fromJson(e)).toList();
      }
    } catch (e) {
      Get.snackbar("Hata", "Profil yüklenemedi: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteTweet(int tweetId) async {
    final userId = _authController.currentUser.value?.id;
    if (userId == null) return;

    try {
      final response = await http.delete(
        Uri.parse('${ApiHelper.baseUrl}/tweet/$tweetId?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        myTweets.removeWhere((tweet) => tweet.id == tweetId);
        Get.snackbar("Başarılı", "Tweet silindi",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 1));
      } else {
        Get.snackbar("Hata", "Silinemedi. Yetkiniz olmayabilir.");
      }
    } catch (e) {
      Get.snackbar("Hata", "Bir sorun oluştu: $e");
    }
  }

  Future<void> fetchMyStats() async {
    final myId = _authController.currentUser.value?.id;
    if (myId == null) return;

    try {
      final response = await http
          .get(Uri.parse('${ApiHelper.baseUrl}/user-summary?target_id=$myId'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        followersCount.value = data['followers'];
        followingCount.value = data['following'];
      }
    } catch (e) {
      print("İstatistik hatası: $e");
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
    myTweets.refresh();

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
        myTweets.refresh();
        Get.snackbar("Hata", "İşlem başarısız");
      }
    } catch (e) {
      tweet.isRetweeted = originalState;
      tweet.retweetCount =
          originalState ? tweet.retweetCount + 1 : tweet.retweetCount - 1;
      myTweets.refresh();
      print("Retweet hatası: $e");
    }
  }
}
