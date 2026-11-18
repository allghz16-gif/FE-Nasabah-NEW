// Registrasi kata sandi.
part of 'package:nasabah_resik/main.dart';

// 3. REGISTRASI STEP 2 - BUAT PASSWORD
// ---------------------------------------------------------------
class RegisterStep2 extends StatefulWidget {
  final String nama;
  final String telepon;
  final String email;
  final String alamat;
  const RegisterStep2({
    super.key,
    required this.nama,
    required this.telepon,
    required this.email,
    required this.alamat,
  });

  @override
  State<RegisterStep2> createState() => _RegisterStep2State();
}

class _RegisterStep2State extends State<RegisterStep2> {
  bool agree = false;
  bool loading = false;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  TextSpan _link(String t) => TextSpan(
    text: t,
    style: const TextStyle(
      fontWeight: FontWeight.w800,
      color: AppColors.dark,
      decoration: TextDecoration.underline,
    ),
  );

  Future<void> _submit() async {
    if (!agree) {
      await _showAuthPopup(
        context,
        title: 'Persetujuan diperlukan',
        message:
            'Setujui Syarat & Ketentuan dan Kebijakan Privasi terlebih dahulu.',
        icon: Icons.fact_check_outlined,
      );
      return;
    }
    if (_passwordController.text.length < 8 ||
        _passwordController.text != _confirmPasswordController.text) {
      await _showAuthPopup(
        context,
        title: 'Password perlu diperiksa',
        message: 'Gunakan password minimal 8 karakter dan pastikan konfirmasinya sama.',
        icon: Icons.password_rounded,
      );
      return;
    }
    setState(() => loading = true);
    try {
      await ApiService.register(
        nama: widget.nama,
        telepon: widget.telepon,
        password: _passwordController.text,
        email: widget.email.isEmpty ? null : widget.email,
        alamat: widget.alamat.isEmpty ? null : widget.alamat,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SuccessScreen(name: widget.nama)),
      );
    } catch (error) {
      if (!mounted) return;
      await _showAuthPopup(
        context,
        title: 'Pendaftaran belum berhasil',
        message: _authErrorMessage('Registrasi', error),
        icon: Icons.person_add_alt_1_rounded,
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          children: [
            const AuthTopBar(step: 2),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 22),
                  Center(
                    child: Text('Satu langkah lagi!', style: display(size: 22)),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      'Buat password yang kuat untuk\nkeamanan akunmu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ),
                  const SizedBox(height: 24),
                  LabeledField(
                    label: 'Password',
                    hint: '••••••••',
                    obscure: true,
                    controller: _passwordController,
                  ),
                  LabeledField(
                    label: 'Konfirmasi Password',
                    hint: '••••••••',
                    obscure: true,
                    controller: _confirmPasswordController,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: agree,
                          side: const BorderSide(
                            color: AppColors.dark,
                            width: 1.5,
                          ),
                          onChanged: (v) => setState(() => agree = v!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'Saya setuju dengan ',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.muted,
                            ),
                            children: [
                              _link('Syarat & Ketentuan'),
                              const TextSpan(text: ' dan '),
                              _link('Kebijakan Privasi'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
            const SizedBox(height: 36),
            HardButton(
              label: loading ? 'Memproses...' : 'Daftar Sekarang',
              onTap: loading ? () {} : _submit,
            ),
            const SizedBox(height: 14),
            BottomLink(
              text: 'Sudah punya akun?',
              action: 'Masuk',
              onTap: () => _goLogin(context),
            ),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------
