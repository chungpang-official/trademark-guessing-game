import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

void main() {
  runApp(const TrademarkGame());
}

class TrademarkGame extends StatelessWidget {
  const TrademarkGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trademark Guesser',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const GameScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  // Game Data
  final List<Map<String, String>> trademarks = [
    {
      'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a6/Logo_NIKE.svg/1200px-Logo_NIKE.svg.png',
      'answer': 'nike'
    },
    {
      'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2f/Google_2015_logo.svg/1200px-Google_2015_logo.svg.png',
      'answer': 'google'
    },
    {
      'image': 'https://upload.wikimedia.org/wikipedia/commons/8/83/Steam_icon_logo.svg',
      'answer': 'steam'
    },
    {
      'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Apple_logo_black.svg/800px-Apple_logo_black.svg.png',
      'answer': 'apple'
    },
    {
      'image': 'https://upload.wikimedia.org/wikipedia/commons/a/ab/Valve_logo.svg',
      'answer': 'valve'
    },
  ];

  // Game State
  int _currentIndex = 0;
  int _score = 0;
  int _highScore = 0;
  int _timeLeft = 30;
  bool _showHint = false;
  String _message = '';
  bool _isCorrect = false;
  Timer? _timer;
  final TextEditingController _guessController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _startTimer();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _audioPlayer.dispose();
    _guessController.dispose();
    super.dispose();
  }

  // Load saved high score
  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  // Save new high score
  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highScore', _highScore);
  }

  // Start/reset timer
  void _startTimer() {
    _timer?.cancel();
    setState(() => _timeLeft = 30);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        timer.cancel();
        _handleTimeOut();
      }
    });
  }

  // Handle timer expiration
  void _handleTimeOut() {
    setState(() {
      _message = 'Time\'s up! Answer: ${trademarks[_currentIndex]['answer']}';
      _showHint = false;
    });
    _playSound('wrong.mp3');
    _nextQuestion();
  }

  // Play sound effects
  Future<void> _playSound(String soundFile) async {
    await _audioPlayer.play(AssetSource(soundFile));
  }

  // Move to next question or end game
  void _nextQuestion() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          if (_currentIndex < trademarks.length - 1) {
            _currentIndex++;
            _guessController.clear();
            _message = '';
            _showHint = false;
            _isCorrect = false;
            _startTimer();
          } else {
            _endGame();
          }
        });
      }
    });
  }

  // End game logic
  void _endGame() {
    if (_score > _highScore) {
      setState(() => _highScore = _score);
      _saveHighScore();
    }
    setState(() {
      _message = 'Game Over! Score: $_score | High Score: $_highScore';
    });
  }

  // Check user's answer
  void _checkAnswer() {
    final userGuess = _guessController.text.toLowerCase().trim();
    final correctAnswer = trademarks[_currentIndex]['answer']!.toLowerCase();

    if (userGuess.isEmpty) return;

    if (userGuess == correctAnswer) {
      _timer?.cancel();
      setState(() {
        _score++;
        _message = 'Correct! +1 point';
        _isCorrect = true;
        _animationController.forward(from: 0.0);
      });
      _playSound('correct.mp3');
      _nextQuestion();
    } else {
      setState(() {
        _message = 'Incorrect. Try again!';
        _showHint = true;
        _isCorrect = false;
        _animationController.forward(from: 0.0);
      });
      _playSound('wrong.mp3');
    }
  }

  // Generate hint (reveals every other letter)
  String _getHint() {
    final answer = trademarks[_currentIndex]['answer']!;
    var hint = '';
    for (int i = 0; i < answer.length; i++) {
      hint += (i % 2 == 0 || answer[i] == ' ') ? answer[i] : '_';
    }
    return hint;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guess the Trademark'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                'High Score: $_highScore',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Score and Timer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Score: $_score',
                  style: const TextStyle(fontSize: 20),
                ),
                Text(
                  '⏱️ $_timeLeft',
                  style: TextStyle(
                    fontSize: 20,
                    color: _timeLeft <= 10 ? Colors.red : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Animated Logo
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isCorrect ? Colors.green : Colors.grey,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CachedNetworkImage(
                    imageUrl: trademarks[_currentIndex]['image']!,
                    height: 150,
                    placeholder: (context, url) => const CircularProgressIndicator(),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Hint
            if (_showHint)
              Text(
                'Hint: ${_getHint()}',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.blueAccent,
                ),
              ),
            const SizedBox(height: 10),

            // Input Field
            TextField(
              controller: _guessController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter brand name',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _checkAnswer,
                ),
              ),
              onSubmitted: (_) => _checkAnswer(),
            ),
            const SizedBox(height: 20),

            // Message
            Text(
              _message,
              style: TextStyle(
                fontSize: 18,
                color: _isCorrect ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}