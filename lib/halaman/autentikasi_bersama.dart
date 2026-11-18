// Widget dan helper autentikasi.
part of 'package:nasabah_resik/main.dart';

const _line = Color(0xFFE6DFCF); // border krem, sama dengan AppCard
const _card = Color(0xFFFDFBF5);

void _goHome(BuildContext context) => Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(builder: (_) => const MainShell()),
  (r) => false,
);

void _goLogin(BuildContext context) => Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(builder: (_) => const LoginScreen()),
  (r) => false,
);

String _authErrorMessage(String action, Object error) {
  if (error is ApiException) return error.message;
  if (error is TimeoutException) {
    return 'Server tidak merespons. Periksa koneksi lalu coba lagi.';
  }
  return '$action gagal: $error';
}

String _normalizePhone(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('62')) return '0${digits.substring(2)}';
  if (digits.startsWith('8')) return '0$digits';
  return digits;
}

String _normalizeLoginIdentifier(String value) {
  final identifier = value.trim();
  if (identifier.contains('@')) return identifier.toLowerCase();
  if (RegExp(r'^[+0-9()\s.-]+$').hasMatch(identifier)) {
    return _normalizePhone(identifier);
  }
  return identifier;
}

// ---------------------------------------------------------------
// WIDGET BERSAMA
// ---------------------------------------------------------------
class AuthLogo extends StatelessWidget {
  final double size;
  const AuthLogo({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * .3),
    child: Image.asset(
      'assets/images/Overlay.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        color: AppColors.orange,
        child: Icon(Icons.eco_rounded, color: Colors.white, size: size * .5),
      ),
    ),
  );
}

class HardButton extends StatelessWidget {
  final String label;
  final IconData? trailing;
  final VoidCallback onTap;
  const HardButton({
    super.key,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => _Pressable(
    onTap: onTap,
    child: Container(
      height: 52,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: AppColors.dark, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Icon(trailing, color: Colors.white, size: 16),
          ],
        ],
      ),
    ),
  );
}

class GoogleButton extends StatelessWidget {
  final Color background;
  final VoidCallback onTap;
  const GoogleButton({
    super.key,
    required this.onTap,
    this.background = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) => _Pressable(
    onTap: onTap,
    child: Container(
      height: 48,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dark, width: 1.5),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'G',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4285F4),
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Lanjut dengan Google',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _Pressable({required this.child, required this.onTap});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) => AnimatedScale(
    scale: _pressed ? .97 : 1,
    duration: const Duration(milliseconds: 110),
    curve: Curves.easeOut,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
        onTapUp: widget.onTap == null ? null : (_) => _setPressed(false),
        onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
        borderRadius: BorderRadius.circular(12),
        child: widget.child,
      ),
    ),
  );
}

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(child: Divider(color: _line)),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          'ATAU',
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 1,
            color: AppColors.muted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      Expanded(child: Divider(color: _line)),
    ],
  );
}

class LabeledField extends StatelessWidget {
  final String label, hint;
  final bool obscure;
  final Widget? trailingLabel;
  final TextInputType? keyboard;
  final TextEditingController? controller;
  const LabeledField({
    super.key,
    required this.label,
    required this.hint,
    this.obscure = false,
    this.trailingLabel,
    this.keyboard,
    this.controller,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
              ),
            ),
            if (trailingLabel != null) trailingLabel!,
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboard,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13,
              color: AppColors.muted.withValues(alpha: .6),
            ),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.dark, width: 1.5),
            ),
          ),
        ),
      ],
    ),
  );
}

class BottomLink extends StatelessWidget {
  final String text, action;
  final Color actionColor;
  final VoidCallback onTap;
  const BottomLink({
    super.key,
    required this.text,
    required this.action,
    required this.onTap,
    this.actionColor = AppColors.dark,
  });

  @override
  Widget build(BuildContext context) => _Pressable(
    onTap: onTap,
    child: Text.rich(
      TextSpan(
        text: '$text ',
        style: const TextStyle(fontSize: 12, color: AppColors.muted),
        children: [
          TextSpan(
            text: action,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: actionColor,
            ),
          ),
        ],
      ),
    ),
  );
}

class AuthTopBar extends StatelessWidget {
  final int step; // 1 atau 2
  const AuthTopBar({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    Widget seg(Color c) => Expanded(
      child: Container(
        height: 3,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
    final off = Colors.white.withValues(alpha: .8);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const AuthLogo(size: 36),
            const Text(
              'Daftar Akun',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            seg(step == 1 ? AppColors.orange : AppColors.dark),
            const SizedBox(width: 4),
            seg(step == 2 ? AppColors.orange : off),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DATA DIRI',
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                letterSpacing: .5,
                color: step == 1 ? AppColors.orange : AppColors.muted,
              ),
            ),
            Text(
              'BUAT PASSWORD',
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                letterSpacing: .5,
                color: step == 2 ? AppColors.orange : AppColors.muted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------
