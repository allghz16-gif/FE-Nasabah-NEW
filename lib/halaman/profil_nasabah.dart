// Halaman profil nasabah.
part of 'package:nasabah_resik/main.dart';

class ProfilNasabahPage extends StatefulWidget {
  final Future<Map<String, dynamic>> Function()? loadProfile;
  final Future<Map<String, dynamic>> Function()? loadPaymentMethods;
  final Future<Uint8List?> Function()? pickProfilePhoto;
  final VoidCallback? onBack;
  final VoidCallback? onChat;

  const ProfilNasabahPage({
    super.key,
    this.loadProfile,
    this.loadPaymentMethods,
    this.pickProfilePhoto,
    this.onBack,
    this.onChat,
  });

  @override
  State<ProfilNasabahPage> createState() => _ProfilNasabahPageState();
}

class _ProfilNasabahPageState extends State<ProfilNasabahPage> {
  final Map<String, TextEditingController> _fields = {
    for (final key in [
      'nama',
      'telepon',
      'email',
      'nik',
      'alamatLengkap',
      'rt',
      'rw',
      'kelurahan',
      'kecamatan',
      'kota',
      'latitude',
      'longitude',
    ])
      key: TextEditingController(),
  };
  List<Map<String, dynamic>> _paymentMethods = [];
  String _jenisTempat = 'Rumah Tangga';
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Uint8List? _profilePhoto;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    unawaited(_loadProfilePhoto());
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final responses = await Future.wait([
        widget.loadProfile?.call() ?? ApiService.getProfilSaya(),
        widget.loadPaymentMethods?.call() ??
            ApiService.getMetodePencairanSaya(),
      ]);
      final data = responses[0]['data'];
      final paymentRows = responses[1]['data'];
      if (data is! Map<String, dynamic> || paymentRows is! List<dynamic>) {
        throw const FormatException('Data profil tidak valid.');
      }
      final values = <String, String>{
        'nama': '${data['nama'] ?? ''}',
        'telepon': '${data['telepon'] ?? ''}',
        'email': '${data['email'] ?? ''}',
        'nik': '${data['nik'] ?? ''}',
        'alamatLengkap': '${data['alamat_lengkap'] ?? data['alamat'] ?? ''}',
        'rt': '${data['rt'] ?? ''}',
        'rw': '${data['rw'] ?? ''}',
        'kelurahan': '${data['kelurahan'] ?? ''}',
        'kecamatan': '${data['kecamatan'] ?? ''}',
        'kota': '${data['kota'] ?? ''}',
        'latitude': '${data['latitude'] ?? ''}',
        'longitude': '${data['longitude'] ?? ''}',
      };
      for (final entry in values.entries) {
        _fields[entry.key]!.text = entry.value == 'null' ? '' : entry.value;
      }
      final types = ['Rumah Tangga', 'Sekolah', 'Kantor', 'Usaha'];
      final savedType = '${data['jenis_tempat'] ?? types.first}';
      setState(() {
        _jenisTempat = types.contains(savedType) ? savedType : types.first;
        _paymentMethods = paymentRows
            .whereType<Map<String, dynamic>>()
            .toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Gagal memuat profil dari server: $error';
      });
    }
  }

  Future<void> _loadProfilePhoto() async {
    try {
      final photo = await ApiService.getProfilePhoto();
      if (mounted) setState(() => _profilePhoto = photo);
    } catch (error) {
      if (!mounted) return;
      await _showAuthPopup(
        context,
        title: 'Foto profil tidak dapat dimuat',
        message: 'Periksa penyimpanan foto profil dan coba lagi. $error',
        icon: Icons.broken_image_outlined,
      );
    }
  }

  Future<void> _changeProfilePhoto() async {
    try {
      final photo = widget.pickProfilePhoto != null
          ? await widget.pickProfilePhoto!()
          : await _pickProfilePhotoFromGallery();
      if (photo == null || !mounted) return;
      if (photo.lengthInBytes > 2 * 1024 * 1024) {
        await _showAuthPopup(
          context,
          title: 'Ukuran foto terlalu besar',
          message: 'Pilih foto dengan ukuran maksimal 2 MB.',
          icon: Icons.image_not_supported_outlined,
        );
        return;
      }
      await ApiService.saveProfilePhoto(photo);
      if (!mounted) return;
      setState(() => _profilePhoto = photo);
    } catch (error) {
      if (!mounted) return;
      await _showAuthPopup(
        context,
        title: 'Foto profil gagal diperbarui',
        message: 'Coba pilih foto lain. $error',
        icon: Icons.error_outline_rounded,
      );
    }
  }

  Future<Uint8List?> _pickProfilePhotoFromGallery() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );
    return image?.readAsBytes();
  }

  Future<void> _saveProfile() async {
    final name = _fields['nama']!.text.trim();
    if (name.isEmpty) {
      await _showAuthPopup(
        context,
        title: 'Nama wajib diisi',
        message: 'Masukkan nama lengkap sebelum menyimpan profil.',
        icon: Icons.person_outline_rounded,
      );
      return;
    }
    if (_fields['nik']!.text.trim().isNotEmpty &&
        !RegExp(r'^\d{16}$').hasMatch(_fields['nik']!.text.trim())) {
      await _showAuthPopup(
        context,
        title: 'NIK belum valid',
        message: 'NIK harus terdiri dari 16 digit angka.',
        icon: Icons.badge_outlined,
      );
      return;
    }
    final latitude = double.tryParse(_fields['latitude']!.text.trim());
    final longitude = double.tryParse(_fields['longitude']!.text.trim());
    if ((_fields['latitude']!.text.trim().isNotEmpty && latitude == null) ||
        (_fields['longitude']!.text.trim().isNotEmpty && longitude == null) ||
        (latitude != null && (latitude < -90 || latitude > 90)) ||
        (longitude != null && (longitude < -180 || longitude > 180))) {
      await _showAuthPopup(
        context,
        title: 'Koordinat belum valid',
        message: 'Periksa kembali nilai lintang dan bujur lokasi rumahmu.',
        icon: Icons.location_on_outlined,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiService.updateProfil(
        nama: name,
        alamat: _fields['alamatLengkap']!.text.trim(),
        email: _fields['email']!.text.trim(),
        nik: _fields['nik']!.text.trim(),
        jenisTempat: _jenisTempat,
        alamatLengkap: _fields['alamatLengkap']!.text.trim(),
        rt: _fields['rt']!.text.trim(),
        rw: _fields['rw']!.text.trim(),
        kelurahan: _fields['kelurahan']!.text.trim(),
        kecamatan: _fields['kecamatan']!.text.trim(),
        kota: _fields['kota']!.text.trim(),
        latitude: latitude,
        longitude: longitude,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui.')),
      );
    } catch (error) {
      if (!mounted) return;
      await _showAuthPopup(
        context,
        title: 'Profil belum tersimpan',
        message: error is ApiException ? error.message : '$error',
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editLocation() async {
    final latitudeController = TextEditingController(
      text: _fields['latitude']!.text,
    );
    final longitudeController = TextEditingController(
      text: _fields['longitude']!.text,
    );
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Ubah lokasi', style: display(size: 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latitudeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(labelText: 'Latitude'),
            ),
            TextField(
              controller: longitudeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(labelText: 'Longitude'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, (
              latitudeController.text.trim(),
              longitudeController.text.trim(),
            )),
            child: const Text('Pakai Lokasi'),
          ),
        ],
      ),
    );
    latitudeController.dispose();
    longitudeController.dispose();
    if (result == null || !mounted) return;
    setState(() {
      _fields['latitude']!.text = result.$1;
      _fields['longitude']!.text = result.$2;
    });
  }

  Future<void> _addPaymentMethod() async {
    final ownerController = TextEditingController(
      text: _fields['nama']!.text.trim(),
    );
    final numberController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var method = 'GoPay';
    var submitting = false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.dark, width: 1.5),
              boxShadow: const [
                BoxShadow(color: AppColors.dark, offset: Offset(0, 5)),
              ],
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: AppColors.orange,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Tambah Rekening Pencairan',
                          style: display(size: 18),
                        ),
                      ),
                      IconButton(
                        onPressed: submitting
                            ? null
                            : () => Navigator.pop(dialogContext, false),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: method,
                    decoration: const InputDecoration(
                      labelText: 'Metode Pencairan',
                    ),
                    items:
                        const [
                          'GoPay',
                          'DANA',
                          'OVO',
                          'ShopeePay',
                          'BCA',
                          'BRI',
                          'BNI',
                          'Mandiri',
                        ].map((item) {
                          return DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                    onChanged: (value) =>
                        setDialogState(() => method = value ?? method),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: ownerController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nama Pemilik',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Nama pemilik wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: numberController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Akun / Nomor Rekening',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Nomor akun wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: submitting
                          ? null
                          : () async {
                              if (!(formKey.currentState?.validate() ??
                                  false)) {
                                return;
                              }
                              setDialogState(() => submitting = true);
                              try {
                                await ApiService.tambahMetodePencairan(
                                  metode: method,
                                  namaPemilik: ownerController.text.trim(),
                                  nomorRekening: numberController.text.trim(),
                                );
                                if (dialogContext.mounted) {
                                  Navigator.pop(dialogContext, true);
                                }
                              } catch (error) {
                                if (!dialogContext.mounted) return;
                                setDialogState(() => submitting = false);
                                await _showAuthPopup(
                                  dialogContext,
                                  title: 'Rekening belum ditambahkan',
                                  message: error is ApiException
                                      ? error.message
                                      : '$error',
                                  icon: Icons.error_outline_rounded,
                                );
                              }
                            },
                      child: submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Tambah'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    ownerController.dispose();
    numberController.dispose();
    if (result == true && mounted) {
      try {
        await _reloadMethods();
      } catch (error) {
        if (!mounted) return;
        await _showAuthPopup(
          context,
          title: 'Metode belum dimuat',
          message: error is ApiException ? error.message : '$error',
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  Future<void> _reloadMethods() async {
    final response = await ApiService.getMetodePencairanSaya();
    final rows = response['data'];
    if (rows is! List<dynamic>) {
      throw const FormatException('Daftar rekening tidak valid.');
    }
    if (mounted) {
      setState(() {
        _paymentMethods = rows.whereType<Map<String, dynamic>>().toList();
      });
    }
  }

  Future<void> _makePrimary(Map<String, dynamic> method) async {
    final id = int.tryParse('${method['id']}');
    if (id == null) {
      await _showAuthPopup(
        context,
        title: 'Data rekening tidak valid',
        message: 'Tidak dapat mengubah rekening utama. Muat ulang halaman.',
        icon: Icons.error_outline_rounded,
      );
      return;
    }
    try {
      await ApiService.jadikanMetodePencairanUtama(id);
      await _reloadMethods();
    } catch (error) {
      if (!mounted) return;
      await _showAuthPopup(
        context,
        title: 'Metode belum berubah',
        message: error is ApiException ? error.message : '$error',
        icon: Icons.error_outline_rounded,
      );
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.logout_rounded,
          color: AppColors.orange,
          size: 34,
        ),
        title: Text('Yakin mau keluar?', style: display(size: 21)),
        content: const Text(
          'Kamu akan keluar dari akun RESIK. Saldo dan riwayat setoran tetap aman, masuk lagi kapan saja.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Ya, Keluar'),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ApiService.logoutNasabah();
      if (mounted) _goLogin(context);
    } catch (error) {
      if (!mounted) return;
      await _showAuthPopup(
        context,
        title: 'Sesi lokal dihapus',
        message: error is ApiException ? error.message : 'Akun telah dikeluarkan dari perangkat, tetapi server belum dapat mengakhiri sesi.',
        icon: Icons.info_outline_rounded,
        accent: AppColors.dark,
      );
      if (mounted) _goLogin(context);
    }
  }

  Widget _profileTopBar() => Row(
    children: [
      IconButton(
        tooltip: 'Kembali ke Beranda',
        onPressed: widget.onBack,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.dark,
          side: const BorderSide(color: AppColors.dark, width: 1.3),
          fixedSize: const Size(38, 38),
        ),
        icon: const Icon(Icons.arrow_back_rounded, size: 20),
      ),
      const SizedBox(width: 8),
      Expanded(child: Text('Profil', style: display(size: 22))),
      IconButton(
        key: const Key('profile-chatbot-button'),
        tooltip: 'Buka Asisten DaurUang',
        onPressed: widget.onChat,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
          fixedSize: const Size(38, 38),
        ),
        icon: const Icon(Icons.eco_rounded, size: 20),
      ),
    ],
  );

  Widget _profileHeaderCard(String initial) {
    final name = _fields['nama']!.text.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        children: [
          InkWell(
            key: const Key('profile-photo-button'),
            onTap: _changeProfilePhoto,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 62,
              height: 62,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3EDD9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.orange, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _profilePhoto == null
                          ? const Icon(
                              Icons.person_rounded,
                              size: 34,
                              color: AppColors.dark,
                            )
                          : Image.memory(
                              _profilePhoto!,
                              key: const Key('profile-photo-image'),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.broken_image_outlined,
                                size: 30,
                                color: AppColors.dark,
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.photo_camera_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? initial : name,
                  key: const Key('profile-header-name'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: display(size: 16),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBEBC8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Member Gold',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8A5A00),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Container(
          width: 3,
          height: 13,
          decoration: BoxDecoration(
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: .4,
            color: AppColors.dark,
          ),
        ),
      ],
    ),
  );

  Widget _field(
    String key,
    String label, {
    bool readOnly = false,
    TextInputType? keyboardType,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 4),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 8,
              color: AppColors.muted,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        TextField(
          controller: _fields[key],
          readOnly: readOnly,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 11, color: AppColors.dark),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: readOnly ? const Color(0xFFF5F3ED) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: _line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: _line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: AppColors.orange),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _paymentCard(Map<String, dynamic> method) {
    final isPrimary = method['utama'] == 1 || method['utama'] == true;
    final number = '${method['nomor_rekening'] ?? ''}';
    final masked = number.length > 4
        ? '${'•' * (number.length - 4)}${number.substring(number.length - 4)}'
        : number;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Color(0x25000000), offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isPrimary ? 'METODE UTAMA' : 'METODE PENCAIRAN',
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.white70,
                    letterSpacing: .5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                isPrimary
                    ? Icons.check_circle_rounded
                    : Icons.account_balance_wallet_outlined,
                size: 15,
                color: AppColors.orange,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${method['metode'] ?? ''}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'NOMOR AKUN',
            style: TextStyle(fontSize: 7.5, color: Colors.white70),
          ),
          Text(
            masked,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NAMA PEMILIK',
                      style: TextStyle(fontSize: 7.5, color: Colors.white70),
                    ),
                    Text(
                      '${method['nama_pemilik'] ?? ''}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
              if (!isPrimary)
                TextButton(
                  onPressed: () => _makePrimary(method),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white24,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'JADIKAN UTAMA',
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _locationMap() {
    final lat = _fields['latitude']!.text;
    final lon = _fields['longitude']!.text;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 132,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _ProfileMapPainter(),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFD8D7A9), Color(0xFFB9C39A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
            const Center(
              child: Icon(
                Icons.location_pin,
                color: AppColors.orange,
                size: 37,
                shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        lat.isEmpty || lon.isEmpty
                            ? 'Koordinat lokasi belum diatur'
                            : 'Koordinat: $lat, $lon',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 8,
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: _editLocation,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.orange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Ubah Lokasi',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, color: AppColors.orange),
              const SizedBox(height: 10),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadProfile,
                child: const Text('Coba lagi'),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PasswordResetScreen(),
                  ),
                ),
                child: const Text('Lupa Password?'),
              ),
            ],
          ),
        ),
      );
    }
    final initial = _fields['nama']!.text.trim().isEmpty
        ? 'R'
        : _fields['nama']!.text.trim()[0].toUpperCase();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            _profileTopBar(),
            const SizedBox(height: 16),
            _profileHeaderCard(initial),
            const SizedBox(height: 18),
            _sectionLabel('DATA PRIBADI'),
            const SizedBox(height: 10),
            _field('nama', 'Nama Lengkap (Sesuai KTP)'),
            _field('telepon', 'Nomor HP / WhatsApp', readOnly: true),
            _field('nik', 'NIK (KTP)', keyboardType: TextInputType.number),
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 2, bottom: 4),
                    child: Text(
                      'TIPE PENGGUNA',
                      style: TextStyle(
                        fontSize: 8,
                        color: AppColors.muted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    value: _jenisTempat,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 9,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: const BorderSide(color: _line),
                      ),
                    ),
                    items: const ['Rumah Tangga', 'Sekolah', 'Kantor', 'Usaha']
                        .map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        })
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _jenisTempat = value);
                    },
                  ),
                ],
              ),
            ),
            _sectionLabel('ALAMAT'),
            _field('alamatLengkap', 'Alamat Lengkap'),
            Row(
              children: [
                Expanded(child: _field('rt', 'RT')),
                const SizedBox(width: 8),
                Expanded(child: _field('rw', 'RW')),
              ],
            ),
            _field('kelurahan', 'Kelurahan / Desa'),
            _field('kecamatan', 'Kecamatan'),
            _field('kota', 'Kota / Kabupaten'),
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Text(
                'PINDAI LOKASI',
                style: const TextStyle(
                  fontSize: 8,
                  color: AppColors.muted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _locationMap(),
            const SizedBox(height: 16),
            _sectionLabel('REKENING PENCAIRAN'),
            if (_paymentMethods.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _line),
                ),
                child: const Text(
                  'Belum ada metode pencairan. Tambahkan rekening atau e-wallet.',
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              )
            else
              ..._paymentMethods.map(_paymentCard),
            OutlinedButton.icon(
              onPressed: _addPaymentMethod,
              icon: const Icon(Icons.add_circle, color: AppColors.orange),
              label: const Text('Tambah Metode Pencairan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.dark,
                side: const BorderSide(color: _line),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _saving ? null : _saveProfile,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.dark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Simpan Perubahan'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout_rounded, color: AppColors.orange),
              label: const Text('Keluar dari Akun'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.orange,
                side: const BorderSide(color: _line),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PasswordResetScreen()),
              ),
              child: const Text('Lupa Password?'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFFF3EED8)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final minorRoad = Paint()
      ..color = const Color(0xFFE8E2C7)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final roads = [
      Path()
        ..moveTo(0, size.height * .78)
        ..cubicTo(
          size.width * .25,
          size.height * .55,
          size.width * .55,
          size.height * .8,
          size.width,
          size.height * .42,
        ),
      Path()
        ..moveTo(size.width * .12, 0)
        ..cubicTo(
          size.width * .35,
          size.height * .25,
          size.width * .55,
          size.height * .2,
          size.width * .76,
          size.height,
        ),
      Path()
        ..moveTo(size.width * .62, 0)
        ..lineTo(size.width * .48, size.height * .46)
        ..lineTo(size.width, size.height * .82),
      Path()
        ..moveTo(0, size.height * .32)
        ..lineTo(size.width * .4, size.height * .48)
        ..lineTo(size.width * .82, size.height * .08),
    ];
    for (final path in roads) {
      canvas.drawPath(path, roadPaint);
      canvas.drawPath(path, minorRoad);
    }
    final parkPaint = Paint()..color = const Color(0x503B7A2F);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .04,
          size.height * .05,
          size.width * .24,
          size.height * .19,
        ),
        const Radius.circular(9),
      ),
      parkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .73,
          size.height * .58,
          size.width * .22,
          size.height * .23,
        ),
        const Radius.circular(9),
      ),
      parkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

