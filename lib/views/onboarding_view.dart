import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/demo_data_generator.dart';
import 'main_shell.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _loadingDemo = false;

  final _pages = const [
    _OnboardPage(
      emoji: '🔒',
      title: 'Privacy First',
      subtitle: 'Accounts, transactions & AI reasoning stay on your device.\nNo cloud. No tracking. No compromise.',
      color: Color(0xFF6366F1),
    ),
    _OnboardPage(
      emoji: '🤖',
      title: 'On-Device AI CFO',
      subtitle: 'Ask anything about your finances.\nOur AI runs 100% offline using RunAnywhere — your data never leaves your phone.',
      color: Color(0xFF10B981),
    ),
    _OnboardPage(
      emoji: '📊',
      title: 'Smart Insights',
      subtitle: 'Automatic subscription detection, budgets, safe-to-spend & spending trend insights — all local.',
      color: Color(0xFFF59E0B),
    ),
  ];

  Future<void> _loadDemo() async {
    setState(() => _loadingDemo = true);
    try {
      await DemoDataGenerator().generateDemoData();
    } finally {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    }
  }

  void _skip() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _skip,
                child: Text('Skip', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _pages[i],
              ),
            ),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i ? _pages[i].color : AppColors.textMuted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _currentPage < _pages.length - 1
                  ? ElevatedButton(
                      onPressed: () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].color,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    )
                  : Column(
                      children: [
                        ElevatedButton(
                          onPressed: _loadingDemo ? null : _loadDemo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentGreen,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _loadingDemo
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.auto_awesome, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Load Demo & Explore', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _skip,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            side: BorderSide(color: AppColors.textMuted),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text('Start Fresh', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;

  const _OnboardPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 56))),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
