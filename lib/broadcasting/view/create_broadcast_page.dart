import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:society_management/ads/service/ad_service.dart';
import 'package:society_management/ads/widgets/ad_widgets.dart';
import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/broadcasting/model/broadcast_model.dart';
import 'package:society_management/broadcasting/repository/i_broadcast_repository.dart';
import 'package:society_management/broadcasting/service/broadcast_service.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';
import 'package:society_management/widget/theme_aware_card.dart';

class CreateBroadcastPage extends StatefulWidget {
  final BroadcastType? initialType;

  const CreateBroadcastPage({super.key, this.initialType});

  @override
  State<CreateBroadcastPage> createState() => _CreateBroadcastPageState();
}

class _CreateBroadcastPageState extends State<CreateBroadcastPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _lineNumberController = TextEditingController();

  final BroadcastService _broadcastService = getIt<BroadcastService>();
  final AuthService _authService = getIt<AuthService>();

  UserModel? _currentUser;
  BroadcastType _selectedType = BroadcastType.announcement;
  BroadcastPriority _selectedPriority = BroadcastPriority.normal;
  BroadcastTarget _selectedTarget = BroadcastTarget.all;
  DateTime? _scheduledDateTime;
  bool _isLoading = false;
  bool _sendImmediately = true;
  final List<String> _attachments = [];
  bool _premiumTemplatesUnlocked = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
      _setPriorityBasedOnType();
    }
    // Preload ads for better user experience
    AdService.instance.preloadAds();
  }

  void _setPriorityBasedOnType() {
    switch (_selectedType) {
      case BroadcastType.emergency:
        _selectedPriority = BroadcastPriority.critical;
        break;
      case BroadcastType.warning:
        _selectedPriority = BroadcastPriority.urgent;
        break;
      case BroadcastType.reminder:
        _selectedPriority = BroadcastPriority.high;
        break;
      default:
        _selectedPriority = BroadcastPriority.normal;
    }
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getCurrentUser();
    setState(() => _currentUser = user);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: CommonAppBar(
        title: '✨ Create Broadcast',
        showDivider: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
            tooltip: 'Help',
          ),
        ],
      ),
      body: _currentUser == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primaryBlue),
                  const Gap(16),
                  Text(
                    'Loading user information...',
                    style: TextStyle(
                      color: isDark ? Colors.grey[300] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(context),
                    const Gap(20),
                    _buildTypeSection(),
                    const Gap(20),
                    _buildContentSection(),
                    const Gap(20),
                    _buildTargetSection(),
                    const Gap(20),
                    _buildSchedulingSection(),
                    const Gap(30),
                    _buildActionButtons(),
                    const Gap(20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTypeSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ThemeAwareCard(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.category_rounded, color: AppColors.primaryBlue, size: 20),
                ),
                const Gap(12),
                const Text(
                  'Choose Broadcast Type',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Gap(8),
            Text(
              'Select the type that best describes your message',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const Gap(20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: BroadcastType.values.map((type) {
                final isSelected = _selectedType == type;
                final typeColor = _getTypeColor(type);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = type;
                      _setPriorityBasedOnType();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? typeColor.withValues(alpha: 0.1) : (isDark ? Colors.grey[800] : Colors.grey[50]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? typeColor : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: typeColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              type.emoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const Gap(8),
                            Expanded(
                              child: Text(
                                type.displayName,
                                style: TextStyle(
                                  color: isSelected ? typeColor : (isDark ? Colors.white : Colors.black87),
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: typeColor,
                                size: 18,
                              ),
                          ],
                        ),
                        const Gap(4),
                        Text(
                          _getTypeDescription(type),
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const Gap(20),
            _buildPrioritySection(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.priority_high_rounded,
                color: _getPriorityColor(_selectedPriority),
                size: 20,
              ),
              const Gap(8),
              const Text(
                'Priority Level',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Gap(12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: BroadcastPriority.values.map((priority) {
                final isSelected = _selectedPriority == priority;
                final priorityColor = _getPriorityColor(priority);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedPriority = priority);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? priorityColor.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? priorityColor : Colors.grey[400]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: priorityColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const Gap(6),
                          Text(
                            priority.displayName,
                            style: TextStyle(
                              color: isSelected ? priorityColor : (isDark ? Colors.grey[300] : Colors.grey[700]),
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ThemeAwareCard(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_rounded, color: AppColors.primaryGreen, size: 20),
                ),
                const Gap(12),
                const Text(
                  'Broadcast Content',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Gap(8),
            Text(
              'Write your message clearly and concisely',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const Gap(20),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title *',
                hintText: 'Enter a clear, descriptive title',
                prefixIcon: const Icon(Icons.title_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                if (value.trim().length < 3) {
                  return 'Title must be at least 3 characters';
                }
                return null;
              },
            ),
            const Gap(16),
            TextFormField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Message *',
                hintText:
                    'Write your message here...\n\nTip: Be clear and specific about what action (if any) recipients should take.',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.message_rounded),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a message';
                }
                if (value.trim().length < 10) {
                  return 'Message must be at least 10 characters';
                }
                return null;
              },
            ),
            const Gap(16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: AppColors.primaryBlue, size: 20),
                  Gap(8),
                  Expanded(
                    child: Text(
                      'Pro tip: Use emojis and clear language to make your message more engaging!',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(20),
            _buildTemplateSection(isDark),
            const Gap(20),
            _buildPremiumTemplateSection(isDark),
            const Gap(20),
            _buildAttachmentSection(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateSection(bool isDark) {
    final templates = [
      {
        'name': '🚨 Emergency Alert',
        'title': 'URGENT: Emergency Alert',
        'message': 'This is an emergency notification. Please take immediate action as required.'
      },
      {
        'name': '🔧 Maintenance Notice',
        'title': 'Scheduled Maintenance',
        'message':
            'Dear residents, we will be conducting maintenance work on [DATE] from [TIME]. Please plan accordingly.'
      },
      {
        'name': '🎉 Event Invitation',
        'title': 'Community Event Invitation',
        'message': 'You are cordially invited to our community event on [DATE] at [TIME]. Join us for [EVENT DETAILS].'
      },
      {
        'name': '💰 Payment Reminder',
        'title': 'Payment Due Reminder',
        'message':
            'This is a friendly reminder that your payment is due on [DATE]. Please make the payment to avoid late fees.'
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.library_books_rounded, color: AppColors.primaryPurple, size: 20),
              Gap(8),
              Text(
                'Quick Templates',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Gap(12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: templates.map((template) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton(
                    onPressed: () => _useTemplate(template),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Text(
                      template['name']!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTemplateSection(bool isDark) {
    return AdSupportedFeature(
      featureName: '✨ Premium Templates',
      description: 'Unlock professional broadcast templates with advanced formatting',
      icon: Icons.star_rounded,
      isUnlocked: _premiumTemplatesUnlocked,
      onUnlock: () {
        setState(() {
          _premiumTemplatesUnlocked = true;
        });
        Utility.toast(message: '🎉 Premium templates unlocked! Thank you for watching the ad.');
      },
    );
  }

  Widget _buildAttachmentSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.attach_file_rounded, color: AppColors.primaryOrange, size: 20),
              Gap(8),
              Text(
                'Attachments (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(),
                  icon: const Icon(Icons.image_rounded),
                  label: const Text('Add Image'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDocument(),
                  icon: const Icon(Icons.description_rounded),
                  label: const Text('Add Document'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          if (_attachments.isNotEmpty) ...[
            const Gap(12),
            ...(_attachments.map((attachment) => _buildAttachmentItem(attachment, isDark))),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachmentItem(String attachment, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[700] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(
            attachment.contains('.pdf') ? Icons.picture_as_pdf : Icons.image,
            color: AppColors.primaryBlue,
          ),
          const Gap(8),
          Expanded(
            child: Text(
              attachment.split('/').last,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => _removeAttachment(attachment),
            icon: const Icon(Icons.close, size: 18),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildTargetSection() {
    return ThemeAwareCard(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.group, color: AppColors.primaryBlue),
                Gap(8),
                Text(
                  'Target Audience',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Gap(12),
            ...BroadcastTarget.values.map((target) {
              return RadioListTile<BroadcastTarget>(
                title: Text(target.displayName),
                value: target,
                groupValue: _selectedTarget,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedTarget = value);
                  }
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            }),
            if (_selectedTarget == BroadcastTarget.line) ...[
              const Gap(8),
              TextFormField(
                controller: _lineNumberController,
                decoration: const InputDecoration(
                  labelText: 'Line Number',
                  hintText: 'e.g., line_a, line_b',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (_selectedTarget == BroadcastTarget.line && (value == null || value.trim().isEmpty)) {
                    return 'Please enter line number';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulingSection() {
    return ThemeAwareCard(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.schedule, color: AppColors.primaryBlue),
                Gap(8),
                Text(
                  'Scheduling',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Gap(12),
            SwitchListTile(
              title: const Text('Send Immediately'),
              subtitle: Text(_sendImmediately ? 'Broadcast will be sent right away' : 'Schedule for later'),
              value: _sendImmediately,
              onChanged: (value) {
                setState(() => _sendImmediately = value);
              },
              contentPadding: EdgeInsets.zero,
            ),
            if (!_sendImmediately) ...[
              const Gap(8),
              ListTile(
                title: Text(_scheduledDateTime == null
                    ? 'Select Date & Time'
                    : 'Scheduled: ${_formatDateTime(_scheduledDateTime!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDateTime,
                contentPadding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
        ),
        const Gap(12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _createBroadcast,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_sendImmediately ? 'Send Now' : 'Schedule'),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _scheduledDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _createBroadcast() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_sendImmediately && _scheduledDateTime == null) {
      Utility.toast(message: 'Please select a date and time for scheduling');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_sendImmediately) {
        // Create and send immediately
        await _broadcastService.createAndSendBroadcast(
          title: _titleController.text.trim(),
          message: _messageController.text.trim(),
          type: _selectedType,
          priority: _selectedPriority,
          target: _selectedTarget,
          targetLineNumber: _selectedTarget == BroadcastTarget.line ? _lineNumberController.text.trim() : null,
          createdBy: _currentUser!.id!,
          creatorName: _currentUser!.name ?? 'Unknown',
        );

        Utility.toast(message: 'Broadcast sent successfully!');
      } else {
        // Create and schedule
        final createResult = await getIt<IBroadcastRepository>().createBroadcast(
          title: _titleController.text.trim(),
          message: _messageController.text.trim(),
          type: _selectedType,
          priority: _selectedPriority,
          target: _selectedTarget,
          targetLineNumber: _selectedTarget == BroadcastTarget.line ? _lineNumberController.text.trim() : null,
          createdBy: _currentUser!.id!,
          creatorName: _currentUser!.name ?? 'Unknown',
          scheduledAt: _scheduledDateTime,
        );

        createResult.fold(
          (failure) => throw Exception(failure.message),
          (broadcast) async {
            await _broadcastService.scheduleBroadcast(
              broadcastId: broadcast.id!,
              scheduledAt: _scheduledDateTime!,
            );
          },
        );

        Utility.toast(message: 'Broadcast scheduled successfully!');
      }

      if (mounted) {
        // Show interstitial ad after successful broadcast creation
        InterstitialAdHelper.incrementActionCount();
        InterstitialAdHelper.showAdIfNeeded(
          onAdClosed: () => context.pop(true),
        );

        if (!InterstitialAdHelper.shouldShowAd()) {
          context.pop(true);
        }
      }
    } catch (e) {
      Utility.toast(message: 'Error creating broadcast: $e');
    }

    setState(() => _isLoading = false);
  }

  // New improved methods
  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryBlue.withValues(alpha: 0.8), AppColors.primaryPurple.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.create_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create New Broadcast',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(4),
                Text(
                  'Share important information with your community',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: AppColors.primaryBlue),
            Gap(8),
            Text('Broadcasting Help'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📢 Announcement: General community news'),
            Gap(8),
            Text('🚨 Emergency: Critical urgent alerts'),
            Gap(8),
            Text('🔧 Maintenance: Service notifications'),
            Gap(8),
            Text('🎉 Event: Invitations and celebrations'),
            Gap(8),
            Text('⏰ Reminder: Payment and meeting reminders'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  // Helper methods for improved UI
  String _getTypeDescription(BroadcastType type) {
    switch (type) {
      case BroadcastType.emergency:
        return 'Critical urgent alerts';
      case BroadcastType.announcement:
        return 'General community news';
      case BroadcastType.maintenance:
        return 'Service notifications';
      case BroadcastType.event:
        return 'Invitations & celebrations';
      case BroadcastType.reminder:
        return 'Payment & meeting reminders';
      case BroadcastType.notice:
        return 'Official notices';
      case BroadcastType.celebration:
        return 'Achievements & milestones';
      case BroadcastType.warning:
        return 'Important warnings';
    }
  }

  Color _getTypeColor(BroadcastType type) {
    switch (type) {
      case BroadcastType.emergency:
        return AppColors.primaryRed;
      case BroadcastType.announcement:
        return AppColors.primaryBlue;
      case BroadcastType.maintenance:
        return AppColors.primaryOrange;
      case BroadcastType.event:
        return AppColors.primaryGreen;
      case BroadcastType.reminder:
        return AppColors.primaryPurple;
      case BroadcastType.notice:
        return Colors.grey[600]!;
      case BroadcastType.celebration:
        return Colors.pink;
      case BroadcastType.warning:
        return Colors.amber[700]!;
    }
  }

  Color _getPriorityColor(BroadcastPriority priority) {
    switch (priority) {
      case BroadcastPriority.low:
        return Colors.green;
      case BroadcastPriority.normal:
        return AppColors.primaryBlue;
      case BroadcastPriority.high:
        return AppColors.primaryOrange;
      case BroadcastPriority.urgent:
        return AppColors.primaryRed;
      case BroadcastPriority.critical:
        return Colors.red[900]!;
    }
  }

  // Attachment handling methods
  void _pickImage() async {
    // TODO: Implement image picker
    Utility.toast(message: 'Image picker feature coming soon!');
  }

  void _pickDocument() async {
    // TODO: Implement document picker
    Utility.toast(message: 'Document picker feature coming soon!');
  }

  void _removeAttachment(String attachment) {
    setState(() {
      _attachments.remove(attachment);
    });
  }

  void _useTemplate(Map<String, String> template) {
    setState(() {
      _titleController.text = template['title']!;
      _messageController.text = template['message']!;
    });
    Utility.toast(message: 'Template applied! You can edit the content as needed.');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _lineNumberController.dispose();
    super.dispose();
  }
}
