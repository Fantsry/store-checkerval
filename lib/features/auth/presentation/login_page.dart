import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/core/constants/api_constants.dart';
import 'package:valorant_store_tracker/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:valorant_store_tracker/features/auth/presentation/cubit/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  InAppWebViewController? _webViewController;
  double _webProgress = 0;
  bool _isProcessingTokens = false;

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
          final cookiesRiot = await cookieManager.getCookies(
            url: WebUri('https://riotgames.com'),
          );
          final cookiesPv = await cookieManager.getCookies(
            url: WebUri('https://playvalorant.com'),
          );

          final cookieMap = <String, String>{};
          for (final c in [...cookiesAuth, ...cookiesRiot, ...cookiesPv]) {
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
          context.go('/store');
        } else if (state is AuthError) {
          setState(() {
            _isProcessingTokens = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.valorantRed,
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
            if (_webViewController != null && await _webViewController!.canGoBack()) {
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
            backgroundColor: AppTheme.backgroundColor,
            appBar: AppBar(
            backgroundColor: AppTheme.surfaceColor,
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
            title: const Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: AppTheme.valorantRed,
                ),
                SizedBox(width: 8),
                Text(
                  'Riot Games Sign In',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Muat ulang halaman',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => _webViewController?.reload(),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) {
                  if (value == 'clear') {
                    _clearCookiesAndReload();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep_rounded, size: 20),
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
                      color: AppTheme.valorantRed,
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
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  final uri = navigationAction.request.url?.uriValue;
                  if (uri != null &&
                      (uri.toString().contains('playvalorant.com/opt_in') ||
                          uri.fragment.contains('access_token') ||
                          uri.queryParameters.containsKey('access_token'))) {
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
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.valorantRed.withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 44,
                            height: 44,
                            child: CircularProgressIndicator(
                              color: AppTheme.valorantRed,
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Menghubungkan Akun Riot...',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (state is AuthLoading ? state.message : null) ??
                                'Mengambil sesi & rotasi skin store...',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
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
