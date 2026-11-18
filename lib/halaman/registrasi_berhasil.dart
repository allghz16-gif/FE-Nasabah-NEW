// Layar registrasi berhasil.
part of 'package:nasabah_resik/main.dart';

// 4. REGISTRASI BERHASIL
// ---------------------------------------------------------------
class SuccessScreen extends StatelessWidget {
  final String name;
  const SuccessScreen({super.key, this.name = 'Budi Santoso'});

  Widget _dot() => Container(
    width: 6,
    height: 6,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.muted,
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        // dekorasi daun
        Positioned(
          top: -10,
          right: 10,
          child: Transform.rotate(
            angle: .5,
            child: Container(
              width: 130,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: .15),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(90),
                  bottomRight: Radius.circular(90),
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 130,
                          height: 130,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.bg,
                                  border: Border.all(color: _line),
                                ),
                              ),
                              Container(
                                width: 84,
                                height: 84,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.dark,
                                ),
                              ),
                              const Positioned(
                                right: 6,
                                top: 4,
                                child: AuthLogo(size: 24),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Akun Berhasil\nDibuat!',
                          textAlign: TextAlign.center,
                          style: display(size: 26),
                        ),
                        const SizedBox(height: 14),
                        Text.rich(
                          TextSpan(
                            text: 'Selamat datang di ',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              height: 1.5,
                            ),
                            children: [
                              const TextSpan(
                                text: 'RESIK',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.dark,
                                ),
                              ),
                              const TextSpan(text: ', '),
                              TextSpan(
                                text: name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.dark,
                                ),
                              ),
                              const TextSpan(
                                text: '. Kamu sekarang bisa mulai menyetor sampah dan mengumpulkan saldo.',
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 26),
                        HardButton(
                          label: 'Mulai Sekarang',
                          onTap: () => _goHome(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _dot(),
                      const SizedBox(width: 6),
                      Container(
                        width: 26,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.muted,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _dot(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

