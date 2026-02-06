import 'package:flutter/material.dart';
import 'package:interstellar/src/api/client.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:oauth2/oauth2.dart';
import 'package:provider/provider.dart';

class OAuthErrorPage extends StatelessWidget {
  const OAuthErrorPage({required this.error, super.key});

  final AuthorizationException error;

  Future<void> relogin(BuildContext context) async {
    final ac = context.read<AppController>();
    final software = ac.serverSoftware;
    final server = ac.instanceHost;

    await ac.login(software: software, server: server, context: context);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l(context).errorPage_authError,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(error.toString(), textAlign: TextAlign.center),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: () => relogin(context),
            label: Text(
              l(context).refreshAuth,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class RestrictedAuthErrorPage extends StatelessWidget {
  const RestrictedAuthErrorPage({required this.error, super.key});

  final RestrictedAuthException error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l(context).errorPage_restrictedAuthError,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(error.toString(), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class FirstPageErrorIndicator extends StatelessWidget {
  const FirstPageErrorIndicator({
    required this.error,
    required this.onTryAgain,
    super.key,
  });

  final dynamic error;
  final VoidCallback onTryAgain;

  @override
  Widget build(BuildContext context) {
    if (error is AuthorizationException) {
      return OAuthErrorPage(error: error);
    }
    if (error is RestrictedAuthException) {
      return RestrictedAuthErrorPage(error: error);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l(context).errorPage_firstPage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(error.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 48),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: onTryAgain,
                icon: const Icon(Icons.refresh),
                label: Text(
                  l(context).errorPage_firstPage_button,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NewPageErrorIndicator extends StatelessWidget {
  const NewPageErrorIndicator({
    required this.error,
    required this.onTryAgain,
    super.key,
  });

  final dynamic error;
  final VoidCallback onTryAgain;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTryAgain,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${l(context).errorPage_newPage}\n$error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Icon(Icons.refresh, size: 16),
          ],
        ),
      ),
    ),
  );
}

class NoItemsFoundIndicator extends StatefulWidget {
  const NoItemsFoundIndicator({required this.onTryAgain, super.key});

  final VoidCallback onTryAgain;

  @override
  State<NoItemsFoundIndicator> createState() => _NoItemsFoundIndicatorState();
}

class _NoItemsFoundIndicatorState extends State<NoItemsFoundIndicator> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    } else {
      return InkWell(
        onTap: () {
          widget.onTryAgain();
          setState(() {
            _loading = true;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l(context).errorPage_caughtUp,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.arrow_downward_rounded,
                  // size: 16,
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
