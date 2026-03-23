import 'package:flutter/material.dart';
import '../services/tts_service.dart';

/// The preferences view for the Stuff Crawler application.
/// Allows the user to configure settings like TTS speed, voice, and experience.
class PreferencesView extends StatefulWidget {
  final TtsService ttsService;

  const PreferencesView({super.key, required this.ttsService});

  @override
  State<PreferencesView> createState() => _PreferencesViewState();
}

class _PreferencesViewState extends State<PreferencesView> {
  double _speechRate = 0.5;
  bool _autoContinue = true;
  List<dynamic> _allVoices = [];
  List<dynamic> _filteredVoices = [];
  Map? _selectedVoice;
  String _selectedLocale = 'en-US';

  final List<String> _availableLocales = ['en-US', 'en-GB'];

  @override
  void initState() {
    print('Entering PreferencesView.initState');
    super.initState();
    _speechRate = widget.ttsService.getSpeechRate();
    _selectedLocale = widget.ttsService.currentLocale;
    _selectedVoice = widget.ttsService.currentVoice;
    _loadVoices();
    print('Exiting PreferencesView.initState');
  }

  Future<void> _loadVoices() async {
    print('Entering PreferencesView._loadVoices');
    try {
      final voices = await widget.ttsService.getVoices();
      setState(() {
        _allVoices = voices;
        _filterVoices();
      });
    } catch (e) {
      print('Error loading voices: $e');
    }
    print('Exiting PreferencesView._loadVoices');
  }

  void _filterVoices() {
    print(
      'Entering PreferencesView._filterVoices with locale: $_selectedLocale',
    );
    final filtered = _allVoices.where((voice) {
      final locale = voice['locale'] as String?;
      return locale != null &&
          locale.toLowerCase().contains(_selectedLocale.toLowerCase());
    }).toList();

    setState(() {
      _filteredVoices = filtered;

      // Update _selectedVoice to the instance within _filteredVoices that matches by name/identifier
      if (_selectedVoice != null) {
        final existingName = _selectedVoice!['name'];
        final existingIdentifier = _selectedVoice!['identifier'];

        try {
          _selectedVoice = _filteredVoices.firstWhere(
            (v) =>
                (existingIdentifier != null &&
                    v['identifier'] == existingIdentifier) ||
                (v['name'] == existingName),
          );
          // Update the service with the actual instance from the list
          widget.ttsService.setVoice(_selectedVoice!);
        } catch (e) {
          // If no longer found in filtered list, only then reset
          if (!_filteredVoices.contains(_selectedVoice)) {
            if (_filteredVoices.isNotEmpty) {
              _selectedVoice = _filteredVoices.first;
              widget.ttsService.setVoice(_selectedVoice!);
            } else {
              _selectedVoice = null;
              widget.ttsService.resetVoice();
            }
          }
        }
      }
    });
    print(
      'Exiting PreferencesView._filterVoices - found ${_filteredVoices.length} voices',
    );
  }

  /// Handles navigation back to the HomeView.
  void _onBackToHomePressed() {
    print('Navigating back to HomeView');
    Navigator.of(context).pop();
  }

  /// Updates the speech rate setting and syncs with TtsService.
  void _onSpeechRateChanged(double value) {
    print('Speech rate changed to: $value');
    setState(() => _speechRate = value);
    widget.ttsService.setSpeechRate(value);
  }

  /// Updates the selected locale and triggers voice filtering.
  void _onLocaleChanged(String? newLocale) {
    if (newLocale != null) {
      print('Locale changed to: $newLocale');
      setState(() {
        _selectedLocale = newLocale;
        _filterVoices();
      });
    }
  }

  /// Updates the selected voice and syncs with TtsService.
  void _onVoiceChanged(Map? voice) {
    print(
      'Voice changed to: ${voice != null ? voice['name'] : 'System Default'}',
    );
    setState(() => _selectedVoice = voice);
    if (voice != null) {
      widget.ttsService.setVoice(voice);
    } else {
      widget.ttsService.resetVoice();
    }
  }

  /// Toggles the auto-continue session setting.
  void _onAutoContinueChanged(bool value) {
    print('Auto-continue toggled: $value');
    setState(() => _autoContinue = value);
  }

  /// Handles theme mode selection placeholder.
  void _onThemeModeTapped() {
    print('Theme selection tapped (placeholder)');
  }

  @override
  Widget build(BuildContext context) {
    print('Entering PreferencesView.build');
    final result = Scaffold(
      appBar: AppBar(
        title: const Text('Preferences'),
        elevation: 8,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _onBackToHomePressed,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade50, Colors.white],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            _buildSectionHeader('Speech Settings'),
            _buildCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.speed, color: Colors.deepPurple),
                    title: const Text('Speech Rate'),
                    subtitle: Text(
                      '${(_speechRate * 2.0).toStringAsFixed(1)}x',
                    ),
                    trailing: SizedBox(
                      width: 150,
                      child: Slider(
                        value: _speechRate,
                        onChanged: _onSpeechRateChanged,
                        activeColor: Colors.deepPurple,
                      ),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.language,
                      color: Colors.deepPurple,
                    ),
                    title: const Text('Locale Settings'),
                    subtitle: Text('Selected: $_selectedLocale'),
                    trailing: DropdownButton<String>(
                      underline: const SizedBox(),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.deepPurple,
                      ),
                      value: _selectedLocale,
                      items: _availableLocales.map((locale) {
                        return DropdownMenuItem<String>(
                          value: locale,
                          child: Text(locale),
                        );
                      }).toList(),
                      onChanged: _onLocaleChanged,
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.record_voice_over,
                      color: Colors.deepPurple,
                    ),
                    title: const Text('Voice Selection'),
                    subtitle: _selectedVoice == null
                        ? const Text('Default Voice')
                        : Text('${_selectedVoice!['name']}'),
                    trailing: _allVoices.isEmpty
                        ? const CircularProgressIndicator()
                        : DropdownButton<Map?>(
                            underline: const SizedBox(),
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.deepPurple,
                            ),
                            value: _filteredVoices.contains(_selectedVoice)
                                ? _selectedVoice
                                : null,
                            items: [
                              const DropdownMenuItem<Map?>(
                                value: null,
                                child: Text('System Default'),
                              ),
                              ..._filteredVoices.map((voice) {
                                return DropdownMenuItem<Map?>(
                                  value: voice,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 150,
                                    ),
                                    child: Text(
                                      '${voice['name']}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                );
                              }),
                            ],
                            onChanged: _onVoiceChanged,
                          ),
                  ),
                  const Divider(),
                  SwitchListTile(
                    secondary: const Icon(
                      Icons.play_circle_fill,
                      color: Colors.deepPurple,
                    ),
                    title: const Text('Auto-Continue Session'),
                    subtitle: const Text(
                      'Automatically proceed to the next word after reading the definition.',
                    ),
                    value: _autoContinue,
                    onChanged: _onAutoContinueChanged,
                    activeColor: Colors.deepPurple,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('Appearance'),
            _buildCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.color_lens,
                      color: Colors.deepPurple,
                    ),
                    title: const Text('Theme Mode'),
                    trailing: const Text('System Default'),
                    onTap: _onThemeModeTapped,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Center(
              child: ElevatedButton.icon(
                onPressed: _onBackToHomePressed,
                icon: const Icon(Icons.home),
                label: const Text('Back to Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    print('Exiting PreferencesView.build');
    return result;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple.shade700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 4,
      shadowColor: Colors.deepPurple.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(8.0), child: child),
    );
  }
}
