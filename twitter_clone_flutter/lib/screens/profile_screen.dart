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
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => _authController.logout(),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade100, height: 1.0),
        ),
      ),
      body: Column(
        children: [
          // --- 1. ÜST KISIM (KAPAK / BİLGİ) ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
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
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(8),
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
                      Icon(Icons.notes, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text("Henüz hiç tweet atmadın.",
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: _profileController.myTweets.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (context, index) {
                  final tweet = _profileController.myTweets[index];
                  // Retweet kontrolü
                  final bool isRetweet = tweet.retweeterUsername != null;

                  return InkWell(
                    onTap: () => Get.to(() => CommentScreen(tweet: tweet)),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- RETWEET BAŞLIĞI ---
                          if (isRetweet)
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 6, left: 52),
                              child: Row(
                                children: [
                                  const Icon(Icons.repeat,
                                      size: 14, color: Colors.grey),
                                  const SizedBox(width: 6),
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
                                    Get.to(() => OtherProfileScreen(
                                        userId: tweet.userId));
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
                                        Expanded(
                                          child: GestureDetector(
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
                                                Flexible(
                                                  child: Text(
                                                    tweet.username,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                        color: Colors.black),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  "· ${tweet.date.length > 10 ? tweet.date.substring(5, 10) : tweet.date}",
                                                  style: TextStyle(
                                                      color:
                                                          Colors.grey.shade500,
                                                      fontSize: 14),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        // SİLME BUTONU (Sadece kendi yazdığım tweetler için görünür)
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
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(4.0),
                                              child: const Icon(
                                                  Icons.delete_outline,
                                                  size: 18,
                                                  color: Colors.grey),
                                            ),
                                          )
                                      ],
                                    ),

                                    const SizedBox(height: 4),
                                    Text(tweet.content,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            height: 1.3,
                                            color: Colors.black87)),
                                    const SizedBox(height: 12),

                                    // ALT İKONLAR
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(right: 30.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Yorum
                                          _buildActionButton(
                                            icon: Icons.chat_bubble_outline,
                                            activeIcon: Icons.chat_bubble,
                                            color: Colors.grey.shade600,
                                            activeColor: Colors.blue,
                                            count: tweet.commentCount,
                                            isActive: false,
                                            onTap: () => Get.to(() =>
                                                CommentScreen(tweet: tweet)),
                                          ),

                                          // RETWEET
                                          _buildActionButton(
                                            icon: Icons.repeat,
                                            activeIcon: Icons.repeat,
                                            color: Colors.grey.shade600,
                                            activeColor: Colors.green,
                                            count: tweet.retweetCount,
                                            isActive: tweet.isRetweeted,
                                            onTap: () => _profileController
                                                .toggleRetweet(tweet),
                                          ),

                                          // Beğeni
                                          _buildActionButton(
                                            icon: Icons.favorite_border,
                                            activeIcon: Icons.favorite,
                                            color: Colors.grey.shade600,
                                            activeColor: Colors.red,
                                            count: tweet.likeCount,
                                            isActive: tweet.isLiked,
                                            // NOT: ProfileController'da toggleLike fonksiyonu olması lazım.
                                            // Eğer yoksa eklemen gerekir ya da homeController üzerinden çağırabilirsin.
                                            // Şimdilik boş bırakıyorum veya eklemelisin.
                                            onTap: () {},
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
              Text(
                count.toString(),
                style: TextStyle(
                    color: isActive ? activeColor : color,
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
              ),
            ]
          ],
        ),
      ),
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
