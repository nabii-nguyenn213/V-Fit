import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../auth/application/auth_controller.dart';
import '../providers/ai_coach_provider.dart';
import '../providers/ai_workout_planner_provider.dart';
import '../providers/ai_meal_planner_provider.dart';
import '../providers/ai_food_scanner_provider.dart';

class AiCoachPage extends ConsumerStatefulWidget {
  final int initialTab;
  const AiCoachPage({super.key, this.initialTab = 0});

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

    return DefaultTabController(
      length: 4,
      initialIndex: widget.initialTab,
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
            tabs: [
              const Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    SizedBox(width: 6),
                    Text('AI Coach'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.fitness_center_rounded, size: 18),
                    const SizedBox(width: 6),
                    const Text('Lập lịch tập'),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFB03A), Color(0xFFFF7E00)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Text(
                        'VIP',
                        style: TextStyle(
                          fontSize: 8.5,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.restaurant_rounded, size: 18),
                    const SizedBox(width: 6),
                    const Text('Thực đơn AI'),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFB03A), Color(0xFFFF7E00)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Text(
                        'VIP',
                        style: TextStyle(
                          fontSize: 8.5,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_rounded, size: 18),
                    SizedBox(width: 6),
                    Text('Tính calo món'),
                  ],
                ),
              ),
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


  Widget _buildVipBenefitItem(BuildContext context, IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFB03A).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.orange.shade700, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: TextStyle(
                  color: AppColors.textSecondaryOf(context),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showVipUpgradeDialog(BuildContext pageContext) {
    final isDark = AppColors.isDark(pageContext);
    showDialog<void>(
      context: pageContext,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFB03A),
                          Color(0xFFFF7E00),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB03A).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFB03A).withValues(alpha: 0.3), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium_outlined, color: Colors.amber.shade700, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'V-FIT VIP MEMBER',
                          style: TextStyle(
                            color: Colors.amber.shade800,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nâng Cấp Trải Nghiệm VIP',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tính năng Lập lịch tập AI và Thực đơn Dinh dưỡng AI chỉ dành cho thành viên VIP.',
                    style: TextStyle(
                      color: AppColors.textSecondaryOf(context),
                      height: 1.5,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surface1 : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? _ZincColors.shade800 : _ZincColors.shade200,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildVipBenefitItem(
                          context,
                          Icons.auto_awesome_rounded,
                          'Giải Pháp Cá Nhân Hóa AI',
                          'Tự động thiết kế lịch trình tập và thực đơn theo chỉ số cơ thể riêng.',
                        ),
                        const Divider(height: 20, thickness: 0.8),
                        _buildVipBenefitItem(
                          context,
                          Icons.trending_up_rounded,
                          'Bứt Phá Kết Quả Tập Luyện',
                          'Tối ưu hóa tỉ lệ dinh dưỡng đa lượng để đạt mục tiêu nhanh hơn.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        pageContext.go('/profile');
                      },
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFFB03A),
                              Color(0xFFFF7E00),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'NÂNG CẤP VIP NGAY',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
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
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.blue.shade400, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Trò chuyện với AI Coach là tính năng MIỄN PHÍ dành cho mọi thành viên V-FIT.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
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
          ),
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
    final isDark = AppColors.isDark(context);
    final auth = ref.watch(authControllerProvider);
    final isVip = auth.user?.isVipActive == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.teal.shade900.withValues(alpha: 0.4), Colors.cyan.shade900.withValues(alpha: 0.2)]
                    : [Colors.teal.shade50, Colors.cyan.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.teal.shade800.withValues(alpha: 0.5) : Colors.teal.shade100,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOf(context).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.auto_awesome_rounded, color: AppColors.primaryOf(context), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lập lịch tập luyện VIP AI',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cá nhân hóa tối đa dựa trên chỉ số cơ thể của riêng bạn.',
                        style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface1 : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? _ZincColors.shade800 : _ZincColors.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFormLabel('Trình độ hiện tại'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildDifficultyCard(
                      'Mới tập',
                      'Beginner',
                      'Dưới 6 tháng',
                      Icons.fitness_center_rounded,
                      Colors.teal.shade400,
                    ),
                    const SizedBox(width: 10),
                    _buildDifficultyCard(
                      'Trung bình',
                      'Intermediate',
                      'Có nền tảng',
                      Icons.flash_on_rounded,
                      Colors.cyan.shade400,
                    ),
                    const SizedBox(width: 10),
                    _buildDifficultyCard(
                      'Nâng cao',
                      'Advanced',
                      'Kinh nghiệm',
                      Icons.local_fire_department_rounded,
                      Colors.orange.shade400,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildFormLabel('Số ngày tập mong muốn'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surface2 : _ZincColors.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tập luyện:',
                            style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13),
                          ),
                          Text(
                            '$_daysPerWeek ngày / tuần',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: AppColors.primaryOf(context),
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.primaryOf(context),
                          inactiveTrackColor: AppColors.primaryOf(context).withValues(alpha: 0.15),
                          thumbColor: AppColors.primaryOf(context),
                          overlayColor: AppColors.primaryOf(context).withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          value: _daysPerWeek.toDouble(),
                          min: 2,
                          max: 6,
                          divisions: 4,
                          onChanged: (val) {
                            setState(() => _daysPerWeek = val.round());
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryOf(context).withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: state.isLoading
                        ? null
                        : () {
                            if (!isVip) {
                              _showVipUpgradeDialog(context);
                            } else {
                              ref.read(aiWorkoutPlannerProvider.notifier).generateWorkoutPlan(
                                    level: _selectedLevel,
                                    daysPerWeek: _daysPerWeek,
                                  );
                            }
                          },
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryOf(context),
                            AppColors.primaryOf(context).withBlue(250),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: state.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    'THIẾT KẾ GIÁO ÁN TẬP LUYỆN',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (state.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
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

  Widget _buildDifficultyCard(String label, String value, String desc, IconData icon, Color activeColor) {
    final isSelected = _selectedLevel == value;
    final isDark = AppColors.isDark(context);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedLevel = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.12)
                : (isDark ? AppColors.surface2 : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? activeColor : (isDark ? _ZincColors.shade800 : _ZincColors.shade200),
              width: isSelected ? 2 : 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? activeColor : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected ? activeColor : AppColors.textPrimaryOf(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondaryOf(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutPlanResult(Map<String, dynamic> plan) {
    final planName = plan['plan_name'] ?? 'Lịch tập V-FIT AI';
    final goal = plan['goal'] ?? '';
    final note = plan['note'] ?? '';
    final schedule = plan['weekly_schedule'] as Map<String, dynamic>? ?? {};
    final isDark = AppColors.isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFB03A).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFB03A).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.workspace_premium, color: Color(0xFFFFB03A), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      planName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              if (goal.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Mục tiêu: $goal',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryOf(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
          final isRest = focus.toLowerCase().contains('nghỉ') || focus.toLowerCase() == 'nghi';

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surface1 : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isRest
                      ? (isDark ? _ZincColors.shade900 : _ZincColors.shade100)
                      : (isDark ? Colors.teal.shade900.withValues(alpha: 0.5) : Colors.teal.shade100),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isRest
                          ? (isDark ? _ZincColors.shade900.withValues(alpha: 0.5) : _ZincColors.shade50)
                          : (isDark ? Colors.teal.shade900.withValues(alpha: 0.2) : Colors.teal.shade50.withValues(alpha: 0.5)),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formattedDayName,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: isRest ? Colors.grey : AppColors.primaryOf(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isRest
                                  ? Colors.grey.withValues(alpha: 0.15)
                                  : AppColors.primaryOf(context).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              focus,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isRest ? Colors.grey : AppColors.primaryOf(context),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 0.8),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isRest)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                children: [
                                  Icon(Icons.hotel_rounded, size: 40, color: _ZincColors.shade400),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Hôm nay là ngày nghỉ ngơi phục hồi cơ bắp.',
                                    style: TextStyle(
                                      color: AppColors.textSecondaryOf(context),
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (!isRest) ...[
                          if (warmUp.isNotEmpty) ...[
                            _buildSubSectionTitle('Khởi động (Warm-up)'),
                            const SizedBox(height: 6),
                            ...warmUp.map((item) => _buildBulletPoint(item)),
                            const SizedBox(height: 16),
                          ],
                          if (mainWorkout.isNotEmpty) ...[
                            _buildSubSectionTitle('Bài tập chính (Main workout)'),
                            const SizedBox(height: 6),
                            ...mainWorkout.map((item) => _buildBulletPoint(item)),
                            const SizedBox(height: 16),
                          ],
                          if (coolDown.isNotEmpty) ...[
                            _buildSubSectionTitle('Hồi phục (Cool-down)'),
                            const SizedBox(height: 6),
                            ...coolDown.map((item) => _buildBulletPoint(item)),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        if (note.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface1 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? _ZincColors.shade800 : _ZincColors.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.tips_and_updates_rounded, color: Colors.amber.shade600, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lời khuyên từ AI Coach',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        note,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.5,
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // --- TAB 3: AI Meal Planner ---
  Widget _buildMealPlanner(BuildContext context) {
    final state = ref.watch(aiMealPlannerProvider);
    final isDark = AppColors.isDark(context);
    final auth = ref.watch(authControllerProvider);
    final isVip = auth.user?.isVipActive == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.orange.shade900.withValues(alpha: 0.4), Colors.amber.shade900.withValues(alpha: 0.2)]
                    : [Colors.orange.shade50, Colors.amber.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.orange.shade800.withValues(alpha: 0.5) : Colors.orange.shade100,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.restaurant_rounded, color: Colors.orange, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thực đơn Dinh dưỡng VIP AI',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tính toán calo chính xác cho từng mục tiêu của bạn.',
                        style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface1 : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? _ZincColors.shade800 : _ZincColors.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFormLabel('Số bữa ăn trong ngày'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surface2 : _ZincColors.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tần suất:',
                            style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13),
                          ),
                          Text(
                            '$_mealsPerDay bữa / ngày',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.orange,
                          inactiveTrackColor: Colors.orange.withValues(alpha: 0.15),
                          thumbColor: Colors.orange,
                          overlayColor: Colors.orange.withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          value: _mealsPerDay.toDouble(),
                          min: 2,
                          max: 5,
                          divisions: 3,
                          onChanged: (val) {
                            setState(() => _mealsPerDay = val.round());
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: state.isLoading
                        ? null
                        : () {
                            if (!isVip) {
                              _showVipUpgradeDialog(context);
                            } else {
                              ref.read(aiMealPlannerProvider.notifier).generateMealPlan(
                                    mealsPerDay: _mealsPerDay,
                                  );
                            }
                          },
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Colors.orange,
                            Colors.amber,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: state.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    'LÊN THỰC ĐƠN DINH DƯỠNG AI',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (state.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
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
    final isDark = AppColors.isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surface1 : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? _ZincColors.shade800 : _ZincColors.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text('Khuyến nghị Dinh dưỡng Hàng ngày', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 12),
              Text(
                '$dailyCal Kcal',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.orange),
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),
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
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surface1 : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? _ZincColors.shade800 : _ZincColors.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? _ZincColors.shade900.withValues(alpha: 0.5) : _ZincColors.shade50,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Text(
                      mealName.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.orange),
                    ),
                  ),
                  const Divider(height: 1, thickness: 0.8),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: mealItems.map((item) => _buildBulletPoint(item)).toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        if (note.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface1 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? _ZincColors.shade800 : _ZincColors.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.tips_and_updates_rounded, color: Colors.amber.shade600, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lời khuyên Dinh dưỡng',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        note,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.5,
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline_rounded, color: AppColors.primaryOf(context), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZincColors {
  static const Color shade50 = Color(0xFFFAFAFA);
  static const Color shade100 = Color(0xFFF4F4F5);
  static const Color shade200 = Color(0xFFE4E4E7);
  static const Color shade400 = Color(0xFFA1A1AA);
  static const Color shade800 = Color(0xFF27272A);
  static const Color shade900 = Color(0xFF18181B);
}


