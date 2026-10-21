import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/core/constants/api_constants.dart';
import 'package:valorant_store_tracker/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:valorant_store_tracker/features/auth/presentation/cubit/auth_state.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_cubit.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  InAppWebViewController? _webViewController;
  double _webProgress = 0;
  bool _isProcessingTokens = false;
  String? _manualRegion;

  void _handleUrlChange(Uri? uri) async {
    if (uri == null || _isProcessingTokens) return;
    final urlStr = uri.toString();

    // Detect Riot OAuth redirect with tokens in fragment or query
    if (urlStr.contains('playvalorant.com/opt_in') ||
        uri.fragment.contains('access_token') ||
        uri.queryParameters.containsKey('access_token')) {
      final params = {
        ...Uri.splitQueryString(uri.fragment),
        ...uri.queryParameters,
      };

      final accessToken = params['access_token'];
      final idToken = params['id_token'];

      if (accessToken != null &&
          accessToken.isNotEmpty &&
          idToken != null &&
          idToken.isNotEmpty) {
        setState(() {
          _isProcessingTokens = true;
        });

        // Collect all session cookies across Riot domains for silent reauth
        String cookieJar = '';
        try {
          final cookieManager = CookieManager.instance();
          final cookiesAuth = await cookieManager.getCookies(
            url: WebUri('https://auth.riotgames.com'),
          );
          final cookiesAuthDirect = await cookieManager.getCookies(
            url: WebUri('https://auth.riotgames.com/authorize'),
          );
          final cookiesAuthenticate = await cookieManager.getCookies(
            url: WebUri('https://authenticate.riotgames.com'),
          );
          final cookiesRiot = await cookieManager.getCookies(
            url: WebUri('https://riotgames.com'),
          );
          final cookiesPv = await cookieManager.getCookies(
            url: WebUri('https://playvalorant.com'),
          );

          final cookieMap = <String, String>{};
          for (final c in [
            ...cookiesAuth,
            ...cookiesAuthDirect,
            ...cookiesAuthenticate,
            ...cookiesRiot,
            ...cookiesPv,
          ]) {
            cookieMap[c.name] = c.value;
          }
          cookieJar = cookieMap.entries
              .map((e) => '${e.key}=${e.value}')
              .join('; ');
        } catch (e) {
          debugPrint('Cookie collection error: $e');
        }

        if (mounted) {
          context.read<AuthCubit>().loginWithTokens(
            accessToken: accessToken,
            idToken: idToken,
            cookieJar: cookieJar,
            manualRegion: _manualRegion,
          );
        }
      }
    }
  }

  Future<void> _clearCookiesAndReload() async {
    try {
      final cookieManager = CookieManager.instance();
      await cookieManager.deleteAllCookies();
      await InAppWebViewController.clearAllCache();
      await _webViewController?.loadUrl(
        urlRequest: URLRequest(url: WebUri(ApiConstants.authorizeUrl)),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi dibersihkan. Silakan login kembali.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Clear cookies error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.read<ProfileCubit>().loadProfile(forceRefresh: true);
          context.read<StoreCubit>().fetchStore(forceRefresh: true);
          context.go('/store');
        } else if (state is AuthError) {
          setState(() {
            _isProcessingTokens = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.lossRed,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoadingSession = state is AuthLoading || _isProcessingTokens;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            if (_webViewController != null &&
                await _webViewController!.canGoBack()) {
              await _webViewController!.goBack();
              return;
            }
            if (context.mounted) {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/store');
              }
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/store');
                  }
                },
              ),
              title: const Text(
                'Riot sign in',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Muat ulang halaman',
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => _webViewController?.reload(),
                ),
                PopupMenuButton<String>(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (value) {
                    if (value == 'clear') {
                      _clearCookiesAndReload();
                    } else if (value == 'region:auto') {
                      setState(() => _manualRegion = null);
                    } else if (value.startsWith('region:')) {
                      setState(() => _manualRegion = value.substring(7));
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      enabled: false,
                      child: Text(
                        'REGION: ${_manualRegion?.toUpperCase() ?? 'AUTO'}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'region:auto',
                      child: Row(
                        children: [
                          Icon(
                            _manualRegion == null
                                ? Icons.check_rounded
                                : Icons.public_rounded,
                            size: 20,
                            color: _manualRegion == null
                                ? AppColors.accent
                                : Colors.white70,
                          ),
                          const SizedBox(width: 8),
                          const Text('Deteksi Otomatis'),
                        ],
                      ),
                    ),
                    for (final region in const [
                      'ap',
                      'na',
                      'eu',
                      'kr',
                      'latam',
                      'br',
                    ])
                      PopupMenuItem(
                        value: 'region:$region',
                        child: Row(
                          children: [
                            Icon(
                              _manualRegion == region
                                  ? Icons.check_rounded
                                  : Icons.circle_outlined,
                              size: 20,
                              color: _manualRegion == region
                                  ? AppColors.accent
                                  : Colors.white70,
                            ),
                            const SizedBox(width: 8),
                            Text('Region ${region.toUpperCase()}'),
                          ],
                        ),
                      ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'clear',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_sweep_rounded,
                            size: 20,
                            color: AppColors.accent,
                          ),
                          SizedBox(width: 8),
                          Text('Ganti Akun / Hapus Sesi'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              bottom: _webProgress < 1.0
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(3.0),
                      child: LinearProgressIndicator(
                        value: _webProgress,
                        backgroundColor: Colors.transparent,
                        color: AppColors.accent,
                        minHeight: 3,
                      ),
                    )
                  : null,
            ),
            body: Stack(
              children: [
                // Official Riot OAuth WebView
                InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri(ApiConstants.authorizeUrl),
                  ),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    clearCache: false,
                    thirdPartyCookiesEnabled: true,
                    domStorageEnabled: true,
                    databaseEnabled: true,
                    sharedCookiesEnabled: true,
                    supportMultipleWindows: false,
                    allowsInlineMediaPlayback: true,
                    useShouldOverrideUrlLoading: true,
                    userAgent:
                        'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
                  ),
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                  },
                  onProgressChanged: (controller, progress) {
                    setState(() {
                      _webProgress = progress / 100.0;
                    });
                  },
                  shouldOverrideUrlLoading:
                      (controller, navigationAction) async {
                        final uri = navigationAction.request.url?.uriValue;
                        if (uri != null &&
                            (uri.toString().contains(
                                  'playvalorant.com/opt_in',
                                ) ||
                                uri.fragment.contains('access_token') ||
                                uri.queryParameters.containsKey(
                                  'access_token',
                                ))) {
                          _handleUrlChange(uri);
                          return NavigationActionPolicy.CANCEL;
                        }
                        return NavigationActionPolicy.ALLOW;
                      },
                  onLoadStop: (controller, url) async {
                    _handleUrlChange(url?.uriValue);
                  },
                  onUpdateVisitedHistory: (controller, url, isReload) async {
                    _handleUrlChange(url?.uriValue);
                  },
                ),

                // Loading Overlay when authenticating tokens & fetching entitlements
                if (isLoadingSession)
                  Container(
                    color: Colors.black87,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 24,
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 44,
                              height: 44,
                              child: CircularProgressIndicator(
                                color: AppColors.accent,
                                strokeWidth: 3,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'CONNECTING RIOT ACCOUNT',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              (state is AuthLoading ? state.message : null) ??
                                  'Fetching session and daily store...',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
