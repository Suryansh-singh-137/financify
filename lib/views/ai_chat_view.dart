import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ai_cfo_service.dart';
import '../services/model_service.dart';
import '../theme/app_theme.dart';

class AIChatView extends StatefulWidget {
  const AIChatView({super.key});

  @override
  State<AIChatView> createState() => _AIChatViewState();
}

class _AIChatViewState extends State<AIChatView> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [];

  final _quickPrompts = [
    'Can I afford ₹5,000 headphones?',
    'Where am I overspending?',
    'Summarize my subscriptions',
    'How is my savings rate?',
    'What\'s my biggest expense?',
    'Am I on budget this month?',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage(
      isAI: true,
      text: '👋 Hello! I\'m your AI CFO.\n\nI can answer questions about your finances, help you understand your spending, and give you actionable advice — all offline on your device.\n\nWhat would you like to know?',
    ));
  }

  @override
  void dispose() {
    _inputController.dispose();
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

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _inputController.clear();

    setState(() {
      _messages.add(_ChatMessage(isAI: false, text: text));
      _messages.add(_ChatMessage(isAI: true, text: '', isLoading: true));
    });
    _scrollToBottom();

    final aiService = Provider.of<AICFOService>(context, listen: false);
    final response = await aiService.askQuestion(text);

    setState(() {
      final loading = _messages.lastWhere((m) => m.isLoading, orElse: () => _messages.last);
      loading.text = response;
      loading.isLoading = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final modelService = Provider.of<ModelService>(context);
    final aiService = Provider.of<AICFOService>(context);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.accentCyan, AppColors.accentViolet]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: Text('AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI CFO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  modelService.isLLMLoaded ? 'Online · On-device' : 'Model not loaded',
                  style: TextStyle(
                    fontSize: 10,
                    color: modelService.isLLMLoaded ? AppColors.accentGreen : AppColors.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (!modelService.isLLMLoaded)
            IconButton(
              icon: const Icon(Icons.download, color: AppColors.warning),
              tooltip: 'Load AI Model',
              onPressed: () => modelService.downloadAndLoadLLM(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Model not loaded banner
          if (!modelService.isLLMLoaded) _buildModelBanner(modelService),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _buildMessage(_messages[i]),
            ),
          ),

          // Quick prompts
          if (_messages.length <= 1) _buildQuickPrompts(),

          // Input bar
          _buildInputBar(aiService.isGenerating),
        ],
      ),
    );
  }

  Widget _buildModelBanner(ModelService modelService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.warning.withOpacity(0.12),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('AI model not loaded. Download to enable AI answers.', style: TextStyle(color: AppColors.warning, fontSize: 12)),
          ),
          if (!modelService.isLLMDownloading && !modelService.isLLMLoading)
            TextButton(
              onPressed: () => modelService.downloadAndLoadLLM(),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text('Load', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold)),
            )
          else if (modelService.isLLMDownloading)
            SizedBox(
              width: 60,
              child: LinearProgressIndicator(value: modelService.llmDownloadProgress / 100, color: AppColors.warning),
            ),
        ],
      ),
    );
  }

  Widget _buildMessage(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: msg.isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (msg.isAI) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, bottom: 0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.accentCyan, AppColors.accentViolet]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: Text('AI', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: msg.isAI ? AppColors.surfaceCard : AppColors.accentCyan,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(msg.isAI ? 4 : 18),
                  bottomRight: Radius.circular(msg.isAI ? 18 : 4),
                ),
              ),
              child: msg.isLoading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _dot(0), const SizedBox(width: 4),
                        _dot(1), const SizedBox(width: 4),
                        _dot(2),
                      ],
                    )
                  : Text(
                      msg.text,
                      style: TextStyle(
                        color: msg.isAI ? AppColors.textPrimary : AppColors.primaryDark,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.0),
      duration: Duration(milliseconds: 600 + index * 200),
      builder: (_, v, child) => Opacity(opacity: v, child: child),
      child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.textMuted, shape: BoxShape.circle)),
    );
  }

  Widget _buildQuickPrompts() {
    return Container(
      height: 42,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _quickPrompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => _sendMessage(_quickPrompts[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accentCyan.withOpacity(0.3)),
            ),
            child: Text(_quickPrompts[i], style: const TextStyle(color: AppColors.accentCyan, fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isGenerating) {
    return Container(
      padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: BoxDecoration(
        color: AppColors.primaryMid,
        border: Border(top: BorderSide(color: AppColors.textMuted.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: isGenerating ? null : _sendMessage,
              decoration: InputDecoration(
                hintText: 'Ask your CFO anything...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                fillColor: AppColors.surfaceCard,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isGenerating ? null : () => _sendMessage(_inputController.text),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: isGenerating
                    ? null
                    : const LinearGradient(colors: [AppColors.accentCyan, AppColors.accentViolet]),
                color: isGenerating ? AppColors.surfaceCard : null,
                shape: BoxShape.circle,
              ),
              child: isGenerating
                  ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                  : const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  bool isAI;
  String text;
  bool isLoading;

  _ChatMessage({required this.isAI, required this.text, this.isLoading = false});
}
