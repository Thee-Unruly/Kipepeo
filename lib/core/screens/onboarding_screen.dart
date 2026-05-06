import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_service.dart';

/// Onboarding screen for new Kipepeo Daily users.
/// Asks for:
/// 1. Opening capital for today
/// 2. SMS permission grant
/// 3. Basic business info (optional)
class OnboardingScreen extends StatefulWidget {
  final User user;
  final VoidCallback onComplete;

  const OnboardingScreen({
    super.key,
    required this.user,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final db = DatabaseService();
  final capitalCtrl = TextEditingController();
  bool _smsPermissionGranted = false;
  int _currentStep =
      0; // 0: Intro, 1: Opening Capital, 2: SMS Permission, 3: Done

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Welcome to Kipepeo Daily'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step indicator
            _buildStepIndicator(),
            const SizedBox(height: 32),

            // Content based on step
            if (_currentStep == 0) _buildIntroStep(),
            if (_currentStep == 1) _buildCapitalStep(),
            if (_currentStep == 2) _buildSmsPermissionStep(),
            if (_currentStep == 3) _buildCompleteStep(),

            const SizedBox(height: 40),

            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (i) {
        return Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: i <= _currentStep ? Colors.teal : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: i <= _currentStep ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ['Start', 'Capital', 'SMS', 'Done'][i],
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        );
      }),
    );
  }

  Widget _buildIntroStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🦋 Your Daily Business Companion',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          'Kipepeo Daily helps you track your daily sales and understand how much profit you can safely spend.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        _buildFeaturePoint('📊 Real-time sales tracking from M-Pesa'),
        _buildFeaturePoint('💡 Smart insights on your spending'),
        _buildFeaturePoint('🔒 Your data stays on your phone'),
        _buildFeaturePoint('📈 Build your 30-day business passport'),
      ],
    );
  }

  Widget _buildCapitalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How much capital do you have today?',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'This is the money you use to restock. We\'ll protect this amount in your "Red Zone" so you don\'t accidentally spend it.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: capitalCtrl,
          decoration: InputDecoration(
            labelText: 'Opening Capital (KES)',
            prefixText: 'KES ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: 'e.g., 5000',
          ),
          keyboardType: TextInputType.number,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border.all(color: Colors.blue[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '💡 Tip: If you\'re not sure, think about how much you typically spend restocking each day.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _buildSmsPermissionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Allow SMS access',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'Kipepeo reads your M-Pesa messages to automatically track your sales. We ONLY read messages from M-Pesa.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            border: Border.all(color: Colors.green[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🔒 Privacy First',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '• Your messages never leave your phone\n'
                '• We don\'t store personal texts\n'
                '• You see exactly which messages we read',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.green[800]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              // In real app, request SMS permission via permission_handler
              // For now, just mark as granted
              setState(() => _smsPermissionGranted = true);
            },
            icon: const Icon(Icons.check_circle),
            label: Text(
              _smsPermissionGranted
                  ? 'Permission Granted ✓'
                  : 'Grant Permission',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _smsPermissionGranted
                  ? Colors.green
                  : Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, size: 80, color: Colors.teal),
        const SizedBox(height: 24),
        Text(
          'You\'re all set! 🎉',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Your Kipepeo Daily dashboard is ready. Check back each day to track your sales and manage your cash flow.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            border: Border.all(color: Colors.amber[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⭐ Pro Tip',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'After 30 days of tracking, you\'ll unlock your Business Passport to show lenders how serious you are.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.amber[800]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturePoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back button
        if (_currentStep > 0)
          OutlinedButton(
            onPressed: () => setState(() => _currentStep--),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            child: const Text('← Back'),
          ),
        const Spacer(),

        // Next/Complete button
        ElevatedButton(
          onPressed: _canProceed() ? _handleNextStep : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          child: Text(_currentStep == 3 ? 'Start Using Kipepeo →' : 'Next →'),
        ),
      ],
    );
  }

  bool _canProceed() {
    if (_currentStep == 0) return true; // Intro always valid
    if (_currentStep == 1)
      return capitalCtrl.text.isNotEmpty; // Capital must be entered
    if (_currentStep == 2)
      return _smsPermissionGranted; // Permission must be granted
    if (_currentStep == 3) return true; // Done step
    return false;
  }

  Future<void> _handleNextStep() async {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      // Onboarding complete: save opening capital and navigate
      final capital = double.tryParse(capitalCtrl.text) ?? 0;
      // You can save this to SharedPreferences or database if needed
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    capitalCtrl.dispose();
    super.dispose();
  }
}
