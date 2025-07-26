import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/users/widget/user_list_item.dart';

/// A high-quality paginated user list widget with proper state management
/// Features: Pagination (10 items per page), proper color usage, no refresh functionality
class UserListWidget extends StatefulWidget {
  final ValueNotifier<bool> isLoading;
  final ValueNotifier<List<UserModel>> users;
  final ValueNotifier<String?> errorMessage;
  final VoidCallback? onRetry;
  final Function(UserModel)? onResetPassword;
  final int itemsPerPage;

  const UserListWidget({
    super.key,
    required this.isLoading,
    required this.users,
    required this.errorMessage,
    this.onRetry,
    this.onResetPassword,
    this.itemsPerPage = 10,
  });

  @override
  State<UserListWidget> createState() => _UserListWidgetState();
}

class _UserListWidgetState extends State<UserListWidget> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<int> _displayedItemsCount = ValueNotifier(10);
  final ValueNotifier<bool> _isLoadingMore = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    widget.users.addListener(_resetDisplayedItems);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    widget.users.removeListener(_resetDisplayedItems);
    _displayedItemsCount.dispose();
    _isLoadingMore.dispose();
    super.dispose();
  }

  /// Reset displayed items when user list changes
  void _resetDisplayedItems() {
    _displayedItemsCount.value = widget.itemsPerPage;
  }

  /// Handle scroll events for infinite scroll pagination
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }
  }

  /// Load more items with loading indicator
  Future<void> _loadMoreItems() async {
    if (_isLoadingMore.value) return;

    final totalUsers = widget.users.value.length;
    final currentDisplayed = _displayedItemsCount.value;

    if (currentDisplayed >= totalUsers) return;

    _isLoadingMore.value = true;

    // Simulate loading delay for better UX
    await Future.delayed(const Duration(milliseconds: 500));

    final newCount = (currentDisplayed + widget.itemsPerPage).clamp(0, totalUsers);
    _displayedItemsCount.value = newCount;
    _isLoadingMore.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.isLoading,
      builder: (context, isLoadingValue, child) {
        if (isLoadingValue) {
          return _buildLoadingState();
        }

        return ValueListenableBuilder<String?>(
          valueListenable: widget.errorMessage,
          builder: (context, errorValue, child) {
            if (errorValue != null) {
              return _buildErrorState(errorValue);
            }

            return ValueListenableBuilder<List<UserModel>>(
              valueListenable: widget.users,
              builder: (context, usersValue, child) {
                if (usersValue.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildPaginatedUsersList(usersValue);
              },
            );
          },
        );
      },
    );
  }

  /// Build loading state widget with proper styling
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.buttonColor,
            strokeWidth: 3.0,
          ),
          SizedBox(height: 16),
          Text(
            'Loading users...',
            style: TextStyle(
              color: AppColors.greyText,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Build error state widget with proper AppColors
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.red.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Error: $error',
            style: const TextStyle(
              color: AppColors.red,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: widget.onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonColor,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty state widget with proper AppColors
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppColors.greyText.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          const Text(
            'No users found',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.greyText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some users to get started',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.greyText.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Build paginated users list with navigation controls
  Widget _buildPaginatedUsersList(List<UserModel> usersList) {
    return ValueListenableBuilder<int>(
      valueListenable: _displayedItemsCount,
      builder: (_, displayedCount, __) {
        final displayedUsers = usersList.take(displayedCount).toList();
        final hasMoreItems = displayedCount < usersList.length;

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: displayedUsers.length + (hasMoreItems ? 1 : 0),
          itemBuilder: (context, index) {
            // Show loading indicator at the end
            if (index == displayedUsers.length) {
              return _buildLoadingMoreIndicator();
            }
            final user = displayedUsers[index];
            return UserListItem(
              user: user,
              onResetPassword: widget.onResetPassword != null ? () => widget.onResetPassword!(user) : null,
            );
          },
        );
      },
    );
  }

  /// Build loading more indicator for infinite scroll
  Widget _buildLoadingMoreIndicator() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isLoadingMore,
      builder: (context, isLoadingMore, child) {
        if (!isLoadingMore) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.buttonColor,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Loading more users...',
                  style: TextStyle(
                    color: AppColors.greyText,
                    fontSize: 12,
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
