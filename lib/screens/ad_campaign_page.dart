import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';
import '../models/ad_campaign.dart';
import '../services/access_control.dart';
import '../services/user_session.dart';
import '../widgets/gated.dart';

class AdCampaignPage extends StatefulWidget {
  const AdCampaignPage({super.key});

  @override
  State<AdCampaignPage> createState() => _AdCampaignPageState();
}

class _AdCampaignPageState extends State<AdCampaignPage> {
  List<AdCampaign> _campaigns = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = UserSession.instance.current;
    if (user.isGuest) {
      setState(() => _loading = false);
      return;
    }
    try {
      final rows = await Supabase.instance.client
          .from('ad_campaigns')
          .select()
          .eq('company_id', user.id)
          .order('created_at', ascending: false);
      setState(() {
        _campaigns = (rows as List).map((r) => AdCampaign.fromMap(r)).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _submit(int index) async {
    try {
      await Supabase.instance.client
          .from('ad_campaigns')
          .update({'status': AdStatus.submitted.name})
          .eq('id', _campaigns[index].id);
      setState(() {
        _campaigns[index] = _campaigns[index].copyWith(status: AdStatus.submitted);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Campagne soumise pour révision !'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _delete(int index) async {
    try {
      await Supabase.instance.client
          .from('ad_campaigns')
          .delete()
          .eq('id', _campaigns[index].id);
      setState(() => _campaigns.removeAt(index));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FB),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.nearBlack, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Mes Campagnes',
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack, fontSize: 18,
                fontWeight: FontWeight.w900)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(
              color: AppColors.accent, strokeWidth: 2))
          : Column(children: [
              _buildStats(),
              Expanded(
                child: _campaigns.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemCount: _campaigns.length,
                          itemBuilder: (_, i) => _CampaignCard(
                            campaign: _campaigns[i],
                            onSubmit: () => _submit(i),
                            onDelete: () => _delete(i),
                          ),
                        ),
                      ),
              ),
            ]),
      floatingActionButton: GatedTap(
        capability: Capability.manageCampaigns,
        onAllowed: () => _showCreateSheet(context),
        child: FloatingActionButton.extended(
          onPressed: null,
          backgroundColor: AppColors.nearBlack,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text('Nouvelle campagne',
              style: GoogleFonts.montserrat(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _buildStats() {
    final active   = _campaigns.where((c) => c.status == AdStatus.active).length;
    final pending  = _campaigns.where((c) =>
        c.status == AdStatus.submitted || c.status == AdStatus.inReview).length;
    final totalBudget = _campaigns.fold<int>(0, (s, c) => s + c.budgetDZD);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(children: [
        _StatChip('Actives',   '$active',         Colors.green),
        const SizedBox(width: 8),
        _StatChip('En attente', '$pending',        const Color(0xFFFFB300)),
        const SizedBox(width: 8),
        _StatChip('Budget total', '$totalBudget DA', AppColors.blue),
      ]),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          color: AppColors.blue.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.campaign_outlined,
            size: 36, color: AppColors.blue),
      ),
      const SizedBox(height: 16),
      Text('Aucune campagne',
          style: GoogleFonts.montserrat(
              color: AppColors.nearBlack, fontSize: 15,
              fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text('Créez votre première campagne publicitaire\net touchez des milliers d\'acheteurs.',
          style: GoogleFonts.montserrat(
              color: AppColors.gray, fontSize: 12),
          textAlign: TextAlign.center),
    ]),
  );

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CreateCampaignSheet(
        onCreate: (campaign) {
          setState(() => _campaigns.insert(0, campaign));
        },
      ),
    );
  }
}

// ── Campaign card ─────────────────────────────────────────────────────────────

class _CampaignCard extends StatelessWidget {
  final AdCampaign campaign;
  final VoidCallback onSubmit;
  final VoidCallback onDelete;
  const _CampaignCard({required this.campaign, required this.onSubmit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(campaign.status);
    final days = campaign.startDate != null && campaign.endDate != null
        ? campaign.endDate!.difference(campaign.startDate!).inDays + 1
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.campaign_rounded, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(campaign.title,
                  style: GoogleFonts.montserrat(
                      color: AppColors.nearBlack, fontSize: 14,
                      fontWeight: FontWeight.w800),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(campaign.statusLabel,
                      style: GoogleFonts.montserrat(
                          color: statusColor, fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ]),
            ]),
          ),
        ]),

        if (campaign.description != null) ...[
          const SizedBox(height: 10),
          Text(campaign.description!,
              style: GoogleFonts.montserrat(
                  color: AppColors.gray, fontSize: 12),
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ],

        const SizedBox(height: 12),
        const Divider(height: 1, color: AppColors.lightGray),
        const SizedBox(height: 12),

        // Meta grid
        Row(children: [
          _metaItem(Icons.payments_outlined, '${campaign.budgetDZD} DA',
              AppColors.blue),
          const SizedBox(width: 16),
          if (days != null)
            _metaItem(Icons.calendar_today_outlined, '$days jours',
                AppColors.gray),
          const SizedBox(width: 16),
          if (campaign.paymentMethod != null)
            _metaItem(Icons.credit_card_outlined,
                campaign.paymentMethod!.label.split(' ').first,
                const Color(0xFF6C63FF)),
        ]),

        if (campaign.startDate != null) ...[
          const SizedBox(height: 6),
          _metaItem(
            Icons.date_range_outlined,
            '${_fmt(campaign.startDate!)} → ${_fmt(campaign.endDate ?? campaign.startDate!)}',
            AppColors.grayLight,
          ),
        ],

        // Action buttons (draft only)
        if (campaign.status == AdStatus.draft) ...[
          const SizedBox(height: 14),
          Row(children: [
            OutlinedButton(
              onPressed: onDelete,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.lightGray),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
              ),
              child: Text('Supprimer',
                  style: GoogleFonts.montserrat(
                      color: AppColors.gray, fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.nearBlack,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: Text('Soumettre pour révision',
                    style: GoogleFonts.montserrat(
                        fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ],
      ]),
    );
  }

  Widget _metaItem(IconData icon, String label, Color color) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.montserrat(color: color, fontSize: 11,
                fontWeight: FontWeight.w500)),
      ]);

