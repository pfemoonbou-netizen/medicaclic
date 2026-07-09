import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import '../widgets/app_bottom_nav.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  final _products = [
    _FavItem('SUMMER LOOLET SCRAF', 'LOOLET STORE', '1400 DA', '2000 DA'),
    _FavItem('Modern accessorizes', 'MK STORE', '4900 DA', null),
    _FavItem('Light Dress Yellow', 'Dress Modern', '122.99 \$', null),
    _FavItem('LOOLET CHEMISE ETE', 'LOOLET STORE', '4500 DA', null),
  ];

  final _stores = [
    _FavStore('LOOLET STORE', '48k abonnés', true),
    _FavStore('femmedz', '12k abonnés', false),
    _FavStore('MK STORE', '5.3k abonnés', true),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Favoris',
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 18,
                fontWeight: FontWeight.w900)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.nearBlack,
          unselectedLabelColor: AppColors.grayLight,
          indicatorColor: AppColors.nearBlack,
          indicatorWeight: 2,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: AppColors.lightGray,
          labelStyle: GoogleFonts.montserrat(
              fontSize: 13, fontWeight: FontWeight.w800),
          unselectedLabelStyle: GoogleFonts.montserrat(
              fontSize: 13, fontWeight: FontWeight.w500),
          tabs: const [Tab(text: 'Produits'), Tab(text: 'Boutiques')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_buildProducts(), _buildStores()],
      ),
      bottomNavigationBar: AppBottomNav(activeTab: NavTab.shop),
    );
  }

  Widget _buildProducts() {
    if (_products.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.favorite_border, size: 64, color: AppColors.lightGray),
          const SizedBox(height: 12),
          Text('Aucun favori',
              style: GoogleFonts.montserrat(
                  color: AppColors.gray, fontSize: 14)),
        ]),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemCount: _products.length,
      itemBuilder: (_, i) => _productCard(i),
    );
  }

  Widget _productCard(int i) {
    final p = _products[i];
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/product'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 16,
                offset: Offset(0, 4))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Stack(children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: Container(color: AppColors.lightGray, width: double.infinity),
              ),
              Positioned(
                top: 8, right: 8,
                child: GestureDetector(
                  onTap: () => setState(() => _products.removeAt(i)),
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15)),
                    child: const Icon(Icons.favorite,
                        size: 16, color: AppColors.accent),
                  ),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name,
                  style: GoogleFonts.montserrat(
                      color: AppColors.nearBlack, fontSize: 12,
                      fontWeight: FontWeight.w700),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(p.store,
                  style: GoogleFonts.montserrat(
                      color: AppColors.gray, fontSize: 10)),
              const SizedBox(height: 4),
              Row(children: [
                Text(p.price,
                    style: GoogleFonts.montserrat(
                        color: AppColors.nearBlack, fontSize: 13,
                        fontWeight: FontWeight.bold)),
                if (p.oldPrice != null) ...[
                  const SizedBox(width: 6),
                  Text(p.oldPrice!,
                      style: GoogleFonts.montserrat(
                          color: AppColors.gray, fontSize: 10,
                          decoration: TextDecoration.lineThrough)),
                ],
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildStores() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: _stores.length,
      itemBuilder: (_, i) {
        final s = _stores[i];
        return Row(children: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/store'),
            child: Row(children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.dark,
                child: Text(s.name[0],
                    style: GoogleFonts.montserrat(
                        color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.name,
                    style: GoogleFonts.montserrat(
                        color: AppColors.nearBlack, fontSize: 14,
                        fontWeight: FontWeight.w700)),
                Text(s.followers,
                    style: GoogleFonts.montserrat(
                        color: AppColors.gray, fontSize: 12)),
              ]),
            ]),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () =>
                setState(() => _stores[i] = s.copyWith(!s.following)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: s.following ? Colors.transparent : AppColors.dark,
                border: Border.all(
                    color: s.following ? AppColors.lightGray : AppColors.dark),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(s.following ? 'Suivi' : 'Suivre',
                  style: GoogleFonts.montserrat(
                      color: s.following ? AppColors.gray : Colors.white,
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ]);
      },
    );
  }
}

class _FavItem {
  final String name, store, price;
  final String? oldPrice;
  const _FavItem(this.name, this.store, this.price, this.oldPrice);
}

class _FavStore {
  final String name, followers;
  final bool following;
  const _FavStore(this.name, this.followers, this.following);
  _FavStore copyWith(bool following) =>
      _FavStore(name, followers, following);
}
