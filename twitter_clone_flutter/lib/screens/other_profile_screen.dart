import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/other_profile_controller.dart';
import 'comment_screen.dart';
import 'follow_list_screen.dart';

class OtherProfileScreen extends StatefulWidget {
  final int userId;
  const OtherProfileScreen({super.key, required this.userId});

  @override
  State<OtherProfileScreen> createState() => _OtherProfileScreenState();
}

class _OtherProfileScreenState extends State<OtherProfileScreen> {
  // Controller'ı bu sayfaya özel yapıyoruz (TAG KULLANIMI ÖNEMLİ)
  late OtherProfileController _controller;

  @override
  void initState() {
    super.initState();
    // HER PROFİL İÇİN AYRI CONTROLLER OLUŞTURUYORUZ
    // Eğer bunu yapmazsak Jason'ın profilinden Nwolfe'a gidince veriler karışır.
    _controller =
        Get.put(OtherProfileController(), tag: widget.userId.toString());
    _controller.loadProfile(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Profil",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // --- 1. ÜST KISIM (PROFİL BİLGİLERİ) ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
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
                          const Divider(height: 1, color: Colors.grey),
                      itemBuilder: (context, index) {
                        final tweet = _controller.userTweets[index];
                        final bool isRetweet = tweet.retweeterUsername != null;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // RETWEET BİLGİSİ
                              if (isRetweet)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 5, left: 35),
                                  child: GestureDetector(
                                    onTap: () {
                                      // Retweetleyen kişinin profiline git (Eğer zaten orada değilsek)
                                      if (tweet.retweeterId != null &&
                                          tweet.retweeterId != widget.userId) {
                                        Get.to(
                                          () => OtherProfileScreen(
                                              userId: tweet.retweeterId!),
                                          preventDuplicates: false,
                                        );
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
                                  // --- 1. AVATAR ---
                                  GestureDetector(
                                    onTap: () {
                                      // KONTROL BURADA:
                                      // Eğer tweetin sahibi (tweet.userId) şu an baktığımız profil (widget.userId) DEĞİLSE git.
                                      if (tweet.userId != widget.userId) {
                                        Get.to(
                                          () => OtherProfileScreen(
                                              userId: tweet.userId),
                                          preventDuplicates: false,
                                        );
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

                                  const SizedBox(width: 12),

                                  // --- 2. İÇERİK ---
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // İSİM VE TARİH
                                        GestureDetector(
                                          onTap: () {
                                            // KONTROL BURADA DA VAR
                                            if (tweet.userId != widget.userId) {
                                              Get.to(
                                                () => OtherProfileScreen(
                                                    userId: tweet.userId),
                                                preventDuplicates: false,
                                              );
                                            }
                                          },
                                          child: Row(
                                            children: [
                                              Text(tweet.username,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16)),
                                              const SizedBox(width: 5),
                                              Text(
                                                  "• ${tweet.date.length > 10 ? tweet.date.substring(0, 10) : tweet.date}",
                                                  style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600,
                                                      fontSize: 13)),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(height: 4),
                                        Text(tweet.content,
                                            style: const TextStyle(
                                                fontSize: 15, height: 1.3)),

                                        // ... (Alt butonlar aynı) ...
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            InkWell(
                                              onTap: () => Get.to(() =>
                                                  CommentScreen(tweet: tweet)),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                      Icons.chat_bubble_outline,
                                                      size: 18,
                                                      color: Colors.grey),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                      tweet.commentCount > 0
                                                          ? tweet.commentCount
                                                              .toString()
                                                          : "",
                                                      style: const TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 13)),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 30),
                                            // Görsel RT Sayısı
                                            Row(
                                              children: [
                                                const Icon(Icons.repeat,
                                                    size: 18,
                                                    color: Colors.grey),
                                                const SizedBox(width: 5),
                                                Text(
                                                    tweet.retweetCount > 0
                                                        ? tweet.retweetCount
                                                            .toString()
                                                        : "",
                                                    style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 13)),
                                              ],
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
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

  // ... OtherProfileScreen'in en altındaki _buildStat fonksiyonu ...

  Widget _buildStat(String label, int count) {
    return InkWell(
      // <--- InkWell ile sardık
      onTap: () {
        // Hangi listeyi istiyoruz?
        String type = label == "Takipçi" ? "followers" : "following";

        Get.to(() => FollowListScreen(
            userId: widget.userId, // Şu an baktığımız profilin ID'si
            type: type));
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
}