  Color _statusColor(AdStatus s) => switch (s) {
    AdStatus.draft     => AppColors.gray,
    AdStatus.submitted => AppColors.blue,
    AdStatus.inReview  => const Color(0xFFFFB300),
    AdStatus.approved  => AppColors.success,
    AdStatus.rejected  => AppColors.error,
    AdStatus.active    => AppColors.success,
    AdStatus.ended     => AppColors.grayLight,
  };

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Text(value,
            style: GoogleFonts.montserrat(
                color: color, fontSize: 14, fontWeight: FontWeight.w900)),
        const SizedBox(height: 1),
        Text(label,
            style: GoogleFonts.montserrat(
                color: AppColors.gray, fontSize: 9,
                fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

// ── Create campaign bottom sheet ──────────────────────────────────────────────

class _CreateCampaignSheet extends StatefulWidget {
  final void Function(AdCampaign) onCreate;
  const _CreateCampaignSheet({required this.onCreate});

  @override
  State<_CreateCampaignSheet> createState() => _CreateCampaignSheetState();
}

class _CreateCampaignSheetState extends State<_CreateCampaignSheet> {
  final _titleCtrl  = TextEditingController();
  final _descCtrl   = TextEditingController();
  final _budgetCtrl = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  AdPaymentMethod? _paymentMethod;
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  int get _durationDays {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Date de début',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.nearBlack),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEnd() async {
    if (_startDate == null) {
      await _pickStart();
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate!.add(const Duration(days: 7)),
      firstDate: _startDate!,
      lastDate: _startDate!.add(const Duration(days: 365)),
      helpText: 'Date de fin',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.nearBlack),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _create() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Le titre est obligatoire.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (_paymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Choisissez une méthode de paiement.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _loading = true);

    final user   = UserSession.instance.current;
    final budget = int.tryParse(_budgetCtrl.text.trim()) ?? 0;

    final data = {
      'company_id':     user.id,
      'title':          _titleCtrl.text.trim(),
      'description':    _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      'status':         'draft',
      'budget_dzd':     budget,
      'start_date':     _startDate?.toIso8601String().split('T').first,
      'end_date':       _endDate?.toIso8601String().split('T').first,
      'placement':      'home_banner',
      'payment_method': _paymentMethod!.name,
    };

    try {
      final row = await Supabase.instance.client
          .from('ad_campaigns')
          .insert(data)
          .select()
          .single();

      final campaign = AdCampaign.fromMap(row);
      if (mounted) {
        setState(() => _loading = false);
        widget.onCreate(campaign);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Campagne créée en brouillon !'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = _titleCtrl.text.trim().isNotEmpty &&
        _paymentMethod != null &&
        (_budgetCtrl.text.trim().isNotEmpty);

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.accent, AppColors.blue]),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.campaign_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Nouvelle campagne',
                  style: GoogleFonts.montserrat(
                      color: AppColors.nearBlack, fontSize: 17,
                      fontWeight: FontWeight.w900)),
              Text('Bannière publicitaire · Accueil',
                  style: GoogleFonts.montserrat(
                      color: AppColors.grayLight, fontSize: 11)),
            ]),
          ]),
          const SizedBox(height: 24),

          // ── Champs de base ───────────────────────────────────────────────────
          _label('Titre de la campagne *'),
          const SizedBox(height: 6),
          _textField(_titleCtrl, 'Ex : Soldes été 2026',
              icon: Icons.title_rounded,
              onChanged: (_) => setState(() {})),
          const SizedBox(height: 14),

          _label('Description'),
          const SizedBox(height: 6),
          _textField(_descCtrl, 'Message affiché sur la bannière...',
              icon: Icons.notes_rounded, maxLines: 2),
          const SizedBox(height: 14),

          // ── Budget ──────────────────────────────────────────────────────────
          _label('Budget (DA) *'),
          const SizedBox(height: 6),
          _textField(_budgetCtrl, 'Ex : 15000',
              icon: Icons.payments_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {})),
          const SizedBox(height: 14),

          // ── Durée / Dates ────────────────────────────────────────────────────
          _label('Période de diffusion'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: _pickStart,
                child: _dateBox(
                  label: 'Date début',
                  value: _startDate != null ? _fmtDate(_startDate!) : null,
                  icon: Icons.calendar_today_rounded,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: AppColors.grayLight, size: 16),
            ),
            Expanded(
              child: GestureDetector(
                onTap: _pickEnd,
                child: _dateBox(
                  label: 'Date fin',
                  value: _endDate != null ? _fmtDate(_endDate!) : null,
                  icon: Icons.event_rounded,
                ),
              ),
            ),
          ]),
          if (_durationDays > 0) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.timer_outlined, size: 13, color: AppColors.blue),
              const SizedBox(width: 4),
              Text('Durée : $_durationDays jours',
                  style: GoogleFonts.montserrat(
                      color: AppColors.blue, fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ]),
          ],
          const SizedBox(height: 20),

          // ── Méthode de paiement ──────────────────────────────────────────────
          _label('Méthode de paiement *'),
          const SizedBox(height: 10),
          ...AdPaymentMethod.values.map((method) => _PaymentOption(
            method: method,
            selected: _paymentMethod == method,
            onTap: () => setState(() => _paymentMethod = method),
          )),
          const SizedBox(height: 24),

          // ── Info box ─────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.blue.withValues(alpha: 0.2)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.info_outline_rounded,
                  size: 16, color: AppColors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Votre campagne sera créée en brouillon. '
                  'Vous pourrez la soumettre pour révision avant publication.',
                  style: GoogleFonts.montserrat(
                      color: AppColors.blue, fontSize: 11),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Bouton créer ─────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (canCreate && !_loading) ? _create : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.nearBlack,
                disabledBackgroundColor: AppColors.lightGray,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('Créer en brouillon',
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _label(String text) => Text(text,
    style: GoogleFonts.montserrat(
        color: AppColors.nearBlack, fontSize: 12,
        fontWeight: FontWeight.w700));

  Widget _textField(
    TextEditingController ctrl,
    String hint, {
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.nearBlack),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.montserrat(
              color: AppColors.lightGray, fontSize: 13),
          prefixIcon: Icon(icon, color: AppColors.gray, size: 18),
          filled: true,
          fillColor: AppColors.surfaceAlt,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightGray)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightGray)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppColors.nearBlack, width: 1.5)),
        ),
      );

  Widget _dateBox({
    required String label,
    required String? value,
    required IconData icon,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: value != null
              ? AppColors.nearBlack.withValues(alpha: 0.05)
              : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value != null ? AppColors.nearBlack : AppColors.lightGray,
            width: value != null ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Icon(icon, size: 15,
              color: value != null ? AppColors.nearBlack : AppColors.grayLight),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: GoogleFonts.montserrat(
                      color: AppColors.grayLight, fontSize: 9,
                      fontWeight: FontWeight.w600)),
              Text(value ?? 'Choisir',
                  style: GoogleFonts.montserrat(
                      color: value != null
                          ? AppColors.nearBlack
                          : AppColors.gray,
                      fontSize: 12,
                      fontWeight: value != null
                          ? FontWeight.w700
                          : FontWeight.w500)),
            ]),
          ),
        ]),
      );
}

// ── Payment method option tile ─────────────────────────────────────────────────

class _PaymentOption extends StatelessWidget {
  final AdPaymentMethod method;
  final bool selected;
  final VoidCallback onTap;
  const _PaymentOption({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (method) {
      AdPaymentMethod.ccp       => (Icons.account_balance_outlined, const Color(0xFF0D7A3E)),
      AdPaymentMethod.baridimob => (Icons.phone_android_outlined,   const Color(0xFF0D7A3E)),
      AdPaymentMethod.virement  => (Icons.swap_horiz_rounded,       AppColors.blue),
      AdPaymentMethod.carte     => (Icons.credit_card_rounded,      const Color(0xFF6C63FF)),
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.07) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppColors.lightGray,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Text(method.label,
              style: GoogleFonts.montserrat(
                  color: selected ? color : AppColors.nearBlack,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
          const Spacer(),
          if (selected)
            Icon(Icons.check_circle_rounded, color: color, size: 20),
        ]),
      ),
    );
  }
}
