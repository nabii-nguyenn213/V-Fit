import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_button.dart';

class FlashyVipRequiredModal extends StatelessWidget {
  const FlashyVipRequiredModal({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark 
                    ? [const Color(0xFF1E1B4B), const Color(0xFF311042)]
                    : [Colors.white, const Color(0xFFFAF5FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                width: 2,
                color: const Color(0xFFE81CFF).withOpacity(0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE81CFF).withOpacity(0.25),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: const Color(0xFF06B6D4).withOpacity(0.15),
                  blurRadius: 15,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFE81CFF), Color(0xFF06B6D4), Color(0xFFD9F920)],
                  ).createShader(bounds),
                  child: Text(
                    'V-FIT VIP MEMBER',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: const Color(0xFFE81CFF).withOpacity(0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Mở Khóa Giải Pháp AI Cao Cấp',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tính năng thiết lập lịch tập và thực đơn dinh dưỡng tự động 7 ngày tối ưu riêng theo thể trạng chỉ dành riêng cho hội viên VIP.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFFD4D4D8) : const Color(0xFF52525B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                _buildVipFeatureRow(
                  context, 
                  Icons.auto_awesome_rounded, 
                  'AI Meal Planner & Trainer', 
                  'Tự động lên thực đơn và giáo án 7 ngày cân bằng Macro.',
                  const Color(0xFFE81CFF),
                ),
                const SizedBox(height: 12),
                _buildVipFeatureRow(
                  context, 
                  Icons.center_focus_strong_rounded, 
                  'AI Body Scan', 
                  'Quét cơ thể qua camera để tính lượng mỡ thừa.',
                  const Color(0xFF06B6D4),
                ),
                const SizedBox(height: 12),
                _buildVipFeatureRow(
                  context, 
                  Icons.bolt_rounded, 
                  'Tối Ưu Calo Tùy Chọn', 
                  'Gợi ý dinh dưỡng nâng cao theo lịch tập luyện.',
                  const Color(0xFFD9F920),
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE81CFF), Color(0xFF06B6D4)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE81CFF).withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go('/premium');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.workspace_premium_rounded, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'NÂNG CẤP VIP NGAY',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Để sau',
                    style: TextStyle(
                      color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -36,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                size: 38,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVipFeatureRow(
    BuildContext context, 
    IconData icon, 
    String title, 
    String subtitle,
    Color accentColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: accentColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
