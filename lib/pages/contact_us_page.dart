import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  final Color bgColor = const Color(0xFFF2FBFA);
  final Color textColor = const Color(0xFF5A3B24);
  final Color subTextColor = const Color(0xFF9E8E81);
  final Color cardColor = const Color(0xFFF6EFE6);
  final Color iconBgColor = const Color(0xFF88C5C4);

  // Launches external URLs
  Future<void> _launchURL(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open $urlString')));
      }
    }
  }

  // Displays profile options
  void _showProfileOptions(
    BuildContext context,
    String platform,
    List<Map<String, String>> options,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Select $platform Profile',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((option) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  title: Text(
                    option['name']!,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  trailing: Icon(
                    Icons.open_in_new,
                    color: iconBgColor,
                    size: 18,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _launchURL(context, option['url']!);
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: subTextColor,
                  size: 18,
                ),
                label: Text(
                  'My Profile',
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Contact Us',
                style: TextStyle(
                  color: textColor,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Don't hesitate to contact us whether you have a suggestion on our improvement, a complain to discuss or an issue to solve",
                style: TextStyle(
                  color: textColor.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 25),

              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildContactCard(
                        icon: Icons.phone_in_talk,
                        title: 'Call us',
                        details: '082-455-0533\n065-960-4322',
                        subtext: 'Our team is on the line\nMon - Fri 9-17',
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildContactCard(
                        icon: Icons.email_outlined,
                        title: 'Email us',
                        details:
                            'kittamette.mua@student.mahidol.ac.th\nboonyanuch.pho@student.mahidol.ac.th',
                        subtext: 'Our team is online\nMon - Fri 9-17',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              Text(
                'Contact us in Social Media',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),

              _buildSocialCard(
                icon: Icons.camera_alt_outlined,
                title: 'Instagram',
                onTap: () => _showProfileOptions(context, 'Instagram', [
                  {
                    'name': 'sprayingoneifell',
                    'url': 'https://www.instagram.com/sprayingoneiffel/',
                  },
                  {
                    'name': 'littleaomam.m',
                    'url': 'https://www.instagram.com/littleaomam.m/',
                  },
                ]),
              ),
              _buildSocialCard(
                icon: Icons.facebook,
                title: 'Facebook',
                onTap: () => _showProfileOptions(context, 'Facebook', [
                  {
                    'name': 'Kittamette Muangdee',
                    'url':
                        'https://www.facebook.com/kittamette.muangdee?locale=th_TH',
                  },
                  {
                    'name': 'Boonyanuch Phongpheaw',
                    'url':
                        'https://www.facebook.com/boonyanuch.phxngpheaw.1?locale=th_TH',
                  },
                ]),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String details,
    required String subtext,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              details,
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor, fontSize: 10),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtext,
            textAlign: TextAlign.center,
            style: TextStyle(color: subTextColor, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5DDD5), width: 1.5),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
          child: Center(child: Icon(icon, color: Colors.white, size: 30)),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        trailing: Icon(Icons.ios_share, color: subTextColor, size: 20),
      ),
    );
  }
}
