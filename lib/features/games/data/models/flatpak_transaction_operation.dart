class MyFlatpakTransactionOperation {
  final String ref;
  final String type;
  final String remote;

  MyFlatpakTransactionOperation({
    required this.ref,
    required this.type,
    required this.remote,
  });

  factory MyFlatpakTransactionOperation.fromJson(Map<String, dynamic> json) {
    return MyFlatpakTransactionOperation(
      ref: json['ref'] as String? ?? '',
      type: json['type'] as String? ?? '',
      remote: json['remote'] as String? ?? '',
    );
  }
}

class FlatpakProgress {
  final List<MyFlatpakTransactionOperation> operations;
  final double progress;
  final String? status;

  FlatpakProgress({
    required this.operations,
    required this.progress,
    this.status,
  });
}
