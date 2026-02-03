import 'dart:async';

import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:interstellar/src/widgets/error_page.dart';
import 'package:logger/logger.dart';

/// Derived from [PagingController]. A controller to handle a [PagingState].
///
/// Next page key storage and item deduplication have been added.
class AdvancedPagingController<PageKeyType, PageItemType, PageItemIdType>
    extends ValueNotifier<PagingState<PageKeyType, PageItemType>> {
  AdvancedPagingController({
    required Logger logger,
    required PageKeyType firstPageKey,
    required PageItemIdType Function(PageItemType item) getItemId,
    required Future<(List<PageItemType>, PageKeyType?)> Function(
      PageKeyType pageKey,
    )
    fetchPage,
  }) : _fetchPage = fetchPage,
       _getItemId = getItemId,
       _firstPage = firstPageKey,
       _nextPage = firstPageKey,
       _logger = logger,
       super(PagingState<PageKeyType, PageItemType>());

  /// Used to detect and remove duplicate items.
  final PageItemIdType Function(PageItemType item) _getItemId;

  /// The function to fetch a page.
  /// Returns a record with a list of resultant items the next page key.
  final Future<(List<PageItemType>, PageKeyType?)> Function(PageKeyType pageKey)
  _fetchPage;

  Set<PageItemIdType> _itemIds = {};
  PageKeyType? _nextPage;
  final PageKeyType _firstPage;

  final Logger _logger;

  /// Keeps track of the current operation.
  /// If the operation changes during its execution, the operation is cancelled.
  ///
  /// Instead of using this property directly, use [fetchNextPage], [refresh], or [cancel].
  /// If you are extending this class, check and set this property before and after the fetch operation.
  @protected
  @visibleForTesting
  Object? operation;

  /// Fetches the next page.
  ///
  /// If called while a page is fetching or no more pages are available, this method does nothing.
  Future<void> fetchNextPage() async {
    // We are already loading a new page.
    if (this.operation != null) return;

    final operation = this.operation = Object();

    value = value.copyWith(isLoading: true, error: null);

    // we use a local copy of value,
    // so that we only send one notification now and at the end of the method.
    var state = value;
    PageKeyType? newNextPage;
    final newItemIds = <PageItemIdType>{..._itemIds};

    try {
      // There are no more pages to load.
      if (!state.hasNextPage) return;

      // We are at the end of the list.
      if (_nextPage == null) {
        state = state.copyWith(hasNextPage: false);
        return;
      }

      final thisPage = _nextPage as PageKeyType;

      final result = await _fetchPage(thisPage);

      // Only include a new item if it's unique identifier does not already exist
      final newItems = <PageItemType>[];
      for (final item in result.$1) {
        final itemId = _getItemId(item);
        if (!newItemIds.contains(itemId)) {
          newItems.add(item);
          newItemIds.add(itemId);
        }
      }

      // Update our state in case it was modified during the fetch operation.
      // This beaks atomicity, but is necessary to allow users to modify the state during a fetch.
      state = value;

      state = state.copyWith(
        pages: [...?state.pages, newItems],
        keys: [...?state.keys, thisPage],
      );
      newNextPage = result.$2;
    } catch (error, st) {
      state = state.copyWith(error: error);
      _logger.e(error, stackTrace: st);

      if (error is! Exception) {
        // Errors which are not exceptions indicate that something
        // went unexpectedly wrong. These errors are rethrown
        // so they can be logged and investigated.
        rethrow;
      }
    } finally {
      if (operation == this.operation) {
        value = state.copyWith(
          isLoading: false,
          hasNextPage: _nextPage != null,
        );
        _nextPage = newNextPage;
        _itemIds = newItemIds;
        this.operation = null;
      }
    }
  }

  /// Restarts the pagination process.
  ///
  /// This cancels the current fetch operation and resets the state.
  void refresh() {
    operation = null;
    value = value.reset();
    _nextPage = _firstPage;
    _itemIds.clear();
  }

  /// Cancels the current fetch operation.
  ///
  /// This can be called right before a call to [fetchNextPage] to force a new fetch.
  void cancel() {
    operation = null;
    value = value.copyWith(isLoading: false);
  }

  @override
  void dispose() {
    operation = null;
    super.dispose();
  }

  void updateItem(PageItemType oldItem, PageItemType newItem) {
    final oldItemId = _getItemId(oldItem);
    mapItems((oldItem) => oldItemId == _getItemId(oldItem) ? newItem : oldItem);
  }

  void removeItem(PageItemType oldItem) {
    final oldItemId = _getItemId(oldItem);
    value = value.filterItems((item) => oldItemId != _getItemId(item));
  }

  void mapItems(PageItemType Function(PageItemType item) mapper) =>
      value = value.mapItems(mapper);

  void prependPage(PageKeyType key, List<PageItemType> items) {
    var state = value;

    final newItemIds = <PageItemIdType>{..._itemIds};
    final newItems = <PageItemType>[];
    for (final item in items) {
      final itemId = _getItemId(item);
      if (!newItemIds.contains(itemId)) {
        newItems.add(item);
        newItemIds.add(itemId);
      }
    }

    state = state.copyWith(
      keys: [key, ...?state.keys],
      pages: [items, ...?state.pages],
    );
    value = state;
    _itemIds = newItemIds;
  }
}

