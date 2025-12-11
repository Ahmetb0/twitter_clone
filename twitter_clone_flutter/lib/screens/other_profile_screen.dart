import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/other_profile_controller.dart';
import '../controllers/auth_controller.dart'; // Yönlendirme kontrolü için
import 'comment_screen.dart';
import 'follow_list_screen.dart';

class OtherProfileScreen extends StatefulWidget {
  final int userId;
  const OtherProfileScreen({super.key, required this.userId});

  @override
  State<OtherProfileScreen> createState() => _OtherProfileScreenState();
}

class _OtherProfileScreenState extends State<OtherProfileScreen> {
  late OtherProfileController _controller;
  // AuthController'ı bulalım ki "kendime tıklarsam" kontrolü yapabilelim
  final AuthController _authController = Get.find();

  @override
  void initState() {
    super.initState();
    _controller =
        Get.put(OtherProfileController(), tag: widget.userId.toString());
    _controller.loadProfile(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // --- APP BAR ---
      appBar: AppBar(
        title: const Text("Profil",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme:
            const IconThemeData(color: Colors.black), // Geri butonu siyah
      ),

      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // --- 1. ÜST KISIM (KAPAK / BİLGİ) ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.blue.shade50,
                        child: Text(
                          _controller.username.value.isNotEmpty
                              ? _controller.username.value[0].toUpperCase()
                              : "?",
                          style: const TextStyle(
                              fontSize: 30,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("@${_controller.username.value}",
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            Text(_controller.bio.value,
                                style: TextStyle(
                                    color: Colors.grey.shade700, fontSize: 14)),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                _buildStat("Takipçi",
                                    _controller.followersCount.value),
                                const SizedBox(width: 25),
                                _buildStat(
                                    "Takip", _controller.followingCount.value),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Takip Et Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 35,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _controller.isFollowing.value
                            ? Colors.white
                            : Colors.black,
                        foregroundColor: _controller.isFollowing.value
                            ? Colors.black
                            : Colors.white,
                        elevation: 0,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () => _controller.toggleFollow(widget.userId),
                      child: Text(
                          _controller.isFollowing.value
                              ? "Takip Ediliyor"
                              : "Takip Et",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),

            // --- 2. ALT KISIM (TWEET LİSTESİ) ---
            Expanded(
              child: _controller.userTweets.isEmpty
                  ? Center(
                      child: Text("Henüz tweet yok.",
                          style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      itemCount: _controller.userTweets.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        final tweet = _controller.userTweets[index];
                        final bool isRetweet = tweet.retweeterUsername != null;

                        return InkWell(
                          onTap: () =>
                              Get.to(() => CommentScreen(tweet: tweet)),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // --- RETWEET BİLGİSİ ---
                                if (isRetweet)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 6, left: 52),
                                    child: GestureDetector(
                                      onTap: () {
                                        if (tweet.retweeterId != null &&
                                            tweet.retweeterId !=
                                                _authController
                                                    .currentUser.value?.id) {
                                          Get.to(
                                              () => OtherProfileScreen(
                                                  userId: tweet.retweeterId!),
                                              preventDuplicates: false);
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
                                    // --- AVATAR (Kendime Tıklarsam Gitme, Başkasına Git) ---
                                    GestureDetector(
                                      onTap: () {
                                        // Zaten bu profildeysek (widget.userId == tweet.userId) gitme
                                        if (tweet.userId != widget.userId) {
                                          Get.to(
                                              () => OtherProfileScreen(
                                                  userId: tweet.userId),
                                              preventDuplicates: false);
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // İSİM VE TARİH
                                          Row(
                                            children: [
                                              Flexible(
                                                child: GestureDetector(
                                                  onTap: () {
                                                    if (tweet.userId !=
                                                        widget.userId) {
                                                      Get.to(
                                                          () =>
                                                              OtherProfileScreen(
                                                                  userId: tweet
                                                                      .userId),
                                                          preventDuplicates:
                                                              false);
                                                    }
                                                  },
                                                  child: Text(
                                                    tweet.username,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16),
                                                    overflow:
                                                        TextOverflow.ellipsis,
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

                                          // METİN
                                          Text(tweet.content,
                                              style: const TextStyle(
                                                  fontSize: 15,
                                                  height: 1.3,
                                                  color: Colors.black87)),

                                          const SizedBox(height: 12),

                                          // --- ALT BUTONLAR ---
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 30.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                // YORUM
                                                _buildActionButton(
                                                  icon:
                                                      Icons.chat_bubble_outline,
                                                  activeIcon: Icons.chat_bubble,
                                                  color: Colors.grey.shade600,
                                                  activeColor: Colors.blue,
                                                  count: tweet.commentCount,
                                                  isActive: false,
                                                  onTap: () => Get.to(() =>
                                                      CommentScreen(
                                                          tweet: tweet)),
                                                ),

                                                // RETWEET
                                                _buildActionButton(
                                                  icon: Icons.repeat,
                                                  activeIcon: Icons.repeat,
                                                  color: Colors.grey.shade600,
                                                  activeColor: Colors.green,
                                                  count: tweet.retweetCount,
                                                  isActive: tweet.isRetweeted,
                                                  onTap: () =>
                                                      _controller.toggleRetweet(
                                                          tweet), // Fonksiyon çalışacak
                                                ),

                                                // BEĞENİ (ARTIK ÇALIŞIYOR!)
                                                _buildActionButton(
                                                  icon: Icons.favorite_border,
                                                  activeIcon: Icons.favorite,
                                                  color: Colors.grey.shade600,
                                                  activeColor: Colors.red,
                                                  count: tweet.likeCount,
                                                  isActive: tweet.isLiked,
                                                  onTap: () =>
                                                      _controller.toggleLike(
                                                          tweet), // Yeni eklediğimiz fonksiyon
                                                ),
                                              ],
                                            ),
                                          )
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
                    ),
            ),
          ],
        );
      }),
    );
  }

  // Yardımcı İstatistik Widget'ı
  Widget _buildStat(String label, int count) {
    return InkWell(
      onTap: () {
        String type = label == "Takipçi" ? "followers" : "following";
        Get.to(() => FollowListScreen(userId: widget.userId, type: type));
      },
      child: Column(
        children: [
          Text(count.toString(),
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  // Yardımcı Buton Widget'ı
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
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Icon(isActive ? activeIcon : icon,
                size: 19, color: isActive ? activeColor : color),
            if (count > 0) ...[
              const SizedBox(width: 4),
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
}
