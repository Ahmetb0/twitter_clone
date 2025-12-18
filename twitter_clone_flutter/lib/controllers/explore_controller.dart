import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../models.dart';
import 'api_helper.dart';
import 'auth_controller.dart';

class ExploreController extends GetxController {
  // Veriler
  var allTweets = <Tweet>[].obs; // Tüm tweetler
  var foundUsers = <User>[].obs; // Arama sonuçları

  // Durumlar
  var isLoading = true.obs;
  var isSearching = false.obs;

  final AuthController _authController = Get.find();

  @override
  void onInit() {
    fetchExploreFeed();
    super.onInit();
  }

  // KEŞFET AKIŞI
  Future<void> fetchExploreFeed() async {
    isLoading.value = true;
    final myId = _authController.currentUser.value?.id;
    if (myId == null) return;

    try {
      final response =
          await http.get(Uri.parse('${ApiHelper.baseUrl}/explore-feed/$myId'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        allTweets.value = data.map((e) => Tweet.fromJson(e)).toList();
      }
    } catch (e) {
      print("Keşfet hatası: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // 2. KULLANICI ARA
  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      isSearching.value = false;
      foundUsers.clear();
      return;
    }
    isSearching.value = true;
    final myId = _authController.currentUser.value?.id;

    try {
      final response = await http
          .get(Uri.parse('${ApiHelper.baseUrl}/search?q=$query&user_id=$myId'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        foundUsers.value = data.map((e) => User.fromJson(e)).toList();
      }
    } catch (e) {
      print("Arama hatası: $e");
    }
  }

  // 3. TAKİP ET
  Future<void> toggleFollow(User user) async {
    final myId = _authController.currentUser.value?.id;
    if (myId == null) return;

    user.isFollowing = !user.isFollowing;
    foundUsers.refresh(); // Listeyi görsel olarak yenile

    String endpoint = user.isFollowing ? '/follow' : '/unfollow';

    try {
      final response = await http.post(
        Uri.parse('${ApiHelper.baseUrl}$endpoint'), // Dinamik endpoint
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "follower_id": myId,
          "following_id": user.id,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        // Hata olursa işlemi geri al
        user.isFollowing = !user.isFollowing;
        foundUsers.refresh();
        Get.snackbar("Hata", "İşlem başarısız oldu");
      }
    } catch (e) {
      user.isFollowing = !user.isFollowing;
      foundUsers.refresh();
      Get.snackbar("Hata", "Bağlantı sorunu");
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
    allTweets.refresh();

    try {
      await http.post(
        Uri.parse('${ApiHelper.baseUrl}/toggle-like'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": myId, "tweet_id": tweet.id}),
      );
    } catch (e) {
      tweet.isLiked = originalLiked;
      tweet.likeCount =
          originalLiked ? tweet.likeCount + 1 : tweet.likeCount - 1;
      allTweets.refresh();
    }
  }

  Future<void> followUserFromTweet(Tweet tweet) async {
    final myId = _authController.currentUser.value?.id;
    if (myId == null) return;

    if (tweet.userId == myId) return;

    tweet.isFollowing = !tweet.isFollowing;
    allTweets.refresh();

    String endpoint = tweet.isFollowing ? '/follow' : '/unfollow';

    try {
      await http.post(
        Uri.parse('${ApiHelper.baseUrl}$endpoint'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"follower_id": myId, "following_id": tweet.userId}),
      );
    } catch (e) {
      tweet.isFollowing = !tweet.isFollowing;
      allTweets.refresh();
      Get.snackbar("Hata", "İşlem başarısız");
    }
  }
}
