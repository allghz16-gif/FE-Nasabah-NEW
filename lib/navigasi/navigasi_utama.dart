// Navigasi utama dan pergantian halaman.
part of 'package:nasabah_resik/main.dart';

// ---------------------------------------------------------------
// SHELL: halaman + bottom navigation
// ---------------------------------------------------------------
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  bool showNotifications = false;
  bool showChat = false;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(
        onNotifications: () => setState(() {
          showNotifications = true;
          showChat = false;
        }),
        onChat: () => setState(() {
          showChat = true;
          showNotifications = false;
        }),
        onProfile: () => setState(() {
          index = 4;
          showChat = false;
          showNotifications = false;
        }),
      ),
      TukarSaldoPage(onBack: () => setState(() => index = 0)),
      SetorPage(onBack: () => setState(() => index = 0)),
      RiwayatPage(onBack: () => setState(() => index = 0)),
      ProfilNasabahPage(
        key: const Key('nasabah-profile-tab'),
        onBack: () => setState(() => index = 0),
        onChat: () => setState(() {
          showChat = true;
          showNotifications = false;
        }),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: showChat
            ? ChatPage(onBack: () => setState(() => showChat = false))
            : showNotifications
            ? NotifikasiNasabahPage(
                onBack: () => setState(() => showNotifications = false),
              )
            : pages[index],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE6DFCF)),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_outlined, 'Beranda'),
              _navItem(1, Icons.account_balance_wallet_outlined, 'Tukar'),
              _navItem(2, Icons.recycling_rounded, 'Setor'),
              _navItem(3, Icons.receipt_long_outlined, 'Riwayat'),
              _navItem(4, Icons.person_rounded, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int i, IconData icon, String label) {
    final active = index == i;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() {
        index = i;
        showChat = false;
        showNotifications = false;
      }),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? AppColors.orange : AppColors.dark),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: active ? AppColors.orange : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
                color: active ? Colors.white : AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

