import 'package:drift/drift.dart' show Expression, Insertable, Value;
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:interstellar/src/api/comments.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/api/images.dart' show ImageStore;
import 'package:interstellar/src/controller/database/database.dart'
    show ProfilesCompanion;
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/actions.dart'
    show ActionLocation, ActionLocationWithTabs, SwipeAction;
import 'package:interstellar/src/widgets/content_item/content_item.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

enum OpenLinksIn { inAppBrowser, externalBrowser }

/// Profile class where all fields are required.
@freezed
abstract class ProfileRequired with _$ProfileRequired {
  @JsonSerializable(explicitToJson: true, includeIfNull: false)
  const factory ProfileRequired({
    // If the autoSwitchAccount key is ever changed, be sure to update the AppController code that removes accounts, which references this key.
    required String? autoSwitchAccount,
    // Behavior settings
    required String defaultCreateLanguage,
    required bool disableTabSwiping,
    required bool askBeforeUnsubscribing,
    required bool askBeforeDeleting,
    required bool autoPlayVideos,
    required bool hapticFeedback,
    required bool autoTranslate,
    required bool markThreadsReadOnScroll,
    required bool markMicroblogsReadOnScroll,
    required double animationSpeed,
    required bool inlineReplies,
    required bool showCrossPostComments,
    required bool markCrossPostsAsRead,
    required ImageStore defaultImageStore,
    // Display settings
    required String appLanguage,
    required ThemeMode themeMode,
    required FlexScheme colorScheme,
    required bool enableTrueBlack,
    required bool compactMode,
    required bool hideActionButtons,
    required bool hideFeedUIOnScroll,
    required double globalTextScale,
    required bool alwaysShowInstance,
    required bool coverMediaMarkedSensitive,
    required bool fullImageSizeThreads,
    required bool fullImageSizeMicroblogs,
    required bool showPostsCards,
    required List<PostComponent> postComponentOrder,
    required double dividerThickness,
    required bool hideEmojiReactions,
    // Feed defaults
    required FeedSort feedDefaultThreadsSort,
    required FeedSort feedDefaultMicroblogSort,
    @JsonKey(readValue: _parseFeedDefaultCombinedSort)
    required FeedSort feedDefaultCombinedSort,
    required FeedSort feedDefaultExploreSort,
    required CommentSort feedDefaultCommentSort,
    required bool feedDefaultHideReadPosts,
    required List<FeedView> feedViewOrder,
    required List<FeedSource> feedSourceOrder,
    required List<FeedSort> feedSortOrder,
    // Feed actions
    required ActionLocation feedActionBackToTop,
    required ActionLocation feedActionCreateNew,
    required ActionLocation feedActionExpandFab,
    required ActionLocation feedActionRefresh,
    required ActionLocationWithTabs feedActionSetFilter,
    required ActionLocationWithTabs feedActionSetSort,
    required ActionLocationWithTabs feedActionSetView,
    required ActionLocation feedActionHideReadPosts,
    // Swipe Actions
    required bool enableSwipeActions,
    required SwipeAction swipeActionLeftShort,
    required SwipeAction swipeActionLeftLong,
    required SwipeAction swipeActionRightShort,
    required SwipeAction swipeActionRightLong,
    required double swipeActionThreshold,
    // Filter list activations
    required Map<String, bool> filterLists,
    required bool showErrors,
  }) = _ProfileRequired;
  const ProfileRequired._();

  factory ProfileRequired.fromJson(JsonMap json) =>
      _$ProfileRequiredFromJson(json);

