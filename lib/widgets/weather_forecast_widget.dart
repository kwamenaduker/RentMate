import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rent_mate/services/weather_service.dart';
import 'package:rent_mate/config/app_theme.dart';

class WeatherForecastWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final DateTime startDate;
  final DateTime endDate;
  final String locationName;

  const WeatherForecastWidget({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.startDate,
    required this.endDate,
    required this.locationName,
  }) : super(key: key);

  @override
  State<WeatherForecastWidget> createState() => _WeatherForecastWidgetState();
}

class _WeatherForecastWidgetState extends State<WeatherForecastWidget> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _forecastData = [];

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final weatherService = Provider.of<WeatherService>(context, listen: false);
      final forecast = await weatherService.getWeatherForDateRange(
        widget.latitude,
        widget.longitude,
        widget.startDate,
        widget.endDate,
      );
      
      if (mounted) {
        setState(() {
          _forecastData = forecast;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getDayName(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) return 'N/A';
    
    try {
      final date = DateTime(
        int.parse(parts[0]), 
        int.parse(parts[1]), 
        int.parse(parts[2])
      );
      return DateFormat('E').format(date); // Returns short day name (e.g., Mon, Tue)
    } catch (e) {
      return 'N/A';
    }
  }

  String _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return '☀️';
      case 'partly cloudy':
        return '⛅';
      case 'cloudy':
      case 'overcast':
        return '☁️';
      case 'light rain':
      case 'patchy rain possible':
      case 'light rain shower':
        return '🌦️';
      case 'moderate rain':
      case 'heavy rain':
      case 'rain':
        return '🌧️';
      case 'thunderstorm':
      case 'thundery outbreaks possible':
        return '⛈️';
      case 'snow':
      case 'patchy snow possible':
      case 'light snow':
        return '❄️';
      case 'mist':
      case 'fog':
      case 'freezing fog':
        return '🌫️';
      default:
        return '🌤️';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        margin: EdgeInsets.symmetric(vertical: 10),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weather Forecast',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 12),
              Center(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_forecastData.isEmpty) {
      return const SizedBox.shrink(); // Hide if no data
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
            child: Row(
              children: [
                const Icon(Icons.wb_sunny_outlined, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Weather Forecast',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          // Weather cards
          SizedBox(
            height: 90,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              scrollDirection: Axis.horizontal,
              itemCount: _forecastData.length,
              itemBuilder: (context, index) {
                final forecast = _forecastData[index];
                final dayName = _getDayName(forecast['date']);
                final condition = forecast['condition'];
                final temp = forecast['temp'].toStringAsFixed(1);
                final weatherIcon = _getWeatherIcon(condition);
                
                return Container(
                  width: 55,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        weatherIcon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$temp°C',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Footer
          const Padding(
            padding: EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Text(
              'Weather data powered by WeatherAPI.com',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
