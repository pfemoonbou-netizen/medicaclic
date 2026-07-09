import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';

// Existing design-export screens
import 'screens/feed_page.dart';
import 'screens/home_page.dart';
import 'screens/product_details_page.dart';

// Auth
import 'screens/splash_page.dart';
import 'screens/welcome_page.dart';
import 'screens/login_page.dart';
import 'screens/forgot_password_page.dart';
import 'screens/sign_up_page.dart';

// Onboarding
import 'screens/choose_profile_type_page.dart';
import 'screens/complete_buyer_page.dart';
import 'screens/complete_seller_page.dart';
import 'screens/complete_company_page.dart';
import 'screens/complete_creator_page.dart';
import 'screens/pending_verification_page.dart';

// Main navigation
import 'screens/reels_page.dart';
import 'screens/shop_page.dart';
import 'screens/dashboard_page.dart';

// Admin
import 'screens/admin_dashboard_page.dart';

// Commerce
import 'screens/store_profile_page.dart';
import 'screens/cart_page.dart';
import 'screens/checkout_page.dart';
import 'screens/order_tracking_page.dart';
import 'screens/my_orders_page.dart';
import 'screens/order_feedback_page.dart';
import 'screens/order_details_for_seller_page.dart';
import 'screens/create_content_page.dart';
import 'screens/creator_space_page.dart';
import 'screens/creator_apply_page.dart';

// Search
import 'screens/search_page.dart';

// Profile
import 'screens/my_profile_page.dart';
import 'screens/seller_pack_page.dart';
import 'screens/edit_profile_page.dart';
import 'screens/favorites_page.dart';
import 'screens/notifications_page.dart';
import 'screens/wallet_page.dart';
import 'screens/messages_page.dart';

// Support & settings
import 'screens/help_center_page.dart';
import 'screens/create_ticket_page.dart';
import 'screens/chatbot_page.dart';
import 'screens/settings_page.dart';
import 'screens/rewards_page.dart';
import 'screens/ad_campaign_page.dart';
import 'screens/ad_offer_page.dart';
import 'screens/quick_ad_publish_page.dart';
import 'screens/company_page.dart';
// Delivery
import 'screens/delivery/delivery_center_page.dart';
import 'screens/delivery/smart_delivery_activation_page.dart';
import 'screens/delivery/smart_orders_page.dart';
import 'screens/delivery/delivery_settings_page.dart';
import 'screens/delivery/pickup_schedule_page.dart';
import 'screens/delivery/delivery_analytics_page.dart';
import 'screens/delivery/shipping_labels_page.dart';
import 'screens/delivery/fulfillment_page.dart';
import 'services/user_session.dart';
import 'widgets/user_scope.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      debugPrint('FLUTTER ERROR: ${details.exception}');
      debugPrint('${details.stack}');
    };

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.publishableKey,
      ).timeout(const Duration(seconds: 6));
    } catch (e) {
      debugPrint('Supabase init skipped: $e');
    }

    // Load user profile (falls back to demo if no session)
    await UserSession.instance.initialize();
    UserSession.instance.listenToProfileChanges();

    runApp(const LincooApp());
  }, (error, stack) {
    debugPrint('ZONE ERROR: $error');
    debugPrint('$stack');
  });
}

final supabase = Supabase.instance.client;

/// Global route observer — screens can subscribe to get didPopNext callbacks.
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class LincooApp extends StatelessWidget {
  const LincooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return UserScope(child: MaterialApp(
      title: 'LINCOO',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF292526)),
        useMaterial3: true,
        fontFamily: 'Montserrat',
      ),
      initialRoute: '/',
      routes: {
        // Splash & auth
        '/': (context) => const SplashPage(),
        '/welcome': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/signup': (context) => const SignUpPage(),

        // Onboarding / role selection
        '/choose-role': (context) => const ChooseProfileTypePage(),
        '/complete-buyer': (context) => const CompleteBuyerPage(),
        '/complete-seller': (context) => const CompleteSellerPage(),
        '/complete-company': (context) => const CompleteCompanyPage(),
        '/complete-creator': (context) => const CompleteCreatorPage(),
        '/pending': (context) => const PendingVerificationPage(),

        // Main tabs
        '/feed': (context) => const FeedPage(),
        '/reels': (context) => const ReelsPage(),
        '/shop': (context) => const ShopPage(),
        '/catalog': (context) => const HomePage(),
        '/dashboard': (context) => const DashboardPage(),
        '/messages': (context) => const MessagesPage(),

        // Commerce
        '/product': (context) => const ProductDetailsPage(),
        '/search': (context) => const SearchPage(),
        '/store': (context) => const StoreProfilePage(),
        '/cart': (context) => const CartPage(),
        '/checkout': (context) => const CheckoutPage(),
        '/order-tracking': (context) => const OrderTrackingPage(),
        '/my-orders': (context) => const MyOrdersPage(),
        '/order-feedback': (context) => const OrderFeedbackPage(),
        '/order-details-seller': (context) => const OrderDetailsForSellerPage(),
        '/create': (context) => const CreateContentPage(),
        '/create-post': (context) => const CreateContentPage(),
        '/seller-orders': (context) => const MyOrdersPage(),

        // Profile & account
        '/profile': (context) => const MyProfilePage(),
        '/seller-packs': (context) => const SellerPackPage(),
        '/edit-profile': (context) => const EditProfilePage(),
        '/favorites': (context) => const FavoritesPage(),
        '/notifications': (context) => const NotificationsPage(),
        '/wallet': (context) => const WalletPage(),
        '/rewards': (context) => const RewardsPage(),
        '/creator-space': (context) => const CreatorSpacePage(),
        '/creator-apply': (context) => const CreatorApplyPage(),

        // Support & settings
        '/help': (context) => const HelpCenterPage(),
        '/create-ticket': (context) => const CreateTicketPage(),
        '/chatbot': (context) => const ChatbotPage(),
        '/settings': (context) => const SettingsPage(),
        '/campaigns': (context) => const AdCampaignPage(),
        '/ad-offer': (context) => const AdOfferPage(),
        '/quick-ad-publish': (context) => const QuickAdPublishPage(),

        // Company public page
        '/company-page': (context) => CompanyPage(
              companyId: ModalRoute.of(context)!.settings.arguments as String,
            ),

        // Admin
        '/admin': (context) => const AdminDashboardPage(),

        // Delivery
        '/delivery-center':       (context) => const DeliveryCenterPage(),
        '/smart-delivery-activate': (context) => const SmartDeliveryActivationPage(),
        '/smart-orders':          (context) => const SmartOrdersPage(),
        '/delivery-settings':     (context) => const DeliverySettingsPage(),
        '/pickup-schedule':       (context) => const PickupSchedulePage(),
        '/delivery-analytics':    (context) => const DeliveryAnalyticsPage(),
        '/shipping-labels':       (context) => const ShippingLabelsPage(),
        '/fulfillment':           (context) => const FulfillmentPage(),
      },
    ));
  }
}
