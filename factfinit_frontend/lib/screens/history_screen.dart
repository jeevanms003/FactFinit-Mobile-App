// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart'; // Added import for DateFormat
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../models/history_response.dart';
import '../providers/auth_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _apiService = ApiService();
  HistoryResponse? _historyResponse;
  String? _errorMessage;
  bool _isLoading = false;
  int _currentPage = 1;
  int _limit = 10;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  void _fetchHistory({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = page;
    });

    try {
      final response = await _apiService.fetchHistory(
        context: context,
        page: _currentPage,
        limit: _limit,
      );

      setState(() {
        _isLoading = false;
        _historyResponse = response;
        if (response.error != null) {
          _errorMessage = response.error;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to fetch history. Please try again.';
      });
    }
  }

  void _copyTranscript(String transcript) {
    Clipboard.setData(ClipboardData(text: transcript));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Normalized transcript copied to clipboard',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open link: $url',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    final padding = isWideScreen ? MediaQuery.of(context).size.width * 0.15 : 24.0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.primary,
              size: isWideScreen ? 24 : 22,
            ),
            const SizedBox(width: 8),
            const Text(
              'Verification History',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SpinKitCircle(
                    color: Colors.white,
                    size: 50.0,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading history...',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: isWideScreen ? 16 : 14,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                            size: isWideScreen ? 22 : 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: isWideScreen ? 14 : 12,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _fetchHistory(page: _currentPage),
                            child: Text(
                              'Retry',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: isWideScreen ? 14 : 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms),
                  ),
                )
              : _historyResponse?.data?.history.isEmpty ?? true
                  ? Center(
                      child: Text(
                        'No history found.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: isWideScreen ? 16 : 14,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: padding, vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Verification History',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: isWideScreen ? 28 : 26,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ).animate().fadeIn(duration: 400.ms),
                            const SizedBox(height: 8),
                            Text(
                              'View all videos you have verified.',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: isWideScreen ? 16 : 14,
                                fontWeight: FontWeight.w400,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                            const SizedBox(height: 24),
                            ..._historyResponse!.data!.history.asMap().entries.map((entry) {
                              final item = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 24.0),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 400),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                                  ),
                                  child: Card(
                                    elevation: 0,
                                    color: Colors.transparent,
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                item.platform.toLowerCase().contains('youtube')
                                                    ? Icons.play_circle
                                                    : item.platform.toLowerCase().contains('instagram')
                                                        ? Icons.camera_alt
                                                        : Icons.videocam,
                                                color: item.platform.toLowerCase().contains('youtube')
                                                    ? const Color(0xFFFF0000)
                                                    : item.platform.toLowerCase().contains('instagram')
                                                        ? const Color(0xFF833AB4)
                                                        : Theme.of(context).colorScheme.primary,
                                                size: isWideScreen ? 24 : 22,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: InkWell(
                                                  onTap: () => _launchUrl(item.videoURL),
                                                  child: Text(
                                                    item.videoURL,
                                                    style: TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: isWideScreen ? 16 : 14,
                                                      fontWeight: FontWeight.w600,
                                                      color: Theme.of(context).colorScheme.primary,
                                                      decoration: TextDecoration.underline,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.content_copy,
                                                  color: Theme.of(context).colorScheme.primary,
                                                  size: isWideScreen ? 22 : 20,
                                                ),
                                                onPressed: () => _copyTranscript(item.normalizedTranscript),
                                                tooltip: 'Copy Normalized Transcript',
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Platform: ${item.platform}',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: isWideScreen ? 14 : 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Verified on: ${DateFormat('MMM dd, yyyy – HH:mm').format(item.createdAt)}',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: isWideScreen ? 14 : 12,
                                              fontWeight: FontWeight.w400,
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          if (item.isFinancial) ...[
                                            Text(
                                              'Normalized Transcript',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: isWideScreen ? 18 : 16,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Container(
                                              constraints: BoxConstraints(maxHeight: isWideScreen ? 200 : 150),
                                              child: SingleChildScrollView(
                                                child: SelectableText(
                                                  item.normalizedTranscript,
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: isWideScreen ? 14 : 12,
                                                    fontWeight: FontWeight.w400,
                                                    height: 1.5,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            Text(
                                              'Fact-Check Results',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: isWideScreen ? 18 : 16,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            if (item.factCheck.claims.isEmpty)
                                              Text(
                                                'No specific claims identified for fact-checking.',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: isWideScreen ? 14 : 12,
                                                  fontWeight: FontWeight.w400,
                                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                                ),
                                              ),
                                            ...item.factCheck.claims.asMap().entries.map((entry) {
                                              final claim = entry.value;
                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 16.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Claim: ${claim.claim}',
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontSize: isWideScreen ? 16 : 14,
                                                        fontWeight: FontWeight.w600,
                                                        color: Theme.of(context).colorScheme.onSurface,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          claim.isAccurate ? Icons.check_circle : Icons.cancel,
                                                          color: claim.isAccurate
                                                              ? Colors.green
                                                              : Theme.of(context).colorScheme.error,
                                                          size: isWideScreen ? 20 : 18,
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          claim.isAccurate ? 'Accurate' : 'Inaccurate',
                                                          style: TextStyle(
                                                            fontFamily: 'Poppins',
                                                            fontSize: isWideScreen ? 14 : 12,
                                                            fontWeight: FontWeight.w500,
                                                            color: claim.isAccurate
                                                                ? Colors.green
                                                                : Theme.of(context).colorScheme.error,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      claim.explanation,
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontSize: isWideScreen ? 14 : 12,
                                                        fontWeight: FontWeight.w400,
                                                        height: 1.5,
                                                        color: Theme.of(context).colorScheme.onSurface,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                            if (item.factCheck.sources.isNotEmpty) ...[
                                              const SizedBox(height: 24),
                                              Text(
                                                'Sources',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: isWideScreen ? 18 : 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              ...item.factCheck.sources.asMap().entries.map((entry) {
                                                final source = entry.value;
                                                return Padding(
                                                  padding: const EdgeInsets.only(bottom: 16.0),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      InkWell(
                                                        onTap: () => _launchUrl(source.url),
                                                        child: Text(
                                                          source.title,
                                                          style: TextStyle(
                                                            fontFamily: 'Poppins',
                                                            fontSize: isWideScreen ? 14 : 12,
                                                            fontWeight: FontWeight.w600,
                                                            color: Theme.of(context).colorScheme.primary,
                                                            decoration: TextDecoration.underline,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        source.snippet,
                                                        style: TextStyle(
                                                          fontFamily: 'Poppins',
                                                          fontSize: isWideScreen ? 14 : 12,
                                                          fontWeight: FontWeight.w400,
                                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ],
                                          ] else ...[
                                            Text(
                                              'Non-financial video',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: isWideScreen ? 14 : 12,
                                                fontWeight: FontWeight.w400,
                                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn(duration: 400.ms);
                            }).toList(),
                            if (_historyResponse!.data!.pagination.totalPages > 1)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.arrow_back,
                                      color: _currentPage > 1
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                      size: isWideScreen ? 24 : 22,
                                    ),
                                    onPressed: _currentPage > 1
                                        ? () => _fetchHistory(page: _currentPage - 1)
                                        : null,
                                  ),
                                  Text(
                                    'Page $_currentPage of ${_historyResponse!.data!.pagination.totalPages}',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: isWideScreen ? 14 : 12,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.arrow_forward,
                                      color: _currentPage < _historyResponse!.data!.pagination.totalPages
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                      size: isWideScreen ? 24 : 22,
                                    ),
                                    onPressed: _currentPage < _historyResponse!.data!.pagination.totalPages
                                        ? () => _fetchHistory(page: _currentPage + 1)
                                        : null,
                                  ),
                                ],
                              ).animate().fadeIn(duration: 400.ms),
                          ],
                        ),
                      ),
                    ),
    );
  }
}