// Login dan pemulihan kata sandi.
part of 'package:nasabah_resik/main.dart';

// 1. LOGIN
// ---------------------------------------------------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool remember = false, hide = true;
  bool _loading = false;
  bool _rememberPreferenceChanged = false;
  bool _loginEdited = false;
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _restoreRememberedLogin();
  }

  Future<void> _restoreRememberedLogin() async {
    final values = await Future.wait<Object?>([
      ApiService.getRememberMePreference(),
      ApiService.getRememberedLogin(),
    ]);
    if (!mounted) return;
    final shouldRemember = values[0] as bool? ?? false;
    final rememberedLogin = values[1] as String?;
    setState(() {
      if (!_rememberPreferenceChanged) remember = shouldRemember;
      if (!_loginEdited &&
          shouldRemember &&
          rememberedLogin != null &&
          rememberedLogin.isNotEmpty) {
        _loginController.text = rememberedLogin;
      }
    });
  }

  Future<void> _setRememberMe(bool value) async {
    setState(() {
      _rememberPreferenceChanged = true;
      remember = value;
    });
    await ApiService.saveRememberMe(value);
    final identifier = _loginController.text.trim();
    if (value && identifier.isNotEmpty) {
      await ApiService.saveRememberedLogin(identifier);
    } else if (!value) {
      await ApiService.clearRememberedLogin();
    }
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loginController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      await _showAuthPopup(
        context,
        title: 'Data belum lengkap',
        message: 'Masukkan nomor telepon atau email dan password untuk masuk.',
        icon: Icons.edit_note_rounded,
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiService.login(
        teleponAtauEmail: _normalizeLoginIdentifier(_loginController.text),
        password: _passwordController.text,
        rememberMe: remember,
      );
      if (mounted) _goHome(context);
    } catch (error) {
      if (!mounted) return;
      await _showAuthPopup(
        context,
        title: 'Login belum berhasil',
        message: _authErrorMessage('Login', error),
        icon: Icons.lock_outline_rounded,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _dec(String hint, IconData icon, {Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 12,
          color: AppColors.muted.withValues(alpha: .6),
        ),
        prefixIcon: Icon(icon, size: 16, color: AppColors.muted),
        suffixIcon: suffix,
        filled: true,
        fillColor: _card,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.dark, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const AuthLogo(),
              const SizedBox(height: 22),
              Text(
                'Selamat Datang',
                style: display(size: 28, weight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Masuk untuk lanjut setor sampah dan\nkumpulkan saldomu.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.dark, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: AppColors.dark, offset: Offset(0, 5)),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _loginController,
                      style: const TextStyle(fontSize: 13),
                      onChanged: (value) {
                        _loginEdited = true;
                        if (remember && value.trim().isNotEmpty) {
                          ApiService.saveRememberedLogin(value.trim());
                        }
                      },
                      decoration: _dec(
                        'WhatsApp atau Email',
                        Icons.phone_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: hide,
                      style: const TextStyle(fontSize: 13),
                      decoration: _dec(
                        'Password',
                        Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(
                            hide
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                            color: AppColors.dark,
                          ),
                          onPressed: () => setState(() => hide = !hide),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: Checkbox(
                            value: remember,
                            side: const BorderSide(color: AppColors.dark),
                            onChanged: (value) =>
                                _setRememberMe(value ?? false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _Pressable(
                          onTap: _loading
                              ? null
                              : () => _setRememberMe(!remember),
                          child: const Text(
                            'Ingat saya',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: AppColors.dark,
                            ),
                          ),
                        ),
                        const Spacer(),
                        _Pressable(
                          onTap: _loading
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PasswordResetScreen(),
                                  ),
                                ),
                          child: const Text(
                            'Lupa Password?',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    HardButton(
                      label: _loading ? 'Memproses...' : 'Masuk',
                      trailing: Icons.arrow_forward,
                      onTap: _loading ? () {} : _login,
                    ),
                    const SizedBox(height: 14),
                    const OrDivider(),
                    const SizedBox(height: 14),
                    GoogleButton(
                      onTap: () => _showAuthPopup(
                        context,
                        title: 'Segera hadir',
                        message: 'Login dengan Google belum tersedia. Silakan masuk menggunakan nomor telepon atau email.',
                        icon: Icons.auto_awesome_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              BottomLink(
                text: 'Belum punya akun?',
                action: 'Daftar',
                actionColor: AppColors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterStep1()),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                '© 2026 RESIK ECOSYSTEM',
                style: TextStyle(fontSize: 9, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _codeSent = false;
  bool _loading = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _requestCode() async {
    final email = _emailController.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showMessage('Masukkan alamat email yang valid.');
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await ApiService.requestPasswordReset(email: email);
      if (!mounted) return;
      setState(() => _codeSent = true);
      _showMessage(
        result['message']?.toString() ??
            'Jika email terdaftar, kode verifikasi akan dikirim.',
      );
    } catch (error) {
      if (mounted) _showMessage(_authErrorMessage('Permintaan kode', error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final otp = _otpController.text.trim();
    final password = _passwordController.text;
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      _showMessage('Masukkan kode verifikasi 6 digit.');
      return;
    }
    if (password.length < 8) {
      _showMessage('Password baru minimal 8 karakter.');
      return;
    }
    if (password != _confirmPasswordController.text) {
      _showMessage('Konfirmasi password tidak sama.');
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await ApiService.completePasswordReset(
        email: _emailController.text,
        otp: otp,
        password: password,
      );
      if (!mounted) return;
      final message =
          result['message']?.toString() ??
          'Password berhasil diubah. Silakan masuk kembali.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (error) {
      if (mounted) _showMessage(_authErrorMessage('Reset password', error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Kembali',
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: AppColors.dark),
                  ),
                  const Spacer(),
                  const AuthLogo(size: 36),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                _codeSent ? 'Verifikasi Email' : 'Lupa Password?',
                style: display(size: 26, weight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                _codeSent
                    ? 'Masukkan kode yang dikirim ke email, lalu buat password baru.'
                    : 'Masukkan email yang terhubung dengan akun RESIK untuk menerima kode verifikasi.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.dark, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: AppColors.dark, offset: Offset(0, 5)),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      enabled: !_codeSent && !_loading,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'nama@email.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    if (_codeSent) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: _otpController,
                        enabled: !_loading,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: 'Kode verifikasi',
                          hintText: '6 digit',
                          prefixIcon: Icon(Icons.password_outlined),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        enabled: !_loading,
                        obscureText: _hidePassword,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: InputDecoration(
                          labelText: 'Password baru',
                          hintText: 'Minimal 8 karakter',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _hidePassword
                                ? 'Tampilkan password'
                                : 'Sembunyikan password',
                            onPressed: () =>
                                setState(() => _hidePassword = !_hidePassword),
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _confirmPasswordController,
                        enabled: !_loading,
                        obscureText: _hidePassword,
                        decoration: const InputDecoration(
                          labelText: 'Konfirmasi password baru',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    HardButton(
                      label: _loading
                          ? 'Memproses...'
                          : _codeSent
                          ? 'Ubah Password'
                          : 'Kirim Kode',
                      onTap: _loading
                          ? () {}
                          : _codeSent
                          ? _resetPassword
                          : _requestCode,
                    ),
                    if (_codeSent) ...[
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => setState(() {
                                _codeSent = false;
                                _otpController.clear();
                                _passwordController.clear();
                                _confirmPasswordController.clear();
                              }),
                        child: const Text('Ganti email'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------
