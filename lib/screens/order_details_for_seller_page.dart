import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_colors.dart';
import '../widgets/primary_button.dart';

class OrderDetailsForSellerPage extends StatefulWidget {
  const OrderDetailsForSellerPage({super.key});

  @override
  State<OrderDetailsForSellerPage> createState() =>
      _OrderDetailsForSellerPageState();
}

class _OrderDetailsForSellerPageState extends State<OrderDetailsForSellerPage> {
  final _formKey = GlobalKey<FormState>();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  String? _orderId;
  RealtimeChannel? _channel;

  // Editable fields (public.orders)
  String? _status;
  String? _address;
  String? _wilaya;
  String? _notes;

  List<Map<String, dynamic>> _items = [];
  int _total = 0;
  String? _buyerName;
  String? _buyerPhone;
  String? _deliveryType;
  String? _paymentMethod;

  final _statusOptions = const [
    'pending',
    'confirmed',
    'shipped',
    'delivered',
    'cancelled',
    'refunded',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_orderId == null) {
      final rawArgs = ModalRoute.of(context)?.settings.arguments;
      if (rawArgs is Map) {
        final map = rawArgs.cast<String, dynamic>();
        final id = map['orderId'] ?? map['id'];
        if (id != null) _orderId = id.toString();
      }
      _hydrate();
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  void _applyRow(Map<String, dynamic> data) {
    if (!mounted) return;
    final items = (data['items'] as List?) ?? const [];
    setState(() {
      _status         = (data['status'] as String?) ?? 'pending';
      _address        = data['address'] as String?;
      _wilaya         = data['wilaya'] as String?;
      _notes          = data['notes'] as String?;
      _items          = items.map((i) => Map<String, dynamic>.from(i as Map)).toList();
      _total          = (data['total'] as num?)?.toInt() ?? 0;
      _buyerName      = data['buyer_name'] as String?;
      _buyerPhone     = data['buyer_phone'] as String?;
      _deliveryType   = data['delivery_type'] as String?;
      _paymentMethod  = data['payment_method'] as String?;
      _loading        = false;
      _error          = null;
    });
  }

  Future<void> _hydrate() async {
    if (_orderId == null || _orderId!.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'orderId manquant.';
        });
      }
      return;
    }

    try {
      final res = await Supabase.instance.client
          .from('orders')
          .select()
          .eq('id', _orderId!)
          .maybeSingle();

      if (res == null) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'Commande introuvable.';
          });
        }
        return;
      }

      _applyRow((res as Map).cast<String, dynamic>());
      _subscribe(_orderId!);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Erreur de chargement: $e';
        });
      }
    }
  }

  void _subscribe(String id) {
    _channel?.unsubscribe();
    _channel = Supabase.instance.client
        .channel('order-details-seller-$id')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq, column: 'id', value: id),
          callback: (payload) =>
              _applyRow(Map<String, dynamic>.from(payload.newRecord)),
        )
        .subscribe();
  }

  String _prettyStatus(String? s) {
    if (s == null) return '—';
    final upper = s.toUpperCase();
    return upper
        .replaceAll('PENDING', 'En attente')
        .replaceAll('CONFIRMED', 'Confirmée')
        .replaceAll('SHIPPED', 'Expédiée')
        .replaceAll('DELIVERED', 'Livrée')
        .replaceAll('CANCELLED', 'Annulée')
        .replaceAll('REFUNDED', 'Remboursée');
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;
    if (_orderId == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      // “toutes les details” => au moins : status, address, wilaya, notes
      // (les champs sensibles type unit_price/total_price ne sont pas exposés dans cette UI)
      final payload = <String, dynamic>{
        'status': _status,
        'address': _address,
        'wilaya': _wilaya,
        'notes': _notes,
      };

      await Supabase.instance.client
          .from('orders')
          .update(payload)
          .eq('id', _orderId!);

      await _hydrate();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Commande mise à jour ✅',
              style: GoogleFonts.montserrat(),
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Erreur de sauvegarde: $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _inputDecoration({String? hint, IconData? icon}) =>
      InputDecoration(
        hintText: hint,
        prefixIcon:
            icon != null ? Icon(icon, size: 18, color: AppColors.gray) : null,
        filled: true,
        fillColor: AppColors.bgGray,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      );

  Widget _fieldLabel(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          t,
          style: GoogleFonts.montserrat(
            color: AppColors.nearBlack,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      );

  Widget _pill(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.bgGray,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          t,
          style: GoogleFonts.montserrat(
            color: AppColors.gray,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _infoCard({required String orderId}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Commande #${orderId.length >= 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase()}',
            style: GoogleFonts.montserrat(
              color: AppColors.nearBlack,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Statut actuel: ${_prettyStatus(_status)}',
            style: GoogleFonts.montserrat(
              color: AppColors.gray,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          if (_items.isNotEmpty) ...[
            Text('Articles',
                style: GoogleFonts.montserrat(
                    color: AppColors.nearBlack,
                    fontSize: 12,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            ..._items.map((it) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${it['qty'] ?? 1}× ${it['name'] ?? 'Produit'}'
                    '${it['size'] != null ? ' (${it['size']})' : ''}',
                    style: GoogleFonts.montserrat(
                        color: AppColors.gray, fontSize: 12),
                  ),
                )),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _pill('Total: $_total DA'),
              _pill('Client: ${_buyerName ?? '—'}'),
              if (_buyerPhone != null) _pill('Tél: $_buyerPhone'),
              if (_deliveryType != null) _pill('Livraison: $_deliveryType'),
              if (_paymentMethod != null) _pill('Paiement: $_paymentMethod'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _editCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Modifier les détails',
            style: GoogleFonts.montserrat(
              color: AppColors.nearBlack,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),

          _fieldLabel('Statut'),
          DropdownButtonFormField<String>(
            initialValue: _status ?? 'pending',
            items: _statusOptions
                .map((s) => DropdownMenuItem<String>(
                      value: s,
                      child: Text(
                        _prettyStatus(s),
                        style: GoogleFonts.montserrat(),
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _status = v),
            decoration: _inputDecoration(),
            validator: (v) => (v == null || v.isEmpty) ? 'Statut requis' : null,
          ),

          const SizedBox(height: 14),

          _fieldLabel('Wilaya'),
          TextFormField(
            initialValue: _wilaya ?? '',
            onChanged: (v) => _wilaya = v.trim().isEmpty ? null : v.trim(),
            decoration: _inputDecoration(hint: 'Ex: 16 - Alger'),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Wilaya requise'
                : null,
          ),

          const SizedBox(height: 14),

          _fieldLabel('Adresse'),
          TextFormField(
            initialValue: _address ?? '',
            onChanged: (v) => _address = v.trim().isEmpty ? null : v.trim(),
            decoration:
                _inputDecoration(hint: 'Rue, quartier, point de repère…'),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Adresse requise'
                : null,
            minLines: 2,
            maxLines: 3,
          ),

          const SizedBox(height: 14),

          _fieldLabel('Notes (vendeur)'),
          TextFormField(
            initialValue: _notes ?? '',
            onChanged: (v) => _notes = v.trim().isEmpty ? null : v.trim(),
            decoration: _inputDecoration(
              hint: 'Ajouter une note pour la livraison…',
              icon: Icons.note_alt_outlined,
            ),
            minLines: 2,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderId = _orderId;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Détails commande',
          style: GoogleFonts.montserrat(
            color: AppColors.nearBlack,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.nearBlack,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      _error!,
                      style:
                          GoogleFonts.montserrat(color: Colors.red.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : SafeArea(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(18),
                      children: [
      _infoCard(orderId: orderId ?? ''),
                        const SizedBox(height: 16),
                        _editCard(),
                        const SizedBox(height: 18),
                        if (_error != null) ...[
                          Text(
                            _error!,
                            style: GoogleFonts.montserrat(
                              color: Colors.red.shade700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        PrimaryButton(
                          label: _saving ? 'Mise à jour...' : 'Enregistrer',
                          loading: _saving,
                          onPressed: _saving ? null : _save,
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

