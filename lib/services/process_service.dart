import 'dart:io' as io;
import '../core/errors/app_exceptions.dart';

/// Abstraction for executing OS processes, allowing services to be tested
/// without spawning actual processes.
abstract class ProcessService {
  /// Runs a process to completion asynchronously and returns the result.
  Future<io.ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  });

  /// Starts a process and returns a [io.Process] handle for streaming stdout/stderr
  /// and handling cancellation.
  Future<io.Process> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    io.ProcessStartMode mode = io.ProcessStartMode.normal,
  });
}

/// Standard implementation of [ProcessService] using `dart:io`.
class SystemProcessService implements ProcessService {
  const SystemProcessService();

  @override
  Future<io.ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    try {
      return await io.Process.run(
        executable,
        arguments,
        workingDirectory: workingDirectory,
        environment: environment,
        runInShell: false, // Prevents shell injection
      );
    } on io.ProcessException catch (e) {
      throw ProcessExecutionException(
        'Failed to start executable "$executable".',
        technicalDetails: e.message,
      );
    } catch (e) {
      throw ProcessExecutionException(
        'Unexpected error executing "$executable".',
        technicalDetails: e.toString(),
      );
    }
  }

  @override
  Future<io.Process> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    io.ProcessStartMode mode = io.ProcessStartMode.normal,
  }) async {
    try {
      return await io.Process.start(
        executable,
        arguments,
        workingDirectory: workingDirectory,
        environment: environment,
        mode: mode,
        runInShell: false, // Prevents shell injection
      );
    } on io.ProcessException catch (e) {
      throw ProcessExecutionException(
        'Failed to launch executable "$executable".',
        technicalDetails: e.message,
      );
    } catch (e) {
      throw ProcessExecutionException(
        'Unexpected error launching "$executable".',
        technicalDetails: e.toString(),
      );
    }
  }
}
