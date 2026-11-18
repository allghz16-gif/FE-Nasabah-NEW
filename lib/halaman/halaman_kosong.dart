// Halaman placeholder.
part of 'package:nasabah_resik/main.dart';

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Halaman $title (belum dibuat)'),
        if (title == 'Profil')
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PasswordResetScreen()),
            ),
            child: const Text('Lupa Password?'),
          ),
      ],
    ),
  );
}