  factory ProfileRequired.fromOptional(
    ProfileOptional? profile,
  ) => ProfileRequired(
    autoSwitchAccount: profile?.autoSwitchAccount,
    defaultCreateLanguage:
        profile?.defaultCreateLanguage ?? defaultProfile.defaultCreateLanguage,
    disableTabSwiping:
        profile?.disableTabSwiping ?? defaultProfile.disableTabSwiping,
    askBeforeUnsubscribing:
        profile?.askBeforeUnsubscribing ??
        defaultProfile.askBeforeUnsubscribing,
    askBeforeDeleting:
        profile?.askBeforeDeleting ?? defaultProfile.askBeforeDeleting,
    autoPlayVideos: profile?.autoPlayVideos ?? defaultProfile.autoPlayVideos,
    hapticFeedback: profile?.hapticFeedback ?? defaultProfile.hapticFeedback,
    autoTranslate: profile?.autoTranslate ?? defaultProfile.autoTranslate,
    markThreadsReadOnScroll:
        profile?.markThreadsReadOnScroll ??
        defaultProfile.markThreadsReadOnScroll,
    markMicroblogsReadOnScroll:
        profile?.markMicroblogsReadOnScroll ??
        defaultProfile.markMicroblogsReadOnScroll,
    animationSpeed: profile?.animationSpeed ?? defaultProfile.animationSpeed,
    inlineReplies: profile?.inlineReplies ?? defaultProfile.inlineReplies,
    showCrossPostComments:
        profile?.showCrossPostComments ?? defaultProfile.showCrossPostComments,
    markCrossPostsAsRead:
        profile?.markCrossPostsAsRead ?? defaultProfile.markCrossPostsAsRead,
    defaultImageStore:
        profile?.defaultImageStore ?? defaultProfile.defaultImageStore,
    appLanguage: profile?.appLanguage ?? defaultProfile.appLanguage,
    themeMode: profile?.themeMode ?? defaultProfile.themeMode,
    colorScheme: profile?.colorScheme ?? defaultProfile.colorScheme,
    enableTrueBlack: profile?.enableTrueBlack ?? defaultProfile.enableTrueBlack,
    compactMode: profile?.compactMode ?? defaultProfile.compactMode,
    hideActionButtons:
        profile?.hideActionButtons ?? defaultProfile.hideActionButtons,
    hideFeedUIOnScroll:
        profile?.hideFeedUIOnScroll ?? defaultProfile.hideFeedUIOnScroll,
    globalTextScale: profile?.globalTextScale ?? defaultProfile.globalTextScale,
    alwaysShowInstance:
        profile?.alwaysShowInstance ?? defaultProfile.alwaysShowInstance,
    coverMediaMarkedSensitive:
        profile?.coverMediaMarkedSensitive ??
        defaultProfile.coverMediaMarkedSensitive,
    fullImageSizeThreads:
        profile?.fullImageSizeThreads ?? defaultProfile.fullImageSizeThreads,
    fullImageSizeMicroblogs:
        profile?.fullImageSizeMicroblogs ??
        defaultProfile.fullImageSizeMicroblogs,
    showPostsCards: profile?.showPostsCards ?? defaultProfile.showPostsCards,
    postComponentOrder:
        profile?.postComponentOrder ?? defaultProfile.postComponentOrder,
    dividerThickness:
        profile?.dividerThickness ?? defaultProfile.dividerThickness,
    hideEmojiReactions:
        profile?.hideEmojiReactions ?? defaultProfile.hideEmojiReactions,
    feedDefaultThreadsSort:
        profile?.feedDefaultThreadsSort ??
        defaultProfile.feedDefaultThreadsSort,
    feedDefaultMicroblogSort:
        profile?.feedDefaultMicroblogSort ??
        defaultProfile.feedDefaultMicroblogSort,
    feedDefaultCombinedSort:
        profile?.feedDefaultCombinedSort ??
        defaultProfile.feedDefaultCombinedSort,
    feedDefaultExploreSort:
        profile?.feedDefaultExploreSort ??
        defaultProfile.feedDefaultExploreSort,
    feedDefaultCommentSort:
        profile?.feedDefaultCommentSort ??
        defaultProfile.feedDefaultCommentSort,
    feedDefaultHideReadPosts:
        profile?.feedDefaultHideReadPosts ??
        defaultProfile.feedDefaultHideReadPosts,
    feedViewOrder: profile?.feedViewOrder ?? defaultProfile.feedViewOrder,
    feedSourceOrder: profile?.feedSourceOrder ?? defaultProfile.feedSourceOrder,
    feedSortOrder: profile?.feedSortOrder ?? defaultProfile.feedSortOrder,
    feedActionBackToTop:
        profile?.feedActionBackToTop ?? defaultProfile.feedActionBackToTop,
    feedActionCreateNew:
        profile?.feedActionCreateNew ?? defaultProfile.feedActionCreateNew,
    feedActionExpandFab:
        profile?.feedActionExpandFab ?? defaultProfile.feedActionExpandFab,
    feedActionRefresh:
        profile?.feedActionRefresh ?? defaultProfile.feedActionRefresh,
    feedActionSetFilter:
        profile?.feedActionSetFilter ?? defaultProfile.feedActionSetFilter,
    feedActionSetSort:
        profile?.feedActionSetSort ?? defaultProfile.feedActionSetSort,
    feedActionSetView:
        profile?.feedActionSetView ?? defaultProfile.feedActionSetView,
    feedActionHideReadPosts:
        profile?.feedActionHideReadPosts ??
        defaultProfile.feedActionHideReadPosts,
    enableSwipeActions:
        profile?.enableSwipeActions ?? defaultProfile.enableSwipeActions,
    swipeActionLeftShort:
        profile?.swipeActionLeftShort ?? defaultProfile.swipeActionLeftShort,
    swipeActionLeftLong:
        profile?.swipeActionLeftLong ?? defaultProfile.swipeActionLeftLong,
    swipeActionRightShort:
        profile?.swipeActionRightShort ?? defaultProfile.swipeActionRightShort,
    swipeActionRightLong:
        profile?.swipeActionRightLong ?? defaultProfile.swipeActionRightLong,
    swipeActionThreshold:
        profile?.swipeActionThreshold ?? defaultProfile.swipeActionThreshold,
    filterLists: profile?.filterLists ?? defaultProfile.filterLists,
    showErrors: profile?.showErrors ?? defaultProfile.showErrors,
  );

