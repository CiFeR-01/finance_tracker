
import 'package:flutter/material.dart';

class PrivacyNoticePage extends StatelessWidget {
  const PrivacyNoticePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Notice'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text(
            'How Finance Tracker handles your information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),

          _NoticeSection(
            title: '1. Information We Collect',
            details:
            'Finance Tracker uses your email address, '
                'name, personal tax profile, income records, '
                'expense records and any receipt or proof '
                'images you choose to add.',
          ),

          _NoticeSection(
            title: '2. Why We Use Your Information',
            details:
            'Your information is used to manage your '
                'financial records, show income and expense '
                'summaries, and estimate Malaysian tax relief. '
                'Your email is also used for account login '
                'and password reset.',
          ),

          _NoticeSection(
            title: '3. Data Storage',
            details:
            'Firebase Authentication is used for account '
                'login. Cloud Firestore stores your profile '
                'and financial records. Receipt and proof '
                'images are saved in the app documents folder '
                'on your device. The saved file path may also '
                'be included in your financial record.',
          ),

          _NoticeSection(
            title: '4. Reports and Sharing',
            details:
            'Finance Tracker allows you to export financial '
                'reports and receipt records. These files may '
                'contain personal and financial information. '
                'Please check the files carefully before saving '
                'or sharing them with other people or apps.',
          ),

          _NoticeSection(
            title: '5. Privacy Requests',
            details:
            'The current version does not provide an '
                'in-app account deletion or personal data '
                'request feature. A contact method for '
                'privacy requests must be provided before '
                'the app is released to real users.',
          ),

          _NoticeSection(
            title: '6. Protecting Your Account',
            details:
            'Use a strong and unique password. Keep your '
                'login information private and protect your '
                'mobile device. Be careful when sharing '
                'financial reports or receipt images.',
          ),

          SizedBox(height: 8),

          Text(
            'This notice describes the current student '
                'project version. It must be reviewed and '
                'completed before the app is released '
                'to real users.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _NoticeSection extends StatelessWidget {
  final String title;
  final String details;

  const _NoticeSection({
    required this.title,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(details),
        ],
      ),
    );
  }
}
