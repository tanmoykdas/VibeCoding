import 'dart:async';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/transaction_provider.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/local_storage_service.dart';
import 'services/notification_service.dart';

void main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      await Firebase.initializeApp(
        options: kIsWeb ? DefaultFirebaseOptions.web : null,
      );

      if (!kIsWeb) {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
        );
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;
        ui.PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }

      final authService = AuthService();
      final firestoreService = FirestoreService();
      final localStorageService = LocalStorageService();
      final notificationService = NotificationService(scaffoldMessengerKey);

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(authService),
            ),
            ChangeNotifierProvider<ThemeProvider>(
              create: (_) => ThemeProvider(localStorageService),
            ),
            ChangeNotifierProvider<ConnectivityProvider>(
              create: (_) => ConnectivityProvider(Connectivity()),
            ),
            ChangeNotifierProxyProvider<AuthProvider, TransactionProvider>(
              create: (context) => TransactionProvider(
                firestoreService,
                localStorageService,
                notificationService,
                context.read<AuthProvider>(),
              ),
              update: (context, authProvider, previous) {
                if (previous == null) {
                  return TransactionProvider(
                    firestoreService,
                    localStorageService,
                    notificationService,
                    authProvider,
                  );
                }
                Future.microtask(previous.syncAuthState);
                return previous;
              },
            ),
          ],
          child: MoneycoApp(scaffoldMessengerKey: scaffoldMessengerKey),
        ),
      );
    },
    (error, stack) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    },
  );
}
