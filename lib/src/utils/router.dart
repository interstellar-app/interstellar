
import 'package:auto_route/auto_route.dart';
import 'router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {

  @override
  RouteType get defaultRouteType => RouteType.material();

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: AppHome.page, path: '/'),
    AutoRoute(page: ExploreRoute.page, path: '/explore'),
    AutoRoute(page: PostRoute.page, path: '/post/:id'),
    AutoRoute(page: PostCommentRoute.page, path: '/comment/:id'),
    AutoRoute(page: UserRoute.page, path: '/user/:id'),
    AutoRoute(page: MessageThreadRoute.page, path: '/message'),
    AutoRoute(page: CommunityRoute.page, path: '/community/:id'),
    AutoRoute(page: ModLogRoute.page, path: '/modlog'),
    AutoRoute(page: DomainRoute.page, path: '/domain'),
    AutoRoute(page: CommunityOwnerPanelRoute.page, path: '/community-owner'),
    AutoRoute(page: CommunityModPanelRoute.page, path: '/community-mod'),
  ];

}