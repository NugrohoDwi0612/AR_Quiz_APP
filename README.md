### AR Quiz App - Hoax Hunter

Selamat datang di repositori **Hoax Hunter**, sebuah aplikasi kuis interaktif berbasis **Augmented Reality (AR)** yang dirancang untuk mengedukasi pengguna tentang bahaya hoax dan cara mengidentifikasinya. Aplikasi ini memungkinkan pemain berburu soal kuis dengan memindai kode QR yang tersebar di lingkungan nyata, kemudian menjawab pertanyaan melalui pengalaman AR yang imersif.

### Fitur Utama

  * **Pemindaian Kode QR**: Gunakan kamera perangkat Anda untuk memindai kode QR yang berisi soal-soal kuis.
  * **Pengalaman AR Interaktif**: Setelah memindai, model 3D papan kuis akan muncul di dunia nyata melalui teknologi AR, tempat Anda bisa menjawab pertanyaan.
  * **Sistem Poin**: Dapatkan poin untuk setiap jawaban yang benar dan lihat skor Anda diperbarui secara *real-time*.
  * **Papan Peringkat**: Lacak skor tim dan lihat peringkat Anda di papan peringkat global yang diperbarui secara langsung.
  * **Manajemen Lobi**: Bergabung dengan lobi tim untuk berkompetisi dengan teman-teman Anda.

-----

### Persyaratan Sistem

Pastikan Anda memiliki hal-hal berikut untuk menjalankan proyek ini:

  * **Flutter SDK**: Versi 3.x.x atau lebih baru.
  * **Dart SDK**: Versi 3.x.x atau lebih baru.
  * **Perangkat Seluler**: Ponsel Android atau iOS yang mendukung ARCore (Android) atau ARKit (iOS).
  * **Firebase CLI**: Diperlukan untuk konfigurasi Firebase.

-----

### Instalasi dan Pengaturan

1.  **Clone Repositori:**

    ```bash
    git clone [URL_REPOSITORI_ANDA]
    cd ar_quiz_app
    ```

2.  **Instal Dependensi Flutter:**

    ```bash
    flutter pub get
    ```

3.  **Pengaturan Firebase:**
    Aplikasi ini menggunakan Firebase sebagai *backend*. Anda harus menyiapkan proyek Firebase Anda sendiri.

      * Buat proyek baru di [Firebase Console](https://console.firebase.google.com/).
      * Aktifkan **Firestore Database**.
      * Instal Firebase CLI: `npm install -g firebase-tools`
      * Masuk ke akun Firebase Anda: `firebase login`
      * Jalankan perintah konfigurasi: `flutterfire configure`
      * Ikuti petunjuk di terminal untuk menghubungkan proyek Anda dengan Firebase.

4.  **Siapkan Data Kuis Dummy:**
    Aplikasi ini memerlukan data kuis di Firestore. Anda dapat menambahkan soal-soal dummy dengan menjalankan fungsi yang ada di `firebase_db.dart`.

5.  **Jalankan Aplikasi:**

    ```bash
    flutter run
    ```

-----
