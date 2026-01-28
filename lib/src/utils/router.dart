import 'package:auto_route/auto_route.dart';
import 'package:drift_db_viewer/drift_db_viewer.dart';
import '../controller/database.dart';
import 'router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => RouteType.material();

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: AppHome.page, path: '/'),
    AutoRoute(page: FeedRoute.page, path: '/feed'),
    AutoRoute(page: ExploreRoute.page, path: '/explore'),

    AutoRoute(page: ThreadRoute.page, path: '/thread/:id'),
    AutoRoute(page: MicroblogRoute.page, path: '/microblog/:id'),
    AutoRoute(page: PostCommentRoute.page, path: '/comment/:id'),
    AutoRoute(page: ContentReplyRoute.page, path: '/reply'),

    AutoRoute(page: UserRoute.page, path: '/user/:userId'),
    AutoRoute(page: ModLogUserRoute.page, path: '/user/:userId/modlog'),
    AutoRoute(page: MessageThreadRoute.page, path: '/user/:userId/message'),

    AutoRoute(page: CommunityRoute.page, path: '/community/:communityId'),
    AutoRoute(page: ModLogCommunityRoute.page, path: '/community/:communityId/modlog'),
    AutoRoute(page: CommunityModPanelRoute.page, path: '/community/:communityId/mod'),
    AutoRoute(page: CommunityOwnerPanelRoute.page, path: '/community/:communityId/owner'),

    AutoRoute(page: ModLogRoute.page, path: '/modlog'),
    AutoRoute(page: DomainRoute.page, path: '/domain'),
    AutoRoute(page: CreateRoute.page, path: '/create'),
    AutoRoute(page: AdvancedImageRoute.page, path: '/image'),
    AutoRoute(page: TagUsersRoute.page, path: '/tags/:tag'),
    AutoRoute(page: TagEditorRoute.page, path: '/tags-editor/:tag'),
    AutoRoute(page: BookmarkListRoute.page, path: '/bookmarks'),
    AutoRoute(page: BookmarksRoute.page, path: '/bookmarks/:bookmarkList'),
    AutoRoute(page: ProfileEditRoute.page, path: '/account/edit'),
    AutoRoute(page: EditProfileRoute.page, path: '/profile/edit'),
    AutoRoute(page: EditFilterListRoute.page, path: '/filter/:filterList'),
    AutoRoute(page: EditFeedRoute.page, path: '/feed/:feed/edit'),

    //settings
    AutoRoute(page: BehaviorSettingsRoute.page, path: '/settings/behavior'),
    AutoRoute(page: DisplaySettingsRoute.page, path: '/settings/display'),
    AutoRoute(page: FeedSettingsRoute.page, path: '/settings/feeds'),
    AutoRoute(page: FeedActionsSettingsRoute.page, path: '/settings/actions'),
    AutoRoute(page: FeedDefaultSettingsRoute.page, path: '/settings/defaults'),
    AutoRoute(
      page: FeedSourceOrderSettingsRoute.page,
      path: '/settings/defaults/source',
    ),
    AutoRoute(
      page: FeedViewOrderSettingsRoute.page,
      path: '/settings/defaults/view',
    ),
    AutoRoute(
      page: FeedSortOrderSettingsRoute.page,
      path: '/settings/defaults/sort',
    ),
    AutoRoute(page: TagsRoute.page, path: '/settings/tags'),
    AutoRoute(page: FilterListsRoute.page, path: '/settings/filters'),
    AutoRoute(
      page: NotificationSettingsRoute.page,
      path: '/settings/notifications',
    ),
    AutoRoute(page: DataUtilitiesRoute.page, path: '/settings/utilities'),
    AutoRoute(
      page: AccountMigrationRoute.page,
      path: '/settings/utilities/migration',
    ),
    AutoRoute(page: AccountResetRoute.page, path: '/settings/utilities/reset'),
    AutoRoute(page: AboutRoute.page, path: '/settings/about'),
    AutoRoute(page: DebugSettingsRoute.page, path: '/settings/about/debug'),
    AutoRoute(page: LogConsole.page, path: '/settings/about/debug/log'),
    // DriftDbViewer is part of a library so can't use code gen.
    NamedRouteDef(
      name: 'DriftDbViewer',
      builder: (context, data) => DriftDbViewer(database),
      path: '/settings/about/debug/database',
    ),
    AutoRoute(page: LoginSelectRoute.page, path: '/settings/login'),
    AutoRoute(page: LoginConfirmRoute.page, path: '/settings/login/confirm'),
    AutoRoute(page: WebViewRoute.page, path: '/webview'),
    AutoRoute(page: RedirectListener.page, path: '/redirect'),
  ];
}
