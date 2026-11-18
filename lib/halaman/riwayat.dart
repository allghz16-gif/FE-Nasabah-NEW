// Riwayat transaksi dan model riwayat.
part of 'package:nasabah_resik/main.dart';

class RiwayatPage extends StatefulWidget {
  final VoidCallback? onBack;
  const RiwayatPage({super.key, this.onBack});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  late final Future<List<_RiwayatItem>> _history = _loadHistory();

  Future<List<_RiwayatItem>> _loadHistory() async {
    final responses = await Future.wait([
      ApiService.getSetoranSaya(),
      ApiService.getRiwayatTransaksi(),
    ]);
    final rows = <_RiwayatItem>[];
    final deposits = responses[0];
    final transactions = responses[1];
    for (final item
        in (deposits['data'] as List<dynamic>)
            .whereType<Map<String, dynamic>>()) {
      final status = '${item['status']}'.toLowerCase();
      final berat = num.tryParse('${item['berat_kg']}') ?? 0;
      rows.add(
        _RiwayatItem(
          title: 'Setor ${item['jenis']}',
          date: DateTime.tryParse('${item['tanggal']}'),
                status: status == 'diterima' || status == 'berhasil'
              ? 'Selesai'
              : status == 'ditolak'
              ? 'Ditolak'
              : 'Diproses',
          amount: (num.tryParse('${item['total_saldo']}') ?? 0).round(),
          incoming: true,
          detail: '${berat.toStringAsFixed(berat % 1 == 0 ? 0 : 1)} KG',
          icon: _iconForWaste('${item['jenis']}'),
        ),
      );
    }
    for (final item
        in (transactions['data'] as List<dynamic>)
            .whereType<Map<String, dynamic>>()) {
      final keluar = item['tipe'] == 'keluar';
      final date = DateTime.tryParse('${item['created_at']}');
      final status = '${item['status']}'.toLowerCase();
      rows.add(
        _RiwayatItem(
          title: keluar
              ? 'Tarik Saldo\n(${item['metode'] ?? 'Penarikan'})'
              : 'Saldo Setoran',
          date: date,
          status: status == 'berhasil' || status == 'berhasil diproses'
              ? 'Selesai'
              : 'Diproses',
          amount: (num.tryParse('${item['jumlah']}') ?? 0).round(),
          incoming: !keluar,
          detail: keluar
              ? 'TUJUAN ${item['nomor_tujuan'] ?? '-'}'
              : 'SALDO MASUK',
          icon: keluar
              ? Icons.payments_outlined
              : Icons.account_balance_wallet_outlined,
        ),
      );
    }
    rows.sort((a, b) {
      if (a.date == null) return 1;
      if (b.date == null) return -1;
      return b.date!.compareTo(a.date!);
    });
    return rows;
  }

  IconData _iconForWaste(String name) {
    final normalized = name.toLowerCase();
    if (normalized.contains('kertas') || normalized.contains('kardus')) {
      return Icons.inventory_2_outlined;
    }
    if (normalized.contains('minyak')) return Icons.eco_outlined;
    if (normalized.contains('plastik')) return Icons.local_drink_outlined;
    return Icons.recycling_rounded;
  }

