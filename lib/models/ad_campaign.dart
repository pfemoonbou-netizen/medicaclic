enum AdStatus { draft, submitted, inReview, approved, rejected, active, ended }

enum AdPlacement { homeBanner }

enum AdPaymentMethod { ccp, baridimob, virement, carte }

enum AdPaymentStatus { pending, verified, rejected }

enum AdApprovalStatus { pending, approved, rejected }

extension AdPaymentMethodX on AdPaymentMethod {
  String get label => switch (this) {
    AdPaymentMethod.ccp       => 'CCP (Algérie Poste)',
    AdPaymentMethod.baridimob => 'BaridiMob',
    AdPaymentMethod.virement  => 'Virement bancaire',
    AdPaymentMethod.carte     => 'Carte bancaire',
  };
}

extension AdPaymentStatusX on AdPaymentStatus {
  String get label => switch (this) {
    AdPaymentStatus.pending  => 'En attente',
    AdPaymentStatus.verified => 'Vérifié',
    AdPaymentStatus.rejected => 'Rejeté',
  };
}

extension AdApprovalStatusX on AdApprovalStatus {
  String get label => switch (this) {
    AdApprovalStatus.pending  => 'En attente',
    AdApprovalStatus.approved => 'Approuvé',
    AdApprovalStatus.rejected => 'Rejeté',
  };
}

class AdCampaign {
  final String id;
  final String companyId;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? ctaLabel;
  final String? ctaRoute;
  final AdStatus status;
  final int budgetDZD;
  final DateTime? startDate;
  final DateTime? endDate;
  final AdPlacement placement;
  final AdPaymentMethod? paymentMethod;
  final DateTime createdAt;
  final String? receiptUrl;
  final AdPaymentStatus paymentStatus;
  final AdApprovalStatus approvalStatus;
  final DateTime? approvedAt;
  final String? approvedBy;

  const AdCampaign({
    required this.id,
    required this.companyId,
    required this.title,
    this.description,
    this.imageUrl,
    this.ctaLabel,
    this.ctaRoute,
    required this.status,
    required this.budgetDZD,
    this.startDate,
    this.endDate,
    this.placement = AdPlacement.homeBanner,
    this.paymentMethod,
    required this.createdAt,
    this.receiptUrl,
    this.paymentStatus = AdPaymentStatus.pending,
    this.approvalStatus = AdApprovalStatus.pending,
    this.approvedAt,
    this.approvedBy,
  });

  bool get isActive => status == AdStatus.active;
  bool get isDraft => status == AdStatus.draft;
  bool get canSubmit => status == AdStatus.draft;
  bool get isLive =>
      isActive &&
      approvalStatus == AdApprovalStatus.approved &&
      (startDate == null || !DateTime.now().isBefore(startDate!)) &&
      (endDate == null || !DateTime.now().isAfter(endDate!));

  String get statusLabel => switch (status) {
    AdStatus.draft     => 'Brouillon',
    AdStatus.submitted => 'Soumis',
    AdStatus.inReview  => 'En révision',
    AdStatus.approved  => 'Approuvé',
    AdStatus.rejected  => 'Rejeté',
    AdStatus.active    => 'Actif',
    AdStatus.ended     => 'Terminé',
  };

  factory AdCampaign.fromMap(Map<String, dynamic> m) => AdCampaign(
        id: m['id'] as String,
        companyId: m['company_id'] as String,
        title: m['title'] as String,
        description: m['description'] as String?,
        imageUrl: m['image_url'] as String?,
        ctaLabel: m['cta_label'] as String?,
        ctaRoute: m['cta_route'] as String?,
        status: AdStatus.values.firstWhere(
          (s) => s.name == m['status'],
          orElse: () => AdStatus.draft,
        ),
        budgetDZD: (m['budget_dzd'] as num?)?.toInt() ?? 0,
        startDate: m['start_date'] != null
            ? DateTime.tryParse(m['start_date'] as String)
            : null,
        endDate: m['end_date'] != null
            ? DateTime.tryParse(m['end_date'] as String)
            : null,
        placement: AdPlacement.homeBanner,
        paymentMethod: m['payment_method'] != null
            ? AdPaymentMethod.values.firstWhere(
                (p) => p.name == m['payment_method'],
                orElse: () => AdPaymentMethod.ccp)
            : null,
        createdAt:
            DateTime.tryParse(m['created_at'] as String? ?? '') ??
                DateTime.now(),
        receiptUrl: m['receipt_url'] as String?,
        paymentStatus: AdPaymentStatus.values.firstWhere(
          (s) => s.name == (m['payment_status'] as String?),
          orElse: () => AdPaymentStatus.pending,
        ),
        approvalStatus: AdApprovalStatus.values.firstWhere(
          (s) => s.name == (m['approval_status'] as String?),
          orElse: () => AdApprovalStatus.pending,
        ),
        approvedAt: m['approved_at'] != null
            ? DateTime.tryParse(m['approved_at'] as String)
            : null,
        approvedBy: m['approved_by'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'company_id':      companyId,
        'title':           title,
        'description':     description,
        'image_url':       imageUrl,
        'cta_label':       ctaLabel,
        'cta_route':       ctaRoute,
        'status':          status.name,
        'budget_dzd':      budgetDZD,
        'start_date':      startDate?.toIso8601String().split('T').first,
        'end_date':        endDate?.toIso8601String().split('T').first,
        'placement':       'home_banner',
        'payment_method':  paymentMethod?.name,
        'receipt_url':     receiptUrl,
        'payment_status':  paymentStatus.name,
        'approval_status': approvalStatus.name,
      };

  AdCampaign copyWith({
    AdStatus? status,
    AdPaymentStatus? paymentStatus,
    AdApprovalStatus? approvalStatus,
    String? receiptUrl,
    DateTime? approvedAt,
    String? approvedBy,
  }) =>
      AdCampaign(
        id: id,
        companyId: companyId,
        title: title,
        description: description,
        imageUrl: imageUrl,
        ctaLabel: ctaLabel,
        ctaRoute: ctaRoute,
        status: status ?? this.status,
        budgetDZD: budgetDZD,
        startDate: startDate,
        endDate: endDate,
        placement: placement,
        paymentMethod: paymentMethod,
        createdAt: createdAt,
        receiptUrl: receiptUrl ?? this.receiptUrl,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        approvalStatus: approvalStatus ?? this.approvalStatus,
        approvedAt: approvedAt ?? this.approvedAt,
        approvedBy: approvedBy ?? this.approvedBy,
      );

  // ── Mock data for demo ──────────────────────────────────────────────────────

  static List<AdCampaign> get mockActive => [
        AdCampaign(
          id: 'ad_djezzy',
          companyId: 'djezzy',
          title: 'Djezzy — Rechargez & Gagnez',
          description: 'Rechargez votre forfait et gagnez des points LINCOO !',
          ctaLabel: 'Découvrir l\'offre',
          ctaRoute: '/shop',
          status: AdStatus.active,
          budgetDZD: 50000,
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 6, 30),
          placement: AdPlacement.homeBanner,
          createdAt: DateTime(2026, 6, 1),
          approvalStatus: AdApprovalStatus.approved,
          paymentStatus: AdPaymentStatus.verified,
        ),
      ];
}
