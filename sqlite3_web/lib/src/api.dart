import 'dart:js_interop';
import 'dart:typed_data';

import 'package:sqlite3/wasm.dart';

import 'client.dart';
import 'worker.dart';

typedef ExistingDatabase = (StorageMode, String);

enum FileType {
  database,
  journal,
}

enum StorageMode {
  // Note: Indices in this enum are used in the protocol, changing them is a
  // backwards-incompatible change.
  opfs,
  indexedDb,
  inMemory,
}

enum AccessMode {
  throughSharedWorker,
  throughDedicatedWorker,
  inCurrentContext,
}

final class RemoteException implements Exception {
  final String message;

  RemoteException({required this.message});

  @override
  String toString() {
    return 'Remote error: $message';
  }
}

abstract class FileSystem {
  StorageMode get storage;
  String get databaseName;

  Future<bool> exists(FileType type);
  Future<Uint8List> readFile(FileType type);
  Future<void> writeFile(FileType type, Uint8List content);
}

abstract class Database {
  FileSystem get fileSystem;
  Stream<SqliteUpdate> get updates;

  Future<void> dispose();

  Future<int> get lastInsertRowId;

  Future<int> get userVersion;
  Future<void> setUserVersion(int version);

  Future<void> execute(String sql, [List<Object?> parameters = const []]);
  Future<ResultSet> select(String sql, [List<Object?> parameters = const []]);

  Future<JSAny?> customRequest(JSAny? request);
}

abstract class ClientConnection {
  int get id;

  Future<void> get closed;

  Future<JSAny?> customRequest(JSAny? request);
}

abstract class WorkerDatabase {
  CommonDatabase get database;

  Future<JSAny?> handleCustomRequest(
      ClientConnection connection, JSAny? request);
}

abstract base class DatabaseController {
  Future<WasmSqlite3> loadWasmModule(Uri uri,
      {Map<String, String>? headers}) async {
    return WasmSqlite3.loadFromUrl(uri, headers: headers);
  }

  Future<WorkerDatabase> openDatabase(WasmSqlite3 sqlite3, String vfs);

  Future<JSAny?> handleCustomRequest(
      ClientConnection connection, JSAny? request);
}

/// An enumeration of features not supported by the current browsers.
///
/// While this information may not be useful to end users, it can be used to
/// understand why a particular file system implementation is unavailable.
enum MissingBrowserFeature {
  /// The browser is missing support for [shared workers].
  ///
  /// [shared workers]: https://developer.mozilla.org/en-US/docs/Web/API/SharedWorker
  sharedWorkers,

  /// The browser is missing support for [web workers] in general.
  ///
  /// [web workers]: https://developer.mozilla.org/en-US/docs/Web/API/Worker
  dedicatedWorkers,

  /// The browser doesn't allow shared workers to spawn dedicated workers in
  /// their context.
  ///
  /// While the specification for web workers explicitly allows this, this
  /// feature is only implemented by Firefox at the time of writing.
  dedicatedWorkersInSharedWorkers,

  /// The browser doesn't allow dedicated workers to spawn their own dedicated
  /// workers.
  dedicatedWorkersCanNest,

  /// The browser does not support a synchronous version of the [File System API]
  ///
  /// [File System API]: https://developer.mozilla.org/en-US/docs/Web/API/File_System_Access_API
  fileSystemAccess,

  /// The browser does not support IndexedDB.
  indexedDb,

  /// The browser does not support shared array buffers and `Atomics.wait`.
  ///
  /// To enable this feature in most browsers, you need to serve your app with
  /// two [special headers](https://web.dev/coop-coep/).
  sharedArrayBuffers,
}

final class FeatureDetectionResult {
  /// A list of features that were probed and found to be unsupported in the
  /// current browser.
  final List<MissingBrowserFeature> missingFeatures;

  final List<ExistingDatabase> existingDatabases;

  final List<(StorageMode, AccessMode)> availableImplementations;

  FeatureDetectionResult({
    required this.missingFeatures,
    required this.existingDatabases,
    required this.availableImplementations,
  });

  @override
  String toString() {
    return 'Existing: $existingDatabases, available: '
        '$availableImplementations, missing: $missingFeatures';
  }
}

final class ConnectToRecommendedResult {
  final Database database;
  final FeatureDetectionResult features;
  final StorageMode storage;
  final AccessMode access;

  ConnectToRecommendedResult({
    required this.database,
    required this.features,
    required this.storage,
    required this.access,
  });
}

abstract class WebSqlite {
  Future<FeatureDetectionResult> runFeatureDetection({String? databaseName});

  Future<Database> connect(String name, StorageMode type, AccessMode access);

  Future<ConnectToRecommendedResult> connectToRecommended(String name);

  static void workerEntrypoint({
    required DatabaseController controller,
  }) {
    WorkerRunner(controller).handleRequests();
  }

  static Future<WebSqlite> open({
    required Uri worker,
    required Uri wasmModule,
  }) async {
    return DatabaseClient(worker, wasmModule);
  }
}