import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../models/verify_response.dart';

class UrlInputForm extends StatefulWidget {
  final String? initialUrl;

  const UrlInputForm({super.key, this.initialUrl});

  @override
  _UrlInputFormState createState() => _UrlInputFormState();
}

class _UrlInputFormState extends State<UrlInputForm> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final ApiService _apiService = ApiService();
  String? _result;
  String? _errorMessage;
  bool _isLoading = false;
  VerifyResponse? _response;

  @override
  void initState() {
    super.initState();
    if (widget.initialUrl != null && widget.initialUrl!.trim().isNotEmpty) {
      _urlController.text = widget.initialUrl!.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _urlController.text = widget.initialUrl!.trim();
          });
          if (_formKey.currentState!.validate()) {
            _fetchTranscript();
          } else {
            setState(() {
              _errorMessage = 'Invalid shared URL. Please enter a valid YouTube or Instagram URL.';
            });
          }
        }
      });
    }
    // Add listener to ensure UI updates if URL changes
    _urlController.addListener(() {
      setState(() {});
    });
  }

  void _fetchTranscript() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _result = null;
        _errorMessage = null;
        _response = null;
      });

      try {
        final response = await _apiService.fetchTranscript(
          videoURL: _urlController.text.trim(),
          context: context,
        );

        setState(() {
          _isLoading = false;
          _response = response;
          if (response.error != null) {
            _errorMessage = response.error;
            if (response.error!.toLowerCase().contains('instagram')) {
              _errorMessage = 'Instagram videos are not yet supported.';
            }
          } else if (response.data?.isFinancial == true &&
              response.data?.normalizedTranscript != null &&
              response.data!.normalizedTranscript.isNotEmpty) {
            _result = response.data!.normalizedTranscript;
          } else if (response.data?.isFinancial == false) {
            _errorMessage = 'This is not a financial video.';
          } else {
            _errorMessage = 'No normalized transcript available for this video.';
          }
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to fetch data. Please try again.';
        });
      }
    }
  }

  void _copyTranscript() {
    if (_result != null) {
      Clipboard.setData(ClipboardData(text: _result!));
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
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    final padding = isWideScreen ? MediaQuery.of(context).size.width * 0.15 : 24.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fact_check,
                  color: Theme.of(context).colorScheme.primary,
                  size: isWideScreen ? 32 : 28,
                ),
                const SizedBox(width: 8),
                Text(
                  'Video Fact-Checker',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: isWideScreen ? 28 : 26,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 8),
            Text(
              'Enter a YouTube or Instagram video URL to verify its financial content and fact-check claims.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: isWideScreen ? 16 : 14,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
            const SizedBox(height: 24),
            TextFormField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Video URL',
                hintText: 'e.g., https://www.youtube.com/watch?v=example',
                prefixIcon: Icon(
                  Icons.link,
                  color: Theme.of(context).colorScheme.primary,
                  size: isWideScreen ? 22 : 20,
                ),
                suffixIcon: _urlController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          size: isWideScreen ? 22 : 20,
                        ),
                        onPressed: () {
                          _urlController.clear();
                          setState(() {
                            _result = null;
                            _errorMessage = null;
                            _response = null;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              onChanged: (value) => setState(() {}),
              onFieldSubmitted: (value) => _fetchTranscript(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a valid URL';
                }
                final urlPattern = RegExp(
                  r'^(https?:\/\/)?(www\.)?(youtube\.com|youtu\.be|instagram\.com)\/.*$',
                  caseSensitive: false,
                );
                if (!urlPattern.hasMatch(value.trim())) {
                  return 'Please enter a valid YouTube or Instagram URL';
                }
                return null;
              },
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
            const SizedBox(height: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              decoration: BoxDecoration(
                color: _isLoading
                    ? Theme.of(context).colorScheme.surface.withOpacity(0.5)
                    : Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _fetchTranscript,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(
                    vertical: isWideScreen ? 16 : 14,
                    horizontal: isWideScreen ? 32 : 24,
                  ),
                ),
                child: _isLoading
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SpinKitCircle(
                            color: Colors.white,
                            size: 20.0,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Verifying...',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: isWideScreen ? 16 : 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: isWideScreen ? 20 : 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Verify Video',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: isWideScreen ? 16 : 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 300.ms).scaleXY(begin: 0.95, end: 1.0),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              AnimatedContainer(
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
                    if (_errorMessage != 'This is not a financial video.' &&
                        _errorMessage != 'Instagram videos are not yet supported.')
                      TextButton(
                        onPressed: _fetchTranscript,
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
            if (_isLoading)
              Shimmer.fromColors(
                baseColor: Theme.of(context).colorScheme.surface.withOpacity(0.2),
                highlightColor: Theme.of(context).colorScheme.surface.withOpacity(0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: isWideScreen ? 28 : 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: isWideScreen ? 150 : 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              )
            else if (_response != null && _response!.data != null)
              AnimatedContainer(
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
                              _response!.data!.platform.toLowerCase().contains('youtube')
                                  ? Icons.play_circle
                                  : _response!.data!.platform.toLowerCase().contains('instagram')
                                      ? Icons.camera_alt
                                      : Icons.videocam,
                              color: _response!.data!.platform.toLowerCase().contains('youtube')
                                  ? const Color(0xFFFF0000)
                                  : _response!.data!.platform.toLowerCase().contains('instagram')
                                      ? const Color(0xFF833AB4)
                                      : Theme.of(context).colorScheme.primary,
                              size: isWideScreen ? 24 : 22,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Platform: ${_response!.data!.platform}',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: isWideScreen ? 16 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            if (_result != null)
                              IconButton(
                                icon: Icon(
                                  Icons.content_copy,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: isWideScreen ? 22 : 20,
                                ),
                                onPressed: _copyTranscript,
                                tooltip: 'Copy Normalized Transcript',
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_response!.data!.isFinancial) ...[
                          if (_result != null) ...[
                            Text(
                              'Normalized Transcript',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: isWideScreen ? 20 : 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              constraints: BoxConstraints(maxHeight: isWideScreen ? 400 : 300),
                              child: SingleChildScrollView(
                                child: SelectableText(
                                  _result!,
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
                          ],
                          Text(
                            'Fact-Check Results',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: isWideScreen ? 20 : 18,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_response!.data!.factCheck.claims.isEmpty)
                            Text(
                              'No specific claims identified for fact-checking.',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: isWideScreen ? 14 : 12,
                                fontWeight: FontWeight.w400,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ..._response!.data!.factCheck.claims.asMap().entries.map((entry) {
                            final index = entry.key;
                            final claim = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Claim ${index + 1}: ${claim.claim}',
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
                          if (_response!.data!.factCheck.sources.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Text(
                              'Sources',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: isWideScreen ? 20 : 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._response!.data!.factCheck.sources.asMap().entries.map((entry) {
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
                        ],
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}