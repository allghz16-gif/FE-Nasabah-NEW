// Form dan proses setor sampah.
part of 'package:nasabah_resik/main.dart';

// LAYAR: SETOR SAMPAH
// ---------------------------------------------------------------

/// Data satu jenis sampah.
class _Jenis {
  final int id;
  final String nama;
  final IconData icon;
  final int hargaPerKg;
  const _Jenis(this.id, this.nama, this.icon, this.hargaPerKg);
}

class SetorPage extends StatefulWidget {
  final VoidCallback? onBack;
  const SetorPage({super.key, this.onBack});

  @override
  State<SetorPage> createState() => _SetorPageState();
}

class _SetorPageState extends State<SetorPage> {
  final List<int> selected = [];
  final List<TextEditingController> controllers = [];
  List<_Jenis> jenis = [];
  bool loading = true;
  Uint8List? _buktiBytes;
  String _buktiNama = 'bukti.jpg';
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadJenis();
  }

  Future<void> _loadJenis() async {
    try {
      final response = await ApiService.getJenisSampah();
      final data = response['data'] as List<dynamic>;
      final loaded = data
         .where((item) {
            if (item is! Map<String, dynamic>) return false;
            final n = '${item['nama']}'.toLowerCase();
            return n.contains('plastik') ||
                n.contains('kardus') ||
                n.contains('minyak');
          })
          .map((item) {
            final row = item as Map<String, dynamic>;
            final name = (row['nama'] as String).toUpperCase();
            final icon = name.contains('MINYAK')
                ? Icons.opacity_outlined
                : name.contains('KARDUS') || name.contains('KERTAS')
                ? Icons.inventory_2_outlined
                : name.contains('PLASTIK')
                ? Icons.local_drink_outlined
                : Icons.recycling_rounded;
            return _Jenis(
              int.parse('${row['id']}'),
              name,
              icon,
              (num.tryParse('${row['harga_per_kg']}') ?? 0).round(),
            );
          })
          .toList();
      if (!mounted) return;
      for (final controller in controllers) {
        controller.dispose();
      }
      setState(() {
        jenis = loaded;
        controllers.addAll(
          List.generate(
            loaded.length,
            (_) => TextEditingController(text: '2.5'),
          ),
        );
        if (loaded.isNotEmpty) selected.add(0);
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat jenis sampah: $error')),
      );
    }
  }

  @override
  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------- logika ----------
  double _kg(int i) =>
      double.tryParse(controllers[i].text.replaceAll(',', '.')) ?? 0;

  int _harga(int i) => (_kg(i) * jenis[i].hargaPerKg).round();

  double get totalKg => selected.fold(0.0, (s, i) => s + _kg(i));
  int get totalSaldo => selected.fold(0, (s, i) => s + _harga(i));

  String _fmtKg(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  void _toggle(int i) {
    setState(() {
      if (selected.contains(i)) {
        if (selected.length > 1) selected.remove(i); // minimal 1 jenis
      } else {
        selected.add(i);
      }
    });
  }

  void _tambahJenis() {
    final sisa = List.generate(
      jenis.length,
      (i) => i,
    ).where((i) => !selected.contains(i));
    if (sisa.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua jenis sampah sudah ditambahkan')),
      );
      return;
    }
    setState(() => selected.add(sisa.first));
  }

  Future<void> _konfirmasi() async {
    if (loading || jenis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jenis sampah belum tersedia')),
      );
      return;
    }
    if (totalKg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi estimasi berat terlebih dahulu')),
      );
      return;
    }
        if (_sending) return;
    final items = <Map<String, dynamic>>[];
    for (final i in selected) {
      final kg = _kg(i);
      if (kg <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Isi berat untuk ${jenis[i].nama}')),
        );
        return;
      }
      items.add({'jenis_sampah_id': jenis[i].id, 'berat': kg});
    }
    if (_buktiBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan foto bukti timbangan dulu')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      await ApiService.kirimSetoran(
        items: items,
        buktiBytes: _buktiBytes!,
        buktiNama: _buktiNama,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Setoran gagal dikirim: ${error is ApiException ? error.message : error}',
          ),
        ),
      );
      return;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    if (!mounted) return;
    setState(() => _buktiBytes = null);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black38,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 30),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.dark, width: 2.5),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 34,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'SETORAN BERHASIL',
                style: display(size: 16, weight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // tutup popup
  }

  Future<void> _pilihBukti(ImageSource source) async {
    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      _buktiBytes = bytes;
      _buktiNama = image.name;
    });
  }

  Widget _buktiCard() => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FOTO BUKTI TIMBANGAN',
          style: TextStyle(
            fontSize: 8.5,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 10),
        if (_buktiBytes != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              _buktiBytes!,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pilihBukti(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined, size: 16),
                label: const Text('Kamera'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pilihBukti(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined, size: 16),
                label: Text(_buktiBytes == null ? 'Galeri' : 'Ganti'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  // ---------- tampilan ----------
  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (jenis.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Data jenis sampah belum tersedia.'),
            TextButton(onPressed: _loadJenis, child: const Text('Coba lagi')),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _topBar(),
          const SizedBox(height: 14),
          _stepper(),
          const SizedBox(height: 18),
          Text(
            'Pilih Kategori Sampah',
            style: display(size: 15, weight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _kategoriRow(),
          const SizedBox(height: 16),
          for (final i in selected) _beratCard(i),
          const SizedBox(height: 4),
          _ringkasan(),
          const SizedBox(height: 14),
          _buktiCard(),
          const SizedBox(height: 4),
          _konfirmasiButton(),
          const SizedBox(height: 18),
          _caraSetor(),
        ],
      ),
    );
  }

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
        Expanded(child: Text('Setor Sampah', style: display(size: 22))),
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

  Widget _stepper() {
    Widget step(String no, String label, bool active) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? AppColors.dark : _line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? AppColors.dark : Colors.transparent,
              border: active ? null : Border.all(color: AppColors.muted),
            ),
            child: Text(
              no,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: active ? Colors.white : AppColors.muted,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.dark : AppColors.muted,
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          step('1', 'Pilih Kategori', true),
          const Expanded(child: Divider(color: _line, indent: 6, endIndent: 6)),
          step('2', 'Konfirmasi', false),
        ],
      ),
    );
  }

  Widget _kategoriRow() {
    return Row(
      children: [
        for (int i = 0; i < jenis.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == jenis.length - 1 ? 0 : 10),
              child: _kategoriTile(i),
            ),
          ),
      ],
    );
  }

  Widget _kategoriTile(int i) {
    final j = jenis[i];
    final on = selected.contains(i);
    return GestureDetector(
      onTap: () => _toggle(i),
      child: Container(
        height: 74,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: on ? AppColors.orange : _line,
            width: on ? 1.8 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              j.icon,
              size: 24,
              color: on ? AppColors.orange : AppColors.muted,
            ),
            const SizedBox(height: 6),
            Text(
              j.nama,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: .5,
                color: on ? AppColors.orange : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _beratCard(int i) {
    final j = jenis[i];
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16, right: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dark, width: 1.5),
        boxShadow: const [
          BoxShadow(color: AppColors.dark, offset: Offset(4, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ESTIMASI BERAT (KG)',
            style: TextStyle(
              fontSize: 8.5,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEDEAE0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.dark, width: 1.2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controllers[i],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      LengthLimitingTextInputFormatter(6),
                    ],
                    style: display(size: 22),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const Text(
                  'KG',
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ESTIMASI PENDAPATAN',
                      style: TextStyle(
                        fontSize: 8.5,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(rupiah(_harga(i)), style: display(size: 20)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEAE0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'RP ${rupiah(j.hargaPerKg).substring(3)} / KG',
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _tambahJenis,
            child: CustomPaint(
              foregroundPainter: const _DashedBorderPainter(
                color: AppColors.dark,
                radius: 10,
              ),
              child: Container(
                height: 42,
                alignment: Alignment.center,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_circle_rounded,
                      size: 15,
                      color: AppColors.dark,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Tambah Jenis Sampah',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
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

  Widget _ringkasan() {
    return Column(
      children: [
        Row(
          children: [
            Text('Ringkasan Setoran', style: display(size: 15)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${selected.length} JENIS',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Berat',
              style: TextStyle(fontSize: 11, color: AppColors.muted),
            ),
            Text(
              '${_fmtKg(totalKg)} Kg',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(height: 1, color: _line),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Saldo Diterima',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
              ),
            ),
            Text(
              rupiah(totalSaldo),
              style: display(size: 18, color: AppColors.orange),
            ),
          ],
        ),
      ],
    );
  }

  Widget _konfirmasiButton() {
    return GestureDetector(
      onTap: _konfirmasi,
      child: Container(
        height: 50,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.dark,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black26, offset: Offset(0, 3)),
          ],
        ),
        child: const Text(
          'Konfirmasi Setoran',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _caraSetor() {
    Widget item(String no, String judul, String isi) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              no,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isi,
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 15, color: AppColors.dark),
              const SizedBox(width: 6),
              Text('Cara Setor Sampah', style: display(size: 13)),
            ],
          ),
          const SizedBox(height: 12),
          item(
            '1',
            'Pilih & Kategorikan',
            'Pisahkan sampah sesuai terlebih dahulu hingga bersih.',
          ),
          item(
            '2',
            'Bawa ke Drop Point',
            'Sari titik penjemputan atau datang langsung ke titik terdekat.',
          ),
          item(
            '3',
            'Timbang & Cairkan',
            'Petugas akan menimbang sampahmu dan saldo akan langsung masuk.',
          ),
        ],
      ),
    );
  }
}