  String _groupLabel(DateTime? date) {
    if (date == null) return 'TANGGAL TIDAK TERSEDIA';
    final now = DateTime.now();
    final day = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return 'HARI INI';
    if (day == today.subtract(const Duration(days: 1))) return 'KEMARIN';
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MEI',
      'JUN',
      'JUL',
      'AGU',
      'SEP',
      'OKT',
      'NOV',
      'DES',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _monthLabel(DateTime date) {
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
    return '${months[date.month - 1]} ${date.year}';
  }

  String _timeLabel(DateTime? date) {
    if (date == null) return '--:--';
    final local = date.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<_RiwayatItem>>(
    future: _history,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Gagal memuat riwayat: ${snapshot.error}'),
          ),
        );
      }
      final rows = snapshot.data ?? [];
      final grouped = <String, List<_RiwayatItem>>{};
      for (final row in rows) {
        grouped.putIfAbsent(_groupLabel(row.date), () => []).add(row);
      }
      final summaryDate = DateTime.now();
      final thisMonth = rows
          .where(
            (row) =>
                row.date?.year == summaryDate.year &&
                row.date?.month == summaryDate.month &&
                row.incoming &&
                row.status == 'Selesai',
          )
          .toList();
      final totalKg = rows
          .where(
            (row) =>
                row.date?.year == summaryDate.year &&
                row.date?.month == summaryDate.month &&
                row.title.toLowerCase().startsWith('setor'),
          )
          .fold<double>(0, (sum, row) => sum + row.weightKg);
      final totalSaldo = thisMonth.fold<int>(0, (sum, row) => sum + row.amount);

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _topBar(),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    icon: Icons.recycling_rounded,
                    label: 'TERKUMPUL',
                    value: '${totalKg.toStringAsFixed(1)} Kg',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _summaryCard(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'SALDO MASUK',
                    value: _compactRupiah(totalSaldo),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _monthHeader(_monthLabel(summaryDate)),
            const SizedBox(height: 16),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: Text('Belum ada aktivitas.')),
              )
            else
              for (final entry in grouped.entries) ...[
                _groupHeader(entry.key),
                const SizedBox(height: 12),
                for (final row in entry.value) _historyCard(row),
                const SizedBox(height: 6),
              ],
          ],
        ),
      );
    },
  );

  Widget _topBar() => Row(
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
      Expanded(child: Text('Riwayat', style: display(size: 22))),
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

  Widget _summaryCard({
    required IconData icon,
    required String label,
    required String value,
  }) => Container(
    margin: const EdgeInsets.only(right: 4, bottom: 4),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.dark, width: 1.5),
      boxShadow: const [BoxShadow(color: AppColors.dark, offset: Offset(4, 4))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFFADBD0),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Icon(icon, size: 11, color: AppColors.orange),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 8,
                  letterSpacing: .5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(value, style: display(size: 22)),
      ],
    ),
  );

  Widget _monthHeader(String text) => Row(
    children: [
      Text(text, style: display(size: 14, weight: FontWeight.w700)),
      const SizedBox(width: 10),
      const Expanded(child: Divider(color: Color(0xFFE6DFCF), height: 1)),
      const SizedBox(width: 6),
      const Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 18,
        color: AppColors.muted,
      ),
    ],
  );

  Widget _groupHeader(String text) => Row(
    children: [
      Text(
        text,
        style: const TextStyle(
          fontSize: 9.5,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
        ),
      ),
      const SizedBox(width: 10),
      const Expanded(child: Divider(color: Color(0xFFE6DFCF), height: 1)),
    ],
  );

  Widget _historyCard(_RiwayatItem item) {
    final complete = item.status == 'Selesai';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6DFCF)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.incoming
                  ? const Color(0xFFFADBD0)
                  : const Color(0xFFE6E0CF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              item.icon,
              size: 22,
              color: item.incoming ? AppColors.orange : AppColors.muted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 3),
                Text.rich(
                  TextSpan(
                    text: '${_timeLabel(item.date)} · ',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                    ),
                    children: [
                      TextSpan(
                        text: item.status,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: complete ? AppColors.green : AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.incoming ? '+' : '-'}${rupiah(item.amount)}',
                style: display(size: 15, weight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                item.detail,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 8,
                  letterSpacing: .5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _compactRupiah(int amount) => amount >= 1000000
      ? 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt'
      : 'Rp ${amount ~/ 1000}k';
}

class _RiwayatItem {
  final String title;
  final DateTime? date;
  final String status;
  final int amount;
  final bool incoming;
  final String detail;
  final IconData icon;

  const _RiwayatItem({
    required this.title,
    required this.date,
    required this.status,
    required this.amount,
    required this.incoming,
    required this.detail,
    required this.icon,
  });

  double get weightKg {
    final match = RegExp(r'[\d,.]+').firstMatch(detail);
    return double.tryParse(match?.group(0)?.replaceAll(',', '.') ?? '') ?? 0;
  }
}

