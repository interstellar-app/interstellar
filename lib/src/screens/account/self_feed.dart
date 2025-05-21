import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/screens/explore/user_screen.dart';
import 'package:interstellar/src/widgets/loading_template.dart';
import 'package:provider/provider.dart';

class SelfFeed extends StatefulWidget {
  const SelfFeed({super.key});

  @override
  State<SelfFeed> createState() => _SelfFeedState();
}

class _SelfFeedState extends State<SelfFeed>
    with AutomaticKeepAliveClientMixin<SelfFeed> {
  DetailedUserModel? _meUser;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    context.read<AppController>().api.users.getMe().then(
      (value) => setState(() {
        _meUser = value;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_meUser == null) return const LoadingTemplate();

    final user = _meUser!;

    return UserScreen(user.id, initData: _meUser);
  }
}
