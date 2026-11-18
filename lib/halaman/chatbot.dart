// Chatbot dan formatter input.
part of 'package:nasabah_resik/main.dart';

class _ChatMessage {
  final bool isBot;
  final String text;
  final String time;

  const _ChatMessage(this.isBot, this.text, this.time);
}

String _chatTime() {
  final now = DateTime.now();
  final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
  final minute = now.minute.toString().padLeft(2, '0');
  return '${hour.toString().padLeft(2, '0')}:$minute '
      '${now.hour < 12 ? 'AM' : 'PM'}';
}

List<_ChatMessage> _newChatHistory() => [
  _ChatMessage(
    true,
    'Halo! Saya Asisten DaurUang. Ada yang bisa saya bantu seputar sampah, '
    'harga, atau penarikan saldo?',
    _chatTime(),
  ),
];

final List<_ChatMessage> _chatHistory = _newChatHistory();

String _chatAnswer(String question) {
  final text = question.toLowerCase();
  bool includes(List<String> terms) => terms.any(text.contains);

  if (includes(['harga'])) {
    return 'Silakan cek harga terbaru pada bagian Harga Sampah di halaman '
        'Beranda karena nilainya dapat berubah setiap hari.';
  }
  if (includes(['pet', 'hdpe', 'bedakan', 'plastik'])) {
    return 'PET (kode 1) biasanya jernih dan digunakan untuk botol air mineral. '
        'HDPE (kode 2) lebih tebal dan sering digunakan untuk botol deterjen '
        'atau susu.';
  }
  if (includes(['tarik', 'tukar', 'saldo', 'cair'])) {
    return 'Saldo dapat ditarik lewat menu Tukar ke E-Wallet atau Transfer '
        'Bank. Minimal penarikan Rp50.000 dengan biaya layanan Rp1.000.';
  }
  if (includes(['jadwal', 'jemput', 'ambil'])) {
    return 'Kamu akan mendapat notifikasi saat armada penjemputan menuju '
        'lokasimu. Pastikan sampah sudah terpilah dan bersih.';
  }
  if (includes(['setor', 'cara'])) {
    return 'Pisahkan dan bersihkan sampah, lalu bawa ke drop point atau '
        'gunakan layanan penjemputan. Setelah ditimbang, saldo akan masuk '
        'ke akunmu.';
  }
  if (includes(['terima kasih', 'makasih', 'thanks'])) {
    return 'Sama-sama! Senang bisa membantu.';
  }
  if (includes(['halo', 'hai', 'hi ', 'pagi', 'siang', 'sore', 'malam'])) {
    return 'Halo! Ada yang bisa saya bantu seputar sampah, harga, atau '
        'penarikan saldo?';
  }
  return 'Maaf, saya belum paham pertanyaan itu. Coba tanyakan tentang harga '
      'sampah, cara setor, jadwal penjemputan, cara tarik saldo, atau jenis '
      'plastik.';
}

class ChatPage extends StatefulWidget {
  final VoidCallback? onBack;

  const ChatPage({super.key, this.onBack});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _typing = false;

  static const _suggestions = [
    'Harga sampah hari ini?',
    'Cara setor sampah?',
    'Jadwal penjemputan?',
    'Cara tarik saldo?',
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send(String value) async {
    final text = value.trim();
    if (text.isEmpty || _typing) return;
    _input.clear();
    setState(() {
      _chatHistory.add(_ChatMessage(false, text, _chatTime()));
      _typing = true;
    });
    _scrollToBottom();

    await Future<void>.delayed(const Duration(milliseconds: 500));
    _chatHistory.add(_ChatMessage(true, _chatAnswer(text), _chatTime()));
    if (!mounted) return;
    setState(() => _typing = false);
    _scrollToBottom();
  }

  Future<void> _clearConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus percakapan?'),
        content: const Text('Semua pesan di chat ini akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _chatHistory
        ..clear()
        ..addAll(_newChatHistory());
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Row(
            children: [
              IconButton(
                key: const Key('chatbot-back-button'),
                tooltip: 'Kembali',
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.dark,
                child: Icon(Icons.eco, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asisten DaurUang',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                    Text(
                      'Online • Siap membantu',
                      style: TextStyle(fontSize: 10, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opsi percakapan',
                onSelected: (value) {
                  if (value == 'clear') _clearConversation();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'clear',
                    child: Text('Hapus percakapan'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            key: const Key('chatbot-message-list'),
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6E0CF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'HARI INI',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              for (final message in List<_ChatMessage>.of(_chatHistory))
                _messageBubble(message),
              if (_typing) _typingBubble(),
            ],
          ),
        ),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _suggestions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) => ActionChip(
              key: Key('chatbot-suggestion-$index'),
              label: Text(
                _suggestions[index],
                style: const TextStyle(fontSize: 10),
              ),
              onPressed: _typing ? null : () => _send(_suggestions[index]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.muted.withValues(alpha: .3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('chatbot-message-input'),
                    controller: _input,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _send,
                    decoration: const InputDecoration(
                      hintText: 'Tulis pesan...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('chatbot-send-button'),
                  tooltip: 'Kirim pesan',
                  onPressed: _typing ? null : () => _send(_input.text),
                  icon: const Icon(Icons.send_rounded, color: AppColors.green),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _messageBubble(_ChatMessage message) {
    final time = Text(
      message.time,
      style: const TextStyle(fontSize: 8, color: AppColors.muted),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: message.isBot
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.dark,
                  child: Icon(Icons.eco, size: 13, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.muted.withValues(alpha: .2),
                          ),
                        ),
                        child: Text(
                          message.text,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.45,
                            color: AppColors.dark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      time,
                    ],
                  ),
                ),
              ],
            )
          : Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * .72,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.dark,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      message.text,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  time,
                ],
              ),
            ),
    );
  }

  Widget _typingBubble() => const Padding(
    padding: EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppColors.dark,
          child: Icon(Icons.eco, size: 13, color: Colors.white),
        ),
        SizedBox(width: 8),
        Text(
          'Sedang mengetik...',
          style: TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------
