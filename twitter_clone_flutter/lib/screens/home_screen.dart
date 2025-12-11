import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../controllers/auth_controller.dart';
import 'comment_screen.dart';
import 'other_profile_screen.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final HomeController _homeController = Get.put(HomeController());
  final AuthController _authController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.white, // Arka planı beyaz yapalım, daha temiz durur
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, // Gölgeyi kaldır
        title: Obx(() => Text(
              "Hoşgeldin, ${_authController.currentUser.value?.username}",
              style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            )),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: _homeController.fetchFeed,
          )
        ],
      ),
      body: Obx(() {
        if (_homeController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.separated(
          // Card yerine daha modern bir liste görünümü
          itemCount: _homeController.tweets.length,
          separatorBuilder: (context, index) =>
              const Divider(height: 1, color: Colors.grey), // Çizgi ile ayır
          itemBuilder: (context, index) {
            final tweet = _homeController.tweets[index];
            // Retweet kontrolü
            final bool isRetweet = tweet.retweeterUsername != null;

            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- RETWEET BAŞLIĞI (YENİ EKLENDİ) ---
                  if (isRetweet)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5, left: 35),
                      child: GestureDetector(
                        onTap: () {
                          // RT yapan kişinin profiline git
                          if (tweet.retweeterId != null) {
                            Get.to(() =>
                                OtherProfileScreen(userId: tweet.retweeterId!));
                          }
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.repeat,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 5),
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
                      // --- 1. SOL TARA (AVATAR) ---
                      GestureDetector(
                        onTap: () {
                          // Kendi profilimiz değilse git
                          if (tweet.userId !=
                              _authController.currentUser.value?.id) {
                            Get.to(
                                () => OtherProfileScreen(userId: tweet.userId));
                          }
                        },
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.blue.shade50,
                          child: Text(
                            tweet.username.isNotEmpty
                                ? tweet.username[0].toUpperCase()
                                : "?",
                            style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      const SizedBox(
                          width: 12), // Avatar ile içerik arası boşluk

                      // --- 2. SAĞ TARAF (İÇERİK) ---
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // İsim ve Tarih Satırı
                            GestureDetector(
                              onTap: () {
                                if (tweet.userId !=
                                    _authController.currentUser.value?.id) {
                                  Get.to(() =>
                                      OtherProfileScreen(userId: tweet.userId));
                                }
                              },
                              child: Row(
                                children: [
                                  Text(
                                    tweet.username,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    "• ${tweet.date.length > 10 ? tweet.date.substring(0, 10) : tweet.date}",
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 4),

                            // Tweet Metni
                            Text(
                              tweet.content,
                              style: const TextStyle(fontSize: 15, height: 1.3),
                            ),

                            const SizedBox(height: 12),

                            // Etkileşim Butonları (Beğeni & Yorum & Retweet)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                // YORUM
                                _buildActionButton(
                                  icon: Icons.chat_bubble_outline,
                                  color: Colors.grey,
                                  count: tweet.commentCount,
                                  onTap: () =>
                                      Get.to(() => CommentScreen(tweet: tweet)),
                                ),

                                const SizedBox(width: 30),

                                // BEĞENİ
                                _buildActionButton(
                                  icon: tweet.isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color:
                                      tweet.isLiked ? Colors.red : Colors.grey,
                                  count: tweet.likeCount,
                                  onTap: () =>
                                      _homeController.toggleLike(tweet),
                                ),

                                const SizedBox(width: 30),

                                // RETWEET
                                _buildActionButton(
                                  icon: Icons.repeat,
                                  color: tweet.isRetweeted
                                      ? Colors.green
                                      : Colors.grey,
                                  count: tweet.retweetCount,
                                  onTap: () =>
                                      _homeController.toggleRetweet(tweet),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          final txtController = TextEditingController();
          Get.defaultDialog(
            title: "Tweet At",
            titleStyle: const TextStyle(fontWeight: FontWeight.bold),
            content: TextField(
              controller: txtController,
              decoration: const InputDecoration(
                hintText: "Neler oluyor?",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            textConfirm: "Gönder",
            textCancel: "İptal",
            confirmTextColor: Colors.white,
            buttonColor: Colors.blue,
            onConfirm: () {
              _homeController.postTweet(txtController.text);
              Get.back();
            },
          );
        },
      ),
    );
  }

  // Kod tekrarını önlemek için yardımcı widget
  Widget _buildActionButton(
      {required IconData icon,
      required Color color,
      required int count,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20), // Tıklama efekti yuvarlak olsun
      child: Padding(
        padding: const EdgeInsets.all(5.0), // Tıklama alanını genişlet
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 5),
            Text(
              count > 0 ? count.toString() : "",
              style: TextStyle(color: color, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
