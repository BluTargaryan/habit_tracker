import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/weather.dart';
import '../../providers/quote_provider.dart';
import '../../providers/weather_provider.dart';
import '../../widgets/app_drawer.dart';

class MotivationScreen extends StatefulWidget {
  const MotivationScreen({super.key});

  @override
  State<MotivationScreen> createState() => _MotivationScreenState();
}

class _MotivationScreenState extends State<MotivationScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<QuoteProvider>().loadIfNeeded();
      context.read<WeatherProvider>().loadIfNeeded();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quoteProvider = context.watch<QuoteProvider>();
    final weatherProvider = context.watch<WeatherProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Motivation & Weather')),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Motivation', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _QuoteSection(quoteProvider: quoteProvider),
            const SizedBox(height: 32),
            Text('Weather', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _WeatherSection(weatherProvider: weatherProvider, searchController: _searchController),
          ],
        ),
      ),
    );
  }
}

class _QuoteSection extends StatelessWidget {
  final QuoteProvider quoteProvider;

  const _QuoteSection({required this.quoteProvider});

  @override
  Widget build(BuildContext context) {
    final quote = quoteProvider.quote;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (quote == null && quoteProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (quote != null) ...[
              Text('"${quote.text}"', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('— ${quote.author}', style: Theme.of(context).textTheme.bodyMedium),
            ] else
              const Text('No quote available.'),
            if (quoteProvider.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                quoteProvider.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: quoteProvider.isLoading ? null : quoteProvider.refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherSection extends StatelessWidget {
  final WeatherProvider weatherProvider;
  final TextEditingController searchController;

  const _WeatherSection({required this.weatherProvider, required this.searchController});

  @override
  Widget build(BuildContext context) {
    if (weatherProvider.needsManualLocation) {
      return _ManualLocationSearch(weatherProvider: weatherProvider, controller: searchController);
    }

    if (weatherProvider.isLoading && weatherProvider.snapshot == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final snapshot = weatherProvider.snapshot;
    if (snapshot == null) {
      return Text(
        weatherProvider.errorMessage ?? 'Weather unavailable.',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (weatherProvider.locationLabel != null)
          Text(weatherProvider.locationLabel!, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.wb_sunny_outlined, size: 32),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${snapshot.current.temperature.round()}°C',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(describeWeatherCode(snapshot.current.weatherCode)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Forecast', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...snapshot.daily.map((day) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_formatWeekday(day.date)),
            subtitle: Text(describeWeatherCode(day.weatherCode)),
            trailing: Text('${day.maxTemp.round()}° / ${day.minTemp.round()}°'),
          );
        }),
      ],
    );
  }

  String _formatWeekday(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }
}

class _ManualLocationSearch extends StatelessWidget {
  final WeatherProvider weatherProvider;
  final TextEditingController controller;

  const _ManualLocationSearch({required this.weatherProvider, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Location access is unavailable. Search for a city to see its weather:'),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'City name',
            suffixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) => weatherProvider.searchCity(value),
        ),
        const SizedBox(height: 8),
        if (weatherProvider.isSearching)
          const Center(child: CircularProgressIndicator())
        else
          ...weatherProvider.searchResults.map((result) {
            return ListTile(
              title: Text(result.name),
              subtitle: result.country != null ? Text(result.country!) : null,
              onTap: () => weatherProvider.setManualLocation(result),
            );
          }),
      ],
    );
  }
}
