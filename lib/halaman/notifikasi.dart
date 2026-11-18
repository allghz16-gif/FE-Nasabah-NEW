// Halaman notifikasi.
part of 'package:nasabah_resik/main.dart';

class NotifikasiNasabahPage extends StatefulWidget {
  final VoidCallback onBack;
  const NotifikasiNasabahPage({super.key, required this.onBack});

  @override
  State<NotifikasiNasabahPage> createState() => _NotifikasiNasabahPageState();
}

class _NotifikasiNasabahPageState extends State<NotifikasiNasabahPage> {
  late Future<List<Map<String, dynamic>>> _notifications = _loadNotifications();
  String? _error;

  Future<List<Map<String, dynamic>>> _loadNotifications() async {
    final response = await ApiService.getNotifikasi();
    return (response['data'] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  bool _isRead(Map<String, dynamic> notification) {
    final value = notification['sudah_dibaca'];
    return value == true || value == 1 || value == '1';
  }

  Future<void> _markRead(Map<String, dynamic> notification) async {
    if (_isRead(notification)) return;
    try {
      await ApiService.tandaiNotifikasiBaca(int.parse('${notification['id']}'));
      if (!mounted) return;
      setState(() {
        notification['sudah_dibaca'] = 1;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memperbarui notifikasi: $error');
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'sukses':
        return Icons.check_circle_outline_rounded;
      case 'peringatan':
        return Icons.warning_amber_rounded;
      case 'error':
        return Icons.error_outline_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<Map<String, dynamic>>>(
    future: _notifications,
    builder: (context, snapshot) {
      final items = snapshot.data ?? [];
      final unread = items.where((item) => !_isRead(item)).length;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
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
                Expanded(child: Text('Notifikasi', style: display(size: 22))),
                if (unread > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '$unread baru',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (snapshot.connectionState == ConnectionState.waiting)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (snapshot.hasError)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Gagal memuat notifikasi: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _error = null;
                            _notifications = _loadNotifications();
                          });
                        },
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (items.isEmpty)
            const Expanded(child: Center(child: Text('Belum ada notifikasi.')))
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: _isRead(item)
                            ? Colors.white.withValues(alpha: .75)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _markRead(item),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _isRead(item)
                                    ? const Color(0xFFE6DFCF)
                                    : AppColors.green,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFADBD0),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _iconFor('${item['tipe']}'),
                                    color: AppColors.orange,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item['judul'] ?? 'Notifikasi'}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.dark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item['pesan'] ?? ''}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        DateTime.tryParse(
                                                  '${item['created_at']}',
                                                )
                                                ?.toLocal()
                                                .toString()
                                                .substring(0, 16) ??
                                            '',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!_isRead(item))
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8, top: 4),
                                    child: CircleAvatar(
                                      radius: 4,
                                      backgroundColor: AppColors.orange,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      );
    },
  );
}

// ---------------------------------------------------------------
