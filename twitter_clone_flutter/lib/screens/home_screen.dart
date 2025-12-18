import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/nav_controller.dart';
import 'comment_screen.dart';
import 'other_profile_screen.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final HomeController _homeController = Get.put(HomeController());
  final AuthController _authController = Get.find();

  final NavController _navController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Icon(Icons.flutter_dash, color: Colors.blue, size: 32),
        leading: Padding(
          padding: const EdgeInsets.all(10.0), // Biraz boşluk
          child: GestureDetector(
            onTap: () {
              // Profil sekmesine (Index 2) geçiş yap
              _navController.changeIndex(2);
            },
            child: CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              backgroundImage: null,
              child: Text(
                _authController.currentUser.value?.username[0].toUpperCase() ??
                    "U",
                style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ),
        ),
        actions: const [],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade100, height: 1.0),
        ),
      ),

      // --- BODY ---
      body: RefreshIndicator(
        onRefresh: () async {
          await _homeController.fetchFeed();
        },
        color: Colors.blue,
        backgroundColor: Colors.white,
        child: Obx(() {
          if (_homeController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_homeController.tweets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.feed_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text("Akışın sessiz görünüyor.",
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _homeController.tweets.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final tweet = _homeController.tweets[index];
              final bool isRetweet = tweet.retweeterUsername != null;

              return InkWell(
                onTap: () => Get.to(() => CommentScreen(tweet: tweet)),
                splashColor:
                    const Color.fromARGB(0, 33, 149, 243).withOpacity(0.05),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- RETWEET BİLGİSİ ---
                      if (isRetweet)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6, left: 38),
                          child: GestureDetector(
                            onTap: () {
                              if (tweet.retweeterId != null &&
                                  tweet.retweeterId !=
                                      _authController.currentUser.value?.id) {
                                Get.to(() => OtherProfileScreen(
                                    userId: tweet.retweeterId!));
                              }
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.repeat,
                                    size: 14, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(
                                  "${tweet.retweeterUsername} Retweetledi",
                                  style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- AVATAR ---
                          GestureDetector(
                            onTap: () {
                              if (tweet.userId !=
                                  _authController.currentUser.value?.id) {
                                Get.to(() =>
                                    OtherProfileScreen(userId: tweet.userId));
                              } else {
                                _navController.changeIndex(2);
                              }
                            },
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.blue.shade50,
                              child: Text(
                                tweet.username.isNotEmpty
                                    ? tweet.username[0].toUpperCase()
                                    : "?",
                                style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // --- İÇERİK ---
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Başlık (İsim + Kullanıcı Adı + Tarih)
                                Row(
                                  children: [
                                    Flexible(
                                      child: GestureDetector(
                                        onTap: () {
                                          if (tweet.userId !=
                                              _authController
                                                  .currentUser.value?.id) {
                                            Get.to(() => OtherProfileScreen(
                                                userId: tweet.userId));
                                          } else {
                                            _navController.changeIndex(2);
                                          }
                                        },
                                        child: Text(
                                          tweet.username,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                              color: Colors.black),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      "· ${tweet.date.length > 10 ? tweet.date.substring(5, 10) : tweet.date}",
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 14),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 4),

                                // Tweet Metni
                                Text(
                                  tweet.content,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.3,
                                      color: Colors.black87),
                                ),

                                const SizedBox(height: 12),

                                Padding(
                                  padding: const EdgeInsets.only(right: 40.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // YORUM
                                      _buildActionButton(
                                        icon: Icons.chat_bubble_outline,
                                        activeIcon: Icons.chat_bubble,
                                        color: Colors.grey.shade600,
                                        activeColor: Colors.blue,
                                        count: tweet.commentCount,
                                        isActive: false,
                                        onTap: () => Get.to(
                                            () => CommentScreen(tweet: tweet)),
                                      ),

                                      // RETWEET
                                      _buildActionButton(
                                        icon: Icons.repeat,
                                        activeIcon: Icons.repeat,
                                        color: Colors.grey.shade600,
                                        activeColor: Colors.green,
                                        count: tweet.retweetCount,
                                        isActive: tweet.isRetweeted,
                                        onTap: () => _homeController
                                            .toggleRetweet(tweet),
                                      ),

                                      // BEĞENİ
                                      _buildActionButton(
                                        icon: Icons.favorite_border,
                                        activeIcon: Icons.favorite,
                                        color: Colors.grey.shade600,
                                        activeColor: Colors.red,
                                        count: tweet.likeCount,
                                        isActive: tweet.isLiked,
                                        onTap: () =>
                                            _homeController.toggleLike(tweet),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ),

      // Floating Action Button (Tweet At)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        shape: const CircleBorder(),
        elevation: 3,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
        onPressed: () => _showTweetSheet(context),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required IconData activeIcon,
    required Color color,
    required Color activeColor,
    required int count,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        child: Row(
          children: [
            Icon(isActive ? activeIcon : icon,
                size: 19, color: isActive ? activeColor : color),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Text(count.toString(),
                  style: TextStyle(
                      color: isActive ? activeColor : color,
                      fontSize: 13,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal)),
            ]
          ],
        ),
      ),
    );
  }

  void _showTweetSheet(BuildContext context) {
    final txtController = TextEditingController();
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
        height: 600,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                    onPressed: () => Get.back(),
                    child: const Text("İptal",
                        style: TextStyle(color: Colors.black87, fontSize: 16))),
                ElevatedButton(
                  onPressed: () {
                    _homeController.postTweet(txtController.text);
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8)),
                  child: const Text("Gönder",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Yazı Alanı
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  radius: 18,
                  child: Text(
                    _authController.currentUser.value?.username[0]
                            .toUpperCase() ??
                        "U",
                    style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    controller: txtController,
                    autofocus: true,
                    maxLength: 280,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      hintText: "Neler oluyor?",
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 18, color: Colors.grey),
                      counterText: "", // Sayacı gizle
                    ),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
