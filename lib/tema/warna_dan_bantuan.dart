// Warna, format angka, font, dan popup umum.
part of 'package:nasabah_resik/main.dart';


// ---------------------------------------------------------------
// WARNA & HELPER
// ---------------------------------------------------------------
class AppColors {
  static const bg = Color(0xFFF3EEE3); // krem
  static const dark = Color(0xFF17472A); // hijau tua
  static const green = Color(0xFF3B7A2F); // hijau
  static const orange = Color(0xFFE8582B); // aksen
  static const muted = Color(0xFF7A7A6E); // teks abu
}

String rupiah(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return 'Rp $buf';
}

/// Font judul / angka besar (serif display seperti di desain).
/// Kalau di Figma fontnya beda, ganti GoogleFonts.fraunces di sini saja.
TextStyle display({
  double size = 14,
  FontWeight weight = FontWeight.w800,
  Color color = AppColors.dark,
}) => GoogleFonts.fraunces(fontSize: size, fontWeight: weight, color: color);

Future<void> _showAuthPopup(
  BuildContext context, {
  required String title,
  required String message,
  required IconData icon,
  Color accent = AppColors.orange,
}) => showDialog<void>(
  context: context,
  builder: (dialogContext) => Dialog(
    backgroundColor: Colors.transparent,
    child: Container(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.dark, width: 1.5),
        boxShadow: const [
          BoxShadow(color: AppColors.dark, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 31),
          ),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: display(size: 22)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Mengerti',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);