  static const defaultProfile = ProfileRequired(
    autoSwitchAccount: null,
    defaultCreateLanguage: 'en',
    disableTabSwiping: false,
    askBeforeUnsubscribing: false,
    askBeforeDeleting: true,
    autoPlayVideos: false,
    hapticFeedback: true,
    autoTranslate: false,
    markThreadsReadOnScroll: false,
    markMicroblogsReadOnScroll: false,
    animationSpeed: 1,
    inlineReplies: true,
    showCrossPostComments: true,
    markCrossPostsAsRead: false,
    defaultImageStore: ImageStore.platform,
    appLanguage: '',
    themeMode: ThemeMode.system,
    colorScheme: FlexScheme.custom,
    enableTrueBlack: false,
    compactMode: false,
    hideActionButtons: false,
    hideFeedUIOnScroll: false,
    globalTextScale: 1,
    alwaysShowInstance: false,
    coverMediaMarkedSensitive: true,
    fullImageSizeThreads: false,
    fullImageSizeMicroblogs: false,
    showPostsCards: true,
    postComponentOrder: [
      PostComponent.image,
      PostComponent.title,
      PostComponent.flairs,
      PostComponent.link,
      PostComponent.info,
      PostComponent.body,
    ],
    dividerThickness: 1,
    hideEmojiReactions: false,
    feedDefaultThreadsSort: FeedSort.hot,
    feedDefaultMicroblogSort: FeedSort.hot,
    feedDefaultCombinedSort: FeedSort.hot,
    feedDefaultExploreSort: FeedSort.newest,
    feedDefaultCommentSort: CommentSort.hot,
    feedDefaultHideReadPosts: false,
    feedViewOrder: [FeedView.threads, FeedView.microblog, FeedView.combined],
    feedSourceOrder: [
      FeedSource.subscribed,
      FeedSource.moderated,
      FeedSource.favorited,
      FeedSource.all,
      FeedSource.local,
    ],
    feedSortOrder: FeedSort.values,
    feedActionBackToTop: ActionLocation.fabMenu,
    feedActionCreateNew: ActionLocation.fabMenu,
    feedActionExpandFab: ActionLocation.fabTap,
    feedActionRefresh: ActionLocation.fabMenu,
    feedActionSetFilter: ActionLocationWithTabs.tabs,
    feedActionSetSort: ActionLocationWithTabs.appBar,
    feedActionSetView: ActionLocationWithTabs.appBar,
    feedActionHideReadPosts: ActionLocation.fabMenu,
    enableSwipeActions: false,
    swipeActionLeftShort: SwipeAction.upvote,
    swipeActionLeftLong: SwipeAction.boost,
    swipeActionRightShort: SwipeAction.bookmark,
    swipeActionRightLong: SwipeAction.reply,
    swipeActionThreshold: 0.20,
    filterLists: {},
    showErrors: true,
  );
}

