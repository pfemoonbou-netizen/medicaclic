import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final _msgCtrl = TextEditingController();
  final _scroll  = ScrollController();
  final _msgs    = <_Msg>[];
  bool _typing     = false;
  bool _showWelcome = true;

  static const _topics = [
    _Topic(Icons.inventory_2_outlined,   'Mes commandes'),
    _Topic(Icons.undo_outlined,          'Retours & remboursements'),
    _Topic(Icons.payment_outlined,       'Paiement'),
    _Topic(Icons.local_shipping_outlined,'Livraison'),
    _Topic(Icons.card_giftcard_outlined, 'Points & récompenses'),
    _Topic(Icons.storefront_outlined,    'Vendeurs'),
  ];

  static const _faq = [
    'Suivre ma commande',
    'Politique de retour',
    'Problème de paiement',
    'Contacter un vendeur',
  ];

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── Send / reply ───────────────────────────────────────────────────────────

  void _send(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _showWelcome = false;
      _msgs.add(_Msg(true, text.trim(), DateTime.now()));
      _msgCtrl.clear();
      _typing = true;
    });
    _scrollDown();

    final delay = 900 + (text.length * 18).clamp(0, 800);
    await Future.delayed(Duration(milliseconds: delay));
    if (!mounted) return;

    setState(() {
      _typing = false;
      _msgs.add(_Msg(false, _reply(text.trim()), DateTime.now()));
    });
    _scrollDown();
  }

  String _reply(String msg) {
    final q = msg.toLowerCase();
    if (q.contains('commande') || q.contains('suivi') || q.contains('tracking')) {
      return '📦 Pour suivre votre commande :\n\n'
          '1. Allez dans « Mes Commandes »\n'
          '2. Sélectionnez la commande\n'
          '3. Appuyez sur « Suivi »\n\n'
          'Vous avez aussi reçu un e-mail de confirmation avec un lien de tracking.';
    }
    if (q.contains('retour') || q.contains('remboursement')) {
      return '↩️ Politique de retour LINCOO :\n\n'
          '• Délai : 7 jours après réception\n'
          '• État : produit non utilisé, emballage d\'origine\n'
          '• Procédure : Mes Commandes → « Demander un retour »\n\n'
          'Le remboursement est effectué sous 3–5 jours ouvrables.';
    }
    if (q.contains('paiement') || q.contains('cib') || q.contains('edahabia')) {
      return '💳 Modes de paiement acceptés :\n\n'
          '• Paiement à la livraison (espèces)\n'
          '• Carte CIB — bientôt disponible\n'
          '• Carte EDAHABIA — bientôt disponible\n'
          '• Wallet LINCOO — créateurs uniquement\n\n'
          'Pour un problème de paiement, créez un ticket dans le Centre d\'aide.';
    }
    if (q.contains('livraison') || q.contains('délai') || q.contains('expédition')) {
      return '🚚 Délais & tarifs de livraison :\n\n'
          '• Fast ⚡ : 1–2 jours · 700 DA\n'
          '• Standard 📦 : 3–5 jours · 350 DA\n'
          '• Smart Delivery 🚀 : 2–3 jours · 450 DA\n\n'
          'Les délais sont indicatifs et peuvent varier selon la wilaya.';
    }
    if (q.contains('vendeur') || q.contains('boutique') || q.contains('contacter')) {
      return '🏪 Pour contacter un vendeur :\n\n'
          '1. Ouvrez la page de la boutique\n'
          '2. Appuyez sur « Contacter la boutique »\n'
          '3. Appelez directement le vendeur\n\n'
          'Communiquez toujours via LINCOO pour votre sécurité.';
    }
    if (q.contains('point') || q.contains('récompense') || q.contains('fidélité')) {
      return '🎁 Programme LINCOO Points :\n\n'
          '• Achat : +10 pts / 100 DA dépensés\n'
          '• Avis laissé : +15 pts\n'
          '• Partage : +5 pts\n\n'
          'Vos points sont convertibles en réductions depuis « Récompenses ».';
    }
    if (q.contains('wallet') || q.contains('solde')) {
      return '👛 Wallet LINCOO :\n\n'
          'Le Wallet est actuellement réservé aux créateurs & boutiques.\n\n'
          'Il sera bientôt disponible pour les acheteurs. Vous serez notifié dès l\'ouverture.';
    }
    if (q.contains('compte') || q.contains('profil') || q.contains('mot de passe')) {
      return '👤 Gestion de votre compte :\n\n'
          '• Modifier le profil : Paramètres → Modifier\n'
          '• Mot de passe oublié : Connexion → « Mot de passe oublié »\n'
          '• Supprimer le compte : Paramètres → Aide\n\n'
          'Besoin d\'aide ? Créez un ticket de support.';
    }
    return '🤔 Je n\'ai pas trouvé de réponse précise pour « $msg ».\n\n'
        'Pour une assistance personnalisée :\n'
        '• Consultez notre Centre d\'aide\n'
        '• Créez un ticket — réponse sous 24h';
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: _buildAppBar(),
      body: Column(children: [
        Expanded(child: _showWelcome ? _buildWelcome() : _buildChat()),
        _buildInputBar(),
      ]),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() => AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.nearBlack, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          _aiAvatar(36, 12),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Assistant IA LINCOO',
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w900)),
            Row(children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: Colors.green, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text('En ligne · Propulsé par IA',
                  style: GoogleFonts.montserrat(
                      color: AppColors.gray, fontSize: 10)),
            ]),
          ]),
        ]),
        actions: [
          if (!_showWelcome)
            IconButton(
              tooltip: 'Nouveau sujet',
              onPressed: () =>
                  setState(() { _msgs.clear(); _showWelcome = true; }),
              icon: const Icon(Icons.refresh_outlined,
                  color: AppColors.gray, size: 20),
            ),
        ],
      );

  // ── Welcome screen ─────────────────────────────────────────────────────────

  Widget _buildWelcome() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Hero card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B1C), Color(0xFF6E1128)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text('LINCOO AI',
                  style: GoogleFonts.montserrat(
                      color: Colors.white60,
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 16),
            Text('Bonjour ! 👋',
                style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(
              'Comment puis-je vous aider aujourd\'hui ?\nPosez-moi n\'importe quelle question.',
              style: GoogleFonts.montserrat(
                  color: Colors.white60, fontSize: 13, height: 1.6),
            ),
          ]),
        ),

        const SizedBox(height: 24),
        Text('Choisissez un sujet',
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 14,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),

        // Topic grid 2 columns
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.5,
          children: _topics
              .map((t) => GestureDetector(
                    onTap: () => _send(t.label),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.lightGray),
                      ),
                      child: Row(children: [
                        Icon(t.icon, size: 17, color: AppColors.nearBlack),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(t.label,
                              style: GoogleFonts.montserrat(
                                  color: AppColors.nearBlack,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                    ),
                  ))
              .toList(),
        ),

        const SizedBox(height: 20),
        Text('Questions fréquentes',
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 14,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),

        ..._faq.map((s) => GestureDetector(
              onTap: () => _send(s),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.lightGray),
                ),
                child: Row(children: [
                  const Icon(Icons.chevron_right,
                      size: 16, color: AppColors.gray),
                  const SizedBox(width: 8),
                  Text(s,
                      style: GoogleFonts.montserrat(
                          color: AppColors.nearBlack, fontSize: 13)),
                ]),
              ),
            )),
      ],
    );
  }

  // ── Chat ───────────────────────────────────────────────────────────────────

  Widget _buildChat() => ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        itemCount: _msgs.length + (_typing ? 1 : 0),
        itemBuilder: (_, i) {
          if (_typing && i == _msgs.length) return _buildTypingBubble();
          return _buildBubble(_msgs[i]);
        },
      );

  Widget _buildBubble(_Msg msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _aiAvatar(28, 8),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 11),
                  constraints: BoxConstraints(
                      maxWidth:
                          MediaQuery.of(context).size.width * 0.72),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.nearBlack : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft:
                          Radius.circular(isUser ? 16 : 4),
                      bottomRight:
                          Radius.circular(isUser ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Text(msg.text,
                      style: GoogleFonts.montserrat(
                          color: isUser
                              ? Colors.white
                              : AppColors.nearBlack,
                          fontSize: 13,
                          height: 1.6)),
                ),
                const SizedBox(height: 3),
                Text(
                  '${msg.time.hour.toString().padLeft(2, '0')}:'
                  '${msg.time.minute.toString().padLeft(2, '0')}',
                  style: GoogleFonts.montserrat(
                      color: AppColors.gray, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingBubble() => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _aiAvatar(28, 8),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: const _TypingDots(),
          ),
        ]),
      );

  // ── Input bar ──────────────────────────────────────────────────────────────

  Widget _buildInputBar() => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 28),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.bgGray,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.lightGray),
              ),
              child: TextField(
                controller: _msgCtrl,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Posez votre question…',
                  hintStyle: GoogleFonts.montserrat(
                      color: const Color(0xFFCAC9C9), fontSize: 13),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.fromLTRB(16, 12, 16, 12),
                ),
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack, fontSize: 13),
                onSubmitted: _send,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _send(_msgCtrl.text),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF292526), Color(0xFF6E1128)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(23),
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ]),
      );

  // ── Shared AI avatar ───────────────────────────────────────────────────────

  Widget _aiAvatar(double size, double radius) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF292526), Color(0xFF6E1128)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Icon(Icons.auto_awesome,
            color: Colors.white, size: size * 0.45),
      );
}

// ── Animated typing dots ───────────────────────────────────────────────────

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _dot(0.0),
      const SizedBox(width: 5),
      _dot(0.33),
      const SizedBox(width: 5),
      _dot(0.66),
    ]);
  }

  Widget _dot(double offset) => AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final phase =
              ((_ctrl.value - offset) % 1.0 + 1.0) % 1.0;
          final scale =
              0.6 + 0.4 * (1.0 - (phase * 2 - 1).abs());
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.gray,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        },
      );
}

// ── Data ───────────────────────────────────────────────────────────────────

class _Msg {
  final bool isUser;
  final String text;
  final DateTime time;
  const _Msg(this.isUser, this.text, this.time);
}

class _Topic {
  final IconData icon;
  final String label;
  const _Topic(this.icon, this.label);
}
