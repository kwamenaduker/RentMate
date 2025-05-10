import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class WeatherService {
  // API key from WeatherAPI.com - in production, store this securely!
  // Get a free API key at https://www.weatherapi.com/
  final String apiKey = 'fa53a8a1aa214fc6a74233357250905'; // Replace with your actual API key
  final String baseUrl = 'https://api.weatherapi.com/v1';
  
  // Get current weather for a location
  Future<Map<String, dynamic>?> getCurrentWeather(double latitude, double longitude) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/current.json?key=$apiKey&q=$latitude,$longitude'),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        if (kDebugMode) {
          print('Failed to get weather: ${response.statusCode}');
          print('Response: ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting weather data: $e');
      }
      
      // Demo data for testing/development
      return {
        "location": {
          "name": "Demo Location",
          "region": "Demo Region",
          "country": "Demo Country",
          "lat": latitude,
          "lon": longitude,
          "localtime": "2023-05-09 12:00"
        },
        "current": {
          "temp_c": 22.5,
          "condition": {
            "text": "Sunny",
            "icon": "//cdn.weatherapi.com/weather/64x64/day/113.png",
            "code": 1000
          },
          "wind_kph": 10.8,
          "humidity": 65
        }
      };
    }
  }
  
  // Get forecast for a location (up to 3 days for free API plan)
  Future<Map<String, dynamic>?> getForecast(double latitude, double longitude, {int days = 3}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/forecast.json?key=$apiKey&q=$latitude,$longitude&days=$days'),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        if (kDebugMode) {
          print('Failed to get forecast: ${response.statusCode}');
          print('Response: ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting forecast data: $e');
      }
      
      // Demo forecast data for WeatherAPI.com format
      return {
        "location": {
          "name": "Demo Location",
          "region": "Demo Region",
          "country": "Demo Country",
          "lat": latitude,
          "lon": longitude,
          "localtime": "2023-05-09 12:00"
        },
        "current": {
          "temp_c": 22.5,
          "condition": {
            "text": "Sunny",
            "icon": "//cdn.weatherapi.com/weather/64x64/day/113.png",
            "code": 1000
          }
        },
        "forecast": {
          "forecastday": [
            {
              "date": DateTime.now().add(const Duration(days: 0)).toString().split(' ')[0],
              "day": {
                "maxtemp_c": 24.5,
                "mintemp_c": 18.2,
                "avgtemp_c": 22.1,
                "condition": {
                  "text": "Sunny",
                  "icon": "//cdn.weatherapi.com/weather/64x64/day/113.png",
                  "code": 1000
                }
              }
            },
            {
              "date": DateTime.now().add(const Duration(days: 1)).toString().split(' ')[0],
              "day": {
                "maxtemp_c": 23.1,
                "mintemp_c": 17.8,
                "avgtemp_c": 21.3,
                "condition": {
                  "text": "Partly cloudy",
                  "icon": "//cdn.weatherapi.com/weather/64x64/day/116.png",
                  "code": 1003
                }
              }
            },
            {
              "date": DateTime.now().add(const Duration(days: 2)).toString().split(' ')[0],
              "day": {
                "maxtemp_c": 20.6,
                "mintemp_c": 16.5,
                "avgtemp_c": 19.2,
                "condition": {
                  "text": "Light rain",
                  "icon": "//cdn.weatherapi.com/weather/64x64/day/296.png",
                  "code": 1183
                }
              }
            }
          ]
        }
      };
    }
  }
  
  // Get the appropriate weather icon URL (WeatherAPI.com already provides full URLs)
  String getWeatherIconUrl(String iconPath) {
    // Check if the URL is already complete
    if (iconPath.startsWith('http')) {
      return iconPath;
    }
    
    // If it's a relative URL, add the necessary prefix
    if (iconPath.startsWith('//')) {
      return 'https:$iconPath';
    }
    
    // Fallback icon if none provided
    return 'https://cdn.weatherapi.com/weather/64x64/day/113.png';
  }
  
  // Get weather for specified dates at a location
  Future<List<Map<String, dynamic>>> getWeatherForDateRange(
    double latitude, 
    double longitude, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      // Calculate days needed for forecast (max 14 days for paid API, 3 for free)
      final daysDifference = endDate.difference(startDate).inDays + 1;
      final days = daysDifference < 3 ? 3 : daysDifference;
      
      final forecastData = await getForecast(latitude, longitude, days: days);
      
      if (forecastData == null || !forecastData.containsKey('forecast')) {
        return _getDemoForecastData(startDate, endDate);
      }
      
      final forecastList = forecastData['forecast']['forecastday'] as List;
      final filteredForecast = <Map<String, dynamic>>[];
      
      // Process each day's forecast
      for (var item in forecastList) {
        final dateStr = item['date'] as String;
        final date = DateTime.parse(dateStr);
        
        // Skip dates outside our range
        if (date.isBefore(startDate.subtract(const Duration(days: 1))) || 
            date.isAfter(endDate.add(const Duration(days: 1)))) {
          continue;
        }
        
        final dayData = item['day'];
        final condition = dayData['condition'];
        
        filteredForecast.add({
          'date': dateStr,
          'temp': dayData['avgtemp_c'],
          'condition': condition['text'],
          'description': condition['text'],
          'icon': condition['icon'],
          'code': condition['code'],
        });
      }
      
      // Fill in any missing days with demo data if needed
      if (filteredForecast.isEmpty) {
        return _getDemoForecastData(startDate, endDate);
      }
      
      // Sort by date just to be sure
      filteredForecast.sort((a, b) => a['date'].compareTo(b['date']));
      
      return filteredForecast;
    } catch (e) {
      if (kDebugMode) {
        print('Error processing forecast data: $e');
      }
      return _getDemoForecastData(startDate, endDate);
    }
  }
  
  // Create demo forecast data for a range of dates
  List<Map<String, dynamic>> _getDemoForecastData(DateTime startDate, DateTime endDate) {
    final demoForecasts = <Map<String, dynamic>>[];
    
    for (var d = startDate; d.isBefore(endDate.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
      demoForecasts.add(_createDemoForecast(d));
    }
    
    return demoForecasts;
  }
  
  // Create a single demo forecast for a specific date
  Map<String, dynamic> _createDemoForecast(DateTime date) {
    // Generate weather based on the date to create variability
    final weatherTypes = ['Sunny', 'Partly cloudy', 'Light rain', 'Cloudy'];
    final descriptions = ['Sunny', 'Partly cloudy', 'Light rain', 'Cloudy'];
    final icons = [
      '//cdn.weatherapi.com/weather/64x64/day/113.png',
      '//cdn.weatherapi.com/weather/64x64/day/116.png',
      '//cdn.weatherapi.com/weather/64x64/day/296.png',
      '//cdn.weatherapi.com/weather/64x64/day/119.png'
    ];
    final codes = [1000, 1003, 1183, 1006];
    
    // Use the day of month to select a weather type (creates variety)
    final index = date.day % weatherTypes.length;
    
    // Temperature varies by day but stays reasonable
    final baseTemp = 22.0;
    final tempVariation = (date.day % 10) - 5; // -5 to +4
    
    return {
      'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'temp': baseTemp + tempVariation,
      'condition': weatherTypes[index],
      'description': descriptions[index],
      'icon': icons[index],
      'code': codes[index],
    };
  }
}
