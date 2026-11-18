// Fitur tukar saldo.
part of 'package:nasabah_resik/main.dart';

// LAYAR: TUKAR SALDO (E-Wallet & Transfer Bank)
// ---------------------------------------------------------------

/// Format angka jadi 150.000 saat mengetik.
class RibuanFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    final text = rupiah(int.parse(digits)).substring(3); // buang "Rp "
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Kotak dengan border putus-putus (kartu ringkasan & tombol tambah).
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

class TukarSaldoPage extends StatefulWidget {
  final VoidCallback? onBack;
  const TukarSaldoPage({super.key, this.onBack});

  @override
  State<TukarSaldoPage> createState() => _TukarSaldoPageState();
}

class _TukarSaldoPageState extends State<TukarSaldoPage> {
  static const int minimal = 50000;
  static const int biayaLayanan = 1000;

  int saldo = 0;
  bool loading = true;
  bool submitting = false;
  final controller = TextEditingController(text: '150.000');
  final destinationController = TextEditingController();
  int amount = 150000;
  int method = 0; // 0 = E-Wallet, 1 = Transfer Bank
  int provider = 0; // index provider pada daftar metode yang aktif
  final quickAmounts = [50000, 100000, 150000, 200000];

  // daftar provider untuk tiap metode
  static const ewallets = ['Gopay', 'Dana', 'OVO', 'ShopeePay'];
  static const banks = ['Mandiri', 'BCA', 'BNI', 'BRI'];
  List<String> get providers => method == 0 ? ewallets : banks;

  // riwayat penarikan (terbaru di index 0)
  final List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final profile =
          (await ApiService.getProfilSaya())['data'] as Map<String, dynamic>;
      final response = await ApiService.getRiwayatTransaksi(tipe: 'keluar');
      final transactions = response['data'] as List<dynamic>;
      if (!mounted) return;
      setState(() {
        saldo = (num.tryParse('${profile['saldo']}') ?? 0).round();
        history
          ..clear()
          ..addAll(
            transactions.whereType<Map<String, dynamic>>().map(
              (item) => {
                'name':
                    '${item['metode'] ?? 'Penarikan'} - ${item['nomor_tujuan'] ?? ''}',
                'date':
                    DateTime.tryParse('${item['created_at']}')
                        ?.toLocal()
                        .toString()
                        .substring(0, 10) ??
                    '',
                'amount': (num.tryParse('${item['jumlah']}') ?? 0).round(),
              },
            ),
          );
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal memuat saldo: $error')));
    }
  }

  @override
  void dispose() {
    controller.dispose();
    destinationController.dispose();
    super.dispose();
  }

  void setAmount(int v) {
    setState(() {
      amount = v;
      controller.text = rupiah(v).substring(3);
    });
  }

  Future<void> _submit() async {
    if (amount < minimal) {
      await _showNoticeDialog(
        icon: Icons.info_outline_rounded,
        title: 'Nominal belum memenuhi minimum',
        message: 'Minimal penukaran saldo adalah ${rupiah(minimal)}.',
        actionLabel: 'Ubah nominal',
      );
      return;
    }

    if (destinationController.text.trim().isEmpty) {
      final enteredDestination = await _showDestinationDialog();
      if (enteredDestination != true || !mounted) return;
    }

    final totalDebit = amount + biayaLayanan;
    if (totalDebit > saldo) {
      await _showInsufficientBalanceDialog(totalDebit);
      return;
    }

    final confirmed = await _showExchangeConfirmation(totalDebit);
    if (confirmed != true || !mounted) return;

    await _performWithdrawal();
  }

