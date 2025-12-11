import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import 'comment_screen.dart';
import 'other_profile_screen.dart'; // Yönlendirme için gerekli
import 'follow_list_screen.dart'; // Takipçi/ Takip Edilen listesi için

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final AuthController _authController = Get.find();
  final ProfileController _profileController = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Profilim",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => _authController.logout(),
          )
        ],
      ),
      body: Column(
        children: [
          // --- 1. ÜST KISIM (KAPAK / BİLGİ) ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Obx(() => Text(
                                "@${_authController.currentUser.value?.username ?? "Kullanıcı"}",
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              )),
                          InkWell(
                            onTap: () => _showEditBioDialog(context),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue.shade50),
                              child: const Icon(Icons.edit,
                                  size: 18, color: Colors.blue),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 5),
                      Obx(() => Text(
                            _authController.currentUser.value?.bio ??
                                "Merhaba!",
                            style: TextStyle(
                                color: Colors.grey.shade700, fontSize: 14),
                          )),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          _buildStat(
                              "Takipçi", _profileController.followersCount),
                          const SizedBox(width: 25),
                          _buildStat(
                              "Takip", _profileController.followingCount),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- 2. ALT KISIM (TWEET LİSTESİ) ---
          Expanded(
            child: Obx(() {
              if (_profileController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_profileController.myTweets.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notes, size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 10),
                      const Text("Henüz hiç tweet atmadın.",
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: _profileController.myTweets.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: Colors.grey),
                itemBuilder: (context, index) {
                  final tweet = _profileController.myTweets[index];
                  // Retweet kontrolü
                  final bool isRetweet = tweet.retweeterUsername != null;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- RETWEET BAŞLIĞI ---
                        if (isRetweet)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5, left: 35),
                            child: Row(
                              children: [
                                const Icon(Icons.repeat,
                                    size: 14, color: Colors.grey),
                                const SizedBox(width: 5),
                                const Text(
                                  "Sen Retweetledin",
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- 1. AVATAR (Yönlendirmeli) ---
                            GestureDetector(
                              onTap: () {
                                // Eğer bu tweet bana ait değilse (RT yapmışsam), sahibine git
                                if (tweet.userId !=
                                    _authController.currentUser.value?.id) {
                                  Get.to(() =>
                                      OtherProfileScreen(userId: tweet.userId));
                                }
                              },
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.blue.shade50,
                                child: Text(
                                  tweet.username[0].toUpperCase(),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // İsim, Tarih ve ÇÖP KUTUSU
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if (tweet.userId !=
                                              _authController
                                                  .currentUser.value?.id) {
                                            Get.to(() => OtherProfileScreen(
                                                userId: tweet.userId));
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

                                      // SİLME BUTONU (Sadece kendi yazdığım tweetler için görünür)
                                      // Retweetleri silmek yerine "RT Geri Al" (Unretweet) yapılır.
                                      if (!isRetweet)
                                        InkWell(
                                          onTap: () {
                                            Get.defaultDialog(
                                              title: "Sil",
                                              middleText:
                                                  "Bu gönderiyi silmek istediğine emin misin?",
                                              textConfirm: "Evet, Sil",
                                              textCancel: "Vazgeç",
                                              confirmTextColor: Colors.white,
                                              buttonColor: Colors.red,
                                              onConfirm: () {
                                                _profileController
                                                    .deleteTweet(tweet.id);
                                                Get.back();
                                              },
                                            );
                                          },
                                          child: const Icon(
                                              Icons.delete_outline,
                                              size: 18,
                                              color: Colors.grey),
                                        )
                                    ],
                                  ),

                                  const SizedBox(height: 4),
                                  Text(tweet.content,
                                      style: const TextStyle(
                                          fontSize: 15, height: 1.3)),
                                  const SizedBox(height: 12),

                                  // ALT İKONLAR
                                  Row(
                                    children: [
                                      // Yorum
                                      InkWell(
                                        onTap: () => Get.to(
                                            () => CommentScreen(tweet: tweet)),
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

                                      // Beğeni
                                      Row(
                                        children: [
                                          Icon(
                                              tweet.isLiked
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              size: 18,
                                              color: tweet.isLiked
                                                  ? Colors.red
                                                  : Colors.grey),
                                          const SizedBox(width: 5),
                                          Text(
                                              tweet.likeCount > 0
                                                  ? tweet.likeCount.toString()
                                                  : "",
                                              style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 13)),
                                        ],
                                      ),
                                      const SizedBox(width: 30),

                                      // RETWEET (Tıklanabilir)
                                      InkWell(
                                        onTap: () => _profileController
                                            .toggleRetweet(tweet),
                                        child: Row(
                                          children: [
                                            Icon(Icons.repeat,
                                                size: 18,
                                                // Eğer RT ise yeşil, değilse gri
                                                color: tweet.isRetweeted
                                                    ? Colors.green
                                                    : Colors.grey),
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
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, RxInt count) {
    return InkWell(
      onTap: () {
        final myId = _authController.currentUser.value?.id;
        if (myId == null) return;

        // Hangi listeyi açacağız?
        String type = label == "Takipçi" ? "followers" : "following";

        Get.to(() => FollowListScreen(userId: myId, type: type));
      },
      child: Obx(() => Column(
            children: [
              Text(count.value.toString(),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              Text(label,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            ],
          )),
    );
  }

  void _showEditBioDialog(BuildContext context) {
    final txtController =
        TextEditingController(text: _authController.currentUser.value?.bio);
    Get.defaultDialog(
      title: "Profili Düzenle",
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: TextField(
          controller: txtController,
          maxLength: 160,
          decoration: const InputDecoration(
            labelText: "Hakkında",
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
        ),
      ),
      textConfirm: "Kaydet",
      textCancel: "İptal",
      confirmTextColor: Colors.white,
      buttonColor: Colors.blue,
      onConfirm: () {
        _authController.updateBio(txtController.text);
        Get.back();
      },
    );
  }
}
