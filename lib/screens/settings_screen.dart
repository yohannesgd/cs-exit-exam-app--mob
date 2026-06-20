import 'package:cs_exit_exam_app/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../services/database_helper.dart';

import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _vibrationEnabled = true;
  bool _soundEnabled = true;
  bool _showExplanations = true;
  bool _lightningRoundEnabled = false;
  int _questionOrder = 0; // 0: Random, 1: Sequential
  bool _shuffleQuestions = true;
  bool _shuffleOptions = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
      _soundEnabled = prefs.getBool('soundEnabled') ?? true;
      _showExplanations = prefs.getBool('showExplanations') ?? true;
      _lightningRoundEnabled = prefs.getBool('lightningRoundEnabled') ?? false;
      _questionOrder = prefs.getInt('questionOrder') ?? 0;
      _shuffleQuestions = prefs.getBool('shuffleQuestions') ?? true;
      _shuffleOptions = prefs.getBool('shuffleOptions') ?? true;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    }
  }

  Future<void> _resetProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Progress?'),
        content: const Text(
          'This will delete all exam results and reset your settings. '
          'This action cannot be undone.',
       ),
       actions: [
         TextButton(
           onPressed: () => Navigator.pop(context, false),
           child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Reset All',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Clear database
        await DatabaseHelper.clearAllResults();
      
        // Clear shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      
        // Reset local state
        setState(() {
          _vibrationEnabled = true;
          _soundEnabled = true;
          _showExplanations = true;
          _questionOrder = 0;
          _shuffleQuestions = true;
         // _lightningRoundEnabled = false;
          _shuffleOptions = true;
        });

        if (!mounted) return;
      
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All progress has been reset'),
            backgroundColor: Colors.green,
          ),
        );
      
        // ✅ Navigate back to home and refresh
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error resetting: $e'),
              backgroundColor: Colors.red,
            ),
           );
          }
        }
      }

      void _showAppInfo() {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('About CS Exit Exam App'),
            content: const SingleChildScrollView(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ethiopian Computer Science Exit Exam Preparation',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Version 1.0.0'),
                  Divider(),
                  Text('FREE VERSION:'),
                  Text('• 13000 questions across 29 subjects'),
                  Text('• Basic analytics & achievements'),
                  SizedBox(height: 8),
                  //Text('• 300+ advanced practice questions (6 bundles)'),
                  //Text('• 3 full-length exam simulators (100 questions each)'),
                  //Text('• Previous years\' exit exams'),
                  Text('• Detailed performance analytics'),
                  //Text('• PDF answer sheets'),
                  Text('• No ads'),
                  SizedBox(height: 8),
                  Text('Developed by: Yohannes Gurmu', style: TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
      @override
      Widget build(BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return ListView(
                children: [
                  // Appearance Section
                  _buildSectionHeader('Appearance'),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Use System Theme'),
                          subtitle: const Text('Follow device theme settings'),
                          value: themeProvider.useSystemTheme,
                          onChanged: (value) {
                            themeProvider.setUseSystemTheme(value);
                          },
                          secondary: const Icon(Icons.phone_android),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Dark Mode'),
                          subtitle: const Text('Enable dark theme'),
                          value: themeProvider.isDarkMode,
                          onChanged: themeProvider.useSystemTheme 
                          ? null
                          : (value) {
                            themeProvider.toggleTheme(value);
                          },
                          secondary: const Icon(Icons.dark_mode),
                        ),
                      ],
                    ),
                   ),

                  // Exam Settings Section
                  _buildSectionHeader('Exam Settings'),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Show Explanations'),
                          subtitle: const Text('Show answer explanations after each question'),
                          value: _showExplanations,
                          onChanged: (value) {
                            setState(() => _showExplanations = value);
                            _saveSetting('showExplanations', value);
                          },
                          secondary: const Icon(Icons.help_outline),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Lightning Round'),
                          subtitle: const Text('Hide explanations for faster practice'),
                          value: _lightningRoundEnabled,
                          onChanged: (value) {
                            setState(() => _lightningRoundEnabled = value);
                            _saveSetting('lightningRoundEnabled', value);
                          },
                          secondary: const Icon(Icons.flash_on),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.shuffle),
                          title: const Text('Question Order'),
                          subtitle: const Text('Choose how questions are presented'),
                          trailing: DropdownButton<int>(
                            value: _questionOrder,
                            items: const [
                              DropdownMenuItem(
                                value: 0,
                                child: Text('Random'),
                              ),
                              DropdownMenuItem(
                                value: 1,
                                child: Text('Sequential'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _questionOrder = value);
                                _saveSetting('questionOrder', value);
                              }
                            },
                          ),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Shuffle Questions'),
                          subtitle: const Text('Randomize the order of questions'),
                          value: _shuffleQuestions,
                          onChanged: (value) {
                            setState(() => _shuffleQuestions = value);
                            _saveSetting('shuffleQuestions', value);
                          },
                          secondary: const Icon(Icons.shuffle),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Shuffle Options'),
                          subtitle: const Text('Randomize the order of answer choices'),
                          value: _shuffleOptions,
                          onChanged: (value) {
                            setState(() => _shuffleOptions = value);
                            _saveSetting('shuffleOptions', value);
                          },
                          secondary: const Icon(Icons.swap_horiz),
                        ),
                      ],
                    ),
                  ),

                  // Sound & Vibration Section
                  _buildSectionHeader('Sound & Vibration'),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Sound Effects'),
                          subtitle: const Text('Play sounds during exam'),
                          value: _soundEnabled,
                          onChanged: (value) {
                            setState(() => _soundEnabled = value);
                            _saveSetting('soundEnabled', value);
                          },
                          secondary: const Icon(Icons.volume_up),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Vibration'),
                          subtitle: const Text('Vibrate on answer feedback'),
                          value: _vibrationEnabled,
                          onChanged: (value) {
                            setState(() => _vibrationEnabled = value);
                            _saveSetting('vibrationEnabled', value);
                          },
                          secondary: const Icon(Icons.vibration),
                        ),
                      ],
                    ),
                  ),

                  // Data Management Section
                  _buildSectionHeader('Data Management'),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        
                        // In settings_screen.dart, find the "Reset All Progress" ListTile
                        ListTile(
                          leading: const Icon(Icons.restart_alt, color: Colors.orange),
                          title: const Text('Reset All Progress'),
                          subtitle: const Text('Clear all data and reset to defaults'),
                          onTap: _resetProgress,  // ✅ This should be here
                        ),
                        
                        const Divider(height: 1),
                        // In settings_screen.dart, update the clear history onTap:
                        ListTile(
                          leading: const Icon(Icons.delete, color: Colors.red),
                          title: const Text('Clear Exam History'),
                          subtitle: const Text('Remove all saved exam results'),
                          onTap: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Clear Exam History?'),
                                content: const Text('This will delete all your exam results.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: Text(
                                      'Clear',
                                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                                    ),
                                  ),
                                ],
                              ),
                            );
                        
                            if (confirmed == true) {
                              try {
                                await DatabaseHelper.clearAllResults();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Exam history cleared'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
        
                                // ✅ Navigate back to home with fresh stats
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                                  (route) => false,
                                );
                                
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        // End of Column children
                      ],
                    ),
                  ),

                  // About Section
                  _buildSectionHeader('About'),
                 Card(
  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: FutureBuilder<PackageInfo>(
    future: PackageInfo.fromPlatform(),
    builder: (context, snapshot) {
      // While waiting for data, show a placeholder or empty text
      String version = snapshot.data?.version ?? "Loading...";
      
      return ListTile(
        leading: const Icon(Icons.info_outline),
        title: const Text('About App'),
        subtitle: Text('Version $version'), // This is now automatic!
        onTap: _showAppInfo,
      );
    },
  ),
),

                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'CS Exit Exam App v1.1.4',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          )
        );
      }

      Widget _buildSectionHeader(String title) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
  }
}
    