  Future<bool?> _showDestinationDialog() {
    String? validationMessage;
    return showDialog<bool>(
      context: context,
      builder: (routeContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF8),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFE6DFCF)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3317472A),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogIcon(Icons.account_balance_wallet_outlined),
                const SizedBox(height: 16),
                Text('Masukkan nomor tujuan', style: display(size: 21)),
                const SizedBox(height: 7),
                Text(
                  'Nomor tujuan ${providers[provider]} diperlukan untuk memproses penukaran saldo.',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  key: const Key('exchange-destination-dialog-field'),
                  controller: destinationController,
                  autofocus: true,
                  keyboardType: TextInputType.phone,
                  onChanged: (_) {
                    if (validationMessage != null) {
                      setDialogState(() => validationMessage = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: method == 0
                        ? 'Nomor e-wallet tujuan'
                        : 'Nomor rekening tujuan',
                    prefixIcon: const Icon(Icons.phone_android_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    errorText: validationMessage,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.dark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          if (destinationController.text.trim().isEmpty) {
                            setDialogState(
                              () => validationMessage =
                                  'Nomor tujuan wajib diisi.',
                            );
                            return;
                          }
                          Navigator.pop(dialogContext, true);
                        },
                        child: const Text('Lanjutkan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showInsufficientBalanceDialog(int totalDebit) {
    final shortfall = totalDebit - saldo;
    return _showNoticeDialog(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Saldo tidak cukup',
      message:
          'Saldo tersedia ${rupiah(saldo)}. Total yang dibutuhkan ${rupiah(totalDebit)} termasuk biaya layanan ${rupiah(biayaLayanan)}. Tambahkan saldo atau kurangi nominal sebesar minimal ${rupiah(shortfall)}.',
      actionLabel: 'Ubah nominal',
      secondaryLabel: 'Mengerti',
    );
  }

  Future<void> _showNoticeDialog({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    String? secondaryLabel,
  }) => showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF8),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFE6DFCF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3317472A),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dialogIcon(icon),
            const SizedBox(height: 16),
            Text(title, style: display(size: 21)),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.dark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(actionLabel),
              ),
            ),
            if (secondaryLabel != null)
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(secondaryLabel),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Future<bool?> _showExchangeConfirmation(int totalDebit) => showDialog<bool>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF8),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFE6DFCF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3317472A),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dialogIcon(Icons.payments_outlined),
            const SizedBox(height: 16),
            Text('Konfirmasi penukaran', style: display(size: 21)),
            const SizedBox(height: 6),
            const Text(
              'Pastikan detail tujuan dan nominal sudah benar.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            _confirmationRow('Metode', providers[provider]),
            _confirmationRow('Nomor tujuan', destinationController.text.trim()),
            _confirmationRow('Dana diterima', rupiah(amount)),
            _confirmationRow('Biaya layanan', rupiah(biayaLayanan)),
            const Divider(height: 20),
            _confirmationRow(
              'Total potong saldo',
              rupiah(totalDebit),
              emphasize: true,
            ),
            _confirmationRow('Sisa saldo', rupiah(saldo - totalDebit)),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('confirm-exchange-button'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.dark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Tukar sekarang'),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Periksa kembali'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _dialogIcon(IconData icon) => Container(
    width: 52,
    height: 52,
    decoration: BoxDecoration(
      color: const Color(0xFFFADBD0),
      borderRadius: BorderRadius.circular(17),
    ),
    child: Icon(icon, color: AppColors.orange, size: 27),
  );

  Widget _confirmationRow(
    String label,
    String value, {
    bool emphasize = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: emphasize ? AppColors.dark : AppColors.muted,
              fontSize: 12,
              fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: emphasize ? AppColors.orange : AppColors.dark,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _performWithdrawal() async {
    if (submitting) return;
    setState(() => submitting = true);
    Map<String, dynamic> withdrawal;
    try {
      final response = await ApiService.tarikSaldo(
        jumlah: amount,
        metode: providers[provider],
        nomorTujuan: destinationController.text.trim(),
      );
      withdrawal = response['data'] as Map<String, dynamic>;
    } catch (error) {
      if (!mounted) return;
      if (error.toString().toLowerCase().contains('saldo tidak cukup')) {
        await _showInsufficientBalanceDialog(amount + biayaLayanan);
      } else {
        await _showNoticeDialog(
          icon: Icons.error_outline_rounded,
          title: 'Penukaran belum berhasil',
          message: 'Permintaan gagal diproses: $error',
          actionLabel: 'Coba lagi',
        );
      }
      return;
    } finally {
      if (mounted) setState(() => submitting = false);
    }
    if (!mounted) return;

    // popup "PENUKARAN BERHASIL"
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black38,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 30),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.dark, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.dark, width: 2.5),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 32,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'PENUKARAN BERHASIL',
                style: display(size: 14, weight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );

    // catat ke riwayat & kurangi saldo
    final now = DateTime.now();
    setState(() {
      saldo = (num.tryParse('${withdrawal['saldo_akhir']}') ?? saldo).round();
      history.insert(0, {
        'name': '${withdrawal['metode']} - ${withdrawal['nomor_tujuan']}',
        'date': '${now.day}/${now.month}/${now.year}',
        'amount': (num.tryParse('${withdrawal['jumlah']}') ?? amount).round(),
      });
    });

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // tutup popup
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _topBar(),
          const SizedBox(height: 18),
          _saldoCard(),
          const SizedBox(height: 22),
          _label('METODE PENARIKAN'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _methodBox(0, Icons.smartphone_rounded, 'E-Wallet'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _methodBox(
                  1,
                  Icons.account_balance_rounded,
                  'Transfer Bank',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _providerRow(),
          const SizedBox(height: 12),
          _destinationField(),
          const SizedBox(height: 14),
          _nominalBox(),
          const SizedBox(height: 8),
          Text(
            '*Minimal Penarikan ${rupiah(minimal)}',
            style: TextStyle(
              fontSize: 11,
              color: amount < minimal ? AppColors.orange : AppColors.muted,
            ),
          ),
          const SizedBox(height: 10),
          _quickChips(),
          const SizedBox(height: 18),
          _summaryCard(),
          const SizedBox(height: 22),
          _submitButton(),
          const SizedBox(height: 26),
          Row(
            children: [
              _label('TARIK TERAKHIR'),
              const Spacer(),
              const Text(
                'LIHAT SEMUA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _historyTile(),
        ],
      ),
    );
  }

  // ---------- bagian-bagian layar ----------
  Widget _topBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: widget.onBack,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.dark, width: 1.5),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: AppColors.dark,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text('Tukar Saldo', style: display(size: 22)),
        const Spacer(),
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.dark,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.eco, size: 15, color: Colors.white),
        ),
      ],
    );
  }

  Widget _saldoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: AppColors.orange, offset: Offset(5, 5)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SALDO TERSEDIA',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  rupiah(saldo),
                  style: display(size: 32, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.eco, size: 11, color: Colors.white70),
                      SizedBox(width: 5),
                      Text(
                        'Eco-Warrior Level 2',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 40,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      letterSpacing: 1.2,
      fontWeight: FontWeight.w600,
      color: AppColors.muted,
    ),
  );

  Widget _providerRow() {
    final list = providers;
    return Row(
      children: [
        for (int i = 0; i < list.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == list.length - 1 ? 0 : 8),
              child: GestureDetector(
                onTap: () => setState(() => provider = i),
                child: Container(
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: provider == i ? AppColors.dark : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.dark),
                  ),
                  child: Text(
                    list[i],
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: provider == i ? Colors.white : AppColors.dark,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _destinationField() => TextField(
    controller: destinationController,
    keyboardType: TextInputType.phone,
    decoration: InputDecoration(
      labelText: method == 0
          ? 'Nomor e-wallet tujuan'
          : 'Nomor rekening tujuan',
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  Widget _methodBox(int i, IconData icon, String label) {
    final selected = method == i;
    return GestureDetector(
      onTap: () => setState(() {
        method = i;
        provider = 0;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.orange : const Color(0xFFE6DFCF),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFFADBD0)
                    : const Color(0xFFEDE9DF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 19,
                color: selected ? AppColors.orange : AppColors.muted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? AppColors.dark : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nominalBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.dark, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NOMINAL PENARIKAN',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Rp',
                style: display(
                  size: 26,
                  weight: FontWeight.w700,
                  color: const Color(0xFF9AA598),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                    RibuanFormatter(),
                  ],
                  style: display(size: 30),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (v) => setState(
                    () => amount = int.tryParse(v.replaceAll('.', '')) ?? 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickChips() {
    return Row(
      children: [
        for (int i = 0; i < quickAmounts.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: i == quickAmounts.length - 1 ? 0 : 8,
              ),
              child: GestureDetector(
                onTap: () => setAmount(quickAmounts[i]),
                child: Container(
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: amount == quickAmounts[i]
                        ? AppColors.dark
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.dark),
                  ),
                  child: Text(
                    '${quickAmounts[i] ~/ 1000}k',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: amount == quickAmounts[i]
                          ? Colors.white
                          : AppColors.dark,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _summaryCard() {
    return CustomPaint(
      foregroundPainter: const _DashedBorderPainter(
        color: Color(0xFFB9B3A2),
        radius: 16,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEDE8DA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _summaryRow('Biaya Layanan', rupiah(biayaLayanan)),
            _summaryRow('Estimasi Tiba', 'Instan ( < 10 Menit )'),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Divider(height: 1, color: Color(0xFFD8D2C2)),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Diterima',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark,
                    ),
                  ),
                  Text(
                    rupiah(amount),
                    style: display(size: 18, color: AppColors.orange),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _submitButton() {
    return GestureDetector(
      onTap: submitting ? null : _submit,
      child: Container(
        height: 58,
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: AppColors.dark,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: AppColors.orange, offset: Offset(5, 5)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              submitting
                  ? Icons.hourglass_top_rounded
                  : Icons.payments_outlined,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Text(
              submitting ? 'Memproses...' : 'Tukar Sekarang',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyTile() {
    if (history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6DFCF)),
        ),
        child: const Row(
          children: [
            Icon(Icons.credit_card_rounded, size: 20, color: AppColors.muted),
            SizedBox(width: 10),
            Text(
              'Belum ada riwayat penarikan',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      );
    }
    final last = history.first;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6DFCF)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE6E0CF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.credit_card_rounded,
              size: 17,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  last['name'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  last['date'] as String,
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Text(
            rupiah(last['amount'] as int),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ===============================================================
// AUTH: LOGIN, REGISTRASI STEP 1 & 2, SUKSES
// ===============================================================