class AdvancedPagingListener<PageKeyType, PageItemType, PageItemIdType>
    extends StatelessWidget {
  const AdvancedPagingListener({
    required this.controller,
    required this.builder,
    super.key,
  });

  final AdvancedPagingController<PageKeyType, PageItemType, PageItemIdType>
  controller;
  final Widget Function(
    BuildContext context,
    PagingState<PageKeyType, PageItemType> state,
    NextPageCallback fetchNextPage,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PagingState<PageKeyType, PageItemType>>(
      valueListenable: controller,
      builder: (context, state, _) =>
          builder(context, state, controller.fetchNextPage),
    );
  }
}

/// Derived from [PagedSliverList]. A [SliverList] with pagination capabilities.
///
/// Will automatically pass in `state` and `fetchNextPage` to a [PagedSliverList] based on the passed in [AdvancedPagingController].
class AdvancedPagedSliverList<PageKeyType, PageItemType, PageItemIdType>
    extends StatelessWidget {
  const AdvancedPagedSliverList({
    required this.controller,
    required this.itemBuilder,
    super.key,
  });

  final AdvancedPagingController<PageKeyType, PageItemType, PageItemIdType>
  controller;
  final ItemWidgetBuilder<PageItemType> itemBuilder;

  @override
  Widget build(BuildContext context) => AdvancedPagingListener(
    controller: controller,
    builder: (context, state, fetchNextPage) => PagedSliverList(
      state: state,
      fetchNextPage: fetchNextPage,
      builderDelegate: PagedChildBuilderDelegate<PageItemType>(
        firstPageErrorIndicatorBuilder: (context) => FirstPageErrorIndicator(
          error: state.error,
          onTryAgain: controller.fetchNextPage,
        ),
        newPageErrorIndicatorBuilder: (context) => NewPageErrorIndicator(
          error: state.error,
          onTryAgain: controller.fetchNextPage,
        ),
        itemBuilder: itemBuilder,
      ),
    ),
  );
}

/// Use in place of [CustomScrollView]. A [RefreshIndicator] is built in.
class AdvancedPagedScrollView<PageKeyType, PageItemType, PageItemIdType>
    extends StatelessWidget {
  const AdvancedPagedScrollView({
    required this.controller,
    required this.itemBuilder,
    this.scrollController,
    this.leadingSlivers,
    this.trailingSlivers,

    super.key,
  });

  final AdvancedPagingController<PageKeyType, PageItemType, PageItemIdType>
  controller;
  final ItemWidgetBuilder<PageItemType> itemBuilder;
  final ScrollController? scrollController;

  final List<Widget>? leadingSlivers;
  final List<Widget>? trailingSlivers;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () => Future.sync(controller.refresh),
    child: CustomScrollView(
      controller: scrollController,
      slivers: [
        ...?leadingSlivers,
        AdvancedPagedSliverList(
          controller: controller,
          itemBuilder: itemBuilder,
        ),
        ...?trailingSlivers,
      ],
    ),
  );
}
