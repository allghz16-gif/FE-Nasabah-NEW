import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nasabah_resik/services/api_service.dart';
part 'tema/warna_dan_bantuan.dart';
part 'aplikasi/aplikasi_dan_sesi.dart';
part 'navigasi/navigasi_utama.dart';
part 'halaman/profil_nasabah.dart';
part 'halaman/halaman_kosong.dart';
part 'halaman/riwayat.dart';
part 'halaman/notifikasi.dart';
part 'halaman/setor_sampah.dart';
part 'komponen/komponen_umum.dart';
part 'halaman/beranda.dart';
part 'halaman/chatbot.dart';
part 'halaman/tukar_saldo.dart';
part 'halaman/autentikasi_bersama.dart';
part 'halaman/login_lupa_sandi.dart';
part 'halaman/registrasi_data_diri.dart';
part 'halaman/registrasi_buat_sandi.dart';
part 'halaman/registrasi_berhasil.dart';

void main() => runApp(const ResikApp());
