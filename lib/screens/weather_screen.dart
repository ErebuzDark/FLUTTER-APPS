import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/weather_data.dart';
import '../services/weather_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  WeatherData? _weather;
  bool _isLoading = false;
  String? _error;

  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    _focusNode.unfocus();
    setState(() {
      _isLoading = true;
      _error = null;
    });
    _fadeController.reset();

    try {
      final data = await WeatherService.fetch(query);
      setState(() {
        _weather = data;
        _isLoading = false;
      });
      _fadeController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _weather = null;
        _isLoading = false;
      });
    }
  }

  List<Color> get _backgroundColors {
    if (_weather == null) {
      return [const Color(0xFF0F1C2E), const Color(0xFF1E3A5F)];
    }
    return _gradientForIcon(_weather!.icon);
  }

  List<Color> _gradientForIcon(String icon) {
    if (icon.contains('01')) {
      return [const Color(0xFF1E3A5F), const Color(0xFF4A90D9)];
    } else if (icon.contains('02') || icon.contains('03')) {
      return [const Color(0xFF2C3E50), const Color(0xFF546E7A)];
    } else if (icon.contains('04')) {
      return [const Color(0xFF3D4451), const Color(0xFF6B7280)];
    } else if (icon.contains('09') || icon.contains('10')) {
      return [const Color(0xFF1A2535), const Color(0xFF37474F)];
    } else if (icon.contains('11')) {
      return [const Color(0xFF1A1A2E), const Color(0xFF2D2D44)];
    } else if (icon.contains('13')) {
      return [const Color(0xFF2E3F5C), const Color(0xFF7B9CC0)];
    } else if (icon.contains('50')) {
      return [const Color(0xFF3D4451), const Color(0xFF7F8C8D)];
    }
    return [const Color(0xFF1E3A5F), const Color(0xFF4A90D9)];
  }

  String _emojiForIcon(String icon) {
    if (icon.contains('01d')) return '☀️';
    if (icon.contains('01n')) return '🌙';
    if (icon.contains('02')) return '⛅';
    if (icon.contains('03') || icon.contains('04')) return '☁️';
    if (icon.contains('09')) return '🌧️';
    if (icon.contains('10d')) return '🌦️';
    if (icon.contains('10n')) return '🌧️';
    if (icon.contains('11')) return '⛈️';
    if (icon.contains('13')) return '❄️';
    if (icon.contains('50')) return '🌫️';
    return '🌡️';
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _backgroundColors,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildSearchBar(),
              const SizedBox(height: 32),
              if (_isLoading) _buildLoader(),
              if (_error != null) _buildError(),
              if (_weather != null && !_isLoading)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildWeatherCard(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weather',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -1,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        Text(
          'Check conditions anywhere',
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(Icons.search_rounded,
                  color: Colors.white.withOpacity(0.6), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onSubmitted: (_) => _search(),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Search city…',
                    hintStyle:
                        TextStyle(color: Colors.white.withOpacity(0.4)),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _search,
                child: Container(
                  margin: const EdgeInsets.all(6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Go',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: const Text('🌍', style: TextStyle(fontSize: 56)),
            ),
            const SizedBox(height: 20),
            Text(
              'Fetching weather…',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7), fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 15,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    final w = _weather!;
    final emoji = _emojiForIcon(w.icon);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on_rounded,
                          color: Colors.white.withOpacity(0.7), size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${w.city}, ${w.country}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(emoji, style: const TextStyle(fontSize: 80)),
                  const SizedBox(height: 8),
                  Text(
                    '${w.temperature.round()}°',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 80,
                        fontWeight: FontWeight.w200,
                        letterSpacing: -4,
                        height: 1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _capitalize(w.description),
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 18),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'H:${w.tempMax.round()}°  L:${w.tempMin.round()}°',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildStatTile('💧', 'Humidity', '${w.humidity}%'),
            const SizedBox(width: 12),
            _buildStatTile(
                '🌬️', 'Wind', '${w.windSpeed.toStringAsFixed(1)} m/s'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatTile('🌡️', 'Feels like', '${w.feelsLike.round()}°C'),
            const SizedBox(width: 12),
            _buildStatTile('👁️', 'Visibility', '${w.visibility} km'),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatTileFull('🔽', 'Pressure', '${w.pressure} hPa'),
      ],
    );
  }

  Widget _buildStatTile(String emoji, String label, String value) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 6),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(label,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatTileFull(String emoji, String label, String value) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 12)),
                  Text(value,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}