import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/screens/explore/user_screen.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/error_page.dart';
import 'package:interstellar/src/widgets/loading_template.dart';
import 'package:oauth2/oauth2.dart';
import 'package:provider/provider.dart';

class SelfFeed extends StatefulWidget {
  const SelfFeed({super.key});

  @override
  State<SelfFeed> createState() => _SelfFeedState();
}

class _SelfFeedState extends State<SelfFeed>
    with AutomaticKeepAliveClientMixin<SelfFeed> {
  DetailedUserModel? _meUser;
  AuthorizationException? _authError;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    final ac = context.read<AppController>();

    if (ac.isLoggedIn) {
      ac.api.users
          .getMe()
          .then((value) {
            if (!mounted) return;

            setState(() {
              _meUser = value;
              _authError = null;
            });
          })
          .catchError((dynamic error) {
            if (error is AuthorizationException) {
              setState(() {
                _authError = error;
              });
            }
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final ac = context.read<AppController>();

    if (!ac.isLoggedIn) {
      return Center(child: Text(l(context).notLoggedIn));
    }

    if (_authError != null) return AuthErrorPage(error: _authError!);

    if (_meUser == null) return const LoadingTemplate();

    final user = _meUser!;

    return UserScreen(user.id, initData: _meUser);
  }
}
