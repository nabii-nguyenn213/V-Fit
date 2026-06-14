import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../providers/ai_coach_provider.dart';
import '../providers/ai_workout_planner_provider.dart';

class AiCoachSheet extends ConsumerStatefulWidget {
  const AiCoachSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AiCoachSheet(),
    );
  }

  @override
  ConsumerState<AiCoachSheet> createState() => _AiCoachSheetState();
}

class _AiCoachSheetState extends ConsumerState<AiCoachSheet> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Workout Planner state
  String _selectedLevel = 'Beginner';
  int _daysPerWeek = 4;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.76,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 15,
              spreadRadius: 2,
            )
          ],
        ),
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Header with TabBar
              TabBar(
                indicatorColor: AppColors.primaryOf(context),
                labelColor: AppColors.primaryOf(context),
                unselectedLabelColor: AppColors.textSecondaryOf(context),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(icon: Icon(Icons.chat_bubble_outline_rounded), text: 'AI Coach Chat'),
                  Tab(icon: Icon(Icons.fitness_center_rounded), text: 'Lập lịch tập AI'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildChatTab(context),
                    _buildWorkoutTab(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  // --- TAB 1: Chat ---
  Widget _buildChatTab(BuildContext context) {
    final chatState = ref.watch(aiCoachProvider);

    ref.listen(aiCoachProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length || next.isLoading) {
        _scrollToBottom();
      }
    });

    return Column(
      children: [
        if (chatState.error != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.red.withValues(alpha: 0.1),
            child: Text(
              chatState.error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        Expanded(
          child: chatState.messages.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: chatState.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatState.messages[index];
                    return _buildMessageBubble(context, message);
                  },
                ),
        ),
        if (chatState.isLoading)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'AI Coach đang nghĩ',
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        _buildInputBar(context, chatState.isLoading),
      ],
    );
  }

  Widget _buildMessageBubble(BuildContext context, dynamic message) {
    final isUser = message.isUser as bool;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isUser
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).cardColor;
    final textColor = isUser ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 14),
          ),
        ),
        child: Text(
          message.text as String,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, bool isLoading) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: _messageController,
                textInputAction: TextInputAction.send,
                onSubmitted: isLoading ? null : _handleSend,
                decoration: const InputDecoration(
                  hintText: 'Nhập câu hỏi...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: Icon(
              Icons.send_rounded,
              color: isLoading ? Colors.grey : Theme.of(context).colorScheme.primary,
            ),
            onPressed: isLoading ? null : () => _handleSend(_messageController.text),
          )
        ],
      ),
    );
  }

  void _handleSend(String text) {
    if (text.trim().isEmpty) return;
    ref.read(aiCoachProvider.notifier).sendMessage(text);
    _messageController.clear();
    _scrollToBottom();
  }

  // --- TAB 2: Workout Planner ---
  Widget _buildWorkoutTab(BuildContext context) {
    final state = ref.watch(aiWorkoutPlannerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Lập lịch tập luyện AI',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Hệ thống AI sẽ phân tích thể trạng của bạn để đề xuất lịch tập tối ưu nhất.',
            style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12),
          ),
          const SizedBox(height: 16),
          _buildFormLabel('Trình độ của bạn'),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildChoiceChip(
                label: 'Mới bắt đầu',
                selected: _selectedLevel == 'Beginner',
                onSelected: (selected) {
                  if (selected) setState(() => _selectedLevel = 'Beginner');
                },
              ),
              const SizedBox(width: 8),
              _buildChoiceChip(
                label: 'Trung bình',
                selected: _selectedLevel == 'Intermediate',
                onSelected: (selected) {
                  if (selected) setState(() => _selectedLevel = 'Intermediate');
                },
              ),
              const SizedBox(width: 8),
              _buildChoiceChip(
                label: 'Nâng cao',
                selected: _selectedLevel == 'Advanced',
                onSelected: (selected) {
                  if (selected) setState(() => _selectedLevel = 'Advanced');
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildFormLabel('Số ngày tập mỗi tuần: $_daysPerWeek ngày'),
          Slider(
            value: _daysPerWeek.toDouble(),
            min: 2,
            max: 6,
            divisions: 4,
            activeColor: AppColors.primaryOf(context),
            onChanged: (val) {
              setState(() => _daysPerWeek = val.round());
            },
          ),
          if (_daysPerWeek == 2) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tập 2 buổi/tuần không đảm bảo hiệu quả (Khuyến nghị >= 3 buổi)',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          AppButton.primary(
            label: 'Tạo kế hoạch tập với AI',
            icon: Icons.auto_awesome_rounded,
            loading: state.isLoading,
            onPressed: () {
              ref.read(aiWorkoutPlannerProvider.notifier).generateWorkoutPlan(
                    level: _selectedLevel,
                    daysPerWeek: _daysPerWeek,
                  );
            },
          ),
          if (state.error != null) ...[
            const SizedBox(height: 14),
            Text(
              state.error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
          if (state.plan != null) ...[
            const SizedBox(height: 20),
            _buildWorkoutPlanResult(state.plan!),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkoutPlanResult(Map<String, dynamic> plan) {
    final planName = plan['plan_name'] ?? 'Lịch tập V-FIT AI';
    final goal = plan['goal'] ?? '';
    final note = plan['note'] ?? '';
    final schedule = plan['weekly_schedule'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryOf(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primaryOf(context).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                planName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              if (goal.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text('Mục tiêu: $goal', style: const TextStyle(fontSize: 12)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...schedule.entries.map((entry) {
          final dayKey = entry.key;
          final dayData = entry.value as Map<String, dynamic>? ?? {};
          final focus = dayData['focus'] ?? 'Nghỉ ngơi/Tự do';
          final warmUp = List<String>.from(dayData['warm_up'] ?? []);
          final mainWorkout = List<String>.from(dayData['main_workout'] ?? []);
          final coolDown = List<String>.from(dayData['cool_down'] ?? []);

          final formattedDayName = dayKey.replaceAll('_', ' ').toUpperCase();

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formattedDayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryOf(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          focus,
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  if (warmUp.isNotEmpty) ...[
                    _buildSubSectionTitle('Khởi động (Warm-up)'),
                    ...warmUp.map((item) => _buildBulletPoint(item)),
                    const SizedBox(height: 6),
                  ],
                  if (mainWorkout.isNotEmpty) ...[
                    _buildSubSectionTitle('Bài tập chính (Main workout)'),
                    ...mainWorkout.map((item) => _buildBulletPoint(item)),
                    const SizedBox(height: 6),
                  ],
                  if (coolDown.isNotEmpty) ...[
                    _buildSubSectionTitle('Hồi phục (Cool-down)'),
                    ...coolDown.map((item) => _buildBulletPoint(item)),
                  ],
                ],
              ),
            ),
          );
        }),
        if (note.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Lưu ý từ AI: $note',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ],
    );
  }

  // --- Helpers ---
  Widget _buildFormLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppColors.primaryOf(context).withValues(alpha: 0.2),
      checkmarkColor: AppColors.primaryOf(context),
      labelStyle: TextStyle(
        color: selected ? AppColors.primaryOf(context) : AppColors.textSecondaryOf(context),
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildSubSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 2.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
