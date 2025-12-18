import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../models.dart';
import 'api_helper.dart';
import '../screens/home_screen.dart';
import '../screens/main_screen.dart';

class AuthController extends GetxController {
  var currentUser = Rxn<User>();
  var isLoading = false.obs;

  Future<void> login(String username) async {
    if (username.isEmpty) return;

    isLoading.value = true;
    try {
      final response = await http.post(
        Uri.parse('${ApiHelper.baseUrl}/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        currentUser.value = User.fromJson(data);

        // Başarılı giriş -> Anasayfaya yönlendir ve geçmişi sil
        Get.offAll(() => MainScreen());
      } else {
        Get.snackbar("Hata", "Kullanıcı bulunamadı!",
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar("Hata", "Bağlantı sorunu: $e",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register(String username, String email, String password) async {
    isLoading.value = true;
    try {
      final response = await http.post(
        Uri.parse('${ApiHelper.baseUrl}/register'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 201) {
        // Kayıt başarılı oldu, şimdi otomatik giriş yapalım veya login sayfasına yönlendirelim
        Get.snackbar("Başarılı", "Hesap oluşturuldu! Giriş yapılıyor...");

        // Otomatik giriş yap
        await login(username);
      } else if (response.statusCode == 409) {
        Get.snackbar("Hata", "Bu kullanıcı adı zaten kullanılıyor.");
      } else {
        Get.snackbar(
            "Hata", "Kayıt olunamadı. Hata kodu: ${response.statusCode}");
      }
    } catch (e) {
      Get.snackbar("Hata", "Bağlantı sorunu: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateBio(String newBio) async {
    final myId = currentUser.value?.id;
    if (myId == null) return;

    try {
      final response = await http.put(
        Uri.parse('${ApiHelper.baseUrl}/update-profile'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": myId,
          "bio": newBio,
        }),
      );

      if (response.statusCode == 200) {
        // API'de güncellendi, şimdi Uygulama içindeki veriyi de güncelleyelim
        // Mevcut kullanıcıyı al, bio'sunu değiştirip yerine koy
        final updatedUser = User(
          id: currentUser.value!.id,
          username: currentUser.value!.username,
          bio: newBio, // <--- Yeni bio
          isFollowing: false,
        );
        currentUser.value = updatedUser; // Obx tetiklenir, ekran güncellenir

        Get.snackbar("Başarılı", "Profilin güncellendi!");
      } else {
        Get.snackbar("Hata", "Güncellenemedi");
      }
    } catch (e) {
      Get.snackbar("Hata", "Bağlantı sorunu: $e");
    }
  }

  void logout() {
    currentUser.value = null;
    Get.offAllNamed("/"); // Veya Get.offAll(() => LoginScreen());
  }
}