/// Profile class where all fields are optional.
@freezed
abstract class ProfileOptional
    with _$ProfileOptional
    implements Insertable<ProfileOptional> {
  @JsonSerializable(explicitToJson: true, includeIfNull: false)
  const factory ProfileOptional({
    required String name,
    required String? autoSwitchAccount,
    // Behavior settings
    required String? defaultCreateLanguage,
    required bool? disableTabSwiping,
    required bool? askBeforeUnsubscribing,
    required bool? askBeforeDeleting,
    required bool? autoPlayVideos,
    required bool? hapticFeedback,
    required bool? autoTranslate,
    required bool? markThreadsReadOnScroll,
    required bool? markMicroblogsReadOnScroll,
    required double? animationSpeed,
    required bool? inlineReplies,
    required bool? showCrossPostComments,
    required bool? markCrossPostsAsRead,
    required ImageStore? defaultImageStore,
    // Display settings
    required String? appLanguage,
    required ThemeMode? themeMode,
    required FlexScheme? colorScheme,
    required bool? enableTrueBlack,
    required bool? compactMode,
    required bool? hideActionButtons,
    required bool? hideFeedUIOnScroll,
    required double? globalTextScale,
    required bool? alwaysShowInstance,
    required bool? coverMediaMarkedSensitive,
    required bool? fullImageSizeThreads,
    required bool? fullImageSizeMicroblogs,
    required bool? showPostsCards,
    required List<PostComponent>? postComponentOrder,
    required double? dividerThickness,
    required bool? hideEmojiReactions,
    // Feed defaults
    required FeedSort? feedDefaultThreadsSort,
    required FeedSort? feedDefaultMicroblogSort,
    @JsonKey(readValue: _parseFeedDefaultCombinedSort)
    required FeedSort? feedDefaultCombinedSort,
    required FeedSort? feedDefaultExploreSort,
    required CommentSort? feedDefaultCommentSort,
    required bool? feedDefaultHideReadPosts,
    required List<FeedView>? feedViewOrder,
    required List<FeedSource>? feedSourceOrder,
    required List<FeedSort>? feedSortOrder,
    // Feed actions
    required ActionLocation? feedActionBackToTop,
    required ActionLocation? feedActionCreateNew,
    required ActionLocation? feedActionExpandFab,
    required ActionLocation? feedActionRefresh,
    required ActionLocationWithTabs? feedActionSetFilter,
    required ActionLocationWithTabs? feedActionSetSort,
    required ActionLocationWithTabs? feedActionSetView,
    required ActionLocation? feedActionHideReadPosts,
    required bool? enableSwipeActions,
    required SwipeAction? swipeActionLeftShort,
    required SwipeAction? swipeActionLeftLong,
    required SwipeAction? swipeActionRightShort,
    required SwipeAction? swipeActionRightLong,
    required double? swipeActionThreshold,
    // Filter list activations
    required Map<String, bool>? filterLists,
    required bool? showErrors,
  }) = _ProfileOptional;
  const ProfileOptional._();

  factory ProfileOptional.fromJson(JsonMap json) =>
      _$ProfileOptionalFromJson(json);

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    return ProfilesCompanion(
      name: Value(name),
      autoSwitchAccount: Value(autoSwitchAccount),
      // Behaviour
      defaultCreateLanguage: Value(defaultCreateLanguage),
      disableTabSwiping: Value(disableTabSwiping),
      askBeforeUnsubscribing: Value(askBeforeUnsubscribing),
      askBeforeDeleting: Value(askBeforeDeleting),
      autoPlayVideos: Value(autoPlayVideos),
      hapticFeedback: Value(hapticFeedback),
      autoTranslate: Value(autoTranslate),
      markThreadsReadOnScroll: Value(markThreadsReadOnScroll),
      markMicroblogsReadOnScroll: Value(markMicroblogsReadOnScroll),
      animationSpeed: Value(animationSpeed),
      inlineReplies: Value(inlineReplies),
      showCrossPostComments: Value(showCrossPostComments),
      markCrossPostsAsRead: Value(markCrossPostsAsRead),
      defaultImageStore: Value(defaultImageStore),
      // Display
      appLanguage: Value(appLanguage),
      themeMode: Value(themeMode),
      colorScheme: Value(colorScheme),
      enableTrueBlack: Value(enableTrueBlack),
      compactMode: Value(compactMode),
      hideActionButtons: Value(hideActionButtons),
      hideFeedUIOnScroll: Value(hideFeedUIOnScroll),
      globalTextScale: Value(globalTextScale),
      alwaysShowInstance: Value(alwaysShowInstance),
      coverMediaMarkedSensitive: Value(coverMediaMarkedSensitive),
      fullImageSizeThreads: Value(fullImageSizeThreads),
      fullImageSizeMicroblogs: Value(fullImageSizeMicroblogs),
      showPostsCards: Value(showPostsCards),
      postComponentOrder: Value(postComponentOrder),
      dividerThickness: Value(dividerThickness),
      hideEmojiReactions: Value(hideEmojiReactions),
      // Feed defaults
      feedDefaultThreadsSort: Value(feedDefaultThreadsSort),
      feedDefaultMicroblogSort: Value(feedDefaultMicroblogSort),
      feedDefaultCombinedSort: Value(feedDefaultCombinedSort),
      feedDefaultExploreSort: Value(feedDefaultExploreSort),
      feedDefaultCommentSort: Value(feedDefaultCommentSort),
      feedDefaultHideReadPosts: Value(feedDefaultHideReadPosts),
      feedViewOrder: Value(feedViewOrder),
      feedSourceOrder: Value(feedSourceOrder),
      feedSortOrder: Value(feedSortOrder),
      // Feed actions
      feedActionBackToTop: Value(feedActionBackToTop),
      feedActionCreateNew: Value(feedActionCreateNew),
      feedActionExpandFab: Value(feedActionExpandFab),
      feedActionRefresh: Value(feedActionRefresh),
      feedActionSetFilter: Value(feedActionSetFilter),
      feedActionSetSort: Value(feedActionSetSort),
      feedActionSetView: Value(feedActionSetView),
      feedActionHideReadPosts: Value(feedActionHideReadPosts),
      // Swipe actions
      enableSwipeActions: Value(enableSwipeActions),
      swipeActionLeftShort: Value(swipeActionLeftShort),
      swipeActionLeftLong: Value(swipeActionLeftLong),
      swipeActionRightShort: Value(swipeActionRightShort),
      swipeActionRightLong: Value(swipeActionRightLong),
      swipeActionThreshold: Value(swipeActionThreshold),
      // Filter list activations
      filterLists: Value(filterLists),
      showErrors: Value(showErrors),
    ).toColumns(nullToAbsent);
  }

  static const nullProfile = ProfileOptional(
    name: '',
    autoSwitchAccount: null,
    defaultCreateLanguage: null,
    disableTabSwiping: null,
    askBeforeUnsubscribing: null,
    askBeforeDeleting: null,
    autoPlayVideos: null,
    hapticFeedback: null,
    autoTranslate: null,
    markThreadsReadOnScroll: null,
    markMicroblogsReadOnScroll: null,
    animationSpeed: null,
    inlineReplies: null,
    showCrossPostComments: null,
    markCrossPostsAsRead: null,
    defaultImageStore: null,
    appLanguage: null,
    themeMode: null,
    colorScheme: null,
    enableTrueBlack: null,
    compactMode: null,
    hideActionButtons: null,
    hideFeedUIOnScroll: null,
    globalTextScale: null,
    alwaysShowInstance: null,
    coverMediaMarkedSensitive: null,
    fullImageSizeThreads: null,
    fullImageSizeMicroblogs: null,
    showPostsCards: null,
    postComponentOrder: null,
    dividerThickness: null,
    hideEmojiReactions: null,
    feedDefaultThreadsSort: null,
    feedDefaultMicroblogSort: null,
    feedDefaultCombinedSort: null,
    feedDefaultExploreSort: null,
    feedDefaultCommentSort: null,
    feedDefaultHideReadPosts: null,
    feedViewOrder: null,
    feedSourceOrder: null,
    feedSortOrder: null,
    feedActionBackToTop: null,
    feedActionCreateNew: null,
    feedActionExpandFab: null,
    feedActionRefresh: null,
    feedActionSetFilter: null,
    feedActionSetSort: null,
    feedActionSetView: null,
    feedActionHideReadPosts: null,
    enableSwipeActions: null,
    swipeActionLeftShort: null,
    swipeActionLeftLong: null,
    swipeActionRightShort: null,
    swipeActionRightLong: null,
    swipeActionThreshold: null,
    filterLists: null,
    showErrors: null,
  );

  ProfileOptional merge(ProfileOptional? other) {
    if (other == null) return this;

    return ProfileOptional(
      name: name,
      autoSwitchAccount: other.autoSwitchAccount,
      defaultCreateLanguage:
          other.defaultCreateLanguage ?? defaultCreateLanguage,
      disableTabSwiping: other.disableTabSwiping ?? disableTabSwiping,
      askBeforeUnsubscribing:
          other.askBeforeUnsubscribing ?? askBeforeUnsubscribing,
      askBeforeDeleting: other.askBeforeDeleting ?? askBeforeDeleting,
      autoPlayVideos: other.autoPlayVideos ?? autoPlayVideos,
      hapticFeedback: other.hapticFeedback ?? hapticFeedback,
      autoTranslate: other.autoTranslate ?? autoTranslate,
      markThreadsReadOnScroll:
          other.markThreadsReadOnScroll ?? markThreadsReadOnScroll,
      markMicroblogsReadOnScroll:
          other.markMicroblogsReadOnScroll ?? markMicroblogsReadOnScroll,
      animationSpeed: other.animationSpeed ?? animationSpeed,
      inlineReplies: other.inlineReplies ?? inlineReplies,
      showCrossPostComments:
          other.showCrossPostComments ?? showCrossPostComments,
      markCrossPostsAsRead: other.markCrossPostsAsRead ?? markCrossPostsAsRead,
      defaultImageStore: other.defaultImageStore ?? defaultImageStore,
      appLanguage: other.appLanguage ?? appLanguage,
      themeMode: other.themeMode ?? themeMode,
      colorScheme: other.colorScheme ?? colorScheme,
      enableTrueBlack: other.enableTrueBlack ?? enableTrueBlack,
      compactMode: other.compactMode ?? compactMode,
      hideActionButtons: other.hideActionButtons ?? hideActionButtons,
      hideFeedUIOnScroll: other.hideFeedUIOnScroll ?? hideFeedUIOnScroll,
      globalTextScale: other.globalTextScale ?? globalTextScale,
      alwaysShowInstance: other.alwaysShowInstance ?? alwaysShowInstance,
      coverMediaMarkedSensitive:
          other.coverMediaMarkedSensitive ?? coverMediaMarkedSensitive,
      fullImageSizeThreads: other.fullImageSizeThreads ?? fullImageSizeThreads,
      fullImageSizeMicroblogs:
          other.fullImageSizeMicroblogs ?? fullImageSizeMicroblogs,
      showPostsCards: other.showPostsCards ?? showPostsCards,
      postComponentOrder: other.postComponentOrder ?? postComponentOrder,
      dividerThickness: other.dividerThickness ?? dividerThickness,
      hideEmojiReactions: other.hideEmojiReactions ?? hideEmojiReactions,
      feedDefaultThreadsSort:
          other.feedDefaultThreadsSort ?? feedDefaultThreadsSort,
      feedDefaultMicroblogSort:
          other.feedDefaultMicroblogSort ?? feedDefaultMicroblogSort,
      feedDefaultCombinedSort:
          other.feedDefaultCombinedSort ?? feedDefaultCombinedSort,
      feedDefaultExploreSort:
          other.feedDefaultExploreSort ?? feedDefaultExploreSort,
      feedDefaultCommentSort:
          other.feedDefaultCommentSort ?? feedDefaultCommentSort,
      feedDefaultHideReadPosts:
          other.feedDefaultHideReadPosts ?? feedDefaultHideReadPosts,
      feedViewOrder: other.feedViewOrder ?? feedViewOrder,
      feedSourceOrder: other.feedSourceOrder ?? feedSourceOrder,
      feedSortOrder: other.feedSortOrder ?? feedSortOrder,
      feedActionBackToTop: other.feedActionBackToTop ?? feedActionBackToTop,
      feedActionCreateNew: other.feedActionCreateNew ?? feedActionCreateNew,
      feedActionExpandFab: other.feedActionExpandFab ?? feedActionExpandFab,
      feedActionRefresh: other.feedActionRefresh ?? feedActionRefresh,
      feedActionSetFilter: other.feedActionSetFilter ?? feedActionSetFilter,
      feedActionSetSort: other.feedActionSetSort ?? feedActionSetSort,
      feedActionSetView: other.feedActionSetView ?? feedActionSetView,
      feedActionHideReadPosts:
          other.feedActionHideReadPosts ?? feedActionHideReadPosts,
      enableSwipeActions: other.enableSwipeActions ?? enableSwipeActions,
      swipeActionLeftShort: other.swipeActionLeftShort ?? swipeActionLeftShort,
      swipeActionLeftLong: other.swipeActionLeftLong ?? swipeActionLeftLong,
      swipeActionRightShort:
          other.swipeActionRightShort ?? swipeActionRightShort,
      swipeActionRightLong: other.swipeActionRightLong ?? swipeActionRightLong,
      swipeActionThreshold: other.swipeActionThreshold ?? swipeActionThreshold,
      filterLists: filterLists != null && other.filterLists != null
          ? {...filterLists!, ...other.filterLists!}
          : other.filterLists ?? filterLists,
      showErrors: other.showErrors ?? showErrors,
    );
  }

  ProfileOptional cleanupActions(
    String actionName,
    ProfileRequired builtProfile,
  ) {
    // Only clean up actions with the following locations
    if (![
      ActionLocation.fabTap.name,
      ActionLocation.fabHold.name,
      ActionLocationWithTabs.tabs.name,
    ].contains(actionName)) {
      return this;
    }

    return copyWith(
      feedActionBackToTop: builtProfile.feedActionBackToTop.name == actionName
          ? ActionLocation.hide
          : feedActionBackToTop,
      feedActionCreateNew: builtProfile.feedActionCreateNew.name == actionName
          ? ActionLocation.hide
          : feedActionCreateNew,
      feedActionExpandFab: builtProfile.feedActionExpandFab.name == actionName
          ? ActionLocation.hide
          : feedActionExpandFab,
      feedActionRefresh: builtProfile.feedActionRefresh.name == actionName
          ? ActionLocation.hide
          : feedActionRefresh,
      feedActionSetFilter: builtProfile.feedActionSetFilter.name == actionName
          ? ActionLocationWithTabs.hide
          : feedActionSetFilter,
      feedActionSetSort: builtProfile.feedActionSetSort.name == actionName
          ? ActionLocationWithTabs.hide
          : feedActionSetSort,
      feedActionSetView: builtProfile.feedActionSetView.name == actionName
          ? ActionLocationWithTabs.hide
          : feedActionSetView,
    );
  }

  // Remove fields that depend on a certain setup
  ProfileOptional exportReady() {
    return copyWith(autoSwitchAccount: null, filterLists: null);
  }
}

Object? _parseFeedDefaultCombinedSort(Map json, String name) {
  final current = json[name];
  if (current != null) return current;
  return json['feedDefaultTimelineSort'];
}

class FeedViewConverter implements JsonConverter<FeedView, String> {
  const FeedViewConverter();

  @override
  FeedView fromJson(String json) {
    if (json == 'timeline') json = 'combined';
    return FeedView.values.byName(json);
  }

  @override
  String toJson(FeedView view) => view.name;
}
