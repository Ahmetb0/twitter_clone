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
        elevation: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: "Kullanıcı Ara...",
              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20),
              suffixIcon: IconButton(
                icon: Icon(Icons.clear, color: Colors.grey[600], size: 18),
                onPressed: () {
                  searchController.clear();
                  controller.searchUsers("");
                  FocusScope.of(context).unfocus(); // Klavyeyi kapat
                },
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (val) => controller.searchUsers(val),
          ),
        ),
      ),
      body: Obx(() {
        // --- DURUM 1: ARAMA MODU (Kullanıcı Listesi) ---
        if (controller.isSearching.value) {
          if (controller.foundUsers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  const Text("Kullanıcı bulunamadı",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: controller.foundUsers.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = controller.foundUsers[index];
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.blue.shade50,
                  child: Text(
                    user.username[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  user.username,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                trailing: ElevatedButton(
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  ),
                  onPressed: () => controller.toggleFollow(user),
                  child: Text(
                    user.isFollowing ? "Takip Ediliyor" : "Takip Et",
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                onTap: () {
                  Get.to(() => OtherProfileScreen(userId: user.id));
                },
              );
            },
          );
        }

        // --- DURUM 2: NORMAL AKIŞ MODU (Tweet Listesi) ---
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.separated(
          itemCount: controller.allTweets.length,
          separatorBuilder: (context, index) =>
              const Divider(height: 1, color: Colors.grey),
          itemBuilder: (context, index) {
            final tweet = controller.allTweets[index];
            final bool isMe =
                tweet.userId == authController.currentUser.value?.id;

            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. AVATAR (SOL)
                  GestureDetector(
                    onTap: () {
                      if (!isMe) {
                        Get.to(() => OtherProfileScreen(userId: tweet.userId));
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
                            color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // 2. İÇERİK (SAĞ)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // İsim, Tarih ve Takip Butonu
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    tweet.username,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
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

                            // Takip Butonu (Eğer ben değilsem)
                            if (!isMe)
                              GestureDetector(
                                onTap: () =>
                                    controller.followUserFromTweet(tweet),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: tweet.isFollowing
                                          ? Colors.transparent
                                          : Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: tweet.isFollowing
                                              ? Colors.grey.shade300
                                              : Colors.transparent)),
                                  child: Text(
                                    tweet.isFollowing ? "Takipte" : "Takip Et",
                                    style: TextStyle(
                                        color: tweet.isFollowing
                                            ? Colors.grey
                                            : Colors.blue,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              )
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Tweet Metni
                        Text(
                          tweet.content,
                          style: const TextStyle(fontSize: 15, height: 1.3),
                        ),

                        const SizedBox(height: 12),

                        // Alt Butonlar
                        Row(
                          children: [
                            _buildActionButton(
                              icon: Icons.chat_bubble_outline,
                              color: Colors.grey,
                              count: tweet.commentCount,
                              onTap: () =>
                                  Get.to(() => CommentScreen(tweet: tweet)),
                            ),
                            const SizedBox(width: 30),
                            _buildActionButton(
                              icon: tweet.isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: tweet.isLiked ? Colors.red : Colors.grey,
                              count: tweet.likeCount,
                              onTap: () => controller.toggleLike(tweet),
                            ),
                            const SizedBox(width: 30),
                            _buildActionButton(
                              icon: Icons.repeat,
                              color: Colors.grey,
                              count: 0,
                              onTap: () {},
                            ),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required Color color,
      required int count,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
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
