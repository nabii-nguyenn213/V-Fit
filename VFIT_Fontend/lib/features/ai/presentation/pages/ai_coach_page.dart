import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../auth/application/auth_controller.dart';
import '../providers/ai_coach_provider.dart';
import '../providers/ai_workout_planner_provider.dart';
import '../providers/ai_meal_planner_provider.dart';
import '../providers/ai_food_scanner_provider.dart';

class AiCoachPage extends ConsumerStatefulWidget {
  const AiCoachPage({super.key});

  @override
  ConsumerState<AiCoachPage> createState() => _AiCoachPageState();
}

class _AiCoachPageState extends ConsumerState<AiCoachPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Workout Planner form state
  String _selectedLevel = 'Beginner';
  int _daysPerWeek = 4;

  // Meal Planner form state
  int _mealsPerDay = 3;

  // Food Scanner form state
  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _portionController = TextEditingController(text: '1 phần');

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _foodNameController.dispose();
    _portionController.dispose();
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
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final isVip = user?.isVipActive == true;

    if (!isVip) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text(
            'V-FIT AI Workspace',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: Stack(
          children: [
            _buildBackgroundDecoration(),
            SafeArea(child: _buildVipGateScreen(context)),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          title: const Text(
            'V-FIT AI Workspace',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.primaryOf(context),
            labelColor: AppColors.primaryOf(context),
            unselectedLabelColor: AppColors.textSecondaryOf(context),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(icon: Icon(Icons.chat_bubble_outline_rounded), text: 'AI Coach'),
              Tab(icon: Icon(Icons.fitness_center_rounded), text: 'Lập lịch tập'),
              Tab(icon: Icon(Icons.restaurant_rounded), text: 'Thực đơn AI'),
              Tab(icon: Icon(Icons.search_rounded), text: 'Tính calo món'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Reset dữ liệu',
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Reset workspace?'),
                    content: const Text('Lịch sử chat và kế hoạch hiện tại sẽ được làm mới.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(aiCoachProvider.notifier).clearChat();
                          ref.read(aiWorkoutPlannerProvider.notifier).reset();
                          ref.read(aiMealPlannerProvider.notifier).reset();
                          ref.read(aiFoodScannerProvider.notifier).reset();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Reset',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildChatInterface(context),
            _buildWorkoutPlanner(context),
            _buildMealPlanner(context),
            _buildFoodScanner(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundDecoration() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVipGateScreen(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.shade400,
                      Colors.orange.shade700,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Khu vực V-FIT VIP AI',
                style: AppTypography.headerLargeFor(context).copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Mở khóa toàn bộ bộ công cụ AI: Nhận giáo án tập luyện cá nhân hóa, lên thực đơn dinh dưỡng chi tiết và trao đổi 24/7 với AI Coach.',
                style: AppTypography.bodyFor(context).copyWith(
                  color: AppColors.textSecondaryOf(context),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  color: Theme.of(context).cardColor.withValues(alpha: 0.5),
                  child: Column(
                    children: [
                      _buildBenefitRow(
                        context,
                        Icons.chat_bubble_outline_rounded,
                        'Hỏi đáp 24/7 với AI Coach',
                        'Giải đáp thắc mắc về kỹ thuật tập và dinh dưỡng.',
                      ),
                      const Divider(height: 24),
                      _buildBenefitRow(
                        context,
                        Icons.fitness_center_rounded,
                        'Lập lịch tập luyện cá nhân',
                        'Tự động thiết kế lịch tập dựa trên thể trạng của bạn.',
                      ),
                      const Divider(height: 24),
                      _buildBenefitRow(
                        context,
                        Icons.restaurant_rounded,
                        'Thực đơn ăn uống thông minh',
                        'AI phân chia calo, carb, protein, fat chuẩn gymer.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              AppButton.add(
                label: 'Nâng cấp lên VIP ngay',
                fullWidth: true,
                onPressed: () {
                  context.go('/profile');
                },
              ),
              const SizedBox(height: 16),
              AppButton.ghost(
                label: 'Quay lại',
                fullWidth: true,
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(
    BuildContext context,
    IconData icon,
    String title,
    String desc,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 26,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyFor(context).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: AppTypography.bodyFor(context).copyWith(
                  color: AppColors.textSecondaryOf(context),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- TAB 1: AI Coach ---
  Widget _buildChatInterface(BuildContext context) {
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.red.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    chatState.error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: chatState.messages.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: chatState.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatState.messages[index];
                    return _buildMessageBubble(context, message);
                  },
                ),
        ),
        if (chatState.isLoading)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'AI Coach đang suy nghĩ',
                        style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 12,
                        height: 12,
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
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          message.text as String,
          style: TextStyle(
            color: textColor,
            fontSize: 14.5,
            height: 1.4,
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
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _messageController,
                textInputAction: TextInputAction.send,
                onSubmitted: isLoading ? null : _handleSend,
                decoration: const InputDecoration(
                  hintText: 'Nhập câu hỏi...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
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

  // --- TAB 2: AI Workout Planner ---
  Widget _buildWorkoutPlanner(BuildContext context) {
    final state = ref.watch(aiWorkoutPlannerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Lập lịch tập cá nhân hóa',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Hệ thống AI sẽ tự động phân tích độ tuổi, cân nặng, chiều cao của bạn để tạo ra lịch trình phù hợp.',
            style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13),
          ),
          const SizedBox(height: 20),
          _buildFormLabel('Trình độ tập luyện'),
          const SizedBox(height: 8),
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
          const SizedBox(height: 16),
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
          const SizedBox(height: 20),
          AppButton.primary(
            label: 'Tạo kế hoạch tập luyện',
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
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],
          if (state.plan != null) ...[
            const SizedBox(height: 24),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryOf(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryOf(context).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                planName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (goal.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Mục tiêu: $goal', style: const TextStyle(fontSize: 13)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...schedule.entries.map((entry) {
          final dayKey = entry.key;
          final dayData = entry.value as Map<String, dynamic>? ?? {};
          final focus = dayData['focus'] ?? 'Nghỉ ngơi/Tự do';
          final warmUp = List<String>.from(dayData['warm_up'] ?? []);
          final mainWorkout = List<String>.from(dayData['main_workout'] ?? []);
          final coolDown = List<String>.from(dayData['cool_down'] ?? []);

          final formattedDayName = dayKey.replaceAll('_', ' ').toUpperCase();

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              padding: const EdgeInsets.all(16),
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
                      Text(
                        focus,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  if (warmUp.isNotEmpty) ...[
                    _buildSubSectionTitle('Khởi động (Warm-up)'),
                    ...warmUp.map((item) => _buildBulletPoint(item)),
                    const SizedBox(height: 10),
                  ],
                  if (mainWorkout.isNotEmpty) ...[
                    _buildSubSectionTitle('Bài tập chính (Main workout)'),
                    ...mainWorkout.map((item) => _buildBulletPoint(item)),
                    const SizedBox(height: 10),
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Lưu ý từ AI: $note',
              style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ],
    );
  }

  // --- TAB 3: AI Meal Planner ---
  Widget _buildMealPlanner(BuildContext context) {
    final state = ref.watch(aiMealPlannerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Lên thực đơn dinh dưỡng',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'AI sẽ tính toán Calo hàng ngày cần thiết dựa trên chiều cao, cân nặng và đề xuất bữa ăn phù hợp.',
            style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13),
          ),
          const SizedBox(height: 20),
          _buildFormLabel('Số bữa ăn mong muốn trong ngày: $_mealsPerDay bữa'),
          Slider(
            value: _mealsPerDay.toDouble(),
            min: 2,
            max: 5,
            divisions: 3,
            activeColor: AppColors.primaryOf(context),
            onChanged: (val) {
              setState(() => _mealsPerDay = val.round());
            },
          ),
          const SizedBox(height: 20),
          AppButton.primary(
            label: 'Tạo thực đơn dinh dưỡng',
            icon: Icons.auto_awesome_rounded,
            loading: state.isLoading,
            onPressed: () {
              ref.read(aiMealPlannerProvider.notifier).generateMealPlan(
                    mealsPerDay: _mealsPerDay,
                  );
            },
          ),
          if (state.error != null) ...[
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],
          if (state.plan != null) ...[
            const SizedBox(height: 24),
            _buildMealPlanResult(state.plan!),
          ],
        ],
      ),
    );
  }

  Widget _buildMealPlanResult(Map<String, dynamic> plan) {
    final dailyCal = plan['daily_calories'] ?? 0;
    final protein = plan['protein_g'] ?? 0;
    final carbs = plan['carbs_g'] ?? 0;
    final fat = plan['fat_g'] ?? 0;
    final meals = plan['meal_plan'] as Map<String, dynamic>? ?? {};
    final note = plan['note'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Text('Khuyến nghị hàng ngày', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                '$dailyCal kcal',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMacroColumn('Protein', '${protein}g', Colors.orange),
                  _buildMacroColumn('Carbs', '${carbs}g', Colors.blue),
                  _buildMacroColumn('Fat', '${fat}g', Colors.red),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...meals.entries.map((entry) {
          final mealName = entry.key;
          final mealItems = List<String>.from(entry.value ?? []);

          if (mealItems.isEmpty) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mealName.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Divider(height: 16),
                  ...mealItems.map((item) => _buildBulletPoint(item)),
                ],
              ),
            ),
          );
        }),
        if (note.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Lời khuyên dinh dưỡng: $note',
              style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMacroColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  // --- TAB 4: AI Food Scanner ---
  Widget _buildFoodScanner(BuildContext context) {
    final state = ref.watch(aiFoodScannerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Phân tích món ăn bằng văn bản',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhập tên món ăn và khẩu phần ước lượng, AI của V-FIT sẽ ước tính các chỉ số dinh dưỡng (Protein, Carbs, Fat) và tổng lượng Calo.',
            style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _foodNameController,
            decoration: const InputDecoration(
              labelText: 'Tên món ăn',
              hintText: 'ví dụ: Cơm rang dưa bò, Phở gà, Ức gà...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _portionController,
            decoration: const InputDecoration(
              labelText: 'Khẩu phần',
              hintText: 'ví dụ: 1 đĩa, 1 tô, 200g...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          AppButton.primary(
            label: 'Ước lượng dinh dưỡng',
            icon: Icons.search_rounded,
            loading: state.isLoading,
            onPressed: () {
              if (_foodNameController.text.trim().isEmpty) return;
              ref.read(aiFoodScannerProvider.notifier).estimateFood(
                    foodName: _foodNameController.text.trim(),
                    portion: _portionController.text.trim(),
                  );
            },
          ),
          if (state.error != null) ...[
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],
          if (state.result != null) ...[
            const SizedBox(height: 24),
            _buildFoodScannerResult(state.result!),
          ],
        ],
      ),
    );
  }

  Widget _buildFoodScannerResult(Map<String, dynamic> result) {
    final foodName = result['food_name'] ?? '';
    final portion = result['portion'] ?? '';
    final cal = result['total_calories'] ?? 0;
    final protein = result['protein_g'] ?? 0;
    final carbs = result['carbs_g'] ?? 0;
    final fat = result['fat_g'] ?? 0;
    final confidence = (result['confidence'] ?? 1.0) * 100;
    final note = result['note'] ?? '';

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    foodName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  'Tin cậy: ${confidence.toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ],
            ),
            if (portion.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Khẩu phần: $portion', style: const TextStyle(fontSize: 13)),
            ],
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$cal',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                      const Text('Kcal', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${protein}g',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                      const Text('Đạm', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${carbs}g',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const Text('Carb', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${fat}g',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      const Text('Béo', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            if (note.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                'Ghi chú dinh dưỡng: $note',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- Helpers ---
  Widget _buildFormLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
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
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
