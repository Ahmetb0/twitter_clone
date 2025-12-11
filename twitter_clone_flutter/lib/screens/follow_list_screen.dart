import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../models.dart'; // User modelini kullanacağız
import '../controllers/api_helper.dart';
import 'other_profile_screen.dart';

class FollowListScreen extends StatefulWidget {
  final int userId;
  final String type; // 'followers' veya 'following'

  const FollowListScreen({super.key, required this.userId, required this.type});

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  List<User> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      final response = await http.get(Uri.parse(
          '${ApiHelper.baseUrl}/users/${widget.userId}/${widget.type}'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          users = data.map((e) => User.fromJson(e)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      print("Liste hatası: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.type == 'followers' ? "Takipçiler" : "Takip Edilenler",
          style:
              const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? const Center(child: Text("Kimse yok."))
              : ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade50,
                        child: Text(user.username[0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold)),
                      ),
                      title: Text(user.username,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(user.bio,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () {
                        // O kişinin profiline git
                        Get.to(() => OtherProfileScreen(userId: user.id),
                            preventDuplicates: false);
                      },
                    );
                  },
                ),
    );
  }
}
