import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../models.dart';
import '../controllers/api_helper.dart';
import '../controllers/auth_controller.dart';
import 'other_profile_screen.dart'; // <--- Import etmeyi unutma

class CommentScreen extends StatefulWidget {
  final Tweet tweet;
  const CommentScreen({super.key, required this.tweet});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _commentController = TextEditingController();
  final AuthController _authController = Get.find();
  List<dynamic> comments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchComments();
  }

  Future<void> fetchComments() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiHelper.baseUrl}/comments/${widget.tweet.id}'));
      if (response.statusCode == 200) {
        setState(() {
          comments = jsonDecode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      print("Hata: $e");
    }
  }

  Future<void> postComment() async {
    if (_commentController.text.isEmpty) return;

    final myId = _authController.currentUser.value?.id;
    if (myId == null) return;

    try {
      await http.post(
        Uri.parse('${ApiHelper.baseUrl}/comment'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": myId,
          "tweet_id": widget.tweet.id,
          "content": _commentController.text
        }),
      );

      _commentController.clear();
      FocusScope.of(context).unfocus(); // Klavyeyi kapat
      fetchComments(); // Listeyi yenile
      Get.snackbar("Başarılı", "Yorum gönderildi",
          duration: const Duration(seconds: 1));
    } catch (e) {
      Get.snackbar("Hata", "Gönderilemedi: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Tweet",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // 1. TWEETİN KENDİSİ (Modern Tasarım)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.shade50,
                  child: Text(widget.tweet.username[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.tweet.username,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(widget.tweet.content,
                          style: const TextStyle(fontSize: 16, height: 1.3)),
                      const SizedBox(height: 8),
                      Text(widget.tweet.date,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(thickness: 1, height: 1),

          // 2. YORUM LİSTESİ
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : comments.isEmpty
                    ? Center(
                        child: Text("Henüz yorum yok. İlk yorumu sen yap!",
                            style: TextStyle(color: Colors.grey.shade600)),
                      )
                    : ListView.separated(
                        itemCount: comments.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final c = comments[index];
                          // Yorumu yapan kişi ben miyim?
                          final bool isMe = c['user_id'] ==
                              _authController.currentUser.value?.id;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: GestureDetector(
                              // TIKLANABİLİR AVATAR
                              onTap: () {
                                if (!isMe) {
                                  Get.to(() =>
                                      OtherProfileScreen(userId: c['user_id']));
                                }
                              },
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey.shade200,
                                child: Text(c['username'][0].toUpperCase(),
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54)),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(c['username'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                const SizedBox(width: 5),
                                Text("• yanıtladı",
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12)),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(c['content'],
                                  style: const TextStyle(
                                      color: Colors.black87, fontSize: 15)),
                            ),
                          );
                        },
                      ),
          ),

          // 3. YORUM YAZMA ALANI (Alt Bar)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: "Yanıtını gönder",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: postComment,
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
