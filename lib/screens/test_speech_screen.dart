import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class TestSpeechScreen extends StatefulWidget {
  const TestSpeechScreen({super.key});

  @override
  State<TestSpeechScreen> createState() => _TestSpeechScreenState();
}

class _TestSpeechScreenState extends State<TestSpeechScreen> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _speechAvailable = false;
  String _lastWords = '';
  String _status = 'Initializing speech recognition...';
  bool _isListening = false;
  double _confidence = 0.0;
  final List<String> _recognizedPhrases = [];
  List<LocaleName> _availableLocales = [];
  LocaleName? _selectedLocale;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    setState(() {
      _status = 'Checking permissions...';
    });

    // Request microphone permission
    PermissionStatus permission = await Permission.microphone.request();
    
    if (permission != PermissionStatus.granted) {
      setState(() {
        _status = 'Microphone permission denied. Please grant permission in settings.';
        _speechEnabled = false;
      });
      return;
    }

    setState(() {
      _status = 'Initializing speech recognition...';
    });

    try {
      _speechEnabled = await _speechToText.initialize(
        onStatus: (status) {
          setState(() {
            _status = 'Status: $status';
            if (status == 'notListening') {
              _isListening = false;
            } else if (status == 'listening') {
              _isListening = true;
            }
          });
        },
        onError: (error) {
          setState(() {
            _status = 'Error: ${error.errorMsg}';
            _isListening = false;
          });
        },
      );

      if (_speechEnabled) {
        _speechAvailable = _speechToText.isAvailable;
        _availableLocales = await _speechToText.locales();
        
        // Find English locale
        _selectedLocale = _availableLocales.firstWhere(
          (locale) => locale.localeId.startsWith('en'),
          orElse: () => _availableLocales.isNotEmpty ? _availableLocales.first : LocaleName('en_US', 'English'),
        );
        
        setState(() {
          if (_speechAvailable) {
            _status = 'Speech recognition ready! Tap microphone to start listening.';
          } else {
            _status = 'Speech recognition not available on this device.\n\nThis could be due to:\n• Device limitations\n• Missing speech services\n• Network connectivity issues\n\nTry restarting the app or checking device settings.';
          }
        });
      } else {
        setState(() {
          _status = 'Failed to initialize speech recognition. Check permissions.';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error initializing speech recognition: $e';
        _speechEnabled = false;
      });
    }
  }

  void _startListening() async {
    if (!_speechEnabled || !_speechAvailable) {
      _initSpeech(); // Try to reinitialize
      return;
    }

    setState(() {
      _lastWords = '';
      _confidence = 0.0;
      _status = 'Listening for speech...';
    });

    try {
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _lastWords = result.recognizedWords;
            _confidence = result.confidence;
            if (result.finalResult) {
              if (_lastWords.isNotEmpty) {
                _recognizedPhrases.add(_lastWords);
                if (_recognizedPhrases.length > 15) {
                  _recognizedPhrases.removeAt(0);
                }
              }
              _status = 'Recognition complete. Tap microphone to listen again.';
            } else {
              _status = 'Listening... (partial result)';
            }
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: _selectedLocale?.localeId ?? 'en_US',
        onSoundLevelChange: (level) {
          // Could show sound level indicator here
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.confirmation,
        ),
      );
    } catch (e) {
      setState(() {
        _status = 'Error starting speech recognition: $e';
        _isListening = false;
      });
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
      _status = _speechAvailable 
          ? 'Speech recognition ready. Tap microphone to start listening.'
          : 'Speech recognition not available';
    });
  }

  void _clearResults() {
    setState(() {
      _recognizedPhrases.clear();
      _lastWords = '';
      _confidence = 0.0;
      _status = 'History cleared. Ready for speech recognition.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Speech Recognition Test',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          if (_availableLocales.isNotEmpty)
            PopupMenuButton<LocaleName>(
              icon: const Icon(Icons.language),
              onSelected: (LocaleName locale) {
                setState(() {
                  _selectedLocale = locale;
                  _status = 'Language changed to ${locale.name}';
                });
              },
              itemBuilder: (BuildContext context) {
                return _availableLocales.take(10).map((LocaleName locale) {
                  return PopupMenuItem<LocaleName>(
                    value: locale,
                    child: Text('${locale.name} (${locale.localeId})'),
                  );
                }).toList();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
            // Status Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _speechEnabled ? Colors.blue[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _speechEnabled ? Colors.blue[300]! : Colors.red[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _speechEnabled ? Icons.mic : Icons.mic_off,
                        color: _speechEnabled ? Colors.blue[800] : Colors.red[800],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _speechEnabled ? Colors.blue[800] : Colors.red[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (_isListening) 
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.blue[600],
                          ),
                        ),
                      if (_isListening) const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _status,
                          style: TextStyle(
                            fontSize: 14,
                            color: _speechEnabled ? Colors.blue[700] : Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_confidence > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: _confidence,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_selectedLocale != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Language: ${_selectedLocale!.name} (${_selectedLocale!.localeId})',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Current Recognition
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.hearing, color: Colors.green[800]),
                      const SizedBox(width: 8),
                      Text(
                        'Current Recognition',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 60),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Text(
                      _lastWords.isEmpty ? 'Speak something...' : _lastWords,
                      style: TextStyle(
                        fontSize: 16,
                        color: _lastWords.isEmpty ? Colors.grey[500] : Colors.black,
                        fontStyle: _isListening ? FontStyle.italic : FontStyle.normal,
                        fontWeight: _isListening ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Start/Stop Listening Button
                ElevatedButton.icon(
                  onPressed: _speechEnabled && _speechAvailable
                      ? (_isListening ? _stopListening : _startListening)
                      : _initSpeech,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !_speechEnabled 
                        ? Colors.orange[400]
                        : (_isListening ? Colors.red[400] : Colors.green[400]),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: Icon(!_speechEnabled 
                      ? Icons.refresh
                      : (_isListening ? Icons.mic_off : Icons.mic)),
                  label: Text(!_speechEnabled 
                      ? 'Init'
                      : (_isListening ? 'Stop' : 'Listen')),
                ),
                
                // Clear Results Button
                ElevatedButton.icon(
                  onPressed: _clearResults,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Recognition History
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history, color: Colors.purple[800]),
                        const SizedBox(width: 8),
                        Text(
                          'Recognition History (${_recognizedPhrases.length})',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _recognizedPhrases.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.record_voice_over,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No speech recognized yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap "Listen" to start recording',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _recognizedPhrases.length,
                              itemBuilder: (context, index) {
                                final phrase = _recognizedPhrases[_recognizedPhrases.length - 1 - index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.purple[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: Colors.purple[100],
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${_recognizedPhrases.length - index}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.purple[600],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          phrase,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.copy,
                                          size: 16,
                                          color: Colors.purple[400],
                                        ),
                                        onPressed: () {
                                          // Copy to clipboard functionality could be added here
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }
}