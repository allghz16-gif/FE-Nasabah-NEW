// Dashboard dan ringkasan beranda.
part of 'package:nasabah_resik/main.dart';

// LAYAR: BERANDA (RESIK)
// ---------------------------------------------------------------
class CardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final bool light;
  const CardHeader({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white70 : AppColors.muted;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: light ? Colors.white12 : AppColors.bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class DashedLine extends StatelessWidget {
  final Color color;
  const DashedLine({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final n = (box.maxWidth / 8).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            n,
            (_) => Container(width: 4, height: 1.5, color: color),
          ),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback? onNotifications;
  final VoidCallback? onChat;
  final VoidCallback? onProfile;

  const HomePage({
    super.key,
    this.onNotifications,
    this.onChat,
    this.onProfile,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _name = '';
  int? _balance;
  double? _totalKg;
  int? _transactionCount;
  double _monthKg = 0;
  int _monthCredit = 0;
  int _unreadNotifications = 0;
  List<Map<String, dynamic>> _monthlyDeposits = [];
  List<Map<String, dynamic>> _recentDeposits = [];
  List<Map<String, dynamic>> _recentTransactions = [];
  List<Map<String, dynamic>> _prices = [];
  List<Map<String, dynamic>> _dropPoints = [];
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    try {
      final response = await ApiService.getDashboardSaya();
      final dashboard = response['data'];
      if (dashboard is! Map<String, dynamic>) {
        throw ApiException('Data dashboard tidak valid', 500);
      }
      final profile = dashboard['profile'];
      final summary = dashboard['summary'];
      if (profile is! Map<String, dynamic> ||
          summary is! Map<String, dynamic>) {
        throw ApiException('Ringkasan dashboard tidak lengkap', 500);
      }
      final now = DateTime.now();
      final monthlyDeposits = _rows(dashboard['monthly_deposits']);
      final currentMonth = monthlyDeposits.where(
        (item) =>
            _integer(item['tahun']) == now.year &&
            _integer(item['bulan']) == now.month,
      );
      final currentMonthKg = currentMonth.fold<double>(
        0,
        (total, item) => total + _decimal(item['total_kg']),
      );
      final recentDeposits = _rows(dashboard['recent_deposits']);
      final recentTransactions = _rows(dashboard['recent_transactions']);
      if (!mounted) return;
      setState(() {
        _name = (profile['nama'] as String?) ?? '';
        _balance = (num.tryParse('${profile['saldo']}') ?? 0).round();
        _totalKg = num.tryParse('${profile['total_setoran']}')?.toDouble() ?? 0;
        _transactionCount = _integer(summary['jumlah_transaksi']);
        _monthKg = currentMonthKg;
        _monthCredit = _integer(summary['saldo_masuk_bulan_ini']);
        _unreadNotifications = _integer(summary['notifikasi_belum_dibaca']);
        _monthlyDeposits = monthlyDeposits;
        _recentDeposits = recentDeposits;
        _recentTransactions = recentTransactions;
        _prices = _rows(dashboard['prices']);
        _dropPoints = _rows(dashboard['drop_points']);
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error.toString());
    }
  }

  List<Map<String, dynamic>> _rows(dynamic value) {
    if (value is! List) return [];
    return value.whereType<Map<String, dynamic>>().toList();
  }

  int _integer(dynamic value) => num.tryParse('$value')?.round() ?? 0;

  double _decimal(dynamic value) => num.tryParse('$value')?.toDouble() ?? 0;

  String _formatToday() {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final now = DateTime.now();
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  DateTime? _parseDate(dynamic value) => DateTime.tryParse('$value');

  String _formatDateTime(dynamic value) {
    final date = _parseDate(value)?.toLocal();
    if (date == null) return 'Waktu tidak tersedia';
    final now = DateTime.now();
    final day = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    final dayLabel = day == today
        ? 'Hari ini'
        : day == today.subtract(const Duration(days: 1))
        ? 'Kemarin'
        : '${date.day}/${date.month}/${date.year}';
    return '$dayLabel · ${date.hour.toString().padLeft(2, '0')}.${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(dynamic value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) return '--:--';
    return text.length >= 5 ? text.substring(0, 5) : text;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 18),
          Text(
            'Halo, ${_name.isEmpty ? 'Nasabah' : _name}',
            style: display(size: 26),
          ),
          Text(
            _formatToday(),
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          if (_loadError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Gagal memuat data dashboard: $_loadError',
                      style: const TextStyle(color: Colors.red, fontSize: 11),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadOverview,
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          _saldoCard(),
          _targetCard(),
          _chartCard(),
          _priceCard(),
          _transaksiCard(),
          _mapCard(),
        ],
      ),
    );
  }

  // ---------- Header ----------
  Widget _header() {
    return Row(
      children: [
        // Logo RESIK (assets/images/Overlay.png)
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/Overlay.png',
            width: 30,
            height: 30,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 8),
        Text('RESIK', style: display(size: 20)),
        const Spacer(),
        IconButton(
          tooltip: 'Notifikasi',
          onPressed: widget.onNotifications,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.orange,
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: -5,
                  top: -5,
                  child: CircleAvatar(
                    radius: 7,
                    backgroundColor: AppColors.orange,
                    child: Text(
                      _unreadNotifications > 9 ? '9+' : '$_unreadNotifications',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          key: const Key('dashboard-chatbot-button'),
          onTap: widget.onChat,
          customBorder: const CircleBorder(),
          child: const CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.green,
            child: Icon(Icons.eco, size: 15, color: Colors.white),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          key: const Key('dashboard-profile-button'),
          onTap: widget.onProfile,
          customBorder: const CircleBorder(),
          child: CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.dark,
            child: Text(
              _name.isEmpty ? 'N' : _name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------- Saldo tabungan ----------
  Widget _saldoCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(
            icon: Icons.account_balance_wallet_outlined,
            title: 'SALDO TABUNGAN',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE3EDD9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Saldo RESIK',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.green,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Rp', style: display(size: 16, weight: FontWeight.w400)),
              const SizedBox(width: 6),
              Text(
                _balance == null ? '—' : rupiah(_balance!).substring(3),
                style: display(size: 44),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: Stat(
                  label: 'SETORAN',
                  value: _totalKg == null
                      ? '—'
                      : '${_totalKg!.toStringAsFixed(1)} kg',
                ),
              ),
              Expanded(
                child: Stat(
                  label: 'SALDO MASUK BULAN INI',
                  value: rupiah(_monthCredit),
                ),
              ),
              Expanded(
                child: Stat(
                  label: 'TRANSAKSI',
                  value: _transactionCount?.toString() ?? '—',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Target September (kartu hijau tua) ----------
  Widget _targetCard() {
    const targetKg = 20.0;
    final progress = (_monthKg / targetKg).clamp(0.0, 1.0);
    final remaining = (targetKg - _monthKg).clamp(0.0, targetKg);
    return AppCard(
      color: AppColors.dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHeader(
            icon: Icons.track_changes,
            title: 'TARGET BULAN INI',
            light: true,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 84,
                      height: 84,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        color: AppColors.orange,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(progress * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          'tercapai',
                          style: TextStyle(color: Colors.white70, fontSize: 9),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_monthKg.toStringAsFixed(1)} / ${targetKg.toStringAsFixed(0)} kg',
                      style: display(size: 24, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      remaining == 0
                          ? 'Target bulanan tercapai. Terima kasih sudah memilah sampah!'
                          : 'Kurang ${remaining.toStringAsFixed(1)} kg untuk mencapai target bulan ini.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 26, color: Colors.white24),
          Row(
            children: [
              Expanded(
                child: Stat(
                  label: 'SETORAN BULAN INI',
                  value: '${_monthKg.toStringAsFixed(1)} kg',
                  light: true,
                ),
              ),
              Expanded(
                child: Stat(
                  label: 'SALDO MASUK BULAN INI',
                  value: rupiah(_monthCredit),
                  light: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Grafik setoran 6 bulan ----------
  Widget _chartCard() {
    final now = DateTime.now();
    final monthRows = <Map<String, dynamic>>[];
    for (var offset = 5; offset >= 0; offset--) {
      final month = DateTime(now.year, now.month - offset);
      final result = _monthlyDeposits.where(
        (item) =>
            _integer(item['tahun']) == month.year &&
            _integer(item['bulan']) == month.month,
      );
      monthRows.add({
        'label': _shortMonth(month.month),
        'kg': result.fold<double>(
          0,
          (total, item) => total + _decimal(item['total_kg']),
        ),
        'current': month.year == now.year && month.month == now.month,
      });
    }
    final maxKg = monthRows.fold<double>(20, (maximum, item) {
      final kg = item['kg'] as double;
      return kg > maximum ? kg : maximum;
    });
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(
            icon: Icons.bar_chart_rounded,
            title: 'SETORAN 6 BULAN',
            trailing: const Text(
              'kg / bulan',
              style: TextStyle(fontSize: 10, color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: Stack(
              children: [
                Positioned(
                  top: 120 - 92 * (20 / maxKg),
                  left: 0,
                  right: 0,
                  child: const DashedLine(color: AppColors.orange),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: monthRows
                      .map(
                        (item) => _Bar(
                          label: item['label'] as String,
                          kg: item['kg'] as double,
                          maxKg: maxKg,
                          highlight: item['current'] as bool,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Harga hari ini ----------
  String _shortMonth(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ][month - 1];

  Widget _priceCard() {
    const iconBackgrounds = [
      Color(0xFFE3EDD9),
      Color(0xFFFBEBC8),
      Color(0xFFFADBD0),
    ];
    final now = DateTime.now();
    return AppCard(
      child: Column(
        children: [
          CardHeader(
            icon: Icons.sell_outlined,
            title: 'HARGA HARI INI',
            trailing: Text(
              '${now.day} ${_shortMonth(now.month)}',
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 8),
          if (_prices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Belum ada harga material aktif.'),
            )
          else
            for (var i = 0; i < _prices.length; i++)
              _PriceRow(
                icon: _priceIcon(_prices[i]['nama']?.toString() ?? ''),
                iconBg: iconBackgrounds[i % iconBackgrounds.length],
                name: _prices[i]['nama']?.toString() ?? 'Material',
                sub:
                    _prices[i]['keterangan']?.toString() ??
                    'Harga berlaku per ${_prices[i]['satuan'] ?? 'kg'}',
                price:
                    '${rupiah(_integer(_prices[i]['harga_per_kg']))}/${_prices[i]['satuan'] ?? 'kg'}',
              ),
        ],
      ),
    );
  }

  IconData _priceIcon(String name) {
    final value = name.toLowerCase();
    if (value.contains('organik') || value.contains('minyak')) {
      return Icons.eco_outlined;
    }
    if (value.contains('plastik')) return Icons.local_drink_outlined;
    if (value.contains('kertas') || value.contains('kardus')) {
      return Icons.inventory_2_outlined;
    }
    return Icons.recycling_rounded;
  }

  // ---------- Aktivitas terbaru ----------
  Widget _transaksiCard() {
    final activities = <Map<String, dynamic>>[
      ..._recentDeposits.map(
        (item) => {'kind': 'setoran', 'item': item, 'at': item['tanggal']},
      ),
      ..._recentTransactions.map(
        (item) => {'kind': 'transaksi', 'item': item, 'at': item['created_at']},
      ),
    ];
    activities.sort((left, right) {
      final leftDate = _parseDate(left['at']) ?? DateTime(0);
      final rightDate = _parseDate(right['at']) ?? DateTime(0);
      return rightDate.compareTo(leftDate);
    });

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(
            icon: Icons.receipt_long_outlined,
            title: 'AKTIVITAS TERAKHIR',
            trailing: const Text(
              'Terbaru',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.orange,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (activities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Belum ada aktivitas.'),
            )
          else
            for (final activity in activities.take(3)) _activityTile(activity),
        ],
      ),
    );
  }

  Widget _activityTile(Map<String, dynamic> activity) {
    final item = activity['item'] as Map<String, dynamic>;
    final isDeposit = activity['kind'] == 'setoran';
    final status = item['status']?.toString() ?? '';
    final approved = status == 'diterima' || status == 'berhasil';
    final amount = _integer(isDeposit ? item['total_saldo'] : item['jumlah']);
    final name = isDeposit
        ? item['jenis']?.toString() ?? 'Setoran'
        : item['keterangan']?.toString() ??
              (item['tipe'] == 'keluar'
                  ? 'Penarikan saldo'
                  : 'Transaksi saldo');
    final details = isDeposit
        ? '${_formatDateTime(activity['at'])} · ${_decimal(item['berat_kg']).toStringAsFixed(1)} kg · ${_statusLabel(status)}'
        : '${_formatDateTime(activity['at'])} · ${_statusLabel(status)}';
    final amountLabel = !approved
        ? _statusLabel(status)
        : '${item['tipe'] == 'keluar' ? '−' : '+'}${rupiah(amount)}';

    return ActivityTile(
      icon: isDeposit
          ? Icons.recycling_rounded
          : item['tipe'] == 'keluar'
          ? Icons.south_west_rounded
          : Icons.account_balance_wallet_outlined,
      title: name,
      subtitle: details,
      amount: amountLabel,
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'diterima':
      case 'berhasil':
        return 'Berhasil';
      case 'ditolak':
      case 'gagal':
        return 'Ditolak';
      case 'menunggu':
      case 'verifikasi':
      case 'pending':
        return 'Menunggu';
      default:
        return status.isEmpty ? 'Status tidak tersedia' : status;
    }
  }

  // ---------- Titik setor aktif ----------
  Widget _mapCard() {
    final point = _dropPoints.isEmpty ? null : _dropPoints.first;
    final latitude = point?['latitude']?.toString();
    final longitude = point?['longitude']?.toString();
    final hasCoordinates =
        latitude != null &&
        longitude != null &&
        num.tryParse(latitude) != null &&
        num.tryParse(longitude) != null;
    final isOpen = point?['status'] == 'buka';
    final openingHours = point == null
        ? ''
        : '${_formatTime(point['jam_buka'])}–${_formatTime(point['jam_tutup'])}';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(
            icon: Icons.location_on_outlined,
            title: 'TITIK SETOR AKTIF',
            trailing: Text(
              '${_dropPoints.length} titik',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.orange,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 120,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFDCE6D0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _MapLinesPainter()),
                ),
                const Center(
                  child: Icon(
                    Icons.location_on,
                    color: AppColors.orange,
                    size: 38,
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      point == null
                          ? 'Belum ada titik setor terdaftar'
                          : hasCoordinates
                          ? 'Koordinat: $latitude, $longitude'
                          : 'Lokasi tersedia di data titik setor',
                      style: const TextStyle(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (point == null)
            const Text('Data titik setor belum tersedia.')
          else ...[
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 9,
                  color: isOpen ? AppColors.green : AppColors.muted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    point['nama']?.toString() ?? 'Titik setor',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  isOpen ? 'Buka' : 'Tutup',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isOpen ? AppColors.green : AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const SizedBox(width: 17),
                Expanded(
                  child: Text(
                    point['alamat']?.toString() ?? 'Alamat belum tersedia',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                Text(
                  openingHours,
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MapLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB8C9A8)
      ..strokeWidth = 2;
    for (var i = 1; i <= 4; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 12), paint);
    }
    for (var i = 1; i <= 5; i++) {
      final x = size.width * i / 6;
      canvas.drawLine(Offset(x, 0), Offset(x - 10, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Bar extends StatelessWidget {
  final String label;
  final double kg;
  final double maxKg;
  final bool highlight;
  const _Bar({
    required this.label,
    required this.kg,
    required this.maxKg,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '${kg.toStringAsFixed(0)} kg',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: highlight ? AppColors.orange : AppColors.muted,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 26,
          height: kg == 0 ? 4 : (kg / maxKg * 92).clamp(4, 92).toDouble(),
          decoration: BoxDecoration(
            color: highlight ? AppColors.orange : AppColors.green,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String name;
  final String sub;
  final String price;
  const _PriceRow({
    required this.icon,
    required this.iconBg,
    required this.name,
    required this.sub,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.dark),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }
}

