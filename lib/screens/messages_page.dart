import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

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

  static const _convos = [
    _Convo('LOOLET STORE', 'Votre colis a été expédié !', '5 min', 2, true),
    _Convo('MK STORE', 'Merci pour votre commande.', '1h', 0, true),
    _Convo('femmedz', 'Merci pour le like 🌸', '3h', 1, false),
    _Convo('Support LINCOO', 'Votre ticket #T-2024 a été traité.', 'Hier', 0, false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Messages',
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 18,
                fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square, color: AppColors.nearBlack, size: 22),
            onPressed: () {},
          ),
        ],
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
          tabs: const [Tab(text: 'Messages'), Tab(text: 'Demandes')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_buildConvoList(), _buildRequests()],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.dark,
        onPressed: () {},
        child: const Icon(Icons.chat_outlined, color: Colors.white),
      ),
    );
  }

  Widget _buildConvoList() {
    return ListView.separated(
      separatorBuilder: (_, __) =>
          const Divider(indent: 70, height: 1, color: AppColors.lightGray),
      itemCount: _convos.length,
      itemBuilder: (_, i) => _convoTile(_convos[i]),
    );
  }

  Widget _convoTile(_Convo c) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.dark,
            child: Text(c.name[0],
                style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
          ),
          if (c.online)
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2)),
              ),
            ),
        ],
      ),
      title: Text(c.name,
          style: GoogleFonts.montserrat(
              color: AppColors.nearBlack,
              fontSize: 14,
              fontWeight: c.unread > 0 ? FontWeight.w800 : FontWeight.normal)),
      subtitle: Text(c.lastMsg,
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: GoogleFonts.montserrat(
              color: c.unread > 0 ? AppColors.nearBlack : AppColors.gray,
              fontSize: 12)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(c.time,
              style: GoogleFonts.montserrat(
                  color: c.unread > 0 ? AppColors.blue : AppColors.gray,
                  fontSize: 11)),
          if (c.unread > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: AppColors.blue,
                  borderRadius: BorderRadius.circular(10)),
              child: Text('${c.unread}',
                  style: GoogleFonts.montserrat(
                      color: Colors.white, fontSize: 10)),
            ),
          ],
        ],
      ),
      onTap: () {},
    );
  }

  Widget _buildRequests() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.mark_chat_unread_outlined,
            size: 64, color: AppColors.lightGray),
        const SizedBox(height: 12),
        Text('Aucune demande en attente',
            style: GoogleFonts.montserrat(
                color: AppColors.gray, fontSize: 14)),
      ]),
    );
  }
}

class _Convo {
  final String name, lastMsg, time;
  final int unread;
  final bool online;
  const _Convo(this.name, this.lastMsg, this.time, this.unread, this.online);
}
