import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/nav_controller.dart';
import '../controllers/home_controller.dart'; // Eklendi
import '../controllers/explore_controller.dart'; // Eklendi
import '../controllers/profile_controller.dart'; // Eklendi
import 'home_screen.dart';
import 'explore_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatelessWidget {
  MainScreen({super.key});

  final NavController _navController = Get.put(NavController());

  // Sayfa listemiz
  final List<Widget> _pages = [
    HomeScreen(),
    const ExploreScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body kısmı seçili index'e göre değişecek
      body: Obx(() => _pages[_navController.selectedIndex.value]),

      bottomNavigationBar: Obx(() => NavigationBar(
            backgroundColor: Colors.white,
            elevation: 5,
            selectedIndex: _navController.selectedIndex.value,
            onDestinationSelected: (index) {
              // 1. Önce görsel olarak sekmeyi değiştir
              _navController.changeIndex(index);

              // 2. ŞİMDİ VERİLERİ YENİLE (Magic Touch ✨)
              switch (index) {
                case 0:
                  // Ana Sayfaya basıldıysa: Home Feed'i yenile
                  if (Get.isRegistered<HomeController>()) {
                    Get.find<HomeController>().fetchFeed();
                  }
                  break;
                case 1:
                  // Keşfet'e basıldıysa: Explore Feed'i yenile
                  if (Get.isRegistered<ExploreController>()) {
                    Get.find<ExploreController>().fetchExploreFeed();
                  }
                  break;
                case 2:
                  // Profile basıldıysa: Kendi tweetlerimi yenile
                  if (Get.isRegistered<ProfileController>()) {
                    Get.find<ProfileController>().fetchMyTweets();
                  }
                  break;
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: Colors.blue),
                label: 'Ana Sayfa',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search, color: Colors.blue),
                label: 'Keşfet',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person, color: Colors.blue),
                label: 'Profil',
              ),
            ],
          )),
    );
  }
}
