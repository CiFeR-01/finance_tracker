
import 'package:flutter/material.dart';

class SecurityTipsPage extends StatelessWidget {
  const SecurityTipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Tips'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SecurityTip(
            icon: Icons.password_rounded,
            title: 'Use a Strong Password',
            description:
            'Use a unique password that you do not use '
                'for other accounts. Avoid sharing your '
                'password with anyone.',
          ),

          _SecurityTip(
            icon: Icons.lock_outline_rounded,
            title: 'Protect Your Phone',
            description:
            'Turn on a screen lock to prevent other '
                'people from easily accessing your '
                'personal information.',
          ),

          _SecurityTip(
            icon: Icons.person_off_outlined,
            title: 'Keep Login Details Private',
            description:
            'Do not share your password or password '
                'reset link with others. Always keep '
                'your account information private.',
          ),

          _SecurityTip(
            icon: Icons.logout_rounded,
            title: 'Be Careful on Shared Devices',
            description:
            'Avoid using Finance Tracker on shared '
                'devices. If needed, log out after use. '
                'Remember that saved or exported files '
                'may still remain on the device.',
          ),

          _SecurityTip(
            icon: Icons.share_outlined,
            title: 'Check Before Sharing',
            description:
            'Financial reports and receipts may contain '
                'personal information. Check the files '
                'carefully before sharing them with '
                'other people or apps.',
          ),
        ],
      ),
    );
  }
}

class _SecurityTip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _SecurityTip({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(title),
        subtitle: Text(description),
        isThreeLine: true,
      ),
    );
  }
}
