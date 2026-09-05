import 'package:flutter/foundation.dart';
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
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _twoFactorCodeController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isWebViewOpen = false;
  double _webProgress = 0;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _twoFactorCodeController.dispose();
    super.dispose();
  }

  void _openRiotWebView(BuildContext context) {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Riot login is designed for mobile native devices.'),
        ),
      );
      return;
    }

    setState(() {
      _isWebViewOpen = true;
      _webProgress = 0;
    });
  }

  void _handleUrlChange(Uri? uri) async {
    if (uri == null) return;
    final urlStr = uri.toString();

    // Check if redirected to opt_in URL with tokens in fragment
    if (urlStr.contains('playvalorant.com/opt_in') ||
        uri.fragment.contains('access_token')) {
      final fragment = uri.fragment;
      final params = Uri.splitQueryString(fragment);

      final accessToken = params['access_token'];
      final idToken = params['id_token'];

      if (accessToken != null && idToken != null) {
        // Collect all session cookies across Riot domains for reliable silent reauth
        String cookieJar = '';
        try {
          final cookieManager = CookieManager.instance();
          final cookiesAuth = await cookieManager.getCookies(
            url: WebUri('https://auth.riotgames.com'),
          );
          final cookiesRiot = await cookieManager.getCookies(
            url: WebUri('https://riotgames.com'),
          );

          final cookieMap = <String, String>{};
          for (final c in [...cookiesAuth, ...cookiesRiot]) {
            cookieMap[c.name] = c.value;
          }
          cookieJar = cookieMap.entries
              .map((e) => '${e.key}=${e.value}')
              .join('; ');
        } catch (_) {}

        if (mounted) {
          setState(() {
            _isWebViewOpen = false;
          });
          context.read<AuthCubit>().loginWithTokens(
                accessToken: accessToken,
                idToken: idToken,
                cookieJar: cookieJar,
              );
        }
      }
    }
  }

  void _submitDirectLogin() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both your Riot username and password.'),
          backgroundColor: AppTheme.valorantRed,
        ),
      );
      return;
    }

    context.read<AuthCubit>().loginWithCredentials(
          username: username,
          password: password,
        );
  }

  void _show2FaDialog(Auth2FaRequired state) {
    _twoFactorCodeController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.security_rounded, color: AppTheme.valorantRed),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '2-Factor Authentication',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Riot Mobile push approval info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.valorantRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.valorantRed.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.phone_android_rounded,
                        color: AppTheme.valorantRed, size: 28),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Riot Mobile Approval',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Check your Riot Mobile app and tap Approve.\nThis page will update automatically.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.valorantRed,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Divider with "OR" label
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR ENTER CODE',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text(
                'Enter the 6-digit code sent to:\n${state.email}',
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _twoFactorCodeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••••',
                  hintStyle: const TextStyle(
                    color: AppTheme.textMuted,
                    letterSpacing: 8,
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<AuthCubit>().cancelMfaPolling();
              Navigator.of(ctx).pop();
            },
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = _twoFactorCodeController.text.trim();
              if (code.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid 6-digit code'),
                  ),
                );
                return;
              }
              Navigator.of(ctx).pop();
              context.read<AuthCubit>().submit2FaCode(
                    code: code,
                    sessionCookies: state.sessionCookies,
                  );
            },
            child: const Text('VERIFY & SIGN IN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Close any open dialogs (e.g., 2FA dialog) before navigating
          Navigator.of(context).popUntil((route) => route.isFirst);
          context.go('/store');
        } else if (state is Auth2FaRequired) {
          _show2FaDialog(state);
        } else if (state is AuthError) {
          // Close any open dialogs (e.g., 2FA dialog on timeout)
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.valorantRed,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          body: Stack(
            children: [
              // Main Login Screen
              Container(
                decoration:
                    const BoxDecoration(gradient: AppTheme.backgroundGradient),
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 20,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Brand Badge
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.valorantRed
                                      .withValues(alpha: 0.35),
                                  blurRadius: 28,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.local_fire_department_rounded,
                                size: 44,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Titles
                          Text(
                            'VALORANT',
                            style: Theme.of(context)
                                .textTheme
                                .displayLarge
                                ?.copyWith(
                                  letterSpacing: 8,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'STORE & WISHLIST TRACKER',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: AppTheme.valorantRed,
                                  letterSpacing: 3,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 32),

                          // Direct Login Form Card
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.surfaceColor.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SIGN IN TO YOUR RIOT ACCOUNT',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Connects directly to Riot RSO API. Supports 2FA.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // Username Input
                                TextField(
                                  controller: _usernameController,
                                  enabled: !isLoading,
                                  decoration: InputDecoration(
                                    labelText: 'Riot Username / ID',
                                    prefixIcon: const Icon(
                                      Icons.person_outline_rounded,
                                      size: 20,
                                    ),
                                    filled: true,
                                    fillColor: AppTheme.surfaceLight
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Password Input
                                TextField(
                                  controller: _passwordController,
                                  enabled: !isLoading,
                                  obscureText: !_isPasswordVisible,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      size: 20,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        size: 20,
                                        color: AppTheme.textSecondary,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible =
                                              !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                    filled: true,
                                    fillColor: AppTheme.surfaceLight
                                        .withValues(alpha: 0.6),
                                  ),
                                  onSubmitted: (_) => _submitDirectLogin(),
                                ),
                                const SizedBox(height: 20),

                                // Sign In Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed:
                                        isLoading ? null : _submitDirectLogin,
                                    child: isLoading
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                state.message ??
                                                    'AUTHENTICATING...',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                            ],
                                          )
                                        : const Text(
                                            'SIGN IN (DIRECT & 2FA)',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Divider / OR
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Web Sign-In Button (Official InAppWebView)
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: isLoading
                                  ? null
                                  : () => _openRiotWebView(context),
                              icon: const Icon(Icons.open_in_browser_rounded,
                                  size: 20),
                              label: const Text(
                                'SIGN IN VIA RIOT WEBVIEW',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: AppTheme.valorantRed
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Security Notice
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.verified_user_outlined,
                                size: 14,
                                color: AppTheme.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'All data is fetched live from Riot & Valorant APIs.\nCredentials and tokens stored in hardware Keystore.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.textMuted,
                                        fontSize: 11,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // In-App WebView Overlay
              if (_isWebViewOpen)
                SafeArea(
                  child: Container(
                    color: AppTheme.backgroundColor,
                    child: Column(
                      children: [
                        // WebView Top Bar
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            border: const Border(
                              bottom: BorderSide(color: AppTheme.surfaceLight),
                            ),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  setState(() => _isWebViewOpen = false);
                                },
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Riot Official Sign-In (Supports 2FA)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              if (_webProgress < 1.0)
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    value: _webProgress,
                                    strokeWidth: 2,
                                    color: AppTheme.valorantRed,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Progress Bar
                        if (_webProgress < 1.0)
                          LinearProgressIndicator(
                            value: _webProgress,
                            backgroundColor: Colors.transparent,
                            color: AppTheme.valorantRed,
                            minHeight: 2,
                          ),

                        // Actual WebView with complete 2FA support
                        Expanded(
                          child: InAppWebView(
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
                                          'playvalorant.com/opt_in') ||
                                      uri.fragment.contains('access_token'))) {
                                _handleUrlChange(uri);
                                return NavigationActionPolicy.CANCEL;
                              }
                              return NavigationActionPolicy.ALLOW;
                            },
                            onLoadStop: (controller, url) async {
                              _handleUrlChange(url?.uriValue);
                            },
                            onUpdateVisitedHistory:
                                (controller, url, isReload) async {
                              _handleUrlChange(url?.uriValue);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
