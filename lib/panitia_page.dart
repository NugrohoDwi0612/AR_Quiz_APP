import 'package:flutter/material.dart';
import 'download_qr_page.dart';
import 'buat_lobby_page.dart';

class PanitiaPage extends StatelessWidget {
  const PanitiaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo diposisikan di atas
            Image.asset('assets/images/logo.png', width: 100),
            const SizedBox(height: 20),
            const Text(
              'PANITIA',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 50),
            _buildCustomButton(context, 'Buat lobby', () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const BuatLobbyPage()));
            }),
            const SizedBox(height: 20),
            _buildCustomButton(context, 'Download QR Code', () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DownloadQRPage()));
            }),
            const SizedBox(height: 20),
            _buildCustomButton(
                context, 'Kembali', () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomButton(
      BuildContext context, String text, VoidCallback onPressed) {
    return Container(
      width: 250,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
