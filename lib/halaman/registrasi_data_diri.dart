// Registrasi data diri.
part of 'package:nasabah_resik/main.dart';

// 2. REGISTRASI STEP 1 - DATA DIRI
// ---------------------------------------------------------------
class RegisterStep1 extends StatefulWidget {
  const RegisterStep1({super.key});

  @override
  State<RegisterStep1> createState() => _RegisterStep1State();
}

class _RegisterStep1State extends State<RegisterStep1> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          children: [
            const AuthTopBar(step: 1),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.recycling_rounded,
                        color: AppColors.green,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Yuk, mulai setor\nsampah!',
                      textAlign: TextAlign.center,
                      style: display(size: 22),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      'Daftar dulu untuk mulai kumpulkan saldo\ndari sampahmu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ),
                  const SizedBox(height: 20),
                  LabeledField(
                    label: 'Nama Lengkap',
                    hint: 'Contoh: Andi Wijaya',
                    controller: _nameController,
                  ),
                  LabeledField(
                    label: 'Nomor WhatsApp',
                    hint: '0812xxxx',
                    keyboard: TextInputType.phone,
                    controller: _phoneController,
                  ),
                  LabeledField(
                    label: 'Email',
                    hint: 'nama@email.com',
                    keyboard: TextInputType.emailAddress,
                    controller: _emailController,
                  ),
                  LabeledField(
                    label: 'Alamat / Kelurahan',
                    hint: 'Cari kelurahan Anda',
                    controller: _addressController,
                    trailingLabel: Text(
                      'Pakai lokasi saya',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            HardButton(
              label: 'Lanjut',
              onTap: () {
                final nama = _nameController.text.trim();
                final telepon = _normalizePhone(_phoneController.text);
                final email = _emailController.text.trim();
                if (nama.isEmpty) {
                  _showAuthPopup(
                    context,
                    title: 'Nama belum diisi',
                    message:
                        'Masukkan nama lengkap agar kami dapat mengenalimu.',
                    icon: Icons.person_outline_rounded,
                  );
                  return;
                }
                if (telepon.length < 8 || telepon.length > 15) {
                  _showAuthPopup(
                    context,
                    title: 'Nomor belum valid',
                    message:
                        'Masukkan nomor WhatsApp yang terdiri dari 8–15 digit.',
                    icon: Icons.phone_rounded,
                  );
                  return;
                }
                if (email.isNotEmpty &&
                    !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                  _showAuthPopup(
                    context,
                    title: 'Email belum valid',
                    message: 'Periksa kembali format alamat email yang kamu masukkan.',
                    icon: Icons.alternate_email_rounded,
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RegisterStep2(
                      nama: nama,
                      telepon: telepon,
                      email: email,
                      alamat: _addressController.text.trim(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            const OrDivider(),
            const SizedBox(height: 14),
            GoogleButton(
              background: _card,
              onTap: () => _showAuthPopup(
                context,
                title: 'Segera hadir',
                message: 'Pendaftaran dengan Google belum tersedia. Kamu dapat melanjutkan dengan mengisi data diri.',
                icon: Icons.auto_awesome_rounded,
              ),
            ),
            const SizedBox(height: 16),
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
