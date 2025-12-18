import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/explore_controller.dart';
import '../controllers/auth_controller.dart';
import 'comment_screen.dart';
import 'other_profile_screen.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ExploreController controller = Get.put(ExploreController());
    final AuthController authController = Get.find();
    final TextEditingController searchController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(25),
          ),
          child: TextField(
            controller: searchController,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: "Kullanıcı Ara...",
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              border: InputBorder.none,
              prefixIcon:
                  Icon(Icons.search, color: Colors.grey.shade500, size: 22),
              suffixIcon: IconButton(
                icon: Icon(Icons.cancel, color: Colors.grey.shade400, size: 20),
                onPressed: () {
                  searchController.clear();
                  controller.searchUsers("");
                  FocusScope.of(context).unfocus(); // Klavyeyi kapat
                },
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            onChanged: (val) => controller.searchUsers(val),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade100, height: 1.0),
        ),
      ),
      body: Obx(() {
        // DURUM 1: ARAMA MODU (Kullanıcı Listesi)
        if (controller.isSearching.value) {
          if (controller.foundUsers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text("Kullanıcı bulunamadı",
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            );
          }
          // Arama Sonuçları Listesi
          return ListView.separated(
            itemCount: controller.foundUsers.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final user = controller.foundUsers[index];
              return InkWell(
                onTap: () => Get.to(() => OtherProfileScreen(userId: user.id)),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey.shade200,
                        child: Text(
                          user.username[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.username,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      // Takip Et Butonu
                      SizedBox(
                        height: 32,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                user.isFollowing ? Colors.white : Colors.black,
                            foregroundColor:
                                user.isFollowing ? Colors.black : Colors.white,
                            elevation: 0,
                            side: BorderSide(
                                color: user.isFollowing
                                    ? Colors.grey.shade300
                                    : Colors.transparent),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onPressed: () => controller.toggleFollow(user),
                          child: Text(
                            user.isFollowing ? "Takip Ediliyor" : "Takip Et",
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        // DURUM 2: NORMAL AKIŞ MODU (Tweet Listesi)
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async => await controller.fetchExploreFeed(),
          color: Colors.blue,
          backgroundColor: Colors.white,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: controller.allTweets.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final tweet = controller.allTweets[index];
              final bool isMe =
                  tweet.userId == authController.currentUser.value?.id;

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
                      // --- RETWEET BİLGİSİ (Varsa) ---
                      if (isRetweet)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6, left: 52),
                          child: Row(
                            children: [
                              const Icon(Icons.repeat,
                                  size: 12, color: Colors.grey),
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

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. AVATAR
                          GestureDetector(
                            onTap: () {
                              if (!isMe) {
                                Get.to(() =>
                                    OtherProfileScreen(userId: tweet.userId));
                              }
                            },
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.grey.shade200,
                              child: Text(
                                tweet.username.isNotEmpty
                                    ? tweet.username[0].toUpperCase()
                                    : "?",
                                style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // 2. İÇERİK
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Başlık
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        tweet.username,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            color: Colors.black),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      "· ${tweet.date.length > 10 ? tweet.date.substring(5, 10) : tweet.date}",
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 14),
                                    ),
                                    const Spacer(),
                                    // Keşfet'e özel küçük "Takip Et" butonu (Eğer takip etmiyorsak)
                                    if (!isMe && !tweet.isFollowing)
                                      GestureDetector(
                                        onTap: () => controller
                                            .followUserFromTweet(tweet),
                                        child: Text(
                                          "Takip Et",
                                          style: TextStyle(
                                              color: Colors.blue.shade700,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13),
                                        ),
                                      )
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

                                //ALT BUTONLAR ( Yorum, Retweet, Beğeni )
                                Padding(
                                  padding: const EdgeInsets.only(right: 30.0),
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
                                        onTap: () => Get.to(
                                            () => CommentScreen(tweet: tweet)),
                                      ),
                                      // Retweet
                                      _buildActionButton(
                                        icon: Icons.repeat,
                                        activeIcon: Icons.repeat,
                                        color: Colors.grey.shade600,
                                        activeColor: Colors.green,
                                        count: tweet.retweetCount,
                                        isActive: tweet.isRetweeted,
                                        onTap: () {},
                                      ),
                                      // Beğeni
                                      _buildActionButton(
                                        icon: Icons.favorite_border,
                                        activeIcon: Icons.favorite,
                                        color: Colors.grey.shade600,
                                        activeColor: Colors.red,
                                        count: tweet.likeCount,
                                        isActive: tweet.isLiked,
                                        onTap: () =>
                                            controller.toggleLike(tweet),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  // Yardımcı Buton Widget'ı (HomeScreen ile aynı)
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
                size: 18, color: isActive ? activeColor : color),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(count.toString(),
                  style: TextStyle(
                      color: isActive ? activeColor : color,
                      fontSize: 12,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal)),
            ]
          ],
        ),
      ),
    );
  }
}
