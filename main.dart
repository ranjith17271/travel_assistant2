import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(TravelAssistantApp());
}

class TravelAssistantApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel Assistant',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: HomeScreen(),
    );
  }
}

class WeatherService {
  final String apiKey = '74ea6ad814387cb4e55935e72bf2a993'; // Replace with your OpenWeatherMap API key

  Future<Map<String, dynamic>> fetchWeather(String city) async {
    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$city&units=metric&appid=$apiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Weather not found');
    }
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> cities = ['Delhi', 'Mumbai', 'Chennai', 'Bangalore', 'Kolkata'];
  String selectedCity = 'Delhi';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Travel Assistant')),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: DropdownButtonFormField<String>(
                value: selectedCity,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Select a City',
                  border: OutlineInputBorder(),
                ),
                items: cities.map((city) {
                  return DropdownMenuItem(
                    value: city,
                    child: Text(city),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCity = value!;
                  });
                },
              ),
            ),
            ElevatedButton(
              child: Text("Explore"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CityInfoScreen(city: selectedCity),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}

class CityInfoScreen extends StatefulWidget {
  final String city;
  CityInfoScreen({required this.city});

  @override
  _CityInfoScreenState createState() => _CityInfoScreenState();
}

class _CityInfoScreenState extends State<CityInfoScreen> with TickerProviderStateMixin {
  late Future<Map<String, dynamic>> weatherData;
  late TabController _tabController;

  final Map<String, List<Map<String, String>>> cityAttractions = {
    'Delhi': [
      {'name': 'Red Fort', 'image': 'assets/images/red_fort.jpg'},
      {'name': 'India Gate', 'image': 'assets/images/india_gate.jpg'},
    ],
    'Mumbai': [
      {'name': 'Gateway of India', 'image': 'assets/images/gateway_of_india.jpg'},
      {'name': 'Marine Drive', 'image': 'assets/images/marine_drive.jpg'},
    ],
    'Chennai': [
      {'name': 'Marina Beach', 'image': 'assets/images/marina_beach.jpg'},
      {'name': 'Kapaleeshwarar Temple', 'image': 'assets/images/kapaleeshwarar_temple.jpg'},
    ],
    'Bangalore': [
      {'name': 'Lalbagh Garden', 'image': 'assets/images/lalbagh_garden.jpg'},
      {'name': 'Bangalore Palace', 'image': 'assets/images/bangalore_palace.jpg'},
    ],
    'Kolkata': [
      {'name': 'Victoria Memorial', 'image': 'assets/images/victoria_memorial.jpg'},
      {'name': 'Howrah Bridge', 'image': 'assets/images/howrah_bridge.jpg'},
    ]
  };

  @override
  void initState() {
    super.initState();
    weatherData = WeatherService().fetchWeather(widget.city);
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _launchMap(String query) async {
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
    if (!await launchUrl(url)) {
      throw 'Could not launch $url';
    }
  }

  Widget buildWeatherTab(Map<String, dynamic> data) {
    final temp = data['main']['temp'];
    final desc = data['weather'][0]['description'];
    final icon = data['weather'][0]['icon'];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${widget.city}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text('$temp°C', style: TextStyle(fontSize: 48)),
          Text(desc, style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic)),
          SizedBox(height: 10),
          Image.network('http://openweathermap.org/img/wn/$icon@2x.png'),
        ],
      ),
    );
  }

  Widget buildAttractionsTab(List<Map<String, String>> attractions) {
    return PageView.builder(
      itemCount: attractions.length,
      controller: PageController(viewportFraction: 0.9),
      itemBuilder: (context, index) {
        final place = attractions[index];
        return GestureDetector(
          onTap: () => _launchMap('${place['name']} ${widget.city}'),
          child: Card(
            margin: EdgeInsets.all(16),
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.asset(
                      place['image']!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.image_not_supported, size: 100),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    place['name']!,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final attractions = cityAttractions[widget.city]!;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.city} Info'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Weather'),
            Tab(text: 'Attractions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FutureBuilder<Map<String, dynamic>>(
            future: weatherData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return Center(child: CircularProgressIndicator());
              if (snapshot.hasError)
                return Center(child: Text('Error loading weather'));
              return buildWeatherTab(snapshot.data!);
            },
          ),
          buildAttractionsTab(attractions),
        ],
      ),
    );
  }
}
