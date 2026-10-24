class ApiEndpoint {
  final String name;
  final String url;
  final String method;
  final Map<String, String> headers;
  final String bodyTemplate;
  final bool enabled;

  ApiEndpoint({
    required this.name,
    required this.url,
    this.method = 'POST',
    this.headers = const {'Content-Type': 'application/json'},
    this.bodyTemplate = '{"phone":"{phone}"}',
    this.enabled = true,
  });

  ApiEndpoint copyWith({
    String? name,
    String? url,
    String? method,
    Map<String, String>? headers,
    String? bodyTemplate,
    bool? enabled,
  }) =>
      ApiEndpoint(
        name: name ?? this.name,
        url: url ?? this.url,
        method: method ?? this.method,
        headers: headers ?? this.headers,
        bodyTemplate: bodyTemplate ?? this.bodyTemplate,
        enabled: enabled ?? this.enabled,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'url': url,
        'method': method,
        'headers': headers,
        'bodyTemplate': bodyTemplate,
        'enabled': enabled,
      };

  factory ApiEndpoint.fromJson(Map<String, dynamic> json) => ApiEndpoint(
        name: json['name'] as String,
        url: json['url'] as String,
        method: json['method'] as String? ?? 'POST',
        headers: Map<String, String>.from(json['headers'] as Map? ?? {}),
        bodyTemplate: json['bodyTemplate'] as String? ?? '{"phone":"{phone}"}',
        enabled: json['enabled'] as bool? ?? true,
      );
}